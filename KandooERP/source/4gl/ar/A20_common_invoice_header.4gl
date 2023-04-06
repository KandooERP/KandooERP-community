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
# A20,A21,A22,A27
# Invoice Header INPUT
############################################################
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl" 
GLOBALS "../ar/A2_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/A20_GLOBALS.4gl"

########################################################################
# FUNCTION A21_enter_invoice_header(p_mode)
##
## This FUNCTION opens the third window allowing the user TO enter
## date , reference, fiscal yewar/period etc..
##
########################################################################
FUNCTION A21_enter_invoice_header(p_mode) 
	DEFINE p_mode STRING 
	DEFINE l_rec_tax RECORD LIKE tax.* 
	DEFINE l_rec_term RECORD LIKE term.* 
	DEFINE l_rec_salesperson RECORD LIKE salesperson.* 
	DEFINE l_save_date DATE 
	DEFINE l_invalid_period SMALLINT 
	DEFINE l_orig_ware_code LIKE warehouse.ware_code 
	DEFINE l_ret_nav SMALLINT 	#Wizard Style Navigation NAV_BACKWARD=0 NAV_FORWARD SMALLINT=1 NAV_CANCEL SMALLINT=-1 NAV_DONE SMALLINT = 2

	LET l_ret_nav = NAV_FORWARD #default value wizzard style direction	
	
	OPEN WINDOW A139 with FORM "A139" #invoice header window
	CALL windecoration_a("A139")

	DISPLAY BY NAME glob_rec_arparms.inv_ref1_text 
	#------------------------
	# Set up valid defaults
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

	LET l_orig_ware_code = glob_rec_warehouse.ware_code 
	
	#-------------------------------------
	# SELECT tax & description
	SELECT * INTO l_rec_tax.* 
	FROM tax 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND tax_code = glob_rec_invoicehead.tax_code 

	IF status = NOTFOUND THEN 
		LET l_rec_tax.desc_text = "**********" 
	END IF 

	#------------------------------------------------------
	# SELECT warehouse & description
	IF glob_rec_warehouse.ware_code IS NOT NULL THEN #check if warehouse is actually enabled for this invoice
		CALL db_warehouse_get_rec(UI_OFF,glob_rec_warehouse.ware_code ) RETURNING glob_rec_warehouse.* 
		IF sqlca.sqlcode != 0 THEN
			LET glob_rec_warehouse.desc_text = "**********" 
		END IF 
	END IF	
	
	#-------------------------------------
	# SELECT salesperson & description
	CALL db_salesperson_get_rec(UI_OFF,glob_rec_invoicehead.sale_code) RETURNING l_rec_salesperson.*
	IF l_rec_salesperson.sale_code IS NULL THEN
		LET l_rec_salesperson.name_text = "**********"
	END IF
	
	#-------------------------------------
	# SELECT term & description
	SELECT * INTO l_rec_term.* 
	FROM term 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND term_code = glob_rec_invoicehead.term_code 
	IF status = NOTFOUND THEN 
		LET l_rec_term.desc_text = "**********" 
	END IF 
	
	#--------------------------------
	# SELECT default year & period

	IF p_mode = MODE_CLASSIC_ADD THEN 
		CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,glob_rec_invoicehead.inv_date) 
		RETURNING 
			glob_rec_invoicehead.year_num, 
			glob_rec_invoicehead.period_num 
	END IF 
	
	MESSAGE kandoomsg2("A",1064,"")	#A1064 Enter Invoice Stuff - F8 Cust Inq.
	#User enters InvoiceHead information inc. default warehouse and tax code # Form A138
	INPUT BY NAME
		glob_rec_invoicehead.purchase_code, 
		glob_rec_invoicehead.inv_date, 
		glob_rec_invoicehead.year_num, 
		glob_rec_invoicehead.period_num, 
		glob_rec_warehouse.ware_code, 
		glob_rec_invoicehead.sale_code, 
		glob_rec_invoicehead.term_code, 
		glob_rec_invoicehead.tax_code, 
		glob_rec_invoicehead.job_code, # ????
		glob_rec_invoicehead.entry_code, 
		glob_rec_invoicehead.conv_qty WITHOUT DEFAULTS ATTRIBUTE(UNBUFFERED) 

		BEFORE INPUT
