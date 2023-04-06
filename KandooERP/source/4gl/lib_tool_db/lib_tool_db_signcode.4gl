########################################################################################################################
# TABLE signcode
#
#
########################################################################################################################

##########################################################
# GLOBAL Scope Variables
##########################################################
GLOBALS "../common/glob_GLOBALS.4gl"
GLOBALS "../common/glob_GLOBALS_userDataTypes.4gl"

			
############################################################
# FUNCTION db_signcode_pk_exists(p_ui,p_signcode_id)
#
# Validate PK - Unique
############################################################
#	CONSTANT UI_OFF SMALLINT = 0
#	CONSTANT UI_ON SMALLINT = 1
#	CONSTANT UI_FK SMALLINT = 2
#	CONSTANT UI_PK SMALLINT = 3
############################################################
FUNCTION db_signcode_pk_exists(p_ui_mode,p_op_mode,p_signcode_id)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_op_mode SMALLINT	
	DEFINE p_signcode_id LIKE signcode.sign_code
	DEFINE ret BOOLEAN
	DEFINE recCount INT
	DEFINE l_msgStr STRING

	IF p_signcode_id IS NULL THEN
		IF p_ui_mode >= UI_ON THEN
			ERROR "Sign Code (sign_code) ID can not be empty"
			#LET msgresp = kandoomsg("G",9178,"")
			#9178 Bank/State/Branchs must NOT be NULL
		END IF
		RETURN FALSE
	END IF

	
		SQL
			SELECT count(*) 
			INTO $recCount 
			FROM signcode 
			WHERE signcode.sign_code = $p_signcode_id  
		END SQL
	
		
	IF recCount > 0 THEN
		LET ret = TRUE	
		CASE p_op_mode
			WHEN MODE_INSERT
				CASE p_ui_mode
					WHEN UI_PK
						ERROR "Sign Code (sign_code)s Code already exists! (", trim(p_signcode_id), ")"
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
						ERROR "Sign Code (sign_code) ID does not exist! (", trim(p_signcode_id), ")"
					OTHERWISE
						#No MESSAGE
				END CASE
			
			WHEN MODE_DELETE
				CASE p_ui_mode
					WHEN UI_PK
						#No MESSAGE
					WHEN UI_FK
						ERROR "Sign Code (sign_code) ID does not exist! (", trim(p_signcode_id), ")"
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
						ERROR "Sign Code (sign_code) ID does not exist! (", trim(p_signcode_id), ")"
					OTHERWISE
						#No MESSAGE
				END CASE

			WHEN MODE_UPDATE
				CASE p_ui_mode
					WHEN UI_PK
						ERROR "Sign Code (sign_code) ID does not exist! (", trim(p_signcode_id), ")"
					WHEN UI_FK
						#No MESSAGE
					OTHERWISE
						#No MESSAGE
				END CASE

			WHEN MODE_DELETE
				CASE p_ui_mode
					WHEN UI_PK
						ERROR "Sign Code (sign_code) ID does not exist! (", trim(p_signcode_id), ")"
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
# FUNCTION db_signcode_get_count()
#
# Return total number of rows in signcode 
############################################################
FUNCTION db_signcode_get_count()
	DEFINE ret INT

	
		SQL
			SELECT count(*) 
			INTO $ret 
			FROM signcode				
		
		END SQL
	
			
	RETURN ret
END FUNCTION



############################################################
# FUNCTION db_signcode_get_count(p_signcode_id)
#
# Return total number of rows in signcode 
############################################################
FUNCTION db_signcode_get_class_count(p_signcode_id)
	DEFINE p_signcode_id LIKE signcode.sign_code
	DEFINE l_ret INT

	
		SQL
			SELECT count(*) 
			INTO $l_ret 
			FROM signcode 
			WHERE signcode.sign_code = $p_signcode_id
		
		END SQL
	
			
	RETURN l_ret
END FUNCTION


