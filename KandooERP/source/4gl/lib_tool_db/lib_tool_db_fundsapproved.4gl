########################################################################################################################
# TABLE fundsapproved
#
#
########################################################################################################################

##########################################################
# GLOBAL Scope Variables
##########################################################
GLOBALS "../common/glob_GLOBALS.4gl"



############################################################
# FUNCTION db_fundsapproved_get_count()
#
# Return total number of rows in fundsapproved FROM current company
############################################################
FUNCTION db_fundsapproved_get_count()
	DEFINE ret INT

	SQL
		SELECT count(*) 
		INTO $ret 
		FROM fundsapproved 
		WHERE fundsapproved.cmpy_code = $glob_rec_kandoouser.cmpy_code		
	END SQL
		
	RETURN ret
END FUNCTION

				
############################################################
# FUNCTION db_fundsapproved_pk_exists(p_acct_code)
#
# Validate PK - Unique
############################################################
FUNCTION db_fundsapproved_pk_exists(p_acct_code)
	DEFINE p_acct_code LIKE fundsapproved.acct_code
	DEFINE ret INT

	IF p_acct_code IS NULL THEN
		ERROR "Primary key can not be empty"
		RETURN -1
	END IF
	SQL
		SELECT count(*) 
		INTO $ret 
		FROM fundsapproved 
		WHERE fundsapproved.cmpy_code = $glob_rec_kandoouser.cmpy_code 
		AND fundsapproved.acct_code = $p_acct_code  		
	END SQL
	
	RETURN ret
END FUNCTION


############################################################
# FUNCTION db_fundsapproved_get_rec(p_acct_code)
#
#
############################################################
FUNCTION db_fundsapproved_get_rec(p_acct_code)
	DEFINE p_acct_code LIKE fundsapproved.acct_code
	DEFINE l_rec_fundsapproved RECORD LIKE fundsapproved.*

	SQL
      SELECT *
        INTO $l_rec_fundsapproved.*
        FROM fundsapproved
       WHERE acct_code = $p_acct_code
         AND cmpy_code = $glob_rec_kandoouser.cmpy_code
	END SQL         

	IF sqlca.sqlcode != 0 THEN 		                                                                                        
		RETURN -1	                                                                                              	
	ELSE		                                                                                                                    
		RETURN l_rec_fundsapproved.*		                                                                                                
	END IF	         
END FUNCTION	


############################################################
# FUNCTION db_fundsapproved_get_limit_amt(p_acct_code)
# RETURN l_ret_limit_amt
#
# Get limit_amt FROM fundsapproved record
############################################################
FUNCTION db_fundsapproved_get_limit_amt(p_ui_mode,p_acct_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_acct_code LIKE fundsapproved.acct_code
	DEFINE l_ret_limit_amt LIKE fundsapproved.limit_amt

	IF p_acct_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "fundsapproved Code can NOT be empty"
		END IF
		RETURN NULL
	END IF
		
	SQL
		SELECT limit_amt 
		INTO $l_ret_limit_amt 
		FROM fundsapproved 
		WHERE fundsapproved.cmpy_code = $glob_rec_kandoouser.cmpy_code 
		AND fundsapproved.acct_code = $p_acct_code  		
	END SQL

	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "fundsapproved Description with Code ",trim(p_acct_code),  "NOT found"
		END IF
		RETURN NULL
	ELSE
		RETURN l_ret_limit_amt	                                                                                                
	END IF	
END FUNCTION



########################################################################################################################
# 
# UPDATE INSERT DELETE row from DB
#
########################################################################################################################


############################################################
# FUNCTION db_fundsapproved_update(p_rec_fundsapproved)
#
#
############################################################
FUNCTION db_fundsapproved_update(p_rec_fundsapproved)
	DEFINE p_rec_fundsapproved RECORD LIKE fundsapproved.*

	SQL
		UPDATE fundsapproved
		SET * = $p_rec_fundsapproved.*
		WHERE acct_code = $p_rec_fundsapproved.acct_code
		AND cmpy_code = $glob_rec_kandoouser.cmpy_code
	END SQL

	RETURN STATUS
END FUNCTION        

   
############################################################
# FUNCTION db_fundsapproved_insert(p_rec_fundsapproved)
#
#
############################################################
FUNCTION db_fundsapproved_insert(p_ui_mode,p_rec_fundsapproved)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_rec_fundsapproved RECORD LIKE fundsapproved.*

	IF p_rec_fundsapproved.acct_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Primary key acct_code can not be empty"
		END IF
		RETURN -1
	END IF

	IF p_rec_fundsapproved.cmpy_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Company Code can not be empty"
		END IF
		RETURN -2
	END IF

	IF p_rec_fundsapproved.fund_type_ind IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Fund Type (fund_type_ind) can not be empty"
		END IF
		RETURN -3
	END IF



	IF db_fundsapproved_pk_exists(p_rec_fundsapproved.acct_code) THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Carrier configuartion already exists!"
		END IF
		RETURN -10
	ELSE
		INSERT INTO fundsapproved
    VALUES(p_rec_fundsapproved.*)
	END IF
	
	RETURN STATUS
END FUNCTION


############################################################
# 
# FUNCTION db_fundsapproved_delete(p_acct_code)
#
#
############################################################
FUNCTION db_fundsapproved_delete(p_acct_code)
	DEFINE p_acct_code LIKE fundsapproved.acct_code
	DEFINE l_msgresp LIKE language.yes_flag	
	DEFINE l_sql_stmt_status SMALLINT	


	SQL
	DELETE FROM fundsapproved
	WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code
	AND acct_code = $p_acct_code
	END SQL

	IF sqlca.sqlcode < 0 THEN   		                                                                                        
		LET l_sql_stmt_status = -1		 
		ERROR "Could not delete Approved Funds (fundsapproved)"                                                                                             	
	ELSE		                                                                                                                    
		LET l_sql_stmt_status=0		                                                                                                
	END IF		             
	                                                                                                     
	RETURN l_sql_stmt_status	
		  
END FUNCTION
	
