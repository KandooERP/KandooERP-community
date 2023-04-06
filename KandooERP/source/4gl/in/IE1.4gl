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

	Source code beautified by beautify.pl on 2020-01-03 09:12:36	$Id: $
}




# IE1.4gl - Dangerous Goods Classes Maintenance
#           Includes maintenance of the class/carry matrix
# IE1.4gl:FUNCTION select_dangerclasses()
#         SELECT the Dangerous Goods Classes
# IE1.4gl:FUNCTION scan_dangerclasses()
#         Maintain the Dangerous Goods Classes
# IE1.4gl:FUNCTION delete_dangerclass(pr_class_code)
#         Verify possible deletion of a Dangerous Goods Classes
# IE1.4gl:FUNCTION maintain_matrix(pr_class_code)
#         Maintain the Dangerous Goods Classes matrix
# IE1.4gl:FUNCTION update_matrix(pr_dangercarry)
#         Update the Dangerous Goods Classes Matrix
# IE1.4gl:FUNCTION update_dangerclass(pr_dangerclass)
#         Update the Dangerous Goods Classes
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "I_IN_GLOBALS.4gl" 

#Module scope variables



####################################################################
# MAIN
####################################################################
MAIN 
	#Initial UI Init
	CALL setModuleId("IE1") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_i_in() --init i/in warehouse inventory management module 

	OPEN WINDOW i651 with FORM "I651" 
	 CALL windecoration_i("I651") -- albo kd-758 
	WHILE select_dangerclasses() 
		CALL scan_dangerclasses() 
	END WHILE 
	CLOSE WINDOW i651 
END MAIN 
#
# SELECT Classes - Maintenance of Dangerous Classes
#
FUNCTION select_dangerclasses() 
	DEFINE 
	query_text CHAR(300), 
	where_text CHAR(200) 

	CLEAR FORM 
	LET msgresp = kandoomsg("I",1001,"") 
	#1001 " Enter Selection Criteria - ESC TO Continue"
	CONSTRUCT BY NAME where_text ON class_code,desc_text 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","IE1","construct-class_code-1") -- albo kd-505 

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
		LET query_text = "SELECT * FROM dangerclass ", 
		"WHERE ", where_text clipped," ", 
		"ORDER BY class_code" 
		PREPARE s_dangerclass FROM query_text 
		DECLARE c_dangerclass CURSOR FOR s_dangerclass 
		RETURN true 
	END IF 
END FUNCTION 
#
# Delete Danger Class - Verifies Deleteion of a Danger Class
#
FUNCTION delete_dangerclass(pr_class_code) 
	DEFINE 
	pr_class_code LIKE dangerclass.class_code 

	SELECT unique 1 FROM proddanger 
	WHERE proddanger.class_code = pr_class_code 
	AND proddanger.cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF status = notfound THEN 
		RETURN true 
	ELSE 
		RETURN false 
	END IF 
