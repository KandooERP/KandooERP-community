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

# JRF.4gl Job Management WIP Reconciliation Report

GLOBALS 

	DEFINE 
	formname CHAR(15), 
	rpt_pageno LIKE rmsreps.page_num, 
	rpt_wid LIKE rmsreps.report_width_num, 
	rpt_length LIKE rmsreps.page_length_num, 
	rpt_note LIKE rmsreps.report_text, 
	pr_menunames RECORD LIKE menunames.*, 
	pa_job ARRAY [100] OF RECORD 
		trans CHAR(1), 
		job_code LIKE job.job_code, 
		title_text LIKE job.title_text, 
		type_code LIKE job.type_code, 
		bill_way_ind LIKE job.bill_way_ind, 
		cost DECIMAL(16, 2) 
	END RECORD, 
	pr_job RECORD LIKE job.*, 
	pr_jobtype RECORD LIKE jobtype.*, 
	pr_jobvars RECORD LIKE jobvars.*, 
	pr_job_desc RECORD LIKE job_desc.*, 
	pa_job_desc ARRAY [100] OF LIKE job_desc.desc_text, 
	pr_customer RECORD LIKE customer.*, 
	pr_coa RECORD LIKE coa.*, 
	pr_account RECORD LIKE account.*, 
	pr_jmparms RECORD LIKE jmparms.*, 
	pr_rec_kandoouser RECORD LIKE kandoouser.*, 
	pr_user_scan_code LIKE kandoouser.acct_mask_code, 
	pv_date DATE, 
	pv_year LIKE period.year_num, 
	pv_period LIKE period.period_num, 
	user_default_code, 
	acct_desc_text LIKE coa.desc_text, 
	default_entry_ok, 
	entry_flag SMALLINT, 
	err_continue CHAR(1), 
	return_status INTEGER, 
	ans CHAR(1), 
	max_cnt SMALLINT, 
	runner CHAR(30), 
	idx, 
	scrn, 
	cnt SMALLINT, 
	rpt_time CHAR(10), 
	file_name CHAR(30), 
	pr_output CHAR(60), 
	where_clause CHAR(499), 
	fv_job_code LIKE job.job_code, 
	fv_apply_cos_amt LIKE resbill.apply_cos_amt 
END GLOBALS 


MAIN 
	#Initial UI Init
	CALL setModuleId("JRF") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	CALL user_security(glob_rec_kandoouser.cmpy_code, glob_rec_kandoouser.sign_on_code) 
	RETURNING pr_rec_kandoouser.acct_mask_code,	pr_user_scan_code 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN "1" #UI/MENU Mode 	
			OPEN WINDOW J314 with FORM "J314" -- alch kd-747 
			CALL winDecoration_j("J314") -- alch kd-747 
		
			MENU " WIP Reconciliation" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","JRF","menu-wip_reconc-1") -- alch kd-506 
					CALL rpt_rmsreps_reset(NULL) 
					CALL JRF_rpt_process(JRF_rpt_query()) 

				ON ACTION "WEB-HELP" -- albo kd-373 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "REPORRT" --COMMAND "Report" " Generate Job Reconciliation Report" 
					CALL rpt_rmsreps_reset(NULL) 
					CALL JRF_rpt_process(JRF_rpt_query()) 
		
				ON ACTION "Print Manager"					#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS", "", "", "", "") 
		
				ON ACTION "CANCEL" --COMMAND KEY(interrupt, "E") "Exit" " Exit TO menus" 
					EXIT MENU 
		 
			END MENU 
			
			CLOSE WINDOW J314 

		WHEN "2" #Background Process with rmsreps.report_code
			CALL JRF_rpt_process(NULL)  

		WHEN "3" #Only create query-where-part
			OPEN WINDOW J314 with FORM "J314" 
			CALL winDecoration_j("J314") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(JRF_rpt_query()) #save where clause in env 
			CLOSE WINDOW J314 
			
		WHEN "4" #Background Process with SQL WHERE ARGUMENT
			CALL JRF_rpt_process(get_url_sel_text())
	END CASE 	
		
