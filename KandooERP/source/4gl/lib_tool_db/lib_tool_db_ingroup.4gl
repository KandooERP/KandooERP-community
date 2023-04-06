########################################################################################################################
# TABLE ingroup
#
# 3 Column PK cmpy, type_ind, ingroup_code
########################################################################################################################

##########################################################
# GLOBAL Scope Variables
##########################################################
GLOBALS "../common/glob_GLOBALS.4gl"
GLOBALS "../common/glob_GLOBALS_userDataTypes.4gl"


############################################################
# FUNCTION db_ingroup_get_count()
#
# Return total number of rows in ingroup 
############################################################
FUNCTION db_ingroup_get_count()
	DEFINE ret INT

	
		SQL
			SELECT count(*) 
			INTO $ret 
			FROM ingroup 
			WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code		
		
		END SQL
	
			
	RETURN ret
END FUNCTION

				
############################################################
# FUNCTION db_ingroup_pk_exists(p_ui,p_ingroup_code)
#
# Validate PK - Unique
############################################################
#	CONSTANT UI_OFF SMALLINT = 0
#	CONSTANT UI_ON SMALLINT = 1
#	CONSTANT UI_FK SMALLINT = 2
#	CONSTANT UI_PK SMALLINT = 3
############################################################
FUNCTION db_ingroup_pk_exists(p_ui,p_ingroup_code)
	DEFINE p_ui SMALLINT
	DEFINE p_ingroup_code LIKE ingroup.ingroup_code
	DEFINE ret BOOLEAN
	DEFINE recCount INT
	DEFINE msgStr STRING

	IF p_ingroup_code IS NULL THEN
		IF p_ui != UI_OFF THEN
			ERROR "INGROUP Code can not be empty"
			#LET msgresp = kandoomsg("G",9178,"")
			#9178 Bank/State/Branchs must NOT be NULL
		END IF
		RETURN FALSE
	END IF

	
		SQL
			SELECT count(*) 
			INTO $recCount 
			FROM ingroup
			WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code			
			AND ingroup.ingroup_code = $p_ingroup_code
		END SQL
	
		
	IF recCount <> 0 THEN
		LET ret = TRUE	
		IF p_ui = UI_ON THEN
			MESSAGE "INGROUP Code with Type_Ind exists! (", trim(p_ingroup_code), ")"
		END IF
		IF p_ui = UI_PK THEN
			MESSAGE "INGROUP Code with Type_Ind already exists! (", trim(p_ingroup_code), ")"
		END IF
	ELSE
		LET ret = FALSE	
		IF p_ui = UI_FK THEN
			MESSAGE "INGROUP Code with Type_Ind does not exists! (", trim(p_ingroup_code), ")"
		END IF
	END IF
	
	RETURN ret
END FUNCTION


