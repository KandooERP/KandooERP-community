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
############################################################
# FUNCTION A2A_main()
#
# 2A - AR Adjustments
# Creates an invoice IF adjustment IS positive Creates a credit IF adjustment IS negative
############################################################
FUNCTION A2A_main() 
DEFINE l_trans_num INTEGER 
	DEFINE l_message CHAR(30) 
	DEFINE l_run_arg STRING 

	DEFER quit 
	DEFER interrupt 

	CALL setModuleId("A2A") 

	OPEN WINDOW A168 with FORM "A168" 
	CALL windecoration_a("A168") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	WHILE A2A_enter_adjustment() 
		LET glob_inv_text = NULL 
		LET glob_inv_text = NULL 
		
		IF glob_rec_invoicedetl.line_total_amt >= 0 THEN 
			LET l_trans_num = A2A_create_invoice(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,glob_rec_invoicehead.*,	glob_rec_invoicedetl.*) 
			LET l_message = "Invoice.",l_trans_num USING "<<<<<<<<<" 
			LET glob_inv_text = "invoicehead.inv_num = ",		l_trans_num USING "<<<<<<<<<<" 
		ELSE 
			LET l_trans_num = create_credit(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,glob_rec_invoicehead.*,glob_rec_invoicedetl.*,	glob_cred_reason) 
			CALL cred_appl(l_trans_num,glob_rec_kandoouser.sign_on_code) 
			LET l_message = " Credit.",l_trans_num USING "<<<<<<<<<" 
			LET glob_inv_text = "credithead.cred_num = ",		l_trans_num USING "<<<<<<<<<<" 
		END IF 
		
		MESSAGE kandoomsg2("A",7084,l_message) #huho: what is this ?????
		SLEEP 2
		
		LET l_message = " Print Invoice/Credit " 
		IF kandoomsg("U",10,l_message)  = "Y" THEN 

			LET l_run_arg = "INVOICE_TEXT=", trim(glob_inv_text) 
			LET l_run_arg = trim(l_run_arg), " ", "CREDIT_TEXT=", trim(glob_inv_text) 

			CALL run_prog("AS1",l_run_arg,"","","") --invoice PRINT 
			CALL run_prog("URS","","","","") -- ON ACTION "Print Manager" 

		END IF 
	END WHILE 
	
	CLOSE WINDOW A168
	 
END FUNCTION 
############################################################
# END FUNCTION A2A_main()
############################################################


