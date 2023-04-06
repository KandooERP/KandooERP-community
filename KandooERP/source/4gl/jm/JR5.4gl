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
GLOBALS "../jm/JR_GROUP_GLOBALS.4gl"  
GLOBALS "../jm/JR5_GLOBALS.4gl"

#Module Scope Variables
DEFINE 
pr_jobtype RECORD LIKE jobtype.*, 
pr_jmparms RECORD LIKE jmparms.*, 
pr_rec_kandoouser RECORD LIKE kandoouser.*, 
pr_company RECORD LIKE company.*, 
pr_user_scan_code LIKE kandoouser.acct_mask_code, 
pr_wildcard CHAR(1), 
tot_act_chg_amt, 
tot_act_bdgt_amt, 
tot_act_cost_amt, 
tot_act_var_amt, 
tot_act_apply_amt, 
tot_act_apply_cost_amt, 
tot_act_margin_amt, 
tot_job_chg_amt, 
tot_job_bdgt_amt, 
tot_job_cost_amt, 
tot_job_var_amt, 
tot_job_apply_amt, 
tot_job_apply_cost_amt, 
tot_job_margin_amt, 
tot_rpt_chg_amt, 
tot_rpt_bdgt_amt, 
tot_rpt_cost_amt, 
tot_rpt_var_amt, 
tot_rpt_apply_amt, 
tot_rpt_apply_cost_amt, 
tot_rpt_margin_amt LIKE activity.act_bill_amt, 
rpt_wid , 
pr_zero_act_ind, 
pr_zero_job_ind SMALLINT, 
tot_act_cost_per, 
tot_act_rev_per, 
tot_job_cost_per, 
tot_job_rev_per, 
tot_rpt_cost_per, 
tot_rpt_rev_per INTEGER, 
pr_option1, pr_option2 CHAR(100) 

# Purpose - Job Revenue AND Cost Analysis Report
MAIN 
	DEFINE l_msgresp LIKE language.yes_flag

	#Initial UI Init
	CALL setModuleId("JR5") -- albo 
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
		LET l_msgresp = kandoomsg("J",7505,"") 
		#7505" Job Management Parameters NOT found - Refer Menu JZP "
		EXIT program 
	END IF 
	SELECT * 
	INTO pr_company.* 
	FROM company 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
	 
	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN "1" #UI/MENU Mode 
		OPEN WINDOW J318 with FORM "J318" -- alch kd-747 
		CALL winDecoration_j("J318") -- alch kd-747 
		DISPLAY BY NAME pr_jmparms.prompt1_text, 
		pr_jmparms.prompt2_text, 
		pr_jmparms.prompt3_text, 
		pr_jmparms.prompt4_text, 
		pr_jmparms.prompt5_text, 
		pr_jmparms.prompt6_text, 
		pr_jmparms.prompt7_text, 
		pr_jmparms.prompt8_text 
		MENU " Job Revenue AND Cost Analysis Report" 
			BEFORE MENU 
				CALL publish_toolbar("kandoo","JR5","menu-job_revenue-1") -- alch kd-506
				CALL rpt_rmsreps_reset(NULL)
				CALL JR5_rpt_process(JR5_rpt_query())  
				 
			ON ACTION "WEB-HELP" -- albo kd-373 
				CALL onlinehelp(getmoduleid(),null)
				 
			ON ACTION "REPORT" --COMMAND "Run" " Enter selection criteria AND generate REPORT"
				CALL rpt_rmsreps_reset(NULL)
				CALL JR5_rpt_process(JR5_rpt_query())  
	
			ON ACTION "Print Manager" 		#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
				CALL run_prog("URS","","","","") 
	
			COMMAND KEY("E",interrupt)"Exit" " Exit TO menus" 
				EXIT MENU 
		END MENU 
	
		CLOSE WINDOW J318 
	 
		WHEN "2" #Background Process with rmsreps.report_code
			CALL JR5_rpt_process(NULL)  

		WHEN "3" #Only create query-where-part
			OPEN WINDOW J318 with FORM "J318" 
			CALL winDecoration_j("J318") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(JR5_rpt_query()) #save where clause in env 
			CLOSE WINDOW J318 
			
		WHEN "4" #Background Process with SQL WHERE ARGUMENT
			CALL JR5_rpt_process(get_url_sel_text())
	END CASE 	
END MAIN 


