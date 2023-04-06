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

	Source code beautified by beautify.pl on 2020-01-02 19:48:01	$Id: $
}

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "J_JM_GLOBALS.4gl" 

# Purpose - Job Inquiry

GLOBALS 
	DEFINE 
	formname CHAR(15), 

	pv_type_code LIKE job.type_code, 
	pv_wildcard CHAR(1), 
	pr_job RECORD LIKE job.*, 
	pr_jmparms RECORD LIKE jmparms.*, 
	pr_customer RECORD LIKE customer.*, 
	pr_salesperson RECORD LIKE salesperson.*, 
	pr_responsible RECORD LIKE responsible.*, 
	pr_job_desc RECORD LIKE job_desc.*, 
	pr_rec_kandoouser RECORD LIKE kandoouser.*, 
	pr_user_scan_code LIKE kandoouser.acct_mask_code, 
	pr_jobtype RECORD LIKE jobtype.*, 
	pr_resp_name_text LIKE responsible.name_text 
END GLOBALS 

MAIN 
	#Initial UI Init
	CALL setModuleId("J12") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	CALL user_security(glob_rec_kandoouser.cmpy_code, glob_rec_kandoouser.sign_on_code) 

	RETURNING pr_rec_kandoouser.acct_mask_code, 
	pr_user_scan_code 
	SELECT jmparms.* INTO pr_jmparms.* FROM jmparms 
	WHERE jmparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND jmparms.key_code = "1" 
	IF status = notfound THEN 
		LET msgresp = kandoomsg("J",7002,"") 
		#7002 " Must SET up JM Parameters first in JZP"
		EXIT program 
	END IF 
	OPEN WINDOW j131 with FORM "J131" -- alch kd-747 
	CALL winDecoration_j("J131") -- alch kd-747 
	IF num_args() > 0 THEN 
		IF select_job() THEN 
			CALL display_job() 
			LET pv_type_code = pr_job.type_code 
			CALL disp_report_codes() 
			CALL query() 
		END IF 
	ELSE 
		CALL query() 
	END IF 
	CLOSE WINDOW j131 
END MAIN 


