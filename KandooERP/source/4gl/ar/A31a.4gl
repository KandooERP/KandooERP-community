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
--GLOBALS "../ar/A21_GLOBALS.4gl" 
--GLOBALS "../ar/A22_GLOBALS.4gl"
--GLOBALS "../ar/A2_GROUP_GLOBALS.4gl" 
##############################################################
# FUNCTION enter_cash_blind(p_company_cmpy_code,p_kandoouser_sign_on_code,p_inv_num,p_apply_ind,p_cash_type_ind)
#
# \brief module - A31a.4gl
# Purpose - FUNCTION enter_cashreceipt allows the user TO enter cash
#           receipts FROM customers
##############################################################
FUNCTION enter_cash_blind(p_company_cmpy_code,p_kandoouser_sign_on_code,p_inv_num,p_apply_ind,p_cash_type_ind) 
	DEFINE p_cash_type_ind CHAR(1) 
	DEFINE p_company_cmpy_code LIKE company.cmpy_code 
	DEFINE p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code 
	DEFINE p_inv_num LIKE invoicehead.inv_num 
	DEFINE p_apply_ind SMALLINT #may be NOT used 

	DEFINE l_inv_num2 LIKE invoicehead.inv_num 
	DEFINE l_rec_glparms RECORD LIKE glparms.* 
--	DEFINE l_rec_arparms RECORD LIKE arparms.* 
	DEFINE l_rec_userlocn RECORD LIKE userlocn.* 
	DEFINE l_company RECORD LIKE company.* 
	DEFINE l_customer RECORD LIKE customer.* 
	DEFINE l_rec_customertype RECORD LIKE customertype.* 
	DEFINE l_invoicehead RECORD LIKE invoicehead.* 
	DEFINE l_rec_bank RECORD LIKE bank.* 
	DEFINE l_rec_araudit RECORD LIKE araudit.* 
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

