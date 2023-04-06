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
###########################################################################
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl" 
GLOBALS "../ar/AZ_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/AZ1_GLOBALS.4gl" 

############################################################
# Module Scope Variables
############################################################

##############################################################################
# FUNCTION AZ1_main()
#
# Facility TO SET up AND maintain all tax codes that are used throughout KandooERP.  One tax code should be SET up for each unique rate AND method that IS used TO calculate tax.
# These codes are then linked TO particular Customers, Vendors AND Products as required.  The use of codes (rather than entering the actual percentage), ensures accuracy WHILE still enabling rates TO be changed easily.
# The same Tax Codes are used by the AR, AP AND Inventory Systems.  Therefore, take care when changing OR deleting codes since a change TO a code in one system will apply TO all systems in which it IS used.
##############################################################################
FUNCTION AZ1_main() 
	DEFINE l_filter SMALLINT 

	DEFER quit 
	DEFER interrupt 

	CALL setModuleId("AZ1") 

	OPEN WINDOW A100 with FORM "A100" 
	CALL windecoration_a("A100") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	CALL AZ1_scan_tax()

--	WHILE select_tax(l_filter) 
--		LET l_filter = AZ1_scan_tax() 
--		IF l_filter = 2 OR int_flag THEN 
--			EXIT WHILE 
--		END IF 
--	END WHILE 

	CLOSE WINDOW A100 
END FUNCTION 
##############################################################################
# END FUNCTION AZ1_main()
##############################################################################


##############################################################################
# FUNCTION db_tax_get_datasource(p_filter)
#
#
##############################################################################
FUNCTION db_tax_get_datasource(p_filter) 
	DEFINE p_filter SMALLINT 
	DEFINE l_query_text STRING
	DEFINE l_where_text STRING 
	DEFINE l_rec_tax RECORD LIKE tax.* 
	DEFINE l_arr_rec_tax DYNAMIC ARRAY OF RECORD 
		scroll_flag CHAR(1), 
		tax_code LIKE tax.tax_code, 
		desc_text LIKE tax.desc_text, 
		calc_method_flag LIKE tax.calc_method_flag, 
		tax_per LIKE tax.tax_per 
	END RECORD 
	DEFINE l_idx SMALLINT 

	IF p_filter THEN 
		CLEAR FORM 
		MESSAGE kandoomsg2("U",1001,"")		#1001 Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON 
			tax_code, 
			desc_text, 
			calc_method_flag, 
			tax_per 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","AZ1","construct-tax") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_where_text = " 1=1 " 
		END IF 
	ELSE 
		LET l_where_text = " 1=1 " 
	END IF 

	MESSAGE kandoomsg2("U",1002,"") #1002 Searching database - pls wait
	LET l_query_text = 
		"SELECT * FROM tax ", 
		"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND ",l_where_text clipped," ", 
		"ORDER BY tax_code" 

	PREPARE s_tax FROM l_query_text 
	DECLARE c_tax CURSOR FOR s_tax 

	LET l_idx = 0 
	FOREACH c_tax INTO l_rec_tax.* 
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

	MESSAGE kandoomsg2("U",9113,l_idx) 

	RETURN l_arr_rec_tax 

END FUNCTION 
##############################################################################
# END FUNCTION db_tax_get_datasource(p_filter)
##############################################################################


##############################################################################
# FUNCTION AZ1_scan_tax()
#
#
##############################################################################
FUNCTION AZ1_scan_tax() 
	DEFINE l_rec_tax RECORD LIKE tax.* 
	DEFINE l_arr_rec_tax DYNAMIC ARRAY OF RECORD 
		scroll_flag CHAR(1), 
		tax_code LIKE tax.tax_code, 
		desc_text LIKE tax.desc_text, 
		calc_method_flag LIKE tax.calc_method_flag, 
		tax_per LIKE tax.tax_per 
	END RECORD 
	DEFINE l_idx SMALLINT 

	#if the the table has more than 1000 rows, force a query TO filter data
	IF db_tax_get_count() < 1000 THEN 
		CALL db_tax_get_datasource(FALSE) RETURNING l_arr_rec_tax
	ELSE
		CALL db_tax_get_datasource(TRUE) RETURNING l_arr_rec_tax	 
	END IF 

	MESSAGE kandoomsg2("U",1003,"")	#1003 "F1 TO Add - F2 TO Delete - RETURN TO Edit
	DISPLAY ARRAY l_arr_rec_tax TO sr_tax.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","AZ1","inp-tax") 
			CALL dialog.setActionHidden("ACCEPT",TRUE)
			CALL dialog.setActionHidden("EDIT",NOT l_arr_rec_tax.getSize())
			CALL dialog.setActionHidden("DELETE",NOT l_arr_rec_tax.getSize())

		BEFORE ROW 
			LET l_idx = arr_curr() 

		ON ACTION "FILTER" 
			CALL l_arr_rec_tax.clear()
			CALL db_tax_get_datasource(TRUE) RETURNING l_arr_rec_tax 

		ON ACTION "REFRESH" 
			CALL l_arr_rec_tax.clear()
			CALL db_tax_get_datasource(FALSE) RETURNING l_arr_rec_tax 
			CALL windecoration_a("A100")
			
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION ("EDIT","doubleClick")
			IF (l_idx > 0) AND (l_idx <= l_arr_rec_tax.getSize()) THEN
				CALL edit_tax(l_arr_rec_tax[l_idx].tax_code) 
				--CALL getprogarrayfromdb() RETURNING l_arr_rec_tax
				CALL l_arr_rec_tax.clear()
				CALL db_tax_get_datasource(FALSE) RETURNING l_arr_rec_tax 
			END IF

		ON ACTION "NEW" 
			CALL edit_tax("") 
