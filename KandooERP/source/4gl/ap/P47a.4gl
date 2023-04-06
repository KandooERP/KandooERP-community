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



# FUNCTION P47a allows the user TO edit cheques

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_P4_GLOBALS.4gl" 


FUNCTION input_cheque(p_cmpy,p_bank_acct_code,p_cheq_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_bank_acct_code LIKE cheque.bank_acct_code 
	DEFINE p_cheq_code LIKE cheque.cheq_code 
	DEFINE l_rec_r_cheque RECORD LIKE cheque.* 
	DEFINE l_rec_s_cheque RECORD LIKE cheque.* 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_bank RECORD LIKE bank.* 
	DEFINE l_rec_apaudit RECORD LIKE apaudit.* 
	DEFINE l_pay_amt LIKE cheque.pay_amt 
	DEFINE l_save_amt LIKE cheque.pay_amt 
	DEFINE l_err_message CHAR(40) 
	DEFINE l_invalid_period INTEGER 
	DEFINE l_base_currency LIKE glparms.base_currency_code 
	DEFINE l_last_foreign_amt LIKE cheque.pay_amt 
	DEFINE l_rec_formonly RECORD
		foreign_amt LIKE cheque.pay_amt
	END RECORD
	--DEFINE l_foreign_amt LIKE cheque.pay_amt
	DEFINE l_last_conv_qty LIKE cheque.conv_qty 
	DEFINE l_set_up_conv_qty SMALLINT 
	DEFINE l_curr_code LIKE cheque.currency_code 
	DEFINE l_s_tax_amt LIKE cheque.net_pay_amt 
	DEFINE l_r_tax_amt LIKE cheque.net_pay_amt
	DEFINE l_tax_code LIKE cheque.tax_code 
	DEFINE l_msgresp LIKE language.yes_flag 

	SELECT base_currency_code 
	INTO l_base_currency 
	FROM glparms 
	WHERE key_code = "1" 
	AND cmpy_code = p_cmpy 
	IF sqlca.sqlcode = NOTFOUND THEN 
		LET l_msgresp = kandoomsg("P",5007,"") 
		#General Ledger Parameters NOT SET up - Refer GZP
		EXIT PROGRAM 
	END IF 
	SELECT * INTO l_rec_r_cheque.* 
	FROM cheque 
	WHERE cmpy_code = p_cmpy 
	AND bank_acct_code = p_bank_acct_code 
	AND cheq_code = p_cheq_code 
	AND pay_meth_ind = "1" 
	CASE 
		WHEN sqlca.sqlcode = NOTFOUND 
			LET l_msgresp = kandoomsg("P",9130,"") 
			#9130 "Cheque NOT found"
			RETURN 
		WHEN l_rec_r_cheque.post_flag = "Y" 
			LET l_msgresp = kandoomsg("P",9514,"") 
			#9514 " Cheque has been posted, no changes allowed"
			RETURN 
		WHEN l_rec_r_cheque.post_flag = "H" 
			LET l_msgresp = kandoomsg("P",9515,"") 
			# " Cheque IS on hold, no changes allowed"
			RETURN 
		WHEN l_rec_r_cheque.rec_state_num IS NOT NULL 
			LET l_msgresp = kandoomsg("P",9516,"") 
			#9516 " Cheque has been presented, no changes allowed"
			RETURN 
		WHEN l_rec_r_cheque.pay_amt = 0 
			LET l_msgresp = kandoomsg("P",9045,"") 
			#9045 Cheque IS FOR Tax Refund - no edit allowed
			RETURN 
		WHEN l_rec_r_cheque.contra_amt != 0 
			LET l_msgresp = kandoomsg("P",9085,"") 
			#9045 Cheque has contra deduction - no edit allowed
			RETURN 
		OTHERWISE 
			LET l_rec_s_cheque.* = l_rec_r_cheque.* 
			LET l_save_amt = l_rec_r_cheque.pay_amt 
			## Keep orig cheq amt as a test TO determine whether another
			## user edits cheq between here AND the the commit
	END CASE 
	SELECT vendor.* INTO l_rec_vendor.* 
	FROM vendor 
	WHERE vend_code = l_rec_r_cheque.vend_code 
	AND cmpy_code = p_cmpy 
	IF sqlca.sqlcode = NOTFOUND THEN 
		LET l_msgresp = kandoomsg("P",9501,"") 
		#9501 " Vendor NOT found "
		RETURN 
	END IF 
	SELECT * INTO l_rec_bank.* 
	FROM bank 
	WHERE acct_code = l_rec_r_cheque.bank_acct_code 
	AND cmpy_code = p_cmpy 
	OPEN WINDOW p137 at 2,3 with FORM "P137" 
	CALL windecoration_p("P137") 

	LET l_rec_formonly.foreign_amt = 0 
	LET l_curr_code = l_rec_r_cheque.currency_code 
	MESSAGE " Enter Cheque Details - F8 FOR Account Status" 

	INPUT BY NAME l_rec_r_cheque.cheq_date, 
		l_rec_r_cheque.withhold_tax_ind, 
		l_rec_r_cheque.tax_code, 
		l_rec_r_cheque.pay_amt, 
		l_rec_r_cheque.net_pay_amt, 
		l_rec_formonly.foreign_amt, 
		l_rec_r_cheque.conv_qty, 
		l_rec_r_cheque.com3_text, 
		l_rec_r_cheque.year_num, 
		l_rec_r_cheque.period_num, 
		l_rec_r_cheque.com1_text, 
		l_rec_r_cheque.com2_text 
		WITHOUT DEFAULTS 
	--FROM l_rec_r_cheque.cheq_date, 
	--cheque.withhold_tax_ind, 
	--cheque.tax_code, 
	--cheque.pay_amt, 
	--cheque.net_pay_amt, 
	--foreign_amt, 
	--cheque.conv_qty, 
	--cheque.com3_text, 
	--cheque.year_num, 
	--cheque.period_num, 
	--cheque.com1_text, 
	--cheque.com2_text

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","P47a","inp-cheque-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON KEY (control-b) infield (tax_code) 
			LET l_rec_r_cheque.tax_code = show_tax(p_cmpy) 
			DISPLAY BY NAME l_rec_r_cheque.tax_code 

			NEXT FIELD tax_code 


		ON KEY (F8) 
			OPEN WINDOW p175 at 6,3 with FORM "P175" 
			CALL windecoration_p("P175") 

			DISPLAY BY NAME l_rec_vendor.curr_amt, 
			l_rec_vendor.over1_amt, 
			l_rec_vendor.over30_amt, 
			l_rec_vendor.bal_amt, 
			l_rec_vendor.over60_amt, 
			l_rec_vendor.over90_amt, 
			l_rec_vendor.last_payment_date, 
			l_rec_vendor.last_vouc_date, 
			l_rec_vendor.last_po_date, 
			l_rec_vendor.last_debit_date 

			CALL eventsuspend() 
			# LET l_msgresp = kandoomsg("U",1,"")

			CLOSE WINDOW p175 

		BEFORE FIELD cheq_date 
			DISPLAY BY NAME l_rec_r_cheque.vend_code, 
			l_rec_r_cheque.cheq_code, 
			l_rec_vendor.name_text, 
			l_rec_r_cheque.withhold_tax_ind, 
			l_rec_r_cheque.tax_code, 
			l_rec_r_cheque.tax_per, 
			l_rec_r_cheque.pay_amt, 
			l_rec_r_cheque.net_pay_amt, 
			l_rec_r_cheque.currency_code, 
			l_rec_r_cheque.bank_currency_code, 
			l_rec_r_cheque.conv_qty, 
			l_rec_r_cheque.bank_code, 
			l_rec_bank.name_acct_text, 
			l_rec_r_cheque.bank_acct_code, 
			l_rec_r_cheque.entry_code, 
			l_rec_r_cheque.cheq_date, 
			l_rec_r_cheque.entry_date, 
			l_rec_r_cheque.com1_text, 
			l_rec_r_cheque.com2_text, 
			l_rec_r_cheque.com3_text, 
			l_rec_r_cheque.year_num, 
			l_rec_r_cheque.period_num ,
			l_rec_formonly.foreign_amt

		AFTER FIELD cheq_date 
			IF l_rec_r_cheque.cheq_date IS NULL THEN 
				LET l_msgresp = kandoomsg("U",9102,"") 
				#9102 "Value must be entered"
				LET l_rec_r_cheque.cheq_date = l_rec_s_cheque.cheq_date 
				NEXT FIELD cheq_date 
			END IF 
			IF l_set_up_conv_qty THEN 
				CALL get_conv_rate(p_cmpy,l_rec_vendor.currency_code, 
				l_rec_r_cheque.cheq_date, "B") 
				RETURNING l_rec_r_cheque.conv_qty 
				DISPLAY BY NAME l_rec_r_cheque.conv_qty 

			END IF 
			CALL db_period_what_period(p_cmpy, l_rec_r_cheque.cheq_date) 
			RETURNING l_rec_r_cheque.year_num, 
			l_rec_r_cheque.period_num 
			DISPLAY BY NAME l_rec_r_cheque.period_num, 
			l_rec_r_cheque.year_num 

		BEFORE FIELD withhold_tax_ind 
			IF l_rec_r_cheque.apply_amt != 0 
			OR (l_rec_vendor.drop_flag IS NULL OR 
			l_rec_vendor.drop_flag != "Y") THEN 
				IF fgl_lastkey() = fgl_keyval("up") THEN 
					NEXT FIELD previous 
				ELSE 
					NEXT FIELD NEXT 
				END IF 
			END IF 
		AFTER FIELD withhold_tax_ind 
			IF l_rec_r_cheque.withhold_tax_ind IS NULL 
			OR (NOT (l_rec_r_cheque.withhold_tax_ind matches "[0123]")) THEN 
				LET l_msgresp = kandoomsg("P",9112,"") 
				#9112 Withholding Tax Indicator must be 0, 1 ,2 OR 3
				NEXT FIELD withhold_tax_ind 
			END IF 
			IF l_rec_r_cheque.withhold_tax_ind = "0" THEN 
				LET l_rec_r_cheque.tax_code = NULL 
				LET l_rec_r_cheque.tax_per = 0 
				DISPLAY BY NAME l_rec_r_cheque.tax_code, 
				l_rec_r_cheque.tax_per 

			END IF 
		BEFORE FIELD tax_code 
			LET l_tax_code = l_rec_r_cheque.tax_code 
			IF l_rec_r_cheque.withhold_tax_ind = "0" THEN 
				IF fgl_lastkey() = fgl_keyval("UP") THEN 
					NEXT FIELD previous 
				ELSE 
					NEXT FIELD NEXT 
				END IF 
			END IF 
		AFTER FIELD tax_code 
			IF l_rec_r_cheque.tax_code != l_tax_code THEN 
				IF l_rec_r_cheque.tax_code IS NULL THEN 
					LET l_rec_r_cheque.tax_per = 0 
				ELSE 
					IF l_rec_vendor.drop_flag != "Y" 
					OR l_rec_r_cheque.withhold_tax_ind = 0 THEN 
						SELECT tax_per 
						INTO l_rec_r_cheque.tax_per 
						FROM tax 
						WHERE cmpy_code = p_cmpy 
						AND tax_code = l_rec_r_cheque.tax_code 
						IF sqlca.sqlcode = NOTFOUND THEN 
							LET l_msgresp = kandoomsg("P",9106,"") 
							#9106 Tax Code NOT found - try window
							NEXT FIELD tax_code 
						END IF 
					END IF 
					IF l_rec_r_cheque.tax_per IS NULL THEN 
						LET l_rec_r_cheque.tax_per = 0 
					END IF 
				END IF 
				CALL wtaxcalc(l_rec_r_cheque.pay_amt, 
				l_rec_r_cheque.tax_per, 
				l_rec_r_cheque.withhold_tax_ind, 
				p_cmpy) 
				RETURNING l_rec_r_cheque.net_pay_amt, 
				l_r_tax_amt 
				DISPLAY BY NAME l_rec_r_cheque.tax_per, 
				l_rec_r_cheque.net_pay_amt 

			END IF 
		BEFORE FIELD pay_amt 
			LET l_pay_amt = l_rec_r_cheque.pay_amt 
		AFTER FIELD pay_amt 
			IF l_rec_r_cheque.pay_amt IS NULL THEN 
				LET l_msgresp = kandoomsg("U",9102,"") 
				#9102 "Value must be entered"
				NEXT FIELD pay_amt 
			END IF 
			IF l_rec_r_cheque.pay_amt <= 0 THEN 
				LET l_msgresp = kandoomsg("P",9011,"") 
				#9011 "Cheque amount must be greater than 0"
				NEXT FIELD pay_amt 
			END IF 
			IF l_rec_r_cheque.pay_amt != l_pay_amt THEN 
				IF l_rec_r_cheque.apply_amt > l_rec_r_cheque.pay_amt THEN 
					LET l_msgresp = kandoomsg("P",9518,"") 
					#9011 "Cheque amount must be greater than applied amount "
					NEXT FIELD pay_amt 
				END IF 
				CALL wtaxcalc(l_rec_r_cheque.pay_amt, 
				l_rec_r_cheque.tax_per, 
				l_rec_r_cheque.withhold_tax_ind, 
				p_cmpy) 
				RETURNING l_rec_r_cheque.net_pay_amt, 
				l_r_tax_amt 
				DISPLAY BY NAME l_rec_r_cheque.net_pay_amt 

			END IF 
		BEFORE FIELD net_pay_amt 
			IF l_rec_vendor.drop_flag != "Y" OR l_rec_r_cheque.withhold_tax_ind = 0 THEN 
				NEXT FIELD foreign_amt 
			END IF 
		AFTER FIELD net_pay_amt 
			IF l_rec_r_cheque.net_pay_amt IS NULL THEN 
				LET l_rec_r_cheque.net_pay_amt = 0 
				DISPLAY BY NAME l_rec_r_cheque.net_pay_amt 

			END IF 
			IF l_rec_r_cheque.net_pay_amt > l_rec_r_cheque.pay_amt THEN 
				LET l_msgresp = kandoomsg("P",9131,"") 
				#9131 Net Pay Amount must be less than Gross Pay Amount
				NEXT FIELD net_pay_amt 
			END IF 
			LET l_r_tax_amt = l_rec_r_cheque.pay_amt - l_rec_r_cheque.net_pay_amt 
			LET l_rec_r_cheque.tax_per = (l_r_tax_amt / l_rec_r_cheque.pay_amt) * 100 
			DISPLAY BY NAME l_rec_r_cheque.tax_per 

		BEFORE FIELD foreign_amt 
			LET l_last_foreign_amt = l_rec_formonly.foreign_amt 
			IF l_rec_vendor.currency_code = l_base_currency THEN 
				--IF fgl_lastkey() = fgl_keyval("up") THEN 
				--	NEXT FIELD pay_amt 
				--ELSE 
				--	NEXT FIELD com3_text 
				--END IF 
			ELSE 
				IF l_rec_r_cheque.bank_currency_code != l_base_currency THEN 
				--	IF fgl_lastkey() = fgl_keyval("up") THEN 
				--		NEXT FIELD pay_amt 
				--	ELSE 
				--		NEXT FIELD conv_qty 
				--	END IF 
				END IF 
			END IF 
		AFTER FIELD foreign_amt 
			IF l_rec_formonly.foreign_amt IS NULL THEN 
				LET l_rec_formonly.foreign_amt = 0 
				DISPLAY BY NAME l_rec_formonly.foreign_amt

			END IF 
			IF l_last_foreign_amt != l_rec_formonly.foreign_amt AND l_rec_formonly.foreign_amt = 0 THEN 
				CALL get_conv_rate(p_cmpy,l_rec_vendor.currency_code, l_rec_r_cheque.cheq_date, "B") 
				RETURNING l_rec_r_cheque.conv_qty 
				DISPLAY BY NAME l_rec_r_cheque.conv_qty 
				LET l_set_up_conv_qty = true 
			END IF 
			IF l_rec_r_cheque.bank_currency_code = l_base_currency AND l_rec_vendor.currency_code != l_base_currency THEN 
				IF l_rec_r_cheque.pay_amt != 0 AND l_rec_formonly.foreign_amt != 0 THEN 
					LET l_rec_r_cheque.conv_qty = l_rec_r_cheque.pay_amt / l_rec_formonly.foreign_amt 
					DISPLAY BY NAME l_rec_r_cheque.conv_qty 
					LET l_set_up_conv_qty = false 
				END IF 
			END IF 
		
			AFTER FIELD period_num 
			CALL valid_period(p_cmpy, l_rec_r_cheque.year_num,l_rec_r_cheque.period_num, "ap") 
			RETURNING l_rec_r_cheque.year_num, l_rec_r_cheque.period_num, l_invalid_period 
			IF l_invalid_period THEN 
				NEXT FIELD year_num 
			END IF 
		
			BEFORE FIELD conv_qty 
			LET l_last_conv_qty = l_rec_r_cheque.conv_qty 
			IF l_rec_r_cheque.bank_currency_code = l_base_currency AND l_rec_vendor.currency_code = l_base_currency THEN 
				--IF fgl_lastkey() = fgl_keyval("up") THEN 
				--	NEXT FIELD foreign_amt 
				--ELSE 
				--	NEXT FIELD com3_text 
				--END IF 
			END IF 
			IF l_rec_r_cheque.bank_currency_code != l_base_currency AND l_rec_vendor.currency_code != l_base_currency THEN 
				IF l_rec_r_cheque.pay_amt != 0 AND l_rec_formonly.foreign_amt != 0 THEN 
					--IF fgl_lastkey() = fgl_keyval("up") THEN 
					--	NEXT FIELD foreign_amt 
					--ELSE 
					--	NEXT FIELD com3_text 
					--END IF 
				END IF 
			END IF 
			IF l_rec_r_cheque.bank_currency_code = l_base_currency AND l_rec_vendor.currency_code != l_base_currency THEN 
				IF l_rec_r_cheque.pay_amt != 0 AND l_rec_formonly.foreign_amt != 0 THEN 
					LET l_rec_r_cheque.conv_qty = l_rec_r_cheque.pay_amt / l_rec_formonly.foreign_amt 
					DISPLAY BY NAME l_rec_r_cheque.conv_qty 
					LET l_set_up_conv_qty = false 
					--IF fgl_lastkey() = fgl_keyval("up") THEN 
					--	NEXT FIELD foreign_amt 
					--ELSE 
					--	NEXT FIELD com3_text 
					--END IF 
				END IF 
			END IF 
		
		AFTER FIELD conv_qty 
			IF l_rec_r_cheque.conv_qty IS NULL THEN 
				LET l_msgresp = kandoomsg("U",9102,"") 
				#9102 "Value must be entered"
				NEXT FIELD conv_qty 
			END IF 
			IF l_rec_r_cheque.conv_qty <= 0 THEN 
				LET l_msgresp = kandoomsg("P",9012,"") 
				#9102 " Exchange Rate must be greater than zero"
				NEXT FIELD conv_qty 
			END IF 
			IF l_last_conv_qty != l_rec_r_cheque.conv_qty THEN 
				LET l_set_up_conv_qty = false 
			END IF 
		
		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				IF l_rec_r_cheque.tax_code IS NULL THEN 
					LET l_rec_r_cheque.tax_per = 0 
				ELSE 
					SELECT tax_per 
					INTO l_rec_r_cheque.tax_per 
					FROM tax 
					WHERE cmpy_code = p_cmpy 
					AND tax_code = l_rec_r_cheque.tax_code 
					IF sqlca.sqlcode = NOTFOUND THEN 
						LET l_msgresp = kandoomsg("P",9106,"") 
						#9106 Tax Code NOT found - try window
						NEXT FIELD tax_code 
					END IF 
					IF l_rec_r_cheque.tax_per IS NULL THEN 
						LET l_rec_r_cheque.tax_per = 0 
					END IF 
				END IF 
				CALL valid_period(p_cmpy, l_rec_r_cheque.year_num, 
				l_rec_r_cheque.period_num, "ap") 
				RETURNING l_rec_r_cheque.year_num, 
				l_rec_r_cheque.period_num, 
				l_invalid_period 
				IF l_invalid_period THEN 
					NEXT FIELD year_num 
				END IF 
				GOTO bypass 
				LABEL recovery: 
				IF error_recover(l_err_message,status) = "N" THEN 
					EXIT INPUT 
				END IF 
				LABEL bypass: 
				WHENEVER ERROR GOTO recovery 
				BEGIN WORK 
					LET l_err_message = "P47 - Chechead UPDATE" 
					DECLARE c_cheque CURSOR FOR 
					SELECT * FROM cheque 
					WHERE cmpy_code = p_cmpy 
					AND bank_acct_code = l_rec_r_cheque.bank_acct_code 
					AND cheq_code = l_rec_r_cheque.cheq_code 
					AND pay_meth_ind = "1" 
					FOR UPDATE 
					OPEN c_cheque 
					FETCH c_cheque INTO l_rec_s_cheque.* 
					IF l_rec_s_cheque.pay_amt != l_save_amt THEN 
						ROLLBACK WORK 
						LET l_rec_r_cheque.* = l_rec_s_cheque.* 
						LET l_msgresp = kandoomsg("P",9519,"") 
						#9519 Cheque Detail Altered by Another User - Re Edit Cheque
						NEXT FIELD cheq_date 
					END IF 
					# Reset the tax amount before updating the cheque.  Note that this
					# calculation IS only valid FOR cheques without contra amounts.
					# Prior code prevents edit of cheques with non-zero contra amounts.
					LET l_rec_r_cheque.tax_amt = 
					l_rec_r_cheque.pay_amt - l_rec_r_cheque.net_pay_amt 
					UPDATE cheque SET * = l_rec_r_cheque.* 
					WHERE cmpy_code = p_cmpy 
					AND bank_acct_code = l_rec_r_cheque.bank_acct_code 
					AND cheq_code = l_rec_r_cheque.cheq_code 
					AND vend_code = l_rec_r_cheque.vend_code 
					AND pay_meth_ind = "1" 
					IF l_rec_r_cheque.pay_amt != l_rec_s_cheque.pay_amt OR l_rec_r_cheque.net_pay_amt != l_rec_s_cheque.net_pay_amt THEN 
						LET l_s_tax_amt = 
						l_rec_s_cheque.pay_amt - l_rec_s_cheque.net_pay_amt 
						LET l_err_message = "P47 - Vendor RECORD Lock" 
						DECLARE c_vendor CURSOR FOR 
						SELECT * FROM vendor 
						WHERE cmpy_code = p_cmpy 
						AND vend_code = l_rec_r_cheque.vend_code 
						FOR UPDATE 
						OPEN c_vendor 
						FETCH c_vendor INTO l_rec_vendor.* 
						## Increment Vendor Attributes FOR apaudit
						LET l_rec_vendor.bal_amt = l_rec_vendor.bal_amt + l_rec_s_cheque.net_pay_amt 
						LET l_rec_vendor.next_seq_num = l_rec_vendor.next_seq_num + 1 
						## SET up apaudit
						LET l_rec_apaudit.cmpy_code = p_cmpy 
						LET l_rec_apaudit.tran_date = l_rec_s_cheque.cheq_date 
						LET l_rec_apaudit.vend_code = l_rec_s_cheque.vend_code 
						LET l_rec_apaudit.seq_num = l_rec_vendor.next_seq_num 
						LET l_rec_apaudit.trantype_ind = "CH" 
						LET l_rec_apaudit.year_num = l_rec_s_cheque.year_num 
						LET l_rec_apaudit.period_num = l_rec_s_cheque.period_num 
						LET l_rec_apaudit.source_num = l_rec_s_cheque.cheq_code 
						LET l_rec_apaudit.tran_text = "Backout Chq Amt" 
						LET l_rec_apaudit.tran_amt = l_rec_s_cheque.net_pay_amt 
						LET l_rec_apaudit.entry_code = l_rec_s_cheque.entry_code 
						LET l_rec_apaudit.bal_amt = l_rec_vendor.bal_amt 
						LET l_rec_apaudit.currency_code = l_rec_s_cheque.currency_code 
						LET l_rec_apaudit.conv_qty = l_rec_s_cheque.conv_qty 
						LET l_rec_apaudit.entry_date = today 
						LET l_err_message = "P47 - APlog INSERT" 
						INSERT INTO apaudit VALUES (l_rec_apaudit.*) 
						## IF tax applicable, INSERT tax entry
						IF l_s_tax_amt != 0 THEN 
							## Increment Vendor Attributes FOR apaudit
							LET l_rec_vendor.bal_amt = l_rec_vendor.bal_amt+ l_s_tax_amt 
							LET l_rec_vendor.next_seq_num = l_rec_vendor.next_seq_num + 1 
							## SET up apaudit
							LET l_rec_apaudit.seq_num = l_rec_vendor.next_seq_num 
							LET l_rec_apaudit.tran_text = "Backout Chq Tax" 
							LET l_rec_apaudit.tran_amt = l_s_tax_amt 
							LET l_rec_apaudit.bal_amt = l_rec_vendor.bal_amt 
							INSERT INTO apaudit VALUES (l_rec_apaudit.*) 
						END IF 
						## Increment Vendor Attributes FOR apaudit
						LET l_r_tax_amt = l_rec_r_cheque.pay_amt - l_rec_r_cheque.net_pay_amt 
						LET l_rec_vendor.bal_amt = l_rec_vendor.bal_amt - l_rec_r_cheque.net_pay_amt 
						LET l_rec_vendor.next_seq_num = l_rec_vendor.next_seq_num + 1 
						## SET up apaudit
						LET l_rec_apaudit.cmpy_code = p_cmpy 
						LET l_rec_apaudit.tran_date = l_rec_r_cheque.cheq_date 
						LET l_rec_apaudit.vend_code = l_rec_r_cheque.vend_code 
						LET l_rec_apaudit.seq_num = l_rec_vendor.next_seq_num 
						LET l_rec_apaudit.trantype_ind = "CH" 
						LET l_rec_apaudit.year_num = l_rec_r_cheque.year_num 
						LET l_rec_apaudit.period_num = l_rec_r_cheque.period_num 
						LET l_rec_apaudit.source_num = l_rec_r_cheque.cheq_code 
						LET l_rec_apaudit.tran_text = "Edit Cheque Amt" 
						LET l_rec_apaudit.tran_amt = 0 - l_rec_r_cheque.net_pay_amt 
						LET l_rec_apaudit.entry_code = l_rec_r_cheque.entry_code 
						LET l_rec_apaudit.bal_amt = l_rec_vendor.bal_amt 
						LET l_rec_apaudit.currency_code = l_rec_r_cheque.currency_code 
						LET l_rec_apaudit.conv_qty = l_rec_r_cheque.conv_qty 
						LET l_rec_apaudit.entry_date = today 
						LET l_err_message = "P47 - APlog INSERT" 
						INSERT INTO apaudit VALUES (l_rec_apaudit.*) 
						## IF tax applicable, INSERT tax entry
						IF l_r_tax_amt != 0 THEN 
							## Increment Vendor Attributes FOR apaudit
							LET l_rec_vendor.bal_amt = l_rec_vendor.bal_amt - l_r_tax_amt 
							LET l_rec_vendor.next_seq_num = l_rec_vendor.next_seq_num + 1 
							## SET up apaudit
							LET l_rec_apaudit.seq_num = l_rec_vendor.next_seq_num 
							LET l_rec_apaudit.tran_text = "Edit Chq Tax" 
							LET l_rec_apaudit.tran_amt = 0 - l_r_tax_amt 
							LET l_rec_apaudit.bal_amt = l_rec_vendor.bal_amt 
							INSERT INTO apaudit VALUES (l_rec_apaudit.*) 
						END IF 
						#### UPDATE the vendor
						LET l_err_message = "P47 - Vendor RECORD Update" 
						IF l_rec_r_cheque.cheq_date > l_rec_vendor.last_payment_date OR l_rec_vendor.last_payment_date IS NULL THEN 
							LET l_rec_vendor.last_payment_date = l_rec_r_cheque.cheq_date 
						END IF 
						LET l_rec_vendor.curr_amt = l_rec_vendor.curr_amt + l_rec_s_cheque.pay_amt - l_rec_r_cheque.pay_amt 
						UPDATE vendor SET * = l_rec_vendor.* 
						WHERE cmpy_code = p_cmpy 
						AND vend_code = l_rec_r_cheque.vend_code 
					END IF 
				COMMIT WORK 
				WHENEVER ERROR stop 
			END IF 
	END INPUT 
	LET int_flag = false 
	LET quit_flag = false 
	CLOSE WINDOW p137 
END FUNCTION 