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
# PRT.4gl - Vendor Aging Report that allows:
#           1) Entry of aging year AND period
#           2) Report TO be printed TO Type, Vendor OR Detail level
#           3) Unpicks transactions closed AFTER cutoff year AND period

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_GLOBALS.4gl"
GLOBALS "../common/glob_GLOBALS_report.4gl" 
GLOBALS 
	DEFINE glob_where_text CHAR(2048)
	DEFINE glob_tot_over1 DECIMAL(16,2)
	DEFINE glob_tot_over30 DECIMAL(16,2)
	DEFINE glob_tot_over60 DECIMAL(16,2)
	DEFINE glob_tot_over90 DECIMAL(16,2)
	DEFINE glob_tot_curr DECIMAL(16,2)
	DEFINE glob_tot_bal DECIMAL(16,2)
	DEFINE glob_tot_post_amt DECIMAL(16,2) 
	DEFINE glob_tot_vend INTEGER 
	DEFINE glob_pr_base_currency LIKE currency.currency_code
	DEFINE glob_age_year LIKE period.year_num
	DEFINE glob_age_period LIKE period.period_num
	DEFINE glob_age_date DATE 
	DEFINE glob_report_level CHAR(1) 
END GLOBALS 

############################################################
# MAIN
############################################################
MAIN 
	DEFER quit 
	DEFER interrupt
	
	#Initial UI Init
	CALL setModuleId("PRT") 
	CALL ui_init(0) 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_p_ap() #init p/ap module 

	SELECT * INTO glob_rec_company.* FROM company 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	CREATE temp TABLE doctab (d_vend CHAR(8), 
	d_type_code CHAR(3), 
	d_date DATE, 
	d_ref INTEGER, 
	d_ref_text CHAR(20), 
	d_desc CHAR(30), 
	d_conv_qty FLOAT, 
	d_type CHAR(2), 
	d_age INTEGER, 
	d_bal DECIMAL(16,2), 
	d_base_bal DECIMAL(16,2)) with no LOG 
	CREATE INDEX d_tmp_key ON doctab(d_ref) 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 	
			OPEN WINDOW P507 with FORM "P507" 
			CALL windecoration_p("P507") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
		
			MENU " Vendor Period Aging" 
		
				BEFORE MENU 
					CALL publish_toolbar("kandoo","PRT","menu-vendor_period_aging-1") 
					CALL rpt_rmsreps_reset(NULL)
					CALL PRT_rpt_process(PRT_rpt_query())
		
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				COMMAND "Report" " SELECT criteria AND PRINT REPORT" 
					CALL rpt_rmsreps_reset(NULL)
					CALL PRT_rpt_process(PRT_rpt_query())
		
				ON ACTION "Print Manager"			#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		 
				COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus" 
					EXIT MENU 
		
			END MENU 
			CLOSE WINDOW P507

		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL PRT_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW P507 with FORM "P507" 
			CALL windecoration_p("P507") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(PRT_rpt_query()) #save where clause in env 
			CLOSE WINDOW P507 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL PRT_rpt_process(get_url_sel_text())
	END CASE 
		 
END MAIN 


FUNCTION PRT_rpt_query()
	DEFINE l_where_text STRING 
	DEFINE l_default_year LIKE period.year_num
	DEFINE l_default_period LIKE period.period_num 
	DEFINE l_msgresp LIKE language.yes_flag 

	SELECT base_currency_code 
	INTO glob_pr_base_currency 
	FROM glparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND key_code = '1' 
	IF status = NOTFOUND THEN 
		ERROR kandoomsg2("U",3511,"")		#3511 GL Parameters NOT SET up
		sleep 2
		RETURN false 
	END IF 
	
	CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,today) 
	RETURNING l_default_year,	l_default_period
	 
	LET glob_age_year = l_default_year 
	LET glob_age_period = l_default_period 
	LET glob_report_level = "1" 

	INPUT glob_age_year,glob_age_period,glob_report_level WITHOUT DEFAULTS 
	FROM age_year,age_period,report_level 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","PRT","inp-age-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER FIELD age_period 
			SELECT end_date 
			INTO glob_age_date 
			FROM period 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND year_num = glob_age_year 
			AND period_num = glob_age_period 
			IF status = NOTFOUND THEN 
				ERROR kandoomsg2("G",9012,"") 	#9012 Fiscal year AND period invalid
				NEXT FIELD age_year 
			END IF 
			DISPLAY glob_age_date TO age_date  

		AFTER FIELD report_level 
			IF glob_report_level IS NULL OR	(glob_report_level NOT matches "[123]") THEN 
				LET glob_report_level = 1 
				DISPLAY glob_report_level TO report_level 
				NEXT FIELD report_level 
			END IF 
			
		AFTER INPUT 
			SELECT end_date 
			INTO glob_age_date 
			FROM period 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND year_num = glob_age_year 
			AND period_num = glob_age_period 
			IF status = NOTFOUND THEN 
				ERROR kandoomsg2("G",9012,"")				#9012 Fiscal year AND period invalid
				NEXT FIELD age_year 
			END IF 
			
			IF glob_report_level IS NULL OR 
			NOT (glob_report_level matches "[123]") THEN 
				LET glob_report_level = 1 
				DISPLAY glob_report_level TO report_level 
				NEXT FIELD report_level 
			END IF 

	END INPUT
	 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 
	
	MESSAGE kandoomsg2("U",1001,"")
	CONSTRUCT BY NAME l_where_text ON vend_code, 
	name_text, 
	addr1_text, 
	addr2_text, 
	addr3_text, 
	city_text, 
	state_code, 
	post_code, 
	country_code, 
	type_code, 
	currency_code, 
	term_code, 
	tax_code, 
	drop_flag, 
	tax_text, 
	our_acct_code, 
	contact_text, 
	tele_text, 
	extension_text, 
	fax_text 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","PRT","construct-vendor-1") 

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
		LET glob_rec_rpt_selector.ref1_date = glob_age_date 
		LET glob_rec_rpt_selector.ref1_num = glob_age_year 
		LET glob_rec_rpt_selector.ref2_num = glob_age_period 
		LET glob_rec_rpt_selector.ref3_num = glob_report_level 
		RETURN l_where_text 
	END IF 


