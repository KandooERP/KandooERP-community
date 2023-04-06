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
# P68a Applies debits TO outstanding vouchers

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/P6_GROUP_GLOBALS.4gl"
GLOBALS "../ap/P61_GLOBALS.4gl"
###########################################################################
# MODULE Scope Variables
###########################################################################

FUNCTION apply_debit(p_cmpy,p_deb_num) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_deb_num LIKE debithead.debit_num 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_voucher RECORD LIKE voucher.* 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_apaudit RECORD LIKE apaudit.* 
	DEFINE l_rec_voucherpays RECORD LIKE voucherpays.* 
	DEFINE l_arr_deb ARRAY[400] OF RECORD 
		vouch_code LIKE voucher.vouch_code, 
		inv_text LIKE voucher.inv_text, 
		apply_amt LIKE voucherpays.apply_amt, 
		disc_amt LIKE voucherpays.disc_amt, 
		total_amt LIKE voucher.total_amt, 
		paid_amt LIKE voucher.paid_amt 
	END RECORD 
	DEFINE l_rec_debithead RECORD LIKE debithead.* 
	DEFINE l_err_message CHAR(40) 
	DEFINE l_appl_amt DECIMAL(12,2) 
	DEFINE l_discount_amt DECIMAL(12,2)
	DEFINE l_save_dis LIKE voucher.total_amt 
	DEFINE l_save_amt LIKE voucher.total_amt
	DEFINE l_save_num LIKE voucher.vouch_code 
	DEFINE l_base_vouc_apply_amt LIKE voucherpays.apply_amt 
	DEFINE l_base_debt_apply_amt LIKE voucherpays.apply_amt
	DEFINE l_rec_exchangevar RECORD LIKE exchangevar.* 
	DEFINE l_cycle_in_progress SMALLINT 
	DEFINE l_arr_size SMALLINT
	DEFINE l_latep SMALLINT
	DEFINE l_payment SMALLINT	
	DEFINE l_id_flag SMALLINT
	DEFINE try_again CHAR(1)
	DEFINE i,idx, scrn SMALLINT

	SELECT * INTO l_rec_debithead.* FROM debithead 
	WHERE cmpy_code = p_cmpy 
	AND debit_num = p_deb_num 
	IF status = NOTFOUND THEN 
		LET l_msgresp = kandoomsg("P",9058,p_deb_num) 
		#9058 Debit number does NOT exist
		RETURN 
	END IF 
	#now done it CALL init_p_ap() #init P/AP module
	#SELECT * INTO pr_apparms.* FROM apparms
	# WHERE cmpy_code = p_cmpy
	#   AND parm_code = "1"
	SELECT * INTO l_rec_vendor.* FROM vendor 
	WHERE cmpy_code = p_cmpy 
	AND vend_code = l_rec_debithead.vend_code 
	IF l_rec_debithead.apply_amt >= l_rec_debithead.total_amt THEN 
		LET l_msgresp = kandoomsg("P",7027,"") 
		#9058 Debit number applied
		RETURN 
	END IF 
	DECLARE vouchcurs CURSOR FOR 
	SELECT * FROM voucher 
	WHERE cmpy_code = p_cmpy 
	AND vend_code = l_rec_debithead.vend_code 
	AND total_amt <> paid_amt 
	AND post_flag <> "V" 
	AND hold_code IS NULL #and (hold_code = "NO" OR hold_code IS null) 
	ORDER BY vouch_code 
	OPEN vouchcurs 
	LET idx = 0 
	LET l_cycle_in_progress = false 
	FOREACH vouchcurs INTO l_rec_voucher.* 
		SELECT unique 1 FROM tentpays 
		WHERE vend_code = l_rec_debithead.vend_code 
		AND vouch_code = l_rec_voucher.vouch_code 
		AND cmpy_code = p_cmpy 
		IF status != NOTFOUND THEN 
			LET l_cycle_in_progress = true 
			CONTINUE FOREACH 
		END IF 
		LET idx = idx + 1 
		LET l_arr_deb[idx].vouch_code = l_rec_voucher.vouch_code 
		LET l_arr_deb[idx].inv_text = l_rec_voucher.inv_text 
		LET l_arr_deb[idx].apply_amt = 0 
		IF l_rec_debithead.post_flag = "Y" THEN 
			LET l_arr_deb[idx].disc_amt = 0 
		ELSE 
			IF l_rec_debithead.debit_date > l_rec_voucher.disc_date THEN 
				LET l_arr_deb[idx].disc_amt = 0 
			ELSE 
				LET l_arr_deb[idx].disc_amt = l_rec_voucher.poss_disc_amt 
				- l_rec_voucher.taken_disc_amt 
				IF l_arr_deb[idx].disc_amt < 0 THEN 
					LET l_arr_deb[idx].disc_amt = 0 
				END IF 
			END IF 
		END IF 
		LET l_arr_deb[idx].total_amt = l_rec_voucher.total_amt 
		LET l_arr_deb[idx].paid_amt = l_rec_voucher.paid_amt 
		IF idx = 300 THEN 
			EXIT FOREACH 
		END IF 
	END FOREACH 
	CALL set_count(idx) 
	IF l_cycle_in_progress THEN 
		LET l_msgresp = kandoomsg("P",7085,"") 
		#7885 "All vouchers may NOT be listed "
	END IF 
	IF idx = 0 THEN 
		LET l_msgresp = kandoomsg("P",9198,"") 
		#9007 "No outstanding vouchers"
		RETURN 
	END IF 
	OPEN WINDOW wp171 with FORM "P171" 
	CALL windecoration_p("P171") 

	DISPLAY BY NAME l_rec_vendor.currency_code 
	attribute (green) 
	DISPLAY BY NAME l_rec_debithead.vend_code, 
	l_rec_vendor.name_text, 
	l_rec_debithead.debit_num, 
	l_rec_debithead.total_amt, 
	l_rec_debithead.dist_amt, 
	l_rec_debithead.apply_amt, 
	l_rec_debithead.debit_date 

	IF idx = 300 THEN 
		LET l_msgresp = kandoomsg("U",9010,idx) 
		#9010 First idx rows selected
	END IF 
	LET l_msgresp = kandoomsg("P",1080,"") 
	#1080 " RETURN on line TO apply; OK WHEN finished"
	OPTIONS INSERT KEY f36, 
	DELETE KEY f38 

	INPUT ARRAY l_arr_deb WITHOUT DEFAULTS FROM sr_debit.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","P68a","inp-arr-debit-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			LET l_id_flag = 0 
			IF l_arr_deb[idx].apply_amt IS NULL THEN 
				LET l_arr_deb[idx].apply_amt = 0 
			END IF 
			IF l_arr_deb[idx].disc_amt IS NULL THEN 
				LET l_arr_deb[idx].disc_amt = 0 
			END IF 
			LET l_save_amt = l_arr_deb[idx].apply_amt 
			LET l_save_dis = l_arr_deb[idx].disc_amt 
			LET l_save_num = l_arr_deb[idx].vouch_code 
		AFTER ROW 
			IF fgl_lastkey() = fgl_keyval("nextpage") THEN 
				IF l_arr_deb[idx+6].vouch_code IS NULL 
				OR l_arr_deb[idx+6].vouch_code = 0 THEN 
					LET l_msgresp = kandoomsg("U",9001,"") 
					#9001 No more rows in this direction
					NEXT FIELD vouch_code 
				END IF 
			END IF 
			IF ((fgl_lastkey() = fgl_keyval("down")) 
			AND (l_arr_deb[idx+1].vouch_code IS NULL 
			OR l_arr_deb[idx+1].vouch_code = 0)) THEN 
				LET l_msgresp = kandoomsg("W",9001,"") 
				#9001 No more Rows in direction
				NEXT FIELD vouch_code 
			END IF 
		AFTER FIELD inv_text 
			NEXT FIELD apply_amt 
		BEFORE FIELD apply_amt 
			IF l_rec_debithead.total_amt < l_rec_debithead.apply_amt THEN 
				MESSAGE "Debit has been over applied" 
				attribute(yellow) 
			END IF 
			LET l_arr_deb[idx].apply_amt = l_rec_debithead.total_amt 
			- l_rec_debithead.apply_amt 
			+ l_save_amt 
			# see IF too much TO apply, IF so adjust
			IF l_arr_deb[idx].apply_amt > l_arr_deb[idx].total_amt 
			+ l_save_amt 
			- l_arr_deb[idx].paid_amt 
			- l_save_dis THEN 
				LET l_arr_deb[idx].apply_amt = l_arr_deb[idx].total_amt 
				+ l_save_amt 
				- l_arr_deb[idx].paid_amt 
				- l_save_dis 
			END IF 
			#cant claim discount IF part paying
			IF l_arr_deb[idx].apply_amt < l_arr_deb[idx].total_amt 
			+ l_save_amt 
			- l_arr_deb[idx].paid_amt THEN 
				LET l_arr_deb[idx].disc_amt = 0 
			END IF 
			LET l_arr_deb[idx].paid_amt = l_arr_deb[idx].paid_amt - l_save_amt 
			LET l_rec_debithead.apply_amt = l_rec_debithead.apply_amt - l_save_amt 
			LET l_save_amt = 0 
			DISPLAY l_arr_deb[idx].disc_amt, 
			l_arr_deb[idx].apply_amt, 
			l_arr_deb[idx].total_amt, 
			l_arr_deb[idx].paid_amt 
			TO sr_debit[scrn].disc_amt, 
			sr_debit[scrn].apply_amt, 
			sr_debit[scrn].total_amt, 
			sr_debit[scrn].paid_amt 

		AFTER FIELD apply_amt 
			IF l_arr_deb[idx].apply_amt >= 0 THEN 
			ELSE 
				LET l_msgresp = kandoomsg("P",9193,"") 
				#9193 Payment amount must be greater than zero
				NEXT FIELD apply_amt 
			END IF 
			IF l_arr_deb[idx].apply_amt > l_arr_deb[idx].total_amt 
			- l_arr_deb[idx].paid_amt THEN 
				LET l_msgresp = kandoomsg("P",9194,"") 
				#9194 "Payment will overapply the voucher"
				NEXT FIELD apply_amt 
			END IF 
			IF l_arr_deb[idx].apply_amt > l_rec_debithead.total_amt 
			- l_rec_debithead.apply_amt THEN 
				LET l_msgresp = kandoomsg("P",9195,"") 
				#9195 "Payment will overapply the debit"
				NEXT FIELD apply_amt 
			END IF 
			NEXT FIELD disc_amt 
		AFTER FIELD disc_amt 
			IF l_arr_deb[idx].disc_amt >= 0 THEN 
			ELSE 
				LET l_msgresp = kandoomsg("P",9196,"") 
				#9196 " Amount of discount must be positive OR zero"
				NEXT FIELD apply_amt 
			END IF 
			IF l_arr_deb[idx].paid_amt + l_arr_deb[idx].apply_amt + l_arr_deb[idx].disc_amt 
			- l_save_dis - l_save_amt > l_arr_deb[idx].total_amt THEN 
				LET l_msgresp = kandoomsg("P",9194,"") 
				#9194 "Payment will overapply the voucher"
				NEXT FIELD apply_amt 
			END IF 
			IF l_arr_deb[idx].disc_amt != 0 THEN 
				IF l_rec_debithead.post_flag = "Y" THEN 
					LET l_msgresp = kandoomsg("P",9197,"") 
					#9197 " Debit has been posted, no discounts allowed"
					NEXT FIELD apply_amt 
				END IF 
				IF l_arr_deb[idx].disc_amt > l_save_dis THEN 
					ERROR "Too much discount taken, maximum displayed" 
					LET l_arr_deb[idx].disc_amt = l_save_dis 
				END IF 
				IF l_arr_deb[idx].apply_amt < l_arr_deb[idx].total_amt 
				- l_arr_deb[idx].paid_amt THEN 
					ERROR "Must fully pay TO claim discount" 
					NEXT FIELD disc_amt 
				END IF 
			END IF 
			LET l_rec_debithead.apply_amt = l_rec_debithead.apply_amt 
			+ l_arr_deb[idx].apply_amt 
			LET l_arr_deb[idx].paid_amt = l_arr_deb[idx].paid_amt 
			+ l_arr_deb[idx].apply_amt 
			+ l_arr_deb[idx].disc_amt 
			LET l_arr_deb[idx].vouch_code = l_save_num 
			DISPLAY l_rec_debithead.apply_amt, 
			l_arr_deb[idx].paid_amt 
			TO apply_amt, 
			sr_debit[scrn].paid_amt 

			# just in CASE they changed the voucher number
			DISPLAY l_arr_deb[idx].vouch_code 
			TO sr_debit[scrn].vouch_code 
			attribute(white) 
			LET l_save_amt = l_arr_deb[idx].apply_amt 
			LET l_save_dis = l_arr_deb[idx].disc_amt 
			NEXT FIELD vouch_code 
		BEFORE DELETE 
			IF l_arr_deb[idx].apply_amt IS NULL THEN 
				LET l_arr_deb[idx].apply_amt = 0 
			END IF 
			LET l_rec_debithead.apply_amt = l_rec_debithead.apply_amt 
			- l_arr_deb[idx].apply_amt 
			DISPLAY l_rec_debithead.apply_amt 
			TO apply_amt 
			attribute(magenta) 
		AFTER INPUT 
			LET l_arr_size = arr_count() 

	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		CLOSE WINDOW wp171 
		RETURN 
	ELSE 
		GOTO bypass 
		LABEL recovery: 
		LET try_again = error_recover(l_err_message, status) 
		IF try_again != "Y" THEN 
			EXIT PROGRAM 
		END IF 
		LABEL bypass: 
		WHENEVER ERROR GOTO recovery 
		BEGIN WORK 
			LET l_err_message = "P68 - Debhead UPDATE" 
			DECLARE dm_curs CURSOR FOR 
			SELECT * INTO l_rec_debithead.* FROM debithead 
			WHERE cmpy_code = p_cmpy 
			AND debit_num = l_rec_debithead.debit_num 
			FOR UPDATE 
			FOREACH dm_curs 
				LET l_rec_debithead.appl_seq_num = l_rec_debithead.appl_seq_num + 1 
				LET l_appl_amt = 0 
				LET l_discount_amt = 0 
				LET l_payment = 0 
				LET l_latep = 0 
				FOR i = 1 TO l_arr_size 
					IF l_arr_deb[i].apply_amt = 0 
					OR l_arr_deb[i].vouch_code = 0 THEN 
					ELSE 
						DECLARE vo1_curs CURSOR FOR 
						SELECT * INTO l_rec_voucher.* FROM voucher 
						WHERE vouch_code = l_arr_deb[i].vouch_code 
						AND cmpy_code = p_cmpy 
						FOR UPDATE 
						FOREACH vo1_curs 
							LET l_rec_voucher.paid_amt = l_rec_voucher.paid_amt 
							+ l_arr_deb[i].apply_amt 
							+ l_arr_deb[i].disc_amt 
							IF l_rec_voucher.paid_amt > l_rec_voucher.total_amt THEN 
								ROLLBACK WORK 
								LET l_msgresp = kandoomsg("P",7083,"") 
								#97083 "Voucher has changed, try again"
								EXIT PROGRAM 
							END IF 
							IF l_rec_voucher.taken_disc_amt IS NULL THEN 
								LET l_rec_voucher.taken_disc_amt = 0 
							END IF 
							LET l_rec_voucher.pay_seq_num = l_rec_voucher.pay_seq_num + 1 
							LET l_rec_voucher.taken_disc_amt = l_rec_voucher.taken_disc_amt 
							+ l_arr_deb[i].disc_amt 
							IF l_rec_voucher.total_amt = l_rec_voucher.paid_amt THEN 
								LET l_rec_voucher.paid_date = l_rec_debithead.debit_date 
							END IF 
							LET l_err_message = "P68 - Vouchead UPDATE" 
							UPDATE voucher 
							SET paid_amt = l_rec_voucher.paid_amt, 
							pay_seq_num = l_rec_voucher.pay_seq_num, 
							taken_disc_amt = l_rec_voucher.taken_disc_amt, 
							paid_date = l_rec_voucher.paid_date 
							WHERE CURRENT OF vo1_curs 
							LET l_appl_amt = l_appl_amt + l_arr_deb[i].apply_amt 
							LET l_discount_amt = l_discount_amt + l_arr_deb[i].disc_amt 
							LET l_payment = l_payment + 1 
							LET l_rec_voucherpays.cmpy_code = p_cmpy 
							LET l_rec_voucherpays.vend_code = l_rec_debithead.vend_code 
							LET l_rec_voucherpays.vouch_code = l_rec_voucher.vouch_code 
							LET l_rec_voucherpays.seq_num = 0 
							LET l_rec_voucherpays.pay_num = l_rec_debithead.debit_num 
							LET l_rec_voucherpays.apply_num = l_rec_voucher.pay_seq_num 
							LET l_rec_voucherpays.pay_type_code = "DB" 
							LET l_rec_voucherpays.pay_date = today 
							LET l_rec_voucherpays.apply_amt = l_arr_deb[i].apply_amt 
							LET l_rec_voucherpays.disc_amt = l_arr_deb[i].disc_amt 
							LET l_rec_voucherpays.withhold_tax_ind = "0" 
							LET l_rec_voucherpays.tax_code = NULL 
							LET l_rec_voucherpays.tax_per = 0 
							LET l_rec_voucherpays.bank_code = NULL 
							LET l_rec_voucherpays.rev_flag = NULL 
							LET l_rec_voucherpays.pay_meth_ind = NULL 
							LET l_rec_voucherpays.pay_doc_num = 0 
							LET l_rec_voucherpays.remit_doc_num = 0 
							LET l_err_message = "P68 - Voucpay INSERT" 
							INSERT INTO voucherpays VALUES (l_rec_voucherpays.*) 
							LET l_base_vouc_apply_amt = 0 
							LET l_base_debt_apply_amt = 0 
							IF l_rec_voucher.conv_qty IS NOT NULL THEN 
								IF l_rec_voucher.conv_qty != 0 THEN 
									IF l_rec_debithead.conv_qty != l_rec_voucher.conv_qty THEN 
										LET l_base_vouc_apply_amt = l_rec_voucherpays.apply_amt 
										/ l_rec_voucher.conv_qty 
										LET l_base_debt_apply_amt = l_rec_voucherpays.apply_amt 
										/ l_rec_debithead.conv_qty 
									END IF 
								END IF 

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
								LET l_rec_exchangevar.currency_code = 
								l_rec_voucher.currency_code 
								LET l_rec_exchangevar.exchangevar_amt = 
								l_base_debt_apply_amt 
								- l_base_vouc_apply_amt 
								LET l_rec_exchangevar.posted_flag = "N" 
								IF l_rec_exchangevar.exchangevar_amt != 0 THEN 
									INSERT INTO exchangevar VALUES (l_rec_exchangevar.*) 
								END IF 
							END IF 
						END FOREACH 
					END IF 
				END FOR 
				IF l_discount_amt > 0 THEN 
					LET l_err_message = "P68 - Vendmain UPDATE" 
					DECLARE curr_amts CURSOR FOR 
					SELECT * INTO l_rec_vendor.* FROM vendor 
					WHERE cmpy_code = p_cmpy 
					AND vend_code = l_rec_debithead.vend_code 
					FOR UPDATE 
					FOREACH curr_amts 
						LET l_rec_vendor.curr_amt = l_rec_vendor.curr_amt 
						- l_arr_deb[idx].disc_amt 
						LET l_rec_vendor.bal_amt = l_rec_vendor.bal_amt 
						- l_arr_deb[idx].disc_amt 
						LET l_rec_vendor.last_payment_date = l_rec_debithead.debit_date 
						LET l_rec_vendor.next_seq_num = l_rec_vendor.next_seq_num + 1 
						LET l_err_message = "P68 - Vendmain UPDATE" 
						UPDATE vendor 
						SET bal_amt = l_rec_vendor.bal_amt, 
						curr_amt = l_rec_vendor.curr_amt, 
						last_payment_date = l_rec_vendor.last_payment_date, 
						next_seq_num = l_rec_vendor.next_seq_num 
						WHERE CURRENT OF curr_amts 
					END FOREACH 
					#now done it CALL init_p_ap() #init P/AP module
					#SELECT apparms.* INTO pr_apparms.* FROM apparms
					# WHERE apparms.parm_code = "1"
					#   AND apparms.cmpy_code = p_cmpy
					#IF STATUS = NOTFOUND THEN
					#   LET l_msgresp = kandoomsg("P",5016,"")
					#   #5016 "Parameters Not Found, See Menu PZP"
					#   rollback work
					#   EXIT PROGRAM
					#END IF
					CALL db_period_what_period(p_cmpy, today) RETURNING l_rec_apaudit.year_num, 
					l_rec_apaudit.period_num 
					LET l_rec_apaudit.cmpy_code = p_cmpy 
					LET l_rec_apaudit.tran_date = today 
					LET l_rec_apaudit.vend_code = l_rec_debithead.vend_code 
					LET l_rec_apaudit.seq_num = l_rec_vendor.next_seq_num 
					LET l_rec_apaudit.trantype_ind = "DB" 
					LET l_rec_apaudit.source_num = l_rec_debithead.debit_num 
					LET l_rec_apaudit.tran_text = "Apply Discount" 
					LET l_rec_apaudit.tran_amt = 0 - l_discount_amt 
					LET l_rec_apaudit.entry_code = l_rec_debithead.entry_code 
					LET l_rec_apaudit.bal_amt = l_rec_vendor.bal_amt 
					LET l_rec_apaudit.currency_code = l_rec_debithead.currency_code 
					LET l_rec_apaudit.conv_qty = l_rec_debithead.conv_qty 
					LET l_rec_apaudit.entry_date = today 
					LET l_err_message = "P68 - Apdlog INSERT" 
					INSERT INTO apaudit VALUES (l_rec_apaudit.*) 
				END IF 
				LET l_err_message = "P68b - Cheque Header UPDATE" 
				LET l_rec_debithead.apply_amt = l_rec_debithead.apply_amt 
				+ l_appl_amt 
				LET l_rec_debithead.disc_amt = l_rec_debithead.disc_amt 
				+ l_discount_amt 
				IF l_rec_debithead.apply_amt > l_rec_debithead.total_amt THEN 
					LET l_msgresp = kandoomsg("P",7084,"") 
					#7084 "Applied amount > debit amount, try again"
					ROLLBACK WORK 
					CLOSE WINDOW wp171 
					RETURN 
				END IF 
				UPDATE debithead 
				SET * = l_rec_debithead.* 
				WHERE CURRENT OF dm_curs 
			END FOREACH 
		COMMIT WORK 
	END IF 
	CLOSE WINDOW wp171 
END FUNCTION 


