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
# Purpose - Missing/Incomplete Timesheets by Person
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl"
GLOBALS "../common/glob_GLOBALS_report.4gl" 
GLOBALS "../jm/J_JM_GLOBALS.4gl" 
GLOBALS "../jm/JR_GROUP_GLOBALS.4gl"  
GLOBALS "../jm/JRR_GLOBALS.4gl"

#Module Scope Variables
DEFINE 
pr_ts_head RECORD LIKE ts_head.*, 
pr_ts_detail RECORD LIKE ts_detail.*, 
pr_person RECORD LIKE person.*, 
prh_period RECORD LIKE period.*, 
pr_period RECORD LIKE period.*, 
gv_hours_worked SMALLFLOAT, 
gv_per_end_date DATE, 
gv_problem_text CHAR(20) 

MAIN 
	## SET explain on
	#Initial UI Init
	CALL setModuleId("JRR") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN "1" #UI/MENU Mode
			OPEN WINDOW J214 with FORM "J214" -- alch kd-747 
			CALL winDecoration_j("J214") -- alch kd-747
 
			MENU " Missing/Incomplete Timesheets by Person" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","JRR","menu-missing_incomplete_timesheets-1") -- alch kd-506 
					CALL rpt_rmsreps_reset(NULL) 
					CALL JRR_rpt_process(JRR_rpt_query())

				ON ACTION "WEB-HELP" -- albo kd-373 
					CALL onlinehelp(getmoduleid(),null) 

				COMMAND "Report" " SELECT Criteria AND PRINT REPORT" 
					CALL rpt_rmsreps_reset(NULL) 
					CALL JRR_rpt_process(JRR_rpt_query())

				ON ACTION "Print Manager"		#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
					NEXT option "Exit" 

				ON ACTION "Cancel" #COMMAND KEY(interrupt, "E")"Exit" " Exit TO menus" 
					EXIT MENU 

			END MENU 
			CLOSE WINDOW J214 
			
		WHEN "2" #Background Process with rmsreps.report_code
			CALL JRR_rpt_process(NULL)  

		WHEN "3" #Only create query-where-part
			OPEN WINDOW J214 with FORM "J214" 
			CALL winDecoration_j("J214") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(JRR_rpt_query()) #save where clause in env 
			CLOSE WINDOW J214 
			
		WHEN "4" #Background Process with SQL WHERE ARGUMENT
			CALL JRR_rpt_process(get_url_sel_text())
	END CASE 	
	 
END MAIN 


FUNCTION JRR_rpt_query() 
	DEFINE l_msgresp LIKE language.yes_flag

	LET l_msgresp = kandoomsg("U",1001,"") #1001 Enter Selection Criteria;  OK TO Continue"

	SELECT max(per_end_date) 
	INTO pr_period.end_date 
	FROM ts_head 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 

	CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, pr_period.end_date) 
	RETURNING pr_period.year_num, pr_period.period_num 

	INPUT BY NAME pr_period.end_date, pr_period.year_num, pr_period.period_num 
	WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","JRR","input-pr_period-1") -- alch kd-506 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL
	ELSE
		LET glob_rec_rpt_selector.ref1_date = pr_period.end_date
		LET glob_rec_rpt_selector.ref1_num = pr_period.year_num
		LET glob_rec_rpt_selector.ref2_num = pr_period.period_num
		RETURN "N/A"
	END IF 
END FUNCTION 


