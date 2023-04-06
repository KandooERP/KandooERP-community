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

	Source code beautified by beautify.pl on 2020-01-02 10:35:09	$Id: $
}


GLOBALS "../common/glob_GLOBALS.4gl" 

FUNCTION contra_invoice(p_cmpy,p_whom,p_cust_code,p_payment_date,p_year_num,p_period_num,p_acct_code,p_contra_amt) 
	DEFINE p_cmpy LIKE customer.cmpy_code 
	DEFINE p_whom LIKE kandoouser.sign_on_code 
	DEFINE p_cust_code LIKE customer.cust_code 
	DEFINE p_payment_date LIKE cheque.cheq_date 
	DEFINE p_year_num LIKE invoicehead.year_num 
	DEFINE p_period_num LIKE invoicehead.period_num 
	DEFINE p_acct_code LIKE coa.acct_code 
	DEFINE p_contra_amt LIKE invoicehead.total_amt 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_invoicehead RECORD LIKE invoicehead.* 
	DEFINE l_rec_invoicedetl RECORD LIKE invoicedetl.* 
	DEFINE l_rec_araudit RECORD LIKE araudit.* 
	DEFINE l_rec_tax RECORD LIKE tax.* 
	DEFINE l_rec_term RECORD LIKE term.* 
	DEFINE l_err_message CHAR(80) 

	GOTO bypass 
	LABEL ret_status: 
	RETURN -2, status, "", 0 
	LABEL bypass: 
	WHENEVER ERROR GOTO ret_status 

	SELECT unique 1 FROM coa 
	WHERE acct_code = p_acct_code 
	AND cmpy_code = p_cmpy 
	IF status = notfound THEN 
		LET l_err_message = 
		"GL Clearing Account FOR Contra NOT found: " , 
		p_acct_code clipped 
		RETURN -1, status, l_err_message, 0 
	END IF 

	DECLARE c1_customer CURSOR FOR 
	SELECT * FROM customer 
	WHERE cmpy_code = p_cmpy 
	AND cust_code = p_cust_code 
	FOR UPDATE 
	OPEN c1_customer 
	FETCH c1_customer INTO l_rec_customer.* 
	IF status = notfound THEN 
		LET l_err_message = "Contra Customer NOT found: ", p_cust_code clipped 
		RETURN -1, status, l_err_message, 0 
	END IF 

	SELECT * INTO l_rec_tax.* FROM tax 
	WHERE cmpy_code = p_cmpy AND tax_code = l_rec_customer.tax_code
	
	CALL db_term_get_rec(UI_OFF,l_rec_customer.term_code) RETURNING l_rec_term.* 

	INITIALIZE l_rec_invoicehead.* TO NULL 
	
	LET l_rec_invoicehead.inv_num = next_trans_num(p_cmpy, TRAN_TYPE_INVOICE_IN,p_acct_code) 
	
	IF l_rec_invoicehead.inv_num < 0 THEN 
		LET l_err_message = "Contra Invoice - Next invoice number UPDATE" 
		LET status = l_rec_invoicehead.inv_num 
		RETURN -1, status, l_err_message, 0 
	END IF 

	LET l_rec_invoicehead.cmpy_code = p_cmpy 
	LET l_rec_invoicehead.inv_date = p_payment_date 
	LET l_rec_invoicehead.cust_code = p_cust_code 
	LET l_rec_invoicehead.year_num = p_year_num 
	LET l_rec_invoicehead.period_num = p_period_num 
	LET l_rec_invoicehead.tax_code = l_rec_customer.tax_code 
	LET l_rec_invoicehead.term_code = l_rec_customer.term_code 
	LET l_rec_invoicehead.com1_text = "Contra entry on ", today USING "dd/mm/yyyy" 
	#
	# Negative contra payments result in an invoice
	#
	LET l_rec_invoicehead.goods_amt = 0 - p_contra_amt 
	LET l_rec_invoicehead.total_amt = l_rec_invoicehead.goods_amt 
	LET l_rec_invoicehead.hand_amt = 0 
	LET l_rec_invoicehead.tax_amt = 0 
	IF l_rec_customer.corp_cust_code IS NOT NULL AND 
	l_rec_customer.corp_cust_ind = "1" THEN 
		LET p_cust_code = l_rec_customer.corp_cust_code 
		LET l_rec_invoicehead.org_cust_code = 
		l_rec_invoicehead.cust_code 
	ELSE 
		LET p_cust_code = l_rec_customer.cust_code 
		LET l_rec_invoicehead.org_cust_code = NULL 
	END IF 
	LET l_rec_invoicehead.entry_code = p_whom 
	LET l_rec_invoicehead.entry_date = today 
	LET l_rec_invoicehead.sale_code = l_rec_customer.sale_code 
	LET l_rec_invoicehead.currency_code = l_rec_customer.currency_code 
	LET l_rec_invoicehead.invoice_to_ind = l_rec_customer.invoice_to_ind 
	LET l_rec_invoicehead.territory_code = l_rec_customer.territory_code 
	LET l_rec_invoicehead.scheme_amt = 0 
	LET l_rec_invoicehead.line_num = 1 
	LET l_rec_invoicehead.rev_date = l_rec_invoicehead.entry_date 
	LET l_rec_invoicehead.rev_num = 0 
	LET l_rec_invoicehead.name_text = l_rec_customer.name_text 
	LET l_rec_invoicehead.ship_code = l_rec_customer.cust_code 
	LET l_rec_invoicehead.addr1_text = l_rec_customer.addr1_text 
	LET l_rec_invoicehead.addr2_text = l_rec_customer.addr2_text 
	LET l_rec_invoicehead.city_text = l_rec_customer.city_text 
	LET l_rec_invoicehead.state_code = l_rec_customer.state_code 
	LET l_rec_invoicehead.post_code = l_rec_customer.post_code 
	LET l_rec_invoicehead.country_code = l_rec_customer.country_code 
