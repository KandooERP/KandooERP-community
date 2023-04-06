########################################################################################################################
# TABLE inparms
#
#
########################################################################################################################

##########################################################
# GLOBAL Scope Variables
##########################################################
GLOBALS "../common/glob_GLOBALS.4gl"
			
############################################################
# FUNCTION db_inparms_pk_exists(p_ui,p_parm_code)
#
# Validate PK - Unique
############################################################
#	CONSTANT UI_OFF SMALLINT = 0
#	CONSTANT UI_ON SMALLINT = 1
#	CONSTANT UI_FK SMALLINT = 2
#	CONSTANT UI_PK SMALLINT = 3
############################################################
FUNCTION db_inparms_pk_exists(p_ui_mode,p_op_mode,p_parm_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_op_mode SMALLINT	
	DEFINE p_parm_code LIKE inparms.parm_code
	DEFINE ret BOOLEAN
	DEFINE recCount INT
	DEFINE msgStr STRING

	IF p_parm_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "IN-Configuration Code can not be empty"
			#LET msgresp = kandoomsg("G",9178,"")
			#9178 Bank/State/Branchs must NOT be NULL
		END IF
		RETURN FALSE
	END IF

	SELECT count(*) 
	INTO recCount 
	FROM inparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code				
	AND inparms.parm_code = p_parm_code  
		
	IF recCount > 0 THEN
		LET ret = TRUE	
		CASE p_op_mode
			WHEN MODE_INSERT
				CASE p_ui_mode
					WHEN UI_PK
						ERROR "IN-Configurations Code already exists! (", trim(p_parm_code), ")"
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
						ERROR "IN-Configuration Code does not exist! (", trim(p_parm_code), ")"
					OTHERWISE
						#No MESSAGE
				END CASE
			
			WHEN MODE_DELETE
				CASE p_ui_mode
					WHEN UI_PK
						#No MESSAGE
					WHEN UI_FK
						ERROR "IN-Configuration Code does not exist! (", trim(p_parm_code), ")"
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
						ERROR "IN-Configuration Code does not exist! (", trim(p_parm_code), ")"
					OTHERWISE
						#No MESSAGE
				END CASE

			WHEN MODE_UPDATE
				CASE p_ui_mode
					WHEN UI_PK
						ERROR "IN-Configuration Code does not exist! (", trim(p_parm_code), ")"
					WHEN UI_FK
						#No MESSAGE
					OTHERWISE
						#No MESSAGE
				END CASE

			WHEN MODE_DELETE
				CASE p_ui_mode
					WHEN UI_PK
						ERROR "IN-Configuration Code does not exist! (", trim(p_parm_code), ")"
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
# FUNCTION db_inparms_get_count()
#
# Return total number of rows in inparms 
############################################################
FUNCTION db_inparms_get_count()
	DEFINE ret INT
	
	SELECT count(*) 
	INTO ret 
	FROM inparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code				
			
	RETURN ret
END FUNCTION



############################################################
# FUNCTION db_inparms_get_instance_count(p_parm_code)
#
# Return total number of rows in inparms 
############################################################
FUNCTION db_inparms_get_instance_count(p_parm_code)
	DEFINE p_parm_code LIKE inparms.parm_code
	DEFINE l_ret INT

	SELECT count(*) 
	INTO l_ret 
	FROM inparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code				
	AND inparms.parm_code = p_parm_code
			
	RETURN l_ret
END FUNCTION


############################################################
# FUNCTION db_inparms_get_rec(p_ui_mode,p_parm_code)
# RETURN l_rec_inparms.*
# Get inparms/Part record
############################################################
FUNCTION db_inparms_get_rec(p_ui_mode,p_parm_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_parm_code LIKE inparms.parm_code
	DEFINE l_rec_inparms RECORD LIKE inparms.*

	IF p_parm_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Can not retrieve record with empty Product Adjustment Types Code"
		END IF
		RETURN NULL
	END IF

	SELECT *
	INTO l_rec_inparms.*
	FROM inparms
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code		        
	AND parm_code = p_parm_code
	
	IF sqlca.sqlcode != 0 THEN   		  
		INITIALIZE l_rec_inparms.* TO NULL                                                                                      
	ELSE		                                                                                                                    
		#		                                                                                                
	END IF	         

	RETURN l_rec_inparms.*		                                                                                                
END FUNCTION	


############################################################
# FUNCTION db_inparms_get_inv_journal_code(p_ui_mode,p_parm_code)
# RETURN l_ret_inv_journal_code 
#
# Get description text of Product Adjustment Types record
############################################################
FUNCTION db_inparms_get_inv_journal_code(p_ui_mode,p_parm_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_parm_code LIKE inparms.parm_code
	DEFINE l_ret_inv_journal_code LIKE inparms.inv_journal_code

	IF p_parm_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN	
			ERROR "Product Adjustment Types Code can NOT be empty"
		END IF
			RETURN NULL
	END IF
	
	SELECT inv_journal_code 
	INTO l_ret_inv_journal_code 
	FROM inparms
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code				 
	AND inparms.parm_code = p_parm_code  		
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Product Adjustment Types Description with Code ",trim(p_parm_code),  "NOT found"
		END IF			
		LET l_ret_inv_journal_code = NULL
	ELSE
		#
	END IF	
	RETURN l_ret_inv_journal_code
END FUNCTION

############################################################
# FUNCTION db_inparms_get_mast_ware_code(p_ui_mode,p_parm_code)
# RETURN l_ret_inv_journal_code 
#
# Get description text of Product/Part record
############################################################
FUNCTION db_inparms_get_mast_ware_code(p_ui_mode,p_parm_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_parm_code LIKE inparms.parm_code
	DEFINE l_ret_mast_ware_code LIKE inparms.mast_ware_code

	IF p_parm_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Product Adjustment Types Code can NOT be empty"
		END IF
		RETURN NULL
	END IF

	SELECT mast_ware_code 
	INTO l_ret_mast_ware_code
	FROM inparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code				
	AND inparms.parm_code = p_parm_code  		

	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Product Adjustment Types Reference with Product Adjustment Types Code ",trim(p_parm_code),  "NOT found"
		END IF
		LET l_ret_mast_ware_code = NULL
	ELSE
		#	                                                                                                
	END IF	

	RETURN l_ret_mast_ware_code	                                                                                                
END FUNCTION


############################################################
# FUNCTION db_inparms_get_parm_code(p_ui_mode,p_parm_code)
# RETURN l_ret_inv_journal_code 
#
# Get description text of inparms/Part record
############################################################
FUNCTION db_inparms_get_parm_code(p_ui_mode,p_parm_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_parm_code LIKE inparms.parm_code
	DEFINE l_ret_parm_code LIKE inparms.parm_code

	IF p_parm_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Product Adjustment Types Code can NOT be empty"
		END IF
		RETURN NULL
	END IF

	SELECT parm_code 
	INTO l_ret_parm_code
	FROM inparms
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code	
	AND inparms.parm_code = p_parm_code  		
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Product Adjustment Types Code ",trim(p_parm_code),  "NOT found"
		END IF
		LET l_ret_parm_code = NULL
	ELSE
		#	                                                                                                
	END IF	

	RETURN l_ret_parm_code	                                                                                                
END FUNCTION


{
############################################################
# FUNCTION db_inparms_get_cat_code(p_ui_mode,p_parm_code)
# RETURN l_ret_inv_journal_code 
#
# Get description text of Product/Part record
############################################################
FUNCTION db_inparms_get_cat_code(p_ui_mode,p_parm_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_parm_code LIKE inparms.parm_code
	DEFINE l_ret_cat_code LIKE inparms.cat_code

	IF p_parm_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Product Adjustment Types Code can NOT be empty"
		END IF
		RETURN NULL
	END IF

			SELECT cat_code 
			INTO l_ret_cat_code
			FROM inparms
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code				 
			AND inparms.parm_code = p_parm_code  		
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Product Adjustment Types Code ",trim(p_parm_code),  "NOT found"
		END IF
		LET l_ret_cat_code = NULL
	ELSE
		#	                                                                                                
	END IF	

	RETURN l_ret_cat_code	                                                                                                
END FUNCTION
}
########################################################################################################################
# 
# Get Array record data from DB
#
########################################################################################################################

############################################################
# FUNCTION db_inparms_get_arr_rec(p_query_text)
#
#
############################################################
FUNCTION db_inparms_get_arr_rec(p_query_type,p_query_or_where_text)
	DEFINE p_query_type SMALLINT
	DEFINE p_query_or_where_text STRING
	DEFINE l_query_text STRING
	DEFINE l_where_text STRING
	DEFINE l_arr_rec_inparms DYNAMIC ARRAY OF RECORD LIKE inparms.*		
	DEFINE l_rec_inparms RECORD LIKE inparms.*
	DEFINE l_idx SMALLINT

	IF p_query_type = FILTER_QUERY_WHERE AND p_query_or_where_text IS NULL THEN
		LET p_query_or_where_text = " 1=1 "
	END IF
		
	#p_query_text is optional
	CASE p_query_type
		WHEN FILTER_QUERY_OFF
			LET l_query_text = 
				"SELECT * FROM inparms ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ",					
				"ORDER BY inparms.parm_code" 	

		WHEN FILTER_QUERY_WHERE
			LET l_where_text = p_query_or_where_text
			LET l_query_text = 
				"SELECT * FROM inparms ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ",					
				"AND ", l_where_text clipped," ",
				"ORDER BY inparms.parm_code" 	

		WHEN FILTER_QUERY_SELECT
			LET l_query_text = p_query_or_where_text		
		
		OTHERWISE
			LET l_query_text = 
				"SELECT * FROM inparms ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ",					
				"ORDER BY inparms.parm_code" 				
	END CASE

	PREPARE s_inparms FROM l_query_text
	DECLARE c_inparms CURSOR FOR s_inparms


	LET l_idx = 0
	FOREACH c_inparms INTO l_arr_rec_inparms[l_idx].*
      LET l_idx = l_idx + 1

	END FOREACH

	IF sqlca.sqlcode < 0 THEN   	
		LET l_arr_rec_inparms = NULL	                                                                                        
	ELSE		                                                                                                                    
		#		                                                                                                
	END IF	         

	RETURN l_arr_rec_inparms		                                                                                                
END FUNCTION


{
############################################################
# FUNCTION db_inparms_get_arr_rec(p_query_text)
#
#
############################################################
FUNCTION db_inparms_get_arr_rec_ac_dt_ac_with_scrollflag(p_query_type,p_query_or_where_text)
	DEFINE p_query_type SMALLINT
	DEFINE p_query_or_where_text VARCHAR(500)
	DEFINE l_query_text STRING
	DEFINE l_where_text STRING
	DEFINE l_arr_rec_inparms DYNAMIC ARRAY OF t_rec_inparms_ac_dt_ac_with_scrollflag	
	DEFINE l_rec_inparms t_rec_inparms_ac_dt_ac
	DEFINE l_idx SMALLINT
	
	#p_query_text is optional
	IF p_query_or_where_text IS NULL THEN
		LET p_query_type = FILTER_QUERY_OFF
	END IF

	CASE p_query_type
		WHEN FILTER_QUERY_OFF
			LET l_query_text = 
				"SELECT parm_code,inv_journal_code,mast_ware_code FROM inparms ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ",					
				"ORDER BY inparms.parm_code" 	


#		WHEN FILTER_QUERY_ON
#			LET l_query_text = p_query_or_where_text

		WHEN FILTER_QUERY_WHERE
			LET l_where_text = p_query_or_where_text
			LET l_query_text = 
				"SELECT parm_code,inv_journal_code,mast_ware_code FROM inparms ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ",					
				"AND ", l_where_text clipped," ",
				"ORDER BY inparms.parm_code" 	

		WHEN FILTER_QUERY_SELECT
			LET l_query_text = p_query_or_where_text		
		
		OTHERWISE
			LET l_query_text = 
				"SELECT parm_code,inv_journal_code,mast_ware_code FROM inparms ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ",					
				"ORDER BY inparms.parm_code" 				
	END CASE

	PREPARE s2_inparms FROM l_query_text
	DECLARE c2_inparms CURSOR FOR s2_inparms


	LET l_idx = 0
	FOREACH c2_inparms INTO l_rec_inparms.*
		LET l_idx = l_idx + 1
		LET l_arr_rec_inparms[l_idx].* = "",l_rec_inparms.*
	END FOREACH

	IF sqlca.sqlcode < 0 THEN   	
		LET l_arr_rec_inparms = NULL	                                                                                        
	ELSE		                                                                                                                    
		#		                                                                                                
	END IF	         

	RETURN l_arr_rec_inparms		                                                                                                
END FUNCTION

}



########################################################################################################################
# 
# UPDATE INSERT DELETE row from DB
#
########################################################################################################################


############################################################
# FUNCTION db_inparms_update(p_rec_inparms)
#
#
############################################################
FUNCTION db_inparms_update(p_ui_mode,p_pk_parm_code,p_rec_inparms)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_pk_parm_code LIKE inparms.parm_code
	DEFINE p_rec_inparms RECORD LIKE inparms.*
	DEFINE l_ui_mode SMALLINT
	DEFINE ret INT
	DEFINE msgStr STRING
	
	IF p_ui_mode = UI_ON THEN
		LET l_ui_mode = UI_PK
	END IF

	IF p_pk_parm_code IS NULL OR p_rec_inparms.parm_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET msgStr = "Product Adjustment Types code can not be empty ! (original IN-Configuration Code=",trim(p_pk_parm_code), " / new IN-Configuration Code=", trim(p_rec_inparms.parm_code), ")"  
			ERROR msgStr
		END IF
		RETURN -1
	END IF
# Needs doing !!!!!!!!!! 	
#	IF db_XXXXXXXX_get_inparms_count(p_pk_parm_code) AND (p_pk_parm_code <> p_rec_inparms.parm_code) THEN #PK parm_code can only be changed if it's not used already
#		IF p_ui_mode > 0 THEN
#			ERROR "Can not change Product Adjustment Types ! It is already used in a configuration"
#		END IF
#		LET ret =  -1
#	ELSE
		
			SQL
				UPDATE inparms
				SET * = $p_rec_inparms.*
				WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code					
				AND parm_code = $p_pk_parm_code
			END SQL
			LET ret = status
		
#	END IF

	IF p_ui_mode != UI_OFF THEN #display MESSAGE if ui is enabled
		IF ret < 0 THEN   		
			LET msgStr = "Coud not modify Product Adjustment Types record ! /nOriginal IN-Configuration", trim(p_pk_parm_code), "New inparms/Part ", trim(p_rec_inparms.parm_code),  "\nDatabase Error ", trim(ret)                                                                                        
			#ERROR msgStr 
			CALL fgl_winmessage("Error when trying to modify/update Product Adjustment Types record",msgStr,"error")
		ELSE
			LET msgStr = "Product Adjustment Typest record ", trim(p_rec_inparms.parm_code), " updated successfully !"   
			MESSAGE msgStr
		END IF                                           	
	END IF	
	
	RETURN ret
END FUNCTION        

   
############################################################
# FUNCTION db_inparms_insert(p_rec_inparms)
#
#
############################################################
FUNCTION db_inparms_insert(p_ui_mode,p_rec_inparms)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_rec_inparms RECORD LIKE inparms.*
	DEFINE ret INT
	DEFINE l_ui_mode SMALLINT
	DEFINE msgStr STRING	
	
	IF p_ui_mode = UI_ON THEN
		LET l_ui_mode = UI_PK
	END IF

	IF p_rec_inparms.parm_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET msgStr = "Product Adjustment Types code can not be empty ! (IN-Configuration=", trim(p_rec_inparms.parm_code), ")"  
			ERROR msgStr
		END IF
		RETURN -1
	END IF

	LET p_rec_inparms.cmpy_code = glob_rec_kandoouser.cmpy_code
	
	IF db_inparms_pk_exists(UI_PK,MODE_INSERT,p_rec_inparms.parm_code) THEN
		LET ret = -1
	ELSE
		
			INSERT INTO inparms
	    VALUES(p_rec_inparms.*)
	    LET ret = status
		
	END IF

	IF p_ui_mode != UI_OFF THEN #display MESSAGE if ui is enabled
		IF ret < 0 THEN   		
			LET msgStr = "Coud not create Product Adjustment Types record ", trim(p_rec_inparms.parm_code), " !\nDatabase Error ", trim(ret)                                                                                        
			#ERROR msgStr 
			CALL fgl_winmessage("Error when trying to create/insert Product Adjustment Types record",msgStr,"error")
		ELSE
			LET msgStr = "PProduct Adjustment Types record ", trim(p_rec_inparms.parm_code), " created successfully !"   
			MESSAGE msgStr
		END IF                                           	
	END IF
	
	RETURN ret
END FUNCTION


############################################################
# 
# FUNCTION db_inparms_delete(p_parm_code)
#
#
############################################################
FUNCTION db_inparms_delete(p_ui_mode,p_confirm,p_parm_code)
	DEFINE p_ui_mode SMALLINT #hide or show error/warning messages
	DEFINE p_confirm BOOLEAN #is operator requested to confirm this operation / independent of ui mode	
	DEFINE p_parm_code LIKE inparms.parm_code
	DEFINE l_msgresp LIKE language.yes_flag	
	DEFINE ret SMALLINT	
	DEFINE msgStr STRING

	IF p_confirm = UI_CONFIRM_ON THEN
		LET msgStr = "Delete Product Adjustment Types configuration ", trim(p_parm_code), " ?"
		IF NOT promptTF("Delete IN-Configuration",msgStr,TRUE) THEN
			RETURN -2
		END IF
	END IF
	
	IF p_parm_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET msgStr = "Product Adjustment Types code can not be empty ! (IN-Configuration=", trim(p_parm_code), ")"  
			ERROR msgStr
		END IF
		RETURN -1
	END IF
# Needs doing !!!!!!!!!! 
#	IF db_XXXXX_get_inparms_count(p_parm_code) THEN #PK parm_code can only be deleted if it's not used already
#		IF p_ui_mode != UI_OFF THEN
#			LET msgStr = "Can not delete Product/Part ! ", trim(p_parm_code), " It is already used in a bank configuration"
#			CALL fgl_winmessage("Can not delete IN-Configuration ! ",msgStr,"error")
#		END IF
#		LET ret =  -1
#	ELSE
		
			SQL
				DELETE FROM inparms
				WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code					
				AND parm_code = $p_parm_code
			END SQL
			LET ret = status
		
			
#	END IF
	
	IF p_ui_mode != UI_OFF THEN #display MESSAGE if ui is enabled
		IF ret < 0 THEN   		
			LET msgStr = "Could not delete Product Adjustment Types record ", trim(p_parm_code), " !\nDatabase Error ", trim(ret)                                                                                        
			#ERROR msgStr 
			CALL fgl_winmessage("Error when trying to delete",msgStr,"error")
		ELSE
			LET msgStr = "Product Adjustment Types record ", trim(p_parm_code), " deleted !"   
			MESSAGE msgStr
		END IF                                           	
	END IF		             

	RETURN ret	
		  
END FUNCTION
	

############################################################
# 
# FUNCTION db_inparms_delete(p_parm_code)
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
FUNCTION db_inparms_rec_validation(p_ui_mode,p_op_mode,p_rec_inparms)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_op_mode SMALLINT
	DEFINE p_rec_inparms RECORD LIKE inparms.*
	DEFINE l_ret SMALLINT
	DEFINE l_msgStr STRING
	DISPLAY "p_ui_mode=", p_ui_mode
	DISPLAY "p_op_mode=", p_op_mode
	CASE p_op_mode
		WHEN MODE_INSERT
			#parm_code
			LET l_msgStr = "Can not create record. TAP Code already exists"  
			IF db_inparms_pk_exists(UI_PK,p_op_mode,p_rec_inparms.parm_code) THEN
				RETURN -1 #PK Already exists
			END IF		

			#inv_journal_code
			IF p_rec_inparms.inv_journal_code IS NULL THEN
				LET l_msgStr =  "Can not create IN-Configuration record with empty description text - parm_code: ", trim(p_rec_inparms.parm_code)
				IF p_ui_mode > 0 THEN
					ERROR l_msgStr
				END IF				
				RETURN -2
			END IF

			#mast_ware_code
			IF NOT db_coa_pk_exists(UI_FK,p_op_mode,p_rec_inparms.mast_ware_code) THEN
				LET l_msgStr =  "Can not create IN-Configuration record with invalid COA Code: ", trim(p_rec_inparms.mast_ware_code)
				IF p_ui_mode > 0 THEN
					ERROR l_msgStr
				END IF
				RETURN -3
			END IF
				
		WHEN MODE_UPDATE
			#parm_code
			IF NOT db_inparms_pk_exists(UI_PK,p_op_mode,p_rec_inparms.parm_code) THEN
				LET l_msgStr = "Can not update record. TAP Code does not exist!"  			
				RETURN -1 #PK NOT FOUND
			END IF			

			#inv_journal_code
			IF p_rec_inparms.inv_journal_code IS NULL THEN
				LET l_msgStr =  "Can not update IN-Configuration record with empty description text - parm_code: ", trim(p_rec_inparms.parm_code)
				IF p_ui_mode > 0 THEN
					ERROR l_msgStr
				END IF				
				RETURN -2
			END IF

			#mast_ware_code
			IF NOT db_coa_pk_exists(UI_FK,p_op_mode,p_rec_inparms.mast_ware_code) THEN
				LET l_msgStr =  "Can not update IN-Configuration record with invalid GL-COA Code: ", trim(p_rec_inparms.mast_ware_code)
				IF p_ui_mode > 0 THEN
					ERROR l_msgStr
				END IF
				RETURN -3
			END IF
							
		WHEN MODE_DELETE
			#parm_code
			IF db_inparms_pk_exists(UI_PK,p_op_mode,p_rec_inparms.parm_code) THEN
				LET l_msgStr =  "Can not delete IN-Configuration record which does not exist - parm_code: ", trim(p_rec_inparms.parm_code)
				IF p_ui_mode > 0 THEN
					ERROR l_msgStr
				END IF
				RETURN -1 #PK NOT FOUND
			END IF			
	
	
	END CASE

	RETURN TRUE	
	
END FUNCTION