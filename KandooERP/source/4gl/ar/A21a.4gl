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
# A21 -  Allows the user TO enter Accounts Receivable Invoices
#        either updating inventory OR NOT depending on the parameters
#        file settings.
#
############################################################
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl" 
GLOBALS "../ar/A2_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/A20_GLOBALS.4gl"
GLOBALS "../ar/A21_GLOBALS.4gl"
 
########################################################################
# FUNCTION invoice_head_info_entry(p_mode)
#
#
########################################################################
FUNCTION invoice_head_info_entry(p_mode) 
	DEFINE p_mode STRING 
	DEFINE l_mgr_code LIKE salesperson.mgr_code 
	DEFINE l_territory_area_code LIKE territory.area_code 
	DEFINE l_rec_salesperson RECORD LIKE salesperson.* 
	DEFINE l_save_date DATE 
	DEFINE l_rec_term RECORD LIKE term.* 
	DEFINE l_rec_tax RECORD LIKE tax.* 
	DEFINE l_invalid_period SMALLINT 
	DEFINE l_orig_ware_code LIKE warehouse.ware_code 
	DEFINE l_tooldb_status SMALLINT #tool_db return status
	
	OPEN WINDOW A139 with FORM "A139" 
	CALL windecoration_a("A139") 

	CLEAR FORM 
	OPTIONS INPUT NO WRAP #Turn it off as we have a one field input and it's confusing for the user otherwise
	INPUT glob_rec_customer.cust_code WITHOUT DEFAULTS FROM cust_code ATTRIBUTE(UNBUFFERED) 
		BEFORE INPUT 
			IF p_mode = MODE_CLASSIC_EDIT THEN 
				EXIT INPUT 
			ELSE 
				MESSAGE kandoomsg2("A",1062,"")	#A1062 Enter Customer Code
			END IF 

			CALL publish_toolbar("kandoo","A21a","inp-cust_code-1") 
			DISPLAY db_customer_get_name_text(UI_OFF,glob_rec_customer.cust_code) TO customer.name_text

		ON CHANGE cust_code
			DISPLAY db_customer_get_name_text(UI_OFF,glob_rec_customer.cust_code) TO customer.name_text

			#Preview Data... ------------------
			IF glob_rec_customer.cust_code IS NULL THEN 
				ERROR kandoomsg2("U",9102,"") #9102 Value must be entered
				NEXT FIELD cust_code 
			END IF 

			CALL db_customer_get_rec(UI_OFF,glob_rec_customer.cust_code ) RETURNING glob_rec_customer.*
			IF glob_rec_customer.cust_code IS NULL THEN #NOTFOUND 
				ERROR kandoomsg2("A",9009,"") #9009 Customer code NOT found - Try Window
				NEXT FIELD cust_code
			ELSE
				CALL db_country_localize(glob_rec_customer.country_code)			
				DISPLAY glob_rec_customer.addr1_text TO addr1_text 
				DISPLAY glob_rec_customer.addr2_text TO addr2_text 
				DISPLAY glob_rec_customer.city_text TO city_text 
				DISPLAY glob_rec_customer.state_code TO state_code 
				DISPLAY glob_rec_customer.post_code TO post_code
				DISPLAY glob_rec_customer.country_code TO country_code
				DISPLAY glob_rec_customer.hold_code TO hold_code
			END IF 

			IF glob_rec_customer.delete_flag = "Y" THEN 
				ERROR kandoomsg2("A",9144,"") #9144" Customer has been marked FOR deletion"
				NEXT FIELD cust_code 
			END IF 

			IF glob_rec_customer.hold_code IS NOT NULL THEN
				LET glob_temp_text = db_holdreas_get_reason_text(UI_OFF,glob_rec_customer.hold_code) 
				ERROR kandoomsg2("E",7018,glob_temp_text)	#7018" Warning : Nominated Customer 'On Hold'"
				NEXT FIELD cust_code 
			END IF 

			SELECT area_code INTO l_territory_area_code 
			FROM territory 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND terr_code = glob_rec_customer.territory_code 

			SELECT mgr_code INTO l_mgr_code 
			FROM salesperson 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND sale_code = glob_rec_customer.sale_code 

			IF glob_rec_customer.corp_cust_code IS NOT NULL AND glob_rec_customer.corp_cust_ind = "1" THEN 
				SELECT * INTO glob_rec_corpcust.* 
				FROM customer 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cust_code = glob_rec_customer.corp_cust_code 

				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("A",9115,"") #9115 Corporate customer NOT found, setup using A15"
					NEXT FIELD cust_code 
				END IF 

				IF glob_rec_corpcust.delete_flag = "Y" THEN 
					ERROR kandoomsg2("A",9144,"") #9144" Customer has been marked FOR deletetion"
					NEXT FIELD cust_code 
				END IF 

				IF glob_rec_customer.currency_code != glob_rec_corpcust.currency_code THEN 
					ERROR kandoomsg2("A",9060,"") #9060 Corporate AND Originating customer must use same currency
					NEXT FIELD cust_code 
				END IF 

				IF glob_rec_corpcust.hold_code IS NOT NULL THEN 
					ERROR kandoomsg2("A",9145,"") #9145 Corporate customer IS on hold - Release before proceeding
					NEXT FIELD cust_code 
				END IF 

				IF glob_rec_corpcust.cred_override_ind = 0 THEN 
					IF glob_rec_corpcust.bal_amt > glob_rec_corpcust.cred_limit_amt THEN 
						ERROR kandoomsg2("A",9301,"") #9301 "Corporate Customer has exceeded credit limit"
						NEXT FIELD cust_code 
					END IF 
					IF glob_rec_customer.credit_chk_flag = "O" THEN 
						IF NOT cc_credit_chk(glob_rec_customer.cust_code, 
						glob_rec_customer.corp_cust_code, 
						glob_rec_customer.cred_limit_amt) THEN 
							NEXT FIELD cust_code 
						END IF 
					END IF 
				END IF 

				LET glob_rec_invoicehead.cust_code = glob_rec_customer.corp_cust_code 
				LET glob_rec_invoicehead.org_cust_code = glob_rec_customer.cust_code 

			ELSE 

				IF glob_rec_customer.cred_override_ind = 0 THEN 
					IF glob_rec_customer.bal_amt > glob_rec_customer.cred_limit_amt THEN 
						ERROR kandoomsg2("A",9315,"") #9315 customers credit limit exceeded
						NEXT FIELD cust_code 
					END IF 
				END IF 
			END IF 

			#End of Preview Data... ------------------
			
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "DETAIL" --ON KEY (F8) --customer details 
			CALL cinq_clnt(glob_rec_kandoouser.cmpy_code,glob_rec_customer.cust_code)--customer details 
			NEXT FIELD cust_code 

		ON ACTION "LOOKUP" infield (cust_code)
			LET glob_rec_customer.cust_code = show_clnt(glob_rec_kandoouser.cmpy_code) 
			NEXT FIELD cust_code 

		AFTER FIELD cust_code 
			IF glob_rec_customer.cust_code IS NULL THEN 
				ERROR kandoomsg2("U",9102,"") #9102 Value must be entered
				NEXT FIELD cust_code 
			END IF 

			CALL db_customer_get_rec(UI_OFF,glob_rec_customer.cust_code ) RETURNING glob_rec_customer.* 
