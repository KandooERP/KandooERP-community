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
GLOBALS "../ar/ACA_GLOBALS.4gl"
#####################################################################
# FUNCTION ACA_main()
#
# ACA - Unapplied Receipts Report
#####################################################################
FUNCTION ACA_main() 
	DEFER interrupt 
	DEFER quit 

	CALL setModuleId("ACA") 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode
			OPEN WINDOW A148 with FORM "A148" 
			CALL windecoration_a("A148") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title

			MENU " Unapplied Receipts" 

				BEFORE MENU 
					CALL publish_toolbar("kandoo","ACA","menu-unapplied-receipts") 
					CALL ACA_rpt_process(ACA_rpt_query())
					
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				ON ACTION "Report"	#COMMAND "Run" " Enter selection criteria AND generate REPORT"
					CALL ACA_rpt_process(ACA_rpt_query())

				ON ACTION "Print Manager" #COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "CANCEL" 	#COMMAND KEY("E",interrupt)"Exit" " Exit TO menus"
					EXIT MENU 


			END MENU 

			CLOSE WINDOW A148 

	 
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL ACA_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW A148 with FORM "A148" 
			CALL windecoration_a("A148") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(ACA_rpt_query()) #save where clause in env 
			CLOSE WINDOW A148 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL ACA_rpt_process(get_url_sel_text())
	END CASE 	
	
END FUNCTION 
#####################################################################
# FUNCTION ACA_main()
#####################################################################


#####################################################################
# FUNCTION ACA_rpt_query()
#
#
#####################################################################
FUNCTION ACA_rpt_query() 
	DEFINE l_where_text STRING

	MESSAGE kandoomsg2("U",1001,"")	#1001 Enter Selection Criteria; OK TO Continue.
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
			CALL publish_toolbar("kandoo","ACA","construct-cashreceipt") 

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
# END FUNCTION ACA_rpt_query()
#####################################################################


#####################################################################
# FUNCTION ACA_rpt_process()
#
#
#####################################################################
FUNCTION ACA_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT   
	DEFINE l_rec_receipt RECORD 
		cust_code LIKE cashreceipt.cust_code, 
		name_text LIKE customer.name_text, 
		currency_code LIKE customer.currency_code, 
		cash_num LIKE cashreceipt.cash_num, 
		cash_amt LIKE cashreceipt.cash_amt, 
		cash_date LIKE cashreceipt.cash_date, 
		applied_amt LIKE cashreceipt.applied_amt, 
		cheque_text LIKE cashreceipt.cheque_text, 
		appl_num LIKE invoicepay.appl_num, 
		inv_num LIKE invoicepay.inv_num, 
		apply_num LIKE invoicepay.apply_num, 
		pay_date LIKE invoicepay.pay_date, 
		pay_amt LIKE invoicepay.pay_amt, 
		disc_amt LIKE invoicepay.disc_amt 
	END RECORD
	DEFINE l_order_text STRING
--	DEFINE l_rec_arparms RECORD LIKE arparms.* 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"ACA_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT ACA_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

