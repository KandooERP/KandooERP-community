########################################################################################################################
# TABLE rndcode
#
#
########################################################################################################################

##########################################################
# GLOBAL Scope Variables
##########################################################
GLOBALS "../common/glob_GLOBALS.4gl"
GLOBALS "../common/glob_GLOBALS_userDataTypes.4gl"

			
############################################################
# FUNCTION db_rndcode_pk_exists(p_ui,p_rndcode_id)
#
# Validate PK - Unique
############################################################
#	CONSTANT UI_OFF SMALLINT = 0
#	CONSTANT UI_ON SMALLINT = 1
#	CONSTANT UI_FK SMALLINT = 2
#	CONSTANT UI_PK SMALLINT = 3
############################################################
FUNCTION db_rndcode_pk_exists(p_ui_mode,p_op_mode,p_rndcode_id)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_op_mode SMALLINT	
	DEFINE p_rndcode_id LIKE rndcode.rnd_code
	DEFINE ret BOOLEAN
	DEFINE recCount INT
	DEFINE l_msgStr STRING

	IF p_rndcode_id IS NULL THEN
		IF p_ui_mode >= UI_ON THEN
			ERROR "Rounding Code (rndcode) ID can not be empty"
			#LET msgresp = kandoomsg("G",9178,"")
			#9178 Bank/State/Branchs must NOT be NULL
		END IF
		RETURN FALSE
	END IF

	
		SQL
			SELECT count(*) 
			INTO $recCount 
			FROM rndcode 
			WHERE rndcode.rnd_code = $p_rndcode_id  
		END SQL
	
		
	IF recCount > 0 THEN
		LET ret = TRUE	
		CASE p_op_mode
			WHEN MODE_INSERT
				CASE p_ui_mode
					WHEN UI_PK
						ERROR "Rounding Code (rndcode)s Code already exists! (", trim(p_rndcode_id), ")"
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
						ERROR "Rounding Code (rndcode) ID does not exist! (", trim(p_rndcode_id), ")"
					OTHERWISE
						#No MESSAGE
				END CASE
			
			WHEN MODE_DELETE
				CASE p_ui_mode
					WHEN UI_PK
						#No MESSAGE
					WHEN UI_FK
						ERROR "Rounding Code (rndcode) ID does not exist! (", trim(p_rndcode_id), ")"
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
						ERROR "Rounding Code (rndcode) ID does not exist! (", trim(p_rndcode_id), ")"
					OTHERWISE
						#No MESSAGE
				END CASE

			WHEN MODE_UPDATE
				CASE p_ui_mode
					WHEN UI_PK
						ERROR "Rounding Code (rndcode) ID does not exist! (", trim(p_rndcode_id), ")"
					WHEN UI_FK
						#No MESSAGE
					OTHERWISE
						#No MESSAGE
				END CASE

			WHEN MODE_DELETE
				CASE p_ui_mode
					WHEN UI_PK
						ERROR "Rounding Code (rndcode) ID does not exist! (", trim(p_rndcode_id), ")"
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
# FUNCTION db_rndcode_get_count()
#
# Return total number of rows in rndcode 
############################################################
FUNCTION db_rndcode_get_count()
	DEFINE ret INT

	
		SQL
			SELECT count(*) 
			INTO $ret 
			FROM rndcode				
		
		END SQL
	
			
	RETURN ret
END FUNCTION



############################################################
# FUNCTION db_rndcode_get_count(p_rndcode_id)
#
# Return total number of rows in rndcode 
############################################################
FUNCTION db_rndcode_get_class_count(p_rndcode_id)
	DEFINE p_rndcode_id LIKE rndcode.rnd_code
	DEFINE l_ret INT

	
		SQL
			SELECT count(*) 
			INTO $l_ret 
			FROM rndcode 
			WHERE rndcode.rnd_code = $p_rndcode_id
		
		END SQL
	
			
	RETURN l_ret
END FUNCTION


