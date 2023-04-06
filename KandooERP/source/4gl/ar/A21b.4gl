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
GLOBALS "../common/glob_GLOBALS_userDataTypes.4gl"
GLOBALS "../ar/A_AR_GLOBALS.4gl" 
GLOBALS "../ar/A2_GROUP_GLOBALS.4gl"
GLOBALS "../ar/A20_GLOBALS.4gl"
GLOBALS "../ar/A21_GLOBALS.4gl"

###########################################################################
# FUNCTION compare_pos_null_str(p_str1,p_str2)
#
#
###########################################################################
FUNCTION compare_pos_null_str(p_str1,p_str2)
	DEFINE p_str1 STRING
	DEFINE p_str2 STRING
	DEFINE l_ret BOOLEAN
	
	#Both NULL strings
	IF p_str1 IS NULL AND p_str2 IS NULL THEN
		RETURN TRUE
	END IF
	
	#ONE string is NULL
	IF p_str1 IS NULL OR p_str2 IS NULL THEN
		RETURN FALSE
	END IF
	
	IF p_str1 = p_str2 THEN
		RETURN TRUE
	ELSE
		RETURN FALSE
	END IF	

END FUNCTION
###########################################################################
# END FUNCTION compare_pos_null_str(p_str1,p_str2)
###########################################################################


############################################################
# FUNCTION invoicedetl_enable_disable_fields(p_rec_invoicedetl)
# 
# Depending on the warehouse and other attributes i.e. tax code, we need to enable disable related input fields
############################################################
FUNCTION invoicedetl_enable_disable_fields(p_rec_invoicedetl)
	DEFINE p_rec_invoicedetl RECORD LIKE invoicedetl.* 
	--DEFINE p_tax_code LIKE tax.tax_code
	--DEFINE p_ware_code LIKE warehouse.ware_code
	DEFINE l_calc_method_flag LIKE tax.calc_method_flag
	LET l_calc_method_flag = db_tax_get_calc_method_flag(UI_OFF,p_rec_invoicedetl.tax_code)
	#Enable/Disable tax related fields depending on main invoice header tax code


	#NOTE: I have still no idea how all these tax codes (invoice,customer, invoice line and warehouseProduct) work together
	#so, I have still no idea when to enable and when to disable a field...

	#Warehouse Item
	IF p_rec_invoicedetl.ware_code IS NOT NULL THEN  
		CALL Dialog.setFieldActive("invoicedetl.part_code",TRUE) #Warehouse Part Code
		CALL Dialog.setFieldActive("invoicedetl.line_text",FALSE) #None-Warehouse line text OR for warehouse, it will be updated automatically by part details
		CALL Dialog.setFieldActive("invoicedetl.tax_code",TRUE) #Item Tax Code #either tax_code or unit_tax_amt is readOnly
		CALL Dialog.setFieldActive("invoicedetl.unit_tax_amt",FALSE) #FReq-Ali: Item Tax Amount #either tax_code or unit_tax_amt is readOnly
	#No Warehouse Item
	ELSE
		CALL Dialog.setFieldActive("invoicedetl.part_code",FALSE) #Warehouse Part Code
		CALL Dialog.setFieldActive("invoicedetl.line_text",TRUE) #None-Warehouse line text OR for warehouse, it will be updated automatically by part details
		CALL Dialog.setFieldActive("invoicedetl.tax_code",TRUE) #Item Tax Code
		CALL Dialog.setFieldActive("invoicedetl.unit_tax_amt",TRUE) #Item Tax Amount
	END IF

	#New user (Ali) request - For free none-warehouse items, tax can be entered via Tax_code OR by unit tax amount
	IF p_rec_invoicedetl.ware_code IS NULL THEN #free item/part 	
		IF p_rec_invoicedetl.tax_code IS NOT NULL THEN #by default, we always use tax code
			CALL Dialog.setFieldActive("invoicedetl.unit_tax_amt",FALSE) #Item Tax Amount
		ELSE
			CALL Dialog.setFieldActive("invoicedetl.unit_tax_amt",TRUE) #Item Tax Amount
		END IF
	END IF
	
	#Anna confirmed on the 16.03.2021, this is ok (disable qty)
	#Anna spotted this one - qty should be disabled until product base information was entered
	#ship_qty
	IF (p_rec_invoicedetl.ware_code IS NOT NULL AND p_rec_invoicedetl.part_code IS NULL) 
	OR (p_rec_invoicedetl.ware_code IS NULL AND p_rec_invoicedetl.line_text IS NULL) 
	OR p_rec_invoicedetl.line_acct_code IS NULL 
	OR p_rec_invoicedetl.tax_code IS NULL THEN 
			CALL Dialog.setFieldActive("invoicedetl.ship_qty",FALSE)
	ELSE
			CALL Dialog.setFieldActive("invoicedetl.ship_qty",TRUE) 
	END IF
	
	#tax_code
	IF (p_rec_invoicedetl.ware_code IS NOT NULL AND p_rec_invoicedetl.part_code IS NULL) 
	OR (p_rec_invoicedetl.ware_code IS NULL AND p_rec_invoicedetl.line_text IS NULL) 
	OR p_rec_invoicedetl.line_acct_code IS NULL THEN 	
			CALL Dialog.setFieldActive("invoicedetl.tax_code",FALSE)
	ELSE
			CALL Dialog.setFieldActive("invoicedetl.tax_code",TRUE) 
	END IF			
{	
	CASE l_calc_method_flag
		WHEN "P" #The amount of sales tax is dictated by the tax Percentage associated with the Product.
			CALL set_fieldattribute_readonly("invoicedetl.tax_code",FALSE) #Item Tax Code
			CALL set_fieldattribute_readonly("invoicedetl.unit_tax_amt",TRUE) #Item Tax Amount
		
		WHEN "D" #The amount of sales tax is dictated by the money (Dollar/Euro) tax amount associated with the Product.
			CALL set_fieldattribute_readonly("invoicedetl.tax_code",TRUE) #Item Tax Code
			CALL set_fieldattribute_readonly("invoicedetl.unit_tax_amt",FALSE) #Item Tax Amount
		WHEN "T" #The amount of sales tax is a flat percentage of the Transaction Total (ie. invoice or voucher) based on the Customer’s (or Vendor’s) tax rate.
			CALL set_fieldattribute_readonly("invoicedetl.tax_code",TRUE) #Item Tax Code
			CALL set_fieldattribute_readonly("invoicedetl.unit_tax_amt",TRUE) #Item Tax Amount

		WHEN "N" #The amount of (Net) sales tax is calculated by applying the Customer’s (or Vendor’s) tax rate to each Product line in a transaction, (which may result in a difference compared to the Total tax method due to the rounding of each line amount).
			CALL set_fieldattribute_readonly("invoicedetl.tax_code",TRUE) #Item Tax Code
			CALL set_fieldattribute_readonly("invoicedetl.unit_tax_amt",TRUE) #Item Tax Amount

		WHEN "I" #This is used to identify customers, vendors, or products whose prices are Inclusive of tax.  Whether or not tax is calculated depends on its combination with other methods.
			CALL set_fieldattribute_readonly("invoicedetl.tax_code",TRUE) #Item Tax Code
			CALL set_fieldattribute_readonly("invoicedetl.unit_tax_amt",TRUE) #Item Tax Amount

		WHEN "X" #This is used to identify customers, vendors, or products whose prices are Exclusive of tax.  Tax is not added (but may in some circumstances be deducted).
			CALL set_fieldattribute_readonly("invoicedetl.tax_code",TRUE) #Item Tax Code
			CALL set_fieldattribute_readonly("invoicedetl.unit_tax_amt",TRUE) #Item Tax Amount

		WHEN "W" #This is used to identify customers, vendors, and products that are subject to tax where the tax is collected at the last wholesale transaction.  Wholesale tax is calculated at the point of goods receipt entry (for vendors and stocked items with tax type “W”) and posted to a tax payable account.  The tax is then recalculated when posting the Cost of Goods sold for invoices and credits, (for customers and stocked items with tax type “W”), and posted to a tax claimable account.  The amount of tax is calculated from the percentage associated with the tax code stored on the product status record.	
			CALL set_fieldattribute_readonly("invoicedetl.tax_code",TRUE) #Item Tax Code
			CALL set_fieldattribute_readonly("invoicedetl.unit_tax_amt",TRUE) #Item Tax Amount

	END CASE
	}
	#Info: The tax rate is primarily determined by the Customer’s (or Vendor’s) method.  
	#However, in certain situations (defined below) the Product method will modify or overrule this.
	#There are a number of different tax regimes supported by KandooERP.  
	#These are listed in the docs together with suggestions on how Tax Codes should be set up to implement them 
	#(however please refer to the AR Tax Calculation Summary for the definitive rules).
