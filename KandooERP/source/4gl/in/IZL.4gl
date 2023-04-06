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




{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module IZL - Maintains product Labels
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "I_IN_GLOBALS.4gl" 
GLOBALS 
	DEFINE 
	err_message CHAR(40) 
END GLOBALS 

####################################################################
# MAIN
####################################################################
MAIN 
	#Initial UI Init
	CALL setModuleId("IZL") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_i_in() --init i/in warehouse inventory management module 

	OPTIONS INSERT KEY f1, 
	DELETE KEY f36 
	OPEN WINDOW i627 with FORM "I627" 
	 CALL windecoration_i("I627") -- albo kd-758 

	WHILE select_labelhead() 
		CALL scan_labelhead() 
	END WHILE 
	CLOSE WINDOW i627 
END MAIN 


FUNCTION select_labelhead() 
	DEFINE query_text CHAR(300) 
	DEFINE where_text CHAR(200) 
	DEFINE l_msgresp LIKE language.yes_flag 

	CLEAR FORM 
	LET l_msgresp = kandoomsg("I",1001,"") 
	#1001 " Enter Selection Criteria - ESC TO Continue"
	CONSTRUCT BY NAME where_text ON label_code, 
	desc_text 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","IZI","construct-label_code-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		LET l_msgresp = kandoomsg("I",1002,"") 
		#1002 " Searching database - please wait"
		LET query_text = "SELECT * FROM labelhead ", 
		"WHERE cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
		"AND ", where_text clipped," ", 
		"ORDER BY labelhead.label_code" 
		PREPARE s_labelhead FROM query_text 
		DECLARE c_labelhead CURSOR FOR s_labelhead 
		RETURN true 
	END IF 
END FUNCTION 

FUNCTION valid_field(pr_text) 
	DEFINE 
	pr_text LIKE labeldetl.line_text, 
	pos, len SMALLINT, 
	pr_field LIKE labeldetl.line_text 

	WHILE true 
		LET len = length(pr_text) 
		FOR pos = 1 TO len 
			IF pr_text[pos] = "<" THEN 
				LET len = length(pr_text) 
				LET pr_text = pr_text[pos, len] 
				LET pos = 0 
				EXIT FOR 
			END IF 
		END FOR 
		LET len = length(pr_text) 
		IF pos >= len THEN 
			EXIT WHILE 
		END IF 
		LET len = length(pr_text) 
		FOR pos = 2 TO len 
			IF pr_text[pos] = ">" THEN 
				LET pr_field = pr_text[2, (pos - 1)] 
				IF bad_field(pr_field) THEN 
					RETURN false 
				END IF 
				LET len = length(pr_text) 
				IF pos < len THEN 
					LET pr_text = pr_text[(pos + 1), len] 
					LET pos = 0 
				ELSE 
					LET pr_text = NULL 
					EXIT WHILE 
				END IF 
				EXIT FOR 
			ELSE 
				IF pr_text[pos] = "<" THEN 
					LET len = length(pr_text) 
					LET pr_text = pr_text[pos, len] 
					EXIT FOR 
				END IF 
			END IF 
		END FOR 
		LET len = length(pr_text) 
		IF pos >= len THEN 
			EXIT WHILE 
		END IF 
	END WHILE 
	RETURN true 
END FUNCTION 

FUNCTION bad_field(pr_field) 
	DEFINE 
	pr_field LIKE labeldetl.line_text, 
	pos, len SMALLINT, 
	pr_table CHAR(30), 
	pr_column CHAR(50) 

	LET pr_table = NULL 
	LET pr_column = NULL 
	LET len = length(pr_field) 
	FOR pos = 1 TO len 
		IF pr_field[pos] = "." THEN 
			LET pr_table = pr_field[1, (pos - 1)] 
			LET pr_column = pr_field[(pos + 1), len] 
			EXIT FOR 
		END IF 
	END FOR 
	IF pr_table IS NULL 
	OR pr_column IS NULL THEN 
		RETURN true 
	END IF 
	IF pr_table != "company" 
	AND pr_table != "warehouse" 
	AND pr_table != "product" 
	AND pr_table != "prodstatus" 
	AND pr_table != "prodgrp" 
	AND pr_table != "maingrp" 
	AND pr_table != "category" 
	AND pr_table != "class" 
	AND pr_table != "serialinfo" THEN 
		RETURN true 
	END IF 
	SELECT * FROM syscolumns, systables 
	WHERE systables.tabid = syscolumns.tabid 
	AND systables.tabname = pr_table 
	AND syscolumns.colname = pr_column 
	IF status = notfound THEN 
		RETURN true 
	END IF 
	RETURN false 
END FUNCTION 

FUNCTION scan_labelhead() 
	DEFINE pr_labelhead RECORD LIKE labelhead.* 
	DEFINE pa_labelhead array[100] OF 
	RECORD 
		scroll_flag CHAR(1), 
		label_code LIKE labelhead.label_code, 
		desc_text LIKE labelhead.desc_text 
	END RECORD 
	DEFINE pr_scroll_flag CHAR(1) 
	DEFINE pr_curr,pr_cnt,idx,scrn,del_cnt,pr_rowid SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET idx = 0 
	FOREACH c_labelhead INTO pr_labelhead.* 
		LET idx = idx + 1 
		LET pa_labelhead[idx].label_code = pr_labelhead.label_code 
		LET pa_labelhead[idx].desc_text = pr_labelhead.desc_text 
		IF idx = 100 THEN 
			LET l_msgresp = kandoomsg("I",9151,idx) 
			#9151 " First ??? entries selected only"
			EXIT FOREACH 
		END IF 
	END FOREACH 
	IF idx = 0 THEN 
		LET l_msgresp = kandoomsg("I",9152,"") 
		#9152" No entries satisfied selection criteria "
		LET idx = 1 
	END IF 
	OPTIONS INSERT KEY f1, 
	DELETE KEY f36 
	CALL set_count(idx) 
	LET l_msgresp = kandoomsg("I",1003,"") 
	#1003 "F1 TO Add - F2 TO Delete - RETURN TO Edit
	INPUT ARRAY pa_labelhead WITHOUT DEFAULTS FROM sr_labelhead.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","IZI","input-arr-pa_labelhead-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE FIELD scroll_flag 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			LET pr_scroll_flag = pa_labelhead[idx].scroll_flag 
			DISPLAY pa_labelhead[idx].* TO sr_labelhead[scrn].* 

		AFTER FIELD scroll_flag 
			LET pa_labelhead[idx].scroll_flag = pr_scroll_flag 
			DISPLAY pa_labelhead[idx].scroll_flag TO sr_labelhead[scrn].scroll_flag 

			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF pa_labelhead[idx+1].label_code IS NULL 
				OR arr_curr() >= arr_count() THEN 
					LET l_msgresp=kandoomsg("I",9001,"") 
					#9001 There no more rows...
					NEXT FIELD scroll_flag 
				END IF 
			END IF 
		BEFORE FIELD label_code 
			IF pa_labelhead[idx].label_code IS NOT NULL THEN 
				LET pr_labelhead.label_code = pa_labelhead[idx].label_code 
				LET pr_labelhead.desc_text = pa_labelhead[idx].desc_text 
				LET pr_curr = arr_curr() 
				LET pr_cnt = arr_count() 
				IF edit_labelhead(pr_labelhead.label_code) THEN 
					SELECT * INTO pr_labelhead.* FROM labelhead 
					WHERE label_code = pr_labelhead.label_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					LET pa_labelhead[idx].label_code = pr_labelhead.label_code 
					LET pa_labelhead[idx].desc_text = pr_labelhead.desc_text 
				END IF 
			END IF 
			NEXT FIELD scroll_flag 
		BEFORE INSERT 
			IF arr_curr() < arr_count() THEN 
				LET pr_curr = arr_curr() 
				LET pr_cnt = arr_count() 
				LET pr_rowid = 
				edit_labelhead("") 
				IF pr_rowid = 0 THEN 
					FOR idx = pr_curr TO pr_cnt 
						LET pa_labelhead[idx].* = pa_labelhead[idx+1].* 
						IF scrn <= 12 THEN 
							DISPLAY pa_labelhead[idx].* TO sr_labelhead[scrn].* 

							LET scrn = scrn + 1 
						END IF 
					END FOR 
					INITIALIZE pa_labelhead[idx].* TO NULL 
				ELSE 
					SELECT * INTO pr_labelhead.* FROM labelhead 
					WHERE rowid = pr_rowid 
					LET pa_labelhead[idx].label_code = pr_labelhead.label_code 
					LET pa_labelhead[idx].desc_text = pr_labelhead.desc_text 
				END IF 
			ELSE 
				IF idx > 1 THEN 
					LET l_msgresp = kandoomsg("I",9001,"") 
					#9001 There are no more rows....
				END IF 
			END IF 
		ON KEY (F2) 
			IF pa_labelhead[idx].scroll_flag IS NULL THEN 
				LET pa_labelhead[idx].scroll_flag = "*" 
				LET del_cnt = del_cnt + 1 
			ELSE 
				LET pa_labelhead[idx].scroll_flag = NULL 
				LET del_cnt = del_cnt - 1 
			END IF 
			NEXT FIELD scroll_flag 
		AFTER ROW 
			DISPLAY pa_labelhead[idx].* 
			TO sr_labelhead[scrn].* 

		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	GOTO bypass 
	LABEL recovery: 
	IF error_recover(err_message, status) = "N" THEN 
		CLOSE WINDOW i627 
		RETURN 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	BEGIN WORK 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		ELSE 
			IF del_cnt > 0 THEN 
				LET l_msgresp = kandoomsg("I",8032,del_cnt) 
				#8032 Confirm TO Delete ",del_cnt," Label(s)? (Y/N)"
				IF l_msgresp = "Y" THEN 
					FOR idx = 1 TO arr_count() 
						IF pa_labelhead[idx].scroll_flag = "*" THEN 
							LET err_message = "IZL - Deleting FROM labelhead" 
							DELETE FROM labelhead 
							WHERE label_code = pa_labelhead[idx].label_code 
							AND cmpy_code = glob_rec_kandoouser.cmpy_code 
							LET err_message = "IZL - Deleting FROM labeldetl" 
							DELETE FROM labeldetl 
							WHERE label_code = pa_labelhead[idx].label_code 
							AND cmpy_code = glob_rec_kandoouser.cmpy_code 
						END IF 
					END FOR 
				END IF 
			END IF 
		END IF 
	COMMIT WORK 
END FUNCTION 

FUNCTION edit_labelhead(pr_label_code) 
	DEFINE ps_labelhead RECORD LIKE labelhead.* 
	DEFINE pr_labelhead RECORD LIKE labelhead.* 
	DEFINE pr_labeldetl RECORD LIKE labeldetl.* 
	DEFINE pr_label_code LIKE labelhead.label_code 
	DEFINE pr_sqlerrd INTEGER 
	DEFINE pr_line_text LIKE labeldetl.line_text 
	DEFINE pa_labeldetl array[100] OF 
	RECORD 
		line_text LIKE labeldetl.line_text 
	END RECORD 
	DEFINE pr_scroll_flag CHAR(1) 
	DEFINE idx,scrn,x,i,j SMALLINT 
	DEFINE pr_blank_qty SMALLINT 
	DEFINE winds_text CHAR(40) 
	DEFINE l_msgresp LIKE language.yes_flag 

	INITIALIZE pr_labelhead.* TO NULL 
	LET idx = 0 
	IF pr_label_code IS NOT NULL THEN 
		SELECT * INTO pr_labelhead.* FROM labelhead 
		WHERE label_code = pr_label_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		DECLARE c_labeldetl CURSOR FOR 
		SELECT * FROM labeldetl 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND label_code = pr_label_code 
		ORDER BY line_num 
		FOREACH c_labeldetl INTO pr_labeldetl.* 
			LET idx = idx + 1 
			LET pa_labeldetl[idx].line_text = pr_labeldetl.line_text 
		END FOREACH 
	ELSE 
		LET pr_labelhead.cmpy_code = glob_rec_kandoouser.cmpy_code 
	END IF 
	CALL set_count(idx) 
	OPEN WINDOW i628 with FORM "I628" 
	 CALL windecoration_i("I628") -- albo kd-758 
	LET l_msgresp = kandoomsg("I",1039,"") 
	#1039 " Enter Label Details
	DISPLAY BY NAME pr_labelhead.label_code, 
	pr_labelhead.desc_text, 
	pr_labelhead.print_code 

	WHILE true 
		INPUT BY NAME pr_labelhead.label_code, 
		pr_labelhead.desc_text, 
		pr_labelhead.print_code WITHOUT DEFAULTS 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","IZI","input-pr_labelhead-1") -- albo kd-505 

			ON ACTION "WEB-HELP" -- albo kd-372 
				CALL onlinehelp(getmoduleid(),null) 

			ON KEY (control-b) 
				CASE 
					WHEN infield(print_code) 
						LET winds_text = NULL 
						LET winds_text = show_print(glob_rec_kandoouser.cmpy_code) 
						IF winds_text IS NOT NULL THEN 
							LET pr_labelhead.print_code = winds_text 
							DISPLAY BY NAME pr_labelhead.print_code 

						END IF 
						OPTIONS INSERT KEY f1, 
						DELETE KEY f36 
						NEXT FIELD print_code 
				END CASE 
			BEFORE FIELD label_code 
				IF pr_label_code IS NOT NULL THEN 
					NEXT FIELD desc_text 
				END IF 
			AFTER FIELD label_code 
				IF pr_labelhead.label_code IS NULL THEN 
					LET l_msgresp = kandoomsg("I",9162,"") 
					#9162 " Label Code must be entered
					NEXT FIELD label_code 
				END IF 
				IF pr_label_code IS NULL THEN 
					SELECT * INTO ps_labelhead.* FROM labelhead 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND label_code = pr_labelhead.label_code 
					IF status != notfound THEN 
						LET l_msgresp = kandoomsg("I",9163,"") 
						#9163 Label alreay exists - Please re-enter
						NEXT FIELD label_code 
					END IF 
				END IF 
			AFTER FIELD desc_text 
				IF pr_labelhead.desc_text IS NULL THEN 
					LET l_msgresp = kandoomsg("I",9084,"") 
					#9084 " Description must be entered
					NEXT FIELD desc_text 
				END IF 
			AFTER FIELD print_code 
				IF pr_labelhead.print_code IS NOT NULL THEN 
					SELECT * FROM printcodes 
					WHERE print_code = pr_labelhead.print_code 
					IF status = notfound THEN 
						LET l_msgresp = kandoomsg("I",9164,"") 
						#9164 Printer does NOT exist - Try Window
						NEXT FIELD print_code 
					END IF 
				END IF 
			AFTER INPUT 
				IF NOT (int_flag OR quit_flag) THEN 
					IF pr_label_code IS NOT NULL THEN 
						IF pr_labelhead.label_code IS NULL THEN 
							LET l_msgresp = kandoomsg("I",9162,"") 
							#9162 " Label Code must be entered
							NEXT FIELD label_code 
						END IF 
					ELSE 
						SELECT * INTO ps_labelhead.* FROM labelhead 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND label_code = pr_labelhead.label_code 
						IF status != notfound THEN 
							LET l_msgresp = kandoomsg("I",9163,"") 
							#9163 Label alreay exists - Please re-enter
							NEXT FIELD label_code 
						END IF 
					END IF 
					IF pr_labelhead.desc_text IS NULL THEN 
						LET l_msgresp = kandoomsg("I",9084,"") 
						#9084 " Description must be entered
						NEXT FIELD desc_text 
					END IF 
					IF pr_labelhead.print_code IS NOT NULL THEN 
						SELECT * FROM printcodes 
						WHERE print_code = pr_labelhead.print_code 
						IF status = notfound THEN 
							LET l_msgresp = kandoomsg("I",9164,"") 
							#9164 Printer does NOT exist - Try Window
							NEXT FIELD print_code 
						END IF 
					END IF 
				END IF 
			ON KEY (control-w) 
				CALL kandoohelp("") 
		END INPUT 
		IF int_flag OR quit_flag THEN 
			LET quit_flag = false 
			LET int_flag = false 
			CLOSE WINDOW i628 
			RETURN false 
			EXIT WHILE 
		END IF 
		OPTIONS INSERT KEY f1, 
		DELETE KEY f2 
		LET l_msgresp = kandoomsg("I",1003,"") 
		#" F1 TO Add - F2 TO Delete - RETURN on line TO Edit "
		INPUT ARRAY pa_labeldetl WITHOUT DEFAULTS FROM sr_labeldetl.* 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","IZI","input-arr-pa_labeldetl-1") -- albo kd-505 

			ON ACTION "WEB-HELP" -- albo kd-372 
				CALL onlinehelp(getmoduleid(),null) 

			BEFORE ROW 
				LET idx = arr_curr() 
				LET scrn = scr_line() 
				NEXT FIELD line_text 
			BEFORE INSERT 
				INITIALIZE pr_labeldetl.* TO NULL 
				INITIALIZE pa_labeldetl[idx].* TO NULL 
				LET j = idx 
				FOR x = scrn TO 12 
					DISPLAY pa_labeldetl[j].* TO sr_labeldetl[x].* 

					LET j = j + 1 
				END FOR 
				NEXT FIELD line_text 
			BEFORE FIELD line_text 
				DISPLAY pa_labeldetl[idx].* TO sr_labeldetl[scrn].* 

			AFTER FIELD line_text 
				IF NOT valid_field(pa_labeldetl[idx].line_text) THEN 
					LET l_msgresp = kandoomsg("I",9183,"") 
					#9183 Must be valid field on database
					NEXT FIELD line_text 
				END IF 
				CASE 
					WHEN fgl_lastkey() = fgl_keyval("accept") 
						EXIT INPUT 
					WHEN fgl_lastkey() = fgl_keyval("down") 
						OR fgl_lastkey() = fgl_keyval("RETURN") 
						OR fgl_lastkey() = fgl_keyval("tab") 
						OR fgl_lastkey() = fgl_keyval("right") 
						IF arr_curr() >= (arr_count() + 1) THEN 
							LET l_msgresp=kandoomsg("I",9001,"") 
							#9001 There no more rows...
							NEXT FIELD line_text 
						END IF 
				END CASE 
			AFTER ROW 
				DISPLAY pa_labeldetl[idx].* TO sr_labeldetl[scrn].* 

			AFTER INPUT 
				IF NOT (int_flag OR quit_flag) THEN 
					LET pr_blank_qty = 0 
					FOR idx = 1 TO arr_count() 
						IF pa_labeldetl[idx].line_text IS NULL THEN 
							LET pr_blank_qty = pr_blank_qty + 1 
						ELSE 
							IF pr_blank_qty > 1 THEN 
								LET l_msgresp = kandoomsg("I",9165,"") 
								#9165 Only one blank Template Line can be entered
								NEXT FIELD line_text 
								EXIT FOR 
							END IF 
						END IF 
					END FOR 
				END IF 
			ON KEY (control-w) 
				CALL kandoohelp("") 
		END INPUT 
		OPTIONS INSERT KEY f1, 
		DELETE KEY f36 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		ELSE 
			GOTO bypass 
			LABEL recovery: 
			IF error_recover(err_message, status) = "N" THEN 
				CLOSE WINDOW i628 
				RETURN false 
				EXIT WHILE 
			END IF 
			LABEL bypass: 
			WHENEVER ERROR GOTO recovery 
			BEGIN WORK 
				LET err_message = "IZL - Updating labeldetl" 
				DELETE FROM labeldetl 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND label_code = pr_labelhead.label_code 
				LET pr_blank_qty = 0 
				FOR idx = 1 TO arr_count() 
					IF pa_labeldetl[idx].line_text IS NULL 
					AND pr_blank_qty != 0 THEN 
					ELSE 
						IF pa_labeldetl[idx].line_text IS NOT NULL 
						OR pa_labeldetl[idx+1].line_text IS NOT NULL THEN 
							LET pr_labeldetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
							LET pr_labeldetl.label_code = pr_labelhead.label_code 
							LET pr_labeldetl.line_num = idx 
							LET pr_labeldetl.line_text = pa_labeldetl[idx].line_text 
							INSERT INTO labeldetl VALUES (pr_labeldetl.*) 
							IF pa_labeldetl[idx].line_text IS NULL THEN 
								LET pr_blank_qty = pr_blank_qty + 1 
							END IF 
						END IF 
					END IF 
				END FOR 
				LET err_message = "IZL - Updating labelhead" 
				IF pr_label_code IS NULL THEN 
					INSERT INTO labelhead VALUES (pr_labelhead.*) 
					LET pr_sqlerrd = sqlca.sqlerrd[6] 
				ELSE 
					UPDATE labelhead 
					SET * = pr_labelhead.* 
					WHERE label_code = pr_labelhead.label_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					LET pr_sqlerrd = sqlca.sqlerrd[3] 
				END IF 
			COMMIT WORK 
			CLOSE WINDOW i628 
			RETURN pr_sqlerrd 
			EXIT WHILE 
		END IF 
	END WHILE 
END FUNCTION 
