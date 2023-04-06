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




#   IE2 - Dangerous Goods Maintenance
#   IE2.4gl:FUNCTION select_danger()
#   IE2.4gl:FUNCTION check_class(pr_class_code)
#   IE2.4gl:FUNCTION delete_danger(pr_dg_code)
#   IE2.4gl:FUNCTION scan_danger()
#   IE2.4gl:FUNCTION edit_proddanger(pr_dg_code)
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "I_IN_GLOBALS.4gl" 

#Module Scope Variables
DEFINE err_message CHAR(40) 

####################################################################
# MAIN
####################################################################
MAIN 
	#Initial UI Init
	CALL setModuleId("IE2") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_i_in() --init i/in warehouse inventory management module 

	OPEN WINDOW i653 with FORM "I653" 
	 CALL windecoration_i("I653") -- albo kd-758 
	WHILE select_danger() 
		CALL scan_danger() 
	END WHILE 
	CLOSE WINDOW i653 
END MAIN 
#
#  SELECT Dangerous Goods - SELECT Dangerous Goods TO Maintain
#
FUNCTION select_danger() 
	DEFINE 
	query_text CHAR(300), 
	where_text CHAR(200) 

	CLEAR FORM 
	LET msgresp = kandoomsg("I",1001,"") 
	#1001 " Enter Selection Criteria - ESC TO Continue"
	CONSTRUCT BY NAME where_text ON dg_code, tech_text, class_code 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","IE2","construct-dg_code-1") -- albo kd-505 

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
		LET query_text = "SELECT * FROM proddanger ", 
		"WHERE ", where_text clipped," ", 
		"AND cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"ORDER BY dg_code, cmpy_code" 
		PREPARE s_proddanger FROM query_text 
		DECLARE c_proddanger CURSOR FOR s_proddanger 
		RETURN true 
	END IF 
END FUNCTION 
#
#  Check Dangerous Class - Verify the Dangerous Class exists
#
FUNCTION check_class(pr_class_code) 
	DEFINE 
	pr_class_code LIKE dangerclass.class_code 

	SELECT unique 1 FROM dangerclass 
	WHERE dangerclass.class_code = pr_class_code 
	IF status = notfound THEN 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 
#
#  Delete Dangerous Goods - Verify use with othe related tables
#
FUNCTION delete_danger(pr_dg_code) 
	DEFINE 
	pr_dg_code LIKE proddanger.dg_code 

	###-Verify that the Dangerous Good Code does NOT exist in Orders
	SELECT unique 1 
	FROM product 
	WHERE dg_code = pr_dg_code 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF status = notfound THEN 
		RETURN true 
	ELSE 
		RETURN false 
	END IF 