--@db-patch_2020_10_04--	LET l_rec_invoicehead.country_text = l_rec_customer.country_text 
	LET l_rec_invoicehead.contact_text = l_rec_customer.contact_text 
	LET l_rec_invoicehead.tele_text = l_rec_customer.tele_text 
	LET l_rec_invoicehead.hand_tax_amt = 0 
	LET l_rec_invoicehead.freight_amt = 0 
	LET l_rec_invoicehead.freight_tax_amt = 0 
	LET l_rec_invoicehead.tax_per = l_rec_tax.tax_per 
	LET l_rec_invoicehead.disc_amt = 0 
	LET l_rec_invoicehead.paid_amt = 0 
	LET l_rec_invoicehead.disc_taken_amt = 0 
	LET l_rec_invoicehead.disc_per = 0 
	LET l_rec_invoicehead.cost_amt = 0 
	LET l_rec_invoicehead.acct_override_code = p_acct_code 
	LET l_rec_invoicehead.conv_qty = get_conv_rate(
		p_cmpy, 
		l_rec_invoicehead.currency_code, 
		l_rec_invoicehead.inv_date,
		CASH_EXCHANGE_SELL) 
	
	IF l_rec_invoicehead.term_code IS NOT NULL THEN 
		CALL get_due_and_discount_date(
			l_rec_term.*,
			l_rec_invoicehead.inv_date) 
		RETURNING 
			l_rec_invoicehead.due_date, 
			l_rec_invoicehead.disc_date 
		
		LET l_rec_invoicehead.disc_per = l_rec_term.disc_per 
	END IF 
	LET l_rec_invoicehead.ship_date = l_rec_invoicehead.inv_date 
	LET l_rec_invoicehead.prepaid_flag = "P" 
	LET l_rec_invoicehead.seq_num = 0 
	LET l_rec_invoicehead.on_state_flag = "N" 
	LET l_rec_invoicehead.posted_flag = "N" 
	LET l_rec_invoicehead.inv_ind = "C" 
	LET l_rec_invoicehead.printed_num = 1 

	INITIALIZE l_rec_invoicedetl.* TO NULL 
	LET l_rec_invoicedetl.cmpy_code = p_cmpy 
	LET l_rec_invoicedetl.cust_code = l_rec_invoicehead.cust_code 
	LET l_rec_invoicedetl.inv_num = l_rec_invoicehead.inv_num 
	LET l_rec_invoicedetl.line_num = 1 
	LET l_rec_invoicedetl.ship_qty = 1 
	LET l_rec_invoicedetl.sold_qty = l_rec_invoicedetl.ship_qty 
	LET l_rec_invoicedetl.ord_qty = 1 
	LET l_rec_invoicedetl.back_qty = 0 
	LET l_rec_invoicedetl.prev_qty = 0 
	LET l_rec_invoicedetl.bonus_qty = 0 
	LET l_rec_invoicedetl.seq_num = 0 
	LET l_rec_invoicedetl.ser_flag = "N" 
	LET l_rec_invoicedetl.ser_qty = 0 
	LET l_rec_invoicedetl.level_code = "L" 
	LET l_rec_invoicedetl.tax_code = l_rec_invoicehead.tax_code 
	LET l_rec_invoicedetl.unit_sale_amt = l_rec_invoicehead.goods_amt 
	LET l_rec_invoicedetl.unit_tax_amt = l_rec_invoicehead.tax_amt 
	LET l_rec_invoicedetl.ext_sale_amt = 
	l_rec_invoicedetl.sold_qty * l_rec_invoicedetl.unit_sale_amt 
	LET l_rec_invoicedetl.ext_tax_amt = 
	l_rec_invoicedetl.sold_qty * l_rec_invoicedetl.unit_tax_amt 
	LET l_rec_invoicedetl.line_total_amt = 
	l_rec_invoicedetl.ext_sale_amt + l_rec_invoicedetl.ext_tax_amt 
	LET l_rec_invoicedetl.list_price_amt = l_rec_invoicedetl.unit_sale_amt 
	LET l_rec_invoicedetl.unit_cost_amt = 0 
	LET l_rec_invoicedetl.ext_cost_amt = 0 
	LET l_rec_invoicedetl.disc_amt = 0 
	LET l_rec_invoicedetl.ext_bonus_amt = 0 
	LET l_rec_invoicedetl.ext_stats_amt = 0 
	LET l_rec_invoicedetl.comm_amt = 0 
	LET l_rec_invoicedetl.comp_per = 0 
	LET l_rec_invoicedetl.disc_per = 0 
	LET l_rec_invoicedetl.line_text = l_rec_invoicehead.com1_text 
	LET l_rec_invoicedetl.line_acct_code = p_acct_code 

	LET l_err_message = "Contra Invoice - invoice line addition failed" 

	#INSERT invoiceDetl Record
	IF db_invoicedetl_rec_validation(UI_ON,MODE_INSERT,l_rec_invoicedetl.*) THEN
		INSERT INTO invoicedetl VALUES (l_rec_invoicedetl.*)		
	ELSE
		DISPLAY l_rec_invoicedetl.*
		CALL fgl_winmessage("Error","Could not insert new invoiceDetl record","ERROR")
	END IF 


	LET l_err_message = "Contra Invoice - invoice header addition failed" 

	#INSERT invoicehead Record
	IF db_invoicehead_rec_validation(UI_ON,MODE_INSERT,l_rec_invoicehead.*) THEN
		INSERT INTO invoicehead VALUES (l_rec_invoicehead.*)			
	ELSE
		DISPLAY l_rec_invoicehead.*
		CALL fgl_winmessage("Error","Could not insert new invoicehead record","ERROR")
	END IF 

	LET l_err_message = "Contra Invoice - Customer Update Inv" 
	LET l_rec_customer.next_seq_num = l_rec_customer.next_seq_num + 1 
	LET l_rec_customer.bal_amt = l_rec_customer.bal_amt + l_rec_invoicehead.total_amt 
	LET l_rec_customer.curr_amt = l_rec_customer.curr_amt	+ l_rec_invoicehead.total_amt 
	
	INITIALIZE l_rec_araudit.* TO NULL 
	
	LET l_rec_araudit.cmpy_code = p_cmpy 
	LET l_rec_araudit.tran_date = l_rec_invoicehead.inv_date 
	LET l_rec_araudit.cust_code = l_rec_invoicehead.cust_code 
	LET l_rec_araudit.seq_num = l_rec_customer.next_seq_num 
	LET l_rec_araudit.tran_type_ind = TRAN_TYPE_INVOICE_IN 
	LET l_rec_araudit.source_num = l_rec_invoicehead.inv_num 
	LET l_rec_araudit.tran_text = "Contra Invoice" 
	LET l_rec_araudit.tran_amt = l_rec_invoicehead.total_amt 
	LET l_rec_araudit.entry_code = p_whom 
	LET l_rec_araudit.sales_code = l_rec_invoicehead.sale_code 
	LET l_rec_araudit.year_num = l_rec_invoicehead.year_num 
	LET l_rec_araudit.period_num = l_rec_invoicehead.period_num 
	LET l_rec_araudit.bal_amt = l_rec_customer.bal_amt 
	LET l_rec_araudit.currency_code = l_rec_customer.currency_code 
	LET l_rec_araudit.conv_qty = l_rec_invoicehead.conv_qty 
	LET l_rec_araudit.entry_date = today 
	LET l_err_message = "Contra Invoice - Unable TO add TO AR log table " 
	
	INSERT INTO araudit VALUES (l_rec_araudit.*) 
	
	IF l_rec_customer.bal_amt > l_rec_customer.highest_bal_amt THEN 
		LET l_rec_customer.highest_bal_amt = l_rec_customer.bal_amt 
	END IF 
	
	LET l_rec_customer.cred_bal_amt =	l_rec_customer.cred_limit_amt - l_rec_customer.bal_amt 
	IF year(l_rec_invoicehead.inv_date)	> year(l_rec_customer.last_inv_date) THEN 
		LET l_rec_customer.ytds_amt = 0 
	END IF 
	
	LET l_rec_customer.ytds_amt = l_rec_customer.ytds_amt+ l_rec_invoicehead.total_amt 
	
	IF (month(l_rec_invoicehead.inv_date) 
	> month(l_rec_customer.last_inv_date) 
	OR year(l_rec_invoicehead.inv_date) 
	> year(l_rec_customer.last_inv_date)) THEN 
		LET l_rec_customer.mtds_amt = 0 
	END IF 
	
	LET l_rec_customer.mtds_amt = l_rec_customer.mtds_amt	+ l_rec_invoicehead.total_amt 
	LET l_rec_customer.last_inv_date = l_rec_invoicehead.inv_date 
	LET l_err_message = "Contra Invoice - Custmain actual UPDATE " 
	
	UPDATE customer	SET 
		next_seq_num = l_rec_customer.next_seq_num, 
		bal_amt = l_rec_customer.bal_amt, 
		curr_amt = l_rec_customer.curr_amt, 
		highest_bal_amt = l_rec_customer.highest_bal_amt, 
		cred_bal_amt = l_rec_customer.cred_bal_amt, 
		last_inv_date = l_rec_customer.last_inv_date, 
		ytds_amt = l_rec_customer.ytds_amt, 
		mtds_amt = l_rec_customer.mtds_amt 
	WHERE cust_code = p_cust_code 
	AND cmpy_code = p_cmpy 
	CLOSE c1_customer 
	RETURN 0, 0, " ", l_rec_invoicehead.inv_num 