--			SELECT * INTO glob_rec_customer.* 
--			FROM customer 
--			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
--			AND cust_code = glob_rec_customer.cust_code 
			IF glob_rec_customer.cust_code IS NULL THEN
				ERROR kandoomsg2("A",9009,"") #9009 Customer code NOT found - Try Window
				NEXT FIELD cust_code 
			END IF 

			IF glob_rec_customer.delete_flag = "Y" THEN 
				ERROR kandoomsg2("A",9144,"") #9144" Customer has been marked FOR deletion"
				NEXT FIELD cust_code 
			END IF 

			IF glob_rec_customer.hold_code IS NOT NULL THEN 
				SELECT reason_text INTO glob_temp_text 
				FROM holdreas 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND hold_code = glob_rec_customer.hold_code 
				ERROR kandoomsg2("E",7018,glob_temp_text) #7018" Warning : Nominated Customer 'On Hold'"
				NEXT FIELD cust_code 
			END IF 

			SELECT area_code INTO l_territory_area_code 
			FROM territory 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND terr_code = glob_rec_customer.territory_code 

			SELECT mgr_code INTO l_mgr_code 
			FROM salesperson 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND sale_code = glob_rec_customer.sale_code 

			IF glob_rec_customer.corp_cust_code IS NOT NULL 
			AND glob_rec_customer.corp_cust_ind = "1" THEN 
				SELECT * INTO glob_rec_corpcust.* 
				FROM customer 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cust_code = glob_rec_customer.corp_cust_code 

				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("A",9115,"") #9115 Corporate customer NOT found, setup using A15"
					NEXT FIELD cust_code 
				END IF 

				IF glob_rec_corpcust.delete_flag = "Y" THEN 
					ERROR kandoomsg2("A",9144,"") #9144" Customer has been marked FOR deletetion"
					NEXT FIELD cust_code 
				END IF 

				IF glob_rec_customer.currency_code != glob_rec_corpcust.currency_code THEN 
					ERROR kandoomsg2("A",9060,"") #9060 Corporate AND Originating customer must use same currency
					NEXT FIELD cust_code 
				END IF 

				IF glob_rec_corpcust.hold_code IS NOT NULL THEN 
					ERROR kandoomsg2("A",9145,"") #9145 Corporate customer IS on hold - Release before proceeding
					NEXT FIELD cust_code 
				END IF 

				IF glob_rec_corpcust.cred_override_ind = 0 THEN 
					IF glob_rec_corpcust.bal_amt > glob_rec_corpcust.cred_limit_amt THEN 
						ERROR kandoomsg2("A",9301,"") #9301 "Corporate Customer has exceeded credit limit"
						NEXT FIELD cust_code 
					END IF 
					IF glob_rec_customer.credit_chk_flag = "O" THEN 
						IF NOT cc_credit_chk(
							glob_rec_customer.cust_code, 
							glob_rec_customer.corp_cust_code, 
							glob_rec_customer.cred_limit_amt) THEN 
							NEXT FIELD cust_code 
						END IF 
					END IF 
				END IF 

				LET glob_rec_invoicehead.cust_code = glob_rec_customer.corp_cust_code 
				LET glob_rec_invoicehead.org_cust_code = glob_rec_customer.cust_code 

			ELSE 

				IF glob_rec_customer.cred_override_ind = 0 THEN 
					IF glob_rec_customer.bal_amt > glob_rec_customer.cred_limit_amt THEN 
						ERROR kandoomsg2("A",9315,"") #9315 customers credit limit exceeded
						NEXT FIELD cust_code 
					END IF 
				END IF 
			END IF 
	END INPUT 
	
	OPTIONS INPUT WRAP
	########################

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 

	IF glob_rec_customer.corp_cust_code IS NOT NULL AND glob_rec_customer.corp_cust_ind = "1" THEN 
		LET glob_rec_invoicehead.cust_code = glob_rec_customer.corp_cust_code 
		LET glob_rec_invoicehead.org_cust_code = glob_rec_customer.cust_code 
	ELSE 
		LET glob_rec_invoicehead.cust_code = glob_rec_customer.cust_code 
		LET glob_rec_invoicehead.org_cust_code = NULL 
	END IF 

	LET glob_rec_invoicehead.term_code = glob_rec_customer.term_code 
	LET glob_rec_invoicehead.tax_code = glob_rec_customer.tax_code 
	LET glob_rec_invoicehead.hand_tax_code = glob_rec_customer.tax_code 
	LET glob_rec_invoicehead.freight_tax_code = glob_rec_customer.tax_code 
	LET glob_rec_invoicehead.sale_code = glob_rec_customer.sale_code 
	LET glob_rec_invoicehead.territory_code = glob_rec_customer.territory_code 
	LET glob_rec_invoicehead.cond_code = glob_rec_customer.cond_code 
	LET glob_rec_invoicehead.invoice_to_ind = glob_rec_customer.invoice_to_ind 
	LET glob_rec_invoicehead.country_code = glob_rec_customer.country_code 
	LET glob_rec_invoicehead.currency_code = glob_rec_customer.currency_code 
	LET glob_rec_invoicehead.area_code = l_territory_area_code 
	LET glob_rec_invoicehead.mgr_code = l_mgr_code 
	LET glob_rec_invoicehead.tax_cert_text = glob_rec_customer.tax_num_text 

	## SELECT default year & period
	IF p_mode = MODE_CLASSIC_ADD THEN 
		CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,glob_rec_invoicehead.inv_date) 
		RETURNING glob_rec_invoicehead.year_num,	glob_rec_invoicehead.period_num 
	END IF 
	
	MESSAGE kandoomsg2("A",1064,"") #A1064 Enter Invoice Stuff - F8 Cust Inq.
	INPUT BY NAME 
		glob_rec_invoicehead.purchase_code, 
		glob_rec_invoicehead.inv_date, 
		glob_rec_invoicehead.year_num, 
		glob_rec_invoicehead.period_num, 
		glob_rec_invoicehead.conv_qty, 
		glob_rec_warehouse.ware_code, 
		glob_rec_invoicehead.sale_code, 
		glob_rec_invoicehead.term_code, 
		glob_rec_invoicehead.tax_code, 
		glob_rec_invoicehead.ref_num WITHOUT DEFAULTS ATTRIBUTE(UNBUFFERED) 

		BEFORE INPUT 
			CALL display_head_info() 
			CALL publish_toolbar("kandoo","A21a","inp-invoicehead-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield(sale_code)
			LET glob_rec_invoicehead.sale_code = show_sale(glob_rec_kandoouser.cmpy_code) 
			DISPLAY glob_rec_invoicehead.sale_code TO sale_code
			NEXT FIELD sale_code 

		ON ACTION "LOOKUP" infield(term_code) 
			LET glob_rec_invoicehead.term_code = show_term(glob_rec_kandoouser.cmpy_code) 
			DISPLAY glob_rec_invoicehead.term_code TO term_code
			NEXT FIELD term_code 

		ON ACTION "LOOKUP" infield(tax_code) 
			LET glob_rec_invoicehead.tax_code = show_tax(glob_rec_kandoouser.cmpy_code) 
			DISPLAY glob_rec_invoicehead.tax_code TO tax_code
			NEXT FIELD tax_code 

		ON ACTION "LOOKUP" infield(ware_code) 

			LET glob_rec_warehouse.ware_code = show_ware(glob_rec_kandoouser.cmpy_code) 
			DISPLAY glob_rec_warehouse.ware_code TO ware_code
			NEXT FIELD ware_code 

		ON ACTION "DETAILS"
		--ON KEY (F8) --customer details 
			CALL cinq_clnt(glob_rec_kandoouser.cmpy_code,glob_rec_customer.cust_code)--customer details 
			NEXT FIELD purchase_code 

		BEFORE FIELD inv_date 
			LET l_save_date = glob_rec_invoicehead.inv_date 

		AFTER FIELD inv_date 
			IF glob_rec_invoicehead.inv_date IS NULL THEN 
				LET glob_rec_invoicehead.inv_date = l_save_date 
				NEXT FIELD inv_date 
			END IF 

			IF glob_rec_invoicehead.inv_date != l_save_date THEN 
				CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,glob_rec_invoicehead.inv_date) 
				RETURNING 
					glob_rec_invoicehead.year_num, 
					glob_rec_invoicehead.period_num 

				IF p_mode = MODE_CLASSIC_ADD AND glob_rec_invoicehead.currency_code!=glob_rec_glparms.base_currency_code THEN 
					LET glob_rec_invoicehead.conv_qty =	get_conv_rate(
						glob_rec_kandoouser.cmpy_code,
						glob_rec_invoicehead.currency_code, 
						glob_rec_invoicehead.inv_date, 
						CASH_EXCHANGE_SELL) 
				END IF 
			END IF 

			DISPLAY BY NAME 
				glob_rec_invoicehead.year_num, 
				glob_rec_invoicehead.period_num, 
				glob_rec_invoicehead.conv_qty 


		BEFORE FIELD conv_qty 
			IF p_mode = MODE_CLASSIC_EDIT OR glob_rec_invoicehead.currency_code=glob_rec_glparms.base_currency_code THEN 
				IF NOT get_is_screen_navigation_forward() THEN  
					NEXT FIELD previous 
				ELSE 
					NEXT FIELD NEXT 
				END IF 
			END IF 

		AFTER FIELD conv_qty 
			IF glob_rec_invoicehead.conv_qty IS NULL THEN 
				ERROR kandoomsg2("A",9180,"") #9180 Exchange rate must be entered.
				NEXT FIELD conv_qty 
			END IF 
			IF glob_rec_invoicehead.conv_qty <= 0 THEN 
				ERROR kandoomsg2("A",9181,"") #9181 " Exchange Rate must be greater than zero "
				NEXT FIELD conv_qty 
			END IF 

		AFTER FIELD sale_code 
			IF glob_rec_invoicehead.sale_code IS NULL THEN 
				ERROR kandoomsg2("U",9102,"") #9102 Value must be entered
				NEXT FIELD sale_code 
			ELSE 
				CALL db_salesperson_get_name_text(UI_OFF,glob_rec_customer.sale_code) RETURNING l_rec_salesperson.name_text			
				IF sqlca.sqlcode != 0 THEN
					ERROR kandoomsg2("U",9105,"") #9105 RECORD NOT found; Try window.
					NEXT FIELD sale_code 
				ELSE 
					DISPLAY l_rec_salesperson.name_text TO name_text
				END IF 
			END IF 

		BEFORE FIELD ware_code 
			## Change of warehouse NOT permitted during edit
			## as it has potential TO change all prices/costs etc..
			IF glob_rec_invoicehead.line_num > 0 THEN 
				IF NOT get_is_screen_navigation_forward() THEN 
					NEXT FIELD PREVIOUS 
				ELSE 
					NEXT FIELD NEXT 
				END IF 
			END IF 

		AFTER FIELD ware_code 
			IF glob_rec_warehouse.ware_code IS NULL THEN 
				#HuHo 05.04.2020 I removed this constraint
				#otherwise user will not be able to created
				#none warehouse product based invoices (free invoices)
				MESSAGE "Invoice will not include warehouse items" #ERROR kandoomsg2("U",9102,"") #9102 Value must be entered
				DISPLAY "No Warehouse will be used" TO warehouse.desc_text
				--NEXT FIELD ware_code
				MESSAGE "You will not be able to use warehouse parts/items!" 
			ELSE 
				CALL db_warehouse_get_rec(UI_OFF,glob_rec_warehouse.ware_code) RETURNING glob_rec_warehouse.* 
				IF glob_rec_warehouse.ware_code IS NULL THEN #NOTFOUND 
					ERROR kandoomsg2("U",9105,"") #9105 RECORD NOT found; Try window.
					NEXT FIELD ware_code 
				ELSE 
					DISPLAY glob_rec_warehouse.desc_text TO warehouse.desc_text
				END IF 
			END IF 

		AFTER FIELD term_code 
			IF glob_rec_invoicehead.term_code IS NULL THEN 
				ERROR kandoomsg2("U",9102,"") #9102 Value must be entered
				NEXT FIELD term_code 
			ELSE 
				CALL db_term_get_rec(UI_OFF,glob_rec_invoicehead.term_code) RETURNING l_rec_term.*
				IF l_rec_term.term_code IS NULL THEN #NOTFOUND 
					ERROR kandoomsg2("U",9105,"") #9105 RECORD NOT found; Try window.
					NEXT FIELD term_code 
				ELSE 
					DISPLAY l_rec_term.desc_text TO term.desc_text 
				END IF 
			END IF 

		AFTER FIELD tax_code 
			IF glob_rec_invoicehead.tax_code IS NULL THEN 
				ERROR kandoomsg2("U",9102,"") #9102 Value must be entered
				NEXT FIELD tax_code 
			ELSE 
				CALL db_tax_get_rec(UI_OFF,glob_rec_invoicehead.tax_code) RETURNING l_rec_tax.*
				IF l_rec_tax.tax_code IS NULL THEN #NOTFOUND  
					ERROR kandoomsg2("U",9105,"") #9105 RECORD NOT found; Try window.
					NEXT FIELD tax_code 
				ELSE 
					DISPLAY l_rec_tax.desc_text TO tax.desc_text 
				END IF 
			END IF 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				##
				## Fiscal year/period validation
				CALL valid_period(
					glob_rec_kandoouser.cmpy_code,
					glob_rec_invoicehead.year_num, 
					glob_rec_invoicehead.period_num,
					LEDGER_TYPE_AR) 
				RETURNING 
					glob_rec_invoicehead.year_num, 
					glob_rec_invoicehead.period_num, 
					l_invalid_period 

				IF l_invalid_period THEN 
					NEXT FIELD year_num 
				END IF 
				#------------------------------
				# Warehouse validation
				#Feature Request from Ali - Invoice should support warehouse and none-warehouse items	
