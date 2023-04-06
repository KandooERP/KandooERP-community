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
# \file
# \brief module GCEe - Payment Entry, Validation & Apply
###########################################################################

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl"
GLOBALS "../gl/GC_GROUP_GLOBALS.4gl" 
GLOBALS "../gl/GCE_GLOBALS.4gl"
###########################################################################
# MODULE Scope Variables
###########################################################################

###########################################################################
# FUNCTION payment_entry(p_rec_bankstatement,p_seq_num)
#
#
###########################################################################
FUNCTION payment_entry(p_rec_bankstatement,p_seq_num) 
	DEFINE p_rec_bankstatement RECORD LIKE bankstatement.* 
	DEFINE p_seq_num SMALLINT 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_currency_ind char(1) ### (1)-> bank = base & vend = base 
	### (2)-> Bank = base & Vend = foreign
	### (3)-> Bank = foreign & Vend = foreign
	DEFINE l_save_vouchered_amt LIKE bankstatement.tran_amt 
	DEFINE l_save_conv_qty LIKE bankstatement.conv_qty 
	DEFINE l_invalid_input SMALLINT 
	DEFINE ans char(1) 
	DEFINE last_field char(4) 
	DEFINE l_msgresp LIKE language.yes_flag 

	SELECT vendor.* INTO l_rec_vendor.* 
	FROM vendor 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND vend_code = p_rec_bankstatement.ref_code 
	LET p_rec_bankstatement.ref_currency_code = l_rec_vendor.currency_code 
	IF p_rec_bankstatement.bank_currency_code = glob_rec_glparms.base_currency_code THEN 
		IF l_rec_vendor.currency_code = p_rec_bankstatement.bank_currency_code THEN 
			LET l_currency_ind = "1" 
			LET p_rec_bankstatement.conv_qty = 1 
			LET p_rec_bankstatement.other_amt = p_rec_bankstatement.tran_amt 
		ELSE 
			LET l_currency_ind = "2" 
			IF p_rec_bankstatement.conv_qty IS NULL 
			OR p_rec_bankstatement.conv_qty = 0 THEN 
				LET p_rec_bankstatement.conv_qty = get_conv_rate(
					glob_rec_kandoouser.cmpy_code,
					p_rec_bankstatement.ref_currency_code, 
					p_rec_bankstatement.tran_date,
					CASH_EXCHANGE_SELL) 
			END IF 
			
			LET p_rec_bankstatement.other_amt = p_rec_bankstatement.tran_amt * p_rec_bankstatement.conv_qty 
		END IF 
	ELSE 
	
		LET l_currency_ind = "3" 
		LET p_rec_bankstatement.other_amt = p_rec_bankstatement.tran_amt 
		LET p_rec_bankstatement.conv_qty = get_conv_rate(
			glob_rec_kandoouser.cmpy_code,
			p_rec_bankstatement.ref_currency_code, 
			p_rec_bankstatement.tran_date,
			CASH_EXCHANGE_SELL) 
	END IF 
	
	LET l_save_vouchered_amt = p_rec_bankstatement.other_amt 
	LET l_save_conv_qty = p_rec_bankstatement.conv_qty 

	OPEN WINDOW G414 with FORM "G414" 
	CALL windecoration_g("G414") 

	DISPLAY BY NAME 
		p_rec_bankstatement.ref_code, 
		l_rec_vendor.name_text, 
		p_rec_bankstatement.tran_date, 
		p_rec_bankstatement.tran_amt, 
		p_rec_bankstatement.acct_code, 
		p_rec_bankstatement.entry_code, 
		p_rec_bankstatement.entry_date 

	DISPLAY BY NAME 
		p_rec_bankstatement.bank_currency_code, 
		p_rec_bankstatement.ref_currency_code 

	LET l_msgresp=kandoomsg("P",1048,"") 

	#P1048" Enter Payment Details - F8 FOR Account Status"
	INPUT BY NAME 
		p_rec_bankstatement.ref_text, 
		p_rec_bankstatement.ref_num, 
		p_rec_bankstatement.other_amt, 
		p_rec_bankstatement.conv_qty, 
		p_rec_bankstatement.year_num, 
		p_rec_bankstatement.period_num, 
		p_rec_bankstatement.com1_text, 
		p_rec_bankstatement.com2_text WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GCEe","inp-bankstatement") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON KEY (f8) 

			OPEN WINDOW p175 with FORM "P175" 
			CALL windecoration_p("P175") 

			DISPLAY BY NAME 
				l_rec_vendor.curr_amt, 
				l_rec_vendor.over1_amt, 
				l_rec_vendor.over30_amt, 
				l_rec_vendor.bal_amt, 
				l_rec_vendor.over60_amt, 
				l_rec_vendor.over90_amt, 
				l_rec_vendor.last_payment_date, 
				l_rec_vendor.last_vouc_date, 
				l_rec_vendor.last_po_date, 
				l_rec_vendor.last_debit_date 

			CALL eventsuspend() # LET ans = kandoomsg("U",1,"") 

			CLOSE WINDOW P175 

		AFTER FIELD ref_num 
			IF p_rec_bankstatement.ref_num IS NULL OR p_rec_bankstatement.ref_num = 0 THEN 
				LET l_msgresp = kandoomsg("U",9102,"") 
				# Value must be entered
				NEXT FIELD ref_num 
			END IF 
			##
			## "ref_num" (Direct Debit number) IS a unique number
			## FOR this pay_method/bank/company combination AND hence
			## following validation needs TO be performed
			##
			## Check TO ensure Direct Debit does NOT appear elsewhere
			## on this banksheet
			##
			SELECT unique 1 FROM t_bkstate 
			WHERE seq_num != p_seq_num 
			AND entry_type_code = "PA" 
			AND ref_num = p_rec_bankstatement.ref_num 
			IF status = 0 THEN 
				LET l_msgresp = kandoomsg("G",9104,"") 
				#9104" Payment Reference already exists"
				NEXT FIELD ref_num 
			END IF 
			
			##
			## Check TO ensure Direct Debit does NOT appear elsewhere
			## on other banksheets
			##
			SELECT unique 1 FROM bankstatement 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND bank_code = glob_rec_bank.bank_code 
			AND sheet_num != glob_rec_bank.sheet_num 
			AND entry_type_code = "PA" 
			AND ref_num = p_rec_bankstatement.ref_num 
			IF status = 0 THEN 
				LET l_msgresp = kandoomsg("G",9104,"") 
				#9104" Payment Reference already exists"
				NEXT FIELD ref_num 
			END IF 
			
			##
			## Check TO ensure Direct Debit does NOT exist in system.
			## (This check IS seems unnecessary as transaction would need TO
			##  have existed on a banksheet TO get INTO the system).
			##
			SELECT unique 1 FROM cheque 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND bank_code = glob_rec_bank.bank_code 
			AND cheq_code = p_rec_bankstatement.ref_num 
			AND pay_meth_ind = "4" 
			IF status = 0 THEN 
				LET l_msgresp = kandoomsg("G",9104,"") 
				#9104" Payment Reference already exists"
				NEXT FIELD ref_num 
			END IF 
			LET last_field = "ref" 
		
		BEFORE FIELD other_amt 
			IF l_currency_ind != "2" THEN 
				IF last_field = "ref" THEN 
					NEXT FIELD conv_qty 
				ELSE 
					NEXT FIELD ref_num 
				END IF 
			END IF 
		
		AFTER FIELD other_amt 
			IF p_rec_bankstatement.other_amt IS NULL 
			OR p_rec_bankstatement.other_amt = 0 THEN 
				LET p_rec_bankstatement.other_amt = l_save_vouchered_amt 
				LET l_msgresp = kandoomsg("G",9102,"") 
				#9102" Value must be entered
				NEXT FIELD other_amt 
			END IF 
			LET p_rec_bankstatement.conv_qty = p_rec_bankstatement.other_amt 
			/ p_rec_bankstatement.tran_amt 
			DISPLAY BY NAME p_rec_bankstatement.conv_qty 

			LET last_field = "rmit" 

		BEFORE FIELD conv_qty 
			IF l_currency_ind = "1" THEN 
				IF last_field = "year" THEN 
					NEXT FIELD other_amt 
				ELSE 
					NEXT FIELD year_num 
				END IF 
			END IF 

		AFTER FIELD conv_qty 
			IF p_rec_bankstatement.conv_qty IS NULL 
			OR p_rec_bankstatement.conv_qty <= 0 THEN 
				LET l_msgresp = kandoomsg("G",9102,"") 
				#9102" Value must be entered
				LET p_rec_bankstatement.conv_qty = l_save_conv_qty 
				NEXT FIELD conv_qty 
			END IF 
			IF l_currency_ind = "2" THEN 
				LET p_rec_bankstatement.other_amt = p_rec_bankstatement.tran_amt 
				* p_rec_bankstatement.conv_qty 
				DISPLAY BY NAME p_rec_bankstatement.other_amt 

			END IF 
			LET last_field = "conv_qty" 

		AFTER FIELD year_num 
			LET last_field = "year_num" 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				IF p_rec_bankstatement.ref_num IS NULL 
				OR p_rec_bankstatement.ref_num = 0 THEN 
					LET l_msgresp = kandoomsg("G",9102,"") 
					#9102" Value must be entered
					NEXT FIELD ref_num 
				END IF 
				CALL valid_period(glob_rec_kandoouser.cmpy_code,p_rec_bankstatement.year_num, 
				p_rec_bankstatement.period_num,"ap") 
				RETURNING p_rec_bankstatement.year_num, 
				p_rec_bankstatement.period_num, 
				l_invalid_input 
				IF l_invalid_input THEN 
					NEXT FIELD year_num 
				END IF 
				UPDATE t_bkstate 
				SET bank_currency_code = 
				p_rec_bankstatement.bank_currency_code, 
				ref_currency_code = 
				p_rec_bankstatement.ref_currency_code, 
				conv_qty = p_rec_bankstatement.conv_qty, 
				ref_text = p_rec_bankstatement.ref_text, 
				ref_num = p_rec_bankstatement.ref_num, 
				year_num = p_rec_bankstatement.year_num, 
				period_num = p_rec_bankstatement.period_num, 
				other_amt = p_rec_bankstatement.other_amt, 
				type_code = "C", 
				disc_amt = 0, 
				desc_text = p_rec_bankstatement.desc_text, 
				com1_text = p_rec_bankstatement.com1_text, 
				com2_text = p_rec_bankstatement.com2_text 
				WHERE seq_num = p_seq_num 

				MENU "Payment entry" 
					BEFORE MENU 
						CALL publish_toolbar("kandoo","GCEe","menu-payment-entry") 

					ON ACTION "WEB-HELP" 
						CALL onlinehelp(getmoduleid(),null) 

					ON ACTION "actToolbarManager" 
						CALL setuptoolbar() 


					COMMAND "Apply" " Apply payment TO outstanding vouchers" 
						IF NOT apply_payment(p_rec_bankstatement.*,p_seq_num) THEN 
							LET quit_flag = false 
						ELSE 
							LET quit_flag = true 
						END IF 
						EXIT MENU 
					COMMAND "Change" " Change payment details" 
						LET quit_flag = false 
						EXIT MENU 
					COMMAND KEY(interrupt,"E")"Exit" 
						LET quit_flag = true 
						EXIT MENU 
					COMMAND KEY (control-w) 
						CALL kandoohelp("") 
				END MENU 
				IF int_flag OR quit_flag THEN 
					LET int_flag = false 
					LET quit_flag = false 
				ELSE 
					LET l_msgresp=kandoomsg("A",1093,"") 
					#1093,"Payment Details; F8 Account Status")
					NEXT FIELD ref_text 
				END IF 
			END IF 
			--      ON KEY (control-w)
			--         CALL kandoohelp("")
	END INPUT 

	CLOSE WINDOW g414 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 


