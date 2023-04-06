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
#        wulocnwin.4gl - show_user_loc
#                        window FUNCTION FOR finding location records
#                        returns locn_code
###########################################################################

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_userDataTypes.4gl"

#######################################################################
# FUNCTION show_user_loc(p_cmpy)
#
#
#######################################################################
FUNCTION db_location_filter_datasource(p_filter,p_cmpy) 
	DEFINE p_filter BOOLEAN 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_location RECORD LIKE location.* 
	DEFINE l_arr_rec_location DYNAMIC ARRAY OF t_rec_location_lc_dt_with_scrollflag 
	#	DEFINE l_arr_rec_location array[100] of record
	#         scroll_flag CHAR(1),
	#         locn_code LIKE location.locn_code,
	#         desc_text LIKE location.desc_text
	#      END RECORD
	DEFINE l_idx SMALLINT 
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 

	IF p_cmpy IS NULL THEN 
		LET p_cmpy = glob_rec_kandoouser.cmpy_code 
	END IF 

	IF p_filter THEN 
		CLEAR FORM 
		MESSAGE kandoomsg2("U",1001,"") 	#1001 " Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON 
			locn_code, 
			desc_text 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","wulocnwind","construct-location") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = FALSE 
			LET quit_flag = FALSE 
			LET l_rec_location.locn_code = NULL 
			LET l_where_text = " 1=1 " 
		END IF 
	ELSE 
		LET l_where_text = " 1=1 " 
	END IF 


	MESSAGE kandoomsg2("U",1002,"") 	#1002 " Searching database - please wait"
	LET l_query_text = 
		"SELECT * FROM location ", 
		"WHERE cmpy_code = '",p_cmpy,"' ", 
		"AND ",l_where_text CLIPPED," ", 
		"ORDER BY locn_code" 
	WHENEVER ERROR CONTINUE 

	OPTIONS SQL interrupt ON 
	PREPARE s_location FROM l_query_text 
	DECLARE c_location CURSOR FOR s_location 

	LET l_idx = 0 
	FOREACH c_location INTO l_rec_location.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_location[l_idx].locn_code = l_rec_location.locn_code 
		LET l_arr_rec_location[l_idx].desc_text = l_rec_location.desc_text 

		IF l_idx = glob_rec_settings.maxListArraySize THEN
			ERROR kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF	
	END FOREACH 

	RETURN l_arr_rec_location 
END FUNCTION 
#######################################################################
# END FUNCTION show_user_loc(p_cmpy)
#######################################################################


#######################################################################
# FUNCTION show_user_loc(p_cmpy)
#
#
#######################################################################
FUNCTION show_user_loc(p_cmpy) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE l_rec_location RECORD LIKE location.* 
	DEFINE l_arr_rec_location DYNAMIC ARRAY OF t_rec_location_lc_dt_with_scrollflag 
	#	DEFINE l_arr_rec_location array[100] of record
	#         scroll_flag CHAR(1),
	#         locn_code LIKE location.locn_code,
	#         desc_text LIKE location.desc_text
	#      END RECORD
	DEFINE l_idx SMALLINT 
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 
	DEFINE l_arg_run STRING 

	OPEN WINDOW W119 with FORM "W119" 
	CALL windecoration_w("W119") 

	CALL db_location_filter_datasource(FALSE,p_cmpy) RETURNING l_arr_rec_location 

	IF l_arr_rec_location.getlength() < 1 THEN 
		ERROR "KandooERP is may be not setup correctly OR you are working with a new company with an unfinished setup. You need to setup default locations" 
	END IF 
	MESSAGE kandoomsg2("U",9113,l_arr_rec_location.getLength())#U9113 l_idx records selected

	WHENEVER ERROR stop 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 
	MESSAGE kandoomsg2("U",1006,"")	#1006 " ESC on line TO SELECT - F10 TO Add"

	DISPLAY ARRAY l_arr_rec_location TO sr_location.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","wulocnwin","input-arr-location") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "FILTER" 
			CALL l_arr_rec_location.clear()
			CALL db_location_filter_datasource(TRUE,p_cmpy) RETURNING l_arr_rec_location 

		ON ACTION "REFRESH" 
			CALL windecoration_w("W119") 
			CALL l_arr_rec_location.clear()
			CALL db_location_filter_datasource(TRUE,p_cmpy) RETURNING l_arr_rec_location 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			LET l_rec_location.locn_code = l_arr_rec_location[l_idx].locn_code 

		ON KEY (F10) 
			LET l_arg_run = "COMPANY_CODE=", trim(p_cmpy) #trim(get_url_company_code()) 
			CALL run_prog("WZ5",l_arg_run,"","","") 

		#AFTER INSERT
		#	INSERT INTO location VALUES(l_rec_location[l_idx].*) #brutal without any exception handler ? @eric @todo

--		AFTER DISPLAY
--			LET l_rec_location.locn_code = l_arr_rec_location[l_idx].locn_code

	END DISPLAY 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
	END IF 

	CLOSE WINDOW W119 

	RETURN l_rec_location.locn_code 
END FUNCTION 
#######################################################################
# END FUNCTION show_user_loc(p_cmpy)
#######################################################################


#######################################################################
# FUNCTION db_location_new()
#
#
#######################################################################
FUNCTION db_location_new() 

END FUNCTION 
#######################################################################
# END FUNCTION db_location_new()
#######################################################################