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
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl"
GLOBALS "../ar/AS_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/AST_GLOBALS.4gl"
###########################################################################
# Module Scope Variables
###########################################################################
DEFINE modu_rec_tax RECORD LIKE tax.* 
DEFINE modu_rec_term RECORD LIKE term.* 
DEFINE modu_cred_reason LIKE arparms.reason_code 
DEFINE modu_acct_code LIKE prodledg.acct_code 
DEFINE modu_coa_desc_text LIKE coa.desc_text 
DEFINE modu_line_text CHAR(30) 
DEFINE modu_inv_date LIKE invoicehead.inv_date 
DEFINE modu_year_num LIKE invoicehead.year_num 
DEFINE modu_period_num LIKE invoicehead.period_num 
DEFINE modu_com1_text LIKE invoicehead.com1_text 
DEFINE modu_com2_text LIKE invoicehead.com2_text 
DEFINE modu_cust_code LIKE customer.cust_code 
DEFINE modu_next_seq_num LIKE customer.next_seq_num 
DEFINE modu_ytds_amt LIKE customer.ytds_amt 
DEFINE modu_mtds_amt LIKE customer.mtds_amt 
DEFINE modu_cred_bal_amt LIKE customer.cred_bal_amt 
DEFINE modu_temp_curr_amt LIKE customer.curr_amt 
DEFINE modu_temp_over1_amt LIKE customer.over1_amt 
DEFINE modu_temp_over30_amt LIKE customer.over30_amt 
DEFINE modu_temp_over60_amt LIKE customer.over60_amt 
DEFINE modu_temp_over90_amt LIKE customer.over90_amt 
DEFINE modu_temp_bal_amt LIKE customer.bal_amt 


###########################################################################
# FUNCTION AST_main()
#
#   Program: AST - AR Debtors Take-on Adjustments
#   Description: Allows debtors take-on balances TO be quickly
#                entered INTO system AND creating the necessary
#                supporting transactions.
#
#                Creates an invoice IF adjustment IS positive
#                Creates a credit IF adjustment IS negative
###########################################################################
FUNCTION AST_main() 
	DEFER QUIT 
	DEFER INTERRUPT 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 
	
	CALL setModuleId("AST") 

	OPEN WINDOW A700 with FORM "A700" 
	CALL windecoration_a("A700") 

	LET modu_acct_code = NULL 
	LET modu_coa_desc_text = NULL 
	LET modu_line_text = NULL 
	LET modu_inv_date = today 
	LET modu_year_num = NULL 
	LET modu_period_num = NULL 

	SELECT reason_code INTO modu_cred_reason FROM arparms 
	WHERE parm_code = "1" 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 

	IF status = NOTFOUND THEN 
		LET modu_cred_reason = " " 
	END IF 

	WHILE AST_enter_invoice_header() 
		WHILE enter_adjustment() 
		END WHILE 
	END WHILE 

	CLOSE WINDOW A700 
END FUNCTION
###########################################################################
# END FUNCTION AST_main()
###########################################################################


####################################################################
# FUNCTION AST_enter_invoice_header() #re
#
# NOTE: same AST_enter_invoice_header() function name in A21 which I renamed to A21_enter_invoice_header(
####################################################################
FUNCTION AST_enter_invoice_header() 
	DEFINE l_temp_text CHAR(100) 
	DEFINE l_failed_it SMALLINT 

	CLEAR FORM 

	IF modu_inv_date IS NOT NULL 
	AND modu_year_num IS NULL 
	AND modu_period_num IS NULL THEN 
		CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, modu_inv_date) 
		RETURNING modu_year_num, modu_period_num 
	END IF 

	IF modu_acct_code IS NOT NULL OR modu_acct_code = " " THEN 
		DISPLAY modu_coa_desc_text TO desc_text 

	END IF 

	ERROR kandoomsg2("U",1020,"Debtors Take-on Header") #1020 Enter Debtors Take-on Header Details;  OK TO Continue.

	INPUT 
		modu_acct_code, 
		modu_line_text, 
		modu_inv_date, 
		modu_year_num, 
		modu_period_num WITHOUT DEFAULTS 
	FROM 
		invoicedetl.line_acct_code, 
		invoicedetl.line_text, 
		invoicehead.inv_date, 
		invoicehead.year_num, 
		invoicehead.period_num 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","AST","inp-invoice") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield(line_acct_code) 
					LET l_temp_text = show_acct(glob_rec_kandoouser.cmpy_code) 

					IF l_temp_text IS NOT NULL AND l_temp_text != " " THEN 
						LET modu_acct_code = l_temp_text 
					END IF 

					NEXT FIELD line_acct_code 

		AFTER FIELD line_acct_code 
			IF modu_acct_code IS NULL THEN 
				ERROR kandoomsg2("U",9102,"") 			#9102 Value must be entered.
				NEXT FIELD line_acct_code 
			END IF 

			SELECT desc_text INTO modu_coa_desc_text FROM coa 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND acct_code = modu_acct_code 
			IF status = NOTFOUND THEN 
				ERROR kandoomsg2("G",9031,"") 			#9102 Account code NOT found.
				NEXT FIELD line_acct_code 
			END IF 

			IF NOT acct_type(glob_rec_kandoouser.cmpy_code,modu_acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"Y") THEN 
				NEXT FIELD line_acct_code 
			END IF 
			DISPLAY modu_coa_desc_text TO desc_text 

		AFTER FIELD line_text 
			IF modu_line_text IS NULL THEN 
				ERROR kandoomsg2("U",9102,"") 			#9102 Value must be entered.
				NEXT FIELD line_text 
			END IF 

		AFTER FIELD inv_date 
			IF modu_inv_date IS NULL THEN 
				ERROR kandoomsg2("U",9102,"") 			#9102 Value must be entered.
				NEXT FIELD inv_date 
			END IF 

			CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, modu_inv_date) 
			RETURNING modu_year_num, modu_period_num 

			DISPLAY 
				modu_inv_date, 
				modu_period_num, 
				modu_year_num 
			TO 
				inv_date, 
				period_num, 
				year_num 

		AFTER FIELD year_num 
			IF modu_year_num IS NULL THEN 
				ERROR kandoomsg2("U",9102,"") 			#9102 Value must be entered.
				NEXT FIELD year_num 
			END IF 

		AFTER FIELD period_num 
			IF modu_period_num IS NULL THEN 
				ERROR kandoomsg2("U",9102,"") 			#9102 Value must be entered.
				NEXT FIELD period_num 
			END IF 
			
			CALL valid_period(
				glob_rec_kandoouser.cmpy_code, 
				modu_year_num, 
				modu_period_num, TRAN_TYPE_INVOICE_IN) 
			RETURNING 
				modu_year_num, 
				modu_period_num, 
				l_failed_it 
			
			IF l_failed_it = 1 THEN 
				NEXT FIELD year_num 
			END IF 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				IF fgl_lastkey() = fgl_keyval("accept") THEN 
					IF modu_inv_date IS NULL THEN 
						ERROR kandoomsg2("U",9102,"") 					#9102 Value must be entered.
						NEXT FIELD inv_date 
					END IF 

					IF modu_line_text IS NULL THEN 
						ERROR kandoomsg2("U",9102,"") 					#9102 Value must be entered.
						NEXT FIELD line_text 
					END IF 

					IF modu_year_num IS NULL THEN 
						ERROR kandoomsg2("U",9102,"") 						#9102 Value must be entered.
						NEXT FIELD year_num 
					END IF 
				END IF 
			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 
	RETURN true 
