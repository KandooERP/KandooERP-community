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
	Source code beautified by beautify.pl on 2020-01-03 13:41:28	$Id: $
}
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_P3_GLOBALS.4gl" 
############################################################
# Module Scope Variables
############################################################

############################################################
# MAIN
#
# \brief module P3C  Payment Cycle Cancellation
############################################################
MAIN 

	#Initial UI Init
	CALL setModuleId("P3C") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_p_ap() #init p/ap module 

	OPEN WINDOW p511 with FORM "P511" 
	CALL windecoration_p("P511") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	CALL cancel_payment_run() 
	CLOSE WINDOW p511 
END MAIN 


FUNCTION cancel_payment_run() 
	DEFINE l_payment_ind CHAR(1) 
	DEFINE l_rec_tenthead RECORD LIKE tenthead.* 
	DEFINE l_msgresp LIKE language.yes_flag 

	WHILE TRUE 
		SELECT * INTO l_rec_tenthead.* FROM tenthead 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		IF status = NOTFOUND 
		OR l_rec_tenthead.status_ind != '3' THEN 
			LET l_msgresp = kandoomsg("P",7068,"") 
			#7068 "A payment cycle does NOT exist OR IS NOT currently running"
			EXIT WHILE 
		END IF 
		LET l_msgresp = kandoomsg("P",1056,"") 
		#1056 Enter Payment Details - ESC TO Continue
		DISPLAY BY NAME l_rec_tenthead.bank_code, 
		l_rec_tenthead.status_ind, 
		l_rec_tenthead.status_datetime, 
		l_rec_tenthead.entry_code 

		INPUT l_payment_ind FROM payment_ind

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","P3C","inp-payment_ind-2") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			AFTER FIELD payment_ind 
				IF l_payment_ind IS NULL THEN 
					LET l_msgresp = kandoomsg("U",9102,"") 
					#9102 "Value must be entered"
					NEXT FIELD payment_ind 
				END IF 
			AFTER INPUT 
				IF (not int_flag OR quit_flag) THEN 
					IF l_payment_ind = '1' THEN 
						IF restart_run(l_rec_tenthead.*) THEN 
							LET l_msgresp = kandoomsg("P",7066,"") 
							#7066 "Payment cycle has been successfully restarted"
							LET int_flag = TRUE 
						ELSE 
							NEXT FIELD payment_ind 
						END IF 
					ELSE 
						IF cancel_run(l_rec_tenthead.*) THEN 
							LET l_msgresp = kandoomsg("P",7067,"") 
							#7067 "Payment cycle has successfully cancelled"
							LET int_flag = TRUE 
						ELSE 
							NEXT FIELD payment_ind 
						END IF 
					END IF 
				END IF 

		END INPUT 
		IF (int_flag OR quit_flag) THEN 
			LET int_flag = FALSE 
			LET quit_flag = FALSE 
			EXIT WHILE 
		END IF 
	END WHILE 
END FUNCTION 


FUNCTION enter_reason() 
	DEFINE l_rec_cancelcheq RECORD LIKE cancelcheq.* 
	DEFINE l_msgresp LIKE language.yes_flag 

	OPEN WINDOW wp164 with FORM "P164" 
	CALL windecoration_p("P164") 

	LET l_msgresp = kandoomsg("P",1074,"") 

	#1074 Enter Cancelation Details - OK TO Continue
	INPUT BY NAME l_rec_cancelcheq.com1_text, 
	l_rec_cancelcheq.com2_text WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","P3C","inp-cancelcheq-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER FIELD com1_text 
			IF l_rec_cancelcheq.com1_text IS NULL THEN 
				LET l_msgresp = kandoomsg("U",9102,"") 
				#9102 "Value must be entered"
				NEXT FIELD com1_text 
			END IF 

	END INPUT 
	CLOSE WINDOW wp164 
	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		LET l_rec_cancelcheq.com1_text = NULL 
	END IF 
	RETURN l_rec_cancelcheq.com1_text 
END FUNCTION 


