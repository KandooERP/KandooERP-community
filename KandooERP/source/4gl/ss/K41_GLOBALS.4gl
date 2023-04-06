############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl"
GLOBALS 
	DEFINE 
	pr_subcustomer RECORD LIKE subcustomer.*, 
	pr_subproduct RECORD LIKE subproduct.*, 
	pr_credithead RECORD LIKE credithead.*, 
	pr_credheadaddr RECORD LIKE credheadaddr.*, 
	ps_credithead RECORD LIKE credithead.*, 
	pr_warehouse RECORD LIKE warehouse.*, 
	pr_customer RECORD LIKE customer.*, 
	pr_tax RECORD LIKE tax.*, 
	pr_creditdetl RECORD LIKE creditdetl.*, 
	cat_codecat RECORD LIKE category.*, 
	pr_product RECORD LIKE product.*, 
	ps_creditdetl RECORD LIKE creditdetl.*, 
	pr_arparms RECORD LIKE arparms.*, 
	pr_prodstatus RECORD LIKE prodstatus.*, 
	pr_term RECORD LIKE term.*, 
	pr_salesperson RECORD LIKE salesperson.*, 
	pr_subhead RECORD LIKE subhead.*, 
	pr_customership RECORD LIKE customership.*, 
	pr_statab RECORD 
		cmpy LIKE prodstatus.cmpy_code, 
		ware LIKE prodstatus.ware_code, 
		part LIKE prodstatus.part_code, 
		ship LIKE prodstatus.onhand_qty, 
		which CHAR(3) 
	END RECORD, 
	pr_part_code LIKE creditdetl.part_code, 
	p1_overdue, p1_baddue LIKE customer.over1_amt, 
	arr_size,nxtfld, priority, firstime, counter SMALLINT, 
	matrix CHAR(1), 
	matrix_key CHAR(1), 
	matcat CHAR(2), 
	func_type CHAR(14), 
	f_type CHAR(1), 
	imaging_used, back_out, first_time SMALLINT, 
	try_again CHAR(1), 
	err_message CHAR(40), 
	available LIKE prodstatus.onhand_qty, 
	dec2fix DECIMAL(10,2), 
	st_creditdetl array[100] OF RECORD 
		LIKE creditdetl.*, 
		px_creditdetl array[100] OF RECORD 
			LIKE creditdetl.*, 
			i,idx, ret_flag, id_flag, scrn, noerror SMALLINT, 
			chng_qty DECIMAL(10,4), 
			goon, ans CHAR(1), 
			patch_code LIKE account.acct_code, 
			cogs_cost DECIMAL(16,2), 
			inv_cost DECIMAL(16,2), 
			display_cred_num CHAR(1), 
			temp_cred_num INTEGER , 
			cred_type CHAR(1), 
			save_ship LIKE customership.ship_code, 
			la_tax_per, fr_tax_per DECIMAL(5,3) 
END GLOBALS 
