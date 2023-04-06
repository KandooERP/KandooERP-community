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
#  module cashbox - Black box routines TO add/UPDATE/apply cash receipts
#                   on the database
#
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

###########################################################################
# FUNCTION cash_add(p_cashreceipt, p_pallet_amt)
#
# FUNCTION Name:        cash_add
# Description:          Used TO add a cash receipts RECORD AND UPDATE/INSERT
#                       the related records.
# Passed:
#   pr_cashreceipt      the cashreceipt RECORD ready TO be saved TO the db
#   pr_pallet_amt       the pallet price amount FOR pallet processing
# Returned:
#   TRUE/FALSE          FALSE-IF errors encountered;TRUE-no errors encountered
#   pr_cash_num         generated cash receipt number
#   pr_error_text       used TO indicate in brief the error that occurred
#                       IF the cash_add routine fails; NULL OTHERWISE
#########################################################################
FUNCTION cash_add(p_cashreceipt, p_pallet_amt) 
	DEFINE p_cashreceipt RECORD LIKE cashreceipt.* 
	DEFINE p_pallet_amt LIKE prodstatus.price1_amt 
	DEFINE l_rec_ordhead RECORD LIKE ordhead.* 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_customertype RECORD LIKE customertype.* 
	DEFINE l_rec_custpallet RECORD LIKE custpallet.* 
	DEFINE l_rec_pallet RECORD LIKE pallet.* 
	DEFINE l_rec_araudit RECORD LIKE araudit.* 
	DEFINE l_err_message CHAR(100) 
	DEFINE l_error_text CHAR(40) 
	DEFINE l_kandoo_seq_num INTEGER 
	DEFINE l_status INTEGER 
	DEFINE l_cash_num LIKE cashreceipt.cash_num 

	DEFER QUIT 
	DEFER INTERRUPT 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 
	
	GOTO bypass 
	LABEL founderror: 
	LET l_status = status 
	LET l_err_message = l_error_text clipped, " - STATUS = ", l_status 
	CALL errorlog(l_err_message) 
	LET l_cash_num = NULL 
	RETURN false, l_cash_num, l_error_text 
	LABEL bypass: 

	WHENEVER ERROR GOTO founderror 

	LET l_error_text = "Customer Type SELECT Failed -cashbox" 
	SELECT * INTO l_rec_customertype.* FROM customertype 
	WHERE cmpy_code = p_cashreceipt.cmpy_code 
	AND type_code = 
	(SELECT type_code 
	FROM customer 
	WHERE cust_code = p_cashreceipt.cust_code 
	AND cmpy_code = p_cashreceipt.cmpy_code) 
	LET p_cashreceipt.cash_num = 
	next_trans_num(p_cashreceipt.cmpy_code, 
	TRAN_TYPE_RECEIPT_CA, 
	l_rec_customertype.acct_mask_code) 

	IF p_cashreceipt.cash_num < 0 THEN 
		LET l_error_text = "Next Cash Number Failed -cashbox" 
		LET status = p_cashreceipt.cash_num 
		GOTO founderror 
	END IF 

	LET l_error_text = "Cash Number Exists -cashbox" 
	SELECT unique 1 FROM cashreceipt 
	WHERE cmpy_code = p_cashreceipt.cmpy_code 
	AND cash_num = p_cashreceipt.cash_num 
	IF status = 0 THEN 
		LET p_cashreceipt.cash_num = 
		next_trans_num(p_cashreceipt.cmpy_code, 
		TRAN_TYPE_RECEIPT_CA, 
		l_rec_customertype.acct_mask_code) 
	END IF 

	LET l_error_text = "Cash Insert Failed -cashbox" 

	INSERT INTO cashreceipt VALUES (p_cashreceipt.*) 
	### Prepare TO Update the Customer Details ###
	LET l_error_text = "Customer Update Failed -cashbox" 
	DECLARE c_customer CURSOR FOR 
	SELECT * FROM customer 
	WHERE cmpy_code = p_cashreceipt.cmpy_code 
	AND cust_code = p_cashreceipt.cust_code 
	FOR UPDATE 

	LET l_error_text = "Customer Open Cursor Failed -cashbox" 

	OPEN c_customer 
	LET l_error_text = "Customer Fetch Cursor Failed -cashbox" 
	FETCH c_customer INTO l_rec_customer.* 

	LET l_rec_customer.bal_amt = l_rec_customer.bal_amt- p_cashreceipt.cash_amt 
	LET l_rec_customer.curr_amt = l_rec_customer.curr_amt - p_cashreceipt.cash_amt 
	LET l_rec_customer.last_pay_date = p_cashreceipt.cash_date 
	LET l_rec_customer.next_seq_num = l_rec_customer.next_seq_num + 1 
	LET l_rec_customer.cred_bal_amt = l_rec_customer.cred_limit_amt - l_rec_customer.bal_amt 
	LET l_rec_customer.ytdp_amt = l_rec_customer.ytdp_amt + p_cashreceipt.cash_amt 
	LET l_rec_customer.mtdp_amt = l_rec_customer.mtdp_amt + p_cashreceipt.cash_amt 
	
	### Update the Customer Details ###
	LET l_error_text = "Customer Update Failed -cashbox" 
	UPDATE customer 
	SET bal_amt = l_rec_customer.bal_amt, 
	last_pay_date = l_rec_customer.last_pay_date, 
	curr_amt = l_rec_customer.curr_amt, 
	next_seq_num = l_rec_customer.next_seq_num, 
	cred_bal_amt = l_rec_customer.cred_bal_amt, 
	ytdp_amt = l_rec_customer.ytdp_amt, 
	mtdp_amt = l_rec_customer.mtdp_amt 
	WHERE cmpy_code = p_cashreceipt.cmpy_code 
	AND cust_code = p_cashreceipt.cust_code 
	
	### Pallet specific code ###
	IF (p_pallet_amt IS NOT null) AND # able TO charge pallets 
	(p_pallet_amt <> 0) # decided TO charge pallets 
	THEN 
		INITIALIZE l_rec_pallet.* TO NULL 
		SELECT * INTO l_rec_ordhead.* FROM ordhead 
		WHERE cmpy_code = p_cashreceipt.cmpy_code 
		AND order_num = p_cashreceipt.order_num 
		
		LET l_rec_pallet.trans_qty = (p_pallet_amt / l_rec_ordhead.pallet_price_amt) * -1 
		
		SELECT * INTO l_rec_custpallet.* FROM custpallet 
		WHERE cmpy_code = p_cashreceipt.cmpy_code 
		AND cust_code = p_cashreceipt.cust_code 
		IF status = notfound THEN 
			INITIALIZE l_rec_custpallet.* TO NULL 
			LET l_rec_custpallet.cmpy_code = p_cashreceipt.cmpy_code 
			LET l_rec_custpallet.cust_code = p_cashreceipt.cust_code 
			LET l_rec_custpallet.bal_amt = (l_rec_pallet.trans_qty * l_rec_ordhead.pallet_price_amt) 
			LET l_rec_custpallet.curr_amt = (l_rec_pallet.trans_qty	* l_rec_ordhead.pallet_price_amt) 
			LET l_rec_custpallet.over1_amt = 0 
			LET l_rec_custpallet.over30_amt = 0 
			LET l_rec_custpallet.over60_amt = 0 
			LET l_rec_custpallet.over90_amt = 0 
			LET l_rec_custpallet.onorder_amt = 0 
			LET l_error_text = "Customer Pallet Insert Failed -cashbox"
			
			------------------------------------------------------ 
			INSERT INTO custpallet VALUES (l_rec_custpallet.*) 
		ELSE 
			LET l_rec_custpallet.bal_amt = l_rec_custpallet.bal_amt + (l_rec_pallet.trans_qty	* l_rec_ordhead.pallet_price_amt) 
			LET l_rec_custpallet.curr_amt = l_rec_custpallet.curr_amt + (l_rec_pallet.trans_qty	* l_rec_ordhead.pallet_price_amt) 
			LET l_error_text = "Customer Pallet Update Failed -cashbox" 
			
			UPDATE custpallet	SET 
				bal_amt = l_rec_custpallet.bal_amt, 
				curr_amt = l_rec_custpallet.curr_amt 
			WHERE cmpy_code = p_cashreceipt.cmpy_code 
			AND cust_code = p_cashreceipt.cust_code 
		END IF 
		
		LET l_rec_pallet.cmpy_code = p_cashreceipt.cmpy_code 
		
		IF p_cashreceipt.cust_code != l_rec_ordhead.cust_code THEN 
			LET l_rec_pallet.org_cust_code = l_rec_ordhead.cust_code #subsidiary 
		END IF 
		
		SELECT max(seq_num) 
		INTO l_kandoo_seq_num 
		FROM pallet 
		WHERE cust_code = l_rec_ordhead.cust_code 
		AND cmpy_code = l_rec_ordhead.cmpy_code 
		
		IF l_kandoo_seq_num IS NULL THEN 
			LET l_kandoo_seq_num = 0 
		END IF 
		
		LET l_rec_pallet.cust_code = p_cashreceipt.cust_code 
		LET l_rec_pallet.order_num = p_cashreceipt.order_num 
		LET l_rec_pallet.trans_num = p_cashreceipt.cash_num 
		LET l_rec_pallet.tran_type_ind = "DE" #deposit paid 
		LET l_rec_pallet.unit_price_amt = l_rec_ordhead.pallet_price_amt 
		LET l_rec_pallet.tran_date = p_cashreceipt.cash_date 
		LET l_rec_pallet.seq_num = l_kandoo_seq_num + 1 
		LET l_error_text = "Pallet Insert Failed -cashbox" 
		
		#-------------------------------------------
		INSERT INTO pallet VALUES (l_rec_pallet.*) 
	END IF 
	
	LET l_rec_araudit.cmpy_code = p_cashreceipt.cmpy_code 
	LET l_rec_araudit.tran_date = p_cashreceipt.cash_date 
	LET l_rec_araudit.cust_code = p_cashreceipt.cust_code 
	LET l_rec_araudit.seq_num = l_rec_customer.next_seq_num 
	LET l_rec_araudit.tran_type_ind = TRAN_TYPE_RECEIPT_CA 
	LET l_rec_araudit.source_num = p_cashreceipt.cash_num 
	LET l_rec_araudit.tran_text = "Cash Receipt" 
	LET l_rec_araudit.tran_amt = 0 - p_cashreceipt.cash_amt 
	LET l_rec_araudit.entry_code = p_cashreceipt.entry_code 
	LET l_rec_araudit.year_num = p_cashreceipt.year_num 
	LET l_rec_araudit.period_num = p_cashreceipt.period_num 
	LET l_rec_araudit.bal_amt = l_rec_customer.bal_amt 
	LET l_rec_araudit.currency_code = p_cashreceipt.currency_code 
	LET l_rec_araudit.conv_qty = p_cashreceipt.conv_qty 
	LET l_rec_araudit.entry_date = today 
	LET l_error_text = "Audit Trail Insert Failed -cashbox" 
	
	INSERT INTO araudit VALUES (l_rec_araudit.*) 
	WHENEVER ERROR stop 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	
	LET l_error_text = NULL 
	LET l_cash_num = p_cashreceipt.cash_num 

	RETURN true, l_cash_num, l_error_text 
