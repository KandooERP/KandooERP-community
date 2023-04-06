##############################################################################################
#TABLE credreas
##############################################################################################

##########################################################
# GLOBAL Scope Variables
##########################################################
GLOBALS "../common/glob_GLOBALS.4gl"


############################################################
# FUNCTION db_credreas_get_count()
#
# Return total number of rows in credreas FROM current company
############################################################
FUNCTION db_credreas_get_count()
	DEFINE ret INT
	SELECT count(*) 
	INTO ret 
	FROM credreas 
	WHERE credreas.cmpy_code = glob_rec_kandoouser.cmpy_code		
	RETURN ret
END FUNCTION

# get full record, no GUI involved
FUNCTION credreas_get_full_record(p_reason_code)
	DEFINE p_reason_code LIKE credreas.reason_code
	DEFINE l_rec_credreas RECORD LIKE credreas.*

	WHENEVER SQLERROR CONTINUE
      SELECT *
        INTO l_rec_credreas.*
        FROM credreas
       WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
       	AND reason_code= p_reason_code
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	RETURN sqlca.sqlcode,l_rec_credreas.*	
END FUNCTION # category_get_full_record

# get full record, no GUI involved
FUNCTION db_get_desc_credreas(p_reason_code)
	DEFINE p_reason_code LIKE credreas.reason_code
	DEFINE l_reason_text LIKE credreas.reason_text

	WHENEVER SQLERROR CONTINUE
      SELECT reason_text
        INTO l_reason_text
        FROM credreas
       WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
       	AND reason_code= p_reason_code
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	
	RETURN sqlca.sqlcode,l_reason_text	
END FUNCTION # category_get_full_record

FUNCTION check_prykey_exists_credreas(p_cmpy_code,p_reason_code)
	DEFINE p_cmpy_code LIKE credreas.cmpy_code
	DEFINE p_reason_code LIKE credreas.reason_code
	DEFINE prykey_exists BOOLEAN
	# initialize prykey_exists to false. If key is found, it is set to 'true'
	LET prykey_exists = FALSE
	SELECT TRUE
	INTO prykey_exists
	FROM credreas
	WHERE cmpy_code = p_cmpy_code
	AND reason_code = p_reason_code 

	RETURN prykey_exists
END FUNCTION #check_prykey_exists_credreas()
