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

	Source code beautified by beautify.pl on 2020-01-02 10:35:06	$Id: $
}



#
#  module cheqbox - Black box routines FOR cheques transactions
#
GLOBALS "../common/glob_GLOBALS.4gl" 
#
#
##############################################################################
# FUNCTION Name:   cheque_add
# Description:     Used TO add a cheque RECORD AND UPDATE/INSERT
#                  the related records.
# Passed:  (Legend: M=Mandatory O=Optional)
# M pr_cheque      this will be the cheque RECORD FROM the calling FUNCTION
# M pr_verbose     TRUE OR FALSE; whether TO DISPLAY errors interactivily
#                  OR via error logging/silent mode.
# Returned:
#   TRUE/FALSE     FALSE - IF errors encountered; TRUE - no errors encountered
#   r_error_text IS used TO show a brief description of the error found
#                  WHEN adding a cheque details INTO the cheque AND relevant
#                  tables. Specifically 30 chars FOR brief desc AND remainder
#                  describes the 4gl program name.
##############################################################################
FUNCTION cheque_add(p_rec_cheque,p_verbose) 
	DEFINE p_rec_cheque RECORD LIKE cheque.*
	DEFINE p_verbose SMALLINT
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_cheque RECORD LIKE cheque.* 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_apaudit RECORD LIKE apaudit.* 
	DEFINE l_status SMALLINT 
	DEFINE l_update_bank SMALLINT 
	DEFINE l_err_message CHAR(100) 
	DEFINE l_tax_amt LIKE cheque.net_pay_amt 
	DEFINE l_next_num LIKE bank.next_cheque_num 
	DEFINE r_error_text CHAR(40)

	### Verify the cheque does NOT already exist ###
	LET r_error_text = "Cheque Exists - cheqbox" 
	SELECT * INTO l_rec_cheque.* FROM cheque 
	WHERE cheq_code = p_rec_cheque.cheq_code 
	AND bank_acct_code = p_rec_cheque.bank_acct_code 
	AND pay_meth_ind = p_rec_cheque.pay_meth_ind 
	AND cmpy_code = p_rec_cheque.cmpy_code 
	IF status = 0 THEN 
		IF p_verbose THEN 
			CASE l_rec_cheque.pay_meth_ind 
				WHEN "1" LET l_msgresp = kandoomsg("P",9174,l_rec_cheque.cheq_code) 
				WHEN "2" ### do nothing 
				WHEN "3" LET l_msgresp = kandoomsg("P",9175,l_rec_cheque.cheq_code) 
				WHEN "4" ### do nothing 
			END CASE 
		END IF 
		RETURN FALSE, r_error_text 
	END IF 
	### Verify the cheque paying amount ### RETURN Status 3 ###
	LET r_error_text = "Cheque Amount <= 0 - cheqbox" 
	IF not(p_rec_cheque.pay_amt > 0) THEN 
		CASE l_rec_cheque.pay_meth_ind 
			WHEN "1" LET l_msgresp = kandoomsg("P",9011,p_rec_cheque.cheq_code) 
			WHEN "2" ### do nothing 
			WHEN "3" LET l_msgresp = kandoomsg("P",9176,p_rec_cheque.cheq_code) 
			WHEN "4" ### do nothing 
		END CASE 
		RETURN FALSE, r_error_text 
	END IF 
	GOTO bypass 
	LABEL founderror: 
	LET l_status = status 
	LET l_err_message = r_error_text clipped, 
	" - Status = ", l_status USING "<<<<<" 
	CALL errorlog(l_err_message) 
	RETURN FALSE, r_error_text 
	LABEL bypass: 
	WHENEVER ERROR GOTO founderror 
	### Collect the cheque number ###
	LET r_error_text = "Cheque Insert Failed -cheqbox" 
	INSERT INTO cheque VALUES (p_rec_cheque.*) 
	LET r_error_text = "Vendor Locked -cheqbox" 
	DECLARE curr_amts CURSOR FOR 
	SELECT vendor.* 
	FROM vendor 
	WHERE vend_code = p_rec_cheque.vend_code 
	AND cmpy_code = p_rec_cheque.cmpy_code 
	FOR UPDATE 
	LET r_error_text = "Vendor Open Cursor -cheqbox" 
	OPEN curr_amts 
	LET r_error_text = "Vendor Fetch Cursor -cheqbox" 
	FETCH curr_amts INTO l_rec_vendor.* 
	IF p_rec_cheque.cheq_date > l_rec_vendor.last_payment_date 
	OR l_rec_vendor.last_payment_date IS NULL THEN 
		LET l_rec_vendor.last_payment_date = p_rec_cheque.cheq_date 
	END IF 
	LET l_rec_vendor.bal_amt = l_rec_vendor.bal_amt - p_rec_cheque.net_pay_amt 
	LET l_rec_vendor.curr_amt = l_rec_vendor.curr_amt - p_rec_cheque.net_pay_amt 
	LET l_rec_vendor.next_seq_num = l_rec_vendor.next_seq_num + 1 
	CASE p_rec_cheque.pay_meth_ind 
		WHEN "1" LET l_rec_apaudit.tran_text = "Auto Cheque Amt" 
		WHEN "2" LET l_rec_apaudit.tran_text = "Manual Cheque Amt" 
		WHEN "3" LET l_rec_vendor.bkdetls_mod_flag = "N" 
			LET l_rec_apaudit.tran_text = "Auto EFT Amt" 
		WHEN "4" LET l_rec_apaudit.tran_text = "Direct Debit Amt" 
	END CASE 
	LET l_rec_apaudit.trantype_ind = "CH" 
	LET l_rec_apaudit.cmpy_code = p_rec_cheque.cmpy_code 
	LET l_rec_apaudit.tran_date = p_rec_cheque.cheq_date 
	LET l_rec_apaudit.vend_code = p_rec_cheque.vend_code 
	LET l_rec_apaudit.seq_num = l_rec_vendor.next_seq_num 
	LET l_rec_apaudit.year_num = p_rec_cheque.year_num 
	LET l_rec_apaudit.period_num = p_rec_cheque.period_num 
	LET l_rec_apaudit.source_num = p_rec_cheque.cheq_code 
	LET l_rec_apaudit.tran_amt = 0 - p_rec_cheque.net_pay_amt 
	LET l_rec_apaudit.entry_code = p_rec_cheque.entry_code 
	LET l_rec_apaudit.bal_amt = l_rec_vendor.bal_amt 
	LET l_rec_apaudit.currency_code = p_rec_cheque.currency_code 
	LET l_rec_apaudit.conv_qty = p_rec_cheque.conv_qty 
	LET l_rec_apaudit.entry_date = today 
	LET r_error_text = "Aplog Insert Failed(1) -cheqbox" 
	INSERT INTO apaudit VALUES (l_rec_apaudit.*) 
	LET l_tax_amt = p_rec_cheque.pay_amt - p_rec_cheque.net_pay_amt 
	IF l_tax_amt != 0 THEN 
		LET l_rec_vendor.bal_amt = l_rec_vendor.bal_amt - l_tax_amt 
		LET l_rec_vendor.curr_amt = l_rec_vendor.curr_amt - l_tax_amt 
		LET l_rec_vendor.next_seq_num = l_rec_vendor.next_seq_num + 1 
		LET l_rec_apaudit.seq_num = l_rec_vendor.next_seq_num 
		CASE p_rec_cheque.pay_meth_ind 
			WHEN "1" LET l_rec_apaudit.tran_text = "Auto Cheque Tax" 
			WHEN "2" LET l_rec_apaudit.tran_text = "Manual Cheque Tax" 
			WHEN "3" LET l_rec_vendor.bkdetls_mod_flag = "N" 
				LET l_rec_apaudit.tran_text = "Auto EFT Tax" 
			WHEN "4" LET l_rec_apaudit.tran_text = "Direct Debit Tax" 
		END CASE 
		LET l_rec_apaudit.tran_amt = 0 - l_tax_amt 
		LET l_rec_apaudit.bal_amt = l_rec_vendor.bal_amt 
		LET r_error_text = "Aplog Insert Failed(2) -cheqbox" 
		INSERT INTO apaudit VALUES (l_rec_apaudit.*) 
	END IF 

	LET r_error_text = "Vendor Update Failed -cheqbox" 
	UPDATE vendor 
	SET * = l_rec_vendor.* 
	WHERE cmpy_code = p_rec_cheque.cmpy_code 
	AND vend_code = p_rec_cheque.vend_code 

	### Verify IF the cheque number was taken FROM bank RECORD ###
	LET l_update_bank = FALSE 
	LET r_error_text = "Bank SELECT Failed -cheqbox" 
	SELECT next_cheque_num 
	INTO l_next_num 
	FROM bank 
	WHERE acct_code = p_rec_cheque.bank_acct_code 
	AND cmpy_code = p_rec_cheque.cmpy_code 
	IF (l_next_num IS NOT null) THEN 
		IF (l_next_num = p_rec_cheque.cheq_code) THEN 
			LET l_update_bank = true 
		END IF 
	END IF 
	IF (p_rec_cheque.pay_meth_ind = "1") THEN 
		IF (l_update_bank) THEN 
			LET r_error_text = "Bank Update Failed -cheqbox" 
			UPDATE bank 
			SET next_cheque_num = p_rec_cheque.cheq_code + 1 
			WHERE acct_code = p_rec_cheque.bank_acct_code 
			AND cmpy_code = p_rec_cheque.cmpy_code 
		END IF 
		LET r_error_text = "Apparm Update Failed -cheqbox" 
		UPDATE apparms 
		SET last_chq_prnt_date = p_rec_cheque.cheq_date 
		WHERE cmpy_code = p_rec_cheque.cmpy_code 
	END IF 
	WHENEVER ERROR stop 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	LET r_error_text = NULL 
	RETURN true, r_error_text 
