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

	Source code beautified by beautify.pl on 2020-01-02 19:48:28	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_userDataTypes.4gl"
GLOBALS "J_JM_GLOBALS.4gl" 


############################################################
# MAIN
#
# Purpose - This Program allows the user TO enter AND maintain
#           Resource Groups FOR Job Management
############################################################
MAIN 
	#Initial UI Init
	CALL setModuleId("JZ1") -- albo 
	CALL ui_init(0) 
	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	OPEN WINDOW j199 with FORM "J199" -- alch kd-747 
	CALL winDecoration_j("J199") -- alch kd-747 

	#	WHILE select_group()
	CALL scan_group() 
	#	END WHILE

	CLOSE WINDOW j199 
END MAIN 


############################################################
# FUNCTION select_group()
#
#
############################################################
FUNCTION select_group(p_filter) 
	DEFINE p_filter boolean 
	DEFINE l_rec_resgrp RECORD LIKE resgrp.* 
	DEFINE l_arr_rec_resgrp DYNAMIC ARRAY OF t_rec_resgrp_rc_rt_rt_with_scrollflag 
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 
	DEFINE l_idx SMALLINT 

	IF p_filter THEN 
		CLEAR FORM 
		LET msgresp = kandoomsg("U",1001,"") 
		#1001 " Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON 
		resgrp_code, 
		resgrp_text, 
		res_type_ind 
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","JZ1","const-resgrp_code-1") -- alch kd-506 
			ON ACTION "WEB-HELP" -- albo kd-373 
				CALL onlinehelp(getmoduleid(),null) 
		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_where_text = " 1=1 " 
		END IF 
	ELSE 
		LET l_where_text = " 1=1 " 
	END IF 

	LET msgresp = kandoomsg("U",1002,"") 
	#1002 " Searching database - please wait"
	LET l_query_text = "SELECT * FROM resgrp ", 
	"WHERE cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
	"AND ", l_where_text clipped," ", 
	"ORDER BY resgrp_code" 
	PREPARE s_resgrp FROM l_query_text 
	DECLARE c_resgrp CURSOR FOR s_resgrp 

	LET l_idx = 0 
	FOREACH c_resgrp INTO l_rec_resgrp.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_resgrp[l_idx].resgrp_code = l_rec_resgrp.resgrp_code 
		LET l_arr_rec_resgrp[l_idx].resgrp_text = l_rec_resgrp.resgrp_text 
		LET l_arr_rec_resgrp[l_idx].res_type_ind = l_rec_resgrp.res_type_ind 
		IF l_idx = 100 THEN 
			LET msgresp = kandoomsg("U",6100,l_idx) 
			EXIT FOREACH 
		END IF 
	END FOREACH 

	RETURN l_arr_rec_resgrp 
END FUNCTION 