--				IF p_mode = MODE_CLASSIC_ADD OR (l_orig_ware_code IS NOT NULL AND l_orig_ware_code != " ") THEN 
--					SELECT 1 FROM warehouse 
--					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
--					AND ware_code = glob_rec_warehouse.ware_code 
--					IF status = NOTFOUND THEN 
--						ERROR kandoomsg2("U",9105,"") #9105 RECORD NOT found; Try window.
--						NEXT FIELD ware_code 
--					END IF 
--				END IF 
				
				#------------------------
				# Salesperson validation
				SELECT 1 FROM salesperson 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND sale_code = glob_rec_invoicehead.sale_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("U",9105,"") #9105 RECORD NOT found; Try window.
					NEXT FIELD sale_code 
				END IF 
				
				#---------------------------------------------------------
				## Term validation
				SELECT 1 FROM term 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND term_code = glob_rec_invoicehead.term_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("U",9105,"") #9105 RECORD NOT found; Try window.
					NEXT FIELD term_code 
				END IF 
				
				#----------------------------------------------------------
				# Tax validation
				CALL db_tax_get_rec(UI_OFF,glob_rec_invoicehead.tax_code) RETURNING l_rec_tax.*
				IF l_rec_tax.tax_code IS NULL THEN #NOTFOUND  
					ERROR kandoomsg2("U",9105,"") #9105 RECORD NOT found; Try window.
					NEXT FIELD tax_code 
				ELSE 
					IF l_rec_tax.calc_method_flag = "X" THEN 
						IF (glob_rec_customer.last_mail_date < glob_rec_invoicehead.inv_date) 
						OR (glob_rec_customer.last_mail_date IS null) 
						OR (glob_rec_customer.tax_num_text IS null) THEN 
							IF glob_rec_invoicehead.tax_cert_text IS NULL THEN 
								LET glob_rec_invoicehead.tax_cert_text = enter_exempt_num(
									glob_rec_kandoouser.cmpy_code, 
									glob_rec_invoicehead.tax_code, 
									glob_rec_customer.tax_num_text) 
							ELSE 
								LET glob_rec_invoicehead.tax_cert_text = enter_exempt_num(
									glob_rec_kandoouser.cmpy_code, 
									glob_rec_invoicehead.tax_code, 
									glob_rec_invoicehead.tax_cert_text) 
							END IF 
						END IF 
					END IF 
				END IF 

				LET glob_rec_invoicehead.tax_per = l_rec_tax.tax_per 
				LET glob_rec_invoicehead.hand_tax_code = glob_rec_invoicehead.tax_code 
				LET glob_rec_invoicehead.freight_tax_code = glob_rec_invoicehead.tax_code 
				##
				## Set up account overlay mask FOR invoice header
				##
				LET glob_rec_invoicehead.acct_override_code = setup_ar_override(
					glob_rec_kandoouser.cmpy_code,
					glob_rec_kandoouser.sign_on_code,
					TRAN_TYPE_INVOICE_IN,
					glob_rec_customer.cust_code, 
					glob_rec_warehouse.ware_code, 
					glob_rec_arparms.show_seg_flag) 
				IF glob_rec_invoicehead.acct_override_code IS NULL THEN 
					CONTINUE INPUT 
				END IF 
			END IF 


	END INPUT 
	########################################################

	CLOSE WINDOW A139 #invoice header window

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 

