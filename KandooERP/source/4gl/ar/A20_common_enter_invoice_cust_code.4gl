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


########################################################################
# FUNCTION enter_new_invoice_cust_code(p_mode)
#
#
########################################################################
FUNCTION enter_new_invoice_cust_code(p_mode) 
	DEFINE p_mode STRING 
	DEFINE l_mgr_code LIKE salesperson.mgr_code 
	DEFINE l_territory_area_code LIKE territory.area_code 
	DEFINE l_ret_nav SMALLINT
	
	IF p_mode = MODE_CLASSIC_EDIT THEN
		CALL display_custromer_credit_status(glob_rec_customer.cust_code,FALSE)
		RETURN TRUE
	END IF
	 
	OPEN WINDOW A137 with FORM "A137" 
	CALL windecoration_a("A137") 
		
	#----------------------------------------------------------------------------------
	# This FUNCTION allows the user TO enter the customer code.
	# WHEN mode = MODE_CLASSIC_EDIT the FUNCTION IS used in a DISPLAY only manner
	#    NB: much of the default VALUES of the invoicehead,  those dependent
	#        upon the customer are SET up in this FUNCTION.
	#
	CLEAR FORM 
	OPTIONS INPUT NO WRAP --disable FOR this scope 
	INPUT glob_rec_customer.cust_code WITHOUT DEFAULTS FROM customer.cust_code ATTRIBUTE(UNBUFFERED)
		BEFORE INPUT 
			IF p_mode = MODE_CLASSIC_EDIT THEN 
				EXIT INPUT 
			ELSE 
				LET glob_rec_customer.cust_code = NULL
				MESSAGE kandoomsg2("A",1062,"") 			#A1062 Enter Customer Code
			END IF 

			CALL publish_toolbar("kandoo","A21a","inp-cust_code-2") 

		ON ACTION "REFRESH"
			CALL windecoration_a("A137")
			
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "actNewCustomer" 
			CALL clear_user_clipboard() --clear db clipboard 
			CALL run_prog("A11","","","","") 
			CALL ui.ComboBox.ForName("cust_code").CLEAR() 
			CALL comboList_customer("cust_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 
			LET glob_rec_customer.cust_code = get_db_clipboard_string_val() --store new customer id in db clipboard 

		ON ACTION "CUSTOMER" #Customer Details
		--ON KEY (F8) --customer details 
			CALL cinq_clnt(glob_rec_kandoouser.cmpy_code,glob_rec_customer.cust_code) --customer details
			CALL windecoration_a("A137") 
			NEXT FIELD cust_code 

		ON ACTION "LOOKUP" infield (cust_code)--Lookup customer 
			LET glob_rec_customer.cust_code = show_clnt(glob_rec_kandoouser.cmpy_code)
			CALL windecoration_a("A137") 
			NEXT FIELD cust_code 

		ON CHANGE customer.cust_code
			CALL db_customer_get_rec(UI_OFF,glob_rec_customer.cust_code) RETURNING  glob_rec_customer.*
			IF glob_rec_customer.cust_code IS NULL THEN #NOTFOUND 
				ERROR kandoomsg2("A",9009,"")				#9009 Customer code NOT found - Try Window
				NEXT FIELD cust_code 
			END IF 
			
			CALL db_country_localize(db_customer_get_country_code(UI_OFF,glob_rec_customer.cust_code)) #Localize

			#Preview Data... ------------------
			CALL display_custromer_credit_status(glob_rec_customer.cust_code,FALSE) #DISPLAY all customer data/info incl. balance..
			
			IF glob_rec_customer.cust_code IS NULL THEN 
				ERROR kandoomsg2("U",9102,"")				#9102 Value must be entered
				NEXT FIELD cust_code 
			END IF 


			IF glob_rec_customer.delete_flag = "Y" THEN 
				ERROR kandoomsg2("A",9144,"")				#9144" Customer has been marked FOR deletion"
				NEXT FIELD cust_code 
			END IF 

			IF glob_rec_customer.hold_code IS NOT NULL THEN
				LET glob_temp_text = db_holdreas_get_reason_text(UI_OFF,glob_rec_customer.hold_code) 
				ERROR kandoomsg2("E",7018,glob_temp_text) 		#7018" Warning : Nominated Customer 'On Hold'"
				NEXT FIELD cust_code 
			END IF 

			LET l_territory_area_code = db_territory_get_area_code(UI_OFF,glob_rec_customer.territory_code)
			LET l_mgr_code = db_salesperson_get_mgr_code(UI_OFF,glob_rec_customer.sale_code)

			IF glob_rec_customer.corp_cust_code IS NOT NULL AND glob_rec_customer.corp_cust_ind = "1" THEN
				CALL db_customer_get_rec(UI_OFF,glob_rec_customer.corp_cust_code) RETURNING glob_rec_corpcust.* 
				IF glob_rec_corpcust.cust_code IS NULL THEN #NOTFOUND  
					ERROR kandoomsg2("A",9115,"") 					#9115 Corporate customer NOT found, setup using A15"
					NEXT FIELD cust_code 
				END IF 

				IF glob_rec_corpcust.delete_flag = "Y" THEN 
					ERROR kandoomsg2("A",9144,"") 				#9144" Customer has been marked FOR deletetion"
					NEXT FIELD cust_code 
				END IF 

				IF glob_rec_customer.currency_code != glob_rec_corpcust.currency_code THEN 
					ERROR kandoomsg2("A",9060,"") 				#9060 Corporate AND Originating customer must use same currency
					NEXT FIELD cust_code 
				END IF 

				IF glob_rec_corpcust.hold_code IS NOT NULL THEN 
					ERROR kandoomsg2("A",9145,"") 				#9145 Corporate customer IS on hold - Release before proceeding
					NEXT FIELD cust_code 
				END IF 

				IF glob_rec_corpcust.cred_override_ind = 0 THEN 
					IF glob_rec_corpcust.bal_amt > glob_rec_corpcust.cred_limit_amt THEN 
						ERROR kandoomsg2("A",9301,"") 					#9301 "Corporate Customer has exceeded credit limit"
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
						ERROR kandoomsg2("A",9315,"") 					#9315 customers credit limit exceeded
						NEXT FIELD cust_code 
					END IF 
				END IF 
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

			#END OF Preview Data... ------------------


		AFTER FIELD cust_code 
			IF glob_rec_customer.cust_code IS NULL THEN 
				ERROR kandoomsg2("U",9102,"") 		#9102 Value must be entered
				NEXT FIELD cust_code 
			END IF 

			CALL db_customer_get_rec(UI_OFF,glob_rec_customer.cust_code) RETURNING glob_rec_customer.*
			IF glob_rec_customer.cust_code IS NULL THEN #NOTFOUND 
				ERROR kandoomsg2("A",9009,"") 			#9009 Customer code NOT found - Try Window
				NEXT FIELD cust_code 
			END IF 

			IF glob_rec_customer.delete_flag = "Y" THEN 
				ERROR kandoomsg2("A",9144,"") 			#9144" Customer has been marked FOR deletion"
				NEXT FIELD cust_code 
			END IF 

			IF glob_rec_customer.hold_code IS NOT NULL THEN 
				LET glob_temp_text = db_holdreas_get_reason_text(UI_OFF,glob_rec_customer.hold_code)
				ERROR kandoomsg2("E",7018,glob_temp_text) 				#7018" Warning : Nominated Customer 'On Hold'"
				NEXT FIELD cust_code 
			END IF 

			LET l_territory_area_code = db_territory_get_area_code(UI_OFF,glob_rec_customer.territory_code)
			LET l_mgr_code = db_salesperson_get_mgr_code(UI_OFF,glob_rec_customer.sale_code )

			IF glob_rec_customer.corp_cust_code IS NOT NULL	AND glob_rec_customer.corp_cust_ind = "1" THEN 

				CALL db_customer_get_rec(UI_OFF,glob_rec_customer.corp_cust_code) RETURNING glob_rec_corpcust.*

				IF glob_rec_corpcust.cust_code IS NULL THEN #not found 
					ERROR kandoomsg2("A",9115,"") 				#9115 Corporate customer NOT found, setup using A15"
					NEXT FIELD cust_code 
				END IF 

				IF glob_rec_corpcust.delete_flag = "Y" THEN 
					ERROR kandoomsg2("A",9144,"") 				#9144" Customer has been marked FOR deletetion"
					NEXT FIELD cust_code 
				END IF 

				IF glob_rec_customer.currency_code != glob_rec_corpcust.currency_code THEN 
					ERROR kandoomsg2("A",9060,"") 				#9060 Corporate AND Originating customer must use same currency
					NEXT FIELD cust_code 
				END IF 

				IF glob_rec_corpcust.hold_code IS NOT NULL THEN 
					ERROR kandoomsg2("A",9145,"") 				#9145 Corporate customer IS on hold - Release before proceeding
					NEXT FIELD cust_code 
				END IF 

				IF glob_rec_corpcust.cred_override_ind = 0 THEN 
					IF glob_rec_corpcust.bal_amt > glob_rec_corpcust.cred_limit_amt THEN 
						ERROR kandoomsg2("A",9301,"") 					#9301 "Corporate Customer has exceeded credit limit"
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
						ERROR kandoomsg2("A",9315,"") 					#9315 customers credit limit exceeded
						NEXT FIELD cust_code 
					END IF 
				END IF 
			END IF 

			IF glob_rec_customer.corp_cust_code IS NOT NULL 
			AND glob_rec_customer.corp_cust_ind = "1" THEN 
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


	END INPUT #------------------------------------------------------------------------

	OPTIONS INPUT WRAP --turn it ON again FROM here 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false
		LET l_ret_nav = NAV_CANCEL 
		CLOSE WINDOW A137

--		RETURN FALSE 
	ELSE 
		IF p_mode = MODE_CLASSIC_EDIT THEN  #???
			CALL display_custromer_credit_status(glob_rec_customer.cust_code,FALSE)
		END IF
		CLOSE WINDOW A137
		LET l_ret_nav = NAV_FORWARD
		--RETURN TRUE
	END IF
	
	RETURN l_ret_nav 
END FUNCTION 
########################################################################
# END FUNCTION enter_new_invoice_cust_code(p_mode)
########################################################################

