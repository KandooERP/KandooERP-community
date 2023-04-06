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
GLOBALS "../ar/AA_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/AAL_GLOBALS.4gl" 
############################################################
# MODULE Scope Variables
############################################################
DEFINE modu_rec_credithead RECORD LIKE credithead.* 
DEFINE modu_rec_cashreceipt RECORD LIKE cashreceipt.* 
DEFINE modu_rec_doc RECORD 
	d_cust CHAR(8), 
	d_date DATE, 
	d_ref INTEGER, 
	d_age INTEGER, 
	d_bal money(12,2) 
END RECORD 
DEFINE modu_tot_over1 DECIMAL(16,2) 
DEFINE modu_tot_over30 DECIMAL(16,2) 
DEFINE modu_tot_over60 DECIMAL(16,2) 
DEFINE modu_tot_l_over90 DECIMAL(16,2) 
DEFINE modu_tot_curr DECIMAL(16,2) 
DEFINE modu_tot_bal DECIMAL(16,2) 
DEFINE modu_tot_cust INTEGER 
#####################################################################
# FUNCTION AAL_main()
#
# Summary Aging Version that allows entry of aging Date
#####################################################################
FUNCTION AAL_main()

	CALL setModuleId("AAL") 

	IF NOT fgl_find_table("doctab") THEN	
		CREATE temp TABLE doctab (d_cust CHAR(8), 
		d_date DATE, 
		d_ref INTEGER, 
		d_age INTEGER, 
		d_bal money(12,2)) with no LOG 
	END IF
	
	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode  
			OPEN WINDOW Aa652 with FORM "A652" 
			CALL windecoration_a("A652") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title

			MENU " Customer Summary Aging" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","AAL","menu-customer-summary-aging") 
					CALL rpt_rmsreps_reset(NULL)
					CALL AAL_rpt_process(AAL_rpt_query())
					
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				ON ACTION "Report" #COMMAND "Run" " SELECT criteria AND PRINT REPORT"
					CALL rpt_rmsreps_reset(NULL)
					CALL AAL_rpt_process(AAL_rpt_query())

				ON ACTION "Print Manager"	#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "CANCEL" #COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus"
					EXIT MENU 
			END MENU 

			CLOSE WINDOW A652 

		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL AAL_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW A652 with FORM "A652" 
			CALL windecoration_a("A652") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(AAL_rpt_query()) #save where clause in env 
			CLOSE WINDOW A652 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL AAL_rpt_process(get_url_sel_text())
	END CASE 

	IF fgl_find_table("doctab") THEN
		DROP TABLE doctab
	END IF
		
END FUNCTION
#####################################################################
# END FUNCTION AAL_main()
#####################################################################


