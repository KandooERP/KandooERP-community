############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

GLOBALS 
	DEFINE 

	pr_job RECORD LIKE job.*, 
	pr_jobtype RECORD LIKE jobtype.*, 
	pr_customer RECORD LIKE customer.*, 
	pr_activity RECORD LIKE activity.*, 
	pr_actiunit RECORD LIKE actiunit.*, 
	pr_jobvars RECORD LIKE jobvars.*, 
	pr_responsible RECORD LIKE responsible.*, 
	pr_glparms RECORD LIKE glparms.*, 
	pr_coa RECORD LIKE coa.*, 
	pr_act_desc RECORD LIKE act_desc.*, 
	pa_act_desc array[100] OF LIKE act_desc.desc_text, 
	pr_jmparms RECORD LIKE jmparms.*, 
	pr_rec_kandoouser RECORD LIKE kandoouser.*, 
	pr_user_scan_code LIKE kandoouser.acct_mask_code, 
	entry_mask, 
	wip_entry_mask, cos_entry_mask LIKE kandoouser.acct_mask_code, 
	acct_desc_text LIKE coa.desc_text, 

	acct_flag, 
	wip_acct_flag, cos_acct_flag SMALLINT, 
	ans, err_continue CHAR(1), 
	ins_text CHAR(200), 
	err_message CHAR(40), 
	pv_cnt, 
	act_desc_cnt, entry_flag SMALLINT 
END GLOBALS 
