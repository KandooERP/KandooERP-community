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



#
{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module P41a - Entry of AP cheque
#
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/../ap/P_AP_P4_GLOBALS.4gl" 

############################################################
# FUNCTION enter_cheq(p_cmpy,p_kandoouser_sign_on_code,p_vouch_code,
#                              p_vend_code,# vend FROM voucher
#                              p_cheq_amt, # Amt FROM voucher
#                              p_conv_qty) # Conv.qty FROM voucher
#
#
#
############################################################
FUNCTION enter_cheq(p_cmpy,p_kandoouser_sign_on_code,p_vouch_code, 
	p_vend_code,# vend FROM voucher 
	p_cheq_amt, # amt FROM voucher 
	p_conv_qty) # conv.qty FROM voucher 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code 
	DEFINE p_vouch_code LIKE voucher.vouch_code 
	DEFINE p_vend_code LIKE vendor.vend_code 
	DEFINE p_cheq_amt LIKE cheque.pay_amt 
	DEFINE p_conv_qty LIKE cheque.conv_qty 
	DEFINE l_msgresp LIKE language.yes_flag 
	#DEFINE pr_apparms RECORD LIKE apparms.*
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_cheque RECORD LIKE cheque.* 
	DEFINE l_rec_voucher RECORD LIKE voucher.* 
	DEFINE l_rec_apaudit RECORD LIKE apaudit.* 
	DEFINE l_rec_bank RECORD LIKE bank.* 
	DEFINE l_err_message CHAR(40) 
	DEFINE l_invalid_period INTEGER 
	DEFINE l_base_currency LIKE glparms.base_currency_code 
	DEFINE l_tax_amt LIKE cheque.net_pay_amt 
	DEFINE l_foreign_amt DECIMAL(16,2) 
	DEFINE l_save_amt DECIMAL(16,2) 
	DEFINE l_save_qty FLOAT 
	DEFINE l_disc_amt LIKE voucher.poss_disc_amt 
	DEFINE l_disc_taken_ind CHAR(1) 
	DEFINE l_recalc_ind CHAR(1) 
	DEFINE l_save_date LIKE cheque.cheq_date 
	DEFINE l_vendor_tax_ind LIKE cheque.withhold_tax_ind 

	#now done it CALL init_p_ap() #init P/AP module
	#SELECT * INTO pr_apparms.* FROM apparms
	# WHERE parm_code = "1"
	#   AND cmpy_code = p_cmpy
	#IF STATUS = NOTFOUND THEN
	#   LET l_msgresp=kandoomsg("P",5016,"")
	#   #5016 "Parameters Not Found, See Menu PZP"
	#   EXIT PROGRAM
	#END IF

	SELECT base_currency_code INTO l_base_currency FROM glparms 
	WHERE key_code = "1" 
	AND cmpy_code = p_cmpy 
	IF status = NOTFOUND THEN 
		LET l_msgresp=kandoomsg("P",5007,"") 
		#5007 "Parameters Not Found, See Menu GZP"
		EXIT PROGRAM 
	END IF 

	OPEN WINDOW p137 with FORM "P137" 
	CALL windecoration_p("P137") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	LET l_msgresp=kandoomsg("P",1048,"") 
	#P1048 Enter Cheque Details - ESC TO Continue
	INITIALIZE l_rec_cheque.* TO NULL 
	LET l_rec_cheque.conv_qty = NULL 
	LET l_rec_cheque.cheq_code = NULL 
	LET l_rec_cheque.cheq_date = today 
	LET l_rec_cheque.pay_amt = 0 
	LET l_rec_cheque.disc_amt = 0 
	LET l_foreign_amt = 0 
	LET l_rec_cheque.entry_date = today 
	LET l_rec_cheque.entry_code = p_kandoouser_sign_on_code 
	CALL db_period_what_period(p_cmpy,l_rec_cheque.cheq_date) 
	RETURNING l_rec_cheque.year_num, 
	l_rec_cheque.period_num 

	INPUT 
	l_rec_cheque.vend_code, 
	l_rec_bank.bank_code, 
	l_rec_cheque.cheq_code, 
	l_rec_cheque.cheq_date, 
	l_rec_cheque.withhold_tax_ind, 
	l_rec_cheque.tax_code, 
	l_rec_cheque.pay_amt, 
	l_rec_cheque.net_pay_amt, 
	l_foreign_amt, 
	l_rec_cheque.conv_qty, 
	l_rec_cheque.com3_text, 
	l_rec_cheque.year_num, 
	l_rec_cheque.period_num, 
	l_rec_cheque.bank_acct_code, 
	l_rec_cheque.com1_text, 
	l_rec_cheque.com2_text, 
	l_rec_cheque.entry_code, 
	l_rec_cheque.entry_date WITHOUT DEFAULTS 
	FROM 
	vend_code, 
	bank_code, 
	cheq_code, 
	cheq_date, 
	withhold_tax_ind, 
	tax_code, 
	pay_amt, 
	net_pay_amt, 
	foreign_amt, 
	conv_qty, 
	com3_text, 
	year_num, 
	period_num, 
	bank_acct_code, 
	com1_text, 
	com2_text, 
	entry_code, 
	entry_date 
	ATTRIBUTE(UNBUFFERED) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","P41A","inp-cheque-1") 
			CALL DIALOG.SetFieldTouched("vend_code", true) #we do this TO support INPUT wrap - original code prepares data in BEFORE FIELD 
			CALL DIALOG.SetFieldTouched("bank_code", true) #we do this TO support INPUT wrap 

			IF p_vouch_code IS NOT NULL #if voucher code IS empty OR it IS marked NOT TO be dropped/deletes, you will NOT able TO change this FIELD deduction code 
			OR (l_rec_vendor.drop_flag IS NULL OR 
			l_rec_vendor.drop_flag != "Y") THEN 
				CALL set_fieldAttribute_readOnly("withhold_tax_ind",TRUE) 
			ELSE 
				CALL set_fieldAttribute_readOnly("withhold_tax_ind",FALSE) 
			END IF 

			IF l_rec_cheque.withhold_tax_ind = "0" THEN 
				CALL set_fieldAttribute_readOnly("tax_code",TRUE) 
			ELSE 
				CALL set_fieldAttribute_readOnly("tax_code",FALSE) 
			END IF 




		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON KEY (control-b) infield (vend_code) 
			LET l_rec_cheque.vend_code = show_vend(p_cmpy,l_rec_cheque.vend_code) 
			NEXT FIELD vend_code 

		ON KEY (control-b) infield (bank_code) 
			CALL show_bank(p_cmpy) RETURNING l_rec_bank.bank_code, 
			l_rec_bank.acct_code 
			IF l_rec_bank.bank_code IS NOT NULL THEN 
				LET l_rec_cheque.bank_code = l_rec_bank.bank_code 
				NEXT FIELD bank_code 
			END IF 
		ON KEY (control-b) infield (tax_code) 
			LET l_rec_cheque.tax_code = show_tax(p_cmpy) 
			NEXT FIELD tax_code 


		ON KEY (F8) --account status 
			OPEN WINDOW p175 with FORM "P175" 
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

			#LET l_msgresp = kandoomsg("U",1,"")
			CALL eventsuspend() 
			#1 Any Key TO Continue

			CLOSE WINDOW p175 

		BEFORE FIELD vend_code 
			IF p_vend_code IS NOT NULL THEN 
				IF field_touched(vend_code) THEN 
					#CALL DIALOG.SetFieldTouched("vend_code", FALSE)  #we do this TO support input wrap

					LET l_rec_cheque.vend_code = p_vend_code 
					SELECT * INTO l_rec_vendor.* 
					FROM vendor 
					WHERE cmpy_code = p_cmpy 
					AND vend_code = l_rec_cheque.vend_code 
					IF status = NOTFOUND THEN 
						#P9014 Logic Error: Vendor Not found
						LET l_msgresp=kandoomsg("P",9014,"") 
						LET quit_flag = true 
						EXIT INPUT 
					END IF 
					LET l_rec_cheque.bank_code = l_rec_vendor.bank_code 
					LET l_rec_cheque.pay_amt = p_cheq_amt 
					LET l_rec_cheque.conv_qty = p_conv_qty 
					DISPLAY BY NAME l_rec_cheque.vend_code, 
					l_rec_cheque.bank_code, 
					l_rec_cheque.conv_qty 

					SELECT * INTO l_rec_voucher.* 
					FROM voucher 
					WHERE cmpy_code = p_cmpy 
					AND vouch_code = p_vouch_code 
					CASE get_kandoooption_feature_state("AP","PT") 
						WHEN '1' 
							LET l_recalc_ind = 'N' 
						WHEN '2' 
							LET l_recalc_ind = 'Y' 
						WHEN '3' 
							LET l_recalc_ind = kandoomsg("P",1503,"") 
							#P1503 Override invoice discount settings (Y/N)
					END CASE 
					LET l_disc_amt = 0 
					IF l_recalc_ind = 'Y' THEN 
						LET l_disc_amt = l_rec_voucher.goods_amt * 
						( show_disc ( p_cmpy, 
						l_rec_voucher.term_code, 
						l_rec_cheque.cheq_date, 
						l_rec_voucher.vouch_date ) /100 ) 
						IF l_disc_amt != 0 THEN 
							IF l_disc_taken_ind IS NULL THEN 
								LET l_disc_taken_ind = kandoomsg("P",1504,"") 
								#P1504 Apply settlement discount (Y/N)
							END IF 
						END IF 
						IF l_disc_taken_ind IS NOT NULL 
						AND l_disc_taken_ind = 'N' THEN 
							LET l_disc_amt = 0 
						END IF 
					ELSE 
						IF l_rec_cheque.cheq_date <= l_rec_voucher.vouch_date THEN 
							LET l_disc_amt = l_rec_voucher.poss_disc_amt 
						END IF 
					END IF 
					LET l_rec_cheque.pay_amt = l_rec_voucher.total_amt 
					- l_rec_voucher.paid_amt 
					- l_disc_amt 
				END IF 
				NEXT FIELD NEXT 
			END IF 

		AFTER FIELD vend_code 
			IF field_touched(vend_code) THEN 
				CALL DIALOG.SetFieldTouched("vend_code", false) #we do this TO support INPUT wrap 
				SELECT * INTO l_rec_vendor.* FROM vendor 
				WHERE cmpy_code = p_cmpy 
				AND vend_code = l_rec_cheque.vend_code 
				IF status = NOTFOUND THEN 
					#P9105 "Vendor Not found - Try Window
					LET l_msgresp=kandoomsg("P",9105,"") 
					NEXT FIELD vend_code 
				END IF 
			END IF 

		BEFORE FIELD bank_code 
			IF l_rec_cheque.bank_code IS NULL THEN 
				LET l_rec_cheque.bank_code = l_rec_vendor.bank_code 
			END IF 
			IF field_touched(bank_code) THEN 
				#CALL DIALOG.SetFieldTouched("bank_code", FALSE)  #we do this TO support input wrap
				SELECT * INTO l_rec_bank.* FROM bank 
				WHERE cmpy_code = p_cmpy 
				AND currency_code = l_rec_vendor.currency_code 
				AND bank_code = l_rec_cheque.bank_code 
				CALL get_whold_tax(p_cmpy,l_rec_cheque.vend_code, 
				l_rec_vendor.type_code) 
				RETURNING l_rec_cheque.withhold_tax_ind, 
				l_rec_cheque.tax_code, 
				l_rec_cheque.tax_per 
				# Save the Vendor's own tax ind in CASE it IS overwritten FOR this
				# cheque.  We need it FOR the tax reporting indicator.
				LET l_vendor_tax_ind = l_rec_cheque.withhold_tax_ind 
				IF p_vouch_code IS NOT NULL THEN 
					LET l_rec_cheque.withhold_tax_ind = l_rec_voucher.withhold_tax_ind 
				END IF 
				CALL wtaxcalc(l_rec_cheque.pay_amt, 
				l_rec_cheque.tax_per, 
				l_rec_cheque.withhold_tax_ind, p_cmpy) 
				RETURNING l_rec_cheque.net_pay_amt, 
				l_tax_amt 
				LET l_rec_cheque.currency_code = l_rec_vendor.currency_code 
				IF p_conv_qty IS NULL AND NOT field_touched(conv_qty) THEN 
					## calc conv qty only IF NOT previously entered
					LET l_rec_cheque.conv_qty = 
					get_conv_rate(p_cmpy,l_rec_cheque.currency_code, 
					l_rec_cheque.cheq_date,"B") 
				END IF 
				IF l_rec_bank.currency_code = l_rec_vendor.currency_code THEN 
					LET l_foreign_amt = l_rec_cheque.pay_amt 
				ELSE 
					LET l_foreign_amt = l_rec_cheque.pay_amt*l_rec_cheque.conv_qty 
				END IF 
				DISPLAY BY NAME l_rec_cheque.vend_code, 
				l_rec_vendor.name_text, 
				l_rec_cheque.bank_code, 
				l_rec_bank.name_acct_text, 
				l_rec_cheque.cheq_code, 
				l_rec_cheque.pay_amt, 
				l_rec_cheque.net_pay_amt, 
				l_rec_cheque.withhold_tax_ind, 
				l_rec_cheque.tax_code, 
				l_rec_cheque.tax_per, 
				l_rec_cheque.conv_qty, 
				l_rec_cheque.bank_acct_code 
				DISPLAY l_foreign_amt TO foreign_amt 
				DISPLAY BY NAME l_rec_cheque.currency_code, 
				l_rec_cheque.bank_currency_code 
				attribute(green) 
				DISPLAY l_rec_vendor.currency_code TO curr_code 
				attribute(green) 
			END IF 

		AFTER FIELD bank_code 
			IF field_touched(bank_code) THEN 
				CALL DIALOG.SetFieldTouched("bank_code", false) #we do this TO support INPUT wrap 
				SELECT * INTO l_rec_bank.* FROM bank 
				WHERE cmpy_code = p_cmpy 
				AND bank_code = l_rec_bank.bank_code 
				IF status = NOTFOUND THEN 
					#P9003 Bank Account IS NOT found, use the window "
					LET l_msgresp=kandoomsg("P",9003,"") 
					NEXT FIELD bank_code 
				END IF 
				LET l_rec_cheque.bank_code = l_rec_bank.bank_code 
				IF l_rec_bank.currency_code != l_rec_vendor.currency_code THEN 
					IF l_rec_bank.currency_code != l_base_currency THEN 
						#P9008 Bank Account has wrong currency,try the window
						LET l_msgresp=kandoomsg("P",9008,"") 
						NEXT FIELD bank_code 
					END IF 
				END IF 
				LET l_rec_cheque.bank_currency_code = l_rec_bank.currency_code 
				LET l_rec_cheque.bank_acct_code = l_rec_bank.acct_code 
				IF l_rec_cheque.cheq_code IS NULL THEN 
					LET l_rec_cheque.cheq_code = l_rec_bank.next_cheque_num 
				END IF 
				DISPLAY BY NAME l_rec_bank.name_acct_text, 
				l_rec_cheque.cheq_code, 
				l_rec_cheque.bank_acct_code 

				DISPLAY BY NAME l_rec_cheque.currency_code, 
				l_rec_cheque.bank_currency_code 
			END IF 
		AFTER FIELD cheq_code 
			IF l_rec_cheque.cheq_code IS NULL 
			OR l_rec_cheque.cheq_code <= 0 THEN 
				#P9009 "Enter valid cheque number
				LET l_msgresp=kandoomsg("P",9009,"") 
				NEXT FIELD cheq_code 
			ELSE 
				SELECT unique 1 FROM cheque 
				WHERE cmpy_code = p_cmpy 
				AND bank_code = l_rec_cheque.bank_code 
				AND cheq_code = l_rec_cheque.cheq_code 
				AND pay_meth_ind = "1" 
				IF status = 0 THEN 
					#P9010 Cheque already issued
					LET l_msgresp=kandoomsg("P",9010,l_rec_cheque.cheq_code) 
					NEXT FIELD cheq_code 
				END IF 
			END IF 

		BEFORE FIELD cheq_date 
			LET l_save_date = l_rec_cheque.cheq_date 

		AFTER FIELD cheq_date 
			IF l_rec_cheque.cheq_date IS NULL THEN 
				ERROR "" 
				NEXT FIELD cheq_date 
			ELSE 
				IF p_conv_qty IS NULL AND NOT field_touched(conv_qty) THEN 
					LET l_rec_cheque.conv_qty = 
					get_conv_rate(p_cmpy,l_rec_cheque.currency_code, 
					l_rec_cheque.cheq_date,"B") 
				END IF 
			END IF 
			IF l_rec_cheque.cheq_date != l_save_date THEN 
				CALL db_period_what_period(p_cmpy, l_rec_cheque.cheq_date) 
				RETURNING l_rec_cheque.year_num, l_rec_cheque.period_num 
				DISPLAY BY NAME l_rec_cheque.year_num, 
				l_rec_cheque.period_num 

			END IF 
			IF p_vouch_code IS NOT NULL THEN 
				IF l_recalc_ind = 'Y' THEN 
					LET l_disc_amt = l_rec_voucher.goods_amt * 
					( show_disc ( p_cmpy, 
					l_rec_voucher.term_code, 
					l_rec_cheque.cheq_date, 
					l_rec_voucher.vouch_date ) /100 ) 
					IF l_disc_taken_ind IS NOT NULL 
					AND l_disc_taken_ind = 'N' THEN 
						LET l_disc_amt = 0 
					END IF 
				ELSE 
					IF l_rec_cheque.cheq_date <= l_rec_voucher.disc_date THEN 
						LET l_disc_amt = l_rec_voucher.poss_disc_amt 
					ELSE 
						LET l_disc_amt = 0 
					END IF 
				END IF 
				LET l_rec_cheque.pay_amt = l_rec_voucher.total_amt 
				- l_rec_voucher.paid_amt 
				- l_disc_amt 
				IF l_rec_cheque.pay_amt IS NULL THEN 
					LET l_rec_cheque.pay_amt = 0 
				END IF 
			END IF 
			DISPLAY BY NAME l_rec_cheque.pay_amt 

		BEFORE FIELD withhold_tax_ind 
			IF p_vouch_code IS NOT NULL #if voucher code IS empty OR it IS marked NOT TO be dropped/deletes, you will NOT able TO change this FIELD deduction code 
			OR (l_rec_vendor.drop_flag IS NULL OR 
			l_rec_vendor.drop_flag != "Y") THEN 
				CALL set_fieldAttribute_readOnly("withhold_tax_ind",TRUE) 
			ELSE 
				CALL set_fieldAttribute_readOnly("withhold_tax_ind",FALSE) 
			END IF 
			#            IF fgl_lastkey() = fgl_keyval("up") THEN -- bloody legacy key navigation
			#               NEXT FIELD previous
			#            ELSE
			#               NEXT FIELD next
			#            END IF
			#         END IF

		AFTER FIELD withhold_tax_ind 
			IF l_rec_cheque.withhold_tax_ind IS NULL 
			OR (NOT (l_rec_cheque.withhold_tax_ind matches "[0123]")) THEN 
				LET l_msgresp = kandoomsg("P",9112,"") 
				#9112 Withholding Tax Indicator must be 0, 1 ,2 OR 3
				NEXT FIELD withhold_tax_ind 
			END IF 
			IF l_rec_cheque.withhold_tax_ind = "0" THEN 
				LET l_rec_cheque.tax_code = NULL 
				LET l_rec_cheque.tax_per = 0 
				DISPLAY BY NAME l_rec_cheque.tax_code, 
				l_rec_cheque.tax_per 

			END IF 

		BEFORE FIELD tax_code 
			IF l_rec_cheque.withhold_tax_ind = "0" THEN 
				CALL set_fieldAttribute_readOnly("tax_code",TRUE) 
				IF fgl_lastkey() = fgl_keyval("up") THEN 
					NEXT FIELD previous 
				ELSE 
					NEXT FIELD NEXT 
				END IF 
			ELSE 
				CALL set_fieldAttribute_readOnly("tax_code",FALSE) 
			END IF 


		AFTER FIELD tax_code 
			IF l_rec_cheque.tax_code IS NULL THEN 
				LET l_rec_cheque.tax_per = 0 
			ELSE 
				SELECT tax_per INTO l_rec_cheque.tax_per 
				FROM tax 
				WHERE cmpy_code = p_cmpy 
				AND tax_code = l_rec_cheque.tax_code 
				IF status = NOTFOUND THEN 
					LET l_msgresp = kandoomsg("P",9106,"") 
					#9106 Tax Code NOT found - try window
					NEXT FIELD tax_code 
				END IF 
				IF l_rec_cheque.tax_per IS NULL THEN 
					LET l_rec_cheque.tax_per = 0 
				END IF 
			END IF 
			CALL wtaxcalc(l_rec_cheque.pay_amt, 
			l_rec_cheque.tax_per, 
			l_rec_cheque.withhold_tax_ind,p_cmpy) 
			RETURNING l_rec_cheque.net_pay_amt, 
			l_tax_amt 
			IF l_rec_cheque.net_pay_amt IS NULL THEN 
				LET l_rec_cheque.net_pay_amt = 0 
			END IF 
			DISPLAY BY NAME l_rec_cheque.tax_per, 
			l_rec_cheque.net_pay_amt 

		AFTER FIELD pay_amt 
			CASE 
				WHEN l_rec_cheque.pay_amt IS NULL 
					LET l_msgresp = kandoomsg("P",9011,"") 
					#9011 "Cheque amount must have a value
					NEXT FIELD pay_amt 
				WHEN l_rec_cheque.pay_amt <= 0 
					LET l_msgresp = kandoomsg("P",9011,"") 
					#9011 "Cheque amount must have a value
					NEXT FIELD pay_amt 
				OTHERWISE 
					CALL wtaxcalc(l_rec_cheque.pay_amt, 
					l_rec_cheque.tax_per, 
					l_rec_cheque.withhold_tax_ind,p_cmpy) 
					RETURNING l_rec_cheque.net_pay_amt, 
					l_tax_amt 
					IF l_rec_vendor.currency_code = l_rec_bank.currency_code THEN 
						LET l_foreign_amt = l_rec_cheque.pay_amt 
					ELSE 
						LET l_foreign_amt = l_rec_cheque.pay_amt / l_rec_cheque.conv_qty 
					END IF 
					DISPLAY l_foreign_amt TO foreign_amt 
					DISPLAY BY NAME l_rec_cheque.net_pay_amt 

			END CASE 

		BEFORE FIELD net_pay_amt 
			IF l_rec_vendor.drop_flag != "Y" 
			OR l_rec_cheque.withhold_tax_ind = 0 THEN 
				NEXT FIELD foreign_amt 
			END IF 

		AFTER FIELD net_pay_amt 
			IF l_rec_cheque.net_pay_amt IS NULL THEN 
				LET l_rec_cheque.net_pay_amt = 0 
			END IF 
			IF l_rec_cheque.net_pay_amt > l_rec_cheque.pay_amt THEN 
				LET l_msgresp = kandoomsg("P",9131,"") 
				#9131 Net Pay Amount must be less than Gross Pay Amount
				NEXT FIELD net_pay_amt 
			END IF 
			LET l_tax_amt = l_rec_cheque.pay_amt - l_rec_cheque.net_pay_amt 
			LET l_rec_cheque.tax_per = (l_tax_amt / l_rec_cheque.pay_amt) * 100 
			DISPLAY BY NAME l_rec_cheque.tax_per 

		BEFORE FIELD foreign_amt 
			IF l_rec_vendor.currency_code = l_rec_bank.currency_code THEN 
				LET l_foreign_amt = l_rec_cheque.pay_amt 
				IF fgl_lastkey() = fgl_keyval("up") THEN 
					NEXT FIELD pay_amt 
				ELSE 
					NEXT FIELD NEXT 
				END IF 
			END IF 
			LET l_save_amt = l_foreign_amt 

		AFTER FIELD foreign_amt 
			IF l_foreign_amt IS NULL THEN 
				LET l_foreign_amt = 0 
			END IF 
			IF l_save_amt > 0 AND l_foreign_amt = 0 THEN 
				LET l_foreign_amt = l_rec_cheque.pay_amt / l_rec_cheque.conv_qty 
			END IF 
			IF l_rec_cheque.pay_amt > 0 AND l_foreign_amt > 0 THEN 
				LET l_rec_cheque.conv_qty = l_rec_cheque.pay_amt/l_foreign_amt 
			END IF 
			DISPLAY BY NAME l_rec_cheque.conv_qty 

		BEFORE FIELD conv_qty 
			IF l_rec_vendor.currency_code = l_base_currency THEN 
				IF fgl_lastkey() = fgl_keyval("up") THEN 
					NEXT FIELD previous 
				ELSE 
					NEXT FIELD NEXT 
				END IF 
			END IF 
			LET l_save_qty = l_rec_cheque.conv_qty 

		AFTER FIELD conv_qty 
			CASE 
				WHEN l_rec_cheque.conv_qty IS NULL 
					LET l_msgresp = kandoomsg("P",9012,"") 
					#9012 Exchange Rate must have a value"
					LET l_rec_cheque.conv_qty = 
					get_conv_rate(p_cmpy,l_rec_cheque.currency_code, 
					l_rec_cheque.cheq_date,"B") 
					NEXT FIELD conv_qty 
				WHEN l_rec_cheque.conv_qty <= 0 
					LET l_msgresp = kandoomsg("P",9012,"") 
					#9012 Exchange Rate must have a value"
					LET l_rec_cheque.conv_qty = 
					get_conv_rate(p_cmpy,l_rec_cheque.currency_code, 
					l_rec_cheque.cheq_date,"B") 
					NEXT FIELD conv_qty 
				OTHERWISE 
					IF l_rec_bank.currency_code = l_base_currency THEN 
						LET l_foreign_amt = l_rec_cheque.pay_amt / l_rec_cheque.conv_qty 
						DISPLAY l_foreign_amt TO foreign_amt 

					END IF 
			END CASE 

		AFTER FIELD period_num 
			CALL valid_period(p_cmpy,l_rec_cheque.year_num, 
			l_rec_cheque.period_num,"ap") 
			RETURNING l_rec_cheque.year_num, 
			l_rec_cheque.period_num, 
			l_invalid_period 
			IF l_invalid_period THEN 
				NEXT FIELD year_num 
			END IF 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				IF l_rec_cheque.bank_code IS NULL THEN 
					LET l_msgresp=kandoomsg("A",9505,"") 
					#9505 Value must be entered
					# Before INPUT will DISPLAY the default bank code WHEN the next
					# statement IS executed - but I believe we should still beep

					NEXT FIELD bank_code 
				END IF 

				IF l_rec_cheque.cheq_code IS NULL THEN 
					#P9009 "Enter valid cheque number
					LET l_msgresp=kandoomsg("P",9009,"") 
					NEXT FIELD cheq_code 
				ELSE 
					SELECT unique 1 FROM cheque 
					WHERE cmpy_code = p_cmpy 
					AND bank_code = l_rec_cheque.bank_code 
					AND cheq_code = l_rec_cheque.cheq_code 
					AND pay_meth_ind = "1" 
					IF status = 0 THEN 
						#P9010 Cheque already issued
						LET l_msgresp=kandoomsg("P",9010,l_rec_cheque.cheq_code) 
						NEXT FIELD cheq_code 
					END IF 
				END IF 

				IF l_rec_cheque.pay_amt = 0 THEN 
					LET l_msgresp = kandoomsg("P",9011,"") 
					#9011 "Cheque amount must have a value
					NEXT FIELD pay_amt 
				END IF 

				IF l_rec_cheque.tax_code IS NOT NULL THEN 
					SELECT tax_per INTO l_rec_cheque.tax_per FROM tax 
					WHERE cmpy_code = p_cmpy 
					AND tax_code = l_rec_cheque.tax_code 
					IF status = NOTFOUND THEN 
						LET l_msgresp = kandoomsg("P",9106,"") 
						#9106 Tax Code NOT found - try window
						NEXT FIELD tax_code 
					END IF 
				END IF 

				IF l_rec_cheque.tax_code IS NULL THEN 
					LET l_rec_cheque.tax_per = 0 
				ELSE 
					IF l_rec_vendor.drop_flag != "Y" 
					OR l_rec_cheque.withhold_tax_ind = 0 THEN 
						SELECT tax_per INTO l_rec_cheque.tax_per 
						FROM tax 
						WHERE cmpy_code = p_cmpy 
						AND tax_code = l_rec_cheque.tax_code 
						IF status = NOTFOUND THEN 
							LET l_msgresp = kandoomsg("P",9106,"") 
							#9106 Tax Code NOT found - try window
							NEXT FIELD tax_code 
						END IF 
					END IF 
					IF l_rec_cheque.tax_per IS NULL THEN 
						LET l_rec_cheque.tax_per = 0 
					END IF 
				END IF 

				CALL valid_period(p_cmpy,l_rec_cheque.year_num, 
				l_rec_cheque.period_num,"ap") 
				RETURNING l_rec_cheque.year_num, 
				l_rec_cheque.period_num, 
				l_invalid_period 
				IF l_invalid_period THEN 
					NEXT FIELD year_num 
				END IF 
			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET l_rec_cheque.cheq_code = NULL 
		LET int_flag = false 
		LET quit_flag = false 
	ELSE 
		GOTO bypass 
		LABEL recovery: 
		IF error_recover(l_err_message, status) != "Y" THEN 
			EXIT PROGRAM 
		END IF 
		LABEL bypass: 
		WHENEVER ERROR GOTO recovery 
		BEGIN WORK 

			### there may be two audit entries (net amount AND tax)
			### FOR withholding tax cheques
			LET l_err_message = "P41 - Vendor Master Update" 
			DECLARE c_vendor CURSOR FOR 
			SELECT * FROM vendor 
			WHERE cmpy_code = p_cmpy 
			AND vend_code = l_rec_cheque.vend_code 
			FOR UPDATE 
			OPEN c_vendor 
			FETCH c_vendor INTO l_rec_vendor.* 
			LET l_err_message = "P41 - Cheque RECORD Insert" 
			LET l_rec_cheque.cmpy_code = p_cmpy 
			LET l_rec_cheque.post_flag = "N" 
			LET l_rec_cheque.recon_flag = "N" 
			LET l_rec_cheque.post_date = NULL 
			LET l_rec_cheque.pay_meth_ind = "1" 
			LET l_rec_cheque.eft_run_num = 0 
			LET l_rec_cheque.apply_amt = 0 
			LET l_rec_cheque.doc_num = 0 
			IF l_rec_voucher.source_ind IS NULL THEN #p43 instance 
				SELECT unique 1 FROM bank 
				WHERE bank_code = l_rec_cheque.vend_code 
				AND cmpy_code = p_cmpy 
				IF status != NOTFOUND THEN 
					LET l_rec_cheque.source_ind = "S" 
					LET l_rec_cheque.source_text = NULL 
				ELSE 
					LET l_rec_cheque.source_ind = '1' 
					LET l_rec_cheque.source_text = l_rec_cheque.vend_code 
				END IF 
			ELSE 
				IF l_rec_voucher.source_ind = "S" THEN 
					LET l_rec_cheque.source_ind = "S" 
					LET l_rec_cheque.source_text = l_rec_voucher.vouch_code 
					USING "&&&&&&&&" 
				ELSE 
					LET l_rec_cheque.source_ind = '1' 
					LET l_rec_cheque.source_text = l_rec_cheque.vend_code 
				END IF 
			END IF 
			# Note: Contra amounts cannot be deducted FROM manual cheques
			LET l_rec_cheque.tax_amt = 
			l_rec_cheque.pay_amt - l_rec_cheque.net_pay_amt 
			LET l_rec_cheque.contra_amt = 0 
			LET l_rec_cheque.whtax_rep_ind = l_vendor_tax_ind 
			INSERT INTO cheque VALUES (l_rec_cheque.*) 
			IF l_rec_cheque.cheq_date > l_rec_vendor.last_payment_date 
			OR l_rec_vendor.last_payment_date IS NULL THEN 
				LET l_rec_vendor.last_payment_date = l_rec_cheque.cheq_date 
			END IF 
			LET l_rec_vendor.bal_amt = l_rec_vendor.bal_amt 
			- l_rec_cheque.net_pay_amt 
			LET l_rec_vendor.next_seq_num = l_rec_vendor.next_seq_num + 1 
			LET l_rec_apaudit.cmpy_code = p_cmpy 
			LET l_rec_apaudit.tran_date = l_rec_cheque.cheq_date 
			LET l_rec_apaudit.vend_code = l_rec_cheque.vend_code 
			LET l_rec_apaudit.seq_num = l_rec_vendor.next_seq_num 
			LET l_rec_apaudit.trantype_ind = "CH" 
			LET l_rec_apaudit.source_num = l_rec_cheque.cheq_code 
			LET l_rec_apaudit.tran_text = "Manual Chq Amt" 
			LET l_rec_apaudit.tran_amt = 0 - l_rec_cheque.net_pay_amt 
			LET l_rec_apaudit.entry_code = l_rec_cheque.entry_code 
			LET l_rec_apaudit.year_num = l_rec_cheque.year_num 
			LET l_rec_apaudit.period_num = l_rec_cheque.period_num 
			LET l_rec_apaudit.bal_amt = l_rec_vendor.bal_amt 
			LET l_rec_apaudit.currency_code = l_rec_cheque.currency_code 
			LET l_rec_apaudit.conv_qty = l_rec_cheque.conv_qty 
			LET l_rec_apaudit.entry_date = today 
			LET l_err_message = "P41 - AP Audit Insert" 
			INSERT INTO apaudit VALUES (l_rec_apaudit.*) 
			IF l_tax_amt > 0 THEN 
				LET l_rec_vendor.bal_amt = l_rec_vendor.bal_amt 
				- l_tax_amt 
				LET l_rec_vendor.next_seq_num = l_rec_vendor.next_seq_num + 1 
				LET l_rec_apaudit.seq_num = l_rec_vendor.next_seq_num 
				LET l_rec_apaudit.tran_text = "Manual Chq Tax" 
				LET l_rec_apaudit.tran_amt = 0 - l_tax_amt 
				LET l_rec_apaudit.bal_amt = l_rec_vendor.bal_amt 
				LET l_err_message = "P41 - AP Audit Insert" 
				INSERT INTO apaudit VALUES (l_rec_apaudit.*) 
			END IF 
			LET l_err_message = "P41 - Vendor Master Update" 
			LET l_rec_vendor.curr_amt = l_rec_vendor.curr_amt 
			- l_rec_cheque.pay_amt 
			UPDATE vendor SET * = l_rec_vendor.* 
			WHERE cmpy_code = p_cmpy 
			AND vend_code = l_rec_cheque.vend_code 
			LET l_err_message = "P41 - Bank RECORD Update" 
			UPDATE bank 
			SET next_cheque_num = l_rec_cheque.cheq_code + 1 
			WHERE acct_code = l_rec_cheque.bank_acct_code 
			AND cmpy_code = l_rec_cheque.cmpy_code 
		COMMIT WORK 
		WHENEVER ERROR stop 

	END IF 
	IF l_rec_cheque.cheq_code IS NOT NULL THEN 
		#7028 Cheque: 999999  successfully entered AND applied" AT 1,1
		LET l_msgresp=kandoomsg("P",7028,l_rec_cheque.cheq_code) 
	END IF 

	CLOSE WINDOW p137 

	RETURN l_rec_cheque.cheq_code, 
	l_rec_cheque.bank_acct_code 
END FUNCTION 


