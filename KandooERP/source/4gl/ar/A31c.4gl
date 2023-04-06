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

###########################################################################
#  A31c.4gl - FUNCTION auto_cash_apply
#             Receives four arguments 1. company,
#                                     2. p_kandoouser_sign_on_code,
#                                     3. cashreceipt number
#                                     4. invoicehead selection criteria
#             This FUNCTION determines the outstanding amount of the
#             cashreceipt nominated AND works through each outstanding
#             invoice which satifies the criteria specified in due date
#             sequence.  FOREACH invoice it applies the outstanding amount
#             of the receipt TO the outstanding amount of the invoice.
#             The database UPDATE IS performed by calling the receipt
#             apply FUNCTION also in this source file.
#
#  A31c.4gl - FUNCTION receipt_apply
#             automatically applies the nominated amount of a specified
#             receipt TO a sepcified invoice
#
# NB1 : Posted cashreceipts.  It IS valid TO apply a posted cashreceipt
#       as long as there IS no settlement discount.Discount IS posted TO
#       GL with a receipt AND hence addition of discount in AR puts
#       subsidiary ledger out of balance.
#
# NB2 : Dishonoured Cheques.  These are handled in AR as 2 cashreceipts,
#       the original cheque AND a negative correcting entry.The negative
#       entry IS joined via cashreceipt.job_code TO the original entry.
#       The user only ever sees the original entry AND any application
#        OR unapplication TO the original automatically applies
#       /unapplies the negative entry TO the same invoices.
###########################################################################

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl" 
GLOBALS "../ar/A3_GROUP_GLOBALS.4gl"
GLOBALS "../ar/A31_GLOBALS.4gl"

######################################################################################
# FUNCTION auto_cash_apply(p_company_cmpy_code,p_kandoouser_sign_on_code,p_cash_num,p_where_text)
#
#
######################################################################################
FUNCTION auto_cash_apply(p_company_cmpy_code,p_kandoouser_sign_on_code,p_cash_num,p_where_text) 
	DEFINE p_company_cmpy_code LIKE company.cmpy_code 
	DEFINE p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code 
	DEFINE p_cash_num LIKE cashreceipt.cash_num 
	DEFINE p_where_text STRING 

	DEFINE l_rec_cashreceipt RECORD LIKE cashreceipt.* 
	DEFINE l_rec_invoicehead RECORD LIKE invoicehead.* 
	DEFINE l_appl_amt LIKE cashreceipt.cash_amt 
	DEFINE l_disc_amt LIKE cashreceipt.cash_amt 
	DEFINE l_recalc_ind CHAR(1) 
	DEFINE l_query_text STRING 

	LET l_appl_amt = 0
	LET l_disc_amt = 0

	##
	## SELECT Cashreceipt
	##
	LET l_query_text = 
		"SELECT * ", --INTO l_rec_cashreceipt.* 
		"FROM cashreceipt ", 
		"WHERE cmpy_code = '", trim(p_company_cmpy_code), "' ", 
		"AND cash_num = ", trim(p_cash_num), " ",  
		"AND applied_amt != cash_amt ", 
		"AND cash_amt > 0" 
	
