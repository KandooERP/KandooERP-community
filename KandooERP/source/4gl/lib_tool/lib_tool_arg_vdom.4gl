###########################################################################
# Module Scope Variables
###########################################################################
DEFINE ml_vdom SMALLINT --vdom = 1 OR 0 
DEFINE ml_vdom_set boolean --true = variable initialized/set false=not initialized 


###########################################################################
# FUNCTION get_url_vdom()
#
# Accessor Method for ml_vdom
###########################################################################
FUNCTION get_url_vdom() 

	IF ml_vdom_set = false THEN 
		IF fgl_getenv("VDOM") IS NULL THEN 
			CALL set_url_vdom(TRUE) 
		ELSE 
			CALL set_url_vdom(fgl_getenv("VDOM")) 
		END IF 
	END IF 

	RETURN ml_vdom 
END FUNCTION 


{
###########################################################################
# FUNCTION get_url_vdom()
#
# Accessor Method for ml_vdom
###########################################################################
FUNCTION get_url_vdom()

	IF ml_vdom_set = FALSE THEN
		IF fgl_getenv("VDOM")	 IS NULL THEN
#CALL fgl_winmessage("VDOM NOT specified","You need TO specify the value of VDOM\nIn the environment OR in the URL!","error")
			CALL set_url_vdom(0)
		ELSE
			CALL set_url_vdom(fgl_getenv("VDOM"))
		END IF
	END IF

	RETURN ml_vdom
END FUNCTION
}

###########################################################################
# FUNCTION get_vdom_set()
#
# Accessor Method for ml_vdom_set  = STATUS, if vdom was SET
###########################################################################
FUNCTION get_vdom_set() 
	RETURN ml_vdom_set 
END FUNCTION 


###########################################################################
# FUNCTION set_url_vdom(p_vDom)
#
# Accessor Method for ml_vdom
###########################################################################
FUNCTION set_url_vdom(p_vdom) 
	DEFINE p_vdom SMALLINT 

	IF p_vdom = 0 OR p_vdom = 1 THEN 
		LET ml_vdom = p_vdom 
		CALL fgl_setenv("VDOM",ml_vdom) 
		LET ml_vdom_set = true 
	END IF 
END FUNCTION 

{
###########################################################################
# FUNCTION set_url_vdom(p_vDom)
#
# Accessor Method for ml_vdom
###########################################################################
FUNCTION set_url_vdom(p_vDom)
	DEFINE p_vDom SMALLINT

	IF p_vDom = 0 OR p_vDom = 1 THEN
		LET ml_vdom = p_vDom
		CALL fgl_setenv("VDOM",ml_vdom)
		LET ml_vdom_set = TRUE
	END IF
END FUNCTION
}