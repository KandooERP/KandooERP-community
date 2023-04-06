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
# common/orhdwind.4gl
# common/orddfunc.4gl
###########################################################################

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../eo/E_EO_GLOBALS.4gl"
GLOBALS "../eo/E1_GROUP_GLOBALS.4gl"
GLOBALS "../eo/E1A_GLOBALS.4gl"
###########################################################################
# MODULE Scope Variables
###########################################################################
###########################################################################
# FUNCTION E1A_main()
#
# E1A allows the user TO view backorder allocations
###########################################################################
FUNCTION E1A_main() 
	DEFINE l_prodstatus RECORD LIKE prodstatus.* 
	
	DEFER QUIT 
	DEFER INTERRUPT 
	
	CALL setModuleId("E1A") 

	OPEN WINDOW E416 with FORM "E416" 
	 CALL windecoration_e("E416") -- albo kd-755 

	LET l_prodstatus.part_code = get_url_product_part_code()  
	LET l_prodstatus.ware_code = get_url_warehouse_code() 
	IF (l_prodstatus.part_code IS NOT NULL) AND (l_prodstatus.ware_code IS NOT NULL) THEN
		CALL db_prodstatus_get_rec(UI_OFF,l_prodstatus.ware_code,l_prodstatus.part_code) RETURNING l_prodstatus.*
		CALL set_url_child_run_once_only(TRUE) 
	ELSE
		CALL enter_part_ware_code() RETURNING l_prodstatus.ware_code,l_prodstatus.part_code
		CALL db_prodstatus_get_rec(UI_ON,l_prodstatus.ware_code,l_prodstatus.part_code) RETURNING l_prodstatus.*  
	END IF 
	
	CALL scan_orderdetl(l_prodstatus.ware_code,l_prodstatus.part_code)
	
	CLOSE WINDOW E416 
END FUNCTION 
###########################################################################
# FUNCTION scanner() 
###########################################################################


###########################################################################
# FUNCTION enter_part_ware_code() 
#
# 
###########################################################################
FUNCTION enter_part_ware_code() 
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.*
	DEFINE l_desc_text LIKE product.desc_text 

	CLEAR FORM 
	MESSAGE kandoomsg2("U",1020,"Product") 
	INPUT BY NAME l_rec_prodstatus.part_code, l_rec_prodstatus.ware_code WITHOUT DEFAULTS ATTRIBUTE(UNBUFFERED) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","E1A","input-l_rec_prodstatus-1") -- albo kd-502 


		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield (part_code) 
					LET l_rec_prodstatus.part_code = show_part(glob_rec_kandoouser.cmpy_code,"") 
					NEXT FIELD part_code 
					
		ON ACTION "LOOKUP" infield (ware_code) 
					LET l_rec_prodstatus.ware_code = show_ware(glob_rec_kandoouser.cmpy_code) 
					NEXT FIELD ware_code 


		ON CHANGE part_code
			DISPLAY db_product_get_desc_text(UI_ON,l_rec_prodstatus.part_code) TO part_code
		
		ON CHANGE ware_code
			DISPLAY	db_warehouse_get_desc_text(UI_OFF,l_rec_prodstatus.ware_code) TO ware_code 
			
		AFTER FIELD part_code 
			IF l_rec_prodstatus.part_code IS NOT NULL THEN
				LET l_desc_text = db_product_get_desc_text(UI_ON,l_rec_prodstatus.part_code)
				DISPLAY l_desc_text TO product.desc_text
			END IF
			 {
			IF l_rec_prodstatus.part_code IS NOT NULL THEN 
				IF valid_part(glob_rec_kandoouser.cmpy_code,l_rec_prodstatus.part_code,"", 
				TRUE,3,0,"","","") THEN 
					SELECT desc_text INTO l_desc_text 
					FROM product 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = l_rec_prodstatus.part_code 
					DISPLAY l_desc_text TO product.desc_text 

				ELSE 
					NEXT FIELD part_code 
				END IF 
			END IF 
}

		AFTER INPUT
			IF not(int_flag OR quit_flag) THEN 

				IF l_rec_prodstatus.part_code IS NULL THEN
					ERROR "Product Code is required"
					NEXT FIELD PART_CODE
				END IF
				IF l_rec_prodstatus.ware_code IS NULL THEN
					ERROR "Warehouse Code is required"
					NEXT FIELD WARE_CODE
				END IF
				  
				IF l_rec_prodstatus.part_code IS NOT NULL THEN 
					IF NOT valid_part(glob_rec_kandoouser.cmpy_code,l_rec_prodstatus.part_code,l_rec_prodstatus.ware_code,TRUE,3,0,"","","") THEN 
						ERROR "Invalid Part"
						NEXT FIELD part_code 
					END IF 
				END IF 
	
				IF NOT db_warehouse_pk_exists(UI_ON,l_rec_prodstatus.ware_code) THEN
					ERROR "Warehouse not found"
					NEXT FIELD ware_code
				END IF
				
				IF NOT valid_part(glob_rec_kandoouser.cmpy_code,l_rec_prodstatus.part_code,l_rec_prodstatus.ware_code,TRUE,3,0,"","","") THEN
					CONTINUE INPUT
				END IF
			END IF		
			
