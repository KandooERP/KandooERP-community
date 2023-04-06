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
# JRH - Detailed Resource Reconciliation Report
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "J_JM_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl" 

#Module Scope Variables


MAIN 
	#Initial UI Init
	CALL setModuleId("JRH") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN "1" #UI/MENU Mode 
			OPEN WINDOW J170 with FORM "J170" -- alch kd-747 
			CALL winDecoration_j("J170") -- alch kd-747 
			MENU " Resource Reconciliation Report" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","JRH","menu-resource_recon_report-1") -- alch kd-506 
					CALL rpt_rmsreps_reset(NULL) 
					CALL JRH_rpt_process(JRH_rpt_query())		
					
				ON ACTION "WEB-HELP" -- albo kd-373 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "REPORT" --COMMAND "Run" " Enter selection criteria AND generate REPORT" 
					CALL rpt_rmsreps_reset(NULL) 
					CALL JRH_rpt_process(JRH_rpt_query())				

				ON ACTION "Print Manager"					#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				COMMAND KEY("E",interrupt)"Exit" " Exit TO menus" 
					EXIT MENU 

			END MENU 
			CLOSE WINDOW J170 

		WHEN "2" #Background Process with rmsreps.report_code
			CALL JRH_rpt_process(NULL)  

		WHEN "3" #Only create query-where-part
			OPEN WINDOW J170 with FORM "J170" 
			CALL winDecoration_j("J170") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(JRH_rpt_query()) #save where clause in env 
			CLOSE WINDOW J170 
			
		WHEN "4" #Background Process with SQL WHERE ARGUMENT
			CALL JRH_rpt_process(get_url_sel_text())
	END CASE 
END MAIN 

FUNCTION JRH_rpt_query() 
	DEFINE l_where_text STRING
	LET msgresp = kandoomsg("U",1001,"")	#1001 Enter Selection Criteria; OK TO Continue

	CONSTRUCT BY NAME l_where_text ON 
	job.job_code, 
	job.title_text, 
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
	job.bill_way_ind, 
	job.acct_code, 
	job.finish_flag, 
	job.report_text, 
	job.resp_code 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","JRH","const-job_job_code-9") -- alch kd-506 
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


