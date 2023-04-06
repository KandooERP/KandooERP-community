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
GLOBALS "../ar/A4_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/A49_GLOBALS.4gl"

#################################################################
# MODULE scope variables
#################################################################

#################################################################
# FUNCTION unapply_credit_from_invoice_receipt(p_company_cmpy_code, p_cust, p_cred_recnum, p_kandoouser_sign_on_code)
#
# \brief module A49b allows the user TO unapply Credit Headers TO the invoices
#              The user can unapply cred FROM any receipt
#################################################################
FUNCTION unapply_credit_from_invoice_receipt(p_company_cmpy_code, p_cust, p_cred_recnum, p_kandoouser_sign_on_code) 
	DEFINE p_company_cmpy_code LIKE company.cmpy_code 
	DEFINE p_cust LIKE customer.cust_code 
	DEFINE p_cred_recnum LIKE credithead.cred_num 
	DEFINE p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code 

	DEFINE l_rec_invoicepay RECORD LIKE invoicepay.* 
	DEFINE l_rec_exchangevar RECORD LIKE exchangevar.* 
	DEFINE l_rec_credithead RECORD LIKE credithead.* 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_araudit RECORD LIKE araudit.* 
	DEFINE l_rec_cred RECORD 
		inv_num LIKE invoicehead.inv_num, 
		purchase_code LIKE invoicehead.purchase_code, 
		total_amt LIKE invoicehead.total_amt, 
		paid_amt LIKE invoicehead.paid_amt 
	END RECORD 
	DEFINE l_try_again CHAR(1) 
	DEFINE l_err_message CHAR(40) 
	DEFINE l_appl_amt DECIMAL(12,2) 
	DEFINE l_discount_amt DECIMAL(12,2) 
	DEFINE l_save_dis LIKE invoicehead.total_amt 
	DEFINE l_save_amt LIKE invoicehead.total_amt 
	DEFINE l_save_inv LIKE invoicehead.inv_num 
	DEFINE l_payment SMALLINT 
	#DEFINE l_latep SMALLINT
	#DEFINE l_ndct SMALLINT
	#DEFINE l_ndcg SMALLINT
	DEFINE i SMALLINT 
	DEFINE l_arr_size SMALLINT 

	DEFINE l_number SMALLINT 
	DEFINE l_idx SMALLINT 
	DEFINE l_id_flag SMALLINT 
	DEFINE l_cnt SMALLINT 
	DEFINE l_err_flag SMALLINT 
	DEFINE l_credit_age INTEGER 
	DEFINE l_invoice_age INTEGER 
	DEFINE l_sel_text CHAR(200) 
	DEFINE l_cust_code LIKE customer.cust_code 
	DEFINE l_inv_num LIKE invoicehead.inv_num 
	DEFINE l_paid_date LIKE invoicehead.paid_date 

	CALL arparms_init() # AR/Account Receivable Parameters (arparms)

--	GOTO bypass 
--	
--	LABEL recovery: 
--	LET l_try_again = error_recover(l_err_message, status) 
--	IF l_try_again != "Y" THEN 
--		EXIT PROGRAM 
--	END IF 
	
