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
# FUNCTION db_disbhead_get_datasource(p_filter,p_cmpy,p_filter_text)
#
#
###########################################################################
FUNCTION db_disbhead_get_datasource(p_filter,p_cmpy,p_filter_text)
	DEFINE p_filter BOOLEAN
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_filter_text CHAR(300)
	DEFINE l_rec_disbhead RECORD LIKE disbhead.* 
	DEFINE l_arr_rec_disbhead DYNAMIC ARRAY OF #array[100] OF 
				RECORD 
					scroll_flag CHAR(1), 
					disb_code LIKE disbhead.disb_code, 
					desc_text LIKE disbhead.desc_text 
				END RECORD 
	DEFINE l_idx SMALLINT 
	DEFINE l_query_text STRING
	DEFINE l_where_text STRING 

	IF p_filter_text IS NULL THEN 
		LET p_filter_text = "1=1" 
	END IF 

	IF p_filter THEN
 
		MESSAGE kandoomsg2("U",1001,"")	#1001 " Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON disb_code, desc_text 
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","disbwind","construct-disbhead") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_rec_disbhead.disb_code = NULL 
			LET l_where_text = " 1=1 "
		END IF
	ELSE
		LET l_where_text = " 1=1 "
	END IF 

	MESSAGE kandoomsg2("U",1002,"")	#1002 " Searching database - please wait"
	LET l_query_text = 
		"SELECT * FROM disbhead ", 
		"WHERE cmpy_code = '",p_cmpy,"' ", 
		"AND ",l_where_text CLIPPED," ", 
		"AND ",p_filter_text CLIPPED," ", 
		"ORDER BY disb_code" 

	WHENEVER ERROR CONTINUE 

	OPTIONS SQL interrupt ON 
	PREPARE s_disbhead FROM l_query_text 
	DECLARE c_disbhead CURSOR FOR s_disbhead 

	LET l_idx = 0 
	FOREACH c_disbhead INTO l_rec_disbhead.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_disbhead[l_idx].disb_code = l_rec_disbhead.disb_code 
		LET l_arr_rec_disbhead[l_idx].desc_text = l_rec_disbhead.desc_text 

		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF

	END FOREACH 

	MESSAGE kandoomsg2("U",9113,l_idx)		#U9113 l_idx records selected

	RETURN l_arr_rec_disbhead
END FUNCTION
###########################################################################
# END FUNCTION db_disbhead_get_datasource(p_filter,p_cmpy,p_filter_text)
###########################################################################


###########################################################################
# FUNCTION show_disb(p_cmpy,p_filter_text)
#
#   disbwind.4gl - show_disb
#                  Window FUNCTION FOR finding a disbhead record
#                  returns disb_code
###########################################################################
FUNCTION show_disb(p_cmpy,p_filter_text) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_filter_text CHAR(300)
	DEFINE l_rec_disbhead RECORD LIKE disbhead.* 
	DEFINE l_arr_rec_disbhead DYNAMIC ARRAY OF #array[100] OF 
				RECORD 
					scroll_flag CHAR(1), 
					disb_code LIKE disbhead.disb_code, 
					desc_text LIKE disbhead.desc_text 
				END RECORD 
	DEFINE l_idx SMALLINT 
	
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

	OPEN WINDOW G466 with FORM "G466" 
	CALL winDecoration_g("G466") 

	CALL db_disbhead_get_datasource(FALSE,p_cmpy,p_filter_text) RETURNING l_arr_rec_disbhead 

	MESSAGE kandoomsg2("U",1006,"")	#1006 " ESC on line TO SELECT - F10 TO Add"
	DISPLAY ARRAY l_arr_rec_disbhead TO sr_disbhead.* 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","disbwind","input-arr-disbhead") 

		BEFORE ROW 
			LET l_idx = arr_curr()
			LET l_rec_disbhead.disb_code = l_arr_rec_disbhead[l_idx].disb_code

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "FILTER"
			CALL l_arr_rec_disbhead.clear()
			CALL db_disbhead_get_datasource(TRUE,p_cmpy,p_filter_text) RETURNING l_arr_rec_disbhead

		ON ACTION "REFRESH"
			CALL l_arr_rec_disbhead.clear()
			CALL db_disbhead_get_datasource(FALSE,p_cmpy,p_filter_text) RETURNING l_arr_rec_disbhead
		
		ON ACTION "RUN-G31" --ON KEY (F10) 
			CALL run_prog("G31","","","","") 

	END DISPLAY 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false
		LET l_rec_disbhead.disb_code = NULL 
	END IF 

	CLOSE WINDOW G466 

	RETURN l_rec_disbhead.disb_code 
END FUNCTION
###########################################################################
# END FUNCTION show_disb(p_cmpy,p_filter_text)
###########################################################################