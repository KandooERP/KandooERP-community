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

	Source code beautified by beautify.pl on 2020-01-02 19:48:27	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "J_JM_GLOBALS.4gl" 

# Job Cost Transfer - transfers costs FROM WIP FOR internal jobs (which
#                     are NOT invoiced AND external jobs WHERE costs
#                     have been entered AFTER job completion AND invoicing

GLOBALS 
	DEFINE 
	formname CHAR(15), 
	pr_menunames RECORD LIKE menunames.*, 
	pa_job array[100] OF RECORD 
		trans CHAR(1), 
		job_code LIKE job.job_code, 
		title_text LIKE job.title_text, 
		type_code LIKE job.type_code, 
		bill_way_ind LIKE job.bill_way_ind, 
		internal_flag LIKE job.internal_flag, 
		cost DECIMAL(16,2) 
	END RECORD, 
	pr_job RECORD LIKE job.*, 
	pr_jobtype RECORD LIKE jobtype.*, 
	pr_jobvars RECORD LIKE jobvars.*, 
	pr_job_desc RECORD LIKE job_desc.*, 
	pa_job_desc array[100] OF LIKE job_desc.desc_text, 
	pr_customer RECORD LIKE customer.*, 
	pr_coa RECORD LIKE coa.*, 
	pr_jmparms RECORD LIKE jmparms.*, 
	pr_rec_kandoouser RECORD LIKE kandoouser.*, 
	pr_user_scan_code LIKE kandoouser.acct_mask_code, 
	pv_date DATE, 
	pv_year LIKE period.year_num, 
	pv_period LIKE period.period_num, 
	user_default_code, 
	acct_desc_text LIKE coa.desc_text, 
	default_entry_ok, entry_flag SMALLINT, 
	err_continue CHAR(1), 
	return_status INTEGER, 
	ans CHAR(1), 
	max_cnt SMALLINT, 
	runner CHAR(30), 
	idx, scrn, cnt SMALLINT 

END GLOBALS 

MAIN 
	#Initial UI Init
	CALL setModuleId("JS2") -- albo 
	CALL ui_init(0) 
	DEFER quit 
	DEFER interrupt 
	CALL authenticate(getmoduleid()) 
	CALL user_security(glob_rec_kandoouser.cmpy_code, glob_rec_kandoouser.sign_on_code) 
	RETURNING pr_rec_kandoouser.acct_mask_code, pr_user_scan_code 
	OPEN WINDOW w301 with FORM "J301" -- alch kd-747 
	CALL winDecoration_j("J301") -- alch kd-747 
	MENU " Job Cost Transfers" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","JS2","menu-job_cost_transfer-1") -- alch kd-506 
		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 
		COMMAND "Transfer" " Transfer Costs" 
			CALL show_jobs( ) 
			NEXT option "Exit" 
		COMMAND KEY(interrupt,"E") "Exit" " RETURN TO The Menus" 
			EXIT MENU 
		COMMAND KEY (control-w) 
			CALL kandoohelp("") 
	END MENU 
	CLOSE WINDOW w301 
END MAIN 