FUNCTION JRR_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx] 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false
		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"JRR_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT JRR_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("JRR_rpt_list")].sel_text
	#------------------------------------------------------------
	LET pr_period.end_date = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref1_date 
	LET pr_period.year_num = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref1_num
	LET pr_period.period_num = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref2_num
	#------------------------------------------------------------
		
	DECLARE c_person CURSOR FOR 
	SELECT * 
	FROM person 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND active_flag = "Y" 
	ORDER BY dept_code, person_code 

	FOREACH c_person INTO pr_person.* 

		LET gv_hours_worked = 0 
		LET pr_ts_head.ts_num = 0 

		SELECT ts_num 
		INTO pr_ts_head.ts_num 
		FROM ts_head 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND person_code = pr_person.person_code 
		AND per_end_date = pr_period.end_date 

		IF status = notfound THEN 
			LET gv_problem_text = "Timesheet Missing"
			#---------------------------------------------------------
			OUTPUT TO REPORT JRR_rpt_list(l_rpt_idx,
			pr_ts_head.*, 
			pr_ts_detail.*, 
			pr_person.*, 
			"M", 
			0)
			IF NOT rpt_int_flag_handler2("Person:",pr_person.person_code, pr_person.name_text,l_rpt_idx) THEN
				EXIT FOREACH 
			END IF 			 
			#---------------------------------------------------------				

		ELSE 

			DECLARE c_ts_detail CURSOR FOR 
			SELECT * 
			FROM ts_detail 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND ts_num = pr_ts_head.ts_num 

			LET gv_hours_worked = 0 

			FOREACH c_ts_detail INTO pr_ts_detail.* 

				LET gv_hours_worked = gv_hours_worked + pr_ts_detail.dur_qty 

			END FOREACH 

			IF gv_hours_worked < 
			(pr_person.maxdur_qty * pr_person.work_days_qty) THEN 
				LET gv_problem_text = "Timesheet Incomplete" 
				#---------------------------------------------------------
				OUTPUT TO REPORT JRR_rpt_list(l_rpt_idx,
				pr_ts_head.*, 
				pr_ts_detail.*, 
				pr_person.*, 
				"I", 
				gv_hours_worked) 
				IF NOT rpt_int_flag_handler2("Person:",pr_person.person_code, pr_person.name_text,l_rpt_idx) THEN
					EXIT FOREACH 
				END IF 			 
				#---------------------------------------------------------		

				DECLARE c_ts_detail_2 CURSOR FOR 
				SELECT * 
				FROM ts_detail 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND ts_num = pr_ts_head.ts_num 

				FOREACH c_ts_detail_2 INTO pr_ts_detail.* 
					#---------------------------------------------------------
					OUTPUT TO REPORT JRR_rpt_list(l_rpt_idx,
					pr_ts_head.*, 
					pr_ts_detail.*, 
					pr_person.*, 
					"D", 
					gv_hours_worked ) 
					IF NOT rpt_int_flag_handler2("Person:",pr_person.person_code, pr_person.name_text,l_rpt_idx) THEN
						EXIT FOREACH 
					END IF 			 
					#---------------------------------------------------------	

				END FOREACH 

			END IF 
		END IF 

	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT JRR_rpt_list
	CALL rpt_finish("JRR_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 


REPORT JRR_rpt_list(p_rpt_idx,pr_ts_head, pr_ts_detail, pr_person,gv_problem, gv_hours_worked)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx] 
	DEFINE 
	pr_ts_head RECORD LIKE ts_head.*, 
	pr_ts_detail RECORD LIKE ts_detail.*, 
	pr_person RECORD LIKE person.*, 
	pr_department RECORD LIKE department.*, 
	pr_unit_code LIKE jmresource.unit_code, 
	pr_task_period_text CHAR(15), 
	pa_line array[4] OF CHAR(132), 
	gv_problem CHAR(1), 
	gv_hours_worked SMALLFLOAT 

	OUTPUT 
	ORDER external BY pr_person.dept_code, pr_person.person_code 
	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  

		BEFORE GROUP OF pr_person.dept_code 
			SELECT * INTO pr_department.* FROM department 
			WHERE department.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND department.dept_code = pr_person.dept_code 
			NEED 10 LINES 
			SKIP 1 LINES 
			PRINT COLUMN 002, pr_department.dept_text clipped, " (", 
			pr_department.dept_code clipped, ")" 
			SKIP 1 line 

		ON EVERY ROW 
			CASE 
				WHEN gv_problem = "D" 
					PRINT COLUMN 100, pr_ts_detail.task_date USING "ddd dd mmm yyyy", 
					COLUMN 120, pr_ts_detail.dur_qty USING "---&.&& " 
				WHEN gv_problem = "T" 
					PRINT COLUMN 120, "=========" 
					PRINT COLUMN 100, "Timesheet Total", 
					COLUMN 120, gv_hours_worked USING "---&.&& " 
					PRINT COLUMN 120, "=========" 
				OTHERWISE 
					PRINT COLUMN 040, pr_person.name_text clipped," (", 
					pr_person.person_code clipped, ")", 
					COLUMN 070, gv_problem_text, 
					COLUMN 085, pr_ts_head.ts_num USING "--------" 
			END CASE 

		ON LAST ROW 
			SKIP 1 line 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	
			
END REPORT 