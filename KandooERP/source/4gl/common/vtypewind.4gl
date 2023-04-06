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
# FUNCTION db_vendortype_filter_datasource(p_filter)
#
#
###########################################################################
FUNCTION db_vendortype_filter_datasource(p_filter) 
	DEFINE p_filter BOOLEAN 
	DEFINE l_rec_vendortype RECORD LIKE vendortype.* 
	DEFINE l_arr_vendortype DYNAMIC ARRAY OF t_rec_vendortype_tc_tt_with_scrollflag 
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 
	DEFINE l_idx SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	IF p_filter = TRUE THEN 

		CLEAR FORM 
		LET l_msgresp = kandoomsg("U",1001,"")#1001 " Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON 
			type_code, 
			type_text 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","vtypewind","construct-vendortype") 
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = FALSE 
			LET quit_flag = FALSE 
			LET l_rec_vendortype.type_code = NULL 
			LET l_where_text = " 1=1 " 
		END IF 

	ELSE 
		LET l_where_text = " 1=1 " 
	END IF 

	LET l_msgresp = kandoomsg("U",1002,"")	#1002 " Searching database - please wait"
	LET l_query_text = 
		"SELECT * FROM vendortype ", 
		"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND ",l_where_text CLIPPED," ", 
		"ORDER BY type_code" 

	WHENEVER ERROR CONTINUE 
	OPTIONS SQL interrupt ON 

	PREPARE s_vendortype FROM l_query_text 
	DECLARE c_vendortype CURSOR FOR s_vendortype 

	LET l_idx = 0 
	FOREACH c_vendortype INTO l_rec_vendortype.* 
		LET l_idx = l_idx + 1 
		LET l_arr_vendortype[l_idx].type_code = l_rec_vendortype.type_code 
		LET l_arr_vendortype[l_idx].type_text = l_rec_vendortype.type_text 
		--IF l_idx = 100 THEN 
		--	LET l_msgresp = kandoomsg("U",6100,l_idx) 
		--	EXIT FOREACH 
		--END IF 
		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF			
	END FOREACH 

	LET l_msgresp=kandoomsg("U",9113,l_idx)	#U9113 l_idx records selected


	RETURN l_arr_vendortype 
END FUNCTION 
###########################################################################
# END FUNCTION db_vendortype_filter_datasource(p_filter)
###########################################################################


###############################################################
# FUNCTION show_vtyp(p_cmpy)
#
#       vtypewind.4gl - show_vtyp
#                       window FUNCTION FOR finding vendortypetype records
#                       returns type_code
###############################################################
FUNCTION show_vtyp(p_cmpy) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_vendortype RECORD LIKE vendortype.* 
	DEFINE l_arr_vendortype DYNAMIC ARRAY OF t_rec_vendortype_tc_tt_with_scrollflag 
	#	array[100] OF xx
	#		RECORD
	#			scroll_flag CHAR(1),
	#			type_code LIKE vendortype.type_code,
	#			type_text LIKE vendortype.type_text
	#		END RECORD
	DEFINE l_idx SMALLINT 

	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 

	OPEN WINDOW p167 with FORM "P167" 
	CALL windecoration_p("P167") 

	IF db_vendortype_get_count() > 1000 THEN 
		CALL db_vendortype_filter_datasource(TRUE) RETURNING l_arr_vendortype 
	ELSE 
		CALL db_vendortype_filter_datasource(FALSE) RETURNING l_arr_vendortype 
	END IF 

	IF l_arr_vendortype.getlength() = 0 THEN 
		LET l_idx = 1 
		INITIALIZE l_arr_vendortype[1].* TO NULL 
	END IF 

	WHENEVER ERROR stop 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 

	LET l_msgresp = kandoomsg("U",1006,"") #1006 " ESC on line TO SELECT - F10 TO Add"
	#      CALL set_count(l_idx)
	#INPUT ARRAY l_arr_vendortype WITHOUT DEFAULTS FROM sr_vendortype.* ATTRIBUTE(UNBUFFERED)

	DISPLAY ARRAY l_arr_vendortype TO sr_vendortype.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","vtypewind","input-arr-vendortype") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "FILTER" 
			CALL db_vendortype_filter_datasource(TRUE) RETURNING l_arr_vendortype 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			LET l_rec_vendortype.type_code = l_arr_vendortype[l_idx].type_code 
			#LET scrn = scr_line()
			#IF l_arr_vendortype[l_idx].type_code IS NOT NULL THEN
			#   DISPLAY l_arr_vendortype[l_idx].* TO sr_vendortype[scrn].*
			#
			#END IF
			#            NEXT FIELD scroll_flag

		ON KEY (F10) 
			CALL run_prog("PZ5","","","","") 

			CALL db_vendortype_filter_datasource(FALSE) RETURNING l_arr_vendortype 

			#         AFTER FIELD scroll_flag
			#            LET l_arr_vendortype[l_idx].scroll_flag = NULL
			#            IF  fgl_lastkey() = fgl_keyval("down")
			#            AND arr_curr() >= arr_count() THEN
			#               LET l_msgresp = kandoomsg("U",9001,"")
			#               NEXT FIELD scroll_flag
			#            END IF

			#         BEFORE FIELD type_code
			#            LET l_rec_vendortype.type_code = l_arr_vendortype[l_idx].type_code
			#            EXIT INPUT
			#AFTER ROW
			#   DISPLAY l_arr_vendortype[l_idx].* TO sr_vendortype[scrn].*

		AFTER DISPLAY 
			LET l_rec_vendortype.type_code = l_arr_vendortype[l_idx].type_code 

	END DISPLAY 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
	END IF 

	CLOSE WINDOW P167 
	CALL comboList_vendorType("type_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT)  
	RETURN l_rec_vendortype.type_code 

END FUNCTION 
###############################################################
# END FUNCTION show_vtyp(p_cmpy)
###############################################################