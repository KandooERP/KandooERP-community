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



FUNCTION read_details() 

	INPUT 
	pr_activity.title_text, 
	pr_activity.est_start_date, 
	pr_activity.est_end_date, 
	pr_activity.sort_text, 
	pr_activity.locked_ind, 
	pr_activity.retain_per, 
	pr_activity.priority_ind, 
	pr_activity.unit_code, 
	pr_activity.resp_code, 
	pr_activity.report_text, 
	pa_act_desc[1], 
	pa_act_desc[2], 
	pa_act_desc[3] WITHOUT DEFAULTS 
	FROM 
	activity.title_text, 
	est_start_date, 
	est_end_date, 
	sort_text, 
	locked_ind, 
	retain_per, 
	priority_ind, 
	unit_code, 
	resp_code, 
	report_text, 
	pr_desc_1, 
	pr_desc_2, 
	pr_desc_3 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","J51a","input-pr_activity-1") -- alch kd-506 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (control-b) 
			CASE 
				WHEN infield (unit_code) 
					LET pr_activity.unit_code = show_unit(glob_rec_kandoouser.cmpy_code) 
					DISPLAY pr_activity.unit_code 
					TO activity.unit_code 

				WHEN infield (resp_code) 
					LET pr_activity.resp_code = show_resp(glob_rec_kandoouser.cmpy_code) 
					DISPLAY pr_activity.resp_code 
					TO activity.resp_code 

			END CASE 
		ON KEY (f10) 
			CASE 
				WHEN infield (pr_desc_1) 
					OR infield (pr_desc_2) 
					OR infield (pr_desc_3) 

					#GET THE CURRENT CONTENTS OF THE FIELD BEFORE DISPLAY ALL
					CASE 
						WHEN infield (pr_desc_1) 
							CALL get_fldbuf(pr_desc_1) RETURNING pa_act_desc[1] 
						WHEN infield (pr_desc_2) 
							CALL get_fldbuf(pr_desc_2) RETURNING pa_act_desc[2] 
						WHEN infield (pr_desc_3) 
							CALL get_fldbuf(pr_desc_3) RETURNING pa_act_desc[3] 
					END CASE 


					CALL read_description() 
					DISPLAY pa_act_desc[1], 
					pa_act_desc[2], 
					pa_act_desc[3] 
					TO pr_desc_1, 
					pr_desc_2, 
					pr_desc_3 

			END CASE 

			SELECT name_text 
			INTO pr_responsible.name_text 
			FROM responsible 
			WHERE responsible.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND responsible.resp_code = pr_activity.resp_code 
			IF status != notfound THEN 
				DISPLAY pr_responsible.name_text 
				TO resp_name_text 

			END IF 


		AFTER FIELD unit_code 
			CLEAR desc_text 
			IF pr_activity.unit_code IS NOT NULL THEN 
				SELECT desc_text 
				INTO pr_actiunit.desc_text 
				FROM actiunit 
				WHERE actiunit.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND actiunit.unit_code = pr_activity.unit_code 
				IF status = notfound THEN 
					LET msgresp = kandoomsg("J",9484," ") 
					#ERROR "No such Unit Code. Try window FOR help."
					NEXT FIELD unit_code 
				ELSE 
					DISPLAY BY NAME pr_actiunit.desc_text 

				END IF 
			END IF 
		AFTER FIELD resp_code 
			IF pr_job.locked_ind != "0" THEN 
				IF pr_activity.resp_code IS NULL THEN 
					LET msgresp = kandoomsg("J",9491," ") 
					#ERROR " Responsibility Code must be entered "
					NEXT FIELD resp_code 
				END IF 
				SELECT name_text 
				INTO pr_responsible.name_text 
				FROM responsible 
				WHERE responsible.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND responsible.resp_code = pr_activity.resp_code 
				IF status = notfound THEN 
					#ERROR "No such Responsible code. Try window FOR help."
					LET msgresp = kandoomsg("J",9847," ") 
					NEXT FIELD resp_code 
				ELSE 
					DISPLAY pr_responsible.name_text 
					TO resp_name_text 

				END IF 
			END IF 
		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 
			IF pr_activity.resp_code IS NULL AND 
			pr_job.locked_ind != "0" THEN 
				LET msgresp = kandoomsg("J",9491," ") 
				#ERROR " Responsibility Code must be entered "
				NEXT FIELD resp_code 
			END IF 
			CASE 
				WHEN pr_job.est_start_date IS NOT NULL 
					AND pr_job.est_end_date IS NOT NULL 
					CASE 
						WHEN pr_activity.est_start_date IS NOT NULL 
							AND pr_activity.est_end_date IS NOT NULL 
							IF pr_activity.est_end_date > 
							pr_job.est_end_date 
							OR pr_activity.est_start_date < 
							pr_job.est_start_date THEN 
								CALL validate_est_dates() 
								NEXT FIELD est_start_date 
							ELSE 
								IF pr_activity.est_start_date > 
								pr_activity.est_end_date THEN 
									LET msgresp = kandoomsg("J",9629," ") 
									#" Estimated Start Date IS After Completion Date,"
									NEXT FIELD est_start_date 
								END IF 
							END IF 
						WHEN pr_activity.est_start_date IS NOT NULL 
							IF pr_activity.est_start_date < 
							pr_job.est_start_date 
							OR pr_activity.est_start_date > 
							pr_job.est_end_date THEN 
								CALL validate_est_dates() 
								NEXT FIELD est_start_date 
							END IF 
						WHEN pr_activity.est_end_date IS NOT NULL 
							IF pr_activity.est_end_date > 
							pr_job.est_end_date 
							OR pr_activity.est_end_date < 
							pr_job.est_start_date THEN 
								CALL validate_est_dates() 
								NEXT FIELD est_end_date 
							END IF 
					END CASE 
				WHEN pr_job.est_start_date IS NOT NULL 
					CASE 
						WHEN pr_activity.est_start_date IS NOT NULL 
							AND pr_activity.est_end_date IS NOT NULL 
							IF pr_activity.est_start_date < 
							pr_job.est_start_date THEN 
								CALL validate_est_dates() 
								NEXT FIELD est_start_date 
							ELSE 
								IF pr_activity.est_start_date > 
								pr_activity.est_end_date THEN 
									LET msgresp = kandoomsg("J",9629," ") 
									#"Estimated start date IS AFTER completion Date"
									NEXT FIELD est_start_date 
								END IF 
							END IF 
						WHEN pr_activity.est_start_date IS NOT NULL 
							IF pr_activity.est_start_date < 
							pr_job.est_start_date THEN 
								CALL validate_est_dates() 
								NEXT FIELD est_start_date 
							END IF 
						WHEN pr_activity.est_end_date IS NOT NULL 
							IF pr_activity.est_end_date < 
							pr_job.est_start_date THEN 
								CALL validate_est_dates() 
								NEXT FIELD est_end_date 
							END IF 
					END CASE 
				WHEN pr_job.est_end_date IS NOT NULL 
					CASE 
						WHEN pr_activity.est_start_date IS NOT NULL 
							AND pr_activity.est_end_date IS NOT NULL 
							IF pr_activity.est_end_date > 
							pr_job.est_end_date THEN 
								CALL validate_est_dates() 
								NEXT FIELD est_start_date 
							ELSE 
								IF pr_activity.est_start_date > 
								pr_activity.est_end_date THEN 
									LET msgresp = kandoomsg("J",9629," ") 
									#"Estimated Start Date IS AFTER Completion Date"
									NEXT FIELD est_start_date 
								END IF 
							END IF 
						WHEN pr_activity.est_start_date IS NOT NULL 
							IF pr_activity.est_start_date > 
							pr_job.est_end_date THEN 
								CALL validate_est_dates() 
								NEXT FIELD est_start_date 
							END IF 
						WHEN pr_activity.est_end_date IS NOT NULL 
							IF pr_activity.est_end_date > 
							pr_job.est_end_date THEN 
								CALL validate_est_dates() 
								NEXT FIELD est_end_date 
							END IF 
					END CASE 
			END CASE 
			#CHECK HOW MANY DESCRIPTION LINES ARE TO BE SAVED
			IF act_desc_cnt = 0 THEN #f10 NOT pressed - CHECK manually 
				FOR pv_cnt = 1 TO 3 
					IF pa_act_desc[pv_cnt] IS NOT NULL THEN 
						LET act_desc_cnt = act_desc_cnt + 1 
					END IF 
				END FOR 
			END IF 

		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
