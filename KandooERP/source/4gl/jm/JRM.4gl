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
# Purpose - JM Cost Transaction Report
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl"
GLOBALS "../common/glob_GLOBALS_report.4gl" 
GLOBALS "../jm/J_JM_GLOBALS.4gl" 
GLOBALS "../jm/JR_GROUP_GLOBALS.4gl"  
GLOBALS "../jm/JRM_GLOBALS.4gl"
 
#Module Scope Variables
DEFINE 
pr_jobtype RECORD LIKE jobtype.*, 
pr_jmparms RECORD LIKE jmparms.*, 
pr_underline_reqd, pr_print_all_trans CHAR(1), 
pr_print_trailer, pr_wildcard CHAR(1), 
pr_time_frame RECORD 
	from_year_num LIKE period.year_num, 
	from_period_num LIKE period.period_num, 
	from_date LIKE period.start_date, 
	to_year_num LIKE period.year_num, 
	to_period_num LIKE period.period_num, 
	to_date LIKE period.end_date, 
	sort_ind CHAR(1), 
	content_ind CHAR(1), 
	zero_trans CHAR(1) 
END RECORD, 
pr_cost_total, 
pr_mtd_total, 
pr_commit_total, 
pr_total LIKE activity.act_bill_amt 

MAIN 
	DEFINE l_msgresp LIKE language.yes_flag

	#Initial UI Init
	CALL setModuleId("JRM") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 


	SELECT jmparms.* INTO pr_jmparms.* FROM jmparms 
	WHERE jmparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND jmparms.key_code = "1" 
	IF status = notfound THEN 
		LET l_msgresp = kandoomsg("J",7505,"") 
		#7505" Job Management Parameters NOT found - Refer Menu JZP "
		EXIT program 
	END IF 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN "1" #UI/MENU Mode 	

			OPEN WINDOW J178 with FORM "J178" -- alch kd-747 
			CALL winDecoration_j("J178") -- alch kd-747
 
			DISPLAY BY NAME pr_jmparms.prompt1_text, 
			pr_jmparms.prompt2_text, 
			pr_jmparms.prompt3_text, 
			pr_jmparms.prompt4_text, 
			pr_jmparms.prompt5_text, 
			pr_jmparms.prompt6_text, 
			pr_jmparms.prompt7_text, 
			pr_jmparms.prompt8_text
			 
			MENU " Job Cost Transaction Report" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","JRM","menu-job_cost_trans_rep-1") -- alch kd-506
 
				ON ACTION "WEB-HELP" -- albo kd-373 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "REPORT" --COMMAND "Run" " Enter selection criteria AND generate REPORT" 
					CALL rpt_rmsreps_reset(NULL) 
					CALL JRM_rpt_process(JRM_rpt_query())

				ON ACTION "Print Manager"			#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "CANCEL" --COMMAND KEY("E",interrupt)"Exit" " Exit TO menus" 
					EXIT MENU 

			END MENU 
			CLOSE WINDOW J178
			 
	 
		WHEN "2" #Background Process with rmsreps.report_code
			CALL JRM_rpt_process(NULL)  

		WHEN "3" #Only create query-where-part
			OPEN WINDOW J178 with FORM "J178" 
			CALL winDecoration_j("J178") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(JRM_rpt_query()) #save where clause in env 
			CLOSE WINDOW J178 
			
		WHEN "4" #Background Process with SQL WHERE ARGUMENT
			CALL JRM_rpt_process(get_url_sel_text())
	END CASE 
END MAIN 


