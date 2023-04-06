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




#
#Program GL4 - Maintains sub group
#
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 

###########################################################################
# MAIN
#
# Maintains sub group
###########################################################################
MAIN 

	CALL setModuleId("GL4") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_g_gl() #init g/gl general ledger module 


	OPEN WINDOW g542 with FORM "G542" 
	CALL windecoration_g("G542") 

	WHILE select_glrepsubgrp() 
		CALL scan_glrepsubgrp() 
	END WHILE 
	CLOSE WINDOW g542 
END MAIN 


###########################################################################
# FUNCTION select_glrepsubgrp()
#
#
###########################################################################
FUNCTION select_glrepsubgrp() 
	DEFINE l_query_text CHAR(500) 
	DEFINE l_where_text CHAR(300) 
	DEFINE l_msgresp LIKE language.yes_flag 

	CLEAR FORM 

	LET l_msgresp = kandoomsg("U",1001,"") 
	#1001 " Enter Selection Criteria - ESC TO Continue"
	CONSTRUCT BY NAME l_where_text ON group_code, 
	desc_text, 
	maingrp_code, 
	maingrp_order 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","GL4","construct-group") 

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
		LET l_query_text = "SELECT * FROM glrepsubgrp ", 
		"WHERE cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
		"AND ", l_where_text clipped," ", 
		"ORDER BY glrepsubgrp.group_code" 
		PREPARE s_glrepsubgrp FROM l_query_text 
		DECLARE c_glrepsubgrp CURSOR FOR s_glrepsubgrp 

		RETURN true 

	END IF 

END FUNCTION 


