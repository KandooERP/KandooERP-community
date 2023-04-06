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
GLOBALS "../common/glob_GLOBALS_userDataTypes.4gl"

###########################################################################
# FUNCTION select_wsub(p_filter)
#
#       wsubwind.4gl - show_wsub
#                      window FUNCTION FOR finding suburb records
#                      returns suburb_code
###########################################################################
FUNCTION select_wsub(p_filter) 
	DEFINE p_filter BOOLEAN 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_suburb RECORD LIKE suburb.* 
	DEFINE l_arr_code DYNAMIC ARRAY OF #array[100] OF RECORD 
		RECORD 
			suburb_code LIKE suburb.suburb_code 
		END RECORD 
	DEFINE l_arr_suburb DYNAMIC ARRAY OF t_rec_suburb_st_sc_pc_with_scrollflag 
		#	array[100] of record
		#         scroll_flag CHAR(1),
		#         suburb_text LIKE suburb.suburb_text,
		#         state_code LIKE suburb.state_code,
		#         post_code LIKE suburb.post_code
		#      END RECORD
	DEFINE l_idx SMALLINT 
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 


		IF p_filter THEN 
			CLEAR FORM 
			MESSAGE kandoomsg2("U",1001,"")			#1001 Enter Selection Criteria - ESC TO Continue"
			CONSTRUCT BY NAME l_where_text ON 
				suburb_text, 
				state_code, 
				post_code 

				BEFORE CONSTRUCT 
					CALL publish_toolbar("kandoo","wsubwind","construct-suburb") 

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
			END CONSTRUCT 


			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
				LET l_rec_suburb.suburb_code = 0 
				LET l_where_text = " 1=1 " 
			END IF 
		ELSE 
			LET l_where_text = " 1=1 " 
		END IF 

		MESSAGE kandoomsg2("U",1002,"")	#1002 Searching database = please wait
		LET l_query_text = "SELECT * FROM suburb ", 
		"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code ,"' ", 
		"AND ", l_where_text CLIPPED, " ", 
		"ORDER BY suburb_text,state_code" 

		WHENEVER ERROR CONTINUE 
 
		PREPARE s_suburb FROM l_query_text 
		DECLARE c_suburb CURSOR FOR s_suburb 

		LET l_idx = 0 
		FOREACH c_suburb INTO l_rec_suburb.* 
			LET l_idx = l_idx + 1 
			LET l_arr_suburb[l_idx].suburb_text = l_rec_suburb.suburb_text 
			LET l_arr_suburb[l_idx].state_code = l_rec_suburb.state_code 
			LET l_arr_suburb[l_idx].post_code = l_rec_suburb.post_code 
			LET l_arr_code[l_idx].suburb_code = l_rec_suburb.suburb_code

			IF l_idx = glob_rec_settings.maxListArraySize THEN
				MESSAGE kandoomsg2("U",6100,l_idx)
				EXIT FOREACH
			END IF				 
		END FOREACH 


		MESSAGE kandoomsg2("U",9113,l_arr_suburb.getLength())	#9113 l_idx records selected
		RETURN l_arr_suburb, l_arr_code 
END FUNCTION 
###########################################################################
# END FUNCTION select_wsub(p_filter)
###########################################################################

###########################################################################
# FUNCTION show_wsub(p_cmpy)
#
#       
###########################################################################
FUNCTION show_wsub(p_cmpy) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_suburb RECORD LIKE suburb.* 
	DEFINE l_arr_code DYNAMIC ARRAY OF RECORD 
		suburb_code LIKE suburb.suburb_code 
	END RECORD 
	DEFINE l_arr_suburb DYNAMIC ARRAY OF t_rec_suburb_st_sc_pc_with_scrollflag
	DEFINE l_idx SMALLINT 	 
		#	array[100] of record
		#         scroll_flag CHAR(1),
		#         suburb_text LIKE suburb.suburb_text,
		#         state_code LIKE suburb.state_code,
		#         post_code LIKE suburb.post_code
		#      END RECORD

		OPEN WINDOW U112 with FORM "U112" 
		CALL windecoration_u("U112") -- albo kd-758 

		IF db_street_get_count() > 1000 THEN 
			CALL select_wsub(true) RETURNING l_arr_suburb, l_arr_code 
		ELSE 
			CALL select_wsub(false) RETURNING l_arr_suburb, l_arr_code 
		END IF 

		IF l_arr_suburb.getlength() = 0 THEN 
			LET l_idx = 1 
			INITIALIZE l_arr_suburb[1].* TO NULL 
			LET l_arr_code[1].suburb_code = 0 
		END IF 

		WHENEVER ERROR stop 
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

		MESSAGE kandoomsg2("U",1006,"") 	#1006 " ESC on line TO SELECT - F10 TO Add

		DISPLAY ARRAY l_arr_suburb TO sr_suburb.* ATTRIBUTE(UNBUFFERED) 
			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","wsubwind","input-arr-suburb") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			BEFORE ROW 
				LET l_idx = arr_curr() 

			ON KEY (F10) 
				CALL run_prog("U51","","","","") 
				CALL select_wsub(false) RETURNING l_arr_suburb, l_arr_code 

			AFTER DISPLAY 
				LET l_rec_suburb.suburb_code = l_arr_code[l_idx].suburb_code 

		END DISPLAY 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_rec_suburb.suburb_code = NULL 
		END IF 

		CLOSE WINDOW u112 

		RETURN l_rec_suburb.suburb_code 
END FUNCTION 
###########################################################################
# END FUNCTION show_wsub(p_cmpy)
###########################################################################