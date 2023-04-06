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
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl"
GLOBALS "../ar/AB_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/AC1_GLOBALS.4gl"
###########################################################################
# MODULE Scope Variables
###########################################################################
DEFINE modu_tot_amt DECIMAL(16,2) #Will be incremented/added in actual report block 
#####################################################################
# FUNCTION AC1_main()
#
# Cash Receipts
#####################################################################
FUNCTION AC1_main() 
	DEFER quit 
	DEFER interrupt
	
	CALL setModuleId("AC1") 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 	
			OPEN WINDOW A148 with FORM "A148" 
			CALL windecoration_a("A148") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title

			MENU " Cash Receipt by Customer" 

				BEFORE MENU 
					CALL publish_toolbar("kandoo","AC1","menu-cash-receipt-customer")
					CALL rpt_rmsreps_reset(NULL) 
					CALL AC1_rpt_process(AC1_rpt_query())
					
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				ON ACTION "Report" #COMMAND "Run" " Enter selection criteria AND generate REPORT"
					CALL rpt_rmsreps_reset(NULL)	
					CALL AC1_rpt_process(AC1_rpt_query())

				ON ACTION "Print Manager" #COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "Cancel" #COMMAND KEY("E",interrupt)"Exit" " Exit TO menus"
					EXIT MENU 

			END MENU 

			CLOSE WINDOW A148 

	 
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL AC1_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW A148 with FORM "A148" 
			CALL windecoration_a("A148") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(AC1_rpt_query()) #save where clause in env 
			CLOSE WINDOW A148 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL AC1_rpt_process(get_url_sel_text())
	END CASE 	
END FUNCTION 
#####################################################################
# END FUNCTION AC1_main()
#####################################################################


#####################################################################
# FUNCTION AC1_rpt_query()
#
#
#####################################################################
FUNCTION AC1_rpt_query() 
	DEFINE l_where_text STRING
	
	MESSAGE kandoomsg2("U",1001,"") #1001 Enter Selection Criteria - ESC TO Continue "
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
			CALL publish_toolbar("kandoo","AC1","construct-cashreceipt") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null)
			 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		MESSAGE "Report Generation aborted"
		RETURN NULL
	ELSE
		RETURN l_where_text
	END IF 
END FUNCTION 
#####################################################################
# END FUNCTION AC1_rpt_query()
#####################################################################


