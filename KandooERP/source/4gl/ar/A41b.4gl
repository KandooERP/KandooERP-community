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
#    !!! A41b !!
# \file
# \brief module E5Cb -  ????? why E5Cb ?????

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl"
GLOBALS "../ar/A4_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/A41_GLOBALS.4gl" 

###########################################################################
# MODULE scope variables
###########################################################################

###########################################################################
# FUNCTION credit_for_invoice_details()
#
# Works with glob_rec_credithead.*
###########################################################################
FUNCTION credit_for_invoice_details() 
	DEFINE l_rec_credreas RECORD LIKE credreas.* 
	DEFINE l_rec_salesperson RECORD LIKE salesperson.* 
	DEFINE l_rec_tax RECORD LIKE tax.* 
	DEFINE l_temp_date DATE 
	DEFINE l_part_code LIKE product.part_code 
	DEFINE l_save_reason_code LIKE credithead.reason_code 
	DEFINE l_save_sale_code LIKE credithead.sale_code 
	DEFINE l_save_ware_code LIKE warehouse.ware_code 
	DEFINE l_save_tax_code LIKE credithead.tax_code 
	DEFINE l_invalid_period SMALLINT 

	IF glob_rec_credithead.reason_code IS NOT NULL THEN 
		SELECT * INTO l_rec_credreas.* 
		FROM credreas 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND reason_code = glob_rec_credithead.reason_code 
		IF sqlca.sqlcode = NOTFOUND THEN 
			ERROR kandoomsg2("A",9058,"") #9058 Credit reason does NOT exist - Try Window"
			LET l_rec_credreas.reason_text = "**********" 
		END IF 
	END IF 

	IF glob_rec_credithead.sale_code IS NOT NULL THEN 
		CALL db_salesperson_get_name_text(UI_OFF,glob_rec_credithead.sale_code) RETURNING l_rec_salesperson.name_text
		IF sqlca.sqlcode != 0 THEN
			ERROR kandoomsg2("E",9214,"") #9214" Salesperson Code do NOT exist "
			LET l_rec_salesperson.name_text = "**********" 
		END IF 
	ELSE 
		LET glob_rec_credithead.sale_code = glob_rec_customer.sale_code 
	END IF 
	
	IF glob_rec_warehouse.ware_code IS NOT NULL AND glob_rec_warehouse.ware_code != " " THEN #adjustment credits
		CALL db_warehouse_get_desc_text(UI_OFF,glob_rec_warehouse.ware_code) RETURNING glob_rec_warehouse.desc_text
		IF sqlca.sqlcode = NOTFOUND THEN 
			ERROR kandoomsg2("E",9057,"") #9057" Warehouse does NOT exist - try window"
			LET glob_rec_warehouse.desc_text = "**********" 
		END IF 

	ELSE 
		LET glob_rec_warehouse.desc_text = "Adjustment" 
	END IF 

	IF glob_rec_credithead.tax_code IS NOT NULL THEN 
		SELECT desc_text INTO l_rec_tax.desc_text 
		FROM tax 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND tax_code = glob_rec_credithead.tax_code 
		IF sqlca.sqlcode = NOTFOUND THEN 
			ERROR kandoomsg2("E",9057,"") #9057" Taxation Code do NOT exist "
			LET l_rec_tax.desc_text = "**********" 
		END IF 
	ELSE 
		LET glob_rec_credithead.tax_code = glob_rec_customer.tax_code 
	END IF 
	
	IF glob_rec_credithead.conv_qty IS NULL OR glob_rec_credithead.conv_qty = 0 THEN 
		LET glob_rec_credithead.conv_qty = get_conv_rate(
			glob_rec_kandoouser.cmpy_code,
			glob_rec_credithead.currency_code, 
			glob_rec_credithead.cred_date,
			CASH_EXCHANGE_SELL) 
	END IF 
	
	OPEN WINDOW A670 with FORM "A670" 
	CALL windecoration_a("A670") 

	LET glob_temp_text = glob_rec_arparms.credit_ref1_text clipped,"......." 
	DISPLAY glob_temp_text TO arparms.credit_ref1_text 

	MESSAGE kandoomsg2("E",1062,"")	#1062 Enter Payment Details - F8 Customer Inquiry - F9 Credit Details
	DISPLAY 
		l_rec_credreas.reason_text, 
		l_rec_salesperson.name_text, 
		glob_rec_warehouse.desc_text, 
		l_rec_tax.desc_text 
	TO 
		credreas.reason_text, 
		salesperson.name_text, 
		warehouse.desc_text, 
		tax.desc_text 

	DISPLAY BY NAME glob_rec_credithead.currency_code #HuHo: attribute(GREEN) #why with color / green ? I'll remove it 
	INPUT BY NAME 
		glob_rec_credithead.cred_text, 
		glob_rec_credithead.cred_date, 
		glob_rec_credithead.year_num, 
		glob_rec_credithead.period_num, 
		glob_rec_credithead.conv_qty, 
		glob_rec_credithead.reason_code, 
		glob_rec_warehouse.ware_code, 
		glob_rec_credithead.tax_code, 
		glob_rec_credithead.sale_code WITHOUT DEFAULTS 


		BEFORE INPUT 
			CALL publish_toolbar("kandoo","A41b","inp-credithead") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield (reason_code) 
			#FUNCTION show_credreas(p_cmpy,p_filter_where2_text,p_def_reason_code) 
			LET glob_temp_text = show_credreas(glob_rec_kandoouser.cmpy_code,NULL,glob_rec_credithead.reason_code) 
			IF glob_temp_text IS NOT NULL THEN 
				LET glob_rec_credithead.reason_code = glob_temp_text 
			END IF 
			NEXT FIELD reason_code 
			
		ON ACTION "LOOKUP" infield (sale_code) 
			LET glob_temp_text = show_sale(glob_rec_kandoouser.cmpy_code) 
			
			IF glob_temp_text IS NOT NULL THEN 
				LET glob_rec_credithead.sale_code = glob_temp_text 
			END IF 
			NEXT FIELD sale_code 
			
		ON ACTION "LOOKUP" infield (ware_code) 
			LET glob_temp_text = show_ware(glob_rec_kandoouser.cmpy_code) 
			
			IF glob_temp_text IS NOT NULL THEN 
				LET glob_rec_warehouse.ware_code = glob_temp_text 
			END IF 
			NEXT FIELD ware_code 
			
		ON ACTION "LOOKUP" infield (tax_code) 
			LET glob_temp_text = show_tax(glob_rec_kandoouser.cmpy_code) 
			IF glob_temp_text IS NOT NULL THEN 
				LET glob_rec_credithead.tax_code = glob_temp_text 
			END IF 
			NEXT FIELD tax_code 

		ON KEY (F8) --customer details 
			CALL cinq_clnt(glob_rec_kandoouser.cmpy_code,glob_rec_credithead.cust_code) --customer details 

		BEFORE FIELD cred_date 
			LET l_temp_date = glob_rec_credithead.cred_date 

		AFTER FIELD cred_date 
			IF glob_rec_credithead.cred_date IS NULL THEN 
				LET glob_rec_credithead.cred_date = l_temp_date 
				NEXT FIELD cred_date 
			END IF 

			IF l_temp_date != glob_rec_credithead.cred_date THEN 
				CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,glob_rec_credithead.cred_date) 
				RETURNING 
					glob_rec_credithead.year_num, 
					glob_rec_credithead.period_num 
				
				DISPLAY BY NAME 
					glob_rec_credithead.year_num, 
					glob_rec_credithead.period_num 
			END IF 

		BEFORE FIELD conv_qty 
			IF glob_rec_glparms.base_currency_code = glob_rec_credithead.currency_code THEN 
				LET glob_rec_credithead.conv_qty = 1.0 
				DISPLAY BY NAME glob_rec_credithead.conv_qty 

				IF fgl_lastkey() = fgl_keyval("up") THEN 
					NEXT FIELD previous 
				ELSE 
					NEXT FIELD NEXT 
				END IF 
			END IF 

		AFTER FIELD conv_qty 
			IF glob_rec_credithead.conv_qty IS NULL OR glob_rec_credithead.conv_qty = 0 THEN 
				ERROR kandoomsg2("E",9060,"") 				#9060" Currency Exchange Rate must have a value "
				LET glob_rec_credithead.conv_qty = get_conv_rate(
					glob_rec_kandoouser.cmpy_code,
					glob_rec_credithead.currency_code, 
					glob_rec_credithead.cred_date,
					CASH_EXCHANGE_SELL) 
				NEXT FIELD conv_qty 
			END IF
			 
			IF glob_rec_credithead.conv_qty < 0 THEN 
				ERROR kandoomsg2("E",9061,"") 				#9061 " Exchange Rate must be greater than zero "
				NEXT FIELD conv_qty 
			END IF
			 
			IF glob_rec_credithead.conv_qty != get_conv_rate(
				glob_rec_kandoouser.cmpy_code,
				glob_rec_credithead.currency_code, 
				glob_rec_credithead.cred_date,
				CASH_EXCHANGE_SELL) THEN 
				
				IF kandoomsg("E",8012,"")  = "Y" THEN #8012 Exchange Rate IS NOT current. Do you wish TO Update.Y/N
					LET glob_rec_credithead.conv_qty = get_conv_rate(
						glob_rec_kandoouser.cmpy_code,
						glob_rec_credithead.currency_code, 
						glob_rec_credithead.cred_date,
						CASH_EXCHANGE_SELL) 
					NEXT FIELD conv_qty 
				END IF 
			END IF 

		BEFORE FIELD reason_code 
			LET l_save_reason_code = glob_rec_credithead.reason_code 

		ON CHANGE reason_code
			DISPLAY glob_rec_credithead.reason_code TO reason_code 
			DISPLAY l_rec_credreas.reason_text TO reason_text 
						
		AFTER FIELD reason_code 
			IF glob_rec_credithead.reason_code IS NOT NULL THEN 
				SELECT reason_text INTO l_rec_credreas.reason_text 
				FROM credreas 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND reason_code = glob_rec_credithead.reason_code 
				IF sqlca.sqlcode = NOTFOUND THEN 
					ERROR kandoomsg2("A",9058,"") 		#9058" credit reason do NOT exist "
					LET glob_rec_credithead.reason_code = l_save_reason_code 
					NEXT FIELD reason_code 
				END IF 
				
				DISPLAY glob_rec_credithead.reason_code TO reason_code 
				DISPLAY l_rec_credreas.reason_text TO reason_text 
			END IF 

		BEFORE FIELD sale_code 
			LET l_save_sale_code = glob_rec_credithead.sale_code 

		ON CHANGE sale_code
			DISPLAY glob_rec_credithead.sale_code TO sale_code 
			DISPLAY l_rec_salesperson.name_text TO salesperson.name_text 

		AFTER FIELD sale_code 
			IF glob_rec_credithead.sale_code IS NOT NULL THEN 
				CALL db_salesperson_get_name_text(UI_OFF,glob_rec_credithead.sale_code) RETURNING l_rec_salesperson.name_text
				IF sqlca.sqlcode != 0 THEN
					ERROR kandoomsg2("E",9214,"") 				#9214" salesperson code do NOT exist "
					LET glob_rec_credithead.sale_code = l_save_sale_code 
					NEXT FIELD sale_code 
				END IF 
				
				DISPLAY glob_rec_credithead.sale_code TO sale_code 
				DISPLAY l_rec_salesperson.name_text TO salesperson.name_text 

			END IF 
			IF NOT get_is_screen_navigation_forward() THEN 
				### Only allow tax code entry IF credit has no lines
				SELECT unique 1 FROM t_creditdetl 
				IF status = 0 THEN 
					NEXT FIELD ware_code 
				END IF 
			END IF 

		BEFORE FIELD ware_code 
			LET l_save_ware_code = glob_rec_warehouse.ware_code 

		ON CHANGE ware_code
				DISPLAY glob_rec_warehouse.ware_code TO warehouse.ware_code 
				DISPLAY glob_rec_warehouse.desc_text TO warehouse.desc_text 
		
		AFTER FIELD ware_code 
			IF glob_rec_warehouse.ware_code IS NOT NULL THEN 
				IF glob_rec_credithead.cred_ind = "4" THEN 
					ERROR kandoomsg2("E",9272,"") 		#9227 Warehouse must NOT be entered FOR adjustments
					LET glob_rec_warehouse.ware_code = l_save_ware_code 
					NEXT FIELD ware_code 
				END IF 

				CALL db_warehouse_get_desc_text(UI_OFF,glob_rec_warehouse.ware_code) RETURNING glob_rec_warehouse.desc_text
				IF sqlca.sqlcode = NOTFOUND THEN 
					ERROR kandoomsg2("E",9047,"") 	#9047 Warehouse do NOT exist try window
					LET glob_rec_warehouse.ware_code = l_save_ware_code 
					NEXT FIELD ware_code 
				END IF 
				
				DISPLAY glob_rec_warehouse.ware_code TO warehouse.ware_code 
				DISPLAY glob_rec_warehouse.desc_text TO warehouse.desc_text 
			END IF 

		BEFORE FIELD tax_code 
			### Only allow tax code entry IF credit has no lines
			SELECT unique 1 FROM t_creditdetl 
			IF status = 0 THEN 
				NEXT FIELD sale_code 
			END IF 
			
			LET l_save_tax_code = glob_rec_credithead.tax_code 

		ON CHANGE tax_code
				DISPLAY glob_rec_credithead.tax_code TO credithead.tax_code 
				DISPLAY l_rec_tax.desc_text TO tax.desc_text 

		AFTER FIELD tax_code 
			IF glob_rec_credithead.tax_code IS NOT NULL THEN 
				SELECT desc_text INTO l_rec_tax.desc_text 
				FROM tax 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND tax_code = glob_rec_credithead.tax_code 
				IF sqlca.sqlcode = NOTFOUND THEN 
					ERROR kandoomsg2("E",9057,"") #9057" Taxation Code do NOT exist "
					LET glob_rec_credithead.tax_code = l_save_tax_code 
					NEXT FIELD tax_code 
				END IF 

				DISPLAY glob_rec_credithead.tax_code TO credithead.tax_code 
				DISPLAY l_rec_tax.desc_text TO tax.desc_text 
			END IF 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				CALL valid_period(
					glob_rec_kandoouser.cmpy_code,
					glob_rec_credithead.year_num, 
					glob_rec_credithead.period_num,
					"AR") 
				RETURNING 
					glob_rec_credithead.year_num, 
					glob_rec_credithead.period_num, 
					l_invalid_period 
				
				IF l_invalid_period THEN 
					NEXT FIELD year_num 
				END IF
				# warehouse will be commented based on an old feature request from Ali and Anna
				#support NONE.Warehouse items im invoices etc.. even if warehouse is installed
				#Hybrid of warehouse and free items
				#------------------------------------------- 
				#IF glob_rec_warehouse.ware_code IS NULL 
				#AND glob_rec_credithead.cred_ind != "4" 
				#AND glob_rec_company.module_text[9] = "I" THEN 
				#	##
				#	## Warehouse IS only mandatory FOR Inventory sites
				#	##
				#	ERROR kandoomsg2("E",9046,"") 				#9046" Warehouse code must be Entered"
				#	NEXT FIELD ware_code 
				#END IF 
				
				IF glob_rec_credithead.reason_code IS NULL THEN 
					ERROR kandoomsg2("W",9277,"") 
					#9277" Credit reason must be entered. "
					LET glob_rec_credithead.reason_code = glob_rec_arparms.reason_code 
					NEXT FIELD reason_code 
				ELSE 
					LET l_rec_credreas.reason_text = NULL 
					SELECT reason_text INTO l_rec_credreas.reason_text 
					FROM credreas 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND reason_code = glob_rec_credithead.reason_code 
					IF sqlca.sqlcode = NOTFOUND THEN 
						ERROR kandoomsg2("A",9058,"") 					#9058" credit reason do NOT exist "
						NEXT FIELD reason_code 
					END IF 
				
					DISPLAY BY NAME l_rec_credreas.reason_text 

				END IF 
				IF glob_rec_credithead.sale_code IS NULL THEN 
					ERROR kandoomsg2("E",9062,"") 				#9062" Salesperson code must be Entered"
					LET glob_rec_credithead.sale_code = glob_rec_customer.sale_code 
					NEXT FIELD sale_code 
				END IF 
				
				IF glob_rec_credithead.tax_code IS NULL THEN 
					ERROR kandoomsg2("E",9059,"") 				#9059" Taxation Code must be Entered"
					LET glob_rec_credithead.tax_code = glob_rec_customer.tax_code 
					NEXT FIELD tax_code 
				END IF 
				
				## IF imaged lines exist THEN check that each has a prodstatus
				## FOR this warehouse
				DECLARE c_creditdetl CURSOR FOR 
				SELECT part_code FROM t_creditdetl 
				WHERE part_code IS NOT NULL 
				
				FOREACH c_creditdetl INTO l_part_code 
					SELECT 1 FROM prodstatus 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = l_part_code 
					AND ware_code = glob_rec_warehouse.ware_code 
					IF status = NOTFOUND THEN 
						ERROR kandoomsg2("E",9241,l_part_code) 	#9241" Warehouse does NOT exists FOR line ",l_part_code," "
						NEXT FIELD ware_code 
					END IF 
				END FOREACH 
			END IF 

	END INPUT 

	CLOSE WINDOW A670 
	
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 
###########################################################################
# END FUNCTION credit_for_invoice_details()
###########################################################################