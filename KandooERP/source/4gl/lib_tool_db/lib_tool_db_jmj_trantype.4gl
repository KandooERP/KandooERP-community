##############################################################################################
#TABLE jmj_trantype
##############################################################################################

##########################################################
# GLOBAL Scope Variables
##########################################################
GLOBALS "../common/glob_GLOBALS.4gl"


############################################################
# FUNCTION db_jmj_trantype_get_count()
#
# Return total number of rows in jmj_trantype FROM current company
############################################################
FUNCTION db_jmj_trantype_get_count()
	DEFINE ret INT

	SQL
		SELECT count(*) 
		INTO $ret 
		FROM jmj_trantype 
		WHERE jmj_trantype.cmpy_code = $glob_rec_kandoouser.cmpy_code		
	END SQL
		
	RETURN ret
END FUNCTION