END FUNCTION 


FUNCTION PRT_rpt_process(p_where_text)
	DEFINE p_where_text STRING 
	DEFINE l_rpt_idx SMALLINT  #report array index
	DEFINE l_rec_vendor RECORD LIKE vendor.*
	DEFINE l_rec_voucher RECORD LIKE voucher.*
	DEFINE l_rec_debithead RECORD LIKE debithead.*
	DEFINE l_rec_cheque RECORD LIKE cheque.*
	DEFINE l_rec_cancelcheq RECORD LIKE cancelcheq.*
	DEFINE l_rec_voucherpays RECORD LIKE voucherpays.*
	DEFINE l_rec_doc RECORD 
		d_vend LIKE vendor.vend_code, 
		d_type_code LIKE vendor.type_code, 
		d_date LIKE voucher.vouch_date, 
		d_ref LIKE voucher.vouch_code, 
		d_ref_text LIKE voucher.inv_text, 
		d_desc LIKE voucher.com1_text, 
		d_conv_qty LIKE voucher.conv_qty, 
		d_type CHAR(2), 
		d_age INTEGER, 
		d_bal DECIMAL(16,2), 
		d_base_bal DECIMAL(16,2) 
	END RECORD
	DEFINE l_query_text CHAR(2200)
	DEFINE l_order_text CHAR(200)
	DEFINE l_rpt_output CHAR(60) 
	DEFINE l_payment_year LIKE period.year_num 
	DEFINE l_payment_period LIKE period.period_num 
	DEFINE l_voucher_in SMALLINT 
	DEFINE l_payment_in SMALLINT
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_tmp_str STRING
	
	LET glob_tot_over1 = 0 
	LET glob_tot_over30 = 0 
	LET glob_tot_over60 = 0 
	LET glob_tot_over90 = 0 
	LET glob_tot_curr = 0 
	LET glob_tot_bal = 0 
	LET glob_tot_post_amt = 0 
	LET glob_tot_vend = 0

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"PRT_rpt_list_vend_age",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT PRT_rpt_list_vend_age TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------
	#Case specific rems_reps works...
	LET glob_age_date = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref1_date
	LET glob_age_year = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref1_num
	LET glob_age_period = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref2_num
	LET glob_report_level = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref3_num

	LET l_tmp_str = glob_age_year, "/", glob_age_period USING "<<<<" 
	CALL rpt_set_header_footer_line_2_append(l_rpt_idx,NULL, l_tmp_str)
	#------------------------------------------------------------


	IF glob_rec_apparms.report_ord_flag = "C" THEN 
		LET l_order_text = " vend_code " 
	ELSE 
		LET l_order_text = " name_text, vend_code " 
	END IF 
	LET l_query_text = "SELECT * FROM vendor ", 
	" WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	" AND ", glob_where_text clipped, 
	" ORDER BY type_code,",l_order_text clipped 

	PREPARE s_vendor FROM l_query_text 
	DECLARE c_vendor CURSOR with HOLD FOR s_vendor 
	FOREACH c_vendor INTO glob_rec_vendor.* 
		IF glob_rec_apparms.report_ord_flag = "C" THEN 
			DISPLAY glob_rec_vendor.type_code," - ",glob_rec_vendor.vend_code at 1,17 

		ELSE 
			DISPLAY glob_rec_vendor.type_code," - ",glob_rec_vendor.name_text at 1,17 

		END IF 
		################################
		#   VOUCHERS
		################################
		DECLARE c_voucher CURSOR FOR 
		SELECT * FROM voucher 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND vend_code = l_rec_vendor.vend_code 
		AND (year_num < glob_age_year OR 
		(year_num = glob_age_year AND period_num <= glob_age_period)) 
		AND total_amt <> paid_amt 
		FOREACH c_voucher INTO l_rec_voucher.* 
			LET l_rec_doc.d_vend = l_rec_voucher.vend_code 
			LET l_rec_doc.d_type_code = glob_rec_vendor.type_code 
			LET l_rec_doc.d_date = l_rec_voucher.vouch_date 
			LET l_rec_doc.d_ref = l_rec_voucher.vouch_code 
			LET l_rec_doc.d_ref_text = l_rec_voucher.inv_text 
			LET l_rec_doc.d_desc = l_rec_voucher.com1_text 
			LET l_rec_doc.d_type = "VO" 
			LET l_rec_doc.d_age = glob_age_date - l_rec_voucher.due_date 
			IF l_rec_voucher.conv_qty = 0 OR l_rec_voucher.conv_qty IS NULL THEN 
				LET l_rec_voucher.conv_qty = 1 
			END IF 
			LET l_rec_doc.d_conv_qty = l_rec_voucher.conv_qty 
			LET l_rec_doc.d_bal = l_rec_voucher.total_amt - l_rec_voucher.paid_amt 
			LET l_rec_doc.d_base_bal = l_rec_doc.d_bal / l_rec_voucher.conv_qty 
			INSERT INTO doctab VALUES (l_rec_doc.*) 
		END FOREACH 
		################################
		#   DEBITS
		################################
		DECLARE c_debithead CURSOR FOR 
		SELECT * FROM debithead 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND vend_code = l_rec_vendor.vend_code 
		AND (year_num < glob_age_year OR 
		(year_num = glob_age_year AND period_num <= glob_age_period)) 
		AND total_amt <> apply_amt 
		FOREACH c_debithead INTO l_rec_debithead.* 
			LET l_rec_doc.d_vend = l_rec_debithead.vend_code 
			LET l_rec_doc.d_type_code = glob_rec_vendor.type_code 
			LET l_rec_doc.d_ref = l_rec_debithead.debit_num 
			LET l_rec_doc.d_ref_text = l_rec_debithead.debit_text 
			LET l_rec_doc.d_date = l_rec_debithead.debit_date 
			LET l_rec_doc.d_desc = l_rec_debithead.com1_text 
			LET l_rec_doc.d_type = "DB" 
			LET l_rec_doc.d_age = glob_age_date - l_rec_debithead.debit_date 
			IF l_rec_debithead.conv_qty = 0 OR l_rec_debithead.conv_qty IS NULL THEN 
				LET l_rec_debithead.conv_qty = 1 
			END IF 
			LET l_rec_doc.d_conv_qty = l_rec_debithead.conv_qty 
			LET l_rec_doc.d_bal = l_rec_debithead.apply_amt - l_rec_debithead.total_amt 
			LET l_rec_doc.d_base_bal = l_rec_doc.d_bal / l_rec_debithead.conv_qty 
			INSERT INTO doctab VALUES (l_rec_doc.*) 
		END FOREACH 
		################################
		#   PAYMENTS
		################################
		DECLARE c_cheque CURSOR FOR 
		SELECT * FROM cheque 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND vend_code = l_rec_vendor.vend_code 
		AND (year_num < glob_age_year OR 
		(year_num = glob_age_year AND period_num <= glob_age_period)) 
		AND pay_amt <> apply_amt 
		FOREACH c_cheque INTO l_rec_cheque.* 
			LET l_rec_doc.d_vend = l_rec_cheque.vend_code 
			LET l_rec_doc.d_type_code = glob_rec_vendor.type_code 
			LET l_rec_doc.d_date = l_rec_cheque.cheq_date 
			LET l_rec_doc.d_ref = l_rec_cheque.cheq_code 
			LET l_rec_doc.d_ref_text = l_rec_cheque.com3_text 
			LET l_rec_doc.d_desc = l_rec_cheque.com1_text 
			LET l_rec_doc.d_type = "CH" 
			LET l_rec_doc.d_age = glob_age_date - l_rec_cheque.cheq_date 
			IF l_rec_cheque.conv_qty = 0 OR l_rec_cheque.conv_qty IS NULL THEN 
				LET l_rec_cheque.conv_qty = 1 
			END IF 
			LET l_rec_doc.d_conv_qty = l_rec_cheque.conv_qty 
			LET l_rec_doc.d_bal = l_rec_cheque.apply_amt - l_rec_cheque.pay_amt ##ar 197 
			LET l_rec_doc.d_base_bal = l_rec_doc.d_bal / l_rec_cheque.conv_qty 
			INSERT INTO doctab VALUES (l_rec_doc.*) 
		END FOREACH 
		################################
		#   CANCELLED CHEQUES
		################################
		# Now we need TO examine all cheques FOR this period which have been
		# cancelled AFTER posting WHERE the general journal TO correct
		# the AP balance IS FOR a period outside the cut_off period.
		# This IS because the cheque itself has been deleted FROM the cheque
		# table AND will NOT be included in the o/s cheque transactions
		# but the AP control account total has been reduced by the original
		# cheque posting.
		#################################################################
		DECLARE c_cancelcheq CURSOR FOR 
		SELECT * FROM cancelcheq 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND vend_code = l_rec_vendor.vend_code 
		AND orig_posted_flag = 'Y' 
		AND (orig_year_num < glob_age_year OR 
		(orig_year_num = glob_age_year AND orig_period_num <= glob_age_period)) 
		AND (cancel_year_num > glob_age_year OR 
		(cancel_year_num = glob_age_year AND cancel_period_num > glob_age_period)) 
		FOREACH c_cancelcheq INTO l_rec_cancelcheq.* 
			LET l_rec_doc.d_vend = l_rec_cancelcheq.vend_code 
			LET l_rec_doc.d_type_code = glob_rec_vendor.type_code 
			LET l_rec_doc.d_date = l_rec_cancelcheq.cheq_date 
			LET l_rec_doc.d_ref = l_rec_cancelcheq.cheq_code 
			LET l_rec_doc.d_ref_text = "Cancelled ", 
			l_rec_cancelcheq.cancel_year_num USING "####","/", 
			l_rec_cancelcheq.cancel_period_num USING "<<" 
			LET l_rec_doc.d_desc = l_rec_cancelcheq.com1_text 
			LET l_rec_doc.d_type = "CC" 
			LET l_rec_doc.d_age = glob_age_date - l_rec_cancelcheq.cheq_date 
			IF l_rec_cancelcheq.orig_conv_qty = 0 OR 
			l_rec_cancelcheq.orig_conv_qty IS NULL THEN 
				LET l_rec_cancelcheq.orig_conv_qty = 1 
			END IF 
			LET l_rec_doc.d_conv_qty = l_rec_cancelcheq.orig_conv_qty 
			LET l_rec_doc.d_bal = 0 - l_rec_cancelcheq.pay_amt 
			LET l_rec_doc.d_base_bal = l_rec_doc.d_bal / l_rec_cancelcheq.orig_conv_qty 
			INSERT INTO doctab VALUES (l_rec_doc.*) 
		END FOREACH 
		################################
		#   VOUCHERPAYS
		################################
		# Now we need TO examine all payment applications AND adjust balances
		# FOR any payments made by cheques/debits outside the cut-off period OR
		# any applications made TO vouchers outside the cut_off period
		#################################################################
		DECLARE c_voucherpays CURSOR FOR 
		SELECT p.*, 
		v.vouch_date, 
		v.due_date, 
		v.inv_text, 
		v.total_amt, 
		v.paid_amt, 
		v.year_num, 
		v.period_num, 
		v.com1_text 
		FROM voucherpays p, voucher v 
		WHERE p.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND p.vend_code = l_rec_vendor.vend_code 
		AND v.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND v.vouch_code = p.vouch_code 
		FOREACH c_voucherpays INTO l_rec_voucherpays.*, 
			l_rec_voucher.vouch_date, 
			l_rec_voucher.due_date, 
			l_rec_voucher.inv_text, 
			l_rec_voucher.total_amt, 
			l_rec_voucher.paid_amt, 
			l_rec_voucher.year_num, 
			l_rec_voucher.period_num, 
			l_rec_voucher.com1_text 
			#################################################################
			# Determine the payment period
			#################################################################
			IF l_rec_voucherpays.pay_type_code = "CH" THEN 
				SELECT * INTO l_rec_cheque.* 
				FROM cheque 
				WHERE vend_code = l_rec_voucherpays.vend_code 
				AND bank_code = l_rec_voucherpays.bank_code 
				AND cheq_code = l_rec_voucherpays.pay_num 
				AND pay_meth_ind = l_rec_voucherpays.pay_meth_ind 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				## Cheque may have been cancelled so ignore missing
				## cheque entries - cheque IS unapplied before
				## cancellation so the entry has no effect anyway
				IF status = NOTFOUND THEN 
					CONTINUE FOREACH 
				ELSE 
					LET l_payment_year = l_rec_cheque.year_num 
					LET l_payment_period = l_rec_cheque.period_num 
				END IF 
			ELSE 
				SELECT * INTO l_rec_debithead.* 
				FROM debithead 
				WHERE vend_code = l_rec_voucherpays.vend_code 
				AND debit_num = l_rec_voucherpays.pay_num 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = NOTFOUND THEN ## logic ERROR - ignore 
					CONTINUE FOREACH 
				ELSE 
					LET l_payment_year = l_rec_debithead.year_num 
					LET l_payment_period = l_rec_debithead.period_num 
				END IF 
			END IF 
			#################################################################
			# Determine whether the payment AND voucher are in the cutoff period
			#################################################################
			LET l_voucher_in = 0 
			IF (l_rec_voucher.year_num < glob_age_year OR 
			(l_rec_voucher.year_num = glob_age_year AND 
			l_rec_voucher.period_num <= glob_age_period)) THEN 
				LET l_voucher_in = 1 
			END IF 
			LET l_payment_in = 0 
			IF (l_payment_year < glob_age_year OR 
			(l_payment_year = glob_age_year AND 
			l_payment_period <= glob_age_period)) THEN 
				LET l_payment_in = 1 
			END IF 
			#################################################################
			# IF the payment IS outside the cut-off period but the voucher IS in,
			# check whether the voucher IS already in the temporary table AND
			# adjust the outstanding balance.  IF the voucher IS NOT found,
			# INSERT the voucher because future payments do NOT count
			#################################################################
			IF (l_voucher_in != l_payment_in) THEN 
				IF l_voucher_in THEN 
					SELECT * INTO l_rec_doc.* 
					FROM doctab 
					WHERE d_ref = l_rec_voucherpays.vouch_code 
					AND d_type = "VO" 
					IF status = 0 THEN 
						LET l_rec_doc.d_bal = l_rec_doc.d_bal + 
						(l_rec_voucherpays.apply_amt + l_rec_voucherpays.disc_amt) 
						LET l_rec_doc.d_base_bal = l_rec_doc.d_bal / l_rec_doc.d_conv_qty 
						UPDATE doctab SET d_bal = l_rec_doc.d_bal, 
						d_base_bal = l_rec_doc.d_base_bal 
						WHERE d_ref = l_rec_voucherpays.vouch_code 
						AND d_type = "VO" 
					ELSE 
						LET l_rec_doc.d_vend = l_rec_voucherpays.vend_code 
						LET l_rec_doc.d_type_code = glob_rec_vendor.type_code 
						LET l_rec_doc.d_date = l_rec_voucher.vouch_date 
						LET l_rec_doc.d_ref = l_rec_voucherpays.vouch_code 
						LET l_rec_doc.d_type = TRAN_TYPE_INVOICE_IN 
						LET l_rec_doc.d_ref_text = l_rec_voucher.inv_text 
						LET l_rec_doc.d_desc = l_rec_voucher.com1_text 
						LET l_rec_doc.d_type = "VO" 
						LET l_rec_doc.d_age = glob_age_date - l_rec_voucher.due_date 
						IF l_rec_voucher.conv_qty = 0 OR l_rec_voucher.conv_qty IS NULL THEN 
							LET l_rec_voucher.conv_qty = 1 
						END IF 
						LET l_rec_doc.d_conv_qty = l_rec_voucher.conv_qty 
						LET l_rec_doc.d_bal = l_rec_voucher.total_amt - 
						(l_rec_voucher.paid_amt - l_rec_voucherpays.apply_amt - 
						l_rec_voucherpays.disc_amt) 
						LET l_rec_doc.d_base_bal = l_rec_doc.d_bal / l_rec_doc.d_conv_qty 
						INSERT INTO doctab VALUES (l_rec_doc.*) 
					END IF 
				ELSE 
					#################################################################
					# Need TO check temp table FOR payment first. IF it IS there
					# THEN UPDATE it, OTHERWISE INSERT the details
					#################################################################
					SELECT * INTO l_rec_doc.* 
					FROM doctab 
					WHERE d_ref = l_rec_voucherpays.pay_num 
					AND d_type = l_rec_voucherpays.pay_type_code 
					IF status = 0 THEN 
						LET l_rec_doc.d_bal = l_rec_doc.d_bal - l_rec_voucherpays.apply_amt - 
						l_rec_voucherpays.disc_amt 
						LET l_rec_doc.d_base_bal = l_rec_doc.d_bal / l_rec_doc.d_conv_qty 
						UPDATE doctab 
						SET d_bal = l_rec_doc.d_bal, 
						d_base_bal = l_rec_doc.d_base_bal 
						WHERE d_ref = l_rec_voucherpays.pay_num 
						AND d_type = l_rec_voucherpays.pay_type_code 
					ELSE 
						IF l_rec_voucherpays.pay_type_code = "CH" THEN 
							LET l_rec_doc.d_vend = l_rec_cheque.vend_code 
							LET l_rec_doc.d_type_code = glob_rec_vendor.type_code 
							LET l_rec_doc.d_date = l_rec_cheque.cheq_date 
							LET l_rec_doc.d_ref = l_rec_cheque.cheq_code 
							LET l_rec_doc.d_ref_text = l_rec_cheque.com3_text 
							LET l_rec_doc.d_desc = l_rec_cheque.com1_text 
							LET l_rec_doc.d_type = "CH" 
							LET l_rec_doc.d_age = glob_age_date - l_rec_cheque.cheq_date 
							IF l_rec_cheque.conv_qty = 0 OR l_rec_cheque.conv_qty IS NULL THEN 
								LET l_rec_cheque.conv_qty = 1 
							END IF 
							LET l_rec_doc.d_conv_qty = l_rec_cheque.conv_qty 
							LET l_rec_doc.d_bal = 
							(l_rec_cheque.apply_amt - l_rec_cheque.pay_amt) - 
							(l_rec_voucherpays.apply_amt + l_rec_voucherpays.disc_amt) 
							LET l_rec_doc.d_base_bal = l_rec_doc.d_bal / l_rec_cheque.conv_qty 
							INSERT INTO doctab VALUES (l_rec_doc.*) 
						ELSE 
							LET l_rec_doc.d_vend = l_rec_debithead.vend_code 
							LET l_rec_doc.d_type_code = glob_rec_vendor.type_code 
							LET l_rec_doc.d_ref = l_rec_debithead.debit_num 
							LET l_rec_doc.d_ref_text = l_rec_debithead.debit_text 
							LET l_rec_doc.d_date = l_rec_debithead.debit_date 
							LET l_rec_doc.d_desc = l_rec_debithead.com1_text 
							LET l_rec_doc.d_type = "DB" 
							LET l_rec_doc.d_age = glob_age_date - l_rec_debithead.debit_date 
							IF l_rec_debithead.conv_qty = 0 OR 
							l_rec_debithead.conv_qty IS NULL THEN 
								LET l_rec_debithead.conv_qty = 1 
							END IF 
							LET l_rec_doc.d_conv_qty = l_rec_debithead.conv_qty 
							LET l_rec_doc.d_bal = 
							(l_rec_debithead.apply_amt - l_rec_voucherpays.apply_amt) 
							- l_rec_debithead.total_amt 
							LET l_rec_doc.d_base_bal = l_rec_doc.d_bal / l_rec_debithead.conv_qty 
							INSERT INTO doctab VALUES (l_rec_doc.*) 
						END IF 
					END IF 
				END IF 
			END IF 
		END FOREACH 
		
		DECLARE c_t_doctab CURSOR FOR 
		SELECT * FROM doctab 
		WHERE d_vend = l_rec_vendor.vend_code 
		ORDER BY d_date,d_ref
		 
		FOREACH c_t_doctab INTO l_rec_doc.*

			#---------------------------------------------------------
			OUTPUT TO REPORT PRT_rpt_list_vend_age(l_rpt_idx,
			l_rec_doc.*) 
			IF NOT rpt_int_flag_handler2("Vendor/Voucher...:",l_rec_doc.d_vend, l_rec_doc.d_ref,l_rpt_idx) THEN
				EXIT FOREACH 
			END IF 
			#---------------------------------------------------------

		END FOREACH 

		DELETE FROM doctab WHERE 1=1 

	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT PRT_rpt_list_vend_age
	CALL rpt_finish("PRT_rpt_list_vend_age")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = FALSE 
		ERROR " Printing was aborted" 
		RETURN FALSE 
	ELSE 
		RETURN TRUE 
	END IF 	