FUNCTION JRM_rpt_query() 
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
	LET l_msgresp = kandoomsg("J",1001,"")	#1001 "Enter Selection Criteria; OK TO Continue"
	#CONSTRUCT BY NAME glob_rec_rmsreps.sel_text on job.job_code,
	CONSTRUCT l_where_text ON 
	job.job_code, 
	job.title_text, 
	job.type_code, 
	job.cust_code, 
	customer.name_text, 
	job.resp_code, 
	job.finish_flag, 
	jobledger.var_code, 
	jobledger.activity_code, 
	activity.title_text, 
	jobledger.trans_source_text, 
	jmresource.resgrp_code, 
	resgrp.res_type_ind, 
	job.report_text, 
	job.report1_text, 
	job.report2_text, 
	job.report3_text, 
	job.report4_text, 
	job.report5_text, 
	job.report6_text, 
	job.report7_text, 
	job.report8_text 
	FROM 
	job.job_code, 
	job.title_text, 
	job.type_code, 
	job.cust_code, 
	customer.name_text, 
	job.resp_code, 
	job.finish_flag, 
	jobledger.var_code, 
	jobledger.activity_code, 
	activity.title_text, 
	jobledger.trans_source_text, 
	jmresource.resgrp_code, 
	resgrp.res_type_ind, 
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
			CALL publish_toolbar("kandoo","JRM","const-job_job_code-12") -- alch kd-506 
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
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END CONSTRUCT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL
	ELSE
	LET pr_time_frame.sort_ind = 1 
	CALL get_time_frame() 
	LET glob_rec_rpt_selector.ref1_num = pr_time_frame.from_year_num 
	LET glob_rec_rpt_selector.ref2_num = pr_time_frame.from_period_num 
	LET glob_rec_rpt_selector.ref3_num = pr_time_frame.to_year_num 
	LET glob_rec_rpt_selector.ref4_num = pr_time_frame.to_period_num 
	LET glob_rec_rpt_selector.ref1_date = pr_time_frame.from_date 
	LET glob_rec_rpt_selector.ref2_date = pr_time_frame.to_date 
	LET glob_rec_rpt_selector.ref1_ind = pr_time_frame.zero_trans 
	LET glob_rec_rpt_selector.ref2_ind = pr_time_frame.sort_ind 
	LET glob_rec_rpt_selector.ref3_ind = pr_time_frame.content_ind 
	RETURN 	 
	END IF 

END FUNCTION 


