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
# \brief module A39b - Cash Receipt Unapply
# ------------   allows the user TO unapply Cash Receipts TO the invoices
#
# NB1 : Posted cashreceipts.  It IS valid TO unapply a posted cashreceipt
#       as long as there IS no settlement discount.  Discount IS posted TO
#       GL with a receipt AND hence removal of posted discount in AR puts
#       subsidiary ledger out of balance.
#
# NB2 : Dishonoured Cheques.  These are handled in AR as two cashreceipts,
#       the original cheque AND the negative correcting entry. The negative
#       entry IS joined via cashreceipt.job_code TO the original entry.
#       The user only ever sees the original entry AND any applications OR
#       unapplications TO the original automatically applies/unapplies
#       the negative entry TO the same invoices.
###########################################################################

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl" 
GLOBALS "../ar/A3_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/A39_GLOBALS.4gl" 
###########################################################################
# MODULE Scope Variables
###########################################################################

###########################################################################
# FUNCTION unapp_cash(p_company_cmpy_code,p_cust_code,p_cash_num,p_kandoouser_sign_on_code)
#
#
###########################################################################
FUNCTION unapp_cash(p_company_cmpy_code,p_cust_code,p_cash_num,p_kandoouser_sign_on_code) 
	#
	# UPDATE procedure IS .
	#  1. lock cashreceipt table
	#  2. FOREACH application
	#  3.    FETCH invoicehead
	#  4.    UPDATE invoicehead
	#  5.    total reversed discount
	#  6. reverse exchange variance entry
	#  7. UPDATE cashreceipt
	#  8. IF dishonoured THEN rpt steps 1 -> 7 (cashreceipt = negative entry)
	#  9. IF any discount reversed THEN OUTPUT araudit/UPDATE customer
	#
	DEFINE p_company_cmpy_code LIKE company.cmpy_code 
	DEFINE p_cust_code LIKE customer.cust_code 
	DEFINE p_cash_num LIKE cashreceipt.cash_num 
	DEFINE p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code 

	DEFINE l_invoicehead RECORD LIKE invoicehead.* 
	DEFINE l_rec_invoicepay RECORD LIKE invoicepay.* 
	DEFINE l_rec_exchangevar RECORD LIKE exchangevar.* 
	DEFINE l_rec_cashreceipt RECORD LIKE cashreceipt.* 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_araudit RECORD LIKE araudit.* 
--	DEFINE l_rec_arparms RECORD LIKE arparms.* 
	DEFINE l_unapplied_amt DECIMAL(12,2) ## unapplied OF this receipt 
	DEFINE l_revdisc_amt DECIMAL(12,2) ## discount reversed this receipt 
	DEFINE l_totdisc_amt DECIMAL(12,2) ## total discount reversed 
	DEFINE l_base_curr_code LIKE glparms.base_currency_code 
	DEFINE l_query_text STRING --CHAR(200) 
	DEFINE l_err_message CHAR(40) 
	DEFINE l_invoice_age SMALLINT 
	DEFINE l_receipt_age SMALLINT 
	DEFINE i SMALLINT 
	DEFINE l_paid_amt LIKE invoicehead.paid_amt 
	DEFINE l_cust_code LIKE customer.cust_code 
	DEFINE l_inv_num LIKE invoicehead.inv_num 
	DEFINE l_paid_date LIKE invoicehead.paid_date 

