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

	Source code beautified by beautify.pl on 2020-01-02 19:48:12	$Id: $
}

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "J_JM_GLOBALS.4gl" 
GLOBALS "J8_GLOBALS.4gl" 
GLOBALS "J81_GLOBALS.4gl" 



{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module - V81 (J81 !!)
#  Purpose - INPUT timesheet data



MAIN 
	#Initial UI Init
	CALL setModuleId("J81") -- albo 
	CALL ui_init(0) 
	DEFER quit 
	DEFER interrupt 
	CALL authenticate(getmoduleid()) 
	SELECT * INTO pr_jmparms.* FROM jmparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND key_code = "1" 
	IF status = notfound THEN 
		LET msgresp = kandoomsg("J",7002,"") 
		#7002 "Job Management Parameters NOT found - Refer Menu JZP"
		EXIT program 
	END IF 
	CREATE temp TABLE t_summary (task_date DATE, 
	job_code CHAR(8), 
	var_code SMALLINT, 
	activity_code CHAR(8), 
	res_code CHAR(8), 
	dur_qty float) 
	OPEN WINDOW j139 with FORM "J139" -- alch kd-747 
	CALL winDecoration_j("J139") -- alch kd-747 
	WHILE get_ts_head() 
		CALL get_ts_details() 
		CLEAR FORM 
	END WHILE 
	LET int_flag = false 
	LET quit_flag = false 
	CLOSE WINDOW j139 
END MAIN 


FUNCTION get_ts_head() 
	DEFINE 
	pr_end_date LIKE ts_head.per_end_date, 
	pr_tmp_end_date LIKE ts_head.per_end_date, 
	pr_person RECORD LIKE person.*, 
	pr_taskperiod RECORD LIKE taskperiod.*, 
	pr_period_length SMALLFLOAT, 
	pr_year_head_num LIKE ts_head.year_num, 
	pr_period_head_num LIKE ts_head.period_num, 
	pr_invalid, cnt SMALLINT, 
	pr_winds_text CHAR(40) 

	INITIALIZE pr_person.* TO NULL 
	INITIALIZE pr_ts_head.* TO NULL 
	LET pr_year_head_num = NULL 
	LET pr_period_head_num = NULL 
	LET msgresp = kandoomsg("U",1020,"Timesheet") 
	INPUT BY NAME pr_ts_head.person_code, 
	pr_ts_head.per_end_date, 
	pr_year_head_num, 
	pr_period_head_num WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","J81","input-pr_ts_head-1") -- alch kd-506 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (control-b) 
			IF infield (person_code) THEN 
				LET pr_winds_text = show_person(glob_rec_kandoouser.cmpy_code) 
				IF pr_winds_text IS NOT NULL THEN 
					LET pr_ts_head.person_code = pr_winds_text 
				END IF 
				NEXT FIELD person_code 
			END IF 
		AFTER FIELD person_code 
			SELECT person.* INTO pr_person.* FROM person 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND person_code = pr_ts_head.person_code 
			IF status = notfound THEN 
				LET msgresp = kandoomsg("J",9500,"") 
				#9500 "Person NOT found - Try Window"
				NEXT FIELD person_code 
			END IF 
			IF pr_person.active_flag = "N" THEN 
				LET msgresp = kandoomsg("J",7006,"") 
				#7006 Person IS inactive; Reactivate through J83 - Person Maintain"
				NEXT FIELD person_code 
			END IF 
			SELECT * INTO pr_taskperiod.* FROM taskperiod 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND task_period_ind = pr_person.task_period_ind 
			IF status = notfound THEN 
				LET msgresp = kandoomsg("J",9602,"") 
				#9602 "Task period indicator does NOT exist"
				NEXT FIELD person_code 
			END IF 
			LET pr_period_length = pr_taskperiod.days_qty 
			DISPLAY pr_person.name_text, 
			pr_taskperiod.task_period_text 
			TO name_text, 
			task_period_text 

			SELECT max(per_end_date) INTO pr_end_date FROM ts_head 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND person_code = pr_ts_head.person_code 
			IF pr_end_date IS NULL 
			OR pr_end_date = "31/12/1899" THEN 
				LET pr_end_date = pr_person.per_end_date 
			END IF 
			CALL calc_end_date(pr_person.task_period_ind, 
			pr_end_date, 
			pr_period_length) 
			RETURNING pr_end_date 
			CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, pr_end_date) 
			RETURNING pr_year_head_num, 
			pr_period_head_num 
			LET pr_ts_head.per_end_date = pr_end_date 
			DISPLAY BY NAME pr_year_head_num, 
			pr_period_head_num 

		BEFORE FIELD per_end_date 
			LET pr_tmp_end_date = pr_ts_head.per_end_date 
		AFTER FIELD per_end_date 
			IF pr_ts_head.per_end_date IS NULL OR 
			pr_ts_head.per_end_date = 0 THEN 
				LET msgresp = kandoomsg("J",9501,"") 
				#9501 "Period END Date Must be Entered"
				NEXT FIELD per_end_date 
			END IF 
			IF pr_person.task_period_ind = "M" THEN 
				CALL calc_end_date(pr_person.task_period_ind, 
				pr_end_date, 
				pr_period_length) 
				RETURNING pr_end_date 
				IF pr_end_date = pr_tmp_end_date 
				AND pr_ts_head.per_end_date <> pr_tmp_end_date THEN 
					LET msgresp = kandoomsg("J",9502,"") 
					#9502 "You have a Monthly Task Period, do NOT change the day"
					LET pr_ts_head.per_end_date = pr_end_date 
					NEXT FIELD per_end_date 
				ELSE 
					IF month(pr_end_date) <> month(pr_tmp_end_date) 
					AND day(pr_end_date) <> day(pr_ts_head.per_end_date) THEN 
						LET msgresp = kandoomsg("J",9503,"") 
						#9503 "You have a Monthly Task Period, press Enter...
						LET pr_ts_head.per_end_date = pr_end_date 
						NEXT FIELD per_end_date 
					END IF 
				END IF 
			END IF 
			IF pr_person.task_period_ind = "M" THEN 
				SELECT count(*) INTO cnt FROM ts_head 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND person_code = pr_ts_head.person_code 
				AND per_end_date = pr_ts_head.per_end_date 
			ELSE 
				SELECT count(*) INTO cnt FROM ts_head 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND person_code = pr_ts_head.person_code 
				AND per_end_date between pr_ts_head.per_end_date 
				AND (pr_ts_head.per_end_date 
				+ pr_period_length - 1) 
			END IF 
			IF cnt > 0 THEN 
				LET msgresp = kandoomsg("J",9504,"") 
				#9504 "This timesheet already exists"
				NEXT FIELD per_end_date 
			END IF 
			CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, pr_ts_head.per_end_date) 
			RETURNING pr_year_head_num, 
			pr_period_head_num 
			DISPLAY BY NAME pr_year_head_num, 
			pr_period_head_num 

		AFTER FIELD pr_period_head_num 
			CALL valid_period(glob_rec_kandoouser.cmpy_code,pr_year_head_num, 
			pr_period_head_num, "JM") 
			RETURNING pr_year_head_num, 
			pr_period_head_num, 
			pr_invalid 
			IF pr_invalid THEN 
				NEXT FIELD pr_year_head_num 
			END IF 
		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN 
				IF pr_ts_head.per_end_date IS NULL OR 
				pr_ts_head.per_end_date = 0 THEN 
					LET msgresp = kandoomsg("J",9501,"") 
					#9501 "Period END Date Must be Entered"
					NEXT FIELD per_end_date 
				END IF 
				IF pr_year_head_num IS NULL 
				OR pr_period_head_num IS NULL THEN 
					CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, pr_ts_head.per_end_date) 
					RETURNING pr_year_head_num, 
					pr_period_head_num 
					DISPLAY BY NAME pr_year_head_num, 
					pr_period_head_num 

				END IF 
				IF pr_person.task_period_ind = "M" THEN 
					SELECT count(*) INTO cnt FROM ts_head 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND person_code = pr_ts_head.person_code 
					AND per_end_date = pr_ts_head.per_end_date 
				ELSE 
					SELECT count(*) INTO cnt FROM ts_head 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND person_code = pr_ts_head.person_code 
					AND per_end_date between pr_ts_head.per_end_date 
					AND (pr_ts_head.per_end_date 
					+ pr_period_length - 1) 
				END IF 
				IF cnt > 0 THEN 
					LET msgresp = kandoomsg("J",9504,"") 
					#9504 "This timesheet already exists"
					NEXT FIELD per_end_date 
				END IF 
				CALL valid_period(glob_rec_kandoouser.cmpy_code,pr_year_head_num, 
				pr_period_head_num, "JM") 
				RETURNING pr_year_head_num, 
				pr_period_head_num, 
				pr_invalid 
				IF pr_invalid THEN 
					NEXT FIELD pr_year_head_num 
				END IF 
				LET pr_ts_head.year_num = pr_year_head_num 
				LET pr_ts_head.period_num = pr_period_head_num 

			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 


