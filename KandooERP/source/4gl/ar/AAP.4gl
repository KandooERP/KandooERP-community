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
GLOBALS "../ar/AAP_GLOBALS.4gl" 
############################################################
# MODULE Scope Variables
############################################################
DEFINE modu_base_currency LIKE currency.currency_code 
DEFINE modu_age_year LIKE period.year_num 
DEFINE modu_age_period LIKE period.period_num 
DEFINE modu_age_date DATE 
DEFINE modu_report_level CHAR(1) 
DEFINE modu_aging_date DATE 
DEFINE modu_future_date DATE 
DEFINE modu_over1_date DATE 
DEFINE modu_over30_date DATE 
DEFINE modu_over60_date DATE 
DEFINE modu_over90_date DATE 
DEFINE modu_credit_aging SMALLINT 
DEFINE modu_tot_over1 DECIMAL(16,2)
DEFINE modu_tot_over30 DECIMAL(16,2)
DEFINE modu_tot_over60 DECIMAL(16,2) 
DEFINE modu_tot_over90 DECIMAL(16,2) 
DEFINE modu_tot_curr DECIMAL(16,2) 
DEFINE modu_tot_fwd DECIMAL(16,2) 
DEFINE modu_tot_bal DECIMAL(16,2) 
DEFINE modu_tot_cust INTEGER 
#####################################################################
# FUNCTION AAP_main()
#
# Customer Aging by Fiscal Period
#           1) Allows entry of aging year AND period
#           2) Report TO be printed TO Type, Vendor OR Detail level
#           3) Unpicks transactions closed AFTER cutoff year AND period
#####################################################################
FUNCTION AAP_main()

	CALL setModuleId("AAP")
	
	SELECT base_currency_code 
	INTO modu_base_currency 
	FROM glparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND key_code = '1' 

	IF status = NOTFOUND THEN 
		CALL fgl_winmessage("ERROR",kandoomsg2("U",3511,""),"ERROR") 
		#3511 GL Parameters NOT SET up
		EXIT PROGRAM 
	END IF 

	CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,today) 
	RETURNING modu_age_year, 
	modu_age_period 
	LET modu_report_level = "1" 

	IF NOT fgl_find_table("f_document") THEN
		CREATE temp TABLE f_document (cust_code CHAR(8), 
		type_code CHAR(3), 
		trans_date DATE, 
		ref_num INTEGER, 
		trans_type CHAR(2), 
		tran_age INTEGER, 
		conv_qty FLOAT, 
		year_num SMALLINT, 
		period_num SMALLINT, 
		trans_amt DECIMAL(16,2), 
		base_trans_amt DECIMAL (16,2)) with no LOG 
	END IF
	
	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 
			OPEN WINDOW A707 with FORM "A707" 
			CALL windecoration_a("A707") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title

			DISPLAY modu_age_year TO age_year
			DISPLAY modu_age_period TO age_period 
			DISPLAY modu_report_level TO report_level 

			MENU " Customer Aging by Period" 

				BEFORE MENU 
					CALL publish_toolbar("kandoo","AAP","menu-customer-aging-period")
					CALL rpt_rmsreps_reset(NULL) 
					CALL AAP_rpt_process(AAP_rpt_query())
					
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				ON ACTION "Report" #COMMAND "Run" " SELECT criteria AND PRINT REPORT"
					CALL rpt_rmsreps_reset(NULL)
					IF fgl_find_table("f_document") THEN
						DELETE FROM f_document WHERE "1=1"
					END IF			
										
					CALL AAP_rpt_process(AAP_rpt_query())

				ON ACTION "Print" #COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog ("URS","","","","") 

				ON ACTION "CANCEL" #COMMAND KEY(interrupt,"E")"Exit" " RETURN TO menus"
					EXIT MENU 


			END MENU 

			CLOSE WINDOW A707 

		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL AAP_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW A707 with FORM "A112" 
			CALL windecoration_a("A112") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(AAP_rpt_query()) #save where clause in env 
			CLOSE WINDOW A707 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL AAP_rpt_process(get_url_sel_text())
	END CASE 

	IF fgl_find_table("f_document") THEN
		DROP TABLE f_document
	END IF
		
END FUNCTION 
#####################################################################
# END FUNCTION AAP_main()
#####################################################################


