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
GLOBALS "../eo/E_EO_GLOBALS.4gl"
GLOBALS "../eo/EC_GROUP_GLOBALS.4gl"  
GLOBALS "../eo/EC4_GLOBALS.4gl" 
###########################################################################
# FUNCTION EC4_main()
#
# EC4 - allows users TO SELECT a salesperson TO which peruse
#       turnover information FROM statistics tables.
###########################################################################
FUNCTION EC4_main()
	DEFINE l_arg_sale_code LIKE salesperson.sale_code 
	DEFER QUIT 
	DEFER INTERRUPT 
	
	CALL setModuleId("EC4")  

	LET l_arg_sale_code = get_url_sale_code()
	IF l_arg_sale_code IS NOT NULL THEN
		CALL sper_turnover(glob_rec_kandoouser.cmpy_code,l_arg_sale_code) 
	ELSE 

		OPEN WINDOW E184 with FORM "E184" 
		 CALL windecoration_e("E184") 
		
		CALL scan_sale() 
		 
		CLOSE WINDOW E184 
	END IF 
END FUNCTION 
###########################################################################
# END FUNCTION EC4_main()
#
# EC4 - allows users TO SELECT a salesperson TO which peruse
#       turnover information FROM statistics tables.
###########################################################################


###########################################################################
# FUNCTION db_salesperson_get_datasource(p_filter)
#
# Query and return data array
###########################################################################
FUNCTION db_salesperson_get_datasource(p_filter)
	DEFINE p_filter BOOLEAN 
	DEFINE l_where_text STRING 
	DEFINE l_query_text STRING 
	DEFINE l_rec_salesperson RECORD LIKE salesperson.* 
	DEFINE l_arr_rec_salesperson DYNAMIC ARRAY OF RECORD --array[100] OF RECORD 
		scroll_flag char(1), 
		sale_code LIKE salesperson.sale_code, 
		name_text LIKE salesperson.name_text, 
		city_text LIKE salesperson.city_text, 
		state_code LIKE salesperson.state_code, 
		mgr_code LIKE salesperson.mgr_code, 
		sale_type_ind LIKE salesperson.sale_type_ind, 
		stat_flag char(1) 
	END RECORD 
	DEFINE l_idx SMALLINT 

	IF p_filter THEN
		CLEAR FORM 
		 
		MESSAGE kandoomsg2("E",1001,"") 
		CONSTRUCT BY NAME l_where_text ON 
			sale_code, 
			name_text, 
			city_text, 
			state_code, 
			mgr_code, 
			sale_type_ind 
	
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","EC4","construct-sale_code-1") -- albo kd-502 
	
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
	
		END CONSTRUCT 
	
		IF int_flag OR quit_flag THEN 
			LET int_flag = FALSE 
			LET quit_flag = FALSE 
			LET l_where_text = " 1=1 "
		END IF 
	ELSE 
		LET l_where_text = " 1=1 "
	END IF
	
	MESSAGE kandoomsg2("E",1002,"")		#1002 Searching database -please wait

	LET l_query_text = 
		"SELECT * FROM salesperson ", 
		"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND ",l_where_text clipped," ", 
		"ORDER BY 1,2" 
	PREPARE s_salesperson FROM l_query_text 
	DECLARE c_salesperson cursor FOR s_salesperson 

	LET l_idx = 0 
	FOREACH c_salesperson INTO l_rec_salesperson.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_salesperson[l_idx].sale_code = l_rec_salesperson.sale_code 
		LET l_arr_rec_salesperson[l_idx].name_text = l_rec_salesperson.name_text 

		IF l_rec_salesperson.city_text IS NOT NULL THEN 
			LET l_arr_rec_salesperson[l_idx].city_text = l_rec_salesperson.city_text 
		ELSE 
			LET l_arr_rec_salesperson[l_idx].city_text = l_rec_salesperson.addr2_text 
		END IF 

		LET l_arr_rec_salesperson[l_idx].state_code = l_rec_salesperson.state_code 
		LET l_arr_rec_salesperson[l_idx].mgr_code = l_rec_salesperson.mgr_code 
		LET l_arr_rec_salesperson[l_idx].sale_type_ind = l_rec_salesperson.sale_type_ind 

		SELECT unique 1 FROM statsper 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND sale_code = l_rec_salesperson.sale_code 
		AND year_num = glob_rec_statparms.year_num 
		AND type_code = glob_rec_statparms.mth_type_code 
		IF status = 0 THEN 
			LET l_arr_rec_salesperson[l_idx].stat_flag = "*" 
		ELSE 
			LET l_arr_rec_salesperson[l_idx].stat_flag = NULL 
		END IF 

		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF
	END FOREACH 

	RETURN l_arr_rec_salesperson 
END FUNCTION 
###########################################################################
# END FUNCTION db_salesperson_get_datasource(p_filter)
#
#
###########################################################################


###########################################################################
# FUNCTION scan_sale() 
#
#
###########################################################################
FUNCTION scan_sale() 
	DEFINE l_rec_salesperson RECORD LIKE salesperson.* 
	DEFINE l_arr_rec_salesperson DYNAMIC ARRAY OF RECORD --array[100] OF RECORD 
		scroll_flag char(1), 
		sale_code LIKE salesperson.sale_code, 
		name_text LIKE salesperson.name_text, 
		city_text LIKE salesperson.city_text, 
		state_code LIKE salesperson.state_code, 
		mgr_code LIKE salesperson.mgr_code, 
		sale_type_ind LIKE salesperson.sale_type_ind, 
		stat_flag char(1) 
	END RECORD 
	DEFINE l_idx SMALLINT 
 
	CALL db_salesperson_get_datasource(FALSE) RETURNING l_arr_rec_salesperson

	MESSAGE kandoomsg2("E",1082,"") #Salesperson Monthly Turnover - RETURN TO View
	DISPLAY ARRAY l_arr_rec_salesperson TO sr_salesperson.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","EC4","input-arr-l_arr_rec_salesperson-1") 
 			CALL dialog.setActionHidden("ACCEPT",NOT l_arr_rec_salesperson.getSize())
 			
		ON ACTION "FILTER"
			CALL l_arr_rec_salesperson.clear()
			CALL db_salesperson_get_datasource(TRUE) RETURNING l_arr_rec_salesperson		
			CALL dialog.setActionHidden("ACCEPT",NOT l_arr_rec_salesperson.getSize())

		ON ACTION "REFRESH"
			 CALL windecoration_e("E184")
			CALL l_arr_rec_salesperson.clear()
			CALL db_salesperson_get_datasource(FALSE) RETURNING l_arr_rec_salesperson	
			CALL dialog.setActionHidden("ACCEPT",NOT l_arr_rec_salesperson.getSize())
				
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION ("ACCEPT","DOUBLECLICK") 
			IF (l_idx > 0) AND (l_idx <= l_arr_rec_salesperson.getSize()) THEN
				CALL sper_turnover(glob_rec_kandoouser.cmpy_code,l_arr_rec_salesperson[l_idx].sale_code)
			END IF 

		BEFORE ROW 
			LET l_idx = arr_curr() 

	END DISPLAY 

	LET int_flag = FALSE 
	LET quit_flag = FALSE 
END FUNCTION 
###########################################################################
# FUNCTION scan_sale() 
#
#
###########################################################################