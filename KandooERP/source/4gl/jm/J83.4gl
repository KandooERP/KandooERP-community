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

	Source code beautified by beautify.pl on 2020-01-02 19:48:14	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "J_JM_GLOBALS.4gl" 
GLOBALS "J8_GLOBALS.4gl" 
#GLOBALS "J81_GLOBALS.4gl"

#      J83 - Allows the user TO enter AND maintain persons

MAIN 
	#Initial UI Init
	CALL setModuleId("J83") -- albo 
	CALL ui_init(0) 
	DEFER quit 
	DEFER interrupt 
	CALL authenticate(getmoduleid()) 
	SELECT * INTO pr_jmparms.* FROM jmparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND key_code = "1" 
	IF status = notfound THEN 
		LET msgresp = kandoomsg("J",7002,"") 
		#7002 "Must SET up JM Parameters first in JZP"
		EXIT program 
	END IF 
	OPEN WINDOW j142 with FORM "J142" -- alch kd-747 
	CALL winDecoration_j("J142") -- alch kd-747 
	WHILE select_person() 
	END WHILE 
	CLOSE WINDOW j142 
END MAIN 

FUNCTION select_person() 
	DEFINE 
	query_text CHAR(700), 
	where_text CHAR(500), 
	pr_person RECORD LIKE person.*, 
	pr_taskperiod RECORD LIKE taskperiod.*, 
	pa_person array[200] OF RECORD 
		scroll_flag CHAR(1), 
		person_code LIKE person.person_code, 
		name_text LIKE person.name_text, 
		dept_code LIKE person.dept_code, 
		task_period_ind LIKE person.task_period_ind, 
		task_period_text LIKE taskperiod.task_period_text, 
		active_flag LIKE person.active_flag 
	END RECORD, 
	pr_err_message CHAR(60), 
	pr_scroll_flag CHAR(1), 
	pr_del_num, i, idx, scrn SMALLINT 

	CLEAR FORM 
	LET msgresp = kandoomsg("U",1001,"") 
	#1001 Enter Selection Criteria; OK TO Continue.
	CONSTRUCT BY NAME where_text ON 
	person_code, 
	name_text, 
	dept_code, 
	task_period_ind, 
	active_flag 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","J83","const-person_code-2") -- alch kd-506 
		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 
	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 
	LET query_text = "SELECT * FROM person ", 
	" WHERE person.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	" AND ",where_text clipped," ", 
	"ORDER BY person_code" 
	PREPARE s_person FROM query_text 
	DECLARE c_person CURSOR FOR s_person 
	LET idx = 0 
	FOREACH c_person INTO pr_person.* 
		LET idx = idx + 1 
		LET pa_person[idx].person_code = pr_person.person_code 
		LET pa_person[idx].name_text = pr_person.name_text 
		LET pa_person[idx].dept_code = pr_person.dept_code 
		LET pa_person[idx].task_period_ind = pr_person.task_period_ind 
		LET pa_person[idx].active_flag = pr_person.active_flag 
		SELECT task_period_text INTO pa_person[idx].task_period_text 
		FROM taskperiod 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND task_period_ind = pr_person.task_period_ind 
		IF idx = 200 THEN 
			LET msgresp = kandoomsg("U",6100,idx) 
			#6100 "First idx Persons Selected Only"
			EXIT FOREACH 
		END IF 
	END FOREACH 
	LET msgresp = kandoomsg("U",9113,idx) 
	# idx records selected.
	IF idx = 0 THEN 
		LET idx = 1 
		INITIALIZE pa_person[idx].* TO NULL 
	END IF 
	CALL set_count(idx) 
	LET msgresp = kandoomsg("J",1009,"") 
	#1003 F1 TO Add; F2 TO Delete; ENTER TO Edit.
	LET pr_del_num = 0 
	INPUT ARRAY pa_person WITHOUT DEFAULTS FROM sr_person.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","J83","input_arr-pa_person-1") -- alch kd-506 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE ROW 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
		BEFORE FIELD scroll_flag 
			OPTIONS INSERT KEY f1, 
			DELETE KEY f36 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			LET pr_scroll_flag = pa_person[idx].scroll_flag 
			DISPLAY pa_person[idx].* TO sr_person[scrn].* 

		AFTER FIELD scroll_flag 
			LET pa_person[idx].scroll_flag = pr_scroll_flag 
			DISPLAY pa_person[idx].* TO sr_person[scrn].* 

			IF fgl_lastkey() = fgl_keyval("down") 
			AND arr_curr() >= arr_count() THEN 
				LET msgresp = kandoomsg("U",9001,"") 
				#9001 There no more rows...
				NEXT FIELD scroll_flag 
			END IF 
		BEFORE FIELD person_code 
			CALL edit_person(pa_person[idx].person_code) 
			RETURNING pr_person.* 
			IF pr_person.person_code IS NOT NULL THEN 
				SELECT * INTO pr_person.* FROM person 
				WHERE person_code = pa_person[idx].person_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET pa_person[idx].person_code = pr_person.person_code 
				LET pa_person[idx].name_text = pr_person.name_text 
				LET pa_person[idx].dept_code = pr_person.dept_code 
				LET pa_person[idx].task_period_ind = pr_person.task_period_ind 
				SELECT task_period_text INTO pa_person[idx].task_period_text 
				FROM taskperiod 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND task_period_ind = pr_person.task_period_ind 
			END IF 
			NEXT FIELD scroll_flag 
		BEFORE INSERT 
			CALL edit_person(pa_person[idx].person_code) 
			RETURNING pr_person.* 
			IF pr_person.person_code IS NOT NULL THEN 
				LET pa_person[idx].person_code = pr_person.person_code 
				LET pa_person[idx].name_text = pr_person.name_text 
				LET pa_person[idx].dept_code = pr_person.dept_code 
				LET pa_person[idx].task_period_ind = pr_person.task_period_ind 
				SELECT task_period_text INTO pa_person[idx].task_period_text 
				FROM taskperiod 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND task_period_ind = pr_person.task_period_ind 
			ELSE 
				FOR i = arr_curr() TO arr_count() 
					LET pa_person[i].* = pa_person[i+1].* 
					IF i = arr_count() THEN 
						INITIALIZE pa_person[i].* TO NULL 
						EXIT FOR 
					END IF 
					IF scrn < 8 THEN 
						DISPLAY pa_person[i].* TO sr_person[scrn].* 

						LET scrn = scrn + 1 
					END IF 
				END FOR 
			END IF 
			NEXT FIELD scroll_flag 
		ON KEY (F2) 
			IF infield(scroll_flag) THEN 
				IF pa_person[idx].person_code IS NOT NULL THEN 
					IF pr_scroll_flag IS NOT NULL THEN 
						LET pr_del_num = pr_del_num - 1 
						LET pa_person[idx].scroll_flag = NULL 
						LET pr_scroll_flag = NULL 
					ELSE 
						IF pa_person[idx].active_flag = "N" THEN 
							LET msgresp = kandoomsg("J",9613,"") 
							#9613 This person IS already inactive.
							NEXT FIELD scroll_flag 
						END IF 
						SELECT unique 1 FROM ts_head, ts_detail 
						WHERE ts_head.cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND ts_detail.cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND ts_head.person_code = pa_person[idx].person_code 
						AND ts_detail.ts_num = ts_head.ts_num 
						IF status = 0 THEN 
							LET msgresp = kandoomsg("J",7005,"") 
							#7005 "Cannot Delete; Timesheets Exists; Inactive Instead"
						END IF 
						LET pr_del_num = pr_del_num + 1 
						LET pa_person[idx].scroll_flag = "*" 
						LET pr_scroll_flag = "*" 
					END IF 
				END IF 
				NEXT FIELD scroll_flag 
			END IF 
		ON KEY (F6) 
			IF infield(scroll_flag) THEN 
				IF pa_person[idx].active_flag = "N" 
				AND pa_person[idx].person_code IS NOT NULL THEN 
					IF kandoomsg("J",8012,pa_person[idx].person_code) = "Y" THEN 
						#8012 Confirm TO re-activate
						GOTO bypass2 
						LABEL recovery2: 
						IF error_recover(pr_err_message,status) != "Y" THEN 
							RETURN true 
						END IF 
						LABEL bypass2: 
						WHENEVER ERROR GOTO recovery2 
						BEGIN WORK 
							DECLARE c3_person CURSOR FOR 
							SELECT * FROM person 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND person_code = pa_person[idx].person_code 
							FOR UPDATE 
							OPEN c3_person 
							FETCH c3_person INTO pr_person.* 
							LET pr_err_message = "Update Person Active Flag(Y) - J83" 
							UPDATE person 
							SET active_flag = "Y" 
							WHERE person.cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND person.person_code = pa_person[idx].person_code 
							CLOSE c3_person 
						COMMIT WORK 
						WHENEVER ERROR stop 
						LET pa_person[idx].active_flag = "Y" 
					END IF 
				ELSE 
					LET msgresp = kandoomsg("J",9614,"") 
					#9614 Person IS NOT inactive; Cannot Reactivate.
				END IF 
				NEXT FIELD scroll_flag 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	ELSE 
		IF pr_del_num > 0 THEN 
			LET msgresp = kandoomsg("J",8505,pr_del_num) 
			#8505 "Confirm TO Delete ??? Person Records?"
			IF msgresp = "Y" THEN 
				GOTO bypass 
				LABEL recovery: 
				IF error_recover(pr_err_message,status) != "Y" THEN 
					RETURN true 
				END IF 
				LABEL bypass: 
				WHENEVER ERROR GOTO recovery 
				BEGIN WORK 
					FOR idx = 1 TO arr_count() 
						IF pa_person[idx].scroll_flag IS NOT NULL THEN 
							DECLARE c2_person CURSOR FOR 
							SELECT * FROM person 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND person_code = pa_person[idx].person_code 
							FOR UPDATE 
							OPEN c2_person 
							FETCH c2_person INTO pr_person.* 
							SELECT unique 1 FROM ts_head, ts_detail 
							WHERE ts_head.cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND ts_detail.cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND ts_head.person_code = pa_person[idx].person_code 
							AND ts_detail.ts_num = ts_head.ts_num 
							IF status = 0 THEN 
								LET pr_err_message = "Update Person Active Flag(N) - J83" 
								UPDATE person 
								SET active_flag = "N" 
								WHERE person.cmpy_code = glob_rec_kandoouser.cmpy_code 
								AND person.person_code = pa_person[idx].person_code 
							ELSE 
								LET pr_err_message = "Delete Person - J83" 
								DELETE FROM person 
								WHERE person.cmpy_code = glob_rec_kandoouser.cmpy_code 
								AND person.person_code = pa_person[idx].person_code 
							END IF 
							CLOSE c2_person 
						END IF 
					END FOR 
				COMMIT WORK 
				WHENEVER ERROR stop 
			END IF 
		END IF 
	END IF 
	RETURN true 
