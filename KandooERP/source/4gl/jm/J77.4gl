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
# \brief module J77, Budgets AT Resource level

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "J_JM_GLOBALS.4gl" 
GLOBALS "J7_GLOBALS.4gl" 
GLOBALS "J77_GLOBALS.4gl" 

DEFINE 
mv_multiadd, 
mv_parms_flag SMALLINT, 
mv_sys_resbdgt_flg char, 
cont_flag CHAR 


MAIN 
	#Initial UI Init
	CALL setModuleId("J77") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	CALL user_security(glob_rec_kandoouser.cmpy_code, glob_rec_kandoouser.sign_on_code) 
	RETURNING glob_rec_kandoouser.acct_mask_code, 
	pv_user_scan_code 
	LET mv_sys_resbdgt_flg = get_kandoooption_feature_state("JM", "W1") 
	OPEN WINDOW j197w with FORM "J197" -- alch kd-747 
	CALL winDecoration_j("J197") -- alch kd-747 
	INITIALIZE pr_resbdgt TO NULL 
	LET mv_parms_flag = false 
	LET cont_flag = "Y" 
	WHILE cont_flag = "Y" 
		INITIALIZE pr_resbdgt.res_code, 
		pr_resbdgt.est_cost_amt, 
		pr_resbdgt.est_bill_amt, 
		pr_resbdgt.bdgt_cost_amt, 
		pr_resbdgt.bdgt_bill_amt, 
		pr_resbdgt.est_cost_qty, 
		pr_resbdgt.est_bill_qty, 
		pr_resbdgt.bdgt_cost_qty, 
		pr_resbdgt.bdgt_bill_qty TO NULL 
		IF num_args() > 0 THEN 
			CALL fgl_winmessage("this needs fixing","huho-needs fixing","info") 
			# LET pv_cmpy_code = arg_val(1)
			LET pr_resbdgt.job_code = arg_val(2) 
			LET pr_resbdgt.var_code = arg_val(3) 
			LET pr_resbdgt.activity_code = arg_val(4) 
			LET mv_parms_flag = true 
		ELSE 
			LET pr_resbdgt.job_code = NULL 
			LET pr_resbdgt.var_code = 0 
			LET pr_resbdgt.activity_code = NULL 
		END IF 
		# MESSAGE "Enter Details  - ESC TO continue -DEL TO Exit"
		#    attribute (yellow)
		LET msgresp = kandoomsg("J", 1420, " ") 
		WHILE add_resbdgt() 
			INITIALIZE pr_resbdgt.res_code, 
			pr_resbdgt.est_cost_amt, 
			pr_resbdgt.est_bill_amt, 
			pr_resbdgt.bdgt_cost_amt, 
			pr_resbdgt.bdgt_bill_amt, 
			pr_resbdgt.est_cost_qty, 
			pr_resbdgt.est_bill_qty, 
			pr_resbdgt.bdgt_cost_qty, 
			pr_resbdgt.bdgt_bill_qty TO NULL 
		END WHILE 
		LET cont_flag = kandoomsg("J", 1422, " ") 
		LET cont_flag = upshift(cont_flag) 
	END WHILE 
	CLOSE WINDOW j197w 
	LET int_flag = false 
	LET quit_flag = false 
END MAIN 


