{
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

	Source code beautified by beautify.pl on 2020-01-02 10:35:29	$Id: $
}



#
{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module - prsswind.4gl
#
# Purpose - Displays incomplete shipment lines which have has stock
#           receipted against them.
#
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 


##################################################################################################
# FUNCTION show_stock_transit(l_cmpy_code,l_part_code,l_ware_code)
#
# Displays incomplete shipment lines which have has stock
#           receipted against them.
##################################################################################################
FUNCTION show_stock_transit(l_cmpy_code,l_part_code,l_ware_code) 
	DEFINE l_cmpy_code LIKE company.cmpy_code 
	DEFINE l_part_code LIKE product.part_code 
	DEFINE l_ware_code LIKE warehouse.ware_code 

	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.* 
	DEFINE l_rec_shiphead RECORD LIKE shiphead.* 
	DEFINE l_rec_shipdetl RECORD LIKE shipdetl.* 
	DEFINE l_part_desc_text LIKE product.desc_text 
	DEFINE l_ware_desc_text LIKE warehouse.desc_text 
	DEFINE l_uom_code LIKE product.stock_uom_code 
	DEFINE l_cal_available_flag LIKE opparms.cal_available_flag 
	DEFINE l_avail_qty LIKE prodstatus.onhand_qty 
	DEFINE l_favail_qty LIKE prodstatus.onhand_qty 
	DEFINE l_ship_type_code LIKE shiphead.ship_type_code 
	DEFINE l_vend_code LIKE shiphead.vend_code 
	DEFINE l_in_transit LIKE shipdetl.ship_rec_qty 
	DEFINE l_query_text CHAR(400) 
	DEFINE l_arr_rec_stock_transit DYNAMIC ARRAY OF # array[100] OF RECORD 
		RECORD 
			scroll_flag CHAR(1), 
			ship_code LIKE shipdetl.ship_code, 
			ship_type_code LIKE shiphead.ship_type_code, 
			vend_code LIKE shiphead.vend_code, 
			source_doc_num LIKE shipdetl.source_doc_num, 
			line_num LIKE shipdetl.line_num, 
			ship_rec_qty LIKE shipdetl.ship_rec_qty, 
			ship_inv_qty LIKE shipdetl.ship_inv_qty, 
			landed_cost LIKE shipdetl.landed_cost 
		END RECORD 
	DEFINE l_idx SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

		OPEN WINDOW i682 with FORM "I682" 
		CALL windecoration_i("I682") 

		LET l_msgresp = kandoomsg("U",1002,"") 
		#1002 Searching Database;  Please wait.
		SELECT desc_text, stock_uom_code INTO l_part_desc_text, l_uom_code 
		FROM product 
		WHERE cmpy_code = l_cmpy_code 
		AND part_code = l_part_code 

		IF sqlca.sqlcode = NOTFOUND THEN 
			LET l_msgresp = kandoomsg("I",5010,"") 
			#5010 Logic Error:  Product Code does NOT exist.
			CLOSE WINDOW i682 
			RETURN 
		END IF 

		SELECT desc_text INTO l_ware_desc_text FROM warehouse 
		WHERE cmpy_code = l_cmpy_code 
		AND ware_code = l_ware_code 
		IF sqlca.sqlcode = NOTFOUND THEN 
			LET l_msgresp = kandoomsg("I",5011,"") 
			#5011 Logic Error:  Warehouse Code does NOT exist.
			CLOSE WINDOW i682 
			RETURN 
		END IF 
		SELECT * INTO l_rec_prodstatus.* FROM prodstatus 
		WHERE cmpy_code = l_cmpy_code 
		AND part_code = l_part_code 
		AND ware_code = l_ware_code 

		IF sqlca.sqlcode = NOTFOUND THEN 
			LET l_msgresp = kandoomsg("A",9126,"") 
			#9156 Product NOT stocked AT this location.
			CLOSE WINDOW i682 
			RETURN 
		END IF 

		SELECT cal_available_flag INTO l_cal_available_flag FROM opparms 
		WHERE cmpy_code = l_cmpy_code 
		AND key_num = "1" 

		IF sqlca.sqlcode = NOTFOUND THEN 
			LET l_cal_available_flag = "N" 
		END IF 

		IF l_cal_available_flag = "N" THEN 
			LET l_avail_qty = l_rec_prodstatus.onhand_qty 
			- l_rec_prodstatus.reserved_qty 
			- l_rec_prodstatus.back_qty 
		ELSE 
			LET l_avail_qty = l_rec_prodstatus.onhand_qty 
			- l_rec_prodstatus.reserved_qty 
		END IF 

		# DISPLAY the header information
		DISPLAY l_part_code, 
		l_part_desc_text, 
		l_ware_code, 
		l_ware_desc_text, 
		l_uom_code, 
		l_uom_code, 
		l_rec_prodstatus.onhand_qty, 
		l_rec_prodstatus.reserved_qty, 
		l_rec_prodstatus.back_qty, 
		l_avail_qty, 
		l_avail_qty, 
		l_rec_prodstatus.onord_qty 
		TO prodstatus.part_code, 
		product.desc_text, 
		prodstatus.ware_code, 
		warehouse.desc_text, 
		sr_stock[1].stock_uom_code, 
		sr_stock[2].stock_uom_code, 
		prodstatus.onhand_qty, 
		prodstatus.reserved_qty, 
		prodstatus.back_qty, 
		sr_avail[1].avail_qty, 
		sr_avail[2].avail_qty, 
		prodstatus.onord_qty 

		LET l_query_text = "SELECT shipdetl.* ", 
		"FROM shipdetl, shiphead ", 
		"WHERE shiphead.cmpy_code = '",l_cmpy_code,"' ", 
		"AND shipdetl.cmpy_code = shiphead.cmpy_code ", 
		"AND shipdetl.ship_code = shiphead.ship_code ", 
		"AND shipdetl.part_code = '",l_part_code,"' ", 
		"AND shiphead.ware_code = '",l_ware_code,"' ", 
		"AND ship_rec_qty != 0 ", 
		"AND shiphead.finalised_flag != 'Y' ", 
		"ORDER BY shipdetl.ship_code, shipdetl.line_num" 
		PREPARE s_shipdetl FROM l_query_text 
		DECLARE c_shipdetl CURSOR FOR s_shipdetl 

		LET l_idx = 0 
		LET l_in_transit = 0 

		FOREACH c_shipdetl INTO l_rec_shipdetl.* 
			LET l_idx = l_idx + 1 
			SELECT ship_type_code, vend_code INTO l_ship_type_code, l_vend_code 
			FROM shiphead 
			WHERE cmpy_code = l_cmpy_code 
			AND ship_code = l_rec_shipdetl.ship_code 
			IF sqlca.sqlcode = NOTFOUND THEN 
				LET l_arr_rec_stock_transit[l_idx].ship_type_code = NULL 
				LET l_arr_rec_stock_transit[l_idx].vend_code = NULL 
			END IF 
			LET l_arr_rec_stock_transit[l_idx].ship_code = l_rec_shipdetl.ship_code 
			LET l_arr_rec_stock_transit[l_idx].ship_type_code = l_ship_type_code 
			LET l_arr_rec_stock_transit[l_idx].vend_code = l_vend_code 
			LET l_arr_rec_stock_transit[l_idx].source_doc_num = l_rec_shipdetl.source_doc_num 
			LET l_arr_rec_stock_transit[l_idx].line_num = l_rec_shipdetl.line_num 
			LET l_arr_rec_stock_transit[l_idx].ship_rec_qty = l_rec_shipdetl.ship_rec_qty 
			LET l_arr_rec_stock_transit[l_idx].ship_inv_qty = l_rec_shipdetl.ship_inv_qty 
			LET l_arr_rec_stock_transit[l_idx].landed_cost = l_rec_shipdetl.landed_cost 
			IF l_idx = 100 THEN 
				EXIT FOREACH 
			END IF 
		END FOREACH 

		SELECT sum(ship_rec_qty) INTO l_in_transit 
		FROM shipdetl, shiphead 
		WHERE shiphead.cmpy_code = l_cmpy_code 
		AND shipdetl.cmpy_code = l_cmpy_code 
		AND shipdetl.ship_code = shiphead.ship_code 
		AND shipdetl.part_code = l_part_code 
		AND shiphead.ware_code = l_ware_code 
		AND ship_rec_qty != 0 
		AND shiphead.finalised_flag != "Y" 
		IF l_in_transit IS NULL 
		OR l_in_transit = " " THEN 
			LET l_in_transit = 0 
		END IF 
		LET l_favail_qty = l_avail_qty 
		+ l_rec_prodstatus.onord_qty 
		+ l_rec_prodstatus.forward_qty 
		DISPLAY l_in_transit, 
		l_favail_qty 
		TO in_transit, 
		favail_qty 

		IF l_idx = 100 THEN 
			LET l_msgresp = kandoomsg("U",9100,l_idx) 
			#9021 First 100 entries Selected Only"
		ELSE 
			LET l_msgresp = kandoomsg("U",9113,l_idx) 
			#9113 l_idx records selected.
			IF l_idx = 0 THEN 
				LET l_idx = 1 
				INITIALIZE l_arr_rec_stock_transit[1].* TO NULL 
			END IF 
		END IF 

		#   CALL set_count(l_idx)
		LET l_msgresp = kandoomsg("U",1008,"") 
		#1008 F3/F4 TO Page Fwd/Bwd;  OK TO Continue.
		INPUT ARRAY l_arr_rec_stock_transit WITHOUT DEFAULTS FROM sr_stock_transit.* 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","prsitwind","input-arr-stock_transit") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 


			BEFORE ROW 
				LET l_idx = arr_curr() 
				#         LET scrn = scr_line()
				#         IF l_arr_rec_stock_transit[l_idx].ship_code IS NOT NULL THEN
				#            DISPLAY l_arr_rec_stock_transit[l_idx].* TO sr_stock_transit[scrn].*
				#
				#         END IF

			AFTER FIELD scroll_flag 
				LET l_idx = arr_curr() 
				#         LET scrn = scr_line()
				LET l_arr_rec_stock_transit[l_idx].scroll_flag = NULL 
				IF (fgl_lastkey() = fgl_keyval("down") 
				OR fgl_lastkey() = fgl_keyval("right")) 
				AND arr_curr() >= arr_count() THEN 
					LET l_msgresp = kandoomsg("W",9001,"") 
					#9001 There are no more rows in the direction you are going.
					NEXT FIELD scroll_flag 
				END IF 

				#      AFTER ROW
				#         DISPLAY l_arr_rec_stock_transit[l_idx].* TO sr_stock_transit[scrn].*


		END INPUT 

		LET int_flag = false 
		LET quit_flag = false 

		CLOSE WINDOW i682 

END FUNCTION 		# show_stock_transit