FUNCTION JRM_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE 
	pr_jobledger RECORD LIKE jobledger.*, 
	pr_job RECORD LIKE job.*, 
	pr_order_text CHAR(13), 
	query_text CHAR(3000), 
	date_text CHAR(250), 
	sort_text CHAR(250), 
	pr_zone, 
	pr_costcode, 
	pr_comp, 
	pr_subc LIKE activity.activity_code, 
	pr_unit_code LIKE jmresource.unit_code, 
	pr_resgrp_code LIKE resgrp.resgrp_code, 
	pr_res_type_ind LIKE resgrp.res_type_ind 

	LET pr_cost_total = 0 
	LET pr_mtd_total = 0 
	LET pr_commit_total = 0 
	LET pr_total = 0 
	LET pr_wildcard = "N" 
	LET pr_print_trailer = "N" 
	LET pr_underline_reqd = "N" 


	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"JRM_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT JRM_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("JRM_rpt_list")].sel_text
	#------------------------------------------------------------
	#Data from rms_reps
	LET pr_time_frame.from_year_num = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref1_num 
	LET pr_time_frame.from_period_num = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref2_num 
	LET pr_time_frame.to_year_num = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref3_num 
	LET pr_time_frame.to_period_num = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref4_num 
	LET pr_time_frame.zero_trans = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref1_ind 
	LET pr_time_frame.from_date = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref1_date 
	LET pr_time_frame.to_date = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref2_date 
	LET pr_print_all_trans = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref1_ind 
	LET pr_time_frame.sort_ind = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref2_ind 
	LET pr_time_frame.content_ind = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref3_ind 
	#------------------------------------------------------------

	IF pr_time_frame.from_year_num IS NOT NULL THEN 
		LET date_text = 
		" AND (jobledger.year_num > ",pr_time_frame.from_year_num," ", 
		" OR (jobledger.year_num = ",pr_time_frame.from_year_num," ", 
		" AND jobledger.period_num >= ",pr_time_frame.from_period_num,")) ", 
		" AND (jobledger.year_num < ",pr_time_frame.to_year_num," ", 
		" OR (jobledger.year_num = ",pr_time_frame.to_year_num," ", 
		" AND jobledger.period_num <= ",pr_time_frame.to_period_num,")) " 
		SELECT start_date INTO pr_time_frame.from_date 
		FROM period 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND year_num = pr_time_frame.from_year_num 
		AND period_num = pr_time_frame.from_period_num 
		SELECT end_date INTO pr_time_frame.to_date 
		FROM period 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND year_num = pr_time_frame.to_year_num 
		AND period_num = pr_time_frame.to_period_num 
	ELSE 
		LET date_text = 
		" AND jobledger.trans_date >= \"", pr_time_frame.from_date, "\" ", 
		" AND jobledger.trans_date <= \"", pr_time_frame.to_date, "\" " 
	END IF 
	IF pr_time_frame.sort_ind = "1" THEN 
		LET sort_text = "jobledger.activity_code[4,6], ", 
		"jobledger.activity_code[1,1], ", 
		"jobledger.activity_code[2,2], ", 
		"jobledger.activity_code[3,3], " 
	ELSE 
		LET sort_text = "jobledger.activity_code[1,1], ", 
		"jobledger.activity_code[2,2], ", 
		"jobledger.activity_code[3,3], ", 
		"jobledger.activity_code[4,6], " 
	END IF 
	LET query_text = "SELECT jobledger.job_code, ", 
	" jobledger.var_code, ", 
	" jobledger.activity_code, ", 
	" jobledger.trans_type_ind, ", 
	" jobledger.trans_source_num, ", 
	" jobledger.trans_source_text, ", 
	" jobledger.desc_text, ", 
	" jobledger.trans_date, ", 
	" jmresource.unit_code, ", 
	" resgrp.resgrp_code, ", 
	" resgrp.res_type_ind, ", 
	" sum(jobledger.trans_qty), ", 
	" sum(jobledger.trans_amt) ", 
	"FROM jobledger, job, activity, customer, ", 
	" jmresource, resgrp ", 
	" WHERE job.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
	" AND jobledger.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
	" AND jobledger.job_code = job.job_code ", 
	" AND activity.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
	" AND activity.job_code = jobledger.job_code ", 
	" AND activity.var_code = jobledger.var_code ", 
	" AND activity.activity_code = jobledger.activity_code ", 
	" AND jmresource.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
	" AND jmresource.res_code = jobledger.trans_source_text ", 
	" AND resgrp.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
	" AND jmresource.resgrp_code = resgrp.resgrp_code ", 
	" AND jobledger.trans_type_ind <> 'SA' ", 
	" AND jobledger.trans_type_ind <> 'CO' ", 
	" AND jobledger.accrual_ind IS NULL ", 
	" AND customer.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
	" AND job.cust_code = customer.cust_code ", 
	" AND ",p_where_text clipped," ",date_text, 
	" group by 1,2,3,4,5,6,7,8,9,10,11 ", 
	" ORDER BY ", 
	"jobledger.job_code, ", 
	"jobledger.var_code, ", 
	sort_text, 
	"jobledger.trans_date, ", 
	"jobledger.trans_source_num " 
	PREPARE s_job FROM query_text 
	DECLARE c_job CURSOR FOR s_job 
	FOREACH c_job INTO pr_jobledger.job_code, 
		pr_jobledger.var_code, 
		pr_jobledger.activity_code, 
		pr_jobledger.trans_type_ind, 
		pr_jobledger.trans_source_num, 
		pr_jobledger.trans_source_text, 
		pr_jobledger.desc_text, 
		pr_jobledger.trans_date, 
		pr_unit_code, 
		pr_resgrp_code, 
		pr_res_type_ind , 
		pr_jobledger.trans_qty, 
		pr_jobledger.trans_amt 
		IF pr_jobledger.trans_qty = 0 
		AND pr_jobledger.trans_amt = 0 THEN 
			CONTINUE FOREACH 
		END IF 
		LET pr_jobledger.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET pr_costcode = pr_jobledger.activity_code[4,6] 
		LET pr_zone = pr_jobledger.activity_code[1,1] 
		LET pr_comp = pr_jobledger.activity_code[2,2] 
		LET pr_subc = pr_jobledger.activity_code[3,3] 
		IF pr_time_frame.sort_ind = "1" THEN
			#---------------------------------------------------------
			OUTPUT TO REPORT JRM_rpt_list(l_rpt_idx,
			pr_costcode,pr_zone,pr_comp,pr_subc, #4 sort arguments 
			pr_jobledger.*, pr_unit_code, pr_resgrp_code, pr_res_type_ind, pr_time_frame.*) 
			 
			IF NOT rpt_int_flag_handler2("Job/Activity:",pr_jobledger.job_code, pr_jobledger.activity_code,l_rpt_idx) THEN
				EXIT FOREACH 
			END IF 
			#---------------------------------------------------------	
		ELSE 
			#---------------------------------------------------------
			OUTPUT TO REPORT JRM_rpt_list(l_rpt_idx, 
			pr_zone,pr_comp,pr_subc,pr_costcode, #4 sort arguments 
			pr_jobledger.*, pr_unit_code, pr_resgrp_code, pr_res_type_ind, pr_time_frame.*) 
			 
			IF NOT rpt_int_flag_handler2("Job/Activity:",pr_jobledger.job_code, pr_jobledger.activity_code,l_rpt_idx) THEN
				EXIT FOREACH 
			END IF 
			#---------------------------------------------------------	

		END IF 


	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT JRM_rpt_list
	CALL rpt_finish("JRM_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
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



FUNCTION get_time_frame() 
	DEFINE 
	pr_year_num LIKE period.year_num, 
	pr_period_num LIKE period.period_num, 
	pr_string CHAR(7) 
	DEFINE l_msgresp LIKE language.yes_flag
	
	OPEN WINDOW j179 with FORM "J179" -- alch kd-747 
	CALL winDecoration_j("J179") -- alch kd-747 
	LET l_msgresp = kandoomsg("U",1020,"Report") 
	#1020 Enter Report Details; OK TO Continue
	CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, today) 
	RETURNING pr_year_num, 
	pr_period_num 
	LET pr_time_frame.to_year_num = pr_year_num 
	LET pr_time_frame.to_period_num = pr_period_num 
	LET pr_time_frame.from_year_num = pr_year_num 
	LET pr_time_frame.from_period_num = pr_period_num 
	LET pr_time_frame.from_date = NULL 
	LET pr_time_frame.to_date = NULL 
	LET pr_time_frame.zero_trans = "N" 
	LET pr_time_frame.sort_ind = "1" 
	LET pr_time_frame.content_ind = "D" 
	INPUT BY NAME pr_time_frame.from_year_num, 
	pr_time_frame.from_period_num, 
	pr_time_frame.to_year_num, 
	pr_time_frame.to_period_num, 
	pr_time_frame.from_date, 
	pr_time_frame.to_date, 
	pr_time_frame.sort_ind, 
	pr_time_frame.content_ind WITHOUT DEFAULTS 
	#pr_time_frame.zero_trans WITHOUT DEFAULTS

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","JRM","input-pr_time_frame-1") -- alch kd-506 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

		AFTER FIELD from_year_num 
			IF pr_time_frame.from_year_num IS NULL THEN 
				LET pr_time_frame.to_period_num = NULL 
				LET pr_time_frame.to_year_num = NULL 
				LET pr_time_frame.from_period_num = NULL 
				DISPLAY pr_time_frame.from_year_num, 
				pr_time_frame.from_period_num, 
				pr_time_frame.to_year_num, 
				pr_time_frame.to_period_num 
				TO from_year_num, 
				from_period_num, 
				to_year_num, 
				to_period_num 

				NEXT FIELD from_date 
			ELSE 
				LET pr_time_frame.from_date = NULL 
				LET pr_time_frame.to_date = NULL 
				DISPLAY pr_time_frame.from_date, 
				pr_time_frame.to_date 
				TO from_date, 
				to_date 

			END IF 
		BEFORE FIELD from_date 
			IF pr_time_frame.from_year_num IS NOT NULL THEN 
				IF fgl_lastkey() = fgl_keyval("up") THEN 
					NEXT FIELD previous 
				ELSE 
					NEXT FIELD sort_ind 
				END IF 
			END IF 
		AFTER FIELD from_date 
			IF pr_time_frame.from_date IS NULL 
			AND pr_time_frame.from_year_num IS NULL THEN 
				LET l_msgresp = kandoomsg("J",9649,0) 
				NEXT FIELD from_year_num 
			END IF 
		BEFORE FIELD to_date 
			IF pr_time_frame.from_date IS NULL THEN 
				IF fgl_lastkey() = fgl_keyval("up") THEN 
					NEXT FIELD to_period_num 
				END IF 
			END IF 
		AFTER FIELD to_date 
			IF pr_time_frame.from_date IS NOT NULL 
			AND pr_time_frame.to_date IS NULL THEN 
				LET l_msgresp = kandoomsg("J",9505,0) 
				NEXT FIELD to_date 
			END IF 
			IF pr_time_frame.from_date IS NOT NULL 
			AND pr_time_frame.to_date < pr_time_frame.from_date THEN 
				LET l_msgresp = kandoomsg("J",9650,0) 
				NEXT FIELD to_date 
			END IF 
		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				IF pr_time_frame.from_period_num IS NULL THEN 
					IF pr_time_frame.from_year_num IS NOT NULL THEN 
						LET l_msgresp = kandoomsg("U",9102,"") 
						#9102 Value must be entered
						NEXT FIELD from_period_num 
					END IF 
				END IF 
				IF pr_time_frame.to_period_num IS NULL THEN 
					IF pr_time_frame.to_year_num IS NOT NULL THEN 
						LET l_msgresp = kandoomsg("U",9102,"") 
						#9102 Value must be entered
						NEXT FIELD to_period_num 
					END IF 
				END IF 
				IF pr_time_frame.from_year_num IS NOT NULL 
				AND pr_time_frame.from_period_num IS NOT NULL THEN 
					SELECT 1 FROM period 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND year_num = pr_time_frame.from_year_num 
					AND period_num = pr_time_frame.from_period_num 
					IF status = notfound THEN 
						LET pr_string = pr_time_frame.from_year_num USING "&&&&", 
						"/",pr_time_frame.from_period_num USING "&&" 
						LET l_msgresp = kandoomsg("G",9201,pr_string) 
						#9201 "Year AND Period NOT defined FOR 1998/02"
						NEXT FIELD from_year_num 
					END IF 
				END IF 
				IF pr_time_frame.to_year_num IS NOT NULL 
				AND pr_time_frame.to_period_num IS NULL THEN 
					LET l_msgresp = kandoomsg("U",9102,"") 
					#9102 A value must be entered
					NEXT FIELD to_period_num 
				END IF 
				IF pr_time_frame.from_year_num IS NOT NULL 
				AND pr_time_frame.to_year_num IS NULL THEN 
					LET l_msgresp = kandoomsg("U",9907,pr_time_frame.from_year_num) 
					#9907 "Value must be >= FROM year"
					NEXT FIELD to_year_num 
				END IF 
				IF pr_time_frame.from_year_num IS NOT NULL 
				AND pr_time_frame.to_year_num IS NOT NULL THEN 
					IF pr_time_frame.to_year_num < pr_time_frame.from_year_num THEN 
						LET l_msgresp = kandoomsg("U",9907,pr_time_frame.from_year_num) 
						#9907 "Value must be >= FROM year"
						NEXT FIELD to_year_num 
					END IF 
					IF pr_time_frame.from_year_num = pr_time_frame.to_year_num 
					AND pr_time_frame.to_period_num < pr_time_frame.from_period_num THEN 
						LET l_msgresp = kandoomsg("U",9907,pr_time_frame.from_period_num) 
						#9907 "Value must be >= FROM period"
						NEXT FIELD to_period_num 
					END IF 
				END IF 
				IF pr_time_frame.to_year_num IS NOT NULL 
				AND pr_time_frame.to_period_num IS NOT NULL THEN 
					SELECT 1 FROM period 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND year_num = pr_time_frame.to_year_num 
					AND period_num = pr_time_frame.to_period_num 
					IF status = notfound THEN 
						LET pr_string = pr_time_frame.to_year_num USING "&&&&", 
						"/",pr_time_frame.to_period_num USING "&&" 
						LET l_msgresp = kandoomsg("G",9201,pr_string) 
						#9201 "Year AND Period NOT defined FOR 1998/02"
						NEXT FIELD to_year_num 
					END IF 
				END IF 
				IF pr_time_frame.from_date IS NOT NULL 
				AND pr_time_frame.to_date IS NULL THEN 
					LET l_msgresp = kandoomsg("J",9505,0) 
					NEXT FIELD to_date 
				END IF 
				IF pr_time_frame.from_date IS NOT NULL 
				AND pr_time_frame.to_date < pr_time_frame.from_date THEN 
					LET l_msgresp = kandoomsg("J",9650,0) 
					NEXT FIELD to_date 
				END IF 
			END IF 

	END INPUT 
	#JP MAY NOT INCLUDE THIS LET pr_time_frame.zero_trans = kandoomsg("J",8005,0)
	# Print Activities with no transactions?
	CLOSE WINDOW j179 
