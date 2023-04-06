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
GLOBALS "../ar/A20_GLOBALS.4gl"
GLOBALS "../ar/A21_GLOBALS.4gl" 

########################################################################
# FUNCTION validate_field_and_update_temp_line(p_field_name,p_rec_invoicedetl)
# Common validation routines are NOT usually in max but has
# been included here TO avoid gross duplication of code
# This FUNCTION now uses validation based on whether the line
# IS being added OR editted.
#
# NOTE: a) It validates b) updates line c) returns true/false and invoiceRecord 
# 
########################################################################
FUNCTION validate_field_and_update_temp_line(p_field_name,p_rec_invoicedetl) 
	DEFINE p_field_name CHAR(15) 
	DEFINE p_rec_invoicedetl RECORD LIKE invoicedetl.* 
	DEFINE l_ret_valid BOOLEAN
	DEFINE l_rec_invoicedetl_backup RECORD LIKE invoicedetl.* 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.* #keeps product amount etc. details
	DEFINE l_float FLOAT #required for amount calculation
	DEFINE l_disc_per LIKE invoicedetl.disc_per 
	DEFINE l_unit_sale_amt LIKE invoicedetl.unit_sale_amt 
	DEFINE i SMALLINT 
	DEFINE l_idx SMALLINT 
	DEFINE l_scrn_opt LIKE language.yes_flag 
	DEFINE l_msg STRING
	DEFINE l_ret_next_field STRING #next field to go to for possible validation return
	IF get_debug() THEN
		LET l_msg = "START FUNCTION validate_field_and_update_temp_line(p_field_name=", trim(p_field_name) , ",", "p_rec_invoicedetl=", trim(p_rec_invoicedetl), ")"
		CALL debug_show_invoicedetl(l_msg,p_rec_invoicedetl.*)
	END IF

	#Create record-backup from DB	
	SELECT * INTO l_rec_invoicedetl_backup.*   #Backup the line - we get this invoice line from the DB .. argument AND DB ?????
	FROM t_invoicedetl 
	WHERE line_num = p_rec_invoicedetl.line_num 
	
	LET l_ret_valid = TRUE #invalid validations will set it to false
	CASE p_field_name 
		#WARE_CODE -----------------------------------------------------------------------------------------------
		WHEN "ware_code"
			#not much to validate
			IF  p_rec_invoicedetl.ware_code IS NULL THEN
				LET p_rec_invoicedetl.part_code = NULL
			END IF

		#PART_CODE -----------------------------------------------------------------------------------------------
		WHEN "part_code" 

			#01 - Check - part_code can NOT be NULL when ware_code is NULL
			IF (p_rec_invoicedetl.ware_code IS NULL) AND (p_rec_invoicedetl.ware_code IS NULL) THEN #Warehouse is disabled for this invoice -> part_code can be empty /no Warehouse validation
				LET p_rec_invoicedetl.unit_sale_amt = 0 
				LET p_rec_invoicedetl.line_text = 0
				ERROR "PartCode can not be empty if warehouse is disabled"
				LET l_ret_valid = FALSE
				RETURN l_ret_valid,p_rec_invoicedetl.* 
			END IF
			
