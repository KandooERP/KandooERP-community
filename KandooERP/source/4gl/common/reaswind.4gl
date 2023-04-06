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
#   reaswind.4gl - show_credreas
#                  Window FUNCTION FOR finding a credreas records
#                  FUNCTION will RETURN reason_code TO calling program
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

###########################################################################
# FUNCTION db_credreas_get_datasource(p_filter,p_filter_where2_text,p_cmpy)
#   reaswind.4gl - show_credreas
#                  Window FUNCTION FOR finding a credreas records
#                  FUNCTION will RETURN reason_code TO calling program
###########################################################################
FUNCTION db_credreas_get_datasource(p_filter,p_filter_where2_text,p_cmpy)
	DEFINE p_filter BOOLEAN
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_filter_where2_text STRING
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_credreas RECORD LIKE credreas.* 
	DEFINE l_arr_credreas DYNAMIC ARRAY OF RECORD 
			scroll_flag CHAR(1), 
			reason_code LIKE credreas.reason_code, 
			reason_text LIKE credreas.reason_text 
		END RECORD 
	DEFINE l_idx SMALLINT 
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 

	IF p_filter_where2_text IS NULL THEN 
		LET p_filter_where2_text = "1=1" 
	END IF 

	IF p_filter THEN

		CLEAR FORM 
		MESSAGE kandoomsg2("U",1001,"")#1001 " Enter Selection Criteria - ESC TO Continue"

		CONSTRUCT BY NAME l_where_text ON 
			reason_code, 
			reason_text 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","reaswind","construct-credreas") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_rec_credreas.reason_code = NULL 
			LET l_where_text = " 1=1 " 
		END IF 
	ELSE 
		LET l_where_text = " 1=1 "
	END IF
	
		MESSAGE kandoomsg2("U",1002,"")	#1002 " Searching database - please wait"
		LET l_query_text = 
			"SELECT * FROM credreas ", 
			"WHERE cmpy_code = \"",p_cmpy,"\" ", 
			"AND ",l_where_text CLIPPED," ", 
			"AND ",p_filter_where2_text CLIPPED," ", 
			"ORDER BY reason_code" 
		
		WHENEVER ERROR CONTINUE 
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
		OPTIONS SQL interrupt ON 

		PREPARE s_credreas FROM l_query_text 
		DECLARE c_credreas CURSOR FOR s_credreas 
		LET l_idx = 0 

		FOREACH c_credreas INTO l_rec_credreas.* 
			LET l_idx = l_idx + 1 
			LET l_arr_credreas[l_idx].reason_code = l_rec_credreas.reason_code 
			LET l_arr_credreas[l_idx].reason_text = l_rec_credreas.reason_text

			IF l_idx = glob_rec_settings.maxListArraySize THEN
				MESSAGE kandoomsg2("U",6100,l_idx)
				EXIT FOREACH
			END IF				 
		END FOREACH 
		
		MESSAGE kandoomsg2("U",9113,l_idx)		#9113 " l_idx records selected "

	RETURN l_arr_credreas
END FUNCTION
###########################################################################
# FUNCTION db_credreas_get_datasource(p_filter,p_filter_where2_text,p_cmpy)
###########################################################################


###########################################################################
# FUNCTION show_credreas(p_cmpy,p_filter_where2_text)
#
#
###########################################################################
FUNCTION show_credreas(p_cmpy,p_filter_where2_text,p_def_reason_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_filter_where2_text STRING
	DEFINE p_def_reason_code LIKE credreas.reason_code
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_credreas RECORD LIKE credreas.* 
	DEFINE l_arr_credreas DYNAMIC ARRAY OF RECORD 
			scroll_flag CHAR(1), 
			reason_code LIKE credreas.reason_code, 
			reason_text LIKE credreas.reason_text 
		END RECORD 
	DEFINE l_idx SMALLINT 
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 

	IF p_filter_where2_text IS NULL THEN 
		LET p_filter_where2_text = "1=1" 
	END IF 

	OPEN WINDOW A601 with FORM "A601" 
	CALL windecoration_a("A601") 

	CALL db_credreas_get_datasource(FALSE,p_filter_where2_text,p_cmpy) RETURNING l_arr_credreas

	MESSAGE kandoomsg2("U",1006,"")	#1006 " ESC on line TO SELECT - F10 TO Add"
	DISPLAY ARRAY l_arr_credreas TO sr_credreas.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","reaswind","input-arr-credreas") 
			CALL dialog.setActionHidden("ACCEPT",NOT l_arr_credreas.getSize())

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "FILTER"
			CALL l_arr_credreas.clear()
			CALL db_credreas_get_datasource(FALSE,p_filter_where2_text,p_cmpy) RETURNING l_arr_credreas
						
		ON ACTION "REFRESH"
			CALL windecoration_a("A601")
			CALL l_arr_credreas.clear()
			CALL db_credreas_get_datasource(FALSE,p_filter_where2_text,p_cmpy) RETURNING l_arr_credreas
		
		ON ACTION "RUN AZR" --ON KEY (F10) 
			CALL run_prog("AZR","","","","")
			CALL windecoration_a("A601")
			CALL l_arr_credreas.clear()
			CALL db_credreas_get_datasource(FALSE,p_filter_where2_text,p_cmpy) RETURNING l_arr_credreas
			 
			CALL dialog.setActionHidden("ACCEPT",NOT l_arr_credreas.getSize())
			
		ON ACTION ("ACCEPT","DOUBLECLICK") #BEFORE FIELD reason_code
			IF (l_idx > 0) AND (l_idx <= l_arr_credreas.getSize()) THEN
				LET l_rec_credreas.reason_code = l_arr_credreas[l_idx].reason_code
			END IF 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			LET l_rec_credreas.reason_code = l_arr_credreas[l_idx].reason_code

		AFTER DISPLAY
			IF (l_idx > 0) AND (l_idx <= l_arr_credreas.getSize()) THEN
				LET l_rec_credreas.reason_code = l_arr_credreas[l_idx].reason_code
			END IF 

	END DISPLAY
	 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		LET l_rec_credreas.reason_code = p_def_reason_code
	END IF 

	CLOSE WINDOW A601 

	RETURN l_rec_credreas.reason_code 
END FUNCTION 
###########################################################################
# END FUNCTION show_credreas(p_cmpy,p_filter_where2_text)
###########################################################################