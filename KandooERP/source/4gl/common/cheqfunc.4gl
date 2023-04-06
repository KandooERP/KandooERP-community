{
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

	Source code beautified by beautify.pl on 2020-01-02 10:35:07	$Id: $
}



#
#  module cheqfunc - common routines FOR cheque transactions
#


GLOBALS "../common/glob_GLOBALS.4gl" 
#
# FUNCTION init_cheque
#
# This routine sets up the initial cheque VALUES based on the
# vendor AND transaction date details AND returns the initialised
# record.
# NOTE: The cheque year AND period are initialised using the
# version of "what_period" that does NOT DISPLAY error MESSAGEs.
# The VALUES of year AND period should be checked AFTER calling
# the routine, TO ensure that they are NOT NULL.
#
# Parameters: p_cmpy_code      = the company code FOR the vendor
#           : p_whom           = the user sign on code
#           : p_vend_code      = the vendor code
#           : p_tran_date      = the transaction date
#           : p_base_curr_code = the base currency code FROM gl parms
#
# Returns   : CALL STATUS      = TRUE IF successful, FALSE if
#                                application error
#           : r_rec_cheque.*     = initialised voucher record
#           : err_msg          = error MESSAGE IF applicable

FUNCTION init_cheque(p_cmpy_code,p_whom,p_vend_code,p_cheq_code,p_tran_date,p_bank_code,p_base_curr_code) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_whom LIKE kandoouser.sign_on_code 
	DEFINE p_vend_code LIKE vendor.vend_code 
	DEFINE p_cheq_code LIKE cheque.cheq_code 
	DEFINE p_tran_date LIKE cheque.cheq_date 
	DEFINE p_bank_code LIKE bank.bank_code 
	DEFINE p_base_curr_code LIKE glparms.base_currency_code 
	DEFINE l_rec_bank RECORD LIKE bank.* 
 	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE r_rec_cheque RECORD LIKE cheque.*
	DEFINE r_error_msg CHAR(60) 

	INITIALIZE r_rec_cheque.* TO NULL 
	SELECT * INTO l_rec_vendor.* 
	FROM vendor 
	WHERE vend_code = p_vend_code 
	AND cmpy_code = p_cmpy_code 
	IF STATUS = NOTFOUND THEN 
		LET r_error_msg = "Logic Error: Vendor ", p_vend_code clipped, 
		" NOT found" 
		RETURN FALSE, r_rec_cheque.*, r_error_msg 
	END IF 
	SELECT * INTO l_rec_bank.* 
	FROM bank 
	WHERE bank_code = p_bank_code 
	AND cmpy_code = p_cmpy_code 
	IF STATUS = NOTFOUND THEN 
		LET r_error_msg = "Logic Error: Bank ", p_bank_code clipped, 
		" NOT found" 
		RETURN FALSE, r_rec_cheque.*, r_error_msg 
	END IF 
	CALL get_fiscal_year_period_for_date(p_cmpy_code, p_tran_date) 
	RETURNING r_rec_cheque.year_num, r_rec_cheque.period_num 
	IF r_rec_cheque.year_num IS NULL OR r_rec_cheque.period_num IS NULL THEN 
		LET r_error_msg = "Year AND period NOT SET up FOR ", 
		p_tran_date USING "dd/mm/yyyy" 
		RETURN FALSE, r_rec_cheque.*, r_error_msg 
	END IF 
	LET r_rec_cheque.cmpy_code = p_cmpy_code 
	LET r_rec_cheque.vend_code = p_vend_code 
	LET r_rec_cheque.cheq_code = p_cheq_code 
	LET r_rec_cheque.bank_acct_code = l_rec_bank.acct_code 
	LET r_rec_cheque.entry_code = p_whom 
	LET r_rec_cheque.entry_date = today 
	LET r_rec_cheque.cheq_date = p_tran_date 
	LET r_rec_cheque.pay_amt = 0 
	LET r_rec_cheque.apply_amt = 0 
	LET r_rec_cheque.disc_amt = 0 
	LET r_rec_cheque.hist_flag = 'N' 
	LET r_rec_cheque.post_flag = 'N' 
	LET r_rec_cheque.next_appl_num = 0 
	LET r_rec_cheque.currency_code = l_rec_vendor.currency_code 
	IF l_rec_vendor.currency_code = p_base_curr_code THEN 
		LET r_rec_cheque.conv_qty = 1.0 
	ELSE 
		CALL get_conv_rate(p_cmpy_code,r_rec_cheque.currency_code,r_rec_cheque.cheq_date,CASH_EXCHANGE_BUY) 
		RETURNING r_rec_cheque.conv_qty 
	END IF
	 
	LET r_rec_cheque.bank_code = l_rec_bank.bank_code 
	LET r_rec_cheque.bank_currency_code = l_rec_bank.currency_code 
	LET r_rec_cheque.net_pay_amt = 0 
	CALL get_whold_tax(r_rec_cheque.cmpy_code, r_rec_cheque.vend_code, l_rec_vendor.type_code) 
	RETURNING 
		r_rec_cheque.withhold_tax_ind, 
		r_rec_cheque.tax_code, 
		r_rec_cheque.tax_per 
	
	LET r_rec_cheque.pay_meth_ind = l_rec_vendor.pay_meth_ind 
	LET r_rec_cheque.eft_run_num = 0 
	LET r_rec_cheque.doc_num = 0 
	LET r_rec_cheque.tax_amt = 0 
	LET r_rec_cheque.contra_amt = 0 
	LET r_rec_cheque.contra_trans_num = 0 
	LET r_rec_cheque.source_ind = "1" 
	LET r_rec_cheque.source_text = l_rec_vendor.vend_code 
	LET r_rec_cheque.whtax_rep_ind = r_rec_cheque.withhold_tax_ind 

	RETURN TRUE, r_rec_cheque.*, r_error_msg 