#####################################################################
# FUNCTION AAP_rpt_query()
#
#
#####################################################################
FUNCTION AAP_rpt_query() 
	DEFINE l_where_text CHAR(500) 
	DEFINE l_msgresp LIKE language.yes_flag
	
	CLEAR FORM 
	DISPLAY modu_age_year TO age_year 
	DISPLAY modu_age_period TO age_period 
	DISPLAY modu_report_level TO report_level

	LET l_msgresp = kandoomsg("A",1034,"") 
	#1034 Enter REPORT parameters - ESC TO Continue
	INPUT modu_age_year, 	modu_age_period,	modu_report_level WITHOUT DEFAULTS
	FROM age_year, 	age_period,	report_level

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","AAP","inp-rep-param") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER FIELD age_period 
			SELECT end_date 
			INTO modu_age_date 
			FROM period 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND year_num = modu_age_year 
			AND period_num = modu_age_period 
			IF status = NOTFOUND THEN 
				LET l_msgresp = kandoomsg("G",9012,"")	#9012 Fiscal year AND period invalid
				NEXT FIELD age_year 
			END IF 
			
			DISPLAY modu_age_date TO age_date  

		AFTER FIELD report_level 
			IF modu_report_level IS NULL OR 
			(modu_report_level NOT matches "[123]") THEN 
				LET modu_report_level = 1 
				
				DISPLAY modu_report_level TO report_level  

				NEXT FIELD report_level 
			END IF 

		AFTER INPUT 
			SELECT end_date 
			INTO modu_age_date 
			FROM period 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND year_num = modu_age_year 
			AND period_num = modu_age_period 
			IF status = NOTFOUND THEN 
				LET l_msgresp = kandoomsg("G",9012,"") 
				#9012 Fiscal year AND period invalid
				NEXT FIELD age_year 
			END IF 
			IF modu_report_level IS NULL OR 
			NOT (modu_report_level matches "[123]") THEN 
				LET modu_report_level = 1 
				DISPLAY modu_report_level TO report_level 

				NEXT FIELD report_level 
			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL 
	END IF 

	MESSAGE kandoomsg("U",1001,"") 	#1001 Enter Selection Criteria - ESC TO Continue
	CONSTRUCT BY NAME l_where_text ON cust_code, 
	name_text, 
	addr1_text, 
	addr2_text, 
	city_text, 
	state_code, 
	post_code, 
	country_code, 
	type_code, 
	currency_code, 
	term_code, 
	tax_code, 
	sale_code, 
	territory_code 


		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","AAP","construct-customer") 

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
	
	LET glob_rec_rpt_selector.sel_text = l_where_text 
	LET glob_rec_rpt_selector.ref1_num = modu_age_year 
	LET glob_rec_rpt_selector.ref2_num = modu_age_period 
	LET glob_rec_rpt_selector.ref1_date = modu_age_date 
	LET glob_rec_rpt_selector.ref1_code = modu_report_level 

	RETURN l_where_text
END FUNCTION 
#####################################################################
# END FUNCTION AAP_rpt_query()
#####################################################################


