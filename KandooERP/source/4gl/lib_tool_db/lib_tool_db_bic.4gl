########################################################################################################################
# TABLE bic
#
#
########################################################################################################################

##########################################################
# GLOBAL Scope Variables
##########################################################
GLOBALS "../common/glob_GLOBALS.4gl"				
############################################################
# FUNCTION db_bic_pk_exists(p_ui_mode,p_op_mode,p_bic_code)
#
# Validate PK - Unique
############################################################
#	CONSTANT UI_OFF SMALLINT = 0
#	CONSTANT UI_ON SMALLINT = 1
#	CONSTANT UI_FK SMALLINT = 2
#	CONSTANT UI_PK SMALLINT = 3
############################################################
FUNCTION db_bic_pk_exists(p_ui_mode,p_op_mode,p_bic_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_op_mode SMALLINT		
	DEFINE p_bic_code LIKE bic.bic_code
	DEFINE ret BOOLEAN
	DEFINE recCount INT
	DEFINE msgStr STRING

	IF p_bic_code IS NULL THEN
		IF p_ui_mode >= UI_ON THEN
			ERROR "BIC Code can not be empty"
			#LET msgresp = kandoomsg("G",9178,"")
			#9178 Bank/State/Branchs must NOT be NULL
		END IF
		RETURN FALSE
	END IF

	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	
	SELECT count(*) 
	INTO recCount 
	FROM bic 
	WHERE bic.bic_code = p_bic_code  
		
	IF recCount > 0 THEN
		LET ret = TRUE	
#		IF p_ui = UI_ON THEN
#			MESSAGE "BIC Code exists! (", trim(p_bic_code), ")"
#		END IF
#		IF p_ui = UI_PK THEN
#			MESSAGE "BIC Code already exists! (", trim(p_bic_code), ")"
#		END IF
		
		
		CASE p_op_mode
			WHEN MODE_INSERT
				CASE p_ui_mode
					WHEN UI_PK
						ERROR "BIC Code already exists! (", trim(p_bic_code), ")"
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
						ERROR "BIC Code does not exist! (", trim(p_bic_code), ")"
					OTHERWISE
						#No MESSAGE
				END CASE
			
			WHEN MODE_DELETE
				CASE p_ui_mode
					WHEN UI_PK
						#No MESSAGE
					WHEN UI_FK
						ERROR "BIC Code does not exist! (", trim(p_bic_code), ")"
					OTHERWISE
						#No MESSAGE
				END CASE
					
		END CASE		
		
	ELSE
		LET ret = FALSE	
#		IF p_ui = UI_FK THEN
#			MESSAGE "BIC Code does not exists! (", trim(p_bic_code), ")"
#		END IF
		CASE p_op_mode		
			WHEN MODE_INSERT
				CASE p_ui_mode
					WHEN UI_PK
						#No MESSAGE
					WHEN UI_FK
						ERROR "BIC Code does not exist! (", trim(p_bic_code), ")"
					OTHERWISE
						#No MESSAGE
				END CASE

			WHEN MODE_UPDATE
				CASE p_ui_mode
					WHEN UI_PK
						ERROR "BIC Code does not exist! (", trim(p_bic_code), ")"
					WHEN UI_FK
						#No MESSAGE
					OTHERWISE
						#No MESSAGE
				END CASE

			WHEN MODE_DELETE
				CASE p_ui_mode
					WHEN UI_PK
						ERROR "BIC Code does not exist! (", trim(p_bic_code), ")"
					WHEN UI_FK
						#No MESSAGE
					OTHERWISE
						#No MESSAGE
				END CASE
		END CASE	
				
	END IF
	
	RETURN ret
END FUNCTION
############################################################
# END FUNCTION db_bic_pk_exists(p_ui_mode,p_op_mode,p_bic_code)
############################################################


############################################################
# FUNCTION db_bic_get_count()
#
# Return total number of rows in bic 
############################################################
FUNCTION db_bic_get_count()
	DEFINE ret INT

	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

	SELECT count(*) 
	INTO ret 
	FROM bic 
			
	RETURN ret
END FUNCTION
############################################################
# END FUNCTION db_bic_get_count()
############################################################


############################################################
# FUNCTION db_bic_get_rec(p_ui_mode,p_bic_code)
# RETURN l_rec_bic.*
# Get BIC record
############################################################
FUNCTION db_bic_get_rec(p_ui_mode,p_bic_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_bic_code LIKE bic.bic_code
	DEFINE l_rec_bic RECORD LIKE bic.*

	IF p_bic_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Can not retrieve record with empty BIC code"
		END IF
		RETURN NULL
	END IF

	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

  SELECT *
    INTO l_rec_bic.*
    FROM bic
   WHERE bic_code = p_bic_code
	
	IF sqlca.sqlcode != 0 THEN    		  
		INITIALIZE l_rec_bic.* TO NULL
		    
		IF p_ui_mode != UI_OFF THEN
			ERROR "Can not retrieve record! BIC record with code ", trim(p_bic_code), " not found."
		END IF
				                                                                                  
	ELSE		                                                                                                                    
		#		                                                                                                
	END IF	         

	RETURN l_rec_bic.*		                                                                                                
END FUNCTION	
############################################################
# END FUNCTION db_bic_get_rec(p_ui_mode,p_bic_code)
############################################################


############################################################
# FUNCTION db_bic_get_desc_text(p_ui_mode,p_bic_code)
# RETURN l_ret_desc_text 
#
# Get description text of BIC record
############################################################
FUNCTION db_bic_get_desc_text(p_ui_mode,p_bic_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_bic_code LIKE bic.bic_code
	DEFINE l_ret_desc_text LIKE bic.desc_text

	IF p_bic_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN	
			ERROR "BIC Code can NOT be empty"
		END IF
			RETURN NULL
	END IF

	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

	SELECT desc_text 
	INTO l_ret_desc_text 
	FROM bic 
	WHERE bic.bic_code = p_bic_code  		

	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "BIC Description with Code ",trim(p_bic_code),  "NOT found"
		END IF			
		RETURN NULL
	ELSE
		#
	END IF	
	RETURN l_ret_desc_text
END FUNCTION
############################################################
# END FUNCTION db_bic_get_desc_text(p_ui_mode,p_bic_code)
############################################################


############################################################
# FUNCTION db_bic_get_bank_ref(p_ui_mode,p_bic_code)
# RETURN l_ret_desc_text 
#
# Get description text of BIC record
############################################################
FUNCTION db_bic_get_bank_ref(p_ui_mode,p_bic_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_bic_code LIKE bic.bic_code
	DEFINE l_ret_bank_ref LIKE bic.bank_ref

	IF p_bic_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "BIC Code can NOT be empty"
		END IF
		RETURN NULL
	END IF

	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

	SELECT bank_ref 
	INTO l_ret_bank_ref
	FROM bic 
	WHERE bic.bic_code = p_bic_code  		
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "BIC Bank Reference with BIC Code ",trim(p_bic_code),  "NOT found"
		END IF
		INITIALIZE l_ret_bank_ref TO NULL
	END IF	

	RETURN l_ret_bank_ref	                                                                                                
END FUNCTION
############################################################
# END FUNCTION db_bic_get_bank_ref(p_ui_mode,p_bic_code)
############################################################


########################################################################################################################
# 
# Get Array record data from DB
#
########################################################################################################################

############################################################
# FUNCTION db_bic_get_arr_rec(p_query_text)
#
#
############################################################
FUNCTION db_bic_get_arr_rec(p_query_type,p_query_or_where_text)
	DEFINE p_query_type SMALLINT
	DEFINE p_query_or_where_text VARCHAR(500)
	DEFINE l_query_text VARCHAR(500)
	DEFINE l_where_text VARCHAR(500)
	DEFINE l_arr_rec_bic DYNAMIC ARRAY OF RECORD LIKE bic.*		
	DEFINE l_rec_bic RECORD LIKE bic.*
	DEFINE l_idx SMALLINT
	
	#p_query_text is optional
	CASE p_query_type
		WHEN FILTER_QUERY_OFF
			LET l_query_text = 
				"SELECT * FROM bic ",
				"ORDER BY bic.bic_code" 	


#		WHEN FILTER_QUERY_ON
#			LET l_query_text = p_query_or_where_text

		WHEN FILTER_QUERY_WHERE
			LET l_where_text = p_query_or_where_text
			LET l_query_text = 
				"SELECT * FROM bic ",
				"WHERE ", l_where_text clipped," ",
				"ORDER BY bic.bic_code" 	

		WHEN FILTER_QUERY_SELECT
			LET l_query_text = p_query_or_where_text		
		
		OTHERWISE
			LET l_query_text = 
				"SELECT * FROM bic ",
				"ORDER BY bic.bic_code" 				
	END CASE

	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	PREPARE s_bic FROM l_query_text
	DECLARE c_bic CURSOR FOR s_bic


	LET l_idx = 1
	FOREACH c_bic INTO l_arr_rec_bic[l_idx].*
      LET l_idx = l_idx + 1
      #LET l_arr_rec_bic[l_idx].bic_code = l_rec_bic.bic_code
      #LET l_arr_rec_bic[l_idx].desc_text = l_rec_bic.desc_text
      #LET l_arr_rec_bic[l_idx].post_code = l_rec_bic.post_code
      #LET l_arr_rec_bic[l_idx].bank_ref = l_rec_bic.bank_ref
	END FOREACH
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	
	CALL l_arr_rec_bic.delete(l_idx) --correct/remove last empty row

	IF sqlca.sqlcode < 0 THEN   	
		LET l_arr_rec_bic = NULL	                                                                                        
	ELSE		                                                                                                                    
		#		                                                                                                
	END IF	         

	RETURN l_arr_rec_bic		                                                                                                
END FUNCTION
############################################################
# END FUNCTION db_bic_get_arr_rec(p_query_text)
############################################################


########################################################################################################################
# 
# UPDATE INSERT DELETE row from DB
#
########################################################################################################################


############################################################
# FUNCTION db_bic_update(p_rec_bic)
#
#
############################################################
FUNCTION db_bic_update(p_ui_mode,p_pk_bic_code,p_rec_bic)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_pk_bic_code LIKE bic.bic_code
	DEFINE p_rec_bic RECORD LIKE bic.*
	DEFINE l_ui_mode SMALLINT
	DEFINE ret INT
	DEFINE msgStr STRING
	
	IF p_ui_mode = UI_ON THEN
		LET l_ui_mode = UI_PK
	END IF

	IF p_pk_bic_code IS NULL OR p_rec_bic.bic_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET msgStr = "BIC code can not be empty ! (original BIC=",trim(p_pk_bic_code), " / new BIC=", trim(p_rec_bic.bic_code), ")"  
			ERROR msgStr
		END IF
		RETURN -1
	END IF
	
	IF db_bank_get_bic_count(p_pk_bic_code) AND (p_pk_bic_code <> p_rec_bic.bic_code) THEN #PK bic_code can only be changed if it's not used already
		IF p_ui_mode > 0 THEN
			ERROR "Can not change BIC ! It is already used in a bank configuration"
		END IF
		LET ret =  -1
	ELSE
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

		UPDATE bic
		SET * = p_rec_bic.*
		WHERE bic_code = p_pk_bic_code

		LET ret = status
		
	END IF

	IF p_ui_mode != UI_OFF THEN #display MESSAGE if ui is enabled
		IF ret < 0 THEN   		
			LET msgStr = "Coud not modify BIC record ! /nOriginal BIC", trim(p_pk_bic_code), "New BIC ", trim(p_rec_bic.bic_code),  "\nDatabase Error ", trim(ret)                                                                                        
			#ERROR msgStr 
			CALL fgl_winmessage("Error when trying to modify/update BIC record",msgStr,"error")
		ELSE
			LET msgStr = "BIC record ", trim(p_rec_bic.bic_code), " updated successfully !"   
			MESSAGE msgStr
		END IF                                           	
	END IF	
	
	RETURN ret
END FUNCTION        
############################################################
# END FUNCTION db_bic_update(p_rec_bic)
############################################################

   
############################################################
# FUNCTION db_bic_insert(p_rec_bic)
#
#
############################################################
FUNCTION db_bic_insert(p_ui_mode,p_rec_bic)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_rec_bic RECORD LIKE bic.*
	DEFINE ret INT
	DEFINE l_ui_mode SMALLINT
	DEFINE msgStr STRING	
	
	IF p_ui_mode = UI_ON THEN
		LET l_ui_mode = UI_PK
	END IF

	IF p_rec_bic.bic_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET msgStr = "BIC code can not be empty ! (BIC=", trim(p_rec_bic.bic_code), ")"  
			ERROR msgStr
		END IF
		RETURN -1
	END IF
	
	IF db_bic_pk_exists(UI_PK,MODE_INSERT,p_rec_bic.bic_code) THEN
		LET ret = -1
	ELSE
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
			INSERT INTO bic
	    VALUES(p_rec_bic.*)
	    LET ret = status
		
	END IF

	IF p_ui_mode != UI_OFF THEN #display MESSAGE if ui is enabled
		IF ret < 0 THEN   		
			LET msgStr = "Coud not create BIC record ", trim(p_rec_bic.bic_code), " !\nDatabase Error ", trim(ret)                                                                                        
			#ERROR msgStr 
			CALL fgl_winmessage("Error when trying to create/insert BIC record",msgStr,"error")
		ELSE
			LET msgStr = "BIC record ", trim(p_rec_bic.bic_code), " created successfully !"   
			MESSAGE msgStr
		END IF                                           	
	END IF
	
	RETURN ret
END FUNCTION
############################################################
# END FUNCTION db_bic_insert(p_rec_bic)
############################################################


############################################################
# FUNCTION db_bic_delete(p_ui_mode,p_bic_code)
#
#
############################################################
FUNCTION db_bic_delete(p_ui_mode,p_confirm,p_bic_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_confirm BOOLEAN #is operator requested to confirm this operation / independent of ui mode	
	DEFINE p_bic_code LIKE bic.bic_code
	DEFINE l_msgresp LIKE language.yes_flag	
	DEFINE ret SMALLINT	
	DEFINE msgStr STRING

	IF p_confirm = UI_CONFIRM_ON THEN
		LET msgStr = "Delete BIC configuration ", trim(p_bic_code), " ?"
		IF NOT promptTF("Delete BIC",msgStr,TRUE) THEN
			RETURN -2
		END IF
	END IF
	
	IF p_bic_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET msgStr = "BIC code can not be empty ! (BIC=", trim(p_bic_code), ")"  
			ERROR msgStr
		END IF
		RETURN -1
	END IF

	IF db_bank_get_bic_count(p_bic_code) THEN #PK bic_code can only be deleted if it's not used already
		IF p_ui_mode != UI_OFF THEN
			LET msgStr = "Can not delete BIC ! ", trim(p_bic_code), " It is already used in a bank configuration"
			CALL fgl_winmessage("Can not delete BIC ! ",msgStr,"error")
		END IF
		LET ret =  -1
	ELSE
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

		DELETE FROM bic
		WHERE bic_code = p_bic_code

		LET ret = status
			
	END IF
	
	IF p_ui_mode != UI_OFF THEN #display MESSAGE if ui is enabled
		IF ret < 0 THEN   		
			LET msgStr = "Coud not delete BIC record ", trim(p_bic_code), " !\nDatabase Error ", trim(ret)                                                                                        
			#ERROR msgStr 
			CALL fgl_winmessage("Error when trying to delete",msgStr,"error")
		ELSE
			LET msgStr = "BIC record ", trim(p_bic_code), " deleted !"   
			MESSAGE msgStr
		END IF                                           	
	END IF		             

	RETURN ret	
		  
END FUNCTION
############################################################
# END FUNCTION db_bic_delete(p_ui_mode,p_bic_code)
############################################################

	
############################################################
# FUNCTION db_bic_rec_validation(p_ui_mode,p_op_mode,p_rec_bic)
#
#
#	CONSTANT MODE_INSERT = 1
#	CONSTANT MODE_UPDATE = 2
#	CONSTANT MODE_DELETE = 3
#
#	CONSTANT UI_OFF SMALLINT = 0
#	CONSTANT UI_ON SMALLINT = 1
#	CONSTANT UI_FK SMALLINT = 2
#	CONSTANT UI_PK SMALLINT = 3
############################################################
FUNCTION db_bic_rec_validation(p_ui_mode,p_op_mode,p_rec_bic)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_op_mode SMALLINT
	DEFINE p_rec_bic RECORD LIKE bic.*
	DEFINE l_ret SMALLINT
	DEFINE l_msgStr STRING
	DISPLAY "p_ui_mode=", p_ui_mode
	DISPLAY "p_op_mode=", p_op_mode
	CASE p_op_mode
		WHEN MODE_INSERT
			#bic_code PK
			LET l_msgStr = "Can not create record. BIC Code already exists"  
			IF db_bic_pk_exists(UI_PK,p_op_mode,p_rec_bic.bic_code) THEN
				RETURN -1 #PK Already exists
			END IF		

			#desc_text NOT NULL
			IF p_rec_bic.desc_text IS NULL THEN
				LET l_msgStr =  "Can not create BIC record with empty description text - bic_code: ", trim(p_rec_bic.bic_code)
				IF p_ui_mode > 0 THEN
					ERROR l_msgStr
				END IF				
				RETURN -2
			END IF

			##bank_ref FK -- huho: not sure if this is a FK or just optional text
			#IF NOT db_bank_pk_exists(UI_FK,p_op_mode,p_rec_bic.bank_ref) THEN
			#	LET l_msgStr =  "Can not create BIC record with invalid bank Code: ", trim(p_rec_bic.bank_ref)
			#	IF p_ui_mode > 0 THEN
			#		ERROR l_msgStr
			#	END IF
			#	RETURN -3
			#END IF
				
		WHEN MODE_UPDATE
			#bic_code PK
			IF NOT db_bic_pk_exists(UI_PK,p_op_mode,p_rec_bic.bic_code) THEN
				LET l_msgStr = "Can not update record. BIC Code does not exist!"  			
				RETURN -1 #PK NOT FOUND
			END IF			

			#desc_text NOT NULL
			IF p_rec_bic.desc_text IS NULL THEN
				LET l_msgStr =  "Can not update BIC record with empty description text - bic_code: ", trim(p_rec_bic.bic_code)
				IF p_ui_mode > 0 THEN
					ERROR l_msgStr
				END IF				
				RETURN -2
			END IF

			##bank_ref FK -- huho: not sure if this is a FK or just optional text
			#IF NOT db_bank_pk_exists(UI_FK,p_op_mode,p_rec_bic.bank_ref) THEN
			#	LET l_msgStr =  "Can not update BIC record with invalid GL-bank Code: ", trim(p_rec_bic.bank_ref)
			#	IF p_ui_mode > 0 THEN
			#		ERROR l_msgStr
			#	END IF
			#	RETURN -3
			#END IF
							
		WHEN MODE_DELETE
			#bic_code PK
			IF db_bic_pk_exists(UI_PK,p_op_mode,p_rec_bic.bic_code) THEN
				LET l_msgStr =  "Can not delete BIC record which does not exist - bic_code: ", trim(p_rec_bic.bic_code)
				IF p_ui_mode > 0 THEN
					ERROR l_msgStr
				END IF
				RETURN -1 #PK NOT FOUND
			END IF			
	
	END CASE

	RETURN TRUE	
END FUNCTION	
############################################################
# END FUNCTION db_bic_rec_validation(p_ui_mode,p_op_mode,p_rec_bic)
############################################################