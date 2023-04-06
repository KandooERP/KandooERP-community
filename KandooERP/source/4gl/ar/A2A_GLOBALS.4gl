############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_DATABASE.4gl"

GLOBALS 
	DEFINE glob_rec_invoicedetl RECORD LIKE invoicedetl.* 
	DEFINE glob_cred_reason LIKE arparms.reason_code 
	DEFINE glob_inv_text CHAR(100)
	DEFINE glob_cred_text CHAR(100)
END GLOBALS 