END FUNCTION 
#
# Maintain Matrix - Maintain the Danger Class Matrix
#
FUNCTION maintain_matrix(pr_class_code) 
	DEFINE 
	pr_class_code LIKE dangerclass.class_code, 
	pr_dangercarry RECORD LIKE dangercarry.*, 
	pr_dangerclass RECORD LIKE dangerclass.*, 
	pa_dangercarry array[1000] OF RECORD 
		scroll_flag CHAR(1), 
		class2_code LIKE dangercarry.class2_code, 
		desc_text LIKE dangerclass.desc_text, 
		carry_ind LIKE dangercarry.carry_ind 
	END RECORD, 
	pr_class_desc LIKE dangerclass.desc_text, 
	pr_scroll_flag CHAR(1), 
	idx SMALLINT #scrn 

	OPEN WINDOW i652 with FORM "I652" 
	 CALL windecoration_i("I652") -- albo kd-758 
	###-Collect the matrix combinations FOR this danger class
	LET msgresp = kandoomsg("I",1002,"") 
	#1002 " Searching database - please wait"
	DECLARE c_dangercarry1 CURSOR FOR 
	SELECT * FROM dangercarry 
	WHERE class1_code = pr_class_code 
	LET idx=0 
	FOREACH c_dangercarry1 INTO pr_dangercarry.* 
		IF pr_dangercarry.class2_code = pr_class_code THEN 
			CONTINUE FOREACH 
		END IF 
		LET idx=idx+1 
		LET pa_dangercarry[idx].class2_code = pr_dangercarry.class2_code 
		LET pa_dangercarry[idx].carry_ind = pr_dangercarry.carry_ind 
		SELECT desc_text INTO pa_dangercarry[idx].desc_text 
		FROM dangerclass 
		WHERE class_code = pa_dangercarry[idx].class2_code 
	END FOREACH 
	IF idx=0 THEN 
		LET msgresp=kandoomsg("I","9241","") 
		#9241 There are no matrix combinations FOR this dangerous goods class
		CLOSE WINDOW i652 
		RETURN 
	END IF 
	###-Collect the danger class details
	SELECT * INTO pr_dangerclass.* 
	FROM dangerclass 
	WHERE class_code = pr_class_code 
	###-DISPLAY the VALUES TO the SCREEN
	DISPLAY BY NAME pr_dangerclass.class_code 

	DISPLAY pr_dangerclass.desc_text TO class_desc 

	###-Maintain the matrix combinations
	#OPTIONS INSERT KEY F36,
	#        DELETE KEY F36
	CALL set_count(idx) 
	LET msgresp = kandoomsg("I",9248,"") 
	#9248 " Enter Segregation Rule - ESC TO Continue"
	INPUT ARRAY pa_dangercarry WITHOUT DEFAULTS FROM sr_dangercarry.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","IE1","input-arr-pa_dangercarry-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE ROW 
			#  NEXT FIELD scroll_flag
			#BEFORE FIELD scroll_flag
			LET idx = arr_curr() 
			#LET scrn = scr_line()
			#   LET pr_scroll_flag = pa_dangercarry[idx].scroll_flag
			#AFTER FIELD scroll_flag
			#   LET pa_dangercarry[idx].scroll_flag = pr_scroll_flag
			#   DISPLAY pa_dangercarry[idx].scroll_flag
			#        TO sr_dangercarry[scrn].scroll_flag
			#
			#   LET pr_dangercarry.class2_code = pa_dangercarry[idx].class2_code
			#   LET pr_dangercarry.carry_ind   = pa_dangercarry[idx].carry_ind
			#   LET pr_class_desc            = pa_dangercarry[idx].desc_text
			#  IF fgl_lastkey() = fgl_keyval("down") THEN
			#     IF pa_dangercarry[idx+1].class2_code IS NULL
			#     OR arr_curr() >= arr_count() THEN
			#        LET msgresp=kandoomsg("I",9001,"")
			#        #9001 There no more rows...
			#        NEXT FIELD scroll_flag
			#     END IF
			#  END IF
		BEFORE FIELD carry_ind 
			LET pr_dangercarry.class2_code = pa_dangercarry[idx].class2_code 
			LET pr_dangercarry.carry_ind = pa_dangercarry[idx].carry_ind 
			LET pr_class_desc = pa_dangercarry[idx].desc_text 
			# DISPLAY pa_dangercarry[idx].* TO sr_dangercarry[scrn].*

			#DISPLAY pa_dangercarry[idx].* TO sr_dangercarry[scrn].*
			#
		AFTER FIELD carry_ind 
			CASE 
				WHEN fgl_lastkey() = fgl_keyval("accept") 
					OR fgl_lastkey() = fgl_keyval("RETURN") 
					OR fgl_lastkey() = fgl_keyval("tab") 
					OR fgl_lastkey() = fgl_keyval("right") 
					OR fgl_lastkey() = fgl_keyval("down") 
					LET pr_dangercarry.class1_code = pr_dangerclass.class_code 
					LET pr_dangercarry.class2_code = pa_dangercarry[idx].class2_code 
					LET pr_dangercarry.carry_ind = pa_dangercarry[idx].carry_ind 
					LET pr_class_desc = pa_dangercarry[idx].desc_text 
					CALL update_matrix(pr_dangercarry.*) 
					IF fgl_lastkey() = fgl_keyval("down") THEN 
						IF pa_dangercarry[idx+1].class2_code IS NULL 
						OR arr_curr() >= arr_count() THEN 
							LET msgresp=kandoomsg("I",9001,"") 
							#9001 There no more rows...
							NEXT FIELD carry_ind 
						END IF 
					END IF 
					NEXT FIELD NEXT 
				OTHERWISE 
					NEXT FIELD NEXT 
			END CASE 
			# AFTER ROW
			#    DISPLAY pa_dangercarry[idx].* TO sr_dangercarry[scrn].*

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				LET pa_dangercarry[idx].class2_code = pr_dangercarry.class2_code 
				LET pa_dangercarry[idx].desc_text = pr_class_desc 
				LET pa_dangercarry[idx].carry_ind = pr_dangercarry.carry_ind 
				LET int_flag = false 
				LET quit_flag = false 
				EXIT INPUT 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 
	CLOSE WINDOW i652 
