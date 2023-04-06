############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS 

	DEFINE 
	formname CHAR(10), 
	err_continue CHAR(1), 
	err_message CHAR(50), 
	pv_bor_flag SMALLINT, 
	pv_seq_cnt SMALLINT, 
	pv_min_ord_qty LIKE product.min_ord_qty, 
	pv_wgted_cost_tot LIKE prodmfg.wgted_cost_amt, 
	pv_est_cost_tot LIKE prodmfg.est_cost_amt, 
	pv_act_cost_tot LIKE prodmfg.act_cost_amt, 
	pv_list_price_tot LIKE prodmfg.list_price_amt, 

	pr_menunames RECORD LIKE menunames.*, 
	pr_bor RECORD LIKE bor.*, 
	pr_mnparms RECORD LIKE mnparms.*, 
	pr_inparms RECORD LIKE inparms.* 

END GLOBALS 

