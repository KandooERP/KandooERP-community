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


# Purpose - Post Timesheet



MAIN 
	#Initial UI Init
	CALL setModuleId("J87") -- albo 
	CALL ui_init(0) 
	DEFER quit 
	DEFER interrupt 
	CALL authenticate(getmoduleid()) 
	OPEN WINDOW j315 with FORM "J315" -- alch kd-747 
	CALL winDecoration_j("J315") -- alch kd-747 
	SELECT * INTO pr_jmparms.* FROM jmparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND key_code = "1" 
	IF status = notfound THEN 
		LET msgresp = kandoomsg("J",7002,"") 
		#7002 "JM Parameters NOT found; Refer TO JZP"
		EXIT program 
	END IF 
	WHILE select_timesht() 
	END WHILE 
	CLOSE WINDOW j315 
END MAIN 


FUNCTION select_timesht() 
	DEFINE 
	pr_person RECORD LIKE person.*, 
	query_text CHAR(800), 
	where_text CHAR(200), 
	pa_ts_head array[200] OF RECORD 
		scroll_flag CHAR(1), 
		person_code LIKE ts_head.person_code, 
		per_end_date LIKE ts_head.per_end_date, 
		ts_num LIKE ts_head.ts_num, 
		dept_code LIKE person.dept_code, 
		year_num LIKE ts_head.year_num, 
		period_num LIKE ts_head.period_num, 
		posted_flag LIKE ts_head.posted_flag 
	END RECORD, 
	pa_ts_head2 array[200] OF RECORD 
		name_text LIKE person.name_text 
	END RECORD, 
	pr_scroll_flag CHAR(1), 
	pr_post_timesheet, i, idx, scrn SMALLINT 

	CLEAR FORM 
	LET msgresp = kandoomsg("U",1001,"") 
	#1001 Enter Selection Criteria; OK TO Continue.
	CONSTRUCT BY NAME where_text ON 
	ts_head.person_code, 
	ts_head.per_end_date, 
	ts_head.ts_num, 
	person.dept_code, 
	ts_head.year_num, 
	ts_head.period_num, 
	person.name_text 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","J87","const-person_code-4") -- alch kd-506 
		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 
	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 
	LET query_text = "SELECT ts_head.*, person.* ", 
	" FROM ts_head, person ", 
	" WHERE ts_head.cmpy_code = '",glob_rec_kandoouser.cmpy_code ,"' ", 
	" AND person.cmpy_code = ts_head.cmpy_code ", 
	" AND person.person_code = ts_head.person_code ", 
	" AND ts_head.posted_flag != 'Y' ", 
	" AND ",where_text clipped," ", 
	" ORDER BY ts_head.person_code, ts_head.per_end_date " 
	PREPARE s_ts_head FROM query_text 
	DECLARE c_ts_head CURSOR FOR s_ts_head 
	LET idx = 0 
	FOREACH c_ts_head INTO pr_ts_head.*, pr_person.* 
		SELECT unique 1 FROM ts_detail 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND ts_num = pr_ts_head.ts_num 
		IF status = notfound THEN 
			CONTINUE FOREACH 
		END IF 
		LET idx = idx + 1 
		LET pa_ts_head[idx].person_code = pr_ts_head.person_code 
		LET pa_ts_head[idx].per_end_date = pr_ts_head.per_end_date 
		LET pa_ts_head[idx].ts_num = pr_ts_head.ts_num 
		LET pa_ts_head[idx].year_num = pr_ts_head.year_num 
		LET pa_ts_head[idx].period_num = pr_ts_head.period_num 
		LET pa_ts_head[idx].posted_flag = pr_ts_head.posted_flag 
		LET pa_ts_head[idx].dept_code = pr_person.dept_code 
		LET pa_ts_head2[idx].name_text = pr_person.name_text 
		IF idx = 200 THEN 
			LET msgresp = kandoomsg("U",6100,idx) 
			#6100 First idx records selected only
			EXIT FOREACH 
		END IF 
	END FOREACH 
	LET msgresp = kandoomsg("U",9113,idx) 
	#9113 idx records selected
	IF idx = 0 THEN 
		LET idx = 1 
		INITIALIZE pa_ts_head[idx].* TO NULL 
		INITIALIZE pa_ts_head2[idx].* TO NULL 
	END IF 
	CALL set_count(idx) 
	LET msgresp = kandoomsg("J",1400,"") 
	#1400 ENTER TO View; F9 TO Toggle Post; OK TO Commence Posting.
	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 
	LET pr_post_timesheet = 0 
	INPUT ARRAY pa_ts_head WITHOUT DEFAULTS FROM sr_ts_head.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","J87","input_arr-pa_ts_head-1") -- alch kd-506 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE ROW 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
		BEFORE FIELD scroll_flag 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			LET pr_scroll_flag = pa_ts_head[idx].scroll_flag 
			DISPLAY BY NAME pa_ts_head2[idx].name_text 

			DISPLAY pa_ts_head[idx].* TO sr_ts_head[scrn].* 

		AFTER FIELD scroll_flag 
			LET pa_ts_head[idx].scroll_flag = pr_scroll_flag 
			IF fgl_lastkey() = fgl_keyval("down") 
			AND arr_curr() >= arr_count() THEN 
				LET msgresp = kandoomsg("U",9001,"") 
				#9001 There no more rows...
				NEXT FIELD scroll_flag 
			END IF 
			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF pa_ts_head[idx+1].person_code IS NULL THEN 
					LET msgresp = kandoomsg("U",9001,"") 
					#9001 There no more rows...
					NEXT FIELD scroll_flag 
				END IF 
			END IF 
			IF fgl_lastkey() = fgl_keyval("nextpage") 
			AND pa_ts_head[idx+12].person_code IS NULL THEN 
				LET msgresp = kandoomsg("U",9001,"") 
				#9001 No more rows in this direction
				NEXT FIELD scroll_flag 
			END IF 
		ON KEY (F7) 
			LET pa_ts_head[idx].scroll_flag = pr_scroll_flag 
			IF infield(scroll_flag) THEN 
				LET scrn = 1 
				FOR i = 1 TO arr_count() 
					IF pa_ts_head[i].person_code IS NULL THEN 
						LET scrn = scrn + 1 
						CONTINUE FOR 
					END IF 
					IF pa_ts_head[i].posted_flag = "Y" THEN 
						LET scrn = scrn + 1 
						CONTINUE FOR 
					END IF 
					IF pa_ts_head[i].scroll_flag IS NULL THEN 
						LET pa_ts_head[i].scroll_flag = "*" 
						LET pr_post_timesheet = pr_post_timesheet + 1 
					ELSE 
						LET pa_ts_head[i].scroll_flag = NULL 
						LET pr_post_timesheet = pr_post_timesheet - 1 
					END IF 
					IF scrn <= 12 THEN 
						DISPLAY pa_ts_head[i].* TO sr_ts_head[scrn].* 

						LET scrn = scrn + 1 
					END IF 
				END FOR 
				LET pr_scroll_flag = pa_ts_head[idx].scroll_flag 
				NEXT FIELD scroll_flag 
			END IF 

		ON KEY (F9) 
			IF infield(scroll_flag) THEN 
				IF pa_ts_head[idx].person_code IS NULL THEN 
					NEXT FIELD scroll_flag 
				END IF 
				IF pa_ts_head[idx].posted_flag = "Y" THEN 
					LET msgresp = kandoomsg("J",9544,"") 
					#9544 This timesheet has already been posted
					NEXT FIELD scroll_flag 
				END IF 
				SELECT unique 1 FROM ts_detail 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND ts_num = pa_ts_head[idx].ts_num 
				IF status = notfound THEN 
					LET msgresp = kandoomsg("J",9606,"") 
					#9606 This timesheet has no detail lines TO post
					NEXT FIELD scroll_flag 
				END IF 
				IF pr_scroll_flag IS NULL THEN 
					LET pa_ts_head[idx].scroll_flag = "*" 
					LET pr_scroll_flag = "*" 
					LET pr_post_timesheet = pr_post_timesheet + 1 
				ELSE 
					LET pa_ts_head[idx].scroll_flag = NULL 
					LET pr_scroll_flag = NULL 
					LET pr_post_timesheet = pr_post_timesheet - 1 
				END IF 
				NEXT FIELD scroll_flag 
			END IF 
		BEFORE FIELD person_code 
			IF pa_ts_head[idx].person_code IS NULL THEN 
				NEXT FIELD scroll_flag 
			END IF 
			OPEN WINDOW j190 with FORM "J190" -- alch kd-747 
			CALL winDecoration_j("J190") -- alch kd-747 
			CALL display_timesheet(pa_ts_head[idx].ts_num) 
			LET int_flag = false 
			LET quit_flag = false 
			CLOSE WINDOW j190 
			SELECT posted_flag INTO pa_ts_head[idx].posted_flag 
			FROM ts_head 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND ts_num = pa_ts_head[idx].ts_num 
			IF pr_scroll_flag IS NOT NULL THEN 
				LET pr_scroll_flag = NULL 
				LET pa_ts_head[idx].scroll_flag = NULL 
				LET pr_post_timesheet = pr_post_timesheet - 1 
			END IF 
			NEXT FIELD scroll_flag 
		AFTER ROW 
			DISPLAY pa_ts_head[idx].* TO sr_ts_head[scrn].* 

		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN 
				IF pr_post_timesheet THEN 
					LET msgresp = kandoomsg("J",8003,pr_post_timesheet) 
					#8003 Confirm TO post ??? timesheet entries (Y/N)?
					IF msgresp = "Y" THEN 
						#                  OPEN WINDOW w1 AT 10,10 with 3 rows, 60 columns
						#                     ATTRIBUTE(border)      -- alch KD-747
						DISPLAY "Posting Timesheet: " at 1,1 
						FOR i = 1 TO arr_count() 
							IF pa_ts_head[i].scroll_flag IS NOT NULL THEN 
								DISPLAY " ", pa_ts_head[i].ts_num at 2,1 

								DISPLAY " ", pa_ts_head2[i].name_text at 3,1 

								CALL post_timesheet(pa_ts_head[i].ts_num) 
							END IF 
						END FOR 
						#                  CLOSE WINDOW w1      -- alch KD-747
					ELSE 
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
	END IF 
	RETURN true 
