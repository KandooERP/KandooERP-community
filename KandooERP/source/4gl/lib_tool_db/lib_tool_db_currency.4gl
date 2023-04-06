##############################################################################################
# TABLE currency
# NOTE: This Module is linked with lib_tool (not lib_tool_db) because it is required by ALL programs i.e. due to authentication
##############################################################################################

##########################################################
# GLOBAL Scope Variables
##########################################################
GLOBALS "../common/glob_GLOBALS.4gl"

############################################################
# FUNCTION db_currency_get_count()
#
# Return total number of rows in currency FROM current company
############################################################
FUNCTION db_currency_get_count()
	DEFINE ret INT
	SQL
		SELECT count(*) INTO $ret FROM currency 
	END SQL
	RETURN ret
END FUNCTION


############################################################
# FUNCTION db_currency_pk_exists(p_currency_code)
#
# Validate PK - Unique
############################################################
FUNCTION db_currency_pk_exists(p_ui_mode,p_op_mode,p_currency_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_op_mode SMALLINT	
	DEFINE p_currency_code LIKE currency.currency_code
	DEFINE l_ret BOOLEAN
	DEFINE l_recCount INT

	IF p_currency_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Currency Code can not be empty"	#LET msgresp = kandoomsg("G",9178,"")	#9178 Bank/State/Branchs must NOT be NULL
		END IF
		RETURN FALSE
	END IF
			
	SELECT count(*) 
	INTO l_recCount 
	FROM currency 
	WHERE currency.currency_code = p_currency_code		
	
	IF l_recCount > 0 THEN
		LET l_ret = TRUE	
		CASE p_op_mode
			WHEN MODE_INSERT
				CASE p_ui_mode
					WHEN UI_PK
						ERROR "PATs Code already exists! (", trim(p_currency_code), ")"
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
						ERROR "Currency Code does not exist! (", trim(p_currency_code), ")"
					OTHERWISE
						#No MESSAGE
				END CASE
			
			WHEN MODE_DELETE
				CASE p_ui_mode
					WHEN UI_PK
						#No MESSAGE
					WHEN UI_FK
						ERROR "Currency Code does not exist! (", trim(p_currency_code), ")"
					OTHERWISE
						#No MESSAGE
				END CASE
					
		END CASE
	ELSE
		LET l_ret = FALSE	
		CASE p_op_mode		
			WHEN MODE_INSERT
				CASE p_ui_mode
					WHEN UI_PK
						#No MESSAGE
					WHEN UI_FK
						ERROR "Currency Code does not exist! (", trim(p_currency_code), ")"
					OTHERWISE
						#No MESSAGE
				END CASE

			WHEN MODE_UPDATE
				CASE p_ui_mode
					WHEN UI_PK
						ERROR "Currency Code does not exist! (", trim(p_currency_code), ")"
					WHEN UI_FK
						#No MESSAGE
					OTHERWISE
						#No MESSAGE
				END CASE

			WHEN MODE_DELETE
				CASE p_ui_mode
					WHEN UI_PK
						ERROR "Currency Code does not exist! (", trim(p_currency_code), ")"
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
# FUNCTION db_currency_get_rec(p_currency_code)
#
# Return currency record matching PK currency_code
############################################################
FUNCTION db_currency_get_rec(p_currency_code)
	DEFINE p_currency_code LIKE currency.currency_code
	DEFINE l_ret_rec_currency RECORD LIKE currency.*
	DEFINE l_msgresp LIKE language.yes_flag 

	IF p_currency_code IS NULL THEN
		ERROR "Vendor Type Code can NOT be empty"
		RETURN NULL
	END IF
		
	SQL
		SELECT * 
		INTO $l_ret_rec_currency 
		FROM currency 
		WHERE currency.currency_code = $p_currency_code  		
	END SQL

	IF sqlca.sqlcode != 0 THEN 
		ERROR "Vendor Type Record with Code ",trim(p_currency_code),  "NOT found"
		ERROR kandoomsg2("P",9026,"")#P9026 " Hold Code NOT found, try window"		
		INITIALIZE l_ret_rec_currency.* TO NULL	
		RETURN NULL
	ELSE
		RETURN l_ret_rec_currency.*		                                                                                                
	END IF			
END FUNCTION		


############################################################
# FUNCTION db_currency_get_desc_text(p_ui_mode,p_currency_code)
# RETURN l_ret_desc_text
#
# Get desc_text FROM currency record
############################################################
FUNCTION db_currency_get_desc_text(p_ui_mode,p_currency_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_currency_code LIKE currency.currency_code
	DEFINE l_ret_desc_text LIKE currency.desc_text

	IF p_currency_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Currency Code can NOT be empty"
		END IF
		RETURN NULL
	END IF
		
	SQL
		SELECT desc_text 
		INTO $l_ret_desc_text 
		FROM currency 
		WHERE currency.currency_code = $p_currency_code 
	END SQL

	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Currency Description with Code ",trim(p_currency_code),  "NOT found"
		END IF
		RETURN NULL
	ELSE
		RETURN l_ret_desc_text 
	END IF	
END FUNCTION


############################################################
# FUNCTION db_currency_get_symbol_text(p_currency_code)
# RETURN l_ret_symbol_text
#
# Get symbol_text FROM currency record
############################################################
FUNCTION db_currency_get_symbol_text(p_currency_code)
	DEFINE p_currency_code LIKE currency.currency_code
	DEFINE l_ret_symbol_text LIKE currency.symbol_text

	IF p_currency_code IS NULL THEN
		ERROR "Currency Code can NOT be empty"
		RETURN NULL
	END IF
		
	SQL
		SELECT symbol_text 
		INTO $l_ret_symbol_text 
		FROM currency 
		WHERE currency.currency_code = $p_currency_code 
	END SQL

	IF SQLCA.SQLCODE != 0 THEN
		ERROR "Currency Description with Code ",trim(p_currency_code),  "NOT found"
		RETURN NULL
	ELSE
		RETURN l_ret_symbol_text
	END IF	
END FUNCTION		