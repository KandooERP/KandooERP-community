##############################################################################################
#TABLE tax
##############################################################################################

##########################################################
# GLOBAL Scope Variables
##########################################################
GLOBALS "../common/glob_GLOBALS.4gl"

############################################################
# FUNCTION db_tax_get_count()
#
# Return total number of rows in tax FROM current company
############################################################
FUNCTION db_tax_get_count()
	DEFINE ret INT

	SELECT count(*) 
	INTO ret 
	FROM tax 
	WHERE tax.cmpy_code = glob_rec_kandoouser.cmpy_code		

	RETURN ret
END FUNCTION
############################################################
# END FUNCTION db_tax_get_count()
############################################################


############################################################
# FUNCTION db_tax_pk_exists(p_tax_code)
#
# Validate PK - Unique
############################################################
FUNCTION db_tax_pk_exists(p_tax_code)
	DEFINE p_tax_code LIKE tax.tax_code
	DEFINE ret INT

	IF p_tax_code IS NULL THEN
		RETURN -1
	END IF
			
	SELECT count(*) 
	INTO ret 
	FROM tax 
	WHERE tax.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND tax.tax_code = p_tax_code		
	
	RETURN ret
END FUNCTION
############################################################
# END FUNCTION db_tax_pk_exists(p_tax_code)
############################################################


