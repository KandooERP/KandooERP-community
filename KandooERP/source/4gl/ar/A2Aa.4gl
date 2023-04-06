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
GLOBALS "../ar/A2A_GLOBALS.4gl" 

######################################################################################
# FUNCTION A2A_create_invoice(p_company_cmpy_code,p_kandoouser_sign_on_code,p_invoicehead,p_rec_invoicedetl)
#
# \brief module A2Aa - AR Adjustments
#                 Creates an invoice IF adjustment IS positive
#                 Creates a credit IF adjustment IS negative
######################################################################################
FUNCTION A2A_create_invoice(p_company_cmpy_code,p_kandoouser_sign_on_code,p_invoicehead,p_rec_invoicedetl) 
	DEFINE p_company_cmpy_code LIKE company.cmpy_code
	DEFINE p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code
	DEFINE p_invoicehead RECORD LIKE invoicehead.*
	DEFINE p_rec_invoicedetl RECORD LIKE invoicedetl.*
	
	DEFINE l_rec_araudit RECORD LIKE araudit.*
	DEFINE l_customer RECORD LIKE customer.*
	DEFINE l_rec_tax RECORD LIKE tax.*
	DEFINE l_rec_term RECORD LIKE term.*
	DEFINE l_cust_code LIKE customer.corp_cust_code
	DEFINE l_err_message CHAR(30) 
	DEFINE l_err_continue CHAR(1) 

	GOTO bypass 
	LABEL recovery: 
	LET l_err_continue = error_recover(l_err_message, status) 
	IF l_err_continue != "Y" THEN 
		EXIT PROGRAM 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	BEGIN WORK 
	
		SELECT * INTO l_customer.* FROM customer 
		WHERE cmpy_code = p_company_cmpy_code 
		AND cust_code = p_invoicehead.cust_code 
	
		IF l_customer.corp_cust_code IS NOT NULL AND	l_customer.corp_cust_ind = "1" THEN 
			LET l_cust_code = l_customer.corp_cust_code 
			LET p_invoicehead.org_cust_code = p_invoicehead.cust_code 
		ELSE 
			LET l_cust_code = l_customer.cust_code 
			LET p_invoicehead.org_cust_code = NULL 
		END IF 
		
		SELECT * INTO l_rec_tax.* FROM tax 
		WHERE tax_code = p_invoicehead.tax_code 
		AND cmpy_code = p_company_cmpy_code 
		
		DECLARE c1_customer CURSOR FOR		
		SELECT * FROM customer 
		WHERE cmpy_code = p_company_cmpy_code 
		AND cust_code = l_cust_code 
		FOR UPDATE 
		OPEN c1_customer 
		FETCH c1_customer INTO l_customer.* 

		LET p_invoicehead.cust_code = l_cust_code 

		LET p_invoicehead.cmpy_code = p_company_cmpy_code 
		LET p_invoicehead.entry_code = p_kandoouser_sign_on_code 
		LET p_invoicehead.entry_date = today 
		LET p_invoicehead.currency_code = l_customer.currency_code 
		LET p_invoicehead.name_text = l_customer.name_text 
		LET p_invoicehead.ship_code = l_customer.cust_code 
		LET p_invoicehead.addr1_text = l_customer.addr1_text 
		LET p_invoicehead.addr2_text = l_customer.addr2_text 
		LET p_invoicehead.city_text = l_customer.city_text 
		LET p_invoicehead.state_code = l_customer.state_code 
		LET p_invoicehead.post_code = l_customer.post_code 
		LET p_invoicehead.country_code = l_customer.country_code --@db-patch_2020_10_04--
		LET p_invoicehead.contact_text = l_customer.contact_text 
		LET p_invoicehead.tele_text = l_customer.tele_text 
		LET p_invoicehead.mobile_phone = l_customer.mobile_phone
		LET p_invoicehead.email = l_customer.email				
		LET p_invoicehead.total_amt = 0 
		LET p_invoicehead.hand_amt = 0 
		LET p_invoicehead.hand_tax_amt = 0 
		LET p_invoicehead.freight_amt = 0 
		LET p_invoicehead.freight_tax_amt = 0 
		LET p_invoicehead.tax_amt = 0 
		LET p_invoicehead.tax_per = l_rec_tax.tax_per 
		LET p_invoicehead.disc_amt = 0 
		LET p_invoicehead.paid_amt = 0 
		LET p_invoicehead.paid_date = NULL 
		LET p_invoicehead.disc_taken_amt = 0 
		LET p_invoicehead.disc_per = 0 
		LET p_invoicehead.cost_amt = 0 
		LET p_invoicehead.acct_override_code = p_rec_invoicedetl.line_acct_code 
		LET p_invoicehead.conv_qty = get_conv_rate(
			p_company_cmpy_code, 
			p_invoicehead.currency_code, 
			p_invoicehead.inv_date,
			CASH_EXCHANGE_SELL) 
		
		LET p_rec_invoicedetl.tax_code = p_invoicehead.tax_code 

		IF p_invoicehead.term_code IS NOT NULL THEN 
			CALL db_term_get_rec(UI_OFF,p_invoicehead.term_code) RETURNING l_rec_term.*	

			CALL get_due_and_discount_date(l_rec_term.*,p_invoicehead.inv_date)	
				RETURNING p_invoicehead.due_date,	p_invoicehead.disc_date 

			LET p_invoicehead.disc_per = l_rec_term.disc_per 
		END IF 

		LET p_invoicehead.ship_date = p_invoicehead.inv_date 
		LET p_invoicehead.prepaid_flag = "P" 
		LET p_invoicehead.tax_amt = p_rec_invoicedetl.unit_tax_amt 
		LET p_invoicehead.goods_amt = p_rec_invoicedetl.unit_sale_amt 
		LET p_invoicehead.total_amt = p_rec_invoicedetl.unit_sale_amt	+ p_rec_invoicedetl.unit_tax_amt 
		LET p_invoicehead.seq_num = 0 
		LET p_invoicehead.on_state_flag = "N" 
		LET p_invoicehead.posted_flag = "N" 
		LET p_invoicehead.inv_ind = "4" 
		LET p_invoicehead.printed_num = 1 
		LET p_invoicehead.line_num = 1 
		LET p_rec_invoicedetl.cmpy_code = p_company_cmpy_code 
		LET p_rec_invoicedetl.ship_qty = 1 
		LET p_rec_invoicedetl.sold_qty = p_rec_invoicedetl.ship_qty 
		LET p_rec_invoicedetl.line_num = 1 
		LET p_rec_invoicedetl.level_code = 1 
		LET p_rec_invoicedetl.line_total_amt = p_rec_invoicedetl.unit_tax_amt	+ p_rec_invoicedetl.unit_sale_amt 
		LET p_rec_invoicedetl.ext_sale_amt = p_rec_invoicedetl.unit_sale_amt 
		LET p_rec_invoicedetl.ext_tax_amt = p_rec_invoicedetl.unit_tax_amt 
		LET p_rec_invoicedetl.cust_code = p_invoicehead.cust_code 
		LET p_rec_invoicedetl.ord_qty = 1 
		LET p_rec_invoicedetl.back_qty = 0 
		LET p_rec_invoicedetl.prev_qty = 0 
		LET p_rec_invoicedetl.ser_flag = "N" 
		LET p_rec_invoicedetl.ser_qty = 0 
		LET p_rec_invoicedetl.unit_cost_amt = 0 
		LET p_rec_invoicedetl.ext_cost_amt = 0 
		LET p_rec_invoicedetl.disc_amt = 0 
		
		INITIALIZE l_rec_araudit.* TO NULL
		 
		LET p_invoicehead.inv_num =	
			next_trans_num(p_company_cmpy_code,TRAN_TYPE_INVOICE_IN,p_invoicehead.acct_override_code) 

		IF p_invoicehead.inv_num < 0 THEN 
			LET l_err_message = "A2A - Next invoice number UPDATE" 
			LET status = p_invoicehead.inv_num 
			GOTO recovery 
		END IF 

		LET l_err_message = "A21 - Customer Update Inv" 
		LET l_customer.next_seq_num = l_customer.next_seq_num + 1 
		LET l_customer.bal_amt = l_customer.bal_amt + p_invoicehead.total_amt 
		LET l_customer.curr_amt = l_customer.curr_amt	+ p_invoicehead.total_amt 
		LET l_rec_araudit.cmpy_code = p_company_cmpy_code 
		LET l_rec_araudit.tran_date = p_invoicehead.inv_date 
		LET l_rec_araudit.cust_code = p_invoicehead.cust_code 
		LET l_rec_araudit.seq_num = l_customer.next_seq_num 
		LET l_rec_araudit.tran_type_ind = TRAN_TYPE_INVOICE_IN 
		LET l_rec_araudit.source_num = p_invoicehead.inv_num 
		LET l_rec_araudit.tran_text = "Adjustment" 
		LET l_rec_araudit.tran_amt = p_invoicehead.total_amt 
		LET l_rec_araudit.entry_code = p_kandoouser_sign_on_code 
		LET l_rec_araudit.sales_code = p_invoicehead.sale_code 
		LET l_rec_araudit.year_num = p_invoicehead.year_num 
		LET l_rec_araudit.period_num = p_invoicehead.period_num 
		LET l_rec_araudit.bal_amt = l_customer.bal_amt 
		LET l_rec_araudit.currency_code = l_customer.currency_code 
		LET l_rec_araudit.conv_qty = p_invoicehead.conv_qty 
		LET l_rec_araudit.entry_date = today 
		LET l_err_message = "A21 - Unable TO add TO AR log table "
		 
		# INSERT INTO araudit
		INSERT INTO araudit VALUES (l_rec_araudit.*) 

		IF l_customer.bal_amt > l_customer.highest_bal_amt THEN 
			LET l_customer.highest_bal_amt = l_customer.bal_amt 
		END IF 
		
		LET l_customer.cred_bal_amt = l_customer.cred_limit_amt	- l_customer.bal_amt 

		IF year(p_invoicehead.inv_date) > year(l_customer.last_inv_date) THEN 
			LET l_customer.ytds_amt = 0 
		END IF 
		
		LET l_customer.ytds_amt = l_customer.ytds_amt	+ p_invoicehead.total_amt 

		IF (month(p_invoicehead.inv_date)	> month(l_customer.last_inv_date)	
		OR year(p_invoicehead.inv_date)	> year(l_customer.last_inv_date)) THEN 
			LET l_customer.mtds_amt = 0 
		END IF 
		
		LET l_customer.mtds_amt = l_customer.mtds_amt	+ p_invoicehead.total_amt 
		LET l_customer.last_inv_date = p_invoicehead.inv_date 
		LET l_err_message = "A2A - Custmain actual UPDATE "
		
		# UPDATE customer -------------------------------------- 
		UPDATE customer	SET 
			next_seq_num = l_customer.next_seq_num, 
			bal_amt = l_customer.bal_amt, 
			curr_amt = l_customer.curr_amt, 
			highest_bal_amt = l_customer.highest_bal_amt, 
			cred_bal_amt = l_customer.cred_bal_amt, 
			last_inv_date = l_customer.last_inv_date, 
			ytds_amt = l_customer.ytds_amt, 
			mtds_amt = l_customer.mtds_amt 
		WHERE CURRENT OF c1_customer
		 
		LET p_rec_invoicedetl.inv_num = p_invoicehead.inv_num 

		#INSERT invoicehead Record
		IF db_invoicehead_rec_validation(UI_ON,MODE_INSERT,p_invoicehead.*) THEN
			INSERT INTO invoicehead VALUES (p_invoicehead.*)
		ELSE
			DISPLAY p_invoicehead.*
			CALL fgl_winmessage("Error","Could not insert new invoicehead record","ERROR")
		END IF 

		#INSERT invoiceDetl Record
		IF db_invoicedetl_rec_validation(UI_ON,MODE_INSERT,p_rec_invoicedetl.*) THEN
			INSERT INTO invoicedetl VALUES (p_rec_invoicedetl.*)		
		ELSE
			DISPLAY p_rec_invoicedetl.*
			CALL fgl_winmessage("Error","Could not insert new invoiceDetl record","ERROR")
		END IF

	COMMIT WORK 

	WHENEVER ERROR stop 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

	RETURN p_invoicehead.inv_num 
