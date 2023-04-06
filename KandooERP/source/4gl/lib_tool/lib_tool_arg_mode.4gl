###########################################################################
# Global Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl"
###########################################################################
# Module Scope Variables
###########################################################################
DEFINE ml_arg_mode VARCHAR(4) --mode i.e. edit/new/del 
###########################################################################
# FUNCTION get_url_mode()
#
# Accessor Method for ml_arg_mode
###########################################################################
FUNCTION get_url_mode() #used TO be FUNCTION getargmode() 

	RETURN ml_arg_mode 
END FUNCTION 

###########################################################################
# FUNCTION set_url_mode(p_mode)
#
# Accessor Method for ml_arg_mode
###########################################################################
FUNCTION set_url_mode(p_mode) #used TO be FUNCTION get_url_mode(p_mode) 
	DEFINE p_mode STRING -- VARCHAR(4) 
	DEFINE l_msg STRING 

	LET p_mode = p_mode.touppercase() 
	IF NOT ((p_mode = MODE_CLASSIC_ADD) OR (p_mode = MODE_CLASSIC_INSERT) OR (p_mode = MODE_CLASSIC_UPDATE) OR (p_mode = MODE_CLASSIC_EDIT) OR (p_mode = MODE_CLASSIC_DELETE)) THEN 
		LET l_msg = "MODE value ", trim(p_mode), " is invalid!" 
		CALL fgl_winmessage("Error in URL argument MODE",l_msg,"ERROR") 
	ELSE 
		LET ml_arg_mode = p_mode 
	END IF 

END FUNCTION 
