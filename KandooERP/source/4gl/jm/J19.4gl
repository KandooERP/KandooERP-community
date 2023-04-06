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
# \brief module J19 -  Job Management , Job Addition & Image Program

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "J_JM_GLOBALS.4gl" 
GLOBALS "J11_GLOBALS.4gl" 

MAIN 
	DEFINE 
	pr_menunames RECORD LIKE menunames.* 


	#Initial UI Init
	CALL setModuleId("J19") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	CALL user_mask_security(glob_rec_kandoouser.cmpy_code, 
	glob_rec_kandoouser.sign_on_code, 
	"J19", 
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
		LET msgresp = kandoomsg("G",7006,"") 
		#7006 "  GL Parameters NOT found - use GZP "
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
				CALL publish_toolbar("kandoo","J19","menu-job_addiction-2") -- alch kd-506 
			ON ACTION "WEB-HELP" -- albo kd-373 
				CALL onlinehelp(getmoduleid(),null) 
			COMMAND "Job " 
				"RETURN TO Master Job Addition" 
				EXIT MENU 
			COMMAND "Activity" 
				"Add an Activity TO this Job" 
				CALL run_prog("J51",pr_job.job_code,"","","") 
			COMMAND KEY (interrupt,"E") "Exit" 
				"Cancel TO Exit Job Addition" 
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
		pr_job.sale_code 

		DISPLAY pr_salesperson.name_text TO salesperson.name_text 

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
				CALL publish_toolbar("kandoo","J19","input-pr_job-1") -- alch kd-506 

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
						# Reset image activity flag
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
						DISPLAY pr_salesperson.name_text TO salesperson.name_text 

						DISPLAY BY NAME pr_job.sale_code 


				END CASE 
			AFTER FIELD job_code 
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
			AFTER FIELD title_text 
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
					#
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
				LET pr_job.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET pr_job.bill_way_ind = pr_jobtype.bill_way_ind 
				LET pr_job.bill_when_ind = pr_jobtype.bill_when_ind 
				LET pr_job.bill_issue_ind = pr_jobtype.bill_issue_ind 
				LET pr_job.finish_flag = "Y" 
				LET pr_job.locked_ind = "0" 
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
				"J19", 
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
		LET err_message = " J19 - Inserting Job" 
		DISPLAY BY NAME pr_job.job_code 


		INSERT INTO job VALUES (pr_job.*) 
		LET err_message = " J19 - Inserting job description" 
		FOR cnt = 1 TO 100 
			IF pa_job_desc[cnt] IS NOT NULL THEN 
				INSERT INTO job_desc VALUES (glob_rec_kandoouser.cmpy_code, 
				pr_job.job_code, 
				cnt, 
				pa_job_desc[cnt]) 
			END IF 
		END FOR 

	COMMIT WORK 
	WHENEVER ERROR stop 
	RETURN true 
END FUNCTION 


FUNCTION image_job() 
	DEFINE 
	pr_target_job_code LIKE job.job_code, 
	pr_target_title_text LIKE job.title_text, 
	pr_customer RECORD LIKE customer.*, 
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
				CALL publish_toolbar("kandoo","J19","input-pr_source-1") -- alch kd-506 

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
				CALL publish_toolbar("kandoo","J19","input-pr_job-2") -- alch kd-506 

			ON ACTION "WEB-HELP" -- albo kd-373 
				CALL onlinehelp(getmoduleid(),null) 

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

					NEXT FIELD image_desc 
				END IF 

			AFTER FIELD sale_code 
				SELECT salesperson.* 
				INTO pr_salesperson.* 
				FROM salesperson 
				WHERE salesperson.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND salesperson.sale_code = pr_job.sale_code 
				IF status = notfound THEN 
					LET msgresp=kandoomsg("U",9105,"") 

					NEXT FIELD salesperson.sale_code 
				ELSE 
					DISPLAY pr_salesperson.name_text TO salesperson.name_text 

					NEXT FIELD image_desc 
				END IF 

			AFTER FIELD image_desc 
				IF full_pg_enter = "Y" AND 
				pr_image_desc = "Y" THEN 
					CALL wrning() 
					RETURNING pr_image_desc 
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
				IF full_pg_enter = "Y" AND 
				pr_image_desc = "Y" THEN 
					CALL wrning() 
					RETURNING pr_image_desc 
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
			LET pr_job.locked_ind = "0" 
			LET pr_job.finish_flag = "Y" 
			LET pr_job.internal_flag = "Y" 
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


# Warning IF overwriting keyed in full page
# description WHEN imaging job.
FUNCTION wrning() 
	DEFINE 
	reply CHAR(1), 
	pr_image_desc CHAR(1) 
	{  -- albo
	   OPEN WINDOW wrn AT 10,12
	   with 5 rows, 50 columns
	   attribute (border, reverse, prompt line last)
	   DISPLAY "WARNING : Imaged Full Page Description will     "
	      AT 1,1
	   DISPLAY "overwrite what you have just keyed "
	      AT 2,1
	   DISPLAY " "
	      AT 3,1
	   prompt " Do you want TO overwrite (Y)es (N)o "
	   FOR CHAR reply
	   CLOSE WINDOW wrn
	}
	LET reply = promptYN("","WARNING: Imaged Full Page Description \nwill overwrite what you have just keyed. \nDo you want TO overwrite? (Y)es (N)o","Y") -- albo 

	IF reply matches "[Yy]" THEN 
		LET pr_image_desc = "Y" 
	ELSE 
		LET pr_image_desc = "N" 
	END IF 
	RETURN pr_image_desc 
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



