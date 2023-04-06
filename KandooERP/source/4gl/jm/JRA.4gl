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
# \brief module JRA.4gl Job Summary Report
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "J_JM_GLOBALS.4gl" 
GLOBALS 
	DEFINE 
	pr_company RECORD LIKE company.*, 
	pr_jmparms RECORD LIKE jmparms.*, 
	pr_rec_kandoouser RECORD LIKE kandoouser.*, 
	pr_jobledger RECORD LIKE jobledger.*, 
--	where_text1, query_text CHAR(3400), 
	rpt_wid, 
	rpt_pageno, 
	return_status SMALLINT, 
	pr_output CHAR(60), 
	sum_bdgt_bill, cust_bdgt_bill, tot_bdgt_bill LIKE activity.bdgt_bill_amt, 
	sum_charge_amt, cust_charge_amt, tot_charge_amt LIKE jobledger.charge_amt, 
	sum_trans_amt, cust_trans_amt, tot_trans_amt LIKE jobledger.trans_amt, 
	sum_trans_month,cust_trans_month, tot_trans_month LIKE jobledger.trans_amt, 
	sum_post_revenue, cust_post_revenue, tot_post_revenue LIKE activity.post_revenue_amt, 
	sum_post_cost, cust_post_cost, tot_post_cost LIKE activity.post_cost_amt, 
	gross_profit, cust_gross_profit, tot_gross_profit LIKE jobledger.trans_amt, 
	percentage, cust_percentage, tot_percentage DECIMAL(5,2), 
	pr_resp_name_text LIKE responsible.name_text, 
	pr_user_scan_code LIKE kandoouser.acct_mask_code, 
	pr_jobtype RECORD LIKE jobtype.* 
END GLOBALS 
	DEFINE modu_rec_job RECORD LIKE job.*
	DEFINE modu_rec_customer RECORD LIKE customer.*
MAIN 
	#Initial UI Init
	CALL setModuleId("JRA") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	CALL user_security(glob_rec_kandoouser.cmpy_code, glob_rec_kandoouser.sign_on_code) 

	RETURNING pr_rec_kandoouser.acct_mask_code, 
	pr_user_scan_code 
	SELECT * INTO pr_jmparms.* 
	FROM jmparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND jmparms.key_code = "1" 
	IF status = notfound THEN 
		ERROR " Must SET up JM Parameters first in JZP" 
		SLEEP 5 
		EXIT program 
	END IF 
	SELECT * INTO pr_company.* 
	FROM company 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF status = notfound THEN 
		ERROR " Company details NOT found" 
		SLEEP 5 
		EXIT program 
	END IF 
	OPEN WINDOW j131 with FORM "J131" -- alch kd-747 
	CALL winDecoration_j("J131") -- alch kd-747 
	DISPLAY BY NAME pr_jmparms.prompt1_text, 
	pr_jmparms.prompt2_text, 
	pr_jmparms.prompt3_text, 
	pr_jmparms.prompt4_text, 
	pr_jmparms.prompt5_text, 
	pr_jmparms.prompt6_text, 
	pr_jmparms.prompt7_text, 
	pr_jmparms.prompt8_text 
	MENU " Job Summary" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","JRA","menu-job_summary-1") -- alch kd-506 
		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND "Report" " SELECT criteria AND PRINT REPORT" 
			IF JRA_rpt_query() THEN 
				NEXT option "Print Manager" 
			END IF 

		ON ACTION "Print Manager" 
			#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
			CALL run_prog("URS","","","","") 
			NEXT option "Exit" 

		COMMAND KEY("E",interrupt)"Exit" " Exit the program" 
			EXIT MENU 
		COMMAND KEY (control-w) 
			CALL kandoohelp("") 
	END MENU 
	CLOSE WINDOW j131 
END MAIN 


