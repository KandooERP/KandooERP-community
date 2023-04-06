############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 


GLOBALS 
	DEFINE 
	pr_purchhead RECORD LIKE purchhead.*, 
	pr_vendor RECORD LIKE vendor.*, 
	pr_warehouse RECORD LIKE warehouse.*, 
	pr_tax RECORD LIKE tax.*, 
	pr_poaudit RECORD LIKE poaudit.*, 
	pr_purchdetl RECORD LIKE purchdetl.*, 
	pr_prodstatus RECORD LIKE prodstatus.*, 
	pr_category RECORD LIKE category.*, 
	pr_currency RECORD LIKE currency.*, 
	pr_product RECORD LIKE product.*, 
	pr_puparms RECORD LIKE puparms.*, 
	pr_term RECORD LIKE term.*, 
	passover INTEGER, 
	pr_mode CHAR(1), 
	pr_prev_mode CHAR(1), 
	p1_overdue, p1_baddue LIKE vendor.over1_amt, 
	func_type CHAR(14), 
	err_message CHAR(40), 
	try_again CHAR(1), 
	available DECIMAL(8,2), 
	fr_tax_per DECIMAL(5,3), 
	la_tax_per DECIMAL(5,3), 
	dec_unpr DECIMAL(12,2), 
	dec_taxp DECIMAL(12,2), 
	dec_untax DECIMAL(12,2), 
	dec2fix DECIMAL(10,2), 
	chng_qty DECIMAL(10,4), 
	save_date DATE, 
	save_year, save_period SMALLINT, 
	pr_stat SMALLINT, 
	pa_jmresource ARRAY [2020] OF RECORD 
		allocation_ind LIKE jmresource.allocation_ind 
	END RECORD 
END GLOBALS 
