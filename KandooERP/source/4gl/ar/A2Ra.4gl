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
GLOBALS "../ar/A2_GROUP_GLOBALS.4gl"
GLOBALS "../ar/A2R_GLOBALS.4gl"

##########################################################################
# FUNCTION enter_refund()
#
# allows the user TO enter refunds FOR customers
##########################################################################
FUNCTION enter_refund() 
	DEFINE l_rec_s_vendor RECORD LIKE vendor.*
	DEFINE l_rec_customer RECORD LIKE customer.*
	DEFINE l_availcr_amt LIKE customer.bal_amt
	DEFINE l_invalid_period INTEGER 

	MESSAGE kandoomsg2("A",1061,"") #1061 Enter Refund Details
	LET glob_rec_arparms.inv_ref1_text = glob_rec_arparms.inv_ref1_text clipped,	"................" 
	
	WHILE TRUE 
		INITIALIZE l_rec_customer.* TO NULL 
		CLEAR FORM 
		DISPLAY BY NAME glob_rec_arparms.inv_ref1_text attribute(white) 

		# INPUT ---------------------------------------------------------------
		INPUT BY NAME glob_rec_invoicehead.cust_code 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","A2Ra","inp-cust_code") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			ON ACTION "LOOKUP" infield (cust_code) --lookup customer id 
				CALL show_clnt(glob_rec_kandoouser.cmpy_code) 
				RETURNING glob_rec_invoicehead.cust_code 
				NEXT FIELD cust_code 

			ON ACTION "CREDIT" --ON KEY (F8) --customer credit status 
				IF glob_rec_invoicehead.cust_code IS NOT NULL THEN 
					LET l_availcr_amt = l_rec_customer.cred_limit_amt 
						- l_rec_customer.bal_amt 
						- l_rec_customer.onorder_amt 

					OPEN WINDOW A618 with FORM "A618" 
					CALL windecoration_a("A618") 

					DISPLAY BY NAME l_rec_customer.currency_code #HuHo: attribute(GREEN) #why with color / green ? I'll remove it 
					DISPLAY BY NAME 
						l_rec_customer.curr_amt, 
						l_rec_customer.over1_amt, 
						l_rec_customer.over30_amt, 
						l_rec_customer.over60_amt, 
						l_rec_customer.over90_amt, 
						l_rec_customer.cred_limit_amt, 
						l_rec_customer.onorder_amt, 
						l_rec_customer.last_pay_date 

					DISPLAY l_rec_customer.bal_amt TO sr_balance[1].bal_amt 
					DISPLAY l_rec_customer.bal_amt TO sr_balance[2].bal_amt 
					DISPLAY l_availcr_amt TO availcr_amt 
					#MESSAGE kandoomsg2("U",1,"")
					
					CALL eventsuspend() 
					
					CLOSE WINDOW A618 
				ELSE 
					CALL fgl_winmessage("Customer ID","You need do specify the customer id prior","info") 
				END IF 

			AFTER FIELD cust_code 
				IF glob_rec_invoicehead.cust_code IS NULL THEN 
					ERROR kandoomsg2("A",9024,"") 				#9024 Customer Code must be entered
					NEXT FIELD cust_code 
				ELSE 
					CALL db_customer_get_rec(UI_OFF,glob_rec_invoicehead.cust_code) RETURNING l_rec_customer.*
--					SELECT * INTO l_rec_customer.* FROM customer 
--					WHERE cust_code = glob_rec_invoicehead.cust_code 
--					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					IF l_rec_customer.cust_code IS NULL THEN  
--					IF status = NOTFOUND THEN 					
						ERROR kandoomsg2("A",9009,"")		#9009 Customer Code does NOT exist. Try window
						NEXT FIELD cust_code 
					END IF 
					
					IF l_rec_customer.delete_flag = "Y" THEN 
						ERROR kandoomsg2("A",9144,"") 					#9144 Customer IS marked FOR deletion
						NEXT FIELD cust_code 
					END IF
					 
					IF l_rec_customer.hold_code IS NOT NULL THEN 
						ERROR kandoomsg2("A",9143,"") 					#9143 Customer IS on hold
						NEXT FIELD cust_code 
					END IF
					 
					IF l_rec_customer.corp_cust_code IS NOT NULL AND l_rec_customer.corp_cust_ind = "1" THEN 
						ERROR kandoomsg2("A",7069,"") 					#7069 You can NOT refund cash FOR a Subsidiary Debtor
						LET glob_rec_invoicehead.cust_code = l_rec_customer.corp_cust_code 
						NEXT FIELD cust_code 
					END IF 
				END IF 

			AFTER INPUT 
				IF not(int_flag OR quit_flag) THEN 
					IF glob_rec_invoicehead.cust_code IS NULL THEN 
						ERROR kandoomsg2("A",9024,"") 				#9024 Customer Code must be entered
						NEXT FIELD cust_code 
					ELSE 
						CALL db_customer_get_rec(UI_OFF,glob_rec_invoicehead.cust_code) RETURNING l_rec_customer.*
