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

	Source code beautified by beautify.pl on 2019-12-31 14:28:28	$Id: $
}




# K11g.4gl - Subscription Cash Receipts
# K11g.4gl:FUNCTION K11_enter_receipt()
#           enter cashreceipt details FOR prepaid subs.
#           Amount defaults TO unpaid amount of sub

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "K_SS_GLOBALS.4gl" 
GLOBALS "K11_GLOBALS.4gl" 


FUNCTION K11_enter_receipt(pr_mode) 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE 
	pr_corpcust RECORD LIKE customer.*, 
	pr_glparms RECORD LIKE glparms.*, 
	pr_customertype RECORD LIKE customertype.*, 
	pr_cashreceipt RECORD LIKE cashreceipt.*, 
	pr_bank RECORD LIKE bank.*, 
	pr_availcr_amt LIKE customer.bal_amt, 
	pr_amt_int INTEGER, 
	pr_amt_flt FLOAT, 
	invalid_period INTEGER, 
	pr_appl_amt LIKE cashreceipt.cash_amt, 
	pr_poss_disc_amt , 
	pr_disc_amt LIKE cashreceipt.cash_amt, 
	pr_disc_taken_ind CHAR(1), 
	pr_mode CHAR(4), 
	pr_recalc_ind CHAR(1), 
	err_message CHAR(40), 
	pr_continue, exitmenu SMALLINT, 
	winds_text CHAR(20), 
	winds_num INTEGER, 
	pr_reference_text LIKE kandooword.reference_text 

	SELECT base_currency_code INTO pr_glparms.base_currency_code FROM glparms 
	WHERE key_code = "1" 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF status = notfound THEN 
		LET msgresp=kandoomsg("A",5001,"") 
		#5001 GL Parameters Not Found - Refer Menu GZP"
		RETURN 0 
	END IF 
	LET pr_csubhead.paid_amt = pr_subhead.paid_amt 
	LET pr_csubhead.total_amt = pr_subhead.total_amt 
	IF pr_mode = "CORP" THEN 
		SELECT sum(paid_amt),sum(total_amt) 
		INTO pr_csubhead.paid_amt, 
		pr_csubhead.total_amt 
		FROM t_subhead 
	END IF 
	IF pr_csubhead.total_amt IS NULL THEN 
		LET pr_csubhead.total_amt = 0 
	END IF 
	IF pr_csubhead.paid_amt IS NULL THEN 
		LET pr_csubhead.paid_amt = 0 
	END IF 
	OPEN WINDOW k134 at 2,4 WITH FORM "K134" 
	attribute(border) 
	LET msgresp = kandoomsg("A",1023,"") 
	#1023 Enter Cash Receipt Details - F8 FOR Customer Information
	WHILE true 
		CLEAR FORM 
		INITIALIZE pr_bank.* TO NULL 
		INITIALIZE pr_cashreceipt.* TO NULL 
		SELECT * INTO pr_cashreceipt.* 
		FROM t_cashreceipt 
		IF status = notfound THEN 
			LET pr_cashreceipt.cash_amt = pr_csubhead.total_amt 
			- pr_csubhead.paid_amt 
		END IF 
		IF pr_cashreceipt.cash_amt < 0 THEN 
			LET pr_cashreceipt.cash_amt = 0 
		END IF 
		LET pr_cashreceipt.order_num = pr_subhead.sub_num 
		LET pr_cashreceipt.cust_code = pr_subhead.cust_code 
		IF pr_subhead.corp_flag = "Y" THEN 
			LET pr_cashreceipt.cust_code = pr_subhead.corp_cust_code 
		END IF 
		IF pr_mode = "CORP" THEN 
			LET pr_cashreceipt.cust_code = pr_csubhead.cust_code 
		END IF 
		SELECT * INTO pr_customer.* 
		FROM customer 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = pr_cashreceipt.cust_code 
		IF pr_customer.corp_cust_code IS NOT NULL 
		AND pr_customer.corp_cust_ind = "1" THEN 
			LET msgresp=kandoomsg("A",7032,"") 
			#7032 You can NOT receipt cash FOR a Subsidiary Debtor
			LET pr_cashreceipt.cust_code = pr_customer.corp_cust_code 
			SELECT name_text,currency_code 
			INTO pr_customer.name_text, 
			pr_customer.currency_code 
			FROM customer 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cust_code = pr_customer.corp_cust_code 
		END IF 
		LET pr_cashreceipt.conv_qty = get_conv_rate(
			glob_rec_kandoouser.cmpy_code, 
			pr_customer.currency_code, 
			today, 
			CASH_EXCHANGE_SELL) 
		
		DECLARE c1_bank CURSOR FOR 
		SELECT * FROM bank 
		WHERE currency_code = pr_customer.currency_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		OPEN c1_bank 
		FETCH c1_bank INTO pr_bank.* 
		
		LET pr_cashreceipt.bank_code = pr_bank.bank_code 
		LET pr_cashreceipt.cash_acct_code = pr_bank.acct_code 
		LET pr_cashreceipt.currency_code = pr_customer.currency_code 
		LET pr_cashreceipt.bank_currency_code = pr_bank.currency_code 
		
		DISPLAY BY NAME pr_cashreceipt.currency_code	attribute(green) 
		
		LET pr_cashreceipt.cash_type_ind = "C" 
		LET pr_cashreceipt.cash_date = today 
		LET pr_cashreceipt.chq_date = today 
		LET pr_cashreceipt.entry_date = today 
		LET pr_cashreceipt.entry_code = glob_rec_kandoouser.sign_on_code 
		CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,today) 
		RETURNING pr_cashreceipt.year_num, 
		pr_cashreceipt.period_num 
		LET pr_reference_text = kandooword("cashreceipt.cash_type_ind", 
		pr_cashreceipt.cash_type_ind) 
		DISPLAY BY NAME pr_customer.name_text, 
		pr_bank.name_acct_text, 
		pr_cashreceipt.cash_date, 
		pr_cashreceipt.year_num, 
		pr_cashreceipt.period_num, 
		pr_cashreceipt.entry_code, 
		pr_cashreceipt.entry_date, 
		pr_reference_text 

		INPUT BY NAME pr_cashreceipt.cust_code, 
		pr_bank.bank_code, 
		pr_cashreceipt.order_num, 
		pr_cashreceipt.cash_date, 
		pr_cashreceipt.cash_type_ind, 
		pr_cashreceipt.year_num, 
		pr_cashreceipt.period_num, 
		pr_cashreceipt.cash_amt, 
		pr_cashreceipt.com1_text, 
		pr_cashreceipt.com2_text WITHOUT DEFAULTS 

			ON ACTION "WEB-HELP" -- albo kd-374 
				CALL onlinehelp(getmoduleid(),null) 

			ON KEY (control-b) 
				CASE 
					WHEN infield(cust_code) 
						LET winds_text = show_clnt(glob_rec_kandoouser.cmpy_code) 
						IF winds_text IS NOT NULL THEN 
							LET pr_cashreceipt.cust_code = winds_text 
						END IF 
						NEXT FIELD cust_code 
					WHEN infield(bank_code) 
						CALL show_bank(glob_rec_kandoouser.cmpy_code) 
						RETURNING pr_bank.bank_code, 
						pr_cashreceipt.cash_acct_code 
						DISPLAY BY NAME pr_bank.bank_code 

						NEXT FIELD bank_code 
				END CASE 

			ON KEY (F8) --customer details / customer invoice submenu 
				CALL cinq_clnt(glob_rec_kandoouser.cmpy_code,pr_customer.cust_code) --customer details / customer invoice submenu 
				NEXT FIELD cust_code 

			BEFORE FIELD cust_code 
				SELECT * INTO pr_customertype.* FROM customertype 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND type_code = pr_customer.type_code 
				IF NOT valid_trans_num(glob_rec_kandoouser.cmpy_code, 
				TRAN_TYPE_RECEIPT_CA, 
				pr_customertype.acct_mask_code) THEN 
					LET msgresp=kandoomsg("A",7031,"") 
					#7031 "Warning: Invalid numbering - Review Menu GZD"
				END IF 
				NEXT FIELD NEXT 
			AFTER FIELD cust_code 
				SELECT * INTO pr_customer.* FROM customer 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cust_code = pr_cashreceipt.cust_code 
				AND delete_flag != "Y" 
				IF status = notfound THEN 
					LET msgresp=kandoomsg("A",9009,"") 
					#9009" Customer NOT found - Try Window"
					NEXT FIELD cust_code 
				END IF 
				IF pr_customer.corp_cust_code IS NOT NULL 
				AND pr_customer.corp_cust_ind = "1" THEN 
					LET msgresp=kandoomsg("A",7032,"") 
					#7032 You can NOT receipt cash FOR a Subsidiary Debtor
					LET pr_cashreceipt.cust_code = pr_customer.corp_cust_code 
					NEXT FIELD cust_code 
				END IF 
				LET pr_cashreceipt.conv_qty = get_conv_rate(
					glob_rec_kandoouser.cmpy_code,
					pr_customer.currency_code,
					today,
					CASH_EXCHANGE_SELL) 
				
				SELECT customertype.* INTO pr_customertype.* FROM customertype 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND type_code = pr_customer.type_code 
				
				IF NOT valid_trans_num(glob_rec_kandoouser.cmpy_code,TRAN_TYPE_RECEIPT_CA, 
				pr_customertype.acct_mask_code) THEN 
					LET msgresp=kandoomsg("A",7031,"")			#7031 "Warning: Invalid numbering - Review Menu GZD"
				END IF 
				
				LET pr_cashreceipt.conv_qty =	get_conv_rate(
					glob_rec_kandoouser.cmpy_code, 
					pr_customer.currency_code, 
					today, 
					CASH_EXCHANGE_SELL)
				 
				DECLARE c2_bank CURSOR FOR 
				SELECT * FROM bank 
				WHERE currency_code = pr_customer.currency_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				OPEN c2_bank 
				FETCH c2_bank INTO pr_bank.* 
				
				LET pr_cashreceipt.bank_code = pr_bank.bank_code 
				LET pr_cashreceipt.cash_acct_code = pr_bank.acct_code 
				LET pr_cashreceipt.currency_code = pr_customer.currency_code 
				LET pr_cashreceipt.bank_currency_code = pr_bank.currency_code 
				DISPLAY BY NAME pr_customer.name_text, 
				pr_bank.name_acct_text 

				DISPLAY BY NAME pr_cashreceipt.currency_code 
				attribute(green) 
			AFTER FIELD bank_code 
				SELECT * INTO pr_bank.* FROM bank 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND bank_code = pr_bank.bank_code 
				IF status = notfound THEN 
					LET msgresp=kandoomsg("A",9132,"") 
					#9132" Bank Account Not Found - Try Window "
					NEXT FIELD bank_code 
				END IF 
				IF pr_bank.currency_code != pr_customer.currency_code THEN 
					IF pr_bank.currency_code != pr_glparms.base_currency_code THEN 
						LET msgresp=kandoomsg("A",9133,"") 
						#9133 Banking IS permitted INTO cust OR base curr bankac
						NEXT FIELD bank_code 
					END IF 
				END IF 
				LET pr_cashreceipt.bank_code = pr_bank.bank_code 
				LET pr_cashreceipt.bank_currency_code = pr_bank.currency_code 
				LET pr_cashreceipt.cash_acct_code = pr_bank.acct_code 
				DISPLAY BY NAME pr_bank.name_acct_text 

			BEFORE FIELD order_num 
				IF fgl_lastkey() = fgl_keyval("up") 
				OR fgl_lastkey() = fgl_keyval("left") THEN 
					NEXT FIELD previous 
				ELSE 
				NEXT FIELD NEXT 
			END IF 
			AFTER FIELD cash_date 
				IF pr_cashreceipt.cash_date IS NULL THEN 
					LET pr_cashreceipt.cash_date = today 
					NEXT FIELD cash_date 
				END IF 
				CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,pr_cashreceipt.cash_date) 
				RETURNING pr_cashreceipt.year_num, 
				pr_cashreceipt.period_num 
				DISPLAY BY NAME pr_cashreceipt.cash_date, 
				pr_cashreceipt.year_num, 
				pr_cashreceipt.period_num 

			AFTER FIELD cash_type_ind 
				IF pr_cashreceipt.cash_type_ind IS NULL 
				OR pr_cashreceipt.cash_type_ind NOT matches "[CQPO]" THEN 
					LET msgresp = kandoomsg("W",9295,"") 
					#9295 Payment type NOT found "
					NEXT FIELD cash_type_ind 
				END IF 
				LET pr_reference_text = kandooword("cashreceipt.cash_type_ind", 
				pr_cashreceipt.cash_type_ind) 
				DISPLAY BY NAME pr_reference_text 

				IF fgl_lastkey() = fgl_keyval("up") 
				OR fgl_lastkey() = fgl_keyval("left") THEN 
					NEXT FIELD bank_code 
				END IF 
				
			AFTER FIELD period_num 
				CALL valid_period(
					glob_rec_kandoouser.cmpy_code,
					pr_cashreceipt.year_num, 
					pr_cashreceipt.period_num,
					LEDGER_TYPE_AR) 
				RETURNING 
					pr_cashreceipt.year_num, 
					pr_cashreceipt.period_num, 
					invalid_period
					 
				IF invalid_period THEN 
					CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,pr_cashreceipt.cash_date) 
					RETURNING pr_cashreceipt.year_num, 
					pr_cashreceipt.period_num 
					DISPLAY BY NAME pr_cashreceipt.year_num, 
					pr_cashreceipt.period_num 

					NEXT FIELD year_num 
				END IF 
			AFTER FIELD cash_amt 
				IF pr_cashreceipt.cash_amt IS NULL THEN 
					LET msgresp=kandoomsg("A",9131,"") 
					#9131 " Must enter a value in the received amount"
					NEXT FIELD cash_amt 
				END IF 
				IF pr_cashreceipt.cash_amt = 0 THEN 
					LET msgresp=kandoomsg("A",9131,"") 	#9131 " Must enter a value in the received amount"
					NEXT FIELD cash_amt 
				END IF 
			AFTER INPUT 
				IF not(int_flag OR quit_flag) THEN 
					CALL valid_period(
						glob_rec_kandoouser.cmpy_code, 
						pr_cashreceipt.year_num, 
						pr_cashreceipt.period_num, 
						LEDGER_TYPE_AR) 
					RETURNING 
						pr_cashreceipt.year_num, 
						pr_cashreceipt.period_num, 
						invalid_period 
					IF invalid_period THEN 
						NEXT FIELD year_num 
					END IF 
					
					IF pr_cashreceipt.cash_type_ind IS NULL	OR pr_cashreceipt.cash_type_ind NOT matches "[CQPO]" THEN 
						LET msgresp = kandoomsg("W",9295,"")		#9295 Payment type NOT found "
						NEXT FIELD cash_type_ind 
					END IF 
					IF pr_cashreceipt.cash_amt IS NULL THEN 
						LET msgresp=kandoomsg("A",9131,"")		#9131 " Must enter a value in the received amount"
						NEXT FIELD cash_amt 
					END IF 
					IF pr_cashreceipt.cash_amt = 0 THEN 
						LET msgresp=kandoomsg("A",9131,"") 
						#9131 " Must enter a value in the received amount"
						NEXT FIELD cash_amt 
					END IF 
					IF pr_cashreceipt.cash_amt < 0 THEN 
						IF kandoomsg("A",8012,"") != "Y" THEN 
							#8012 Warning: Negative Cash Receipt authorized.
							NEXT FIELD cash_amt 
						END IF 
					END IF 
					IF pr_cashreceipt.cash_type_ind = PAYMENT_TYPE_CHEQUE_Q THEN 
						CALL banking(pr_cashreceipt.*, pr_customer.name_text) 
						RETURNING pr_cashreceipt.*, pr_continue 
						IF NOT pr_continue THEN 
							NEXT FIELD bank_code 
						END IF 
					END IF 
					IF pr_cashreceipt.cash_type_ind = "P" THEN 
						CALL cards(pr_cashreceipt.*, pr_customer.name_text) 
						RETURNING pr_cashreceipt.*, pr_continue 
						IF NOT pr_continue THEN 
							NEXT FIELD bank_code 
						END IF 
					END IF 
				END IF 
			ON KEY (control-w) 
				CALL kandoohelp("") 
		END INPUT 
		IF int_flag OR quit_flag THEN 
			CLOSE WINDOW k134 
			RETURN 0 
		END IF 
		DELETE FROM t_cashreceipt 
		WHERE 1=1 
		LET err_message = "K11g - Cash Receipt insert" 
		LET pr_cashreceipt.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET pr_cashreceipt.applied_amt = 0 
		LET pr_cashreceipt.disc_amt = 0 
		LET pr_cashreceipt.on_state_flag = "N" 
		LET pr_cashreceipt.posted_flag = CASHRECEIPT_POST_FLAG_STATUS_NOT_POSTED_N 
		LET pr_cashreceipt.next_num = 0 
		LET pr_cashreceipt.banked_flag = "N" 
		
		#INSERT ----------------------------------------------
		INSERT INTO t_cashreceipt VALUES (pr_cashreceipt.*) 
		EXIT WHILE 
		
	END WHILE 
	CLOSE WINDOW k134 
	RETURN pr_cashreceipt.cash_amt 
