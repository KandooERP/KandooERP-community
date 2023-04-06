########################################################################################################################
# TABLE opparms
#
#
########################################################################################################################
##########################################################
# GLOBAL Scope Variables
##########################################################
GLOBALS "../common/glob_GLOBALS.4gl"
############################################################
# FUNCTION db_opparms_pk_exists(p_ui_mode,p_op_mode,p_key_num)
#
# Validate PK - Unique
############################################################
#	CONSTANT UI_OFF SMALLINT = 0
#	CONSTANT UI_ON SMALLINT = 1
#	CONSTANT UI_FK SMALLINT = 2
#	CONSTANT UI_PK SMALLINT = 3
############################################################
FUNCTION db_opparms_pk_exists(p_ui_mode,p_op_mode,p_key_num)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_op_mode SMALLINT	
	DEFINE p_key_num LIKE opparms.key_num
	DEFINE l_ret_pk_exist BOOLEAN
	DEFINE l_recCount INT
	DEFINE l_msgStr STRING

	IF p_key_num IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "opparms Key (FK/PK) can not be NULL(empty)"
			#LET msgresp = kandoomsg("G",9178,"")
			#9178 Bank/State/Branchs must NOT be NULL
		END IF
		RETURN FALSE
	END IF
	
	SELECT count(*) 
	INTO l_recCount 
	FROM opparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code				
	AND opparms.key_num = p_key_num  
		
	IF l_recCount > 0 THEN
		LET l_ret_pk_exist = TRUE	
		CASE p_op_mode
			WHEN MODE_INSERT
				CASE p_ui_mode
					WHEN UI_PK
						ERROR "opparms Code already exists! (", trim(p_key_num), ")"
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
						ERROR "opparms Key (FK/PK) does not exist! (", trim(p_key_num), ")"
					OTHERWISE
						#No MESSAGE
				END CASE
			
			WHEN MODE_DELETE
				CASE p_ui_mode
					WHEN UI_PK
						#No MESSAGE
					WHEN UI_FK
						ERROR "opparms Key (FK/PK) does not exist! (", trim(p_key_num), ")"
					OTHERWISE
						#No MESSAGE
				END CASE
					
		END CASE
	ELSE
		LET l_ret_pk_exist = FALSE	
		CASE p_op_mode		
			WHEN MODE_INSERT
				CASE p_ui_mode
					WHEN UI_PK
						#No MESSAGE
					WHEN UI_FK
						ERROR "opparms Key (FK/PK) does not exist! (", trim(p_key_num), ")"
					OTHERWISE
						#No MESSAGE
				END CASE

			WHEN MODE_UPDATE
				CASE p_ui_mode
					WHEN UI_PK
						ERROR "opparms Key (FK/PK) does not exist! (", trim(p_key_num), ")"
					WHEN UI_FK
						#No MESSAGE
					OTHERWISE
						#No MESSAGE
				END CASE

			WHEN MODE_DELETE
				CASE p_ui_mode
					WHEN UI_PK
						ERROR "opparms Key (FK/PK) does not exist! (", trim(p_key_num), ")"
					WHEN UI_FK
						#No MESSAGE
					OTHERWISE
						#No MESSAGE
				END CASE
		END CASE	
	END IF
	
	RETURN l_ret_pk_exist
END FUNCTION
############################################################
# END FUNCTION db_opparms_pk_exists(p_ui_mode,p_op_mode,p_key_num)
############################################################


############################################################
# FUNCTION db_opparms_get_count()
#
# Return total number of rows in opparms 
############################################################
FUNCTION db_opparms_get_count()
	DEFINE l_ret_count INT

	SELECT count(*) 
	INTO l_ret_count 
	FROM opparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code				
			
	RETURN l_ret_count
END FUNCTION
############################################################
# END FUNCTION db_opparms_get_count()
############################################################


############################################################
# FUNCTION db_opparms_get_count(p_key_num)
#
# Return total number of rows in opparms 
############################################################
FUNCTION db_opparms_get_class_count(p_key_num)
	DEFINE p_key_num LIKE opparms.key_num
	DEFINE l_ret_count INT

	SELECT count(*) 
	INTO l_ret_count 
	FROM opparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code				
	AND opparms.key_num = p_key_num
			
	RETURN l_ret_count
END FUNCTION
############################################################
# END FUNCTION db_opparms_get_count(p_key_num)
############################################################