END FUNCTION 
####################################################################
# END FUNCTION AST_enter_invoice_header()
####################################################################


####################################################################
# FUNCTION enter_adjustment()
#
#
####################################################################
FUNCTION enter_adjustment() 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_salesperson RECORD LIKE salesperson.* 
	DEFINE l_type_text LIKE customertype.type_text 
	--DEFINE l_failed_it SMALLINT 
	DEFINE l_counter SMALLINT 
	DEFINE l_keep_bal_amts SMALLINT 

	DEFINE l_temp_text CHAR(30) 

	CLEAR 
		name_text, 
		type_code, 
		type_text, 
		curr_amt, 
		over1_amt, 
		over30_amt, 
		over60_amt, 
		over90_amt, 
		bal_amt, 
		com1_text, 
		com2_text 

	INITIALIZE glob_rec_customer.* TO NULL 

	LET l_keep_bal_amts = false 
	LET modu_ytds_amt = 0 
	LET modu_temp_curr_amt = NULL 
	LET modu_temp_bal_amt = NULL 
	LET modu_temp_over1_amt = NULL 
	LET modu_temp_over30_amt = NULL 
	LET modu_temp_over60_amt = NULL 
	LET modu_temp_over90_amt = NULL 
	LET modu_com1_text = NULL 
	LET modu_com2_text = NULL 

	MESSAGE kandoomsg2("A",1082,"") #A1082 Enter Adjustment Details;  OK TO Continue.
	INPUT 
		glob_rec_customer.cust_code, 
		modu_temp_curr_amt, 
		modu_temp_over1_amt, 
		modu_temp_over30_amt, 
		modu_temp_over60_amt, 
		modu_temp_over90_amt, 
		modu_temp_bal_amt, 
		modu_com1_text, 
		modu_com2_text WITHOUT DEFAULTS 
	FROM 
		customer.cust_code, 
		customer.curr_amt, 
		customer.over1_amt, 
		customer.over30_amt, 
		customer.over60_amt, 
		customer.over90_amt, 
		customer.bal_amt, 
		invoicehead.com1_text, 
		invoicehead.com2_text 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","AST","inp-cust_balance") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		ON ACTION "LOOKUP" infield(cust_code) 
					LET l_temp_text = show_wcust(glob_rec_kandoouser.cmpy_code,"","") 
					IF l_temp_text IS NOT NULL THEN 
						LET glob_rec_customer.cust_code = l_temp_text
						 
						DISPLAY BY NAME glob_rec_customer.cust_code 

					END IF 
					NEXT FIELD cust_code 

		AFTER FIELD cust_code 
			CLEAR 
				name_text, 
				type_code, 
				type_text 
			
			IF glob_rec_customer.cust_code IS NULL THEN 
				ERROR kandoomsg2("U",9102,"") 			#9102 Value must be entered.
				NEXT FIELD cust_code 
			END IF 
			
			CALL db_customer_get_rec(UI_OFF,glob_rec_customer.cust_code) RETURNING glob_rec_customer.* 