END FUNCTION 
########################################################################
# END FUNCTION invoice_head_info_entry(p_mode)
########################################################################





########################################################################
# FUNCTION display_head_info()
#
# new FUNCTION FOR INPUT SCREEN A137a
########################################################################
FUNCTION display_head_info() 
	DEFINE l_rec_tax RECORD LIKE tax.* 
	DEFINE l_rec_term RECORD LIKE term.* 
	DEFINE l_rec_salesperson RECORD LIKE salesperson.* 
	DEFINE l_balance_amt LIKE customer.cred_bal_amt 
	DEFINE l_cred_avail_amt LIKE customer.cred_bal_amt 
	DEFINE l_rec_org_customer RECORD LIKE customer.* 
	DEFINE l_orig_ware_code LIKE warehouse.ware_code 
	DEFINE l_ref_text LIKE arparms.inv_ref1_text 
	DEFINE l_temp_text CHAR(32) 
	DEFINE l_rec_customership RECORD LIKE customership.* #moved FROM global TO local scope 
	DEFINE l_style STRING #i.e. ATTRIBUTE_OK

	SELECT * INTO l_rec_customership.* 
	FROM customership 
	WHERE cust_code = glob_rec_invoicehead.cust_code 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND ship_code = glob_rec_invoicehead.cust_code 

	LET glob_rec_invoicehead.ship_code = l_rec_customership.ship_code 
	LET glob_rec_invoicehead.name_text = l_rec_customership.name_text 
	LET glob_rec_invoicehead.addr1_text = l_rec_customership.addr_text 
	LET glob_rec_invoicehead.addr2_text = l_rec_customership.addr2_text 
	LET glob_rec_invoicehead.city_text = l_rec_customership.city_text 
	LET glob_rec_invoicehead.state_code = l_rec_customership.state_code 
	LET glob_rec_invoicehead.post_code = l_rec_customership.post_code 
	LET glob_rec_invoicehead.country_code = l_rec_customership.country_code --@db-patch_2020_10_04--
	LET glob_rec_invoicehead.contact_text = l_rec_customership.contact_text 
	LET glob_rec_invoicehead.tele_text = l_rec_customership.tele_text 
	LET glob_rec_invoicehead.mobile_phone = l_rec_customership.mobile_phone	
	LET glob_rec_invoicehead.email = l_rec_customership.email	

	IF glob_rec_invoicehead.org_cust_code IS NOT NULL THEN 
		SELECT * INTO l_rec_org_customer.* FROM customer 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = glob_rec_invoicehead.org_cust_code 
		IF glob_rec_corpcust.inv_addr_flag != "C" THEN 
			## move orgs address TO cust addrs fields
			LET glob_rec_customer.addr1_text = l_rec_org_customer.addr1_text 
			LET glob_rec_customer.addr2_text = l_rec_org_customer.addr2_text 
		END IF 
	END IF 

	LET glob_overdue = glob_rec_customer.over1_amt 
		+ glob_rec_customer.over30_amt 
		+ glob_rec_customer.over60_amt 
		+ glob_rec_customer.over90_amt 
	
	LET glob_baddue =	glob_rec_customer.over30_amt 
		+ glob_rec_customer.over60_amt 
		+ glob_rec_customer.over90_amt 

	CALL db_term_get_rec(UI_OFF,glob_rec_customer.term_code ) RETURNING l_rec_term.*
	
	LET l_balance_amt = glob_rec_customer.bal_amt 
	LET l_cred_avail_amt = glob_rec_customer.cred_limit_amt - glob_rec_customer.bal_amt - glob_rec_customer.onorder_amt 

	IF glob_rec_invoicehead.currency_code = glob_rec_glparms.base_currency_code THEN 
		LET glob_rec_invoicehead.conv_qty = 1 
	ELSE 
		IF glob_rec_invoicehead.conv_qty IS NULL OR glob_rec_invoicehead.conv_qty = 0 THEN 
			LET glob_rec_invoicehead.conv_qty = get_conv_rate(
				glob_rec_kandoouser.cmpy_code,
				glob_rec_invoicehead.currency_code, 
				glob_rec_invoicehead.inv_date,
				CASH_EXCHANGE_SELL) 
		END IF 
	END IF
	 
	LET l_temp_text = glob_rec_arparms.inv_ref1_text clipped, "................" 
	LET l_ref_text = l_temp_text 

	IF glob_rec_warehouse.ware_code IS NULL THEN 
		LET glob_rec_warehouse.ware_code = l_rec_customership.ware_code 
	END IF 

	LET l_orig_ware_code = glob_rec_warehouse.ware_code 

	#---------------------------------------------------
	# SELECT tax & description
	SELECT * INTO l_rec_tax.* 
	FROM tax 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND tax_code = glob_rec_invoicehead.tax_code 
	IF status = NOTFOUND THEN 
		LET l_rec_tax.desc_text = "**********" 
	END IF 
	
	#-----------------------------------------------------
	# SELECT warehouse & description
	CALL db_warehouse_get_rec(UI_OFF,glob_rec_warehouse.ware_code) RETURNING glob_rec_warehouse.* 
	IF sqlca.sqlcode != 0 THEN
		LET glob_rec_warehouse.desc_text = "**********" 
	END IF 
	
	# SELECT salesperson & description
	CALL db_salesperson_get_rec(UI_OFF,glob_rec_invoicehead.sale_code) RETURNING l_rec_salesperson.*
	IF l_rec_salesperson.sale_code IS NULL THEN
		LET l_rec_salesperson.name_text = "**********"
	END IF
	
	## SELECT term & description
	SELECT * INTO l_rec_term.* 
	FROM term 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND term_code = glob_rec_invoicehead.term_code 
	IF status = NOTFOUND THEN 
		LET l_rec_term.desc_text = "**********" 
	END IF 

	IF glob_overdue > 0 THEN 
		IF glob_baddue > 0 THEN
			LET l_style = ATTRIBUTE_WARNING 
			DISPLAY BY NAME 
				glob_rec_customer.currency_code, 
				glob_rec_customer.name_text, 
				glob_rec_customer.addr1_text, 
				glob_rec_customer.addr2_text, 
				glob_rec_customer.city_text, 
				glob_rec_customer.state_code, 
				glob_rec_customer.post_code, 
				glob_rec_customer.country_code,--@db-patch_2020_10_04-- 
				glob_rec_customer.hold_code attribute(STYLE=l_style)  
			DISPLAY l_rec_term.desc_text TO desc_text attribute(STYLE=l_style) 

			IF glob_rec_invoicehead.org_cust_code IS NOT NULL THEN 
				DISPLAY glob_rec_invoicehead.org_cust_code TO customer.cust_code attribute(STYLE=ATTRIBUTE_OK) 
			ELSE 
				DISPLAY BY NAME glob_rec_customer.cust_code attribute(STYLE=ATTRIBUTE_OK) 
			END IF 

			LET l_style = ATTRIBUTE_ERROR
			DISPLAY 
				glob_rec_invoicehead.inv_date, 
				glob_rec_invoicehead.entry_code, 
				glob_rec_invoicehead.year_num, 
				glob_rec_invoicehead.period_num, 
				glob_rec_invoicehead.conv_qty, 
				glob_rec_invoicehead.currency_code, 
				glob_rec_invoicehead.purchase_code, 
				glob_rec_warehouse.ware_code, 
				glob_rec_warehouse.desc_text, 
				glob_rec_invoicehead.sale_code, 
				l_rec_salesperson.name_text, 
				glob_rec_invoicehead.term_code, 
				l_rec_term.desc_text, 
				glob_rec_invoicehead.tax_code, 
				l_rec_tax.desc_text, 
				l_ref_text 
			TO 
				invoicehead.inv_date, 
				invoicehead.entry_code, 
				invoicehead.year_num, 
				invoicehead.period_num, 
				invoicehead.conv_qty, 
				invoicehead.currency_code, 
				invoicehead.purchase_code, 
				warehouse.ware_code, 
				warehouse.desc_text, 
				invoicehead.sale_code, 
				salesperson.name_text, 
				invoicehead.term_code, 
				term.desc_text, 
				invoicehead.tax_code, 
				tax.desc_text, 
				inv_ref1_text attribute(STYLE=l_style) 
		ELSE 
			LET l_style = ATTRIBUTE_OK 
			DISPLAY BY NAME 
				glob_rec_customer.currency_code, 
				glob_rec_customer.name_text, 
				glob_rec_customer.addr1_text, 
				glob_rec_customer.addr2_text, 
				glob_rec_customer.city_text, 
				glob_rec_customer.state_code, 
				glob_rec_customer.post_code, 
				glob_rec_customer.country_code, --@db-patch_2020_10_04--
				glob_rec_customer.hold_code ATTRIBUTE(STYLE=l_style)
				 
			DISPLAY l_rec_term.desc_text TO desc_text ATTRIBUTE(STYLE=l_style)  

			IF glob_rec_invoicehead.org_cust_code IS NOT NULL THEN 
				DISPLAY glob_rec_invoicehead.org_cust_code TO customer.cust_code ATTRIBUTE(STYLE=l_style)
			ELSE 
				DISPLAY glob_rec_customer.cust_code TO customer.cust_code ATTRIBUTE(STYLE=l_style) 
			END IF 
			
			LET l_style = ATTRIBUTE_WARNING
			
			DISPLAY glob_rec_invoicehead.inv_date TO invoicehead.inv_date attribute(STYLE=l_style)
			DISPLAY glob_rec_invoicehead.entry_code TO invoicehead.entry_code attribute(STYLE=l_style)
			DISPLAY glob_rec_invoicehead.year_num TO invoicehead.year_num attribute(STYLE=l_style)
			DISPLAY glob_rec_invoicehead.period_num TO invoicehead.period_num attribute(STYLE=l_style)
			DISPLAY glob_rec_invoicehead.conv_qty TO invoicehead.conv_qty attribute(STYLE=l_style)
			DISPLAY glob_rec_invoicehead.currency_code TO invoicehead.currency_code attribute(STYLE=l_style)
			DISPLAY glob_rec_invoicehead.purchase_code TO invoicehead.purchase_code attribute(STYLE=l_style)
			DISPLAY glob_rec_invoicehead.job_code TO invoicehead.job_code attribute(STYLE=l_style)
			DISPLAY glob_rec_warehouse.ware_code TO warehouse.ware_code attribute(STYLE=l_style)
			DISPLAY glob_rec_warehouse.desc_text TO warehouse.desc_text attribute(STYLE=l_style)
			DISPLAY glob_rec_invoicehead.sale_code TO invoicehead.sale_code attribute(STYLE=l_style)
			DISPLAY l_rec_salesperson.name_text TO salesperson.name_text attribute(STYLE=l_style) 
			DISPLAY glob_rec_invoicehead.term_code TO invoicehead.term_code attribute(STYLE=l_style)
			DISPLAY l_rec_term.desc_text TO term.desc_text attribute(STYLE=l_style) 
			DISPLAY glob_rec_invoicehead.tax_code TO invoicehead.tax_code attribute(STYLE=l_style) 
			DISPLAY l_rec_tax.desc_text TO tax.desc_text attribute(STYLE=l_style) 
			DISPLAY l_ref_text TO inv_ref1_text attribute(STYLE=l_style) 
				
		END IF 

	ELSE 

		LET l_style = ATTRIBUTE_OK
		
		DISPLAY BY NAME 
			glob_rec_customer.currency_code, 
			glob_rec_customer.name_text, 
			glob_rec_customer.addr1_text, 
			glob_rec_customer.addr2_text, 
			glob_rec_customer.city_text, 
			glob_rec_customer.state_code, 
			glob_rec_customer.post_code, 
			glob_rec_customer.country_code, --@db-patch_2020_10_04--
			glob_rec_customer.hold_code attribute(STYLE=l_style)  
		
		DISPLAY l_rec_term.desc_text TO desc_text attribute(STYLE=l_style) 

		IF glob_rec_invoicehead.org_cust_code IS NOT NULL THEN 
			DISPLAY glob_rec_invoicehead.org_cust_code TO customer.cust_code attribute(STYLE=l_style) 
		ELSE 
			DISPLAY BY NAME glob_rec_customer.cust_code attribute(STYLE=l_style) 
		END IF 

		DISPLAY glob_rec_invoicehead.inv_date TO invoicehead.inv_date attribute(STYLE=l_style) 
			DISPLAY glob_rec_invoicehead.entry_code TO invoicehead.entry_code attribute(STYLE=l_style) 
			DISPLAY glob_rec_invoicehead.year_num TO invoicehead.year_num attribute(STYLE=l_style) 
			DISPLAY glob_rec_invoicehead.period_num TO invoicehead.period_num attribute(STYLE=l_style) 
			DISPLAY glob_rec_invoicehead.conv_qty TO invoicehead.conv_qty attribute(STYLE=l_style) 
			DISPLAY glob_rec_invoicehead.currency_code TO invoicehead.currency_code attribute(STYLE=l_style) 
			DISPLAY glob_rec_invoicehead.purchase_code TO invoicehead.purchase_code attribute(STYLE=l_style) 
			DISPLAY glob_rec_invoicehead.ref_num TO invoicehead.ref_num attribute(STYLE=l_style) 
			DISPLAY glob_rec_warehouse.ware_code TO warehouse.ware_code attribute(STYLE=l_style) 
			DISPLAY glob_rec_warehouse.desc_text TO warehouse.desc_text attribute(STYLE=l_style) 
			DISPLAY glob_rec_invoicehead.sale_code TO invoicehead.sale_code attribute(STYLE=l_style) 
			DISPLAY l_rec_salesperson.name_text TO salesperson.name_text attribute(STYLE=l_style) 
			DISPLAY glob_rec_invoicehead.term_code TO invoicehead.term_code attribute(STYLE=l_style) 
			DISPLAY l_rec_term.desc_text TO term.desc_text attribute(STYLE=l_style) 
			DISPLAY glob_rec_invoicehead.tax_code TO invoicehead.tax_code attribute(STYLE=l_style) 
			DISPLAY l_rec_tax.desc_text TO tax.desc_text attribute(STYLE=l_style) 
			DISPLAY l_ref_text TO inv_ref1_text attribute(STYLE=l_style) 
	END IF 