--	SELECT * INTO l_rec_arparms.* 
--	FROM arparms 
--	WHERE cmpy_code = p_company_cmpy_code 
--	AND parm_code = "1" 
--	IF sqlca.sqlcode = NOTFOUND THEN 
--		ERROR kandoomsg2("A",5002,"")		#5002 " AR Parameters are NOT found"
--		SLEEP 3
--		RETURN 
--	END IF 
	
	SELECT base_currency_code INTO l_base_curr_code 
	FROM glparms 
	WHERE cmpy_code = p_company_cmpy_code 
	AND key_code = "1" 
	
	## only DECLARE cursors once
	## cashreceipt
	LET l_query_text = "SELECT * FROM cashreceipt ", 
	"WHERE cmpy_code= '",p_company_cmpy_code,"' ", 
	"AND cash_num= ? ", 
	"FOR UPDATE " 
	PREPARE s_cashreceipt FROM l_query_text 
	DECLARE c_cashreceipt CURSOR FOR s_cashreceipt 
	
	## invoicehead
	LET l_query_text = "SELECT * FROM invoicehead ", 
	"WHERE cmpy_code= '",p_company_cmpy_code,"' ", 
	"AND inv_num= ? ", 
	"FOR UPDATE " 
	PREPARE s_invoicehead FROM l_query_text 
	DECLARE c_invoicehead CURSOR FOR s_invoicehead 
	
	## invoicepay
	LET l_query_text = "SELECT * FROM invoicepay ", 
	"WHERE cmpy_code='",p_company_cmpy_code,"' ", 
	"AND cust_code=? ", 
	"AND ref_num=? ", 
	"AND pay_type_ind='CA' ", 
	"AND rev_flag IS NULL ", 
	"FOR UPDATE " 

	PREPARE s_invoicepay FROM l_query_text 
	DECLARE c_invoicepay CURSOR FOR s_invoicepay 
--	GOTO bypass 
--	LABEL recovery: 
--	IF error_recover(l_err_message, status) != "Y" THEN 
--		RETURN 
--	END IF 
--	LABEL bypass: 
--	WHENEVER ERROR GOTO recovery 

	BEGIN WORK 

		CALL set_aging(p_company_cmpy_code,glob_rec_arparms.cust_age_date) 
		DECLARE c_customer CURSOR FOR 
		SELECT * FROM customer 
		WHERE cust_code = p_cust_code 
		AND cmpy_code = p_company_cmpy_code 
		FOR UPDATE 
	
		OPEN c_cashreceipt USING p_cash_num 
	
		LET l_totdisc_amt = 0 

		OPEN c_customer 
		FETCH c_customer INTO l_rec_customer.* 
		IF sqlca.sqlcode = NOTFOUND THEN 
			LET l_err_message = "A39 - Logic Error: Customer does NOT exist"
			CALL fgl_winmessage("ERROR #93223",l_err_message,"ERROR") 
