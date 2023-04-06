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

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl" 
GLOBALS "../ar/A3_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/A31_GLOBALS.4gl" 
GLOBALS "../ar/A33_GLOBALS.4gl" 

############################################################
# FUNCTION A33_enter_receipt()
#
# \brief module - A33a.4gl
# Purpose - FUNCTION A33_enter_receipt allows the user TO enter cash
#           receipts FOR non debtors
############################################################
FUNCTION A33_enter_receipt() 
	DEFINE l_rec_bank RECORD LIKE bank.* 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_invalid_period INTEGER 
	DEFINE l_reference_text LIKE kandooword.reference_text 
	
	CLEAR FORM 
	MESSAGE kandoomsg2("A",1059,"")	#1059 Enter Sundry Receipt Information;  OK TO Continue.
	IF glob_rec_cashreceipt.bank_code IS NULL THEN 
		DECLARE c1_bank CURSOR FOR 
		SELECT * FROM bank 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND acct_code = glob_rec_arparms.cash_acct_code
		 
		OPEN c1_bank 
		FETCH c1_bank INTO l_rec_bank.* 
		
		LET glob_rec_cashreceipt.cash_date = today 
		LET glob_rec_cashreceipt.chq_date = today 
		LET glob_rec_cashreceipt.cash_amt = 0 
		LET glob_rec_cashreceipt.applied_amt = 0 
		LET glob_rec_cashreceipt.order_num = NULL 
		LET glob_rec_cashreceipt.cash_type_ind = "C" 
		LET glob_rec_cashreceipt.conv_qty = NULL 

		CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,today) 		
		RETURNING 
			glob_rec_cashreceipt.year_num, 
			glob_rec_cashreceipt.period_num 
	END IF 

	LET l_reference_text = kandooword("cashreceipt.cash_type_ind",glob_rec_cashreceipt.cash_type_ind)
	 
	DISPLAY l_reference_text  TO reference_text

	INPUT BY NAME 
		glob_rec_cashreceipt.bank_code, 
		glob_rec_cashreceipt.order_num, 
		glob_rec_cashreceipt.cash_amt, 
		glob_rec_cashreceipt.cash_type_ind, 
		glob_rec_cashreceipt.cash_date, 
		glob_rec_cashreceipt.com1_text, 
		glob_rec_cashreceipt.com2_text, 
		glob_rec_cashreceipt.year_num, 
		glob_rec_cashreceipt.period_num, 
		glob_rec_cashreceipt.conv_qty WITHOUT DEFAULTS 


		BEFORE INPUT 
			CALL publish_toolbar("kandoo","A33a","inp-cashreceipt") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
			
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield(bank_code) 
				CALL show_bank(glob_rec_kandoouser.cmpy_code) 
				RETURNING glob_rec_cashreceipt.bank_code, glob_rec_cashreceipt.cash_acct_code 
				NEXT FIELD bank_code 
 
		AFTER FIELD bank_code 
			SELECT * INTO l_rec_bank.* 
			FROM bank 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND bank_code = glob_rec_cashreceipt.bank_code 
			IF status = NOTFOUND THEN 
				ERROR kandoomsg2("A",9132,"") 			#9132 Bank code NOT found;  Try Window.
				NEXT FIELD bank_code 
			END IF 
			
			## Sundry debtor has cust_code = bank_code
			CALL db_customer_get_rec_not_deleted(UI_OFF,glob_rec_cashreceipt.bank_code ) RETURNING l_rec_customer.*
--			SELECT * INTO l_rec_customer.* 
--			FROM customer 
--			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
--			AND cust_code = glob_rec_cashreceipt.bank_code # ???????
--			AND delete_flag = "N" 

			IF l_rec_customer.cust_code IS NULL THEN			
