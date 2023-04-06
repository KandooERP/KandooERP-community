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
GLOBALS "../common/glob_GLOBALS_report.4gl"  
GLOBALS "../gl/G_GL_GLOBALS.4gl"
GLOBALS "../gl/GR_GROUP_GLOBALS.4gl"
GLOBALS "../gl/GRF_GLOBALS.4gl" 
GLOBALS 
	DEFINE glob_q1_text STRING 
	DEFINE glob_where_part STRING -- CHAR(800) 
	DEFINE glob_query_text STRING -- CHAR(890) 
	DEFINE glob_debit_amt LIKE accounthist.debit_amt 
	DEFINE glob_credit_amt LIKE accounthist.credit_amt 
	DEFINE glob_open_amt LIKE account.open_amt 
	DEFINE glob_open_drcr LIKE account.open_amt 
	DEFINE glob_rept_curr_code LIKE batchdetl.currency_code 
	DEFINE glob_conv_qty LIKE rate_exchange.conv_sell_qty 
END GLOBALS 
############################################################
# FUNCTION GRF_main()
#
# Trial Balance - Pre-close amounts
############################################################
FUNCTION GRF_main() 
	DEFER quit 
	DEFER interrupt 
	
	CALL setModuleId("GRF") 
	CALL ui_init(0) #initial ui init 
	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_g_gl() #init g/gl general ledger module 

	OPEN WINDOW G188 with FORM "G188" 
	CALL windecoration_g("G188") 

		
	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 
			MENU " Trial Balance Pre-Close" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","GRF","menu-trial-balance-pre-close")
					CALL GRF_rpt_process(GRF_rpt_query()) 
					CALL rpt_rmsreps_reset(NULL)
		
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				ON ACTION "Report" #COMMAND "Report" " SELECT criteria AND PRINT REPORT"
					CALL GRF_rpt_process(GRF_rpt_query())
					CALL rpt_rmsreps_reset(NULL)
		
				ON ACTION "Print Manager" #COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "Exit" #COMMAND KEY(interrupt, "E")"Exit" " Exit TO menus"
					EXIT MENU 
		
			END MENU 
		
			CLOSE WINDOW G188 

		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL GRF_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW G188 with FORM "G188" 
			CALL windecoration_g("G188") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(GRF_rpt_query()) #save where clause in env 
			CLOSE WINDOW G188 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL GRF_rpt_process(get_url_sel_text())
	END CASE 				
END FUNCTION 


############################################################
# FUNCTION GRF_rpt_query()
#
#
############################################################
FUNCTION GRF_rpt_query() 
	DEFINE l_where_text STRING
	DEFINE l_exist SMALLINT 
	DEFINE l_acct_found SMALLINT 
	DEFINE l_rec_accounthist RECORD LIKE accounthist.* 
	DEFINE l_rec_accounthistcur RECORD LIKE accounthistcur.* 
	DEFINE l_rec_glparms RECORD LIKE glparms.* 
	DEFINE l_str CHAR (2000) 
	DEFINE l_query_text STRING 
	DEFINE l_multi_currency_used CHAR(1) #Y/N  
	 
	IF glob_rec_glparms.style_ind = 1 THEN 
		LET glob_rec_glparms.style_ind = 7 
	END IF 

	MESSAGE kandoomsg2("U",1001,"")
	#--------------------------------
	# Consruct 1 = l_where_text ON year_num, period_num
	# with and without currency
	#--------------------------------
	 
	#1001 Enter selection criteria; OK TO continue.
	IF l_rec_glparms.use_currency_flag != "Y" THEN
		LET l_multi_currency_used = "N" 
		CONSTRUCT BY NAME l_where_text ON year_num, period_num 
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","GRF","construct-year1") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null)
				 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
		END CONSTRUCT 

	ELSE 
		CONSTRUCT BY NAME l_where_text ON year_num, 
		period_num, 
		currency_code 
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","GRF","construct-year2") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar()
			
		END CONSTRUCT 

	END IF 

	IF int_flag OR quit_flag THEN 
		LET int_flag = 0 
		LET quit_flag = 0 
		RETURN NULL
	ELSE
		IF l_where_text matches "*currency_code*" THEN
			LET l_multi_currency_used = "Y"
		ELSE
			LET l_multi_currency_used = "N"
		END IF
		LET glob_rec_rpt_selector.ref1_ind =  l_multi_currency_used