END FUNCTION 
########################################################################
# END FUNCTION display_head_info()
########################################################################




########################################################################
# FUNCTION cc_credit_chk(p_cust_code,p_corp_cust,p_cred_limit)
#
#
########################################################################
FUNCTION cc_credit_chk(p_cust_code,p_corp_cust,p_cred_limit) 
	DEFINE p_cust_code LIKE customer.cust_code 
	DEFINE p_corp_cust LIKE customer.cust_code 
	DEFINE p_cred_limit LIKE customer.cred_limit_amt 
	DEFINE l_inv_tot LIKE customer.cred_limit_amt 
	DEFINE l_cred_tot LIKE customer.cred_limit_amt 

	SELECT sum(total_amt-paid_amt) INTO l_inv_tot 
	FROM invoicehead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cust_code = p_corp_cust 
	AND org_cust_code = p_cust_code 
	AND total_amt != paid_amt 

	IF l_inv_tot IS NULL THEN 
		LET l_inv_tot = 0 
	END IF 
	# Do this here TO save having TO check credits

	IF l_inv_tot < p_cred_limit THEN 
		RETURN true 
	END IF 

	SELECT sum(total_amt - appl_amt) INTO l_cred_tot 
	FROM credithead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cust_code = p_corp_cust 
	AND org_cust_code = p_cust_code 
	AND total_amt != appl_amt 

	IF l_cred_tot IS NULL THEN 
		LET l_cred_tot = 0 
	END IF 
	LET l_inv_tot = l_inv_tot - l_cred_tot 

	IF l_inv_tot < p_cred_limit THEN 
		RETURN true 
	ELSE 
		RETURN false 
	END IF 
