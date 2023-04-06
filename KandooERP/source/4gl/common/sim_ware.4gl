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

	Source code beautified by beautify.pl on 2020-01-02 10:35:35	$Id: $
}

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 


############################################################
# FUNCTION sim_warehouse( p_cmpy_code, p_rec_product, p_rec_new_warehouse)
#
# sim_warehouse - This program allows the user TO SET up a
#                 prodstatus RECORD FOR a warehouse
#                 that IS similar TO another warehouse.
############################################################
FUNCTION sim_warehouse(p_cmpy_code,p_rec_product,p_rec_new_warehouse) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_rec_product RECORD LIKE product.* 
	DEFINE p_rec_new_warehouse LIKE prodstatus.ware_code 
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.* 
	DEFINE l_cnt INTEGER 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET l_rec_prodstatus.cmpy_code = p_cmpy_code 
	LET l_rec_prodstatus.part_code = p_rec_product.part_code 
	LET l_rec_prodstatus.ware_code = p_rec_new_warehouse 
	IF NOT ware_exists(l_rec_prodstatus.*) THEN 
		LET l_msgresp = kandoomsg("U",7001,"Warehouse") 
		#7001 Logic Error: Warehouse RECORD does NOT exist
		RETURN l_rec_prodstatus.ware_code 
	END IF 
	IF status_exists(l_rec_prodstatus.*) THEN 
		LET l_msgresp = kandoomsg("I",7004,"") 
		#7001 " Product Status Already Exist FOR this Warehouse"
		RETURN l_rec_prodstatus.ware_code 
	END IF 

	OPEN WINDOW i155 with FORM "I155" 
	CALL windecoration_i("I155") -- albo kd-758 
	LET l_msgresp = kandoomsg("I",1030,"") 
	#1030 Enter Warehouse Code; OK TO Continue

	INPUT BY NAME l_rec_prodstatus.ware_code 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","sim_ware","input-prodstatus") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield (ware_code) 
			LET l_rec_prodstatus.ware_code = show_ware(p_cmpy_code) 
			DISPLAY BY NAME l_rec_prodstatus.ware_code 

		AFTER FIELD ware_code 
			IF NOT status_exists(l_rec_prodstatus.*) THEN 
				IF ware_exists(l_rec_prodstatus.*) THEN 
					LET l_msgresp = kandoomsg("A",9148,"") 
					#9148 Product STATUS FOR selected warehouse NOT found.
				ELSE 
					LET l_msgresp = kandoomsg("U",9105,"") 
					#9105 RECORD NOT found - Try Window
				END IF 
				NEXT FIELD ware_code 
			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		LET l_rec_prodstatus.ware_code = NULL 
	ELSE 
		SELECT prodstatus.* 
		INTO l_rec_prodstatus.* 
		FROM prodstatus 
		WHERE cmpy_code = l_rec_prodstatus.cmpy_code 
		AND part_code = l_rec_prodstatus.part_code 
		AND ware_code = l_rec_prodstatus.ware_code 
		LET l_rec_prodstatus.ware_code = p_rec_new_warehouse 
		LET l_rec_prodstatus.onhand_qty = 0 
		LET l_rec_prodstatus.onord_qty = 0 
		LET l_rec_prodstatus.reserved_qty = 0 
		LET l_rec_prodstatus.back_qty = 0 
		LET l_rec_prodstatus.transit_qty = 0 
		LET l_rec_prodstatus.forward_qty = 0 
		LET l_rec_prodstatus.bin1_text = " " 
		LET l_rec_prodstatus.bin2_text = " " 
		LET l_rec_prodstatus.bin3_text = " " 
		LET l_rec_prodstatus.last_sale_date = today 
		LET l_rec_prodstatus.status_date = today 
		LET l_rec_prodstatus.last_receipt_date = today 
		LET l_rec_prodstatus.seq_num = 1 
		LET l_rec_prodstatus.phys_count_qty = 0 
		LET l_rec_prodstatus.last_stcktake_date = 31/12/1899 
		LET l_rec_prodstatus.stockturn_qty = 0 
		INSERT INTO prodstatus VALUES (l_rec_prodstatus.*) 
	END IF 

	CLOSE WINDOW i155 

	RETURN l_rec_prodstatus.ware_code 
END FUNCTION 


############################################################
# FUNCTION ware_exists(p_rec_prodstatus)
#
#
############################################################
FUNCTION ware_exists(p_rec_prodstatus) 
	DEFINE p_rec_prodstatus RECORD LIKE prodstatus.* 
	DEFINE l_cnt INTEGER 

	IF p_rec_prodstatus.ware_code IS NULL THEN 
		RETURN false 
	END IF 

	SELECT count(*) 
	INTO l_cnt 
	FROM warehouse 
	WHERE cmpy_code = p_rec_prodstatus.cmpy_code 
	AND ware_code = p_rec_prodstatus.ware_code 

	RETURN l_cnt 
END FUNCTION 


############################################################
# FUNCTION status_exists(p_rec_prodstatus)
#
#
############################################################
FUNCTION status_exists(p_rec_prodstatus) 
	DEFINE p_rec_prodstatus RECORD LIKE prodstatus.* 
	DEFINE l_cnt INTEGER 

	SELECT count(*) 
	INTO l_cnt 
	FROM prodstatus 
	WHERE cmpy_code = p_rec_prodstatus.cmpy_code 
	AND part_code = p_rec_prodstatus.part_code 
	AND ware_code = p_rec_prodstatus.ware_code 
	RETURN l_cnt 
END FUNCTION 


