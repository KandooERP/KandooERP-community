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
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "../jm/J_JM_GLOBALS.4gl"
GLOBALS "../jm/J3_GROUP_GLOBALS.4gl" 
GLOBALS "../jm/J3C_GLOBALS.4gl"
GLOBALS 
	DEFINE 
	formname CHAR(15), 
	pr_menunames RECORD LIKE menunames.*, 
	pr_job RECORD LIKE job.*, 
	pr_company RECORD LIKE company.*, 
	pr_activity RECORD LIKE activity.*, 
	pr_customer RECORD LIKE customer.*, 
	pr_jobledger RECORD LIKE jobledger.*, 
	pr_salesperson RECORD LIKE salesperson.*, 
	pr_jmparms RECORD LIKE jmparms.*, 
	pr_rec_kandoouser RECORD LIKE kandoouser.*, 
	pr_user_scan_code LIKE kandoouser.acct_mask_code, 
	pr_resp_name_text LIKE responsible.name_text, 
	ans CHAR(1), 
	where_part, query_text CHAR(3400), 
	pr_option1, pr_option2 CHAR(100), 
	pr_jobtype RECORD LIKE jobtype.*, 
	where_text_2 CHAR(800), 
	err_message CHAR(40), 
	job_markup_per LIKE job.markup_per, 
--	glob_rec_rmsreps.report_width_num SMALLINT, 
--	glob_rec_rmsreps.page_num LIKE rmsreps.page_num, 
--	glob_rec_rmsreps.page_length_num LIKE rmsreps.page_length_num, 
	err_flag, idx, scrn, cnt SMALLINT, 
	pv_type_code LIKE job.type_code, 

	pv_wildcard CHAR(1), 
	pr_zero_act_ind, pr_zero_job_ind SMALLINT, 
	tot_act_cost_amt, 
	tot_act_bill_amt, 
	tot_job_cost_amt, 
	tot_job_bill_amt, 
	tot_rpt_cost_amt, 
	tot_rpt_bill_amt LIKE activity.act_bill_amt 

END GLOBALS 
###########################################################################
# MAIN
#
# J3C.4gl Pre-bill REPORT
# Modified FROM J34 Pre-invoice REPORT
###########################################################################
MAIN 

	#Initial UI Init
	CALL setModuleId("J3C") -- albo 
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
	WHERE jmparms.cmpy_code = glob_rec_kandoouser.cmpy_code AND 
	jmparms.key_code = "1" 

--	SELECT * 
--	INTO pr_company.* 
--	FROM company 
--	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF status = notfound THEN 
		ERROR " Must SET up JM Parameters first in JZP" 
		SLEEP 5 
		EXIT program 
	END IF 


	CLEAR screen 

	OPTIONS MENU line 1, MESSAGE line 1 
	OPEN WINDOW j131 with FORM "J131" -- alch kd-747 
	CALL winDecoration_j("J131") -- alch kd-747 

	MENU "Pre-bill REPORT" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","J3C","menu-pre_bill_rep-1") -- alch kd-506 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND "Run Report" "SELECT criteria AND PRINT REPORT" 
			CALL J3C_rpt_query() 
			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
				NEXT option "Run Report" 
			ELSE 
				NEXT option "Print Manager" 
			END IF 

		ON ACTION "Print Manager"		#COMMAND KEY ("P",f11) "Print" "Print OR view using RMS"
			CALL run_prog("URS","","","","") 
			NEXT option "Exit" 

		COMMAND KEY(interrupt,"E") "Exit" "Exit the program" 
			EXIT MENU 
			
	END MENU 

	CLOSE WINDOW j131 
	CLEAR screen 
END MAIN 
###########################################################################
# MAIN
#
# J3C.4gl Pre-bill REPORT
# Modified FROM J34 Pre-invoice REPORT
###########################################################################


