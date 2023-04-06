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
###########################################################################
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl" 
GLOBALS "../ar/A3_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/A37_GLOBALS.4gl" 

############################################################
# MODULE Scope Variables
############################################################
--	DEFINE glob_rec_cashreceipt RECORD LIKE cashreceipt.*
DEFINE modu_rec_bank RECORD LIKE bank.* 
DEFINE modu_rec_araudit RECORD LIKE araudit.* 
DEFINE modu_try_again CHAR(1) 
DEFINE modu_err_message CHAR(40) 
DEFINE modu_failed_it SMALLINT 
DEFINE modu_chng_amt DECIMAL(12,2) 
DEFINE modu_pv_amt DECIMAL(16,2) 

############################################################
# FUNCTION cashreceipt_edit(p_company_cmpy_code, p_cashnum, p_kandoouser_sign_on_code)
#
# \brief module - A37a
# Purpose - Allows the user TO edit AND apply cash receipts FROM customers
############################################################
FUNCTION cashreceipt_edit(p_company_cmpy_code, p_cashnum, p_kandoouser_sign_on_code) 
	DEFINE p_company_cmpy_code LIKE company.cmpy_code 
	DEFINE p_cashnum LIKE cashreceipt.cash_num 
	DEFINE p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code 

	DEFINE l_rec_company RECORD LIKE company.* 
	DEFINE l_rec_cashreceipt RECORD LIKE cashreceipt.* 
	DEFINE l_last_conv_qty LIKE cashreceipt.conv_qty 
	DEFINE l_base_currency LIKE glparms.base_currency_code 
	DEFINE l_last_field CHAR(18) 
	DEFINE l_last_foreign_amt LIKE cashreceipt.cash_amt 
	DEFINE l_foreign_amt LIKE cashreceipt.cash_amt 
	DEFINE l_cash_amt LIKE cashreceipt.cash_amt 
	DEFINE l_set_up_conv_qty SMALLINT 
	DEFINE l_orig_cash_amt LIKE cashreceipt.cash_amt 
	DEFINE l_error_msg CHAR(76) 
	DEFINE l_reference_text LIKE kandooword.reference_text 

	INITIALIZE glob_rec_cashreceipt.* TO NULL 

	SELECT * INTO l_rec_company.* FROM company 
	WHERE cmpy_code = p_company_cmpy_code 
	SELECT * INTO glob_rec_cashreceipt.* FROM cashreceipt 
	WHERE cmpy_code = p_company_cmpy_code 
	AND cash_num = p_cashnum 
	IF status = NOTFOUND THEN 
		#ERROR kandoomsg2("U",7001,"Cash Receipt") 	#7001 Logic Error: Cash Receipt RECORD Does Not Exist
		CALL msgerror("",kandoomsg2("U",7001,"Cash Receipt"))
		RETURN 
	END IF 

	CALL db_customer_get_rec(UI_OFF,glob_rec_cashreceipt.cust_code ) RETURNING glob_rec_customer.* 
