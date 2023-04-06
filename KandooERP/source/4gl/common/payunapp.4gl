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
# FUNCTION unapply_payment
#
# This routine performs all the processing required TO reverse
# the application of a given payment TO a vendor. It will UPDATE the
# voucher paid amounts, reverse the voucherpays entries AND UPDATE
# the vendor balance IF a discount was taken.  It will also reverse
# the effect of any exchange variance entries previously created.
# The FUNCTION must be run in a transaction, started FROM within the
# calling process. The calling process must also lock the cheque
# RECORD FOR the payment being unapplied FOR UPDATE before passing
# the cheque RECORD as a parameter.
#
# Parameters: p_whom          = the user id
#             p_cheque.*      = the cheque RECORD FOR which payment
#                                applications are being reversed
# Returns   : CALL STATUS      = 0 IF successful, -1 IF application
#                                error, -2 IF database error (including
#                                locks)
#           : database STATUS  = the STATUS that caused the "whenever
#                                error" procedure TO be invoked, FOR
#                                CALL STATUS of -2 only
#           : error MESSAGE    = an error MESSAGE indicating the source
#                                of the database OR application error
#
###########################################################################

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

###########################################################################
# FUNCTION unapply_payment(p_whom,p_cheque)
#
#
###########################################################################
FUNCTION unapply_payment(p_whom,p_cheque) 
	DEFINE p_whom LIKE kandoouser.sign_on_code 
	DEFINE p_cheque RECORD LIKE cheque.* 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_apaudit RECORD LIKE apaudit.* 
	DEFINE l_rec_voucherpays RECORD LIKE voucherpays.* 
	DEFINE l_rec_voucher RECORD LIKE voucher.*
	DEFINE l_rec_exchangevar RECORD LIKE exchangevar.* 
	DEFINE l_err_message CHAR(80)
	DEFINE l_finish_flag SMALLINT 
	DEFINE l_base_vouch_amt LIKE voucherpays.apply_amt 
	DEFINE l_base_cheque_amt LIKE voucherpays.apply_amt
	DEFINE l_current_year LIKE period.year_num
	DEFINE l_current_period LIKE period.period_num 

	GOTO bypass 
	LABEL ret_status: 
	RETURN -2, status, l_err_message 
	LABEL bypass: 
	WHENEVER ERROR GOTO ret_status 
	#
	# Set up current year AND period FOR later use
	#
	CALL get_fiscal_year_period_for_date(p_cheque.cmpy_code, today) 
	RETURNING l_current_year, l_current_period 
	IF l_current_year IS NULL THEN 
		LET l_err_message = "Unapply Payment - current year & period NOT SET up" 
		RETURN -1,0,l_err_message 
	END IF 
	#
	# Retrieve all the applications FOR this payment AND UPDATE
	# the voucher paid amount WHILE creating a reversal application
	# AND updating the reversal flag on the original application
	#
	LET l_finish_flag = true 
	DECLARE c_voucherpays CURSOR FOR 
	SELECT * FROM voucherpays 
	WHERE cmpy_code = p_cheque.cmpy_code 
	AND pay_num = p_cheque.cheq_code 
	AND vend_code = p_cheque.vend_code 
	AND pay_meth_ind = p_cheque.pay_meth_ind 
	AND pay_type_code = "CH" 
	AND (bank_code = p_cheque.bank_code OR bank_code IS null) 
	AND rev_flag IS NULL	
	FOR UPDATE 
	
	FOREACH c_voucherpays INTO l_rec_voucherpays.* 
		DECLARE c_voucher CURSOR FOR 
		SELECT * FROM voucher 
		WHERE vouch_code = l_rec_voucherpays.vouch_code 
		AND vend_code = l_rec_voucherpays.vend_code 
		AND cmpy_code = l_rec_voucherpays.cmpy_code 
		FOR UPDATE 
		OPEN c_voucher 
		FETCH c_voucher INTO l_rec_voucher.* 
		IF status = notfound THEN 
			LET l_err_message = "Unapply Payment - voucher ", 
			l_rec_voucherpays.vouch_code USING "<<<<<<<<<", " NOT found" 
			LET l_finish_flag = false 
			EXIT FOREACH 
		END IF 

		#
		# Check TO see IF this voucherpays IS in an incomplete payment
		# cycle - IF so, do NOT continue with the reversal
		#
		SELECT unique 1 FROM tentpays 
		WHERE vend_code = l_rec_voucherpays.vend_code 
		AND vouch_code = l_rec_voucherpays.vouch_code 
		AND cmpy_code = l_rec_voucherpays.cmpy_code 
		IF status != notfound THEN 
			LET l_err_message = "Unapply Payment - voucher ", 
			l_rec_voucherpays.vouch_code USING "<<<<<<<<", 
			" part of current auto pay cycle" 
			LET l_finish_flag = false 
			EXIT FOREACH 

		END IF 
		IF l_rec_voucher.taken_disc_amt IS NULL THEN 
			LET l_rec_voucher.taken_disc_amt = 0 
		END IF 

		LET l_rec_voucher.taken_disc_amt = l_rec_voucher.taken_disc_amt - l_rec_voucherpays.disc_amt 
		LET l_rec_voucher.paid_amt = l_rec_voucher.paid_amt - l_rec_voucherpays.apply_amt - l_rec_voucherpays.disc_amt 

		IF l_rec_voucher.paid_amt < 0 THEN 
			LET l_err_message = "Unapply Payment - unapply will reduce voucher paid total TO < 0" 
			LET l_finish_flag = false 
			EXIT FOREACH 
		END IF 

		LET l_err_message = "Unapply payment - Voucher UPDATE" 
		LET l_rec_voucher.pay_seq_num = l_rec_voucher.pay_seq_num + 1 

		UPDATE voucher SET pay_seq_num = l_rec_voucher.pay_seq_num, 
		paid_amt = l_rec_voucher.paid_amt, 
		taken_disc_amt = l_rec_voucher.taken_disc_amt 
		WHERE vouch_code = l_rec_voucher.vouch_code 
		AND cmpy_code = l_rec_voucher.cmpy_code 

		#
		# IF NOT a base currency vendor, check apply AND discount amounts AND
		# reverse any exchange variances
		#
		IF l_rec_voucher.conv_qty <> 1 OR p_cheque.conv_qty <> 1 THEN 
			IF l_rec_voucher.conv_qty = 0 OR l_rec_voucher.conv_qty IS NULL THEN 
				LET l_err_message = "Unapply Payment - voucher ", 
				l_rec_voucher.vouch_code USING "<<<<<<<<<", 
				" has invalid conversion rate" 
				LET l_finish_flag = false 
				EXIT FOREACH 
			END IF 

			IF p_cheque.conv_qty = 0 OR p_cheque.conv_qty IS NULL THEN 
				LET l_err_message = "Unapply Payment - cheque ", 
				p_cheque.cheq_code USING "<<<<<<<<<", 
				" has invalid conversion rate" 
				LET l_finish_flag = false 
				EXIT FOREACH 
			END IF 

			LET l_rec_exchangevar.cmpy_code = p_cheque.cmpy_code 
			LET l_rec_exchangevar.year_num = l_current_year 
			LET l_rec_exchangevar.period_num = l_current_period 
			LET l_rec_exchangevar.source_ind = PAYMENT_TYPE_CC_P #was "P" ?? 
			LET l_rec_exchangevar.tran_date = p_cheque.cheq_date 
			LET l_rec_exchangevar.ref_code = p_cheque.vend_code 
			LET l_rec_exchangevar.tran_type1_ind = "VO" 
			LET l_rec_exchangevar.ref1_num = l_rec_voucher.vouch_code 
			LET l_rec_exchangevar.tran_type2_ind = "CH" 
			LET l_rec_exchangevar.ref2_num = p_cheque.cheq_code 
			LET l_rec_exchangevar.currency_code = l_rec_voucher.currency_code 
			LET l_rec_exchangevar.posted_flag = "N" 

			# Apply amount exchange variance - note that this IS the reverse
			# of the application calculation
			LET l_base_vouch_amt = l_rec_voucherpays.apply_amt / l_rec_voucher.conv_qty 
			LET l_base_cheque_amt = l_rec_voucherpays.apply_amt / p_cheque.conv_qty 
			LET l_rec_exchangevar.exchangevar_amt = l_base_vouch_amt - l_base_cheque_amt 

			IF l_rec_exchangevar.exchangevar_amt != 0 THEN 
				INSERT INTO exchangevar VALUES (l_rec_exchangevar.*) 
			END IF 

			# Create exchange variance on discount
			LET l_base_vouch_amt = l_rec_voucherpays.disc_amt / l_rec_voucher.conv_qty 
			LET l_base_cheque_amt = l_rec_voucherpays.disc_amt / p_cheque.conv_qty 
			LET l_rec_exchangevar.exchangevar_amt = l_base_vouch_amt - l_base_cheque_amt 
			IF l_rec_exchangevar.exchangevar_amt != 0 THEN 
				INSERT INTO exchangevar VALUES (l_rec_exchangevar.*) 
			END IF 
		END IF
		 
		UPDATE voucherpays SET rev_flag = "Y" 
		WHERE vend_code = l_rec_voucherpays.vend_code 
		AND pay_num = l_rec_voucherpays.pay_num 
		AND seq_num = l_rec_voucherpays.seq_num 
		AND cmpy_code = l_rec_voucherpays.cmpy_code
		 
		LET l_err_message = "Unapply payment - Voucherpays UPDATE" 
		LET l_rec_voucherpays.apply_amt = 0 - l_rec_voucherpays.apply_amt 
		LET l_rec_voucherpays.disc_amt = 0 - l_rec_voucherpays.disc_amt 
		LET l_rec_voucherpays.seq_num = 0 
		LET l_rec_voucherpays.remit_doc_num = 0 
		LET l_rec_voucherpays.apply_num = l_rec_voucher.pay_seq_num 
		LET l_rec_voucherpays.pay_date = today 
		LET l_rec_voucherpays.rev_flag = "Y"
		 
		INSERT INTO voucherpays VALUES (l_rec_voucherpays.*)
		 
	END FOREACH 

	IF l_finish_flag = false THEN 
		RETURN -1,0,l_err_message 
	END IF 

	#
	# IF discount was taken, reduce vendor balance AND create an apaudit
	# TO reflect that adjustment
	#
	IF p_cheque.disc_amt <> 0 THEN
	 
		DECLARE c_vendor CURSOR FOR 
		SELECT * FROM vendor 
		WHERE vend_code = p_cheque.vend_code 
		AND cmpy_code = p_cheque.cmpy_code 
		FOR UPDATE 
		OPEN c_vendor 
		FETCH c_vendor INTO l_rec_vendor.* 
		IF status = notfound THEN 
			LET l_err_message = "Unapply Payment - vendor ", 
			p_cheque.vend_code, " NOT found" 
			RETURN -1,0,l_err_message 
		END IF 

		LET l_rec_vendor.curr_amt = l_rec_vendor.curr_amt + p_cheque.disc_amt 
		LET l_rec_vendor.bal_amt = l_rec_vendor.bal_amt + p_cheque.disc_amt 
		LET l_rec_vendor.next_seq_num = l_rec_vendor.next_seq_num + 1 
		LET l_err_message = "Unapply Payment - vendor UPDATE"
		 
		UPDATE vendor 
		SET bal_amt = l_rec_vendor.bal_amt, 
		curr_amt = l_rec_vendor.curr_amt, 
		next_seq_num = l_rec_vendor.next_seq_num 
		WHERE vend_code = l_rec_vendor.vend_code 
		AND cmpy_code = p_cheque.cmpy_code
		 
		LET l_rec_apaudit.cmpy_code = p_cheque.cmpy_code 
		LET l_rec_apaudit.tran_date = today 
		LET l_rec_apaudit.vend_code = p_cheque.vend_code 
		LET l_rec_apaudit.seq_num = l_rec_vendor.next_seq_num 
		LET l_rec_apaudit.trantype_ind = "CH" 
		LET l_rec_apaudit.year_num = l_current_year 
		LET l_rec_apaudit.period_num = l_current_period 
		LET l_rec_apaudit.source_num = p_cheque.cheq_code 
		LET l_rec_apaudit.tran_text = "Un-apply Discount" 
		LET l_rec_apaudit.tran_amt = p_cheque.disc_amt 
		LET l_rec_apaudit.entry_code = p_cheque.entry_code 
		LET l_rec_apaudit.bal_amt = l_rec_vendor.bal_amt 
		LET l_rec_apaudit.currency_code = p_cheque.currency_code 
		LET l_rec_apaudit.conv_qty = p_cheque.conv_qty 
		LET l_rec_apaudit.entry_date = today 
		LET l_err_message = "Unapply Payment - INSERT apaudit" 
		INSERT INTO apaudit VALUES (l_rec_apaudit.*) 
	END IF
	 
	UPDATE cheque SET apply_amt = 0, 
	disc_amt = 0, 
	source_text = NULL 
	WHERE bank_code = p_cheque.bank_code 
	AND cheq_code = p_cheque.cheq_code 
	AND pay_meth_ind = p_cheque.pay_meth_ind 
	AND cmpy_code = p_cheque.cmpy_code 

	RETURN 0,0,l_err_message 
END FUNCTION 
###########################################################################
# END FUNCTION unapply_payment(p_whom,p_cheque)
###########################################################################
