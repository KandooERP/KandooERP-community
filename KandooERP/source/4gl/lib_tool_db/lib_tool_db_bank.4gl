########################################################################################################################
# TABLE bank
#
#
########################################################################################################################

##########################################################
# GLOBAL Scope Variables
##########################################################
GLOBALS "../common/glob_GLOBALS.4gl"


############################################################
# FUNCTION db_bank_pk_exists(p_ui,p_bank_code)
#
# Validate PK - Unique
############################################################
#	CONSTANT UI_OFF SMALLINT = 0
#	CONSTANT UI_ON SMALLINT = 1
#	CONSTANT UI_FK SMALLINT = 2
#	CONSTANT UI_PK SMALLINT = 3
############################################################
FUNCTION db_bank_pk_exists(p_ui_mode,p_op_mode,p_bank_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_op_mode SMALLINT	
	DEFINE p_bank_code LIKE bank.bank_code
	DEFINE l_ret BOOLEAN
	DEFINE l_recCount INT
	DEFINE msgStr STRING

	IF p_bank_code IS NULL THEN
		IF p_ui_mode >= UI_ON THEN
			ERROR "Vendor Bank Code can not be empty"
			#LET msgresp = kandoomsg("G",9178,"")
			#9178 Bank/State/Branchs must NOT be NULL
		END IF
		RETURN FALSE
	END IF

	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
		SQL
			SELECT count(*) 
			INTO $l_recCount 
			FROM bank 
			WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code				
			AND bank.bank_code = $p_bank_code  
		END SQL
	
		
	IF l_recCount > 0 THEN
		LET l_ret = TRUE	
		
		CASE p_op_mode
			WHEN MODE_INSERT
				CASE p_ui_mode
					WHEN UI_PK
						ERROR "Vendor Invoices Code already exists! (", trim(p_bank_code), ")"
					WHEN UI_FK
						#No MESSAGE
					OTHERWISE
						#No MESSAGE
				END CASE				

			WHEN MODE_UPDATE
				CASE p_ui_mode
					WHEN UI_PK
						#No MESSAGE
					WHEN UI_FK
						--MESSAGE "Vendor Bank Code does exist - (", trim(p_bank_code), ")"
					OTHERWISE
						#No MESSAGE
				END CASE
			
			WHEN MODE_DELETE
				CASE p_ui_mode
					WHEN UI_PK
						#No MESSAGE
					WHEN UI_FK
						MESSAGE "Vendor Bank Code does exist - (", trim(p_bank_code), ")"
					OTHERWISE
						#No MESSAGE
				END CASE
					
		END CASE
	ELSE #NOT FOUND / EXIST
		LET l_ret = FALSE	
		CASE p_op_mode		
			WHEN MODE_INSERT
				CASE p_ui_mode
					WHEN UI_PK
						#No MESSAGE
					WHEN UI_FK
						ERROR "Vendor Bank Code does not exist! (", trim(p_bank_code), ")"
					OTHERWISE
						#No MESSAGE
				END CASE

			WHEN MODE_UPDATE
				CASE p_ui_mode
					WHEN UI_PK
						ERROR "Vendor Bank Code does not exist! (", trim(p_bank_code), ")"
					WHEN UI_FK
						#No MESSAGE
					OTHERWISE
						#No MESSAGE
				END CASE

			WHEN MODE_DELETE
				CASE p_ui_mode
					WHEN UI_PK
						ERROR "Vendor Bank Code does not exist! (", trim(p_bank_code), ")"
					WHEN UI_FK
						#No MESSAGE
					OTHERWISE
						#No MESSAGE
				END CASE
		END CASE	
	END IF
	
	RETURN l_ret
END FUNCTION
############################################################
# END FUNCTION db_bank_pk_exists(p_ui,p_bank_code)
############################################################


############################################################
# FUNCTION db_bank_get_count()
#
# Return total number of rows in product 
############################################################
FUNCTION db_bank_get_count()
	DEFINE l_ret INT

	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

	SELECT count(*) 
	INTO l_ret 
	FROM bank 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code				
			
	RETURN l_ret
END FUNCTION
############################################################
# END FUNCTION db_bank_get_count()
############################################################


############################################################
# FUNCTION db_bank_get_rec(p_ui_mode,p_bank_code)
# RETURN l_rec_bank.*
# Get bank/Part record
############################################################
FUNCTION db_bank_get_rec(p_ui_mode,p_bank_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_bank_code LIKE bank.bank_code
	DEFINE l_rec_bank RECORD LIKE bank.*

	IF p_bank_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Can not retrieve record with empty Bank Account Code"
		END IF
		RETURN NULL
	END IF

	SELECT *
	INTO l_rec_bank.*
	FROM bank
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code		        
	AND bank_code = p_bank_code
	
	IF sqlca.sqlcode != 0 THEN   		  
		INITIALIZE l_rec_bank.* TO NULL                                                                                      
	ELSE		                                                                                                                    
		#		                                                                                                
	END IF	         

	RETURN l_rec_bank.*		                                                                                                
END FUNCTION	
############################################################
# END FUNCTION db_bank_get_rec(p_ui_mode,p_bank_code)
############################################################


############################################################
# FUNCTION db_bank_get_bic_count(p_bic_code)
#
# Return total number of rows in bic 
############################################################
FUNCTION db_bank_get_bic_count(p_bic_code)
	DEFINE p_bic_code LIKE bank.bic_code
	DEFINE l_ret INT
	
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

	SELECT count(*) 
	INTO l_ret 
	FROM bank 
	WHERE bic_code = p_bic_code
	
	RETURN l_ret
END FUNCTION
############################################################
# END FUNCTION db_bank_get_bic_count(p_bic_code)
############################################################


############################################################
# FUNCTION db_bank_get_name_acct_text(p_ui_mode,p_bank_code)
# RETURN l_ret_name_acct_text 
#
# Get description text of bank record
############################################################
FUNCTION db_bank_get_name_acct_text(p_ui_mode,p_bank_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_bank_code LIKE bank.bank_code
	DEFINE l_ret_name_acct_text LIKE bank.name_acct_text

	IF p_bank_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN	
			ERROR "Bank Code can NOT be empty"
		END IF
			RETURN NULL
	END IF

	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

	SELECT name_acct_text 
	INTO l_ret_name_acct_text 
	FROM bank
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code				 
	AND bank.bank_code = p_bank_code  		
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Bank Description with Code ",trim(p_bank_code),  "NOT found"
		END IF			
		LET l_ret_name_acct_text = NULL
	ELSE
		#
	END IF	
	RETURN l_ret_name_acct_text
END FUNCTION
############################################################
# END FUNCTION db_bank_get_name_acct_text(p_ui_mode,p_bank_code)
############################################################


############################################################
# FUNCTION db_bank_get_iban(p_ui_mode,p_bank_code)
# RETURN l_ret_iban 
#
# Get description text of bank record
############################################################
FUNCTION db_bank_get_iban(p_ui_mode,p_bank_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_bank_code LIKE bank.bank_code
	DEFINE l_ret_iban LIKE bank.iban

	IF p_bank_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN	
			ERROR "Bank Code can NOT be empty"
		END IF
			RETURN NULL
	END IF

	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

	SELECT iban 
	INTO l_ret_iban 
	FROM bank
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code				 
	AND bank.bank_code = p_bank_code  		
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Bank Description with Code ",trim(p_bank_code),  "NOT found"
		END IF			
		LET l_ret_iban = NULL
	ELSE
		#
	END IF	
	RETURN l_ret_iban
END FUNCTION
############################################################
# END FUNCTION db_bank_get_iban(p_ui_mode,p_bank_code)
############################################################


############################################################
# FUNCTION db_bank_get_bic_code(p_ui_mode,p_bank_code)
# RETURN l_ret_bic_code 
#
# Get description text of bank record
############################################################
FUNCTION db_bank_get_bic_code(p_ui_mode,p_bank_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_bank_code LIKE bank.bank_code
	DEFINE l_ret_bic_code LIKE bank.bic_code

	IF p_bank_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN	
			ERROR "Bank Code can NOT be empty"
		END IF
			RETURN NULL
	END IF

	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
		SQL
			SELECT bic_code 
			INTO $l_ret_bic_code 
			FROM bank
			WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code				 
			AND bank.bank_code = $p_bank_code  		
		END SQL
	
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Bank Description with Code ",trim(p_bank_code),  "NOT found"
		END IF			
		LET l_ret_bic_code = NULL
	ELSE
		#
	END IF	
	RETURN l_ret_bic_code
END FUNCTION
############################################################
# END FUNCTION db_bank_get_bic_code(p_ui_mode,p_bank_code)
############################################################


############################################################
# FUNCTION db_bank_get_sheet_num(p_ui_mode,p_bank_code)
# RETURN l_ret_sheet_num 
#
# Get description text of bank record
############################################################
FUNCTION db_bank_get_sheet_num(p_ui_mode,p_bank_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_bank_code LIKE bank.bank_code
	DEFINE l_ret_sheet_num LIKE bank.sheet_num

	IF p_bank_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN	
			ERROR "Bank Code can NOT be empty"
		END IF
			RETURN NULL
	END IF

	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

	SELECT sheet_num 
	INTO l_ret_sheet_num 
	FROM bank
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code				 
	AND bank.bank_code = p_bank_code  		

	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Bank Description with Code ",trim(p_bank_code),  "NOT found"
		END IF			
		LET l_ret_sheet_num = NULL
	ELSE
		#
	END IF	
	RETURN l_ret_sheet_num
END FUNCTION
############################################################
# END FUNCTION db_bank_get_sheet_num(p_ui_mode,p_bank_code)
############################################################


############################################################
# FUNCTION db_bank_get_state_bal_amt(p_ui_mode,p_bank_code)
# RETURN l_ret_state_bal_amt 
#
# Get description text of bank record
############################################################
FUNCTION db_bank_get_state_bal_amt(p_ui_mode,p_bank_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_bank_code LIKE bank.bank_code
	DEFINE l_ret_state_bal_amt LIKE bank.state_bal_amt

	IF p_bank_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN	
			ERROR "Bank Code can NOT be empty"
		END IF
			RETURN NULL
	END IF

	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

	SELECT state_bal_amt 
	INTO l_ret_state_bal_amt 
	FROM bank
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code				 
	AND bank.bank_code = p_bank_code  		
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Bank Description with Code ",trim(p_bank_code),  "NOT found"
		END IF			
		LET l_ret_state_bal_amt = NULL
	ELSE
		#
	END IF	
	RETURN l_ret_state_bal_amt
END FUNCTION
############################################################
# END FUNCTION db_bank_get_state_bal_amt(p_ui_mode,p_bank_code)
############################################################