###########################################################################
# FUNCTION J3C_rpt_query()
#
# 
###########################################################################
FUNCTION J3C_rpt_query()
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx] 
	DEFINE pr_output CHAR(60)
	DEFINE pv_trans SMALLINT 
	DEFINE num_trans SMALLINT
	
	LET msgresp = kandoomsg("U",1001,"") 

	DISPLAY BY NAME pr_jmparms.prompt1_text, 
	pr_jmparms.prompt2_text, 
	pr_jmparms.prompt3_text, 
	pr_jmparms.prompt4_text, 
	pr_jmparms.prompt5_text, 
	pr_jmparms.prompt6_text, 
	pr_jmparms.prompt7_text, 
	pr_jmparms.prompt8_text 

	LET pv_type_code = NULL 
	LET pv_wildcard = "N" 

	CONSTRUCT BY NAME where_part ON 
	job.job_code, 
	job.title_text, 
	job.type_code, 
	job.cust_code, 
	customer.name_text, 
	salesperson.sale_code, 
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
	job.report_text, 
	job.resp_code, 
	job.report1_text, 
	job.report2_text, 
	job.report3_text, 
	job.report4_text, 
	job.report5_text, 
	job.report6_text, 
	job.report7_text, 
	job.report8_text 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","J3C","const-job_job_code-2") -- alch kd-506 
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
					LET pr_job.job_code = showujobs(glob_rec_kandoouser.cmpy_code, pr_user_scan_code) 
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
					NEXT FIELD report1_text 
			END CASE 

	END CONSTRUCT 

	IF int_flag 
	OR quit_flag THEN 
		EXIT program 
	END IF 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (where_part IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"J3C_rpt_list",where_part, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT J3C_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET where_part = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("J3C_rpt_list")].sel_text
	#------------------------------------------------------------

	LET query_text = 
	"SELECT unique job.* , customer.*, salesperson.*", 
	" FROM job, customer, salesperson WHERE ", 
	where_part clipped, 
	" AND job.cmpy_code = \"", glob_rec_kandoouser.cmpy_code, "\"", 
	" AND (job.acct_code matches \"",pr_user_scan_code,"\" OR locked_ind = \"1\" )", 
	" AND customer.cust_code = job.cust_code ", 
	" AND customer.cmpy_code = \"", glob_rec_kandoouser.cmpy_code, "\"", 
	" AND salesperson.sale_code = job.sale_code ", 
	" AND salesperson.cmpy_code = \"", glob_rec_kandoouser.cmpy_code, "\"", 
	" ORDER BY customer.cust_code, job_code " 

	IF int_flag OR quit_flag THEN 
		RETURN 
	END IF 

	# Option TO exclude OPEN jobs without any transaction
	#   OPEN WINDOW w1 AT 10,10 with 2 rows, 50 columns
	#      ATTRIBUTE(border, MESSAGE line first)     -- alch KD-747
	# "Exclude jobs without transactions?"
	LET msgresp = kandoomsg("J",1564,"") 
	IF upshift(msgresp) <> "N" THEN 
		LET pr_zero_job_ind = true 
	ELSE 
		LET pr_zero_job_ind = false 
	END IF 
	#   CLOSE WINDOW w1     -- alch KD-747

	# Option TO exclude activities without any transaction
	#   OPEN WINDOW w2 AT 10,10 with 2 rows, 50 columns
	#      ATTRIBUTE(border, MESSAGE line first)     -- alch KD-747
	# "Exclude activities without transaction?"
	LET msgresp = kandoomsg("J",1565,"") 
	IF upshift(msgresp) <> "N" THEN 
		LET pr_zero_act_ind = true 
	ELSE 
		LET pr_zero_act_ind = false 
	END IF 
	#   CLOSE WINDOW w2     -- alch KD-747
	# S T A R T R E P O R T J3C_rpt_list TO pr_output 
	#	OPEN WINDOW wfJM AT 10,10 with 1 rows, 50 columns
	#      ATTRIBUTE(border, MESSAGE line first)     -- alch KD-747
	PREPARE q_1 FROM query_text 
	DECLARE c_1 CURSOR FOR q_1 
	LET tot_rpt_cost_amt = 0 
	LET tot_rpt_bill_amt = 0 

	FOREACH c_1 INTO pr_job.*, pr_customer.* 
		DECLARE act_curs CURSOR FOR 
		SELECT activity.* 
		FROM activity 
		WHERE cmpy_code = pr_job.cmpy_code 
		AND job_code = pr_job.job_code 
		AND act_cost_amt != post_cost_amt 
		AND finish_flag = "N" 
		FOREACH act_curs INTO pr_activity.* 
			# IF exclude the jobs without any transaction
			IF pr_zero_job_ind THEN 
				##IF exclude the activities without any transaction
				IF pr_zero_act_ind THEN 
					## Check IF the current activity has transactions
					SELECT count(*) INTO num_trans 
					FROM jobledger 
					WHERE cmpy_code = pr_activity.cmpy_code 
					AND job_code = pr_activity.job_code 
					AND var_code = pr_activity.var_code 
					AND activity_code = pr_activity.activity_code 
					IF num_trans > 0 THEN 
						#---------------------------------------------------------
						OUTPUT TO REPORT J3C_rpt_list(l_rpt_idx,
						pr_job.*, pr_activity.*, pr_customer.cust_code, pr_customer.name_text) 
						IF NOT rpt_int_flag_handler2("Job:",pr_job.title_text, NULL,l_rpt_idx) THEN
							EXIT FOREACH 
						END IF 
						#---------------------------------------------------------
					END IF 
				ELSE 
					SELECT count(*) INTO pv_trans 
					FROM jobledger 
					WHERE cmpy_code = pr_job.cmpy_code 
					AND job_code = pr_job.job_code 
					IF pv_trans > 0 THEN 
						#---------------------------------------------------------
						OUTPUT TO REPORT J3C_rpt_list(l_rpt_idx,
						pr_job.*, pr_activity.*, pr_customer.cust_code, pr_customer.name_text) 
						IF NOT rpt_int_flag_handler2("Job:",pr_job.title_text, NULL,l_rpt_idx) THEN
							EXIT FOREACH 
						END IF 
						#---------------------------------------------------------
					END IF 
				END IF 
			ELSE 
				##Print all OPEN jobs
				#---------------------------------------------------------
				OUTPUT TO REPORT J3C_rpt_list(l_rpt_idx,
				pr_job.*, pr_activity.*, pr_customer.cust_code, pr_customer.name_text) 
				IF NOT rpt_int_flag_handler2("Job:",pr_job.title_text, NULL,l_rpt_idx) THEN
					EXIT FOREACH 
				END IF 
				#---------------------------------------------------------
			END IF 
		END FOREACH 
	END FOREACH 
	
	#------------------------------------------------------------
	FINISH REPORT J3C_rpt_list
	CALL rpt_finish("J3C_rpt_list")
	#------------------------------------------------------------

	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 	