--			CALL getprogarrayfromdb() RETURNING l_arr_rec_tax 
			CALL l_arr_rec_tax.clear()
			CALL db_tax_get_datasource(FALSE) RETURNING l_arr_rec_tax 
			CALL dialog.setActionHidden("EDIT",NOT l_arr_rec_tax.getSize())
			CALL dialog.setActionHidden("DELETE",NOT l_arr_rec_tax.getSize())

		ON ACTION "DELETE" 
			IF (l_idx > 0) AND (l_idx <= l_arr_rec_tax.getSize()) THEN
				IF kandoomsg("U",8020,1) = "Y" THEN		#8001 Confirmation TO delete l_del_cnt Sales Area
	
					IF tax_deleteable(l_arr_rec_tax[l_idx].tax_code) THEN 
						DELETE FROM tax 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND tax_code = l_arr_rec_tax[l_idx].tax_code 
	
--						IF status >= 0 THEN 
--							CALL getprogarrayfromdb() RETURNING l_arr_rec_tax 
--						END IF
			 			CALL l_arr_rec_tax.clear()
						CALL db_tax_get_datasource(FALSE) RETURNING l_arr_rec_tax 
 
					ELSE 
						ERROR kandoomsg2("U",9114,"") 
					END IF 
				END IF
			END IF 

			CALL dialog.setActionHidden("EDIT",NOT l_arr_rec_tax.getSize())
			CALL dialog.setActionHidden("DELETE",NOT l_arr_rec_tax.getSize())

	END DISPLAY 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 
END FUNCTION 
##############################################################################
# END FUNCTION AZ1_scan_tax()
##############################################################################


##############################################################################
# FUNCTION getProgArrayfromDb()
#
# Return the tax data record array with all records
#
# Note: FUNCTION edit_tax(p_tax_code) IS also defined in GT1.4gl HuHo
##############################################################################
FUNCTION getprogarrayfromdb() 
	DEFINE l_rec_tax RECORD LIKE tax.* 
	DEFINE l_arr_rec_tax DYNAMIC ARRAY OF RECORD 
		scroll_flag CHAR(1), 
		tax_code LIKE tax.tax_code, 
		desc_text LIKE tax.desc_text, 
		calc_method_flag LIKE tax.calc_method_flag, 
		tax_per LIKE tax.tax_per 
	END RECORD 
	DEFINE l_idx int 

	LET l_idx = 0 
	FOREACH c_tax INTO l_rec_tax.* 
		LET l_idx = l_idx + 1 
		DISPLAY "l_idx=", trim(l_idx), " arrSize=", trim(l_arr_rec_tax.getSize()), " tax_code=", trim(l_rec_tax.tax_code)
		LET l_arr_rec_tax[l_idx].tax_code = l_rec_tax.tax_code 
		LET l_arr_rec_tax[l_idx].desc_text = l_rec_tax.desc_text 
		LET l_arr_rec_tax[l_idx].calc_method_flag = l_rec_tax.calc_method_flag 
		LET l_arr_rec_tax[l_idx].tax_per = l_rec_tax.tax_per 
	END FOREACH 

	RETURN l_arr_rec_tax 

END FUNCTION 
##############################################################################
# END FUNCTION getProgArrayfromDb()
##############################################################################


