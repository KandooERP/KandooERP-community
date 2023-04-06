#Ledger Segment Not Set Up
#Run Prior: GZ3 - GL Flexible Structure Code

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

	Source code beautified by beautify.pl on 2020-01-03 14:29:04	$Id: $
}





############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 
GLOBALS 
	DEFINE glob_rec_structure RECORD LIKE structure.* 

END GLOBALS 

############################################################
# MAIN
#
#   GZJ - Consolidated Report Codes
############################################################
MAIN 
	DEFINE l_msgresp LIKE language.yes_flag 

	CALL setModuleId("GZJ") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_g_gl() #init g/gl general ledger module 

	CALL db_structure_get_rec_with_type("L") RETURNING glob_rec_structure.* 
	#   SELECT * INTO glob_rec_structure.* FROM structure
	#     WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
	#       AND type_ind = "L"

	IF db_structure_get_type_count("L") < 1 THEN 
		CALL fgl_winmessage("Ledger Segment Not Set Up","Ledger Segment Not Set Up\nRun GZ3 - GL Flexible Structure Code\nEXIT PROGRAM","error") 
		EXIT PROGRAM 
	END IF 

	OPEN WINDOW g452 with FORM "G452" 
	CALL windecoration_g("G452") 

	SELECT * INTO glob_rec_structure.* FROM structure 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND type_ind = "L" 
	IF status = NOTFOUND THEN 
		LET l_msgresp = kandoomsg("G",5019,"") 
		#5019 " Ledger Segment Not Set Up
	ELSE 
		WHILE select_consol() 
			CALL scan_consol() 
		END WHILE 
	END IF 
	CLOSE WINDOW g452 
END MAIN 

#		CALL fgl_winmessage("Ledger Segment Not Set Up","Ledger Segment Not Set Up\nRun GZ3 - GL Flexible Structure Code\nExit Program","error")
#	#Initial UI Init
#	CALL setModuleId("GZJ")
#	CALL ui_init(0)
#
#
#   defer interrupt
#   defer quit
#
#	CALL authenticate(getModuleId()) returning cmpy, whom
#   OPEN WINDOW G452 AT 2,10 WITH FORM "G452"
#		CALL windecoration_g("G452")
#
#   SELECT * into glob_rec_structure.* FROM structure
#     WHERE cmpy_code = cmpy
#       and type_ind = "L"
#   IF status = NOTFOUND THEN
#      LET l_msgresp = kandoomsg("G",5019,"")
#      #5019 " Ledger Segment Not Set Up
#   ELSE
#      WHILE select_consol()
#         CALL scan_consol()
#      END WHILE
#   END IF
#   CLOSE WINDOW G452
#END MAIN

FUNCTION select_consol() 
	DEFINE 
	query_text CHAR(300), 
	where_text CHAR(200) 
	DEFINE l_msgresp LIKE language.yes_flag 

	CLEAR FORM 
	LET l_msgresp = kandoomsg("G",1001,"") 
	#1001 " Enter Selection Criteria - ESC TO Continue"
	CONSTRUCT BY NAME where_text ON consol_code, 
	desc_text 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","GZJ","consolHeadQuery") 

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
		LET l_msgresp = kandoomsg("G",1002,"") 
		#1002 " Searching database - please wait"
		LET query_text = "SELECT * FROM consolhead ", 
		"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND ",where_text clipped," ", 
		"ORDER BY 2" 
		PREPARE s_consolhead FROM query_text 
		DECLARE c_consolhead CURSOR FOR s_consolhead 
		RETURN true 
	END IF 
END FUNCTION 