END FUNCTION

REPORT JRM_rpt_list(p_rpt_idx,pr_sort1, pr_sort2, pr_sort3, pr_sort4, pr_jobledger, 
	pr_unit_code,pr_resgrp_code,pr_res_type_ind, pr_time_frame)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	 
	DEFINE 
	pr_sort1, 
	pr_sort2, 
	pr_sort3, 
	pr_sort4 LIKE activity.activity_code, 
	pr_jobledger RECORD LIKE jobledger.*, 
	pr_unit_code LIKE jmresource.unit_code, 
	pr_resgrp_code LIKE resgrp.resgrp_code, 
	pr_res_type_ind LIKE resgrp.res_type_ind, 
	pr_amt LIKE jobledger.trans_amt, 
	pr_time_frame RECORD 
		from_year_num LIKE period.year_num, 
		from_period_num LIKE period.period_num, 
		from_date LIKE period.start_date, 
		to_year_num LIKE period.year_num, 
		to_period_num LIKE period.period_num, 
		to_date LIKE period.end_date, 
		sort_ind CHAR(1), 
		content_ind CHAR(1), 
		zero_trans CHAR(1) 
	END RECORD, 
	pr_job RECORD LIKE job.*, 
	pr_open_bal LIKE jobledger.trans_amt, 
	held_order_num LIKE purchhead.order_num, 
	pr_ref_text CHAR(20), 
	pr_vend_code LIKE vendor.vend_code, 
	pr_cust_name_text LIKE customer.name_text, 
	pr_jobtype_text LIKE jobtype.type_text, 
	pr_resp_name_text LIKE responsible.name_text, 
	pr_act_text LIKE activity.title_text, 
	pa_line array[4] OF CHAR(145) 

	OUTPUT 
	left margin 0 
	PAGE length 66 
	ORDER external BY pr_jobledger.job_code, 
	pr_jobledger.var_code, 
	pr_sort1, pr_sort2, pr_sort3, pr_sort4, 
	pr_jobledger.trans_date 
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  
	
			IF pr_time_frame.sort_ind = "1" THEN 
				PRINT COLUMN 01, "Cost Zone/Comp/Sub"; 
			ELSE 
				PRINT COLUMN 01, "Zone/Comp/Sub Cost"; 
			END IF 
			PRINT COLUMN 23, "Date", 
			COLUMN 30, "Vendor", 
			COLUMN 38, "Src Description", 
			COLUMN 70, "Invoice", 
			COLUMN 91, "Ref.", 
			COLUMN 100, "Group", 
			COLUMN 108, "Qty", 
			COLUMN 114, "UOM", 
			COLUMN 123, "Rate", 
			COLUMN 137, "Amount" 
			IF pr_time_frame.sort_ind = "1" THEN 
				PRINT COLUMN 01, "Code" 
			ELSE 
				PRINT COLUMN 15, "Code" 
			END IF 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  

		BEFORE GROUP OF pr_jobledger.job_code 
			SKIP TO top OF PAGE 
			SELECT * INTO pr_job.* 
			FROM job 
			WHERE cmpy_code = pr_jobledger.cmpy_code 
			AND job_code = pr_jobledger.job_code 
			IF status = notfound THEN 
				LET pr_job.title_text = "*** JOB NOT FOUND ***" 
			END IF 

			SELECT name_text INTO pr_cust_name_text 
			FROM customer 
			WHERE cust_code = pr_job.cust_code 
			AND cmpy_code = pr_jobledger.cmpy_code 
			IF status = notfound THEN 
				LET pr_cust_name_text = "*** CUSTOMER NOT FOUND ***" 
			END IF 

			SELECT type_text INTO pr_jobtype_text 
			FROM jobtype 
			WHERE cmpy_code = pr_jobledger.cmpy_code 
			AND type_code = pr_job.type_code 
			IF status = notfound THEN 
				LET pr_jobtype_text = "*** JOB TYPE NOT FOUND ***" 
			END IF 

			SELECT name_text INTO pr_resp_name_text 
			FROM responsible 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND resp_code = pr_job.resp_code 
			IF status = notfound THEN 
				LET pr_resp_name_text = "*** RESPONSIBLE CODE NOT FOUND ***" 
			END IF 

			#PRINT COLUMN 01, pa_line[3]
			PRINT COLUMN 01, "Job Code:", 
			COLUMN 12, pr_jobledger.job_code, 
			COLUMN 22, pr_job.title_text, 
			COLUMN 56, "Cust:", 
			COLUMN 63, pr_job.cust_code, 
			COLUMN 73, pr_cust_name_text 

			PRINT COLUMN 01, "Type:", 
			COLUMN 12, pr_job.type_code, 
			COLUMN 22, pr_jobtype_text, 
			COLUMN 56, "Resp:", 
			COLUMN 73, pr_resp_name_text, 
			COLUMN 104, "Terr:" 

			PRINT COLUMN 01, "Commencing:", 
			COLUMN 14, pr_time_frame.from_date USING "dd/mm/yyyy", 
			COLUMN 30, "Ending:", 
			COLUMN 39, pr_time_frame.to_date USING "dd/mm/yyyy" 

		BEFORE GROUP OF pr_sort1 
			IF pr_time_frame.sort_ind = "1" THEN 
				PRINT COLUMN 2, pr_sort1 clipped; 
			ELSE 
			END IF 

		BEFORE GROUP OF pr_sort2 
			IF pr_time_frame.sort_ind = "1" THEN 
			ELSE 
			END IF 

		BEFORE GROUP OF pr_sort3 
			IF pr_time_frame.sort_ind = "1" THEN 
			ELSE 
				PRINT COLUMN 3, pr_sort1 clipped; 
				PRINT COLUMN 7, pr_sort2 clipped; 
				PRINT COLUMN 11, pr_sort3 clipped; 
			END IF 

		BEFORE GROUP OF pr_sort4 
			SELECT title_text 
			INTO pr_act_text 
			FROM activity 
			WHERE cmpy_code = pr_jobledger.cmpy_code 
			AND job_code = pr_jobledger.job_code 
			AND var_code = pr_jobledger.var_code 
			AND activity_code = pr_jobledger.activity_code 
			IF status = notfound THEN 
				LET pr_act_text = "*** NOT FOUND ***" 
			END IF 
			IF pr_time_frame.sort_ind = "1" THEN 
				PRINT COLUMN 8, pr_sort2 clipped; 
				PRINT COLUMN 12, pr_sort3 clipped; 
				PRINT COLUMN 16, pr_sort4 clipped; 
			ELSE 
				PRINT COLUMN 16, pr_sort4 clipped; 
			END IF 

			IF pr_time_frame.content_ind = "D" THEN 
				PRINT COLUMN 21, pr_act_text 
			ELSE 
				PRINT COLUMN 21, pr_act_text; 
			END IF 

		ON EVERY ROW 
			IF pr_time_frame.content_ind = "D" THEN 
				CASE pr_jobledger.trans_type_ind 
					WHEN "VO" 
						SELECT vend_code,inv_text 
						INTO pr_vend_code, pr_ref_text 
						FROM voucher 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND vouch_code = pr_jobledger.trans_source_num 
					WHEN "DB" 
						SELECT vend_code, debit_text 
						INTO pr_vend_code, pr_ref_text 
						FROM debithead 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND debit_num = pr_jobledger.trans_source_num 
					WHEN "PU" 
						SELECT vend_code 
						INTO pr_vend_code 
						FROM purchhead 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND order_num = pr_jobledger.trans_source_num 
						LET pr_ref_text = NULL 
					WHEN "TS" 
						SELECT unique person_code 
						INTO pr_vend_code 
						FROM ts_head 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND ts_num = pr_jobledger.trans_source_num 
					WHEN "IS" 
						LET pr_vend_code = NULL 
						LET pr_ref_text = NULL 
					WHEN "RE" 
						LET pr_vend_code = NULL 
						LET pr_ref_text = NULL 
					OTHERWISE 
						LET pr_vend_code = NULL 
						LET pr_ref_text = NULL 
				END CASE 

				PRINT COLUMN 021, pr_jobledger.trans_date USING "dd/mm/yy", 
				COLUMN 030, pr_vend_code, 
				COLUMN 039, pr_jobledger.trans_type_ind, 
				COLUMN 042, pr_jobledger.desc_text[1,28] clipped, 
				COLUMN 070, pr_ref_text clipped, 
				COLUMN 091, pr_jobledger.trans_source_num USING "<<<<<<<<", 
				COLUMN 100, pr_resgrp_code, 
				COLUMN 104, pr_jobledger.trans_qty USING "------&.&","/", 
				COLUMN 114, pr_unit_code, 
				COLUMN 118, pr_jobledger.trans_amt / pr_jobledger.trans_qty 
				USING "--,---,-$&.&&", 
				COLUMN 131, pr_jobledger.trans_amt USING "----,---,-$&.&&" 
			END IF 

		AFTER GROUP OF pr_sort4 
			IF pr_time_frame.content_ind = "D" THEN 
				NEED 2 LINES 
				PRINT COLUMN 131, "---------------" 
				IF pr_time_frame.sort_ind = "1" THEN 
					PRINT COLUMN 8, "Total ", 
					pr_sort2 clipped, 
					pr_sort3 clipped, 
					pr_sort4 clipped; 
				ELSE 
					PRINT COLUMN 8, "Total ", 
					pr_sort4 clipped; 
				END IF 
				PRINT COLUMN 131, GROUP sum(pr_jobledger.trans_amt) 
				USING "----,---,-$&.&&" 
				PRINT 
			ELSE 
				PRINT COLUMN 131, GROUP sum(pr_jobledger.trans_amt) 
				USING "----,---,-$&.&&" 
			END IF 

		AFTER GROUP OF pr_sort3 
			NEED 2 LINES 
			PRINT COLUMN 131, "---------------" 
			IF pr_time_frame.sort_ind = "1" THEN 
				PRINT COLUMN 6, "Total ", 
				pr_sort2 clipped, 
				pr_sort3 clipped; 
			ELSE 
				PRINT COLUMN 6, "Total ", 
				pr_sort1 clipped, 
				pr_sort2 clipped, 
				pr_sort3 clipped; 
			END IF 
			PRINT COLUMN 131, GROUP sum(pr_jobledger.trans_amt) 
			USING "----,---,-$&.&&" 
			PRINT 

		AFTER GROUP OF pr_sort2 
			NEED 2 LINES 
			PRINT COLUMN 131, "---------------" 
			IF pr_time_frame.sort_ind = "1" THEN 
				PRINT COLUMN 4, "Total ", 
				pr_sort2 clipped; 
			ELSE 
				PRINT COLUMN 4, "Total ", 
				pr_sort1 clipped, 
				pr_sort2 clipped; 
			END IF 
			PRINT COLUMN 131, GROUP sum(pr_jobledger.trans_amt) 
			USING "----,---,-$&.&&" 
			PRINT 

		AFTER GROUP OF pr_sort1 
			NEED 3 LINES 
			PRINT COLUMN 131, "---------------" 
			IF pr_time_frame.sort_ind = "1" THEN 
				PRINT COLUMN 2, "Total ", 
				pr_sort1 clipped; 
			ELSE 
				PRINT COLUMN 2, "Total ", 
				pr_sort1 clipped; 
			END IF 
			PRINT COLUMN 131, GROUP sum(pr_jobledger.trans_amt) 
			USING "----,---,-$&.&&" 
			PRINT COLUMN 131, "===============" 
			PRINT 
			NEED 9 LINES 
			IF pr_time_frame.sort_ind = "1" THEN 
				PRINT COLUMN 01, "Cost Code:", 
				COLUMN 12, pr_sort1; 
			ELSE 
				PRINT COLUMN 01, "Zone:", 
				COLUMN 09, pr_sort1; 
			END IF 
			LET pr_amt = GROUP sum(pr_jobledger.trans_amt) 
			WHERE pr_res_type_ind = "2" 
			PRINT COLUMN 22, "Labour", 
			COLUMN 41, pr_amt USING "---,---,-$&.&&" 
			LET pr_amt = GROUP sum(pr_jobledger.trans_amt) 
			WHERE pr_res_type_ind = "1" 
			PRINT COLUMN 22, "Materials", 
			COLUMN 41, pr_amt USING "---,---,-$&.&&" 
			LET pr_amt = GROUP sum(pr_jobledger.trans_amt) 
			WHERE pr_res_type_ind = "4" 
			PRINT COLUMN 22, "Plant", 
			COLUMN 41, pr_amt USING "---,---,-$&.&&" 
			LET pr_amt = GROUP sum(pr_jobledger.trans_amt) 
			WHERE pr_res_type_ind = "3" 
			PRINT COLUMN 22, "Subcontract", 
			COLUMN 41, pr_amt USING "---,---,-$&.&&" 
			LET pr_amt = GROUP sum(pr_jobledger.trans_amt) 
			WHERE pr_res_type_ind != "1" 
			AND pr_res_type_ind != "2" 
			AND pr_res_type_ind != "3" 
			AND pr_res_type_ind != "4" 
			PRINT COLUMN 22, "Other", 
			COLUMN 41, pr_amt USING "---,---,-$&.&&" 
			PRINT COLUMN 41, "---------------" 
			PRINT COLUMN 41, GROUP sum(pr_jobledger.trans_amt) USING "---,---,-$&.&&" 
			PRINT COLUMN 41, "===============" 
			PRINT 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  

		AFTER GROUP OF pr_jobledger.job_code 
			NEED 13 LINES 
			PRINT COLUMN 131, "---------------" 
			PRINT COLUMN 1, "Job Total ", 
			pr_jobledger.job_code clipped, 
			COLUMN 131, GROUP sum(pr_jobledger.trans_amt) 
			USING "----,---,-$&.&&" 
			PRINT COLUMN 131, "===============" 
			PRINT 
			PRINT COLUMN 01, "Summary:", 
			COLUMN 12, pr_jobledger.job_code; 
			LET pr_amt = GROUP sum(pr_jobledger.trans_amt) 
			WHERE pr_res_type_ind = "2" 
			PRINT COLUMN 22, "Labour", 
			COLUMN 41, pr_amt USING "---,---,-$&.&&" 
			LET pr_amt = GROUP sum(pr_jobledger.trans_amt) 
			WHERE pr_res_type_ind = "1" 
			PRINT COLUMN 22, "Materials", 
			COLUMN 41, pr_amt USING "---,---,-$&.&&" 
			LET pr_amt = GROUP sum(pr_jobledger.trans_amt) 
			WHERE pr_res_type_ind = "4" 
			PRINT COLUMN 22, "Plant", 
			COLUMN 41, pr_amt USING "---,---,-$&.&&" 
			LET pr_amt = GROUP sum(pr_jobledger.trans_amt) 
			WHERE pr_res_type_ind = "3" 
			PRINT COLUMN 22, "Subcontract", 
			COLUMN 41, pr_amt USING "---,---,-$&.&&" 
			LET pr_amt = GROUP sum(pr_jobledger.trans_amt) 
			WHERE pr_res_type_ind != "1" 
			AND pr_res_type_ind != "2" 
			AND pr_res_type_ind != "3" 
			AND pr_res_type_ind != "4" 
			PRINT COLUMN 22, "Other", 
			COLUMN 41, pr_amt USING "---,---,-$&.&&" 
			PRINT COLUMN 41, "---------------" 
			PRINT COLUMN 41, GROUP sum(pr_jobledger.trans_amt) USING "---,---,-$&.&&" 
			PRINT COLUMN 41, "===============" 

		ON LAST ROW 
			SKIP TO top OF PAGE 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	
			
END REPORT
 