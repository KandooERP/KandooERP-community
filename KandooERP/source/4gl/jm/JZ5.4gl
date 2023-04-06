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
GLOBALS "J_JM_GLOBALS.4gl" 

# Purpose - This Program allows the user TO enter AND maintain
#           Responsible persons FOR Job Management

GLOBALS 
	DEFINE 
	formname CHAR(15), 
	pa_responsible array[300] OF RECORD 
		delete_flag CHAR(1), 
		resp_code LIKE responsible.resp_code, 
		name_text LIKE responsible.name_text 
	END RECORD, 
	arr_cnt SMALLINT 
END GLOBALS 

MAIN 
	#Initial UI Init
	CALL setModuleId("JZ5") -- albo 
	CALL ui_init(0) 
	DEFER quit 
	DEFER interrupt 
	CALL authenticate(getmoduleid()) 
	OPEN WINDOW j210 with FORM "J210" -- alch kd-747 
	CALL winDecoration_j("J210") -- alch kd-747 
	WHILE select_resp() 
		CALL edit_resp() 
	END WHILE 
	CLOSE WINDOW j210 
END MAIN 


FUNCTION select_resp() 
	DEFINE 
	idx SMALLINT, 
	query_text CHAR(500), 
	where_text CHAR(200) 
	CLEAR FORM 
	WHENEVER ERROR CONTINUE 
	OPTIONS 
	DELETE KEY f36 
	WHENEVER ERROR stop 
	#MESSAGE " Enter Selection Criteria - ESC TO Continue"
	#   ATTRIBUTE(yellow)
	LET msgresp = kandoomsg("U",1001," ") 
	CONSTRUCT where_text ON 
	responsible.resp_code, 
	responsible.name_text 
	FROM 
	sr_responsible[1].resp_code, 
	sr_responsible[1].name_text 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","JZ5","const-resp_code-3") -- alch kd-506 
		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 
	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 
	LET query_text = 
	"SELECT resp_code,", 
	"name_text ", 
	"FROM responsible ", 
	"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND ",where_text clipped, 
	" ORDER BY resp_code" 
	PREPARE resp_query FROM query_text 
	DECLARE c_resp CURSOR FOR resp_query 
	LET idx = 1 
	LET arr_cnt = 0 
	FOREACH c_resp INTO pa_responsible[idx].resp_code, 
		pa_responsible[idx].name_text 
		LET pa_responsible[idx].delete_flag = NULL 
		LET arr_cnt = arr_cnt + 1 
		LET idx = idx + 1 
		IF idx > 300 THEN 
			#ERROR " First 300 Responsibility Codes Selected"
			LET msgresp = kandoomsg("U",1504," ") 
			EXIT FOREACH 
		END IF 
	END FOREACH 
	RETURN true 
END FUNCTION 


