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
# Requires
# common\orhdwind.4gl
# common/orddfunc.4gl
###########################################################################

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../eo/E_EO_GLOBALS.4gl"
GLOBALS "../eo/E3_GROUP_GLOBALS.4gl"
GLOBALS "../eo/E33_GLOBALS.4gl" 
###########################################################################
# MODULE Scope Variables
###########################################################################
DEFINE modu_rec_product RECORD LIKE product.* 
DEFINE modu_rec_prodstatus RECORD LIKE prodstatus.*
DEFINE modu_rec_backorder RECORD LIKE backorder.* 
DEFINE modu_arr_rec_backorder DYNAMIC ARRAY OF RECORD --array[240] OF RECORD 
	alloc_qty LIKE backorder.alloc_qty, 
	cust_code LIKE backorder.cust_code, 
	order_num LIKE backorder.order_num, 
	line_num LIKE backorder.line_num, 
	order_date LIKE backorder.order_date, 
	req_qty LIKE backorder.req_qty 
END RECORD 
DEFINE modu_func_type char(14)
###########################################################################
# FUNCTION E33_main()
#
# allows the user TO alter backorder allocations
###########################################################################
FUNCTION E33_main() 
	DEFINE l_ans CHAR

	DEFER QUIT 
	DEFER INTERRUPT 

	CALL setModuleId("E33") 

	LET modu_func_type = "View order" 
	LET l_ans = "Y" 

	OPEN WINDOW E404 with FORM "E404" 
	 CALL windecoration_e("E404") 
	CALL scan_backorder() 

	CLOSE WINDOW E404

END FUNCTION 
###########################################################################
# END FUNCTION E33_main()
###########################################################################


