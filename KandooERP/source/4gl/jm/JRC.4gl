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

# Purpose - Activity Transaction Report By Sort Code


GLOBALS 
	DEFINE 
	pr_job RECORD LIKE job.*, 
	pr_activity RECORD LIKE activity.*, 
	where_part_2 CHAR(800), 
	where_part CHAR(800), 
	query_text CHAR(1600), 
	pr_company RECORD LIKE company.*, 
	pr_customer RECORD LIKE customer.*, 
	pr_jmparms RECORD LIKE jmparms.*, 
	rt_commit_amt, rt_cost_amt, rt_total_amt, 
	activity_total, acti_cost_amt_tot, commit_amt, 
	total_commit_amt, job_cost_amt, job_commit_amt, 
	job_total,sort_cost_amt,sort_commit_amt, 
	sort_total LIKE activity.act_bill_amt, 
	pr_output CHAR(20), 
	rpt_pageno LIKE rmsreps.page_num, 
	rpt_wid LIKE rmsreps.report_width_num, 
	rpt_length LIKE rmsreps.page_length_num, 
	rpt_note LIKE rmsreps.report_text, 
	pr_zero_ind SMALLINT, 
	pv_type_code LIKE job.type_code, 
	pv_wildcard CHAR(1) 
END GLOBALS 

MAIN 
	LET rt_cost_amt = 0 
	LET rt_commit_amt = 0 
	LET rt_total_amt = 0 

	#Initial UI Init
	CALL setModuleId("JRC") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 


	SELECT jmparms.* INTO pr_jmparms.* FROM jmparms 
	WHERE jmparms.cmpy_code = glob_rec_kandoouser.cmpy_code AND 
	jmparms.key_code = "1" 

	SELECT * INTO pr_company.* FROM company 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF status = notfound THEN 
		
		CALL fgl_winmessage("ERROR",kandoomsg2("J",1501,""),"ERROR") #" Job Management Parameters NOT found - Refer Menu JZP " 
		EXIT program 
	END IF 


	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN "1" #UI/MENU Mode 	
			OPEN WINDOW J160 with FORM "J160" -- alch kd-747 
			CALL winDecoration_j("J160") -- alch kd-747 
		
			MENU " Activity Transaction" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","JRC","menu-activity_transaction-1") -- alch kd-506
					CALL rpt_rmsreps_reset(NULL) 
					CALL JRC_rpt_process(JRC_rpt_query()) 
		 
				ON ACTION "WEB-HELP" -- albo kd-373 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "REPORT" --COMMAND "Report" " SELECT criteria AND PRINT REPORT"
					CALL rpt_rmsreps_reset(NULL) 
					CALL JRC_rpt_process(JRC_rpt_query()) 
		
				COMMAND "Message" " Enter REPORT name TO appear on heading" --         prompt " Report text." FOR rpt_note -- albo
					LET rpt_note = promptInput(" Report text.","",60) -- albo 
		
				ON ACTION "Print Manager" 		#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "CANCEL" --COMMAND KEY(interrupt,"E")"Exit" " RETURN TO the menus" 
					EXIT MENU 
		
			END MENU
			 
			CLOSE WINDOW J160 
	 
		WHEN "2" #Background Process with rmsreps.report_code
			CALL JRC_rpt_process(NULL)  

		WHEN "3" #Only create query-where-part
			OPEN WINDOW J160 with FORM "J160" 
			CALL winDecoration_j("J160") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(JRC_rpt_query()) #save where clause in env 
			CLOSE WINDOW J160 
			
		WHEN "4" #Background Process with SQL WHERE ARGUMENT
			CALL JRC_rpt_process(get_url_sel_text())
	END CASE			
END MAIN 


FUNCTION JRC_rpt_query() 
	DEFINE l_where_text STRING 
	CLEAR FORM 
	LET msgresp = kandoomsg("U",1001,"") # Enter Selection Criteria - ESC TO Continue"

	LET pv_type_code = NULL 
	LET pv_wildcard = "N"
	 
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
			CALL publish_toolbar("kandoo","JRC","const-activity_job_code-5") -- alch kd-506 
		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 
	END CONSTRUCT
	 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF
	 
	OPEN WINDOW j187 with FORM "J187" -- alch kd-747 
	CALL winDecoration_j("J187") -- alch kd-747
 
	CONSTRUCT BY NAME where_part_2 ON 
	jobledger.year_num, 
	jobledger.period_num 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","JRC","const-year_num-2") -- alch kd-506 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 
	END CONSTRUCT 