END MAIN 


FUNCTION JRF_rpt_query() 
	DEFINE l_where_text STRING
	
	CREATE temp TABLE job_act(job_code CHAR(12), var_code SMALLINT, 
	activity_code CHAR(8), wip_acct_code CHAR(18), 
	title_text CHAR(30), bill_way_ind CHAR(1)) 
	
	CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, today)	RETURNING pv_year, pv_period
	 
	LET msgresp = kandoomsg("U", 1503, "")
	 
	INPUT 
		pv_year, pv_period WITHOUT DEFAULTS 
	FROM 
		jobledger.year_num,	jobledger.period_num 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","JRF","input-pv_year-1") -- alch kd-506 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

		AFTER FIELD year_num 
			IF pv_year IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 			#9102 Value must be entered.
				NEXT FIELD jobledger.year_num 
			END IF 
			
			SELECT unique period.year_num 
			FROM period 
			WHERE period.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND period.year_num = pv_year 
			IF status = notfound THEN 
				LET msgresp = kandoomsg("J", 9617, "")				#9617 Invalid year number entered.
				NEXT FIELD year_num 
			END IF 
			
		AFTER FIELD jobledger.period_num 
			IF pv_period IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"")				#9102 Value must be entered.
				NEXT FIELD jobledger.period_num 
			END IF 
			
			SELECT period.* 
			FROM period 
			WHERE period.year_num = pv_year 
			AND period.period_num = pv_period 
			AND period.cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF status = notfound THEN 
				LET msgresp = kandoomsg("W", 9241, "")	#9241 Invalid year AND period.
				NEXT FIELD jobledger.year_num 
			END IF 
			
		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN 
				SELECT unique period.year_num 
				FROM period 
				WHERE period.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND period.year_num = pv_year 
				IF status = notfound THEN 
					LET msgresp = kandoomsg("J", 9617, "") 
					#9617 Invalid year number entered.
					NEXT FIELD year_num 
				END IF 
				
				SELECT period.* 
				FROM period 
				WHERE period.year_num = pv_year 
				AND period.period_num = pv_period 
				AND period.cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = notfound THEN 
					LET msgresp = kandoomsg("W", 9241, "")			#9241 Invalid year AND period.
					NEXT FIELD jobledger.year_num 
				END IF 
			END IF 

	END INPUT 
	
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		DROP TABLE job_act 
		RETURN NULL 
	END IF 

	CONSTRUCT BY NAME l_where_text ON 
	activity.job_code, 
	activity.wip_acct_code 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","JRF","const-activity_job_code-5") -- alch kd-506 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 
	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false
		
		DROP TABLE job_act
		 
		MESSAGE "Report Generation aborted"
		RETURN NULL
	ELSE
		RETURN l_where_text
	END IF 	
END FUNCTION 

