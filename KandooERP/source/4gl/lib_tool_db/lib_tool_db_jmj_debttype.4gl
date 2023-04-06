##############################################################################################
#TABLE salesmgr
##############################################################################################

##########################################################
# GLOBAL Scope Variables
##########################################################
GLOBALS "../common/glob_GLOBALS.4gl"

############################################################
# FUNCTION db_jmj_debttype_get_count()
#
# Return total number of rows in jmj_debttype FROM current company
############################################################
FUNCTION db_jmj_debttype_get_count()
	DEFINE ret INT

	SQL
		SELECT count(*) 
		INTO $ret 
		FROM jmj_debttype 
		WHERE jmj_debttype.cmpy_code = $glob_rec_kandoouser.cmpy_code		
	END SQL

	RETURN ret
END FUNCTION