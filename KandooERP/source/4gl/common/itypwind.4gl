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
# FUNCTION db_stattype_filter_datasource(p_filter)
#
#
###########################################################################
FUNCTION db_stattype_filter_datasource(p_filter) 
	DEFINE p_filter BOOLEAN 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_stattype RECORD LIKE stattype.* 
	DEFINE l_idx SMALLINT 
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 
	DEFINE r_arr_stattype DYNAMIC ARRAY OF #array[100] OF RECORD 
		RECORD 
			scroll_flag CHAR(1), 
			type_code LIKE stattype.type_code, 
			type_text LIKE stattype.type_text 
		END RECORD 

		IF p_filter THEN 
			CLEAR FORM 
			LET l_msgresp = kandoomsg("U",1001,"")#1001 " Enter Selection Criteria - ESC TO Continue"
			CONSTRUCT BY NAME l_where_text ON 
				type_code, 
				type_text 

				BEFORE CONSTRUCT 
					CALL publish_toolbar("kandoo","itypwind","construct-stattype") 

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

			END CONSTRUCT 

			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
				LET l_rec_stattype.type_code = NULL 
				LET l_where_text = " 1=1 " 
			END IF 

		ELSE 
			LET l_where_text = " 1=1 " 
		END IF 

		LET l_msgresp = kandoomsg("U",1002,"")	#1002 " Searching database - please wait"
		LET l_query_text = 
			"SELECT * FROM stattype ", 
			"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
			"AND ",l_where_text clipped," ", 
			"ORDER BY type_code" 

		WHENEVER ERROR CONTINUE 
		OPTIONS SQL interrupt ON 

		PREPARE s_stattype FROM l_query_text 
		DECLARE c_stattype CURSOR FOR s_stattype 

		LET l_idx = 0 
		FOREACH c_stattype INTO l_rec_stattype.* 
			LET l_idx = l_idx + 1 
			LET r_arr_stattype[l_idx].type_code = l_rec_stattype.type_code 
			LET r_arr_stattype[l_idx].type_text = l_rec_stattype.type_text 
			#         IF l_idx = 100 THEN
			#            LET l_msgresp = kandoomsg("U",6100,l_idx)
			#            EXIT FOREACH
			#         END IF
			IF l_idx = glob_rec_settings.maxListArraySize THEN
				MESSAGE kandoomsg2("U",6100,l_idx)
				EXIT FOREACH
			END IF	
		END FOREACH 
		LET l_msgresp = kandoomsg("U",9113,l_idx) 	#U9113 l_idx records selected

		RETURN r_arr_stattype 
END FUNCTION 
###########################################################################
# END FUNCTION db_stattype_filter_datasource(p_filter)
###########################################################################


###################################################################
# FUNCTION show_inttype(p_cmpy,p_filter_text)
#
# show_area
#                  Window FUNCTION FOR finding stattype records
#                  FUNCTION will RETURN type_code TO calling program
###################################################################
FUNCTION show_inttype(p_cmpy,p_filter_text) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_filter_text CHAR(200)
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_stattype RECORD LIKE stattype.* 
	DEFINE l_arr_stattype DYNAMIC ARRAY OF #array[100] OF RECORD 
		RECORD 
			scroll_flag CHAR(1), 
			type_code LIKE stattype.type_code, 
			type_text LIKE stattype.type_text 
		END RECORD 
	DEFINE l_idx SMALLINT 
		#	DEFINE l_query_text STRING
		#	DEFINE l_where_text STRING

		--OPTIONS INSERT KEY f36, 
		--DELETE KEY f36 
		OPEN WINDOW U219 with FORM "U219" 
		CALL windecoration_u("U219") -- albo kd-755 

		#   WHILE TRUE

		CALL db_stattype_filter_datasource(false) RETURNING l_arr_stattype 
		-------------

		#      IF l_idx = 0 THEN
		#         LET l_idx = 1
		#         INITIALIZE l_arr_stattype[1].* TO NULL
		#      END IF
		WHENEVER ERROR stop 
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 

		LET l_msgresp = kandoomsg("U",1006,"")		#1006 " ESC on line TO SELECT - F10 TO Add"
		#      CALL set_count(l_idx)
		#INPUT ARRAY l_arr_stattype WITHOUT DEFAULTS FROM sr_stattype.*
		DISPLAY ARRAY l_arr_stattype TO sr_stattype.* ATTRIBUTE(UNBUFFERED) 
			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","itypwind","input-arr-stattype") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			ON ACTION "FILTER" 
				CALL db_stattype_filter_datasource(true) RETURNING l_arr_stattype 

			BEFORE ROW 
				LET l_idx = arr_curr() 
				LET l_rec_stattype.type_code = l_arr_stattype[l_idx].type_code 

			ON KEY (F10) 
				CALL run_prog("U61","","","","") 
				CALL db_stattype_filter_datasource(false) RETURNING l_arr_stattype 

				#         AFTER FIELD scroll_flag
				#            LET l_arr_stattype[l_idx].scroll_flag = NULL
				#            IF fgl_lastkey() = fgl_keyval("down")
				#            AND arr_curr() >= arr_count() THEN
				#               LET l_msgresp = kandoomsg("U",9001,"")
				#               NEXT FIELD scroll_flag
				#            END IF

			ON ACTION ("ACCEPT","DOUBLECLICK") 
				#         BEFORE FIELD type_code
				LET l_rec_stattype.type_code = l_arr_stattype[l_idx].type_code 
				EXIT DISPLAY 

		END DISPLAY 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		END IF 

		CLOSE WINDOW U219 

		RETURN l_rec_stattype.type_code 
END FUNCTION 
###################################################################
# END FUNCTION show_inttype(p_cmpy,p_filter_text)
#
###################################################################