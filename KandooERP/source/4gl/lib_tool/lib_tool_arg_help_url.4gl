###########################################################################
# Module Scope Variables
###########################################################################
DEFINE ml_help_url VARCHAR(30) --help_url NAME 
DEFINE ml_help_url_set boolean --true = variable initialized/set false=not initialized 

###########################################################################
# FUNCTION set_help_url(p_help_url)
#
# Accessor Method for ml_help_url
# DEFINE ml_help_url VARCHAR(30)  --help_url name
# DEFINE ml_help_url_set BOOLEAN --TRUE = variable INITIALIZEd/SET FALSE=NOT INITIALIZEd
###########################################################################
FUNCTION set_help_url(p_help_url) 
	DEFINE p_help_url STRING 

	IF p_help_url IS NOT NULL THEN 
		LET ml_help_url = p_help_url 
		CALL fgl_setenv("HELP_URL",ml_help_url) 
		LET ml_help_url_set = true 
	END IF 
END FUNCTION 


###########################################################################
# FUNCTION get_help_url()
#
# Accessor Method for ml_help_url_set = STATUS, if help_url was SET
###########################################################################
FUNCTION get_help_url() 

	IF ml_help_url_set = false THEN 
		IF (fgl_getenv("HELP_URL") IS null) THEN 
			#use defaut kandoodb
			CALL fgl_setenv("HELP_URL","http://doc.kandooerp.org/") 
			CALL set_help_url("http://doc.kandooerp.org/") 
		ELSE 
			IF fgl_getenv("HELP_URL") IS NOT NULL THEN 
				CALL set_help_url(trim(fgl_getenv("HELP_URL"))) 
			--ELSE 
			--	CALL set_help_url(trim(fgl_getenv("HELP_URL"))) 
			END IF 
		END IF 
	END IF 

	RETURN ml_help_url 
END FUNCTION 


###########################################################################
# FUNCTION get_help_url_set()
#
# Accessor Method for ml_help_url_set  = STATUS, if help_url was SET
###########################################################################
FUNCTION get_help_url_set() 
	RETURN ml_help_url_set 
END FUNCTION 