###########################################################################
# FUNCTION db_backorder_get_datasource(p_filter)
#
#
###########################################################################
FUNCTION db_backorder_get_datasource(p_filter)
	DEFINE p_filter BOOLEAN
	DEFINE l_idx SMALLINT
	DEFINE l_quant_alloc decimal(10,2)
	DEFINE l_quant_unalloc decimal(10,2)
	DEFINE l_pre_alloc decimal(10,2) 
	DEFINE l_query_text STRING
	
	IF p_filter THEN
		MESSAGE " Enter Product ID FOR allocation details"	attribute (yellow) 
	
		INPUT BY NAME
			modu_rec_backorder.part_code, 
			modu_rec_backorder.ware_code WITHOUT DEFAULTS ATTRIBUTE(UNBUFFERED) 
	
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","E33","input-part_code-1") 
	
			ON ACTION "WEB-HELP"  
				CALL onlinehelp(getmoduleid(),null) 
	
			ON ACTION "LOOKUP" infield(part_code) 
						LET modu_rec_backorder.part_code = show_item(glob_rec_kandoouser.cmpy_code) 
						DISPLAY BY NAME modu_rec_backorder.part_code 
	
						--NEXT FIELD part_code 
	
			ON ACTION "LOOKUP" infield (ware_code) 
						LET modu_rec_backorder.ware_code = show_ware(glob_rec_kandoouser.cmpy_code) 
						DISPLAY BY NAME modu_rec_backorder.ware_code 
	
						--NEXT FIELD ware_code 
	
			ON CHANGE part_code
				DISPLAY db_product_get_desc_text(UI_OFF,modu_rec_backorder.part_code) TO product.desc_text		

			AFTER FIELD part_code 
				SELECT * 
				INTO modu_rec_product.* 
				FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = modu_rec_backorder.part_code 
	
				IF status = NOTFOUND 
				THEN 
					ERROR " Product NOT found - use window" 
					NEXT FIELD part_code 
				END IF 
	
				DISPLAY BY NAME 
					modu_rec_product.desc_text, 
					modu_rec_backorder.part_code 

			ON CHANGE ware_code
				DISPLAY db_warehouse_get_desc_text(UI_OFF,modu_rec_backorder.ware_code) TO warehouse.desc_text
	
			AFTER INPUT 
	
				IF NOT int_flag THEN
	
					SELECT * 
					INTO modu_rec_prodstatus.* 
					FROM prodstatus 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = modu_rec_backorder.part_code 
					AND ware_code = modu_rec_backorder.ware_code 
	
					IF status = NOTFOUND THEN 
						ERROR " Product NOT found AT warehouse - use window" 
						NEXT FIELD ware_code 
					END IF 
	
					LET l_quant_alloc = 0 
					LET l_quant_unalloc = 0 
	
					DISPLAY BY NAME 
						modu_rec_prodstatus.onhand_qty, 
						modu_rec_backorder.ware_code, 
						modu_rec_prodstatus.reserved_qty 
	
				END IF 
	
		END INPUT
		
		IF int_flag THEN
			LET l_query_text = 
				"SELECT * FROM backorder ", 
				"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
				"ORDER BY alloc_qty" 
	
		ELSE
			#base sql query
			LET l_query_text = 
				"SELECT * FROM backorder ", 
				"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" " 
			
			#build/inject query
			IF modu_rec_backorder.part_code IS NOT NULL THEN
				LET l_query_text =l_query_text CLIPPED, " ",  
					" AND part_code = '",modu_rec_backorder.part_code CLIPPED , "' "
			END IF

			IF modu_rec_backorder.ware_code IS NOT NULL THEN
				LET l_query_text =	l_query_text CLIPPED, " ",  
					" AND ware_code = '",modu_rec_backorder.ware_code CLIPPED, "' " 
			END IF

			LET l_query_text = l_query_text CLIPPED, " ",				 
				" ORDER BY alloc_qty "
				   
		END IF

	ELSE

		LET l_query_text = 
			"SELECT * FROM backorder ", 
			"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
			"ORDER BY alloc_qty" 
	END IF
		
	PREPARE s_backorder FROM l_query_text 
	DECLARE baccur cursor FOR s_backorder

	LET l_idx = 0 
	FOREACH baccur INTO modu_rec_backorder.* 
		LET l_idx = l_idx + 1
		 
		IF modu_rec_backorder.alloc_qty IS NULL	THEN 
			LET modu_rec_backorder.alloc_qty = 0 
		END IF 
		
		IF modu_rec_backorder.req_qty IS NULL THEN 
			LET modu_rec_backorder.req_qty = 0 
		END IF 
		
		LET l_quant_alloc = l_quant_alloc + modu_rec_backorder.alloc_qty 
		LET l_quant_unalloc = l_quant_unalloc + modu_rec_backorder.alloc_qty - modu_rec_backorder.req_qty 
		LET modu_arr_rec_backorder[l_idx].order_num = modu_rec_backorder.order_num 
		LET modu_arr_rec_backorder[l_idx].line_num = modu_rec_backorder.line_num 
		LET modu_arr_rec_backorder[l_idx].alloc_qty = modu_rec_backorder.alloc_qty 
		LET modu_arr_rec_backorder[l_idx].cust_code = modu_rec_backorder.cust_code 
		LET modu_arr_rec_backorder[l_idx].order_date = modu_rec_backorder.order_date 
		LET modu_arr_rec_backorder[l_idx].req_qty = modu_rec_backorder.req_qty 

		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF		
	END FOREACH 
 
	MESSAGE modu_arr_rec_backorder.getSize(), " back order allocations were found"
	DISPLAY l_quant_alloc TO alloc attribute(magenta) 
	DISPLAY l_quant_unalloc TO unalloc attribute(magenta) 

	RETURN modu_arr_rec_backorder
END FUNCTION
###########################################################################
# END FUNCTION db_backorder_get_datasource(p_filter)
###########################################################################


