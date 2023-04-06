###########################################################################
# Module Scope Variables
###########################################################################
DEFINE ml_kandooinfo SMALLINT --kandooinfo = 1 OR 0 
DEFINE ml_kandooinfo_set boolean --true = variable initialized/set false=not initialized 


###########################################################################
# FUNCTION get_kandooinfo()
#
# Accessor Method for ml_kandooinfo
###########################################################################
FUNCTION get_kandooinfo() 

	IF ml_kandooinfo_set = false THEN 
		IF fgl_getenv("KANDOOINFO") IS NULL THEN 
			CALL set_kandooinfo(0) 
		ELSE 
			CALL set_kandooinfo(fgl_getenv("KANDOOINFO")) 
		END IF 
	END IF 

	RETURN ml_kandooinfo 
END FUNCTION 


###########################################################################
# FUNCTION get_kandooinfo_set()
#
# Accessor Method for ml_kandooinfo_set  = STATUS, if kandooinfo was SET
###########################################################################
FUNCTION get_kandooinfo_set() 
	RETURN ml_kandooinfo_set 
END FUNCTION 


###########################################################################
# FUNCTION set_kandooinfo(p_kandooinfo)
#
# Accessor Method for ml_kandooinfo
###########################################################################
FUNCTION set_kandooinfo(p_kandooinfo) 
	DEFINE p_kandooinfo SMALLINT 

	IF p_kandooinfo = 0 OR p_kandooinfo = 1 THEN 
		LET ml_kandooinfo = p_kandooinfo 
		CALL fgl_setenv("KANDOOINFO",ml_kandooinfo) 
		LET ml_kandooinfo_set = true 
	END IF 
END FUNCTION 