END FUNCTION 
######################################################################################
# END FUNCTION A2A_create_invoice(p_company_cmpy_code,p_kandoouser_sign_on_code,p_invoicehead,p_rec_invoicedetl)
######################################################################################


######################################################################################
# FUNCTION create_credit(p_company_cmpy_code,p_kandoouser_sign_on_code,p_invoicehead,p_rec_invoicedetl,p_cred_reason)
#
#
######################################################################################
FUNCTION create_credit(p_company_cmpy_code,p_kandoouser_sign_on_code,p_invoicehead,p_rec_invoicedetl,p_cred_reason) 
	DEFINE p_company_cmpy_code LIKE company.cmpy_code 
	DEFINE p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code 
	DEFINE p_invoicehead RECORD LIKE invoicehead.* 
	DEFINE p_rec_invoicedetl RECORD LIKE invoicedetl.* 
	DEFINE p_cred_reason LIKE arparms.reason_code 

	DEFINE l_rec_araudit RECORD LIKE araudit.* 
	DEFINE l_rec_credithead RECORD LIKE credithead.* 
	DEFINE l_rec_creditdetl RECORD LIKE creditdetl.* 
	DEFINE l_customer RECORD LIKE customer.* 
	DEFINE l_rec_tax RECORD LIKE tax.* 
	DEFINE l_err_message CHAR(30) 
	DEFINE l_err_continue CHAR(1) 
	DEFINE l_cust_code LIKE customer.corp_cust_code 
	DEFINE l_chng_amt LIKE araudit.tran_amt 

	GOTO bypass 
	LABEL recovery: 
	LET l_err_continue = error_recover(l_err_message, status) 
	IF l_err_continue != "Y" THEN 
		EXIT PROGRAM 
	END IF
	 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery
	 
	BEGIN WORK 
		SELECT * INTO l_customer.* FROM customer 
		WHERE cmpy_code = p_company_cmpy_code 
		AND cust_code = p_invoicehead.cust_code 
		
		IF l_customer.corp_cust_code IS NOT NULL	AND l_customer.corp_cust_ind = "1" THEN 
			LET l_cust_code = l_customer.corp_cust_code 
			LET l_rec_credithead.org_cust_code = p_invoicehead.cust_code 
		ELSE 
			LET l_cust_code = l_customer.cust_code 
			LET l_rec_credithead.org_cust_code = NULL 
		END IF 
		
		SELECT * INTO l_rec_tax.* FROM tax 
		WHERE tax_code = p_invoicehead.tax_code 
		AND cmpy_code = p_company_cmpy_code
		 
		DECLARE c2_customer CURSOR FOR 
		SELECT * FROM customer 
		WHERE cmpy_code = p_company_cmpy_code 
		AND cust_code = l_cust_code 
		FOR UPDATE 
		OPEN c2_customer 
		FETCH c2_customer INTO l_customer.* 

		LET p_invoicehead.cust_code = l_cust_code 
		LET l_rec_credithead.cmpy_code = p_company_cmpy_code 
		LET l_rec_credithead.cust_code = p_invoicehead.cust_code 
		LET l_rec_credithead.entry_code = p_kandoouser_sign_on_code 
		LET l_rec_credithead.entry_date = today 
		LET l_rec_credithead.cred_date = p_invoicehead.inv_date 
		LET l_rec_credithead.sale_code = p_invoicehead.sale_code 
		LET l_rec_credithead.tax_code = p_invoicehead.tax_code 
		LET l_rec_credithead.tax_per = l_rec_tax.tax_per 
		LET l_rec_credithead.goods_amt = 0 - p_rec_invoicedetl.unit_sale_amt 
		LET l_rec_credithead.hand_amt = 0 
		LET l_rec_credithead.hand_tax_amt = 0 
		LET l_rec_credithead.freight_amt = 0 
		LET l_rec_credithead.freight_tax_amt = 0 
		LET l_rec_credithead.tax_amt = 0 - p_rec_invoicedetl.unit_tax_amt 
		LET l_rec_credithead.total_amt = l_rec_credithead.goods_amt	+ l_rec_credithead.tax_amt 
		LET l_rec_credithead.cost_amt = 0 
		LET l_rec_credithead.appl_amt = 0 
		LET l_rec_credithead.disc_amt = 0 
		LET l_rec_credithead.year_num = p_invoicehead.year_num 
		LET l_rec_credithead.period_num = p_invoicehead.period_num 
		LET l_rec_credithead.on_state_flag = "N" 
		LET l_rec_credithead.posted_flag = "N" 
		LET l_rec_credithead.next_num = 0 
		LET l_rec_credithead.line_num = 1 
		LET l_rec_credithead.printed_num = 0 
		LET l_rec_credithead.com1_text = p_invoicehead.com1_text 
		LET l_rec_credithead.com2_text = p_invoicehead.com2_text 
		LET l_rec_credithead.rev_date = today 
		LET l_rec_credithead.rev_num = 0 
		LET l_rec_credithead.currency_code = l_customer.currency_code 
		LET l_rec_credithead.cred_ind = "4" 
		LET l_rec_credithead.acct_override_code = p_rec_invoicedetl.line_acct_code 
		LET l_rec_credithead.reason_code = p_cred_reason 
		LET l_rec_credithead.conv_qty = get_conv_rate(
			p_company_cmpy_code, 
			l_rec_credithead.currency_code, 
			l_rec_credithead.cred_date,
			CASH_EXCHANGE_SELL)
			 
		LET l_rec_creditdetl.cmpy_code = p_company_cmpy_code 
		LET l_rec_creditdetl.cust_code = l_rec_credithead.cust_code 
		LET l_rec_creditdetl.line_num = 1 
		LET l_rec_creditdetl.ship_qty = 1 
		LET l_rec_creditdetl.ser_ind = "N" 
		LET l_rec_creditdetl.line_text = p_rec_invoicedetl.line_text 
		LET l_rec_creditdetl.unit_cost_amt = 0 
		LET l_rec_creditdetl.ext_cost_amt = 0 
		LET p_rec_invoicedetl.disc_amt = 0 
		LET l_rec_creditdetl.unit_sales_amt = 0 - p_rec_invoicedetl.unit_sale_amt 
		LET l_rec_creditdetl.ext_sales_amt = 0 - p_rec_invoicedetl.unit_sale_amt 
		LET l_rec_creditdetl.unit_tax_amt = 0 - p_rec_invoicedetl.unit_tax_amt 
		LET l_rec_creditdetl.ext_tax_amt = 0 - p_rec_invoicedetl.unit_tax_amt 
		LET l_rec_creditdetl.line_total_amt = l_rec_credithead.total_amt 
		LET l_rec_creditdetl.seq_num = 1 
		LET l_rec_creditdetl.line_acct_code = p_rec_invoicedetl.line_acct_code 
		LET l_rec_creditdetl.level_code = 1 
		LET l_rec_creditdetl.tax_code = p_rec_invoicedetl.tax_code 
		LET l_rec_creditdetl.reason_code = p_cred_reason 
		
		INITIALIZE l_rec_araudit.* TO NULL
		 
		LET l_rec_credithead.cred_num = 
			next_trans_num(p_company_cmpy_code, TRAN_TYPE_CREDIT_CR, l_rec_credithead.acct_override_code) 
		
		IF l_rec_credithead.cred_num < 0 THEN 
			LET l_err_message = "A2A - Next Credit Number Update" 
			LET status = l_rec_credithead.cred_num 
			GOTO recovery 
		END IF
		 
		LET l_err_message = "A21 - Customer Update Credit" 
		LET l_customer.next_seq_num = l_customer.next_seq_num + 1 
		LET l_customer.bal_amt = l_customer.bal_amt - l_rec_credithead.total_amt 

		LET l_chng_amt = 0 
		LET l_chng_amt = l_chng_amt - l_rec_credithead.total_amt 
		LET l_customer.curr_amt = l_customer.curr_amt - l_rec_credithead.total_amt 
		LET l_rec_araudit.cmpy_code = p_company_cmpy_code 
		LET l_rec_araudit.tran_date = l_rec_credithead.cred_date 
		LET l_rec_araudit.cust_code = l_rec_credithead.cust_code 
		LET l_rec_araudit.seq_num = l_customer.next_seq_num 
		LET l_rec_araudit.tran_type_ind = TRAN_TYPE_CREDIT_CR 
		LET l_rec_araudit.source_num = l_rec_credithead.cred_num 
		LET l_rec_araudit.tran_text = "Adjustment" 
		LET l_rec_araudit.tran_amt = l_chng_amt 
		LET l_rec_araudit.entry_code = p_kandoouser_sign_on_code 
		LET l_rec_araudit.sales_code = l_rec_credithead.sale_code 
		LET l_rec_araudit.year_num = l_rec_credithead.year_num 
		LET l_rec_araudit.period_num = l_rec_credithead.period_num 
		LET l_rec_araudit.bal_amt = l_customer.bal_amt 
		LET l_rec_araudit.currency_code = l_customer.currency_code 
		LET l_rec_araudit.conv_qty = l_rec_credithead.conv_qty 
		LET l_rec_araudit.entry_date = today 
		LET l_err_message = "A21 - Unable TO add TO AR log table " 
		
		INSERT INTO araudit VALUES (l_rec_araudit.*) 
		LET l_customer.cred_bal_amt = l_customer.cred_limit_amt	- l_customer.bal_amt 
		LET l_customer.ytds_amt = l_customer.ytds_amt - l_rec_credithead.total_amt 
		LET l_customer.mtds_amt = l_customer.mtds_amt - l_rec_credithead.total_amt 
		LET l_err_message = "A2A - Customer Update FOR Credit" 
		
		UPDATE customer 
		SET next_seq_num = l_customer.next_seq_num, 
		bal_amt = l_customer.bal_amt, 
		curr_amt = l_customer.curr_amt, 
		cred_bal_amt = l_customer.cred_bal_amt, 
		last_inv_date = l_customer.last_inv_date, 
		ytds_amt = l_customer.ytds_amt, 
		mtds_amt = l_customer.mtds_amt 
		WHERE CURRENT OF c2_customer 
		
		LET l_rec_creditdetl.cred_num = l_rec_credithead.cred_num 
		LET l_err_message = "A21 - Insert INTO Credit line table" 
		
		INSERT INTO creditdetl VALUES (l_rec_creditdetl.*) 
		LET l_err_message = "A21 - Insert INTO Credit header table" 
		INSERT INTO credithead VALUES (l_rec_credithead.*) 
		
	COMMIT WORK 
	
	WHENEVER ERROR stop 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	
	RETURN l_rec_credithead.cred_num 
