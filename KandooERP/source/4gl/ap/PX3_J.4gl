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
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
############################################################
# MODULE Scope Variables
############################################################
DEFINE modu_rec_tenthead RECORD LIKE tenthead.* 
DEFINE modu_cycle_num LIKE tentpays.cycle_num 
DEFINE modu_pr_header SMALLINT 
############################################################
# MAIN
#
#
############################################################
MAIN 
	DEFINE l_prog_call CHAR(10) 
	DEFINE l_msgresp LIKE language.yes_flag 

	#Initial UI Init
	CALL setModuleId("PX3_J") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL fgl_winmessage("??? Moudle","Special Australian WestPacs Bank\nundocumented module - needs 2 arguments","info") 
	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_p_ap() #init p/ap module 

	LET modu_cycle_num = get_url_cycle_num() #arg_val(1) 
	LET l_prog_call = get_url_prog_child() #arg_val(2) 
	IF l_prog_call IS NOT NULL THEN 
		IF l_prog_call = "P3A" THEN 
			CALL westpac_interface() 
		END IF 
	END IF 
END MAIN 


############################################################
# FUNCTION westpac_interface()
#
#
############################################################
FUNCTION westpac_interface() 
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE l_rec_bank RECORD LIKE bank.* 
	DEFINE l_rec_tentpays RECORD LIKE tentpays.* 
	DEFINE l_rec_cheque RECORD LIKE cheque.* 
	DEFINE l_comment CHAR(60) 
	DEFINE l_done INTEGER 
	DEFINE l_doc_num INTEGER 
	DEFINE l_count INTEGER 
	DEFINE l_complete FLOAT 
	DEFINE l_msgresp LIKE language.yes_flag 

	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start("PX3_J-U","PX3_rpt_list_westpac_unload","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT PX3_rpt_list_westpac_unload TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = 0, 
	BOTTOM MARGIN = 0, 
	LEFT MARGIN = 0, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start("PX3_J-S","PX3_rpt_list_westpac_summary","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT PX3_rpt_list_westpac_summary TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = 0, 
	BOTTOM MARGIN = 0, 
	LEFT MARGIN = 0, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	LET modu_pr_header = true 
	OPEN WINDOW p237 with FORM "P237" 
	CALL windecoration_p("P237") 

	LET l_msgresp = kandoomsg("U",1002,"") 
	#1002 Searching database - please wait

	SELECT * INTO modu_rec_tenthead.* FROM tenthead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cycle_num = modu_cycle_num 
	IF status != 0 THEN 
		LET l_msgresp = kandoomsg("P","7070",modu_cycle_num) 
		#7070 The Automatic Payment Cycle VALUE does NOT exist
		EXIT PROGRAM 
	END IF 

	SELECT * INTO l_rec_bank.* FROM bank 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND bank_code = modu_rec_tenthead.bank_code 
	SELECT count(*) INTO l_count FROM tentpays 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cycle_num = modu_cycle_num 
	AND status_ind = "4" 
	IF l_count = 0 
	OR l_count IS NULL THEN 
		LET l_msgresp=kandoomsg("P","7069",modu_cycle_num) 
		#7069 There are NO Automatic Payments TO process...
		EXIT PROGRAM 
	END IF 

	DECLARE c_tentpays CURSOR FOR 
	SELECT * FROM tentpays 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cycle_num = modu_cycle_num 
	AND status_ind = "4" 
	ORDER BY pay_meth_ind, 
	pay_doc_num, 
	vouch_date, 
	inv_text 


	LET l_done = 0 
	FOREACH c_tentpays INTO l_rec_tentpays.* 
		LET l_done = l_done + 1 
		LET l_complete = ((l_done/l_count) * 100) 
		IF l_complete mod 10 = 0 THEN 
			LET l_comment = "Processing in Progress..", 
			l_complete USING "##&", "% Complete" 
			DISPLAY l_comment TO comments1 

		END IF 

		#---------------------------------------------------------
		OUTPUT TO REPORT PX3_rpt_list_westpac_unload(l_rpt_idx,l_rec_tentpays.*) 
		IF NOT rpt_int_flag_handler2("Company:",l_rec_tentpays.cmpy_code, l_rec_tentpays.cycle_num,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------	
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT PX3_rpt_list_westpac_unload
	CALL rpt_finish("PX3_rpt_list_westpac_unload")
	#------------------------------------------------------------


	SELECT count(unique pay_doc_num) INTO l_count FROM tentpays 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cycle_num = modu_cycle_num 
	AND status_ind = "4" 
	DECLARE c_tentpays2 CURSOR FOR 
	SELECT unique pay_doc_num FROM tentpays 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cycle_num = modu_cycle_num 
	AND status_ind = "4" 
	LET l_done = 0 
	FOREACH c_tentpays2 INTO l_doc_num 
		SELECT * INTO l_rec_cheque.* FROM cheque 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND doc_num = l_doc_num 
		LET l_done = l_done + 1 
		LET l_complete = ((l_done/l_count) * 100) 
		IF l_complete mod 10 = 0 THEN 
			LET l_comment = "Processing Summary Report: ", 
			l_complete USING "##&", "% Complete" 
			DISPLAY l_comment TO comments1 

		END IF 

		IF status = 0 THEN 
			#---------------------------------------------------------
			OUTPUT TO REPORT PX3_rpt_list_westpac_summary(l_rpt_idx,l_rec_cheque.*) 
			#---------------------------------------------------------	
			
		END IF 
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT PX3_rpt_list_westpac_summary
	CALL rpt_finish("PX3_rpt_list_westpac_summary")
	#------------------------------------------------------------	
	
	CLOSE WINDOW P237 

END FUNCTION 


############################################################
# REPORT PX3_rpt_list_westpac_unload(p_rpt_idx,p_rec_tentpays)
#
#
############################################################
REPORT PX3_rpt_list_westpac_unload(p_rpt_idx,p_rec_tentpays) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_tentpays RECORD LIKE tentpays.* 
	DEFINE l_rec_vouchpayee RECORD LIKE vouchpayee.* 
	DEFINE l_rec_cheque RECORD LIKE cheque.* 
	DEFINE l_rec_cheque2 RECORD LIKE cheque.* 
	DEFINE l_rec_debithead RECORD LIKE debithead.* 
	DEFINE l_rec_voucher RECORD LIKE voucher.* 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_work_amt DECIMAL(10,2) 
	DEFINE l_shop_amt DECIMAL(10,2) 
	DEFINE l_apply_amt DECIMAL(10,2) 
	DEFINE l_disc_amt DECIMAL(10,2) 
	DEFINE l_invoiced_total DECIMAL(10,2) 
	DEFINE l_adjusted_total DECIMAL(10,2) 
	DEFINE l_discount_total DECIMAL(10,2) 
	DEFINE l_cheque_total DECIMAL(10,2) 
	DEFINE l_rec_payment 
	RECORD 
		cred_code CHAR(15), 
		name_text CHAR(35), 
		addr1_text CHAR(35), 
		addr2_text CHAR(35), 
		addr3_text CHAR(35), 
		city_text CHAR(25), 
		state_code CHAR(3), 
		post_code CHAR(9), 
		pay_meth_ind CHAR(1), 
		remittance_type CHAR(1), 
		post_type CHAR(1), 
		fax_text CHAR(15), 
		cheque_code CHAR(18), 
		cheque_number CHAR(7), 
		vend_type_ind CHAR(1) 
	END RECORD 
	DEFINE l_rec_invoice 
	RECORD 
		inv_num CHAR(10), 
		invoiced_amt DECIMAL(10,2), 
		inv_sign_text CHAR(1), 
		paid_sign_text CHAR(1), 
		discount_amt DECIMAL(10,2), 
		disc_sign_text CHAR(1), 
		desc_text CHAR(80) 
	END RECORD 
	DEFINE l_payee_reference CHAR(10) 
	DEFINE l_time CHAR(10) 
	DEFINE l_pay_type_code CHAR(2) 
	DEFINE l_pay_num INTEGER 
	DEFINE l_pay_doc_num INTEGER
	DEFINE l_shop_invoice SMALLINT 
	DEFINE l_unauthorised_invoice SMALLINT 
	DEFINE l_payment_num SMALLINT 
	DEFINE l_invoice_num SMALLINT 
	DEFINE i SMALLINT 
	DEFINE j SMALLINT 

	OUTPUT 
--	left margin 0 
--	top margin 0 
--	bottom margin 0 
--	PAGE length 1 
	ORDER external BY p_rec_tentpays.pay_meth_ind, 
	p_rec_tentpays.pay_doc_num, 
	p_rec_tentpays.vouch_date, 
	p_rec_tentpays.inv_text 
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
	
		BEFORE GROUP OF p_rec_tentpays.pay_doc_num 
			IF modu_pr_header THEN 
				####  HEADER RECORD  #####
				LET l_time = time 
				FOR i = 1 TO 8 
					IF i >= 3 THEN 
						LET l_time[i] = l_time[i+1] 
					END IF 
					IF i >= 5 THEN 
						LET l_time[i] = l_time[i+2] 
					END IF 
				END FOR 
				LET l_payee_reference = modu_rec_tenthead.eft_run_num 
				# NOTE: Westpac identify the correct script FOR processing based on finding
				#       the text "JMJ" in the header - do NOT change without consulting
				#       the Westpac PPS staff.
				PRINT "01", "JMJ ",modu_rec_tenthead.cheq_date USING "ddmmyy", 
				l_time[1,6],"GE Capital F/S ", 
				l_payee_reference, 
				" ", 
				" ", 
				" ", 
				" ", 
				" ", 
				" " 
				####  END OF HEADER RECORD  #####
				LET l_cheque_total = 0 
				LET l_payment_num = 0 
				LET l_invoice_num = 0 
				LET modu_pr_header = false 
			END IF 
			LET l_payment_num = l_payment_num + 1 
			INITIALIZE l_rec_payment.* TO NULL 
			####  PAYMENT RECORD  #####
			SELECT * INTO l_rec_cheque.* FROM cheque 
			WHERE doc_num = p_rec_tentpays.pay_doc_num 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			INITIALIZE l_rec_customer.* TO NULL 
			INITIALIZE l_rec_vendor.* TO NULL 
			INITIALIZE l_rec_vouchpayee.* TO NULL 
			SELECT * INTO l_rec_vendor.* FROM vendor 
			WHERE vend_code = l_rec_cheque.vend_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF l_rec_vendor.pay_meth_ind = "1" THEN 
				LET l_rec_payment.cheque_number = l_rec_cheque.cheq_code 
			ELSE 
				LET l_rec_payment.cheque_number = " " 
			END IF 
			IF l_rec_cheque.source_ind = "8" THEN 
				SELECT * INTO l_rec_customer.* FROM customer 
				WHERE cust_code = l_rec_cheque.source_text 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET l_rec_payment.cred_code = l_rec_customer.cust_code 
				LET l_rec_payment.name_text = l_rec_customer.name_text 
				LET l_rec_payment.addr1_text = l_rec_customer.addr1_text 
				LET l_rec_payment.addr2_text = l_rec_customer.addr2_text 
				LET l_rec_payment.addr3_text = " " 
				LET l_rec_payment.city_text = l_rec_customer.city_text 
				LET l_rec_payment.state_code = l_rec_customer.state_code 
				LET l_rec_payment.post_code = l_rec_customer.post_code 
				LET l_rec_payment.fax_text = l_rec_customer.fax_text 
			ELSE 
				IF l_rec_cheque.source_ind = "S" THEN ## sundry voucher 
					SELECT * INTO l_rec_vouchpayee.* FROM vouchpayee 
					WHERE vend_code = l_rec_cheque.vend_code 
					AND vouch_code = l_rec_cheque.source_text 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					LET l_rec_payment.cred_code = "SUNDRY" 
					LET l_rec_payment.name_text = l_rec_vouchpayee.name_text 
					LET l_rec_payment.addr1_text = l_rec_vouchpayee.addr1_text 
					LET l_rec_payment.addr2_text = l_rec_vouchpayee.addr2_text 
					LET l_rec_payment.addr3_text = l_rec_vouchpayee.addr3_text 
					LET l_rec_payment.city_text = l_rec_vouchpayee.city_text 
					LET l_rec_payment.state_code = l_rec_vouchpayee.state_code 
					LET l_rec_payment.post_code = l_rec_vouchpayee.post_code 
					LET l_rec_payment.fax_text = "" 
					LET l_rec_vendor.bank_acct_code = l_rec_vouchpayee.bank_acct_code 
				ELSE 
					LET l_rec_payment.cred_code = l_rec_vendor.vend_code 
					LET l_rec_payment.name_text = l_rec_vendor.name_text 
					LET l_rec_payment.addr1_text = l_rec_vendor.addr1_text 
					LET l_rec_payment.addr2_text = l_rec_vendor.addr2_text 
					LET l_rec_payment.addr3_text = l_rec_vendor.addr3_text 
					LET l_rec_payment.city_text = l_rec_vendor.city_text 
					LET l_rec_payment.state_code = l_rec_vendor.state_code 
					LET l_rec_payment.post_code = l_rec_vendor.post_code 
					LET l_rec_payment.fax_text = l_rec_vendor.fax_text 
				END IF 
			END IF 
			IF l_rec_vouchpayee.vend_code IS NOT NULL THEN 
				IF l_rec_vouchpayee.pay_meth_ind = "1" THEN 
					LET l_rec_payment.pay_meth_ind = "C" 
				ELSE 
					LET l_rec_payment.pay_meth_ind = "D" 
				END IF 
			ELSE 
				IF l_rec_vendor.pay_meth_ind = "1" THEN 
					LET l_rec_payment.pay_meth_ind = "C" 
				ELSE 
					LET l_rec_payment.pay_meth_ind = "D" 
				END IF 
			END IF 
			IF l_rec_payment.pay_meth_ind = "D" THEN 
				IF l_rec_payment.fax_text IS NULL OR 
				l_rec_payment.fax_text = " " THEN 
					LET l_rec_payment.remittance_type = "P" 
					LET l_rec_payment.post_type = "P" 
				ELSE 
					LET l_rec_payment.remittance_type = "F" 
					LET l_rec_payment.post_type = "N" 
				END IF 
			ELSE 
				LET l_rec_payment.remittance_type = "P" 
				IF l_rec_payment.fax_text = "RETURN" THEN 
					LET l_rec_payment.post_type = "R" 
				ELSE 
					LET l_rec_payment.post_type = "P" 
				END IF 
			END IF 
			IF l_rec_payment.remittance_type != "F" THEN 
				LET l_rec_payment.fax_text = " " 
			END IF 
			IF l_rec_vendor.type_code = "V70" 
			OR l_rec_vendor.type_code = "N80" 
			OR l_rec_vendor.type_code = "W95" THEN 
				LET l_rec_payment.vend_type_ind = "G" 
			ELSE 
				LET l_rec_payment.vend_type_ind = "N" 
			END IF 
			LET l_rec_payment.cheque_code = l_rec_cheque.cheq_code 
			LET l_cheque_total = l_cheque_total + l_rec_cheque.net_pay_amt 
			PRINT "02",l_rec_payment.cred_code, 
			(l_rec_cheque.net_pay_amt * 100) USING "&&&&&&&&&&&&&", 
			l_rec_cheque.currency_code, 
			l_rec_payment.name_text, 
			l_rec_payment.addr1_text, 
			l_rec_payment.addr2_text, 
			l_rec_payment.addr3_text, 
			l_rec_payment.city_text," ", 
			l_rec_payment.state_code," ", 
			l_rec_payment.post_code, 
			l_rec_payment.pay_meth_ind, 
			l_rec_payment.remittance_type, 
			l_rec_payment.post_type,"3", 
			l_rec_vendor.bank_acct_code[1,3],"-", 
			l_rec_vendor.bank_acct_code[4,6], 
			l_rec_vendor.bank_acct_code[8,16], 
			l_rec_payment.fax_text, 
			l_rec_payment.cheque_code, 
			" ", 
			l_rec_payment.cheque_number USING "&&&&&&&", 
			l_rec_payment.vend_type_ind, 
			" " 
			###  END OF PAYMENT RECORD  ###
			LET l_invoiced_total = 0 
			LET l_adjusted_total = 0 
			LET l_discount_total = 0 
			#LET pr_tax_total = 0
		ON EVERY ROW 
			####  INVOICE RECORD  #####
			INITIALIZE l_rec_invoice.* TO NULL 
			INITIALIZE l_rec_voucher.* TO NULL 
			SELECT * INTO l_rec_voucher.* FROM voucher 
			WHERE vouch_code = p_rec_tentpays.vouch_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF l_rec_voucher.com1_text[1,5] = "WORK" THEN 
				LET l_rec_invoice.inv_num = l_rec_voucher.com1_text[6,12] 
				IF l_rec_payment.vend_type_ind = "G" 
				AND l_rec_voucher.com1_text[25,25] = "T" THEN 
					LET l_rec_invoice.inv_num = l_rec_invoice.inv_num clipped,"*" 
				END IF 
			ELSE 
				LET l_rec_invoice.inv_num = l_rec_voucher.com1_text[1,7] 
			END IF 
			#
			# Retrieve Unauthorised Work / Shop Supplies amounts
			#
			LET l_work_amt = 0 
			LET l_shop_amt = 0 
			LET l_unauthorised_invoice = false 
			LET l_shop_invoice = false 
			IF l_rec_voucher.com1_text[1,5] = "WORK" THEN 
				FOR i = 1 TO 28 
					IF l_rec_voucher.com2_text[i,i+2] = '(u)' THEN 
						WHENEVER ERROR CONTINUE 
						LET l_work_amt = l_rec_voucher.com2_text[1,i-1] 
						WHENEVER ERROR stop 
						IF status < 0 THEN 
							LET l_work_amt = 0 
						ELSE 
							LET l_unauthorised_invoice = true 
						END IF 
						EXIT FOR 
					END IF 
				END FOR 
				IF i > 24 THEN 
					LET i = 1 
				ELSE 
					LET i = i + 3 
				END IF 
				FOR j = i TO 28 
					IF l_rec_voucher.com2_text[j,j+2] = '(s)' THEN 
						WHENEVER ERROR CONTINUE 
						LET l_shop_amt = l_rec_voucher.com2_text[i,j-1] 
						WHENEVER ERROR stop 
						IF status < 0 THEN 
							LET l_shop_amt = 0 
						ELSE 
							LET l_shop_invoice = true 
						END IF 
					END IF 
				END FOR 
			END IF 
			LET l_rec_invoice.invoiced_amt = l_rec_voucher.total_amt 
			+ l_work_amt 
			+ l_shop_amt 
			LET l_rec_invoice.discount_amt = p_rec_tentpays.taken_disc_amt 
			IF l_rec_invoice.invoiced_amt < 0 THEN 
				LET l_rec_invoice.inv_sign_text = "-" 
			ELSE 
				LET l_rec_invoice.inv_sign_text = "+" 
			END IF 
			IF p_rec_tentpays.vouch_amt < 0 THEN 
				LET l_rec_invoice.paid_sign_text = "-" 
			ELSE 
				LET l_rec_invoice.paid_sign_text = "+" 
			END IF 
			IF l_rec_invoice.discount_amt < 0 THEN 
				LET l_rec_invoice.disc_sign_text = "+" 
			ELSE 
				LET l_rec_invoice.disc_sign_text = "-" 
			END IF 
			LET l_rec_invoice.desc_text = l_rec_voucher.inv_text[1,15] 
			LET l_invoiced_total = l_invoiced_total + l_rec_invoice.invoiced_amt 
			LET l_discount_total = l_discount_total + p_rec_tentpays.taken_disc_amt 
			LET l_invoice_num = l_invoice_num + 1 
			PRINT "03",l_rec_invoice.inv_num, 
			l_rec_voucher.vouch_date USING "ddmmyy", 
			(l_rec_invoice.invoiced_amt * 100) USING "&&&&&&&&&&&&&", 
			l_rec_invoice.inv_sign_text, 
			(p_rec_tentpays.vouch_amt * 100) USING "&&&&&&&&&&&&&", 
			l_rec_invoice.paid_sign_text, 
			l_rec_invoice.desc_text, 
			(l_rec_invoice.discount_amt * 100) USING "&&&&&&&&&&&&&", 
			" ", 
			" ", 
			"I", 
			" ", 
			" ", 
			" " 
			###  END OF INVOICE RECORD  ###

			###  INVOICE ADJUSTMENT RECORDS  ###
			IF l_shop_invoice 
			AND l_shop_amt != 0 THEN 
				LET l_rec_invoice.invoiced_amt = 0 
				LET l_rec_invoice.inv_num = " " 
				LET l_rec_invoice.desc_text = "Shop Supplies" 
				IF l_shop_amt < 0 THEN 
					LET l_rec_invoice.disc_sign_text = "+" 
				ELSE 
					LET l_rec_invoice.disc_sign_text = "-" 
				END IF 
				LET l_invoice_num = l_invoice_num + 1 
				PRINT "03",l_rec_invoice.inv_num, 
				l_rec_voucher.vouch_date USING "ddmmyy", 
				(l_rec_invoice.invoiced_amt * 100) USING "&&&&&&&&&&&&&", 
				"+", 
				(l_rec_invoice.invoiced_amt * 100) USING "&&&&&&&&&&&&&", 
				"+", 
				l_rec_invoice.desc_text, 
				(l_shop_amt * 100) USING "&&&&&&&&&&&&&", 
				" ", 
				" ", 
				"A", 
				" ", 
				" ", 
				" " 
				LET l_adjusted_total = l_adjusted_total + l_shop_amt 
			END IF 
			IF l_unauthorised_invoice 
			AND l_work_amt != 0 THEN 
				LET l_rec_invoice.invoiced_amt = 0 
				LET l_rec_invoice.inv_num = " " 
				LET l_rec_invoice.desc_text = "Unauth. Work" 
				IF l_work_amt < 0 THEN 
					LET l_rec_invoice.disc_sign_text = "+" 
				ELSE 
					LET l_rec_invoice.disc_sign_text = "-" 
				END IF 
				LET l_invoice_num = l_invoice_num + 1 
				PRINT "03",l_rec_invoice.inv_num, 
				l_rec_voucher.vouch_date USING "ddmmyy", 
				(l_rec_invoice.invoiced_amt * 100) USING "&&&&&&&&&&&&&", 
				"+", 
				(l_rec_invoice.invoiced_amt * 100) USING "&&&&&&&&&&&&&", 
				"+", 
				l_rec_invoice.desc_text, 
				(l_work_amt * 100) USING "&&&&&&&&&&&&&", 
				" ", 
				" ", 
				"A", 
				" ", 
				" ", 
				" " 
				LET l_adjusted_total = l_adjusted_total + l_work_amt 
			END IF 
			DECLARE c_otherpays CURSOR FOR 
			SELECT pay_doc_num, 
			pay_num, 
			pay_type_code, 
			sum(apply_amt), 
			sum(disc_amt) 
			FROM voucherpays 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND vend_code = p_rec_tentpays.vend_code 
			AND vouch_code = p_rec_tentpays.vouch_code 
			AND pay_doc_num != p_rec_tentpays.pay_doc_num 
			AND remit_doc_num = p_rec_tentpays.pay_doc_num 
			AND (rev_flag != "Y" OR rev_flag IS null) 
			GROUP BY 1,2,3 
			having sum(apply_amt+disc_amt) != 0 
			FOREACH c_otherpays INTO l_pay_doc_num, 
				l_pay_num, l_pay_type_code, 
				l_apply_amt, l_disc_amt 
				IF l_pay_type_code = "DB" THEN 
					INITIALIZE l_rec_debithead.* TO NULL 
					SELECT * INTO l_rec_debithead.* FROM debithead 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND debit_num = l_pay_num 
					AND vend_code = p_rec_tentpays.vend_code 
					IF l_apply_amt IS NULL THEN 
						LET l_apply_amt = 0 
					END IF 
					IF l_disc_amt IS NULL THEN 
						LET l_disc_amt = 0 
					END IF 
					LET l_apply_amt = l_apply_amt + l_disc_amt 
					IF l_rec_debithead.com1_text[1,4] = "WORK" THEN 
						LET l_rec_invoice.inv_num = l_rec_debithead.com1_text[6,12] 
						IF l_rec_payment.vend_type_ind = "G" 
						AND l_rec_voucher.com1_text[25,25] = "T" THEN 
							LET l_rec_invoice.inv_num = l_rec_invoice.inv_num clipped,"*" 
						END IF 
					ELSE 
						LET l_rec_invoice.inv_num = l_rec_debithead.com1_text[1,7] 
					END IF 
					LET l_rec_invoice.invoiced_amt = 0 
					LET l_rec_invoice.desc_text = "Debit Adjustment" 
					IF l_apply_amt < 0 THEN 
						LET l_rec_invoice.disc_sign_text = "+" 
					ELSE 
						LET l_rec_invoice.disc_sign_text = "-" 
					END IF 
					LET l_invoice_num = l_invoice_num + 1 
					PRINT "03",l_rec_invoice.inv_num, 
					l_rec_debithead.debit_date USING "ddmmyy", 
					(l_rec_invoice.invoiced_amt * 100) USING "&&&&&&&&&&&&&", 
					"+", 
					(l_rec_invoice.invoiced_amt * 100) USING "&&&&&&&&&&&&&", 
					"+", 
					l_rec_invoice.desc_text, 
					(l_apply_amt * 100) USING "&&&&&&&&&&&&&", 
					" ", 
					" ", 
					"A", 
					" ", 
					" ", 
					" " 
					LET l_adjusted_total = l_adjusted_total + l_apply_amt 
				ELSE 
					INITIALIZE l_rec_cheque2.* TO NULL 
					SELECT * INTO l_rec_cheque2.* FROM cheque 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND doc_num = l_pay_doc_num 
					IF l_disc_amt IS NULL THEN 
						LET l_disc_amt = 0 
					END IF 
					IF l_apply_amt IS NULL THEN 
						LET l_apply_amt = 0 
					END IF 
					LET l_apply_amt = l_apply_amt + l_disc_amt 
					IF l_rec_cheque2.com1_text[1,4] = "WORK" THEN 
						LET l_rec_invoice.inv_num = l_rec_cheque2.com1_text[6,12] 
					ELSE 
						LET l_rec_invoice.inv_num = l_rec_cheque2.com1_text[1,7] 
					END IF 
					LET l_rec_invoice.invoiced_amt = 0 
					LET l_rec_invoice.desc_text = "Manual Cheques" 
					IF l_apply_amt < 0 THEN 
						LET l_rec_invoice.disc_sign_text = "+" 
					ELSE 
						LET l_rec_invoice.disc_sign_text = "-" 
					END IF 
					LET l_invoice_num = l_invoice_num + 1 
					PRINT "03",l_rec_invoice.inv_num, 
					l_rec_cheque2.cheq_date USING "ddmmyy", 
					(l_rec_invoice.invoiced_amt * 100) USING "&&&&&&&&&&&&&", 
					"+", 
					(l_rec_invoice.invoiced_amt * 100) USING "&&&&&&&&&&&&&", 
					"+", 
					l_rec_invoice.desc_text, 
					(l_apply_amt * 100) USING "&&&&&&&&&&&&&", 
					" ", 
					" ", 
					"A", 
					" ", 
					" ", 
					" " 
					LET l_adjusted_total = l_adjusted_total + l_apply_amt 
				END IF 
			END FOREACH 
			###  END OF INVOICE ADJUSTMENT RECORDS  ###
			UPDATE tentpays 
			SET page_num = 1 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND vend_code = p_rec_tentpays.vend_code 
			AND vouch_code = p_rec_tentpays.vouch_code 
		AFTER GROUP OF p_rec_tentpays.pay_doc_num 
			### PPT ADJUSTMENT RECORD ###
			IF l_rec_cheque.tax_amt != 0 THEN 
				LET l_rec_invoice.invoiced_amt = 0 
				LET l_rec_invoice.inv_num = " " 
				LET l_rec_invoice.desc_text = "PPT" 
				IF l_rec_cheque.tax_amt < 0 THEN 
					LET l_rec_invoice.disc_sign_text = "+" 
				ELSE 
					LET l_rec_invoice.disc_sign_text = "-" 
				END IF 
				LET l_invoice_num = l_invoice_num + 1 
				PRINT "03",l_rec_invoice.inv_num, 
				l_rec_voucher.vouch_date USING "ddmmyy", 
				(l_rec_invoice.invoiced_amt * 100) USING "&&&&&&&&&&&&&", 
				"+", 
				(l_rec_invoice.invoiced_amt * 100) USING "&&&&&&&&&&&&&", 
				"+", 
				l_rec_invoice.desc_text, 
				(l_rec_cheque.tax_amt * 100) USING "&&&&&&&&&&&&&", 
				" ", 
				" ", 
				"A", 
				" ", 
				" ", 
				" " 
				LET l_adjusted_total = l_adjusted_total + l_rec_cheque.tax_amt 
			END IF 
			### END OF PPT ADJUSTMENT RECORD ###

			### CONTRA ADJUSTMENT RECORD ###
			IF l_rec_cheque.contra_amt != 0 THEN 
				LET l_rec_invoice.invoiced_amt = 0 
				LET l_rec_invoice.inv_num = " " 
				LET l_rec_invoice.desc_text = "Contra Adj'ment" 
				IF l_rec_cheque.contra_amt < 0 THEN 
					LET l_rec_invoice.disc_sign_text = "+" 
				ELSE 
					LET l_rec_invoice.disc_sign_text = "-" 
				END IF 
				LET l_invoice_num = l_invoice_num + 1 
				PRINT "03",l_rec_invoice.inv_num, 
				l_rec_voucher.vouch_date USING "ddmmyy", 
				(l_rec_invoice.invoiced_amt * 100) USING "&&&&&&&&&&&&&", 
				"+", 
				(l_rec_invoice.invoiced_amt * 100) USING "&&&&&&&&&&&&&", 
				"+", 
				l_rec_invoice.desc_text, 
				(l_rec_cheque.contra_amt * 100) USING "&&&&&&&&&&&&&", 
				" ", 
				" ", 
				"A", 
				" ", 
				" ", 
				" " 
				LET l_adjusted_total = l_adjusted_total + l_rec_cheque.contra_amt 
			END IF 
			### END OF CONTRA ADJUSTMENT RECORD ###

			####  SUB-TOTAL INVOICE RECORD  #####
			IF l_invoiced_total < 0 THEN 
				LET l_rec_invoice.inv_sign_text = "-" 
			ELSE 
				LET l_rec_invoice.inv_sign_text = "+" 
			END IF 
			IF l_adjusted_total < 0 THEN 
				LET l_rec_invoice.paid_sign_text = "+" 
			ELSE 
				LET l_rec_invoice.paid_sign_text = "-" 
			END IF 
			IF l_discount_total < 0 THEN 
				LET l_rec_invoice.disc_sign_text = "+" 
			ELSE 
				LET l_rec_invoice.disc_sign_text = "-" 
			END IF 
			LET l_rec_invoice.desc_text = " " 
			LET l_rec_invoice.inv_num = " " 
			LET l_invoice_num = l_invoice_num + 1 
			PRINT "03",l_rec_invoice.inv_num, 
			l_rec_voucher.vouch_date USING "ddmmyy", 
			(l_invoiced_total * 100) USING "&&&&&&&&&&&&&", 
			l_rec_invoice.inv_sign_text, 
			(l_adjusted_total * 100) USING "&&&&&&&&&&&&&", 
			l_rec_invoice.paid_sign_text, 
			l_rec_invoice.desc_text, 
			(l_discount_total * 100) USING "&&&&&&&&&&&&&", 
			" ", 
			" ", 
			"T", 
			" ", 
			" ", 
			" " 
			###  END OF SUB-TOTAL INVOICE RECORD  ###
		ON LAST ROW 
			###  TRAILER RECORD  ###
			PRINT "99",l_payment_num USING "&&&&&", 
			l_invoice_num USING "&&&&&", 
			(l_cheque_total * 100) USING "&&&&&&&&&&&&&&&", 
			" ", 
			" ", 
			" ", 
			" ", 
			" ", 
			" " 
			###  END OF TRAILER RECORD  ###
END REPORT 

############################################################
# REPORT PX3_rpt_list_westpac_unload(p_rpt_idx,p_rec_tentpays)
#
#
############################################################
REPORT PX3_rpt_list_westpac_summary(p_rpt_idx,p_rec_cheque) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_cheque RECORD LIKE cheque.*
	DEFINE l_rec_vendor RECORD LIKE vendor.*
	DEFINE l_rec_vouchpayee RECORD LIKE vouchpayee.* 
	DEFINE l_pay_text CHAR(6) 
	DEFINE l_rpt_note CHAR(40) 
	DEFINE l_total_payment LIKE cheque.pay_amt 
	DEFINE l_line1 CHAR(80) 
	DEFINE l_offset1, l_offset2 SMALLINT 

	OUTPUT 
--	left margin 0 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 01, "Vendor", 
			COLUMN 10, "Name", 
			COLUMN 43, "Payment No", 
			COLUMN 55, "Pay Method", 
			COLUMN 75, "Amount" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
 
		ON EVERY ROW 
			SELECT * INTO l_rec_vendor.* FROM vendor 
			WHERE vend_code = p_rec_cheque.vend_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF p_rec_cheque.source_ind = "S" THEN ## sundry voucher 
				SELECT * INTO l_rec_vouchpayee.* FROM vouchpayee 
				WHERE vend_code = p_rec_cheque.vend_code 
				AND vouch_code = p_rec_cheque.source_text 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET l_rec_vendor.name_text = l_rec_vouchpayee.name_text 
			END IF 
			IF l_rec_vendor.pay_meth_ind = "1" THEN 
				LET l_pay_text = "CHEQUE" 
			ELSE 
				LET l_pay_text = "EFTPOS" 
			END IF 
			PRINT COLUMN 01, p_rec_cheque.vend_code, 
			COLUMN 10, l_rec_vendor.name_text, 
			COLUMN 43, p_rec_cheque.cheq_code USING "##########", 
			COLUMN 55, l_pay_text, 
			COLUMN 67, p_rec_cheque.pay_amt USING "---,---,--&.&&" 
			IF l_total_payment IS NULL THEN 
				LET l_total_payment = 0 
			END IF 
			LET l_total_payment = l_total_payment + p_rec_cheque.pay_amt 
		ON LAST ROW 
			PRINT COLUMN 67, "--------------" 
			PRINT COLUMN 10, "EFT Run Number: ",p_rec_cheque.eft_run_num, 
			COLUMN 50, "Total Payment: ", 
			COLUMN 67, l_total_payment USING "---,---,--&.&&" 
			SKIP 2 LINES 
			PRINT COLUMN 25, "***** END OF REPORT (P3A) *****" 

END REPORT 