FUNCTION show_jobs( ) 
	DEFINE 
	fv_zero_cost, 
	fv_reselect SMALLINT, 
	fv_end_date DATE, 
	fv_finish_flag LIKE job.finish_flag, 
	runner CHAR(100), 
	idx SMALLINT, 
	scrn SMALLINT, 
	cnt SMALLINT, 
	query_text CHAR(200), 
	sel_text CHAR(1200) 
	LET fv_reselect = true 
	WHILE fv_reselect 
		CLEAR FORM 
		#MESSAGE " Enter criteria - press ESC"  attribute (yellow)
		LET msgresp = kandoomsg("U",1001," ") 
		CONSTRUCT query_text ON 
		job.job_code, 
		job.title_text, 
		job.type_code, 
		job.bill_way_ind, 
		job.internal_flag 
		FROM 
		sr_job[1].job_code, 
		sr_job[1].title_text, 
		sr_job[1].type_code, 
		sr_job[1].bill_way_ind, 
		sr_job[1].internal_flag 
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","JS2","const-job_job_code-16") -- alch kd-506 
			ON ACTION "WEB-HELP" -- albo kd-373 
				CALL onlinehelp(getmoduleid(),null) 
		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			EXIT WHILE 
		END IF 
		LET sel_text = 
		"SELECT '*', job.job_code, ", 
		"job.title_text, ", 
		"job.type_code, ", 
		"job.bill_way_ind, ", 
		"job.internal_flag, 0 , job.act_end_date, finish_flag ", 
		" FROM job WHERE ", 
		query_text clipped, 
		" AND ", 
		"job.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\"", 
		" AND (job.acct_code matches \"",pr_user_scan_code, 
		"\" OR ", "job.locked_ind <= \"1\")", 
		" ORDER BY job.job_code" 

		LET fv_reselect = false 

		PREPARE job FROM sel_text 
		#MESSAGE  "Searching FOR jobs..."
		LET msgresp = kandoomsg("J",1002," ") 
		DECLARE jobcurs CURSOR FOR job 
		OPEN jobcurs 
		LET idx = 1 
		FOREACH jobcurs INTO pa_job[idx].*, fv_end_date, fv_finish_flag 

			IF pa_job[idx].internal_flag = "N" THEN 
				# IF fv_end_date IS NULL THEN
				IF fv_finish_flag != "Y" THEN 
					CONTINUE FOREACH 
				END IF 
			END IF 


			CALL costs2post( pa_job[idx].job_code) 
			RETURNING pa_job[idx].cost, fv_zero_cost 
			IF fv_zero_cost THEN 
				CONTINUE FOREACH 
			END IF 




			LET idx = idx + 1 
			IF idx > 100 THEN 
				EXIT FOREACH 
			END IF 

		END FOREACH 
		CLOSE jobcurs 
		LET idx = idx -1 
		LET max_cnt = idx 
		IF idx > 0 THEN 
			LET msgresp = kandoomsg("J",1019,idx) 
			# First idx jobs selected only
			#   MESSAGE idx, " Jobs, ", "RETURN FOR details, F10 TO toggle post,",
			#           " F9 TO re-SELECT" attribute (yellow)
			LET msgresp = kandoomsg("J",1539,idx) 
		ELSE 
			#MESSAGE "No jobs satisfy criteria, F9 TO Re-SELECT"
			#       attribute (yellow)
			LET msgresp = kandoomsg("J",1541,idx) 
		END IF 
		LET cnt = idx 
		CALL set_count(idx) 

		INPUT ARRAY pa_job WITHOUT DEFAULTS FROM sr_job.* 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","JS2","input_arr-pa_job-1") -- alch kd-506 

			ON ACTION "WEB-HELP" -- albo kd-373 
				CALL onlinehelp(getmoduleid(),null) 

			ON KEY (F10) 
				IF pa_job[idx].trans = " " THEN 
					LET pa_job[idx].trans = "*" 
				ELSE 
					LET pa_job[idx].trans = " " 
				END IF 
				DISPLAY pa_job[idx].* TO sr_job[scrn].* 


				#ON KEY(F9)
				#LET fv_reselect = TRUE
				#EXIT INPUT

			BEFORE ROW 
				LET idx = arr_curr() 
				LET scrn = scr_line() 
				IF idx <= cnt THEN 
					DISPLAY pa_job[idx].* TO sr_job[scrn].* 

				END IF 
			AFTER FIELD trans 
				IF fgl_lastkey() = fgl_keyval("down") 
				AND arr_curr() >= arr_count() THEN 
					LET msgresp=kandoomsg("J",9001,"") 
					#9001 There are no more rows in the direction you are going.
					NEXT FIELD trans 
				END IF 
				IF fgl_lastkey() = fgl_keyval("RETURN") THEN 
					--#               IF fgl_fglgui() THEN
					--#                  EXIT INPUT
					--#               END IF
					CALL run_prog("J12",pa_job[idx].job_code,"","","") 
					LET idx = arr_curr() 
					LET scrn = scr_line() 
					DISPLAY pa_job[idx].* TO sr_job[scrn].* 

					NEXT FIELD trans 
				END IF 
				IF fgl_lastkey() = fgl_keyval("right") 
				OR fgl_lastkey() = fgl_keyval("tab") THEN 
					CALL run_prog("J12",pa_job[idx].job_code,"","","") 
					LET idx = arr_curr() 
					LET scrn = scr_line() 
					DISPLAY pa_job[idx].* TO sr_job[scrn].* 

					NEXT FIELD trans 
				END IF 
			AFTER ROW 
				IF idx <= cnt THEN 
					DISPLAY pa_job[idx].* TO sr_job[scrn].* 

				END IF 
			ON KEY (control-w) 
				CALL kandoohelp("") 
		END INPUT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET fv_reselect = true 
		END IF 

	END WHILE 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	ELSE 
		OPEN WINDOW w302 with FORM "J302" -- alch kd-747 
		CALL winDecoration_j("J302") -- alch kd-747 
		LET pv_date = today 
		CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, today) 
		RETURNING pv_year,pv_period 
		INPUT pv_date,pv_year,pv_period WITHOUT DEFAULTS 
		FROM jobledger.trans_date, 
		jobledger.year_num, 
		jobledger.period_num 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","JS2","input-pv_date-1") -- alch kd-506 

			ON ACTION "WEB-HELP" -- albo kd-373 
				CALL onlinehelp(getmoduleid(),null) 

			AFTER FIELD trans_date 
				CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, pv_date) 
				RETURNING pv_year, pv_period 
				DISPLAY pv_year,pv_period TO jobledger.year_num, 
				jobledger.period_num 

			AFTER INPUT 
				CALL valid_period(glob_rec_kandoouser.cmpy_code, pv_year,pv_period,"JM") 
				RETURNING pv_year, 
				pv_period, 
				return_status 
				IF return_status THEN 
					NEXT FIELD trans_date 
				END IF 

			ON KEY (control-w) 
				CALL kandoohelp("") 
		END INPUT 

		CLOSE WINDOW w302 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			RETURN 
		END IF 

		FOR idx = 1 TO max_cnt 
			IF pa_job[idx].trans = "*" THEN 
				CALL transfer_costs(pa_job[idx].job_code) 
			END IF 
		END FOR 

	END IF 

