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
GLOBALS "../jm/J4_GROUP_GLOBALS.4gl" 
GLOBALS "../jm/J4A_GLOBALS.4gl"
GLOBALS 
	DEFINE formname CHAR(15) 
	DEFINE pr_menunames RECORD LIKE menunames.* 
	DEFINE pr_company RECORD LIKE company.* 
	DEFINE pr_rec_kandoouser RECORD LIKE kandoouser.* 
	DEFINE pr_user_scan_code LIKE kandoouser.acct_mask_code 
	DEFINE pr_activity RECORD LIKE activity.* 
	DEFINE pr_job RECORD LIKE job.* 
	DEFINE pr_output CHAR(60) 
	DEFINE where_part CHAR(200) 
	DEFINE query_text CHAR(1000) 
	DEFINE print_zero CHAR(1) 
	DEFINE rpt_pageno LIKE rmsreps.page_num 
	DEFINE rpt_length LIKE rmsreps.page_length_num 
	DEFINE rpt_time CHAR(10) 
	DEFINE rpt_note CHAR(40) 
	DEFINE rpt_wid SMALLINT 
	DEFINE rpt_date DATE 
END GLOBALS 

###########################################################################
# MAIN
#
# J4A Report - Job Completion Status
###########################################################################
MAIN 

	#Initial UI Init
	CALL setModuleId("J4A") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	CALL user_security(glob_rec_kandoouser.cmpy_code, glob_rec_kandoouser.sign_on_code) 
	RETURNING pr_rec_kandoouser.acct_mask_code, 
	pr_user_scan_code
	 
	SELECT * 
	INTO pr_company.* 
	FROM company 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 

	OPEN WINDOW J171 with FORM "J171" -- alch kd-747 
	CALL winDecoration_j("J171") -- alch kd-747 

	MENU " Activity Completion Report " 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","J4A","menu-act_compl_rep-1") -- alch kd-506 
		COMMAND "Report" " SELECT criteria AND PRINT REPORT" 
			IF J4A_rpt_query() THEN 
				NEXT option "Print " 
			ELSE 
				LET int_flag = false 
				LET quit_flag = false 
			END IF 

		ON ACTION "Print Manager" 
			#COMMAND "Print " " Print OR view using RMS"
			CALL run_prog("URS","","","","") 
			LET int_flag = false 
			LET quit_flag = false 
			NEXT option "Exit" 

		COMMAND KEY(interrupt,"E") "Exit" " RETURN TO the menus" 
			EXIT MENU 

	END MENU 
	CLOSE WINDOW J171 
END MAIN 
###########################################################################
# END MAIN
###########################################################################


###########################################################################
# FUNCTION J4A_rpt_query()
#
# J4A Report - Job Completion Status
###########################################################################
FUNCTION J4A_rpt_query() 
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE pr_rpt_line RECORD 
		job_code LIKE activity.job_code, 
		job_title LIKE job.title_text, 
		var_code LIKE activity.var_code, 
		var_title LIKE jobvars.title_text, 
		activity_code LIKE activity.activity_code, 
		act_title LIKE activity.title_text, 
		est_comp_per LIKE activity.est_comp_per, 
		est_end_date LIKE activity.est_end_date, 
		act_end_date LIKE activity.act_end_date, 
		finish_flag LIKE activity.finish_flag, 
		sort_text LIKE activity.sort_text 
	END RECORD 
	DEFINE l_status_msg1 STRING
	DEFINE l_status_msg2 STRING
	
	#" Enter Selection Criteria - ESC TO Continue"

	LET msgresp = kandoomsg("U",1001,"") 

	CONSTRUCT where_part ON 
	activity.job_code, 
	job.title_text, 
	activity.var_code, 
	activity.activity_code, 
	activity.title_text, 
	customer.cust_code, 
	customer.name_text, 
	activity.est_start_date, 
	activity.est_end_date, 
	activity.act_start_date, 
	activity.act_end_date, 
	activity.sort_text, 
	activity.locked_ind, 
	activity.priority_ind, 
	activity.finish_flag, 
	activity.unit_code, 
	activity.resp_code, 
	activity.report_text, 
	activity.retain_per, 
	activity.retain_amt 
	FROM 
	activity.job_code, 
	job.title_text, 
	activity.var_code, 
	activity.activity_code, 
	activity.title_text, 
	customer.cust_code, 
	customer.name_text, 
	activity.est_start_date, 
	activity.est_end_date, 
	activity.act_start_date, 
	activity.act_end_date, 
	activity.sort_text, 
	activity.locked_ind, 
	activity.priority_ind, 
	activity.finish_flag, 
	activity.unit_code, 
	activity.resp_code, 
	activity.report_text, 
	activity.retain_per, 
	activity.retain_amt 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","J4A","const-activity_job_code-1") -- alch kd-506 
		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 
	END CONSTRUCT 

	IF int_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 


