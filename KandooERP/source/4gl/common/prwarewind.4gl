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
}

GLOBALS "../common/glob_GLOBALS.4gl" 

#Control-B lookup SCREEN FOR valid warehouses FOR a product
#FUNCTION wioth same name bu one param in warewind.4gl
FUNCTION show_ware_part_code(p_cmpy,p_part_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_part_code LIKE product.part_code
	DEFINE l_formname CHAR(15) 
	DEFINE l_idx SMALLINT 
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.* 
	DEFINE l_rec_warehouse RECORD LIKE warehouse.*
	DEFINE l_arr_warehouse DYNAMIC ARRAY OF RECORD 
		ware_code LIKE warehouse.ware_code, 
		desc_text LIKE warehouse.desc_text 
	END RECORD 

	DECLARE warecurs CURSOR FOR 
	SELECT * 
	FROM prodstatus 
	WHERE cmpy_code = p_cmpy 
	AND part_code = p_part_code 

	LET l_idx = 0 

	FOREACH warecurs INTO l_rec_prodstatus.* 
		SELECT * 
		INTO l_rec_warehouse.* 
		FROM warehouse 
		WHERE cmpy_code = p_cmpy 
		AND ware_code = l_rec_prodstatus.ware_code 

		LET l_idx = l_idx + 1 
		LET l_arr_warehouse[l_idx].desc_text = l_rec_warehouse.desc_text 
		LET l_arr_warehouse[l_idx].ware_code = l_rec_prodstatus.ware_code 
	END FOREACH 

	IF l_idx = 0 THEN 
		ERROR kandoomsg2("M", 9505, "") # ERROR "This product has no valid warehouses"
		RETURN "" 
	END IF 

	OPEN WINDOW w_m166 with FORM "M166" 
	CALL windecoration_m("M166") -- albo kd-758 

	MESSAGE "Select OR Exit"
	DISPLAY ARRAY l_arr_warehouse TO sr_warehouse.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","prwarewind","display-arr-warehouse") 
			DISPLAY p_part_code TO part_code 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
			
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END DISPLAY 

	LET l_idx = arr_curr() 

	CLOSE WINDOW w_m166 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		LET l_arr_warehouse[l_idx].ware_code = NULL 
	END IF 

	RETURN l_arr_warehouse[l_idx].ware_code 

END FUNCTION 
