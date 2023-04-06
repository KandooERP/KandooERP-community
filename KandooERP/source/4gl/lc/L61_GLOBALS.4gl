############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

GLOBALS 
	# these GLOBALS should be duplicated in          L64.4gl
	DEFINE 
	pr_shiphead RECORD LIKE shiphead.*, 
	ps_shiphead RECORD LIKE shiphead.*, 
	pr_customer RECORD LIKE customer.*, 
	pr_corp_cust RECORD LIKE customer.*, 
	sav_cust_code LIKE customer.cust_code, 
	sav_corp_code LIKE customer.cust_code, 
	pr_tax RECORD LIKE tax.*, 
	pr_shipdetl RECORD LIKE shipdetl.*, 
	cat_codecat RECORD LIKE category.*, 
	pr_product RECORD LIKE product.*, 
	ps_shipdetl RECORD LIKE shipdetl.*, 
	pr_arparms RECORD LIKE arparms.*, 
	pr_smparms RECORD LIKE smparms.*, 
	pr_prodstatus RECORD LIKE prodstatus.*, 
	pr_shiptype RECORD LIKE shiptype.*, 
	pr_shipstatus RECORD LIKE shipstatus.*, 
	pr_term RECORD LIKE term.*, 
	pr_salesperson RECORD LIKE salesperson.*, 
	#pr_statab record
	#cmpy LIKE prodstatus.cmpy_code,
	#ware LIKE prodstatus.ware_code,
	#part LIKE prodstatus.part_code,
	#ship LIKE prodstatus.onhand_qty,
	#which CHAR(3)
	#END RECORD,
	pr_part_code LIKE shipdetl.part_code, 
	p1_overdue, p1_baddue LIKE customer.over1_amt, 
	arr_size,nxtfld, priority, firstime, counter SMALLINT, 
	matrix CHAR(1), 
	matrix_key CHAR(1), 
	matcat CHAR(2), 
	func_type CHAR(14), 
	f_type CHAR(1), 
	back_out, first_time SMALLINT, 
	try_again CHAR(1), 
	err_message CHAR(40), 
	available LIKE prodstatus.onhand_qty, 
	f_taxper, h_taxper LIKE tax.tax_per, 
	dec2fix DECIMAL(10,2), 
	st_shipdetl array[300] OF RECORD LIKE shipdetl.*, 
	pa_taxamt array[300] OF RECORD 
		tax_code LIKE tax.tax_code, 
		duty_ent_amt LIKE shipdetl.duty_ext_ent_amt 
	END RECORD, 
	i,idx, ret_flag, id_flag, scrn, noerror SMALLINT, 
	chng_qty DECIMAL(10,4), 
	goon, ans CHAR(1), 
	patch_code LIKE account.acct_code, 
	cogs_cost MONEY, 
	inv_cost MONEY, 
	display_ship_code CHAR(1), 
	temp_ship_code LIKE shiphead.ship_code, 
	tot_lines SMALLINT, 
	pv_corp_cust SMALLINT, 
	save_ware LIKE warehouse.ware_code, 
	ins_line CHAR(1), 
	edit_line CHAR(1), 
	del_yes CHAR(1) 

END GLOBALS 
