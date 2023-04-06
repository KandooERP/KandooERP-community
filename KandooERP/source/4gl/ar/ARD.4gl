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
GLOBALS "../ar/ARD_GLOBALS.4gl" 
############################################################
# MODULE Scope Variables
############################################################
	DEFINE modu_rec_credithead RECORD LIKE credithead.* 
	DEFINE modu_rec_cashreceipt RECORD LIKE cashreceipt.* 
	DEFINE modu_rec_invoicepay RECORD LIKE invoicepay.* 
	DEFINE modu_rec_doc RECORD 
		d_cust CHAR(8), 
		d_date DATE, 
		d_ref INTEGER, 
		d_type CHAR(2), 
		d_age INTEGER, 
		d_bal money(12,2) 
	END RECORD 
	DEFINE modu_where_text CHAR(1000) 
	DEFINE modu_tot_over1 DECIMAL(16,2) 
	DEFINE modu_tot_over30 DECIMAL(16,2) 
	DEFINE modu_tot_over60 DECIMAL(16,2) 
	DEFINE modu_tot_over90 DECIMAL(16,2) 
	DEFINE modu_tot_curr DECIMAL(16,2) 
	DEFINE modu_tot_bal DECIMAL(16,2) 
	DEFINE modu_tot_cust INTEGER 
	DEFINE modu_over_ind SMALLINT 
	DEFINE modu_detail_ind CHAR(1) 
	DEFINE modu_age_date DATE 
	DEFINE modu_page_counter SMALLINT
#####################################################################
# MAIN
#
# Summary Aging Version that allows entry of aging Date AND
# unpicks transactions closed AFTER cutoff date
# There IS still one instance that we can NOT unpick AND that IS if
# a transaction was applied before the cutoff date but has since been
# unapplied. This IS because unnapply deletes the original invoicepay record
# AND therefore breaks the trail.
#####################################################################
FUNCTION ARD_main() 
	DEFER quit 
	DEFER interrupt

	CALL setModuleId("ARD")
	CALL init_report_ar() #report default data from db-arparms
	CALL AR_temp_tables_create()
	
	LET modu_page_counter = 0

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query

		WHEN RPT_OP_MENU #UI/MENU Mode 	
			OPEN WINDOW A652 with FORM "A652" 
			CALL windecoration_a("A652") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
		
			MENU " Customer Summary Aging" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","ARD","menu-customer-sum-aging") 
					CALL ARD_rpt_process(ARD_rpt_query())
					CALL AR_temp_tables_delete()
		
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				ON ACTION "REPORT"	--COMMAND "Run" " SELECT criteria AND PRINT REPORT" 
					CALL ARD_rpt_process(ARD_rpt_query())
					CALL AR_temp_tables_delete()
		
				ON ACTION "Print Manager" #COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "CANCEL"	#COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus"
					EXIT MENU 
		
			END MENU 

			CLOSE WINDOW A652 
	 
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL ARD_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW A652 with FORM "A652" 
			CALL windecoration_a("A652") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(ARD_rpt_query()) #save where clause in env 
			CLOSE WINDOW A652 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL ARD_rpt_process(get_url_sel_text())
	END CASE
	
			CALL AR_temp_tables_drop()
END FUNCTION 