END FUNCTION 
#########################################################################
# FUNCTION:        cheque_INITIALIZE
# Description:     Used TO INITIALIZE a cheque RECORD setting up the
#                  default fields.
# Passed: (Legend: M=Mandatory O=Optional)
# M pr_cmpy_code   the default company code
# M pr_whom        the default user login
# M pr_vend_code   the vendor which will be receiving the cheque
# O pr_amount      the amount of the cheque
# Returned:
#   TRUE/FALSE     FALSE - IF errors encountered; TRUE - no errors encountered
#   pr_cheque      new cheque RECORD (with defaults) IF TRUE;
#   r_error_text  IS used TO show a brief description of the error found
#                  WHEN setting up cheque details
#########################################################################
FUNCTION cheque_initialize(p_cmpy_code, p_whom, p_vend_code, p_bank_code, p_amount) 
	DEFINE p_cmpy_code LIKE company.cmpy_code
	DEFINE p_whom LIKE kandoouser.sign_on_code
	DEFINE p_vend_code LIKE vendor.vend_code
	DEFINE p_bank_code LIKE bank.bank_code
	DEFINE p_amount LIKE cheque.pay_amt
	DEFINE l_rec_pr_cheque RECORD LIKE cheque.* 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_glparms RECORD LIKE glparms.* 
	DEFINE l_rec_bank RECORD LIKE bank.* 
	DEFINE r_rec_ps_cheque RECORD LIKE cheque.*
	DEFINE r_error_text CHAR(40) 

	INITIALIZE r_rec_ps_cheque.* TO NULL 
	INITIALIZE l_rec_vendor.* TO NULL 
	SELECT * INTO l_rec_glparms.* FROM glparms 
	WHERE cmpy_code = p_cmpy_code 
	AND key_code = "1" 
	IF status = notfound THEN 
		LET r_error_text = "G.L Details Not Found - cheqbox" 
		RETURN FALSE, r_rec_ps_cheque.*, r_error_text 
	END IF 
	SELECT * INTO l_rec_vendor.* FROM vendor 
	WHERE cmpy_code = p_cmpy_code 
	AND vend_code = p_vend_code 
	IF status = notfound THEN 
		LET r_error_text = "Vendor Details Not Found - cheqbox" 
		RETURN FALSE, r_rec_ps_cheque.*, r_error_text 
	END IF 
	SELECT * INTO l_rec_bank.* FROM bank 
	WHERE cmpy_code = p_cmpy_code 
	AND bank_code = p_bank_code 
	IF status = notfound THEN 
		LET r_error_text = "Bank Details Not Found - cheqbox" 
		RETURN FALSE, l_rec_pr_cheque.*, r_error_text 
	END IF 
	### Since the necessary details have been derived FROM the db  ###
	### fill in all the other relevant fields too.                 ###
	LET r_rec_ps_cheque.cmpy_code = p_cmpy_code 
	LET r_rec_ps_cheque.vend_code = l_rec_vendor.vend_code 
	LET r_rec_ps_cheque.bank_code = l_rec_bank.bank_code 
	LET r_rec_ps_cheque.bank_acct_code = l_rec_bank.acct_code 
	LET r_rec_ps_cheque.bank_currency_code = l_rec_bank.currency_code 
	LET r_rec_ps_cheque.cheq_code = l_rec_bank.next_cheque_num 
	LET r_rec_ps_cheque.entry_code = p_whom 
	LET r_rec_ps_cheque.entry_date = today 
	LET r_rec_ps_cheque.cheq_date = today 
	CALL db_period_what_period(r_rec_ps_cheque.cmpy_code, r_rec_ps_cheque.cheq_date) 
	RETURNING r_rec_ps_cheque.year_num, r_rec_ps_cheque.period_num 
	LET r_rec_ps_cheque.pay_amt = p_amount 
	IF p_amount IS NULL 
	OR p_amount < 0 THEN 
		LET r_rec_ps_cheque.pay_amt = 0 
	END IF 
	LET r_rec_ps_cheque.apply_amt = 0 
	LET r_rec_ps_cheque.disc_amt = 0 
	LET r_rec_ps_cheque.hist_flag = "N" 
	LET r_rec_ps_cheque.post_flag = "N" 
	LET r_rec_ps_cheque.recon_flag = "N" 
	LET r_rec_ps_cheque.next_appl_num = 0 
	LET r_rec_ps_cheque.currency_code = l_rec_bank.currency_code 
	LET r_rec_ps_cheque.conv_qty = 1.0 
	IF (r_rec_ps_cheque.currency_code != l_rec_glparms.base_currency_code) THEN 
		CALL get_conv_rate(r_rec_ps_cheque.cmpy_code, 
		r_rec_ps_cheque.currency_code, 
		r_rec_ps_cheque.cheq_date, 
		CASH_EXCHANGE_BUY) 
		RETURNING r_rec_ps_cheque.conv_qty 
	END IF 
	
	LET r_rec_ps_cheque.withhold_tax_ind = "0" 
	
	CALL get_whold_tax(
		r_rec_ps_cheque.cmpy_code, 
		r_rec_ps_cheque.vend_code, 
		l_rec_vendor.type_code) 
	RETURNING 
		r_rec_ps_cheque.withhold_tax_ind, 
		r_rec_ps_cheque.tax_code, 
		r_rec_ps_cheque.tax_per 
	
	LET r_rec_ps_cheque.whtax_rep_ind = r_rec_ps_cheque.withhold_tax_ind 
	LET r_rec_ps_cheque.pay_meth_ind = l_rec_vendor.pay_meth_ind 
	LET r_rec_ps_cheque.eft_run_num = 0 
	LET r_rec_ps_cheque.apply_amt = 0 
	LET r_rec_ps_cheque.doc_num = 0 
	LET r_error_text = NULL 
	RETURN true, r_rec_ps_cheque.*, r_error_text 
