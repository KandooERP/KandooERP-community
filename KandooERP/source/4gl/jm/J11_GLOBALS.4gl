############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

GLOBALS 
	DEFINE 
	formname CHAR(15), 
	pr_job RECORD LIKE job.*, 
	pr_jobtype RECORD LIKE jobtype.*, 
	pr_jobvars RECORD LIKE jobvars.*, 
	pr_job_desc RECORD LIKE job_desc.*, 
	pa_job_desc array[100] OF LIKE job_desc.desc_text, 
	pr_customer RECORD LIKE customer.*, 
	pr_salesperson RECORD LIKE salesperson.*, 
	pr_coa RECORD LIKE coa.*, 
	pr_jmparms RECORD LIKE jmparms.*, 
	pr_rec_kandoouser RECORD LIKE kandoouser.*, 
	pr_base_currency LIKE glparms.base_currency_code, 
	pr_user_scan_code LIKE kandoouser.acct_mask_code, 
	pr_activity RECORD LIKE activity.*, 
	pr_act_desc RECORD LIKE act_desc.*, 
	act_desc_cnt SMALLINT, 
	pa_act_desc array[100] OF LIKE act_desc.desc_text, 
	pr_image_all_act CHAR(1), 
	pr_source_job_code LIKE job.job_code, 
	pr_source_title_text LIKE job.title_text, 
	pr_responsible RECORD LIKE responsible.*, 
	user_default_code, 
	bill_entry_mask, 
	wip_entry_mask, 
	cos_entry_mask LIKE kandoouser.acct_mask_code, 
	acct_desc_text LIKE coa.desc_text, 
	bill_acct_flag, wip_acct_flag, cos_acct_flag SMALLINT, 
	default_entry_ok, entry_flag SMALLINT, 
	err_continue CHAR(1), 
	ans CHAR(1), 
	ins_text CHAR(200), 
	err_message CHAR(40), 
	runner CHAR(30), 
	first_time CHAR(1), 
	idx, scrn, cnt SMALLINT, 
	pr_validate_ind CHAR(1), 
	pv_type_code LIKE job.type_code, 
	pv_wildcard CHAR(1), 
	pr_menunames RECORD LIKE menunames.* 
END GLOBALS 