############################################################
# FUNCTION db_opparms_get_rec(p_ui_mode,p_key_num)
# RETURN l_rec_opparms.*
# Get opparms/Part record
############################################################
FUNCTION db_opparms_get_rec(p_ui_mode,p_key_num)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_key_num LIKE opparms.key_num
	DEFINE l_rec_opparms RECORD LIKE opparms.*

	IF p_key_num IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Can not retrieve record with empty Operational Parameters Key (FK/PK)"
		END IF
		RETURN NULL
	END IF

	SELECT *
	INTO l_rec_opparms.*
	FROM opparms
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code		        
	AND key_num = p_key_num
	
	IF sqlca.sqlcode != 0 THEN   		  
		INITIALIZE l_rec_opparms.* TO NULL                                                                                      
	ELSE		                                                                                                                    
		#		                                                                                                
	END IF	         

	RETURN l_rec_opparms.*		                                                                                                
END FUNCTION	
############################################################
# END FUNCTION db_opparms_get_rec(p_ui_mode,p_key_num)
############################################################


############################################################
# FUNCTION db_opparms_get_next_ord_num(p_ui_mode,p_key_num)
# RETURN l_ret_next_ord_num 
#
# Get description text of Operational Parameters record
############################################################
FUNCTION db_opparms_get_next_ord_num(p_ui_mode,p_key_num)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_key_num LIKE opparms.key_num
	DEFINE l_ret_next_ord_num LIKE opparms.next_ord_num

	IF p_key_num IS NULL THEN
		IF p_ui_mode != UI_OFF THEN	
			ERROR "Operational Parameters Key (FK/PK) can NOT be empty"
		END IF
			RETURN NULL
	END IF

	SELECT next_ord_num 
	INTO l_ret_next_ord_num 
	FROM opparms
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code				 
	AND opparms.key_num = p_key_num  		
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Operational Parameters with Key (FK/PK) ",trim(p_key_num),  "NOT found"
		END IF			
		LET l_ret_next_ord_num = NULL
	ELSE
		#
	END IF	
	RETURN l_ret_next_ord_num
END FUNCTION
############################################################
# END FUNCTION db_opparms_get_next_ord_num(p_ui_mode,p_key_num)
############################################################


############################################################
# FUNCTION db_opparms_get_next_pick_num(p_ui_mode,p_key_num)
# RETURN l_ret_desc_text 
#
# Get description text of Product/Part record
############################################################
FUNCTION db_opparms_get_next_pick_num(p_ui_mode,p_key_num)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_key_num LIKE opparms.key_num
	DEFINE l_ret_next_pick_num LIKE opparms.next_pick_num

	IF p_key_num IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Operational Parameters Key (FK/PK) can NOT be empty"
		END IF
		RETURN NULL
	END IF
	
	SELECT next_pick_num 
	INTO l_ret_next_pick_num
	FROM opparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code				
	AND opparms.key_num = p_key_num  		
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Operational Parameters Reference with Operational Parameters Key (FK/PK) ",trim(p_key_num),  "NOT found"
		END IF
		LET l_ret_next_pick_num = NULL
	ELSE
		#	                                                                                                
	END IF	

	RETURN l_ret_next_pick_num	                                                                                                
END FUNCTION
############################################################
# END FUNCTION db_opparms_get_next_pick_num(p_ui_mode,p_key_num)
############################################################


############################################################
# FUNCTION db_opparms_get_cal_available_flag (p_ui_mode,p_key_num)
# RETURN l_ret_cal_available_flag  
#
# Get description text of Operational Parameters record
############################################################
FUNCTION db_opparms_get_cal_available_flag(p_ui_mode,p_key_num)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_key_num LIKE opparms.key_num
	DEFINE l_ret_cal_available_flag  LIKE opparms.cal_available_flag 

	IF p_key_num IS NULL THEN
		IF p_ui_mode != UI_OFF THEN	
			ERROR "Operational Parameters Key (FK/PK) can NOT be empty"
		END IF
			RETURN NULL
	END IF

	SELECT cal_available_flag  
	INTO l_ret_cal_available_flag  
	FROM opparms
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code				 
	AND opparms.key_num = p_key_num  		
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Operational Parameters with Key (FK/PK) ",trim(p_key_num),  "NOT found"
		END IF			
		LET l_ret_cal_available_flag  = NULL
	ELSE
		#
	END IF	
	RETURN l_ret_cal_available_flag 
