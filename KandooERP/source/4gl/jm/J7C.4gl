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
GLOBALS "J7_GLOBALS.4gl" 

# Purpose - Job Accrual Reversal

GLOBALS 
	DEFINE 
	pr_sel_text CHAR(2500), 
	pr_jobtype RECORD LIKE jobtype.*, 
	pr_jmparms RECORD LIKE jmparms.*, 
	pr_time_frame RECORD 
		from_year_num LIKE period.year_num, 
		from_period_num LIKE period.period_num, 
		to_year_num LIKE period.year_num, 
		to_period_num LIKE period.period_num 
	END RECORD 
END GLOBALS 

MAIN 

	#Initial UI Init
	CALL setModuleId("J7C") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 


	SELECT jmparms.* INTO pr_jmparms.* FROM jmparms 
	WHERE jmparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND jmparms.key_code = "1" 
	IF status = notfound THEN 
		LET msgresp = kandoomsg("J",7505,"") 
		#7505" Job Management Parameters NOT found - Refer Menu JZP "
		EXIT program 
	END IF 
	OPEN WINDOW j203 with FORM "J203" -- alch kd-747 
	CALL winDecoration_j("J203") -- alch kd-747 
	DISPLAY BY NAME pr_jmparms.prompt1_text, 
	pr_jmparms.prompt2_text, 
	pr_jmparms.prompt3_text, 
	pr_jmparms.prompt4_text, 
	pr_jmparms.prompt5_text, 
	pr_jmparms.prompt6_text, 
	pr_jmparms.prompt7_text, 
	pr_jmparms.prompt8_text 
	MENU " Accrual Reversal" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","J7C","menu-accrual_reversal-1") -- alch kd-506 
		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 
		COMMAND "Run" " Enter selection criteria AND create reversals" 
			IF J7C_rpt_query() THEN 
				CALL J7C_rpt_process() 
				NEXT option "Exit" 
			END IF 
		COMMAND KEY("E",interrupt)"Exit" " Exit TO menus" 
			EXIT MENU 
		COMMAND KEY (control-w) 
			CALL kandoohelp("") 
	END MENU 
	CLOSE WINDOW j203 
END MAIN 