END FUNCTION 


REPORT PRT_rpt_list_vend_age(p_rpt_idx,p_rec_doc)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	  
	DEFINE p_rec_doc RECORD 
		d_vend LIKE vendor.vend_code, 
		d_type_code LIKE vendor.type_code, 
		d_date LIKE voucher.vouch_date, 
		d_ref LIKE voucher.vouch_code, 
		d_ref_text LIKE voucher.inv_text, 
		d_desc LIKE voucher.com1_text, 
		d_conv_qty LIKE voucher.conv_qty, 
		d_type CHAR(2), 
		d_age INTEGER, 
		d_bal DECIMAL(16,2), 
		d_base_bal DECIMAL(16,2) 
	END RECORD
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_vendortype RECORD LIKE vendortype.*
	DEFINE l_type_text CHAR(8)
	DEFINE l_bal_amt DECIMAL(16,2)
	DEFINE l_over90 DECIMAL(16,2)
	DEFINE l_over60_90 DECIMAL(16,2)
	DEFINE l_over30_60 DECIMAL(16,2)
	DEFINE l_over1_30 DECIMAL(16,2)
	DEFINE l_curr DECIMAL(16,2)
	DEFINE l_typ_bal_amt DECIMAL(16,2)
	DEFINE l_typ_over60_90 DECIMAL(16,2)
	DEFINE l_typ_over30_60 DECIMAL(16,2)
	DEFINE l_typ_over90 DECIMAL(16,2)
	DEFINE l_base_bal_amt DECIMAL(16,2)
	DEFINE l_typ_over1_30 DECIMAL(16,2)
	DEFINE l_typ_curr DECIMAL(16,2)
	DEFINE l_post_amt DECIMAL(16,2)
	DEFINE l_typ_post_amt DECIMAL(16,2)