FUNCTION JRF_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx] 
	DEFINE 
	fr_job RECORD LIKE job.*, 
	fr_activity RECORD LIKE activity.*, 
	query_text CHAR(999), 
	fr_job_act RECORD 
		job_code LIKE job.job_code, 
		var_code LIKE activity.var_code, 
		activity_code LIKE activity.activity_code, 
		wip_acct_code LIKE activity.wip_acct_code, 
		title_text LIKE activity.title_text, 
		bill_way_ind LIKE activity.bill_way_ind 
	END RECORD, 
	fv_amt DECIMAL(16, 2), 
	fv_billed, 
	fv_posted LIKE activity.bdgt_bill_amt, 
	fv_count SMALLINT, 
	fv_sel, 
	fv_sel2 CHAR(500), 
	fr_jobledger RECORD LIKE jobledger.*, 
	fr_resbill RECORD LIKE resbill.* 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"JRF_rpt_list_recon_rept",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT JRF_rpt_list_recon_rept TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("JRF_rpt_list_recon_rept")].sel_text
	#------------------------------------------------------------

	LET l_query_text = "SELECT * ", 
	"FROM job, activity ", 
	" WHERE job.job_code = activity.job_code", 
	" AND job.cmpy_code = \"", glob_rec_kandoouser.cmpy_code, "\"", 
	" AND activity.cmpy_code = \"", glob_rec_kandoouser.cmpy_code, "\"", 
	" AND ", p_where_text clipped, 
	" AND job.locked_ind <= ", "1" 
	PREPARE ex_stmt1 
	FROM l_query_text 
	
	DECLARE act_curs CURSOR FOR ex_stmt1 
	FOREACH act_curs INTO fr_job.*, 
		fr_activity.* 
		INSERT INTO job_act VALUES (fr_activity.job_code, fr_activity.var_code, 
		fr_activity.activity_code , fr_activity.wip_acct_code, 
		fr_job.title_text , fr_activity.bill_way_ind) 
	END FOREACH 
	LET query_text = "SELECT * ", 
	"FROM job_act ", 
	"ORDER BY wip_acct_code, job_code " 
	PREPARE ex_stmt2 
	FROM query_text 

	#DISPLAY "Reporting on Job:" at 1,3 
	DECLARE act2_curs CURSOR FOR ex_stmt2 
	
	FOREACH act2_curs INTO fr_job_act.* 
		LET fv_amt = 0 
		LET fv_billed = 0 
		LET fv_posted = 0 
		IF fr_job_act.bill_way_ind = "F" THEN 
			SELECT sum(trans_amt), 
			count(*) INTO fv_billed, 
			fv_count 
			FROM jobledger 
			WHERE job_code = fr_job_act.job_code 
			AND var_code = fr_job_act.var_code 
			AND activity_code = fr_job_act.activity_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND trans_amt IS NOT NULL 
			AND trans_type_ind != "CT" 
			AND (year_num < pv_year 
			OR (year_num = pv_year 
			AND period_num <= pv_period)) 
			
			IF fv_count = 0 THEN 
				CONTINUE FOREACH 
			END IF 
			
			IF fv_billed IS NULL THEN 
				LET fv_billed = 0 
			END IF 
			LET fv_posted = fr_activity.post_cost_amt 
		ELSE 
			LET fv_sel = 'select * ', 
			'from jobledger ', 
			'where job_code = "', fr_job_act.job_code, '" ', 
			'and var_code = "', fr_job_act.var_code, '" ', 
			'and activity_code = "', fr_job_act.activity_code, '" ', 
			'and cmpy_code = "', glob_rec_kandoouser.cmpy_code, '" ', 
			'and trans_amt IS NOT NULL ', 
			'and ( year_num < "', pv_year, '" OR ', 
			'( year_num = "', pv_year, '" AND period_num <= "', pv_period,'" )) ', 
			'order BY seq_num ' 
			PREPARE s_1 
			FROM fv_sel 
			
			DECLARE c_1 CURSOR FOR s_1 
			FOREACH c_1 INTO fr_jobledger.* 
				LET fv_billed = fv_billed + fr_jobledger.trans_amt 
				LET fv_sel2 = 'select * ', 
				'from resbill ', 
				'where job_code = "', fr_job_act.job_code, '" ', 
				'and var_code = "', fr_job_act.var_code, '" ', 
				'and activity_code = "', fr_job_act.activity_code, '" ', 
				'and cmpy_code = "', glob_rec_kandoouser.cmpy_code, '" ', 
				'and apply_cos_amt IS NOT NULL ', 
				'and seq_num = "', fr_jobledger.seq_num, '"' 
				PREPARE s_2 
				FROM fv_sel2 
				DECLARE c_2 CURSOR FOR s_2 
				FOREACH c_2 INTO fr_resbill.* 
					LET fv_posted = fv_posted + fr_resbill.apply_cos_amt 
				END FOREACH 
			END FOREACH 
		END IF 
		
		IF fv_posted IS NULL THEN 
			LET fv_posted = 0 
		END IF 
		IF fv_billed IS NULL THEN 
			LET fv_billed = 0 
		END IF 
		
		IF fv_billed != fv_posted THEN 
			LET fv_amt = fv_billed - fv_posted
			#---------------------------------------------------------
			OUTPUT TO REPORT JRF_rpt_list_recon_rept(l_rpt_idx,
			fr_job_act.*, fv_amt) 
			IF NOT rpt_int_flag_handler2("Job:",fr_job_act.job_code , NULL,l_rpt_idx) THEN
				EXIT FOREACH 
			END IF 
			#---------------------------------------------------------	
			 
		END IF 
	END FOREACH 

	DROP TABLE job_act 
	
	#------------------------------------------------------------
	FINISH REPORT JRF_rpt_list_recon_rept
	CALL rpt_finish("JRF_rpt_list_recon_rept")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF  