############################################################
# FUNCTION db_rndcode_get_rec(p_ui_mode,p_rndcode_id)
# RETURN l_rec_rndcode.*
# Get rndcode/Part record
############################################################
FUNCTION db_rndcode_get_rec(p_ui_mode,p_rndcode_id)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_rndcode_id LIKE rndcode.rnd_code
	DEFINE l_rec_rndcode RECORD LIKE rndcode.*

	IF p_rndcode_id IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Can not retrieve record with empty Rounding Code (rndcode) ID"
		END IF
		RETURN NULL
	END IF

	
		SQL
			SELECT *
			INTO $l_rec_rndcode.*
			FROM rndcode
			WHERE rnd_code = $p_rndcode_id
		END SQL         
	
	
	IF sqlca.sqlcode != 0 THEN   		  
		INITIALIZE l_rec_rndcode.* TO NULL                                                                                      
	ELSE		                                                                                                                    
		#		                                                                                                
	END IF	         

	RETURN l_rec_rndcode.*		                                                                                                
END FUNCTION	


############################################################
# FUNCTION db_rndcode_get_rpt_text(p_ui_mode,p_rndcode_id)
# RETURN l_ret_rpt_text 
#
# Get description text of Rounding Code (rndcode) record
############################################################
FUNCTION db_rndcode_get_rpt_text(p_ui_mode,p_rndcode_id)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_rndcode_id LIKE rndcode.rnd_code
	DEFINE l_ret_rpt_text LIKE rndcode.rnd_desc

	IF p_rndcode_id IS NULL THEN
		IF p_ui_mode != UI_OFF THEN	
			ERROR "Rounding Code (rndcode) ID can NOT be empty"
		END IF
			RETURN NULL
	END IF

	
		SQL
			SELECT rnd_desc 
			INTO $l_ret_rpt_text 
			FROM rndcode
			WHERE rndcode.rnd_code = $p_rndcode_id  		
		END SQL
	
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Rounding Code (rndcode) Description with Code ",trim(p_rndcode_id),  "NOT found"
		END IF			
		LET l_ret_rpt_text = NULL
	ELSE
		#
	END IF	
	RETURN l_ret_rpt_text
END FUNCTION

############################################################
# FUNCTION db_rndcode_get_adj_acct_code(p_ui_mode,p_rndcode_id)
# RETURN l_ret_rpt_text 
#
# Get description text of Product/Part record
############################################################
FUNCTION db_rndcode_get_adj_acct_code(p_ui_mode,p_rndcode_id)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_rndcode_id LIKE rndcode.rnd_code
	DEFINE l_ret_adj_acct_code LIKE rndcode.rnd_code

	IF p_rndcode_id IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Rounding Code (rndcode) ID can NOT be empty"
		END IF
		RETURN NULL
	END IF

	
		SQL
			SELECT rnd_code 
			INTO $l_ret_adj_acct_code
			FROM rndcode 
			WHERE rndcode.rnd_code = $p_rndcode_id  		
		END SQL
	
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Rounding Code (rndcode) Reference with Rounding Code (rndcode) ID ",trim(p_rndcode_id),  "NOT found"
		END IF
		LET l_ret_adj_acct_code = NULL
	ELSE
		#	                                                                                                
	END IF	

	RETURN l_ret_adj_acct_code	                                                                                                
END FUNCTION


############################################################
# FUNCTION db_rndcode_get_adj_type_code(p_ui_mode,p_rndcode_id)
# RETURN l_ret_rpt_text 
#
# Get description text of rndcode/Part record
############################################################
FUNCTION db_rndcode_get_adj_type_code(p_ui_mode,p_rndcode_id)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_rndcode_id LIKE rndcode.rnd_code
	DEFINE l_ret_adj_type_code LIKE rndcode.rnd_code

	IF p_rndcode_id IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Rounding Code (rndcode) ID can NOT be empty"
		END IF
		RETURN NULL
	END IF

	
		SQL
			SELECT rnd_code 
			INTO $l_ret_adj_type_code
			FROM rndcode
			WHERE rndcode.rnd_code = $p_rndcode_id  		
		END SQL
	
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Rounding Code (rndcode) ID ",trim(p_rndcode_id),  "NOT found"
		END IF
		LET l_ret_adj_type_code = NULL
	ELSE
		#	                                                                                                
	END IF	

	RETURN l_ret_adj_type_code	                                                                                                