END FUNCTION 


FUNCTION display_timesheet(pr_ts_num) 
	DEFINE 
	pr_ts_num LIKE ts_head.ts_num, 
	pr_person RECORD LIKE person.*, 
	pr_taskperiod RECORD LIKE taskperiod.*, 
	pr_year_head_num LIKE ts_head.year_num, 
	pr_period_head_num LIKE ts_head.period_num, 
	pr_tp_ects_int RECORD LIKE tp_ects_int.*, 
	pr_activity RECORD LIKE activity.*, 
	pr_ts_detail RECORD LIKE ts_detail.*, 
	pr_jmresource RECORD LIKE jmresource.*, 
	pr_jobledger RECORD LIKE jobledger.*, 
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
	err_message CHAR(60), 
	pr_posted_flag, pr_scroll_flag CHAR(1), 
	pr_return_status, pr_posted_count, pr_detail_count SMALLINT, 
	pr_post_timesheet, i, scrn, idx SMALLINT 

	INITIALIZE pr_person.* TO NULL 
	INITIALIZE pr_taskperiod.* TO NULL 
	INITIALIZE pr_ts_head.* TO NULL 
	SELECT * INTO pr_ts_head.* FROM ts_head 
	WHERE ts_num = pr_ts_num 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF status = notfound THEN 
		LET msgresp = kandoomsg("U",7001,"Timesheet") 
		#7001 Logic Error: Timesheet RECORD Not Found
		RETURN false 
	END IF 
	SELECT * INTO pr_person.* FROM person 
	WHERE person_code = pr_ts_head.person_code 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF status = notfound THEN 
		LET msgresp = kandoomsg("U",7001,"Person") 
		#7001 Logic Error: Person RECORD Not Found
		RETURN false 
	END IF 
	SELECT * INTO pr_taskperiod.* FROM taskperiod 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND task_period_ind = pr_person.task_period_ind 
	IF status = notfound THEN 
		LET msgresp = kandoomsg("U",7001,"Task Period") 
		#7001 "Logic Error: Task Period RECORD Not Found
		RETURN false 
	END IF 
	LET pr_year_head_num = pr_ts_head.year_num 
	LET pr_period_head_num = pr_ts_head.period_num 
	DISPLAY BY NAME pr_ts_head.ts_num, 
	pr_ts_head.per_end_date, 
	pr_ts_head.posted_flag, 
	pr_year_head_num, 
	pr_period_head_num, 
	pr_person.person_code, 
	pr_person.name_text, 
	pr_taskperiod.task_period_text 

	DECLARE c_ts_detail CURSOR FOR 
	SELECT * FROM ts_detail 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND ts_num = pr_ts_head.ts_num 
	LET idx = 0 
	FOREACH c_ts_detail INTO pr_ts_detail.* 
		LET idx = idx + 1 
		LET pa_ts_detail2[idx].comment_text = pr_ts_detail.comment_text 
		LET pa_ts_detail2[idx].unit_cost_amt = pr_ts_detail.unit_cost_amt 
		LET pa_ts_detail2[idx].unit_bill_amt = pr_ts_detail.unit_bill_amt 
		LET pa_ts_detail2[idx].env_code = pr_ts_detail.env_code 
		LET pa_ts_detail2[idx].pay_code = pr_ts_detail.pay_code 
		LET pa_ts_detail2[idx].rate_code = pr_ts_detail.rate_code 
		LET pa_ts_detail[idx].task_date = pr_ts_detail.task_date 
		LET pa_ts_detail[idx].job_code = pr_ts_detail.job_code 
		LET pa_ts_detail[idx].var_code = pr_ts_detail.var_code 
		LET pa_ts_detail[idx].activity_code = pr_ts_detail.activity_code 
		LET pa_ts_detail[idx].res_code = pr_ts_detail.res_code 
		LET pa_ts_detail[idx].dur_qty = pr_ts_detail.dur_qty 
		LET pa_ts_detail[idx].seq_num = pr_ts_detail.seq_num 
		LET pa_ts_detail[idx].year_num = pr_ts_detail.year_num 
		LET pa_ts_detail[idx].period_num = pr_ts_detail.period_num 
		LET pa_ts_detail[idx].post_flag = pr_ts_detail.post_flag 
		LET pa_ts_detail[idx].allocation_ind = pr_ts_detail.allocation_ind 
		IF idx = 300 THEN 
			LET msgresp = kandoomsg("U",6100,idx) 
			#6100 First idx rows selected only
			EXIT FOREACH 
		END IF 
	END FOREACH 
	LET msgresp = kandoomsg("U",9113,idx) 
	#9113 idx records selected
	IF idx = 0 THEN 
		LET idx = 1 
		INITIALIZE pa_ts_detail[idx].* TO NULL 
	END IF 
	CALL set_count(idx) 
	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 
	LET msgresp = kandoomsg("J",1511,"") 
	#1511 F7 TO Toggle All; F9 TO Toggle One
	LET pr_post_timesheet = 0 
	INPUT ARRAY pa_ts_detail WITHOUT DEFAULTS FROM sr_ts_detail.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","J87","input_arr-pa_ts_detail-1") -- alch kd-506 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE ROW 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
		BEFORE FIELD scroll_flag 
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
			LET pr_ts_detail.allocation_ind = pa_ts_detail[idx].allocation_ind 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			LET pr_scroll_flag = pa_ts_detail[idx].scroll_flag 
			SELECT * INTO pr_jmresource.* FROM jmresource 
			WHERE res_code = pa_ts_detail[idx].res_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			DISPLAY BY NAME pa_ts_detail2[idx].comment_text, 
			pr_jmresource.desc_text 

			DISPLAY pa_ts_detail[idx].* TO sr_ts_detail[scrn].* 

		AFTER FIELD scroll_flag 
			LET pa_ts_detail[idx].scroll_flag = pr_scroll_flag 
			DISPLAY pa_ts_detail[idx].* TO sr_ts_detail[scrn].* 

			IF fgl_lastkey() = fgl_keyval("down") 
			AND arr_curr() >= arr_count() THEN 
				LET msgresp = kandoomsg("U",9001,"") 
				#9001 There no more rows...
				NEXT FIELD scroll_flag 
			END IF 
			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF pa_ts_detail[idx+1].job_code IS NULL THEN 
					LET msgresp = kandoomsg("U",9001,"") 
					#9001 There no more rows...
					NEXT FIELD scroll_flag 
				END IF 
			END IF 
			IF fgl_lastkey() = fgl_keyval("nextpage") 
			AND pa_ts_detail[idx+9].job_code IS NULL THEN 
				LET msgresp = kandoomsg("U",9001,"") 
				#9001 No more rows in this direction
				NEXT FIELD scroll_flag 
			END IF 
		BEFORE FIELD seq_num 
			NEXT FIELD scroll_flag 
		ON KEY (F9) 
			LET pa_ts_detail[idx].scroll_flag = pr_scroll_flag 
			IF infield(scroll_flag) THEN 
				IF pa_ts_detail[idx].job_code IS NULL THEN 
					NEXT FIELD scroll_flag 
				END IF 
				IF pa_ts_detail[idx].post_flag = "Y" THEN 
					LET msgresp = kandoomsg("J",9607,"") 
					#9607 This detail line has already been posted
					NEXT FIELD scroll_flag 
				END IF 
				IF pr_scroll_flag IS NULL THEN 
					LET pa_ts_detail[idx].scroll_flag = "*" 
					LET pr_scroll_flag = "*" 
					LET pr_post_timesheet = pr_post_timesheet + 1 
				ELSE 
					LET pa_ts_detail[idx].scroll_flag = NULL 
					LET pr_scroll_flag = NULL 
					LET pr_post_timesheet = pr_post_timesheet - 1 
				END IF 
				NEXT FIELD scroll_flag 
			END IF 
		ON KEY (F7) 
			LET pa_ts_detail[idx].scroll_flag = pr_scroll_flag 
			IF infield(scroll_flag) THEN 
				LET scrn = 1 
				FOR i = 1 TO arr_count() 
					IF pa_ts_detail[i].job_code IS NULL THEN 
						LET scrn = scrn + 1 
						CONTINUE FOR 
					END IF 
					IF pa_ts_detail[i].post_flag = "Y" THEN 
						LET scrn = scrn + 1 
						CONTINUE FOR 
					END IF 
					IF pa_ts_detail[i].scroll_flag IS NULL THEN 
						LET pa_ts_detail[i].scroll_flag = "*" 
						LET pr_post_timesheet = pr_post_timesheet + 1 
					ELSE 
						LET pa_ts_detail[i].scroll_flag = NULL 
						LET pr_post_timesheet = pr_post_timesheet - 1 
					END IF 
					IF scrn <= 9 THEN 
						DISPLAY pa_ts_detail[i].* TO sr_ts_detail[scrn].* 

						LET scrn = scrn + 1 
					END IF 
				END FOR 
				LET pr_scroll_flag = pa_ts_detail[idx].scroll_flag 
				NEXT FIELD scroll_flag 
			END IF 
		AFTER ROW 
			DISPLAY pa_ts_detail[idx].* TO sr_ts_detail[scrn].* 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				IF kandoomsg("J",8003,pr_post_timesheet) = "N" THEN 
					#8003 Confirm TO post ??? timesheet entries (Y/N)?
					NEXT FIELD scroll_flag 
				END IF 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag 
	OR NOT pr_post_timesheet THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN 
	END IF 
	GOTO bypass 
	LABEL recovery: 
	IF error_recover(err_message, status) != "Y" THEN 
		RETURN 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	BEGIN WORK 
		LOCK TABLE ts_detail in share MODE 
		LOCK TABLE jobledger in share MODE 
		LET err_message = "V87 - Locking Timesheet Header Record" 
		DECLARE c_ts_head3 CURSOR FOR 
		SELECT * FROM ts_head 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND ts_num = pr_ts_num 
		FOR UPDATE 
		OPEN c_ts_head3 
		FETCH c_ts_head3 INTO pr_ts_head.* 
		CLOSE c_ts_head3 
		FOR i = 1 TO arr_count() 
			IF pa_ts_detail[i].task_date IS NOT NULL 
			AND pa_ts_detail[i].dur_qty IS NOT NULL 
			AND pa_ts_detail[i].post_flag = "N" 
			AND pa_ts_detail[i].scroll_flag IS NOT NULL THEN 
				LET err_message = "V87 - Updating Timesheet Detail Line" 
				DECLARE c_ts_detail4 CURSOR FOR 
				SELECT * FROM ts_detail 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND ts_num = pr_ts_head.ts_num 
				AND seq_num = pa_ts_detail[i].seq_num 
				FOR UPDATE 
				OPEN c_ts_detail4 
				FETCH c_ts_detail4 INTO pr_ts_detail.* 
				IF status = notfound THEN 
					GOTO recovery 
				END IF 
				UPDATE ts_detail 
				SET post_flag = "Y" 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND ts_num = pr_ts_detail.ts_num 
				AND seq_num = pr_ts_detail.seq_num 
				CLOSE c_ts_detail4 
				SELECT * INTO pr_jmresource.* FROM jmresource 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND res_code = pr_ts_detail.res_code 
				LET err_message = "V87 - Validating Year & Period" 
				
				CALL valid_period (
					glob_rec_kandoouser.cmpy_code, 
					pr_ts_detail.year_num, 
					pr_ts_detail.period_num, 
					LEDGER_TYPE_JM) 
				RETURNING 
					pr_jobledger.year_num, 
					pr_jobledger.period_num, 
					pr_return_status 
				
				IF pr_return_status THEN 
					GOTO recovery 
				END IF 
				
				LET err_message = "V87 - Locking Activity Record" 
				
				DECLARE c_activity2 CURSOR FOR 
				SELECT * FROM activity 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND job_code = pr_ts_detail.job_code 
				AND var_code = pr_ts_detail.var_code 
				AND activity_code = pr_ts_detail.activity_code 
				FOR UPDATE 
				OPEN c_activity2 
				FETCH c_activity2 INTO pr_activity.* 
				IF status = notfound THEN 
					GOTO recovery 
				END IF 
				LET pr_activity.seq_num = pr_activity.seq_num + 1 
				LET pr_jobledger.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET pr_jobledger.trans_date = pr_ts_detail.task_date 
				LET pr_jobledger.job_code = pr_ts_detail.job_code 
				LET pr_jobledger.var_code = pr_ts_detail.var_code 
				LET pr_jobledger.activity_code = pr_ts_detail.activity_code 
				LET pr_jobledger.seq_num = pr_activity.seq_num 
				LET pr_jobledger.trans_type_ind = "TS" 
				LET pr_jobledger.trans_source_num = pr_ts_detail.ts_num 
				LET pr_jobledger.trans_source_text = pr_ts_detail.res_code 
				IF pr_ts_detail.unit_cost_amt IS NULL THEN 
					LET pr_ts_detail.unit_cost_amt = pr_jmresource.unit_cost_amt 
				END IF 
				LET pr_jobledger.allocation_ind = pr_ts_detail.allocation_ind 
				LET pr_jobledger.trans_qty = pr_ts_detail.dur_qty 
				LET pr_jobledger.trans_amt = pr_ts_detail.unit_cost_amt 
				* pr_ts_detail.dur_qty 
				IF pr_ts_detail.unit_bill_amt IS NULL THEN 
					LET pr_ts_detail.unit_bill_amt = pr_jmresource.unit_bill_amt 
				END IF 
				LET pr_jobledger.charge_amt = pr_ts_detail.unit_bill_amt 
				* pr_ts_detail.dur_qty 
				LET pr_jobledger.desc_text = pr_ts_detail.comment_text 
				IF pr_jobledger.desc_text IS NULL THEN 
					LET pr_jobledger.desc_text = pr_jmresource.desc_text 
				END IF 
				LET pr_jobledger.posted_flag = "N" 
				LET pr_jobledger.entry_date = today 
				LET pr_jobledger.entry_code = glob_rec_kandoouser.sign_on_code 
				LET err_message = "V87 - Insert Jobledger Record" 
				INSERT INTO jobledger VALUES (pr_jobledger.*) 
				CALL set_start(pr_jobledger.job_code, pr_jobledger.trans_date) 
				IF pr_jmparms.pa_post_flag = "Y" THEN 
					LET pr_tp_ects_int.trn_num = 0 
					LET pr_tp_ects_int.cust_code = glob_rec_kandoouser.cmpy_code 
					LET pr_tp_ects_int.emp_code = pr_ts_head.person_code 
					LET pr_tp_ects_int.payroll_no_code = NULL 
					LET pr_tp_ects_int.period_end_date = pr_ts_head.per_end_date 
					LET pr_tp_ects_int.env_code = "1" 
					LET pr_tp_ects_int.daily_date = pr_ts_detail.task_date 
					LET pr_tp_ects_int.cat_code = NULL 
					LET pr_tp_ects_int.pay_code = pr_ts_detail.pay_code 
					LET pr_tp_ects_int.hrs_qty = pr_ts_detail.dur_qty 
					LET pr_tp_ects_int.mlt_qty = 0 
					LET pr_tp_ects_int.rate_amt = 0 
					LET pr_tp_ects_int.rte_set_code = NULL 
					LET pr_tp_ects_int.rate_code = pr_ts_detail.rate_code 
					LET pr_tp_ects_int.acct_code = pr_jmresource.exp_acct_code 
					LET pr_tp_ects_int.cost_code = pr_ts_detail.job_code, 
					pr_ts_detail.var_code, 
					pr_ts_detail.activity_code 
					LET pr_tp_ects_int.entry_date = today 
					LET pr_tp_ects_int.user_login = glob_rec_kandoouser.sign_on_code 
					LET pr_tp_ects_int.bch_num = NULL 
					LET pr_tp_ects_int.src_code = "Job Management" 
					LET pr_tp_ects_int.asc_trn_code = NULL 
					LET err_message = "V87 - Inserting tp_ects_ind Record" 
					INSERT INTO tp_ects_int VALUES (pr_tp_ects_int.*) 
				END IF 
				LET pr_activity.act_cost_amt = pr_activity.act_cost_amt 
				+ pr_jobledger.trans_amt 
				LET pr_activity.act_cost_qty = pr_activity.act_cost_qty 
				+ pr_jobledger.trans_qty 
				LET pr_activity.post_revenue_amt = pr_activity.post_revenue_amt 
				+ pr_jobledger.charge_amt 
				LET err_message = "V87 - Updating Activity" 
				IF pr_activity.act_start_date IS NULL 
				OR pr_activity.act_start_date > pr_jobledger.trans_date THEN 
					UPDATE activity 
					SET act_start_date = pr_jobledger.trans_date, 
					act_cost_amt = pr_activity.act_cost_amt, 
					act_cost_qty = pr_activity.act_cost_qty, 
					post_revenue_amt = pr_activity.post_revenue_amt, 
					seq_num = pr_activity.seq_num 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND job_code = pr_ts_detail.job_code 
					AND var_code = pr_ts_detail.var_code 
					AND activity_code = pr_ts_detail.activity_code 
				ELSE 
					UPDATE activity 
					SET act_cost_amt = pr_activity.act_cost_amt, 
					act_cost_qty = pr_activity.act_cost_qty, 
					post_revenue_amt = pr_activity.post_revenue_amt, 
					seq_num = pr_activity.seq_num 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND job_code = pr_ts_detail.job_code 
					AND var_code = pr_ts_detail.var_code 
					AND activity_code = pr_ts_detail.activity_code 
				END IF 
				CLOSE c_activity2 
			END IF 
		END FOR 
	COMMIT WORK 
	WHENEVER ERROR stop 
	SELECT count(*) INTO pr_posted_count FROM ts_detail 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND ts_num = pr_ts_head.ts_num 
	AND post_flag = "Y" 
	SELECT count(*) INTO pr_detail_count FROM ts_detail 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND ts_num = pr_ts_head.ts_num 
	IF pr_detail_count = pr_posted_count THEN 
		LET pr_posted_flag = "Y" 
	ELSE 
		IF pr_posted_count = 0 THEN 
			LET pr_posted_flag = "N" 
		ELSE 
			LET pr_posted_flag = "P" 
		END IF 
	END IF 
	IF pr_posted_flag <> pr_ts_head.posted_flag THEN 
		UPDATE ts_head 
		SET posted_flag = pr_posted_flag 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND ts_num = pr_ts_head.ts_num 
	END IF 
