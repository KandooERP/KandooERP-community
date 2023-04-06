##########################################################################
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
# Purpose - Charegable Hours Report
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl"
GLOBALS "../common/glob_GLOBALS_report.4gl" 
GLOBALS "../jm/J_JM_GLOBALS.4gl" 
GLOBALS "../jm/JR_GROUP_GLOBALS.4gl"  
GLOBALS "../jm/JRS_GLOBALS.4gl"

#Module Scope Variables
DEFINE 

pr_ts_head RECORD LIKE ts_head.*, 
pr_ts_detail RECORD LIKE ts_detail.*, 
pr_person RECORD LIKE person.*, 
pr_job RECORD LIKE job.*, 
prh_period RECORD LIKE period.*, 
pr_period RECORD LIKE period.*, 
gv_current_person LIKE person.person_code, 
gv_pre_sales_hours LIKE ts_detail.dur_qty, 
gv_leave_hours LIKE ts_detail.dur_qty, 
gv_training_hours LIKE ts_detail.dur_qty, 
gv_waiting_hours LIKE ts_detail.dur_qty, 
gv_admin_hours LIKE ts_detail.dur_qty, 
gv_charge_hours LIKE ts_detail.dur_qty, 
gv_total_hours LIKE ts_detail.dur_qty 

MAIN 
	#  SET explain on
	#Initial UI Init
	CALL setModuleId("JRS") -- albo 
	CALL ui_init(0) 
	
	DEFER quit 
	DEFER interrupt
	 
	CALL authenticate(getmoduleid()) 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN "1" #UI/MENU Mode 	
			OPEN WINDOW J215 with FORM "J215" -- alch kd-747 
			CALL winDecoration_j("J215") -- alch kd-747
			CALL rpt_rmsreps_reset(NULL) 
			CALL JRS_rpt_process(JRS_rpt_query())
					
			MENU " Chargeable Hours" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","JRS","menu-chargeable_hours-1") -- alch kd-506
 
				ON ACTION "WEB-HELP" -- albo kd-373 
					CALL onlinehelp(getmoduleid(),null)
					 
				ON ACTION "REPORT" --COMMAND "Report" " SELECT Criteria AND PRINT REPORT" 
					CALL rpt_rmsreps_reset(NULL) 
					CALL JRS_rpt_process(JRS_rpt_query())
					
				ON ACTION "Print Manager"		#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "Cancel" #COMMAND KEY(interrupt, "E")"Exit" " Exit TO menus" 
					EXIT MENU 
 
			END MENU 
			CLOSE WINDOW J215
			 
	 
		WHEN "2" #Background Process with rmsreps.report_code
			CALL JRS_rpt_process(NULL)  

		WHEN "3" #Only create query-where-part
			OPEN WINDOW J215 with FORM "J215" 
			CALL winDecoration_j("J215") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(JRS_rpt_query()) #save where clause in env 
			CLOSE WINDOW J215 
			
		WHEN "4" #Background Process with SQL WHERE ARGUMENT
			CALL JRS_rpt_process(get_url_sel_text())
	END CASE 	
END MAIN 


FUNCTION JRS_rpt_query()
	DEFINE l_where_text STRING
	DEFINE l_msgresp LIKE language.yes_flag
 
	LET l_msgresp = kandoomsg("U",1001,"") #1001 Enter Selection Criteria;  OK TO Continue"

	SELECT max(per_end_date) 
	INTO pr_period.end_date 
	FROM ts_head 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 

	CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, pr_period.end_date) 
	RETURNING pr_period.year_num, pr_period.period_num 

	CONSTRUCT BY NAME l_where_text ON 
	ts_head.person_code, 
	person.dept_code, 
	ts_head.year_num, 
	ts_head.period_num 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","JRS","const-person_code-6") -- alch kd-506
 
		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 
	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		MESSAGE "Report Generation aborted"
		RETURN NULL
	ELSE
		RETURN l_where_text
	END IF 
END FUNCTION 


