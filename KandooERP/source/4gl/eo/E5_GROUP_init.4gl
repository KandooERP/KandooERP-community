############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../eo/E_EO_GLOBALS.4gl" 
GLOBALS "../eo/E5_GROUP_GLOBALS.4gl"
############################################################
# FUNCTION init_E5_GROUP()
#
# Initialise Sales Order Processing Module
############################################################
FUNCTION init_E5_GROUP() 

	CALL db_opparms_get_rec(UI_OFF,"1") RETURNING glob_rec_opparms.*
	IF glob_rec_opparms.cmpy_code IS NULL THEN 
		CALL fgl_winmessage("Configuration Error - Operational Parameters missing (Program EZP)",kandoomsg2("E",5003,""),"ERROR") #HuHo 2.12.2020: Was "OZP" which we haven't got and I changed it to "EZP"
		EXIT PROGRAM 
	END IF 
		
END FUNCTION 
############################################################
# END FUNCTION init_E5_GROUP()
############################################################