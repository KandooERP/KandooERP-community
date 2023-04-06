##############################################################################################
#TABLE uom
##############################################################################################

##########################################################
# GLOBAL Scope Variables
##########################################################
GLOBALS "../common/glob_GLOBALS.4gl"

############################################################
# FUNCTION uom_get_full_record(p_uom_code)
#
#
############################################################
FUNCTION uom_get_full_record(p_uom_code)
	DEFINE p_uom_code LIKE uom.uom_code
	DEFINE l_rec_uom RECORD LIKE uom.*

	WHENEVER SQLERROR CONTINUE
      SELECT *
        INTO l_rec_uom.*
        FROM uom
       WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
       	AND uom_code= p_uom_code
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	
	RETURN sqlca.sqlcode,l_rec_uom.*		                                                                                                
END FUNCTION # uom_get_full_record	      

FUNCTION check_prykey_exists_uom(p_cmpy_code,p_uom_code)
	DEFINE p_cmpy_code LIKE uom.cmpy_code
	DEFINE p_uom_code LIKE uom.uom_code
	DEFINE prykey_exists BOOLEAN
	# initialize prykey_exists to false. If key is found, it is set to 'true'
	LET prykey_exists = FALSE
	SELECT TRUE
	INTO prykey_exists
	FROM uom
	WHERE cmpy_code = p_cmpy_code
	AND uom_code = p_uom_code 

	RETURN prykey_exists
END FUNCTION #check_prykey_exists_uom()

# This function returns the uom description
FUNCTION db_get_desc_uom(p_cmpy_code,p_uom_code)
	DEFINE p_cmpy_code LIKE uom.cmpy_code
	DEFINE p_uom_code LIKE uom.uom_code
	DEFINE l_uom_desc LIKE uom.desc_text
	DEFINE p_set_isolation_mode PREPARED
	LET l_uom_desc = NULL

	SET ISOLATION TO DIRTY READ
	SELECT desc_text INTO l_uom_desc
	FROM uom
	WHERE cmpy_code = p_cmpy_code
	AND uom_code = p_uom_code

	IF sqlca.sqlcode = 0 THEN
		CALL reset_isolation_mode()	#  reset to default isolation mode
		RETURN l_uom_desc,1
	ELSE
		CALL reset_isolation_mode()	#  reset to default isolation mode
		RETURN l_uom_desc,0
	END IF
	
END FUNCTION # db_get_desc_uom