FUNCTION J7C_rpt_query() 
	DEFINE 
	pr_type_code LIKE job.type_code 

	CLEAR FORM 
	DISPLAY BY NAME pr_jmparms.prompt1_text, 
	pr_jmparms.prompt2_text, 
	pr_jmparms.prompt3_text, 
	pr_jmparms.prompt4_text, 
	pr_jmparms.prompt5_text, 
	pr_jmparms.prompt6_text, 
	pr_jmparms.prompt7_text, 
	pr_jmparms.prompt8_text 
	LET msgresp = kandoomsg("J",1001,"") 
	#1001 "Enter Selection Criteria; OK TO Continue"
	#CONSTRUCT BY NAME glob_rec_rmsreps.sel_text on job.job_code,
	CONSTRUCT pr_sel_text ON 
	job.job_code, 
	job.title_text, 
	job.type_code, 
	job.cust_code, 
	customer.name_text, 
	job.resp_code, 
	job.finish_flag, 
	jobledger.var_code, 
	jobledger.activity_code, 
	activity.title_text, 
	jobledger.trans_source_text, 
	jmresource.resgrp_code, 
	resgrp.res_type_ind, 
	job.report_text, 
	job.report1_text, 
	job.report2_text, 
	job.report3_text, 
	job.report4_text, 
	job.report5_text, 
	job.report6_text, 
	job.report7_text, 
	job.report8_text 
	FROM 
	job.job_code, 
	job.title_text, 
	job.type_code, 
	job.cust_code, 
	customer.name_text, 
	job.resp_code, 
	job.finish_flag, 
	jobledger.var_code, 
	jobledger.activity_code, 
	activity.title_text, 
	jobledger.trans_source_text, 
	jmresource.resgrp_code, 
	resgrp.res_type_ind, 
	job.report_text, 
	job.report1_text, 
	job.report2_text, 
	job.report3_text, 
	job.report4_text, 
	job.report5_text, 
	job.report6_text, 
	job.report7_text, 
	job.report8_text 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","J7C","const-job_job_code-3") -- alch kd-506 
		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 
		AFTER FIELD type_code 
			IF field_touched(type_code) THEN 
				LET pr_type_code = get_fldbuf(type_code) 
			END IF 
			IF pr_type_code IS NOT NULL THEN 
				CALL disp_report_codes(pr_type_code) 
			END IF 
		BEFORE FIELD report1_text 
			IF pr_type_code IS NOT NULL THEN 
				IF pr_jobtype.prompt1_ind = 5 THEN 
					NEXT FIELD report2_text 
				END IF 
			ELSE 
				IF pr_jmparms.prompt1_ind = 5 THEN 
					NEXT FIELD report2_text 
				END IF 
			END IF 
		BEFORE FIELD report2_text 
			IF pr_type_code IS NOT NULL THEN 
				IF pr_jobtype.prompt2_ind = 5 THEN 
					IF fgl_lastkey() = fgl_keyval("up") THEN 
						NEXT FIELD report1_text 
					ELSE 
						NEXT FIELD report3_text 
					END IF 
				END IF 
			ELSE 
				IF pr_jmparms.prompt2_ind = 5 THEN 
					IF fgl_lastkey() = fgl_keyval("up") THEN 
						NEXT FIELD report1_text 
					ELSE 
						NEXT FIELD report3_text 
					END IF 
				END IF 
			END IF 
		BEFORE FIELD report3_text 
			IF pr_type_code IS NOT NULL THEN 
				IF pr_jobtype.prompt3_ind = 5 THEN 
					IF fgl_lastkey() = fgl_keyval("up") THEN 
						NEXT FIELD report2_text 
					ELSE 
						NEXT FIELD report4_text 
					END IF 
				END IF 
			ELSE 
				IF pr_jmparms.prompt3_ind = 5 THEN 
					IF fgl_lastkey() = fgl_keyval("up") THEN 
						NEXT FIELD report2_text 
					ELSE 
						NEXT FIELD report4_text 
					END IF 
				END IF 
			END IF 
		BEFORE FIELD report4_text 
			IF pr_type_code IS NOT NULL THEN 
				IF pr_jobtype.prompt4_ind = 5 THEN 
					IF fgl_lastkey() = fgl_keyval("up") THEN 
						NEXT FIELD report3_text 
					ELSE 
						NEXT FIELD report5_text 
					END IF 
				END IF 
			ELSE 
				IF pr_jmparms.prompt4_ind = 5 THEN 
					IF fgl_lastkey() = fgl_keyval("up") THEN 
						NEXT FIELD report3_text 
					ELSE 
						NEXT FIELD report5_text 
					END IF 
				END IF 
			END IF 
		BEFORE FIELD report5_text 
			IF pr_type_code IS NOT NULL THEN 
				IF pr_jobtype.prompt5_ind = 5 THEN 
					IF fgl_lastkey() = fgl_keyval("up") THEN 
						NEXT FIELD report4_text 
					ELSE 
						NEXT FIELD report6_text 
					END IF 
				END IF 
			ELSE 
				IF pr_jmparms.prompt5_ind = 5 THEN 
					IF fgl_lastkey() = fgl_keyval("up") THEN 
						NEXT FIELD report4_text 
					ELSE 
						NEXT FIELD report6_text 
					END IF 
				END IF 
			END IF 
		BEFORE FIELD report6_text 
			IF pr_type_code IS NOT NULL THEN 
				IF pr_jobtype.prompt6_ind = 5 THEN 
					IF fgl_lastkey() = fgl_keyval("up") THEN 
						NEXT FIELD report5_text 
					ELSE 
						NEXT FIELD report7_text 
					END IF 
				END IF 
			ELSE 
				IF pr_jmparms.prompt6_ind = 5 THEN 
					IF fgl_lastkey() = fgl_keyval("up") THEN 
						NEXT FIELD report5_text 
					ELSE 
						NEXT FIELD report7_text 
					END IF 
				END IF 
			END IF 
		BEFORE FIELD report7_text 
			IF pr_type_code IS NOT NULL THEN 
				IF pr_jobtype.prompt7_ind = 5 THEN 
					IF fgl_lastkey() = fgl_keyval("up") THEN 
						NEXT FIELD report6_text 
					ELSE 
						NEXT FIELD report8_text 
					END IF 
				END IF 
			ELSE 
				IF pr_jmparms.prompt7_ind = 5 THEN 
					IF fgl_lastkey() = fgl_keyval("up") THEN 
						NEXT FIELD report6_text 
					ELSE 
						NEXT FIELD report8_text 
					END IF 
				END IF 
			END IF 
		BEFORE FIELD report8_text 
			IF pr_type_code IS NOT NULL THEN 
				IF pr_jobtype.prompt8_ind = 5 THEN 
					EXIT CONSTRUCT 
				END IF 
			ELSE 
				IF pr_jmparms.prompt8_ind = 5 THEN 
					EXIT CONSTRUCT 
				END IF 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END CONSTRUCT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 
	CALL get_time_frame() 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 
	RETURN true 