END FUNCTION 


FUNCTION validate_est_dates() 
	DEFINE 
	date_buffer DATE 
	OPEN WINDOW j163 with FORM "J163" -- alch kd-747 
	CALL winDecoration_j("J163") -- alch kd-747 
	DISPLAY 
	pr_job.job_code, 
	pr_activity.activity_code, 
	pr_job.est_start_date, 
	pr_job.est_end_date, 
	pr_activity.est_start_date, 
	pr_activity.est_end_date 
	TO 
	job.job_code, 
	activity.activity_code, 
	job.est_start_date, 
	job.est_end_date, 
	activity.est_start_date, 
	activity.est_end_date 
	INPUT 
	pr_job.est_start_date, 
	pr_job.est_end_date, 
	pr_activity.est_start_date, 
	pr_activity.est_end_date 
	WITHOUT DEFAULTS FROM 
	job.est_start_date, 
	job.est_end_date, 
	activity.est_start_date, 
	activity.est_end_date 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","J51a","input-pr_job-1") -- alch kd-506 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE FIELD job.est_start_date 
			LET date_buffer = pr_job.est_start_date 
		BEFORE FIELD job.est_end_date 
			LET date_buffer = pr_job.est_end_date 
		AFTER FIELD job.est_start_date 
			IF pr_job.est_start_date IS NOT NULL 
			AND pr_job.est_start_date > date_buffer THEN 
				#ERROR " Cannot increase Job estimated start date"
				LET msgresp = kandoomsg("J",9630," ") 
				LET pr_job.est_start_date = date_buffer 
				DISPLAY pr_job.est_start_date 
				TO job.est_start_date 
				NEXT FIELD job.est_start_date 
			END IF 
		AFTER FIELD job.est_end_date 
			IF pr_job.est_end_date IS NOT NULL 
			AND pr_job.est_end_date < date_buffer THEN 
				LET msgresp = kandoomsg("J",9631," ") 
				#ERROR " Cannot decrease Job estimated completion date"
				LET pr_job.est_end_date = date_buffer 
				DISPLAY pr_job.est_end_date 
				TO job.est_end_date 
				NEXT FIELD job.est_end_date 
			END IF 
		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 
			IF pr_activity.est_start_date IS NOT NULL 
			AND pr_job.est_start_date IS NOT NULL 
			AND pr_activity.est_start_date < pr_job.est_start_date THEN 
				#ERROR " Activity cannot start before Job start date"
				LET msgresp = kandoomsg("J",9632," ") 
				NEXT FIELD activity.est_start_date 
			END IF 
			IF pr_activity.est_end_date IS NOT NULL 
			AND pr_job.est_end_date IS NOT NULL 
			AND pr_activity.est_end_date > pr_job.est_end_date THEN 
				#ERROR " Activity cannot finish AFTER Job finish date"
				LET msgresp = kandoomsg("J",9633," ") 
				NEXT FIELD activity.est_end_date 
			END IF 
			IF pr_activity.est_start_date IS NOT NULL 
			AND pr_activity.est_end_date IS NOT NULL 
			AND pr_activity.est_end_date < pr_activity.est_start_date THEN 
				#ERROR " Estimated start date IS AFTER completion Date,"
				LET msgresp = kandoomsg("J",9629," ") 
				NEXT FIELD activity.est_start_date 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	CLOSE WINDOW j163 
	DISPLAY pr_activity.est_start_date, 
	pr_activity.est_end_date 
	TO activity.est_start_date, 
	activity.est_end_date 
	LET quit_flag = false 
	LET int_flag = false 