END FUNCTION


{
############################################################
# FUNCTION db_rndcode_get_cat_code(p_ui_mode,p_rndcode_id)
# RETURN l_ret_rpt_text 
#
# Get description text of Product/Part record
############################################################
FUNCTION db_rndcode_get_cat_code(p_ui_mode,p_rndcode_id)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_rndcode_id LIKE rndcode.rnd_code
	DEFINE l_ret_cat_code LIKE rndcode.cat_code

	IF p_rndcode_id IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Rounding Code (rndcode) ID can NOT be empty"
		END IF
		RETURN NULL
	END IF

	
		SQL
			SELECT cat_code 
			INTO $l_ret_cat_code
			FROM rndcode
			WHERE rndcode.rnd_code = $p_rndcode_id  		
		END SQL
	
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Rounding Code (rndcode) ID ",trim(p_rndcode_id),  "NOT found"
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
# FUNCTION db_rndcode_get_arr_rec(p_query_text)
#
#
############################################################
FUNCTION db_rndcode_get_arr_rec(p_query_type,p_query_or_where_text)
	DEFINE p_query_type SMALLINT
	DEFINE p_query_or_where_text STRING
	DEFINE l_query_text STRING
	DEFINE l_where_text STRING
	DEFINE l_arr_rec_rndcode DYNAMIC ARRAY OF RECORD LIKE rndcode.*		
	DEFINE l_rec_rndcode RECORD LIKE rndcode.*
	DEFINE l_idx SMALLINT

	IF p_query_type = FILTER_QUERY_WHERE AND p_query_or_where_text IS NULL THEN
		LET p_query_or_where_text = " 1=1 "
	END IF
		
	#p_query_text is optional
	CASE p_query_type
		WHEN FILTER_QUERY_OFF
			LET l_query_text = 
				"SELECT * FROM rndcode ",
				"ORDER BY rndcode.rnd_code" 	

		WHEN FILTER_QUERY_WHERE
			LET l_where_text = p_query_or_where_text
			LET l_query_text = 
				"SELECT * FROM rndcode ",
				"AND ", l_where_text clipped," ",
				"ORDER BY rndcode.rnd_code" 	

		WHEN FILTER_QUERY_SELECT
			LET l_query_text = p_query_or_where_text		
		
		OTHERWISE
			LET l_query_text = 
				"SELECT * FROM rndcode ",
				"ORDER BY rndcode.rnd_code" 				
	END CASE

	PREPARE s_rndcode FROM l_query_text
	DECLARE c_rndcode CURSOR FOR s_rndcode


	LET l_idx = 0
	FOREACH c_rndcode INTO l_arr_rec_rndcode[l_idx].*
      LET l_idx = l_idx + 1

	END FOREACH

	IF sqlca.sqlcode < 0 THEN   	
		LET l_arr_rec_rndcode = NULL	                                                                                        
	ELSE		                                                                                                                    
		#		                                                                                                
	END IF	         

	RETURN l_arr_rec_rndcode		                                                                                                
END FUNCTION



############################################################
# FUNCTION db_rndcode_get_arr_rec(p_query_text)
#
#
############################################################
FUNCTION db_rndcode_get_arr_rec_ac_dt_ac_with_scrollflag(p_query_type,p_query_or_where_text)
	DEFINE p_query_type SMALLINT
	DEFINE p_query_or_where_text VARCHAR(500)
	DEFINE l_query_text STRING
	DEFINE l_where_text STRING
	DEFINE l_arr_rec_rndcode DYNAMIC ARRAY OF t_rec_rndcode_id_de	
	DEFINE l_rec_rndcode t_rec_rndcode_id_de
	DEFINE l_idx SMALLINT
	
	#p_query_text is optional
	IF p_query_or_where_text IS NULL THEN
		LET p_query_type = FILTER_QUERY_OFF
	END IF

	CASE p_query_type
		WHEN FILTER_QUERY_OFF
			LET l_query_text = 
				"SELECT rnd_code,rnd_desc,rnd_code FROM rndcode ",
				"ORDER BY rndcode.rnd_code" 	


#		WHEN FILTER_QUERY_ON
#			LET l_query_text = p_query_or_where_text

		WHEN FILTER_QUERY_WHERE
			LET l_where_text = p_query_or_where_text
			LET l_query_text = 
				"SELECT rnd_code,rnd_desc,rnd_code FROM rndcode ",
				"ORDER BY rndcode.rnd_code" 	

		WHEN FILTER_QUERY_SELECT
			LET l_query_text = p_query_or_where_text		
		
		OTHERWISE
			LET l_query_text = 
				"SELECT rnd_code,rnd_desc,rnd_code FROM rndcode ",
				"ORDER BY rndcode.rnd_code" 				
	END CASE

	PREPARE s2_rndcode FROM l_query_text
	DECLARE c2_rndcode CURSOR FOR s2_rndcode


	LET l_idx = 0
	FOREACH c2_rndcode INTO l_rec_rndcode.*
		LET l_idx = l_idx + 1
		LET l_arr_rec_rndcode[l_idx].* = "",l_rec_rndcode.*
	END FOREACH

	IF sqlca.sqlcode < 0 THEN   	
		LET l_arr_rec_rndcode = NULL	                                                                                        
	ELSE		                                                                                                                    
		#		                                                                                                
	END IF	         

	RETURN l_arr_rec_rndcode		                                                                                                
END FUNCTION





########################################################################################################################
# 
# UPDATE INSERT DELETE row from DB
#
########################################################################################################################


############################################################
# FUNCTION db_rndcode_update(p_rec_rndcode)
#
#
############################################################
FUNCTION db_rndcode_update(p_ui_mode,p_pk_adj_type_code,p_rec_rndcode)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_pk_adj_type_code LIKE rndcode.rnd_code
	DEFINE p_rec_rndcode RECORD LIKE rndcode.*
	DEFINE l_ui_mode SMALLINT
	DEFINE ret INT
	DEFINE l_msgStr STRING
	
	IF p_ui_mode = UI_ON THEN
		LET l_ui_mode = UI_PK
	END IF

	IF p_pk_adj_type_code IS NULL OR p_rec_rndcode.rnd_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET l_msgStr = "Rounding Code (rndcode) ID can not be empty ! (original Rounding Code (rndcode) ID=",trim(p_pk_adj_type_code), " / new Rounding Code (rndcode) ID=", trim(p_rec_rndcode.rnd_code), ")"  
			ERROR l_msgStr
		END IF
		RETURN -1
	END IF
# Needs doing !!!!!!!!!! 	
#	IF db_XXXXXXXX_get_rndcode_count(p_pk_adj_type_code) AND (p_pk_adj_type_code <> p_rec_rndcode.rnd_code) THEN #PK rnd_code can only be changed if it's not used already
#		IF p_ui_mode > 0 THEN
#			ERROR "Can not change Rounding Code (rndcode) ! It is already used in a configuration"
#		END IF
#		LET ret =  -1
#	ELSE
		
			SQL
				UPDATE rndcode
				SET * = $p_rec_rndcode.*
				WHERE rnd_code = $p_pk_adj_type_code
			END SQL
			LET ret = status
		
#	END IF

	IF p_ui_mode != UI_OFF THEN #display MESSAGE if ui is enabled
		IF ret < 0 THEN   		
			LET l_msgStr = "Coud not modify Rounding Code (rndcode) record ! /nOriginal Rounding Code (rndcode)", trim(p_pk_adj_type_code), "New rndcode/Part ", trim(p_rec_rndcode.rnd_code),  "\nDatabase Error ", trim(ret)                                                                                        
			#ERROR l_msgStr 
			CALL fgl_winmessage("Error when trying to modify/update Rounding Code (rndcode)   record",l_msgStr,"error")
		ELSE
			LET l_msgStr = "Rounding Code (rndcode) record ", trim(p_rec_rndcode.rnd_code), " updated successfully !"   
			MESSAGE l_msgStr
		END IF                                           	
	END IF	
	
	RETURN ret
END FUNCTION        

   
############################################################
# FUNCTION db_rndcode_insert(p_rec_rndcode)
#
#
############################################################
FUNCTION db_rndcode_insert(p_ui_mode,p_rec_rndcode)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_rec_rndcode RECORD LIKE rndcode.*
	DEFINE ret INT
	DEFINE l_ui_mode SMALLINT
	DEFINE l_msgStr STRING	
	
	IF p_ui_mode = UI_ON THEN
		LET l_ui_mode = UI_PK
	END IF

	IF p_rec_rndcode.rnd_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET l_msgStr = "Rounding Code (rndcode) ID can not be empty ! (Rounding Code (rndcode)=", trim(p_rec_rndcode.rnd_code), ")"  
			ERROR l_msgStr
		END IF
		RETURN -1
	END IF


	IF db_rndcode_pk_exists(UI_PK,MODE_INSERT,p_rec_rndcode.rnd_code) THEN
		LET ret = -1
	ELSE
		
			INSERT INTO rndcode
	    VALUES(p_rec_rndcode.*)
	    LET ret = status
		
	END IF

	IF p_ui_mode != UI_OFF THEN #display MESSAGE if ui is enabled
		IF ret < 0 THEN   		
			LET l_msgStr = "Coud not create Rounding Code (rndcode)   record ", trim(p_rec_rndcode.rnd_code), " !\nDatabase Error ", trim(ret)                                                                                        
			#ERROR l_msgStr 
			CALL fgl_winmessage("Error when trying to create/insert Rounding Code (rndcode) record",l_msgStr,"error")
		ELSE
			LET l_msgStr = "PRounding Code (rndcode) record ", trim(p_rec_rndcode.rnd_code), " created successfully !"   
			MESSAGE l_msgStr
		END IF                                           	
	END IF
	
	RETURN ret
END FUNCTION


############################################################
# 
# FUNCTION db_rndcode_delete(p_rndcode_id)
#
#
############################################################
FUNCTION db_rndcode_delete(p_ui_mode,p_confirm,p_rndcode_id)
	DEFINE p_ui_mode SMALLINT #hide or show error/warning messages
	DEFINE p_confirm BOOLEAN #is operator requested to confirm this operation / independent of ui mode	
	DEFINE p_rndcode_id LIKE rndcode.rnd_code
	DEFINE l_msgresp LIKE language.yes_flag	
	DEFINE ret SMALLINT	
	DEFINE l_msgStr STRING

	IF p_confirm = UI_CONFIRM_ON THEN
		LET l_msgStr = "Delete Rounding Code (rndcode) configuration ", trim(p_rndcode_id), " ?"
		IF NOT promptTF("Delete Rounding Code (rndcode)",l_msgStr,TRUE) THEN
			RETURN -2
		END IF
	END IF
	
	IF p_rndcode_id IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET l_msgStr = "Rounding Code (rndcode) ID can not be empty ! (Rounding Code (rndcode)=", trim(p_rndcode_id), ")"  
			ERROR l_msgStr
		END IF
		RETURN -1
	END IF
# Needs doing !!!!!!!!!! 
#	IF db_XXXXX_get_rndcode_count(p_rndcode_id) THEN #PK rnd_code can only be deleted if it's not used already
#		IF p_ui_mode != UI_OFF THEN
#			LET l_msgStr = "Can not delete Product/Part ! ", trim(p_rndcode_id), " It is already used in a bank configuration"
#			CALL fgl_winmessage("Can not delete Rounding Code (rndcode) ! ",l_msgStr,"error")
#		END IF
#		LET ret =  -1
#	ELSE
		
			SQL
				DELETE FROM rndcode
				WHERE rnd_code = $p_rndcode_id
			END SQL
			LET ret = status
		
			
#	END IF
	
	IF p_ui_mode != UI_OFF THEN #display MESSAGE if ui is enabled
		IF ret < 0 THEN   		
			LET l_msgStr = "Could not delete Rounding Code (rndcode) record ", trim(p_rndcode_id), " !\nDatabase Error ", trim(ret)                                                                                        
			#ERROR l_msgStr 
			CALL fgl_winmessage("Error when trying to delete",l_msgStr,"error")
		ELSE
			LET l_msgStr = "Rounding Code (rndcode) record ", trim(p_rndcode_id), " deleted !"   
			MESSAGE l_msgStr
		END IF                                           	
	END IF		             

	RETURN ret	
		  
END FUNCTION
	

############################################################
# 
# FUNCTION db_rndcode_delete(p_rndcode_id)
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
FUNCTION db_rndcode_rec_validation(p_ui_mode,p_op_mode,p_rec_rndcode)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_op_mode SMALLINT
	DEFINE p_rec_rndcode RECORD LIKE rndcode.*
	DEFINE l_ret SMALLINT
	DEFINE l_msgStr STRING
	DISPLAY "p_ui_mode=", p_ui_mode
	DISPLAY "p_op_mode=", p_op_mode
	CASE p_op_mode
		WHEN MODE_INSERT
			#rnd_code
			LET l_msgStr = "Can not create record. Rounding Code already exists"  
			IF db_rndcode_pk_exists(UI_PK,p_op_mode,p_rec_rndcode.rnd_code) THEN
				RETURN -1 #PK Already exists
			END IF		

			#rnd_desc
			IF p_rec_rndcode.rnd_desc IS NULL THEN
				LET l_msgStr =  "Can not create Rounding Code (rndcode) record with empty description text - rnd_code: ", trim(p_rec_rndcode.rnd_code)
				IF p_ui_mode > 0 THEN
					ERROR l_msgStr
				END IF				
				RETURN -2
			END IF

#			#rnd_code
#			IF NOT db_coa_pk_exists(UI_FK,p_op_mode,p_rec_rndcode.rnd_code) THEN
#				LET l_msgStr =  "Can not create Rounding Code (rndcode) record with invalid COA Code: ", trim(p_rec_rndcode.rnd_code)
#				IF p_ui_mode > 0 THEN
#					ERROR l_msgStr
#				END IF
#				RETURN -3
#			END IF
				
		WHEN MODE_UPDATE
			#rnd_code
			IF NOT db_rndcode_pk_exists(UI_PK,p_op_mode,p_rec_rndcode.rnd_code) THEN
				LET l_msgStr = "Can not update record. Rounding Code does not exist!"  			
				RETURN -1 #PK NOT FOUND
			END IF			

			#rnd_desc
			IF p_rec_rndcode.rnd_desc IS NULL THEN
				LET l_msgStr =  "Can not update Rounding Code (rndcode) record with empty description text - rnd_code: ", trim(p_rec_rndcode.rnd_code)
				IF p_ui_mode > 0 THEN
					ERROR l_msgStr
				END IF				
				RETURN -2
			END IF

			#rnd_code
			IF NOT db_coa_pk_exists(UI_FK,p_op_mode,p_rec_rndcode.rnd_code) THEN
				LET l_msgStr =  "Can not update Rounding Code (rndcode) record with invalid GL-COA Code: ", trim(p_rec_rndcode.rnd_code)
				IF p_ui_mode > 0 THEN
					ERROR l_msgStr
				END IF
				RETURN -3
			END IF
							
		WHEN MODE_DELETE
			#rnd_code
			IF db_rndcode_pk_exists(UI_PK,p_op_mode,p_rec_rndcode.rnd_code) THEN
				LET l_msgStr =  "Can not delete Rounding Code (rndcode) record which does not exist - rnd_code: ", trim(p_rec_rndcode.rnd_code)
				IF p_ui_mode > 0 THEN
					ERROR l_msgStr
				END IF
				RETURN -1 #PK NOT FOUND
			END IF			
	
	
	END CASE

	RETURN TRUE
	
	
END FUNCTION	
	
