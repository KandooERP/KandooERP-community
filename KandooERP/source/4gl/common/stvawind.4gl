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

############################################################
# MODULE Scope Variables
############################################################
DEFINE glob_rec_product RECORD LIKE product.* 
DEFINE glob_rec_prodstatus RECORD LIKE prodstatus.* 
DEFINE glob_rec_inparms RECORD LIKE inparms.* 
DEFINE glob_arr_rec_prodstat DYNAMIC ARRAY OF 
	RECORD 
		ware_code LIKE prodstatus.ware_code, 
		wgted_cost_amt DECIMAL(16,2), 
		est_cost_amt DECIMAL(16,2), 
		act_cost_amt DECIMAL(16,2), 
		fifo_lifo DECIMAL(16,2) 
	END RECORD 
--DEFINE l_where_text STRING 
--DEFINE l_query_text STRING 
--DEFINE glob_runner STRING 
--DEFINE glob_filter_text STRING 
DEFINE glob_idx SMALLINT 

############################################################
# FUNCTION stock_valuation_window(p_cmpy, p_part_code)
#
# \brief module stock_valuation_window allows the user TO scan Valuation costs.
############################################################
FUNCTION stock_valuation_window(p_cmpy,p_part_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_part_code LIKE product.part_code 
	DEFINE l_ret_value INTEGER 

	CALL db_inparms_get_rec(UI_OFF,"1") RETURNING glob_rec_inparms.*
	IF glob_rec_inparms.parm_code IS NULL THEN 
		CALL fgl_winmessage("IN-Configuration Error",kandoomsg2("I",5002,""),"ERROR")		#5002" Inventory parameters are NOT SET up - Refer Menu IZP
		SLEEP 2 
		RETURN FALSE 
	END IF 

	OPEN WINDOW I183 with FORM "I183" 
	CALL windecoration_i("I183") 

	IF p_part_code IS NOT NULL THEN 
		IF stock_valuation_product_display(p_cmpy, p_part_code) THEN 
			CALL stock_valuation_scan_manage_product(p_cmpy, p_part_code) 
		END IF 
	ELSE 
		CALL stock_valuation_product_select(p_cmpy) RETURNING l_ret_value, p_part_code 
		IF l_ret_value = TRUE THEN 
			CALL stock_valuation_scan_manage_product(p_cmpy, p_part_code) 
		END IF 
	END IF 

	CLOSE WINDOW I183 
END FUNCTION 
############################################################
# END FUNCTION stock_valuation_window(p_cmpy, p_part_code)
############################################################


############################################################
# FUNCTION stock_valuation_product_display(p_cmpy, p_part_code)
#
#
############################################################
FUNCTION stock_valuation_product_display(p_cmpy,p_part_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_part_code LIKE product.part_code 

	DISPLAY p_part_code TO prodstatus.part_code 
	SELECT * INTO glob_rec_product.* FROM product 
	WHERE cmpy_code = p_cmpy 
	AND part_code = p_part_code 
	IF status = notfound THEN 
		ERROR kandoomsg2("I",5010,p_part_code) 	#5010" Logic error: Product code NOT found ????"
		SLEEP 2
		RETURN FALSE 
	END IF 

	DISPLAY glob_rec_product.desc_text TO product.desc_text 
	DISPLAY glob_rec_product.desc2_text TO product.desc2_text
	 
	RETURN TRUE 
END FUNCTION 
############################################################
# END FUNCTION stock_valuation_product_display(p_cmpy, p_part_code)
############################################################


############################################################
# FUNCTION stock_valuation_product_select(p_cmpy)
#
#
############################################################
FUNCTION stock_valuation_product_select(p_cmpy) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE l_part_code LIKE product.part_code 

	INPUT l_part_code WITHOUT DEFAULTS 
	FROM prodstatus.part_code 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","stvawind","input-l_part_code") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
			
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER FIELD part_code 
			SELECT * INTO glob_rec_product.* FROM product 
			WHERE cmpy_code = p_cmpy 
			AND part_code = l_part_code 
			IF status = notfound THEN 
				ERROR kandoomsg2("I",9010,"")	# 9010 Product does NOT exist - Try window
				NEXT FIELD part_code 
			ELSE 
				DISPLAY glob_rec_product.desc_text TO product.desc_text 
				DISPLAY glob_rec_product.desc2_text TO product.desc2_text 
			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN FALSE, " " 
	END IF 
	RETURN TRUE, l_part_code 
END FUNCTION 
############################################################
# END FUNCTION stock_valuation_product_select(p_cmpy)
############################################################


############################################################
# FUNCTION db_prodstatus_stock_valuation_get_datasource(p_cmpy, p_part_code)
#
#
############################################################
FUNCTION db_prodstatus_stock_valuation_get_datasource(p_filter,p_cmpy,p_part_code)
	DEFINE p_filter BOOLEAN 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_part_code LIKE product.part_code 
	DEFINE l_ware_code LIKE warehouse.ware_code 
	DEFINE l_ret_value INTEGER 
	DEFINE l_where_text STRING
	DEFINE l_query_text STRING
	DEFINE l_arr_rec_prodstat DYNAMIC ARRAY OF	RECORD 
		ware_code LIKE prodstatus.ware_code, 
		wgted_cost_amt DECIMAL(16,2), 
		est_cost_amt DECIMAL(16,2), 
		act_cost_amt DECIMAL(16,2), 
		fifo_lifo DECIMAL(16,2) 
	END RECORD 	
	DEFINE l_idx SMALLINT
	
	IF p_filter THEN

		MESSAGE kandoomsg2("I",1001,"") # 1001" Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON ware_code 
	
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","stvawind","construct-prodstatus") 
	
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
	
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
		END CONSTRUCT 
	
		IF int_flag OR quit_flag THEN 
			LET int_flag = FALSE 
			LET quit_flag = FALSE 
			LET l_where_text = " 1=1 "
		END IF
	ELSE
		LET l_where_text = " 1=1 "
	END IF 

	MESSAGE kandoomsg2("U",1002,"")	#1002 Searching Database;  Please Wait;
	LET l_query_text = 
		"SELECT * FROM prodstatus", 
		" WHERE cmpy_code = \"",p_cmpy,"\" ", 
		" AND part_code = \"",p_part_code,"\" ", 
		" AND ",l_where_text CLIPPED," ", 
		"ORDER BY ware_code" 

	LET l_idx = 0 
	PREPARE s_product FROM l_query_text 
	DECLARE c_product SCROLL CURSOR FOR s_product 

	FOREACH c_product INTO glob_rec_prodstatus.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_prodstat[l_idx].ware_code = glob_rec_prodstatus.ware_code 
		LET l_arr_rec_prodstat[l_idx].wgted_cost_amt = glob_rec_prodstatus.wgted_cost_amt *	glob_rec_prodstatus.onhand_qty 
		LET l_arr_rec_prodstat[l_idx].est_cost_amt = glob_rec_prodstatus.est_cost_amt * glob_rec_prodstatus.onhand_qty 
		LET l_arr_rec_prodstat[l_idx].act_cost_amt = glob_rec_prodstatus.act_cost_amt * glob_rec_prodstatus.onhand_qty 
		LET l_arr_rec_prodstat[l_idx].fifo_lifo = NULL 

		IF glob_rec_inparms.cost_ind = "F" OR glob_rec_inparms.cost_ind = "L" THEN 
			SELECT sum(curr_cost_amt * onhand_qty) INTO l_arr_rec_prodstat[l_idx].fifo_lifo 
			FROM costledg 
			WHERE cmpy_code = p_cmpy 
			AND part_code = glob_rec_prodstatus.part_code 
			AND ware_code = glob_rec_prodstatus.ware_code 
		END IF 

		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF			
	END FOREACH 

	IF l_arr_rec_prodstat.getSize() = 0 THEN 
		ERROR kandoomsg2("I",9099,"") #9099 No product found TO satisfied the selection criteria
	END IF 

	RETURN l_arr_rec_prodstat
END FUNCTION 
############################################################
# END FUNCTION db_prodstatus_stock_valuation_get_datasource(p_cmpy, p_part_code)
############################################################


############################################################
# FUNCTION stock_valuation_scan_manage_product(p_cmpy, p_part_code)
#
#
############################################################
FUNCTION stock_valuation_scan_manage_product(p_cmpy,p_part_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_part_code LIKE product.part_code 
	DEFINE l_ware_code LIKE warehouse.ware_code 
	DEFINE l_ret_value INTEGER 

	CALL db_prodstatus_stock_valuation_get_datasource(FALSE,p_cmpy, p_part_code) RETURNING glob_arr_rec_prodstat 
	IF glob_rec_inparms.cost_ind = "L" OR glob_rec_inparms.cost_ind = "F" THEN 
		MESSAGE kandoomsg2("I",1007,"")	# F3/F4 TO page forward/backward RETURN on line TO View
	ELSE 
		MESSAGE kandoomsg2("I",1008,"") # F3/F4 TO page forward/backward ESC TO continue
	END IF 

	DISPLAY ARRAY glob_arr_rec_prodstat TO sr_prodstat.* 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","stvawind","input-arr-prodstat") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar()
			 
		ON ACTION "FILTER"
			CALL glob_arr_rec_prodstat.clear()
			CALL db_prodstatus_stock_valuation_get_datasource(FALSE,p_cmpy, p_part_code) RETURNING glob_arr_rec_prodstat

		ON ACTION "REFRESH"
			CALL windecoration_i("I183") 
			CALL glob_arr_rec_prodstat.clear()
			CALL db_prodstatus_stock_valuation_get_datasource(FALSE,p_cmpy, p_part_code) RETURNING glob_arr_rec_prodstat

		ON ACTION "DETAIL" --BEFORE FIELD wgted_cost_amt 
			IF (glob_rec_inparms.cost_ind = "L" OR glob_rec_inparms.cost_ind = "F") 
			AND glob_arr_rec_prodstat[glob_idx].fifo_lifo IS NOT NULL THEN 
				CALL cost_ledger_inquiry(p_cmpy,glob_rec_prodstatus.part_code, l_ware_code) 
			END IF 

			LET glob_arr_rec_prodstat[glob_idx].ware_code = l_ware_code 
			NEXT FIELD ware_code 

		BEFORE ROW --BEFORE FIELD ware_code 
			LET glob_idx = arr_curr() 
			LET l_ware_code = glob_arr_rec_prodstat[glob_idx].ware_code 
			
	END DISPLAY

	LET int_flag = FALSE 
	LET quit_flag = FALSE 

	CLEAR FORM 
--	OPTIONS INSERT KEY f1, 
--	DELETE KEY f2
	RETURN l_ware_code --why not... I hate this globals approach 
END FUNCTION 
############################################################
# END FUNCTION stock_valuation_scan_manage_product(p_cmpy, p_part_code)
############################################################