END FUNCTION 


FUNCTION display_details() 
	DISPLAY 
	pr_activity.job_code, 
	pr_job.title_text, 
	pr_job.cust_code, 
	pr_customer.name_text, 
	pr_activity.var_code, 
	pr_activity.activity_code, 
	pr_activity.title_text, 
	pr_activity.est_start_date, 
	pr_activity.est_end_date, 
	pr_activity.act_start_date, 
	pr_activity.act_end_date, 
	pr_activity.sort_text, 
	pr_activity.locked_ind, 
	pr_activity.priority_ind, 
	pr_activity.retain_per, 
	pr_activity.retain_amt, 
	pr_activity.finish_flag, 
	pr_activity.unit_code, 
	pr_activity.resp_code, 
	pr_activity.report_text, 
	pa_act_desc[1], 
	pa_act_desc[2], 
	pa_act_desc[3] 
	TO activity.job_code, 
	job.title_text, 
	customer.cust_code, 
	customer.name_text, 
	activity.var_code, 
	activity.activity_code, 
	activity.title_text, 
	est_start_date, 
	est_end_date, 
	act_start_date, 
	act_end_date, 
	sort_text, 
	locked_ind, 
	priority_ind, 
	retain_per, 
	retain_amt, 
	finish_flag, 
	unit_code, 
	resp_code, 
	report_text, 
	pr_desc_1, 
	pr_desc_2, 
	pr_desc_3 

	IF pr_activity.resp_code IS NULL THEN 
		LET pr_responsible.name_text = NULL 
	ELSE 
		SELECT name_text 
		INTO pr_responsible.name_text 
		FROM responsible 
		WHERE responsible.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND responsible.resp_code = pr_activity.resp_code 
	END IF 
	DISPLAY pr_responsible.name_text 
	TO resp_name_text 

	IF pr_activity.unit_code IS NULL THEN 
		LET pr_actiunit.desc_text = NULL 
	ELSE 
		SELECT desc_text 
		INTO pr_actiunit.desc_text 
		FROM actiunit 
		WHERE actiunit.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND actiunit.unit_code = pr_activity.unit_code 
	END IF 
	DISPLAY BY NAME pr_actiunit.desc_text 

END FUNCTION 