---------------------
	
	SELECT * INTO l_rec_cashreceipt.* 
	FROM cashreceipt 
	WHERE cmpy_code = p_company_cmpy_code 
	AND cash_num = p_cash_num 
	AND applied_amt != cash_amt 
	AND cash_amt > 0 
	IF status = NOTFOUND THEN 
		RETURN 

	END IF 
	IF get_kandoooption_feature_state("AR","PT") = "2" THEN 
		## kandoooption use multi-level discounts (Y/N)"
		## IF Y THEN recalc discount amount
		LET l_recalc_ind = 'Y' 
	ELSE 
		LET l_recalc_ind = 'N' 
	END IF 

	#---------------------------
	## SELECT Invoiceheads
	##
	LET l_query_text = 
		"SELECT * FROM invoicehead ", 
		"WHERE cmpy_code = '",p_company_cmpy_code CLIPPED,"' ", 
		"AND cust_code = '",l_rec_cashreceipt.cust_code CLIPPED,"' ", 
		"AND total_amt != paid_amt ", 
		"AND ",p_where_text clipped," ", 
		"ORDER BY cust_code,", ## force TO use INDEX 
		"due_date,", 
		"inv_num" 

	DISPLAY "#43414 DEBUG SQL=", trim(l_query_text)

	PREPARE s0_invoicehead FROM l_query_text 
	DECLARE c0_invoicehead CURSOR with HOLD FOR s0_invoicehead 

	FOREACH c0_invoicehead INTO l_rec_invoicehead.* 

		LET l_disc_amt = 0 
		LET l_appl_amt = l_rec_invoicehead.total_amt - l_rec_invoicehead.paid_amt 
		IF l_appl_amt>(l_rec_cashreceipt.cash_amt-l_rec_cashreceipt.applied_amt) THEN 
			LET l_appl_amt = l_rec_cashreceipt.cash_amt-l_rec_cashreceipt.applied_amt 
		END IF 

		IF l_rec_cashreceipt.posted_flag != CASHRECEIPT_POST_FLAG_STATUS_POSTED_Y THEN 
			IF l_recalc_ind = 'Y' THEN 
				LET l_disc_amt = 
					l_rec_invoicehead.total_amt * show_disc(
						p_company_cmpy_code,
						l_rec_invoicehead.term_code, 
						l_rec_cashreceipt.cash_date, 
						l_rec_invoicehead.inv_date) /100 
			ELSE 
				IF l_rec_cashreceipt.cash_date <= l_rec_invoicehead.disc_date THEN 
					LET l_disc_amt = l_rec_invoicehead.disc_amt 
				END IF 
			END IF 
			
			IF (l_rec_invoicehead.total_amt-l_rec_invoicehead.paid_amt) > (l_appl_amt + l_disc_amt) THEN 
				LET l_disc_amt = 0 
			ELSE 
				LET l_appl_amt = l_rec_invoicehead.total_amt - l_rec_invoicehead.paid_amt - l_disc_amt 
			END IF 
		END IF 

		IF (l_appl_amt+l_disc_amt) > 0 THEN 
			IF receipt_apply(
				p_company_cmpy_code,
				p_kandoouser_sign_on_code,
				l_rec_cashreceipt.cash_num, 
				l_rec_invoicehead.inv_num, 
				l_appl_amt, 
				l_disc_amt) THEN 
				SELECT applied_amt INTO l_rec_cashreceipt.applied_amt 
				FROM cashreceipt 
				WHERE cmpy_code = p_company_cmpy_code 
				AND cust_code = l_rec_cashreceipt.cust_code 
				AND cash_num = l_rec_cashreceipt.cash_num 
			ELSE 
				EXIT FOREACH 
			END IF 
		ELSE 
			EXIT FOREACH 
		END IF 
	END FOREACH 

END FUNCTION 
######################################################################################
# END FUNCTION auto_cash_apply(p_company_cmpy_code,p_kandoouser_sign_on_code,p_cash_num,p_where_text)
######################################################################################


######################################################################################
# FUNCTION receipt_apply(p_company_cmpy_code,p_kandoouser_sign_on_code,p_cash_num,p_inv_num,p_applied_amt, p_discount_amt)
#
#
######################################################################################
FUNCTION receipt_apply( 
	p_company_cmpy_code, 
	p_kandoouser_sign_on_code, 
	p_cash_num, 
	p_inv_num, 
	p_applied_amt, 
	p_discount_amt) 
	#
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
	DEFINE p_company_cmpy_code LIKE company.cmpy_code 
	DEFINE p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code 
	DEFINE p_cash_num LIKE cashreceipt.cash_num 
	DEFINE p_inv_num LIKE invoicehead.inv_num 
	DEFINE p_applied_amt LIKE cashreceipt.cash_amt 
	DEFINE p_discount_amt LIKE cashreceipt.cash_amt 

	DEFINE l_appl_amt LIKE cashreceipt.cash_amt 
	DEFINE l_disc_amt LIKE cashreceipt.cash_amt 
	DEFINE l_customer RECORD LIKE customer.* 
	DEFINE l_rec_cashreceipt RECORD LIKE cashreceipt.* 
	DEFINE l_rec_invoicehead RECORD LIKE invoicehead.* 
	DEFINE l_rec_invoicepay RECORD LIKE invoicepay.* 
	DEFINE l_rec_exchangevar RECORD LIKE exchangevar.* 
	DEFINE l_rec_araudit RECORD LIKE araudit.* 
