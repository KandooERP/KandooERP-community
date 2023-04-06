########################################################################################################################
# TABLE cheque
#
#
########################################################################################################################

##########################################################
# GLOBAL Scope Variables
##########################################################
GLOBALS "../common/glob_GLOBALS.4gl"

############################################################
# FUNCTION db_cheque_get_count(p_vend_code)
#
# Return total number of rows in cheque FROM current company
############################################################
FUNCTION db_cheque_get_count(p_vend_code)
	DEFINE p_vend_code LIKE cheque.vend_code
	DEFINE l_ret INT

	IF p_vend_code IS NULL THEN
		ERROR "Vendor cheque Code can NOT be empty"
		RETURN NULL
	END IF

	SQL
		SELECT count(*) 
		INTO $l_ret 
		FROM cheque 
		WHERE cheque.cmpy_code = $glob_rec_kandoouser.cmpy_code	
		AND cheque.vend_code = $p_vend_code	
	END SQL
		
	RETURN l_ret
END FUNCTION


############################################################
# FUNCTION db_cheque_get_count_for_bank_rec_state_num_not_null(p_bank_code)
#
# Return total number of rows in cheque FROM current company
############################################################
FUNCTION db_cheque_get_count_for_bank_rec_state_num_not_null(p_bank_code)
	DEFINE p_bank_code LIKE cheque.bank_code
	DEFINE l_ret INT

	IF p_bank_code IS NULL THEN
		ERROR "Vendor cheque - Bank Code can NOT be empty"
		RETURN NULL
	END IF

	SELECT COUNT(*) 
	INTO l_ret 
	FROM cheque 
	WHERE cheque.cmpy_code = glob_rec_kandoouser.cmpy_code	
	AND cheque.bank_code = p_bank_code	
	AND cheque.rec_state_num IS NOT NULL
		
	RETURN l_ret
END FUNCTION


#SELECT DISTINCT rec_state_num, vend_code FROM cheque WHERE cmpy_code = 'KA' AND bank_code = 'SUNDRY' AND rec_state_num IS NOT NULL ORDER BY rec_state_num ASC
				
############################################################
# FUNCTION db_cheque_pk_exists(p_vend_code,p_cheq_code)
#
# Validate PK - Unique
############################################################
FUNCTION db_cheque_pk_exists(p_vend_code,p_cheq_code)
	DEFINE p_vend_code LIKE cheque.vend_code
	DEFINE p_cheq_code LIKE cheque.cheq_code	
	DEFINE l_ret INT

	SQL
		SELECT count(*) 
		INTO $l_ret 
		FROM cheque 
		WHERE cheque.cmpy_code = $glob_rec_kandoouser.cmpy_code 
		AND cheque.vend_code = $p_vend_code
		AND cheque.cheq_code = $p_cheq_code
		  		
	END SQL
	
	RETURN l_ret
END FUNCTION


############################################################
# FUNCTION db_cheque_get_rec(p_vend_code,p_cheq_code)
#
# Return cheque record matching PK vend_code
############################################################
FUNCTION db_cheque_get_rec(p_vend_code,p_cheq_code)
	DEFINE p_vend_code LIKE cheque.vend_code
	DEFINE p_cheq_code LIKE cheque.cheq_code		
	DEFINE l_ret_rec_cheque RECORD LIKE cheque.*
	DEFINE l_msgresp LIKE language.yes_flag 

	IF p_vend_code IS NULL THEN
		ERROR "Vendor Code can NOT be empty"
		RETURN NULL
	END IF

	IF p_cheq_code IS NULL THEN
		ERROR "Cheque Code can NOT be empty"
		RETURN NULL
	END IF
		
	SQL
		SELECT * 
		INTO $l_ret_rec_cheque 
		FROM cheque 
		WHERE cheque.cmpy_code = $glob_rec_kandoouser.cmpy_code 
		AND cheque.vend_code = $p_vend_code  		
		AND cheque.cheq_code = $p_cheq_code  		
	END SQL

	IF sqlca.sqlcode != 0 THEN 
		ERROR "Vendor cheque record with vendor code ",trim(p_vend_code), " AND cheque code ", trim(p_cheq_code),   " NOT found"
		RETURN NULL
	ELSE
		RETURN l_ret_rec_cheque.*		                                                                                                
	END IF	
END FUNCTION				