###########################################################################
# FUNCTION scan_glrepsubgrp()
#
#
###########################################################################
FUNCTION scan_glrepsubgrp() 
	DEFINE l_rec_glrepsubgrp RECORD LIKE glrepsubgrp.* 
	DEFINE l_arr_rec_glrepsubgrp DYNAMIC ARRAY OF RECORD --array[1000] OF RECORD 
		scroll_flag CHAR(1), 
		group_code LIKE glrepsubgrp.group_code, 
		desc_text LIKE glrepsubgrp.desc_text, 
		maingrp_code LIKE glrepsubgrp.maingrp_code, 
		maingrp_order LIKE glrepsubgrp.maingrp_order 
	END RECORD 
	DEFINE l_scroll_flag CHAR(1) 
	DEFINE l_desc_text CHAR(40) 
	DEFINE l_winds_text CHAR(40)
	DEFINE i SMALLINT  
	DEFINE l_idx SMALLINT  
	DEFINE l_del_cnt SMALLINT  
	DEFINE l_msgresp LIKE language.yes_flag 

	LET l_idx = 0 

	FOREACH c_glrepsubgrp INTO l_rec_glrepsubgrp.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_glrepsubgrp[l_idx].group_code = l_rec_glrepsubgrp.group_code 
		LET l_arr_rec_glrepsubgrp[l_idx].desc_text = l_rec_glrepsubgrp.desc_text 
		LET l_arr_rec_glrepsubgrp[l_idx].maingrp_code = l_rec_glrepsubgrp.maingrp_code 
		LET l_arr_rec_glrepsubgrp[l_idx].maingrp_order = l_rec_glrepsubgrp.maingrp_order 

		IF l_idx = 1000 THEN 
			LET l_msgresp = kandoomsg("U",9100,l_idx) 
			#9100 " First ??? entries Selected Only"
			EXIT FOREACH 
		END IF 

	END FOREACH 

	IF l_idx = 0 THEN 
		LET l_idx = 1 
		LET l_msgresp = kandoomsg("U",9101,"") 
		#9101" No records satisfied selection criteria "
	END IF 

	OPTIONS INSERT KEY f1, 
	DELETE KEY f36 

	LET l_msgresp = kandoomsg("U",1003,"") 

	#1003 " F1 TO Add - F2 TO Delete - RETURN on line TO Edit "
	INPUT ARRAY l_arr_rec_glrepsubgrp WITHOUT DEFAULTS FROM sr_glrepsubgrp.* ATTRIBUTE(UNBUFFERED) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GL4","inp-arr-glrepsubgrp") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		BEFORE ROW 
			LET l_idx = arr_curr() 
			#LET scrn = scr_line()
			NEXT FIELD scroll_flag 

		BEFORE INSERT 
			INITIALIZE l_rec_glrepsubgrp.* TO NULL 
			INITIALIZE l_arr_rec_glrepsubgrp[l_idx].* TO NULL 
			NEXT FIELD group_code 

		BEFORE FIELD scroll_flag 
			LET l_scroll_flag = l_arr_rec_glrepsubgrp[l_idx].scroll_flag 
			#DISPLAY l_arr_rec_glrepsubgrp[l_idx].* TO sr_glrepsubgrp[scrn].*

		AFTER FIELD scroll_flag 
			LET l_arr_rec_glrepsubgrp[l_idx].scroll_flag = l_scroll_flag 

			# DISPLAY l_arr_rec_glrepsubgrp[l_idx].scroll_flag
			#      TO sr_glrepsubgrp[scrn].scroll_flag

			LET l_rec_glrepsubgrp.group_code = l_arr_rec_glrepsubgrp[l_idx].group_code 
			LET l_rec_glrepsubgrp.desc_text = l_arr_rec_glrepsubgrp[l_idx].desc_text 
			LET l_rec_glrepsubgrp.maingrp_code = l_arr_rec_glrepsubgrp[l_idx].maingrp_code 
			LET l_rec_glrepsubgrp.maingrp_order = l_arr_rec_glrepsubgrp[l_idx].maingrp_order 

			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF l_arr_rec_glrepsubgrp[l_idx+1].group_code IS NULL 
				OR arr_curr() >= arr_count() THEN 
					LET l_msgresp=kandoomsg("U",9001,"") 
					#9001 There no more rows...
					NEXT FIELD scroll_flag 
				END IF 
			END IF 

			IF fgl_lastkey() = fgl_keyval("nextpage") THEN 
				IF l_arr_rec_glrepsubgrp[l_idx+8].maingrp_code IS NULL 
				OR arr_curr() >= arr_count() THEN 
					LET l_msgresp=kandoomsg("U",9001,"") 
					#9001 There no more rows...
					NEXT FIELD scroll_flag 
				END IF 
			END IF 

		BEFORE FIELD group_code 
			#DISPLAY l_arr_rec_glrepsubgrp[l_idx].* TO sr_glrepsubgrp[scrn].*

			IF l_arr_rec_glrepsubgrp[l_idx].group_code IS NOT NULL THEN 
				IF l_rec_glrepsubgrp.group_code IS NOT NULL THEN 
					NEXT FIELD desc_text 
				END IF 
			END IF 

		AFTER FIELD group_code 
			CASE 
				WHEN fgl_lastkey() = fgl_keyval("accept") 
					OR fgl_lastkey() = fgl_keyval("RETURN") 
					OR fgl_lastkey() = fgl_keyval("tab") 
					OR fgl_lastkey() = fgl_keyval("right") 
					OR fgl_lastkey() = fgl_keyval("down") 

					IF l_arr_rec_glrepsubgrp[l_idx].group_code IS NULL THEN 
						LET l_msgresp = kandoomsg("U",9102,"") 
						#9102 Value must be entered
						NEXT FIELD group_code 
					ELSE 
						IF l_rec_glrepsubgrp.group_code IS NULL THEN 
							SELECT unique 1 FROM glrepsubgrp 
							WHERE group_code = l_arr_rec_glrepsubgrp[l_idx].group_code 
							AND cmpy_code = glob_rec_kandoouser.cmpy_code 

							IF status != NOTFOUND THEN 
								LET l_msgresp = kandoomsg("U",9104,"") 
								# 9104 RECORD already exists
								NEXT FIELD group_code 
							ELSE 

								FOR i = 1 TO arr_count() 
									IF i <> l_idx THEN 

										IF l_arr_rec_glrepsubgrp[l_idx].group_code = 
										l_arr_rec_glrepsubgrp[i].group_code THEN 
											LET l_msgresp = kandoomsg("U",9013,"") 
											# 9013 RECORD already exists
											NEXT FIELD group_code 
										END IF 

									END IF 
								END FOR 

							END IF 
						ELSE 
							LET l_arr_rec_glrepsubgrp[l_idx].group_code 
							= l_rec_glrepsubgrp.group_code 
							#DISPLAY l_arr_rec_glrepsubgrp[l_idx].group_code
							#     TO sr_glrepsubgrp[scrn].group_code

						END IF 
						IF fgl_lastkey() = fgl_keyval("accept") THEN 
							IF l_arr_rec_glrepsubgrp[l_idx].desc_text IS NULL THEN 
								LET l_msgresp = kandoomsg("U",9102,"") 
								#9102 A value must be entered
								NEXT FIELD desc_text 
							END IF 

							IF l_arr_rec_glrepsubgrp[l_idx].maingrp_code IS NULL THEN 
								LET l_msgresp = kandoomsg("U",9102,"") 
								#9102 A value must be entered
								NEXT FIELD maingrp_code 
							END IF 
							IF l_arr_rec_glrepsubgrp[l_idx].maingrp_order IS NULL THEN 
								LET l_msgresp = kandoomsg("U",9102,"") 
								#9102 A value must be entered
								NEXT FIELD maingrp_order 
							END IF 

							NEXT FIELD scroll_flag 

						END IF 
						NEXT FIELD NEXT 

					END IF 

				OTHERWISE 

					NEXT FIELD group_code 
			END CASE 

		AFTER FIELD desc_text 
			CASE 
				WHEN fgl_lastkey() = fgl_keyval("accept") 
					OR fgl_lastkey() = fgl_keyval("RETURN") 
					OR fgl_lastkey() = fgl_keyval("tab") 
					OR fgl_lastkey() = fgl_keyval("right") 
					OR fgl_lastkey() = fgl_keyval("down") 

					IF l_arr_rec_glrepsubgrp[l_idx].desc_text IS NULL THEN 
						LET l_msgresp = kandoomsg("U",9102,"") 
						#9102 A value must be entered
						NEXT FIELD desc_text 
					ELSE 
						IF fgl_lastkey() = fgl_keyval("accept") THEN 
							IF l_arr_rec_glrepsubgrp[l_idx].maingrp_code IS NULL THEN 
								LET l_msgresp = kandoomsg("U",9105,"") 
								#9105 RECORD NOT found - Try window
								NEXT FIELD maingrp_code 
							END IF 

							IF l_arr_rec_glrepsubgrp[l_idx].maingrp_order IS NULL THEN 
								LET l_msgresp = kandoomsg("U",9102,"") 
								#9102 A value must be entered
								NEXT FIELD maingrp_order 
							END IF 

							NEXT FIELD scroll_flag 

						END IF 

						NEXT FIELD NEXT 
					END IF 

				WHEN fgl_lastkey() = fgl_keyval("left") 
					OR fgl_lastkey() = fgl_keyval("up") 
					NEXT FIELD previous 

				OTHERWISE 
					NEXT FIELD desc_text 

			END CASE 

		ON ACTION "LOOKUP" infield (maingrp_code) 
			LET l_winds_text = NULL 
			LET l_winds_text = show_maingrp_code(glob_rec_kandoouser.cmpy_code) 
			OPTIONS INSERT KEY f1, 
			DELETE KEY f36 
			IF l_winds_text IS NOT NULL THEN 
				LET l_arr_rec_glrepsubgrp[l_idx].maingrp_code = l_winds_text 
			END IF 
			NEXT FIELD maingrp_code 

		AFTER FIELD maingrp_code 
			SELECT * FROM glrepmaingrp 
			WHERE l_arr_rec_glrepsubgrp[l_idx].maingrp_code = maingrp_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 

			IF status = NOTFOUND THEN 
				LET l_msgresp = kandoomsg("U",9105,"") 
				#9105 RECORD NOT found - try window
				NEXT FIELD maingrp_code 
			END IF 

			CASE 
				WHEN fgl_lastkey() = fgl_keyval("accept") 
					OR fgl_lastkey() = fgl_keyval("RETURN") 
					OR fgl_lastkey() = fgl_keyval("tab") 
					OR fgl_lastkey() = fgl_keyval("right") 
					OR fgl_lastkey() = fgl_keyval("down") 

					IF l_arr_rec_glrepsubgrp[l_idx].maingrp_code IS NULL THEN 
						LET l_msgresp = kandoomsg("U",9105,"") 
						#9105 RECORD NOT found - try window
						NEXT FIELD maingrp_code 
					ELSE 
						IF fgl_lastkey() = fgl_keyval("accept") THEN 
							IF l_arr_rec_glrepsubgrp[l_idx].maingrp_order IS NULL THEN 
								LET l_msgresp = kandoomsg("U",9102,"") 
								#9102 A value must be entered
								NEXT FIELD maingrp_order 
							END IF 
							NEXT FIELD scroll_flag 
						END IF 
						NEXT FIELD NEXT 
					END IF 

				WHEN fgl_lastkey() = fgl_keyval("left") 
					OR fgl_lastkey() = fgl_keyval("up") 
					NEXT FIELD previous 

				OTHERWISE 
					NEXT FIELD maingrp_code 
			END CASE 

		AFTER FIELD maingrp_order 

			CASE 
				WHEN fgl_lastkey() = fgl_keyval("accept") 
					OR fgl_lastkey() = fgl_keyval("RETURN") 
					OR fgl_lastkey() = fgl_keyval("tab") 
					OR fgl_lastkey() = fgl_keyval("right") 
					OR fgl_lastkey() = fgl_keyval("down") 

					IF l_arr_rec_glrepsubgrp[l_idx].maingrp_order IS NULL THEN 
						LET l_msgresp = kandoomsg("U",9102,"") 
						#9102 A value must be entered
						NEXT FIELD maingrp_order 
					ELSE 
						NEXT FIELD NEXT 
					END IF 

				WHEN fgl_lastkey() = fgl_keyval("left") 
					OR fgl_lastkey() = fgl_keyval("up") 
					NEXT FIELD previous 

				OTHERWISE 
					NEXT FIELD maingrp_order 

			END CASE 

		ON KEY (F2) infield (scroll_flag) 
			IF l_arr_rec_glrepsubgrp[l_idx].scroll_flag IS NULL THEN 
				LET l_arr_rec_glrepsubgrp[l_idx].scroll_flag = "*" 
				LET l_del_cnt = l_del_cnt + 1 
			ELSE 
				LET l_arr_rec_glrepsubgrp[l_idx].scroll_flag = NULL 
				LET l_del_cnt = l_del_cnt - 1 
			END IF 
			NEXT FIELD scroll_flag 

			#AFTER ROW
			#   DISPLAY l_arr_rec_glrepsubgrp[l_idx].* TO sr_glrepsubgrp[scrn].*

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				IF NOT (infield(scroll_flag)) THEN 
					IF l_rec_glrepsubgrp.group_code IS NULL THEN 

						FOR l_idx = arr_curr() TO arr_count() 
							LET l_arr_rec_glrepsubgrp[l_idx].* = l_arr_rec_glrepsubgrp[l_idx+1].* 

							IF l_idx = arr_count() THEN 
								INITIALIZE l_arr_rec_glrepsubgrp[l_idx].* TO NULL 
							END IF 

							#IF scrn <= 8 THEN
							#   DISPLAY l_arr_rec_glrepsubgrp[l_idx].* TO sr_glrepsubgrp[scrn].*
							#
							#   LET scrn = scrn + 1
							#END IF

						END FOR 

						#LET scrn = scr_line()
						LET int_flag = false 
						LET quit_flag = false 

						NEXT FIELD scroll_flag 

					ELSE 
						LET l_arr_rec_glrepsubgrp[l_idx].group_code 
						= l_rec_glrepsubgrp.group_code 
						LET l_arr_rec_glrepsubgrp[l_idx].desc_text = l_rec_glrepsubgrp.desc_text 
						LET l_arr_rec_glrepsubgrp[l_idx].maingrp_code 
						= l_rec_glrepsubgrp.maingrp_code 
						LET l_rec_glrepsubgrp.maingrp_order 
						= l_arr_rec_glrepsubgrp[l_idx].maingrp_order 
						LET int_flag = false 
						LET quit_flag = false 

						NEXT FIELD scroll_flag 

					END IF 

				END IF 
			END IF 

	END INPUT 
	######################################################################

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	ELSE 

		FOR l_idx = 1 TO arr_count() 
			IF l_arr_rec_glrepsubgrp[l_idx].group_code IS NOT NULL THEN 

				LET l_rec_glrepsubgrp.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET l_rec_glrepsubgrp.group_code = l_arr_rec_glrepsubgrp[l_idx].group_code 
				LET l_rec_glrepsubgrp.desc_text = l_arr_rec_glrepsubgrp[l_idx].desc_text 
				LET l_rec_glrepsubgrp.maingrp_code = l_arr_rec_glrepsubgrp[l_idx].maingrp_code 
				LET l_rec_glrepsubgrp.maingrp_order = l_arr_rec_glrepsubgrp[l_idx].maingrp_order 

				UPDATE glrepsubgrp 
				SET * = l_rec_glrepsubgrp.* 
				WHERE group_code = l_rec_glrepsubgrp.group_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 

				IF sqlca.sqlerrd[3] = 0 THEN 
					INSERT INTO glrepsubgrp VALUES (l_rec_glrepsubgrp.*) 
				END IF 

			END IF 
		END FOR 

		IF l_del_cnt > 0 THEN 
			LET l_msgresp = kandoomsg("U",9902,l_del_cnt) 
			#9902 Confirm TO Delete ",l_del_cnt," sub group(s)? (Y/N)"

			IF l_msgresp = "Y" THEN 
				FOR l_idx = 1 TO arr_count() 

					IF l_arr_rec_glrepsubgrp[l_idx].scroll_flag = "*" THEN 
						DELETE FROM glrepsubgrp 
						WHERE group_code = l_arr_rec_glrepsubgrp[l_idx].group_code 
						AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					END IF 

				END FOR 
			END IF 

		END IF 

	END IF 
END FUNCTION