############################################################
# FUNCTION apply_payment(p_rec_bankstatement,p_seq_num)
#
#
############################################################
FUNCTION apply_payment(p_rec_bankstatement,p_seq_num) 
	DEFINE p_rec_bankstatement RECORD LIKE bankstatement.* 
	DEFINE p_seq_num SMALLINT 
	DEFINE l_rec_voucher RECORD LIKE voucher.* 
	DEFINE l_arr_rec_voucher DYNAMIC ARRAY OF RECORD --array[400] OF RECORD 
		ref_num LIKE bankdetails.ref_num, 
		inv_text LIKE voucher.inv_text, 
		tran_amt LIKE bankdetails.tran_amt, 
		disc_amt LIKE bankdetails.disc_amt, 
		total_amt LIKE voucher.total_amt, 
		paid_amt LIKE voucher.paid_amt 
	END RECORD 
	DEFINE l_arr_vouch_disc_amt DYNAMIC ARRAY OF money(12,2) 
	DEFINE l_arr_orig_paid_amt DYNAMIC ARRAY OF money(12,2) 
	DEFINE l_max_app_amt LIKE bankstatement.tran_amt 
	DEFINE l_applied_amt LIKE bankstatement.tran_amt 
	DEFINE glob_temp_amt LIKE bankstatement.tran_amt 
	DEFINE save_amt LIKE voucher.total_amt 
	DEFINE arr_size INTEGER 
	DEFINE idx INTEGER 
	DEFINE query_text STRING --char(500) 
	DEFINE where_text STRING --char(200) 
	DEFINE l_msgresp LIKE language.yes_flag 

	OPEN WINDOW g415 with FORM "G415" 
	CALL windecoration_g("G415") 

	WHILE true 
		CLEAR FORM 
		SELECT sum(tran_amt) INTO l_applied_amt 
		FROM t_bkdetl 
		WHERE seq_num = p_seq_num 
		IF l_applied_amt IS NULL THEN 
			LET l_applied_amt = 0 
		ELSE 
			IF l_applied_amt > p_rec_bankstatement.other_amt THEN 
				DELETE FROM t_bkdetl 
				WHERE seq_num = p_seq_num 
				CONTINUE WHILE 
			END IF 
		END IF 
		DISPLAY BY NAME p_rec_bankstatement.other_amt 
		DISPLAY l_applied_amt TO applied_amt

		DISPLAY BY NAME p_rec_bankstatement.ref_currency_code 

		IF p_rec_bankstatement.doc_num > 0 THEN 
			SELECT vouch_code INTO l_rec_voucher.vouch_code 
			FROM voucher 
			WHERE vouch_code = p_rec_bankstatement.doc_num 
			AND (total_amt - paid_amt) = p_rec_bankstatement.other_amt 
			AND vend_code = p_rec_bankstatement.ref_code 
			IF status = NOTFOUND THEN 
				LET p_rec_bankstatement.doc_num = 0 
				CONTINUE WHILE 
			ELSE 
				LET where_text = " voucher.vouch_code = ", 
				l_rec_voucher.vouch_code," " 
			END IF 
		ELSE 
			LET l_msgresp=kandoomsg("G",1001,"") 
			CONSTRUCT where_text ON vouch_code FROM ref_num 
				BEFORE CONSTRUCT 
					CALL publish_toolbar("kandoo","GCEe","construct-vouch") 

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
			END CONSTRUCT 

			IF int_flag OR quit_flag THEN 
				EXIT WHILE 
			ELSE 
				LET l_msgresp=kandoomsg("G",1002,"") 
				#G1002" Searching database - please wait"
			END IF 
		END IF 
		LET query_text = 
		"SELECT * FROM voucher ", 
		"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND vend_code = '",p_rec_bankstatement.ref_code,"' ", 
		"AND total_amt != paid_amt ", 
		"AND hold_code = 'NO' ", 
		"AND year_num != 9999 ", 
		"AND ",where_text clipped," ", 
		"ORDER BY vouch_code" 
		PREPARE s_voucher FROM query_text 
		DECLARE c_voucher CURSOR FOR s_voucher 
		LET idx = 1 
		FOREACH c_voucher INTO l_rec_voucher.* 
			LET save_amt = sum_vouch_app(l_rec_voucher.vouch_code,p_seq_num) 
			IF l_rec_voucher.total_amt = (l_rec_voucher.paid_amt + save_amt) THEN 
				CONTINUE FOREACH 
			END IF 
			LET l_arr_rec_voucher[idx].ref_num = l_rec_voucher.vouch_code 
			LET l_arr_rec_voucher[idx].inv_text = l_rec_voucher.inv_text 
			SELECT tran_amt, 
			disc_amt 
			INTO l_arr_rec_voucher[idx].tran_amt, 
			l_arr_rec_voucher[idx].disc_amt 
			FROM t_bkdetl 
			WHERE ref_num = l_rec_voucher.vouch_code 
			AND seq_num = p_seq_num 
			IF status = NOTFOUND THEN 
				LET l_arr_rec_voucher[idx].tran_amt = 0 
				IF p_rec_bankstatement.tran_date > l_rec_voucher.disc_date THEN 
					LET l_arr_rec_voucher[idx].disc_amt = 0 
				ELSE 
					LET l_arr_rec_voucher[idx].disc_amt = 
					l_rec_voucher.poss_disc_amt 
					- l_rec_voucher.taken_disc_amt 
				END IF 
			END IF 
			IF l_arr_rec_voucher[idx].disc_amt < 0 
			OR l_arr_rec_voucher[idx].disc_amt IS NULL THEN 
				LET l_arr_rec_voucher[idx].disc_amt = 0 
			END IF 
			LET l_arr_vouch_disc_amt[idx] = l_arr_rec_voucher[idx].disc_amt 
			LET l_arr_rec_voucher[idx].total_amt = l_rec_voucher.total_amt 
			LET l_arr_orig_paid_amt[idx] = l_rec_voucher.paid_amt + save_amt 
			LET l_arr_rec_voucher[idx].paid_amt = l_arr_orig_paid_amt[idx] 
			+ l_arr_rec_voucher[idx].tran_amt 
			+ l_arr_rec_voucher[idx].disc_amt 
			--         IF idx = 400 THEN
			--            LET l_msgresp = kandoomsg("U",6100,idx)
			--            EXIT FOREACH
			--         ELSE
			LET idx = idx + 1 
			--         END IF
		END FOREACH 
		FREE s_voucher 
		LET arr_size = idx - 1 
		--      CALL set_count(arr_size)
		IF p_rec_bankstatement.doc_num > 0 THEN 
			IF save_amt != 0 THEN 
				LET p_rec_bankstatement.doc_num = 0 
				CONTINUE WHILE 
			END IF 
			LET l_arr_rec_voucher[1].disc_amt = 0 
			DISPLAY l_arr_rec_voucher[1].* TO sr_voucher[1].* 

			SELECT vouch_date, 
			due_date, 
			disc_date 
			INTO l_rec_voucher.vouch_date, 
			l_rec_voucher.due_date, 
			l_rec_voucher.disc_date 
			FROM voucher 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND vouch_code = l_arr_rec_voucher[1].ref_num 
			
			DISPLAY BY NAME l_rec_voucher.vouch_date, 
			l_rec_voucher.due_date, 
			l_rec_voucher.disc_date 


			MENU "Payment application" 
				BEFORE MENU 
					#menu "Payment Entry"
					CALL publish_toolbar("kandoo","GCEe","menu-payment-application") 

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 


				COMMAND "Apply" 
					" Apply this Payment TO this voucher" 
					LET l_arr_rec_voucher[1].tran_amt = p_rec_bankstatement.other_amt 
					LET l_arr_rec_voucher[1].paid_amt = l_arr_rec_voucher[1].paid_amt 
					+ l_arr_rec_voucher[1].tran_amt 
					- save_amt 
					DISPLAY l_arr_rec_voucher[1].* TO sr_voucher[1].* 

					LET l_applied_amt = l_arr_rec_voucher[1].tran_amt 
					DISPLAY l_applied_amt TO applied_amt 

					SLEEP 2 
					EXIT MENU 

				COMMAND "Re select" 
					" Re SELECT Vouchers FOR Payment application" 
					LET p_rec_bankstatement.doc_num = 0 
					EXIT MENU 

				COMMAND KEY(interrupt,"E")"Exit" 
					LET quit_flag = true 
					EXIT MENU 
					--            COMMAND KEY (control-w)
					--               CALL kandoohelp("")
			END MENU 

			DISPLAY "" at 1,1 
			DISPLAY "" at 2,1 
			IF p_rec_bankstatement.doc_num = 0 THEN 
				CONTINUE WHILE 
			END IF 
			IF int_flag OR quit_flag THEN 
				EXIT WHILE 
			END IF 
		ELSE 
			LET l_msgresp = kandoomsg("G",1062,"") 
			OPTIONS INSERT KEY f36 
			OPTIONS DELETE KEY f36 

			INPUT ARRAY l_arr_rec_voucher WITHOUT DEFAULTS FROM sr_voucher.* attributes(unbuffered) 

				BEFORE INPUT 
					CALL publish_toolbar("kandoo","GCEe","inp-arr-voucher") 

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				BEFORE ROW 
					LET idx = arr_curr() 
					#LET scrn = scr_line()
					IF l_arr_rec_voucher[idx].ref_num IS NULL 
					OR l_arr_rec_voucher[idx].ref_num = 0 THEN 
						LET l_msgresp = kandoomsg("G",9001,"") 
						LET l_arr_rec_voucher[idx].ref_num = NULL 
					ELSE 
						SELECT vouch_date, 
						due_date, 
						disc_date 
						INTO l_rec_voucher.vouch_date, 
						l_rec_voucher.due_date, 
						l_rec_voucher.disc_date 
						FROM voucher 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND vouch_code = l_arr_rec_voucher[idx].ref_num 
						DISPLAY BY NAME l_rec_voucher.vouch_date, 
						l_rec_voucher.due_date, 
						l_rec_voucher.disc_date 

					END IF 
					IF (l_arr_rec_voucher[idx].total_amt - l_arr_orig_paid_amt[idx] 
					- l_arr_vouch_disc_amt[idx]) 
					> (p_rec_bankstatement.other_amt - l_applied_amt) THEN 
						LET l_max_app_amt = p_rec_bankstatement.other_amt 
						- l_applied_amt 
						+ l_arr_rec_voucher[idx].tran_amt 
					ELSE 
						LET l_max_app_amt = l_arr_rec_voucher[idx].total_amt 
						- l_arr_orig_paid_amt[idx] 
						- l_arr_vouch_disc_amt[idx] 
						+ l_arr_rec_voucher[idx].tran_amt 
					END IF 
					LET l_rec_voucher.vouch_code = l_arr_rec_voucher[idx].ref_num 
				AFTER FIELD ref_num 
					LET l_arr_rec_voucher[idx].ref_num = l_rec_voucher.vouch_code 
					IF l_rec_voucher.vouch_code IS NOT NULL THEN 
						#DISPLAY l_arr_rec_voucher[idx].ref_num
						#     TO sr_voucher[scrn].ref_num

					END IF 
				BEFORE FIELD tran_amt 
					IF l_arr_rec_voucher[idx].ref_num IS NULL THEN 
						NEXT FIELD ref_num 
					END IF 
					LET save_amt = l_arr_rec_voucher[idx].tran_amt 
					IF l_arr_rec_voucher[idx].tran_amt = 0 THEN 
						LET l_arr_rec_voucher[idx].tran_amt = l_max_app_amt 
						LET l_arr_rec_voucher[idx].disc_amt = l_arr_vouch_disc_amt[idx] 
					END IF 
					LET l_applied_amt = l_applied_amt 
					+ l_arr_rec_voucher[idx].tran_amt 
					- save_amt 
					LET l_arr_rec_voucher[idx].paid_amt = l_arr_orig_paid_amt[idx] 
					+ l_arr_rec_voucher[idx].disc_amt 
					+ l_arr_rec_voucher[idx].tran_amt 
					#DISPLAY l_arr_rec_voucher[idx].*
					#     TO sr_voucher[scrn].*

					DISPLAY l_applied_amt TO applied_amt 

					LET save_amt = l_arr_rec_voucher[idx].tran_amt 
				AFTER FIELD tran_amt 
					CASE 
						WHEN l_arr_rec_voucher[idx].tran_amt IS NULL 
							LET l_msgresp = kandoomsg("U",9102,"") 
							#1037 " Value must be entered.
							LET l_arr_rec_voucher[idx].tran_amt = save_amt 
							NEXT FIELD tran_amt 
						WHEN l_arr_rec_voucher[idx].tran_amt < l_max_app_amt 
							LET l_arr_rec_voucher[idx].disc_amt = 0 
						WHEN l_arr_rec_voucher[idx].tran_amt > (l_max_app_amt + 
							l_arr_vouch_disc_amt[idx]) 
							LET l_msgresp = kandoomsg("P",9057,"") 
							LET l_arr_rec_voucher[idx].tran_amt = l_max_app_amt 
							NEXT FIELD tran_amt 
						OTHERWISE 
							IF (l_arr_rec_voucher[idx].tran_amt 
							+ l_arr_rec_voucher[idx].disc_amt 
							+ l_arr_orig_paid_amt[idx]) 
							> (l_arr_rec_voucher[idx].total_amt) THEN 
								LET l_arr_rec_voucher[idx].disc_amt = 
								l_arr_rec_voucher[idx].total_amt 
								- l_arr_rec_voucher[idx].tran_amt 
								- l_arr_orig_paid_amt[idx] 
							END IF 
					END CASE 
					LET l_arr_rec_voucher[idx].paid_amt = l_arr_orig_paid_amt[idx] 
					+ l_arr_rec_voucher[idx].disc_amt 
					+ l_arr_rec_voucher[idx].tran_amt 
					#DISPLAY l_arr_rec_voucher[idx].*
					#     TO sr_voucher[scrn].*

					LET l_applied_amt = l_applied_amt 
					+ l_arr_rec_voucher[idx].tran_amt 
					- save_amt 
					DISPLAY l_applied_amt TO applied_amt

					NEXT FIELD disc_amt 
				AFTER FIELD disc_amt 
					CASE 
						WHEN l_arr_rec_voucher[idx].disc_amt IS NULL 
							LET l_msgresp = kandoomsg("U",9102,"") 
							#1037 " Value must be entered.
							LET l_arr_rec_voucher[idx].disc_amt = l_arr_vouch_disc_amt[idx] 
							NEXT FIELD disc_amt 
						WHEN l_arr_rec_voucher[idx].disc_amt > l_arr_vouch_disc_amt[idx] 
							error" Maximum discount permitted IS ", 
							l_arr_vouch_disc_amt[idx] USING "$$$$.##"," " 
							LET l_arr_rec_voucher[idx].disc_amt = l_arr_vouch_disc_amt[idx] 
							NEXT FIELD disc_amt 
						WHEN l_arr_rec_voucher[idx].disc_amt < 0 
							LET l_msgresp = kandoomsg("G",9907,"") 
							#9907 "Amount must be positive OR zero"
							LET l_arr_rec_voucher[idx].disc_amt = l_arr_vouch_disc_amt[idx] 
							NEXT FIELD disc_amt 
						OTHERWISE 
							LET glob_temp_amt = l_arr_rec_voucher[idx].tran_amt 
							+ l_arr_rec_voucher[idx].disc_amt 
							+ l_arr_orig_paid_amt[idx] 
							CASE 
								WHEN glob_temp_amt > l_arr_rec_voucher[idx].total_amt 
									LET l_msgresp = kandoomsg("P",9057,"") 
									IF l_arr_rec_voucher[idx].disc_amt = 0 THEN 
										LET l_arr_rec_voucher[idx].disc_amt = 
										l_arr_vouch_disc_amt[idx] 
										LET l_arr_rec_voucher[idx].tran_amt = 
										l_arr_rec_voucher[idx].total_amt 
										- l_arr_orig_paid_amt[idx] 
										- l_arr_rec_voucher[idx].disc_amt 
										NEXT FIELD tran_amt 
									ELSE 
										LET l_arr_rec_voucher[idx].disc_amt = 
										l_arr_rec_voucher[idx].total_amt 
										- l_arr_orig_paid_amt[idx] 
										- l_arr_rec_voucher[idx].tran_amt 
										IF l_arr_rec_voucher[idx].disc_amt < 0 THEN 
											LET l_arr_rec_voucher[idx].disc_amt = 0 
											NEXT FIELD tran_amt 
										ELSE 
											NEXT FIELD disc_amt 
										END IF 
									END IF 
								WHEN glob_temp_amt < l_arr_rec_voucher[idx].total_amt 
									IF l_arr_rec_voucher[idx].disc_amt > 0 THEN 
										LET l_msgresp = kandoomsg("G",9083,"") 
										#9083 "Must fully pay voucher TO claim discount"
										LET l_arr_rec_voucher[idx].disc_amt = 0 
										NEXT FIELD disc_amt 
									END IF 
							END CASE 
					END CASE 
					IF l_applied_amt = p_rec_bankstatement.other_amt THEN 

						MENU " Payment has been fully applied" 
							BEFORE MENU 
								CALL publish_toolbar("kandoo","GCEe","menu-payment-fully-applied") 

							ON ACTION "WEB-HELP" 
								CALL onlinehelp(getmoduleid(),null) 

							ON ACTION "actToolbarManager" 
								CALL setuptoolbar() 

							COMMAND "Continue" 
								EXIT MENU 
							COMMAND KEY(interrupt,"E")"Exit" 
								LET quit_flag = true 
								EXIT MENU 
								--                     COMMAND KEY (control-w)
								--                        CALL kandoohelp("")
						END MENU 

						IF int_flag OR quit_flag THEN 
							LET l_msgresp = kandoomsg("G",1061,"") 
							LET int_flag = false 
							LET quit_flag = false 
						ELSE 
							EXIT INPUT 
						END IF 
					END IF 
					NEXT FIELD ref_num 

				AFTER INPUT 
					IF not(int_flag OR quit_flag) THEN 
						IF l_applied_amt > p_rec_bankstatement.other_amt 
						OR l_applied_amt < 0 THEN 
							LET l_msgresp = kandoomsg("G",9082,"") 
							#9082" Payment has been over applied"
							NEXT FIELD ref_num 
						END IF 
					END IF 
					--            ON KEY (control-w)
					--               CALL kandoohelp("")
			END INPUT 

		END IF 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		ELSE 
			EXIT WHILE 
		END IF 
	END WHILE 

	CLOSE WINDOW g415 
	
	OPTIONS INSERT KEY f1 
	OPTIONS DELETE KEY f2 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 
	
	DELETE FROM t_bkdetl 
	WHERE seq_num = p_seq_num 
	
	FOR idx = 1 TO arr_size 
		IF l_arr_rec_voucher[idx].tran_amt != 0 THEN 
			SELECT conv_qty INTO l_rec_voucher.conv_qty 
			FROM voucher 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND vouch_code = l_arr_rec_voucher[idx].ref_num 
			IF status = NOTFOUND THEN 
				CONTINUE FOR 
			END IF 
			INSERT INTO t_bkdetl VALUES (p_seq_num, 
			p_rec_bankstatement.ref_code, 
			l_arr_rec_voucher[idx].ref_num, 
			"", 
			l_arr_rec_voucher[idx].tran_amt, 
			l_arr_rec_voucher[idx].disc_amt, 
			"", 
			"", 
			l_rec_voucher.conv_qty) 
		END IF 
	END FOR 
	### Do NOT remove following code - <Suse> bug
	IF true THEN 
	END IF 
	UPDATE t_bkstate 
	SET doc_num = p_rec_bankstatement.doc_num 
	WHERE seq_num = p_seq_num 
	RETURN true 