###########################################################################
# FUNCTION scan_backorder()  
#
# 
###########################################################################
FUNCTION scan_backorder() 
	DEFINE l_idx SMALLINT
	DEFINE l_quant_alloc decimal(10,2)
	DEFINE l_quant_unalloc decimal(10,2)
	DEFINE l_pre_alloc decimal(10,2) 
	
	--OPEN WINDOW E404 with FORM "E404" 
	-- CALL windecoration_e("E404") 

	CALL db_backorder_get_datasource(FALSE) RETURNING modu_arr_rec_backorder

	MESSAGE " Change allocation as required " Attribute (yellow) 
	INPUT ARRAY modu_arr_rec_backorder WITHOUT DEFAULTS FROM sr_backorder.* ATTRIBUTE(UNBUFFERED,APPEND ROW = FALSE, INSERT ROW = FALSE, DELETE ROW = FALSE) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","E33","inp-arr-backorder") 
			CALL dialog.setActionHidden("LOOKUP",NOT modu_arr_rec_backorder.getSize())
			CALL dialog.setActionHidden("ACCEPT",NOT modu_arr_rec_backorder.getSize())
				
		ON ACTION "WEB-HELP"  
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "FILTER"
			CALL modu_arr_rec_backorder.clear()
			CALL db_backorder_get_datasource(TRUE) RETURNING modu_arr_rec_backorder
			CALL dialog.setActionHidden("ACCEPT",NOT modu_arr_rec_backorder.getSize())
			
		ON ACTION "REFRESH"
			 CALL windecoration_e("E404") 
			CALL modu_arr_rec_backorder.clear()
			CALL db_backorder_get_datasource(FALSE) RETURNING modu_arr_rec_backorder
			CALL dialog.setActionHidden("ACCEPT",NOT modu_arr_rec_backorder.getSize())
			
		ON ACTION "LOOKUP" 
			IF (l_idx > 0) AND (l_idx <= modu_arr_rec_backorder.getSize()) THEN
				CALL lordshow(
					glob_rec_kandoouser.cmpy_code, 
					modu_arr_rec_backorder[l_idx].cust_code, 
					modu_arr_rec_backorder[l_idx].order_num, 
					modu_func_type) 
			END IF
			
		BEFORE ROW 
			LET l_idx = arr_curr()
			
			IF (l_idx > 0) AND (l_idx <= modu_arr_rec_backorder.getSize()) THEN
				LET l_pre_alloc = modu_arr_rec_backorder[l_idx].alloc_qty
			END IF 

		BEFORE FIELD cust_code 
			IF (l_idx > 0) AND (l_idx <= modu_arr_rec_backorder.getSize()) THEN
				IF l_pre_alloc != modu_arr_rec_backorder[l_idx].alloc_qty THEN 

					UPDATE backorder 
					SET alloc_qty = modu_arr_rec_backorder[l_idx].alloc_qty 
					WHERE backorder.part_code = modu_rec_backorder.part_code 
					AND backorder.ware_code = modu_rec_backorder.ware_code 
					AND backorder.order_num = modu_arr_rec_backorder[l_idx].order_num 
					AND backorder.line_num = modu_arr_rec_backorder[l_idx].line_num 

					IF status < 0 
					THEN 
						CALL errorlog("O33 - Bacallo(Backorder) UPDATE failed") #HuHo:what is Bacallo ??? 
						RETURN 
					END IF 
	
				END IF 
				NEXT FIELD alloc_qty 
			END IF

		AFTER ROW
			IF (l_idx > 0) AND (l_idx <= modu_arr_rec_backorder.getSize()) THEN

				LET l_quant_alloc = l_quant_alloc - l_pre_alloc + modu_arr_rec_backorder[l_idx].alloc_qty 
				LET l_quant_unalloc = l_quant_unalloc + l_pre_alloc - modu_arr_rec_backorder[l_idx].alloc_qty 

				DISPLAY l_quant_alloc TO alloc attribute(magenta) 
				DISPLAY l_quant_unalloc TO unalloc attribute(magenta) 

				IF l_quant_alloc > (modu_rec_prodstatus.onhand_qty - modu_rec_prodstatus.reserved_qty) THEN 
					MESSAGE " Allocated greater THEN available" attribute(yellow) 
				ELSE 
					MESSAGE "" 
				END IF 
			END IF
			
	END INPUT
	 
	LET int_flag = 0 
	LET quit_flag = 0 

END FUNCTION
###########################################################################
# END FUNCTION scan_backorder() 
###########################################################################