--	SELECT * INTO glob_rec_customer.* FROM customer 
--	WHERE cmpy_code = p_company_cmpy_code 
--	AND cust_code = glob_rec_cashreceipt.cust_code 
	IF glob_rec_customer.cust_code IS NULL THEN
		#ERROR kandoomsg2("U",7001,"Customer") 	#7001 Logic Error: Customer RECORD Does Not Exist
		CALL msgerror("",kandoomsg2("U",7001,"Customer"))
		RETURN 
	END IF 

	SELECT * INTO modu_rec_bank.* FROM bank 
	WHERE acct_code = glob_rec_cashreceipt.cash_acct_code 
	AND cmpy_code = p_company_cmpy_code 
	IF glob_rec_cashreceipt.cust_code = modu_rec_bank.bank_code THEN 
		#ERROR kandoomsg2("A",6997,"") 	#6997 Sundry Receipt - Cannot Edit
		#CALL msgerror("",kandoomsg2("A",6997,""))
		CALL msgerror("","Sundry Receipt - Cannot edit.")
		RETURN 
	END IF 

	IF glob_rec_cashreceipt.posted_flag = CASHRECEIPT_POST_FLAG_STATUS_ON_HOLD_H THEN 
		#ERROR kandoomsg2("A",7007,"put on hold") 	#7007 Cash Receipt IS on hold - cannot edit
		CALL msgerror("",kandoomsg2("A",7007,"put on hold"))
		RETURN 
	END IF 

	IF glob_rec_cashreceipt.posted_flag = CASHRECEIPT_POST_FLAG_STATUS_VOIDED_V THEN 
		#ERROR kandoomsg2("A",7007,"voided") 	#7007 Cash Receipt has been voided - cannot edit
		CALL msgerror("",kandoomsg2("A",7007,"voided"))
		RETURN 
	END IF 

	IF glob_rec_cashreceipt.posted_flag = CASHRECEIPT_POST_FLAG_STATUS_POSTED_Y THEN 
		#ERROR kandoomsg2("A",7007,"posted") 	#7007 Cash receipt has been posted - cannot edit
		CALL msgerror("",kandoomsg2("A",7007,"posted"))
		RETURN 
	END IF 

	IF get_url_cashreceipt_number() IS NULL THEN 
		IF glob_rec_cashreceipt.banked_flag = "Y" THEN 
			#ERROR kandoomsg2("A",7007,"banked") 		#7007 Cash receipt has been banked - cannot edit
			CALL msgerror("",kandoomsg2("A",7007,"banked"))
			RETURN 
		END IF 
		IF glob_rec_cashreceipt.cash_amt = glob_rec_cashreceipt.applied_amt 
		AND glob_rec_cashreceipt.cash_amt != 0 THEN 
			#ERROR kandoomsg2("A",7007,"fully applied") 		#7007 Cash receipt has been fully applied - cannot edit
			CALL msgerror("",kandoomsg2("A",7007,"fully applied"))			
			RETURN 
		END IF 
	END IF 

	LET modu_chng_amt = glob_rec_cashreceipt.cash_amt 

	### Save cash amount TO temporary variable as
	### needed IF locking problems occur
	### Also save original amount in field just FOR testing
	### that another edit has NOT occurred
	LET l_orig_cash_amt = glob_rec_cashreceipt.cash_amt 
	LET modu_pv_amt = modu_chng_amt 
	LET l_set_up_conv_qty = false 

	CALL get_conv_rate(
		p_company_cmpy_code, 
		glob_rec_customer.currency_code, 
		glob_rec_cashreceipt.cash_date, 
		CASH_EXCHANGE_SELL) 
	RETURNING glob_rec_cashreceipt.conv_qty 

	IF glob_rec_cashreceipt.conv_qty IS NULL 
	OR glob_rec_cashreceipt.conv_qty = "" THEN 
		LET glob_rec_cashreceipt.conv_qty = 0 
	END IF 
	LET l_foreign_amt = 0 

	CALL arparms_init() # AR/Account Receivable Parameters (arparms)

	SELECT base_currency_code INTO l_base_currency FROM glparms 
	WHERE key_code = "1" 
	AND cmpy_code = p_company_cmpy_code 
	IF status = NOTFOUND THEN 
		#ERROR kandoomsg2("G",7006,"") 	#7006 General Ledger Parms NOT SET up; Refer TO GZP.
		CALL msgerror("",kandoomsg2("G",7006,""))
		EXIT PROGRAM 
	END IF 

	OPEN WINDOW A153 with FORM "A153" 
	CALL windecoration_a("A153") 

	MESSAGE kandoomsg2("A",1023,"") #1023 Enter Cash Receipt; F8 FOR Customer Information
	DISPLAY BY NAME glob_rec_customer.name_text 

	SELECT * INTO modu_rec_bank.* FROM bank 
	WHERE acct_code = glob_rec_cashreceipt.cash_acct_code 
	AND cmpy_code = p_company_cmpy_code 
	LET l_reference_text = kandooword("cashreceipt.cash_type_ind", 
	glob_rec_cashreceipt.cash_type_ind) 

	DISPLAY glob_rec_cashreceipt.cust_code TO cust_code
	CALL combolist_order_num("order_num", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,combo_null_none)
	 
	DISPLAY glob_rec_customer.name_text TO name_text 
	DISPLAY modu_rec_bank.bank_code TO bank_code 
	DISPLAY modu_rec_bank.name_acct_text TO name_acct_text 
	DISPLAY glob_rec_cashreceipt.cash_num TO cash_num 
	DISPLAY glob_rec_cashreceipt.order_num TO order_num 
	DISPLAY glob_rec_cashreceipt.cash_type_ind TO cash_type_ind 
	DISPLAY l_reference_text TO reference_text 
	DISPLAY glob_rec_cashreceipt.currency_code TO currency_code 
	DISPLAY glob_rec_cashreceipt.bank_currency_code TO bank_currency_code 
	DISPLAY glob_rec_cashreceipt.cash_amt TO cash_amt 
	DISPLAY glob_rec_cashreceipt.cash_date TO cash_date 
	DISPLAY glob_rec_cashreceipt.year_num TO year_num 
	DISPLAY glob_rec_cashreceipt.period_num TO period_num 
	DISPLAY glob_rec_cashreceipt.cash_acct_code TO cash_acct_code
	DISPLAY db_coa_get_desc_text(UI_OFF,glob_rec_cashreceipt.cash_acct_code) TO coa.desc_text 
	DISPLAY glob_rec_cashreceipt.com1_text TO com1_text 
	DISPLAY glob_rec_cashreceipt.com2_text TO com2_text 
	DISPLAY glob_rec_cashreceipt.entry_date TO entry_date 
	DISPLAY glob_rec_cashreceipt.entry_code TO entry_code 

	INPUT 
		modu_rec_bank.bank_code, 
		glob_rec_cashreceipt.order_num, 
		glob_rec_cashreceipt.cash_type_ind, 
		glob_rec_cashreceipt.cash_date, 
		glob_rec_cashreceipt.cash_amt, 
		l_foreign_amt, 
		glob_rec_cashreceipt.conv_qty, 
		glob_rec_cashreceipt.year_num, 
		glob_rec_cashreceipt.period_num, 
		glob_rec_cashreceipt.com1_text, 
		glob_rec_cashreceipt.com2_text WITHOUT DEFAULTS 
	FROM 
		bank_code, 
		order_num, 
		cash_type_ind, 
		cash_date, 
		cash_amt, 
		foreign_amt, 
		conv_qty, 
		year_num, 
		period_num, 
		com1_text, 
		com2_text 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","A37a","inp-cashreceipt-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield (bank_code) 
					CALL show_bank(p_company_cmpy_code) 
					RETURNING 
						modu_rec_bank.bank_code, 
						glob_rec_cashreceipt.cash_acct_code 
					
					DISPLAY BY NAME 
						modu_rec_bank.bank_code, 
						glob_rec_cashreceipt.cash_acct_code 

					NEXT FIELD bank_code 

		ON ACTION "Account Status" --KEY (F8) 
			OPEN WINDOW A204 with FORM "A204" 
			CALL windecoration_a("A204") 

			DISPLAY BY NAME 
				glob_rec_customer.curr_amt, 
				glob_rec_customer.over1_amt, 
				glob_rec_customer.over30_amt, 
				glob_rec_customer.over60_amt, 
				glob_rec_customer.over90_amt, 
				glob_rec_customer.bal_amt, 
				glob_rec_customer.onorder_amt, 
				glob_rec_customer.cred_limit_amt, 
				glob_rec_customer.hold_code, 
				glob_rec_customer.last_pay_date 

			CALL eventsuspend() 
			#ERROR kandoomsg2("U",1,"")		#1 Press Any Key
			CLOSE WINDOW A204 


		ON CHANGE bank_code
			DISPLAY db_bank_get_name_acct_text(UI_OFF,modu_rec_bank.bank_code) TO bank.name_acct_text
		

		BEFORE FIELD bank_code 
			IF get_url_cashreceipt_number() IS NOT NULL THEN 
				NEXT FIELD NEXT 
			END IF 

		AFTER FIELD bank_code 
			SELECT * INTO modu_rec_bank.* FROM bank 
			WHERE bank_code = modu_rec_bank.bank_code 
			AND cmpy_code = p_company_cmpy_code 
			IF status = NOTFOUND THEN 
				ERROR kandoomsg2("U",9105,"") 			#9105 RECORD Not Found; Try Window
				NEXT FIELD bank_code 
			END IF 
			
			IF modu_rec_bank.currency_code != glob_rec_customer.currency_code THEN 
				IF modu_rec_bank.currency_code != l_base_currency THEN 
					ERROR kandoomsg2("A",9133,"") 				#9133 Bank account must be of base currency OR customer currency
					NEXT FIELD bank_code 
				END IF 
			END IF 

			IF modu_rec_bank.currency_code != glob_rec_customer.currency_code THEN 
				LET glob_rec_cashreceipt.bank_currency_code = modu_rec_bank.currency_code 
			END IF 

			LET glob_rec_cashreceipt.cash_acct_code = modu_rec_bank.acct_code 

			DISPLAY BY NAME 
				modu_rec_bank.name_acct_text, 
				modu_rec_bank.name_acct_text, 
				glob_rec_cashreceipt.currency_code, 
				glob_rec_cashreceipt.bank_currency_code 

			LET glob_rec_cashreceipt.bank_currency_code = modu_rec_bank.currency_code 

		AFTER FIELD order_num 
			IF glob_rec_cashreceipt.order_num IS NOT NULL	AND l_rec_company.module_text[23] = "W" THEN 
				SELECT unique 1 FROM ordhead 
				WHERE cmpy_code = p_company_cmpy_code 
				AND order_num = glob_rec_cashreceipt.order_num 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("A",9517,"") 				#9517 Order NOT found
					NEXT FIELD order_num 
				END IF 
			END IF 

		AFTER FIELD cash_type_ind 
			IF glob_rec_cashreceipt.cash_type_ind IS NULL OR glob_rec_cashreceipt.cash_type_ind NOT matches "[CQPO]" THEN 
				ERROR kandoomsg2("U",9112,"Payment Type") 			#9112 Invalid Payment Type
				NEXT FIELD cash_type_ind 
			END IF 
			
			LET l_reference_text = kandooword("cashreceipt.cash_type_ind",glob_rec_cashreceipt.cash_type_ind) 
			
			DISPLAY l_reference_text TO reference_text 

		AFTER FIELD cash_date 
			IF glob_rec_cashreceipt.cash_date IS NULL THEN 
				LET glob_rec_cashreceipt.cash_date = today 
				CALL db_period_what_period(p_company_cmpy_code,glob_rec_cashreceipt.cash_date) 
				RETURNING 
					glob_rec_cashreceipt.year_num, 
					glob_rec_cashreceipt.period_num 
			END IF
			 
			DISPLAY BY NAME 
				glob_rec_cashreceipt.period_num, 
				glob_rec_cashreceipt.year_num 

			IF l_set_up_conv_qty THEN 
				CALL get_conv_rate(
					p_company_cmpy_code, 
					glob_rec_customer.currency_code, 
					glob_rec_cashreceipt.cash_date, 
					CASH_EXCHANGE_SELL) 
				RETURNING glob_rec_cashreceipt.conv_qty
				 
				IF glob_rec_cashreceipt.conv_qty IS NULL OR glob_rec_cashreceipt.conv_qty = "" THEN 
					LET glob_rec_cashreceipt.conv_qty = 0 
				END IF 
				DISPLAY BY NAME glob_rec_cashreceipt.conv_qty 

			END IF 

		BEFORE FIELD conv_qty 
			LET l_last_conv_qty = glob_rec_cashreceipt.conv_qty 
			IF modu_rec_bank.currency_code = l_base_currency AND glob_rec_customer.currency_code = l_base_currency THEN 
				IF l_last_field = "cash_amt" OR l_last_field = "l_foreign_amt" THEN 
					NEXT FIELD year_num 
				ELSE 
					NEXT FIELD foreign_amt 
				END IF 
			END IF 
			
			IF modu_rec_bank.currency_code != l_base_currency	AND glob_rec_customer.currency_code != l_base_currency THEN 
				IF glob_rec_cashreceipt.cash_amt != 0 AND l_foreign_amt != 0 THEN 
					IF l_last_field = "l_foreign_amt" THEN 
						NEXT FIELD year_num 
					ELSE 
						NEXT FIELD foreign_amt 
					END IF 
				END IF 
			END IF 
			
			IF modu_rec_bank.currency_code = l_base_currency AND glob_rec_customer.currency_code != l_base_currency THEN 
				IF glob_rec_cashreceipt.cash_amt != 0 AND l_foreign_amt != 0 THEN 
					LET glob_rec_cashreceipt.conv_qty = glob_rec_cashreceipt.cash_amt /	l_foreign_amt 
					
					DISPLAY BY NAME glob_rec_cashreceipt.conv_qty 

					LET l_set_up_conv_qty = false 
					
					IF l_last_field = "cash_amt" OR l_last_field = "l_foreign_amt" THEN 
						NEXT FIELD year_num 
					ELSE 
						NEXT FIELD foreign_amt 
					END IF 
				END IF 
			END IF 

		AFTER FIELD conv_qty 
			IF glob_rec_cashreceipt.conv_qty IS NULL THEN 
				ERROR kandoomsg2("A",9180,"") 			#9180 Exchange Rate must be entered
				NEXT FIELD conv_qty 
			END IF 
			IF glob_rec_cashreceipt.conv_qty <= 0 THEN 
				ERROR kandoomsg2("A",9181,"") 			#9181 Exchange Rate must be greater than zero.
				NEXT FIELD conv_qty 
			END IF 
			IF l_last_conv_qty != glob_rec_cashreceipt.conv_qty THEN 
				LET l_set_up_conv_qty = false 
			END IF 
			LET l_last_field = "conv_qty" 

		AFTER FIELD year_num 
			LET l_last_field = "year_num" 

		AFTER FIELD cash_amt 
			IF glob_rec_cashreceipt.cash_amt IS NULL THEN 
				ERROR kandoomsg2("A",9102,"") 
				NEXT FIELD cash_amt 
			END IF 
			
			SELECT cash_amt INTO l_cash_amt FROM cashreceipt 
			WHERE cmpy_code = p_company_cmpy_code 
			AND cash_num = p_cashnum 
			IF status != NOTFOUND THEN 
				IF l_cash_amt < 0 THEN 
					IF glob_rec_cashreceipt.cash_amt > 0 THEN 
						ERROR kandoomsg2("A",9005,"") 					#9005 Receipt must be negative amount
						NEXT FIELD cash_amt 
					END IF 
					IF glob_rec_cashreceipt.applied_amt < glob_rec_cashreceipt.cash_amt THEN 
						ERROR kandoomsg2("A",9008,"") 			#9008 Cash Receipt must exceed applied amount
						NEXT FIELD cash_amt 
					END IF 
				ELSE 
					IF glob_rec_cashreceipt.cash_amt < 0 THEN 
						ERROR kandoomsg2("A",9006,"") 		#9006 Cannot apply positive amount TO negative amount
						NEXT FIELD cash_amt 
					END IF 
					IF glob_rec_cashreceipt.applied_amt > glob_rec_cashreceipt.cash_amt THEN 
						ERROR kandoomsg2("A",9008,"") 				#9008 Cash Receipt must exceed applied amount
						NEXT FIELD cash_amt 
					END IF 
				END IF 
			END IF 

			LET l_last_field = "cash_amt" 

		BEFORE FIELD foreign_amt 
			LET l_last_foreign_amt = l_foreign_amt 
			IF (modu_rec_bank.currency_code = l_base_currency	AND glob_rec_customer.currency_code = l_base_currency) THEN 
				IF l_last_field = "cash_amt" THEN 
					NEXT FIELD year_num 
				ELSE 
					NEXT FIELD cash_amt 
				END IF 
			END IF 
			
			IF (modu_rec_bank.currency_code != l_base_currency AND glob_rec_customer.currency_code != l_base_currency) THEN 
				IF l_last_field = "cash_amt" THEN 
					NEXT FIELD conv_qty 
				ELSE 
					NEXT FIELD cash_amt 
				END IF 
			END IF 

		AFTER FIELD foreign_amt 
			IF l_foreign_amt IS NULL THEN 
				LET l_foreign_amt = 0 
				DISPLAY l_foreign_amt TO foreign_amt  

			END IF 
			IF l_last_foreign_amt != l_foreign_amt AND l_foreign_amt = 0 THEN 
				CALL get_conv_rate(
					p_company_cmpy_code, 
					glob_rec_customer.currency_code, 
					glob_rec_cashreceipt.cash_date, 
					CASH_EXCHANGE_SELL) 
				RETURNING glob_rec_cashreceipt.conv_qty
				 
				IF glob_rec_cashreceipt.conv_qty IS NULL OR glob_rec_cashreceipt.conv_qty = "" THEN 
					LET glob_rec_cashreceipt.conv_qty = 0 
				END IF 
				
				DISPLAY BY NAME glob_rec_cashreceipt.conv_qty 

				LET l_set_up_conv_qty = true 
			END IF 
			
			IF modu_rec_bank.currency_code = l_base_currency AND glob_rec_customer.currency_code != l_base_currency THEN 
				IF glob_rec_cashreceipt.cash_amt != 0 AND l_foreign_amt != 0 THEN 
					LET glob_rec_cashreceipt.conv_qty = glob_rec_cashreceipt.cash_amt /	l_foreign_amt 
					
					DISPLAY BY NAME glob_rec_cashreceipt.conv_qty 

					LET l_set_up_conv_qty = false 
				END IF 
			END IF 
			
			LET l_last_field = "l_foreign_amt" 
		
		AFTER FIELD period_num 
			CALL valid_period(
				p_company_cmpy_code, 
				glob_rec_cashreceipt.year_num, 
				glob_rec_cashreceipt.period_num, 
				LEDGER_TYPE_AR) 
			RETURNING 
				glob_rec_cashreceipt.year_num, 
				glob_rec_cashreceipt.period_num, 
				modu_failed_it 
			IF modu_failed_it = 1 THEN 
				NEXT FIELD year_num 
			END IF 
		
		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN 
				IF glob_rec_cashreceipt.cash_type_ind = PAYMENT_TYPE_CHEQUE_Q THEN 
					IF NOT banking() THEN 
						NEXT FIELD bank_code 
					END IF 
				END IF 
				IF glob_rec_cashreceipt.cash_type_ind = PAYMENT_TYPE_CC_P THEN 
					IF NOT cards() THEN 
						NEXT FIELD bank_code 
					END IF 
				END IF 
			END IF 

	END INPUT
	#----------------------------------------------------
 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	ELSE 
		GOTO bypass 
		LABEL recovery: 
		LET modu_try_again = error_recover(modu_err_message, status) 
		IF modu_try_again != "Y" THEN 
			EXIT PROGRAM 
		END IF 
		LET modu_chng_amt = modu_pv_amt 
		
		LABEL bypass: 
		WHENEVER ERROR GOTO recovery 
		
		BEGIN WORK 
			DECLARE c_cashreceipt CURSOR FOR 
			SELECT * FROM cashreceipt 
			WHERE cmpy_code = p_company_cmpy_code 
			AND cash_num = glob_rec_cashreceipt.cash_num 
			FOR UPDATE 
			
			FOREACH c_cashreceipt INTO l_rec_cashreceipt.* 
				IF get_url_cashreceipt_number() IS NULL THEN 
					IF l_rec_cashreceipt.banked_flag = 'Y' THEN 
						ERROR kandoomsg2("W",7027,"") 		#7027 Cash Receipt has been edited by another user  Can NOT UPDATE details
						ROLLBACK WORK 
						CLOSE WINDOW A153 
						RETURN 
					END IF 
				END IF 

				IF l_rec_cashreceipt.cash_amt <> l_orig_cash_amt 
				OR l_rec_cashreceipt.applied_amt <> glob_rec_cashreceipt.applied_amt 
				OR l_rec_cashreceipt.posted_flag = CASHRECEIPT_POST_FLAG_STATUS_POSTED_Y THEN 
					ERROR kandoomsg2("W",7027,"") #7027 Cash Receipt has been edited by another user  Can NOT UPDATE details
					ROLLBACK WORK 
					CLOSE WINDOW A153 
					RETURN 
				END IF 
				EXIT FOREACH 
			END FOREACH 
			
			LET modu_chng_amt = modu_chng_amt - glob_rec_cashreceipt.cash_amt 

			UPDATE cashreceipt SET * = glob_rec_cashreceipt.* 
			WHERE cmpy_code = p_company_cmpy_code 
			AND cash_num = glob_rec_cashreceipt.cash_num 

			IF modu_chng_amt != 0 THEN 
				LET modu_err_message = "A37 - Custmain UPDATE" 

				DECLARE curr_amts CURSOR FOR 
				SELECT * INTO glob_rec_customer.* FROM customer 
				WHERE cmpy_code = p_company_cmpy_code 
				AND cust_code = glob_rec_cashreceipt.cust_code 
				FOR UPDATE 
				
				FOREACH curr_amts 
					LET glob_rec_customer.bal_amt = glob_rec_customer.bal_amt + modu_chng_amt 
					LET glob_rec_customer.curr_amt = glob_rec_customer.curr_amt + modu_chng_amt 
					LET glob_rec_customer.last_pay_date = glob_rec_cashreceipt.cash_date 
					LET glob_rec_customer.next_seq_num = glob_rec_customer.next_seq_num + 1 
					LET glob_rec_customer.cred_bal_amt = glob_rec_customer.cred_limit_amt -	(glob_rec_customer.bal_amt + glob_rec_customer.onorder_amt) 
					LET glob_rec_customer.ytdp_amt = glob_rec_customer.ytdp_amt + modu_chng_amt 
					LET glob_rec_customer.mtdp_amt = glob_rec_customer.mtdp_amt + modu_chng_amt 

					UPDATE customer 
					SET 
						bal_amt = glob_rec_customer.bal_amt, 
						curr_amt = glob_rec_customer.curr_amt, 
						last_pay_date = glob_rec_customer.last_pay_date, 
						next_seq_num = glob_rec_customer.next_seq_num, 
						cred_bal_amt = glob_rec_customer.cred_bal_amt, 
						ytdp_amt = glob_rec_customer.ytdp_amt, 
						mtdp_amt = glob_rec_customer.mtdp_amt 
					WHERE CURRENT OF curr_amts 
				END FOREACH 
				
				LET modu_rec_araudit.cmpy_code = p_company_cmpy_code 
				LET modu_rec_araudit.tran_date = today 
				LET modu_rec_araudit.cust_code = glob_rec_cashreceipt.cust_code 
				LET modu_rec_araudit.seq_num = glob_rec_customer.next_seq_num 
				LET modu_rec_araudit.tran_type_ind = TRAN_TYPE_RECEIPT_CA 
				LET modu_rec_araudit.source_num = glob_rec_cashreceipt.cash_num 
				LET modu_rec_araudit.tran_text = "Edit Receipt" 
				LET modu_rec_araudit.tran_amt = modu_chng_amt 
				LET modu_rec_araudit.entry_code = p_kandoouser_sign_on_code 
				LET modu_rec_araudit.year_num = glob_rec_cashreceipt.year_num 
				LET modu_rec_araudit.period_num = glob_rec_cashreceipt.period_num 
				LET modu_rec_araudit.bal_amt = glob_rec_customer.bal_amt 
				LET modu_rec_araudit.currency_code = glob_rec_customer.currency_code 
				LET modu_rec_araudit.conv_qty = glob_rec_cashreceipt.conv_qty 
				LET modu_rec_araudit.entry_date = today 
				LET modu_err_message = "A37 - Daily log INSERT" 

				INSERT INTO araudit VALUES (modu_rec_araudit.*) 

			END IF 
		COMMIT WORK 
	END IF 

	WHENEVER ERROR stop 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

	CLOSE WINDOW A153 

