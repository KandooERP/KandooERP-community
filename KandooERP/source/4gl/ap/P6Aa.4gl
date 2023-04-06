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
#Generic debit application UPDATE routine


GLOBALS "../common/glob_GLOBALS.4gl" 


FUNCTION debit_apply(p_cmpy,p_kandoouser_sign_on_code,p_verbose_ind,p_db_num,p_vo_num,p_applied_amt,p_discount_amt) 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code 
	DEFINE p_verbose_ind SMALLINT 
	DEFINE p_db_num LIKE debithead.debit_num 
	DEFINE p_vo_num LIKE voucher.vouch_code 
	DEFINE p_applied_amt LIKE debithead.apply_amt 
	DEFINE p_discount_amt LIKE debithead.disc_amt 
	DEFINE l_appl_amt LIKE debithead.apply_amt 
	DEFINE l_disc_amt LIKE debithead.disc_amt 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_debithead RECORD LIKE debithead.* 
	DEFINE l_rec_voucher RECORD LIKE voucher.* 
	DEFINE l_rec_voucherpays RECORD LIKE voucherpays.* 
	DEFINE l_rec_exchangevar RECORD LIKE exchangevar.* 
	DEFINE l_rec_apaudit RECORD LIKE apaudit.* 
	DEFINE l_base_vo_amt LIKE voucherpays.apply_amt
	DEFINE l_base_db_amt LIKE voucherpays.apply_amt 
	DEFINE l_err_message CHAR(40) 
	DEFINE l_query_text CHAR(2200) 
	DEFINE l_msg_num SMALLINT 
	DEFINE i SMALLINT

	#
	# Dynamic Cursor's
	#
	LET l_query_text = " SELECT * FROM debithead ", 
	" WHERE cmpy_code = '",p_cmpy,"' ", 
	" AND debit_num = ?", 
	" FOR UPDATE" 
	PREPARE s_debithead FROM l_query_text 
	DECLARE c_debithead CURSOR FOR s_debithead 
	LET l_query_text = " SELECT * FROM voucher ", 
	" WHERE cmpy_code = '",p_cmpy,"' ", 
	" AND vouch_code = ?", 
	" FOR UPDATE " 
	PREPARE s_voucher FROM l_query_text 
	DECLARE c_voucher CURSOR FOR s_voucher 
	LET l_query_text = " SELECT * FROM vendor ", 
	" WHERE cmpy_code = '",p_cmpy,"' ", 
	" AND vend_code = ?", 
	" FOR UPDATE " 
	PREPARE s_vendor FROM l_query_text 
	DECLARE c_vendor CURSOR FOR s_vendor 
	#
	#
	#
	GOTO bypass 
	LABEL recovery: 
	IF p_verbose_ind THEN 
		IF status != 0 THEN 
			IF error_recover( l_err_message, status ) != 'Y' THEN 
				RETURN false 
			END IF 
		ELSE 
			ROLLBACK WORK 
			LET msgresp = kandoomsg( 'P', l_msg_num, l_err_message ) 
			RETURN false 
		END IF 
	ELSE 
		IF status != 0 THEN 
			CALL errorlog( l_err_message ) 
		END IF 
		ROLLBACK WORK 
		RETURN false 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	BEGIN WORK 
		#
		#
		#
		OPEN c_debithead USING p_db_num 
		FETCH c_debithead INTO l_rec_debithead.* 
		IF status = NOTFOUND THEN 
			LET l_msg_num = 9058 
			#9058 Logic Error: Debit <VALUE> does NOT exist
			LET l_err_message = p_db_num 
			GOTO recovery 
		END IF 
		LET l_err_message = "P6A - Error locking Vendor" 
		OPEN c_vendor USING l_rec_debithead.vend_code 
		FETCH c_vendor INTO l_rec_vendor.* 
		IF status = NOTFOUND THEN 
			LET l_msg_num = 9060 
			#9060 Logic Error: Vendor <VALUE> does NOT exist
			LET l_err_message = l_rec_debithead.vend_code 
			GOTO recovery 
		END IF 
		LET l_appl_amt = p_applied_amt 
		LET l_disc_amt = p_discount_amt 
		IF l_rec_debithead.post_flag = "Y" AND l_disc_amt != 0 THEN 
			LET l_msg_num = 7042 
			#7042 Warning: Debit <VALUE> has been posted - Discount NOT possible
			LET l_err_message = p_db_num 
			GOTO recovery 
		END IF 
		IF l_rec_debithead.total_amt >= 0 THEN 
			IF l_rec_debithead.total_amt < 
			( l_rec_debithead.apply_amt + l_appl_amt ) THEN 
				LET l_msg_num = 7041 
				# Error: Attempt has been made TO over apply debit <VALUE>
				LET l_err_message = p_db_num 
				GOTO recovery 
			END IF 
		END IF 
		LET l_err_message = "P6B - Error locking Voucher" 
		OPEN c_voucher USING p_vo_num 
		FETCH c_voucher INTO l_rec_voucher.* 
		IF status = NOTFOUND THEN 
			LET l_msg_num = 9059 
			#9059 Logic Error : Voucher <VALUE> does NOT exist
			LET l_err_message = p_vo_num 
			GOTO recovery 
		END IF 
		LET l_rec_voucher.paid_amt = l_rec_voucher.paid_amt 
		+ l_appl_amt 
		+ l_disc_amt 
		IF l_rec_voucher.paid_amt > l_rec_voucher.total_amt THEN 
			LET l_msg_num = 7040 
			#7040 Error: Attempt has been made TO over pay voucher <VALUE>
			LET l_err_message = p_vo_num 
			GOTO recovery 
		END IF 
		IF l_rec_voucher.paid_amt != l_rec_voucher.total_amt 
		AND l_disc_amt > 0 THEN 
			LET l_msg_num = 7039 
			#7039 Error: Invalid discount claim made on voucher <VALUE>
			LET l_err_message = p_vo_num 
			GOTO recovery 
		END IF 
		IF l_rec_voucher.total_amt = l_rec_voucher.paid_amt THEN 
			LET l_rec_voucher.paid_date = l_rec_debithead.debit_date 
		END IF 
		LET l_rec_voucher.pay_seq_num = l_rec_voucher.pay_seq_num + 1 
		LET l_rec_voucher.taken_disc_amt = 
		l_rec_voucher.taken_disc_amt + l_disc_amt 
		LET l_err_message = "P6B - Error updating Voucher" 
		UPDATE voucher 
		SET paid_amt = l_rec_voucher.paid_amt, 
		paid_date = l_rec_voucher.paid_date, 
		pay_seq_num = l_rec_voucher.pay_seq_num, 
		taken_disc_amt = l_rec_voucher.taken_disc_amt 
		WHERE cmpy_code = p_cmpy 
		AND vouch_code = p_vo_num 
		#
		# Voucherpays
		#
		INITIALIZE l_rec_voucherpays.* TO NULL 
		LET l_rec_voucherpays.cmpy_code = p_cmpy 
		LET l_rec_voucherpays.vend_code = l_rec_debithead.vend_code 
		LET l_rec_voucherpays.vouch_code = l_rec_voucher.vouch_code 
		LET l_rec_voucherpays.seq_num = 0 
		LET l_rec_voucherpays.pay_num = l_rec_debithead.debit_num 
		LET l_rec_voucherpays.apply_num = l_rec_voucher.pay_seq_num 
		LET l_rec_voucherpays.pay_type_code = 'DB' 
		LET l_rec_voucherpays.pay_date = today 
		LET l_rec_voucherpays.apply_amt = l_appl_amt 
		LET l_rec_voucherpays.disc_amt = l_disc_amt 
		LET l_rec_voucherpays.withhold_tax_ind = '0' 
		LET l_rec_voucherpays.tax_code = NULL 
		LET l_rec_voucherpays.bank_code = NULL 
		LET l_rec_voucherpays.rev_flag = NULL 
		LET l_rec_voucherpays.tax_per = 0 
		LET l_rec_voucherpays.pay_meth_ind = NULL 
		LET l_rec_voucherpays.remit_doc_num = 0 
		LET l_rec_voucherpays.pay_doc_num = 0 
		LET l_err_message = "P6B- Error inserting voucher payment details" 
		INSERT INTO voucherpays VALUES (l_rec_voucherpays.*) 
		#
		# Exchange Variance
		#
		LET l_base_vo_amt = 0 
		LET l_base_db_amt = 0 
		IF l_rec_voucher.conv_qty IS NOT NULL THEN 
			IF l_rec_voucher.conv_qty != 0 THEN 
				LET l_base_vo_amt = l_rec_voucherpays.apply_amt 
				/ l_rec_voucher.conv_qty 
				LET l_base_db_amt = l_rec_voucherpays.apply_amt 
				/ l_rec_debithead.conv_qty 
			END IF 
		END IF 
		LET l_rec_exchangevar.exchangevar_amt = l_base_vo_amt - l_base_db_amt 
		IF l_rec_exchangevar.exchangevar_amt != 0 THEN 
			LET l_rec_exchangevar.cmpy_code = l_rec_debithead.cmpy_code 
			LET l_rec_exchangevar.year_num = l_rec_debithead.year_num 
			LET l_rec_exchangevar.period_num = l_rec_debithead.period_num 
			LET l_rec_exchangevar.source_ind = "P" 
			LET l_rec_exchangevar.tran_date = l_rec_debithead.debit_date 
			LET l_rec_exchangevar.ref_code = l_rec_debithead.vend_code 
			LET l_rec_exchangevar.tran_type1_ind = "VO" 
			LET l_rec_exchangevar.ref1_num = l_rec_voucher.vouch_code 
			LET l_rec_exchangevar.tran_type2_ind = "DM" 
			LET l_rec_exchangevar.ref2_num = l_rec_debithead.debit_num 
			LET l_rec_exchangevar.currency_code = l_rec_voucher.currency_code 
			LET l_rec_exchangevar.posted_flag = "N" 
			INSERT INTO exchangevar VALUES ( l_rec_exchangevar.* ) 
		END IF 
		#
		# Debithead Update
		#
		LET l_rec_debithead.appl_seq_num = l_rec_debithead.appl_seq_num + 1 
		LET l_rec_debithead.apply_amt = l_rec_debithead.apply_amt + l_appl_amt 
		LET l_rec_debithead.disc_amt = l_rec_debithead.disc_amt + l_disc_amt 
		LET l_err_message = "P6B - Error updating Debit header" 
		UPDATE debithead 
		SET apply_amt = l_rec_debithead.apply_amt, 
		disc_amt = l_rec_debithead.disc_amt, 
		appl_seq_num = l_rec_debithead.appl_seq_num 
		WHERE cmpy_code = p_cmpy 
		AND debit_num = l_rec_debithead.debit_num 
		#
		# Discount
		#
		IF l_disc_amt != 0 THEN 
			#
			# Update Vendor
			#
			LET l_rec_vendor.bal_amt = l_rec_vendor.bal_amt - l_disc_amt 
			LET l_rec_vendor.curr_amt = l_rec_vendor.curr_amt - l_disc_amt 
			LET l_rec_vendor.next_seq_num = l_rec_vendor.next_seq_num + 1 
			LET l_rec_vendor.last_payment_date = l_rec_debithead.debit_date 
			LET l_err_message = "P6B- Error updating vendor" 
			UPDATE vendor 
			SET bal_amt = l_rec_vendor.bal_amt, 
			curr_amt = l_rec_vendor.curr_amt, 
			last_payment_date = l_rec_vendor.last_payment_date, 
			next_seq_num = l_rec_vendor.next_seq_num 
			WHERE cmpy_code = p_cmpy 
			AND vend_code = l_rec_debithead.vend_code 
			#
			# AP Audit
			#
			CALL db_period_what_period(p_cmpy, today) 
			RETURNING l_rec_apaudit.year_num, 
			l_rec_apaudit.period_num 
			LET l_rec_apaudit.cmpy_code = p_cmpy 
			LET l_rec_apaudit.tran_date = today 
			LET l_rec_apaudit.vend_code = l_rec_debithead.vend_code 
			LET l_rec_apaudit.seq_num = l_rec_vendor.next_seq_num 
			LET l_rec_apaudit.source_num = l_rec_debithead.debit_num 
			LET l_rec_apaudit.trantype_ind = 'DB' 
			LET l_rec_apaudit.tran_text = 'apply discount' 
			LET l_rec_apaudit.tran_amt = 0 - l_disc_amt 
			LET l_rec_apaudit.entry_code = p_kandoouser_sign_on_code 
			LET l_rec_apaudit.bal_amt = l_rec_vendor.bal_amt 
			LET l_rec_apaudit.currency_code = l_rec_debithead.currency_code 
			LET l_rec_apaudit.conv_qty = l_rec_debithead.conv_qty 
			LET l_rec_apaudit.entry_date = today 
			LET l_err_message = "P6B- Error inserting AP audit" 
			INSERT INTO apaudit VALUES (l_rec_apaudit.*) 
		END IF 
	COMMIT WORK 
	WHENEVER ERROR stop 
	RETURN true 
END FUNCTION 


