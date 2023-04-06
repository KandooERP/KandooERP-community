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

###########################################################################
# FUNCTION check_coa(p_cmpy_code,p_acct_code,p_year_num,p_period_num) 
#
# This routine checks TO see IF the nominated account exists AND IS
# OPEN FOR the year AND period
###########################################################################
FUNCTION check_coa(p_cmpy_code,p_acct_code,p_year_num,p_period_num) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_acct_code LIKE coa.acct_code 
	DEFINE p_year_num LIKE period.year_num 
	DEFINE p_period_num LIKE period.period_num 
	DEFINE l_rec_coa RECORD LIKE coa.* 

	INITIALIZE l_rec_coa.* TO NULL 
	SELECT * INTO l_rec_coa.* FROM coa 
	WHERE cmpy_code = p_cmpy_code 
	AND acct_code = p_acct_code 
	AND (start_year_num < p_year_num OR 
	(start_year_num = p_year_num 
	AND start_period_num <= p_period_num)) 
	AND (end_year_num > p_year_num OR 
	(end_year_num = p_year_num 
	AND end_period_num>= p_period_num)) 
	RETURN l_rec_coa.* 
END FUNCTION 
###########################################################################
# END FUNCTION check_coa(p_cmpy_code,p_acct_code,p_year_num,p_period_num) 
###########################################################################


