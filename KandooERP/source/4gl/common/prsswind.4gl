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
# FUNCTION prsswind allows the user TO view stock STATUS AT different
# warehouses
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
###########################################################################
# FUNCTION prsswind(p_cmpy,p_part_code)
#
#
###########################################################################
FUNCTION prsswind(p_cmpy,p_part_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_part_code LIKE product.part_code 
	DEFINE l_rec_opparms RECORD LIKE opparms.* 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_rec_class RECORD LIKE class.* 
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.* 
	DEFINE l_arr_rec_prodstatus DYNAMIC ARRAY OF  
		RECORD 
			scroll_flag CHAR(1), 
			part_code LIKE prodstatus.part_code, 
			ware_code LIKE prodstatus.ware_code, 
			onhand_qty LIKE prodstatus.onhand_qty, 
			reserved_qty LIKE prodstatus.reserved_qty, 
			back_qty LIKE prodstatus.back_qty, 
			onord_qty LIKE prodstatus.onord_qty, 
			avail LIKE prodstatus.onord_qty 
		END RECORD 
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 
	DEFINE l_match_part CHAR(30) 
	DEFINE l_available LIKE prodstatus.onord_qty 
	DEFINE l_count SMALLINT 
	DEFINE l_idx SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

		OPEN WINDOW I109 with FORM "I109" 
		CALL windecoration_i("I109") 

		SELECT sell_uom_code, class_code 
		INTO l_rec_product.sell_uom_code, l_rec_product.class_code 
		FROM product 
		WHERE cmpy_code = p_cmpy 
		AND part_code = p_part_code 
		IF get_kandoooption_feature_state(TRAN_TYPE_INVOICE_IN,"FS") = "Y" THEN 
			SELECT * INTO l_rec_class.* FROM class 
			WHERE cmpy_code = p_cmpy 
			AND class_code = l_rec_product.class_code 
			IF status = notfound 
			OR l_rec_class.stock_level_ind = "1" THEN 
				LET l_match_part = p_part_code 
			ELSE 
				LET l_match_part = p_part_code clipped, "*" 
			END IF 
		ELSE 
			LET l_match_part = p_part_code 
		END IF 

		CALL db_opparms_get_rec(UI_OFF,"1") RETURNING l_rec_opparms.*
		IF l_rec_opparms.key_num IS NULL AND l_rec_opparms.cmpy_code IS NULL THEN 
			LET l_rec_opparms.cal_available_flag = "N" 
		END IF 
	
		LET l_where_text = NULL 

		SELECT count(*) INTO l_count FROM prodstatus 
		WHERE cmpy_code = p_cmpy 
		AND part_code matches l_match_part
		 
		IF l_count > 11 THEN 
			ERROR kandoomsg2("U",1001,"") #1001 Enter Selection Criteria; OK TO Continue.
			DISPLAY p_part_code TO part_code 

			CONSTRUCT BY NAME l_where_text ON 
				ware_code, 
				onhand_qty, 
				reserved_qty, 
				back_qty, 
				onord_qty 

				BEFORE CONSTRUCT 
					CALL publish_toolbar("kandoo","prsswind","construct-prodstatus") 

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
			END CONSTRUCT 

			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
				CLOSE WINDOW i109 
				RETURN 
			END IF 
		END IF 
		IF l_where_text IS NULL THEN 
			LET l_where_text = "1=1" 
		END IF 
		
		MESSAGE kandoomsg2("U",1002,"") #1002 Searching Database; Please Wait.
		
		LET l_query_text = "SELECT * FROM prodstatus ", 
		" WHERE cmpy_code = \"",p_cmpy," \"", 
		" AND part_code matches \"",l_match_part," \"", 
		" AND ",l_where_text clipped, 
		" ORDER BY part_code, ware_code" 
		PREPARE s_prodstatus FROM l_query_text 
		DECLARE c_prodstatus CURSOR FOR s_prodstatus
		 
		LET l_idx = 0 
		FOREACH c_prodstatus INTO l_rec_prodstatus.* 
			LET l_idx = l_idx + 1 
			LET l_arr_rec_prodstatus[l_idx].part_code = l_rec_prodstatus.part_code 
			LET l_arr_rec_prodstatus[l_idx].ware_code = l_rec_prodstatus.ware_code 
			LET l_arr_rec_prodstatus[l_idx].onhand_qty = l_rec_prodstatus.onhand_qty 
			LET l_arr_rec_prodstatus[l_idx].onord_qty = l_rec_prodstatus.onord_qty 
			LET l_arr_rec_prodstatus[l_idx].reserved_qty = l_rec_prodstatus.reserved_qty 
			LET l_arr_rec_prodstatus[l_idx].back_qty = l_rec_prodstatus.back_qty 

			IF l_rec_opparms.cal_available_flag = "N" THEN 
				LET l_arr_rec_prodstatus[l_idx].avail = l_rec_prodstatus.onhand_qty 
				- l_rec_prodstatus.reserved_qty 
				- l_rec_prodstatus.back_qty 
			ELSE 
				LET l_arr_rec_prodstatus[l_idx].avail = l_rec_prodstatus.onhand_qty	- l_rec_prodstatus.reserved_qty 
			END IF 
		END FOREACH 
		
		IF l_idx = 0 THEN 
			ERROR kandoomsg2("I",9082,"") 		#9082 No product/warehouse rows satsified the selection criteria.
			CLOSE WINDOW I109 
			RETURN 
		END IF 

		DISPLAY BY NAME l_rec_product.sell_uom_code 

		LET l_query_text = 
			"SELECT sum(onhand_qty), sum(reserved_qty), ", 
			" sum(back_qty), sum(onord_qty) ", 
			" FROM prodstatus ", 
			" WHERE cmpy_code = \"",p_cmpy," \"", 
			" AND part_code matches \"",l_match_part," \"", 
			" AND ",l_where_text clipped 

		PREPARE s1_prodstatus FROM l_query_text 
		DECLARE c1_prodstatus CURSOR FOR s1_prodstatus 
		OPEN c1_prodstatus 
		FETCH c1_prodstatus INTO 
			l_rec_prodstatus.onhand_qty, 
			l_rec_prodstatus.reserved_qty, 
			l_rec_prodstatus.back_qty, 
			l_rec_prodstatus.onord_qty 

		IF l_rec_opparms.cal_available_flag = "N" THEN 
			LET l_available = l_rec_prodstatus.onhand_qty - l_rec_prodstatus.reserved_qty - l_rec_prodstatus.back_qty 
		ELSE 
			LET l_available = l_rec_prodstatus.onhand_qty - l_rec_prodstatus.reserved_qty 
		END IF 

		DISPLAY 
			l_rec_prodstatus.onhand_qty, 
			l_rec_prodstatus.reserved_qty, 
			l_rec_prodstatus.back_qty, 
			l_rec_prodstatus.onord_qty, 
			l_available 
		TO 
			tot_onhand_qty, 
			tot_reserved_qty, 
			tot_back_qty, 
			tot_onord_qty, 
			tot_avail_qty attribute(yellow)
			
		LET l_msgresp=kandoomsg("I",1009,"") #1009 F3/F4 TO Page Fwd/Bwd;  F5 Stock In Transit;  Enter FOR Part Movement.

		DISPLAY ARRAY l_arr_rec_prodstatus TO sr_prodstatus.* 
			BEFORE DISPLAY
				CALL publish_toolbar("kandoo","prsswind","input-arr-prodstatus") 
 				CALL dialog.setActionHidden("ACCEPT",NOT l_arr_rec_prodstatus.getSize())
 				CALL dialog.setActionHidden("STOCK TRANSIT",NOT l_arr_rec_prodstatus.getSize())
 				 				
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			ON ACTION "STOCK TRANSIT" --ON KEY (F5)
				IF (l_idx > 0) AND (l_idx <= l_arr_rec_prodstatus.getSize()) THEN
					CALL show_stock_transit(p_cmpy,l_arr_rec_prodstatus[l_idx].part_code,	l_arr_rec_prodstatus[l_idx].ware_code) 
				END IF
				
			BEFORE ROW 
				LET l_idx = arr_curr() 

			ON ACTION ("ACCEPT","DOUBLECLICK") --BEFORE FIELD part_code
				IF (l_idx > 0) AND (l_idx <= l_arr_rec_prodstatus.getSize()) THEN 
					CALL prmowind(p_cmpy,l_arr_rec_prodstatus[l_idx].ware_code, l_arr_rec_prodstatus[l_idx].part_code)
				END IF 

		END DISPLAY 

		CLOSE WINDOW I109
		 
		LET int_flag = false 
		LET quit_flag = false 
END FUNCTION 
###########################################################################
# END FUNCTION prsswind(p_cmpy,p_part_code)
###########################################################################