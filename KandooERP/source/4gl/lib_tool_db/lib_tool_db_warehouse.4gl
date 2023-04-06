########################################################################################################################
# TABLE warehouse
#
#
########################################################################################################################

##########################################################
# GLOBAL Scope Variables
##########################################################
GLOBALS "../common/glob_GLOBALS.4gl"
GLOBALS "../common/glob_GLOBALS_userDataTypes.4gl"
############################################################
# FUNCTION db_warehouse_get_count()
#
# Return total number of rows in warehouse 
############################################################
FUNCTION db_warehouse_get_count()
	DEFINE ret_count INT

	SELECT count(*) 
	INTO ret_count 
	FROM warehouse 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code		
			
	RETURN ret_count
END FUNCTION
############################################################
# END FUNCTION db_warehouse_get_count()
############################################################

				
############################################################
# FUNCTION db_warehouse_pk_exists(p_ui,p_ware_code)
#
# Validate PK - Unique
############################################################
#	CONSTANT UI_OFF SMALLINT = 0
#	CONSTANT UI_ON SMALLINT = 1
#	CONSTANT UI_FK SMALLINT = 2
#	CONSTANT UI_PK SMALLINT = 3
############################################################
FUNCTION db_warehouse_pk_exists(p_ui,p_ware_code)
	DEFINE p_ui SMALLINT
	DEFINE p_ware_code LIKE warehouse.ware_code
	DEFINE ret_exists BOOLEAN
	DEFINE l_recCount INT
	DEFINE l_msg STRING

	IF p_ware_code IS NULL THEN
		IF p_ui != UI_OFF THEN
			ERROR "WAREHOUSE Code can not be empty"
		END IF
		RETURN FALSE
	END IF
	
	SELECT count(*) 
	INTO l_recCount 
	FROM warehouse
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code			
	AND warehouse.ware_code = p_ware_code		  
		
	IF l_recCount <> 0 THEN
		LET ret_exists = TRUE	
		IF p_ui = UI_ON THEN
			MESSAGE "WAREHOUSE Code exists! (", trim(p_ware_code), ")"
		END IF
		IF p_ui = UI_PK THEN
			MESSAGE "WAREHOUSE Code already exists! (", trim(p_ware_code), ")"
		END IF
	ELSE
		LET ret_exists = FALSE	
		IF p_ui = UI_FK THEN
			MESSAGE "WAREHOUSE Code does not exists! (", trim(p_ware_code), ")"
		END IF
	END IF
	
	RETURN ret_exists
END FUNCTION
############################################################
# END FUNCTION db_warehouse_pk_exists(p_ui,p_ware_code)
############################################################