END FUNCTION
############################################################
# END FUNCTION db_opparms_get_cal_available_flag (p_ui_mode,p_key_num)
############################################################




########################################################################################################################
# 
# Get Array record data from DB
#
########################################################################################################################
############################################################
# FUNCTION db_opparms_get_arr_rec(p_query_type,p_query_or_where_text)
#
#
############################################################
FUNCTION db_opparms_get_arr_rec(p_query_type,p_query_or_where_text)
	DEFINE p_query_type SMALLINT
	DEFINE p_query_or_where_text STRING
	DEFINE l_query_text STRING
	DEFINE l_where_text STRING
	DEFINE l_arr_rec_opparms DYNAMIC ARRAY OF RECORD LIKE opparms.*		
	DEFINE l_rec_opparms RECORD LIKE opparms.*
	DEFINE l_idx SMALLINT

	IF p_query_type = FILTER_QUERY_WHERE AND p_query_or_where_text IS NULL THEN
		LET p_query_or_where_text = " 1=1 "
	END IF
		
	#p_query_text is optional
	CASE p_query_type
		WHEN FILTER_QUERY_OFF
			LET l_query_text = 
				"SELECT * FROM opparms ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ",					
				"ORDER BY opparms.key_num" 	

		WHEN FILTER_QUERY_WHERE
			LET l_where_text = p_query_or_where_text
			LET l_query_text = 
				"SELECT * FROM opparms ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ",					
				"AND ", l_where_text clipped," ",
				"ORDER BY opparms.key_num" 	

		WHEN FILTER_QUERY_SELECT
			LET l_query_text = p_query_or_where_text		
		
		OTHERWISE
			LET l_query_text = 
				"SELECT * FROM opparms ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ",					
				"ORDER BY opparms.key_num" 				
	END CASE

	PREPARE s_opparms FROM l_query_text
	DECLARE c_opparms CURSOR FOR s_opparms


	LET l_idx = 0
	FOREACH c_opparms INTO l_arr_rec_opparms[l_idx].*
      LET l_idx = l_idx + 1

	END FOREACH

	IF sqlca.sqlcode < 0 THEN   	
		LET l_arr_rec_opparms = NULL	                                                                                        
	ELSE		                                                                                                                    
		#		                                                                                                
	END IF	         

	RETURN l_arr_rec_opparms		                                                                                                
END FUNCTION
############################################################
# END FUNCTION db_opparms_get_arr_rec(p_query_type,p_query_or_where_text)
############################################################




########################################################################################################################
# 
# UPDATE INSERT DELETE row from DB
#
########################################################################################################################

############################################################
# FUNCTION db_opparms_update(p_ui_mode,p_pk_key_num,p_rec_opparms)
#
#
############################################################
FUNCTION db_opparms_update(p_ui_mode,p_pk_key_num,p_rec_opparms)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_pk_key_num LIKE opparms.key_num
	DEFINE p_rec_opparms RECORD LIKE opparms.*
	DEFINE l_ui_mode SMALLINT
	DEFINE l_ret_update_status INT
	DEFINE l_msgStr STRING
	
	IF p_ui_mode = UI_ON THEN
		LET l_ui_mode = UI_PK
	END IF

	IF p_pk_key_num IS NULL OR p_rec_opparms.key_num IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET l_msgStr = "Operational Parameters Key (FK/PK) can not be empty ! (original opparms Key (FK/PK)=",trim(p_pk_key_num), " / new opparms Key (FK/PK)=", trim(p_rec_opparms.key_num), ")"  
			ERROR l_msgStr
		END IF
		RETURN -1
	END IF
# Needs doing !!!!!!!!!! 	
#	IF db_XXXXXXXX_get_opparms_count(p_pk_key_num) AND (p_pk_key_num <> p_rec_opparms.key_num) THEN #PK key_num can only be changed if it's not used already
#		IF p_ui_mode > 0 THEN
#			ERROR "Can not change Operational Parameters ! It is already used in a configuration"
#		END IF
#		LET l_ret_update_status =  -1
#	ELSE
		
	UPDATE opparms
	SET * = p_rec_opparms.*
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code					
	AND key_num = p_pk_key_num

	LET l_ret_update_status = status
		
