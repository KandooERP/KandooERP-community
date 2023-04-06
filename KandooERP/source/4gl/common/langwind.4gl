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

	Source code beautified by beautify.pl on 2020-01-02 10:35:18	$Id: $
}





############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

FUNCTION langwind_whenever_sqlerror ()
    # this code instanciates the default sql errors handling for all the code lines below this function
    # it is a compiler preprocessor. It is not necessary to execute that function
    WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
END FUNCTION

#######################################################################
# FUNCTION show_language()
#
#     langwind.4gl - show_language
#                    window FUNCTION FOR finding language records
#                    returns language_code
#######################################################################
FUNCTION show_language() 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_language RECORD LIKE language.* 
	DEFINE l_arr_language ARRAY[100] OF 
				RECORD 
					language_code LIKE language.language_code, 
					language_text LIKE language.language_text, 
					yes_flag LIKE language.yes_flag, 
					no_flag LIKE language.no_flag 
				END RECORD 
	DEFINE l_idx SMALLINT 
	DEFINE l_query_text CHAR(2200) 
	DEFINE l_where_text CHAR(2048) 

	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 

	OPEN WINDOW u131 with FORM "U131" 
	CALL windecoration_u("U131") 

	WHILE true 
		CLEAR FORM 
		LET l_msgresp = kandoomsg("U",1001,"") 
		#1001 " Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON language_code, 
		language_text, 
		yes_flag, 
		no_flag 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","langwind","construct-language") 
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
		END CONSTRUCT 


		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_rec_language.language_code = NULL 
			EXIT WHILE 
		END IF 
		LET l_msgresp = kandoomsg("U",1002,"") 
		#1002 " Searching database - please wait"
		LET l_query_text = "SELECT * FROM language ", 
		"WHERE ",l_where_text clipped," ", 
		"ORDER BY language_code" 
		WHENEVER ERROR CONTINUE 
		OPTIONS SQL interrupt ON 
		PREPARE s_language FROM l_query_text 
		DECLARE c_language CURSOR FOR s_language 
		LET l_idx = 0 
		FOREACH c_language INTO l_rec_language.* 
			LET l_idx = l_idx + 1 
			LET l_arr_language[l_idx].language_code = l_rec_language.language_code 
			LET l_arr_language[l_idx].language_text = l_rec_language.language_text 
			LET l_arr_language[l_idx].yes_flag = l_rec_language.yes_flag 
			LET l_arr_language[l_idx].no_flag = l_rec_language.no_flag 
			IF l_idx = 100 THEN 
				LET l_msgresp = kandoomsg("U",6100,l_idx) 
				EXIT FOREACH 
			END IF 
		END FOREACH 
		LET l_msgresp=kandoomsg("U",9113,l_idx) 
		#U9113 l_idx records selected
		IF l_idx = 0 THEN 
			LET l_idx = 1 
			INITIALIZE l_arr_language[1].* TO NULL 
		END IF 
		WHENEVER ERROR stop 
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 

		LET l_msgresp = kandoomsg("U",1006,"") 
		#1006 " ESC on line TO SELECT - F10 TO Add"
		CALL set_count(l_idx) 
		INPUT ARRAY l_arr_language WITHOUT DEFAULTS FROM sr_language.* 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","langwind","input-arr-language") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			BEFORE ROW 
				LET l_idx = arr_curr() 
				#LET scrn = scr_line()
				#IF l_arr_language[l_idx].language_code IS NOT NULL THEN
				#   DISPLAY l_arr_language[l_idx].* TO sr_language[scrn].*
				#
				#END IF
				NEXT FIELD language_code 
			ON KEY (F10) 
				CALL run_prog("U1L","","","","") 
				NEXT FIELD language_code 
			AFTER FIELD language_code 
				IF fgl_lastkey() = fgl_keyval("down") 
				AND arr_curr() >= arr_count() THEN 
					LET l_msgresp = kandoomsg("U",9001,"") 
					NEXT FIELD language_code 
				END IF 
			BEFORE FIELD language_text 
				LET l_rec_language.language_code = l_arr_language[l_idx].language_code 
				EXIT INPUT 
				#AFTER ROW
				#   DISPLAY l_arr_language[l_idx].* TO sr_language[scrn].*

			AFTER INPUT 
				LET l_rec_language.language_code = l_arr_language[l_idx].language_code 

		END INPUT 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		ELSE 
			EXIT WHILE 
		END IF 
	END WHILE 

	CLOSE WINDOW u131 

	RETURN l_rec_language.language_code 
END FUNCTION 


