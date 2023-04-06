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

	Source code beautified by beautify.pl on 2020-01-02 10:35:22	$Id: $
}



#   pflexwin.4gl - flex_code
#                  Window FUNCTION FOR finding class records
#                  FUNCTION will RETURN flex_code TO calling program
GLOBALS "../common/glob_GLOBALS.4gl" 

FUNCTION show_flex_code(p_cmpy,p_class_code,p_start_num) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_class_code LIKE class.class_code 
	DEFINE p_start_num LIKE prodstructure.start_num 
	DEFINE l_rec_class RECORD LIKE class.*
	DEFINE l_rec_prodstructure RECORD LIKE prodstructure.* 
	DEFINE l_rec_prodflex RECORD LIKE prodflex.*
	DEFINE l_arr_prodflex array[100] OF RECORD 
		scroll_flag CHAR(1), 
		flex_code LIKE prodflex.flex_code, 
		desc_text LIKE prodflex.desc_text 
	END RECORD
	DEFINE l_idx,l_scrn SMALLINT 
	DEFINE l_query_text CHAR(2200) 
	DEFINE l_where_text CHAR(2048) 
	DEFINE l_msgresp LIKE language.yes_flag 

	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 
	SELECT * INTO l_rec_class.* FROM class 
	WHERE class_code = p_class_code 
	AND cmpy_code = p_cmpy 
	SELECT * INTO l_rec_prodstructure.* FROM prodstructure 
	WHERE class_code = p_class_code 
	AND start_num = p_start_num 
	AND cmpy_code = p_cmpy 
	OPEN WINDOW w170 with FORM "W170" 
	CALL windecoration_w("W170") -- albo kd-758 
	WHILE true 
		CLEAR FORM 
		DISPLAY BY NAME l_rec_class.class_code, 
		l_rec_prodstructure.start_num, 
		l_rec_prodstructure.length 

		DISPLAY l_rec_class.desc_text TO class_text 

		LET l_msgresp = kandoomsg("U",1001,"") 
		#1001 " Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON flex_code, 
		desc_text 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","pflexwin","construct-prodflex") 
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
		END CONSTRUCT 


		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_rec_prodflex.flex_code = NULL 
			EXIT WHILE 
		END IF 
		LET l_msgresp = kandoomsg("U",1002,"") 
		#1002 " Searching database - please wait"
		LET l_query_text = "SELECT * FROM prodflex ", 
		"WHERE cmpy_code = '", p_cmpy, "' ", 
		"AND class_code = '", p_class_code, "' ", 
		"AND start_num = '", p_start_num, "' ", 
		"AND ", l_where_text CLIPPED," ", 
		"ORDER BY flex_code" 
		WHENEVER ERROR CONTINUE 
		OPTIONS SQL interrupt ON 
		PREPARE s_prodflex FROM l_query_text 
		DECLARE c_prodflex CURSOR FOR s_prodflex 
		LET l_idx = 0 
		FOREACH c_prodflex INTO l_rec_prodflex.* 
			LET l_idx = l_idx + 1 
			LET l_arr_prodflex[l_idx].flex_code = l_rec_prodflex.flex_code 
			LET l_arr_prodflex[l_idx].desc_text = l_rec_prodflex.desc_text 
			IF l_idx = 100 THEN 
				LET l_msgresp = kandoomsg("U",6100,l_idx) 
				EXIT FOREACH 
			END IF 
		END FOREACH 
		LET l_msgresp = kandoomsg("U",9113,l_idx) 
		#9113 "l_idx records selected"
		IF l_idx = 0 THEN 
			LET l_idx = 1 
			INITIALIZE l_arr_prodflex[1].* TO NULL 
		END IF 
		WHENEVER ERROR stop 
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

		LET l_msgresp = kandoomsg("U",1006,"") 
		#1006 " ESC on line TO SELECT
		CALL set_count(l_idx) 
		INPUT ARRAY l_arr_prodflex WITHOUT DEFAULTS FROM sr_prodflex.* 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","pflexwin","input-arr-prodflex") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 


			BEFORE ROW 
				LET l_idx = arr_curr() 
				LET l_scrn = scr_line() 
				IF l_arr_prodflex[l_idx].flex_code IS NOT NULL THEN 
					DISPLAY l_arr_prodflex[l_idx].* 
					TO sr_prodflex[l_scrn].* 

				END IF 
				NEXT FIELD scroll_flag 
			AFTER FIELD scroll_flag 
				LET l_arr_prodflex[l_idx].scroll_flag = NULL 
				IF fgl_lastkey() = fgl_keyval("down") 
				AND arr_curr() >= arr_count() THEN 
					LET l_msgresp = kandoomsg("U",9001,"") 
					NEXT FIELD scroll_flag 
				END IF 
			BEFORE FIELD flex_code 
				LET l_rec_prodflex.flex_code = l_arr_prodflex[l_idx].flex_code 
				EXIT INPUT 
			ON KEY (F10) 
				CALL run_prog("IZS","","","","") 
				NEXT FIELD scroll_flag 
			AFTER ROW 
				DISPLAY l_arr_prodflex[l_idx].* TO sr_prodflex[l_scrn].* 

			AFTER INPUT 
				LET l_rec_prodflex.flex_code = l_arr_prodflex[l_idx].flex_code 

		END INPUT 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		ELSE 
			EXIT WHILE 
		END IF 
	END WHILE 
	CLOSE WINDOW w170 
	RETURN l_rec_prodflex.flex_code 
END FUNCTION 


