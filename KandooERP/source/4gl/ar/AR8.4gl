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
GLOBALS "../ar/AR8_GLOBALS.4gl" 
############################################################
# MODULE Scope Variables
############################################################
	DEFINE modu_year_num SMALLINT 
	DEFINE modu_period_num SMALLINT 
	DEFINE modu_output_flag CHAR(1) 
	DEFINE modu_l1_cust_bal_amt DECIMAL(10,2) 
	DEFINE modu_l2_cust_bal_amt DECIMAL(10,2) 
	DEFINE modu_l3_cust_bal_amt DECIMAL(10,2) 
	DEFINE modu_local_bal_amt DECIMAL(10,2) 
	DEFINE modu_tot_local_bal_amt DECIMAL(10,2) 
	DEFINE modu_first_ind SMALLINT 
	DEFINE modu_rec_period RECORD LIKE period.* 
#####################################################################
# FUNCTION AR8_main()
#
# AR8, Debtors snapshot as AT a given year/period
# Prints all clients, even WHEN balance IS zero, but does NOT PRINT
# zero balance invoices
#####################################################################
FUNCTION AR8_main()
	DEFER quit 
	DEFER interrupt
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

	CALL setModuleId("AR8")
	CALL init_report_ar() #report default data from db-arparms
	CALL AR_temp_tables_create()

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query

		WHEN RPT_OP_MENU #UI/MENU Mode 	
			OPEN WINDOW A193 with FORM "A193" 
			CALL windecoration_a("A193") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
		
			MENU " AR Snapshot" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","AR8","menu-ar-snapshot") 
					CALL AR8_rpt_process(AR8_rpt_query())
					CALL AR_temp_tables_delete()
					
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				ON ACTION "Report" #COMMAND "Run Report" " SELECT criteria AND PRINT REPORT"
					CALL AR8_rpt_process(AR8_rpt_query())
					CALL AR_temp_tables_delete()	
		
				ON ACTION "Print Manager"	#COMMAND KEY ("P",f11) "Print" "Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "Exit" #COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus"
					EXIT MENU 
		
			END MENU 
		
			CALL AR_temp_tables_drop()
			
			CLOSE WINDOW A193 
	 
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL AR8_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW A193 with FORM "A193" 
			CALL windecoration_a("A193") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(AR8_rpt_query()) #save where clause in env 
			CLOSE WINDOW A193 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL AR8_rpt_process(get_url_sel_text())
	END CASE
	
	CALL AR_temp_tables_drop()
END FUNCTION 


#####################################################################
# FUNCTION AR8_rpt_query()
#
# Query SnapshotYear and Period
#####################################################################
FUNCTION AR8_rpt_query() #AR8 ... soo strange was called as7_query in the original code
	
	DEFINE l_where_text STRING
	LET modu_year_num = trim(YEAR(TODAY))
	LET modu_period_num = 1
	
	INPUT modu_year_num,modu_period_num WITHOUT DEFAULTS 
	FROM year_num,period_num  ATTRIBUTE(UNBUFFERED)

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","AR8","inp-period") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE FIELD year_num
			MESSAGE "Enter the Year and period followed by Apply"

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				SELECT unique * 
				INTO modu_rec_period.* 
				FROM period 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND year_num = modu_year_num 
				AND period_num = modu_period_num 
				IF status = NOTFOUND THEN 
					error"This year AND period NOT SET up in the GL" 
					NEXT FIELD year_num 
				END IF 
			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL
	END IF

	MESSAGE kandoomsg2("A",1001,"") 
	#1001 Enter selection criteria
	CONSTRUCT BY NAME l_where_text ON customer.cust_code 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","AR8","construct-customer") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	BEFORE FIELD cust_code
		MESSAGE "Enter Customer Code or Search Pattern"

	END CONSTRUCT 



	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL
	ELSE 
		LET glob_rec_rpt_selector.ref1_num = modu_year_num
		LET glob_rec_rpt_selector.ref2_num = modu_period_num
		#------------------------------------------------------------
		LET glob_rec_rpt_selector.ref2_text = " - Year ",modu_year_num USING "####", "  Period ",modu_period_num USING "###" 
		#------------------------------------------------------------	
		
		RETURN l_where_text 
	END IF 
END FUNCTION 