--#--------- Original - not sure if we need this			
--			## We van now edit Adjustment & Sundry Receipt invoices which have no
--			## product lines AND no ware_code.  IF the ware_code IS NULL, do NOT
--			## allow non-NULL part_code. Restore price & description overwitten above.
--			##
--				IF p_rec_invoicedetl.part_code IS NOT NULL AND p_rec_invoicedetl.ware_code IS NULL THEN  #part_code has data AND Warehouse is NOT set / disabled
--				ERROR kandoomsg2("A",9319,"") 	#9319 Product lines NOT allowed on Adjustment Invoices
--				LET p_rec_invoicedetl.unit_sale_amt = l_rec_invoicedetl_backup.unit_sale_amt 
--				LET p_rec_invoicedetl.tax_code = l_rec_invoicedetl_backup.tax_code
--				LET p_rec_invoicedetl.line_text = l_rec_invoicedetl_backup.line_text
--				LET l_ret_valid = FALSE 
--				RETURN l_ret_valid,p_rec_invoicedetl.* 
--			END IF 

			# Original Code			
			#02 - Original line had free item OR original lineprt ode is differnt to modified line			
			#edit existing row changed free item to part code			
			#PartCode IS NULL OR BACKUP Part is different -> existing part_ode entry has been modified
			IF(l_rec_invoicedetl_backup.part_code IS NULL) OR #NEW OR EDIT, if it#s unchanged, no re-calculation/changes should be done
				(l_rec_invoicedetl_backup.part_code != p_rec_invoicedetl.part_code) THEN #part has changed (either new or edit invoice line)

				#Get product record if part code exists
				IF p_rec_invoicedetl.part_code IS NOT NULL THEN #get product details record with new part code
					#GET Product Details based on part_code 
					CALL db_product_get_rec(UI_OFF,p_rec_invoicedetl.part_code) RETURNING l_rec_product.*

					#--------------------------------------------------------------------
					#Product parts can be superceeded by newer/replacement product parts
					#--------------------------------------------------------------------
					IF l_rec_product.super_part_code IS NOT NULL THEN 
						LET l_idx = 0 

						WHILE l_rec_product.super_part_code IS NOT NULL 
							LET l_idx = l_idx + 1 

							IF NOT valid_part(glob_rec_kandoouser.cmpy_code,l_rec_product.super_part_code, p_rec_invoicedetl.ware_code, TRUE,2,0,"","","") THEN 
								LET p_rec_invoicedetl.part_code = NULL 
								LET p_rec_invoicedetl.line_text = NULL
								LET l_ret_valid = FALSE  
								RETURN l_ret_valid,p_rec_invoicedetl.* 
							END IF
							#get product based on SUPER PART CODE 
							CALL db_product_get_rec(UI_OFF,l_rec_product.super_part_code) RETURNING p_rec_invoicedetl.*

							IF l_idx > 20 THEN 
								ERROR kandoomsg2("E",9183,"") 					#9183 Product code supercession limit exceeded
								LET p_rec_invoicedetl.part_code = NULL 
								LET p_rec_invoicedetl.line_text = NULL
								LET l_ret_valid = FALSE  
								RETURN l_ret_valid,p_rec_invoicedetl.* 
							END IF 

						END WHILE 

						ERROR kandoomsg2("E",7060,l_rec_product.part_code) 					#7060 Product replaced by superceded product .....
						LET p_rec_invoicedetl.part_code = l_rec_product.part_code 
						LET p_rec_invoicedetl.line_text = l_rec_product.desc_text 
						LET l_ret_valid = FALSE
						RETURN l_ret_valid,p_rec_invoicedetl.* 

					ELSE 
						IF NOT valid_part(glob_rec_kandoouser.cmpy_code,p_rec_invoicedetl.part_code,p_rec_invoicedetl.ware_code,TRUE,2,0,"","","") THEN
							LET l_ret_valid = FALSE 
							RETURN l_ret_valid,p_rec_invoicedetl.* 
						END IF 
					END IF
					# why is this here.. it was proessed with correct part_code					
					## Unit Price always calc. b/c in Add Mode
				END IF 
			END IF

