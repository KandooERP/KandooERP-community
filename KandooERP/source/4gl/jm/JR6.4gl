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
GLOBALS "../jm/JR6_GLOBALS.4gl"

#Module Scope Variables
DEFINE pr_run_csv_flag CHAR(1) 
# Purpose - Timesheets by Person
MAIN 
	#Initial UI Init
	CALL setModuleId("JR6") -- albo 
	CALL ui_init(0) 
	DEFER quit 
	DEFER interrupt 
	CALL authenticate(getmoduleid()) 
	LET pr_run_csv_flag = NULL
	 
	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN "1" #UI/MENU Mode 	
			OPEN WINDOW J176 with FORM "J176" -- alch kd-747 
			CALL winDecoration_j("J176") -- alch kd-747 

			MENU " Timesheets by Person" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","JR6","menu-timesheets_b_person-1") -- alch kd-506 

				ON ACTION "WEB-HELP" -- albo kd-373 
					CALL onlinehelp(getmoduleid(),null) 

				COMMAND "Report" " SELECT Criteria AND PRINT REPORT" 
					LET pr_run_csv_flag = "N"
					CALL rpt_rmsreps_reset(NULL)
					CALL JR6_rpt_process(JR6_rpt_query())

				COMMAND "Run CSV" " Enter selection criteria AND generate CSV REPORT" 
					LET pr_run_csv_flag = "Y"
					CALL rpt_rmsreps_reset(NULL) 
					CALL JR6_rpt_process(JR6_rpt_query()) 
 
				ON ACTION "Print Manager"					#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "CANCEL" --COMMAND KEY(interrupt, "E")"Exit" " Exit TO menus" 
					EXIT MENU 

			END MENU 
			CLOSE WINDOW J176 

	 
		WHEN "2" #Background Process with rmsreps.report_code
			CALL JR6_rpt_process(NULL)  

		WHEN "3" #Only create query-where-part
			OPEN WINDOW J176 with FORM "J176" 
			CALL winDecoration_j("J176") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(JR6_rpt_query()) #save where clause in env 
			CLOSE WINDOW J176 
			
		WHEN "4" #Background Process with SQL WHERE ARGUMENT
			CALL JR6_rpt_process(get_url_sel_text())
	END CASE 	
END MAIN 


FUNCTION JR6_rpt_query()
	DEFINE l_where_text STRING 
	DEFINE l_msgresp LIKE language.yes_flag
 
	LET l_msgresp = kandoomsg("U",1001,"") 	#1001 Enter Selection Criteria;  OK TO Continue"

	CONSTRUCT BY NAME l_where_text ON 
	ts_head.ts_num, 
	ts_head.per_end_date, 
	ts_head.person_code, 
	person.name_text, 
	person.task_period_ind, 
	person.dept_code, 
	ts_detail.job_code, 
	ts_detail.var_code, 
	ts_detail.activity_code, 
	ts_detail.res_code
	 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","JR6","const-ts_num-1") -- alch kd-506
 
		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 
			
	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL
	ELSE
		RETURN l_where_text 
	END IF 
END FUNCTION 