############################################################
# FUNCTION scan_group()
#
#
############################################################
FUNCTION scan_group() 
	DEFINE l_rec_resgrp RECORD LIKE resgrp.* 
	DEFINE l_arr_rec_resgrp DYNAMIC ARRAY OF t_rec_resgrp_rc_rt_rt_with_scrollflag 
	#	#array[100] of record
	#		RECORD
	#         scroll_flag CHAR(1),
	#         resgrp_code LIKE resgrp.resgrp_code,
	#         resgrp_text LIKE resgrp.resgrp_text,
	#         res_type_ind LIKE resgrp.res_type_ind
	#      END RECORD
	DEFINE l_scroll_flag CHAR(1) 
	DEFINE l_mode CHAR(3) 
	DEFINE l_res_type_ind LIKE resgrp.res_type_ind 
	DEFINE i SMALLINT 
	DEFINE l_idx SMALLINT 
	DEFINE l_del_cnt SMALLINT 


	CALL select_group(false) RETURNING l_arr_rec_resgrp 

	OPTIONS INSERT KEY f1, 
	DELETE KEY f36 
	#   CALL set_count(l_idx)
	LET msgresp = kandoomsg("W",1003,"") 

	#" F1 TO Add - F2 TO Delete - RETURN on line TO Edit "
	INPUT ARRAY l_arr_rec_resgrp WITHOUT DEFAULTS FROM sr_resgrp.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","JZ1","input_arr-l_arr_rec_resgrp-1") -- alch kd-506 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "FILTER" 
			CALL select_group(true) RETURNING l_arr_rec_resgrp 

		ON KEY (control-b) infield(res_type_ind) 
			LET l_res_type_ind = show_kandooword("resgrp.res_type_ind") 
			IF l_res_type_ind IS NOT NULL THEN 
				LET l_arr_rec_resgrp[l_idx].res_type_ind = l_res_type_ind 
			END IF 
			#               DISPLAY l_arr_rec_resgrp[l_idx].scroll_flag
			#                    TO sr_resgrp[scrn].scroll_flag

			NEXT FIELD res_type_ind 


		BEFORE ROW 
			LET l_idx = arr_curr() 
			#         LET scrn = scr_line()
			NEXT FIELD scroll_flag 

		BEFORE INSERT 
			INITIALIZE l_rec_resgrp.* TO NULL 
			INITIALIZE l_arr_rec_resgrp[l_idx].* TO NULL 
			LET l_mode = "ADD" 
			NEXT FIELD resgrp_code 

		BEFORE FIELD scroll_flag 
			INITIALIZE l_mode TO NULL 
			LET l_scroll_flag = l_arr_rec_resgrp[l_idx].scroll_flag 
			#         DISPLAY l_arr_rec_resgrp[l_idx].* TO sr_resgrp[scrn].*

		AFTER FIELD scroll_flag 
			LET l_arr_rec_resgrp[l_idx].scroll_flag = l_scroll_flag 
			#         DISPLAY l_arr_rec_resgrp[l_idx].scroll_flag
			#              TO sr_resgrp[scrn].scroll_flag

			LET l_rec_resgrp.resgrp_code = l_arr_rec_resgrp[l_idx].resgrp_code 
			LET l_rec_resgrp.resgrp_text = l_arr_rec_resgrp[l_idx].resgrp_text 
			LET l_rec_resgrp.res_type_ind = l_arr_rec_resgrp[l_idx].res_type_ind 
			#         IF fgl_lastkey() = fgl_keyval("down") THEN
			#            IF l_arr_rec_resgrp[l_idx+1].resgrp_code IS NULL
			#            OR arr_curr() >= arr_count() THEN
			#               LET msgresp=kandoomsg("W",9001,"")
			#               #9001 There no more rows...
			#               NEXT FIELD scroll_flag
			#            END IF
			#         END IF

		BEFORE FIELD resgrp_code 
			#         DISPLAY l_arr_rec_resgrp[l_idx].* TO sr_resgrp[scrn].*

			IF l_arr_rec_resgrp[l_idx].resgrp_code IS NOT NULL THEN 
				IF l_rec_resgrp.resgrp_code IS NOT NULL THEN 
					NEXT FIELD resgrp_text 
				END IF 
			END IF 
			IF l_arr_rec_resgrp[l_idx].resgrp_code IS NULL 
			AND l_mode IS NULL THEN 
				NEXT FIELD scroll_flag 
			END IF 

		AFTER FIELD resgrp_code 
			CASE 
				WHEN fgl_lastkey() = fgl_keyval("accept") 
					OR fgl_lastkey() = fgl_keyval("RETURN") 
					OR fgl_lastkey() = fgl_keyval("tab") 
					OR fgl_lastkey() = fgl_keyval("right") 
					OR fgl_lastkey() = fgl_keyval("down") 
					IF l_arr_rec_resgrp[l_idx].resgrp_code IS NULL THEN 
						LET msgresp = kandoomsg("U",9102,"") 
						#9102 Value must be entered
						NEXT FIELD resgrp_code 
					ELSE 
						IF l_rec_resgrp.resgrp_code IS NULL THEN 
							SELECT unique 1 FROM resgrp 
							WHERE resgrp_code = l_arr_rec_resgrp[l_idx].resgrp_code 
							AND cmpy_code = glob_rec_kandoouser.cmpy_code 
							IF status != notfound THEN 
								LET msgresp = kandoomsg("U",9104,"") 
								#9104 RECORD already exists
								NEXT FIELD resgrp_code 
							ELSE 
								FOR i = 1 TO arr_count() 
									IF i <> l_idx THEN 
										IF l_arr_rec_resgrp[l_idx].resgrp_code = 
										l_arr_rec_resgrp[i].resgrp_code THEN 
											LET msgresp = kandoomsg("U",9104,"") 
											# 9104 RECORD already exists
											NEXT FIELD resgrp_code 
										END IF 
									END IF 
								END FOR 
							END IF 
						ELSE 
							LET l_arr_rec_resgrp[l_idx].resgrp_code 
							= l_rec_resgrp.resgrp_code 
							#                     DISPLAY l_arr_rec_resgrp[l_idx].resgrp_code
							#                          TO sr_resgrp[scrn].resgrp_code

						END IF 
						IF fgl_lastkey() = fgl_keyval("accept") THEN 
							IF l_arr_rec_resgrp[l_idx].resgrp_text IS NULL THEN 
								LET msgresp = kandoomsg("U",9102,"") 
								#9102 Value must be entered
								NEXT FIELD resgrp_text 
							END IF 
							NEXT FIELD scroll_flag 
						END IF 
						NEXT FIELD NEXT 
					END IF 
				OTHERWISE 
					NEXT FIELD resgrp_code 
			END CASE 

		AFTER FIELD resgrp_text 
			CASE 
				WHEN fgl_lastkey() = fgl_keyval("accept") 
					OR fgl_lastkey() = fgl_keyval("RETURN") 
					OR fgl_lastkey() = fgl_keyval("tab") 
					OR fgl_lastkey() = fgl_keyval("right") 
					OR fgl_lastkey() = fgl_keyval("down") 
					IF l_arr_rec_resgrp[l_idx].resgrp_text IS NULL THEN 
						LET msgresp = kandoomsg("U",9102,"") 
						#9102 Value must be entered
						NEXT FIELD resgrp_text 
					END IF 
					IF fgl_lastkey() = fgl_keyval("accept") THEN 
						NEXT FIELD scroll_flag 
					END IF 
					NEXT FIELD NEXT 
				WHEN fgl_lastkey() = fgl_keyval("left") 
					OR fgl_lastkey() = fgl_keyval("up") 
					NEXT FIELD previous 
				OTHERWISE 
					NEXT FIELD resgrp_text 
			END CASE 

		AFTER FIELD res_type_ind 
			IF fgl_lastkey() = fgl_keyval("left") 
			OR fgl_lastkey() = fgl_keyval("up") THEN 
				NEXT FIELD previous 
			ELSE 
				NEXT FIELD scroll_flag 
			END IF 

		ON KEY (F2) infield (scroll_flag) 
			IF l_arr_rec_resgrp[l_idx].scroll_flag IS NULL 
			AND l_arr_rec_resgrp[l_idx].resgrp_code IS NOT NULL THEN 
				SELECT unique 1 FROM jmresource 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND resgrp_code = l_arr_rec_resgrp[l_idx].resgrp_code 
				IF status = 0 THEN 
					LET msgresp = kandoomsg("J",9563,"") 
					NEXT FIELD scroll_flag 
				END IF 
				LET l_arr_rec_resgrp[l_idx].scroll_flag = "*" 
				LET l_del_cnt = l_del_cnt + 1 
			ELSE 
				IF l_arr_rec_resgrp[l_idx].scroll_flag = "*" THEN 
					LET l_arr_rec_resgrp[l_idx].scroll_flag = NULL 
					LET l_del_cnt = l_del_cnt - 1 
				END IF 
			END IF 
			NEXT FIELD scroll_flag 

			#      AFTER ROW
			#         DISPLAY l_arr_rec_resgrp[l_idx].* TO sr_resgrp[scrn].*

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				IF NOT (infield(scroll_flag)) THEN 
					IF l_rec_resgrp.resgrp_code IS NULL THEN 
						FOR l_idx = arr_curr() TO arr_count() 
							LET l_arr_rec_resgrp[l_idx].* = l_arr_rec_resgrp[l_idx+1].* 
							IF l_idx = arr_count() THEN 
								INITIALIZE l_arr_rec_resgrp[l_idx].* TO NULL 
							END IF 
							#                     IF scrn <= 8 THEN
							#                        DISPLAY l_arr_rec_resgrp[l_idx].* TO sr_resgrp[scrn].*
							#
							#                        LET scrn = scrn + 1
							#                     END IF
						END FOR 
						#                  LET scrn = scr_line()
						LET int_flag = false 
						LET quit_flag = false 
						NEXT FIELD scroll_flag 
					ELSE 
						LET l_arr_rec_resgrp[l_idx].resgrp_code = l_rec_resgrp.resgrp_code 
						LET l_arr_rec_resgrp[l_idx].resgrp_text = l_rec_resgrp.resgrp_text 
						LET l_arr_rec_resgrp[l_idx].res_type_ind = l_rec_resgrp.res_type_ind 
						LET int_flag = false 
						LET quit_flag = false 
						NEXT FIELD scroll_flag 
					END IF 
				END IF 
			END IF 

			#      ON KEY (control-w)
			#         CALL kandoohelp("")

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	ELSE 
		FOR l_idx = 1 TO arr_count() 
			IF l_arr_rec_resgrp[l_idx].resgrp_code IS NOT NULL THEN 
				LET l_rec_resgrp.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET l_rec_resgrp.resgrp_code = l_arr_rec_resgrp[l_idx].resgrp_code 
				LET l_rec_resgrp.resgrp_text = l_arr_rec_resgrp[l_idx].resgrp_text 
				LET l_rec_resgrp.res_type_ind = l_arr_rec_resgrp[l_idx].res_type_ind 
				UPDATE resgrp 
				SET * = l_rec_resgrp.* 
				WHERE resgrp_code = l_rec_resgrp.resgrp_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF sqlca.sqlerrd[3] = 0 THEN 
					INSERT INTO resgrp VALUES (l_rec_resgrp.*) 
				END IF 
			END IF 
		END FOR 

		IF l_del_cnt > 0 THEN 
			LET msgresp = kandoomsg("J",8008,l_del_cnt) 
			#8014 Confirm TO Delete ",l_del_cnt," Resource Group(s)? (Y/N)"
			IF msgresp = "Y" THEN 
				FOR l_idx = 1 TO arr_count() 
					IF l_arr_rec_resgrp[l_idx].scroll_flag = "*" THEN 
						DELETE FROM resgrp 
						WHERE resgrp_code = l_arr_rec_resgrp[l_idx].resgrp_code 
						AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					END IF 
				END FOR 
			END IF 
		END IF 
	END IF 

END FUNCTION 