END FUNCTION 
###########################################################################
# END FUNCTION J3C_rpt_query()
###########################################################################


###########################################################################
# FUNCTION disp_report_codes()
#
# 
###########################################################################
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
###########################################################################
# END FUNCTION disp_report_codes()
#
# 
###########################################################################


###########################################################################
# REPORT J3C_rpt_list(p_rpt_idx,pr_job, pr_activity, pr_cust_code, pr_cust_name)
#
# 
###########################################################################
REPORT J3C_rpt_list(p_rpt_idx,pr_job, pr_activity, pr_cust_code, pr_cust_name) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE pr_job RECORD LIKE job.* 
	DEFINE pr_activity RECORD LIKE activity.* 
	DEFINE pr_var_title LIKE jobvars.title_text 
	DEFINE pr_cust_code LIKE customer.cust_code 
	DEFINE pr_cust_name LIKE customer.name_text 
	DEFINE pr_jobledger RECORD LIKE jobledger.* 
	DEFINE line1 CHAR(132) 
	DEFINE line2 CHAR(132)
	DEFINE rpt_note CHAR(40) 
	DEFINE pv_person_code LIKE person.person_code 
	DEFINE offset1 SMALLINT
	DEFINE offset2 SMALLINT
	DEFINE pv_trans SMALLINT
	 
	DEFINE str CHAR (4000) 

	OUTPUT 

	ORDER external BY pr_cust_code, pr_job.job_code, pr_activity.var_code, pr_activity.activity_code 

	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  
--			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
--			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text 
--			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  

		BEFORE GROUP OF pr_cust_code 
			SKIP TO top OF PAGE 

		BEFORE GROUP OF pr_job.job_code 
			SKIP TO top OF PAGE 
			LET tot_job_cost_amt = 0 
			LET tot_job_bill_amt = 0 

		BEFORE GROUP OF pr_activity.var_code 
			SKIP TO top OF PAGE 
			SELECT jobvars.title_text INTO pr_var_title 
			FROM jobvars 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND job_code = pr_activity.job_code 
			AND var_code = pr_activity.var_code 
			IF status = notfound THEN 
				LET pr_var_title = "No variation" 
			END IF 
			PRINT "Customer Code :", 
			COLUMN 20, pr_cust_code, 
			COLUMN 35, pr_cust_name 
			PRINT "Job Code :", 
			COLUMN 20, pr_job.job_code, 
			COLUMN 35, pr_job.title_text 
			PRINT "Variation Code :", 
			COLUMN 20, pr_activity.var_code USING "<<<<<<&", 
			COLUMN 35, pr_var_title 
			PRINT "________________________________________", 
			"________________________________________", 
			"___________________" 
			PRINT 
			PRINT "Date", 
			COLUMN 10, "Type", 
			COLUMN 16, "By", 
			COLUMN 20, "Reference", 
			COLUMN 37, "QTY", 
			COLUMN 48, "Cost", 
			COLUMN 65, "Bill", 
			COLUMN 75, "description" 
			PRINT "________________________________________", 
			"________________________________________", 
			"___________________" 

		BEFORE GROUP OF pr_activity.activity_code 
			SKIP 1 line 
			PRINT "Activity Code :", 
			COLUMN 20, pr_activity.activity_code, 
			COLUMN 35, pr_activity.title_text 
			LET tot_act_cost_amt = 0 
			LET tot_act_bill_amt = 0 

		ON EVERY ROW 

