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
# Cash Receipts
# FUNCTION enter_receipt(p_cmpy,p_kandoouser_sign_on_code,pr_cust,pr_amt,pr_ref)
# expects calling program TO have created a temp t_cashreceipt table

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

###########################################################################
#FUNCTION enter_receipt(p_cmpy,p_kandoouser_sign_on_code,p_cust,p_amt,p_paid,p_ref,p_mode)
#
#
###########################################################################
FUNCTION enter_receipt(p_cmpy,p_kandoouser_sign_on_code,p_cust,p_amt,p_paid,p_ref,p_mode) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code 
	DEFINE p_cust LIKE customer.cust_code 
	DEFINE p_amt DECIMAL(16,4) 
	DEFINE p_paid DECIMAL(16,4) 
	DEFINE p_ref LIKE cashreceipt.order_num 
	DEFINE p_mode CHAR(4) 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_glparms RECORD LIKE glparms.* 
	DEFINE l_rec_customertype RECORD LIKE customertype.* 
	DEFINE l_rec_pr_cashreceipt RECORD LIKE cashreceipt.* 
	DEFINE l_rec_bank RECORD LIKE bank.* 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_invalid_period INTEGER 
	DEFINE l_bank_amt LIKE cashreceipt.cash_amt 
	DEFINE l_err_message CHAR(40) 
	DEFINE l_pr_continue SMALLINT 
	DEFINE l_winds_text CHAR(20) 
	DEFINE l_pr_reference_text LIKE kandooword.reference_text 

	SELECT base_currency_code INTO l_rec_glparms.base_currency_code FROM glparms 
	WHERE key_code = "1" 
	AND cmpy_code = p_cmpy 
	IF status = notfound THEN 
		ERROR kandoomsg2("A",5001,"") #5001 GL Parameters Not Found - Refer Menu GZP"
		RETURN 0 
	END IF 

	IF p_paid IS NULL THEN 
		LET p_paid = 0 
	END IF 

	IF p_amt IS NULL THEN 
		LET p_amt = 0 
	END IF 

	OPEN WINDOW A182 with FORM "A182" 
	CALL windecoration_a("A182") -- albo kd-755 

	ERROR kandoomsg2("A",1023,"") #1023 Enter Cash Receipt Details - F8 FOR Customer Information

	WHILE true 
		CLEAR FORM 
		INITIALIZE l_rec_bank.* TO NULL 
		INITIALIZE l_rec_pr_cashreceipt.* TO NULL 

		SELECT * INTO l_rec_pr_cashreceipt.* 
		FROM t_cashreceipt 

		IF status = notfound THEN 
			LET l_rec_pr_cashreceipt.cash_amt = p_amt - p_paid 
		END IF 

		IF l_rec_pr_cashreceipt.cash_amt < 0 THEN 
			LET l_rec_pr_cashreceipt.cash_amt = 0 
		END IF 

		LET l_rec_pr_cashreceipt.order_num = p_ref 
		LET l_rec_pr_cashreceipt.cust_code = p_cust 
		SELECT * INTO l_rec_customer.* 
		FROM customer 
		WHERE cmpy_code = p_cmpy 
		AND cust_code = l_rec_pr_cashreceipt.cust_code 
		IF status = notfound THEN 
			ERROR kandoomsg2("U",7001,"customer") 
			# Logic error:
			EXIT program 
		END IF 
		
		IF l_rec_customer.corp_cust_code IS NOT NULL 
		AND l_rec_customer.corp_cust_ind = "1" THEN 
			SELECT * INTO l_rec_customer.* 
			FROM customer 
			WHERE cmpy_code = p_cmpy 
			AND cust_code = l_rec_customer.corp_cust_code 
			IF status = notfound THEN 
				ERROR kandoomsg2("U",7001,"customer") 
				# Logic error:
				EXIT program 
			END IF 
			LET l_rec_pr_cashreceipt.cust_code = l_rec_customer.cust_code 
			LET l_rec_pr_cashreceipt.com1_text = "Org Cust: ",p_cust 
		ELSE 
			LET l_rec_pr_cashreceipt.cust_code = l_rec_customer.cust_code 
		END IF
		 
		LET l_rec_pr_cashreceipt.conv_qty = get_conv_rate(
			p_cmpy, 
			l_rec_customer.currency_code, 
			today, 
			CASH_EXCHANGE_SELL) 
		
		DECLARE c1_bank CURSOR FOR 
		SELECT * FROM bank 
		WHERE currency_code = l_rec_customer.currency_code 
		AND cmpy_code = p_cmpy 
		OPEN c1_bank 

		FETCH c1_bank INTO l_rec_bank.* 
		LET l_rec_pr_cashreceipt.bank_code = l_rec_bank.bank_code 
		LET l_rec_pr_cashreceipt.cash_acct_code = l_rec_bank.acct_code 
		LET l_rec_pr_cashreceipt.currency_code = l_rec_customer.currency_code 
		LET l_rec_pr_cashreceipt.bank_currency_code = l_rec_bank.currency_code 

		DISPLAY BY NAME	l_rec_pr_cashreceipt.currency_code attribute(green) 

		LET l_rec_pr_cashreceipt.cash_type_ind = "C" 
		LET l_pr_reference_text = kandooword("cashreceipt.cash_type_ind",l_rec_pr_cashreceipt.cash_type_ind) 
		LET l_rec_pr_cashreceipt.cash_date = today 
		LET l_rec_pr_cashreceipt.chq_date = today 
		LET l_rec_pr_cashreceipt.entry_date = today 
		LET l_rec_pr_cashreceipt.entry_code = p_kandoouser_sign_on_code 

		IF l_rec_bank.currency_code = l_rec_pr_cashreceipt.currency_code THEN 
			LET l_bank_amt = l_rec_pr_cashreceipt.cash_amt 
		ELSE 
			LET l_bank_amt = l_rec_pr_cashreceipt.cash_amt/ l_rec_pr_cashreceipt.conv_qty 
		END IF 
		
		CALL db_period_what_period(p_cmpy,today) 
		RETURNING 
			l_rec_pr_cashreceipt.year_num, 
			l_rec_pr_cashreceipt.period_num 

		DISPLAY BY NAME 
			l_rec_customer.name_text, 
			l_rec_bank.name_acct_text, 
			l_rec_pr_cashreceipt.cash_date, 
			l_rec_pr_cashreceipt.year_num, 
			l_rec_pr_cashreceipt.period_num, 
			l_rec_pr_cashreceipt.entry_code, 
			l_rec_pr_cashreceipt.entry_date 

		DISPLAY l_pr_reference_text TO pr_reference_text 

		INPUT 
			l_rec_pr_cashreceipt.cust_code, 
			l_rec_bank.bank_code, 
			l_rec_pr_cashreceipt.order_num, 
			l_rec_pr_cashreceipt.cash_type_ind, 
			l_rec_pr_cashreceipt.cash_date, 
			l_rec_pr_cashreceipt.year_num, 
			l_rec_pr_cashreceipt.period_num, 
			l_rec_pr_cashreceipt.cash_amt, 
			l_bank_amt, 
			l_rec_pr_cashreceipt.conv_qty, 
			l_rec_pr_cashreceipt.com1_text, 
			l_rec_pr_cashreceipt.com2_text WITHOUT DEFAULTS 
		FROM 
			cust_code, 
			bank_code, 
			order_num, 
			cash_type_ind, 
			cash_date, 
			year_num, 
			period_num, 
			cash_amt, 
			pr_bank_amt, 
			conv_qty, 
			com1_text, 
			com2_text 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","cashfunc","input-cashreceipt-1") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			ON ACTION "LOOKUP" #ON KEY (control-b) 
				CASE 
					WHEN infield(cust_code) 
						LET l_winds_text = show_clnt(p_cmpy) 
						IF l_winds_text IS NOT NULL THEN 
							LET l_rec_pr_cashreceipt.cust_code = l_winds_text 
						END IF 
						NEXT FIELD cust_code 

					WHEN infield(bank_code) 
						CALL show_bank(p_cmpy) 
						RETURNING l_rec_bank.bank_code, 
						l_rec_pr_cashreceipt.cash_acct_code 
						DISPLAY BY NAME l_rec_bank.bank_code 

						NEXT FIELD bank_code 
				END CASE 

			ON KEY (F8) 
				CALL cinq_clnt(p_cmpy,l_rec_customer.cust_code) --customer details 
				NEXT FIELD cust_code 

			BEFORE FIELD cust_code 
				SELECT * INTO l_rec_customertype.* FROM customertype 
				WHERE cmpy_code = p_cmpy 
				AND type_code = l_rec_customer.type_code 
				IF NOT valid_trans_num(	p_cmpy,	TRAN_TYPE_RECEIPT_CA,	l_rec_customertype.acct_mask_code) THEN 
					ERROR kandoomsg2("A",7031,"")#7031 "Warning: Invalid numbering - Review Menu GZD"
				END IF 
				NEXT FIELD NEXT 
				
			AFTER FIELD cust_code 
				SELECT * INTO l_rec_customer.* FROM customer 
				WHERE cmpy_code = p_cmpy 
				AND cust_code = l_rec_pr_cashreceipt.cust_code 
				AND delete_flag != "Y" 
				IF status = notfound THEN 
					ERROR kandoomsg2("A",9009,"")	#9009" Customer NOT found - Try Window"
					NEXT FIELD cust_code 
				END IF 
				
				IF l_rec_customer.corp_cust_code IS NOT NULL AND l_rec_customer.corp_cust_ind = "1" THEN 
					ERROR kandoomsg2("A",7032,"")			#7032 You can NOT receipt cash FOR a Subsidiary Debtor
					LET l_rec_pr_cashreceipt.cust_code = l_rec_customer.corp_cust_code 
					NEXT FIELD cust_code 
				END IF 
				LET l_rec_pr_cashreceipt.conv_qty = get_conv_rate(p_cmpy,l_rec_customer.currency_code,today,CASH_EXCHANGE_SELL) 
				SELECT customertype.* INTO l_rec_customertype.* FROM customertype 
				WHERE cmpy_code = p_cmpy 
				AND type_code = l_rec_customer.type_code
				 
				IF NOT valid_trans_num(p_cmpy,TRAN_TYPE_RECEIPT_CA,	l_rec_customertype.acct_mask_code) THEN 
					ERROR kandoomsg2("A",7031,"") #7031 "Warning: Invalid numbering - Review Menu GZD"
				END IF 

				LET l_rec_pr_cashreceipt.conv_qty = get_conv_rate(
					p_cmpy, 
					l_rec_customer.currency_code, 
					today, 
					CASH_EXCHANGE_SELL) 
	
				DECLARE c2_bank CURSOR FOR 
				SELECT * FROM bank 
				WHERE currency_code = l_rec_customer.currency_code 
				AND cmpy_code = p_cmpy 
				OPEN c2_bank 
	
				FETCH c2_bank INTO l_rec_bank.* 
				LET l_rec_pr_cashreceipt.bank_code = l_rec_bank.bank_code 
				LET l_rec_pr_cashreceipt.cash_acct_code = l_rec_bank.acct_code 
				LET l_rec_pr_cashreceipt.currency_code = l_rec_customer.currency_code 
				LET l_rec_pr_cashreceipt.bank_currency_code = l_rec_bank.currency_code 
	
				DISPLAY BY NAME 
					l_rec_customer.name_text, 
					l_rec_bank.name_acct_text 

				DISPLAY BY NAME l_rec_pr_cashreceipt.currency_code	attribute(green) 

			BEFORE FIELD bank_code 
				IF l_rec_bank.bank_code IS NULL THEN 
					LET l_rec_pr_cashreceipt.chq_date = today 
					DECLARE c12_bank CURSOR FOR 
					SELECT * FROM bank 
					WHERE currency_code = l_rec_customer.currency_code 
					AND acct_code = pr_arparms.cash_acct_code 
					AND cmpy_code = p_cmpy 

					OPEN c12_bank 

					FETCH c12_bank INTO l_rec_bank.* 
					IF status = notfound THEN 
						DECLARE c22_bank CURSOR FOR 
						SELECT * FROM bank 
						WHERE currency_code = l_rec_customer.currency_code 
						AND cmpy_code = p_cmpy 
						OPEN c22_bank 
						FETCH c22_bank INTO l_rec_bank.* 
					END IF 
					LET l_bank_amt = 0 
					LET l_rec_pr_cashreceipt.bank_currency_code = NULL 
				END IF 

				LET l_rec_pr_cashreceipt.currency_code = l_rec_customer.currency_code 

				DISPLAY BY NAME 
					l_rec_pr_cashreceipt.cust_code, 
					l_rec_customer.name_text, 
					l_rec_bank.bank_code, 
					l_rec_bank.name_acct_text, 
					l_rec_pr_cashreceipt.cash_date, 
					l_rec_pr_cashreceipt.cash_amt, 
					l_rec_pr_cashreceipt.conv_qty, 
					l_rec_pr_cashreceipt.year_num, 
					l_rec_pr_cashreceipt.period_num, 
					l_rec_pr_cashreceipt.cash_acct_code, 
					l_rec_pr_cashreceipt.entry_code, 
					l_rec_pr_cashreceipt.entry_date 

				DISPLAY l_bank_amt TO bank_amt 

				DISPLAY BY NAME 
					l_rec_pr_cashreceipt.bank_currency_code, 
					l_rec_pr_cashreceipt.currency_code attribute(green) 

			AFTER FIELD bank_code 
				SELECT * INTO l_rec_bank.* 
				FROM bank 
				WHERE cmpy_code = p_cmpy 
				AND bank_code = l_rec_bank.bank_code 
				IF status = notfound THEN 
					ERROR kandoomsg2("A",9132,"")	#9132" Bank Account Not Found - Try Window "
					NEXT FIELD bank_code 
				END IF 

				IF l_rec_bank.currency_code != l_rec_customer.currency_code THEN 
					IF l_rec_bank.currency_code != l_rec_glparms.base_currency_code THEN 
						ERROR kandoomsg2("A",9133,"") 		#9133 Banking IS permitted INTO cust OR base curr bankac
						NEXT FIELD bank_code 
					END IF 
				END IF 
				LET l_rec_pr_cashreceipt.bank_currency_code = l_rec_bank.currency_code 
				LET l_rec_pr_cashreceipt.cash_acct_code = l_rec_bank.acct_code 
				DISPLAY BY NAME 
					l_rec_bank.name_acct_text, 
					l_rec_pr_cashreceipt.cash_acct_code 

				DISPLAY BY NAME 
					l_rec_pr_cashreceipt.currency_code, 
					l_rec_pr_cashreceipt.bank_currency_code	attribute(green)
					 
				IF p_ref > 0 THEN 
					IF NOT get_is_screen_navigation_forward() THEN  
						NEXT FIELD bank_code 
					END IF 
				END IF
				 
			BEFORE FIELD order_num 
				IF NOT get_is_screen_navigation_forward() THEN 
					NEXT FIELD previous 
				ELSE 
					NEXT FIELD NEXT 
				END IF 
				
			AFTER FIELD cash_date 
				IF l_rec_pr_cashreceipt.cash_date IS NULL THEN 
					LET l_rec_pr_cashreceipt.cash_date = today 
					NEXT FIELD cash_date 
				END IF
				 
				CALL db_period_what_period(p_cmpy,l_rec_pr_cashreceipt.cash_date) 
				RETURNING 
					l_rec_pr_cashreceipt.year_num, 
					l_rec_pr_cashreceipt.period_num 
				
				DISPLAY BY NAME 
					l_rec_pr_cashreceipt.cash_date, 
					l_rec_pr_cashreceipt.year_num, 
					l_rec_pr_cashreceipt.period_num 

			AFTER FIELD cash_type_ind 
				IF l_rec_pr_cashreceipt.cash_type_ind IS NULL OR l_rec_pr_cashreceipt.cash_type_ind NOT matches "[CQPO]" THEN 
					ERROR kandoomsg2("W",9295,"") #9295 Payment type NOT found "
					NEXT FIELD cash_type_ind 
				END IF 
				
				LET l_pr_reference_text = kandooword(
					"cashreceipt.cash_type_ind",
					l_rec_pr_cashreceipt.cash_type_ind) 

				DISPLAY l_pr_reference_text TO pr_reference_text 

				IF NOT get_is_screen_navigation_forward() THEN 
					NEXT FIELD bank_code 
				END IF 
				
			AFTER FIELD period_num 
				CALL valid_period(
					p_cmpy,
					l_rec_pr_cashreceipt.year_num, 
					l_rec_pr_cashreceipt.period_num,
						LEDGER_TYPE_AR) 
				RETURNING 
					l_rec_pr_cashreceipt.year_num, 
					l_rec_pr_cashreceipt.period_num, 
					l_invalid_period 

				IF l_invalid_period THEN 
					CALL db_period_what_period(p_cmpy,l_rec_pr_cashreceipt.cash_date) 
					RETURNING 
						l_rec_pr_cashreceipt.year_num, 
						l_rec_pr_cashreceipt.period_num 
					
					DISPLAY BY NAME 
						l_rec_pr_cashreceipt.year_num, 
						l_rec_pr_cashreceipt.period_num 

					NEXT FIELD year_num 
				END IF
				 
			AFTER FIELD cash_amt 
				IF l_rec_pr_cashreceipt.cash_amt IS NULL THEN 
					ERROR kandoomsg2("A",9131,"")	#9131 " Must enter a value in the received amount"
					NEXT FIELD cash_amt 
				END IF 
				
				IF l_rec_pr_cashreceipt.cash_amt = 0 THEN 
					ERROR kandoomsg2("A",9131,"")			#9131 " Must enter a value in the received amount"
					NEXT FIELD cash_amt 
				END IF 
				
			BEFORE FIELD pr_bank_amt 
				IF l_rec_customer.currency_code = l_rec_glparms.base_currency_code THEN 
					LET l_bank_amt = l_rec_pr_cashreceipt.cash_amt 
					LET l_rec_pr_cashreceipt.conv_qty = 1 
					NEXT FIELD com1_text 
				ELSE 
					IF l_rec_bank.currency_code = l_rec_customer.currency_code THEN 
						LET l_bank_amt = l_rec_pr_cashreceipt.cash_amt 
						NEXT FIELD conv_qty 
					ELSE 
						IF l_rec_pr_cashreceipt.conv_qty > 0 THEN 
							LET l_bank_amt = l_rec_pr_cashreceipt.cash_amt	/ l_rec_pr_cashreceipt.conv_qty 
						END IF 
					END IF 
				END IF 

			AFTER FIELD pr_bank_amt 
				CASE 
					WHEN l_bank_amt IS NULL 
						LET l_bank_amt = 0 
					
					WHEN l_bank_amt = 0 
						CALL get_conv_rate(
							p_cmpy,
							l_rec_customer.currency_code, 
							l_rec_pr_cashreceipt.cash_date,
							CASH_EXCHANGE_SELL) 
						RETURNING l_rec_pr_cashreceipt.conv_qty 
						LET l_bank_amt = l_rec_pr_cashreceipt.cash_amt / l_rec_pr_cashreceipt.conv_qty 
					
					WHEN l_rec_pr_cashreceipt.cash_amt != 0 
						AND l_bank_amt != 0 
						LET l_rec_pr_cashreceipt.conv_qty = l_rec_pr_cashreceipt.cash_amt	/ l_bank_amt 
					
					WHEN l_rec_pr_cashreceipt.cash_amt = 0 
						AND l_bank_amt != 0 
						LET l_rec_pr_cashreceipt.cash_amt = l_bank_amt * l_rec_pr_cashreceipt.conv_qty 
				END CASE 
				
				DISPLAY BY NAME 
					l_rec_pr_cashreceipt.cash_amt, 
					l_rec_pr_cashreceipt.conv_qty 
				
				DISPLAY l_bank_amt TO pr_bank_amt 

			BEFORE FIELD conv_qty 
				IF l_rec_bank.currency_code = l_rec_glparms.base_currency_code THEN 
					IF l_rec_pr_cashreceipt.cash_amt != 0 AND l_bank_amt != 0 THEN 
						LET l_rec_pr_cashreceipt.conv_qty = l_rec_pr_cashreceipt.cash_amt	/ l_bank_amt 
					END IF 
				END IF 

			AFTER FIELD conv_qty 
				IF l_rec_pr_cashreceipt.conv_qty IS NULL THEN 
					CALL get_conv_rate(
						p_cmpy,
						l_rec_customer.currency_code, 
						l_rec_pr_cashreceipt.cash_date,
						CASH_EXCHANGE_SELL) 
					RETURNING l_rec_pr_cashreceipt.conv_qty 
					
					ERROR kandoomsg2("A",9117,"") #9117" Exchange rate must have a value"
					NEXT FIELD conv_qty 
				END IF 
				
				IF l_rec_pr_cashreceipt.conv_qty <= 0 THEN 
					ERROR kandoomsg2("A",9118,"")	#9118" Exchange Rate must be greater than zero"
					NEXT FIELD conv_qty 
				ELSE 
					IF l_rec_bank.currency_code = l_rec_glparms.base_currency_code THEN 
						LET l_bank_amt = l_rec_pr_cashreceipt.cash_amt / l_rec_pr_cashreceipt.conv_qty 
					END IF 
				END IF 
				
				IF NOT get_is_screen_navigation_forward() THEN 
					IF l_rec_customer.currency_code = l_rec_bank.currency_code THEN 
						NEXT FIELD cash_amt 
					ELSE 
						NEXT FIELD pr_bank_amt 
					END IF 
				END IF 
				
			BEFORE FIELD com1_text 
				DISPLAY BY NAME 
					l_rec_pr_cashreceipt.cash_amt, 
					l_rec_pr_cashreceipt.conv_qty 
				
				DISPLAY l_bank_amt TO pr_bank_amt 

			AFTER FIELD com1_text 
				IF NOT get_is_screen_navigation_forward() THEN  
					IF l_rec_customer.currency_code = l_rec_glparms.base_currency_code THEN 
						NEXT FIELD cash_amt 
					ELSE 
						NEXT FIELD conv_qty 
					END IF 
				END IF 
				
			AFTER INPUT 
				IF not(int_flag OR quit_flag) THEN 
					CALL valid_period(
						p_cmpy, 
						l_rec_pr_cashreceipt.year_num, 
						l_rec_pr_cashreceipt.period_num, 
						LEDGER_TYPE_AR) 
					RETURNING 
						l_rec_pr_cashreceipt.year_num, 
						l_rec_pr_cashreceipt.period_num, 
						l_invalid_period 
					
					IF l_invalid_period THEN 
						NEXT FIELD year_num 
					END IF 
					
					IF l_rec_pr_cashreceipt.cash_type_ind IS NULL	OR l_rec_pr_cashreceipt.cash_type_ind NOT matches "[CQPO]" THEN 
						ERROR kandoomsg2("W",9295,"") #9295 Payment type NOT found "
						NEXT FIELD cash_type_ind 
					END IF 
					
					IF l_rec_pr_cashreceipt.cash_amt IS NULL THEN 
						ERROR kandoomsg2("A",9131,"")#9131 " Must enter a value in the received amount"
						NEXT FIELD cash_amt 
					END IF 
					
					IF l_rec_pr_cashreceipt.cash_amt = 0 THEN 
						ERROR kandoomsg2("A",9131,"")#9131 " Must enter a value in the received amount"
						NEXT FIELD cash_amt 
					END IF 
					
					IF l_rec_pr_cashreceipt.cash_amt < 0 THEN 
						IF kandoomsg("A",8012,"") != "Y" THEN	#8012 Warning: Negative Cash Receipt authorized.
							NEXT FIELD cash_amt 
						END IF 
					END IF 
					
					IF l_rec_pr_cashreceipt.cash_type_ind = PAYMENT_TYPE_CHEQUE_Q THEN 
						CALL banking(l_rec_pr_cashreceipt.*, l_rec_customer.name_text) 
						RETURNING l_rec_pr_cashreceipt.*, l_pr_continue 
						
						IF NOT l_pr_continue THEN 
							NEXT FIELD bank_code 
						END IF 
					END IF
					 
					IF l_rec_pr_cashreceipt.cash_type_ind = PAYMENT_TYPE_CC_P THEN 
						CALL cards(l_rec_pr_cashreceipt.*, l_rec_customer.name_text) 
						RETURNING l_rec_pr_cashreceipt.*, l_pr_continue 
						
						IF NOT l_pr_continue THEN 
							NEXT FIELD bank_code 
						END IF 
					END IF 
				END IF 

		END INPUT 
		
		IF int_flag OR quit_flag THEN 
			CLOSE WINDOW A182 
			RETURN 0 
		END IF 
		DELETE FROM t_cashreceipt 
		WHERE 1=1
		 
		LET l_err_message = "Temp Cash Receipt Insert" 
		LET l_rec_pr_cashreceipt.cmpy_code = p_cmpy 
		LET l_rec_pr_cashreceipt.applied_amt = 0 
		LET l_rec_pr_cashreceipt.disc_amt = 0 
		LET l_rec_pr_cashreceipt.on_state_flag = "N" 
		LET l_rec_pr_cashreceipt.posted_flag = CASHRECEIPT_POST_FLAG_STATUS_NOT_POSTED_N 
		LET l_rec_pr_cashreceipt.next_num = 0 
		LET l_rec_pr_cashreceipt.banked_flag = "N" 
		
		INSERT INTO t_cashreceipt VALUES (l_rec_pr_cashreceipt.*) 
		
		EXIT WHILE 
	END WHILE
	 
	CLOSE WINDOW A182 

	RETURN l_rec_pr_cashreceipt.cash_amt 
