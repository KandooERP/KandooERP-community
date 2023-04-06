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

###########################################################################
# FUNCTION db_tax_filter_datasource(p_filter)
#
#
###########################################################################
FUNCTION db_tax_filter_datasource(p_filter) 
	DEFINE p_filter BOOLEAN 
	DEFINE l_rec_tax RECORD LIKE tax.* 
	DEFINE l_arr_rec_tax DYNAMIC ARRAY OF t_rec_tax_tc_dt_cm_tp 
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_idx SMALLINT 

	IF p_filter THEN 
		CLEAR FORM 
		MESSAGE kandoomsg2("U",1001,"") 		#1001 " Enter Selection Criteria - ESC TO Continue"

		CONSTRUCT BY NAME l_where_text ON 
			tax_code, 
			desc_text, 
			calc_method_flag, 
			tax_per 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","taxwind","construct-tax") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = FALSE 
			LET quit_flag = FALSE 
			LET l_rec_tax.tax_code = NULL 
			LET l_where_text = " 1=1 " 
		END IF 

	ELSE 
		LET l_where_text = " 1=1 " 
	END IF 

	MESSAGE kandoomsg2("U",1002,"")	#1002 Searching database; Please wait.
	LET l_query_text = "SELECT * FROM tax ", 
	"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND ",l_where_text CLIPPED," ", 
	"ORDER BY tax_code" 

	OPTIONS SQL interrupt ON 
	PREPARE s_tax1 FROM l_query_text 
	DECLARE c_tax1 CURSOR FOR s_tax1 

	LET l_idx = 0 
	FOREACH c_tax1 INTO l_rec_tax.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_tax[l_idx].tax_code = l_rec_tax.tax_code 
		LET l_arr_rec_tax[l_idx].desc_text = l_rec_tax.desc_text 
		LET l_arr_rec_tax[l_idx].calc_method_flag = l_rec_tax.calc_method_flag 
		LET l_arr_rec_tax[l_idx].tax_per = l_rec_tax.tax_per
		
		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF			 
	END FOREACH 

	MESSAGE kandoomsg2("U",9113,l_arr_rec_tax.getLength()) #9113 l_idx records selected

	RETURN l_arr_rec_tax 
END FUNCTION 
###########################################################################
# END FUNCTION db_tax_filter_datasource(p_filter)
###########################################################################