#####################################################################
# FUNCTION ARD_rpt_query()
#
#
#####################################################################
FUNCTION ARD_rpt_query() 
	DEFINE l_where_text STRING

	LET modu_age_date = glob_rec_arparms.last_stmnt_date 
	LET modu_detail_ind = "Y" #Default is Detailed Listing

	INPUT modu_age_date,	modu_detail_ind WITHOUT DEFAULTS FROM age_date,	detail_ind ATTRIBUTE(UNBUFFERED) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","ARD","inp-age") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER FIELD age_date 
			IF modu_age_date IS NULL THEN 
				LET modu_age_date = glob_rec_arparms.last_stmnt_date 
				DISPLAY modu_age_date TO age_date 

			END IF 

		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN 
				IF modu_age_date IS NULL THEN 
					LET modu_age_date = glob_rec_arparms.last_stmnt_date 
					DISPLAY modu_age_date TO age_date 

				END IF 
				IF modu_detail_ind IS NULL THEN 
					MESSAGE kandoomsg2("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD detail_ind 
				END IF 
			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL 
	END IF 

	MESSAGE kandoomsg2("A",1001,"") 
	
	CONSTRUCT BY NAME l_where_text ON 
	customer.cust_code,
	customer.name_text, 
	customer.addr1_text, 
	customer.addr2_text, 
	customer.city_text, 
	customer.state_code, 
	customer.post_code, 
	customer.country_code, 
	customer.tele_text, 
	customer.mobile_phone, 
	customer.currency_code,
	customer.bal_amt, 
	customer.inv_level_ind, 
	customer.avg_cred_day_num, 
	customer.last_inv_date, 
	customer.last_pay_date, 
	customer.type_code, 
	customer.term_code, 
	customer.cred_limit_amt, 
	customer.onorder_amt, 
	customer.hold_code, 
	customer.sale_code, 
	customer.territory_code 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","ARD","construct-customer") 

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
# FUNCTION ARD_rpt_process()
# AGING !!!
#
#####################################################################
FUNCTION ARD_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT  
	DEFINE l_page_counter SMALLINT
	DEFINE l_rec_invoicehead RECORD LIKE invoicehead.*
	DEFINE l_rec_customer RECORD LIKE customer.*
	DEFINE l_order_text CHAR(200) 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"ARD_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	

	START REPORT ARD_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------
	
	LET modu_tot_over1 = 0 
	LET modu_tot_over30 = 0 
	LET modu_tot_over60 = 0 
	LET modu_tot_over90 = 0 
	LET modu_tot_curr = 0 
	LET modu_tot_bal = 0 
	LET modu_tot_cust = 0 

	CALL set_aging(glob_rec_kandoouser.cmpy_code,modu_age_date) 

#------------------------------------------------------------	
#	IF glob_rec_rmsreps.report_text IS NULL THEN 
#		LET glob_rec_rmsreps.report_text = "Customer Summary Aging (Menu ARD) - Age Date: ",	modu_age_date USING "dd/mm/yy"
#	END IF 



	IF glob_rec_arparms.report_ord_flag = "C" THEN 
		LET l_order_text = " ORDER BY cust_code " 
	ELSE 
		LET l_order_text = " ORDER BY name_text, cust_code " 
	END IF
	 
	LET l_query_text = "SELECT * FROM customer ", 
	"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND ", p_where_text CLIPPED," ",
	l_order_text CLIPPED
 	 
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
		AND inv_date <= modu_age_date 
		AND ((total_amt <> paid_amt) OR 
		(paid_date IS NOT NULL AND paid_date >= modu_age_date)) 
		
		FOREACH c_invoicehead INTO l_rec_invoicehead.* 
			LET modu_rec_doc.d_cust = l_rec_invoicehead.cust_code 
			LET modu_rec_doc.d_date = l_rec_invoicehead.inv_date 
			LET modu_rec_doc.d_ref = l_rec_invoicehead.inv_num 
			LET modu_rec_doc.d_type = TRAN_TYPE_INVOICE_IN 
			LET modu_rec_doc.d_age = get_age_bucket(TRAN_TYPE_INVOICE_IN,l_rec_invoicehead.due_date) 
			LET modu_rec_doc.d_bal = l_rec_invoicehead.total_amt - 
			l_rec_invoicehead.paid_amt 
			INSERT INTO t_doctab VALUES (modu_rec_doc.*) 
		END FOREACH 
		
		################################
		#   CREDITS
		################################
		DECLARE c_credithead CURSOR FOR 
		SELECT * FROM credithead 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = l_rec_customer.cust_code 
		AND cred_date <= modu_age_date 
		AND total_amt <> appl_amt 
		FOREACH c_credithead INTO modu_rec_credithead.* 
			LET modu_rec_doc.d_cust = modu_rec_credithead.cust_code 
			LET modu_rec_doc.d_ref = modu_rec_credithead.cred_num 
			LET modu_rec_doc.d_date = modu_rec_credithead.cred_date 
			LET modu_rec_doc.d_type = TRAN_TYPE_CREDIT_CR 
			LET modu_rec_doc.d_age = get_age_bucket(TRAN_TYPE_CREDIT_CR,modu_rec_credithead.cred_date) 
			LET modu_rec_doc.d_bal = modu_rec_credithead.appl_amt - modu_rec_credithead.total_amt 
			INSERT INTO t_doctab VALUES (modu_rec_doc.*) 
		END FOREACH 
		
		################################
		#   CASH RECEIPTS
		################################
		DECLARE c_cashreceipt CURSOR FOR 
		SELECT * FROM cashreceipt 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = l_rec_customer.cust_code 
		AND cash_date <= modu_age_date 
		AND cash_amt <> applied_amt 
		FOREACH c_cashreceipt INTO modu_rec_cashreceipt.* 
			LET modu_rec_doc.d_cust = modu_rec_cashreceipt.cust_code 
			LET modu_rec_doc.d_date = modu_rec_cashreceipt.cash_date 
			LET modu_rec_doc.d_ref = modu_rec_cashreceipt.cash_num 
			LET modu_rec_doc.d_type = TRAN_TYPE_RECEIPT_CA 
			LET modu_rec_doc.d_age = get_age_bucket(TRAN_TYPE_RECEIPT_CA,modu_rec_cashreceipt.cash_date) 
			LET modu_rec_doc.d_bal = modu_rec_cashreceipt.applied_amt - modu_rec_cashreceipt.cash_amt 
			INSERT INTO t_doctab VALUES (modu_rec_doc.*) 
		END FOREACH 
		
		################################
		#   INVOICEPAYS
		################################
		# Now we need TO reopen anything closed since the cutoff date
		#################################################################
		DECLARE c_invoicepay CURSOR FOR 
		SELECT * FROM invoicepay 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = l_rec_customer.cust_code 
		AND pay_date > modu_age_date 
		FOREACH c_invoicepay INTO modu_rec_invoicepay.*
		 
			#################################################################
			# The invoice will already be in the temporary table IF it
			# was entered before the cutoff date AND paid later
			#################################################################
			SELECT * INTO modu_rec_doc.* 
			FROM t_doctab 
			WHERE d_ref = modu_rec_invoicepay.inv_num 
			AND d_type = TRAN_TYPE_INVOICE_IN 
			IF status = 0 THEN 
				LET modu_rec_doc.d_bal = modu_rec_doc.d_bal + modu_rec_invoicepay.pay_amt + modu_rec_invoicepay.disc_amt 
				UPDATE t_doctab SET d_bal = modu_rec_doc.d_bal 
				WHERE d_ref = modu_rec_invoicepay.inv_num 
				AND d_type = TRAN_TYPE_INVOICE_IN 
			ELSE 
		
				###################################################################
				# But paid date IS NOT always applied date so check Invoice if
				# it IS NOT in temporary table AND add it IF it was entered
				# before the cutoff date
				###################################################################
				SELECT * INTO l_rec_invoicehead.* 
				FROM invoicehead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND inv_num = modu_rec_invoicepay.inv_num 
				AND cust_code = l_rec_customer.cust_code 
				AND inv_date <= modu_age_date 
				IF status = 0 THEN 
					LET modu_rec_doc.d_cust = l_rec_invoicehead.cust_code 
					LET modu_rec_doc.d_date = l_rec_invoicehead.inv_date 
					LET modu_rec_doc.d_ref = l_rec_invoicehead.inv_num 
					LET modu_rec_doc.d_type = TRAN_TYPE_INVOICE_IN 
					LET modu_rec_doc.d_age = get_age_bucket(TRAN_TYPE_INVOICE_IN,l_rec_invoicehead.due_date) 
					LET modu_rec_doc.d_bal = l_rec_invoicehead.total_amt - 
					l_rec_invoicehead.paid_amt + 
					modu_rec_invoicepay.pay_amt + 
					modu_rec_invoicepay.disc_amt 

					INSERT INTO t_doctab VALUES (modu_rec_doc.*) 
				END IF 
			END IF 

			#################################################################
			# Need TO check temp table FOR cash receipt first. IF it IS there
			# THEN UPDATE it
			#################################################################
			IF modu_rec_invoicepay.pay_type_ind = TRAN_TYPE_RECEIPT_CA THEN 
				SELECT * INTO modu_rec_doc.* 
				FROM t_doctab 
				WHERE d_ref = modu_rec_invoicepay.ref_num 
				AND d_type = TRAN_TYPE_RECEIPT_CA 
				IF status = 0 THEN 
					LET modu_rec_doc.d_bal = modu_rec_doc.d_bal - modu_rec_invoicepay.pay_amt 
					UPDATE t_doctab SET d_bal = modu_rec_doc.d_bal 
					WHERE d_ref = modu_rec_invoicepay.ref_num 
					AND d_type = TRAN_TYPE_RECEIPT_CA 
				ELSE 

					#################################################################
					# IF cashreceipt IS NOT in temp table THEN SELECT it AND INSERT
					# it IF it was entered before cutoff date
					#################################################################
					SELECT * INTO modu_rec_cashreceipt.* 
					FROM cashreceipt 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cash_num = modu_rec_invoicepay.ref_num 
					AND cash_date <= modu_age_date 
					IF status = 0 THEN 
						LET modu_rec_doc.d_cust = modu_rec_cashreceipt.cust_code 
						LET modu_rec_doc.d_date = modu_rec_cashreceipt.cash_date 
						LET modu_rec_doc.d_ref = modu_rec_cashreceipt.cash_num 
						LET modu_rec_doc.d_type = TRAN_TYPE_RECEIPT_CA 
						LET modu_rec_doc.d_age = get_age_bucket(TRAN_TYPE_RECEIPT_CA, modu_rec_cashreceipt.cash_date) 
						LET modu_rec_doc.d_bal = (modu_rec_cashreceipt.applied_amt - 
						modu_rec_invoicepay.pay_amt ) 
						- modu_rec_cashreceipt.cash_amt 
						INSERT INTO t_doctab VALUES (modu_rec_doc.*) 
					END IF 
				END IF 
			ELSE 
				# Must be a credit
				SELECT * INTO modu_rec_doc.* 
				FROM t_doctab 
				WHERE d_ref = modu_rec_invoicepay.ref_num 
				AND d_type = TRAN_TYPE_CREDIT_CR 
				IF status = 0 THEN 
					LET modu_rec_doc.d_bal = modu_rec_doc.d_bal - modu_rec_invoicepay.pay_amt 
					UPDATE t_doctab SET d_bal = modu_rec_doc.d_bal 
					WHERE d_ref = modu_rec_invoicepay.ref_num 
					AND d_type = TRAN_TYPE_CREDIT_CR 
				ELSE
				 
					#################################################################
					# IF credit IS NOT in temp table THEN SELECT it AND INSERT
					# it IF it was entered before cutoff date
					#################################################################
					SELECT * INTO modu_rec_credithead.* 
					FROM credithead 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cred_num = modu_rec_invoicepay.ref_num 
					AND cred_date <= modu_age_date 
					IF status = 0 THEN 
						LET modu_rec_doc.d_cust = modu_rec_credithead.cust_code 
						LET modu_rec_doc.d_date = modu_rec_credithead.cred_date 
						LET modu_rec_doc.d_ref = modu_rec_credithead.cred_num 
						LET modu_rec_doc.d_type = TRAN_TYPE_CREDIT_CR 
						LET modu_rec_doc.d_age = get_age_bucket(TRAN_TYPE_CREDIT_CR, 
						modu_rec_credithead.cred_date) 
						LET modu_rec_doc.d_bal = (modu_rec_credithead.appl_amt - modu_rec_invoicepay.pay_amt ) - modu_rec_credithead.total_amt 
						INSERT INTO t_doctab VALUES (modu_rec_doc.*) 
					END IF 
				END IF 
			END IF 
		END FOREACH 

		DECLARE c_t_doctab CURSOR FOR 
		SELECT * FROM t_doctab 
		WHERE d_cust = l_rec_customer.cust_code 
		ORDER BY d_date, d_ref 

	
		FOREACH c_t_doctab INTO modu_rec_doc.* 
			#---------------------------------------------------------
			OUTPUT TO REPORT ARD_rpt_list(l_rpt_idx,modu_rec_doc.*) 
			IF NOT rpt_int_flag_handler2("Customer/Credit Code:",modu_rec_doc.d_cust, modu_rec_doc.d_ref,l_rpt_idx) THEN
				EXIT FOREACH 
			END IF 
			#---------------------------------------------------------		
			LET modu_page_counter =  modu_page_counter + 1
		END FOREACH 

		DELETE FROM t_doctab WHERE 1=1 
		IF int_flag OR quit_flag THEN 
			#8503 Continue Report(Y/N)
			IF kandoomsg("U",8503,"") = "N" THEN 
				#9501 Report Terminated
				ERROR kandoomsg2("U",9501,"") 
				EXIT FOREACH 
			END IF 
		END IF 

	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT ARD_rpt_list
	RETURN rpt_finish("ARD_rpt_list")
	#------------------------------------------------------------

END FUNCTION 


#####################################################################
# REPORT ARD_rpt_list(p_rpt_idx,p_rec_doc)
#
#
#####################################################################
REPORT ARD_rpt_list(p_rpt_idx,p_rec_doc)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx] 
	DEFINE p_rec_doc RECORD 
		d_cust CHAR(8), 
		d_date DATE, 
		d_ref INTEGER, 
		d_type CHAR(2), 
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
	DEFINE l_bal money(12,2)	
	DEFINE l_conv_rate FLOAT
	DEFINE l_line1 CHAR(80)
	DEFINE l_line2 CHAR(80)
	DEFINE l_offset1 SMALLINT 
	DEFINE l_offset2 SMALLINT 
	DEFINE l_print_ind SMALLINT 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,PAGENO) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 CLIPPED #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 CLIPPED #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text CLIPPED 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text CLIPPED 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]

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
			WHEN modu_over_ind = 0 
				LET l_print_ind = true 
			WHEN modu_over_ind = 1 
				IF (l_over1_30 + l_over30_60 + l_over60_90 + l_over90) > 0 THEN 
					LET l_print_ind = true 
				END IF 
			WHEN modu_over_ind = 2 
				IF (l_over30_60 + l_over60_90 + l_over90) > 0 THEN 
					LET l_print_ind = true 
				END IF 
			WHEN modu_over_ind = 3 
				IF (l_over60_90 + l_over90) > 0 THEN 
					LET l_print_ind = true 
				END IF 
			WHEN modu_over_ind = 4 
				IF (l_over90) > 0 THEN 
					LET l_print_ind = true 
				END IF 
		END CASE 
			
		IF l_print_ind THEN 
			NEED 3 LINES 
			LET modu_tot_cust = modu_tot_cust + 1 
			INITIALIZE l_rec_customer.* TO NULL 
			SELECT * INTO l_rec_customer.* FROM customer 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cust_code = p_rec_doc.d_cust 
			IF modu_detail_ind = "Y" THEN
				PRINT	
				COLUMN 01,  l_rec_customer.cust_code CLIPPED," ",
				COLUMN 10, 	l_rec_customer.name_text CLIPPED," ", 
								l_rec_customer.addr1_text CLIPPED," ", 
								l_rec_customer.contact_text CLIPPED," ", 
								l_rec_customer.tele_text CLIPPED," ", 
								l_rec_customer.mobile_phone CLIPPED
			ELSE 
				PRINT 
				COLUMN 01,  l_rec_customer.cust_code CLIPPED," ", 
				COLUMN 10, 	l_rec_customer.name_text CLIPPED 
			END IF
			PRINT 
			COLUMN 30, l_rec_customer.currency_code CLIPPED, 
			COLUMN 36, l_bal_amt   USING "----,---,--&.&&", 
			COLUMN 54, l_curr      USING "----,---,--&.&&", 
			COLUMN 72, l_over1_30  USING "----,---,--&.&&", 
			COLUMN 90, l_over30_60 USING "----,---,--&.&&", 
			COLUMN 108,l_over60_90 USING "----,---,--&.&&", 
			COLUMN 126,l_over90    USING "----,---,--&.&&", 
			COLUMN 144,l_rec_customer.hold_code CLIPPED
			LET modu_tot_bal = modu_tot_bal + conv_currency(l_bal_amt, glob_rec_kandoouser.cmpy_code,	l_rec_customer.currency_code, "F", today, "S") 
			LET modu_tot_curr = modu_tot_curr + conv_currency(l_curr, glob_rec_kandoouser.cmpy_code, 	l_rec_customer.currency_code, "F", today, "S") 
			LET modu_tot_over1 = modu_tot_over1 + conv_currency(l_over1_30, glob_rec_kandoouser.cmpy_code, l_rec_customer.currency_code, "F", today, "S") 
			LET modu_tot_over30 = modu_tot_over30 + conv_currency(l_over30_60, glob_rec_kandoouser.cmpy_code, l_rec_customer.currency_code, "F", today, "S") 
			LET modu_tot_over60 = modu_tot_over60 + conv_currency(l_over60_90, glob_rec_kandoouser.cmpy_code, l_rec_customer.currency_code, "F", today, "S") 
			LET modu_tot_over90 = modu_tot_over90 + conv_currency(l_over90, glob_rec_kandoouser.cmpy_code, l_rec_customer.currency_code, "F", today, "S") 
		END IF 

	ON LAST ROW 
		NEED 7 LINES 
		PRINT COLUMN 47, "-----------------------------------------------", 
		"-----------------------------------------------" 
		PRINT 
		COLUMN 01,"In Base Currency Totals:", 
		COLUMN 33, modu_tot_bal    USING "---,---,---,--&.&&", 
		COLUMN 72, modu_tot_over1  USING "----,---,--&.&&", 
		COLUMN 108,modu_tot_over60 USING "----,---,--&.&&" 
		PRINT 
		COLUMN 01,"Total Customers: ", modu_tot_cust USING "###", 
		COLUMN 54, modu_tot_curr   USING "----,---,--&.&&", 
		COLUMN 90, modu_tot_over30 USING "----,---,--&.&&", 
		COLUMN 126,modu_tot_over90 USING "----,---,--&.&&" 
		SKIP 2 line
		#End Of Report
		IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
			PRINT COLUMN 01,"Selection Criteria:" 
			PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
		END IF 
		PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	

END REPORT 