END FUNCTION
############################################################
# END FUNCTION invoicedetl_enable_disable_fields(p_rec_invoicedetl)
############################################################



############################################################################
# FUNCTION debug_info_invoice_line_input_array(p_msg1,p_msg2,line1_num,line2_num, p_idx,p_rec_curr_row_invoicedetl,p_rec_curr_row_invoicedetl_original,p_rec_invoicedetl_list)
#
# DISPLAY Debug information
############################################################################
FUNCTION debug_info_invoice_line_input_array(p_msg1,p_msg2,line1_num,line2_num, p_idx,p_rec_curr_row_invoicedetl,p_rec_curr_row_invoicedetl_original,p_rec_invoicedetl_list)
	DEFINE p_msg1 STRING 
	DEFINE p_msg2 STRING 
	DEFINE line1_num LIKE invoicedetl.line_num
	DEFINE line2_num LIKE invoicedetl.line_num
	DEFINE p_idx SMALLINT
	DEFINE p_rec_curr_row_invoicedetl RECORD LIKE invoicedetl.*
	DEFINE p_rec_curr_row_invoicedetl_original RECORD LIKE invoicedetl.*
	DEFINE p_rec_invoicedetl_list OF dt_rec_invoicedetl_list


	DISPLAY p_msg1 CLIPPED, " ..............................."
	DISPLAY p_msg2
	DISPLAY "p_rec_curr_row_invoicedetl.line_num=", trim(line1_num)
	DISPLAY "l_arr_rec_invoicedetl_list[l_idx].line_num=", trim(line2_num)
	DISPLAY "l_idx=", p_idx
	DISPLAY "..............................."
	CALL debug_show_keys("AFTER FIELD scroll_flag")
	DISPLAY "..............................."
	DISPLAY "p_rec_curr_row_invoicedetl.line_num=", p_rec_curr_row_invoicedetl.line_num		
	DISPLAY "p_rec_curr_row_invoicedetl.part_code=",p_rec_curr_row_invoicedetl.part_code
	DISPLAY "p_rec_curr_row_invoicedetl.ware_code=", p_rec_curr_row_invoicedetl.ware_code
	DISPLAY "p_rec_curr_row_invoicedetl.cat_code=", p_rec_curr_row_invoicedetl.cat_code
	DISPLAY "p_rec_curr_row_invoicedetl.ord_qty=", p_rec_curr_row_invoicedetl.ord_qty
	DISPLAY "p_rec_curr_row_invoicedetl.ship_qty=", p_rec_curr_row_invoicedetl.ship_qty
	DISPLAY "p_rec_curr_row_invoicedetl.line_text=", p_rec_curr_row_invoicedetl.line_text
	DISPLAY "p_rec_curr_row_invoicedetl.unit_sale_amt=", p_rec_curr_row_invoicedetl.unit_sale_amt
	DISPLAY "p_rec_curr_row_invoicedetl.ext_sale_amt=", p_rec_curr_row_invoicedetl.ext_sale_amt
	DISPLAY "p_rec_curr_row_invoicedetl.unit_tax_amt=",p_rec_curr_row_invoicedetl.unit_tax_amt
	DISPLAY "p_rec_curr_row_invoicedetl.ext_tax_amt=", p_rec_curr_row_invoicedetl.ext_tax_amt
	DISPLAY "p_rec_curr_row_invoicedetl.line_total_amt=", p_rec_curr_row_invoicedetl.line_total_amt
	DISPLAY "p_rec_curr_row_invoicedetl.line_acct_code=", p_rec_curr_row_invoicedetl.line_acct_code
	DISPLAY "p_rec_curr_row_invoicedetl.level_code=", p_rec_curr_row_invoicedetl.level_code
	DISPLAY "p_rec_curr_row_invoicedetl.tax_code=", p_rec_curr_row_invoicedetl.tax_code
	DISPLAY "p_rec_curr_row_invoicedetl.list_price_amt=", p_rec_curr_row_invoicedetl.list_price_amt
	#--------------------------------------------------
	DISPLAY "p_rec_curr_row_invoicedetl_original.line_num=", p_rec_curr_row_invoicedetl_original.line_num
	DISPLAY "p_rec_curr_row_invoicedetl_original.part_code=", p_rec_curr_row_invoicedetl_original.part_code
	DISPLAY "p_rec_curr_row_invoicedetl_original.ware_code=", p_rec_curr_row_invoicedetl_original.ware_code
	DISPLAY "p_rec_curr_row_invoicedetl_original.cat_code=", p_rec_curr_row_invoicedetl_original.cat_code
	DISPLAY "p_rec_curr_row_invoicedetl_original.ord_qty=", p_rec_curr_row_invoicedetl_original.ord_qty
	DISPLAY "p_rec_curr_row_invoicedetl_original.ship_qty=", p_rec_curr_row_invoicedetl_original.ship_qty
	DISPLAY "p_rec_curr_row_invoicedetl_original.line_text=", p_rec_curr_row_invoicedetl_original.line_text
	DISPLAY "p_rec_curr_row_invoicedetl_original.unit_sale_amt=", p_rec_curr_row_invoicedetl_original.unit_sale_amt
	DISPLAY "p_rec_curr_row_invoicedetl_original.ext_sale_amt=", p_rec_curr_row_invoicedetl_original.ext_sale_amt
	DISPLAY "p_rec_curr_row_invoicedetl_original.unit_tax_amt=", p_rec_curr_row_invoicedetl_original.unit_tax_amt
	DISPLAY "p_rec_curr_row_invoicedetl_original.ext_tax_amt=", p_rec_curr_row_invoicedetl_original.ext_tax_amt
	DISPLAY "p_rec_curr_row_invoicedetl_original.line_total_amt=", p_rec_curr_row_invoicedetl_original.line_total_amt
	DISPLAY "p_rec_curr_row_invoicedetl_original.line_acct_code=", p_rec_curr_row_invoicedetl_original.line_acct_code
	DISPLAY "p_rec_curr_row_invoicedetl_original.level_code=", p_rec_curr_row_invoicedetl_original.level_code
	DISPLAY "p_rec_curr_row_invoicedetl_original.tax_code=", p_rec_curr_row_invoicedetl_original.tax_code
	DISPLAY "p_rec_curr_row_invoicedetl_original.list_price_amt=", p_rec_curr_row_invoicedetl_original.list_price_amt
	#p_rec_invoicedetl_list --------------------------------------------------
	DISPLAY "p_rec_invoicedetl_list.line_num=", p_rec_invoicedetl_list.line_num
	DISPLAY "p_rec_invoicedetl_list.part_code=", p_rec_invoicedetl_list.part_code
	DISPLAY "p_rec_invoicedetl_list.ware_code=", p_rec_invoicedetl_list.ware_code
