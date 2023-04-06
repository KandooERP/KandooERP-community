###########################################################################
# This program IS free software; you can redistribute it AND/OR modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 2 of the License, OR (at your
# option) any later version.
#
# This program IS distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License FOR more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; IF NOT, write TO the Free Software Foundation, Inc.,
# 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
#
###########################################################################
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS 

	DEFINE glob_sum_det CHAR(1) 
	DEFINE glob_data_found SMALLINT 
END GLOBALS 
--DEFINE modu_where_text CHAR(2048) 
############################################################
# MAIN
#
#
############################################################
MAIN 

	#Initial UI Init
	CALL setModuleId("PRB") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_p_ap() #init p/ap module 

	CALL ring_menu() 


	EXIT PROGRAM 0 

END MAIN 

############################################################
# FUNCTION ring_menu()
#
#
############################################################
FUNCTION ring_menu() 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 	

			OPEN WINDOW P178 with FORM "P178" 
			CALL windecoration_p("P178") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
		
			MENU "Batch Report" 
		
				BEFORE MENU 
					CALL publish_toolbar("kandoo","PRB","menu-batch_rep-1") 
					CALL rpt_rmsreps_reset(NULL) 
					CALL PRB_rpt_process(PRB_rpt_query() ) # process the REPORT
		
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				COMMAND "Run Report" " SELECT criteria AND PRINT REPORT"
					CALL rpt_rmsreps_reset(NULL) 
					CALL PRB_rpt_process(PRB_rpt_query() ) # process the REPORT
		
				ON ACTION "Print Manager"			#COMMAND "Print" "Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "CANCEL"			#COMMAND "Exit" " Exit TO menus"
					EXIT MENU 
					CLOSE WINDOW P178 
		
			END MENU 

		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL PRB_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW P178 with FORM "P178" 
			CALL windecoration_p("P178") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(PRB_rpt_query()) #save where clause in env 
			CLOSE WINDOW P178 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL PRB_rpt_process(get_url_sel_text())
	END CASE 
	
END FUNCTION #ring_menu() 

############################################################
# FUNCTION PRB_rpt_query()
#
#
############################################################
FUNCTION PRB_rpt_query()
	DEFINE l_where_text STRING 
	
--	INITIALIZE modu_where_text TO NULL 
--	INITIALIZE glob_rpt_output TO NULL 
	INITIALIZE glob_sum_det TO NULL 
	INITIALIZE glob_data_found TO NULL 

	MESSAGE kandoomsg2("U",1001,"")	#selection IS a little complex because of ORDER of items on SCREEN
	CONSTRUCT BY NAME l_where_text ON batchhead.year_num , 
	batchhead.period_num , 
	batchhead.jour_date , 
	batchhead.jour_num , 
	batchdetl.tran_type_ind, 
	batchdetl.ref_num , 
	batchdetl.acct_code 


		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","PRB","construct-batchhead-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = 0 
		LET quit_flag = 0 
		RETURN 
	END IF 

	LET glob_sum_det = "D" 

	INPUT glob_sum_det WITHOUT DEFAULTS 
	FROM sum_det 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","PRB","inp-dum_det-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER INPUT 
			# Exclusive OR
			# Lycia issue: Lycia SET's quit_flag = TRUE
			# whenever int_flag IS SET automatically.
			# IF NOT int_flag OR quit_flag THEN
			# huho - changed TO
			IF NOT (int_flag OR quit_flag) THEN 
				IF glob_sum_det IS NULL THEN 
					ERROR "Enter (S) FOR Summary OR (D) FOR Detail REPORT " 
					NEXT FIELD sum_det 
				END IF 
			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = 0 
		LET quit_flag = 0 
		RETURN NULL
	ELSE
		LET glob_rec_rpt_selector.ref1_ind = glob_sum_det
		RETURN "N/A"
	END IF 
END FUNCTION # PRB_rpt_query() 