FUNCTION select_job() 
	DEFINE 
	where_text1, 
	query_text CHAR(1200) 

	CLEAR FORM 
	DISPLAY BY NAME 
	pr_jmparms.prompt1_text, 
	pr_jmparms.prompt2_text, 
	pr_jmparms.prompt3_text, 
	pr_jmparms.prompt4_text, 
	pr_jmparms.prompt5_text, 
	pr_jmparms.prompt6_text, 
	pr_jmparms.prompt7_text, 
	pr_jmparms.prompt8_text 
	WHILE true 
		IF num_args() > 0 THEN 
			IF int_flag OR quit_flag THEN 
				EXIT program 
			ELSE 
				LET where_text1 = " job_code = \"",arg_val(1) clipped, "\"" 
			END IF 
		ELSE 
			LET msgresp = kandoomsg("U",1001," ") 
			#1001 " Enter selection criteria - ESC TO begin search "
			LET pv_type_code = NULL 
			LET pv_wildcard = "N" 
			CONSTRUCT BY NAME where_text1 ON job.job_code, 
			job.title_text, 
			job.type_code, 
			job.cust_code, 
			customer.name_text, 
			job.sale_code, 
			job.est_start_date, 
			job.review_date, 
			job.val_date, 
			job.est_end_date, 
			job.act_start_date, 
			job.act_end_date, 
			job.contract_text, 
			job.contract_date, 
			job.contract_amt, 
			job.locked_ind, 
			job.finish_flag, 
			job.report_text, 
			job.resp_code, 
			job.internal_flag, 
			job.report1_text, 
			job.report2_text, 
			job.report3_text, 
			job.report4_text, 
			job.report5_text, 
			job.report6_text, 
			job.report7_text, 
			job.report8_text 
				BEFORE CONSTRUCT 
					CALL publish_toolbar("kandoo","J12","const-job_job_code-1") -- alch kd-506 
				ON ACTION "WEB-HELP" -- albo kd-373 
					CALL onlinehelp(getmoduleid(),null) 
				AFTER FIELD type_code 
					IF field_touched(type_code) THEN 
						LET pv_type_code = get_fldbuf(type_code) 
					END IF 
					IF pv_type_code IS NOT NULL THEN 
						CALL disp_report_codes() 
					END IF 
				BEFORE FIELD report1_text 
					IF pv_type_code IS NOT NULL THEN 
						IF pv_wildcard != "Y" THEN 
							IF pr_jobtype.prompt1_ind = 5 THEN 
								NEXT FIELD report2_text 
							END IF 
						ELSE 
							IF pr_jmparms.prompt1_ind = 5 THEN 
								NEXT FIELD report2_text 
							END IF 
						END IF 
					ELSE 
						IF pr_jmparms.prompt1_ind = 5 THEN 
							NEXT FIELD report2_text 
						END IF 
					END IF 
				BEFORE FIELD report2_text 
					IF pv_type_code IS NOT NULL THEN 
						IF pv_wildcard != "Y" THEN 
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
					IF pv_type_code IS NOT NULL THEN 
						IF pv_wildcard != "Y" THEN 
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
					IF pv_type_code IS NOT NULL THEN 
						IF pv_wildcard != "Y" THEN 
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
					IF pv_type_code IS NOT NULL THEN 
						IF pv_wildcard != "Y" THEN 
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
					IF pv_type_code IS NOT NULL THEN 
						IF pv_wildcard != "Y" THEN 
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
					IF pv_type_code IS NOT NULL THEN 
						IF pv_wildcard != "Y" THEN 
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
					IF pv_type_code IS NOT NULL THEN 
						IF pv_wildcard != "Y" THEN 
							IF pr_jobtype.prompt8_ind = 5 THEN 
								EXIT CONSTRUCT 
							END IF 
						ELSE 
							IF pr_jmparms.prompt8_ind = 5 THEN 
								EXIT CONSTRUCT 
							END IF 
						END IF 
					ELSE 
						IF pr_jmparms.prompt8_ind = 5 THEN 
							EXIT CONSTRUCT 
						END IF 
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
							DISPLAY BY NAME pr_job.title_text 
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
							DISPLAY pr_job.cust_code TO job.cust_code 
							DISPLAY pr_customer.name_text TO customer.name_text 
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
							NEXT FIELD est_start_date 
						WHEN infield(resp_code) 
							LET pr_job.resp_code = show_resp(glob_rec_kandoouser.cmpy_code) 
							SELECT name_text 
							INTO pr_resp_name_text 
							FROM responsible 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
							resp_code = pr_job.resp_code 
							DISPLAY BY NAME pr_job.resp_code 
							DISPLAY pr_resp_name_text TO resp_name_text 
							NEXT FIELD internal_flag 
					END CASE 
				ON KEY (control-w) 
					CALL kandoohelp("") 
			END CONSTRUCT 
			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
				RETURN false 
			END IF 
		END IF 

		INITIALIZE pr_job_desc.* TO NULL 
		LET query_text = 
		"SELECT job.*,", 
		"customer.name_text,", 
		"jobtype.type_text,", 
		"salesperson.name_text", 
		" FROM job,", 
		"customer,", 
		"jobtype,", 
		"salesperson", 
		" WHERE ",where_text1 clipped, 
		" AND job.cmpy_code = \"", glob_rec_kandoouser.cmpy_code, "\"", 
		" AND customer.cust_code = job.cust_code ", 
		" AND customer.cmpy_code = \"", glob_rec_kandoouser.cmpy_code, "\"", 
		" AND salesperson.sale_code = job.sale_code ", 
		" AND salesperson.cmpy_code = \"", glob_rec_kandoouser.cmpy_code, "\"", 
		" AND jobtype.cmpy_code = \"", glob_rec_kandoouser.cmpy_code, "\"", 
		" AND jobtype.type_code = job.type_code ", 
		" AND (job.acct_code matches \"",pr_user_scan_code, 
		"\" OR ", "job.locked_ind <= \"1\")" 
		LET query_text = query_text clipped, " ORDER BY job.job_code" 
		DISPLAY query_text 
		PREPARE q_1 FROM query_text 
		DECLARE q_2 SCROLL CURSOR FOR q_1 
		OPEN q_2 
		FETCH q_2 INTO pr_job.*, 
		pr_customer.name_text, 
		pr_jobtype.type_text, 
		pr_salesperson.name_text 
		IF status = notfound THEN 
			LET msgresp = kandoomsg("U",9506,"") 
			#9506 " No Jobs Found TO Satisfy Criteria - Re SELECT"
			IF num_args() > 0 THEN 
				SLEEP 2 
				RETURN false 
			END IF 
		ELSE 
			EXIT WHILE 
		END IF 
	END WHILE 
	RETURN true 
