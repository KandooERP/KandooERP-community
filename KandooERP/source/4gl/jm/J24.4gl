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

	Source code beautified by beautify.pl on 2020-01-02 19:48:02	$Id: $
}



{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module J24 Job Adjustments
#
# IF an adjustment IS TO be done, a reversing entry IS written TO jobledger
# the activity amt AND qty IS reduced by the value of the adjustment
# before a ledger row IS written FOR the target activity AND that activity has
# its act_amt AND qty increased.

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "J_JM_GLOBALS.4gl" 
GLOBALS 

	DEFINE 
	pr_user_scan_code LIKE kandoouser.acct_mask_code, 
	pr1_activity RECORD LIKE activity.*, 
	pr2_activity RECORD LIKE activity.*, 
	pr_jobledger RECORD LIKE jobledger.*, 
	pr_job RECORD LIKE job.*, 
	pr_activity RECORD LIKE activity.*, 
	pr_glparms RECORD LIKE glparms.*, 
	pr_jmparms RECORD LIKE jmparms.*, 
	pr_rec_kandoouser RECORD LIKE kandoouser.*, 
	pr_act1_cost_amt, 
	pr_act1_charge_amt, 
	pr_act2_cost_amt, 
	pr_act2_charge_amt, 
	pr_adj_cost_amt, 
	pr_adj_charge_amt, 
	pr_adj1_cost_amt, 
	pr_adj1_charge_amt DECIMAL(16, 2), 
	pr_act1_cost_qty, 
	pr_act2_cost_qty, 
	pr_adj_cost_qty, 
	pr_adj1_cost_qty DECIMAL(15, 3), 
	try_again, 
	another, 
	ans CHAR(1), 
	err_message CHAR(40), 
	runner CHAR(200), 
	idx, 
	scrn, 
	cnt, 
	max_row, 
	no_good SMALLINT 
END GLOBALS 


MAIN 
	#Initial UI Init
	CALL setModuleId("J24") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	CALL user_security(glob_rec_kandoouser.cmpy_code, glob_rec_kandoouser.sign_on_code) 
	RETURNING pr_rec_kandoouser.acct_mask_code, 
	pr_user_scan_code 
	SELECT jmparms.* INTO pr_jmparms.* 
	FROM jmparms 
	WHERE jmparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND jmparms.key_code = "1" 
	IF status = notfound THEN 
		#ERROR " Must SET up JM Parameters first in JZP"
		LET msgresp = kandoomsg("J", 1501, " ") 
		EXIT program 
	END IF 
	SELECT * INTO pr_glparms.* 
	FROM glparms 
	WHERE glparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND glparms.key_code = "1" 
	IF status = notfound THEN 
		#ERROR " Must SET up GL Parameters first in GZP"
		LET msgresp = kandoomsg("G", 9537, " ") 
		SLEEP 5 
		EXIT program 
	END IF 
	OPEN WINDOW j123 with FORM "J123" -- alch kd-747 
	CALL winDecoration_j("J123") -- alch kd-747 
	WHILE true 
		CALL doit() 
		IF int_flag 
		OR quit_flag THEN 
			EXIT program 
		END IF 
		CALL ins_rows() 
	END WHILE 
END MAIN 

FUNCTION doit() 
	INITIALIZE pr1_activity.* TO NULL 
	INITIALIZE pr2_activity.* TO NULL 
	INITIALIZE pr_jobledger.* TO NULL 
	CLEAR FORM 
	# Put in this WHILE TO allow re-edit of top half of SCREEN
	WHILE true 
		IF pr_jobledger.trans_date IS NULL THEN 
			LET pr_jobledger.trans_date = today 
		END IF 
		CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, today) 
		RETURNING pr_jobledger.year_num, 
		pr_jobledger.period_num 
		DISPLAY pr_jobledger.trans_date, 
		pr_jobledger.year_num, 
		pr_jobledger.period_num, 
		pr1_activity.job_code, 
		pr1_activity.var_code, 
		pr1_activity.activity_code, 
		pr2_activity.job_code, 
		pr2_activity.var_code, 
		pr2_activity.activity_code, 
		pr_adj_cost_amt, 
		pr_adj_cost_qty, 
		pr_adj_charge_amt, 
		pr_jobledger.desc_text TO trans_date, 
		year_num, 
		period_num, 
		job1_code, 
		var1_code, 
		activity1_code, 
		job2_code, 
		var2_code, 
		activity2_code, 
		adj_cost_amt, 
		adj_cost_qty, 
		adj_charge_amt, 
		desc_text 

		#MESSAGE " Enter details of Adjustment" ATTRIBUTE(yellow)
		LET msgresp = kandoomsg("J", 1550, " ") 
		INPUT pr_jobledger.trans_date, 
		pr_jobledger.year_num, 
		pr_jobledger.period_num, 
		pr1_activity.job_code, 
		pr1_activity.var_code, 
		pr1_activity.activity_code, 
		pr2_activity.job_code, 
		pr2_activity.var_code, 
		pr2_activity.activity_code, 
		pr_adj_cost_amt, 
		pr_adj_cost_qty, 
		pr_adj_charge_amt, 
		pr_jobledger.desc_text WITHOUT DEFAULTS 
		FROM trans_date, 
		year_num, 
		period_num, 
		job1_code, 
		var1_code, 
		activity1_code, 
		job2_code, 
		var2_code, 
		activity2_code, 
		adj_cost_amt, 
		adj_cost_qty, 
		adj_charge_amt, 
		desc_text 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","J19","input-pr_jobledger-1") -- alch kd-506 

			ON ACTION "WEB-HELP" -- albo kd-373 
				CALL onlinehelp(getmoduleid(),null) 

			AFTER FIELD trans_date 
				CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, pr_jobledger.trans_date) 
				RETURNING pr_jobledger.year_num, 
				pr_jobledger.period_num 
				DISPLAY BY NAME pr_jobledger.year_num, 
				pr_jobledger.period_num 

			AFTER FIELD period_num 
				CALL valid_period(glob_rec_kandoouser.cmpy_code, pr_jobledger.year_num, 
				pr_jobledger.period_num, "JM") 
				RETURNING pr_jobledger.year_num, 
				pr_jobledger.period_num, 
				no_good 
				IF no_good THEN 
					NEXT FIELD trans_date 
				END IF 
			ON KEY (control-b) 
				CASE 
					WHEN infield(job1_code) 
						LET pr1_activity.job_code = showpjobs(glob_rec_kandoouser.cmpy_code, pr_user_scan_code) 
						DISPLAY pr1_activity.job_code TO job1_code 

					WHEN infield(job2_code) 
						LET pr2_activity.job_code = showpjobs(glob_rec_kandoouser.cmpy_code, pr_user_scan_code) 
						DISPLAY pr2_activity.job_code TO job2_code 

					WHEN infield(var1_code) 
						LET pr1_activity.var_code = show_jobvars(glob_rec_kandoouser.cmpy_code, 
						pr1_activity.job_code ) 
						DISPLAY pr1_activity.var_code TO var1_code 

					WHEN infield(var2_code) 
						LET pr2_activity.var_code = show_jobvars(glob_rec_kandoouser.cmpy_code, 
						pr2_activity.job_code ) 
						DISPLAY pr2_activity.var_code TO var2_code 

					WHEN infield(activity1_code) 
						LET pr1_activity.activity_code = show_activity(glob_rec_kandoouser.cmpy_code, 
						pr1_activity.job_code , 
						pr1_activity.var_code ) 
						DISPLAY pr1_activity.activity_code TO activity1_code 

					WHEN infield(activity2_code) 
						LET pr2_activity.activity_code = show_activity(glob_rec_kandoouser.cmpy_code, 
						pr2_activity.job_code , 
						pr2_activity.var_code ) 
						DISPLAY pr2_activity.activity_code TO activity2_code 

				END CASE 
			AFTER FIELD job1_code 
				IF pr1_activity.job_code IS NULL THEN 
					#ERROR "Job Code must be entered"
					LET msgresp = kandoomsg("J", 9508, " ") 
					NEXT FIELD job1_code 
				END IF 
				SELECT * INTO pr_job.* 
				FROM job 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND job.job_code = pr1_activity.job_code 
				IF status = notfound THEN 
					#ERROR " Job NOT found, use window FOR help"
					LET msgresp = kandoomsg("J", 9558, " ") 
					NEXT FIELD job1_code 
				ELSE 
					IF pr_job.locked_ind = 0 THEN 
						#error - Master job NOT allowed
						LET msgresp = kandoomsg("J", 9594, " ") 
						NEXT FIELD job1_code 
					END IF 
				END IF 
				NEXT FIELD var1_code 
			AFTER FIELD job2_code 
				IF pr2_activity.job_code IS NULL THEN 
					#ERROR "Job Code must be entered"
					LET msgresp = kandoomsg("J", 9508, " ") 
					NEXT FIELD job2_code 
				END IF 
				SELECT * INTO pr_job.* 
				FROM job 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND job.job_code = pr2_activity.job_code 
				IF status = notfound THEN 
					#ERROR " Job NOT found, use window FOR help"
					LET msgresp = kandoomsg("J", 9558, " ") 
					NEXT FIELD job2_code 
				ELSE 
					IF pr_job.locked_ind = 0 THEN 
						#error - Master job NOT allowed
						LET msgresp = kandoomsg("J", 9594, " ") 
						NEXT FIELD job2_code 
					END IF 
				END IF 
				NEXT FIELD var2_code 
			AFTER FIELD var1_code 
				IF pr1_activity.var_code IS NULL 
				OR pr1_activity.var_code = 0 THEN 
					LET pr1_activity.var_code = 0 
					DISPLAY pr1_activity.var_code TO var1_code 

					NEXT FIELD activity1_code 
				ELSE 
					SELECT var_code 
					FROM jobvars 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND job_code = pr1_activity.job_code 
					AND var_code = pr1_activity.var_code 
					IF status = notfound THEN 
						#ERROR " Variation NOT found, use window FOR help"
						LET msgresp = kandoomsg("J", 9510, " ") 
						NEXT FIELD job1_code 
					ELSE 
						NEXT FIELD activity1_code 
					END IF 
				END IF 
			AFTER FIELD var2_code 
				IF pr2_activity.var_code IS NULL 
				OR pr2_activity.var_code = 0 THEN 
					LET pr2_activity.var_code = 0 
					DISPLAY pr2_activity.var_code TO var2_code 

					NEXT FIELD activity2_code 
				ELSE 
					SELECT var_code 
					FROM jobvars 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND job_code = pr2_activity.job_code 
					AND var_code = pr2_activity.var_code 
					IF status = notfound THEN 
						#ERROR " Variation NOT found, use window FOR help"
						LET msgresp = kandoomsg("J", 9510, " ") 
						NEXT FIELD job2_code 
					ELSE 
						NEXT FIELD activity2_code 
					END IF 
				END IF 
			AFTER FIELD activity1_code 
				IF pr1_activity.activity_code IS NULL THEN 
					#ERROR " Activity Code must be entered"
					LET msgresp = kandoomsg("J", 9511, " ") 
					NEXT FIELD activity1_code 
				END IF 
				SELECT * INTO pr1_activity.* 
				FROM activity 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND job_code = pr1_activity.job_code 
				AND var_code = pr1_activity.var_code 
				AND activity_code = pr1_activity.activity_code 
				IF status = notfound THEN 
					#ERROR " Activity NOT found, use window FOR help"
					LET msgresp = kandoomsg("J", 9512, " ") 
					NEXT FIELD activity1_code 
				ELSE 
					DISPLAY pr1_activity.act_cost_amt TO act1_cost_amt 

					DISPLAY pr1_activity.act_cost_qty TO act1_cost_qty 

					DISPLAY pr1_activity.post_revenue_amt TO act1_charge_amt 

				END IF 
			AFTER FIELD activity2_code 
				IF pr2_activity.activity_code IS NULL THEN 
					#ERROR " Activity Code must be entered"
					LET msgresp = kandoomsg("J", 9511, " ") 
					NEXT FIELD activity2_code 
				END IF 
				IF pr2_activity.job_code = pr1_activity.job_code 
				AND pr2_activity.activity_code = pr1_activity.activity_code 
				AND pr2_activity.var_code = pr1_activity.var_code THEN 
					#ERROR " The TO job, activity AND var codes must be different TO the FROM"
					LET msgresp = kandoomsg("J", 9595, " ") 
					NEXT FIELD job2_code 
				END IF 
				SELECT * INTO pr2_activity.* 
				FROM activity 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND job_code = pr2_activity.job_code 
				AND var_code = pr2_activity.var_code 
				AND activity_code = pr2_activity.activity_code 
				IF status = notfound THEN 
					#ERROR " Activity NOT found, use window FOR help"
					LET msgresp = kandoomsg("J", 9512, " ") 
					NEXT FIELD activity2_code 
				ELSE 
					DISPLAY pr2_activity.act_cost_amt TO act2_cost_amt 

					DISPLAY pr2_activity.act_cost_qty TO act2_cost_qty 

					DISPLAY pr2_activity.post_revenue_amt TO act2_charge_amt 

				END IF 
			AFTER INPUT 
				IF NOT int_flag AND NOT quit_flag THEN 
					IF pr1_activity.job_code IS NULL THEN 
						#ERROR "Job Code must be entered"
						LET msgresp = kandoomsg("J", 9508, " ") 
						NEXT FIELD job1_code 
					END IF 
					IF pr1_activity.var_code IS NULL 
					OR pr1_activity.var_code = 0 THEN 
						LET pr1_activity.var_code = 0 
					END IF 
					IF pr1_activity.activity_code IS NULL THEN 
						#ERROR " Activity Code must be entered"
						LET msgresp = kandoomsg("J", 9511, " ") 
						NEXT FIELD activity1_code 
					END IF 
					IF pr2_activity.job_code IS NULL THEN 
						#ERROR "Job Code must be entered"
						LET msgresp = kandoomsg("J", 9508, " ") 
						NEXT FIELD job2_code 
					END IF 
					IF pr2_activity.var_code IS NULL 
					OR pr2_activity.var_code = 0 THEN 
						LET pr2_activity.var_code = 0 
					END IF 
					IF pr2_activity.activity_code IS NULL THEN 
						#ERROR " Activity Code must be entered"
						LET msgresp = kandoomsg("J", 9511, " ") 
						NEXT FIELD activity2_code 
					END IF 
					IF pr_adj_cost_amt IS NULL THEN 
						LET pr_adj_cost_amt = 0 
					END IF 
					LET pr_act1_cost_amt = pr1_activity.act_cost_amt - pr_adj_cost_amt 
					LET pr_act2_cost_amt = pr2_activity.act_cost_amt + pr_adj_cost_amt 
					DISPLAY pr_act1_cost_amt TO act1_cost_amt 

					DISPLAY pr_act2_cost_amt TO act2_cost_amt 

					IF pr_adj_cost_qty IS NULL THEN 
						LET pr_adj_cost_qty = 0 
					END IF 
					LET pr_act1_cost_qty = pr1_activity.act_cost_qty - pr_adj_cost_qty 
					LET pr_act2_cost_qty = pr2_activity.act_cost_qty + pr_adj_cost_qty 
					DISPLAY pr_act1_cost_qty TO act1_cost_qty 

					DISPLAY pr_act2_cost_qty TO act2_cost_qty 

					IF pr_adj_charge_amt IS NULL THEN 
						LET pr_adj_charge_amt = 0 
					END IF 
					LET pr_act1_charge_amt = pr1_activity.post_revenue_amt - 
					pr_adj_charge_amt 
					LET pr_act2_charge_amt = pr2_activity.post_revenue_amt + 
					pr_adj_charge_amt 
					DISPLAY pr_act1_charge_amt TO act1_charge_amt 

					DISPLAY pr_act2_charge_amt TO act2_charge_amt 

					CALL valid_period(glob_rec_kandoouser.cmpy_code, pr_jobledger.year_num, 
					pr_jobledger.period_num , "JM") 
					RETURNING pr_jobledger.year_num, 
					pr_jobledger.period_num, 
					no_good 
					IF no_good THEN 
						NEXT FIELD trans_date 
					END IF 
				END IF 
			ON KEY (control-w) 
				CALL kandoohelp("") 
		END INPUT 
		IF pr_adj_cost_amt IS NULL THEN 
			LET pr_adj_cost_amt = 0 
		END IF 
		IF pr_adj_cost_qty IS NULL THEN 
			LET pr_adj_cost_qty = 0 
		END IF 
		IF pr_adj_charge_amt IS NULL THEN 
			LET pr_adj_charge_amt = 0 
		END IF 
		IF quit_flag 
		OR int_flag THEN 
			RETURN 
		END IF 
		#prompt " OK TO proceed (y/n) ? " FOR CHAR ans
		LET msgresp = kandoomsg("J", 8509, " ") 
		LET ans = upshift(msgresp) 
		IF ans = "Y" THEN 
			EXIT WHILE 
		END IF 
	END WHILE 
