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
# \brief module JRO.4gl Job Cost Worksheet Report
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl"
GLOBALS "../common/glob_GLOBALS_report.4gl" 
GLOBALS "../jm/J_JM_GLOBALS.4gl" 
GLOBALS "../jm/JR_GROUP_GLOBALS.4gl"  
GLOBALS "../jm/JRO_GLOBALS.4gl"

#Module Scope Variables
DEFINE 
pr_jobtype RECORD LIKE jobtype.*, 
pr_jmparms RECORD LIKE jmparms.*, 
pr_underline_reqd, pr_print_all_trans CHAR(1), 
pr_print_trailer, pr_wildcard CHAR(1), 
pr_time_frame RECORD 
	to_year_num LIKE period.year_num, 
	to_period_num LIKE period.period_num, 
	to_date LIKE period.end_date, 
	content_ind CHAR(1) 
END RECORD, 
pr_cost_total, 
pr_mtd_total, 
pr_commit_total, 
pr_total LIKE activity.act_bill_amt, 
pr_jro RECORD 
	job_code CHAR(8), 
	activity_code CHAR(8), 
	var_code SMALLINT, 
	res_code CHAR(8), 
	est_cost_amt DECIMAL(16,2), 
	est_bill_amt DECIMAL(16,2), 
	act_cost_amt DECIMAL(16,2), 
	act_bill_amt DECIMAL(16,2), 
	bdgt_cost_amt DECIMAL(16,2), 
	bdgt_bill_amt DECIMAL(16,2), 
	est_cost_qty FLOAT, 
	est_bill_qty FLOAT, 
	act_cost_qty FLOAT, 
	act_bill_qty FLOAT, 
	bdgt_cost_qty FLOAT, 
	bdgt_bill_qty FLOAT, 
	unit_code CHAR(3), 
	baltocomp_amt DECIMAL(16,2) 
END RECORD 
MAIN 
	DEFINE l_msgresp LIKE language.yes_flag

	#Initial UI Init
	CALL setModuleId("JRO") -- albo 
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
			OPEN WINDOW J202 with FORM "J202" -- alch kd-747 
			CALL winDecoration_j("J202") -- alch kd-747
 
			DISPLAY BY NAME pr_jmparms.prompt1_text, 
			pr_jmparms.prompt2_text, 
			pr_jmparms.prompt3_text, 
			pr_jmparms.prompt4_text, 
			pr_jmparms.prompt5_text, 
			pr_jmparms.prompt6_text, 
			pr_jmparms.prompt7_text, 
			pr_jmparms.prompt8_text
			 
			MENU " Job Cost Worksheet" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","JRO","menu-job_cost_worksheet-1") -- alch kd-506 

				ON ACTION "WEB-HELP" -- albo kd-373 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "Report" #COMMAND "Run" " Enter selection criteria AND generate REPORT" 
					CALL rpt_rmsreps_reset(NULL) 
					CALL JRO_rpt_process(JRO_rpt_query())

				ON ACTION "Print Manager" #COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "Cancel" #COMMAND KEY("E",interrupt)"Exit" " Exit TO menus" 
					EXIT MENU 

			END MENU 

			CLOSE WINDOW J202 

	 
		WHEN "2" #Background Process with rmsreps.report_code
			CALL JRO_rpt_process(NULL)  

		WHEN "3" #Only create query-where-part
			OPEN WINDOW J202 with FORM "J202" 
			CALL winDecoration_j("J202") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(JRO_rpt_query()) #save where clause in env 
			CLOSE WINDOW J202 
			
		WHEN "4" #Background Process with SQL WHERE ARGUMENT
			CALL JRO_rpt_process(get_url_sel_text())
	END CASE
	
END MAIN 


FUNCTION JRO_rpt_query()
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

	CONSTRUCT l_where_text ON 
	job.job_code, 
	job.title_text, 
	job.type_code, 
	job.cust_code, 
	customer.name_text, 
	job.resp_code, 
	job.finish_flag, 
	activity.var_code, 
	activity.activity_code, 
	activity.title_text, 
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
	activity.var_code, 
	activity.activity_code, 
	activity.title_text, 
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
			CALL publish_toolbar("kandoo","JRO","const-job_job_code-15") -- alch kd-506 
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
		CALL get_time_frame() 
		LET glob_rec_rpt_selector.ref3_num = pr_time_frame.to_year_num 
		LET glob_rec_rpt_selector.ref4_num = pr_time_frame.to_period_num 
		LET glob_rec_rpt_selector.ref3_ind = pr_time_frame.content_ind 
		RETURN l_where_text
	END IF
