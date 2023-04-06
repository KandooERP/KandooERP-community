############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

GLOBALS 
	DEFINE 
	pr_shiphead RECORD LIKE shiphead.*, 
	ps_shiphead RECORD LIKE shiphead.*, 
	pr_vendor RECORD LIKE vendor.*, 
	pr_shipagent RECORD LIKE vendor.*, 
	pr_warehouse RECORD LIKE warehouse.*, 
	pr_shipdetl RECORD LIKE shipdetl.*, 
	pr_prodstatus RECORD LIKE prodstatus.*, 
	pr_category RECORD LIKE category.*, 
	pr_product RECORD LIKE product.*, 
	pr_currency RECORD LIKE currency.*, 
	pr_tariff RECORD LIKE tariff.*, 
	pr_smparms RECORD LIKE smparms.*, 
	pr_glparms RECORD LIKE glparms.*, 
	pr_shipstatus RECORD LIKE shipstatus.*, 
	pr_voucher RECORD LIKE voucher.*, 
	pr_debithead RECORD LIKE debithead.*, 
	pr_part_code LIKE shipdetl.part_code, 
	scrn, idx, ret_flag, i, restart, noerror SMALLINT, 
	firstime, nxtfld SMALLINT, 
	arr_size, counter SMALLINT, 
	f_type, ans CHAR(1), 
	try_again CHAR(1), 
	save_conversion_qty FLOAT, 
	save_curr_code LIKE shiphead.curr_code, 
	func_type CHAR(14), 
	retain_flag SMALLINT, 
	st_shipdetl array[300] OF RECORD LIKE shipdetl.*, 
	err_message CHAR(40), 
	tran_date DATE, 
	temp_ship_code CHAR(8), 
	pr_po_num LIKE purchhead.order_num, 
	max_shipdetls SMALLINT, 
	pa_shipdetl ARRAY [300] OF RECORD 
		part_code LIKE shipdetl.part_code, 
		source_doc_num LIKE shipdetl.source_doc_num, 
		ship_inv_qty LIKE shipdetl.ship_inv_qty, 
		fob_unit_ent_amt LIKE shipdetl.fob_unit_ent_amt, 
		tariff_code LIKE shipdetl.tariff_code, 
		duty_unit_ent_amt LIKE shipdetl.duty_unit_ent_amt 
	END RECORD 
END GLOBALS 