END FUNCTION 


FUNCTION banking(pr_cashreceipt, pr_name_text) 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE 
	pr_cashreceipt RECORD LIKE cashreceipt.*, 
	ps_cashreceipt RECORD LIKE cashreceipt.*, 
	pr_name_text LIKE customer.name_text 

	OPEN WINDOW A151 WITH FORM "A151" 

	LET msgresp = kandoomsg("U",1020,"Cheque") 
	#1020 Enter Cheque Details; OK TO Continue
	LET ps_cashreceipt.* = pr_cashreceipt.* 
	LET ps_cashreceipt.drawer_text = pr_name_text 
	DISPLAY BY NAME ps_cashreceipt.bank_text, 
	ps_cashreceipt.branch_text, 
	ps_cashreceipt.drawer_text, 
	ps_cashreceipt.cheque_text, 
	ps_cashreceipt.chq_date 

	INPUT BY NAME ps_cashreceipt.bank_text, 
	ps_cashreceipt.branch_text, 
	ps_cashreceipt.drawer_text, 
	ps_cashreceipt.cheque_text, 
	ps_cashreceipt.chq_date WITHOUT DEFAULTS 

		ON ACTION "WEB-HELP" -- albo kd-374 
			CALL onlinehelp(getmoduleid(),null) 

	END INPUT 

	CLOSE WINDOW A151 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN pr_cashreceipt.*, false 
	END IF 
	RETURN ps_cashreceipt.*, true 
