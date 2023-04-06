############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

GLOBALS 
	#DEFINE pr_vendor RECORD LIKE vendor.*
	DEFINE glob_rec_voucher RECORD LIKE voucher.* 
	DEFINE glob_desc_ind CHAR(1) 
	DEFINE glob_default_text CHAR(40) 
END GLOBALS 
