###########################################################################
# Module Scope Variables
###########################################################################
DEFINE ml_arg_id_int int --i.e. can be used FOR i.e opening a particular RECORD BY INDEX int 
DEFINE ml_arg_id_char VARCHAR(20) --i.e. can be used FOR i.e opening a particular RECORD BY CHAR id LIKE the customer id 

###########################################################################
# FUNCTION get_url_id_int() / get_url_id_char()
#
# Accessor Method for ml_demo
###########################################################################
FUNCTION get_url_id_int() 
	RETURN ml_arg_id_int 
END FUNCTION 

FUNCTION get_url_id_char() 
	RETURN ml_arg_id_char 
END FUNCTION 


###########################################################################
# FUNCTION set_url_id_int(argValue) / set_url_id_char(argValue)
#
# Accessor Method for ml_demo
###########################################################################
FUNCTION set_url_id_int(argvalue) 
	DEFINE argvalue int 
	LET ml_arg_id_int = argvalue 
END FUNCTION 

FUNCTION set_url_id_char(argvalue) 
	DEFINE argvalue VARCHAR(20) 
	LET ml_arg_id_char = argvalue 
END FUNCTION 
