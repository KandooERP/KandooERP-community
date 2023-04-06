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

	Source code beautified by beautify.pl on 2020-01-03 18:54:43	$Id: $
}
{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module - U1W.4gl
# Purpose - Verify kandoomsg AND menu tables on site vs standard

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../utility/U_UT_GLOBALS.4gl" 
GLOBALS 
	DEFINE loadfile CHAR(80)
	DEFINE loaddir CHAR(80)
	DEFINE ret_code SMALLINT
	DEFINE pa_menu3 array[1000] OF RECORD 
		menu1_code LIKE menu3.menu1_code, 
		menu2_code LIKE menu3.menu2_code, 
		menu3_code LIKE menu3.menu3_code, 
		name_text LIKE menu3.name_text, 
		run_text LIKE menu3.run_text, 
		include_flag CHAR(1) 
	END RECORD 
	DEFINE ans CHAR(1) 
	DEFINE x SMALLINT
	DEFINE y SMALLINT
	DEFINE p SMALLINT
	DEFINE q SMALLINT
	DEFINE r SMALLINT
	DEFINE s SMALLINT	
	DEFINE stat_1 SMALLINT
	DEFINE stat_2 SMALLINT	
	DEFINE idx SMALLINT	 
	DEFINE pr_company RECORD LIKE company.* 
	DEFINE select_text CHAR(1200)
	DEFINE where_part CHAR(1200)
	 
END GLOBALS 


MAIN 
	DEFINE 
	pr_module CHAR(1), 
	pr_path_name,pr_runner CHAR(80), 
	pr_name_text LIKE menu1.name_text 
	DEFINE l_msgresp LIKE language.yes_flag

	CALL setModuleId("U1W") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_u_ut() #init utility module 

	OPEN WINDOW u206 with FORM "U206" 
	CALL windecoration_u("U206") 

	SELECT * INTO pr_company.* FROM company 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF pr_company.module_text = " " 
	OR pr_company.module_text IS NULL THEN 
		LET l_msgresp = kandoomsg("U",9036,"") 
		#9036 " No modules configured FOR this company - Refer GZC "
		EXIT program 
	END IF 
	LET pr_company.module_text = upshift(pr_company.module_text) 
	CALL create_table("menu1","t_menu1","","Y") 
	CALL create_table("menu2","t_menu2","","Y") 
	CALL create_table("menu3","t_menu3","","Y") 
	CALL create_table("kandoomsg","t_kandoomsg","","Y") 
	CREATE unique INDEX t_menu2_key ON t_menu2(menu1_code, 
	menu2_code) 
	CREATE unique INDEX t_menu3_key ON t_menu3(menu1_code, 
	menu2_code, 
	menu3_code) 
	CREATE unique INDEX t_kandoomsg_key ON t_kandoomsg(source_ind, 
	msg_num, 
	language_code) 
	CREATE temp TABLE t_kandoomsg2 (source_ind CHAR(1), 
	msg_num INTEGER, 
	msg_ind CHAR(1), 
	format_ind CHAR(1), 
	language_code CHAR(3), 
	msg1_text CHAR(70), 
	msg2_text CHAR(70), 
	action_flag CHAR(1), 
	include_flag CHAR(1)) 
	CREATE unique INDEX kandoomsg2_key ON t_kandoomsg2(source_ind, 
	msg_num, 
	language_code) 
	LET loaddir = fgl_getenv("KANDOODIR") 
	INPUT loaddir WITHOUT DEFAULTS FROM loaddir 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","U1W","input-loaddir") 
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		AFTER FIELD loaddir 
			WHENEVER ERROR CONTINUE 
			LET pr_path_name = loaddir clipped, "/tempfile" 
			UNLOAD TO pr_path_name 
			SELECT * FROM t_kandoomsg 
			IF status = -806 THEN 
				LET l_msgresp=kandoomsg("G",9140,"") 
				#9140 " Directory NOT found - Check UNIX path AND re-enter"
				WHENEVER ERROR stop 
				NEXT FIELD loaddir 
			END IF 
			WHENEVER ERROR stop 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	ELSE 

		MENU " Library Load" 
			BEFORE MENU 
				CALL publish_toolbar("kandoo","U1W","menu-library_load") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 


			COMMAND "Menus" " Load new menu structure" 
				DELETE FROM t_menu1 WHERE 1=1 
				DELETE FROM t_menu2 WHERE 1=1 
				DELETE FROM t_menu3 WHERE 1=1 
				LET loadfile = loaddir clipped,"/test/data/menu1" 
				LOAD FROM loadfile INSERT INTO t_menu1 
				LET loadfile = loaddir clipped,"/test/data/menu2" 
				LOAD FROM loadfile INSERT INTO t_menu2 
				LET loadfile = loaddir clipped,"/test/data/menu3" 
				LOAD FROM loadfile INSERT INTO t_menu3 

				OPEN WINDOW w1_u1w with FORM "U999" 
				CALL windecoration_u("U999") 

				DISPLAY "Verifying " TO lbinfo1 
				LET q = 0 
				FOR p = 1 TO 26 
					IF pr_company.module_text[p] != " " THEN 
						LET pr_module = pr_company.module_text[p] 
						LET pr_name_text = NULL 
						SELECT name_text INTO pr_name_text FROM menu1 
						WHERE menu1_code = pr_module 
						DISPLAY pr_name_text clipped," menus " at 1,12 

						CALL menu1_check(pr_module) 
						CALL menu2_check(pr_module) 
						CALL menu3_check(pr_module) 
					END IF 
				END FOR 
				CLOSE WINDOW w1_u1w 
			COMMAND "Message" " Load new max MESSAGEs" 
				DELETE FROM t_kandoomsg2 
				DELETE FROM t_kandoomsg 
				LET loadfile = loaddir clipped,"/test/data/kandoomsg" 
				LOAD FROM loadfile INSERT INTO t_kandoomsg 
				CALL kandoomsg_check() 
			COMMAND KEY(interrupt,"E") "Exit" " Exit TO main menu" 
				EXIT MENU 
			COMMAND KEY (control-w) 
				CALL kandoohelp("") 
		END MENU 
	END IF 
	CLOSE WINDOW u206 
END MAIN 


FUNCTION kandoomsg_check() 
	DEFINE 
	pr_kandoomsg RECORD LIKE kandoomsg.*, 
	ps_kandoomsg RECORD LIKE kandoomsg.*, 
	pa_kandoomsg array[1500] OF RECORD 
		source_ind LIKE kandoomsg.source_ind, 
		msg_num LIKE kandoomsg.msg_num, 
		msg_ind LIKE kandoomsg.msg_ind, 
		format_ind LIKE kandoomsg.format_ind, 
		language_code LIKE kandoomsg.language_code, 
		msg1_text LIKE kandoomsg.msg1_text, 
		msg2_text LIKE kandoomsg.msg2_text, 
		action_flag CHAR(1), 
		include_flag CHAR(1) 
	END RECORD, 
	cont_while SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag
	
	LET l_msgresp = kandoomsg("U",1049,"") 
	DECLARE check_msg CURSOR FOR 
	SELECT * FROM t_kandoomsg 
	LET idx = 0 
	FOREACH check_msg INTO pr_kandoomsg.* 
		SELECT * INTO ps_kandoomsg.* FROM kandoomsg 
		WHERE source_ind = pr_kandoomsg.source_ind 
		AND msg_num = pr_kandoomsg.msg_num 
		AND language_code = pr_kandoomsg.language_code 
		IF status THEN 
			LET idx = idx + 1 
			LET pa_kandoomsg[idx].source_ind = pr_kandoomsg.source_ind 
			LET pa_kandoomsg[idx].msg_num = pr_kandoomsg.msg_num 
			LET pa_kandoomsg[idx].msg_ind = pr_kandoomsg.msg_ind 
			LET pa_kandoomsg[idx].format_ind = pr_kandoomsg.format_ind 
			LET pa_kandoomsg[idx].language_code = pr_kandoomsg.language_code 
			LET pa_kandoomsg[idx].msg1_text = pr_kandoomsg.msg1_text 
			LET pa_kandoomsg[idx].msg2_text = pr_kandoomsg.msg2_text 
			LET pa_kandoomsg[idx].action_flag = "N" {no action} 
			LET pa_kandoomsg[idx].include_flag = "Y" {new} 
		ELSE 
			IF pr_kandoomsg.msg_ind != ps_kandoomsg.msg_ind OR 
			pr_kandoomsg.format_ind != ps_kandoomsg.format_ind OR 
			pr_kandoomsg.msg1_text != ps_kandoomsg.msg1_text OR 
			pr_kandoomsg.msg2_text != ps_kandoomsg.msg2_text THEN 
				LET idx = idx + 1 
				LET pa_kandoomsg[idx].source_ind = pr_kandoomsg.source_ind 
				LET pa_kandoomsg[idx].msg_num = pr_kandoomsg.msg_num 
				LET pa_kandoomsg[idx].msg_ind = pr_kandoomsg.msg_ind 
				LET pa_kandoomsg[idx].format_ind = pr_kandoomsg.format_ind 
				LET pa_kandoomsg[idx].language_code = pr_kandoomsg.language_code 
				LET pa_kandoomsg[idx].msg1_text = pr_kandoomsg.msg1_text 
				LET pa_kandoomsg[idx].msg2_text = pr_kandoomsg.msg2_text 
				LET pa_kandoomsg[idx].action_flag = "C" {changed} 
				LET pa_kandoomsg[idx].include_flag = "Y" {no action} 
			END IF 
		END IF 
	END FOREACH 
	# check site kandoomsg vs max development kandoomsg
	LET l_msgresp = kandoomsg("U",1050,"") 
	DECLARE check_msg1 CURSOR FOR 
	SELECT * FROM kandoomsg 
	FOREACH check_msg1 INTO pr_kandoomsg.* 
		SELECT * INTO ps_kandoomsg.* FROM t_kandoomsg 
		WHERE source_ind = pr_kandoomsg.source_ind 
		AND msg_num = pr_kandoomsg.msg_num 
		AND language_code = pr_kandoomsg.language_code 
		IF status THEN 
			LET idx = idx + 1 
			LET pa_kandoomsg[idx].source_ind = pr_kandoomsg.source_ind 
			LET pa_kandoomsg[idx].msg_num = pr_kandoomsg.msg_num 
			LET pa_kandoomsg[idx].msg_ind = pr_kandoomsg.msg_ind 
			LET pa_kandoomsg[idx].format_ind = pr_kandoomsg.format_ind 
			LET pa_kandoomsg[idx].language_code = pr_kandoomsg.language_code 
			LET pa_kandoomsg[idx].msg1_text = pr_kandoomsg.msg1_text 
			LET pa_kandoomsg[idx].msg2_text = pr_kandoomsg.msg2_text 
			LET pa_kandoomsg[idx].action_flag = "D" {delete} 
			LET pa_kandoomsg[idx].include_flag = "Y" {no action} 
		END IF 
	END FOREACH 
	FOR s = 1 TO idx 
		INSERT INTO t_kandoomsg2 VALUES (pa_kandoomsg[s].*) 
		INITIALIZE pa_kandoomsg[s].* TO NULL 
	END FOR 

	OPEN WINDOW u207 with FORM "U207" 
	CALL windecoration_u("U207") 

	WHILE (true) 
		CLEAR FORM 
		LET cont_while = false 
		LET l_msgresp = kandoomsg("U",1001,"") 
		CONSTRUCT BY NAME where_part ON msg_num, 
		source_ind, 
		msg_ind, 
		format_ind, 
		language_code, 
		action_flag, 
		include_flag, 
		msg1_text, 
		msg2_text 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","U1W","construct-kandoomsg2") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END CONSTRUCT 


		IF int_flag OR quit_flag THEN 
			EXIT WHILE 
		END IF 
		LET select_text = "SELECT * FROM t_kandoomsg2 ", 
		"WHERE ",where_part clipped," ", 
		"ORDER BY source_ind,msg_num " 
		PREPARE select_msg FROM select_text 
		DECLARE msg_curs CURSOR FOR select_msg 
		LET idx = 1 
		FOREACH msg_curs INTO pa_kandoomsg[idx].* 
			LET idx = idx + 1 
		END FOREACH 
		LET idx = idx - 1 
		IF idx > 0 THEN 
			WHILE (true) 

				CALL set_count(idx) 
				LET l_msgresp = kandoomsg("U",1048,"") 
				INPUT ARRAY pa_kandoomsg WITHOUT DEFAULTS FROM sr_kandoomsg.* 
					BEFORE INPUT 
						CALL publish_toolbar("kandoo","U1W","input-arr-kandoomsg") 
					ON ACTION "WEB-HELP" 
						CALL onlinehelp(getmoduleid(),null) 
					ON ACTION "actToolbarManager" 
						CALL setuptoolbar() 


					BEFORE ROW 
						LET idx = arr_curr() 

					ON KEY (F7) {accept all} 
						FOR r = 1 TO arr_count() 
							IF pa_kandoomsg[r].include_flag != " " AND 
							pa_kandoomsg[r].include_flag IS NOT NULL THEN 
								LET pa_kandoomsg[r].include_flag = "Y" 
							END IF 
						END FOR 
						IF arr_count() < 4 THEN 
							LET y = arr_count() 
						ELSE 
							LET y = 4 
						END IF 
						FOR x = 1 TO y 
							DISPLAY "Y" TO sr_kandoomsg[x].include_flag 
						END FOR 

					ON KEY (control-v) 
						CASE pa_kandoomsg[idx].action_flag 
							WHEN "C" 
								OPEN WINDOW show_it with FORM "U201" 
								CALL windecoration_u("U201") 

								SELECT * INTO pr_kandoomsg.* FROM kandoomsg 
								WHERE source_ind = pa_kandoomsg[idx].source_ind 
								AND msg_num = pa_kandoomsg[idx].msg_num 
								AND language_code = pa_kandoomsg[idx].language_code 
								DISPLAY BY NAME pr_kandoomsg.source_ind, 
								pr_kandoomsg.msg_num, 
								pr_kandoomsg.msg_ind, 
								pr_kandoomsg.format_ind, 
								pr_kandoomsg.msg1_text, 
								pr_kandoomsg.msg2_text, 
								pr_kandoomsg.help_num 
								CALL eventsuspend() # LET l_msgresp = kandoomsg("U",1,"") 
								CLOSE WINDOW show_it 

							WHEN "D" 
								LET l_msgresp = kandoomsg("U",9037,"") 
								#9037 "This IS the current entry"

							WHEN "N" 
								LET l_msgresp = kandoomsg("U",9038,"") 
								#9038 "This IS a NEW option"
						END CASE 

					AFTER INPUT 
						LET idx = arr_count() 

					ON KEY (control-w) 
						CALL kandoohelp("") 

				END INPUT 

				IF int_flag OR quit_flag THEN 
					LET int_flag = false 
					LET quit_flag = false 
					FOR s = 1 TO idx 
						INITIALIZE pa_kandoomsg[s].* TO NULL 
					END FOR 
					LET cont_while = true 
					EXIT WHILE 
				END IF 
				LET y = 0 
				FOR x = 1 TO idx 
					IF pa_kandoomsg[x].include_flag = "Y" THEN 
						LET y = y + 1 
					ELSE 
						DELETE FROM t_kandoomsg2 
						WHERE source_ind = pa_kandoomsg[idx].source_ind 
						AND msg_num = pa_kandoomsg[idx].msg_num 
						AND language_code = pa_kandoomsg[idx].language_code 
					END IF 
				END FOR 
				IF y = 0 THEN 
					LET l_msgresp = kandoomsg("U",9039,"kandoomsg") 
					#9039 "No changes made TO kandoomsg"
					FOR s = 1 TO idx 
						INITIALIZE pa_kandoomsg[s].* TO NULL 
					END FOR 
					LET cont_while = true 
					EXIT WHILE 
				END IF 
				IF kandoomsg("U",8017,"") != "Y" THEN 
					CONTINUE WHILE 
				ELSE 
					EXIT WHILE 
				END IF 
			END WHILE 
			IF cont_while THEN 
				CONTINUE WHILE 
			END IF 
			FOR idx = 1 TO arr_count() 
				IF pa_kandoomsg[idx].include_flag = "Y" THEN 
					SELECT * INTO pr_kandoomsg.* FROM kandoomsg 
					WHERE source_ind = pa_kandoomsg[idx].source_ind 
					AND msg_num = pa_kandoomsg[idx].msg_num 
					AND language_code = pa_kandoomsg[idx].language_code 
					LET stat_1 = status # in CURRENT kandoomsg TABLE 
					SELECT * 
					INTO ps_kandoomsg.* 
					FROM t_kandoomsg 
					WHERE source_ind = pa_kandoomsg[idx].source_ind 
					AND msg_num = pa_kandoomsg[idx].msg_num 
					AND language_code = pa_kandoomsg[idx].language_code 
					LET stat_2 = status # in dev kandoomsg TABLE 
					IF stat_1 AND NOT stat_2 THEN {in max AND NOT in site} 
						SELECT * 
						INTO pr_kandoomsg.* 
						FROM t_kandoomsg 
						WHERE source_ind = pa_kandoomsg[idx].source_ind 
						AND msg_num = pa_kandoomsg[idx].msg_num 
						AND language_code = pa_kandoomsg[idx].language_code 
						INSERT INTO kandoomsg VALUES (pr_kandoomsg.*) 
					END IF 
					IF NOT stat_1 AND NOT stat_2 THEN {in both - update} 
						UPDATE kandoomsg SET * = ps_kandoomsg.* 
						WHERE source_ind = pa_kandoomsg[idx].source_ind 
						AND msg_num = pa_kandoomsg[idx].msg_num 
						AND language_code = pa_kandoomsg[idx].language_code 
					END IF 
					IF NOT stat_1 AND stat_2 THEN {in site NOT in dev} 
						DELETE FROM kandoomsg 
						WHERE source_ind = pa_kandoomsg[idx].source_ind 
						AND msg_num = pa_kandoomsg[idx].msg_num 
						AND language_code = pa_kandoomsg[idx].language_code 
					END IF 
					DELETE FROM t_kandoomsg2 
					WHERE source_ind = pa_kandoomsg[idx].source_ind 
					AND msg_num = pa_kandoomsg[idx].msg_num 
					AND language_code = pa_kandoomsg[idx].language_code 
				ELSE {flag was n - DELETE the row, no action} 
					DELETE FROM t_kandoomsg2 
					WHERE source_ind = pa_kandoomsg[idx].source_ind 
					AND msg_num = pa_kandoomsg[idx].msg_num 
					AND language_code = pa_kandoomsg[idx].language_code 
				END IF 
			END FOR 
		ELSE 
			CONTINUE WHILE 
		END IF 
	END WHILE 
	CLOSE WINDOW u207 
END FUNCTION 


FUNCTION menu1_check(module) 
	DEFINE 
	pa_menu1 array[50] OF RECORD 
		menu1_code LIKE menu3.menu1_code, 
		menu2_code LIKE menu3.menu2_code, 
		menu3_code LIKE menu3.menu3_code, 
		name_text LIKE menu1.name_text, 
		run_text LIKE menu3.run_text, 
		include_flag CHAR(1) 
	END RECORD, 
	ps_menu1, pr_menu1 RECORD LIKE menu1.*, 
	module CHAR(1) 
	DEFINE l_msgresp LIKE language.yes_flag
	
	DECLARE check_curs2 CURSOR FOR 
	SELECT * FROM t_menu1 
	WHERE menu1_code = module 
	ORDER BY menu1_code 
	LET idx = 0 
	FOREACH check_curs2 INTO pr_menu1.* 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			RETURN 
		END IF 
		SELECT * INTO ps_menu1.* FROM menu1 
		WHERE menu1_code = pr_menu1.menu1_code 
		IF status THEN 
			LET idx = idx + 1 
			LET pa_menu1[idx].menu1_code = pr_menu1.menu1_code 
			LET pa_menu1[idx].menu2_code = NULL 
			LET pa_menu1[idx].menu3_code = NULL 
			LET pa_menu1[idx].name_text = pr_menu1.name_text 
			LET pa_menu1[idx].include_flag = "N" # new option 
		ELSE 
			#pr_ = current menu's
			#ps_ = standard menus
			IF pr_menu1.name_text != ps_menu1.name_text THEN 
				LET idx = idx + 1 
				LET pa_menu1[idx].menu1_code = pr_menu1.menu1_code 
				LET pa_menu1[idx].menu2_code = NULL 
				LET pa_menu1[idx].menu3_code = NULL 
				LET pa_menu1[idx].name_text = pr_menu1.name_text 
				LET pa_menu1[idx].include_flag = "C" # change option 
			END IF 
		END IF 
	END FOREACH 
	# check site menu's vs development menus
	DECLARE check_curs3 CURSOR FOR 
	SELECT * FROM menu1 
	WHERE menu1_code = module 
	ORDER BY menu1_code 
	FOREACH check_curs3 INTO pr_menu1.* 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			RETURN 
		END IF 
		#pr_ = current menu's
		#ps_ = standard menus
		SELECT * INTO ps_menu1.* FROM t_menu1 
		WHERE menu1_code = pr_menu1.menu1_code 
		IF status THEN 
			LET idx = idx + 1 
			LET pa_menu1[idx].menu1_code = pr_menu1.menu1_code 
			LET pa_menu1[idx].menu2_code = NULL 
			LET pa_menu1[idx].menu3_code = NULL 
			LET pa_menu1[idx].name_text = pr_menu1.name_text 
			LET pa_menu1[idx].include_flag = "D" # DELETE option 
		END IF 
	END FOREACH 

	IF idx > 0 THEN 
		OPEN WINDOW wu205 with FORM "U205" 
		CALL windecoration_u("U205") 

		WHILE (true) 
			CALL set_count(idx) 
			LET l_msgresp = kandoomsg("U",1048,"") 
			INPUT ARRAY pa_menu1 WITHOUT DEFAULTS FROM sr_menu3.* 
				BEFORE INPUT 
					CALL publish_toolbar("kandoo","U1W","input-arr-menu1") 
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
				BEFORE ROW 
					LET idx = arr_curr() 
				ON KEY (F7) {accept all} 
					FOR r = 1 TO arr_count() 
						LET pa_menu1[r].include_flag = "Y" 
					END FOR 
					LET y = 10 
					IF arr_count() < 10 THEN 
						LET y = arr_count() 
					END IF 
					FOR x = 1 TO y 
						DISPLAY "Y" TO sr_menu3[x].include_flag 

					END FOR 
				ON KEY (control-v) 
					CASE pa_menu1[idx].include_flag 
						WHEN "C" 
							OPEN WINDOW show_it with FORM "U999" 
							CALL windecoration_u("U999") 
							SELECT * INTO pr_menu1.* FROM menu1 
							WHERE menu1_code = pa_menu1[idx].menu1_code 
							DISPLAY "Current Menu Settings" at 1,1 
							DISPLAY "Option : ",pr_menu1.menu1_code," " at 2,1 
							DISPLAY "Name : ",pr_menu1.name_text at 3,1 
							# prompt "Any key TO continue" FOR CHAR ans
							CALL eventsuspend() # LET l_msgresp = kandoomsg("U",1,"") 
							CLOSE WINDOW show_it 
						WHEN "D" 
							LET l_msgresp = kandoomsg("U",9040,"") 
							#9040 " This entry will be deleted"
						WHEN "N" 
							LET l_msgresp = kandoomsg("U",9041,"") 
							#9041 " This entry will be added "
					END CASE 
				AFTER INPUT 
					LET idx = arr_count() 
				ON KEY (control-w) 
					CALL kandoohelp("") 
			END INPUT 
			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
				CLOSE WINDOW wu205 
				RETURN 
			END IF 
			LET y = 0 
			FOR x = 1 TO idx 
				IF pa_menu1[x].include_flag = "Y" THEN 
					LET y = y + 1 
				END IF 
			END FOR 
			IF y = 0 THEN 
				# Nothing TO UPDATE
				CLOSE WINDOW wu205 
				RETURN 
			END IF 
			IF kandoomsg("U",8017,"") != "Y" THEN 
				CONTINUE WHILE 
			ELSE 
				EXIT WHILE 
			END IF 
		END WHILE 

		FOR idx = 1 TO arr_count() 
			IF pa_menu1[idx].include_flag = "Y" THEN 
				#
				#   this shouls all be replaced with the new ACTION
				#   indicator  A N OR D
				#
				#
				SELECT * INTO pr_menu1.* FROM menu1 
				WHERE menu1_code = pa_menu3[idx].menu1_code 
				LET stat_1 = status # in CURRENT MENU system 
				SELECT * INTO ps_menu1.* FROM t_menu1 
				WHERE menu1_code = pa_menu1[idx].menu1_code 
				LET stat_2 = status # in dev MENU system 
				IF stat_1 AND NOT stat_2 THEN {in dev NOT in site} 
					SELECT * INTO pr_menu1.* FROM t_menu1 
					WHERE menu1_code = pa_menu1[idx].menu1_code 
					INSERT INTO menu1 VALUES (pr_menu1.*) 
				END IF 
				IF NOT stat_1 AND NOT stat_2 THEN {in both - update} 
					UPDATE menu1 SET * = ps_menu1.* 
					WHERE menu1_code = pa_menu1[idx].menu1_code 
				END IF 
				IF NOT stat_1 AND stat_2 THEN {in site NOT in dev} 
					DELETE FROM menu1 
					WHERE menu1_code = pa_menu1[idx].menu1_code 
					#  NOTE
					# This should delete all menu2 AND menu3 entries FOR
					# the menu1 code
					#
					#
					#
					#
					#

				END IF 
			END IF 
		END FOR 
		CLOSE WINDOW wu205 
	END IF 
END FUNCTION 


FUNCTION menu2_check(module) 
	DEFINE 
	pa_menu2 array[500] OF RECORD 
		menu1_code LIKE menu3.menu1_code, 
		menu2_code LIKE menu3.menu2_code, 
		menu3_code LIKE menu3.menu3_code, 
		name_text LIKE menu2.name_text, 
		run_text LIKE menu3.run_text, 
		include_flag CHAR(1) 
	END RECORD, 
	ps_menu2, pr_menu2 RECORD LIKE menu2.*, 
	module CHAR(1) 
	DEFINE l_msgresp LIKE language.yes_flag
	
	DECLARE check_curs4 CURSOR FOR 
	SELECT * FROM t_menu2 
	WHERE menu1_code = module 
	ORDER BY menu1_code,menu2_code 
	LET idx = 0 
	FOREACH check_curs4 INTO pr_menu2.* 
		IF int_flag OR quit_flag THEN 
			RETURN 
		END IF 
		SELECT * INTO ps_menu2.* FROM menu2 
		WHERE menu1_code = pr_menu2.menu1_code 
		AND menu2_code = pr_menu2.menu2_code 
		# store all the menu OPTIONS that are NOT in their menu
		IF status THEN 
			LET idx = idx + 1 
			LET pa_menu2[idx].menu1_code = pr_menu2.menu1_code 
			LET pa_menu2[idx].menu2_code = pr_menu2.menu2_code 
			LET pa_menu2[idx].menu3_code = NULL 
			LET pa_menu2[idx].name_text = pr_menu2.name_text 
			LET pa_menu2[idx].include_flag = "N" # new option 
		ELSE 
			IF pr_menu2.name_text != ps_menu2.name_text THEN 
				LET idx = idx + 1 
				LET pa_menu2[idx].menu1_code = pr_menu2.menu1_code 
				LET pa_menu2[idx].menu2_code = pr_menu2.menu2_code 
				LET pa_menu2[idx].menu3_code = NULL 
				LET pa_menu2[idx].name_text = pr_menu2.name_text 
				LET pa_menu2[idx].include_flag = "C" # change option 
			END IF 
		END IF 
	END FOREACH 
	# check site menu's vs development menus
	DECLARE check_curs5 CURSOR FOR 
	SELECT * 
	FROM menu2 
	WHERE menu1_code = module 
	ORDER BY menu1_code,menu2_code 
	FOREACH check_curs5 INTO pr_menu2.* 
		IF int_flag OR quit_flag THEN 
			RETURN 
		END IF 
		SELECT * 
		INTO ps_menu2.* 
		FROM t_menu2 
		WHERE menu1_code = pr_menu2.menu1_code 
		AND menu2_code = pr_menu2.menu2_code 
		# store all the menu OPTIONS that are NOT in our menu
		IF status THEN 
			LET idx = idx + 1 
			LET pa_menu2[idx].menu1_code = pr_menu2.menu1_code 
			LET pa_menu2[idx].menu2_code = pr_menu2.menu2_code 
			LET pa_menu2[idx].menu3_code = NULL 
			LET pa_menu2[idx].name_text = pr_menu2.name_text 
			LET pa_menu2[idx].include_flag = "D" # DELETE option 
		END IF 
	END FOREACH 
	IF idx > 0 THEN 
		OPEN WINDOW wu205 with FORM "U205" 
		CALL windecoration_u("U205") 

		WHILE (true) 

			CALL set_count(idx) 
			LET l_msgresp = kandoomsg("U",1048,"") 
			DISPLAY "2" TO level_code 
			INPUT ARRAY pa_menu2 WITHOUT DEFAULTS FROM sr_menu3.* 
				BEFORE INPUT 
					CALL publish_toolbar("kandoo","U1W","input-arr-menu2") 
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 


				BEFORE ROW 
					LET idx = arr_curr() 
				ON KEY (F7) {accept all} 
					FOR r = 1 TO arr_count() 
						IF pa_menu2[r].include_flag != " " AND 
						pa_menu2[r].include_flag IS NOT NULL THEN 
							LET pa_menu2[r].include_flag = "Y" 
						END IF 
					END FOR 
					IF arr_count() < 10 THEN 
						LET y = arr_count() 
					ELSE 
						LET y = 10 
					END IF 
					FOR x = 1 TO y 
						DISPLAY "Y" TO sr_menu3[x].include_flag 
					END FOR 
				ON KEY (control-v) 
					CASE pa_menu2[idx].include_flag 
						WHEN "C" 
							OPEN WINDOW show_it with FORM "U999" 
							CALL windecoration_u("U999") 

							SELECT * 
							INTO pr_menu2.* 
							FROM menu2 
							WHERE menu1_code = pa_menu2[idx].menu1_code 
							AND menu2_code = pa_menu2[idx].menu2_code 
							DISPLAY "Current Menu Settings" at 1,1 
							DISPLAY "Option : ",pr_menu2.menu1_code," ", 
							pr_menu2.menu2_code," " at 2,1 
							DISPLAY "Name : ",pr_menu2.name_text at 3,1 
							# prompt "Any key TO continue" FOR CHAR ans
							CALL eventsuspend() # LET l_msgresp = kandoomsg("U",1,"") 
							CLOSE WINDOW show_it 
						WHEN "D" 
							LET l_msgresp = kandoomsg("U",9037,"") 
							#9037 "This IS the current entry"
						WHEN "N" 
							LET l_msgresp = kandoomsg("U",9038,"") 
							#9038 "This IS a NEW option"
					END CASE 

				AFTER INPUT 
					LET idx = arr_count() 

				ON KEY (control-w) 
					CALL kandoohelp("") 

			END INPUT 

			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
				CLOSE WINDOW wu205 
				RETURN 
			END IF 

			LET y = 0 
			FOR x = 1 TO idx 
				IF pa_menu2[x].include_flag = "Y" THEN 
					LET y = y + 1 
				END IF 
			END FOR 
			IF y = 0 THEN 
				LET l_msgresp = kandoomsg("U",9039,"menu system") 
				CLOSE WINDOW wu205 
				RETURN 
			END IF 
			IF kandoomsg("U",8017,"") != "Y" THEN 
				CONTINUE WHILE 
			ELSE 
				EXIT WHILE 
			END IF 
		END WHILE 
		FOR idx = 1 TO arr_count() 
			IF pa_menu2[idx].include_flag = "Y" THEN 
				SELECT * 
				INTO pr_menu2.* 
				FROM menu2 
				WHERE menu1_code = pa_menu2[idx].menu1_code 
				AND menu2_code = pa_menu2[idx].menu2_code 
				LET stat_1 = status # in CURRENT MENU system 
				SELECT * 
				INTO ps_menu2.* 
				FROM t_menu2 
				WHERE menu1_code = pa_menu2[idx].menu1_code 
				AND menu2_code = pa_menu2[idx].menu2_code 
				LET stat_2 = status # in dev MENU system 
				IF stat_1 AND NOT stat_2 THEN {in dev NOT in site} 
					SELECT * 
					INTO pr_menu2.* 
					FROM t_menu2 
					WHERE menu1_code = pa_menu2[idx].menu1_code 
					AND menu2_code = pa_menu2[idx].menu2_code 
					INSERT INTO menu2 VALUES (pr_menu2.*) 
				END IF 
				IF NOT stat_1 AND NOT stat_2 THEN {in both - update} 
					UPDATE menu2 SET * = ps_menu2.* 
					WHERE menu1_code = pa_menu2[idx].menu1_code 
					AND menu2_code = pa_menu2[idx].menu2_code 
				END IF 
				IF NOT stat_1 AND stat_2 THEN {in site NOT in dev} 
					DELETE FROM menu2 
					WHERE menu2_code = pa_menu2[idx].menu1_code 
					AND menu2_code = pa_menu2[idx].menu2_code 
				END IF 
			END IF 
		END FOR 
		CLOSE WINDOW wu205 
	END IF 
END FUNCTION 


FUNCTION menu3_check(module) 
	DEFINE 
	module CHAR(1), 
	ps_menu3, pr_menu3 RECORD LIKE menu3.* 
	DEFINE l_msgresp LIKE language.yes_flag
	
	DECLARE check_curs CURSOR FOR 
	SELECT * 
	FROM t_menu3 
	WHERE menu1_code = module 
	ORDER BY menu1_code,menu2_code,menu3_code 
	LET idx = 0 
	FOREACH check_curs INTO pr_menu3.* 
		IF int_flag OR quit_flag THEN 
			RETURN 
		END IF 
		# MESSAGE "Verifying menu entries FOR module: ",pr_menu3.menu1_code, " ",
		#         pr_menu3.menu2_code," ",pr_menu3.menu3_code, "            "
		SELECT * INTO ps_menu3.* FROM menu3 
		WHERE menu1_code = pr_menu3.menu1_code 
		AND menu2_code = pr_menu3.menu2_code 
		AND menu3_code = pr_menu3.menu3_code 
		# store all the menu OPTIONS that are NOT in their menu
		IF status THEN 
			LET idx = idx + 1 
			LET pa_menu3[idx].menu1_code = pr_menu3.menu1_code 
			LET pa_menu3[idx].menu2_code = pr_menu3.menu2_code 
			LET pa_menu3[idx].menu3_code = pr_menu3.menu3_code 
			LET pa_menu3[idx].name_text = pr_menu3.name_text 
			LET pa_menu3[idx].run_text = pr_menu3.run_text 
			LET pa_menu3[idx].include_flag = "N" # new option 
		ELSE 
			IF pr_menu3.name_text != ps_menu3.name_text OR 
			pr_menu3.run_text != ps_menu3.run_text THEN 
				LET idx = idx + 1 
				LET pa_menu3[idx].menu1_code = pr_menu3.menu1_code 
				LET pa_menu3[idx].menu2_code = pr_menu3.menu2_code 
				LET pa_menu3[idx].menu3_code = pr_menu3.menu3_code 
				LET pa_menu3[idx].name_text = pr_menu3.name_text 
				LET pa_menu3[idx].run_text = pr_menu3.run_text 
				LET pa_menu3[idx].include_flag = "C" # change option 
			END IF 
		END IF 
	END FOREACH 
	# check site menu's vs development menus
	DECLARE check_curs1 CURSOR FOR 
	SELECT * 
	FROM menu3 
	WHERE menu1_code = module 
	ORDER BY menu1_code,menu2_code,menu3_code 
	FOREACH check_curs1 INTO pr_menu3.* 
		IF int_flag OR quit_flag THEN 
			RETURN 
		END IF 
		SELECT * INTO ps_menu3.* FROM t_menu3 
		WHERE menu1_code = pr_menu3.menu1_code 
		AND menu2_code = pr_menu3.menu2_code 
		AND menu3_code = pr_menu3.menu3_code 
		# store all the menu OPTIONS that are NOT in our menu
		IF status THEN 
			LET idx = idx + 1 
			LET pa_menu3[idx].menu1_code = pr_menu3.menu1_code 
			LET pa_menu3[idx].menu2_code = pr_menu3.menu2_code 
			LET pa_menu3[idx].menu3_code = pr_menu3.menu3_code 
			LET pa_menu3[idx].name_text = pr_menu3.name_text 
			LET pa_menu3[idx].run_text = pr_menu3.run_text 
			LET pa_menu3[idx].include_flag = "D" # DELETE option 
		END IF 
	END FOREACH 
	IF idx > 0 THEN 
		OPEN WINDOW wu205 with FORM "U205" 
		CALL windecoration_u("U205") 

		WHILE (true) 

			CALL set_count(idx) 
			LET l_msgresp = kandoomsg("U",1048,"") 
			DISPLAY "3" TO level_code 

			INPUT ARRAY pa_menu3 WITHOUT DEFAULTS FROM sr_menu3.* 
				BEFORE INPUT 
					CALL publish_toolbar("kandoo","U1W","input-arr-menu2") 
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
				BEFORE ROW 
					LET idx = arr_curr() 
				ON KEY (F7) {accept all} 
					FOR r = 1 TO arr_count() 
						IF pa_menu3[r].include_flag != " " AND 
						pa_menu3[r].include_flag IS NOT NULL THEN 
							LET pa_menu3[r].include_flag = "Y" 
						END IF 
					END FOR 
					IF arr_count() < 10 THEN 
						LET y = arr_count() 
					ELSE 
						LET y = 10 
					END IF 
					FOR x = 1 TO y 
						DISPLAY "Y" TO sr_menu3[x].include_flag 
					END FOR 
				ON KEY (control-v) 
					CASE pa_menu3[idx].include_flag 
						WHEN "C" 
							OPEN WINDOW show_it with FORM "U999" 
							CALL windecoration_u("U999") 

							SELECT * 
							INTO pr_menu3.* 
							FROM menu3 
							WHERE menu1_code = pa_menu3[idx].menu1_code 
							AND menu2_code = pa_menu3[idx].menu2_code 
							AND menu3_code = pa_menu3[idx].menu3_code 
							DISPLAY "Current Menu Settings" at 1,1 
							DISPLAY "Option : ",pr_menu3.menu1_code," ", 
							pr_menu3.menu2_code," ", 
							pr_menu3.menu3_code," " at 2,1 
							DISPLAY "Name : ",pr_menu3.name_text at 3,1 
							DISPLAY "Run : ",pr_menu3.run_text at 4,1 

							# prompt "Any key TO continue" FOR CHAR ans
							CALL eventsuspend() # LET l_msgresp = kandoomsg("U",1,"") 
							CLOSE WINDOW show_it 

						WHEN "D" 
							LET l_msgresp = kandoomsg("U",9037,"") 
							#9037 "This IS the current entry"

						WHEN "N" 
							LET l_msgresp = kandoomsg("U",9038,"") 
							#9038 "This IS a NEW option"

					END CASE 

				AFTER INPUT 
					LET idx = arr_count() 

				ON KEY (control-w) 
					CALL kandoohelp("") 

			END INPUT 

			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
				CLOSE WINDOW wu205 
				RETURN 
			END IF 
			LET y = 0 
			FOR x = 1 TO idx 
				IF pa_menu3[x].include_flag = "Y" THEN 
					LET y = y + 1 
				END IF 
			END FOR 
			IF y = 0 THEN 
				LET l_msgresp = kandoomsg("U",9039,"menu system") 
				CLOSE WINDOW wu205 
				RETURN 
			END IF 
			IF kandoomsg("U",8017,"") != "Y" THEN 
				CONTINUE WHILE 
			ELSE 
				EXIT WHILE 
			END IF 
		END WHILE 
		FOR idx = 1 TO arr_count() 
			IF pa_menu3[idx].include_flag = "Y" THEN 
				SELECT * 
				INTO pr_menu3.* 
				FROM menu3 
				WHERE menu1_code = pa_menu3[idx].menu1_code 
				AND menu2_code = pa_menu3[idx].menu2_code 
				AND menu3_code = pa_menu3[idx].menu3_code 
				LET stat_1 = status # in CURRENT MENU system 
				SELECT * 
				INTO ps_menu3.* 
				FROM t_menu3 
				WHERE menu1_code = pa_menu3[idx].menu1_code 
				AND menu2_code = pa_menu3[idx].menu2_code 
				AND menu3_code = pa_menu3[idx].menu3_code 
				LET stat_2 = status # in dev MENU system 
				IF stat_1 AND NOT stat_2 THEN {in dev NOT in site} 
					SELECT * 
					INTO pr_menu3.* 
					FROM t_menu3 
					WHERE menu1_code = pa_menu3[idx].menu1_code 
					AND menu2_code = pa_menu3[idx].menu2_code 
					AND menu3_code = pa_menu3[idx].menu3_code 
					INSERT INTO menu3 VALUES (pr_menu3.*) 
				END IF 
				IF NOT stat_1 AND NOT stat_2 THEN {in both - update} 
					UPDATE menu3 SET * = ps_menu3.* 
					WHERE menu1_code = pa_menu3[idx].menu1_code 
					AND menu2_code = pa_menu3[idx].menu2_code 
					AND menu3_code = pa_menu3[idx].menu3_code 
				END IF 
				IF NOT stat_1 AND stat_2 THEN {in site NOT in dev} 
					DELETE FROM menu3 
					WHERE menu1_code = pa_menu3[idx].menu1_code 
					AND menu2_code = pa_menu3[idx].menu2_code 
					AND menu3_code = pa_menu3[idx].menu3_code 
				END IF 
			END IF 
		END FOR 
		CLOSE WINDOW wu205 
	END IF 
END FUNCTION