############################################################
# FUNCTION A2A_enter_adjustment()
#
#
############################################################
FUNCTION A2A_enter_adjustment() 
	DEFINE l_rec_customer RECORD LIKE customer.*
	DEFINE l_rec_term RECORD LIKE term.*
	DEFINE l_rec_tax RECORD LIKE tax.*
	DEFINE l_rec_salesperson RECORD LIKE salesperson.*
	DEFINE l_save_code LIKE customer.cust_code
	DEFINE l_save_date LIKE invoicehead.inv_date
	DEFINE l_failed_it SMALLINT
	DEFINE l_temp_text CHAR(30) 

	CLEAR FORM 
	INITIALIZE glob_rec_invoicehead.* TO NULL 
	INITIALIZE glob_rec_invoicedetl.* TO NULL 
	INITIALIZE glob_cred_reason TO NULL
	 
	LET glob_rec_invoicehead.inv_date = today 
	LET glob_rec_invoicedetl.line_text = "Adjustment" 
	LET glob_rec_invoicedetl.unit_sale_amt = 0 
	LET glob_rec_invoicedetl.unit_tax_amt = 0 
	LET glob_rec_invoicedetl.line_total_amt = 0
	 
	SELECT reason_code INTO glob_cred_reason FROM arparms 
	WHERE parm_code = "1" 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code
	 
	CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,glob_rec_invoicehead.inv_date) 
	RETURNING glob_rec_invoicehead.year_num,	glob_rec_invoicehead.period_num 

	MESSAGE kandoomsg2("A",1082,"")#A1082 Enter Adjustment Details - ESC TO Continue
	DISPLAY BY NAME glob_rec_invoicedetl.line_total_amt 

	INPUT 
		glob_rec_invoicehead.cust_code, 
		glob_rec_invoicehead.inv_date, 
		glob_rec_invoicedetl.line_text, 
		glob_rec_invoicehead.year_num, 
		glob_rec_invoicehead.period_num, 
		glob_rec_invoicedetl.unit_sale_amt, 
		glob_rec_invoicedetl.unit_tax_amt, 
		glob_cred_reason, 
		glob_rec_invoicehead.sale_code, 
		glob_rec_invoicehead.tax_code, 
		glob_rec_invoicehead.term_code, 
		glob_rec_invoicehead.com1_text, 
		glob_rec_invoicehead.com2_text WITHOUT DEFAULTS
	FROM	
		cust_code, 
		inv_date, 
		line_text, 
		year_num, 
		period_num, 
		unit_sale_amt, 
		unit_tax_amt, 
		cred_reason, 
		sale_code, 
		tax_code, 
		term_code, 
		com1_text, 
		com2_text	ATTRIBUTE(UNBUFFERED)
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","A2A","inp-invoicehead") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield(cred_reason) 
			#FUNCTION show_credreas(p_cmpy,p_filter_where2_text,p_def_reason_code)
			LET l_temp_text = show_credreas(glob_rec_kandoouser.cmpy_code,NULL,glob_cred_reason) 
			IF l_temp_text IS NOT NULL THEN 
				LET glob_cred_reason = l_temp_text 
				NEXT FIELD cred_reason 
			END IF
					 
		ON ACTION "LOOKUP" infield(cust_code) 
					LET glob_rec_invoicehead.cust_code = show_clnt(glob_rec_kandoouser.cmpy_code) 
					NEXT FIELD cust_code
					 
		ON ACTION "LOOKUP" infield(sale_code) 
					LET l_temp_text = show_sale(glob_rec_kandoouser.cmpy_code) 
					IF l_temp_text IS NOT NULL THEN 
						LET glob_rec_invoicehead.sale_code = l_temp_text 
						NEXT FIELD sale_code 
					END IF
					 
		ON ACTION "LOOKUP" infield(term_code) 
					LET l_temp_text = show_term(glob_rec_kandoouser.cmpy_code) 
					IF l_temp_text IS NOT NULL THEN 
						LET glob_rec_invoicehead.term_code = l_temp_text 
						NEXT FIELD term_code 
					END IF
					 
		ON ACTION "LOOKUP" infield(tax_code) 
					LET l_temp_text = show_tax(glob_rec_kandoouser.cmpy_code) 
					IF l_temp_text IS NOT NULL THEN 
						LET glob_rec_invoicehead.tax_code = l_temp_text 
						NEXT FIELD tax_code 
					END IF 

		ON CHANGE cust_code
			DISPLAY db_customer_get_name_text(UI_OFF,glob_rec_invoicehead.cust_code) TO customer.name_text
			DISPLAY db_customer_get_currency_code(UI_OFF,glob_rec_invoicehead.cust_code) TO invoicehead.currency_code
			
		BEFORE FIELD cust_code 
			LET l_save_code = glob_rec_invoicehead.cust_code
			 
		AFTER FIELD cust_code 
			CLEAR customer.name_text 
			IF glob_rec_invoicehead.cust_code IS NULL THEN 
				ERROR kandoomsg2("U",9102,"") 
				NEXT FIELD cust_code 
			END IF 
			
			CALL db_customer_get_rec(UI_OFF,glob_rec_invoicehead.cust_code) RETURNING l_rec_customer.*
--			SELECT * INTO l_rec_customer.* 
--			FROM customer 
--			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
--			AND cust_code = glob_rec_invoicehead.cust_code
			IF l_rec_customer.cust_code IS NULL THEN  