#####################################################################
# FUNCTION AR8_rpt_process() 
# Original function name: generate_report()
#
# 1. User enters Code/Pattern for Customer in a Construct 
# 2. Query DB with user code and previously specified snapshot year and period
# 3. Create Report
#
# RETURN TRUE on success and FALSE on CANCEL
#####################################################################
FUNCTION AR8_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT  
	DEFINE l_rec_customer RECORD LIKE customer.*
	DEFINE l_rec_invoicehead RECORD LIKE invoicehead.* 
	DEFINE l_rec_invoicepay RECORD LIKE invoicepay.* 
	DEFINE l_prev_cust_code LIKE customer.cust_code 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"AR8_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT AR8_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AR8_rpt_list")].sel_text
	#------------------------------------------------------------

		LET modu_year_num = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AR8_rpt_list")].ref1_num
		LET modu_period_num = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AR8_rpt_list")].ref2_num
			
		LET l_query_text="SELECT * FROM customer,", 
		"outer invoicehead ", 
		"WHERE invoicehead.cmpy_code ='",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND customer.cmpy_code='",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND customer.cust_code=invoicehead.cust_code ", 
		"and(year_num < '",modu_year_num,"' ", 
		"or(year_num ='",modu_year_num,"' ", 
		"AND period_num<='",modu_period_num,"')) ", 
		"AND ",glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AR8_rpt_list")].sel_text clipped," ", 
		"ORDER BY customer.cust_code,", 
		"invoicehead.inv_num " 
		
		PREPARE s_invoicehead FROM l_query_text 
		DECLARE c_invoicehead CURSOR FOR s_invoicehead
		 
		LET modu_output_flag = "N" 