FUNCTION restart_run(p_rec_tenthead) 
	DEFINE p_rec_tenthead RECORD LIKE tenthead.*
	DEFINE l_ind2 CHAR(1)
	DEFINE l_err_message CHAR(40) 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE try_again CHAR(1)

	OPEN WINDOW p513 with FORM "P513" 
	CALL windecoration_p("P513") 

	LET l_msgresp = kandoomsg("P",1076,"") 

	#1076 Answer Restart Prompts - OK TO Continue
	INPUT l_ind2 FROM ind2 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","P3C","inp-ind2-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER FIELD ind2 
			IF l_ind2 IS NULL THEN 
				LET l_msgresp = kandoomsg("U",9102,"") 
				#9102 "Value must be entered"
				NEXT FIELD ind2 
			END IF 

	END INPUT 
	IF (int_flag OR quit_flag) 
	OR l_ind2 = "N" THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		CLOSE WINDOW p513 
		RETURN FALSE 
	END IF 
	LET l_msgresp = kandoomsg("U",1005,"") 
	#1005 "Updating Database - please wait"
	GOTO bypass 
	LABEL recovery: 
	LET try_again = error_recover(l_err_message, status) 
	IF try_again = "N" THEN 
		CLOSE WINDOW p513 
		RETURN FALSE 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	BEGIN WORK 
		DECLARE c_tenthead CURSOR FOR 
		SELECT * FROM tenthead 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cycle_num = p_rec_tenthead.cycle_num 
		FOR UPDATE 
		OPEN c_tenthead 
		FETCH c_tenthead INTO p_rec_tenthead.* 
		UPDATE tenthead 
		SET status_ind = '1', 
		status_datetime = current, 
		entry_code = glob_rec_kandoouser.sign_on_code 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cycle_num = p_rec_tenthead.cycle_num 
	COMMIT WORK 
	LET int_flag = FALSE 
	LET quit_flag = FALSE 
	CLOSE WINDOW p513 
	RETURN TRUE 
END FUNCTION 