FUNCTION add_resbdgt() 
	DEFINE 
	fv_count INTEGER, 
	fr_customer RECORD LIKE customer.*, 
	fr_job RECORD LIKE job.*, 
	fv_status SMALLINT, 
	fv_desc_text LIKE jmresource.desc_text, 
	pr_msg_text CHAR(60), 
	fv_unit_code LIKE jmresource.unit_code 

	CLEAR FORM 
	LET fv_status = true 
	IF mv_parms_flag THEN 
		SELECT job.title_text, 
		customer.cust_code, 
		customer.name_text INTO fr_job.title_text, 
		fr_customer.cust_code, 
		fr_customer.name_text 
		FROM job, customer 
		WHERE job.cmpy_code = pv_cmpy_code 
		AND job.job_code = pr_resbdgt.job_code 
		AND customer.cmpy_code = pv_cmpy_code 
		AND customer.cust_code = job.cust_code 
		AND (job.acct_code matches pv_user_scan_code 
		OR job.locked_ind <= "1") 
		IF status = notfound THEN 
			#ERROR "No such Job Code "
			LET msgresp = kandoomsg("J", 9558, " ") 
			SLEEP 3 
			RETURN false 
		ELSE 
			DISPLAY BY NAME pr_resbdgt.job_code, 
			fr_job.title_text, 
			fr_customer.cust_code, 
			fr_customer.name_text 

		END IF 
	END IF 
	IF pr_resbdgt.var_code IS NULL THEN 
		LET pr_resbdgt.var_code = 0 
	END IF 
	IF pr_resbdgt.est_cost_amt IS NULL THEN 
		LET pr_resbdgt.est_cost_amt = 0.0 
	END IF 
	IF pr_resbdgt.est_bill_amt IS NULL THEN 
		LET pr_resbdgt.est_bill_amt = 0.0 
	END IF 
	IF pr_resbdgt.bdgt_bill_amt IS NULL THEN 
		LET pr_resbdgt.bdgt_bill_amt = 0.0 
	END IF 
	IF pr_resbdgt.bdgt_cost_amt IS NULL THEN 
		LET pr_resbdgt.bdgt_cost_amt = 0.0 
	END IF 
	IF pr_resbdgt.est_cost_qty IS NULL THEN 
		LET pr_resbdgt.est_cost_qty = 0.0 
	END IF 
	IF pr_resbdgt.est_bill_qty IS NULL THEN 
		LET pr_resbdgt.est_bill_qty = 0.0 
	END IF 
	IF pr_resbdgt.bdgt_bill_qty IS NULL THEN 
		LET pr_resbdgt.bdgt_bill_qty = 0.0 
	END IF 
	IF pr_resbdgt.bdgt_cost_qty IS NULL THEN 
		LET pr_resbdgt.bdgt_cost_qty = 0.0 
	END IF 
	INPUT BY NAME pr_resbdgt.job_code, 
	pr_resbdgt.var_code, 
	pr_resbdgt.activity_code, 
	pr_resbdgt.res_code, 
	pr_resbdgt.est_cost_amt, 
	pr_resbdgt.est_bill_amt, 
	pr_resbdgt.bdgt_cost_amt, 
	pr_resbdgt.bdgt_bill_amt, 
	pr_resbdgt.est_cost_qty, 
	pr_resbdgt.est_bill_qty, 
	pr_resbdgt.bdgt_cost_qty, 
	pr_resbdgt.bdgt_bill_qty WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","J77","input-pr_resbdgt-1") -- alch kd-506 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE FIELD job_code 
			IF NOT pr_resbdgt.job_code IS NULL 
			AND NOT pr_resbdgt.var_code IS NULL 
			AND NOT pr_resbdgt.activity_code IS NULL THEN 
				SELECT job.title_text, 
				customer.cust_code, 
				customer.name_text INTO fr_job.title_text, 
				fr_customer.cust_code, 
				fr_customer.name_text 
				FROM job, customer 
				WHERE job.cmpy_code = pv_cmpy_code 
				AND job.job_code = pr_resbdgt.job_code 
				AND customer.cmpy_code = pv_cmpy_code 
				AND customer.cust_code = job.cust_code 
				AND (job.acct_code matches pv_user_scan_code 
				OR job.locked_ind <= "1") 
				IF status = notfound THEN 
					#ERROR "No such Job Code.  ", "Try Window. "
					LET msgresp = kandoomsg("J", 9558, " ") 
					INITIALIZE pr_resbdgt, 
					pr_activity TO NULL 
					CLEAR FORM 
					NEXT FIELD job_code 
				ELSE 
					DISPLAY BY NAME pr_resbdgt.job_code, 
					fr_job.title_text, 
					fr_customer.cust_code, 
					fr_customer.name_text, 
					pr_resbdgt.var_code 

				END IF 
				SELECT * INTO pr_activity.* 
				FROM activity 
				WHERE cmpy_code = pv_cmpy_code 
				AND activity_code = pr_resbdgt.activity_code 
				AND job_code = pr_resbdgt.job_code 
				AND var_code = pr_resbdgt.var_code 
				IF status = notfound THEN 
					#ERROR "Activity code must exist FOR this job AND variation.  "
					LET msgresp = kandoomsg("J", 9512, " ") 
					INITIALIZE pr_resbdgt, 
					pr_activity TO NULL 
					NEXT FIELD job_code 
				END IF 
				DISPLAY pr_resbdgt.activity_code, 
				pr_activity.title_text TO activity_code, 
				activity_desc 

				NEXT FIELD res_code 
			END IF 
		AFTER FIELD job_code 
			IF pr_resbdgt.job_code IS NULL THEN 
				#ERROR "A Job Code must be entered.  Try window.  "
				LET msgresp = kandoomsg("J", 9508, " ") 
				NEXT FIELD job_code 
			END IF 
			SELECT job.title_text, 
			customer.cust_code, 
			customer.name_text INTO fr_job.title_text, 
			fr_customer.cust_code, 
			fr_customer.name_text 
			FROM job, customer 
			WHERE job.cmpy_code = pv_cmpy_code 
			AND job.job_code = pr_resbdgt.job_code 
			AND customer.cmpy_code = pv_cmpy_code 
			AND customer.cust_code = job.cust_code 
			AND (job.acct_code matches pv_user_scan_code 
			OR job.locked_ind <= "1") 
			IF status = notfound THEN 
				#ERROR "No such Job Code.   Try window. "
				LET msgresp = kandoomsg("J", 9558, " ") 
				NEXT FIELD job_code 
			END IF 
			DISPLAY BY NAME pr_resbdgt.job_code, 
			fr_job.title_text, 
			fr_customer.cust_code, 
			fr_customer.name_text 

		AFTER FIELD var_code 
			IF pr_resbdgt.var_code IS NULL THEN 
				LET pr_resbdgt.var_code = 0 
				DISPLAY BY NAME pr_resbdgt.var_code 
			END IF 
			IF NOT pr_resbdgt.var_code = 0 THEN 
				SELECT count(*)INTO fv_count 
				FROM jobvars 
				WHERE cmpy_code = pv_cmpy_code 
				AND job_code = pr_resbdgt.job_code 
				AND var_code = pr_resbdgt.var_code 
				IF status = notfound 
				OR fv_count = 0 THEN 
					#ERROR "No such variation FOR Job Code.  "
					LET msgresp = kandoomsg("J", 9510, " ") 
					NEXT FIELD var_code 
				END IF 
			END IF 
			DISPLAY BY NAME pr_resbdgt.var_code 

		AFTER FIELD activity_code 
			IF fgl_lastkey() = fgl_keyval("left") 
			OR fgl_lastkey() = fgl_keyval("up") THEN 
				NEXT FIELD previous 
			END IF 
			IF pr_resbdgt.activity_code IS NULL THEN 
				#ERROR "Activity code must be entered.  Try window."
				LET msgresp = kandoomsg("J", 9511, " ") 
				NEXT FIELD activity_code 
			END IF 
			SELECT * INTO pr_activity.* 
			FROM activity 
			WHERE cmpy_code = pv_cmpy_code 
			AND activity_code = pr_resbdgt.activity_code 
			AND job_code = pr_resbdgt.job_code 
			AND var_code = pr_resbdgt.var_code 
			IF status = notfound THEN 
				#ERROR "Activity code must exist FOR this job AND variation.  ",
				#      "Try window.  "
				LET msgresp = kandoomsg("J", 9512, " ") 
				NEXT FIELD activity_code 
			END IF 
			DISPLAY pr_resbdgt.activity_code, 
			pr_activity.title_text 
			TO activity_code, 
			activity_desc 

		AFTER FIELD res_code 
			IF fgl_lastkey() = fgl_keyval("left") 
			OR fgl_lastkey() = fgl_keyval("up") THEN 
				NEXT FIELD previous 
			END IF 
			IF pr_resbdgt.res_code IS NULL THEN 
				IF mv_parms_flag THEN 
					INITIALIZE pr_resbdgt.activity_code TO NULL 
					# MESSAGE "Enter Criteria - ESC TO continue -DEL TO Exit"
					#    attribute (yellow)
					LET msgresp = kandoomsg("U", 1001, " ") 
					NEXT FIELD activity_code 
				ELSE 
					#ERROR "A Resource Code must be entered.  Try window.  "
					LET msgresp = kandoomsg("J", 9514, " ") 
					NEXT FIELD res_code 
				END IF 
			END IF 
			SELECT desc_text, unit_code INTO fv_desc_text, fv_unit_code 
			FROM jmresource 
			WHERE res_code = pr_resbdgt.res_code 
			AND cmpy_code = pv_cmpy_code 
			IF status = notfound THEN 
				#ERROR "Resource Code must exist.  Try window.  "
				LET msgresp = kandoomsg("J", 9515, " ") 
				NEXT FIELD res_code 
			END IF 
			LET fv_count = 0 
			SELECT count(*)INTO fv_count 
			FROM resbdgt 
			WHERE cmpy_code = pv_cmpy_code 
			AND job_code = pr_resbdgt.job_code 
			AND var_code = pr_resbdgt.var_code 
			AND res_code = pr_resbdgt.res_code 
			AND activity_code = pr_resbdgt.activity_code 
			IF status = notfound 
			OR fv_count > 0 THEN 
				#ERROR "A resource budget already exists FOR this resource.  ",
				#      "Try Again"
				LET msgresp = kandoomsg("J", 9576, " ") 
				NEXT FIELD res_code 
			END IF 
			DISPLAY pr_resbdgt.res_code, 
			fv_desc_text , 
			fv_unit_code 
			TO res_code, 
			desc_text, 
			unit_code 

			IF fv_unit_code != pr_activity.unit_code 
			OR (fv_unit_code IS NULL AND pr_activity.unit_code IS NOT null) 
			OR (fv_unit_code IS NOT NULL AND pr_activity.unit_code IS null) THEN 
				LET msgresp = kandoomsg("J",9652,0) 
				#9652 Quantity figures will NOT be updated on the Activity.
			END IF 
		AFTER FIELD est_cost_amt 
			LET pr_resbdgt.bdgt_cost_amt = pr_resbdgt.est_cost_amt 
			DISPLAY BY NAME pr_resbdgt.bdgt_cost_amt 

		AFTER FIELD est_bill_amt 
			LET pr_resbdgt.bdgt_bill_amt = pr_resbdgt.est_bill_amt 
			DISPLAY BY NAME pr_resbdgt.bdgt_bill_amt 

		AFTER FIELD est_cost_qty 
			LET pr_resbdgt.bdgt_cost_qty = pr_resbdgt.est_cost_qty 
			DISPLAY BY NAME pr_resbdgt.bdgt_cost_qty 

		AFTER FIELD est_bill_qty 
			LET pr_resbdgt.bdgt_bill_qty = pr_resbdgt.est_bill_qty 
			DISPLAY BY NAME pr_resbdgt.bdgt_bill_qty 

		ON KEY (control-b) 
			CASE 
				WHEN infield(job_code) 
					LET pr_resbdgt.job_code = showujobs(pv_cmpy_code, 
					glob_rec_kandoouser.acct_mask_code ) 
					SELECT job.title_text, 
					customer.cust_code, 
					customer.name_text INTO fr_job.title_text, 
					fr_customer.cust_code, 
					fr_customer.name_text 
					FROM job, 
					customer 
					WHERE job.cmpy_code = pv_cmpy_code 
					AND job_code = pr_resbdgt.job_code 
					AND customer.cmpy_code = pv_cmpy_code 
					AND customer.cust_code = job.cust_code 
					AND (job.acct_code matches pv_user_scan_code 
					OR job.locked_ind <= "1") 
					IF status = notfound THEN 
						#ERROR "No such Job Code.   Try window. "
						LET msgresp = kandoomsg("J", 9509, " ") 
					END IF 
					DISPLAY BY NAME pr_resbdgt.job_code, 
					fr_job.title_text, 
					fr_customer.cust_code, 
					fr_customer.name_text 

				WHEN infield(var_code) 
					LET pr_resbdgt.var_code = show_jobvars(pv_cmpy_code, 
					pr_resbdgt.job_code ) 
					DISPLAY BY NAME pr_resbdgt.var_code 

				WHEN infield(activity_code) 
					LET pr_resbdgt.activity_code = show_activity(pv_cmpy_code, 
					pr_resbdgt.job_code , 
					pr_resbdgt.var_code ) 
					DISPLAY BY NAME pr_resbdgt.activity_code 

				WHEN infield(res_code) 
					LET pr_resbdgt.res_code = show_res(pv_cmpy_code) 
					DISPLAY BY NAME pr_resbdgt.res_code 

			END CASE 
		AFTER INPUT 
			IF int_flag 
			OR quit_flag THEN 
				LET fv_status = false 
				EXIT INPUT 
			END IF 
			#Check FOR NULL inputs
			IF pr_resbdgt.job_code IS NULL THEN 
				NEXT FIELD job_code 
			END IF 
			IF pr_resbdgt.var_code IS NULL THEN 
				NEXT FIELD var_code 
			END IF 
			IF pr_resbdgt.activity_code IS NULL THEN 
				NEXT FIELD activity_code 
			END IF 
			SELECT job.title_text, 
			customer.cust_code, 
			customer.name_text INTO fr_job.title_text, 
			fr_customer.cust_code, 
			fr_customer.name_text 
			FROM job, customer 
			WHERE job.cmpy_code = pv_cmpy_code 
			AND job.job_code = pr_resbdgt.job_code 
			AND customer.cmpy_code = pv_cmpy_code 
			AND customer.cust_code = job.cust_code 
			AND (job.acct_code matches pv_user_scan_code 
			OR job.locked_ind <= "1") 
			IF status = notfound THEN 
				#ERROR "No such Job Code.   Try window. "
				LET msgresp = kandoomsg("J", 9558, " ") 
				NEXT FIELD job_code 
			END IF 
			DISPLAY BY NAME pr_resbdgt.job_code, 
			fr_job.title_text, 
			fr_customer.cust_code, 
			fr_customer.name_text 

			IF NOT pr_resbdgt.var_code = 0 THEN 
				SELECT count(*)INTO fv_count 
				FROM jobvars 
				WHERE cmpy_code = pv_cmpy_code 
				AND job_code = pr_resbdgt.job_code 
				AND var_code = pr_resbdgt.var_code 
				IF status = notfound 
				OR fv_count = 0 THEN 
					#ERROR "No such variation FOR Job Code.  "
					LET msgresp = kandoomsg("J", 9510, " ") 
					NEXT FIELD var_code 
				END IF 
			END IF 
			SELECT * INTO pr_activity.* 
			FROM activity 
			WHERE cmpy_code = pv_cmpy_code 
			AND activity_code = pr_resbdgt.activity_code 
			AND job_code = pr_resbdgt.job_code 
			AND var_code = pr_resbdgt.var_code 
			IF status = notfound THEN 
				#ERROR "Activity code must exist FOR this job AND variation.  ",
				#      "Try window.  "
				LET msgresp = kandoomsg("J", 9512, " ") 
				NEXT FIELD activity_code 
			END IF 
			DISPLAY pr_resbdgt.activity_code, 
			pr_activity.title_text TO activity_code, 
			activity_desc 

			IF pr_resbdgt.res_code IS NULL THEN 
				IF mv_parms_flag THEN 
					INITIALIZE pr_resbdgt.activity_code TO NULL 
					# MESSAGE "Enter Criteria - ESC TO continue -DEL TO Exit"
					#    attribute (yellow)
					LET msgresp = kandoomsg("U", 1001, " ") 
					NEXT FIELD activity_code 
				ELSE 
					#ERROR "A Resource Code must be entered.  Try window.  "
					LET msgresp = kandoomsg("J", 9514, " ") 
					NEXT FIELD res_code 
				END IF 
			END IF 
			SELECT desc_text INTO fv_desc_text 
			FROM jmresource 
			WHERE res_code = pr_resbdgt.res_code 
			AND cmpy_code = pv_cmpy_code 
			IF status = notfound THEN 
				#ERROR "Resource Code must exist.  Try window.  "
				LET msgresp = kandoomsg("J", 9515, " ") 
				NEXT FIELD res_code 
			END IF 
			LET fv_count = 0 
			SELECT count(*)INTO fv_count 
			FROM resbdgt 
			WHERE cmpy_code = pv_cmpy_code 
			AND job_code = pr_resbdgt.job_code 
			AND var_code = pr_resbdgt.var_code 
			AND res_code = pr_resbdgt.res_code 
			AND activity_code = pr_resbdgt.activity_code 
			IF status = notfound 
			OR fv_count > 0 THEN 
				#ERROR "A resource budget already exists FOR this resource.  ",
				#      "Try Again"
				LET msgresp = kandoomsg("J", 9576, " ") 
				NEXT FIELD res_code 
			END IF 
			DISPLAY pr_resbdgt.res_code, 
			fv_desc_text TO res_code, 
			desc_text 

			LET pr_resbdgt.cmpy_code = pv_cmpy_code 
			LET pr_resbdgt.baltocomp_amt = 0 
			LET pr_resbdgt.est_comp_per = 0 
			BEGIN WORK 
				DELETE 
				FROM resbdgt 
				WHERE cmpy_code = pv_cmpy_code 
				AND job_code = pr_resbdgt.job_code 
				AND var_code = pr_resbdgt.var_code 
				AND activity_code = pr_resbdgt.activity_code 
				AND res_code = pr_resbdgt.res_code 
				INSERT INTO resbdgt VALUES (pr_resbdgt.*) 
				IF status THEN 
					#ERROR "Unsuccessful Addition Insert resbdget failed.  Stat:",STATUS
					LET msgresp = kandoomsg("J", 9577, status) 
					ROLLBACK WORK 
					LET fv_status = false 
					EXIT INPUT 
				ELSE 
					IF mv_sys_resbdgt_flg = "Y" THEN 
						SELECT sum(est_cost_amt), 
						sum(est_bill_amt), 
						sum(bdgt_cost_amt), 
						sum(bdgt_bill_amt) 
						INTO pr_activity.est_cost_amt, 
						pr_activity.est_bill_amt, 
						pr_activity.bdgt_cost_amt, 
						pr_activity.bdgt_bill_amt 
						FROM resbdgt 
						WHERE cmpy_code = pv_cmpy_code 
						AND job_code = pr_resbdgt.job_code 
						AND activity_code = pr_resbdgt.activity_code 
						AND var_code = pr_resbdgt.var_code 
						IF status THEN 
							# ERROR "Unsuccessful Addition sum of est_cost_amt failed.",
							#      "Stat:",STATUS
							LET msgresp = kandoomsg("J", 9578, status) 
							ROLLBACK WORK 
							LET fv_status = false 
							EXIT INPUT 
						END IF 
						SELECT sum(resbdgt.est_cost_qty), 
						sum(resbdgt.est_bill_qty), 
						sum(resbdgt.bdgt_cost_qty), 
						sum(resbdgt.bdgt_bill_qty) 
						INTO pr_activity.est_cost_qty, 
						pr_activity.est_bill_qty, 
						pr_activity.bdgt_cost_qty, 
						pr_activity.bdgt_bill_qty 
						FROM resbdgt, jmresource, activity 
						WHERE resbdgt.cmpy_code = pv_cmpy_code 
						AND resbdgt.job_code = pr_resbdgt.job_code 
						AND resbdgt.activity_code = pr_resbdgt.activity_code 
						AND resbdgt.var_code = pr_resbdgt.var_code 
						AND resbdgt.cmpy_code = pv_cmpy_code 
						AND activity.job_code = pr_resbdgt.job_code 
						AND activity.activity_code = pr_resbdgt.activity_code 
						AND activity.var_code = pr_resbdgt.var_code 
						AND activity.cmpy_code = pr_resbdgt.cmpy_code 
						AND jmresource.cmpy_code = pv_cmpy_code 
						AND jmresource.res_code = resbdgt.res_code 
						AND (jmresource.unit_code = activity.unit_code 
						OR (jmresource.unit_code IS NULL 
						AND activity.unit_code IS null)) 
						IF status THEN 
							# ERROR "Unsuccessful Addition sum of est_cost_amt failed.",
							#      "Stat:",STATUS
							LET msgresp = kandoomsg("J", 9578, status) 
							ROLLBACK WORK 
							LET fv_status = false 
							EXIT INPUT 
						END IF 
						IF pr_activity.est_cost_amt IS NULL THEN 
							LET pr_activity.est_cost_amt = 0 
						END IF 
						IF pr_activity.est_bill_amt IS NULL THEN 
							LET pr_activity.est_bill_amt = 0 
						END IF 
						IF pr_activity.bdgt_cost_amt IS NULL THEN 
							LET pr_activity.bdgt_cost_amt = 0 
						END IF 
						IF pr_activity.bdgt_bill_amt IS NULL THEN 
							LET pr_activity.bdgt_bill_amt = 0 
						END IF 
						IF pr_activity.est_cost_qty IS NULL THEN 
							LET pr_activity.est_cost_qty = 0 
						END IF 
						IF pr_activity.est_bill_qty IS NULL THEN 
							LET pr_activity.est_bill_qty = 0 
						END IF 
						IF pr_activity.bdgt_cost_qty IS NULL THEN 
							LET pr_activity.bdgt_cost_qty = 0 
						END IF 
						IF pr_activity.bdgt_bill_qty IS NULL THEN 
							LET pr_activity.bdgt_bill_qty = 0 
						END IF 
						UPDATE activity 
						#SET * = pr_activity.*
						SET est_cost_amt = pr_activity.est_cost_amt, 
						est_bill_amt = pr_activity.est_bill_amt, 
						bdgt_cost_amt = pr_activity.bdgt_cost_amt, 
						bdgt_bill_amt = pr_activity.bdgt_bill_amt, 
						est_cost_qty = pr_activity.est_cost_qty, 
						est_bill_qty = pr_activity.est_bill_qty, 
						bdgt_cost_qty = pr_activity.bdgt_cost_qty, 
						bdgt_bill_qty = pr_activity.bdgt_bill_qty 
						WHERE cmpy_code = pv_cmpy_code 
						AND activity_code = pr_activity.activity_code 
						AND job_code = pr_activity.job_code 
						AND var_code = pr_activity.var_code 
						IF status THEN 
							#ERROR "Unsuccessful Addition activity UPDATE failed.",
							#      "Stat:",STATUS
							LET msgresp = kandoomsg("J", 9579, status) 
							ROLLBACK WORK 
							LET fv_status = false 
							EXIT INPUT 
						ELSE 
						COMMIT WORK 
						# MESSAGE "Budgets added FOR Resource ",
						#        pr_resbdgt.res_code clipped,
						#        " AND Budgets Updated FOR Activity ",
						LET pr_msg_text = "(",pr_resbdgt.activity_code clipped, "/", 
						pr_resbdgt.res_code clipped,")" 
						LET msgresp = kandoomsg("J", 1415, pr_msg_text) 
						LET fv_status = true 
						EXIT INPUT 
					END IF 
				ELSE 
				COMMIT WORK 
				# MESSAGE "Budgets added FOR Resource ",
				#        pr_resbdgt.res_code clipped,
				#        " - Budgets NOT Updated FOR Activity ",
				#        pr_resbdgt.activity_code
				#   attribute (yellow)
				LET msgresp = kandoomsg("J", 1416, "") 
				#LET msgresp = kandoomsg("J", 1415, pr_resbdgt.res_code)
				LET fv_status = true 
				EXIT INPUT 
			END IF 
		END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 

	RETURN fv_status 
END FUNCTION #add_resbdgt 