END FUNCTION 


FUNCTION post_timesheet(pr_ts_num) 
	DEFINE 
	pr_ts_head RECORD LIKE ts_head.*, 
	pr_ts_detail RECORD LIKE ts_detail.*, 
	pr_ts_num LIKE ts_head.ts_num, 
	pr_person RECORD LIKE person.*, 
	pr_jmresource RECORD LIKE jmresource.*, 
	pr_jobledger RECORD LIKE jobledger.*, 
	pr_tp_ects_int RECORD LIKE tp_ects_int.*, 
	pr_activity RECORD LIKE activity.*, 
	pr_return_status SMALLINT, 
	err_message CHAR(60) 

	GOTO bypass 
	LABEL recovery: 
	IF error_recover(err_message, status) != "Y" THEN 
		EXIT program 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	BEGIN WORK 
		LOCK TABLE ts_detail in share MODE 
		LOCK TABLE jobledger in share MODE 
		LET err_message = "V87 - Locking Timesheet Header Record" 
		DECLARE c_ts_head2 CURSOR FOR 
		SELECT * FROM ts_head 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND ts_num = pr_ts_num 
		FOR UPDATE 
		OPEN c_ts_head2 
		FETCH c_ts_head2 INTO pr_ts_head.* 
		UPDATE ts_head 
		SET posted_flag = "Y" 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND ts_num = pr_ts_head.ts_num 
		CLOSE c_ts_head2 
		DECLARE c_ts_detail2 CURSOR FOR 
		SELECT * FROM ts_detail 
		WHERE ts_num = pr_ts_head.ts_num 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		FOREACH c_ts_detail2 INTO pr_ts_detail.* 
			IF pr_ts_detail.task_date IS NOT NULL 
			AND pr_ts_detail.dur_qty IS NOT NULL 
			AND pr_ts_detail.post_flag = "N" THEN 
				LET err_message = "V87 - Updating Timesheet Detail Line" 
				DECLARE c_ts_detail3 CURSOR FOR 
				SELECT * FROM ts_detail 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND ts_num = pr_ts_detail.ts_num 
				AND seq_num = pr_ts_detail.seq_num 
				FOR UPDATE 
				OPEN c_ts_detail3 
				FETCH c_ts_detail3 INTO pr_ts_detail.* 
				IF status = notfound THEN 
					GOTO recovery 
				END IF 
				UPDATE ts_detail 
				SET post_flag = "Y" 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND ts_num = pr_ts_detail.ts_num 
				AND seq_num = pr_ts_detail.seq_num 
				CLOSE c_ts_detail3 
				SELECT * INTO pr_jmresource.* FROM jmresource 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND res_code = pr_ts_detail.res_code 
				LET err_message = "V87 - Validating Year & Period" 
				
				CALL valid_period (
					glob_rec_kandoouser.cmpy_code, 
					pr_ts_detail.year_num, 
					pr_ts_detail.period_num, 
					LEDGER_TYPE_JM) 
				RETURNING 
					pr_jobledger.year_num, 
					pr_jobledger.period_num, 
					pr_return_status 
				
				IF pr_return_status THEN 
					GOTO recovery 
				END IF 
				
				LET err_message = "V87 - Locking Activity Record" 
				
				DECLARE c_activity CURSOR FOR 
				SELECT * FROM activity 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND job_code = pr_ts_detail.job_code 
				AND var_code = pr_ts_detail.var_code 
				AND activity_code = pr_ts_detail.activity_code 
				FOR UPDATE 
				OPEN c_activity 
				FETCH c_activity INTO pr_activity.* 
				IF status = notfound THEN 
					GOTO recovery 
				END IF 
				LET pr_activity.seq_num = pr_activity.seq_num + 1 
				LET pr_jobledger.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET pr_jobledger.trans_date = pr_ts_detail.task_date 
				LET pr_jobledger.job_code = pr_ts_detail.job_code 
				LET pr_jobledger.var_code = pr_ts_detail.var_code 
				LET pr_jobledger.activity_code = pr_ts_detail.activity_code 
				LET pr_jobledger.seq_num = pr_activity.seq_num 
				LET pr_jobledger.trans_type_ind = "TS" 
				LET pr_jobledger.trans_source_num = pr_ts_detail.ts_num 
				LET pr_jobledger.trans_source_text = pr_ts_detail.res_code 
				IF pr_ts_detail.unit_cost_amt IS NULL THEN 
					LET pr_ts_detail.unit_cost_amt = pr_jmresource.unit_cost_amt 
				END IF 
				LET pr_jobledger.allocation_ind = pr_ts_detail.allocation_ind 
				LET pr_jobledger.trans_qty = pr_ts_detail.dur_qty 
				LET pr_jobledger.trans_amt = pr_ts_detail.unit_cost_amt 
				* pr_ts_detail.dur_qty 
				IF pr_ts_detail.unit_bill_amt IS NULL THEN 
					LET pr_ts_detail.unit_bill_amt = pr_jmresource.unit_bill_amt 
				END IF 
				LET pr_jobledger.charge_amt = pr_ts_detail.unit_bill_amt 
				* pr_ts_detail.dur_qty 
				LET pr_jobledger.desc_text = pr_ts_detail.comment_text 
				IF pr_jobledger.desc_text IS NULL THEN 
					LET pr_jobledger.desc_text = pr_jmresource.desc_text 
				END IF 
				LET pr_jobledger.posted_flag = "N" 
				LET pr_jobledger.entry_date = today 
				LET pr_jobledger.entry_code = glob_rec_kandoouser.sign_on_code 
				LET err_message = "V87 - Insert Jobledger Record" 
				INSERT INTO jobledger VALUES (pr_jobledger.*) 
				CALL set_start(pr_jobledger.job_code, pr_jobledger.trans_date) 
				IF pr_jmparms.pa_post_flag = "Y" THEN 
					LET pr_tp_ects_int.trn_num = 0 
					LET pr_tp_ects_int.cust_code = glob_rec_kandoouser.cmpy_code 
					LET pr_tp_ects_int.emp_code = pr_ts_head.person_code 
					LET pr_tp_ects_int.payroll_no_code = NULL 
					LET pr_tp_ects_int.period_end_date = pr_ts_head.per_end_date 
					LET pr_tp_ects_int.env_code = "1" 
					LET pr_tp_ects_int.daily_date = pr_ts_detail.task_date 
					LET pr_tp_ects_int.cat_code = NULL 
					LET pr_tp_ects_int.pay_code = pr_ts_detail.pay_code 
					LET pr_tp_ects_int.hrs_qty = pr_ts_detail.dur_qty 
					LET pr_tp_ects_int.mlt_qty = 0 
					LET pr_tp_ects_int.rate_amt = 0 
					LET pr_tp_ects_int.rte_set_code = NULL 
					LET pr_tp_ects_int.rate_code = pr_ts_detail.rate_code 
					LET pr_tp_ects_int.acct_code = pr_jmresource.exp_acct_code 
					LET pr_tp_ects_int.cost_code = pr_ts_detail.job_code, 
					pr_ts_detail.var_code, 
					pr_ts_detail.activity_code 
					LET pr_tp_ects_int.entry_date = today 
					LET pr_tp_ects_int.user_login = glob_rec_kandoouser.sign_on_code 
					LET pr_tp_ects_int.bch_num = NULL 
					LET pr_tp_ects_int.src_code = "Job Management" 
					LET pr_tp_ects_int.asc_trn_code = NULL 
					LET err_message = "V87 - Inserting tp_ects_ind Record" 
					INSERT INTO tp_ects_int VALUES (pr_tp_ects_int.*) 
				END IF 
				LET pr_activity.act_cost_amt = pr_activity.act_cost_amt 
				+ pr_jobledger.trans_amt 
				LET pr_activity.act_cost_qty = pr_activity.act_cost_qty 
				+ pr_jobledger.trans_qty 
				LET pr_activity.post_revenue_amt = pr_activity.post_revenue_amt 
				+ pr_jobledger.charge_amt 
				LET err_message = "V87 - Updating Activity" 
				IF pr_activity.act_start_date IS NULL 
				OR pr_activity.act_start_date > pr_jobledger.trans_date THEN 
					UPDATE activity 
					SET act_start_date = pr_jobledger.trans_date, 
					act_cost_amt = pr_activity.act_cost_amt, 
					act_cost_qty = pr_activity.act_cost_qty, 
					post_revenue_amt = pr_activity.post_revenue_amt, 
					seq_num = pr_activity.seq_num 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND job_code = pr_ts_detail.job_code 
					AND var_code = pr_ts_detail.var_code 
					AND activity_code = pr_ts_detail.activity_code 
				ELSE 
					UPDATE activity 
					SET act_cost_amt = pr_activity.act_cost_amt, 
					act_cost_qty = pr_activity.act_cost_qty, 
					post_revenue_amt = pr_activity.post_revenue_amt, 
					seq_num = pr_activity.seq_num 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND job_code = pr_ts_detail.job_code 
					AND var_code = pr_ts_detail.var_code 
					AND activity_code = pr_ts_detail.activity_code 
				END IF 
				CLOSE c_activity 
			END IF 
		END FOREACH 
	COMMIT WORK 
	WHENEVER ERROR stop 
END FUNCTION 
