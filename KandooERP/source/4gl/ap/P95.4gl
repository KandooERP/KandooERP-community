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

	Source code beautified by beautify.pl on 2020-01-03 13:41:35	$Id: $
}
{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module - P95
# Purpose - Allows entry of a cheque with net amount payable TO the
#           vendor equal TO the amount of withholding tax TO be refunded
#           AND a gross amount payable TO vouchers of zero
#

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/P9_GROUP_GLOBALS.4gl" 
GLOBALS "../ap/P95_GLOBALS.4gl"
###########################################################################
# MODULE Scope Variables
###########################################################################
DEFINE modu_rec_cheque RECORD LIKE cheque.*
DEFINE modu_base_currency LIKE glparms.base_currency_code

############################################################
# MAIN
#
#
############################################################
MAIN 
	DEFINE l_msgresp LIKE language.yes_flag 

	#Initial UI Init
	CALL setModuleId("P95") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_p_ap() #init p/ap module 

	OPEN WINDOW p204 with FORM "P204" 
	CALL windecoration_p("P204") 

	#now done it CALL init_p_ap() #init P/AP module
	# SELECT * INTO pr_apparms.* FROM apparms
	#    WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
	#      AND parm_code = "1"
	# IF STATUS = NOTFOUND THEN
	#    LET l_msgresp = kandoomsg("P",3510,"")
	#    #3510 AP Parameters missing
	#    sleep 3
	#    EXIT PROGRAM
	# END IF

	SELECT base_currency_code INTO modu_base_currency FROM glparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND key_code = "1" 
	IF status = NOTFOUND THEN 
		LET l_msgresp = kandoomsg("P",5007,"") 
		#5007 General Ledger Parameters Not Found, See Menu GZP
		EXIT PROGRAM 
	END IF 

	WHILE enter_tax_refund() 
		MESSAGE "Refund Cheque: ", modu_rec_cheque.cheq_code USING "<<<<<<<<<", 
		" successfully entered" 
	END WHILE 

	CLOSE WINDOW p204 
END MAIN 


############################################################
# FUNCTION enter_tax_refund()
#
#
############################################################
FUNCTION enter_tax_refund() 
	DEFINE l_rec_cheque RECORD LIKE cheque.*
	DEFINE l_rec_vendor RECORD LIKE vendor.*
	DEFINE l_rec_apaudit RECORD LIKE apaudit.*
	DEFINE l_rec_bank RECORD LIKE bank.*
	DEFINE l_last_foreign_amt LIKE cheque.pay_amt 
	DEFINE l_foreign_amt LIKE cheque.pay_amt
	DEFINE l_last_conv_qty LIKE cheque.conv_qty 
	DEFINE l_set_up_conv_qty SMALLINT
	DEFINE l_failed_it INTEGER
	DEFINE l_err_message CHAR(40)
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE try_again CHAR(1)
	DEFINE cnt SMALLINT

	CLEAR FORM 
	INITIALIZE modu_rec_cheque.* TO NULL 

	LET modu_rec_cheque.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET modu_rec_cheque.entry_code = glob_rec_kandoouser.sign_on_code 
	LET modu_rec_cheque.entry_date = today 
	LET modu_rec_cheque.cheq_date = today 
	LET modu_rec_cheque.apply_amt = 0 
	LET modu_rec_cheque.next_appl_num = 0 
	LET modu_rec_cheque.pay_amt = 0 
	LET l_foreign_amt = 0 
	LET modu_rec_cheque.disc_amt = 0 
	LET modu_rec_cheque.contra_amt = 0 
	LET modu_rec_cheque.tax_amt = 0 
	LET modu_rec_cheque.bank_currency_code = NULL 
	LET modu_rec_cheque.net_pay_amt = 0 
	LET modu_rec_cheque.tax_per = 0 
	LET modu_rec_cheque.post_flag = "N" 
	LET modu_rec_cheque.recon_flag = "N" 

	CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, today) 
	RETURNING modu_rec_cheque.year_num, modu_rec_cheque.period_num 

	INPUT BY NAME modu_rec_cheque.vend_code 
	WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","P95","inp-vend_code-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		ON KEY (control-b) infield (vend_code) 
			LET modu_rec_cheque.vend_code = show_vend(glob_rec_kandoouser.cmpy_code,modu_rec_cheque.vend_code) 
			DISPLAY BY NAME modu_rec_cheque.vend_code 

			NEXT FIELD vend_code 

		AFTER FIELD vend_code 
			SELECT * 
			INTO l_rec_vendor.* 
			FROM vendor 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND vend_code = modu_rec_cheque.vend_code 
			IF status = NOTFOUND THEN 
				LET l_msgresp = kandoomsg("P",9105,"") 
				#9105 Vendor NOT found - try window
				NEXT FIELD vend_code 
			END IF 
			SELECT withhold_tax_ind 
			INTO modu_rec_cheque.withhold_tax_ind 
			FROM vendortype 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND type_code = l_rec_vendor.type_code 
			IF modu_rec_cheque.withhold_tax_ind IS NULL OR 
			modu_rec_cheque.withhold_tax_ind = "0" THEN 
				LET l_msgresp = kandoomsg("P",9125,l_rec_vendor.type_code) 
				#9125 Vendor of type,l_rec_vendor.type_code, NOT taxable
				#     - no refund allowed
				NEXT FIELD vend_code 
			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		RETURN false 
	END IF 
	LET modu_rec_cheque.source_ind = "1" 
	LET modu_rec_cheque.source_text = modu_rec_cheque.vend_code 
	LET l_set_up_conv_qty = true 
	CALL get_conv_rate(glob_rec_kandoouser.cmpy_code, 
	l_rec_vendor.currency_code, 
	modu_rec_cheque.cheq_date, 
	"B") 
	RETURNING modu_rec_cheque.conv_qty 
	IF modu_rec_cheque.conv_qty IS NULL OR 
	modu_rec_cheque.conv_qty = "" THEN 
		LET modu_rec_cheque.conv_qty = 0 
	END IF 

	LET modu_rec_cheque.bank_acct_code = glob_rec_apparms.bank_acct_code 
	SELECT * 
	INTO l_rec_bank.* 
	FROM bank 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND acct_code = modu_rec_cheque.bank_acct_code 
	AND currency_code = l_rec_vendor.currency_code 
	LET modu_rec_cheque.bank_code = l_rec_bank.bank_code 

	LET modu_rec_cheque.cheq_code = l_rec_bank.next_cheque_num 
	LET modu_rec_cheque.currency_code = l_rec_vendor.currency_code 
	LET modu_rec_cheque.bank_currency_code = NULL 

	DISPLAY BY NAME modu_rec_cheque.vend_code, 
	l_rec_vendor.name_text, 
	l_rec_bank.bank_code, 
	l_rec_bank.name_acct_text, 
	modu_rec_cheque.cheq_code, 
	modu_rec_cheque.currency_code, 
	modu_rec_cheque.cheq_date, 
	modu_rec_cheque.net_pay_amt, 
	modu_rec_cheque.conv_qty, 
	modu_rec_cheque.entry_code, 
	modu_rec_cheque.entry_date, 
	modu_rec_cheque.bank_acct_code, 
	modu_rec_cheque.year_num, 
	modu_rec_cheque.period_num 
	DISPLAY l_foreign_amt TO foreign_amt 

	MESSAGE "" 
	MESSAGE " F8 FOR Account Status" 
	attribute (yellow) 

	INPUT l_rec_bank.bank_code, 
	modu_rec_cheque.cheq_code, 
	modu_rec_cheque.cheq_date, 
	modu_rec_cheque.net_pay_amt, 
	l_foreign_amt, 
	modu_rec_cheque.conv_qty, 
	modu_rec_cheque.com3_text, 
	modu_rec_cheque.year_num, 
	modu_rec_cheque.period_num, 
	modu_rec_cheque.com1_text, 
	modu_rec_cheque.com2_text 
	WITHOUT DEFAULTS
	FROM bank_code, 
	cheq_code, 
	cheq_date, 
	net_pay_amt, 
	foreign_amt, 
	conv_qty, 
	com3_text, 
	year_num, 
	period_num, 
	com1_text, 
	com2_text

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","P95","inp-bank_code-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON KEY (control-b) infield (bank_code) 
			CALL show_bank(glob_rec_kandoouser.cmpy_code) RETURNING l_rec_bank.bank_code, 
			modu_rec_cheque.bank_acct_code 
			DISPLAY BY NAME l_rec_bank.bank_code, 
			modu_rec_cheque.bank_acct_code 

			LET modu_rec_cheque.bank_code = l_rec_bank.bank_code 
			NEXT FIELD bank_code 

		ON KEY (F8) 
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

		AFTER FIELD bank_code 
			SELECT * 
			INTO l_rec_bank.* 
			FROM bank 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND bank_code = l_rec_bank.bank_code 
			IF status = NOTFOUND THEN 
				LET l_msgresp = kandoomsg("P",9003,"") 
				#9003 Bank Code IS NOT found, try the window
				NEXT FIELD bank_code 
			END IF 
			LET modu_rec_cheque.bank_code = l_rec_bank.bank_code 
			IF l_rec_bank.currency_code != l_rec_vendor.currency_code THEN 
				IF l_rec_bank.currency_code != modu_base_currency THEN 
					LET l_msgresp = kandoomsg("P",9008,"") 
					#9008 Bank has wrong currency, try the window
					NEXT FIELD bank_code 
				END IF 
			END IF 
			IF l_rec_bank.currency_code != l_rec_vendor.currency_code THEN 
				LET modu_rec_cheque.bank_currency_code = l_rec_bank.currency_code 
			ELSE 
				LET modu_rec_cheque.bank_currency_code = NULL 
			END IF 
			LET modu_rec_cheque.cheq_code = l_rec_bank.next_cheque_num 
			LET modu_rec_cheque.bank_acct_code = l_rec_bank.acct_code 
			DISPLAY BY NAME l_rec_bank.name_acct_text, 
			modu_rec_cheque.cheq_code, 
			modu_rec_cheque.bank_acct_code, 
			modu_rec_cheque.currency_code, 
			modu_rec_cheque.bank_currency_code 

			LET modu_rec_cheque.bank_currency_code = l_rec_bank.currency_code 

		AFTER FIELD cheq_code 
			IF modu_rec_cheque.cheq_code IS NULL THEN 
				LET l_msgresp = kandoomsg("P",9009,"") 
				#9009 Must enter valid cheque number
				NEXT FIELD cheq_code 
			END IF 

			SELECT cheque.* 
			INTO l_rec_cheque.* 
			FROM cheque 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cheq_code = modu_rec_cheque.cheq_code 
			AND bank_acct_code = modu_rec_cheque.bank_acct_code 
			AND pay_meth_ind = "1" 
			IF NOT (status = NOTFOUND) THEN 
				LET l_msgresp = kandoomsg("P",9010,l_rec_cheque.cheq_code) 
				#9010 Cheque number,l_rec_cheque.cheq_code,already issued
				NEXT FIELD cheq_code 
			END IF 

		AFTER FIELD cheq_date 
			IF modu_rec_cheque.cheq_date IS NULL THEN 
				LET modu_rec_cheque.cheq_date = today 
				DISPLAY BY NAME modu_rec_cheque.cheq_date 

			END IF 
			IF l_set_up_conv_qty THEN 
				CALL get_conv_rate(glob_rec_kandoouser.cmpy_code, 
				l_rec_vendor.currency_code, 
				modu_rec_cheque.cheq_date, 
				"B") 
				RETURNING modu_rec_cheque.conv_qty 
				IF modu_rec_cheque.conv_qty IS NULL OR 
				modu_rec_cheque.conv_qty = "" THEN 
					LET modu_rec_cheque.conv_qty = 0 
				END IF 
				DISPLAY BY NAME modu_rec_cheque.conv_qty 

			END IF 
			CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, 
			modu_rec_cheque.cheq_date) 
			RETURNING modu_rec_cheque.year_num, 
			modu_rec_cheque.period_num 
			DISPLAY BY NAME modu_rec_cheque.period_num, 
			modu_rec_cheque.year_num 


		AFTER FIELD net_pay_amt 
			IF modu_rec_cheque.net_pay_amt IS NULL THEN 
				LET l_msgresp = kandoomsg("P",9506,"") 
				#9506 Must enter a value
				NEXT FIELD net_pay_amt 
			END IF 
			IF modu_rec_cheque.net_pay_amt <= 0 THEN 
				LET l_msgresp = kandoomsg("P",9011,"") 
				#9011 Cheque amount must be greater than zero
				NEXT FIELD net_pay_amt 
			END IF 

		BEFORE FIELD foreign_amt 
			LET l_last_foreign_amt = l_foreign_amt 
			IF (l_rec_bank.currency_code = modu_base_currency AND 
			l_rec_vendor.currency_code = modu_base_currency) THEN 
				IF fgl_lastkey() = fgl_keyval("UP") THEN 
					NEXT FIELD net_pay_amt 
				ELSE 
					NEXT FIELD com3_text 
				END IF 
			END IF 
			IF (l_rec_bank.currency_code != modu_base_currency AND 
			l_rec_vendor.currency_code != modu_base_currency) THEN 
				IF fgl_lastkey() = fgl_keyval("UP") THEN 
					NEXT FIELD net_pay_amt 
				ELSE 
					NEXT FIELD conv_qty 
				END IF 
			END IF 

		AFTER FIELD foreign_amt 
			IF l_foreign_amt IS NULL THEN 
				LET l_foreign_amt = 0 
				DISPLAY l_foreign_amt TO foreign_amt  

			END IF 
			IF l_last_foreign_amt != l_foreign_amt AND 
			l_foreign_amt = 0 THEN 
				CALL get_conv_rate(glob_rec_kandoouser.cmpy_code, 
				l_rec_vendor.currency_code, 
				modu_rec_cheque.cheq_date, 
				"B") 
				RETURNING modu_rec_cheque.conv_qty 
				IF modu_rec_cheque.conv_qty IS NULL 
				OR modu_rec_cheque.conv_qty = "" THEN 
					LET modu_rec_cheque.conv_qty = 0 
				END IF 
				DISPLAY BY NAME modu_rec_cheque.conv_qty 

				LET l_set_up_conv_qty = true 
			END IF 
			IF l_rec_bank.currency_code = modu_base_currency AND 
			l_rec_vendor.currency_code != modu_base_currency THEN 
				IF modu_rec_cheque.net_pay_amt != 0 AND 
				l_foreign_amt != 0 THEN 
					LET modu_rec_cheque.conv_qty = modu_rec_cheque.net_pay_amt / 
					l_foreign_amt 
					DISPLAY BY NAME modu_rec_cheque.conv_qty 

					LET l_set_up_conv_qty = false 
				END IF 
			END IF 

		AFTER FIELD period_num 
			CALL valid_period(glob_rec_kandoouser.cmpy_code, 
			modu_rec_cheque.year_num, 
			modu_rec_cheque.period_num, 
			"ap") 
			RETURNING modu_rec_cheque.year_num, 
			modu_rec_cheque.period_num, 
			l_failed_it 
			IF l_failed_it THEN 
				NEXT FIELD year_num 
			END IF 

		BEFORE FIELD conv_qty 
			LET l_last_conv_qty = modu_rec_cheque.conv_qty 
			IF l_rec_bank.currency_code = modu_base_currency AND 
			l_rec_vendor.currency_code = modu_base_currency THEN 
				IF fgl_lastkey() = fgl_keyval("UP") THEN 
					NEXT FIELD foreign_amt 
				ELSE 
					NEXT FIELD com3_text 
				END IF 
			END IF 
			IF l_rec_bank.currency_code != modu_base_currency AND 
			l_rec_vendor.currency_code != modu_base_currency THEN 
				IF modu_rec_cheque.net_pay_amt != 0 AND l_foreign_amt != 0 THEN 
					IF fgl_lastkey() = fgl_keyval("UP") THEN 
						NEXT FIELD foreign_amt 
					ELSE 
						NEXT FIELD com3_text 
					END IF 
				END IF 
			END IF 
			IF l_rec_bank.currency_code = modu_base_currency AND 
			l_rec_vendor.currency_code != modu_base_currency THEN 
				IF modu_rec_cheque.net_pay_amt != 0 AND l_foreign_amt != 0 THEN 
					LET modu_rec_cheque.conv_qty = modu_rec_cheque.net_pay_amt / 
					l_foreign_amt 
					DISPLAY BY NAME modu_rec_cheque.conv_qty 

					LET l_set_up_conv_qty = false 
				END IF 
			END IF 

		AFTER FIELD conv_qty 
			IF modu_rec_cheque.conv_qty IS NULL THEN 
				LET l_msgresp = kandoomsg("P",9506,"") 
				#9506 Must enter a value
				NEXT FIELD conv_qty 
			END IF 
			IF modu_rec_cheque.conv_qty <= 0 THEN 
				LET l_msgresp = kandoomsg("P",9012,"") 
				#9012 Exchange Rate must be greater than zero
				NEXT FIELD conv_qty 
			END IF 
			IF l_last_conv_qty != modu_rec_cheque.conv_qty THEN 
				LET l_set_up_conv_qty = false 
			END IF 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 

			SELECT * 
			INTO l_rec_bank.* 
			FROM bank 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND bank_code = l_rec_bank.bank_code 
			IF status = NOTFOUND THEN 
				LET l_msgresp = kandoomsg("P",9003,"") 
				#9003 Bank Code IS NOT found, try the window
				NEXT FIELD bank_code 
			END IF 
			LET modu_rec_cheque.bank_code = l_rec_bank.bank_code 

			IF modu_rec_cheque.cheq_code IS NULL THEN 
				LET l_msgresp = kandoomsg("P",9009,"") 
				#9009 Must enter valid cheque number
				NEXT FIELD cheq_code 
			END IF 

			SELECT cheque.* 
			INTO l_rec_cheque.* 
			FROM cheque 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cheq_code = modu_rec_cheque.cheq_code 
			AND bank_acct_code = modu_rec_cheque.bank_acct_code 
			AND pay_meth_ind = "1" 
			IF NOT (status = NOTFOUND) THEN 
				LET l_msgresp = kandoomsg("P",9010,l_rec_cheque.cheq_code) 
				#9010 Cheque number,l_rec_cheque.cheq_code,already issued
				NEXT FIELD cheq_code 
			END IF 

			IF modu_rec_cheque.net_pay_amt <= 0 THEN 
				LET l_msgresp = kandoomsg("P",9011,"") 
				#9011 Cheque amount must be greater than zero
				NEXT FIELD net_pay_amt 
			END IF 

			CALL valid_period(glob_rec_kandoouser.cmpy_code, 
			modu_rec_cheque.year_num, 
			modu_rec_cheque.period_num, 
			"ap") 
			RETURNING modu_rec_cheque.year_num, 
			modu_rec_cheque.period_num, 
			l_failed_it 

			IF l_failed_it THEN 
				NEXT FIELD year_num 
			END IF 

			SELECT count(*) 
			INTO cnt 
			FROM coa 
			WHERE coa.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND coa.acct_code = modu_rec_cheque.bank_acct_code 
			IF (cnt != 1) THEN 
				LET l_msgresp = kandoomsg("P",9013,"") 
				#9013 Bank GL Account NOT found
				NEXT FIELD bank_code 
			END IF 

			IF modu_rec_cheque.cheq_date IS NULL THEN 
				LET modu_rec_cheque.cheq_date = today 
			END IF 
			LET modu_rec_cheque.pay_meth_ind = "1" 
			LET modu_rec_cheque.eft_run_num = 0 
			GOTO bypass 
			LABEL recovery: 
			LET try_again = error_recover(l_err_message, status) 
			IF try_again != "Y" THEN 
				EXIT PROGRAM 
			END IF 
			LABEL bypass: 
			WHENEVER ERROR GOTO recovery 
			BEGIN WORK 

				LET l_err_message = "P95 - Cheqhead INSERT" 
				LET modu_rec_cheque.doc_num = 0 
				LET modu_rec_cheque.tax_amt = modu_rec_cheque.pay_amt 
				- modu_rec_cheque.net_pay_amt 
				LET modu_rec_cheque.whtax_rep_ind = modu_rec_cheque.withhold_tax_ind 
				INSERT INTO cheque VALUES (modu_rec_cheque.*) 

				LET l_err_message = "P95 - Vendor UPDATE" 
				DECLARE c_vendor CURSOR FOR 
				SELECT * 
				INTO l_rec_vendor.* 
				FROM vendor 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND vend_code = modu_rec_cheque.vend_code 
				FOR UPDATE 

				# Retrieve vendor balance AND next sequence number
				# A transaction IS OUTPUT TO apaudit but this cheque has no effect
				# on vendor balance as the gross amount IS zero
				FOREACH c_vendor 
					LET l_rec_vendor.next_seq_num = l_rec_vendor.next_seq_num + 1 
					UPDATE vendor SET * = l_rec_vendor.* 
					WHERE CURRENT OF c_vendor 
				END FOREACH 

				LET l_rec_apaudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET l_rec_apaudit.tran_date = modu_rec_cheque.cheq_date 
				LET l_rec_apaudit.vend_code = modu_rec_cheque.vend_code 
				LET l_rec_apaudit.seq_num = l_rec_vendor.next_seq_num 
				LET l_rec_apaudit.trantype_ind = "CH" 
				LET l_rec_apaudit.source_num = modu_rec_cheque.cheq_code 
				LET l_rec_apaudit.tran_text = "Tax Refund Chq" 
				LET l_rec_apaudit.tran_amt = 0 
				LET l_rec_apaudit.entry_code = modu_rec_cheque.entry_code 
				LET l_rec_apaudit.year_num = modu_rec_cheque.year_num 
				LET l_rec_apaudit.period_num = modu_rec_cheque.period_num 
				LET l_rec_apaudit.bal_amt = l_rec_vendor.bal_amt 
				LET l_rec_apaudit.currency_code = modu_rec_cheque.currency_code 
				LET l_rec_apaudit.conv_qty = modu_rec_cheque.conv_qty 
				LET l_rec_apaudit.entry_date = today 
				LET l_err_message = "P95 - apudit INSERT" 
				INSERT INTO apaudit VALUES (l_rec_apaudit.*) 

				LET l_err_message = "P95 - Bank Chq UPDATE" 
				UPDATE bank 
				SET next_cheque_num = modu_rec_cheque.cheq_code + 1 
				WHERE cmpy_code = modu_rec_cheque.cmpy_code 
				AND acct_code = modu_rec_cheque.bank_acct_code 
			COMMIT WORK 
			WHENEVER ERROR stop 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = 0 
		LET quit_flag = 0 
		RETURN false 
	ELSE 

		RETURN true 
	END IF 

END FUNCTION 