FUNCTION JRS_rpt_process(p_where_text) 
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

	LET l_rpt_idx = rpt_start(getmoduleid(),"JRS_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT JRS_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("JRS_rpt_list")].sel_text
	#------------------------------------------------------------

	LET l_query_text = " SELECT ts_head.*, person.*, ts_detail.*, job.*", 
	" FROM ts_head, person, ts_detail, job", 
	" WHERE ts_head.cmpy_code = '",glob_rec_kandoouser.cmpy_code ,"' ", 
	" AND person.cmpy_code = ts_head.cmpy_code", 
	" AND person.person_code = ts_head.person_code", 
	" AND ts_detail.cmpy_code = ts_head.cmpy_code", 
	" AND ts_detail.ts_num = ts_head.ts_num", 
	" AND job.cmpy_code = ts_head.cmpy_code", 
	" AND job.job_code = ts_detail.job_code", 
	" AND ",p_where_text clipped," ", 
	" ORDER BY dept_code, person.person_code" 

	PREPARE s_person FROM l_query_text 
	DECLARE c_person CURSOR FOR s_person 

	FOREACH c_person INTO pr_ts_head.*, pr_person.*, pr_ts_detail.*, pr_job.* 

		#---------------------------------------------------------
		OUTPUT TO REPORT JRS_rpt_list(l_rpt_idx,
		pr_ts_head.*, 
		pr_ts_detail.*, 
		pr_person.*)  
		IF NOT rpt_int_flag_handler2("Person:",pr_person.person_code, pr_person.name_text,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------	

		CASE 

			WHEN pr_job.type_code = "PS" 
				LET gv_pre_sales_hours = gv_pre_sales_hours 
				+ pr_ts_detail.dur_qty 

			WHEN pr_ts_detail.activity_code = "HOL1" 
				OR pr_ts_detail.activity_code = "HOL2" 
				OR pr_ts_detail.activity_code = "SICK" 
				LET gv_leave_hours = gv_leave_hours + pr_ts_detail.dur_qty 

			WHEN pr_ts_detail.activity_code = "TRAIN" 
				LET gv_training_hours = gv_training_hours + pr_ts_detail.dur_qty 

			WHEN pr_ts_detail.activity_code = "WAIT" 
				LET gv_waiting_hours = gv_waiting_hours + pr_ts_detail.dur_qty 

			WHEN pr_job.cust_code = "10583" 
				LET gv_admin_hours = gv_admin_hours + pr_ts_detail.dur_qty 

			OTHERWISE 
				LET gv_charge_hours = gv_charge_hours + pr_ts_detail.dur_qty 
		END CASE 

		LET gv_total_hours = gv_total_hours + pr_ts_detail.dur_qty 

	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT JRS_rpt_list
	CALL rpt_finish("JRS_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 

REPORT JRS_rpt_list(p_rpt_idx,pr_ts_head, pr_ts_detail, pr_person)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx] 
	DEFINE 
	pr_ts_head RECORD LIKE ts_head.*, 
	pr_ts_detail RECORD LIKE ts_detail.*, 
	pr_person RECORD LIKE person.*, 
	pr_department RECORD LIKE department.*, 
	pr_unit_code LIKE jmresource.unit_code, 
	pr_task_period_text CHAR(15) 

	OUTPUT 

	ORDER external BY pr_person.dept_code,pr_person.person_code 
	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  
			PRINT "Department, Person, Total Hours, Chargeable,", 
			"Pre-Sales, Leave, Training, Waiting FOR Work, Admin" 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  

		BEFORE GROUP OF pr_person.dept_code 
			SELECT * INTO pr_department.* FROM department 
			WHERE department.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND department.dept_code = pr_person.dept_code 
			NEED 10 LINES 
			SKIP 1 LINES 

		AFTER GROUP OF pr_person.person_code 
			PRINT pr_department.dept_text clipped, "(", 
			pr_person.dept_code clipped, "),", 
			pr_person.name_text clipped, "(", 
			pr_person.person_code clipped, "),", 
			gv_total_hours USING "<<<&.&&&&", ",", 
			gv_charge_hours USING "<<<&.&&&&", ",", 
			gv_pre_sales_hours USING "<<<&.&&&&", ",", 
			gv_leave_hours USING "<<<&.&&&&", ",", 
			gv_training_hours USING "<<<&.&&&&", ",", 
			gv_waiting_hours USING "<<<&.&&&&", ",", 
			gv_admin_hours USING "<<<&.&&&&" 
			LET gv_pre_sales_hours = 0 
			LET gv_leave_hours = 0 
			LET gv_training_hours = 0 
			LET gv_waiting_hours = 0 
			LET gv_admin_hours = 0 
			LET gv_charge_hours = 0 
			LET gv_total_hours = 0 


		ON LAST ROW 
			SKIP 1 line 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	
			
END REPORT 