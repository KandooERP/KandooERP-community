###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

###########################################################################
# Module Scope Variables
###########################################################################
#DEFINE gl_debug BOOLEAN  --FOR debugging on/off switch TO OUTPUT additional debug information TO the console
DEFINE ml_debug SMALLINT --vdom = 1 OR 0 
DEFINE ml_debug_set boolean --true = variable initialized/set false=not initialized 

###########################################################################
# FUNCTION get_debug_set()
#
# Accessor Method for ml_debug_set  = STATUS, if debug was SET
###########################################################################
FUNCTION get_debug_set() 
	RETURN ml_debug_set 
END FUNCTION 

###########################################################################
# FUNCTION get_debug()
#
# Accessor Method for ml_debug_set = STATUS, if DEBUG was SET
###########################################################################
FUNCTION get_debug() 

	IF ml_debug_set = false THEN 
		IF fgl_getenv("DEBUG") IS NULL THEN 
		ELSE 
			CALL set_debug(trim(fgl_getenv("DEBUG"))) 
		END IF 
	END IF 

	RETURN ml_debug 
END FUNCTION 


###########################################################################
# FUNCTION set_debug(p_debug)
#
# Accessor Method for ml_debug
###########################################################################
FUNCTION set_debug(p_debug) 
	DEFINE p_debug SMALLINT 

	IF p_debug = 0 OR p_debug = 1 THEN 
		LET ml_debug = p_debug 
		CALL fgl_setenv("DEBUG",ml_debug) 
		LET ml_debug_set = true 
	END IF 
END FUNCTION 