FUNCTION edit_resp() 
	DEFINE 
	pr_responsible RECORD 
		resp_code LIKE responsible.resp_code, 
		name_text LIKE responsible.name_text 
	END RECORD, 
	pv_del_no, 
	idx, scrn SMALLINT 

	#MESSAGE "F1 TO Add - F2 TO Delete - RETURN TO Edit Line"
	#   ATTRIBUTE(yellow)
	LET msgresp = kandoomsg("U",1003," ") 
	CALL set_count(arr_cnt) 
	INPUT ARRAY pa_responsible WITHOUT DEFAULTS FROM sr_responsible.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","JZ5","input_arr-pa_responsible-1") -- alch kd-506 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE ROW 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			LET pr_responsible.resp_code = pa_responsible[idx].resp_code 
			LET pr_responsible.name_text = pa_responsible[idx].name_text 

		BEFORE FIELD delete_flag 
			DISPLAY pa_responsible[idx].* TO 
			sr_responsible[scrn].* 

		AFTER FIELD delete_flag 
			#LET pa_responsible[idx].delete_flag = pr_delete_flag
			IF fgl_lastkey() = fgl_keyval("down") 
			AND pa_responsible[idx+1].resp_code IS NULL THEN 
				LET msgresp=kandoomsg("A",9001,"") 
				#9001 There are no more rows in the direction you are going.
				NEXT FIELD delete_flag 
			END IF 
			IF fgl_lastkey() = fgl_keyval("down") 
			AND arr_curr() >= arr_count() THEN 
				LET msgresp=kandoomsg("A",9001,"") 
				#9001 There are no more rows in the direction you are going.
				NEXT FIELD delete_flag 
			END IF 
		BEFORE FIELD resp_code 
			IF pr_responsible.resp_code IS NOT NULL THEN 
				NEXT FIELD name_text 
			END IF 
		AFTER FIELD resp_code 
			IF pr_responsible.resp_code IS NOT NULL THEN 
				IF pa_responsible[idx].resp_code IS NULL THEN 
					#ERROR " Responsibility Code Must be Entered"
					LET msgresp = kandoomsg("J",9491," ") 
					NEXT FIELD resp_code 
				ELSE 
					IF pa_responsible[idx].resp_code != pr_responsible.resp_code 
					AND resp_exists(pa_responsible[idx].resp_code) THEN 
						#ERROR "The Responsibiliy code must be unique"
						LET msgresp = kandoomsg("J",9492," ") 
						LET pa_responsible[idx].resp_code = NULL 
						NEXT FIELD resp_code 
					END IF 
				END IF 
			ELSE 
				IF pa_responsible[idx].resp_code IS NULL THEN 
					#ERROR " Responsibility Code Must be Entered"
					LET msgresp = kandoomsg("J",9491," ") 
					NEXT FIELD resp_code 
				END IF 
				IF resp_exists(pa_responsible[idx].resp_code) THEN 
					#ERROR "The Responsibiliy code must be unique"
					LET msgresp = kandoomsg("J",9492," ") 
					LET pa_responsible[idx].resp_code = NULL 
					NEXT FIELD resp_code 
				END IF 
			END IF 
		AFTER FIELD name_text 
			IF pa_responsible[idx].name_text IS NULL 
			AND pa_responsible[idx].resp_code IS NOT NULL THEN 
				#ERROR " Description text must be entered"
				LET msgresp = kandoomsg("J",9493," ") 
				NEXT FIELD name_text 
			END IF 
		BEFORE INSERT 
			IF idx >= arr_count() THEN 
				#ERROR "There are no more rows in this direction"
				LET msgresp = kandoomsg("U",9001," ") 
			END IF 
			INITIALIZE pr_responsible.* TO NULL 
			NEXT FIELD resp_code 
		AFTER INSERT 
			IF pa_responsible[idx].resp_code IS NOT NULL AND 
			pa_responsible[idx].name_text IS NOT NULL AND 
			(NOT resp_exists(pa_responsible[idx].resp_code)) THEN 
				LET pr_responsible.resp_code = pa_responsible[idx].resp_code 
				LET pr_responsible.name_text = pa_responsible[idx].name_text 
				INSERT INTO responsible 
				VALUES (glob_rec_kandoouser.cmpy_code, 
				pr_responsible.*) 
			END IF 

		ON KEY (f2) 
			IF pa_responsible[idx].delete_flag IS NULL THEN 
				SELECT unique 1 
				FROM activity 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND resp_code = pa_responsible[idx].resp_code 
				AND finish_flag != "Y" 
				IF status = notfound THEN 
					LET pa_responsible[idx].delete_flag = "*" 
					LET pv_del_no = pv_del_no + 1 
				ELSE 
					# Activities exist FOR this code
					LET msgresp = kandoomsg("J",9490," ") 
				END IF 
			ELSE 
				LET pa_responsible[idx].delete_flag = " " 
				LET pv_del_no = pv_del_no - 1 
			END IF 
			DISPLAY pa_responsible[idx].delete_flag TO 
			sr_responsible[scrn].delete_flag 

		AFTER ROW 
			IF pr_responsible.resp_code IS NOT NULL THEN 
				IF pa_responsible[idx].resp_code != pr_responsible.resp_code THEN 
					IF resp_exists(pa_responsible[idx].resp_code) THEN 
						#ERROR "The Responsibility Code must be unique"
						LET msgresp = kandoomsg("J",9492," ") 
						NEXT FIELD resp_code 
					END IF 
				END IF 
				IF pr_responsible.resp_code != pa_responsible[idx].resp_code 
				OR pr_responsible.name_text != pa_responsible[idx].name_text THEN 
					UPDATE responsible 
					SET resp_code = pa_responsible[idx].resp_code, 
					name_text = pa_responsible[idx].name_text 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND resp_code = pr_responsible.resp_code 
				END IF 
			ELSE 
				IF pa_responsible[idx].resp_code IS NOT NULL AND 
				pa_responsible[idx].name_text IS NOT NULL AND 
				(NOT resp_exists(pa_responsible[idx].resp_code)) THEN 
					LET pr_responsible.resp_code = pa_responsible[idx].resp_code 
					LET pr_responsible.name_text = pa_responsible[idx].name_text 
					INSERT INTO responsible 
					VALUES (glob_rec_kandoouser.cmpy_code, 
					pr_responsible.*) 
				END IF 
			END IF 
			DISPLAY pa_responsible[idx].* TO 
			sr_responsible[scrn].* 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				IF pa_responsible[idx].resp_code IS NULL THEN 
					FOR idx = arr_curr() TO arr_count() 
						LET pa_responsible[idx].* = pa_responsible[idx+1].* 
						IF arr_curr() = arr_count() THEN 
							INITIALIZE pa_responsible[idx].* TO NULL 
							EXIT FOR 
						END IF 
						IF scrn <= 10 THEN 
							DISPLAY pa_responsible[idx].* 
							TO sr_responsible[scrn].* 

							LET scrn = scrn + 1 
						END IF 
					END FOR 
					LET idx =arr_curr() 
					LET int_flag = false 
					LET quit_flag = false 
					NEXT FIELD delete_flag 
				END IF 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET quit_flag = false 
		LET int_flag = false 
	ELSE 
		IF pv_del_no > 0 THEN 
			LET msgresp = kandoomsg("J",8508,pv_del_no) 
			IF upshift(msgresp) = "Y" THEN 
				FOR idx = 1 TO arr_count() 
					IF pa_responsible[idx].delete_flag IS NOT NULL THEN 
						DELETE FROM responsible 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND resp_code = pa_responsible[idx].resp_code 
					END IF 
				END FOR 
			END IF 
		END IF 
	END IF 
END FUNCTION 


FUNCTION resp_exists(pr_resp_code) 
	DEFINE 
	cnt SMALLINT, 
	pr_resp_code LIKE responsible.resp_code 

	LET cnt = 0 
	SELECT count(*) 
	INTO cnt 
	FROM responsible 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND resp_code = pr_resp_code 
	RETURN cnt 
END FUNCTION 