END FUNCTION 
###########################################################################
# END FUNCTION enter_receipt(p_cmpy,p_kandoouser_sign_on_code,p_cust,p_amt,p_paid,p_ref,p_mode)
###########################################################################


###########################################################################
# FUNCTION banking(p_cashreceipt, p_name_text)
#
#
###########################################################################
FUNCTION banking(p_cashreceipt, p_name_text) 
	DEFINE p_cashreceipt RECORD LIKE cashreceipt.* 
	DEFINE p_name_text LIKE customer.name_text 
	DEFINE l_rec_cashreceipt RECORD LIKE cashreceipt.* 
	DEFINE l_msgresp LIKE language.yes_flag 

	OPEN WINDOW A151 with FORM "A151" 
	CALL windecoration_a("A151")  

	MESSAGE kandoomsg2("U",1020,"Cheque")	#1020 Enter Cheque Details; OK TO Continue
	LET l_rec_cashreceipt.* = p_cashreceipt.* 
	LET l_rec_cashreceipt.drawer_text = p_name_text 

	DISPLAY BY NAME 
		l_rec_cashreceipt.bank_text, 
		l_rec_cashreceipt.branch_text, 
		l_rec_cashreceipt.drawer_text, 
		l_rec_cashreceipt.cheque_text, 
		l_rec_cashreceipt.chq_date 

	INPUT BY NAME 
		l_rec_cashreceipt.bank_text, 
		l_rec_cashreceipt.branch_text, 
		l_rec_cashreceipt.drawer_text, 
		l_rec_cashreceipt.cheque_text, 
		l_rec_cashreceipt.chq_date WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","cashfunc","input-cashreceipt-2") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END INPUT 

	CLOSE WINDOW A151 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN p_cashreceipt.*, false 
	END IF 

	RETURN l_rec_cashreceipt.*, true 
