############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

GLOBALS 
	DEFINE 
	pr_jmparms RECORD LIKE jmparms.*, 
	pr_ts_head RECORD LIKE ts_head.* 
END GLOBALS 