{
	CALL upd_rms(glob_rec_kandoouser.cmpy_code, 
	glob_rec_kandoouser.sign_on_code, 
	pr_rec_kandoouser.security_ind, 
	glob_rec_rmsreps.report_width_num, 
	"J4A", 
	"JM Costing Completion %") 
	RETURNING pr_output 
	START REPORT J4A_rpt_list TO pr_output 
}
	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (where_part IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"J4A_rpt_list",where_part, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT J4A_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET where_part = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("J4A_rpt_list")].sel_text
	#------------------------------------------------------------


	LET query_text = 
	"SELECT job.job_code,", 
	"job.title_text,", 
	"jobvars.var_code,", 
	"jobvars.title_text,", 
	"activity.activity_code,", 
	"activity.title_text,", 
	"activity.est_comp_per,", 
	"activity.est_end_date,", 
	"activity.act_end_date,", 
	"activity.finish_flag,", 
	"activity.sort_text ", 
	"FROM job,", 
	"activity,", 
	"customer,", 
	"outer jobvars ", 
	"WHERE ",where_part clipped," ", 
	"AND job.cmpy_code = \"", glob_rec_kandoouser.cmpy_code, "\" ", 
	"AND activity.cmpy_code = \"", glob_rec_kandoouser.cmpy_code, "\" ", 
	"AND jobvars.cmpy_code = \"", glob_rec_kandoouser.cmpy_code, "\" ", 
	"AND customer.cmpy_code = \"", glob_rec_kandoouser.cmpy_code, "\" ", 
	"AND activity.job_code = job.job_code ", 
	"AND activity.job_code = jobvars.job_code ", 
	"AND activity.var_code = jobvars.var_code ", 
	"AND customer.cust_code = job.cust_code ", 
	"AND (job.acct_code matches \"",pr_user_scan_code,"\" ", 
	"OR job.locked_ind <= \"1\") ", 
	"ORDER BY job.job_code,", 

	"jobvars.var_code,", 
	"activity.activity_code,", 
	"activity.sort_text" 


	PREPARE slstmt FROM query_text 
	DECLARE c_activity CURSOR FOR slstmt 

	
	
	LET msgresp = kandoomsg("J",1518,"") 
	LET print_zero = upshift(msgresp) 


	#   OPEN WINDOW w1 AT 10,10 with 2 rows,64 columns
	#      ATTRIBUTE(border)      -- alch KD-747
	--DISPLAY "Reporting on Job......." at 1,2 
--	DISPLAY " Activity.." at 2,2 
	FOREACH c_activity INTO pr_rpt_line.* 

		IF print_zero = "N" 
		AND pr_rpt_line.est_comp_per = 0 THEN 
		ELSE 
			#---------------------------------------------------------
			OUTPUT TO REPORT J4A_rpt_list(l_rpt_idx,
			pr_rpt_line.*) 
			LET l_status_msg1 = pr_rpt_line.job_code," ",	pr_rpt_line.job_title
			LET l_status_msg2 = pr_rpt_line.activity_code ," ", pr_rpt_line.act_title
			IF NOT rpt_int_flag_handler2("Job/Activity:",l_status_msg1,l_status_msg2,l_rpt_idx) THEN
				EXIT FOREACH 
			END IF 
			#---------------------------------------------------------	
 
		END IF 
	END FOREACH 
 
	#------------------------------------------------------------
	FINISH REPORT J4A_rpt_list
	CALL rpt_finish("J4A_rpt_list")
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
# END FUNCTION J4A_rpt_query()
###########################################################################


###########################################################################
# REPORT J4A_rpt_list(p_rec_rpt_line)
#
# 
###########################################################################
REPORT J4A_rpt_list(p_rpt_idx,p_rec_rpt_line) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_rpt_line RECORD 
		job_code LIKE activity.job_code, 
		job_title LIKE job.title_text, 
		var_code LIKE activity.var_code, 
		var_title LIKE jobvars.title_text, 
		activity_code LIKE activity.activity_code, 
		act_title LIKE activity.title_text, 
		est_comp_per LIKE activity.est_comp_per, 
		est_end_date LIKE activity.est_end_date, 
		act_end_date LIKE activity.act_end_date, 
		finish_flag LIKE activity.finish_flag, 
		sort_text LIKE activity.sort_text 
	END RECORD 
	DEFINE line1, line2 CHAR(80) 
	DEFINE offset1, offset2 SMALLINT 

	OUTPUT 
--	left margin 1 
	ORDER external BY p_rec_rpt_line.job_code, 
	p_rec_rpt_line.var_code, 
	p_rec_rpt_line.activity_code, 
	p_rec_rpt_line.sort_text 
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  

			PRINT COLUMN 64,"Percentage", 
			COLUMN 85,"Completion Dates", 
			COLUMN 111,"Finish" 
			PRINT COLUMN 64,"Completion", 
			COLUMN 80,"Estimated", 
			COLUMN 98,"Actual", 
			COLUMN 112,"Flag" 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  

		BEFORE GROUP OF p_rec_rpt_line.job_code 
			SKIP 1 line 
			PRINT COLUMN 3,"Job: ",p_rec_rpt_line.job_code, 
			" ",p_rec_rpt_line.job_title 
			PRINT COLUMN 3,"--------------------------------------------" 

		BEFORE GROUP OF p_rec_rpt_line.var_code 
			IF p_rec_rpt_line.var_code > 0 THEN 
				SKIP 1 line 
				PRINT COLUMN 6,"Variation:",p_rec_rpt_line.var_code," ", 
				p_rec_rpt_line.var_title 
				PRINT COLUMN 6,"--------------------------------------------", 
				"---" 
			END IF 

		ON EVERY ROW 
			PRINT COLUMN 6, p_rec_rpt_line.activity_code, 
			COLUMN 16, p_rec_rpt_line.act_title, 
			COLUMN 64, p_rec_rpt_line.est_comp_per,"%", 
			COLUMN 80, p_rec_rpt_line.est_end_date, 
			COLUMN 96, p_rec_rpt_line.act_end_date, 
			COLUMN 114, p_rec_rpt_line.finish_flag 

		ON LAST ROW 
			SKIP 2 LINES 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	
			
END REPORT 
###########################################################################
# END REPORT J4A_rpt_list(p_rec_rpt_line)
###########################################################################