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

	Source code beautified by beautify.pl on 2020-01-02 19:48:13	$Id: $
}

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "J_JM_GLOBALS.4gl" 
GLOBALS "J8_GLOBALS.4gl" 
GLOBALS "J81_GLOBALS.4gl" 

FUNCTION calc_end_date(pr_task_ind, pr_end_date, pr_period_length) 
	DEFINE 
	pr_end_date LIKE ts_head.per_end_date, 
	pr_period_length LIKE taskperiod.days_qty, 
	pr_day_num, pr_month_num, pr_year_num SMALLINT, 
	pr_task_ind LIKE person.task_period_ind, 
	pr_temp_date CHAR(10) 

	CASE pr_task_ind 
		WHEN "M" 
			LET pr_month_num = month(pr_end_date) + 1 
			LET pr_year_num = year(pr_end_date) 
			IF pr_month_num = 13 THEN 
				LET pr_month_num = 1 
				LET pr_year_num = pr_year_num + 1 
			END IF 
			CASE pr_month_num 
				WHEN 1 LET pr_day_num = 31 
				WHEN 2 LET pr_day_num = 28 
				WHEN 3 LET pr_day_num = 31 
				WHEN 4 LET pr_day_num = 30 
				WHEN 5 LET pr_day_num = 31 
				WHEN 6 LET pr_day_num = 30 
				WHEN 7 LET pr_day_num = 31 
				WHEN 8 LET pr_day_num = 31 
				WHEN 9 LET pr_day_num = 30 
				WHEN 10 LET pr_day_num = 31 
				WHEN 11 LET pr_day_num = 30 
				WHEN 12 LET pr_day_num = 31 
			END CASE 
			LET pr_temp_date = pr_day_num USING "&&", "/", 
			pr_month_num USING "&&", "/", 
			pr_year_num USING "&&&&" 
			LET pr_end_date = date(pr_temp_date) 
			IF pr_month_num = 2 THEN #check february 29 
				LET pr_end_date = pr_end_date + 1 
				LET pr_month_num = month(pr_end_date) 
				IF pr_month_num = 3 THEN #there IS no february 29 
					LET pr_end_date = pr_end_date - 1 
				END IF 
			END IF 
		OTHERWISE 
			LET pr_end_date = pr_end_date + pr_period_length 
	END CASE 
	RETURN pr_end_date 
END FUNCTION 


FUNCTION activity_totals() 
	DEFINE 
	pr_summary RECORD 
		task_date LIKE ts_detail.task_date, 
		job_code LIKE ts_detail.job_code, 
		var_code LIKE ts_detail.var_code, 
		activity_code LIKE ts_detail.activity_code, 
		res_code LIKE ts_detail.res_code, 
		dur_qty LIKE ts_detail.dur_qty 
	END RECORD, 
	pa_summary array[200] OF RECORD 
		scroll_flag CHAR(1), 
		job_code LIKE ts_detail.job_code, 
		var_code LIKE ts_detail.var_code, 
		activity_code LIKE ts_detail.activity_code, 
		task_date CHAR(10), 
		total_ind CHAR(2), 
		dur_qty LIKE ts_detail.dur_qty 
	END RECORD, 
	pr_ts_total_amt, pr_total_amt LIKE ts_detail.dur_qty, 
	pr_tmp_activity LIKE ts_detail.activity_code, 
	idx SMALLINT 
	OPEN WINDOW j141 with FORM "J141" -- alch kd-747 
	CALL winDecoration_j("J141") -- alch kd-747 
	FOR idx = 1 TO 200 
		INITIALIZE pa_summary[idx].* TO NULL 
	END FOR 
	LET msgresp = kandoomsg("J",1507,"") 
	#1507 "F3/F4 TO scroll; OK TO Continue"
	DECLARE c_summary CURSOR FOR 
	SELECT * FROM t_summary 
	ORDER BY activity_code, 
	task_date, 
	job_code, 
	var_code 
	LET pr_tmp_activity = NULL 
	LET pr_total_amt = 0 
	LET pr_ts_total_amt = 0 
	LET idx = 0 
	FOREACH c_summary INTO pr_summary.* 
		IF pr_tmp_activity IS NULL THEN 
			LET pr_tmp_activity = pr_summary.activity_code 
		END IF 
		IF pr_tmp_activity != pr_summary.activity_code THEN 
			LET idx = idx + 1 
			LET pa_summary[idx].activity_code = "**TOTAL" 
			LET pa_summary[idx].dur_qty = pr_total_amt 
			LET pa_summary[idx].total_ind = "**" 
			LET pr_total_amt = 0 
			LET pr_tmp_activity = pr_summary.activity_code 
		END IF 
		LET idx = idx + 1 
		LET pa_summary[idx].job_code = pr_summary.job_code 
		LET pa_summary[idx].var_code = pr_summary.var_code 
		LET pa_summary[idx].activity_code = pr_summary.activity_code 
		LET pa_summary[idx].task_date = pr_summary.task_date USING "ddd dd mmm" 
		LET pa_summary[idx].dur_qty = pr_summary.dur_qty 
		LET pr_total_amt = pr_total_amt + pr_summary.dur_qty 
		LET pr_ts_total_amt = pr_ts_total_amt + pr_summary.dur_qty 
	END FOREACH 
	LET idx = idx + 1 
	LET pa_summary[idx].activity_code = "**TOTAL" 
	LET pa_summary[idx].dur_qty = pr_total_amt 
	LET pa_summary[idx].total_ind = "**" 
	LET idx = idx + 1 
	LET pa_summary[idx].activity_code = "**TOTAL" 
	LET pa_summary[idx].task_date = "Timesheet" 
	LET pa_summary[idx].dur_qty = pr_ts_total_amt 
	CALL set_count(idx) 
	DISPLAY ARRAY pa_summary TO sr_summary.* 

		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","J81","display-arr-summary-1") -- alch kd-506

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END DISPLAY 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 
	CLOSE WINDOW j141 