END FUNCTION 


FUNCTION costs2post( fv_job_code) 

	DEFINE fr_job RECORD LIKE job.*, 
	fr_activity RECORD LIKE activity.*, 
	fv_job_code LIKE job.job_code, 
	fv_billed, 
	fv_actual, 
	fv_posted LIKE activity.bdgt_bill_amt, 
	fv_amt DECIMAL(16,2), 
	fv_zero_cost, 
	fv_count SMALLINT 

	SELECT * 
	INTO fr_job.* 
	FROM job 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND job_code = fv_job_code 

	IF status !=0 THEN 
		#ERROR "Job does NOT exist" ATTRIBUTE(reverse,red)
		LET msgresp = kandoomsg("J",9590," ") 
		RETURN 0 
	END IF 

	LET fv_amt = 0 
	LET fv_billed = 0 
	LET fv_posted = 0 
	LET fv_actual = 0 
	LET fv_zero_cost = true 

	DECLARE cact_curs CURSOR FOR 
	SELECT * 
	FROM activity 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND job_code = fv_job_code 

	FOREACH cact_curs INTO fr_activity.* 

		IF fr_activity.bill_way_ind = "F" THEN 
			SELECT sum(trans_amt), count(*) 
			INTO fv_billed, 
			fv_count 
			FROM jobledger 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND job_code = fv_job_code 
			AND var_code = fr_activity.var_code 
			AND activity_code = fr_activity.activity_code 
			AND trans_amt IS NOT NULL 
			AND trans_type_ind != "CT" 

			IF fv_count = 0 THEN 
				CONTINUE FOREACH 
			END IF 

			IF fv_billed IS NULL THEN 
				LET fv_billed = 0 
			ELSE 
				IF fv_billed > 0 THEN 
					LET fv_zero_cost = false 
				END IF 
			END IF 

			LET fv_posted = fr_activity.post_cost_amt 

			# IF internal AND NOT finished - adjust quantities according TO cost allocation
			IF fr_job.internal_flag = "Y" 
			AND fr_job.finish_flag != "Y" THEN 
				CASE fr_activity.cost_alloc_flag 
					WHEN "1" 
						LET fv_billed = (fr_activity.est_comp_per * 
						fr_activity.est_cost_amt) / 100 
					WHEN "2" 
						IF fr_activity.est_comp_per != 100 THEN 
							LET fv_billed = (fr_activity.est_comp_per * 
							fr_activity.est_cost_amt) / 100 
						END IF 
					WHEN "3" 
						LET fv_billed = (fv_billed * fr_activity.est_comp_per) 
						/ 100 
					WHEN "5" 
						LET fv_posted = 0 
						LET fv_billed = 0 
				END CASE 
			END IF 
		ELSE 

			SELECT sum(trans_amt), count(*) 
			INTO fv_billed, 
			fv_count 
			FROM jobledger 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND job_code = fv_job_code 
			AND var_code = fr_activity.var_code 
			AND activity_code = fr_activity.activity_code 
			AND trans_amt IS NOT NULL 

			IF fv_count = 0 THEN 
				CONTINUE FOREACH 
			END IF 

			IF fv_billed IS NULL THEN 
				LET fv_billed = 0 
			ELSE 
				IF fv_billed > 0 THEN 
					LET fv_zero_cost = false 
				END IF 
			END IF 

			SELECT sum(apply_cos_amt) 
			INTO fv_posted 
			FROM resbill 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND job_code = fv_job_code 
			AND var_code = fr_activity.var_code 
			AND activity_code = fr_activity.activity_code 
			AND apply_cos_amt IS NOT NULL 

			IF fv_posted IS NULL THEN 
				LET fv_posted = 0 
			END IF 

		END IF 

		IF fv_billed != fv_posted THEN 
			LET fv_amt = fv_amt + (fv_billed - fv_posted) 
		END IF 

	END FOREACH 

	RETURN fv_amt, 
	fv_zero_cost 