#####################################################################
# FUNCTION AAL_rpt_query()
#
#
#####################################################################
FUNCTION AAL_rpt_query() 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_over_text STRING
	DEFINE l_age_date DATE
	DEFINE l_detail_ind CHAR(1)
	DEFINE l_where_text STRING
	DEFINE l_over_ind CHAR(1) 

	MENU "Which Balances? " 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","AAL","menu-which-balances") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "ALL" #COMMAND "All" "All Customers "
			LET glob_rec_rpt_selector.ref1_ind = "0" 
			EXIT MENU 

		ON ACTION "1+" #COMMAND "1+" "Customer with any overdue balance"
			LET glob_rec_rpt_selector.ref1_ind = "1" 
			EXIT MENU 

		ON ACTION "31+" #COMMAND "31+" "Customer with any balance 31+ days overdue "
			LET glob_rec_rpt_selector.ref1_ind = "2" 
			EXIT MENU 

		ON ACTION "61+" 	#COMMAND "61+" "Customer with any balance 61+ days overdue "
			LET glob_rec_rpt_selector.ref1_ind = "3" 
			EXIT MENU 

		ON ACTION "91+" 	#COMMAND "91+" "Customer with any overdue balance"
			LET glob_rec_rpt_selector.ref1_ind = "4" 
			EXIT MENU 

		ON ACTION "CANCEL"		#COMMAND KEY(interrupt)
			EXIT MENU 

	END MENU 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL 
	END IF 

	LET l_age_date = glob_rec_arparms.last_stmnt_date 
	LET l_detail_ind = "Y" --make yes the default 
	INPUT l_age_date, l_detail_ind WITHOUT DEFAULTS FROM age_date, detail_ind 


		BEFORE INPUT 
			CALL publish_toolbar("kandoo","AAL","inp-rep-param") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER FIELD age_date 
			IF l_age_date IS NULL THEN 
				LET l_age_date = glob_rec_arparms.last_stmnt_date 
				DISPLAY l_age_date TO age_date 

			END IF 

		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN 
				IF l_age_date IS NULL THEN 
					LET l_age_date = glob_rec_arparms.last_stmnt_date 
				END IF 
				IF l_detail_ind IS NULL THEN 
					MESSAGE kandoomsg2("U",9102,"") 
					NEXT FIELD detail_ind 
				END IF 
			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL 
	END IF 

	LET glob_rec_rpt_selector.ref1_date = l_age_date 
	LET glob_rec_rpt_selector.ref2_ind = l_detail_ind 
	MESSAGE kandoomsg("A",1001,"") 

	CONSTRUCT BY NAME l_where_text ON currency_code, 
	cust_code, 
	name_text, 
	addr1_text, 
	addr2_text, 
	city_text, 
	state_code, 
	post_code, 
	country_text, 
	tele_text, 
	mobile_phone, #added
	email, #added
	l_bal_amt, 
	inv_level_ind, 
	avg_cred_day_num, 
	last_inv_date, 
	last_pay_date, 
	type_code, 
	term_code, 
	cred_limit_amt, 
	onorder_amt, 
	hold_code, 
	sale_code, 
	territory_code 


		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","AAL","construct-customer") 

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
# FUNCTION AAL_rpt_process()
#
#
#####################################################################
FUNCTION AAL_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_rpt_idx SMALLINT  
	DEFINE l_query_text CHAR(1000) 
	DEFINE l_order_text CHAR(200) 
	DEFINE l_rec_invoicehead RECORD LIKE invoicehead.*
	DEFINE l_rec_customer RECORD LIKE customer.*
	--DEFINE l_sum_inv money(12,2) 
	--DEFINE l_sum_pay money(12,2) 
	DEFINE l_l_late_pay1 money(12,2) 	
	DEFINE l_l_late_dis1 money(12,2) 
	DEFINE l_late_pay money(12,2) 
	DEFINE l_late_dis money(12,2) 

	LET modu_tot_over1 = 0 
	LET modu_tot_over30 = 0 
	LET modu_tot_over60 = 0 
	LET modu_tot_l_over90 = 0 
	LET modu_tot_curr = 0 
	LET modu_tot_bal = 0 
	LET modu_tot_cust = 0 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"AA1_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT AA1_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	CALL set_aging(glob_rec_kandoouser.cmpy_code, glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref1_date) 

	IF glob_rec_arparms.report_ord_flag = "C" THEN 
		LET l_order_text = " ORDER BY cust_code " 
	ELSE 
		LET l_order_text = " ORDER BY name_text, cust_code " 
	END IF 

	LET l_query_text = "SELECT * FROM customer ", 
	"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND ", glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text clipped,l_order_text 

	PREPARE s_customer FROM l_query_text 
	DECLARE c_customer CURSOR with HOLD FOR s_customer 

	FOREACH c_customer INTO l_rec_customer.* 
		################################
		#   INVOICES
		################################
		DECLARE c_invoicehead CURSOR FOR 
		SELECT * FROM invoicehead 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = l_rec_customer.cust_code 
		AND inv_date <= glob_rec_rmsreps.ref1_date 
		AND (total_amt <> paid_amt OR 
		paid_date IS NOT NULL AND paid_date > glob_rec_rmsreps.ref1_date) 

		FOREACH c_invoicehead INTO l_rec_invoicehead.* 
			#        In the CASE of a late payment being included in the paid_amt
			#        figure subtract this payment FROM the paid_amt....
			#        need TO look AT original document
			SELECT sum(invoicepay.pay_amt), sum(invoicepay.disc_amt) 
			INTO l_late_pay, l_late_dis 
			FROM invoicepay, credithead 
			WHERE invoicepay.cmpy_code = l_rec_invoicehead.cmpy_code 
			AND invoicepay.cust_code = l_rec_invoicehead.cust_code 
			AND invoicepay.inv_num = l_rec_invoicehead.inv_num 
			AND invoicepay.pay_type_ind = TRAN_TYPE_CREDIT_CR 
			AND credithead.cmpy_code = l_rec_invoicehead.cmpy_code 
			AND credithead.cred_num = invoicepay.ref_num 
			AND credithead.cust_code = l_rec_invoicehead.cust_code 
			AND credithead.cred_date > glob_rec_rmsreps.ref1_date 

			IF l_late_pay IS NULL THEN 
				LET l_late_pay = 0 
			END IF 
			IF l_late_dis IS NULL THEN 
				LET l_late_dis = 0 
			END IF 

			SELECT sum(invoicepay.pay_amt), sum(invoicepay.disc_amt) 
			INTO l_l_late_pay1, l_l_late_dis1 
			FROM invoicepay, cashreceipt 
			WHERE invoicepay.cmpy_code = l_rec_invoicehead.cmpy_code 
			AND invoicepay.cust_code = l_rec_invoicehead.cust_code 
			AND invoicepay.inv_num = l_rec_invoicehead.inv_num 
			AND invoicepay.pay_type_ind = TRAN_TYPE_RECEIPT_CA 
			AND cashreceipt.cmpy_code = l_rec_invoicehead.cmpy_code 
			AND cashreceipt.cash_num = invoicepay.ref_num 
			AND cashreceipt.cust_code = l_rec_invoicehead.cust_code 
			AND cashreceipt.cash_date > glob_rec_rmsreps.ref1_date 

			IF l_l_late_pay1 IS NULL THEN 
				LET l_l_late_pay1 = 0 
			END IF 

			LET l_late_pay = l_late_pay + l_l_late_pay1 

			IF l_l_late_dis1 IS NULL THEN 
				LET l_l_late_dis1 = 0 
			END IF 

			LET l_late_dis = l_late_dis + l_l_late_dis1 
			LET modu_rec_doc.d_cust = l_rec_invoicehead.cust_code 
			LET modu_rec_doc.d_date = l_rec_invoicehead.inv_date 
			LET modu_rec_doc.d_ref = l_rec_invoicehead.inv_num 
			LET modu_rec_doc.d_age = get_age_bucket(TRAN_TYPE_INVOICE_IN,l_rec_invoicehead.due_date) 
			LET modu_rec_doc.d_bal = l_rec_invoicehead.total_amt - 
			(l_rec_invoicehead.paid_amt - (l_late_pay + l_late_dis)) 
			INSERT INTO doctab VALUES (modu_rec_doc.*) 

		END FOREACH 

		################################
		#   CREDITS
		################################
		DECLARE c_credithead CURSOR FOR 
		SELECT * FROM credithead 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = l_rec_customer.cust_code 
		AND cred_date <= glob_rec_rmsreps.ref1_date 
		AND total_amt <> appl_amt 

		FOREACH c_credithead INTO modu_rec_credithead.* 
			LET modu_rec_doc.d_cust = modu_rec_credithead.cust_code 
			LET modu_rec_doc.d_ref = modu_rec_credithead.cred_num 
			LET modu_rec_doc.d_date = modu_rec_credithead.cred_date 
			LET modu_rec_doc.d_age = get_age_bucket(TRAN_TYPE_CREDIT_CR,modu_rec_credithead.cred_date) 
			LET modu_rec_doc.d_bal = modu_rec_credithead.appl_amt - modu_rec_credithead.total_amt 
			INSERT INTO doctab VALUES (modu_rec_doc.*) 
		END FOREACH 

		################################
		#   CASH RECEIPTS
		################################
		DECLARE c_cashreceipt CURSOR FOR 
		SELECT * FROM cashreceipt 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = l_rec_customer.cust_code 
		AND cash_date <= glob_rec_rmsreps.ref1_date 
		AND cash_amt <> applied_amt 

		FOREACH c_cashreceipt INTO modu_rec_cashreceipt.* 
			#        In the CASE of a late invoice being included in the applied_amt
			#        figure subtract this payment FROM the applied_amt ....
			SELECT sum(P.pay_amt), sum(P.disc_amt) INTO l_late_pay, l_late_dis 
			FROM invoicepay p,invoicehead i 
			WHERE p.cmpy_code = modu_rec_cashreceipt.cmpy_code 
			AND p.cust_code = modu_rec_cashreceipt.cust_code 
			AND p.ref_num = modu_rec_cashreceipt.cash_num 
			AND p.cmpy_code = i.cmpy_code 
			AND p.cust_code = i.cust_code 
			AND p.inv_num = i.inv_num 
			AND i.inv_date > glob_rec_rmsreps.ref1_date 

			IF l_late_pay IS NULL THEN 
				LET l_late_pay = 0 
			END IF 

			IF l_late_dis IS NULL THEN 
				LET l_late_dis = 0 
			END IF 

			LET modu_rec_doc.d_cust = modu_rec_cashreceipt.cust_code 
			LET modu_rec_doc.d_date = modu_rec_cashreceipt.cash_date 
			LET modu_rec_doc.d_ref = modu_rec_cashreceipt.cash_num 
			LET modu_rec_doc.d_age = get_age_bucket(TRAN_TYPE_RECEIPT_CA,modu_rec_cashreceipt.cash_date) 
			LET modu_rec_doc.d_bal = modu_rec_cashreceipt.applied_amt 
			- modu_rec_cashreceipt.cash_amt 
			- l_late_pay 
			- l_late_dis 
			INSERT INTO doctab VALUES (modu_rec_doc.*) 

		END FOREACH 

		DECLARE c_t_doctab CURSOR FOR 
		SELECT * FROM doctab 
		WHERE d_cust = l_rec_customer.cust_code 
		ORDER BY d_date, d_ref 

		FOREACH c_t_doctab INTO modu_rec_doc.* 

			#---------------------------------------------------------
			OUTPUT TO REPORT AAL_rpt_list(l_rpt_idx,modu_rec_doc.*) 
			IF NOT rpt_int_flag_handler2(NULL,NULL,NULL,l_rpt_idx) THEN
				EXIT FOREACH 
			END IF 
			#---------------------------------------------------------
		END FOREACH 

		DELETE FROM doctab WHERE 1=1 

	END FOREACH 
	 
	#------------------------------------------------------------
	FINISH REPORT AAL_rpt_list
	CALL rpt_finish("AAL_rpt_list")
	#------------------------------------------------------------

	IF int_flag THEN
		RETURN FALSE
	ELSE
		RETURN TRUE
	END IF 	 