END FUNCTION 
#
#  Scan Dangerous Goods - Maintain Dangerous Goods
#
FUNCTION scan_danger() 
	DEFINE 
	pr_proddanger RECORD LIKE proddanger.*, 
	pa_proddanger array[100] OF RECORD 
		scroll_flag CHAR(1), 
		dg_code LIKE proddanger.dg_code, 
		tech_text LIKE proddanger.tech_text, 
		class_code LIKE proddanger.class_code 
	END RECORD, 
	pr_scroll_flag CHAR(1), 
	i,idx,scrn,del_cnt, pr_curr, pr_cnt, pr_rowid, x SMALLINT, 
	vcount INTEGER 

	LET idx = 0 
	FOREACH c_proddanger INTO pr_proddanger.* 
		LET idx = idx + 1 
		LET pa_proddanger[idx].dg_code = pr_proddanger.dg_code 
		LET pa_proddanger[idx].tech_text = pr_proddanger.tech_text 
		LET pa_proddanger[idx].class_code = pr_proddanger.class_code 
		IF idx = 100 THEN 
			LET msgresp = kandoomsg("U",1505,idx) 
			#1505 " First ??? entries Selected Only"
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
	LET msgresp = kandoomsg("U",1003,"") 
	#1003 " F1 TO Add - F2 TO Delete - RETURN on line TO Edit "
	INPUT ARRAY pa_proddanger WITHOUT DEFAULTS FROM sr_proddanger.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","IE2","input-pa_proddanger-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE FIELD scroll_flag 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			LET pr_scroll_flag = pa_proddanger[idx].scroll_flag 
			DISPLAY pa_proddanger[idx].* TO sr_proddanger[scrn].* 

		AFTER FIELD scroll_flag 
			LET pa_proddanger[idx].scroll_flag = pr_scroll_flag 
			DISPLAY pa_proddanger[idx].scroll_flag 
			TO sr_proddanger[scrn].scroll_flag 

			LET pr_proddanger.dg_code = pa_proddanger[idx].dg_code 
			LET pr_proddanger.tech_text = pa_proddanger[idx].tech_text 
			LET pr_proddanger.class_code = pa_proddanger[idx].class_code 
			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF pa_proddanger[idx+1].dg_code IS NULL 
				OR arr_curr() >= arr_count() THEN 
					LET msgresp=kandoomsg("U",3513,"") 
					#3513 There no more rows...
					NEXT FIELD scroll_flag 
				END IF 
			END IF 
		BEFORE FIELD dg_code 
			IF pa_proddanger[idx].dg_code IS NOT NULL THEN 
				LET pr_proddanger.dg_code = pa_proddanger[idx].dg_code 
				IF edit_proddanger(pr_proddanger.dg_code) THEN 
					SELECT * INTO pr_proddanger.* FROM proddanger 
					WHERE dg_code = pr_proddanger.dg_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					LET pa_proddanger[idx].dg_code = pr_proddanger.dg_code 
					LET pa_proddanger[idx].tech_text = pr_proddanger.tech_text 
					LET pa_proddanger[idx].class_code = pr_proddanger.class_code 
				END IF 
			END IF 
			OPTIONS INSERT KEY f1, 
			DELETE KEY f36 
			NEXT FIELD scroll_flag 
		BEFORE INSERT 
			IF arr_curr() < arr_count() THEN 
				LET pr_curr = arr_curr() 
				LET pr_cnt = arr_count() 
				LET pr_rowid = edit_proddanger("") 
				OPTIONS INSERT KEY f1, 
				DELETE KEY f36 
				IF pr_rowid = 0 THEN 
					FOR idx = pr_curr TO pr_cnt 
						LET pa_proddanger[idx].* = pa_proddanger[idx+1].* 
						IF scrn <= 10 THEN 
							DISPLAY pa_proddanger[idx].* TO sr_proddanger[scrn].* 

							LET scrn = scrn + 1 
						END IF 
					END FOR 
					INITIALIZE pa_proddanger[idx].* TO NULL 
				ELSE 
					SELECT * INTO pr_proddanger.* FROM proddanger 
					WHERE rowid = pr_rowid 
					LET pa_proddanger[idx].dg_code = pr_proddanger.dg_code 
					LET pa_proddanger[idx].tech_text = pr_proddanger.tech_text 
					LET pa_proddanger[idx].class_code = pr_proddanger.class_code 
				END IF 
			ELSE 
				IF idx > 1 THEN 
					LET msgresp = kandoomsg("U",3513,"") 
					#3513 There are no more rows....
				END IF 
			END IF 
		ON KEY (F2) 
			IF pa_proddanger[idx].scroll_flag IS NULL THEN 
				IF delete_danger(pa_proddanger[idx].dg_code) 
				THEN 
					LET pa_proddanger[idx].scroll_flag = "*" 
					LET del_cnt = del_cnt + 1 
				ELSE 
					LET msgresp = kandoomsg("I",9247,"") 
					#9247 This dangerous goods code IS currently...
				END IF 
			ELSE 
				LET pa_proddanger[idx].scroll_flag = NULL 
				LET del_cnt = del_cnt - 1 
			END IF 
			NEXT FIELD scroll_flag 
		AFTER ROW 
			DISPLAY pa_proddanger[idx].* 
			TO sr_proddanger[scrn].* 

		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 

	GOTO bypass 
	LABEL recovery: 
	IF error_recover(err_message, status) = "N" THEN 
		CLOSE WINDOW i653 
		RETURN false 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	BEGIN WORK 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		ELSE 
			IF del_cnt > 0 THEN 
				LET msgresp = kandoomsg("I",8013,del_cnt) 
				#8013 "Confirm TO Delete ",del_cnt," Dangerous Goods Code(s)? (Y/N)"
				IF msgresp = "Y" THEN 
					FOR idx = 1 TO arr_count() 
						IF pa_proddanger[idx].scroll_flag = "*" THEN 
							DELETE FROM proddanger 
							WHERE dg_code = pa_proddanger[idx].dg_code 
							AND cmpy_code = glob_rec_kandoouser.cmpy_code 
						END IF 
					END FOR 
				END IF 
			END IF 
		END IF 
	COMMIT WORK 