END FUNCTION 


FUNCTION cards(pr_cashreceipt, pr_name_text) 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE 
	pr_card_type CHAR(1), 
	pr_cashreceipt RECORD LIKE cashreceipt.*, 
	ps_cashreceipt RECORD LIKE cashreceipt.*, 
	pr_month_exp, pr_year_exp SMALLINT, 
	pr_name_text LIKE customer.name_text 

	OPEN WINDOW A632 WITH FORM "A632" 

	LET ps_cashreceipt.* = pr_cashreceipt.* 
	LET ps_cashreceipt.drawer_text = pr_name_text 
	LET pr_month_exp = ps_cashreceipt.card_exp_date[1,2] 
	LET pr_year_exp = ps_cashreceipt.card_exp_date[3,4] 
	LET pr_card_type = ps_cashreceipt.bank_text[1] 

	LET msgresp = kandoomsg("U",1020,"Credit Card")	#1020 Enter Credit Card Details; OK TO Continue

	INPUT BY NAME 
		pr_card_type, 
		ps_cashreceipt.bank_text, 
		ps_cashreceipt.branch_text, 
		ps_cashreceipt.drawer_text, 
		pr_month_exp, 
		pr_year_exp WITHOUT DEFAULTS 

		ON ACTION "WEB-HELP" -- albo kd-374 
			CALL onlinehelp(getmoduleid(),null) 

		AFTER FIELD pr_card_type 
			IF pr_card_type = "V" THEN 
				LET ps_cashreceipt.bank_text = "VISA" 
			END IF 
			IF pr_card_type = "M" THEN 
				LET ps_cashreceipt.bank_text = "MASTERCARD" 
			END IF 
			IF pr_card_type = "B" THEN 
				LET ps_cashreceipt.bank_text = "BANKCARD" 
			END IF 
			IF pr_card_type = "A" THEN 
				LET ps_cashreceipt.bank_text = "AMEX" 
			END IF 
			IF pr_card_type = "D" THEN 
				LET ps_cashreceipt.bank_text = "DINERS club" 
			END IF 
		AFTER FIELD branch_text 
			IF ps_cashreceipt.branch_text IS NOT NULL THEN 
				IF verify_creditcard_number(ps_cashreceipt.branch_text) THEN 
					LET msgresp = kandoomsg("K",6000,"") 
					#6000 Invalid Credit Card Number Entered.
				END IF 
			END IF 

	END INPUT 

	CLOSE WINDOW A632 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN pr_cashreceipt.*, false 
	END IF 

	LET ps_cashreceipt.card_exp_date = pr_month_exp USING "&&",	pr_year_exp USING "&&" 
	RETURN ps_cashreceipt.*, true 
