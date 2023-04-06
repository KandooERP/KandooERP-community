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
# \brief module JRE.4gl Job REPORT
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "J_JM_GLOBALS.4gl" 
GLOBALS 
	DEFINE 
	formname CHAR(15), 
	rpt_pageno LIKE rmsreps.page_num, 
--	rpt_wid LIKE rmsreps.report_width_num, 
--	rpt_length LIKE rmsreps.page_length_num, 
--	rpt_note LIKE rmsreps.report_text, 
--	pr_menunames RECORD LIKE menunames.*, 
	pr_job RECORD LIKE job.*, 
	pr_company RECORD LIKE company.*, 
	pr_activity RECORD LIKE activity.*, 
	pr_customer RECORD LIKE customer.*, 
	pr_jmparms RECORD LIKE jmparms.*, 
	pr_rec_kandoouser RECORD LIKE kandoouser.*, 
	pr_user_scan_code LIKE kandoouser.acct_mask_code, 
	ans CHAR(1), 
--	where_part, query_text CHAR(3400), 

	pr_jobtype RECORD LIKE jobtype.*, 
--	where_text_2 CHAR(800), 

	err_message CHAR(40), 
	this_bill_amt, 
	job_markup_per LIKE job.markup_per, 
	pv_completed CHAR(1), 

	err_flag, idx, cnt SMALLINT 
END GLOBALS 

DEFINE 	modu_rpt_type CHAR(1)

MAIN 
	#Initial UI Init
	CALL setModuleId("JRE") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) RETURNING glob_rec_kandoouser.cmpy_code, glob_rec_kandoouser.sign_on_code -- albo 
	CALL user_security(glob_rec_kandoouser.cmpy_code, glob_rec_kandoouser.sign_on_code) 
	RETURNING pr_rec_kandoouser.acct_mask_code,pr_user_scan_code
	 
	SELECT jmparms.* 
	INTO pr_jmparms.* 
	FROM jmparms 
	WHERE jmparms.cmpy_code = glob_rec_kandoouser.cmpy_code AND 
	jmparms.key_code = "1" 
	IF status = notfound THEN 
		ERROR " Must SET up JM Parameters first in JZP" 
		SLEEP 5 
		EXIT program 
	END IF
	 
	SELECT * 
	INTO pr_company.* 
	FROM company 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 

	CLEAR screen 
	OPTIONS MESSAGE line 1 


	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN "1" #UI/MENU Mode 	

			OPEN WINDOW j303 with FORM "J303" -- alch kd-747 
			CALL winDecoration_j("J303") -- alch kd-747 
		
			MENU " Jobs" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","JRE","menu-jobs-1") -- alch kd-506 
					CALL rpt_rmsreps_reset(NULL) 
					CALL JRE_rpt_process(JRE_rpt_query()) 

				ON ACTION "WEB-HELP" -- albo kd-373 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "REPORT" --COMMAND "Report" " SELECT criteria AND PRINT REPORT" 
					CALL rpt_rmsreps_reset(NULL) 
					CALL JRE_rpt_process(JRE_rpt_query()) 

		
				ON ACTION "Print Manager"		#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "CANCEL" --COMMAND KEY(interrupt,"E") "Exit" " Exit the Program" 
					EXIT MENU 
		
			END MENU 
		
			CLOSE WINDOW J303 
			CLEAR screen

		WHEN "2" #Background Process with rmsreps.report_code
			CALL JRE_rpt_process(NULL)  

		WHEN "3" #Only create query-where-part
			OPEN WINDOW J303 with FORM "J303" 
			CALL winDecoration_j("J303") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(JRE_rpt_query()) #save where clause in env 
			CLOSE WINDOW J303 
			
		WHEN "4" #Background Process with SQL WHERE ARGUMENT
			CALL JRE_rpt_process(get_url_sel_text())
	END CASE 				 
END MAIN 