--	DEFINE l_rpt_line1 CHAR(80)
--	DEFINE l_rpt_offset1 SMALLINT 
--	DEFINE l_rpt_offset2 SMALLINT

	OUTPUT 
	left margin 0 
	ORDER external BY p_rec_doc.d_type_code,p_rec_doc.d_vend 
	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			IF glob_report_level = "1" THEN 
				LET l_type_text = " Type" 
			ELSE 
				LET l_type_text = "Vendor" 
			END IF 

			PRINT COLUMN 01, l_type_text, 
			COLUMN 20, "Name", 
			COLUMN 109, "Open Item", 
			COLUMN 123, "Base Posted" 

			PRINT COLUMN 36, "Current", 
			COLUMN 49, "1-30 Days", 
			COLUMN 63, "31-60 Days", 
			COLUMN 78, "61-90 Days", 
			COLUMN 91, "Over 90 Days", 
			COLUMN 111, "Balance", 
			COLUMN 126, "Balance" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

		BEFORE GROUP OF p_rec_doc.d_type_code 
			LET l_typ_bal_amt = 0 
			LET l_typ_curr = 0 
			LET l_typ_over90 = 0 
			LET l_typ_over60_90 = 0 
			LET l_typ_over30_60 = 0 
			LET l_typ_over1_30 = 0 
			LET l_typ_post_amt = 0 
			SELECT * INTO l_rec_vendortype.* 
			FROM vendortype 
			WHERE type_code = p_rec_doc.d_type_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF glob_report_level != "1" THEN 
				NEED 3 LINES 
				SKIP 1 line 
				PRINT COLUMN 01, "Vendor Type: ", 
				l_rec_vendortype.type_code, " ", 
				l_rec_vendortype.type_text 
				SKIP 1 line 
			END IF 
		BEFORE GROUP OF p_rec_doc.d_vend 
			SELECT * INTO l_rec_vendor.* 
			FROM vendor 
			WHERE vend_code = p_rec_doc.d_vend 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF glob_report_level = '3' THEN 
				PRINT COLUMN 1, l_rec_vendor.vend_code, 
				COLUMN 10, l_rec_vendor.name_text, 
				COLUMN 42, l_rec_vendor.addr1_text, 
				COLUMN 73, l_rec_vendor.contact_text, 
				COLUMN 94, l_rec_vendor.tele_text 
				SKIP 1 line 
			END IF 
			LET l_bal_amt = 0 
			LET l_base_bal_amt = 0 
			LET l_post_amt = 0 
			LET l_curr = 0 
			LET l_over90 = 0 
			LET l_over60_90 = 0 
			LET l_over30_60 = 0 
			LET l_over1_30 = 0 
		ON EVERY ROW 
			CASE 
				WHEN (p_rec_doc.d_age > 90) 
					LET l_over90 = l_over90 + p_rec_doc.d_bal 
					LET l_typ_over90 = l_typ_over90 + p_rec_doc.d_base_bal 
					LET glob_tot_over90 = glob_tot_over90 + p_rec_doc.d_base_bal 
				WHEN (p_rec_doc.d_age > 60 AND p_rec_doc.d_age <= 90) 
					LET l_over60_90 = l_over60_90 + p_rec_doc.d_bal 
					LET l_typ_over60_90 = l_typ_over60_90 + p_rec_doc.d_base_bal 
					LET glob_tot_over60 = glob_tot_over60 + p_rec_doc.d_base_bal 
				WHEN (p_rec_doc.d_age > 30 AND p_rec_doc.d_age <= 60) 
					LET l_over30_60 = l_over30_60 + p_rec_doc.d_bal 
					LET l_typ_over30_60 = l_typ_over30_60 + p_rec_doc.d_base_bal 
					LET glob_tot_over30 = glob_tot_over30 + p_rec_doc.d_base_bal 
				WHEN (p_rec_doc.d_age > 0 AND p_rec_doc.d_age <= 30) 
					LET l_over1_30 = l_over1_30 + p_rec_doc.d_bal 
					LET l_typ_over1_30 = l_typ_over1_30 + p_rec_doc.d_base_bal 
					LET glob_tot_over1 = glob_tot_over1 + p_rec_doc.d_base_bal 
				OTHERWISE 
					LET l_curr = l_curr + p_rec_doc.d_bal 
					LET l_typ_curr = l_typ_curr + p_rec_doc.d_base_bal 
					LET glob_tot_curr = glob_tot_curr + p_rec_doc.d_base_bal 
			END CASE 
			LET l_bal_amt = l_bal_amt + p_rec_doc.d_bal 
			LET l_base_bal_amt = l_base_bal_amt + p_rec_doc.d_base_bal 
			LET l_post_amt = l_post_amt + p_rec_doc.d_base_bal 
			LET l_typ_bal_amt = l_typ_bal_amt + p_rec_doc.d_base_bal 
			LET l_typ_post_amt = l_typ_post_amt + p_rec_doc.d_base_bal 
			LET glob_tot_bal = glob_tot_bal + p_rec_doc.d_base_bal 
			LET glob_tot_post_amt = glob_tot_post_amt + p_rec_doc.d_base_bal 
			IF glob_report_level = '3' THEN 
				PRINT COLUMN 01, p_rec_doc.d_type, 
				COLUMN 03, p_rec_doc.d_ref USING "########&", 
				COLUMN 13, p_rec_doc.d_date USING "dd/mm/yy", 
				COLUMN 22, p_rec_doc.d_ref_text, 
				COLUMN 42, p_rec_doc.d_desc, 
				COLUMN 104, p_rec_doc.d_bal USING "---,---,--&.&&", 
				COLUMN 119, (p_rec_doc.d_base_bal) 
				USING "---,---,--&.&&" 
			END IF 

		AFTER GROUP OF p_rec_doc.d_vend 
			IF glob_report_level != "1" THEN 
				NEED 4 LINES 
				LET glob_tot_vend = glob_tot_vend + 1 
				IF glob_report_level = "2" THEN 
					PRINT COLUMN 1, l_rec_vendor.vend_code, 
					COLUMN 10, l_rec_vendor.name_text, 
					COLUMN 42, l_rec_vendor.addr1_text, 
					COLUMN 73, l_rec_vendor.contact_text, 
					COLUMN 94, l_rec_vendor.tele_text 
				ELSE 
					SKIP 1 line 
				END IF 
				PRINT COLUMN 02, l_rec_vendor.currency_code, 
				COLUMN 29, l_curr USING "---,---,--&.&&", 
				COLUMN 44, l_over1_30 USING "---,---,--&.&&", 
				COLUMN 59, l_over30_60 USING "---,---,--&.&&", 
				COLUMN 74, l_over60_90 USING "---,---,--&.&&", 
				COLUMN 89, l_over90 USING "---,---,--&.&&", 
				COLUMN 104, l_bal_amt USING "---,---,--&.&&"; 
				IF l_rec_vendor.currency_code = glob_pr_base_currency THEN 
					PRINT COLUMN 119, l_post_amt USING "---,---,--&.&&" 
				END IF 
				SKIP 1 line 
				IF l_rec_vendor.currency_code != glob_pr_base_currency THEN 
					PRINT COLUMN 02, glob_pr_base_currency, 
					COLUMN 104, l_base_bal_amt USING "---,---,--&.&&", 
					COLUMN 119, l_post_amt USING "---,---,--&.&&" 
				END IF 
			END IF 
		AFTER GROUP OF p_rec_doc.d_type_code 
			IF glob_report_level != "1" THEN 
				PRINT COLUMN 29, "----------------------------------------------------", 
				"----------------------------------------------------" 
				PRINT COLUMN 01,"Total "; 
			END IF 
			PRINT COLUMN 07, p_rec_doc.d_type_code, 
			COLUMN 11, l_rec_vendortype.type_text 
			PRINT COLUMN 02, glob_pr_base_currency, 
			COLUMN 29, l_typ_curr USING "---,---,--&.&&", 
			COLUMN 44, l_typ_over1_30 USING "---,---,--&.&&", 
			COLUMN 59, l_typ_over30_60 USING "---,---,--&.&&", 
			COLUMN 74, l_typ_over60_90 USING "---,---,--&.&&", 
			COLUMN 89, l_typ_over90 USING "---,---,--&.&&", 
			COLUMN 104, l_typ_bal_amt USING "---,---,--&.&&", 
			COLUMN 119, l_typ_post_amt USING "---,---,--&.&&" 
			SKIP 2 LINES 

		ON LAST ROW 
			NEED 7 LINES 
			PRINT COLUMN 29, "----------------------------------------------------", 
			"----------------------------------------------------" 
			PRINT COLUMN 01,"In ", glob_pr_base_currency, " Totals:", 
			COLUMN 43, glob_tot_over1 USING "----,---,--&.&&", 
			COLUMN 73, glob_tot_over60 USING "----,---,--&.&&", 
			COLUMN 103, glob_tot_bal USING "----,---,--&.&&" 
			PRINT COLUMN 01,"Total Vendors: ", glob_tot_vend USING "###", 
			COLUMN 28, glob_tot_curr USING "----,---,--&.&&", 
			COLUMN 58, glob_tot_over30 USING "----,---,--&.&&", 
			COLUMN 88, glob_tot_over90 USING "----,---,--&.&&", 
			COLUMN 118, glob_tot_post_amt USING "----,---,--&.&&" 
			
			SKIP 2 line 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			 
END REPORT