--		RETURN l_where_text
	END IF 
	# add on the search dimension of segments.......


	IF l_multi_currency_used = "Y" THEN # matches "*currency_code*" THEN 
		CALL segment_con(glob_rec_kandoouser.cmpy_code, "accounthistcur") 
		RETURNING glob_q1_text 
		IF int_flag 
		OR quit_flag 
		OR glob_q1_text IS NULL THEN 
			LET int_flag = 0 
			LET quit_flag = 0 
			RETURN 
		END IF 
	ELSE #l_multi_currency_used = "N"
		CALL segment_con(glob_rec_kandoouser.cmpy_code, "accounthist") 
		RETURNING glob_q1_text 
		IF int_flag 
		OR quit_flag 
		OR glob_q1_text IS NULL THEN 
			LET int_flag = 0 
			LET quit_flag = 0 
			RETURN 
		END IF 
		LET glob_rept_curr_code = l_rec_glparms.base_currency_code 
		LET glob_conv_qty = 1.0 
	END IF 

	LET l_where_text = l_where_text clipped, glob_q1_text 
	LET l_acct_found = 0 
	
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		MESSAGE "Report Query aborted"
		RETURN NULL 
	ELSE
		LET glob_rec_rpt_selector.ref2_code = l_rec_glparms.base_currency_code #glob_rept_curr_code
		LET glob_rec_rpt_selector.ref1_factor = 1.0 #glob_conv_qty
		LET glob_rec_rpt_selector.ref1_ind = l_multi_currency_used
		RETURN l_where_text
	END IF	
END FUNCTION	
	

############################################################
# FUNCTION GRF_rpt_process() 
#
#
############################################################
FUNCTION GRF_rpt_process(p_where_text)
	DEFINE p_where_text STRING 
	DEFINE l_rpt_idx SMALLINT  
	DEFINE l_query_text STRING 
	 
