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

	Source code beautified by beautify.pl on 2020-01-02 19:48:23	$Id: $
}


#GLOBALS "../common/glob_GLOBALS.4gl"

{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module JRB.4gl Job Summary Report

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "J_JM_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl" 

#Module Scope Variables
DEFINE 
tot_purch_costs, 
gtot_purch_costs LIKE poaudit.line_total_amt , 
tot_est_costs, 
gtot_est_costs LIKE activity.act_cost_amt, 
variance, 
costs_movement, 
month_movement, 
tot_variance, 
gtot_variance LIKE activity.act_cost_amt, 
tot_bdgt_cost_qty, gtot_bdgt_cost_qty LIKE activity.bdgt_cost_qty, 
tot_bdgt_cost_amt, gtot_bdgt_cost_amt LIKE activity.bdgt_cost_amt, 
tot_hours_qty, gtot_hours_qty LIKE activity.act_cost_qty, 
tot_act_cost_amt, gtot_act_cost_amt LIKE activity.act_cost_amt, 
tot_cost_movement, gtot_cost_movement LIKE activity.est_cost_amt, 
tot_month_movement, gtot_month_movement LIKE activity.est_cost_amt, 
tot_baltocomp_amtl, gtot_baltocomp_amtl LIKE activity.bdgt_cost_amt, 
pr_report_move_type CHAR(1), 
pr_hours_qty LIKE ts_detail.dur_qty, 
pr_resp_name_text LIKE responsible.name_text, 
pr_job RECORD LIKE job.*, 
pr_customer RECORD LIKE customer.*, 
pr_user_scan_code LIKE kandoouser.acct_mask_code, 
pr_jobtype RECORD LIKE jobtype.*, 
pr_rec_kandoouser RECORD LIKE kandoouser.* 

MAIN 
	#Initial UI Init
	CALL setModuleId("JRB") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	CALL user_security(glob_rec_kandoouser.cmpy_code, glob_rec_kandoouser.sign_on_code) 

	RETURNING pr_rec_kandoouser.acct_mask_code, 
	pr_user_scan_code 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN "1" #UI/MENU Mode 
			OPEN WINDOW J131 with FORM "J131" -- alch kd-747 
			CALL winDecoration_j("J131") -- alch kd-747
 
			MENU " Contract Status Report" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","JRB","menu-contract_status_report-1") -- alch kd-506
 
				ON ACTION "WEB-HELP" -- albo kd-373 
					CALL onlinehelp(getmoduleid(),null)
					 
				ON ACTION "REPORT INTERIM" --COMMAND "Interim" " Generate interim REPORT" 
					LET pr_report_move_type = "I" 
					CALL rpt_rmsreps_reset(NULL) 
					CALL JRB_rpt_process(JRB_rpt_query()) 

				ON ACTION "REPORT MONTHLY" --COMMAND "Monthly" " Generate monthly REPORT" 
					LET pr_report_move_type = "M" 
					CALL rpt_rmsreps_reset(NULL) 
					CALL JRB_rpt_process(JRB_rpt_query()) 

				ON ACTION "Print Manager"		#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "CANCEL" --COMMAND KEY("E",interrupt)"Exit" " Exit TO menus" 
					EXIT MENU 

			END MENU 
			CLOSE WINDOW J131 

		WHEN "2" #Background Process with rmsreps.report_code
			CALL JRB_rpt_process(NULL)  

		WHEN "3" #Only create query-where-part
			OPEN WINDOW J131 with FORM "J131" 
			CALL winDecoration_j("J131") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(JRB_rpt_query()) #save where clause in env 
			CLOSE WINDOW J131 
			
		WHEN "4" #Background Process with SQL WHERE ARGUMENT
			CALL JRB_rpt_process(get_url_sel_text())
	END CASE
END MAIN 


FUNCTION JRB_rpt_query()
	DEFINE l_where_text STRING
	DEFINE l_msgresp LIKE language.yes_flag
 
	LET l_msgresp = kandoomsg("U",1001,"") 
	#1001 "Enter Selection Criteria; OK TO Continue"
	CONSTRUCT BY NAME l_where_text ON 
	job.job_code, 
	job.title_text, 
	job.type_code, 
	job.cust_code, 
	customer.name_text, 
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
	job.resp_code 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","JRB","const-job_job_code-7") -- alch kd-506 
		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (control-b) 
			CASE 
				WHEN infield (job_code) 
					LET pr_job.job_code = showujobs(glob_rec_kandoouser.cmpy_code, pr_user_scan_code) 
					SELECT title_text INTO pr_job.title_text FROM job 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND job_code = pr_job.job_code 
					DISPLAY BY NAME pr_job.job_code, pr_job.title_text 

					NEXT FIELD type_code 
				WHEN infield (type_code) 
					LET pr_job.type_code = show_type(glob_rec_kandoouser.cmpy_code) 
					SELECT * INTO pr_jobtype.* FROM jobtype 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND type_code = pr_job.type_code 
					DISPLAY BY NAME pr_job.type_code, pr_jobtype.type_text 

					NEXT FIELD cust_code 
				WHEN infield (cust_code) 
					LET pr_job.cust_code = show_clnt(glob_rec_kandoouser.cmpy_code) 
					SELECT name_text INTO pr_customer.name_text FROM customer 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cust_code = pr_job.cust_code 
					DISPLAY BY NAME pr_job.cust_code, pr_customer.name_text 

					NEXT FIELD est_start_date 
				WHEN infield(resp_code) 
					LET pr_job.resp_code = show_resp(glob_rec_kandoouser.cmpy_code) 
					SELECT name_text INTO pr_resp_name_text FROM responsible 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND resp_code = pr_job.resp_code 
					DISPLAY BY NAME pr_job.resp_code 

					DISPLAY pr_resp_name_text TO resp_name_text 

					NEXT FIELD internal_flag 
			END CASE 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL 
	ELSE
		LET glob_rec_rpt_selector.ref1_ind = pr_report_move_type
		RETURN l_where_text	
	END IF 
 
END FUNCTION 


FUNCTION JRB_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
 
	DEFINE 
--	query_text CHAR(2500), 
	pr_job RECORD LIKE job.*, 
	pr_customer RECORD LIKE customer.*, 
	pr_poaudit RECORD LIKE poaudit.*, 
	pr_purchdetl RECORD LIKE purchdetl.*, 
	pr_activity RECORD LIKE activity.*, 
	pr_order_date LIKE purchhead.order_date, 
	pr_curr_code LIKE purchhead.curr_code, 
	po_cost_amt LIKE poaudit.line_total_amt, 
	pr_conv_qty LIKE purchhead.conv_qty 

	LET tot_bdgt_cost_qty = 0 
	LET tot_bdgt_cost_amt = 0 
	LET tot_hours_qty = 0 
	LET tot_act_cost_amt = 0 
	LET tot_purch_costs = 0 
	LET tot_est_costs = 0 
	LET tot_baltocomp_amtl = 0 
	LET tot_variance = 0 
	LET tot_cost_movement = 0 
	LET tot_month_movement = 0 


	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"JRB_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT JRB_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("JRB_rpt_list")].sel_text
	#------------------------------------------------------------

	LET pr_report_move_type = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref1_ind 

	LET l_query_text = "SELECT unique job.*, customer.*, activity.* ", 
	" FROM job, customer, activity ", 
	" WHERE ",p_where_text clipped," ", 
	" AND job.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
	" AND customer.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
	" AND customer.cust_code = job.cust_code ", 
	" AND activity.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	" AND activity.job_code = job.job_code ", 
	" ORDER BY job.job_code, activity.priority_ind,", 
	" activity.report_text, activity.var_code,", 
	" activity.activity_code " 
	
	PREPARE s_job FROM l_query_text 
	DECLARE c_job CURSOR FOR s_job
	 
	FOREACH c_job INTO pr_job.*, pr_customer.*, pr_activity.* 
		LET po_cost_amt = 0 
		DECLARE pocurs CURSOR FOR 
		SELECT purchdetl.*, 
		purchhead.order_date, 
		purchhead.curr_code, 
		purchhead.conv_qty 
		FROM purchdetl, purchhead 
		WHERE purchdetl.cmpy_code = pr_activity.cmpy_code 
		AND purchdetl.job_code = pr_activity.job_code 
		AND purchdetl.var_num = pr_activity.var_code 
		AND purchdetl.activity_code = pr_activity.activity_code 
		AND purchhead.cmpy_code = purchdetl.cmpy_code 
		AND purchhead.order_num = purchdetl.order_num 
		FOREACH pocurs INTO pr_purchdetl.*, 
			pr_order_date, 
			pr_curr_code, 
			pr_conv_qty 
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
			IF pr_poaudit.line_total_amt IS NULL THEN 
				LET pr_poaudit.line_total_amt = 0 
			END IF 
			IF pr_conv_qty IS NULL OR pr_conv_qty = 0 THEN 
				LET pr_poaudit.line_total_amt = 
				conv_currency(pr_poaudit.line_total_amt, 
				glob_rec_kandoouser.cmpy_code, 
				pr_curr_code, 
				"F", 
				pr_order_date, 
				"B") 
			ELSE 
				LET pr_poaudit.line_total_amt = pr_poaudit.line_total_amt	/ pr_conv_qty 
			END IF 
			LET po_cost_amt = po_cost_amt + pr_poaudit.line_total_amt 
		END FOREACH 
		
		SELECT sum(dur_qty) INTO pr_hours_qty FROM ts_detail 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND job_code = pr_activity.job_code 
		AND var_code = pr_activity.var_code 
		AND activity_code = pr_activity.activity_code 
		AND post_flag = "Y" 
		IF pr_hours_qty IS NULL THEN 
			LET pr_hours_qty = 0 
		END IF

		#---------------------------------------------------------
		OUTPUT TO REPORT JRB_rpt_list(l_rpt_idx,
		pr_job.*, 
		pr_customer.name_text, 
		po_cost_amt, 
		pr_activity.*, 
		pr_hours_qty)  
		IF NOT rpt_int_flag_handler2("Job/Activity:",pr_job.title_text, pr_activity.title_text,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------	
		 
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT JRB_rpt_list
	CALL rpt_finish("JRB_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 


REPORT JRB_rpt_list(p_rpt_idx,pr_job, 
	cust_name, 
	po_cost_amt, 
	pr_activity, 
	pr_hours_qty) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE 
	pr_job RECORD LIKE job.*, 
	pr_activity RECORD LIKE activity.*, 
	pr_job_desc RECORD LIKE job_desc.*, 
	po_cost_amt LIKE poaudit.line_total_amt, 
	cust_name LIKE customer.name_text, 
	baltocomp_amtl LIKE activity.bdgt_cost_amt, 
	heading_reqd CHAR(1), 
	movement_found SMALLINT, 
	prev_total_cost LIKE activity.act_cost_amt, 
	prev_month_cost LIKE activity.act_cost_amt, 
	pr_var_code LIKE activity.var_code, 
	pr_priority_ind LIKE activity.priority_ind, 
	pr_bdgt_cost_amt, 
	pr_retain_amt, 
	pr_act_bill_amt, 
	pr_act_cost_amt, 
	pr_contract_value, 
	pr_total_contr, 
	pr_orig_contr, 
	pr_retention, 
	pr_invoiced, 
	pr_est_total_costs, 
	pr_total_costs LIKE activity.bdgt_cost_amt, 
	pr_hours_qty LIKE ts_detail.dur_qty, 
	pa_line array[4] OF CHAR(143) 

	OUTPUT 

	ORDER external BY pr_job.job_code, 
	pr_activity.priority_ind, 
	pr_activity.report_text, 
	pr_activity.var_code, 
	pr_activity.activity_code 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  
	
			LET heading_reqd = "Y"
			 
		BEFORE GROUP OF pr_job.job_code 
			LET gtot_bdgt_cost_qty = 0 
			LET gtot_bdgt_cost_amt = 0 
			LET gtot_hours_qty = 0 
			LET gtot_act_cost_amt = 0 
			LET gtot_purch_costs = 0 
			LET gtot_est_costs = 0 
			LET gtot_baltocomp_amtl = 0 
			LET gtot_variance = 0 
			LET gtot_cost_movement = 0 
			LET gtot_month_movement = 0 
			SKIP TO top OF PAGE 
			PRINT COLUMN 01, "Customer: ", pr_job.cust_code, 
			COLUMN 25, cust_name 
			SKIP 1 line 
			PRINT COLUMN 01, "Job: ", pr_job.job_code, 
			COLUMN 25, pr_job.title_text
			 
		ON EVERY ROW 
			NEED 2 LINES 
			IF heading_reqd = "Y" THEN 
				LET heading_reqd = "N" 
				NEED 7 LINES 
				SKIP 1 LINES 
				PRINT COLUMN 50, "PLANNED", 
				COLUMN 64, "PURCHASE", 
				COLUMN 77, "INCURRED", 
				COLUMN 92, "BALANCE", 
				COLUMN 126, "REPORT" 
				PRINT COLUMN 46, "---------------", 
				COLUMN 66, "ORDER", 
				COLUMN 74, "---------------", 
				COLUMN 95, "TO", 
				COLUMN 104, "TOTAL", 
				COLUMN 115, "TOTAL", 
				COLUMN 127, "COST"; 
				IF pr_report_move_type = "M" THEN 
					PRINT COLUMN 137, "PERIOD" 
				ELSE 
					PRINT COLUMN 137, " " 
				END IF 
				PRINT COLUMN 01, "VAR", 
				COLUMN 06, "ACTIVITY", 
				COLUMN 15, "DESCRIPTION", 
				COLUMN 46, "HOURS", 
				COLUMN 56, "COSTS", 
				COLUMN 66, "COSTS", 
				COLUMN 74, "HOURS", 
				COLUMN 84, "COSTS", 
				COLUMN 92, "COMPLETE", 
				COLUMN 104, "COSTS", 
				COLUMN 114, "VARIANCE", 
				COLUMN 125, "MOVEMENT"; 
				IF pr_report_move_type = "M" THEN 
					PRINT COLUMN 136, "MOVEMENT" 
				ELSE 
					PRINT COLUMN 137, " " 
				END IF 
				PRINT COLUMN 01, pa_line[3] 
			END IF 
			IF pr_activity.unit_code != "HRS" THEN 
				LET pr_activity.bdgt_cost_qty = 0 
				LET pr_hours_qty = 0 
			END IF 
			IF pr_activity.bdgt_cost_amt IS NULL THEN 
				LET pr_activity.bdgt_cost_amt = 0 
			END IF 
			IF pr_activity.act_cost_amt IS NULL THEN 
				LET pr_activity.act_cost_amt = 0 
			END IF 
			IF po_cost_amt IS NULL THEN 
				LET po_cost_amt = 0 
			END IF 
			IF pr_activity.priority_ind = "C" THEN 
				LET baltocomp_amtl = 0 
				LET variance = 0 
				LET costs_movement = 0 
				LET month_movement = 0 
				LET pr_est_total_costs = 0 
			ELSE 
				IF po_cost_amt > pr_activity.bdgt_cost_amt THEN 
					LET baltocomp_amtl = po_cost_amt 
				ELSE 
					LET baltocomp_amtl = pr_activity.bdgt_cost_amt 
				END IF 
				LET baltocomp_amtl = baltocomp_amtl - pr_activity.act_cost_amt 
				IF pr_activity.finish_flag = "Y" THEN 
					LET baltocomp_amtl = 0 
				ELSE 
					IF baltocomp_amtl < 0 THEN 
						LET baltocomp_amtl = 0 
					END IF 
					IF pr_activity.baltocomp_amt IS NOT NULL THEN 
						LET baltocomp_amtl = baltocomp_amtl + pr_activity.baltocomp_amt 
					END IF 
				END IF 
				LET pr_est_total_costs = baltocomp_amtl + pr_activity.act_cost_amt 
				LET variance = pr_activity.bdgt_cost_amt - pr_est_total_costs 
				LET movement_found = false 
				LET prev_total_cost = NULL 
				LET prev_month_cost = NULL 
				SELECT total_cost_amt, total_month_amt 
				INTO prev_total_cost, prev_month_cost 
				FROM jrb_movement 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND job_code = pr_activity.job_code 
				AND var_code = pr_activity.var_code 
				AND activity_code = pr_activity.activity_code 
				IF status = notfound THEN 
					LET prev_total_cost = 0 
					LET prev_month_cost = 0 
				ELSE 
					LET movement_found = true 
					IF prev_total_cost IS NULL THEN 
						LET prev_total_cost = 0 
					END IF 
					IF prev_month_cost IS NULL THEN 
						LET prev_month_cost = 0 
					END IF 
				END IF 
				LET costs_movement = pr_est_total_costs - prev_total_cost 
				LET month_movement = pr_est_total_costs - prev_month_cost 
			END IF 
			IF pr_est_total_costs > 0 OR pr_activity.finish_flag != "Y" THEN 
				PRINT COLUMN 01, pr_activity.var_code USING "##&", 
				COLUMN 06, pr_activity.activity_code, 
				COLUMN 15, pr_activity.title_text, 
				COLUMN 46, pr_activity.bdgt_cost_qty USING "####", 
				COLUMN 51, pr_activity.bdgt_cost_amt USING "---------#", 
				COLUMN 62, po_cost_amt USING "---------#", 
				COLUMN 74, pr_hours_qty USING "####", 
				COLUMN 79, pr_activity.act_cost_amt USING "---------#", 
				COLUMN 90, baltocomp_amtl USING "---------&", 
				COLUMN 101, pr_est_total_costs USING "---------#", 
				COLUMN 112, variance USING "---------#", 
				COLUMN 123, costs_movement USING "---------#"; 
				IF pr_report_move_type = "M" THEN 
					PRINT COLUMN 134, month_movement USING "---------#" 
				ELSE 
					PRINT COLUMN 137, " " 
				END IF 
			END IF 
			LET tot_bdgt_cost_qty = tot_bdgt_cost_qty 
			+ pr_activity.bdgt_cost_qty 
			LET tot_bdgt_cost_amt = tot_bdgt_cost_amt 
			+ pr_activity.bdgt_cost_amt 
			LET tot_purch_costs = tot_purch_costs + po_cost_amt 
			LET tot_hours_qty = tot_hours_qty + pr_hours_qty 
			LET tot_act_cost_amt = tot_act_cost_amt + pr_activity.act_cost_amt 
			LET tot_baltocomp_amtl = tot_baltocomp_amtl + baltocomp_amtl 
			LET tot_est_costs = tot_est_costs + pr_est_total_costs 
			LET tot_variance = tot_variance + variance 
			LET tot_cost_movement = tot_cost_movement + costs_movement 
			LET tot_month_movement = tot_month_movement + month_movement 
			WHENEVER ERROR CONTINUE 
			IF movement_found THEN 
				IF pr_report_move_type = "M" THEN 
					UPDATE jrb_movement 
					SET total_cost_amt = pr_est_total_costs, 
					total_month_amt = pr_est_total_costs 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND job_code = pr_activity.job_code 
					AND var_code = pr_activity.var_code 
					AND activity_code = pr_activity.activity_code 
				ELSE 
					UPDATE jrb_movement 
					SET total_cost_amt = pr_est_total_costs 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND job_code = pr_activity.job_code 
					AND var_code = pr_activity.var_code 
					AND activity_code = pr_activity.activity_code 
				END IF 
			ELSE 
				INSERT INTO jrb_movement VALUES (glob_rec_kandoouser.cmpy_code, 
				pr_activity.job_code, 
				pr_activity.var_code, 
				pr_activity.activity_code, 
				pr_est_total_costs, 
				pr_est_total_costs) 
			END IF 
			WHENEVER ERROR stop 
			LET gtot_bdgt_cost_qty = gtot_bdgt_cost_qty + tot_bdgt_cost_qty 
			LET gtot_bdgt_cost_amt = gtot_bdgt_cost_amt + tot_bdgt_cost_amt 
			LET gtot_purch_costs = gtot_purch_costs + tot_purch_costs 
			LET gtot_hours_qty = gtot_hours_qty + tot_hours_qty 
			LET gtot_act_cost_amt = gtot_act_cost_amt + tot_act_cost_amt 
			LET gtot_baltocomp_amtl = gtot_baltocomp_amtl + tot_baltocomp_amtl 
			LET gtot_est_costs = gtot_est_costs + tot_est_costs 
			LET gtot_variance = gtot_variance + tot_variance 
			LET gtot_cost_movement = gtot_cost_movement + tot_cost_movement 
			LET gtot_month_movement = gtot_month_movement + tot_month_movement 
			LET tot_bdgt_cost_qty = 0 
			LET tot_bdgt_cost_amt = 0 
			LET tot_hours_qty = 0 
			LET tot_act_cost_amt = 0 
			LET tot_purch_costs = 0 
			LET tot_est_costs = 0 
			LET tot_baltocomp_amtl = 0 
			LET tot_variance = 0 
			LET tot_cost_movement = 0 
			LET tot_month_movement = 0
			 
		AFTER GROUP OF pr_activity.priority_ind 
			IF pr_activity.priority_ind <> "C" 
			OR pr_activity.priority_ind IS NULL THEN 
				NEED 2 LINES 
				PRINT COLUMN 46, "----", 
				COLUMN 51, "----------", 
				COLUMN 62, "----------", 
				COLUMN 74, "----", 
				COLUMN 79, "----------", 
				COLUMN 90, "----------", 
				COLUMN 101, "----------", 
				COLUMN 112, "----------", 
				COLUMN 123, "----------"; 
				IF pr_report_move_type = "M" THEN 
					PRINT COLUMN 134, "----------" 
				ELSE 
					PRINT COLUMN 137, " " 
				END IF 
				PRINT COLUMN 35, "COST TOTAL ", 
				COLUMN 46, gtot_bdgt_cost_qty USING "###&", 
				COLUMN 51, gtot_bdgt_cost_amt USING "---------&", 
				COLUMN 62, gtot_purch_costs USING "---------&", 
				COLUMN 74, gtot_hours_qty USING "###&", 
				COLUMN 79, gtot_act_cost_amt USING "---------&", 
				COLUMN 90, gtot_baltocomp_amtl USING "---------&", 
				COLUMN 101, gtot_est_costs USING "---------&", 
				COLUMN 112, gtot_variance USING "---------&", 
				COLUMN 123, gtot_cost_movement USING "---------&"; 
				IF pr_report_move_type = "M" THEN 
					PRINT COLUMN 134, gtot_month_movement USING "---------#" 
				ELSE 
					PRINT COLUMN 137, " " 
				END IF 
				SKIP 1 LINES 
			END IF 
			
		AFTER GROUP OF pr_job.job_code 
			NEED 4 LINES 
			PRINT COLUMN 46, "----", 
			COLUMN 51, "----------", 
			COLUMN 62, "----------", 
			COLUMN 74, "----", 
			COLUMN 79, "----------", 
			COLUMN 90, "----------", 
			COLUMN 101, "----------", 
			COLUMN 112, "----------", 
			COLUMN 123, "----------"; 
			IF pr_report_move_type = "M" THEN 
				PRINT COLUMN 134, "----------" 
			ELSE 
				PRINT COLUMN 137, " " 
			END IF 
			PRINT COLUMN 36, "JOB TOTAL ", 
			COLUMN 46, gtot_bdgt_cost_qty USING "###&", 
			COLUMN 51, gtot_bdgt_cost_amt USING "---------&", 
			COLUMN 62, gtot_purch_costs USING "---------&", 
			COLUMN 74, gtot_hours_qty USING "###&", 
			COLUMN 79, gtot_act_cost_amt USING "---------&", 
			COLUMN 90, gtot_baltocomp_amtl USING "---------&", 
			COLUMN 101, gtot_est_costs USING "---------&", 
			COLUMN 112, gtot_variance USING "---------&", 
			COLUMN 123, gtot_cost_movement USING "---------&"; 
			IF pr_report_move_type = "M" THEN 
				PRINT COLUMN 134, gtot_month_movement USING "---------#" 
			ELSE 
				PRINT COLUMN 137, " " 
			END IF 
			LET pr_bdgt_cost_amt = 0 
			LET pr_retain_amt = 0 
			LET pr_act_bill_amt = 0 
			LET pr_act_cost_amt = 0 
			LET pr_est_total_costs = 0 
			LET pr_contract_value = 0 
			LET pr_total_contr = 0 
			LET pr_orig_contr = 0 
			LET pr_retention = 0 
			LET pr_invoiced = 0 
			LET pr_total_costs = 0 
			DECLARE c_activity CURSOR FOR 
			SELECT var_code, priority_ind, bdgt_cost_amt, retain_amt, 
			act_bill_amt, act_cost_amt 
			FROM activity 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND job_code = pr_job.job_code 
			FOREACH c_activity INTO pr_var_code, 
				pr_priority_ind, 
				pr_bdgt_cost_amt, 
				pr_retain_amt, 
				pr_act_bill_amt, 
				pr_act_cost_amt 
				IF pr_bdgt_cost_amt IS NULL THEN 
					LET pr_bdgt_cost_amt = 0 
				END IF 
				IF pr_retain_amt IS NULL THEN 
					LET pr_retain_amt = 0 
				END IF 
				IF pr_act_bill_amt IS NULL THEN 
					LET pr_act_bill_amt = 0 
				END IF 
				IF pr_act_cost_amt IS NULL THEN 
					LET pr_act_cost_amt = 0 
				END IF 
				LET pr_contract_value = pr_contract_value + pr_bdgt_cost_amt 
				IF pr_priority_ind = "C" THEN 
					LET pr_total_contr = pr_total_contr + pr_bdgt_cost_amt 
					IF pr_var_code = 0 THEN 
						LET pr_orig_contr = pr_orig_contr + pr_bdgt_cost_amt 
					END IF 
				END IF 
				LET pr_retention = pr_retention + pr_retain_amt 
				LET pr_invoiced = pr_invoiced + pr_act_bill_amt 
				LET pr_total_costs = pr_total_costs + pr_act_cost_amt 
			END FOREACH 
			SKIP 1 line 
			PRINT COLUMN 01, "SUMMARY" 
			PRINT COLUMN 01, "Customer: ", pr_job.cust_code, 
			COLUMN 25, cust_name 
			SKIP 1 line 
			PRINT COLUMN 01, "Job: ", pr_job.job_code, 
			COLUMN 25, pr_job.title_text 
			SKIP 1 line 
			PRINT COLUMN 02, "Current Contract Value", 
			COLUMN 50, pr_contract_value USING "-----------&" 
			PRINT COLUMN 02, "Current Planned Contributions", 
			COLUMN 50, pr_total_contr USING "-----------&" 

			PRINT COLUMN 02, "Current Estimated Contributions", 
			COLUMN 50, pr_total_contr + gtot_variance USING "-----------&" 

			PRINT COLUMN 02, "Original Planned Contributions", 
			COLUMN 50, pr_orig_contr USING "-----------&" 

			PRINT COLUMN 02, "Retention Value", 
			COLUMN 50, pr_retention USING "-----------&" 
			IF pr_contract_value = 0 OR pr_retention = 0 THEN 
				PRINT COLUMN 02, "Retention Percentage" 
			ELSE 
				PRINT COLUMN 02, "Retention Percentage", 
				COLUMN 56, (pr_retention / pr_contract_value) * 100 
				USING "---&.&&", 
				COLUMN 61, "%" 
			END IF 
			SKIP 1 line 
			PRINT COLUMN 02, "Invoiced TO Date", 
			COLUMN 50, pr_invoiced USING "-----------&" 
			IF pr_contract_value = 0 OR pr_invoiced = 0 THEN 
				PRINT COLUMN 02, "Contract Value Invoiced", 
				COLUMN 61, "0%" 
			ELSE 
				PRINT COLUMN 02, "Contract Value Invoiced ", 
				COLUMN 55, (pr_invoiced / pr_contract_value) * 100 
				USING "---&.&&", 
				COLUMN 62, "%" 
			END IF 
			PRINT COLUMN 02, "Total Cost Incurred", 
			COLUMN 50, pr_total_costs USING "-----------&" 
			SKIP 1 line 
			PRINT COLUMN 02, "Commencement Date", 
			COLUMN 50, pr_job.act_start_date USING "dd/mm/yyyy" 
			PRINT COLUMN 02, "Original Completion Date", 
			COLUMN 50, pr_job.est_end_date USING "dd/mm/yyyy" 
			PRINT COLUMN 02, "Revised Completion Date", 
			COLUMN 50, pr_job.act_end_date USING "dd/mm/yyyy" 
			SKIP 2 LINES 
			DECLARE c_2 CURSOR FOR 
			SELECT * FROM job_desc 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND job_code = pr_job.job_code 
			ORDER BY seq_num 
			FOREACH c_2 INTO pr_job_desc.* 
				PRINT COLUMN 10, pr_job_desc.desc_text 
			END FOREACH 
			
		ON LAST ROW 
			SKIP 3 line 
			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	
		
END REPORT 