############################################################
# FUNCTION scan_consol()
#
#
############################################################
FUNCTION scan_consol() 
	DEFINE l_rec_consolhead RECORD LIKE consolhead.* 
	DEFINE l_arr_rec_consolhead array[100] OF 
	RECORD 
		scroll_flag CHAR(1), 
		consol_code LIKE consolhead.consol_code, 
		desc_text LIKE consolhead.desc_text 
	END RECORD 
	DEFINE l_scroll_flag CHAR(1) 
	DEFINE l_curr SMALLINT 
	DEFINE l_cnt SMALLINT 
	DEFINE l_idx SMALLINT 
	DEFINE l_del_cnt SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET l_idx = 0 
	FOREACH c_consolhead INTO l_rec_consolhead.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_consolhead[l_idx].consol_code = l_rec_consolhead.consol_code 
		LET l_arr_rec_consolhead[l_idx].desc_text = l_rec_consolhead.desc_text 
		#      IF l_idx = 100 THEN
		#         LET l_msgresp = kandoomsg("G",9119,l_idx)
		#         #9119 " First ??? Consolidation Groups Selected Only"
		#         EXIT FOREACH
		#      END IF
	END FOREACH 
	IF l_idx = 0 THEN 
		LET l_msgresp = kandoomsg("G",9120,"") 
		#9120" No Consolidation Groups satisfied selection criteria "
		LET l_idx = 1 
	END IF 
	OPTIONS INSERT KEY f1, 
	DELETE KEY f36 
	CALL set_count(l_idx) 
	LET l_msgresp = kandoomsg("G",1003,"") 
	#" F1 TO Add - F2 TO Delete - RETURN on line TO Edit "
	INPUT ARRAY l_arr_rec_consolhead WITHOUT DEFAULTS FROM sr_consolhead.* attribute(UNBUFFERED, append ROW = false, auto append = false) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GZJ","consolHeadList") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "EDIT" 

			IF l_arr_rec_consolhead[l_idx].consol_code IS NOT NULL THEN 
				LET l_rec_consolhead.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET l_rec_consolhead.consol_code = l_arr_rec_consolhead[l_idx].consol_code 
				LET l_rec_consolhead.desc_text = l_arr_rec_consolhead[l_idx].desc_text 
				LET l_curr = arr_curr() 
				LET l_cnt = arr_count() 
				CALL edit_ledger(l_rec_consolhead.*) 
				RETURNING l_rec_consolhead.* 
				IF l_rec_consolhead.consol_code IS NULL THEN 
					FOR l_idx = l_curr TO l_cnt 
						LET l_arr_rec_consolhead[l_idx].* = l_arr_rec_consolhead[l_idx+1].* 
						#IF scrn <= 10 THEN
						#   DISPLAY l_arr_rec_consolhead[l_idx].* TO sr_consolhead[scrn].*
						#
						#   LET scrn = scrn + 1
						#END IF
					END FOR 
					INITIALIZE l_arr_rec_consolhead[l_idx].* TO NULL 
				ELSE 
					LET l_arr_rec_consolhead[l_idx].consol_code = l_rec_consolhead.consol_code 
					LET l_arr_rec_consolhead[l_idx].desc_text = l_rec_consolhead.desc_text 
				END IF 
			END IF 
			NEXT FIELD scroll_flag 

		BEFORE FIELD scroll_flag 
			LET l_idx = arr_curr() 
			#LET scrn = scr_line()
			LET l_scroll_flag = l_arr_rec_consolhead[l_idx].scroll_flag 
			#DISPLAY l_arr_rec_consolhead[l_idx].*
			#     TO sr_consolhead[scrn].*

		AFTER FIELD scroll_flag 
			LET l_arr_rec_consolhead[l_idx].scroll_flag = l_scroll_flag 
			#DISPLAY l_arr_rec_consolhead[l_idx].scroll_flag
			#     TO sr_consolhead[scrn].scroll_flag

			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF l_arr_rec_consolhead[l_idx+1].consol_code IS NULL 
				OR arr_curr() >= arr_count() THEN 
					LET l_msgresp=kandoomsg("G",9001,"") 
					#9001 There no more rows...
					NEXT FIELD scroll_flag 
				END IF 
			END IF 

		BEFORE FIELD consol_code 
			IF l_arr_rec_consolhead[l_idx].consol_code IS NOT NULL THEN 
				LET l_rec_consolhead.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET l_rec_consolhead.consol_code = l_arr_rec_consolhead[l_idx].consol_code 
				LET l_rec_consolhead.desc_text = l_arr_rec_consolhead[l_idx].desc_text 
				LET l_curr = arr_curr() 
				LET l_cnt = arr_count() 
				CALL edit_ledger(l_rec_consolhead.*) 
				RETURNING l_rec_consolhead.* 
				IF l_rec_consolhead.consol_code IS NULL THEN 
					FOR l_idx = l_curr TO l_cnt 
						LET l_arr_rec_consolhead[l_idx].* = l_arr_rec_consolhead[l_idx+1].* 
						#IF scrn <= 10 THEN
						#   DISPLAY l_arr_rec_consolhead[l_idx].* TO sr_consolhead[scrn].*
						#
						#   LET scrn = scrn + 1
						#END IF
					END FOR 
					INITIALIZE l_arr_rec_consolhead[l_idx].* TO NULL 
				ELSE 
					LET l_arr_rec_consolhead[l_idx].consol_code = l_rec_consolhead.consol_code 
					LET l_arr_rec_consolhead[l_idx].desc_text = l_rec_consolhead.desc_text 
				END IF 
			END IF 
			NEXT FIELD scroll_flag 

		BEFORE INSERT 
			IF arr_curr() < arr_count() THEN 
				LET l_curr = arr_curr() 
				LET l_cnt = arr_count() 
				CALL add_ledger() 
				RETURNING l_rec_consolhead.* 
				IF l_rec_consolhead.consol_code IS NULL THEN 
					FOR l_idx = l_curr TO l_cnt 
						LET l_arr_rec_consolhead[l_idx].* = l_arr_rec_consolhead[l_idx+1].* 
						#IF scrn <= 10 THEN
						#   DISPLAY l_arr_rec_consolhead[l_idx].* TO sr_consolhead[scrn].*
						#
						#   LET scrn = scrn + 1
						#END IF
					END FOR 
					INITIALIZE l_arr_rec_consolhead[l_idx].* TO NULL 
				ELSE 
					LET l_arr_rec_consolhead[l_idx].consol_code = l_rec_consolhead.consol_code 
					LET l_arr_rec_consolhead[l_idx].desc_text = l_rec_consolhead.desc_text 
				END IF 
			ELSE 
				IF l_idx > 1 THEN 
					LET l_msgresp = kandoomsg("G",9001,"") 
					#9001 There are no more rows....
				END IF 
			END IF 

		ON KEY (F2) #delete marker 
			IF l_arr_rec_consolhead[l_idx].scroll_flag IS NULL THEN 
				LET l_arr_rec_consolhead[l_idx].scroll_flag = "*" 
				LET l_del_cnt = l_del_cnt + 1 
			ELSE 
				LET l_arr_rec_consolhead[l_idx].scroll_flag = NULL 
				LET l_del_cnt = l_del_cnt - 1 
			END IF 
			NEXT FIELD scroll_flag 
			#AFTER ROW
			#   DISPLAY l_arr_rec_consolhead[l_idx].*
			#        TO sr_consolhead[scrn].*

			#      ON KEY (control-w)
			#         CALL kandoohelp("")

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	ELSE 
		IF l_del_cnt > 0 THEN 
			LET l_msgresp = kandoomsg("G",8012,l_del_cnt) 
			#8012 Confirm TO Delete ",l_del_cnt," Consolidation Code(s)? (Y/N)"
			IF l_msgresp = "Y" THEN 
				FOR l_idx = 1 TO arr_count() 
					IF l_arr_rec_consolhead[l_idx].scroll_flag = "*" THEN 
						DELETE FROM consoldetl 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND consol_code = l_arr_rec_consolhead[l_idx].consol_code 
						DELETE FROM consolhead 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND consol_code = l_arr_rec_consolhead[l_idx].consol_code 
					END IF 
				END FOR 
			END IF 
		END IF 
	END IF 