END FUNCTION 
#
# Update the Danger Class Matrix - Update the Danger Class Matrix
#
FUNCTION update_matrix(pr_dangercarry) 
	DEFINE 
	pr_dangercarry RECORD LIKE dangercarry.* 

	###-Update the matrix WHERE either combination exists
	###-Update X co-ordinate v's Y co-ordinate
	UPDATE dangercarry 
	SET carry_ind = pr_dangercarry.carry_ind 
	WHERE class1_code = pr_dangercarry.class1_code 
	AND class2_code = pr_dangercarry.class2_code 
	###-Update Y co-ordinate v's X co-ordinate
	UPDATE dangercarry 
	SET carry_ind = pr_dangercarry.carry_ind 
	WHERE class2_code = pr_dangercarry.class1_code 
	AND class1_code = pr_dangercarry.class2_code 
END FUNCTION 
#
# Scan Danger Classes - Used TO Add, Edit AND Delete Danger Classes
#
FUNCTION scan_dangerclasses() 
	DEFINE pr_dangerclass RECORD LIKE dangerclass.* 
	DEFINE pa_dangerclass array[100] OF 
	RECORD 
		scroll_flag CHAR(1), 
		class_code LIKE dangerclass.class_code, 
		desc_text LIKE dangerclass.desc_text 
	END RECORD 
	DEFINE pr_scroll_flag CHAR(1) 
	DEFINE i SMALLINT 
	DEFINE idx SMALLINT 
	#DEFINE scrn SMALLINT
	DEFINE del_cnt SMALLINT 

	DEFINE err_message CHAR(40) 

	LET idx = 0 
	FOREACH c_dangerclass INTO pr_dangerclass.* 
		LET idx = idx + 1 
		LET pa_dangerclass[idx].class_code = pr_dangerclass.class_code 
		LET pa_dangerclass[idx].desc_text = pr_dangerclass.desc_text 
		IF idx = 100 THEN 
			LET msgresp = kandoomsg("U",1022,idx) 
			#9021 " First ??? entries selected only"
			EXIT FOREACH 
		END IF 
	END FOREACH 
	IF idx = 0 THEN 
		LET msgresp = kandoomsg("U",1021,"") 
		#1021" No entries satisfied selection criteria "
		LET idx=1 
	END IF 
	OPTIONS INSERT KEY f1, 
	DELETE KEY f36 
	CALL set_count(idx) 
	LET msgresp = kandoomsg("I",1126,"") 
	#1126 " F1 TO Add - F2 TO Delete - F8 Segregation"
	INPUT ARRAY pa_dangerclass WITHOUT DEFAULTS FROM sr_dangerclass.* 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE ROW 
			LET idx = arr_curr() 
			# LET scrn = scr_line()
			NEXT FIELD scroll_flag 
		BEFORE INSERT 
			INITIALIZE pr_dangerclass.* TO NULL 
			INITIALIZE pa_dangerclass[idx].* TO NULL 
			NEXT FIELD class_code 
		BEFORE FIELD scroll_flag 
			LET pr_scroll_flag = pa_dangerclass[idx].scroll_flag 
			#DISPLAY pa_dangerclass[idx].* TO sr_dangerclass[scrn].*

		AFTER FIELD scroll_flag 
			LET pa_dangerclass[idx].scroll_flag = pr_scroll_flag 
			#DISPLAY pa_dangerclass[idx].scroll_flag
			#     TO sr_dangerclass[scrn].scroll_flag

			LET pr_dangerclass.class_code = pa_dangerclass[idx].class_code 
			LET pr_dangerclass.desc_text = pa_dangerclass[idx].desc_text 
			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF pa_dangerclass[idx+1].class_code IS NULL 
				OR arr_curr() >= arr_count() THEN 
					LET msgresp=kandoomsg("U",9001,"") 
					#9001 There no more rows...
					NEXT FIELD scroll_flag 
				END IF 
			END IF 
		BEFORE FIELD class_code 
			#DISPLAY pa_dangerclass[idx].* TO sr_dangerclass[scrn].*

			IF pr_dangerclass.class_code IS NOT NULL THEN 
				NEXT FIELD desc_text 
			END IF 
		AFTER FIELD class_code 
			CASE 
				WHEN fgl_lastkey() = fgl_keyval("accept") 
					OR fgl_lastkey() = fgl_keyval("RETURN") 
					OR fgl_lastkey() = fgl_keyval("tab") 
					OR fgl_lastkey() = fgl_keyval("right") 
					OR fgl_lastkey() = fgl_keyval("down") 
					IF pa_dangerclass[idx].class_code IS NULL THEN 
						LET msgresp=kandoomsg("I",9242,"") 
						#9242 A Danger Class Code must be entered
						NEXT FIELD class_code 
					ELSE 
						IF pr_dangerclass.class_code IS NULL THEN 
							SELECT unique 1 FROM dangerclass 
							WHERE class_code = pa_dangerclass[idx].class_code 
							IF status != notfound THEN 
								LET msgresp=kandoomsg("I",9243,"") 
								#9243 This Danger Class Code already exists
								LET pa_dangerclass[idx].class_code = 
								pr_dangerclass.class_code 
								#DISPLAY pa_dangerclass[idx].class_code TO
								#        sr_dangerclass[scrn].class_code

								NEXT FIELD class_code 
							END IF 
						ELSE 
							LET pa_dangerclass[idx].class_code = 
							pr_dangerclass.class_code 
							#DISPLAY pa_dangerclass[idx].class_code TO
							#        sr_dangerclass[scrn].class_code

						END IF 
						IF fgl_lastkey() = fgl_keyval("accept") THEN 
							IF pa_dangerclass[idx].desc_text IS NULL THEN 
								LET msgresp=kandoomsg("I",9244,"") 
								#9244 This Danger Class Description must be entered
								NEXT FIELD desc_text 
							END IF 
							NEXT FIELD scroll_flag 
						END IF 
						NEXT FIELD NEXT 
					END IF 
				OTHERWISE 
					NEXT FIELD class_code 
			END CASE 
		AFTER FIELD desc_text 
			CASE 
				WHEN fgl_lastkey() = fgl_keyval("accept") 
					OR fgl_lastkey() = fgl_keyval("RETURN") 
					OR fgl_lastkey() = fgl_keyval("tab") 
					OR fgl_lastkey() = fgl_keyval("right") 
					OR fgl_lastkey() = fgl_keyval("down") 
					IF pa_dangerclass[idx].desc_text IS NULL THEN 
						LET msgresp=kandoomsg("I",9244,"") 
						#9244 This Danger Class Description must be entered
						NEXT FIELD desc_text 
					ELSE 
						LET pr_dangerclass.class_code = pa_dangerclass[idx].class_code 
						LET pr_dangerclass.desc_text = pa_dangerclass[idx].desc_text 
						IF NOT update_dangerclass(pr_dangerclass.*) 
						THEN 
							RETURN 
						END IF 
						NEXT FIELD scroll_flag 
					END IF 
				WHEN fgl_lastkey() = fgl_keyval("left") 
					OR fgl_lastkey() = fgl_keyval("up") 
					NEXT FIELD previous 
				OTHERWISE 
					NEXT FIELD class_code 
			END CASE 
		ON KEY (F2) #delete 
			IF infield(scroll_flag) THEN 
				IF pa_dangerclass[idx].scroll_flag IS NULL THEN 
					IF delete_dangerclass(pa_dangerclass[idx].class_code) 
					THEN 
						LET pa_dangerclass[idx].scroll_flag = "*" 
						LET del_cnt = del_cnt + 1 
					ELSE 
						LET msgresp=kandoomsg("I",9245,"") 
						#9245 This danger class IS currently used with products
					END IF 
				ELSE 
					LET pa_dangerclass[idx].scroll_flag = NULL 
					LET del_cnt = del_cnt - 1 
				END IF 
				NEXT FIELD scroll_flag 
			END IF 
		ON KEY (F8) 
			IF infield(scroll_flag) THEN 
				CALL maintain_matrix(pa_dangerclass[idx].class_code) 
			END IF 
			OPTIONS INSERT KEY f1, 
			DELETE KEY f2 
			#AFTER ROW
			#   DISPLAY pa_dangerclass[idx].* TO sr_dangerclass[scrn].*

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				IF NOT infield(scroll_flag) THEN 
					IF pr_dangerclass.class_code IS NULL THEN 
						#FOR idx = arr_curr() TO arr_count()
						#   LET pa_dangerclass[idx].* = pa_dangerclass[idx+1].*
						#IF scrn <= 6 THEN
						#   DISPLAY pa_dangerclass[idx].* TO sr_dangerclass[scrn].*
						#
						#   LET scrn = scrn + 1
						#END IF
						#END FOR
						#INITIALIZE pa_dangerclass[idx].* TO NULL
						#IF idx <= 6 THEN
						#   DISPLAY pa_dangerclass[idx].* TO sr_dangerclass[scrn].*
						#
						#END IF
					ELSE 
						LET pa_dangerclass[idx].class_code = pr_dangerclass.class_code 
						LET pa_dangerclass[idx].desc_text = pr_dangerclass.desc_text 
					END IF 
					LET int_flag = false 
					LET quit_flag = false 
					NEXT FIELD scroll_flag 
				END IF 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	GOTO bypass 
	LABEL recovery: 
	IF error_recover(err_message, status) = "N" THEN 
		CLOSE WINDOW i651 
		EXIT program 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	BEGIN WORK 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		ELSE 
			IF del_cnt > 0 THEN 
				LET msgresp = kandoomsg("I",8008,del_cnt) 
				#8012 Confirm TO Delete ",del_cnt," Danger Class(es) (Y/N)?"
				IF msgresp = "Y" THEN 
					FOR idx = 1 TO arr_count() 
						IF pa_dangerclass[idx].scroll_flag = "*" THEN 
							LET err_message = "IE1 - Deleting danger class code AND carry" 
							###-Delete Danger Class
							DELETE FROM dangerclass 
							WHERE class_code = pa_dangerclass[idx].class_code 
							###-Delete X carry matrix co-ordinates
							LET err_message = "IE1 - Deleting danger carry - part 1" 
							DELETE FROM dangercarry 
							WHERE class1_code = pa_dangerclass[idx].class_code 
							###-Delete Y carry matrix co-ordinates
							LET err_message = "IE1 - Deleting danger carry - part 2" 
							DELETE FROM dangercarry 
							WHERE class2_code = pa_dangerclass[idx].class_code 
						END IF 
					END FOR 
				END IF 
			END IF 
		END IF 
	COMMIT WORK 
