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
	ps_shipdetl RECORD LIKE shipdetl.*, 
	pr_rate_exchange RECORD LIKE rate_exchange.*, 
	pr_currency RECORD LIKE currency.*, 
	pr_tariff RECORD LIKE tariff.*, 
	pr_smparms RECORD LIKE smparms.*, 
	pr_glparms RECORD LIKE glparms.*, 
	pr_shipstatus RECORD LIKE shipstatus.*, 
	pr_shipcosttype RECORD LIKE shipcosttype.*, 
	pr_voucher RECORD LIKE voucher.*, 
	pr_debithead RECORD LIKE debithead.*, 
	pr_source_doc_num LIKE shipdetl.source_doc_num, 
	p1_overdue, p1_baddue LIKE vendor.over1_amt, 
	patch_code LIKE account.acct_code, 
	restart, i,idx, alloc_flag, ret_flag, id_flag, scrn, noerror SMALLINT, 
	arr_size,nxtfld, priority, firstime, counter SMALLINT, 
	matrix, matrix_key, f_type, try_again, ans CHAR(1), 
	display_ship_code CHAR(1), 
	save_conversion_qty FLOAT, 
	save_curr_code LIKE shiphead.curr_code, 
	matcaty CHAR(2), 
	func_type CHAR(14), 
	retain_flag, back_out, first_time SMALLINT, 
	err_message CHAR(40), 
	available DECIMAL(8,2), 
	st_shipdetl array[100] OF RECORD LIKE shipdetl.*, 
	chng_qty DECIMAL(10,4), 
	check_cost, check_amt, check_tax, check_mat, cogs_cost MONEY, 
	tran_date, starter DATE, 
	inv_cost MONEY, 
	temp_ship_code CHAR(8), 
	pr_po_num LIKE purchhead.order_num, 
	pa_shipdetl ARRAY [100] OF RECORD 
		source_doc_num LIKE shipdetl.source_doc_num, 
		doc_line_num LIKE shipdetl.doc_line_num, 
		part_code LIKE shipdetl.part_code, 
		ship_inv_qty LIKE shipdetl.ship_inv_qty, 
		fob_unit_ent_amt LIKE shipdetl.fob_unit_ent_amt, 
		fob_ext_ent_amt LIKE shipdetl.fob_ext_ent_amt, 
		desc_text LIKE shipdetl.desc_text 
	END RECORD 
END GLOBALS 