#####################################################################
# FUNCTION AC1_rpt_process(p_where_text) 
#
#
#####################################################################
FUNCTION AC1_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE l_rec_cashreceipt RECORD LIKE cashreceipt.*
	DEFINE l_rec_customer RECORD LIKE customer.*
	--DEFINE l_rec_arparms RECORD LIKE arparms.*

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"AC1_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT AC1_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AC1_rpt_list")].sel_text
	#------------------------------------------------------------

	LET modu_tot_amt = 0 
	LET glob_tot_appl = 0 
	
	IF glob_rec_arparms.report_ord_flag = "C" THEN 
		LET l_query_text = 
		"SELECT cashreceipt.*, customer.* ", 
		"FROM cashreceipt, customer ", 
		"WHERE cashreceipt.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
		"AND customer.cust_code = cashreceipt.cust_code ", 
		"AND customer.cmpy_code = cashreceipt.cmpy_code ", 
		"AND ", glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AC1_rpt_list")].sel_text clipped, " ", 
		"ORDER BY cashreceipt.cust_code, cashreceipt.cash_num" 
	ELSE 
		LET l_query_text = 
		"SELECT cashreceipt.*, customer.* ", 
		"FROM cashreceipt, customer ", 
		"WHERE cashreceipt.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
		"AND customer.cust_code = cashreceipt.cust_code ", 
		"AND customer.cmpy_code = cashreceipt.cmpy_code ", 
		"AND ", glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AC1_rpt_list")].sel_text clipped, " ", 
		"ORDER BY customer.name_text,cashreceipt.cust_code,cashreceipt.cash_num" 
	END IF 
	PREPARE s_cashreceipt FROM l_query_text 
	DECLARE c_cashreceipt CURSOR FOR s_cashreceipt 
	FOREACH c_cashreceipt INTO l_rec_cashreceipt.*, l_rec_customer.* 
		#---------------------------------------------------------
		OUTPUT TO REPORT AC1_rpt_list(l_rpt_idx,
		l_rec_cashreceipt.*,l_rec_customer.*)  
		IF NOT rpt_int_flag_handler2("Receipt:",l_rec_cashreceipt.cash_num, l_rec_customer.name_text,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------	
	END FOREACH 
	 
	#------------------------------------------------------------
	FINISH REPORT AC1_rpt_list
	RETURN rpt_finish("AC1_rpt_list")
	#------------------------------------------------------------

END FUNCTION 
#####################################################################
# END FUNCTION AC1_rpt_process(p_where_text) 
#####################################################################


#####################################################################
# REPORT AC1_rpt_list(p_rpt_idx,p_rec_cashreceipt, p_rec_customer) 
#
#
#####################################################################
REPORT AC1_rpt_list(p_rpt_idx,p_rec_cashreceipt, p_rec_customer) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_cashreceipt RECORD LIKE cashreceipt.*
	DEFINE p_rec_customer RECORD LIKE customer.*

	OUTPUT 
--	left margin 0 
	ORDER external BY p_rec_cashreceipt.cust_code, p_rec_cashreceipt.cash_num 
	
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  

		BEFORE GROUP OF p_rec_cashreceipt.cust_code 
			NEED 4 LINES 
			SKIP 2 LINES 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  
			PRINT COLUMN 1, "Customer Code: ", p_rec_cashreceipt.cust_code, 
			COLUMN 25, p_rec_customer.name_text, 
			" Currency ", p_rec_customer.currency_code 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  
			
		ON EVERY ROW 
			PRINT COLUMN 1, p_rec_cashreceipt.cash_num USING "########", 
			COLUMN 10, p_rec_cashreceipt.cheque_text, 
			COLUMN 25, p_rec_cashreceipt.cash_date USING "dd/mm/yy", 
			COLUMN 35, p_rec_cashreceipt.year_num USING "####", 
			COLUMN 40, p_rec_cashreceipt.period_num USING "###", 
			COLUMN 45, p_rec_cashreceipt.cash_amt USING "---,---,--&.&&", 
			COLUMN 60, p_rec_cashreceipt.applied_amt USING "---,---,--&.&&", 
			COLUMN 78, p_rec_cashreceipt.posted_flag 
			LET modu_tot_amt = modu_tot_amt + conv_currency(p_rec_cashreceipt.cash_amt, 
			glob_rec_kandoouser.cmpy_code, 
			p_rec_customer.currency_code, 
			"F", 
			p_rec_cashreceipt.cash_date, 
			"S") 
			LET glob_tot_appl = glob_tot_appl + conv_currency(p_rec_cashreceipt.applied_amt, 
			glob_rec_kandoouser.cmpy_code, 
			p_rec_customer.currency_code, 
			"F", 
			p_rec_cashreceipt.cash_date, 
			"S") 

		AFTER GROUP OF p_rec_cashreceipt.cust_code 
			NEED 3 LINES 
			PRINT COLUMN 01, "Customer Totals:", 
			COLUMN 45, "==============================" 
			PRINT COLUMN 01, "Receipts: ", GROUP count(*) USING "####", 
			COLUMN 45, GROUP sum(p_rec_cashreceipt.cash_amt) 
			USING "---,---,--&.&&", 
			COLUMN 60, GROUP sum(p_rec_cashreceipt.applied_amt) 
			USING "---,---,--&.&&" 

		ON LAST ROW 
			NEED 7 LINES 
			PRINT COLUMN 1, "----------------------------------------", 
			"----------------------------------------" 
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
# END REPORT AC1_rpt_list(p_rpt_idx,p_rec_cashreceipt, p_rec_customer) 
#####################################################################