##############################################################################################
#TABLE stnd_grp
##############################################################################################

##########################################################
# GLOBAL Scope Variables
##########################################################
GLOBALS "../common/glob_GLOBALS.4gl"

############################################################
# FUNCTION db_stnd_grp_get_count()
#
# Return total number of rows in stnd_grp FROM current company
############################################################
FUNCTION db_stnd_grp_get_count()
	DEFINE ret INT

	SQL
		SELECT count(*) 
		INTO $ret 
		FROM stnd_grp 
		WHERE stnd_grp.cmpy_code = $glob_rec_kandoouser.cmpy_code		
	END SQL

	RETURN ret
END FUNCTION