#####################################################################
# FUNCTION AAP_rpt_process()
#
#
#####################################################################
FUNCTION AAP_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_rpt_idx SMALLINT 
	DEFINE l_rec_document RECORD 
		cust_code LIKE customer.cust_code, 
		type_code LIKE customer.type_code, 
		trans_date LIKE invoicehead.inv_date, 
		ref_num LIKE invoicehead.inv_num, 
		trans_type LIKE araudit.tran_type_ind, 
		trans_age INTEGER, 
		conv_qty LIKE invoicehead.conv_qty, 
		year_num LIKE invoicehead.year_num, 
		period_num LIKE invoicehead.period_num, 
		trans_amt LIKE invoicehead.total_amt, 
		base_trans_amt LIKE invoicehead.total_amt 
	END RECORD
	DEFINE l_rec_customer RECORD LIKE customer.*
	DEFINE l_rec_invoicehead RECORD LIKE invoicehead.*
	DEFINE l_rec_credithead RECORD LIKE credithead.*
	DEFINE l_rec_cashreceipt RECORD LIKE cashreceipt.*
	DEFINE l_rec_invoicepay RECORD LIKE invoicepay.*
	DEFINE l_query_text STRING

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"AAP_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT AAP_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	
	LET modu_age_year = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref1_num 
	LET modu_age_period = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref2_num 
	LET modu_age_date = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref1_date 
	LET modu_report_level = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref1_code 
	LET modu_tot_over1 = 0 
	LET modu_tot_over30 = 0 
	LET modu_tot_over60 = 0 
	LET modu_tot_over90 = 0 
	LET modu_tot_curr = 0 
	LET modu_tot_fwd = 0 
	LET modu_tot_bal = 0 
	LET modu_tot_cust = 0 
	##
	## NOTE NOTE NOTE NOTE
	## FOR this REPORT TO work correctly, the aging dates should always be
	## SET as per type 2 aging (ie. fiscal period), regardless of the
	## usual system tailoring option.  FOR this reason, we do NOT use the
	## FUNCTION set_aging TO SET up the dates.
	##
	CALL set_period_aging(glob_rec_kandoouser.cmpy_code,modu_age_date) 
	LET l_query_text = "SELECT * FROM customer ", 
	" WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	" AND ", glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AAP_rpt_list")].sel_text clipped, 
	" ORDER BY type_code, cust_code" 
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
		AND (inv_date <= modu_age_date OR 
		(entry_date <= modu_age_date AND inv_date > modu_age_date)) 
		AND ((total_amt <> paid_amt) OR 
		(paid_date IS NOT NULL AND paid_date >= modu_age_date)) 
		FOREACH c_invoicehead INTO l_rec_invoicehead.* 
			LET l_rec_document.cust_code = l_rec_invoicehead.cust_code 
			LET l_rec_document.type_code = l_rec_customer.type_code 
			LET l_rec_document.trans_date = l_rec_invoicehead.inv_date 
			LET l_rec_document.ref_num = l_rec_invoicehead.inv_num 
			LET l_rec_document.trans_type = TRAN_TYPE_INVOICE_IN 
			LET l_rec_document.trans_age = get_age_group(TRAN_TYPE_INVOICE_IN,l_rec_invoicehead.inv_date) 
			LET l_rec_document.conv_qty = l_rec_invoicehead.conv_qty 
			LET l_rec_document.year_num = l_rec_invoicehead.year_num 
			LET l_rec_document.period_num = l_rec_invoicehead.period_num 
			LET l_rec_document.trans_amt = l_rec_invoicehead.total_amt -	l_rec_invoicehead.paid_amt 
			LET l_rec_document.base_trans_amt = l_rec_document.trans_amt / l_rec_document.conv_qty 
			INSERT INTO f_document VALUES (l_rec_document.*) 
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
		FOREACH c_credithead INTO l_rec_credithead.* 
			LET l_rec_document.cust_code = l_rec_credithead.cust_code 
			LET l_rec_document.type_code = l_rec_customer.type_code 
			LET l_rec_document.ref_num = l_rec_credithead.cred_num 
			LET l_rec_document.trans_date = l_rec_credithead.cred_date 
			LET l_rec_document.trans_type = TRAN_TYPE_CREDIT_CR 
			LET l_rec_document.trans_age = get_age_group(TRAN_TYPE_CREDIT_CR,l_rec_credithead.cred_date) 
			LET l_rec_document.conv_qty = l_rec_credithead.conv_qty 
			LET l_rec_document.year_num = l_rec_credithead.year_num 
			LET l_rec_document.period_num = l_rec_credithead.period_num 
			LET l_rec_document.trans_amt = l_rec_credithead.appl_amt - l_rec_credithead.total_amt 
			LET l_rec_document.base_trans_amt = l_rec_document.trans_amt / 
			l_rec_document.conv_qty 
			INSERT INTO f_document VALUES (l_rec_document.*) 
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
		FOREACH c_cashreceipt INTO l_rec_cashreceipt.* 
			LET l_rec_document.cust_code = l_rec_cashreceipt.cust_code 
			LET l_rec_document.type_code = l_rec_customer.type_code 
			LET l_rec_document.trans_date = l_rec_cashreceipt.cash_date 
			LET l_rec_document.ref_num = l_rec_cashreceipt.cash_num 
			LET l_rec_document.trans_type = TRAN_TYPE_RECEIPT_CA 
			LET l_rec_document.trans_age = get_age_group(TRAN_TYPE_RECEIPT_CA,l_rec_cashreceipt.cash_date) 
			LET l_rec_document.conv_qty = l_rec_cashreceipt.conv_qty 
			LET l_rec_document.year_num = l_rec_cashreceipt.year_num 
			LET l_rec_document.period_num = l_rec_cashreceipt.period_num 
			LET l_rec_document.trans_amt = l_rec_cashreceipt.applied_amt - l_rec_cashreceipt.cash_amt 
			LET l_rec_document.base_trans_amt = l_rec_document.trans_amt /l_rec_document.conv_qty 
			INSERT INTO f_document VALUES (l_rec_document.*) 
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
		FOREACH c_invoicepay INTO l_rec_invoicepay.* 
			###############################################################
			# The invoice should already be in the temporary table IF it
			# was entered before the cutoff date AND paid later
			###############################################################
			SELECT * INTO l_rec_document.* 
			FROM f_document 
			WHERE ref_num = l_rec_invoicepay.inv_num 
			AND trans_type = TRAN_TYPE_INVOICE_IN 
			IF status = 0 THEN 
				LET l_rec_document.trans_amt = l_rec_document.trans_amt + l_rec_invoicepay.pay_amt + l_rec_invoicepay.disc_amt 
				LET l_rec_document.base_trans_amt = l_rec_document.trans_amt / l_rec_document.conv_qty 
				UPDATE f_document SET trans_amt = l_rec_document.trans_amt,	base_trans_amt = l_rec_document.base_trans_amt 
				WHERE ref_num = l_rec_invoicepay.inv_num 
				AND trans_type = TRAN_TYPE_INVOICE_IN 
			ELSE 
				###############################################################
				# But paid date IS NOT always applied date so check Invoice if
				# it IS NOT in temporary table AND add it IF it was entered
				# before the cutoff date
				###############################################################
				SELECT * INTO l_rec_invoicehead.* 
				FROM invoicehead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND inv_num = l_rec_invoicepay.inv_num 
				AND cust_code = l_rec_customer.cust_code 
				AND (inv_date <= modu_age_date OR (entry_date <= modu_age_date AND inv_date > modu_age_date)) 
				IF status = 0 THEN 
					LET l_rec_document.cust_code = l_rec_invoicehead.cust_code 
					LET l_rec_document.type_code = l_rec_customer.type_code 
					LET l_rec_document.trans_date = l_rec_invoicehead.inv_date 
					LET l_rec_document.ref_num = l_rec_invoicehead.inv_num 
					LET l_rec_document.trans_type = TRAN_TYPE_INVOICE_IN 
					LET l_rec_document.trans_age = get_age_group(TRAN_TYPE_INVOICE_IN,l_rec_invoicehead.inv_date) 
					LET l_rec_document.conv_qty = l_rec_invoicehead.conv_qty 
					LET l_rec_document.year_num = l_rec_invoicehead.year_num 
					LET l_rec_document.period_num = l_rec_invoicehead.period_num 
					LET l_rec_document.trans_amt = l_rec_invoicehead.total_amt - l_rec_invoicehead.paid_amt + l_rec_invoicepay.pay_amt + l_rec_invoicepay.disc_amt 
					LET l_rec_document.base_trans_amt = l_rec_document.trans_amt / l_rec_document.conv_qty 
					INSERT INTO f_document VALUES (l_rec_document.*) 
				END IF 
			END IF 
			###############################################################
			# Need TO check temp table FOR cash receipt first. IF it IS
			# there THEN UPDATE it
			###############################################################
			IF l_rec_invoicepay.pay_type_ind = TRAN_TYPE_RECEIPT_CA THEN 
				SELECT * INTO l_rec_document.* 
				FROM f_document 
				WHERE ref_num = l_rec_invoicepay.ref_num 
				AND trans_type = TRAN_TYPE_RECEIPT_CA 
				IF status = 0 THEN 
					LET l_rec_document.trans_amt = l_rec_document.trans_amt - l_rec_invoicepay.pay_amt 
					LET l_rec_document.base_trans_amt = l_rec_document.trans_amt / l_rec_document.conv_qty 
					UPDATE f_document SET trans_amt = l_rec_document.trans_amt,	base_trans_amt = l_rec_document.base_trans_amt 
					WHERE ref_num = l_rec_invoicepay.ref_num 
					AND trans_type = TRAN_TYPE_RECEIPT_CA 
				ELSE 
					############################################################
					# IF cashreceipt IS NOT in temp table THEN SELECT it AND
					# INSERT it IF it was entered before cutoff date
					############################################################
					SELECT * INTO l_rec_cashreceipt.* 
					FROM cashreceipt 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cash_num = l_rec_invoicepay.ref_num 
					AND cash_date <= modu_age_date 
					IF status = 0 THEN 
						LET l_rec_document.cust_code = l_rec_cashreceipt.cust_code 
						LET l_rec_document.type_code = l_rec_customer.type_code 
						LET l_rec_document.trans_date = l_rec_cashreceipt.cash_date 
						LET l_rec_document.ref_num = l_rec_cashreceipt.cash_num 
						LET l_rec_document.trans_type = TRAN_TYPE_RECEIPT_CA 
						LET l_rec_document.trans_age = get_age_group(TRAN_TYPE_RECEIPT_CA, l_rec_cashreceipt.cash_date) 
						LET l_rec_document.conv_qty = l_rec_cashreceipt.conv_qty 
						LET l_rec_document.year_num = l_rec_cashreceipt.year_num 
						LET l_rec_document.period_num = l_rec_cashreceipt.period_num 
						LET l_rec_document.trans_amt = (l_rec_cashreceipt.applied_amt -	l_rec_invoicepay.pay_amt ) - l_rec_cashreceipt.cash_amt 
						LET l_rec_document.base_trans_amt =	l_rec_document.trans_amt / l_rec_document.conv_qty 
						INSERT INTO f_document VALUES (l_rec_document.*) 
					END IF 
				END IF 
			ELSE 
			
				# Must be a credit
				SELECT * INTO l_rec_document.* 
				FROM f_document 
				WHERE ref_num = l_rec_invoicepay.ref_num 
				AND trans_type = TRAN_TYPE_CREDIT_CR 
				IF status = 0 THEN 
					LET l_rec_document.trans_amt = l_rec_document.trans_amt - l_rec_invoicepay.pay_amt 
					LET l_rec_document.base_trans_amt =	l_rec_document.trans_amt / l_rec_document.conv_qty 
					UPDATE f_document SET trans_amt = l_rec_document.trans_amt,	base_trans_amt = l_rec_document.base_trans_amt 
					WHERE ref_num = l_rec_invoicepay.ref_num 
					AND trans_type = TRAN_TYPE_CREDIT_CR 
				ELSE 
					############################################################
					# IF credit IS NOT in temp table THEN SELECT it AND INSERT
					# it IF it was entered before cutoff date
					############################################################
					SELECT * INTO l_rec_credithead.* 
					FROM credithead 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cred_num = l_rec_invoicepay.ref_num 
					AND cred_date <= modu_age_date 
					IF status = 0 THEN 
						LET l_rec_document.cust_code = l_rec_credithead.cust_code 
						LET l_rec_document.type_code = l_rec_customer.type_code 
						LET l_rec_document.trans_date = l_rec_credithead.cred_date 
						LET l_rec_document.ref_num = l_rec_credithead.cred_num 
						LET l_rec_document.trans_type = TRAN_TYPE_CREDIT_CR 
						LET l_rec_document.trans_age = get_age_group(TRAN_TYPE_CREDIT_CR, l_rec_credithead.cred_date) 
						LET l_rec_document.conv_qty = l_rec_credithead.conv_qty 
						LET l_rec_document.year_num = l_rec_credithead.year_num 
						LET l_rec_document.period_num = l_rec_credithead.period_num 
						LET l_rec_document.trans_amt = (l_rec_credithead.appl_amt -	l_rec_invoicepay.pay_amt ) - l_rec_credithead.total_amt 
						LET l_rec_document.base_trans_amt = l_rec_document.trans_amt / l_rec_document.conv_qty 
						INSERT INTO f_document VALUES (l_rec_document.*) 
					END IF 
				END IF 
			END IF 
		END FOREACH 

		DECLARE c_f_document CURSOR FOR 
		SELECT * FROM f_document 
		ORDER BY trans_date, ref_num 

		FOREACH c_f_document INTO l_rec_document.*
			#---------------------------------------------------------
			OUTPUT TO REPORT AAP_rpt_list(l_rpt_idx,l_rec_document.*) 
			IF NOT rpt_int_flag_handler2("Type:",l_rec_customer.type_code, l_rec_customer.cust_code,l_rpt_idx) THEN
				EXIT FOREACH 
			END IF 
			#---------------------------------------------------------
				 
		END FOREACH 

		DELETE FROM f_document WHERE 1=1 
	END FOREACH 
	 
	#------------------------------------------------------------
	FINISH REPORT AAP_rpt_list
	CALL rpt_finish("AAP_rpt_list")
	#------------------------------------------------------------

	IF int_flag THEN
		RETURN FALSE
	ELSE
		RETURN TRUE
	END IF 	