FUNCTION get_ts_details() 
	DEFINE 
	pr_ts_detail RECORD LIKE ts_detail.*, 
	pr_jmresource RECORD LIKE jmresource.*, 
	pr_person RECORD LIKE person.*, 
	pr_taskperiod RECORD LIKE taskperiod.*, 
	pr_locked_ind LIKE job.locked_ind, 
	pa_ts_detail array[300] OF RECORD 
		scroll_flag CHAR(1), 
		seq_num LIKE ts_detail.seq_num, 
		task_date LIKE ts_detail.task_date, 
		job_code LIKE ts_detail.job_code, 
		var_code LIKE ts_detail.var_code, 
		activity_code LIKE ts_detail.activity_code, 
		res_code LIKE ts_detail.res_code, 
		dur_qty LIKE ts_detail.dur_qty, 
		year_num LIKE ts_detail.year_num, 
		period_num LIKE ts_detail.period_num, 
		post_flag CHAR(1), 
		allocation_ind CHAR(1) 
	END RECORD, 
	pa_ts_detail2 array[300] OF RECORD 
		comment_text LIKE ts_detail.comment_text, 
		unit_cost_amt LIKE ts_detail.unit_cost_amt, 
		unit_bill_amt LIKE ts_detail.unit_bill_amt, 
		env_code LIKE ts_detail.env_code, 
		pay_code LIKE ts_detail.pay_code, 
		rate_code LIKE ts_detail.rate_code 
	END RECORD, 
	pa_ts_check array[31] OF RECORD 
		dur_qty LIKE ts_detail.dur_qty, 
		status SMALLINT 
	END RECORD, 
	pr_finish_flag LIKE activity.finish_flag, 
	pr_period_length SMALLFLOAT, 
	pr_winds_text CHAR(40), 
	err_message CHAR(60), 
	pr_scroll_flag CHAR(1), 
	pr_seq_num, pr_row_exists, i, pr_invalid, scrn, idx SMALLINT, 
	pr_day_num, pr_check_dur_qty, pr_check_no_days SMALLINT 

	LET idx = 1 
	CALL set_count(idx) 
	SELECT person.* INTO pr_person.* FROM person 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND person_code = pr_ts_head.person_code 
	IF status = notfound THEN 
		LET msgresp = kandoomsg("J",9500,"") 
		#9500 "Person NOT found - Try Window"
		RETURN 
	END IF 
	SELECT * INTO pr_taskperiod.* FROM taskperiod 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND task_period_ind = pr_person.task_period_ind 
	IF status = notfound THEN 
		LET msgresp = kandoomsg("J",9602,"") 
		#9602 "Task period indicator does NOT exist"
		RETURN 
	END IF 
	LET pr_period_length = pr_taskperiod.days_qty 
	INITIALIZE pa_ts_detail[idx].* TO NULL 
	LET msgresp = kandoomsg("J",1504,"") 
	#1504 "F8 TO alter Allocation Mode, F9 daily totals, F10 activity totals"
	OPTIONS INSERT KEY f1, 
	DELETE KEY f36 
	LET pr_seq_num = 0 
	INPUT ARRAY pa_ts_detail WITHOUT DEFAULTS FROM sr_ts_detail.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","J81","input_arr-pa_ts_details-1") -- alch kd-506 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (control-b) 
			CASE 
				WHEN infield (res_code) 
					LET pr_winds_text = show_res(glob_rec_kandoouser.cmpy_code) 
					IF pr_winds_text IS NOT NULL THEN 
						LET pa_ts_detail[idx].res_code = pr_winds_text 
					END IF 
					LET msgresp = kandoomsg("J",1504,"") 
					#1504 "F8 TO alter Allocation Mode, F10 activity totals"
					OPTIONS INSERT KEY f1, 
					DELETE KEY f36 
					NEXT FIELD res_code 
				WHEN infield (job_code) 
					LET pr_winds_text = show_job(glob_rec_kandoouser.cmpy_code) 
					IF pr_winds_text IS NOT NULL THEN 
						LET pa_ts_detail[idx].job_code = pr_winds_text 
					END IF 
					LET msgresp = kandoomsg("J",1504,"") 
					#1504 "F8 TO alter Allocation Mode, F10 activity totals"
					OPTIONS INSERT KEY f1, 
					DELETE KEY f36 
					NEXT FIELD job_code 
				WHEN infield (var_code) 
					LET pr_winds_text = show_jobvars(glob_rec_kandoouser.cmpy_code,pa_ts_detail[idx].job_code) 
					IF pr_winds_text IS NOT NULL THEN 
						LET pa_ts_detail[idx].var_code = pr_winds_text 
					END IF 
					LET msgresp = kandoomsg("J",1504,"") 
					#1504 "F8 TO alter Allocation Mode, F10 activity totals"
					OPTIONS INSERT KEY f1, 
					DELETE KEY f36 
					NEXT FIELD var_code 
				WHEN infield (activity_code) 
					LET pr_winds_text = show_activity(glob_rec_kandoouser.cmpy_code, 
					pa_ts_detail[idx].job_code, 
					pa_ts_detail[idx].var_code) 
					IF pr_winds_text IS NOT NULL THEN 
						LET pa_ts_detail[idx].activity_code = pr_winds_text 
					END IF 
					LET msgresp = kandoomsg("J",1504,"") 
					#1504 "F8 TO alter Allocation Mode, F10 activity totals"
					OPTIONS INSERT KEY f1, 
					DELETE KEY f36 
					NEXT FIELD activity_code 
			END CASE 
			--- modif ericv init # ON KEY (F1)
		BEFORE ROW 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
		BEFORE FIELD scroll_flag 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			LET pr_scroll_flag = pa_ts_detail[idx].scroll_flag 
			LET pr_ts_detail.comment_text = pa_ts_detail2[idx].comment_text 
			LET pr_ts_detail.unit_cost_amt = pa_ts_detail2[idx].unit_cost_amt 
			LET pr_ts_detail.unit_bill_amt = pa_ts_detail2[idx].unit_bill_amt 
			LET pr_ts_detail.env_code = pa_ts_detail2[idx].env_code 
			LET pr_ts_detail.pay_code = pa_ts_detail2[idx].pay_code 
			LET pr_ts_detail.rate_code = pa_ts_detail2[idx].rate_code 
			LET pr_ts_detail.task_date = pa_ts_detail[idx].task_date 
			LET pr_ts_detail.job_code = pa_ts_detail[idx].job_code 
			LET pr_ts_detail.var_code = pa_ts_detail[idx].var_code 
			LET pr_ts_detail.activity_code = pa_ts_detail[idx].activity_code 
			LET pr_ts_detail.res_code = pa_ts_detail[idx].res_code 
			LET pr_ts_detail.dur_qty = pa_ts_detail[idx].dur_qty 
			LET pr_ts_detail.seq_num = pa_ts_detail[idx].seq_num 
			LET pr_ts_detail.year_num = pa_ts_detail[idx].year_num 
			LET pr_ts_detail.period_num = pa_ts_detail[idx].period_num 
			LET pr_ts_detail.post_flag = pa_ts_detail[idx].post_flag 
			LET pr_ts_detail.allocation_ind = pa_ts_detail[idx].allocation_ind 
			DISPLAY pa_ts_detail[idx].* TO sr_ts_detail[scrn].* 

		AFTER FIELD scroll_flag 
			LET pa_ts_detail[idx].scroll_flag = pr_scroll_flag 
			DISPLAY pa_ts_detail[idx].* TO sr_ts_detail[scrn].* 

			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF pa_ts_detail[idx].job_code IS NULL THEN 
					INITIALIZE pr_ts_detail.* TO NULL 
					NEXT FIELD seq_num 
				END IF 
			END IF 
		BEFORE FIELD seq_num 
			IF pa_ts_detail[idx].seq_num = 0 
			OR pa_ts_detail[idx].seq_num IS NULL THEN 
				LET pr_seq_num = pr_seq_num + 1 
				LET pa_ts_detail[idx].seq_num = pr_seq_num 
				DISPLAY pa_ts_detail[idx].seq_num TO sr_ts_detail[scrn].seq_num 

			END IF 
			NEXT FIELD task_date 
		BEFORE FIELD task_date 
			IF pa_ts_detail[idx].scroll_flag IS NOT NULL THEN 
				LET msgresp = kandoomsg("J",9601,"") 
				#9601 This line cannot be editted as it has been deleted
				NEXT FIELD scroll_flag 
			END IF 
			IF pa_ts_detail[idx].task_date IS NULL 
			OR pa_ts_detail[idx].task_date = "31/12/1899" THEN 
				IF idx = 1 THEN 
					LET pa_ts_detail[idx].task_date = pr_ts_head.per_end_date 
					LET pa_ts_detail[idx].res_code = pr_person.res_code 
					LET pa_ts_detail[idx].year_num = pr_ts_head.year_num 
					LET pa_ts_detail[idx].period_num = pr_ts_head.period_num 
				ELSE 
					IF idx > 1 THEN 
						LET pa_ts_detail[idx].task_date = 
						pa_ts_detail[idx-1].task_date 
						LET pa_ts_detail[idx].job_code = 
						pa_ts_detail[idx-1].job_code 
						LET pa_ts_detail[idx].var_code = 
						pa_ts_detail[idx-1].var_code 
						LET pa_ts_detail[idx].res_code = 
						pa_ts_detail[idx-1].res_code 
						LET pa_ts_detail[idx].year_num = 
						pa_ts_detail[idx-1].year_num 
						LET pa_ts_detail[idx].period_num = 
						pa_ts_detail[idx-1].period_num 
						LET pa_ts_detail[idx].allocation_ind = 
						pa_ts_detail[idx-1].allocation_ind 
					END IF 
				END IF 
			END IF 
			DISPLAY pa_ts_detail[idx].* TO sr_ts_detail[scrn].* 

		AFTER FIELD task_date 
			IF pa_ts_detail[idx].task_date = "31/12/1899" 
			OR pa_ts_detail[idx].task_date IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 "Value must be entered"
				NEXT FIELD task_date 
			END IF 
			CASE 
				WHEN fgl_lastkey() = fgl_keyval("accept") 
					OR fgl_lastkey() = fgl_keyval("RETURN") 
					OR fgl_lastkey() = fgl_keyval("tab") 
					OR fgl_lastkey() = fgl_keyval("right") 
					OR fgl_lastkey() = fgl_keyval("down") 
					IF pr_person.task_period_ind = "M" THEN 
						IF month(pr_ts_head.per_end_date) <> 
						month(pa_ts_detail[idx].task_date) 
						OR year(pr_ts_head.per_end_date) <> 
						year(pa_ts_detail[idx].task_date) THEN 
							LET msgresp = kandoomsg("J", 9506, "") 
							#9506 "Date NOT in current timesheet period,",
							#     " must be same month/year"
							NEXT FIELD task_date 
						END IF 
					ELSE 
						IF pa_ts_detail[idx].task_date > pr_ts_head.per_end_date 
						OR pa_ts_detail[idx].task_date <= 
						(pr_ts_head.per_end_date - pr_period_length) THEN 
							LET msgresp = kandoomsg("J",9507,"") 
							#9507 "Date NOT in current timesheet period"
							NEXT FIELD task_date 
						END IF 
					END IF 
					IF fgl_lastkey() = fgl_keyval("accept") THEN 
						IF pa_ts_detail[idx].job_code IS NULL THEN 
							LET msgresp = kandoomsg("U",9102,"") 
							#9102 Value must be entered
							NEXT FIELD job_code 
						END IF 
						IF pa_ts_detail[idx].var_code IS NULL THEN 
							LET pa_ts_detail[idx].var_code = 0 
							DISPLAY pa_ts_detail[idx].var_code 
							TO sr_ts_detail[scrn].var_code 

						END IF 
						IF pa_ts_detail[idx].activity_code IS NULL THEN 
							LET msgresp = kandoomsg("U",9102,"") 
							#9102 Value must be entered
							NEXT FIELD activity_code 
						END IF 
						IF pa_ts_detail[idx].res_code IS NULL THEN 
							LET msgresp = kandoomsg("U",9102,"") 
							#9102 Value must be entered
							NEXT FIELD res_code 
						END IF 
						IF pa_ts_detail[idx].dur_qty IS NULL THEN 
							LET pa_ts_detail[idx].dur_qty = 0 
							DISPLAY pa_ts_detail[idx].dur_qty 
							TO sr_ts_detail[scrn].dur_qty 

						END IF 
						IF pa_ts_detail[idx].year_num IS NULL THEN 
							IF idx = 1 THEN 
								LET pa_ts_detail[idx].year_num = pr_ts_head.year_num 
							ELSE 
								LET pa_ts_detail[idx].year_num = 
								pa_ts_detail[idx-1].year_num 
							END IF 
						END IF 
						IF pa_ts_detail[idx].period_num IS NULL THEN 
							IF idx = 1 THEN 
								LET pa_ts_detail[idx].period_num = pr_ts_head.period_num 
							ELSE 
								LET pa_ts_detail[idx].period_num = 
								pa_ts_detail[idx-1].period_num 
							END IF 
						END IF 
						NEXT FIELD post_flag 
					END IF 
					NEXT FIELD NEXT 
				OTHERWISE 
					NEXT FIELD task_date 
			END CASE 
		AFTER FIELD job_code 
			IF pa_ts_detail[idx].job_code IS NOT NULL THEN 
				SELECT locked_ind INTO pr_locked_ind FROM job 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND job_code = pa_ts_detail[idx].job_code 
				IF status = notfound THEN 
					LET msgresp = kandoomsg("U",9105,"") 
					#9105 "Record Not Found - Try Window"
					NEXT FIELD job_code 
				END IF 
				IF pr_locked_ind = 0 THEN 
					LET msgresp = kandoomsg("J",9556,"") 
					#9556 "Cannot enter time against a master job"
					NEXT FIELD job_code 
				END IF 
				SELECT unique 1 FROM activity 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND job_code = pa_ts_detail[idx].job_code 
				IF status = notfound THEN 
					LET msgresp = kandoomsg("J",9599,"") 
					#9599 No activities exist FOR this job
					NEXT FIELD job_code 
				END IF 
			END IF 
			CASE 
				WHEN fgl_lastkey() = fgl_keyval("accept") 
					OR fgl_lastkey() = fgl_keyval("RETURN") 
					OR fgl_lastkey() = fgl_keyval("tab") 
					OR fgl_lastkey() = fgl_keyval("right") 
					OR fgl_lastkey() = fgl_keyval("down") 
					IF pa_ts_detail[idx].job_code IS NULL THEN 
						LET msgresp = kandoomsg("U",9102,"") 
						#9102 "Value must be entered"
						NEXT FIELD job_code 
					END IF 
					IF fgl_lastkey() = fgl_keyval("accept") THEN 
						IF pa_ts_detail[idx].var_code IS NULL THEN 
							LET pa_ts_detail[idx].var_code = 0 
							DISPLAY pa_ts_detail[idx].var_code 
							TO sr_ts_detail[scrn].var_code 

						END IF 
						IF pa_ts_detail[idx].activity_code IS NULL THEN 
							LET msgresp = kandoomsg("U",9102,"") 
							#9102 Value must be entered
							NEXT FIELD activity_code 
						END IF 
						IF pa_ts_detail[idx].res_code IS NULL THEN 
							LET msgresp = kandoomsg("U",9102,"") 
							#9102 Value must be entered
							NEXT FIELD res_code 
						END IF 
						IF pa_ts_detail[idx].dur_qty IS NULL THEN 
							LET pa_ts_detail[idx].dur_qty = 0 
							DISPLAY pa_ts_detail[idx].dur_qty 
							TO sr_ts_detail[scrn].dur_qty 

						END IF 
						IF pa_ts_detail[idx].year_num IS NULL THEN 
							IF idx = 1 THEN 
								LET pa_ts_detail[idx].year_num = pr_ts_head.year_num 
							ELSE 
								LET pa_ts_detail[idx].year_num = 
								pa_ts_detail[idx-1].year_num 
							END IF 
						END IF 
						IF pa_ts_detail[idx].period_num IS NULL THEN 
							IF idx = 1 THEN 
								LET pa_ts_detail[idx].period_num = pr_ts_head.period_num 
							ELSE 
								LET pa_ts_detail[idx].period_num = 
								pa_ts_detail[idx-1].period_num 
							END IF 
						END IF 
						NEXT FIELD post_flag 
					END IF 
					NEXT FIELD NEXT 
				WHEN fgl_lastkey() = fgl_keyval("left") 
					OR fgl_lastkey() = fgl_keyval("up") 
					NEXT FIELD previous 
				OTHERWISE 
					NEXT FIELD job_code 
			END CASE 
		AFTER FIELD var_code 
			IF pa_ts_detail[idx].var_code IS NULL THEN 
				LET pa_ts_detail[idx].var_code = 0 
				DISPLAY pa_ts_detail[idx].var_code 
				TO sr_ts_detail[scrn].var_code 

			END IF 
			IF pa_ts_detail[idx].var_code != 0 THEN 
				SELECT * FROM jobvars 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND job_code = pa_ts_detail[idx].job_code 
				AND var_code = pa_ts_detail[idx].var_code 
				IF status = notfound THEN 
					LET msgresp = kandoomsg("U",9105,"") 
					#9105 "Record Not Found; Try Window"
					LET pa_ts_detail[idx].var_code = NULL 
					NEXT FIELD var_code 
				END IF 
			END IF 
			CASE 
				WHEN fgl_lastkey() = fgl_keyval("accept") 
					OR fgl_lastkey() = fgl_keyval("RETURN") 
					OR fgl_lastkey() = fgl_keyval("tab") 
					OR fgl_lastkey() = fgl_keyval("right") 
					OR fgl_lastkey() = fgl_keyval("down") 
					SELECT unique 1 FROM activity 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND job_code = pa_ts_detail[idx].job_code 
					AND var_code = pa_ts_detail[idx].var_code 
					IF status = notfound THEN 
						LET msgresp = kandoomsg("J",9599,"") 
						#9599 No activities exist FOR this job/variation.
						LET pa_ts_detail[idx].var_code = NULL 
						NEXT FIELD var_code 
					END IF 
					IF fgl_lastkey() = fgl_keyval("accept") THEN 
						IF pa_ts_detail[idx].activity_code IS NULL THEN 
							LET msgresp = kandoomsg("U",9102,"") 
							#9102 Value must be entered
							NEXT FIELD activity_code 
						END IF 
						IF pa_ts_detail[idx].res_code IS NULL THEN 
							LET msgresp = kandoomsg("U",9102,"") 
							#9102 Value must be entered
							NEXT FIELD res_code 
						END IF 
						IF pa_ts_detail[idx].dur_qty IS NULL THEN 
							LET pa_ts_detail[idx].dur_qty = 0 
							DISPLAY pa_ts_detail[idx].dur_qty 
							TO sr_ts_detail[scrn].dur_qty 

						END IF 
						IF pa_ts_detail[idx].year_num IS NULL THEN 
							IF idx = 1 THEN 
								LET pa_ts_detail[idx].year_num = pr_ts_head.year_num 
							ELSE 
								LET pa_ts_detail[idx].year_num = 
								pa_ts_detail[idx-1].year_num 
							END IF 
						END IF 
						IF pa_ts_detail[idx].period_num IS NULL THEN 
							IF idx = 1 THEN 
								LET pa_ts_detail[idx].period_num = pr_ts_head.period_num 
							ELSE 
								LET pa_ts_detail[idx].period_num = 
								pa_ts_detail[idx-1].period_num 
							END IF 
						END IF 
						NEXT FIELD post_flag 
					END IF 
					NEXT FIELD NEXT 
				WHEN fgl_lastkey() = fgl_keyval("left") 
					OR fgl_lastkey() = fgl_keyval("up") 
					NEXT FIELD previous 
				OTHERWISE 
					NEXT FIELD var_code 
			END CASE 
		AFTER FIELD activity_code 
			IF pa_ts_detail[idx].activity_code IS NOT NULL THEN 
				SELECT finish_flag INTO pr_finish_flag FROM activity 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND job_code = pa_ts_detail[idx].job_code 
				AND var_code = pa_ts_detail[idx].var_code 
				AND activity_code = pa_ts_detail[idx].activity_code 
				IF status = notfound THEN 
					LET msgresp = kandoomsg("J",9512,"") 
					#9512 "This Activity NOT found FOR Job/Variation",
					LET pa_ts_detail[idx].activity_code = NULL 
					NEXT FIELD activity_code 
				END IF 
				IF pr_finish_flag = "Y" THEN 
					LET msgresp = kandoomsg("J",9513,"") 
					#9513 "Activity IS Finished No more costs may be allocated"
					LET pa_ts_detail[idx].activity_code = NULL 
					NEXT FIELD activity_code 
				END IF 
			END IF 
			CASE 
				WHEN fgl_lastkey() = fgl_keyval("accept") 
					OR fgl_lastkey() = fgl_keyval("RETURN") 
					OR fgl_lastkey() = fgl_keyval("tab") 
					OR fgl_lastkey() = fgl_keyval("right") 
					OR fgl_lastkey() = fgl_keyval("down") 
					IF pa_ts_detail[idx].activity_code IS NULL THEN 
						LET msgresp = kandoomsg("U",9102,"") 
						#9102 "Value must be entered"
						NEXT FIELD activity_code 
					END IF 
					IF fgl_lastkey() = fgl_keyval("accept") THEN 
						IF pa_ts_detail[idx].res_code IS NULL THEN 
							LET msgresp = kandoomsg("U",9102,"") 
							#9102 Value must be entered
							NEXT FIELD res_code 
						END IF 
						IF pa_ts_detail[idx].dur_qty IS NULL THEN 
							LET pa_ts_detail[idx].dur_qty = 0 
							DISPLAY pa_ts_detail[idx].dur_qty 
							TO sr_ts_detail[scrn].dur_qty 

						END IF 
						IF pa_ts_detail[idx].year_num IS NULL THEN 
							IF idx = 1 THEN 
								LET pa_ts_detail[idx].year_num = pr_ts_head.year_num 
							ELSE 
								LET pa_ts_detail[idx].year_num = 
								pa_ts_detail[idx-1].year_num 
							END IF 
						END IF 
						IF pa_ts_detail[idx].period_num IS NULL THEN 
							IF idx = 1 THEN 
								LET pa_ts_detail[idx].period_num = pr_ts_head.period_num 
							ELSE 
								LET pa_ts_detail[idx].period_num = 
								pa_ts_detail[idx-1].period_num 
							END IF 
						END IF 
						NEXT FIELD post_flag 
					END IF 
					NEXT FIELD NEXT 
				WHEN fgl_lastkey() = fgl_keyval("left") 
					OR fgl_lastkey() = fgl_keyval("up") 
					NEXT FIELD previous 
				OTHERWISE 
					NEXT FIELD activity_code 
			END CASE 
		AFTER FIELD res_code 
			IF pa_ts_detail[idx].res_code IS NOT NULL THEN 
				SELECT * INTO pr_jmresource.* FROM jmresource 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND res_code = pa_ts_detail[idx].res_code 
				IF status = notfound THEN 
					LET msgresp = kandoomsg("U",9105,"") 
					#9105 "Record NOT found - Try window "
					NEXT FIELD res_code 
				END IF 
				IF pr_jmresource.allocation_ind IS NULL THEN 
					LET pa_ts_detail[idx].allocation_ind = "A" 
				ELSE 
					LET pa_ts_detail[idx].allocation_ind = 
					pr_jmresource.allocation_ind 
				END IF 
			END IF 
			CASE 
				WHEN fgl_lastkey() = fgl_keyval("accept") 
					OR fgl_lastkey() = fgl_keyval("RETURN") 
					OR fgl_lastkey() = fgl_keyval("tab") 
					OR fgl_lastkey() = fgl_keyval("right") 
					OR fgl_lastkey() = fgl_keyval("down") 
					IF pa_ts_detail[idx].res_code IS NULL THEN 
						LET msgresp = kandoomsg("U",9102,"") 
						#9102 "Value must be entered"
						NEXT FIELD res_code 
					END IF 
					IF fgl_lastkey() = fgl_keyval("accept") THEN 
						IF pa_ts_detail[idx].dur_qty IS NULL THEN 
							LET pa_ts_detail[idx].dur_qty = 0 
							DISPLAY pa_ts_detail[idx].dur_qty 
							TO sr_ts_detail[scrn].dur_qty 

						END IF 
						IF pa_ts_detail[idx].year_num IS NULL THEN 
							IF idx = 1 THEN 
								LET pa_ts_detail[idx].year_num = pr_ts_head.year_num 
							ELSE 
								LET pa_ts_detail[idx].year_num = 
								pa_ts_detail[idx-1].year_num 
							END IF 
						END IF 
						IF pa_ts_detail[idx].period_num IS NULL THEN 
							IF idx = 1 THEN 
								LET pa_ts_detail[idx].period_num = pr_ts_head.period_num 
							ELSE 
								LET pa_ts_detail[idx].period_num = 
								pa_ts_detail[idx-1].period_num 
							END IF 
						END IF 
						NEXT FIELD post_flag 
					END IF 
					NEXT FIELD NEXT 
				WHEN fgl_lastkey() = fgl_keyval("left") 
					OR fgl_lastkey() = fgl_keyval("up") 
					NEXT FIELD previous 
				OTHERWISE 
					NEXT FIELD res_code 
			END CASE 
		AFTER FIELD dur_qty 
			IF pa_ts_detail[idx].dur_qty IS NULL THEN 
				LET pa_ts_detail[idx].dur_qty = 0 
				DISPLAY pa_ts_detail[idx].dur_qty 
				TO sr_ts_detail[scrn].dur_qty 

			END IF 
			IF fgl_lastkey() = fgl_keyval("accept") THEN 
				IF pa_ts_detail[idx].year_num IS NULL THEN 
					IF idx = 1 THEN 
						LET pa_ts_detail[idx].year_num = pr_ts_head.year_num 
					ELSE 
						LET pa_ts_detail[idx].year_num = pa_ts_detail[idx-1].year_num 
					END IF 
				END IF 
				IF pa_ts_detail[idx].period_num IS NULL THEN 
					IF idx = 1 THEN 
						LET pa_ts_detail[idx].period_num = pr_ts_head.period_num 
					ELSE 
						LET pa_ts_detail[idx].period_num = 
						pa_ts_detail[idx-1].period_num 
					END IF 
				END IF 
				NEXT FIELD post_flag 
			END IF 
		AFTER FIELD year_num 
			IF pa_ts_detail[idx].year_num IS NULL THEN 
				IF idx = 1 THEN 
					LET pa_ts_detail[idx].year_num = pr_ts_head.year_num 
				ELSE 
					LET pa_ts_detail[idx].year_num = pa_ts_detail[idx-1].year_num 
				END IF 
			END IF 
			IF fgl_lastkey() = fgl_keyval("accept") THEN 
				IF pa_ts_detail[idx].period_num IS NULL THEN 
					IF idx = 1 THEN 
						LET pa_ts_detail[idx].period_num = pr_ts_head.period_num 
					ELSE 
						LET pa_ts_detail[idx].period_num = 
						pa_ts_detail[idx-1].period_num 
					END IF 
				END IF 
				CALL valid_period(glob_rec_kandoouser.cmpy_code, pa_ts_detail[idx].year_num, 
				pa_ts_detail[idx].period_num, "JM") 
				RETURNING pa_ts_detail[idx].year_num, 
				pa_ts_detail[idx].period_num, 
				pr_invalid 
				IF pr_invalid THEN 
					NEXT FIELD year_num 
				END IF 
				NEXT FIELD post_flag 
			END IF 
		AFTER FIELD period_num 
			IF pa_ts_detail[idx].period_num IS NULL THEN 
				IF idx = 1 THEN 
					LET pa_ts_detail[idx].period_num = pr_ts_head.period_num 
				ELSE 
					LET pa_ts_detail[idx].period_num = pa_ts_detail[idx-1].period_num 
				END IF 
			END IF 
			CALL valid_period(glob_rec_kandoouser.cmpy_code, pa_ts_detail[idx].year_num, 
			pa_ts_detail[idx].period_num, "JM") 
			RETURNING pa_ts_detail[idx].year_num, 
			pa_ts_detail[idx].period_num, 
			pr_invalid 
			IF pr_invalid THEN 
				NEXT FIELD year_num 
			END IF 
			NEXT FIELD post_flag 
		BEFORE FIELD post_flag 
			LET pa_ts_detail[idx].post_flag = "N" 
			LET pr_ts_detail.comment_text = pa_ts_detail2[idx].comment_text 
			LET pr_ts_detail.unit_cost_amt = pa_ts_detail2[idx].unit_cost_amt 
			LET pr_ts_detail.unit_bill_amt = pa_ts_detail2[idx].unit_bill_amt 
			LET pr_ts_detail.env_code = pa_ts_detail2[idx].env_code 
			LET pr_ts_detail.pay_code = pa_ts_detail2[idx].pay_code 
			LET pr_ts_detail.rate_code = pa_ts_detail2[idx].rate_code 
			LET pr_ts_detail.task_date = pa_ts_detail[idx].task_date 
			LET pr_ts_detail.job_code = pa_ts_detail[idx].job_code 
			LET pr_ts_detail.var_code = pa_ts_detail[idx].var_code 
			LET pr_ts_detail.activity_code = pa_ts_detail[idx].activity_code 
			LET pr_ts_detail.res_code = pa_ts_detail[idx].res_code 
			LET pr_ts_detail.dur_qty = pa_ts_detail[idx].dur_qty 
			LET pr_ts_detail.seq_num = pa_ts_detail[idx].seq_num 
			LET pr_ts_detail.year_num = pa_ts_detail[idx].year_num 
			LET pr_ts_detail.period_num = pa_ts_detail[idx].period_num 
			LET pr_ts_detail.post_flag = pa_ts_detail[idx].post_flag 
			LET pr_ts_detail.allocation_ind = pa_ts_detail[idx].allocation_ind 
			IF pr_jmresource.cost_ind = "1" 
			OR pr_jmresource.bill_ind = "1" THEN 
				CALL adjust_cost(pr_ts_detail.*) 
				RETURNING pr_ts_detail.* 
				LET pa_ts_detail2[idx].unit_cost_amt = pr_ts_detail.unit_cost_amt 
				LET pa_ts_detail2[idx].unit_bill_amt = pr_ts_detail.unit_bill_amt 
			END IF 
			IF pr_jmparms.pa_post_flag = "Y" THEN 
				CALL get_paycodes(glob_rec_kandoouser.cmpy_code, 
				pr_person.person_code, 
				pa_ts_detail2[idx].env_code, 
				pa_ts_detail2[idx].pay_code, 
				pa_ts_detail2[idx].rate_code) 
				RETURNING pa_ts_detail2[idx].env_code, 
				pa_ts_detail2[idx].pay_code, 
				pa_ts_detail2[idx].rate_code 
			ELSE 
				LET pa_ts_detail2[idx].env_code = NULL 
				LET pa_ts_detail2[idx].pay_code = NULL 
				LET pa_ts_detail2[idx].rate_code = NULL 
			END IF 
			LET pa_ts_detail2[idx].comment_text = 
			get_comment(pa_ts_detail2[idx].comment_text) 
			NEXT FIELD scroll_flag 
		BEFORE INSERT 
			IF fgl_lastkey() = fgl_keyval("delete") 
			OR fgl_lastkey() = fgl_keyval("interrupt") THEN 
				INITIALIZE pa_ts_detail[idx].* TO NULL 
				NEXT FIELD scroll_flag 
			END IF 
			INITIALIZE pr_ts_detail.* TO NULL 
			FOR i = arr_count() TO arr_curr() step -1 
				IF i != 0 THEN 
					LET pa_ts_detail2[i+1].* = pa_ts_detail2[i].* 
					IF i = arr_curr() THEN 
						INITIALIZE pa_ts_detail2[i].* TO NULL 
					END IF 
				END IF 
			END FOR 
			NEXT FIELD seq_num 
		ON KEY (F2) 
			IF infield(scroll_flag) THEN 
				LET pa_ts_detail[idx].scroll_flag = pr_scroll_flag 
				IF pa_ts_detail[idx].job_code IS NOT NULL THEN 
					IF pa_ts_detail[idx].scroll_flag = "*" THEN 
						LET pa_ts_detail[idx].scroll_flag = "" 
						LET pr_scroll_flag = "" 
					ELSE 
						LET pa_ts_detail[idx].scroll_flag = "*" 
						LET pr_scroll_flag = "*" 
					END IF 
				END IF 
				NEXT FIELD scroll_flag 
			END IF 
		ON KEY (F8) 
			IF infield(scroll_flag) THEN 
				LET pa_ts_detail[idx].scroll_flag = pr_scroll_flag 
				IF pa_ts_detail[idx].scroll_flag IS NOT NULL THEN 
					LET msgresp = kandoomsg("J",9601,"") 
					#9601 This line cannot be editted as it has been deleted
					NEXT FIELD scroll_flag 
				END IF 
				IF pa_ts_detail[idx].res_code IS NOT NULL THEN 
					SELECT * INTO pr_jmresource.* FROM jmresource 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND res_code = pa_ts_detail[idx].res_code 
					IF pr_jmresource.allocation_flag <> "1" 
					OR pr_jmresource.allocation_flag IS NULL THEN 
						LET msgresp = kandoomsg("J",9555,"") 
						#9555 Resource does NOT permit override of allocation ind
					ELSE 
						CALL adjust_allocflag(glob_rec_kandoouser.cmpy_code, pr_jmresource.res_code, 
						pa_ts_detail[idx].allocation_ind) 
						RETURNING pa_ts_detail[idx].allocation_ind 
					END IF 
				END IF 
				NEXT FIELD scroll_flag 
			END IF 
		ON KEY (F9) 
			IF infield(scroll_flag) THEN 
				LET pa_ts_detail[idx].scroll_flag = pr_scroll_flag 
				FOR i = 1 TO arr_count() 
					IF pa_ts_detail[i].job_code IS NOT NULL 
					AND pa_ts_detail[i].scroll_flag IS NULL THEN 
						INSERT INTO t_summary VALUES (pa_ts_detail[i].task_date, 
						pa_ts_detail[i].job_code, 
						pa_ts_detail[i].var_code, 
						pa_ts_detail[i].activity_code, 
						pa_ts_detail[i].res_code, 
						pa_ts_detail[i].dur_qty) 
					END IF 
				END FOR 
				CALL daily_totals() 
				DELETE FROM t_summary 
				WHERE 1=1 
				LET msgresp = kandoomsg("J",1504,"") 
				#1504 "F8 TO alter Allocation Mode, F10 activity totals"
				OPTIONS INSERT KEY f1, 
				DELETE KEY f36 
			END IF 
		ON KEY (F10) 
			IF infield(scroll_flag) THEN 
				LET pa_ts_detail[idx].scroll_flag = pr_scroll_flag 
				FOR i = 1 TO arr_count() 
					IF pa_ts_detail[i].job_code IS NOT NULL 
					AND pa_ts_detail[i].scroll_flag IS NULL THEN 
						INSERT INTO t_summary VALUES (pa_ts_detail[i].task_date, 
						pa_ts_detail[i].job_code, 
						pa_ts_detail[i].var_code, 
						pa_ts_detail[i].activity_code, 
						pa_ts_detail[i].res_code, 
						pa_ts_detail[i].dur_qty) 
					END IF 
				END FOR 
				CALL activity_totals() 
				DELETE FROM t_summary 
				WHERE 1=1 
				LET msgresp = kandoomsg("J",1504,"") 
				#1504 "F8 TO alter Allocation Mode, F10 activity totals"
				OPTIONS INSERT KEY f1, 
				DELETE KEY f36 
			END IF 
		AFTER ROW 
			DISPLAY pa_ts_detail[idx].* TO sr_ts_detail[scrn].* 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				IF NOT infield(scroll_flag) THEN 
					IF pr_ts_detail.job_code IS NOT NULL THEN 
						LET pa_ts_detail2[idx].comment_text = 
						pr_ts_detail.comment_text 
						LET pa_ts_detail2[idx].unit_cost_amt = 
						pr_ts_detail.unit_cost_amt 
						LET pa_ts_detail2[idx].unit_bill_amt = 
						pr_ts_detail.unit_bill_amt 
						LET pa_ts_detail2[idx].env_code = pr_ts_detail.env_code 
						LET pa_ts_detail2[idx].pay_code = pr_ts_detail.pay_code 
						LET pa_ts_detail2[idx].rate_code = pr_ts_detail.rate_code 
						LET pa_ts_detail[idx].task_date = pr_ts_detail.task_date 
						LET pa_ts_detail[idx].job_code = pr_ts_detail.job_code 
						LET pa_ts_detail[idx].var_code = pr_ts_detail.var_code 
						LET pa_ts_detail[idx].activity_code = 
						pr_ts_detail.activity_code 
						LET pa_ts_detail[idx].res_code = pr_ts_detail.res_code 
						LET pa_ts_detail[idx].dur_qty = pr_ts_detail.dur_qty 
						LET pa_ts_detail[idx].seq_num = pr_ts_detail.seq_num 
						LET pa_ts_detail[idx].year_num = pr_ts_detail.year_num 
						LET pa_ts_detail[idx].period_num = pr_ts_detail.period_num 
						LET pa_ts_detail[idx].post_flag = pr_ts_detail.post_flag 
						LET pa_ts_detail[idx].allocation_ind = 
						pr_ts_detail.allocation_ind 
						LET int_flag = false 
						LET quit_flag = false 
						NEXT FIELD scroll_flag 
					ELSE 
						FOR i = arr_curr() TO arr_count() 
							LET pa_ts_detail[i].* = pa_ts_detail[i+1].* 
							LET pa_ts_detail2[i].* = pa_ts_detail2[i+1].* 
							IF i = arr_count() THEN 
								INITIALIZE pa_ts_detail[i].* TO NULL 
								INITIALIZE pa_ts_detail2[i].* TO NULL 
							END IF 
							IF scrn <= 8 THEN 
								DISPLAY pa_ts_detail[i].* TO sr_ts_detail[scrn].* 

								LET scrn = scrn + 1 
							END IF 
						END FOR 
						LET pr_seq_num = pr_seq_num - 1 
						LET scrn = scr_line() 
						LET int_flag = false 
						LET quit_flag = false 
						NEXT FIELD scroll_flag 
					END IF 
				ELSE 
					FOR i = 1 TO arr_count() 
						IF pa_ts_detail[i].scroll_flag IS NULL 
						AND pa_ts_detail[i].job_code IS NOT NULL THEN 
							LET pr_row_exists = true 
							EXIT FOR 
						END IF 
					END FOR 
					IF pr_row_exists THEN 
						LET msgresp = kandoomsg("J",8001,"") 
						#8001 Confirm TO discard all changes TO this timesheet?
						IF msgresp = "N" THEN 
							NEXT FIELD scroll_flag 
						ELSE 
							LET int_flag = true 
						END IF 
					END IF 
				END IF 
			ELSE 
				LET pr_row_exists = false 
				FOR i = 1 TO arr_count() 
					IF pa_ts_detail[i].scroll_flag IS NULL 
					AND pa_ts_detail[i].job_code IS NOT NULL THEN 
						LET pr_row_exists = true 
					END IF 
				END FOR 
				IF NOT pr_row_exists THEN 
					LET msgresp = kandoomsg("J",9519,"") 
					#9519 There are no entries FOR this timesheet
					LET int_flag = true 
					EXIT INPUT 
				END IF 
				# Check WHEN go back TO the detail line AND modified the job_code
				FOR idx = 1 TO arr_count() 
					IF pa_ts_detail[idx].job_code IS NOT NULL 
					AND pa_ts_detail[idx].activity_code IS NOT NULL THEN 
						SELECT unique 1 FROM activity 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND job_code = pa_ts_detail[idx].job_code 
						AND activity_code = pa_ts_detail[idx].activity_code 
						IF status = notfound THEN 
							LET msgresp = kandoomsg("J",9599,"") 
							#9599 No activities exist FOR this job
							NEXT FIELD job_code 
						END IF 
					END IF 
				END FOR 

				LET pr_check_dur_qty = 0 
				LET pr_check_no_days = 0 
				FOR i = 1 TO 31 
					LET pa_ts_check[i].dur_qty = 0 
					LET pa_ts_check[i].status = 0 
				END FOR 
				FOR idx = 1 TO arr_count() 
					IF pa_ts_detail[idx].job_code IS NOT NULL 
					AND pa_ts_detail[idx].scroll_flag IS NULL THEN 
						LET pr_day_num = day(pa_ts_detail[idx].task_date) 
						LET pa_ts_check[pr_day_num].dur_qty = 
						pa_ts_check[pr_day_num].dur_qty 
						+ pa_ts_detail[idx].dur_qty 
						LET pa_ts_check[pr_day_num].status = 1 
					END IF 
				END FOR 
				FOR pr_day_num = 1 TO 31 
					IF pa_ts_check[pr_day_num].dur_qty > pr_person.maxdur_qty AND 
					pr_person.maxdur_qty <> 0 THEN 
						LET pr_check_dur_qty = pr_check_dur_qty + 1 
					END IF 
					IF pa_ts_check[pr_day_num].status = 1 THEN 
						LET pr_check_no_days = pr_check_no_days + 1 
					END IF 
				END FOR 
				IF (pr_person.task_period_ind = "M" 
				AND pr_check_no_days > day(pr_ts_head.per_end_date) ) 
				OR (pr_person.task_period_ind <> "M" 
				AND pr_check_no_days > pr_taskperiod.days_qty ) THEN 
					LET msgresp = kandoomsg("J",9516,"") 
					#9516 "There are too much days in this worksheet"
					NEXT FIELD scroll_flag 
				ELSE 
					IF (pr_person.task_period_ind = "M" 
					AND pr_check_no_days <> 0 
					AND pr_check_no_days < day(pr_ts_head.per_end_date) ) 
					OR (pr_person.task_period_ind <> "M" 
					AND pr_check_no_days <> 0 
					AND pr_person.work_days_qty <> 0 
					AND pr_person.work_days_qty IS NOT NULL 
					AND pr_check_no_days < pr_person.work_days_qty ) THEN 
						LET msgresp = kandoomsg("J", 8500, "") 
						#There are less days entered than possible; Edit timesheet?
						IF msgresp = "N" THEN 
							NEXT FIELD scroll_flag 
						END IF 
					ELSE 
						IF pr_check_no_days = 0 THEN 
							LET msgresp = kandoomsg("J",7502,"") 
							#7502 "You have NOT entered a good Detail Line so far"
							NEXT FIELD scroll_flag 
						END IF 
					END IF 
				END IF 
				IF pr_check_dur_qty > 0 THEN 
					LET msgresp = kandoomsg("J",8501,pr_check_dur_qty) 
					#8501 There are <VALUE> day(s) with more units per day...
					IF msgresp = "N" THEN 
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
		RETURN 
	END IF 
	GOTO bypass 
	LABEL recovery: 
	IF error_recover(err_message,status) != "Y" THEN 
		EXIT program 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	BEGIN WORK 
		LET pr_ts_head.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET pr_ts_head.posted_flag = "N" 
		LET pr_ts_head.entry_code = glob_rec_kandoouser.sign_on_code 
		LET pr_ts_head.entry_date = today 
		LET pr_ts_head.ts_num = 0 
		LET err_message = "V81 - Inserting ts_head" 
		INSERT INTO ts_head VALUES (pr_ts_head.*) 
		LET pr_ts_head.ts_num = sqlca.sqlerrd[2] 
		LET pr_seq_num = 0 
		FOR idx = 1 TO arr_count() 
			IF pa_ts_detail[idx].job_code IS NOT NULL 
			AND pa_ts_detail[idx].scroll_flag IS NULL THEN 
				LET pr_seq_num = pr_seq_num + 1 
				LET pr_ts_detail.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET pr_ts_detail.ts_num = pr_ts_head.ts_num 
				LET pr_ts_detail.seq_num = pr_seq_num 
				LET pr_ts_detail.post_flag = "N" 
				LET pr_ts_detail.comment_text = pa_ts_detail2[idx].comment_text 
				LET pr_ts_detail.unit_cost_amt = pa_ts_detail2[idx].unit_cost_amt 
				LET pr_ts_detail.unit_bill_amt = pa_ts_detail2[idx].unit_bill_amt 
				LET pr_ts_detail.env_code = pa_ts_detail2[idx].env_code 
				LET pr_ts_detail.pay_code = pa_ts_detail2[idx].pay_code 
				LET pr_ts_detail.rate_code = pa_ts_detail2[idx].rate_code 
				LET pr_ts_detail.task_date = pa_ts_detail[idx].task_date 
				LET pr_ts_detail.job_code = pa_ts_detail[idx].job_code 
				LET pr_ts_detail.var_code = pa_ts_detail[idx].var_code 
				LET pr_ts_detail.activity_code = pa_ts_detail[idx].activity_code 
				LET pr_ts_detail.res_code = pa_ts_detail[idx].res_code 
				LET pr_ts_detail.dur_qty = pa_ts_detail[idx].dur_qty 
				LET pr_ts_detail.year_num = pa_ts_detail[idx].year_num 
				LET pr_ts_detail.period_num = pa_ts_detail[idx].period_num 
				LET pr_ts_detail.allocation_ind = pa_ts_detail[idx].allocation_ind 
				LET err_message = "V81 - Inserting ts_detail row" 
				INSERT INTO ts_detail VALUES (pr_ts_detail.*) 
			END IF 
		END FOR 
	COMMIT WORK 
	LET msgresp = kandoomsg("J",7000,pr_ts_head.ts_num) 
	#7000 Timesheet No: ??? has been successfully added
	WHENEVER ERROR stop 
