##############################################################################################
#TABLE loadparms
##############################################################################################

##########################################################
# GLOBAL Scope Variables
##########################################################
GLOBALS "../common/glob_GLOBALS.4gl"


############################################################
# FUNCTION db_loadparms_get_count()
#
# Return total number of rows in loadparms FROM current company
############################################################
FUNCTION db_loadparms_get_count()
	DEFINE ret INT

	SQL
		SELECT count(*) 
		INTO $ret 
		FROM loadparms 
		WHERE loadparms.cmpy_code = $glob_rec_kandoouser.cmpy_code		
	END SQL
		
	RETURN ret
END FUNCTION