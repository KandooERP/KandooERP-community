########################################################################################################################
# TABLE suburb
#
#
########################################################################################################################

##########################################################
# GLOBAL Scope Variables
##########################################################
GLOBALS "../common/glob_GLOBALS.4gl"
GLOBALS "../common/glob_GLOBALS_userDataTypes.4gl"

			
############################################################
# FUNCTION db_suburb_pk_exists(p_ui,p_suburb_code)
#
# Validate PK - Unique
############################################################
#	CONSTANT UI_OFF SMALLINT = 0
#	CONSTANT UI_ON SMALLINT = 1
#	CONSTANT UI_FK SMALLINT = 2
#	CONSTANT UI_PK SMALLINT = 3
############################################################
FUNCTION db_suburb_pk_exists(p_ui_mode,p_op_mode,p_suburb_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_op_mode SMALLINT	
	DEFINE p_suburb_code LIKE suburb.suburb_code
	DEFINE ret BOOLEAN
	DEFINE recCount INT
	DEFINE msgStr STRING

	IF p_suburb_code IS NULL THEN
		IF p_ui_mode >= UI_ON THEN
			ERROR "Suburb Code can not be empty"
			#LET msgresp = kandoomsg("G",9178,"")
			#9178 Bank/State/Branchs must NOT be NULL
		END IF
		RETURN FALSE
	END IF

	
		SQL
			SELECT count(*) 
			INTO $recCount 
			FROM suburb 
			WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code				
			AND suburb.suburb_code = $p_suburb_code  
		END SQL
	
		
	IF recCount > 0 THEN
		LET ret = TRUE	
		CASE p_op_mode
			WHEN MODE_INSERT
				CASE p_ui_mode
					WHEN UI_PK
						ERROR "PATs Code already exists! (", trim(p_suburb_code), ")"
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
						ERROR "Suburb Code does not exist! (", trim(p_suburb_code), ")"
					OTHERWISE
						#No MESSAGE
				END CASE
			
			WHEN MODE_DELETE
				CASE p_ui_mode
					WHEN UI_PK
						#No MESSAGE
					WHEN UI_FK
						ERROR "Suburb Code does not exist! (", trim(p_suburb_code), ")"
					OTHERWISE
						#No MESSAGE
				END CASE
					
		END CASE
	ELSE
		LET ret = FALSE	
		CASE p_op_mode		
			WHEN MODE_INSERT
				CASE p_ui_mode
					WHEN UI_PK
						#No MESSAGE
					WHEN UI_FK
						ERROR "Suburb Code does not exist! (", trim(p_suburb_code), ")"
					OTHERWISE
						#No MESSAGE
				END CASE

			WHEN MODE_UPDATE
				CASE p_ui_mode
					WHEN UI_PK
						ERROR "Suburb Code does not exist! (", trim(p_suburb_code), ")"
					WHEN UI_FK
						#No MESSAGE
					OTHERWISE
						#No MESSAGE
				END CASE

			WHEN MODE_DELETE
				CASE p_ui_mode
					WHEN UI_PK
						ERROR "Suburb Code does not exist! (", trim(p_suburb_code), ")"
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
# FUNCTION db_suburb_get_count()
#
# Return total number of rows in suburb 
############################################################
FUNCTION db_suburb_get_count()
	DEFINE ret INT

	
		SQL
			SELECT count(*) 
			INTO $ret 
			FROM suburb 
			WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code				
		
		END SQL
	
			
	RETURN ret
END FUNCTION



############################################################
# FUNCTION db_suburb_get_count(p_suburb_code)
#
# Return total number of rows in suburb 
############################################################
FUNCTION db_suburb_get_class_count(p_suburb_code)
	DEFINE p_suburb_code LIKE suburb.suburb_code
	DEFINE l_ret INT

	
		SQL
			SELECT count(*) 
			INTO $l_ret 
			FROM suburb 
			WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code				
			AND suburb.suburb_code = $p_suburb_code
		
		END SQL
	
			
	RETURN l_ret
END FUNCTION


############################################################
# FUNCTION db_suburb_get_rec(p_ui_mode,p_suburb_code)
# RETURN l_rec_suburb.*
# Get suburb/Part record
############################################################
FUNCTION db_suburb_get_rec(p_ui_mode,p_suburb_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_suburb_code LIKE suburb.suburb_code
	DEFINE l_rec_suburb RECORD LIKE suburb.*

	IF p_suburb_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Can not retrieve record with empty Suburb Code"
		END IF
		RETURN NULL
	END IF

	
		SQL
			SELECT *
			INTO $l_rec_suburb.*
			FROM suburb
			WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code		        
			AND suburb_code = $p_suburb_code
		END SQL         
	
	
	IF sqlca.sqlcode != 0 THEN    		  
		INITIALIZE l_rec_suburb.* TO NULL                                                                                      
	ELSE		                                                                                                                    
		#		                                                                                                
	END IF	         

	RETURN l_rec_suburb.*		                                                                                                
END FUNCTION	


############################################################
# FUNCTION db_suburb_get_suburb_text(p_ui_mode,p_suburb_code)
# RETURN l_ret_suburb_text 
#
# Get description text of Suburb record
############################################################
FUNCTION db_suburb_get_suburb_text(p_ui_mode,p_suburb_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_suburb_code LIKE suburb.suburb_code
	DEFINE l_ret_suburb_text LIKE suburb.suburb_text

	IF p_suburb_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN	
			ERROR "Suburb Code can NOT be empty"
		END IF
			RETURN NULL
	END IF

	
		SQL
			SELECT suburb_text 
			INTO $l_ret_suburb_text 
			FROM suburb
			WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code				 
			AND suburb.suburb_code = $p_suburb_code  		
		END SQL
	
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Suburb Description with Code ",trim(p_suburb_code),  "NOT found"
		END IF			
		LET l_ret_suburb_text = NULL
	ELSE
		#
	END IF	
	RETURN l_ret_suburb_text
END FUNCTION

############################################################
# FUNCTION db_suburb_get_suburb_code(p_ui_mode,p_suburb_code)
# RETURN l_ret_suburb_text 
#
# Get description text of Product/Part record
############################################################
FUNCTION db_suburb_get_suburb_code(p_ui_mode,p_suburb_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_suburb_code LIKE suburb.suburb_code
	DEFINE l_ret_suburb_code LIKE suburb.suburb_code

	IF p_suburb_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Suburb Code can NOT be empty"
		END IF
		RETURN NULL
	END IF

	
		SQL
			SELECT suburb_code 
			INTO $l_ret_suburb_code
			FROM suburb 
			WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code				
			AND suburb.suburb_code = $p_suburb_code  		
		END SQL
	
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Suburb Reference with Suburb Code ",trim(p_suburb_code),  "NOT found"
		END IF
		LET l_ret_suburb_code = NULL
	ELSE
		#	                                                                                                
	END IF	

	RETURN l_ret_suburb_code	                                                                                                
END FUNCTION


############################################################
# FUNCTION db_suburb_get_suburb_code(p_ui_mode,p_suburb_code)
# RETURN l_ret_suburb_text 
#
# Get description text of suburb/Part record
############################################################
FUNCTION db_suburb_get_state_code(p_ui_mode,p_suburb_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_suburb_code LIKE suburb.suburb_code
	DEFINE l_ret_state_code LIKE suburb.state_code

	IF p_suburb_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Suburb Code can NOT be empty"
		END IF
		RETURN NULL
	END IF

	
		SQL
			SELECT state_code 
			INTO $l_ret_state_code
			FROM suburb
			WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code	
			AND suburb.suburb_code = $p_suburb_code  		
		END SQL
	
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Suberb Code ",trim(p_suburb_code),  "NOT found"
		END IF
		LET l_ret_state_code = NULL
	ELSE
		#	                                                                                                
	END IF	

	RETURN l_ret_state_code	                                                                                                
END FUNCTION



########################################################################################################################
# 
# Get Array record data from DB
#
########################################################################################################################

############################################################
# FUNCTION db_suburb_get_arr_rec(p_query_text)
#
#
############################################################
FUNCTION db_suburb_get_arr_rec(p_query_type,p_query_or_where_text)
	DEFINE p_query_type SMALLINT
	DEFINE p_query_or_where_text STRING
	DEFINE l_query_text STRING
	DEFINE l_where_text STRING
	DEFINE l_arr_rec_suburb DYNAMIC ARRAY OF RECORD LIKE suburb.*		
	DEFINE l_rec_suburb RECORD LIKE suburb.*
	DEFINE l_idx SMALLINT

	IF p_query_type = FILTER_QUERY_WHERE AND p_query_or_where_text IS NULL THEN
		LET p_query_or_where_text = " 1=1 "
	END IF
		
	#p_query_text is optional
	CASE p_query_type
		WHEN FILTER_QUERY_OFF
			LET l_query_text = 
				"SELECT * FROM suburb ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ",					
				"ORDER BY suburb.suburb_code" 	

		WHEN FILTER_QUERY_WHERE
			LET l_where_text = p_query_or_where_text
			LET l_query_text = 
				"SELECT * FROM suburb ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ",					
				"AND ", l_where_text clipped," ",
				"ORDER BY suburb.suburb_code" 	

		WHEN FILTER_QUERY_SELECT
			LET l_query_text = p_query_or_where_text		
		
		OTHERWISE
			LET l_query_text = 
				"SELECT * FROM suburb ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ",					
				"ORDER BY suburb.suburb_code" 				
	END CASE

	PREPARE s_suburb FROM l_query_text
	DECLARE c_suburb CURSOR FOR s_suburb


	LET l_idx = 0
	FOREACH c_suburb INTO l_arr_rec_suburb[l_idx].*
      LET l_idx = l_idx + 1

	END FOREACH

	IF sqlca.sqlcode < 0 THEN   	
		LET l_arr_rec_suburb = NULL	                                                                                        
	ELSE		                                                                                                                    
		#		                                                                                                
	END IF	         

	RETURN l_arr_rec_suburb		                                                                                                
END FUNCTION



############################################################
# FUNCTION db_suburb_get_arr_rec(p_query_text)
#
#
############################################################
FUNCTION db_suburb_get_arr_rec_ac_dt_ac_with_scrollflag(p_query_type,p_query_or_where_text)
	DEFINE p_query_type SMALLINT
	DEFINE p_query_or_where_text STRING
	DEFINE l_query_text STRING
	DEFINE l_where_text STRING
	DEFINE l_arr_rec_suburb DYNAMIC ARRAY OF t_rec_suburb_sc_st_sc_pc	
	DEFINE l_rec_suburb t_rec_suburb_st_sc_pc_with_scrollflag
	DEFINE l_idx SMALLINT
	
	#p_query_text is optional
	IF p_query_or_where_text IS NULL THEN
		LET p_query_type = FILTER_QUERY_OFF
	END IF

	CASE p_query_type
		WHEN FILTER_QUERY_OFF
			LET l_query_text = 
				"SELECT suburb_code,suburb_text,state_code,post_code FROM suburb ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ",					
				"ORDER BY suburb.suburb_code" 	


#		WHEN FILTER_QUERY_ON
#			LET l_query_text = p_query_or_where_text

		WHEN FILTER_QUERY_WHERE
			LET l_where_text = p_query_or_where_text
			LET l_query_text = 
				"SELECT suburb_code,suburb_text,state_code,post_code FROM suburb ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ",					
				"AND ", l_where_text clipped," ",
				"ORDER BY suburb.suburb_code" 	

		WHEN FILTER_QUERY_SELECT
			LET l_query_text = p_query_or_where_text		
		
		OTHERWISE
			LET l_query_text = 
				"SELECT suburb_code,suburb_text,state_code,post_code FROM suburb ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ",					
				"ORDER BY suburb.suburb_code" 				
	END CASE

	PREPARE s2_suburb FROM l_query_text
	DECLARE c2_suburb CURSOR FOR s2_suburb


	LET l_idx = 0
	FOREACH c2_suburb INTO l_rec_suburb.*
		LET l_idx = l_idx + 1
		LET l_arr_rec_suburb[l_idx].* = "",l_rec_suburb.*
	END FOREACH

	IF sqlca.sqlcode < 0 THEN   	
		LET l_arr_rec_suburb = NULL	                                                                                        
	ELSE		                                                                                                                    
		#		                                                                                                
	END IF	         

	RETURN l_arr_rec_suburb		                                                                                                
END FUNCTION





########################################################################################################################
# 
# UPDATE INSERT DELETE row from DB
#
########################################################################################################################


############################################################
# FUNCTION db_suburb_update(p_rec_suburb)
#
#
############################################################
FUNCTION db_suburb_update(p_ui_mode,p_pk_suburb_code,p_rec_suburb)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_pk_suburb_code LIKE suburb.suburb_code
	DEFINE p_rec_suburb RECORD LIKE suburb.*
	DEFINE l_ui_mode SMALLINT
	DEFINE ret INT
	DEFINE msgStr STRING
	
	IF p_ui_mode = UI_ON THEN
		LET l_ui_mode = UI_PK
	END IF

	IF p_pk_suburb_code IS NULL OR p_rec_suburb.suburb_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET msgStr = "Suburb code can not be empty ! (original Suburb Code=",trim(p_pk_suburb_code), " / new Suburb Code=", trim(p_rec_suburb.suburb_code), ")"  
			ERROR msgStr
		END IF
		RETURN -1
	END IF
# Needs doing !!!!!!!!!! 	
#	IF db_XXXXXXXX_get_suburb_count(p_pk_suburb_code) AND (p_pk_suburb_code <> p_rec_suburb.suburb_code) THEN #PK suburb_code can only be changed if it's not used already
#		IF p_ui_mode > 0 THEN
#			ERROR "Can not change Suburb ! It is already used in a configuration"
#		END IF
#		LET ret =  -1
#	ELSE
		
			SQL
				UPDATE suburb
				SET * = $p_rec_suburb.*
				WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code					
				AND suburb_code = $p_pk_suburb_code
			END SQL
			LET ret = status
		
#	END IF

	IF p_ui_mode != UI_OFF THEN #display MESSAGE if ui is enabled
		IF ret < 0 THEN   		
			LET msgStr = "Coud not modify Suburb record ! /nOriginal Suburb", trim(p_pk_suburb_code), "New suburb/Part ", trim(p_rec_suburb.suburb_code),  "\nDatabase Error ", trim(ret)                                                                                        
			#ERROR msgStr 
			CALL fgl_winmessage("Error when trying to modify/update Suburb record",msgStr,"error")
		ELSE
			LET msgStr = "Suburbt record ", trim(p_rec_suburb.suburb_code), " updated successfully !"   
			MESSAGE msgStr
		END IF                                           	
	END IF	
	
	RETURN ret
END FUNCTION        

   
############################################################
# FUNCTION db_suburb_insert(p_rec_suburb)
#
#
############################################################
FUNCTION db_suburb_insert(p_ui_mode,p_rec_suburb)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_rec_suburb RECORD LIKE suburb.*
	DEFINE ret INT
	DEFINE l_ui_mode SMALLINT
	DEFINE msgStr STRING	
	
	IF p_ui_mode = UI_ON THEN
		LET l_ui_mode = UI_PK
	END IF

	IF p_rec_suburb.suburb_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET msgStr = "Suburb code can not be empty ! (Suburb=", trim(p_rec_suburb.suburb_code), ")"  
			ERROR msgStr
		END IF
		RETURN -1
	END IF

	LET p_rec_suburb.cmpy_code = glob_rec_kandoouser.cmpy_code
	
	IF db_suburb_pk_exists(UI_PK,MODE_INSERT,p_rec_suburb.suburb_code) THEN
		LET ret = -1
	ELSE
		
			INSERT INTO suburb
	    VALUES(p_rec_suburb.*)
	    LET ret = status
		
	END IF

	IF p_ui_mode != UI_OFF THEN #display MESSAGE if ui is enabled
		IF ret < 0 THEN   		
			LET msgStr = "Coud not create Suburb record ", trim(p_rec_suburb.suburb_code), " !\nDatabase Error ", trim(ret)                                                                                        
			#ERROR msgStr 
			CALL fgl_winmessage("Error when trying to create/insert Suburb record",msgStr,"error")
		ELSE
			LET msgStr = "PSuburb record ", trim(p_rec_suburb.suburb_code), " created successfully !"   
			MESSAGE msgStr
		END IF                                           	
	END IF
	
	RETURN ret
END FUNCTION


############################################################
# 
# FUNCTION db_suburb_delete(p_suburb_code)
#
#
############################################################
FUNCTION db_suburb_delete(p_ui_mode,p_confirm,p_suburb_code)
	DEFINE p_ui_mode SMALLINT #hide or show error/warning messages
	DEFINE p_confirm BOOLEAN #is operator requested to confirm this operation / independent of ui mode	
	DEFINE p_suburb_code LIKE suburb.suburb_code
	DEFINE l_msgresp LIKE language.yes_flag	
	DEFINE ret SMALLINT	
	DEFINE msgStr STRING

	IF p_confirm = UI_CONFIRM_ON THEN
		LET msgStr = "Delete Suburb configuration ", trim(p_suburb_code), " ?"
		IF NOT promptTF("Delete Suburb",msgStr,TRUE) THEN
			RETURN -2
		END IF
	END IF
	
	IF p_suburb_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET msgStr = "Suburb code can not be empty ! (Suburb=", trim(p_suburb_code), ")"  
			ERROR msgStr
		END IF
		RETURN -1
	END IF
# Needs doing !!!!!!!!!! 
#	IF db_XXXXX_get_suburb_count(p_suburb_code) THEN #PK suburb_code can only be deleted if it's not used already
#		IF p_ui_mode != UI_OFF THEN
#			LET msgStr = "Can not delete Product/Part ! ", trim(p_suburb_code), " It is already used in a bank configuration"
#			CALL fgl_winmessage("Can not delete Suburb ! ",msgStr,"error")
#		END IF
#		LET ret =  -1
#	ELSE
		
			SQL
				DELETE FROM suburb
				WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code					
				AND suburb_code = $p_suburb_code
			END SQL
			LET ret = status
		
			
#	END IF
	
	IF p_ui_mode != UI_OFF THEN #display MESSAGE if ui is enabled
		IF ret < 0 THEN   		
			LET msgStr = "Could not delete Suburb record ", trim(p_suburb_code), " !\nDatabase Error ", trim(ret)                                                                                        
			#ERROR msgStr 
			CALL fgl_winmessage("Error when trying to delete",msgStr,"error")
		ELSE
			LET msgStr = "Suburb record ", trim(p_suburb_code), " deleted !"   
			MESSAGE msgStr
		END IF                                           	
	END IF		             

	RETURN ret	
		  
END FUNCTION
	

############################################################
# 
# FUNCTION db_suburb_delete(p_suburb_code)
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
#	CONSTANT UI_DEL SMALLINT = 4	
############################################################
FUNCTION db_suburb_rec_validation(p_ui_mode,p_op_mode,p_rec_suburb)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_op_mode SMALLINT
	DEFINE p_rec_suburb RECORD LIKE suburb.*
	DEFINE l_ret SMALLINT
	DEFINE l_msgStr STRING
	DISPLAY "p_ui_mode=", p_ui_mode
	DISPLAY "p_op_mode=", p_op_mode
	CASE p_op_mode
		WHEN MODE_INSERT
			#suburb_code
			LET l_msgStr = "Can not create record. TAP Code already exists"  
			IF db_suburb_pk_exists(UI_PK,p_op_mode,p_rec_suburb.suburb_code) THEN
				RETURN -1 #PK Already exists
			END IF		

			#suburb_text
			IF p_rec_suburb.suburb_text IS NULL THEN
				LET l_msgStr =  "Can not create Suburb record with empty description text - suburb_code: ", trim(p_rec_suburb.suburb_code)
				IF p_ui_mode > 0 THEN
					ERROR l_msgStr
				END IF				
				RETURN -2
			END IF

			#suburb_code
			IF NOT db_coa_pk_exists(UI_FK,p_op_mode,p_rec_suburb.suburb_code) THEN
				LET l_msgStr =  "Can not create Suburb record with invalid COA Code: ", trim(p_rec_suburb.suburb_code)
				IF p_ui_mode > 0 THEN
					ERROR l_msgStr
				END IF
				RETURN -3
			END IF
				
		WHEN MODE_UPDATE
			#suburb_code
			IF NOT db_suburb_pk_exists(UI_PK,p_op_mode,p_rec_suburb.suburb_code) THEN
				LET l_msgStr = "Can not update record. TAP Code does not exist!"  			
				RETURN -1 #PK NOT FOUND
			END IF			

			#suburb_text
			IF p_rec_suburb.suburb_text IS NULL THEN
				LET l_msgStr =  "Can not update Suburb record with empty description text - suburb_code: ", trim(p_rec_suburb.suburb_code)
				IF p_ui_mode > 0 THEN
					ERROR l_msgStr
				END IF				
				RETURN -2
			END IF

			#suburb_code
			IF NOT db_coa_pk_exists(UI_FK,p_op_mode,p_rec_suburb.suburb_code) THEN
				LET l_msgStr =  "Can not update Suburb record with invalid GL-COA Code: ", trim(p_rec_suburb.suburb_code)
				IF p_ui_mode > 0 THEN
					ERROR l_msgStr
				END IF
				RETURN -3
			END IF
							
		WHEN MODE_DELETE
			#suburb_code
			IF db_suburb_pk_exists(UI_PK,p_op_mode,p_rec_suburb.suburb_code) THEN
				LET l_msgStr =  "Can not delete Suburb record which does not exist - suburb_code: ", trim(p_rec_suburb.suburb_code)
				IF p_ui_mode > 0 THEN
					ERROR l_msgStr
				END IF
				RETURN -1 #PK NOT FOUND
			END IF			
	
	
	END CASE

	RETURN TRUE
	
	
END FUNCTION	
	