#	END IF

	IF p_ui_mode != UI_OFF THEN #display MESSAGE if ui is enabled
		IF l_ret_update_status < 0 THEN   		
			LET l_msgStr = "Coud not modify Operational Parameters record ! /nOriginal opparms", trim(p_pk_key_num), "New opparms/Part ", trim(p_rec_opparms.key_num),  "\nDatabase Error ", trim(l_ret_update_status)                                                                                        
			#ERROR l_msgStr 
			CALL fgl_winmessage("Error when trying to modify/update Operational Parameters record",l_msgStr,"error")
		ELSE
			LET l_msgStr = "Operational Parameterst record ", trim(p_rec_opparms.key_num), " updated successfully !"   
			MESSAGE l_msgStr
		END IF                                           	
	END IF	
	
	RETURN l_ret_update_status
END FUNCTION        
############################################################
# END FUNCTION db_opparms_update(p_ui_mode,p_pk_key_num,p_rec_opparms)
############################################################

   
############################################################
# FUNCTION db_opparms_insert(p_ui_mode,p_rec_opparms)
#
#
############################################################
FUNCTION db_opparms_insert(p_ui_mode,p_rec_opparms)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_rec_opparms RECORD LIKE opparms.*
	DEFINE l_ret_insert_status INT
	DEFINE l_ui_mode SMALLINT
	DEFINE l_msgStr STRING	
	
	IF p_ui_mode = UI_ON THEN
		LET l_ui_mode = UI_PK
	END IF

	IF p_rec_opparms.key_num IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET l_msgStr = "Operational Parameters Key (FK/PK) can not be empty ! (opparms=", trim(p_rec_opparms.key_num), ")"  
			ERROR l_msgStr
		END IF
		RETURN -1
	END IF

	LET p_rec_opparms.cmpy_code = glob_rec_kandoouser.cmpy_code
	
	IF db_opparms_pk_exists(UI_PK,MODE_INSERT,p_rec_opparms.key_num) THEN
		LET l_ret_insert_status = -1
	ELSE
		
	INSERT INTO opparms
  VALUES(p_rec_opparms.*)
  LET l_ret_insert_status = status
		
	END IF

	IF p_ui_mode != UI_OFF THEN #display MESSAGE if ui is enabled
		IF l_ret_insert_status < 0 THEN   		
			LET l_msgStr = "Coud not create Operational Parameters record ", trim(p_rec_opparms.key_num), " !\nDatabase Error ", trim(l_ret_insert_status)                                                                                        
			#ERROR l_msgStr 
			CALL fgl_winmessage("Error when trying to create/insert Operational Parameters record",l_msgStr,"error")
		ELSE
			LET l_msgStr = "POperational Parameters record ", trim(p_rec_opparms.key_num), " created successfully !"   
			MESSAGE l_msgStr
		END IF                                           	
	END IF
	
	RETURN l_ret_insert_status
END FUNCTION
############################################################
# END FUNCTION db_opparms_insert(p_ui_mode,p_rec_opparms)
############################################################


############################################################
# FUNCTION db_opparms_delete(p_ui_mode,p_confirm,p_key_num)
#
#
############################################################
FUNCTION db_opparms_delete(p_ui_mode,p_confirm,p_key_num)
	DEFINE p_ui_mode SMALLINT #hide or show error/warning messages
	DEFINE p_confirm BOOLEAN #is operator requested to confirm this operation / independent of ui mode	
	DEFINE p_key_num LIKE opparms.key_num
	DEFINE l_msgresp LIKE language.yes_flag	
	DEFINE l_ret_delete_status SMALLINT	
	DEFINE l_msgStr STRING

	IF p_confirm = UI_CONFIRM_ON THEN
		LET l_msgStr = "Delete Operational Parameters configuration ", trim(p_key_num), " ?"
		IF NOT promptTF("Delete opparms",l_msgStr,TRUE) THEN
			RETURN -2
		END IF
	END IF
	
	IF p_key_num IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET l_msgStr = "Operational Parameters Key (FK/PK) can not be empty ! (opparms=", trim(p_key_num), ")"  
			ERROR l_msgStr
		END IF
		RETURN -1
	END IF
# Needs doing !!!!!!!!!! 
#	IF db_XXXXX_get_opparms_count(p_key_num) THEN #PK key_num can only be deleted if it's not used already
#		IF p_ui_mode != UI_OFF THEN
#			LET l_msgStr = "Can not delete Product/Part ! ", trim(p_key_num), " It is already used in a bank configuration"
#			CALL fgl_winmessage("Can not delete opparms ! ",l_msgStr,"error")
#		END IF
#		LET l_ret_delete_status =  -1
#	ELSE
		
	DELETE FROM opparms
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code					
	AND key_num = p_key_num

	LET l_ret_delete_status = status
		
			
