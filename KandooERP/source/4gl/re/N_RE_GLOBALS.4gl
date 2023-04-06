############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_DATABASE.4gl" 
GLOBALS 
	DEFINE msgresp LIKE language.yes_flag #this joke needs TO GO as soon we cleanup all files/functions
	DEFiNE glob_rec_reqparms RECORD LIKE reqparms.* 
END GLOBALS 