--	SELECT arparms.* INTO l_rec_arparms.* FROM arparms 
--	WHERE arparms.parm_code = "1" 
--	AND arparms.cmpy_code = p_company_cmpy_code
--	IF status = NOTFOUND THEN 
--		ERROR kandoomsg2("A",5002,"") #5002" AP Parameters Not Found - Refer Menu AZP"
--		EXIT PROGRAM 
--	END IF
	 
	SELECT base_currency_code INTO l_rec_glparms.base_currency_code 
	FROM glparms 
	WHERE key_code = "1" 
	AND cmpy_code = p_company_cmpy_code 
	IF status = NOTFOUND THEN 
		ERROR kandoomsg2("A",5001,"") #5001 GL Parameters Not Found - Refer Menu GZP"
		EXIT PROGRAM 
	END IF 

	SELECT * INTO l_company.* FROM company 
	WHERE cmpy_code = p_company_cmpy_code 

	INITIALIZE glob_rec_cashreceipt.* TO NULL 
	INITIALIZE l_customer.* TO NULL 
	INITIALIZE l_rec_bank.* TO NULL 

	IF l_invoicehead.disc_amt IS NULL THEN
		LET l_invoicehead.disc_amt = 0
	END IF

	LET glob_rec_cashreceipt.entry_date = today 
	LET glob_rec_cashreceipt.entry_code = trim(p_kandoouser_sign_on_code) 
	LET glob_rec_cashreceipt.cash_date = today 
	LET glob_rec_cashreceipt.cash_acct_code = trim(glob_rec_arparms.cash_acct_code) 
	LET glob_rec_cashreceipt.cash_amt = 0 
	LET l_disc_amt = 0 
	LET l_bank_amt = 0 

	CALL db_period_what_period(p_company_cmpy_code,today) 
	RETURNING glob_rec_cashreceipt.year_num, glob_rec_cashreceipt.period_num 

	IF p_inv_num > 0 THEN 
		SELECT * INTO l_invoicehead.* FROM invoicehead 
		WHERE cmpy_code = p_company_cmpy_code 
		AND inv_num = p_inv_num 

		SELECT * INTO l_customer.* FROM customer 
		WHERE cmpy_code = p_company_cmpy_code 
		AND cust_code = l_invoicehead.cust_code 
		AND delete_flag != "Y" 

		LET glob_rec_cashreceipt.cash_date = l_invoicehead.inv_date 
		LET glob_rec_cashreceipt.year_num = l_invoicehead.year_num 
		LET glob_rec_cashreceipt.period_num = l_invoicehead.period_num 
		LET glob_rec_cashreceipt.conv_qty = l_invoicehead.conv_qty 
		LET glob_rec_cashreceipt.cust_code = trim(l_customer.cust_code) 

		SELECT customertype.* INTO l_rec_customertype.* FROM customertype 
		WHERE cmpy_code = p_company_cmpy_code 
		AND type_code = l_customer.type_code 

		IF NOT valid_trans_num(
			p_company_cmpy_code,
			TRAN_TYPE_RECEIPT_CA, 
			l_rec_customertype.acct_mask_code) THEN 
			ERROR kandoomsg2("A",7031,"") #7031 "Warning: Invalid numbering - Review Menu GZD"
		END IF 

		CALL calc_cash_amt(p_company_cmpy_code, glob_rec_cashreceipt.cash_date,	l_invoicehead.*) 
		RETURNING glob_rec_cashreceipt.cash_amt, l_disc_amt, l_recalc_ind, 	l_disc_taken_ind 
	END IF 

	SELECT * INTO l_customer.* FROM customer 
	WHERE cmpy_code = p_company_cmpy_code 
	AND cust_code = glob_rec_cashreceipt.cust_code 
	AND delete_flag != "Y" 

	IF status = NOTFOUND THEN 
		ERROR kandoomsg2("A",9009,"") #9009" Customer NOT found - Try Window"
		RETURN false 

	END IF 

	IF l_customer.corp_cust_code IS NOT NULL AND 
	l_customer.corp_cust_ind = "1" THEN 
		ERROR kandoomsg2("A",7032,"") #7032 You can NOT receipt cash FOR a Subsidiary Debtor
		LET glob_rec_cashreceipt.cust_code = trim(l_customer.corp_cust_code) 
		RETURN false 

	END IF 

	LET glob_rec_cashreceipt.conv_qty = get_conv_rate(
		p_company_cmpy_code,
		l_customer.currency_code,
		today,
		CASH_EXCHANGE_SELL) 

	MESSAGE kandoomsg2("A",1023,"") #1023 Enter Cash Receipt Details;  F8 FOR Customer Information.
	SELECT customertype.* INTO l_rec_customertype.* FROM customertype 
	WHERE cmpy_code = p_company_cmpy_code 
	AND type_code = l_customer.type_code 

	IF NOT valid_trans_num(p_company_cmpy_code,TRAN_TYPE_RECEIPT_CA,l_rec_customertype.acct_mask_code) THEN 
		ERROR kandoomsg2("A",7031,"") #7031 "Warning: Invalid numbering - Review Menu GZD"
	END IF 

	IF l_rec_bank.bank_code IS NULL THEN 
		DECLARE bc1_bank CURSOR FOR 
		SELECT * FROM bank 
		WHERE currency_code = l_customer.currency_code 
		AND acct_code = glob_rec_arparms.cash_acct_code 
		AND cmpy_code = p_company_cmpy_code 
		OPEN bc1_bank 
		FETCH bc1_bank INTO l_rec_bank.* 

		IF status = NOTFOUND THEN 
			DECLARE bc2_bank CURSOR FOR 
			SELECT * FROM bank 
			WHERE currency_code = l_customer.currency_code 
			AND cmpy_code = p_company_cmpy_code 
			OPEN bc2_bank 
			FETCH bc2_bank INTO l_rec_bank.* 
		END IF 

		LET l_bank_amt = 0 
		LET glob_rec_cashreceipt.bank_currency_code = NULL 

	END IF 

	LET glob_rec_cashreceipt.currency_code = trim(l_customer.currency_code) 

	IF glob_rec_cashreceipt.cash_amt > 0 THEN 
		IF l_customer.currency_code = l_rec_glparms.base_currency_code THEN 
			LET l_bank_amt = glob_rec_cashreceipt.cash_amt 
			LET glob_rec_cashreceipt.conv_qty = 1 
		ELSE 
			IF l_rec_bank.currency_code = l_customer.currency_code THEN 
				LET l_bank_amt = glob_rec_cashreceipt.cash_amt 
			ELSE 
				IF glob_rec_cashreceipt.conv_qty > 0 THEN 
					LET l_bank_amt = glob_rec_cashreceipt.cash_amt / glob_rec_cashreceipt.conv_qty 
				END IF 
			END IF 
		END IF 
	END IF 

	SELECT * INTO l_rec_bank.* FROM bank 
	WHERE cmpy_code = p_company_cmpy_code 
	AND bank_code = l_rec_bank.bank_code 
	IF status = NOTFOUND THEN 
		ERROR kandoomsg2("A",9132,"") #9132" Bank Account Not Found - Try Window "
		RETURN false 
	END IF 

	IF l_rec_bank.currency_code != l_customer.currency_code THEN 
		IF l_rec_bank.currency_code != l_rec_glparms.base_currency_code THEN 
			ERROR kandoomsg2("A",9133,"") #9133 Banking IS permitted INTO cust OR base curr bankac
			RETURN false 
		END IF 
	END IF 
	
	LET glob_rec_cashreceipt.bank_currency_code = trim(l_rec_bank.currency_code) 
	LET glob_rec_cashreceipt.cash_acct_code = trim(l_rec_bank.acct_code) 

	IF glob_rec_cashreceipt.order_num IS NOT NULL	AND l_company.module_text[23] = "W" THEN 
		SELECT unique 1 FROM ordhead 
		WHERE cmpy_code = p_company_cmpy_code 
		AND order_num = glob_rec_cashreceipt.order_num 
		IF status = NOTFOUND THEN 
			ERROR kandoomsg2("A",9517,"") #9517 Order NOT found.
			RETURN false 
		END IF 
	END IF 

	IF glob_rec_cashreceipt.cash_type_ind IS NULL THEN 
		ERROR kandoomsg2("U",9102,"") #9102 Value must be entered.
		RETURN false 
	END IF 

	IF glob_rec_cashreceipt.cash_type_ind NOT matches "[CPQO]" THEN #CONSTANT PAYMENT_TYPE_CASH_C, PAYMENT_TYPE_CHEQUE_Q,	PAYMENT_TYPE_CC_P,  PAYMENT_TYPE_ORDER_O
		ERROR kandoomsg2("U",9112,"Payment Type") #9112 Invalid Payment Type.
		RETURN false 
	END IF 
	LET l_reference_text = kandooword("cashreceipt.cash_type_ind", glob_rec_cashreceipt.cash_type_ind) 

	IF glob_rec_cashreceipt.cash_type_ind = PAYMENT_TYPE_CHEQUE_Q THEN 
		LET glob_rec_cashreceipt.chq_date = today 
	ELSE 
		LET glob_rec_cashreceipt.chq_date = NULL 
	END IF 

	IF glob_rec_cashreceipt.cash_date IS NULL THEN 
		LET glob_rec_cashreceipt.cash_date = today 
	END IF 

	CALL db_period_what_period(p_company_cmpy_code CLIPPED, glob_rec_cashreceipt.cash_date) 
	RETURNING glob_rec_cashreceipt.year_num, glob_rec_cashreceipt.period_num 

	IF p_inv_num = 0 THEN 
		CALL get_conv_rate(
			p_company_cmpy_code,
			l_customer.currency_code, 
			glob_rec_cashreceipt.cash_date,
			CASH_EXCHANGE_SELL) 
		RETURNING	glob_rec_cashreceipt.conv_qty 
		
		IF glob_rec_cashreceipt.conv_qty IS NULL THEN 
			LET glob_rec_cashreceipt.conv_qty = 0 
		END IF 
	ELSE 
		IF l_recalc_ind = 'Y' THEN 
			IF l_disc_taken_ind = "N" THEN 
				LET l_disc_amt = 0 
			END IF 
		ELSE 
			IF glob_rec_cashreceipt.cash_date <= l_invoicehead.disc_date THEN 
				LET l_disc_amt = l_invoicehead.disc_amt 
			ELSE 
				LET l_disc_amt = 0 
			END IF 
		END IF 

		LET glob_rec_cashreceipt.cash_amt = l_invoicehead.total_amt 
			- l_invoicehead.paid_amt 
			- l_disc_amt 
	END IF 

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
		RETURNING glob_rec_cashreceipt.year_num, glob_rec_cashreceipt.period_num 
	END IF 

	IF glob_rec_cashreceipt.cash_amt IS NULL THEN 
		ERROR kandoomsg2("A",9131,"") #9131 " Must enter a value in the received amount"
		RETURN false 
	END IF 

	IF glob_rec_cashreceipt.cash_amt < 0 THEN 
		IF NOT kandooDialog("A",8012,"",TRUE,"Negative Cash Receipt","WARNING") THEN
		--IF kandoomsg("A",8012,"") != "Y" THEN #8012 Warning: Negative Cash Receipt authorized.
			RETURN false 
		END IF 
	END IF 

	IF l_customer.currency_code = l_rec_glparms.base_currency_code THEN 
		LET l_bank_amt = glob_rec_cashreceipt.cash_amt 
		LET glob_rec_cashreceipt.conv_qty = 1 
	ELSE 
		IF l_rec_bank.currency_code = l_customer.currency_code THEN 
			LET l_bank_amt = glob_rec_cashreceipt.cash_amt 
		ELSE 
			IF glob_rec_cashreceipt.conv_qty > 0 THEN 
				LET l_bank_amt = glob_rec_cashreceipt.cash_amt / glob_rec_cashreceipt.conv_qty 
			END IF 
		END IF 
	END IF 
	
	CASE 
		WHEN l_bank_amt IS NULL 
			LET l_bank_amt = 0 
		WHEN l_bank_amt = 0 
			CALL get_conv_rate(
				p_company_cmpy_code,
				l_customer.currency_code, 
				glob_rec_cashreceipt.cash_date,
				CASH_EXCHANGE_SELL) 
			RETURNING 
				glob_rec_cashreceipt.conv_qty
				 
			LET l_bank_amt = glob_rec_cashreceipt.cash_amt / glob_rec_cashreceipt.conv_qty 
		WHEN glob_rec_cashreceipt.cash_amt != 0 
			AND l_bank_amt != 0 
			LET glob_rec_cashreceipt.conv_qty = glob_rec_cashreceipt.cash_amt / l_bank_amt 
		WHEN glob_rec_cashreceipt.cash_amt = 0 
			AND l_bank_amt != 0 
			LET glob_rec_cashreceipt.cash_amt = l_bank_amt 	* glob_rec_cashreceipt.conv_qty 
	END CASE 

	IF trim(l_rec_bank.currency_code) = trim(l_rec_glparms.base_currency_code) THEN 
		IF glob_rec_cashreceipt.cash_amt != 0 AND l_bank_amt != 0 THEN 
			LET glob_rec_cashreceipt.conv_qty = glob_rec_cashreceipt.cash_amt / l_bank_amt 
		END IF 
	END IF 

	IF glob_rec_cashreceipt.conv_qty IS NULL THEN 
		CALL get_conv_rate(
			p_company_cmpy_code,
			l_customer.currency_code,
			glob_rec_cashreceipt.cash_date,
			CASH_EXCHANGE_SELL) 
		RETURNING 
			glob_rec_cashreceipt.conv_qty 
		
		ERROR kandoomsg2("A",9117,"") #9117" Exchange rate must have a value"
		RETURN false 
	END IF 

	IF glob_rec_cashreceipt.conv_qty <= 0 THEN 
		ERROR kandoomsg2("A",9118,"") #9118" Exchange Rate must be greater than zero"
		RETURN false 
	ELSE 
		IF l_rec_bank.currency_code = l_rec_glparms.base_currency_code THEN 
			LET l_bank_amt = glob_rec_cashreceipt.cash_amt / glob_rec_cashreceipt.conv_qty 
		END IF 
	END IF 

	IF not(int_flag OR quit_flag) THEN 
		SELECT * INTO l_rec_bank.* FROM bank 
		WHERE cmpy_code = p_company_cmpy_code 
		AND bank_code = l_rec_bank.bank_code 

		IF status = NOTFOUND THEN 
			ERROR kandoomsg2("A",9132,"") #9132" Bank Account Not Found - Try Window "
			RETURN false 
		END IF 

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
			RETURN false 
		END IF 

		IF glob_rec_cashreceipt.order_num IS NOT NULL 
		AND l_company.module_text[23] = "W" THEN 
			SELECT unique 1 FROM ordhead 
			WHERE cmpy_code = trim(p_company_cmpy_code) 
			AND order_num = glob_rec_cashreceipt.order_num 
			IF status = NOTFOUND THEN 
				ERROR kandoomsg2("A",9517,"") #9517 Order NOT found.
				RETURN false 
			END IF 
		END IF 

		IF glob_rec_cashreceipt.cash_type_ind IS NULL THEN 
			ERROR kandoomsg2("U",9102,"") #9102 Value must be entered
			RETURN false 
		END IF 

		IF glob_rec_cashreceipt.cash_type_ind = PAYMENT_TYPE_CHEQUE_Q THEN 
			IF NOT banking(glob_rec_cashreceipt.*,l_customer.name_text) THEN 
				RETURN false 
			END IF 
		END IF 
		IF glob_rec_cashreceipt.cash_type_ind = PAYMENT_TYPE_CC_P THEN 
			IF NOT cards(glob_rec_cashreceipt.*,l_customer.name_text) THEN 
				RETURN false 
			END IF 
		END IF 
		LET l_poss_disc_amt = l_disc_amt 
	END IF 

	IF not(int_flag OR quit_flag) THEN 

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
			LET glob_rec_cashreceipt.cash_num = next_trans_num(
			p_company_cmpy_code,TRAN_TYPE_RECEIPT_CA,l_rec_customertype.acct_mask_code) 
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

			INSERT INTO cashreceipt VALUES (glob_rec_cashreceipt.*) 

			LET l_err_message =" A31 - Customer Table Update" 

			DECLARE bc_customer CURSOR FOR 
			SELECT * FROM customer 
			WHERE cmpy_code = p_company_cmpy_code 
			AND cust_code = glob_rec_cashreceipt.cust_code 
			FOR UPDATE 
			OPEN bc_customer 
			FETCH bc_customer INTO l_customer.* 

			LET l_customer.bal_amt = l_customer.bal_amt	- glob_rec_cashreceipt.cash_amt 
			LET l_customer.curr_amt = l_customer.curr_amt	- glob_rec_cashreceipt.cash_amt 
			LET l_customer.last_pay_date = glob_rec_cashreceipt.cash_date 
			LET l_customer.next_seq_num = l_customer.next_seq_num + 1 
			LET l_customer.cred_bal_amt = l_customer.cred_limit_amt	- l_customer.bal_amt 
			IF year(glob_rec_cashreceipt.cash_date) >	year(l_customer.last_pay_date) THEN 
				LET l_customer.ytdp_amt = 0 
			END IF 

			LET l_customer.ytdp_amt = l_customer.ytdp_amt	+ glob_rec_cashreceipt.cash_amt 
			LET l_customer.mtdp_amt = l_customer.mtdp_amt	+ glob_rec_cashreceipt.cash_amt 

			UPDATE customer SET 
				bal_amt = l_customer.bal_amt, 
				last_pay_date = l_customer.last_pay_date, 
				curr_amt = l_customer.curr_amt, 
				next_seq_num = l_customer.next_seq_num, 
				cred_bal_amt = l_customer.cred_bal_amt, 
				ytdp_amt = l_customer.ytdp_amt, 
				mtdp_amt = l_customer.mtdp_amt 
			WHERE cmpy_code = p_company_cmpy_code 
			AND cust_code = glob_rec_cashreceipt.cust_code 

			LET l_err_message = "A32 - AR Audit Row Insert" 
			LET l_rec_araudit.cmpy_code = p_company_cmpy_code 
			LET l_rec_araudit.tran_date = glob_rec_cashreceipt.cash_date 
			LET l_rec_araudit.cust_code = glob_rec_cashreceipt.cust_code 
			LET l_rec_araudit.seq_num = l_customer.next_seq_num 
			LET l_rec_araudit.tran_type_ind = TRAN_TYPE_RECEIPT_CA 
			LET l_rec_araudit.source_num = glob_rec_cashreceipt.cash_num 
			LET l_rec_araudit.tran_text = "Cash Receipt" 
			LET l_rec_araudit.tran_amt = 0 - glob_rec_cashreceipt.cash_amt 
			LET l_rec_araudit.entry_code = p_kandoouser_sign_on_code 
			LET l_rec_araudit.year_num = glob_rec_cashreceipt.year_num 
			LET l_rec_araudit.period_num = glob_rec_cashreceipt.period_num 
			LET l_rec_araudit.bal_amt = l_customer.bal_amt 
			LET l_rec_araudit.currency_code = l_customer.currency_code 
			LET l_rec_araudit.conv_qty = glob_rec_cashreceipt.conv_qty 
			LET l_rec_araudit.entry_date = today 
			INSERT INTO araudit VALUES (l_rec_araudit.*) 

		COMMIT WORK 
		WHENEVER ERROR stop 
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

		IF p_inv_num = 0 THEN 
			DISPLAY "successfull addition of receipt number ",glob_rec_cashreceipt.cash_num #1024 successfull addition of receipt number 12210012 
			SLEEP 1 
			CALL auto_cash_apply(
				p_company_cmpy_code,
				p_kandoouser_sign_on_code,
				glob_rec_cashreceipt.cash_num,
				"1=1") 
		ELSE 
			LET l_disc_amt = l_poss_disc_amt 
			LET l_appl_amt = glob_rec_cashreceipt.cash_amt 
			
			IF ( l_invoicehead.total_amt - l_invoicehead.paid_amt )	> ( l_appl_amt + l_disc_amt ) THEN 
				LET l_disc_amt = 0 
			ELSE 
				LET l_appl_amt = l_invoicehead.total_amt - l_invoicehead.paid_amt	- l_disc_amt 
			END IF 
			
			IF receipt_apply(
				p_company_cmpy_code,
				p_kandoouser_sign_on_code,
				glob_rec_cashreceipt.cash_num, 
				p_inv_num, 
				l_appl_amt, 
				l_disc_amt) THEN 
			END IF 
			#            EXIT WHILE
		END IF 
	END IF 
	
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		#         EXIT WHILE
	END IF 
	RETURN glob_rec_cashreceipt.cash_num 
