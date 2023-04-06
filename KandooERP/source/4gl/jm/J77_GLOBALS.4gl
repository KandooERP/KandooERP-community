############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

GLOBALS 

	DEFINE 
	formname CHAR(15), 
	pr_resbdgt RECORD LIKE resbdgt.*, 
	pr_activity RECORD LIKE activity.*, 
	pv_cmpy_code LIKE company.cmpy_code, 
	pv_username LIKE kandoouser.sign_on_code, 
	pv_menupath CHAR(3), 
	pv_progname CHAR(25), 
	pv_query_1 CHAR(250), 
	pv_rowid, 
	pv_scurs_open, 
	pv_num_rows INTEGER, 
	# pr_rec_kandoouser RECORD LIKE kandoouser.*,
	pv_user_scan_code LIKE kandoouser.acct_mask_code 


END GLOBALS 