--	DISPLAY "p_rec_invoicedetl_list.cat_code=", p_rec_invoicedetl_list.cat_code
--	DISPLAY "p_rec_invoicedetl_list.ord_qty=", p_rec_invoicedetl_list.ord_qty
	DISPLAY "p_rec_invoicedetl_list.ship_qty=", p_rec_invoicedetl_list.ship_qty
	DISPLAY "p_rec_invoicedetl_list.line_text=", p_rec_invoicedetl_list.line_text
	DISPLAY "p_rec_invoicedetl_list.unit_sale_amt=", p_rec_invoicedetl_list.unit_sale_amt
	DISPLAY "p_rec_invoicedetl_list.ext_sale_amt=", p_rec_invoicedetl_list.ext_sale_amt
	DISPLAY "p_rec_invoicedetl_list.unit_tax_amt=", p_rec_invoicedetl_list.unit_tax_amt
	DISPLAY "p_rec_invoicedetl_list.ext_tax_amt=", p_rec_invoicedetl_list.ext_tax_amt
	DISPLAY "p_rec_invoicedetl_list.line_total_amt=", p_rec_invoicedetl_list.line_total_amt
	DISPLAY "p_rec_invoicedetl_list.line_acct_code=", p_rec_invoicedetl_list.line_acct_code
	--DISPLAY "p_rec_invoicedetl_list.level_code=", p_rec_invoicedetl_list.level_code
	DISPLAY "p_rec_invoicedetl_list.tax_code=", p_rec_invoicedetl_list.tax_code
	--DISPLAY "p_rec_invoicedetl_list.list_price_amt=", p_rec_invoicedetl_list.list_price_amt

	DISPLAY "glob_rec_invoicehead.goods_amt", glob_rec_invoicehead.goods_amt  
	DISPLAY "glob_rec_invoicehead.tax_amt =", glob_rec_invoicehead.tax_amt
	DISPLAY "glob_rec_invoicehead.total_amt =", glob_rec_invoicehead.total_amt

END FUNCTION
############################################################################
# END FUNCTION debug_info_invoice_line_input_array(p_msg1,p_msg2,line1_num,line2_num, p_idx,p_rec_curr_row_invoicedetl,p_rec_curr_row_invoicedetl_original,p_rec_invoicedetl_list)
############################################################################





############################################################################
# FUNCTION db_st_invoicedetl_delete_invalid_rows()
#
#		DELETE invalid invoice lines from temp table t_invoicedetl
#
# 	#Original (Doc states, I can enter ZERO Amount invoice lines as comments.. 
#		#so I need to remove the line_total_amt = 0 condition
#		DELETE FROM t_invoicedetl 
#		WHERE part_code IS NULL AND line_text IS NULL AND 
#		(line_total_amt IS NULL OR line_total_amt = 0)
############################################################################
FUNCTION db_st_invoicedetl_delete_invalid_rows()
	DEFINE l_msg STRING

		WHENEVER ERROR CONTINUE #delete row from temp table
			DELETE FROM t_invoicedetl 
			WHERE line_text IS NULL
			--(ware_code IS NOT NULL AND part_code IS NULL)
			--OR (ware_code IS NULL AND line_text IS NULL)
			--OR (tax_code IS NULL)
			OR (line_num IS NULL)
			#I removed these lines because we may add support for comments
			#in form of empty (ZERO Quantity and amount) invoice lines
			--WHERE part_code IS NULL AND line_text IS NULL AND # 
			--(line_total_amt IS NULL OR line_total_amt = 0)
		WHENEVER ERROR STOP
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

END FUNCTION								
############################################################################
# END FUNCTION db_st_invoicedetl_delete_invalid_rows()
############################################################################


############################################################################
# FUNCTION db_st_invoicedetl_delete_row(p_line)
#
# DELETE specified line (line number) from temp table t_invoicedetl
############################################################################
FUNCTION db_st_invoicedetl_delete_row(p_line)
	DEFINE p_line LIKE invoicedetl.line_num
	DEFINE l_msg STRING
{
	LET l_msg = "FUNCTION db_st_invoicedetl_delete_row(", trim(p_line), ")\nArgument can not be 0 or negative"
	IF (p_line < 1) OR (p_line IS NULL) THEN 
		CALL fgl_winmessage("Internal 4gl code error",l_msg,"ERROR")
		RETURN NULL
	END IF	

	IF (p_line IS NOT NULL) AND (p_line != 0) THEN
		WHENEVER ERROR CONTINUE #delete row from temp table
			DELETE FROM t_invoicedetl 
			WHERE line_num = p_line
		WHENEVER ERROR STOP	
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	END IF
}
END FUNCTION
############################################################################
# END FUNCTION db_st_invoicedetl_delete_row(p_line)
############################################################################


############################################################################
# FUNCTION debug_show_keys(p_str)
#
# DEBUG function to show last actions, key code and key name
############################################################################
FUNCTION debug_show_keys(p_str)
	DEFINE p_str STRING
	DEFINE l_label CHAR(30)
	LET l_label = p_str
	DISPLAY "----------------------------------------------------"	
	DISPLAY trim(l_label), ": fgl_lastAction()=",fgl_lastAction()
	DISPLAY trim(l_label), ": fgl_lastkey()=",fgl_lastkey()		
	DISPLAY trim(l_label), ": fgl_keyname()=",fgl_keyname(fgl_lastkey())
	DISPLAY "####################################################"
END FUNCTION
############################################################################
# END FUNCTION debug_show_keys(p_str)
############################################################################


