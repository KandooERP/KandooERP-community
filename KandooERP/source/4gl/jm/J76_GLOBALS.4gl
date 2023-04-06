###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

GLOBALS 
	DEFINE 
	formname CHAR(15), 
	pr_text CHAR(20), 
	pr_glparms RECORD LIKE glparms.*, 
	pr_jmparms RECORD LIKE jmparms.*, 
	pr_activity RECORD LIKE activity.*, 
	pr_jobledger RECORD LIKE jobledger.*, 
	pr_jmresource RECORD LIKE jmresource.*,
	#pr_coa RECORD LIKE coa.*,
	pr_actiunit RECORD LIKE actiunit.*,
	pa_res_alloc array[300] OF RECORD 
		job_code LIKE activity.job_code, 
		var_code LIKE activity.var_code, 
		activity_code LIKE activity.activity_code, 
		trans_qty LIKE jobledger.trans_qty, 
		unit_cost_amt LIKE jmresource.unit_cost_amt, 
		unit_bill_amt LIKE jmresource.unit_bill_amt, 
		trans_amt LIKE jobledger.trans_amt, 
		charge_amt LIKE jobledger.charge_amt 
	END RECORD, 
	pa_desc array[300] OF RECORD 
		desc_prompt CHAR(20), 
		desc_text CHAR(40) 
	END RECORD, 
	where_part CHAR(500), 
	#pr_rec_kandoouser RECORD LIKE kandoouser.*,
--	pr_user_scan_code LIKE kandoouser.acct_mask_code, 
	pa_jobledger array[310] OF RECORD 
		job_code LIKE jobledger.job_code, 
		var_code LIKE jobledger.var_code, 
		activity_code LIKE jobledger.activity_code, 
		trans_type_ind LIKE jobledger.trans_type_ind, 
		trans_date LIKE jobledger.trans_date, 
		trans_source_num LIKE jobledger.trans_source_num, 
		trans_source_text LIKE jobledger.trans_source_text, 
		trans_amt LIKE jobledger.trans_amt, 
		year_num LIKE jobledger.year_num, 
		period_num LIKE jobledger.period_num, 
		posted_flag LIKE jobledger.posted_flag 
	END RECORD, 
	idx, scrn, arr_size SMALLINT 
END GLOBALS 
