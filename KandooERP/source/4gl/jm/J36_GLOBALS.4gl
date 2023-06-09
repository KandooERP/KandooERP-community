############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

GLOBALS 
	DEFINE 
	formname CHAR(15), 
	pr_menunames RECORD LIKE menunames.*, 
	pr_rec_kandoouser RECORD LIKE kandoouser.*, 
	pr_jmparms RECORD LIKE jmparms.*, 
	pr_arparms RECORD LIKE arparms.*, 
	pr_glparms RECORD LIKE glparms.*, 
	pr_job RECORD LIKE job.*, 
	pr_activity RECORD LIKE activity.*, 
	pr_customer RECORD LIKE customer.*, 

	pr_corp_cust RECORD LIKE customer.*, 
	pv_corp_cust SMALLINT, 

	pr_jobledger RECORD LIKE jobledger.*, 
	pr_saved_inv, 
	pr_invoicehead RECORD LIKE invoicehead.*, 
	pr_tax RECORD LIKE tax.*, 
	pr_customership RECORD LIKE customership.*, 
	pr_term RECORD LIKE term.*, 
	pr_salesperson RECORD LIKE salesperson.*, 
	pr_invoicedetl RECORD LIKE invoicedetl.*, 
	pr_summary RECORD LIKE invoicedetl.*, 
	pa_invoicedetl array[600] OF RECORD LIKE invoicedetl.*, 
	pa_invd_ins array[3000] OF RECORD LIKE invoicedetl.*, 
	pa_inv_line array[600] OF RECORD 
		invoice_flag CHAR(1), 
		activity_code LIKE activity.activity_code, 
		var_code LIKE activity.var_code, 
		title_text LIKE activity.title_text, 
		est_comp_per LIKE activity.est_comp_per, 
		est_cost_amt LIKE activity.est_cost_amt, 
		act_cost_amt LIKE activity.act_cost_amt, 
		diff_act_amt LIKE activity.act_cost_amt, 
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
	pa_inv_select array[600] OF RECORD 
		invoice_flag CHAR(1), 
		activity_code LIKE activity.activity_code, 
		var_code LIKE activity.var_code, 
		title_text LIKE activity.title_text, 
		est_comp_per LIKE activity.est_comp_per, 
		est_cost_amt LIKE activity.est_cost_amt, 
		act_cost_amt LIKE activity.act_cost_amt, 
		diff_act_amt LIKE activity.act_cost_amt, 
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
	pa_notes array[600] OF RECORD 
		note_code CHAR(18), 
		var_code LIKE activity.var_code, 
		activity_code LIKE activity.activity_code, 
		title_text LIKE activity.title_text 
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
		prev_apply_amt DECIMAL(16,2), 
		prev_apply_cos_amt DECIMAL(16,2), 
		allocation_ind LIKE jobledger.allocation_ind 
	END RECORD, 
	pr_addbill RECORD 
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
		prev_apply_amt DECIMAL(16,2), 
		prev_apply_cos_amt DECIMAL(16,2), 
		allocation_ind LIKE jobledger.allocation_ind 
	END RECORD, 
	pr_editbill RECORD 
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
		prev_apply_amt DECIMAL(16,2), 
		prev_apply_cos_amt DECIMAL(16,2) 
	END RECORD, 
	pr_user_scan_code LIKE kandoouser.acct_mask_code, 
	note_size SMALLINT, 
	arr_size SMALLINT 
	DEFINE glob_password CHAR(6)
	 


	DEFINE tmp_ext_price_amt, 
	tmp_unit_tax_amt, 
	tmp_line_tot_amt, 
	tmp_ext_tax_amt, 
	tmp_tax_total money(10,2), 
	tmp_tax_code LIKE tax.tax_code, 
	sav_tot_lines, tot_lines SMALLINT, 
	x SMALLINT, 
	pr_inv_line_num SMALLINT, 
	pr_tax_line_num SMALLINT, 
	display_inv_num CHAR(1), 
	select_text CHAR(1500), 
	where_part CHAR(1200), 
	scrn, 
	idx SMALLINT, 
	# ARRAY TO hold original VALUES FOR reversing
	ps_activity array[600] OF RECORD 
		invoice_flag CHAR(1), 
		title_text LIKE activity.title_text, 
		this_bill_amt DECIMAL(10,2), 
		this_bill_qty DECIMAL(10,2), 
		this_cos_amt DECIMAL(10,2) 
	END RECORD, 
	pa_pcs array[3] OF RECORD 
		act_bill_amt, # ROW 1 IS current, 
		est_bill_amt, # ROW 2 IS this invoice (only billed TO date), 
		bill_pc, # ROW 3 IS total OF CURRENT AND this invoice 
		act_cost_amt, 
		cost_pc DECIMAL, 
		post_cost_amt, 
		act_p_l_amt, 
		act_p_l_pc DECIMAL(16,2) 
	END RECORD, 
	max_array SMALLINT, 
	pa_activity array[600] OF RECORD 
		invoice_flag CHAR(1), 
		title_text LIKE activity.title_text, 
		this_bill_amt DECIMAL(10,2), 
		this_bill_qty DECIMAL(10,2), 
		this_cos_amt DECIMAL(10,2) 
	END RECORD, 
	allow_update SMALLINT, 
	ans CHAR(1), 
	first_time SMALLINT, 
	orig_inv_amt LIKE invoicehead.total_amt 

END GLOBALS 