############################################################################
# FUNCTION db_st_invoicedetl_get_arr_rec_invoice_lines()
#
#
# This FUNCTION retrieves all rows from the table t_invoicedetl, 
# corrects line numbers incrementing, removes invalid/empty rows from table
# RETURN l_arr_rec_invoicedetl_list  (entire invoice list ARRAY record)
############################################################################
FUNCTION db_st_invoicedetl_get_arr_rec_invoice_lines()
	DEFINE l_rec_invoicedetl RECORD LIKE invoicedetl.* 
	DEFINE l_arr_rec_invoicedetl_list DYNAMIC ARRAY OF dt_rec_invoicedetl_list
	DEFINE l_idx SMALLINT
	
	DECLARE c_datasource_invoicedetl CURSOR FOR 
	SELECT * FROM t_invoicedetl 
	ORDER BY line_num 

	IF get_debug() THEN
		DISPLAY "---------------------------------------------"
		DISPLAY "db_st_invoicedetl_get_arr_rec_invoice_lines()"
	END IF

	LET l_idx = 0 
	FOREACH c_datasource_invoicedetl INTO l_rec_invoicedetl.*	
		CASE
		WHEN (l_rec_invoicedetl.line_num IS NULL) OR (l_rec_invoicedetl.line_num < 1) #Line Number is NULL, 0 or negative
			IF get_debug() THEN
				DISPLAY "WHEN: Line Number is NULL, 0 or negative"
			END IF

			DELETE FROM t_invoicedetl 
			WHERE line_num = l_rec_invoicedetl.line_num
		
		WHEN (l_rec_invoicedetl.ware_code IS NOT NULL) AND (l_rec_invoicedetl.part_code IS NULL) #PartCode or shiping qty is NULL, 0 or negative	
			IF get_debug() THEN
				DISPLAY "WHEN: Warehouse IS NOT NULL AND PartCode is NULL"
			END IF

			DELETE FROM t_invoicedetl 
			WHERE line_num = l_rec_invoicedetl.line_num

		
		WHEN (l_rec_invoicedetl.ware_code IS NULL) AND (l_rec_invoicedetl.line_text IS NULL) #PartCode or shiping qty is NULL, 0 or negative	
			IF get_debug() THEN
				DISPLAY "WHEN: Warehouse IS NULL AND line_text is NULL"
			END IF

			DELETE FROM t_invoicedetl 
			WHERE line_num = l_rec_invoicedetl.line_num


		WHEN l_rec_invoicedetl.ship_qty < 0  #Shipping qty negative	
			IF get_debug() THEN
				DISPLAY "WHEN: shipping Quantity is negative"
			END IF

			DELETE FROM t_invoicedetl 
			WHERE line_num = l_rec_invoicedetl.line_num

		#Warehouse item invoice lines can not have quantiy 0 or negative / free items can i.e. for adding comments
		WHEN (l_rec_invoicedetl.ware_code IS NOT NULL) AND (l_rec_invoicedetl.ship_qty <= 1)  #Shipping qty negative	
			IF get_debug() THEN
				DISPLAY "WHEN: Warehouse=ON AND shipping Quantity is ZERO or negative"
			END IF

			DELETE FROM t_invoicedetl 
			WHERE line_num = l_rec_invoicedetl.line_num


		OTHERWISE		  
			LET l_idx = l_idx + 1 
			LET l_rec_invoicedetl.ware_code = glob_rec_warehouse.ware_code 

			#Correct by 1 incrementing line number
			IF l_rec_invoicedetl.line_num != l_idx THEN 
				UPDATE t_invoicedetl 
				SET line_num = l_idx 
				WHERE line_num = l_rec_invoicedetl.line_num 
				LET l_rec_invoicedetl.line_num = l_idx 
			END IF 

			CALL invoicedetl_morph_rec_to_list_line(l_rec_invoicedetl.*) RETURNING l_arr_rec_invoicedetl_list[l_idx].*	
--			LET l_arr_rec_invoicedetl_list[l_idx].line_num =			l_rec_invoicedetl.line_num 
--			LET l_arr_rec_invoicedetl_list[l_idx].part_code =			l_rec_invoicedetl.part_code 
--			LET l_arr_rec_invoicedetl_list[l_idx].line_text =			l_rec_invoicedetl.line_text 
--			LET l_arr_rec_invoicedetl_list[l_idx].line_acct_code =l_rec_invoicedetl.line_acct_code 
--			LET l_arr_rec_invoicedetl_list[l_idx].tax_code =			l_rec_invoicedetl.tax_code 
--			LET l_arr_rec_invoicedetl_list[l_idx].tax_per =				db_tax_get_tax_per(UI_OFF,l_rec_invoicedetl.tax_code ) 
--			LET l_arr_rec_invoicedetl_list[l_idx].ship_qty =			l_rec_invoicedetl.ship_qty 
--			LET l_arr_rec_invoicedetl_list[l_idx].unit_sale_amt =	l_rec_invoicedetl.unit_sale_amt
--			LET l_arr_rec_invoicedetl_list[l_idx].disc_amt =			l_rec_invoicedetl.disc_amt
--			LET l_arr_rec_invoicedetl_list[l_idx].unit_tax_amt =	l_rec_invoicedetl.unit_tax_amt
--			LET l_arr_rec_invoicedetl_list[l_idx].ext_sale_amt=		l_rec_invoicedetl.ext_sale_amt
--			LET l_arr_rec_invoicedetl_list[l_idx].ext_tax_amt=		l_rec_invoicedetl.ext_tax_amt				
--			LET l_arr_rec_invoicedetl_list[l_idx].line_total_amt =l_rec_invoicedetl.line_total_amt
 
			#Handle conditional tax for line item/amount 
			#IF glob_rec_arparms.show_tax_flag  = "Y" THEN
			#This option is no longer used - we show all data now 
			 
		END CASE
		
	END FOREACH 
	CLOSE c_datasource_invoicedetl
	IF get_debug() THEN
		DISPLAY "---------------------------------------------"
		DISPLAY "RETURN: l_arr_rec_invoicedetl_list"
	END IF
		
	RETURN l_arr_rec_invoicedetl_list
END FUNCTION	
############################################################################
# END FUNCTION db_st_invoicedetl_get_arr_rec_invoice_lines()
############################################################################


############################################################################
# FUNCTION invoicedetl_morph_rec_to_list_line(p_rec_invoicedetl_source)
#
#
# Returns a invoice line LIST (input array) record based on a invoicedetl record
############################################################################
FUNCTION invoicedetl_morph_rec_to_list_line(p_rec_invoicedetl_source)
	DEFINE p_rec_invoicedetl_source  RECORD LIKE invoicedetl.*
	DEFINE l_ret_rec_invoicedetl_list_line  OF dt_rec_invoicedetl_list

	LET l_ret_rec_invoicedetl_list_line.line_num = p_rec_invoicedetl_source.line_num
	LET l_ret_rec_invoicedetl_list_line.ware_code = p_rec_invoicedetl_source.ware_code 
	LET l_ret_rec_invoicedetl_list_line.part_code = p_rec_invoicedetl_source.part_code 
	LET l_ret_rec_invoicedetl_list_line.line_text = p_rec_invoicedetl_source.line_text 
	LET l_ret_rec_invoicedetl_list_line.line_acct_code = p_rec_invoicedetl_source.line_acct_code 
	LET l_ret_rec_invoicedetl_list_line.tax_code = p_rec_invoicedetl_source.tax_code 
	LET l_ret_rec_invoicedetl_list_line.tax_per = db_tax_get_tax_per(UI_OFF,p_rec_invoicedetl_source.tax_code ) 
	LET l_ret_rec_invoicedetl_list_line.ship_qty = p_rec_invoicedetl_source.ship_qty 
	LET l_ret_rec_invoicedetl_list_line.unit_sale_amt = p_rec_invoicedetl_source.unit_sale_amt
	LET l_ret_rec_invoicedetl_list_line.disc_amt = p_rec_invoicedetl_source.disc_amt
	LET l_ret_rec_invoicedetl_list_line.unit_tax_amt = p_rec_invoicedetl_source.unit_tax_amt
	LET l_ret_rec_invoicedetl_list_line.ext_sale_amt= p_rec_invoicedetl_source.ext_sale_amt
	LET l_ret_rec_invoicedetl_list_line.ext_tax_amt= p_rec_invoicedetl_source.ext_tax_amt 
	LET l_ret_rec_invoicedetl_list_line.line_total_amt = p_rec_invoicedetl_source.line_total_amt

	RETURN l_ret_rec_invoicedetl_list_line.*