##############################################################################
# FUNCTION edit_tax(p_tax_code)
#
# Edit AND create new
#
# Note: FUNCTION edit_tax(p_tax_code) IS also defined in GT1.4gl HuHo
##############################################################################
FUNCTION edit_tax(p_tax_code) 
	DEFINE p_tax_code LIKE tax.tax_code 
	DEFINE l_rec_tax RECORD LIKE tax.* 
	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_calc_desc_text CHAR(60) 
	DEFINE l_err_message CHAR(60) 
	DEFINE l_winds_text CHAR(40) 
	DEFINE l_sqlerrd INTEGER 
	DEFINE l_temp_text CHAR(40) #huho moved FROM globs TO local scope 

	IF p_tax_code IS NOT NULL THEN 
		SELECT * INTO l_rec_tax.* 
		FROM tax 
		WHERE tax_code = p_tax_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET l_calc_desc_text =	kandooword("tax.calc_method_flag",l_rec_tax.calc_method_flag) 
	ELSE 
		LET l_rec_tax.calc_method_flag = "X" 
		LET l_rec_tax.tax_per = 0 
		LET l_rec_tax.freight_per = 0 
		LET l_rec_tax.hand_per = 0 
		LET l_rec_tax.uplift_per = 0 
		LET l_rec_tax.start_date = today 
	END IF 

	OPEN WINDOW A119 with FORM "A119" 
	CALL windecoration_a("A119") 

	DISPLAY get_tax_calculation_description("A") TO tax_calc_description_detailed
	ERROR kandoomsg2("U",1020,"Tax") 

	INPUT 
		l_rec_tax.tax_code, 
		l_rec_tax.desc_text, 
		l_rec_tax.calc_method_flag, 
		l_rec_tax.start_date, 
		l_rec_tax.sell_acct_code, 
		l_rec_tax.buy_acct_code, 
		l_rec_tax.tax_per, 
		l_rec_tax.freight_per, 
		l_rec_tax.hand_per, 
		l_rec_tax.uplift_per WITHOUT DEFAULTS 
	FROM
		tax_code, 
		tax.desc_text, 
		calc_method_flag, 
		start_date, 
		sell_acct_code, 
		buy_acct_code, 
		tax_per, 
		freight_per, 
		hand_per, 
		uplift_per	ATTRIBUTE(UNBUFFERED)

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","AZ1","inp-tax") 
			DISPLAY kandooword("tax.calc_method_flag",l_rec_tax.calc_method_flag) TO calc_desc_text
			DISPLAY db_coa_get_desc_text(UI_OFF,l_rec_tax.sell_acct_code) TO sell_desc_text
			DISPLAY db_coa_get_desc_text(UI_OFF,l_rec_tax.buy_acct_code) TO buy_desc_text
			DISPLAY get_tax_calculation_description(l_rec_tax.calc_method_flag) TO tax_calc_description
						
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield (sell_acct_code) 
			LET l_temp_text = show_acct(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET l_rec_tax.sell_acct_code = l_temp_text 
			END IF 
			NEXT FIELD sell_acct_code 

		ON ACTION "LOOKUP" infield (buy_acct_code) 
			LET l_temp_text = show_acct(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET l_rec_tax.buy_acct_code = l_temp_text 
			END IF 
			NEXT FIELD buy_acct_code 

		ON ACTION "LOOKUP" infield (start_date) 
			LET l_winds_text = showdate(l_rec_tax.start_date) 
			IF l_winds_text IS NOT NULL THEN 
				LET l_rec_tax.start_date = l_winds_text 
			END IF 
			NEXT FIELD start_date 


		BEFORE FIELD tax_code 
			IF p_tax_code IS NOT NULL THEN 
				NEXT FIELD desc_text 
			END IF 

		AFTER FIELD tax_code 
			IF l_rec_tax.tax_code IS NOT NULL THEN 
				SELECT unique 1 FROM tax 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND tax_code = l_rec_tax.tax_code 
				IF status = 0 THEN 
					ERROR kandoomsg2("U",9104,"") 				#9104 " RECORD already exists - Please Re Enter"
					LET l_rec_tax.tax_code = NULL 
					NEXT FIELD tax_code 
				END IF 
			END IF 

		AFTER FIELD tax_per 
			IF l_rec_tax.tax_per IS NOT NULL THEN 
				IF l_rec_tax.tax_per < 0 THEN 
					ERROR " Tax percentage must be greater than OR equal TO zero" 
					NEXT FIELD tax_per 
				END IF 
			ELSE 
				LET l_rec_tax.tax_per = 0 
				NEXT FIELD tax_per 
			END IF 

		ON CHANGE sell_acct_code
			DISPLAY db_coa_get_desc_text(UI_OFF,l_rec_tax.sell_acct_code) TO sell_desc_text

		AFTER FIELD sell_acct_code 
			CLEAR sell_desc_text 
			IF l_rec_tax.sell_acct_code IS NOT NULL THEN 
				SELECT * INTO l_rec_coa.* 
				FROM coa 
				WHERE acct_code = l_rec_tax.sell_acct_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("U",9105,"") 				#9105 " Tax Account Code-Sell NOT found, try window"
					NEXT FIELD sell_acct_code 
				ELSE 
					DISPLAY l_rec_coa.desc_text TO sell_desc_text 

				END IF 
			END IF 

		ON CHANGE buy_acct_code
			DISPLAY db_coa_get_desc_text(UI_OFF,l_rec_tax.buy_acct_code) TO buy_desc_text		

		AFTER FIELD buy_acct_code 
			CLEAR buy_desc_text 
			IF l_rec_tax.buy_acct_code IS NOT NULL THEN 
				SELECT * INTO l_rec_coa.* 
				FROM coa 
				WHERE acct_code = l_rec_tax.buy_acct_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("U",9105,"") 			#9105 " Tax Account Code-Sell NOT found, try window"
					NEXT FIELD buy_acct_code 
				ELSE 
					DISPLAY l_rec_coa.desc_text TO buy_desc_text 

				END IF 
			END IF 

		BEFORE FIELD start_date 
			IF l_rec_tax.start_date IS NULL THEN 
				LET l_rec_tax.start_date = today 
			END IF 

		ON CHANGE calc_method_flag
			DISPLAY kandooword("tax.calc_method_flag",l_rec_tax.calc_method_flag) TO calc_desc_text
			DISPLAY get_tax_calculation_description(l_rec_tax.calc_method_flag) TO tax_calc_description

		AFTER FIELD calc_method_flag 
--			LET l_calc_desc_text = kandooword("tax.calc_method_flag",l_rec_tax.calc_method_flag) 
			DISPLAY kandooword("tax.calc_method_flag",l_rec_tax.calc_method_flag) TO calc_desc_text 

		AFTER FIELD freight_per 
			IF l_rec_tax.freight_per IS NOT NULL THEN 
				IF l_rec_tax.freight_per < 0 THEN 
					error" percentage must be greater than OR equal TO zero" 
					NEXT FIELD freight_per 
				END IF 
			ELSE 
				LET l_rec_tax.freight_per = 0 
				NEXT FIELD freight_per 
			END IF 

		AFTER FIELD hand_per 
			IF l_rec_tax.hand_per IS NOT NULL THEN 
				IF l_rec_tax.hand_per < 0 THEN 
					error" percentage must be greater than OR equal TO zero" 
					NEXT FIELD hand_per 
				END IF 
			ELSE 
				LET l_rec_tax.hand_per = 0 
				NEXT FIELD hand_per 
			END IF 

		AFTER FIELD uplift_per 
			IF l_rec_tax.uplift_per IS NOT NULL THEN 
				IF l_rec_tax.uplift_per < 0 THEN 
					error" percentage must be greater than OR equal TO zero" 
					NEXT FIELD uplift_per 
				END IF 
			ELSE 
				LET l_rec_tax.uplift_per = 0 
				NEXT FIELD uplift_per 
			END IF 

		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN 
				IF l_rec_tax.tax_code IS NULL THEN 
					ERROR kandoomsg2("U",9102,"") 				#9102 " Tax Code must be Entered"
					NEXT FIELD tax_code 
				END IF 
				IF l_rec_tax.desc_text IS NULL THEN 
					ERROR kandoomsg2("U",9102,"") 				#9049 " Description must be entered
					NEXT FIELD desc_text 
				END IF 
				IF p_tax_code IS NULL THEN 
				END IF 
			END IF 

	END INPUT 

	CLOSE WINDOW A119 

	IF int_flag OR quit_flag THEN 
		LET quit_flag = false 
		LET int_flag = false 
		RETURN false 
	ELSE 
		LET l_err_message = "AZ1 - Updating tax" 
		MESSAGE l_err_message 
		#GOTO bypass
		#label recovery:
		#   IF error_recover(l_err_message,STATUS) = "N" THEN
		#      RETURN FALSE
		#   END IF
		#
		#label bypass:
		#WHENEVER ERROR GOTO recovery
		BEGIN WORK 

			IF p_tax_code IS NULL THEN 
				SELECT unique 1 FROM tax 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND tax_code = l_rec_tax.tax_code 
				IF status = 0 THEN 
					ERROR kandoomsg2("U",9102,"") 				#9104" TAx Code already exists - Please Re Enter"
					LET l_sqlerrd = 0 
				ELSE 
					LET l_rec_tax.cmpy_code = glob_rec_kandoouser.cmpy_code
					 
					INSERT INTO tax VALUES (l_rec_tax.*) 
					
					LET l_sqlerrd = sqlca.sqlerrd[6] 
				END IF 
			ELSE 
				UPDATE tax 
				SET * = l_rec_tax.* 
				WHERE tax_code = l_rec_tax.tax_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET l_sqlerrd = sqlca.sqlerrd[3] 
			END IF 

		COMMIT WORK 
		WHENEVER ERROR stop 
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

	END IF 

	RETURN p_tax_code 	#RETURN l_sqlerrd
END FUNCTION 
##############################################################################
# END FUNCTION edit_tax(p_tax_code)
##############################################################################


##############################################################################
# FUNCTION tax_deleteable(p_tax_code)
#
#
##############################################################################
FUNCTION tax_deleteable(p_tax_code) 
	DEFINE p_tax_code LIKE tax.tax_code 

	SELECT unique 1 FROM customer 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND tax_code = p_tax_code 

	IF status = 0 THEN 
		RETURN false 
	END IF 

	SELECT unique 1 FROM vendor 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND tax_code = p_tax_code 

	IF status = 0 THEN 
		RETURN false 
	END IF 

	RETURN true 
END FUNCTION 
##############################################################################
# END FUNCTION tax_deleteable(p_tax_code)
##############################################################################


#################################################################################################################################################################################################################
# AZ1 - Tax Code Maintenance
#################################################################################################################################################################################################################
# This facility TO SET up AND maintain all tax codes that are used throughout KandooERP.  One tax code should be SET up for each unique rate AND method that IS used TO calculate tax.
# These codes are then linked TO particular Customers, Vendors AND Products as required.  The use of codes (rather than entering the actual percentage), ensures accuracy WHILE still enabling rates TO be changed easily.
#
# The same Tax Codes are used by the AR, AP AND Inventory Systems.  Therefore, take care when changing OR deleting codes since a change TO a code in one system will apply TO all systems in which it IS used.
#
# Overview of Predefined Tax Calculation Methods
#
# Depending on the laws of your country, sales tax may OR may NOT be associated with customers, vendors AND/OR products.  KandooERP has been designed TO provide flexibility in tax matters
# AND different tax rates, AND methods of calculation may be applied TO individual customers, vendors, AND products, (plus freight AND handling), as required.
#
# The tax codes determine the percentage (OR amount) of tax TO be applied according TO a defined calculation method.  There are a number of methods for calculating tax.
# These determine whether the tax rate IS derived FROM the product, OR FROM the customer (OR vendor), OR a combination of both, AND whether the tax IS calculated on an individual product line OR whole invoice (OR voucher) basis.
# The methods available are listed below, AND their use in typical tax regimes IS described afterwards.
#
# Method “P”
#
# The amount of sales tax IS dictated by the tax Percentage associated with the Product.
#
# Method “D”
#
# The amount of sales tax IS dictated by the (Dollar) tax amount associated with the Product.
#
# Method “T”
#
# The amount of sales tax IS a flat percentage of the Transaction Total (ie. invoice OR voucher) based on the Customer’s (OR Vendor’s) tax rate.
#
# Method “N”
#
# The amount of (Net) sales tax IS calculated by applying the Customer’s (OR Vendor’s) tax rate TO each Product line in a transaction, (which may result in a difference compared TO the Total tax method due TO the rounding of each line amount).
#
# Method “I”
#
# This IS used TO identify customers, vendors, OR products whose prices are Inclusive of tax.  Whether OR NOT tax IS calculated depends on its combination with other methods.
#
# Method “X”
#
# This IS used TO identify customers, vendors, OR products whose prices are Exclusive of tax.  Tax IS NOT added (but may in some circumstances be deducted).
#
# Method “W”
#
# This IS used TO identify customers, vendors, AND products that are subject TO tax where the tax IS collected at the last wholesale transaction.
#  Wholesale tax IS calculated at the point of goods receipt entry (for vendors AND stocked items with tax type “W”) AND posted TO a tax payable account.
# The tax IS then recalculated when posting the Cost of Goods sold for invoices AND credits, (for customers AND stocked items with tax type “W”), AND posted TO a tax claimable account.  The amount of tax IS calculated FROM the percentage associated with the tax code stored on the product STATUS record.
#
# The tax rate IS primarily determined by the Customer’s (OR Vendor’s) method.  However, in certain situations (defined below) the Product method will modify OR overrule this.
# There are a number of different tax regimes supported by KandooERP.  These are listed below together with suggestions on how Tax Codes should be SET up TO implement them (however please refer TO the AR Tax Calculation Summary for the definitive rules).
#################################################################################################################################################################################################################