END FUNCTION 


FUNCTION J7C_rpt_process() 
	DEFINE 
	pr_jobledger RECORD LIKE jobledger.*, 
	pr_rowid INTEGER, 
	pr_job RECORD LIKE job.*, 
	pr_order_text CHAR(13), 
	query_text CHAR(3000), 
	date_text CHAR(250), 
	sort_text CHAR(250), 
	pr_zone, 
	pr_costcode, 
	pr_comp, 
	pr_subc LIKE activity.activity_code, 
	pr_unit_code LIKE jmresource.unit_code, 
	pr_resgrp_code LIKE resgrp.resgrp_code, 
	pr_res_type_ind LIKE resgrp.res_type_ind, 
	pr_okay_flag CHAR(1), 
	pr_rev_cnt SMALLINT 

	LET date_text = 
	" AND jobledger.year_num >= ",pr_time_frame.from_year_num," ", 
	" AND jobledger.period_num >= ",pr_time_frame.from_period_num," ", 
	" AND jobledger.year_num <= ",pr_time_frame.to_year_num," ", 
	" AND jobledger.period_num <= ",pr_time_frame.to_period_num," " 
	LET query_text = "SELECT jobledger.*, jobledger.rowid ", 
	"FROM jobledger, job, activity, customer, ", 
	" jmresource, resgrp ", 
	" WHERE job.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
	" AND jobledger.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
	" AND jobledger.job_code = job.job_code ", 
	" AND activity.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
	" AND activity.job_code = jobledger.job_code ", 
	" AND activity.var_code = jobledger.var_code ", 
	" AND activity.activity_code = jobledger.activity_code ", 
	" AND jmresource.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
	" AND jmresource.res_code = jobledger.trans_source_text ", 
	" AND resgrp.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
	" AND jmresource.resgrp_code = resgrp.resgrp_code ", 
	" AND jobledger.trans_type_ind <> 'SA' ", 
	" AND jobledger.trans_type_ind <> 'CO' ", 
	" AND jobledger.accrual_ind = '1' ", 
	" AND jobledger.reversal_date IS NULL ", 
	" AND customer.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
	" AND job.cust_code = customer.cust_code ", 
	" AND ",pr_sel_text clipped," ",date_text, 
	" ORDER BY ", 
	"jobledger.job_code, ", 
	"jobledger.var_code, ", 
	"jobledger.trans_date " 
	LET msgresp = kandoomsg("J",1002,0) 
	# searching
	PREPARE s_job FROM query_text 
	DECLARE c_job CURSOR with HOLD FOR s_job 
	LET pr_rev_cnt = 0 
	LET pr_okay_flag = true 
	#   OPEN WINDOW w1 AT 10,10 with 3 rows,60 columns
	#       ATTRIBUTE(border)      -- alch KD-747
	FOREACH c_job INTO pr_jobledger.*, pr_rowid 
		LET pr_rev_cnt = 1 
		DISPLAY " Processing ",pr_jobledger.job_code at 1,1 
		DISPLAY " ",pr_jobledger.activity_code at 2,1 
		LET pr_okay_flag = reverse_accrual(pr_rowid) 
		IF pr_okay_flag THEN 
		ELSE 
			EXIT FOREACH 
		END IF 
	END FOREACH 
	IF pr_okay_flag THEN 
		CASE pr_rev_cnt 
			WHEN 1 
				LET msgresp = kandoomsg("J",7024,0) 
				# successful generation of accrual reversal.
			WHEN 0 
				LET msgresp = kandoomsg("J",7025,0) 
				# no accruals found TO reverse
		END CASE 
	END IF 
	CLOSE c_job 
	#   CLOSE WINDOW w1      -- alch KD-747
