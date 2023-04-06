############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_DATABASE.4gl" 
GLOBALS 
	DEFINE glob_rec_arparms RECORD LIKE arparms.*
	DEFINE glob_rec_arparmext RECORD LIKE arparmext.* 
	DEFINE glob_temp_text VARCHAR(200)
END GLOBALS