--			SELECT * INTO glob_rec_customer.* FROM customer 
--			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
--			AND cust_code = glob_rec_customer.cust_code

			IF glob_rec_customer.cust_code IS NULL THEN
				ERROR kandoomsg2("A",9009,"") 			#9009 Customer code does NOT exits;  Try Window
				NEXT FIELD cust_code 
			END IF 
			
			IF glob_rec_customer.delete_flag = "Y" THEN 
				ERROR kandoomsg2("A",9144,"") 			#9144" Customer has been marked FOR deletion"
				NEXT FIELD cust_code 
			END IF 
			
			IF glob_rec_customer.curr_amt != 0 
			OR glob_rec_customer.over1_amt != 0 
			OR glob_rec_customer.over30_amt != 0 
			OR glob_rec_customer.over60_amt != 0 
			OR glob_rec_customer.over90_amt != 0 
			OR glob_rec_customer.bal_amt != 0 THEN 
				ERROR kandoomsg2("A",9555,"")	#9555 Customer already has balances.
				NEXT FIELD cust_code 
			END IF 
			
			IF glob_rec_customer.hold_code IS NOT NULL THEN 
				SELECT reason_text INTO l_temp_text 
				FROM holdreas 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND hold_code = glob_rec_customer.hold_code 
				ERROR kandoomsg2("E",7018,l_temp_text) #7018" Warning : Nominated Customer 'On Hold'"
			END IF 

			# Get sales person record
			CALL db_salesperson_get_rec(UI_OFF,glob_rec_customer.sale_code) RETURNING l_rec_salesperson.*
			IF l_rec_salesperson.sale_code IS NULL THEN
				LET l_rec_salesperson.name_text = "**********"
			END IF
		
			SELECT type_text INTO l_type_text FROM customertype 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND type_code = glob_rec_customer.type_code 
			IF status = NOTFOUND THEN 
				LET l_type_text = " " 
			END IF 
			
			#---------------------------------------------------------
			# restore entered balance amounts so that we don't lose
			# entered VALUES by user
			IF NOT l_keep_bal_amts THEN 
				LET modu_temp_curr_amt = glob_rec_customer.curr_amt 
				LET modu_temp_bal_amt = glob_rec_customer.bal_amt 
				LET modu_temp_over1_amt = glob_rec_customer.over1_amt 
				LET modu_temp_over30_amt = glob_rec_customer.over30_amt 
				LET modu_temp_over60_amt = glob_rec_customer.over60_amt 
				LET modu_temp_over90_amt = glob_rec_customer.over90_amt 

				IF modu_temp_curr_amt IS NULL THEN 
					LET modu_temp_curr_amt = 0 
				END IF 
				IF modu_temp_over1_amt IS NULL THEN 
					LET modu_temp_over1_amt = 0 
				END IF 
				IF modu_temp_over30_amt IS NULL THEN 
					LET modu_temp_over30_amt = 0 
				END IF 
				IF modu_temp_over60_amt IS NULL THEN 
					LET modu_temp_over60_amt = 0 
				END IF 
				IF modu_temp_over90_amt IS NULL THEN 
					LET modu_temp_over90_amt = 0 
				END IF 
				IF modu_temp_bal_amt IS NULL THEN 
					LET modu_temp_bal_amt = 0 
				END IF 

			END IF 

			DISPLAY 
				glob_rec_customer.name_text, 
				glob_rec_customer.type_code, 
				l_type_text, 
				modu_temp_curr_amt, 
				modu_temp_over1_amt, 
				modu_temp_over30_amt, 
				modu_temp_over60_amt, 
				modu_temp_over90_amt, 
				modu_temp_bal_amt 
			TO 
				customer.name_text, 
				customer.type_code, 
				type_text, 
				customer.curr_amt, 
				customer.over1_amt, 
				customer.over30_amt, 
				customer.over60_amt, 
				customer.over90_amt, 
				customer.bal_amt 

		AFTER FIELD curr_amt 
			IF modu_temp_curr_amt IS NULL THEN 
				ERROR kandoomsg2("U",9102,"") 			#9102 Value must be entered.
				NEXT FIELD curr_amt 
			END IF 
			
			IF fgl_lastkey() = fgl_keyval("left") OR fgl_lastkey() = fgl_keyval("up") THEN 
				IF (modu_temp_curr_amt + modu_temp_over1_amt + 
				modu_temp_over30_amt + modu_temp_over60_amt + 
				modu_temp_over90_amt) != modu_temp_bal_amt THEN 
					ERROR kandoomsg2("A","9554","") 			# Debtor account details do NOT balance.
					NEXT FIELD curr_amt 
				END IF 
			END IF 
			
			IF fgl_lastkey() = fgl_keyval("RETURN") 
			OR fgl_lastkey() = fgl_keyval("accept") 
			OR fgl_lastkey() = fgl_keyval("tab") 
			OR fgl_lastkey() = fgl_keyval("down") 
			OR fgl_lastkey() = fgl_keyval("right") THEN 
				LET l_keep_bal_amts = true 
			END IF 
		
		AFTER FIELD over1_amt 
			IF modu_temp_over1_amt IS NULL THEN 
				ERROR kandoomsg2("U",9102,"") 			#9102 Value must be entered.
				NEXT FIELD over1_amt 
			END IF 
			
		AFTER FIELD over30_amt 
			IF modu_temp_over30_amt IS NULL THEN 
				ERROR kandoomsg2("U",9102,"") 			#9102 Value must be entered.
				NEXT FIELD over30_amt 
			END IF 
			
		AFTER FIELD over60_amt 
			IF modu_temp_over60_amt IS NULL THEN 
				ERROR kandoomsg2("U",9102,"") 			#9102 Value must be entered.
				NEXT FIELD over60_amt 
			END IF 
			
		AFTER FIELD over90_amt 
			IF modu_temp_over90_amt IS NULL THEN 
				ERROR kandoomsg2("U",9102,"") 			#9102 Value must be entered.
				NEXT FIELD over90_amt 
			END IF 
			
		AFTER FIELD bal_amt 
			IF modu_temp_bal_amt IS NULL THEN 
				ERROR kandoomsg2("U",9102,"") 			#9102 Value must be entered.
				NEXT FIELD bal_amt 
			END IF 
			IF (modu_temp_curr_amt + modu_temp_over1_amt + 
			modu_temp_over30_amt + modu_temp_over60_amt + 
			modu_temp_over90_amt) != modu_temp_bal_amt THEN 
				ERROR kandoomsg2("A","9554","") 			# Debtor account details do NOT balance.
				NEXT FIELD curr_amt 
			END IF 
			
		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				IF (modu_temp_curr_amt + modu_temp_over1_amt + 
				modu_temp_over30_amt + modu_temp_over60_amt + 
				modu_temp_over90_amt) != modu_temp_bal_amt THEN 
					ERROR kandoomsg2("A","9554","") 				# Debtor account details do NOT balance.
					NEXT FIELD curr_amt 
				END IF 

				ERROR kandoomsg2("A",8045,"") 			#8045 Do you wish TO save Debtor Account details?

				IF l_msgresp = "N" THEN 
					NEXT FIELD cust_code 
				END IF 

				SELECT * INTO modu_rec_tax.* FROM tax 
				WHERE tax_code = glob_rec_customer.tax_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("U",9111,"Customer tax code") 				#9111 Customer tax code NOT found.
					NEXT FIELD cust_code 
				END IF 

				SELECT * INTO modu_rec_term.* FROM term 
				WHERE term_code = glob_rec_customer.term_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("U",9111,"Customer term code") 				#9111 Customer tax code NOT found.
					NEXT FIELD cust_code 
				END IF 
				ERROR kandoomsg2("U",1005,"") 			#1005 Updating database;  Please wait.
				CALL generate_invoice() 
				LET l_keep_bal_amts = false 
			END IF 

	END INPUT 
	
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 
####################################################################
# END FUNCTION enter_adjustment()
####################################################################


