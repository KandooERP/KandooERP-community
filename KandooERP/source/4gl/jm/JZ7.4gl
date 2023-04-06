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

	Source code beautified by beautify.pl on 2020-01-02 19:48:29	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "J_JM_GLOBALS.4gl" 

{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module JZ7 allows the user TO maintain the Departments

GLOBALS 
	DEFINE 
	pr_department RECORD 
		dept_code LIKE department.dept_code, 
		dept_text LIKE department.dept_text 
	END RECORD, 
	pa_department array[600] OF RECORD 
		delete_flag CHAR(1), 
		dept_code LIKE department.dept_code, 
		dept_text LIKE department.dept_text 
	END RECORD, 
	idx, id_flag, scrn, err_flag SMALLINT 

END GLOBALS 


MAIN 
	#Initial UI Init
	CALL setModuleId("JZ7") -- albo 
	CALL ui_init(0) 
	DEFER quit 
	DEFER interrupt 
	CALL authenticate(getmoduleid()) 
	OPTIONS INSERT KEY f1, 
	DELETE KEY f36 
	OPEN WINDOW j186 with FORM "J186" -- alch kd-747 
	CALL winDecoration_j("J186") -- alch kd-747 
	WHILE select_dept() 
		CALL scan_dept() 
		CLEAR FORM 
	END WHILE 
	CLOSE WINDOW j186 
END MAIN 


FUNCTION select_dept() 
	DEFINE 
	query_text CHAR(200), 
	where_text CHAR(100) 
	LET msgresp=kandoomsg("U",1001,"") 
	#1001 Enter Selection Criteria;  OK TO Continue."
	CONSTRUCT BY NAME where_text ON 
	dept_code, 
	dept_text 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","JZ7","const-dept_code-2") -- alch kd-506 
		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 
	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		LET query_text = 
		"SELECT * ", 
		"FROM department ", 
		"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
		"AND ",where_text clipped," ", 
		"ORDER BY cmpy_code,", 
		"dept_code" 
		PREPARE s_department FROM query_text 
		DECLARE c_department CURSOR FOR s_department 
		RETURN true 
	END IF 
END FUNCTION 


FUNCTION scan_dept() 
	DEFINE 
	pr_department RECORD LIKE department.*, 
	pa_department array[100] OF RECORD 
		scroll_flag CHAR(1), 
		dept_code LIKE department.dept_code, 
		dept_text LIKE department.dept_text 
	END RECORD, 
	pr_scroll_flag CHAR(1), 
	idx,scrn,del_cnt SMALLINT 

	LET idx = 0 
	LET del_cnt = 0 
	FOREACH c_department INTO pr_department.* 
		LET idx = idx + 1 
		LET pa_department[idx].scroll_flag = NULL 
		LET pa_department[idx].dept_code = pr_department.dept_code 
		LET pa_department[idx].dept_text = pr_department.dept_text 
		IF idx = 100 THEN 
			LET msgresp=kandoomsg("J",1562,idx) 
			#1562 " First 100 Department Codes selected"
			EXIT FOREACH 
		END IF 
	END FOREACH 
	IF idx = 0 THEN 
		LET idx = 1 
	END IF 
	LET msgresp=kandoomsg("U",9113,idx) 
	#9113 "idx" records selected.
	CALL set_count(idx) 
	LET msgresp=kandoomsg("U",1003,"100") 
	#1003 F1 TO Add;  F2 TO delete;  ENTER on line TO Edit.
	INPUT ARRAY pa_department WITHOUT DEFAULTS FROM sr_department.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","JZ7","input_arr-pa_department-1") -- alch kd-506 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE ROW 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			NEXT FIELD scroll_flag 
		BEFORE FIELD scroll_flag 
			LET pr_scroll_flag = pa_department[idx].scroll_flag 
			DISPLAY pa_department[idx].* 
			TO sr_department[scrn].* 

		AFTER FIELD scroll_flag 
			LET pa_department[idx].scroll_flag = pr_scroll_flag 
			IF fgl_lastkey() = fgl_keyval("down") 
			AND pa_department[idx+1].dept_code IS NULL THEN 
				LET msgresp=kandoomsg("J",9001,"") 
				#9001 There are no more rows in the direction you are going.
				NEXT FIELD scroll_flag 
			END IF 
			IF fgl_lastkey() = fgl_keyval("down") 
			AND arr_curr() >= arr_count() THEN 
				LET msgresp=kandoomsg("J",9001,"") 
				#9001 There are no more rows in the direction you are going.
				NEXT FIELD scroll_flag 
			END IF 
		BEFORE FIELD dept_code 
			IF pa_department[idx].dept_code IS NOT NULL THEN 
				NEXT FIELD dept_text 
			END IF 
		AFTER FIELD dept_code 
			IF pa_department[idx].dept_code IS NULL THEN 
				LET msgresp=kandoomsg("J",9498,"") 
				#9498 Department Code must be entered.
				NEXT FIELD dept_code 
			ELSE 
				SELECT unique 1 FROM department 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND dept_code = pa_department[idx].dept_code 
				IF status = 0 THEN 
					LET msgresp=kandoomsg("J",9499,"") 
					#9499 Department Code already exists;  Please Re Enter.
					LET pa_department[idx].dept_code = NULL 
					NEXT FIELD dept_code 
				END IF 
				NEXT FIELD dept_text 
			END IF 
		BEFORE INSERT 
			INITIALIZE pa_department[idx].* TO NULL 
			IF arr_curr() < arr_count() THEN 
				NEXT FIELD dept_code 
			END IF 
		AFTER ROW 
			LET pr_department.cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF pa_department[idx].dept_code IS NOT NULL THEN 
				UPDATE department 
				SET dept_text = pa_department[idx].dept_text 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND dept_code = pa_department[idx].dept_code 
				IF sqlca.sqlerrd[3] = 0 THEN 
					INSERT INTO department VALUES (glob_rec_kandoouser.cmpy_code,pa_department[idx].dept_code, 
					pa_department[idx].dept_text) 
				END IF 
			ELSE 
				INITIALIZE pa_department[idx].* TO NULL 
			END IF 
			DISPLAY pa_department[idx].* 
			TO sr_department[scrn].* 

		ON KEY (F2) 
			IF pa_department[idx].dept_code IS NOT NULL THEN 
				IF pa_department[idx].scroll_flag IS NULL THEN 
					IF dept_inuse(pa_department[idx].dept_code) THEN 
						LET msgresp=kandoomsg("J",9489,"") 
						#9489 Unit Code in use; Delete NOT allowed.
					ELSE 
						LET pa_department[idx].scroll_flag = "*" 
						LET del_cnt = del_cnt + 1 
					END IF 
				ELSE 
					LET pa_department[idx].scroll_flag = NULL 
					LET del_cnt = del_cnt - 1 
				END IF 
			END IF 
			NEXT FIELD scroll_flag 
		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				IF pa_department[idx].dept_code IS NULL THEN 
					FOR idx = arr_curr() TO arr_count() 
						LET pa_department[idx].* = pa_department[idx+1].* 
						IF arr_curr() = arr_count() THEN 
							INITIALIZE pa_department[idx].* TO NULL 
							EXIT FOR 
						END IF 
						IF scrn <= 10 THEN 
							DISPLAY pa_department[idx].* 
							TO sr_department[scrn].* 

							LET scrn = scrn + 1 
						END IF 
					END FOR 
					LET idx =arr_curr() 
					LET int_flag = false 
					LET quit_flag = false 
					NEXT FIELD scroll_flag 
				END IF 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	ELSE 
		IF del_cnt > 0 THEN 
			LET msgresp=kandoomsg("J",8015,del_cnt) 
			#8015 Confirmation TO Delete del_cnt Department Codes (Y/N)?:
			IF msgresp = "Y" THEN 
				FOR idx = 1 TO arr_count() 
					IF pa_department[idx].scroll_flag IS NOT NULL THEN 
						IF dept_inuse(pa_department[idx].dept_code) THEN 
							LET msgresp=kandoomsg("J",7014,pa_department[idx].dept_code) 
							#7014 Department code in use delete NOT allowed.
							#     Any key TO continue.
						ELSE 
							DELETE FROM department 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND dept_code = pa_department[idx].dept_code 
						END IF 
					END IF 
				END FOR 
			END IF 
		END IF 
	END IF 
END FUNCTION 


FUNCTION dept_inuse(pr_dept_code) 
	DEFINE 
	pr_dept_code LIKE department.dept_code 

	SELECT unique 1 FROM person 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND dept_code = pr_dept_code 
	IF status = 0 THEN 
		RETURN true 
	END IF 
	RETURN false 
END FUNCTION 
