GLOBALS "../common/glob_GLOBALS.4gl" 


###########################################################################
# FUNCTION get_ku_cmpy_code()
#
# Accessor Methods for glob_moduleId
#
###########################################################################
#FUNCTION get_ku_cmpy_code() 
#
#	RETURN glob_rec_kandoouser.cmpy_code 
#END FUNCTION 



{
###########################################################################
# FUNCTION get_glob_moduleId() / set_glob_moduleId()
#
# Accessor Methods for glob_moduleId
# Program name without file extension
# DEFINE glob_moduleId STRING --Module/Program Name
###########################################################################
FUNCTION get_glob_moduleId()
	RETURN m_moduleId
END FUNCTION

FUNCTION set_glob_moduleId(argValue)
	DEFINE argValue VARCHAR(4)
	LET m_moduleId = argValue
END FUNCTION
}
{
###########################################################################
# FUNCTION get_glob_moduleId() / set_glob_moduleId()
#
# Accessor Methods for glob_moduleId
# DEFINE gl_arg_mode VARCHAR(4)  --mode i.e. edit/new/del
###########################################################################
FUNCTION get_glob_moduleId()
	RETURN glob_moduleId
END FUNCTION

FUNCTION set_glob_moduleId(argValue)
	DEFINE argValue VARCHAR(4)
	LET glob_moduleId = argValue
END FUNCTION
}