--			IF status = NOTFOUND THEN 
				ERROR kandoomsg2("A",9009,"") 			#9009 Customer code NOT found - Try Window
				NEXT FIELD cust_code 
			END IF 
			IF l_rec_customer.delete_flag = "Y" THEN 
				ERROR kandoomsg2("A",9144,"") 			#9144" Customer has been marked FOR deletion"
				NEXT FIELD cust_code 
			END IF 
			IF l_rec_customer.hold_code IS NOT NULL THEN 
				SELECT reason_text INTO l_temp_text 
				FROM holdreas 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND hold_code = l_rec_customer.hold_code 
				ERROR kandoomsg2("E",7018,l_temp_text) 			#7018" Warning : Nominated Customer 'On Hold'"
			END IF 
			
			DISPLAY BY NAME l_rec_customer.name_text 

			#Sales Person
			CALL db_salesperson_get_rec(UI_OFF,l_rec_customer.sale_code) RETURNING l_rec_salesperson.*
			IF l_rec_salesperson.sale_code IS NULL THEN
				LET l_rec_salesperson.name_text = "**********"
			END IF
			
			SELECT * INTO l_rec_tax.* 
			FROM tax 
			WHERE tax_code = l_rec_customer.tax_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF status = NOTFOUND THEN 
				LET l_rec_tax.desc_text = "**********" 
			END IF 

			SELECT * INTO l_rec_term.* 
			FROM term 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND term_code = l_rec_customer.term_code 
			IF status = NOTFOUND THEN 
				LET l_rec_term.desc_text = "**********" 
			END IF 

			LET glob_rec_invoicehead.sale_code = l_rec_customer.sale_code 
			LET glob_rec_invoicehead.term_code = l_rec_customer.term_code 
			LET glob_rec_invoicehead.tax_code = l_rec_customer.tax_code 
			
			DISPLAY BY NAME 
				l_rec_customer.name_text, 
				glob_rec_invoicehead.sale_code, 
				glob_rec_invoicehead.tax_code, 
				glob_rec_invoicehead.term_code 

			DISPLAY 
				l_rec_customer.name_text, 
				l_rec_salesperson.name_text, 
				l_rec_tax.desc_text, 
				l_rec_term.desc_text 
			TO 
				customer.name_text, 
				salesperson.name_text, 
				tax.desc_text, 
				term.desc_text 

			DISPLAY BY NAME l_rec_customer.currency_code #HuHo: attribute(GREEN) #why with color / green ? I'll remove it 
			
		BEFORE FIELD inv_date 
			LET l_save_date = glob_rec_invoicehead.inv_date
			 
		AFTER FIELD inv_date 
			CASE 
				WHEN glob_rec_invoicehead.inv_date IS NULL 
					LET glob_rec_invoicehead.inv_date = today 
					NEXT FIELD inv_date 
				WHEN glob_rec_invoicehead.inv_date != l_save_date 
					CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, glob_rec_invoicehead.inv_date) 
					RETURNING glob_rec_invoicehead.year_num, 
					glob_rec_invoicehead.period_num 
					DISPLAY BY NAME glob_rec_invoicehead.period_num, 
					glob_rec_invoicehead.year_num 

			END CASE
			 
		AFTER FIELD unit_sale_amt 
			IF glob_rec_invoicedetl.unit_sale_amt IS NULL THEN 
				LET glob_rec_invoicedetl.unit_sale_amt = 0 
				ERROR kandoomsg2("A",9102,"") 				#9102 value must be entered
				NEXT FIELD unit_sale_amt 
			END IF 
			
			LET glob_rec_invoicedetl.line_total_amt = glob_rec_invoicedetl.unit_sale_amt 	+ glob_rec_invoicedetl.unit_tax_amt 
			DISPLAY BY NAME glob_rec_invoicedetl.line_total_amt 

			IF NOT get_is_screen_navigation_forward() THEN 
				NEXT FIELD previous 
			END IF 
			IF glob_rec_invoicedetl.unit_sale_amt >= 0 
			AND fgl_lastkey() != fgl_keyval("accept") THEN 
				NEXT FIELD unit_tax_amt 
			END IF 
			
		AFTER FIELD unit_tax_amt 
			IF glob_rec_invoicedetl.unit_tax_amt IS NULL THEN 
				LET glob_rec_invoicedetl.unit_tax_amt = 0 
				ERROR kandoomsg2("A",9102,"") 			#9102 value must be entered
				NEXT FIELD unit_tax_amt 
			END IF 
			
			LET glob_rec_invoicedetl.line_total_amt = glob_rec_invoicedetl.unit_sale_amt + glob_rec_invoicedetl.unit_tax_amt 
			DISPLAY BY NAME glob_rec_invoicedetl.line_total_amt 

		BEFORE FIELD cred_reason 
			IF glob_rec_invoicedetl.line_total_amt >= 0 THEN 
				IF (fgl_lastkey() = fgl_keyval("up") 
				OR fgl_lastkey() = fgl_keyval("left")) THEN 
					NEXT FIELD unit_tax_amt 
				ELSE 
					NEXT FIELD sale_code 
				END IF 
			END IF 			
			
		AFTER FIELD cred_reason 
			IF glob_cred_reason IS NULL THEN 
				ERROR kandoomsg2("U",9102,"") 			#9102 Value must be entered.
				NEXT FIELD cred_reason 
			END IF 
			SELECT unique 1 FROM credreas 
			WHERE reason_code = glob_cred_reason 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF status = NOTFOUND THEN 
				ERROR kandoomsg2("A",9058,"") 			#9058 Credit Reason Not Found - Try Window
				NEXT FIELD cred_reason 
			END IF

		ON CHANGE sale_code
			DISPLAY db_salesperson_get_name_text(UI_OFF,glob_rec_invoicehead.sale_code) TO salesperson.name_text
			 
		AFTER FIELD sale_code 
			CALL db_salesperson_get_name_text(UI_OFF,glob_rec_invoicehead.sale_code) RETURNING l_rec_salesperson.name_text
			IF sqlca.sqlcode != 0 THEN 
				ERROR kandoomsg2("A",9032,"") 			#9032 salesperson does NOT exist
				NEXT FIELD sale_code 
			ELSE 
				DISPLAY l_rec_salesperson.name_text TO salesperson.name_text 
			END IF 

		ON CHANGE tax_code
			DISPLAY db_tax_get_desc_text(UI_OFF,glob_rec_invoicehead.tax_code) TO tax.desc_text		

		AFTER FIELD tax_code 
			SELECT * INTO l_rec_tax.* FROM tax 
			WHERE tax.tax_code = glob_rec_invoicehead.tax_code 
			AND tax.cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF status = NOTFOUND THEN 
				ERROR kandoomsg2("A",9130,"") 			#9130 "Tax Code NOT found, try again"
				NEXT FIELD tax_code 
			ELSE 
				DISPLAY l_rec_tax.desc_text TO tax.desc_text 
			END IF 

		ON CHANGE term_code
			DISPLAY db_term_get_desc_text(UI_OFF,glob_rec_invoicehead.term_code) TO term.desc_text

		AFTER FIELD term_code 
			CALL db_term_get_rec(UI_OFF,glob_rec_invoicehead.term_code) RETURNING l_rec_term.*		
			IF status = NOTFOUND THEN 
				ERROR kandoomsg2("A",9034,"") 			#9034 "Term Code NOT found, try again"
				NEXT FIELD term_code 
			ELSE 
				DISPLAY l_rec_term.desc_text TO term.desc_text 

			END IF 
			
		# AFTER INPUT ----------------------------			
		AFTER INPUT 
		
			IF not(int_flag OR quit_flag) THEN 
				IF glob_rec_invoicedetl.unit_tax_amt IS NULL THEN 
					LET glob_rec_invoicedetl.unit_tax_amt = 0 
				END IF 
				
				IF glob_rec_invoicedetl.unit_sale_amt IS NULL THEN 
					LET glob_rec_invoicedetl.unit_sale_amt = 0 
				END IF 
				
				IF (glob_rec_invoicedetl.unit_sale_amt > 0 AND glob_rec_invoicedetl.unit_tax_amt < 0) 
				OR (glob_rec_invoicedetl.unit_sale_amt < 0 AND glob_rec_invoicedetl.unit_tax_amt > 0) THEN 
					MESSAGE kandoomsg2("A",9509,"") 				#9509" Adjustment AND tax amounts must be of the same sign "
					NEXT FIELD unit_sale_amt 
				END IF 
				
				IF glob_rec_invoicehead.inv_date IS NULL THEN 
					LET glob_rec_invoicehead.inv_date = today 
					NEXT FIELD inv_date 
				END IF 
				
				CALL valid_period(glob_rec_kandoouser.cmpy_code, glob_rec_invoicehead.year_num, glob_rec_invoicehead.period_num,"AR") 
				RETURNING glob_rec_invoicehead.year_num, glob_rec_invoicehead.period_num,	l_failed_it 
				
				IF l_failed_it THEN 
					NEXT FIELD year_num 
				END IF 
				IF glob_cred_reason IS NULL 
				AND glob_rec_invoicedetl.unit_sale_amt < 0 THEN 
					ERROR kandoomsg2("U",9102,"") 				#9102 Value must be entered.
					NEXT FIELD cred_reason 
				END IF 
				
				SELECT unique(1) FROM salesperson 
				WHERE sale_code = glob_rec_invoicehead.sale_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("A",9032,"") 				#9032 Salesperson code NOT found;  Try Window.
					NEXT FIELD sale_code 
				END IF 
				
				SELECT unique(1) FROM tax 
				WHERE tax.tax_code = glob_rec_invoicehead.tax_code 
				AND tax.cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("A",9130,"") 			#9130 Tax code does NOT exist;  Try Window.
					NEXT FIELD tax_code 
				END IF 
				
				SELECT unique(1) FROM term 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND term_code = glob_rec_invoicehead.term_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("A",9034,"") 		#9034 Term Code NOT found;  Try Window.
					NEXT FIELD term_code 
				END IF 
				IF glob_rec_invoicedetl.unit_sale_amt = 0 
				AND glob_rec_invoicedetl.unit_tax_amt = 0 THEN 
					IF kandoomsg("A",8031,"") != "Y" THEN 
						CONTINUE INPUT 
					END IF 
				END IF 
				
				LET glob_rec_invoicedetl.line_acct_code = 
				enter_valid_acct(glob_rec_kandoouser.cmpy_code,"",glob_rec_invoicehead.year_num, 
				glob_rec_invoicehead.period_num) 
				
				IF glob_rec_invoicedetl.line_acct_code IS NULL THEN 
					CONTINUE INPUT 
				END IF 
				IF glob_rec_invoicedetl.line_total_amt >= 0 THEN 
					LET glob_cred_reason = NULL 
				END IF 
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
############################################################
# END FUNCTION A2A_enter_adjustment()
############################################################


