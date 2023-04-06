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

	Source code beautified by beautify.pl on 2020-01-03 13:41:33	$Id: $
}



# P6Ba Unapplies debits FROM outstanding vouchers
#
GLOBALS "../common/glob_GLOBALS.4gl" 
FUNCTION unapply_debit(p_cmpy,p_deb_num) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_deb_num LIKE debithead.debit_num 
	DEFINE l_rec_voucher RECORD LIKE voucher.* 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_apaudit RECORD LIKE apaudit.* 
	DEFINE l_rec_voucherpays RECORD LIKE voucherpays.* 
	DEFINE l_rec_exchangevar RECORD LIKE exchangevar.* 
	DEFINE l_rec_debithead RECORD LIKE debithead.* 
	DEFINE l_msgresp LIKE language.yes_flag
	DEFINE l_err_message CHAR(40) 
	DEFINE l_temp_apply_amt DECIMAL(12,2) 
	DEFINE l_temp_disc_amt DECIMAL(12,2)
	DEFINE l_applied_debit SMALLINT 
	DEFINE try_again CHAR(1)

	SELECT * 
	INTO l_rec_debithead.* 
	FROM debithead 
	WHERE cmpy_code = p_cmpy 
	AND debit_num = p_deb_num 


	IF status = NOTFOUND THEN 
		ERROR " Debit NOT found" 
		SLEEP 5 
		RETURN 
	END IF 

	#now done it CALL init_p_ap() #init P/AP module
	#SELECT *
	#INTO pr_apparms.*
	#FROM apparms
	#WHERE cmpy_code = p_cmpy
	#AND parm_code = "1"

	SELECT * 
	INTO l_rec_vendor.* 
	FROM vendor 
	WHERE cmpy_code = p_cmpy 
	AND vend_code = l_rec_debithead.vend_code 

	GOTO bypass 
	LABEL recovery: 
	LET try_again = error_recover(l_err_message, status) 
	IF try_again != "Y" 
	THEN 
		EXIT PROGRAM 
	END IF 

	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	BEGIN WORK 
		LET l_applied_debit = 0 
		LET l_err_message = "P6B - Debhead UPDATE" 
		DECLARE dm_curs CURSOR FOR 
		SELECT * 
		INTO l_rec_debithead.* 
		FROM debithead 
		WHERE cmpy_code = p_cmpy 
		AND debit_num = l_rec_debithead.debit_num 
		FOR UPDATE 
		FOREACH dm_curs 
			LET l_temp_apply_amt = l_rec_debithead.apply_amt 
			LET l_temp_disc_amt = l_rec_debithead.disc_amt 
			DECLARE vo1_curs CURSOR FOR 
			SELECT * INTO l_rec_voucherpays.* FROM voucherpays 
			WHERE pay_num = l_rec_debithead.debit_num 
			AND pay_type_code = "DB" 
			AND pay_meth_ind IS NULL 
			AND cmpy_code = p_cmpy 
			AND rev_flag IS NULL 
			FOR UPDATE 
			FOREACH vo1_curs 
				SELECT * FROM tentpays 
				WHERE vend_code = l_rec_debithead.vend_code 
				AND vouch_code = l_rec_voucherpays.vouch_code 
				AND cmpy_code = p_cmpy 
				IF status != NOTFOUND THEN 
					LET l_temp_apply_amt = l_temp_apply_amt 
					+ l_rec_voucherpays.apply_amt 
					LET l_temp_disc_amt = l_temp_disc_amt 
					+ l_rec_voucherpays.disc_amt 
					LET l_applied_debit = 1 
					CONTINUE FOREACH 
				END IF 
				DECLARE vo_curs CURSOR FOR 
				SELECT * INTO l_rec_voucher.* FROM voucher 
				WHERE cmpy_code = p_cmpy 
				AND vouch_code = l_rec_voucherpays.vouch_code 
				AND vend_code = l_rec_vendor.vend_code 
				FOR UPDATE 
				FOREACH vo_curs 
					LET l_err_message = "P6B - Vouchead UPDATE" 
					UPDATE voucher SET paid_amt = l_rec_voucher.paid_amt 
					- l_rec_voucherpays.apply_amt 
					- l_rec_voucherpays.disc_amt, 
					pay_seq_num = l_rec_voucher.pay_seq_num + 1, 
					taken_disc_amt = l_rec_voucher.taken_disc_amt - l_rec_voucherpays.disc_amt 
					WHERE CURRENT OF vo_curs 
				END FOREACH 
				IF l_rec_voucherpays.disc_amt > 0 
				THEN 
					LET l_err_message = "P6B - Vendmain UPDATE" 
					DECLARE curr_amts CURSOR FOR 
					SELECT * 
					INTO l_rec_vendor.* 
					FROM vendor 
					WHERE cmpy_code = p_cmpy 
					AND vend_code = l_rec_debithead.vend_code 
					FOR UPDATE 
					FOREACH curr_amts 
						LET l_rec_vendor.curr_amt = l_rec_vendor.curr_amt + 
						l_rec_voucherpays.disc_amt 
						LET l_rec_vendor.bal_amt = l_rec_vendor.bal_amt + 
						l_rec_voucherpays.disc_amt 
						LET l_rec_vendor.next_seq_num = l_rec_vendor.next_seq_num + 1 
						LET l_err_message = "P6B - Vendmain UPDATE" 
						UPDATE vendor SET bal_amt = l_rec_vendor.bal_amt, 
						curr_amt = l_rec_vendor.curr_amt, 
						next_seq_num = l_rec_vendor.next_seq_num 
						WHERE CURRENT OF curr_amts 
					END FOREACH 
					CALL db_period_what_period(p_cmpy, today) 
					RETURNING l_rec_apaudit.year_num, 
					l_rec_apaudit.period_num 
					LET l_rec_apaudit.cmpy_code = p_cmpy 
					LET l_rec_apaudit.tran_date = today 
					LET l_rec_apaudit.vend_code = l_rec_debithead.vend_code 
					LET l_rec_apaudit.seq_num = l_rec_vendor.next_seq_num 
					LET l_rec_apaudit.trantype_ind = "DB" 
					LET l_rec_apaudit.source_num = l_rec_debithead.debit_num 
					LET l_rec_apaudit.tran_text = "Unapply Discount" 
					LET l_rec_apaudit.tran_amt = l_rec_voucherpays.disc_amt 
					LET l_rec_apaudit.entry_code = l_rec_debithead.entry_code 
					LET l_rec_apaudit.bal_amt = l_rec_vendor.bal_amt 
					LET l_rec_apaudit.currency_code = l_rec_debithead.currency_code 
					LET l_rec_apaudit.conv_qty = l_rec_debithead.conv_qty 
					LET l_rec_apaudit.entry_date = today 
					LET l_err_message = "P6B - Apdlog INSERT" 
					INSERT INTO apaudit VALUES (l_rec_apaudit.*) 
				END IF 
			END FOREACH 
			DECLARE c_unapdebit CURSOR FOR 
			SELECT * FROM voucherpays 
			WHERE pay_num = l_rec_debithead.debit_num 
			AND pay_type_code = "DB" 
			AND pay_meth_ind IS NULL 
			AND cmpy_code = p_cmpy 
			AND rev_flag IS NULL 
			FOREACH c_unapdebit INTO l_rec_voucherpays.* 
				SELECT * FROM tentpays 
				WHERE vend_code = l_rec_debithead.vend_code 
				AND vouch_code = l_rec_voucherpays.vouch_code 
				AND cmpy_code = p_cmpy 
				IF status != NOTFOUND THEN 
					CONTINUE FOREACH 
				END IF 
				UPDATE voucherpays SET rev_flag = "Y" 
				WHERE cmpy_code = p_cmpy 
				AND pay_num = l_rec_debithead.debit_num 
				AND voucherpays.vend_code = l_rec_voucherpays.vend_code 
				AND seq_num = l_rec_voucherpays.seq_num 

				LET l_rec_voucherpays.apply_amt = 0 - l_rec_voucherpays.apply_amt 
				LET l_rec_voucherpays.disc_amt = 0 - l_rec_voucherpays.disc_amt 
				LET l_rec_voucherpays.seq_num = 0 
				LET l_rec_voucherpays.apply_num = l_rec_voucherpays.apply_num + 1 
				LET l_rec_voucherpays.pay_date = today 
				LET l_rec_voucherpays.rev_flag = "Y" 
				LET l_rec_voucherpays.remit_doc_num = 0 
				LET l_rec_voucherpays.pay_doc_num = 0 
				INSERT INTO voucherpays VALUES (l_rec_voucherpays.*) 
			END FOREACH 

			DECLARE exch_curs CURSOR FOR 
			SELECT unique cmpy_code, 
			year_num, 
			period_num, 
			source_ind, 
			tran_date, 
			ref_code, 
			tran_type1_ind, 
			ref1_num, 
			tran_type2_ind, 
			ref2_num, 
			currency_code, 
			posted_flag, 
			jour_num, 
			post_date 
			INTO l_rec_exchangevar.cmpy_code, 
			l_rec_exchangevar.year_num, 
			l_rec_exchangevar.period_num, 
			l_rec_exchangevar.source_ind, 
			l_rec_exchangevar.tran_date, 
			l_rec_exchangevar.ref_code, 
			l_rec_exchangevar.tran_type1_ind, 
			l_rec_exchangevar.ref1_num, 
			l_rec_exchangevar.tran_type2_ind, 
			l_rec_exchangevar.ref2_num, 
			l_rec_exchangevar.currency_code, 
			l_rec_exchangevar.posted_flag, 
			l_rec_exchangevar.jour_num, 
			l_rec_exchangevar.post_date 
			FROM exchangevar 
			WHERE cmpy_code = p_cmpy 
			AND tran_type2_ind = "DM" 
			AND ref2_num = p_deb_num 
			FOREACH exch_curs 
				SELECT sum(0 - exchangevar_amt) INTO l_rec_exchangevar.exchangevar_amt 
				FROM exchangevar 
				WHERE cmpy_code = p_cmpy 
				AND tran_type2_ind = "DM" 
				AND ref2_num = p_deb_num 
				AND ref1_num = l_rec_exchangevar.ref1_num #unique voucher 
				IF l_rec_exchangevar.exchangevar_amt != 0 THEN 
					LET l_rec_exchangevar.posted_flag = "N" 
					INSERT INTO exchangevar VALUES (l_rec_exchangevar.*) 
				END IF 
			END FOREACH 

			LET l_err_message = "P6Bb - Debit Header UPDATE" 
			UPDATE debithead SET apply_amt = l_temp_apply_amt 
			- l_rec_debithead.apply_amt, 
			disc_amt = l_temp_disc_amt 
			- l_rec_debithead.disc_amt 
			WHERE CURRENT OF dm_curs 

		END FOREACH 
	COMMIT WORK 
	IF l_applied_debit THEN 
		LET l_msgresp = kandoomsg("P",7003,"") 
		#7003 Debit was NOT fully unapplied due TO vouchers in P3A.
	END IF 
END FUNCTION 


