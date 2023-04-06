##############################################################################################
#TABLE salearea
##############################################################################################

##########################################################
# GLOBAL Scope Variables
##########################################################
GLOBALS "../common/glob_GLOBALS.4gl"


############################################################
# FUNCTION db_salearea_get_count()
#
# Return total number of rows in salearea FROM current company
############################################################
FUNCTION db_salearea_get_count()
	DEFINE ret INT
	
	SQL
		SELECT count(*) 
		INTO $ret 
		FROM salearea 
		WHERE salearea.cmpy_code = $glob_rec_kandoouser.cmpy_code		
	END SQL

	RETURN ret
END FUNCTION