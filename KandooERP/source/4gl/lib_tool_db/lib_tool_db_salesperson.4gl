########################################################################################################################
# TABLE salesperson
#
#
########################################################################################################################

##########################################################
# GLOBAL Scope Variables
##########################################################
GLOBALS "../common/glob_GLOBALS.4gl"

			
############################################################
# FUNCTION db_salesperson_pk_exists(p_ui_mode,p_op_mode,p_sale_code)
#
# Validate PK - Unique
############################################################
#	CONSTANT UI_OFF SMALLINT = 0
#	CONSTANT UI_ON SMALLINT = 1
#	CONSTANT UI_FK SMALLINT = 2
#	CONSTANT UI_PK SMALLINT = 3
############################################################
FUNCTION db_salesperson_pk_exists(p_ui_mode,p_op_mode,p_sale_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_op_mode SMALLINT	
	DEFINE p_sale_code LIKE salesperson.sale_code
	DEFINE l_ret_exist BOOLEAN
	DEFINE l_recCount INT
	DEFINE l_msgStr STRING

	IF p_sale_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Sales salesperson Code can not be empty"
			#LET msgresp = kandoomsg("G",9178,"")
			#9178 Bank/State/Branchs must NOT be NULL
		END IF
		RETURN FALSE
	END IF
	
	SELECT count(*) 
	INTO l_recCount 
	FROM salesperson 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code				
	AND salesperson.sale_code = p_sale_code  
		
	IF l_recCount > 0 THEN
		LET l_ret_exist = TRUE	
		CASE p_op_mode
			WHEN MODE_INSERT
				CASE p_ui_mode
					WHEN UI_PK
						ERROR "Sales salespersons Code already exists! (", trim(p_sale_code), ")"
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
						MESSAGE "Sales salesperson Code found! (", trim(p_sale_code), ")"
					OTHERWISE
						#No MESSAGE
				END CASE
			
			WHEN MODE_DELETE
				CASE p_ui_mode
					WHEN UI_PK
						#No MESSAGE
					WHEN UI_FK
						ERROR "Sales salesperson Code does not exist! (", trim(p_sale_code), ")"
					OTHERWISE
						#No MESSAGE
				END CASE
					
		END CASE
	ELSE
		LET l_ret_exist = FALSE	
		CASE p_op_mode		
			WHEN MODE_INSERT
				CASE p_ui_mode
					WHEN UI_PK
						#No MESSAGE
					WHEN UI_FK
						ERROR "Sales salesperson Code does not exist! (", trim(p_sale_code), ")"
					OTHERWISE
						#No MESSAGE
				END CASE

			WHEN MODE_UPDATE
				CASE p_ui_mode
					WHEN UI_PK
						ERROR "Sales salesperson Code does not exist! (", trim(p_sale_code), ")"
					WHEN UI_FK
						#No MESSAGE
					OTHERWISE
						#No MESSAGE
				END CASE

			WHEN MODE_DELETE
				CASE p_ui_mode
					WHEN UI_PK
						ERROR "Sales salesperson Code does not exist! (", trim(p_sale_code), ")"
					WHEN UI_FK
						#No MESSAGE
					OTHERWISE
						#No MESSAGE
				END CASE
		END CASE	
	END IF
	
	RETURN l_ret_exist
END FUNCTION
############################################################
# END FUNCTION db_salesperson_pk_exists(p_ui_mode,p_op_mode,p_sale_code)
############################################################


############################################################
# FUNCTION db_salesperson_get_count()
#
# Return total number of rows in salesperson 
############################################################
FUNCTION db_salesperson_get_count()
	DEFINE l_ret_count INT

	SELECT count(*) 
	INTO l_ret_count 
	FROM salesperson 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code				
			
	RETURN l_ret_count
END FUNCTION
############################################################
# END FUNCTION db_salesperson_get_count()
############################################################


############################################################
# FUNCTION db_salesperson_get_count(p_sale_code)
#
# Return total number of rows in salesperson 
############################################################
FUNCTION db_salesperson_get_class_count(p_sale_code)
	DEFINE p_sale_code LIKE salesperson.sale_code
	DEFINE l_ret INT

	SELECT count(*) 
	INTO l_ret 
	FROM salesperson 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code				
	AND salesperson.sale_code = p_sale_code
			
	RETURN l_ret
END FUNCTION
############################################################
# END FUNCTION db_salesperson_get_count(p_sale_code)
############################################################


############################################################
# FUNCTION db_salesperson_get_rec(p_ui_mode,p_sale_code)
# RETURN l_rec_salesperson.*
# Get salesperson/Part record
############################################################
FUNCTION db_salesperson_get_rec(p_ui_mode,p_sale_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_sale_code LIKE salesperson.sale_code
	DEFINE l_rec_salesperson RECORD LIKE salesperson.*

	IF p_sale_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Can not retrieve record with empty Sales salesperson Code"
		END IF
		RETURN NULL
	END IF

	SELECT *
	INTO l_rec_salesperson.*
	FROM salesperson
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code		        
	AND sale_code = p_sale_code
	
	IF sqlca.sqlcode != 0 THEN 	  
		INITIALIZE l_rec_salesperson.* TO NULL                                                                                      
	ELSE		                                                                                                                    
		#		                                                                                                
	END IF	         

	RETURN l_rec_salesperson.*		                                                                                                
END FUNCTION	
############################################################
# END FUNCTION db_salesperson_get_rec(p_ui_mode,p_sale_code)
############################################################


############################################################
# FUNCTION db_salesperson_get_name_text(p_ui_mode,p_sale_code)
# RETURN l_ret_name_text 
#
# Get description text of Sales salesperson record
#
# Someone added a second return value sqlca.sqlcode
# This will break it's usage i.e. DISPLAY db_salesperson_get_name_text() TO field_x
############################################################
FUNCTION db_salesperson_get_name_text(p_ui_mode,p_sale_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_sale_code LIKE salesperson.sale_code
	DEFINE l_ret_name_text LIKE salesperson.name_text

	IF p_sale_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN	
			ERROR "Sales salesperson Code can NOT be empty"
		END IF
			RETURN NULL
	END IF

	SELECT name_text 
	INTO l_ret_name_text 
	FROM salesperson
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code				 
	AND salesperson.sale_code = p_sale_code  		
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Sales salesperson Description with Code ",trim(p_sale_code),  "NOT found"
		END IF			
		LET l_ret_name_text = NULL
	ELSE
		#
	END IF	
	RETURN l_ret_name_text #Huho don't add a second argument,sqlca.sqlcode 
END FUNCTION
############################################################
# END FUNCTION db_salesperson_get_name_text(p_ui_mode,p_sale_code)
############################################################


############################################################
# FUNCTION db_salesperson_get_mgr_code(p_ui_mode,p_sale_code)
# RETURN l_ret_mgr_code 
#
# Get Sales Manager Code of salesperson record
############################################################
FUNCTION db_salesperson_get_mgr_code(p_ui_mode,p_sale_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_sale_code LIKE salesperson.sale_code
	DEFINE l_ret_mgr_code LIKE salesperson.mgr_code

	IF p_sale_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN	
			ERROR "Sales salesperson Code can NOT be empty"
		END IF
			RETURN NULL
	END IF

	SELECT mgr_code 
	INTO l_ret_mgr_code 
	FROM salesperson
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code				 
	AND salesperson.sale_code = p_sale_code  		
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Sales salesperson Description with Code ",trim(p_sale_code),  "NOT found"
		END IF			
		LET l_ret_mgr_code = NULL
	END IF	
	RETURN l_ret_mgr_code
END FUNCTION
############################################################
# END FUNCTION db_salesperson_get_mgr_code(p_ui_mode,p_sale_code)
############################################################


############################################################
# FUNCTION db_salesperson_get_comm_per(p_ui_mode,p_sale_code)
# RETURN l_ret_comm_per 
#
# Get Commission of Sales salesperson record
############################################################
FUNCTION db_salesperson_get_comm_per(p_ui_mode,p_sale_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_sale_code LIKE salesperson.sale_code
	DEFINE l_ret_comm_per LIKE salesperson.comm_per

	IF p_sale_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN	
			ERROR "Sales salesperson Code can NOT be empty"
		END IF
			RETURN NULL
	END IF

	SELECT comm_per 
	INTO l_ret_comm_per 
	FROM salesperson
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code				 
	AND salesperson.sale_code = p_sale_code  		
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Sales salesperson Description with Code ",trim(p_sale_code),  "NOT found"
		END IF			
		LET l_ret_comm_per = NULL
	ELSE
		#
	END IF	
	RETURN l_ret_comm_per
END FUNCTION
############################################################
# END FUNCTION db_salesperson_get_comm_per(p_ui_mode,p_sale_code)
############################################################


############################################################
# FUNCTION db_salesperson_get_terri_code(p_ui_mode,p_sale_code)
# RETURN l_ret_terri_code 
#
# Get Commission of Sales salesperson record
############################################################
FUNCTION db_salesperson_get_terri_code(p_ui_mode,p_sale_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_sale_code LIKE salesperson.sale_code
	DEFINE l_ret_terri_code LIKE salesperson.terri_code

	IF p_sale_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN	
			ERROR "Sales salesperson Code can NOT be empty"
		END IF
			RETURN NULL
	END IF

	SELECT terri_code 
	INTO l_ret_terri_code 
	FROM salesperson
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code				 
	AND salesperson.sale_code = p_sale_code  		
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Sales salesperson Description with Code ",trim(p_sale_code),  "NOT found"
		END IF			
		LET l_ret_terri_code = NULL
	ELSE
		#
	END IF	
	RETURN l_ret_terri_code
END FUNCTION
############################################################
# END FUNCTION db_salesperson_get_terri_code(p_ui_mode,p_sale_code)
############################################################


############################################################
# FUNCTION db_salesperson_get_sale_type_ind(p_ui_mode,p_sale_code)
# RETURN l_ret_sale_type_ind 
#
# Get Commission of Sales salesperson record
############################################################
FUNCTION db_salesperson_get_sale_type_ind(p_ui_mode,p_sale_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_sale_code LIKE salesperson.sale_code
	DEFINE l_ret_sale_type_ind LIKE salesperson.sale_type_ind

	IF p_sale_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN	
			ERROR "Sales salesperson Code can NOT be empty"
		END IF
			RETURN NULL
	END IF

	SELECT sale_type_ind 
	INTO l_ret_sale_type_ind 
	FROM salesperson
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code				 
	AND salesperson.sale_code = p_sale_code  		
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Sales salesperson Description with Code ",trim(p_sale_code),  "NOT found"
		END IF			
		LET l_ret_sale_type_ind = NULL
	ELSE
		#
	END IF	
	RETURN l_ret_sale_type_ind
END FUNCTION
############################################################
# END FUNCTION db_salesperson_get_sale_type_ind(p_ui_mode,p_sale_code)
############################################################


############################################################
# FUNCTION db_salesperson_get_ware_code(p_ui_mode,p_sale_code)
# RETURN l_ret_ware_code 
#
# Get Commission of Sales salesperson record
############################################################
FUNCTION db_salesperson_get_ware_code(p_ui_mode,p_sale_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_sale_code LIKE salesperson.sale_code
	DEFINE l_ret_ware_code LIKE salesperson.ware_code

	IF p_sale_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN	
			ERROR "Sales salesperson Code can NOT be empty"
		END IF
			RETURN NULL
	END IF

	SELECT ware_code 
	INTO l_ret_ware_code 
	FROM salesperson
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code				 
	AND salesperson.sale_code = p_sale_code  		
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Sales salesperson Description with Code ",trim(p_sale_code),  "NOT found"
		END IF			
		LET l_ret_ware_code = NULL
	ELSE
		#
	END IF	
	RETURN l_ret_ware_code
END FUNCTION
############################################################
# END FUNCTION db_salesperson_get_ware_code(p_ui_mode,p_sale_code)
############################################################


############################################################
# FUNCTION db_salesperson_get_acct_mask_code(p_ui_mode,p_sale_code)
# RETURN l_ret_acct_mask_code 
#
# Get Commission of Sales salesperson record
############################################################
FUNCTION db_salesperson_get_acct_mask_code(p_ui_mode,p_sale_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_sale_code LIKE salesperson.sale_code
	DEFINE l_ret_acct_mask_code LIKE salesperson.acct_mask_code

	IF p_sale_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN	
			ERROR "Sales salesperson Code can NOT be empty"
		END IF
			RETURN NULL
	END IF

	SELECT acct_mask_code 
	INTO l_ret_acct_mask_code 
	FROM salesperson
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code				 
	AND salesperson.sale_code = p_sale_code  		
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Sales salesperson Description with Code ",trim(p_sale_code),  "NOT found"
		END IF			
		LET l_ret_acct_mask_code = NULL
	ELSE

	END IF	
	RETURN l_ret_acct_mask_code
END FUNCTION
############################################################
# END FUNCTION db_salesperson_get_acct_mask_code(p_ui_mode,p_sale_code)
############################################################


########################################################################################################################
# 
# Get Array record data from DB
#
########################################################################################################################

############################################################
# FUNCTION db_salesperson_get_arr_rec(p_query_text)
#
#
############################################################
FUNCTION db_salesperson_get_arr_rec(p_query_type,p_query_or_where_text)
	DEFINE p_query_type SMALLINT
	DEFINE p_query_or_where_text STRING
	DEFINE l_query_text STRING
	DEFINE l_where_text STRING
	DEFINE l_arr_rec_salesperson DYNAMIC ARRAY OF RECORD LIKE salesperson.*		
	DEFINE l_rec_salesperson RECORD LIKE salesperson.*
	DEFINE l_idx SMALLINT

	IF p_query_type = FILTER_QUERY_WHERE AND p_query_or_where_text IS NULL THEN
		LET p_query_or_where_text = " 1=1 "
	END IF
		
	#p_query_text is optional
	CASE p_query_type
		WHEN FILTER_QUERY_OFF
			LET l_query_text = 
				"SELECT * FROM salesperson ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ",					
				"ORDER BY salesperson.sale_code" 	

		WHEN FILTER_QUERY_WHERE
			LET l_where_text = p_query_or_where_text
			LET l_query_text = 
				"SELECT * FROM salesperson ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ",					
				"AND ", l_where_text clipped," ",
				"ORDER BY salesperson.sale_code" 	

		WHEN FILTER_QUERY_SELECT
			LET l_query_text = p_query_or_where_text		
		
		OTHERWISE
			LET l_query_text = 
				"SELECT * FROM salesperson ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ",					
				"ORDER BY salesperson.sale_code" 				
	END CASE

	PREPARE s_salesperson FROM l_query_text
	DECLARE c_salesperson CURSOR FOR s_salesperson

	LET l_idx = 0
	FOREACH c_salesperson INTO l_arr_rec_salesperson[l_idx].*
      LET l_idx = l_idx + 1

	END FOREACH

	IF sqlca.sqlcode < 0 THEN   	
		LET l_arr_rec_salesperson = NULL	                                                                                        
	ELSE		                                                                                                                    
		#		                                                                                                
	END IF	         

	RETURN l_arr_rec_salesperson		                                                                                                
END FUNCTION
############################################################
# END FUNCTION db_salesperson_get_arr_rec(p_query_text)
############################################################


########################################################################################################################
# 
# UPDATE INSERT DELETE row from DB
#
########################################################################################################################


############################################################
# FUNCTION db_salesperson_update(p_ui_mode,p_pk_sale_code,p_rec_salesperson)
#
#
############################################################
FUNCTION db_salesperson_update(p_ui_mode,p_pk_sale_code,p_rec_salesperson)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_pk_sale_code LIKE salesperson.sale_code
	DEFINE p_rec_salesperson RECORD LIKE salesperson.*
	DEFINE l_ui_mode SMALLINT
	DEFINE l_ret_status INT
	DEFINE l_msgStr STRING
	
	IF p_ui_mode = UI_ON THEN
		LET l_ui_mode = UI_PK
	END IF

	IF p_pk_sale_code IS NULL OR p_rec_salesperson.sale_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET l_msgStr = "Sales salesperson code can not be empty ! (original Sales salesperson Code=",trim(p_pk_sale_code), " / new Sales salesperson Code=", trim(p_rec_salesperson.sale_code), ")"  
			ERROR l_msgStr
		END IF
		RETURN -1
	END IF
# Needs doing !!!!!!!!!! 	
#	IF db_XXXXXXXX_get_salesperson_count(p_pk_sale_code) AND (p_pk_sale_code <> p_rec_salesperson.sale_code) THEN #PK sale_code can only be changed if it's not used already
#		IF p_ui_mode > 0 THEN
#			ERROR "Can not change Sales salesperson ! It is already used in a configuration"
#		END IF
#		LET l_ret_status =  -1
#	ELSE
	UPDATE salesperson
	SET * = p_rec_salesperson.*
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code					
	AND sale_code = p_pk_sale_code

	LET l_ret_status = status
		
#	END IF

	IF p_ui_mode != UI_OFF THEN #display MESSAGE if ui is enabled
		IF l_ret_status < 0 THEN   		
			LET l_msgStr = "Coud not modify Sales salesperson record ! /nOriginal Sales salesperson", trim(p_pk_sale_code), "New salesperson/Part ", trim(p_rec_salesperson.sale_code),  "\nDatabase Error ", trim(l_ret_status)                                                                                        
			#ERROR l_msgStr 
			CALL fgl_winmessage("Error when trying to modify/update Sales salesperson record",l_msgStr,"error")
		ELSE
			LET l_msgStr = "Sales salespersont record ", trim(p_rec_salesperson.sale_code), " updated successfully !"   
			MESSAGE l_msgStr
		END IF                                           	
	END IF	
	
	RETURN l_ret_status
END FUNCTION        
############################################################
# END FUNCTION db_salesperson_update(p_ui_mode,p_pk_sale_code,p_rec_salesperson)
############################################################

   
############################################################
# FUNCTION db_salesperson_insert(p_rec_salesperson)
#
#
############################################################
FUNCTION db_salesperson_insert(p_ui_mode,p_rec_salesperson)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_rec_salesperson RECORD LIKE salesperson.*
	DEFINE l_ret_status INT
	DEFINE l_ui_mode SMALLINT
	DEFINE l_msgStr STRING	
	
	IF p_ui_mode = UI_ON THEN
		LET l_ui_mode = UI_PK
	END IF

	IF p_rec_salesperson.sale_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET l_msgStr = "Sales salesperson code can not be empty ! (Sales salesperson=", trim(p_rec_salesperson.sale_code), ")"  
			ERROR l_msgStr
		END IF
		RETURN -1
	END IF

	LET p_rec_salesperson.cmpy_code = glob_rec_kandoouser.cmpy_code
	
	IF db_salesperson_pk_exists(UI_PK,MODE_INSERT,p_rec_salesperson.sale_code) THEN
		LET l_ret_status = -1
	ELSE
		
	INSERT INTO salesperson
  VALUES(p_rec_salesperson.*)
  LET l_ret_status = status
		
	END IF

	IF p_ui_mode != UI_OFF THEN #display MESSAGE if ui is enabled
		IF l_ret_status < 0 THEN   		
			LET l_msgStr = "Coud not create Sales salesperson record ", trim(p_rec_salesperson.sale_code), " !\nDatabase Error ", trim(l_ret_status)                                                                                        
			#ERROR l_msgStr 
			CALL fgl_winmessage("Error when trying to create/insert Sales salesperson record",l_msgStr,"error")
		ELSE
			LET l_msgStr = "PSales salesperson record ", trim(p_rec_salesperson.sale_code), " created successfully !"   
			MESSAGE l_msgStr
		END IF                                           	
	END IF
	
	RETURN l_ret_status
END FUNCTION
############################################################
# END FUNCTION db_salesperson_insert(p_rec_salesperson)
############################################################


############################################################
# 
# FUNCTION db_salesperson_delete(p_ui_mode,p_confirm,p_sale_code)
#
#
############################################################
FUNCTION db_salesperson_delete(p_ui_mode,p_confirm,p_sale_code)
	DEFINE p_ui_mode SMALLINT #hide or show error/warning messages
	DEFINE p_confirm BOOLEAN #is operator requested to confirm this operation / independent of ui mode	
	DEFINE p_sale_code LIKE salesperson.sale_code
	DEFINE l_msgresp LIKE language.yes_flag	
	DEFINE l_ret_status SMALLINT	
	DEFINE l_msgStr STRING

	IF p_confirm = UI_CONFIRM_ON THEN
		LET l_msgStr = "Delete Sales salesperson configuration ", trim(p_sale_code), " ?"
		IF NOT promptTF("Delete Sales salesperson",l_msgStr,TRUE) THEN
			RETURN -2
		END IF
	END IF
	
	IF p_sale_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET l_msgStr = "Sales salesperson code can not be empty ! (Sales salesperson=", trim(p_sale_code), ")"  
			ERROR l_msgStr
		END IF
		RETURN -1
	END IF
# Needs doing !!!!!!!!!! 
#	IF db_XXXXX_get_salesperson_count(p_sale_code) THEN #PK sale_code can only be deleted if it's not used already
#		IF p_ui_mode != UI_OFF THEN
#			LET l_msgStr = "Can not delete Product/Part ! ", trim(p_sale_code), " It is already used in a bank configuration"
#			CALL fgl_winmessage("Can not delete Sales salesperson ! ",l_msgStr,"error")
#		END IF
#		LET l_ret_status =  -1
#	ELSE
		
	DELETE FROM salesperson
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code					
	AND sale_code = p_sale_code

	LET l_ret_status = status
			
#	END IF
	
	IF p_ui_mode != UI_OFF THEN #display MESSAGE if ui is enabled
		IF l_ret_status < 0 THEN   		
			LET l_msgStr = "Could not delete Sales salesperson record ", trim(p_sale_code), " !\nDatabase Error ", trim(l_ret_status)                                                                                        
			#ERROR l_msgStr 
			CALL fgl_winmessage("Error when trying to delete",l_msgStr,"error")
		ELSE
			LET l_msgStr = "Sales salesperson record ", trim(p_sale_code), " deleted !"   
			MESSAGE l_msgStr
		END IF                                           	
	END IF		             

	RETURN l_ret_status	
		  
END FUNCTION
############################################################
# END FUNCTION db_salesperson_delete(p_ui_mode,p_confirm,p_sale_code)
############################################################
	

############################################################
# FUNCTION db_salesperson_delete(p_sale_code)
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
FUNCTION db_salesperson_rec_validation(p_ui_mode,p_op_mode,p_rec_salesperson)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_op_mode SMALLINT
	DEFINE p_rec_salesperson RECORD LIKE salesperson.*
	DEFINE l_ret SMALLINT
	DEFINE l_msgStr STRING
	DISPLAY "p_ui_mode=", p_ui_mode
	DISPLAY "p_op_mode=", p_op_mode
	CASE p_op_mode
		WHEN MODE_INSERT
			#sale_code
			LET l_msgStr = "Can not create record. TAP Code already exists"  
			IF db_salesperson_pk_exists(UI_PK,p_op_mode,p_rec_salesperson.sale_code) THEN
				RETURN -1 #PK Already exists
			END IF		

			#name_text
			IF p_rec_salesperson.name_text IS NULL THEN
				LET l_msgStr =  "Can not create Sales salesperson record with empty description text - sale_code: ", trim(p_rec_salesperson.sale_code)
				IF p_ui_mode > 0 THEN
					ERROR l_msgStr
				END IF				
				RETURN -2
			END IF

			#sale_code
			IF NOT db_coa_pk_exists(UI_FK,p_op_mode,p_rec_salesperson.sale_code) THEN
				LET l_msgStr =  "Can not create Sales salesperson record with invalid COA Code: ", trim(p_rec_salesperson.sale_code)
				IF p_ui_mode > 0 THEN
					ERROR l_msgStr
				END IF
				RETURN -3
			END IF
				
		WHEN MODE_UPDATE
			#sale_code
			IF NOT db_salesperson_pk_exists(UI_PK,p_op_mode,p_rec_salesperson.sale_code) THEN
				LET l_msgStr = "Can not update record. TAP Code does not exist!"  			
				RETURN -1 #PK NOT FOUND
			END IF			

			#name_text
			IF p_rec_salesperson.name_text IS NULL THEN
				LET l_msgStr =  "Can not update Sales salesperson record with empty description text - sale_code: ", trim(p_rec_salesperson.sale_code)
				IF p_ui_mode > 0 THEN
					ERROR l_msgStr
				END IF				
				RETURN -2
			END IF

			#sale_code
			IF NOT db_coa_pk_exists(UI_FK,p_op_mode,p_rec_salesperson.sale_code) THEN
				LET l_msgStr =  "Can not update Sales salesperson record with invalid GL-COA Code: ", trim(p_rec_salesperson.sale_code)
				IF p_ui_mode > 0 THEN
					ERROR l_msgStr
				END IF
				RETURN -3
			END IF
							
		WHEN MODE_DELETE
			#sale_code
			IF db_salesperson_pk_exists(UI_PK,p_op_mode,p_rec_salesperson.sale_code) THEN
				LET l_msgStr =  "Can not delete Sales salesperson record which does not exist - sale_code: ", trim(p_rec_salesperson.sale_code)
				IF p_ui_mode > 0 THEN
					ERROR l_msgStr
				END IF
				RETURN -1 #PK NOT FOUND
			END IF			
	
	END CASE

	RETURN TRUE	
END FUNCTION	
############################################################
# END FUNCTION db_salesperson_delete(p_sale_code)
############################################################