END FUNCTION 


FUNCTION disp_report_codes(pr_type_code) 
	DEFINE 
	pr_type_code LIKE job.type_code 

	SELECT * INTO pr_jobtype.* FROM jobtype 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND type_code = pr_type_code 
	IF status <> notfound THEN 
		IF pr_jobtype.prompt1_text IS NULL THEN 
			LET pr_jobtype.prompt1_text = pr_jmparms.prompt1_text 
			LET pr_jobtype.prompt1_ind = pr_jmparms.prompt1_ind 
		END IF 
		IF pr_jobtype.prompt2_text IS NULL THEN 
			LET pr_jobtype.prompt2_text = pr_jmparms.prompt2_text 
			LET pr_jobtype.prompt2_ind = pr_jmparms.prompt2_ind 
		END IF 
		IF pr_jobtype.prompt3_text IS NULL THEN 
			LET pr_jobtype.prompt3_text = pr_jmparms.prompt3_text 
			LET pr_jobtype.prompt3_ind = pr_jmparms.prompt3_ind 
		END IF 
		IF pr_jobtype.prompt4_text IS NULL THEN 
			LET pr_jobtype.prompt4_text = pr_jmparms.prompt4_text 
			LET pr_jobtype.prompt4_ind = pr_jmparms.prompt4_ind 
		END IF 
		IF pr_jobtype.prompt5_text IS NULL THEN 
			LET pr_jobtype.prompt5_text = pr_jmparms.prompt5_text 
			LET pr_jobtype.prompt5_ind = pr_jmparms.prompt5_ind 
		END IF 
		IF pr_jobtype.prompt6_text IS NULL THEN 
			LET pr_jobtype.prompt6_text = pr_jmparms.prompt6_text 
			LET pr_jobtype.prompt6_ind = pr_jmparms.prompt6_ind 
		END IF 
		IF pr_jobtype.prompt7_text IS NULL THEN 
			LET pr_jobtype.prompt7_text = pr_jmparms.prompt7_text 
			LET pr_jobtype.prompt7_ind = pr_jmparms.prompt7_ind 
		END IF 
		IF pr_jobtype.prompt8_text IS NULL THEN 
			LET pr_jobtype.prompt8_text = pr_jmparms.prompt8_text 
			LET pr_jobtype.prompt8_ind = pr_jmparms.prompt8_ind 
		END IF 
		IF pr_jobtype.prompt1_ind != 5 
		OR pr_jobtype.prompt2_ind != 5 
		OR pr_jobtype.prompt3_ind != 5 
		OR pr_jobtype.prompt4_ind != 5 
		OR pr_jobtype.prompt5_ind != 5 
		OR pr_jobtype.prompt6_ind != 5 
		OR pr_jobtype.prompt7_ind != 5 
		OR pr_jobtype.prompt8_ind != 5 THEN 
			DISPLAY pr_jobtype.prompt1_text, 
			pr_jobtype.prompt2_text, 
			pr_jobtype.prompt3_text, 
			pr_jobtype.prompt4_text, 
			pr_jobtype.prompt5_text, 
			pr_jobtype.prompt6_text, 
			pr_jobtype.prompt7_text, 
			pr_jobtype.prompt8_text 
			TO jobtype.prompt1_text, 
			jobtype.prompt2_text, 
			jobtype.prompt3_text, 
			jobtype.prompt4_text, 
			jobtype.prompt5_text, 
			jobtype.prompt6_text, 
			jobtype.prompt7_text, 
			jobtype.prompt8_text 
		END IF 
	END IF 
END FUNCTION 


