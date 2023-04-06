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

	Source code beautified by beautify.pl on 2020-01-03 13:41:29	$Id: $
}



# FUNCTION auto_cheq_app applies the cheques TO the given voucher
#

GLOBALS "../common/glob_GLOBALS.4gl" 

FUNCTION auto_cheq_appl(p_cmpy,p_cheqnum,p_vouch_num,p_the_bank_acct_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_cheqnum LIKE cheque.cheq_code 
	DEFINE p_vouch_num LIKE voucher.vouch_code 
	DEFINE p_the_bank_acct_code LIKE cheque.bank_acct_code 
	DEFINE l_msgresp LIKE language.yes_flag
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
	DEFINE l_try_again CHAR(1) 

	GOTO bypass 
	LABEL recovery: 
	LET l_try_again = error_recover(l_err_message, status) 
	IF l_try_again != "Y" THEN 
		EXIT PROGRAM 
	END IF 

	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	BEGIN WORK 

		LET l_err_message = "P41 - Chechead UPDATE" 
		DECLARE ck_curs CURSOR FOR 
		SELECT * INTO l_rec_cheque.* FROM cheque 
		WHERE cheque.cmpy_code = p_cmpy 
		AND cheque.bank_acct_code = p_the_bank_acct_code 
		AND cheque.cheq_code = p_cheqnum 
		AND cheque.pay_meth_ind = "1" 
		FOR UPDATE 
		FOREACH ck_curs 
			LET l_rec_cheque.next_appl_num = l_rec_cheque.next_appl_num + 1 
			DECLARE vo1_curs CURSOR FOR 
			SELECT * INTO l_rec_voucher.* FROM voucher 
			WHERE cmpy_code = p_cmpy 
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
				+ l_rec_cheque.pay_amt 
				+ l_disc_amt 

				IF l_rec_voucher.paid_amt > l_rec_voucher.total_amt THEN 
					ROLLBACK WORK 
					LET l_msgresp = kandoomsg("P",9002,"") 
					#9002 Cheque amount does NOT equal voucher total; Apply manually.
					SLEEP 5 
					EXIT PROGRAM 
				END IF 
				LET l_rec_voucher.pay_seq_num = l_rec_voucher.pay_seq_num + 1 

				IF l_rec_voucher.total_amt = l_rec_voucher.paid_amt THEN 
					LET l_rec_voucher.paid_date = l_rec_cheque.cheq_date 
				END IF 

				LET l_err_message = "P41 - Vouchead UPDATE" 
				UPDATE voucher 
				SET paid_amt = l_rec_voucher.paid_amt, 
				pay_seq_num = l_rec_voucher.pay_seq_num, 
				taken_disc_amt = l_rec_voucher.taken_disc_amt, 
				poss_disc_amt = l_rec_voucher.poss_disc_amt, 
				paid_date = l_rec_voucher.paid_date 
				WHERE CURRENT OF vo1_curs 

				LET l_rec_voucherpays.cmpy_code = p_cmpy 
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
				LET l_rec_voucherpays.remit_doc_num = 0 
				LET l_err_message = "P41 - Voucpay INSERT" 

				INSERT INTO voucherpays VALUES (l_rec_voucherpays.*) 

				#OUTPUT discount record
				IF l_disc_amt > 0 THEN 
					SELECT * INTO l_rec_vendor.* FROM vendor 
					WHERE cmpy_code = p_cmpy 
					AND vend_code = l_rec_cheque.vend_code 
					LET l_rec_vendor.next_seq_num = l_rec_vendor.next_seq_num + 1 
					LET l_rec_vendor.curr_amt = l_rec_vendor.curr_amt 
					- l_disc_amt 
					LET l_rec_vendor.bal_amt = l_rec_vendor.bal_amt 
					- l_disc_amt 
					LET l_err_message = "P41c - Vendor UPDATE" 
					UPDATE vendor 
					SET next_seq_num = l_rec_vendor.next_seq_num, 
					curr_amt = l_rec_vendor.curr_amt, 
					bal_amt = l_rec_vendor.bal_amt 
					WHERE cmpy_code = p_cmpy 
					AND vend_code = l_rec_cheque.vend_code 

					CALL db_period_what_period(p_cmpy, today) 
					RETURNING l_rec_apaudit.year_num, 
					l_rec_apaudit.period_num 
					LET l_rec_apaudit.cmpy_code = p_cmpy 
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
					LET l_err_message = "P41 - Apdlog INSERT" 
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
					INSERT INTO exchangevar VALUES (l_rec_exchangevar.*) 
				END IF 
				#add RECORD FOR exchange variance on discount
				LET l_rec_exchangevar.exchangevar_amt = l_base_cheq_disc_amt - 
				l_base_vouc_disc_amt 
				IF l_rec_exchangevar.exchangevar_amt != 0 THEN 
					INSERT INTO exchangevar 
					VALUES (l_rec_exchangevar.*) 
				END IF 

			END FOREACH 

			LET l_err_message = "P41b - Cheque Header UPDATE" 
			LET l_rec_cheque.apply_amt = l_rec_cheque.pay_amt 
			LET l_rec_cheque.disc_amt = l_disc_amt 
			IF l_rec_cheque.source_ind = "S" 
			AND l_rec_cheque.source_text IS NULL THEN 
				LET l_rec_cheque.source_text = l_rec_voucher.vouch_code 
			END IF 
			UPDATE cheque 
			SET * = l_rec_cheque.* 
			WHERE CURRENT OF ck_curs 

		END FOREACH 
	COMMIT WORK 
	LET int_flag = false 
	LET quit_flag = false 
END FUNCTION 


