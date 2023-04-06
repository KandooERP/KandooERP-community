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

	Source code beautified by beautify.pl on 2020-01-02 19:48:00	$Id: $
}
#let me try - here it looks much better..  #DONE why do you need all this spaces?)

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "J_JM_GLOBALS.4gl" 
GLOBALS "J11_GLOBALS.4gl" 
{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module J11 -  Job Management , Job Addition & Image Program

GLOBALS "J11a.4gl" 

MAIN 
	DEFINE 
	pr_menunames RECORD LIKE menunames.* 

	#Initial UI Init
	CALL setModuleId("J11") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	CALL user_mask_security(glob_rec_kandoouser.cmpy_code, 
	glob_rec_kandoouser.sign_on_code, 
	"J11", 
	"3") 
	RETURNING pr_rec_kandoouser.acct_mask_code, 
	pr_user_scan_code 
	LET user_default_code = pr_rec_kandoouser.acct_mask_code 
	LET default_entry_ok = true 

	SELECT base_currency_code 
	INTO pr_base_currency 
	FROM glparms 
	WHERE glparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND glparms.key_code = "1" 
	IF status = notfound THEN 
		LET msgresp = kandoomsg("J",7002,"") 
		EXIT program 
	END IF 
	OPEN WINDOW j100 with FORM "J100" -- alch kd-747 
	CALL winDecoration_j("J100") -- alch kd-747 
	WHILE job_entry() 
		# Inserting Imaged activities
		IF pr_image_all_act = "Y" THEN 
			CALL image_activity(pr_job.acct_code, 
			pr_job.wip_acct_code, 
			pr_job.cos_acct_code, 
			pr_source_job_code, 
			pr_source_title_text) 
		END IF 
		OPEN WINDOW j164 with FORM "J164" -- alch kd-747 
		CALL winDecoration_j("J164") -- alch kd-747 
		DISPLAY BY NAME pr_job.job_code 
		MENU "Job Addition" 
			BEFORE MENU 
				CALL publish_toolbar("kandoo","J11","menu-job_addiction-1") -- alch kd-506 
			ON ACTION "WEB-HELP" -- albo kd-373 
				CALL onlinehelp(getmoduleid(),null) 
			COMMAND "Job " "RETURN TO Job Addition" 
				EXIT MENU 
			COMMAND "Activity" "Add an Activity TO this Job" 
				CALL run_prog("J51",pr_job.job_code,"","","") 
			COMMAND KEY (interrupt,"E") "Exit" "Cancel TO Exit Job Addition" 
				EXIT program 
			COMMAND KEY (control-w) 
				CALL kandoohelp("") 
		END MENU 
		CLOSE WINDOW j164 
	END WHILE 
	CLOSE WINDOW j100 
END MAIN 

FUNCTION job_entry() 
	DEFINE 
	desc_lines SMALLINT, 
	chkagn, ans CHAR(1) 
	LET first_time = "Y" 

	LET desc_lines = 0 
	INITIALIZE pa_job_desc TO NULL 
	INITIALIZE pr_job.* TO NULL 
	LET pr_jobtype.type_text = "" 
	LET pr_customer.name_text = "" 
	LET pr_salesperson.name_text = "" 
	WHILE true 
		SELECT jmparms.* 
		INTO pr_jmparms.* 
		FROM jmparms 
		WHERE jmparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND jmparms.key_code = "1" 
		IF status = notfound THEN 
			LET msgresp=kandoomsg("J",1401,"") 
			#ERROR " Parameters NOT found - use JZP "
			RETURN false 
		END IF 


		CLEAR FORM 
		LET msgresp=kandoomsg("J",1003,"") 
		# MESSAGE " Enter new Job Details - F9 TO Image Existing Job"

		DISPLAY BY NAME pr_jmparms.prompt1_text, 
		pr_jmparms.prompt2_text, 
		pr_jmparms.prompt3_text, 
		pr_jmparms.prompt4_text, 
		pr_jmparms.prompt5_text, 
		pr_jmparms.prompt6_text, 
		pr_jmparms.prompt7_text, 
		pr_jmparms.prompt8_text 
		attribute(white) 

		DISPLAY BY NAME pr_job.job_code, 
		pr_job.title_text, 
		pr_job.type_code, 
		pr_jobtype.type_text, 
		pr_job.cust_code, 
		pr_customer.name_text, 
		pr_job.sale_code, 
		pr_salesperson.name_text 

		INPUT pr_job.job_code, 
		pr_job.title_text, 
		pr_job.type_code, 
		pr_job.cust_code, 
		pr_job.sale_code WITHOUT DEFAULTS 
		FROM job_code, 
		job.title_text, 
		type_code, 
		cust_code, 
		sale_code 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","J11","input-pr_job-1") -- alch kd-506 

			ON ACTION "WEB-HELP" -- albo kd-373 
				CALL onlinehelp(getmoduleid(),null) 

			ON KEY (F9) 
				IF infield(job_code) THEN 
					CALL image_job() 
					RETURNING pr_job.*, 
					pr_jobtype.*, 
					pr_customer.*, 
					pr_salesperson.* 
					IF int_flag OR quit_flag THEN 
						INITIALIZE pr_job.*, 
						pr_jobtype.*, 
						pr_customer.*, 
						pr_salesperson.* TO NULL 
						#Reset image activity flag
						LET pr_image_all_act = "N" 
						LET int_flag = false 
						LET quit_flag = false 
						NEXT FIELD job_code 
					ELSE 
						DISPLAY BY NAME pr_job.job_code, 
						pr_job.title_text, 
						pr_job.type_code, 
						pr_jobtype.type_text, 
						pr_job.cust_code, 
						pr_customer.name_text, 
						pr_job.sale_code 

						DISPLAY pr_salesperson.name_text TO salesperson.name_text 



						CALL disp_report_code() 

						EXIT INPUT 
					END IF 
				END IF 
			ON KEY (F10) 
				IF infield(title_text) THEN 
					CALL read_description(desc_lines) 
					RETURNING desc_lines 
				END IF 
			ON KEY (control-b) 
				CASE 
					WHEN infield (job_code) 
						LET pr_job.job_code = 
						showujobs(glob_rec_kandoouser.cmpy_code, pr_user_scan_code) 
						SELECT title_text 
						INTO pr_job.title_text 
						FROM job 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
						job_code = pr_job.job_code 


						DISPLAY BY NAME pr_job.job_code, pr_job.title_text 

						NEXT FIELD type_code 
					WHEN infield (type_code) 
						LET pr_job.type_code = show_type(glob_rec_kandoouser.cmpy_code) 
						SELECT jobtype.* 
						INTO pr_jobtype.* 
						FROM jobtype 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
						type_code = pr_job.type_code 
						DISPLAY BY NAME pr_job.type_code, 
						pr_jobtype.type_text 

						NEXT FIELD cust_code 
					WHEN infield (cust_code) 
						LET pr_job.cust_code = show_clnt(glob_rec_kandoouser.cmpy_code) 
						SELECT name_text 
						INTO pr_customer.name_text 
						FROM customer 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
						cust_code = pr_job.cust_code 
						DISPLAY BY NAME pr_job.cust_code, 
						pr_customer.name_text 

						NEXT FIELD sale_code 

					WHEN infield (sale_code) 
						LET pr_job.sale_code = show_salperson(glob_rec_kandoouser.cmpy_code) 
						SELECT name_text 
						INTO pr_salesperson.name_text 
						FROM salesperson 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
						sale_code = pr_job.sale_code 
						DISPLAY BY NAME pr_job.sale_code 

						DISPLAY pr_salesperson.name_text TO salesperson.name_text 


				END CASE 
			AFTER FIELD job_code 
				IF pr_jmparms.nextjob_num != 0 THEN 
					IF pr_job.job_code IS NOT NULL THEN 
						LET msgresp=kandoomsg("J",9597,"") 
						#ERROR "Job code must be blank, next number",
						#" will be automatically allocated "
						NEXT FIELD job_code 
					END IF 
				ELSE 
					IF pr_job.job_code IS NULL THEN 
						LET msgresp=kandoomsg("U",9102,"") 
						#ERROR " A Unique Job Code must be entered "
						NEXT FIELD job_code 
					END IF 
					SELECT count(*) 
					INTO cnt 
					FROM job 
					WHERE job.cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND job_code = pr_job.job_code 
					IF cnt != 0 THEN 
						LET msgresp=kandoomsg("U",9104,"") 
						#ERROR " Job Code Exists - New Job Code must be Unique"
						NEXT FIELD job_code 
					END IF 
				END IF 
			BEFORE FIELD title_text 
				LET msgresp=kandoomsg("J",1004,"") 
				# MESSAGE" F10 TO Enter Full-Page Description"
			AFTER FIELD title_text 
				LET msgresp=kandoomsg("J",1003,"") 
				# MESSAGE " Enter new Job Details - F9 TO Image Existing Job"
				IF pr_job.type_code IS NULL THEN 
					NEXT FIELD type_code 
				END IF 

			AFTER FIELD type_code 
				IF pr_job.type_code IS NULL THEN 
					LET msgresp=kandoomsg("U",9102,"") 
					# ERROR " Job Type Code must be entered "
					NEXT FIELD type_code 
				END IF 
				SELECT jobtype.* 
				INTO pr_jobtype.* 
				FROM jobtype 
				WHERE jobtype.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND jobtype.type_code = pr_job.type_code 
				IF status = notfound THEN 
					LET msgresp=kandoomsg("U",9105,"") 
					# ERROR " No such Job Type Code - Try Help Window "
					NEXT FIELD type_code 
				ELSE 
					DISPLAY pr_jobtype.type_text TO jobtype.type_text 

					CALL disp_report_code() 
				END IF 
			AFTER FIELD cust_code 
				IF pr_job.cust_code IS NULL THEN 
					LET msgresp=kandoomsg("U",9102,"") 
					# ERROR " Client Code must be entered "
					NEXT FIELD cust_code 
				END IF 
				SELECT * 
				INTO pr_customer.* 
				FROM customer 
				WHERE customer.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND customer.cust_code = pr_job.cust_code 
				IF status = notfound THEN 
					LET msgresp=kandoomsg("U",9105,"") 
					#ERROR " No such Client Code - try help window "
					NEXT FIELD cust_code 
				ELSE 
					DISPLAY pr_customer.name_text TO customer.name_text 

				END IF 
			AFTER FIELD sale_code 
				IF pr_job.sale_code IS NULL THEN 
					LET msgresp=kandoomsg("U",9102,"") 
					# ERROR " Sales Person Code must be entered "
					NEXT FIELD sale_code 
				END IF 
				SELECT salesperson.* 
				INTO pr_salesperson.* 
				FROM salesperson 
				WHERE salesperson.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND salesperson.sale_code = pr_job.sale_code 
				IF status = notfound THEN 
					LET msgresp=kandoomsg("U",9105,"") 

					NEXT FIELD sale_code 
				ELSE 
					DISPLAY pr_salesperson.name_text TO salesperson.name_text 

				END IF 

			AFTER INPUT 
				IF int_flag OR quit_flag THEN 
					EXIT INPUT 
				END IF 
				IF pr_job.cust_code IS NULL THEN 
					LET msgresp=kandoomsg("U",9102,"") 
					# ERROR " Client Code must be entered "
					NEXT FIELD cust_code 
				END IF 
				IF pr_job.type_code IS NULL THEN 
					LET msgresp=kandoomsg("U",9102,"") 
					# ERROR " Job Type Code must be entered "
					NEXT FIELD type_code 
				END IF 
				IF pr_job.sale_code IS NULL THEN 
					LET msgresp=kandoomsg("U",9102,"") 
					# ERROR " Sales Person Code must be entered "
					NEXT FIELD sale_code 
				END IF 
				LET pr_job.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET pr_job.bill_way_ind = pr_jobtype.bill_way_ind 
				LET pr_job.bill_when_ind = pr_jobtype.bill_when_ind 
				LET pr_job.bill_issue_ind = pr_jobtype.bill_issue_ind 
				LET pr_job.finish_flag = "N" 
				LET pr_job.locked_ind = "1" 
				LET pr_job.internal_flag = "N" 
			ON KEY (control-w) 
				CALL kandoohelp("") 
		END INPUT 
		IF int_flag OR quit_flag THEN 
			RETURN false 
		END IF 
		WHILE true 
			CALL read_details() 
			IF int_flag OR quit_flag THEN 
				EXIT WHILE 
			END IF 
			IF default_entry_ok THEN 
				CALL acct_fill(glob_rec_kandoouser.cmpy_code, 
				glob_rec_kandoouser.sign_on_code, 
				"J11", 
				pr_rec_kandoouser.acct_mask_code, 
				user_default_code, 
				4, 
				"Account Defaults") 
				RETURNING user_default_code, 
				acct_desc_text, 
				default_entry_ok 
			END IF 
			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
				RETURN false 
			END IF 
			OPEN WINDOW j103 with FORM "J103" -- alch kd-747 
			CALL winDecoration_j("J103") -- alch kd-747 
			CALL build_mask(glob_rec_kandoouser.cmpy_code, 
			pr_jobtype.bill_acct_code, 
			user_default_code) 
			RETURNING pr_job.acct_code 
			LET bill_entry_mask = pr_job.acct_code 
			CALL build_mask(glob_rec_kandoouser.cmpy_code, 
			pr_jobtype.wip_acct_code, 
			user_default_code) 
			RETURNING pr_job.wip_acct_code 
			LET wip_entry_mask = pr_job.wip_acct_code 
			CALL build_mask(glob_rec_kandoouser.cmpy_code, 
			pr_jobtype.cos_acct_code, 
			user_default_code) 
			RETURNING pr_job.cos_acct_code 
			LET cos_entry_mask = pr_job.cos_acct_code 
			CALL read_financials() 
			CLOSE WINDOW j103 
			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
			ELSE 
				EXIT WHILE 
			END IF 
		END WHILE 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		ELSE 
			EXIT WHILE 
		END IF 
	END WHILE 
	GOTO bypass 
	LABEL recovery: 
	LET err_continue = error_recover(err_message, status) 
	IF err_continue != "Y" THEN 
		EXIT program 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	BEGIN WORK 
		LET err_message = " J11 - Inserting Job" 
		# Added TO get the next job number just BEFORE INSERT job
		SELECT nextjob_num 
		INTO pr_jmparms.nextjob_num 
		FROM jmparms 
		WHERE jmparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND jmparms.key_code = "1" 
		WHENEVER ERROR GOTO recovery 
		IF pr_jmparms.nextjob_num != 0 THEN 
			LET pr_job.job_code = next_job_number(pr_job.acct_code, " ") 
			WHENEVER ERROR CONTINUE 
			IF pr_job.job_code = "NOTVALID" THEN 
				LET msgresp = kandoomsg("A",9516,"") 
				#ERROR " Invalid Numbering - Review Menu GZD"
				SLEEP 5 
				EXIT program 
			END IF 
			WHENEVER ERROR stop 
			DISPLAY BY NAME pr_job.job_code 

		END IF 
		LET chkagn = "Y" 

		{Check IF job number already exists on job file}
		WHILE chkagn = "Y" 
			SELECT * 
			FROM job 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND job_code = pr_job.job_code 

			IF status = notfound THEN 
				LET chkagn = "N" 
				EXIT WHILE 
			END IF 
			IF kandoomsg("J",8000,pr_job.job_code) = "Y" THEN 
				LET pr_job.job_code = next_job_number(pr_job.acct_code, "Y") 
				IF pr_job.job_code = "NOTVALID" THEN 
					LET msgresp = kandoomsg("A",9516,"") 
					#ERROR " Invalid Numbering - Review Menu GZD"
					SLEEP 3 
					EXIT program 
				END IF 
			ELSE 
				RETURN false 
			END IF 
		END WHILE 
		INSERT INTO job VALUES (pr_job.*) 
		LET err_message = " J11 - Inserting job description" 
		FOR cnt = 1 TO 100 
			IF pa_job_desc[cnt] IS NOT NULL THEN 
				INSERT INTO job_desc VALUES (glob_rec_kandoouser.cmpy_code, 
				pr_job.job_code, 
				cnt, 
				pa_job_desc[cnt]) 
			END IF 
		END FOR 

		WHENEVER ERROR stop 
	COMMIT WORK 
	RETURN true 
END FUNCTION 


FUNCTION image_job() 
	DEFINE 
	pr_target_job_code LIKE job.job_code, 
	pr_target_title_text LIKE job.title_text, 
	pr_customer RECORD LIKE customer.*, 
	pr_salesperson RECORD LIKE salesperson.*, 
	pr_jobtype RECORD LIKE jobtype.*, 
	cnt, desc_lines SMALLINT, 
	reply CHAR(1), 
	pr_image_desc CHAR(1), 
	full_pg_enter CHAR(1) 

	LET desc_lines = 0 
	LET pr_image_desc = "Y" 
	LET full_pg_enter = "N" 
	LET pr_image_all_act = "Y" 
	OPEN WINDOW wj156 with FORM "J156" -- alch kd-747 
	CALL winDecoration_j("J156") -- alch kd-747 
	WHILE true 
		CLEAR FORM 
		LET msgresp=kandoomsg("U",1512,"") 
		INPUT pr_source_job_code WITHOUT DEFAULTS 
		FROM source_job_code 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","J11","input-pr_source_job_code-1") -- alch kd-506 

			ON ACTION "WEB-HELP" -- albo kd-373 
				CALL onlinehelp(getmoduleid(),null) 

			ON KEY (control-b) 
				LET pr_source_job_code = showujobs(glob_rec_kandoouser.cmpy_code, pr_user_scan_code) 
				DISPLAY pr_source_job_code TO source_job_code 

			AFTER FIELD source_job_code 
				SELECT job.* 
				INTO pr_job.* 
				FROM job 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND job_code = pr_source_job_code 
				AND (acct_code matches pr_user_scan_code 
				OR locked_ind <= "1") 
				IF status = notfound THEN 
					LET msgresp=kandoomsg("U",9105,"") 
					#ERROR " Source Job NOT found - Try Window"
					NEXT FIELD source_job_code 
				ELSE 
					SELECT name_text 
					INTO pr_customer.name_text 
					FROM customer 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cust_code = pr_job.cust_code 
					SELECT type_text 
					INTO pr_jobtype.type_text 
					FROM jobtype 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND type_code = pr_job.type_code 
					SELECT name_text 
					INTO pr_salesperson.name_text 
					FROM salesperson 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND sale_code = pr_job.sale_code 
					DISPLAY pr_job.title_text, 
					pr_job.title_text, 
					pr_job.type_code, 
					pr_jobtype.type_text, 
					pr_job.cust_code, 
					pr_customer.name_text, 
					pr_job.sale_code, 
					pr_salesperson.name_text, 
					pr_image_desc, 
					pr_image_all_act 
					TO source_title_text, 
					target_title_text, 
					jobtype.type_code, 
					jobtype.type_text, 
					customer.cust_code, 
					customer.name_text, 
					salesperson.sale_code, 
					salesperson.name_text, 
					formonly.image_desc, 
					formonly.image_all_act 

				END IF 
			ON KEY (control-w) 
				CALL kandoohelp("") 
		END INPUT 
		IF int_flag OR quit_flag THEN 
			EXIT WHILE 
		END IF 
		LET pr_job.job_code = NULL 
		INPUT pr_job.job_code, 
		pr_job.title_text, 
		pr_job.type_code, 
		pr_job.cust_code, 
		pr_job.sale_code, 
		pr_image_desc, 
		pr_image_all_act 
		WITHOUT DEFAULTS 
		FROM target_job_code, 
		target_title_text, 
		jobtype.type_code, 
		customer.cust_code, 
		salesperson.sale_code, 
		image_desc, 
		image_all_act 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","J11","input-pr_job-2") -- alch kd-506 

			ON KEY (control-b) 
				CASE 
					WHEN infield (target_job_code) 
						IF pr_jmparms.nextjob_num = 0 THEN 
							LET pr_target_job_code = 
							showujobs(glob_rec_kandoouser.cmpy_code, pr_user_scan_code) 
						END IF 
						## Add code TO DISPLAY job code AND title text
						SELECT title_text 
						INTO pr_target_title_text 
						FROM job 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
						job_code = pr_target_job_code 
						DISPLAY pr_target_job_code, pr_target_title_text 
						TO target_job_code, target_title_text 

						NEXT FIELD type_code 
					WHEN infield (type_code) 
						LET pr_job.type_code = show_type(glob_rec_kandoouser.cmpy_code) 
						SELECT type_text 
						INTO pr_jobtype.type_text 
						FROM jobtype 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
						type_code = pr_job.type_code 
						DISPLAY BY NAME pr_job.type_code, 
						pr_jobtype.type_text 

					WHEN infield (cust_code) 
						LET pr_job.cust_code = show_clnt(glob_rec_kandoouser.cmpy_code) 
						SELECT name_text 
						INTO pr_customer.name_text 
						FROM customer 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
						cust_code = pr_job.cust_code 
						DISPLAY BY NAME pr_job.cust_code, 
						pr_customer.name_text 


					WHEN infield (sale_code) 
						LET pr_job.sale_code = show_salperson(glob_rec_kandoouser.cmpy_code) 
						SELECT name_text 
						INTO pr_salesperson.name_text 
						FROM salesperson 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
						sale_code = pr_job.sale_code 
						DISPLAY pr_salesperson.name_text TO salesperson.name_text 

						DISPLAY BY NAME pr_job.sale_code 


				END CASE 
			ON KEY (F10) 
				IF infield(target_title_text) THEN 
					CALL read_description(desc_lines) 
					RETURNING desc_lines 
					LET full_pg_enter = "Y" 
				END IF 
			BEFORE FIELD target_job_code 
				IF pr_jmparms.nextjob_num != 0 THEN 
					NEXT FIELD target_title_text 
				END IF 
			AFTER FIELD target_job_code 
				IF pr_job.job_code IS NULL THEN 
					LET msgresp=kandoomsg("U",9102,"") 
					#ERROR " A Target Job Code must be entered"
					NEXT FIELD target_job_code 
				ELSE 
					SELECT count(*) 
					INTO cnt 
					FROM job 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND job_code = pr_job.job_code 
					IF cnt > 0 THEN 
						LET msgresp=kandoomsg("U",9104,"") 
						#" Job Code Exists - Target Job Code must be Unique"
						NEXT FIELD target_job_code 
					END IF 
				END IF 
			AFTER FIELD type_code 
				SELECT jobtype.* 
				INTO pr_jobtype.* 
				FROM jobtype 
				WHERE jobtype.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND jobtype.type_code = pr_job.type_code 
				IF status = notfound THEN 
					LET msgresp=kandoomsg("U",9105,"") 
					#ERROR " No such Job Type Code - try help window"
					NEXT FIELD jobtype.type_code 
				ELSE 
					DISPLAY pr_jobtype.type_text TO jobtype.type_text 

				END IF 
			AFTER FIELD cust_code 
				SELECT customer.* 
				INTO pr_customer.* 
				FROM customer 
				WHERE customer.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND customer.cust_code = pr_job.cust_code 
				IF status = notfound THEN 
					LET msgresp=kandoomsg("U",9105,"") 
					#ERROR " No such Client Code - try help window "
					NEXT FIELD customer.cust_code 
				ELSE 





					DISPLAY pr_customer.name_text TO customer.name_text 


					NEXT FIELD sale_code 
				END IF 

			AFTER FIELD sale_code 
				SELECT salesperson.* 
				INTO pr_salesperson.* 
				FROM salesperson 
				WHERE salesperson.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND salesperson.sale_code = pr_job.sale_code 
				IF status = notfound THEN 
					LET msgresp=kandoomsg("U",9105,"") 
					#error
					NEXT FIELD salesperson.sale_code 
				ELSE 
					DISPLAY pr_salesperson.name_text TO salesperson.name_text 

					NEXT FIELD image_desc 
				END IF 

			AFTER FIELD image_desc 
				IF full_pg_enter = "Y" AND 
				pr_image_desc = "Y" THEN 
					LET pr_image_desc = kandoomsg("J",8013,"") 
				END IF 
			AFTER INPUT 
				IF int_flag OR quit_flag THEN 
					EXIT INPUT 
				END IF 
				SELECT jobtype.* 
				INTO pr_jobtype.* 
				FROM jobtype 
				WHERE jobtype.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND jobtype.type_code = pr_job.type_code 
				IF status = notfound THEN 
					LET msgresp=kandoomsg("U",9105,"") 
					#ERROR " No such Job Type Code - try help window "
					NEXT FIELD type_code 
				ELSE 
					DISPLAY pr_jobtype.type_text TO jobtype.type_text 

				END IF 
				SELECT customer.* 
				INTO pr_customer.* 
				FROM customer 
				WHERE customer.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND customer.cust_code = pr_job.cust_code 
				IF status = notfound THEN 
					LET msgresp=kandoomsg("U",9105,"") 
					#ERROR " No such Client Code - try help window "
					NEXT FIELD customer.cust_code 
				ELSE 





					DISPLAY pr_customer.name_text TO customer.name_text 

				END IF 
				IF full_pg_enter = "Y" AND 
				pr_image_desc = "Y" THEN 
					LET pr_image_desc = kandoomsg("J",8013,"") 
				END IF 
			ON KEY (control-w) 
				CALL kandoohelp("") 
		END INPUT 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		ELSE 
			INITIALIZE pr_job.est_start_date, 
			pr_job.est_end_date, 
			pr_job.review_date, 
			pr_job.val_date, 
			pr_job.act_start_date, 
			pr_job.act_end_date, 
			pr_job.passwd_text, 
			pr_job.finish_flag, 
			pr_job.contract_text, 
			pr_job.contract_date, 
			pr_job.bill_comp_per, 
			pr_job.unit_comp_per, 
			pr_job.est_comp_per, 
			pr_job.cost_comp_per TO NULL 
			IF pr_job.locked_ind = "0" THEN 
				LET pr_job.locked_ind = "1" 
			END IF 
			LET pr_job.finish_flag = "N" 
			EXIT WHILE 
		END IF 
	END WHILE 
	CLOSE WINDOW wj156 

	IF pr_image_desc = "Y" THEN 
		DECLARE full_pg CURSOR FOR 
		SELECT * FROM job_desc 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND job_code = pr_source_job_code 
		ORDER BY seq_num 
		LET cnt = 0 
		FOREACH full_pg INTO pr_job_desc.* 
			LET cnt = cnt + 1 
			LET pa_job_desc[cnt] = pr_job_desc.desc_text 
		END FOREACH 
	END IF 
	RETURN pr_job.*, 
	pr_jobtype.*, 
	pr_customer.*, 
	pr_salesperson.* 
END FUNCTION 


FUNCTION next_job_number(acct_code, add_one) 
	DEFINE 
	acct_code LIKE job.acct_code, 
	pr_nextnumber RECORD LIKE nextnumber.*, 
	pr_structure RECORD LIKE structure.*, 
	next_number, prefixed_num LIKE job.job_code, 
	prefix LIKE job.acct_code, 
	nextjob_numwk LIKE nextnumber.next_num, 
	sav_jobnum LIKE nextnumber.next_num, 
	pr_flex_code LIKE invoicehead.acct_override_code, 
	chk_length CHAR(10), 
	add_one CHAR(1), 
	runner CHAR(80), 
	todays_date CHAR(23), 
	flex array[3] OF INTEGER, 
	prefix_length, idx, i, j, cnt SMALLINT 
	LET sav_jobnum = pr_jmparms.nextjob_num 

	SELECT next_num 
	INTO nextjob_numwk 
	FROM nextnumber 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND tran_type_ind = TRAN_TYPE_JOB_JOB 
	AND flex_code = "POSITIONS" 
	IF status != notfound THEN 
		LET pr_jmparms.nextjob_num = nextjob_numwk 
		LET idx = 1 
		LET j = 0 - pr_jmparms.nextjob_num + 0 
		FOR i = 2 TO 0 step -1 
			IF flex[idx] != 0 THEN 
				LET idx = idx + 1 
			END IF 
			LET flex[idx] = j / (100 ** i) 
			LET j = j mod (100 ** i) 
		END FOR 
		LET todays_date = CURRENT clipped 
		LET idx = 1 
		WHILE idx < 4 AND flex[idx] != 0 
			SELECT * INTO pr_structure.* 
			FROM structure 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND start_num = flex[idx] 
			AND type_ind = "S" 
			IF status = notfound THEN 
				LET msgresp = kandoomsg("J",7009,"") 
				#7009 " Start number FOR flex code IS wrong "
				LET runner = "echo ' Date :", todays_date, " ' >> ", trim(get_settings_logFile())
				RUN runner 
				LET runner = 
				"echo ' Invdfunc - Flex code start position IS incorrect' >> ", trim(get_settings_logFile())
				RUN runner 
				EXIT program 
			END IF 
			LET i = pr_structure.start_num 
			LET j = pr_structure.length_num 
			LET prefix = prefix clipped, acct_code[i,i+j-1] 
			LET pr_flex_code[i,i+j-1] = acct_code[i,i+j-1] 
			LET idx = idx + 1 
		END WHILE 
		LET prefix_length = length(prefix) 
		IF prefix_length > 7 THEN 
			LET msgresp = kandoomsg("J",7010,"") 
			#7010 " Prefix IS too long TO allow invoice numbering "
			LET runner = "echo ' Date :", todays_date, " ' >> ",trim(get_settings_logFile()) 
			RUN runner 
			LET runner = 
			"echo ' Invdfunc - Prefix selected IS too long' >> ",trim(get_settings_logFile()) 
			RUN runner 
			EXIT program 
		END IF 
		WHENEVER ERROR CONTINUE 
		SELECT * INTO pr_nextnumber.* 
		FROM nextnumber 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND tran_type_ind = TRAN_TYPE_JOB_JOB 
		AND flex_code = pr_flex_code 
		IF status = -284 THEN 
			RETURN("NOTVALID") 
		END IF 
		WHENEVER ERROR stop 
		IF status != notfound THEN 
			IF pr_nextnumber.next_num = 0 THEN 
				IF first_time != "N" THEN 
					LET msgresp = kandoomsg("J",7011,"") 
					#7011"Job Number exceeds maximum - Review auto_numbering (GZD) "
					LET first_time = "N" 
				END IF 
				SELECT jmparms.* 
				INTO pr_jmparms.* 
				FROM jmparms 
				WHERE jmparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND jmparms.key_code = "1" 
			END IF 
			LET next_number = pr_nextnumber.next_num USING "&&&&&&&&" 
			LET prefixed_num = prefix 
			LET prefixed_num[prefix_length+1,8] = next_number[prefix_length+1,8] 
			IF pr_nextnumber.next_num != 0 THEN 
				IF prefix_length + length(chk_length) <= 8 THEN 
					CASE prefix_length 
						WHEN "1" 
							IF pr_nextnumber.next_num = 9999999 THEN 
								IF pr_jmparms.nextjob_num >= 0 THEN 
									UPDATE jmparms 
									SET nextjob_num = pr_jmparms.nextjob_num + 1 
									WHERE jmparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
									AND jmparms.key_code = "1" 
								ELSE 
									UPDATE jmparms SET nextjob_num = 1 
									WHERE jmparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
									AND jmparms.key_code = "1" 
								END IF 
								UPDATE nextnumber SET next_num = 0000000 
								WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
								AND tran_type_ind = TRAN_TYPE_JOB_JOB 
								AND flex_code = pr_flex_code 
								RETURN(prefixed_num) 
							ELSE 
								UPDATE nextnumber 
								SET next_num = pr_nextnumber.next_num + 1 
								WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
								AND tran_type_ind = TRAN_TYPE_JOB_JOB 
								AND flex_code = pr_flex_code 
								RETURN(prefixed_num) 
							END IF 
						WHEN "2" 
							IF pr_nextnumber.next_num = 999999 THEN 
								IF pr_jmparms.nextjob_num >= 0 THEN 
									UPDATE jmparms 
									SET nextjob_num = pr_jmparms.nextjob_num + 1 
									WHERE jmparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
									AND jmparms.key_code = "1" 
								ELSE 
									UPDATE jmparms SET nextjob_num = 1 
									WHERE jmparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
									AND jmparms.key_code = "1" 
								END IF 
								UPDATE nextnumber SET next_num = 000000 
								WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
								AND tran_type_ind = TRAN_TYPE_JOB_JOB 
								AND flex_code = pr_flex_code 
								RETURN(prefixed_num) 
							ELSE 
								UPDATE nextnumber 
								SET next_num = pr_nextnumber.next_num + 1 
								WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
								AND tran_type_ind = TRAN_TYPE_JOB_JOB 
								AND flex_code = pr_flex_code 
								RETURN(prefixed_num) 
							END IF 
						WHEN "3" 
							IF pr_nextnumber.next_num = 99999 THEN 
								IF pr_jmparms.nextjob_num >= 0 THEN 
									UPDATE jmparms 
									SET nextjob_num = pr_jmparms.nextjob_num + 1 
									WHERE jmparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
									AND jmparms.key_code = "1" 
								ELSE 
									UPDATE jmparms SET nextjob_num = 1 
									WHERE jmparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
									AND jmparms.key_code = "1" 
								END IF 
								UPDATE nextnumber SET next_num = 00000 
								WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
								AND tran_type_ind = TRAN_TYPE_JOB_JOB 
								AND flex_code = pr_flex_code 
								RETURN(prefixed_num) 
							ELSE 
								UPDATE nextnumber 
								SET next_num = pr_nextnumber.next_num + 1 
								WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
								AND tran_type_ind = TRAN_TYPE_JOB_JOB 
								AND flex_code = pr_flex_code 
								RETURN(prefixed_num) 
							END IF 
						WHEN "4" 
							IF pr_nextnumber.next_num = 9999 THEN 
								IF pr_jmparms.nextjob_num >= 0 THEN 
									UPDATE jmparms 
									SET nextjob_num = pr_jmparms.nextjob_num + 1 
									WHERE jmparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
									AND jmparms.key_code = "1" 
								ELSE 
									UPDATE jmparms SET nextjob_num = 1 
									WHERE jmparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
									AND jmparms.key_code = "1" 
								END IF 
								UPDATE nextnumber SET next_num = 0000 
								WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
								AND tran_type_ind = TRAN_TYPE_JOB_JOB 
								AND flex_code = pr_flex_code 
								RETURN(prefixed_num) 
							ELSE 
								UPDATE nextnumber 
								SET next_num = pr_nextnumber.next_num + 1 
								WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
								AND tran_type_ind = TRAN_TYPE_JOB_JOB 
								AND flex_code = pr_flex_code 
								RETURN(prefixed_num) 
							END IF 
						WHEN "5" 
							IF pr_nextnumber.next_num = 999 THEN 
								IF pr_jmparms.nextjob_num >= 0 THEN 
									UPDATE jmparms 
									SET nextjob_num = pr_jmparms.nextjob_num + 1 
									WHERE jmparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
									AND jmparms.key_code = "1" 
								ELSE 
									UPDATE jmparms SET nextjob_num = 1 
									WHERE jmparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
									AND jmparms.key_code = "1" 
								END IF 
								UPDATE nextnumber SET next_num = 000 
								WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
								AND tran_type_ind = TRAN_TYPE_JOB_JOB 
								AND flex_code = pr_flex_code 
								RETURN(prefixed_num) 
							ELSE 
								UPDATE nextnumber 
								SET next_num = pr_nextnumber.next_num + 1 
								WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
								AND tran_type_ind = TRAN_TYPE_JOB_JOB 
								AND flex_code = pr_flex_code 
								RETURN(prefixed_num) 
							END IF 
						WHEN "6" 
							IF pr_nextnumber.next_num = 99 THEN 
								IF pr_jmparms.nextjob_num >= 0 THEN 
									UPDATE jmparms 
									SET nextjob_num = pr_jmparms.nextjob_num + 1 
									WHERE jmparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
									AND jmparms.key_code = "1" 
								ELSE 
									UPDATE jmparms SET nextjob_num = 1 
									WHERE jmparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
									AND jmparms.key_code = "1" 
								END IF 
								UPDATE nextnumber SET next_num = 00 
								WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
								AND tran_type_ind = TRAN_TYPE_JOB_JOB 
								AND flex_code = pr_flex_code 
								RETURN(prefixed_num) 
							ELSE 
								UPDATE nextnumber 
								SET next_num = pr_nextnumber.next_num + 1 
								WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
								AND tran_type_ind = TRAN_TYPE_JOB_JOB 
								AND flex_code = pr_flex_code 
								RETURN(prefixed_num) 
							END IF 
						WHEN "7" 
							IF pr_nextnumber.next_num = 9 THEN 
								IF pr_jmparms.nextjob_num >= 0 THEN 
									UPDATE jmparms 
									SET nextjob_num = pr_jmparms.nextjob_num + 1 
									WHERE jmparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
									AND jmparms.key_code = "1" 
								ELSE 
									UPDATE jmparms SET nextjob_num = 1 
									WHERE jmparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
									AND jmparms.key_code = "1" 
								END IF 
								UPDATE nextnumber SET next_num = 0 
								WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
								AND tran_type_ind = TRAN_TYPE_JOB_JOB 
								AND flex_code = pr_flex_code 
								RETURN(prefixed_num) 
							ELSE 
								UPDATE nextnumber 
								SET next_num = pr_nextnumber.next_num + 1 
								WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
								AND tran_type_ind = TRAN_TYPE_JOB_JOB 
								AND flex_code = pr_flex_code 
								RETURN(prefixed_num) 
							END IF 
						WHEN "8" 
							UPDATE nextnumber SET next_num = pr_nextnumber.next_num + 1 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND tran_type_ind = TRAN_TYPE_JOB_JOB 
							AND flex_code = pr_flex_code 
							RETURN(prefixed_num) 
					END CASE 
				END IF 
			END IF 
		ELSE 
			LET pr_jmparms.nextjob_num = sav_jobnum 
		END IF 
	END IF 
	IF pr_jmparms.nextjob_num > 0 THEN 
		UPDATE jmparms SET nextjob_num = pr_jmparms.nextjob_num + 1 
		WHERE jmparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND jmparms.key_code = "1" 
		RETURN(pr_jmparms.nextjob_num) 
	END IF 
	RETURN("NOTVALID") 
END FUNCTION 


FUNCTION disp_report_code() 

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
	IF pr_jobtype.prompt1_ind != 5 OR 
	pr_jobtype.prompt2_ind != 5 OR 
	pr_jobtype.prompt3_ind != 5 OR 
	pr_jobtype.prompt4_ind != 5 OR 
	pr_jobtype.prompt5_ind != 5 OR 
	pr_jobtype.prompt6_ind != 5 OR 
	pr_jobtype.prompt7_ind != 5 OR 
	pr_jobtype.prompt8_ind != 5 THEN 
		DISPLAY BY NAME pr_jobtype.prompt1_text, 
		pr_jobtype.prompt2_text, 
		pr_jobtype.prompt3_text, 
		pr_jobtype.prompt4_text, 
		pr_jobtype.prompt5_text, 
		pr_jobtype.prompt6_text, 
		pr_jobtype.prompt7_text, 
		pr_jobtype.prompt8_text 

	END IF 
END FUNCTION 