END FUNCTION 


FUNCTION edit_person(pr_person_code) 
	DEFINE 
	pr_person_code LIKE person.person_code, 
	pr_person RECORD LIKE person.*, 
	pr_department RECORD LIKE department.*, 
	pr_jmresource RECORD LIKE jmresource.*, 
	pr_taskperiod RECORD LIKE taskperiod.*, 
	pr_winds_text CHAR(40) 
	OPEN WINDOW j144 with FORM "J144" -- alch kd-747 
	CALL winDecoration_j("J144") -- alch kd-747 
	INITIALIZE pr_person.* TO NULL 
	INITIALIZE pr_department.* TO NULL 
	INITIALIZE pr_taskperiod.* TO NULL 
	INITIALIZE pr_jmresource.* TO NULL 
	IF pr_person_code IS NOT NULL THEN 
		SELECT * INTO pr_person.* FROM person 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND person_code = pr_person_code 
		SELECT * INTO pr_department.* FROM department 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND dept_code = pr_person.dept_code 
		SELECT * INTO pr_taskperiod.* FROM taskperiod 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND task_period_ind = pr_person.task_period_ind 
		SELECT * INTO pr_jmresource.* FROM jmresource 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND res_code = pr_person.res_code 
		DISPLAY BY NAME pr_person.person_code, 
		pr_person.name_text, 
		pr_person.dept_code, 
		pr_department.dept_text, 
		pr_person.task_period_ind, 
		pr_taskperiod.task_period_text, 
		pr_person.target_hours, 
		pr_person.work_days_qty, 
		pr_person.start_date, 
		pr_person.per_end_date, 
		pr_person.res_code, 
		pr_jmresource.desc_text, 
		pr_person.maxdur_qty 

	END IF 
	LET msgresp = kandoomsg("U",1020,"Person") 
	#1020 Enter Person Details; OK TO Continue.
	INPUT BY NAME pr_person.person_code, 
	pr_person.name_text, 
	pr_person.dept_code, 
	pr_person.task_period_ind, 
	pr_person.target_hours, 
	pr_person.work_days_qty, 
	pr_person.start_date, 
	pr_person.per_end_date, 
	pr_person.res_code, 
	pr_person.maxdur_qty WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","J83","input-pr_person-1") -- alch kd-506 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (control-b) 
			CASE 
				WHEN infield(dept_code) 
					LET pr_winds_text = show_departments(glob_rec_kandoouser.cmpy_code) 
					IF pr_winds_text IS NOT NULL THEN 
						LET pr_person.dept_code = pr_winds_text 
					END IF 
					NEXT FIELD dept_code 
				WHEN infield(task_period_ind) 
					LET pr_winds_text = show_taskperiods(glob_rec_kandoouser.cmpy_code) 
					IF pr_winds_text IS NOT NULL THEN 
						LET pr_person.task_period_ind = pr_winds_text 
					END IF 
					NEXT FIELD task_period_ind 
				WHEN infield(res_code) 
					LET pr_winds_text = show_res(glob_rec_kandoouser.cmpy_code) 
					IF pr_winds_text IS NOT NULL THEN 
						LET pr_person.res_code = pr_winds_text 
					END IF 
					NEXT FIELD res_code 
			END CASE 
		BEFORE FIELD person_code 
			IF pr_person_code IS NOT NULL THEN 
				NEXT FIELD name_text 
			END IF 
		AFTER FIELD person_code 
			IF pr_person_code IS NULL THEN 
				IF pr_person.person_code IS NOT NULL THEN 
					SELECT unique 1 FROM person 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND person_code = pr_person.person_code 
					IF status = 0 THEN 
						LET msgresp = kandoomsg("U",9104,"") 
						#9104 "Record already exists"
						NEXT FIELD person_code 
					END IF 
				END IF 
			END IF 
		AFTER FIELD dept_code 
			IF pr_person.dept_code IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered.
				NEXT FIELD dept_code 
			END IF 
			SELECT * INTO pr_department.* FROM department 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND dept_code = pr_person.dept_code 
			IF status = notfound THEN 
				LET msgresp = kandoomsg("U",9105,"") 
				#9105 "Record NOT found; Try Window"
				NEXT FIELD dept_code 
			END IF 
			DISPLAY BY NAME pr_department.dept_text 

		AFTER FIELD task_period_ind 
			IF pr_person.task_period_ind IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered.
				NEXT FIELD task_period_ind 
			END IF 
			SELECT * INTO pr_taskperiod.* FROM taskperiod 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND task_period_ind = pr_person.task_period_ind 
			IF status = notfound THEN 
				LET msgresp = kandoomsg("U",9105,"") 
				#9105 "Record NOT found; Try Window"
				NEXT FIELD task_period_ind 
			END IF 
			LET pr_person.work_days_qty = pr_taskperiod.avg_days_qty 
			DISPLAY pr_taskperiod.task_period_text, 
			pr_person.work_days_qty 
			TO task_period_text, 
			work_days_qty 

		AFTER FIELD target_hours 
			IF pr_person.target_hours IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered.
				NEXT FIELD target_hours 
			END IF 
		AFTER FIELD work_days_qty 
			IF pr_person.work_days_qty IS NULL THEN 
				LET pr_person.work_days_qty = 0 
				DISPLAY BY NAME pr_person.work_days_qty 

			END IF 
		AFTER FIELD res_code 
			IF pr_person.res_code IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered.
				NEXT FIELD res_code 
			END IF 
			SELECT * INTO pr_jmresource.* FROM jmresource 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND res_code = pr_person.res_code 
			IF status = notfound THEN 
				LET msgresp = kandoomsg("U",9105,"") 
				#9105 "Record NOT found; Try Window"
				NEXT FIELD res_code 
			END IF 
			DISPLAY BY NAME pr_jmresource.desc_text 

		AFTER FIELD maxdur_qty 
			IF pr_person.maxdur_qty IS NULL THEN 
				LET pr_person.maxdur_qty = 0 
				DISPLAY BY NAME pr_person.maxdur_qty 

			END IF 
		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				IF pr_person.person_code IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 "Value must be entered"
					NEXT FIELD person_code 
				END IF 
				IF pr_person.dept_code IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 "Value must be entered"
					NEXT FIELD dept_code 
				END IF 
				IF pr_person.task_period_ind IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 "Value must be entered"
					NEXT FIELD task_period_ind 
				END IF 
				IF pr_person.target_hours IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered.
					NEXT FIELD tartet_hours 
				END IF 
				IF pr_person.work_days_qty IS NULL THEN 
					LET pr_person.work_days_qty = 0 
					DISPLAY BY NAME pr_person.work_days_qty 

				END IF 
				IF pr_person.res_code IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD res_code 
				END IF 
				IF pr_person.maxdur_qty IS NULL THEN 
					LET pr_person.maxdur_qty = 0 
					DISPLAY BY NAME pr_person.maxdur_qty 

				END IF 
				IF pr_jmparms.pa_post_flag = "Y" THEN 
					CALL get_paycodes(glob_rec_kandoouser.cmpy_code, "", 
					pr_person.env_code, 
					pr_person.pay_code, 
					pr_person.rate_code) 
					RETURNING pr_person.env_code, 
					pr_person.pay_code, 
					pr_person.rate_code 
					IF int_flag OR quit_flag THEN 
						LET int_flag = false 
						LET quit_flag = false 
						NEXT FIELD person_code 
					END IF 
				END IF 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		INITIALIZE pr_person.* TO NULL 
	ELSE 
		IF pr_person_code IS NOT NULL THEN 
			LET pr_person.cmpy_code = glob_rec_kandoouser.cmpy_code 
			UPDATE person 
			SET * = pr_person.* 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND person_code = pr_person.person_code 
		ELSE 
			LET pr_person.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET pr_person.active_flag = "Y" 
			INSERT INTO person VALUES (pr_person.*) 
		END IF 
	END IF 
	CLOSE WINDOW j144 
	RETURN pr_person.* 
END FUNCTION 
