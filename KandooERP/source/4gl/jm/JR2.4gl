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
GLOBALS "../jm/JR2_GLOBALS.4gl"

GLOBALS 
	DEFINE 
	pr_company RECORD LIKE company.*, 
	pr_rec_kandoouser RECORD LIKE kandoouser.*, 
	pr_activity RECORD LIKE activity.*, 
	pr_poaudit RECORD LIKE poaudit.*, 
	pr_job RECORD LIKE job.*, 
	pr_jobvars RECORD LIKE jobvars.*, 
	pr_purchdetl RECORD LIKE purchdetl.*, 
	rpt_date DATE, 
	rpt_time CHAR(10), 
	rpt_pageno LIKE rmsreps.page_num, 
	rpt_wid LIKE rmsreps.report_width_num, 
	rpt_length LIKE rmsreps.page_length_num, 
	rpt_note LIKE rmsreps.report_text, 
	pr_output CHAR(60), 
	--where_part CHAR(600), 
	line1, line2 CHAR(80), 
	offset1, offset2 SMALLINT, 
	pr_budget_total, 
	pr_pending_total, 
	pr_approved_total, 
	pr_revision_total, 
	pr_commit_total, 
	pr_measure_total, 
	pr_cost_total, 
	pr_measured_cost_total, 
	pr_bdgt_cost_amt, 
	pr_pend_amt, 
	pr_appro_amt LIKE activity.bdgt_cost_amt, 
	ans CHAR(1), 
	appro_flag SMALLINT 
END GLOBALS 
# \brief module JR2 Billing Report
MAIN 
	#Initial UI Init
	CALL setModuleId("JR2") -- albo 
	CALL ui_init(0) 
	DEFER quit 
	DEFER interrupt 
	CALL authenticate(getmoduleid()) 
	SELECT * INTO pr_company.* FROM company 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET rpt_wid = 132 
	OPEN WINDOW j171 with FORM "J171" -- alch kd-747 
	CALL winDecoration_j("J171") -- alch kd-747 
	MENU " Cost Report" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","JR2","menu-cost_report-1") -- alch kd-506 
		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 
		COMMAND "Report" " SELECT Criteria AND PRINT REPORT" 
			IF jr2_query() THEN 
				NEXT option "Print Manager" 
			END IF 
		ON ACTION "Print Manager" 
			#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
			CALL run_prog("URS","","","","") 
			NEXT option "Exit" 
		COMMAND KEY(interrupt,"E") "Exit" " RETURN TO the menus" 
			EXIT MENU 
		COMMAND KEY (control-w) 
			CALL kandoohelp("") 
	END MENU 
	CLOSE WINDOW j171 
END MAIN 