--	#get Account Receivable Parameters Record
--	CALL db_arparms_get_rec(UI_ON,1) RETURNING l_rec_arparms.* 

	IF glob_rec_arparms.report_ord_flag = "C" THEN 
		LET l_order_text = " ORDER BY cashreceipt.cust_code, ", " cashreceipt.cash_num, invoicepay.apply_num" 
	ELSE 
		LET l_order_text = " ORDER BY customer.name_text, cashreceipt.cust_code, ",	" cashreceipt.cash_num, invoicepay.apply_num" 
	END IF 
	
	LET l_query_text = 
		"SELECT cashreceipt.cust_code, customer.name_text, ", 
		" customer.currency_code, cashreceipt.cash_num, ", 
		" cashreceipt.cash_amt, cashreceipt.cash_date, ", 
		" cashreceipt.applied_amt, cashreceipt.cheque_text, ", 
		" invoicepay.appl_num, invoicepay.inv_num, ", 
		" invoicepay.apply_num, invoicepay.pay_date, ", 
		" invoicepay.pay_amt, invoicepay.disc_amt ", 
		" FROM cashreceipt, customer, outer invoicepay", 
		" WHERE cashreceipt.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
		" customer.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
		" invoicepay.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
		" cashreceipt.cust_code = invoicepay.cust_code AND ", 
		" cashreceipt.cust_code = customer.cust_code AND ", 
		" cashreceipt.cash_amt <> cashreceipt.applied_amt AND ", 
		" cashreceipt.cash_num = invoicepay.ref_num AND ", 
		" invoicepay.pay_type_ind = ", "\"", TRAN_TYPE_RECEIPT_CA, "\"", " AND ", 
		glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ACA_rpt_list")].sel_text clipped, " ",
		l_order_text clipped 
	PREPARE s_cashreceipt FROM l_query_text 
	DECLARE c_cashreceipt CURSOR FOR s_cashreceipt 

	FOREACH c_cashreceipt INTO l_rec_receipt.* 
		IF l_rec_receipt.pay_amt IS NULL THEN 
			LET l_rec_receipt.pay_amt = 0 
		END IF 

		#---------------------------------------------------------
		OUTPUT TO REPORT ACA_rpt_list(l_rpt_idx,l_rec_receipt.*)  
		IF NOT rpt_int_flag_handler2("Cash Receipt:",l_rec_receipt.cash_num, l_rec_receipt.pay_amt,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------
	END FOREACH 
	 
	#------------------------------------------------------------
	FINISH REPORT ACA_rpt_list
	RETURN rpt_finish("ACA_rpt_list")
	#------------------------------------------------------------
	 
END FUNCTION 
#####################################################################
# END FUNCTION ACA_rpt_process()
#####################################################################


#####################################################################
# REPORT ACA_rpt_list(p_rec_receipt)
#
#
#####################################################################
REPORT ACA_rpt_list(p_rpt_idx,p_rec_receipt) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_receipt RECORD 
		cust_code LIKE cashreceipt.cust_code, 
		name_text LIKE customer.name_text, 
		currency_code LIKE customer.currency_code, 
		cash_num LIKE cashreceipt.cash_num, 
		cash_amt LIKE cashreceipt.cash_amt, 
		cash_date LIKE cashreceipt.cash_date, 
		applied_amt LIKE cashreceipt.applied_amt, 
		cheque_text LIKE cashreceipt.cheque_text, 
		appl_num LIKE invoicepay.appl_num, 
		inv_num LIKE invoicepay.inv_num, 
		apply_num LIKE invoicepay.apply_num, 
		pay_date LIKE invoicepay.pay_date, 
		pay_amt LIKE invoicepay.pay_amt, 
		disc_amt LIKE invoicepay.disc_amt 
	END RECORD
	DEFINE l_ord_num LIKE invoicehead.ord_num
	DEFINE l_cust_cash_amt LIKE cashreceipt.cash_amt
	DEFINE l_arr_line array[4] OF CHAR(132) 

	OUTPUT 
 
	ORDER external BY p_rec_receipt.cust_code, 
	p_rec_receipt.cash_num, 
	p_rec_receipt.appl_num 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		BEFORE GROUP OF p_rec_receipt.cust_code 
			SKIP 2 LINES 
			PRINT COLUMN 1, "Customer Code: ", p_rec_receipt.cust_code, 
			COLUMN 25, p_rec_receipt.name_text, 
			" Currency " , p_rec_receipt.currency_code 
			LET l_cust_cash_amt = 0 

		BEFORE GROUP OF p_rec_receipt.cash_num 
			SKIP 1 line 
			PRINT COLUMN 1, "Receipt: ", p_rec_receipt.cash_num USING "########", 
			COLUMN 20, "Date: ", p_rec_receipt.pay_date USING "dd/mm/yy", 
			COLUMN 37, "Amount: ", p_rec_receipt.cash_amt USING "---,---,--&.&&" 
			LET l_cust_cash_amt = l_cust_cash_amt + p_rec_receipt.cash_amt 

		ON EVERY ROW 
			IF p_rec_receipt.appl_num IS NOT NULL 
			OR p_rec_receipt.inv_num IS NOT NULL THEN 
				SELECT ord_num INTO l_ord_num FROM invoicehead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cust_code = p_rec_receipt.cust_code 
				AND inv_num = p_rec_receipt.inv_num 
				IF status = NOTFOUND THEN 
					LET l_ord_num = NULL 
				END IF 
				PRINT COLUMN 1, p_rec_receipt.appl_num USING "######", 
				COLUMN 15, p_rec_receipt.pay_date USING "dd/mm/yy", 
				COLUMN 25, p_rec_receipt.inv_num USING "########", 
				COLUMN 35, p_rec_receipt.apply_num USING "######", 
				COLUMN 45, l_ord_num USING "########", 
				COLUMN 60, p_rec_receipt.cheque_text, 
				COLUMN 75, p_rec_receipt.pay_amt USING "---,---,--&.&&" 
			END IF 

		AFTER GROUP OF p_rec_receipt.cust_code 
			PRINT COLUMN 75, "============== ==============" 
			PRINT COLUMN 1 , "Customer Totals:", 
			COLUMN 75, GROUP sum(p_rec_receipt.pay_amt) USING "---,---,--&.&&"; 
			IF GROUP sum(p_rec_receipt.pay_amt) IS NULL THEN 
				PRINT COLUMN 90, l_cust_cash_amt USING "---,---,--&.&&" 
			ELSE 
				PRINT COLUMN 90, l_cust_cash_amt - GROUP sum(p_rec_receipt.pay_amt) 
				USING "---,---,--&.&&" 
			END IF 

		AFTER GROUP OF p_rec_receipt.cash_num 
			PRINT COLUMN 75, "============== ==============" 
			PRINT COLUMN 75, GROUP sum(p_rec_receipt.pay_amt) USING "---,---,--&.&&"; 
			IF GROUP sum(p_rec_receipt.pay_amt) IS NULL THEN 
				PRINT COLUMN 90, p_rec_receipt.cash_amt USING "---,---,--&.&&" 
			ELSE 
				PRINT COLUMN 90, p_rec_receipt.cash_amt - GROUP sum(p_rec_receipt.pay_amt) 
				USING "---,---,--&.&&" 
			END IF 

		ON LAST ROW 
			SKIP 1 line 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4]
 	
END REPORT 
#####################################################################
# END REPORT ACA_rpt_list(p_rec_receipt)
#####################################################################