############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"  
GLOBALS "../gl/G_GL_GLOBALS.4gl"
GLOBALS "../gl/GR_GROUP_GLOBALS.4gl"
GLOBALS "../gl/GRL_GLOBALS.4gl" 
############################################################
# MODULE Scope Variables
############################################################
DEFINE modu_rec_rpt_total RECORD 
	limit_amt LIKE fundsapproved.limit_amt, 
	po_amt LIKE poaudit.line_total_amt, 
	vouch_amt LIKE voucherdist.dist_amt, 
	debit_amt LIKE debitdist.dist_amt, 
	gl_amt LIKE batchdetl.debit_amt, 
	consumed_amt LIKE fundsapproved.limit_amt, 
	available_amt LIKE fundsapproved.limit_amt 
END RECORD
############################################################
# FUNCTION GRL_main()
#
#Capital Account Report
#manu say it's Approved Funds Account Details
############################################################
FUNCTION GRL_main() 
	DEFER quit 
	DEFER interrupt 

	CALL setModuleId("GRL") 
	CALL ui_init(0) #initial ui init 
	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_g_gl() #init g/gl general ledger module 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 

			OPEN WINDOW g552 with FORM "G552" 
			CALL windecoration_g("G552") 

			MENU " Approved Funds Account" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","GRL","menu-approved-funds-account") 
					CALL GRL_rpt_process(GRL_rpt_query())
					CALL rpt_rmsreps_reset(NULL)
					
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				ON ACTION "Report"		#COMMAND "Run" " SELECT Criteria AND PRINT REPORT"
					CALL GRL_rpt_process(GRL_rpt_query())
					CALL rpt_rmsreps_reset(NULL)

				ON ACTION "Print Manager" 	#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "Exit" 	#COMMAND KEY (interrupt,"E")"Exit" " Exit TO menus"
					EXIT MENU 

			END MENU 

			CLOSE WINDOW G552 

		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL GRL_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW G552 with FORM "G552" 
			CALL windecoration_g("G552") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(GRL_rpt_query()) #save where clause in env 
			CLOSE WINDOW G552 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL GRL_rpt_process(get_url_sel_text())
	END CASE 

END FUNCTION


############################################################
# FUNCTION GRL_rpt_query()
#
#
############################################################
FUNCTION GRL_rpt_query() 
	DEFINE l_where_text STRING 
	
	MESSAGE kandoomsg2("U",1001,"") #1001 Enter Selection Criteria;  OK TO Continue.
	CONSTRUCT BY NAME l_where_text ON fundsapproved.acct_code, 
	coa.desc_text, 
	coa.type_ind, 
	fundsapproved.fund_type_ind, 
	fundsapproved.locn_text, 
	fundsapproved.amend_code, 
	fundsapproved.limit_amt, 
	fundsapproved.amend_date, 
	fundsapproved.approval_date, 
	fundsapproved.capital_ref, 
	fundsapproved.active_flag 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","GRL","construct-fundsapproved") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 
	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL 
	END IF 

	RETURN l_where_text
END FUNCTION 