END FUNCTION 


FUNCTION adjust_cost(pr_ts_detail) 
	DEFINE 
	pr_ts_detail RECORD LIKE ts_detail.*, 
	pr_jmresource RECORD LIKE jmresource.*, 
	pr_cost_total, 
	pr_bill_total DECIMAL(16,2), 
	pv_hourly_rate LIKE rate.hourly_rate 
	OPEN WINDOW j135 with FORM "J135" -- alch kd-747 
	CALL winDecoration_j("J135") -- alch kd-747 
	LET msgresp = kandoomsg("U",1020,"Cost/Rate") 
	#1020 Enter Cost/Rate Details; OK TO Continue.
	INITIALIZE pr_jmresource.* TO NULL 
	SELECT * INTO pr_jmresource.* FROM jmresource 
	WHERE res_code = pr_ts_detail.res_code 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 

	IF pr_ts_detail.unit_cost_amt IS NULL THEN 
		LET pr_ts_detail.unit_cost_amt = pr_jmresource.unit_cost_amt 
	END IF 
	IF pr_ts_detail.unit_bill_amt IS NULL THEN 
		CALL get_hourly_rate(pr_ts_detail.*) RETURNING pv_hourly_rate 

		#IF the rate FOR rate types has already been SET
		IF pv_hourly_rate < 0 THEN 
			LET pr_ts_detail.unit_bill_amt = pr_jmresource.unit_bill_amt 
		ELSE 
			LET pr_ts_detail.unit_bill_amt = pv_hourly_rate 
		END IF 
	END IF 
	LET pr_cost_total = pr_ts_detail.dur_qty 
	* pr_ts_detail.unit_cost_amt 
	LET pr_bill_total = pr_ts_detail.dur_qty 
	* pr_ts_detail.unit_bill_amt 
	IF pr_cost_total IS NULL THEN 
		LET pr_cost_total = 0 
	END IF 
	IF pr_bill_total IS NULL THEN 
		LET pr_bill_total = 0 
	END IF 
	IF pr_ts_detail.dur_qty IS NULL THEN 
		LET pr_ts_detail.dur_qty = 0 
	END IF 
	IF pr_ts_detail.unit_bill_amt IS NULL THEN 
		LET pr_ts_detail.unit_bill_amt = 0 
	END IF 
	IF pr_ts_detail.unit_cost_amt IS NULL THEN 
		LET pr_ts_detail.unit_cost_amt = 0 
	END IF 
	IF pr_cost_total IS NULL THEN 
		LET pr_cost_total = 0 
	END IF 
	DISPLAY pr_ts_detail.res_code, 
	pr_jmresource.desc_text, 
	pr_ts_detail.dur_qty, 
	pr_jmresource.unit_code, 
	pr_cost_total, 
	pr_bill_total 
	TO res_code, 
	desc_text, 
	dur_qty, 
	unit_code, 
	trans_amt, 
	charge_amt 
	attribute(yellow) 
	INPUT BY NAME pr_ts_detail.unit_cost_amt, 
	pr_ts_detail.unit_bill_amt WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","J81","input-pr_ts_details-1") -- alch kd-506 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE FIELD unit_cost_amt 
			IF pr_jmresource.cost_ind != "1" THEN 
				NEXT FIELD unit_bill_amt 
			END IF 
		AFTER FIELD unit_cost_amt 
			IF pr_ts_detail.unit_cost_amt IS NULL THEN 
				LET pr_ts_detail.unit_cost_amt = pr_jmresource.unit_cost_amt 
			END IF 
			LET pr_cost_total = pr_ts_detail.dur_qty 
			* pr_ts_detail.unit_cost_amt 
			DISPLAY pr_ts_detail.unit_cost_amt 
			TO unit_cost_amt 

			DISPLAY pr_cost_total 
			TO trans_amt 
			attribute(yellow) 
		BEFORE FIELD unit_bill_amt 
			IF pr_jmresource.bill_ind != "1" THEN 
				NEXT FIELD unit_cost_amt 
			END IF 
		AFTER FIELD unit_bill_amt 
			IF pr_ts_detail.unit_bill_amt IS NULL THEN 
				LET pr_ts_detail.unit_bill_amt = pr_jmresource.unit_bill_amt 
			END IF 
			LET pr_bill_total = pr_ts_detail.dur_qty 
			* pr_ts_detail.unit_bill_amt 
			DISPLAY pr_ts_detail.unit_bill_amt 
			TO unit_bill_amt 

			DISPLAY pr_bill_total 
			TO charge_amt 
			attribute(yellow) 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	CLOSE WINDOW j135 
	RETURN pr_ts_detail.* 