END FUNCTION 
#####################################################################
# END FUNCTION AAP_rpt_process()
#####################################################################


#####################################################################
# FUNCTION set_period_aging(p_rec_cmpy_code,p_age_date)
#
#
#####################################################################
FUNCTION set_period_aging(p_rec_cmpy_code,p_age_date) 
	DEFINE p_rec_cmpy_code LIKE company.cmpy_code
	DEFINE p_age_date DATE
	DEFINE l_end_date DATE
	DEFINE l_prev_date DATE	
	DEFINE l_aging_year LIKE period.year_num
	DEFINE l_aging_period LIKE period.period_num
	DEFINE l_arr_period_date array[5] OF DATE
	DEFINE l_idx SMALLINT 

	LET modu_aging_date = p_age_date 
	LET modu_credit_aging = get_kandoooption_feature_state("AR",TRAN_TYPE_RECEIPT_CA) 
	SELECT year_num, period_num 
	INTO l_aging_year, l_aging_period 
	FROM period 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND start_date <= modu_aging_date 
	AND end_date >= modu_aging_date 
	IF status = NOTFOUND THEN 
		FOR l_idx = 1 TO 5 
			LET l_arr_period_date[l_idx] = modu_aging_date 
		END FOR 
	ELSE 
		LET l_prev_date = modu_aging_date 
		DECLARE c_period CURSOR FOR 
		SELECT end_date FROM period 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND ((year_num = l_aging_year 
		AND period_num <= l_aging_period) OR year_num < l_aging_year) 
		ORDER BY end_date desc 
		OPEN c_period 

		FOR l_idx = 1 TO 5 
			FETCH c_period INTO l_end_date 
			IF status = NOTFOUND THEN 
				LET l_arr_period_date[l_idx] = l_prev_date 
			ELSE 
				LET l_prev_date = l_end_date 
				LET l_arr_period_date[l_idx] = l_end_date 
			END IF 
		END FOR 

		CLOSE c_period 
	END IF 

	LET modu_future_date = l_arr_period_date[1] 
	LET modu_over1_date = l_arr_period_date[2] 
	LET modu_over30_date = l_arr_period_date[3] 
	LET modu_over60_date = l_arr_period_date[4] 
	LET modu_over90_date = l_arr_period_date[5] 