--			DISPLAY "EXIT: disabled code because of <Anton Dickinson> ecp issue with OUTER" 
--			DISPLAY "see jm/J3C.4gl" 
--			EXIT program (1) 


			LET str = 
			" SELECT distinct JL.*, TH.person_code ", 
			" INTO pr_jobledger.*, pv_person_code ", 
			" FROM jobledger JL, OUTER (ts_detail TD, ts_head TH) ", 
			" WHERE JL.cmpy_code = ", pr_activity.cmpy_code, 
			" AND JL.job_code = ", pr_activity.job_code, 
			" AND JL.var_code = ", pr_activity.var_code, 
			" AND JL.activity_code = ",pr_activity.activity_code, 
			" AND TD.cmpy_code = ", pr_activity.cmpy_code, 
			" AND TD.job_code = ", pr_activity.job_code, 
			" AND TD.var_code = ", pr_activity.var_code, 
			" AND TD.activity_code = ", pr_activity.activity_code, 
			" AND JL.trans_source_num = TD.ts_num ", 
			" AND TD.ts_num = TH.ts_num ", 
			" AND TD.cmpy_code = ", pr_activity.cmpy_code, 
			" AND NOT exists (SELECT * ", 
			" FROM resbill ", 
			" WHERE cmpy_code = ", pr_activity.cmpy_code, 
			" AND job_code = ", pr_activity.job_code, 
			" AND var_code = ", pr_activity.var_code, 
			" AND activity_code = ", pr_activity.activity_code, 
			" AND seq_num = JL.seq_num) ", 
			" ORDER BY trans_date " 

			PREPARE kert FROM str 
			DECLARE ledg_curs CURSOR FOR kert 

			FOREACH ledg_curs 
				PRINT pr_jobledger.trans_date USING "dd/mm/yy", 
				COLUMN 12, pr_jobledger.trans_type_ind, 
				COLUMN 16, pv_person_code clipped, 
				COLUMN 20, pr_jobledger.trans_source_num USING "--------", 
				COLUMN 31, pr_jobledger. trans_qty USING "---,--&.&&" clipped, 
				COLUMN 41, pr_jobledger.trans_amt USING "--------.--", 
				COLUMN 58, pr_jobledger.charge_amt USING "--------.--", 
				COLUMN 75, pr_jobledger.desc_text clipped 
				LET tot_act_cost_amt = tot_act_cost_amt + pr_jobledger.trans_amt 
				LET tot_act_bill_amt = tot_act_bill_amt + pr_jobledger.charge_amt 
			END FOREACH 

		AFTER GROUP OF pr_activity.activity_code 
			PRINT COLUMN 42, "----------", COLUMN 59, "----------" 
			PRINT COLUMN 20, "Activity Total", COLUMN 41, tot_act_cost_amt USING "--------.--", COLUMN 58, tot_act_bill_amt USING "--------.--" 
			PRINT COLUMN 42, "__________", COLUMN 59, "__________" 
			LET tot_job_cost_amt = tot_job_cost_amt + tot_act_cost_amt 
			LET tot_job_bill_amt = tot_job_bill_amt + tot_act_bill_amt 
	
		AFTER GROUP OF pr_job.job_code 
			SKIP 3 line 
			PRINT COLUMN 42, "----------", COLUMN 59, "----------" 
			PRINT COLUMN 20, "Job Total", COLUMN 41, tot_job_cost_amt USING "--------.--", COLUMN 58, tot_job_bill_amt USING "--------.--" 
			PRINT COLUMN 42, "__________", COLUMN 59, "__________" 
			LET tot_rpt_cost_amt = tot_rpt_cost_amt + tot_job_cost_amt 
			LET tot_rpt_bill_amt = tot_rpt_bill_amt + tot_job_bill_amt 
			####      LET tot_rpt_bill_amt = tot_rpt_cost_amt + tot_job_bill_amt
			####  Wrong !
	
		ON LAST ROW 
			IF pr_zero_job_ind THEN 
				LET pr_option1 = "Active jobs" 
			ELSE 
				LET pr_option1 = "All jobs" 
			END IF 

			IF pr_zero_act_ind THEN 
				LET pr_option2 = "Exclude zero transaction activities" 
			ELSE 
				LET pr_option2 = "All activities" 
			END IF 
			SKIP 3 LINES 
			PRINT COLUMN 42, "----------", COLUMN 59, "----------" 
			PRINT COLUMN 20, "Report Total", COLUMN 41, tot_rpt_cost_amt USING "--------.--", COLUMN 58, tot_rpt_bill_amt USING "--------.--" 
			PRINT COLUMN 42, "==========", COLUMN 59, "==========" 
			SKIP 3 LINES 

			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
				PRINT COLUMN 25, pr_option1 clipped 
				PRINT COLUMN 25, pr_option2 clipped 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = pageno

END REPORT 
###########################################################################
# END REPORT J3C_rpt_list(p_rpt_idx,pr_job, pr_activity, pr_cust_code, pr_cust_name)
###########################################################################