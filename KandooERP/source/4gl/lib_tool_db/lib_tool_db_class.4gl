########################################################################################################################
# TABLE class
#
#
########################################################################################################################

##########################################################
# GLOBAL Scope Variables
##########################################################
GLOBALS "../common/glob_GLOBALS.4gl"
GLOBALS "../common/glob_GLOBALS_userDataTypes.4gl"



############################################################
# FUNCTION db_class_get_count()
#
# Return total number of rows in class 
############################################################
FUNCTION db_class_get_count()
	DEFINE ret INT

	
		SQL
			SELECT count(*) 
			INTO $ret 
			FROM class 
			WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code		
		
		END SQL
	
			
	RETURN ret
END FUNCTION

				
############################################################
# FUNCTION db_class_pk_exists(p_ui,p_class_code)
#
# Validate PK - Unique
############################################################
#	CONSTANT UI_OFF SMALLINT = 0
#	CONSTANT UI_ON SMALLINT = 1
#	CONSTANT UI_FK SMALLINT = 2
#	CONSTANT UI_PK SMALLINT = 3
############################################################
FUNCTION db_class_pk_exists(p_ui,p_class_code)
	DEFINE p_ui SMALLINT
	DEFINE p_class_code LIKE class.class_code
	DEFINE ret BOOLEAN
	DEFINE recCount INT
	DEFINE msgStr STRING

	IF p_class_code IS NULL THEN
		IF p_ui != UI_OFF THEN
			ERROR "CLASS Code can not be empty"
			#LET msgresp = kandoomsg("G",9178,"")
			#9178 Bank/State/Branchs must NOT be NULL
		END IF
		RETURN FALSE
	END IF

	
		SQL
			SELECT count(*) 
			INTO $recCount 
			FROM class
			WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code			
			AND class.class_code = $p_class_code
			  
		END SQL
	
		
	IF recCount <> 0 THEN
		LET ret = TRUE	
		IF p_ui = UI_ON THEN
			MESSAGE "CLASS Code exists! (", trim(p_class_code), ")"
		END IF
		IF p_ui = UI_PK THEN
			MESSAGE "CLASS Code already exists! (", trim(p_class_code), ")"
		END IF
	ELSE
		LET ret = FALSE	
		IF p_ui = UI_FK THEN
			MESSAGE "CLASS Code does not exists! (", trim(p_class_code), ")"
		END IF
	END IF
	
	RETURN ret
END FUNCTION