###########################################################################
# FUNCTION cancel_payment
#
# This routine performs all the processing required TO cancel
# payments. It will create the necessary General Ledger journals,
# reverse any withholding tax transactions, reverse the effect
# on the vendor balance AND transfer the payment transaction TO
# the cancelled payment table cancelcheq.
# The FUNCTION must be run in a transaction, started FROM within the
# calling process. The calling process must also lock the glparms
# table FOR UPDATE, TO allow the next journal number TO be allocated.
#
# NOTE: The discount amount IS SET TO zero by the unapply_payment
# FUNCTION.  IF the code IS changed TO re-read the cheque record
# AFTER the CALL TO unapply_payment, the discount amount must
# be stored in a variable AND the stored amount used in the batch
# creation code below.
#
#
# Parameters: p_cmpy_code          = the calling company code
#             p_whom          = the user id
#             p_bank_code     = the bank code of the payment
#             p_cheq_code     = the payment TO be cancelled
#             p_pay_meth_ind  = the payment method
#             p_com1_text     = the first line of cancellation reason
#             p_com2_text     = the second line of cancellation reason
#             p_rec_state_num = the original statement number
#             p__rec_glparms       = the glparms record, already locked
#
# Returns   : CALL STATUS      = 0 IF successful, -1 IF application
#                                error, -2 IF database error (including
#                                locks)
#           : database STATUS  = the STATUS that caused the "whenever
#                                error" procedure TO be invoked, FOR
#                                CALL STATUS of -2 only
#           : error MESSAGE    = an error MESSAGE indicating the source
#                                of the database OR application error
#           : journal number   = the last journal number created, FOR
#                                UPDATE of the glparms table by the
#                                calling process
###########################################################################
FUNCTION cancel_payment(
		p_cmpy, p_whom,p_bank_code,	p_cheq_code, p_pay_meth_ind, 
		p_com1_text, p_com2_text,p_rec_state_num,p_glparms) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_whom LIKE kandoouser.sign_on_code 
	DEFINE p_bank_code LIKE bank.bank_code 
	DEFINE p_cheq_code LIKE cheque.cheq_code 
	DEFINE p_pay_meth_ind LIKE cheque.pay_meth_ind 
	DEFINE p_com1_text LIKE cheque.com1_text 
	DEFINE p_com2_text LIKE cheque.com2_text 
	DEFINE p_rec_state_num LIKE cheque.rec_state_num 
	DEFINE p_glparms RECORD LIKE glparms.* 
	DEFINE l_rc_apparms RECORD LIKE apparms.* 
	DEFINE l_rec_cheque RECORD LIKE cheque.* 
	DEFINE l_rec_cancelcheq RECORD LIKE cancelcheq.* 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_vendortype RECORD LIKE vendortype.* 
	DEFINE l_rec_apaudit RECORD LIKE apaudit.* 
	DEFINE l_rec_voucherpays RECORD LIKE voucherpays.* 
	DEFINE l_rec_wholdtax RECORD LIKE wholdtax.* 
	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_rec_batchhead RECORD LIKE batchhead.* 
	DEFINE l_rec_batchdetl RECORD LIKE batchdetl.* 
	DEFINE l_err_message CHAR(80) 
	DEFINE l_current_year LIKE period.year_num 
	DEFINE l_current_period LIKE period.period_num 
	DEFINE l_save_bal_amt LIKE vendor.bal_amt 
	DEFINE l_save_seq_num LIKE vendor.next_seq_num 
	DEFINE l_tax_adj_amt LIKE cheque.tax_amt 
	DEFINE l_call_status INTEGER 
	DEFINE l_db_status INTEGER 
	DEFINE l_tran_num INTEGER 
	DEFINE l_chq_jour_num LIKE batchhead.jour_num 

	GOTO bypass 
	LABEL ret_status: 
	RETURN -2, status, l_err_message, 0 
	LABEL bypass: 
	WHENEVER ERROR GOTO ret_status 

	SELECT * 
	INTO l_rc_apparms.* 
	FROM apparms 
	WHERE cmpy_code = p_cmpy 
	AND parm_code = "1" 

	CALL get_fiscal_year_period_for_date(p_cmpy, today) 
	RETURNING l_current_year, l_current_period 
	IF l_current_year IS NULL THEN 
		LET l_err_message = "Cancel Payment - current year & period NOT SET up" 
		RETURN -1,0,l_err_message,0 
	END IF 

	LET l_err_message = "Cancel Payment - FETCH payment RECORD FOR UPDATE" 
	DECLARE c_cheque CURSOR FOR 
	SELECT * INTO l_rec_cheque.* FROM cheque 
	WHERE cmpy_code = p_cmpy 
	AND bank_code = p_bank_code 
	AND cheq_code = p_cheq_code 
	AND cheq_code != 0 
	AND pay_meth_ind = p_pay_meth_ind 

	FOR UPDATE 
	OPEN c_cheque 
	FETCH c_cheque INTO l_rec_cheque.* 
	IF status = notfound THEN 
		LET l_err_message = "Cancel Payment - Payment RECORD NOT found" 
		RETURN -1, 100, l_err_message, 0 
	END IF 
	#
	# Check that the reconciliation statement number has NOT changed as this
	# may mean that the payment has been reconciled before locking FOR
	# UPDATE.  Note that IF this routine IS called FROM within GCE, it
	# IS OK TO cancel a previously reconciled payment (ie. a rejected
	# EFT) hence the FUNCTION cannot simple check on the reconciliation
	# flag but must ensure that the STATUS has NOT changed.
	#
	IF l_rec_cheque.rec_state_num IS NOT NULL AND 
	l_rec_cheque.rec_state_num != p_rec_state_num THEN 
		LET l_err_message = "Cancel Payment - Payment recon. STATUS has changed" 
		RETURN -1, 100, l_err_message, 0 
	END IF 

	#
	# IF the payment IS still applied, reverse the applications before
	# cancelling.
	#
	IF l_rec_cheque.apply_amt <> 0 THEN 
		CALL unapply_payment(p_whom, l_rec_cheque.*) 
		RETURNING l_call_status, l_db_status, l_err_message 
		IF l_call_status = -2 THEN 
			LET status = l_db_status 
			GOTO ret_status 
		END IF 
		IF l_call_status != 0 THEN 
			RETURN -1,0,l_err_message,0 
		END IF 
	END IF 

	#
	# Update all voucherpays FOR other payments/debits that were
	# marked as reported on this cheque AND reset TO ensure that
	# they are reported again on next payment
	#
	LET l_err_message = "Payment Cancel - Voucherpays UPDATE" 
	DECLARE c_voucherpays CURSOR FOR 
	SELECT * 
	INTO l_rec_voucherpays.* 
	FROM voucherpays 
	WHERE remit_doc_num = l_rec_cheque.doc_num 
	AND pay_doc_num <> l_rec_cheque.doc_num 
	AND cmpy_code = p_cmpy 
	FOR UPDATE 
	FOREACH c_voucherpays 
		UPDATE voucherpays 
		SET remit_doc_num = 0 
		WHERE vend_code = l_rec_voucherpays.vend_code 
		AND vouch_code = l_rec_voucherpays.vouch_code 
		AND seq_num = l_rec_voucherpays.seq_num 
		AND cmpy_code = p_cmpy 
	END FOREACH 

	#
	# Update the vendor balance AND audit details TO reverse
	# the payment TO the vendor
	#
	LET l_err_message = "Cancel Payment - FETCH vendor FOR UPDATE" 
	DECLARE c_vendor CURSOR FOR 
	SELECT * INTO l_rec_vendor.* FROM vendor 
	WHERE cmpy_code = p_cmpy 
	AND vend_code = l_rec_cheque.vend_code 
	FOR UPDATE 
	OPEN c_vendor 
	FETCH c_vendor 
	IF status = notfound THEN 
		LET l_err_message = "Vendor RECORD NOT found" 
		RETURN -1, 100, l_err_message, 0 
	END IF 

	LET l_save_bal_amt = l_rec_vendor.bal_amt 
	LET l_rec_vendor.next_seq_num = l_rec_vendor.next_seq_num + 1 
	LET l_save_seq_num = l_rec_vendor.next_seq_num 
	LET l_rec_vendor.bal_amt = l_rec_vendor.bal_amt + l_rec_cheque.pay_amt 
	LET l_rec_vendor.curr_amt = l_rec_vendor.curr_amt + l_rec_cheque.pay_amt 

	# There may be additional transactions FOR withholding tax OR contra amount.
	# Note that there IS no apaudit FOR discount because the unapply
	# takes care of it. Update the next sequence number accordingly.
	IF l_rec_cheque.tax_amt <> 0 THEN 
		LET l_rec_vendor.next_seq_num = l_rec_vendor.next_seq_num + 1 
	END IF 

	IF l_rec_cheque.contra_amt <> 0 THEN 
		LET l_rec_vendor.next_seq_num = l_rec_vendor.next_seq_num + 1 
	END IF 
	UPDATE vendor 

	SET 
		next_seq_num = l_rec_vendor.next_seq_num, 
		bal_amt = l_rec_vendor.bal_amt, 
		curr_amt = l_rec_vendor.curr_amt 
	WHERE cmpy_code = p_cmpy 
	AND vend_code = l_rec_cheque.vend_code 

	# Audit RECORD FOR net payment amount
	LET l_rec_apaudit.cmpy_code = p_cmpy 
	LET l_rec_apaudit.tran_date = today 
	LET l_rec_apaudit.vend_code = l_rec_cheque.vend_code 
	LET l_rec_apaudit.seq_num = l_save_seq_num 
	LET l_rec_apaudit.trantype_ind = "CH" 

	IF l_rec_cheque.post_flag = "Y" THEN 
		LET l_rec_apaudit.year_num = l_current_year 
		LET l_rec_apaudit.period_num = l_current_period 
	ELSE 
		LET l_rec_apaudit.year_num = l_rec_cheque.year_num 
		LET l_rec_apaudit.period_num = l_rec_cheque.period_num 
	END IF 


	LET l_rec_apaudit.source_num = l_rec_cheque.cheq_code 
	IF l_rec_cheque.pay_amt > 0 THEN 
		LET l_rec_apaudit.tran_text = "Cancel Chq Amt" 
		LET l_rec_apaudit.tran_amt = l_rec_cheque.net_pay_amt 
	ELSE 
		LET l_rec_apaudit.tran_text = "Cancel Refund" 
		LET l_rec_apaudit.tran_amt = l_rec_cheque.pay_amt 
	END IF 

	LET l_rec_apaudit.entry_code = l_rec_cheque.entry_code 
	LET l_rec_apaudit.bal_amt = l_save_bal_amt + l_rec_apaudit.tran_amt 
	LET l_rec_apaudit.currency_code = l_rec_cheque.currency_code 
	LET l_rec_apaudit.conv_qty = l_rec_cheque.conv_qty 
	LET l_rec_apaudit.entry_date = today 
	LET l_err_message = "Cancel Payment - INSERT INTO apaudit (1)" 

	INSERT INTO apaudit 
	VALUES (l_rec_apaudit.*) 

	IF l_rec_cheque.tax_amt > 0 THEN 
		LET l_rec_apaudit.seq_num = l_rec_apaudit.seq_num + 1 
		LET l_rec_apaudit.tran_text = "Cancel Chq Tax" 
		LET l_rec_apaudit.tran_amt = l_rec_cheque.tax_amt 
		LET l_rec_apaudit.bal_amt = l_rec_apaudit.bal_amt + l_rec_cheque.tax_amt 
		LET l_err_message = "Cancel Payment - INSERT INTO apaudit (2)" 

		INSERT INTO apaudit VALUES (l_rec_apaudit.*) 

	END IF 

	IF l_rec_cheque.contra_amt <> 0 THEN 
		LET l_rec_apaudit.seq_num = l_rec_apaudit.seq_num + 1 
		LET l_rec_apaudit.tran_text = "Cancel Contra" 
		LET l_rec_apaudit.tran_amt = l_rec_cheque.contra_amt 
		LET l_rec_apaudit.bal_amt = l_rec_apaudit.bal_amt + l_rec_cheque.contra_amt 
		LET l_err_message = "Cancel Payment - INSERT INTO apaudit (3)" 

		INSERT INTO apaudit VALUES (l_rec_apaudit.*) 

	END IF 

	#
	# IF a contra amount has been taken with this cheque, a reversal
	# transaction IS required in the AR ledger
	#
	IF l_rec_cheque.contra_amt <> 0 THEN 
		LET l_call_status = 0 
		CASE 

			WHEN (l_rec_cheque.contra_amt > 0) 
				# Original transaction was a credit - create an invoice
				CALL contra_invoice(p_cmpy, 
				p_whom, 
				l_rec_vendor.contra_cust_code, 
				today, 
				l_current_year, 
				l_current_period, 
				p_glparms.clear_acct_code, 
				0 - l_rec_cheque.contra_amt) 
				RETURNING l_call_status, 
				l_db_status, 
				l_err_message, 
				l_tran_num 

			WHEN (l_rec_cheque.contra_amt < 0) 
				# Original transaction was an invoice - create an credit
				CALL contra_credit(p_cmpy, 
				p_whom, 
				l_rec_vendor.contra_cust_code, 
				today, 
				l_current_year, 
				l_current_period, 
				p_glparms.clear_acct_code, 
				0 - l_rec_cheque.contra_amt) 
				RETURNING l_call_status, 
				l_db_status, 
				l_err_message, 
				l_tran_num 

		END CASE 

		IF l_call_status = -2 THEN 
			LET status = l_db_status 
			GOTO ret_status 
		END IF 

		IF l_call_status = -1 THEN 
			RETURN -1, 0, l_err_message, 0 
		END IF 
	END IF 

	# IF the cheque has been posted, create a General Journal TO
	# reverse the deduction FROM the bank account (including contra
	# adjustment posting IF applicable).  IF there was discount,
	# create another General Journal FOR that reversal also
	#
	IF l_rec_cheque.post_flag = "Y" THEN 
		INITIALIZE l_rec_vendortype.* TO NULL 
		SELECT * INTO l_rec_vendortype.* FROM vendortype 
		WHERE cmpy_code = p_cmpy 
		AND type_code = l_rec_vendor.type_code 

		#
		# Check control AND discount accounts AND IF NULL, use defaults
		# FROM apparms
		#
		IF l_rec_vendortype.pay_acct_code IS NULL THEN 
			LET l_rec_vendortype.pay_acct_code = l_rc_apparms.pay_acct_code 
		END IF 
		IF l_rec_vendortype.disc_acct_code IS NULL THEN 
			LET l_rec_vendortype.disc_acct_code = l_rc_apparms.disc_acct_code 
		END IF 

		#
		# IF the conversion rate IS corrupt, do NOT continue with
		# cancellation
		#
		IF l_rec_cheque.conv_qty = 0 OR l_rec_cheque.conv_qty IS NULL THEN 
			LET l_err_message = "Cancel Payment - invalid exchange rate" 
			RETURN -1,0,l_err_message,0 
		END IF 

		#
		# Set up batch header details
		#
		INITIALIZE l_rec_batchhead.* TO NULL 
		LET p_glparms.next_jour_num = p_glparms.next_jour_num + 1 
		LET l_rec_batchhead.cmpy_code = p_cmpy 
		LET l_rec_batchhead.jour_code = l_rc_apparms.chq_jour_code 
		LET l_rec_batchhead.jour_num = p_glparms.next_jour_num 
		LET l_chq_jour_num = l_rec_batchhead.jour_num 
		LET l_rec_batchhead.entry_code = "AP" 
		LET l_rec_batchhead.jour_date = today 
		LET l_rec_batchhead.year_num = l_current_year 
		LET l_rec_batchhead.period_num = l_current_period 
		LET l_rec_batchhead.control_amt = 0 
		LET l_rec_batchhead.debit_amt = 0 
		LET l_rec_batchhead.credit_amt = 0 
		LET l_rec_batchhead.control_qty = 0 
		LET l_rec_batchhead.stats_qty = 0 

		IF p_glparms.use_currency_flag = "N" THEN 
			LET l_rec_batchhead.currency_code = p_glparms.base_currency_code 
			LET l_rec_batchhead.conv_qty = 1 
			LET l_rec_batchhead.rate_type_ind = " " 
		ELSE 
			LET l_rec_batchhead.currency_code = l_rec_cheque.currency_code 
			LET l_rec_batchhead.conv_qty = l_rec_cheque.conv_qty 
			LET l_rec_batchhead.rate_type_ind = "B" 
		END IF 

		LET l_rec_batchhead.for_debit_amt = 0 
		LET l_rec_batchhead.for_credit_amt = 0 
		LET l_rec_batchhead.source_ind = "P" 
		LET l_rec_batchhead.post_flag = "N" 
		LET l_rec_batchhead.seq_num = 0 
		LET l_rec_batchhead.com1_text = "Payment cancellation" 

		IF p_glparms.use_clear_flag = "Y" THEN 
			LET l_rec_batchhead.cleared_flag = "N" 
		ELSE 
			LET l_rec_batchhead.cleared_flag = "Y" 
		END IF 

		LET l_rec_batchhead.post_run_num = 0 
		LET l_rec_batchhead.consol_num = 0 

		#
		# Set up detail line FOR payment reversal
		#
		CALL check_coa(p_cmpy, l_rec_cheque.bank_acct_code,	l_current_year, l_current_period)	RETURNING l_rec_coa.* 
		
		IF l_rec_coa.acct_code IS NULL THEN # NOT found OR NOT OPEN 
			LET l_err_message = "Cancel Payment - bank GL account ", 
			l_rec_cheque.bank_acct_code clipped, " NOT OPEN" 
			RETURN -1,0,l_err_message,0 
		END IF 

		INITIALIZE l_rec_batchdetl.* TO NULL 

		LET l_rec_batchdetl.cmpy_code = l_rec_batchhead.cmpy_code 
		LET l_rec_batchdetl.jour_code = l_rec_batchhead.jour_code 
		LET l_rec_batchdetl.jour_num = l_rec_batchhead.jour_num 
		LET l_rec_batchhead.seq_num = l_rec_batchhead.seq_num + 1 
		LET l_rec_batchdetl.seq_num = l_rec_batchhead.seq_num 
		LET l_rec_batchdetl.tran_type_ind = "CH" 
		LET l_rec_batchdetl.analysis_text = NULL 
		LET l_rec_batchdetl.tran_date = l_rec_batchhead.jour_date 
		LET l_rec_batchdetl.ref_text = l_rec_cheque.vend_code 
		LET l_rec_batchdetl.ref_num = l_rec_cheque.cheq_code 
		LET l_rec_batchdetl.acct_code = l_rec_cheque.bank_acct_code 
		LET l_rec_batchdetl.desc_text = 
		"1 ", l_rec_cheque.cheq_code USING "<<<<<<<<<", " cancelled " 
		LET l_rec_batchdetl.stats_qty = 0 
		#
		# IF multi-currency GL NOT in use, whole batch IS in base
		# currency, OTHERWISE batch IS in currency of cheque
		#
		LET l_rec_batchdetl.debit_amt = 
		l_rec_cheque.net_pay_amt/l_rec_cheque.conv_qty 
		IF p_glparms.use_currency_flag = "N" THEN 
			LET l_rec_batchdetl.for_debit_amt = l_rec_batchdetl.debit_amt 
		ELSE 
			LET l_rec_batchdetl.for_debit_amt = l_rec_cheque.net_pay_amt 
		END IF 

		LET l_rec_batchdetl.credit_amt = 0 
		LET l_rec_batchdetl.for_credit_amt = 0 
		LET l_rec_batchdetl.currency_code = l_rec_batchhead.currency_code 
		LET l_rec_batchdetl.conv_qty = l_rec_batchhead.conv_qty 
		LET l_rec_batchdetl.stats_qty = 0 
		LET l_err_message="Cancel Payment - Inserting Batch details (1)" 

		INSERT INTO batchdetl VALUES (l_rec_batchdetl.*) 

		LET l_rec_batchhead.debit_amt = l_rec_batchhead.debit_amt +	l_rec_batchdetl.debit_amt 
		LET l_rec_batchhead.for_debit_amt = l_rec_batchhead.for_debit_amt +	l_rec_batchdetl.for_debit_amt 

		#
		# Set up detail line FOR contra reversal IF applicable
		#
		IF l_rec_cheque.contra_amt != 0 THEN 
			CALL check_coa(p_cmpy, p_glparms.clear_acct_code,		l_current_year, l_current_period)	RETURNING l_rec_coa.* 

			IF l_rec_coa.acct_code IS NULL THEN # NOT found OR NOT OPEN 
				LET l_err_message = "Cancel Payment - Contra GL account ",p_glparms.clear_acct_code clipped, " NOT OPEN" 
				RETURN -1,0,l_err_message,0 
			END IF 
			
			LET l_rec_batchhead.seq_num = l_rec_batchhead.seq_num + 1 
			LET l_rec_batchdetl.seq_num = l_rec_batchhead.seq_num 
			LET l_rec_batchdetl.tran_type_ind = "CCO" 
			LET l_rec_batchdetl.acct_code = p_glparms.clear_acct_code 
			LET l_rec_batchdetl.desc_text = 
			"1 ", l_rec_cheque.cheq_code USING "<<<<<<<<<", " contra cancelled " 

			#
			# IF multi-currency GL NOT in use, whole batch IS in base
			# currency, OTHERWISE batch IS in currency of cheque
			#
			LET l_rec_batchdetl.debit_amt =	l_rec_cheque.contra_amt/l_rec_cheque.conv_qty 

			IF p_glparms.use_currency_flag = "N" THEN 
				LET l_rec_batchdetl.for_debit_amt = l_rec_batchdetl.debit_amt 
			ELSE 
				LET l_rec_batchdetl.for_debit_amt = l_rec_cheque.contra_amt 
			END IF 

			#
			# Contra payments may be negative, in which CASE switch FROM
			# debit TO credit
			#
			IF l_rec_batchdetl.debit_amt < 0 THEN 
				LET l_rec_batchdetl.credit_amt = l_rec_batchdetl.debit_amt 
				LET l_rec_batchdetl.for_credit_amt = l_rec_batchdetl.for_debit_amt 
				LET l_rec_batchdetl.debit_amt = 0 
				LET l_rec_batchdetl.for_debit_amt = 0 
			ELSE 
				LET l_rec_batchdetl.credit_amt = 0 
				LET l_rec_batchdetl.for_credit_amt = 0 
			END IF 

			LET l_err_message="Cancel Payment - Inserting Batch details (2)" 

			INSERT INTO batchdetl VALUES (l_rec_batchdetl.*) 

			LET l_rec_batchhead.debit_amt = l_rec_batchhead.debit_amt +	l_rec_batchdetl.debit_amt 
			LET l_rec_batchhead.for_debit_amt = l_rec_batchhead.for_debit_amt +	l_rec_batchdetl.for_debit_amt 
			LET l_rec_batchhead.credit_amt = l_rec_batchhead.credit_amt + l_rec_batchdetl.credit_amt 
			LET l_rec_batchhead.for_credit_amt = l_rec_batchhead.for_credit_amt +	l_rec_batchdetl.for_credit_amt 
		END IF 
		
		#
		# Set up detail line FOR Control account balancing - only
		# required IF debits do NOT already equal credits
		#
		IF l_rec_batchhead.for_debit_amt <> l_rec_batchhead.for_credit_amt THEN 
			CALL check_coa(p_cmpy, l_rec_vendortype.pay_acct_code,l_current_year, l_current_period)	RETURNING l_rec_coa.* 
			IF l_rec_coa.acct_code IS NULL THEN # NOT found OR NOT OPEN 
				LET l_err_message = "Cancel Payment - Control GL account ", l_rec_vendortype.pay_acct_code clipped, " NOT OPEN" 
				RETURN -1,0,l_err_message,0 
			END IF 
			
			LET l_rec_batchhead.seq_num = l_rec_batchhead.seq_num + 1 
			LET l_rec_batchdetl.seq_num = l_rec_batchhead.seq_num 
			LET l_rec_batchdetl.ref_num = 0 
			LET l_rec_batchdetl.ref_text = NULL 
			LET l_rec_batchdetl.acct_code = l_rec_vendortype.pay_acct_code 
			LET l_rec_batchdetl.desc_text =	"1 ", l_rec_cheque.cheq_code USING "<<<<<<<<<", " cancelled " 

			#
			# Balancing entry equals difference between debits & credits
			#
			IF l_rec_batchhead.for_debit_amt > l_rec_batchhead.for_credit_amt THEN 
				LET l_rec_batchdetl.credit_amt = l_rec_batchhead.debit_amt - l_rec_batchhead.credit_amt 
				LET l_rec_batchdetl.for_credit_amt = l_rec_batchhead.for_debit_amt - l_rec_batchhead.for_credit_amt 
				LET l_rec_batchdetl.debit_amt = 0 
				LET l_rec_batchdetl.for_debit_amt = 0 
			ELSE 
				LET l_rec_batchdetl.debit_amt = l_rec_batchhead.credit_amt - l_rec_batchhead.debit_amt 
				LET l_rec_batchdetl.for_debit_amt = l_rec_batchhead.for_credit_amt - l_rec_batchhead.for_debit_amt 
				LET l_rec_batchdetl.credit_amt = 0 
				LET l_rec_batchdetl.for_credit_amt = 0 
			END IF 
			
			LET l_err_message="Cancel Payment - Inserting Batch details (3)"
			 
			INSERT INTO batchdetl VALUES (l_rec_batchdetl.*)
			 
			LET l_rec_batchhead.debit_amt = l_rec_batchhead.debit_amt +	l_rec_batchdetl.debit_amt 
			LET l_rec_batchhead.for_debit_amt = l_rec_batchhead.for_debit_amt +	l_rec_batchdetl.for_debit_amt 
			LET l_rec_batchhead.credit_amt = l_rec_batchhead.credit_amt + l_rec_batchdetl.credit_amt 
			LET l_rec_batchhead.for_credit_amt = l_rec_batchhead.for_credit_amt +	l_rec_batchdetl.for_credit_amt 
		END IF 
		
		LET l_rec_batchhead.control_amt = l_rec_batchhead.for_debit_amt 
		LET l_rec_batchhead.control_qty = l_rec_batchhead.stats_qty 
		LET l_err_message="Cancel Payment - Inserting Batch header (1)" 
		CALL fgl_winmessage("1 Learning batch head codes - tell Hubert",l_rec_batchhead.source_ind,"info") 
		
		INSERT INTO batchhead VALUES (l_rec_batchhead.*) 
		
		#
		# Set up batch header details FOR discount reversal, IF applicable
		#
		IF l_rec_cheque.disc_amt <> 0 THEN 
			LET p_glparms.next_jour_num = p_glparms.next_jour_num + 1 
			LET l_rec_batchhead.jour_code = l_rc_apparms.pur_jour_code 
			LET l_rec_batchhead.jour_num = p_glparms.next_jour_num 
			LET l_rec_batchhead.control_amt = 0 
			LET l_rec_batchhead.debit_amt = 0 
			LET l_rec_batchhead.credit_amt = 0 
			LET l_rec_batchhead.control_qty = 0 
			LET l_rec_batchhead.stats_qty = 0 
			LET l_rec_batchhead.for_debit_amt = 0 
			LET l_rec_batchhead.for_credit_amt = 0 
			LET l_rec_batchhead.seq_num = 0 
			LET l_rec_batchhead.com1_text = "Payment discount cancellation" 

			#
			# Set up detail line FOR discount reversal
			#
			CALL check_coa(p_cmpy, l_rec_vendortype.disc_acct_code,	l_current_year, l_current_period)	RETURNING l_rec_coa.* 
			IF l_rec_coa.acct_code IS NULL THEN # NOT found OR NOT OPEN 
				LET l_err_message = "Cancel Payment - discount GL account ", l_rec_vendortype.disc_acct_code clipped, " NOT OPEN" 
				RETURN -1,0,l_err_message,0 
			END IF 
			
			LET l_rec_batchdetl.jour_code = l_rec_batchhead.jour_code 
			LET l_rec_batchdetl.jour_num = l_rec_batchhead.jour_num 
			LET l_rec_batchhead.seq_num = l_rec_batchhead.seq_num + 1 
			LET l_rec_batchdetl.seq_num = l_rec_batchhead.seq_num 
			LET l_rec_batchdetl.tran_type_ind = "CH" 
			LET l_rec_batchdetl.ref_text = l_rec_cheque.vend_code 
			LET l_rec_batchdetl.ref_num = l_rec_cheque.cheq_code 
			LET l_rec_batchdetl.acct_code = l_rec_vendortype.disc_acct_code 
			LET l_rec_batchdetl.desc_text =	"1 ", l_rec_cheque.cheq_code USING "<<<<<<<<<", " discount cancelled " 

			#
			# IF multi-currency GL NOT in use, whole batch IS in base
			# currency, OTHERWISE batch IS in currency of cheque
			#
			LET l_rec_batchdetl.debit_amt = l_rec_cheque.disc_amt/l_rec_cheque.conv_qty 

			IF p_glparms.use_currency_flag = "N" THEN 
				LET l_rec_batchdetl.for_debit_amt = l_rec_batchdetl.debit_amt 
			ELSE 
				LET l_rec_batchdetl.for_debit_amt = l_rec_cheque.disc_amt 
			END IF 

			LET l_rec_batchdetl.credit_amt = 0 
			LET l_rec_batchdetl.for_credit_amt = 0 
			LET l_err_message="Cancel Payment - Inserting Batch details (4)" 

			INSERT INTO batchdetl VALUES (l_rec_batchdetl.*) 

			LET l_rec_batchhead.debit_amt = l_rec_batchdetl.debit_amt 
			LET l_rec_batchhead.for_debit_amt = l_rec_batchdetl.for_debit_amt 
			LET l_rec_batchhead.seq_num = l_rec_batchhead.seq_num + 1 
			LET l_rec_batchdetl.seq_num = l_rec_batchhead.seq_num 
			LET l_rec_batchdetl.ref_num = 0 
			LET l_rec_batchdetl.acct_code = l_rec_vendortype.pay_acct_code 
			LET l_rec_batchdetl.desc_text = 
			"1 ", l_rec_cheque.cheq_code USING "<<<<<<<<<", " cancelled " 
			#
			# Balancing entry IS equal TO discount entry but opposite sign
			#
			LET l_rec_batchdetl.credit_amt = l_rec_batchdetl.debit_amt 
			LET l_rec_batchdetl.for_credit_amt = l_rec_batchdetl.for_debit_amt 
			LET l_rec_batchdetl.debit_amt = 0 
			LET l_rec_batchdetl.for_debit_amt = 0 
			LET l_err_message="Cancel Payment - Inserting Batch details (5)" 

			INSERT INTO batchdetl VALUES (l_rec_batchdetl.*) 

			LET l_rec_batchhead.credit_amt = l_rec_batchdetl.credit_amt 
			LET l_rec_batchhead.for_credit_amt = l_rec_batchdetl.for_credit_amt 
			LET l_rec_batchhead.control_amt = l_rec_batchhead.for_debit_amt 
			LET l_rec_batchhead.control_qty = l_rec_batchhead.stats_qty 
			LET l_err_message="Cancel Payment - Inserting Batch header (2)" 

			CALL fgl_winmessage("2 Learning batch head codes - tell Hubert",l_rec_batchhead.source_ind,"info") 
			INSERT INTO batchhead VALUES (l_rec_batchhead.*) 
		END IF 

		#
		# IF the cheque has been posted AND withholding tax applies,
		# the tax amount must be reversed by creating a debit FOR a positive tax
		# amount OR a voucher FOR a negative tax amount.  A cross-reference IS
		# created between the cancelled cheque AND the adjustment transaction
		# AND the original posting cross-reference updated TO point TO the
		# cancel cheque entry as the original cheque IS now deleted
		#
		IF l_rec_cheque.withhold_tax_ind != "0" THEN 
			SELECT unique 1 
			FROM vendor 
			WHERE cmpy_code = p_cmpy 
			AND vend_code = l_rec_vendortype.tax_vend_code 
			IF status = notfound THEN 
				LET l_err_message = "Cancel Payment - Tax Vendor ",	l_rec_vendortype.tax_vend_code, " NOT found"		#9118 Tax vendor NOT found - cancel NOT allowed"
				RETURN -1,0,l_err_message,0 
			END IF
			 
			IF l_rec_cheque.tax_amt != 0 THEN 
				LET l_tax_adj_amt = 0 - l_rec_cheque.tax_amt 
			
				IF l_rec_cheque.tax_amt < 0 THEN 
					LET l_err_message = "Cancel Payment - Tax Voucher creation" 
					LET l_rec_wholdtax.tax_tran_type = "1" #voucher 
					LET l_rec_wholdtax.tax_ref_num = create_tax_voucher(
						p_cmpy, 
						p_whom, 
						l_rec_vendortype.tax_vend_code, 
						l_tax_adj_amt, 
						l_rec_vendortype.pay_acct_code, 
						l_current_year, 
						l_current_period) 
				ELSE 
					LET l_err_message = "Cancel Payment - Tax Debit creation" 
					LET l_rec_wholdtax.tax_tran_type = "2" #debit 
					LET l_rec_wholdtax.tax_ref_num = create_tax_debit(
						p_cmpy, 
						p_whom, 
						l_rec_vendortype.tax_vend_code, 
						l_tax_adj_amt, 
						l_rec_vendortype.pay_acct_code, 
						l_current_year, 
						l_current_period) 
				END IF 

				IF l_rec_wholdtax.tax_ref_num IS NULL THEN 
					LET l_err_message = "Cancel Payment - cannot create tax adjustment" 
					RETURN -1,0,l_err_message,0 
				END IF 

				LET l_rec_wholdtax.cmpy_code = p_cmpy 
				LET l_rec_wholdtax.payee_tran_type = "2" #cancel cheque 
				LET l_rec_wholdtax.payee_vend_code = l_rec_cheque.vend_code 
				LET l_rec_wholdtax.payee_ref_num = l_rec_cheque.cheq_code 
				LET l_rec_wholdtax.payee_bank_code = l_rec_cheque.bank_code 
				LET l_rec_wholdtax.pay_meth_ind = l_rec_cheque.pay_meth_ind 
				LET l_err_message = "Cancel Payment - wholdtax INSERT" 

				INSERT INTO wholdtax VALUES (l_rec_wholdtax.*) 
			END IF 

			UPDATE wholdtax 
			SET payee_tran_type = "2", 
			payee_ref_num = l_rec_cheque.cheq_code 
			WHERE cmpy_code = p_cmpy 
			AND payee_tran_type = "1" 
			AND payee_vend_code = l_rec_cheque.vend_code 
			AND payee_ref_num = l_rec_cheque.cheq_code 
			AND payee_bank_code = l_rec_cheque.bank_code 
			AND pay_meth_ind = l_rec_cheque.pay_meth_ind 
		END IF 
	END IF 

	#
	# Now transfer details TO cancelcheq table
	#

	LET l_rec_cancelcheq.cmpy_code = p_cmpy 
	LET l_rec_cancelcheq.vend_code = l_rec_cheque.vend_code 
	LET l_rec_cancelcheq.bank_code = l_rec_cheque.bank_code 
	LET l_rec_cancelcheq.cheq_code = l_rec_cheque.cheq_code 
	LET l_rec_cancelcheq.bank_acct_code = l_rec_cheque.bank_acct_code 
	LET l_rec_cancelcheq.entry_code = p_whom 
	LET l_rec_cancelcheq.entry_date = today 
	LET l_rec_cancelcheq.orig_posted_flag = l_rec_cheque.post_flag 
	LET l_rec_cancelcheq.orig_year_num = l_rec_cheque.year_num 
	LET l_rec_cancelcheq.orig_period_num = l_rec_cheque.period_num 
	LET l_rec_cancelcheq.cheq_date = l_rec_cheque.cheq_date 
	LET l_rec_cancelcheq.pay_amt = l_rec_cheque.pay_amt 

	IF l_rec_cheque.post_flag = "Y" THEN 
		LET l_rec_cancelcheq.cancel_year_num = l_current_year 
		LET l_rec_cancelcheq.cancel_period_num = l_current_period 
		LET l_rec_cancelcheq.cancel_jour_num = l_chq_jour_num 
	ELSE 
		LET l_rec_cancelcheq.cancel_year_num = l_rec_cheque.year_num 
		LET l_rec_cancelcheq.cancel_period_num = l_rec_cheque.period_num 
		LET l_rec_cancelcheq.cancel_jour_num = 0 
	END IF 

	LET l_rec_cancelcheq.com1_text = p_com1_text 
	LET l_rec_cancelcheq.com2_text = p_com2_text 
	LET l_rec_cancelcheq.orig_curr_code = l_rec_cheque.currency_code 
	LET l_rec_cancelcheq.orig_conv_qty = l_rec_cheque.conv_qty 
	LET l_rec_cancelcheq.withhold_tax_ind = l_rec_cheque.withhold_tax_ind 
	LET l_rec_cancelcheq.net_pay_amt = l_rec_cheque.net_pay_amt 
	LET l_rec_cancelcheq.tax_code = l_rec_cheque.tax_code 
	LET l_rec_cancelcheq.tax_per = l_rec_cheque.tax_per 
	LET l_rec_cancelcheq.source_ind = l_rec_cheque.source_ind 
	LET l_rec_cancelcheq.source_text = l_rec_cheque.source_text 
	LET l_rec_cancelcheq.tax_amt = l_rec_cheque.tax_amt 
	LET l_rec_cancelcheq.contra_amt = l_rec_cheque.contra_amt 
	LET l_rec_cancelcheq.contra_trans_num = l_rec_cheque.contra_trans_num 
	LET l_rec_cancelcheq.whtax_rep_ind = l_rec_cheque.whtax_rep_ind 
	LET l_rec_cancelcheq.orig_doc_num = l_rec_cheque.doc_num 

	INSERT INTO cancelcheq 
	VALUES (l_rec_cancelcheq.*) 

	DELETE FROM cheque 
	WHERE cmpy_code = p_cmpy 
	AND bank_code = p_bank_code 
	AND cheq_code = p_cheq_code 
	AND pay_meth_ind = p_pay_meth_ind 

	RETURN 0, 0, l_err_message, p_glparms.next_jour_num 
END FUNCTION 
###########################################################################
# FUNCTION cancel_payment
###########################################################################