--		#Part Code is valid - Retrieve some data from the DB/part data
			LET p_rec_invoicedetl.line_text = l_rec_product.desc_text #part fine.. get part line_text
			LET p_rec_invoicedetl.unit_sale_amt = unit_price(p_rec_invoicedetl.ware_code, p_rec_invoicedetl.part_code, p_rec_invoicedetl.level_code)
			LET p_rec_invoicedetl.tax_code = db_prodstatus_get_sale_tax_code(UI_OFF,p_rec_invoicedetl.ware_code, p_rec_invoicedetl.part_code)
			LET p_rec_invoicedetl.line_acct_code	= db_category_get_sale_acct_code(UI_OFF,l_rec_product.cat_code)
			LET p_rec_invoicedetl.cat_code				= l_rec_product.cat_code

			#Retrieve data from product status record
			CALL db_prodstatus_get_rec(UI_OFF,p_rec_invoicedetl.ware_code,p_rec_invoicedetl.part_code)
			RETURNING l_rec_prodstatus.*  
			
			LET p_rec_invoicedetl.tax_code				= l_rec_prodstatus.sale_tax_code
			LET p_rec_invoicedetl.unit_cost_amt = l_rec_prodstatus.wgted_cost_amt	* glob_rec_invoicehead.conv_qty 
			LET p_rec_invoicedetl.list_price_amt = l_rec_prodstatus.list_amt * glob_rec_invoicehead.conv_qty 
			
			IF p_rec_invoicedetl.list_price_amt = 0 THEN 
				LET p_rec_invoicedetl.list_price_amt=p_rec_invoicedetl.unit_sale_amt 
				LET p_rec_invoicedetl.disc_per = 0 
			END IF 

			#IF unit sales amount is NULL -> Apply Special discount  ????
			IF p_rec_invoicedetl.unit_sale_amt IS NULL THEN 
				## calc price based on disc_per
				LET p_rec_invoicedetl.unit_sale_amt = (p_rec_invoicedetl.disc_per/100)*p_rec_invoicedetl.list_price_amt 
			END IF 
		
			#Deal with optional Discount
			IF p_rec_invoicedetl.disc_per IS NULL THEN 
				## calc disc_per based on price
				LET l_float = 100 * (p_rec_invoicedetl.list_price_amt-p_rec_invoicedetl.unit_sale_amt) /p_rec_invoicedetl.list_price_amt 
				IF l_float <= 0 THEN 
					LET p_rec_invoicedetl.disc_per = 0 
					LET p_rec_invoicedetl.list_price_amt=p_rec_invoicedetl.unit_sale_amt 
				ELSE 
					LET p_rec_invoicedetl.disc_per = l_float 
				END IF 
			END IF 

			LET p_rec_invoicedetl.disc_amt = p_rec_invoicedetl.list_price_amt	- p_rec_invoicedetl.unit_sale_amt
--			#TaxCode is taken from product 
--			LET p_rec_invoicedetl.tax_code = l_rec_prodstatus.sale_tax_code #already done prior... 
---------------
			 
--			LET p_rec_invoicedetl.class_code			= l_rec_product.class_code 
--			LET p_rec_invoicedetl.line_acct_code	= l_rec_product.line_acct_code 

--			LET p_rec_invoicedetl.unit_cost_amt				= l_rec_product.unit_cost_amt 
--			LET p_rec_invoicedetl.ext_cost_amt				= l_rec_product.ext_cost_amt 
--			LET p_rec_invoicedetl.uom_code				= l_rec_product.line_text 
--
--
--			LET p_rec_invoicedetl.line_acct_code	= db_category_get_sale_acct_code(UI_OFF,db_product_get_cat_code(UI_OFF,l_rec_invoicedetl.part_code)) 
--			LET p_rec_invoicedetl.unit_sale_amt		= l_rec_invoicedetl.unit_sale_amt 
--			LET p_rec_invoicedetl.tax_code				= l_rec_invoicedetl.tax_code		#prodstatus.tax_code
--			LET p_rec_invoicedetl.disc_amt				= l_rec_invoicedetl.disc_amt
--			LET p_rec_invoicedetl.tax_per					= db_tax_get_tax_per(UI_OFF,p_rec_invoicedetl.tax_code)		#prodstatus.tax_code
			 
			LET l_ret_valid = TRUE

		#LINE_TEXT -----------------------------------------------------------------------------------------------
		WHEN "line_text" 
			IF p_rec_invoicedetl.ware_code IS NULL AND p_rec_invoicedetl.line_text IS NULL THEN
				ERROR "Line Text can not be empty when the warehouse is disabled"
				LET l_ret_valid = FALSE
				RETURN l_ret_valid,p_rec_invoicedetl.*
			END IF
			#Get first/default GL-Sales-Account
			LET p_rec_invoicedetl.line_acct_code = db_category_get_first_sale_acct_code(UI_OFF)
			
		LET l_ret_valid = TRUE

		#LINE_ACCT_CODE -----------------------------------------------------------------------------------------------
		WHEN "line_acct_code"			
			IF p_rec_invoicedetl.line_acct_code IS NULL AND ((p_rec_invoicedetl.line_total_amt > 0) OR (p_rec_invoicedetl.part_code IS NOT NULL)) THEN
				ERROR "GL-Account for an invoice line can not be empty"
				LET l_ret_valid = FALSE
				RETURN l_ret_valid,p_rec_invoicedetl.*
			END IF
