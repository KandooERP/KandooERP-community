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

	Source code beautified by beautify.pl on 2020-01-02 19:48:08	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "J_JM_GLOBALS.4gl" 
GLOBALS "J5_GLOBALS.4gl" 
GLOBALS "J51_GLOBALS.4gl" 
{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module J51, add an activity



DEFINE 
pr_menunames RECORD LIKE menunames.* 

MAIN 

	#Initial UI Init
	CALL setModuleId("J51") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	CALL user_security(glob_rec_kandoouser.cmpy_code, glob_rec_kandoouser.sign_on_code) 
	RETURNING pr_rec_kandoouser.acct_mask_code, 
	pr_user_scan_code 
	SELECT jmparms.* 
	INTO pr_jmparms.* 
	FROM jmparms 
	WHERE jmparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND jmparms.key_code = "1" 
	IF status = notfound THEN 
		#ERROR " Must SET up JM Parameters first in JZP"
		LET msgresp = kandoomsg("J",1501," ") 
		SLEEP 5 
		EXIT program 
	END IF 
	OPEN WINDOW j104 with FORM "J104" -- alch kd-747 
	CALL winDecoration_j("J104") -- alch kd-747 
	IF num_args() > 0 THEN 
		LET pr_activity.job_code = arg_val(1) 
		WHILE add_activity() 
		END WHILE 
	ELSE 
		WHILE get_job() 
			WHILE add_activity() 
			END WHILE 
		END WHILE 
	END IF 
	CLOSE WINDOW j104 
	LET int_flag = false 
	LET quit_flag = false 
END MAIN 


FUNCTION get_job() 
	INPUT BY NAME pr_activity.job_code 
	WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","J51","input-pr_activity-1") -- alch kd-506 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (control-b) 
			LET pr_activity.job_code = showujobs(glob_rec_kandoouser.cmpy_code, 
			pr_rec_kandoouser.acct_mask_code) 
			SELECT title_text 
			INTO pr_job.title_text 
			FROM job 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND job_code = pr_activity.job_code 
			DISPLAY BY NAME pr_activity.job_code, 
			pr_job.title_text 

		BEFORE FIELD job_code 
			LET msgresp = kandoomsg("J",1020,"") 
			# J1020 Enter new activity details; CANCEL TO EXIT.
		AFTER FIELD job_code 
			SELECT job.*, 
			customer.name_text 
			INTO pr_job.*, 
			pr_customer.name_text 
			FROM job, customer 
			WHERE job.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND job_code = pr_activity.job_code 
			AND customer.cmpy_code = job.cmpy_code 
			AND customer.cust_code = job.cust_code 
			AND (job.acct_code matches pr_user_scan_code OR 
			job.locked_ind <= "1") 
			IF status = notfound THEN 
				#ERROR "No such Job Code - Try Window"
				LET msgresp = kandoomsg("J",9509," ") 
				NEXT FIELD job_code 
			ELSE 
				DISPLAY BY NAME pr_job.title_text, 
				pr_job.cust_code, 
				pr_customer.name_text 

			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 


FUNCTION add_activity() 
	DEFINE 
	fv_runner CHAR(200), 
	cnt SMALLINT 

	SELECT job.*, 
	customer.name_text 
	INTO pr_job.*, 
	pr_customer.name_text 
	FROM job, 
	customer 
	WHERE job.job_code = pr_activity.job_code 
	AND job.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND customer.cust_code = job.cust_code 
	AND customer.cmpy_code = glob_rec_kandoouser.cmpy_code 
	CALL get_acct_masks(pr_job.type_code) 
	CLEAR FORM 
	INITIALIZE pr_activity.* TO NULL 
	FOR cnt = 1 TO 100 
		INITIALIZE pa_act_desc[cnt] TO NULL 
	END FOR 
	LET pr_activity.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET pr_activity.job_code = pr_job.job_code 
	DISPLAY BY NAME pr_job.job_code, 
	pr_job.title_text, 
	pr_job.cust_code, 
	pr_customer.name_text 

	WHILE true 
		INPUT BY NAME pr_activity.var_code, 
		pr_activity.activity_code 
		WITHOUT DEFAULTS 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","J51","input-pr_activity-2") -- alch kd-506 

			BEFORE FIELD var_code 
				SELECT count(*) 
				INTO cnt 
				FROM activity 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND job_code = pr_activity.job_code 
				AND var_code = 0 
				IF cnt = 0 THEN 
					LET pr_activity.var_code = 0 
					DISPLAY BY NAME pr_activity.var_code 

					NEXT FIELD activity_code 
				END IF 
			AFTER FIELD var_code 
				IF pr_activity.var_code IS NULL THEN 
					LET pr_activity.var_code = 0 
					DISPLAY BY NAME pr_activity.var_code 

				END IF 
				IF pr_activity.var_code != 0 THEN 
					SELECT count(*) 
					INTO cnt 
					FROM jobvars 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND jobvars.job_code = pr_activity.job_code 
					AND jobvars.var_code = pr_activity.var_code 
					IF cnt = 0 THEN 
						#error" No such Variation FOR this Job - Try Window"
						LET msgresp = kandoomsg("J",9510," ") 
						NEXT FIELD var_code 
					END IF 
				END IF 
			BEFORE FIELD activity_code 
				# MESSAGE "F9 TO Image Existing Activities"
				#   ATTRIBUTE(yellow)
				LET msgresp = kandoomsg("J",1532," ") 
			AFTER FIELD activity_code 
				LET msgresp = kandoomsg("J",1020,"") 
				# J1020 Enter new activity details; CANCEL TO EXIT.
				IF pr_activity.activity_code IS NULL THEN 
					#ERROR " Activity Code must be entered "
					LET msgresp = kandoomsg("J",9511," ") 
					NEXT FIELD activity_code 
				ELSE 
					SELECT count(*) 
					INTO cnt 
					FROM activity 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
					job_code = pr_activity.job_code AND 
					activity.var_code = pr_activity.var_code AND 
					activity_code = pr_activity.activity_code 
					IF cnt != 0 THEN 
						#error
						#" Activity Code Exists FOR this Code AND Variation"
						LET msgresp = kandoomsg("J",9566," ") 
						NEXT FIELD activity_code 
					END IF 
				END IF 
				SELECT title_text 
				INTO pr_activity.title_text 
				FROM activity 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND job_code = pr_activity.job_code 
				AND var_code = 0 
				AND activity_code = pr_activity.activity_code 
				IF status != notfound THEN 
					DISPLAY pr_activity.title_text TO activity.title_text 

				END IF 
			ON KEY (control-b) 
				CASE 
					WHEN infield (var_code) 
						LET pr_activity.var_code = 
						show_jobvars(glob_rec_kandoouser.cmpy_code, pr_activity.job_code) 
						DISPLAY pr_activity.var_code 
						TO activity.var_code 

					WHEN infield (activity_code) 
						LET pr_activity.activity_code = 
						show_activity(glob_rec_kandoouser.cmpy_code, pr_activity.job_code, 0) 
						DISPLAY pr_activity.activity_code 
						TO activity.activity_code 

				END CASE 
			ON KEY (F9) 
				IF infield (activity_code) THEN 
					CALL image_activity(pr_job.acct_code, 
					pr_job.wip_acct_code, 
					pr_job.cos_acct_code, 
					" ", " ") 
					LET int_flag = true 
					EXIT INPUT 
				END IF 
			ON KEY (control-w) 
				CALL kandoohelp("") 
		END INPUT 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			RETURN false 
		END IF 
		IF pr_job.locked_ind = "0" THEN 
			LET pr_activity.finish_flag = "Y" 
		ELSE 
			LET pr_activity.finish_flag = "N" 
		END IF 
		LET pr_activity.locked_ind = "1" 
		LET pr_activity.est_comp_per = 0 
		LET pr_activity.post_cost_amt = 0 
		LET pr_activity.post_revenue_amt = 0 
		LET pr_activity.est_cost_amt = 0 
		LET pr_activity.est_bill_amt = 0 
		LET pr_activity.est_cost_qty = 0 
		LET pr_activity.est_bill_qty = 0 
		LET pr_activity.bdgt_cost_amt = 0 
		LET pr_activity.bdgt_bill_amt = 0 
		LET pr_activity.bdgt_cost_qty = 0 
		LET pr_activity.bdgt_bill_qty = 0 
		LET pr_activity.act_cost_amt = 0 
		LET pr_activity.act_bill_amt = 0 
		LET pr_activity.act_cost_qty = 0 
		LET pr_activity.act_bill_qty = 0 
		LET pr_activity.est_wroff_qty = 0 
		LET pr_activity.est_wroff_amt = 0 
		LET pr_activity.bdgt_wroff_qty = 0 
		LET pr_activity.bdgt_wroff_amt = 0 
		LET pr_activity.act_wroff_qty = 0 
		LET pr_activity.act_wroff_amt = 0 
		LET pr_activity.seq_num = 0 
		LET pr_activity.est_start_date = pr_job.est_start_date 
		LET pr_activity.est_end_date = pr_job.est_end_date 
		LET pr_activity.bill_way_ind = pr_job.bill_way_ind 
		LET pr_activity.bill_when_ind = pr_job.bill_when_ind 
		CALL read_details() 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		ELSE 
			OPEN WINDOW j105 with FORM "J105" -- alch kd-747 
			CALL winDecoration_j("J105") -- alch kd-747 
			DISPLAY BY NAME pr_job.job_code, 
			pr_job.title_text, 
			pr_activity.var_code 
			CALL build_mask (glob_rec_kandoouser.cmpy_code, 
			pr_jobtype.bill_acct_code, 
			pr_rec_kandoouser.acct_mask_code) 
			RETURNING entry_mask 
			LET pr_activity.acct_code = pr_job.acct_code 
			CALL build_mask (glob_rec_kandoouser.cmpy_code, 
			pr_jobtype.wip_acct_code, 
			pr_rec_kandoouser.acct_mask_code) 
			RETURNING wip_entry_mask 
			LET pr_activity.wip_acct_code = pr_job.wip_acct_code 
			CALL build_mask (glob_rec_kandoouser.cmpy_code, 
			pr_jobtype.cos_acct_code, 
			pr_rec_kandoouser.acct_mask_code) 
			RETURNING cos_entry_mask 
			LET pr_activity.cos_acct_code = pr_job.cos_acct_code 
			CALL read_financials() 
			CLOSE WINDOW j105 
			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
			ELSE 
				CALL insert_data() 
				EXIT WHILE 
			END IF 
		END IF 
	END WHILE 
	LET msgresp = kandoomsg("J",7019,pr_activity.activity_code) 
	# Suuccessful addition of activity
	IF get_kandoooption_feature_state("JM","W1") = "Y" THEN 
		LET msgresp = kandoomsg("J",1533," ") 
		IF upshift(msgresp) = "Y" THEN 
			CALL run_prog("J77",glob_rec_kandoouser.cmpy_code, 
			pr_activity.job_code, 
			pr_activity.var_code, 
			pr_activity.activity_code) 
		END IF 
	END IF 
	RETURN true 
END FUNCTION 


FUNCTION insert_data() 
	DEFINE 
	cnt SMALLINT 

	GOTO bypass 
	LABEL recovery: 
	LET err_continue = error_recover(err_message, status) 
	IF err_continue != "Y" THEN 
		EXIT program 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	BEGIN WORK 
		LET err_message = "J51 - Inserting Activity" 
		INSERT INTO activity VALUES (pr_activity.*) 
		DECLARE ins_j_curs CURSOR FOR 
		INSERT INTO act_desc VALUES (pr_act_desc.*) 
		OPEN ins_j_curs 
		LET err_message = " J51 - Inserting activity description" 
		FOR cnt = 1 TO act_desc_cnt 
			LET pr_act_desc.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET pr_act_desc.job_code = pr_activity.job_code 
			LET pr_act_desc.var_code = pr_activity.var_code 
			LET pr_act_desc.activity_code = pr_activity.activity_code 
			LET pr_act_desc.seq_num = cnt 
			LET pr_act_desc.desc_text = pa_act_desc[cnt] 
			PUT ins_j_curs 
		END FOR 
		CLOSE ins_j_curs 
		LET err_message = " J51 - Updating Job" 
		WHENEVER ERROR GOTO recovery 
		UPDATE job 
		SET ( est_start_date , est_end_date ) = 
		( pr_job.est_start_date, pr_job.est_end_date ) 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND job_code = pr_job.job_code 
		AND cust_code = pr_job.cust_code 
		WHENEVER ERROR stop 
	COMMIT WORK 
END FUNCTION 


