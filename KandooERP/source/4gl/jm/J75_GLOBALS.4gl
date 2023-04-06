###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_DATABASE.4gl" 

GLOBALS 
	DEFINE 
	formname CHAR(15), 
	pr_jmresource RECORD LIKE jmresource.*,
	pr_glparms RECORD LIKE glparms.*, 
	pr_jmparms RECORD LIKE jmparms.*, 
	pr_jobledger RECORD LIKE jobledger.*, 
	pr_activity RECORD LIKE activity.*, 
	pr_actiunit RECORD LIKE actiunit.*,
	pa_res_alloc array[100] OF RECORD 
		scroll_flag CHAR(1), 
		job_code LIKE jobledger.job_code, 
		var_code LIKE jobledger.var_code, 
		activity_code LIKE jobledger.activity_code, 
		trans_qty LIKE jobledger.trans_qty, 
		unit_cost_amt LIKE jmresource.unit_cost_amt, 
		unit_bill_amt LIKE jmresource.unit_bill_amt, 
		trans_amt LIKE jobledger.trans_amt, 
		charge_amt LIKE jobledger.charge_amt, 
		allocation_ind LIKE jobledger.allocation_ind 
	END RECORD, 
	pa_comment array[100] OF RECORD 
		desc_text LIKE jobledger.desc_text 
	END RECORD, 
	pa_unit_code array[100] OF CHAR(3), 
	idx, scrn, return_status,pr_add_value SMALLINT, 
	pr_avg_rate_amt DECIMAL(12,4), 
	pr_tot_trans_qty DECIMAL(10,2), 
	pr_tot_cost_amt DECIMAL(17,2), 
	pr_tot_bill_amt DECIMAL(17,2) 
END GLOBALS 