END FUNCTION 
#####################################################################
# END FUNCTION set_period_aging(p_rec_cmpy_code,p_age_date)
#####################################################################


#####################################################################
# FUNCTION get_age_group(p_trantype_ind, p_due_date)
#
#
#####################################################################
FUNCTION get_age_group(p_trantype_ind, p_due_date) 
	DEFINE p_trantype_ind CHAR(2)
	DEFINE p_due_date DATE 

	IF p_trantype_ind = TRAN_TYPE_CREDIT_CR 
	AND modu_credit_aging THEN 
		RETURN 0 
	END IF 

	CASE 
		WHEN p_due_date <= modu_over90_date 
			RETURN 91 
		WHEN p_due_date <= modu_over60_date 
			RETURN 61 
		WHEN p_due_date <= modu_over30_date 
			RETURN 31 
		WHEN p_due_date <= modu_over1_date 
			RETURN 1 
		WHEN p_due_date <= modu_future_date 
			RETURN 0 
		OTHERWISE 
			RETURN -31 
	END CASE 
END FUNCTION 
#####################################################################
# END FUNCTION get_age_group(p_trantype_ind, p_due_date)
#####################################################################


#####################################################################
# REPORT AAP_rpt_list(p_rpt_idx,p_rec_document)
#
#
#####################################################################
REPORT AAP_rpt_list(p_rpt_idx,p_rec_document) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_document RECORD 
		cust_code LIKE customer.cust_code, 
		type_code LIKE customer.type_code, 
		trans_date LIKE invoicehead.inv_date, 
		ref_num LIKE invoicehead.inv_num, 
		trans_type LIKE araudit.tran_type_ind, 
		tran_age INTEGER, 
		conv_qty LIKE invoicehead.conv_qty, 
		year_num LIKE invoicehead.year_num, 
		period_num LIKE invoicehead.period_num, 
		trans_amt LIKE invoicehead.total_amt, 
		base_trans_amt LIKE invoicehead.total_amt 
	END RECORD
	DEFINE l_type_text CHAR(8)
	DEFINE l_rec_customer RECORD LIKE customer.*
	DEFINE l_rec_customertype RECORD LIKE customertype.*
	DEFINE l_bal_amt DECIMAL(16,2)
	DEFINE l_over60_90 DECIMAL(16,2)
	DEFINE l_over90 DECIMAL(16,2)
	DEFINE l_over30_60 DECIMAL(16,2)
	
	DEFINE l_over1_30 DECIMAL(16,2)
	DEFINE l_curr DECIMAL(16,2)
	DEFINE l_fwd_amt DECIMAL(16,2)
	DEFINE l_bal DECIMAL(16,2)
	 
	DEFINE l_typ_bal_amt DECIMAL(16,2)  
	DEFINE l_typ_over60_90 DECIMAL(16,2)  
	DEFINE l_typ_over90 DECIMAL(16,2)  
	DEFINE l_typ_over30_60 DECIMAL(16,2)  
	
	DEFINE l_typ_over1_30 DECIMAL(16,2) 
	DEFINE l_typ_curr DECIMAL(16,2) 
	DEFINE l_typ_fwd DECIMAL(16,2) 
	DEFINE l_typ_bal DECIMAL(16,2) 


	OUTPUT 
 
	ORDER external BY p_rec_document.type_code,p_rec_document.cust_code 
	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			
			PRINT COLUMN 40, "Aging Year/Period : ", 
			COLUMN 60, modu_age_year USING "&&&&","/",modu_age_period USING "&&", 
			COLUMN 70, "Aging Date : ", 
			COLUMN 83, modu_age_date USING "dd/mm/yyyy" 
			
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]
			
			PRINT COLUMN 01, "Customer", 
			COLUMN 10, "Name", 
			COLUMN 15, "l_curr", 
			COLUMN 26, "Balance", 
			COLUMN 42, "Forward", 
			COLUMN 58, "Current", 
			COLUMN 75, "Over 1", 
			COLUMN 90, "Over 30", 
			COLUMN 106,"Over 60", 
			COLUMN 122,"Over 90" 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		BEFORE GROUP OF p_rec_document.type_code 
			LET l_typ_bal_amt = 0 
			LET l_typ_fwd = 0 
			LET l_typ_curr = 0 
			LET l_typ_over90 = 0 
			LET l_typ_over60_90 = 0 
			LET l_typ_over30_60 = 0 
			LET l_typ_over1_30 = 0 
			SELECT * INTO l_rec_customertype.* 
			FROM customertype 
			WHERE type_code = p_rec_document.type_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF modu_report_level != "1" THEN 
				NEED 3 LINES 
				SKIP 1 line 
				PRINT COLUMN 01, "Customer Type: ", 
				l_rec_customertype.type_code, " ", 
				l_rec_customertype.type_text 
				SKIP 1 line 
			END IF 

		BEFORE GROUP OF p_rec_document.cust_code 
			CALL db_customer_get_rec(UI_OFF,p_rec_document.cust_code) RETURNING l_rec_customer.*		