END FUNCTION 
############################################################
# END FUNCTION cashreceipt_edit(p_company_cmpy_code, p_cashnum, p_kandoouser_sign_on_code)
############################################################


############################################################
# FUNCTION banking()
#
#
############################################################
FUNCTION banking() 

	OPEN WINDOW A151 with FORM "A151" 
	CALL windecoration_a("A151") 

	MESSAGE kandoomsg2("U",1020,"Cheque") #1020 Enter Cheque Details; OK TO Continue
	DISPLAY BY NAME 
		glob_rec_cashreceipt.bank_text, 
		glob_rec_cashreceipt.branch_text, 
		glob_rec_cashreceipt.drawer_text, 
		glob_rec_cashreceipt.cheque_text, 
		glob_rec_cashreceipt.chq_date 

	INPUT BY NAME 
		glob_rec_cashreceipt.bank_text, 
		glob_rec_cashreceipt.branch_text, 
		glob_rec_cashreceipt.drawer_text, 
		glob_rec_cashreceipt.cheque_text, 
		glob_rec_cashreceipt.chq_date WITHOUT DEFAULTS ATTRIBUTE(UNBUFFERED) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","A37a","inp-cashreceipt-2") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 
	END INPUT 

	CLOSE WINDOW A151 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 

	RETURN true 
