###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS 
	DEFINE glob_yes_flag LIKE language.yes_flag 
	DEFINE glob_no_flag LIKE language.no_flag 
	DEFINE glob_rec_condsale RECORD LIKE condsale.* 
END GLOBALS