--	LABEL bypass: 
--	WHENEVER ERROR GOTO recovery 

	BEGIN WORK 
		CALL set_aging(p_company_cmpy_code,glob_rec_arparms.cust_age_date) 
		LET l_err_message = "A49b - Credit Header UPDATE" 

		DECLARE c_credithead CURSOR FOR 
		SELECT * FROM credithead 
		WHERE cmpy_code = p_company_cmpy_code 
		AND cred_num = p_cred_recnum 
		FOR UPDATE 

		OPEN c_credithead 
		FETCH c_credithead INTO l_rec_credithead.* 

		LET l_appl_amt = 0 
		LET l_discount_amt = 0 
		LET l_payment = l_payment + 1 
		#LET l_ndcg = 0
		#LET ndct = 0
		#LET l_latep = 0

		LET l_credit_age = get_age_bucket(TRAN_TYPE_CREDIT_CR,l_rec_credithead.cred_date) 
		LET l_err_message = " A49b - Customer Header Update" 

		DECLARE c_customer CURSOR FOR 
		SELECT * FROM customer 
		WHERE customer.cust_code = l_rec_credithead.cust_code 
		AND customer.cmpy_code = p_company_cmpy_code 

		FOR UPDATE 
		DECLARE c_invoicepay CURSOR FOR 
		SELECT * FROM invoicepay 
		WHERE invoicepay.cmpy_code = p_company_cmpy_code 
		AND invoicepay.cust_code = l_rec_credithead.cust_code 
		AND invoicepay.ref_num = p_cred_recnum 
		AND invoicepay.pay_type_ind = TRAN_TYPE_CREDIT_CR 
		AND invoicepay.rev_flag IS NULL 

		FOR UPDATE 
		OPEN c_customer 
		FETCH c_customer INTO l_rec_customer.* 

		FOREACH c_invoicepay INTO l_rec_invoicepay.* 
			LET l_cust_code = l_rec_invoicepay.cust_code 
			LET l_inv_num = l_rec_invoicepay.inv_num 
			LET l_err_message = " A49b - Invoice Header Update" 

			DECLARE c_invoicehead CURSOR FOR 
			SELECT * FROM invoicehead 
			WHERE invoicehead.cmpy_code = p_company_cmpy_code 
			AND invoicehead.inv_num = l_rec_invoicepay.inv_num 
			FOR UPDATE 
			OPEN c_invoicehead 
			FETCH c_invoicehead INTO glob_rec_invoicehead.* 

			LET l_invoice_age = get_age_bucket(TRAN_TYPE_INVOICE_IN,glob_rec_invoicehead.due_date) 
			LET l_discount_amt = l_discount_amt + l_rec_invoicepay.disc_amt 
			LET l_appl_amt = l_appl_amt + l_rec_invoicepay.pay_amt 

			IF l_rec_invoicepay.pay_amt IS NULL THEN 
				LET l_rec_invoicepay.pay_amt = 0 
			END IF 

			IF l_rec_invoicepay.disc_amt IS NULL THEN 
				LET l_rec_invoicepay.disc_amt = 0 
			END IF 

			LET glob_rec_invoicehead.paid_amt =	glob_rec_invoicehead.paid_amt -	l_rec_invoicepay.pay_amt - l_rec_invoicepay.disc_amt 
			LET glob_rec_invoicehead.seq_num = glob_rec_invoicehead.seq_num + 1 
			LET glob_rec_invoicehead.disc_taken_amt = glob_rec_invoicehead.disc_taken_amt -	l_rec_invoicepay.disc_amt 

			UPDATE invoicehead 
			SET 
				paid_amt = glob_rec_invoicehead.paid_amt, 
				seq_num = glob_rec_invoicehead.seq_num, 
				disc_taken_amt =glob_rec_invoicehead.disc_taken_amt 
			WHERE cmpy_code = p_company_cmpy_code 
			AND inv_num = l_rec_invoicepay.inv_num 

			CLOSE c_invoicehead 

			IF l_credit_age <= 0 AND l_invoice_age <=0 THEN 
			ELSE 
				CASE 
					WHEN l_credit_age <= 0 
						LET l_rec_customer.curr_amt = l_rec_customer.curr_amt - l_rec_invoicepay.pay_amt 
					WHEN l_credit_age >=1 AND l_credit_age <=30 
						LET l_rec_customer.over1_amt = l_rec_customer.over1_amt - l_rec_invoicepay.pay_amt 
					WHEN l_credit_age >=31 AND l_credit_age <=60 
						LET l_rec_customer.over30_amt= l_rec_customer.over30_amt - l_rec_invoicepay.pay_amt 
					WHEN l_credit_age >=61 AND l_credit_age <=90 
						LET l_rec_customer.over60_amt= l_rec_customer.over60_amt - l_rec_invoicepay.pay_amt 
					OTHERWISE 
						LET l_rec_customer.over90_amt= l_rec_customer.over90_amt - l_rec_invoicepay.pay_amt 
				END CASE 

				CASE 
					WHEN l_invoice_age <=0 
						LET l_rec_customer.curr_amt = l_rec_customer.curr_amt + l_rec_invoicepay.pay_amt + l_rec_invoicepay.disc_amt 
					WHEN l_invoice_age >=1 AND l_invoice_age <=30 
						LET l_rec_customer.over1_amt = l_rec_customer.over1_amt + l_rec_invoicepay.pay_amt	+ l_rec_invoicepay.disc_amt 
					WHEN l_invoice_age >=31 AND l_invoice_age <=60 
						LET l_rec_customer.over30_amt= l_rec_customer.over30_amt + l_rec_invoicepay.pay_amt	+ l_rec_invoicepay.disc_amt 
					WHEN l_invoice_age >=61 AND l_invoice_age <=90 
						LET l_rec_customer.over60_amt= l_rec_customer.over60_amt + l_rec_invoicepay.pay_amt + l_rec_invoicepay.disc_amt 
					OTHERWISE 
						LET l_rec_customer.over90_amt= l_rec_customer.over90_amt + l_rec_invoicepay.pay_amt + l_rec_invoicepay.disc_amt 
				END CASE 

				UPDATE customer 
				SET 
					curr_amt = l_rec_customer.curr_amt, 
					over1_amt = l_rec_customer.over1_amt, 
					over30_amt = l_rec_customer.over30_amt, 
					over60_amt = l_rec_customer.over60_amt, 
					over90_amt = l_rec_customer.over90_amt 
				WHERE customer.cust_code = l_rec_credithead.cust_code 
				AND customer.cmpy_code = p_company_cmpy_code 
			END IF 

			UPDATE invoicepay SET rev_flag = "Y" 
			WHERE cmpy_code = p_company_cmpy_code 
			AND invoicepay.cust_code = l_rec_credithead.cust_code 
			AND ref_num = l_rec_credithead.cred_num 
			AND appl_num = l_rec_invoicepay.appl_num 

			LET l_rec_credithead.next_num = l_rec_credithead.next_num + 1 
			LET l_rec_invoicepay.appl_num = 0 
			LET l_rec_invoicepay.pay_amt = 0 - l_rec_invoicepay.pay_amt 
			LET l_rec_invoicepay.disc_amt = 0 - l_rec_invoicepay.disc_amt 
			LET l_rec_invoicepay.apply_num = l_rec_credithead.next_num 
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
		END FOREACH 

		CLOSE c_customer 

		IF l_discount_amt != 0 THEN 
			LET l_err_message = "A49b - Customer UPDATE" 
			LET l_rec_customer.bal_amt = l_rec_customer.bal_amt + l_discount_amt 
			LET l_rec_customer.cred_bal_amt =	l_rec_customer.cred_bal_amt + l_discount_amt 

			IF year(l_rec_credithead.cred_date) >	year(l_rec_customer.last_pay_date) THEN 
				LET l_rec_customer.ytdp_amt = 0 
			END IF 

			LET l_rec_customer.ytdp_amt = l_rec_customer.ytdp_amt -		l_discount_amt
			 
			IF (year(l_rec_credithead.cred_date) > year(l_rec_customer.last_pay_date) 
			OR month(l_rec_credithead.cred_date)>month(l_rec_customer.last_pay_date)) 
			THEN 
				LET l_rec_customer.mtdp_amt = 0 
			END IF 
			
			LET l_rec_customer.mtdp_amt = l_rec_customer.mtdp_amt - l_discount_amt 
			LET l_rec_customer.next_seq_num = l_rec_customer.next_seq_num + 1 
			LET l_err_message = " A49b - Custmain Update" 

			UPDATE customer 
			SET 
				bal_amt = l_rec_customer.bal_amt, 
				cred_bal_amt = l_rec_customer.cred_bal_amt, 
				mtdp_amt = l_rec_customer.mtdp_amt, 
				ytdp_amt = l_rec_customer.ytdp_amt, 
				next_seq_num = l_rec_customer.next_seq_num 
			WHERE customer.cust_code = l_rec_credithead.cust_code 
			AND customer.cmpy_code = p_company_cmpy_code 

			LET l_rec_araudit.cmpy_code = p_company_cmpy_code 
			LET l_rec_araudit.tran_date = today 
			LET l_rec_araudit.cust_code = l_rec_credithead.cust_code 
			LET l_rec_araudit.seq_num = l_rec_customer.next_seq_num 
			LET l_rec_araudit.tran_type_ind = TRAN_TYPE_CREDIT_CR 
			LET l_rec_araudit.source_num = l_rec_credithead.cred_num 
			LET l_rec_araudit.tran_text = "Rev. Discount" 
			LET l_rec_araudit.tran_amt = l_discount_amt 
			LET l_rec_araudit.entry_code = p_kandoouser_sign_on_code 
			LET l_rec_araudit.year_num = l_rec_credithead.year_num 
			LET l_rec_araudit.period_num = l_rec_credithead.period_num 
			LET l_rec_araudit.bal_amt = l_rec_customer.bal_amt 
			LET l_rec_araudit.currency_code = l_rec_customer.currency_code 
			LET l_rec_araudit.conv_qty = l_rec_credithead.conv_qty 
			LET l_rec_araudit.entry_date = today 
			LET l_err_message = "A49b - Daily Log INSERT" 

			#INSERT -------------------------------------------
			INSERT INTO araudit VALUES (l_rec_araudit.*) 

		END IF 

		# The following source IS summing the result of all exchangevars FOR
		# each credit AND inserting a reversing entry.
		# This IS done because we are unable TO identify the most recent credit
		# applications TO correctly calculate the exchange variation.
		DECLARE exch_curs CURSOR FOR 
		SELECT unique 
			cmpy_code, 
			year_num, 
			period_num, 
			source_ind, 
			tran_date, 
			ref_code, 
			tran_type1_ind, 
			ref1_num, 
			tran_type2_ind, 
			ref2_num, 
			currency_code, 
			posted_flag, 
			jour_num, 
			post_date 
		INTO 
			l_rec_exchangevar.cmpy_code, 
			l_rec_exchangevar.year_num, 
			l_rec_exchangevar.period_num, 
			l_rec_exchangevar.source_ind, 
			l_rec_exchangevar.tran_date, 
			l_rec_exchangevar.ref_code, 
			l_rec_exchangevar.tran_type1_ind, 
			l_rec_exchangevar.ref1_num, 
			l_rec_exchangevar.tran_type2_ind, 
			l_rec_exchangevar.ref2_num, 
			l_rec_exchangevar.currency_code, 
			l_rec_exchangevar.posted_flag, 
			l_rec_exchangevar.jour_num, 
			l_rec_exchangevar.post_date 
		FROM exchangevar 
		WHERE cmpy_code = p_company_cmpy_code 
		AND tran_type2_ind = TRAN_TYPE_CREDIT_CR 
		AND ref2_num = p_cred_recnum 

		FOREACH exch_curs 
			SELECT sum(0 - exchangevar_amt) INTO l_rec_exchangevar.exchangevar_amt 
			FROM exchangevar 
			WHERE cmpy_code = p_company_cmpy_code 
			AND tran_type2_ind = TRAN_TYPE_CREDIT_CR 
			AND ref2_num = p_cred_recnum 
			AND ref1_num = l_rec_exchangevar.ref1_num #unique invoice 

			IF l_rec_exchangevar.exchangevar_amt != 0 THEN 
				LET l_rec_exchangevar.posted_flag = "N" 
				INSERT INTO exchangevar VALUES (l_rec_exchangevar.*) 
			END IF 
		END FOREACH 

		LET l_err_message = " A49b - Credit Header UPDATE" 
		LET l_rec_credithead.appl_amt = l_rec_credithead.appl_amt - l_appl_amt 
		LET l_rec_credithead.disc_amt = l_rec_credithead.disc_amt - l_discount_amt 

		IF l_rec_credithead.appl_amt != 0	OR l_rec_credithead.disc_amt != 0 THEN 
			ROLLBACK WORK 
			ERROR kandoomsg2("A",7008,"") 		#7008 "Applied amount OR discount NOT equal TO zero"
			RETURN 
		END IF 
		
		UPDATE credithead SET * = l_rec_credithead.* 
		WHERE cmpy_code = p_company_cmpy_code 
		AND cred_num = p_cred_recnum 
		CLOSE c_credithead 
	COMMIT WORK 
	
	WHENEVER ERROR stop 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

END FUNCTION 
#################################################################
# END FUNCTION unapply_credit_from_invoice_receipt(p_company_cmpy_code, p_cust, p_cred_recnum, p_kandoouser_sign_on_code)
#################################################################