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
GLOBALS "../jm/JR1_GLOBALS.4gl"

#Module Scope Variables
DEFINE 
pr_jobtype RECORD LIKE jobtype.*, 
pr_jmparms RECORD LIKE jmparms.*, 
pr_underline_reqd, pr_print_all_trans CHAR(1), 
pr_print_trailer, pr_wildcard CHAR(1), 
pr_time_frame RECORD 
	from_year_num LIKE period.year_num, 
	from_period_num LIKE period.period_num, 
	to_year_num LIKE period.year_num, 
	to_period_num LIKE period.period_num, 
	zero_trans CHAR(1) 
END RECORD, 
pr_cost_total, 
pr_mtd_total, 
pr_commit_total, 
pr_total LIKE activity.act_bill_amt 

# Purpose - Activity Transaction Report
MAIN 
	DEFINE l_msgresp LIKE language.yes_flag

	#Initial UI Init
	CALL setModuleId("JR1") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	SELECT jmparms.* INTO pr_jmparms.* FROM jmparms 
	WHERE jmparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND jmparms.key_code = "1" 
	IF status = notfound THEN 
		LET l_msgresp = kandoomsg("J",7505,"")#7505" Job Management Parameters NOT found - Refer Menu JZP "
		EXIT program 
	END IF 
	
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

			MENU " Activity Transaction Report" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","JR1","menu-act_transaction_report-1") -- alch kd-506
					CALL rpt_rmsreps_reset(NULL) 
					CALL JR1_rpt_process(JR1_rpt_query()) 

 					
				ON ACTION "WEB-HELP" -- albo kd-373 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "REPORT" --COMMAND "Run" " Enter selection criteria AND generate REPORT"
					CALL rpt_rmsreps_reset(NULL) 
					CALL JR1_rpt_process(JR1_rpt_query()) 

				ON ACTION "Print Manager" 				#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "CANCEL" --COMMAND KEY("E",interrupt)"Exit" " Exit TO menus" 
					EXIT MENU 
			END MENU 

			CLOSE WINDOW J318 

		WHEN "2" #Background Process with rmsreps.report_code
			CALL JR1_rpt_process(NULL)  

		WHEN "3" #Only create query-where-part
			OPEN WINDOW J318 with FORM "J318" 
			CALL winDecoration_j("J318") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(JR1_rpt_query()) #save where clause in env 
			CLOSE WINDOW J318 
			
		WHEN "4" #Background Process with SQL WHERE ARGUMENT
			CALL JR1_rpt_process(get_url_sel_text())
	END CASE 
END MAIN 


FUNCTION JR1_rpt_query() 
	DEFINE 
	pr_type_code LIKE job.type_code 
	DEFINE l_msgresp LIKE language.yes_flag
	DEFINE l_where_text STRING #sel_text
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]

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
	LET l_msgresp = kandoomsg("U",1001,"") 
	#1001 "Enter Selection Criteria; OK TO Continue"
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
			CALL publish_toolbar("kandoo","JR1","const-job_job_code-4") -- alch kd-506
 
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
		RETURN false 
	END IF 
	LET pr_print_all_trans = "N" 
	CALL get_time_frame() 

	LET glob_rec_rpt_selector.ref1_num = pr_time_frame.from_year_num 
	LET glob_rec_rpt_selector.ref2_num = pr_time_frame.from_period_num 
	LET glob_rec_rpt_selector.ref3_num = pr_time_frame.to_year_num 
	LET glob_rec_rpt_selector.ref4_num = pr_time_frame.to_period_num 
	LET glob_rec_rpt_selector.ref1_ind = pr_time_frame.zero_trans 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL
	ELSE
		RETURN l_where_text 
	END IF 
	
END FUNCTION 