--			#HuHo I assume, we need to associate this free/none-warehouse product with some GL acccount
--			#Amount 0 = this is just a comment line.. some information in the invoice without effecting the invoice totals
--			IF (p_rec_invoicedetl.line_total_amt > 0) AND (p_rec_invoicedetl.part_code IS NULL) THEN 
--				LET p_rec_invoicedetl.line_acct_code = enter_acct(p_rec_invoicedetl.line_acct_code)  #none-warehouse products need to have a GL account associated 
--			END IF
--			
--			LET l_ret_valid = TRUE
		
		#SHIP_QTY -----------------------------------------------------------------------------------------------
		WHEN "ship_qty"
			#First and major test for ship_qty
			IF l_rec_invoicedetl_backup.ship_qty < 0 OR l_rec_invoicedetl_backup.ship_qty IS NULL THEN
				ERROR "Quantity can not be Negative"
				LET l_ret_valid = FALSE
				RETURN l_ret_valid,p_rec_invoicedetl.*
			END IF
			
			#Detailed validation
			CASE
				#Warehouse Part  
				WHEN p_rec_invoicedetl.ware_code IS NULL #Warehouse is disabled for this invoice -> no further work with warehouse
					IF p_rec_invoicedetl.ship_qty < 0 THEN --warehouse does not allow ZERO or negative quantity
						ERROR "Quantity can not be negative"
						LET l_ret_valid = FALSE 
						RETURN l_ret_valid,p_rec_invoicedetl.*
					END IF

				WHEN (p_rec_invoicedetl.ware_code IS NULL) AND (p_rec_invoicedetl.ship_qty = 0)  --warehouse does not allow ZERO or negative quantity
						LET p_rec_invoicedetl.line_acct_code = NULL #comment line have no GL account
						ERROR "Quantity can not be negative"
						LET l_ret_valid = FALSE 
						RETURN l_ret_valid,p_rec_invoicedetl.*
					
				#None-Warehouse part
				WHEN p_rec_invoicedetl.ware_code IS NOT NULL #Warehouse is ENABLED for this invoice -> part_code can be empty /no Warehouse validation
					IF p_rec_invoicedetl.ship_qty < 1 THEN --warehouse does not allow ZERO or negative quantity
						ERROR "Quantity can not be zero or negative"
						LET l_ret_valid = FALSE 
						RETURN l_ret_valid,p_rec_invoicedetl.*
					END IF

					#Something from EO which we haven't got yet
					IF (p_rec_invoicedetl.sold_qty IS NULL) THEN #needs checking when we have EO 
						LET p_rec_invoicedetl.ship_qty = l_rec_invoicedetl_backup.sold_qty
						LET l_ret_valid = FALSE 
						RETURN l_ret_valid,p_rec_invoicedetl.* 
