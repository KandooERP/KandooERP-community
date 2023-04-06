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
GLOBALS "../ar/A_AR_GLOBALS.4gl"
GLOBALS "../ar/AC_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/AC2_GLOBALS.4gl"
############################################################
# MODULE Scope Variables
############################################################
DEFINE modu_tot_amt DECIMAL(16,2) #Will be incremented/added in actual report block 
#####################################################################
# FUNCTION AC2_main()
#
# AC2 Cash Receipts By Number
#####################################################################
FUNCTION AC2_main() 
	DEFER quit 
	DEFER interrupt
	
	CALL setModuleId("AC2") 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 	
			OPEN WINDOW A148 with FORM "A148" 
			CALL windecoration_a("A148")
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

			MENU " Cash Receipt by Number" 

				BEFORE MENU 
					CALL publish_toolbar("kandoo","AC2","menu-cash-receipt-number") 
					CALL AC2_rpt_process(AC2_rpt_query())
					
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				ON ACTION "Report" #COMMAND "Run" " Enter selection criteria AND generate REPORT"
					CALL AC2_rpt_process(AC2_rpt_query()) 

				ON ACTION "Print Manager"		#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "CANCEL"#COMMAND KEY("E",interrupt)"Exit" " Exit TO menus"
					EXIT MENU 


			END MENU 
			CLOSE WINDOW A148 

		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL AC2_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW A148 with FORM "A148" 
			CALL windecoration_a("A148") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(AC2_rpt_query()) #save where clause in env 
			CLOSE WINDOW A148 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL AC2_rpt_process(get_url_sel_text())
	END CASE 

END FUNCTION 
#####################################################################
# END FUNCTION AC2_main()
#####################################################################


#####################################################################
# FUNCTION AC2_rpt_query()
#
#
#####################################################################
FUNCTION AC2_rpt_query() 
	DEFINE l_where_text STRING

	MESSAGE kandoomsg2("U",1001,"")	#1001 Enter Selection Criteria - ESC TO Continue "
	CONSTRUCT BY NAME l_where_text ON cashreceipt.cust_code, 
	customer.name_text, 
	cashreceipt.cash_num, 
	cashreceipt.cash_date, 
	cashreceipt.order_num, 
	cashreceipt.cash_type_ind, 
	customer.currency_code, 
	cashreceipt.cash_amt, 
	cashreceipt.applied_amt, 
	cashreceipt.disc_amt, 
	cashreceipt.banked_flag, 
	cashreceipt.locn_code, 
	cashreceipt.on_state_flag, 
	cashreceipt.year_num, 
	cashreceipt.period_num, 
	cashreceipt.posted_flag, 
	cashreceipt.bank_code, 
	cashreceipt.cash_acct_code, 
	cashreceipt.bank_text, 
	cashreceipt.cheque_text, 
	cashreceipt.chq_date, 
	cashreceipt.bank_dep_num, 
	cashreceipt.banked_date, 
	cashreceipt.drawer_text, 
	cashreceipt.branch_text, 
	cashreceipt.com1_text, 
	cashreceipt.com2_text, 
	cashreceipt.entry_code, 
	cashreceipt.entry_date 


		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","AC2","construct-cashreceipt") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL
	ELSE
		RETURN l_where_text
	END IF 
END FUNCTION 
#####################################################################
# END FUNCTION AC2_rpt_query()
#####################################################################


#####################################################################
# FUNCTION AC2_rpt_process()
#
#
#####################################################################
FUNCTION AC2_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT   
	DEFINE l_rec_cashreceipt RECORD LIKE cashreceipt.* 

	LET modu_tot_amt = 0 
	LET glob_tot_appl = 0 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"AC2_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT AC2_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	LET l_query_text = "SELECT cashreceipt.* FROM cashreceipt, customer ", 
	" WHERE cashreceipt.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	" AND customer.cmpy_code = cashreceipt.cmpy_code ", 
	" AND cashreceipt.cust_code = customer.cust_code ", 
	" AND ",glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AC2_rpt_list")].sel_text clipped," ", 
	" ORDER BY cash_num" 
	PREPARE s_cashreceipt FROM l_query_text 
	DECLARE c_cashreceipt CURSOR FOR s_cashreceipt 
	FOREACH c_cashreceipt INTO l_rec_cashreceipt.*
#@debug
	 DISPLAY l_rec_cashreceipt.*
		#---------------------------------------------------------
		OUTPUT TO REPORT AC2_rpt_list(l_rpt_idx,
		l_rec_cashreceipt.*)  
		IF NOT rpt_int_flag_handler2("Cash Receipt",l_rec_cashreceipt.cash_num,l_rec_cashreceipt.cust_code,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------	
	END FOREACH 
	 
	#------------------------------------------------------------
	FINISH REPORT AC2_rpt_list
	RETURN rpt_finish("AC2_rpt_list")
	#------------------------------------------------------------
 
END FUNCTION 
#####################################################################
# END FUNCTION AC2_rpt_process()
#####################################################################


#####################################################################
# REPORT AC2_rpt_list(p_rpt_idx,p_rec_cashreceipt)
#
#
#####################################################################
REPORT AC2_rpt_list(p_rpt_idx,p_rec_cashreceipt) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE p_rec_cashreceipt RECORD LIKE cashreceipt.*
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_arr_line array[4] OF CHAR(132) 

	OUTPUT 
 
	ORDER external BY p_rec_cashreceipt.cash_num 
	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  

		ON EVERY ROW 
			CALL db_customer_get_rec(UI_OFF,p_rec_cashreceipt.cust_code) RETURNING l_rec_customer.*	
			PRINT COLUMN 1, p_rec_cashreceipt.cash_num USING "########", 
			COLUMN 10, p_rec_cashreceipt.cheque_text, 
			COLUMN 25, p_rec_cashreceipt.cash_date USING "dd/mm/yy", 
			COLUMN 35, p_rec_cashreceipt.year_num USING "####", 
			COLUMN 40, p_rec_cashreceipt.period_num USING "###", 
			COLUMN 45, p_rec_cashreceipt.currency_code, 
			COLUMN 49, p_rec_cashreceipt.cash_amt USING "---,---,--&.&&", 
			COLUMN 64, p_rec_cashreceipt.applied_amt USING "---,---,--&.&&", 
			COLUMN 82, p_rec_cashreceipt.posted_flag, 
			COLUMN 86, p_rec_cashreceipt.cust_code, 
			COLUMN 94, l_rec_customer.name_text[1,27] 
			LET modu_tot_amt = modu_tot_amt + conv_currency(p_rec_cashreceipt.cash_amt, glob_rec_kandoouser.cmpy_code, 
			p_rec_cashreceipt.currency_code, "F", p_rec_cashreceipt.cash_date, "S") 
			LET glob_tot_appl = glob_tot_appl + conv_currency(p_rec_cashreceipt.applied_amt, glob_rec_kandoouser.cmpy_code, 
			p_rec_cashreceipt.currency_code, "F", p_rec_cashreceipt.cash_date, "S") 

		ON LAST ROW 
			NEED 5 LINES 
			SKIP 1 line 
			PRINT COLUMN 1, "Report Totals In Base Currency:" 
			PRINT COLUMN 1, "Receipts: ", count(*) USING "####", 
			COLUMN 45, modu_tot_amt USING "---,---,--&.&&", 
			COLUMN 60, glob_tot_appl USING "---,---,--&.&&" 
			SKIP 1 line 
			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	
END REPORT
#####################################################################
# END REPORT AC2_rpt_list(p_rpt_idx,p_rec_cashreceipt)
#####################################################################