############################################################
# FUNCTION db_signcode_get_rec(p_ui_mode,p_signcode_id)
# RETURN l_rec_signcode.*
# Get signcode/Part record
############################################################
FUNCTION db_signcode_get_rec(p_ui_mode,p_signcode_id)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_signcode_id LIKE signcode.sign_code
	DEFINE l_rec_signcode RECORD LIKE signcode.*

	IF p_signcode_id IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Can not retrieve record with empty Sign Code (sign_code) ID"
		END IF
		RETURN NULL
	END IF

	
		SQL
			SELECT *
			INTO $l_rec_signcode.*
			FROM signcode
			WHERE sign_code = $p_signcode_id
		END SQL         
	
	
	IF sqlca.sqlcode != 0 THEN   		  
		INITIALIZE l_rec_signcode.* TO NULL                                                                                      
	ELSE		                                                                                                                    
		#		                                                                                                
	END IF	         

	RETURN l_rec_signcode.*		                                                                                                
END FUNCTION	


############################################################
# FUNCTION db_signcode_get_rpt_text(p_ui_mode,p_signcode_id)
# RETURN l_ret_rpt_text 
#
# Get description text of Sign Code (sign_code) record
############################################################
FUNCTION db_signcode_get_rpt_text(p_ui_mode,p_signcode_id)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_signcode_id LIKE signcode.sign_code
	DEFINE l_ret_rpt_text LIKE signcode.sign_desc

	IF p_signcode_id IS NULL THEN
		IF p_ui_mode != UI_OFF THEN	
			ERROR "Sign Code (sign_code) ID can NOT be empty"
		END IF
			RETURN NULL
	END IF

	
		SQL
			SELECT sign_desc 
			INTO $l_ret_rpt_text 
			FROM signcode
			WHERE signcode.sign_code = $p_signcode_id  		
		END SQL
	
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Sign Code (sign_code) Description with Code ",trim(p_signcode_id),  "NOT found"
		END IF			
		LET l_ret_rpt_text = NULL
	ELSE
		#
	END IF	
	RETURN l_ret_rpt_text
END FUNCTION

############################################################
# FUNCTION db_signcode_get_adj_acct_code(p_ui_mode,p_signcode_id)
# RETURN l_ret_rpt_text 
#
# Get description text of Product/Part record
############################################################
FUNCTION db_signcode_get_adj_acct_code(p_ui_mode,p_signcode_id)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_signcode_id LIKE signcode.sign_code
	DEFINE l_ret_adj_acct_code LIKE signcode.sign_code

	IF p_signcode_id IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Sign Code (sign_code) ID can NOT be empty"
		END IF
		RETURN NULL
	END IF

	
		SQL
			SELECT sign_code 
			INTO $l_ret_adj_acct_code
			FROM signcode 
			WHERE signcode.sign_code = $p_signcode_id  		
		END SQL
	
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Sign Code (sign_code) Reference with Sign Code (sign_code) ID ",trim(p_signcode_id),  "NOT found"
		END IF
		LET l_ret_adj_acct_code = NULL
	ELSE
		#	                                                                                                
	END IF	

	RETURN l_ret_adj_acct_code	                                                                                                
END FUNCTION


############################################################
# FUNCTION db_signcode_get_adj_type_code(p_ui_mode,p_signcode_id)
# RETURN l_ret_rpt_text 
#
# Get description text of signcode/Part record
############################################################
FUNCTION db_signcode_get_adj_type_code(p_ui_mode,p_signcode_id)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_signcode_id LIKE signcode.sign_code
	DEFINE l_ret_adj_type_code LIKE signcode.sign_code

	IF p_signcode_id IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Sign Code (sign_code) ID can NOT be empty"
		END IF
		RETURN NULL
	END IF

	
		SQL
			SELECT sign_code 
			INTO $l_ret_adj_type_code
			FROM signcode
			WHERE signcode.sign_code = $p_signcode_id  		
		END SQL
	
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Sign Code (sign_code) ID ",trim(p_signcode_id),  "NOT found"
		END IF
		LET l_ret_adj_type_code = NULL
	ELSE
		#	                                                                                                
	END IF	

	RETURN l_ret_adj_type_code	                                                                                                
