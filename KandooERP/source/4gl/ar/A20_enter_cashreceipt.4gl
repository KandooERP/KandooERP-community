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

#################################################################################
# FUNCTION enter_cashreceipt(p_company_cmpy_code,p_kandoouser_sign_on_code,p_inv_num,p_apply_ind)
#
#
#################################################################################
FUNCTION enter_cashreceipt(p_company_cmpy_code,p_kandoouser_sign_on_code,p_inv_num,p_apply_ind) 
	DEFINE p_company_cmpy_code LIKE company.cmpy_code 
	DEFINE p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code 
	DEFINE p_inv_num SMALLINT 
	DEFINE p_apply_ind SMALLINT 
	DEFINE l_rec_glparms RECORD LIKE glparms.* 
	DEFINE l_rec_userlocn RECORD LIKE userlocn.* 
	DEFINE l_rec_company RECORD LIKE company.* 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_customertype RECORD LIKE customertype.* 
	DEFINE l_rec_invoicehead RECORD LIKE invoicehead.* 
	DEFINE l_rec_bank RECORD LIKE bank.* 
	DEFINE l_rec_araudit RECORD LIKE araudit.* 
	DEFINE l_inv_num2 LIKE invoicehead.inv_num 
	DEFINE l_bank_amt LIKE cashreceipt.cash_amt 
	DEFINE l_appl_amt LIKE cashreceipt.cash_amt 
	DEFINE l_poss_disc_amt LIKE cashreceipt.cash_amt 
	DEFINE l_disc_amt LIKE cashreceipt.cash_amt 
	DEFINE l_availcr_amt LIKE customer.bal_amt 
	DEFINE l_invalid_period INTEGER 
	DEFINE l_recalc_ind CHAR(1) 
	DEFINE l_disc_taken_ind CHAR(1) 
	DEFINE l_err_continue CHAR(1) 
	DEFINE l_err_message CHAR(40) 
	DEFINE l_reference_text LIKE kandooword.reference_text 
	DEFINE l_cust_code LIKE customer.cust_code 
	DEFINE l_temp_text CHAR(30) 
	DEFINE l_cash_amt LIKE cashreceipt.cash_amt 
	DEFINE l_msg STRING
	
	SELECT base_currency_code INTO l_rec_glparms.base_currency_code 
	FROM glparms 
	WHERE key_code = "1" 
	AND cmpy_code = p_company_cmpy_code 

	IF status = NOTFOUND THEN 
		ERROR kandoomsg2("A",5001,"") #5001 GL Parameters Not Found - Refer Menu GZP"
		EXIT PROGRAM 
	END IF 

	SELECT * INTO l_rec_company.* FROM company 
	WHERE cmpy_code = p_company_cmpy_code 

	OPEN WINDOW A182 with FORM "A182" 
	CALL windecoration_a("A182") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	IF p_inv_num != 0 THEN 
		MESSAGE kandoomsg2("A",1023,"") #1023 Enter Cash Receipt Details;  F8 FOR Customer Information.
	ELSE 
		MESSAGE kandoomsg2("A",1099,"") #1099 Enter Cash Receipt Details;  F8 Customer Info;  F9 Invoice Scan.
	END IF 

	WHILE TRUE 

		CLEAR FORM 

		INITIALIZE glob_rec_cashreceipt.* TO NULL 
		INITIALIZE l_rec_customer.* TO NULL 
		INITIALIZE l_rec_bank.* TO NULL 

		LET glob_rec_cashreceipt.entry_date = today 
		LET glob_rec_cashreceipt.cmpy_code = glob_rec_company.cmpy_code
		LET glob_rec_cashreceipt.entry_code = p_kandoouser_sign_on_code 
		LET glob_rec_cashreceipt.cash_date = today 
		LET glob_rec_cashreceipt.cash_acct_code = glob_rec_arparms.cash_acct_code 
		LET glob_rec_cashreceipt.cash_amt = 0 
		LET l_disc_amt = 0 
		LET l_bank_amt = 0 

		CALL db_period_what_period(p_company_cmpy_code,today) 
		RETURNING glob_rec_cashreceipt.year_num,glob_rec_cashreceipt.period_num 