--			GOTO recovery 
		END IF 

		FOR i = 1 TO 2 
			LET l_unapplied_amt = 0 
			LET l_revdisc_amt = 0 
			
			## performs "for" loop once FOR normal receipts
			## performs "for" loop twice FOR dishonoured cheques
			LET l_err_message = "A39b - Cash Receipt Update" 
			FETCH c_cashreceipt INTO l_rec_cashreceipt.* 
			IF sqlca.sqlcode = NOTFOUND THEN 
				LET l_err_message = "A39 - Logic Error: Receipt does NOT exist"
				CALL fgl_winmessage("ERROR #93224",l_err_message,"ERROR")  
				--GOTO recovery 
			END IF 
			
			LET l_receipt_age = get_age_bucket(TRAN_TYPE_RECEIPT_CA,l_rec_cashreceipt.cash_date) 
			OPEN c_invoicepay USING l_rec_cashreceipt.cust_code CLIPPED,	l_rec_cashreceipt.cash_num 
			
			FOREACH c_invoicepay INTO l_rec_invoicepay.* 
				LET l_err_message = " A39b - Invoice Header Update" 
				LET l_cust_code = l_rec_invoicepay.cust_code 
				LET l_inv_num = l_rec_invoicepay.inv_num 

				OPEN c_invoicehead USING l_rec_invoicepay.inv_num 
				FETCH c_invoicehead INTO l_invoicehead.* 
				IF sqlca.sqlcode = 0 THEN 
					LET l_invoice_age = get_age_bucket(TRAN_TYPE_INVOICE_IN,l_invoicehead.due_date) 
					
					IF l_rec_invoicepay.disc_amt IS NULL THEN 
						LET l_rec_invoicepay.disc_amt = 0 
					END IF
					 
					IF l_rec_invoicepay.pay_amt IS NULL THEN 
						LET l_rec_invoicepay.pay_amt = 0 
					END IF 

					LET l_paid_amt = 
						l_invoicehead.paid_amt 
						- l_rec_invoicepay.pay_amt 
						- l_rec_invoicepay.disc_amt 

					IF l_paid_amt < 0 AND l_rec_cashreceipt.job_code IS NULL THEN 
						ERROR kandoomsg2("A",9159,l_invoicehead.inv_num) 	#A9159 Unapply Negative Cashreceipt FOR Invoice first
						ROLLBACK WORK 

						RETURN 

					ELSE 
						LET l_revdisc_amt = l_revdisc_amt + l_rec_invoicepay.disc_amt 
						LET l_unapplied_amt = l_unapplied_amt+l_rec_invoicepay.pay_amt 
						LET l_invoicehead.paid_amt = l_paid_amt 
						LET l_invoicehead.seq_num = l_invoicehead.seq_num + 1 
						LET l_invoicehead.disc_taken_amt =	l_invoicehead.disc_taken_amt - l_rec_invoicepay.disc_amt 

						UPDATE invoicehead 
						SET 
							paid_amt = l_invoicehead.paid_amt, 
							seq_num = l_invoicehead.seq_num, 
							disc_taken_amt = l_invoicehead.disc_taken_amt 
						WHERE cmpy_code = p_company_cmpy_code 
						AND inv_num = l_rec_invoicepay.inv_num 

					END IF 

					CASE 
						WHEN l_receipt_age <= 0 
							LET l_rec_customer.curr_amt = l_rec_customer.curr_amt- l_rec_invoicepay.pay_amt 
						WHEN l_receipt_age >=1 AND l_receipt_age <=30 
							LET l_rec_customer.over1_amt = l_rec_customer.over1_amt-l_rec_invoicepay.pay_amt 
						WHEN l_receipt_age >=31 AND l_receipt_age <=60 
							LET l_rec_customer.over30_amt= l_rec_customer.over30_amt-l_rec_invoicepay.pay_amt 
						WHEN l_receipt_age >=61 AND l_receipt_age <=90 
							LET l_rec_customer.over60_amt= l_rec_customer.over60_amt-l_rec_invoicepay.pay_amt 
						OTHERWISE 
							LET l_rec_customer.over90_amt= l_rec_customer.over90_amt-l_rec_invoicepay.pay_amt 
					END CASE 

					CASE 
						WHEN l_invoice_age <=0 
							LET l_rec_customer.curr_amt = l_rec_customer.curr_amt + l_rec_invoicepay.pay_amt + l_rec_invoicepay.disc_amt 
						WHEN l_invoice_age >=1 AND l_invoice_age <=30 
							LET l_rec_customer.over1_amt = l_rec_customer.over1_amt+l_rec_invoicepay.pay_amt + l_rec_invoicepay.disc_amt 
						WHEN l_invoice_age >=31 AND l_invoice_age <=60 
							LET l_rec_customer.over30_amt= l_rec_customer.over30_amt+l_rec_invoicepay.pay_amt + l_rec_invoicepay.disc_amt 
						WHEN l_invoice_age >=61 AND l_invoice_age <=90 
							LET l_rec_customer.over60_amt= l_rec_customer.over60_amt+l_rec_invoicepay.pay_amt + l_rec_invoicepay.disc_amt 
						OTHERWISE 
							LET l_rec_customer.over90_amt= l_rec_customer.over90_amt+l_rec_invoicepay.pay_amt	+ l_rec_invoicepay.disc_amt 
					END CASE 

					UPDATE invoicepay SET rev_flag = "Y" 
					WHERE cmpy_code = p_company_cmpy_code 
					AND invoicepay.cust_code = l_rec_cashreceipt.cust_code 
					AND inv_num = l_invoicehead.inv_num 
					AND ref_num = l_rec_cashreceipt.cash_num 
					AND appl_num = l_rec_invoicepay.appl_num 

					LET l_rec_cashreceipt.next_num = l_rec_cashreceipt.next_num + 1 
					LET l_rec_invoicepay.appl_num = 0 
					LET l_rec_invoicepay.pay_amt = 0 - l_rec_invoicepay.pay_amt 
					LET l_rec_invoicepay.disc_amt = 0 - l_rec_invoicepay.disc_amt 
					LET l_rec_invoicepay.apply_num = l_rec_cashreceipt.next_num 
					LET l_rec_invoicepay.pay_date = today 
					LET l_rec_invoicepay.rev_flag = "Y" 
					LET l_rec_invoicepay.stat_date = NULL 
					LET l_rec_invoicepay.on_state_flag = "N"
					 
					INSERT INTO invoicepay VALUES (l_rec_invoicepay.*) 

					SELECT max(pay_date) 
					INTO l_paid_date 
					FROM invoicepay ip 
					WHERE ip.cmpy_code = p_company_cmpy_code 
					AND ip.cust_code = l_cust_code 
					AND ip.inv_num = l_inv_num 
					AND ip.rev_flag IS NULL 

					IF status = NOTFOUND THEN 
						LET l_paid_date = NULL 
					END IF 

					UPDATE invoicehead 
					SET paid_date = l_paid_date 
					WHERE invoicehead.cmpy_code = p_company_cmpy_code 
					AND invoicehead.cust_code = l_cust_code 
					AND invoicehead.inv_num = l_inv_num 
				END IF 
			END FOREACH 

			IF l_rec_cashreceipt.currency_code != l_base_curr_code THEN 
				# The following source IS summing the result of all exchangevars FOR
				# each receipt AND inserting a reversing entry.
				# This IS done b/c we are unable TO identify the most recent receipt
				# applications TO correctly calculate the exchange variation.
				DECLARE c_exchangevar CURSOR FOR 
				SELECT unique 
					year_num, 
					period_num, 
					source_ind, 
					tran_date, 
					ref_code, 
					tran_type1_ind, 
					ref1_num, 
					tran_type2_ind, 
					ref2_num, 
					currency_code 
				FROM exchangevar 
				WHERE cmpy_code = p_company_cmpy_code 
				AND tran_type2_ind = TRAN_TYPE_RECEIPT_CA 
				AND ref2_num = p_cash_num 

				FOREACH c_exchangevar INTO 
					l_rec_exchangevar.year_num, 
					l_rec_exchangevar.period_num, 
					l_rec_exchangevar.source_ind, 
					l_rec_exchangevar.tran_date, 
					l_rec_exchangevar.ref_code, 
					l_rec_exchangevar.tran_type1_ind, 
					l_rec_exchangevar.ref1_num, 
					l_rec_exchangevar.tran_type2_ind, 
					l_rec_exchangevar.ref2_num, 
					l_rec_exchangevar.currency_code 

					SELECT sum(0 - exchangevar_amt) 
					INTO l_rec_exchangevar.exchangevar_amt 
					FROM exchangevar 
					WHERE cmpy_code = p_company_cmpy_code 
					AND tran_type2_ind = TRAN_TYPE_RECEIPT_CA 
					AND ref2_num = p_cash_num 
					AND ref1_num = l_rec_exchangevar.ref1_num 
					
					IF l_rec_exchangevar.exchangevar_amt != 0 THEN 
						LET l_rec_exchangevar.cmpy_code = p_company_cmpy_code 
						LET l_rec_exchangevar.posted_flag = "N" 
						LET l_rec_exchangevar.post_date= NULL 
						LET l_rec_exchangevar.jour_num= NULL 
						#-------------------------------
						INSERT INTO exchangevar VALUES (l_rec_exchangevar.*) 
					END IF 

				END FOREACH 

			END IF 

			LET l_err_message = " A39b - Cash Receipt UPDATE" 
			LET l_rec_cashreceipt.applied_amt = l_rec_cashreceipt.applied_amt	- l_unapplied_amt 
			LET l_rec_cashreceipt.disc_amt = l_rec_cashreceipt.disc_amt - l_revdisc_amt 
			
