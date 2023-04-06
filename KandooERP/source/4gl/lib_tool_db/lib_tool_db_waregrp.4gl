##############################################################################################
#TABLE salesperson
##############################################################################################

##########################################################
# GLOBAL Scope Variables
##########################################################
GLOBALS "../common/glob_GLOBALS.4gl"

############################################################
# FUNCTION db_salesperson_get_count()
#
# Return total number of rows in salesperson FROM current company
############################################################
FUNCTION db_waregrp_get_count()
	DEFINE ret INT

	SQL
		SELECT count(*) 
		INTO $ret 
		FROM waregrp 
		WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code		
	END SQL
		
	RETURN ret
END FUNCTION