END FUNCTION #enter_cash_blind() 
##############################################################
# END FUNCTION enter_cash_blind(p_company_cmpy_code,p_kandoouser_sign_on_code,p_inv_num,p_apply_ind,p_cash_type_ind)
##############################################################


#################################################################################
# FUNCTION banking(p_rec_cashreceipt,p_name_text)
#
#
#################################################################################
FUNCTION banking(p_rec_cashreceipt,p_name_text) 
	DEFINE p_rec_cashreceipt RECORD LIKE cashreceipt.* 
	DEFINE p_name_text LIKE customer.name_text 

	OPEN WINDOW A151 with FORM "A151" 
	CALL windecoration_a("A151") 

	ERROR kandoomsg2("U",1020,"Cheque") #1020 Enter Cheque Details; OK TO Continue.
	LET p_rec_cashreceipt.drawer_text = p_name_text 

	INPUT BY NAME 
		p_rec_cashreceipt.bank_text, 
		p_rec_cashreceipt.branch_text, 
		p_rec_cashreceipt.drawer_text, 
		p_rec_cashreceipt.cheque_text, 
		p_rec_cashreceipt.chq_date WITHOUT DEFAULTS 


		BEFORE INPUT 
			CALL publish_toolbar("kandoo","A31a","inp-cashreceipt-2") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER FIELD chq_date 
			IF p_rec_cashreceipt.chq_date > today 
			OR p_rec_cashreceipt.chq_date < (today - 30) THEN 

				IF kandooDialog("A",8017,"",TRUE,"Cheque Date","QUESTION") THEN
					NEXT FIELD chq_date 
				END IF 
			END IF 


	END INPUT 

	CLOSE WINDOW A151 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		LET glob_rec_cashreceipt.* = p_rec_cashreceipt.* 
		RETURN true 
	END IF 
