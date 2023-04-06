{
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

	Source code beautified by beautify.pl on 2020-01-02 10:35:30	$Id: $
}





############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

#################################################################################
# FUNCTION show_purchtype(p_cmpy,p_filter_text)
#
#     ptypwind.4gl - show_purchtype
#                    Window FUNCTION FOR finding purchtype records
#                    FUNCTION will RETURN purchtype_code TO calling program
#################################################################################
FUNCTION show_purchtype(p_cmpy,p_filter_text) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_filter_text CHAR(300)
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_purchtype RECORD LIKE purchtype.* 
	DEFINE l_arr_purchtype ARRAY[100] OF 
		RECORD 
			scroll_flag CHAR(1), 
			purchtype_code LIKE purchtype.purchtype_code, 
			desc_text LIKE purchtype.desc_text 
		END RECORD 
	DEFINE l_idx SMALLINT 
	DEFINE l_query_text CHAR(2200) 
	DEFINE l_where_text CHAR(2048) 

	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 
	IF p_filter_text IS NULL THEN 
		LET p_filter_text = "1=1" 
	END IF 
	OPEN WINDOW r602 with FORM "R602" 
	CALL windecoration_r("R602") -- albo kd-752 
	WHILE true 
		CLEAR FORM 
		LET l_msgresp = kandoomsg("U",1001,"") 
		#1001 " Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON purchtype_code, 
		desc_text 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","ptypwind","construct-purchtype") 
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
		END CONSTRUCT 


		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_rec_purchtype.purchtype_code = NULL 
			EXIT WHILE 
		END IF 
		LET l_msgresp = kandoomsg("U",1002,"") 
		#1002 " Searching database - please wait"
		LET l_query_text = "SELECT * FROM purchtype ", 
		"WHERE cmpy_code = \"",p_cmpy,"\" ", 
		"AND ",l_where_text CLIPPED," ", 
		"AND ",p_filter_text CLIPPED," ", 
		"ORDER BY purchtype_code" 
		WHENEVER ERROR CONTINUE 
		OPTIONS SQL interrupt ON 
		PREPARE s_purchtype FROM l_query_text 
		DECLARE c_purchtype CURSOR FOR s_purchtype 
		LET l_idx = 0 
		FOREACH c_purchtype INTO l_rec_purchtype.* 
			LET l_idx = l_idx + 1 
			LET l_arr_purchtype[l_idx].purchtype_code = l_rec_purchtype.purchtype_code 
			LET l_arr_purchtype[l_idx].desc_text = l_rec_purchtype.desc_text 
			IF l_idx = 100 THEN 
				LET l_msgresp = kandoomsg("U",6100,l_idx) 
				EXIT FOREACH 
			END IF 
		END FOREACH 
		LET l_msgresp = kandoomsg("U",9113,l_idx) 
		#9113 l_idx records selected
		IF l_idx = 0 THEN 
			LET l_idx = 1 
			INITIALIZE l_arr_purchtype[1].* TO NULL 
		END IF 
		WHENEVER ERROR stop 
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

		LET l_msgresp = kandoomsg("U",1006,"") 
		#1006 " ESC on line TO SELECT - F10 TO Add"
		CALL set_count(l_idx) 
		INPUT ARRAY l_arr_purchtype WITHOUT DEFAULTS FROM sr_purchtype.* 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","ptypwind","input-arr-purchtype") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			BEFORE ROW 
				LET l_idx = arr_curr() 
				#LET scrn = scr_line()
				#IF l_arr_purchtype[l_idx].purchtype_code IS NOT NULL THEN
				#   DISPLAY l_arr_purchtype[l_idx].* TO sr_purchtype[scrn].*
				#
				#END IF
				NEXT FIELD scroll_flag 
			ON KEY (F10) 
				CALL run_prog("RZ3","","","","") 
				NEXT FIELD scroll_flag 
			AFTER FIELD scroll_flag 
				LET l_arr_purchtype[l_idx].scroll_flag = NULL 
				IF fgl_lastkey() = fgl_keyval("down") 
				AND arr_curr() >= arr_count() THEN 
					LET l_msgresp=kandoomsg("U",9001,"") 
					NEXT FIELD scroll_flag 
				END IF 
			BEFORE FIELD purchtype_code 
				LET l_rec_purchtype.purchtype_code = l_arr_purchtype[l_idx].purchtype_code 
				EXIT INPUT 
				#AFTER ROW
				#   DISPLAY l_arr_purchtype[l_idx].* TO sr_purchtype[scrn].*

			AFTER INPUT 
				LET l_rec_purchtype.purchtype_code = l_arr_purchtype[l_idx].purchtype_code 

		END INPUT 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		ELSE 
			EXIT WHILE 
		END IF 
	END WHILE 
	CLOSE WINDOW r602 

	RETURN l_rec_purchtype.purchtype_code 
END FUNCTION 


