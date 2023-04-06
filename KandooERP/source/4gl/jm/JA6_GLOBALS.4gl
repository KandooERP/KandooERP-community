############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

GLOBALS 

	DEFINE 

	pr_user_scan_code LIKE kandoouser.acct_mask_code, 
	sel_dat_text, sel_inv_text, sel_inv1_text, sel_inv2_text, 

	sel_contract_text, query_text CHAR(1500), 
	formname CHAR(15), 

	runner CHAR(30), 
	rpt_pageno LIKE rmsreps.page_num, 
	rpt_length LIKE rmsreps.page_length_num, 
	rpt_wid SMALLINT, 
	pr_output CHAR(132), 

	pv_ans CHAR(1), 
	pv_contract_code LIKE contracthead.contract_code, 
	pv_billing_type, pv_billing_delete CHAR(1), 
	pv_error_text CHAR(50), 
	pv_invoice_present, array_size, arr_size, idx, x SMALLINT, 
	pv_error, pv_error_run, pv_corp_cust, pr_inv_line_num, 
	pr_tax_line_num SMALLINT, 
	pv_invoice_date DATE, 
	pv_invoice_idate DATE, 
	pv_year_num, 
	pv_period_num SMALLINT, 
	pv_job_start_idx SMALLINT, 
	pv_curr_job_start_idx SMALLINT, 
	pv_curr_idx SMALLINT, 
	pv_cnt SMALLINT, 
	pv_run_total LIKE tentinvhead.total_amt, 
	pv_prev_type_code LIKE contractdetl.type_code 
	DEFINE glob_password CHAR(6) 


	DEFINE tmp_ext_price_amt, 
	tmp_unit_tax_amt, 
	tmp_line_tot_amt, 
	tmp_ext_tax_amt, 
	tmp_tax_total money(10,2), 
	tmp_tax_code LIKE tax.tax_code, 
	tot_lines, sav_tot_lines SMALLINT, 

	pa_tentinvdetl array[900] OF RECORD LIKE tentinvdetl.*, 
	pa_invd_ins array[3000] OF RECORD LIKE tentinvdetl.*, 

	pa_inv_line array[900] OF RECORD 
		invoice_flag CHAR(1), 
		activity_code LIKE activity.activity_code, 
		var_code LIKE activity.var_code, 
		title_text LIKE activity.title_text, 
		est_comp_per LIKE activity.est_comp_per, 
		est_cost_amt LIKE activity.est_cost_amt, 
		act_cost_amt LIKE activity.act_cost_amt, 
		diff_acct_amt LIKE activity.act_cost_amt, 
		est_bill_amt LIKE activity.est_bill_amt, 
		act_bill_amt LIKE activity.act_bill_amt, 
		diff_bill_amt LIKE activity.act_bill_amt, 
		post_cost_amt LIKE activity.post_cost_amt, 
		diff_post_amt LIKE activity.post_cost_amt, 
		unit_code LIKE activity.unit_code, 
		est_cost_qty LIKE activity.est_cost_qty, 
		act_cost_qty LIKE activity.act_cost_qty, 
		est_bill_qty LIKE activity.est_bill_qty, 
		act_bill_qty LIKE activity.act_bill_qty, 
		diff_bill_qty LIKE activity.act_cost_qty, 
		post_revenue_amt LIKE activity.post_revenue_amt, 
		bill_way_ind LIKE activity.bill_way_ind, 
		cost_alloc_flag LIKE activity.cost_alloc_flag, 
		this_bill_amt DECIMAL(10,2), 
		this_bill_qty DECIMAL(10,2), 
		this_cos_amt DECIMAL(10,2), 
		acct_code CHAR(18) 
	END RECORD, 


	pa_tentinvrun array[2000] OF RECORD 
		line_ind CHAR(1), 
		inv_num LIKE tentinvhead.inv_num, 
		contract_code LIKE contracthead.contract_code, 
		desc_text LIKE contracthead.desc_text, 
		total_amt LIKE tentinvhead.total_amt 
	END RECORD, 


	pr_tempbill RECORD 
		trans_invoice_flag CHAR(1), 
		trans_date LIKE jobledger.trans_date, 
		var_code LIKE jobledger.var_code, 
		activity_code LIKE jobledger.activity_code, 
		seq_num LIKE jobledger.seq_num, 
		line_num LIKE resbill.line_num, 
		trans_type_ind LIKE jobledger.trans_type_ind, 
		trans_source_num LIKE jobledger.trans_source_num, 
		trans_source_text LIKE jobledger.trans_source_text, 
		trans_amt LIKE jobledger.trans_amt, 
		trans_qty LIKE jobledger.trans_qty, 
		charge_amt LIKE jobledger.charge_amt, 
		apply_qty LIKE resbill.apply_qty, 
		apply_amt LIKE resbill.apply_amt, 
		apply_cos_amt LIKE resbill.apply_cos_amt, 
		desc_text LIKE jobledger.desc_text, 
		prev_apply_qty DECIMAL(15,3), 
		prev_apply_amt DECIMAL(16,3), 
		prev_apply_cos_amt DECIMAL(16,2), 
		allocation_ind LIKE jobledger.allocation_ind 
	END RECORD, 

	pr_tax RECORD LIKE tax.*, 
	pr_term RECORD LIKE term.*, 
	pr_salesperson RECORD LIKE salesperson.*, 
	pr_company RECORD LIKE company.*, 
	pr_job RECORD LIKE job.*, 
	pr_customer RECORD LIKE customer.*, 
	pr_corp_cust RECORD LIKE customer.*, 
	pr_customership RECORD LIKE customership.*, 
	pr_summary RECORD LIKE tentinvdetl.*, 
	pr_product RECORD LIKE product.*, 
	pr_category RECORD LIKE category.*, 
	pr_tentinvdetl RECORD LIKE tentinvdetl.*, 
	pr_tentinvhead RECORD LIKE tentinvhead.*, 
	pr_contracthead RECORD LIKE contracthead.*, 
	pr_contractdetl RECORD LIKE contractdetl.*, 
	pr_contractdate RECORD LIKE contractdate.*, 
	pr_activity RECORD LIKE activity.*, 
	pr_menunames RECORD LIKE menunames.*, 
	pr_jobledger RECORD LIKE jobledger.*, 
	pr_period RECORD LIKE period.*, 
	pr_rec_kandoouser RECORD LIKE kandoouser.*, 
	pr_arparms RECORD LIKE arparms.*, 
	pr_jmparms RECORD LIKE jmparms.* 

END GLOBALS 