############################################################
# FUNCTION db_class_get_rec(p_ui_mode,p_class_code)
# RETURN l_rec_class.*
# Get CLASS record
############################################################
FUNCTION db_class_get_rec(p_ui_mode,p_class_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_class_code LIKE class.class_code
	DEFINE l_rec_class RECORD LIKE class.*

	IF p_class_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Can not retrieve record with empty CLASS code"
		END IF
		RETURN NULL
	END IF

	
		SQL
	      SELECT *
	        INTO $l_rec_class.*
	        FROM class
					WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code			
	       AND class_code = $p_class_code
		END SQL         
	
	
	IF sqlca.sqlcode != 0 THEN    		  
		INITIALIZE l_rec_class.* TO NULL                                                                                      
	ELSE		                                                                                                                    
		#		                                                                                                
	END IF	         

	RETURN l_rec_class.*		                                                                                                
END FUNCTION	


############################################################
# FUNCTION db_class_get_desc_text(p_ui_mode,p_class_code)
# RETURN l_ret_desc_text 
#
# Get description text of CLASS record
############################################################
FUNCTION db_class_get_desc_text(p_ui_mode,p_class_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_class_code LIKE class.class_code
	DEFINE l_ret_desc_text LIKE class.desc_text

	IF p_class_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN	
			ERROR "CLASS Code can NOT be empty"
		END IF
			RETURN NULL
	END IF

	
		SQL
			SELECT desc_text 
			INTO $l_ret_desc_text 
			FROM class 
			WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code				
			AND class.class_code = $p_class_code  		
		END SQL
	
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "CLASS Description with Code ",trim(p_class_code),  "NOT found"
		END IF			
		LET l_ret_desc_text = NULL
	ELSE
		#
	END IF	
	RETURN l_ret_desc_text
END FUNCTION

############################################################
# FUNCTION db_class_get_price_level_ind(p_ui_mode,p_class_code)
# RETURN l_ret_desc_text 
#
# Get description text of CLASS record
############################################################
FUNCTION db_class_get_price_level_ind(p_ui_mode,p_class_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_class_code LIKE class.class_code
	DEFINE l_ret_price_level_ind LIKE class.price_level_ind

	IF p_class_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "CLASS Code can NOT be empty"
		END IF
		RETURN NULL
	END IF

	
		SQL
			SELECT price_level_ind 
			INTO $l_ret_price_level_ind
			FROM class
			WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code				 
			AND class.class_code = $p_class_code  		
		END SQL
	
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "CLASS Bank Reference with CLASS Code ",trim(p_class_code),  "NOT found"
		END IF
		LET l_ret_price_level_ind = NULL
	ELSE
		#	                                                                                                
	END IF	

	RETURN l_ret_price_level_ind	                                                                                                
END FUNCTION


########################################################################################################################
# 
# Get Array record data from DB
#
########################################################################################################################

############################################################
# FUNCTION db_class_get_arr_rec(p_query_text)
#
#
############################################################
FUNCTION db_class_get_arr_rec(p_query_type,p_query_or_where_text)
	DEFINE p_query_type SMALLINT
	DEFINE p_query_or_where_text VARCHAR(500)
	DEFINE l_query_text VARCHAR(500)
	DEFINE l_where_text VARCHAR(500)
	DEFINE l_arr_rec_class DYNAMIC ARRAY OF RECORD LIKE class.*		
	DEFINE l_rec_class RECORD LIKE class.*
	DEFINE l_idx SMALLINT
	
	#p_query_text is optional
	CASE p_query_type
		WHEN FILTER_QUERY_OFF
			LET l_query_text = 
				"SELECT * FROM class ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ", 
				"ORDER BY class.class_code" 	


#		WHEN FILTER_QUERY_ON
#			LET l_query_text = p_query_or_where_text

		WHEN FILTER_QUERY_WHERE
			LET l_where_text = p_query_or_where_text
			LET l_query_text = 
				"SELECT * FROM class ",
				"WHERE ", l_where_text clipped," ",
				"AND cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ", 				
				"ORDER BY class.class_code" 	

		WHEN FILTER_QUERY_SELECT
			LET l_query_text = p_query_or_where_text		
		
		OTHERWISE
			LET l_query_text = 
				"SELECT * FROM class ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ", 
				"ORDER BY class.class_code"
				 				
	END CASE

	PREPARE s_class FROM l_query_text
	DECLARE c_class CURSOR FOR s_class


	LET l_idx = 0
	FOREACH c_class INTO l_rec_class.*
		LET l_idx = l_idx + 1
		LET l_arr_rec_class[l_idx].class_code = l_rec_class.class_code
		LET l_arr_rec_class[l_idx].desc_text = l_rec_class.desc_text
		LET l_arr_rec_class[l_idx].price_level_ind = l_rec_class.price_level_ind
		LET l_arr_rec_class[l_idx].ord_level_ind = l_rec_class.ord_level_ind
		LET l_arr_rec_class[l_idx].stock_level_ind = l_rec_class.stock_level_ind
		LET l_arr_rec_class[l_idx].desc_level_ind = l_rec_class.desc_level_ind
		
      
	END FOREACH

	IF sqlca.sqlcode < 0 THEN   	
		LET l_arr_rec_class = NULL	                                                                                        
	ELSE		                                                                                                                    
		#		                                                                                                
	END IF	         

	RETURN l_arr_rec_class		                                                                                                
END FUNCTION




############################################################
# FUNCTION db_class_get_arr_rec(p_query_text)
#
#
############################################################
FUNCTION db_class_get_arr_rec_c_d(p_query_type,p_query_or_where_text)
	DEFINE p_query_type SMALLINT
	DEFINE p_query_or_where_text VARCHAR(2200)
	DEFINE l_query_text VARCHAR(2200)
	DEFINE l_where_text VARCHAR(2048)
	DEFINE l_arr_rec_class DYNAMIC ARRAY OF t_rec_class_c_d		
	DEFINE l_rec_class RECORD LIKE class.*
	DEFINE l_idx SMALLINT
	
	#p_query_text is optional
	CASE p_query_type
		WHEN FILTER_QUERY_OFF
			LET l_query_text = 
				"SELECT * FROM class ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ", 
				"ORDER BY class.class_code" 	


#		WHEN FILTER_QUERY_ON
#			LET l_query_text = p_query_or_where_text

		WHEN FILTER_QUERY_WHERE
			LET l_where_text = p_query_or_where_text
			LET l_query_text = 
				"SELECT * FROM class ",
				"WHERE ", l_where_text clipped," ",
				"AND cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ", 				
				"ORDER BY class.class_code" 	

		WHEN FILTER_QUERY_SELECT
			LET l_query_text = p_query_or_where_text		
		
		OTHERWISE
			LET l_query_text = 
				"SELECT * FROM class ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ", 
				"ORDER BY class.class_code"
				 				
	END CASE

	PREPARE s2_class FROM l_query_text
	DECLARE c2_class CURSOR FOR s2_class


	LET l_idx = 0
	FOREACH c2_class INTO l_rec_class.*
		LET l_idx = l_idx + 1
		LET l_arr_rec_class[l_idx].class_code = l_rec_class.class_code
		LET l_arr_rec_class[l_idx].desc_text = l_rec_class.desc_text
	END FOREACH

	IF sqlca.sqlcode < 0 THEN   	
		LET l_arr_rec_class = NULL	                                                                                        
	ELSE		                                                                                                                    
		#		                                                                                                
	END IF	         

	RETURN l_arr_rec_class		                                                                                                
END FUNCTION


########################################################################################################################
# 
# UPDATE INSERT DELETE row from DB
#
########################################################################################################################


############################################################
# FUNCTION db_class_update(p_rec_class)
#
#
############################################################
FUNCTION db_class_update(p_ui_mode,p_pk_class_code,p_rec_class)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_pk_class_code LIKE class.class_code
	DEFINE p_rec_class RECORD LIKE class.*
	DEFINE l_ui_mode SMALLINT
	DEFINE ret INT
	DEFINE msgStr STRING
	
	IF p_ui_mode = UI_ON THEN
		LET l_ui_mode = UI_PK
	END IF

	IF p_pk_class_code IS NULL OR p_rec_class.class_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET msgStr = "CLASS code can not be empty ! (original CLASS=",trim(p_pk_class_code), " / new CLASS=", trim(p_rec_class.class_code), ")"  
			ERROR msgStr
		END IF
		RETURN -1
	END IF
	
	IF db_product_get_class_count(p_pk_class_code) AND (p_pk_class_code <> p_rec_class.class_code) THEN #PK class_code can only be changed if it's not used already
		IF p_ui_mode > 0 THEN
			ERROR "Can not change CLASS ! It is already used in a bank configuration"
		END IF
		LET ret =  -1
	ELSE
		
			SQL
				UPDATE class
				SET * = $p_rec_class.*
				WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code				
				AND class_code = $p_pk_class_code
			END SQL
			LET ret = status
		
	END IF

	IF p_ui_mode != UI_OFF THEN #display MESSAGE if ui is enabled
		IF ret < 0 THEN   		
			LET msgStr = "Coud not modify CLASS record ! /nOriginal CLASS", trim(p_pk_class_code), "New CLASS ", trim(p_rec_class.class_code),  "\nDatabase Error ", trim(ret)                                                                                        
			#ERROR msgStr 
			CALL fgl_winmessage("Error when trying to modify/update CLASS record",msgStr,"error")
		ELSE
			LET msgStr = "CLASS record ", trim(p_rec_class.class_code), " updated successfully !"   
			MESSAGE msgStr
		END IF                                           	
	END IF	
	
	RETURN ret
END FUNCTION        

   
############################################################
# FUNCTION db_class_insert(p_rec_class)
#
#
############################################################
FUNCTION db_class_insert(p_ui_mode,p_rec_class)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_rec_class RECORD LIKE class.*
	DEFINE ret INT
	DEFINE l_ui_mode SMALLINT
	DEFINE msgStr STRING	
	
	IF p_ui_mode = UI_ON THEN
		LET l_ui_mode = UI_PK
	END IF

	IF p_rec_class.class_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET msgStr = "CLASS code can not be empty ! (CLASS=", trim(p_rec_class.class_code), ")"  
			ERROR msgStr
		END IF
		RETURN -1
	END IF
	
	IF db_class_pk_exists(UI_PK,p_rec_class.class_code) THEN
		LET ret = -1
	ELSE
		
			INSERT INTO class
	    VALUES(p_rec_class.*)
	    
	    LET ret = status
		
	END IF

	IF p_ui_mode != UI_OFF THEN #display MESSAGE if ui is enabled
		IF ret < 0 THEN   		
			LET msgStr = "Coud not create CLASS record ", trim(p_rec_class.class_code), " !\nDatabase Error ", trim(ret)                                                                                        
			#ERROR msgStr 
			CALL fgl_winmessage("Error when trying to create/insert CLASS record",msgStr,"error")
		ELSE
			LET msgStr = "CLASS record ", trim(p_rec_class.class_code), " created successfully !"   
			MESSAGE msgStr
		END IF                                           	
	END IF
	
	RETURN ret
END FUNCTION


############################################################
# 
# FUNCTION db_class_delete(p_class_code)
#
#
############################################################
FUNCTION db_class_delete(p_ui_mode,p_confirm,p_class_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_confirm BOOLEAN #is operator requested to confirm this operation / independent of ui mode
	DEFINE p_class_code LIKE class.class_code
	DEFINE l_msgresp LIKE language.yes_flag	
	DEFINE ret SMALLINT	
	DEFINE msgStr STRING

	IF p_confirm = UI_CONFIRM_ON THEN
		LET msgStr = "Delete CLASS configuration ", trim(p_class_code), " ?"
		IF NOT promptTF("Delete CLASS",msgStr,TRUE) THEN
			RETURN -2
		END IF
	END IF
	
	IF p_class_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET msgStr = "CLASS code can not be empty ! (CLASS=", trim(p_class_code), ")"  
			ERROR msgStr
		END IF
		RETURN -1
	END IF

#	IF db_bank_get_class_count(p_class_code) THEN #PK class_code can only be deleted if it's not used already
#		IF p_ui_mode != UI_OFF THEN
#			LET msgStr = "Can not delete CLASS ! ", trim(p_class_code), " It is already used in a bank configuration"
#			CALL fgl_winmessage("Can not delete CLASS ! ",msgStr,"error")
#		END IF
#		LET ret =  -1
#	ELSE
		
			SQL
				DELETE FROM class
				WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code
				AND class_code = $p_class_code
			END SQL
			LET ret = status
		
			
#	END IF
	
	IF p_ui_mode != UI_OFF THEN #display MESSAGE if ui is enabled
		IF ret < 0 THEN   		
			LET msgStr = "Coud not delete CLASS record ", trim(p_class_code), " !\nDatabase Error ", trim(ret)                                                                                        
			#ERROR msgStr 
			CALL fgl_winmessage("Error when trying to delete",msgStr,"error")
		ELSE
			LET msgStr = "CLASS record ", trim(p_class_code), " deleted !"   
			MESSAGE msgStr
		END IF                                           	
	END IF		             

	RETURN ret	
		  
END FUNCTION
	
# This function returns the class description
FUNCTION db_get_desc_class(p_cmpy_code,p_class_code)
	DEFINE p_cmpy_code LIKE class.cmpy_code
	DEFINE p_class_code LIKE class.class_code
	DEFINE l_class_desc LIKE class.desc_text
	DEFINE p_set_isolation_mode PREPARED
	LET l_class_desc = NULL

	SET ISOLATION TO DIRTY READ
	SELECT desc_text INTO l_class_desc
	FROM class
	WHERE cmpy_code = p_cmpy_code
	AND class_code = p_class_code



	IF sqlca.sqlcode = 0 THEN
		CALL reset_isolation_mode()	#  reset to default isolation mode
		RETURN l_class_desc,1
	ELSE
		CALL reset_isolation_mode()	#  reset to default isolation mode
		RETURN l_class_desc,0
	END IF
	
END FUNCTION # db_get_desc_class

FUNCTION check_prykey_exists_class(p_cmpy_code,p_class_code)
	DEFINE p_cmpy_code LIKE class.cmpy_code
	DEFINE p_class_code LIKE class.class_code
	DEFINE prykey_exists BOOLEAN
	# initialize prykey_exists to false. If key is found, it is set to 'true'
	LET prykey_exists = FALSE
	SELECT TRUE
	INTO prykey_exists
	FROM class
	WHERE cmpy_code = p_cmpy_code
	AND class_code = p_class_code

	RETURN prykey_exists
END FUNCTION #check_prykey_exists_product()