--					ELSE 
--						IF l_scrn_opt = "N" THEN 
--							IF p_rec_invoicedetl.ship_qty < 0 THEN 
--								ERROR kandoomsg2("E",9180,"") 	#9180 Quantity may NOT be negative
--								LET p_rec_invoicedetl.ship_qty = 0 - p_rec_invoicedetl.ship_qty
--								LET l_ret_valid = FALSE  
--								RETURN l_ret_valid,p_rec_invoicedetl.* 
--							END IF 
--						END IF 
					END IF 
			END CASE 



		#UNIT_SALE_AMT -----------------------------------------------------------------------------------------------
		WHEN "unit_sale_amt"
			CASE 
				WHEN p_rec_invoicedetl.ware_code IS NULL --Warehouse disabled
					IF p_rec_invoicedetl.unit_sale_amt IS NULL OR p_rec_invoicedetl.unit_sale_amt < 0 THEN
						ERROR kandoomsg2("E",9239,"") 
						#9239 Selling price cannot be negative
						LET l_ret_valid = FALSE
						RETURN l_ret_valid,p_rec_invoicedetl.*
					--ELSE
					--	RETURN TRUE,p_rec_invoicedetl.*					 					
					END IF
				
				WHEN p_rec_invoicedetl.ware_code IS NOT NULL --Warehouse enabled 
					IF p_rec_invoicedetl.unit_sale_amt IS NULL THEN 
						LET p_rec_invoicedetl.unit_sale_amt = unit_price(p_rec_invoicedetl.ware_code,	p_rec_invoicedetl.part_code,p_rec_invoicedetl.level_code)
						LET l_ret_valid = FALSE 
						RETURN l_ret_valid,p_rec_invoicedetl.* 
					ELSE 
						IF p_rec_invoicedetl.unit_sale_amt < 0 THEN 
							ERROR kandoomsg2("E",9239,"") 
							#9239 Selling price cannot be negative
							LET l_ret_valid = FALSE 
							RETURN l_ret_valid,p_rec_invoicedetl.* 
						ELSE 
							IF p_rec_invoicedetl.list_price_amt = 0 THEN 
								LET p_rec_invoicedetl.list_price_amt =p_rec_invoicedetl.unit_sale_amt 
							END IF 
						END IF 
					END IF
			END CASE 

			LET l_ret_valid = TRUE
			 
		#TAX_CODE-----------------------------------------------------------------------------------------------
		WHEN "tax_code"
			CASE 
				WHEN p_rec_invoicedetl.ware_code IS NULL --Warehouse disabled
					IF p_rec_invoicedetl.tax_code IS NULL THEN
						MESSAGE "Tax Code is empty - Only valid for none-warehouse products" 
						#9239 Selling price cannot be negative
						#RETURN FALSE,p_rec_invoicedetl.*
					--ELSE
					--	RETURN TRUE,p_rec_invoicedetl.*					 					
					END IF
				
				WHEN p_rec_invoicedetl.ware_code IS NOT NULL --Warehouse enabled
					IF p_rec_invoicedetl.tax_code IS NULL THEN
						MESSAGE "Tax Code is empty. With Warehouse items, you must use a tax code"
					END IF 
			END CASE

						#9239 Selling price cannot be negative
						#RETURN FALSE,p_rec_invoicedetl.*
					--ELSE
					--	RETURN TRUE,p_rec_invoicedetl.*					 					
					

					#Warehouse Products keep their own tax code/money
{ 
					IF p_rec_invoicedetl.unit_sale_amt IS NULL THEN 
						LET p_rec_invoicedetl.unit_sale_amt = unit_price(p_rec_invoicedetl.ware_code,	p_rec_invoicedetl.part_code,p_rec_invoicedetl.level_code) 
						RETURN false,p_rec_invoicedetl.* 
					ELSE 
						IF p_rec_invoicedetl.unit_sale_amt < 0 THEN 
							ERROR kandoomsg2("E",9239,"") 
							#9239 Selling price cannot be negative
							RETURN false,p_rec_invoicedetl.* 
						ELSE 
							IF p_rec_invoicedetl.list_price_amt = 0 THEN 
								LET p_rec_invoicedetl.list_price_amt =p_rec_invoicedetl.unit_sale_amt 
							END IF 
						END IF 
					END IF
}	
		 
		#UNIT_TAX_AMT -----------------------------------------------------------------------------------------------
		WHEN "unit_tax_amt"
			IF p_rec_invoicedetl.unit_tax_amt IS NULL THEN
				LET p_rec_invoicedetl.unit_tax_amt = 0
			END IF
				
			IF p_rec_invoicedetl.unit_tax_amt < 0 THEN
				ERROR "Tax Amount can not be negative"
				LET p_rec_invoicedetl.unit_tax_amt = 0
				LET l_ret_valid = FALSE
				RETURN l_ret_valid,p_rec_invoicedetl.*
			END IF

		#ALL - Check all fields! -----------------------------------------------------------------------------------------------
		WHEN "all"

			CASE
				#WAREHOUSE (ware_code IS NULL & part_code NOT NULL)
				WHEN  p_rec_invoicedetl.ware_code IS NULL AND p_rec_invoicedetl.part_code IS NOT NULL
					LET l_ret_next_field = A21_INV_LINE_FIELD_WARE_CODE 
					ERROR "No Warehouse choosen! You can not enter a part_code"
					LET l_ret_valid = FALSE
					
				#WAREHOUSE (ware_code NOT NULL & part_code IS NULL)
				WHEN  p_rec_invoicedetl.ware_code IS NOT NULL AND p_rec_invoicedetl.part_code IS NULL #ware_code is specified
					LET l_ret_next_field = A21_INV_LINE_FIELD_PART_CODE  
					ERROR "Warehouse is used/choosen! You need to enter a product part_code"
					LET l_ret_valid = FALSE		
	
				# "line_text" 
				WHEN p_rec_invoicedetl.line_text IS NULL 
					LET l_ret_next_field = A21_INV_LINE_FIELD_LINE_TEXT  
					ERROR "Description Line Text can not be empty"
					LET l_ret_valid = FALSE		
	
				# GL nominal code acct_code
				WHEN p_rec_invoicedetl.line_acct_code IS NULL AND ((p_rec_invoicedetl.line_total_amt > 0) OR (p_rec_invoicedetl.part_code IS NOT NULL))
					LET l_ret_next_field = A21_INV_LINE_FIELD_LINE_ACCT_CODE  
					ERROR "GL-Account for an invoice line can not be empty"
					LET l_ret_valid = FALSE		
				 
			END CASE
			#IF ANY Of the "ALL" cases/validations fail, return   
			IF l_ret_valid = FALSE THEN
				CALL DIALOG.nextField(l_ret_next_field)
				RETURN l_ret_valid,l_ret_next_field,p_rec_invoicedetl.*
			END IF



			#----------------------------------------------------------------

			#Write invoice line record to DB
			CALL invoicedetl_update_line(p_rec_invoicedetl.*)
			
			SELECT * INTO p_rec_invoicedetl.* 
			FROM t_invoicedetl 
			WHERE line_num = p_rec_invoicedetl.line_num 
		
			IF get_debug() THEN
				LET l_msg = "ALL FUNCTION validate_field_and_update_temp_line(p_field_name=", trim(p_field_name) , ",", "p_rec_invoicedetl=", trim(p_rec_invoicedetl), ")"
				CALL debug_show_invoicedetl(l_msg,p_rec_invoicedetl.*)
			END IF