####################################################################
# FUNCTION generate_invoice()
#
#
####################################################################
FUNCTION generate_invoice() 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_err_message CHAR(30) 
	DEFINE l_diff_amt DECIMAL(16,2) 
	DEFINE l_counter SMALLINT 

	LET modu_cust_code = glob_rec_customer.cust_code 

	FOR l_counter = 1 TO 5 
		CASE l_counter 
			WHEN 1 # CURRENT amount 
				LET l_diff_amt = modu_temp_curr_amt 
			WHEN 2 # 1-30 amount 
				LET l_diff_amt = modu_temp_over1_amt 
			WHEN 3 # 31-60 amount 
				LET l_diff_amt = modu_temp_over30_amt 
			WHEN 4 # 61-90 amount 
				LET l_diff_amt = modu_temp_over60_amt 
			WHEN 5 # 90+ amount 
				LET l_diff_amt = modu_temp_over90_amt 
		END CASE 

		# IF difference IS 0, don't create an invoice OR credit
		IF (l_diff_amt) > 0 THEN 
			CALL AST_create_invoice(glob_rec_kandoouser.cmpy_code, glob_rec_kandoouser.sign_on_code, l_diff_amt, l_counter) 
		ELSE 
			IF (l_diff_amt) < 0 THEN 
				CALL create_credit(glob_rec_kandoouser.cmpy_code, glob_rec_kandoouser.sign_on_code, l_diff_amt, l_counter) 
			END IF 
		END IF 

	END FOR 

END FUNCTION 
####################################################################
# END FUNCTION generate_invoice()
####################################################################


