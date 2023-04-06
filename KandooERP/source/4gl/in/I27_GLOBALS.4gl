############################################################
# GLOBAL Scope Variables
############################################################
{
GLOBALS "../common/glob_GLOBALS.4gl" 

GLOBALS 
	DEFINE 
	pr_inparms RECORD LIKE inparms.*, 
	pr_reedit CHAR(1), 
	ans CHAR(1) 

END GLOBALS 
}