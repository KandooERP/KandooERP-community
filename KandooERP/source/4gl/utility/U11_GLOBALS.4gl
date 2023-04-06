############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl"
GLOBALS "../common/glob_GLOBALS_userDataTypes.4gl"

GLOBALS 
	DEFINE glob_rec_kandoouser_edit RECORD LIKE kandoouser.* #OF t_rec_kandoouser #like kandoouser.*, #not the CURRENT kandoouser - nothing TO do with the global kandoouser 
END GLOBALS
