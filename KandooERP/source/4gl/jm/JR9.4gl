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
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "J_JM_GLOBALS.4gl" 

# Purpose - Resource Allocations Report

GLOBALS 
	DEFINE pr_jmresource RECORD LIKE jmresource.*, 
	pr_jobledger RECORD LIKE jobledger.*, 
	pr_job RECORD LIKE job.*, 
	pr_company RECORD LIKE company.*, 
	pr_rec_kandoouser RECORD LIKE kandoouser.*, 
	rpt_pageno LIKE rmsreps.page_num, 
	rpt_wid LIKE rmsreps.report_width_num, 
	rpt_length LIKE rmsreps.page_length_num, 
	rpt_note LIKE rmsreps.report_text, 
	rpt_date DATE, 
--	where_part, query_text CHAR(3400), 
	rpt_time CHAR(10), 
	line1, line2 CHAR(80), 
	offset1, offset2 SMALLINT, 
	pr_output CHAR(60), 
	prg_name CHAR(7) 
END GLOBALS 

MAIN 
	#Initial UI Init
	CALL setModuleId("JR9") -- albo 
	CALL ui_init(0) 
	DEFER quit 
	DEFER interrupt 
	CALL authenticate(getmoduleid()) 

	SELECT * 
	INTO pr_company.* 
	FROM company 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 

	CLEAR screen 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN "1" #UI/MENU Mode 	
	
			OPEN WINDOW J188 with FORM "J188" -- alch kd-747 
			CALL winDecoration_j("J188") -- alch kd-747 
			 
			MENU " Resource Allocations" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","JR9","menu-resource_alloc-1") -- alch kd-506 
					CALL rpt_rmsreps_reset(NULL) 
					CALL JR9_rpt_process(JR9_rpt_query())

				ON ACTION "WEB-HELP" -- albo kd-373 
					CALL onlinehelp(getmoduleid(),null) 

				COMMAND "Report" " SELECT criteria AND PRINT REPORT" 
					CALL rpt_rmsreps_reset(NULL) 
					CALL JR9_rpt_process(JR9_rpt_query())

				ON ACTION "Print Manager" 				#COMMAND "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "CANCEL" --COMMAND "Exit" " Exit TO menus" 
					EXIT MENU 

			END MENU 

			CLOSE WINDOW J188 
			CLEAR screen
			
	 
		WHEN "2" #Background Process with rmsreps.report_code
			CALL JR9_rpt_process(NULL)  

		WHEN "3" #Only create query-where-part
			OPEN WINDOW J188 with FORM "J188" 
			CALL winDecoration_j("J188") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(JR9_rpt_query()) #save where clause in env 
			CLOSE WINDOW J188 
			
		WHEN "4" #Background Process with SQL WHERE ARGUMENT
			CALL JR9_rpt_process(get_url_sel_text())
	END CASE			 
END MAIN 


FUNCTION JR9_rpt_query() 
	DEFINE l_where_text STRING
	
	LET msgresp=kandoomsg("U",1001,"")#1001 " Enter criteria FOR selection - ESC TO begin search"
	CONSTRUCT BY NAME l_where_text ON 
	jobledger.job_code, 
	jobledger.var_code, 
	jobledger.activity_code, 
	jobledger.year_num, 
	jobledger.period_num, 
	jobledger.trans_date, 
	jobledger.trans_source_num, 
	jobledger.trans_source_text, 
	jobledger.trans_amt 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","JR9","const-job_code-6") -- alch kd-506 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 
	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		LET msgresp = kandoomsg("U",9501,"")#ERROR "Printing was aborted"
		RETURN NULL
	ELSE
		RETURN l_where_text 
	END IF 
END FUNCTION

