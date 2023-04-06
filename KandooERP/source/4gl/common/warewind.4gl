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


###########################################################################
# FUNCTION db_warehouse_get_datasource(p_filter,p_cmpy)
#
#
###########################################################################
FUNCTION db_warehouse_get_datasource(p_filter,p_cmpy)
	DEFINE p_filter BOOLEAN
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE l_rec_warehouse RECORD LIKE warehouse.* 
	DEFINE l_arr_rec_warehouse DYNAMIC ARRAY OF RECORD 
		scroll_flag CHAR(1), 
		ware_code LIKE warehouse.ware_code, 
		desc_text LIKE warehouse.desc_text 
	END RECORD 
	DEFINE l_where_text STRING
	DEFINE l_idx SMALLINT 
	DEFINE l_query_text STRING
		
	IF p_filter THEN
			MESSAGE kandoomsg2("U",1001,"")			#1001 " Enter Selection Criteria - ESC TO Continue"
			CONSTRUCT BY NAME l_where_text ON ware_code, desc_text 
				BEFORE CONSTRUCT 
					CALL publish_toolbar("kandoo","warewind","construct-warehouse") 

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
			END CONSTRUCT 

			IF int_flag OR quit_flag THEN 
				LET int_flag = FALSE 
				LET quit_flag = FALSE 
				LET l_rec_warehouse.ware_code = NULL 
				LET l_where_text = " 1=1 "
			END IF 
		ELSE
			LET l_where_text = " 1=1 "
		END IF

		MESSAGE kandoomsg2("U",1002,"")		#1002 " Searching database - please wait"

		LET l_query_text = 
			"SELECT * FROM warehouse ", 
			"WHERE cmpy_code = '",p_cmpy,"' ", 
			"AND ",l_where_text CLIPPED," ", 
			"ORDER BY ware_code" 

		WHENEVER ERROR CONTINUE 

		PREPARE s_warehouse FROM l_query_text 
		DECLARE c_warehouse CURSOR FOR s_warehouse 
		LET l_idx = 0 

		FOREACH c_warehouse INTO l_rec_warehouse.* 
			LET l_idx = l_idx + 1 
			LET l_arr_rec_warehouse[l_idx].ware_code = l_rec_warehouse.ware_code 
			LET l_arr_rec_warehouse[l_idx].desc_text = l_rec_warehouse.desc_text

			IF l_idx = glob_rec_settings.maxListArraySize THEN
				MESSAGE kandoomsg2("U",6100,l_idx)
				EXIT FOREACH
			END IF				 
		END FOREACH 

		MESSAGE kandoomsg2("U",9113,l_idx)	#U9113 l_idx records selected
	
	RETURN l_arr_rec_warehouse
END FUNCTION
###########################################################################
# END FUNCTION db_warehouse_get_datasource(p_filter,p_cmpy)
###########################################################################


###########################################################################
# FUNCTION show_ware(p_cmpy)
#	RETURN l_rec_warehouse.ware_code
#
#     warewind.4gl - show_ware
#                    window FUNCTION FOR finding warehouse records
#                    returns ware_code
###########################################################################
FUNCTION show_ware(p_cmpy) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE l_rec_warehouse RECORD LIKE warehouse.* 
	DEFINE l_arr_rec_warehouse DYNAMIC ARRAY OF RECORD 
		scroll_flag CHAR(1), 
		ware_code LIKE warehouse.ware_code, 
		desc_text LIKE warehouse.desc_text 
	END RECORD 
	DEFINE l_idx SMALLINT 
	DEFINE l_query_text STRING
	DEFINE l_where_text STRING 

--	DEFINE l_withquery SMALLINT 

	OPEN WINDOW I134 with FORM "I134" 
	CALL winDecoration_i("I134") 

 	CALL db_warehouse_get_datasource(FALSE,p_cmpy) RETURNING l_arr_rec_warehouse  
	MESSAGE kandoomsg2("U",1006,"")		#1006 " ESC on line TO SELECT - F10 TO Add"

	IF l_arr_rec_warehouse.getSize() = 0 THEN
		CALL fgl_winmessage("No Warehouses found","No Warehouses found","INFO")
	END IF 

	DISPLAY ARRAY l_arr_rec_warehouse TO sr_warehouse.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","warewind","display-arr-warehouse") 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			IF l_idx > 0 THEN
				LET l_rec_warehouse.ware_code = l_arr_rec_warehouse[l_idx].ware_code
			END IF 

		ON ACTION "FILTER" 
			CALL l_arr_rec_warehouse.clear()
			CALL db_warehouse_get_datasource(TRUE,p_cmpy) RETURNING l_arr_rec_warehouse 
			
		ON ACTION "REFRESH" 
			CALL winDecoration_i("I134")
			CALL l_arr_rec_warehouse.clear()
			CALL db_warehouse_get_datasource(FALSE,p_cmpy) RETURNING l_arr_rec_warehouse 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "WAREHOUSE-MAINTENANCE" --ON KEY (F10) 
			CALL run_prog("IZ3","","","","") 

	END DISPLAY 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE
	END IF 

 

	CLOSE WINDOW I134 

	RETURN l_rec_warehouse.ware_code 
END FUNCTION 
###########################################################################
# END FUNCTION show_ware(p_cmpy)
###########################################################################