END FUNCTION	 
############################################################################
# END FUNCTION invoicedetl_morph_rec_to_list_line(p_rec_invoicedetl_source)
############################################################################


############################################################################
# FUNCTION db_st_invoicedetl_get_row_by_line_num(p_line_num)
#
#
# This FUNCTION retrieves all rows from the table t_invoicedetl, 
# corrects line numbers incrementing, removes invalid/empty rows from table
# RETURNS ArrayRecord l_arr_rec_invoicedetl_list AND l_rec_invoicedetl
############################################################################
FUNCTION db_st_invoicedetl_get_row_by_line_num(p_line_num)
	DEFINE p_line_num LIKE invoicedetl.line_num 
	DEFINE l_rec_invoicedetl RECORD LIKE invoicedetl.*
	DEFINE l_rec_screen_line_invoicedetl OF dt_rec_invoicedetl_list
	DEFINE l_idx SMALLINT
	DEFINE l_msg STRING

	IF get_debug() THEN					
		DISPLAY "..............................."
		DISPLAY "db_st_invoicedetl_get_row_by_line_num(", trim(p_line_num), ")" 
		CALL debug_show_keys("BEFORE FIELD part_code")
		DISPLAY "..............................."
	END IF
	
	IF (p_line_num IS NULL) OR (p_line_num <= 0) THEN #argumentmust not be NULL/0 or negative
		LET l_msg = "Error ?? in FUNCTION db_st_invoicedetl_get_row_by_line_num(", trim(p_line_num), ")"
		CALL fgl_winmessage("Internal 4gl code ERROR",l_msg,"error")
		RETURN NULL
	END IF

	SELECT *
	INTO l_rec_invoicedetl.*
	FROM t_invoicedetl
	WHERE line_num = p_line_num
	
	CALL invoicedetl_morph_rec_to_list_line(l_rec_invoicedetl.*)
	RETURNING l_rec_screen_line_invoicedetl.*
		
	RETURN l_rec_screen_line_invoicedetl.*, l_rec_invoicedetl.*
END FUNCTION	
############################################################################
# END FUNCTION db_st_invoicedetl_get_row_by_line_num(p_line_num)
############################################################################


############################################################################
# FUNCTION db_t_invoicedetl_get_line_rec(p_line_num)
#
#
# Retrieve invoicedetl record based on line_num (not row/array index)
############################################################################
FUNCTION db_t_invoicedetl_get_line_rec(p_line_num)
	DEFINE p_line_num LIKE invoicedetl.line_num
	DEFINE l_rec_invoicedetl RECORD LIKE invoicedetl.*
	DEFINE l_msg STRING
	IF p_line_num IS NULL OR p_line_num < 1 THEN
		LET l_msg ="Error in db_t_invoicedetl_get_line_rec(", trim(p_line_num), ")\nArgument can not be NULL,0 or negative"
		CALL fgl_winmessage("ERROR",l_msg,"ERROR")
		RETURN NULL
	END IF 
	WHENEVER ERROR CONTINUE
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	SELECT * INTO l_rec_invoicedetl.*
				    FROM t_invoicedetl
				    WHERE line_num = p_line_num
	WHENEVER ERROR STOP
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	RETURN l_rec_invoicedetl.*
END FUNCTION				    
############################################################################
# END FUNCTION db_t_invoicedetl_get_line_rec(p_line_num)
############################################################################


############################################################################
# FUNCTION db_st_invoicedetl_delete_line(p_line_num)
#
# Deletes the table row with the specified line_number (column value line_num)
# AND
# retrieves all rows from the table t_invoicedetl, 
# corrects line numbers incrementing, removes invalid/empty rows from table
# RETURNS ArrayRecord l_arr_rec_invoicedetl_list
############################################################################
FUNCTION db_st_invoicedetl_delete_line(p_line_num)
	DEFINE p_line_num LIKE invoicedetl.line_num
	DEFINE l_delete_valid BOOLEAN
	DEFINE l_rec_invoicedetl RECORD LIKE invoicedetl.* 
	DEFINE l_arr_rec_invoicedetl_list DYNAMIC ARRAY OF dt_rec_invoicedetl_list
	DEFINE l_idx SMALLINT
	
	LET l_delete_valid = FALSE
	
	IF (p_line_num IS NULL) OR (p_line_num < 1) THEN
		ERROR "Can not delete product line with line number 0 (or negative)"
		LET l_delete_valid = FALSE
	ELSE 
		LET l_delete_valid = TRUE
	END IF
	
	DECLARE c_del_invoicedetl CURSOR FOR 
	SELECT * FROM t_invoicedetl 
	ORDER BY line_num 

	LET l_idx = 0 
	FOREACH c_del_invoicedetl INTO l_rec_invoicedetl.*
	
		CASE
			WHEN (l_delete_valid = TRUE) AND (l_rec_invoicedetl.line_num = p_line_num)
				DELETE FROM t_invoicedetl 
				WHERE line_num = l_rec_invoicedetl.line_num
			 
			WHEN (l_rec_invoicedetl.line_num IS NULL) OR (l_rec_invoicedetl.line_num < 1) #Line Number is NULL, 0 or negative
				DELETE FROM t_invoicedetl 
				WHERE line_num = l_rec_invoicedetl.line_num
			
			WHEN (l_rec_invoicedetl.part_code IS NULL) OR (l_rec_invoicedetl.ship_qty < 1) #PartCode or shiping qty is NULL, 0 or negative	
				DELETE FROM t_invoicedetl 
				WHERE line_num = l_rec_invoicedetl.line_num
	
			OTHERWISE		  
				LET l_idx = l_idx + 1 
				LET l_rec_invoicedetl.ware_code = glob_rec_warehouse.ware_code 
	
				#Correct by 1 incrementing line number
				IF l_rec_invoicedetl.line_num != l_idx THEN 
					UPDATE t_invoicedetl 
					SET line_num = l_idx 
					WHERE line_num = l_rec_invoicedetl.line_num 
					LET l_rec_invoicedetl.line_num = l_idx 
				END IF 
		
				LET l_arr_rec_invoicedetl_list[l_idx].line_num = l_rec_invoicedetl.line_num 
				LET l_arr_rec_invoicedetl_list[l_idx].part_code = l_rec_invoicedetl.part_code 
				LET l_arr_rec_invoicedetl_list[l_idx].line_text = l_rec_invoicedetl.line_text 
				LET l_arr_rec_invoicedetl_list[l_idx].ship_qty = l_rec_invoicedetl.ship_qty 
				LET l_arr_rec_invoicedetl_list[l_idx].unit_sale_amt = l_rec_invoicedetl.unit_sale_amt
				 
				#Handle conditional tax for line item/amount 
				IF glob_rec_arparms.show_tax_flag  = "Y" THEN 
					LET l_arr_rec_invoicedetl_list[l_idx].line_total_amt = l_rec_invoicedetl.line_total_amt 
				ELSE 
					LET l_arr_rec_invoicedetl_list[l_idx].line_total_amt =l_rec_invoicedetl.ext_sale_amt 
				END IF
			 
		END CASE
		
	END FOREACH 
	
	CLOSE c_del_invoicedetl
		
	RETURN l_arr_rec_invoicedetl_list
