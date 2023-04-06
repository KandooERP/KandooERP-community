########################################################################################################################
# TABLE disbhead
#
#
########################################################################################################################

##########################################################
# GLOBAL Scope Variables
##########################################################
GLOBALS "../common/glob_GLOBALS.4gl"


			
############################################################
# FUNCTION db_disbhead_pk_exists(p_ui,p_disb_code)
#
# Validate PK - Unique
############################################################
#	CONSTANT UI_OFF SMALLINT = 0
#	CONSTANT UI_ON SMALLINT = 1
#	CONSTANT UI_FK SMALLINT = 2
#	CONSTANT UI_PK SMALLINT = 3
############################################################
FUNCTION db_disbhead_pk_exists(p_ui_mode,p_op_mode,p_disb_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_op_mode SMALLINT	
	DEFINE p_disb_code LIKE disbhead.disb_code
	DEFINE ret BOOLEAN
	DEFINE recCount INT
	DEFINE msgStr STRING

	IF p_disb_code IS NULL THEN
		IF p_ui_mode >= UI_ON THEN
			ERROR "PAT Code can not be empty"
			#LET msgresp = kandoomsg("G",9178,"")
			#9178 Bank/State/Branchs must NOT be NULL
		END IF
		RETURN FALSE
	END IF

	
		SQL
			SELECT count(*) 
			INTO $recCount 
			FROM disbhead 
			WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code				
			AND disbhead.disb_code = $p_disb_code  
		END SQL
	
		
	IF recCount > 0 THEN
		LET ret = TRUE	
		CASE p_op_mode
			WHEN MODE_INSERT
				CASE p_ui_mode
					WHEN UI_PK
						ERROR "PATs Code already exists! (", trim(p_disb_code), ")"
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
						ERROR "PAT Code does not exist! (", trim(p_disb_code), ")"
					OTHERWISE
						#No MESSAGE
				END CASE
			
			WHEN MODE_DELETE
				CASE p_ui_mode
					WHEN UI_PK
						#No MESSAGE
					WHEN UI_FK
						ERROR "PAT Code does not exist! (", trim(p_disb_code), ")"
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
						ERROR "PAT Code does not exist! (", trim(p_disb_code), ")"
					OTHERWISE
						#No MESSAGE
				END CASE

			WHEN MODE_UPDATE
				CASE p_ui_mode
					WHEN UI_PK
						ERROR "PAT Code does not exist! (", trim(p_disb_code), ")"
					WHEN UI_FK
						#No MESSAGE
					OTHERWISE
						#No MESSAGE
				END CASE

			WHEN MODE_DELETE
				CASE p_ui_mode
					WHEN UI_PK
						ERROR "PAT Code does not exist! (", trim(p_disb_code), ")"
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
# FUNCTION db_disbhead_get_count()
#
# Return total number of rows in disbhead 
############################################################
FUNCTION db_disbhead_get_count()
	DEFINE ret INT

	SELECT count(*) 
	INTO ret 
	FROM disbhead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code				
			
	RETURN ret
END FUNCTION



############################################################
# FUNCTION db_disbhead_get_count(p_disb_code)
#
# Return total number of rows in disbhead 
############################################################
FUNCTION db_disbhead_get_class_count(p_disb_code)
	DEFINE p_disb_code LIKE disbhead.disb_code
	DEFINE l_ret INT

	
		SQL
			SELECT count(*) 
			INTO $l_ret 
			FROM disbhead 
			WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code				
			AND disbhead.disb_code = $p_disb_code
		
		END SQL
	
			
	RETURN l_ret
END FUNCTION


############################################################
# FUNCTION db_disbhead_get_rec(p_ui_mode,p_disb_code)
# RETURN l_rec_disbhead.*
# Get disbhead/Part record
############################################################
FUNCTION db_disbhead_get_rec(p_ui_mode,p_disb_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_disb_code LIKE disbhead.disb_code
	DEFINE l_rec_disbhead RECORD LIKE disbhead.*

	IF p_disb_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Can not retrieve record with empty Product Adjustment Types Code"
		END IF
		RETURN NULL
	END IF

	
		SQL
			SELECT *
			INTO $l_rec_disbhead.*
			FROM disbhead
			WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code		        
			AND disb_code = $p_disb_code
		END SQL         
	
	
	IF sqlca.sqlcode != 0 THEN   		  
		INITIALIZE l_rec_disbhead.* TO NULL                                                                                      
	ELSE		                                                                                                                    
		#		                                                                                                
	END IF	         

	RETURN l_rec_disbhead.*		                                                                                                
END FUNCTION	


############################################################
# FUNCTION db_disbhead_get_desc_text(p_ui_mode,p_disb_code)
# RETURN l_ret_desc_text 
#
# Get description text of Product Adjustment Types record
############################################################
FUNCTION db_disbhead_get_desc_text(p_ui_mode,p_disb_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_disb_code LIKE disbhead.disb_code
	DEFINE l_ret_desc_text LIKE disbhead.desc_text

	IF p_disb_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN	
			ERROR "Product Adjustment Types Code can NOT be empty"
		END IF
			RETURN NULL
	END IF

	
		SQL
			SELECT desc_text 
			INTO $l_ret_desc_text 
			FROM disbhead
			WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code				 
			AND disbhead.disb_code = $p_disb_code  		
		END SQL
	
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Product Adjustment Types Description with Code ",trim(p_disb_code),  "NOT found"
		END IF			
		LET l_ret_desc_text = NULL
	ELSE
		#
	END IF	
	RETURN l_ret_desc_text
END FUNCTION



############################################################
# FUNCTION db_disbhead_get_disb_code(p_ui_mode,p_disb_code)
# RETURN l_ret_desc_text 
#
# Get description text of disbhead/Part record
############################################################
FUNCTION db_disbhead_get_disb_code(p_ui_mode,p_disb_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_disb_code LIKE disbhead.disb_code
	DEFINE l_ret_disb_code LIKE disbhead.disb_code

	IF p_disb_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Product Adjustment Types Code can NOT be empty"
		END IF
		RETURN NULL
	END IF

	
		SQL
			SELECT disb_code 
			INTO $l_ret_disb_code
			FROM disbhead
			WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code	
			AND disbhead.disb_code = $p_disb_code  		
		END SQL
	
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Product Adjustment Types Code ",trim(p_disb_code),  "NOT found"
		END IF
		LET l_ret_disb_code = NULL
	ELSE
		#	                                                                                                
	END IF	

	RETURN l_ret_disb_code	                                                                                                
END FUNCTION


{
############################################################
# FUNCTION db_disbhead_get_cat_code(p_ui_mode,p_disb_code)
# RETURN l_ret_desc_text 
#
# Get description text of Product/Part record
############################################################
FUNCTION db_disbhead_get_cat_code(p_ui_mode,p_disb_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_disb_code LIKE disbhead.disb_code
	DEFINE l_ret_cat_code LIKE disbhead.cat_code

	IF p_disb_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Product Adjustment Types Code can NOT be empty"
		END IF
		RETURN NULL
	END IF

	
		SQL
			SELECT cat_code 
			INTO $l_ret_cat_code
			FROM disbhead
			WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code				 
			AND disbhead.disb_code = $p_disb_code  		
		END SQL
	
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Product Adjustment Types Code ",trim(p_disb_code),  "NOT found"
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
# FUNCTION db_disbhead_get_arr_rec(p_query_text)
#
#
############################################################
FUNCTION db_disbhead_get_arr_rec(p_query_type,p_query_or_where_text)
	DEFINE p_query_type SMALLINT
	DEFINE p_query_or_where_text STRING
	DEFINE l_query_text STRING
	DEFINE l_where_text STRING
	DEFINE l_arr_rec_disbhead DYNAMIC ARRAY OF RECORD LIKE disbhead.*		
	DEFINE l_rec_disbhead RECORD LIKE disbhead.*
	DEFINE l_idx SMALLINT

	IF p_query_type = FILTER_QUERY_WHERE AND p_query_or_where_text IS NULL THEN
		LET p_query_or_where_text = " 1=1 "
	END IF
		
	#p_query_text is optional
	CASE p_query_type
		WHEN FILTER_QUERY_OFF
			LET l_query_text = 
				"SELECT * FROM disbhead ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ",					
				"ORDER BY disbhead.disb_code" 	

		WHEN FILTER_QUERY_WHERE
			LET l_where_text = p_query_or_where_text
			LET l_query_text = 
				"SELECT * FROM disbhead ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ",					
				"AND ", l_where_text clipped," ",
				"ORDER BY disbhead.disb_code" 	

		WHEN FILTER_QUERY_SELECT
			LET l_query_text = p_query_or_where_text		
		
		OTHERWISE
			LET l_query_text = 
				"SELECT * FROM disbhead ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ",					
				"ORDER BY disbhead.disb_code" 				
	END CASE

	PREPARE s_disbhead FROM l_query_text
	DECLARE c_disbhead CURSOR FOR s_disbhead


	LET l_idx = 0
	FOREACH c_disbhead INTO l_arr_rec_disbhead[l_idx].*
      LET l_idx = l_idx + 1

	END FOREACH

	IF sqlca.sqlcode < 0 THEN   	
		LET l_arr_rec_disbhead = NULL	                                                                                        
	ELSE		                                                                                                                    
		#		                                                                                                
	END IF	         

	RETURN l_arr_rec_disbhead		                                                                                                
END FUNCTION

{

############################################################
# FUNCTION db_disbhead_get_arr_rec(p_query_text)
#
#
############################################################
FUNCTION db_disbhead_get_arr_rec_ac_dt_ac_with_scrollflag(p_query_type,p_query_or_where_text)
	DEFINE p_query_type SMALLINT
	DEFINE p_query_or_where_text VARCHAR(500)
	DEFINE l_query_text STRING
	DEFINE l_where_text STRING
	DEFINE l_arr_rec_disbhead DYNAMIC ARRAY OF t_rec_disbhead_ac_dt_ac_with_scrollflag	
	DEFINE l_rec_disbhead t_rec_disbhead_ac_dt_ac
	DEFINE l_idx SMALLINT
	
	#p_query_text is optional
	IF p_query_or_where_text IS NULL THEN
		LET p_query_type = FILTER_QUERY_OFF
	END IF

	CASE p_query_type
		WHEN FILTER_QUERY_OFF
			LET l_query_text = 
				"SELECT disb_code,desc_text,adj_acct_code FROM disbhead ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ",					
				"ORDER BY disbhead.disb_code" 	


#		WHEN FILTER_QUERY_ON
#			LET l_query_text = p_query_or_where_text

		WHEN FILTER_QUERY_WHERE
			LET l_where_text = p_query_or_where_text
			LET l_query_text = 
				"SELECT disb_code,desc_text,adj_acct_code FROM disbhead ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ",					
				"AND ", l_where_text clipped," ",
				"ORDER BY disbhead.disb_code" 	

		WHEN FILTER_QUERY_SELECT
			LET l_query_text = p_query_or_where_text		
		
		OTHERWISE
			LET l_query_text = 
				"SELECT disb_code,desc_text,adj_acct_code FROM disbhead ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ",					
				"ORDER BY disbhead.disb_code" 				
	END CASE

	PREPARE s2_disbhead FROM l_query_text
	DECLARE c2_disbhead CURSOR FOR s2_disbhead


	LET l_idx = 0
	FOREACH c2_disbhead INTO l_rec_disbhead.*
		LET l_idx = l_idx + 1
		LET l_arr_rec_disbhead[l_idx].* = "",l_rec_disbhead.*
	END FOREACH

	IF sqlca.sqlcode < 0 THEN   	
		LET l_arr_rec_disbhead = NULL	                                                                                        
	ELSE		                                                                                                                    
		#		                                                                                                
	END IF	         

	RETURN l_arr_rec_disbhead		                                                                                                
END FUNCTION



}

########################################################################################################################
# 
# UPDATE INSERT DELETE row from DB
#
########################################################################################################################


############################################################
# FUNCTION db_disbhead_update(p_rec_disbhead)
#
#
############################################################
FUNCTION db_disbhead_update(p_ui_mode,p_pk_disb_code,p_rec_disbhead)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_pk_disb_code LIKE disbhead.disb_code
	DEFINE p_rec_disbhead RECORD LIKE disbhead.*
	DEFINE l_ui_mode SMALLINT
	DEFINE ret INT
	DEFINE msgStr STRING
	
	IF p_ui_mode = UI_ON THEN
		LET l_ui_mode = UI_PK
	END IF

	IF p_pk_disb_code IS NULL OR p_rec_disbhead.disb_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET msgStr = "Product Adjustment Types code can not be empty ! (original PAT Code=",trim(p_pk_disb_code), " / new PAT Code=", trim(p_rec_disbhead.disb_code), ")"  
			ERROR msgStr
		END IF
		RETURN -1
	END IF
# Needs doing !!!!!!!!!! 	
#	IF db_XXXXXXXX_get_disbhead_count(p_pk_disb_code) AND (p_pk_disb_code <> p_rec_disbhead.disb_code) THEN #PK disb_code can only be changed if it's not used already
#		IF p_ui_mode > 0 THEN
#			ERROR "Can not change Product Adjustment Types ! It is already used in a configuration"
#		END IF
#		LET ret =  -1
#	ELSE
		
			SQL
				UPDATE disbhead
				SET * = $p_rec_disbhead.*
				WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code					
				AND disb_code = $p_pk_disb_code
			END SQL
			LET ret = status
		
#	END IF

	IF p_ui_mode != UI_OFF THEN #display MESSAGE if ui is enabled
		IF ret < 0 THEN   		
			LET msgStr = "Coud not modify Product Adjustment Types record ! /nOriginal PAT", trim(p_pk_disb_code), "New disbhead/Part ", trim(p_rec_disbhead.disb_code),  "\nDatabase Error ", trim(ret)                                                                                        
			#ERROR msgStr 
			CALL fgl_winmessage("Error when trying to modify/update Product Adjustment Types record",msgStr,"error")
		ELSE
			LET msgStr = "Product Adjustment Typest record ", trim(p_rec_disbhead.disb_code), " updated successfully !"   
			MESSAGE msgStr
		END IF                                           	
	END IF	
	
	RETURN ret
END FUNCTION        

   
############################################################
# FUNCTION db_disbhead_insert(p_rec_disbhead)
#
#
############################################################
FUNCTION db_disbhead_insert(p_ui_mode,p_rec_disbhead)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_rec_disbhead RECORD LIKE disbhead.*
	DEFINE ret INT
	DEFINE l_ui_mode SMALLINT
	DEFINE msgStr STRING	
	
	IF p_ui_mode = UI_ON THEN
		LET l_ui_mode = UI_PK
	END IF

	IF p_rec_disbhead.disb_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET msgStr = "Product Adjustment Types code can not be empty ! (PAT=", trim(p_rec_disbhead.disb_code), ")"  
			ERROR msgStr
		END IF
		RETURN -1
	END IF

	LET p_rec_disbhead.cmpy_code = glob_rec_kandoouser.cmpy_code
	
	IF db_disbhead_pk_exists(UI_PK,MODE_INSERT,p_rec_disbhead.disb_code) THEN
		LET ret = -1
	ELSE
		
			INSERT INTO disbhead
	    VALUES(p_rec_disbhead.*)
	    LET ret = status
		
	END IF

	IF p_ui_mode != UI_OFF THEN #display MESSAGE if ui is enabled
		IF ret < 0 THEN   		
			LET msgStr = "Coud not create Product Adjustment Types record ", trim(p_rec_disbhead.disb_code), " !\nDatabase Error ", trim(ret)                                                                                        
			#ERROR msgStr 
			CALL fgl_winmessage("Error when trying to create/insert Product Adjustment Types record",msgStr,"error")
		ELSE
			LET msgStr = "PProduct Adjustment Types record ", trim(p_rec_disbhead.disb_code), " created successfully !"   
			MESSAGE msgStr
		END IF                                           	
	END IF
	
	RETURN ret
END FUNCTION


############################################################
# 
# FUNCTION db_disbhead_delete(p_disb_code)
#
#
############################################################
FUNCTION db_disbhead_delete(p_ui_mode,p_confirm,p_disb_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_confirm BOOLEAN #is operator requested to confirm this operation / independent of ui mode
	DEFINE p_disb_code LIKE disbhead.disb_code
	DEFINE l_msgresp LIKE language.yes_flag	
	DEFINE ret SMALLINT	
	DEFINE msgStr STRING

	IF p_confirm = UI_CONFIRM_ON THEN
		LET msgStr = "Delete Product Adjustment Types configuration ", trim(p_disb_code), " ?"
		IF NOT promptTF("Delete PAT",msgStr,TRUE) THEN
			RETURN -2
		END IF
	END IF
	
	IF p_disb_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET msgStr = "Product Adjustment Types code can not be empty ! (PAT=", trim(p_disb_code), ")"  
			ERROR msgStr
		END IF
		RETURN -1
	END IF
# Needs doing !!!!!!!!!! 
#	IF db_XXXXX_get_disbhead_count(p_disb_code) THEN #PK disb_code can only be deleted if it's not used already
#		IF p_ui_mode != UI_OFF THEN
#			LET msgStr = "Can not delete Product/Part ! ", trim(p_disb_code), " It is already used in a bank configuration"
#			CALL fgl_winmessage("Can not delete PAT ! ",msgStr,"error")
#		END IF
#		LET ret =  -1
#	ELSE
		
			SQL
				DELETE FROM disbhead
				WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code					
				AND disb_code = $p_disb_code
			END SQL
			LET ret = status
		
			
#	END IF
	
	IF p_ui_mode != UI_OFF THEN #display MESSAGE if ui is enabled
		IF ret < 0 THEN   		
			LET msgStr = "Could not delete Product Adjustment Types record ", trim(p_disb_code), " !\nDatabase Error ", trim(ret)                                                                                        
			#ERROR msgStr 
			CALL fgl_winmessage("Error when trying to delete",msgStr,"error")
		ELSE
			LET msgStr = "Product Adjustment Types record ", trim(p_disb_code), " deleted !"   
			MESSAGE msgStr
		END IF                                           	
	END IF		             

	RETURN ret	
		  
END FUNCTION
	

############################################################
# 
# FUNCTION db_disbhead_delete(p_disb_code)
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
FUNCTION db_disbhead_rec_validation(p_ui_mode,p_op_mode,p_rec_disbhead)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_op_mode SMALLINT
	DEFINE p_rec_disbhead RECORD LIKE disbhead.*
	DEFINE l_ret SMALLINT
	DEFINE l_msgStr STRING
	DISPLAY "p_ui_mode=", p_ui_mode
	DISPLAY "p_op_mode=", p_op_mode
	CASE p_op_mode
		WHEN MODE_INSERT
			#disb_code
			LET l_msgStr = "Can not create record. TAP Code already exists"  
			IF db_disbhead_pk_exists(UI_PK,p_op_mode,p_rec_disbhead.disb_code) THEN
				RETURN -1 #PK Already exists
			END IF		

			#desc_text
			IF p_rec_disbhead.desc_text IS NULL THEN
				LET l_msgStr =  "Can not create PAT record with empty description text - disb_code: ", trim(p_rec_disbhead.disb_code)
				IF p_ui_mode > 0 THEN
					ERROR l_msgStr
				END IF				
				RETURN -2
			END IF
{
			#adj_acct_code
			IF NOT db_coa_pk_exists(UI_FK,p_op_mode,p_rec_disbhead.adj_acct_code) THEN
				LET l_msgStr =  "Can not create PAT record with invalid COA Code: ", trim(p_rec_disbhead.adj_acct_code)
				IF p_ui_mode > 0 THEN
					ERROR l_msgStr
				END IF
				RETURN -3
			END IF
}				
		WHEN MODE_UPDATE
			#disb_code
			IF NOT db_disbhead_pk_exists(UI_PK,p_op_mode,p_rec_disbhead.disb_code) THEN
				LET l_msgStr = "Can not update record. TAP Code does not exist!"  			
				RETURN -1 #PK NOT FOUND
			END IF			

			#desc_text
			IF p_rec_disbhead.desc_text IS NULL THEN
				LET l_msgStr =  "Can not update PAT record with empty description text - disb_code: ", trim(p_rec_disbhead.disb_code)
				IF p_ui_mode > 0 THEN
					ERROR l_msgStr
				END IF				
				RETURN -2
			END IF
{
			#adj_acct_code
			IF NOT db_coa_pk_exists(UI_FK,p_op_mode,p_rec_disbhead.adj_acct_code) THEN
				LET l_msgStr =  "Can not update PAT record with invalid GL-COA Code: ", trim(p_rec_disbhead.adj_acct_code)
				IF p_ui_mode > 0 THEN
					ERROR l_msgStr
				END IF
				RETURN -3
			END IF
}							
		WHEN MODE_DELETE
			#disb_code
			IF db_disbhead_pk_exists(UI_PK,p_op_mode,p_rec_disbhead.disb_code) THEN
				LET l_msgStr =  "Can not delete PAT record which does not exist - disb_code: ", trim(p_rec_disbhead.disb_code)
				IF p_ui_mode > 0 THEN
					ERROR l_msgStr
				END IF
				RETURN -1 #PK NOT FOUND
			END IF			
	
	
	END CASE

	RETURN TRUE
	
	
END FUNCTION	
	
