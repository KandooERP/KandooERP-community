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

	Source code beautified by beautify.pl on 2020-01-03 09:12:49	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "I_IN_GLOBALS.4gl" 

#   IZD.4gl - Maintenance Program FOR Departments AND sub Departments.

GLOBALS 
	DEFINE 
	glob_dept_ind SMALLINT 
END GLOBALS 

####################################################################
# MAIN
#
#
####################################################################
MAIN 
	#Initial UI Init
	CALL setModuleId("IZD") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_i_in() --init i/in warehouse inventory management module 

	OPEN WINDOW i607 with FORM "I607" 
	 CALL windecoration_i("I607") -- albo kd-758 

	WHILE true 
		MENU " Department Level" 
			BEFORE MENU 
				CLEAR FORM 
				CALL publish_toolbar("kandoo","IZD","menu-Department_Level-1") -- albo kd-505 
			ON ACTION "WEB-HELP" -- albo kd-372 
				CALL onlinehelp(getmoduleid(),null) 
			COMMAND "Dept" " Maintain Departments" 
				LET glob_dept_ind = 1 
				EXIT MENU 
			COMMAND "Sub-Dept" " Maintain Sub-Departments" 
				LET glob_dept_ind = 2 
				EXIT MENU 
			COMMAND KEY (interrupt,"E")"Exit" " EXIT PROGRAM" 
				LET glob_dept_ind = 0 
				EXIT MENU 
				#         COMMAND KEY (control-w)
				#            CALL kandoohelp("")
		END MENU 

		IF NOT glob_dept_ind THEN 
			EXIT WHILE 
		END IF 
		IF select_main() THEN 
			CALL scan_main() 
		END IF 
	END WHILE 

	CLOSE WINDOW i607 

END MAIN 


####################################################################
# FUNCTION select_main()
#
#
####################################################################
FUNCTION select_main() 
	DEFINE l_query_text CHAR(200) 
	DEFINE l_where_text CHAR(100) 
	DEFINE msgresp LIKE language.yes_flag 

	CLEAR FORM 
	LET msgresp = kandoomsg("I",1001,"") 
	#1001 " Enter Selection Criteria - ESC TO Continue"
	CONSTRUCT BY NAME l_where_text ON dept_code, 
	desc_text 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","IZC","construct-dept_code-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		LET msgresp = kandoomsg("I",1002,"") 
		#1002 " Searching database - please wait"
		LET l_query_text = "SELECT * ", 
		"FROM proddept ", 
		"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
		"AND ",l_where_text clipped," ", 
		"AND dept_ind = ",glob_dept_ind," ", 
		"ORDER BY cmpy_code,", 
		"dept_code" 
		PREPARE s_proddept FROM l_query_text 
		DECLARE c_proddept CURSOR FOR s_proddept 
		RETURN true 
	END IF 

END FUNCTION 