############################################################
# FUNCTION GRL_rpt_process()
#
#
############################################################
FUNCTION GRL_rpt_process(p_where_text)
	DEFINE p_where_text STRING 
	DEFINE l_rpt_idx SMALLINT  
	DEFINE l_query_text STRING 
	DEFINE l_rec_fundsapproved RECORD LIKE fundsapproved.* 
	DEFINE l_desc_text LIKE coa.desc_text 

	LET modu_rec_rpt_total.limit_amt = 0 
	LET modu_rec_rpt_total.po_amt = 0 
	LET modu_rec_rpt_total.vouch_amt = 0 
	LET modu_rec_rpt_total.debit_amt = 0 
	LET modu_rec_rpt_total.gl_amt = 0 
	LET modu_rec_rpt_total.consumed_amt = 0 
	LET modu_rec_rpt_total.available_amt = 0 


	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false
		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"GRL_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT GRL_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0
	LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GRL_rpt_list")].sel_text
	#------------------------------------------------------------

	LET l_query_text = "SELECT fundsapproved.* FROM fundsapproved, coa ", 
	"WHERE fundsapproved.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND coa.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND coa.acct_code = fundsapproved.acct_code ", 
	"AND ",glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GRL_rpt_list")].sel_text clipped," ", 
	"ORDER BY locn_text, acct_code" 
	PREPARE s_fundsapproved FROM l_query_text 
	DECLARE c_fundsapproved CURSOR FOR s_fundsapproved 

	FOREACH c_fundsapproved INTO l_rec_fundsapproved.* 
		#---------------------------------------------------------
		OUTPUT TO REPORT GRL_rpt_list(l_rpt_idx,l_rec_fundsapproved.*) 
		IF NOT rpt_int_flag_handler2("Location:",l_rec_fundsapproved.locn_text, l_rec_fundsapproved.acct_code,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT GRL_rpt_list
	CALL rpt_finish("GRL_rpt_list")
	#------------------------------------------------------------

	IF int_flag THEN
		MESSAGE "Report Generation Canceled..."
		RETURN FALSE
	ELSE
		RETURN TRUE
	END IF 
END FUNCTION 


############################################################
# REPORT GRL_rpt_list(p_rpt_idx,p_rec_fundsapproved)
#
#
############################################################
REPORT GRL_rpt_list(p_rpt_idx,p_rec_fundsapproved) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_fundsapproved RECORD LIKE fundsapproved.* 
	DEFINE l_rec_poaudit RECORD LIKE poaudit.*
	DEFINE l_rec_cabdetl RECORD 
		po_amt LIKE poaudit.line_total_amt, 
		vouch_amt LIKE voucherdist.dist_amt, 
		debit_amt LIKE debitdist.dist_amt, 
		gl_amt LIKE batchdetl.debit_amt, 
		consumed_amt LIKE fundsapproved.limit_amt, 
		available_amt LIKE fundsapproved.limit_amt 
	END RECORD 
	DEFINE l_rec_cabtotal RECORD 
		limit_amt LIKE fundsapproved.limit_amt, 
		po_amt LIKE poaudit.line_total_amt, 
		vouch_amt LIKE voucherdist.dist_amt, 
		debit_amt LIKE debitdist.dist_amt, 
		gl_amt LIKE batchdetl.debit_amt, 
		consumed_amt LIKE fundsapproved.limit_amt, 
		available_amt LIKE fundsapproved.limit_amt 
	END RECORD 
	DEFINE l_counter LIKE purchdetl.line_num 
	DEFINE l_line_num LIKE purchdetl.line_num 
	DEFINE l_ref_num LIKE purchdetl.order_num
	DEFINE l_total_amt LIKE fundsapproved.limit_amt 
	DEFINE l_line array[4] OF CHAR(132) 
	DEFINE l_desc_text LIKE coa.desc_text 

	OUTPUT 
--	left margin 0 
	ORDER external BY p_rec_fundsapproved.locn_text, 
	p_rec_fundsapproved.acct_code 
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		BEFORE GROUP OF p_rec_fundsapproved.locn_text 
			LET l_rec_cabtotal.limit_amt = 0 
			LET l_rec_cabtotal.po_amt = 0 
			LET l_rec_cabtotal.vouch_amt = 0 
			LET l_rec_cabtotal.debit_amt = 0 
			LET l_rec_cabtotal.gl_amt = 0 
			LET l_rec_cabtotal.consumed_amt = 0 
			LET l_rec_cabtotal.available_amt = 0 
			PRINT COLUMN 01, "Location: ",p_rec_fundsapproved.locn_text 
			PRINT "" 

		BEFORE GROUP OF p_rec_fundsapproved.acct_code 
			SELECT desc_text INTO l_desc_text FROM coa 
			WHERE acct_code = p_rec_fundsapproved.acct_code 
			IF status = NOTFOUND THEN 
				LET l_desc_text = NULL 
			END IF 
			PRINT COLUMN 03, p_rec_fundsapproved.acct_code, 
			COLUMN 23, l_desc_text[1,30], " ", 
			p_rec_fundsapproved.capital_ref[1,15], 
			COLUMN 70, "Approval: ", 
			p_rec_fundsapproved.approval_date USING "dd/mm/yyyy", 
			COLUMN 98, "Last Amended: ", 
			p_rec_fundsapproved.amend_date USING "dd/mm/yyyy"," ", 
			p_rec_fundsapproved.amend_code 

		ON EVERY ROW 
			LET l_rec_cabdetl.po_amt = 0 
			LET l_rec_cabdetl.vouch_amt = 0 
			LET l_rec_cabdetl.debit_amt = 0 
			LET l_rec_cabdetl.gl_amt = 0 
			LET l_rec_cabdetl.consumed_amt = 0 
			LET l_rec_cabdetl.available_amt = 0 

			# Get Purchase Order information
			DECLARE c_purchdetl CURSOR FOR 
			SELECT order_num, line_num 
			FROM purchdetl 
			WHERE cmpy_code = cmpy_code 
			AND acct_code = p_rec_fundsapproved.acct_code 
			ORDER BY order_num 
			FOREACH c_purchdetl INTO l_ref_num, l_line_num 
				CALL po_line_info(glob_rec_kandoouser.cmpy_code, 
				l_ref_num, 
				l_line_num) 
				RETURNING l_rec_poaudit.order_qty, 
				l_rec_poaudit.received_qty, 
				l_rec_poaudit.voucher_qty, 
				l_rec_poaudit.unit_cost_amt, 
				l_rec_poaudit.ext_cost_amt, 
				l_rec_poaudit.unit_tax_amt, 
				l_rec_poaudit.ext_tax_amt, 
				l_rec_poaudit.line_total_amt 
				LET l_rec_cabdetl.po_amt = l_rec_cabdetl.po_amt + l_rec_poaudit.line_total_amt 
			END FOREACH 

			# Get Voucher information
			SELECT sum(dist_amt) INTO l_rec_cabdetl.vouch_amt 
			FROM voucherdist 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND acct_code = p_rec_fundsapproved.acct_code 
			IF l_rec_cabdetl.vouch_amt IS NULL THEN 
				LET l_rec_cabdetl.vouch_amt = 0 
			END IF 

			# Get General Ledger information
			SELECT sum(batchdetl.for_debit_amt) - sum(batchdetl.for_credit_amt) 
			INTO l_rec_cabdetl.gl_amt 
			FROM batchhead, batchdetl 
			WHERE batchhead.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND batchdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND batchhead.jour_num = batchdetl.jour_num 
			AND batchdetl.acct_code = p_rec_fundsapproved.acct_code 
			AND (batchhead.source_ind != 'R' 
			AND batchhead.source_ind != 'P') 
			IF l_rec_cabdetl.gl_amt IS NULL THEN 
				LET l_rec_cabdetl.gl_amt = 0 
			END IF 

			# Get Debit information
			SELECT sum(debitdist.dist_amt) INTO l_rec_cabdetl.debit_amt 
			FROM debitdist, debithead 
			WHERE debithead.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND debitdist.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND debitdist.debit_code = debithead.debit_num 
			AND debitdist.acct_code = p_rec_fundsapproved.acct_code 
			IF l_rec_cabdetl.debit_amt IS NULL THEN 
				LET l_rec_cabdetl.debit_amt = 0 
			END IF 

			LET l_rec_cabdetl.consumed_amt = l_rec_cabdetl.po_amt 
				+ l_rec_cabdetl.vouch_amt 
				+ l_rec_cabdetl.gl_amt 
				- l_rec_cabdetl.debit_amt 
			LET l_rec_cabdetl.available_amt = p_rec_fundsapproved.limit_amt - l_rec_cabdetl.consumed_amt 

			PRINT COLUMN 05, p_rec_fundsapproved.limit_amt USING "--,---,--&.&&", 
			COLUMN 21, l_rec_cabdetl.po_amt USING "--,---,--&.&&", 
			COLUMN 37, l_rec_cabdetl.vouch_amt USING "--,---,--&.&&", 
			COLUMN 53, l_rec_cabdetl.debit_amt USING "--,---,--&.&&", 
			COLUMN 69, l_rec_cabdetl.gl_amt USING "--,---,--&.&&", 
			COLUMN 85, l_rec_cabdetl.consumed_amt USING "--,---,--&.&&", 
			COLUMN 101, l_rec_cabdetl.available_amt USING "--,---,--&.&&", 
			COLUMN 118, p_rec_fundsapproved.active_flag, 
			COLUMN 123, p_rec_fundsapproved.complete_date USING "dd/mm/yyyy" 
			PRINT "" 
			LET l_rec_cabtotal.limit_amt = l_rec_cabtotal.limit_amt + p_rec_fundsapproved.limit_amt 
			LET l_rec_cabtotal.po_amt = l_rec_cabtotal.po_amt + l_rec_cabdetl.po_amt 
			LET l_rec_cabtotal.vouch_amt = l_rec_cabtotal.vouch_amt + l_rec_cabdetl.vouch_amt 
			LET l_rec_cabtotal.debit_amt = l_rec_cabtotal.debit_amt + l_rec_cabdetl.debit_amt 
			LET l_rec_cabtotal.gl_amt = l_rec_cabtotal.gl_amt + l_rec_cabdetl.gl_amt 
			LET l_rec_cabtotal.consumed_amt = l_rec_cabtotal.consumed_amt + l_rec_cabdetl.consumed_amt 
			LET l_rec_cabtotal.available_amt = l_rec_cabtotal.available_amt + l_rec_cabdetl.available_amt 
			
		AFTER GROUP OF p_rec_fundsapproved.locn_text 
			PRINT "Location Total:" 
			PRINT COLUMN 04, l_rec_cabtotal.limit_amt USING "---,---,--&.&&", 
			COLUMN 20, l_rec_cabtotal.po_amt USING "---,---,--&.&&", 
			COLUMN 36, l_rec_cabtotal.vouch_amt USING "---,---,--&.&&", 
			COLUMN 52, l_rec_cabtotal.debit_amt USING "---,---,--&.&&", 
			COLUMN 68, l_rec_cabtotal.gl_amt USING "---,---,--&.&&", 
			COLUMN 84, l_rec_cabtotal.consumed_amt USING "---,---,--&.&&", 
			COLUMN 100, l_rec_cabtotal.available_amt USING "---,---,--&.&&" 
			PRINT "" 
			LET modu_rec_rpt_total.limit_amt = modu_rec_rpt_total.limit_amt + l_rec_cabtotal.limit_amt 
			LET modu_rec_rpt_total.po_amt = modu_rec_rpt_total.po_amt + l_rec_cabtotal.po_amt 
			LET modu_rec_rpt_total.vouch_amt = modu_rec_rpt_total.vouch_amt + l_rec_cabtotal.vouch_amt 
			LET modu_rec_rpt_total.debit_amt = modu_rec_rpt_total.debit_amt + l_rec_cabtotal.debit_amt 
			LET modu_rec_rpt_total.gl_amt = modu_rec_rpt_total.gl_amt + l_rec_cabtotal.gl_amt 
			LET modu_rec_rpt_total.consumed_amt = modu_rec_rpt_total.consumed_amt + l_rec_cabtotal.consumed_amt 
			LET modu_rec_rpt_total.available_amt = modu_rec_rpt_total.available_amt + l_rec_cabtotal.available_amt 
			
		ON LAST ROW 
			PRINT "Report Totals:" 
			PRINT COLUMN 04, modu_rec_rpt_total.limit_amt USING "---,---,--&.&&", 
			COLUMN 20, modu_rec_rpt_total.po_amt USING "---,---,--&.&&", 
			COLUMN 36, modu_rec_rpt_total.vouch_amt USING "---,---,--&.&&", 
			COLUMN 52, modu_rec_rpt_total.debit_amt USING "---,---,--&.&&", 
			COLUMN 68, modu_rec_rpt_total.gl_amt USING "---,---,--&.&&", 
			COLUMN 84, modu_rec_rpt_total.consumed_amt USING "---,---,--&.&&", 
			COLUMN 100, modu_rec_rpt_total.available_amt USING "---,---,--&.&&" 
			SKIP 3 line
			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			

			
			
END REPORT