END FUNCTION 



#####################################################################
# REPORT AAL_rpt_list(p_rec_doc)
#
#
#####################################################################
REPORT AAL_rpt_list(p_rpt_idx,p_rec_doc) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_doc RECORD 
		d_cust CHAR(8), 
		d_date DATE, 
		d_ref INTEGER, 
		d_age INTEGER, 
		d_bal money(12,2) 
	END RECORD
	DEFINE l_rec_customer RECORD LIKE customer.*
	DEFINE l_bal_amt money(12,2)
	DEFINE l_over60_90 money(12,2)
	DEFINE l_over90 money(12,2)
	DEFINE l_over30_60 money(12,2)
	DEFINE l_over1_30 money(12,2)
	DEFINE l_curr money(12,2)
	--DEFINE l_bal money(12,2)	
	DEFINE l_conv_rate FLOAT
	DEFINE l_print_ind SMALLINT 

	OUTPUT 
	left margin 0 
	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text			
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		BEFORE GROUP OF p_rec_doc.d_cust 
			LET l_bal_amt = 0 
			LET l_curr = 0 
			LET l_over90 = 0 
			LET l_over60_90 = 0 
			LET l_over30_60 = 0 
			LET l_over1_30 = 0 

		ON EVERY ROW 
			CASE 
				WHEN (p_rec_doc.d_age > 90) 
					LET l_over90 = l_over90 + p_rec_doc.d_bal 
				WHEN (p_rec_doc.d_age > 60 AND p_rec_doc.d_age <= 90) 
					LET l_over60_90 = l_over60_90 + p_rec_doc.d_bal 
				WHEN (p_rec_doc.d_age > 30 AND p_rec_doc.d_age <= 60) 
					LET l_over30_60 = l_over30_60 + p_rec_doc.d_bal 
				WHEN (p_rec_doc.d_age > 0 AND p_rec_doc.d_age <= 30) 
					LET l_over1_30 = l_over1_30 + p_rec_doc.d_bal 
				OTHERWISE 
					LET l_curr = l_curr + p_rec_doc.d_bal 
			END CASE 
			LET l_bal_amt = l_bal_amt + p_rec_doc.d_bal 

		AFTER GROUP OF p_rec_doc.d_cust 
			LET l_print_ind = false 
			CASE 
				WHEN glob_arr_rec_rpt_rmsreps[p_rpt_idx].ref1_ind = "0" 
					LET l_print_ind = true 
				WHEN glob_arr_rec_rpt_rmsreps[p_rpt_idx].ref1_ind = "1" 
					IF (l_over1_30 + l_over30_60 + l_over60_90 + l_over90) > 0 THEN 
						LET l_print_ind = true 
					END IF 
				WHEN glob_arr_rec_rpt_rmsreps[p_rpt_idx].ref1_ind = "2" 
					IF (l_over30_60 + l_over60_90 + l_over90) > 0 THEN 
						LET l_print_ind = true 
					END IF 
				WHEN glob_arr_rec_rpt_rmsreps[p_rpt_idx].ref1_ind = "3" 
					IF (l_over60_90 + l_over90) > 0 THEN 
						LET l_print_ind = true 
					END IF 
				WHEN glob_arr_rec_rpt_rmsreps[p_rpt_idx].ref1_ind = "4" 
					IF (l_over90) > 0 THEN 
						LET l_print_ind = true 
					END IF 
			END CASE 
			IF l_print_ind THEN 
				NEED 3 LINES 
				LET modu_tot_cust = modu_tot_cust + 1 
				INITIALIZE l_rec_customer.* TO NULL 

				CALL db_customer_get_rec(UI_OFF,p_rec_doc.d_cust) RETURNING l_rec_customer.*					