CLOSE WINDOW J187

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	 
		RETURN NULL
	ELSE

		LET msgresp = kandoomsg("J",1502,"") 
		IF upshift(msgresp) <> "N" THEN 
			LET pr_zero_ind = true 
		ELSE 
			LET pr_zero_ind = false 
		END IF 

		RETURN l_where_text 
	END IF 
END FUNCTION


FUNCTION JRC_rpt_process(p_where_text) 
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

	LET l_rpt_idx = rpt_start(getmoduleid(),"AC1_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT AC1_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AC1_rpt_list")].sel_text
	#------------------------------------------------------------


	LET l_query_text = "SELECT activity.* ", 
	" FROM activity,job,customer,salesperson", 
	" WHERE activity.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	" AND activity.job_code = job.job_code ", 
	" AND job.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "'", 
	" AND customer.cust_code = job.cust_code ", 
	" AND customer.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "'", 
	" AND salesperson.sale_code = job.sale_code ", 
	" AND salesperson.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "'", 
	" AND ",p_where_text clipped," ", 
	" ORDER BY activity.job_code,activity.sort_text,", 
	" activity.activity_code " 

 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF


	 
	PREPARE s_activity FROM query_text 
	DECLARE c_activity CURSOR FOR s_activity 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"JRC_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT JRC_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("JRC_rpt_list")].sel_text
	#------------------------------------------------------------
	
	 
	--DISPLAY "" at 1,1 
	--DISPLAY "Reporting on Job...." at 1,1 
	--DISPLAY " Activity..." at 2,1 
	
	FOREACH c_activity INTO pr_activity.* 
		#---------------------------------------------------------
		OUTPUT TO REPORT JRC_rpt_list(l_rpt_idx,
		pr_activity.*)   
		IF NOT rpt_int_flag_handler2("Job:",pr_activity.job_code, NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------	

	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT JRC_rpt_list
	CALL rpt_finish("JRC_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF	
END FUNCTION 


REPORT JRC_rpt_list(p_rpt_idx,pr_activity)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx] 
	DEFINE 
	pr_activity RECORD LIKE activity.*, 
	pr_poaudit RECORD LIKE poaudit.*, 
	pr_jobledger RECORD LIKE jobledger.*, 
	pr_job RECORD LIKE job.*, 
	pr_jmresource RECORD LIKE jmresource.*, 
	line1, line2 CHAR(132), 
	offset1, offset2 SMALLINT, 
	job_head_flag, sort_head_flag, act_head_flag, 
	job_tot_print, sort_tot_print INTEGER, 
	held_order_num LIKE purchhead.order_num, 
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
	END RECORD 

	OUTPUT 

	ORDER external BY pr_activity.job_code,pr_activity.sort_text, 
	pr_activity.activity_code 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  
	
			PRINT COLUMN 1, "Date", 
			COLUMN 10, "Type", 
			COLUMN 19, "No.", 
			COLUMN 24, "Text", 
			COLUMN 35, "Cost Amount", 
			COLUMN 47, "Posted", 
			COLUMN 54, "Description", 
			COLUMN 87, "Commitments", 
			COLUMN 110, "Total" 
			
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		BEFORE GROUP OF pr_activity.job_code 
			SELECT * INTO pr_job.* 
			FROM job 
			WHERE job_code = pr_activity.job_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET job_head_flag = 0 
			LET job_tot_print = 0 
			IF pr_zero_ind THEN 
				LET job_tot_print = 1 
				LET job_head_flag = 1 
				NEED 5 LINES 
				PRINT "Job :", 
				COLUMN 9, pr_job.job_code, 
				COLUMN 18, ": ", pr_job.title_text 
			END IF 
			LET job_cost_amt = 0 
			LET job_commit_amt = 0 
			LET job_total = 0 
		BEFORE GROUP OF pr_activity.sort_text 
			LET sort_head_flag = 0 
			LET sort_tot_print = 0 
			IF pr_zero_ind THEN 
				LET sort_tot_print = 1 
				LET sort_head_flag = 1 
				NEED 4 LINES 
				PRINT "Sort Code :", pr_activity.sort_text 
			END IF 
			LET sort_cost_amt = 0 
			LET sort_commit_amt = 0 
			LET sort_total = 0 

		ON EVERY ROW 
			LET act_head_flag = 0 
			IF pr_zero_ind THEN 
				LET act_head_flag = 1 
				DISPLAY pr_activity.title_text at 2,20 
				NEED 7 LINES 
				PRINT "Activity :",pr_activity.activity_code," ", 
				pr_activity.title_text," ", 
				"Variation", pr_activity.var_code USING "-------" 
				SKIP 1 line 
			END IF 
			LET query_text = 
			" SELECT * ", 
			" FROM jobledger ", 
			" WHERE cmpy_code = '",pr_activity.cmpy_code,"' ", 
			" AND job_code = '",pr_activity.job_code clipped,"' ", 
			" AND var_code = '",pr_activity.var_code,"' ", 
			" AND activity_code = '",pr_activity.activity_code clipped,"' ", 
			" AND trans_type_ind <> 'SA' ", 
			" AND trans_type_ind <> 'CO' AND ", 
			where_part_2 clipped, 
			" ORDER BY cmpy_code, trans_date " 
			PREPARE s_jobledg FROM query_text 
			DECLARE ledg_curs CURSOR FOR s_jobledg 

			LET acti_cost_amt_tot = 0 
			LET total_commit_amt = 0 
			LET activity_total = 0 
			FOREACH ledg_curs INTO pr_jobledger.* 
				IF job_head_flag = 0 THEN 
					LET job_tot_print = 1 
					LET job_head_flag = 1 
					NEED 5 LINES 
					PRINT "Job :", 
					COLUMN 9, pr_job.job_code, 
					COLUMN 18, ": ", pr_job.title_text 
				END IF 
				IF sort_head_flag = 0 THEN 
					LET sort_tot_print = 1 
					LET sort_head_flag = 1 
					NEED 4 LINES 
					PRINT "Sort Code :", pr_activity.sort_text 
				END IF 
				IF act_head_flag = 0 THEN 
					LET act_head_flag = 1 
					DISPLAY pr_activity.title_text at 2,20 
					NEED 7 LINES 
					PRINT "Activity :",pr_activity.activity_code," ", 
					pr_activity.title_text," ", 
					"Variation", pr_activity.var_code USING "-------" 
					SKIP 1 LINES 
				END IF 
				IF pr_jobledger.trans_amt IS NOT NULL THEN 
					LET acti_cost_amt_tot = 
					acti_cost_amt_tot + pr_jobledger.trans_amt 
				END IF 
				IF pr_jobledger.trans_qty IS NOT NULL THEN 
				END IF 
				IF pr_jobledger.desc_text IS NULL THEN 
					IF pr_jobledger.trans_type_ind = "RE" 
					OR pr_jobledger.trans_type_ind = "TS" THEN 
						SELECT * INTO pr_jmresource.* 
						FROM jmresource 
						WHERE cmpy_code = pr_jobledger.cmpy_code 
						AND res_code = pr_jobledger.trans_source_text 
						LET pr_jobledger.desc_text = pr_jmresource.desc_text 
					END IF 
				END IF 
				IF pr_jobledger.trans_type_ind = "DB" THEN 
					SELECT a.name_text,b.debit_date 
					INTO pr_jobledger.desc_text , 
					pr_jobledger.trans_date 
					FROM vendor a, debithead b 
					WHERE a.cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND b.cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND b.debit_num = pr_jobledger.trans_source_num 
					AND b.vend_code = a.vend_code 
				END IF 
				IF pr_jobledger.trans_type_ind = "VO" THEN 
					SELECT a.name_text,b.vouch_date 
					INTO pr_jobledger.desc_text , 
					pr_jobledger.trans_date 
					FROM vendor a, voucher b 
					WHERE a.cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND b.cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND b.vouch_code = pr_jobledger.trans_source_num 
					AND b.vend_code = a.vend_code 
				END IF 
				PRINT COLUMN 1 , pr_jobledger.trans_date USING "dd/mm/yy", 
				COLUMN 11, pr_jobledger.trans_type_ind, 
				COLUMN 15, pr_jobledger.trans_source_num USING "--------", 
				COLUMN 24, pr_jobledger.trans_source_text, 
				COLUMN 33, pr_jobledger.trans_amt USING "----------.--", 
				COLUMN 49, pr_jobledger.posted_flag, 
				COLUMN 54, pr_jobledger.desc_text 
			END FOREACH 
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
				IF job_head_flag = 0 THEN 
					LET job_tot_print = 1 
					LET job_head_flag = 1 
					NEED 5 LINES 
					PRINT "Job :", 
					COLUMN 9, pr_job.job_code, 
					COLUMN 18, ": ", pr_job.title_text 
				END IF 
				IF sort_head_flag = 0 THEN 
					LET sort_tot_print = 1 
					LET sort_head_flag = 1 
					NEED 4 LINES 
					PRINT "Sort Code :", pr_activity.sort_text 
				END IF 
				IF act_head_flag = 0 THEN 
					LET act_head_flag = 1 
					DISPLAY pr_activity.title_text at 2,20 
					NEED 7 LINES 
					PRINT "Activity :",pr_activity.activity_code," ", 
					pr_activity.title_text," ", 
					"Variation", pr_activity.var_code USING "-------" 
					SKIP 1 LINES 
				END IF 
				IF held_order_num <> pr_purchdetl.order_num THEN 
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
				IF pr_poaudit.order_qty > pr_poaudit.received_qty THEN 
					LET commit_amt = 
					(pr_purchdetl.unit_cost_amt + pr_purchdetl.unit_tax_amt) * 
					(pr_purchdetl.order_qty - pr_purchdetl.received_qty) 
					PRINT COLUMN 1, pr_purchdetl.order_date USING "dd/mm/yy", 
					COLUMN 11, "PO", 
					COLUMN 15, pr_purchdetl.order_num USING "########", 
					COLUMN 24, pr_purchdetl.res_code[1,8], 
					COLUMN 49, pr_purchdetl.posted_flag, 
					COLUMN 54, pr_purchdetl.desc_text[1,30], 
					COLUMN 85, commit_amt USING "----------.--" 
					LET total_commit_amt = total_commit_amt + commit_amt 
				END IF 
			END FOREACH 
			IF act_head_flag = 1 OR 
			pr_zero_ind THEN 
				LET activity_total = acti_cost_amt_tot + total_commit_amt 
				NEED 2 LINES 
				PRINT COLUMN 33, "-------------", 
				COLUMN 85, "-------------", 
				COLUMN 102, "-------------" 
				PRINT COLUMN 33, acti_cost_amt_tot USING "----------.--", 
				COLUMN 85, total_commit_amt USING "----------.--", 
				COLUMN 102, activity_total USING "----------.--" 
				LET sort_cost_amt = sort_cost_amt + acti_cost_amt_tot 
				LET sort_commit_amt = sort_commit_amt + total_commit_amt 
				LET sort_total = sort_total + activity_total 
				LET job_cost_amt = job_cost_amt + acti_cost_amt_tot 
				LET job_commit_amt = job_commit_amt + total_commit_amt 
				LET job_total = job_total + activity_total 
				SKIP 1 line 
			END IF 

		AFTER GROUP OF pr_activity.sort_text 
			IF sort_tot_print = 1 THEN 
				NEED 3 LINES 
				PRINT 
				PRINT COLUMN 33, "=============", 
				COLUMN 85, "=============", 
				COLUMN 102, "=============" 
				PRINT COLUMN 9, "SORT TOTAL", 
				COLUMN 33, sort_cost_amt USING "----------.--", 
				COLUMN 85, sort_commit_amt USING "----------.--", 
				COLUMN 102,sort_total USING "----------.--" 
				SKIP 1 line 
			END IF 
		AFTER GROUP OF pr_activity.job_code 
			IF job_tot_print = 1 THEN 
				NEED 3 LINES 
				PRINT 
				PRINT COLUMN 33, "=============", 
				COLUMN 85, "=============", 
				COLUMN 102, "=============" 
				PRINT COLUMN 9, "JOB SUMMARY", 
				COLUMN 33, job_cost_amt USING "----------.--", 
				COLUMN 85, job_commit_amt USING "----------.--", 
				COLUMN 102, job_total USING "----------.--" 
				LET rt_cost_amt = rt_cost_amt + job_cost_amt 
				LET rt_commit_amt = rt_commit_amt + job_commit_amt 
				LET rt_total_amt = rt_total_amt + job_total 
			END IF 
			SKIP 1 line 

		ON LAST ROW 
			SKIP 2 LINES 
			PRINT 
			PRINT COLUMN 33, "=============", 
			COLUMN 85, "=============", 
			COLUMN 102, "=============" 
			PRINT COLUMN 9, "REPORT TOTAL", 
			COLUMN 33, rt_cost_amt USING "----------.--", 
			COLUMN 85, rt_commit_amt USING "----------.--", 
			COLUMN 102, rt_total_amt USING "----------.--" 
			SKIP 1 line 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	
			
			LET rt_cost_amt = 0 
			LET rt_commit_amt = 0 
			LET rt_total_amt = 0 
 
END REPORT 
