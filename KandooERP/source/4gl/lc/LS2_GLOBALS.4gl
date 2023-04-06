############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_DATABASE.4gl" 


GLOBALS 
	DEFINE 
	pr_shiphead RECORD LIKE shiphead.*, 
	pr_product RECORD LIKE product.*, 
	pr_smparms RECORD LIKE smparms.*, 
	pr_inparms RECORD LIKE inparms.*, 
	pr_arparms RECORD LIKE arparms.*, 
	pr_credithead RECORD LIKE credithead.*, 
	pr_creditdetl RECORD LIKE creditdetl.*, 
	pr_customer RECORD LIKE customer.*, 
	pr_glparms RECORD LIKE glparms.*, 
	pa_ship_costs array[50] OF RECORD 
		cost_type_code LIKE shipcosttype.cost_type_code, 
		cost_amt LIKE voucherdist.cost_amt, 
		total_amt LIKE voucherdist.cost_amt, 
		assigned_amt LIKE voucherdist.cost_amt, 
		acct_code LIKE shipcosttype.acct_code 
	END RECORD, 
	pa_idx SMALLINT, # SET TO size OF above ARRAY in ls2b 
	pr_data RECORD 
		tran_type_ind LIKE batchdetl.tran_type_ind, 
		ref_num LIKE batchdetl.ref_num, 
		ref_text LIKE batchdetl.ref_text, 
		acct_code LIKE batchdetl.acct_code, 
		desc_text LIKE batchdetl.desc_text, 
		debit_amt LIKE batchdetl.debit_amt, 
		credit_amt LIKE batchdetl.credit_amt, 
		base_debit_amt LIKE batchdetl.debit_amt, 
		base_credit_amt LIKE batchdetl.credit_amt, 
		currency_code LIKE currency.currency_code, 
		conv_qty LIKE rate_exchange.conv_buy_qty, 
		tran_date LIKE batchdetl.tran_date, 
		stats_qty LIKE batchdetl.stats_qty 
	END RECORD, 
	patch_code LIKE account.acct_code, 
	ans, all_ok, try_again, display_ship_code CHAR(1), 
	counter SMALLINT, 
	err_message CHAR(80), 
	i, idx, id_flag, scrn, noerror SMALLINT, 
	check_tax, check_mat MONEY, 
	message_text CHAR(40), 
	rpt_note CHAR(60), 
	rpt_wid LIKE rmsreps.report_width_num, 
	rpt_length LIKE rmsreps.page_length_num, 
	rpt_pageno LIKE rmsreps.page_num, 
	pr_output CHAR(60), 
	temp_ship_code CHAR(8), 
	pr_goods_ret_amt, pr_tax_ret_amt LIKE shiphead.total_amt, 
	pr_total_ret_amt LIKE shiphead.total_amt 
END GLOBALS 