END FUNCTION 
##############################################################################
# FUNCTION Name:        auto_cash_apply
# Description:          Used TO apply a cash receipt TO an invoice
# Passed:
#   p_cmpy_code        the related company code value FOR all transactions
#   p_whom             the person caUSING all the problems
#   p_cash_num         the cash receipt number
#   pr_verbose          TRUE-DISPLAY all MESSAGEs/errors interactivily
#                       FALSE-all MESSAGEs/errors silent
# Returned:
#   TRUE/FALSE          FALSE-IF errors encountered;TRUE-no errors encountered
#   pr_error_text       a brief description of the error encountered
##############################################################################
FUNCTION auto_cash_apply(p_cmpy_code, 
	p_whom, 
	p_cash_num, 
	p_where_text, 
	p_verbose) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_whom LIKE kandoouser.sign_on_code 
	DEFINE p_cash_num LIKE cashreceipt.cash_num 
	DEFINE p_where_text CHAR(2048) 
	DEFINE p_verbose SMALLINT 
	DEFINE l_query_text CHAR(2048) 
	DEFINE l_rec_cashreceipt RECORD LIKE cashreceipt.* 
	DEFINE l_rec_invoicehead RECORD LIKE invoicehead.* 
	DEFINE l_appl_amt LIKE cashreceipt.cash_amt 
	DEFINE l_disc_amt LIKE cashreceipt.cash_amt 
	DEFINE l_recalc_ind CHAR(1) 
	DEFINE l_error_text CHAR(40) 
	DEFINE l_status SMALLINT 

	##
	## SELECT Cashreceipt
	##
	LET l_error_text = "CashReceipt SELECT Failed -cashbox" 
	SELECT * INTO l_rec_cashreceipt.* 
	FROM cashreceipt 
	WHERE cmpy_code = p_cmpy_code 
	AND cash_num = p_cash_num 
	AND applied_amt != cash_amt 
	AND cash_amt > 0 
	IF status = notfound THEN 
		RETURN false, l_error_text 
	END IF 
	IF get_kandoooption_feature_state("AR","PT") = "2" THEN 
		## kandoooption use multi-level discounts (Y/N)"
		## IF Y THEN recalc discount amount
		LET l_recalc_ind = 'Y' 
	ELSE 
		LET l_recalc_ind = 'N' 
	END IF 
	
	##
	## SELECT Invoiceheads
	##
	LET l_query_text = "SELECT * FROM invoicehead ", 
	"WHERE cmpy_code = '",p_cmpy_code,"' ", 
	"AND cust_code = '",l_rec_cashreceipt.cust_code,"' ", 
	"AND total_amt != paid_amt ", 
	"AND ",p_where_text clipped," ", 
	"ORDER BY cust_code,", ## force TO use INDEX 
	"due_date,", 
	"inv_num" 
	PREPARE s0_invoicehead FROM l_query_text 
	DECLARE c0_invoicehead CURSOR with HOLD FOR s0_invoicehead 
	
	FOREACH c0_invoicehead INTO l_rec_invoicehead.* 
		LET l_disc_amt = 0 
		LET l_appl_amt = l_rec_invoicehead.total_amt- l_rec_invoicehead.paid_amt 
		IF l_appl_amt>(l_rec_cashreceipt.cash_amt-l_rec_cashreceipt.applied_amt) THEN 
			LET l_appl_amt = l_rec_cashreceipt.cash_amt-l_rec_cashreceipt.applied_amt 
		END IF 
		IF l_rec_cashreceipt.posted_flag != CASHRECEIPT_POST_FLAG_STATUS_POSTED_Y THEN 
			IF l_recalc_ind = 'Y' THEN 
				LET l_disc_amt = l_rec_invoicehead.total_amt * 
				(show_disc(p_cmpy_code,l_rec_invoicehead.term_code, 
				l_rec_cashreceipt.cash_date, 
				l_rec_invoicehead.inv_date)/100) 
			ELSE 
				IF l_rec_cashreceipt.cash_date <= l_rec_invoicehead.disc_date THEN 
					LET l_disc_amt = l_rec_invoicehead.disc_amt 
				END IF 
			END IF 
			IF (l_rec_invoicehead.total_amt-l_rec_invoicehead.paid_amt) > (l_appl_amt + l_disc_amt) THEN 
				LET l_disc_amt = 0 
			ELSE 
				LET l_appl_amt = l_rec_invoicehead.total_amt 
				- l_rec_invoicehead.paid_amt 
				- l_disc_amt 
			END IF 
		END IF 
		
		IF (l_appl_amt+l_disc_amt) > 0 THEN 
			CALL receipt_apply(
				p_cmpy_code, 
				p_whom, 
				l_rec_cashreceipt.cash_num, 
				l_rec_invoicehead.inv_num, 
				l_appl_amt, 
				l_disc_amt, 
				p_verbose) 
			RETURNING l_status, l_error_text 
			
			IF l_status THEN 
				SELECT applied_amt INTO l_rec_cashreceipt.applied_amt 
				FROM cashreceipt 
				WHERE cmpy_code = p_cmpy_code 
				AND cust_code = l_rec_cashreceipt.cust_code 
				AND cash_num = l_rec_cashreceipt.cash_num 
			ELSE 
				RETURN false, l_error_text 
			END IF 
		ELSE 
			EXIT FOREACH 
		END IF 
	END FOREACH
	 
	LET l_error_text = NULL 
	RETURN true, l_error_text 
