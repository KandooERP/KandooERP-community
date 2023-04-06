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

	Source code beautified by beautify.pl on 2020-01-02 10:35:36	$Id: $
}



#   strtwind.4gl - start_num
#                  Window FUNCTION FOR finding prodstructure records
#                  FUNCTION will RETURN start_num TO calling program
GLOBALS "../common/glob_GLOBALS.4gl" 

FUNCTION show_start_num(p_cmpy,p_class_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_class_code LIKE class.class_code 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_prodstructure RECORD LIKE prodstructure.* 
	DEFINE l_arr_prodstructure ARRAY[100] OF RECORD 
		scroll_flag CHAR(1), 
		start_num LIKE prodstructure.start_num, 
		desc_text LIKE prodstructure.desc_text 
	END RECORD 
	DEFINE l_idx,l_scrn SMALLINT 
	DEFINE l_query_text CHAR(2200) 
	DEFINE l_where_text CHAR(2048) 

	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 
	OPEN WINDOW i624 with FORM "I624" 
	CALL windecoration_i("I624") -- albo kd-758 
	WHILE true 
		CLEAR FORM 
		LET l_msgresp = kandoomsg("U",1001,"") 
		#1001 " Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON start_num, 
		desc_text 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","strtwind","construct-prodstructure") 
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
		END CONSTRUCT 


		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_rec_prodstructure.start_num = NULL 
			EXIT WHILE 
		END IF 
		LET l_msgresp = kandoomsg("U",1002,"") 
		#1002 " Searching database - please wait"
		LET l_query_text = "SELECT * FROM prodstructure ", 
		"WHERE cmpy_code = '", p_cmpy, "' ", 
		"AND class_code = '", p_class_code, "' ", 
		"AND ", l_where_text CLIPPED," ", 
		"ORDER BY start_num" 
		WHENEVER ERROR CONTINUE 
		OPTIONS SQL interrupt ON 
		PREPARE s_prodstructure FROM l_query_text 
		DECLARE c_prodstructure CURSOR FOR s_prodstructure 
		LET l_idx = 0 
		FOREACH c_prodstructure INTO l_rec_prodstructure.* 
			LET l_idx = l_idx + 1 
			LET l_arr_prodstructure[l_idx].start_num = l_rec_prodstructure.start_num 
			LET l_arr_prodstructure[l_idx].desc_text = l_rec_prodstructure.desc_text 
			IF l_idx = 100 THEN 
				LET l_msgresp = kandoomsg("U",6100,l_idx) 
				EXIT FOREACH 
			END IF 
		END FOREACH 
		LET l_msgresp = kandoomsg("U",9113,l_idx) 
		#9113 "l_idx records selected"
		IF l_idx = 0 THEN 
			LET l_idx = 1 
			INITIALIZE l_arr_prodstructure[1].* TO NULL 
		END IF 
		WHENEVER ERROR stop 
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

		LET l_msgresp = kandoomsg("U",1006,"") 
		#1006 " ESC on line TO SELECT
		CALL set_count(l_idx) 
		INPUT ARRAY l_arr_prodstructure WITHOUT DEFAULTS FROM sr_prodstructure.* 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","strtwind","input-arr-prodstructure") 


			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			BEFORE ROW 
				LET l_idx = arr_curr() 
				LET l_scrn = scr_line() 
				IF l_arr_prodstructure[l_idx].start_num IS NOT NULL THEN 
					DISPLAY l_arr_prodstructure[l_idx].* TO sr_prodstructure[l_scrn].* 

				END IF 
				NEXT FIELD scroll_flag 
			AFTER FIELD scroll_flag 
				LET l_arr_prodstructure[l_idx].scroll_flag = NULL 
				IF fgl_lastkey() = fgl_keyval("down") 
				AND arr_curr() >= arr_count() THEN 
					LET l_msgresp = kandoomsg("U",9001,"") 
					NEXT FIELD scroll_flag 
				END IF 
			BEFORE FIELD start_num 
				LET l_rec_prodstructure.start_num = l_arr_prodstructure[l_idx].start_num 
				EXIT INPUT 
			ON KEY (F10) 
				CALL run_prog("IZ2","","","","") 
			AFTER ROW 
				DISPLAY l_arr_prodstructure[l_idx].* TO sr_prodstructure[l_scrn].* 

			AFTER INPUT 
				LET l_rec_prodstructure.start_num = l_arr_prodstructure[l_idx].start_num 

		END INPUT 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		ELSE 
			EXIT WHILE 
		END IF 
	END WHILE 
	CLOSE WINDOW i624 
	RETURN l_rec_prodstructure.start_num 
END FUNCTION 