END FUNCTION	
############################################################################
# END FUNCTION db_st_invoicedetl_delete_line(p_line_num)
############################################################################


############################################################################
# FUNCTION insert_line(p_rec_invoicedetl.*)
#
# This FUNCTION inserts a line in the t_invoicedetl with the appropriate
# defaults.
# INSERT INTO t_invoicedetl VALUES (p_rec_invoicedetl.*)
# RETURN p_rec_invoicedetl.* 
############################################################################
FUNCTION insert_line(p_rec_invoicedetl) 
	DEFINE p_rec_invoicedetl RECORD LIKE invoicedetl.* 

	IF get_debug() THEN					
		DISPLAY "..............................."
		DISPLAY "FUNCTION insert_line(", trim(p_rec_invoicedetl), ")" 
	END IF
						
	SELECT max(line_num) INTO p_rec_invoicedetl.line_num #get the last (highest) line number
	FROM t_invoicedetl 

	IF get_debug() THEN					
		DISPLAY "MAX Line=", trim(p_rec_invoicedetl.line_num) 
	END IF

	IF p_rec_invoicedetl.line_num IS NULL THEN 
		LET p_rec_invoicedetl.line_num = 1 
	ELSE 
		LET p_rec_invoicedetl.line_num = p_rec_invoicedetl.line_num + 1 
	END IF 

	IF get_debug() THEN					
		DISPLAY "p_rec_invoicedetl.line_num=", trim(p_rec_invoicedetl.line_num) 
	END IF
	LET p_rec_invoicedetl.ware_code = glob_rec_warehouse.ware_code  #already done..  
	LET p_rec_invoicedetl.part_code = NULL #huho ??? 3.4.2020 
	LET p_rec_invoicedetl.ord_qty = 0 
	LET p_rec_invoicedetl.ship_qty = 0 
	LET p_rec_invoicedetl.prev_qty = 0 
	LET p_rec_invoicedetl.back_qty = 0 
	LET p_rec_invoicedetl.ser_qty = 0 
	LET p_rec_invoicedetl.unit_cost_amt = 0 
	LET p_rec_invoicedetl.ext_cost_amt = 0 
	LET p_rec_invoicedetl.disc_amt = 0 
	LET p_rec_invoicedetl.unit_sale_amt = 0 
	LET p_rec_invoicedetl.ext_sale_amt = 0 
	LET p_rec_invoicedetl.unit_tax_amt = 0 
	LET p_rec_invoicedetl.ext_tax_amt = 0 
	LET p_rec_invoicedetl.line_total_amt = 0 
	LET p_rec_invoicedetl.seq_num = 0 
	LET p_rec_invoicedetl.level_code = glob_rec_customer.inv_level_ind 
	LET p_rec_invoicedetl.comm_amt = 0 
	LET p_rec_invoicedetl.comp_per = 0 
	LET p_rec_invoicedetl.tax_code = glob_rec_customer.tax_code 
	LET p_rec_invoicedetl.order_line_num = NULL 
	LET p_rec_invoicedetl.order_num = NULL 
	LET p_rec_invoicedetl.disc_per = 0 
	LET p_rec_invoicedetl.sold_qty = 0 
	LET p_rec_invoicedetl.bonus_qty = 0 
	LET p_rec_invoicedetl.ext_bonus_amt = 0 
	LET p_rec_invoicedetl.ext_stats_amt = 0 
	LET p_rec_invoicedetl.list_price_amt = 0 
	LET p_rec_invoicedetl.return_qty = 0 
	LET p_rec_invoicedetl.km_qty = 0 
	
	INSERT INTO t_invoicedetl VALUES (p_rec_invoicedetl.*)

	IF get_debug() THEN					
		DISPLAY "INSERT INTO t_invoicedetl VALUES (", p_rec_invoicedetl.*, ")" 
		DISPLAY "..............................."
	END IF
	 
	RETURN p_rec_invoicedetl.* 
END FUNCTION 
############################################################################
# END FUNCTION insert_line(p_rec_invoicedetl.*)
############################################################################


