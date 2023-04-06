############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
{
GLOBALS 
	DEFINE pr_product RECORD LIKE product.*, 
	pr_prodledg RECORD LIKE prodledg.*, 
	pr_prodadjtype RECORD LIKE prodadjtype.*, 
	pr_inparms RECORD LIKE inparms.*, 
	pr_company RECORD LIKE company.*, 
	pr_coa RECORD LIKE coa.*, 
	pr_prodstatus RECORD LIKE prodstatus.*, 
	pa_stockissue array[1000] OF RECORD 
		scroll_flag CHAR(1), 
		part_code LIKE prodstatus.part_code, 
		ware_code LIKE prodstatus.ware_code, 
		source_text LIKE prodledg.source_text, 
		tran_qty LIKE prodledg.tran_qty, 
		sell_uom_code LIKE product.sell_uom_code, 
		cost_amt LIKE prodledg.cost_amt 
	END RECORD, 
	pr_stockissue RECORD 
		scroll_flag CHAR(1), 
		part_code LIKE prodstatus.part_code, 
		ware_code LIKE prodstatus.ware_code, 
		source_text LIKE prodledg.source_text, 
		tran_qty LIKE prodledg.tran_qty, 
		sell_uom_code LIKE product.sell_uom_code, 
		cost_amt LIKE prodledg.cost_amt 
	END RECORD, 
	pa_stockother array[1000] OF RECORD 
		part_desc_text LIKE product.desc_text, 
		source_desc_text LIKE prodledg.desc_text, 
		acct_code LIKE prodledg.acct_code, 
		coa_desc_text LIKE coa.desc_text, 
		note_entry SMALLINT 
	END RECORD, 
	pr_stockother RECORD 
		part_desc_text LIKE product.desc_text, 
		source_desc_text LIKE prodledg.desc_text, 
		acct_code LIKE prodledg.acct_code, 
		coa_desc_text LIKE coa.desc_text, 
		note_entry SMALLINT 
	END RECORD, 
	issue_text CHAR(8), 
	pr_wind_text CHAR(200), 
	pr_rec_kandoouser RECORD LIKE kandoouser.*, 
	failed_it, bacheq_code SMALLINT, 
	rpt_note LIKE rmsreps.report_text, 
	rpt_wid LIKE rmsreps.report_text, 
	rpt_length LIKE rmsreps.page_length_num, 
	rpt_pageno LIKE rmsreps.page_num, 


	pr_tran_date LIKE prodledg.tran_date, 
	pr_source_num LIKE prodledg.source_num, 
	pr_year_num LIKE prodledg.year_num, 
	pr_period_num LIKE prodledg.period_num, 
	pr_continue, pr_first_time SMALLINT, 
	pr_bypass_menu char(1) # bypasses ring MENU IF user answers "N" 
	# TO quit MESSAGE
END GLOBALS 
}

