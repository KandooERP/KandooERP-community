############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_DATABASE.4gl" 
GLOBALS 
	DEFINE pr_arparms RECORD LIKE arparms.* 
	DEFINE glob_rec_qpparms RECORD LIKE qpparms.* 
	DEFINE msgresp LIKE language.yes_flag #this joke needs TO GO as soon we cleanup all files/functions 
END GLOBALS 
