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
GLOBALS "../ar/AA_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/AAT_J_GLOBALS.4gl" 
############################################################
# MODULE Scope Variables
############################################################
DEFINE modu_rec_credithead RECORD LIKE credithead.* 
DEFINE modu_rec_cashreceipt RECORD LIKE cashreceipt.* 
DEFINE modu_rec_invoicepay RECORD LIKE invoicepay.* 
DEFINE modu_rec_doc RECORD 
	d_cust CHAR(8), 
	d_type_code CHAR(3), 
	d_date DATE, 
	d_ref INTEGER, 
	d_type CHAR(2), 
	d_age INTEGER, 
	d_bal money(12,2) 
END RECORD 
--DEFINE l_report_level CHAR(1) 
DEFINE modu_report_invoices CHAR(1)
DEFINE modu_tot_over1 DECIMAL(16,2) 
DEFINE modu_tot_over30 DECIMAL(16,2) 
DEFINE modu_tot_over60 DECIMAL(16,2) 
DEFINE modu_tot_over90 DECIMAL(16,2) 
DEFINE modu_tot_curr DECIMAL(16,2) 
DEFINE modu_tot_bal DECIMAL(16,2) 
DEFINE modu_tot_cust INTEGER 
DEFINE modu_age_date DATE 


#####################################################################
# FUNCTION AAT_J_main()
#
# Summary AAT_rpt_processing Version that allows entry of AAT_rpt_processing Date AND
#           unpicks transactions closed AFTER cutoff date
# Only works with invoices that have either manifest_num NULL OR <> -1
# OR manifest_num = -1 depending on selection
#####################################################################
FUNCTION AAT_J_main()	

	CALL setModuleId("AAT")

	IF NOT fgl_find_table("doctab") THEN		 
		CREATE temp TABLE doctab (d_cust CHAR(8), 
		d_type_code CHAR(3), 
		d_date DATE, 
		d_ref INTEGER, 
		d_type CHAR(2), 
		d_age INTEGER, 
		d_bal DECIMAL(16,2)) with no LOG 
		CREATE INDEX d_tmp_key ON doctab(d_ref) 
	END IF
	
	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 
			OPEN WINDOW Aa657 with FORM "A657" 
			CALL windecoration_a("A657") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title
		
			MENU " Special Summary AAT_rpt_processing" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","AAT_J","menu-special-summary-AAT_rpt_processing")
					CALL rpt_rmsreps_reset(NULL) 
					CALL AAT_J_rpt_process(AAT_J_rpt_query())
					
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				ON ACTION "Report" #COMMAND "Report" " SELECT criteria AND PRINT REPORT"
					CALL rpt_rmsreps_reset(NULL)
					IF fgl_find_table("doctab") THEN
						DELETE FROM doctab WHERE "1=1"
					END IF						

					CALL AAT_J_rpt_process(AAT_J_rpt_query()) 
		
				ON ACTION "Print Manager"#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "CANCEL" #COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus"
					EXIT MENU 
			END MENU 
		
			CLOSE WINDOW A657 
			
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL AAT_J_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW A657 with FORM "A657" 
			CALL windecoration_a("A657") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(AAT_J_rpt_query()) #save where clause in env 
			CLOSE WINDOW A657 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL AAT_J_rpt_process(get_url_sel_text())
	END CASE 

	IF fgl_find_table("doctab") THEN
		DROP TABLE doctab
	END IF
	
END FUNCTION 	
#####################################################################
# END FUNCTION AAT_J_main()
#####################################################################