END FUNCTION 
#########################################################################
# FUNCTION:        cheque_verify
# Description:     Used TO verify a cheque prior TO inserting
# Passed: (Legend: M=Mandatory O=Optional)
# M p_rec_cheque      cheque RECORD TO be verified.
# Returned:
#   TRUE/FALSE     FALSE - IF errors encountered; TRUE - no errors encountered
#   r_rec_cheque      new cheque RECORD (with defaults) IF TRUE;
#   r_error_text  IS used TO show a brief description of the error found
#                  WHEN setting up cheque details
#########################################################################
FUNCTION cheque_verify(p_rec_cheque) 
	DEFINE p_rec_cheque RECORD LIKE cheque.*
 	DEFINE l_rec_bank RECORD LIKE bank.* 
	DEFINE l_rec_glparms RECORD LIKE glparms.* 
	DEFINE r_rec_cheque RECORD LIKE cheque.*
	DEFINE r_error_text CHAR(40)

	INITIALIZE r_rec_cheque.* TO NULL 
	INITIALIZE l_rec_bank.* TO NULL 
	LET r_rec_cheque.* = p_rec_cheque.* 
	IF r_rec_cheque.cmpy_code IS NULL 
	OR r_rec_cheque.cmpy_code = " " THEN 
		LET r_error_text = "Company Code Not Setup(2) - cheqbox" 
		RETURN FALSE, r_rec_cheque.*, r_error_text 
	ELSE 
		SELECT * INTO l_rec_glparms.* FROM glparms 
		WHERE cmpy_code = r_rec_cheque.cmpy_code 
		AND key_code = "1" 
	END IF 
	LET r_error_text = "Vendor Code Not Setup (2) - cheqbox" 
	IF r_rec_cheque.vend_code IS NULL 
	OR r_rec_cheque.vend_code = " " THEN 
		RETURN FALSE, r_rec_cheque.*, r_error_text 
	END IF 
	LET r_error_text = "Bank Code Not Setup (2) - cheqbox" 
	IF r_rec_cheque.bank_code IS NULL 
	OR r_rec_cheque.bank_code = " " THEN 
		RETURN FALSE, r_rec_cheque.*, r_error_text 
	END IF 
	IF r_rec_cheque.cheq_code IS NULL THEN 
		### Need TO retrieve the bank details FOR r_rec_cheque.bank_code
		SELECT * INTO l_rec_bank.* FROM bank 
		WHERE cmpy_code = r_rec_cheque.cmpy_code 
		AND bank_code = r_rec_cheque.bank_code 
		IF status = notfound THEN 
			LET r_error_text = "Bank Code Not Setup (3) - cheqbox" 
			RETURN FALSE, r_rec_cheque.*, r_error_text 
		END IF 
		LET r_rec_cheque.cheq_code = l_rec_bank.next_cheque_num 
	END IF 
	IF r_rec_cheque.entry_date IS NULL THEN 
		LET r_rec_cheque.entry_date = today 
	END IF 
	IF r_rec_cheque.cheq_date IS NULL THEN 
		LET r_rec_cheque.cheq_date = today 
	END IF 
	IF (r_rec_cheque.year_num IS null) OR (r_rec_cheque.period_num IS null) THEN 
		CALL db_period_what_period(r_rec_cheque.cmpy_code, r_rec_cheque.cheq_date) 
		RETURNING r_rec_cheque.year_num, r_rec_cheque.period_num 
	END IF 
	IF r_rec_cheque.pay_amt IS NULL THEN 
		LET r_rec_cheque.pay_amt = 0 
	END IF 
	IF (r_rec_cheque.currency_code != l_rec_glparms.base_currency_code) THEN 
		CALL get_conv_rate(
			r_rec_cheque.cmpy_code, 
			r_rec_cheque.currency_code, 
			r_rec_cheque.cheq_date, 
			CASH_EXCHANGE_BUY) 
		RETURNING r_rec_cheque.conv_qty 
	END IF 
	
	CALL wtaxcalc(r_rec_cheque.pay_amt, 
	r_rec_cheque.tax_per, 
	r_rec_cheque.withhold_tax_ind, 
	r_rec_cheque.cmpy_code) 
	RETURNING r_rec_cheque.net_pay_amt, 
	r_rec_cheque.tax_amt 
	IF r_rec_cheque.pay_meth_ind = "3" THEN 
		LET r_rec_cheque.com2_text = "EFT Run Number ", r_rec_cheque.eft_run_num 
	END IF 
	LET r_rec_cheque.source_ind = "1" 
	LET r_rec_cheque.source_text = p_rec_cheque.vend_code 
	LET r_rec_cheque.contra_amt = 0 
	LET r_rec_cheque.contra_trans_num = 0 
	LET r_error_text = NULL 
	RETURN true, r_rec_cheque.*, r_error_text 
