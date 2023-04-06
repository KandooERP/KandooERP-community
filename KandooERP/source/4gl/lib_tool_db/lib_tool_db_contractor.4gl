############################################################
# FUNCTION contractor_get_full_record(p_vend_code)
#
#
############################################################
FUNCTION contractor_get_full_record(p_vend_code)
	DEFINE p_vend_code LIKE contractor.vend_code
	DEFINE l_rec_contractor RECORD LIKE contractor.*

	WHENEVER SQLERROR CONTINUE
      SELECT *
        INTO l_rec_contractor.*
        FROM contractor
       WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
       	AND vend_code= p_vend_code
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	RETURN sqlca.sqlcode,l_rec_contractor.*		                                                                                                
END FUNCTION # contractor_get_full_record	      

FUNCTION check_prykey_exists_contractor(p_cmpy_code,p_vend_code)
	DEFINE p_cmpy_code LIKE contractor.cmpy_code
	DEFINE p_vend_code LIKE contractor.vend_code
	DEFINE prykey_exists BOOLEAN
	# initialize prykey_exists to false. If key is found, it is set to 'true'
	LET prykey_exists = FALSE
	SELECT TRUE
	INTO prykey_exists
	FROM contractor
	WHERE cmpy_code = p_cmpy_code
	AND vend_code = p_vend_code 

	RETURN prykey_exists
END FUNCTION #check_prykey_exists_contractor()