FUNCTION JRA_rpt_query() 
	DEFINE l_where_text STRING 
	DEFINE 
	continue_rep CHAR(1), 

 
	pr_salesperson RECORD LIKE salesperson.* 

	LET msgresp = kandoomsg("J",1001,"") 
	CONSTRUCT BY NAME l_where_text ON 
	job.job_code, 
	job.title_text, 
	job.type_code, 
	job.cust_code, 
	customer.name_text, 
	job.sale_code, 
	salesperson.name_text, 
	job.est_start_date, 
	job.est_end_date, 
	job.review_date, 
	job.val_date, 
	job.act_start_date, 
	job.act_end_date, 
	job.contract_text, 
	job.contract_date, 
	job.contract_amt, 
	job.locked_ind, 
	job.finish_flag, 
	job.report_text, 
	job.resp_code, 
	job.report1_text, 
	job.report2_text, 
	job.report3_text, 
	job.report4_text, 
	job.report5_text, 
	job.report6_text, 
	job.report7_text, 
	job.report8_text 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","JRA","const-job_job_code-6") -- alch kd-506 
		ON KEY (control-b) 
			CASE 
				WHEN infield (job_code) 
					LET modu_rec_job.job_code = showujobs(glob_rec_kandoouser.cmpy_code, pr_user_scan_code) 
					SELECT title_text 
					INTO modu_rec_job.title_text 
					FROM job 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
					job_code = modu_rec_job.job_code 
					DISPLAY BY NAME modu_rec_job.job_code, modu_rec_job.title_text 

					NEXT FIELD type_code
					 
				WHEN infield (type_code) 
					LET modu_rec_job.type_code = show_type(glob_rec_kandoouser.cmpy_code) 
					SELECT jobtype.* 
					INTO pr_jobtype.* 
					FROM jobtype 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
					type_code = modu_rec_job.type_code 
					DISPLAY BY NAME modu_rec_job.type_code, 
					pr_jobtype.type_text 

					NEXT FIELD cust_code 
					
				WHEN infield (cust_code) 
					LET modu_rec_job.cust_code = show_clnt(glob_rec_kandoouser.cmpy_code) 
					SELECT name_text 
					INTO modu_rec_customer.name_text 
					FROM customer 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
					cust_code = modu_rec_job.cust_code 
					DISPLAY BY NAME modu_rec_job.cust_code, 
					modu_rec_customer.name_text 


					NEXT FIELD sale_code 

				WHEN infield (sale_code) 
					LET modu_rec_job.sale_code = show_salperson(glob_rec_kandoouser.cmpy_code) 
					SELECT name_text 
					INTO pr_salesperson.name_text 
					FROM salesperson 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
					sale_code = modu_rec_job.sale_code 
					DISPLAY BY NAME modu_rec_job.sale_code 

					DISPLAY pr_salesperson.name_text TO salesperson.name_text 

					NEXT FIELD est_start_date 

				WHEN infield(resp_code) 
					LET modu_rec_job.resp_code = show_resp(glob_rec_kandoouser.cmpy_code) 
					SELECT name_text 
					INTO pr_resp_name_text 
					FROM responsible 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
					resp_code = modu_rec_job.resp_code 
					DISPLAY BY NAME modu_rec_job.resp_code 
					DISPLAY pr_resp_name_text TO resp_name_text 
					NEXT FIELD report1_text 
			END CASE 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 
	OPEN WINDOW j165 with FORM "J165" -- alch kd-747 
	CALL winDecoration_j("J165") -- alch kd-747 
	CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,today) 
	RETURNING pr_jobledger.year_num, 
	pr_jobledger.period_num 
	INPUT BY NAME pr_jobledger.year_num, 
	pr_jobledger.period_num WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","JRA","input-pr_jobledger-1") -- alch kd-506 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				CALL valid_period(glob_rec_kandoouser.cmpy_code, pr_jobledger.year_num, 
				pr_jobledger.period_num, "JM") 
				RETURNING pr_jobledger.year_num, 
				pr_jobledger.period_num, 
				return_status 
				IF return_status THEN 
					NEXT FIELD year_num 
				END IF 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	CLOSE WINDOW j165 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 
END FUNCTION

