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
GLOBALS "../jm/JR3_GLOBALS.4gl"



GLOBALS 
	DEFINE pr_job RECORD LIKE job.*, 
	pr_company RECORD LIKE company.*, 
	pr_customer RECORD LIKE customer.*, 
	pr_jmparms RECORD LIKE jmparms.*, 
	pr_rec_kandoouser RECORD LIKE kandoouser.*, 
	ans, another CHAR(1), 
	where_part, query_text CHAR(3400), 
	err_message CHAR(40), 

	rpt_pageno LIKE rmsreps.page_num, 
	rpt_wid LIKE rmsreps.report_width_num, 
	rpt_length LIKE rmsreps.page_length_num, 
	rpt_note LIKE rmsreps.report_text, 
	pr_output CHAR(20), 
	err_flag, idx, scrn, cnt SMALLINT 
END GLOBALS 

# Purpose - Available Funds Report
MAIN 

	#Initial UI Init
	CALL setModuleId("JR3") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 


	SELECT jmparms.* 
	INTO pr_jmparms.* 
	FROM jmparms 
	WHERE jmparms.cmpy_code = glob_rec_kandoouser.cmpy_code AND 
	jmparms.key_code = "1" 
	SELECT * 
	INTO pr_company.* 
	FROM company 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF status = notfound THEN 
		#Merror " Must SET up JM Parameters first in JZP"
		LET msgresp = kandoomsg("J",1501,"") 
		SLEEP 5 
		EXIT program 
	END IF 

	LET rpt_wid = 132 

	OPTIONS MENU line 1, MESSAGE line 1 
	CLEAR screen 
	OPEN WINDOW j170 with FORM "J170" -- alch kd-747 
	CALL winDecoration_j("J170") -- alch kd-747 
	MENU " Available Funds" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","JR3","menu-available_funds-1") -- alch kd-506 
		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND "Report" " SELECT Criteria AND PRINT REPORT" 
			IF NOT JR3_rpt_query() THEN 
				LET int_flag = false 
				LET quit_flag = false 
			END IF 
			NEXT option "Print Manager" 

		ON ACTION "Print Manager" 
			#COMMAND "Print" " Print OR view using RMS"
			CALL run_prog("URS","","","","") 
			NEXT option "Exit" 

		COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus" 
			EXIT MENU 
		COMMAND KEY (control-w) 
			CALL kandoohelp("") 
	END MENU 
	CLOSE WINDOW j170 
	LET int_flag = false 
	LET quit_flag = false 
END MAIN 

FUNCTION JR3_rpt_query() 
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	LET msgresp = kandoomsg("U",1001,"") #MMESSAGE " Enter criteria FOR selection - ESC TO begin search"
	CALL set_count(3) 
	CONSTRUCT BY NAME where_part ON 
	job.job_code, 
	job.title_text , 
	job.cust_code , 
	customer.name_text, 
	job.sale_code , 
	salesperson.name_text, 
	job.est_start_date , 
	job.review_date , 
	job.act_start_date , 
	job.est_end_date , 
	job.val_date , 
	job.act_end_date , 
	job.contract_text , 
	job.contract_date , 
	job.contract_amt , 
	job.bill_way_ind, 
	job.acct_code, 
	job.finish_flag, 
	job.report_text , 
	job.resp_code 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","JR3","const-job_job_code-5") -- alch kd-506 
		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 
	END CONSTRUCT 

	LET msgresp = kandoomsg("J",1502,"") 
	LET ans = msgresp #1502 Print activities with no transactions (y/n)?

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL
	ELSE
		RETURN where_part 
	END IF 
	
END FUNCTION	
	
