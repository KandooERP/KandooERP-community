############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_DATABASE.4gl" 
GLOBALS 
	DEFINE pr_jmresource RECORD LIKE jmresource.* 
	DEFINE pr_coa RECORD LIKE coa.* 
	DEFINE pr_actiunit RECORD LIKE actiunit.* 
	DEFINE pr_rec_kandoouser RECORD LIKE kandoouser.* 
	DEFINE pr_user_scan_code LIKE kandoouser.acct_mask_code 
	DEFINE ans, err_continue CHAR(1) 
	DEFINE ins_text CHAR(200) 
	DEFINE err_message CHAR(40) 
	DEFINE cnt SMALLINT 
	#DEFINE pv_cmpy_code LIKE company.cmpy_code
END GLOBALS 