--	DEFINE l_where_text STRING
	DEFINE l_exist SMALLINT 
	DEFINE l_acct_found SMALLINT 
	DEFINE l_rec_accounthist RECORD LIKE accounthist.* 
	DEFINE l_rec_accounthistcur RECORD LIKE accounthistcur.* 
	DEFINE l_rec_glparms RECORD LIKE glparms.* 
	DEFINE l_str CHAR (2000) 
	DEFINE l_multi_currency_used CHAR(1) #Y/N 


	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false
		RETURN FALSE
	END IF

	#Special: We need ref1_ind xxx to decide, what report is used/generated
	IF get_url_report_code() IS NOT NULL THEN
		LET l_multi_currency_used = db_rmsreps_get_ref1_ind(UI_OFF,get_url_report_code()) #from db
	ELSE
		LET l_multi_currency_used = glob_rec_rpt_selector.ref1_ind #from construct
	END IF

	IF l_multi_currency_used = "Y" THEN #MULTI CURRENCY
		LET l_rpt_idx = rpt_start("GRF-CURR","GRF_rpt_list_currency",p_where_text, RPT_SHOW_RMS_DIALOG)
		IF l_rpt_idx = 0 THEN #User pressed CANCEL
			RETURN FALSE
		END IF	
		START REPORT GRF_rpt_list_currency TO rpt_get_report_file_with_path2(l_rpt_idx)
		WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0
		LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GRF_rpt_list_currency")].sel_text
	ELSE #SINGLE Currency
		LET l_rpt_idx = rpt_start("GRF","GRF_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
		IF l_rpt_idx = 0 THEN #User pressed CANCEL
			RETURN FALSE
		END IF	
		START REPORT GRF_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
		WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0
		LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GRF_rpt_list")].sel_text
	
	END IF

	#Values from rmsreps
	LET glob_rept_curr_code = glob_rec_rpt_selector.ref2_code #= l_rec_glparms.base_currency_code #glob_rept_curr_code
	#LET l_rec_glparms.base_currency_code = glob_rec_rpt_selector.ref2_code =  #glob_rept_curr_code
	LET glob_conv_qty = glob_rec_rpt_selector.ref1_factor #= 1.0 #glob_conv_qty
	LET l_multi_currency_used = glob_rec_rpt_selector.ref1_ind 
		
	#----------------------------------------------------------
	# MULTI CURRENCY
	#----------------------------------------------------------
	
	IF l_multi_currency_used = "Y" THEN --glob_where_part matches "*currency_code*" THEN 

		#LET l_query_text = "SELECT * FROM accounthistcur ",
		# prepare main query from the construct
		LET l_query_text = "SELECT * FROM accounthistcur ", 
		" WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\"", 
		" AND ",p_where_text clipped, 
		" ORDER BY currency_code,year_num,period_num,acct_code" 
		PREPARE s_accounthistcur FROM l_query_text 

		# prepare second query (accountcur outer accountledger) with place holders ( just once, not in every iteration of the foreach loop )
		LET l_query_text = "SELECT a.open_amt , sum(l.for_debit_amt) - sum(l.for_credit_amt) ", 
		" FROM accountcur a, outer accountledger l ", 
		" WHERE a.cmpy_code = ? ", # l_rec_accounthistcur.cmpy_code, 
		" AND a.acct_code = ? ", # l_rec_accounthistcur.acct_code, 
		" AND a.currency_code = ? ", # l_rec_accounthistcur.currency_code, 
		" AND a.cmpy_code = l.cmpy_code ", 
		" AND a.acct_code = l.acct_code ", 
		" AND a.currency_code = l.currency_code ", 
		" AND a.year_num = ? ", # l_rec_accounthistcur.year_num, 
		" AND a.year_num = l.year_num ", 
		" AND l.period_num < ? ", #l_rec_accounthistcur.period_num, 
		" AND tran_type_ind != 'CL' ", 
		" GROUP BY a.open_amt " 
		PREPARE p_acccur_outer_accledger FROM l_query_text 
		DECLARE c_acccur_outer_accledger CURSOR FOR p_acccur_outer_accledger 
		# execute immediate l_str


		DECLARE c_accounthistcur CURSOR FOR s_accounthistcur 
		FOREACH c_accounthistcur INTO l_rec_accounthistcur.* 
			SELECT sum(for_debit_amt), sum(for_credit_amt) 
			INTO glob_debit_amt, glob_credit_amt 
			FROM accountledger 
			WHERE cmpy_code = l_rec_accounthistcur.cmpy_code 
			AND acct_code = l_rec_accounthistcur.acct_code 
			AND year_num = l_rec_accounthistcur.year_num 
			AND period_num = l_rec_accounthistcur.period_num 
			AND currency_code = l_rec_accounthistcur.currency_code 
			AND tran_type_ind != "CL" 
			IF glob_debit_amt IS NULL THEN 
				LET glob_debit_amt = 0 
			END IF 
			IF glob_credit_amt IS NULL THEN 
				LET glob_credit_amt = 0 
			END IF 
			LET glob_open_amt = 0 

			#DISPLAY "EXIT: disabled code because of <Anton Dickinson> ecp issue with OUTER"
			#DISPLAY "see gl/GRF.4gl"
			#EXIT PROGRAM (1)
			# replaced the prepare/declare execute by a open using, query prepared out of the loop
			OPEN c_acccur_outer_accledger 
			USING l_rec_accounthistcur.cmpy_code, 
			l_rec_accounthistcur.acct_code, 
			l_rec_accounthistcur.currency_code, 
			l_rec_accounthistcur.year_num, 
			l_rec_accounthistcur.period_num 

			FETCH c_acccur_outer_accledger 
			INTO glob_open_amt, glob_open_drcr 

			IF glob_open_amt IS NULL THEN 
				LET glob_open_amt = 0 
			END IF 
			IF glob_open_drcr IS NULL THEN 
				LET glob_open_drcr = 0 
			END IF 
			LET glob_open_amt = glob_open_amt + glob_open_drcr 
			LET l_acct_found = 1


			#---------------------------------------------------------
			OUTPUT TO REPORT GRF_rpt_list_currency(l_rpt_idx,
				l_rec_accounthistcur.*, l_rec_glparms.*, 
				glob_debit_amt, glob_credit_amt, glob_open_amt)  
			IF NOT rpt_int_flag_handler2("Account:",l_rec_accounthistcur.acct_code, NULL,l_rpt_idx) THEN
				EXIT FOREACH 
			END IF 
			#---------------------------------------------------------			
		END FOREACH 

		#------------------------------------------------------------
		FINISH REPORT GRF_rpt_list_currency
		CALL rpt_finish("GRF_rpt_list_currency")
		#------------------------------------------------------------


	#----------------------------------------------------------
	# SINGLE CURRENCY
	#----------------------------------------------------------

	ELSE 

		#      OPEN WINDOW wfGL WITH FORM "U999" ATTRIBUTES(BORDER)
		#		CALL windecoration_u("U999")
--		IF glob_where_part IS NULL 
--		OR glob_where_part = " " THEN 
--			LET glob_where_part = "1=1" 
--		END IF 
		LET l_query_text = "SELECT * FROM accounthist ", 
		" WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"'", 
		" AND ",p_where_text clipped, " ", 
		" ORDER BY year_num, period_num, acct_code" 
		PREPARE s_accounthist FROM l_query_text 

		# prepare second query out of the foreach loop
		LET l_query_text = " SELECT a.open_amt , sum(l.debit_amt) - sum(l.credit_amt) ", 
		" FROM account a, outer accountledger l ", 
		" WHERE a.cmpy_code = ? ", # l_rec_accounthist.cmpy_code 
		" AND a.acct_code = ? ", # l_rec_accounthist.acct_code, 
		" AND a.cmpy_code = l.cmpy_code ", 
		" AND a.acct_code = l.acct_code ", 
		" AND a.year_num = ? ", # l_rec_accounthist.year_num, 
		" AND a.year_num = l.year_num ", 
		" AND l.period_num < ? ", # l_rec_accounthist.period_num, 
		" AND tran_type_ind != 'CL' ", 
		" GROUP BY a.open_amt" 
		PREPARE p_accnt_outer_accledger FROM l_query_text 
		DECLARE c_accnt_outer_accledger CURSOR FOR p_accnt_outer_accledger 


		DECLARE c_accounthist CURSOR FOR s_accounthist 
		FOREACH c_accounthist INTO l_rec_accounthist.* 
			SELECT sum(debit_amt), sum(credit_amt) 
			INTO glob_debit_amt, glob_credit_amt 
			FROM accountledger 
			WHERE cmpy_code = l_rec_accounthist.cmpy_code 
			AND acct_code = l_rec_accounthist.acct_code 
			AND year_num = l_rec_accounthist.year_num 
			AND period_num = l_rec_accounthist.period_num 
			AND tran_type_ind != "CL" 

			IF glob_debit_amt IS NULL THEN 
				LET glob_debit_amt = 0 
			END IF 
			IF glob_credit_amt IS NULL THEN 
				LET glob_credit_amt = 0 
			END IF 
			LET glob_open_amt = 0 

			#ERROR "EXIT: disabled code because of <Anton Dickinson> ecp issue with OUTER - see gl/GRF.4gl"

			#EXIT PROGRAM (1)
			# open using instead of prepare execute immediate everytime
			OPEN c_accnt_outer_accledger 
			USING l_rec_accounthist.cmpy_code, 
			l_rec_accounthist.acct_code, 
			l_rec_accounthist.year_num, 
			l_rec_accounthist.period_num 
			FETCH c_accnt_outer_accledger 
			INTO glob_open_amt, glob_open_drcr 

			IF glob_open_amt IS NULL THEN 
				LET glob_open_amt = 0 
			END IF 
			IF glob_open_drcr IS NULL THEN 
				LET glob_open_drcr = 0 
			END IF 
			LET glob_open_amt = glob_open_amt + glob_open_drcr 
			LET l_acct_found = 1 
			LET glob_open_amt = glob_open_amt * glob_conv_qty 
			LET glob_debit_amt = glob_debit_amt * glob_conv_qty 
			LET glob_credit_amt = glob_credit_amt * glob_conv_qty 
			LET l_rec_accounthist.pre_close_amt = l_rec_accounthist.pre_close_amt * 
			glob_conv_qty 
			
			#---------------------------------------------------------
			OUTPUT TO REPORT GRF_rpt_list(l_rpt_idx,
				l_rec_accounthistcur.*, l_rec_glparms.*, 
				glob_debit_amt, glob_credit_amt, glob_open_amt)  
			IF NOT rpt_int_flag_handler2("Account:",l_rec_accounthistcur.acct_code, NULL,l_rpt_idx) THEN
				EXIT FOREACH 
			END IF 
			#---------------------------------------------------------		
		END FOREACH 

		#------------------------------------------------------------
		FINISH REPORT GRF_rpt_list
		CALL rpt_finish("GRF_rpt_list")
		#------------------------------------------------------------

	END IF 


	IF int_flag THEN
		MESSAGE "Report Generation Canceled..."
		RETURN FALSE
	ELSE
		RETURN TRUE
	END IF 	
END FUNCTION 




############################################################
# REPORT GRF_rpt_list(p_rec_accounthist, p_rec_glparms, p_debit_amt, p_credit_amt, p_open_amt)
#
#
############################################################
REPORT GRF_rpt_list(p_rpt_idx,p_rec_accounthist, p_rec_glparms, p_debit_amt, p_credit_amt, p_open_amt) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_accounthist RECORD LIKE accounthist.* 
	DEFINE p_rec_glparms RECORD LIKE glparms.* 
	DEFINE p_debit_amt LIKE accounthist.debit_amt 
	DEFINE p_credit_amt LIKE accounthist.credit_amt 
	DEFINE p_open_amt LIKE account.open_amt 

	DEFINE l_rec_coa RECORD LIKE coa.* 

	DEFINE l_summary_only CHAR(1) 
	#	DEFINE l_sum_open_amt DECIMAL (16,2)
	#	DEFINE l_sum_debit_amt DECIMAL (16,2)
	#	DEFINE l_sum_credit_amt DECIMAL (16,2)
	#	DEFINE l_sum_close_amt DECIMAL (16,2)
	DEFINE l_close_amt DECIMAL (16,2) 
	DEFINE l_grp_close_amt DECIMAL (16,2) 
	DEFINE l_grp_open_amt DECIMAL (16,2) 

	OUTPUT 
	left margin 0 
	ORDER external BY p_rec_accounthist.year_num, 
	p_rec_accounthist.period_num, 
	p_rec_accounthist.acct_code 
	FORMAT 
		PAGE HEADER
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 1, " Values in currency : ", glob_rept_curr_code, 
			10 SPACE,
			" Exchange rate : ", glob_conv_qty USING "<<<.<<<" 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

			PRINT COLUMN 1, "Account", 
			COLUMN 72, "Opening", 
			COLUMN 91, "Period", 
			COLUMN 108, "Period", 
			COLUMN 127, "Ending" 
			PRINT COLUMN 1, "Number", 
			COLUMN 20, "Description", 
			COLUMN 72, "Balance", 
			COLUMN 91, "Debits", 
			COLUMN 108, "Credits", 
			COLUMN 126, "Balance" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

		BEFORE GROUP OF p_rec_accounthist.period_num 
			SKIP TO top OF PAGE 
			PRINT "Year: ", p_rec_accounthist.year_num USING "####", 
			2 spaces, "Period: ", p_rec_accounthist.period_num USING "####" 
			SKIP 1 line 
			
		ON EVERY ROW 
			NEED 2 LINES 
			SELECT * INTO l_rec_coa.* FROM coa 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND acct_code = p_rec_accounthist.acct_code 
			IF p_open_amt = 0 
			AND p_debit_amt = 0 
			AND p_credit_amt = 0 
			AND p_rec_accounthist.pre_close_amt = 0 THEN 
			ELSE 
				LET l_close_amt = p_rec_accounthist.pre_close_amt + p_open_amt 
				PRINT COLUMN 1, p_rec_accounthist.acct_code , 
				COLUMN 20, l_rec_coa.desc_text[1,40], 
				COLUMN 62, p_open_amt USING "--,---,---,--&.&&", 
				COLUMN 80, p_debit_amt USING "--,---,---,--&.&&", 
				COLUMN 98, p_credit_amt USING "--,---,---,--&.&&", 
				COLUMN 116, l_close_amt USING "--,---,---,--&.&&" 
				LET l_rec_coa.desc_text = NULL 
			END IF
			 
		ON LAST ROW 
			SKIP 1 line 
			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_option1 clipped wordwrap right margin 100				
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 


		AFTER GROUP OF p_rec_accounthist.period_num 
			IF GROUP sum(p_open_amt) = 0 AND 
			GROUP sum(p_debit_amt) = 0 AND 
			GROUP sum(p_credit_amt) = 0 AND 
			GROUP sum(p_rec_accounthist.pre_close_amt) = 0 THEN 
			ELSE 
				LET l_grp_open_amt = GROUP sum(p_open_amt) 
				LET l_grp_close_amt = GROUP sum(p_rec_accounthist.pre_close_amt 
				+ p_open_amt) 
				SKIP 1 line 
				PRINT COLUMN 1, "Period Total:", 
				COLUMN 62, l_grp_open_amt USING "--,---,---,--&.&&", 
				COLUMN 80, GROUP sum(p_debit_amt) USING "--,---,---,--&.&&", 
				COLUMN 98, GROUP sum(p_credit_amt) USING "--,---,---,--&.&&", 
				COLUMN 116,l_grp_close_amt USING "--,---,---,--&.&&" 
			END IF 

END REPORT 


############################################################
# REPORT GRF_rpt_list_currency(p_rpt_idx,p_rec_accounthistcur, p_rec_glparms, p_debit_amt, p_credit_amt, p_open_amt)
#
#
############################################################
REPORT GRF_rpt_list_currency(p_rpt_idx,p_rec_accounthistcur, p_rec_glparms, p_debit_amt, p_credit_amt, p_open_amt)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	 
	DEFINE p_rec_accounthistcur RECORD LIKE accounthistcur.* 
	DEFINE p_rec_glparms RECORD LIKE glparms.* 
	DEFINE p_debit_amt LIKE accounthist.debit_amt 
	DEFINE p_credit_amt LIKE accounthist.credit_amt 
	DEFINE p_open_amt LIKE account.open_amt 
	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_summary_only CHAR(1) 
	DEFINE l_sum_open_amt DECIMAL (16,2) 
	DEFINE l_sum_debit_amt DECIMAL (16,2) 
	DEFINE l_sum_credit_amt DECIMAL (16,2) 
	DEFINE l_sum_close_amt DECIMAL (16,2) 
	DEFINE l_close_amt DECIMAL (16,2) 
	DEFINE l_grp_close_amt DECIMAL (16,2) 
	DEFINE l_grp_open_amt DECIMAL (16,2) 


	OUTPUT 
--	left margin 0 
	ORDER external BY p_rec_accounthistcur.currency_code, 
	p_rec_accounthistcur.year_num, 
	p_rec_accounthistcur.period_num, 
	p_rec_accounthistcur.acct_code 

	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 01, " Values in currency : ",	p_rec_accounthistcur.currency_code 
 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 1, "Account", 
			COLUMN 72, "Opening", 
			COLUMN 91, "Period", 
			COLUMN 109, "Period", 
			COLUMN 127, "Ending" 
			PRINT COLUMN 1, "Number", 
			COLUMN 20, "Description", 
			COLUMN 72, "Balance", 
			COLUMN 91, "Debits", 
			COLUMN 108, "Credits", 
			COLUMN 126, "Balance" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		BEFORE GROUP OF p_rec_accounthistcur.currency_code 
			SKIP TO top OF PAGE 
			PRINT "Currency: ", p_rec_accounthistcur.currency_code 
			SKIP 1 line 

		BEFORE GROUP OF p_rec_accounthistcur.period_num 
			SKIP 1 line 
			PRINT "Year: ", p_rec_accounthistcur.year_num USING "####", 
			2 spaces, "Period: ", p_rec_accounthistcur.period_num USING "####" 
			SKIP 1 line 

		ON EVERY ROW 
			SELECT * INTO l_rec_coa.* FROM coa 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND acct_code = p_rec_accounthistcur.acct_code 
			IF (p_open_amt = 0) 
			AND (p_debit_amt = 0) 
			AND (p_credit_amt = 0) 
			AND (p_rec_accounthistcur.pre_close_amt = 0) THEN 
			ELSE 
				LET l_close_amt = p_rec_accounthistcur.pre_close_amt + p_open_amt 
				PRINT COLUMN 1, p_rec_accounthistcur.acct_code, 
				COLUMN 20, l_rec_coa.desc_text[1,40], 
				COLUMN 62, p_open_amt USING "--,---,---,--&.&&", 
				COLUMN 80, p_debit_amt USING "--,---,---,--&.&&", 
				COLUMN 98, p_credit_amt USING "--,---,---,--&.&&", 
				COLUMN 116, l_close_amt USING "--,---,---,--&.&&" 
				LET l_rec_coa.desc_text = NULL 
			END IF 

		ON LAST ROW 
			SKIP 1 line 
			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_option1 clipped wordwrap right margin 100 

			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 


		AFTER GROUP OF p_rec_accounthistcur.period_num 
			IF GROUP sum(p_open_amt) = 0 AND 
			GROUP sum(p_debit_amt) = 0 AND 
			GROUP sum(p_credit_amt) = 0 AND 
			GROUP sum(p_rec_accounthistcur.pre_close_amt) = 0 THEN 
			ELSE 
				LET l_grp_open_amt = GROUP sum(p_open_amt) 
				LET l_grp_close_amt = GROUP sum(p_rec_accounthistcur.pre_close_amt 
				+ p_open_amt) 
				SKIP 1 line 
				PRINT COLUMN 1, "Period Total:", 
				COLUMN 62, l_grp_open_amt USING "--,---,---,--&.&&", 
				COLUMN 80, GROUP sum(p_debit_amt) USING "--,---,---,--&.&&", 
				COLUMN 98, GROUP sum(p_credit_amt) USING "--,---,---,--&.&&", 
				COLUMN 116,l_grp_close_amt USING "--,---,---,--&.&&" 
			END IF 

		AFTER GROUP OF p_rec_accounthistcur.currency_code 
			IF GROUP sum(p_open_amt) = 0 AND 
			GROUP sum(p_debit_amt) = 0 AND 
			GROUP sum(p_credit_amt) = 0 AND 
			GROUP sum(p_rec_accounthistcur.pre_close_amt) = 0 THEN 
			ELSE 
				LET l_grp_open_amt = GROUP sum(p_open_amt) 
				LET l_grp_close_amt = GROUP sum(p_rec_accounthistcur.pre_close_amt 
				+ p_open_amt) 
				SKIP 1 line 
				PRINT COLUMN 1, "Currency Total:", 
				COLUMN 62, l_grp_open_amt USING "--,---,---,--&.&&", 
				COLUMN 80, GROUP sum(p_debit_amt) USING "--,---,---,--&.&&", 
				COLUMN 98, GROUP sum(p_credit_amt) USING "--,---,---,--&.&&", 
				COLUMN 116,l_grp_close_amt USING "--,---,---,--&.&&" 
			END IF 

END REPORT 