FUNCTION JRA_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]

	 
	LET tot_bdgt_bill = 0 
	LET tot_charge_amt = 0 
	LET tot_trans_amt = 0 
	LET tot_trans_month = 0 
	LET tot_post_revenue = 0 
	LET tot_post_cost = 0 
	LET tot_gross_profit = 0 
	LET tot_percentage = 0 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"JRA_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT JRA_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("JRA_rpt_list")].sel_text
	#------------------------------------------------------------

	
	LET msgresp=kandoomsg("J",1002,"") 
	LET l_query_text = "SELECT job.*,customer.*", 
	" FROM job, customer, salesperson ", 
	"WHERE job.cmpy_code='",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND customer.cmpy_code='",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND customer.cust_code = job.cust_code ", 
	"AND salesperson.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND salesperson.sale_code = job.sale_code ", 
	"AND ",p_where_text clipped," ", 
	"ORDER BY customer.name_text, job.job_code " 


	PREPARE s_job FROM l_query_text 
	DECLARE c_job CURSOR FOR s_job 

	DISPLAY "Reporting on Job...:" at 1,2 
	FOREACH c_job INTO modu_rec_job.*,	modu_rec_customer.*
		#---------------------------------------------------------
		OUTPUT TO REPORT JRA_rpt_list(l_rpt_idx,
		modu_rec_job.*, 
		modu_rec_customer.name_text, 
		pr_jobledger.*) 
		IF NOT rpt_int_flag_handler2("Job:",modu_rec_job.job_code, modu_rec_job.title_text,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------		
 

	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT JRA_rpt_list
	CALL rpt_finish("JRA_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF
END FUNCTION 

REPORT JRA_rpt_list(p_rpt_idx,modu_rec_job,cust_name,pr_jobledger) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE 
	modu_rec_job RECORD LIKE job.*, 
	pr_jobledger RECORD LIKE jobledger.*, 
	pr_activity RECORD LIKE activity.*, 
	cust_name LIKE customer.name_text, 
	line1, line2 CHAR(132), 
	rpt_note CHAR(40), 
	offset1, offset2 SMALLINT 

	OUTPUT 

	ORDER external BY cust_name, modu_rec_job.job_code 
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  
 
			PRINT COLUMN 51, "=========== Work in Progess =========== ", 
			"============== Completed ===============" 
			PRINT COLUMN 01, TRAN_TYPE_JOB_JOB, 
			COLUMN 10, TRAN_TYPE_JOB_JOB, 
			COLUMN 42, "Start", 
			COLUMN 53, "Budget", 
			COLUMN 64, "Billing", 
			COLUMN 78, "Costs", 
			COLUMN 85, "Month", 
			COLUMN 95, "Invoiced", 
			COLUMN 109, "Cost", 
			COLUMN 118, "Gross", 
			COLUMN 125, "% GP TO" 
			PRINT COLUMN 01, "Code", 
			COLUMN 10, "Title", 
			COLUMN 43, "Date", 
			COLUMN 86, "Move", 
			COLUMN 107, "of Sales", 
			COLUMN 118, "Profit", 
			COLUMN 127, "Sales" 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

		BEFORE GROUP OF cust_name 
			SKIP 1 line 
			LET cust_bdgt_bill = 0 
			LET cust_charge_amt = 0 
			LET cust_trans_amt = 0 
			LET cust_trans_month = 0 
			LET cust_post_revenue = 0 
			LET cust_post_cost = 0 
			LET cust_gross_profit = 0 
			LET cust_percentage = 0 
			PRINT COLUMN 01, "Customer name: ", cust_name 
			
		ON EVERY ROW 
			SELECT sum(apply_amt) INTO sum_post_revenue 
			FROM resbill, jobledger 
			WHERE resbill.cmpy_code = modu_rec_job.cmpy_code 
			AND resbill.job_code = modu_rec_job.job_code 
			AND jobledger.cmpy_code = modu_rec_job.cmpy_code 
			AND jobledger.job_code = modu_rec_job.job_code 
			AND jobledger.var_code = resbill.var_code 
			AND jobledger.activity_code = resbill.activity_code 
			AND jobledger.seq_num = resbill.seq_num 
			AND ((year_num = pr_jobledger.year_num 
			AND period_num <= pr_jobledger.period_num) 
			OR (year_num < pr_jobledger.year_num)) 
			IF sum_post_revenue IS NULL THEN 
				LET sum_post_revenue = 0 
			END IF 
			#SELECT sum(post_cost_amt)
			#INTO sum_post_cost FROM activity
			#WHERE cmpy_code = modu_rec_job.cmpy_code
			#AND job_code = modu_rec_job.job_code
			SELECT sum(apply_cos_amt) 
			INTO sum_post_cost 
			FROM resbill, jobledger 
			WHERE resbill.cmpy_code = modu_rec_job.cmpy_code 
			AND resbill.job_code = modu_rec_job.job_code 
			AND jobledger.cmpy_code = modu_rec_job.cmpy_code 
			AND jobledger.job_code = modu_rec_job.job_code 
			AND jobledger.var_code = resbill.var_code 
			AND jobledger.activity_code = resbill.activity_code 
			AND jobledger.seq_num = resbill.seq_num 
			AND ((year_num = pr_jobledger.year_num 
			AND period_num <= pr_jobledger.period_num) 
			OR (year_num < pr_jobledger.year_num)) 
			IF sum_post_cost IS NULL THEN 
				LET sum_post_cost = 0 
			END IF 
			SELECT sum(bdgt_bill_amt) INTO sum_bdgt_bill 
			FROM activity 
			WHERE cmpy_code = modu_rec_job.cmpy_code 
			AND job_code = modu_rec_job.job_code 
			IF sum_bdgt_bill IS NULL THEN 
				LET sum_bdgt_bill = 0 
			END IF 
			SELECT sum(charge_amt) INTO sum_charge_amt 
			FROM jobledger 
			WHERE cmpy_code = modu_rec_job.cmpy_code 
			AND job_code = modu_rec_job.job_code 
			AND ((year_num = pr_jobledger.year_num AND 
			period_num <= pr_jobledger.period_num) 
			OR(year_num < pr_jobledger.year_num)) 
			IF sum_charge_amt IS NULL THEN 
				LET sum_charge_amt = 0 
			ELSE 
				LET sum_charge_amt = sum_charge_amt - sum_post_revenue 
			END IF 
			SELECT sum(trans_amt) 
			INTO sum_trans_amt FROM jobledger 
			WHERE cmpy_code = modu_rec_job.cmpy_code 
			AND job_code = modu_rec_job.job_code 
			AND ((year_num = pr_jobledger.year_num 
			AND period_num <= pr_jobledger.period_num) 
			OR(year_num < pr_jobledger.year_num)) 
			IF sum_trans_amt IS NULL THEN 
				LET sum_trans_amt = 0 
			ELSE 
				LET sum_trans_amt = sum_trans_amt - sum_post_cost 
			END IF 
			SELECT sum(trans_amt) INTO sum_trans_month 
			FROM jobledger 
			WHERE cmpy_code = modu_rec_job.cmpy_code 
			AND job_code = modu_rec_job.job_code 
			AND year_num = pr_jobledger.year_num 
			AND period_num = pr_jobledger.period_num 
			IF sum_trans_month IS NULL THEN 
				LET sum_trans_month = 0 
			END IF 
			LET gross_profit = sum_post_revenue - sum_post_cost 
			IF sum_post_revenue = 0 THEN 
				LET percentage = 0 
			ELSE 
				LET percentage = (gross_profit / sum_post_revenue) * 100 
			END IF 







			LET cust_bdgt_bill = cust_bdgt_bill + sum_bdgt_bill 
			LET cust_charge_amt = cust_charge_amt + sum_charge_amt 
			LET cust_trans_amt = cust_trans_amt + sum_trans_amt 
			LET cust_trans_month = cust_trans_month + sum_trans_month 
			LET cust_post_revenue = cust_post_revenue + sum_post_revenue 
			LET cust_post_cost = cust_post_cost + sum_post_cost 
			IF sum_charge_amt = 0 THEN 
				LET sum_charge_amt = NULL 
			END IF 
			IF sum_trans_amt = 0 THEN 
				LET sum_trans_amt = NULL 
			END IF 
			IF sum_post_revenue = 0 THEN 
				LET sum_post_revenue = NULL 
			END IF 
			IF sum_post_cost = 0 THEN 
				LET sum_post_cost = NULL 
			END IF 
			IF percentage = 0 THEN 
				LET percentage = NULL 
			END IF 
			PRINT COLUMN 01, modu_rec_job.job_code, 
			COLUMN 10, modu_rec_job.title_text, 
			COLUMN 41, modu_rec_job.act_start_date USING "dd/mm/yy", 
			COLUMN 50, sum_bdgt_bill USING "--------#", 
			COLUMN 59, sum_charge_amt USING "--------&.&&", 
			COLUMN 71, sum_trans_amt USING "--------&.&&", 
			COLUMN 83, sum_trans_month USING "------#", 
			COLUMN 91, sum_post_revenue USING "--------&.&&", 
			COLUMN 103, sum_post_cost USING "--------&.&&", 
			COLUMN 116, gross_profit USING "-------#", 
			COLUMN 125, percentage USING "---&.&&" 

		AFTER GROUP OF cust_name 
			LET cust_gross_profit = cust_post_revenue - cust_post_cost 
			IF cust_post_revenue = 0 THEN 
				LET cust_percentage = 0 
			ELSE 
				LET cust_percentage = (cust_gross_profit / cust_post_revenue) * 100 
			END IF 
			LET tot_bdgt_bill = tot_bdgt_bill + cust_bdgt_bill 
			LET tot_charge_amt = tot_charge_amt + cust_charge_amt 
			LET tot_trans_amt = tot_trans_amt + cust_trans_amt 
			LET tot_trans_month = tot_trans_month + cust_trans_month 
			LET tot_post_revenue = tot_post_revenue + cust_post_revenue 
			LET tot_post_cost = tot_post_cost + cust_post_cost 
			PRINT 
			PRINT COLUMN 51, "--------", 
			COLUMN 60, "-----------", 
			COLUMN 72, "-----------", 
			COLUMN 84, "------", 
			COLUMN 92, "-----------", 
			COLUMN 104, "-----------", 
			COLUMN 117, "-------", 
			COLUMN 126, "------" 
			PRINT COLUMN 50, cust_bdgt_bill USING "--------&", 
			COLUMN 59, cust_charge_amt USING "--------&.&&", 
			COLUMN 71, cust_trans_amt USING "--------&.&&", 
			COLUMN 83, cust_trans_month USING "------&", 
			COLUMN 91, cust_post_revenue USING "--------&.&&", 
			COLUMN 103, cust_post_cost USING "--------&.&&", 
			COLUMN 116, cust_gross_profit USING "-------&", 
			COLUMN 125, cust_percentage USING "---&.&&" 

		ON LAST ROW 
			LET tot_gross_profit = tot_post_revenue - tot_post_cost 
			IF tot_post_revenue = 0 THEN 
				LET tot_percentage = 0 
			ELSE 
				LET tot_percentage = (tot_gross_profit / tot_post_revenue) * 100 
			END IF 
			PRINT 
			PRINT COLUMN 51, "========", 
			COLUMN 60, "===========", 
			COLUMN 72, "===========", 
			COLUMN 84, "======", 
			COLUMN 92, "===========", 
			COLUMN 104, "===========", 
			COLUMN 117, "=======", 
			COLUMN 126, "======" 
			PRINT COLUMN 50, tot_bdgt_bill USING "--------&", 
			COLUMN 59, tot_charge_amt USING "--------&.&&", 
			COLUMN 71, tot_trans_amt USING "--------&.&&", 
			COLUMN 83, tot_trans_month USING "------&", 
			COLUMN 91, tot_post_revenue USING "--------&.&&", 
			COLUMN 103, tot_post_cost USING "--------&.&&", 
			COLUMN 116, tot_gross_profit USING "-------&", 
			COLUMN 125, tot_percentage USING "---&.&&" 
			SKIP 2 LINES 
			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	
			
END REPORT 