END FUNCTION


{
############################################################
# FUNCTION db_signcode_get_cat_code(p_ui_mode,p_signcode_id)
# RETURN l_ret_rpt_text 
#
# Get description text of Product/Part record
############################################################
FUNCTION db_signcode_get_cat_code(p_ui_mode,p_signcode_id)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_signcode_id LIKE signcode.sign_code
	DEFINE l_ret_cat_code LIKE signcode.cat_code

	IF p_signcode_id IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Sign Code (sign_code) ID can NOT be empty"
		END IF
		RETURN NULL
	END IF

	
		SQL
			SELECT cat_code 
			INTO $l_ret_cat_code
			FROM signcode
			WHERE signcode.sign_code = $p_signcode_id  		
		END SQL
	
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Sign Code (sign_code) ID ",trim(p_signcode_id),  "NOT found"
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
# FUNCTION db_signcode_get_arr_rec(p_query_text)
#
#
############################################################
FUNCTION db_signcode_get_arr_rec(p_query_type,p_query_or_where_text)
	DEFINE p_query_type SMALLINT
	DEFINE p_query_or_where_text STRING
	DEFINE l_query_text STRING
	DEFINE l_where_text STRING
	DEFINE l_arr_rec_signcode DYNAMIC ARRAY OF RECORD LIKE signcode.*		
	DEFINE l_rec_signcode RECORD LIKE signcode.*
	DEFINE l_idx SMALLINT

	IF p_query_type = FILTER_QUERY_WHERE AND p_query_or_where_text IS NULL THEN
		LET p_query_or_where_text = " 1=1 "
	END IF
		
	#p_query_text is optional
	CASE p_query_type
		WHEN FILTER_QUERY_OFF
			LET l_query_text = 
				"SELECT * FROM signcode ",
				"ORDER BY signcode.sign_code" 	

		WHEN FILTER_QUERY_WHERE
			LET l_where_text = p_query_or_where_text
			LET l_query_text = 
				"SELECT * FROM signcode ",
				"AND ", l_where_text clipped," ",
				"ORDER BY signcode.sign_code" 	

		WHEN FILTER_QUERY_SELECT
			LET l_query_text = p_query_or_where_text		
		
		OTHERWISE
			LET l_query_text = 
				"SELECT * FROM signcode ",
				"ORDER BY signcode.sign_code" 				
	END CASE

	PREPARE s_signcode FROM l_query_text
	DECLARE c_signcode CURSOR FOR s_signcode


	LET l_idx = 0
	FOREACH c_signcode INTO l_arr_rec_signcode[l_idx].*
      LET l_idx = l_idx + 1

	END FOREACH

	IF sqlca.sqlcode < 0 THEN   	
		LET l_arr_rec_signcode = NULL	                                                                                        
	ELSE		                                                                                                                    
		#		                                                                                                
	END IF	         

	RETURN l_arr_rec_signcode		                                                                                                
END FUNCTION



############################################################
# FUNCTION db_signcode_get_arr_rec(p_query_text)
#
#
############################################################
FUNCTION db_signcode_get_arr_rec_ac_dt_ac_with_scrollflag(p_query_type,p_query_or_where_text)
	DEFINE p_query_type SMALLINT
	DEFINE p_query_or_where_text VARCHAR(500)
	DEFINE l_query_text STRING
	DEFINE l_where_text STRING
	DEFINE l_arr_rec_signcode DYNAMIC ARRAY OF t_rec_signcode_co_de_ch_ba	
	DEFINE l_rec_signcode t_rec_signcode_co_de_ch_ba
	DEFINE l_idx SMALLINT
	
	#p_query_text is optional
	IF p_query_or_where_text IS NULL THEN
		LET p_query_type = FILTER_QUERY_OFF
	END IF

	CASE p_query_type
		WHEN FILTER_QUERY_OFF
			LET l_query_text = 
				"SELECT sign_code,sign_desc,sign_code FROM signcode ",
				"ORDER BY signcode.sign_code" 	


#		WHEN FILTER_QUERY_ON
#			LET l_query_text = p_query_or_where_text

		WHEN FILTER_QUERY_WHERE
			LET l_where_text = p_query_or_where_text
			LET l_query_text = 
				"SELECT sign_code,sign_desc,sign_code FROM signcode ",
				"ORDER BY signcode.sign_code" 	

		WHEN FILTER_QUERY_SELECT
			LET l_query_text = p_query_or_where_text		
		
		OTHERWISE
			LET l_query_text = 
				"SELECT sign_code,sign_desc,sign_code FROM signcode ",
				"ORDER BY signcode.sign_code" 				
	END CASE

	PREPARE s2_signcode FROM l_query_text
	DECLARE c2_signcode CURSOR FOR s2_signcode


	LET l_idx = 0
	FOREACH c2_signcode INTO l_rec_signcode.*
		LET l_idx = l_idx + 1
		LET l_arr_rec_signcode[l_idx].* = "",l_rec_signcode.*
	END FOREACH

	IF sqlca.sqlcode < 0 THEN   	
		LET l_arr_rec_signcode = NULL	                                                                                        
	ELSE		                                                                                                                    
		#		                                                                                                
	END IF	         

	RETURN l_arr_rec_signcode		                                                                                                
END FUNCTION





########################################################################################################################
# 
# UPDATE INSERT DELETE row from DB
#
########################################################################################################################


############################################################
# FUNCTION db_signcode_update(p_rec_signcode)
#
#
############################################################
FUNCTION db_signcode_update(p_ui_mode,p_pk_adj_type_code,p_rec_signcode)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_pk_adj_type_code LIKE signcode.sign_code
	DEFINE p_rec_signcode RECORD LIKE signcode.*
	DEFINE l_ui_mode SMALLINT
	DEFINE ret INT
	DEFINE l_msgStr STRING
	
	IF p_ui_mode = UI_ON THEN
		LET l_ui_mode = UI_PK
	END IF

	IF p_pk_adj_type_code IS NULL OR p_rec_signcode.sign_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET l_msgStr = "Sign Code (sign_code) ID can not be empty ! (original Sign Code (sign_code) ID=",trim(p_pk_adj_type_code), " / new Sign Code (sign_code) ID=", trim(p_rec_signcode.sign_code), ")"  
			ERROR l_msgStr
		END IF
		RETURN -1
	END IF
# Needs doing !!!!!!!!!! 	
#	IF db_XXXXXXXX_get_signcode_count(p_pk_adj_type_code) AND (p_pk_adj_type_code <> p_rec_signcode.sign_code) THEN #PK sign_code can only be changed if it's not used already
#		IF p_ui_mode > 0 THEN
#			ERROR "Can not change Sign Code (sign_code) ! It is already used in a configuration"
#		END IF
#		LET ret =  -1
#	ELSE
		
			SQL
				UPDATE signcode
				SET * = $p_rec_signcode.*
				WHERE sign_code = $p_pk_adj_type_code
			END SQL
			LET ret = status
		
#	END IF

	IF p_ui_mode != UI_OFF THEN #display MESSAGE if ui is enabled
		IF ret < 0 THEN   		
			LET l_msgStr = "Coud not modify Sign Code (sign_code) record ! /nOriginal Sign Code (sign_code)", trim(p_pk_adj_type_code), "New signcode/Part ", trim(p_rec_signcode.sign_code),  "\nDatabase Error ", trim(ret)                                                                                        
			#ERROR l_msgStr 
			CALL fgl_winmessage("Error when trying to modify/update Sign Code (sign_code)   record",l_msgStr,"error")
		ELSE
			LET l_msgStr = "Sign Code (sign_code) record ", trim(p_rec_signcode.sign_code), " updated successfully !"   
			MESSAGE l_msgStr
		END IF                                           	
	END IF	
	
	RETURN ret
END FUNCTION        

   
############################################################
# FUNCTION db_signcode_insert(p_rec_signcode)
#
#
############################################################
FUNCTION db_signcode_insert(p_ui_mode,p_rec_signcode)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_rec_signcode RECORD LIKE signcode.*
	DEFINE ret INT
	DEFINE l_ui_mode SMALLINT
	DEFINE l_msgStr STRING	
	
	IF p_ui_mode = UI_ON THEN
		LET l_ui_mode = UI_PK
	END IF

	IF p_rec_signcode.sign_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET l_msgStr = "Sign Code (sign_code) ID can not be empty ! (Sign Code (sign_code)=", trim(p_rec_signcode.sign_code), ")"  
			ERROR l_msgStr
		END IF
		RETURN -1
	END IF


	IF db_signcode_pk_exists(UI_PK,MODE_INSERT,p_rec_signcode.sign_code) THEN
		LET ret = -1
	ELSE
		
			INSERT INTO signcode
	    VALUES(p_rec_signcode.*)
	    LET ret = status
		
	END IF

	IF p_ui_mode != UI_OFF THEN #display MESSAGE if ui is enabled
		IF ret < 0 THEN   		
			LET l_msgStr = "Coud not create Sign Code (sign_code)   record ", trim(p_rec_signcode.sign_code), " !\nDatabase Error ", trim(ret)                                                                                        
			#ERROR l_msgStr 
			CALL fgl_winmessage("Error when trying to create/insert Sign Code (sign_code) record",l_msgStr,"error")
		ELSE
			LET l_msgStr = "PRounding Code (sign_code) record ", trim(p_rec_signcode.sign_code), " created successfully !"   
			MESSAGE l_msgStr
		END IF                                           	
	END IF
	
	RETURN ret
END FUNCTION


############################################################
# 
# FUNCTION db_signcode_delete(p_signcode_id)
#
#
############################################################
FUNCTION db_signcode_delete(p_ui_mode,p_confirm,p_signcode_id)
	DEFINE p_ui_mode SMALLINT #hide or show error/warning messages
	DEFINE p_confirm BOOLEAN #is operator requested to confirm this operation / independent of ui mode	
	DEFINE p_signcode_id LIKE signcode.sign_code
	DEFINE l_msgresp LIKE language.yes_flag	
	DEFINE ret SMALLINT	
	DEFINE l_msgStr STRING

	IF p_confirm = UI_CONFIRM_ON THEN
		LET l_msgStr = "Delete Sign Code (sign_code) configuration ", trim(p_signcode_id), " ?"
		IF NOT promptTF("Delete Sign Code (sign_code)",l_msgStr,TRUE) THEN
			RETURN -2
		END IF
	END IF
	
	IF p_signcode_id IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET l_msgStr = "Sign Code (sign_code) ID can not be empty ! (Sign Code (sign_code)=", trim(p_signcode_id), ")"  
			ERROR l_msgStr
		END IF
		RETURN -1
	END IF
# Needs doing !!!!!!!!!! 
#	IF db_XXXXX_get_signcode_count(p_signcode_id) THEN #PK sign_code can only be deleted if it's not used already
#		IF p_ui_mode != UI_OFF THEN
#			LET l_msgStr = "Can not delete Product/Part ! ", trim(p_signcode_id), " It is already used in a bank configuration"
#			CALL fgl_winmessage("Can not delete Sign Code (sign_code) ! ",l_msgStr,"error")
#		END IF
#		LET ret =  -1
#	ELSE
		
			SQL
				DELETE FROM signcode
				WHERE sign_code = $p_signcode_id
			END SQL
			LET ret = status
		
			
#	END IF
	
	IF p_ui_mode != UI_OFF THEN #display MESSAGE if ui is enabled
		IF ret < 0 THEN   		
			LET l_msgStr = "Could not delete Sign Code (sign_code) record ", trim(p_signcode_id), " !\nDatabase Error ", trim(ret)                                                                                        
			#ERROR l_msgStr 
			CALL fgl_winmessage("Error when trying to delete",l_msgStr,"error")
		ELSE
			LET l_msgStr = "Sign Code (sign_code) record ", trim(p_signcode_id), " deleted !"   
			MESSAGE l_msgStr
		END IF                                           	
	END IF		             

	RETURN ret	
		  
END FUNCTION
	

############################################################
# 
# FUNCTION db_signcode_delete(p_signcode_id)
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
FUNCTION db_signcode_rec_validation(p_ui_mode,p_op_mode,p_rec_signcode)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_op_mode SMALLINT
	DEFINE p_rec_signcode RECORD LIKE signcode.*
	DEFINE l_ret SMALLINT
	DEFINE l_msgStr STRING
	DISPLAY "p_ui_mode=", p_ui_mode
	DISPLAY "p_op_mode=", p_op_mode
	CASE p_op_mode
		WHEN MODE_INSERT
			#sign_code
			LET l_msgStr = "Can not create record. Sign Code already exists"  
			IF db_signcode_pk_exists(UI_PK,p_op_mode,p_rec_signcode.sign_code) THEN
				RETURN -1 #PK Already exists
			END IF		

			#sign_desc
			IF p_rec_signcode.sign_desc IS NULL THEN
				LET l_msgStr =  "Can not create Sign Code (sign_code) record with empty description text - sign_code: ", trim(p_rec_signcode.sign_code)
				IF p_ui_mode > 0 THEN
					ERROR l_msgStr
				END IF				
				RETURN -2
			END IF

#			#sign_code
#			IF NOT db_coa_pk_exists(UI_FK,p_op_mode,p_rec_signcode.sign_code) THEN
#				LET l_msgStr =  "Can not create Sign Code (sign_code) record with invalid COA Code: ", trim(p_rec_signcode.sign_code)
#				IF p_ui_mode > 0 THEN
#					ERROR l_msgStr
#				END IF
#				RETURN -3
#			END IF
				
		WHEN MODE_UPDATE
			#sign_code
			IF NOT db_signcode_pk_exists(UI_PK,p_op_mode,p_rec_signcode.sign_code) THEN
				LET l_msgStr = "Can not update record. Sign Code does not exist!"  			
				RETURN -1 #PK NOT FOUND
			END IF			

			#sign_desc
			IF p_rec_signcode.sign_desc IS NULL THEN
				LET l_msgStr =  "Can not update Sign Code (sign_code) record with empty description text - sign_code: ", trim(p_rec_signcode.sign_code)
				IF p_ui_mode > 0 THEN
					ERROR l_msgStr
				END IF				
				RETURN -2
			END IF

#			#sign_code
#			IF NOT db_coa_pk_exists(UI_FK,p_op_mode,p_rec_signcode.sign_code) THEN
#				LET l_msgStr =  "Can not update Sign Code (sign_code) record with invalid GL-COA Code: ", trim(p_rec_signcode.sign_code)
#				IF p_ui_mode > 0 THEN
#					ERROR l_msgStr
#				END IF
#				RETURN -3
#			END IF
							
		WHEN MODE_DELETE
			#sign_code
			IF db_signcode_pk_exists(UI_PK,p_op_mode,p_rec_signcode.sign_code) THEN
				LET l_msgStr =  "Can not delete Sign Code (sign_code) record which does not exist - sign_code: ", trim(p_rec_signcode.sign_code)
				IF p_ui_mode > 0 THEN
					ERROR l_msgStr
				END IF
				RETURN -1 #PK NOT FOUND
			END IF			
	
	
	END CASE

	RETURN TRUE
	
	
END FUNCTION	
	