####################################################################
# FUNCTION AST_create_invoice(p_company_cmpy_code, p_kandoouser_sign_on_code, p_unit_sale_amt, p_counter)
#
#
####################################################################
FUNCTION AST_create_invoice(p_company_cmpy_code, p_kandoouser_sign_on_code, p_unit_sale_amt, p_counter) 
	DEFINE p_company_cmpy_code LIKE company.cmpy_code 
	DEFINE p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code 
	DEFINE p_unit_sale_amt LIKE invoicedetl.unit_sale_amt 
	DEFINE p_counter SMALLINT 

	DEFINE l_rec_invoicehead RECORD LIKE invoicehead.*
	DEFINE l_rec_araudit RECORD LIKE araudit.* 
	DEFINE l_rec_invoicedetl RECORD LIKE invoicedetl.* 
	DEFINE l_err_message CHAR(30) 
	DEFINE l_call_status INTEGER 
	DEFINE l_db_status INTEGER 
	--DEFINE l_get_date INTEGER 
	DEFINE l_dbase_status INTEGER 
	DEFINE l_msgresp LIKE language.yes_flag
	
	GOTO bypass 
	LABEL recovery: 
	LET l_msgresp = error_recover(l_err_message, l_dbase_status) 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 

	BEGIN WORK 
		LET l_err_message = "Customer RECORD does NOT exist" 
		
		DECLARE c1_customer CURSOR FOR 
		SELECT * FROM customer 
		WHERE cust_code = modu_cust_code 
		AND cmpy_code = p_company_cmpy_code 
		FOR UPDATE 
		
		OPEN c1_customer 
		FETCH c1_customer INTO glob_rec_customer.* 

		LET l_rec_invoicehead.inv_num = 
		next_trans_num(p_company_cmpy_code,TRAN_TYPE_INVOICE_IN,modu_acct_code) 
		
		IF l_rec_invoicehead.inv_num < 0 THEN 
			LET l_err_message = "Next Invoice Number Update" 
			LET l_db_status = l_rec_invoicehead.inv_num 
			GOTO recovery 
		END IF
		 
		LET l_rec_invoicehead.cust_code = glob_rec_customer.cust_code 
		LET l_rec_invoicehead.cmpy_code = p_company_cmpy_code 
		LET l_rec_invoicehead.entry_code = p_kandoouser_sign_on_code 
		LET l_rec_invoicehead.entry_date = today 
		LET l_rec_invoicehead.year_num = modu_year_num 
		LET l_rec_invoicehead.period_num = modu_period_num 
		LET l_rec_invoicehead.currency_code = glob_rec_customer.currency_code 
		LET l_rec_invoicehead.name_text = glob_rec_customer.name_text 
		LET l_rec_invoicehead.ship_code = glob_rec_customer.cust_code 
		LET l_rec_invoicehead.addr1_text = glob_rec_customer.addr1_text 
		LET l_rec_invoicehead.addr2_text = glob_rec_customer.addr2_text 
		LET l_rec_invoicehead.city_text = glob_rec_customer.city_text 
		LET l_rec_invoicehead.state_code = glob_rec_customer.state_code 
		LET l_rec_invoicehead.post_code = glob_rec_customer.post_code 
		LET l_rec_invoicehead.country_code = glob_rec_customer.country_code --@db-patch_2020_10_04--
		LET l_rec_invoicehead.contact_text = glob_rec_customer.contact_text 
		LET l_rec_invoicehead.tele_text = glob_rec_customer.tele_text 
		LET l_rec_invoicehead.mobile_phone = glob_rec_customer.mobile_phone
		LET l_rec_invoicehead.email = glob_rec_customer.email				
		LET l_rec_invoicehead.total_amt = 0 
		LET l_rec_invoicehead.hand_amt = 0 
		LET l_rec_invoicehead.hand_tax_amt = 0 
		LET l_rec_invoicehead.freight_amt = 0 
		LET l_rec_invoicehead.freight_tax_amt = 0 
		LET l_rec_invoicehead.tax_amt = 0 
		LET l_rec_invoicehead.tax_per = modu_rec_tax.tax_per 
		LET l_rec_invoicehead.disc_amt = 0 
		LET l_rec_invoicehead.paid_amt = 0 
		LET l_rec_invoicehead.paid_date = NULL 
		LET l_rec_invoicehead.disc_taken_amt = 0 
		LET l_rec_invoicehead.disc_per = 0 
		LET l_rec_invoicehead.cost_amt = 0 
		LET l_rec_invoicehead.tax_code = glob_rec_customer.tax_code 
		LET l_rec_invoicehead.acct_override_code = modu_acct_code 
		LET l_rec_invoicehead.term_code = glob_rec_customer.term_code 
		LET l_rec_invoicehead.conv_qty = get_conv_rate(
			p_company_cmpy_code, 
			l_rec_invoicehead.currency_code, 
			modu_inv_date,
			CASH_EXCHANGE_SELL) 

		CASE p_counter 
			WHEN 1 # CURRENT amount 
				LET l_rec_invoicehead.inv_date = modu_inv_date 
			WHEN 2 # 1-30 amount 
				LET l_rec_invoicehead.inv_date = modu_inv_date - 32 
			WHEN 3 # 31-60 amount 
				LET l_rec_invoicehead.inv_date = modu_inv_date - 62 
			WHEN 4 # 61-90 amount 
				LET l_rec_invoicehead.inv_date = modu_inv_date - 92 
			WHEN 5 # 90+ amount 
				LET l_rec_invoicehead.inv_date = modu_inv_date - 122 
		END CASE 

		CALL get_due_and_discount_date(modu_rec_term.*,l_rec_invoicehead.inv_date) 
		RETURNING 
			l_rec_invoicehead.due_date, 
			l_rec_invoicehead.disc_date 

		LET l_rec_invoicehead.disc_per = modu_rec_term.disc_per 
		LET l_rec_invoicehead.ship_date = modu_inv_date 
		LET l_rec_invoicehead.sale_code = glob_rec_customer.sale_code 
		LET l_rec_invoicehead.prepaid_flag = "P" 
		LET l_rec_invoicehead.tax_amt = 0 
		LET l_rec_invoicehead.goods_amt = p_unit_sale_amt 
		LET l_rec_invoicehead.total_amt = p_unit_sale_amt 
		LET l_rec_invoicehead.seq_num = 0 
		LET l_rec_invoicehead.on_state_flag = "N" 
		LET l_rec_invoicehead.posted_flag = "N" 
		LET l_rec_invoicehead.inv_ind = "4" 
		LET l_rec_invoicehead.printed_num = 1 
		LET l_rec_invoicehead.line_num = 1 
		LET l_rec_invoicehead.com1_text = modu_com1_text 
		LET l_rec_invoicehead.com2_text = modu_com2_text 
		LET l_rec_invoicehead.expected_date = NULL 
		LET l_rec_invoicehead.jour_num = NULL 
		LET l_rec_invoicehead.post_date = NULL 
		LET l_rec_invoicehead.ord_num = NULL 
		LET l_rec_invoicehead.rev_date = NULL 
		LET l_rec_invoicehead.rev_num = NULL 
		LET l_rec_invoicehead.stat_date = NULL 
		LET l_rec_invoicehead.ref_num = NULL 
		LET l_rec_invoicehead.manifest_num = NULL 

		LET l_rec_invoicedetl.cmpy_code = p_company_cmpy_code 
		LET l_rec_invoicedetl.tax_code = glob_rec_customer.tax_code 
		LET l_rec_invoicedetl.line_acct_code = modu_acct_code 
		LET l_rec_invoicedetl.order_num = NULL 
		LET l_rec_invoicedetl.order_line_num = NULL 
		LET l_rec_invoicedetl.var_code = NULL 
		LET l_rec_invoicedetl.jobledger_seq_num = NULL 
		LET l_rec_invoicedetl.contract_line_num = NULL 
		LET l_rec_invoicedetl.return_qty = NULL 
		LET l_rec_invoicedetl.km_qty = NULL 
		LET l_rec_invoicedetl.bonus_qty = NULL 
		LET l_rec_invoicedetl.ship_qty = 1 
		LET l_rec_invoicedetl.sold_qty = l_rec_invoicedetl.ship_qty 
		LET l_rec_invoicedetl.line_num = 1 
		LET l_rec_invoicedetl.unit_sale_amt = p_unit_sale_amt 
		LET l_rec_invoicedetl.level_code = 1 
		LET l_rec_invoicedetl.unit_tax_amt = 0 
		LET l_rec_invoicedetl.line_total_amt = p_unit_sale_amt 
		LET l_rec_invoicedetl.ext_sale_amt = p_unit_sale_amt 
		LET l_rec_invoicedetl.ext_tax_amt = 0 
		LET l_rec_invoicedetl.cust_code = l_rec_invoicehead.cust_code 
		LET l_rec_invoicedetl.ord_qty = 1 
		LET l_rec_invoicedetl.back_qty = 0 
		LET l_rec_invoicedetl.prev_qty = 0 
		LET l_rec_invoicedetl.ser_flag = "N" 
		LET l_rec_invoicedetl.ser_qty = 0 
		LET l_rec_invoicedetl.unit_cost_amt = 0 
		LET l_rec_invoicedetl.ext_cost_amt = 0 
		LET l_rec_invoicedetl.disc_amt = 0 
		LET l_rec_invoicedetl.line_text = modu_line_text 
		LET l_rec_invoicedetl.inv_num = l_rec_invoicehead.inv_num 

		LET modu_next_seq_num = glob_rec_customer.next_seq_num + 1 

		INITIALIZE l_rec_araudit.* TO NULL 

		LET l_rec_araudit.cmpy_code = p_company_cmpy_code 
		LET l_rec_araudit.tran_date = l_rec_invoicehead.inv_date 
		LET l_rec_araudit.cust_code = l_rec_invoicehead.cust_code 
		LET l_rec_araudit.seq_num = modu_next_seq_num 
		LET l_rec_araudit.tran_type_ind = TRAN_TYPE_INVOICE_IN 
		LET l_rec_araudit.source_num = l_rec_invoicehead.inv_num 
		LET l_rec_araudit.tran_text = "Adjustment" 
		LET l_rec_araudit.tran_amt = l_rec_invoicehead.total_amt 
		LET l_rec_araudit.entry_code = p_kandoouser_sign_on_code 
		LET l_rec_araudit.sales_code = l_rec_invoicehead.sale_code 
		LET l_rec_araudit.year_num = modu_year_num 
		LET l_rec_araudit.period_num = modu_period_num 
		LET l_rec_araudit.bal_amt = glob_rec_customer.bal_amt + p_unit_sale_amt 
		LET l_rec_araudit.currency_code = glob_rec_customer.currency_code 
		LET l_rec_araudit.conv_qty = l_rec_invoicehead.conv_qty 
		LET l_rec_araudit.entry_date = today 

		LET l_err_message = "Invoice - Unable TO add TO AR log table " 
		INSERT INTO araudit VALUES (l_rec_araudit.*)
		 
		LET l_err_message = "Invoice line addition failed" 

		#INSERT invoiceDetl Record
		IF db_invoicedetl_rec_validation(UI_ON,MODE_INSERT,l_rec_invoicedetl.*) THEN
			INSERT INTO invoicedetl VALUES (l_rec_invoicedetl.*)		
		ELSE
			DISPLAY l_rec_invoicedetl.*
			CALL fgl_winmessage("Error","Could not insert new invoiceDetl record","ERROR")
		END IF 
		 
		LET l_err_message = "Unable TO add TO invoice header table" 

		#INSERT invoicehead Record
		IF db_invoicehead_rec_validation(UI_ON,MODE_INSERT,l_rec_invoicehead.*) THEN
			INSERT INTO invoicehead VALUES (l_rec_invoicehead.*)			
		ELSE
			DISPLAY l_rec_invoicehead.*
			CALL fgl_winmessage("Error","Could not insert new invoicehead record","ERROR")
		END IF 		

		LET l_err_message = "Customer Update Invoice" 
		IF glob_rec_customer.last_inv_date < l_rec_invoicehead.inv_date OR glob_rec_customer.last_inv_date IS NULL THEN 
			LET glob_rec_customer.last_inv_date = l_rec_invoicehead.inv_date 
		END IF 

		IF modu_temp_bal_amt > glob_rec_customer.highest_bal_amt THEN 
			LET glob_rec_customer.highest_bal_amt = modu_temp_bal_amt 
		END IF 

		LET modu_cred_bal_amt = glob_rec_customer.cred_bal_amt - p_unit_sale_amt 

		LET modu_ytds_amt = glob_rec_customer.ytds_amt 

		IF modu_ytds_amt IS NULL THEN 
			LET modu_ytds_amt = 0 
		END IF 

		LET modu_mtds_amt = glob_rec_customer.mtds_amt 

		IF modu_mtds_amt IS NULL THEN 
			LET modu_mtds_amt = 0 
		END IF 

		IF year(l_rec_invoicehead.inv_date) > year(glob_rec_customer.last_inv_date) THEN 
			LET modu_ytds_amt = 0 
		END IF 
		LET modu_ytds_amt = modu_ytds_amt + l_rec_invoicehead.total_amt 

		IF (month(l_rec_invoicehead.inv_date) > month(glob_rec_customer.last_inv_date) 
		OR year(l_rec_invoicehead.inv_date) > year(glob_rec_customer.last_inv_date)) THEN 
			LET modu_mtds_amt = 0 
		END IF 
		
		LET modu_mtds_amt = modu_mtds_amt + l_rec_invoicehead.total_amt 

		CASE p_counter 
			WHEN 1 
				UPDATE customer 
				SET 
					bal_amt = glob_rec_customer.bal_amt + p_unit_sale_amt, 
					curr_amt = glob_rec_customer.curr_amt + p_unit_sale_amt, 
					last_inv_date = glob_rec_customer.last_inv_date, 
					highest_bal_amt = glob_rec_customer.highest_bal_amt, 
					next_seq_num = modu_next_seq_num, 
					ytds_amt = modu_ytds_amt, 
					mtds_amt = modu_mtds_amt, 
					cred_bal_amt = modu_cred_bal_amt 
				WHERE cust_code = glob_rec_customer.cust_code 
				AND cmpy_code = p_company_cmpy_code 

			WHEN 2 
				UPDATE customer 
				SET 
					bal_amt = glob_rec_customer.bal_amt + p_unit_sale_amt, 
					over1_amt = glob_rec_customer.over1_amt + p_unit_sale_amt, 
					last_inv_date = glob_rec_customer.last_inv_date, 
					highest_bal_amt = glob_rec_customer.highest_bal_amt, 
					next_seq_num = modu_next_seq_num, 
					ytds_amt = modu_ytds_amt, 
					mtds_amt = modu_mtds_amt, 
					cred_bal_amt = modu_cred_bal_amt 
				WHERE cust_code = glob_rec_customer.cust_code 
				AND cmpy_code = p_company_cmpy_code 

			WHEN 3 
				UPDATE customer 
				SET 
					bal_amt = glob_rec_customer.bal_amt + p_unit_sale_amt, 
					over30_amt = glob_rec_customer.over30_amt + p_unit_sale_amt, 
					last_inv_date = glob_rec_customer.last_inv_date, 
					highest_bal_amt = glob_rec_customer.highest_bal_amt, 
					next_seq_num = modu_next_seq_num, 
					ytds_amt = modu_ytds_amt, 
					mtds_amt = modu_mtds_amt, 
					cred_bal_amt = modu_cred_bal_amt 
				WHERE cust_code = glob_rec_customer.cust_code 
				AND cmpy_code = p_company_cmpy_code 

			WHEN 4 
				UPDATE customer 
				SET 
					bal_amt = glob_rec_customer.bal_amt + p_unit_sale_amt, 
					over60_amt = glob_rec_customer.over60_amt + p_unit_sale_amt, 
					last_inv_date = glob_rec_customer.last_inv_date, 
					highest_bal_amt = glob_rec_customer.highest_bal_amt, 
					next_seq_num = modu_next_seq_num, 
					ytds_amt = modu_ytds_amt, 
					mtds_amt = modu_mtds_amt, 
					cred_bal_amt = modu_cred_bal_amt 
				WHERE cust_code = glob_rec_customer.cust_code 
				AND cmpy_code = p_company_cmpy_code 

			WHEN 5 
				UPDATE customer 
				SET 
					bal_amt = glob_rec_customer.bal_amt + p_unit_sale_amt, 
					over90_amt = glob_rec_customer.over90_amt + p_unit_sale_amt, 
					last_inv_date = glob_rec_customer.last_inv_date, 
					highest_bal_amt = glob_rec_customer.highest_bal_amt, 
					next_seq_num = modu_next_seq_num, 
					ytds_amt = modu_ytds_amt, 
					mtds_amt = modu_mtds_amt, 
					cred_bal_amt = modu_cred_bal_amt 
				WHERE cust_code = glob_rec_customer.cust_code 
				AND cmpy_code = p_company_cmpy_code 
		END CASE 

	COMMIT WORK 

	WHENEVER ERROR stop 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