--				SELECT * INTO l_rec_customer.* FROM customer 
--				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
--				AND cust_code = p_rec_doc.d_cust 
				IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].ref2_ind = "Y" THEN 
					PRINT COLUMN 1, l_rec_customer.cust_code, 
					COLUMN 10, l_rec_customer.name_text, 
					COLUMN 41, l_rec_customer.addr1_text, 
					COLUMN 61, l_rec_customer.contact_text, 
					COLUMN 81, l_rec_customer.tele_text, 
					COLUMN 101, l_rec_customer.mobile_phone 
					#COLUMN 101, l_rec_customer.email #possible extension
				ELSE 
					PRINT COLUMN 1, l_rec_customer.cust_code, 
					COLUMN 10, l_rec_customer.name_text 
				END IF 
				PRINT COLUMN 30, l_rec_customer.currency_code, 
				COLUMN 34, l_bal_amt USING "----,---,--&.&&", 
				COLUMN 50, l_curr USING "----,---,--&.&&", 
				COLUMN 66, l_over1_30 USING "----,---,--&.&&", 
				COLUMN 82, l_over30_60 USING "----,---,--&.&&", 
				COLUMN 98, l_over60_90 USING "----,---,--&.&&", 
				COLUMN 114, l_over90 USING "----,---,--&.&&", 
				COLUMN 130, l_rec_customer.hold_code 
				LET modu_tot_bal = modu_tot_bal + conv_currency(l_bal_amt, glob_rec_kandoouser.cmpy_code, 
				l_rec_customer.currency_code, "F", today, "S") 
				LET modu_tot_curr = modu_tot_curr + conv_currency(l_curr, glob_rec_kandoouser.cmpy_code, 
				l_rec_customer.currency_code, "F", today, "S") 
				LET modu_tot_over1 = modu_tot_over1 + conv_currency(l_over1_30, glob_rec_kandoouser.cmpy_code, 
				l_rec_customer.currency_code, "F", today, "S") 
				LET modu_tot_over30 = modu_tot_over30 + conv_currency(l_over30_60, glob_rec_kandoouser.cmpy_code, 
				l_rec_customer.currency_code, "F", today, "S") 
				LET modu_tot_over60 = modu_tot_over60 + conv_currency(l_over60_90, glob_rec_kandoouser.cmpy_code, 
				l_rec_customer.currency_code, "F", today, "S") 
				LET modu_tot_l_over90 = modu_tot_l_over90 + conv_currency(l_over90, glob_rec_kandoouser.cmpy_code, 
				l_rec_customer.currency_code, "F", today, "S") 
			END IF 

		ON LAST ROW 
			NEED 7 LINES 
			PRINT COLUMN 35, "-----------------------------------------------", 
			"-----------------------------------------------" 
			PRINT COLUMN 01,"In Base Currency Totals:", 
			COLUMN 31, modu_tot_bal USING "---,---,---,--&.&&", 
			COLUMN 66, modu_tot_over1 USING "----,---,--&.&&", 
			COLUMN 98, modu_tot_over60 USING "----,---,--&.&&" 
			PRINT COLUMN 01,"Total Customers: ", modu_tot_cust USING "###", 
			COLUMN 50, modu_tot_curr USING "----,---,--&.&&", 
			COLUMN 82, modu_tot_over30 USING "----,---,--&.&&", 
			COLUMN 114,modu_tot_l_over90 USING "----,---,--&.&&" 
			SKIP 2 line 
			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = pageno
			
			
END REPORT