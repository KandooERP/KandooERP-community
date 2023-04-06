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

	Source code beautified by beautify.pl on 2020-01-02 10:35:40	$Id: $
}



#
#  module vouchfunc - routines FOR voucher transactions
#
GLOBALS "../common/glob_GLOBALS.4gl" 
#
# FUNCTION init_voucher
#
# This routine sets up the initial voucher VALUES based on the
# vendor AND transaction date details AND returns the initialised
# record.
# NOTE: The voucher year AND period are initialised using the
# version of "what_period" that does NOT DISPLAY error MESSAGEs.
# The VALUES of year AND period should be checked AFTER calling
# the routine, TO ensure that they are NOT NULL.
#
# Parameters: p_cmpy_code      = the company code FOR the vendor
#           : p_whom           = the user sign on code
#           : p_vend_code      = the vendor code
#           : p_tran_date      = the transaction date
#           : p_base_curr_code = the base currency code FROM gl parms
#           : p_approv_flag    = the voucher approval flag FROM ap parms
#
# Returns   : CALL STATUS      = TRUE IF successful, FALSE if
#                                application error
#           : pr_voucher.*     = initialised voucher record
#           : err_msg          = error MESSAGE IF applicable

FUNCTION init_voucher(p_cmpy_code,p_whom,p_vend_code,p_tran_date,p_base_curr_code,p_approv_flag) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_whom LIKE kandoouser.sign_on_code 
	DEFINE p_vend_code LIKE vendor.vend_code 
	DEFINE p_tran_date LIKE voucher.vouch_date 
	DEFINE p_base_curr_code LIKE glparms.base_currency_code 
	DEFINE p_approv_flag LIKE apparms.vouch_approve_flag 
	DEFINE l_rec_voucher RECORD LIKE voucher.* 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_vendortype RECORD LIKE vendortype.* 
	DEFINE l_rec_term RECORD LIKE term.* 
	DEFINE l_error_msg CHAR(60) 

	INITIALIZE l_rec_voucher.* TO NULL 
	SELECT * INTO l_rec_vendor.* 
	FROM vendor 
	WHERE vend_code = p_vend_code 
	AND cmpy_code = p_cmpy_code 
	IF STATUS = NOTFOUND THEN 
		LET l_error_msg = "Logic Error: Vendor ", p_vend_code clipped, 
		" NOT found" 
		RETURN FALSE, l_rec_voucher.*, l_error_msg 
	END IF 
	SELECT * INTO l_rec_vendortype.* 
	FROM vendortype 
	WHERE type_code = l_rec_vendor.type_code 
	AND cmpy_code = p_cmpy_code 
	IF STATUS = NOTFOUND THEN 
		LET l_error_msg = "Logic Error: Vendor type ", 
		l_rec_vendor.type_code, " NOT found" 
		RETURN FALSE, l_rec_voucher.*, l_error_msg 
	END IF 
	SELECT * INTO l_rec_term.* 
	FROM term 
	WHERE term_code = l_rec_vendor.term_code 
	AND cmpy_code = p_cmpy_code 
	IF STATUS = NOTFOUND THEN 
		LET l_error_msg = "Logic Error: Vendor term ", 
		l_rec_vendor.term_code, " NOT found" 
		RETURN FALSE, l_rec_voucher.*, l_error_msg 
	END IF 
	CALL get_fiscal_year_period_for_date(p_cmpy_code, p_tran_date) 
	RETURNING l_rec_voucher.year_num, l_rec_voucher.period_num 
	IF l_rec_voucher.year_num IS NULL OR l_rec_voucher.period_num IS NULL THEN 
		LET l_error_msg = "Year AND period NOT SET up FOR ", 
		p_tran_date USING "dd/mm/yyyy" 
		RETURN FALSE, l_rec_voucher.*, l_error_msg 
	END IF 
	LET l_rec_voucher.cmpy_code = p_cmpy_code 
	LET l_rec_voucher.vend_code = p_vend_code 
	LET l_rec_voucher.inv_text = NULL 
	LET l_rec_voucher.po_num = NULL 
	LET l_rec_voucher.vouch_date = p_tran_date 
	LET l_rec_voucher.entry_code = p_whom 
	LET l_rec_voucher.entry_date = today 
	LET l_rec_voucher.sales_text = l_rec_vendor.contact_text 
	LET l_rec_voucher.term_code = l_rec_vendor.term_code 
	LET l_rec_voucher.tax_code = l_rec_vendor.tax_code 
	LET l_rec_voucher.goods_amt = 0 
	LET l_rec_voucher.tax_amt = 0 
	LET l_rec_voucher.total_amt = 0 
	LET l_rec_voucher.paid_amt = 0 
	LET l_rec_voucher.dist_qty = 0 
	LET l_rec_voucher.dist_amt = 0 
	LET l_rec_voucher.poss_disc_amt = 0 
	LET l_rec_voucher.taken_disc_amt = 0 
	CALL get_due_and_discount_date(l_rec_term.*, l_rec_voucher.vouch_date) 
	RETURNING l_rec_voucher.due_date, l_rec_voucher.disc_date 
	LET l_rec_voucher.hist_flag = 'N' 
	LET l_rec_voucher.jour_num = 0 
	LET l_rec_voucher.post_flag = 'N' 
	LET l_rec_voucher.pay_seq_num = 0 
	LET l_rec_voucher.line_num = 0 
	IF p_approv_flag = "Y" THEN 
		LET l_rec_voucher.approved_code = "N" 
	ELSE 
		LET l_rec_voucher.approved_code = "Y" 
	END IF 
	
	LET l_rec_voucher.split_from_num = 0 
	LET l_rec_voucher.currency_code = l_rec_vendor.currency_code 
	
	IF l_rec_vendor.currency_code = p_base_curr_code THEN 
		LET l_rec_voucher.conv_qty = 1.0 
	ELSE 
		CALL get_conv_rate(p_cmpy_code, l_rec_voucher.currency_code, l_rec_voucher.vouch_date,CASH_EXCHANGE_BUY) 
		RETURNING l_rec_voucher.conv_qty 
	END IF
	 
	LET l_rec_voucher.source_ind = "1" 
	LET l_rec_voucher.withhold_tax_ind = l_rec_vendortype.withhold_tax_ind 

	RETURN TRUE, l_rec_voucher.*, l_error_msg 
