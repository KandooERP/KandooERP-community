########################################################################################################################
# TABLE territory
#
#
########################################################################################################################

##########################################################
# GLOBAL Scope Variables
##########################################################
GLOBALS "../common/glob_GLOBALS.4gl"

############################################################
# FUNCTION db_territory_pk_exists(p_ui_mode,p_op_mode,p_terr_code)
#
# Validate PK - Unique
############################################################
#	CONSTANT UI_OFF SMALLINT = 0
#	CONSTANT UI_ON SMALLINT = 1
#	CONSTANT UI_FK SMALLINT = 2
#	CONSTANT UI_PK SMALLINT = 3
############################################################
FUNCTION db_territory_pk_exists(p_ui_mode,p_op_mode,p_terr_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_op_mode SMALLINT	
	DEFINE p_terr_code LIKE territory.terr_code
	DEFINE l_ret_exist BOOLEAN
	DEFINE l_recCount INT
	DEFINE l_msgStr STRING

	IF p_terr_code IS NULL THEN
		IF p_ui_mode >= UI_ON THEN
			ERROR "Sales Territory Code can not be empty"
			#LET msgresp = kandoomsg("G",9178,"")
			#9178 Bank/State/Branchs must NOT be NULL
		END IF
		RETURN FALSE
	END IF

	SELECT count(*) 
	INTO l_recCount 
	FROM territory 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code				
	AND territory.terr_code = p_terr_code  
		
	IF l_recCount > 0 THEN
		LET l_ret_exist = TRUE	
		CASE p_op_mode
			WHEN MODE_INSERT
				CASE p_ui_mode
					WHEN UI_PK
						ERROR "Sales Territorys Code already exists! (", trim(p_terr_code), ")"
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
						ERROR "Sales Territory Code does not exist! (", trim(p_terr_code), ")"
					OTHERWISE
						#No MESSAGE
				END CASE
			
			WHEN MODE_DELETE
				CASE p_ui_mode
					WHEN UI_PK
						#No MESSAGE
					WHEN UI_FK
						ERROR "Sales Territory Code does not exist! (", trim(p_terr_code), ")"
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
						ERROR "Sales Territory Code does not exist! (", trim(p_terr_code), ")"
					OTHERWISE
						#No MESSAGE
				END CASE

			WHEN MODE_UPDATE
				CASE p_ui_mode
					WHEN UI_PK
						ERROR "Sales Territory Code does not exist! (", trim(p_terr_code), ")"
					WHEN UI_FK
						#No MESSAGE
					OTHERWISE
						#No MESSAGE
				END CASE

			WHEN MODE_DELETE
				CASE p_ui_mode
					WHEN UI_PK
						ERROR "Sales Territory Code does not exist! (", trim(p_terr_code), ")"
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
# END FUNCTION db_territory_pk_exists(p_ui_mode,p_op_mode,p_terr_code)
############################################################


############################################################
# FUNCTION db_territory_get_count()
#
# Return total number of rows in territory 
############################################################
FUNCTION db_territory_get_count()
	DEFINE l_ret_count INT

	SELECT count(*) 
	INTO l_ret_count 
	FROM territory 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code				
			
	RETURN l_ret_count
END FUNCTION
############################################################
# END FUNCTION db_territory_get_count()
############################################################


############################################################
# FUNCTION db_territory_get_count(p_terr_code)
#
# Return total number of rows in territory 
############################################################
FUNCTION db_territory_get_class_count(p_terr_code)
	DEFINE p_terr_code LIKE territory.terr_code
	DEFINE l_ret INT

	SELECT count(*) 
	INTO l_ret 
	FROM territory 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code				
	AND territory.terr_code = p_terr_code
			
	RETURN l_ret
END FUNCTION
############################################################
# END FUNCTION db_territory_get_count(p_terr_code)
############################################################


############################################################
# FUNCTION db_territory_get_rec(p_ui_mode,p_terr_code)
# RETURN l_rec_territory.*
# Get territory/Part record
############################################################
FUNCTION db_territory_get_rec(p_ui_mode,p_terr_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_terr_code LIKE territory.terr_code
	DEFINE l_rec_territory RECORD LIKE territory.*

	IF p_terr_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Can not retrieve record with empty Sales Territory Code"
		END IF
		RETURN NULL
	END IF

	SELECT *
	INTO l_rec_territory.*
	FROM territory
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code		        
	AND terr_code = p_terr_code
	
	IF sqlca.sqlcode != 0 THEN   		  
		INITIALIZE l_rec_territory.* TO NULL                                                                                      
	ELSE		                                                                                                                    
		#		                                                                                                
	END IF	         

	RETURN l_rec_territory.*		                                                                                                
END FUNCTION	
############################################################
# END FUNCTION db_territory_get_rec(p_ui_mode,p_terr_code)
############################################################


############################################################
# FUNCTION db_territory_get_desc_text(p_ui_mode,p_terr_code)
# RETURN l_ret_desc_text 
#
# Get description text of Sales Territory record
############################################################
FUNCTION db_territory_get_desc_text(p_ui_mode,p_terr_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_terr_code LIKE territory.terr_code
	DEFINE l_ret_desc_text LIKE territory.desc_text

	IF p_terr_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN	
			ERROR "Sales Territory Code can NOT be empty"
		END IF
			RETURN NULL
	END IF

	SELECT desc_text 
	INTO l_ret_desc_text 
	FROM territory
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code				 
	AND territory.terr_code = p_terr_code  		
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Sales Territory Description with Code ",trim(p_terr_code),  "NOT found"
		END IF			
		LET l_ret_desc_text = NULL
	ELSE
		#
	END IF	
	RETURN l_ret_desc_text
END FUNCTION
############################################################
# END FUNCTION db_territory_get_desc_text(p_ui_mode,p_terr_code)
############################################################


############################################################
# FUNCTION db_territory_get_area_code(p_ui_mode,p_terr_code)
# RETURN l_ret_area_code 
#
# Get description text of Sales Territory record
############################################################
FUNCTION db_territory_get_area_code(p_ui_mode,p_terr_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_terr_code LIKE territory.terr_code
	DEFINE l_ret_area_code LIKE territory.area_code

	IF p_terr_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN	
			ERROR "Sales Territory Code can NOT be empty"
		END IF
			RETURN NULL
	END IF

	SELECT area_code 
	INTO l_ret_area_code 
	FROM territory
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code				 
	AND territory.terr_code = p_terr_code  		
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Sales Territory Description with Code ",trim(p_terr_code),  "NOT found"
		END IF			
		LET l_ret_area_code = NULL
	ELSE
		#
	END IF	
	RETURN l_ret_area_code
END FUNCTION
############################################################
# END FUNCTION db_territory_get_area_code(p_ui_mode,p_terr_code)
############################################################


############################################################
# FUNCTION db_territory_get_sale_code(p_ui_mode,p_terr_code)
# RETURN l_ret_sale_code 
#
# Get description text of Sales Territory record
############################################################
FUNCTION db_territory_get_sale_code(p_ui_mode,p_terr_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_terr_code LIKE territory.terr_code
	DEFINE l_ret_sale_code LIKE territory.sale_code

	IF p_terr_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN	
			ERROR "Sales Territory Code can NOT be empty"
		END IF
			RETURN NULL
	END IF

	SELECT sale_code 
	INTO l_ret_sale_code 
	FROM territory
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code				 
	AND territory.terr_code = p_terr_code  		
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Sales Territory Description with Code ",trim(p_terr_code),  "NOT found"
		END IF			
		LET l_ret_sale_code = NULL
	ELSE
		#
	END IF	
	RETURN l_ret_sale_code
END FUNCTION
############################################################
# END FUNCTION db_territory_get_sale_code(p_ui_mode,p_terr_code)
############################################################


########################################################################################################################
# 
# Get Array record data from DB
#
########################################################################################################################

############################################################
# FUNCTION db_territory_get_arr_rec(p_query_text)
#
#
############################################################
FUNCTION db_territory_get_arr_rec(p_query_type,p_query_or_where_text)
	DEFINE p_query_type SMALLINT
	DEFINE p_query_or_where_text STRING
	DEFINE l_query_text STRING
	DEFINE l_where_text STRING
	DEFINE l_arr_rec_territory DYNAMIC ARRAY OF RECORD LIKE territory.*		
	DEFINE l_rec_territory RECORD LIKE territory.*
	DEFINE l_idx SMALLINT

	IF p_query_type = FILTER_QUERY_WHERE AND p_query_or_where_text IS NULL THEN
		LET p_query_or_where_text = " 1=1 "
	END IF
		
	#p_query_text is optional
	CASE p_query_type
		WHEN FILTER_QUERY_OFF
			LET l_query_text = 
				"SELECT * FROM territory ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ",					
				"ORDER BY territory.terr_code" 	

		WHEN FILTER_QUERY_WHERE
			LET l_where_text = p_query_or_where_text
			LET l_query_text = 
				"SELECT * FROM territory ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ",					
				"AND ", l_where_text clipped," ",
				"ORDER BY territory.terr_code" 	

		WHEN FILTER_QUERY_SELECT
			LET l_query_text = p_query_or_where_text		
		
		OTHERWISE
			LET l_query_text = 
				"SELECT * FROM territory ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ",					
				"ORDER BY territory.terr_code" 				
	END CASE

	PREPARE s_territory FROM l_query_text
	DECLARE c_territory CURSOR FOR s_territory


	LET l_idx = 0
	FOREACH c_territory INTO l_arr_rec_territory[l_idx].*
      LET l_idx = l_idx + 1

	END FOREACH

	IF sqlca.sqlcode < 0 THEN   	
		LET l_arr_rec_territory = NULL	                                                                                        
	ELSE		                                                                                                                    
		#		                                                                                                
	END IF	         

	RETURN l_arr_rec_territory		                                                                                                
END FUNCTION
############################################################
# END FUNCTION db_territory_get_arr_rec(p_query_text)
############################################################


########################################################################################################################
# 
# UPDATE INSERT DELETE row from DB
#
########################################################################################################################


############################################################
# FUNCTION db_territory_update(p_rec_territory)
#
#
############################################################
FUNCTION db_territory_update(p_ui_mode,p_pk_terr_code,p_rec_territory)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_pk_terr_code LIKE territory.terr_code
	DEFINE p_rec_territory RECORD LIKE territory.*
	DEFINE l_ui_mode SMALLINT
	DEFINE l_ret_status INT
	DEFINE l_msgStr STRING
	
	IF p_ui_mode = UI_ON THEN
		LET l_ui_mode = UI_PK
	END IF

	IF p_pk_terr_code IS NULL OR p_rec_territory.terr_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET l_msgStr = "Sales Territory code can not be empty ! (original Sales Territory Code=",trim(p_pk_terr_code), " / new Sales Territory Code=", trim(p_rec_territory.terr_code), ")"  
			ERROR l_msgStr
		END IF
		RETURN -1
	END IF
# Needs doing !!!!!!!!!! 	
#	IF db_XXXXXXXX_get_territory_count(p_pk_terr_code) AND (p_pk_terr_code <> p_rec_territory.terr_code) THEN #PK terr_code can only be changed if it's not used already
#		IF p_ui_mode > 0 THEN
#			ERROR "Can not change Sales Territory ! It is already used in a configuration"
#		END IF
#		LET l_ret_status =  -1
#	ELSE
		
	UPDATE territory
	SET * = p_rec_territory.*
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code					
	AND terr_code = p_pk_terr_code
			LET l_ret_status = sqlca.sqlcode 
		
#	END IF

	IF p_ui_mode != UI_OFF THEN #display MESSAGE if ui is enabled
		IF l_ret_status < 0 THEN   		
			LET l_msgStr = "Coud not modify Sales Territory record ! /nOriginal Sales Territory", trim(p_pk_terr_code), "New territory/Part ", trim(p_rec_territory.terr_code),  "\nDatabase Error ", trim(l_ret_status)                                                                                        
			#ERROR l_msgStr 
			CALL fgl_winmessage("Error when trying to modify/update Sales Territory record",l_msgStr,"error")
		ELSE
			LET l_msgStr = "Sales Territoryt record ", trim(p_rec_territory.terr_code), " updated successfully !"   
			MESSAGE l_msgStr
		END IF                                           	
	END IF	
	
	RETURN l_ret_status
END FUNCTION        
############################################################
# END FUNCTION db_territory_update(p_rec_territory)
############################################################

   
############################################################
# FUNCTION db_territory_insert(p_rec_territory)
#
#
############################################################
FUNCTION db_territory_insert(p_ui_mode,p_rec_territory)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_rec_territory RECORD LIKE territory.*
	DEFINE l_ret_status INT
	DEFINE l_ui_mode SMALLINT
	DEFINE l_msgStr STRING	
	
	IF p_ui_mode = UI_ON THEN
		LET l_ui_mode = UI_PK
	END IF

	IF p_rec_territory.terr_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET l_msgStr = "Sales Territory code can not be empty ! (Sales Territory=", trim(p_rec_territory.terr_code), ")"  
			ERROR l_msgStr
		END IF
		RETURN -1
	END IF

	LET p_rec_territory.cmpy_code = glob_rec_kandoouser.cmpy_code
	
	IF db_territory_pk_exists(UI_PK,MODE_INSERT,p_rec_territory.terr_code) THEN
		LET l_ret_status = -1
	ELSE
		
			INSERT INTO territory
	    VALUES(p_rec_territory.*)
	    LET l_ret_status = sqlca.sqlcode
		
	END IF

	IF p_ui_mode != UI_OFF THEN #display MESSAGE if ui is enabled
		IF l_ret_status < 0 THEN   		
			LET l_msgStr = "Coud not create Sales Territory record ", trim(p_rec_territory.terr_code), " !\nDatabase Error ", trim(l_ret_status)                                                                                        
			#ERROR l_msgStr 
			CALL fgl_winmessage("Error when trying to create/insert Sales Territory record",l_msgStr,"error")
		ELSE
			LET l_msgStr = "PSales Territory record ", trim(p_rec_territory.terr_code), " created successfully !"   
			MESSAGE l_msgStr
		END IF                                           	
	END IF
	
	RETURN l_ret_status
END FUNCTION
############################################################
# END FUNCTION db_territory_insert(p_rec_territory)
############################################################


############################################################
# FUNCTION db_territory_delete_valid(p_ui_mode,p_terr_code)
#
# Validates, (T/F) IF a territory can be deleted
# RETURN BOOLEAN
############################################################
FUNCTION db_territory_delete_valid(p_ui_mode,p_terr_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_terr_code LIKE territory.terr_code
	DEFINE ret_valid BOOLEAN

	SELECT unique 1 FROM salesperson 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND terri_code = p_terr_code
	IF status = 0 THEN 
		LET ret_valid = FALSE
		IF p_ui_mode != UI_OFF THEN
			ERROR kandoomsg2("A",7016,p_terr_code)	#7016 Salespersons exits FOR this territory - deletion no
		END IF
	ELSE
		LET ret_valid = TRUE
	END IF 
	RETURN ret_valid
END FUNCTION
############################################################
# END FUNCTION db_territory_delete_valid(p_ui_mode,p_terr_code)
############################################################


############################################################
# FUNCTION db_territory_delete(p_terr_code)
#
#
############################################################
FUNCTION db_territory_delete(p_ui_mode,p_confirm,p_terr_code)
	DEFINE p_ui_mode SMALLINT #hide or show error/warning messages
	DEFINE p_confirm BOOLEAN #is operator requested to confirm this operation / independent of ui mode	
	DEFINE p_terr_code LIKE territory.terr_code
	DEFINE l_msgresp LIKE language.yes_flag	
	DEFINE l_ret_status SMALLINT	
	DEFINE l_msgStr STRING

	LET l_ret_status = -1 #init return to none-success
	
	IF p_confirm = UI_CONFIRM_ON THEN
		LET l_msgStr = "Delete Sales Territory configuration ", trim(p_terr_code), " ?"
		IF NOT promptTF("Delete Sales Territory",l_msgStr,TRUE) THEN
			RETURN -2
		END IF
	END IF
	
	IF p_terr_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET l_msgStr = "Sales Territory code can not be empty ! (Sales Territory=", trim(p_terr_code), ")"  
			ERROR l_msgStr
		END IF
		RETURN -1
	END IF


# Needs doing !!!!!!!!!! 
#	IF db_XXXXX_get_territory_count(p_terr_code) THEN #PK terr_code can only be deleted if it's not used already
#		IF p_ui_mode != UI_OFF THEN
#			LET l_msgStr = "Can not delete Product/Part ! ", trim(p_terr_code), " It is already used in a bank configuration"
#			CALL fgl_winmessage("Can not delete Sales Territory ! ",l_msgStr,"error")
#		END IF
#		LET l_ret_status =  -1
#	ELSE

	IF db_territory_delete_valid(p_ui_mode,p_terr_code) THEN		
		DELETE FROM territory
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code					
		AND terr_code = p_terr_code
		
		LET l_ret_status = sqlca.sqlcode
	
		IF p_ui_mode != UI_OFF THEN #display MESSAGE if ui is enabled
			IF l_ret_status < 0 THEN   		
				LET l_msgStr = "Could not delete Sales Territory record ", trim(p_terr_code), " !\nDatabase Error ", trim(l_ret_status)                                                                                        
				#ERROR l_msgStr 
				CALL fgl_winmessage("Error when trying to delete",l_msgStr,"error")
			ELSE
				LET l_msgStr = "Sales Territory record ", trim(p_terr_code), " deleted !"   
				MESSAGE l_msgStr
			END IF                                           	
		END IF		             
	END IF
	
	RETURN l_ret_status		  
END FUNCTION
############################################################
# END FUNCTION db_territory_delete(p_terr_code)
############################################################

	
############################################################
# FUNCTION db_territory_rec_validation(p_ui_mode,p_op_mode,p_rec_territory)
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
FUNCTION db_territory_rec_validation(p_ui_mode,p_op_mode,p_rec_territory)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_op_mode SMALLINT
	DEFINE p_rec_territory RECORD LIKE territory.*
	DEFINE l_ret SMALLINT
	DEFINE l_l_msgStr STRING
	DISPLAY "p_ui_mode=", p_ui_mode
	DISPLAY "p_op_mode=", p_op_mode
	CASE p_op_mode
		WHEN MODE_INSERT
			#terr_code
			LET l_l_msgStr = "Can not create record. TAP Code already exists"  
			IF db_territory_pk_exists(UI_PK,p_op_mode,p_rec_territory.terr_code) THEN
				RETURN -1 #PK Already exists
			END IF		

			#desc_text
			IF p_rec_territory.desc_text IS NULL THEN
				LET l_l_msgStr =  "Can not create Sales Territory record with empty description text - terr_code: ", trim(p_rec_territory.terr_code)
				IF p_ui_mode > 0 THEN
					ERROR l_l_msgStr
				END IF				
				RETURN -2
			END IF

			#terr_code
			IF NOT db_coa_pk_exists(UI_FK,p_op_mode,p_rec_territory.terr_code) THEN
				LET l_l_msgStr =  "Can not create Sales Territory record with invalid COA Code: ", trim(p_rec_territory.terr_code)
				IF p_ui_mode > 0 THEN
					ERROR l_l_msgStr
				END IF
				RETURN -3
			END IF
				
		WHEN MODE_UPDATE
			#terr_code
			IF NOT db_territory_pk_exists(UI_PK,p_op_mode,p_rec_territory.terr_code) THEN
				LET l_l_msgStr = "Can not update record. TAP Code does not exist!"  			
				RETURN -1 #PK NOT FOUND
			END IF			

			#desc_text
			IF p_rec_territory.desc_text IS NULL THEN
				LET l_l_msgStr =  "Can not update Sales Territory record with empty description text - terr_code: ", trim(p_rec_territory.terr_code)
				IF p_ui_mode > 0 THEN
					ERROR l_l_msgStr
				END IF				
				RETURN -2
			END IF

			#terr_code
			IF NOT db_coa_pk_exists(UI_FK,p_op_mode,p_rec_territory.terr_code) THEN
				LET l_l_msgStr =  "Can not update Sales Territory record with invalid GL-COA Code: ", trim(p_rec_territory.terr_code)
				IF p_ui_mode > 0 THEN
					ERROR l_l_msgStr
				END IF
				RETURN -3
			END IF
							
		WHEN MODE_DELETE
			#terr_code
			IF db_territory_pk_exists(UI_PK,p_op_mode,p_rec_territory.terr_code) THEN
				LET l_l_msgStr =  "Can not delete Sales Territory record which does not exist - terr_code: ", trim(p_rec_territory.terr_code)
				IF p_ui_mode > 0 THEN
					ERROR l_l_msgStr
				END IF
				RETURN -1 #PK NOT FOUND
			END IF			
	
	END CASE

	RETURN TRUE	
END FUNCTION	
############################################################
# END FUNCTION db_territory_rec_validation(p_ui_mode,p_op_mode,p_rec_territory)
############################################################