END FUNCTION 
########################################################################
# END FUNCTION cc_credit_chk(p_cust_code,p_corp_cust,p_cred_limit)
########################################################################

{
########################################################################
# FUNCTION initialize_invoice(p_inv_num)
#
# called by edit_invoice
########################################################################
FUNCTION initialize_invoice(p_inv_num) 
	DEFINE p_inv_num LIKE invoicehead.inv_num 

	DELETE FROM t_invoicedetl WHERE 1=1 #empty temp table t_invoicedetl
	INITIALIZE glob_rec_customer.* TO NULL 
	INITIALIZE glob_rec_warehouse.* TO NULL 
	INITIALIZE glob_rec_invoicehead.* TO NULL 
	INITIALIZE glob_rec_customership.* TO NULL 

	IF p_inv_num IS NOT NULL THEN #EDIT or NEW Invoice
		CALL db_invoicehead_get_rec(UI_OFF,p_inv_num) RETURNING glob_rec_invoicehead.* 
		--SELECT * INTO glob_rec_invoicehead.* 
		--FROM invoicehead 
		--WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		--AND inv_num = p_inv_num 

		CALL db_customer_get_rec(UI_OFF,glob_rec_invoicehead.cust_code  ) RETURNING glob_rec_customer.* 
--		SELECT * INTO glob_rec_customer.* 
--		FROM customer 
--		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
--		AND cust_code = glob_rec_invoicehead.cust_code 

		INSERT INTO t_invoicedetl SELECT * FROM invoicedetl 
		WHERE inv_num = glob_rec_invoicehead.inv_num 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 

		#use warehouse code of first line as default - NOTE: what happens with the very first line insert ?
		SELECT ware_code INTO glob_rec_warehouse.ware_code 
		FROM t_invoicedetl 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND inv_num = glob_rec_invoicehead.inv_num 
		AND line_num = 1 

		CALL db_warehouse_get_rec(UI_OFF,glob_rec_warehouse.ware_code) RETURNING glob_rec_warehouse.* 


	ELSE #New Invoice 

		LET glob_rec_invoicehead.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET glob_rec_invoicehead.inv_num = NULL 
		LET glob_rec_invoicehead.ord_num = NULL 
		LET glob_rec_invoicehead.job_code = NULL 
		LET glob_rec_invoicehead.inv_date = today 
		LET glob_rec_invoicehead.entry_code = glob_rec_kandoouser.sign_on_code 
		LET glob_rec_invoicehead.entry_date = today 
		LET glob_rec_invoicehead.disc_per = 0 
		LET glob_rec_invoicehead.tax_per = 0 
		LET glob_rec_invoicehead.goods_amt = 0 
		LET glob_rec_invoicehead.hand_amt = 0 
		LET glob_rec_invoicehead.hand_tax_amt = 0 
		LET glob_rec_invoicehead.freight_amt = 0 
		LET glob_rec_invoicehead.freight_tax_amt = 0 
		LET glob_rec_invoicehead.tax_amt = 0 
		LET glob_rec_invoicehead.disc_amt = 0 
		LET glob_rec_invoicehead.total_amt = 0 
		LET glob_rec_invoicehead.cost_amt = 0 
		LET glob_rec_invoicehead.paid_amt = 0 
		LET glob_rec_invoicehead.paid_date = NULL 
		LET glob_rec_invoicehead.disc_taken_amt = 0 
		LET glob_rec_invoicehead.due_date= NULL 
		LET glob_rec_invoicehead.disc_date = NULL 
		LET glob_rec_invoicehead.expected_date = NULL 
		LET glob_rec_invoicehead.year_num = NULL 
		LET glob_rec_invoicehead.period_num = NULL 
		LET glob_rec_invoicehead.on_state_flag = "N" 
		LET glob_rec_invoicehead.posted_flag = "N" 
		LET glob_rec_invoicehead.seq_num = 0 
		LET glob_rec_invoicehead.line_num = 0 
		LET glob_rec_invoicehead.printed_num = 0 
		LET glob_rec_invoicehead.story_flag = "N" 
		LET glob_rec_invoicehead.rev_date = today 
		LET glob_rec_invoicehead.rev_num = 0 
		LET glob_rec_invoicehead.prepaid_flag = "N" 
		LET glob_rec_invoicehead.inv_ind = "1" 
		LET glob_rec_invoicehead.prev_paid_amt = 0 
		LET glob_rec_invoicehead.jour_num = NULL 
		LET glob_rec_invoicehead.post_date = NULL 
		LET glob_rec_invoicehead.manifest_num = NULL 
		LET glob_rec_invoicehead.stat_date = NULL 
		LET glob_curr_inv_amt = 0 
	END IF 

	CALL serial_init(glob_rec_kandoouser.cmpy_code, "S", "0", p_inv_num) 

END FUNCTION 
########################################################################
# END FUNCTION initialize_invoice(p_inv_num)
########################################################################
}

