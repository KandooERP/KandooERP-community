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
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/PC_GROUP_GLOBALS.4gl"
############################################################
# FUNCTION PC4_main()
# RETURN VOID
#
# PC4 - Cheque by Cancellation Report
############################################################
FUNCTION PC4_main()

	CALL setModuleId("PC4") 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query 
		WHEN RPT_OP_MENU #UI/MENU Mode

			OPEN WINDOW P163 with FORM "P163" 
			CALL windecoration_p("P163") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

			MENU " Cancelled Cheques" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","PC4","menu-cancelled_cheque-1") 
					CALL PC4_rpt_process(PC4_rpt_query())

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				ON ACTION "Report" #COMMAND "Report" " SELECT criteria AND PRINT REPORT"
					CALL PC4_rpt_process(PC4_rpt_query()) 

				ON ACTION "Print Manager" #COMMAND KEY ("P",f11) "Print" " Print OR view using RMS" 
					CALL run_prog("URS","","","","") 

				ON ACTION "CANCEL" #COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus"
					EXIT MENU 

			END MENU 
			CLOSE WINDOW P163 

		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL PC4_rpt_process(NULL) # (NULL query-where-part will read report_code from URL

		WHEN RPT_OP_CONSTRUCT 
			OPEN WINDOW P163 with FORM "P163" 
			CALL windecoration_p("P163") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL PC4_rpt_query()
			CALL set_url_sel_text(PC4_rpt_query()) #save where clause in env 
			CLOSE WINDOW P163
			 
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL PC4_rpt_process(get_url_sel_text())
	END CASE 

END FUNCTION 
############################################################
# END FUNCTION PC4_main()
############################################################


############################################################
# FUNCTION PC4_rpt_query()
# RETURN l_ret_sql_sel_text #WHERE part also stored in rmsreps.sel_text
# 
# DataSource for the report driver with CONSTRUCT
############################################################
FUNCTION PC4_rpt_query() 
	DEFINE l_ret_sql_sel_text LIKE rmsreps.sel_text
	DEFINE l_query_text STRING
--	DEFINE l_msgresp LIKE language.yes_flag
	
	CLEAR FORM 
	MESSAGE kandoomsg2("U",1001,"")	#1001 Enter Selection Criteria - OK TO Continue
	CONSTRUCT BY NAME l_ret_sql_sel_text ON bank_code, 
	bank_acct_code, 
	vend_code, 
	cheq_code, 
	pay_amt, 
	net_pay_amt, 
	cheq_date, 
	orig_posted_flag, 
	orig_year_num, 
	orig_period_num, 
	cancel_year_num, 
	cancel_period_num, 
	cancel_jour_num, 
	com1_text, 
	com2_text 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","PC4","construct-rmsreps-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		LET l_ret_sql_sel_text = NULL
	END IF 

	RETURN l_ret_sql_sel_text
END FUNCTION 
############################################################
# END FUNCTION PC4_rpt_query() 
############################################################

############################################################
# FUNCTION PC4_rpt_process()
# RETURN rpt_finish("PC4_rpt_list")
# 
# The report driver
############################################################
FUNCTION PC4_rpt_process(p_where_text) 
	DEFINE p_where_text STRING
	DEFINE l_rpt_idx SMALLINT #report array index
	DEFINE l_query_text STRING

	DEFINE l_rec_cancelcheq RECORD LIKE cancelcheq.* 
	DEFINE l_base_amt LIKE cancelcheq.pay_amt 
	DEFINE l_base_net_amt LIKE cancelcheq.net_pay_amt
 
	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start(getmoduleid(),"PC4_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT PC4_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0
	#------------------------------------------------------------

	LET l_query_text = " SELECT * FROM cancelcheq ", 
	" WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\"", 
	" AND ",glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("PC4_rpt_list")].sel_text clipped, 
	" ORDER BY bank_code, cheq_code " 
	
	PREPARE s_cancelcheq FROM l_query_text 
	DECLARE c_cancelcheq CURSOR FOR s_cancelcheq 
	
	FOREACH c_cancelcheq INTO l_rec_cancelcheq.* 
		LET l_base_amt = l_rec_cancelcheq.pay_amt / l_rec_cancelcheq.orig_conv_qty 
		LET l_base_net_amt = l_rec_cancelcheq.net_pay_amt / l_rec_cancelcheq.orig_conv_qty

		#------------------------------------------------------------
		OUTPUT TO REPORT PC4_rpt_list(rpt_rmsreps_idx_get_idx("PC4_rpt_list"),l_rec_cancelcheq.*, l_base_amt, l_base_net_amt) 
		IF NOT rpt_int_flag_handler2("Bank ID",l_rec_cancelcheq.bank_code,  l_rec_cancelcheq.cheq_code,rpt_rmsreps_idx_get_idx("PC4_rpt_list")) THEN
			EXIT FOREACH 
		END IF 
		#------------------------------------------------------------

	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT PC4_rpt_list
	RETURN rpt_finish("PC4_rpt_list")
	#------------------------------------------------------------