END FUNCTION 
##############################################################################
# FUNCTION:             auto_cheq_appl
# Description:          Used TO apply a cheque TO a voucher
#                       Pass the company, cheque number, voucher code,
#                       bank acct code AND verbose indicator TO apply cheque
#                       TO voucher.
# Passed:
#   p_cmpy_code       the company code that this application relates TO
#   p_cheq_num        the cheque number of the cheque RECORD being applied
#   p_vouch_num       the voucher number of the voucher record
#   p_bank_acct_code  the bank account code used with cheque number TO SELECT
#                      the cheque details
#   pr_verbose_ind     the indicator TO be verbose with MESSAGEs OR NOT
#
# Returned:
#   TRUE/FALSE    FALSE - IF errors encountered; TRUE - no errors encountered
#   pr_error_text does NOT seem TO be setup AT this moment will need more work
##############################################################################
FUNCTION auto_cheq_appl(p_cmpy_code,p_cheq_num,p_vouch_num,p_bank_acct_code,p_pay_method) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_cheq_num LIKE cheque.cheq_code 
	DEFINE p_vouch_num LIKE voucher.vouch_code 
	DEFINE p_bank_acct_code LIKE cheque.bank_acct_code 
	DEFINE p_pay_method LIKE cheque.pay_meth_ind 
	DEFINE l_rec_voucher RECORD LIKE voucher.* 
	DEFINE l_rec_voucherpays RECORD LIKE voucherpays.* 
	DEFINE l_rec_cheque RECORD LIKE cheque.* 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_apaudit RECORD LIKE apaudit.* 
	DEFINE l_err_message CHAR(40) 
	DEFINE l_base_vouc_apply_amt LIKE voucherpays.apply_amt 
	DEFINE l_base_cheq_apply_amt LIKE voucherpays.apply_amt
	DEFINE l_base_vouc_disc_amt LIKE voucherpays.disc_amt 
	DEFINE l_base_cheq_disc_amt LIKE voucherpays.disc_amt
	DEFINE l_disc_amt LIKE voucherpays.disc_amt 
	DEFINE l_rec_exchangevar RECORD LIKE exchangevar.* 
	DEFINE r_error_num SMALLINT

	LET r_error_num = 0 
	GOTO bypass 
	LABEL founderror: 
	RETURN FALSE, r_error_num 
	LABEL bypass: 
	WHENEVER ERROR GOTO founderror 
	LET l_err_message = "cheqappl - Chechead UPDATE" 
	DECLARE ck_curs CURSOR FOR 
	SELECT * 
	INTO l_rec_cheque.* 
	FROM cheque 
	WHERE cheque.cmpy_code = p_cmpy_code 
	AND cheque.bank_acct_code = p_bank_acct_code 
	AND cheque.cheq_code = p_cheq_num 
	AND cheque.pay_meth_ind = p_pay_method 
	FOR UPDATE 
	FOREACH ck_curs 
		LET l_rec_cheque.next_appl_num = l_rec_cheque.next_appl_num + 1 
		DECLARE vo1_curs CURSOR FOR 
		SELECT * 
		INTO l_rec_voucher.* 
		FROM voucher 
		WHERE cmpy_code = p_cmpy_code 
		AND vouch_code = p_vouch_num 
		FOR UPDATE 
		FOREACH vo1_curs 
			IF l_rec_voucher.taken_disc_amt IS NULL THEN 
				LET l_rec_voucher.taken_disc_amt = 0 
			END IF 
			IF l_rec_voucher.poss_disc_amt IS NULL THEN 
				LET l_rec_voucher.poss_disc_amt = 0 
			END IF 
			IF l_rec_cheque.cheq_date <= l_rec_voucher.disc_date THEN 
				LET l_disc_amt = l_rec_voucher.poss_disc_amt 
			ELSE 
				LET l_disc_amt = 0 
			END IF 
			LET l_rec_voucher.taken_disc_amt = l_rec_voucher.taken_disc_amt 
			+ l_disc_amt 
			LET l_rec_voucher.paid_amt = l_rec_voucher.paid_amt 
			+ l_rec_cheque.pay_amt + l_disc_amt 

			IF l_rec_voucher.paid_amt > l_rec_voucher.total_amt THEN 
				LET r_error_num = 9002 
				RETURN FALSE, r_error_num 
			END IF 
			LET l_rec_voucher.pay_seq_num = l_rec_voucher.pay_seq_num + 1 

			IF l_rec_voucher.total_amt = l_rec_voucher.paid_amt THEN 
				LET l_rec_voucher.paid_date = l_rec_cheque.cheq_date 
			END IF 

			LET r_error_num = 0 
			LET l_err_message = "cheqappl - Vouchead UPDATE" 
			UPDATE voucher 
			SET paid_amt = l_rec_voucher.paid_amt, 
			pay_seq_num = l_rec_voucher.pay_seq_num, 
			taken_disc_amt = l_rec_voucher.taken_disc_amt, 
			poss_disc_amt = l_rec_voucher.poss_disc_amt, 
			paid_date = l_rec_voucher.paid_date 
			WHERE CURRENT OF vo1_curs 

			LET l_rec_voucherpays.cmpy_code = p_cmpy_code 
			LET l_rec_voucherpays.vend_code = l_rec_cheque.vend_code 
			LET l_rec_voucherpays.vouch_code = l_rec_voucher.vouch_code 
			LET l_rec_voucherpays.seq_num = 0 
			LET l_rec_voucherpays.pay_num = l_rec_cheque.cheq_code 
			LET l_rec_voucherpays.pay_meth_ind = l_rec_cheque.pay_meth_ind 
			LET l_rec_voucherpays.apply_num = l_rec_voucher.pay_seq_num 
			LET l_rec_voucherpays.pay_type_code = "CH" 
			LET l_rec_voucherpays.pay_date = today 
			LET l_rec_voucherpays.apply_amt = l_rec_cheque.pay_amt 
			LET l_rec_voucherpays.disc_amt = l_disc_amt 
			LET l_rec_voucherpays.withhold_tax_ind = l_rec_cheque.withhold_tax_ind 
			LET l_rec_voucherpays.tax_code = l_rec_cheque.tax_code 
			LET l_rec_voucherpays.bank_code = l_rec_cheque.bank_code 
			LET l_rec_voucherpays.rev_flag = NULL 
			LET l_rec_voucherpays.tax_per = l_rec_cheque.tax_per 
			LET l_rec_voucherpays.pay_doc_num = l_rec_cheque.doc_num 
			LET l_rec_voucherpays.remit_doc_num = l_rec_cheque.doc_num 
			LET r_error_num = 0 
			LET l_err_message = "cheqappl - Voucherpay Insert" 

			INSERT INTO voucherpays 
			VALUES (l_rec_voucherpays.*) 

			IF l_disc_amt > 0 THEN 
				SELECT * 
				INTO l_rec_vendor.* 
				FROM vendor 
				WHERE cmpy_code = p_cmpy_code 
				AND vend_code = l_rec_cheque.vend_code 
				LET l_rec_vendor.next_seq_num = l_rec_vendor.next_seq_num + 1 
				LET l_rec_vendor.curr_amt = l_rec_vendor.curr_amt - l_disc_amt 
				LET l_rec_vendor.bal_amt = l_rec_vendor.bal_amt - l_disc_amt 
				LET r_error_num = 0 
				LET l_err_message = "cheqappl - Vendor UPDATE" 
				UPDATE vendor 
				SET next_seq_num = l_rec_vendor.next_seq_num, 
				curr_amt = l_rec_vendor.curr_amt, 
				bal_amt = l_rec_vendor.bal_amt 
				WHERE cmpy_code = p_cmpy_code 
				AND vend_code = l_rec_cheque.vend_code 

				CALL db_period_what_period(p_cmpy_code, today) 
				RETURNING l_rec_apaudit.year_num, 
				l_rec_apaudit.period_num 
				LET l_rec_apaudit.cmpy_code = p_cmpy_code 
				LET l_rec_apaudit.tran_date = today 
				LET l_rec_apaudit.vend_code = l_rec_cheque.vend_code 
				LET l_rec_apaudit.seq_num = l_rec_vendor.next_seq_num 
				LET l_rec_apaudit.trantype_ind = "CH" 
				LET l_rec_apaudit.source_num = l_rec_cheque.cheq_code 
				LET l_rec_apaudit.tran_text = "Apply Discount" 
				LET l_rec_apaudit.tran_amt = 0 - l_disc_amt 
				LET l_rec_apaudit.entry_code = l_rec_cheque.entry_code 
				LET l_rec_apaudit.bal_amt = l_rec_vendor.bal_amt 
				LET l_rec_apaudit.currency_code = l_rec_cheque.currency_code 
				LET l_rec_apaudit.conv_qty = l_rec_cheque.conv_qty 
				LET l_rec_apaudit.entry_date = today 
				LET l_err_message = "cheqappl - Apaudit Log Insert" 
				INSERT INTO apaudit VALUES (l_rec_apaudit.*) 
			END IF 

			IF l_rec_voucher.conv_qty IS NOT NULL THEN 
				IF l_rec_voucher.conv_qty != 0 THEN 
					LET l_base_vouc_apply_amt = l_rec_voucherpays.apply_amt / 
					l_rec_voucher.conv_qty 
					LET l_base_cheq_apply_amt = l_rec_voucherpays.apply_amt / 
					l_rec_cheque.conv_qty 
					LET l_base_vouc_disc_amt = l_rec_voucherpays.disc_amt / 
					l_rec_voucher.conv_qty 
					LET l_base_cheq_disc_amt = l_rec_voucherpays.disc_amt / 
					l_rec_cheque.conv_qty 
				END IF 
			END IF 

			LET l_rec_exchangevar.exchangevar_amt = l_base_cheq_apply_amt - 
			l_base_vouc_apply_amt 
			IF l_rec_exchangevar.exchangevar_amt != 0 THEN 
				LET l_rec_exchangevar.cmpy_code = l_rec_cheque.cmpy_code 
				LET l_rec_exchangevar.year_num = l_rec_cheque.year_num 
				LET l_rec_exchangevar.period_num = l_rec_cheque.period_num 
				LET l_rec_exchangevar.source_ind = "P" 
				LET l_rec_exchangevar.tran_date = l_rec_cheque.cheq_date 
				LET l_rec_exchangevar.ref_code = l_rec_cheque.vend_code 
				LET l_rec_exchangevar.tran_type1_ind = "VO" 
				LET l_rec_exchangevar.ref1_num = l_rec_voucher.vouch_code 
				LET l_rec_exchangevar.tran_type2_ind = "CH" 
				LET l_rec_exchangevar.ref2_num = l_rec_cheque.cheq_code 
				LET l_rec_exchangevar.currency_code = l_rec_voucher.currency_code 
				LET l_rec_exchangevar.posted_flag = "N" 
				INSERT INTO exchangevar 
				VALUES (l_rec_exchangevar.*) 
			END IF 
			# add RECORD FOR exchange variance on discount
			LET l_rec_exchangevar.exchangevar_amt = l_base_cheq_disc_amt - 
			l_base_vouc_disc_amt 
			IF l_rec_exchangevar.exchangevar_amt != 0 THEN 
				LET r_error_num = 0 
				LET l_err_message = "cheqappl - ExchangeVar Insert" 
				INSERT INTO exchangevar 
				VALUES (l_rec_exchangevar.*) 
			END IF 

		END FOREACH 

		LET r_error_num = 0 
		LET l_err_message = "cheqbox - Cheque Header UPDATE" 
		LET l_rec_cheque.apply_amt = l_rec_cheque.pay_amt 
		LET l_rec_cheque.disc_amt = l_disc_amt 
		UPDATE cheque 
		SET * = l_rec_cheque.* 
		WHERE CURRENT OF ck_curs 

	END FOREACH 
	LET int_flag = FALSE 
	LET quit_flag = FALSE 
	RETURN true, r_error_num 
END FUNCTION 