############################################################
# FUNCTION PRB_rpt_process()
#
#
############################################################
FUNCTION PRB_rpt_process(p_where_text)
	DEFINE p_where_text STRING 
	DEFINE l_rpt_idx SMALLINT  #report array index	
	DEFINE l_rec_batchhead RECORD LIKE batchhead.*
	DEFINE l_rec_batchdetl RECORD LIKE batchdetl.*
	DEFINE l_amt DEC(19,2)
	DEFINE l_fx_amt DEC(19,2)
	DEFINE l_sel_text CHAR(2200)

	INITIALIZE l_rec_batchhead.* TO NULL
	INITIALIZE l_sel_text TO NULL	
	INITIALIZE l_amt TO NULL
	INITIALIZE l_fx_amt TO NULL

	#SET up the REPORT AND start it


	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"PRB_rpt_list_AP_detail",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT v TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------
	#Case specific rems_reps works...
	LET glob_sum_det  = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref1_ind
	#------------------------------------------------------------

	#now build the SELECT statement

	LET l_sel_text = 
	"SELECT batchhead.* , batchdetl.* " , 
	"FROM batchhead , batchdetl " , 

	"WHERE batchhead.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" " , 
	" AND batchdetl.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" " , 
	" AND batchhead.entry_code = \"AP\" " , 

	" AND batchdetl.jour_num = batchhead.jour_num " 


	LET l_sel_text = l_sel_text clipped, 
	" AND " , p_where_text 

	LET l_sel_text = l_sel_text clipped, 
	" ORDER BY " , 
	" batchdetl.acct_code , batchhead.jour_num , " , 
	" batchhead.year_num , batchhead.period_num , " , 
	" batchdetl.ref_text , batchdetl.tran_type_ind , " , 
	" batchdetl.ref_num " 



	#now get all the data FOR the REPORT

	LET glob_data_found = false 

	PREPARE p_sel1 FROM l_sel_text 
	DECLARE s_curs1 CURSOR FOR p_sel1 

	FOREACH s_curs1 INTO l_rec_batchhead.* , l_rec_batchdetl.* 

		IF int_flag OR quit_flag THEN 
			RETURN 
		END IF 

		LET glob_data_found = true 

		IF l_rec_batchdetl.credit_amt IS NOT NULL AND 
		l_rec_batchdetl.credit_amt != 0 THEN 
			# trans. IS a credit
			LET l_amt = 0 - l_rec_batchdetl.credit_amt 
			LET l_fx_amt = 0 - l_rec_batchdetl.for_credit_amt 
		ELSE 
			# trans. IS a debit
			LET l_amt = l_rec_batchdetl.debit_amt 
			LET l_fx_amt = l_rec_batchdetl.for_debit_amt 
		END IF 

		#---------------------------------------------------------
		OUTPUT TO REPORT PRB_rpt_list_AP_detail(l_rpt_idx,
		l_rec_batchhead.jour_num , 
		l_rec_batchhead.jour_date , 
		l_rec_batchhead.year_num , 
		l_rec_batchhead.period_num , 
		l_rec_batchdetl.tran_type_ind[1,2] , 
		l_rec_batchdetl.ref_text , 
		l_rec_batchdetl.ref_num , 
		l_rec_batchdetl.acct_code , 
		l_rec_batchdetl.currency_code , 
		l_rec_batchdetl.conv_qty , 
		l_amt , 
		l_fx_amt ) 

		IF NOT rpt_int_flag_handler2("Journal:",l_rec_batchhead.jour_num , l_rec_batchhead.jour_date,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------

	END FOREACH 

	IF int_flag OR quit_flag THEN 
		RETURN 
	END IF 


	# IF no data was found FOR the REPORT, send a row anyway,
	# TO get the header printed.

	IF NOT glob_data_found THEN 
		INITIALIZE l_rec_batchhead.* TO NULL 
		INITIALIZE l_rec_batchdetl.* TO NULL 
		LET l_amt = NULL 
		LET l_fx_amt = NULL 

		#---------------------------------------------------------
		OUTPUT TO REPORT PRB_rpt_list_AP_detail(l_rpt_idx,
		l_rec_batchhead.jour_num , 
		l_rec_batchhead.jour_date , 
		l_rec_batchhead.year_num , 
		l_rec_batchhead.period_num , 
		l_rec_batchdetl.tran_type_ind[1,2] , 
		l_rec_batchdetl.ref_text , 
		l_rec_batchdetl.ref_num , 
		l_rec_batchdetl.acct_code , 
		l_rec_batchdetl.currency_code , 
		l_rec_batchdetl.conv_qty , 
		l_amt , 
		l_fx_amt )   
		#---------------------------------------------------------

	END IF 

	#------------------------------------------------------------
	FINISH REPORT PRB_rpt_list_AP_detail
	CALL rpt_finish("PRB_rpt_list_AP_detail")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = FALSE 
		ERROR " Printing was aborted" 
		RETURN FALSE 
	ELSE 
		RETURN TRUE 
	END IF 	
END FUNCTION # PRB_rpt_process 


############################################################
# REPORT PRB_rpt_list_AP_detail(p_rpt_idx,p_rec_rr)
#
#
############################################################
REPORT PRB_rpt_list_AP_detail(p_rpt_idx,p_rec_rr) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE p_rec_rr RECORD 
		jour_num LIKE batchhead.jour_num,
		jour_date LIKE batchhead.jour_date,
		year_num LIKE batchhead.year_num,
		period_num LIKE batchhead.period_num,
		tran_type CHAR(2),
		ref_text LIKE batchdetl.ref_text,
		ref_num LIKE batchdetl.ref_num,
		acct_code LIKE batchdetl.acct_code,
		currency_code LIKE batchdetl.currency_code,
		conv_qty LIKE batchdetl.conv_qty,
		amt DEC(19,2),
		fx_amt DEC(19,2) 
	END RECORD
	DEFINE l_acct_name LIKE coa.desc_text
	DEFINE l_cmpy_name LIKE company.name_text
	DEFINE l_year SMALLINT 

	OUTPUT 

	ORDER external BY	p_rec_rr.acct_code , p_rec_rr.jour_num 

	FORMAT 
	##      first PAGE HEADER   # get company name AND PRINT headings
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 1, "Posting Date" , 
			COLUMN 15, "Batch Number" , 
			COLUMN 30, "Trans" , 
			COLUMN 52, "Currency" 

			PRINT COLUMN 1, "Period" , 
			COLUMN 15, "Cust Code" , 
			COLUMN 30, "Type" , 
			COLUMN 43, "Reference" , 
			COLUMN 58, "Code" , 
			COLUMN 71, "Amount Dr/(Cr)" , 
			COLUMN 91, "Exch rate" , 
			COLUMN 104, "Base Currency Dr/(Cr)" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

		BEFORE GROUP OF p_rec_rr.acct_code # get account NAME AND PRINT it 

			IF glob_data_found THEN 

				SELECT desc_text INTO l_acct_name FROM coa 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND acct_code = p_rec_rr.acct_code 

				SKIP 2 LINES 
				PRINT COLUMN 1, "Control Account: ", p_rec_rr.acct_code , 
				" ", l_acct_name 
			END IF 

		BEFORE GROUP OF p_rec_rr.jour_num # PRINT heading at START OF each batch 

			IF glob_data_found THEN 
				IF glob_sum_det = 'D' THEN 

					PRINT COLUMN 5, p_rec_rr.jour_date , 
					COLUMN 20, p_rec_rr.jour_num USING "<<<<<<<<" 

				ELSE 
					PRINT COLUMN 5, p_rec_rr.jour_date , 
					COLUMN 20, p_rec_rr.jour_num USING "<<<<<<<<"; 
				END IF 
			END IF 

		ON EVERY ROW 

			IF glob_sum_det = "D" THEN 

				IF today < "01/01/2000" THEN 
					LET l_year = p_rec_rr.year_num - 1900 
				ELSE 
					LET l_year = p_rec_rr.year_num - 2000 
				END IF 

				PRINT COLUMN 5, l_year USING "&&" ; 
				PRINT COLUMN 8, p_rec_rr.period_num USING "##" ; 
				PRINT COLUMN 14, p_rec_rr.ref_text ; 
				PRINT COLUMN 35, p_rec_rr.tran_type ; 
				IF p_rec_rr.ref_num IS NOT NULL AND p_rec_rr.ref_num != 0 THEN 
					PRINT COLUMN 43, p_rec_rr.ref_num USING "<<<<<<<<" ; 
				ELSE 
					IF p_rec_rr.amt IS NOT NULL THEN 
						# must be a balancing entry
						PRINT COLUMN 43, "Balc Ent" ; 
					END IF 
				END IF 
				PRINT COLUMN 58, p_rec_rr.currency_code ; 
				PRINT COLUMN 66, p_rec_rr.fx_amt USING "((((,(((,(((,((&.&&)" ; 
				PRINT COLUMN 90, p_rec_rr.conv_qty USING "###&.&&&&" ; 
				PRINT COLUMN 102, p_rec_rr.amt USING "((((,(((,(((,((&.&&)" 
			END IF 

		AFTER GROUP OF p_rec_rr.jour_num 

			IF glob_data_found THEN 
				IF glob_sum_det = "D" THEN 
					NEED 3 LINES 

					PRINT COLUMN 66, "--------------------" , 
					COLUMN 102, "--------------------" 
					PRINT COLUMN 42, "Total FOR Batch ", 
					p_rec_rr.jour_num USING "<<<<<<<<" ; 
				ELSE 
					IF glob_sum_det = "S" THEN 
						PRINT " - total FOR batch"; 
					END IF 
				END IF 

				PRINT COLUMN 66, GROUP sum(p_rec_rr.fx_amt) 
				USING "((((,(((,(((,((&.&&)" , 
				COLUMN 102, GROUP sum(p_rec_rr.amt) 
				USING "((((,(((,(((,((&.&&)" 
			END IF 

		AFTER GROUP OF p_rec_rr.acct_code 

			IF glob_data_found THEN 
				NEED 4 LINES 
				SKIP 1 LINES 
				PRINT COLUMN 102, "--------------------" 

				PRINT COLUMN 1, "Total FOR Account ",p_rec_rr.acct_code , 
				COLUMN 102, GROUP sum(p_rec_rr.amt) USING "((((,(((,(((,((&.&&)" 
			END IF 

		ON LAST ROW 

			IF glob_data_found THEN 
				NEED 6 LINES 
				SKIP 2 LINES 
				PRINT COLUMN 102, "--------------------" 
				PRINT COLUMN 1, "Report Total" , 
				COLUMN 102, sum(p_rec_rr.amt) USING "((((,(((,(((,((&.&&)" 

				PRINT COLUMN 102, "====================" 
			ELSE 

				PRINT COLUMN 1, "No data met the selection criteria entered" 
				SKIP 1 line 
			END IF 

			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 

END REPORT 