END FUNCTION 


FUNCTION daily_totals() 
	DEFINE 
	pr_summary RECORD 
		task_date LIKE ts_detail.task_date, 
		job_code LIKE ts_detail.job_code, 
		var_code LIKE ts_detail.var_code, 
		activity_code LIKE ts_detail.activity_code, 
		res_code LIKE ts_detail.res_code, 
		dur_qty LIKE ts_detail.dur_qty 
	END RECORD, 
	pa_summary array[200] OF RECORD 
		scroll_flag CHAR(1), 
		task_date CHAR(10), 
		job_code LIKE ts_detail.job_code, 
		activity_code LIKE ts_detail.activity_code, 
		res_code CHAR(9), 
		total_ind CHAR(2), 
		dur_qty LIKE ts_detail.dur_qty 
	END RECORD, 
	pr_ts_total_amt, pr_total_amt LIKE ts_detail.dur_qty, 
	pr_tmp_date LIKE ts_detail.task_date, 
	idx SMALLINT 
	OPEN WINDOW j140 with FORM "J140" -- alch kd-747 
	CALL winDecoration_j("J140") -- alch kd-747 
	LET msgresp = kandoomsg("J",1507,"") 
	#1507 "F3/F4 TO scroll, OK TO Continue "
	FOR idx = 1 TO 200 
		INITIALIZE pa_summary[idx].* TO NULL 
	END FOR 
	LET msgresp = kandoomsg("J",1507,"") 
	#1507 "F3/F4 TO scroll; OK TO Continue"
	DECLARE c_summary2 CURSOR FOR 
	SELECT * FROM t_summary 
	ORDER BY task_date, 
	job_code, 
	activity_code, 
	res_code 
	LET pr_tmp_date = NULL 
	LET pr_total_amt = 0 
	LET pr_ts_total_amt = 0 
	LET idx = 0 
	FOREACH c_summary2 INTO pr_summary.* 
		IF pr_tmp_date IS NULL THEN 
			LET pr_tmp_date = pr_summary.task_date 
		END IF 
		IF pr_tmp_date != pr_summary.task_date THEN 
			LET idx = idx + 1 
			LET pa_summary[idx].activity_code = "**TOTAL" 
			LET pa_summary[idx].dur_qty = pr_total_amt 
			LET pa_summary[idx].total_ind = "**" 
			LET pr_tmp_date = pr_summary.task_date 
			LET pr_total_amt = 0 
		END IF 
		LET idx = idx + 1 
		LET pa_summary[idx].job_code = pr_summary.job_code 
		LET pa_summary[idx].res_code = pr_summary.res_code 
		LET pa_summary[idx].activity_code = pr_summary.activity_code 
		LET pa_summary[idx].task_date = pr_summary.task_date USING "ddd dd mmm" 
		LET pa_summary[idx].dur_qty = pr_summary.dur_qty 
		LET pr_total_amt = pr_total_amt + pr_summary.dur_qty 
		LET pr_ts_total_amt = pr_ts_total_amt + pr_summary.dur_qty 
	END FOREACH 
	LET idx = idx + 1 
	LET pa_summary[idx].activity_code = "**TOTAL" 
	LET pa_summary[idx].dur_qty = pr_total_amt 
	LET pa_summary[idx].total_ind = "**" 
	LET idx = idx + 1 
	LET pa_summary[idx].activity_code = "**TOTAL" 
	LET pa_summary[idx].res_code = "Timesheet" 
	LET pa_summary[idx].dur_qty = pr_ts_total_amt 
	CALL set_count(idx) 
	DISPLAY ARRAY pa_summary TO sr_summary.* 

		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","J81","display-arr-summary-2") -- alch kd-506

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END DISPLAY 


	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 
	CLOSE WINDOW j140 
END FUNCTION 
