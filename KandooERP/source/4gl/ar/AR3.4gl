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
GLOBALS "../ar/AR_GROUP_GLOBALS.4gl"
GLOBALS "../ar/AR3_GLOBALS.4gl" 
#############################################################################
# FUNCTION AR3(p_mode)
#
# AR3 Summary by Period
#############################################################################
FUNCTION AR3_main() 
	DEFER quit 
	DEFER interrupt
--	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
whenever any error stop
	CALL setModuleId("AR3")
	CALL init_report_ar() #report default data from db-arparms
	CALL AR_temp_tables_create()

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query

		WHEN RPT_OP_MENU #UI/MENU Mode 	
			OPEN WINDOW A105 with FORM "A105" 
			CALL windecoration_a("A105") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
		
			MENU " Activity by Period" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","AR3","menu-activity-period") 
					CALL AR3_rpt_process(AR3_rpt_query())
					CALL AR_temp_tables_delete()
					
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				ON ACTION "REPORT"	#COMMAND "Report" " SELECT criteria AND PRINT REPORT" 
					CALL AR3_rpt_process(AR3_rpt_query())
					CALL AR_temp_tables_delete()
		
				ON ACTION "Print Manager" 	#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
					NEXT option "Exit" 
		
				ON ACTION "Cancel" 			#COMMAND KEY (interrupt, "E") "Exit" " Exit TO menus"
					EXIT MENU 		
			END MENU 
		
			CLOSE WINDOW A105 
			 
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL AR3_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW A105 with FORM "A105" 
			CALL windecoration_a("A105") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(AR3_rpt_query()) #save where clause in env 
			CLOSE WINDOW A105 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL AR3_rpt_process(get_url_sel_text())
	END CASE
	
	CALL AR_temp_tables_drop()
END FUNCTION 


#############################################################################
# FUNCTION AR3_rpt_query()
#
#
#############################################################################
FUNCTION AR3_rpt_query() 
	DEFINE l_where_text STRING
	DEFINE l_rec_fiscal_period_range RECORD
		year_num1 LIKE period.year_num, #glob_rec_rpt_selector.ref1_num
		period_num1 LIKE period.period_num, #glob_rec_rpt_selector.ref3_code
		year_num2 LIKE period.year_num, #glob_rec_rpt_selector.ref2_num
		period_num2 LIKE period.period_num #glob_rec_rpt_selector.ref4_code
	END RECORD

	CLEAR FORM 

	OPEN WINDOW wtransationqueries with FORM "A950" 
	CALL windecoration_a("A950") 

	LET l_rec_fiscal_period_range.year_num1 = trim(YEAR(TODAY))
	LET l_rec_fiscal_period_range.year_num2 = l_rec_fiscal_period_range.year_num1
	LET l_rec_fiscal_period_range.period_num1 = 1
	LET l_rec_fiscal_period_range.period_num2 = 1

	INPUT l_rec_fiscal_period_range.year_num1, l_rec_fiscal_period_range.period_num1, l_rec_fiscal_period_range.year_num2, l_rec_fiscal_period_range.period_num2 WITHOUT DEFAULTS 
	FROM byear, bperiod, eyear, eperiod   

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON CHANGE byear
			IF l_rec_fiscal_period_range.year_num2 < l_rec_fiscal_period_range.year_num1  THEN
				LET l_rec_fiscal_period_range.year_num2 = l_rec_fiscal_period_range.year_num1
			END IF 


	END INPUT 


	CLOSE WINDOW wtransationqueries 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 

	MESSAGE kandoomsg2("U",1001,"") 
	#1001 Enter Selection Criteria - ESC TO Continue
	CONSTRUCT BY NAME l_where_text ON customer.cust_code, 
	customer.name_text, 
	customer.addr1_text, 
	customer.addr2_text, 
	customer.city_text, 
	customer.state_code, 
	customer.post_code, 
	customer.country_code, 
	customer.currency_code, 
	customer.corp_cust_code, 
	customer.inv_addr_flag, 
	customer.sales_anly_flag, 
	customer.credit_chk_flag, 
	customer.type_code, 
	customer.sale_code, 
	customer.term_code, 
	customer.tax_code, 
	customer.bank_acct_code, 
	customer.setup_date, 
	customer.contact_text, 
	customer.tax_num_text, 
	customer.int_chge_flag, 
	customer.registration_num, 
	customer.vat_code, 
	customer.tele_text, 
	customer.mobile_phone, 
	customer.fax_text ,
	customer.email

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","AR3","construct-customer") 

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
		LET glob_rec_rpt_selector.ref1_num = l_rec_fiscal_period_range.year_num1
		LET glob_rec_rpt_selector.ref2_num = l_rec_fiscal_period_range.period_num1
		LET glob_rec_rpt_selector.ref3_num = l_rec_fiscal_period_range.year_num2
		LET glob_rec_rpt_selector.ref4_num = l_rec_fiscal_period_range.period_num2 		
		RETURN l_where_text
	END IF 