END FUNCTION 
#
# FUNCTION ins_chq_apaudit
#
# This routine inserts all the apaudit records associated with a given
# payment (cheque) record, with the exception of the discount audit
# record. These are inserted separately WHEN the payment IS applied.
#
# Parameters: p_cheque.*      = the cheque RECORD FOR which payment
#                                audit records are being inserted
#           : p_curr_seq_num  = the current value of the next sequence
#                                number field on the vendor record
#           : pr_curr_bal_amt  = the current value of the vendor balance
#           : pr_rev_ind       = "0" IF the cheque IS being inserted
#                              = "1" IF the cheque IS being edited
#                              = "2" IF the cheque IS being reversed
#                                    FOR edit purposes
#                              = "3" IF the cheque IS being reversed
#                                    FOR cancellation
#
# Returns   : CALL STATUS      = 0 IF successful, -1 IF application
#                                error, -2 IF database error (including
#                                locks)
#           : database STATUS  = the STATUS that caused the "whenever
#                                error" procedure TO be invoked, FOR
#                                CALL STATUS of -2 only
#           : error MESSAGE    = an error MESSAGE indicating the source
#                                of the database OR application error
#           : l_rec_apaudit.seq_num = the last used sequence number FOR
#                                  the audit records
#           : l_rec_apaudit.bal_amt = the resulting vendor balance
#
FUNCTION ins_chq_apaudit(p_cheque,p_curr_seq_num,p_curr_bal_amt,p_rev_ind) 
	DEFINE p_cheque RECORD LIKE cheque.* 
	DEFINE p_curr_seq_num LIKE vendor.next_seq_num
	DEFINE p_curr_bal_amt LIKE vendor.bal_amt 
	DEFINE p_rev_ind CHAR(1) 
	DEFINE l_rec_apaudit RECORD LIKE apaudit.* 
	DEFINE l_err_message CHAR(80) 

	GOTO bypass 
	LABEL ret_status: 
	RETURN -2, STATUS, l_err_message, 0, 0 
	LABEL bypass: 
	WHENEVER ERROR GOTO ret_status 

	# Initialise audit RECORD fields
	INITIALIZE l_rec_apaudit.* TO NULL 
	LET l_rec_apaudit.cmpy_code = p_cheque.cmpy_code 
	LET l_rec_apaudit.tran_date = p_cheque.cheq_date 
	LET l_rec_apaudit.vend_code = p_cheque.vend_code 
	LET l_rec_apaudit.year_num = p_cheque.year_num 
	LET l_rec_apaudit.period_num = p_cheque.period_num 
	LET l_rec_apaudit.trantype_ind = "CH" 
	LET l_rec_apaudit.source_num = p_cheque.cheq_code 
	LET l_rec_apaudit.entry_code = p_cheque.entry_code 
	LET l_rec_apaudit.currency_code = p_cheque.currency_code 
	LET l_rec_apaudit.conv_qty = p_cheque.conv_qty 
	LET l_rec_apaudit.entry_date = today 
	#
	# Set up initial VALUES of sequence number AND balance FROM
	# current vendor RECORD VALUES.  Subsequent audit records add TO
	# (OR subtract FROM) these VALUES.
	#
	LET l_rec_apaudit.seq_num = p_curr_seq_num 
	LET l_rec_apaudit.bal_amt = p_curr_bal_amt 
	#
	# Audit RECORD FOR the payment amount - positive IF reversal
	#
	LET l_rec_apaudit.tran_amt = 0 - p_cheque.net_pay_amt 
	LET l_rec_apaudit.tran_text = "Cheque Amount" 
	CASE (p_rev_ind) 
		WHEN "1" 
			LET l_rec_apaudit.tran_text = "Edit Cheque Amt" 
		WHEN "2" 
			LET l_rec_apaudit.tran_amt = p_cheque.net_pay_amt 
			LET l_rec_apaudit.tran_text = "Backout Chq Amt" 
		WHEN "3" 
			LET l_rec_apaudit.tran_amt = p_cheque.net_pay_amt 
			LET l_rec_apaudit.tran_text = "Cancel Chq Amt" 
	END CASE 
	LET l_rec_apaudit.seq_num = l_rec_apaudit.seq_num + 1 
	LET l_rec_apaudit.bal_amt = l_rec_apaudit.bal_amt + l_rec_apaudit.tran_amt 
	LET l_err_message = "ins_chq_apaudit - INSERT INTO apaudit (1)" 
	INSERT INTO apaudit VALUES (l_rec_apaudit.*) 
	#
	# Audit RECORD FOR the tax amount, IF required
	#
	IF p_cheque.tax_amt > 0 THEN 
		LET l_rec_apaudit.tran_amt = 0 - p_cheque.tax_amt 
		LET l_rec_apaudit.tran_text = "Cheque Tax" 
		CASE (p_rev_ind) 
			WHEN "1" 
				LET l_rec_apaudit.tran_text = "Edit Chq Tax" 
			WHEN "2" 
				LET l_rec_apaudit.tran_amt = p_cheque.tax_amt 
				LET l_rec_apaudit.tran_text = "Backout Chq Tax" 
			WHEN "3" 
				LET l_rec_apaudit.tran_amt = p_cheque.tax_amt 
				LET l_rec_apaudit.tran_text = "Cancel Chq Tax" 
		END CASE 
		LET l_rec_apaudit.seq_num = l_rec_apaudit.seq_num + 1 
		LET l_rec_apaudit.bal_amt = l_rec_apaudit.bal_amt + l_rec_apaudit.bal_amt 
		LET l_err_message = "ins_chq_apaudit - INSERT INTO apaudit (2)" 
		INSERT INTO apaudit VALUES (l_rec_apaudit.*) 
	END IF 
	#
	# Audit RECORD FOR the contra amount, IF required
	#
	IF p_cheque.contra_amt <> 0 THEN 
		LET l_rec_apaudit.tran_amt = 0 - p_cheque.contra_amt 
		IF p_cheque.contra_amt > 0 THEN 
			LET l_rec_apaudit.tran_text = "Contra Credit" 
		ELSE 
			LET l_rec_apaudit.tran_text = "Contra Invoice" 
		END IF 
		CASE (p_rev_ind) 
			WHEN "1" 
				LET l_rec_apaudit.tran_text = "Edit Chq Contra" 
			WHEN "2" 
				LET l_rec_apaudit.tran_amt = p_cheque.contra_amt 
				LET l_rec_apaudit.tran_text = "Backout Contra" 
			WHEN "3" 
				LET l_rec_apaudit.tran_amt = p_cheque.contra_amt 
				LET l_rec_apaudit.tran_text = "Cancel Contra" 
		END CASE 
		LET l_rec_apaudit.seq_num = l_rec_apaudit.seq_num + 1 
		LET l_rec_apaudit.bal_amt = l_rec_apaudit.bal_amt + l_rec_apaudit.bal_amt 
		LET l_err_message = "ins_chq_apaudit - INSERT INTO apaudit (3)" 
		INSERT INTO apaudit VALUES (l_rec_apaudit.*) 
	END IF 
	WHENEVER ERROR stop 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	RETURN 0,0,"",l_rec_apaudit.seq_num, l_rec_apaudit.bal_amt 