############################################################
# FUNCTION db_tax_get_rec(p_ui_mode,p_tax_code)
#
# Return tax record matching PK tax_code
############################################################
FUNCTION db_tax_get_rec(p_ui_mode,p_tax_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_tax_code LIKE tax.tax_code
	DEFINE l_ret_rec_tax RECORD LIKE tax.*
	DEFINE l_msg STRING
	IF p_tax_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Tax Code can NOT be empty"
		END IF
		RETURN NULL
	END IF

		SELECT * 
		INTO l_ret_rec_tax 
		FROM tax 
		WHERE tax.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND tax.tax_code = p_tax_code  		
	
	IF sqlca.sqlcode != 0 THEN
		INITIALIZE l_ret_rec_tax.* TO NULL
		IF p_ui_mode != UI_OFF THEN
			LET l_msg =	 "Tax Record with Code ",trim(p_tax_code),  "NOT found"
			ERROR l_msg
			#ERROR kandoomsg2("P",9106,"")		#P9106 " Tax Code NOT found, try window"
		END IF		
	END IF
	
	RETURN l_ret_rec_tax.*		
END FUNCTION	
############################################################
# END FUNCTION db_tax_get_rec(p_ui_mode,p_tax_code)
############################################################


############################################################
# FUNCTION db_tax_get_desc_text(p_tax_code)
# RETURN l_ret_desc_text
#
# Get desc_text FROM tax record
############################################################
FUNCTION db_tax_get_desc_text(p_ui_mode,p_tax_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_tax_code LIKE tax.tax_code
	DEFINE l_ret_desc_text LIKE tax.desc_text

	IF p_tax_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Tax Code can NOT be empty"
		END IF
		RETURN NULL
	END IF
		
	SELECT desc_text 
	INTO l_ret_desc_text 
	FROM tax 
	WHERE tax.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND tax.tax_code = p_tax_code  		

	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Tax Description with Code ",trim(p_tax_code),  "NOT found"
		END IF
		RETURN NULL
	ELSE
		RETURN l_ret_desc_text	                                                                                                
	END IF	
END FUNCTION
############################################################
# END FUNCTION db_tax_get_desc_text(p_tax_code)
############################################################


############################################################
# FUNCTION db_tax_get_calc_method_flag(p_tax_code)
# RETURN l_ret_calc_method_flag
#
# Get calc_method_flag FROM tax record
############################################################
FUNCTION db_tax_get_calc_method_flag(p_ui_mode,p_tax_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_tax_code LIKE tax.tax_code
	DEFINE l_ret_calc_method_flag LIKE tax.calc_method_flag

	IF p_tax_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Tax Code can NOT be empty"
		END IF
		RETURN NULL
	END IF
		
	SELECT calc_method_flag 
	INTO l_ret_calc_method_flag 
	FROM tax 
	WHERE tax.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND tax.tax_code = p_tax_code  		

	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Tax Description with Code ",trim(p_tax_code),  "NOT found"
		END IF
		RETURN NULL
	ELSE
		RETURN l_ret_calc_method_flag	                                                                                                
	END IF	
END FUNCTION
############################################################
# END FUNCTION db_tax_get_calc_method_flag(p_tax_code)
############################################################


############################################################
# FUNCTION db_tax_get_tax_per(p_tax_code)
# RETURN l_ret_tax_per
#
# Get tax_per FROM tax record
############################################################
FUNCTION db_tax_get_tax_per(p_ui_mode,p_tax_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_tax_code LIKE tax.tax_code
	DEFINE l_ret_tax_per LIKE tax.tax_per

	IF p_tax_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Tax Code can NOT be empty"
		END IF
		RETURN NULL
	END IF
		
	SELECT tax_per 
	INTO l_ret_tax_per 
	FROM tax 
	WHERE tax.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND tax.tax_code = p_tax_code  		

	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Tax Description with Code ",trim(p_tax_code),  "NOT found"
		END IF
		RETURN NULL
	ELSE
		RETURN l_ret_tax_per	                                                                                                
	END IF	
END FUNCTION
############################################################
# END FUNCTION db_tax_get_tax_per(p_tax_code)
############################################################


############################################################
# FUNCTION db_tax_get_freight_per(p_tax_code)
# RETURN l_ret_freight_per
#
# Get freight_per FROM tax record
############################################################
FUNCTION db_tax_get_freight_per(p_ui_mode,p_tax_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_tax_code LIKE tax.tax_code
	DEFINE l_ret_freight_per LIKE tax.freight_per

	IF p_tax_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Tax Code can NOT be empty"
		END IF
		RETURN NULL
	END IF
		
	SELECT freight_per 
	INTO l_ret_freight_per 
	FROM tax 
	WHERE tax.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND tax.tax_code = p_tax_code  		

	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Tax Description with Code ",trim(p_tax_code),  "NOT found"
		END IF
		RETURN NULL
	ELSE
		RETURN l_ret_freight_per	                                                                                                
	END IF	
END FUNCTION	
############################################################
# END FUNCTION db_tax_get_freight_per(p_tax_code)
############################################################


############################################################
# FUNCTION db_tax_get_hand_per(p_tax_code)
# RETURN l_ret_hand_per
#
# Get hand_per FROM tax record
############################################################
FUNCTION db_tax_get_hand_per(p_ui_mode,p_tax_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_tax_code LIKE tax.tax_code
	DEFINE l_ret_hand_per LIKE tax.hand_per

	IF p_tax_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Tax Code can NOT be empty"
		END IF
		RETURN NULL
	END IF
		
	SELECT hand_per 
	INTO l_ret_hand_per 
	FROM tax 
	WHERE tax.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND tax.tax_code = p_tax_code  		

	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Tax Description with Code ",trim(p_tax_code),  "NOT found"
		END IF
		RETURN NULL
	ELSE
		RETURN l_ret_hand_per	                                                                                                
	END IF	
END FUNCTION	
############################################################
# FUNCTION db_tax_get_hand_per(p_tax_code)
############################################################


############################################################
# FUNCTION db_tax_get_uplift_per(p_tax_code)
# RETURN l_ret_uplift_per
#
# Get uplift_per FROM tax record
############################################################
FUNCTION db_tax_get_uplift_per(p_ui_mode,p_tax_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_tax_code LIKE tax.tax_code
	DEFINE l_ret_uplift_per LIKE tax.uplift_per

	IF p_tax_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Tax Code can NOT be empty"
		END IF
		RETURN NULL
	END IF
		
	SELECT uplift_per 
	INTO l_ret_uplift_per 
	FROM tax 
	WHERE tax.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND tax.tax_code = p_tax_code  		

	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Tax Description with Code ",trim(p_tax_code),  "NOT found"
		END IF
		RETURN NULL
	ELSE
		RETURN l_ret_uplift_per	                                                                                                
	END IF	
END FUNCTION				
############################################################
# END FUNCTION db_tax_get_uplift_per(p_tax_code)
############################################################


############################################################
# FUNCTION db_tax_get_buy_acct_code(p_tax_code)
# RETURN l_ret_buy_acct_code
#
# Get buy_acct_code FROM tax record
############################################################
FUNCTION db_tax_get_buy_acct_code(p_ui_mode,p_tax_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_tax_code LIKE tax.tax_code
	DEFINE l_ret_buy_acct_code LIKE tax.buy_acct_code

	IF p_tax_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Tax Code can NOT be empty"
		END IF
		RETURN NULL
	END IF
		
	SELECT buy_acct_code 
	INTO l_ret_buy_acct_code 
	FROM tax 
	WHERE tax.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND tax.tax_code = p_tax_code  		

	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Tax Description with Code ",trim(p_tax_code),  "NOT found"
		END IF
		RETURN NULL
	ELSE
		RETURN l_ret_buy_acct_code	                                                                                                
	END IF	
END FUNCTION				
############################################################
# FUNCTION db_tax_get_buy_acct_code(p_tax_code)
############################################################


############################################################
# FUNCTION db_tax_get_sell_acct_code(p_tax_code)
# RETURN l_ret_sell_acct_code
#
# Get sell_acct_code FROM tax record
############################################################
FUNCTION db_tax_get_sell_acct_code(p_ui_mode,p_tax_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_tax_code LIKE tax.tax_code
	DEFINE l_ret_sell_acct_code LIKE tax.sell_acct_code

	IF p_tax_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Tax Code can NOT be empty"
		END IF
		RETURN NULL
	END IF
		
	SELECT sell_acct_code 
	INTO l_ret_sell_acct_code 
	FROM tax 
	WHERE tax.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND tax.tax_code = p_tax_code  		

	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Tax Description with Code ",trim(p_tax_code),  "NOT found"
		END IF
		RETURN NULL
	ELSE
		RETURN l_ret_sell_acct_code	                                                                                                
	END IF	
END FUNCTION				
############################################################
# END FUNCTION db_tax_get_sell_acct_code(p_tax_code)
############################################################


########################################################################################################################
#
# ARRAY DATASOURCE
#
########################################################################################################################

############################################################
# FUNCTION db_tax_get_arr_ret(p_where_text)
# RETURN l_arr_rec_tax 
# Return tax rec array
############################################################
FUNCTION db_tax_get_arr_rec(p_where_text)
	DEFINE p_where_text STRING
	DEFINE l_query_text VARCHAR(500)
	DEFINE l_rec_tax RECORD LIKE tax.*
	DEFINE l_arr_rec_tax DYNAMIC ARRAY OF RECORD LIKE tax.*
	DEFINE l_idx SMALLINT --loop control

	LET l_query_text = "SELECT * FROM tax ",
                        "WHERE cmpy_code =\"",glob_rec_kandoouser.cmpy_code,"\" "

	IF p_where_text IS NOT NULL THEN                        
		LET l_query_text =  l_query_text CLIPPED, " AND ", trim(p_where_text), " "
	END IF
			                      
	LET l_query_text =  l_query_text CLIPPED,
			"ORDER BY ",
				"tax_code"
				
	PREPARE s_tax FROM l_query_text
	DECLARE c_tax CURSOR FOR s_tax


   LET l_idx = 0
   FOREACH c_tax INTO l_rec_tax.*
      LET l_idx = l_idx + 1
      LET l_arr_rec_tax[l_idx].* = l_rec_tax.*
   END FOREACH

	FREE c_tax
	
	RETURN l_arr_rec_tax  
END FUNCTION	
############################################################
# END FUNCTION db_tax_get_arr_ret(p_where_text)
############################################################


############################################################
# FUNCTION db_tax_get_arr_rec_short(p_where_text)
# RETURN l_arr_rec_tax 
# Return tax rec array
############################################################
FUNCTION db_tax_get_arr_rec_short(p_where_text)
	DEFINE p_where_text STRING
	DEFINE l_query_text VARCHAR(500)
	DEFINE l_rec_tax RECORD LIKE tax.*
	DEFINE l_arr_rec_tax DYNAMIC ARRAY OF
		RECORD
			tax_code LIKE tax.tax_code,
			desc_text LIKE tax.desc_text
		END RECORD
	DEFINE l_idx SMALLINT --loop control

	LET l_query_text = "SELECT * FROM tax ",
                        "WHERE cmpy_code =\"",glob_rec_kandoouser.cmpy_code,"\" "

	IF p_where_text IS NOT NULL THEN                        
		LET l_query_text =  l_query_text CLIPPED, " AND ", trim(p_where_text), " "
	END IF
			                      
	LET l_query_text =  l_query_text CLIPPED,
			"ORDER BY ",
				"cmpy_code,",
				"tax_code"
				
	PREPARE s_s_tax FROM l_query_text
	DECLARE c_s_tax CURSOR FOR s_s_tax


   LET l_idx = 0
   FOREACH c_tax INTO l_rec_tax.*
      LET l_idx = l_idx + 1
      LET l_arr_rec_tax[l_idx].tax_code = l_rec_tax.tax_code
      LET l_arr_rec_tax[l_idx].desc_text = l_rec_tax.desc_text
   END FOREACH

	FREE c_s_tax

	RETURN l_arr_rec_tax  
END FUNCTION	
############################################################
# END FUNCTION db_tax_get_arr_rec_short(p_where_text)
############################################################


#############################################################
# Miscellaneous
#############################################################

#############################################################
# FUNCTION get_tax_calculation_description(p_calc_method_flag)
#
#############################################################
FUNCTION get_tax_calculation_description(p_calc_method_flag)
	DEFINE p_calc_method_flag LIKE tax.calc_method_flag
	DEFINE l_calc_description STRING
	CASE p_calc_method_flag
		WHEN "P"
			LET l_calc_description = "The amount of sales tax is dictated by the tax Percentage associated with the Product."
			#CALL ui.ComboBox.ForName(p_cb_field_name).addItem("P","Product Sales Tax (P)")

		WHEN "D"
			LET l_calc_description = "The amount of sales tax is dictated by the (Dollar) tax amount associated with the Product."
			#CALL ui.ComboBox.ForName(p_cb_field_name).addItem("D","Dollar Product Sales Tax (D)")

		WHEN "T"
			LET l_calc_description = "The amount of sales tax is a flat percentage of the Transaction Total (ie. invoice or voucher) based on the Customer’s (or Vendor’s) tax rate."
			#CALL ui.ComboBox.ForName(p_cb_field_name).addItem("N","Customers Sales Tax per Line (N)") 

		WHEN "N"
			LET l_calc_description = "The amount of (Net) sales tax is calculated by applying the Customer’s (or Vendor’s) tax rate to each Product line in a transaction, (which may result in a difference compared to the Total tax method due to the rounding of each line amount)."
			#CALL ui.ComboBox.ForName(p_cb_field_name).addItem("T","Customers Sales Tax (T)") 

		WHEN "I"
			LET l_calc_description = "This is used to identify customers, vendors, or products whose prices are Inclusive of tax.  Whether or not tax is calculated depends on its combination with other methods."
			#CALL ui.ComboBox.ForName(p_cb_field_name).addItem("X","Price excluding Tax (X)") 

		WHEN "X"
			LET l_calc_description = "This is used to identify customers, vendors, or products whose prices are Exclusive of tax.  Tax is not added (but may in some circumstances be deducted)."
			#CALL ui.ComboBox.ForName(p_cb_field_name).addItem("I","Price inclusive Tax (I)") 

		WHEN "W"
			LET l_calc_description = "This is used to identify customers, vendors, and products that are subject to tax where the tax is collected at the last wholesale transaction.  Wholesale tax is calculated at the point of goods receipt entry (for vendors and stocked items with tax type “W”) and posted to a tax payable account.  The tax is then recalculated when posting the Cost of Goods sold for invoices and credits, (for customers and stocked items with tax type “W”), and posted to a tax claimable account.  The amount of tax is calculated from the percentage associated with the tax code stored on the product status record."
			#CALL ui.ComboBox.ForName(p_cb_field_name).addItem("W","Wholesale Tax (W)") 

		WHEN "A" #fictional value to show ALL information with Produt AND Customer calc method
			LET l_calc_description = 
			"AR: Information on how tax is calculated on Accounts Receivable transactions\n",
			"\n",
			"Customer method: P\n",
			"Product method: P\n",
			"Tax RATE associated with the Tax Code of the PRODUCT is used to compute tax (as a percentage of item price) which is then added to the price to arrive at the extended line price.\n",
			"\n",
			"Customer method: P\n",
			"Product method: D\n",
			"Tax AMOUNT set up for PRODUCT is added to the price to arrive at the extended line price.\n",
			"\n",
			"Customer method: P\n",
			"Product method: I, X or not defined\n",
			"No tax is added, as price already either includes or excludes tax calculated by the appropriate method.  Non-product lines therefore attract zero tax since they do not have a tax code (any applicable tax should therefore be added manually, usually as a separate line item).\n",
			"\n",
			"Customer method: I\n",
			"Product method: Various\n",
			"Treated same as Customer method “P” above.\n",
			"\n",
			"Customer method: D\n",
			"Product method: Any\n",
			"Tax AMOUNT set up for PRODUCT is added to the item price to arrive at extended line price.  If tax code is not valid then a tax amount of zero is assumed.  This method assumes that the appropriate tax amount has been set up for EVERY product.  No tax is added to non-product lines (so as to allow manual entry of tax as a separate line item).\n",
			"\n",
			"Customer method: N\n",
			"Product method: Any except for I or X\n",
			"Tax RATE associated with the Tax Code of the CUSTOMER is used to compute tax (as a percentage of item price) which is then added to the item price to arrive at extended line price.  This includes both product and non-product lines.\n",
			"\n",
			"Customer method: N\n",
			"Product method: I or X\n",
			"No (additional) tax is added to this product line.\n",
			"\n",
			"Customer method: T\n",
			"Product method: Any except for X\n",
			"Tax RATE associated with the Tax Code of the CUSTOMER is used to compute tax (as a percentage of total price of all transaction lines, except those for products with a method of “X”) which is then added to the total price to arrive at extended total price.\n",
			"\n",
			"Customer method: T\n",
			"Product method: X\n",
			"The price of these products is excluded from the total on which tax is calculated.\n",
			"Currently Total_Tax_Flag != “Y” is used for this purpose.\n",
			"\n",
			"Customer method: X\n",
			"Product method: I\n",
			"Tax is deducted from both cost and price.  If the Product tax amount is non-zero then this is used, otherwise the reciprocal of the rate associated with the Tax Code of the PRODUCT is used to calculate the tax based on the COST.\n",
			"\n",
			"Customer method: X\n",
			"Product method: Any except for I\n",
			"No tax is added (or deducted).\n",
			"\n",
			"Customer method: W\n",
			"The tax is calculated when posting the Cost of Goods sold for invoices and credits, (for customers and stocked items), and posted to a tax claimable account.  The amount of tax is calculated from the percentage associated with the tax code stored on the product status record.\n"	
	
	END CASE
	
	RETURN l_calc_description
END FUNCTION
#############################################################
# END FUNCTION get_tax_calculation_description(p_calc_method_flag)
#############################################################