FUNCTION JR5_rpt_query() 
	DEFINE l_where_text STRING
	DEFINE pr_type_code LIKE job.type_code 
	DEFINE l_msgresp LIKE language.yes_flag
	
	CLEAR FORM 
	DISPLAY BY NAME pr_jmparms.prompt1_text, 
	pr_jmparms.prompt2_text, 
	pr_jmparms.prompt3_text, 
	pr_jmparms.prompt4_text, 
	pr_jmparms.prompt5_text, 
	pr_jmparms.prompt6_text, 
	pr_jmparms.prompt7_text, 
	pr_jmparms.prompt8_text 
	LET pr_wildcard = "N" 
	
	LET l_msgresp = kandoomsg("U",1001,"")	#1001 "Enter Selection Criteria; OK TO Continue"
	CONSTRUCT BY NAME l_where_text ON 
	job.job_code, 
	job.type_code, 
	activity.activity_code, 
	job.cust_code, 
	job.sale_code, 
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
			CALL publish_toolbar("kandoo","JR5","const-job_job_code-5") -- alch kd-506
 
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
				IF pr_wildcard != "Y" THEN 
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
			IF pr_type_code IS NOT NULL THEN 
				IF pr_wildcard != "Y" THEN 
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
			IF pr_type_code IS NOT NULL THEN 
				IF pr_wildcard != "Y" THEN 
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
			IF pr_type_code IS NOT NULL THEN 
				IF pr_wildcard != "Y" THEN 
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
			IF pr_type_code IS NOT NULL THEN 
				IF pr_wildcard != "Y" THEN 
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
			IF pr_type_code IS NOT NULL THEN 
				IF pr_wildcard != "Y" THEN 
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
			IF pr_type_code IS NOT NULL THEN 
				IF pr_wildcard != "Y" THEN 
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
			IF pr_type_code IS NOT NULL THEN 
				IF pr_wildcard != "Y" THEN 
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

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL
	ELSE
		RETURN l_where_text	 
	END IF 
	
END FUNCTION 