FUNCTION jr2_query() 
	DEFINE l_where_text STRING
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE 
	query_text CHAR(1000), 
	line_total_amt LIKE poaudit.line_total_amt, 
	pr_zero_ind CHAR(1) 

	LET msgresp = kandoomsg("U",1001,"") 
	#1001 " Enter Selection Criteria - ESC TO Continue"
	CONSTRUCT l_where_text ON 
	activity.job_code, 
	job.title_text, 
	activity.var_code, 
	activity.activity_code, 
	activity.title_text, 
	customer.cust_code, 
	customer.name_text, 
	salesperson.sale_code, 
	salesperson.name_text, 
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
	salesperson.sale_code, 
	salesperson.name_text, 
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
			CALL publish_toolbar("kandoo","JR2","const-activity_job_code-4") -- alch kd-506 
		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 
	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF
	
	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (l_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"JR2_rpt_list",l_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT JR2_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET l_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("JR2_rpt_list")].sel_text
	#------------------------------------------------------------	
	 
	LET pr_zero_ind = kandoomsg("J",8005,"") #1502 Print Zero Value Activities
 
	LET query_text = "SELECT activity.*,", 
	"job.title_text,", 
	"jobvars.appro_date ", 
	"FROM activity,", 
	"job,", 
	"customer, ", 
	"salesperson, ", 
	"outer jobvars ", 
	"WHERE activity.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND job.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND job.job_code = activity.job_code ", 
	"AND customer.cust_code = job.cust_code ", 
	"AND customer.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND salesperson.sale_code = job.sale_code ", 
	"AND salesperson.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND jobvars.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND jobvars.job_code = activity.job_code ", 
	"AND jobvars.var_code = activity.var_code ", 
	"AND ", l_where_text clipped," ", 
	"ORDER BY activity.job_code,", 
	"activity.activity_code,", 
	"activity.var_code,", 
	"appro_date desc" 
	PREPARE s_activity FROM query_text 
	DECLARE c_activity CURSOR FOR s_activity 

	LET pr_budget_total = 0 
	LET pr_pending_total = 0 
	LET pr_approved_total = 0 
	LET pr_revision_total = 0 
	LET pr_commit_total = 0 
	LET pr_measure_total = 0 
	LET pr_cost_total = 0 
	LET pr_measured_cost_total = 0
	 
	DISPLAY "Reporting on Job...:" at 1,2 
	FOREACH c_activity INTO pr_activity.*, 
		pr_job.title_text, 
		pr_jobvars.appro_date 
		DISPLAY pr_activity.job_code," ",pr_job.title_text at 1,20 

		IF pr_zero_ind = "N" THEN 
			SELECT unique 1 FROM jobledger 
			WHERE cmpy_code = pr_activity.cmpy_code 
			AND job_code = pr_activity.job_code 
			AND var_code = pr_activity.var_code 
			AND activity_code = pr_activity.activity_code 
			AND trans_type_ind <> 'SA' 
			AND trans_type_ind <> 'CO' 
			IF status = notfound THEN 
				CONTINUE FOREACH 
			END IF 
		END IF 
		IF pr_activity.var_code = 0 THEN 
			LET pr_bdgt_cost_amt = pr_activity.bdgt_cost_amt 
			LET pr_pend_amt = 0 
			LET pr_appro_amt = 0 
		ELSE 
			IF pr_jobvars.appro_date IS NULL THEN 
				LET pr_bdgt_cost_amt = 0 
				LET pr_pend_amt = pr_activity.bdgt_cost_amt 
				LET pr_appro_amt = 0 
			ELSE 
				LET pr_bdgt_cost_amt = 0 
				LET pr_pend_amt = 0 
				LET pr_appro_amt = pr_activity.bdgt_cost_amt 
			END IF 
		END IF 
		DECLARE pocurs CURSOR FOR 
		SELECT purchdetl.* 
		FROM purchdetl 
		WHERE purchdetl.cmpy_code = pr_activity.cmpy_code 
		AND purchdetl.job_code = pr_activity.job_code 
		AND purchdetl.var_num = pr_activity.var_code 
		AND purchdetl.activity_code = pr_activity.activity_code 
		LET line_total_amt = 0 

		FOREACH pocurs INTO pr_purchdetl.* 
			CALL po_line_info(glob_rec_kandoouser.cmpy_code, 
			pr_purchdetl.order_num, 
			pr_purchdetl.line_num) 
			RETURNING pr_poaudit.order_qty, 
			pr_poaudit.received_qty, 
			pr_poaudit.voucher_qty, 
			pr_poaudit.unit_cost_amt, 
			pr_poaudit.ext_cost_amt, 
			pr_poaudit.unit_tax_amt, 
			pr_poaudit.ext_tax_amt, 
			pr_poaudit.line_total_amt 

			IF pr_poaudit.order_qty IS NULL THEN 
				LET pr_poaudit.order_qty = 0 
			END IF 
			IF pr_poaudit.received_qty IS NULL THEN 
				LET pr_poaudit.received_qty = 0 
			END IF 
			IF pr_poaudit.unit_cost_amt IS NULL THEN 
				LET pr_poaudit.unit_cost_amt = 0 
			END IF 
			IF pr_poaudit.unit_tax_amt IS NULL THEN 
				LET pr_poaudit.unit_tax_amt = 0 
			END IF 
			LET line_total_amt = line_total_amt 
			+ ((pr_poaudit.order_qty 
			- pr_poaudit.received_qty) 
			* (pr_poaudit.unit_cost_amt 
			+ pr_poaudit.unit_tax_amt)) 
		END FOREACH 
		
		LET pr_poaudit.line_total_amt = line_total_amt 

		#---------------------------------------------------------
		OUTPUT TO REPORT JR2_rpt_list(l_rpt_idx,
		pr_activity.job_code, 
		pr_job.title_text, 
		pr_activity.var_code, 
		pr_activity.activity_code, 
		pr_activity.title_text, 
		pr_bdgt_cost_amt, 
		pr_pend_amt, 
		pr_appro_amt, 
		pr_poaudit.line_total_amt, 
		pr_activity.est_comp_per, 
		pr_activity.act_cost_amt )  
