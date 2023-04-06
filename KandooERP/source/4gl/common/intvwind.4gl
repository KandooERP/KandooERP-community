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

#   intvwind.4gl - show_interval
#                  Window FUNCTION FOR finding an interval
#                  FUNCTION will RETURN int_num TO calling program
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

###########################################################################
# FUNCTION db_statint_get_datasource(p_filter,p_cmpy,p_filter_text)
#
#
###########################################################################
FUNCTION db_statint_get_datasource(p_filter,p_cmpy,p_filter_text)
	DEFINE p_filter BOOLEAN
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_filter_text STRING
	DEFINE l_rec_statint RECORD LIKE statint.* 
	DEFINE l_arr_statint DYNAMIC ARRAY OF RECORD 
		scroll_flag CHAR(1), 
		int_num LIKE statint.int_num, 
		int_text LIKE statint.int_text, 
		start_date LIKE statint.start_date, 
		end_date LIKE statint.end_date 
	END RECORD 
	DEFINE l_idx SMALLINT 

	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 

	IF p_filter THEN
		MESSAGE kandoomsg2("U",1001,"") #1001 " Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON 
			int_num, 
			int_text, 
			start_date, 
			end_date 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","intvnwind","construct-statint") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_rec_statint.int_num = NULL 
			LET l_where_text = " 1=1 " 
		END IF
	ELSE
		LET l_where_text = " 1=1 "
	END IF 

	MESSAGE kandoomsg2("U",1002,"")	#1002 " Searching database - please wait"

	IF p_filter_text IS NULL THEN 
		LET p_filter_text = " 1=1 "
	END IF
	
	LET l_query_text = 
		"SELECT * FROM statint ", 
		"WHERE cmpy_code = '",p_cmpy,"' ", 
		"AND ",p_filter_text CLIPPED," ", 
		"AND ",l_where_text CLIPPED," ", 
		"ORDER BY year_num, int_num" 

	WHENEVER ERROR CONTINUE 
	OPTIONS SQL interrupt ON 

	PREPARE s_statint FROM l_query_text 
	DECLARE c_statint CURSOR FOR s_statint 

	LET l_idx = 0 
	FOREACH c_statint INTO l_rec_statint.* 
		LET l_idx = l_idx + 1 
		LET l_arr_statint[l_idx].int_num = l_rec_statint.int_num 
		LET l_arr_statint[l_idx].int_text = l_rec_statint.int_text 
		LET l_arr_statint[l_idx].start_date = l_rec_statint.start_date 
		LET l_arr_statint[l_idx].end_date = l_rec_statint.end_date
		
		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF

	END FOREACH 

	MESSAGE kandoomsg2("U",9113,l_idx)#9113 l_idx records selected

	RETURN l_arr_statint			
END FUNCTION
###########################################################################
# END FUNCTION  db_statint_get_datasource(p_filter,p_cmpy,p_filter_text)
###########################################################################


###########################################################################
# FUNCTION show_interval(p_cmpy,p_filter_text)
#
#
###########################################################################
FUNCTION show_interval(p_cmpy,p_filter_text) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_filter_text STRING
	DEFINE l_rec_statint RECORD LIKE statint.* 
	DEFINE l_arr_statint DYNAMIC ARRAY OF RECORD 
		scroll_flag CHAR(1), 
		int_num LIKE statint.int_num, 
		int_text LIKE statint.int_text, 
		start_date LIKE statint.start_date, 
		end_date LIKE statint.end_date 
	END RECORD 
	DEFINE l_idx SMALLINT 

	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING  

	OPEN WINDOW E213 with FORM "E213" 
	CALL windecoration_e("E213")
 
 	CALL db_statint_get_datasource(FALSE,p_cmpy,p_filter_text) RETURNING l_arr_statint

	WHENEVER ERROR stop 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 

	MESSAGE kandoomsg2("U",1006,"") #1006 " ESC on line TO SELECT - F10 TO Add"

	DISPLAY ARRAY l_arr_statint TO sr_statint.* ATTRIBUTE(UNBUFFERED)
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","intvwind","input-arr-statint") 
			CALL dialog.setActionHidden("ACCCEPT",NOT l_arr_statint.getSize())

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
			
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "FILTER"
			CALL l_arr_statint.clear()
			CALL db_statint_get_datasource(TRUE,p_cmpy,p_filter_text) RETURNING l_arr_statint

		ON ACTION "REFRESH"
			CALL windecoration_e("E213")
			CALL l_arr_statint.clear()
			CALL db_statint_get_datasource(FALSE,p_cmpy,p_filter_text) RETURNING l_arr_statint

		BEFORE ROW 
			LET l_idx = arr_curr() 
			LET l_rec_statint.int_num = l_arr_statint[l_idx].int_num 

		ON ACTION "RUN U61" --ON KEY (F10) 
			CALL run_prog("U61","","","","") 

	END DISPLAY 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false
		LET l_rec_statint.int_num = NULL #CANCEL = NULL RETURN 
	END IF 
 
	CLOSE WINDOW E213
	 
	RETURN l_rec_statint.int_num 
END FUNCTION 
###########################################################################
# END FUNCTION show_interval(p_cmpy,p_filter_text)
###########################################################################