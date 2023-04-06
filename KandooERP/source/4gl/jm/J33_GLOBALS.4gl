###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_DATABASE.4gl" 
GLOBALS 
--	DEFINE formname CHAR(15), 
--	DEFINE pr_company RECORD LIKE company.* 
--	DEFINE pr_rec_kandoouser RECORD LIKE kandoouser.* 
	DEFINE glob_rec_arparms RECORD LIKE arparms.* 
	DEFINE glob_rec_usermsg RECORD LIKE usermsg.* 
	DEFINE glob_prt_message CHAR(1) 
--	DEFINE pr_output CHAR(60) 
END GLOBALS 