FUNCTION JR9_rpt_process(p_where_text) 
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

	LET l_rpt_idx = rpt_start(getmoduleid(),"JR9_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT JR9_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("JR9_rpt_list")].sel_text
	#------------------------------------------------------------


	LET l_query_text = "SELECT jobledger.* FROM jobledger,activity ", 
	"WHERE jobledger.cmpy_code = '",glob_rec_kandoouser.cmpy_code, "' ", 
	" AND jobledger.trans_type_ind = 'RE' ", 
	" AND activity.job_code = jobledger.job_code ", 
	" AND activity.activity_code = jobledger.activity_code ", 
	" AND activity.var_code = jobledger.var_code ", 
	" AND activity.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	" AND ", p_where_text clipped," ", 
	"ORDER BY jobledger.trans_source_num" 
	PREPARE choice FROM l_query_text 
	DECLARE selcurs CURSOR FOR choice 

	OPEN selcurs 

	FOREACH selcurs INTO pr_jobledger.* 
		SELECT * 
		INTO pr_jmresource.* 
		FROM jmresource 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
		res_code = pr_jobledger.trans_source_text 
		SELECT * 
		INTO pr_job.* 
		FROM job 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
		job_code = pr_jobledger.job_code 

		#---------------------------------------------------------
		OUTPUT TO REPORT JR9_rpt_list(l_rpt_idx,
		pr_jmresource.*, pr_jobledger.*, pr_job.*)  
		IF NOT rpt_int_flag_handler2("Job:",pr_job.job_code, NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------	


{		IF int_flag OR quit_flag THEN		#8503 Continue Report(Y/N)
			IF kandoomsg("U",8503,"") = "N" THEN	#9501 Report Terminated
				LET msgresp=kandoomsg("U",9501,"") 
				EXIT FOREACH 
			END IF 
			LET int_flag = false 
			LET quit_flag = false 
		END IF 
}
	END FOREACH 
	
	#------------------------------------------------------------ 
	FINISH REPORT JR9_rpt_list
	CALL rpt_finish("JR9_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 


REPORT JR9_rpt_list(p_rpt_idx,pr_jmresource, pr_jobledger, pr_job)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx] 
	DEFINE 
	pr_jmresource RECORD LIKE jmresource.*, 
	pr_jobledger RECORD LIKE jobledger.*, 
	pr_job RECORD LIKE job.* 

	OUTPUT 
	left margin 0 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  

		BEFORE GROUP OF pr_jobledger.trans_source_num 
			NEED 11 LINES 
			SKIP 3 LINES 

			PRINT COLUMN 1,"Resource Allocation Number: ", 
			pr_jobledger.trans_source_num USING "########" 
			PRINT COLUMN 1,"Resource Code: ", 
			pr_jmresource.res_code, 
			COLUMN 40, pr_jmresource.desc_text 
			PRINT COLUMN 1,"Unit of Measure: ", pr_jmresource.unit_code, 
			COLUMN 40,"Cost Rate per Unit: ",pr_jmresource.unit_cost_amt 
			USING "########.####", 
			COLUMN 80,"Charge Rate per Unit",pr_jmresource.unit_bill_amt 
			USING "########.####" 
			PRINT COLUMN 1, "Date: ", pr_jobledger.trans_date USING "dd/mm/yy", 
			COLUMN 40, "Year: ", pr_jobledger.year_num USING "####", 
			COLUMN 80, "Period: ",pr_jobledger.period_num 


			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			PRINT COLUMN 1, TRAN_TYPE_JOB_JOB, 
			COLUMN 10, "Description", 
			COLUMN 42, "Variation", 
			COLUMN 52, "Activity", 
			COLUMN 65, "Use", 
			COLUMN 78, "Charge Rate", 
			COLUMN 95, "Charge Amount", 
			COLUMN 113, "Cost Amount" 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		ON EVERY ROW 
			PRINT COLUMN 1, pr_jobledger.job_code, 
			COLUMN 10, pr_job.title_text, 
			COLUMN 46, pr_jobledger.var_code USING "#####", 
			COLUMN 52, pr_jobledger.activity_code, 
			COLUMN 61, pr_jobledger.trans_qty USING "########.##", 
			COLUMN 74, pr_jobledger.trans_amt USING "-----------&.&&&&", 
			COLUMN 91, pr_jobledger.charge_amt USING "-------------&.&&", 
			COLUMN 109, pr_jobledger.trans_amt USING "-------------&.&&" 

		ON LAST ROW 
			SKIP 1 LINES 
			PRINT COLUMN 1, "Report Totals: ", 
			COLUMN 74, sum(pr_jobledger.trans_amt) USING "-----------&.&&&&", 
			COLUMN 91, sum(pr_jobledger.charge_amt) USING "-------------&.&&", 
			COLUMN 109, sum(pr_jobledger.trans_amt) USING "-------------&.&&" 

			SKIP 2 LINES 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	
		
END REPORT 
