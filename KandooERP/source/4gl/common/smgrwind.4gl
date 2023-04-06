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
#   smgrwind.4gl - show_salesmgr
#                  Window FUNCTION FOR finding salesmgr records
#                  FUNCTION will RETURN mgr_code TO calling program
###########################################################################

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl"  

###########################################################################
# FUNCTION db_salesmgr_get_datasource(p_filter,p_cmpy,p_filter_text)
#
#
###########################################################################
FUNCTION db_salesmgr_get_datasource(p_filter,p_cmpy,p_filter_text)
	DEFINE p_filter BOOLEAN
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_filter_text CHAR(300)
	DEFINE l_msgresp LIKE language.yes_flag
	DEFINE l_rec_salesmgr RECORD LIKE salesmgr.* 
	DEFINE l_arr_salesmgr DYNAMIC ARRAY OF RECORD
		scroll_flag CHAR(1), 
		mgr_code LIKE salesmgr.mgr_code, 
		name_text LIKE salesmgr.name_text 
	END RECORD
	DEFINE l_idx SMALLINT
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 

	IF p_filter_text IS NULL THEN 
		LET p_filter_text = " 1=1 " 
	END IF 

	IF p_filter THEN

		CLEAR FORM 
		MESSAGE kandoomsg2("U",1001,"") #1001 " Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON 
			mgr_code, 
			name_text 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","smgrwind","construct-salesmgr") 
			
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_rec_salesmgr.mgr_code = NULL
			LET l_where_text = " 1=1 " 
		END IF 
	ELSE
		LET l_where_text = " 1=1 "
	END IF
		
		MESSAGE kandoomsg2("U",1002,"")	#1002 " Searching database - please wait"
		LET l_query_text = 
			"SELECT * FROM salesmgr ", 
			"WHERE cmpy_code = \"",p_cmpy,"\" ", 
			"AND ",l_where_text CLIPPED," ", 
			"AND ",p_filter_text CLIPPED," ", 
			"ORDER BY mgr_code" 
		
--		WHENEVER ERROR CONTINUE 
--		OPTIONS SQL interrupt ON 
		
		PREPARE s_salesmgr FROM l_query_text 
		DECLARE c_salesmgr CURSOR FOR s_salesmgr 
		
		LET l_idx = 0 
		FOREACH c_salesmgr INTO l_rec_salesmgr.* 
			LET l_idx = l_idx + 1 
			LET l_arr_salesmgr[l_idx].mgr_code = l_rec_salesmgr.mgr_code 
			LET l_arr_salesmgr[l_idx].name_text = l_rec_salesmgr.name_text 

			IF l_idx = glob_rec_settings.maxListArraySize THEN
				MESSAGE kandoomsg2("U",6100,l_idx)
				EXIT FOREACH
			END IF

		END FOREACH 
		
		MESSAGE kandoomsg2("U",9113,l_idx)	#9113 "l_idx records selected"
		
--		WHENEVER ERROR stop 
--		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 

	
END FUNCTION
###########################################################################
# END FUNCTION db_salesmgr_get_datasource(p_filter,p_cmpy,p_filter_text)
###########################################################################


###########################################################################
# FUNCTION show_salesmgr(p_cmpy,p_filter_text)
#
#
###########################################################################
FUNCTION show_salesmgr(p_cmpy,p_filter_text) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_filter_text CHAR(300)
	DEFINE l_msgresp LIKE language.yes_flag
	DEFINE l_rec_salesmgr RECORD LIKE salesmgr.* 
	DEFINE l_arr_salesmgr DYNAMIC ARRAY OF RECORD
		scroll_flag CHAR(1), 
		mgr_code LIKE salesmgr.mgr_code, 
		name_text LIKE salesmgr.name_text 
	END RECORD
	DEFINE l_idx SMALLINT
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 


	OPEN WINDOW A612 with FORM "A612" 
	CALL windecoration_a("A612") 

	CALL db_salesmgr_get_datasource(FALSE,p_cmpy,p_filter_text) RETURNING l_arr_salesmgr

	MESSAGE kandoomsg2("U",1006,"")	#1006 " ESC on line TO SELECT - F10 TO Add"
	DISPLAY ARRAY l_arr_salesmgr TO sr_salesmgr.* ATTRIBUTE(UNBUFFERED)
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","salesmgr","input-arr-salesmgr") 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			IF (l_idx > 0) AND (l_idx <= l_arr_salesmgr.getSize()) THEN
				LET l_rec_salesmgr.mgr_code = l_arr_salesmgr[l_idx].mgr_code
			ELSE
				LET l_rec_salesmgr.mgr_code = NULL
			END IF

		AFTER ROW
			#nothing

		AFTER DISPLAY
			#nothing

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "FILTER"
			CALL l_arr_salesmgr.clear()
			CALL db_salesmgr_get_datasource(TRUE,p_cmpy,p_filter_text) RETURNING l_arr_salesmgr

		ON ACTION "REFRESH"
			CALL windecoration_a("A612") 
			CALL l_arr_salesmgr.clear()
			CALL db_salesmgr_get_datasource(FALSE,p_cmpy,p_filter_text) RETURNING l_arr_salesmgr
		
		ON ACTION "F10-AZM" 
			CALL run_prog("AZM","","","","") 
 
	END DISPLAY
	 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false
		LET l_rec_salesmgr.mgr_code = NULL 
	END IF
		 
	CLOSE WINDOW A612 
	
	RETURN l_rec_salesmgr.mgr_code 
END FUNCTION 
###########################################################################
# END FUNCTION show_salesmgr(p_cmpy,p_filter_text)
###########################################################################