FUNCTION display_financials() 
	DISPLAY BY NAME 
	pr_job.job_code, 
	pr_job.title_text, 
	pr_activity.var_code, 
	pr_activity.bill_way_ind, 
	pr_activity.cost_alloc_flag, 
	pr_activity.bill_when_ind, 
	pr_activity.acct_code, 
	pr_activity.wip_acct_code, 
	pr_activity.cos_acct_code, 
	pr_activity.rev_image_flag, 
	pr_activity.wip_image_flag, 
	pr_activity.cos_image_flag, 
	pr_activity.est_cost_amt, 
	pr_activity.est_bill_amt, 
	pr_activity.bdgt_cost_amt, 
	pr_activity.bdgt_bill_amt, 
	pr_activity.act_cost_amt, 
	pr_activity.act_bill_amt, 
	pr_activity.post_revenue_amt, 
	pr_activity.est_comp_per, 
	pr_activity.post_cost_amt, 
	pr_activity.unit_code, 
	pr_activity.est_cost_qty, 
	pr_activity.est_bill_qty, 
	pr_activity.bdgt_cost_qty, 
	pr_activity.bdgt_bill_qty, 
	pr_activity.act_cost_qty, 
	pr_activity.act_bill_qty 

	CASE (pr_activity.bill_way_ind) 
		WHEN "C" 
			DISPLAY "Cost Plus Percent" 
			TO bill_way_text 

		WHEN "F" 
			DISPLAY "Fixed Price " 
			TO bill_way_text 

		WHEN "T" 
			DISPLAY "Time & Materials" 
			TO bill_way_text 

		WHEN "R" 
			DISPLAY "Recurring" 
			TO bill_way_text 

	END CASE 
	DISPLAY pr_activity.bill_when_ind, 
	"Daily" 
	TO bill_when_ind, 
	bill_when_text 

	# Add revenue account
	SELECT * 
	INTO pr_coa.* 
	FROM coa 
	WHERE coa.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND coa.acct_code = pr_activity.acct_code 
	IF status = notfound THEN 
		LET pr_coa.desc_text = " " 
	END IF 
	DISPLAY pr_coa.desc_text TO rev_desc_text 


	SELECT * 
	INTO pr_coa.* 
	FROM coa 
	WHERE coa.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND coa.acct_code = pr_activity.wip_acct_code 
	IF status = notfound THEN 
		LET pr_coa.desc_text = " " 
	END IF 
	DISPLAY BY NAME pr_coa.desc_text 

	SELECT coa.* 
	INTO pr_coa.* 
	FROM coa 
	WHERE coa.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND coa.acct_code = pr_activity.cos_acct_code 
	IF status = notfound THEN 
		LET pr_coa.desc_text = " " 
	END IF 
	DISPLAY pr_coa.desc_text TO cos_desc_text 

	# Add cost allocation processing
	CASE (pr_activity.cost_alloc_flag) 
		WHEN "1" 
			DISPLAY "% of Estimate" TO cost_alloc_text 
		WHEN "2" 
			DISPLAY "% + Bal of Actuals @ 100%" TO cost_alloc_text 
		WHEN "3" 
			DISPLAY "% of Actuals" TO cost_alloc_text 
		WHEN "4" 
			DISPLAY "Actuals TO date" TO cost_alloc_text 
		WHEN "5" 
			DISPLAY "Zero" TO cost_alloc_text 
		OTHERWISE 
			EXIT CASE 
	END CASE 

END FUNCTION 


