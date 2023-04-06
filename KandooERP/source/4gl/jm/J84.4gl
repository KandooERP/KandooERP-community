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
GLOBALS "J81_GLOBALS.4gl" 

{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module V84 - Timesheet Inquiry

#GLOBALS
#   DEFINE
#      pr_jmparms RECORD LIKE jmparms.*,
#      pr_ts_head RECORD LIKE ts_head.*
#END GLOBALS

MAIN 
	#Initial UI Init
	CALL setModuleId("J84") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 


	CREATE temp TABLE t_summary (task_date DATE, 
	job_code CHAR(8), 
	var_code SMALLINT, 
	activity_code CHAR(8), 
	res_code CHAR(8), 
	dur_qty float) 
	SELECT * INTO pr_jmparms.* FROM jmparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND key_code = "1" 
	IF status = notfound THEN 
		LET msgresp = kandoomsg("J",7002,"") 
		#7002 "JM Parameters NOT found; Refer TO JZP"
		EXIT program 
	END IF 

	IF num_args() = 1 THEN 
		OPEN WINDOW j190 with FORM "J190" -- alch kd-747 
		CALL winDecoration_j("J190") -- alch kd-747 
		CALL display_timesheet(arg_val(1)) 
		LET int_flag = false 
		LET quit_flag = false 
		CLOSE WINDOW j190 
	ELSE 
		OPEN WINDOW j143 with FORM "J143" -- alch kd-747 
		CALL winDecoration_j("J143") -- alch kd-747 
		WHILE select_timesht() 
		END WHILE 
		CLOSE WINDOW j143 
	END IF 
END MAIN 


FUNCTION select_timesht() 
	DEFINE 
	query_text CHAR(800), 
	where_text CHAR(200), 
	pa_ts_head array[200] OF RECORD 
		scroll_flag CHAR(1), 
		person_code LIKE ts_head.person_code, 
		name_text LIKE person.name_text, 
		per_end_date LIKE ts_head.per_end_date, 
		ts_num LIKE ts_head.ts_num, 
		posted_flag LIKE ts_head.posted_flag 
	END RECORD, 
	pr_scroll_flag CHAR(1), 
	idx, scrn SMALLINT 

	CLEAR FORM 
	LET msgresp = kandoomsg("U",1001,"") 
	#1001 Enter Selection Criteria; OK TO Continue.
	CONSTRUCT BY NAME where_text ON 
	ts_head.person_code, 
	person.name_text, 
	ts_head.per_end_date, 
	ts_head.ts_num, 
	ts_head.posted_flag 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","J84","const-person_code-4") -- alch kd-506 
		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 
	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 
	LET query_text = "SELECT ts_head.person_code, person.name_text, ", 
	" ts_head.per_end_date, ts_head.ts_num, ", 
	" ts_head.posted_flag ", 
	" FROM ts_head, person ", 
	" WHERE ts_head.cmpy_code = '",glob_rec_kandoouser.cmpy_code ,"' ", 
	" AND person.cmpy_code = ts_head.cmpy_code ", 
	" AND person.person_code = ts_head.person_code ", 
	" AND ",where_text clipped," ", 
	" ORDER BY ts_head.person_code, ts_head.per_end_date " 
	PREPARE s_ts_head FROM query_text 
	DECLARE c_ts_head CURSOR FOR s_ts_head 
	LET idx = 1 
	FOREACH c_ts_head INTO pa_ts_head[idx].person_code, 
		pa_ts_head[idx].name_text, 
		pa_ts_head[idx].per_end_date, 
		pa_ts_head[idx].ts_num, 
		pa_ts_head[idx].posted_flag 
		IF idx = 200 THEN 
			LET msgresp = kandoomsg("U",6100,idx) 
			#6100 First idx records selected only
			LET idx = idx + 1 
			EXIT FOREACH 
		END IF 
		LET idx = idx + 1 
	END FOREACH 
	LET idx = idx - 1 
	LET msgresp = kandoomsg("U",9113,idx) 
	#9113 idx records selected
	IF idx = 0 THEN 
		LET idx = 1 
		INITIALIZE pa_ts_head[idx].* TO NULL 
	END IF 
	CALL set_count(idx) 
	LET msgresp = kandoomsg("A",1551,"") 
	#1033 ENTER on line TO View; OK TO Continue
	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 
	INPUT ARRAY pa_ts_head WITHOUT DEFAULTS FROM sr_ts_head.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","J84","input_arr-pa_ts_head-1") -- alch kd-506 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE ROW 
			LET idx = arr_curr() 
			LET scrn = scr_line() 

		BEFORE FIELD scroll_flag 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			LET pr_scroll_flag = pa_ts_head[idx].scroll_flag 
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
			AND pa_ts_head[idx+9].person_code IS NULL THEN 
				LET msgresp = kandoomsg("U",9001,"") 
				#9001 No more rows in this direction
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
			NEXT FIELD scroll_flag 
		AFTER ROW 
			DISPLAY pa_ts_head[idx].* TO sr_ts_head[scrn].* 

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
	pr_ts_detail RECORD LIKE ts_detail.*, 
	pr_jmresource RECORD LIKE jmresource.*, 
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
	pr_scroll_flag CHAR(1), 
	i, scrn, idx SMALLINT 

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
	LET msgresp = kandoomsg("J",1006,"") 
	#1006 F6 FOR Costs/Rates; F7 FOR Payments Codes;
	INPUT ARRAY pa_ts_detail WITHOUT DEFAULTS FROM sr_ts_detail.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","J84","input_arr-pa_ts_detail-1") -- alch kd-506 

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
		ON KEY (F6) 
			CALL display_cost(pr_ts_detail.*) 
		ON KEY (F7) 
			CALL display_pay_codes(pr_ts_detail.*) 
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
				OPTIONS INSERT KEY f36, 
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
				OPTIONS INSERT KEY f36, 
				DELETE KEY f36 
			END IF 
		AFTER ROW 
			DISPLAY pa_ts_detail[idx].* TO sr_ts_detail[scrn].* 

		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 
	RETURN 
END FUNCTION 


FUNCTION display_cost(pr_ts_detail) 
	DEFINE 
	pr_ts_detail RECORD LIKE ts_detail.*, 
	pr_jmresource RECORD LIKE jmresource.*, 
	pr_cost_total, 
	pr_bill_total DECIMAL(16,2) 
	OPEN WINDOW j135 with FORM "J135" -- alch kd-747 
	CALL winDecoration_j("J135") -- alch kd-747 
	INITIALIZE pr_jmresource.* TO NULL 
	SELECT * INTO pr_jmresource.* FROM jmresource 
	WHERE res_code = pr_ts_detail.res_code 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF pr_ts_detail.unit_cost_amt IS NULL THEN 
		LET pr_ts_detail.unit_cost_amt = pr_jmresource.unit_cost_amt 
	END IF 
	IF pr_ts_detail.unit_bill_amt IS NULL THEN 
		LET pr_ts_detail.unit_bill_amt = pr_jmresource.unit_bill_amt 
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
	DISPLAY BY NAME pr_ts_detail.unit_cost_amt, 
	pr_ts_detail.unit_bill_amt 

	CALL eventsuspend()#let msgresp = kandoomsg("U",1,"") 
	CLOSE WINDOW j135 
END FUNCTION 

FUNCTION display_pay_codes(pr_ts_detail) 
	DEFINE 
	pr_ts_detail RECORD LIKE ts_detail.* 
	OPEN WINDOW j137 with FORM "J137" -- alch kd-747 
	CALL winDecoration_j("J137") -- alch kd-747 
	DISPLAY BY NAME pr_ts_detail.env_code, 
	pr_ts_detail.pay_code, 
	pr_ts_detail.rate_code 
	CALL eventsuspend()#let msgresp = kandoomsg("U",1,"") 
	CLOSE WINDOW j137 
END FUNCTION 

FUNCTION display_comment(pr_comment_text) 
	DEFINE 
	pr_comment_text LIKE ts_detail.comment_text, 
	pr_ts_detail RECORD LIKE ts_detail.* 
	OPEN WINDOW j311 with FORM "J311" -- alch kd-747 
	CALL winDecoration_j("J311") -- alch kd-747 
	LET pr_ts_detail.comment_text = pr_comment_text 
	DISPLAY BY NAME pr_ts_detail.comment_text 
	CALL eventsuspend() # LET msgresp = kandoomsg("U",1,"") 
	CLOSE WINDOW j311 
END FUNCTION 