####################################################################
# FUNCTION select_main()
#
#
####################################################################
FUNCTION scan_main() 
	DEFINE l_rec_proddept RECORD LIKE proddept.* 
	DEFINE l_arr_rec_proddept array[100] OF 
	RECORD 
		scroll_flag CHAR(1), 
		dept_code LIKE proddept.dept_code, 
		desc_text LIKE proddept.desc_text 
	END RECORD 
	DEFINE l_scroll_flag CHAR(1) 
	DEFINE l_rowid INTEGER 
	DEFINE l_idx SMALLINT 
	#	DEFINE scrn SMALLINT
	DEFINE l_del_cnt SMALLINT 
	DEFINE msgresp LIKE language.yes_flag 

	LET l_idx = 0 
	FOREACH c_proddept INTO l_rec_proddept.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_proddept[l_idx].scroll_flag = NULL 
		LET l_arr_rec_proddept[l_idx].dept_code = l_rec_proddept.dept_code 
		LET l_arr_rec_proddept[l_idx].desc_text = l_rec_proddept.desc_text 
		IF l_idx = 100 THEN 
			LET msgresp = kandoomsg("I",9128,"100") 
			#9128" First ??? Departments Selected Only"
			EXIT FOREACH 
		END IF 
	END FOREACH 

	IF l_idx = 0 THEN 
		LET msgresp = kandoomsg("I",9130,"") 
		#9130 No Departments Satsified Selection Criteria
		LET l_idx = 1 
	END IF 
	OPTIONS INSERT KEY f1, 
	DELETE KEY f36 
	CALL set_count(l_idx) 
	LET msgresp = kandoomsg("I",1003,"") 
	#1003 " F1 TO Add - F2 TO Delete - RETURN TO Edit "
	INPUT ARRAY l_arr_rec_proddept WITHOUT DEFAULTS FROM sr_proddept.* attribute(UNBUFFERED, auto append = false, DELETE row=false,append row=false) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","IZD","input-arr-l_arr_rec_proddept-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			#         LET scrn = scr_line()
			LET l_scroll_flag = l_arr_rec_proddept[l_idx].scroll_flag 

		BEFORE FIELD scroll_flag 
			LET l_idx = arr_curr() 
			#         LET scrn = scr_line()
			LET l_scroll_flag = l_arr_rec_proddept[l_idx].scroll_flag 
			#         DISPLAY l_arr_rec_proddept[l_idx].*
			#              TO sr_proddept[scrn].*

		AFTER FIELD scroll_flag 
			LET l_arr_rec_proddept[l_idx].scroll_flag = l_scroll_flag 
			#         DISPLAY l_arr_rec_proddept[l_idx].scroll_flag
			#              TO sr_proddept[scrn].scroll_flag

			#         IF fgl_lastkey() = fgl_keyval("down") THEN
			#            IF arr_curr() = arr_count() THEN
			#               LET msgresp=kandoomsg("I",9001,"")
			#               #9001 There are no more rows in the direction ...
			#               NEXT FIELD scroll_flag
			#            ELSE
			#               IF l_arr_rec_proddept[l_idx+1].dept_code IS NULL THEN
			#                  LET msgresp=kandoomsg("I",9001,"")
			#                  #9001 There are no more rows in the direction ...
			#                  NEXT FIELD scroll_flag
			#               END IF
			#            END IF
			#         END IF

		ON ACTION "EDIT" 
			IF l_arr_rec_proddept[l_idx].dept_code IS NOT NULL THEN 
				IF edit_proddept(l_arr_rec_proddept[l_idx].dept_code) THEN 
					SELECT desc_text 
					INTO l_arr_rec_proddept[l_idx].desc_text 
					FROM proddept 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND dept_code = l_arr_rec_proddept[l_idx].dept_code 
					AND dept_ind = glob_dept_ind 
				END IF 
				OPTIONS DELETE KEY f36, 
				INSERT KEY f1 
			END IF 
			NEXT FIELD scroll_flag 

		BEFORE FIELD dept_code 
			IF l_arr_rec_proddept[l_idx].dept_code IS NOT NULL THEN 
				IF edit_proddept(l_arr_rec_proddept[l_idx].dept_code) THEN 
					SELECT desc_text 
					INTO l_arr_rec_proddept[l_idx].desc_text 
					FROM proddept 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND dept_code = l_arr_rec_proddept[l_idx].dept_code 
					AND dept_ind = glob_dept_ind 
				END IF 
				OPTIONS DELETE KEY f36, 
				INSERT KEY f1 
			END IF 
			NEXT FIELD scroll_flag 

		BEFORE INSERT 
			#         IF arr_curr() < arr_count() THEN
			LET l_rowid = edit_proddept("") 
			SELECT dept_code, 
			desc_text 
			INTO l_arr_rec_proddept[l_idx].dept_code, 
			l_arr_rec_proddept[l_idx].desc_text 
			FROM proddept 
			WHERE rowid = l_rowid 
			IF status = notfound THEN 
				FOR l_idx = arr_curr() TO arr_count() 
					LET l_arr_rec_proddept[l_idx].* = l_arr_rec_proddept[l_idx+1].* 
					#   IF scrn <= 14 THEN
					#      DISPLAY l_arr_rec_proddept[l_idx].*
					#           TO sr_proddept[scrn].*
					#
					#      LET scrn = scrn + 1
					#   END IF
				END FOR 
				INITIALIZE l_arr_rec_proddept[l_idx].* TO NULL 
			END IF 
			OPTIONS DELETE KEY f36, 
			INSERT KEY f1 
			#         ELSE
			#            IF l_idx > 1 THEN
			#               LET msgresp = kandoomsg("E",9001,"")
			#               # There are no more rows in the direction you are going "
			#            END IF
			#         END IF
			NEXT FIELD scroll_flag 

		ON KEY (F2) #delete marker 
			IF l_arr_rec_proddept[l_idx].dept_code IS NOT NULL THEN 
				IF l_arr_rec_proddept[l_idx].scroll_flag IS NULL THEN 
					IF glob_dept_ind = 1 THEN 
						SELECT unique 1 FROM maingrp 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND dept_code = l_arr_rec_proddept[l_idx].dept_code 
					ELSE 
						SELECT unique 1 FROM prodgrp 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND subdept_code = l_arr_rec_proddept[l_idx].dept_code 
					END IF 
					IF status = 0 THEN 
						LET msgresp = kandoomsg("I",7041,l_arr_rec_proddept[l_idx].dept_code) 
						#7041 Department assigned TO Product, No Deletion
					ELSE 
						LET l_arr_rec_proddept[l_idx].scroll_flag = "*" 
						LET l_del_cnt = l_del_cnt + 1 
					END IF 
				ELSE 
					LET l_arr_rec_proddept[l_idx].scroll_flag = NULL 
					LET l_del_cnt = l_del_cnt - 1 
				END IF 
			END IF 
			NEXT FIELD scroll_flag 

			#      ON KEY (control-w)
			#         CALL kandoohelp("")

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	ELSE 
		IF l_del_cnt > 0 THEN 
			LET msgresp = kandoomsg("I",8006,l_del_cnt) 
			#8006 Confirm TO Delete ",l_del_cnt,"Department(s)? (Y/N)"
			IF msgresp = "Y" THEN 
				FOR l_idx = 1 TO arr_count() 
					IF l_arr_rec_proddept[l_idx].scroll_flag = "*" THEN 
						IF glob_dept_ind = 1 THEN 
							SELECT unique 1 FROM maingrp 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND dept_code = l_arr_rec_proddept[l_idx].dept_code 
						ELSE 
							SELECT unique 1 FROM prodgrp 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND subdept_code = l_arr_rec_proddept[l_idx].dept_code 
						END IF 
						IF status = 0 THEN 
							LET msgresp = kandoomsg("I",7041,l_arr_rec_proddept[l_idx].dept_code) 
							#7041 Department assigned TO Product, No Deletion
						ELSE 
							DELETE FROM proddept 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND dept_code = l_arr_rec_proddept[l_idx].dept_code 
							AND dept_ind = glob_dept_ind 
						END IF 
					END IF 
				END FOR 
			END IF 
		END IF 
	END IF 