FUNCTION get_time_frame() 
	DEFINE 
	pr_year_num LIKE period.year_num, 
	pr_period_num LIKE period.period_num, 
	pr_string CHAR(7), 
	pr_return_status SMALLINT 
	OPEN WINDOW j204 with FORM "J204" -- alch kd-747 
	CALL winDecoration_j("J204") -- alch kd-747 
	LET msgresp = kandoomsg("J",1431,0) 
	#1020 Enter Reversal Details; OK TO Continue
	CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, today - 30) 
	RETURNING pr_year_num, 
	pr_period_num 
	LET pr_time_frame.from_year_num = pr_year_num 
	LET pr_time_frame.from_period_num = pr_period_num 
	CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, today ) 
	RETURNING pr_year_num, 
	pr_period_num 
	LET pr_time_frame.to_year_num = pr_year_num 
	LET pr_time_frame.to_period_num = pr_period_num 
	INPUT BY NAME pr_time_frame.from_year_num, 
	pr_time_frame.from_period_num, 
	pr_time_frame.to_year_num, 
	pr_time_frame.to_period_num WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","J7C","input-pr_time_frame-1") -- alch kd-506 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				IF pr_time_frame.from_year_num IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD from_year_num 
				END IF 
				IF pr_time_frame.from_period_num IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD from_period_num 
				END IF 
				IF pr_time_frame.to_year_num IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD to_year_num 
				END IF 
				IF pr_time_frame.to_period_num IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD to_period_num 
				END IF 
				SELECT 1 FROM period 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND year_num = pr_time_frame.from_year_num 
				AND period_num = pr_time_frame.from_period_num 
				IF status = notfound THEN 
					LET pr_string = pr_time_frame.from_year_num USING "&&&&", 
					"/",pr_time_frame.from_period_num USING "&&" 
					LET msgresp = kandoomsg("G",9201,pr_string) 
					#9201 "Year AND Period NOT defined FOR 1998/02"
					NEXT FIELD from_year_num 
				END IF 
				SELECT 1 FROM period 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND year_num = pr_time_frame.to_year_num 
				AND period_num = pr_time_frame.to_period_num 
				IF status = notfound THEN 
					LET pr_string = pr_time_frame.to_year_num USING "&&&&", 
					"/",pr_time_frame.to_period_num USING "&&" 
					LET msgresp = kandoomsg("G",9201,pr_string) 
					#9201 "Year AND Period NOT defined FOR 1998/02"
					NEXT FIELD to_year_num 
				END IF 
				IF pr_time_frame.to_year_num < pr_time_frame.from_year_num THEN 
					LET msgresp = kandoomsg("U",9907,pr_time_frame.from_year_num) 
					#9907 "Value must be >= FROM year"
					NEXT FIELD to_year_num 
				END IF 
				IF pr_time_frame.from_year_num = pr_time_frame.to_year_num 
				AND pr_time_frame.to_period_num <= pr_time_frame.from_period_num THEN 
					LET msgresp = kandoomsg("U",9927,pr_time_frame.from_period_num) 
					#9907 "Value must be > FROM period"
					NEXT FIELD to_period_num 
				END IF 
				
				CALL valid_period(
					glob_rec_kandoouser.cmpy_code, 
					pr_time_frame.to_year_num, 
					pr_time_frame.to_period_num, 
					LEDGER_TYPE_JM) 
				RETURNING 
					pr_time_frame.to_year_num, 
					pr_time_frame.to_period_num, 
					pr_return_status 
				
				IF pr_return_status THEN 
					NEXT FIELD to_year_num 
				END IF 

			END IF 

	END INPUT 

	CLOSE WINDOW J204 
END FUNCTION 