END FUNCTION 

#
# FUNCTION ins_voucherpays
#
# This routine inserts the voucherpays RECORD FOR a given payment OR
# debit application AND the associated exchange variance AND discount
# audit transaction records.
#
# Parameters: p_rec_voucher.*      = the voucher TO which payment IS being
#                                 applied
#           : p_pay_type_code  = "CH" FOR cheques AND EFT's, "DB" FOR
#                                 debits
#           : p_pay_num        = the unique cheque OR debit number
#           : p_apply_amt      = the amount of the payment OR debit
#                                 applied TO the voucher
#           : p_disc_amt       = the amount of discount taken up in
#                                 this payment OR debit application
#           : p_pay_conv_qty   = the exchange rate of the payment OR
#                                 debit
#           : p_entry_code     = the sign on code of the user applying
#                                 the payment OR debit
#           : p_curr_seq_num   = the current value of the next sequence
#                                 number field on the vendor record
#           : p_curr_bal_amt   = the current value of the vendor
#                                 balance
#           : p_rec_cheque.*       = the cheque RECORD being applied - NULL
#                                 FOR debit applications
#
# Returns   : CALL STATUS      = 0 IF successful, -1 IF application
#                                error, -2 IF database error (including
#                                locks)
#           : database STATUS  = the STATUS that caused the "whenever
#                                error" procedure TO be invoked, FOR
#                                CALL STATUS of -2 only
#           : error MESSAGE    = an error MESSAGE indicating the source
#                                of the database OR application error
#           : p_curr_seq_num   = the last used sequence number FOR
#                                 the audit records
#           : p_curr_bal_amt   = the resulting vendor balance
#
FUNCTION ins_voucherpay(p_rec_voucher,p_pay_type_code,p_pay_num,p_apply_amt,p_disc_amt,p_pay_curr_code,p_pay_conv_qty,p_entry_code,p_curr_seq_num,p_curr_bal_amt,p_rec_cheque) 
	DEFINE p_rec_voucher RECORD LIKE voucher.* 
	DEFINE p_pay_type_code LIKE voucherpays.pay_type_code 
	DEFINE p_pay_num LIKE voucherpays.pay_num 
	DEFINE p_apply_amt LIKE voucherpays.apply_amt 
	DEFINE p_disc_amt LIKE voucherpays.disc_amt 
	DEFINE p_pay_curr_code LIKE cheque.currency_code 
	DEFINE p_pay_conv_qty LIKE cheque.conv_qty 
	DEFINE p_entry_code LIKE kandoouser.sign_on_code 
	DEFINE p_curr_seq_num LIKE vendor.next_seq_num 
	DEFINE p_curr_bal_amt LIKE vendor.bal_amt 
	DEFINE p_rec_cheque RECORD LIKE cheque.* 
	DEFINE l_rec_voucherpays RECORD LIKE voucherpays.* 
	DEFINE l_rec_apaudit RECORD LIKE apaudit.* 
	DEFINE l_curr_year_num LIKE period.year_num 
	DEFINE l_curr_period_num LIKE period.period_num 
	DEFINE l_rec_exchangevar RECORD LIKE exchangevar.* 
	DEFINE l_base_vouch_amt LIKE exchangevar.exchangevar_amt
	DEFINE l_base_pay_amt LIKE exchangevar.exchangevar_amt 
	DEFINE l_err_message CHAR(80) 

	GOTO bypass 
	LABEL ret_status: 
	RETURN -2, STATUS, l_err_message, 0, 0 
	LABEL bypass: 
	WHENEVER ERROR GOTO ret_status 

	#
	# Retrieve current year AND period FOR later use
	#
	CALL db_period_what_period(p_rec_voucher.cmpy_code, today) 
	RETURNING l_curr_year_num, 
	l_curr_period_num 
	#
	# Initialise voucherpays RECORD fields
	#
	INITIALIZE l_rec_voucherpays.* TO NULL 
	#
	# Set up AND INSERT voucherpays details.  Note that certain fields are
	# left NULL IF the application IS a debit, NOT a cheque.
	#
	LET l_rec_voucherpays.cmpy_code = p_rec_voucher.cmpy_code 
	LET l_rec_voucherpays.vend_code = p_rec_voucher.vend_code 
	LET l_rec_voucherpays.vouch_code = p_rec_voucher.vouch_code 
	LET l_rec_voucherpays.seq_num = 0 
	LET l_rec_voucherpays.apply_num = p_rec_voucher.pay_seq_num 
	LET l_rec_voucherpays.pay_date = today 
	LET l_rec_voucherpays.pay_type_code = p_pay_type_code 
	LET l_rec_voucherpays.pay_num = p_pay_num 
	LET l_rec_voucherpays.apply_amt = p_apply_amt 
	LET l_rec_voucherpays.disc_amt = p_disc_amt 
	IF p_pay_type_code = "CH" THEN 
		LET l_rec_voucherpays.pay_meth_ind = p_rec_cheque.pay_meth_ind 
		LET l_rec_voucherpays.withhold_tax_ind = p_rec_cheque.withhold_tax_ind 
		LET l_rec_voucherpays.tax_code = p_rec_cheque.tax_code 
		LET l_rec_voucherpays.bank_code = p_rec_cheque.bank_code 
		LET l_rec_voucherpays.tax_per = p_rec_cheque.tax_per 
		LET l_rec_voucherpays.remit_doc_num = 0 
		LET l_rec_voucherpays.pay_doc_num = p_rec_cheque.doc_num 
	ELSE 
		LET l_rec_voucherpays.withhold_tax_ind = "0" 
		LET l_rec_voucherpays.tax_per = 0 
		LET l_rec_voucherpays.pay_doc_num = 0 
	END IF 
	LET l_err_message = "ins_voucherpay - INSERT of voucherpays" 
	INSERT INTO voucherpays VALUES (l_rec_voucherpays.*) 
	#
	# Set up AND INSERT AND audit RECORD FOR the discount taken, IF any.
	#
	IF p_disc_amt > 0 THEN 
		INITIALIZE l_rec_apaudit.* TO NULL 
		LET l_rec_apaudit.cmpy_code = p_rec_voucher.cmpy_code 
		LET l_rec_apaudit.tran_date = today 
		LET l_rec_apaudit.vend_code = p_rec_voucher.vend_code 
		LET l_rec_apaudit.trantype_ind = p_pay_type_code 
		LET l_rec_apaudit.year_num = l_curr_year_num 
		LET l_rec_apaudit.period_num = l_curr_period_num 
		LET l_rec_apaudit.source_num = p_pay_num 
		LET l_rec_apaudit.entry_code = p_entry_code 
		LET l_rec_apaudit.entry_date = today 
		LET l_rec_apaudit.currency_code = p_pay_curr_code 
		LET l_rec_apaudit.conv_qty = p_pay_conv_qty 
		#
		# Set up initial VALUES of sequence number AND balance FROM
		# current vendor RECORD VALUES.  Subsequent audit records add TO
		# (OR subtract FROM) these VALUES.
		#
		LET p_curr_seq_num = p_curr_seq_num + 1 
		LET l_rec_apaudit.seq_num = p_curr_seq_num 
		LET l_rec_apaudit.tran_amt = 0 - p_disc_amt 
		LET l_rec_apaudit.tran_text = "Apply Discount" 
		LET p_curr_bal_amt = p_curr_bal_amt + l_rec_apaudit.tran_amt 
		LET l_rec_apaudit.bal_amt = p_curr_bal_amt 
		LET l_err_message = "ins_vouchpay - INSERT INTO apaudit FOR discount" 
		INSERT INTO apaudit VALUES (l_rec_apaudit.*) 
	END IF 

	IF p_rec_voucher.conv_qty IS NOT NULL AND 
	p_pay_conv_qty IS NOT NULL AND 
	p_rec_voucher.conv_qty != 0 AND p_pay_conv_qty != 0 THEN 
		LET l_base_vouch_amt = 
		(l_rec_voucherpays.apply_amt + l_rec_voucherpays.disc_amt) 
		/ p_rec_voucher.conv_qty 
		LET l_base_pay_amt = 
		(l_rec_voucherpays.apply_amt + l_rec_voucherpays.disc_amt) 
		/ p_pay_conv_qty 
	END IF 
	LET l_rec_exchangevar.exchangevar_amt = 
	l_base_vouch_amt - l_base_pay_amt 
	IF l_rec_exchangevar.exchangevar_amt != 0 THEN 
		LET l_rec_exchangevar.cmpy_code = p_rec_voucher.cmpy_code 
		LET l_rec_exchangevar.year_num = l_curr_year_num 
		LET l_rec_exchangevar.period_num = l_curr_period_num 
		LET l_rec_exchangevar.source_ind = "P" 
		LET l_rec_exchangevar.tran_date = today 
		LET l_rec_exchangevar.ref_code = p_rec_voucher.vend_code 
		LET l_rec_exchangevar.tran_type1_ind = "VO" 
		LET l_rec_exchangevar.ref1_num = p_rec_voucher.vouch_code 
		LET l_rec_exchangevar.tran_type2_ind = p_pay_type_code 
		IF l_rec_exchangevar.tran_type2_ind = "DB" THEN 
			LET l_rec_exchangevar.tran_type2_ind = "DM" 
		END IF 
		LET l_rec_exchangevar.ref2_num = p_pay_num 
		LET l_rec_exchangevar.currency_code = p_pay_curr_code 
		LET l_rec_exchangevar.posted_flag = "N" 
		LET l_err_message = "ins_vouchpay - INSERT INTO exchangevar" 
		INSERT INTO exchangevar VALUES (l_rec_exchangevar.*) 
	END IF 
	WHENEVER ERROR stop 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	RETURN 0,0,"",p_curr_seq_num, p_curr_bal_amt 

END FUNCTION 