FUNCTION cancel_run(p_rec_tenthead) 
	DEFINE p_rec_tenthead RECORD LIKE tenthead.* 
	DEFINE l_rec_bank RECORD LIKE bank.* 
	DEFINE l_rec_r_cheque RECORD LIKE cheque.* 
	DEFINE l_rec_s_cheque RECORD LIKE cheque.* 
	DEFINE l_rec_tentpays RECORD LIKE tentpays.* 
	DEFINE l_rec_voucher RECORD LIKE voucher.* 
	DEFINE l_rec_voucherpays RECORD LIKE voucherpays.* 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_cancelcheq RECORD LIKE cancelcheq.* 
	DEFINE l_rec_2_apaudit RECORD LIKE apaudit.*
	DEFINE l_rec_apaudit RECORD LIKE apaudit.* 
	DEFINE l_rec_exchangevar RECORD LIKE exchangevar.* 
	DEFINE l_rec_glparms RECORD LIKE glparms.* 
	DEFINE l_save_bal_amt LIKE vendor.bal_amt 
	DEFINE l_save_seq_num LIKE vendor.next_seq_num 
	DEFINE l_discount_amt DECIMAL (16,2) 
	DEFINE l_ind2 CHAR(1)
	DEFINE l_err_message CHAR(100) 
	DEFINE l_inserted SMALLINT 
	DEFINE l_query_text CHAR(2200) 
	DEFINE l_call_status SMALLINT 
	DEFINE l_db_status SMALLINT
	DEFINE l_pr_selection_error SMALLINT
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE try_again CHAR(1)

	OPEN WINDOW p512 at 3,7 with FORM "P512" 
	CALL windecoration_p("P512") 

	LET l_msgresp = kandoomsg("P",1075,"") 
	#1075 Answer Cancellation Prompts - OK TO Continue
	INPUT l_ind2 FROM ind2 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","P3C","inp-ind2-2") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER FIELD ind2 
			IF l_ind2 IS NULL THEN 
				LET l_msgresp = kandoomsg("U",9102,"") 
				#9102 "Value must be entered"
				NEXT FIELD ind2 
			END IF 
		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				IF l_ind2 = 'Y' THEN 
					CALL enter_reason() RETURNING l_rec_cancelcheq.com1_text 
					IF l_rec_cancelcheq.com1_text IS NULL THEN 
						NEXT FIELD ind2 
					ELSE 
						EXIT INPUT 
					END IF 
				ELSE 
					NEXT FIELD ind2 
				END IF 
			END IF 

	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = 0 
		LET quit_flag = 0 
		CLOSE WINDOW p512 
		RETURN FALSE 
	END IF 
	LET l_msgresp = kandoomsg("U",1005,"") 
	#1005 "Updating Database - please wait"
	GOTO bypass 
	LABEL recovery: 
	LET try_again = error_recover(l_err_message, status) 
	IF try_again = "N" THEN 
		CLOSE WINDOW p512 
		RETURN FALSE 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	LET l_inserted = FALSE 
	LET l_query_text = "SELECT * FROM cheque ", 
	" WHERE cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
	" AND bank_code = '", p_rec_tenthead.bank_code, "' " 
	IF (p_rec_tenthead.eft_run_num IS NOT null) 
	AND (p_rec_tenthead.eft_run_num != 0) THEN 
		LET l_inserted = TRUE 
		LET l_query_text = l_query_text clipped, 
		" AND (eft_run_num = ", p_rec_tenthead.eft_run_num, 
		" AND pay_meth_ind = '3')" 
	END IF 
	IF (p_rec_tenthead.cheq_run_num IS NOT null) AND 
	(p_rec_tenthead.cheq_run_num != 0) THEN 
		IF l_inserted THEN 
			# Insert additional "(" - both conditions must be grouped in the same
			# "AND" OR the company selection criteria do NOT apply
			LET l_query_text[50,50] = "(" 
			LET l_query_text = l_query_text clipped, 
			" OR (eft_run_num = ", p_rec_tenthead.cheq_run_num, 
			" AND pay_meth_ind = '1'))" 
		ELSE 
			LET l_inserted = TRUE 
			LET l_query_text = l_query_text clipped, 
			" AND (eft_run_num = ", p_rec_tenthead.cheq_run_num, 
			" AND pay_meth_ind = '1')" 
		END IF 
	END IF 
	BEGIN WORK 
		LET l_pr_selection_error = FALSE 
		DECLARE c2_tenthead CURSOR FOR 
		SELECT * FROM tenthead 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cycle_num = p_rec_tenthead.cycle_num 
		FOR UPDATE 
		OPEN c2_tenthead 
		FETCH c2_tenthead INTO p_rec_tenthead.* 
		IF l_inserted THEN ### IF we do have cheq_run OR eft_run TO process 
			SELECT * INTO l_rec_bank.* FROM bank 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND bank_code = p_rec_tenthead.bank_code 
			PREPARE s_cheque FROM l_query_text 
			DECLARE c_cheque CURSOR with HOLD FOR s_cheque 
			FOREACH c_cheque INTO l_rec_r_cheque.* 
				### Check FOR posted OR reconciled cheques just in CASE the
				### selection criteria have picked up too many payments
				IF l_rec_r_cheque.post_flag = "Y" OR l_rec_r_cheque.recon_flag = "Y" OR 
				l_rec_r_cheque.part_recon_flag = "Y" OR 
				(l_rec_r_cheque.pay_meth_ind = "1" AND l_rec_r_cheque.cheq_code <> 0) THEN 
					LET l_msgresp = kandoomsg("P",7094,"") 
					#7094 Attemting TO cancel posted cheques; Aborted.
					LET l_pr_selection_error = TRUE 
					EXIT FOREACH 
				END IF 
				### Unapply cheque first
				IF l_rec_r_cheque.apply_amt > 0 THEN 
					LET l_err_message = "P3C - Checappl read" 
					DECLARE ch_curs CURSOR FOR 
					SELECT * INTO l_rec_voucherpays.* FROM voucherpays 
					WHERE voucherpays.cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND voucherpays.pay_doc_num = l_rec_r_cheque.doc_num 
					AND voucherpays.vend_code = l_rec_r_cheque.vend_code 
					AND (bank_code = p_rec_tenthead.bank_code OR bank_code IS null) 
					AND rev_flag IS NULL 
					FOR UPDATE 
					LET l_discount_amt = 0 
					FOREACH ch_curs 
						DECLARE vo1_curs CURSOR FOR 
						SELECT * INTO l_rec_voucher.* FROM voucher 
						WHERE vouch_code = l_rec_voucherpays.vouch_code 
						AND voucher.vend_code = l_rec_r_cheque.vend_code 
						AND cmpy_code = glob_rec_kandoouser.cmpy_code 
						FOR UPDATE 
						FOREACH vo1_curs 
							IF l_rec_voucher.taken_disc_amt IS NULL THEN 
								LET l_rec_voucher.taken_disc_amt = 0 
							END IF 
							LET l_rec_voucher.taken_disc_amt = l_rec_voucher.taken_disc_amt 
							- l_rec_voucherpays.disc_amt 
							LET l_rec_voucher.paid_amt = l_rec_voucher.paid_amt 
							- l_rec_voucherpays.apply_amt 
							- l_rec_voucherpays.disc_amt 
							IF l_rec_voucher.paid_amt < 0 THEN 
								ROLLBACK WORK 
								ERROR "Voucher has changed, try again" 
								SLEEP 5 
								EXIT PROGRAM 
							END IF 
							LET l_err_message = "P3C - Voucher UPDATE" 
							UPDATE voucher 
							SET pay_seq_num = pay_seq_num + 1, 
							paid_amt = l_rec_voucher.paid_amt, 
							taken_disc_amt = l_rec_voucher.taken_disc_amt 
							WHERE vouch_code = l_rec_voucherpays.vouch_code 
							AND voucher.vend_code = l_rec_r_cheque.vend_code 
							AND cmpy_code = glob_rec_kandoouser.cmpy_code 
						END FOREACH 
						LET l_discount_amt = l_discount_amt + l_rec_voucherpays.disc_amt 
					END FOREACH 
					# Reverse entry in apaudit AND UPDATE vendor
					#         balance with discount
					DECLARE c_vendor CURSOR FOR 
					SELECT * INTO l_rec_vendor.* FROM vendor 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND vend_code = l_rec_r_cheque.vend_code 
					FOR UPDATE 
					FOREACH c_vendor 
						LET l_rec_vendor.curr_amt = l_rec_vendor.curr_amt + l_discount_amt 
						LET l_rec_vendor.bal_amt = l_rec_vendor.bal_amt + l_discount_amt 
						LET l_rec_vendor.last_payment_date = l_rec_r_cheque.cheq_date 
						LET l_rec_vendor.next_seq_num = l_rec_vendor.next_seq_num + 1 
						LET l_err_message = "P3C - Vendmain UPDATE" 
						UPDATE vendor 
						SET bal_amt = l_rec_vendor.bal_amt, 
						curr_amt = l_rec_vendor.curr_amt, 
						last_payment_date = l_rec_vendor.last_payment_date, 
						next_seq_num = l_rec_vendor.next_seq_num 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND vend_code = l_rec_vendor.vend_code 
					END FOREACH 
					#1869 - Only OUTPUT reversal IF there IS a value
					IF l_discount_amt <> 0 THEN 
						CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,today) RETURNING l_rec_apaudit.year_num, 
						l_rec_apaudit.period_num 
						LET l_rec_apaudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
						LET l_rec_apaudit.tran_date = today 
						LET l_rec_apaudit.vend_code = l_rec_r_cheque.vend_code 
						LET l_rec_apaudit.seq_num = l_rec_vendor.next_seq_num 
						LET l_rec_apaudit.trantype_ind = "CC" 
						LET l_rec_apaudit.source_num = l_rec_r_cheque.doc_num 
						LET l_rec_apaudit.tran_text = "Un-apply Discount" 
						LET l_rec_apaudit.tran_amt = l_discount_amt 
						LET l_rec_apaudit.entry_code = glob_rec_kandoouser.sign_on_code 
						LET l_rec_apaudit.bal_amt = l_rec_vendor.bal_amt 
						LET l_rec_apaudit.currency_code = l_rec_r_cheque.currency_code 
						LET l_rec_apaudit.conv_qty = l_rec_r_cheque.conv_qty 
						LET l_rec_apaudit.entry_date = today 
						LET l_err_message = "P3C - Apdlog INSERT" 
						INSERT INTO apaudit VALUES (l_rec_apaudit.*) 
					END IF 
					#2511 -  END of addition
					# potential bug in following delete IS IF a vendor has two cheques
					# paid TO them with the same cheque # FROM different bank accounts
					# No longer exists as we dont delete but instead create reversal
					# entry AND mark original as reversed so it doesn't get reversed
					# again
					DECLARE c_revvouchpay CURSOR FOR 
					SELECT * FROM voucherpays 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND voucherpays.vend_code = l_rec_r_cheque.vend_code 
					AND pay_doc_num = l_rec_r_cheque.doc_num 
					AND pay_meth_ind = l_rec_r_cheque.pay_meth_ind 
					AND pay_type_code = "CH" 
					AND rev_flag IS NULL 
					AND (bank_code = p_rec_tenthead.bank_code OR bank_code IS null) 
					FOR UPDATE 
					FOREACH c_revvouchpay INTO l_rec_voucherpays.* 
						UPDATE voucherpays 
						SET rev_flag = "Y", 
						remit_doc_num = 0 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND voucherpays.vend_code = l_rec_r_cheque.vend_code 
						AND pay_doc_num = l_rec_r_cheque.doc_num 
						AND seq_num = l_rec_voucherpays.seq_num 
						LET l_rec_voucherpays.apply_amt = 0 - l_rec_voucherpays.apply_amt 
						LET l_rec_voucherpays.disc_amt = 0 - l_rec_voucherpays.disc_amt 
						LET l_rec_voucherpays.seq_num = 0 
						LET l_rec_voucherpays.apply_num = l_rec_voucherpays.apply_num + 1 
						LET l_rec_voucherpays.pay_date = today 
						LET l_rec_voucherpays.rev_flag = "Y" 
						LET l_rec_voucherpays.remit_doc_num = 0 
						INSERT INTO voucherpays VALUES (l_rec_voucherpays.*) 
					END FOREACH 
					DECLARE c_voucherpay2 CURSOR FOR 
					SELECT * FROM voucherpays 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND voucherpays.vend_code = l_rec_r_cheque.vend_code 
					AND (pay_doc_num != l_rec_r_cheque.doc_num 
					AND remit_doc_num = l_rec_r_cheque.doc_num) 
					FOR UPDATE 
					FOREACH c_voucherpay2 INTO l_rec_voucherpays.* 
						UPDATE voucherpays 
						SET remit_doc_num = 0 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND voucherpays.vend_code = l_rec_r_cheque.vend_code 
						AND (pay_doc_num != l_rec_r_cheque.doc_num 
						AND remit_doc_num = l_rec_r_cheque.doc_num) 
					END FOREACH 
					SELECT apply_amt INTO l_rec_r_cheque.apply_amt FROM cheque 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND bank_acct_code = l_rec_bank.acct_code 
					AND doc_num = l_rec_r_cheque.doc_num 
					AND vend_code = l_rec_r_cheque.vend_code 
					AND pay_meth_ind = l_rec_r_cheque.pay_meth_ind 
					UPDATE cheque 
					SET apply_amt = 0, 
					disc_amt = 0 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND bank_acct_code = l_rec_bank.acct_code 
					AND doc_num = l_rec_r_cheque.doc_num 
					AND vend_code = l_rec_r_cheque.vend_code 
					AND pay_meth_ind = l_rec_r_cheque.pay_meth_ind 
					IF l_rec_r_cheque.apply_amt != 0 THEN 
						# The following source IS summing the result of all exchangevars
						# FOR each cheque/voucher combination AND inserting a reversing
						# entry. This IS done because we are unable TO identify the
						# most recent cheque applications TO correctly calculate the
						# exchange variation.
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
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND tran_type2_ind = "CH" 
						AND ref2_num = l_rec_r_cheque.doc_num 
						FOREACH exch_curs 
							SELECT sum(0 - exchangevar_amt) 
							INTO l_rec_exchangevar.exchangevar_amt 
							FROM exchangevar 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND tran_type2_ind = "CH" 
							AND ref2_num = l_rec_r_cheque.doc_num 
							AND ref1_num = l_rec_exchangevar.ref1_num 
							IF l_rec_exchangevar.exchangevar_amt != 0 THEN 
								LET l_rec_exchangevar.posted_flag = "N" 
								INSERT INTO exchangevar VALUES (l_rec_exchangevar.*) 
							END IF 
						END FOREACH 
					END IF 
				END IF 
				### Cancel Cheque
				DECLARE c_delcheque CURSOR FOR 
				SELECT * INTO l_rec_s_cheque.* FROM cheque 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND bank_acct_code = l_rec_bank.acct_code 
				AND vend_code = l_rec_r_cheque.vend_code 
				AND doc_num = l_rec_r_cheque.doc_num 
				FOR UPDATE 
				FOREACH c_delcheque 
					DELETE FROM cheque 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND vend_code = l_rec_s_cheque.vend_code 
					AND doc_num = l_rec_s_cheque.doc_num 
				END FOREACH 
				LET l_err_message = "P3C - Vendmain UPDATE" 
				DECLARE c2_vendor CURSOR FOR 
				SELECT * INTO l_rec_vendor.* FROM vendor 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND vend_code = l_rec_r_cheque.vend_code 
				FOR UPDATE 
				FOREACH c2_vendor 
					LET l_save_bal_amt = l_rec_vendor.bal_amt 
					LET l_rec_vendor.next_seq_num = l_rec_vendor.next_seq_num + 1 
					LET l_save_seq_num = l_rec_vendor.next_seq_num 
					LET l_rec_vendor.bal_amt = l_rec_vendor.bal_amt + l_rec_r_cheque.pay_amt 
					LET l_rec_vendor.curr_amt = l_rec_vendor.curr_amt + l_rec_r_cheque.pay_amt 
					# There may be additional trans FOR withholding tax OR contra amount
					IF l_rec_r_cheque.tax_amt > 0 THEN 
						LET l_rec_vendor.next_seq_num = l_rec_vendor.next_seq_num + 1 
					END IF 
					IF l_rec_r_cheque.contra_amt <> 0 THEN 
						LET l_rec_vendor.next_seq_num = l_rec_vendor.next_seq_num + 1 
					END IF 
					UPDATE vendor 
					SET * = l_rec_vendor.* 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND vend_code = l_rec_vendor.vend_code 
				END FOREACH 
				###Collect the apaudit records AND UPDATE the transaction type###
				DECLARE c_apaudit CURSOR FOR 
				SELECT * FROM apaudit 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND vend_code = l_rec_r_cheque.vend_code 
				AND source_num = l_rec_r_cheque.doc_num 
				AND trantype_ind = "PP" 
				FOR UPDATE 
				FOREACH c_apaudit INTO l_rec_2_apaudit.* 
					UPDATE apaudit 
					SET trantype_ind = "CC" ###cancelled transaction type### 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND vend_code = l_rec_2_apaudit.vend_code 
					AND source_num = l_rec_2_apaudit.source_num 
					AND trantype_ind = "PP" ###in progress transaction type### 
				END FOREACH 
				### build the apaudit reversal FOR the cheque amount ###
				LET l_rec_apaudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET l_rec_apaudit.tran_date = today 
				LET l_rec_apaudit.vend_code = l_rec_r_cheque.vend_code 
				LET l_rec_apaudit.seq_num = l_save_seq_num 
				LET l_rec_apaudit.trantype_ind = "CC" 
				LET l_rec_apaudit.year_num = l_rec_r_cheque.year_num 
				LET l_rec_apaudit.period_num = l_rec_r_cheque.period_num 
				LET l_rec_apaudit.source_num = l_rec_r_cheque.doc_num 
				IF l_rec_r_cheque.pay_amt > 0 THEN 
					LET l_rec_apaudit.tran_text = "Cancel Chq Amt" 
					LET l_rec_apaudit.tran_amt = l_rec_r_cheque.net_pay_amt 
				ELSE 
					LET l_rec_apaudit.tran_text = "Cancel Refund" 
					LET l_rec_apaudit.tran_amt = l_rec_r_cheque.pay_amt 
				END IF 
				LET l_rec_apaudit.entry_code = glob_rec_kandoouser.sign_on_code 
				LET l_rec_apaudit.bal_amt = l_save_bal_amt + l_rec_apaudit.tran_amt 
				LET l_rec_apaudit.currency_code = l_rec_r_cheque.currency_code 
				LET l_rec_apaudit.conv_qty = l_rec_r_cheque.conv_qty 
				LET l_rec_apaudit.entry_date = today 
				LET l_err_message = "P3C - APlog INSERT" 
				INSERT INTO apaudit VALUES (l_rec_apaudit.*) 
				IF l_rec_r_cheque.tax_amt > 0 THEN 
					LET l_rec_apaudit.seq_num = l_rec_apaudit.seq_num + 1 
					LET l_rec_apaudit.tran_text = "Cancel Chq Tax" 
					LET l_rec_apaudit.tran_amt = l_rec_r_cheque.tax_amt 
					LET l_rec_apaudit.bal_amt = l_rec_apaudit.bal_amt + l_rec_r_cheque.tax_amt 
					LET l_err_message = "P3C - Apdlog INSERT" 
					INSERT INTO apaudit VALUES (l_rec_apaudit.*) 
				END IF 
				LET l_rec_cancelcheq.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET l_rec_cancelcheq.vend_code = l_rec_r_cheque.vend_code 
				LET l_rec_cancelcheq.bank_code = l_rec_r_cheque.bank_code 
				LET l_rec_cancelcheq.cheq_code = l_rec_r_cheque.cheq_code 
				LET l_rec_cancelcheq.bank_acct_code = l_rec_r_cheque.bank_acct_code 
				LET l_rec_cancelcheq.entry_code = glob_rec_kandoouser.sign_on_code 
				LET l_rec_cancelcheq.entry_date = today 
				LET l_rec_cancelcheq.orig_posted_flag = l_rec_r_cheque.post_flag 
				LET l_rec_cancelcheq.orig_year_num = l_rec_r_cheque.year_num 
				LET l_rec_cancelcheq.orig_period_num = l_rec_r_cheque.period_num 
				LET l_rec_cancelcheq.cheq_date = l_rec_r_cheque.cheq_date 
				LET l_rec_cancelcheq.pay_amt = l_rec_r_cheque.pay_amt 
				LET l_rec_cancelcheq.cancel_year_num = l_rec_r_cheque.year_num 
				LET l_rec_cancelcheq.cancel_period_num = l_rec_r_cheque.period_num 
				LET l_rec_cancelcheq.cancel_jour_num = 0 
				LET l_rec_cancelcheq.orig_curr_code = l_rec_r_cheque.currency_code 
				LET l_rec_cancelcheq.orig_conv_qty = l_rec_r_cheque.conv_qty 
				LET l_rec_cancelcheq.withhold_tax_ind = l_rec_r_cheque.withhold_tax_ind 
				LET l_rec_cancelcheq.net_pay_amt = l_rec_r_cheque.net_pay_amt 
				LET l_rec_cancelcheq.tax_code = l_rec_r_cheque.tax_code 
				LET l_rec_cancelcheq.tax_per = l_rec_r_cheque.tax_per 
				LET l_rec_cancelcheq.source_ind = l_rec_r_cheque.source_ind 
				LET l_rec_cancelcheq.source_text = l_rec_r_cheque.source_text 
				LET l_rec_cancelcheq.contra_trans_num = l_rec_r_cheque.contra_trans_num 
				LET l_rec_cancelcheq.tax_amt = l_rec_r_cheque.tax_amt 
				LET l_rec_cancelcheq.contra_amt = l_rec_r_cheque.contra_amt 
				LET l_rec_cancelcheq.whtax_rep_ind = l_rec_r_cheque.whtax_rep_ind 
				LET l_rec_cancelcheq.orig_doc_num = l_rec_r_cheque.doc_num 
				INSERT INTO cancelcheq VALUES (l_rec_cancelcheq.*) 
				### Remove all unreported applications as these do NOT pertain TO
				### the original tentative payment entered via P31.
				LET l_err_message = "P3C - Tentpays Deletion" 
				DELETE FROM tentpays 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND vend_code = l_rec_r_cheque.vend_code 
				AND pay_doc_num = l_rec_r_cheque.doc_num 
				AND (vouch_amt = 0 AND taken_disc_amt = 0) 
				LET l_err_message = "P3C - Tentpays Update" 
				DECLARE c_tentpays CURSOR FOR 
				SELECT * FROM tentpays 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND vend_code = l_rec_r_cheque.vend_code 
				AND pay_doc_num = l_rec_r_cheque.doc_num 
				FOR UPDATE 
				FOREACH c_tentpays INTO l_rec_tentpays.* 
					UPDATE tentpays 
					SET status_ind = "1", 
					pay_doc_num = 0, 
					page_num = 0, 
					cheq_code = 0 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND vend_code = l_rec_r_cheque.vend_code 
					AND pay_doc_num = l_rec_r_cheque.doc_num 
				END FOREACH 
				SELECT * INTO l_rec_glparms.* FROM glparms 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND key_code = "1" 
				CASE 
					WHEN (l_rec_r_cheque.contra_amt > 0) 
						CALL contra_invoice(glob_rec_kandoouser.cmpy_code, 
						l_rec_r_cheque.entry_code, 
						l_rec_vendor.contra_cust_code, 
						l_rec_r_cheque.cheq_date, 
						l_rec_r_cheque.year_num, 
						l_rec_r_cheque.period_num, 
						l_rec_glparms.clear_acct_code, 
						(0 - l_rec_r_cheque.contra_amt)) 
						RETURNING l_call_status, 
						l_db_status, 
						l_err_message, 
						l_rec_r_cheque.contra_trans_num 
					WHEN (l_rec_r_cheque.contra_amt < 0) 
						CALL contra_credit(glob_rec_kandoouser.cmpy_code, 
						l_rec_r_cheque.entry_code, 
						l_rec_vendor.contra_cust_code, 
						l_rec_r_cheque.cheq_date, 
						l_rec_r_cheque.year_num, 
						l_rec_r_cheque.period_num, 
						l_rec_glparms.clear_acct_code, 
						(0 - l_rec_r_cheque.contra_amt)) 
						RETURNING l_call_status, 
						l_db_status, 
						l_err_message, 
						l_rec_r_cheque.contra_trans_num 
				END CASE 
				IF l_call_status = -2 THEN 
					LET status = l_db_status 
					GOTO recovery 
				END IF 
				IF l_call_status = -1 THEN 
					CALL errorlog(l_err_message) 
				END IF 
				IF l_rec_r_cheque.contra_amt != 0 THEN 
					LET l_rec_apaudit.seq_num = l_rec_apaudit.seq_num + 1 
					LET l_rec_apaudit.tran_text = "Cancel Contra" 
					LET l_rec_apaudit.tran_amt = l_rec_r_cheque.contra_amt 
					LET l_rec_apaudit.bal_amt = 
					l_rec_apaudit.bal_amt + l_rec_r_cheque.contra_amt 
					LET l_err_message = "Problems Inserting Audit Trail(4) - P3C" 
					INSERT INTO apaudit VALUES (l_rec_apaudit.*) 
				END IF 
			END FOREACH 
		END IF 
		IF l_pr_selection_error THEN 
			ROLLBACK WORK 
		ELSE 
			UPDATE tenthead 
			SET status_ind = '1', 
			status_datetime = current, 
			entry_code = glob_rec_kandoouser.sign_on_code, 
			cheq_date = null, 
			eft_run_num = null, 
			cheq_run_num = NULL 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cycle_num = p_rec_tenthead.cycle_num 
		COMMIT WORK 
	END IF 
	WHENEVER ERROR stop 
	LET int_flag = FALSE 
	LET quit_flag = FALSE 
	CLOSE WINDOW p512 
	IF l_pr_selection_error THEN 
		RETURN FALSE 
	END IF 
	RETURN TRUE 
END FUNCTION 