############################################################################
# FUNCTION invoicedetl_update_line(p_rec_invoicedetl)
#
#
# This FUNCTION updates an invoice line item to the TEMP table.
#
############################################################################
FUNCTION invoicedetl_update_line(p_rec_invoicedetl) 
	DEFINE p_rec_invoicedetl RECORD LIKE invoicedetl.* 
	DEFINE l_round_err DECIMAL(16,2) 
	DEFINE l_tax_amt DECIMAL(16,2) 
	DEFINE l_tax_amt2 DECIMAL(16,2) 

	DEFINE l_rec_tax RECORD LIKE tax.* 
	DEFINE l_rec_tax2 RECORD LIKE tax.* 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.* 
	DEFINE l_float FLOAT 
	DEFINE l_taxable_amt LIKE prodstatus.sale_tax_amt 
	DEFINE l_idx SMALLINT 
	DEFINE l_msg STRING
	
	IF get_debug() THEN	
		LET l_msg = "START FUNCTION invoicedetl_update_line(p_rec_invoicedetl)"
		CALL debug_show_invoicedetl(l_msg,p_rec_invoicedetl.*)
	END IF

	#None-Warehouse item/part
	IF p_rec_invoicedetl.part_code IS NULL THEN #Empty part code / NO Warehouse used 
		LET p_rec_invoicedetl.disc_per = 0 
		LET p_rec_invoicedetl.list_price_amt = p_rec_invoicedetl.unit_sale_amt 
		LET p_rec_invoicedetl.ser_flag = "N" 
	ELSE 
	#Warehouse item/part
		CALL db_product_get_rec(UI_OFF,p_rec_invoicedetl.part_code) RETURNING l_rec_product.*  #AGAIN ? do we really need to do this twice ? 
		#Add product data to invoice detail/line record		 
		LET p_rec_invoicedetl.cat_code = l_rec_product.cat_code 
		LET p_rec_invoicedetl.ser_flag = l_rec_product.serial_flag 
		IF p_rec_invoicedetl.line_text IS NULL THEN 
			LET p_rec_invoicedetl.line_text = l_rec_product.desc_text 
		END IF 
		LET p_rec_invoicedetl.uom_code = l_rec_product.sell_uom_code 
		LET p_rec_invoicedetl.prodgrp_code = l_rec_product.prodgrp_code 
		LET p_rec_invoicedetl.maingrp_code = l_rec_product.maingrp_code 

		#Add sales GL-Account
		#We have already done this in the validate and update temp line function... I comment it for now
		--LET p_rec_invoicedetl.line_acct_code = db_category_get_sale_acct_code(UI_OFF,p_rec_invoicedetl.cat_code)
		
		#Warehouse product 
		CALL db_prodstatus_get_rec(UI_OFF,p_rec_invoicedetl.ware_code,p_rec_invoicedetl.part_code)
		RETURNING l_rec_prodstatus.*  
		 
		LET p_rec_invoicedetl.unit_cost_amt = l_rec_prodstatus.wgted_cost_amt	* glob_rec_invoicehead.conv_qty 
		LET p_rec_invoicedetl.list_price_amt = l_rec_prodstatus.list_amt * glob_rec_invoicehead.conv_qty 
		IF p_rec_invoicedetl.list_price_amt = 0 THEN 
			LET p_rec_invoicedetl.list_price_amt=p_rec_invoicedetl.unit_sale_amt 
			LET p_rec_invoicedetl.disc_per = 0 
		END IF 

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
		IF p_rec_invoicedetl.tax_code IS NULL THEN #Ali request - warehouse tax code can be overwritten by user 
			LET p_rec_invoicedetl.tax_code = l_rec_prodstatus.sale_tax_code
		END IF 
	END IF
	#Why is this also called for entering none warehouse items line_text ? 
	#PS:Calculate Tax #There is an invoice tax code AND a product tax code...

	#This is madness... I break warehouse and none-warehouse invoice line tax calculation up (2 seperate calls)

	# ----------------------------
	#TAX calculation
	# ----------------------------
	#None-Warehouse free item/part
	IF p_rec_invoicedetl.ware_code IS NULL THEN #free / none-warehouse product part
		CALL calc_line_tax(
		glob_rec_kandoouser.cmpy_code,
		glob_rec_invoicehead.tax_code, 
		p_rec_invoicedetl.tax_code,  # tax code was MAY BE entered directly by the user
		p_rec_invoicedetl.unit_tax_amt, #tax amount was MAY BE entered directly by the user
		p_rec_invoicedetl.sold_qty, 
		p_rec_invoicedetl.unit_cost_amt, 
		p_rec_invoicedetl.unit_sale_amt) 
		RETURNING p_rec_invoicedetl.unit_tax_amt, p_rec_invoicedetl.ext_tax_amt
		
	#Warehouse Product Item Tax calc
	ELSE 	
		CALL calc_line_tax(
		glob_rec_kandoouser.cmpy_code,
		glob_rec_invoicehead.tax_code, 
		p_rec_invoicedetl.tax_code,  #Can this be NULL or used for warehouse products ? 
		l_rec_prodstatus.sale_tax_amt, 
		p_rec_invoicedetl.sold_qty, 
		p_rec_invoicedetl.unit_cost_amt, 
		p_rec_invoicedetl.unit_sale_amt) 
		RETURNING p_rec_invoicedetl.unit_tax_amt, p_rec_invoicedetl.ext_tax_amt
	END IF
	
	IF get_debug() THEN		
		DISPLAY "p_rec_invoicedetl.unit_tax_amt=", p_rec_invoicedetl.unit_tax_amt
		DISPLAY "p_rec_invoicedetl.ext_tax_amt=", p_rec_invoicedetl.ext_tax_amt
	END IF	 
	LET p_rec_invoicedetl.ext_sale_amt = p_rec_invoicedetl.unit_sale_amt * p_rec_invoicedetl.ship_qty 
	LET p_rec_invoicedetl.ext_tax_amt = p_rec_invoicedetl.unit_tax_amt * p_rec_invoicedetl.ship_qty 
	LET l_round_err = 0 

	INITIALIZE l_rec_tax.* TO NULL 
	LET l_taxable_amt = 0 
	LET l_tax_amt = 0 
	LET l_tax_amt2 = 0 
	CALL db_tax_get_rec(UI_OFF,glob_rec_invoicehead.tax_code) RETURNING l_rec_tax.* #NOT sure if this is still valid use p_rec_invoicedetl.tax_code OR glob_rec_invoicehead.tax_code
	--SELECT * INTO l_rec_tax.* FROM tax 
	--WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	--AND tax_code = glob_rec_invoicehead.tax_code 

	IF l_rec_tax.calc_method_flag = "T" THEN #Method “T” The amount of sales tax is a flat percentage of the Transaction Total (ie. invoice or voucher) based on the Customer’s (or Vendor’s) tax rate.
		INITIALIZE l_rec_tax2.* TO NULL 
		CALL db_tax_get_rec(UI_OFF,p_rec_invoicedetl.tax_code) RETURNING l_rec_tax2.*	
		--SELECT * INTO l_rec_tax2.* FROM tax WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		--AND tax_code = p_rec_invoicedetl.tax_code 
		IF l_rec_tax2.calc_method_flag != "X" THEN #Method “X” This is used to identify customers, vendors, or products whose prices are Exclusive of tax.  Tax is not added (but may in some circumstances be deducted).
			SELECT sum(ext_sale_amt) INTO l_taxable_amt 
			FROM t_invoicedetl,tax 
			WHERE line_num != p_rec_invoicedetl.line_num 
			AND t_invoicedetl.tax_code = tax.tax_code 
			AND calc_method_flag != "X" 
			AND tax.cmpy_code = glob_rec_kandoouser.cmpy_code 
	
			LET l_taxable_amt = l_taxable_amt + p_rec_invoicedetl.ext_sale_amt 

			CALL calc_total_tax(glob_rec_kandoouser.cmpy_code, "T",	l_taxable_amt, l_rec_tax.tax_code) 
			RETURNING l_tax_amt 

			SELECT sum(ext_tax_amt) INTO l_tax_amt2 FROM t_invoicedetl 
			WHERE line_num != p_rec_invoicedetl.line_num 

			LET l_tax_amt2 = l_tax_amt2	+ p_rec_invoicedetl.ext_tax_amt 

			IF l_tax_amt != l_tax_amt2 THEN 
				LET l_round_err = l_tax_amt2 - l_tax_amt 
			END IF 
			IF l_round_err != 0 THEN 
				LET p_rec_invoicedetl.ext_tax_amt = p_rec_invoicedetl.ext_tax_amt - l_round_err 
			END IF 
		END IF 
	END IF 

	IF p_rec_invoicedetl.ext_tax_amt IS NULL THEN 
		LET p_rec_invoicedetl.ext_tax_amt = 0 
	END IF 
	
	#UPDATE invoice line to temp table
	UPDATE t_invoicedetl 
	SET line_num = p_rec_invoicedetl.line_num, 
	part_code = p_rec_invoicedetl.part_code, 
	ware_code = p_rec_invoicedetl.ware_code, 
	cat_code = p_rec_invoicedetl.cat_code, 
	prodgrp_code = p_rec_invoicedetl.prodgrp_code, 
	maingrp_code = p_rec_invoicedetl.maingrp_code, 
	uom_code = p_rec_invoicedetl.uom_code, 
	unit_sale_amt = p_rec_invoicedetl.unit_sale_amt, 
	back_qty = p_rec_invoicedetl.back_qty, 
	tax_code = p_rec_invoicedetl.tax_code, 
	level_code = p_rec_invoicedetl.level_code, 
	unit_tax_amt = p_rec_invoicedetl.unit_tax_amt, 
	ext_tax_amt = p_rec_invoicedetl.ext_tax_amt, 
	unit_cost_amt = p_rec_invoicedetl.unit_cost_amt, 
	ship_qty = p_rec_invoicedetl.ship_qty, 
	line_text = p_rec_invoicedetl.line_text, 
	ext_cost_amt = p_rec_invoicedetl.unit_cost_amt* p_rec_invoicedetl.ship_qty, 
	ext_sale_amt = p_rec_invoicedetl.ext_sale_amt, 
	line_total_amt = p_rec_invoicedetl.ship_qty * (p_rec_invoicedetl.unit_tax_amt + p_rec_invoicedetl.unit_sale_amt), 
	ext_stats_amt = 0, 
	line_acct_code = p_rec_invoicedetl.line_acct_code, 
	list_price_amt = p_rec_invoicedetl.list_price_amt 
	WHERE line_num = p_rec_invoicedetl.line_num 
	
	RETURN p_rec_invoicedetl.*  #Return full record data 