END FUNCTION


#############################################################################
# FUNCTION AR3_rpt_process()
#
#
#############################################################################
FUNCTION AR3_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT 
	DEFINE l_rec_fiscal_period_range RECORD
		year_num1 LIKE period.year_num, #glob_rec_rpt_selector.ref1_num
		period_num1 LIKE period.period_num, #glob_rec_rpt_selector.ref3_code
		year_num2 LIKE period.year_num, #glob_rec_rpt_selector.ref2_num
		period_num2 LIKE period.period_num #glob_rec_rpt_selector.ref4_code
	END RECORD
	DEFINE l_rec_tempdoc RECORD 
		tm_cust LIKE customer.cust_code, 
		tm_name LIKE customer.name_text, 
		tm_date DATE, 
		tm_type CHAR(2), 
		tm_year SMALLINT, 
		tm_period SMALLINT, 
		tm_doc INTEGER, 
		tm_refer CHAR(20), 
		tm_amount money(12,2), 
		tm_paid money(12,2), 
		tm_cred money(12,2), 
		tm_dis money(12,2), 
		tm_post CHAR(1) 
	END RECORD
	DEFINE l_rec_invoicehead RECORD 
		cust_code LIKE invoicehead.cust_code, 
		name_text LIKE customer.name_text, 
		inv_num LIKE invoicehead.inv_num, 
		inv_date LIKE invoicehead.inv_date, 
		purchase_code LIKE invoicehead.purchase_code, 
		total_amt LIKE invoicehead.total_amt, 
		paid_amt LIKE invoicehead.paid_amt, 
		disc_amt LIKE invoicehead.disc_amt, 
		disc_taken_amt LIKE invoicehead.disc_taken_amt, 
		year_num LIKE invoicehead.year_num, 
		period_num LIKE invoicehead.period_num, 
		posted_flag LIKE invoicehead.posted_flag 
	END RECORD
	DEFINE l_rec_credithead RECORD 
		cust_code LIKE credithead.cust_code, 
		name_text LIKE customer.name_text, 
		cred_num LIKE credithead.cred_num, 
		cred_date LIKE credithead.cred_date, 
		cred_text LIKE credithead.cred_text, 
		total_amt LIKE credithead.total_amt, 
		appl_amt LIKE credithead.appl_amt, 
		year_num LIKE credithead.year_num, 
		period_num LIKE credithead.period_num, 
		posted_flag LIKE credithead.posted_flag 
	END RECORD
	DEFINE l_rec_cashreceipt RECORD 
		cust_code LIKE cashreceipt.cust_code, 
		name_text LIKE customer.name_text, 
		cash_num LIKE cashreceipt.cash_num, 
		cash_date LIKE cashreceipt.cash_date, 
		cheque_text LIKE cashreceipt.cheque_text, 
		cash_amt LIKE cashreceipt.cash_amt, 
		applied_amt LIKE cashreceipt.applied_amt, 
		year_num LIKE cashreceipt.year_num, 
		period_num LIKE cashreceipt.period_num, 
		posted_flag LIKE cashreceipt.posted_flag 
	END RECORD 
	DEFINE vee CHAR(1) 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"AR3_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT AR3_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AR3_rpt_list")].sel_text
	#------------------------------------------------------------

	#these variables are stored in rmsreps
	LET l_rec_fiscal_period_range.year_num1 = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AR3_rpt_list")].ref1_num 
	LET l_rec_fiscal_period_range.period_num1 = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AR3_rpt_list")].ref2_num 
	LET l_rec_fiscal_period_range.year_num2 = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AR3_rpt_list")].ref3_num  
	LET l_rec_fiscal_period_range.period_num2 = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AR3_rpt_list")].ref4_num  	
	#------------------------------------------------------------

	LET l_query_text = 
	"SELECT invoicehead.cust_code,customer.name_text,invoicehead.inv_num,invoicehead.inv_date,invoicehead.purchase_code,invoicehead.total_amt, invoicehead.paid_amt,invoicehead.disc_amt, ", 
	"invoicehead.disc_taken_amt, invoicehead.year_num, invoicehead.period_num, invoicehead.posted_flag ", 
	"FROM invoicehead, customer WHERE customer.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND invoicehead.cust_code = customer.cust_code AND ", 
	"invoicehead.cmpy_code = customer.cmpy_code AND invoicehead.year_num between \"",l_rec_fiscal_period_range.year_num1,"\" AND \"",l_rec_fiscal_period_range.year_num2,"\" AND ", 
	" invoicehead.period_num between \"",l_rec_fiscal_period_range.period_num1,"\" AND \"",l_rec_fiscal_period_range.period_num2,"\" AND ", 
	glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AR3_rpt_list")].sel_text clipped 


	PREPARE invoicer FROM l_query_text 
	DECLARE invcurs CURSOR FOR invoicer 

	#DISPLAY "Invoice: " AT 1,2
	--MESSAGE "Invoice" 

	FOREACH invcurs INTO l_rec_invoicehead.* 
		LET l_rec_tempdoc.tm_cust = l_rec_invoicehead.cust_code 
		LET l_rec_tempdoc.tm_name = l_rec_invoicehead.name_text 
		LET l_rec_tempdoc.tm_date = l_rec_invoicehead.inv_date 
		LET l_rec_tempdoc.tm_type = TRAN_TYPE_INVOICE_IN 
		LET l_rec_tempdoc.tm_year = l_rec_invoicehead.year_num 
		LET l_rec_tempdoc.tm_period = l_rec_invoicehead.period_num 
		LET l_rec_tempdoc.tm_doc = l_rec_invoicehead.inv_num 
		LET l_rec_tempdoc.tm_refer = l_rec_invoicehead.purchase_code 
		IF l_rec_invoicehead.posted_flag = "V" THEN 
			LET l_rec_tempdoc.tm_amount = 0 
			LET l_rec_tempdoc.tm_paid = 0 
		ELSE 
			LET l_rec_tempdoc.tm_amount = l_rec_invoicehead.total_amt 
		END IF 
		LET l_rec_tempdoc.tm_post = l_rec_invoicehead.posted_flag 
		LET l_rec_tempdoc.tm_dis = l_rec_invoicehead.disc_amt - 
		l_rec_invoicehead.disc_taken_amt 

		INSERT INTO t_AR3_rpt_data_shuffle VALUES (l_rec_tempdoc.*) 
		INITIALIZE l_rec_tempdoc.* TO NULL 

		--MESSAGE l_rec_invoicehead.inv_num 
		#DISPLAY l_rec_invoicehead.inv_num AT 1,11

		IF int_flag OR quit_flag THEN 
			#8503 Continue Report (Y/N)
			IF kandoomsg("U",8503,"") = "N" THEN 
				MESSAGE kandoomsg2("U",9501,"") 
				#9501 Report Terminated
				LET int_flag = true 
				LET quit_flag = true 
				EXIT FOREACH 
			END IF 
		END IF 
	END FOREACH 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		CLOSE WINDOW w_AR3 
		RETURN false 
	END IF
	 
	LET l_query_text = 
	"SELECT credithead.cust_code, customer.name_text, credithead.cred_num, credithead.cred_date, credithead.cred_text, credithead.total_amt, ", 
	"credithead.appl_amt, credithead.year_num, credithead.period_num, credithead.posted_flag ", 
	"FROM credithead, customer ", 
	"WHERE customer.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND credithead.cmpy_code = customer.cmpy_code AND credithead.cust_code = customer.cust_code AND ", 
	"credithead.year_num between \"",l_rec_fiscal_period_range.year_num1,"\" AND \"",l_rec_fiscal_period_range.year_num2,"\" AND ", 
	"credithead.period_num between \"",l_rec_fiscal_period_range.period_num1,"\" AND \"",l_rec_fiscal_period_range.period_num2,"\" AND ", 
	glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AR3_rpt_list")].sel_text clipped 

	PREPARE creditor FROM l_query_text 
	DECLARE credcurs CURSOR FOR creditor 

	FOREACH credcurs INTO l_rec_credithead.* 

		LET l_rec_tempdoc.tm_cust = l_rec_credithead.cust_code 
		LET l_rec_tempdoc.tm_name = l_rec_credithead.name_text 
		LET l_rec_tempdoc.tm_date = l_rec_credithead.cred_date 
		LET l_rec_tempdoc.tm_type = TRAN_TYPE_CREDIT_CR 
		LET l_rec_tempdoc.tm_year = l_rec_credithead.year_num 
		LET l_rec_tempdoc.tm_period = l_rec_credithead.period_num 
		LET l_rec_tempdoc.tm_doc = l_rec_credithead.cred_num 
		LET l_rec_tempdoc.tm_dis = 0 
		IF l_rec_credithead.posted_flag = "V" THEN 
			LET l_rec_tempdoc.tm_amount = 0 
			LET l_rec_tempdoc.tm_paid = 0 
		ELSE 

			LET l_rec_tempdoc.tm_refer = l_rec_credithead.cred_text 
			LET l_rec_tempdoc.tm_cred = l_rec_credithead.total_amt 
		END IF 
		LET l_rec_tempdoc.tm_post = l_rec_credithead.posted_flag 

		#DISPLAY l_rec_credithead.cred_num AT 1,11
		--MESSAGE "Credit:", l_rec_credithead.cred_num 

		IF int_flag OR quit_flag THEN 
			#8503 Continue Report (Y/N)
			IF kandoomsg("U",8503,"") = "N" THEN 
				MESSAGE kandoomsg2("U",9501,"") 
				#9501 Report Terminated
				LET int_flag = true 
				LET quit_flag = true 
				EXIT FOREACH 
			END IF 
		END IF 
		INSERT INTO t_AR3_rpt_data_shuffle VALUES (l_rec_tempdoc.*) 
		INITIALIZE l_rec_tempdoc.* TO NULL 
	END FOREACH 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		CLOSE WINDOW w_AR3 
		RETURN false 
	END IF 

	LET l_query_text = 
	"SELECT cashreceipt.cust_code, customer.name_text, cashreceipt.cash_num, cashreceipt.cash_date, cashreceipt.cheque_text, cashreceipt.cash_amt, ", 
	"cashreceipt.applied_amt, cashreceipt.year_num, cashreceipt.period_num, cashreceipt.posted_flag ", 
	"FROM cashreceipt, customer ", 
	"WHERE customer.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND cashreceipt.cmpy_code = customer.cmpy_code AND cashreceipt.cust_code = customer.cust_code AND ", 
	"cashreceipt.year_num between \"",l_rec_fiscal_period_range.year_num1,"\" AND \"",l_rec_fiscal_period_range.year_num2,"\" AND ", 
	"cashreceipt.period_num between \"",l_rec_fiscal_period_range.period_num1,"\" AND \"",l_rec_fiscal_period_range.period_num2,"\" AND ", 
	glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AR3_rpt_list")].sel_text clipped 

	PREPARE casher FROM l_query_text 
	DECLARE cashcurs CURSOR FOR casher 

	#DISPLAY "" AT 1,2
	#DISPLAY "Receipt: " AT 1,2

	FOREACH cashcurs INTO l_rec_cashreceipt.* 

		LET l_rec_tempdoc.tm_cust = l_rec_cashreceipt.cust_code 
		LET l_rec_tempdoc.tm_name = l_rec_cashreceipt.name_text 
		LET l_rec_tempdoc.tm_date = l_rec_cashreceipt.cash_date 
		LET l_rec_tempdoc.tm_type = TRAN_TYPE_RECEIPT_CA 
		LET l_rec_tempdoc.tm_doc = l_rec_cashreceipt.cash_num 
		LET l_rec_tempdoc.tm_year = l_rec_cashreceipt.year_num 
		LET l_rec_tempdoc.tm_period = l_rec_cashreceipt.period_num 
		LET l_rec_tempdoc.tm_refer = l_rec_cashreceipt.cheque_text 
		LET l_rec_tempdoc.tm_dis = 0 

		IF l_rec_cashreceipt.posted_flag = CASHRECEIPT_POST_FLAG_STATUS_VOIDED_V THEN 
			LET l_rec_tempdoc.tm_amount = 0 
			LET l_rec_tempdoc.tm_paid = 0 
		ELSE 
			LET l_rec_tempdoc.tm_paid = l_rec_cashreceipt.cash_amt 
		END IF 

		LET l_rec_tempdoc.tm_post = l_rec_cashreceipt.posted_flag 
		#DISPLAY l_rec_cashreceipt.cash_num AT 1,11
		--MESSAGE "Receipt: ", l_rec_cashreceipt.cash_num 

		IF int_flag OR quit_flag THEN 
			#8503 Continue Report (Y/N)
			IF kandoomsg("U",8503,"") = "N" THEN 
				MESSAGE kandoomsg2("U",9501,"") 
				#9501 Report Terminated
				LET int_flag = true 
				LET quit_flag = true 
				EXIT FOREACH 
			END IF 
		END IF 
		INSERT INTO t_AR3_rpt_data_shuffle VALUES (l_rec_tempdoc.*) 
		INITIALIZE l_rec_tempdoc.* TO NULL 

	END FOREACH 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		CLOSE WINDOW w_AR3 
		RETURN false 
	END IF 

	DECLARE selcurs CURSOR FOR 
	SELECT * FROM t_AR3_rpt_data_shuffle 
	ORDER BY tm_cust, tm_date, tm_doc 

	FOREACH selcurs INTO l_rec_tempdoc.* 
		#---------------------------------------------------------
		OUTPUT TO REPORT AR3_rpt_list(l_rpt_idx,l_rec_tempdoc.*)  
		IF NOT rpt_int_flag_handler2("Customer:",l_rec_tempdoc.tm_cust, l_rec_credithead.name_text,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------	

	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT AR3_rpt_list
	CALL rpt_finish("AR3_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 

END FUNCTION 


#############################################################################
# REPORT AR3_rpt_list(p_rpt_idx,p_rec_tempdoc)
#
#
#############################################################################
REPORT AR3_rpt_list(p_rpt_idx,p_rec_tempdoc)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx] 
	DEFINE p_rec_tempdoc RECORD 
		tm_cust CHAR(8), 
		tm_name CHAR(30), 
		tm_date DATE, 
		tm_type CHAR(2), 
		tm_year SMALLINT, 
		tm_period SMALLINT, 
		tm_doc INTEGER, 
		tm_refer CHAR(20), 
		tm_amount money(12,2), 
		tm_paid money(12,2), 
		tm_cred money(12,2), 
		tm_dis money(12,2), 
		tm_post CHAR(1) 
	END RECORD 
	
	OUTPUT 

--	left margin 0 

	ORDER external BY p_rec_tempdoc.tm_cust, p_rec_tempdoc.tm_date, 
	p_rec_tempdoc.tm_doc 

	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #was l_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #was l_arr_line[3]  
			
			PRINT COLUMN 1, "Date", 
			COLUMN 9, "Trans", 
			COLUMN 15, " Doc", 
			COLUMN 24, glob_rec_arparms.inv_ref2a_text, 
			COLUMN 48, "Invoice", 
			COLUMN 61, " Payment ", 
			COLUMN 75, "Discount", 
			COLUMN 89, "Credited", 
			COLUMN 98, "Posted", 
			COLUMN 105, "Year", 
			COLUMN 110, "Period" 

			PRINT COLUMN 9, "Type", 
			COLUMN 15, "Number", 
			COLUMN 24, glob_rec_arparms.inv_ref2b_text, 
			COLUMN 48, "Amount", 
			COLUMN 62, "Amount", 
			COLUMN 76, "Amount", 
			COLUMN 90, "Amount" 
			PRINT COLUMN 1, rpt_get_char_line(p_rpt_idx,NULL,"-")
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #was l_arr_line[3]

		ON EVERY ROW 
			PRINT COLUMN 1, p_rec_tempdoc.tm_date USING "dd/mm/yy", 
			COLUMN 10, p_rec_tempdoc.tm_type, 
			COLUMN 13, p_rec_tempdoc.tm_doc USING "########", 
			COLUMN 22, p_rec_tempdoc.tm_refer[1,19], 
			COLUMN 42, p_rec_tempdoc.tm_amount USING "--,---,--&.&&", 
			COLUMN 56, p_rec_tempdoc.tm_paid USING "--,---,--&.&&", 
			COLUMN 70, p_rec_tempdoc.tm_dis USING "--,---,--&.&&", 
			COLUMN 84, p_rec_tempdoc.tm_cred USING "--,---,--&.&&", 
			COLUMN 101, p_rec_tempdoc.tm_post, 
			COLUMN 103, p_rec_tempdoc.tm_year, 
			COLUMN 108, p_rec_tempdoc.tm_period 

		ON LAST ROW 
			PRINT COLUMN 38, "-----------------------------------------------------------" 
			PRINT COLUMN 38, sum(p_rec_tempdoc.tm_amount) USING "--,---,---,--&.&&", 
			COLUMN 66, sum(p_rec_tempdoc.tm_dis) USING "--,---,---,--&.&&" 

			PRINT COLUMN 52, sum(p_rec_tempdoc.tm_paid) USING "--,---,---,--&.&&", 
			COLUMN 80, sum(p_rec_tempdoc.tm_cred) USING "--,---,---,--&.&&" 

			SKIP 1 line 
			
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	
			


		BEFORE GROUP OF p_rec_tempdoc.tm_cust 
			SKIP 2 LINES 
			PRINT COLUMN 1, "Customer: ", p_rec_tempdoc.tm_cust, 2 spaces, 
			COLUMN 28, p_rec_tempdoc.tm_name 

		AFTER GROUP OF p_rec_tempdoc.tm_cust 
			PRINT COLUMN 38, "-----------------------------------------------------------" 
			PRINT COLUMN 38, GROUP sum(p_rec_tempdoc.tm_amount) USING "--,---,---,--&.&&", 
			COLUMN 66, GROUP sum(p_rec_tempdoc.tm_dis) USING "--,---,---,--&.&&" 

			PRINT COLUMN 52, GROUP sum(p_rec_tempdoc.tm_paid) USING "--,---,---,--&.&&", 
			COLUMN 80, GROUP sum(p_rec_tempdoc.tm_cred) USING "--,---,---,--&.&&" 

END REPORT 