--			IF status = NOTFOUND THEN 
				ERROR kandoomsg2("A",7063,"") 			#7063 Banks must have an associated "sundry" debtor SET up
				#     before receipts may be entered.  Refer manual.
				NEXT FIELD bank_code 
			END IF 
			
			IF l_rec_bank.currency_code != l_rec_customer.currency_code THEN 
				ERROR kandoomsg2("A",7064,"") 			#7064 Error: Sundry debtor & bank must have same currency ...
				NEXT FIELD bank_code 
			END IF 
			
			LET glob_rec_cashreceipt.cust_code = l_rec_customer.cust_code 
			LET glob_rec_cashreceipt.currency_code = l_rec_bank.currency_code 
			LET glob_rec_cashreceipt.conv_qty = get_conv_rate(
				glob_rec_kandoouser.cmpy_code,
				l_rec_customer.currency_code, 
				glob_rec_cashreceipt.cash_date,
				CASH_EXCHANGE_SELL) 
			
			DISPLAY BY NAME 
				l_rec_bank.name_acct_text, 
				glob_rec_cashreceipt.conv_qty 

			DISPLAY BY NAME glob_rec_cashreceipt.currency_code #HuHo: attribute(GREEN) #why with color / green ? I'll remove it
			
		AFTER FIELD cash_type_ind 
			IF glob_rec_cashreceipt.cash_type_ind IS NULL	OR glob_rec_cashreceipt.cash_type_ind NOT matches "[CQPO]" THEN 
				ERROR kandoomsg2("U",9112,"Payment Type") #9112 Invalid Payment Type.
				NEXT FIELD cash_type_ind 
			END IF 

			LET l_reference_text = kandooword("cashreceipt.cash_type_ind", 	glob_rec_cashreceipt.cash_type_ind)
			 
			DISPLAY l_reference_text TO reference_text 

		AFTER FIELD cash_date 
			IF glob_rec_cashreceipt.cash_date IS NULL THEN 
				LET glob_rec_cashreceipt.cash_date = today 
				NEXT FIELD cash_date 
			END IF
			 
			CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, glob_rec_cashreceipt.cash_date) 
			RETURNING 
				glob_rec_cashreceipt.year_num,
				glob_rec_cashreceipt.period_num 
			
			LET glob_rec_cashreceipt.conv_qty = get_conv_rate(
				glob_rec_kandoouser.cmpy_code,
				glob_rec_cashreceipt.currency_code, 
				glob_rec_cashreceipt.cash_date,
				CASH_EXCHANGE_SELL) 
			
			IF glob_rec_cashreceipt.conv_qty IS NULL THEN 
				LET glob_rec_cashreceipt.conv_qty = 1 
			END IF 
			
			DISPLAY BY NAME 
				glob_rec_cashreceipt.period_num, 
				glob_rec_cashreceipt.year_num, 
				glob_rec_cashreceipt.conv_qty 

		AFTER FIELD period_num 
			CALL valid_period(
				glob_rec_kandoouser.cmpy_code,
				glob_rec_cashreceipt.year_num,	
				glob_rec_cashreceipt.period_num,
				LEDGER_TYPE_AR) 
			RETURNING glob_rec_cashreceipt.year_num, glob_rec_cashreceipt.period_num,	l_invalid_period 

			IF l_invalid_period THEN 
				CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,glob_rec_cashreceipt.cash_date) 
				RETURNING glob_rec_cashreceipt.year_num,	glob_rec_cashreceipt.period_num 
				
				DISPLAY glob_rec_cashreceipt.year_num TO year_num 
				DISPLAY glob_rec_cashreceipt.period_num TO period_num 

				NEXT FIELD year_num 
			END IF 

		AFTER FIELD cash_amt 
			IF glob_rec_cashreceipt.cash_amt IS NULL THEN 
				ERROR kandoomsg2("A",9131,"")			#9131 Receipt amount must be entered.
				NEXT FIELD cash_amt 
			END IF 
			IF glob_rec_cashreceipt.cash_amt < 0 THEN 
				IF kandoomsg("A",8012,"") != "Y" THEN			#8012 Has this negative cash receipt been authorized?
					NEXT FIELD cash_amt 
				END IF 
			END IF 

		BEFORE FIELD conv_qty	#from original... I don't get it... breaks navigation 
			--IF l_rec_bank.currency_code = glob_rec_glparms.base_currency_code THEN 
			--	NEXT FIELD previous 
			--END IF
			#changed too:  (but I'M not sure... what the orignal code really tried to do) 
			IF l_rec_bank.currency_code = glob_rec_glparms.base_currency_code THEN 
				NEXT FIELD NEXT 
			END IF 

		AFTER FIELD conv_qty 
			IF glob_rec_cashreceipt.conv_qty IS NULL THEN 
				LET glob_rec_cashreceipt.conv_qty =	get_conv_rate(
					glob_rec_kandoouser.cmpy_code,
					glob_rec_cashreceipt.currency_code,	
					glob_rec_cashreceipt.cash_date,
					CASH_EXCHANGE_SELL) 
				ERROR kandoomsg2("A",9117,"") 			#9117 Currency exchange rate must be entered.
				NEXT FIELD conv_qty 
			END IF 

			IF glob_rec_cashreceipt.conv_qty <= 0 THEN 
				ERROR kandoomsg2("A",9118,"")			#9118" Currency exchange rate must be greater than zero.
				NEXT FIELD conv_qty 
			END IF 
			
		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 

				IF glob_rec_cashreceipt.cash_amt <= 0 THEN
					ERROR "Receipt Amount can not be 0 / empty or negative !"
					CONTINUE INPUT
				END IF

				CALL valid_period(
					glob_rec_kandoouser.cmpy_code,
					glob_rec_cashreceipt.year_num,	
					glob_rec_cashreceipt.period_num, 
					LEDGER_TYPE_AR) 
				RETURNING 
					glob_rec_cashreceipt.year_num,
					glob_rec_cashreceipt.period_num,
					l_invalid_period 
				
				IF l_invalid_period THEN 
					NEXT FIELD year_num 
				END IF
				 
				IF glob_rec_cashreceipt.cash_type_ind = PAYMENT_TYPE_CHEQUE_Q THEN 
					IF NOT banking(glob_rec_cashreceipt.*,"") THEN 
						NEXT FIELD bank_code 
					END IF 
				END IF
				 
				IF glob_rec_cashreceipt.cash_type_ind = PAYMENT_TYPE_CC_P THEN 
					IF NOT cards(glob_rec_cashreceipt.*,"") THEN 
						NEXT FIELD bank_code 
					END IF 
				END IF 
			END IF 

	END INPUT
	 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 
############################################################
# END FUNCTION A33_enter_receipt()
############################################################