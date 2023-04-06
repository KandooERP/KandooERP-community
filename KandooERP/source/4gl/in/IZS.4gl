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

	Source code beautified by beautify.pl on 2020-01-03 09:12:51	$Id: $
}

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "I_IN_GLOBALS.4gl" 

#   IZS - Product Flex Codes


GLOBALS 
	DEFINE 
	temp_text CHAR(20), 
	pr_class_code LIKE class.class_code, 
	pr_start_num LIKE prodstructure.start_num, 
	pr_this_seq_num, pr_last_seq_num LIKE prodstructure.seq_num, 
	pr_length LIKE prodstructure.length 
END GLOBALS 

####################################################################
# MAIN
####################################################################
MAIN 
	#Initial UI Init
	CALL setModuleId("IZS") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_i_in() --init i/in warehouse inventory management module 

	OPEN WINDOW i623 with FORM "I623" 
	 CALL windecoration_i("I623") 

	WHILE select_prodflex() 
		CALL scan_prodflex() 
	END WHILE 
	CLOSE WINDOW i623 
END MAIN 

FUNCTION select_prodflex() 
	DEFINE pr_class RECORD LIKE class.* 
	DEFINE pr_prodstructure RECORD LIKE prodstructure.* 
	DEFINE query_text CHAR(300) 
	DEFINE where_text CHAR(200) 
	DEFINE winds_text CHAR(20) 
	DEFINE l_msgresp LIKE language.yes_flag 

	CLEAR FORM 
	INPUT BY NAME pr_class.class_code, 
	pr_prodstructure.start_num 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","IZS","input-pr_class-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (control-b) infield (class_code) 
			LET winds_text = NULL 
			LET winds_text = show_pcls(glob_rec_kandoouser.cmpy_code) 
			IF winds_text IS NOT NULL THEN 
				LET pr_class.class_code = winds_text 
				DISPLAY BY NAME pr_class.class_code 

			END IF 
			NEXT FIELD class_code 

		ON KEY (control-b) infield (start_num) 
			LET winds_text = NULL 
			LET winds_text = show_start_num(glob_rec_kandoouser.cmpy_code, pr_class.class_code) 
			IF winds_text IS NOT NULL THEN 
				LET pr_prodstructure.start_num = winds_text 
				DISPLAY BY NAME pr_prodstructure.start_num 

			END IF 
			NEXT FIELD start_num 

		BEFORE FIELD class_code 
			LET l_msgresp = kandoomsg("I",1305,"") 
			#1305 Enter Inventory Class FOR Product Flex Codes required
		AFTER FIELD class_code 
			IF pr_class.class_code IS NULL THEN 
				LET l_msgresp = kandoomsg("I",9091,"") 
				#9091 Inventory Class must be entered
				NEXT FIELD class_code 
			ELSE 
				LET pr_class.desc_text = NULL 
				SELECT * INTO pr_class.* FROM class 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND class_code = pr_class.class_code 
				IF status = notfound THEN 
					LET l_msgresp = kandoomsg("I",9041,"") 
					#9041 Inventory Class NOT found
					NEXT FIELD class_code 
				END IF 
				DISPLAY pr_class.desc_text TO class_desc_text 

			END IF 
		BEFORE FIELD start_num 
			LET l_msgresp = kandoomsg("I",1306,"") 
			#1306 Enter Starting Position FOR Product Flex Codes required
		AFTER FIELD start_num 
			IF pr_prodstructure.start_num IS NULL THEN 
				LET l_msgresp = kandoomsg("I",9141,"") 
				#9141 Product Structure Starting Number must be entered
				NEXT FIELD start_num 
			ELSE 
				LET pr_prodstructure.desc_text = NULL 
				SELECT * INTO pr_prodstructure.* FROM prodstructure 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND class_code = pr_class.class_code 
				AND start_num = pr_prodstructure.start_num 
				IF status = notfound THEN 
					LET l_msgresp = kandoomsg("I",9158,"") 
					#9158 Product Structure Starting Number NOT found
					NEXT FIELD start_num 
				END IF 
				DISPLAY pr_prodstructure.desc_text TO start_desc_text 

			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 
	LET pr_class_code = pr_class.class_code 
	LET pr_start_num = pr_prodstructure.start_num 
	LET pr_length = pr_prodstructure.length 
	LET pr_this_seq_num = pr_prodstructure.seq_num 
	SELECT max(seq_num) INTO pr_last_seq_num 
	FROM prodstructure 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND class_code = pr_class.class_code 
	IF pr_last_seq_num IS NULL THEN 
		LET pr_last_seq_num = 0 
	END IF 
	LET l_msgresp = kandoomsg("I",1001,"") 
	#1001 " Enter Selection Criteria - ESC TO Continue"
	CONSTRUCT BY NAME where_text ON flex_code, 
	desc_text 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","IZS","construct-flex_code-1") -- albo kd-505 

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
		LET query_text = "SELECT * FROM prodflex ", 
		"WHERE cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
		"AND class_code = '", pr_class.class_code, "' ", 
		"AND start_num = '", pr_prodstructure.start_num, "' ", 
		"AND ", where_text clipped," ", 
		"ORDER BY prodflex.flex_code" 
		PREPARE s_prodflex FROM query_text 
		DECLARE c_prodflex CURSOR FOR s_prodflex 
		RETURN true 
	END IF 