END FUNCTION 

FUNCTION contra_credit(p_cmpy,p_whom,p_cust_code,p_payment_date,p_year_num,p_period_num,p_acct_code,p_contra_amt) 
	DEFINE p_cmpy LIKE customer.cmpy_code 
	DEFINE p_whom LIKE kandoouser.sign_on_code 
	DEFINE p_cust_code LIKE customer.cust_code 
	DEFINE p_payment_date LIKE cheque.cheq_date 
	DEFINE p_year_num LIKE credithead.year_num 
	DEFINE p_period_num LIKE credithead.period_num 
	DEFINE p_acct_code LIKE coa.acct_code 
	DEFINE p_contra_amt LIKE credithead.total_amt 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_credithead RECORD LIKE credithead.* 
	DEFINE l_rec_creditdetl RECORD LIKE creditdetl.* 
	DEFINE l_rec_araudit RECORD LIKE araudit.* 
	DEFINE l_rec_tax RECORD LIKE tax.* 
	DEFINE l_err_message CHAR(80) 
	DEFINE l_credit_reason LIKE arparms.reason_code 

	GOTO bypass 
	LABEL ret_status: 
	RETURN -2, status, "", 0 
	LABEL bypass: 
	WHENEVER ERROR GOTO ret_status 

	SELECT unique 1 FROM coa 
	WHERE acct_code = p_acct_code 
	AND cmpy_code = p_cmpy 
	IF status = notfound THEN 
		LET l_err_message =		"GL Clearing Account FOR Contra NOT found: " ,		p_acct_code clipped 
		RETURN -1, status, l_err_message, 0 
	END IF 
	
	SELECT reason_code INTO l_credit_reason FROM arparms 
	WHERE parm_code = "1" 
	AND cmpy_code = p_cmpy 
	IF status = notfound THEN 
		LET l_err_message =	"AR Parameters do NOT exist; Refer Menu AZP" 
		RETURN -1, status, l_err_message, 0 
	END IF 
	
	DECLARE c2_customer CURSOR FOR 
	SELECT * FROM customer 
	WHERE cmpy_code = p_cmpy 
	AND cust_code = p_cust_code 
	FOR UPDATE 
	OPEN c2_customer 
	FETCH c2_customer INTO l_rec_customer.* 
	IF status = notfound THEN 
		LET l_err_message = "Contra Customer NOT found: ", 
		p_cust_code clipped 
		RETURN -1, status, l_err_message, 0 
	END IF 

	SELECT * INTO l_rec_tax.* FROM tax 
	WHERE cmpy_code = p_cmpy 
	AND tax_code = l_rec_customer.tax_code 

	INITIALIZE l_rec_credithead.* TO NULL 
	LET l_rec_credithead.cred_num = next_trans_num(p_cmpy, TRAN_TYPE_CREDIT_CR,p_acct_code) 

	IF l_rec_credithead.cred_num < 0 THEN 
		LET l_err_message = "Contra Credit - Next credit number UPDATE" 
		LET status = l_rec_credithead.cred_num 
		RETURN -1, status, l_err_message, 0 
	END IF 

	LET l_rec_credithead.cmpy_code = p_cmpy 
	LET l_rec_credithead.cred_date = p_payment_date 
	LET l_rec_credithead.cust_code = p_cust_code 
	LET l_rec_credithead.year_num = p_year_num 
	LET l_rec_credithead.period_num = p_period_num 
	LET l_rec_credithead.tax_code = l_rec_customer.tax_code 
	LET l_rec_credithead.com1_text =	"Contra entry on ", today USING "dd/mm/yyyy" 
	
	#---------------------------------------------
	# Positive contra payments result in a credit
	
	LET l_rec_credithead.goods_amt = p_contra_amt 
	LET l_rec_credithead.total_amt = l_rec_credithead.goods_amt 
	LET l_rec_credithead.hand_amt = 0 
	LET l_rec_credithead.tax_amt = 0 
	
	IF l_rec_customer.corp_cust_code IS NOT NULL AND l_rec_customer.corp_cust_ind = "1" THEN 
		LET p_cust_code = l_rec_customer.corp_cust_code 
		LET l_rec_credithead.org_cust_code = l_rec_credithead.cust_code 
	ELSE 
		LET p_cust_code = l_rec_customer.cust_code 
		LET l_rec_credithead.org_cust_code = NULL 
	END IF 
	
	LET l_rec_credithead.entry_code = p_whom 
	LET l_rec_credithead.entry_date = today 
	LET l_rec_credithead.sale_code = l_rec_customer.sale_code 
	LET l_rec_credithead.currency_code = l_rec_customer.currency_code 
	LET l_rec_credithead.territory_code = l_rec_customer.territory_code 
	LET l_rec_credithead.line_num = 1 
	LET l_rec_credithead.next_num = 0 
	LET l_rec_credithead.rev_date = l_rec_credithead.entry_date 
	LET l_rec_credithead.rev_num = 0 
	LET l_rec_credithead.hand_tax_amt = 0 
	LET l_rec_credithead.freight_amt = 0 
	LET l_rec_credithead.freight_tax_amt = 0 
	LET l_rec_credithead.tax_per = l_rec_tax.tax_per 
	LET l_rec_credithead.disc_amt = 0 
	LET l_rec_credithead.appl_amt = 0 
	LET l_rec_credithead.cost_amt = 0 
	LET l_rec_credithead.acct_override_code = p_acct_code 
	LET l_rec_credithead.conv_qty =	get_conv_rate(
		p_cmpy, 
		l_rec_credithead.currency_code, 
		l_rec_credithead.cred_date,
		CASH_EXCHANGE_SELL) 
	LET l_rec_credithead.on_state_flag = "N" 
	LET l_rec_credithead.posted_flag = "N" 
	LET l_rec_credithead.cred_ind = "C" 
	LET l_rec_credithead.printed_num = 1 

	INITIALIZE l_rec_creditdetl.* TO NULL 
	
	LET l_rec_creditdetl.cmpy_code = p_cmpy 
	LET l_rec_creditdetl.cust_code = l_rec_credithead.cust_code 
	LET l_rec_creditdetl.cred_num = l_rec_credithead.cred_num 
	LET l_rec_creditdetl.line_num = 1 
	LET l_rec_creditdetl.ship_qty = 1 
	LET l_rec_creditdetl.seq_num = 0 
	LET l_rec_creditdetl.received_qty = 0 
	LET l_rec_creditdetl.level_code = "L" 
	LET l_rec_creditdetl.tax_code = l_rec_credithead.tax_code 
	LET l_rec_creditdetl.unit_sales_amt = l_rec_credithead.goods_amt 
	LET l_rec_creditdetl.unit_tax_amt = l_rec_credithead.tax_amt 
	LET l_rec_creditdetl.ext_sales_amt = l_rec_creditdetl.ship_qty * l_rec_creditdetl.unit_sales_amt 
	LET l_rec_creditdetl.ext_tax_amt = l_rec_creditdetl.ship_qty * l_rec_creditdetl.unit_tax_amt 
	LET l_rec_creditdetl.line_total_amt = l_rec_creditdetl.ext_sales_amt + l_rec_creditdetl.ext_tax_amt 
	LET l_rec_creditdetl.unit_cost_amt = 0 
	LET l_rec_creditdetl.ext_cost_amt = 0 
	LET l_rec_creditdetl.disc_amt = 0 
	LET l_rec_creditdetl.line_text = l_rec_credithead.com1_text 
	LET l_rec_creditdetl.line_acct_code = p_acct_code 
	LET l_rec_creditdetl.comm_amt = 0 
	LET l_rec_creditdetl.list_amt = l_rec_creditdetl.unit_sales_amt 
	LET l_rec_creditdetl.reason_code = l_credit_reason 

	LET l_err_message = "Contra Credit - credit line addition failed" 
	
	INSERT INTO creditdetl VALUES (l_rec_creditdetl.*) 
	
	LET l_err_message = "Contra Credit - credit header addition failed" 
	
	INSERT INTO credithead VALUES (l_rec_credithead.*) 

	LET l_err_message = "Contra Credit - Customer Update CR" 
	LET l_rec_customer.next_seq_num = l_rec_customer.next_seq_num + 1 
	LET l_rec_customer.bal_amt = l_rec_customer.bal_amt - l_rec_credithead.total_amt 
	LET l_rec_customer.curr_amt = l_rec_customer.curr_amt	- l_rec_credithead.total_amt 
	
	INITIALIZE l_rec_araudit.* TO NULL 
	
	LET l_rec_araudit.cmpy_code = p_cmpy 
	LET l_rec_araudit.tran_date = l_rec_credithead.cred_date 
	LET l_rec_araudit.cust_code = l_rec_credithead.cust_code 
	LET l_rec_araudit.seq_num = l_rec_customer.next_seq_num 
	LET l_rec_araudit.tran_type_ind = TRAN_TYPE_CREDIT_CR 
	LET l_rec_araudit.source_num = l_rec_credithead.cred_num 
	LET l_rec_araudit.tran_text = "Contra Credit" 
	LET l_rec_araudit.tran_amt = 0 - l_rec_credithead.total_amt 
	LET l_rec_araudit.entry_code = p_whom 
	LET l_rec_araudit.sales_code = l_rec_credithead.sale_code 
	LET l_rec_araudit.year_num = l_rec_credithead.year_num 
	LET l_rec_araudit.period_num = l_rec_credithead.period_num 
	LET l_rec_araudit.bal_amt = l_rec_customer.bal_amt 
	LET l_rec_araudit.currency_code = l_rec_customer.currency_code 
	LET l_rec_araudit.conv_qty = l_rec_credithead.conv_qty 
	LET l_rec_araudit.entry_date = today 
	LET l_err_message = "Contra Credit - Unable TO add TO AR log table " 
	
	INSERT INTO araudit VALUES (l_rec_araudit.*) 
	
	LET l_rec_customer.cred_bal_amt =	l_rec_customer.cred_limit_amt - l_rec_customer.bal_amt 
	LET l_rec_customer.ytds_amt = l_rec_customer.ytds_amt	- l_rec_credithead.total_amt 
	LET l_rec_customer.mtds_amt = l_rec_customer.mtds_amt - l_rec_credithead.total_amt 
	LET l_err_message = "Contra Invoice - Custmain actual UPDATE " 
	
	UPDATE customer	SET 
		next_seq_num = l_rec_customer.next_seq_num, 
		bal_amt = l_rec_customer.bal_amt, 
		curr_amt = l_rec_customer.curr_amt, 
		cred_bal_amt = l_rec_customer.cred_bal_amt, 
		ytds_amt = l_rec_customer.ytds_amt, 
		mtds_amt = l_rec_customer.mtds_amt 
	WHERE cust_code = p_cust_code 
	AND cmpy_code = p_cmpy 
	CLOSE c2_customer 
	RETURN 0, 0, " ", l_rec_credithead.cred_num 
END FUNCTION 