END FUNCTION 

FUNCTION get_comment(pr_comment_text) 
	DEFINE 
	pr_comment_text LIKE ts_detail.comment_text, 
	pr_ts_detail RECORD LIKE ts_detail.* 
	OPEN WINDOW j311 with FORM "J311" -- alch kd-747 
	CALL winDecoration_j("J311") -- alch kd-747 
	LET msgresp = kandoomsg("U",1020,"Comment") 
	#1020 Enter Comment Details
	LET pr_ts_detail.comment_text = pr_comment_text 
	INPUT BY NAME pr_ts_detail.comment_text WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","J81","input-pr_ts_detail-2") -- alch kd-506 
	
		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 
	END INPUT 
	CLOSE WINDOW j311 
	RETURN pr_ts_detail.comment_text 
END FUNCTION 

## Look up unit_bill_amt on rate table based on rate type selection criterias
FUNCTION get_hourly_rate(pr_ts_detail) 

	DEFINE 
	pr_ts_detail RECORD LIKE ts_detail.*, 
	pv_hourly_rate LIKE rate.hourly_rate 

	## Look up the rate FOR the type "N" AND specific TO a person code
	SELECT hourly_rate 
	INTO pv_hourly_rate 
	FROM rate 
	WHERE rate.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND rate.person_code = pr_ts_head.person_code 
	AND rate.rate_type = "N" 
	AND (rate.expiry_date >=pr_ts_detail.task_date OR rate.expiry_date IS null) 
	AND (rate.cust_code = (SELECT cust_code FROM job WHERE (job_code = pr_ts_detail.job_code AND cmpy_code = glob_rec_kandoouser.cmpy_code)) OR rate.cust_code IS null) 
	AND rate.job_code = pr_ts_detail.job_code 
	AND rate.var_code = pr_ts_detail.var_code 
	AND rate.activity_code = pr_ts_detail.activity_code 
	IF status = 0 THEN 
		RETURN pv_hourly_rate 
	END IF 

	SELECT hourly_rate 
	INTO pv_hourly_rate 
	FROM rate 
	WHERE rate.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND rate.person_code = pr_ts_head.person_code 
	AND rate.rate_type = "N" 
	AND (rate.expiry_date >=pr_ts_detail.task_date OR rate.expiry_date IS null) 
	AND (rate.cust_code = (SELECT cust_code FROM job WHERE (job_code = pr_ts_detail.job_code AND cmpy_code = glob_rec_kandoouser.cmpy_code)) OR rate.cust_code IS null) 
	AND rate.job_code = pr_ts_detail.job_code 
	AND rate.var_code = pr_ts_detail.var_code 
	AND rate.activity_code IS NULL 

	IF status = 0 THEN 
		RETURN pv_hourly_rate 
	END IF 

	SELECT hourly_rate 
	INTO pv_hourly_rate 
	FROM rate 
	WHERE rate.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND rate.person_code = pr_ts_head.person_code 
	AND rate.rate_type = "N" 
	AND (rate.expiry_date >=pr_ts_detail.task_date OR rate.expiry_date IS null) 
	AND (rate.cust_code = (SELECT cust_code FROM job WHERE (job_code = pr_ts_detail.job_code AND cmpy_code = glob_rec_kandoouser.cmpy_code)) OR rate.cust_code IS null) 
	AND rate.job_code = pr_ts_detail.job_code 
	AND rate.var_code IS NULL 
	AND rate.activity_code IS NULL 

	IF status = 0 THEN 
		RETURN pv_hourly_rate 
	END IF 

	SELECT hourly_rate 
	INTO pv_hourly_rate 
	FROM rate 
	WHERE rate.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND rate.person_code = pr_ts_head.person_code 
	AND rate.rate_type = "N" 
	AND (rate.expiry_date >=pr_ts_detail.task_date OR rate.expiry_date IS null) 
	AND (rate.cust_code = (SELECT cust_code FROM job WHERE (job_code = pr_ts_detail.job_code AND cmpy_code = glob_rec_kandoouser.cmpy_code)) OR rate.cust_code IS null) 
	AND rate.job_code IS NULL 
	AND rate.var_code IS NULL 
	AND rate.activity_code IS NULL 

	IF status = 0 THEN 
		RETURN pv_hourly_rate 
	END IF 

	## Look up the rate FOR type "N" without specific TO person code
	SELECT hourly_rate 
	INTO pv_hourly_rate 
	FROM rate 
	WHERE rate.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND rate.person_code IS NULL 
	AND rate.rate_type = "N" 
	AND (rate.expiry_date >=pr_ts_detail.task_date OR rate.expiry_date IS null) 
	AND (rate.cust_code = (SELECT cust_code FROM job WHERE (job_code = pr_ts_detail.job_code AND cmpy_code =glob_rec_kandoouser.cmpy_code)) OR rate.cust_code IS null) 
	AND rate.job_code = pr_ts_detail.job_code 
	AND rate.var_code = pr_ts_detail.var_code 
	AND rate.activity_code = pr_ts_detail.activity_code 
	IF status = 0 THEN 
		RETURN pv_hourly_rate 
	END IF 

	SELECT hourly_rate 
	INTO pv_hourly_rate 
	FROM rate 
	WHERE rate.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND rate.person_code IS NULL 
	AND rate.rate_type = "N" 
	AND (rate.expiry_date >=pr_ts_detail.task_date OR rate.expiry_date IS null) 
	AND (rate.cust_code = (SELECT cust_code FROM job WHERE (job_code = pr_ts_detail.job_code AND cmpy_code = glob_rec_kandoouser.cmpy_code)) OR rate.cust_code IS null) 
	AND rate.job_code = pr_ts_detail.job_code 
	AND rate.var_code = pr_ts_detail.var_code 
	AND rate.activity_code IS NULL 

	IF status = 0 THEN 
		RETURN pv_hourly_rate 
	END IF 

	SELECT hourly_rate 
	INTO pv_hourly_rate 
	FROM rate 
	WHERE rate.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND rate.person_code IS NULL 
	AND rate.rate_type = "N" 
	AND (rate.expiry_date >=pr_ts_detail.task_date OR rate.expiry_date IS null) 
	AND (rate.cust_code = (SELECT cust_code FROM job WHERE (job_code = pr_ts_detail.job_code AND cmpy_code = glob_rec_kandoouser.cmpy_code)) OR rate.cust_code IS null) 
	AND rate.job_code = pr_ts_detail.job_code 
	AND rate.job_code IS NULL 
	AND rate.var_code IS NULL 

	IF status = 0 THEN 
		RETURN pv_hourly_rate 
	END IF 

	SELECT hourly_rate 
	INTO pv_hourly_rate 
	FROM rate 
	WHERE rate.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND rate.person_code IS NULL 
	AND rate.rate_type = "N" 
	AND (rate.expiry_date >=pr_ts_detail.task_date OR rate.expiry_date IS null) 
	AND (rate.cust_code = (SELECT cust_code FROM job WHERE (job_code = pr_ts_detail.job_code AND cmpy_code = glob_rec_kandoouser.cmpy_code)) OR rate.cust_code IS null) 
	AND rate.job_code IS NULL 
	AND rate.var_code IS NULL 
	AND rate.activity_code IS NULL 

	IF status = 0 THEN 
		RETURN pv_hourly_rate 
	END IF 

	SELECT hourly_rate 
	INTO pv_hourly_rate 
	FROM rate 
	WHERE rate.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND pr_ts_detail.activity_code = rate.activity_code 
	AND pr_ts_detail.var_code = rate.var_code 
	AND pr_ts_detail.job_code = rate.job_code 
	AND rate_type = "A" 
	AND (rate.expiry_date >=pr_ts_detail.task_date OR rate.expiry_date IS null) 
	IF status = 0 THEN 
		RETURN pv_hourly_rate 
	END IF 

	SELECT hourly_rate 
	INTO pv_hourly_rate 
	FROM rate 
	WHERE rate.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND pr_ts_detail.var_code = rate.var_code 
	AND pr_ts_detail.job_code = rate.job_code 
	AND rate.rate_type = "V" 
	AND (rate.expiry_date >=pr_ts_detail.task_date OR rate.expiry_date IS null) 
	IF status = 0 THEN 
		RETURN pv_hourly_rate 
	END IF 

	SELECT hourly_rate 
	INTO pv_hourly_rate 
	FROM rate 
	WHERE rate.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND pr_ts_detail.job_code = rate.job_code 
	AND rate.rate_type = "J" 
	AND (rate.expiry_date >=pr_ts_detail.task_date OR rate.expiry_date IS null) 
	IF status = 0 THEN 
		RETURN pv_hourly_rate 
	END IF 

	SELECT hourly_rate 
	INTO pv_hourly_rate 
	FROM rate 
	WHERE rate.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND rate.cust_code = (SELECT cust_code FROM job WHERE (job_code = pr_ts_detail.job_code AND cmpy_code = glob_rec_kandoouser.cmpy_code)) 
	AND rate.rate_type = "C" 
	AND (rate.expiry_date >= pr_ts_detail.task_date OR rate.expiry_date IS null) 
	IF status = 0 THEN 
		RETURN pv_hourly_rate 
	ELSE 
		RETURN -1 
	END IF 

END FUNCTION 