--			#Not sure if this field attribute call is on the correct place.. looks like invoice_detl
--			IF glob_rec_warehouse.ware_code IS NULL THEN #Warehous disabled for this invoice
--				CALL set_fieldattribute_readonly("invoicedetl.line_text",FALSE)
--			ELSE
--				CALL set_fieldattribute_readonly("invoicedetl.line_text",TRUE)
--			END IF

			IF glob_rec_warehouse.ware_code IS NOT NULL THEN
				DISPLAY glob_rec_warehouse.desc_text TO warehouse.desc_text
			ELSE
				DISPLAY "Warenhouse NOT used" TO warehouse.desc_text				
			END IF  
			
			DISPLAY l_rec_salesperson.name_text TO salesperson.name_text  
			DISPLAY l_rec_term.desc_text TO term.desc_text  
			DISPLAY l_rec_tax.desc_text TO tax.desc_text  
			DISPLAY glob_rec_invoicehead.currency_code TO invoicehead.currency_code #HuHo: attribute(GREEN) #why with color / green ? I'll remove it 

			CALL publish_toolbar("kandoo","A21a","inp-invoicehead-3") 
			CALL dialog.setActionHidden("ACCEPT",TRUE)
			
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
			
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "NAV_BACKWARD"
			LET l_ret_nav = NAV_BACKWARD
			EXIT INPUT
		
		ON ACTION (ACCEPT,"NAV_FORWARD")
			LET l_ret_nav = NAV_FORWARD
			ACCEPT INPUT

		ON ACTION "LOOKUP" infield (sale_code) 
			LET glob_rec_invoicehead.sale_code = show_sale(glob_rec_kandoouser.cmpy_code) 
			NEXT FIELD sale_code 
			
		ON ACTION "LOOKUP" infield (term_code) 
			LET glob_rec_invoicehead.term_code = show_term(glob_rec_kandoouser.cmpy_code) 
			NEXT FIELD term_code 
			
		ON ACTION "LOOKUP" infield (tax_code) 
			LET glob_rec_invoicehead.tax_code = show_tax(glob_rec_kandoouser.cmpy_code) 
			NEXT FIELD tax_code 
			
		ON ACTION "LOOKUP" infield (ware_code) 
			LET glob_rec_warehouse.ware_code = show_ware(glob_rec_kandoouser.cmpy_code) 
			NEXT FIELD ware_code 

		ON ACTION "DETAIL" --KEY (F8) --customer details 
			CALL cinq_clnt(glob_rec_kandoouser.cmpy_code,glob_rec_customer.cust_code) --customer details 
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
					LET glob_rec_invoicehead.conv_qty = get_conv_rate(
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
				ERROR kandoomsg2("A",9180,"")	#9180 Exchange rate must be entered.
				NEXT FIELD conv_qty 
			END IF 

			IF glob_rec_invoicehead.conv_qty <= 0 THEN 
				ERROR kandoomsg2("A",9181,"") #9181 " Exchange Rate must be greater than zero "
				NEXT FIELD conv_qty 
			END IF 

		ON CHANGE sale_code
			DISPLAY db_salesperson_get_name_text(UI_OFF,glob_rec_invoicehead.sale_code) TO name_text  

		AFTER FIELD sale_code 
			IF glob_rec_invoicehead.sale_code IS NULL THEN 
				ERROR kandoomsg2("U",9102,"") #9102 Value must be entered
				NEXT FIELD sale_code 
			ELSE 
				CALL db_salesperson_get_name_text(UI_OFF,glob_rec_invoicehead.sale_code) RETURNING l_rec_salesperson.name_text			
				IF sqlca.sqlcode != 0 THEN
					ERROR "Valid Salesperson required" --kandoomsg2("U",9105,"")#9105 RECORD NOT found; Try window.
					NEXT FIELD sale_code 
				ELSE 
					DISPLAY l_rec_salesperson.name_text TO name_text

				END IF 
			END IF 

		ON CHANGE ware_code
			IF glob_rec_warehouse.ware_code IS NOT NULL THEN
				DISPLAY db_warehouse_get_desc_text(UI_ON,glob_rec_warehouse.ware_code) TO warehouse.desc_text
			ELSE
				DISPLAY "WareHouse Disabled for this invoice" TO warehouse.desc_text
				MESSAGE "Disable Warehouse usage for this invoice"
			END IF
					
		BEFORE FIELD ware_code 
			## Change of warehouse NOT permitted during edit
			## as it has potential TO change all prices/costs etc..
			IF glob_rec_invoicehead.line_num > 0 THEN 
				IF NOT get_is_screen_navigation_forward() THEN 
					NEXT FIELD previous 
				ELSE 
					NEXT FIELD NEXT 
				END IF 
			END IF 

		AFTER FIELD ware_code 
			IF glob_rec_warehouse.ware_code IS NULL THEN
				MESSAGE "Warehouse Products are disabled for this invoice" 
				--ERROR kandoomsg2("U",9102,"")  #9102 Value must be entered
				--NEXT FIELD ware_code 
			ELSE 
				CALL db_warehouse_get_rec(UI_OFF,glob_rec_warehouse.ware_code) RETURNING glob_rec_warehouse.* 
				IF sqlca.sqlcode != 0 THEN
					ERROR kandoomsg2("U",9105,"")	#9105 RECORD NOT found; Try window.
					NEXT FIELD ware_code 
				ELSE 
					DISPLAY glob_rec_warehouse.desc_text TO warehouse.desc_text 

				END IF 
			END IF 

		ON CHANGE term_code
			DISPLAY db_term_get_desc_text(UI_OFF,glob_rec_invoicehead.term_code) TO term.desc_text
			
		AFTER FIELD term_code 
			IF glob_rec_invoicehead.term_code IS NULL THEN 
				ERROR kandoomsg2("U",9102,"") #9102 Value must be entered
				NEXT FIELD term_code 
			ELSE 
				SELECT * INTO l_rec_term.* 
				FROM term 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND term_code = glob_rec_invoicehead.term_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("U",9105,"") 				#9105 RECORD NOT found; Try window.
					NEXT FIELD term_code 
				ELSE 
					DISPLAY l_rec_term.desc_text TO term.desc_text 
				END IF 
			END IF 

		ON CHANGE tax_code
				SELECT * INTO l_rec_tax.* 
				FROM tax 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND tax_code = glob_rec_invoicehead.tax_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("U",9105,"")	#9105 RECORD NOT found; Try window.
					NEXT FIELD tax_code 
				ELSE 
					DISPLAY l_rec_tax.desc_text TO tax.desc_text 
				END IF 

		AFTER FIELD tax_code 
			IF glob_rec_invoicehead.tax_code IS NULL THEN 
				ERROR kandoomsg2("U",9102,"") #9102 Value must be entered
				NEXT FIELD tax_code 
			ELSE 
				SELECT * INTO l_rec_tax.* 
				FROM tax 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND tax_code = glob_rec_invoicehead.tax_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("U",9105,"")		#9105 RECORD NOT found; Try window.
					NEXT FIELD tax_code 
				ELSE 
					DISPLAY l_rec_tax.desc_text TO tax.desc_text 
				END IF 
			END IF 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
			
				#------------------------------------------
				# Fiscal year/period validation
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
				
				#----------------------
				# Warehouse validation
				IF glob_rec_warehouse.ware_code IS NOT NULL THEN #Warehouse is enabled for this invoice
					IF p_mode = MODE_CLASSIC_ADD OR (l_orig_ware_code IS NOT NULL AND l_orig_ware_code != " ") THEN					
						IF NOT db_warehouse_pk_exists(UI_OFF,glob_rec_warehouse.ware_code) THEN 
							ERROR kandoomsg2("U",9105,"")			#9105 RECORD NOT found; Try window.
							NEXT FIELD ware_code 
						END IF 
					END IF 
				END IF
				
				#----------------------------
				# Salesperson validation
				SELECT 1 FROM salesperson 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND sale_code = glob_rec_invoicehead.sale_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("U",9105,"")				#9105 RECORD NOT found; Try window.
					NEXT FIELD sale_code 
				END IF 
				
				#--------------------
				# Term validation
				SELECT 1 FROM term 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND term_code = glob_rec_invoicehead.term_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("U",9105,"")	#9105 RECORD NOT found; Try window.
					NEXT FIELD term_code 
				END IF 
				
				#---------------------
				# Tax validation
				SELECT * INTO l_rec_tax.* FROM tax 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND tax_code = glob_rec_invoicehead.tax_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("U",9105,"")			#9105 RECORD NOT found; Try window.
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
				
				#---------------------------------------------------
				# Set up account overlay mask FOR invoice header
				
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
	END INPUT #------------------------------------------------------------

	CLOSE WINDOW A139

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false
		LET l_ret_nav = NAV_CANCEL
	END IF
	
	RETURN l_ret_nav 
END FUNCTION 
########################################################################
# END FUNCTION A21_enter_invoice_header(p_mode)
########################################################################