END FUNCTION 
####################################################################
# END FUNCTION AST_create_invoice(p_company_cmpy_code, p_kandoouser_sign_on_code, p_unit_sale_amt, p_counter)
####################################################################


####################################################################
# FUNCTION create_credit(p_company_cmpy_code, p_kandoouser_sign_on_code, p_unit_sale_amt, p_counter)
#
#
####################################################################
FUNCTION create_credit(p_company_cmpy_code, p_kandoouser_sign_on_code, p_unit_sale_amt, p_counter) 
	DEFINE p_company_cmpy_code LIKE company.cmpy_code 
	DEFINE p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code 
	DEFINE p_unit_sale_amt LIKE invoicedetl.unit_sale_amt 
	DEFINE p_counter SMALLINT 

	DEFINE l_rec_araudit RECORD LIKE araudit.* 
	DEFINE l_rec_credithead RECORD LIKE credithead.* 
	DEFINE l_rec_creditdetl RECORD LIKE creditdetl.* 
	DEFINE l_err_message CHAR(30) 
	DEFINE l_call_status INTEGER 
	DEFINE l_dbase_status INTEGER 
	DEFINE l_msgresp LIKE language.yes_flag 

	GOTO bypass 
	LABEL recovery: 
	LET l_msgresp = error_recover(l_err_message, l_dbase_status) 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 

	BEGIN WORK 
		LET l_err_message = "Customer RECORD does NOT exist" 
		LET l_dbase_status = -2 

		CALL db_customer_get_rec(UI_OFF,modu_cust_code ) RETURNING glob_rec_customer.* 