FUNCTION reverse_accrual(pr_rowid) 
	DEFINE 
	pr_jobledger RECORD LIKE jobledger.*, 
	ps_jobledger RECORD LIKE jobledger.*, 
	pr_activity RECORD LIKE activity.*, 
	pr_jmresource RECORD LIKE jmresource.*, 
	pr_rowid INTEGER, 
	err_message CHAR(40), 
	err_continue CHAR(1) 

	GOTO bypass 
	LABEL recovery: 
	LET err_continue = error_recover(err_message, status) 
	IF err_continue != "Y" THEN 
		RETURN false 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	BEGIN WORK 
		DECLARE jl_upd CURSOR FOR 
		SELECT * 
		FROM jobledger 
		WHERE rowid = pr_rowid 
		FOR UPDATE 
		OPEN jl_upd 
		FETCH jl_upd INTO ps_jobledger.* 
		IF status = notfound THEN 
			GOTO recovery 
		END IF 
		DECLARE act_upd CURSOR FOR 
		SELECT * 
		FROM activity 
		WHERE cmpy_code = ps_jobledger.cmpy_code 
		AND job_code = ps_jobledger.job_code 
		AND var_code = ps_jobledger.var_code 
		AND activity_code = ps_jobledger.activity_code 
		FOR UPDATE 
		OPEN act_upd 
		FETCH act_upd INTO pr_activity.* 
		IF status = notfound THEN 
			GOTO recovery 
		END IF 
		LET pr_activity.seq_num = pr_activity.seq_num + 1 
		LET err_message = "Inserting jobledger" 
		LET pr_jobledger.* = ps_jobledger.* 
		LET pr_jobledger.trans_date = today 
		LET pr_jobledger.year_num = pr_time_frame.to_year_num 
		LET pr_jobledger.period_num = pr_time_frame.to_period_num 
		LET pr_jobledger.seq_num = pr_activity.seq_num 
		LET pr_jobledger.trans_amt = 0 - ps_jobledger.trans_amt 
		LET pr_jobledger.trans_qty = 0 - ps_jobledger.trans_qty 
		LET pr_jobledger.charge_amt = 0 - ps_jobledger.charge_amt 
		LET pr_jobledger.posted_flag = "N" 
		LET pr_jobledger.desc_text = "Accrual Reversal ", 
		ps_jobledger.year_num USING "&&&&", 
		" / ", 
		ps_jobledger.period_num USING "&&" 
		LET pr_jobledger.accrual_ind = "2" 
		LET pr_jobledger.entry_code = glob_rec_kandoouser.sign_on_code 
		LET pr_jobledger.entry_date = today 
		INSERT INTO jobledger VALUES (pr_jobledger.*) 
		LET err_message = "J7C - Jobledger Update" 
		UPDATE jobledger 
		SET reversal_date = today 
		WHERE CURRENT OF jl_upd 
		LET pr_activity.act_cost_amt = pr_activity.act_cost_amt + 
		pr_jobledger.trans_amt 
		LET pr_activity.post_revenue_amt = pr_activity.post_revenue_amt + 
		pr_jobledger.charge_amt 
		SELECT unit_code INTO pr_jmresource.unit_code 
		FROM jmresource 
		WHERE cmpy_code = pr_jobledger.cmpy_code 
		AND res_code = pr_jobledger.trans_source_text 
		IF status = notfound THEN 
			LET pr_jmresource.unit_code = NULL 
		END IF 
		IF (pr_activity.unit_code IS NULL AND pr_jmresource.unit_code IS null) 
		OR pr_activity.unit_code = pr_jmresource.unit_code THEN 
			LET pr_activity.act_cost_qty = pr_activity.act_cost_qty + 
			pr_jobledger.trans_qty 
		END IF 
		LET err_message = "J7B Updating Activity" 
		CALL set_start(pr_jobledger.job_code, pr_jobledger.trans_date) 
		IF pr_activity.act_start_date IS NULL OR 
		pr_activity.act_start_date > pr_jobledger.trans_date THEN 
			UPDATE activity 
			SET act_start_date = pr_jobledger.trans_date, 
			act_cost_amt = pr_activity.act_cost_amt, 
			act_cost_qty = pr_activity.act_cost_qty, 
			post_revenue_amt = pr_activity.post_revenue_amt, 
			seq_num = pr_activity.seq_num 
			WHERE CURRENT OF act_upd 
		ELSE 
			UPDATE activity 
			SET act_cost_amt = pr_activity.act_cost_amt, 
			act_cost_qty = pr_activity.act_cost_qty, 
			post_revenue_amt = pr_activity.post_revenue_amt, 
			seq_num = pr_activity.seq_num 
			WHERE CURRENT OF act_upd 
		END IF 
	COMMIT WORK 
	WHENEVER ERROR stop 
	RETURN true 
END FUNCTION 