FUNCTION read_financials() 
	DEFINE 
	pr_before_bill_way_ind LIKE activity.bill_way_ind, 
	pr_validation_type SMALLINT, 
	pr_validate_ind CHAR(1), 
	pr_year_num, pr_period_num, 
	pr_keyval, pr_upkey SMALLINT, 
	pr_bill_way_ind LIKE activity.bill_way_ind, 
	pr_cost_alloc_flag LIKE activity.cost_alloc_flag, 
	pr_response_text LIKE kandooword.response_text 

	CALL get_kandoo_user() RETURNING pr_rec_kandoouser.* 
	LET pr_upkey = fgl_keyval("up") 

	DISPLAY BY NAME pr_activity.unit_code, 
	pr_activity.est_comp_per 

	IF pr_job.locked_ind = "0" THEN 
		LET pr_validation_type = 2 
	ELSE 
		LET pr_validation_type = 1 
	END IF 
	LET pr_validate_ind = get_kandoooption_feature_state("JM","04") 
	CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, today) 
	RETURNING pr_year_num, pr_period_num 
	CALL validate_acct(glob_rec_kandoouser.cmpy_code,pr_activity.acct_code) 
	RETURNING acct_flag, 
	acct_desc_text 
	DISPLAY BY NAME pr_activity.acct_code 
	DISPLAY acct_desc_text 
	TO rev_desc_text 

	CALL validate_acct(glob_rec_kandoouser.cmpy_code,pr_activity.wip_acct_code) 
	RETURNING wip_acct_flag, 
	acct_desc_text 
	DISPLAY BY NAME pr_activity.wip_acct_code 
	DISPLAY acct_desc_text 
	TO desc_text 


	CALL validate_acct(glob_rec_kandoouser.cmpy_code,pr_activity.cos_acct_code) 
	RETURNING cos_acct_flag, 
	acct_desc_text 
	DISPLAY BY NAME pr_activity.cos_acct_code 
	DISPLAY acct_desc_text 
	TO cos_desc_text 


	IF pr_activity.rev_image_flag IS NULL THEN 
		LET pr_activity.rev_image_flag = pr_jmparms.acct_image_flag 
		DISPLAY BY NAME pr_activity.rev_image_flag 
	END IF 
	IF pr_activity.wip_image_flag IS NULL THEN 
		LET pr_activity.wip_image_flag = pr_jmparms.acct_image_flag 
		DISPLAY BY NAME pr_activity.wip_image_flag 
	END IF 
	IF pr_activity.cos_image_flag IS NULL THEN 
		LET pr_activity.cos_image_flag = pr_jmparms.acct_image_flag 
		DISPLAY BY NAME pr_activity.cos_image_flag 
	END IF 
	INPUT BY NAME 
	pr_activity.bill_way_ind, 
	pr_activity.cost_alloc_flag, 
	pr_activity.bill_when_ind, 
	pr_activity.acct_code, 
	pr_activity.wip_acct_code, 
	pr_activity.cos_acct_code, 
	pr_activity.rev_image_flag, 
	pr_activity.wip_image_flag, 
	pr_activity.cos_image_flag, 
	pr_activity.est_cost_amt, 
	pr_activity.est_bill_amt, 
	pr_activity.bdgt_cost_amt, 
	pr_activity.bdgt_bill_amt, 
	pr_activity.est_cost_qty, 
	pr_activity.est_bill_qty, 
	pr_activity.bdgt_cost_qty, 
	pr_activity.bdgt_bill_qty 
	WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","J51a","input-pr_activity-2") -- alch kd-506 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (control-b) 
			CASE 
				WHEN infield(bill_way_ind) 
					LET pr_bill_way_ind = show_kandooword("activity.bill_way_ind") 
					IF pr_bill_way_ind IS NOT NULL THEN 
						LET pr_activity.bill_way_ind = pr_bill_way_ind 
					END IF 
					DISPLAY pr_activity.bill_way_ind 
					TO bill_way_ind 

					NEXT FIELD bill_way_ind 
				WHEN infield(cost_alloc_flag) 
					LET pr_cost_alloc_flag = show_kandooword("activity.cost_alloc_flag") 
					IF pr_cost_alloc_flag IS NOT NULL THEN 
						LET pr_activity.cost_alloc_flag = pr_cost_alloc_flag 
					END IF 
					DISPLAY pr_activity.cost_alloc_flag 
					TO cost_alloc_flag 

					NEXT FIELD cost_alloc_flag 
			END CASE 
		BEFORE FIELD bill_way_ind 
			LET pr_before_bill_way_ind = pr_activity.bill_way_ind 
		AFTER FIELD bill_way_ind 
			IF pr_before_bill_way_ind IS NOT NULL 
			AND pr_before_bill_way_ind != pr_activity.bill_way_ind THEN 
				IF pr_activity.bill_way_ind = "F" 
				AND NOT act_deletable( pr_activity.job_code, 
				pr_activity.var_code, 
				pr_activity.activity_code ) THEN 
					LET msgresp = kandoomsg("J",9633,"") 
					#ERROR "Cannot Alter Bill Method as Current Invoices Exist"
					LET pr_activity.bill_way_ind = pr_before_bill_way_ind 
					NEXT FIELD bill_way_ind 
				END IF 
				IF pr_before_bill_way_ind = "F" 
				AND NOT act_deletable( pr_activity.job_code, 
				pr_activity.var_code, 
				pr_activity.activity_code ) THEN 
					LET msgresp = kandoomsg("J",9633,"") 
					#ERROR "Cannot Alter Bill Method as Current Invoices Exist"
					LET pr_activity.bill_way_ind = pr_before_bill_way_ind 
					NEXT FIELD bill_way_ind 
				END IF 
			END IF 
			IF pr_activity.bill_way_ind IS NOT NULL THEN 
				SELECT response_text 
				INTO pr_response_text 
				FROM kandooword 
				WHERE language_code = pr_rec_kandoouser.language_code 
				AND reference_text = "activity.bill_way_ind" 
				AND reference_code = pr_activity.bill_way_ind 
				IF status = notfound THEN 
					LET msgresp = kandoomsg("J",9648,0) 
					NEXT FIELD bill_way_ind 
				ELSE 
					DISPLAY pr_response_text 
					TO bill_way_text 

				END IF 
			ELSE 
				LET msgresp = kandoomsg("J",9648,0) 
				NEXT FIELD bill_way_ind 
			END IF 
			IF pr_activity.cost_alloc_flag IS NULL THEN 
				IF pr_activity.bill_way_ind = "F" THEN 
					LET pr_activity.cost_alloc_flag = pr_jmparms.cost_alloc_ind 
				ELSE 
					LET pr_activity.cost_alloc_flag = "4" 
				END IF 
			END IF 
		AFTER FIELD cost_alloc_flag 
			IF pr_activity.bill_way_ind != "F" THEN 
				IF pr_activity.cost_alloc_flag != "4" THEN 
					LET msgresp = kandoomsg("J",9567," ") 
					LET pr_activity.cost_alloc_flag = "4" 
					DISPLAY BY NAME pr_activity.cost_alloc_flag 
					NEXT FIELD cost_alloc_flag 
				END IF 
			END IF 
			IF pr_activity.cost_alloc_flag IS NOT NULL THEN 
				SELECT response_text 
				INTO pr_response_text 
				FROM kandooword 
				WHERE language_code = pr_rec_kandoouser.language_code 
				AND reference_text = "activity.cost_alloc_flag" 
				AND reference_code = pr_activity.cost_alloc_flag 
				IF status = notfound THEN 
					LET msgresp = kandoomsg("J",9648,0) 
					NEXT FIELD cost_alloc_flag 
				ELSE 
					DISPLAY pr_response_text 
					TO cost_alloc_text 

				END IF 
			ELSE 
				LET msgresp = kandoomsg("J",9648,0) 
				NEXT FIELD cost_alloc_flag 
			END IF 
		BEFORE FIELD bill_when_ind 
			CLEAR bill_when_text 
			LET pr_activity.bill_when_ind = 1 
			DISPLAY pr_activity.bill_when_ind, 
			"Daily" 
			TO bill_when_ind, 
			bill_when_text 

			NEXT FIELD acct_code 
			# Add revenue account
		BEFORE FIELD acct_code 
			IF pr_validate_ind matches "[Yy]" 
			OR acct_flag != 1 THEN 
				CALL acct_fill(glob_rec_kandoouser.cmpy_code, 
				glob_rec_kandoouser.sign_on_code, 
				"J51", 
				entry_mask, 
				pr_activity.acct_code, 
				pr_validation_type, 
				"REV Account") 
				RETURNING pr_activity.acct_code, 
				acct_desc_text, 
				entry_flag 
				DISPLAY pr_activity.acct_code TO acct_code 
				DISPLAY acct_desc_text TO rev_desc_text 
				IF int_flag OR quit_flag THEN 
					LET int_flag = false 
					LET quit_flag = false 
					NEXT FIELD bill_way_ind 
				END IF 
			END IF 
		BEFORE FIELD wip_acct_code 


			IF pr_validate_ind matches "[Yy]" 
			OR wip_acct_flag != 1 THEN 
				CALL acct_fill(glob_rec_kandoouser.cmpy_code, 
				glob_rec_kandoouser.sign_on_code, 
				"J51", 
				wip_entry_mask, 
				pr_activity.wip_acct_code, 
				pr_validation_type, 
				"WIP Account") 
				RETURNING pr_activity.wip_acct_code, 
				acct_desc_text, 
				entry_flag 
				DISPLAY pr_activity.wip_acct_code TO wip_acct_code 
				DISPLAY acct_desc_text TO desc_text 
				IF int_flag OR quit_flag THEN 
					LET int_flag = false 
					LET quit_flag = false 
					NEXT FIELD bill_way_ind 
				END IF 
			END IF 
		BEFORE FIELD cos_acct_code 


			IF pr_validate_ind matches "[Yy]" 
			OR cos_acct_flag != 1 THEN 
				CALL acct_fill(glob_rec_kandoouser.cmpy_code, 
				glob_rec_kandoouser.sign_on_code, 
				"J51", 
				cos_entry_mask, 
				pr_activity.cos_acct_code, 
				pr_validation_type, 
				"COS Account") 
				RETURNING pr_activity.cos_acct_code, 
				acct_desc_text, 
				entry_flag 
				DISPLAY pr_activity.cos_acct_code TO cos_acct_code 
				DISPLAY acct_desc_text TO cos_desc_text 
				IF int_flag OR quit_flag THEN 
					LET int_flag = false 
					LET quit_flag = false 
					NEXT FIELD bill_way_ind 
				END IF 
			END IF 
		AFTER FIELD acct_code 
			# Master Job - do NOT verify the account
			IF pr_job.locked_ind != 0 THEN 
				CALL v_acct_code(glob_rec_kandoouser.cmpy_code, 
				glob_rec_kandoouser.sign_on_code, 
				"J51", 
				pr_activity.acct_code, 
				pr_year_num, pr_period_num) 
				RETURNING pr_coa.* 
				IF pr_coa.acct_code IS NULL THEN 
					LET int_flag = true 
					LET quit_flag = true 
					EXIT INPUT 
				END IF 
				LET pr_activity.acct_code = pr_coa.acct_code 
				DISPLAY BY NAME pr_activity.acct_code 
				DISPLAY pr_coa.desc_text TO rev_desc_text 
			END IF 
			NEXT FIELD wip_acct_code 
		AFTER FIELD wip_acct_code 
			# Master Job - do NOT verify the account
			IF pr_job.locked_ind != 0 THEN 
				CALL v_acct_code(glob_rec_kandoouser.cmpy_code, 
				glob_rec_kandoouser.sign_on_code, 
				"J51", 
				pr_activity.wip_acct_code, 
				pr_year_num, pr_period_num) 
				RETURNING pr_coa.* 
				IF pr_coa.acct_code IS NULL THEN 
					LET int_flag = true 
					LET quit_flag = true 
					EXIT INPUT 
				END IF 
				LET pr_activity.wip_acct_code = pr_coa.acct_code 
				DISPLAY BY NAME pr_activity.wip_acct_code 
				DISPLAY pr_coa.desc_text TO desc_text 
			END IF 
			NEXT FIELD cos_acct_code 

		AFTER FIELD cos_acct_code 
			# Master Job - do NOT verify the account
			IF pr_job.locked_ind != 0 THEN 
				CALL v_acct_code(glob_rec_kandoouser.cmpy_code, 
				glob_rec_kandoouser.sign_on_code, 
				"J51", 
				pr_activity.cos_acct_code, 
				pr_year_num, pr_period_num) 
				RETURNING pr_coa.* 
				IF pr_coa.acct_code IS NULL THEN 
					LET int_flag = true 
					LET quit_flag = true 
					EXIT INPUT 
				END IF 
				LET pr_activity.cos_acct_code = pr_coa.acct_code 
				DISPLAY BY NAME pr_activity.cos_acct_code 
				DISPLAY pr_coa.desc_text TO cos_desc_text 
			END IF 
		BEFORE FIELD rev_image_flag 
			IF fgl_lastkey() != pr_upkey THEN 
				NEXT FIELD est_cost_amt 
			END IF 
		AFTER FIELD rev_image_flag 
			IF fgl_lastkey() = pr_upkey THEN 
				NEXT FIELD bill_way_ind 
			END IF 
		BEFORE FIELD est_cost_amt 
			IF pr_activity.rev_image_flag IS NULL THEN 
				LET pr_activity.rev_image_flag = pr_jmparms.acct_image_flag 
			END IF 
			IF pr_activity.wip_image_flag IS NULL THEN 
				LET pr_activity.wip_image_flag = pr_jmparms.acct_image_flag 
			END IF 
			IF pr_activity.cos_image_flag IS NULL THEN 
				LET pr_activity.cos_image_flag = pr_jmparms.acct_image_flag 
			END IF 
			IF get_kandoooption_feature_state("JM", "W1") matches "[yY]" THEN 
				LET msgresp = kandoomsg("J",9569," ") 
				NEXT FIELD est_cost_qty 
			END IF 
			IF pr_activity.locked_ind = "3" 
			OR pr_activity.locked_ind = "4" THEN 
				ERROR " Estimates AND budgets are locked - NO ENTRY" 
				EXIT INPUT 
			END IF 
		AFTER FIELD est_cost_amt 
			IF pr_activity.est_cost_amt IS NULL THEN 
				LET pr_activity.est_cost_amt = 0 
			END IF 
			IF pr_activity.bdgt_cost_amt = 0 THEN 
				LET pr_activity.bdgt_cost_amt = pr_activity.est_cost_amt 
				DISPLAY BY NAME pr_activity.bdgt_cost_amt 

			END IF 
			IF fgl_lastkey() = pr_upkey THEN 
				NEXT FIELD rev_image_flag 
			END IF 
		AFTER FIELD est_bill_amt 
			IF pr_activity.est_bill_amt IS NULL THEN 
				LET pr_activity.est_bill_amt = 0 
			END IF 
			IF pr_activity.bdgt_bill_amt = 0 THEN 
				LET pr_activity.bdgt_bill_amt = pr_activity.est_bill_amt 
				DISPLAY BY NAME pr_activity.bdgt_bill_amt 

			END IF 
		AFTER FIELD bdgt_cost_amt 
			IF pr_activity.bdgt_cost_amt IS NULL THEN 
				LET pr_activity.bdgt_cost_amt = 0 
				DISPLAY BY NAME pr_activity.bdgt_cost_amt 

			END IF 
		AFTER FIELD bdgt_bill_amt 
			IF pr_activity.bdgt_bill_amt IS NULL THEN 
				LET pr_activity.bdgt_bill_amt = 0 
				DISPLAY BY NAME pr_activity.bdgt_bill_amt 

			END IF 
		BEFORE FIELD est_cost_qty 
			IF pr_activity.unit_code IS NULL THEN 
				EXIT INPUT 
			END IF 
		AFTER FIELD est_cost_qty 
			IF pr_activity.est_cost_qty IS NULL THEN 
				LET pr_activity.est_cost_qty = 0 
			END IF 
			IF pr_activity.bdgt_cost_qty = 0 THEN 
				LET pr_activity.bdgt_cost_qty = pr_activity.est_cost_qty 
				DISPLAY BY NAME pr_activity.bdgt_cost_qty 

			END IF 
		AFTER FIELD est_bill_qty 
			IF pr_activity.est_bill_qty IS NULL THEN 
				LET pr_activity.est_bill_qty = 0 
			END IF 
			IF pr_activity.bdgt_bill_qty = 0 THEN 
				LET pr_activity.bdgt_bill_qty = pr_activity.est_bill_qty 
				DISPLAY BY NAME pr_activity.bdgt_bill_qty 

			END IF 
		AFTER FIELD bdgt_cost_qty 
			IF pr_activity.bdgt_cost_qty IS NULL THEN 
				LET pr_activity.bdgt_cost_qty = 0 
				DISPLAY BY NAME pr_activity.bdgt_cost_qty 

			END IF 
		AFTER FIELD bdgt_bill_qty 
			IF pr_activity.bdgt_bill_qty IS NULL THEN 
				LET pr_activity.bdgt_bill_qty = 0 
				DISPLAY BY NAME pr_activity.bdgt_bill_qty 

			END IF 
		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 
			IF pr_job.locked_ind != "0" THEN 

				CALL v_acct_code(glob_rec_kandoouser.cmpy_code, 
				glob_rec_kandoouser.sign_on_code, 
				"J51", 
				pr_activity.acct_code, 
				pr_year_num, pr_period_num) 
				RETURNING pr_coa.* 
				IF pr_coa.acct_code IS NULL THEN 
					LET int_flag = true 
					LET quit_flag = true 
					EXIT INPUT 
				END IF 
				LET pr_activity.acct_code = pr_coa.acct_code 
				DISPLAY BY NAME pr_activity.acct_code 
				DISPLAY pr_coa.desc_text TO rev_desc_text 
				# activity wip account
				CALL v_acct_code(glob_rec_kandoouser.cmpy_code, 
				glob_rec_kandoouser.sign_on_code, 
				"J51", 
				pr_activity.wip_acct_code, 
				pr_year_num, pr_period_num) 
				RETURNING pr_coa.* 
				IF pr_coa.acct_code IS NULL THEN 
					LET int_flag = true 
					LET quit_flag = true 
					EXIT INPUT 
				END IF 
				LET pr_activity.wip_acct_code = pr_coa.acct_code 
				DISPLAY BY NAME pr_activity.wip_acct_code 
				DISPLAY pr_coa.desc_text TO desc_text 

				CALL v_acct_code(glob_rec_kandoouser.cmpy_code, 
				glob_rec_kandoouser.sign_on_code, 
				"J51", 
				pr_activity.cos_acct_code, 
				pr_year_num, pr_period_num) 
				RETURNING pr_coa.* 
				IF pr_coa.acct_code IS NULL THEN 
					LET int_flag = true 
					LET quit_flag = true 
					EXIT INPUT 
				END IF 
				LET pr_activity.cos_acct_code = pr_coa.acct_code 
				DISPLAY BY NAME pr_activity.cos_acct_code 
				DISPLAY pr_coa.desc_text TO cos_desc_text 
			END IF 
			CASE (pr_activity.cost_alloc_flag) 
				WHEN "1" 
					DISPLAY "% of Estimate" TO cost_alloc_text 

				WHEN "2" 
					DISPLAY "% + Bal of Actuals @ 100%" TO cost_alloc_text 

				WHEN "3" 
					DISPLAY "% of Actuals" TO cost_alloc_text 

				WHEN "4" 
					DISPLAY "Actuals TO date" TO cost_alloc_text 

				WHEN "5" 
					DISPLAY "Zero" TO cost_alloc_text 

				OTHERWISE 
					LET msgresp = kandoomsg("J",9568," ") 
					NEXT FIELD cost_alloc_flag 
			END CASE 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
