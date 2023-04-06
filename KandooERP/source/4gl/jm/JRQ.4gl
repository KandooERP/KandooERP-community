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
# \brief module - JRM.4gl (JRQ !!!)
# Purpose - Actual TO target hours REPORT by Person AND Department
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl"
GLOBALS "../common/glob_GLOBALS_report.4gl" 
GLOBALS "../jm/J_JM_GLOBALS.4gl" 
GLOBALS "../jm/JR_GROUP_GLOBALS.4gl"  
GLOBALS "../jm/JRQ_GLOBALS.4gl"

#Module Scope Variables

MAIN 
	#Initial UI Init
	CALL setModuleId("JRQ") -- albo 
	CALL ui_init(0) 
	DEFER quit 
	DEFER interrupt 
	CALL authenticate(getmoduleid()) 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN "1" #UI/MENU Mode 	
			OPEN WINDOW J213 with FORM "J213" -- alch kd-747 
			CALL winDecoration_j("J213") -- alch kd-747
 
			MENU " Actual TO Target Hours" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","JRQ","menu-actual_to_target_hours-1") -- alch kd-506 
					CALL rpt_rmsreps_reset(NULL)	
					CALL JRQ_rpt_process(JRQ_rpt_query())

				ON ACTION "WEB-HELP" -- albo kd-373 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "Report" #COMMAND "Run" " Enter selection criteria AND generate REPORT" 
					CALL rpt_rmsreps_reset(NULL)	
					CALL JRQ_rpt_process(JRQ_rpt_query())
					
				ON ACTION "Print Manager" #COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
					
				ON ACTION "Cancel" #COMMAND KEY("E",interrupt)"Exit" " Exit TO menus" 
					EXIT MENU 
			END MENU 
			
			CLOSE WINDOW J213
	 
		WHEN "2" #Background Process with rmsreps.report_code
			CALL JRQ_rpt_process(NULL)  

		WHEN "3" #Only create query-where-part
			OPEN WINDOW J213 with FORM "J213" 
			CALL winDecoration_j("J213") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(JRQ_rpt_query()) #save where clause in env 
			CLOSE WINDOW J213 
			
		WHEN "4" #Background Process with SQL WHERE ARGUMENT
			CALL JRQ_rpt_process(get_url_sel_text())
	END CASE
END MAIN 


FUNCTION JRQ_rpt_query()
	DEFINE l_where_text STRING
	
	LET msgresp = kandoomsg("U",1001,"") #1001 Enter Selection Criteria; OK TO Continue
	CONSTRUCT BY NAME l_where_text on person.person_code, person.dept_code
		BEFORE CONSTRUCT
			CALL publish_toolbar("kandoo","JRQ","const-rmsreps_sel_text-1") -- alch kd-506 
	END CONSTRUCT

	IF int_flag OR quit_flag THEN
		LET int_flag = FALSE
		LET quit_flag = FALSE
		RETURN NULL
	ELSE
		RETURN l_where_text		
	END IF

END FUNCTION