END FUNCTION 

FUNCTION transfer_costs(fv_job_code) 

	DEFINE fv_job_code LIKE job.job_code, 
	fv_billed LIKE activity.post_cost_amt, 
	fv_posted LIKE activity.post_cost_amt, 
	fv_actual LIKE activity.post_cost_amt, 
	fv_amount DECIMAL(16,2), 
	fv_count SMALLINT, 
	fr_job RECORD LIKE job.*, 
	fr_activity RECORD LIKE activity.*, 
	fr_resbill RECORD LIKE resbill.*, 
	fr_jobledger RECORD LIKE jobledger.* 

	#DISPLAY "Transfering costs FOR ",fv_job_code AT 10,10
	LET msgresp = kandoomsg("J",1542,fv_job_code) 

	SELECT * 
	INTO fr_job.* 
	FROM job 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND job_code = fv_job_code 

	IF status != 0 THEN 
		#ERROR "Could NOT access Job information" ATTRIBUTE(reverse,red)
		LET msgresp = kandoomsg("J",9590," ") 
		SLEEP 1 
		RETURN 
	END IF 

	BEGIN WORK 

		DECLARE cjob_act CURSOR FOR 
		SELECT * 
		FROM activity 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND job_code = fv_job_code 
		FOR UPDATE 

		FOREACH cjob_act INTO fr_activity.* 

			IF fr_activity.bill_way_ind = "F" THEN 

				SELECT sum(trans_amt), count(*) 
				INTO fv_posted, 
				fv_count 
				FROM jobledger 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND job_code = fv_job_code 
				AND var_code = fr_activity.var_code 
				AND activity_code = fr_activity.activity_code 
				AND trans_amt IS NOT NULL 
				AND trans_type_ind != "CT" 

				IF fv_count = 0 THEN 
					CONTINUE FOREACH 
				END IF 

				IF fv_posted IS NULL THEN 
					LET fv_posted = 0 
				END IF 

				LET fv_billed = fr_activity.post_cost_amt 
				# IF internal AND NOT finished - adjust quantities according TO cost allocation
				IF fr_job.internal_flag = "Y" 
				AND fr_job.finish_flag != "Y" THEN 
					CASE fr_activity.cost_alloc_flag 
						WHEN "1" 
							LET fv_posted = (fr_activity.est_comp_per * 
							fr_activity.est_cost_amt) / 100 
						WHEN "2" 
							IF fr_activity.est_comp_per != 100 THEN 
								LET fv_posted = (fr_activity.est_comp_per * 
								fr_activity.est_cost_amt) / 100 
							END IF 
						WHEN "3" 
							LET fv_posted = (fv_posted * fr_activity.est_comp_per) 
							/ 100 
						WHEN "5" 
							LET fv_posted = 0 
							LET fv_billed = 0 
					END CASE 
				END IF 
			ELSE 

				SELECT sum(trans_amt), count(*) 
				INTO fv_posted, 
				fv_count 
				FROM jobledger 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND job_code = fv_job_code 
				AND var_code = fr_activity.var_code 
				AND activity_code = fr_activity.activity_code 
				AND trans_amt IS NOT NULL 

				IF fv_count = 0 THEN 
					CONTINUE FOREACH 
				END IF 

				IF fv_posted IS NULL THEN 
					LET fv_posted = 0 
				END IF 

				SELECT sum(apply_cos_amt) 
				INTO fv_billed 
				FROM resbill 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND job_code = fv_job_code 
				AND var_code = fr_activity.var_code 
				AND activity_code = fr_activity.activity_code 
				AND apply_cos_amt IS NOT NULL 

				IF fv_billed IS NULL THEN 
					LET fv_billed = 0 
				END IF 

			END IF 

			IF fv_billed != fv_posted THEN 
				LET fv_amount = fv_posted - fv_billed 
			ELSE 
				LET fv_amount = 0 
			END IF 

			IF fv_amount = 0 THEN 
				CONTINUE FOREACH 
			END IF 

			LET fr_jobledger.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET fr_jobledger.trans_date = pv_date 
			LET fr_jobledger.year_num = pv_year 
			LET fr_jobledger.period_num = pv_period 
			LET fr_jobledger.job_code = fr_activity.job_code 
			LET fr_jobledger.var_code = fr_activity.var_code 
			LET fr_jobledger.activity_code = fr_activity.activity_code 
			LET fr_jobledger.seq_num = fr_activity.seq_num +1 
			LET fr_jobledger.trans_type_ind = "CT" 
			LET fr_jobledger.trans_source_num = 0 
			LET fr_jobledger.trans_source_text = "COST XFR" 
			LET fr_jobledger.trans_amt = fv_amount * -1 
			LET fr_jobledger.trans_qty = 0 
			LET fr_jobledger.charge_amt = 0 
			LET fr_jobledger.posted_flag = "N" 
			LET fr_jobledger.desc_text = "Cost transfer" 
			LET fr_jobledger.allocation_ind = "C" 
			LET fr_jobledger.entry_date = today 
			LET fr_jobledger.entry_code = glob_rec_kandoouser.sign_on_code 

			INSERT INTO jobledger VALUES (fr_jobledger.*) 

			UPDATE activity 
			SET post_cost_amt = post_cost_amt + fv_amount, 
			seq_num = fr_jobledger.seq_num 
			WHERE CURRENT OF cjob_act 

		END FOREACH 

	COMMIT WORK 

END FUNCTION 
