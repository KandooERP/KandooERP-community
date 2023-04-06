############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 


{
GLOBALS 
	DEFINE 
	pr_inparms RECORD LIKE inparms.*, 
	pr_ibthead RECORD LIKE ibthead.*, 
	pr_customer RECORD LIKE customer.*, 
	pr_ibtdetl RECORD LIKE ibtdetl.*, 
	pr_stk_sel_con_qty LIKE product.stk_sel_con_qty, 
	pr_req_num LIKE reqhead.req_num, 
	pr_sched_ind_sto LIKE ibthead.sched_ind, 
	pr_mode CHAR(10), 
	pr_sched_ind CHAR(1), 
	rpt_pageno LIKE rmsreps.page_num, 
	query_text CHAR(500), 
	pa_ibtdetl DYNAMIC ARRAY OF RECORD 
		scroll_flag CHAR(1), 
		line_num LIKE ibtdetl.line_num, 
		part_code LIKE product.part_code, 
		desc_text LIKE product.desc_text, 
		trf_qty LIKE ibtdetl.trf_qty, 
		stock_uom_code LIKE product.stock_uom_code, 
		sell_tran_qty LIKE prodledg.tran_qty, 
		sell_uom_code LIKE product.stock_uom_code 
	END RECORD, 
	pa_prledger DYNAMIC ARRAY OF RECORD LIKE prodledg.*, 
	pa_prodledg DYNAMIC ARRAY OF RECORD 
		scroll_flag CHAR(1), 
		part_code LIKE product.part_code, 
		desc_text LIKE product.desc_text, 
		stock_tran_qty LIKE prodledg.tran_qty, 
		stock_uom_code LIKE product.stock_uom_code, 
		sell_tran_qty LIKE prodledg.tran_qty, 
		sell_uom_code LIKE product.stock_uom_code 
	END RECORD, 
	pr_printcodes RECORD LIKE printcodes.*, 
	pr_prodledg RECORD LIKE prodledg.*, 
	pr_temp_text CHAR(200), 
	pr_grandtot DECIMAL(16,2), 
	pr_arr_cnt SMALLINT 
END GLOBALS 
}