END FUNCTION 



############################################################
# FUNCTION edit_ledger(p_rec_consolhead)
#
#
############################################################
FUNCTION edit_ledger(p_rec_consolhead) 
	DEFINE p_rec_consolhead RECORD LIKE consolhead.* 
	DEFINE l_rec_consolhead RECORD LIKE consolhead.* 
	DEFINE l_rec_consoldetl RECORD LIKE consoldetl.* 
	DEFINE l_arr_rec_consoldetl DYNAMIC ARRAY OF RECORD #array[300] 
		scroll_flag CHAR(1), 
		flex_code LIKE consoldetl.flex_code, 
		flex_desc LIKE validflex.desc_text 
	END RECORD 
	DEFINE l_scroll_flag CHAR(1) 

	DEFINE l_idx SMALLINT 
	DEFINE l_del_cnt SMALLINT 
	DEFINE i SMALLINT 

	DEFINE l_ins_mode SMALLINT 
	DEFINE x SMALLINT 
	DEFINE y SMALLINT 
	DEFINE temp_text CHAR(20) 
	DEFINE l_msgresp LIKE language.yes_flag 

	OPEN WINDOW g453 with FORM "G453" 
	CALL windecoration_g("G453") 

	LET l_rec_consolhead.* = p_rec_consolhead.* 
	DISPLAY BY NAME p_rec_consolhead.consol_code 

	INPUT BY NAME p_rec_consolhead.desc_text WITHOUT DEFAULTS 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GZJ","consolHeadEdit") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER FIELD desc_text 
			IF p_rec_consolhead.desc_text IS NULL THEN 
				LET l_msgresp = kandoomsg("G",9122,"") 
				#9122 " Consolidation Code Description must NOT be NULL
				NEXT FIELD desc_text 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET quit_flag = false 
		LET int_flag = false 
		CLOSE WINDOW g453 
		RETURN l_rec_consolhead.* 
	END IF 
	FOR i = 1 TO 300 
		INITIALIZE l_arr_rec_consoldetl[i].* TO NULL 
	END FOR 
	DECLARE c_consoldetl CURSOR FOR 
	SELECT * FROM consoldetl 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND consol_code = p_rec_consolhead.consol_code 
	ORDER BY flex_code 
	LET l_idx = 0 
	FOREACH c_consoldetl INTO l_rec_consoldetl.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_consoldetl[l_idx].flex_code = l_rec_consoldetl.flex_code 
		SELECT desc_text INTO l_arr_rec_consoldetl[l_idx].flex_desc FROM validflex 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND start_num = glob_rec_structure.start_num 
		AND flex_code = l_rec_consoldetl.flex_code 
		IF l_idx = 300 THEN 
			LET l_msgresp = kandoomsg("G",9125,l_idx) 
			#9125 " First ??? Consolidation Ledgers Selected Only"
			EXIT FOREACH 
		END IF 
	END FOREACH 
	OPTIONS INSERT KEY f1, 
	DELETE KEY f36 
	CALL set_count(l_idx) 
	LET l_msgresp = kandoomsg("G",1003,"") 
	#" F1 TO Add - F2 TO Delete - RETURN on line TO Edit "

	INPUT ARRAY l_arr_rec_consoldetl WITHOUT DEFAULTS FROM sr_consoldetl.* attribute(UNBUFFERED, append ROW = false, auto append = false) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GZJ","consolHeadListEdit") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield (flex_code) 
			LET temp_text = NULL 
			LET temp_text = show_flex(glob_rec_kandoouser.cmpy_code, 
			glob_rec_structure.start_num) 
			IF temp_text IS NOT NULL THEN 
				LET l_arr_rec_consoldetl[l_idx].flex_code = temp_text 
			END IF 
			NEXT FIELD flex_code 

		BEFORE FIELD scroll_flag 
			LET l_idx = arr_curr() 
			#LET scrn = scr_line()
			LET l_ins_mode = 0 
			LET l_scroll_flag = l_arr_rec_consoldetl[l_idx].scroll_flag 
			#DISPLAY l_arr_rec_consoldetl[l_idx].*
			#     TO sr_consoldetl[scrn].*

		AFTER FIELD scroll_flag 
			LET l_arr_rec_consoldetl[l_idx].scroll_flag = l_scroll_flag 
			#DISPLAY l_arr_rec_consoldetl[l_idx].scroll_flag
			#     TO sr_consoldetl[scrn].scroll_flag

			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF l_arr_rec_consoldetl[l_idx+1].flex_code IS NULL 
				OR arr_curr() >= arr_count() THEN 
					LET l_msgresp=kandoomsg("G",9001,"") 
					#9001 There no more rows...
					NEXT FIELD scroll_flag 
				END IF 
			END IF 

		BEFORE FIELD flex_code 
			IF NOT l_ins_mode 
			AND l_arr_rec_consoldetl[l_idx].flex_code IS NULL THEN 
				NEXT FIELD scroll_flag 
			END IF 

		AFTER FIELD flex_code 
			IF l_arr_rec_consoldetl[l_idx].flex_code IS NULL THEN 
				LET l_msgresp=kandoomsg("G",9114,"") 
				#9114 Ledger code must NOT be NULL - Try Window
				NEXT FIELD flex_code 
			END IF 
			SELECT desc_text INTO l_arr_rec_consoldetl[l_idx].flex_desc FROM validflex 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND start_num = glob_rec_structure.start_num 
			AND flex_code = l_arr_rec_consoldetl[l_idx].flex_code 
			IF status = NOTFOUND THEN 
				LET l_msgresp=kandoomsg("G",9115,"") 
				#9115 Ledger code does NOT exist - Try Window
				NEXT FIELD flex_code 
			END IF 
			FOR i = 1 TO arr_count() 
				IF i = l_idx THEN 
				ELSE 
					IF l_arr_rec_consoldetl[i].flex_code = l_arr_rec_consoldetl[l_idx].flex_code THEN 
						LET l_msgresp=kandoomsg("G",9127,"") 
						#9127 Ledger code already exists in this consolidation
						NEXT FIELD flex_code 
					END IF 
				END IF 
			END FOR 
			NEXT FIELD scroll_flag 

		BEFORE INSERT 
			IF arr_curr() < arr_count() THEN 
				INITIALIZE l_arr_rec_consoldetl[l_idx].* TO NULL 
				#DISPLAY l_arr_rec_consoldetl[l_idx].*
				#     TO sr_consoldetl[scrn].*

				LET l_ins_mode = 1 
				NEXT FIELD flex_code 
			ELSE 
				IF l_idx > 1 THEN 
					LET l_msgresp = kandoomsg("G",9001,"") 
					#9001 There are no more rows....
				END IF 
			END IF 

		ON KEY (F2) #delete marker 
			IF l_arr_rec_consoldetl[l_idx].scroll_flag IS NULL THEN 
				LET l_arr_rec_consoldetl[l_idx].scroll_flag = "*" 
				LET l_del_cnt = l_del_cnt + 1 
			ELSE 
				LET l_arr_rec_consoldetl[l_idx].scroll_flag = NULL 
				LET l_del_cnt = l_del_cnt - 1 
			END IF 
			NEXT FIELD scroll_flag 
			#AFTER ROW
			#   DISPLAY l_arr_rec_consoldetl[l_idx].*
			#        TO sr_consoldetl[scrn].*

			#      ON KEY (control-w)
			#         CALL kandoohelp("")
	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		CLOSE WINDOW g453 
		RETURN l_rec_consolhead.* 
	END IF 

	IF l_del_cnt > 0 THEN 
		LET l_msgresp = kandoomsg("G",8013,l_del_cnt) 
		#8013 Confirm TO Delete ",l_del_cnt," Consolidation Ledger(s)? (Y/N)"
		#
		# coded differently because we delete all rows AND re-INSERT the
		# ones we need - User confirmation IS maintained FOR standards...
	END IF 

	DELETE FROM consoldetl 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND consol_code = p_rec_consolhead.consol_code 
	INITIALIZE l_rec_consoldetl.* TO NULL 
	LET l_rec_consoldetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET l_rec_consoldetl.consol_code = p_rec_consolhead.consol_code 

	FOR l_idx = 1 TO arr_count() 
		IF (l_arr_rec_consoldetl[l_idx].scroll_flag IS NULL AND 
		l_arr_rec_consoldetl[l_idx].flex_code IS NOT null) 
		OR (l_arr_rec_consoldetl[l_idx].scroll_flag IS NOT NULL AND 
		l_msgresp = "N") THEN 
			LET l_rec_consoldetl.flex_code = l_arr_rec_consoldetl[l_idx].flex_code 
			INSERT INTO consoldetl VALUES (l_rec_consoldetl.*) 
		END IF 
	END FOR 
	SELECT unique 1 FROM consoldetl 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND consol_code = p_rec_consolhead.consol_code 
	IF status = NOTFOUND THEN 
		DELETE FROM consolhead 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND consol_code = p_rec_consolhead.consol_code 
		INITIALIZE p_rec_consolhead.* TO NULL 
	ELSE 
		UPDATE consolhead 
		SET consolhead.* = p_rec_consolhead.* 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND consol_code = p_rec_consolhead.consol_code 
	END IF 

	CLOSE WINDOW g453 

	RETURN p_rec_consolhead.* 