END FUNCTION
###########################################################################
# FUNCTION cash_add(p_cashreceipt, p_pallet_amt)
###########################################################################

 
#########################################################################
# FUNCTION Name:        receipt_apply
# Description:          Used TO apply a receipt TO an invoice
# Passed:
#   p_cmpy_code        the related company code value FOR all transactions
#   pr_whom             the person caUSING all the problems
#   pr_inv_num          the invoice number TO which the cash receipt will be
#                       applied
#   pr_applied_amt      the amount TO be applied
#   pr_discount_amt     the discount amount FROM the application of cash TO
#                       invoice
#   pr_verbose          TRUE-DISPLAY all MESSAGEs/errors interactivily
#                       FALSE-all MESSAGEs/errors silent
#
# Returned:
#   TRUE/FALSE          FALSE-IF errors encountered;TRUE-no errors encountered
#   pr_error_text       used TO indicate in brief the error that occurred
#                       IF the receipt_apply routine fails; NULL OTHERWISE
#########################################################################
FUNCTION receipt_apply(p_cmpy_code, 
	p_whom, 
	p_cash_num, 
	p_inv_num, 
	p_applied_amt, 
	p_discount_amt, 
	p_verbose) 
	# UPDATE procedure IS .
	#     1. lock cashreceipt table
	#     2. re-check amounts
	#     3. FETCH invoicehead
	#     4. UPDATE invoicehead
	#     5. INSERT invoicepay
	#     6. INSERT exchange variance (IF any)
	#     7. UPDATE cashreceipt
	#     8. IF dishonoured THEN rpt steps 1 -> 7 (receipt = negative entry)
	#     9. IF any discount added THEN OUTPUT araudit
	#     10.UPDATE customer
	#
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_whom LIKE kandoouser.sign_on_code 
	DEFINE p_cash_num LIKE cashreceipt.cash_num 
	DEFINE p_inv_num LIKE invoicehead.inv_num 
	DEFINE p_applied_amt LIKE cashreceipt.cash_amt 
	DEFINE p_discount_amt LIKE cashreceipt.cash_amt 
	DEFINE p_verbose SMALLINT 
	DEFINE l_appl_amt LIKE cashreceipt.cash_amt 
	DEFINE l_disc_amt LIKE cashreceipt.cash_amt 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_pr_customer RECORD LIKE customer.* 
	DEFINE l_rec_cashreceipt RECORD LIKE cashreceipt.* 
	DEFINE l_rec_invoicehead RECORD LIKE invoicehead.* 
	DEFINE l_rec_invoicepay RECORD LIKE invoicepay.* 
	DEFINE l_rec_exchangevar RECORD LIKE exchangevar.* 
	DEFINE l_rec_araudit RECORD LIKE araudit.* 
	DEFINE l_rec_arparms RECORD LIKE arparms.* 
	DEFINE l_kandoo_date LIKE invoicehead.paid_date 
	DEFINE l_base_inv_amt LIKE invoicepay.pay_amt 
	DEFINE l_base_cash_amt LIKE invoicepay.pay_amt 
	DEFINE l_error_text CHAR(40) 
	DEFINE l_query_text CHAR(2200) 
	DEFINE l_err_message CHAR(200) 
	DEFINE i SMALLINT 
	DEFINE l_msg_num SMALLINT 
	DEFINE l_invoice_age SMALLINT 
	DEFINE l_receipt_age SMALLINT 

	SELECT * INTO l_rec_arparms.* 
	FROM arparms 
	WHERE cmpy_code = p_cmpy_code 
	AND parm_code = "1" 
	LET l_error_text = "AR Parms SELECT Failed -cashbox" 
	IF sqlca.sqlcode = notfound THEN 
		LET l_msgresp = kandoomsg("A",5002,"") 
		#5002 " AR Parameters are NOT found"
		RETURN false, l_error_text 
	END IF 
	LET l_query_text = "SELECT * FROM cashreceipt ", 
	"WHERE cmpy_code = '",p_cmpy_code,"' ", 
	"AND cash_num = ? FOR UPDATE" 
	PREPARE s_cashreceipt FROM l_query_text 
	DECLARE c_cashreceipt CURSOR FOR s_cashreceipt 
	LET l_query_text = "SELECT * FROM invoicehead ", 
	"WHERE cmpy_code = '",p_cmpy_code,"' ", 
	"AND inv_num = ? FOR UPDATE " 
	PREPARE s_invoicehead FROM l_query_text 
	DECLARE c_invoicehead CURSOR FOR s_invoicehead 
	LET l_query_text = " SELECT * FROM customer ", 
	" WHERE cmpy_code = '",p_cmpy_code,"' ", 
	" AND cust_code = ? ", 
	" FOR UPDATE " 
	PREPARE s1_customer FROM l_query_text 
	DECLARE c1_customer CURSOR FOR s1_customer 
	GOTO bypass 
	LABEL founderror: 
	RETURN false, l_error_text 
	LABEL bypass: 
	WHENEVER ERROR GOTO founderror 
	LET l_error_text = "Cash SELECT(2) Failed -cashbox" 
	OPEN c_cashreceipt USING p_cash_num 
	FETCH c_cashreceipt INTO l_rec_cashreceipt.* 
	IF status = notfound THEN 
		LET l_msg_num = 7049 
		#7049 Cash receipt number : 1121 application complete
		LET l_err_message=p_cash_num 
		GOTO founderror 
	END IF 
	LET l_receipt_age = l_rec_arparms.cust_age_date - l_rec_cashreceipt.cash_date 
	LET l_error_text = "Customer Open Cursor Failed - cashbox" 
	OPEN c1_customer USING l_rec_cashreceipt.cust_code 
	LET l_error_text = "Customer Fetch Cursor Failed - cashbox" 
	FETCH c1_customer INTO l_rec_pr_customer.* 
	FOR i = 1 TO 2 
		IF i = 1 THEN ## performs loop once FOR normal receipts 
			LET l_appl_amt = p_applied_amt 
			LET l_disc_amt = p_discount_amt 
		ELSE ## performs loop twice FOR dishonoured cheques 
			LET l_appl_amt = 0 - p_applied_amt 
			LET l_disc_amt = 0 - p_discount_amt 
		END IF 
		IF l_rec_cashreceipt.posted_flag = CASHRECEIPT_POST_FLAG_STATUS_POSTED_Y AND l_disc_amt != 0 THEN 
			LET l_msg_num=7049 
			LET l_error_text = "CashRec Posted. No Discount. - cashbox" 
			#7049 Cashreceipt IS posted - No discount
			GOTO founderror 
		END IF 
		IF l_rec_cashreceipt.cash_amt >= 0 THEN 
			IF l_rec_cashreceipt.cash_amt < 
			(l_rec_cashreceipt.applied_amt+l_appl_amt) THEN 
				LET l_msg_num=7037 
				LET l_error_text = "Over Apply Cash Receipt (1) - cashbox" 
				#7037 Attempt has been made TO over apply receipt :1234
				LET l_err_message=p_cash_num 
				GOTO founderror 
			END IF 
		ELSE 
			## code below handles negative receipts
			IF l_rec_cashreceipt.cash_amt > 
			(l_rec_cashreceipt.applied_amt+l_appl_amt) THEN 
				LET l_msg_num=7037 
				LET l_error_text = "Over Apply Cash Receipt (2) - cashbox" 
				#7037 Attempt has been made TO over apply receipt :1234
				LET l_err_message=p_cash_num 
				GOTO founderror 
			END IF 
		END IF 
		LET l_error_text = "Invoice Head Open Cursor Fail - cashbox" 
		OPEN c_invoicehead USING p_inv_num 
		LET l_error_text = "Invoice Head Fetch Failed - cashbox" 
		FETCH c_invoicehead INTO l_rec_invoicehead.* 
		IF status = notfound THEN 
			LET l_msg_num=7048 
			LET l_error_text = "Invoice SELECT Failed - cashbox" 
			#7048 Logic Error : Invoice 888 does NOT exist
			LET l_err_message=p_inv_num 
			GOTO founderror 
		END IF 
		LET l_invoice_age = l_rec_arparms.cust_age_date - l_rec_invoicehead.due_date 
		IF l_disc_amt IS NULL THEN 
			LET l_disc_amt = 0 
		END IF 
		IF l_appl_amt IS NULL THEN 
			LET l_appl_amt = 0 
		END IF 
		LET l_rec_invoicehead.paid_amt = l_rec_invoicehead.paid_amt 
		+ l_appl_amt 
		+ l_disc_amt 
		IF l_rec_cashreceipt.job_code IS NULL THEN 
			## dont UPDATE paid VALUES IF payment IS dishonoured cheque
			IF l_rec_invoicehead.paid_amt > l_rec_invoicehead.total_amt THEN 
				LET l_msg_num=7039 
				LET l_error_text = "Over Paying the Invoice - cashbox" 
				#7039 Attempt has been made TO over pay invoice 99999
				LET l_err_message=p_inv_num 
				GOTO founderror 
			END IF 
			IF l_rec_invoicehead.paid_amt != l_rec_invoicehead.total_amt 
			AND l_disc_amt > 0 THEN 
				LET l_msg_num=7040 
				LET l_error_text = "Invalid Discount Claim - cashbox" 
				#7040 Invalid discount claim made on invoice: 1121
				LET l_err_message=p_inv_num 
				GOTO founderror 
			END IF 
			IF l_rec_invoicehead.total_amt = l_rec_invoicehead.paid_amt THEN 
				LET l_rec_invoicehead.paid_date = l_rec_cashreceipt.cash_date 
				SELECT max(pay_date) INTO l_kandoo_date 
				FROM invoicepay 
				WHERE cmpy_code = p_cmpy_code 
				AND cust_code = l_rec_invoicehead.cust_code 
				AND inv_num = l_rec_invoicehead.inv_num 
				IF l_kandoo_date > l_rec_cashreceipt.cash_date THEN 
					LET l_rec_invoicehead.paid_date = l_kandoo_date 
				END IF 
				LET l_rec_pr_customer.cred_given_num = l_rec_pr_customer.cred_given_num 
				+ (l_rec_invoicehead.due_date 
				- l_rec_invoicehead.inv_date) 
				LET l_rec_pr_customer.cred_taken_num = l_rec_pr_customer.cred_taken_num 
				+ (l_rec_cashreceipt.cash_date 
				- l_rec_invoicehead.inv_date) 
				IF l_rec_cashreceipt.cash_date > l_rec_invoicehead.due_date THEN 
					LET l_rec_pr_customer.late_pay_num = l_rec_pr_customer.late_pay_num + 1 
				END IF 
			END IF 
		END IF 
		LET l_rec_invoicehead.seq_num = l_rec_invoicehead.seq_num + 1 
		LET l_rec_invoicehead.disc_taken_amt = 
		l_rec_invoicehead.disc_taken_amt + l_disc_amt 
		LET l_error_text = "Invoice Update Failed - cashbox" 
		UPDATE invoicehead 
		SET paid_amt = l_rec_invoicehead.paid_amt, 
		paid_date = l_rec_invoicehead.paid_date, 
		seq_num = l_rec_invoicehead.seq_num, 
		disc_taken_amt = l_rec_invoicehead.disc_taken_amt 
		WHERE cmpy_code = p_cmpy_code 
		AND inv_num = p_inv_num 
		LET l_rec_invoicepay.cmpy_code = p_cmpy_code 
		LET l_rec_invoicepay.cust_code = l_rec_cashreceipt.cust_code 
		LET l_rec_invoicepay.inv_num = l_rec_invoicehead.inv_num 
		LET l_rec_invoicepay.ref_num = l_rec_cashreceipt.cash_num 
		LET l_rec_invoicepay.appl_num = 0 
		LET l_rec_invoicepay.pay_text = l_rec_cashreceipt.cheque_text 
		LET l_rec_invoicepay.apply_num = l_rec_cashreceipt.next_num + 1 
		LET l_rec_invoicepay.pay_type_ind = TRAN_TYPE_RECEIPT_CA 
		LET l_rec_invoicepay.pay_date = today 
		LET l_rec_invoicepay.pay_amt = l_appl_amt 
		LET l_rec_invoicepay.disc_amt = l_disc_amt 
		LET l_rec_invoicepay.rev_flag = NULL 
		LET l_rec_invoicepay.stat_date = NULL 
		LET l_rec_invoicepay.on_state_flag = "N" 
		LET l_error_text = "Invoice Pay Insert Failed - cashbox" 
		INSERT INTO invoicepay VALUES (l_rec_invoicepay.*) 
		IF l_rec_invoicehead.conv_qty IS NOT NULL THEN 
			IF l_rec_invoicehead.conv_qty != 0 THEN 
				LET l_base_inv_amt = l_rec_invoicepay.pay_amt 
				/ l_rec_invoicehead.conv_qty 
				LET l_base_cash_amt = l_rec_invoicepay.pay_amt 
				/ l_rec_cashreceipt.conv_qty 
			END IF 
		END IF 
		LET l_rec_exchangevar.exchangevar_amt =l_base_inv_amt-l_base_cash_amt 
		IF l_rec_exchangevar.exchangevar_amt != 0 THEN 
			LET l_rec_exchangevar.cmpy_code = l_rec_cashreceipt.cmpy_code 
			LET l_rec_exchangevar.year_num = l_rec_cashreceipt.year_num 
			LET l_rec_exchangevar.period_num = l_rec_cashreceipt.period_num 
			LET l_rec_exchangevar.source_ind = "A" 
			LET l_rec_exchangevar.tran_date = l_rec_cashreceipt.cash_date 
			LET l_rec_exchangevar.ref_code = l_rec_cashreceipt.cust_code 
			LET l_rec_exchangevar.tran_type1_ind = TRAN_TYPE_INVOICE_IN 
			LET l_rec_exchangevar.ref1_num = l_rec_invoicehead.inv_num 
			LET l_rec_exchangevar.tran_type2_ind = TRAN_TYPE_RECEIPT_CA 
			LET l_rec_exchangevar.ref2_num = l_rec_cashreceipt.cash_num 
			LET l_rec_exchangevar.currency_code = l_rec_cashreceipt.currency_code 
			LET l_rec_exchangevar.posted_flag = "N" 
			LET l_error_text = "Exchange Variance Insert Fail - cashbox" 
			INSERT INTO exchangevar VALUES (l_rec_exchangevar.*) 
		END IF 
		LET l_error_text = "Cash Receipt Update Failed - cashbox" 
		LET l_rec_cashreceipt.applied_amt = l_rec_cashreceipt.applied_amt 
		+ l_appl_amt 
		LET l_rec_cashreceipt.disc_amt = l_rec_cashreceipt.disc_amt 
		+ l_disc_amt 
		UPDATE cashreceipt 
		SET applied_amt = applied_amt + l_appl_amt, 
		disc_amt = disc_amt + l_disc_amt, 
		next_num = next_num + 1 
		WHERE cmpy_code = p_cmpy_code 
		AND cash_num = l_rec_cashreceipt.cash_num 
		IF l_rec_cashreceipt.job_code IS NULL OR i = 2 THEN 
			EXIT FOR 
		ELSE 
			LET l_error_text = "Cash SELECT Failed (3) - cashbox" 
			OPEN c_cashreceipt USING l_rec_cashreceipt.job_code 
			FETCH c_cashreceipt INTO l_rec_cashreceipt.* 
			IF status = notfound THEN 
				EXIT FOR 
			END IF 
		END IF 
	END FOR 
	IF l_receipt_age <= 0 AND l_invoice_age <=0 AND l_disc_amt = 0 THEN 
	ELSE 
		CASE 
			WHEN l_receipt_age <= 0 
				LET l_rec_pr_customer.curr_amt = l_rec_pr_customer.curr_amt + l_appl_amt 
			WHEN (l_receipt_age >=1 AND l_receipt_age <=30 ) 
				LET l_rec_pr_customer.over1_amt = l_rec_pr_customer.over1_amt + l_appl_amt 
			WHEN l_receipt_age >=31 AND l_receipt_age <=60 
				LET l_rec_pr_customer.over30_amt = l_rec_pr_customer.over30_amt + l_appl_amt 
			WHEN l_receipt_age >=61 AND l_receipt_age <=90 
				LET l_rec_pr_customer.over60_amt = l_rec_pr_customer.over60_amt + l_appl_amt 
			OTHERWISE 
				LET l_rec_pr_customer.over90_amt = l_rec_pr_customer.over90_amt + l_appl_amt 
		END CASE 
		CASE 
			WHEN l_invoice_age <= 0 
				LET l_rec_pr_customer.curr_amt = l_rec_pr_customer.curr_amt - l_appl_amt 
			WHEN l_invoice_age >=1 AND l_invoice_age <=30 
				LET l_rec_pr_customer.over1_amt = l_rec_pr_customer.over1_amt - l_appl_amt 
			WHEN l_invoice_age >=31 AND l_invoice_age <=60 
				LET l_rec_pr_customer.over30_amt = l_rec_pr_customer.over30_amt - l_appl_amt 
			WHEN l_invoice_age >=61 AND l_invoice_age <=90 
				LET l_rec_pr_customer.over60_amt = l_rec_pr_customer.over60_amt - l_appl_amt 
			OTHERWISE 
				LET l_rec_pr_customer.over90_amt = l_rec_pr_customer.over90_amt - l_appl_amt 
		END CASE 
		IF l_disc_amt <> 0 THEN 
			CASE 
				WHEN l_invoice_age <= 0 
					LET l_rec_pr_customer.curr_amt = l_rec_pr_customer.curr_amt - l_disc_amt 
				WHEN l_invoice_age >=1 AND l_invoice_age <=30 
					LET l_rec_pr_customer.over1_amt = l_rec_pr_customer.over1_amt - l_disc_amt 
				WHEN l_invoice_age >=31 AND l_invoice_age <=60 
					LET l_rec_pr_customer.over30_amt = l_rec_pr_customer.over30_amt - l_disc_amt 
				WHEN l_invoice_age >=61 AND l_invoice_age <=90 
					LET l_rec_pr_customer.over60_amt = l_rec_pr_customer.over60_amt - l_disc_amt 
				OTHERWISE 
					LET l_rec_pr_customer.over90_amt = l_rec_pr_customer.over90_amt - l_disc_amt 
			END CASE 
			LET l_rec_pr_customer.bal_amt = l_rec_pr_customer.bal_amt - l_disc_amt 
			LET l_rec_pr_customer.next_seq_num = l_rec_pr_customer.next_seq_num + 1 
			LET l_rec_araudit.cmpy_code = p_cmpy_code 
			LET l_rec_araudit.tran_date = today 
			LET l_rec_araudit.cust_code = l_rec_cashreceipt.cust_code 
			LET l_rec_araudit.seq_num = l_rec_pr_customer.next_seq_num 
			LET l_rec_araudit.tran_type_ind = TRAN_TYPE_RECEIPT_CA 
			LET l_rec_araudit.source_num = l_rec_cashreceipt.cash_num 
			IF l_rec_cashreceipt.cash_amt < 0 THEN 
				LET l_rec_araudit.tran_text = "Reverse Disc." 
			ELSE 
				LET l_rec_araudit.tran_text = "Apply Discount" 
			END IF 
			LET l_rec_araudit.tran_amt = 0 - l_disc_amt 
			LET l_rec_araudit.entry_code = p_whom 
			LET l_rec_araudit.year_num = l_rec_cashreceipt.year_num 
			LET l_rec_araudit.period_num = l_rec_cashreceipt.period_num 
			LET l_rec_araudit.bal_amt = l_rec_pr_customer.bal_amt 
			LET l_rec_araudit.currency_code = l_rec_cashreceipt.currency_code 
			LET l_rec_araudit.conv_qty = l_rec_invoicehead.conv_qty 
			LET l_rec_araudit.entry_date = today 
			LET l_error_text = "AR Audit Trail Insert Failed - cashbox" 
			INSERT INTO araudit VALUES (l_rec_araudit.*) 
		END IF 
	END IF 
	LET l_error_text = "Customer Update Failed - cashbox" 
	UPDATE customer 
	SET bal_amt = l_rec_pr_customer.bal_amt, 
	curr_amt = l_rec_pr_customer.curr_amt, 
	over1_amt = l_rec_pr_customer.over1_amt, 
	over30_amt = l_rec_pr_customer.over30_amt, 
	over60_amt = l_rec_pr_customer.over60_amt, 
	over90_amt = l_rec_pr_customer.over90_amt, 
	cred_bal_amt = l_rec_pr_customer.cred_limit_amt - l_rec_pr_customer.bal_amt, 
	late_pay_num = l_rec_pr_customer.late_pay_num, 
	next_seq_num = l_rec_pr_customer.next_seq_num, 
	cred_given_num = l_rec_pr_customer.cred_given_num, 
	cred_taken_num = l_rec_pr_customer.cred_taken_num 
	WHERE cmpy_code = p_cmpy_code 
	AND cust_code = l_rec_cashreceipt.cust_code 
	WHENEVER ERROR stop 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	LET l_error_text = NULL 

	RETURN true, l_error_text 
