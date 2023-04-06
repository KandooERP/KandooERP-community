############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_DATABASE.4gl" 

GLOBALS 
	DEFINE glob_rec_purchdetl RECORD LIKE purchdetl.* 
	DEFINE glob_rec_poaudit RECORD LIKE poaudit.* 
	DEFINE glob_rec_vendor RECORD LIKE vendor.* 
	DEFINE glob_rec_purchhead RECORD LIKE purchhead.* 
	DEFINE glob_rec_jobledger RECORD LIKE jobledger.* #not used ? 
	DEFINE glob_rec_jmresource RECORD LIKE jmresource.* #not used ? 
	DEFINE glob_onorder_total LIKE vendor.onorder_amt 
END GLOBALS 