--	DEFINE l_rec_arparms RECORD LIKE arparms.* 
	DEFINE l_kandoo_date LIKE invoicehead.paid_date 
	DEFINE l_base_inv_amt LIKE invoicepay.pay_amt 
	DEFINE l_base_cash_amt LIKE invoicepay.pay_amt 
	DEFINE l_err_message CHAR(40) 
	DEFINE l_query_text CHAR(200) 
	DEFINE i SMALLINT 
	DEFINE l_msg_num SMALLINT 
	DEFINE l_invoice_age SMALLINT 
	DEFINE l_receipt_age SMALLINT 

--	SELECT * INTO l_rec_arparms.* 
--	FROM arparms 
--	WHERE cmpy_code = p_company_cmpy_code 
--	AND parm_code = "1" 
--
--	IF sqlca.sqlcode = NOTFOUND THEN 
--		CALL fgl_winmessage("#5002 AR Parameters are NOT found",kandoomsg2("A",5002,""),"ERROR")		#5002 " AR Parameters are NOT found"
--		RETURN false 
--	END IF 

	LET l_query_text = 
		"SELECT * FROM cashreceipt ", 
		"WHERE cmpy_code = '",p_company_cmpy_code,"' ", 
		"AND cash_num = ? FOR UPDATE" 
	
	PREPARE s_cashreceipt FROM l_query_text 
	DECLARE c_cashreceipt CURSOR FOR s_cashreceipt
	 
	LET l_query_text = 
		"SELECT * FROM invoicehead ", 
		"WHERE cmpy_code = '",p_company_cmpy_code,"' ", 
		"AND inv_num = ? FOR UPDATE " 

	PREPARE s_invoicehead FROM l_query_text 
	DECLARE c_invoicehead CURSOR FOR s_invoicehead 
	
	LET l_query_text = 
		" SELECT * FROM customer ", 
		" WHERE cmpy_code = '",p_company_cmpy_code,"' ", 
		" AND cust_code = ? ", 
		" FOR UPDATE " 

	PREPARE s_customer FROM l_query_text 
	DECLARE c_customer CURSOR FOR s_customer 
	GOTO bypass 
	LABEL recovery: 

	IF status != 0 THEN  
		IF error_recover(l_err_message,status) != "Y" THEN 
			RETURN false 
		END IF 
	ELSE 
		ROLLBACK WORK 
		ERROR kandoomsg2("A",l_msg_num,l_err_message) 
		RETURN false 
	END IF 

	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 

	BEGIN WORK 
		CALL set_aging(p_company_cmpy_code,glob_rec_arparms.cust_age_date) 
		OPEN c_cashreceipt USING p_cash_num 
		FETCH c_cashreceipt INTO l_rec_cashreceipt.* 
		IF status = NOTFOUND THEN 
			LET l_msg_num = 7049		#7049 Cash receipt number : 1121 application complete
			LET l_err_message=p_cash_num 
			GOTO recovery 
		END IF 
		
		LET l_receipt_age = get_age_bucket(TRAN_TYPE_RECEIPT_CA,l_rec_cashreceipt.cash_date) 
		LET l_err_message = "A31b - Customer RECORD lock" 
		
		OPEN c_customer USING l_rec_cashreceipt.cust_code 
		FETCH c_customer INTO l_customer.* 
		
		FOR i = 1 TO 2 
			IF i = 1 THEN ## performs loop once FOR normal receipts 
				LET l_appl_amt = p_applied_amt 
				LET l_disc_amt = p_discount_amt 
			ELSE ## performs loop twice FOR dishonoured cheques 
				LET l_appl_amt = 0 - p_applied_amt 
				LET l_disc_amt = 0 - p_discount_amt 
			END IF 

			IF l_rec_cashreceipt.posted_flag = CASHRECEIPT_POST_FLAG_STATUS_POSTED_Y AND l_disc_amt != 0 THEN 
				LET l_msg_num=7049	#7049 Cashreceipt IS posted - No discount
				GOTO recovery 
			END IF 

			IF l_rec_cashreceipt.cash_amt >= 0 THEN 
				IF l_rec_cashreceipt.cash_amt <	(l_rec_cashreceipt.applied_amt+l_appl_amt) THEN 
					LET l_msg_num=7037	#7037 Attempt has been made TO over apply receipt :1234
					LET l_err_message=p_cash_num 
					GOTO recovery 
				END IF 
			ELSE 
				## code below handles negative receipts
				IF l_rec_cashreceipt.cash_amt >	(l_rec_cashreceipt.applied_amt+l_appl_amt) THEN 
					LET l_msg_num=7037	#7037 Attempt has been made TO over apply receipt :1234
					LET l_err_message=p_cash_num 
					GOTO recovery 
				END IF 
			END IF
			 
			LET l_err_message = " A31a - Invoice Header Update" 

			OPEN c_invoicehead USING p_inv_num 
			FETCH c_invoicehead INTO l_rec_invoicehead.* 
			IF status = NOTFOUND THEN 
				LET l_msg_num=7048 	#7048 Logic Error : Invoice 888 does NOT exist
				LET l_err_message=p_inv_num 
				GOTO recovery 
			END IF 

			LET l_invoice_age = get_age_bucket(TRAN_TYPE_INVOICE_IN,l_rec_invoicehead.due_date) 
			IF l_disc_amt IS NULL THEN 
				LET l_disc_amt = 0 
			END IF 

			IF l_appl_amt IS NULL THEN 
				LET l_appl_amt = 0 
			END IF 

			LET l_rec_invoicehead.paid_amt = l_rec_invoicehead.paid_amt	+ l_appl_amt + l_disc_amt 
			IF l_rec_cashreceipt.job_code IS NULL THEN 
				
				#-------------------------------------------
				# dont UPDATE paid VALUES IF payment IS dishonoured cheque
				IF l_rec_invoicehead.paid_amt > l_rec_invoicehead.total_amt THEN 
					LET l_msg_num=7039 	#7039 Attempt has been made TO over pay invoice 99999
					LET l_err_message=p_inv_num 
					GOTO recovery 
				END IF 
				
				IF l_rec_invoicehead.paid_amt != l_rec_invoicehead.total_amt 
				AND l_disc_amt > 0 THEN 
					LET l_msg_num=7040 	#7040 Invalid discount claim made on invoice: 1121
					LET l_err_message=p_inv_num 
					GOTO recovery 
				END IF 
				
				IF l_rec_invoicehead.total_amt = l_rec_invoicehead.paid_amt THEN 
					LET l_rec_invoicehead.paid_date = l_rec_cashreceipt.cash_date 
					SELECT max(pay_date) INTO l_kandoo_date 
					FROM invoicepay 
					WHERE cmpy_code = p_company_cmpy_code 
					AND cust_code = l_rec_invoicehead.cust_code 
					AND inv_num = l_rec_invoicehead.inv_num
					 
					IF l_kandoo_date > l_rec_cashreceipt.cash_date THEN 
						LET l_rec_invoicehead.paid_date = l_kandoo_date 
					END IF
					 
					LET l_customer.cred_given_num =	l_customer.cred_given_num 
						+ (l_rec_invoicehead.due_date - l_rec_invoicehead.inv_date) 
					
					LET l_customer.cred_taken_num = l_customer.cred_taken_num 
						+ (l_rec_cashreceipt.cash_date - l_rec_invoicehead.inv_date)
					 
					IF l_rec_cashreceipt.cash_date > l_rec_invoicehead.due_date THEN 
						LET l_customer.late_pay_num = l_customer.late_pay_num + 1 
					END IF
					 
				END IF 
			END IF
			 
			LET l_rec_invoicehead.seq_num = l_rec_invoicehead.seq_num + 1 
			LET l_rec_invoicehead.disc_taken_amt = l_rec_invoicehead.disc_taken_amt + l_disc_amt 
			
			UPDATE invoicehead 
			SET 
				paid_amt = l_rec_invoicehead.paid_amt, 
				paid_date = l_rec_invoicehead.paid_date, 
				seq_num = l_rec_invoicehead.seq_num, 
				disc_taken_amt = l_rec_invoicehead.disc_taken_amt 
			WHERE cmpy_code = p_company_cmpy_code 
			AND inv_num = p_inv_num 
			
			LET l_rec_invoicepay.cmpy_code = p_company_cmpy_code 
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
			LET l_err_message = "A31b - Invoice Payment Insert" 
			
			#--------------------------------------------------
			INSERT INTO invoicepay VALUES (l_rec_invoicepay.*) 
			
			IF l_rec_invoicehead.conv_qty IS NOT NULL THEN 
				IF l_rec_invoicehead.conv_qty != 0 THEN 
					LET l_base_inv_amt = l_rec_invoicepay.pay_amt / l_rec_invoicehead.conv_qty 
					LET l_base_cash_amt = l_rec_invoicepay.pay_amt / l_rec_cashreceipt.conv_qty 
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
				
				#------------------------------------------------------
				INSERT INTO exchangevar VALUES (l_rec_exchangevar.*) 
			END IF 
			
			LET l_err_message = " A31b - Cash Receipt UPDATE" 
			LET l_rec_cashreceipt.applied_amt = l_rec_cashreceipt.applied_amt	+ l_appl_amt 
			LET l_rec_cashreceipt.disc_amt = l_rec_cashreceipt.disc_amt + l_disc_amt
			 
			UPDATE cashreceipt SET 
				applied_amt = applied_amt + l_appl_amt, 
				disc_amt = disc_amt + l_disc_amt, 
				next_num = next_num + 1 
			WHERE cmpy_code = p_company_cmpy_code 
			AND cash_num = l_rec_cashreceipt.cash_num
			 
			IF l_rec_cashreceipt.job_code IS NULL OR i = 2 THEN 
				EXIT FOR 
			ELSE 
				OPEN c_cashreceipt USING l_rec_cashreceipt.job_code 
				FETCH c_cashreceipt INTO l_rec_cashreceipt.* 
				IF status = NOTFOUND THEN 
					EXIT FOR 
				END IF 
			END IF 
		END FOR 
		
		IF l_receipt_age <= 0 AND l_invoice_age <=0 AND l_disc_amt = 0 THEN 
		ELSE 
			CASE 
				WHEN l_receipt_age <= 0 
					LET l_customer.curr_amt = l_customer.curr_amt + l_appl_amt 
				WHEN (l_receipt_age >=1 AND l_receipt_age <=30 ) 
					LET l_customer.over1_amt = l_customer.over1_amt + l_appl_amt 
				WHEN l_receipt_age >=31 AND l_receipt_age <=60 
					LET l_customer.over30_amt = l_customer.over30_amt + l_appl_amt 
				WHEN l_receipt_age >=61 AND l_receipt_age <=90 
					LET l_customer.over60_amt = l_customer.over60_amt + l_appl_amt 
				OTHERWISE 
					LET l_customer.over90_amt = l_customer.over90_amt + l_appl_amt 
			END CASE
			 
			CASE 
				WHEN l_invoice_age <= 0 
					LET l_customer.curr_amt = l_customer.curr_amt - l_appl_amt 
				WHEN l_invoice_age >=1 AND l_invoice_age <=30 
					LET l_customer.over1_amt = l_customer.over1_amt - l_appl_amt 
				WHEN l_invoice_age >=31 AND l_invoice_age <=60 
					LET l_customer.over30_amt = l_customer.over30_amt - l_appl_amt 
				WHEN l_invoice_age >=61 AND l_invoice_age <=90 
					LET l_customer.over60_amt = l_customer.over60_amt - l_appl_amt 
				OTHERWISE 
					LET l_customer.over90_amt = l_customer.over90_amt - l_appl_amt 
			END CASE
			 
			IF l_disc_amt <> 0 THEN 
				CASE 
					WHEN l_invoice_age <= 0 
						LET l_customer.curr_amt = l_customer.curr_amt - l_disc_amt 
					WHEN l_invoice_age >=1 AND l_invoice_age <=30 
						LET l_customer.over1_amt = l_customer.over1_amt - l_disc_amt 
					WHEN l_invoice_age >=31 AND l_invoice_age <=60 
						LET l_customer.over30_amt = l_customer.over30_amt - l_disc_amt 
					WHEN l_invoice_age >=61 AND l_invoice_age <=90 
						LET l_customer.over60_amt = l_customer.over60_amt - l_disc_amt 
					OTHERWISE 
						LET l_customer.over90_amt = l_customer.over90_amt - l_disc_amt 
				END CASE
				 
				LET l_customer.bal_amt = l_customer.bal_amt - l_disc_amt 
				LET l_customer.next_seq_num = l_customer.next_seq_num + 1 
				LET l_rec_araudit.cmpy_code = p_company_cmpy_code 
				LET l_rec_araudit.tran_date = today 
				LET l_rec_araudit.cust_code = l_rec_cashreceipt.cust_code 
				LET l_rec_araudit.seq_num = l_customer.next_seq_num 
				LET l_rec_araudit.tran_type_ind = TRAN_TYPE_RECEIPT_CA 
				LET l_rec_araudit.source_num = l_rec_cashreceipt.cash_num 
				
				IF l_rec_cashreceipt.cash_amt < 0 THEN 
					LET l_rec_araudit.tran_text = "Reverse Disc." 
				ELSE 
					LET l_rec_araudit.tran_text = "Apply Discount" 
				END IF 
				
				LET l_rec_araudit.tran_amt = 0 - l_disc_amt 
				LET l_rec_araudit.entry_code = p_kandoouser_sign_on_code 
				LET l_rec_araudit.year_num = l_rec_cashreceipt.year_num 
				LET l_rec_araudit.period_num = l_rec_cashreceipt.period_num 
				LET l_rec_araudit.bal_amt = l_customer.bal_amt 
				LET l_rec_araudit.currency_code = l_customer.currency_code 
				LET l_rec_araudit.conv_qty = l_rec_invoicehead.conv_qty 
				LET l_rec_araudit.entry_date = today 
				LET l_err_message = "A31b - Audit Trail INSERT"
				 
				#---------------------------------------------
				INSERT INTO araudit VALUES (l_rec_araudit.*)
				 
			END IF 
		END IF
		 
		LET l_err_message = " A31b - Custmain Update"
		 
		UPDATE customer SET bal_amt = l_customer.bal_amt, 
			curr_amt = l_customer.curr_amt, 
			over1_amt = l_customer.over1_amt, 
			over30_amt = l_customer.over30_amt, 
			over60_amt = l_customer.over60_amt, 
			over90_amt = l_customer.over90_amt, 
			cred_bal_amt = l_customer.cred_limit_amt - l_customer.bal_amt, 
			late_pay_num = l_customer.late_pay_num, 
			next_seq_num = l_customer.next_seq_num, 
			cred_given_num = l_customer.cred_given_num, 
			cred_taken_num = l_customer.cred_taken_num 
		WHERE cmpy_code = p_company_cmpy_code 
		AND cust_code = l_rec_cashreceipt.cust_code 

	COMMIT WORK 

	WHENEVER ERROR stop 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

	RETURN true 
END FUNCTION
######################################################################################
# END FUNCTION receipt_apply(p_company_cmpy_code,p_kandoouser_sign_on_code,p_cash_num,p_inv_num,p_applied_amt, p_discount_amt)
######################################################################################