FUNCTION JR5_rpt_process(p_where_text)
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
 
	DEFINE 
	pr_activity RECORD LIKE activity.*, 
	pr_job RECORD LIKE job.*, 
	pr_output CHAR(60), 
	pr_cust_name_text LIKE customer.name_text 
	DEFINE l_msgresp LIKE language.yes_flag

	LET tot_rpt_chg_amt = 0 
	LET tot_rpt_bdgt_amt = 0 
	LET tot_rpt_cost_amt = 0 
	LET tot_rpt_var_amt = 0 
	LET tot_rpt_apply_amt = 0 
	LET tot_rpt_apply_cost_amt = 0 
	LET tot_rpt_margin_amt = 0 
	LET tot_rpt_cost_per = 0 
	LET tot_rpt_rev_per = 0 


	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"JR5_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT JR5_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("JR5_rpt_list")].sel_text
	#------------------------------------------------------------

	LET l_query_text = "SELECT customer.name_text, job.cust_code, job.title_text, job.resp_code, activity.*", 
	" FROM activity, job, customer", 
	" WHERE job.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
	" AND activity.cmpy_code = job.cmpy_code ", 
	" AND activity.job_code = job.job_code ", 
	" AND customer.cmpy_code = job.cmpy_code ", 
	" AND customer.cust_code = job.cust_code ", 
	" AND ",l_query_text clipped," ", 
	" ORDER BY customer.name_text, ", 
	"job.cust_code, ", 
	"activity.job_code, ", 
	"activity.var_code, ", 
	"activity.activity_code" 

	# Option TO exclude jobs with all zero budget AND cost amount acticvities
	#   OPEN WINDOW w1 AT 10,10 with 2 rows, 50 columns
	#      ATTRIBUTE(border, MESSAGE line first)      -- alch KD-747
	# "Exclude jobs with all zero budget AND cost amount activities?"
	LET l_msgresp = kandoomsg("J",1566,"") 
	IF upshift(l_msgresp) <> "N" THEN 
		LET pr_zero_job_ind = true 
	ELSE 
		LET pr_zero_job_ind = false 
	END IF 
	#   CLOSE WINDOW w1      -- alch KD-747

	# Option TO exclude activities with zero budget AND cost amount
	#   OPEN WINDOW w2 AT 10,10 with 2 rows, 50 columns
	#      ATTRIBUTE(border, MESSAGE line first)      -- alch KD-747
	# "Exclude activities with zero budget AND cost amount?"
	LET l_msgresp = kandoomsg("J",1567,"") 
	IF upshift(l_msgresp) <> "N" THEN 
		LET pr_zero_act_ind = true 
	ELSE 
		LET pr_zero_act_ind = false 
	END IF 
	#   CLOSE WINDOW w2      -- alch KD-747

	#   OPEN WINDOW wfJM AT 10,10 with 1 rows, 50 columns
	#      ATTRIBUTE(border, MESSAGE line first)      -- alch KD-747

	PREPARE s_job FROM l_query_text 
	DECLARE c_job CURSOR FOR s_job 
	FOREACH c_job INTO pr_cust_name_text, pr_job.cust_code, pr_job.title_text, pr_job.resp_code, pr_activity.* 
		# IF exclude jobs with all zero budget AND cost amount acticvities
		IF pr_zero_job_ind THEN 
			##IF exclude the activities with zero budget AND cost amount
			IF pr_zero_act_ind THEN 
				IF (pr_activity.bdgt_cost_amt > 0 OR pr_activity.act_cost_amt > 0) THEN
					#---------------------------------------------------------
					OUTPUT TO REPORT JR5_rpt_list(l_rpt_idx,
					pr_cust_name_text, pr_job.cust_code, pr_job.title_text, pr_job.resp_code, pr_activity.*) 
					IF NOT rpt_int_flag_handler2("Job:",pr_job.title_text, NULL,l_rpt_idx) THEN
						EXIT FOREACH 
					END IF 
					#---------------------------------------------------------	
				END IF 
			ELSE 
				SELECT * FROM job 
				WHERE exists (SELECT * FROM activity 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND job_code = pr_activity.job_code 
				AND var_code = pr_activity.var_code 
				AND activity_code = pr_activity.activity_code 
				AND bdgt_cost_amt > 0 
				OR act_cost_amt > 0 ) 
				IF status != notfound THEN 
					#---------------------------------------------------------
					OUTPUT TO REPORT JR5_rpt_list(l_rpt_idx,
					pr_cust_name_text, pr_job.cust_code, pr_job.title_text, pr_job.resp_code, pr_activity.*) 
					IF NOT rpt_int_flag_handler2("Job:",pr_job.title_text, NULL,l_rpt_idx) THEN
						EXIT FOREACH 
					END IF 
					#---------------------------------------------------------	
				END IF 
			END IF 
		ELSE 
			##Print all jobs AND activities
			#---------------------------------------------------------
			OUTPUT TO REPORT JR5_rpt_list(l_rpt_idx,
			pr_cust_name_text, pr_job.cust_code, pr_job.title_text, pr_job.resp_code, pr_activity.*) 
			IF NOT rpt_int_flag_handler2("Job:",pr_job.title_text, NULL,l_rpt_idx) THEN
				EXIT FOREACH 
			END IF 
			#---------------------------------------------------------	
		END IF 

	END FOREACH 
	FINISH REPORT JR5_rpt_list 
	#   CLOSE WINDOW wfJM      -- alch KD-747
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
	ELSE 
		LET pr_wildcard = "Y" 
	END IF 
END FUNCTION 