END FUNCTION 
#########################################################################
# END FUNCTION receipt_apply(p_cmpy_code,....) 
#########################################################################
 

#########################################################################
# FUNCTION Name:        cash_verify
# Description:          Used TO validate cash receipt records TO ensure all
#                       fields must exist TO create the RECORD are present
# Passed:
#   p_cashreceipt      the cash receipt RECORD prior TO all validation checks
#
# Returned:
#   TRUE/FALSE          FALSE-IF errors encountered;TRUE-no errors encountered
#   l_rec_cashreceipt      the complete/validated cashreceipt record
#   l_error_text       used TO indicate in brief the error that occurred
#                       IF the cash_setup routine fails; NULL OTHERWISE
#########################################################################
FUNCTION cash_verify(p_cashreceipt) 
	DEFINE p_cashreceipt RECORD LIKE cashreceipt.* 
	DEFINE l_rec_cashreceipt RECORD LIKE cashreceipt.* 
	DEFINE l_error_text CHAR(40) 

	### Setup all the fields in the cashreceipt table based upon the passed
	### record.  THEN fill in the defaults AND blanks.

	###INITIALIZE the RECORD variables###
	INITIALIZE l_rec_cashreceipt.* TO NULL 
	LET l_rec_cashreceipt.* = p_cashreceipt.* 
	
	IF (l_rec_cashreceipt.cmpy_code IS null) OR (l_rec_cashreceipt.cmpy_code = " ") THEN 
		LET l_error_text = "Company Code IS Blank - cashbox" 
		RETURN false, p_cashreceipt.*, l_error_text 
	END IF 
	
	IF (l_rec_cashreceipt.cust_code IS null) OR (l_rec_cashreceipt.cust_code = " ") THEN 
		LET l_error_text = "Customer IS Blank - cashbox" 
		RETURN false, p_cashreceipt.*, l_error_text 
	END IF 
	
	IF (l_rec_cashreceipt.cash_acct_code IS null) OR (l_rec_cashreceipt.cash_acct_code = " ") THEN 
		LET l_error_text = "Cash Account Code IS Blank - cashbox" 
		RETURN false, p_cashreceipt.*, l_error_text 
	END IF 
	
	IF (l_rec_cashreceipt.entry_code IS null) OR (l_rec_cashreceipt.entry_code = " ") THEN 
		LET l_error_text = "User Login Code IS Blank - cashbox" 
		RETURN false, p_cashreceipt.*, l_error_text 
	END IF 
	
	IF (l_rec_cashreceipt.entry_date IS null) OR(l_rec_cashreceipt.entry_date = " ")	THEN 
		LET l_error_text = "User Login Date IS Blank - cashbox" 
		RETURN false, p_cashreceipt.*, l_error_text 
	END IF 
	IF (l_rec_cashreceipt.cash_date IS null) OR 
	(l_rec_cashreceipt.cash_date = " ") 
	THEN 
		LET l_error_text = "Transaction Date IS Blank - cashbox" 
		RETURN false, l_rec_cashreceipt.*, l_error_text 
	END IF 
	IF (p_cashreceipt.year_num IS null) OR 
	(p_cashreceipt.period_num IS null) 
	THEN 
		LET l_error_text = "Fiscal Year/Period IS Blank - cashbox" 
		RETURN false, l_rec_cashreceipt.*, l_error_text 
	END IF 
	IF (l_rec_cashreceipt.currency_code IS null) OR 
	(l_rec_cashreceipt.currency_code = " ") 
	THEN 
		LET l_error_text = "Currency Code IS Blank - cashbox" 
		RETURN false, l_rec_cashreceipt.*, l_error_text 
	END IF 
	IF (l_rec_cashreceipt.conv_qty IS null) OR 
	(l_rec_cashreceipt.conv_qty = 0) 
	THEN 
		LET l_error_text = "Conversion Quantity IS Blank - cashbox" 
		RETURN false, l_rec_cashreceipt.*, l_error_text 
	END IF 
	IF (l_rec_cashreceipt.cash_amt IS null) OR 
	(l_rec_cashreceipt.cash_amt = 0) 
	THEN 
		LET l_error_text = "Cash Amount 0 OR Blank - cashbox" 
		RETURN false, l_rec_cashreceipt.*, l_error_text 
	END IF 
	
	IF (l_rec_cashreceipt.cash_type_ind IS null) OR 
	(l_rec_cashreceipt.cash_type_ind = " ") 
	THEN 
		LET l_error_text = "Cash Type Indicator IS Blank - cashbox" 
		RETURN false, l_rec_cashreceipt.*, l_error_text 
	END IF 
	IF (l_rec_cashreceipt.banked_flag IS null) OR 
	(l_rec_cashreceipt.banked_flag = " ") 
	THEN 
		LET l_error_text = "Banked Flag IS Blank - cashbox" 
		RETURN false, l_rec_cashreceipt.*, l_error_text 
	END IF 
	IF (l_rec_cashreceipt.bank_code IS null) OR 
	(l_rec_cashreceipt.bank_code = " ") 
	THEN 
		LET l_error_text = "Bank Code details are Blank - cashbox" 
		RETURN false, l_rec_cashreceipt.*, l_error_text 
	END IF 
	LET l_error_text = NULL 

	RETURN true, l_rec_cashreceipt.*, l_error_text 