--		IF NOT rpt_int_flag_handler2("Receipt:",l_rec_cashreceipt.cash_num, l_rec_customer.name_text,l_rpt_idx) THEN
--			EXIT FOREACH 
--		END IF 
		#---------------------------------------------------------		 
	END FOREACH 


	#------------------------------------------------------------
	FINISH REPORT JR2_rpt_list
	CALL rpt_finish("JR2_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 


REPORT JR2_rpt_list(p_rpt_idx,p_rec_job_data) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE 
	p_rec_job_data RECORD 
		job_code LIKE activity.job_code, 
		job_title LIKE job.title_text, 
		var_code LIKE activity.var_code, 
		activity_code LIKE activity.activity_code, 
		act_title LIKE activity.title_text, 
		bdgt_cost_amt LIKE activity.bdgt_cost_amt, 
		pend_amt LIKE activity.bdgt_cost_amt, 
		appro_amt LIKE activity.bdgt_cost_amt, 
		commit_amt LIKE poaudit.line_total_amt, 
		est_comp_per LIKE activity.est_comp_per, 
		act_cost_amt LIKE activity.act_cost_amt 
	END RECORD, 
	row_cnt SMALLINT, 
	pr_job_meas_amt, # accumulator FOR measured amt FOR curr. job 
	pr_act_meas_amt, # accumulator FOR measured amt FOR curr. activity 
	pr_job_rev_cost, # accumulator FOR job revised costs 
	pr_act_rev_cost, # accumulator FOR activity revised costs 
	pr_meas_amt, pr_bdgt_appro_amt, 
	pr_bdgt_pend_amt, 
	pr_bdgt_cost_amt LIKE activity.est_cost_amt, 
	pr_job_comp_per, 
	pr_act_comp_per SMALLINT, 
	pr_line1, 
	pr_line2, 
	pr_line3 CHAR(132), 
	pr_line_text CHAR(115), 
	pr_temp_text CHAR(20), 
	x,y SMALLINT 

	OUTPUT 

	ORDER external BY p_rec_job_data.job_code, p_rec_job_data.activity_code, p_rec_job_data.var_code 

	FORMAT 
		PAGE HEADER
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  
--			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
--			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text 
--			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  

		 

			PRINT COLUMN 02, "Job /", 
			COLUMN 22, "Budget", 
			COLUMN 35, "Pending", 
			COLUMN 48, "Approved", 
			COLUMN 63, "Revised", 
			COLUMN 75, "Committed", 
			COLUMN 89, "%", 
			COLUMN 95, "Measured", 
			COLUMN 109, "Expended", 
			COLUMN 122, "Measured" 
			PRINT COLUMN 7, "Activity", 
			COLUMN 33, "Variations", 
			COLUMN 47, "Variations", 
			COLUMN 64, "Cost", 
			COLUMN 76, "Cost", 
			COLUMN 85, "Complete", 
			COLUMN 97, "Work", 
			COLUMN 110, "TO date", 
			COLUMN 121, "Less Actual" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		BEFORE GROUP OF p_rec_job_data.job_code 
			SKIP 2 LINES 
			NEED 5 LINES 
			PRINT p_rec_job_data.job_code, " ", p_rec_job_data.job_title 
			LET pr_job_meas_amt = 0 

		BEFORE GROUP OF p_rec_job_data.activity_code 
			LET row_cnt = 0 
			LET pr_act_meas_amt = 0 
		AFTER GROUP OF p_rec_job_data.job_code 
			IF pr_job_rev_cost = 0 THEN 
				LET pr_job_comp_per = 0 
			ELSE 
				LET pr_job_comp_per = pr_job_meas_amt 
				/ pr_job_rev_cost * 100 
			END IF 
			LET pr_job_rev_cost = GROUP sum(p_rec_job_data.bdgt_cost_amt) 
			+ GROUP sum(p_rec_job_data.pend_amt) 
			+ GROUP sum(p_rec_job_data.appro_amt) 
			PRINT COLUMN 16, "-------------", 
			COLUMN 30, "-------------", 
			COLUMN 44, "-------------", 
			COLUMN 58, "-------------", 
			COLUMN 72, "-------------", 
			COLUMN 91, "-------------", 
			COLUMN 105, "-------------", 
			COLUMN 119, "-------------" 
			PRINT COLUMN 02, "Job Total...", 
			COLUMN 16, GROUP sum(p_rec_job_data.bdgt_cost_amt) 
			USING "---------&.&&", 
			COLUMN 30, GROUP sum(p_rec_job_data.pend_amt) 
			USING "---------&.&&", 
			COLUMN 44, GROUP sum(p_rec_job_data.appro_amt) 
			USING "---------&.&&", 
			COLUMN 58, pr_job_rev_cost 
			USING "---------&.&&", 
			COLUMN 72, GROUP sum(p_rec_job_data.commit_amt) 
			USING "---------&.&&", 
			COLUMN 91, pr_job_meas_amt 
			USING "---------&.&&", 
			COLUMN 105, GROUP sum(p_rec_job_data.act_cost_amt) 
			USING "---------&.&&", 
			COLUMN 119, pr_job_meas_amt - GROUP sum(p_rec_job_data.act_cost_amt) 
			USING "---------&.&&" 
			LET pr_budget_total = pr_budget_total 
			+ GROUP sum(p_rec_job_data.bdgt_cost_amt) 
			LET pr_pending_total = pr_pending_total 
			+ GROUP sum(p_rec_job_data.pend_amt) 
			LET pr_approved_total = pr_approved_total 
			+ GROUP sum(p_rec_job_data.appro_amt) 
			LET pr_revision_total = pr_revision_total 
			+ pr_job_rev_cost 
			LET pr_commit_total = pr_commit_total 
			+ GROUP sum(p_rec_job_data.commit_amt) 
			LET pr_measure_total = pr_measure_total 
			+ pr_job_meas_amt 
			LET pr_cost_total = pr_cost_total 
			+ GROUP sum(p_rec_job_data.act_cost_amt) 
			LET pr_measured_cost_total = pr_measured_cost_total 
			+ pr_job_meas_amt 
			- GROUP sum(p_rec_job_data.act_cost_amt) 
		AFTER GROUP OF p_rec_job_data.activity_code 
			LET pr_act_rev_cost = GROUP sum(p_rec_job_data.bdgt_cost_amt) 
			+ GROUP sum(p_rec_job_data.pend_amt) 
			+ GROUP sum(p_rec_job_data.appro_amt) 
			IF pr_act_rev_cost = 0 THEN 
				LET pr_act_comp_per = 0 
			ELSE 
				LET pr_act_comp_per = pr_act_meas_amt 
				/ pr_act_rev_cost * 100 
			END IF 
			PRINT COLUMN 3, p_rec_job_data.activity_code, 
			COLUMN 13, p_rec_job_data.act_title 
			PRINT COLUMN 16, GROUP sum(p_rec_job_data.bdgt_cost_amt) 
			USING "---------&.&&", 
			COLUMN 30, GROUP sum(p_rec_job_data.pend_amt) 
			USING "---------&.&&", 
			COLUMN 44, GROUP sum(p_rec_job_data.appro_amt) 
			USING "---------&.&&", 
			COLUMN 58, pr_act_rev_cost 
			USING "---------&.&&", 
			COLUMN 72, GROUP sum(p_rec_job_data.commit_amt) 
			USING "---------&.&&", 
			COLUMN 85, pr_act_comp_per USING "####&", 
			COLUMN 91, pr_act_meas_amt 
			USING "---------&.&&", 
			COLUMN 105, GROUP sum(p_rec_job_data.act_cost_amt) 
			USING "---------&.&&", 
			COLUMN 119, pr_meas_amt - GROUP sum(p_rec_job_data.act_cost_amt) 
			USING "---------&.&&" 
		AFTER GROUP OF p_rec_job_data.var_code 
			LET row_cnt = row_cnt + 1 
			LET pr_meas_amt = (p_rec_job_data.bdgt_cost_amt + p_rec_job_data.appro_amt + p_rec_job_data.pend_amt) 
			* p_rec_job_data.est_comp_per /100 
			IF pr_meas_amt IS NOT NULL THEN 
				LET pr_act_meas_amt = pr_act_meas_amt + pr_meas_amt 
				LET pr_job_meas_amt = pr_job_meas_amt + pr_act_meas_amt 
			END IF 

		ON LAST ROW 
			SKIP 2 LINES 
			PRINT COLUMN 16, "-------------", 
			COLUMN 30, "-------------", 
			COLUMN 44, "-------------", 
			COLUMN 58, "-------------", 
			COLUMN 72, "-------------", 
			COLUMN 91, "-------------", 
			COLUMN 105, "-------------", 
			COLUMN 119, "-------------" 

			PRINT COLUMN 01, "Report Total.", 
			COLUMN 16, pr_budget_total USING "---------&.&&", 
			COLUMN 30, pr_pending_total USING "---------&.&&", 
			COLUMN 44, pr_approved_total USING "---------&.&&", 
			COLUMN 58, pr_revision_total USING "---------&.&&", 
			COLUMN 72, pr_commit_total USING "---------&.&&", 
			COLUMN 91, pr_measure_total USING "---------&.&&", 
			COLUMN 105, pr_cost_total USING "---------&.&&", 
			COLUMN 119, pr_measured_cost_total USING "---------&.&&"
			 
			SKIP 1 LINES 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	
			
END REPORT 