END FUNCTION 


FUNCTION verify_creditcard_number(pr_card_num) 
	DEFINE 
	pr_card_num CHAR(20), 
	pr_string CHAR(2), 
	pr_check_sum, pr_num_check, pr_total, 
	pr_num, x, y, pr_card_length, idx SMALLINT 

	LET pr_total = 0 
	LET pr_check_sum = 0 
	LET pr_card_length = length(pr_card_num) 
	LET pr_num_check = 2 

	FOR idx = pr_card_length TO 1 step -1 
		IF pr_card_num[idx] = " " THEN 
			CONTINUE FOR 
		END IF 
		IF pr_card_num[idx] = "-" THEN 
			CONTINUE FOR 
		END IF 
		IF pr_card_num[idx] NOT matches "[1234567890]" THEN 
			RETURN true 
		END IF 
		IF pr_num_check = 2 THEN 
			LET pr_num_check = 1 
		ELSE 
		LET pr_num_check = 2 
	END IF 

	LET x = pr_num_check 
	LET y = pr_card_num[idx] 
	LET pr_num = x * y 
	IF pr_num > 9 THEN 
		LET pr_string = pr_num 
		LET x = pr_string[1] 
		LET y = pr_string[2] 
		LET pr_num = x + y 
	END IF 
	LET pr_total = pr_total + pr_num 
END FOR 

LET pr_check_sum = pr_total mod 10 

IF pr_check_sum = 0 THEN 
	RETURN false 
ELSE 
RETURN true 
END IF
END FUNCTION 