END FUNCTION 
############################################################
# END FUNCTION banking()
############################################################


############################################################
# FUNCTION cards()
#
#
############################################################
FUNCTION cards() 
	DEFINE l_card_type CHAR(1) 
	DEFINE l_month_exp, l_year_exp SMALLINT 

	OPEN WINDOW A632 with FORM "A632" 
	CALL windecoration_a("A632") 

	LET l_month_exp = glob_rec_cashreceipt.card_exp_date[1,2] 
	LET l_year_exp = glob_rec_cashreceipt.card_exp_date[3,4] 
	LET l_card_type = glob_rec_cashreceipt.bank_text[1] 

	MESSAGE kandoomsg2("U",1020,"Credit Card") #1020 Enter Credit Card Details; OK TO Continue
	INPUT 
		l_card_type, 
		glob_rec_cashreceipt.bank_text, 
		glob_rec_cashreceipt.branch_text, 
		glob_rec_cashreceipt.drawer_text, 
		l_month_exp, 
		l_year_exp WITHOUT DEFAULTS 
	FROM
		card_type, 
		bank_text, 
		branch_text, 
		drawer_text, 
		month_exp, 
		year_exp ATTRIBUTE(UNBUFFERED)	

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","A37a","inp-cashreceipt-3") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER FIELD card_type 
			IF l_card_type = "V" THEN 
				LET glob_rec_cashreceipt.bank_text = "VISA" 
			END IF 
			IF l_card_type = "M" THEN 
				LET glob_rec_cashreceipt.bank_text = "MASTERCARD" 
			END IF 
			IF l_card_type = "B" THEN 
				LET glob_rec_cashreceipt.bank_text = "BANKCARD" 
			END IF 
			IF l_card_type = "A" THEN 
				LET glob_rec_cashreceipt.bank_text = "AMEX" 
			END IF 
			IF l_card_type = "D" THEN 
				LET glob_rec_cashreceipt.bank_text = "DINERS CLUB" 
			END IF 

		AFTER FIELD branch_text 
			IF glob_rec_cashreceipt.branch_text IS NOT NULL THEN 
				IF verify_creditcard_number(glob_rec_cashreceipt.branch_text) THEN 
					ERROR kandoomsg2("K",6000,"") 				#6000 Invalid Credit Card Number Entered.
				END IF 
			END IF 

	END INPUT 

	CLOSE WINDOW A632 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 

	LET glob_rec_cashreceipt.card_exp_date = l_month_exp USING "&&", 
	l_year_exp USING "&&" 

	RETURN true 