END FUNCTION
#########################################################################
# END FUNCTION Name:        cash_verify
#########################################################################

 
#########################################################################
# FUNCTION Name:        cash_INITIALIZE
# Description:          Used TO INITIALIZE a cashreceipt RECORD based upon
#                       parameters passed AND returns an INITIALIZEd
#                       cashreceipt record
# Passed:
#   pr_cashreceipt      the cash receipt RECORD prior TO all validation checks
#
# Returned:
#   TRUE/FALSE          FALSE-IF errors encountered;TRUE-no errors encountered
#   px_cashreceipt      the complete/validated cashreceipt record
#   pr_error_text       used TO indicate in brief the error that occurred
#                       IF the cash_setup routine fails; NULL OTHERWISE
#########################################################################
FUNCTION cash_initialize(p_cmpy_code, 
	p_cust_code, 
	p_whom, 
	p_cash_date, 
	p_job_code, 
	p_bank_code, 
	p_order_num) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_cust_code LIKE customer.cust_code 
	DEFINE p_whom LIKE kandoouser.sign_on_code 
	DEFINE p_cash_date LIKE cashreceipt.cash_date 
	DEFINE p_job_code LIKE cashreceipt.job_code 
	DEFINE p_bank_code LIKE cashreceipt.bank_code 
	DEFINE p_order_num LIKE cashreceipt.order_num 
	DEFINE l_rec_bank RECORD LIKE bank.* 
	DEFINE l_rec_glparms RECORD LIKE glparms.* 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_userlocn RECORD LIKE userlocn.* 
	DEFINE r_rec_cashreceipt RECORD LIKE cashreceipt.* 
	DEFINE r_error_text CHAR(40) 

	INITIALIZE r_rec_cashreceipt.* TO NULL 
	INITIALIZE l_rec_customer.* TO NULL 
	INITIALIZE l_rec_glparms.* TO NULL 
	INITIALIZE l_rec_bank.* TO NULL 
	INITIALIZE l_rec_userlocn.* TO NULL 
	WHENEVER ERROR CONTINUE 
	SELECT * INTO l_rec_glparms.* FROM glparms 
	WHERE cmpy_code = p_cmpy_code 
	AND key_code = "1" 
	IF status <> 0 THEN 
		LET r_error_text = "G.L. Code Invalid - cashbox" 
		RETURN false, r_rec_cashreceipt.*, r_error_text 
	END IF 
	SELECT * INTO l_rec_customer.* FROM customer 
	WHERE cust_code = p_cust_code 
	AND cmpy_code = p_cmpy_code 
	IF status <> 0 THEN 
		LET r_error_text = "Customer Code Invalid - cashbox" 
		RETURN false, r_rec_cashreceipt.*, r_error_text 
	END IF 
	SELECT * INTO l_rec_bank.* FROM bank 
	WHERE cmpy_code = p_cmpy_code 
	AND bank_code = p_bank_code 
	IF status <> 0 THEN 
		LET r_error_text = "Bank SELECT Failed - cashbox" 
		RETURN false, r_rec_cashreceipt.*, r_error_text 
	END IF 
	SELECT * INTO l_rec_userlocn.* FROM userlocn 
	WHERE cmpy_code = p_cmpy_code 
	AND sign_on_code = p_whom 
	LET r_rec_cashreceipt.cmpy_code = p_cmpy_code 
	LET r_rec_cashreceipt.cust_code = l_rec_customer.cust_code 
	LET r_rec_cashreceipt.cash_acct_code = l_rec_bank.acct_code 
	LET r_rec_cashreceipt.entry_code = p_whom 
	LET r_rec_cashreceipt.entry_date = today 
	LET r_rec_cashreceipt.cash_date = p_cash_date 
	CALL get_fiscal_year_period_for_date(r_rec_cashreceipt.cmpy_code, 
	r_rec_cashreceipt.cash_date) 
	RETURNING r_rec_cashreceipt.year_num, 
	r_rec_cashreceipt.period_num 
	IF r_rec_cashreceipt.year_num IS NULL 
	OR r_rec_cashreceipt.period_num IS NULL THEN 
		LET r_error_text = "Year/Period Not Valid - cashbox" 
		RETURN false, r_rec_cashreceipt.*, r_error_text 
	END IF 
	LET r_rec_cashreceipt.cash_amt = 0 
	LET r_rec_cashreceipt.applied_amt = 0 
	LET r_rec_cashreceipt.disc_amt = 0 
	LET r_rec_cashreceipt.on_state_flag = "N" 
	LET r_rec_cashreceipt.posted_flag = CASHRECEIPT_POST_FLAG_STATUS_NOT_POSTED_N 
	LET r_rec_cashreceipt.next_num = 0 
	LET r_rec_cashreceipt.job_code = p_job_code 
	LET r_rec_cashreceipt.banked_flag = "N" 
	LET r_rec_cashreceipt.currency_code = l_rec_bank.currency_code 
	LET r_rec_cashreceipt.conv_qty = 1.0 
	
	IF r_rec_cashreceipt.currency_code != l_rec_glparms.base_currency_code THEN 
		CALL get_conv_rate(
			r_rec_cashreceipt.cmpy_code, 
			r_rec_cashreceipt.currency_code, 
			r_rec_cashreceipt.cash_date, 
			CASH_EXCHANGE_BUY) 
		RETURNING r_rec_cashreceipt.conv_qty 
	END IF
	 
	LET r_rec_cashreceipt.bank_code = l_rec_bank.bank_code 
	LET r_rec_cashreceipt.bank_currency_code = l_rec_bank.currency_code 
	LET r_rec_cashreceipt.locn_code = l_rec_userlocn.locn_code 
	LET r_rec_cashreceipt.order_num = p_order_num 
	LET r_error_text = NULL 
	
	WHENEVER ERROR stop
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 

	RETURN true, r_rec_cashreceipt.*, r_error_text 
END FUNCTION 
#########################################################################
# END FUNCTION Name:        cash_INITIALIZE
#########################################################################