END FUNCTION 
############################################################
# END FUNCTION PC4_rpt_process()
############################################################

############################################################
# REPORT PC4_rpt_list(p_rpt_idx,p_rec_cancelcheq,p_base_amt,p_base_net_amt) 
#
# Report Definition/Layout
############################################################
REPORT PC4_rpt_list(p_rpt_idx,p_rec_cancelcheq,p_base_amt,p_base_net_amt) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_cancelcheq RECORD LIKE cancelcheq.*
	DEFINE p_base_amt LIKE cancelcheq.pay_amt
	DEFINE p_base_net_amt LIKE cancelcheq.net_pay_amt 
	DEFINE l_rec_bank RECORD LIKE bank.* 
	DEFINE l_name_text LIKE vouchpayee.name_text 


	OUTPUT 
--	left margin 0 
	ORDER external BY p_rec_cancelcheq.bank_code, p_rec_cancelcheq.cheq_code 
	
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno)  #update page number
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]
			
		BEFORE GROUP OF p_rec_cancelcheq.bank_code 
			SELECT * INTO l_rec_bank.* FROM bank 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
			bank_code = p_rec_cancelcheq.bank_code 
			PRINT COLUMN 01, "Bank ID: ", p_rec_cancelcheq.bank_code, " ", 
			l_rec_bank.name_acct_text, " ", 
			"GL Account Code: ", p_rec_cancelcheq.bank_acct_code 
			SKIP 1 line 
			
		ON EVERY ROW 
			PRINT COLUMN 01, p_rec_cancelcheq.cheq_code USING "#########", 
			COLUMN 12, p_rec_cancelcheq.vend_code, 
			COLUMN 21, p_rec_cancelcheq.orig_posted_flag, 
			COLUMN 29, p_rec_cancelcheq.orig_year_num USING "####","/", 
			COLUMN 34, p_rec_cancelcheq.orig_period_num USING "<<#", 
			COLUMN 40, p_rec_cancelcheq.cheq_date USING "dd/mm/yy", 
			COLUMN 50, p_rec_cancelcheq.orig_curr_code, 
			COLUMN 54, p_rec_cancelcheq.pay_amt USING "----,---,---.&&", 
			COLUMN 70, p_rec_cancelcheq.net_pay_amt USING "----,---,---.&&", 
			COLUMN 87, p_rec_cancelcheq.cancel_year_num USING "####", "/", 
			COLUMN 91, p_rec_cancelcheq.cancel_period_num USING "<<#", 
			COLUMN 95, p_rec_cancelcheq.cancel_jour_num USING "######&", 
			COLUMN 103, p_rec_cancelcheq.com1_text 
			
			IF p_rec_cancelcheq.source_ind = "S" THEN 
				SELECT name_text INTO l_name_text FROM vouchpayee 
				WHERE vouchpayee.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND vouchpayee.vend_code = p_rec_cancelcheq.vend_code 
				AND vouchpayee.vouch_code = p_rec_cancelcheq.source_text 
				PRINT COLUMN 12, l_name_text 
			END IF 
			
		AFTER GROUP OF p_rec_cancelcheq.bank_code 
			PRINT COLUMN 54, "---------------" , 
			COLUMN 70, "---------------" 
			PRINT COLUMN 10, "Bank Total in ", l_rec_bank.currency_code, ": "; 
			IF l_rec_bank.currency_code != glob_rec_glparms.base_currency_code THEN 
				PRINT COLUMN 54, GROUP sum(p_rec_cancelcheq.pay_amt) USING "----,---,---.&&", 
				COLUMN 70, GROUP sum(p_rec_cancelcheq.net_pay_amt) USING "----,---,---.&&" 
			ELSE 
				PRINT COLUMN 54, GROUP sum(p_base_amt) USING "----,---,---.&&", 
				COLUMN 70, GROUP sum(p_base_net_amt) USING "----,---,---.&&" 
			END IF 
			SKIP 1 LINES 
			
		ON LAST ROW 
			PRINT COLUMN 54, "---------------" , 
			COLUMN 70, "---------------" 
			PRINT COLUMN 10, "Report Totals in Base Currency: ", 
			COLUMN 54, sum(p_base_amt) USING "----,---,---.&&", 
			COLUMN 70, sum(p_base_net_amt) USING "----,---,---.&&" 
			SKIP 2 line
			
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN #Optional Query Where part print
				PRINT COLUMN 01,"Selection Criteria:"
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100
			END IF
			#End Of Report
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #Let's use the same END of report line whenever it's required/possible			

END REPORT
############################################################
# END REPORT PC4_rpt_list(p_rpt_idx,p_rec_cheque) 
############################################################