END FUNCTION 
#
# FUNCTION ins_vouch_apaudit
#
# This routine inserts the apaudit RECORD associated with a voucher.
#
# Parameters: p_voucher.*     = the voucher RECORD FOR which the
#                                audit RECORD IS being inserted
#           : p_curr_seq_num  = the current value of the next sequence
#                                number field on the vendor record
#           : p_curr_bal_amt  = the current value of the vendor balance
#           : p_rev_ind       = "0" IF the voucher IS being inserted
#                              = "1" IF the voucher IS being edited
#                              = "2" IF the voucher IS being reversed
#                                ie. the audit records are negative
#
# Returns   : CALL STATUS      = 0 IF successful, -1 IF application
#                                error, -2 IF database error (including
#                                locks)
#           : database STATUS  = the STATUS that caused the "whenever
#                                error" procedure TO be invoked, FOR
#                                CALL STATUS of -2 only
#           : error MESSAGE    = an error MESSAGE indicating the source
#                                of the database OR application error
#           : pr_apaudit.seq_num = the last used sequence number FOR
#                                  the audit records
#           : pr_apaudit.bal_amt = the resulting vendor balance
#
FUNCTION ins_vouch_apaudit(p_voucher,p_curr_seq_num,p_curr_bal_amt,p_rev_ind) 
	DEFINE p_voucher RECORD LIKE voucher.* 
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
	LET l_rec_apaudit.cmpy_code = p_voucher.cmpy_code 
	LET l_rec_apaudit.tran_date = p_voucher.vouch_date 
	LET l_rec_apaudit.vend_code = p_voucher.vend_code 
	LET l_rec_apaudit.year_num = p_voucher.year_num 
	LET l_rec_apaudit.period_num = p_voucher.period_num 
	LET l_rec_apaudit.trantype_ind = "VO" 
	LET l_rec_apaudit.source_num = p_voucher.vouch_code 
	LET l_rec_apaudit.entry_code = p_voucher.entry_code 
	LET l_rec_apaudit.currency_code = p_voucher.currency_code 
	LET l_rec_apaudit.conv_qty = p_voucher.conv_qty 
	LET l_rec_apaudit.entry_date = today 
	#
	# Set up initial VALUES of sequence number AND balance FROM
	# current vendor RECORD VALUES.  Subsequent audit records add TO
	# (OR subtract FROM) these VALUES.
	#
	LET l_rec_apaudit.seq_num = p_curr_seq_num 
	LET l_rec_apaudit.bal_amt = p_curr_bal_amt 
	#
	# Audit RECORD FOR the voucher amount - negative IF reversal
	#
	LET l_rec_apaudit.tran_amt = p_voucher.total_amt 
	LET l_rec_apaudit.tran_text = "Voucher Entry" 
	CASE (p_rev_ind) 
		WHEN "1" 
			LET l_rec_apaudit.tran_text = "Voucher Edit" 
		WHEN "2" 
			LET l_rec_apaudit.tran_amt = 0 - p_voucher.total_amt 
			LET l_rec_apaudit.tran_text = "Backout Voucher" 
	END CASE 
	LET l_rec_apaudit.seq_num = l_rec_apaudit.seq_num + 1 
	LET l_rec_apaudit.bal_amt = l_rec_apaudit.bal_amt + l_rec_apaudit.tran_amt 
	LET l_err_message = "ins_vouch_apaudit - INSERT INTO apaudit" 
	INSERT INTO apaudit VALUES (l_rec_apaudit.*) 
	RETURN 0,0,"",l_rec_apaudit.seq_num, l_rec_apaudit.bal_amt 
END FUNCTION 