END FUNCTION 


FUNCTION JRO_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx] 
	DEFINE 
	pr_activity RECORD LIKE activity.*, 
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
	pr_res_type_ind LIKE resgrp.res_type_ind, 
	pr_trans_amt LIKE jobledger.trans_amt, 
	pr_trans_qty LIKE jobledger.trans_qty, 
	pr_resbdgt RECORD LIKE resbdgt.*, 
	pr_jmresource RECORD LIKE jmresource.*, 
	pr_bdgt_ctd_amt LIKE activity.act_cost_amt 

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

	LET l_rpt_idx = rpt_start(getmoduleid(),"JRO_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT JRO_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("JRO_rpt_list")].sel_text
	#------------------------------------------------------------

	CALL create_localtemp() 

	LET pr_time_frame.to_year_num = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref3_num 
	LET pr_time_frame.to_period_num = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref4_num 
	LET pr_time_frame.content_ind = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref3_ind
	 
	LET date_text = 
	" (jobledger.year_num < ",pr_time_frame.to_year_num," ", 
	" OR (jobledger.year_num = ",pr_time_frame.to_year_num," ", 
	" AND jobledger.period_num <= ",pr_time_frame.to_period_num, 
	")) " 
	
	SELECT end_date INTO pr_time_frame.to_date 
	FROM period 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND year_num = pr_time_frame.to_year_num 
	AND period_num = pr_time_frame.to_period_num 
	IF status = notfound THEN 
		LET pr_time_frame.to_date = "31/12/9999" 
	END IF 
	
	LET l_query_text = "SELECT activity.* ", 
	"FROM job, activity, customer ", 
	" WHERE job.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
	" AND activity.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
	" AND activity.job_code = job.job_code ", 
	" AND customer.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
	" AND customer.cust_code = job.cust_code ", 
	" AND ",p_where_text clipped, 
	" ORDER BY ", 
	"activity.job_code, ", 
	"activity.var_code, ", 
	"activity.activity_code " 
	
	PREPARE s_job FROM l_query_text 
	DECLARE c_job CURSOR FOR s_job
	 
	FOREACH c_job INTO pr_activity.* 
		LET pr_costcode = pr_activity.activity_code[4,6] 
		LET pr_zone = pr_activity.activity_code[1,1] 
		LET pr_comp = pr_activity.activity_code[2,2] 
		LET pr_subc = pr_activity.activity_code[3,3] 

		#sum transaction AFTER cut off date TO be excluded
		LET pr_trans_amt = 0 
		LET pr_trans_qty = 0 

		SELECT sum(trans_amt) 
		INTO pr_trans_amt 
		FROM jobledger 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND job_code = pr_activity.job_code 
		AND jobledger.var_code = pr_activity.var_code 
		AND jobledger.activity_code = pr_activity.activity_code 
		AND (jobledger.year_num > pr_time_frame.to_year_num 
		OR (jobledger.year_num = pr_time_frame.to_year_num 
		AND jobledger.period_num > pr_time_frame.to_period_num)) 

		IF pr_trans_amt IS NULL THEN 
			LET pr_trans_amt = 0 
		END IF 

		IF pr_activity.unit_code IS NOT NULL THEN 
			SELECT sum(trans_qty) 
			INTO pr_trans_qty 
			FROM jobledger , jmresource 
			WHERE jobledger.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND job_code = pr_activity.job_code 
			AND jobledger.var_code = pr_activity.var_code 
			AND jobledger.activity_code = pr_activity.activity_code 
			AND (jobledger.year_num > pr_time_frame.to_year_num 
			OR (jobledger.year_num = pr_time_frame.to_year_num 
			AND jobledger.period_num > pr_time_frame.to_period_num)) 
			AND jmresource.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND jmresource.res_code = jobledger.trans_source_text 
			AND jmresource.unit_code = pr_activity.unit_code 
			IF pr_trans_qty IS NULL THEN 
				LET pr_trans_qty = 0 
			END IF 
		END IF 
		LET pr_activity.act_cost_amt = pr_activity.act_cost_amt - pr_trans_amt 
		LET pr_activity.act_cost_qty = pr_activity.act_cost_qty - pr_trans_qty 

		# Add outstanding TO baltocomp
		IF pr_activity.baltocomp_amt IS NULL THEN 
			LET pr_activity.baltocomp_amt = 0 
		END IF 
		IF pr_activity.bdgt_cost_amt > pr_activity.act_cost_amt THEN 
			LET pr_activity.baltocomp_amt = pr_activity.baltocomp_amt + 
			(pr_activity.bdgt_cost_amt - pr_activity.act_cost_amt) 
		ELSE 
			#LET pr_activity.baltocomp_amt = 0
		END IF 

		# calculate activity budgetted cost TO date
		IF pr_activity.act_cost_amt + pr_activity.baltocomp_amt <> 0 THEN 
			LET pr_bdgt_ctd_amt = (pr_activity.act_cost_amt / 
			(pr_activity.act_cost_amt + pr_activity.baltocomp_amt)) * 
			pr_activity.bdgt_cost_amt 
		ELSE 
			LET pr_bdgt_ctd_amt = 0 
		END IF 

		IF pr_time_frame.content_ind = "D" THEN 
			CALL extract_detail(pr_activity.*) 
		END IF 

		#---------------------------------------------------------
		OUTPUT TO REPORT JRO_rpt_list(l_rpt_idx,
		pr_zone,pr_comp,pr_subc,pr_costcode, 
		pr_activity.*, pr_time_frame.*, pr_bdgt_ctd_amt)  
		IF NOT rpt_int_flag_handler2("Job/Activity:",pr_activity.job_code, pr_activity.activity_code,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------

		DELETE FROM f_jro WHERE 1=1 

	END FOREACH 

	DROP TABLE f_jro 

	#------------------------------------------------------------
	FINISH REPORT JRO_rpt_list
	CALL rpt_finish("JRO_rpt_list")
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
	DEFINE pr_type_code LIKE job.type_code 

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
	
	OPEN WINDOW j205 with FORM "J205" -- alch kd-747 
	CALL winDecoration_j("J205") -- alch kd-747 
	LET l_msgresp = kandoomsg("U",1020,"Report") 
	#1020 Enter Report Details; OK TO Continue
	CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, today) 
	RETURNING pr_year_num, 
	pr_period_num 
	LET pr_time_frame.to_year_num = pr_year_num 
	LET pr_time_frame.to_period_num = pr_period_num 
	LET pr_time_frame.content_ind = "S" 
	INPUT BY NAME pr_time_frame.to_year_num, 
	pr_time_frame.to_period_num, 
	pr_time_frame.content_ind WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","JRO","input-pr_time-1") -- alch kd-506 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				IF pr_time_frame.to_period_num IS NULL THEN 
					LET l_msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD to_period_num 
				END IF 
				IF pr_time_frame.to_year_num IS NULL THEN 
					LET l_msgresp = kandoomsg("U",9102,"") 
					#9102 A value must be entered
					NEXT FIELD to_year_num 
				END IF 
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

	END INPUT 
	
	CLOSE WINDOW j205 
		
END FUNCTION 

FUNCTION create_localtemp() 

	CREATE temp TABLE f_jro 
	( 
	job_code CHAR(8), 
	activity_code CHAR(8), 
	var_code SMALLINT, 
	res_code CHAR(8), 
	est_cost_amt DECIMAL(16,2), 
	est_bill_amt DECIMAL(16,2), 
	act_cost_amt DECIMAL(16,2), 
	act_bill_amt DECIMAL(16,2), 
	bdgt_cost_amt DECIMAL(16,2), 
	bdgt_bill_amt DECIMAL(16,2), 
	est_cost_qty FLOAT, 
	est_bill_qty FLOAT, 
	act_cost_qty FLOAT, 
	act_bill_qty FLOAT, 
	bdgt_cost_qty FLOAT, 
	bdgt_bill_qty FLOAT, 
	unit_code CHAR(3), 
	baltocomp_amt DECIMAL(16,2) 
	) with no LOG 

END FUNCTION 

FUNCTION extract_detail(pr_activity) 
	DEFINE 
	pr_activity RECORD LIKE activity.*, 
	pr_resbdgt RECORD LIKE resbdgt.*, 
	pr_jmresource RECORD LIKE jmresource.* 

	#DISPLAY "start extract detail"
	LET pr_jro.job_code = pr_activity.job_code 
	LET pr_jro.activity_code = pr_activity.activity_code 
	LET pr_jro.var_code = pr_activity.var_code 
	LET pr_jro.res_code = NULL 
	LET pr_jro.est_cost_amt = 0 
	LET pr_jro.est_bill_amt = 0 
	LET pr_jro.act_cost_amt = 0 
	LET pr_jro.act_bill_amt = 0 
	LET pr_jro.bdgt_cost_amt = 0 
	LET pr_jro.bdgt_bill_amt = 0 
	LET pr_jro.est_cost_qty = 0 
	LET pr_jro.est_bill_qty = 0 
	LET pr_jro.act_cost_qty = 0 
	LET pr_jro.act_bill_qty = 0 
	LET pr_jro.bdgt_cost_qty = 0 
	LET pr_jro.bdgt_bill_qty = 0 
	LET pr_jro.unit_code = NULL 
	LET pr_jro.baltocomp_amt = 0 
	DECLARE res_curs CURSOR FOR 

	SELECT resbdgt.* , jmresource.* 
	INTO pr_resbdgt.*, pr_jmresource.* 
	FROM resbdgt, jmresource 
	WHERE resbdgt.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND resbdgt.job_code = pr_activity.job_code 
	AND resbdgt.var_code = pr_activity.var_code 
	AND resbdgt.activity_code = pr_activity.activity_code 
	AND jmresource.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND resbdgt.res_code = jmresource.res_code 
	FOREACH res_curs 
		LET pr_jro.res_code = pr_resbdgt.res_code 
		LET pr_jro.est_cost_amt = pr_resbdgt.est_cost_amt 
		LET pr_jro.est_bill_amt = pr_resbdgt.est_bill_amt 
		LET pr_jro.bdgt_cost_amt = pr_resbdgt.bdgt_cost_amt 
		LET pr_jro.bdgt_bill_amt = pr_resbdgt.bdgt_bill_amt 
		LET pr_jro.est_cost_qty = pr_resbdgt.est_cost_qty 
		LET pr_jro.est_bill_qty = pr_resbdgt.est_bill_qty 
		LET pr_jro.bdgt_cost_qty = pr_resbdgt.bdgt_cost_qty 
		LET pr_jro.bdgt_bill_qty = pr_resbdgt.bdgt_bill_qty 
		LET pr_jro.unit_code = pr_jmresource.unit_code 
		INSERT INTO f_jro VALUES (pr_jro.*) 
	END FOREACH 

	LET pr_jro.est_cost_amt = 0 
	LET pr_jro.est_bill_amt = 0 
	LET pr_jro.bdgt_cost_amt = 0 
	LET pr_jro.bdgt_bill_amt = 0 
	LET pr_jro.est_cost_qty = 0 
	LET pr_jro.est_bill_qty = 0 
	LET pr_jro.bdgt_cost_qty = 0 
	LET pr_jro.bdgt_bill_qty = 0 
	LET pr_jro.unit_code = NULL 

	DECLARE res_curs2 CURSOR FOR 
	SELECT jmresource.res_code, jmresource.unit_code, 
	sum(jobledger.trans_amt), sum(jobledger.trans_qty) 
	INTO pr_jro.res_code, pr_jro.unit_code, 
	pr_jro.act_cost_amt, pr_jro.act_cost_qty 
	FROM jobledger, jmresource 
	WHERE jobledger.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND jobledger.job_code = pr_activity.job_code 
	AND jobledger.var_code = pr_activity.var_code 
	AND jobledger.activity_code = pr_activity.activity_code 
	AND jmresource.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND jobledger.trans_source_text = jmresource.res_code 
	AND (jobledger.year_num < pr_time_frame.to_year_num 
	OR (jobledger.year_num = pr_time_frame.to_year_num 
	AND jobledger.period_num <= pr_time_frame.to_period_num)) 
	GROUP BY 1,2 

	FOREACH res_curs2 
		IF pr_jro.unit_code != pr_activity.unit_code THEN 
			#OR pr_activity.unit_code IS NULL THEN
			LET pr_jro.act_cost_qty = 0 
		END IF 
		INSERT INTO f_jro VALUES (pr_jro.*) 
	END FOREACH 

	#DISPLAY "END extract"
END FUNCTION 


REPORT JRO_rpt_list(p_rpt_idx,pr_zone, pr_comp, pr_subc, pr_costcode, pr_activity, pr_time_frame, pr_bdgt_ctd_amt)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx] 
	DEFINE 
	pr_zone, 
	pr_comp, 
	pr_subc, 
	pr_costcode LIKE activity.activity_code, 
	pr_activity RECORD LIKE activity.*, 
	pr_unit_code LIKE jmresource.unit_code, 
	pr_resgrp_code LIKE resgrp.resgrp_code, 
	pr_res_type_ind LIKE resgrp.res_type_ind, 
	pr_amt LIKE jobledger.trans_amt, 
	pr_bdgt_ctd_amt LIKE activity.act_cost_amt, 
	pr_time_frame RECORD 
		to_year_num LIKE period.year_num, 
		to_period_num LIKE period.period_num, 
		to_date LIKE period.end_date, 
		content_ind CHAR(1) 
	END RECORD, 
	pr_job RECORD LIKE job.*, 
	pr_open_bal LIKE jobledger.trans_amt, 
	held_order_num LIKE purchhead.order_num, 
	pr_ref_text CHAR(20), 
	pr_vend_code LIKE vendor.vend_code, 
	pr_cust_name_text LIKE customer.name_text, 
	pr_jobtype_text LIKE jobtype.type_text, 
	pr_resp_name_text LIKE responsible.name_text, 
	pr_comp_per LIKE activity.est_comp_per, 
	pa_line array[4] OF CHAR(150), 
	pr_divisor LIKE activity.baltocomp_amt 

	OUTPUT 
	left margin 0 
	PAGE length 66 
	top margin 0 
	bottom margin 0 
	ORDER external BY pr_activity.job_code, 
	pr_activity.var_code, 
	pr_zone, pr_comp, pr_subc, pr_costcode 
	FORMAT 
		PAGE HEADER 
			PRINT 
			PRINT 
			PRINT 
			PRINT 


		FIRST PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  
	
			PRINT "Job Code,Zone,Component,Sub,Cost Code,Title,Resource,,", 
			" ,Original,,", 
			" ,Revised,,", 
			" ,Budget TO Date,,", 
			" ,Actual TO Date,,", 
			" Var'n,", 
			" ,Cost TO Complete,,", 
			" ,Cost AT Completion,,", 
			" Var'n,", 
			"%" 
			PRINT ",,,,,,,Unit,", 
			"Qty, Rate, Amount, ", 
			"Qty, Rate, Amount, ", 
			"Qty, Rate, Amount, ", 
			"Qty, Rate, Amount, ", 
			"($), ", 
			"Qty, Rate, Amount, ", 
			"Qty, Rate, Amount, ", 
			"($),", 
			"Comp" 
		PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

		BEFORE GROUP OF pr_activity.job_code 
			SKIP TO top OF PAGE 

			SELECT * INTO pr_job.* 
			FROM job 
			WHERE cmpy_code = pr_activity.cmpy_code 
			AND job_code = pr_activity.job_code 
			IF status = notfound THEN 
				LET pr_job.title_text = "*** JOB NOT FOUND ***" 
			END IF 

			SELECT name_text INTO pr_cust_name_text 
			FROM customer 
			WHERE cust_code = pr_job.cust_code 
			AND cmpy_code = pr_activity.cmpy_code 
			IF status = notfound THEN 
				LET pr_cust_name_text = "*** CUSTOMER NOT FOUND ***" 
			END IF 

			SELECT type_text INTO pr_jobtype_text 
			FROM jobtype 
			WHERE cmpy_code = pr_activity.cmpy_code 
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

			PRINT "Job Code: ", 
			pr_activity.job_code, 
			pr_job.title_text, 
			"Cust: ", 
			pr_job.cust_code, 
			pr_cust_name_text, 
			"Type: ", 
			pr_job.type_code, 
			pr_jobtype_text, 
			"Resp: ", 
			pr_resp_name_text, 
			"Ending: ", 
			pr_time_frame.to_date USING "dd/mm/yyyy" 
			#PRINT COLUMN 01, "Terr:"
			#PRINT COLUMN 02, pr_zone clipped, " ", pr_comp clipped, " ",
			#pr_subc clipped,
			#BEFORE GROUP OF pr_costcode
			#IF pr_time_frame.content_ind = "D" THEN
			#PRINT pr_activity.job_code,",",pr_zone,",",
			#pr_comp,",",pr_subc,",";
			#PRINT pr_costcode clipped,",",
			#pr_activity.title_text,",";
			#END IF

		ON EVERY ROW 
			IF pr_time_frame.content_ind = "D" THEN 
				DECLARE a_curs CURSOR FOR 
				SELECT job_code , activity_code , var_code , res_code , 
				sum(est_cost_amt ), sum(est_bill_amt ), sum(act_cost_amt ), 
				sum(act_bill_amt ), sum(bdgt_cost_amt), sum(bdgt_bill_amt), 
				sum(est_cost_qty), sum(est_bill_qty), sum(act_cost_qty), 
				sum(act_bill_qty), sum(bdgt_cost_qty), sum(bdgt_bill_qty), 
				unit_code, 0 
				FROM f_jro 
				GROUP BY 1,2,3,4,17, 18 
				ORDER BY 4 
				FOREACH a_curs INTO pr_jro.* 
					# Add outstanding TO baltocomp
					IF pr_jro.baltocomp_amt IS NULL THEN 
						LET pr_jro.baltocomp_amt = 0 
					END IF 
					IF pr_jro.bdgt_cost_amt > pr_jro.act_cost_amt THEN 
						LET pr_jro.baltocomp_amt = pr_jro.baltocomp_amt + 
						(pr_jro.bdgt_cost_amt - pr_jro.act_cost_amt) 
					ELSE 
						#LET pr_jro.baltocomp_amt = 0
					END IF 
					WHENEVER ERROR stop 
					PRINT pr_activity.job_code,",",pr_zone,",", 
					pr_comp,",",pr_subc,","; 
					PRINT "'",pr_costcode clipped,",", 
					pr_activity.title_text,","; 
					PRINT pr_jro.res_code,",", 
					pr_jro.unit_code,",", 
					# Original Budget
					pr_jro.est_cost_qty USING "----&",","; 
					IF pr_jro.est_cost_qty <> 0 THEN 
						PRINT pr_jro.est_cost_amt / pr_jro.est_cost_qty 
						USING "-------&",","; 
					ELSE 
						PRINT 0 USING "-------&",","; 
					END IF 
					PRINT pr_jro.est_cost_amt USING "-------&",","; 
					# Revised Budget
					PRINT pr_jro.bdgt_cost_qty USING "----&",","; 
					IF pr_jro.bdgt_cost_qty <> 0 THEN 
						PRINT pr_jro.bdgt_cost_amt / pr_jro.bdgt_cost_qty 
						USING "-------&",","; 
					ELSE 
						PRINT 0 USING "-------&",","; 
					END IF 
					PRINT pr_jro.bdgt_cost_amt USING "-------&",","; 
					# Budgetted Cost TO Date
					PRINT pr_jro.act_cost_qty USING "----&",","; 

					IF pr_jro.act_cost_qty <> 0 THEN 
						PRINT ((pr_jro.act_cost_amt / 
						(pr_jro.act_cost_amt + pr_jro.baltocomp_amt)) * 
						pr_jro.bdgt_cost_amt) / pr_jro.act_cost_qty 
						USING "-------&",","; 
					ELSE 
						PRINT 0 USING "-------&",","; 
					END IF 
					IF (pr_jro.act_cost_amt + pr_jro.baltocomp_amt) <> 0 THEN 
						PRINT (pr_jro.act_cost_amt / 
						(pr_jro.act_cost_amt + pr_jro.baltocomp_amt)) * 
						pr_jro.bdgt_cost_amt USING "-------&",","; 
					ELSE 
						PRINT 0 USING "-------&",","; 
					END IF 
					# Actual Cost TO date
					PRINT pr_jro.act_cost_qty USING "----&",","; 
					IF pr_jro.act_cost_qty <> 0 THEN 
						PRINT pr_jro.act_cost_amt / pr_jro.act_cost_qty 
						USING "-------&",","; 
					ELSE 
						PRINT 0 USING "-------&",","; 
					END IF 
					PRINT pr_jro.act_cost_amt USING "-------&",","; 
					# Variation
					IF (pr_jro.act_cost_amt + pr_jro.baltocomp_amt) <> 0 THEN 
						#( ( ( D / (D + E)) * B) - D)
						PRINT 0 - 
						( ( ( pr_jro.act_cost_amt / 
						(pr_jro.act_cost_amt + pr_jro.baltocomp_amt)) * 
						pr_jro.bdgt_cost_amt) - pr_jro.act_cost_amt) 
						USING "-------&",","; 
					ELSE 
						PRINT 0 USING "-------&",","; 
					END IF 
					# Cost TO complete
					IF pr_jro.bdgt_cost_qty > pr_jro.act_cost_qty THEN 
						PRINT pr_jro.bdgt_cost_qty - 
						pr_jro.act_cost_qty USING "----&",","; 
					ELSE 
						PRINT 0 USING "----&",","; 
					END IF 
					PRINT 0 USING "-------&",",", 
					pr_jro.baltocomp_amt USING "-------&",","; 
					# cost AT completion
					IF pr_jro.bdgt_cost_qty > pr_jro.act_cost_qty THEN 
						PRINT pr_jro.bdgt_cost_qty USING "----&",","; 
					ELSE 
						PRINT pr_jro.act_cost_qty USING "----&",","; 
					END IF 
					IF pr_jro.bdgt_cost_qty > pr_jro.act_cost_qty THEN 
						IF pr_jro.bdgt_cost_qty <> 0 THEN 
							PRINT (pr_jro.baltocomp_amt + 
							pr_jro.act_cost_amt)/ 
							pr_jro.bdgt_cost_qty USING "-------&",","; 
						ELSE 
							PRINT 0 USING "-------&",","; 
						END IF 
					ELSE 
						IF pr_jro.act_cost_qty <> 0 THEN 
							PRINT (pr_jro.baltocomp_amt + 
							pr_jro.act_cost_amt)/ 
							pr_jro.act_cost_qty USING "-------&",","; 
						ELSE 
							PRINT 0 USING "-------&",","; 
						END IF 
					END IF 
					PRINT pr_jro.baltocomp_amt + pr_jro.act_cost_amt 
					USING "-------&",","; 
					# Variation
					PRINT 0 - (pr_jro.bdgt_cost_amt - 
					(pr_jro.baltocomp_amt + 
					pr_jro.act_cost_amt)) USING "-------&",","; 
					# % comp
					IF (pr_jro.act_cost_amt + pr_jro.baltocomp_amt) <> 0 THEN 
						PRINT ((pr_jro.act_cost_amt / 
						(pr_jro.act_cost_amt + pr_jro.baltocomp_amt))) * 100 
						USING "---&","%" 
					ELSE 
						PRINT 0 USING "---&","%" 
					END IF 
				END FOREACH 
			END IF 

		AFTER GROUP OF pr_costcode 
			IF pr_time_frame.content_ind = "S" THEN 
				PRINT pr_activity.job_code,",",pr_zone,",", 
				pr_comp,",",pr_subc,","; 
				PRINT "'",pr_costcode clipped,",", 
				pr_activity.title_text,",,"; 
				PRINT pr_activity.unit_code,","; 
				# Original Budget
				PRINT pr_activity.est_cost_qty USING "----&",","; 
				IF pr_activity.est_cost_qty <> 0 THEN 
					PRINT pr_activity.est_cost_amt / pr_activity.est_cost_qty 
					USING "-------&",","; 
				ELSE 
					PRINT 0 USING "-------&",","; 
				END IF 
				PRINT pr_activity.est_cost_amt USING "-------&",","; 
				# Revised Budget
				PRINT pr_activity.bdgt_cost_qty USING "----&",","; 
				IF pr_activity.bdgt_cost_qty <> 0 THEN 
					PRINT pr_activity.bdgt_cost_amt / 
					pr_activity.bdgt_cost_qty USING "-------&",","; 
				ELSE 
					PRINT 0 USING "-------&",","; 
				END IF 
				PRINT pr_activity.bdgt_cost_amt USING "-------&",","; 
				# Budgetted Cost TO Date
				PRINT pr_activity.act_cost_qty USING "----&",","; 
				IF pr_activity.act_cost_qty <> 0 THEN 
					# PRINT ((pr_activity.act_cost_amt /
					#          (pr_activity.act_cost_amt + pr_activity.baltocomp_amt)) *
					#          pr_activity.bdgt_cost_amt) / pr_activity.act_cost_qty
					PRINT pr_bdgt_ctd_amt / pr_activity.act_cost_qty 
					USING "-------&",","; 
				ELSE 
					PRINT 0 USING "-------&",","; 
				END IF 
				PRINT pr_bdgt_ctd_amt USING "-------&",","; 
				#IF (pr_activity.act_cost_amt + pr_activity.baltocomp_amt) <> 0 THEN
				#PRINT (pr_activity.act_cost_amt /
				#         (pr_activity.act_cost_amt + pr_activity.baltocomp_amt)) *
				#         pr_activity.bdgt_cost_amt using "-------&",",";
				#ELSE
				#   PRINT 0 using "-------&",",";
				#END IF
				# Actual Cost TO date
				PRINT pr_activity.act_cost_qty USING "----&",","; 
				IF pr_activity.act_cost_qty <> 0 THEN 
					PRINT pr_activity.act_cost_amt / 
					pr_activity.act_cost_qty USING "-------&",","; 
				ELSE 
					PRINT 0 USING "-------&",","; 
				END IF 
				PRINT pr_activity.act_cost_amt USING "-------&",","; 
				# Variation
				IF (pr_activity.act_cost_amt + pr_activity.baltocomp_amt) <> 0 THEN 
					PRINT 0 - (((pr_activity.act_cost_amt / 
					(pr_activity.act_cost_amt + pr_activity.baltocomp_amt)) * 
					pr_activity.bdgt_cost_amt) - pr_activity.act_cost_amt) 
					USING "-------&",","; 
				ELSE 
					PRINT 0 USING "-------&",","; 
				END IF 
				# Cost TO complete
				IF pr_activity.bdgt_cost_qty > pr_activity.act_cost_qty THEN 
					PRINT pr_activity.bdgt_cost_qty - 
					pr_activity.act_cost_qty USING "----&",","; 
				ELSE 
					PRINT 0 USING "----&",","; 
				END IF 
				PRINT 0 USING "-------&",",", 
				pr_activity.baltocomp_amt USING "-------&",","; 
				# cost AT completion
				IF pr_activity.bdgt_cost_qty > pr_activity.act_cost_qty THEN 
					PRINT pr_activity.bdgt_cost_qty USING "----&",","; 
				ELSE 
					PRINT pr_activity.act_cost_qty USING "----&",","; 
				END IF 
				IF pr_activity.bdgt_cost_qty > pr_activity.act_cost_qty THEN 
					IF pr_activity.bdgt_cost_qty <> 0 THEN 
						PRINT (pr_activity.baltocomp_amt + 
						pr_activity.act_cost_amt)/ 
						pr_activity.bdgt_cost_qty USING "-------&",","; 
					ELSE 
						PRINT 0 USING "-------&",","; 
					END IF 
				ELSE 
					IF pr_activity.act_cost_qty <> 0 THEN 
						PRINT (pr_activity.baltocomp_amt + 
						pr_activity.act_cost_amt)/ 
						pr_activity.act_cost_qty USING "-------&",","; 
					ELSE 
						PRINT 0 USING "-------&",","; 
					END IF 
				END IF 
				PRINT pr_activity.baltocomp_amt + pr_activity.act_cost_amt 
				USING "-------&",","; 
				# Variation
				PRINT 0 - (pr_activity.bdgt_cost_amt - 
				(pr_activity.baltocomp_amt + 
				pr_activity.act_cost_amt)) USING "-------&",","; 
				# % comp
				IF (pr_activity.act_cost_amt + pr_activity.baltocomp_amt) <> 0 THEN 
					PRINT ((pr_activity.act_cost_amt / 
					(pr_activity.act_cost_amt + pr_activity.baltocomp_amt))) * 100 
					USING "---&","%" 
				ELSE 
					PRINT 0 USING "---&","%" 
				END IF 
				IF pr_time_frame.content_ind = "D" THEN 
					PRINT 
				END IF 
			END IF 
			#PRINT "123456789 123456789 123456789 123456789 123456789 ",
			#"123456789 123456789 123456789 123456789 123456789 ",
			#"123456789 123456789 123456789 123456789 123456789 ",
			#"123456789 123456789 123456789 123456789 123456789 "

		AFTER GROUP OF pr_subc 
			#AFTER GROUP OF pr_activity.activity_code
			#IF pr_time_frame.content_ind = "D" THEN
			PRINT pr_activity.job_code,",,,,,Total:,,,,,"; 
			PRINT GROUP sum(pr_activity.est_cost_amt) USING "-------$&",",,,", 
			GROUP sum(pr_activity.bdgt_cost_amt) USING "-------$&",",,,"; 
			PRINT GROUP sum(pr_bdgt_ctd_amt) USING "-------$&",",,,"; 
			PRINT GROUP sum(pr_activity.act_cost_amt) USING "-------$&",","; 
			PRINT GROUP sum(pr_bdgt_ctd_amt) - GROUP sum(pr_activity.act_cost_amt) 
			USING "-------$&", ",,,"; 
			PRINT GROUP sum(pr_activity.baltocomp_amt) USING "-------$&",",,,"; 
			PRINT GROUP sum(pr_activity.baltocomp_amt + 
			pr_activity.act_cost_amt) USING "-------$&",",", 
			0 - (group sum(pr_activity.bdgt_cost_amt - 
			(pr_activity.baltocomp_amt + 
			pr_activity.act_cost_amt))) USING "------$&" 
			#END IF

		ON LAST ROW 
			NEED 3 LINES 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	
			
END REPORT