--			SELECT * INTO l_rec_customer.* 
--			FROM customer 
--			WHERE cust_code = p_rec_document.cust_code 
--			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF modu_report_level = '3' THEN 
				PRINT COLUMN 1, l_rec_customer.cust_code, 
				COLUMN 10, l_rec_customer.name_text 
				SKIP 1 line 
			END IF 
			LET l_bal_amt = 0 
			LET l_fwd_amt = 0 
			LET l_curr = 0 
			LET l_over90 = 0 
			LET l_over60_90 = 0 
			LET l_over30_60 = 0 
			LET l_over1_30 = 0 

		ON EVERY ROW 
			CASE 
				WHEN (p_rec_document.tran_age > 90) 
					LET l_over90 = l_over90 + p_rec_document.trans_amt 
					LET l_typ_over90 = l_typ_over90 + p_rec_document.base_trans_amt 
				WHEN (p_rec_document.tran_age > 60 AND p_rec_document.tran_age <= 90) 
					LET l_over60_90 = l_over60_90 + p_rec_document.trans_amt 
					LET l_typ_over60_90 = l_typ_over60_90 + p_rec_document.base_trans_amt 
				WHEN (p_rec_document.tran_age > 30 AND p_rec_document.tran_age <= 60) 
					LET l_over30_60 = l_over30_60 + p_rec_document.trans_amt 
					LET l_typ_over30_60 = l_typ_over30_60 + p_rec_document.base_trans_amt 
				WHEN (p_rec_document.tran_age > 0 AND p_rec_document.tran_age <= 30) 
					LET l_over1_30 = l_over1_30 + p_rec_document.trans_amt 
					LET l_typ_over1_30 = l_typ_over1_30 + p_rec_document.base_trans_amt 
				WHEN (p_rec_document.tran_age = 0) 
					LET l_curr = l_curr + p_rec_document.trans_amt 
					LET l_typ_curr = l_typ_curr + p_rec_document.base_trans_amt 
				OTHERWISE 
					LET l_fwd_amt = l_fwd_amt + p_rec_document.trans_amt 
					LET l_typ_fwd = l_typ_fwd + p_rec_document.base_trans_amt 
			END CASE 
			LET l_bal_amt = l_bal_amt + p_rec_document.trans_amt 
			LET l_typ_bal_amt = l_typ_bal_amt + p_rec_document.base_trans_amt 
			IF modu_report_level = '3' THEN 
				PRINT COLUMN 01, p_rec_document.trans_type, 
				COLUMN 03, p_rec_document.ref_num USING "########&", 
				COLUMN 13, p_rec_document.trans_date USING "dd/mm/yy", 
				COLUMN 35, p_rec_document.trans_amt USING "---,---,--&.&&" 
			END IF 

		AFTER GROUP OF p_rec_document.cust_code 
			IF modu_report_level != "1" THEN 
				NEED 4 LINES 
				LET modu_tot_cust = modu_tot_cust + 1 
				IF modu_report_level = "2" THEN 
					PRINT COLUMN 1, l_rec_customer.cust_code, 
					COLUMN 10, l_rec_customer.name_text 
				ELSE 
					SKIP 1 line 
				END IF 
				PRINT COLUMN 14, l_rec_customer.currency_code, 
				COLUMN 18, l_bal_amt USING "----,---,--&.&&", 
				COLUMN 34, l_fwd_amt USING "----,---,--&.&&", 
				COLUMN 50, l_curr USING "----,---,--&.&&", 
				COLUMN 66, l_over1_30 USING "----,---,--&.&&", 
				COLUMN 82, l_over30_60 USING "----,---,--&.&&", 
				COLUMN 98, l_over60_90 USING "----,---,--&.&&", 
				COLUMN 114, l_over90 USING "----,---,--&.&&" 
				SKIP 1 line 
			END IF 

		AFTER GROUP OF p_rec_document.type_code 
			IF modu_report_level != "1" THEN 
				PRINT COLUMN 15, "----------------------------------------", 
				"----------------------------------------", 
				"------------------------------------" 
				PRINT COLUMN 01,"Total "; 
			END IF 
			PRINT COLUMN 7, p_rec_document.type_code, 
			COLUMN 11, l_rec_customertype.type_text 
			PRINT COLUMN 14, modu_base_currency, 
			COLUMN 18, l_typ_bal_amt USING "----,---,--&.&&", 
			COLUMN 34, l_typ_fwd USING "----,---,--&.&&", 
			COLUMN 50, l_typ_curr USING "----,---,--&.&&", 
			COLUMN 66, l_typ_over1_30 USING "----,---,--&.&&", 
			COLUMN 82, l_typ_over30_60 USING "----,---,--&.&&", 
			COLUMN 98, l_typ_over60_90 USING "----,---,--&.&&", 
			COLUMN 114, l_typ_over90 USING "----,---,--&.&&" 
			SKIP 2 LINES 
			LET modu_tot_bal = modu_tot_bal + l_typ_bal_amt 
			LET modu_tot_fwd = modu_tot_fwd + l_typ_fwd 
			LET modu_tot_curr = modu_tot_curr + l_typ_curr 
			LET modu_tot_over1 = modu_tot_over1 + l_typ_over1_30 
			LET modu_tot_over30 = modu_tot_over30 + l_typ_over30_60 
			LET modu_tot_over60 = modu_tot_over60 + l_typ_over60_90 
			LET modu_tot_over90 = modu_tot_over90 + l_typ_over90 

		ON LAST ROW 
			NEED 7 LINES 
			PRINT COLUMN 15, "----------------------------------------", 
			"----------------------------------------", 
			"------------------------------------" 
			PRINT COLUMN 01,"Totals:", 
			COLUMN 15, modu_tot_bal USING "---,---,---,--&.&&", 
			COLUMN 50, modu_tot_curr USING "----,---,--&.&&", 
			COLUMN 82, modu_tot_over30 USING "----,---,--&.&&", 
			COLUMN 114,modu_tot_over90 USING "----,---,--&.&&" 
			PRINT COLUMN 01,"Total Customers: ", modu_tot_cust USING "#######", 
			COLUMN 31, modu_tot_fwd USING "---,---,---,--&.&&", 
			COLUMN 66, modu_tot_over1 USING "----,---,--&.&&", 
			COLUMN 98, modu_tot_over60 USING "----,---,--&.&&" 
			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = pageno
			
END REPORT
#####################################################################
# END REPORT AAP_rpt_list(p_rpt_idx,p_rec_document)
#####################################################################