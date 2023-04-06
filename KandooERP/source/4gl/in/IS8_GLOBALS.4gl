GLOBALS "../common/glob_GLOBALS.4gl"

GLOBALS 
	DEFINE 
	pr_output CHAR(60), 
	rpt_pageno LIKE rmsreps.page_num, 
	pr_loadparms RECORD LIKE loadparms.*, 
	pr_loadvalues RECORD 
		mkcost_per FLOAT, 
		mkprice_per FLOAT, 
		vend_code LIKE prodquote.vend_code, 
		curr_code LIKE prodquote.curr_code, 
		break_qty LIKE prodquote.break_qty, 
		lead_time_qty LIKE prodquote.lead_time_qty, 
		expiry_date LIKE prodquote.expiry_date, 
		desc_text LIKE prodquote.desc_text, 
		status_ind LIKE prodquote.status_ind 
	END RECORD, 
	pr_updparms RECORD 
		ans1 CHAR(1), 
		ware_code LIKE warehouse.ware_code, 
		ans3, ans4, ans5, ans6, ans7 CHAR(1) 
	END RECORD 
END GLOBALS 
