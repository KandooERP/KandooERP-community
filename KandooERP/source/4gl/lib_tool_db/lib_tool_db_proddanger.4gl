##############################################################################################
#TABLE proddanger
##############################################################################################

##########################################################
# GLOBAL Scope Variables
##########################################################
GLOBALS "../common/glob_GLOBALS.4gl"

############################################################
# FUNCTION proddanger_get_full_record(p_dg_code)
#
#
############################################################
FUNCTION proddanger_get_full_record(p_dg_code)
	DEFINE p_dg_code LIKE proddanger.dg_code
	DEFINE l_rec_proddanger RECORD LIKE proddanger.*

	WHENEVER SQLERROR CONTINUE
      SELECT *
        INTO l_rec_proddanger.*
        FROM proddanger
       WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
       	AND dg_code= p_dg_code
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	
	RETURN sqlca.sqlcode,l_rec_proddanger.*		                                                                                                
END FUNCTION # proddanger_get_full_record	      

FUNCTION check_prykey_exists_proddanger(p_cmpy_code,p_dg_code)
	DEFINE p_cmpy_code LIKE proddanger.cmpy_code
	DEFINE p_dg_code LIKE proddanger.dg_code
	DEFINE prykey_exists BOOLEAN
	# initialize prykey_exists to false. If key is found, it is set to 'true'
	LET prykey_exists = FALSE
	SELECT TRUE
	INTO prykey_exists
	FROM proddanger
	WHERE cmpy_code = p_cmpy_code
	AND dg_code = p_dg_code 

	RETURN prykey_exists
END FUNCTION #check_prykey_exists_proddanger()

# This function returns the proddanger description
FUNCTION db_get_desc_proddanger(p_cmpy_code,p_dg_code)
	DEFINE p_cmpy_code LIKE proddanger.cmpy_code
	DEFINE p_dg_code LIKE proddanger.dg_code
	DEFINE l_proddanger_desc LIKE proddanger.tech_text
	DEFINE p_set_isolation_mode PREPARED
	LET l_proddanger_desc = NULL

	SET ISOLATION TO DIRTY READ
	SELECT tech_text INTO l_proddanger_desc
	FROM proddanger
	WHERE cmpy_code = p_cmpy_code
	AND dg_code = p_dg_code

	IF sqlca.sqlcode = 0 THEN
		CALL reset_isolation_mode()	#  reset to default isolation mode
		RETURN l_proddanger_desc,1
	ELSE
		CALL reset_isolation_mode()	#  reset to default isolation mode
		RETURN l_proddanger_desc,0
	END IF
	
END FUNCTION # db_get_desc_proddanger