--	#Last final check to be sure... and return l_ret_valid
--	IF ((p_rec_invoicedetl.ware_code IS NULL) AND (p_rec_invoicedetl.line_text IS NULL)) #Warehouse is disabled for this invoice -> part_code can be empty /no Warehouse validation
--	OR ((p_rec_invoicedetl.ware_code IS NOT NULL) AND (p_rec_invoicedetl.part_code IS NULL)) #Warehouse enabled
--	THEN
--		LET l_ret_valid = FALSE
		RETURN l_ret_valid,p_rec_invoicedetl.*
--	END IF 

 
	END CASE 
	#######################

	#IF we reach this point, validation is valid
	LET l_ret_valid = TRUE 

--	#Not sure if we need this here again
--	IF p_rec_invoicedetl.unit_tax_amt IS NULL THEN 
--		LET p_rec_invoicedetl.unit_tax_amt = 0 
--	END IF 

	#Write invoice line record to DB
	CALL invoicedetl_update_line(p_rec_invoicedetl.*) RETURNING p_rec_invoicedetl.*
	#----------------------------------------------------------------
	--CALL db_t_invoicedetl_get_line_rec(p_rec_invoicedetl.line_num) RETURNING p_rec_invoicedetl.*
--	SELECT * INTO p_rec_invoicedetl.* 
--	FROM t_invoicedetl 
--	WHERE line_num = p_rec_invoicedetl.line_num 

	IF get_debug() THEN
		LET l_msg = "END FUNCTION validate_field_and_update_temp_line(p_field_name=", trim(p_field_name) , ",", "p_rec_invoicedetl=", trim(p_rec_invoicedetl), ")"
		CALL debug_show_invoicedetl(l_msg,p_rec_invoicedetl.*)
	END IF