#	END IF
	
	IF p_ui_mode != UI_OFF THEN #display MESSAGE if ui is enabled
		IF l_ret_delete_status < 0 THEN   		
			LET l_msgStr = "Could not delete Operational Parameters record ", trim(p_key_num), " !\nDatabase Error ", trim(l_ret_delete_status)                                                                                        
			#ERROR l_msgStr 
			CALL fgl_winmessage("Error when trying to delete",l_msgStr,"error")
		ELSE
			LET l_msgStr = "Operational Parameters record ", trim(p_key_num), " deleted !"   
			MESSAGE l_msgStr
		END IF                                           	
	END IF		             

	RETURN l_ret_delete_status	
		  
END FUNCTION
############################################################
# END FUNCTION db_opparms_delete(p_ui_mode,p_confirm,p_key_num)
############################################################
	

############################################################
# FUNCTION db_opparms_rec_validation(p_ui_mode,p_op_mode,p_rec_opparms)
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
FUNCTION db_opparms_rec_validation(p_ui_mode,p_op_mode,p_rec_opparms)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_op_mode SMALLINT
	DEFINE p_rec_opparms RECORD LIKE opparms.*
	DEFINE l_ret SMALLINT
	DEFINE l_msgStr STRING

--	DISPLAY "p_ui_mode=", p_ui_mode
--	DISPLAY "p_op_mode=", p_op_mode
	
	CASE p_op_mode
		WHEN MODE_INSERT
			#key_num
			LET l_msgStr = "Can not create record. TAP Key (FK/PK) already exists"  
			IF db_opparms_pk_exists(UI_PK,p_op_mode,p_rec_opparms.key_num) THEN
				RETURN -1 #PK Already exists
			END IF		

			#next_ord_num
			IF p_rec_opparms.next_ord_num = 0 THEN
				LET l_msgStr =  "Can not create opparms record with empty next_ord_num: ", trim(p_rec_opparms.key_num)
				IF p_ui_mode > 0 THEN
					ERROR l_msgStr
				END IF				
				RETURN -2
			END IF

--			#next_pick_num
--			IF NOT db_coa_pk_exists(UI_FK,p_op_mode,p_rec_opparms.next_pick_num) THEN
--				LET l_msgStr =  "Can not create opparms record with invalid COA Key (FK/PK): ", trim(p_rec_opparms.next_pick_num)
--				IF p_ui_mode > 0 THEN
--					ERROR l_msgStr
--				END IF
--				RETURN -3
--			END IF
				
		WHEN MODE_UPDATE
			#key_num
			IF NOT db_opparms_pk_exists(UI_PK,p_op_mode,p_rec_opparms.key_num) THEN
				LET l_msgStr = "Can not update record. TAP Key (FK/PK) does not exist!"  			
				RETURN -1 #PK NOT FOUND
			END IF			

			#next_ord_num
			IF p_rec_opparms.next_ord_num IS NULL THEN
				LET l_msgStr =  "Can not update opparms record with empty description text - key_num: ", trim(p_rec_opparms.key_num)
				IF p_ui_mode > 0 THEN
					ERROR l_msgStr
				END IF				
				RETURN -2
			END IF

			#next_pick_num
			IF NOT db_coa_pk_exists(UI_FK,p_op_mode,p_rec_opparms.next_pick_num) THEN
				LET l_msgStr =  "Can not update opparms record with invalid GL-COA Key (FK/PK): ", trim(p_rec_opparms.next_pick_num)
				IF p_ui_mode > 0 THEN
					ERROR l_msgStr
				END IF
				RETURN -3
			END IF
							
		WHEN MODE_DELETE
			#key_num
			IF db_opparms_pk_exists(UI_PK,p_op_mode,p_rec_opparms.key_num) THEN
				LET l_msgStr =  "Can not delete opparms record which does not exist - key_num: ", trim(p_rec_opparms.key_num)
				IF p_ui_mode > 0 THEN
					ERROR l_msgStr
				END IF
				RETURN -1 #PK NOT FOUND
			END IF				
	
	END CASE

	RETURN TRUE
	
END FUNCTION	
############################################################
# END FUNCTION db_opparms_rec_validation(p_ui_mode,p_op_mode,p_rec_opparms)
############################################################