--		OPEN WINDOW w1 with FORM "U999" 
--		CALL windecoration_u("U999") 

		LET l_prev_cust_code = " " 

		FOREACH c_invoicehead INTO l_rec_customer.*, 
			l_rec_invoicehead.* 
			IF l_rec_invoicehead.inv_num IS NOT NULL THEN 
				LET modu_output_flag = "Y" 
				IF l_prev_cust_code <> l_rec_invoicehead.cust_code THEN 
					DISPLAY "Customer: ", l_rec_invoicehead.cust_code at 1,2 
					LET l_prev_cust_code = l_rec_invoicehead.cust_code 
				END IF 
				LET l_rec_invoicehead.paid_amt = 0 
				LET l_rec_invoicehead.disc_amt = 0
				 
				SELECT sum(invoicepay.pay_amt ), 
				sum(invoicepay.disc_amt ) 
				INTO l_rec_invoicepay.pay_amt, l_rec_invoicepay.disc_amt 
				FROM invoicepay, cashreceipt 
				WHERE invoicepay.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND invoicepay.cust_code = l_rec_invoicehead.cust_code 
				AND invoicepay.inv_num = l_rec_invoicehead.inv_num 
				AND invoicepay.pay_type_ind = TRAN_TYPE_RECEIPT_CA 
				AND cashreceipt.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cashreceipt.cust_code = l_rec_invoicehead.cust_code 
				AND cashreceipt.cash_num = invoicepay.ref_num 
				AND (cashreceipt.year_num < modu_year_num 
				OR (cashreceipt.year_num = modu_year_num 
				AND cashreceipt.period_num <= modu_period_num))
				 
				IF l_rec_invoicepay.pay_amt IS NULL THEN 
					LET l_rec_invoicepay.pay_amt = 0 
				END IF 
				IF l_rec_invoicepay.disc_amt IS NULL THEN 
					LET l_rec_invoicepay.disc_amt = 0 
				END IF
				 
				LET l_rec_invoicehead.paid_amt = l_rec_invoicehead.paid_amt + 
				l_rec_invoicepay.pay_amt 
				LET l_rec_invoicehead.disc_amt = l_rec_invoicehead.disc_amt + 
				l_rec_invoicepay.disc_amt
				 
				SELECT sum(invoicepay.pay_amt), sum(invoicepay.disc_amt) 
				INTO l_rec_invoicepay.pay_amt, l_rec_invoicepay.disc_amt 
				FROM invoicepay, credithead 
				WHERE invoicepay.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND invoicepay.cust_code = l_rec_invoicehead.cust_code 
				AND invoicepay.inv_num = l_rec_invoicehead.inv_num 
				AND invoicepay.pay_type_ind = TRAN_TYPE_CREDIT_CR 
				AND credithead.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND credithead.cust_code = l_rec_invoicehead.cust_code 
				AND credithead.cred_num = invoicepay.ref_num 
				AND (credithead.year_num < modu_year_num 
				OR (credithead.year_num = modu_year_num 
				AND credithead.period_num <= modu_period_num)) 
				
				IF l_rec_invoicepay.pay_amt IS NULL THEN 
					LET l_rec_invoicepay.pay_amt = 0 
				END IF 
				IF l_rec_invoicepay.disc_amt IS NULL THEN 
					LET l_rec_invoicepay.disc_amt = 0 
				END IF 
				
				LET l_rec_invoicehead.paid_amt = l_rec_invoicehead.paid_amt +	l_rec_invoicepay.pay_amt 
				LET l_rec_invoicehead.disc_amt = l_rec_invoicehead.disc_amt + l_rec_invoicepay.disc_amt 
			ELSE 
			
				SELECT unique 1 FROM cashreceipt 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cust_code = l_rec_customer.cust_code 
				AND applied_amt <> cash_amt 
				AND(year_num < modu_year_num 
				OR(year_num = modu_year_num AND period_num <= modu_period_num))
				 
				IF status = 0 THEN 
					LET modu_output_flag = "Y" 
				ELSE 
					SELECT unique 1 FROM credithead 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cust_code = l_rec_customer.cust_code 
					AND appl_amt <credithead.total_amt 
					AND (year_num<modu_year_num 
					OR (year_num=modu_year_num AND period_num<=modu_period_num)) 
					IF status = 0 THEN 
						LET modu_output_flag = "Y" 
					END IF 
				END IF 
			END IF
			 
			IF modu_output_flag = "Y" THEN   
				LET modu_output_flag = "N"
				#---------------------------------------------------------
				OUTPUT TO REPORT AR8_rpt_list(l_rpt_idx,
				l_rec_customer.*, 
				l_rec_invoicehead.*, 
				l_rec_invoicepay.*)   
				IF NOT rpt_int_flag_handler2("Customer:",l_rec_customer.cust_code, l_rec_customer.name_text,l_rpt_idx) THEN
					EXIT FOREACH 
				END IF 
				#---------------------------------------------------------				
			END IF 
		END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT AR8_rpt_list
	CALL rpt_finish("AR8_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 



#####################################################################
# REPORT ar8_rpt_list(p_rec_customer,p_rec_invoicehead,p_rec_invoicepay)
#
#
#####################################################################
REPORT ar8_rpt_list(p_rpt_idx,p_rec_customer,p_rec_invoicehead,p_rec_invoicepay) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_customer RECORD LIKE customer.*
	DEFINE p_rec_invoicehead RECORD LIKE invoicehead.*
	DEFINE p_rec_invoicepay RECORD LIKE invoicepay.* 

	DEFINE l_rec_credithead RECORD LIKE credithead.*
	DEFINE l_rec_cashreceipt RECORD LIKE cashreceipt.*

	OUTPUT 
--	left margin 0 
	
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #was l_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #was l_arr_line[3]  
			
			IF pageno = 1 THEN 
				LET modu_l3_cust_bal_amt = 0 
				LET modu_tot_local_bal_amt = 0 
			END IF 

		BEFORE GROUP OF p_rec_customer.cust_code 
			LET modu_l2_cust_bal_amt = 0 
			PRINT "Customer: ", p_rec_customer.cust_code, " ", p_rec_customer.name_text, 
			"Currency: ", p_rec_customer.currency_code 
			IF p_rec_invoicehead.inv_num IS NOT NULL THEN 
				PRINT "Invoice", 
				COLUMN 11, "Date", 
				COLUMN 21, "Invoice Amt", 
				COLUMN 35, "Disc. Amt", 
				COLUMN 48, "Paid Amt", 
				COLUMN 61, "Balance" 
			END IF 

		ON EVERY ROW 
			IF p_rec_invoicehead.inv_num IS NOT NULL THEN 
				LET modu_l1_cust_bal_amt = p_rec_invoicehead.total_amt - 
				(p_rec_invoicehead.paid_amt + 
				p_rec_invoicehead.disc_taken_amt) 
				LET modu_l2_cust_bal_amt = modu_l2_cust_bal_amt + modu_l1_cust_bal_amt 
				IF modu_l1_cust_bal_amt <> 0 THEN 
					PRINT p_rec_invoicehead.inv_num USING "########", 
					COLUMN 10, p_rec_invoicehead.inv_date USING "dd/mm/yy", 
					COLUMN 21, p_rec_invoicehead.total_amt USING "--------.--", 
					COLUMN 33, p_rec_invoicehead.disc_taken_amt USING "--------.--", 
					COLUMN 45, p_rec_invoicehead.paid_amt USING "--------.--", 
					COLUMN 57, modu_l1_cust_bal_amt USING "--------.--" 
				END IF 
			END IF 

		AFTER GROUP OF p_rec_customer.cust_code 
			# Now get the un un-applied cash receipts
			# posted before the nominated period
			# applied_amt <> cash amt rather than applied < cash amt TO pick up
			# un_applied negative receipts, ie 'journals' TO reverse
			# posted, incorrect receipts
			DECLARE c_4 CURSOR FOR 
			SELECT * FROM cashreceipt 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cust_code = p_rec_customer.cust_code 
			AND (cashreceipt.year_num < modu_year_num 
			OR (cashreceipt.year_num = modu_year_num 
			AND cashreceipt.period_num <= modu_period_num)) 
			AND posted_flag = "Y" 
			AND applied_amt <> cash_amt 
			LET modu_first_ind = true 

			FOREACH c_4 INTO l_rec_cashreceipt.* 
				IF modu_first_ind THEN 
					LET modu_first_ind = false 
					PRINT "Unapplied Cash " 
					PRINT "Receipt", 
					COLUMN 11, "Date", 
					COLUMN 24, "Cash Amt", 
					COLUMN 34, "Applied Amt" 
				END IF 
				LET modu_l1_cust_bal_amt = l_rec_cashreceipt.cash_amt - l_rec_cashreceipt.applied_amt 
				PRINT l_rec_cashreceipt.cash_num USING "########", 
				COLUMN 11, l_rec_cashreceipt.cash_date USING "dd/mm/yy", 
				COLUMN 21, l_rec_cashreceipt. cash_amt USING "--------.--", 
				COLUMN 34, l_rec_cashreceipt. applied_amt USING "--------.--", 
				COLUMN 57, modu_l1_cust_bal_amt USING "--------.--" 
				LET modu_l2_cust_bal_amt = modu_l2_cust_bal_amt - modu_l1_cust_bal_amt 

			END FOREACH 
			{ Now get the un un-applied CREDITS posted before the nominated period}
			DECLARE c_5 CURSOR FOR 
			SELECT * FROM credithead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cust_code = p_rec_customer.cust_code 
			AND (credithead.year_num < modu_year_num 
			OR (credithead.year_num = modu_year_num 
			AND credithead.period_num <= modu_period_num)) 
			AND posted_flag = "Y" 
			AND appl_amt < total_amt 
			LET modu_first_ind = true 

			FOREACH c_5 INTO l_rec_credithead.* 
				IF modu_first_ind THEN 
					LET modu_first_ind = false 
					PRINT "Unapplied Credits " 
					PRINT "Credit", 
					COLUMN 11, "Date", 
					COLUMN 24, "Cred Amt", 
					COLUMN 34, "Applied Amt" 
				END IF 
				LET modu_l1_cust_bal_amt = l_rec_credithead.total_amt - l_rec_credithead.appl_amt 
				PRINT l_rec_credithead.total_amt USING "#######", 
				COLUMN 11, l_rec_credithead.cred_date USING "dd/mm/yy", 
				COLUMN 21, l_rec_credithead. total_amt USING "--------.--", 
				COLUMN 34, l_rec_credithead. appl_amt USING "--------.--", 
				COLUMN 57, modu_l1_cust_bal_amt USING "--------.--" 
				LET modu_l2_cust_bal_amt = modu_l2_cust_bal_amt - modu_l1_cust_bal_amt 
			END FOREACH 

			# now get the cash receipts applied TO later invoices
			DECLARE t_4 CURSOR FOR 
			SELECT cashreceipt.cash_num, 
			cashreceipt.cash_date, 
			cashreceipt.cash_amt, 
			sum(invoicepay.pay_amt) 
			FROM cashreceipt, invoicepay, invoicehead 
			WHERE cashreceipt.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cashreceipt.cust_code = p_rec_customer.cust_code 
			AND (cashreceipt.year_num < modu_year_num 
			OR (cashreceipt.year_num = modu_year_num 
			AND cashreceipt.period_num <= modu_year_num)) 
			AND cashreceipt.posted_flag = CASHRECEIPT_POST_FLAG_STATUS_POSTED_Y 
			AND invoicepay.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND invoicepay.cust_code = p_rec_customer.cust_code 
			AND invoicepay.pay_type_ind = TRAN_TYPE_RECEIPT_CA 
			AND invoicepay.ref_num = cashreceipt.cash_num 
			AND invoicehead.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND invoicehead.cust_code = p_rec_customer.cust_code 
			AND invoicehead.inv_num = invoicepay.inv_num 
			AND (invoicehead.year_num > modu_year_num 
			OR (invoicehead.year_num = modu_year_num 
			AND invoicehead.period_num > modu_year_num)) 
			GROUP BY cashreceipt.cash_num, 
			cashreceipt.cash_date, 
			cashreceipt.cash_amt 
			LET modu_first_ind = true 
			
			FOREACH t_4 INTO l_rec_cashreceipt.cash_num,l_rec_cashreceipt.cash_date, 
				l_rec_cashreceipt.cash_amt,modu_l1_cust_bal_amt 
				IF modu_first_ind THEN 
					LET modu_first_ind = false 
					PRINT "Forward Applied Cash Receipts" 
					PRINT "Receipt", 
					COLUMN 11, "Date", 
					COLUMN 24, "Paid Amt", 
					COLUMN 34, "Future Applied Amt" 
				END IF 
				LET l_rec_cashreceipt.applied_amt = l_rec_cashreceipt.cash_amt - modu_l1_cust_bal_amt 
				PRINT l_rec_cashreceipt.cash_num USING "#######", 
				COLUMN 11, l_rec_cashreceipt.cash_date USING "dd/mm/yy", 
				COLUMN 21, l_rec_cashreceipt.cash_amt USING "--------.--", 
				COLUMN 34, modu_l1_cust_bal_amt USING "--------.--", 
				COLUMN 57, modu_l1_cust_bal_amt USING "--------.--" 
				LET modu_l2_cust_bal_amt = modu_l2_cust_bal_amt - modu_l1_cust_bal_amt 
			END FOREACH 

			# now get the credits applied TO later invoices
			DECLARE t_c CURSOR FOR 
			SELECT credithead.cred_num, 
			credithead.cred_date, 
			credithead.total_amt, 
			sum(invoicepay.pay_amt) 
			FROM credithead, invoicepay, invoicehead 
			WHERE credithead.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND credithead.cust_code = p_rec_customer.cust_code 
			AND (credithead.year_num < modu_year_num 
			OR (credithead.year_num = modu_year_num 
			AND credithead.period_num <= modu_year_num)) 
			AND credithead.posted_flag = "Y" 
			AND invoicepay.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND invoicepay.cust_code = p_rec_customer.cust_code 
			AND invoicepay.pay_type_ind = TRAN_TYPE_CREDIT_CR 
			AND invoicepay.ref_num = credithead.cred_num 
			AND invoicehead.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND invoicehead.cust_code = p_rec_customer.cust_code 
			AND invoicehead.inv_num = invoicepay.inv_num 
			AND (invoicehead.year_num > modu_year_num 
			OR (invoicehead.year_num = modu_year_num 
			AND invoicehead.period_num > modu_year_num)) 
			GROUP BY credithead.cred_num, 
			credithead.cred_date, 
			credithead.total_amt 
			LET modu_first_ind = true 

			FOREACH t_c INTO l_rec_credithead.cred_num,l_rec_credithead.cred_date, 
				l_rec_credithead.total_amt,modu_l1_cust_bal_amt 
				IF modu_first_ind THEN 
					LET modu_first_ind = false 
					PRINT "Forward Applied Credits" 
					PRINT "Credits", 
					COLUMN 11, "Date", 
					COLUMN 24, "Cred Amt", 
					COLUMN 34, "Future Applied Amt" 
				END IF 
				LET l_rec_credithead.appl_amt = l_rec_credithead.total_amt - modu_l1_cust_bal_amt 
				PRINT l_rec_credithead.cred_num USING "#######", 
				COLUMN 11, l_rec_credithead.cred_date USING "dd/mm/yy", 
				COLUMN 21, l_rec_credithead.total_amt USING "--------.--", 
				COLUMN 34, modu_l1_cust_bal_amt USING "--------.--", 
				COLUMN 57, modu_l1_cust_bal_amt USING "--------.--" 
				LET modu_l2_cust_bal_amt = modu_l2_cust_bal_amt - modu_l1_cust_bal_amt 
			END FOREACH 

			PRINT COLUMN 57, "===========" 
			PRINT "Customer Total", 
			COLUMN 56, modu_l2_cust_bal_amt USING "---------.--" 
			LET modu_l3_cust_bal_amt = modu_l3_cust_bal_amt + modu_l2_cust_bal_amt 

			LET modu_local_bal_amt = conv_currency(modu_l2_cust_bal_amt, glob_rec_kandoouser.cmpy_code, 
			p_rec_customer.currency_code, "F", modu_rec_period.start_date, "S") 
			LET modu_tot_local_bal_amt = modu_tot_local_bal_amt + modu_local_bal_amt 
			PRINT 

		ON LAST ROW 
			PRINT "AR Ledger Balance (foreign currency)", 
			COLUMN 56, modu_l3_cust_bal_amt USING "---------.--" 
			PRINT "AR Ledger Balance (local currency)", 
			COLUMN 56, modu_tot_local_bal_amt USING "---------.--" 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	
			

			
END REPORT 