FUNCTION JR6_rpt_process(p_where_text)
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx] 
	DEFINE p_where_text STRING
	DEFINE 
	pr_ts_head RECORD LIKE ts_head.*, 
	pr_ts_detail RECORD LIKE ts_detail.*, 
	pr_person RECORD LIKE person.*, 
	pr_job RECORD LIKE job.*, 
	query_text CHAR(2000) 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"JR6_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT JR6_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("JR6_rpt_list")].sel_text
	#------------------------------------------------------------


	#Add job table in selection criteria in ORDER TO get the customer name text
	LET query_text = "SELECT ts_head.*, person.*, ts_detail.*, job.* ", 
	" FROM ts_head, person, ts_detail, job ", 
	" WHERE ts_head.cmpy_code = '",glob_rec_kandoouser.cmpy_code ,"' ", 
	" AND person.cmpy_code = ts_head.cmpy_code ", 
	" AND person.person_code = ts_head.person_code ", 
	" AND ts_detail.cmpy_code = ts_head.cmpy_code ", 
	" AND ts_detail.ts_num = ts_head.ts_num ", 
	" AND job.job_code = ts_detail.job_code ", 
	" AND job.cmpy_code = '", glob_rec_kandoouser.cmpy_code,"' ", 
	" AND ",p_where_text clipped," ", 
	" ORDER BY ts_head.person_code, ", 
	" ts_head.ts_num, ", 
	" ts_head.per_end_date, ", 
	" ts_detail.task_date" 
	PREPARE s_person FROM query_text 
	DECLARE c_person CURSOR FOR s_person 
	FOREACH c_person INTO pr_ts_head.*, pr_person.*, pr_ts_detail.*, pr_job.*
		#---------------------------------------------------------
		OUTPUT TO REPORT JR6_rpt_list(l_rpt_idx,
		pr_ts_head.*, 
		pr_ts_detail.*, 
		pr_person.*, 
		pr_job.*) 
		IF NOT rpt_int_flag_handler2("Person:",pr_person.person_code, pr_person.name_text,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------	

	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT JR6_rpt_list
	CALL rpt_finish("JR6_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF  
END FUNCTION 


REPORT JR6_rpt_list(pr_ts_head, pr_ts_detail, pr_person, pr_job) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE 
	pr_ts_head RECORD LIKE ts_head.*, 
	pr_ts_detail RECORD LIKE ts_detail.*, 
	pr_person RECORD LIKE person.*, 
	pr_job RECORD LIKE job.*, 
	pr_department RECORD LIKE department.*, 
	pr_title_text LIKE activity.title_text, 
	pr_name_text LIKE customer.name_text, 
	pr_unit_code LIKE jmresource.unit_code, 
	pr_task_period_text CHAR(15), 
	pa_line array[4] OF CHAR(132) 

	OUTPUT 
	left margin 1 
	ORDER external BY pr_ts_head.person_code, 
	pr_ts_head.ts_num, 
	pr_ts_head.per_end_date, 
	pr_ts_detail.task_date 
	
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1

			IF pr_run_csv_flag = "N" THEN 
				PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
				PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
				PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  
				PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
				PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text 
				PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  
			ELSE 
				PRINT "Time Sheet Code, Person, Posted, Task Date,Department,Job Code,Client,"; 
				PRINT "Variation Code,Activity Code,Resource,Quantity,Uint,Charge Out Rate,"; 
				PRINT "Task Period,Activity Title & Comment,Period Ending" 
				PRINT PRINT PRINT PRINT PRINT 
			END IF 
			
		BEFORE GROUP OF pr_ts_head.ts_num 
			IF pr_run_csv_flag = "N" THEN 
				SELECT * INTO pr_department.* FROM department 
				WHERE department.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND department.dept_code = pr_person.dept_code 
				SELECT task_period_text INTO pr_task_period_text FROM taskperiod 
				WHERE taskperiod.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND taskperiod.task_period_ind = pr_person.task_period_ind 
				IF status = notfound THEN 
					LET pr_task_period_text = "(", pr_person.task_period_ind, ")" 
				ELSE 
					LET pr_task_period_text[12]=" " 
					LET pr_task_period_text[13]="(" 
					LET pr_task_period_text[14]=pr_person.task_period_ind 
					LET pr_task_period_text[15]=")" 
				END IF 
				NEED 10 LINES 
				SKIP 1 LINES 
				PRINT COLUMN 002, pr_ts_head.ts_num USING "<<<<<<<", 
				COLUMN 009, pr_person.name_text clipped," (", 
				pr_ts_head.person_code clipped, ")", 
				COLUMN 040, pr_department.dept_text clipped, " (", 
				pr_department.dept_code clipped, ")", 
				COLUMN 080, pr_task_period_text clipped, 
				COLUMN 100, pr_ts_head.per_end_date USING "ddd dd mmm yyyy" 
				SKIP 1 line 
			ELSE 
				SKIP 2 LINES 
			END IF 
		ON EVERY ROW 
			SELECT title_text INTO pr_title_text FROM activity 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND job_code = pr_ts_detail.job_code 
			AND var_code = pr_ts_detail.var_code 
			AND activity_code = pr_ts_detail.activity_code 
			SELECT unit_code INTO pr_unit_code FROM jmresource 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND res_code = pr_ts_detail.res_code 
			SELECT name_text INTO pr_name_text FROM customer 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cust_code = pr_job.cust_code 
			IF pr_run_csv_flag = "N" THEN 








				PRINT COLUMN 009, pr_ts_detail.post_flag,#17 
				COLUMN 013, pr_ts_detail.task_date USING "ddd dd mmm yyyy",#26 
				COLUMN 030, pr_ts_detail.job_code clipped, #43 
				COLUMN 038, pr_name_text[1,20],#56 
				COLUMN 059, pr_ts_detail.var_code USING "##&<<",#77 
				COLUMN 063 ,pr_ts_detail.activity_code,#82 
				COLUMN 072, pr_ts_detail.res_code,#94 
				COLUMN 084, pr_ts_detail.dur_qty USING "<<<&.&&",#104 
				COLUMN 092, pr_unit_code clipped, 
				COLUMN 096, pr_ts_detail.unit_bill_amt USING "-,---,--$.&&" clipped, 
				COLUMN 117, pr_title_text 






				IF pr_ts_detail.comment_text IS NOT NULL THEN 
					PRINT COLUMN 117, pr_ts_detail.comment_text 
				END IF 

			ELSE 
				PRINT pr_ts_head.ts_num USING "<<<<<", ",", 
				pr_person.name_text clipped, ",", 
				pr_ts_head.person_code clipped, ",", 
				pr_ts_detail.post_flag, ",", 
				pr_ts_detail.task_date USING "dd/mm/yyyy", ",", 
				pr_department.dept_text clipped, ",", 
				pr_department.dept_code clipped, ",", 
				pr_ts_detail.job_code clipped, ",", 
				pr_name_text clipped, ",", 
				pr_ts_detail.var_code USING "<<&", ",", 
				pr_ts_detail.activity_code clipped, ",", 
				pr_ts_detail.res_code clipped, ",", 
				pr_ts_detail.dur_qty USING "<<<&.&&", ",", 
				pr_unit_code clipped, ",", 
				pr_ts_detail.unit_bill_amt USING "<,<<<,<<$.&&" clipped, ",", 
				pr_task_period_text clipped, ",", 
				pr_title_text clipped; 
				IF pr_ts_detail.comment_text IS NOT NULL THEN 
					PRINT " -- ", pr_ts_detail.comment_text clipped; 
				END IF 
				PRINT ",", 
				pr_ts_head.per_end_date USING "dd/mm/yyyy", "," 
			END IF 

		AFTER GROUP OF pr_ts_head.ts_num 
			IF pr_run_csv_flag = "N" THEN 
				PRINT COLUMN 83, "-------", COLUMN 99, "-----------" 
				PRINT COLUMN 65, "Timesheet Total", 
				COLUMN 83, GROUP sum(pr_ts_detail.dur_qty) 
				USING "---&.&& ", 
				COLUMN 96, GROUP sum(pr_ts_detail.unit_bill_amt) 
				USING "-,---,--$.&&" 
				PRINT COLUMN 83, "=======", COLUMN 99, "===========" 
			ELSE 
			END IF 
			
		ON LAST ROW 
			IF pr_run_csv_flag = "N" THEN 
				SKIP 1 line 
				#End Of Report
				IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
					PRINT COLUMN 01,"Selection Criteria:" 
					PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
				END IF 
				PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	
			
			ELSE 
				SKIP 2 line 
			END IF 
END REPORT 