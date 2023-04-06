############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../jm/J_JM_GLOBALS.4gl" 

GLOBALS 
# ericv code disabled on purpose, no way we can accept those globals
# TODO: review schema of globals 
#@Eric PLEASE fix/adjust he code when you comment variable declarations or change database tables/columns
	DEFINE 
	pr_rec_kandoouser RECORD LIKE kandoouser.*, 
	pr_job RECORD LIKE job.*, 
	pr_user_scan_code LIKE kandoouser.acct_mask_code 
END GLOBALS