END FUNCTION 


FUNCTION query() 
	DEFINE 
	exist SMALLINT 

	IF num_args() = 0 THEN 
		LET exist = false 
	ELSE 
		LET exist = true 
	END IF 
	MENU " Job" 
		BEFORE MENU 
			HIDE option "Next" 
			HIDE option "Previous" 
			HIDE option "Detail" 
			HIDE option "First" 
			HIDE option "Last" 
			CALL publish_toolbar("kandoo","J12","menu-job-1") -- alch kd-506 
		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 
		COMMAND "Query" " Search FOR jobs" 
			IF num_args() = 0 THEN 
				IF select_job() THEN 
					CALL get_resp() 
					LET exist = true 
					SHOW option "Next" 
					SHOW option "Previous" 
					SHOW option "Detail" 
					SHOW option "First" 
					SHOW option "Last" 
				ELSE 
					LET exist = false 
					HIDE option "Next" 
					HIDE option "Previous" 
					HIDE option "Detail" 
					HIDE option "First" 
					HIDE option "Last" 
				END IF 
			END IF 
		COMMAND KEY ("N",f21) "Next" " DISPLAY next selected job" 
			IF NOT exist THEN 
				NEXT option "Query" 
			ELSE 
				FETCH NEXT q_2 INTO pr_job.*, 
				pr_customer.name_text, 
				pr_jobtype.type_text 

				IF status <> notfound THEN 
					CALL get_resp() 

				ELSE 
					ERROR "You have reached the END of the jobs selected" 
				END IF 
			END IF 
		COMMAND KEY ("P",f19) "Previous" " DISPLAY previous selected job" 
			IF NOT exist THEN 
				NEXT option "Query" 
			ELSE 
				FETCH previous q_2 INTO pr_job.*, 
				pr_customer.name_text, 
				pr_jobtype.type_text 

				IF status <> notfound THEN 
					CALL get_resp() 

				ELSE 
					ERROR "You have reached the start of the jobs selected" 
				END IF 
			END IF 
		COMMAND KEY ("D",f20) "Detail" " View job details" 
			CALL job_detail_inquiry(glob_rec_kandoouser.cmpy_code, pr_job.job_code) 
		COMMAND KEY ("F",f18) "First" " DISPLAY first job in the selected list" 
			IF NOT exist THEN 
				NEXT option "Query" 
			ELSE 
				FETCH FIRST q_2 INTO pr_job.*, 
				pr_customer.name_text, 
				pr_jobtype.type_text 
				IF status <> notfound THEN 
					CALL get_resp() 

				ELSE 
					ERROR "You have reached the start of the jobs selected" 
				END IF 
			END IF 
		COMMAND KEY ("L",f22) "Last" " DISPLAY last job in the selected list" 
			IF NOT exist THEN 
				NEXT option "Query" 
			ELSE 
				FETCH LAST q_2 INTO pr_job.*, 
				pr_customer.name_text, 
				pr_jobtype.type_text 
				IF status <> notfound THEN 
					CALL get_resp() 

				ELSE 
					ERROR "You have reached the END of the jobs selected" 
				END IF 
			END IF 
		COMMAND KEY(interrupt,"E") "Exit" " RETURN TO menus" 
			EXIT MENU 
		COMMAND KEY (control-w) 
			CALL kandoohelp("") 
	END MENU 
END FUNCTION 