END FUNCTION 

FUNCTION scan_prodflex() 
	DEFINE pr_prodflex RECORD LIKE prodflex.* 
	DEFINE pa_prodflex array[100] OF 
	RECORD 
		scroll_flag CHAR(1), 
		flex_code LIKE prodflex.flex_code, 
		desc_text LIKE bic.desc_text 
	END RECORD 
	DEFINE pr_scroll_flag CHAR(1) 
	DEFINE char_string CHAR(30) 
	DEFINE idx,scrn,del_cnt,x SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET idx = 0 
	FOREACH c_prodflex INTO pr_prodflex.* 
		LET idx = idx + 1 
		LET pa_prodflex[idx].flex_code = pr_prodflex.flex_code 
		LET pa_prodflex[idx].desc_text = pr_prodflex.desc_text 
		IF idx = 100 THEN 
			LET l_msgresp = kandoomsg("I",9151,idx) 
			#9151 " First ??? entries Selected Only"
			EXIT FOREACH 
		END IF 
	END FOREACH 
	IF idx = 0 THEN 
		LET l_msgresp = kandoomsg("I",9152,"") 
		#9152" No entries satisfied selection criteria "
	END IF 
	OPTIONS INSERT KEY f1, 
	DELETE KEY f36 
	CALL set_count(idx) 
	LET l_msgresp = kandoomsg("I",1003,"") 
	#" F1 TO Add - F2 TO Delete - RETURN on line TO Edit "
	INPUT ARRAY pa_prodflex WITHOUT DEFAULTS FROM sr_prodflex.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","IZS","input-arr-pa_prodflex-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE ROW 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			NEXT FIELD scroll_flag 
		BEFORE INSERT 
			INITIALIZE pr_prodflex.* TO NULL 
			INITIALIZE pa_prodflex[idx].* TO NULL 
			NEXT FIELD flex_code 
		BEFORE FIELD scroll_flag 
			LET pr_scroll_flag = pa_prodflex[idx].scroll_flag 
			DISPLAY pa_prodflex[idx].* TO sr_prodflex[scrn].* 

		AFTER FIELD scroll_flag 
			LET pa_prodflex[idx].scroll_flag = pr_scroll_flag 
			LET pr_prodflex.flex_code = pa_prodflex[idx].flex_code 
			DISPLAY pa_prodflex[idx].scroll_flag 
			TO sr_prodflex[scrn].scroll_flag 

			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF idx < arr_count() THEN 
					IF pa_prodflex[idx+1].flex_code IS NULL 
					OR arr_curr() >= arr_count() THEN 
						LET l_msgresp=kandoomsg("I",9001,"") 
						#9001 There no more rows...
						NEXT FIELD scroll_flag 
					END IF 
				ELSE 
					LET l_msgresp=kandoomsg("I",9001,"") 
					NEXT FIELD scroll_flag 
				END IF 
			END IF 
		BEFORE FIELD flex_code 
			DISPLAY pa_prodflex[idx].* TO sr_prodflex[scrn].* 

			IF pr_prodflex.flex_code IS NOT NULL THEN 
				NEXT FIELD desc_text 
			END IF 
		AFTER FIELD flex_code 
			IF pa_prodflex[idx].flex_code IS NULL THEN 
				LET l_msgresp = kandoomsg("I",9153,"") 
				#9153 Product Flex Code must be entered
				NEXT FIELD flex_code 
			ELSE 
				LET char_string = pa_prodflex[idx].flex_code 
				IF pr_this_seq_num = pr_last_seq_num THEN 
					IF validate_string(char_string, 1, pr_length, true) 
					THEN ELSE 
						NEXT FIELD flex_code 
					END IF 
				ELSE 
					IF validate_string(char_string, pr_length, pr_length, true) 
					THEN ELSE 
						NEXT FIELD flex_code 
					END IF 
				END IF 
				IF pr_prodflex.flex_code IS NULL THEN 
					SELECT unique 1 FROM prodflex 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND class_code = pr_class_code 
					AND start_num = pr_start_num 
					AND flex_code = pa_prodflex[idx].flex_code 
					IF status != notfound THEN 
						LET l_msgresp = kandoomsg("I",9154,"") 
						# 9154 Product Flex Code already exists
						NEXT FIELD flex_code 
					END IF 
					FOR x = 1 TO 100 
						IF pa_prodflex[idx].flex_code = pa_prodflex[x].flex_code 
						AND idx != x THEN 
							LET l_msgresp = kandoomsg("I",9154,"") 
							# 9154 Product Flex Code already exists
							NEXT FIELD flex_code 
							EXIT FOR 
						END IF 
					END FOR 
				ELSE 
					LET pa_prodflex[idx].flex_code = pr_prodflex.flex_code 
					DISPLAY pa_prodflex[idx].flex_code 
					TO sr_prodflex[scrn].flex_code 

				END IF 
			END IF 
			CASE 
				WHEN fgl_lastkey() = fgl_keyval("accept") 
					OR fgl_lastkey() = fgl_keyval("left") 
					OR fgl_lastkey() = fgl_keyval("up") 
					IF pa_prodflex[idx].desc_text IS NULL THEN 
						LET l_msgresp = kandoomsg("I",9084,"") 
						#9084 A Description must be entered
						NEXT FIELD desc_text 
					ELSE 
						NEXT FIELD scroll_flag 
					END IF 
				WHEN fgl_lastkey() = fgl_keyval("RETURN") 
					OR fgl_lastkey() = fgl_keyval("right") 
					OR fgl_lastkey() = fgl_keyval("tab") 
					OR fgl_lastkey() = fgl_keyval("down") 
					NEXT FIELD NEXT 
				OTHERWISE 
					NEXT FIELD flex_code 
			END CASE 
		AFTER FIELD desc_text 
			IF pa_prodflex[idx].desc_text IS NULL THEN 
				LET l_msgresp = kandoomsg("I",9084,"") 
				#9084 A Description must be entered
				NEXT FIELD desc_text 
			END IF 
			CASE 
				WHEN fgl_lastkey() = fgl_keyval("accept") 
					OR fgl_lastkey() = fgl_keyval("RETURN") 
					OR fgl_lastkey() = fgl_keyval("tab") 
					OR fgl_lastkey() = fgl_keyval("right") 
					OR fgl_lastkey() = fgl_keyval("down") 
					NEXT FIELD scroll_flag 
				WHEN fgl_lastkey() = fgl_keyval("left") 
					OR fgl_lastkey() = fgl_keyval("up") 
					NEXT FIELD previous 
				OTHERWISE 
					NEXT FIELD flex_code 
			END CASE 
		ON KEY (F2) 
			IF pa_prodflex[idx].scroll_flag IS NULL THEN 
				LET pa_prodflex[idx].scroll_flag = "*" 
				LET del_cnt = del_cnt + 1 
			ELSE 
				LET pa_prodflex[idx].scroll_flag = NULL 
				LET del_cnt = del_cnt - 1 
			END IF 
			NEXT FIELD scroll_flag 
		AFTER ROW 
			DISPLAY pa_prodflex[idx].* TO sr_prodflex[scrn].* 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
				IF NOT (infield(scroll_flag)) THEN 
					IF pr_prodflex.flex_code IS NULL THEN 
						FOR idx = arr_curr() TO arr_count() 
							LET pa_prodflex[idx].* = pa_prodflex[idx+1].* 
							IF scrn <= 10 THEN 
								DISPLAY pa_prodflex[idx].* TO sr_prodflex[scrn].* 

								LET scrn = scrn + 1 
							END IF 
						END FOR 
						INITIALIZE pa_prodflex[idx].* TO NULL 
						NEXT FIELD scroll_flag 
					ELSE 
						LET pa_prodflex[idx].flex_code = pr_prodflex.flex_code 
						LET pa_prodflex[idx].desc_text = pr_prodflex.desc_text 
						NEXT FIELD scroll_flag 
					END IF 
				END IF 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	ELSE 
		FOR idx = 1 TO arr_count() 
			IF pa_prodflex[idx].flex_code IS NOT NULL THEN 
				LET pr_prodflex.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET pr_prodflex.class_code = pr_class_code 
				LET pr_prodflex.start_num = pr_start_num 
				LET pr_prodflex.flex_code = pa_prodflex[idx].flex_code 
				LET pr_prodflex.desc_text = pa_prodflex[idx].desc_text 
				UPDATE prodflex 
				SET * = pr_prodflex.* 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND class_code = pr_class_code 
				AND start_num = pr_start_num 
				AND flex_code = pr_prodflex.flex_code 
				IF sqlca.sqlerrd[3] = 0 THEN 
					INSERT INTO prodflex VALUES (pr_prodflex.*) 
				END IF 
			END IF 
		END FOR 
		IF del_cnt > 0 THEN 
			LET l_msgresp = kandoomsg("I",8029,del_cnt) 
			#8029 Confirm TO Delete ",del_cnt," Product Flex Code(s)? (Y/N)"
			IF l_msgresp = "Y" THEN 
				FOR idx = 1 TO arr_count() 
					IF pa_prodflex[idx].scroll_flag = "*" THEN 
						DELETE FROM prodflex 
						WHERE flex_code = pa_prodflex[idx].flex_code 
					END IF 
				END FOR 
			END IF 
		END IF 
	END IF 
END FUNCTION 
