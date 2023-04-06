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
#   btypwind.4gl - type_code
#                  Window FUNCTION FOR finding a Bank Type record
#                  FUNCTION will RETURN type_code TO calling program
###########################################################################

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

###########################################################################
# FUNCTION db_banktype_get_datasource(p_filter)
#
# type_code
#   Window FUNCTION FOR finding a Bank Type record
#   FUNCTION will RETURN type_code TO calling program
###########################################################################
FUNCTION db_banktype_get_datasource(p_filter)
	DEFINE p_filter BOOLEAN 
	DEFINE l_rec_banktype RECORD LIKE banktype.* 
	DEFINE l_arr_rec_banktype DYNAMIC ARRAY OF RECORD 
		scroll_flag CHAR(1), 
		type_code LIKE banktype.type_code, 
		type_text LIKE banktype.type_text 
	END RECORD 
	DEFINE l_idx SMALLINT 
	DEFINE l_query_text STRING --CHAR(2200) 
	DEFINE l_where_text STRING --CHAR(2048) 

	IF p_filter THEN 
		CLEAR FORM 
		MESSAGE kandoomsg2("U",1001,"")		#1001 " Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON 
			type_code, 
			type_text 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","btypwind","construct-type") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_where_text = " 1=1 "
		END IF 
	ELSE
		LET l_where_text = " 1=1 "
	END IF
	
	MESSAGE kandoomsg2("U",1002,"")	#1002 " Searching database - please wait"
	LET l_query_text = 
		"SELECT * FROM banktype ", 
		"WHERE ", l_where_text clipped," ", 
		"ORDER BY type_code" 

	PREPARE s_banktype FROM l_query_text 
	DECLARE c_banktype CURSOR FOR s_banktype 
	LET l_idx = 0 
	FOREACH c_banktype INTO l_rec_banktype.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_banktype[l_idx].type_code = l_rec_banktype.type_code 
		LET l_arr_rec_banktype[l_idx].type_text = l_rec_banktype.type_text

		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF			 
	END FOREACH 

	MESSAGE kandoomsg2("U",9113,l_idx)	#U9113 l_idx records selected

	RETURN l_arr_rec_banktype
END FUNCTION 
###########################################################################
# END FUNCTION db_banktype_get_datasource(p_filter) 
###########################################################################


###########################################################################
# FUNCTION show_banktype() 
#
# type_code
#   Window FUNCTION FOR finding a Bank Type record
#   FUNCTION will RETURN type_code TO calling program
###########################################################################
FUNCTION show_banktype() 
	DEFINE l_rec_banktype RECORD LIKE banktype.* 
	DEFINE l_arr_rec_banktype DYNAMIC ARRAY OF RECORD 
		scroll_flag CHAR(1), 
		type_code LIKE banktype.type_code, 
		type_text LIKE banktype.type_text 
	END RECORD 
	DEFINE l_idx SMALLINT 

	OPEN WINDOW G535 with FORM "G535" 
	CALL windecoration_g("G535") 

	CALL db_banktype_get_datasource(FALSE) RETURNING l_arr_rec_banktype

	MESSAGE kandoomsg2("U",1006,"")	#1006 " ESC on line TO SELECT
	DISPLAY ARRAY l_arr_rec_banktype TO sr_banktype.* 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","btypwind","input-arr-banktype") 
			CALL dialog.setActionHidden("ACCEPT",NOT l_arr_rec_banktype.getSize())			
			
		BEFORE ROW 
			LET l_idx = arr_curr() 
			LET l_rec_banktype.type_code = l_arr_rec_banktype[l_idx].type_code
			
		AFTER ROW 
			#nothing 

		AFTER DISPLAY 
			#nothing

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "FILTER"
			CALL l_arr_rec_banktype.clear()
			CALL db_banktype_get_datasource(FALSE) RETURNING l_arr_rec_banktype

		ON ACTION "REFRESH"
			CALL windecoration_g("G535")
			CALL l_arr_rec_banktype.clear()
			CALL db_banktype_get_datasource(FALSE) RETURNING l_arr_rec_banktype

		ON ACTION "GZT-BANK TYPE MAINT" --ON KEY (F10) 
			CALL run_prog("GZT","","","","") 

	END DISPLAY
	 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 
 
	CLOSE WINDOW G535 

	RETURN l_rec_banktype.type_code 
END FUNCTION 
###########################################################################
# END FUNCTION show_banktype() 
###########################################################################