############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_DATABASE.4gl" 

{
GLOBALS 
	DEFINE 
	pr_jmresource RECORD LIKE jmresource.*, 
	pr_coa RECORD LIKE coa.*, 
	pr_actiunit RECORD LIKE actiunit.*, 
	pr_rec_kandoouser RECORD LIKE kandoouser.*, 
	pr_user_scan_code LIKE kandoouser.acct_mask_code, 
	ans, err_continue CHAR(1), 
	ins_text CHAR(200), 
	err_message CHAR(40), 
	cnt SMALLINT 
	#DEFINE pv_cmpy_code LIKE company.cmpy_code
END GLOBALS 
}