###########################################################################
# Module Scope Variables
###########################################################################
DEFINE ml_demo SMALLINT --demo = 1 OR 0 
DEFINE ml_demo_set boolean --true = variable initialized/set false=not initialized 


###########################################################################
# FUNCTION get_url_demo()
#
# Accessor Method for ml_demo
###########################################################################
FUNCTION get_url_demo() 

	IF ml_demo_set = false THEN 
		IF fgl_getenv("DEMO") IS NULL THEN 
			CALL set_url_demo(0) 
		ELSE 
			CALL set_url_demo(fgl_getenv("DEMO")) 
		END IF 
	END IF 

	RETURN ml_demo 
END FUNCTION 


###########################################################################
# FUNCTION get_demo_set()
#
# Accessor Method for ml_demo_set  = STATUS, if demo was SET
###########################################################################
FUNCTION get_demo_set() 
	RETURN ml_demo_set 
END FUNCTION 


###########################################################################
# FUNCTION set_url_demo(p_demo)
#
# Accessor Method for ml_demo
###########################################################################
FUNCTION set_url_demo(p_demo) 
	DEFINE p_demo SMALLINT 

	IF p_demo = 0 OR p_demo = 1 THEN 
		LET ml_demo = p_demo 
		CALL fgl_setenv("DEMO",ml_demo) 
		LET ml_demo_set = true 
	END IF 
END FUNCTION 