#####################################################################
# FUNCTION AAT_J_rpt_query()
#
#
#####################################################################
FUNCTION AAT_J_rpt_query() 
	DEFINE l_where_text STRING 
	DEFINE l_over_text STRING 
	DEFINE l_report_level CHAR(1)

	MESSAGE kandoomsg2("A",1079,"")	#1079 Enter Date TO age REPORT TO, F9 FOR last AAT_rpt_processing date
	LET modu_age_date = today 
	LET l_report_level = "1" 
	
	INPUT modu_age_date, l_report_level WITHOUT DEFAULTS 
	FROM age_date, report_level

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","AAT_J","inp-rep-param") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 


		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON KEY (F9) infield(modu_age_date) 
					LET modu_age_date = glob_rec_arparms.cust_age_date 
					DISPLAY modu_age_date TO age_date  

					NEXT FIELD age_date 

		AFTER FIELD report_level 
			IF l_report_level IS NULL OR 
			(l_report_level <> "1" AND 
			l_report_level <> "2") THEN 
				LET l_report_level = 1 
				
				DISPLAY l_report_level TO report_level 

				NEXT FIELD report_level 
			END IF 
 
		AFTER INPUT 
			IF modu_age_date IS NULL THEN 
				LET modu_age_date = today 
			END IF 
			LET glob_rec_rpt_selector.ref1_date = modu_age_date
			LET glob_rec_rpt_selector.ref1_ind = l_report_level 
			
	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL 
	END IF 
	MESSAGE kandoomsg2("A",1001,"") 

	CONSTRUCT BY NAME l_where_text ON cust_code, 
	name_text, 
	addr1_text, 
	addr2_text, 
	city_text, 
	state_code, 
	post_code, 
	country_text, 
	currency_code, 
	curr_amt, 
	over1_amt, 
	over30_amt, 
	over60_amt, 
	over90_amt, 
	bal_amt, 
	hold_code, 
	type_code, 
	sale_code, 
	territory_code, 
	term_code, 
	contact_text, 
	tele_text,
	mobile_phone, 
	fax_text,
	email 


		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","AAT_J","construct-customer") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL 
	END IF 

	WHILE true 
		LET modu_report_invoices = fgl_winprompt(5,5, "Enter G FOR GE invoices only, N FOR other invoices", "", 50, 0) 
		IF int_flag OR quit_flag THEN 
			EXIT WHILE 
		END IF 

		LET modu_report_invoices = upshift(modu_report_invoices) 
		IF modu_report_invoices = "G" OR 
		modu_report_invoices = "N" THEN 
			EXIT WHILE 
		END IF 

	END WHILE 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL
	ELSE
		RETURN l_where_text
	END IF 
END FUNCTION 
#####################################################################
# END FUNCTION AAT_J_rpt_query()
#####################################################################


#####################################################################
# FUNCTION AAT_J_rpt_process(p_where_text)
#
#
#####################################################################
FUNCTION AAT_J_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT  	
	DEFINE l_rec_invoicehead RECORD LIKE invoicehead.*
	DEFINE l_rec_customer RECORD LIKE customer.*
	--DEFINE l_sum_inv money(12,2)
	--DEFINE l_sum_pay money(12,2)
	--DEFINE l_late_pay1 money(12,2)
	--DEFINE l_l_late_dis1 money(12,2)
	--DEFINE l_late_pays money(12,2)
	--DEFINE l_late_dis money(12,2)
	 
	DEFINE l_order_text CHAR(200)
	--DEFINE l_rpt_output CHAR(60) 

	LET modu_tot_over1 = 0 
	LET modu_tot_over30 = 0 
	LET modu_tot_over60 = 0 
	LET modu_tot_over90 = 0 
	LET modu_tot_curr = 0 
	LET modu_tot_bal = 0 
	LET modu_tot_cust = 0 
	CALL set_aging(glob_rec_kandoouser.cmpy_code,modu_age_date) 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"AAT_J_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT AAT_J_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	#------------------------------------------------------------
	IF glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_text IS NULL THEN 
		LET glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_text = 
		"Summary AAT_rpt_processing By Type (AAT_J) - Age Date: ", 
		modu_age_date USING "dd/mm/yy" 
		IF modu_report_invoices = "G" THEN 
			LET glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_text clipped, " - GE Only" 
		ELSE 
			LET glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_text clipped, " - Excl GE" 
		END IF 
	END IF 
	#------------------------------------------------------------

	IF glob_rec_arparms.report_ord_flag = "C" THEN 
		LET l_order_text = " cust_code " 
	ELSE 
		LET l_order_text = " name_text, cust_code " 
	END IF 
	LET l_query_text = "SELECT * FROM customer ", 
	" WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	" AND ", glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AAT_J_rpt_list")].sel_text clipped, 
	" ORDER BY type_code,",l_order_text clipped 

	PREPARE s_customer FROM l_query_text
	DECLARE c_customer CURSOR with HOLD FOR s_customer 

	FOREACH c_customer INTO l_rec_customer.* 
