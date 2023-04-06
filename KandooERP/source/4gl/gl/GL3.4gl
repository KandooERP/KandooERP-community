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

	Source code beautified by beautify.pl on 2020-01-03 14:28:46	$Id: $
}



#   GL3 - Main Group Maintenance

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 

############################################################
# MODULE Scope Variables
############################################################
--DEFINE temp_text CHAR(20) 


############################################################
# MAIN
#
#
############################################################
MAIN 
	DEFINE l_msgresp LIKE language.yes_flag 

	CALL setModuleId("GL3") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_g_gl() #init g/gl general ledger module 


	OPEN WINDOW g541 with FORM "G541" 
	CALL windecoration_g("G541") 

	WHILE select_maingrp() 
		CALL scan_maingrp() 
	END WHILE 
	CLOSE WINDOW g541 
END MAIN 


############################################################
# FUNCTION select_maingrp()
#
#
############################################################
FUNCTION select_maingrp() 
	DEFINE l_query_text CHAR(300) 
	DEFINE l_where_text CHAR(200) 
	DEFINE l_msgresp LIKE language.yes_flag 

	CLEAR FORM 
	LET l_msgresp = kandoomsg("U",1001,"") 
	#1001 " Enter Selection Criteria - ESC TO Continue"
	CONSTRUCT BY NAME l_where_text ON maingrp_code,	desc_text 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","GL3","construct-maingrp") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
			
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 
	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		LET l_msgresp = kandoomsg("U",1002,"") 
		#1002 " Searching database - please wait"
		LET l_query_text = "SELECT * FROM glrepmaingrp ", 
		"WHERE cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
		"AND ", l_where_text clipped," ", 
		"ORDER BY maingrp_code" 
		PREPARE s_maingrp FROM l_query_text 
		DECLARE c_maingrp CURSOR FOR s_maingrp 
		RETURN true 
	END IF 
END FUNCTION 