END FUNCTION 


FUNCTION ins_rows() 
	DEFINE 
	pi_jobledger RECORD LIKE jobledger.* 

	GOTO bypass 

	LABEL recovery: 
	LET try_again = error_recover(err_message, status) 
	IF try_again != "Y" THEN 
		EXIT program 
	END IF 

	LABEL bypass: 

	WHENEVER ERROR GOTO recovery 
	BEGIN WORK 
		LET err_message = "Updating jmparms" 
		DECLARE jm_p_c CURSOR FOR 
		SELECT * INTO pr_jmparms.* 
		FROM jmparms 
		WHERE jmparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND jmparms.key_code = "1" 
		FOR UPDATE 
		OPEN jm_p_c 
		FETCH jm_p_c 
		IF status = notfound THEN 
			#ERROR "Someone's messing with Job Management parameters"
			#prompt " Note error AND REPORT" FOR CHAR ans
			LET msgresp = kandoomsg("G", 5010, " ") 
			EXIT program 
		END IF 
		LET pr_jmparms.adj_num = pr_jmparms.adj_num + 1 
		UPDATE jmparms 
		SET adj_num = pr_jmparms.adj_num 
		WHERE CURRENT OF jm_p_c 
		LET err_message = "Updating Activity" 
		DECLARE act1_c CURSOR FOR 
		SELECT * INTO pr_activity.* 
		FROM activity 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND job_code = pr1_activity.job_code 
		AND var_code = pr1_activity.var_code 
		AND activity_code = pr1_activity.activity_code 
		FOR UPDATE 
		OPEN act1_c 
		FETCH act1_c 
		IF status = notfound THEN 
			LET err_message = "Activity NOT found" 
			GOTO recovery 
		END IF 
		LET err_message = "Inserting INTO the job ledger" 
		LET pr_adj1_cost_amt = 0 - pr_adj_cost_amt + 0 
		LET pr_adj1_cost_qty = 0 - pr_adj_cost_qty + 0 
		LET pr_adj1_charge_amt = 0 - pr_adj_charge_amt + 0 
		LET pr_activity.seq_num = pr_activity.seq_num + 1 
		LET pr_jobledger.allocation_ind = "A" 
		INITIALIZE pi_jobledger TO NULL 
		LET pi_jobledger.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET pi_jobledger.trans_date = pr_jobledger.trans_date 
		LET pi_jobledger.year_num = pr_jobledger.year_num 
		LET pi_jobledger.period_num = pr_jobledger.period_num 
		LET pi_jobledger.job_code = pr1_activity.job_code 
		LET pi_jobledger.var_code = pr1_activity.var_code 
		LET pi_jobledger.activity_code = pr1_activity.activity_code 
		LET pi_jobledger.seq_num = pr_activity.seq_num 
		LET pi_jobledger.trans_type_ind = "AD" 
		LET pi_jobledger.trans_source_num = pr_jmparms.adj_num 
		LET pi_jobledger.trans_source_text = "Adjust" 
		LET pi_jobledger.trans_amt = pr_adj1_cost_amt 
		LET pi_jobledger.trans_qty = pr_adj1_cost_qty 
		LET pi_jobledger.charge_amt = pr_adj1_charge_amt 
		LET pi_jobledger.posted_flag = "N" 
		LET pi_jobledger.desc_text = pr_jobledger.desc_text 
		LET pi_jobledger.allocation_ind = pr_jobledger.allocation_ind 
		LET pi_jobledger.entry_date = today 
		LET pi_jobledger.entry_code = glob_rec_kandoouser.sign_on_code 
		LET err_message = "J24 - Insert Jobledger 1" 
		INSERT INTO jobledger VALUES (pi_jobledger.*) 
		#INSERT INTO jobledger VALUES(glob_rec_kandoouser.cmpy_code, pr_jobledger.trans_date,
		#pr_jobledger.year_num , pr_jobledger.period_num,
		#pr1_activity.job_code , pr1_activity.var_code,
		#pr1_activity.activity_code , pr_activity.seq_num,
		#"AD" , pr_jmparms.adj_num, "Adjust",
		#pr_adj1_cost_amt , pr_adj1_cost_qty,
		#pr_adj1_charge_amt , "N", pr_jobledger.desc_text,
		#pr_jobledger.allocation_ind )
		CALL set_start(pr1_activity.job_code, pr_jobledger.trans_date) 
		IF pr_activity.act_start_date IS NULL 
		OR pr_activity.act_start_date > pr_jobledger.trans_date THEN 
			UPDATE activity 
			SET act_start_date = pr_jobledger.trans_date, 
			act_cost_amt = pr_act1_cost_amt, 
			act_cost_qty = pr_act1_cost_qty, 
			post_revenue_amt = pr_act1_charge_amt , 
			seq_num = pr_activity.seq_num 
			WHERE CURRENT OF act1_c 
		ELSE 
			UPDATE activity 
			SET act_cost_amt = pr_act1_cost_amt, 
			act_cost_qty = pr_act1_cost_qty, 
			post_revenue_amt = pr_act1_charge_amt , 
			seq_num = pr_activity.seq_num 
			WHERE CURRENT OF act1_c 
		END IF 
		DECLARE act2_c CURSOR FOR 
		SELECT * INTO pr_activity.* 
		FROM activity 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND job_code = pr2_activity.job_code 
		AND var_code = pr2_activity.var_code 
		AND activity_code = pr2_activity.activity_code 
		FOR UPDATE 
		OPEN act2_c 
		FETCH act2_c 
		IF status = notfound THEN 
			LET err_message = "Activity NOT found" 
			GOTO recovery 
		END IF 
		LET pr_activity.seq_num = pr_activity.seq_num + 1 
		INITIALIZE pi_jobledger TO NULL 
		LET pi_jobledger.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET pi_jobledger.trans_date = pr_jobledger.trans_date 
		LET pi_jobledger.year_num = pr_jobledger.year_num 
		LET pi_jobledger.period_num = pr_jobledger.period_num 
		LET pi_jobledger.job_code = pr2_activity.job_code 
		LET pi_jobledger.var_code = pr2_activity.var_code 
		LET pi_jobledger.activity_code = pr2_activity.activity_code 
		LET pi_jobledger.seq_num = pr_activity.seq_num 
		LET pi_jobledger.trans_type_ind = "AD" 
		LET pi_jobledger.trans_source_num = pr_jmparms.adj_num 
		LET pi_jobledger.trans_source_text = "Adjust" 
		LET pi_jobledger.trans_amt = pr_adj_cost_amt 
		LET pi_jobledger.trans_qty = pr_adj_cost_qty 
		LET pi_jobledger.charge_amt = pr_adj_charge_amt 
		LET pi_jobledger.posted_flag = "N" 
		LET pi_jobledger.desc_text = pr_jobledger.desc_text 
		LET pi_jobledger.allocation_ind = pr_jobledger.allocation_ind 
		LET pi_jobledger.entry_date = today 
		LET pi_jobledger.entry_code = glob_rec_kandoouser.sign_on_code 
		LET err_message = "J24 - Insert Jobledger 1" 
		INSERT INTO jobledger VALUES (pi_jobledger.*) 
		#INSERT INTO jobledger VALUES(glob_rec_kandoouser.cmpy_code, pr_jobledger.trans_date,
		#pr_jobledger.year_num , pr_jobledger.period_num
		#,  pr2_activity.job_code, pr2_activity.var_code
		#,  pr2_activity.activity_code,
		#pr_activity.seq_num , "AD", pr_jmparms.adj_num,
		#"Adjust", pr_adj_cost_amt, pr_adj_cost_qty,
		#pr_adj_charge_amt, "N",
		#pr_jobledger.desc_text ,
		#pr_jobledger.allocation_ind)
		CALL set_start(pr_activity.job_code, pr_jobledger.trans_date) 
		IF pr_activity.act_start_date IS NULL 
		OR pr_activity.act_start_date > pr_jobledger.trans_date THEN 
			UPDATE activity 
			SET act_start_date = pr_jobledger.trans_date, 
			act_cost_amt = pr_act2_cost_amt, 
			act_cost_qty = pr_act2_cost_qty , 
			post_revenue_amt = pr_act2_charge_amt, 
			seq_num = pr_activity.seq_num 
			WHERE CURRENT OF act2_c 
		ELSE 
			UPDATE activity 
			SET act_cost_amt = pr_act2_cost_amt, 
			act_cost_qty = pr_act2_cost_qty, 
			post_revenue_amt = pr_act2_charge_amt , 
			seq_num = pr_activity.seq_num 
			WHERE CURRENT OF act2_c 
		END IF 
	COMMIT WORK 

	WHENEVER ERROR stop 
	LET msgresp = kandoomsg("J", 8510, pr_jmparms.adj_num) 
	LET ans = upshift(msgresp) 
	IF ans <> "Y" THEN 
		EXIT program 
	END IF 
END FUNCTION 