############################################################
# FUNCTION db_ingroup_get_rec(p_ui_mode,p_ingroup_code)
# RETURN l_rec_ingroup.*	
# Get INGROUP record
############################################################
FUNCTION db_ingroup_get_rec(p_ui_mode,p_ingroup_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_type_ind LIKE ingroup.type_ind
	DEFINE p_ingroup_code LIKE ingroup.ingroup_code
	DEFINE l_rec_ingroup RECORD LIKE ingroup.*


	IF p_ingroup_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Can not retrieve record with empty INGROUP code"
		END IF
		RETURN NULL
	END IF


	
		SQL
	      SELECT *
	        INTO $l_rec_ingroup.*
	        FROM ingroup
					WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code			
	       AND ingroup_code = $p_ingroup_code
		END SQL         
	
	
	IF sqlca.sqlcode != 0 THEN    		  
		INITIALIZE l_rec_ingroup.* TO NULL                                                                                      
	ELSE		                                                                                                                    
		#		                                                                                                
	END IF	         

	RETURN l_rec_ingroup.*		                                                                                                
END FUNCTION	


############################################################
# FUNCTION db_ingroup_get_desc_text(p_ui_mode,p_ingroup_code)
# RETURN l_ret_desc_text 
#
# Get description text of INGROUP record
############################################################
FUNCTION db_ingroup_get_desc_text(p_ui_mode,p_ingroup_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_ingroup_code LIKE ingroup.ingroup_code
	DEFINE l_ret_desc_text LIKE ingroup.desc_text


	IF p_ingroup_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN	
			ERROR "INGROUP Code can NOT be empty"
		END IF
			RETURN NULL
	END IF

	
		SQL
			SELECT desc_text 
			INTO $l_ret_desc_text 
			FROM ingroup 
			WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code				
			AND ingroup.ingroup_code = $p_ingroup_code
						  		
		END SQL
	
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "INGROUP Description with Code ",trim(p_ingroup_code),  " NOT found"
		END IF			
		LET l_ret_desc_text = NULL
	ELSE
		#
	END IF	
	RETURN l_ret_desc_text
END FUNCTION


########################################################################################################################
# 
# Get Array record data from DB
#
########################################################################################################################

############################################################
# FUNCTION db_ingroup_get_arr_rec(p_query_text)
#
#
############################################################
FUNCTION db_ingroup_get_arr_rec(p_query_type,p_query_or_where_text)
	DEFINE p_query_type SMALLINT
	DEFINE p_query_or_where_text VARCHAR(500)
	DEFINE l_query_text VARCHAR(500)
	DEFINE l_where_text VARCHAR(500)
	DEFINE l_arr_rec_ingroup DYNAMIC ARRAY OF t_rec_ingroup_i_d_t	
#	DEFINE l_rec_ingroup t_rec_ingroup_i_d_t
	DEFINE l_idx SMALLINT
	
	#p_query_text is optional
	CASE p_query_type
		WHEN FILTER_QUERY_OFF
			LET l_query_text = 
				"SELECT ingroup_code,desc_text,type_ind FROM ingroup ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ", 
				"ORDER BY ingroup.ingroup_code" 	


#		WHEN FILTER_QUERY_ON
#			LET l_query_text = p_query_or_where_text

		WHEN FILTER_QUERY_WHERE
			LET l_where_text = p_query_or_where_text
			LET l_query_text = 
				"SELECT ingroup_code,desc_text,type_ind FROM ingroup ",
				"WHERE ", l_where_text clipped," ",
				"AND cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ", 				
				"ORDER BY ingroup.ingroup_code" 	


		WHEN FILTER_QUERY_SELECT
			LET l_query_text = p_query_or_where_text		
		
		OTHERWISE
			LET l_query_text = 
				"SELECT ingroup_code,desc_text,type_ind FROM ingroup ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ", 
				"ORDER BY ingroup.type_ind"
				 				
	END CASE

	PREPARE s_ingroup FROM l_query_text
	DECLARE c_ingroup CURSOR FOR s_ingroup


	LET l_idx = 1
	FOREACH c_ingroup INTO l_arr_rec_ingroup[l_idx].*
		LET l_idx = l_idx + 1
	END FOREACH

	IF sqlca.sqlcode < 0 THEN   	
		LET l_arr_rec_ingroup = NULL	                                                                                        
	ELSE		                                                                                                                    
		#		                                                                                                
	END IF	         

	RETURN l_arr_rec_ingroup		                                                                                                
END FUNCTION




############################################################
# FUNCTION db_ingroup_get_arr_rec_i_d(p_query_type,p_query_or_where_text)
#
#
############################################################
FUNCTION db_ingroup_get_arr_rec_i_d(p_query_type,p_group_type,p_query_or_where_text)
	DEFINE p_query_type SMALLINT
	DEFINE p_group_type LIKE ingroup.type_ind
	DEFINE p_query_or_where_text VARCHAR(2048)
	DEFINE l_query_text VARCHAR(2200)
	DEFINE l_where_text VARCHAR(2048)
	DEFINE l_arr_rec_ingroup DYNAMIC ARRAY OF t_rec_ingroup_i_d		
	DEFINE l_rec_ingroup RECORD LIKE ingroup.*
	DEFINE l_idx SMALLINT
	
	IF p_query_or_where_text IS NULL THEN #save guard
		LET p_query_or_where_text = " 1=1 "
	END IF	
	
	#p_query_text is optional
	CASE p_query_type
		WHEN FILTER_QUERY_OFF
			LET l_query_text = 
				"SELECT ingroup_code, desc_text FROM ingroup ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ",
				"AND type_ind = '",p_group_type,"' ", 
				"ORDER BY ingroup.ingroup_code" 	


#		WHEN FILTER_QUERY_ON
#			LET l_query_text = p_query_or_where_text

		WHEN FILTER_QUERY_WHERE
			LET l_where_text = p_query_or_where_text
			LET l_query_text = 
				"SELECT ingroup_code, desc_text FROM ingroup ",
				"WHERE ", l_where_text clipped," ",
				"AND cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ",
				"AND type_ind = '",p_group_type,"' ", 				 				
				"ORDER BY ingroup.ingroup_code" 	

		WHEN FILTER_QUERY_SELECT
			LET l_query_text = p_query_or_where_text		
		
		OTHERWISE
			LET l_query_text = 
				"SELECT ingroup_code, desc_text FROM ingroup ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ",
				"AND type_ind = '",p_group_type,"' ", 				 
				"ORDER BY ingroup.ingroup_code"
				 				
	END CASE

	PREPARE s2_ingroup FROM l_query_text
	DECLARE c2_ingroup CURSOR FOR s2_ingroup


	LET l_idx = 1
	FOREACH c2_ingroup INTO l_arr_rec_ingroup[l_idx].*
		LET l_idx = l_idx + 1
	END FOREACH
	CALL l_arr_rec_ingroup.delete(l_idx)

	IF sqlca.sqlcode < 0 THEN   	
		LET l_arr_rec_ingroup = NULL	                                                                                        
	ELSE		                                                                                                                    
		#		                                                                                                
	END IF	         

	RETURN l_arr_rec_ingroup		                                                                                                
END FUNCTION


########################################################################################################################
# 
# UPDATE INSERT DELETE row from DB
#
########################################################################################################################


############################################################
# FUNCTION db_ingroup_update(p_ui_mode,p_pk_ingroup_code,p_rec_ingroup)
#
#
############################################################
FUNCTION db_ingroup_update(p_ui_mode,p_pk_ingroup_code,p_rec_ingroup)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_pk_type_ind LIKE ingroup.type_ind
	DEFINE p_pk_ingroup_code LIKE ingroup.ingroup_code
	DEFINE p_rec_ingroup RECORD LIKE ingroup.*
	DEFINE l_ui_mode SMALLINT
	DEFINE ret INT
	DEFINE msgStr STRING
	
	IF p_ui_mode = UI_ON THEN
		LET l_ui_mode = UI_PK
	END IF


	IF p_pk_ingroup_code IS NULL OR p_rec_ingroup.ingroup_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET msgStr = "INGROUP code can not be empty ! (original INGROUP=",trim(p_pk_ingroup_code), " / new INGROUP=", trim(p_rec_ingroup.ingroup_code), ")"  
			ERROR msgStr
		END IF
		RETURN -1
	END IF

	IF p_rec_ingroup.type_ind IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET msgStr = "INGROUP TYPE_IND code can not be empty !  new TYPE_IND=", trim(p_rec_ingroup.type_ind), ")"  
			ERROR msgStr
		END IF
		RETURN -2
	END IF
	
#	IF db_product_get_class_count(p_pk_ingroup_code) AND (p_pk_ingroup_code <> p_rec_ingroup.ingroup_code) THEN #PK ingroup_code can only be changed if it's not used already
#		IF p_ui_mode > 0 THEN
#			ERROR "Can not change INGROUP ! It is already used in a bank configuration"
#		END IF
#		LET ret =  -1
#	ELSE
		
			SQL
				UPDATE ingroup
				SET * = $p_rec_ingroup.*
				WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code				
				AND ingroup_code = $p_pk_ingroup_code
			END SQL
			LET ret = status
		
#	END IF

	IF p_ui_mode != UI_OFF THEN #display MESSAGE if ui is enabled
		IF ret < 0 THEN   		
			LET msgStr = "Coud not modify INGROUP record ! /nOriginal INGROUP", trim(p_pk_ingroup_code), "New INGROUP ", trim(p_rec_ingroup.ingroup_code),  "\nDatabase Error ", trim(ret)                                                                                        
			#ERROR msgStr 
			CALL fgl_winmessage("Error when trying to modify/update INGROUP record",msgStr,"error")
		ELSE
			LET msgStr = "INGROUP record ", trim(p_rec_ingroup.ingroup_code),  " updated successfully !"   
			MESSAGE msgStr
		END IF                                           	
	END IF	
	
	RETURN ret
END FUNCTION        

   
############################################################
# FUNCTION db_ingroup_insert(p_rec_ingroup)
#
#
############################################################
FUNCTION db_ingroup_insert(p_ui_mode,p_rec_ingroup)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_rec_ingroup RECORD LIKE ingroup.*
	DEFINE ret INT
	DEFINE l_ui_mode SMALLINT
	DEFINE msgStr STRING	
	
	IF p_ui_mode = UI_ON THEN
		LET l_ui_mode = UI_PK
	END IF


	IF p_rec_ingroup.ingroup_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET msgStr = "INGROUP code can not be empty ! (INGROUP=", trim(p_rec_ingroup.ingroup_code), ")"  
			ERROR msgStr
		END IF
		RETURN -1
	END IF


	IF p_rec_ingroup.type_ind IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET msgStr = "Ingroup TYPE_IND can not be empty ! (Ingroup TYPE_IND=", trim(p_rec_ingroup.type_ind), ")"  
			ERROR msgStr
		END IF
		RETURN -2
	END IF
	
	IF db_ingroup_pk_exists(UI_PK,p_rec_ingroup.ingroup_code) THEN #,p_rec_ingroup.type_ind
		LET ret = -10
	ELSE
		
			INSERT INTO ingroup
	    VALUES(p_rec_ingroup.*)
	    
	    LET ret = status
		
	END IF

	IF p_ui_mode != UI_OFF THEN #display MESSAGE if ui is enabled
		IF ret < 0 THEN   		
			LET msgStr = "Coud not create INGROUP record ", trim(p_rec_ingroup.ingroup_code),"/", trim(p_rec_ingroup.type_ind), " !\nDatabase Error ", trim(ret)                                                                                        
			#ERROR msgStr 
			CALL fgl_winmessage("Error when trying to create/insert INGROUP record",msgStr,"error")
		ELSE
			LET msgStr = "INGROUP record ", trim(p_rec_ingroup.ingroup_code), " created successfully !"   
			MESSAGE msgStr
		END IF                                           	
	END IF
	
	RETURN ret
END FUNCTION


############################################################
# 
# FUNCTION db_ingroup_delete(p_ingroup_code)
#
#
############################################################
FUNCTION db_ingroup_delete(p_ui_mode,p_ingroup_code)
	DEFINE p_ui_mode SMALLINT #hide or show error/warning messages
	DEFINE p_confirm BOOLEAN #is operator requested to confirm this operation / independent of ui mode	
	DEFINE p_ingroup_code LIKE ingroup.ingroup_code
	DEFINE l_msgresp LIKE language.yes_flag	
	DEFINE ret SMALLINT	
	DEFINE msgStr STRING

	IF p_confirm = UI_CONFIRM_ON THEN
		LET msgStr = "Delete INGROUP configuration ", trim(p_ingroup_code), " ?"
		IF NOT promptTF("Delete INGROUP",msgStr,TRUE) THEN
			RETURN -10
		END IF
	END IF

	
	IF p_ingroup_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET msgStr = "INGROUP code can not be empty ! (INGROUP=", trim(p_ingroup_code), ")"  
			ERROR msgStr
		END IF
		RETURN -2
	END IF

#	IF db_bank_get_class_count(p_ingroup_code) THEN #PK ingroup_code can only be deleted if it's not used already
#		IF p_ui_mode != UI_OFF THEN
#			LET msgStr = "Can not delete INGROUP ! ", trim(p_ingroup_code), " It is already used in a bank configuration"
#			CALL fgl_winmessage("Can not delete INGROUP ! ",msgStr,"error")
#		END IF
#		LET ret =  -1
#	ELSE
		
			DELETE FROM ingroup
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
			AND ingroup_code = p_ingroup_code
			LET ret = status
		
			
#	END IF
	
	IF p_ui_mode != UI_OFF THEN #display MESSAGE if ui is enabled
		IF ret < 0 THEN   		
			LET msgStr = "Coud not delete INGROUP=", trim(p_ingroup_code), " !\nDatabase Error ", trim(ret)                                                                                        
			#ERROR msgStr 
			CALL fgl_winmessage("Error when trying to delete",msgStr,"error")
		ELSE
			LET msgStr = "INGROUP record ", trim(p_ingroup_code), " deleted !"   
			MESSAGE msgStr
		END IF                                           	
	END IF		             

	RETURN ret	
		  
END FUNCTION
	