--		SELECT * INTO glob_rec_customer.* FROM customer 
--		WHERE cust_code = modu_cust_code 
--		AND cmpy_code = p_company_cmpy_code 

		DECLARE c2_customer CURSOR FOR 
		SELECT * FROM customer 
		WHERE cust_code = modu_cust_code 
		AND cmpy_code = p_company_cmpy_code 
		FOR UPDATE 
		OPEN c2_customer 
		FETCH c2_customer INTO glob_rec_customer.* 

		LET l_rec_credithead.cred_num = next_trans_num(
			p_company_cmpy_code, 
			TRAN_TYPE_CREDIT_CR, 
			l_rec_credithead.acct_override_code)
			 
		IF l_rec_credithead.cred_num < 0 THEN 
			LET l_dbase_status = -1 
			LET l_err_message = "Next Credit Number Update" 
			GOTO recovery 
		END IF 

		CASE p_counter 
			WHEN 1 
				LET l_rec_credithead.cred_date = modu_inv_date 
			WHEN 2 
				LET l_rec_credithead.cred_date = modu_inv_date - 32 
			WHEN 3 
				LET l_rec_credithead.cred_date = modu_inv_date - 62 
			WHEN 4 
				LET l_rec_credithead.cred_date = modu_inv_date - 92 
			WHEN 5 
				LET l_rec_credithead.cred_date = modu_inv_date - 122 
		END CASE 

		LET l_rec_credithead.cmpy_code = p_company_cmpy_code 
		LET l_rec_credithead.cust_code = glob_rec_customer.cust_code 
		LET l_rec_credithead.entry_code = p_kandoouser_sign_on_code 
		LET l_rec_credithead.entry_date = today 
		LET l_rec_credithead.sale_code = glob_rec_customer.sale_code 
		LET l_rec_credithead.tax_code = glob_rec_customer.tax_code 
		LET l_rec_credithead.tax_per = modu_rec_tax.tax_per 
		LET l_rec_credithead.goods_amt = 0 - p_unit_sale_amt 
		LET l_rec_credithead.hand_amt = 0 
		LET l_rec_credithead.hand_tax_amt = 0 
		LET l_rec_credithead.freight_amt = 0 
		LET l_rec_credithead.freight_tax_amt = 0 
		LET l_rec_credithead.tax_amt = 0 
		LET l_rec_credithead.total_amt = l_rec_credithead.goods_amt 
		LET l_rec_credithead.cost_amt = 0 
		LET l_rec_credithead.appl_amt = 0 
		LET l_rec_credithead.disc_amt = 0 
		LET l_rec_credithead.year_num = modu_year_num 
		LET l_rec_credithead.period_num = modu_period_num 
		LET l_rec_credithead.on_state_flag = "N" 
		LET l_rec_credithead.posted_flag = "N" 
		LET l_rec_credithead.next_num = 0 
		LET l_rec_credithead.line_num = 1 
		LET l_rec_credithead.printed_num = 0 
		LET l_rec_credithead.com1_text = modu_com1_text 
		LET l_rec_credithead.com2_text = modu_com2_text 
		LET l_rec_credithead.rev_date = today 
		LET l_rec_credithead.rev_num = 0 
		LET l_rec_credithead.currency_code = glob_rec_customer.currency_code 
		LET l_rec_credithead.cred_ind = "4" 
		LET l_rec_credithead.acct_override_code = modu_acct_code 
		LET l_rec_credithead.reason_code = modu_cred_reason 

		LET l_rec_credithead.conv_qty = get_conv_rate(
			p_company_cmpy_code, 
			l_rec_credithead.currency_code, 
			l_rec_credithead.cred_date,
			CASH_EXCHANGE_SELL) 

		LET l_rec_creditdetl.cmpy_code = p_company_cmpy_code 
		LET l_rec_creditdetl.cust_code = l_rec_credithead.cust_code 
		LET l_rec_creditdetl.line_acct_code = modu_acct_code 
		LET l_rec_creditdetl.line_num = 1 
		LET l_rec_creditdetl.ship_qty = 1 
		LET l_rec_creditdetl.ser_ind = "N" 
		LET l_rec_creditdetl.line_text = modu_line_text 
		LET l_rec_creditdetl.unit_cost_amt = 0 
		LET l_rec_creditdetl.ext_cost_amt = 0 
		LET l_rec_creditdetl.unit_sales_amt = 0 - p_unit_sale_amt 
		LET l_rec_creditdetl.ext_sales_amt = 0 - p_unit_sale_amt 
		LET l_rec_creditdetl.unit_tax_amt = 0 
		LET l_rec_creditdetl.ext_tax_amt = 0 
		LET l_rec_creditdetl.line_total_amt = l_rec_credithead.total_amt 
		LET l_rec_creditdetl.seq_num = 1 
		LET l_rec_creditdetl.level_code = 1 
		LET l_rec_creditdetl.tax_code = glob_rec_customer.tax_code 
		LET l_rec_creditdetl.reason_code = modu_cred_reason 
		LET l_rec_creditdetl.cred_num = l_rec_credithead.cred_num 

		LET modu_next_seq_num = glob_rec_customer.next_seq_num + 1 
		
		INITIALIZE l_rec_araudit.* TO NULL 
		
		LET l_rec_araudit.cmpy_code = p_company_cmpy_code 
		LET l_rec_araudit.tran_date = l_rec_credithead.cred_date 
		LET l_rec_araudit.cust_code = l_rec_credithead.cust_code 
		LET l_rec_araudit.seq_num = modu_next_seq_num 
		LET l_rec_araudit.tran_type_ind = TRAN_TYPE_CREDIT_CR 
		LET l_rec_araudit.source_num = l_rec_credithead.cred_num 
		LET l_rec_araudit.tran_text = "Adjustment" 
		LET l_rec_araudit.tran_amt = 0 - l_rec_credithead.total_amt 
		LET l_rec_araudit.entry_code = p_kandoouser_sign_on_code 
		LET l_rec_araudit.sales_code = l_rec_credithead.sale_code 
		LET l_rec_araudit.year_num = modu_year_num 
		LET l_rec_araudit.period_num = modu_period_num 
		LET l_rec_araudit.bal_amt = glob_rec_customer.bal_amt + p_unit_sale_amt 
		LET l_rec_araudit.currency_code = glob_rec_customer.currency_code 
		LET l_rec_araudit.conv_qty = l_rec_credithead.conv_qty 
		LET l_rec_araudit.entry_date = today 

		LET l_err_message = "Credit - Unable TO add TO AR log table" 
		LET l_dbase_status = -2 
		
		INSERT INTO araudit VALUES (l_rec_araudit.*) 
		
		LET l_err_message = "Credit line addition falied" 
		
		INSERT INTO creditdetl VALUES (l_rec_creditdetl.*) 
		
		LET l_err_message = "Unable TO add TO credit header table" 
		
		INSERT INTO credithead VALUES (l_rec_credithead.*) 

		IF year(l_rec_credithead.cred_date) > year(glob_rec_customer.last_inv_date) THEN 
			LET modu_ytds_amt = 0 
		END IF 
		
		LET modu_ytds_amt = modu_ytds_amt	- l_rec_credithead.total_amt 

		IF (month(l_rec_credithead.cred_date) > month(glob_rec_customer.last_inv_date) 
		OR year(l_rec_credithead.cred_date) > year(glob_rec_customer.last_inv_date)) THEN 
			LET modu_mtds_amt = 0 
		END IF 
		
		LET modu_mtds_amt = glob_rec_customer.mtds_amt	- l_rec_credithead.total_amt 
		LET modu_cred_bal_amt = glob_rec_customer.cred_bal_amt	- p_unit_sale_amt 

		LET l_err_message = "Customer Update Credit" 
		
		CASE p_counter 
			WHEN 1 
				UPDATE customer 
				SET 
					bal_amt = glob_rec_customer.bal_amt + p_unit_sale_amt, 
					curr_amt = glob_rec_customer.curr_amt + p_unit_sale_amt, 
					next_seq_num = modu_next_seq_num, 
					ytds_amt = modu_ytds_amt, 
					mtds_amt = modu_mtds_amt, 
					cred_bal_amt = modu_cred_bal_amt 
				WHERE cust_code = glob_rec_customer.cust_code 
				AND cmpy_code = p_company_cmpy_code 

			WHEN 2 
				UPDATE customer 
				SET 
					bal_amt = glob_rec_customer.bal_amt + p_unit_sale_amt, 
					over1_amt = glob_rec_customer.over1_amt + p_unit_sale_amt, 
					next_seq_num = modu_next_seq_num, 
					ytds_amt = modu_ytds_amt, 
					mtds_amt = modu_mtds_amt, 
					cred_bal_amt = modu_cred_bal_amt 
				WHERE cust_code = glob_rec_customer.cust_code 
				AND cmpy_code = p_company_cmpy_code 

			WHEN 3 
				UPDATE customer 
				SET 
					bal_amt = glob_rec_customer.bal_amt + p_unit_sale_amt, 
					over30_amt = glob_rec_customer.over30_amt + p_unit_sale_amt, 
					next_seq_num = modu_next_seq_num, 
					ytds_amt = modu_ytds_amt, 
					mtds_amt = modu_mtds_amt, 
					cred_bal_amt = modu_cred_bal_amt 
				WHERE cust_code = glob_rec_customer.cust_code 
				AND cmpy_code = p_company_cmpy_code 

			WHEN 4 
				UPDATE customer 
				SET 
					bal_amt = glob_rec_customer.bal_amt + p_unit_sale_amt, 
					over60_amt = glob_rec_customer.over60_amt + p_unit_sale_amt, 
					next_seq_num = modu_next_seq_num, 
					ytds_amt = modu_ytds_amt, 
					mtds_amt = modu_mtds_amt, 
					cred_bal_amt = modu_cred_bal_amt 
				WHERE cust_code = glob_rec_customer.cust_code 
				AND cmpy_code = p_company_cmpy_code 

			WHEN 5 
				UPDATE customer 
				SET 
					bal_amt = glob_rec_customer.bal_amt + p_unit_sale_amt, 
					over90_amt = glob_rec_customer.over90_amt + p_unit_sale_amt, 
					next_seq_num = modu_next_seq_num, 
					ytds_amt = modu_ytds_amt, 
					mtds_amt = modu_mtds_amt, 
					cred_bal_amt = modu_cred_bal_amt 
				WHERE cust_code = glob_rec_customer.cust_code 
				AND cmpy_code = p_company_cmpy_code 
		END CASE 

	COMMIT WORK 

	WHENEVER ERROR stop 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

END FUNCTION 
####################################################################
# END FUNCTION create_credit(p_company_cmpy_code, p_kandoouser_sign_on_code, p_unit_sale_amt, p_counter)
####################################################################