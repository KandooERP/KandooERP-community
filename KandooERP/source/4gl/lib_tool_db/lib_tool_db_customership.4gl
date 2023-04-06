########################################################################################################################
# TABLE customership
#
# 3 Column PK cmpy, cust_code, ship_code
########################################################################################################################

##########################################################
# GLOBAL Scope Variables
##########################################################
GLOBALS "../common/glob_GLOBALS.4gl"



############################################################
# FUNCTION db_customership_get_count()
#
# Return total number of rows in customership 
############################################################
FUNCTION db_customership_all_get_count()
	DEFINE ret INT

	SELECT count(*) 
	INTO ret 
	FROM customership 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code		
			
	RETURN ret
END FUNCTION

############################################################
# FUNCTION db_customership_get_count()
#
# Return total number of rows in customership 
############################################################
FUNCTION db_customership_get_count(p_cust_code)
	DEFINE p_cust_code LIKE customership.cust_code
	DEFINE ret INT

	
		SQL
			SELECT count(*) 
			INTO $ret 
			FROM customership 
			WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code
			AND cust_code = $p_cust_code		
		
		END SQL
	
			
	RETURN ret
END FUNCTION
				
				
############################################################
# FUNCTION db_customership_pk_exists(p_ui,p_cust_code,p_ship_code)
#
# Validate PK - Unique
############################################################
#	CONSTANT UI_OFF SMALLINT = 0
#	CONSTANT UI_ON SMALLINT = 1
#	CONSTANT UI_FK SMALLINT = 2
#	CONSTANT UI_PK SMALLINT = 3
############################################################
FUNCTION db_customership_pk_exists(p_ui,p_cust_code,p_ship_code)
	DEFINE p_ui SMALLINT
	DEFINE p_ship_code LIKE customership.ship_code
	DEFINE p_cust_code LIKE customership.cust_code
	DEFINE ret BOOLEAN
	DEFINE recCount INT
	DEFINE msgStr STRING

	IF p_ship_code IS NULL THEN
		IF p_ui != UI_OFF THEN
			ERROR "customership Code can not be empty"
			#LET msgresp = kandoomsg("G",9178,"")
			#9178 Bank/State/Branchs must NOT be NULL
		END IF
		RETURN FALSE
	END IF

	IF p_cust_code IS NULL THEN
		IF p_ui != UI_OFF THEN
			ERROR "customership cust_code can not be empty"
			#LET msgresp = kandoomsg("G",9178,"")
			#9178 Bank/State/Branchs must NOT be NULL
		END IF
		RETURN FALSE
	END IF


	
		SQL
			SELECT count(*) 
			INTO $recCount 
			FROM customership
			WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code			
			AND customership.ship_code = $p_ship_code
			AND customership.cust_code = $p_cust_code
			  
		END SQL
	
		
	IF recCount <> 0 THEN
		LET ret = TRUE	
		IF p_ui = UI_ON THEN
			MESSAGE "customership Code with cust_code - ship_code exists! (", trim(p_cust_code), "-", trim(p_ship_code),")"
		END IF
		IF p_ui = UI_PK THEN
			MESSAGE "customership Code with cust_code - ship_code already exists! (", trim(p_cust_code), "-", trim(p_ship_code),")"
		END IF
	ELSE
		LET ret = FALSE	
		IF p_ui = UI_FK THEN
			MESSAGE "customership Code with cust_code - ship_code does not exists!  (", trim(p_cust_code), "-", trim(p_ship_code),")"
		END IF
	END IF
	
	RETURN ret
END FUNCTION


