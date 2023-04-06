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

	Source code beautified by beautify.pl on 2020-01-02 10:35:38	$Id: $
}



#     userwind.4gl - show_user
#                    Window FUNCTION FOR finding kandoouser records
#                    FUNCTION will RETURN sign_on_code string
GLOBALS "../common/glob_GLOBALS.4gl" 

FUNCTION show_user() 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_kandoouser RECORD LIKE kandoouser.* 
	DEFINE l_arr_rec_kandoouser ARRAY[300] OF RECORD 
		scroll_flag CHAR(1), 
		sign_on_code LIKE kandoouser.sign_on_code, 
		name_text LIKE kandoouser.name_text 
	END RECORD 
	DEFINE l_scroll_flag CHAR(1)
	DEFINE l_query_text CHAR(2200) 
	DEFINE l_where_text CHAR(2048)
	DEFINE l_tagged SMALLINT 
	DEFINE l_idx, l_scrn SMALLINT
	DEFINE i SMALLINT
	DEFINE r_user_code CHAR(2500)

	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 
	OPEN WINDOW u536 with FORM "U536" 
	CALL windecoration_u("U536") -- albo kd-764 
	WHILE true 
		CLEAR FORM 
		FOR i = 1 TO 300 
			INITIALIZE l_arr_rec_kandoouser[i].* TO NULL 
		END FOR 
		LET l_msgresp = kandoomsg("U",1001,"") 
		#1001 " Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON sign_on_code, 
		name_text 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","userwind","construct-kandoouser") 
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
		END CONSTRUCT 


		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_rec_kandoouser.sign_on_code = NULL 
			EXIT WHILE 
		END IF 
		LET l_msgresp = kandoomsg("U",1002,"") 
		#1002 " Searching database - please wait"
		LET l_query_text = "SELECT * FROM kandoouser ", 
		" WHERE passwd_ind != '0' ", 
		" AND ",l_where_text CLIPPED," ", 
		" ORDER BY sign_on_code" 
		WHENEVER ERROR CONTINUE 
		OPTIONS SQL interrupt ON 
		PREPARE s_rec_kandoouser FROM l_query_text 
		DECLARE c_rec_kandoouser CURSOR FOR s_rec_kandoouser 
		LET l_idx = 0 
		FOREACH c_rec_kandoouser INTO l_rec_kandoouser.* 
			LET l_idx = l_idx + 1 
			LET l_arr_rec_kandoouser[l_idx].sign_on_code = l_rec_kandoouser.sign_on_code 
			LET l_arr_rec_kandoouser[l_idx].name_text = l_rec_kandoouser.name_text 
			IF l_idx = 300 THEN 
				LET l_msgresp = kandoomsg("U",6100,l_idx) 
				EXIT FOREACH 
			END IF 
		END FOREACH 
		LET l_msgresp=kandoomsg("U",9113,l_idx) 
		#U9113 l_idx records selected
		IF l_idx = 0 THEN 
			LET l_idx = 1 
			INITIALIZE l_arr_rec_kandoouser[1].* TO NULL 
		END IF 
		WHENEVER ERROR stop 
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 

		LET l_msgresp = kandoomsg("U",1064,"") 
		#1064 F8 SELECT User; F10 SELECT All; OK TO Continue.
		CALL set_count(l_idx) 
		INPUT ARRAY l_arr_rec_kandoouser WITHOUT DEFAULTS FROM sr_rec_kandoouser.* 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","userwind","input-arr-kandoouser") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			BEFORE ROW 
				LET l_idx = arr_curr() 
				LET l_scrn = scr_line() 
			BEFORE FIELD scroll_flag 
				LET l_idx = arr_curr() 
				LET l_scrn = scr_line() 
				LET l_scroll_flag = l_arr_rec_kandoouser[l_idx].scroll_flag 
				DISPLAY l_arr_rec_kandoouser[l_idx].* TO sr_rec_kandoouser[l_scrn].* 

			ON KEY (F8) 
				IF l_arr_rec_kandoouser[l_idx].sign_on_code IS NOT NULL THEN 
					IF l_arr_rec_kandoouser[l_idx].scroll_flag IS NULL THEN 
						LET l_arr_rec_kandoouser[l_idx].scroll_flag = "*" 
						LET l_scroll_flag = "*" 
						LET l_tagged = l_tagged + 1 
					ELSE 
						LET l_arr_rec_kandoouser[l_idx].scroll_flag = NULL 
						LET l_scroll_flag = NULL 
						LET l_tagged = l_tagged - 1 
					END IF 
				END IF 
				NEXT FIELD scroll_flag 
			ON KEY (F10) 
				FOR i = 1 TO arr_count() 
					IF l_arr_rec_kandoouser[l_idx].sign_on_code IS NOT NULL THEN 
						IF l_arr_rec_kandoouser[i].scroll_flag IS NULL THEN 
							LET l_arr_rec_kandoouser[i].scroll_flag = "*" 
							LET l_tagged = l_tagged + 1 
						ELSE 
							LET l_arr_rec_kandoouser[i].scroll_flag = NULL 
							LET l_tagged = l_tagged - 1 
						END IF 
						IF l_idx = i THEN 
							LET l_scroll_flag = l_arr_rec_kandoouser[i].scroll_flag 
						END IF 
					END IF 
				END FOR 
				FOR l_scrn = 1 TO 12 
					LET l_idx = arr_curr() - scr_line() + l_scrn 
					IF l_idx <= arr_count() THEN 
						DISPLAY l_arr_rec_kandoouser[l_idx].scroll_flag 
						TO sr_rec_kandoouser[l_scrn].scroll_flag 

					ELSE 
						EXIT FOR 
					END IF 
				END FOR 
				NEXT FIELD scroll_flag 
			AFTER FIELD scroll_flag 
				LET l_arr_rec_kandoouser[l_idx].scroll_flag = l_scroll_flag 
				IF fgl_lastkey() = fgl_keyval("down") 
				AND arr_curr() >= arr_count() THEN 
					LET l_msgresp = kandoomsg("U",9001,"") 
					#9001 There no more rows...
					NEXT FIELD scroll_flag 
				END IF 
				IF fgl_lastkey() = fgl_keyval("down") THEN 
					IF l_arr_rec_kandoouser[l_idx+1].sign_on_code IS NULL THEN 
						LET l_msgresp = kandoomsg("U",9001,"") 
						#9001 There no more rows...
						NEXT FIELD scroll_flag 
					END IF 
				END IF 
				IF fgl_lastkey() = fgl_keyval("nextpage") 
				AND l_arr_rec_kandoouser[l_idx+12].sign_on_code IS NULL THEN 
					LET l_msgresp = kandoomsg("U",9001,"") 
					#9001 No more rows in this direction
					NEXT FIELD scroll_flag 
				END IF 
			BEFORE FIELD sign_on_code 
				NEXT FIELD scroll_flag 
			AFTER ROW 
				DISPLAY l_arr_rec_kandoouser[l_idx].* TO sr_rec_kandoouser[l_scrn].* 

			AFTER INPUT 
				LET l_rec_kandoouser.sign_on_code = l_arr_rec_kandoouser[l_idx].sign_on_code 

		END INPUT 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		ELSE 
			EXIT WHILE 
		END IF 
	END WHILE 
	CLOSE WINDOW u536 
	IF l_tagged > 0 THEN 
		FOR i = 1 TO arr_count() 
			IF l_arr_rec_kandoouser[i].scroll_flag = "*" THEN 
				IF length(r_user_code) = 0 THEN 
					LET r_user_code = l_arr_rec_kandoouser[i].sign_on_code 
				ELSE 
					LET r_user_code = r_user_code CLIPPED," ", 
					l_arr_rec_kandoouser[i].sign_on_code 
				END IF 
			END IF 
		END FOR 
	ELSE 
		LET r_user_code = l_arr_rec_kandoouser[l_idx].sign_on_code 
	END IF 
	RETURN r_user_code 
END FUNCTION 