--						SELECT * INTO l_rec_customer.* FROM customer 
--						WHERE cust_code = glob_rec_invoicehead.cust_code 
--						AND cmpy_code = glob_rec_kandoouser.cmpy_code
						IF l_rec_customer.cust_code IS NULL THEN 
--						IF status = NOTFOUND THEN 
							ERROR kandoomsg2("A",9009,"") 						#9009 Customer Code does NOT exist. Try window
							NEXT FIELD cust_code 
						END IF 
					END IF 
				END IF 

		END INPUT 
		# END INPUT ---------------


		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			RETURN false 
			EXIT WHILE 
		END IF 

		INITIALIZE glob_rec_invoicehead.* TO NULL 
		INITIALIZE glob_rec_invoicedetl.* TO NULL 

		DECLARE c1_bank CURSOR FOR 
		SELECT * FROM bank 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND acct_code = glob_rec_arparms.cash_acct_code 

		OPEN c1_bank 
		FETCH c1_bank INTO glob_rec_bank.* 

		CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,today) 
		RETURNING glob_rec_invoicehead.year_num, glob_rec_invoicehead.period_num 

		LET glob_rec_invoicedetl.line_text = "Refund Payment" 
		LET glob_rec_invoicehead.inv_date = today 
		LET glob_rec_invoicehead.due_date = today 

		DISPLAY BY NAME 
			l_rec_customer.name_text, 
			l_rec_customer.addr1_text, 
			l_rec_customer.addr2_text, 
			l_rec_customer.city_text, 
			l_rec_customer.state_code, 
			l_rec_customer.post_code, 
			l_rec_customer.country_code, 
			glob_rec_invoicehead.total_amt, 
			glob_rec_invoicedetl.line_text, 
			glob_rec_invoicehead.inv_date, 
			glob_rec_invoicehead.due_date, 
			glob_rec_invoicehead.year_num, 
			glob_rec_invoicehead.period_num 

		DISPLAY BY NAME l_rec_customer.currency_code attribute(green) 

		INPUT BY NAME 
			glob_rec_invoicehead.total_amt, 
			glob_rec_invoicehead.purchase_code, 
			glob_rec_invoicedetl.line_text, 
			glob_rec_bank.bank_code, 
			glob_rec_invoicehead.inv_date, 
			glob_rec_invoicehead.due_date, 
			glob_rec_invoicehead.com1_text, 
			glob_rec_invoicehead.com2_text, 
			glob_rec_invoicehead.year_num, 
			glob_rec_invoicehead.period_num, 
			glob_rec_invoicehead.conv_qty WITHOUT DEFAULTS 


			BEFORE INPUT 
				CALL publish_toolbar("kandoo","A2Ra","inp-invoicehead") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			ON ACTION "LOOKUP" infield (bank_code) --lookup bank code 
				CALL show_bank(glob_rec_kandoouser.cmpy_code) 
				RETURNING glob_rec_bank.bank_code,	glob_rec_bank.acct_code 
				NEXT FIELD bank_code 

			ON KEY (F8)--Customer account status 
				LET l_availcr_amt = l_rec_customer.cred_limit_amt 
				- l_rec_customer.bal_amt 
				- l_rec_customer.onorder_amt 

				OPEN WINDOW A618 with FORM "A618" 
				CALL windecoration_a("A618") 

				DISPLAY BY NAME l_rec_customer.currency_code #HuHo: attribute(GREEN) #why with color / green ? I'll remove it
				DISPLAY BY NAME 
					l_rec_customer.curr_amt, 
					l_rec_customer.over1_amt, 
					l_rec_customer.over30_amt, 
					l_rec_customer.over60_amt, 
					l_rec_customer.over90_amt, 
					l_rec_customer.cred_limit_amt, 
					l_rec_customer.onorder_amt, 
					l_rec_customer.last_pay_date 

				DISPLAY 
					l_rec_customer.bal_amt, 
					l_rec_customer.bal_amt, 
					l_availcr_amt 
				TO 
					sr_balance[1].bal_amt, 
					sr_balance[2].bal_amt, 
					availcr_amt 

				CALL eventsuspend() 
				#MESSAGE kandoomsg2("U",1,"")
				CLOSE WINDOW A618 

			AFTER FIELD total_amt 
				IF glob_rec_invoicehead.total_amt IS NULL THEN 
					ERROR kandoomsg2("A",9217,"") 				#9217 Refund Amount must be greater than zero
					NEXT FIELD total_amt 
				END IF 
				IF glob_rec_invoicehead.total_amt <= 0 THEN 
					ERROR kandoomsg2("A",9217,"") 					#9217 Refund Amount must be greater than zero
					NEXT FIELD total_amt 
				END IF 

			AFTER FIELD bank_code 
				IF glob_rec_bank.bank_code IS NULL THEN 
					ERROR kandoomsg2("A",9505,"") 				#9505 Bank Account must be entered
					NEXT FIELD bank_code 
				ELSE 
					SELECT * INTO glob_rec_bank.* FROM bank 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND bank_code = glob_rec_bank.bank_code 
					IF status = NOTFOUND THEN 
						ERROR kandoomsg2("A",9132,"") 					#9132" Bank Account Not Found - Try Window "
						NEXT FIELD bank_code 
					END IF 
					
					IF glob_rec_bank.currency_code != l_rec_customer.currency_code THEN 
						ERROR kandoomsg2("A",7070,"") 					#A7070"Customer & bank must have same currency"
						NEXT FIELD bank_code 
					END IF 
					
					## Sundry creditor has vend_code = bank_code
					SELECT * INTO l_rec_s_vendor.* FROM vendor 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND vend_code = glob_rec_bank.bank_code 
					IF status = NOTFOUND THEN 
						ERROR kandoomsg2("A",7067,"") 					#A7067" Sundry creditor NOT SET FOR this bank"
						NEXT FIELD bank_code 
					END IF 
					
					IF glob_rec_bank.currency_code != l_rec_s_vendor.currency_code THEN 
						ERROR kandoomsg2("A",7068,"") 					#A7068"Sundry creditor & bank must have same currency"
						NEXT FIELD bank_code 
					END IF 
					
					IF l_rec_s_vendor.usual_acct_code IS NULL THEN 
						ERROR kandoomsg2("A",9218,"") 					#9218 Usual Account Code must be setup
						NEXT FIELD bank_code 
					END IF 
					
					LET glob_rec_invoicehead.cust_code = l_rec_customer.cust_code 
					LET glob_rec_invoicehead.currency_code = glob_rec_bank.currency_code 
					LET glob_rec_invoicehead.conv_qty =	get_conv_rate(
						glob_rec_kandoouser.cmpy_code,
						l_rec_customer.currency_code, 
						glob_rec_invoicehead.inv_date,
						CASH_EXCHANGE_SELL) 
					
					DISPLAY BY NAME 
						glob_rec_bank.name_acct_text, 
						glob_rec_invoicehead.conv_qty 

				END IF 

			AFTER FIELD inv_date 
				IF glob_rec_invoicehead.inv_date IS NULL THEN 
					LET glob_rec_invoicehead.inv_date = today 
					NEXT FIELD inv_date 
				END IF 

			AFTER FIELD period_num 
				CALL valid_period(
					glob_rec_kandoouser.cmpy_code,
					glob_rec_invoicehead.year_num, 
					glob_rec_invoicehead.period_num,
					LEDGER_TYPE_AR) 
				RETURNING 
					glob_rec_invoicehead.year_num, 
					glob_rec_invoicehead.period_num, 
					l_invalid_period 
					
				IF l_invalid_period THEN 
					CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,glob_rec_invoicehead.inv_date) 
					RETURNING glob_rec_invoicehead.year_num,glob_rec_invoicehead.period_num 
					
					DISPLAY BY NAME 
						glob_rec_invoicehead.year_num, 
						glob_rec_invoicehead.period_num 

					NEXT FIELD year_num 
				END IF 

			BEFORE FIELD conv_qty 
				IF l_rec_customer.currency_code = glob_rec_glparms.base_currency_code THEN 
					NEXT FIELD NEXT 
				END IF 

			AFTER FIELD conv_qty 
				IF glob_rec_invoicehead.conv_qty IS NULL THEN 
					LET glob_rec_invoicehead.conv_qty = get_conv_rate(
						glob_rec_kandoouser.cmpy_code,
						l_rec_customer.currency_code, 
						glob_rec_invoicehead.inv_date,
						CASH_EXCHANGE_SELL) 
					ERROR kandoomsg2("A",9117,"") 				#9117" Exchange rate must have a value"
					NEXT FIELD conv_qty 
				END IF 
				
				IF glob_rec_invoicehead.conv_qty <= 0 THEN 
					ERROR kandoomsg2("A",9118,"") 				#9118" Exchange Rate must be greater than zero"
					NEXT FIELD conv_qty 
				END IF 

			AFTER INPUT 
				IF not(int_flag OR quit_flag) THEN 
					IF glob_rec_invoicehead.total_amt <= 0 THEN 
						ERROR kandoomsg2("A",9217,"") 					#9217 Refund Amount must be greater than zero
						NEXT FIELD total_amt 
					END IF 
					
					IF glob_rec_bank.bank_code IS NULL THEN 
						ERROR kandoomsg2("A",9505,"") 					#9505 Bank Account must be entered
						NEXT FIELD bank_code 
					ELSE 
						SELECT * INTO glob_rec_bank.* FROM bank 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND bank_code = glob_rec_bank.bank_code 
						IF status = NOTFOUND THEN 
							ERROR kandoomsg2("A",9132,"") 						#9132" Bank Account Not Found - Try Window "
							NEXT FIELD bank_code 
						END IF 
						
						#-----------------------------------------
						# Sundry creditor has vend_code = bank_code
						SELECT * INTO l_rec_s_vendor.* FROM vendor 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND vend_code = glob_rec_bank.bank_code 
						IF status = NOTFOUND THEN 
							ERROR kandoomsg2("A",7067,"") 						#A7067" Sundry creditor NOT SET FOR this bank"
							NEXT FIELD bank_code 
						END IF 
						
						IF glob_rec_bank.currency_code != l_rec_s_vendor.currency_code THEN 
							ERROR kandoomsg2("A",7064,"") 						#A7068"Sundry creditor & bank must have same currency"
							NEXT FIELD bank_code 
						END IF 
						
						IF l_rec_s_vendor.usual_acct_code IS NULL THEN 
							ERROR kandoomsg2("A",9218,"") 						#9218 Usual Account Code must be setup
							NEXT FIELD bank_code 
						END IF 
						
						LET glob_rec_invoicehead.cust_code = l_rec_customer.cust_code 
						LET glob_rec_invoicehead.currency_code = glob_rec_bank.currency_code 
						LET glob_rec_invoicehead.conv_qty = get_conv_rate(
							glob_rec_kandoouser.cmpy_code,
							l_rec_customer.currency_code, 
							glob_rec_invoicehead.inv_date,CASH_EXCHANGE_SELL) 
						
						DISPLAY glob_rec_bank.name_acct_text TO name_acct_text

					END IF 

					IF glob_rec_invoicehead.inv_date IS NULL THEN 
						LET glob_rec_invoicehead.inv_date = today 
						NEXT FIELD inv_date 
					END IF 

					CALL valid_period(
						glob_rec_kandoouser.cmpy_code,
						glob_rec_invoicehead.year_num, 
						glob_rec_invoicehead.period_num,
						LEDGER_TYPE_AR) 
					RETURNING 
						glob_rec_invoicehead.year_num, 
						glob_rec_invoicehead.period_num, 
						l_invalid_period
						 
					IF l_invalid_period THEN 
						CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,glob_rec_invoicehead.inv_date) 
						RETURNING glob_rec_invoicehead.year_num,glob_rec_invoicehead.period_num 
						
						DISPLAY BY NAME 
							glob_rec_invoicehead.year_num, 
							glob_rec_invoicehead.period_num 

						NEXT FIELD year_num 
					END IF 
					
					IF glob_rec_invoicehead.conv_qty IS NULL THEN 
						LET glob_rec_invoicehead.conv_qty =	get_conv_rate(
							glob_rec_kandoouser.cmpy_code,
							l_rec_customer.currency_code, 
							glob_rec_invoicehead.inv_date,
							CASH_EXCHANGE_SELL) 
						ERROR kandoomsg2("A",9117,"") 					#9117" Exchange rate must have a value"
						NEXT FIELD conv_qty 
					END IF
					 
					IF glob_rec_invoicehead.conv_qty <= 0 THEN 
						ERROR kandoomsg2("A",9118,"") 				#9118" Exchange Rate must be greater than zero"
						NEXT FIELD conv_qty 
					END IF 
				END IF 

		END INPUT 
		#--------------------------------------------

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		ELSE 
			RETURN true 
			EXIT WHILE 
		END IF 

	END WHILE 

END FUNCTION 
##########################################################################
# END FUNCTION enter_refund()
##########################################################################