FUNCTION JRE_rpt_query() 
	DEFINE l_where_text STRING
	DEFINE pr_output CHAR(60) 
	#   MESSAGE " Enter selection criteria - ESC Continue " attribute (yellow)
	LET msgresp = kandoomsg("U",1001," ") 
	CONSTRUCT BY NAME l_where_text ON 
	job.job_code, 
	job.resp_code, 
	job.type_code, 
	job.est_start_date, 
	job.est_end_date, 
	job.cust_code 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","JRE","const-job_job_code-7") -- alch kd-506 
		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 
	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = 0 
		LET quit_flag = 0 
		RETURN 
		#       EXIT PROGRAM
	END IF 

	LET modu_rpt_type = "F" 

	INPUT modu_rpt_type WITHOUT DEFAULTS 
	FROM formonly.rep_type 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","JRE","input-modu_rpt_type-1") -- alch kd-506 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = 0 
		LET quit_flag = 0 
		RETURN NULL
	ELSE
		RETURN l_where_text 
	END IF 
END FUNCTION


FUNCTION JRE_rpt_process(p_where_text) 
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

	IF modu_rpt_type = "S" THEN 
		LET l_rpt_idx = rpt_start("JRE-SUM","JRE_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	ELSE
		LET l_rpt_idx = rpt_start("JRE-FULL","JRE_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	END IF
	#
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT JRE_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("JRE_rpt_list")].sel_text
	#------------------------------------------------------------


	LET l_query_text = 
	"SELECT * ", 
	" FROM job WHERE ", 
	" job.cmpy_code = \"", glob_rec_kandoouser.cmpy_code, "\" AND ", p_where_text clipped, 
	" AND (job.acct_code matches \"",pr_user_scan_code,"\"", 
	" OR locked_ind = \"1\" )", 
	" ORDER BY job_code " 

	IF int_flag OR quit_flag THEN 
		#MESSAGE " Query aborted"
		LET msgresp = kandoomsg("U",9501," ") 
		RETURN 
	END IF 
	#   CLEAR SCREEN
	#   OPEN WINDOW wdisp AT 10,10 with 2 rows, 40 columns
	#      ATTRIBUTE(border, MESSAGE line last)      -- alch KD-747

	PREPARE q_1 FROM l_query_text 
	DECLARE c_1 CURSOR FOR q_1 
	FOREACH c_1 INTO pr_job.*, pr_customer.* 
		#---------------------------------------------------------
		OUTPUT TO REPORT JRE_rpt_list(l_rpt_idx,
		pr_job.*)
		IF NOT rpt_int_flag_handler2("Job:",pr_job.title_text, NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------	

	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT JRE_rpt_list
	CALL rpt_finish("JRE_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 

REPORT JRE_rpt_list(p_rpt_idx,p_rec_job ) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_job RECORD LIKE job.*, 
	rr_customer RECORD LIKE customer.*, 
	rr_jobtype RECORD LIKE jobtype.*, 
	rr_jobledger RECORD LIKE jobledger.*, 
	line1, line2 CHAR(132), 
	fv_count SMALLINT, 
	ati_cost_amt , 
	ati_bill_amt LIKE activity.act_bill_amt, 
	offset1, offset2 SMALLINT 

	OUTPUT 
	left margin 0 
	ORDER external BY p_rec_job.job_code 

	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			#still needs addressing 
			--IF pv_completed = "Y" THEN 
			--	LET line2 = rpt_note clipped, " including Completed Jobs" 
			--END IF 			
		
			PRINT COLUMN 1, "Activity", 
			COLUMN 40, "Resp", 
			COLUMN 45, "Unit", 
			COLUMN 50, "Budget Cost", 
			COLUMN 64, "Revenue", 
			#                     COLUMN 70, "Meth",
			COLUMN 75, "WIP account", 
			COLUMN 93, "COS account", 
			COLUMN 111, "Revenue account" 
			PRINT 
			
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

		ON EVERY ROW 

			SELECT * 
			INTO rr_customer.* 
			FROM customer 
			WHERE cmpy_code = p_rec_job.cmpy_code 
			AND cust_code = p_rec_job.cust_code 

			SELECT * 
			INTO rr_jobtype.* 
			FROM jobtype 
			WHERE cmpy_code = p_rec_job.cmpy_code 
			AND type_code = p_rec_job.type_code 

			PRINT COLUMN 4, " Job Code: ",p_rec_job.job_code, 
			COLUMN 30, ": ", p_rec_job.title_text 

			PRINT COLUMN 6, "Job Type: ", p_rec_job.type_code, 
			COLUMN 30, ": ", rr_jobtype.type_text, 
			COLUMN 65, "Billing Method : ", p_rec_job.bill_way_ind; 

			CASE p_rec_job.bill_way_ind 
				WHEN "C" 
					PRINT COLUMN 84, "Cost Plus"; 
				WHEN "F" 
					PRINT COLUMN 84, "Fixed Price"; 
				WHEN "T" 
					PRINT COLUMN 84, "Time & Materials"; 
				WHEN "R" 
					PRINT COLUMN 84, "Time & Materials - Recurring"; 
			END CASE 

			PRINT COLUMN 114, "Master Job: "; 

			IF p_rec_job.locked_ind < 1 THEN 
				PRINT COLUMN 126, "Y" 
			ELSE 
				PRINT COLUMN 126, "N" 
			END IF 

			PRINT "Customer Code: ", p_rec_job.cust_code, 
			COLUMN 30, ": ", rr_customer.name_text; 

			IF p_rec_job.internal_flag = "Y" THEN 
				PRINT COLUMN 65, "Internal Job"; 
			ELSE 
				PRINT COLUMN 65, "External Job"; 
			END IF 

			PRINT COLUMN 114, "Finished: ", p_rec_job.finish_flag 

			PRINT "Job Markup ",p_rec_job.markup_per USING "<<&.&&%", 
			COLUMN 41, p_rec_job.resp_code clipped, 
			COLUMN 75, p_rec_job.wip_acct_code clipped, 
			COLUMN 95, p_rec_job.cos_acct_code clipped, 
			COLUMN 114, p_rec_job.acct_code clipped 


			IF modu_rpt_type != "S" THEN 

				DECLARE act_curs CURSOR FOR 
				SELECT activity.* 
				FROM activity 
				WHERE cmpy_code = p_rec_job.cmpy_code 
				AND job_code = p_rec_job.job_code 
				ORDER BY cmpy_code,job_code,var_code,activity_code 

				LET fv_count = 0 
				FOREACH act_curs INTO pr_activity.* 

					IF fv_count = 0 THEN 
						SKIP 1 line 
						#               PRINT COLUMN 1,  "Activity",
						#                     COLUMN 40, "Resp",
						#                     COLUMN 45, "Unit",
						#                     COLUMN 50, "Budget Cost",
						#                     COLUMN 63, "Charge",
						#                     COLUMN 70, "Meth",
						#                     COLUMN 75, "WIP account",
						#                     COLUMN 95, "COS account"
						LET fv_count = 1 
					END IF 

					PRINT 
					COLUMN 1, pr_activity.activity_code clipped, 
					COLUMN 10, pr_activity.title_text clipped, 
					COLUMN 41, pr_activity.resp_code clipped, 
					COLUMN 45, pr_activity.unit_code clipped, 
					COLUMN 49, pr_activity.bdgt_cost_amt USING "------&.&&", 
					COLUMN 60, pr_activity.bdgt_bill_amt USING "------&.&&", 
					COLUMN 71, pr_activity.bill_way_ind, 
					COLUMN 73, pr_activity.cost_alloc_flag, 
					COLUMN 75, pr_activity.wip_acct_code clipped, 
					COLUMN 93, pr_activity.cos_acct_code clipped, 
					COLUMN 111, pr_activity.acct_code clipped 

				END FOREACH 

			END IF 
			SKIP 2 LINES 

		ON LAST ROW 
			SKIP 1 line 
			SKIP 1 line 
			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	
			

END REPORT 
