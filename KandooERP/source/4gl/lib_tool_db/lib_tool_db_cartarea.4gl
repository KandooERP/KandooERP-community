##############################################################################################
#TABLE territory
##############################################################################################

##########################################################
# GLOBAL Scope Variables
##########################################################
GLOBALS "../common/glob_GLOBALS.4gl"

FUNCTION db_cartarea_get_count()
	DEFINE ret INT

	SQL
		SELECT count(*) 
		INTO $ret 
		FROM cartarea 
		WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code		
	END SQL	

	RETURN ret
END FUNCTION