########################################################################################################################
# TABLE country
# NOTE: This Module is linked with lib_tool (not lib_tool_db) because it is required by ALL programs i.e. due to authentication
########################################################################################################################

##########################################################
# GLOBAL Scope Variables
##########################################################
GLOBALS "../common/glob_GLOBALS.4gl"


############################################################
# FUNCTION db_country_get_count()
#
# Return total number of rows in country 
############################################################
FUNCTION db_country_get_count()
	DEFINE l_ret INT

	SELECT count(*) 
	INTO l_ret 
	FROM country 
		
	RETURN l_ret
END FUNCTION
############################################################
# END FUNCTION db_country_get_count()
############################################################


############################################################
# FUNCTION db_country_pk_exists(p_ui_mode,p_op_mode,p_country_code)
#
# Validate PK - Unique
------------------------------------------------------------
#	CONSTANT UI_OFF SMALLINT = 0
#	CONSTANT UI_FK SMALLINT = 2
#	CONSTANT UI_PK SMALLINT = 3
############################################################
FUNCTION db_country_pk_exists(p_ui_mode,p_op_mode,p_country_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_op_mode SMALLINT	
	DEFINE p_country_code LIKE country.country_code
	DEFINE l_ret INT
	DEFINE l_recCount INT
	
	IF p_country_code IS NULL THEN
		IF p_ui_mode >= UI_ON THEN
			ERROR "Country Code can not be empty/NULL"
		END IF
		RETURN -11
	END IF

	SELECT count(*) 
	INTO l_recCount 
	FROM country 
	WHERE country.country_code = p_country_code   		
	
	IF l_recCount > 0 THEN #PK exists
		LET l_ret = 1
		#Messages depend on UI_MODE on/off and the operation mode insert, update, delete	
		CASE p_op_mode
			WHEN MODE_INSERT
				CASE p_ui_mode
					WHEN UI_PK
						ERROR "Country Code already exists! (", trim(p_country_code), ")"
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
						#ERROR "Country Code already exists! (", trim(p_country_code), ")"
					OTHERWISE
						#No MESSAGE
				END CASE
			
			WHEN MODE_DELETE
				CASE p_ui_mode
					WHEN UI_PK
						#No MESSAGE
					WHEN UI_FK
						#ERROR "Country Code already exists! (", trim(p_country_code), ")"
					OTHERWISE
						#No MESSAGE
				END CASE
				
			OTHERWISE #i.e. NULL
				CASE p_ui_mode
					WHEN UI_PK
						ERROR "Country Code already exists! (", trim(p_country_code), ")"
					WHEN UI_FK
						#ERROR "Country Code already exists! (", trim(p_country_code), ")"
					OTHERWISE
						#No MESSAGE
				END CASE							
		END CASE
		
	ELSE #PK does not exist
	
		LET l_ret = FALSE	
		CASE p_op_mode		
			WHEN MODE_INSERT
				CASE p_ui_mode
					WHEN UI_PK
						#No MESSAGE
					WHEN UI_FK
						#ERROR "Country Code already exists! (", trim(p_country_code), ")"
					OTHERWISE
						#No MESSAGE
				END CASE

			WHEN MODE_UPDATE
				CASE p_ui_mode
					WHEN UI_PK
						ERROR "Country Code already exists! (", trim(p_country_code), ")"
					WHEN UI_FK
						ERROR "Country Code does not exists! (", trim(p_country_code), ")" #No MESSAGE
					OTHERWISE
						#No MESSAGE
				END CASE

			WHEN MODE_DELETE
				CASE p_ui_mode
					WHEN UI_PK
						ERROR "Country Code already exists! (", trim(p_country_code), ")"
					WHEN UI_FK
						#No MESSAGE
					OTHERWISE
						#No MESSAGE
				END CASE

			OTHERWISE #i.e. NULL
				CASE p_ui_mode
					WHEN UI_PK
						#ERROR "Country Code already exists! (", trim(p_country_code), ")"
					WHEN UI_FK
						ERROR "Country Code does not exists! (", trim(p_country_code), ")"
					OTHERWISE
						#No MESSAGE
				END CASE		

		END CASE	
	END IF
	
	RETURN l_ret
END FUNCTION
############################################################
# END FUNCTION db_country_pk_exists(p_ui_mode,p_op_mode,p_country_code)
############################################################


############################################################
# FUNCTION db_country_get_rec(p_country_code)
#
#
############################################################
FUNCTION db_country_get_rec(p_country_code)
	DEFINE p_country_code LIKE country.country_code
	DEFINE l_rec_country RECORD LIKE country.*

  SELECT *
    INTO l_rec_country.*
    FROM country
   WHERE country_code = p_country_code

	IF sqlca.sqlcode != 0 THEN   		                                                                                        
		RETURN -1	                                                                                              	
	ELSE		                                                                                                                    
		RETURN l_rec_country.*		                                                                                                
	END IF	         
END FUNCTION	
############################################################
# END FUNCTION db_country_get_rec(p_country_code)
############################################################


############################################################
# FUNCTION db_country_get_country_text(p_ui_mode,p_country_code)
# RETURN l_ret_country_tex
#
# Get country name by country code
############################################################
FUNCTION db_country_get_country_text(p_ui_mode,p_country_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_country_code LIKE country.country_code
	DEFINE l_ret_country_text LIKE country.country_text

	IF p_country_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN 
			ERROR "country Code can NOT be empty"
		END IF
		RETURN NULL
	END IF
			
	SELECT country_text 
	INTO l_ret_country_text 
	FROM country 
	WHERE country.country_code = p_country_code  		

	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN 
			ERROR "Country Language with Code ",trim(p_country_code),  "NOT found"
		END IF
		RETURN NULL
	ELSE
		RETURN l_ret_country_text	                                                                                                
	END IF	
END FUNCTION
############################################################
# END FUNCTION db_country_get_country_text(p_ui_mode,p_country_code)
############################################################


############################################################
# FUNCTION db_country_get_language_code(p_ui_mode,p_country_code)
# RETURN l_ret_limit_amt
#
# Get limit_amt FROM country record
############################################################
FUNCTION db_country_get_language_code(p_ui_mode,p_country_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_country_code LIKE country.country_code
	DEFINE l_ret_language_code LIKE country.language_code

	IF p_country_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN 
			ERROR "country Code can NOT be empty"
		END IF
		RETURN NULL
	END IF
		
	SELECT language_code 
	INTO l_ret_language_code 
	FROM country 
	WHERE country.country_code = p_country_code  		

	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN 
			ERROR "Country Language with Code ",trim(p_country_code),  "NOT found"
		END IF
		RETURN NULL
	ELSE
		RETURN l_ret_language_code	                                                                                                
	END IF	
END FUNCTION
############################################################
# END FUNCTION db_country_get_language_code(p_ui_mode,p_country_code)
############################################################


############################################################
# FUNCTION db_country_get_state_code_text(p_country_code)
# RETURN l_ret_state_code_text
#
# Return what a state/county/oblast/Bundesland is called in this country
############################################################
FUNCTION db_country_get_state_code_text(p_country_code)
	DEFINE p_country_code LIKE country.country_code
	DEFINE l_ret_state_code_text LIKE country.state_code_text

	IF p_country_code IS NULL THEN

		SELECT state_code_text 
		INTO l_ret_state_code_text 
		FROM country 
		WHERE country.country_code = glob_rec_kandoouser.country_code 

		IF sqlca.sqlcode != 0 THEN
			LET l_ret_state_code_text = "State (Error Kandoouser setup Country)"
		END IF
				
		RETURN l_ret_state_code_text

	END IF
		
	SELECT state_code_text 
	INTO l_ret_state_code_text 
	FROM country 
	WHERE country.country_code = p_country_code 

	IF sqlca.sqlcode != 0 THEN

		SELECT state_code_text 
		INTO l_ret_state_code_text 
		FROM country 
		WHERE country.country_code = glob_rec_kandoouser.country_code 

		IF sqlca.sqlcode != 0 THEN
			LET l_ret_state_code_text = "State (Error Country or Kandoouser setup Country)"
		END IF
		
	END IF	
	
	IF l_ret_state_code_text IS NULL THEN
		LET l_ret_state_code_text = "State (NF)"
	END IF
	
	RETURN l_ret_state_code_text 

END FUNCTION
############################################################
# END FUNCTION db_country_get_state_code_text(p_country_code)
############################################################


############################################################
# FUNCTION db_country_get_post_code_text(p_country_code)
# RETURN l_ret_post_code_text
#
# Return what a state/county/oblast/Bundesland is called in this country
############################################################
FUNCTION db_country_get_post_code_text(p_country_code)
	DEFINE p_country_code LIKE country.country_code
	DEFINE l_ret_post_code_text LIKE country.post_code_text

	IF p_country_code IS NULL THEN

		SELECT post_code_text 
		INTO l_ret_post_code_text
		FROM country 
		WHERE country.country_code = glob_rec_kandoouser.country_code 

		IF sqlca.sqlcode != 0 THEN
			LET l_ret_post_code_text = "Post Code (Error Kandoouser setup Country)"
		END IF
				
		RETURN l_ret_post_code_text

	END IF

	SELECT post_code_text 
	INTO l_ret_post_code_text 
	FROM country 
	WHERE country.country_code = p_country_code 

	IF sqlca.sqlcode != 0 THEN
		SELECT post_code_text 
		INTO l_ret_post_code_text
		FROM country 
		WHERE country.country_code = glob_rec_kandoouser.country_code 

		IF sqlca.sqlcode != 0 THEN
			LET l_ret_post_code_text = "Post Code (Error Country or Kandoouser setup Country)"
		END IF
				
	END IF

	IF l_ret_post_code_text IS NULL THEN
		LET l_ret_post_code_text = "Post Code"
	END IF
			
	RETURN l_ret_post_code_text 
	
END FUNCTION
############################################################
# END FUNCTION db_country_get_post_code_text(p_country_code)
############################################################


########################################################################################################################
# 
# UPDATE INSERT DELETE row from DB
#
########################################################################################################################


############################################################
# FUNCTION db_country_update(p_rec_country)
#
#
############################################################
FUNCTION db_country_update(p_rec_country)
	DEFINE p_rec_country RECORD LIKE country.*

	UPDATE country
	SET * = p_rec_country.*
	WHERE country_code = p_rec_country.country_code

	RETURN sqlca.sqlcode
END FUNCTION        
############################################################
# END FUNCTION db_country_update(p_rec_country)
############################################################

   
############################################################
# FUNCTION db_country_insert(p_rec_country)
#
#
############################################################
FUNCTION db_country_insert(p_rec_country)
	DEFINE p_rec_country RECORD LIKE country.*

	INSERT INTO country
   VALUES(p_rec_country.*)

	RETURN sqlca.sqlcode
END FUNCTION
############################################################
# END FUNCTION db_country_insert(p_rec_country)
############################################################


############################################################
# FUNCTION db_country_delete(p_country_code)
#
#
############################################################
FUNCTION db_country_delete(p_ui_mode,p_confirm,p_country_code)
	DEFINE p_ui_mode SMALLINT #with UI messages or silent
	DEFINE p_confirm BOOLEAN #is operator requested to confirm this operation / independent of ui mode
	DEFINE p_country_code LIKE country.country_code
	DEFINE l_msgresp LIKE language.yes_flag	
	DEFINE l_msg_str STRING

	IF p_confirm = UI_CONFIRM_ON THEN
		LET l_msg_str = "Delete Country", trim(p_country_code), " ?"
		IF NOT promptTF("Delete Country",l_msg_str,TRUE) THEN
			RETURN -10
		END IF
	END IF
	
	IF p_country_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET l_msg_str = "Country Code can not be empty !"   
			ERROR l_msg_str
		END IF
		RETURN -1
	END IF

	DELETE FROM country
	WHERE country_code = p_country_code

	IF sqlca.sqlcode != 0 THEN   		                                                                                        
--		LET l_sql_stmt_status = -1		 
		ERROR "Could not delete country (country)"
--	ELSE		                                                                                                                    
--		LET l_sql_stmt_status=0		                                                                                                
	END IF		             
	                                                                                                     
	RETURN sqlca.sqlcode	
		  
END FUNCTION
############################################################
# END FUNCTION db_country_delete(p_country_code)
############################################################
	
	
############################################################
# FUNCTION db_country_localize(p_country_code)	
#	RETURN VOID
#
# Localize form elements state listBox, label for state and postcode
############################################################
FUNCTION db_country_localize(p_country_code)
	DEFINE p_country_code LIKE country.country_code
	
	IF p_country_code IS NULL THEN #default country code is always user/operator country code if nothing else was used/found
		LET p_country_code = get_ku_country_code()
	END IF
	
	CALL comboList_state("state_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,p_country_code,COMBO_NULL_SPACE) 

	#Display localized names for state/county/oblast and ZIP/post code, Postleitzahl
	WHENEVER ERROR CONTINUE

	DISPLAY LSTR(db_country_get_state_code_text(p_country_code)) TO lb_state
	DISPLAY LSTR(db_country_get_post_code_text(p_country_code)) TO lb_postCode 
	DISPLAY LSTR(db_country_get_post_code_text(p_country_code)) TO lb_postCode2 #Note:Some forms have got 2 postcode fields/lablels i.e. delivery from / to addresses

	WHENEVER ERROR STOP
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
		
END FUNCTION
############################################################
# END FUNCTION db_country_localize(p_country_code)	
############################################################