END FUNCTION 
############################################################
# END FUNCTION cards()
############################################################


############################################################
# FUNCTION verify_creditcard_number(p_card_num)
#
#
############################################################
FUNCTION verify_creditcard_number(p_card_num) 
	DEFINE p_card_num CHAR(20) 
	DEFINE l_string CHAR(2) 
	DEFINE l_check_sum SMALLINT 
	DEFINE l_num_check SMALLINT 
	DEFINE l_total SMALLINT 
	DEFINE l_num SMALLINT 
	DEFINE x SMALLINT 
	DEFINE y SMALLINT 
	DEFINE l_card_length SMALLINT 
	DEFINE l_idx SMALLINT 

	LET l_total = 0 
	LET l_check_sum = 0 
	LET l_card_length = length(p_card_num) 
	LET l_num_check = 2 
	
	FOR l_idx = l_card_length TO 1 step -1 
		IF p_card_num[l_idx] = " " THEN 
			CONTINUE FOR 
		END IF 

		IF p_card_num[l_idx] = "-" THEN 
			CONTINUE FOR 
		END IF 

		IF p_card_num[l_idx] NOT matches "[1234567890]" THEN 
			RETURN true 
		END IF 

		IF l_num_check = 2 THEN 
			LET l_num_check = 1 
		ELSE 
			LET l_num_check = 2 
		END IF 

		LET x = l_num_check 
		LET y = p_card_num[l_idx] 
		LET l_num = x * y 

		IF l_num > 9 THEN 
			LET l_string = l_num 
			LET x = l_string[1] 
			LET y = l_string[2] 
			LET l_num = x + y 
		END IF 

		LET l_total = l_total + l_num 

	END FOR 

	LET l_check_sum = l_total mod 10 

	IF l_check_sum = 0 THEN 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 
############################################################
# END FUNCTION verify_creditcard_number(p_card_num)
############################################################