--		IF glob_rec_arparms.report_ord_flag = "C" THEN 
--			DISPLAY l_rec_customer.type_code," - ",l_rec_customer.cust_code at 1,17 
--
--		ELSE 
--			DISPLAY l_rec_customer.type_code," - ",l_rec_customer.name_text at 1,17 
--
--		END IF 

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
			IF (modu_report_invoices = "G" 
			AND (l_rec_invoicehead.manifest_num IS NULL OR 
			l_rec_invoicehead.manifest_num <> -1)) OR 
			(modu_report_invoices = "N" AND l_rec_invoicehead.manifest_num = -1) THEN 
				LET modu_rec_doc.d_cust = l_rec_invoicehead.cust_code 
				LET modu_rec_doc.d_type_code = l_rec_customer.type_code 
				LET modu_rec_doc.d_date = l_rec_invoicehead.inv_date 
				LET modu_rec_doc.d_ref = l_rec_invoicehead.inv_num 
				LET modu_rec_doc.d_type = TRAN_TYPE_INVOICE_IN 
				LET modu_rec_doc.d_age = get_age_bucket(TRAN_TYPE_INVOICE_IN,l_rec_invoicehead.due_date) 
				LET modu_rec_doc.d_bal = l_rec_invoicehead.total_amt - 
				l_rec_invoicehead.paid_amt 
				INSERT INTO doctab VALUES (modu_rec_doc.*) 
			END IF 
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
			IF modu_report_invoices = "G" THEN 
				IF modu_rec_credithead.cred_text = "IMP" 
				OR modu_rec_credithead.year_num > 1995 THEN 
					LET modu_rec_doc.d_cust = modu_rec_credithead.cust_code 
					LET modu_rec_doc.d_type_code = l_rec_customer.type_code 
					LET modu_rec_doc.d_ref = modu_rec_credithead.cred_num 
					LET modu_rec_doc.d_date = modu_rec_credithead.cred_date 
					LET modu_rec_doc.d_type = TRAN_TYPE_CREDIT_CR 
					LET modu_rec_doc.d_age = get_age_bucket(TRAN_TYPE_CREDIT_CR,modu_rec_credithead.cred_date) 
					LET modu_rec_doc.d_bal = modu_rec_credithead.appl_amt 
					- modu_rec_credithead.total_amt 
					INSERT INTO doctab VALUES (modu_rec_doc.*) 
				END IF 
			ELSE 
				IF modu_rec_credithead.cred_text != "IMP" 
				AND modu_rec_credithead.year_num <= 1995 THEN 
					LET modu_rec_doc.d_cust = modu_rec_credithead.cust_code 
					LET modu_rec_doc.d_type_code = l_rec_customer.type_code 
					LET modu_rec_doc.d_ref = modu_rec_credithead.cred_num 
					LET modu_rec_doc.d_date = modu_rec_credithead.cred_date 
					LET modu_rec_doc.d_type = TRAN_TYPE_CREDIT_CR 
					LET modu_rec_doc.d_age = get_age_bucket(TRAN_TYPE_CREDIT_CR,modu_rec_credithead.cred_date) 
					LET modu_rec_doc.d_bal = modu_rec_credithead.appl_amt 
					- modu_rec_credithead.total_amt 
					INSERT INTO doctab VALUES (modu_rec_doc.*) 
				END IF 
			END IF 
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
			IF modu_report_invoices = "G" THEN 
				IF modu_rec_cashreceipt.year_num > 1995 THEN 
					LET modu_rec_doc.d_cust = modu_rec_cashreceipt.cust_code 
					LET modu_rec_doc.d_type_code = l_rec_customer.type_code 
					LET modu_rec_doc.d_date = modu_rec_cashreceipt.cash_date 
					LET modu_rec_doc.d_ref = modu_rec_cashreceipt.cash_num 
					LET modu_rec_doc.d_type = TRAN_TYPE_RECEIPT_CA 
					LET modu_rec_doc.d_age = get_age_bucket(TRAN_TYPE_RECEIPT_CA,modu_rec_cashreceipt.cash_date) 
					LET modu_rec_doc.d_bal = modu_rec_cashreceipt.applied_amt 
					- modu_rec_cashreceipt.cash_amt 
					INSERT INTO doctab VALUES (modu_rec_doc.*) 
				END IF 
			ELSE 
				IF modu_rec_cashreceipt.year_num <= 1995 THEN 
					LET modu_rec_doc.d_cust = modu_rec_cashreceipt.cust_code 
					LET modu_rec_doc.d_type_code = l_rec_customer.type_code 
					LET modu_rec_doc.d_date = modu_rec_cashreceipt.cash_date 
					LET modu_rec_doc.d_ref = modu_rec_cashreceipt.cash_num 
					LET modu_rec_doc.d_type = TRAN_TYPE_RECEIPT_CA 
					LET modu_rec_doc.d_age = get_age_bucket(TRAN_TYPE_RECEIPT_CA,modu_rec_cashreceipt.cash_date) 
					LET modu_rec_doc.d_bal = modu_rec_cashreceipt.applied_amt 
					- modu_rec_cashreceipt.cash_amt 
					INSERT INTO doctab VALUES (modu_rec_doc.*) 
				END IF 
			END IF 
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
			# The invoice should already be in the temporary table IF it
			# was entered before the cutoff date AND paid later
			#################################################################
			SELECT * INTO modu_rec_doc.* 
			FROM doctab 
			WHERE d_ref = modu_rec_invoicepay.inv_num 
			AND d_type = TRAN_TYPE_INVOICE_IN 
			IF status = 0 THEN 
				LET modu_rec_doc.d_bal = modu_rec_doc.d_bal + modu_rec_invoicepay.pay_amt + 
				modu_rec_invoicepay.disc_amt 
				UPDATE doctab SET d_bal = modu_rec_doc.d_bal 
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
					IF (modu_report_invoices = "G" 
					AND (l_rec_invoicehead.manifest_num IS NULL OR 
					l_rec_invoicehead.manifest_num <> -1)) OR 
					(modu_report_invoices = "N" AND l_rec_invoicehead.manifest_num = -1) THEN 
						LET modu_rec_doc.d_cust = l_rec_invoicehead.cust_code 
						LET modu_rec_doc.d_type_code = l_rec_customer.type_code 
						LET modu_rec_doc.d_date = l_rec_invoicehead.inv_date 
						LET modu_rec_doc.d_ref = l_rec_invoicehead.inv_num 
						LET modu_rec_doc.d_type = TRAN_TYPE_INVOICE_IN 
						LET modu_rec_doc.d_age = get_age_bucket(TRAN_TYPE_INVOICE_IN, 
						l_rec_invoicehead.due_date) 
						LET modu_rec_doc.d_bal = l_rec_invoicehead.total_amt - 
						(l_rec_invoicehead.paid_amt - modu_rec_invoicepay.pay_amt) 
						INSERT INTO doctab VALUES (modu_rec_doc.*) 
					END IF 
				END IF 
			END IF 

			#################################################################
			# Need TO check temp table FOR cash receipt first. IF it IS there
			# THEN UPDATE it
			#################################################################
			IF modu_rec_invoicepay.pay_type_ind = TRAN_TYPE_RECEIPT_CA THEN 
				SELECT * INTO modu_rec_doc.* 
				FROM doctab 
				WHERE d_ref = modu_rec_invoicepay.ref_num 
				AND d_type = TRAN_TYPE_RECEIPT_CA 
				IF status = 0 THEN 
					LET modu_rec_doc.d_bal = modu_rec_doc.d_bal - modu_rec_invoicepay.pay_amt 
					UPDATE doctab SET d_bal = modu_rec_doc.d_bal 
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
						IF modu_report_invoices = "G" THEN 
							IF modu_rec_cashreceipt.year_num > 1995 THEN 
								LET modu_rec_doc.d_cust = modu_rec_cashreceipt.cust_code 
								LET modu_rec_doc.d_type_code = l_rec_customer.type_code 
								LET modu_rec_doc.d_date = modu_rec_cashreceipt.cash_date 
								LET modu_rec_doc.d_ref = modu_rec_cashreceipt.cash_num 
								LET modu_rec_doc.d_type = TRAN_TYPE_RECEIPT_CA 
								LET modu_rec_doc.d_age = get_age_bucket(TRAN_TYPE_RECEIPT_CA, 
								modu_rec_cashreceipt.cash_date) 
								LET modu_rec_doc.d_bal = (modu_rec_cashreceipt.applied_amt - 
								modu_rec_invoicepay.pay_amt ) 
								- modu_rec_cashreceipt.cash_amt 
								INSERT INTO doctab VALUES (modu_rec_doc.*) 
							END IF 
						ELSE 
							IF modu_rec_cashreceipt.year_num <= 1995 THEN 
								LET modu_rec_doc.d_cust = modu_rec_cashreceipt.cust_code 
								LET modu_rec_doc.d_type_code = l_rec_customer.type_code 
								LET modu_rec_doc.d_date = modu_rec_cashreceipt.cash_date 
								LET modu_rec_doc.d_ref = modu_rec_cashreceipt.cash_num 
								LET modu_rec_doc.d_type = TRAN_TYPE_RECEIPT_CA 
								LET modu_rec_doc.d_age = get_age_bucket(TRAN_TYPE_RECEIPT_CA, 
								modu_rec_cashreceipt.cash_date) 
								LET modu_rec_doc.d_bal = (modu_rec_cashreceipt.applied_amt - 
								modu_rec_invoicepay.pay_amt ) - modu_rec_cashreceipt.cash_amt 
								INSERT INTO doctab VALUES (modu_rec_doc.*) 
							END IF 
						END IF 
					END IF 
				END IF 
			ELSE 

				# Must be a credit
				SELECT * INTO modu_rec_doc.* 
				FROM doctab 
				WHERE d_ref = modu_rec_invoicepay.ref_num 
				AND d_type = TRAN_TYPE_CREDIT_CR 
				IF status = 0 THEN 
					LET modu_rec_doc.d_bal = modu_rec_doc.d_bal - modu_rec_invoicepay.pay_amt 
					UPDATE doctab SET d_bal = modu_rec_doc.d_bal 
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
						IF modu_report_invoices = "G" THEN 
							IF modu_rec_credithead.cred_text = "IMP" 
							OR modu_rec_credithead.year_num > 1995 THEN 
								LET modu_rec_doc.d_cust = modu_rec_credithead.cust_code 
								LET modu_rec_doc.d_type_code = l_rec_customer.type_code 
								LET modu_rec_doc.d_date = modu_rec_credithead.cred_date 
								LET modu_rec_doc.d_ref = modu_rec_credithead.cred_num 
								LET modu_rec_doc.d_type = TRAN_TYPE_CREDIT_CR 
								LET modu_rec_doc.d_age = get_age_bucket(TRAN_TYPE_CREDIT_CR, modu_rec_credithead.cred_date) 
								LET modu_rec_doc.d_bal = (modu_rec_credithead.appl_amt - 
								modu_rec_invoicepay.pay_amt ) - modu_rec_credithead.total_amt 
								INSERT INTO doctab VALUES (modu_rec_doc.*) 
							END IF 
						ELSE 
							IF modu_rec_credithead.cred_text != "IMP" 
							AND modu_rec_credithead.year_num <= 1995 THEN 
								LET modu_rec_doc.d_cust = modu_rec_credithead.cust_code 
								LET modu_rec_doc.d_type_code = l_rec_customer.type_code 
								LET modu_rec_doc.d_date = modu_rec_credithead.cred_date 
								LET modu_rec_doc.d_ref = modu_rec_credithead.cred_num 
								LET modu_rec_doc.d_type = TRAN_TYPE_CREDIT_CR 
								LET modu_rec_doc.d_age = get_age_bucket(TRAN_TYPE_CREDIT_CR, 
								modu_rec_credithead.cred_date) 
								LET modu_rec_doc.d_bal = (modu_rec_credithead.appl_amt - 
								modu_rec_invoicepay.pay_amt ) 
								- modu_rec_credithead.total_amt 
								INSERT INTO doctab VALUES (modu_rec_doc.*) 
							END IF 
						END IF 
					END IF 
				END IF 
			END IF 
		END FOREACH 

		DECLARE c_t_doctab CURSOR FOR 
		SELECT * FROM doctab 
		WHERE d_cust = l_rec_customer.cust_code 
		ORDER BY d_date,d_ref 

		FOREACH c_t_doctab INTO modu_rec_doc.* 
			#---------------------------------------------------------
			OUTPUT TO REPORT AAT_J_rpt_list(l_rpt_idx,modu_rec_doc.*) 
			IF NOT rpt_int_flag_handler2(NULL,NULL, NULL,l_rpt_idx) THEN
				EXIT FOREACH 
			END IF 
			#---------------------------------------------------------
		END FOREACH 

		DELETE FROM doctab WHERE 1=1 
		IF int_flag OR quit_flag THEN 
			#8503 Continue Report(Y/N)
			IF kandoomsg("U",8503,"") = "N" THEN 
				#9501 Report Terminated
				MESSAGE kandoomsg2("U",9501,"") 
				EXIT FOREACH 
			END IF 
		END IF 
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT AAT_J_rpt_list
	CALL rpt_finish("AAT_J_rpt_list")
	#------------------------------------------------------------
