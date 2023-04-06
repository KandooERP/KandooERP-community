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
GLOBALS "../jm/JRL_GLOBALS.4gl"



GLOBALS 
	DEFINE 
	pr_output CHAR(20), 
	pr_rec_kandoouser RECORD LIKE kandoouser.*, 
	pr_company RECORD LIKE company.*, 
	pr_job RECORD LIKE job.*, 
	where_part, 
	where_part2 CHAR(1500), 
	query_text CHAR(3000), 
	rpt_date LIKE rmsreps.report_date, 
	rpt_note CHAR(80), 
	rpt_wid LIKE rmsreps.report_width_num, 
	line1, 
	line2 CHAR(120), 
	j, 
	i, 
	offset1, 
	offset2 SMALLINT, 
	rpt_head SMALLINT, 
	rpt_time CHAR(8), 
	col, 
	col2 SMALLINT, 
	cmpy_head CHAR(130) 
END GLOBALS 

#  JRL - Job Listing
MAIN 
	LET rpt_date = today USING "dd/mm/yyyy" 
	LET rpt_time = time 

	#Initial UI Init
	CALL setModuleId("JRL") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 


	LET rpt_wid = 132 
	LET rpt_note = NULL 
	SELECT * INTO pr_company.* FROM company 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	OPEN WINDOW j170 with FORM "J170" -- alch kd-747 
	CALL winDecoration_j("J170") -- alch kd-747 
	MENU " JM Listing" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","JRL","menu-jm_listing-1") -- alch kd-506 
		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND "Report" " SELECT criteria AND PRINT REPORT" 
			LET rpt_head = true 
			IF JR1_rpt_query() THEN 
				NEXT option "Print Manager" 
				LET rpt_note = NULL 
			END IF 

		ON ACTION "Print Manager" 
			# COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
			CALL run_prog("URS", "", "", "", "") 
			NEXT option "Exit" 

		COMMAND "Message" " Enter REPORT heading" 
			--         prompt "Enter text..." FOR rpt_note -- albo
			LET rpt_note = promptInput("Enter text...","",60) -- albo 
			NEXT option "Report" 

		COMMAND KEY(interrupt, "E") "Exit" " Exit TO menus" 
			EXIT MENU 

	END MENU 

	CLOSE WINDOW J170 
END MAIN 


FUNCTION JR1_rpt_query() 
	DEFINE l_where_text STRING
	DEFINE pr_jmparms RECORD LIKE jmparms.*
	 
	SELECT * INTO pr_jmparms.* FROM jmparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND key_code = "1"
	 
	LET msgresp = kandoomsg("U",1001,"")	#1001 " Enter Selection Criteria - ESC TO Continue"
	CONSTRUCT BY NAME l_where_text ON 
	job.job_code, 
	job.title_text, 
	job.cust_code, 
	job.est_start_date, 
	job.review_date, 
	job.act_start_date, 
	job.est_end_date, 
	job.val_date, 
	job.act_end_date, 
	job.contract_text, 
	job.contract_date, 
	job.contract_amt, 
	job.bill_way_ind, 
	job.acct_code, 
	job.finish_flag, 
	job.report_text, 
	job.resp_code 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","JRL","const-job_job_code-11") -- alch kd-506
 
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

FUNCTION AC1_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE i SMALLINT 
	
	
	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"JRL_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT JRL_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("JRL_rpt_list")].sel_text
	#------------------------------------------------------------

	
	LET msgresp = kandoomsg("U",1002,"")#1002 Searching Database; Please Wait.
	LET l_query_text = "SELECT unique job.* ", 
	" FROM job WHERE ", 
	p_where_text clipped, 
	" AND job.cmpy_code = \"", glob_rec_kandoouser.cmpy_code, "\"", 
	" ORDER BY job.cmpy_code, job.type_code, job.job_code " 
	



	PREPARE q_1 FROM l_query_text 
	DECLARE c_1 CURSOR FOR q_1 
	
	FOREACH c_1 INTO pr_job.* 
		#---------------------------------------------------------
		OUTPUT TO REPORT JRL_rpt_list(l_rpt_idx,
		pr_job.*)  
		IF NOT rpt_int_flag_handler2("Job:",pr_job.title_text, NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------		
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT JRL_rpt_list
	CALL rpt_finish("AJRL_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
	 
END FUNCTION 


REPORT JRL_rpt_list(p_rpt_idx,pr_job) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE 
	pr_job RECORD LIKE job.*, 
	s, len SMALLINT 

	OUTPUT 

	ORDER external BY pr_job.cmpy_code, 
	pr_job.type_code, 
	pr_job.job_code 

	FORMAT 
		PAGE HEADER 

			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  
	
			PRINT COLUMN 01, TRAN_TYPE_JOB_JOB, 
			COLUMN 10, "Description", 
			COLUMN 53, "Customer" 
	
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  
			 
		ON EVERY ROW 
			PRINT COLUMN 01, pr_job.job_code, 
			COLUMN 10, pr_job.title_text, 
			COLUMN 53, pr_job.cust_code
			 
		ON LAST ROW 
			SKIP 5 LINES 
{
			PRINT COLUMN 10, "Report used the following selection criteria" 
			SKIP 2 LINES 
			PRINT COLUMN 10, "WHERE:-" 
			SKIP 1 LINES 
			LET len = length(where_part) 
			FOR s = 1 TO 1421 step 60 
				IF len > s THEN 
					PRINT COLUMN 10, "|", where_part[s, s + 59], "|" 
				ELSE 
					LET s = 32000 
				END IF 

			END FOR
			# the last line doesnt have 60 characters of where_part TO display
}
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	
			
END REPORT