############################################################
# FUNCTION db_warehouse_get_rec(p_ui_mode,p_ware_code)
# RETURN ret_rec_warehouse.*
# Get WAREHOUSE record
############################################################
FUNCTION db_warehouse_get_rec(p_ui_mode,p_ware_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_ware_code LIKE warehouse.ware_code
	DEFINE ret_rec_warehouse RECORD LIKE warehouse.*
	DEFINE l_msg STRING
	
	IF p_ware_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Can not retrieve record with empty WAREHOUSE code"
		END IF
		RETURN NULL
	END IF

  SELECT *
    INTO ret_rec_warehouse.*
    FROM warehouse
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code			
		AND ware_code = p_ware_code
	
	IF sqlca.sqlcode != 0 THEN  
		INITIALIZE ret_rec_warehouse.* TO NULL                                                                                      
		IF p_ui_mode != UI_OFF THEN
			ERROR kandoomsg2("I",5010,p_ware_code) 	#5010 Logic Error: Warehouse Code does NOT Exist.
		END IF
	END IF	         

	RETURN ret_rec_warehouse.*		                                                                                                
END FUNCTION	
############################################################
# END FUNCTION db_warehouse_get_rec(p_ui_mode,p_ware_code)
############################################################


############################################################
# FUNCTION db_warehouse_get_desc_text(p_ui_mode,p_ware_code)
# RETURN l_ret_desc_text 
#
# Get description text of WAREHOUSE record
############################################################
FUNCTION db_warehouse_get_desc_text(p_ui_mode,p_ware_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_ware_code LIKE warehouse.ware_code
	DEFINE l_ret_desc_text LIKE warehouse.desc_text

	IF p_ware_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN	
			ERROR "WAREHOUSE Code can NOT be empty"
		END IF
			RETURN NULL
	END IF

	SELECT desc_text 
	INTO l_ret_desc_text 
	FROM warehouse 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code				
	AND warehouse.ware_code = p_ware_code  		
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "WAREHOUSE Description with Code ",trim(p_ware_code),  "NOT found"
		END IF			
		LET l_ret_desc_text = NULL
	ELSE
		#
	END IF	
	RETURN l_ret_desc_text
END FUNCTION
############################################################
# END FUNCTION db_warehouse_get_desc_text(p_ui_mode,p_ware_code)
############################################################


############################################################
# FUNCTION db_warehouse_get_country_code(p_ui_mode,p_ware_code)
# RETURN l_ret_desc_text 
#
# Get description text of WAREHOUSE record
############################################################
FUNCTION db_warehouse_get_country_code(p_ui_mode,p_ware_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_ware_code LIKE warehouse.ware_code
	DEFINE l_ret_country_code LIKE warehouse.country_code

	IF p_ware_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "WAREHOUSE Code can NOT be empty"
		END IF
		RETURN NULL
	END IF

	SELECT country_code 
	INTO l_ret_country_code
	FROM warehouse
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code				 
	AND warehouse.ware_code = p_ware_code  		
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "WAREHOUSE Bank Reference with WAREHOUSE Code ",trim(p_ware_code),  "NOT found"
		END IF
		LET l_ret_country_code = NULL
	ELSE
		#	                                                                                                
	END IF	

	RETURN l_ret_country_code	                                                                                                
END FUNCTION
############################################################
# END FUNCTION db_warehouse_get_country_code(p_ui_mode,p_ware_code)
############################################################


########################################################################################################################
# 
# Get Array record data from DB
#
########################################################################################################################

############################################################
# FUNCTION db_warehouse_get_arr_rec(p_query_text)
#
#
############################################################
FUNCTION db_warehouse_get_arr_rec(p_query_type,p_query_or_where_text)
	DEFINE p_query_type SMALLINT
	DEFINE p_query_or_where_text VARCHAR(500)
	DEFINE l_query_text VARCHAR(500)
	DEFINE l_where_text VARCHAR(500)
	DEFINE l_arr_rec_warehouse DYNAMIC ARRAY OF RECORD LIKE warehouse.*		
	DEFINE l_rec_warehouse RECORD LIKE warehouse.*
	DEFINE l_idx SMALLINT
	
	#--------------------------------------
	#p_query_text is optional
	CASE p_query_type
		WHEN FILTER_QUERY_OFF
			LET l_query_text = 
				"SELECT * FROM warehouse ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ", 
				"ORDER BY warehouse.ware_code" 	


		#WHEN FILTER_QUERY_ON
		#	LET l_query_text = p_query_or_where_text

		WHEN FILTER_QUERY_WHERE
			LET l_where_text = p_query_or_where_text
			LET l_query_text = 
				"SELECT * FROM warehouse ",
				"WHERE ", l_where_text clipped," ",
				"AND cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ", 				
				"ORDER BY warehouse.ware_code" 	

		WHEN FILTER_QUERY_SELECT
			LET l_query_text = p_query_or_where_text		
		
		OTHERWISE
			LET l_query_text = 
				"SELECT * FROM warehouse ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ", 
				"ORDER BY warehouse.ware_code"
				 				
	END CASE

	PREPARE s_class FROM l_query_text
	DECLARE c_class CURSOR FOR s_class

	LET l_idx = 0
	FOREACH c_class INTO l_rec_warehouse.*
		LET l_idx = l_idx + 1
		LET l_arr_rec_warehouse[l_idx].ware_code = l_rec_warehouse.ware_code
		LET l_arr_rec_warehouse[l_idx].desc_text = l_rec_warehouse.desc_text
		LET l_arr_rec_warehouse[l_idx].addr1_text = l_rec_warehouse.addr1_text
		LET l_arr_rec_warehouse[l_idx].addr2_text = l_rec_warehouse.addr2_text
		LET l_arr_rec_warehouse[l_idx].city_text = l_rec_warehouse.city_text
		LET l_arr_rec_warehouse[l_idx].state_code = l_rec_warehouse.state_code
		LET l_arr_rec_warehouse[l_idx].post_code = l_rec_warehouse.post_code
		LET l_arr_rec_warehouse[l_idx].country_code = l_rec_warehouse.country_code
		LET l_arr_rec_warehouse[l_idx].contact_text = l_rec_warehouse.contact_text
		LET l_arr_rec_warehouse[l_idx].tele_text = l_rec_warehouse.tele_text
		LET l_arr_rec_warehouse[l_idx].auto_run_num = l_rec_warehouse.auto_run_num
		LET l_arr_rec_warehouse[l_idx].back_order_ind = l_rec_warehouse.back_order_ind
		LET l_arr_rec_warehouse[l_idx].confirm_flag = l_rec_warehouse.confirm_flag
		LET l_arr_rec_warehouse[l_idx].pick_flag = l_rec_warehouse.pick_flag
	END FOREACH

	IF sqlca.sqlcode < 0 THEN   	
		LET l_arr_rec_warehouse = NULL	                                                                                        
	ELSE		                                                                                                                    
		#		                                                                                                
	END IF	         

	RETURN l_arr_rec_warehouse		                                                                                                
END FUNCTION
############################################################
# END FUNCTION db_warehouse_get_arr_rec(p_query_text)
############################################################


############################################################
# FUNCTION db_warehouse_get_arr_rec_c_d(p_query_type,p_query_or_where_text)
#
#
############################################################
FUNCTION db_warehouse_get_arr_rec_w_d_c_t(p_query_type,p_query_or_where_text)
	DEFINE p_query_type SMALLINT
	DEFINE p_query_or_where_text VARCHAR(500)
	DEFINE l_query_text VARCHAR(500)
	DEFINE l_where_text VARCHAR(500)
	DEFINE l_arr_rec_warehouse DYNAMIC ARRAY OF t_rec_warehouse_w_d_c_t		
	DEFINE l_rec_warehouse RECORD LIKE warehouse.*
	DEFINE l_idx SMALLINT
	
	#p_query_text is optional
	CASE p_query_type
		WHEN FILTER_QUERY_OFF
			LET l_query_text = 
				"SELECT * FROM warehouse ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ", 
				"ORDER BY warehouse.ware_code" 	


		#WHEN FILTER_QUERY_ON
		#	LET l_query_text = p_query_or_where_text

		WHEN FILTER_QUERY_WHERE
			LET l_where_text = p_query_or_where_text
			LET l_query_text = 
				"SELECT * FROM warehouse ",
				"WHERE ", l_where_text clipped," ",
				"AND cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ", 				
				"ORDER BY warehouse.ware_code" 	

		WHEN FILTER_QUERY_SELECT
			LET l_query_text = p_query_or_where_text		
		
		OTHERWISE
			LET l_query_text = 
				"SELECT * FROM warehouse ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ", 
				"ORDER BY warehouse.ware_code"
				 				
	END CASE

	PREPARE s2_class FROM l_query_text
	DECLARE c2_class CURSOR FOR s2_class


	LET l_idx = 0
	FOREACH c2_class INTO l_rec_warehouse.*
		LET l_idx = l_idx + 1
		LET l_arr_rec_warehouse[l_idx].ware_code = l_rec_warehouse.ware_code
		LET l_arr_rec_warehouse[l_idx].desc_text = l_rec_warehouse.desc_text
		LET l_arr_rec_warehouse[l_idx].contact_text = l_rec_warehouse.contact_text
		LET l_arr_rec_warehouse[l_idx].tele_text = l_rec_warehouse.tele_text		
      
	END FOREACH

	IF sqlca.sqlcode < 0 THEN   	
		LET l_arr_rec_warehouse = NULL	                                                                                        
	ELSE		                                                                                                                    
		#		                                                                                                
	END IF	         

	RETURN l_arr_rec_warehouse		                                                                                                
END FUNCTION
############################################################
# END FUNCTION db_warehouse_get_arr_rec_c_d(p_query_type,p_query_or_where_text)
############################################################


########################################################################################################################
# 
# UPDATE INSERT DELETE row from DB
#
########################################################################################################################


############################################################
# FUNCTION db_warehouse_update(p_rec_warehouse)
#
#
############################################################
FUNCTION db_warehouse_update(p_ui_mode,p_pk_ware_code,p_rec_warehouse)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_pk_ware_code LIKE warehouse.ware_code
	DEFINE p_rec_warehouse RECORD LIKE warehouse.*
	DEFINE l_ui_mode SMALLINT
	DEFINE l_ret INT
	DEFINE l_msgStr STRING
	
	IF p_ui_mode = UI_ON THEN
		LET l_ui_mode = UI_PK
	END IF

	IF p_pk_ware_code IS NULL OR p_rec_warehouse.ware_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET l_msgStr = "WAREHOUSE code can not be empty ! (original WAREHOUSE=",trim(p_pk_ware_code), " / new WAREHOUSE=", trim(p_rec_warehouse.ware_code), ")"  
			ERROR l_msgStr
		END IF
		RETURN -1
	END IF
	
	IF db_product_get_class_count(p_pk_ware_code) AND (p_pk_ware_code <> p_rec_warehouse.ware_code) THEN #PK ware_code can only be changed if it's not used already
		IF p_ui_mode > 0 THEN
			ERROR "Can not change WAREHOUSE ! It is already used in a bank configuration"
		END IF
		LET l_ret =  -1
	ELSE
		
		UPDATE warehouse
		SET * = p_rec_warehouse.*
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code				
		AND ware_code = p_pk_ware_code
	
		LET l_ret = status
	END IF

	IF p_ui_mode != UI_OFF THEN #display MESSAGE if ui is enabled
		IF l_ret < 0 THEN   		
			LET l_msgStr = "Coud not modify WAREHOUSE record ! /nOriginal WAREHOUSE", trim(p_pk_ware_code), "New WAREHOUSE ", trim(p_rec_warehouse.ware_code),  "\nDatabase Error ", trim(l_ret)                                                                                        
			CALL fgl_winmessage("Error when trying to modify/update WAREHOUSE record",l_msgStr,"error")
		ELSE
			LET l_msgStr = "WAREHOUSE record ", trim(p_rec_warehouse.ware_code), " updated successfully !"   
			MESSAGE l_msgStr
		END IF                                           	
	END IF	
	
	RETURN l_ret
END FUNCTION        
############################################################
# END FUNCTION db_warehouse_update(p_rec_warehouse)
############################################################

   
############################################################
# FUNCTION db_warehouse_insert(p_rec_warehouse)
#
#
############################################################
FUNCTION db_warehouse_insert(p_ui_mode,p_rec_warehouse)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_rec_warehouse RECORD LIKE warehouse.*
	DEFINE l_ret INT
	DEFINE l_ui_mode SMALLINT
	DEFINE l_msgStr STRING	
	
	IF p_ui_mode = UI_ON THEN
		LET l_ui_mode = UI_PK
	END IF

	IF p_rec_warehouse.ware_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET l_msgStr = "WAREHOUSE code can not be empty ! (WAREHOUSE=", trim(p_rec_warehouse.ware_code), ")"  
			ERROR l_msgStr
		END IF
		RETURN -1
	END IF
	
	IF db_warehouse_pk_exists(UI_PK,p_rec_warehouse.ware_code) THEN
		LET l_ret = -1
	ELSE
		
			INSERT INTO warehouse
	    VALUES(p_rec_warehouse.*)
	    
	    LET l_ret = status
		
	END IF

	IF p_ui_mode != UI_OFF THEN #display MESSAGE if ui is enabled
		IF l_ret < 0 THEN   		
			LET l_msgStr = "Coud not create WAREHOUSE record ", trim(p_rec_warehouse.ware_code), " !\nDatabase Error ", trim(l_ret)                                                                                        
			#ERROR l_msgStr 
			CALL fgl_winmessage("Error when trying to create/insert WAREHOUSE record",l_msgStr,"error")
		ELSE
			LET l_msgStr = "WAREHOUSE record ", trim(p_rec_warehouse.ware_code), " created successfully !"   
			MESSAGE l_msgStr
		END IF                                           	
	END IF
	
	RETURN l_ret
END FUNCTION
############################################################
# END FUNCTION db_warehouse_insert(p_rec_warehouse)
############################################################


############################################################
# FUNCTION db_warehouse_delete(p_ware_code)
#
#
############################################################
FUNCTION db_warehouse_delete(p_ui_mode,p_confirm,p_ware_code)
	DEFINE p_ui_mode SMALLINT #hide or show error/warning messages
	DEFINE p_confirm BOOLEAN #is operator requested to confirm this operation / independent of ui mode
	DEFINE p_ware_code LIKE warehouse.ware_code
	DEFINE l_msgresp LIKE language.yes_flag	
	DEFINE l_ret SMALLINT	
	DEFINE l_msgStr STRING

	IF p_confirm = UI_CONFIRM_ON THEN
		LET l_msgStr = "Delete WAREHOUSE configuration ", trim(p_ware_code), " ?"
		IF NOT promptTF("Delete WAREHOUSE",l_msgStr,TRUE) THEN
			RETURN -2
		END IF
	END IF
	
	IF p_ware_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET l_msgStr = "WAREHOUSE code can not be empty ! (WAREHOUSE=", trim(p_ware_code), ")"  
			ERROR l_msgStr
		END IF
		RETURN -1
	END IF

#	IF db_bank_get_class_count(p_ware_code) THEN #PK ware_code can only be deleted if it's not used already
#		IF p_ui_mode != UI_OFF THEN
#			LET l_msgStr = "Can not delete WAREHOUSE ! ", trim(p_ware_code), " It is already used in a bank configuration"
#			CALL fgl_winmessage("Can not delete WAREHOUSE ! ",l_msgStr,"error")
#		END IF
#		LET l_ret =  -1
#	ELSE
		
		DELETE FROM warehouse
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
		AND ware_code = p_ware_code

		LET l_ret = status
		
			
#	END IF
	
	IF p_ui_mode != UI_OFF THEN #display MESSAGE if ui is enabled
		IF l_ret < 0 THEN   		
			LET l_msgStr = "Coud not delete WAREHOUSE record ", trim(p_ware_code), " !\nDatabase Error ", trim(l_ret)                                                                                        
			#ERROR l_msgStr 
			CALL fgl_winmessage("Error when trying to delete",l_msgStr,"error")
		ELSE
			LET l_msgStr = "WAREHOUSE record ", trim(p_ware_code), " deleted !"   
			MESSAGE l_msgStr
		END IF                                           	
	END IF		             

	RETURN l_ret	
		  
END FUNCTION
############################################################
# END FUNCTION db_warehouse_delete(p_ware_code)
############################################################