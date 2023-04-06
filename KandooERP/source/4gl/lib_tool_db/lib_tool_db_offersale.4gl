########################################################################################################################
# TABLE offersale
# PK= compy_code nchar(2) , offer_code integer
# FK= offer_code nchar(3) 
########################################################################################################################

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl"
			
############################################################
# FUNCTION db_offersale_pk_exists(p_ui_mode,p_op_mode,p_offer_code)
#
# Validate PK - Unique
############################################################
#	CONSTANT UI_OFF SMALLINT = 0
#	CONSTANT UI_ON SMALLINT = 1
#	CONSTANT UI_FK SMALLINT = 2
#	CONSTANT UI_PK SMALLINT = 3
############################################################
FUNCTION db_offersale_pk_exists(p_ui_mode,p_op_mode,p_offer_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_op_mode SMALLINT	
	DEFINE p_offer_code LIKE offersale.offer_code
	DEFINE l_ret BOOLEAN
	DEFINE l_recCount INT
	DEFINE l_msgStr STRING

	IF p_offer_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Order Code can not be empty"
		END IF
		RETURN FALSE
	END IF

	SELECT count(*) 
	INTO l_recCount 
	FROM offersale 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code				
	AND offersale.offer_code = p_offer_code  
		
	IF l_recCount > 0 THEN
		LET l_ret = TRUE	
		CASE p_op_mode
			WHEN MODE_INSERT
				CASE p_ui_mode
					WHEN UI_PK
						ERROR "Orders Code already exists! (", trim(p_offer_code), ")"
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
						ERROR "Order Code does not exist! (", trim(p_offer_code), ")"
					OTHERWISE
						#No MESSAGE
				END CASE
			
			WHEN MODE_DELETE
				CASE p_ui_mode
					WHEN UI_PK
						#No MESSAGE
					WHEN UI_FK
						ERROR "Order Code does not exist! (", trim(p_offer_code), ")"
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
						ERROR "Order Code does not exist! (", trim(p_offer_code), ")"
					OTHERWISE
						#No MESSAGE
				END CASE

			WHEN MODE_UPDATE
				CASE p_ui_mode
					WHEN UI_PK
						ERROR "Order Code does not exist! (", trim(p_offer_code), ")"
					WHEN UI_FK
						#No MESSAGE
					OTHERWISE
						#No MESSAGE
				END CASE

			WHEN MODE_DELETE
				CASE p_ui_mode
					WHEN UI_PK
						ERROR "Order Code does not exist! (", trim(p_offer_code), ")"
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
# END FUNCTION db_offersale_pk_exists(p_ui,p_op_mode,p_offer_code)
############################################################


############################################################
# FUNCTION db_offersale_get_count()
#
# Return total number of rows in offersale 
############################################################
FUNCTION db_offersale_get_count()
	DEFINE l_ret_count INT

	SELECT count(*) 
	INTO l_ret_count 
	FROM offersale 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code				
			
	RETURN l_ret_count
END FUNCTION
############################################################
# END FUNCTION db_offersale_get_count()
############################################################


############################################################
# FUNCTION db_offersale_get_rec(p_ui_mode,p_offer_code)
# RETURN l_rec_offersale.*
# Get offersale record
############################################################
FUNCTION db_offersale_get_rec(p_ui_mode,p_offer_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_offer_code LIKE offersale.offer_code
	DEFINE l_rec_offersale RECORD LIKE offersale.*

	IF p_offer_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Can not retrieve record with empty Offer Code"
		END IF
		RETURN NULL
	END IF

	WHENEVER ERROR CONTINUE
	SELECT * INTO l_rec_offersale.*
	FROM offersale
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code		        
	AND offer_code = p_offer_code
	
	WHENEVER ERROR STOP
	
	IF sqlca.sqlcode != 0 THEN   		  
		INITIALIZE l_rec_offersale.* TO NULL                                                                                      
	ELSE		                                                                                                                    
		#		                                                                                                
	END IF	         

	RETURN l_rec_offersale.*		                                                                                                
END FUNCTION	
############################################################
# END FUNCTION db_offersale_get_rec(p_ui_mode,p_offer_code)
############################################################


############################################################
# FUNCTION db_offersale_get_start_date(p_ui_mode,p_offer_code)
# RETURN l_ret_start_date 
#
# Get description text of Product Adjustment Types record
############################################################
FUNCTION db_offersale_get_start_date(p_ui_mode,p_offer_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_offer_code LIKE offersale.offer_code
	DEFINE l_ret_start_date LIKE offersale.start_date

	IF p_offer_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN	
			ERROR "Offer Code can NOT be empty"
		END IF
			RETURN NULL
	END IF

	SELECT start_date 
	INTO l_ret_start_date 
	FROM offersale
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code				 
	AND offersale.offer_code = p_offer_code  		
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Product Adjustment Types Description with Code ",trim(p_offer_code),  "NOT found"
		END IF			
		LET l_ret_start_date = NULL
	ELSE
		#
	END IF	
	RETURN l_ret_start_date
END FUNCTION
############################################################
# END FUNCTION db_offersale_get_start_date(p_ui_mode,p_offer_code)
############################################################

############################################################
# FUNCTION db_offersale_get_end_date(p_ui_mode,p_offer_code)
# RETURN l_ret_end_date 
#
# Get description text of Product Adjustment Types record
############################################################
FUNCTION db_offersale_get_end_date(p_ui_mode,p_offer_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_offer_code LIKE offersale.offer_code
	DEFINE l_ret_end_date LIKE offersale.end_date

	IF p_offer_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN	
			ERROR "Offer Code can NOT be empty"
		END IF
			RETURN NULL
	END IF

	SELECT end_date 
	INTO l_ret_end_date 
	FROM offersale
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code				 
	AND offersale.offer_code = p_offer_code  		
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Product Adjustment Types Description with Code ",trim(p_offer_code),  "NOT found"
		END IF			
		LET l_ret_end_date = NULL
	ELSE
		#
	END IF	
	RETURN l_ret_end_date
END FUNCTION
############################################################
# END FUNCTION db_offersale_get_end_date(p_ui_mode,p_offer_code)
############################################################


########################################################################################################################
# 
# Get Array record data from DB
#
########################################################################################################################


############################################################
# FUNCTION db_offersale_get_arr_rec(p_query_text)
#
#
############################################################
FUNCTION db_offersale_get_arr_rec(p_query_type,p_query_or_where_text)
	DEFINE p_query_type SMALLINT
	DEFINE p_query_or_where_text STRING
	DEFINE l_query_text STRING
	DEFINE l_where_text STRING
	DEFINE l_arr_rec_offersale DYNAMIC ARRAY OF RECORD LIKE offersale.*		
	DEFINE l_rec_offersale RECORD LIKE offersale.*
	DEFINE l_idx SMALLINT

	IF p_query_type = FILTER_QUERY_WHERE AND p_query_or_where_text IS NULL THEN
		LET p_query_or_where_text = " 1=1 "
	END IF
		
	#p_query_text is optional
	CASE p_query_type
		WHEN FILTER_QUERY_OFF
			LET l_query_text = 
				"SELECT * FROM offersale ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ",					
				"ORDER BY offersale.offer_code" 	

		WHEN FILTER_QUERY_WHERE
			LET l_where_text = p_query_or_where_text
			LET l_query_text = 
				"SELECT * FROM offersale ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ",					
				"AND ", l_where_text clipped," ",
				"ORDER BY offersale.offer_code" 	

		WHEN FILTER_QUERY_SELECT
			LET l_query_text = p_query_or_where_text		
		
		OTHERWISE
			LET l_query_text = 
				"SELECT * FROM offersale ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ",					
				"ORDER BY offersale.offer_code" 				
	END CASE

	PREPARE s_offersale FROM l_query_text
	DECLARE c_offersale CURSOR FOR s_offersale


	LET l_idx = 0
	FOREACH c_offersale INTO l_arr_rec_offersale[l_idx].*
      LET l_idx = l_idx + 1

	END FOREACH

	IF sqlca.sqlcode < 0 THEN   	
		LET l_arr_rec_offersale = NULL	                                                                                        
	ELSE		                                                                                                                    
		#		                                                                                                
	END IF	         

	RETURN l_arr_rec_offersale		                                                                                                
END FUNCTION
############################################################
# END FUNCTION db_offersale_get_arr_rec(p_query_text)
############################################################


########################################################################################################################
# 
# UPDATE INSERT DELETE row from DB
#
########################################################################################################################


############################################################
# FUNCTION db_offersale_update(p_rec_offersale)
#
#
############################################################
FUNCTION db_offersale_update(p_ui_mode,p_pk_offer_code,p_rec_offersale)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_pk_offer_code LIKE offersale.offer_code
	DEFINE p_rec_offersale RECORD LIKE offersale.*
	DEFINE l_ui_mode SMALLINT
	DEFINE l_ret INT
	DEFINE l_msgStr STRING
	
	IF p_ui_mode = UI_ON THEN
		LET l_ui_mode = UI_PK
	END IF

	IF p_pk_offer_code IS NULL OR p_rec_offersale.offer_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET l_msgStr = "Offer Code can not be empty ! (original Order Code=",trim(p_pk_offer_code), " / new Order Code=", trim(p_rec_offersale.offer_code), ")"  
			ERROR l_msgStr
		END IF
		RETURN -1
	END IF
# Needs doing !!!!!!!!!! 	
#	IF db_XXXXXXXX_get_offersale_count(p_pk_offer_code) AND (p_pk_offer_code <> p_rec_offersale.offer_code) THEN #PK offer_code can only be changed if it's not used already
#		IF p_ui_mode > 0 THEN
#			ERROR "Can not change Product Adjustment Types ! It is already used in a configuration"
#		END IF
#		LET l_ret =  -1
#	ELSE
		WHENEVER ERROR CONTINUE
		UPDATE offersale
		SET * = p_rec_offersale.*
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code					
		AND offer_code = p_pk_offer_code
		LET l_ret = status
		WHENEVER ERROR STOP
#	END IF

	IF p_ui_mode != UI_OFF THEN #display MESSAGE if ui is enabled
		IF l_ret < 0 THEN   		
			LET l_msgStr = "Coud not modify Product Adjustment Types record ! /nOriginal Order", trim(p_pk_offer_code), "New offersale ", trim(p_rec_offersale.offer_code),  "\nDatabase Error ", trim(l_ret)                                                                                        
			#ERROR l_msgStr 
			CALL fgl_winmessage("Error when trying to modify/update Product Adjustment Types record",l_msgStr,"error")
		ELSE
			LET l_msgStr = "Product Adjustment Typest record ", trim(p_rec_offersale.offer_code), " updated successfully !"   
			MESSAGE l_msgStr
		END IF                                           	
	END IF	
	
	RETURN l_ret
END FUNCTION        
############################################################
# END FUNCTION db_offersale_update(p_rec_offersale)
############################################################

   
############################################################
# FUNCTION db_offersale_insert(p_rec_offersale)
#
#
############################################################
FUNCTION db_offersale_insert(p_ui_mode,p_rec_offersale)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_rec_offersale RECORD LIKE offersale.*
	DEFINE l_ret INT
	DEFINE l_ui_mode SMALLINT
	DEFINE l_msgStr STRING	
	
	IF p_ui_mode = UI_ON THEN
		LET l_ui_mode = UI_PK
	END IF

	IF p_rec_offersale.offer_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET l_msgStr = "Offer Code can not be empty ! (Order=", trim(p_rec_offersale.offer_code), ")"  
			ERROR l_msgStr
		END IF
		RETURN -1
	END IF

	LET p_rec_offersale.cmpy_code = glob_rec_kandoouser.cmpy_code
	
	IF db_offersale_pk_exists(UI_PK,MODE_INSERT,p_rec_offersale.offer_code) THEN
		LET l_ret = -1
	ELSE
		WHENEVER ERROR CONTINUE
			INSERT INTO offersale
	    VALUES(p_rec_offersale.*)
	    LET l_ret = status
		WHENEVER ERROR STOP
	END IF

	IF p_ui_mode != UI_OFF THEN #display MESSAGE if ui is enabled
		IF l_ret < 0 THEN   		
			LET l_msgStr = "Coud not create Product Adjustment Types record ", trim(p_rec_offersale.offer_code), " !\nDatabase Error ", trim(l_ret)                                                                                        
			#ERROR l_msgStr 
			CALL fgl_winmessage("Error when trying to create/insert Product Adjustment Types record",l_msgStr,"error")
		ELSE
			LET l_msgStr = "PProduct Adjustment Types record ", trim(p_rec_offersale.offer_code), " created successfully !"   
			MESSAGE l_msgStr
		END IF                                           	
	END IF
	
	RETURN l_ret
END FUNCTION
############################################################
# END FUNCTION db_offersale_insert(p_rec_offersale)
############################################################


############################################################
# FUNCTION db_offersale_delete(p_offer_code)
#
#
############################################################
FUNCTION db_offersale_delete(p_ui_mode,p_confirm,p_offer_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_confirm BOOLEAN #is operator requested to confirm this operation / independent of ui mode	
	DEFINE p_offer_code LIKE offersale.offer_code
	DEFINE l_msgresp LIKE language.yes_flag	
	DEFINE l_ret SMALLINT	
	DEFINE l_msgStr STRING

	IF p_confirm = UI_CONFIRM_ON THEN
		LET l_msgStr = "Delete order ", trim(p_offer_code), " ?"
		IF NOT promptTF("Delete Order",l_msgStr,TRUE) THEN
			RETURN -2
		END IF
	END IF
	
	IF p_offer_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET l_msgStr = "Order code (offer_code) can not be empty ! (Order=", trim(p_offer_code), ")"  
			ERROR l_msgStr
		END IF
		RETURN -1
	END IF
# Needs doing !!!!!!!!!! 
#	IF db_XXXXX_get_offersale_count(p_offer_code) THEN #PK offer_code can only be deleted if it's not used already
#		IF p_ui_mode != UI_OFF THEN
#			LET l_msgStr = "Can not delete Product ! ", trim(p_offer_code), " It is already used in a bank configuration"
#			CALL fgl_winmessage("Can not delete Order ! ",l_msgStr,"error")
#		END IF
#		LET l_ret =  -1
#	ELSE
		WHENEVER ERROR CONTINUE
		DELETE FROM offersale
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code					
			AND offer_code = p_offer_code
			LET l_ret = status
		WHENEVER ERROR STOP
			
#	END IF
	
	IF p_ui_mode != UI_OFF THEN #display MESSAGE if ui is enabled
		IF l_ret < 0 THEN   		
			LET l_msgStr = "Could not delete order record ", trim(p_offer_code), " !\nDatabase Error ", trim(l_ret)                                                                                        
			#ERROR l_msgStr 
			CALL fgl_winmessage("Error when trying to delete",l_msgStr,"error")
		ELSE
			LET l_msgStr = "Order ", trim(p_offer_code), " deleted !"   
			MESSAGE l_msgStr
		END IF                                           	
	END IF		             

	RETURN l_ret		  
END FUNCTION
############################################################
# END FUNCTION db_offersale_delete(p_offer_code)
############################################################
	

############################################################
# 
# FUNCTION db_offersale_delete(p_offer_code)
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
FUNCTION db_offersale_rec_validation(p_ui_mode,p_op_mode,p_rec_offersale)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_op_mode SMALLINT
	DEFINE p_rec_offersale RECORD LIKE offersale.*
	DEFINE l_ret SMALLINT
	DEFINE l_msgStr STRING
	DISPLAY "p_ui_mode=", p_ui_mode
	DISPLAY "p_op_mode=", p_op_mode
	CASE p_op_mode
		WHEN MODE_INSERT
			#offer_code
			LET l_msgStr = "Can not create record. Order Code already exists"  
			IF db_offersale_pk_exists(UI_PK,p_op_mode,p_rec_offersale.offer_code) THEN
				RETURN -1 #PK Already exists
			END IF		

		WHEN MODE_UPDATE
			#offer_code
			IF NOT db_offersale_pk_exists(UI_PK,p_op_mode,p_rec_offersale.offer_code) THEN
				LET l_msgStr = "Can not update record. TAP Code does not exist!"  			
				RETURN -1 #PK NOT FOUND
			END IF			

							
		WHEN MODE_DELETE
			#offer_code
			IF db_offersale_pk_exists(UI_PK,p_op_mode,p_rec_offersale.offer_code) THEN
				LET l_msgStr =  "Can not delete Order record (offersale) which does not exist - offer_code: ", trim(p_rec_offersale.offer_code)
				IF p_ui_mode > 0 THEN
					ERROR l_msgStr
				END IF
				RETURN -1 #PK NOT FOUND
			END IF			
	
	END CASE

	RETURN TRUE
	
END FUNCTION	
############################################################
# END FUNCTION db_offersale_delete(p_offer_code)
############################################################