#I have to comment this - it was triggered for all SUNDRY receipts
#--			IF l_rec_cashreceipt.applied_amt != 0 OR l_rec_cashreceipt.disc_amt != 0 THEN 
#--				LET l_err_message = "A39 - Logic Error: \nReceipt apply sum incorrect"
#--				 CALL fgl_winmessage("ERROR #93225",l_err_message,"ERROR")
#--				--GOTO recovery 
#--			END IF 

			UPDATE cashreceipt 
			SET 
				applied_amt = 0, 
				disc_amt = 0, 
				next_num = l_rec_cashreceipt.next_num 
			WHERE cmpy_code = p_company_cmpy_code 
			AND cash_num = l_rec_cashreceipt.cash_num 

			LET l_totdisc_amt = l_totdisc_amt + l_revdisc_amt 
			
			IF l_rec_cashreceipt.job_code IS NOT NULL THEN 
				
				# Perform unapply again negative cashreceipt entry
				OPEN c_cashreceipt USING l_rec_cashreceipt.job_code 
			ELSE 
				EXIT FOR 
			END IF 
		END FOR 
		
		### Do NOT remove following code - <Suse> bug
		IF true THEN 
		END IF 
		
		UPDATE customer 
		SET 
			curr_amt = l_rec_customer.curr_amt, 
			over1_amt = l_rec_customer.over1_amt, 
			over30_amt=l_rec_customer.over30_amt, 
			over60_amt=l_rec_customer.over60_amt, 
			over90_amt = l_rec_customer.over90_amt 
		WHERE cust_code = l_rec_cashreceipt.cust_code 
		AND cmpy_code = p_company_cmpy_code 
		CLOSE c_customer 
		
		IF l_totdisc_amt != 0 THEN 
			LET l_err_message = "A39b - Customer UPDATE" 
			
			OPEN c_customer 
			FETCH c_customer INTO l_rec_customer.* 
			
			LET l_rec_customer.bal_amt = l_rec_customer.bal_amt + l_totdisc_amt 
			LET l_rec_customer.next_seq_num = l_rec_customer.next_seq_num + 1 
			
			UPDATE customer 
			SET 
				bal_amt = l_rec_customer.bal_amt, 
				cred_bal_amt = l_rec_customer.cred_limit_amt- l_rec_customer.bal_amt, 
				next_seq_num = l_rec_customer.next_seq_num 
			WHERE cust_code = l_rec_cashreceipt.cust_code 
			AND cmpy_code = p_company_cmpy_code 

			LET l_err_message = "A39b - AR Audit Insert" 
			LET l_rec_araudit.cmpy_code = p_company_cmpy_code 
			LET l_rec_araudit.tran_date = today 
			LET l_rec_araudit.cust_code = l_rec_cashreceipt.cust_code 
			LET l_rec_araudit.seq_num = l_rec_customer.next_seq_num 
			LET l_rec_araudit.tran_type_ind = TRAN_TYPE_RECEIPT_CA 
			LET l_rec_araudit.source_num = l_rec_cashreceipt.cash_num 
			LET l_rec_araudit.tran_amt = l_totdisc_amt 

			IF l_rec_araudit.tran_amt > 0 THEN 
				LET l_rec_araudit.tran_text = "Rev. Discount" 
			ELSE 
				LET l_rec_araudit.tran_text = "Apply Discount" 
			END IF 

			LET l_rec_araudit.entry_code = p_kandoouser_sign_on_code 
			LET l_rec_araudit.year_num = l_rec_cashreceipt.year_num 
			LET l_rec_araudit.period_num = l_rec_cashreceipt.period_num 
			LET l_rec_araudit.bal_amt = l_rec_customer.bal_amt 
			LET l_rec_araudit.currency_code = l_rec_customer.currency_code 
			LET l_rec_araudit.conv_qty = l_rec_cashreceipt.conv_qty 
			LET l_rec_araudit.entry_date = today 

			#----------------------------------------
			INSERT INTO araudit VALUES (l_rec_araudit.*) 
		END IF 

	COMMIT WORK 

END FUNCTION 
############################################################
# END FUNCTION unapp_cash(p_company_cmpy_code,p_cust_code,p_cash_num,p_kandoouser_sign_on_code)
############################################################