{
########################################################################
# FUNCTION invoice_summary_wrapper_sum_print(p_mode)
# new FUNCTION ??? MaxGuys ??? new and not completed.. great ! 
# TO seperate the line INPUT process, use FOR program A21, A22
# AND A27
########################################################################
FUNCTION invoice_summary_wrapper_sum_print(p_mode) 
	DEFINE p_mode STRING 
	DEFINE l_msg STRING
	DEFINE l_ret SMALLINT 	#Wizard Style Navigation NAV_BACKWARD=0 NAV_FORWARD SMALLINT=1 NAV_CANCEL SMALLINT=-1 NAV_DONE SMALLINT = 2	
	DEFINE l_run_arg1 STRING	#Used for RUN statements
	DEFINE l_run_arg2 STRING	#Used for RUN statements
	
	IF get_debug() THEN
		DISPLAY "###############################################"	
		LET l_msg = "BEGIN - invoice_summary_wrapper_sum_print(p_mode=", trim(p_mode), ")" 					
		DISPLAY l_msg 
		DISPLAY "###############################################"
	END IF
	
		# OPEN summmary window
		OPEN WINDOW A642 with FORM "A642" 
		CALL windecoration_a("A642") 

		#------------------------------------------------------------------------
		LET l_ret = invoice_summary(p_mode) #WHILE invoice_summary(p_mode) 
		LET l_ret = A21_invoice_result_menu(p_mode)

		##close summary window
		CLOSE WINDOW A642 


	IF int_flag THEN 
		LET int_flag = FALSE
		LET l_ret = NAV_CANCEL
	ELSE
		RETURN l_ret #2
	END IF
END FUNCTION 
########################################################################
# END FUNCTION invoice_summary_wrapper_sum_print(p_mode)
########################################################################
}