END FUNCTION 
#
# Delete Danger Class - Verifies Deleteion of a Danger Class
#
FUNCTION update_dangerclass(pr_dangerclass) 
	DEFINE pr_class1_code LIKE dangercarry.class1_code 
	DEFINE pr_dangerclass RECORD LIKE dangerclass.* 
	DEFINE pa_dangerclass RECORD LIKE dangerclass.* 
	DEFINE pr_dangercarry RECORD LIKE dangercarry.* 
	DEFINE err_message CHAR(40) 

	GOTO bypass 
	LABEL recovery: 
	IF error_recover(err_message, status) = "N" THEN 
		RETURN false 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	BEGIN WORK 
		LET err_message = "IE1 - Update dangerclass table" 
		UPDATE dangerclass 
		SET * = pr_dangerclass.* 
		WHERE class_code = pr_dangerclass.class_code 
		IF sqlca.sqlerrd[3] = 0 THEN 
			LET err_message = "IE1 - Insert INTO dangerclass table" 
			INSERT INTO dangerclass VALUES (pr_dangerclass.*) 
			###-Insert the all the valid combinations of danger class codes
			###-Declare X co-ordinates
			DECLARE c_dangerclass2 CURSOR FOR 
			SELECT * FROM dangerclass 
			###-Declare Y co-ordinates
			DECLARE c_dangercarry2 CURSOR FOR 
			SELECT unique(class1_code) FROM dangercarry 
			WHERE class1_code != pr_dangerclass.class_code 
			###-Insert the X co-ordinates
			LET pr_dangercarry.class1_code = pr_dangerclass.class_code 
			LET pr_dangercarry.carry_ind = NULL 
			LET err_message = "IE1 - Insert dangercarry X co-ordinates" 
			FOREACH c_dangerclass2 INTO pa_dangerclass.* 
				LET pr_dangercarry.class2_code = pa_dangerclass.class_code 
				INSERT INTO dangercarry VALUES (pr_dangercarry.*) 
			END FOREACH 
			###-Insert the Y co-ordinates
			LET err_message = "IE1 - Insert dangercarry Y co-ordinates" 
			FOREACH c_dangercarry2 INTO pr_class1_code 
				INITIALIZE pr_dangercarry.* TO NULL 
				LET pr_dangercarry.class1_code = pr_class1_code 
				LET pr_dangercarry.class2_code = pr_dangerclass.class_code 
				LET pr_dangercarry.carry_ind = NULL 
				INSERT INTO dangercarry VALUES (pr_dangercarry.*) 
			END FOREACH 
		END IF 
	COMMIT WORK 
	RETURN true 
END FUNCTION 