END FUNCTION 


############################################################
# FUNCTION sum_vouch_app(p_vouch_code,p_seq_num)
#
#
# This FUNCTION sums all the unposted voucher applications
# made by other bank's statements OR other sheets FOR this bank.
#
############################################################
FUNCTION sum_vouch_app(p_vouch_code,p_seq_num) 
	DEFINE p_vouch_code LIKE voucher.vouch_code 
	DEFINE p_seq_num SMALLINT 
	DEFINE l_sum_this_sheet LIKE bankdetails.tran_amt 
	DEFINE l_sum_this_bank LIKE bankdetails.tran_amt 
	DEFINE l_sum_other_banks LIKE bankdetails.tran_amt 
	DEFINE l_sum_total_app LIKE bankdetails.tran_amt 
	DEFINE l_msgresp LIKE language.yes_flag 

	SELECT sum(tran_amt + disc_amt) 
	INTO l_sum_this_sheet 
	FROM t_bkdetl 
	WHERE ref_num = p_vouch_code 
	AND seq_num != p_seq_num 
	AND ((select entry_type_code FROM t_bkstate 
	WHERE seq_num = t_bkdetl.seq_num) = "PA") 
	IF l_sum_this_sheet IS NULL THEN 
		LET l_sum_this_sheet = 0 
	END IF 

	SELECT sum(tran_amt + disc_amt) 
	INTO l_sum_this_bank 
	FROM bankdetails 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND bank_code = glob_rec_bank.bank_code 
	AND sheet_num != glob_rec_bank.sheet_num 
	AND ref_num = p_vouch_code 
	AND sheet_num > (select sheet_num 
	FROM bank 
	WHERE bank.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND bank.bank_code = glob_rec_bank.bank_code) 
	AND (select entry_type_code 
	FROM bankstatement 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND bank_code = glob_rec_bank.bank_code 
	AND sheet_num = bankdetails.sheet_num 
	AND seq_num = bankdetails.seq_num) = "PA" 
	IF l_sum_this_bank IS NULL THEN 
		LET l_sum_this_bank = 0 
	END IF 

	SELECT sum(tran_amt + disc_amt) 
	INTO l_sum_other_banks 
	FROM bankdetails 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND bank_code != glob_rec_bank.bank_code 
	AND ref_num = p_vouch_code 
	AND (select entry_type_code 
	FROM bankstatement 
	WHERE cmpy_code = bankdetails.cmpy_code 
	AND bank_code = bankdetails.bank_code 
	AND sheet_num = bankdetails.sheet_num 
	AND seq_num = bankdetails.seq_num ) = "PA" 
	AND sheet_num > (select sheet_num 
	FROM bank 
	WHERE cmpy_code = bankdetails.cmpy_code 
	AND bank_code = bankdetails.bank_code) 
	IF l_sum_other_banks IS NULL THEN 
		LET l_sum_other_banks = 0 
	END IF 
	LET l_sum_total_app = l_sum_this_sheet 
	+ l_sum_this_bank 
	+ l_sum_other_banks 
	RETURN l_sum_total_app 
END FUNCTION 