END FUNCTION 
#################################################################################
# END FUNCTION banking(p_rec_cashreceipt,p_name_text)
#################################################################################


#################################################################################
# FUNCTION cards(p_rec_cashreceipt,p_name_text)
#
#
#################################################################################
FUNCTION cards(p_rec_cashreceipt,p_name_text) 
	DEFINE p_name_text LIKE customer.name_text 
	DEFINE p_rec_cashreceipt RECORD LIKE cashreceipt.* 

	DEFINE l_card_type CHAR(1) 
	DEFINE l_month_exp SMALLINT 
	DEFINE l_year_exp SMALLINT 

	OPEN WINDOW A632 with FORM "A632" 
	CALL windecoration_a("A632") 

	LET l_month_exp = NULL 
	LET l_year_exp = NULL 

	MESSAGE kandoomsg2("U",1020,"Credit Card") #1020 Enter Credit Card Details; OK TO Continue
	LET p_rec_cashreceipt.drawer_text = p_name_text 

	INPUT 
		l_card_type, 
		p_rec_cashreceipt.bank_text, 
		p_rec_cashreceipt.branch_text, 
		p_rec_cashreceipt.drawer_text, 
		l_month_exp, 
		l_year_exp WITHOUT DEFAULTS 
	FROM 
		card_type, 
		bank_text, 
		branch_text, 
		drawer_text, 
		month_exp, 
		year_exp 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","A31a","inp-cashreceipt-3") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER FIELD card_type 
			IF l_card_type = "V" THEN 
				LET p_rec_cashreceipt.bank_text = "VISA" 
				NEXT FIELD branch_text 
			END IF 
			IF l_card_type = "M" THEN 
				LET p_rec_cashreceipt.bank_text = "MASTERCARD" 
				NEXT FIELD branch_text 
			END IF 
			IF l_card_type = "B" THEN 
				LET p_rec_cashreceipt.bank_text = "BANKCARD" 
			END IF 
			IF l_card_type = "A" THEN 
				LET p_rec_cashreceipt.bank_text = "AMEX" 
				NEXT FIELD branch_text 
			END IF 
			IF l_card_type = "D" THEN 
				LET p_rec_cashreceipt.bank_text = "DINERS CLUB" 
				NEXT FIELD branch_text 
			END IF 

		AFTER FIELD branch_text 
			IF p_rec_cashreceipt.branch_text IS NOT NULL THEN 
				IF verify_creditcard_number(p_rec_cashreceipt.branch_text) THEN 
					ERROR kandoomsg2("K",6000,"") #6000 Invalid Credit Card Number Entered.
				END IF 
			END IF 

	END INPUT 

	CLOSE WINDOW A632 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		LET p_rec_cashreceipt.card_exp_date = l_month_exp USING "&&", l_year_exp USING "&&" 
		LET glob_rec_cashreceipt.* = p_rec_cashreceipt.* 
		RETURN true 
	END IF 

END FUNCTION 
#################################################################################
# END FUNCTION cards(p_rec_cashreceipt,p_name_text)
#################################################################################


#################################################################################
# FUNCTION verify_creditcard_number(p_card_num)
#
#
#################################################################################
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
#################################################################################
# END FUNCTION verify_creditcard_number(p_card_num)
#################################################################################