END FUNCTION 


REPORT JRF_rpt_list_recon_rept(p_rpt_idx,rr_job_act, pv_amt)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx] 
	DEFINE 
	rr_job_act RECORD 
		job_code LIKE job.job_code, 
		var_code LIKE activity.var_code, 
		activity_code LIKE activity.activity_code, 
		wip_acct_code LIKE activity.wip_acct_code, 
		title_text LIKE activity.title_text, 
		bill_way_ind LIKE activity.bill_way_ind 
	END RECORD, 
	pr_job RECORD LIKE job.*, 
	pr_activity RECORD LIKE activity.*, 
	pv_amt LIKE jobledger.trans_amt, 
	rr_company RECORD LIKE company.*, 
	rv_type_text LIKE jobtype.type_text, 
	rv_acct_desc LIKE coa.desc_text, 
	rv_rpt_wid SMALLINT, 
	rv_offset1 SMALLINT, 
	rv_offset2 SMALLINT, 
	rv_title CHAR(50), 
	rv_line1 CHAR(80), 
	rv_line2 CHAR(80) 
	
	OUTPUT 

	ORDER external BY rr_job_act.wip_acct_code, rr_job_act.job_code 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  
			
			LET rv_acct_desc = "OTHER" 
			SELECT desc_text INTO rv_acct_desc 
			FROM coa 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND acct_code = rr_job_act.wip_acct_code 
			 
			PRINT COLUMN 1, "----------------------------------------", 
			"----------------------------------------" 
			PRINT COLUMN 1, rr_job_act.wip_acct_code, 
			COLUMN 10, rv_acct_desc 
			PRINT COLUMN 1, "----------------------------------------", 
			"----------------------------------------" 
			PRINT COLUMN 1, "JOB NO.", 
			COLUMN 10, "DESCRIPTION", 
			COLUMN 45, "AMOUNT" 
			PRINT COLUMN 1, "----------------------------------------", 
			"----------------------------------------"
			 
		BEFORE GROUP OF rr_job_act.wip_acct_code 
			SKIP TO top OF PAGE
			 
		AFTER GROUP OF rr_job_act.wip_acct_code 
			SELECT * INTO pr_account.* 
			FROM account 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND acct_code = rr_job_act.wip_acct_code 
			AND year_num = pv_year 
			IF status = notfound THEN 
				LET pr_account.bal_amt = 0 
			END IF 
			SKIP 1 line 
			PRINT COLUMN 03, "TOTALS FOR GL CODE", 
			COLUMN 22, rr_job_act.wip_acct_code, 
			COLUMN 41, GROUP sum(pv_amt) USING "--,---,--&.&&" 
			PRINT COLUMN 03, "ACTUAL A/C BALANCE ", 
			COLUMN 41, pr_account.bal_amt USING "--,---,--&.&&", 
			COLUMN 57, "Variance ", 
			(group sum(pv_amt) - pr_account.bal_amt) 
			USING "--,---,--&.&&"
			 
		AFTER GROUP OF rr_job_act.job_code 
			PRINT COLUMN 01, rr_job_act.job_code, 
			COLUMN 10, rr_job_act.title_text, 
			COLUMN 41, GROUP sum(pv_amt) USING "--,---,--&.&&"
			 
		ON LAST ROW 
			SKIP 2 LINES 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	
			
END REPORT