END FUNCTION 
#####################################################################
# END FUNCTION AAT_J_rpt_process(p_where_text)
#####################################################################


#####################################################################
# REPORT AAT_J_stmnt(p_rec_doc)
#
#
#####################################################################
REPORT AAT_J_rpt_list(p_rpt_idx,p_rec_doc) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_doc RECORD 
		d_cust CHAR(8), 
		d_type_code CHAR(8), 
		d_date DATE, 
		d_ref INTEGER, 
		d_type CHAR(2), 
		d_age INTEGER, 
		d_bal DECIMAL(16,2) 
	END RECORD
	DEFINE l_type_text CHAR(8)
	DEFINE l_rec_customer RECORD LIKE customer.*
	DEFINE l_rec_customertype RECORD LIKE customertype.*
	DEFINE l_bal_amt money(12,2)
	DEFINE l_over1_30  money(12,2)
	DEFINE l_over60_90 money(12,2)
	DEFINE l_over90 money(12,2)
	DEFINE l_over30_60 money(12,2)
	--DEFINE l_over1_30l money(12,2)
	DEFINE l_curr money(12,2)
	DEFINE l_bal money(12,2)
	
	DEFINE l_typ_bal_amt money(12,2)
	DEFINE l_typ_over60_90 money(12,2)
	DEFINE l_typ_over90 money(12,2)
	DEFINE l_typ_over30_60 money(12,2)
	DEFINE l_typ_over1_30 money(12,2)
	DEFINE l_typ_curr money(12,2)
	DEFINE l_typ_bal money(12,2)
	DEFINE l_conv_rate FLOAT
	DEFINE l_line1 CHAR(80)
	--DEFINE l_line2 CHAR(80)
	DEFINE l_offset1 SMALLINT 
	DEFINE l_offset2 SMALLINT 
	--DEFINE l_print_ind SMALLINT 

	OUTPUT 
 
	ORDER external BY p_rec_doc.d_type_code,p_rec_doc.d_cust 
	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].ref1_ind = "1" THEN #report_level
				LET l_type_text = " Type" 
			ELSE 
				LET l_type_text = "Customer" 
			END IF 
			PRINT COLUMN 01, l_type_text, 
			COLUMN 20, "Name", 
			COLUMN 42, "Balance", 
			COLUMN 58, "Current", 
			COLUMN 73, "1-30 Days", 
			COLUMN 87, "31-60 Days", 
			COLUMN 102,"61-90 Days", 
			COLUMN 119,"90 Plus", 
			COLUMN 128," Hold" 
			PRINT COLUMN 03, "Code", 
			COLUMN 28, "Currency", 
			COLUMN 75, "Overdue", 
			COLUMN 90, "Overdue", 
			COLUMN 105, "Overdue", 
			COLUMN 119, "Overdue", 
			COLUMN 127, " Sales" 
			PRINT COLUMN 1, "--------------------------------------------", 
			"--------------------------------------------", 
			"--------------------------------------------" 

		BEFORE GROUP OF p_rec_doc.d_type_code 
			LET l_typ_bal_amt = 0 
			LET l_typ_curr = 0 
			LET l_typ_over90 = 0 
			LET l_typ_over60_90 = 0 
			LET l_typ_over30_60 = 0 
			LET l_typ_over1_30 = 0 
			SELECT * INTO l_rec_customertype.* 
			FROM customertype 
			WHERE type_code = p_rec_doc.d_type_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].ref1_ind = "2" THEN #report_level
				NEED 3 LINES 
				SKIP 1 line 
				PRINT COLUMN 01, "Customer Type: ", 
				l_rec_customertype.type_code, " ", 
				l_rec_customertype.type_text 
				SKIP 1 line 
			END IF 

		BEFORE GROUP OF p_rec_doc.d_cust 
			SELECT * INTO l_rec_customer.* 
			FROM customer 
			WHERE cust_code = p_rec_doc.d_cust 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
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
					LET l_typ_over90 = l_typ_over90 + conv_currency(p_rec_doc.d_bal, glob_rec_kandoouser.cmpy_code, 
					l_rec_customer.currency_code, "F", today, "S") 
				WHEN (p_rec_doc.d_age > 60 AND p_rec_doc.d_age <= 90) 
					LET l_over60_90 = l_over60_90 + p_rec_doc.d_bal 
					LET l_typ_over60_90 = l_typ_over60_90 + conv_currency(p_rec_doc.d_bal, glob_rec_kandoouser.cmpy_code, 
					l_rec_customer.currency_code, "F", today, "S") 
				WHEN (p_rec_doc.d_age > 30 AND p_rec_doc.d_age <= 60) 
					LET l_over30_60 = l_over30_60 + p_rec_doc.d_bal 
					LET l_typ_over30_60 = l_typ_over30_60 + conv_currency(p_rec_doc.d_bal, glob_rec_kandoouser.cmpy_code, 
					l_rec_customer.currency_code, "F", today, "S") 
				WHEN (p_rec_doc.d_age > 0 AND p_rec_doc.d_age <= 30) 
					LET l_typ_over1_30 = l_typ_over1_30 + conv_currency(p_rec_doc.d_bal, glob_rec_kandoouser.cmpy_code, 
					l_rec_customer.currency_code, "F", today, "S") 
					LET l_over1_30 = l_over1_30 + p_rec_doc.d_bal 
				OTHERWISE 
					LET l_curr = l_curr + p_rec_doc.d_bal 
					LET l_typ_curr = l_typ_curr + conv_currency(p_rec_doc.d_bal, glob_rec_kandoouser.cmpy_code, 
					l_rec_customer.currency_code, "F", today, "S") 
			END CASE 
			LET l_bal_amt = l_bal_amt + p_rec_doc.d_bal 
			LET l_typ_bal_amt = l_typ_bal_amt + conv_currency(p_rec_doc.d_bal, glob_rec_kandoouser.cmpy_code, 
			l_rec_customer.currency_code, "F", today, "S") 

		AFTER GROUP OF p_rec_doc.d_cust 
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].ref1_ind = "2" THEN #report_level
				NEED 4 LINES 
				LET modu_tot_cust = modu_tot_cust + 1 
				PRINT COLUMN 1, l_rec_customer.cust_code, 
				COLUMN 10, l_rec_customer.name_text, 
				COLUMN 42, l_rec_customer.addr1_text, 
				COLUMN 73, l_rec_customer.contact_text, 
				COLUMN 94, l_rec_customer.tele_text, 
				COLUMN 115, l_rec_customer.mobile_phone[1,18] 
				#COLUMN 115, l_rec_customer.email[1,18] #possible extension
				PRINT COLUMN 30, l_rec_customer.currency_code, 
				COLUMN 34, l_bal_amt USING "----,---,--&.&&", 
				COLUMN 50, l_curr USING "----,---,--&.&&", 
				COLUMN 66, l_over1_30 USING "----,---,--&.&&", 
				COLUMN 82, l_over30_60 USING "----,---,--&.&&", 
				COLUMN 98, l_over60_90 USING "----,---,--&.&&", 
				COLUMN 114, l_over90 USING "----,---,--&.&&", 
				COLUMN 130, l_rec_customer.hold_code 
				SKIP 1 line 
			END IF 
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
			LET modu_tot_over90 = modu_tot_over90 + conv_currency(l_over90, glob_rec_kandoouser.cmpy_code, 
			l_rec_customer.currency_code, "F", today, "S") 

		AFTER GROUP OF p_rec_doc.d_type_code 
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].ref1_ind = "2" THEN #report_level
				PRINT COLUMN 35, "-----------------------------------------------", 
				"-----------------------------------------------" 
				PRINT COLUMN 01,"Total "; 
			END IF 
			PRINT COLUMN 1, p_rec_doc.d_type_code, 
			COLUMN 10, l_rec_customertype.type_text 
			PRINT COLUMN 30, glob_rec_arparms.currency_code, 
			COLUMN 34, l_typ_bal_amt USING "----,---,--&.&&", 
			COLUMN 50, l_typ_curr USING "----,---,--&.&&", 
			COLUMN 66, l_typ_over1_30 USING "----,---,--&.&&", 
			COLUMN 82, l_typ_over30_60 USING "----,---,--&.&&", 
			COLUMN 98, l_typ_over60_90 USING "----,---,--&.&&", 
			COLUMN 114, l_typ_over90 USING "----,---,--&.&&" 
			SKIP 2 LINES 

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
			COLUMN 114,modu_tot_over90 USING "----,---,--&.&&" 
			SKIP 2 line 
			
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = pageno
			
END REPORT
#####################################################################
# END REPORT AAT_J_stmnt(p_rec_doc)
##################################################################### 