############################################################
# FUNCTION db_customership_get_rec(p_ui_mode,p_cust_code,p_ship_code)
# RETURN l_rec_customership.*	
# Get customership record
############################################################
FUNCTION db_customership_get_rec(p_ui_mode,p_cust_code,p_ship_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_cust_code LIKE customership.cust_code
	DEFINE p_ship_code LIKE customership.ship_code
	DEFINE l_rec_customership RECORD LIKE customership.*
	DEFINE l_msg STRING
	
	INITIALIZE l_rec_customership.* TO NULL
	
	IF p_cust_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Can not retrieve record with empty Customer Code"
		END IF
		RETURN l_rec_customership.*
	END IF

	IF p_ship_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Can not retrieve record with empty Shipping code"
		END IF
		RETURN l_rec_customership.*
	END IF


	
		SQL
	      SELECT *
	        INTO $l_rec_customership.*
	        FROM customership
					WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code			
	       AND cust_code = $p_cust_code
	       AND ship_code = $p_ship_code
		END SQL         
	
	
	IF sqlca.sqlcode != 0 THEN 		
   	IF p_ui_mode != UI_OFF THEN
      ERROR "customership with Code ", trim(p_cust_code), "/", trim(p_ship_code), " NOT found"
		END IF	  
	END IF	         

	RETURN l_rec_customership.*		                                                                                                
END FUNCTION	


############################################################
# FUNCTION db_customership_get_name_text(p_ui_mode,p_cust_code,p_ship_code)
# RETURN l_ret_name_text 
#
# Get description text of customership record
############################################################
FUNCTION db_customership_get_name_text(p_ui_mode,p_cust_code,p_ship_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_ship_code LIKE customership.ship_code
	DEFINE p_cust_code LIKE customership.cust_code
	DEFINE l_ret_name_text LIKE customership.name_text

	IF p_cust_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN	
			ERROR "customership cust_code can NOT be empty"
		END IF
			RETURN NULL
	END IF

	IF p_ship_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN	
			ERROR "customership Code can NOT be empty"
		END IF
			RETURN NULL
	END IF

	
		SQL
			SELECT name_text 
			INTO $l_ret_name_text 
			FROM customership 
			WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code				
			AND customership.ship_code = $p_ship_code
			AND customership.cust_code = $p_cust_code
						  		
		END SQL
	
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "customership Description with Code ",trim(p_ship_code)," and cust_code ", trim(p_cust_code),  " NOT found"
		END IF			
		LET l_ret_name_text = NULL
	ELSE
		#
	END IF	
	
	RETURN l_ret_name_text
END FUNCTION


########################################################################################################################
# 
# Get Array record data from DB
#
########################################################################################################################
{
############################################################
# FUNCTION db_customership_get_arr_rec(p_query_text)
#
#
############################################################
FUNCTION db_customership_get_arr_rec(p_query_type,p_query_or_where_text)
	DEFINE p_query_type SMALLINT
	DEFINE p_query_or_where_text VARCHAR(500)
	DEFINE l_query_text VARCHAR(500)
	DEFINE l_where_text VARCHAR(500)
	DEFINE l_arr_rec_customership DYNAMIC ARRAY OF t_rec_customership_i_d_t	
#	DEFINE l_rec_customership t_rec_customership_i_d_t
	DEFINE l_idx SMALLINT
	
	#p_query_text is optional
	CASE p_query_type
		WHEN FILTER_QUERY_OFF
			LET l_query_text = 
				"SELECT ship_code,desc_text,cust_code FROM customership ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ", 
				"ORDER BY customership.cust_code, customership.ship_code" 	


#		WHEN FILTER_QUERY_ON
#			LET l_query_text = p_query_or_where_text

		WHEN FILTER_QUERY_WHERE
			LET l_where_text = p_query_or_where_text
			LET l_query_text = 
				"SELECT ship_code,desc_text,cust_code FROM customership ",
				"WHERE ", l_where_text clipped," ",
				"AND cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ", 				
				"ORDER BY customership.cust_code, customership.ship_code" 	

		WHEN FILTER_QUERY_SELECT
			LET l_query_text = p_query_or_where_text		
		
		OTHERWISE
			LET l_query_text = 
				"SELECT ship_code,desc_text,cust_code FROM customership ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ", 
				"ORDER BY customership.cust_code, customership.ship_code"
				 				
	END CASE

	PREPARE s_customership FROM l_query_text
	DECLARE c_customership CURSOR FOR s_customership


	LET l_idx = 1
	FOREACH c_customership INTO l_arr_rec_customership[l_idx].*
		LET l_idx = l_idx + 1
	END FOREACH

	IF sqlca.sqlcode < 0 THEN   	
		LET l_arr_rec_customership = NULL	                                                                                        
	ELSE		                                                                                                                    
		#		                                                                                                
	END IF	         

	RETURN l_arr_rec_customership		                                                                                                
END FUNCTION




############################################################
# FUNCTION db_customership_get_arr_rec_i_d(p_query_type,p_query_or_where_text)
#
#
############################################################
FUNCTION db_customership_get_arr_rec_i_d(p_query_type,p_query_or_where_text)
	DEFINE p_query_type SMALLINT
	DEFINE p_query_or_where_text VARCHAR(500)
	DEFINE l_query_text VARCHAR(500)
	DEFINE l_where_text VARCHAR(500)
	DEFINE l_arr_rec_customership DYNAMIC ARRAY OF t_rec_customership_i_d		
	DEFINE l_rec_customership RECORD LIKE customership.*
	DEFINE l_idx SMALLINT
	
	IF p_query_or_where_text IS NULL THEN #save guard
		LET p_query_or_where_text = " 1=1 "
	END IF	
	
	#p_query_text is optional
	CASE p_query_type
		WHEN FILTER_QUERY_OFF
			LET l_query_text = 
				"SELECT ship_code, desc_text FROM customership ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ", 
				"ORDER BY customership.ship_code" 	


#		WHEN FILTER_QUERY_ON
#			LET l_query_text = p_query_or_where_text

		WHEN FILTER_QUERY_WHERE
			LET l_where_text = p_query_or_where_text
			LET l_query_text = 
				"SELECT ship_code, desc_text FROM customership ",
				"WHERE ", l_where_text clipped," ",
				"AND cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ", 				
				"ORDER BY customership.ship_code" 	

		WHEN FILTER_QUERY_SELECT
			LET l_query_text = p_query_or_where_text		
		
		OTHERWISE
			LET l_query_text = 
				"SELECT ship_code, desc_text FROM customership ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ", 
				"ORDER BY customership.ship_code"
				 				
	END CASE

	PREPARE s2_customership FROM l_query_text
	DECLARE c2_customership CURSOR FOR s2_customership


	LET l_idx = 1
	FOREACH c2_customership INTO l_arr_rec_customership[l_idx].*
		LET l_idx = l_idx + 1
	END FOREACH

	IF sqlca.sqlcode < 0 THEN   	
		LET l_arr_rec_customership = NULL	                                                                                        
	ELSE		                                                                                                                    
		#		                                                                                                
	END IF	         

	RETURN l_arr_rec_customership		                                                                                                
END FUNCTION
}

########################################################################################################################
# 
# UPDATE INSERT DELETE row from DB
#
########################################################################################################################


############################################################
# FUNCTION db_customership_update(p_rec_customership)
#
#
############################################################
FUNCTION db_customership_update(p_ui_mode,p_pk_type_ind,p_pk_customership_code,p_rec_customership)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_pk_type_ind LIKE customership.cust_code
	DEFINE p_pk_customership_code LIKE customership.ship_code
	DEFINE p_rec_customership RECORD LIKE customership.*
	DEFINE l_ui_mode SMALLINT
	DEFINE ret INT
	DEFINE msgStr STRING
	
	IF p_ui_mode = UI_ON THEN
		LET l_ui_mode = UI_PK
	END IF

	IF p_pk_type_ind IS NULL OR p_rec_customership.cust_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET msgStr = "customership cust_code code can not be empty ! (original cust_code=",trim(p_pk_type_ind), " / new cust_code=", trim(p_rec_customership.cust_code), ")"  
			ERROR msgStr
		END IF
		RETURN -1
	END IF

	IF p_pk_customership_code IS NULL OR p_rec_customership.ship_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET msgStr = "customership code can not be empty ! (original customership=",trim(p_pk_customership_code), " / new customership=", trim(p_rec_customership.ship_code), ")"  
			ERROR msgStr
		END IF
		RETURN -2
	END IF
	
#	IF db_product_get_class_count(p_pk_customership_code) AND (p_pk_customership_code <> p_rec_customership.ship_code) THEN #PK ship_code can only be changed if it's not used already
#		IF p_ui_mode > 0 THEN
#			ERROR "Can not change customership ! It is already used in a bank configuration"
#		END IF
#		LET ret =  -1
#	ELSE
		
			SQL
				UPDATE customership
				SET * = $p_rec_customership.*
				WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code				
				AND cust_code = $p_pk_type_ind
				AND ship_code = $p_pk_customership_code
			END SQL
			LET ret = status
		
#	END IF

	IF p_ui_mode != UI_OFF THEN #display MESSAGE if ui is enabled
		IF ret < 0 THEN   		
			LET msgStr = "Coud not modify customership record ! /nOriginal cust_code/customership", trim(p_pk_type_ind), "/", trim(p_pk_customership_code), "New cust_code/customership ", trim(p_rec_customership.cust_code), "/" , trim(p_rec_customership.ship_code),  "\nDatabase Error ", trim(ret)                                                                                        
			#ERROR msgStr 
			CALL fgl_winmessage("Error when trying to modify/update customership record",msgStr,"error")
		ELSE
			LET msgStr = "customership record ", trim(p_rec_customership.ship_code), "/", trim(p_rec_customership.cust_code),  " updated successfully !"   
			MESSAGE msgStr
		END IF                                           	
	END IF	
	
	RETURN ret
END FUNCTION        

   
############################################################
# FUNCTION db_customership_insert(p_rec_customership)
#
#
############################################################
FUNCTION db_customership_insert(p_ui_mode,p_rec_customership)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_rec_customership RECORD LIKE customership.*
	DEFINE ret INT
	DEFINE l_ui_mode SMALLINT
	DEFINE msgStr STRING	
	
	IF p_ui_mode = UI_ON THEN
		LET l_ui_mode = UI_PK
	END IF

	IF p_rec_customership.cust_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET msgStr = "customership cust_code can not be empty ! (customership cust_code=", trim(p_rec_customership.cust_code), ")"  
			ERROR msgStr
		END IF
		RETURN -1
	END IF
	
	IF p_rec_customership.ship_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET msgStr = "customership code can not be empty ! (customership=", trim(p_rec_customership.ship_code), ")"  
			ERROR msgStr
		END IF
		RETURN -2
	END IF
	
	IF db_customership_pk_exists(UI_PK,p_rec_customership.cust_code,p_rec_customership.ship_code) THEN
		LET ret = -1
	ELSE
		
			INSERT INTO customership
	    VALUES(p_rec_customership.*)
	    
	    LET ret = status
		
	END IF

	IF p_ui_mode != UI_OFF THEN #display MESSAGE if ui is enabled
		IF ret < 0 THEN   		
			LET msgStr = "Coud not create customership record ", trim(p_rec_customership.ship_code),"/", trim(p_rec_customership.cust_code), " !\nDatabase Error ", trim(ret)                                                                                        
			#ERROR msgStr 
			CALL fgl_winmessage("Error when trying to create/insert customership record",msgStr,"error")
		ELSE
			LET msgStr = "customership record ", trim(p_rec_customership.ship_code),"/", trim(p_rec_customership.cust_code), " created successfully !"   
			MESSAGE msgStr
		END IF                                           	
	END IF
	
	RETURN ret
END FUNCTION


############################################################
# 
# FUNCTION db_customership_delete(p_ui_mode,p_cust_code,p_ship_code)
#
#
############################################################
FUNCTION db_customership_delete(p_ui_mode,p_confirm,p_cust_code,p_ship_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_confirm BOOLEAN #is operator requested to confirm this operation / independent of ui mode		
	DEFINE p_cust_code LIKE customership.cust_code
	DEFINE p_ship_code LIKE customership.ship_code
	DEFINE l_msgresp LIKE language.yes_flag	
	DEFINE ret SMALLINT	
	DEFINE msgStr STRING

	IF p_confirm = UI_CONFIRM_ON THEN
		LET msgStr = "Delete customership configuration ", trim(p_cust_code), "/", trim(p_ship_code), " ?"
		IF NOT promptTF("Delete customership",msgStr,TRUE) THEN
			RETURN -10
		END IF
	END IF
	
	IF p_cust_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET msgStr = "customership cust_code code can not be empty ! (cust_code/customership=", trim(p_cust_code), "/", trim(p_ship_code), ")"  
			ERROR msgStr
		END IF
		RETURN -1
	END IF
	
	IF p_ship_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET msgStr = "customership code can not be empty ! (customership=", trim(p_ship_code), ")"  
			ERROR msgStr
		END IF
		RETURN -2
	END IF

#	IF db_bank_get_class_count(p_ship_code) THEN #PK ship_code can only be deleted if it's not used already
#		IF p_ui_mode != UI_OFF THEN
#			LET msgStr = "Can not delete customership ! ", trim(p_ship_code), " It is already used in a bank configuration"
#			CALL fgl_winmessage("Can not delete customership ! ",msgStr,"error")
#		END IF
#		LET ret =  -1
#	ELSE
		
			SQL
				DELETE FROM customership
				WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code
				AND cust_code = $p_cust_code
				AND ship_code = $p_ship_code
			END SQL
			LET ret = status
		
			
#	END IF
	
	IF p_ui_mode != UI_OFF THEN #display MESSAGE if ui is enabled
		IF ret < 0 THEN   		
			LET msgStr = "Could not delete cust_code/customership=", trim(p_cust_code), "/", trim(p_ship_code), " !\nDatabase Error ", trim(ret)                                                                                        
			#ERROR msgStr 
			CALL fgl_winmessage("Error when trying to delete",msgStr,"error")
		ELSE
			LET msgStr = "customership record ", trim(p_cust_code), "/", trim(p_ship_code), " deleted !"   
			MESSAGE msgStr
		END IF                                           	
	END IF		             

	RETURN ret	
		  
END FUNCTION
	