FUNCTION display_job() 

	DISPLAY 
	pr_job.job_code, 
	pr_job.title_text, 
	pr_job.type_code, 
	pr_jobtype.type_text, 
	pr_job.cust_code, 
	pr_customer.name_text, 
	pr_job.sale_code, 
	pr_salesperson.name_text, 
	pr_job.est_start_date, 
	pr_job.est_end_date, 
	pr_job.review_date, 
	pr_job.val_date, 
	pr_job.act_start_date, 
	pr_job.act_end_date, 
	pr_job.contract_text, 
	pr_job.contract_date, 
	pr_job.contract_amt, 
	pr_job.locked_ind, 
	pr_job.finish_flag, 
	pr_job.resp_code, 

	pr_responsible.name_text, 
	pr_job.internal_flag, 
	pr_job.report_text, 
	pr_job.report1_text, 
	pr_job.report2_text, 
	pr_job.report3_text, 
	pr_job.report4_text, 
	pr_job.report5_text, 
	pr_job.report6_text, 
	pr_job.report7_text, 
	pr_job.report8_text 

	TO job.job_code, 
	job.title_text, 
	job.type_code, 
	jobtype.type_text, 
	job.cust_code, 
	customer.name_text, 
	job.sale_code, 
	salesperson.name_text, 
	job.est_start_date, 
	job.est_end_date, 
	job.review_date, 
	job.val_date, 
	job.act_start_date, 
	job.act_end_date, 
	job.contract_text, 
	job.contract_date, 
	job.contract_amt, 
	job.locked_ind, 
	job.finish_flag, 
	job.resp_code, 

	formonly.resp_name_text, 

	job.internal_flag, 
	job.report_text, 
	job.report1_text, 
	job.report2_text, 
	job.report3_text, 
	job.report4_text, 
	job.report5_text, 
	job.report6_text, 
	job.report7_text, 
	job.report8_text 


END FUNCTION 

FUNCTION job_entry(p_cmpy, pr_job_code) 
	DEFINE 
	p_cmpy LIKE company.cmpy_code, 
	pr_job_code LIKE job.job_code, 
	job_found_status SMALLINT 

	CLEAR FORM 
	SELECT job.* 
	INTO pr_job.* 
	FROM job 
	WHERE cmpy_code = p_cmpy 
	AND job_code = pr_job_code 
	LET job_found_status = status 
	WHILE job_found_status 
		INPUT BY NAME pr_job.job_code WITHOUT DEFAULTS 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","J12","input-pr_job-1") -- alch kd-506 
			ON ACTION "WEB-HELP" -- albo kd-373 
				CALL onlinehelp(getmoduleid(),null) 
			ON KEY (control-b) 
				LET pr_job.job_code = showujobs(p_cmpy, pr_user_scan_code) 
				NEXT FIELD job_code 
			ON KEY (control-w) 
				CALL kandoohelp("") 
		END INPUT 
		IF int_flag OR quit_flag THEN 
			CLEAR FORM 
			INITIALIZE pr_job.* TO NULL 
			RETURN pr_job.* 
		END IF 
		SELECT job.* 
		INTO pr_job.* 
		FROM job 
		WHERE cmpy_code = p_cmpy 
		AND job_code = pr_job.job_code 
		AND (acct_code matches pr_user_scan_code 
		OR locked_ind <= "1") 
		LET job_found_status = status 
		IF job_found_status THEN 
			LET msgresp = kandoomsg("J",9509,"") 
			#9509 Invalid Job Code;  Try Window.
		END IF 
	END WHILE 
	DISPLAY BY NAME pr_job.job_code, 
	pr_job.title_text 

	RETURN pr_job.* 
END FUNCTION 


FUNCTION disp_report_codes() 


	SELECT jobtype.* 
	INTO pr_jobtype.* 
	FROM jobtype 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
	type_code = pv_type_code 

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


		IF pr_jobtype.prompt1_ind != 5 OR 
		pr_jobtype.prompt2_ind != 5 OR 
		pr_jobtype.prompt3_ind != 5 OR 
		pr_jobtype.prompt4_ind != 5 OR 
		pr_jobtype.prompt5_ind != 5 OR 
		pr_jobtype.prompt6_ind != 5 OR 
		pr_jobtype.prompt7_ind != 5 OR 
		pr_jobtype.prompt8_ind != 5 THEN 

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

	ELSE 
		LET pv_wildcard = "Y" 
	END IF 

END FUNCTION 

FUNCTION get_resp() 

	LET pr_responsible.name_text = " " 

	SELECT name_text 
	INTO pr_responsible.name_text 
	FROM responsible 
	WHERE responsible.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND responsible.resp_code = pr_job.resp_code 

	CALL display_job() 

	LET pv_type_code = pr_job.type_code 
	CALL disp_report_codes() 

END FUNCTION 