END FUNCTION 
######################################################################################
# END FUNCTION create_credit(p_company_cmpy_code,p_kandoouser_sign_on_code,p_invoicehead,p_rec_invoicedetl,p_cred_reason)
######################################################################################


######################################################################################
# FUNCTION auto_invoice_pay(p_company_cmpy_code,p_kandoouser_sign_on_code,p_inv_num)
#
#
######################################################################################
FUNCTION auto_invoice_pay(p_company_cmpy_code,p_kandoouser_sign_on_code,p_inv_num) 
	DEFINE p_company_cmpy_code LIKE company.cmpy_code 
	DEFINE p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code 
	DEFINE p_inv_num LIKE invoicehead.inv_num 

	DEFINE l_rec_invoicehead2 RECORD LIKE invoicehead.* 
	DEFINE l_rec_applyinvoice RECORD 
		cust_code LIKE customer.cust_code, 
		tran_date LIKE credithead.cred_date, 
		tran_ind CHAR(2), 
		diff_amt LIKE credithead.total_amt, 
		tran_num LIKE credithead.cred_num 
	END RECORD 
	DEFINE l_remaining FLOAT 
	DEFINE l_disc_amt LIKE invoicehead.disc_amt 
	DEFINE l_message CHAR(30) 
	DEFINE l_err_cnt INTEGER 

	IF db_invoicehead_pk_exists(UI_ON,MODE_SELECT,p_inv_num) THEN
		CALL db_invoicehead_get_rec(UI_ON,p_inv_num) RETURNING  l_rec_invoicehead2.*
	ELSE
		ERROR "Record not found"
	END IF
	
	DECLARE c_applyinvoice CURSOR with HOLD FOR 
	SELECT cust_code,cred_date,TRAN_TYPE_CREDIT_CR,(total_amt - appl_amt),cred_num 
	FROM credithead 
	WHERE cmpy_code = p_company_cmpy_code 
	AND cust_code = l_rec_invoicehead2.cust_code 
	AND total_amt > appl_amt 
	union
	 
	SELECT cust_code,cash_date,"cp",(cash_amt - applied_amt),cash_num 
	FROM cashreceipt 
	WHERE cmpy_code = p_company_cmpy_code 
	AND cust_code = l_rec_invoicehead2.cust_code 
	AND cash_amt > applied_amt 
	ORDER BY 1,2 
	
	LET l_err_cnt = 0 
	
	FOREACH c_applyinvoice INTO l_rec_applyinvoice.* 
		IF l_rec_applyinvoice.tran_ind = "CP" THEN 
			IF l_rec_applyinvoice.diff_amt > 0 THEN 
				LET l_disc_amt = 0 
				LET l_remaining = l_rec_invoicehead2.total_amt	- l_rec_invoicehead2.paid_amt 
				IF l_remaining > l_rec_applyinvoice.diff_amt THEN 
					IF NOT receipt_apply(p_company_cmpy_code,p_kandoouser_sign_on_code,
						l_rec_applyinvoice.tran_num,l_rec_invoicehead2.inv_num, 
						l_rec_applyinvoice.diff_amt,l_disc_amt) THEN 
						LET l_err_cnt = l_err_cnt + 1 
						EXIT FOREACH 
					END IF 
				ELSE 
					IF NOT receipt_apply(p_company_cmpy_code,p_kandoouser_sign_on_code,l_rec_applyinvoice.tran_num, 
					l_rec_invoicehead2.inv_num,l_remaining,	l_disc_amt) THEN 
						LET l_err_cnt = l_err_cnt + 1 
						EXIT FOREACH 
					END IF 
				END IF 
			END IF
			 
		ELSE
		 
			IF l_rec_applyinvoice.diff_amt > 0 THEN 
				LET l_disc_amt = 0 
				LET l_remaining = l_rec_invoicehead2.total_amt - l_rec_invoicehead2.paid_amt 
				IF l_remaining > l_rec_applyinvoice.diff_amt THEN 
					IF NOT write_cred_appl(p_company_cmpy_code,p_kandoouser_sign_on_code,l_rec_applyinvoice.tran_num, 
					l_rec_invoicehead2.inv_num, l_rec_applyinvoice.diff_amt,l_disc_amt) THEN 
						LET l_err_cnt = l_err_cnt + 1 
						EXIT FOREACH 
					END IF 
				ELSE 
					IF NOT write_cred_appl(p_company_cmpy_code,p_kandoouser_sign_on_code,l_rec_applyinvoice.tran_num, 
					l_rec_invoicehead2.inv_num,l_remaining,	l_disc_amt) THEN 
						LET l_err_cnt = l_err_cnt + 1 
						EXIT FOREACH 
					END IF 
				END IF 
			END IF 
		END IF

		IF db_invoicehead_pk_exists(UI_ON,MODE_SELECT,p_inv_num) THEN
			CALL db_invoicehead_get_rec(UI_ON,p_inv_num) RETURNING  l_rec_invoicehead2.*
		END IF		 

		IF l_rec_invoicehead2.total_amt = l_rec_invoicehead2.paid_amt THEN 
			EXIT FOREACH 
		END IF 
	END FOREACH 

	IF l_err_cnt > 0 THEN 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 

END FUNCTION 
######################################################################################
# END FUNCTION auto_invoice_pay(p_company_cmpy_code,p_kandoouser_sign_on_code,p_inv_num)
######################################################################################