END FUNCTION 
#
#  Edit Dangerous Goods - Edit a Dangerous Good
#
FUNCTION edit_proddanger(pr_dg_code) 
	DEFINE 
	ps_proddanger RECORD LIKE proddanger.*, 
	pr_proddanger RECORD LIKE proddanger.*, 
	pr_dangerclass RECORD LIKE dangerclass.*, 
	pr_dg_code LIKE proddanger.dg_code, 
	pr_temp_text CHAR(20), 
	pr_sqlerrd INTEGER 

	INITIALIZE pr_proddanger.* TO NULL 
	IF pr_dg_code IS NOT NULL THEN 
		SELECT * INTO pr_proddanger.* FROM proddanger 
		WHERE dg_code = pr_dg_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	ELSE 
		LET pr_proddanger.cmpy_code = glob_rec_kandoouser.cmpy_code 
	END IF 

	OPEN WINDOW i654 with FORM "I654" 
	 CALL windecoration_i("I654") -- albo kd-758 
	DISPLAY BY NAME pr_proddanger.dg_code, 
	pr_proddanger.tech_text, 
	pr_proddanger.class_code, 
	pr_proddanger.un_num_text, 
	pr_proddanger.pkg_code, 
	pr_proddanger.con_text, 
	pr_proddanger.hazchem_code 

	SELECT * INTO pr_dangerclass.* 
	FROM dangerclass 
	WHERE dangerclass.class_code = pr_proddanger.class_code 
	LET msgresp = kandoomsg("U","1020","Dangerous Goods") 
	DISPLAY BY NAME pr_dangerclass.desc_text 

	INPUT BY NAME pr_proddanger.dg_code, 
	pr_proddanger.tech_text, 
	pr_proddanger.class_code, 
	pr_proddanger.un_num_text, 
	pr_proddanger.pkg_code, 
	pr_proddanger.con_text, 
	pr_proddanger.hazchem_code 
	WITHOUT DEFAULTS 


		BEFORE FIELD dg_code 
			IF pr_dg_code IS NOT NULL THEN 
				NEXT FIELD tech_text 
			END IF 
		AFTER FIELD dg_code 
			IF pr_proddanger.dg_code IS NULL THEN 
				LET msgresp = kandoomsg("I",9236,"") 
				#9236 Dangerous goods code must be entered
				NEXT FIELD dg_code 
			END IF 
			SELECT * INTO ps_proddanger.* FROM proddanger 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND dg_code = pr_proddanger.dg_code 
			IF status != notfound THEN 
				LET msgresp = kandoomsg("I",9237,"") 
				#9237 Dangerous goods code already exists
				NEXT FIELD dg_code 
			END IF 
		AFTER FIELD tech_text 
			IF pr_proddanger.tech_text IS NULL THEN 
				LET msgresp = kandoomsg("I",9240,"") 
				#9240 A dangerous goods technical description must be entered
				NEXT FIELD tech_text 
			END IF 
		AFTER FIELD class_code 
			IF pr_proddanger.class_code IS NOT NULL THEN 
				IF NOT check_class(pr_proddanger.class_code) 
				THEN 
					LET msgresp = kandoomsg("I",9238,"") 
					#9238 Dangerous goods class does NOT exist...
					NEXT FIELD class_code 
				ELSE 
					SELECT * INTO pr_dangerclass.* 
					FROM dangerclass 
					WHERE dangerclass.class_code = pr_proddanger.class_code 
					DISPLAY BY NAME pr_dangerclass.desc_text 

				END IF 
			ELSE 
				LET msgresp = kandoomsg("I",9239,"") 
				#9239 Dangerous goods class must be entered
				NEXT FIELD class_code 
			END IF 
		ON KEY (control-b) 
			CASE 
				WHEN infield(class_code) 
					LET pr_temp_text = show_dangclass(glob_rec_kandoouser.cmpy_code,"") 
					IF pr_temp_text IS NOT NULL THEN 
						LET pr_proddanger.class_code = pr_temp_text 
					END IF 
					NEXT FIELD class_code 
			END CASE 
		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN 
				IF pr_proddanger.dg_code IS NULL THEN 
					LET msgresp = kandoomsg("I",9236,"") 
					#9236 Dangerous goods code must be entered
					NEXT FIELD dg_code 
				END IF 
				IF pr_proddanger.tech_text IS NULL THEN 
					LET msgresp = kandoomsg("I",9240,"") 
					#9240 A dangerous goods technical description must be entered
					NEXT FIELD tech_text 
				END IF 
				IF pr_proddanger.class_code IS NULL THEN 
					LET msgresp = kandoomsg("I",9239,"") 
					#9239 Dangerous goods class must be entered
					NEXT FIELD class_code 
				ELSE 
					IF NOT check_class(pr_proddanger.class_code) 
					THEN 
						LET msgresp = kandoomsg("I",9238,"") 
						#9238 Dangerous goods class does NOT exist
						NEXT FIELD class_code 
					END IF 
				END IF 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET quit_flag = false 
		LET int_flag = false 
		CLOSE WINDOW i654 
		RETURN false 
	END IF 
	GOTO bypass 
	LABEL recovery: 
	IF error_recover(err_message, status) = "N" THEN 
		--AND WHERE was it opened? CLOSE WINDOW I650
		RETURN false 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	BEGIN WORK 
		LET err_message = "IE2 - Insert INTO proddanger " 
		IF pr_dg_code IS NULL THEN 
			INSERT INTO proddanger VALUES (pr_proddanger.*) 
			LET pr_sqlerrd = sqlca.sqlerrd[6] 
		ELSE 
			LET err_message = "IE2 - Update INTO proddanger " 
			UPDATE proddanger 
			SET * = pr_proddanger.* 
			WHERE dg_code = pr_proddanger.dg_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET pr_sqlerrd = sqlca.sqlerrd[3] 
		END IF 
	COMMIT WORK 
	CLOSE WINDOW i654 
	RETURN pr_sqlerrd 
END FUNCTION 