--		IF not(int_flag OR quit_flag) THEN 
--			IF valid_part(glob_rec_kandoouser.cmpy_code,l_rec_prodstatus.part_code,l_rec_prodstatus.ware_code,TRUE,3,0,"","","") THEN 
--			ELSE 
--				CONTINUE INPUT 
--			END IF 
--		END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN NULL, NULL 
	ELSE 
		RETURN l_rec_prodstatus.ware_code, l_rec_prodstatus.part_code
	END IF 
END FUNCTION 
###########################################################################
# END FUNCTION enter_part_ware_code()  
###########################################################################


###########################################################################
# FUNCTION scan_orderdetl(l_rec_prodstatus) 
#
# 
###########################################################################
FUNCTION scan_orderdetl(p_ware_code,p_part_code)
	DEFINE p_ware_code LIKE warehouse.ware_code
	DEFINE p_part_code LIKE product.part_code
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.* 
	DEFINE l_rec_orderdetl RECORD LIKE orderdetl.* 
	DEFINE l_arr_rec_orderdetl DYNAMIC ARRAY OF RECORD  
		order_date LIKE orderhead.order_date, 
		cust_code LIKE orderdetl.cust_code, 
		order_num LIKE orderdetl.order_num, 
		line_num LIKE orderdetl.line_num, 
		order_qty LIKE orderdetl.order_qty, 
		sched_qty LIKE orderdetl.sched_qty, 
		back_qty LIKE orderdetl.back_qty, 
		reqd_qty LIKE orderdetl.order_qty 
	END RECORD 
	DEFINE l_chk_ordr_qty LIKE orderdetl.order_qty 
	DEFINE l_chk_back_qty LIKE orderdetl.order_qty 
	DEFINE l_chk_resv_qty LIKE orderdetl.order_qty 
	DEFINE l_chk_reqd_qty LIKE orderdetl.order_qty 
	DEFINE l_idx SMALLINT 
	DEFINE l_msg STRING
	
	LET l_rec_prodstatus.ware_code = p_ware_code
	LET l_rec_prodstatus.part_code = p_part_code
		
	LET l_msg = "Product with \npart code ", trim(l_rec_prodstatus.part_code), "\nwareshouse ", trim(l_rec_prodstatus.ware_code), "\ndoes not exist!"
			
	IF (l_rec_prodstatus.part_code IS NULL) OR (l_rec_prodstatus.ware_code IS NULL) THEN
		RETURN FALSE #EXIT PROGRAM / user pressed cancel in query/input
	ELSE
		CALL db_prodstatus_get_rec(UI_OFF,l_rec_prodstatus.ware_code,l_rec_prodstatus.part_code) RETURNING l_rec_prodstatus.*
		IF l_rec_prodstatus.part_code IS NULL THEN #record not found
 			CALL fgl_winmessage("Error",l_msg,"ERROR")
 			RETURN FALSE
 		END IF
	END IF
	
	LET l_idx = 0 
	LET l_chk_ordr_qty = 0 
	LET l_chk_back_qty = 0 
	LET l_chk_resv_qty = 0 
	LET l_chk_reqd_qty = 0 

	MESSAGE kandoomsg2("U",1002,"") #1002 Searching Database; Please Wait