FUNCTION JR1_rpt_process(p_where_text)
	DEFINE p_where_text STRING
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	 
	DEFINE 
	pr_activity RECORD LIKE activity.*, 
	pr_job RECORD LIKE job.*, 
	pr_order_text CHAR(13), 
	query_text CHAR(2500) 

	LET pr_cost_total = 0 
	LET pr_mtd_total = 0 
	LET pr_commit_total = 0 
	LET pr_total = 0 

	LET pr_wildcard = "N" 
	LET pr_print_trailer = "N" 
	LET pr_underline_reqd = "N"

	
	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start(getmoduleid(),"JR1_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT JR1_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("JR1_rpt_list")].sel_text
	#------------------------------------------------------------

	LET pr_time_frame.from_year_num = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref1_num 
	LET pr_time_frame.from_period_num = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref2_num 
	LET pr_time_frame.to_year_num = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref3_num 
	LET pr_time_frame.to_period_num = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref4_num 
	LET pr_time_frame.zero_trans = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref1_ind
	 
	LET pr_print_all_trans = pr_time_frame.zero_trans
	 
	LET query_text = "SELECT job.title_text,activity.*", 
	" FROM job, activity", 
	" WHERE job.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
	" AND activity.cmpy_code = job.cmpy_code ", 
	" AND activity.job_code = job.job_code ", 
	" AND ",p_where_text clipped," ", 
	" ORDER BY activity.cmpy_code, ", 
	"activity.job_code, ", 
	"activity.var_code, ", 
	"activity.activity_code" 
	PREPARE s_job FROM query_text 
	DECLARE c_job CURSOR FOR s_job
	 
	FOREACH c_job INTO pr_job.title_text, pr_activity.* 
		LET pr_order_text = pr_activity.var_code USING "&&&&&",	pr_activity.activity_code

		#---------------------------------------------------------
		OUTPUT TO REPORT JR1_rpt_list(l_rpt_idx,
		pr_job.title_text,pr_activity.*,pr_order_text) 
		IF NOT rpt_int_flag_handler2("Job/Activity:",pr_job.title_text, pr_activity.title_text,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------		 
 
	END FOREACH 
 
	#------------------------------------------------------------
	FINISH REPORT JR1_rpt_list
	CALL rpt_finish("JR1_rpt_list")
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
	
	OPEN WINDOW j319 with FORM "J319" -- alch kd-747 
	CALL winDecoration_j("J319") -- alch kd-747 
	LET l_msgresp = kandoomsg("U",1020,"Report") 
	#1020 Enter Report Details; OK TO Continue
	CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, today) 
	RETURNING pr_year_num, 
	pr_period_num 
	LET pr_time_frame.to_year_num = pr_year_num 
	LET pr_time_frame.to_period_num = pr_period_num 
	LET pr_time_frame.from_year_num = pr_year_num 
	LET pr_time_frame.from_period_num = pr_period_num 
	LET pr_time_frame.zero_trans = "N" 
	INPUT BY NAME pr_time_frame.from_year_num, 
	pr_time_frame.from_period_num, 
	pr_time_frame.to_year_num, 
	pr_time_frame.to_period_num, 
	pr_time_frame.zero_trans WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","JR1","input-pr_time_frame-1") -- alch kd-506 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

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
				IF pr_time_frame.from_year_num IS NULL THEN 
					LET pr_time_frame.from_year_num = 0 
					LET pr_time_frame.from_period_num = 0 
				END IF 
				IF pr_time_frame.to_year_num IS NULL THEN 
					LET pr_time_frame.to_year_num = 9999 
					LET pr_time_frame.to_period_num = 99 
				END IF 
			END IF 

	END INPUT 	
	
	CLOSE WINDOW j319 
	
END FUNCTION 




REPORT JR1_rpt_list(p_rpt_idx,pr_title_text, pr_activity, pr_order_text) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE 
	pr_title_text LIKE job.title_text, 
	pr_activity RECORD LIKE activity.*, 
	pr_order_text CHAR(13), 
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
	END RECORD

	OUTPUT 
	 
	ORDER external BY pr_activity.job_code,	pr_order_text 
	
	FORMAT 
		PAGE HEADER
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  

			LET pr_underline_reqd = "Y" 
			
		BEFORE GROUP OF pr_activity.job_code 
			LET job_head_flag = 0 
			LET job_tot_print = 0 
			IF pr_print_all_trans = "Y" THEN 
				SKIP TO top OF PAGE 
				LET job_tot_print = 1 
				LET job_head_flag = 1 
				PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]
				PRINT "Job:", 
				COLUMN 09, pr_activity.job_code, 
				COLUMN 18, ": ", pr_title_text 
				PRINT "Activity Details" 
				LET pr_underline_reqd = "N" 
			END IF
			 
			LET job_cost_amt = 0 
			LET job_mtd_amt = 0 
			LET job_commit_amt = 0 
			LET job_total = 0
			 
		ON EVERY ROW 
			SELECT sum(trans_amt) INTO pr_open_bal FROM jobledger 
			WHERE cmpy_code = pr_activity.cmpy_code 
			AND job_code = pr_activity.job_code 
			AND var_code = pr_activity.var_code 
			AND activity_code = pr_activity.activity_code 
			AND trans_type_ind <> 'SA' 
			AND trans_type_ind <> 'CO' 
			AND (year_num < pr_time_frame.from_year_num 
			OR (year_num = pr_time_frame.from_year_num AND 
			period_num < pr_time_frame.from_period_num)) 
			IF pr_open_bal IS NULL THEN 
				LET pr_open_bal = 0 
			END IF 
			LET act_head_flag = 0 
			IF pr_print_all_trans = "Y" THEN 
				LET act_head_flag = 1 
				NEED 9 LINES 
				IF pr_underline_reqd = "Y" THEN 
					LET pr_underline_reqd = "N" 
					PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]
				END IF 
				SKIP 1 LINES 
				PRINT "Description ..........", pr_activity.title_text 
				PRINT "Code: ", pr_activity.activity_code, 
				COLUMN 18, "Variation", pr_activity.var_code 
				PRINT "----------------------------------------------------------- ", 
				"TRANSACTIONS ", 
				"-----------------------------------------------------------" 
				PRINT COLUMN 01, "Date", 
				COLUMN 10, "Type", 
				COLUMN 19, "No.", 
				COLUMN 24, "Text", 
				COLUMN 35, "Cost Amount", 
				COLUMN 48, "MTD Cost Amount", 
				COLUMN 65, "Posted", 
				COLUMN 72, "Description", 
				COLUMN 105, "Commitments", 
				COLUMN 128, "Total" 
				PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]
				IF pr_open_bal != 0 THEN 
					PRINT COLUMN 1, "Previous Periods ", 
					COLUMN 33, pr_open_bal USING "---------&.&&" 
				END IF 
			END IF 
			DECLARE jobledger_curs CURSOR FOR 
			SELECT * FROM jobledger 
			WHERE cmpy_code = pr_activity.cmpy_code 
			AND job_code = pr_activity.job_code 
			AND var_code = pr_activity.var_code 
			AND activity_code = pr_activity.activity_code 
			AND trans_type_ind <> 'SA' 
			AND trans_type_ind <> 'CO' 
			AND (year_num > pr_time_frame.from_year_num 
			OR (year_num = pr_time_frame.from_year_num AND 
			period_num >= pr_time_frame.from_period_num)) 
			AND (year_num < pr_time_frame.to_year_num 
			OR (year_num = pr_time_frame.to_year_num AND 
			period_num <= pr_time_frame.to_period_num)) 
			ORDER BY cmpy_code, trans_date 
			LET acti_cost_amt_tot = 0 
			LET acti_cost_amt_tot2 = 0 
			LET total_commit_amt = 0 
			LET activity_total = 0
			 
			FOREACH jobledger_curs INTO pr_jobledger.* 
				IF job_head_flag = 0 THEN 
					LET job_tot_print = 1 
					LET job_head_flag = 1 
					SKIP TO top OF PAGE 
					PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]
					PRINT "Job:", 
					COLUMN 9, pr_activity.job_code, 
					COLUMN 18, ": ", pr_title_text 
					PRINT "Activity Details" 
					LET pr_underline_reqd = "N" 
				END IF 
				IF act_head_flag = 0 THEN 
					LET act_head_flag = 1 
					NEED 8 LINES 
					SKIP 1 LINES 
					PRINT COLUMN 01, "Code: ", pr_activity.activity_code, 
					COLUMN 20, "Description :", pr_activity.title_text, 
					COLUMN 70, "Variation", pr_activity.var_code 
					PRINT "----------------------------------------------------------- ", 
					"TRANSACTIONS ", 
					"-----------------------------------------------------------" 
					PRINT COLUMN 1, "Date", 
					COLUMN 10, "Type", 
					COLUMN 19, "No.", 
					COLUMN 24, "Text", 
					COLUMN 35, "Cost Amount", 
					COLUMN 48, "MTD Cost Amount", 
					COLUMN 65, "Posted", 
					COLUMN 72, "Description", 
					COLUMN 105, "Commitments", 
					COLUMN 128, "Total" 
					PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
					IF pr_open_bal != 0 THEN 
						PRINT COLUMN 1, "Previous Periods ", 
						COLUMN 33, pr_open_bal USING "---------&.&&" 
					END IF 
				END IF 
				
				IF pr_jobledger.desc_text IS NULL THEN 
					IF pr_jobledger.trans_type_ind = "RE" 
					OR pr_jobledger.trans_type_ind = "TP" 
					OR pr_jobledger.trans_type_ind = "TS" THEN 
						SELECT * INTO pr_jmresource.* FROM jmresource 
						WHERE cmpy_code = pr_jobledger.cmpy_code 
						AND res_code = pr_jobledger.trans_source_text 
						LET pr_jobledger.desc_text = pr_jmresource.desc_text 
					END IF 
				END IF 
				NEED 2 LINES 
				LET pr_print_trailer = "Y" 
				IF pr_underline_reqd = "Y" THEN 
					LET pr_underline_reqd = "N" 
					PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]
				END IF 
				
				PRINT COLUMN 01 , pr_jobledger.trans_date USING "dd/mm/yy", 
				COLUMN 11, pr_jobledger.trans_type_ind, 
				COLUMN 15, pr_jobledger.trans_source_num USING "--------", 
				COLUMN 24, pr_jobledger.trans_source_text, 
				COLUMN 33, pr_jobledger.trans_amt USING "---------&.&&", 
				COLUMN 48, pr_jobledger.trans_amt USING "-----------&.&&", 
				COLUMN 68, pr_jobledger.posted_flag, 
				COLUMN 72, pr_jobledger.desc_text 
				IF pr_jobledger.trans_amt IS NOT NULL THEN 
					LET acti_cost_amt_tot = acti_cost_amt_tot 
					+ pr_jobledger.trans_amt 
					LET acti_cost_amt_tot2 = acti_cost_amt_tot2 
					+ pr_jobledger.trans_amt 
				END IF 
			END FOREACH 
			
			LET pr_print_trailer = "N" 
			DECLARE purch_curs CURSOR FOR 
			SELECT purchhead.order_date, 
			purchdetl.order_num, 
			purchdetl.res_code, 
			purchdetl.line_num, 
			poaudit.posted_flag, 
			purchdetl.desc_text, 
			poaudit.order_qty, 
			poaudit.received_qty, 
			poaudit.unit_cost_amt, 
			poaudit.unit_tax_amt 
			INTO pr_purchdetl.* 
			FROM purchhead, purchdetl,poaudit 
			WHERE purchhead.cmpy_code = pr_activity.cmpy_code 
			AND purchdetl.cmpy_code = pr_activity.cmpy_code 
			AND poaudit.cmpy_code = pr_activity.cmpy_code 
			AND purchhead.order_num = purchdetl.order_num 
			AND purchhead.order_num = poaudit.po_num 
			AND purchdetl.job_code = pr_activity.job_code 
			AND purchdetl.var_num = pr_activity.var_code 
			AND purchdetl.activity_code = pr_activity.activity_code 
			AND purchdetl.line_num = poaudit.line_num 
			ORDER BY purchhead.order_date 

			LET held_order_num = 0 
			FOREACH purch_curs 
				IF held_order_num <> pr_purchdetl.order_num THEN 
					LET held_order_num = pr_purchdetl.order_num 
					CALL po_line_info(glob_rec_kandoouser.cmpy_code, 
					pr_purchdetl.order_num, 
					pr_purchdetl.line_num) 
					RETURNING pr_poaudit.order_qty, 
					pr_poaudit.received_qty, 
					pr_poaudit.voucher_qty, 
					pr_poaudit.unit_cost_amt, 
					pr_poaudit.ext_cost_amt, 
					pr_poaudit.unit_tax_amt, 
					pr_poaudit.ext_tax_amt, 
					pr_poaudit.line_total_amt 
				END IF 
				IF pr_poaudit.order_qty > pr_poaudit.received_qty THEN 
					IF job_head_flag = 0 THEN 
						LET job_tot_print = 1 
						LET job_head_flag = 1 
						SKIP TO top OF PAGE 
						PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]
						PRINT "Job:", 
						COLUMN 9, pr_activity.job_code, 
						COLUMN 18, ": ", pr_title_text 
						PRINT "Activity Details" 
						LET pr_underline_reqd = "N" 
					END IF 
					IF act_head_flag = 0 THEN 
						LET act_head_flag = 1 
						NEED 8 LINES 
						SKIP 1 LINES 
						PRINT COLUMN 01, "Code: ", pr_activity.activity_code, 
						COLUMN 20, "Description :", pr_activity.title_text, 
						COLUMN 70, "Variation", pr_activity.var_code 
						PRINT "----------------------------------------------------------- ", 
						"TRANSACTIONS ", 
						"-----------------------------------------------------------" 
						PRINT COLUMN 01, "Date", 
						COLUMN 10, "Type", 
						COLUMN 19, "No.", 
						COLUMN 24, "Text", 
						COLUMN 35, "Cost Amount", 
						COLUMN 48, "MTD Cost Amount", 
						COLUMN 65, "Posted", 
						COLUMN 72, "Description", 
						COLUMN 105, "Commitments", 
						COLUMN 128, "Total" 
						PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
						IF pr_open_bal != 0 THEN 
							PRINT COLUMN 01, "Previous Periods ", 
							COLUMN 33, pr_open_bal USING "---------&.&&" 
						END IF 
					END IF 
					LET commit_amt = 
					(pr_purchdetl.unit_cost_amt + pr_purchdetl.unit_tax_amt) * 
					(pr_purchdetl.order_qty - pr_purchdetl.received_qty) 
					LET pr_print_trailer = "Y" 
					NEED 2 LINES 
					IF pr_underline_reqd = "Y" THEN 
						LET pr_underline_reqd = "N" 
						PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]
					END IF 
					PRINT COLUMN 01, pr_purchdetl.order_date USING "dd/mm/yy", 
					COLUMN 11, "PO", 
					COLUMN 15, pr_purchdetl.order_num USING "########", 
					COLUMN 24, pr_purchdetl.res_code[1,8], 
					COLUMN 68, pr_purchdetl.posted_flag, 
					COLUMN 72, pr_purchdetl.desc_text[1,30], 
					COLUMN 103, commit_amt USING "---------&.&&" 
					LET total_commit_amt = total_commit_amt + commit_amt 
				END IF 
			END FOREACH 
			LET pr_print_trailer = "N" 
			
		AFTER GROUP OF pr_activity.job_code 
			IF job_tot_print = 1 THEN 
				NEED 4 LINES 
				IF pr_underline_reqd = "Y" THEN 
					LET pr_underline_reqd = "N" 
					PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]
				END IF 
				PRINT 
				PRINT COLUMN 9, "JOB SUMMARY", 
				COLUMN 33, "=============", 
				COLUMN 48, "===============", 
				COLUMN 103, "=============", 
				COLUMN 120, "=============" 
				PRINT COLUMN 33, job_cost_amt USING "---------&.&&", 
				COLUMN 48, job_mtd_amt USING "-----------&.&&", 
				COLUMN 103, job_commit_amt USING "---------&.&&", 
				COLUMN 120, job_total USING "---------&.&&" 
				LET pr_cost_total = pr_cost_total + job_cost_amt 
				LET pr_mtd_total = pr_mtd_total + job_mtd_amt 
				LET pr_commit_total = pr_commit_total + job_commit_amt 
				LET pr_total = pr_total + job_total 
			END IF 
		AFTER GROUP OF pr_order_text 
			IF act_head_flag = 1 
			OR pr_print_all_trans = "Y" THEN 
				LET acti_cost_amt_tot = acti_cost_amt_tot + pr_open_bal 
				LET activity_total = acti_cost_amt_tot + total_commit_amt 
				NEED 3 LINES 
				IF pr_underline_reqd = "Y" THEN 
					LET pr_underline_reqd = "N" 
					PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]
				END IF 
				PRINT COLUMN 33, "-------------", 
				COLUMN 48, "---------------", 
				COLUMN 103, "-------------", 
				COLUMN 120, "-------------" 
				PRINT COLUMN 33, acti_cost_amt_tot USING "---------&.&&", 
				COLUMN 48, acti_cost_amt_tot2 USING "-----------&.&&", 
				COLUMN 103, total_commit_amt USING "---------&.&&", 
				COLUMN 120, activity_total USING "---------&.&&" 
				LET job_cost_amt = job_cost_amt + acti_cost_amt_tot 
				LET job_mtd_amt = job_mtd_amt + acti_cost_amt_tot2 
				LET job_commit_amt = job_commit_amt + total_commit_amt 
				LET job_total = job_total + activity_total 
			END IF 
			PAGE TRAILER 
				IF job_tot_print = 1 THEN 
					IF pr_print_trailer = "Y" THEN 
						#Add previous activity totals TO current activity
						LET activity_total = acti_cost_amt_tot 
						+ total_commit_amt 
						+ job_cost_amt 
						+ job_commit_amt 
						SKIP 1 line 
						PRINT COLUMN 9, " Subtotal ", 
						COLUMN 33, job_cost_amt + acti_cost_amt_tot 
						USING "---------&.&&", 
						COLUMN 48, job_mtd_amt + acti_cost_amt_tot2 
						USING "-----------&.&&", 
						COLUMN 103, job_commit_amt + total_commit_amt 
						USING "---------&.&&", 
						COLUMN 120, activity_total USING "---------&.&&" 
					ELSE 
						SKIP 2 LINES 
					END IF 
				ELSE 
					SKIP 2 LINES 
				END IF 
		ON LAST ROW 
			LET job_tot_print = false 
			SKIP TO top OF PAGE 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			PRINT COLUMN 01, "Date", 
			COLUMN 10, "Type", 
			COLUMN 19, "No.", 
			COLUMN 24, "Text", 
			COLUMN 35, "Cost Amount", 
			COLUMN 48, "MTD Cost Amount", 
			COLUMN 65, "Posted", 
			COLUMN 72, "Description", 
			COLUMN 105, "Commitments", 
			COLUMN 128, "Total" 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			SKIP 1 line 
			PRINT COLUMN 09, "REPORT TOTALS", 
			COLUMN 33, "=============", 
			COLUMN 48, "===============", 
			COLUMN 103, "=============", 
			COLUMN 120, "=============" 
			PRINT COLUMN 33, pr_cost_total USING "---------&.&&", 
			COLUMN 48, pr_mtd_total USING "-----------&.&&", 
			COLUMN 103, pr_commit_total USING "---------&.&&", 
			COLUMN 120, pr_total USING "---------&.&&" 
			SKIP 2 line 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	
			
END REPORT