FUNCTION JR3_rpt_process(p_where_text) 
	DEFINE p_where_text STRING
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	
		#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"JR3_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT JR3_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("JR3_rpt_list")].sel_text
	#------------------------------------------------------------
	
	LET query_text = 
	"SELECT unique job.* , customer.*", 
	" FROM job, customer, salesperson WHERE ", 
	p_where_text clipped, 
	" AND job.cmpy_code = \"", glob_rec_kandoouser.cmpy_code, "\"", 
	" AND customer.cust_code = job.cust_code ", 
	" AND customer.cmpy_code = \"", glob_rec_kandoouser.cmpy_code, "\"", 
	" AND salesperson.sale_code = job.sale_code ", 
	" AND salesperson.cmpy_code = \"", glob_rec_kandoouser.cmpy_code, "\"", 
	" ORDER BY job.cmpy_code, job.job_code " 

	PREPARE q_1 FROM query_text 
	DECLARE c_1 CURSOR FOR q_1 

	FOREACH c_1 INTO pr_job.*, pr_customer.name_text 
	{	IF int_flag OR quit_flag THEN 
			IF kandoomsg("U",8503,"") = "N" THEN 		#8503 Continue Report (Y/N)
				LET msgresp=kandoomsg("U",9501,"") 		#9501 Printing was aborted.
				EXIT FOREACH 
			END IF 
		END IF
 }
		#---------------------------------------------------------
		OUTPUT TO REPORT JR3_rpt_list(l_rpt_idx,
		pr_job.*, pr_customer.name_text,ans) 
		IF NOT rpt_int_flag_handler2("Job:",pr_job.title_text, NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------	
		
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT JR3_rpt_list
	CALL rpt_finish("JR3_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF
END FUNCTION 


FUNCTION commit_calc(pr_activity) 
	DEFINE pr_activity RECORD LIKE activity.*, 
	pr_poaudit RECORD LIKE poaudit.*, 
	pr_purchdetl RECORD 
		order_date LIKE purchhead.order_date, 
		order_num LIKE purchdetl.order_num, 
		res_code LIKE purchdetl.res_code, 
		line_num LIKE purchdetl.line_num, 
		posted_flag LIKE poaudit.posted_flag, 
		desc_text LIKE purchdetl.desc_text, 
		order_qty LIKE poaudit.order_qty, 
		received_qty LIKE poaudit.received_qty, 
		unit_cost_amt LIKE poaudit.unit_cost_amt, 
		unit_tax_amt LIKE poaudit.unit_tax_amt 
	END RECORD, 
	print_flag INTEGER, 
	held_order_num LIKE purchhead.order_num, 
	calc_commit_amt, commit_amt LIKE activity.bdgt_cost_amt 
	LET calc_commit_amt = 0 
	LET print_flag = 0 
	DECLARE purch_curs CURSOR FOR 
	SELECT purchhead.order_date, 
	purchdetl.order_num,purchdetl.res_code, 
	purchdetl.line_num, poaudit.posted_flag, 
	purchdetl.desc_text, poaudit.order_qty, 
	poaudit.received_qty, poaudit.unit_cost_amt, 
	poaudit.unit_tax_amt 
	INTO pr_purchdetl.* 
	FROM purchhead, purchdetl,poaudit 
	WHERE purchhead.cmpy_code = pr_activity.cmpy_code 
	AND purchhead.cmpy_code = purchdetl.cmpy_code 
	AND purchhead.cmpy_code = poaudit.cmpy_code 
	AND purchhead.order_num = purchdetl.order_num 
	AND purchhead.order_num = poaudit.po_num 
	AND purchdetl.job_code = pr_activity.job_code 
	AND purchdetl.var_num = pr_activity.var_code 
	AND purchdetl.activity_code = pr_activity.activity_code 
	AND purchdetl.line_num = poaudit.line_num 
	ORDER BY purchhead.order_date 
	LET held_order_num = 0 
	FOREACH purch_curs 
		IF held_order_num <> pr_purchdetl.order_num 
		THEN 
			LET held_order_num = pr_purchdetl.order_num 
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
		END IF 
		IF pr_poaudit.order_qty > pr_poaudit.received_qty 
		THEN 
			IF print_flag = 0 THEN 
				LET print_flag = 1 
			END IF 
			LET commit_amt = 
			(pr_purchdetl.unit_cost_amt + pr_purchdetl.unit_tax_amt) 
			* (pr_purchdetl.order_qty - pr_purchdetl.received_qty) 
			LET calc_commit_amt = calc_commit_amt + commit_amt 
		END IF 
	END FOREACH 
	RETURN calc_commit_amt,print_flag 
END FUNCTION 



REPORT JR3_rpt_list(pr_job, cust_name,ans) 
	DEFINE 
	pr_job RECORD LIKE job.*, 
	cust_name LIKE customer.name_text, 
	pr_activity RECORD LIKE activity.*, 
	activity_total, acti_cost_amt_tot, 
	total_commit_amt, job_cost_amt, job_commit_amt, 
	job_total LIKE activity.act_bill_amt, 
	available_tot LIKE activity.bdgt_cost_amt, 
	cost_jtot LIKE activity.act_bill_amt, 
	commit_jtot LIKE activity.act_bill_amt, 
	total_jtot LIKE activity.act_bill_amt, 
	budget_jtot LIKE activity.act_bill_amt, 
	available_jtot LIKE activity.bdgt_cost_amt, 
	pr_jobledger RECORD LIKE jobledger.*, 
	line1, line2 CHAR(132), 
	rpt_note CHAR(40), 
	job_head_flag, act_head_flag, job_tot_print, print_flag INTEGER, 
	ans CHAR(1), 
	offset1, offset2 SMALLINT 


	OUTPUT 
	left margin 0 

	ORDER external BY pr_job.job_code 
	FORMAT 

		PAGE HEADER 
			LET line1 = today clipped, 10 spaces, glob_rec_kandoouser.cmpy_code, 
			2 spaces, pr_company.name_text clipped, 10 spaces, 
			"Page:", pageno USING "####" 

			LET rpt_note = "Available Funds Report (JR3)" 

			LET line2 = rpt_note clipped 
			LET offset1 = (rpt_wid - length(line1))/2 
			LET offset2 = (rpt_wid - length(line2))/2 

			PRINT COLUMN offset1, line1 clipped 
			PRINT COLUMN offset2, line2 clipped 

			PRINT "--------------------------------------------", 
			"--------------------------------------------", 
			"--------------------------------------------" 

			PRINT COLUMN 1,"Sort Code", 
			COLUMN 11, "Activity", 
			COLUMN 20, "Description", 
			COLUMN 41, "Var No.", 
			COLUMN 50, "Cost Amount", 
			COLUMN 71, "Commitment", 
			COLUMN 91, "Total", 
			COLUMN 109, "Budget", 
			COLUMN 122, "Available" 

			PRINT "--------------------------------------------", 
			"--------------------------------------------", 
			"--------------------------------------------" 

		ON EVERY ROW 

			LET cost_jtot = 0 
			LET commit_jtot = 0 
			LET total_jtot = 0 
			LET budget_jtot = 0 
			LET available_jtot = 0 
			LET job_head_flag = 0 
			LET job_tot_print = 0 
			IF ans = "Y" THEN 
				LET job_head_flag = 1 
				LET job_tot_print = 1 
				PRINT "Job:", 
				COLUMN 9, pr_job.job_code, 
				COLUMN 18, ": ", pr_job.title_text 
			END IF 
			DECLARE act_curs CURSOR FOR 
			SELECT * 
			INTO pr_activity.* 
			FROM activity 
			WHERE cmpy_code = pr_job.cmpy_code 
			AND job_code = pr_job.job_code 
			ORDER BY sort_text 
			FOREACH act_curs 
				LET act_head_flag = 0 
				DISPLAY "Activity...", pr_activity.activity_code at 2,5 
				IF ans = "Y" THEN 
					LET act_head_flag = 1 
					PRINT COLUMN 1, pr_activity.sort_text, 
					COLUMN 11, pr_activity.activity_code, 
					COLUMN 20, pr_activity.title_text[1,20], 
					COLUMN 41, pr_activity.var_code; 
				END IF 
				DECLARE ledg_curs CURSOR FOR 
				SELECT * 
				INTO pr_jobledger.* 
				FROM jobledger 
				WHERE cmpy_code = pr_activity.cmpy_code 
				AND job_code = pr_activity.job_code 
				AND var_code = pr_activity.var_code 
				AND activity_code = pr_activity.activity_code 
				AND trans_type_ind <> "SA" AND trans_type_ind <> "CO" 
				ORDER BY trans_date desc 
				LET acti_cost_amt_tot = 0 
				LET activity_total = 0 
				LET available_tot = 0 
				FOREACH ledg_curs 
					IF job_head_flag = 0 THEN 
						LET job_head_flag = 1 
						LET job_tot_print = 1 
						PRINT "Job:", 
						COLUMN 9, pr_job.job_code, 
						COLUMN 18, ": ", pr_job.title_text 
					END IF 
					IF act_head_flag = 0 THEN 
						LET act_head_flag = 1 
						PRINT COLUMN 1, pr_activity.sort_text, 
						COLUMN 11, pr_activity.activity_code, 
						COLUMN 20, pr_activity.title_text[1,20], 
						COLUMN 41, pr_activity.var_code; 
					END IF 
					IF pr_jobledger.trans_amt IS NOT NULL THEN 
						LET acti_cost_amt_tot = 
						acti_cost_amt_tot + pr_jobledger.trans_amt 
					END IF 
				END FOREACH 
				CALL commit_calc(pr_activity.*) RETURNING total_commit_amt,print_flag 
				IF print_flag = 1 THEN 
					IF job_head_flag = 0 THEN 
						LET job_head_flag = 1 
						LET job_tot_print = 1 
						PRINT "Job:", COLUMN 9, pr_job.job_code, 
						COLUMN 18, ": ", pr_job.title_text 
					END IF 
					IF act_head_flag = 0 THEN 
						LET act_head_flag = 1 
						PRINT COLUMN 1, pr_activity.sort_text, 
						COLUMN 11, pr_activity.activity_code, 
						COLUMN 20, pr_activity.title_text[1,20], 
						COLUMN 41, pr_activity.var_code; 
					END IF 
				END IF 
				IF act_head_flag = 1 OR 
				ans = "Y" THEN 
					LET activity_total = acti_cost_amt_tot + total_commit_amt 
					LET available_tot = pr_activity.bdgt_cost_amt - activity_total 
					PRINT COLUMN 48, acti_cost_amt_tot USING "----------.--", 
					COLUMN 69, total_commit_amt USING "----------.--", 
					COLUMN 84, activity_total USING "----------.--", 
					COLUMN 101, pr_activity.bdgt_cost_amt 
					USING "----,---,---.--", 
					COLUMN 117, available_tot USING "----,---,---.--" 
					LET cost_jtot = cost_jtot + acti_cost_amt_tot 
					LET commit_jtot = commit_jtot + total_commit_amt 
					LET total_jtot = total_jtot + activity_total 
					LET budget_jtot = budget_jtot + pr_activity.bdgt_cost_amt 
					LET available_jtot = available_jtot + available_tot 
				END IF 
			END FOREACH 

		AFTER GROUP OF pr_job.job_code 
			IF job_tot_print = 1 THEN 
				SKIP 1 LINES 
				PRINT COLUMN 1, "Job Totals: ", 
				COLUMN 48, cost_jtot USING "----------.--", 
				COLUMN 69, commit_jtot USING "----------.--", 
				COLUMN 84, total_jtot USING "----------.--", 
				COLUMN 101, budget_jtot USING "----,---,---.--", 
				COLUMN 117, available_jtot USING "----,---,---.--" 
				SKIP 1 LINES 
			END IF 

		ON LAST ROW 
			PRINT 

			PRINT COLUMN 1, "Selection Criteria : ", 
			COLUMN 25, where_part clipped wordwrap right margin 120 
			SKIP 2 LINES 
			LET rpt_pageno = pageno 
			LET rpt_length = 66 
			PRINT COLUMN 50, "******** END OF REPORT JR3 ********" 

END REPORT 