{	SELECT * INTO l_rec_prodstatus.* 
	FROM prodstatus 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = l_rec_prodstatus.part_code 
	AND ware_code = l_rec_prodstatus.ware_code 
}

	LET l_rec_prodstatus.avg_qty = l_rec_prodstatus.onhand_qty - l_rec_prodstatus.reserved_qty - l_rec_prodstatus.back_qty 

	DISPLAY BY NAME 
		l_rec_prodstatus.last_sale_date, 
		l_rec_prodstatus.onhand_qty, 
		l_rec_prodstatus.reserved_qty, 
		l_rec_prodstatus.back_qty, 
		l_rec_prodstatus.avg_qty 

	WHENEVER ERROR CONTINUE 
 
	DECLARE c_orderdetl cursor FOR 
	SELECT * FROM orderdetl 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = l_rec_prodstatus.part_code 
	AND ware_code = l_rec_prodstatus.ware_code 
	AND order_qty > 0 
	AND order_qty > inv_qty 
	ORDER BY part_code,ware_code,order_num,line_num 

	FOREACH c_orderdetl INTO l_rec_orderdetl.* 
		LET l_idx = l_idx + 1 
		SELECT order_date INTO l_arr_rec_orderdetl[l_idx].order_date 
		FROM orderhead 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND order_num = l_rec_orderdetl.order_num 

		IF l_rec_orderdetl.back_qty IS NULL THEN 
			LET l_rec_orderdetl.back_qty = 0 
		END IF 

		IF l_rec_orderdetl.sched_qty IS NULL THEN 
			LET l_rec_orderdetl.sched_qty = 0 
		END IF 

		IF l_rec_orderdetl.picked_qty IS NULL THEN 
			LET l_rec_orderdetl.picked_qty = 0 
		END IF 

		IF l_rec_orderdetl.conf_qty IS NULL THEN 
			LET l_rec_orderdetl.conf_qty = 0 
		END IF 

		LET l_arr_rec_orderdetl[l_idx].order_num = l_rec_orderdetl.order_num 
		LET l_arr_rec_orderdetl[l_idx].line_num = l_rec_orderdetl.line_num 
		LET l_arr_rec_orderdetl[l_idx].cust_code = l_rec_orderdetl.cust_code 
		LET l_arr_rec_orderdetl[l_idx].order_qty = l_rec_orderdetl.order_qty 
		LET l_arr_rec_orderdetl[l_idx].back_qty = l_rec_orderdetl.back_qty 
		LET l_arr_rec_orderdetl[l_idx].sched_qty = l_rec_orderdetl.sched_qty 	+ l_rec_orderdetl.picked_qty 	+ l_rec_orderdetl.conf_qty 
		IF l_rec_orderdetl.inv_qty < l_rec_orderdetl.order_qty THEN 
			LET l_arr_rec_orderdetl[l_idx].reqd_qty = l_rec_orderdetl.order_qty 	- l_rec_orderdetl.inv_qty 
		END IF 

		LET l_chk_ordr_qty = l_chk_ordr_qty + l_arr_rec_orderdetl[l_idx].order_qty 
		LET l_chk_back_qty = l_chk_back_qty + l_arr_rec_orderdetl[l_idx].back_qty 
		LET l_chk_resv_qty = l_chk_resv_qty + l_arr_rec_orderdetl[l_idx].sched_qty 
		LET l_chk_reqd_qty = l_chk_reqd_qty + l_arr_rec_orderdetl[l_idx].reqd_qty 

	END FOREACH 

	MESSAGE kandoomsg2("U",9113,l_idx)	#9113 "l_idx records selected"

	DISPLAY l_chk_ordr_qty TO t_order_qty 
	DISPLAY l_chk_resv_qty TO t_sched_qty 
	DISPLAY l_chk_back_qty TO t_back_qty 
	DISPLAY l_chk_reqd_qty TO t_reqd_qty 

	MESSAGE kandoomsg2("E",1007,"") 

	DISPLAY ARRAY l_arr_rec_orderdetl TO sr_orderdetl.* ATTRIBUTE(UNBUFFERED)
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","E1A","display-arr-orderdetl")
			CALL dialog.setActionHidden("ACCEPT",TRUE) 
 			CALL dialog.setActionHidden("EDIT",NOT l_arr_rec_orderdetl.getSize())
 			
			IF l_arr_rec_orderdetl.getSize() = 0 THEN
				CALL dialog.setActionHidden("EDIT",TRUE)
				CALL dialog.setActionHidden("DOUBLECLICKEDIT",TRUE)				
			END IF
			
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION ("EDIT","ACCEPT","DOUBLECLICK") --ON KEY (tab) 
			IF (l_idx > 0) AND (l_idx <= l_arr_rec_orderdetl.getSize()) THEN 
				IF l_arr_rec_orderdetl[l_idx].cust_code IS NOT NULL THEN 
					CALL lordshow(
						glob_rec_kandoouser.cmpy_code,
						l_arr_rec_orderdetl[l_idx].cust_code,
						l_arr_rec_orderdetl[l_idx].order_num,
						"") 
				END IF
			END IF 
		
		BEFORE ROW
			LET l_idx = arr_curr()

	END DISPLAY 

END FUNCTION
###########################################################################
# END FUNCTION scan_orderdetl(l_rec_prodstatus)  
###########################################################################