END FUNCTION 
############################################################################
# END FUNCTION invoicedetl_update_line(p_rec_invoicedetl)
############################################################################


############################################################################
# FUNCTION disp_total(p_rec_invoicedetl)
#
#
############################################################################
FUNCTION disp_total(p_rec_invoicedetl) 
	DEFINE p_rec_invoicedetl RECORD LIKE invoicedetl.* 
	DEFINE l_desc_text NVARCHAR(30)
	# tax_group_code,tax_group_ext_sale_amt,tax_group_ext_tax_amt
	DEFINE l_rec_tax_group_amt RECORD
		tax_group_code LIKE invoicedetl.tax_code,
		tax_group_ext_tax_amt LIKE invoicedetl.ext_tax_amt,
		tax_group_ext_sale_amt LIKE invoicedetl.ext_sale_amt,
		tax_group_line_total_amt LIKE invoicedetl.line_total_amt				
	END RECORD
	DEFINE l_arr_rec_tax_group_amt DYNAMIC ARRAY OF RECORD #For tax group tax and net amounts display
		tax_group_code LIKE invoicedetl.tax_code,
		tax_group_ext_tax_amt LIKE invoicedetl.ext_tax_amt,
		tax_group_ext_sale_amt LIKE invoicedetl.ext_sale_amt,
		tax_group_line_total_amt LIKE invoicedetl.line_total_amt		
	END RECORD	
	# GL-Account group_code,tax_group_ext_sale_amt,tax_group_ext_tax_amt
	DEFINE l_rec_gl_group_amt RECORD 
		gl_group_line_acct_code LIKE invoicedetl.line_acct_code,
		gl_group_ext_tax_amt LIKE invoicedetl.ext_tax_amt,
		gl_group_ext_sale_amt LIKE invoicedetl.unit_tax_amt,
		gl_group_line_total_amt LIKE invoicedetl.line_total_amt				
	END RECORD
	DEFINE l_arr_rec_gl_group_amt DYNAMIC ARRAY OF RECORD #For tax group tax and net amounts display
		gl_group_line_acct_code LIKE invoicedetl.line_acct_code,
		gl_group_ext_tax_amt LIKE invoicedetl.ext_tax_amt,
		gl_group_ext_sale_amt LIKE invoicedetl.unit_tax_amt,
		gl_group_line_total_amt LIKE invoicedetl.line_total_amt				
	END RECORD	
	
	DEFINE l_idx SMALLINT

	### DISPLAY Current Line Info
	#LET scrn = scr_line()
	IF glob_rec_arparms.show_tax_flag = "N" THEN 
		LET p_rec_invoicedetl.line_total_amt = p_rec_invoicedetl.ext_sale_amt 
	ELSE 
		LET p_rec_invoicedetl.line_total_amt = p_rec_invoicedetl.line_total_amt 
	END IF 

	SELECT 
		sum(ext_sale_amt), 
		sum(ext_tax_amt), 
		sum(ext_cost_amt) 
	INTO 
		glob_rec_invoicehead.goods_amt, 
		glob_rec_invoicehead.tax_amt, 
		glob_rec_invoicehead.cost_amt 
	FROM t_invoicedetl 

	IF glob_rec_invoicehead.goods_amt IS NULL THEN 
		LET glob_rec_invoicehead.goods_amt = 0 
	END IF 

	IF glob_rec_invoicehead.tax_amt IS NULL THEN 
		LET glob_rec_invoicehead.tax_amt = 0 
	END IF 

	LET glob_rec_invoicehead.total_amt = glob_rec_invoicehead.goods_amt + glob_rec_invoicehead.tax_amt 

	LET glob_rec_customer.cred_bal_amt = glob_rec_customer.cred_limit_amt 
	- glob_rec_customer.bal_amt 
	- glob_rec_customer.onorder_amt 
	- glob_rec_invoicehead.total_amt 
	+ glob_curr_inv_amt 

	DISPLAY glob_rec_invoicehead.goods_amt TO invoicehead.goods_amt ATTRIBUTE(YELLOW)  
	DISPLAY glob_rec_invoicehead.tax_amt TO invoicehead.tax_amt ATTRIBUTE(YELLOW)
	DISPLAY glob_rec_invoicehead.total_amt TO invoicehead.total_amt ATTRIBUTE(YELLOW)
	
	DISPLAY glob_rec_customer.cred_bal_amt TO customer.cred_bal_amt
	
	#START - DISPLAY TAX GROUP CODE,AMT,NET ---------------------
	DECLARE tax_group_curs CURSOR with HOLD FOR 
	select tax_code, sum(ext_tax_amt), sum(ext_sale_amt), sum(line_total_amt)
	INTO l_rec_tax_group_amt.*
	from t_invoicedetl
	#where inv_num = xxx
	group by 1
	LET l_idx = 0
	FOREACH tax_group_curs
		LET l_idx = l_idx + 1 
		LET l_arr_rec_tax_group_amt[l_idx].* = l_rec_tax_group_amt.*
	END FOREACH	

	DISPLAY ARRAY l_arr_rec_tax_group_amt TO sr_tax_by_group.* WITHOUT SCROLL
	#END DISPLAY TAX GROUP CODE,AMT,NET ---------------------

	#START - DISPLAY GL GROUP CODE,AMT,NET ---------------------
	DECLARE gl_group_curs CURSOR with HOLD FOR 
	select line_acct_code, sum(ext_tax_amt), sum(ext_sale_amt), sum(line_total_amt)
	INTO l_rec_gl_group_amt.*
	from t_invoicedetl
	#where inv_num = xxx
	group by 1
	LET l_idx = 0
	FOREACH gl_group_curs
		LET l_idx = l_idx + 1 
		LET l_arr_rec_gl_group_amt[l_idx].* = l_rec_gl_group_amt.*
	END FOREACH	

	DISPLAY ARRAY l_arr_rec_gl_group_amt TO sr_gl_by_group.* WITHOUT SCROLL
	#END DISPLAY GL GROUP CODE,AMT,NET ---------------------
	
	#should no longer be required
	#DISPLAY p_rec_invoicedetl.tax_code TO invoicehead.tax_code
	#DISPLAY glob_rec_warehouse.ware_code TO warehouse.ware_code

	#IF p_rec_invoicedetl.tax_code IS NULL THEN 
	#	--CLEAR tax.desc_text #should no longer be required 
	#ELSE 
	#	CALL db_tax_get_desc_text(UI_OFF,p_rec_invoicedetl.tax_code) RETURNING l_desc_text
	#	DISPLAY l_desc_text TO tax.desc_text 
	#END IF 
	
END FUNCTION
############################################################################
# END FUNCTION disp_total(p_rec_invoicedetl)
############################################################################