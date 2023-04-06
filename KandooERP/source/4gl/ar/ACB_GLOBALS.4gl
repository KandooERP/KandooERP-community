############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_DATABASE.4gl"
GLOBALS 
	DEFINE glob_cmpy_code LIKE kandoouser.cmpy_code 
	DEFINE glob_username LIKE kandoouser.sign_on_code 
	DEFINE glob_from_batch LIKE cashrcphdr.batch_no 
	DEFINE glob_to_batch LIKE cashrcphdr.batch_no 
END GLOBALS