{
	#Last final check to be sure... and return l_ret_valid
	IF ((p_rec_invoicedetl.ware_code IS NULL) AND (p_rec_invoicedetl.line_text IS NULL)) #Warehouse is disabled for this invoice -> part_code can be empty /no Warehouse validation
	OR ((p_rec_invoicedetl.ware_code IS NOT NULL) AND (p_rec_invoicedetl.part_code IS NULL)) #Warehouse enabled
	THEN
		RETURN FALSE, l_rec_invoicedetl_backup.* #validation failed - return original record
	ELSE
		RETURN l_ret_valid, p_rec_invoicedetl.* #return modified validated record
	END IF
}
	RETURN l_ret_valid, l_ret_next_field,p_rec_invoicedetl.* #return modified validated record 
END FUNCTION 
########################################################################
# END FUNCTION validate_field_and_update_temp_line(p_field_name,p_rec_invoicedetl)
########################################################################


########################################################################
# FUNCTION enter_acct(p_acct_code)
#
#
########################################################################
FUNCTION enter_acct(p_acct_code) 
	DEFINE p_acct_code LIKE invoicedetl.line_acct_code 
	DEFINE l_rec_coa RECORD LIKE coa.* 

	LET l_rec_coa.acct_code = p_acct_code 

	OPEN WINDOW A672 with FORM "A672" 
	CALL windecoration_a("A672") 

	MESSAGE kandoomsg2("Q",1025,"") #1025 Enter G.L. Account - ESC TO Continue
	INPUT BY NAME l_rec_coa.acct_code WITHOUT DEFAULTS ATTRIBUTE(UNBUFFERED) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","A21d","inp-acct_code") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
			
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP"
		--ON KEY (control-b) 
			LET glob_temp_text = show_acct(glob_rec_kandoouser.cmpy_code) 
			IF glob_temp_text IS NOT NULL AND glob_temp_text != " " THEN 
				LET l_rec_coa.acct_code = glob_temp_text 
			END IF 
			NEXT FIELD acct_code 

		ON CHANGE acct_code
			DISPLAY db_coa_get_desc_text(UI_OFF,l_rec_coa.acct_code) TO coa.desc_text
			
		AFTER FIELD acct_code 
			IF l_rec_coa.acct_code IS NULL THEN 
				ERROR kandoomsg2("Q",9077,"") 			#9077" Account Code IS required FOR Non-Inventory Lines"
				NEXT FIELD acct_code 

			ELSE 

				SELECT unique 1 FROM coa 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND acct_code = l_rec_coa.acct_code 

				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("Q",9078,"") 				#9078" Invoice Line Account code NOT found"
					NEXT FIELD acct_code 
				END IF 

				CALL verify_acct_code(
					glob_rec_kandoouser.cmpy_code,
					l_rec_coa.acct_code, 
					glob_rec_invoicehead.year_num, 
					glob_rec_invoicehead.period_num) 
				RETURNING l_rec_coa.* 

				IF l_rec_coa.acct_code IS NULL THEN 
					ERROR kandoomsg2("U",9102,"") 				#9102 Value must be entered
					NEXT FIELD acct_code 
				END IF 

				IF NOT acct_type(glob_rec_kandoouser.cmpy_code,l_rec_coa.acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"Y") THEN 
					NEXT FIELD acct_code 
				END IF 

			END IF 



	END INPUT 
	#######################################

	CLOSE WINDOW A672 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN p_acct_code 
	ELSE 
		RETURN l_rec_coa.acct_code 
	END IF 

END FUNCTION
########################################################################
# END FUNCTION enter_acct(p_acct_code)
########################################################################