############################################################
# FUNCTION enter_valid_acct(p_cmpy_code,p_default_code,p_year_num,p_period_num)
#
#
############################################################
FUNCTION enter_valid_acct(p_cmpy_code,p_default_code,p_year_num,p_period_num) 
	DEFINE p_cmpy_code LIKE company.cmpy_code #huho may NOT used 
	DEFINE p_default_code LIKE coa.acct_code
	DEFINE p_year_num LIKE period.year_num
	DEFINE p_period_num LIKE period.period_num 
	DEFINE l_rec_coa RECORD LIKE coa.* 

	OPEN WINDOW A104 with FORM "A104" 
	CALL windecoration_a("A104") 
	
	INPUT l_rec_coa.acct_code FROM coa.acct_code ATTRIBUTE(UNBUFFERED)
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","A2A","inp-acct_code")
			DISPLAY db_coa_get_desc_text(UI_OFF,l_rec_coa.acct_code) TO coa.desc_text
						 
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null)
			 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield(acct_code)  
				LET l_rec_coa.acct_code = show_acct(p_cmpy_code) 
				NEXT FIELD acct_code 
		
		ON CHANGE acct_code
			DISPLAY db_coa_get_desc_text(UI_OFF,l_rec_coa.acct_code) TO coa.desc_text
			
		AFTER FIELD acct_code 
			IF l_rec_coa.acct_code IS NULL THEN 
				ERROR kandoomsg2("A",9127,"") 			#9127 " Account Code must be entered"
				NEXT FIELD acct_code 
			END IF 
			IF p_year_num IS NOT NULL AND p_period_num IS NOT NULL THEN 
				CALL verify_acct_code(p_cmpy_code,l_rec_coa.acct_code,p_year_num, 
				p_period_num) 
				RETURNING l_rec_coa.* 
			ELSE 
				SELECT * INTO l_rec_coa.* 
				FROM coa 
				WHERE cmpy_code = p_cmpy_code 
				AND acct_code = l_rec_coa.acct_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("A",9129,"") 				#9129" Account NOT found - Try Window"
					LET l_rec_coa.acct_code = NULL 
				END IF 
			END IF 

			IF l_rec_coa.acct_code IS NULL THEN 
				NEXT FIELD acct_code 
			END IF 
			IF NOT acct_type(p_cmpy_code,l_rec_coa.acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"Y") THEN 
				NEXT FIELD acct_code 
			END IF 

	END INPUT 
	
	CLOSE WINDOW A104 
	
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN "" 
	ELSE 
		RETURN l_rec_coa.acct_code 
	END IF 
END FUNCTION 
############################################################
# END FUNCTION A2A_enter_adjustment()
############################################################