###########################################################################
# FUNCTION show_tax(p_cmpy_code)
#
#
###########################################################################
FUNCTION show_tax(p_cmpy_code) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE l_rec_tax RECORD LIKE tax.* 
	DEFINE l_arr_rec_tax DYNAMIC ARRAY OF t_rec_tax_tc_dt_cm_tp 
	#	array[100] OF
	#		RECORD
	#			tax_code           LIKE tax.tax_code,
	#			desc_text          LIKE tax.desc_text,
	#			calc_method_flag   LIKE tax.calc_method_flag,
	#			tax_per            LIKE tax.tax_per
	#		END RECORD
	DEFINE l_idx SMALLINT 

	OPEN WINDOW G559 with FORM "G559" 
	CALL winDecoration_g("G559") 

	IF db_tax_get_count() > 1000 THEN 
		CALL db_tax_filter_datasource(TRUE) RETURNING l_arr_rec_tax 
	ELSE 
		CALL db_tax_filter_datasource(FALSE) RETURNING l_arr_rec_tax 
	END IF 

	#	WHILE TRUE
	IF l_arr_rec_tax.getlength() = 0 THEN 
		LET l_idx = 1 
		INITIALIZE l_arr_rec_tax[1].* TO NULL 
	END IF 

	MESSAGE kandoomsg2("U",1006,"")	#1006 " ESC on line TO SELECT - F10 TO Add"

	#INPUT ARRAY l_arr_rec_tax WITHOUT DEFAULTS FROM sr_tax.* ATTRIBUTE(UNBUFFERED)
	DISPLAY ARRAY l_arr_rec_tax TO sr_tax_no_scroll_flag.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","taxwind","input-arr-tax") 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			LET l_rec_tax.tax_code = l_arr_rec_tax[l_idx].tax_code 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "FILTER" 
			CALL db_tax_filter_datasource(TRUE) RETURNING l_arr_rec_tax 

		ON KEY (F10) --tax code setup 
			CALL run_prog("GT1","","","","") 
			CALL db_tax_filter_datasource(FALSE) RETURNING l_arr_rec_tax 


	END DISPLAY 
	#------------------------------


	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
	END IF 

	CLOSE WINDOW G559 
	CALL comboList_tax_code("tax_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

	RETURN l_rec_tax.tax_code 
END FUNCTION 
###########################################################################
# FUNCTION show_tax(p_cmpy_code)
###########################################################################


###############################################################
# FUNCTION calc_line_tax(p_cmpy_code,p_cust_tax_code,
#
#  This FUNCTION calculates the total amount of tax FOR a sale line.
#
#  Arguments passed are:
#
#    p_cust_tax_code = tax code FROM customer, (OR entered by user)
#    p_prod_tax_code = tax code selected FROM prodstatus (warehouse)
#    p_prod_tax_amt  = tax amt selected FROM prodstatus
#    p_unit_qty      = quantity of line being sold (ie: excl bonus)
#                       This IS included FOR future enhancements TO do
#                       with line total rounding. Not currently used.
#    p_unit_cost_amt = weighted average cost selected FROM prodstatus
#    p_unit_price_amt= selling price (AFTER any discount) of line item.
#
# Note that all prodstatus VALUES are passed AND NOT selected. This IS
# TO reduce extra SELECT as most program would have already selected it
#
# Values returned TO calling program are:
#
#    pr_unit_tax_amt = Unit amount of tax payable on line item
#    pr_ext_tax_amt  = Extended amount of tax payable on line item
#
# Depending on the laws of your country, sales tax may or may not be associated with customers, vendors and/or products.  KandooERP has been designed to provide flexibility in tax matters and different tax rates, and methods of calculation may be applied to individual customers, vendors, and products, (plus freight and handling), as required.
# 
# The tax codes determine the percentage (or amount) of tax to be applied according to a defined calculation method.  There are a number of methods for calculating tax.  These determine whether the tax rate is derived from the product, or from the customer (or vendor), or a combination of both, and whether the tax is calculated on an individual product line or whole invoice (or voucher) basis.  The methods available are listed below, and their use in typical tax regimes is described afterwards.
# 
# Method “P” The amount of sales tax is dictated by the tax Percentage associated with the Product.
# Method “D” The amount of sales tax is dictated by the (Dollar) tax amount associated with the Product.
# Method “T” The amount of sales tax is a flat percentage of the Transaction Total (ie. invoice or voucher) based on the Customer’s (or Vendor’s) tax rate.
# Method “N” The amount of (Net) sales tax is calculated by applying the Customer’s (or Vendor’s) tax rate to each Product line in a transaction, (which may result in a difference compared to the Total tax method due to the rounding of each line amount).
# Method “I” This is used to identify customers, vendors, or products whose prices are Inclusive of tax.  Whether or not tax is calculated depends on its combination with other methods.
# Method “X” This is used to identify customers, vendors, or products whose prices are Exclusive of tax.  Tax is not added (but may in some circumstances be deducted).
# Method “W” This is used to identify customers, vendors, and products that are subject to tax where the tax is collected at the last wholesale transaction.  Wholesale tax is calculated at the point of goods receipt entry (for vendors and stocked items with tax type “W”) and posted to a tax payable account.  The tax is then recalculated when posting the Cost of Goods sold for invoices and credits, (for customers and stocked items with tax type “W”), and posted to a tax claimable account.  The amount of tax is calculated from the percentage associated with the tax code stored on the product status record.
#
# The tax rate is primarily determined by the Customer’s (or Vendor’s) method.  However, in certain situations (defined below) the Product method will modify or overrule this.
# There are a number of different tax regimes supported by KandooERP.  These are listed below together with suggestions on how Tax Codes should be set up to implement them (however please refer to the AR Tax Calculation Summary for the definitive rules).
###############################################################
FUNCTION calc_line_tax(p_cmpy_code,p_cust_tax_code,p_prod_tax_code,p_prod_tax_amt,p_unit_qty,p_unit_cost_amt,p_unit_price_amt) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_cust_tax_code LIKE tax.tax_code 
	DEFINE p_prod_tax_code LIKE tax.tax_code 
	DEFINE p_prod_tax_amt LIKE prodstatus.purch_tax_amt
	DEFINE p_unit_qty LIKE prodstatus.onhand_qty  
 	DEFINE p_unit_cost_amt LIKE prodstatus.wgted_cost_amt
	DEFINE p_unit_price_amt LIKE prodstatus.list_amt
	DEFINE l_unit_tax_amt LIKE orderdetl.unit_tax_amt 
	DEFINE l_rec_customer_tax RECORD LIKE tax.* 
	DEFINE l_rec_product_tax RECORD LIKE tax.* 
	DEFINE l_msgresp LIKE language.yes_flag 

	##
	## Check FOR nulls
	##
	IF p_unit_qty IS NULL THEN 
		LET p_unit_qty = 0 
	END IF 

	IF p_unit_cost_amt IS NULL THEN 
		LET p_unit_cost_amt = 0 
	END IF 
# ---- next 2 are added by HuHo ... tax calc banged out progam
	IF l_unit_tax_amt IS NULL THEN 
		LET l_unit_tax_amt = 0 
	END IF 

	IF p_unit_price_amt IS NULL THEN 
		LET p_unit_price_amt = 0 
	END IF 

	## Obtain customer tax record.
	CALL db_tax_get_rec(UI_OFF,p_cust_tax_code) RETURNING l_rec_customer_tax.*
	IF l_rec_customer_tax.tax_code IS NULL THEN
		ERROR kandoomsg2("U",7001,"Tax")		#7001 Logic Error: Tax RECORD NOT found in database
		RETURN 0,0 
	END IF 
	
	## Obtain product tax record.
	IF p_prod_tax_code IS NULL THEN 

		## Non Inventory Line
		LET l_rec_product_tax.tax_per = 0 
	ELSE 
		CALL db_tax_get_rec(UI_OFF,p_prod_tax_code) RETURNING l_rec_product_tax.*	

		IF l_rec_product_tax.tax_code IS NULL THEN 
			ERROR kandoomsg2("U",7001,"Tax")		#7001 Logic Error: Tax RECORD NOT found in database
			RETURN 0,0 
		END IF 
	END IF 

	CASE 

		WHEN l_rec_customer_tax.calc_method_flag = "P" #Method "P" The amount of sales tax is dictated by the tax Percentage associated with the Product.
			OR l_rec_customer_tax.calc_method_flag = "I" #Method "I" This is used to identify customers, vendors, or products whose prices are Inclusive of tax.  Whether or not tax is calculated depends on its combination with other methods.

			CASE 
				WHEN l_rec_product_tax.calc_method_flag = "P" #Method "P" The amount of sales tax is dictated by the tax Percentage associated with the Product.
					LET l_unit_tax_amt = (l_rec_product_tax.tax_per/100) * (p_unit_price_amt) 

				WHEN l_rec_product_tax.calc_method_flag = "D" #Method “D” The amount of sales tax is dictated by the (Dollar) tax amount associated with the Product. 
					LET l_unit_tax_amt = p_prod_tax_amt 

				#HuHO added.. but I don'T trust it at all.. hack ?
				WHEN l_rec_product_tax.calc_method_flag IS NULL #User did not enter any item Tax Amt with freely entered(none-warehouse) items
					LET l_unit_tax_amt = p_prod_tax_amt
					
				OTHERWISE 
					LET l_unit_tax_amt = 0 

			END CASE 

		WHEN l_rec_customer_tax.calc_method_flag = "D" #Method “D” The amount of sales tax is dictated by the (Dollar) tax amount associated with the Product. 

			CASE 
				WHEN l_rec_product_tax.calc_method_flag = "P" #Method "P" The amount of sales tax is dictated by the tax Percentage associated with the Product. 
					OR l_rec_product_tax.calc_method_flag = "D" #Method “D” The amount of sales tax is dictated by the (Dollar) tax amount associated with the Product. 
					OR l_rec_product_tax.calc_method_flag = "I" #Method "I" This is used to identify customers, vendors, or products whose prices are Inclusive of tax.  Whether or not tax is calculated depends on its combination with other methods. 
					OR l_rec_product_tax.calc_method_flag = "X" #Method “X” This is used to identify customers, vendors, or products whose prices are Exclusive of tax.  Tax is not added (but may in some circumstances be deducted). 
					OR l_rec_product_tax.calc_method_flag = "E" #Method "E" is NOT documented
					LET l_unit_tax_amt = p_prod_tax_amt 

				#HuHO added.. but I don'T trust it at all.. hack ?
				WHEN l_rec_product_tax.calc_method_flag IS NULL #User did not enter any item Tax Amt with freely entered(none-warehouse) items
					LET l_unit_tax_amt = p_prod_tax_amt

				OTHERWISE 
					LET l_unit_tax_amt = 0 
			END CASE 

		WHEN l_rec_customer_tax.calc_method_flag = "N" #Method “N” The amount of (Net) sales tax is calculated by applying the Customer’s (or Vendor’s) tax rate to each Product line in a transaction, (which may result in a difference compared to the Total tax method due to the rounding of each line amount).

			CASE 
				WHEN l_rec_product_tax.calc_method_flag = "P" #Method "P" The amount of sales tax is dictated by the tax Percentage associated with the Product. 
					OR l_rec_product_tax.calc_method_flag = "D" #Method “D” The amount of sales tax is dictated by the (Dollar) tax amount associated with the Product.
					OR l_rec_product_tax.calc_method_flag = "T" #Method “T” The amount of sales tax is a flat percentage of the Transaction Total (ie. invoice or voucher) based on the Customer’s (or Vendor’s) tax rate.
					OR l_rec_product_tax.calc_method_flag = "N" #Method “N” The amount of (Net) sales tax is calculated by applying the Customer’s (or Vendor’s) tax rate to each Product line in a transaction, (which may result in a difference compared to the Total tax method due to the rounding of each line amount).
					LET l_unit_tax_amt = (l_rec_customer_tax.tax_per/100) * (p_unit_price_amt) 

				#HuHO added.. but I don'T trust it at all.. hack ?
				WHEN l_rec_product_tax.calc_method_flag IS NULL #User did not enter any item Tax Amt with freely entered(none-warehouse) items
					LET l_unit_tax_amt = p_prod_tax_amt

				OTHERWISE 
					LET l_unit_tax_amt = 0 
			END CASE 

		WHEN l_rec_customer_tax.calc_method_flag = "T" #Method “T” The amount of sales tax is a flat percentage of the Transaction Total (ie. invoice or voucher) based on the Customer’s (or Vendor’s) tax rate.

			CASE 
				WHEN l_rec_product_tax.calc_method_flag = "X" #Method “X” This is used to identify customers, vendors, or products whose prices are Exclusive of tax.  Tax is not added (but may in some circumstances be deducted).
					OR l_rec_product_tax.calc_method_flag = "E" #Method "E" is NOT documented
					OR l_rec_product_tax.calc_method_flag = "M" #M ???? Method "M" is NOT documented.. no idea...
					OR l_rec_product_tax.calc_method_flag = "W" #Method “W” This is used to identify customers, vendors, and products that are subject to tax where the tax is collected at the last wholesale transaction.  Wholesale tax is calculated at the point of goods receipt entry (for vendors and stocked items with tax type “W”) and posted to a tax payable account.  The tax is then recalculated when posting the Cost of Goods sold for invoices and credits, (for customers and stocked items with tax type “W”), and posted to a tax claimable account.  The amount of tax is calculated from the percentage associated with the tax code stored on the product status record.
					LET l_unit_tax_amt = 0 

				#HuHO added.. but I don'T trust it at all.. hack ?
				WHEN l_rec_product_tax.calc_method_flag IS NULL #User did not enter any item Tax Amt with freely entered(none-warehouse) items
					LET l_unit_tax_amt = p_prod_tax_amt

				OTHERWISE 
					LET l_unit_tax_amt = (l_rec_customer_tax.tax_per/100) * (p_unit_price_amt) 
			END CASE 

		WHEN l_rec_customer_tax.calc_method_flag = "X" #Method “X” This is used to identify customers, vendors, or products whose prices are Exclusive of tax.  Tax is not added (but may in some circumstances be deducted).
			OR l_rec_customer_tax.calc_method_flag = "E" #Method "E" is NOT documented

			CASE 
				WHEN l_rec_product_tax.calc_method_flag = "I" #Method "I" This is used to identify customers, vendors, or products whose prices are Inclusive of tax.  Whether or not tax is calculated depends on its combination with other methods. 
					IF p_prod_tax_amt != 0 THEN 
						LET l_unit_tax_amt = p_prod_tax_amt 
					ELSE 
						LET l_unit_tax_amt = 0 - ((l_rec_product_tax.tax_per/100)*p_unit_cost_amt) 
					END IF 

				#HuHO added.. but I don'T trust it at all.. hack ?
				WHEN l_rec_product_tax.calc_method_flag IS NULL #User did not enter any item Tax Amt with freely entered(none-warehouse) items
					LET l_unit_tax_amt = p_prod_tax_amt


				OTHERWISE 
					LET l_unit_tax_amt = 0 
			END CASE 

		WHEN l_rec_customer_tax.calc_method_flag = "W" #Method “W” This is used to identify customers, vendors, and products that are subject to tax where the tax is collected at the last wholesale transaction.  Wholesale tax is calculated at the point of goods receipt entry (for vendors and stocked items with tax type “W”) and posted to a tax payable account.  The tax is then recalculated when posting the Cost of Goods sold for invoices and credits, (for customers and stocked items with tax type “W”), and posted to a tax claimable account.  The amount of tax is calculated from the percentage associated with the tax code stored on the product status record. 
			#HuHO added.. but I don'T trust it at all.. hack ?
			IF l_rec_product_tax.calc_method_flag IS NULL THEN #User did not enter any item Tax Amt with freely entered(none-warehouse) items
				LET l_unit_tax_amt = p_prod_tax_amt
			ELSE 
				LET l_unit_tax_amt = 0
			END IF
 

		WHEN l_rec_customer_tax.calc_method_flag = "M" #M ???? Method "M" is NOT documented.. no idea...
			#HuHO added.. but I don'T trust it at all.. hack ?
			IF l_rec_product_tax.calc_method_flag IS NULL THEN #User did not enter any item Tax Amt with freely entered(none-warehouse) items
				LET l_unit_tax_amt = p_prod_tax_amt
			ELSE 
				LET l_unit_tax_amt = 0
			END IF
				
		OTHERWISE { calc method we don't know about } 
			LET l_unit_tax_amt = 0 

	END CASE 
	#------------------------------------------

	IF l_unit_tax_amt IS NULL THEN 
		LET l_unit_tax_amt = 0 
	END IF 

	RETURN l_unit_tax_amt,(l_unit_tax_amt*p_unit_qty) 
END FUNCTION 
###############################################################
# END FUNCTION calc_line_tax(p_cmpy_code,p_cust_tax_code,
###############################################################


###############################################################
# FUNCTION enter_exempt_num(p_cmpy_code,p_tax_code,p_num_text)
#
#
###############################################################
FUNCTION enter_exempt_num(p_cmpy_code,p_tax_code,p_num_text) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_tax_code LIKE tax.tax_code 
	DEFINE p_num_text LIKE customer.tax_num_text 
	DEFINE l_rec_tax RECORD LIKE tax.* 
	DEFINE l_msgresp LIKE language.yes_flag 

	SELECT * INTO l_rec_tax.* 
	FROM tax 
	WHERE cmpy_code = p_cmpy_code 
	AND tax_code = p_tax_code 

	IF status = NOTFOUND THEN 
		ERROR kandoomsg2("U",7001,"Tax")		#7001 Logic Error: Tax RECORD NOT found in database
		RETURN "" 
	END IF 

	OPEN WINDOW A101 with FORM "A101" 
	CALL winDecoration_a("A101") 

	DISPLAY l_rec_tax.tax_code TO tax_code 
	DISPLAY l_rec_tax.desc_text TO desc_text 

	ERROR kandoomsg2("U",1020,"Tax Exemption") 

	INPUT p_num_text WITHOUT DEFAULTS FROM tax_num_text ATTRIBUTE(UNBUFFERED) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","taxwind","input-num_text") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER FIELD tax_num_text 
			IF p_num_text IS NULL THEN 
				ERROR kandoomsg2("U",9102,"") 
				NEXT FIELD tax_num_text 
			END IF 

	END INPUT 


	CLOSE WINDOW A101 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN "" 
	ELSE 
		RETURN p_num_text 
	END IF 

END FUNCTION 
###############################################################
# FUNCTION enter_exempt_num(p_cmpy_code,p_tax_code,p_num_text)
###############################################################


###############################################################
# FUNCTION calc_total_tax (p_cmpy_code, p_mode, p_taxable_amt, p_tax_code)
#
#
###############################################################
FUNCTION calc_total_tax (p_cmpy_code,p_mode,p_taxable_amt,p_tax_code) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_mode CHAR(1) 
	DEFINE p_taxable_amt DECIMAL(16,2) 
	DEFINE p_tax_code CHAR(3) 
	DEFINE l_rec_tax RECORD LIKE tax.* 
	DEFINE l_tax_rate FLOAT 
	DEFINE l_tax_amt DECIMAL(16,2) 
	DEFINE l_msgresp LIKE language.yes_flag 

	SELECT * INTO l_rec_tax.* FROM tax 
	WHERE tax_code = p_tax_code 
	AND cmpy_code = p_cmpy_code 

	IF status = NOTFOUND THEN 
		ERROR kandoomsg2("I",6501,"")		#6501 Tax code IS blank OR NOT SET up.
		RETURN 0 
	END IF 

	CASE 

		WHEN p_mode = "F" 
			LET l_tax_rate = l_rec_tax.freight_per / 100 

		WHEN p_mode = "H" 
			LET l_tax_rate = l_rec_tax.hand_per / 100 

		WHEN p_mode = "T" 
			LET l_tax_rate = l_rec_tax.tax_per / 100 

		OTHERWISE 
			LET l_tax_rate = l_rec_tax.uplift_per / 100 

	END CASE 

	CASE 
		WHEN l_rec_tax.calc_method_flag = "T" 
			LET l_tax_amt = p_taxable_amt * l_tax_rate 

		OTHERWISE 
			LET l_tax_amt = 0 

	END CASE 

	RETURN l_tax_amt 
END FUNCTION 
###############################################################
# END FUNCTION calc_total_tax (p_cmpy_code, p_mode, p_taxable_amt, p_tax_code)
###############################################################


###############################################################
# FUNCTION valid_tax_usage(p_cmpy_code, p_tax_code, p_usage_ind, p_verbose_ind)
#
# Description: This FUNCTION determines whether the tax code IS valid
#              FOR the type of program it IS used in, based upon the tax code
#              calculation method.
# Passed:   p_cmpy_code code,
#           tax code,
#           usage indicator      - The type of program used in.
#           verbose indicator    - DISPLAY errors OR NOT.
#
# Returns:  valid tax code OR NOT.
###############################################################
FUNCTION valid_tax_usage(p_cmpy_code,p_tax_code,p_usage_ind,p_verbose_ind) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_tax_code LIKE tax.tax_code 
	DEFINE p_usage_ind CHAR(1) 
	DEFINE p_verbose_ind CHAR(1) 
	DEFINE l_calc_method_flag LIKE tax.calc_method_flag 
	DEFINE l_error_flag CHAR(1) 
	DEFINE l_msgresp LIKE language.yes_flag 

	IF p_cmpy_code IS NULL THEN 
		IF p_verbose_ind = "Y" THEN 
			ERROR kandoomsg2("U",7039,"Company code IS blank.")		#7039 Logic Error: Company code IS blank.
		END IF 
		RETURN FALSE 
	END IF 

	IF p_tax_code IS NULL THEN 
		IF p_verbose_ind = "Y" THEN 
			ERROR kandoomsg2("U",7039,"Tax code IS blank.") 	#7039 Logic Error: Tax code IS blank.
		END IF 
		RETURN FALSE 
	END IF 

	DECLARE c_tax CURSOR FOR 
	SELECT calc_method_flag FROM tax 
	WHERE cmpy_code = p_cmpy_code 
	AND tax_code = p_tax_code 

	OPEN c_tax 
	FETCH c_tax INTO l_calc_method_flag 

	IF status = NOTFOUND THEN 
		IF p_verbose_ind = "Y" THEN 
			ERROR kandoomsg2("U",7039,"Tax code does NOT exist.")		#7039 Logic Error: Tax code does NOT exist.
		END IF 
		RETURN FALSE 
	END IF 

	LET l_error_flag = FALSE 

	CASE p_usage_ind 

		WHEN "1" #product sell 
			IF l_calc_method_flag NOT MATCHES "[PDIXW]" THEN 
				LET l_error_flag = TRUE 
			END IF 

		WHEN "2" #product purchase 
			IF l_calc_method_flag NOT MATCHES "[PDIXW]" THEN 
				LET l_error_flag = TRUE 
			END IF 

		WHEN "3" #customer 
			IF l_calc_method_flag NOT MATCHES "[PDITXWEN]" THEN 
				LET l_error_flag = TRUE 
			END IF 

		WHEN "4" #vendor 
			IF l_calc_method_flag NOT MATCHES "[PDIXWMNH]" THEN 
				LET l_error_flag = TRUE 
			END IF 

		WHEN "5" #sales order/invoice 
			IF l_calc_method_flag NOT MATCHES "[PDIXWEN]" THEN 
				LET l_error_flag = TRUE 
			END IF 

		WHEN "6" #purchase order/voucher/chart OF accounts 
			IF l_calc_method_flag NOT MATCHES "[PDIXWMNH]" THEN 
				LET l_error_flag = TRUE 
			END IF 

		OTHERWISE 
			IF p_verbose_ind THEN 
				ERROR kandoomsg2("U",7039,"Usage Indicator IS invalid.") 			#7039 Logic Error: Usage Indicator IS invalid.
			END IF 

			RETURN FALSE 
	END CASE 
	#--------------------------------------------------------------

	IF l_error_flag THEN 
		IF p_verbose_ind = "Y" THEN 
			ERROR kandoomsg2("U",9050,"") 		#9050 The tax code IS NOT valid FOR this type of usage.
		END IF 
		RETURN FALSE 
	END IF 

	RETURN TRUE 
END FUNCTION 
###############################################################
# END FUNCTION valid_tax_usage(p_cmpy_code, p_tax_code, p_usage_ind, p_verbose_ind)
###############################################################