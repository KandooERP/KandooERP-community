{
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

	Source code beautified by beautify.pl on 2020-01-02 19:48:24	$Id: $
}



{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module JRD.4gl Job Type Report

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "J_JM_GLOBALS.4gl" 
GLOBALS 
	DEFINE 
	formname CHAR(15), 
	pr_menunames RECORD LIKE menunames.*, 
	pr_company RECORD LIKE company.*, 
	pr_jmparms RECORD LIKE jmparms.*, 
	pr_rec_kandoouser RECORD LIKE kandoouser.*, 
	pr_user_scan_code LIKE kandoouser.acct_mask_code, 
	ans CHAR(1), 
	where_part, query_text CHAR(800), 
	pr_jobtype RECORD LIKE jobtype.*, 
	rpt_pageno LIKE rmsreps.page_num, 
	rpt_wid LIKE rmsreps.report_width_num, 
	rpt_length LIKE rmsreps.page_length_num, 
	rpt_note LIKE rmsreps.report_text, 
	err_flag, idx, scrn, cnt SMALLINT, 
	pa_desc array[5] OF CHAR(20) 
END GLOBALS 

MAIN 

	#Initial UI Init
	CALL setModuleId("JRD") -- albo 
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

	LET pa_desc[1] = " - Optional" 
	LET pa_desc[2] = " - Must Enter" 
	LET pa_desc[3] = " - No Entry Required" 

	CLEAR screen 
	
	
		CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN "1" #UI/MENU Mode  
			OPEN WINDOW J304 with FORM "J304" -- alch kd-747 
			CALL winDecoration_j("J304") -- alch kd-747 
			MENU " Job Type" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","JRD","menu-job_type-1") -- alch kd-506
 					CALL rpt_rmsreps_reset(NULL) 
					CALL JRD_rpt_process(JRD_rpt_query())
					
				ON ACTION "WEB-HELP" -- albo kd-373 
					CALL onlinehelp(getmoduleid(),null) 
		
				COMMAND "Report" " SELECT criteria AND PRINT REPORT" 
 					CALL rpt_rmsreps_reset(NULL) 
					CALL JRD_rpt_process(JRD_rpt_query())
		
				ON ACTION "Print Manager"				#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 

		
				ON ACTION "CANCEL" --COMMAND KEY(interrupt,"E") "Exit" " RETURN TO Menu" 
					EXIT MENU 
			END MENU 

			CLOSE WINDOW J304 
			CLEAR screen 
	 
		WHEN "2" #Background Process with rmsreps.report_code
			CALL JRD_rpt_process(NULL)  

		WHEN "3" #Only create query-where-part
			OPEN WINDOW J304 with FORM "J304" 
			CALL winDecoration_j("J304") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(JRD_rpt_query()) #save where clause in env 
			CLOSE WINDOW J304 
			
		WHEN "4" #Background Process with SQL WHERE ARGUMENT
			CALL JRD_rpt_process(get_url_sel_text())
	END CASE			
END MAIN 


FUNCTION JRD_rpt_query() 
	DEFINE l_where_text STRING
	
	LET msgresp = kandoomsg("U",1001," ") #MESSAGE " Enter selection criteria - ESC Continue " attribute (yellow) 

	CONSTRUCT BY NAME l_where_text ON 
	type_code, 
	bill_way_ind, 
	bill_issue_ind, 
	bill_acct_code, 
	wip_acct_code, 
	cos_acct_code 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","JRD","const-type_code-1") -- alch kd-506 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 
	END CONSTRUCT 

	IF int_flag OR quit_flag THEN
		LET int_flag = FALSE 
		RETURN NULL
	ELSE
		RETURN l_where_text 
	END IF 
END FUNCTION

FUNCTION JRD_rpt_process(p_where_text) 
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

	LET l_rpt_idx = rpt_start(getmoduleid(),"JRD_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT JRD_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("JRD_rpt_listt")].sel_text
	#------------------------------------------------------------


	LET l_query_text = 
	"SELECT * ", 
	" FROM jobtype WHERE ", 
	" cmpy_code = \"", glob_rec_kandoouser.cmpy_code, "\" AND ", p_where_text clipped, 
	" ORDER BY type_code " 

	IF int_flag OR quit_flag THEN 
		#MESSAGE " Query aborted"
		LET msgresp = kandoomsg("U",9501," ") 
		RETURN 
	END IF 

	PREPARE q_1 FROM l_query_text 
	DECLARE c_1 CURSOR FOR q_1 
	FOREACH c_1 INTO pr_jobtype.*

		#---------------------------------------------------------
		OUTPUT TO REPORT JRD_rpt_list(l_rpt_idx,
		pr_jobtype.*) 
		IF NOT rpt_int_flag_handler2("Job type:",pr_jobtype.type_text, NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------	
	 
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT JRD_rpt_list
	CALL rpt_finish("JRD_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 

REPORT JRD_rpt_list(p_rpt_idx,rr_jobtype ) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE 
	rr_jobtype RECORD LIKE jobtype.*, 
	line1, line2 CHAR(132), 
	fv_rev_desc, 
	fv_wip_desc, 
	fv_cos_desc LIKE coa.desc_text, 
	offset1, offset2, rv_count, rv_sub SMALLINT 

	OUTPUT 
	left margin 0 
	ORDER external BY rr_jobtype.type_code 

	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  
	
		ON EVERY ROW 

			SELECT desc_text 
			INTO fv_rev_desc 
			FROM coa 
			WHERE cmpy_code = rr_jobtype.cmpy_code 
			AND acct_code = rr_jobtype.bill_acct_code 

			IF status != 0 THEN 
				LET fv_rev_desc = "Unknown account" 
			END IF 

			SELECT desc_text 
			INTO fv_cos_desc 
			FROM coa 
			WHERE cmpy_code = rr_jobtype.cmpy_code 
			AND acct_code = rr_jobtype.cos_acct_code 

			IF status != 0 THEN 
				LET fv_cos_desc = "Unknown account" 
			END IF 

			SELECT desc_text 
			INTO fv_wip_desc 
			FROM coa 
			WHERE cmpy_code = rr_jobtype.cmpy_code 
			AND acct_code = rr_jobtype.wip_acct_code 

			IF status != 0 THEN 
				LET fv_wip_desc = "Unknown account" 
			END IF 


			PRINT COLUMN 1, "Job Type : ", rr_jobtype.type_code, 
			1 space, rr_jobtype.type_text 

			PRINT COLUMN 1, "Billing Method : ", rr_jobtype.bill_way_ind; 

			CASE rr_jobtype.bill_way_ind 
				WHEN "C" 
					PRINT 1 space, "Cost Plus" 
				WHEN "F" 
					PRINT 1 space, "Fixed Price" 
				WHEN "T" 
					PRINT 1 space, "Time AND Materials" 
				WHEN "R" 
					PRINT 1 space, "Time AND Materials - Recurring" 
			END CASE 

			PRINT COLUMN 1, "Issue : ", 
			rr_jobtype.bill_issue_ind; 
			CASE rr_jobtype.bill_issue_ind 
				WHEN "1" 
					PRINT 1 space, "Summary Invoices" 
				WHEN "2" 
					PRINT 1 space, "Detailed Invoices" 
				WHEN "3" 
					PRINT 1 space, "Summary Invoices" 
				WHEN "4" 
					PRINT 1 space, "Detailed Invoices" 
				OTHERWISE 
					PRINT 1 space, "Unknown issue type" 
			END CASE 

			PRINT COLUMN 1, "Revenue account : ",pr_jobtype.bill_acct_code clipped, 
			1 space, fv_rev_desc 
			PRINT COLUMN 1, "Work in progress : ",pr_jobtype.wip_acct_code clipped, 
			1 space, fv_wip_desc 
			PRINT COLUMN 1, "Cost of Sales : ",pr_jobtype.cos_acct_code clipped, 
			1 space, fv_cos_desc 

			LET rv_count = 0 

			PRINT COLUMN 1, "User Prompts : "; 

			IF pr_jobtype.prompt1_text IS NOT NULL THEN 
				LET rv_sub = pr_jobtype.prompt1_ind 
				PRINT COLUMN 20, "1. ", pr_jobtype.prompt1_text, 
				COLUMN 40, pa_desc[rv_sub] 
				LET rv_count = rv_count + 1 
			END IF 

			IF pr_jobtype.prompt2_text IS NOT NULL THEN 
				LET rv_sub = pr_jobtype.prompt2_ind 
				PRINT COLUMN 20, "2. ", pr_jobtype.prompt2_text, 
				COLUMN 40, pa_desc[rv_sub] 
				LET rv_count = rv_count + 1 
			END IF 

			IF pr_jobtype.prompt3_text IS NOT NULL THEN 
				LET rv_sub = pr_jobtype.prompt3_ind 
				PRINT COLUMN 20, "3. ", pr_jobtype.prompt3_text, 
				COLUMN 40, pa_desc[rv_sub] 
				LET rv_count = rv_count + 1 
			END IF 

			IF pr_jobtype.prompt4_text IS NOT NULL THEN 
				LET rv_sub = pr_jobtype.prompt4_ind 
				PRINT COLUMN 20, "4. ", pr_jobtype.prompt4_text, 
				COLUMN 40, pa_desc[rv_sub] 
				LET rv_count = rv_count + 1 
			END IF 

			IF pr_jobtype.prompt5_text IS NOT NULL THEN 
				LET rv_sub = pr_jobtype.prompt5_ind 
				PRINT COLUMN 20, "5. ", pr_jobtype.prompt5_text, 
				COLUMN 40, pa_desc[rv_sub] 
				LET rv_count = rv_count + 1 
			END IF 

			IF pr_jobtype.prompt6_text IS NOT NULL THEN 
				LET rv_sub = pr_jobtype.prompt6_ind 
				PRINT COLUMN 20, "6. ", pr_jobtype.prompt6_text, 
				COLUMN 40, pa_desc[rv_sub] 
				LET rv_count = rv_count + 1 
			END IF 

			IF pr_jobtype.prompt7_text IS NOT NULL THEN 
				LET rv_sub = pr_jobtype.prompt7_ind 
				PRINT COLUMN 20, "7. ", pr_jobtype.prompt7_text, 
				COLUMN 40, pa_desc[rv_sub] 
				LET rv_count = rv_count + 1 
			END IF 

			IF pr_jobtype.prompt8_text IS NOT NULL THEN 
				LET rv_sub = pr_jobtype.prompt8_ind 
				PRINT COLUMN 20, "8. ", pr_jobtype.prompt8_text, 
				COLUMN 40, pa_desc[rv_sub] 
				LET rv_count = rv_count + 1 
			END IF 

			IF rv_count = 0 THEN 
				PRINT COLUMN 20, "User Prompts Not Set Up" 
			END IF 

			SKIP 1 line 

		ON LAST ROW 
			SKIP 1 line 

			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	
			

END REPORT 