END FUNCTION 


FUNCTION read_description() 
	OPEN WINDOW j109 with FORM "J109" -- alch kd-747 
	CALL winDecoration_j("J109") -- alch kd-747 
	LET msgresp = kandoomsg("J",1428," ") 
	IF act_desc_cnt < 3 THEN 
		LET act_desc_cnt = 3 
	END IF 
	CALL set_count(act_desc_cnt ) 
	DISPLAY pr_activity.job_code, 
	pr_job.title_text, 
	pr_activity.activity_code, 
	pr_activity.var_code, 
	pr_activity.title_text 
	TO activity.job_code, 
	job.title_text, 
	activity.activity_code, 
	activity.var_code, 
	activity.title_text 

	INPUT ARRAY pa_act_desc WITHOUT DEFAULTS FROM sr_act_desc.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","J51a","input-pa_act_desc-1") -- alch kd-506 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (control-w) 
			CALL kandoohelp("") 

	END INPUT 
	LET act_desc_cnt = arr_count() 
	CLOSE WINDOW j109 
END FUNCTION 


FUNCTION get_acct_masks(job_type_code) 
	DEFINE 
	job_type_code LIKE jobtype.type_code 

	SELECT jobtype.* 
	INTO pr_jobtype.* 
	FROM jobtype 
	WHERE jobtype.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND jobtype.type_code = job_type_code 
	IF status = notfound THEN 
		INITIALIZE pr_jobtype.* TO NULL 
	END IF 
	#Add revenue account
	IF pr_jobtype.bill_acct_code IS NULL 
	OR pr_jobtype.bill_acct_code = " " THEN 
		CALL build_mask(glob_rec_kandoouser.cmpy_code,"??????????????????"," ") 
		RETURNING pr_jobtype.bill_acct_code 
	END IF 
	IF pr_jobtype.wip_acct_code IS NULL 
	OR pr_jobtype.wip_acct_code = " " THEN 
		CALL build_mask(glob_rec_kandoouser.cmpy_code,"??????????????????"," ") 
		RETURNING pr_jobtype.wip_acct_code 
	END IF 
	IF pr_jobtype.cos_acct_code IS NULL 
	OR pr_jobtype.cos_acct_code = " " THEN 
		CALL build_mask(glob_rec_kandoouser.cmpy_code,"??????????????????"," ") 
		RETURNING pr_jobtype.cos_acct_code 
	END IF 
END FUNCTION 