END FUNCTION 


####################################################################
# FUNCTION edit_proddept(l_dept_code)
#
#
####################################################################
FUNCTION edit_proddept(p_dept_code) 
	DEFINE p_dept_code LIKE proddept.dept_code 
	DEFINE l_rec_proddept RECORD LIKE proddept.* 
	DEFINE msgresp LIKE language.yes_flag 

	OPEN WINDOW i608 with FORM "I608" 
	 CALL windecoration_i("I608") -- albo kd-758 

	SELECT proddept.* INTO l_rec_proddept.* 
	FROM proddept 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND dept_code = p_dept_code 
	AND dept_ind = glob_dept_ind 
	IF glob_dept_ind = 1 THEN 
		LET msgresp = kandoomsg("I",1303,"") 
		#1303 Enter Department Details - Esc TO Continue
	ELSE 
		LET msgresp = kandoomsg("I",1304,"") 
		#1304 Enter Sub Department Details - Esc TO Continue
	END IF 

	INPUT BY NAME l_rec_proddept.dept_code, 
	l_rec_proddept.desc_text 
	WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","IZD","input-l_rec_proddept-1") -- albo kd-505 

		BEFORE FIELD dept_code 
			IF p_dept_code IS NOT NULL THEN 
				NEXT FIELD NEXT 
			END IF 

		AFTER FIELD dept_code 
			IF l_rec_proddept.dept_code IS NULL THEN 
				LET msgresp = kandoomsg("I",9126,"") 
				#9126" Department must be Entered "
				NEXT FIELD dept_code 
			ELSE 
				SELECT * FROM proddept 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND dept_code = l_rec_proddept.dept_code 
				AND dept_ind = glob_dept_ind 
				IF status = 0 THEN 
					LET msgresp = kandoomsg("I",6014,"") 
					#6014" Warning: Department already exists "
					NEXT FIELD dept_code 
				END IF 
			END IF 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				IF p_dept_code IS NULL THEN 
					SELECT * FROM proddept 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND dept_code = l_rec_proddept.dept_code 
					AND dept_ind = glob_dept_ind 
					IF status = 0 THEN 
						LET msgresp = kandoomsg("I",9129,"") 
						#9129" Department already exists - Please Re Enter "
						NEXT FIELD dept_code 
					END IF 
				END IF 
			END IF 

			#      ON KEY (control-w)
			#         CALL kandoohelp("")

	END INPUT 


	CLOSE WINDOW i608 

	IF int_flag OR quit_flag THEN 
		LET quit_flag = false 
		LET int_flag = false 
		RETURN false 
	ELSE 
		IF p_dept_code IS NULL THEN #new RECORD 
			LET l_rec_proddept.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET l_rec_proddept.dept_ind = glob_dept_ind 
			INSERT INTO proddept VALUES (l_rec_proddept.*) 
			RETURN sqlca.sqlerrd[6] 
			ELSE #edit RECORD 
				UPDATE proddept 
				SET proddept.* = l_rec_proddept.* 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND dept_code = p_dept_code 
				AND dept_ind = glob_dept_ind 
				IF sqlca.sqlerrd[3] THEN 
					RETURN true 
				ELSE 
					RETURN false 
				END IF 
			END IF 
		END IF 

END FUNCTION 