############################################################
# FUNCTION scan_maingrp()
#
#
############################################################
FUNCTION scan_maingrp() 
	DEFINE l_rec_glrepmaingrp RECORD LIKE glrepmaingrp.* 
	DEFINE l_arr_rec_maingrp DYNAMIC ARRAY OF RECORD --array[300] OF RECORD 
		scroll_flag CHAR(1), 
		maingrp_code LIKE glrepmaingrp.maingrp_code, 
		desc_text LIKE glrepmaingrp.desc_text 
	END RECORD 
	DEFINE l_scroll_flag CHAR(1) 
	DEFINE i SMALLINT
	DEFINE l_idx SMALLINT
	DEFINE l_del_cnt SMALLINT
	DEFINE l_msgresp LIKE language.yes_flag 

	LET l_idx = 0 
	FOREACH c_maingrp INTO l_rec_glrepmaingrp.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_maingrp[l_idx].maingrp_code = l_rec_glrepmaingrp.maingrp_code 
		LET l_arr_rec_maingrp[l_idx].desc_text = l_rec_glrepmaingrp.desc_text 
		IF l_idx = 300 THEN 
			LET l_msgresp = kandoomsg("U",9100,l_idx) 
			#9100 " First ??? entries Selected Only"
			EXIT FOREACH 
		END IF 
	END FOREACH
	 
	IF l_idx = 0 THEN 
		LET l_idx=1 
		LET l_msgresp = kandoomsg("U",9101,"") 
		#9101" No records satisfied selection criteria "
	END IF 
	OPTIONS INSERT KEY f1, 
	DELETE KEY f36 
	CALL set_count(l_idx) 
	LET l_msgresp = kandoomsg("U",1003,"") 

	#" F1 TO Add - F2 TO Delete - RETURN on line TO Edit "
	INPUT ARRAY l_arr_rec_maingrp WITHOUT DEFAULTS FROM sr_maingrp.* attributes(UNBUFFERED) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GL3","inp-arr-maingrp") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		BEFORE ROW 
			LET l_idx = arr_curr() 
			#LET scrn = scr_line()
			NEXT FIELD scroll_flag
			 
		BEFORE INSERT 
			INITIALIZE l_rec_glrepmaingrp.* TO NULL 
			INITIALIZE l_arr_rec_maingrp[l_idx].* TO NULL 
			NEXT FIELD maingrp_code
			 
		BEFORE FIELD scroll_flag 
			LET l_scroll_flag = l_arr_rec_maingrp[l_idx].scroll_flag 
			#DISPLAY l_arr_rec_maingrp[l_idx].* TO sr_maingrp[scrn].*

		AFTER FIELD scroll_flag 
			LET l_arr_rec_maingrp[l_idx].scroll_flag = l_scroll_flag 
			#DISPLAY l_arr_rec_maingrp[l_idx].scroll_flag
			#     TO sr_maingrp[scrn].scroll_flag

			LET l_rec_glrepmaingrp.maingrp_code = l_arr_rec_maingrp[l_idx].maingrp_code 
			LET l_rec_glrepmaingrp.desc_text = l_arr_rec_maingrp[l_idx].desc_text 
			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF l_arr_rec_maingrp[l_idx+1].maingrp_code IS NULL 
				OR arr_curr() >= arr_count() THEN 
					LET l_msgresp=kandoomsg("U",9001,"") 
					#9001 There no more rows...
					NEXT FIELD scroll_flag 
				END IF 
			END IF
			 
		BEFORE FIELD maingrp_code 
			#DISPLAY l_arr_rec_maingrp[l_idx].* TO sr_maingrp[scrn].*

			IF l_arr_rec_maingrp[l_idx].maingrp_code IS NOT NULL THEN 
				IF l_rec_glrepmaingrp.maingrp_code IS NOT NULL THEN 
					NEXT FIELD desc_text 
				END IF 
			END IF
			 
		AFTER FIELD maingrp_code 
			CASE 
				WHEN fgl_lastkey() = fgl_keyval("accept") 
					OR fgl_lastkey() = fgl_keyval("RETURN") 
					OR fgl_lastkey() = fgl_keyval("tab") 
					OR fgl_lastkey() = fgl_keyval("right") 
					OR fgl_lastkey() = fgl_keyval("down") 
					IF l_arr_rec_maingrp[l_idx].maingrp_code IS NULL THEN 
						LET l_msgresp = kandoomsg("U",9102,"") 
						#9102 Value must be entered
						NEXT FIELD maingrp_code 
					ELSE 
						IF l_rec_glrepmaingrp.maingrp_code IS NULL THEN 
							SELECT unique 1 FROM glrepmaingrp 
							WHERE maingrp_code = l_arr_rec_maingrp[l_idx].maingrp_code 
							AND cmpy_code = glob_rec_kandoouser.cmpy_code 
							IF status != NOTFOUND THEN 
								LET l_msgresp = kandoomsg("U",9104,"") 
								# 9104 RECORD already exists
								NEXT FIELD maingrp_code 
							ELSE 
								FOR i = 1 TO arr_count() 
									IF i <> l_idx THEN 
										IF l_arr_rec_maingrp[l_idx].maingrp_code = 
										l_arr_rec_maingrp[i].maingrp_code THEN 
											LET l_msgresp = kandoomsg("U",9104,"") 
											# 9104 RECORD already exists
											NEXT FIELD maingrp_code 
										END IF 
									END IF 
								END FOR 
							END IF 
						ELSE 
							LET l_arr_rec_maingrp[l_idx].maingrp_code 
							= l_rec_glrepmaingrp.maingrp_code 
							#DISPLAY l_arr_rec_maingrp[l_idx].maingrp_code
							#     TO sr_maingrp[scrn].maingrp_code

						END IF 
						IF fgl_lastkey() = fgl_keyval("accept") THEN 
							IF l_arr_rec_maingrp[l_idx].desc_text IS NULL THEN 
								LET l_msgresp = kandoomsg("U",9102,"") 
								#9102 A value must be entered
								NEXT FIELD desc_text 
							END IF 
							NEXT FIELD scroll_flag 
						END IF 
						NEXT FIELD NEXT 
					END IF 
				OTHERWISE 
					NEXT FIELD maingrp_code 
			END CASE
			 
		AFTER FIELD desc_text 
			CASE 
				WHEN fgl_lastkey() = fgl_keyval("accept") 
					OR fgl_lastkey() = fgl_keyval("RETURN") 
					OR fgl_lastkey() = fgl_keyval("tab") 
					OR fgl_lastkey() = fgl_keyval("right") 
					OR fgl_lastkey() = fgl_keyval("down") 
					IF l_arr_rec_maingrp[l_idx].desc_text IS NULL THEN 
						LET l_msgresp = kandoomsg("U",9102,"") 
						#9102 A value must be entered
						NEXT FIELD desc_text 
					ELSE 
						IF fgl_lastkey() = fgl_keyval("accept") THEN 
							NEXT FIELD scroll_flag 
						ELSE 
							NEXT FIELD NEXT 
						END IF 
					END IF 
				WHEN fgl_lastkey() = fgl_keyval("left") 
					OR fgl_lastkey() = fgl_keyval("up") 
					NEXT FIELD previous 

				OTHERWISE 
					NEXT FIELD desc_text 

			END CASE 

		ON KEY (F2) infield (scroll_flag) 
			SELECT unique 1 FROM glrepsubgrp 
			WHERE l_arr_rec_maingrp[l_idx].maingrp_code = maingrp_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF status = NOTFOUND THEN 
				IF l_arr_rec_maingrp[l_idx].scroll_flag IS NULL THEN 
					LET l_arr_rec_maingrp[l_idx].scroll_flag = "*" 
					LET l_del_cnt = l_del_cnt + 1 
				ELSE 
					LET l_arr_rec_maingrp[l_idx].scroll_flag = NULL 
					LET l_del_cnt = l_del_cnt - 1 
				END IF 
			ELSE 
				LET l_msgresp = kandoomsg("U",9905,"") 
				#9905 This main group code IS being accessed by a sub group
			END IF 
			NEXT FIELD scroll_flag 


			#AFTER ROW
			#   DISPLAY l_arr_rec_maingrp[l_idx].* TO sr_maingrp[scrn].*

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				IF NOT (infield(scroll_flag)) THEN 
					IF l_rec_glrepmaingrp.maingrp_code IS NULL THEN 
						FOR l_idx = arr_curr() TO arr_count() 
							LET l_arr_rec_maingrp[l_idx].* = l_arr_rec_maingrp[l_idx+1].* 
							IF l_idx = arr_count() THEN 
								INITIALIZE l_arr_rec_maingrp[l_idx].* TO NULL 
							END IF 
							#IF scrn <= 8 THEN
							#   DISPLAY l_arr_rec_maingrp[l_idx].* TO sr_maingrp[scrn].*
							#
							#   LET scrn = scrn + 1
							#END IF
						END FOR 
						#LET scrn = scr_line()
						LET int_flag = false 
						LET quit_flag = false 
						NEXT FIELD scroll_flag 
					ELSE 
						LET l_arr_rec_maingrp[l_idx].maingrp_code 
						= l_rec_glrepmaingrp.maingrp_code 
						LET l_arr_rec_maingrp[l_idx].desc_text = l_rec_glrepmaingrp.desc_text 
						LET int_flag = false 
						LET quit_flag = false 
						NEXT FIELD scroll_flag 
					END IF 
				END IF 
			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	ELSE 
		FOR l_idx = 1 TO arr_count() 
			IF l_arr_rec_maingrp[l_idx].maingrp_code IS NOT NULL THEN 
				LET l_rec_glrepmaingrp.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET l_rec_glrepmaingrp.maingrp_code = l_arr_rec_maingrp[l_idx].maingrp_code 
				LET l_rec_glrepmaingrp.desc_text = l_arr_rec_maingrp[l_idx].desc_text 
				UPDATE glrepmaingrp 
				SET * = l_rec_glrepmaingrp.* 
				WHERE maingrp_code = l_rec_glrepmaingrp.maingrp_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF sqlca.sqlerrd[3] = 0 THEN 
					INSERT INTO glrepmaingrp VALUES (l_rec_glrepmaingrp.*) 
				END IF 
			END IF 
		END FOR 
		IF l_del_cnt > 0 THEN 
			LET l_msgresp = kandoomsg("G",9520,l_del_cnt) 
			#8014 Confirm TO Delete ",l_del_cnt,"   Main Group(s)? (Y/N)"
			IF l_msgresp = "Y" THEN 
				FOR l_idx = 1 TO arr_count() 
					IF l_arr_rec_maingrp[l_idx].scroll_flag = "*" THEN 
						DELETE FROM glrepmaingrp 
						WHERE maingrp_code = l_arr_rec_maingrp[l_idx].maingrp_code 
						AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					END IF 
				END FOR 
			END IF 
		END IF 
	END IF 
END FUNCTION