END FUNCTION 
###########################################################################
# END FUNCTION banking(p_cashreceipt, p_name_text)
###########################################################################


###########################################################################
# FUNCTION cards(p_cashreceipt, p_name_text)
#
#
###########################################################################
FUNCTION cards(p_cashreceipt, p_name_text) 
	DEFINE p_cashreceipt RECORD LIKE cashreceipt.* 
	DEFINE p_name_text LIKE customer.name_text 
	DEFINE l_card_type CHAR(1) 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_cashreceipt RECORD LIKE cashreceipt.* 
	DEFINE l_month_exp SMALLINT 
	DEFINE l_year_exp SMALLINT 

	OPEN WINDOW A632 with FORM "A632" 
	CALL windecoration_a("A632")  

	LET l_rec_cashreceipt.* = p_cashreceipt.* 
	LET l_rec_cashreceipt.drawer_text = p_name_text 
	LET l_month_exp = l_rec_cashreceipt.card_exp_date[1,2] 
	LET l_year_exp = l_rec_cashreceipt.card_exp_date[3,4] 
	LET l_card_type = l_rec_cashreceipt.bank_text[1] 

	MESSAGE kandoomsg2("U",1020,"Credit Card") #1020 Enter Credit Card Details; OK TO Continue

	INPUT 
		l_card_type, 
		l_rec_cashreceipt.bank_text, 
		l_rec_cashreceipt.branch_text, 
		l_rec_cashreceipt.drawer_text, 
		l_month_exp, 
		l_year_exp WITHOUT DEFAULTS 
	FROM 
		pr_card_type, 
		bank_text, 
		branch_text, 
		drawer_text, 
		pr_month_exp, 
		pr_year_exp 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","cashfunc","input-cashreceipt-ccard") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER FIELD pr_card_type 
			IF l_card_type = "V" THEN 
				LET l_rec_cashreceipt.bank_text = "VISA" 
			END IF 
			IF l_card_type = "M" THEN 
				LET l_rec_cashreceipt.bank_text = "MASTERCARD" 
			END IF 
			IF l_card_type = "B" THEN 
				LET l_rec_cashreceipt.bank_text = "BANKCARD" 
			END IF 
			IF l_card_type = "A" THEN 
				LET l_rec_cashreceipt.bank_text = "AMEX" 
			END IF 
			IF l_card_type = "D" THEN 
				LET l_rec_cashreceipt.bank_text = "DINERS CLUB" 
			END IF 

		AFTER FIELD branch_text 
			IF l_rec_cashreceipt.branch_text IS NOT NULL THEN 
				IF verify_creditcard_number(l_rec_cashreceipt.branch_text) THEN 
					ERROR kandoomsg2("K",6000,"")		#6000 Invalid Credit Card Number Entered.
				END IF 
			END IF 

	END INPUT 

	CLOSE WINDOW A632 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN p_cashreceipt.*, false 
	END IF
	 
	LET l_rec_cashreceipt.card_exp_date = l_month_exp USING "&&",l_year_exp USING "&&"
	 
	RETURN l_rec_cashreceipt.*, true 
END FUNCTION 
###########################################################################
# END FUNCTION cards(p_cashreceipt, p_name_text)
###########################################################################


###########################################################################
# FUNCTION verify_creditcard_number(p_card_num)
#
#
###########################################################################
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
###########################################################################
# END FUNCTION verify_creditcard_number(p_card_num)
###########################################################################