END FUNCTION 


############################################################
# FUNCTION add_ledger()
#
#
############################################################
FUNCTION add_ledger() 
	DEFINE l_rec_consolhead RECORD LIKE consolhead.* 
	DEFINE l_rec_consoldetl RECORD LIKE consoldetl.* 
	DEFINE l_arr_rec_consoldetl array[300] OF RECORD 
		scroll_flag CHAR(1), 
		flex_code LIKE consoldetl.flex_code, 
		flex_desc LIKE validflex.desc_text 
	END RECORD 
	DEFINE l_scroll_flag CHAR(1) 
	DEFINE l_idx SMALLINT 
	DEFINE l_del_cnt SMALLINT 
	DEFINE l_ins_mode SMALLINT 
	DEFINE i SMALLINT 
	DEFINE x SMALLINT 
	DEFINE y SMALLINT 
	DEFINE temp_text CHAR(20) 
	DEFINE l_msgresp LIKE language.yes_flag 

	OPEN WINDOW g453 with FORM "G453" 
	CALL windecoration_g("G453") 

	INITIALIZE l_rec_consolhead.* TO NULL 
	LET l_rec_consolhead.cmpy_code = glob_rec_kandoouser.cmpy_code 

	INPUT BY NAME l_rec_consolhead.consol_code, 
	l_rec_consolhead.desc_text WITHOUT DEFAULTS 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GZJ","consolHeadNew") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 




		AFTER FIELD consol_code 
			IF l_rec_consolhead.consol_code IS NULL THEN 
				LET l_msgresp = kandoomsg("G",9123,"") 
				#9123 " Consolidation Code must NOT be NULL
				NEXT FIELD consol_code 
			END IF 
			SELECT unique 1 FROM consolhead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND consol_code = l_rec_consolhead.consol_code 
			IF status != NOTFOUND THEN 
				LET l_msgresp = kandoomsg("G",9124,"") 
				#9124 " Consolidation Code already exists
				NEXT FIELD consol_code 
			END IF 

		AFTER FIELD desc_text 
			IF l_rec_consolhead.desc_text IS NULL THEN 
				LET l_msgresp = kandoomsg("G",9122,"") 
				#9122 " Consolidation Code Description must NOT be NULL
				NEXT FIELD desc_text 
			END IF 

		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN 
				IF l_rec_consolhead.consol_code IS NULL THEN 
					LET l_msgresp = kandoomsg("G",9123,"") 
					#9123 " Consolidation Code must NOT be NULL
					NEXT FIELD consol_code 
				END IF 
				IF l_rec_consolhead.desc_text IS NULL THEN 
					LET l_msgresp = kandoomsg("G",9122,"") 
					#9122 " Consolidation Code Description must NOT be NULL
					NEXT FIELD desc_text 
				END IF 
			END IF 

			#      ON KEY (control-w)
			#         CALL kandoohelp("")

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET quit_flag = false 
		LET int_flag = false 
		INITIALIZE l_rec_consolhead.* TO NULL 
		CLOSE WINDOW g453 
		RETURN l_rec_consolhead.* 
	END IF 

	FOR i = 1 TO 300 
		INITIALIZE l_arr_rec_consoldetl[i].* TO NULL 
	END FOR 
	OPTIONS INSERT KEY f1, 
	DELETE KEY f36 
	LET l_idx = 0 
	CALL set_count(l_idx) 
	LET l_msgresp = kandoomsg("G",1003,"") 
	#" F1 TO Add - F2 TO Delete - RETURN on line TO Edit "


	INPUT ARRAY l_arr_rec_consoldetl WITHOUT DEFAULTS FROM sr_consoldetl.* attribute(UNBUFFERED, append ROW = false, auto append = false) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GZJ","consolHeadListNew") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield (flex_code) 
			LET temp_text = NULL 
			LET temp_text = show_flex(glob_rec_kandoouser.cmpy_code, 
			glob_rec_structure.start_num) 
			IF temp_text IS NOT NULL THEN 
				LET l_arr_rec_consoldetl[l_idx].flex_code = temp_text 
			END IF 
			NEXT FIELD flex_code 

		BEFORE ROW 
			LET l_idx = arr_curr() 

		BEFORE FIELD scroll_flag 
			LET l_idx = arr_curr() 
			#LET scrn = scr_line()
			LET l_ins_mode = 0 
			LET l_scroll_flag = l_arr_rec_consoldetl[l_idx].scroll_flag 
			#DISPLAY l_arr_rec_consoldetl[l_idx].*
			#     TO sr_consoldetl[scrn].*

		AFTER FIELD scroll_flag 
			LET l_arr_rec_consoldetl[l_idx].scroll_flag = l_scroll_flag 
			#DISPLAY l_arr_rec_consoldetl[l_idx].scroll_flag
			#     TO sr_consoldetl[scrn].scroll_flag

			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF l_arr_rec_consoldetl[l_idx+1].flex_code IS NULL 
				OR arr_curr() >= arr_count() THEN 
					LET l_msgresp=kandoomsg("G",9001,"") 
					#9001 There no more rows...
					NEXT FIELD scroll_flag 
				END IF 
			END IF 

		BEFORE FIELD flex_code 
			IF NOT l_ins_mode 
			AND l_arr_rec_consoldetl[l_idx].flex_code IS NULL THEN 
				NEXT FIELD scroll_flag 
			END IF 

		AFTER FIELD flex_code 
			IF l_arr_rec_consoldetl[l_idx].flex_code IS NULL THEN 
				LET l_msgresp=kandoomsg("G",9114,"") 
				#9114 Ledger code must NOT be NULL - Try Window
				NEXT FIELD flex_code 
			END IF 
			SELECT desc_text INTO l_arr_rec_consoldetl[l_idx].flex_desc FROM validflex 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND start_num = glob_rec_structure.start_num 
			AND flex_code = l_arr_rec_consoldetl[l_idx].flex_code 
			IF status = NOTFOUND THEN 
				LET l_msgresp=kandoomsg("G",9115,"") 
				#9115 Ledger code does NOT exist - Try Window
				NEXT FIELD flex_code 
			END IF 
			FOR i = 1 TO arr_count() 
				IF i = l_idx THEN 
				ELSE 
					IF l_arr_rec_consoldetl[i].flex_code = l_arr_rec_consoldetl[l_idx].flex_code THEN 
						LET l_msgresp=kandoomsg("G",9127,"") 
						#9127 Ledger code already exists in this consolidation
						NEXT FIELD flex_code 
					END IF 
				END IF 
			END FOR 
			NEXT FIELD scroll_flag 

		BEFORE INSERT 
			LET l_idx = arr_curr() 
			DISPLAY "arr_count()", arr_count() 
			DISPLAY "arr_curr()", arr_curr() 
			DISPLAY "l_idx", l_idx 
			IF arr_curr() <= arr_count() THEN 
				INITIALIZE l_arr_rec_consoldetl[l_idx].* TO NULL 
				#DISPLAY l_arr_rec_consoldetl[l_idx].*
				#     TO sr_consoldetl[scrn].*

				LET l_ins_mode = 1 
				NEXT FIELD flex_code 
			ELSE 
				IF l_idx > 1 THEN 
					LET l_msgresp = kandoomsg("G",9001,"") 
					#9001 There are no more rows....
				END IF 
			END IF 

		ON KEY (F2) #delete marker 
			IF l_arr_rec_consoldetl[l_idx].scroll_flag IS NULL THEN 
				LET l_arr_rec_consoldetl[l_idx].scroll_flag = "*" 
				LET l_del_cnt = l_del_cnt + 1 
			ELSE 
				LET l_arr_rec_consoldetl[l_idx].scroll_flag = NULL 
				LET l_del_cnt = l_del_cnt - 1 
			END IF 
			NEXT FIELD scroll_flag 
			#AFTER ROW
			#   DISPLAY l_arr_rec_consoldetl[l_idx].*
			#        TO sr_consoldetl[scrn].*

			#      ON KEY (control-w)
			#         CALL kandoohelp("")
	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		INITIALIZE l_rec_consolhead.* TO NULL 
	ELSE 
		IF l_del_cnt > 0 THEN 
			LET l_msgresp = kandoomsg("G",8013,l_del_cnt) 
			#8013 Confirm TO Delete ",l_del_cnt," Consolidation Ledger(s)? (Y/N)"
			#
			# coded differently because we delete all rows AND re-INSERT the
			# ones we need - User confirmation IS maintained FOR standards...
		END IF 

		INITIALIZE l_rec_consoldetl.* TO NULL 
		LET l_rec_consoldetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET l_rec_consoldetl.consol_code = l_rec_consolhead.consol_code 
		FOR l_idx = 1 TO arr_count() 
			IF (l_arr_rec_consoldetl[l_idx].scroll_flag IS NULL AND 
			l_arr_rec_consoldetl[l_idx].flex_code IS NOT null) 
			OR (l_arr_rec_consoldetl[l_idx].scroll_flag IS NOT NULL AND 
			l_msgresp = "N") THEN 
				LET l_rec_consoldetl.flex_code = l_arr_rec_consoldetl[l_idx].flex_code 
				INSERT INTO consoldetl VALUES (l_rec_consoldetl.*) 
			END IF 
		END FOR 

		SELECT unique 1 FROM consoldetl 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND consol_code = l_rec_consolhead.consol_code 
		IF status = NOTFOUND THEN 
			INITIALIZE l_rec_consolhead.* TO NULL 
		ELSE 
			INSERT INTO consolhead VALUES (l_rec_consolhead.*) 
		END IF 
	END IF 

	CLOSE WINDOW g453 

	RETURN l_rec_consolhead.* 
END FUNCTION 