FUNCTION JRQ_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
   DEFINE
      pr_ts_head RECORD LIKE ts_head.*,
      pr_ts_detail RECORD LIKE ts_detail.*,
      pr_person RECORD LIKE person.*,
      pr_department RECORD LIKE department.*,
      query_text CHAR(2500)

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"JRQ_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT JRQ_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("JRQ_rpt_list")].sel_text
	#------------------------------------------------------------

   LET query_text = "SELECT department.*, ts_head.*, ts_detail.*, person.* ",
                    "  FROM department, ts_head, ts_detail, person ",
                    " WHERE department.cmpy_code = '",glob_rec_kandoouser.cmpy_code ,"' ",
                    "   AND department.cmpy_code = ts_head.cmpy_code ",
                    "   AND ts_head.cmpy_code = ts_detail.cmpy_code ",
                    "   AND ts_detail.cmpy_code = person.cmpy_code ",
                    "   AND person.person_code = ts_head.person_code ",
                    "   AND department.dept_code = person.dept_code ",
                    "   AND ts_detail.ts_num = ts_head.ts_num ",
                    "   AND ",p_where_text clipped," ",
                    " ORDER BY department.dept_code, ts_head.per_end_date, ",
                    "          person.person_code, ts_detail.task_date"
   PREPARE s_department FROM query_text
   DECLARE c_department CURSOR FOR s_department
   FOREACH c_department INTO pr_department.*,
                             pr_ts_head.*,
                             pr_ts_detail.*,
                             pr_person.*
		#---------------------------------------------------------
		OUTPUT TO REPORT JRQ_rpt_list(l_rpt_idx,
		pr_department.*,
                                pr_ts_head.*,
                                pr_ts_detail.*,
                                pr_person.*) 
		IF NOT rpt_int_flag_handler2("Department:",pr_department.dept_code, pr_department.dept_text,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------	                             
   END FOREACH

	#------------------------------------------------------------
	FINISH REPORT JRQ_rpt_list
	CALL rpt_finish("JRQ_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION     


REPORT JRQ_rpt_list(p_rpt_idx,pr_department, pr_ts_head, pr_ts_detail, pr_person)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
   DEFINE
      pr_department RECORD LIKE department.*,
      pr_ts_head RECORD LIKE ts_head.*,
      pr_ts_detail RECORD LIKE ts_detail.*,
      pr_person RECORD LIKE person.*,
      pr_title_text LIKE activity.title_text,
      pr_unit_code LIKE jmresource.unit_code,
      pr_task_period_text CHAR(15),
      pa_line array[4] of CHAR(132)

   OUTPUT
      left margin 1
      ORDER external by pr_department.dept_code,
                        pr_ts_head.per_end_date,
                        pr_person.person_code,
                        pr_ts_detail.task_date
   FORMAT
   PAGE HEADER
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  
      
   BEFORE GROUP OF pr_department.dept_code
      skip 1 lines
      PRINT COLUMN 001, pr_department.dept_text clipped," (",
                        pr_department.dept_code clipped, ")"
      skip 1 line
   BEFORE GROUP OF pr_ts_head.per_end_date
      PRINT COLUMN 003, pr_ts_head.per_end_date using "dd/mm/yyyy";
      
   BEFORE GROUP OF pr_person.person_code
      PRINT COLUMN 015, pr_person.person_code,
            COLUMN 025, pr_person.name_text
            
   ON EVERY ROW
      SELECT title_text INTO pr_title_text FROM activity
       WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
         AND job_code = pr_ts_detail.job_code
         AND var_code = pr_ts_detail.var_code
         AND activity_code = pr_ts_detail.activity_code
      SELECT unit_code INTO pr_unit_code FROM jmresource
       WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
         AND res_code = pr_ts_detail.res_code
      PRINT COLUMN 020, pr_ts_detail.task_date using "dd/mm/yyyy",
            COLUMN 045, pr_ts_detail.job_code,
            COLUMN 060, pr_ts_detail.var_code using "##&",
            COLUMN 065, pr_ts_detail.activity_code,
            COLUMN 080, pr_ts_detail.dur_qty using "---&.&&&&",
            COLUMN 093, pr_title_text
      IF pr_ts_detail.comment_text IS NOT NULL THEN
         PRINT COLUMN 93, pr_ts_detail.comment_text
      END IF
      
   AFTER GROUP OF pr_person.person_code
      PRINT COLUMN 080, "---------"
      PRINT COLUMN 032, "Person Total ", pr_person.name_text clipped, " (",
                                         pr_person.person_code clipped, ")",
            COLUMN 080, group sum(pr_ts_detail.dur_qty) using "---&.&&&&"
      skip 1 line
      
   AFTER GROUP OF pr_ts_head.per_end_date
      PRINT COLUMN 080, "---------"
      PRINT COLUMN 032, "Period Total ",
            COLUMN 080, group sum(pr_ts_detail.dur_qty) using "---&.&&&&"
      skip 1 line
      
   AFTER GROUP OF pr_department.dept_code
      PRINT COLUMN 078, "-----------"
      PRINT COLUMN 032, "Department Total ",
                        pr_department.dept_text clipped," (",
                        pr_department.dept_code clipped, ")",
            COLUMN 078, group sum(pr_ts_detail.dur_qty) using "-----&.&&&&"
      PRINT COLUMN 078, "==========="
      skip 1 line
      
   ON LAST ROW
      skip 1 line
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	
			      
END REPORT