REPORT JR5_rpt_list(p_rpt_idx,pr_cust_name_text, pr_cust_code, pr_title_text, pr_resp_code, pr_activity)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx] 
	DEFINE 
	pr_cust_code LIKE job.cust_code, 
	pr_title_text LIKE job.title_text, 
	pr_resp_code LIKE job.resp_code, 
	pr_activity RECORD LIKE activity.*, 
	pr_poaudit RECORD LIKE poaudit.*, 
	pr_jobledger RECORD LIKE jobledger.*, 
	pr_jmresource RECORD LIKE jmresource.*, 
	pr_open_bal LIKE jobledger.trans_amt, 
	held_order_num LIKE purchhead.order_num, 
	activity_total, acti_cost_amt_tot, commit_amt, total_commit_amt, 
	job_cost_amt, job_commit_amt, job_mtd_amt, acti_cost_amt_tot2, 
	job_total LIKE activity.act_bill_amt, 
	job_head_flag, act_head_flag, job_tot_print INTEGER, 
	pr_purchdetl RECORD 
		order_date LIKE purchhead.order_date, 
		order_num LIKE purchdetl.order_num, 
		res_code LIKE purchdetl.res_code, 
		line_num LIKE purchdetl.line_num, 
		posted_flag LIKE poaudit.posted_flag, 
		desc_text LIKE purchdetl.desc_text, 
		order_qty LIKE poaudit.order_qty, 
		received_qty LIKE poaudit.received_qty, 
		unit_cost_amt LIKE poaudit.unit_cost_amt, 
		unit_tax_amt LIKE poaudit.unit_tax_amt 
	END RECORD, 
	pr_cust_name_text LIKE customer.name_text, 
	pr_var_title LIKE jobvars.title_text, 
	pr_apply_amt, 
	pr_apply_cost_amt, 
	pr_bdgt_cost_amt, 
	pr_variance, 
	pr_margin LIKE activity.act_bill_amt, 
	pr_cost_per, pr_rev_per INTEGER, 
	line1, line2 CHAR(132), 
	rpt_note CHAR(40), 
	offset1, offset2, pv_trans SMALLINT 


	OUTPUT 
	ORDER external BY pr_cust_name_text, pr_cust_code, pr_activity.job_code, pr_activity.var_code, pr_activity.activity_code 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  


		BEFORE GROUP OF pr_cust_code 
			SKIP TO top OF PAGE 
			LET tot_job_chg_amt = 0 
			LET tot_job_bdgt_amt = 0 
			LET tot_job_cost_amt = 0 
			LET tot_job_var_amt = 0 
			LET tot_job_apply_amt = 0 
			LET tot_job_apply_cost_amt = 0 
			LET tot_job_margin_amt = 0 
			LET tot_job_cost_per = 0 
			LET tot_job_rev_per = 0 

		BEFORE GROUP OF pr_activity.job_code 
			LET tot_act_chg_amt = 0 
			LET tot_act_bdgt_amt = 0 
			LET tot_act_cost_amt = 0 
			LET tot_act_var_amt = 0 
			LET tot_act_apply_amt = 0 
			LET tot_act_apply_cost_amt = 0 
			LET tot_act_margin_amt = 0 
			LET tot_act_cost_per = 0 
			LET tot_act_rev_per = 0 

			PRINT "----------------------------------------------------", 
			"----------------------------------------------------", 
			"----------------------------------------------------" 
			PRINT "Customer Code :", 
			COLUMN 20, pr_cust_code, 
			COLUMN 35, pr_cust_name_text 
			PRINT "Job Code :", 
			COLUMN 20, pr_activity.job_code, 
			COLUMN 35, pr_title_text, 
			COLUMN 55, "Responsible Code :", 
			COLUMN 80, pr_resp_code 
			PRINT "____________________________________________________", 
			"____________________________________________________", 
			"____________________________________________________" 
			PRINT 
			PRINT "Activity Code", 
			COLUMN 17, "Actual Cost", 
			COLUMN 30, "Charge Out Value", 
			COLUMN 53, "Cost Budget", 
			COLUMN 73, "Variance", 
			COLUMN 90, "%", 
			COLUMN 100, "Billings", 
			COLUMN 114, "Cost of Sale", 
			COLUMN 138, "Margin", 
			COLUMN 152, "%" 
			PRINT "____________________________________________________", 
			"____________________________________________________", 
			"____________________________________________________" 
			
		BEFORE GROUP OF pr_activity.var_code 
			SELECT jobvars.title_text INTO pr_var_title 
			FROM jobvars 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND job_code = pr_activity.job_code 
			AND var_code = pr_activity.var_code 
			IF status = notfound THEN 
				LET pr_var_title = "No variation" 
			END IF 
			PRINT 
			PRINT "Variation Code :", 
			COLUMN 20, pr_activity.var_code USING "<<<<<<&", 
			COLUMN 35, pr_var_title 

		ON EVERY ROW 
			LET pr_apply_amt = 0 
			LET pr_apply_cost_amt = 0 
			LET pr_cost_per = 0 
			LET pr_rev_per = 0 

			SELECT sum(apply_amt), sum(apply_cos_amt) INTO pr_apply_amt, pr_apply_cost_amt 
			FROM resbill 
			WHERE cmpy_code = pr_activity.cmpy_code 
			AND job_code = pr_activity.job_code 
			AND var_code = pr_activity.var_code 
			AND activity_code = pr_activity.activity_code 
			GROUP BY activity_code 
			LET pr_variance = pr_activity.bdgt_cost_amt - pr_activity.act_bill_amt 
			LET pr_bdgt_cost_amt = pr_activity.bdgt_cost_amt 
			IF pr_bdgt_cost_amt != 0 THEN 
				LET pr_cost_per = (pr_variance/pr_bdgt_cost_amt)*100 
			END IF 
			LET pr_margin = pr_apply_amt - pr_apply_cost_amt 
			IF pr_apply_amt != 0 THEN 
				LET pr_rev_per = (pr_margin/pr_apply_amt)*100 
			END IF 
			
			PRINT pr_activity.activity_code clipped, 
			COLUMN 15, pr_activity.act_cost_amt USING "---------&.&&", 
			COLUMN 33, pr_activity.act_bill_amt USING "---------&.&&", 
			COLUMN 51, pr_activity.bdgt_cost_amt USING "---------&.&&", 
			COLUMN 69, pr_variance USING "---------&.&&", 
			COLUMN 87, pr_cost_per USING "-<<&.&&%", 
			COLUMN 96, pr_apply_amt USING "---------&.&&", 
			COLUMN 114, pr_apply_cost_amt USING "---------&.&&", 
			COLUMN 132, pr_margin USING "---------&.&&", 
			COLUMN 150, pr_rev_per USING "-<<&.&&%" 
			LET tot_act_chg_amt = tot_act_chg_amt + pr_activity.act_bill_amt 
			LET tot_act_bdgt_amt = tot_act_bdgt_amt + pr_activity.bdgt_cost_amt 
			LET tot_act_cost_amt = tot_act_cost_amt + pr_activity.act_cost_amt 
			LET tot_act_var_amt = tot_act_var_amt + pr_variance 
			LET tot_act_apply_amt = tot_act_apply_amt + pr_apply_amt 
			LET tot_act_apply_cost_amt = tot_act_apply_cost_amt + pr_apply_cost_amt 
			LET tot_act_margin_amt = tot_act_margin_amt + pr_margin 
			IF tot_act_bdgt_amt !=0 THEN 
				LET tot_act_cost_per = (tot_act_var_amt/tot_act_bdgt_amt)*100 
			END IF 
			IF tot_act_apply_amt != 0 THEN 
				LET tot_act_rev_per = (tot_act_margin_amt/tot_act_apply_amt)*100 
			END IF 

		AFTER GROUP OF pr_activity.job_code 
			PRINT 
			PRINT COLUMN 18, "----------", COLUMN 36, "----------", COLUMN 54, "----------", 
			COLUMN 72,"----------", COLUMN 88, "-------", COLUMN 99, "----------", COLUMN 117, "----------", 
			COLUMN 135, "----------", COLUMN 151, "-------" 
			PRINT "Activity Total", 
			COLUMN 15, tot_act_cost_amt USING "---------&.&&", 
			COLUMN 33, tot_act_chg_amt USING "---------&.&&", 
			COLUMN 51, tot_act_bdgt_amt USING "---------&.&&", 
			COLUMN 69, tot_act_var_amt USING "---------&.&&", 
			COLUMN 87, tot_act_cost_per USING "-<<&.&&%", 
			COLUMN 96, tot_act_apply_amt USING "---------&.&&", 
			COLUMN 114, tot_act_apply_cost_amt USING "---------&.&&", 
			COLUMN 132,tot_act_margin_amt USING "---------&.&&", 
			COLUMN 150,tot_act_rev_per USING "-<<&.&&%" 
			PRINT COLUMN 18, "----------", COLUMN 36, "----------", COLUMN 54, "----------", 
			COLUMN 72,"----------", COLUMN 88, "-------", COLUMN 99, "----------", COLUMN 117, "----------", 
			COLUMN 135, "----------", COLUMN 151, "-------" 
			LET tot_job_chg_amt = tot_job_chg_amt + tot_act_chg_amt 
			LET tot_job_bdgt_amt = tot_job_bdgt_amt + tot_act_bdgt_amt 
			LET tot_job_cost_amt = tot_job_cost_amt + tot_act_cost_amt 
			LET tot_job_var_amt = tot_job_var_amt + tot_act_var_amt 
			LET tot_job_apply_amt = tot_job_apply_amt + tot_act_apply_amt 
			LET tot_job_apply_cost_amt = tot_job_apply_cost_amt + 
			tot_act_apply_cost_amt 
			LET tot_job_margin_amt = tot_job_margin_amt + tot_act_margin_amt 
			IF tot_job_bdgt_amt != 0 THEN 
				LET tot_job_cost_per = (tot_job_var_amt/tot_job_bdgt_amt)*100 
			END IF 
			IF tot_job_apply_amt != 0 THEN 
				LET tot_job_rev_per = (tot_job_margin_amt/tot_job_apply_amt)*100 
			END IF 
			
		AFTER GROUP OF pr_cust_code 
			SKIP 2 LINES 
			PRINT COLUMN 18, "----------", COLUMN 36, "----------", COLUMN 54, "----------", 
			COLUMN 72,"----------", COLUMN 88, "-------", COLUMN 99, "----------", COLUMN 117, "----------", 
			COLUMN 135, "----------", COLUMN 151, "-------" 
			PRINT "Job Total", 
			COLUMN 15, tot_job_cost_amt USING "---------&.&&", 
			COLUMN 33, tot_job_chg_amt USING "---------&.&&", 
			COLUMN 51, tot_job_bdgt_amt USING "---------&.&&", 
			COLUMN 69, tot_job_var_amt USING "---------&.&&", 
			COLUMN 87, tot_job_cost_per USING "-<<&.&&%", 
			COLUMN 96, tot_job_apply_amt USING "---------&.&&", 
			COLUMN 114, tot_job_apply_cost_amt USING "---------&.&&", 
			COLUMN 132,tot_act_margin_amt USING "---------&.&&", 
			COLUMN 150,tot_job_rev_per USING "-<<&.&&%" 
			PRINT COLUMN 18, "----------", COLUMN 36, "----------", COLUMN 54, "----------", 
			COLUMN 72,"----------", COLUMN 88, "-------", COLUMN 99, "----------", COLUMN 117, "----------", 
			COLUMN 135, "----------", COLUMN 151, "-------" 
			LET tot_rpt_chg_amt = tot_rpt_chg_amt + tot_job_chg_amt 
			LET tot_rpt_bdgt_amt = tot_rpt_bdgt_amt + tot_job_bdgt_amt 
			LET tot_rpt_cost_amt = tot_rpt_cost_amt + tot_job_cost_amt 
			LET tot_rpt_var_amt = tot_rpt_var_amt + tot_job_var_amt 
			LET tot_rpt_apply_amt = tot_rpt_apply_amt + tot_job_apply_amt 
			LET tot_rpt_apply_cost_amt = tot_rpt_apply_cost_amt + 
			tot_job_apply_cost_amt 
			LET tot_rpt_margin_amt = tot_rpt_margin_amt + tot_act_margin_amt 
			IF tot_rpt_bdgt_amt != 0 THEN 
				LET tot_rpt_cost_per = (tot_rpt_var_amt/tot_rpt_bdgt_amt)*100 
			END IF 
			IF tot_rpt_apply_amt != 0 THEN 
				LET tot_rpt_rev_per = (tot_rpt_margin_amt/tot_rpt_apply_amt)*100 
			END IF 
			
		ON LAST ROW 
			SKIP 3 line 
			PRINT COLUMN 18, "----------", COLUMN 36, "----------", COLUMN 54, "----------", 
			COLUMN 72,"----------", COLUMN 88, "-------", COLUMN 99, "----------", COLUMN 117, "----------", 
			COLUMN 135, "----------", COLUMN 151, "-------" 
			PRINT "REPORT TOTALS", 
			COLUMN 15, tot_rpt_cost_amt USING "---------&.&&", 
			COLUMN 33, tot_rpt_chg_amt USING "---------&.&&", 
			COLUMN 51, tot_rpt_bdgt_amt USING "---------&.&&", 
			COLUMN 69, tot_rpt_var_amt USING "---------&.&&", 
			COLUMN 87, tot_rpt_cost_per USING "-<<&.&&%", 
			COLUMN 96, tot_rpt_apply_amt USING "---------&.&&", 
			COLUMN 114, tot_rpt_apply_cost_amt USING "---------&.&&", 
			COLUMN 132,tot_rpt_margin_amt USING "---------&.&&", 
			COLUMN 150,tot_rpt_rev_per USING "-<<&.&&%" 

			PRINT COLUMN 18, "==========", COLUMN 36, "==========", COLUMN 54, "==========", 
			COLUMN 72, "==========", COLUMN 88, "=======", COLUMN 99, "==========", COLUMN 117, "==========", 
			COLUMN 135, "==========", COLUMN 151, "=======" 
			IF pr_zero_job_ind THEN 
				LET pr_option1 = "Jobs excluded all zero budget AND cost amount activities" 
			ELSE 
				LET pr_option1 = "All jobs" 
			END IF 

			IF pr_zero_act_ind THEN 
				LET pr_option2 = "Activities excluded zero budget AND cost amount" 
			ELSE 
				LET pr_option2 = "All activities" 
			END IF 
			SKIP 3 LINES 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	
	
			
END REPORT 