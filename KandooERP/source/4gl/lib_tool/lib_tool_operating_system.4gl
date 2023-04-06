###########################################################################
# Module Scope Variables
###########################################################################
DEFINE ml_os_arch SMALLINT --1=windows ( 0= linux) was a GLOBALS in the original code glob_nt_flag 



###########################################################################
# FUNCTION get_kandooinfo()
#
# Accessor Method for ml_kandooinfo
###########################################################################
FUNCTION get_os_arch() 

	#ml_os_arch = 1 = NT
	#ml_os_arch = 0	= Anything else / Linux based server
	RETURN ml_os_arch 

END FUNCTION 

FUNCTION set_os_arch() 
	IF fgl_arch() = "nt" THEN 
		LET ml_os_arch = 1 
	ELSE 
		LET ml_os_arch = 0 
	END IF 
END FUNCTION 



{

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
		LET ml_kandooinfo_set = TRUE
	END IF
END FUNCTION
}