--				LET glob_rec_cashreceipt.cash_amt =  glob_rec_invoicehead.total_amt 
--				LET l_bank_amt =  glob_rec_invoicehead.total_amt	

		INPUT 
			glob_rec_cashreceipt.cust_code, 
			l_rec_bank.bank_code, 
			glob_rec_cashreceipt.order_num, 
			glob_rec_cashreceipt.cash_type_ind, 
			glob_rec_cashreceipt.cash_date, 
			glob_rec_cashreceipt.year_num, 
			glob_rec_cashreceipt.period_num, 
			glob_rec_cashreceipt.cash_amt, 
			l_bank_amt, 
			glob_rec_cashreceipt.conv_qty, 
			glob_rec_cashreceipt.com1_text, 
			glob_rec_cashreceipt.com2_text WITHOUT DEFAULTS 
		FROM 
			cust_code, 
			bank_code, 
			order_num, 
			cash_type_ind, 
			cash_date, 
			year_num, 
			period_num, 
			cash_amt, 
			bank_amt, 
			conv_qty, 
			com1_text, 
			com2_text ATTRIBUTES(UNBUFFERED) 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","A31a","inp-cashreceipt-1") 
				DISPLAY l_bank_amt TO bank_amt
				CALL dialog.setActionHidden("INVOICE SCAN",NOT glob_rec_cashreceipt.cust_code)
				CALL dialog.setActionHidden("DETAILS",NOT glob_rec_cashreceipt.cust_code)

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			ON ACTION "REFRESH"
				CALL windecoration_a("A182")				

			ON ACTION "LOOKUP" infield (bank_code) 
				CALL show_bank(p_company_cmpy_code) 
				RETURNING l_rec_bank.bank_code,	glob_rec_cashreceipt.cash_acct_code
				 
				DISPLAY l_rec_bank.bank_code TO bank_code 
				DISPLAY glob_rec_cashreceipt.cash_acct_code TO cash_acct_code 

				NEXT FIELD bank_code 

			ON ACTION "LOOKUP" infield (cust_code) --lookup customer code 
				LET glob_rec_cashreceipt.cust_code = show_clnt(p_company_cmpy_code) 
				NEXT FIELD cust_code 


				--         ON KEY(F8) infield(bank_code ,
			ON ACTION ("DETAILS") 
--			infield(bank_code , 
--				order_num, 
--				cash_type_ind, 
--				cash_date, 
--				year_num, 
--				period_num, 
--				cash_amt, 
--				l_bank_amt, 
--				conv_qty, 
--				com1_text, 
--				com2_text 
--				)--customer info 
				CALL cinq_clnt(p_company_cmpy_code,l_rec_customer.cust_code)--customer details 
				NEXT FIELD cust_code 

			ON ACTION "INVOICE SCAN" --infield(cust_code) # KEY(F9) infield(cust_code) --invoice scan 
				#ON KEY(F9) infield(cust_code) --Invoice Scan
				CALL invoice_scan(p_company_cmpy_code, glob_rec_cashreceipt.cash_date,glob_rec_cashreceipt.cust_code) 
				RETURNING l_inv_num2 
				
				IF l_inv_num2 != 0 THEN 

					#IF db_invoicehead_pk_exists(UI_ON,MODE_SELECT,l_inv_num2) THEN
					CALL db_invoicehead_get_rec(UI_ON,l_inv_num2) RETURNING  l_rec_invoicehead.*

					
					LET glob_rec_cashreceipt.cust_code = l_rec_invoicehead.cust_code 
					LET l_cust_code = l_rec_invoicehead.cust_code
					 
					IF get_debug() THEN 
						DISPLAY "----- ON ACTION INVOICE SCAN ---------------------------------*"
						DISPLAY  "Init l_rec_invoicehead.disc_amt with 0 -------------- l_rec_invoicehead.disc_amt=", l_rec_invoicehead.disc_amt
					END IF
										
					CALL calc_cash_amt(p_company_cmpy_code, glob_rec_cashreceipt.cash_date, 
					l_rec_invoicehead.*) 
					RETURNING glob_rec_cashreceipt.cash_amt, l_disc_amt, l_recalc_ind, l_disc_taken_ind 

					CALL ui.interface.refresh() 

				END IF 
				
				NEXT FIELD cust_code 

			ON CHANGE cust_code
				DISPLAY db_customer_get_name_text(UI_OFF,glob_rec_cashreceipt.cust_code) TO customer.name_text
				CALL combolist_order_num("order_num", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,combo_null_none)
				CALL dialog.setActionHidden("INVOICE SCAN",NOT glob_rec_cashreceipt.cust_code)
				CALL dialog.setActionHidden("DETAILS",NOT glob_rec_cashreceipt.cust_code)

				#-----------------------------
				# Copied from AFTER FIELD cust_code
				CALL db_customer_get_rec_not_deleted(UI_OFF,glob_rec_cashreceipt.cust_code) RETURNING l_rec_customer.*
--				SELECT * INTO l_rec_customer.* FROM customer 
--				WHERE cmpy_code = p_company_cmpy_code 
--				AND cust_code = glob_rec_cashreceipt.cust_code 
--				AND delete_flag != "Y" 

				IF l_rec_customer IS NULL THEN 
				--IF status = NOTFOUND THEN 
					ERROR kandoomsg2("A",9009,"")	#9009" Customer NOT found - Try Window"
					NEXT FIELD cust_code 
				END IF 

				IF l_rec_customer.corp_cust_code IS NOT NULL AND l_rec_customer.corp_cust_ind = "1" THEN 
					ERROR kandoomsg2("A",7032,"")		#7032 You can NOT receipt cash FOR a Subsidiary Debtor
					LET glob_rec_cashreceipt.cust_code = l_rec_customer.corp_cust_code 
					NEXT FIELD cust_code 
				END IF 

				LET glob_rec_cashreceipt.conv_qty = get_conv_rate(
					p_company_cmpy_code,
					l_rec_customer.currency_code,
					today,
					CASH_EXCHANGE_SELL)
				 
				MESSAGE kandoomsg2("A",1023,"") #1023 Enter Cash Receipt Details;  F8 FOR Customer Information.
				SELECT customertype.* INTO l_rec_customertype.* FROM customertype 
				WHERE cmpy_code = p_company_cmpy_code 
				AND type_code = l_rec_customer.type_code 
				
				IF NOT valid_trans_num(p_company_cmpy_code,TRAN_TYPE_RECEIPT_CA,l_rec_customertype.acct_mask_code) THEN 
					ERROR kandoomsg2("A",7031,"") #7031 "Warning: Invalid numbering - Review Menu GZD"
					SLEEP 2
				END IF 
				
				CALL combolist_order_num("order_num", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,combo_null_none)
				IF get_debug() THEN
					DISPLAY "----- AFTER FIELD cust_code ---------------------------------*" 
					DISPLAY "l_bank_amt=", l_bank_amt
				END IF
			#-------------------------------

			BEFORE FIELD cust_code 
				IF p_inv_num = 0 THEN 
					MESSAGE kandoomsg2("A",1099,"") 		#1099 Enter Cash Receipt Details; F8 Customer Info; F9 ...
				END IF 
				IF p_inv_num > 0 THEN 

					#IF db_invoicehead_pk_exists(UI_ON,MODE_SELECT,p_inv_num) THEN
					CALL db_invoicehead_get_rec(UI_ON,p_inv_num) RETURNING  l_rec_invoicehead.*
					
					CALL db_customer_get_rec_not_deleted(UI_OFF,l_rec_invoicehead.cust_code ) RETURNING l_rec_customer.*
--					SELECT * INTO l_rec_customer.* FROM customer 
--					WHERE cmpy_code = p_company_cmpy_code 
--					AND cust_code = l_rec_invoicehead.cust_code 
--					AND delete_flag != "Y"

					IF get_debug() THEN 
						DISPLAY "----- BEFORE FIELD cust_code ---------------------------------*"
						DISPLAY "l_rec_invoicehead.disc_amt=", l_rec_invoicehead.disc_amt
						DISPLAY "----------------------------------------------------------"
					END IF
						
					IF l_rec_invoicehead.disc_amt IS NULL THEN
						LET l_rec_invoicehead.disc_amt = 0
					END IF

					IF get_debug() THEN 
						DISPLAY "----------------------------------------------------------"
						DISPLAY "l_rec_invoicehead.disc_amt=", l_rec_invoicehead.disc_amt
						DISPLAY "----------------------------------------------------------"
					END IF
					 
					LET glob_rec_cashreceipt.cash_date = l_rec_invoicehead.inv_date 
					LET glob_rec_cashreceipt.year_num = l_rec_invoicehead.year_num 
					LET glob_rec_cashreceipt.period_num = l_rec_invoicehead.period_num 
					LET glob_rec_cashreceipt.conv_qty = l_rec_invoicehead.conv_qty 
					LET glob_rec_cashreceipt.cust_code = l_rec_customer.cust_code 

					SELECT customertype.* INTO l_rec_customertype.* FROM customertype 
					WHERE cmpy_code = p_company_cmpy_code 
					AND type_code = l_rec_customer.type_code 

					IF NOT valid_trans_num(p_company_cmpy_code,TRAN_TYPE_RECEIPT_CA, l_rec_customertype.acct_mask_code) THEN 
						ERROR kandoomsg2("A",7031,"") 					#7031 "Warning: Invalid numbering - view Menu GZD"
					END IF 

					DISPLAY glob_rec_cashreceipt.cust_code TO cust_code 
					DISPLAY glob_rec_cashreceipt.cash_amt TO cash_amt 
					DISPLAY glob_rec_cashreceipt.year_num TO year_num 
					DISPLAY glob_rec_cashreceipt.year_num TO year_num #???? twice ? looks strange.. needs checking why 
					DISPLAY l_rec_customer.name_text TO name_text 

					IF get_debug() THEN 
						DISPLAY "----------------------------------------------------------"
						DISPLAY "p_company_cmpy_code=", trim(p_company_cmpy_code)
						DISPLAY "glob_rec_cashreceipt.cash_date=", trim(glob_rec_cashreceipt.cash_date)
						DISPLAY "l_rec_invoicehead.*=", l_rec_invoicehead.*
						DISPLAY "----------------------------------------------------------"
					END IF

					#Calculate cash amount for Receipt
					CALL calc_cash_amt(p_company_cmpy_code, glob_rec_cashreceipt.cash_date, l_rec_invoicehead.*) 
					RETURNING glob_rec_cashreceipt.cash_amt, l_disc_amt, l_recalc_ind,l_disc_taken_ind

					IF get_debug() THEN 
						DISPLAY "----------------------------------------------------------"
						DISPLAY "glob_rec_cashreceipt.cash_amt=", trim(glob_rec_cashreceipt.cash_amt)
						DISPLAY "l_disc_amt=", trim(l_disc_amt)
						DISPLAY "l_recalc_ind=", trim(l_recalc_ind)
						DISPLAY "l_disc_taken_ind=", trim(l_disc_taken_ind)		
						DISPLAY "l_rec_invoicehead.disc_amt=", l_rec_invoicehead.disc_amt
						DISPLAY "----------------------------------------------------------"
					END IF
					 
					DISPLAY glob_rec_cashreceipt.cash_date TO cash_date 

					NEXT FIELD bank_code 
				END IF 
			
			AFTER FIELD cust_code 
				CALL db_customer_get_rec_not_deleted(UI_ON,glob_rec_cashreceipt.cust_code) RETURNING l_rec_customer.*

				IF l_rec_customer.cust_code IS NULL THEN 
					NEXT FIELD cust_code 
				END IF 

				IF l_rec_customer.corp_cust_code IS NOT NULL AND l_rec_customer.corp_cust_ind = "1" THEN 
					ERROR kandoomsg2("A",7032,"") 	#7032 You can NOT receipt cash FOR a Subsidiary Debtor
					LET glob_rec_cashreceipt.cust_code = l_rec_customer.corp_cust_code 
					NEXT FIELD cust_code 
				END IF 

				LET glob_rec_cashreceipt.conv_qty = get_conv_rate(
					p_company_cmpy_code,
					l_rec_customer.currency_code,
					today,
					CASH_EXCHANGE_SELL)
				 
				MESSAGE kandoomsg2("A",1023,"") 	#1023 Enter Cash Receipt Details;  F8 FOR Customer Information.
				SELECT customertype.* INTO l_rec_customertype.* FROM customertype 
				WHERE cmpy_code = p_company_cmpy_code 
				AND type_code = l_rec_customer.type_code 
				
				IF NOT valid_trans_num(p_company_cmpy_code,TRAN_TYPE_RECEIPT_CA,l_rec_customertype.acct_mask_code) THEN 
					ERROR kandoomsg2("A",7031,"") 	#7031 "Warning: Invalid numbering - Review Menu GZD"
				END IF 
				
				CALL combolist_order_num("order_num", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,combo_null_none)
				IF get_debug() THEN
					DISPLAY "----- AFTER FIELD cust_code ---------------------------------*" 
					DISPLAY "l_bank_amt=", l_bank_amt
				END IF

			ON CHANGE bank_code
				DISPLAY db_bank_get_name_acct_text(UI_OFF,l_rec_bank.bank_code) TO bank.name_acct_text
				
			BEFORE FIELD bank_code 
				IF l_rec_bank.bank_code IS NULL THEN 
					DECLARE c1_bank CURSOR FOR 
					SELECT * FROM bank 
					WHERE currency_code = l_rec_customer.currency_code 
					AND acct_code = glob_rec_arparms.cash_acct_code 
					AND cmpy_code = p_company_cmpy_code 
					OPEN c1_bank 
					FETCH c1_bank INTO l_rec_bank.* 

					IF status = NOTFOUND THEN 
						DECLARE c2_bank CURSOR FOR 
						SELECT * FROM bank 
						WHERE currency_code = l_rec_customer.currency_code 
						AND cmpy_code = p_company_cmpy_code 
						OPEN c2_bank 
						FETCH c2_bank INTO l_rec_bank.* 
					END IF 
					
					LET l_bank_amt = 0 
					LET glob_rec_cashreceipt.bank_currency_code = NULL 
				END IF 

				LET glob_rec_cashreceipt.currency_code = l_rec_customer.currency_code 
				IF get_debug() THEN
					DISPLAY "----- BEFORE FIELD bank_code ---------------------------------*" 
					DISPLAY "glob_rec_cashreceipt.cash_amt=", glob_rec_cashreceipt.cash_amt 
					DISPLAY "l_bank_amt=", l_bank_amt
				END IF

				IF glob_rec_cashreceipt.cash_amt > 0 THEN 
					#Customer currency = Base currency
					IF l_rec_customer.currency_code = l_rec_glparms.base_currency_code THEN 
						LET l_bank_amt = glob_rec_cashreceipt.cash_amt 
						LET glob_rec_cashreceipt.conv_qty = 1 
					ELSE #Customer currency = Foreign Currency
						#Bank Currency = Customer Currency 
						IF l_rec_bank.currency_code = l_rec_customer.currency_code THEN 
							LET l_bank_amt = glob_rec_cashreceipt.cash_amt 
						ELSE #Bank Currency != Customer Currency NEEDS converting/exchange
							IF glob_rec_cashreceipt.conv_qty > 0 THEN 
								LET l_bank_amt = glob_rec_cashreceipt.cash_amt / glob_rec_cashreceipt.conv_qty 
							END IF 
						END IF 
					END IF 
				END IF 

				DISPLAY glob_rec_cashreceipt.cust_code TO cust_code 
				DISPLAY l_rec_customer.name_text TO name_text 
				DISPLAY l_rec_bank.bank_code TO bank_code 
				DISPLAY l_rec_bank.name_acct_text TO name_acct_text 
				DISPLAY glob_rec_cashreceipt.cash_date TO cash_date 
				DISPLAY glob_rec_cashreceipt.cash_amt TO cash_amt 
				DISPLAY l_bank_amt TO bank_amt 
				DISPLAY glob_rec_cashreceipt.conv_qty TO conv_qty 
				DISPLAY glob_rec_cashreceipt.year_num TO year_num 
				DISPLAY glob_rec_cashreceipt.period_num TO period_num 
				DISPLAY glob_rec_cashreceipt.cash_acct_code TO cash_acct_code 
				DISPLAY glob_rec_cashreceipt.entry_code TO entry_code 
				DISPLAY glob_rec_cashreceipt.entry_date TO entry_date 
				DISPLAY glob_rec_cashreceipt.bank_currency_code TO bank_currency_code #HuHo: attribute(GREEN) #why with color / green ? I'll remove it 
				DISPLAY glob_rec_cashreceipt.currency_code TO currency_code #HuHo: attribute(GREEN) #why with color / green ? I'll remove it

			AFTER FIELD bank_code #Bank Code is required
				CALL db_bank_get_rec(UI_OFF,l_rec_bank.bank_code) RETURNING l_rec_bank.*
--				SELECT * INTO l_rec_bank.* FROM bank 
--				WHERE cmpy_code = p_company_cmpy_code 
--				AND bank_code = l_rec_bank.bank_code 

				IF l_rec_bank.bank_code IS NULL THEN 
					ERROR kandoomsg2("A",9132,"") #9132" Bank Account Not Found - Try Window "
					NEXT FIELD bank_code 
				END IF 
				
				IF l_rec_bank.currency_code != l_rec_customer.currency_code #Bank currency != Customer currency  
				AND l_rec_bank.currency_code != l_rec_glparms.base_currency_code THEN #Bank currency != GL base currency
					LET l_msg = kandoomsg2("A",9133,"") #9133 Banking IS permitted INTO cust OR base curr bankac
					LET l_msg = l_msg, " Bank Currency=", trim( l_rec_bank.currency_code), "\nCustomer Currency=", trim(l_rec_customer.currency_code), "\nGL-Currency=", trim(l_rec_glparms.base_currency_code)
					ERROR l_msg 
					NEXT FIELD bank_code 
				END IF 

				LET glob_rec_cashreceipt.bank_currency_code = l_rec_bank.currency_code 
				LET glob_rec_cashreceipt.cash_acct_code = l_rec_bank.acct_code 

				DISPLAY l_rec_bank.name_acct_text TO name_acct_text 
				DISPLAY glob_rec_cashreceipt.cash_acct_code TO cash_acct_code 
				DISPLAY glob_rec_cashreceipt.currency_code TO currency_code #HuHo: attribute(GREEN) #why with color / green ? I'll remove it
				DISPLAY glob_rec_cashreceipt.bank_currency_code TO bank_currency_code #HuHo: attribute(GREEN) #why with color / green ? I'll remove it

				IF p_inv_num > 0 THEN 
					IF NOT get_is_screen_navigation_forward() THEN 
						NEXT FIELD bank_code 
					END IF 
				END IF 

			AFTER FIELD order_num 
				IF (glob_rec_cashreceipt.order_num IS NOT NULL) AND (l_rec_company.module_text[23] = "W") THEN 
					--SELECT unique 1 FROM ordhead 
					SELECT unique 1 FROM orderhead
					WHERE cmpy_code = p_company_cmpy_code 
					AND order_num = glob_rec_cashreceipt.order_num 
					IF status = NOTFOUND THEN 
						ERROR kandoomsg2("A",9517,"") #9517 Order NOT found.
						NEXT FIELD order_num 
					END IF 
				END IF 

			ON CHANGE cash_type_ind
				LET l_reference_text = kandooword("cashreceipt.cash_type_ind",	glob_rec_cashreceipt.cash_type_ind) 
				DISPLAY l_reference_text TO reference_text 

			AFTER FIELD cash_type_ind 
				IF glob_rec_cashreceipt.cash_type_ind IS NULL THEN 
					ERROR kandoomsg2("U",9102,"") #9102 Value must be entered.
					NEXT FIELD cash_type_ind 
				END IF 

				IF glob_rec_cashreceipt.cash_type_ind NOT matches "[CPQO]" THEN 
					ERROR kandoomsg2("U",9112,"Payment Type") #9112 Invalid Payment Type.
					NEXT FIELD cash_type_ind 
				END IF 

				LET l_reference_text = kandooword("cashreceipt.cash_type_ind",	glob_rec_cashreceipt.cash_type_ind) 
				DISPLAY l_reference_text TO reference_text 

				IF glob_rec_cashreceipt.cash_type_ind = PAYMENT_TYPE_CHEQUE_Q THEN 
					LET glob_rec_cashreceipt.chq_date = today 
				ELSE 
					LET glob_rec_cashreceipt.chq_date = NULL 
				END IF 

			AFTER FIELD cash_date 
				IF glob_rec_cashreceipt.cash_date IS NULL THEN 
					LET glob_rec_cashreceipt.cash_date = today 
					NEXT FIELD cash_date 
				END IF 

				CALL db_period_what_period(p_company_cmpy_code, glob_rec_cashreceipt.cash_date) 
				RETURNING glob_rec_cashreceipt.year_num, glob_rec_cashreceipt.period_num 

				IF get_debug() THEN 
					DISPLAY "Invoice Number p_inv_num=", trim(p_inv_num) 
				END IF
				
				# NOT Applied to invoice
				IF p_inv_num = 0 THEN 
	
					CALL get_conv_rate(
						p_company_cmpy_code,
						l_rec_customer.currency_code, 
						glob_rec_cashreceipt.cash_date,
						CASH_EXCHANGE_SELL) 
					RETURNING 
						glob_rec_cashreceipt.conv_qty 
	
					IF glob_rec_cashreceipt.conv_qty IS NULL THEN 
						LET glob_rec_cashreceipt.conv_qty = 0 
					END IF 
	
				ELSE # Applied to invoice
	
					IF l_recalc_ind = 'Y' THEN 
						IF l_disc_taken_ind = "N" THEN 
							LET l_disc_amt = 0 
						END IF 
					ELSE 
						IF glob_rec_cashreceipt.cash_date <= l_rec_invoicehead.disc_date THEN 
							LET l_disc_amt = l_rec_invoicehead.disc_amt 
						ELSE 
							LET l_disc_amt = 0 
						END IF 
					END IF
					 
					IF get_debug() THEN
						DISPLAY "----- AFTER FIELD cash_date ---------------------------------*" 
						DISPLAY "Before calc ------------------------------------"
						DISPLAY "glob_rec_cashreceipt.cash_amt =", trim(glob_rec_cashreceipt.cash_amt)
						DISPLAY "l_rec_invoicehead.total_amt =", trim(l_rec_invoicehead.total_amt)
						DISPLAY "l_rec_invoicehead.paid_amt =", trim(l_rec_invoicehead.paid_amt)
						DISPLAY "l_disc_amt =", trim(l_disc_amt)			
					END IF
				
					LET glob_rec_cashreceipt.cash_amt = 
						l_rec_invoicehead.total_amt 
						- l_rec_invoicehead.paid_amt 
						- l_disc_amt 
				END IF
				 
				IF get_debug() THEN
					DISPLAY "After calc ------------------------------------"
					DISPLAY "glob_rec_cashreceipt.cash_amt =", trim(glob_rec_cashreceipt.cash_amt)
					DISPLAY "l_rec_invoicehead.total_amt =", trim(l_rec_invoicehead.total_amt)
					DISPLAY "l_rec_invoicehead.paid_amt =", trim(l_rec_invoicehead.paid_amt)
					DISPLAY "l_disc_amt =", trim(l_disc_amt)															
				END IF
				
				DISPLAY glob_rec_cashreceipt.period_num TO period_num 
				DISPLAY glob_rec_cashreceipt.cash_amt TO cash_amt #### bs 
				DISPLAY glob_rec_cashreceipt.year_num TO year_num 
				DISPLAY glob_rec_cashreceipt.conv_qty TO conv_qty 

			AFTER FIELD period_num 
				CALL valid_period(
					p_company_cmpy_code,
					glob_rec_cashreceipt.year_num,
					glob_rec_cashreceipt.period_num,
					LEDGER_TYPE_AR) 
				RETURNING 
					glob_rec_cashreceipt.year_num,
					glob_rec_cashreceipt.period_num,
					l_invalid_period 
				
				IF l_invalid_period THEN 
					CALL db_period_what_period(p_company_cmpy_code,glob_rec_cashreceipt.cash_date) 
					RETURNING glob_rec_cashreceipt.year_num,	glob_rec_cashreceipt.period_num 

					DISPLAY glob_rec_cashreceipt.year_num TO year_num 
					DISPLAY glob_rec_cashreceipt.period_num TO period_num 

					NEXT FIELD year_num 
				END IF 

			BEFORE FIELD cash_amt
				IF (glob_rec_cashreceipt.cash_amt IS NULL) OR (glob_rec_cashreceipt.cash_amt = 0) THEN
					LET glob_rec_cashreceipt.cash_amt =  glob_rec_invoicehead.total_amt
				END IF 
							
			AFTER FIELD cash_amt 
				IF glob_rec_cashreceipt.cash_amt IS NULL THEN 
					ERROR kandoomsg2("A",9131,"") #9131 " Must enter a value in the received amount"
					NEXT FIELD cash_amt 
				END IF 

				IF glob_rec_cashreceipt.cash_amt < 0 THEN 
					IF NOT kandooDialog("A",8012,"",TRUE,"Negative Cash Receipt","WARNING") THEN
					--IF kandoomsg("A",8012,"") != "Y" THEN 	#8012 Warning: Negative Cash Receipt authorized.
						NEXT FIELD cash_amt 
					END IF 
				END IF 

			BEFORE FIELD bank_amt 
				#Customer currency = GL Base currency
				IF l_rec_customer.currency_code = l_rec_glparms.base_currency_code THEN 
					LET l_bank_amt = glob_rec_cashreceipt.cash_amt 
					LET glob_rec_cashreceipt.conv_qty = 1 
					NEXT FIELD com1_text 

				ELSE #Customer currency != GL Base currency

					#Bank currency = Customer currency
					IF l_rec_bank.currency_code = l_rec_customer.currency_code THEN 
						LET l_bank_amt = glob_rec_cashreceipt.cash_amt 
						NEXT FIELD conv_qty 
					ELSE #Bank currency != Customer currency
						IF glob_rec_cashreceipt.conv_qty > 0 THEN 
							LET l_bank_amt = glob_rec_cashreceipt.cash_amt / glob_rec_cashreceipt.conv_qty 
						END IF 
					END IF 

				END IF 

			AFTER FIELD bank_amt 
				CASE 
					WHEN l_bank_amt IS NULL 
						LET l_bank_amt = 0 
					WHEN l_bank_amt = 0 
						CALL get_conv_rate(
							p_company_cmpy_code,
							l_rec_customer.currency_code, 
							glob_rec_cashreceipt.cash_date,
							CASH_EXCHANGE_SELL) 
						RETURNING glob_rec_cashreceipt.conv_qty 
						
						LET l_bank_amt = glob_rec_cashreceipt.cash_amt / glob_rec_cashreceipt.conv_qty 

					WHEN glob_rec_cashreceipt.cash_amt != 0 
						AND l_bank_amt != 0 
						LET glob_rec_cashreceipt.conv_qty = glob_rec_cashreceipt.cash_amt	/ l_bank_amt 

					WHEN glob_rec_cashreceipt.cash_amt = 0 
						AND l_bank_amt != 0 
						LET glob_rec_cashreceipt.cash_amt = l_bank_amt * glob_rec_cashreceipt.conv_qty 
				END CASE 

				DISPLAY glob_rec_cashreceipt.cash_amt TO cash_amt 
				DISPLAY l_bank_amt TO bank_amt 
				DISPLAY glob_rec_cashreceipt.conv_qty TO conv_qty 

			BEFORE FIELD conv_qty 
				#Bank currency = GL Base currency
				IF l_rec_bank.currency_code = l_rec_glparms.base_currency_code THEN 
					IF glob_rec_cashreceipt.cash_amt != 0 AND l_bank_amt != 0 THEN 
						LET glob_rec_cashreceipt.conv_qty = glob_rec_cashreceipt.cash_amt	/ l_bank_amt 
					END IF 
				END IF 

			AFTER FIELD conv_qty 
				IF glob_rec_cashreceipt.conv_qty IS NULL THEN 
					CALL get_conv_rate(
						p_company_cmpy_code,
						l_rec_customer.currency_code, 
						glob_rec_cashreceipt.cash_date,
						CASH_EXCHANGE_SELL) 
					RETURNING glob_rec_cashreceipt.conv_qty
					 
					ERROR kandoomsg2("A",9117,"") #9117" Exchange rate must have a value"
					NEXT FIELD conv_qty 
				END IF 

				IF glob_rec_cashreceipt.conv_qty <= 0 THEN 
					ERROR kandoomsg2("A",9118,"") #9118" Exchange Rate must be greater than zero"
					NEXT FIELD conv_qty 
				ELSE
					IF l_rec_bank.currency_code = l_rec_glparms.base_currency_code THEN #Bank currency = GL Base currency
						LET l_bank_amt = glob_rec_cashreceipt.cash_amt 	/ glob_rec_cashreceipt.conv_qty 
					END IF 
				END IF 

			BEFORE FIELD com1_text 
				DISPLAY glob_rec_cashreceipt.cash_amt TO cash_amt 
				DISPLAY l_bank_amt TO bank_amt 
				DISPLAY glob_rec_cashreceipt.conv_qty TO conv_qty 

			AFTER INPUT 
				IF NOT(int_flag OR quit_flag) THEN 

					# Bank Account
					SELECT * INTO l_rec_bank.* FROM bank 
					WHERE cmpy_code = p_company_cmpy_code 
					AND bank_code = l_rec_bank.bank_code 
					IF status = NOTFOUND THEN 
						ERROR kandoomsg2("A",9132,"") #9132" Bank Account Not Found - Try Window "
						NEXT FIELD bank_code 
					END IF 
					
					# Period					
					CALL valid_period(
						p_company_cmpy_code, 
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
					
					# order_num
					IF glob_rec_cashreceipt.order_num IS NOT NULL	AND l_rec_company.module_text[23] = "W" THEN
						SELECT unique 1 FROM orderhead  
						--SELECT unique 1 FROM ordhead #original 
						WHERE cmpy_code = p_company_cmpy_code 
						AND order_num = glob_rec_cashreceipt.order_num 
						IF status = NOTFOUND THEN 
							ERROR kandoomsg2("A",9517,"") #9517 Order NOT found.
							NEXT FIELD order_num 
						END IF 
					END IF 

{					
					# cash_amt AND bank_amt @@@ HuHo 6.10.2020
					IF ((glob_rec_cashreceipt.cash_amt = 0 AND glob_rec_cashreceipt.bank_amt = 0) 
						OR glob_rec_cashreceipt.cash_amt < 0
						OR glob_rec_cashreceipt.bank_amt < 0) THEN
						ERROR "Amount can not be 0 or negative"
						NEXT FIELD cash_amt
					END IF
					#not sure what combinations are allowed
					# cash_amt @@@
					#IF glob_rec_cashreceipt.bank_amt =< 0 THEN
					#	ERROR "Received amount can not be 0 or negative"
					#	NEXT FIELD bank_amt
					#END IF
}			
					# cash_amt
					IF glob_rec_cashreceipt.cash_amt <= 0 THEN
						ERROR "You cannot receive ZERO or negative Cash Amount"
						NEXT FIELD cash_amt
					END IF

					# applied_amt
					IF glob_rec_cashreceipt.applied_amt <= 0 THEN
						ERROR "You cannot apply ZERO or negative Amount"
						NEXT FIELD applied_amt
					END IF
					
					# currency_code #HuHo 6.10.2020
					IF NOT db_currency_pk_exists(UI_ON,MODE_UPDATE,glob_rec_cashreceipt.currency_code) THEN
						NEXT FIELD currency_code
					END IF

					# bank_currency_code #HuHo 6.10.2020
					IF NOT db_currency_pk_exists(UI_ON,MODE_UPDATE,glob_rec_cashreceipt.bank_currency_code) THEN
						NEXT FIELD bank_currency_code
					END IF
								
					# cash_type_ind
					IF glob_rec_cashreceipt.cash_type_ind IS NULL THEN 
						ERROR kandoomsg2("U",9102,"") #9102 Value must be entered
						NEXT FIELD cash_type_ind 
					END IF 

					# cash_type_ind
					IF glob_rec_cashreceipt.cash_type_ind = PAYMENT_TYPE_CHEQUE_Q THEN 
						IF NOT banking(glob_rec_cashreceipt.*,l_rec_customer.name_text) THEN 
							NEXT FIELD bank_code 
						END IF 
					END IF 

					IF glob_rec_cashreceipt.cash_type_ind = PAYMENT_TYPE_CC_P THEN 
						IF NOT cards(glob_rec_cashreceipt.*,l_rec_customer.name_text) THEN 
							NEXT FIELD bank_code 
						END IF 
					END IF 
					LET l_poss_disc_amt = l_disc_amt 
				END IF 

		END INPUT 

		IF int_flag = 0 AND quit_flag = 0 THEN 
			GOTO bypass 
			LABEL recovery: 

			LET l_err_continue = error_recover(l_err_message, status) 
			IF l_err_continue != "Y" THEN 
				EXIT PROGRAM 
			END IF 

			LABEL bypass: 
			WHENEVER ERROR GOTO recovery 

			BEGIN WORK 
				LET l_err_message = "A31a - Next Transaction Number Generater" 
				LET glob_rec_cashreceipt.cash_num = next_trans_num(p_company_cmpy_code,TRAN_TYPE_RECEIPT_CA,l_rec_customertype.acct_mask_code) 
				IF glob_rec_cashreceipt.cash_num < 0 THEN 
					LET status = glob_rec_cashreceipt.cash_num 
					GOTO recovery 
				END IF 

				LET l_err_message = "A31a - Cash Receipt Insert" 
				LET glob_rec_cashreceipt.cmpy_code = p_company_cmpy_code 
				LET glob_rec_cashreceipt.applied_amt = 0 
				LET glob_rec_cashreceipt.disc_amt = 0 
				LET glob_rec_cashreceipt.on_state_flag = "N" 
				LET glob_rec_cashreceipt.posted_flag = CASHRECEIPT_POST_FLAG_STATUS_NOT_POSTED_N 
				LET glob_rec_cashreceipt.next_num = 0 
				LET glob_rec_cashreceipt.banked_flag = "N" 
				LET glob_rec_cashreceipt.bank_code = l_rec_bank.bank_code 

				SELECT * INTO l_rec_userlocn.* FROM userlocn 
				WHERE cmpy_code = p_company_cmpy_code 
				AND sign_on_code = p_kandoouser_sign_on_code 

				LET glob_rec_cashreceipt.locn_code = l_rec_userlocn.locn_code 
				LET glob_rec_cashreceipt.order_num = glob_rec_cashreceipt.order_num 

				SELECT unique 1 FROM cashreceipt 
				WHERE cmpy_code = p_company_cmpy_code 
				AND cash_num = glob_rec_cashreceipt.cash_num 
				IF status = 0 THEN 
					ERROR kandoomsg2("A",9114,"") #9114 "transaction number exists - allocating new number
					LET glob_rec_cashreceipt.cash_num = 
					next_trans_num(p_company_cmpy_code,TRAN_TYPE_RECEIPT_CA,l_rec_customertype.acct_mask_code) 
				END IF 

				# INSERT ----------------------------------------------------
				INSERT INTO cashreceipt VALUES (glob_rec_cashreceipt.*) 

				LET l_err_message =" A31 - Customer Table Update" 

				DECLARE c_customer CURSOR FOR 
				SELECT * FROM customer 
				WHERE cmpy_code = p_company_cmpy_code 
				AND cust_code = glob_rec_cashreceipt.cust_code 
				FOR UPDATE 

				OPEN c_customer 
				FETCH c_customer INTO l_rec_customer.* 

				LET l_rec_customer.bal_amt = l_rec_customer.bal_amt - glob_rec_cashreceipt.cash_amt 
				LET l_rec_customer.curr_amt = l_rec_customer.curr_amt - glob_rec_cashreceipt.cash_amt 
				LET l_rec_customer.last_pay_date = glob_rec_cashreceipt.cash_date 
				LET l_rec_customer.next_seq_num = l_rec_customer.next_seq_num + 1 
				LET l_rec_customer.cred_bal_amt = l_rec_customer.cred_limit_amt - l_rec_customer.bal_amt 

				IF year(glob_rec_cashreceipt.cash_date) >	year(l_rec_customer.last_pay_date) THEN 
					LET l_rec_customer.ytdp_amt = 0 
				END IF 

				LET l_rec_customer.ytdp_amt = l_rec_customer.ytdp_amt + glob_rec_cashreceipt.cash_amt 
				LET l_rec_customer.mtdp_amt = l_rec_customer.mtdp_amt + glob_rec_cashreceipt.cash_amt 

				# UPDATE ------------------------------------
				UPDATE customer SET 
					bal_amt = l_rec_customer.bal_amt, 
					last_pay_date = l_rec_customer.last_pay_date, 
					curr_amt = l_rec_customer.curr_amt, 
					next_seq_num = l_rec_customer.next_seq_num, 
					cred_bal_amt = l_rec_customer.cred_bal_amt, 
					ytdp_amt = l_rec_customer.ytdp_amt, 
					mtdp_amt = l_rec_customer.mtdp_amt 
				WHERE cmpy_code = p_company_cmpy_code 
				AND cust_code = glob_rec_cashreceipt.cust_code 

				LET l_err_message = "A32 - AR Audit Row Insert" 
				LET l_rec_araudit.cmpy_code = p_company_cmpy_code 
				LET l_rec_araudit.tran_date = glob_rec_cashreceipt.cash_date 
				LET l_rec_araudit.cust_code = glob_rec_cashreceipt.cust_code 
				LET l_rec_araudit.seq_num = l_rec_customer.next_seq_num 
				LET l_rec_araudit.tran_type_ind = TRAN_TYPE_RECEIPT_CA 
				LET l_rec_araudit.source_num = glob_rec_cashreceipt.cash_num 
				LET l_rec_araudit.tran_text = "Cash Receipt" 
				LET l_rec_araudit.tran_amt = 0 - glob_rec_cashreceipt.cash_amt 
				LET l_rec_araudit.entry_code = p_kandoouser_sign_on_code 
				LET l_rec_araudit.year_num = glob_rec_cashreceipt.year_num 
				LET l_rec_araudit.period_num = glob_rec_cashreceipt.period_num 
				LET l_rec_araudit.bal_amt = l_rec_customer.bal_amt 
				LET l_rec_araudit.currency_code = l_rec_customer.currency_code 
				LET l_rec_araudit.conv_qty = glob_rec_cashreceipt.conv_qty 
				LET l_rec_araudit.entry_date = today 
	
				# INSERT ----------------------------------------------------
				INSERT INTO araudit VALUES (l_rec_araudit.*) 

			COMMIT WORK 
			WHENEVER ERROR stop
			WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

			#@todo @Eric From HuHo: What is the best way to detect an error with information here ? STATUS ? 
			LET l_msg = 
				"Receipt ", trim(glob_rec_cashreceipt.cash_num), 
				" Cust Seq No:", trim(l_rec_customer.next_seq_num), 
				"\nSource No ", trim(l_rec_araudit.source_num), 
				" over ", trim(l_rec_customer.currency_code), " ", trim(l_rec_araudit.tran_amt), 
				"\nBank Amount:", trim(l_bank_amt), 
				" Inv. No:", trim(glob_rec_invoicehead.inv_num), 
				"\nPurch. Code:", trim(glob_rec_invoicehead.purchase_code), 
				" Customer: ", trim(glob_rec_cashreceipt.cust_code),  
				"\nJournal No:", trim(glob_rec_glparms.next_jour_num), 
				" Seq No:", trim(glob_rec_glparms.next_seq_num),  " successfully created !"
			CALL fgl_winmessage("Receipt",l_msg,"INFO")
			
			IF p_inv_num = 0 THEN 
				#OPEN WINDOW wA31  WITH FORM "U999"  ATTRIBUTE(border)
				#CALL windecoration_u("U999")

				MESSAGE kandoomsg2("A",1024,glob_rec_cashreceipt.cash_num) #1024 successfull addition of receipt number 12210012

				MENU " Receipt Application" 
					BEFORE MENU 
						IF NOT p_apply_ind THEN 
							HIDE option "Manual" 
							HIDE option "Invoice" 
							HIDE option "Oldest" 
						ELSE 
							IF glob_rec_cashreceipt.cust_code != l_cust_code	OR l_cust_code IS NULL THEN 
								HIDE option "Invoice" 
							END IF 
						END IF 

						CALL publish_toolbar("kandoo","A31a","menu-receipt-application") 

					ON ACTION "WEB-HELP" 
						CALL onlinehelp(getmoduleid(),null) 

					ON ACTION "actToolbarManager" 
						CALL setuptoolbar() 


					COMMAND "Invoice" " Apply receipt TO selected invoice" 
						LET l_temp_text = "invoicehead.inv_num = ",l_inv_num2 
						CALL auto_cash_apply(
							p_company_cmpy_code,
							p_kandoouser_sign_on_code,
							glob_rec_cashreceipt.cash_num, 
							l_temp_text) 
						EXIT MENU 

					COMMAND "Manual" " Apply receipt TO nominated invoices" 
						CALL app_cash(
							p_company_cmpy_code,
							glob_rec_cashreceipt.cash_num, 
							p_kandoouser_sign_on_code) 
						EXIT MENU 

					COMMAND "Oldest" " Apply receipt TO invoices in due date ORDER" 
						CALL auto_cash_apply(
							p_company_cmpy_code,
							p_kandoouser_sign_on_code,
							glob_rec_cashreceipt.cash_num,
							"1=1") 
						EXIT MENU 

					COMMAND "Receipt" " Enter another receipt" 
						EXIT MENU 

					COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus" 
						LET quit_flag = TRUE 
						EXIT MENU 


				END MENU 
				#CLOSE WINDOW wA31
			ELSE 
				LET l_disc_amt = l_poss_disc_amt 
				LET l_appl_amt = glob_rec_cashreceipt.cash_amt 
				
				IF ( l_rec_invoicehead.total_amt - l_rec_invoicehead.paid_amt ) > ( l_appl_amt + l_disc_amt ) THEN 
					LET l_disc_amt = 0 
				ELSE 
					LET l_appl_amt = 
						l_rec_invoicehead.total_amt 
						- l_rec_invoicehead.paid_amt 
						- l_disc_amt 
				END IF
				 
				IF receipt_apply(
					p_company_cmpy_code,
					p_kandoouser_sign_on_code,
					glob_rec_cashreceipt.cash_num, 
					p_inv_num, 
					l_appl_amt, 
					l_disc_amt) THEN 
				END IF 
				EXIT WHILE 
			END IF 
		ELSE
			LET int_flag = FALSE 
			LET quit_flag = FALSE 
			EXIT WHILE 
		END IF 

	END WHILE 

	CLOSE WINDOW A182
	 
	RETURN glob_rec_cashreceipt.cash_num 

END FUNCTION #enter_cashreceipt() 
#################################################################################
# END FUNCTION enter_cashreceipt(p_company_cmpy_code,p_kandoouser_sign_on_code,p_inv_num,p_apply_ind)
#################################################################################