FUNCTION JRH_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx] 
	DEFINE 
	pr_inv_date DATE, 
	pr_job RECORD LIKE job.*, 
	pr_cust_name LIKE customer.name_text, 
	pr_jobledger RECORD LIKE jobledger.*, 
	pr_resbill RECORD LIKE resbill.* 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"JRH_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT JRH_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("JRH_rpt_list")].sel_text
	#------------------------------------------------------------

	LET l_query_text = "SELECT unique job.* , customer.name_text ", 
	" FROM job, customer ", 
	" WHERE ",p_where_text clipped, 
	" AND job.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
	" AND customer.cust_code = job.cust_code ", 
	" AND customer.cmpy_code = job.cmpy_code ", 
	" ORDER BY job_code " 
	PREPARE s_job FROM l_query_text 
	DECLARE c_job CURSOR FOR s_job 

	FOREACH c_job INTO pr_job.*, pr_cust_name 

		DECLARE work_c CURSOR FOR 
		SELECT jobledger.*, resbill.*, invoicehead.inv_date 
		FROM jobledger, outer (resbill, invoicehead) 
		WHERE jobledger.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND jobledger.job_code = pr_job.job_code 
		AND jobledger.trans_type_ind NOT in ("SA","CO") 
		AND resbill.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND resbill.job_code = jobledger.job_code 
		AND resbill.var_code = jobledger.var_code 
		AND resbill.activity_code = jobledger.activity_code 
		AND resbill.seq_num = jobledger.seq_num 
		AND resbill.tran_type_ind in ('1','2') 
		AND invoicehead.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND invoicehead.inv_num = resbill.inv_num 
		ORDER BY jobledger.cmpy_code, jobledger.job_code, jobledger.var_code, 
		jobledger.activity_code, jobledger.trans_source_text , 
		jobledger.seq_num
		 
		FOREACH work_c INTO pr_jobledger.*, pr_resbill.*, pr_inv_date
			#---------------------------------------------------------
			OUTPUT TO REPORT JRH_rpt_list(l_rpt_idx,
			pr_job.*, 
			pr_cust_name, 
			pr_jobledger.*, 
			pr_resbill.*, 
			pr_inv_date) 
			IF NOT rpt_int_flag_handler2("Job:",pr_job.job_code ,NULL,l_rpt_idx) THEN
				EXIT FOREACH 
			END IF 
			#---------------------------------------------------------	
		 
		END FOREACH 
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT JRH_rpt_list
	CALL rpt_finish("JRH_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 


REPORT JRH_rpt_list (p_rpt_idx,pr_job, pr_cust_name, pr_jobledger, pr_resbill, pr_inv_date)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx] 
	DEFINE 
	pr_inv_date DATE, 
	pr_job RECORD LIKE job.*, 
	pr_invoicehead RECORD LIKE invoicehead.*, 
	pr_invoicedetl RECORD LIKE invoicedetl.*, 
	pr_cust_name LIKE customer.name_text, 
	pr_jobledger RECORD LIKE jobledger.*, 
	pr_resbill RECORD LIKE resbill.*, 
	pr_resbill_flag SMALLINT, 
	pr_job_tot_trans_amt, 
	pr_act_tot_trans_amt, 
	pr_res_tot_trans_amt, 
	pr_job_tot_charge_amt, 
	pr_act_tot_charge_amt, 
	pr_res_tot_charge_amt, 
	pr_job_tot_apply_amt, 
	pr_act_tot_apply_amt, 
	pr_job_tot_cos_amt, 
	pr_act_tot_cos_amt DECIMAL(16,2), 
	pr_job_tot_trans_qty, 
	pr_act_tot_trans_qty, 
	pr_res_tot_trans_qty DECIMAL(16,3), 
	pa_line array[4] OF CHAR(132) 

	OUTPUT 

	ORDER external BY pr_jobledger.job_code, 
	pr_jobledger.var_code, 
	pr_jobledger.activity_code, 
	pr_jobledger.trans_source_text, 
	pr_jobledger.seq_num 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  
				 
		BEFORE GROUP OF pr_jobledger.job_code 
			SKIP TO top OF PAGE 
			PRINT COLUMN 001, "Job:", 
			COLUMN 009, pr_job.job_code, 
			COLUMN 018, ": ", pr_job.title_text 

			PRINT COLUMN 001, "Client:", 
			COLUMN 009, pr_job.cust_code, 
			COLUMN 018, ": ", pr_cust_name 
			SKIP 1 line 

			CASE 
				WHEN pr_job.bill_way_ind = "F" 
					PRINT COLUMN 001, "Fixed Price Job " 
					PRINT COLUMN 001, "----------------" 
					PRINT COLUMN 001, "On Fixed Price Jobs invoices are NOT", 
					" reconciled TO Costs" 
				WHEN pr_job.bill_way_ind = "C" 
					PRINT COLUMN 001, "Cost Plus Job " 
					PRINT COLUMN 001, "--------------" 
					PRINT COLUMN 001, "On Cost Plus Jobs invoices are NOT", 
					" reconciled TO Costs" 
			END CASE 
			
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]
			 
			LET pr_job_tot_trans_amt = 0 
			LET pr_job_tot_charge_amt = 0 
			LET pr_job_tot_apply_amt = 0 
			LET pr_job_tot_cos_amt = 0 
			LET pr_job_tot_trans_qty = 0
			 
		BEFORE GROUP OF pr_jobledger.activity_code 
			PRINT COLUMN 001, "Activity ", pr_jobledger.activity_code 
			LET pr_act_tot_trans_amt = 0 
			LET pr_act_tot_charge_amt = 0 
			LET pr_act_tot_trans_qty = 0 
			LET pr_act_tot_apply_amt = 0 
			LET pr_act_tot_cos_amt = 0
			 
		BEFORE GROUP OF pr_jobledger.trans_source_text 
			PRINT COLUMN 005, " Resource ", pr_jobledger.trans_source_text 
			LET pr_res_tot_trans_amt = 0 
			LET pr_res_tot_charge_amt = 0 
			LET pr_res_tot_trans_qty = 0
			 
		BEFORE GROUP OF pr_jobledger.seq_num 
			LET pr_resbill_flag = false 
			PRINT COLUMN 001, pr_jobledger.trans_date USING "dd/mm/yy", 
			COLUMN 012, pr_jobledger.trans_type_ind, "#", 
			pr_jobledger.trans_source_num USING "<<<<<<<<", 
			COLUMN 024, pr_jobledger.trans_amt USING "-------&.&&", 
			COLUMN 036, pr_jobledger.charge_amt USING "-------&.&&" , 
			COLUMN 062, pr_jobledger.trans_qty USING "------&.&&&", 
			COLUMN 101, pr_jobledger.desc_text[1,30]
			 
		ON EVERY ROW 
			IF pr_resbill.inv_num IS NOT NULL THEN 
				LET pr_resbill_flag = true 
				PRINT COLUMN 001, pr_inv_date USING "dd/mm/yy", 
				COLUMN 010, "IN#", pr_resbill.inv_num USING "<<<<<<<<", 
				COLUMN 049, pr_resbill.apply_amt USING "-------&.&&" , 
				COLUMN 075, pr_resbill.apply_qty USING "------&.&&&", 
				COLUMN 088, pr_resbill.apply_cos_amt USING "-------&.&&" 
			END IF
			 
		AFTER GROUP OF pr_jobledger.seq_num 
			# IF there were rows FROM resbill, PRINT a total line - FOR this
			# jobledger transaction...voucher, Purchase OR whatever
			IF pr_resbill_flag THEN 
				PRINT COLUMN 023, "----------------------------------------", 
				"------------------------------------" 
				PRINT COLUMN 001, "Total ", pr_jobledger.trans_type_ind, "#", 
				pr_jobledger.trans_source_num USING "<<<<<<<<", 
				COLUMN 024, pr_jobledger.trans_amt USING "-------&.&&", 
				COLUMN 036, pr_jobledger.charge_amt USING "-------&.&&" , 
				COLUMN 049, GROUP sum(pr_resbill.apply_amt) USING "-------&.&&", 
				COLUMN 062, pr_jobledger.trans_qty USING "------&.&&&", 
				COLUMN 075, GROUP sum(pr_resbill.apply_qty) USING "------&.&&&", 
				COLUMN 088, GROUP sum(pr_resbill.apply_cos_amt) 
				USING "-------&.&&"; 
				IF GROUP sum(pr_resbill.apply_qty) = pr_jobledger.trans_qty THEN 
					PRINT COLUMN 101, "Reconciled, quantities billed" 
				ELSE 
					PRINT COLUMN 101, " " 
				END IF 
				PRINT COLUMN 023, "========================================", 
				"====================================" 
			END IF 
			LET pr_res_tot_trans_amt = pr_res_tot_trans_amt + pr_jobledger.trans_amt 
			LET pr_res_tot_charge_amt = pr_res_tot_charge_amt + pr_jobledger.charge_amt 
			IF pr_jobledger.trans_qty IS NOT NULL THEN 
				LET pr_res_tot_trans_qty = pr_res_tot_trans_qty	+ pr_jobledger.trans_qty 
			END IF
			 
		AFTER GROUP OF pr_jobledger.trans_source_text 
			PRINT COLUMN 001, "Resource total ",pr_jobledger.trans_source_text, 
			COLUMN 024, pr_res_tot_trans_amt USING "-------&.&&", 
			COLUMN 036, pr_res_tot_charge_amt USING "-------&.&&" , 
			COLUMN 049, GROUP sum(pr_resbill.apply_amt) USING "-------&.&&" , 
			COLUMN 062, pr_res_tot_trans_qty USING "------&.&&&", 
			COLUMN 075, GROUP sum(pr_resbill.apply_qty) USING "------&.&&&", 
			COLUMN 088, GROUP sum(pr_resbill.apply_cos_amt) USING "-------&.&&"; 
			LET pr_act_tot_trans_amt = pr_act_tot_trans_amt + pr_res_tot_trans_amt 
			LET pr_act_tot_charge_amt = pr_act_tot_charge_amt + pr_res_tot_charge_amt 
			LET pr_act_tot_trans_qty = pr_act_tot_trans_qty + pr_res_tot_trans_qty 
			IF GROUP sum(pr_resbill.apply_qty) = pr_res_tot_trans_amt THEN 
				PRINT COLUMN 101, "Reconciled, quantities billed." 
			ELSE 
				PRINT COLUMN 101, " " 
			END IF 
			PRINT COLUMN 023, "========================================", 
			"====================================" 
			SKIP 1 line 
			
		AFTER GROUP OF pr_jobledger.activity_code 
			IF pr_job.bill_way_ind = "C" 
			OR pr_job.bill_way_ind = "F" THEN 
				DECLARE inv_c CURSOR FOR 
				SELECT * FROM invoicehead, invoicedetl 
				WHERE invoicehead.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND invoicehead.job_code = pr_job.job_code 
				AND invoicedetl.cmpy_code = invoicehead.cmpy_code 
				AND invoicedetl.inv_num = invoicehead.inv_num 
				ORDER BY invoicehead.cmpy_code, invoicehead.inv_num 

				LET pr_act_tot_apply_amt = 0 
				LET pr_act_tot_cos_amt = 0 

				PRINT COLUMN 001, "Un-allocated Invoices " 

				FOREACH inv_c INTO pr_invoicehead.*, pr_invoicedetl.* 
					IF pr_invoicedetl.line_total_amt IS NOT NULL THEN 
						LET pr_act_tot_apply_amt = pr_act_tot_apply_amt + 
						pr_invoicedetl.line_total_amt 
					END IF 
					# COST OF SALES: "T" jobs accumulate cost of sales in the resbill
					# table, but NOT "F" OR "C" as they don't write resbill rows in
					# invoicing.
					# The Activity total gets group sum of apply_cos_amt, but this only
					# works FROM T jobs. FOR F & C jobs we have TO accumulate them
					# separately so FOR both T AND C&F jobs we accumulate cos in
					# pr_act_tot_cos_amt
					IF pr_invoicedetl.ext_cost_amt IS NOT NULL THEN 
						LET pr_act_tot_cos_amt = pr_act_tot_cos_amt + 
						pr_invoicedetl.ext_cost_amt 
					END IF 
					PRINT COLUMN 001, pr_invoicehead.inv_date USING "dd/mm/yy", 
					COLUMN 010, "IN#", pr_invoicehead.inv_num USING "<<<<<<<<", 
					COLUMN 049, pr_invoicedetl.line_total_amt USING "-------&.&&", 
					COLUMN 088, pr_invoicedetl.ext_cost_amt USING "-------&.&&" 
				END FOREACH 

			ELSE 
				LET pr_act_tot_apply_amt = GROUP sum(pr_resbill.apply_amt) 
				LET pr_act_tot_cos_amt = GROUP sum(pr_resbill.apply_cos_amt) 
			END IF 

			PRINT COLUMN 001, "Activity total ", pr_jobledger.activity_code, 
			COLUMN 024, pr_act_tot_trans_amt USING "-------&.&&", 
			COLUMN 036, pr_act_tot_charge_amt USING "-------&.&&" , 
			COLUMN 049, pr_act_tot_apply_amt USING "-------&.&&" , 
			COLUMN 062, pr_act_tot_trans_qty USING "------&.&&&", 
			COLUMN 075, GROUP sum(pr_resbill.apply_qty) USING "------&.&&&", 
			COLUMN 088, pr_act_tot_cos_amt USING "-------&.&&" 
			PRINT COLUMN 023, "========================================", 
			"====================================" 
			LET pr_job_tot_trans_amt = pr_job_tot_trans_amt + pr_act_tot_trans_amt 
			LET pr_job_tot_charge_amt = pr_job_tot_charge_amt + pr_act_tot_charge_amt 
			LET pr_job_tot_apply_amt = pr_job_tot_apply_amt + pr_act_tot_apply_amt 
			LET pr_job_tot_cos_amt = pr_job_tot_cos_amt + pr_act_tot_cos_amt 
			LET pr_job_tot_trans_qty = pr_job_tot_trans_qty + pr_act_tot_trans_qty 
			SKIP 1 line 
			
		AFTER GROUP OF pr_jobledger.job_code 
			PRINT COLUMN 001, "Job total ", pr_jobledger.job_code, 
			COLUMN 024, pr_job_tot_trans_amt USING "-------&.&&", 
			COLUMN 036, pr_job_tot_charge_amt USING "-------&.&&" , 
			COLUMN 049, pr_job_tot_apply_amt USING "-------&.&&" , 
			COLUMN 062, pr_job_tot_trans_qty USING "------&.&&&", 
			COLUMN 075, GROUP sum(pr_resbill.apply_qty) USING "------&.&&&", 
			COLUMN 088, pr_job_tot_cos_amt USING "-------&.&&" 
			PRINT COLUMN 023, "========================================", 
			"====================================" 
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