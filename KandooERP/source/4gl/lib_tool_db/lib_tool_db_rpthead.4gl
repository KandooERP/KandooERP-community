########################################################################################################################
# TABLE rpthead
#
#
########################################################################################################################

##########################################################
# GLOBAL Scope Variables
##########################################################
GLOBALS "../common/glob_GLOBALS.4gl"
GLOBALS "../common/glob_GLOBALS_report.4gl" 			
############################################################
# FUNCTION db_rpthead_pk_exists(p_ui,p_rpt_id)
#
# Validate PK - Unique
############################################################
#	CONSTANT UI_OFF SMALLINT = 0
#	CONSTANT UI_ON SMALLINT = 1
#	CONSTANT UI_FK SMALLINT = 2
#	CONSTANT UI_PK SMALLINT = 3
############################################################
FUNCTION db_rpthead_pk_exists(p_ui_mode,p_op_mode,p_rpt_id)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_op_mode SMALLINT	
	DEFINE p_rpt_id LIKE rpthead.rpt_id
	DEFINE ret BOOLEAN
	DEFINE recCount INT
	DEFINE msgStr STRING

	IF p_rpt_id IS NULL THEN
		IF p_ui_mode >= UI_ON THEN
			ERROR "Report ID can not be empty"
			#LET msgresp = kandoomsg("G",9178,"")
			#9178 Bank/State/Branchs must NOT be NULL
		END IF
		RETURN FALSE
	END IF

	
		SQL
			SELECT count(*) 
			INTO $recCount 
			FROM rpthead 
			WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code				
			AND rpthead.rpt_id = $p_rpt_id  
		END SQL
	
		
	IF recCount > 0 THEN
		LET ret = TRUE	
		CASE p_op_mode
			WHEN MODE_INSERT
				CASE p_ui_mode
					WHEN UI_PK
						ERROR "PATs Code already exists! (", trim(p_rpt_id), ")"
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
						ERROR "Report ID does not exist! (", trim(p_rpt_id), ")"
					OTHERWISE
						#No MESSAGE
				END CASE
			
			WHEN MODE_DELETE
				CASE p_ui_mode
					WHEN UI_PK
						#No MESSAGE
					WHEN UI_FK
						ERROR "Report ID does not exist! (", trim(p_rpt_id), ")"
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
						ERROR "Report ID does not exist! (", trim(p_rpt_id), ")"
					OTHERWISE
						#No MESSAGE
				END CASE

			WHEN MODE_UPDATE
				CASE p_ui_mode
					WHEN UI_PK
						ERROR "Report ID does not exist! (", trim(p_rpt_id), ")"
					WHEN UI_FK
						#No MESSAGE
					OTHERWISE
						#No MESSAGE
				END CASE

			WHEN MODE_DELETE
				CASE p_ui_mode
					WHEN UI_PK
						ERROR "Report ID does not exist! (", trim(p_rpt_id), ")"
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
# FUNCTION db_rpthead_get_count()
#
# Return total number of rows in rpthead 
############################################################
FUNCTION db_rpthead_get_count()
	DEFINE ret INT

	
		SQL
			SELECT count(*) 
			INTO $ret 
			FROM rpthead 
			WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code				
		
		END SQL
	
			
	RETURN ret
END FUNCTION



############################################################
# FUNCTION db_rpthead_get_count(p_rpt_id)
#
# Return total number of rows in rpthead 
############################################################
FUNCTION db_rpthead_get_class_count(p_rpt_id)
	DEFINE p_rpt_id LIKE rpthead.rpt_id
	DEFINE l_ret INT

	
		SQL
			SELECT count(*) 
			INTO $l_ret 
			FROM rpthead 
			WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code				
			AND rpthead.rpt_id = $p_rpt_id
		
		END SQL
	
			
	RETURN l_ret
END FUNCTION


############################################################
# FUNCTION db_rpthead_get_rec(p_ui_mode,p_rpt_id)
# RETURN l_rec_rpthead.*
# Get rpthead/Part record
############################################################
FUNCTION db_rpthead_get_rec(p_ui_mode,p_rpt_id)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_rpt_id LIKE rpthead.rpt_id
	DEFINE l_rec_rpthead RECORD LIKE rpthead.*

	IF p_rpt_id IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Can not retrieve record with empty Report ID"
		END IF
		RETURN NULL
	END IF

	
		SQL
			SELECT *
			INTO $l_rec_rpthead.*
			FROM rpthead
			WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code		        
			AND rpt_id = $p_rpt_id
		END SQL         
	
	
	IF sqlca.sqlcode != 0 THEN 	  
		INITIALIZE l_rec_rpthead.* TO NULL                                                                                      
	ELSE		                                                                                                                    
		#		                                                                                                
	END IF	         

	RETURN l_rec_rpthead.*		                                                                                                
END FUNCTION	


############################################################
# FUNCTION db_rpthead_get_rpt_text(p_ui_mode,p_rpt_id)
# RETURN l_ret_rpt_text 
#
# Get description text of Report Head record
############################################################
FUNCTION db_rpthead_get_rpt_text(p_ui_mode,p_rpt_id)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_rpt_id LIKE rpthead.rpt_id
	DEFINE l_ret_rpt_text LIKE rpthead.rpt_text

	IF p_rpt_id IS NULL THEN
		IF p_ui_mode != UI_OFF THEN	
			ERROR "Report ID can NOT be empty"
		END IF
			RETURN NULL
	END IF

	
		SQL
			SELECT rpt_text 
			INTO $l_ret_rpt_text 
			FROM rpthead
			WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code				 
			AND rpthead.rpt_id = $p_rpt_id  		
		END SQL
	
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Report Head Description with Code ",trim(p_rpt_id),  "NOT found"
		END IF			
		LET l_ret_rpt_text = NULL
	ELSE
		#
	END IF	
	RETURN l_ret_rpt_text
END FUNCTION

############################################################
# FUNCTION db_rpthead_get_adj_acct_code(p_ui_mode,p_rpt_id)
# RETURN l_ret_rpt_text 
#
# Get description text of Product/Part record
############################################################
FUNCTION db_rpthead_get_adj_acct_code(p_ui_mode,p_rpt_id)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_rpt_id LIKE rpthead.rpt_id
	DEFINE l_ret_adj_acct_code LIKE rpthead.rpt_id

	IF p_rpt_id IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Report ID can NOT be empty"
		END IF
		RETURN NULL
	END IF

	
		SQL
			SELECT rpt_id 
			INTO $l_ret_adj_acct_code
			FROM rpthead 
			WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code				
			AND rpthead.rpt_id = $p_rpt_id  		
		END SQL
	
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Report Head Reference with Report ID ",trim(p_rpt_id),  "NOT found"
		END IF
		LET l_ret_adj_acct_code = NULL
	ELSE
		#	                                                                                                
	END IF	

	RETURN l_ret_adj_acct_code	                                                                                                
END FUNCTION


############################################################
# FUNCTION db_rpthead_get_adj_type_code(p_ui_mode,p_rpt_id)
# RETURN l_ret_rpt_text 
#
# Get description text of rpthead/Part record
############################################################
FUNCTION db_rpthead_get_adj_type_code(p_ui_mode,p_rpt_id)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_rpt_id LIKE rpthead.rpt_id
	DEFINE l_ret_adj_type_code LIKE rpthead.rpt_id

	IF p_rpt_id IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Report ID can NOT be empty"
		END IF
		RETURN NULL
	END IF

	
		SQL
			SELECT rpt_id 
			INTO $l_ret_adj_type_code
			FROM rpthead
			WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code	
			AND rpthead.rpt_id = $p_rpt_id  		
		END SQL
	
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Report ID ",trim(p_rpt_id),  "NOT found"
		END IF
		LET l_ret_adj_type_code = NULL
	ELSE
		#	                                                                                                
	END IF	

	RETURN l_ret_adj_type_code	                                                                                                
END FUNCTION


{
############################################################
# FUNCTION db_rpthead_get_cat_code(p_ui_mode,p_rpt_id)
# RETURN l_ret_rpt_text 
#
# Get description text of Product/Part record
############################################################
FUNCTION db_rpthead_get_cat_code(p_ui_mode,p_rpt_id)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_rpt_id LIKE rpthead.rpt_id
	DEFINE l_ret_cat_code LIKE rpthead.cat_code

	IF p_rpt_id IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Report ID can NOT be empty"
		END IF
		RETURN NULL
	END IF

	
		SQL
			SELECT cat_code 
			INTO $l_ret_cat_code
			FROM rpthead
			WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code				 
			AND rpthead.rpt_id = $p_rpt_id  		
		END SQL
	
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Report ID ",trim(p_rpt_id),  "NOT found"
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
# FUNCTION db_rpthead_get_arr_rec(p_query_text)
#
#
############################################################
FUNCTION db_rpthead_get_arr_rec(p_query_type,p_query_or_where_text)
	DEFINE p_query_type SMALLINT
	DEFINE p_query_or_where_text STRING
	DEFINE l_query_text STRING
	DEFINE l_where_text STRING
	DEFINE l_arr_rec_rpthead DYNAMIC ARRAY OF RECORD LIKE rpthead.*		
	DEFINE l_rec_rpthead RECORD LIKE rpthead.*
	DEFINE l_idx SMALLINT

	IF p_query_type = FILTER_QUERY_WHERE AND p_query_or_where_text IS NULL THEN
		LET p_query_or_where_text = " 1=1 "
	END IF
		
	#p_query_text is optional
	CASE p_query_type
		WHEN FILTER_QUERY_OFF
			LET l_query_text = 
				"SELECT * FROM rpthead ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ",					
				"ORDER BY rpthead.rpt_id" 	

		WHEN FILTER_QUERY_WHERE
			LET l_where_text = p_query_or_where_text
			LET l_query_text = 
				"SELECT * FROM rpthead ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ",					
				"AND ", l_where_text clipped," ",
				"ORDER BY rpthead.rpt_id" 	

		WHEN FILTER_QUERY_SELECT
			LET l_query_text = p_query_or_where_text		
		
		OTHERWISE
			LET l_query_text = 
				"SELECT * FROM rpthead ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ",					
				"ORDER BY rpthead.rpt_id" 				
	END CASE

	PREPARE s_rpthead FROM l_query_text
	DECLARE c_rpthead CURSOR FOR s_rpthead


	LET l_idx = 0
	FOREACH c_rpthead INTO l_arr_rec_rpthead[l_idx].*
      LET l_idx = l_idx + 1

	END FOREACH

	IF sqlca.sqlcode < 0 THEN   	
		LET l_arr_rec_rpthead = NULL	                                                                                        
	ELSE		                                                                                                                    
		#		                                                                                                
	END IF	         

	RETURN l_arr_rec_rpthead		                                                                                                
END FUNCTION



############################################################
# FUNCTION db_rpthead_get_arr_rec(p_query_text)
#
#
############################################################
FUNCTION db_rpthead_get_arr_rec_ac_dt_ac_with_scrollflag(p_query_type,p_query_or_where_text)
	DEFINE p_query_type SMALLINT
	DEFINE p_query_or_where_text VARCHAR(500)
	DEFINE l_query_text STRING
	DEFINE l_where_text STRING
	DEFINE l_arr_rec_rpthead DYNAMIC ARRAY OF t_rec_rpthead_id_tx_ty	
	DEFINE l_rec_rpthead t_rec_rpthead_id_tx_ty
	DEFINE l_idx SMALLINT
	
	#p_query_text is optional
	IF p_query_or_where_text IS NULL THEN
		LET p_query_type = FILTER_QUERY_OFF
	END IF

	CASE p_query_type
		WHEN FILTER_QUERY_OFF
			LET l_query_text = 
				"SELECT rpt_id,rpt_text,rpt_id FROM rpthead ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ",					
				"ORDER BY rpthead.rpt_id" 	


#		WHEN FILTER_QUERY_ON
#			LET l_query_text = p_query_or_where_text

		WHEN FILTER_QUERY_WHERE
			LET l_where_text = p_query_or_where_text
			LET l_query_text = 
				"SELECT rpt_id,rpt_text,rpt_id FROM rpthead ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ",					
				"AND ", l_where_text clipped," ",
				"ORDER BY rpthead.rpt_id" 	

		WHEN FILTER_QUERY_SELECT
			LET l_query_text = p_query_or_where_text		
		
		OTHERWISE
			LET l_query_text = 
				"SELECT rpt_id,rpt_text,rpt_id FROM rpthead ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ",					
				"ORDER BY rpthead.rpt_id" 				
	END CASE

	PREPARE s2_rpthead FROM l_query_text
	DECLARE c2_rpthead CURSOR FOR s2_rpthead


	LET l_idx = 0
	FOREACH c2_rpthead INTO l_rec_rpthead.*
		LET l_idx = l_idx + 1
		LET l_arr_rec_rpthead[l_idx].* = "",l_rec_rpthead.*
	END FOREACH

	IF sqlca.sqlcode < 0 THEN   	
		LET l_arr_rec_rpthead = NULL	                                                                                        
	ELSE		                                                                                                                    
		#		                                                                                                
	END IF	         

	RETURN l_arr_rec_rpthead		                                                                                                
END FUNCTION





########################################################################################################################
# 
# UPDATE INSERT DELETE row from DB
#
########################################################################################################################


############################################################
# FUNCTION db_rpthead_update(p_rec_rpthead)
#
#
############################################################
FUNCTION db_rpthead_update(p_ui_mode,p_pk_adj_type_code,p_rec_rpthead)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_pk_adj_type_code LIKE rpthead.rpt_id
	DEFINE p_rec_rpthead RECORD LIKE rpthead.*
	DEFINE l_ui_mode SMALLINT
	DEFINE ret INT
	DEFINE msgStr STRING
	
	IF p_ui_mode = UI_ON THEN
		LET l_ui_mode = UI_PK
	END IF

	IF p_pk_adj_type_code IS NULL OR p_rec_rpthead.rpt_id IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET msgStr = "Report ID can not be empty ! (original Report ID=",trim(p_pk_adj_type_code), " / new Report ID=", trim(p_rec_rpthead.rpt_id), ")"  
			ERROR msgStr
		END IF
		RETURN -1
	END IF
# Needs doing !!!!!!!!!! 	
#	IF db_XXXXXXXX_get_rpthead_count(p_pk_adj_type_code) AND (p_pk_adj_type_code <> p_rec_rpthead.rpt_id) THEN #PK rpt_id can only be changed if it's not used already
#		IF p_ui_mode > 0 THEN
#			ERROR "Can not change Report Head ! It is already used in a configuration"
#		END IF
#		LET ret =  -1
#	ELSE
		
			SQL
				UPDATE rpthead
				SET * = $p_rec_rpthead.*
				WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code					
				AND rpt_id = $p_pk_adj_type_code
			END SQL
			LET ret = status
		
#	END IF

	IF p_ui_mode != UI_OFF THEN #display MESSAGE if ui is enabled
		IF ret < 0 THEN   		
			LET msgStr = "Coud not modify Report Head record ! /nOriginal PAT", trim(p_pk_adj_type_code), "New rpthead/Part ", trim(p_rec_rpthead.rpt_id),  "\nDatabase Error ", trim(ret)                                                                                        
			#ERROR msgStr 
			CALL fgl_winmessage("Error when trying to modify/update Report Head record",msgStr,"error")
		ELSE
			LET msgStr = "Report Headt record ", trim(p_rec_rpthead.rpt_id), " updated successfully !"   
			MESSAGE msgStr
		END IF                                           	
	END IF	
	
	RETURN ret
END FUNCTION        

   
############################################################
# FUNCTION db_rpthead_insert(p_rec_rpthead)
#
#
############################################################
FUNCTION db_rpthead_insert(p_ui_mode,p_rec_rpthead)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_rec_rpthead RECORD LIKE rpthead.*
	DEFINE ret INT
	DEFINE l_ui_mode SMALLINT
	DEFINE msgStr STRING	
	
	IF p_ui_mode = UI_ON THEN
		LET l_ui_mode = UI_PK
	END IF

	IF p_rec_rpthead.rpt_id IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET msgStr = "Report ID can not be empty ! (PAT=", trim(p_rec_rpthead.rpt_id), ")"  
			ERROR msgStr
		END IF
		RETURN -1
	END IF

	LET p_rec_rpthead.cmpy_code = glob_rec_kandoouser.cmpy_code
	
	IF db_rpthead_pk_exists(UI_PK,MODE_INSERT,p_rec_rpthead.rpt_id) THEN
		LET ret = -1
	ELSE
		
			INSERT INTO rpthead
	    VALUES(p_rec_rpthead.*)
	    LET ret = status
		
	END IF

	IF p_ui_mode != UI_OFF THEN #display MESSAGE if ui is enabled
		IF ret < 0 THEN   		
			LET msgStr = "Coud not create Report Head record ", trim(p_rec_rpthead.rpt_id), " !\nDatabase Error ", trim(ret)                                                                                        
			#ERROR msgStr 
			CALL fgl_winmessage("Error when trying to create/insert Report Head record",msgStr,"error")
		ELSE
			LET msgStr = "PReport Head record ", trim(p_rec_rpthead.rpt_id), " created successfully !"   
			MESSAGE msgStr
		END IF                                           	
	END IF
	
	RETURN ret
END FUNCTION


############################################################
# 
# FUNCTION db_rpthead_delete(p_rpt_id)
#
#
############################################################
FUNCTION db_rpthead_delete(p_ui_mode,p_confirm,p_rpt_id)
	DEFINE p_ui_mode SMALLINT #hide or show error/warning messages
	DEFINE p_confirm BOOLEAN #is operator requested to confirm this operation / independent of ui mode
	DEFINE p_rpt_id LIKE rpthead.rpt_id
	DEFINE l_msgresp LIKE language.yes_flag	
	DEFINE ret SMALLINT	
	DEFINE msgStr STRING

	IF p_confirm = UI_CONFIRM_ON THEN
		LET msgStr = "Delete Report Head configuration ", trim(p_rpt_id), " ?"
		IF NOT promptTF("Delete PAT",msgStr,TRUE) THEN
			RETURN -2
		END IF
	END IF
	
	IF p_rpt_id IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET msgStr = "Report ID can not be empty ! (PAT=", trim(p_rpt_id), ")"  
			ERROR msgStr
		END IF
		RETURN -1
	END IF
# Needs doing !!!!!!!!!! 
#	IF db_XXXXX_get_rpthead_count(p_rpt_id) THEN #PK rpt_id can only be deleted if it's not used already
#		IF p_ui_mode != UI_OFF THEN
#			LET msgStr = "Can not delete Product/Part ! ", trim(p_rpt_id), " It is already used in a bank configuration"
#			CALL fgl_winmessage("Can not delete PAT ! ",msgStr,"error")
#		END IF
#		LET ret =  -1
#	ELSE
		
			SQL
				DELETE FROM rpthead
				WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code					
				AND rpt_id = $p_rpt_id
			END SQL
			LET ret = status
		
			
#	END IF
	
	IF p_ui_mode != UI_OFF THEN #display MESSAGE if ui is enabled
		IF ret < 0 THEN   		
			LET msgStr = "Could not delete Report Head record ", trim(p_rpt_id), " !\nDatabase Error ", trim(ret)                                                                                        
			#ERROR msgStr 
			CALL fgl_winmessage("Error when trying to delete",msgStr,"error")
		ELSE
			LET msgStr = "Report Head record ", trim(p_rpt_id), " deleted !"   
			MESSAGE msgStr
		END IF                                           	
	END IF		             

	RETURN ret	
		  
END FUNCTION
	

############################################################
# 
# FUNCTION db_rpthead_delete(p_rpt_id)
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
FUNCTION db_rpthead_rec_validation(p_ui_mode,p_op_mode,p_rec_rpthead)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_op_mode SMALLINT
	DEFINE p_rec_rpthead RECORD LIKE rpthead.*
	DEFINE l_ret SMALLINT
	DEFINE l_msgStr STRING
	DISPLAY "p_ui_mode=", p_ui_mode
	DISPLAY "p_op_mode=", p_op_mode
	CASE p_op_mode
		WHEN MODE_INSERT
			#rpt_id
			LET l_msgStr = "Can not create record. TAP Code already exists"  
			IF db_rpthead_pk_exists(UI_PK,p_op_mode,p_rec_rpthead.rpt_id) THEN
				RETURN -1 #PK Already exists
			END IF		

			#rpt_text
			IF p_rec_rpthead.rpt_text IS NULL THEN
				LET l_msgStr =  "Can not create PAT record with empty description text - rpt_id: ", trim(p_rec_rpthead.rpt_id)
				IF p_ui_mode > 0 THEN
					ERROR l_msgStr
				END IF				
				RETURN -2
			END IF

			#rpt_id
			IF NOT db_coa_pk_exists(UI_FK,p_op_mode,p_rec_rpthead.rpt_id) THEN
				LET l_msgStr =  "Can not create PAT record with invalid COA Code: ", trim(p_rec_rpthead.rpt_id)
				IF p_ui_mode > 0 THEN
					ERROR l_msgStr
				END IF
				RETURN -3
			END IF
				
		WHEN MODE_UPDATE
			#rpt_id
			IF NOT db_rpthead_pk_exists(UI_PK,p_op_mode,p_rec_rpthead.rpt_id) THEN
				LET l_msgStr = "Can not update record. TAP Code does not exist!"  			
				RETURN -1 #PK NOT FOUND
			END IF			

			#rpt_text
			IF p_rec_rpthead.rpt_text IS NULL THEN
				LET l_msgStr =  "Can not update PAT record with empty description text - rpt_id: ", trim(p_rec_rpthead.rpt_id)
				IF p_ui_mode > 0 THEN
					ERROR l_msgStr
				END IF				
				RETURN -2
			END IF

			#rpt_id
			IF NOT db_coa_pk_exists(UI_FK,p_op_mode,p_rec_rpthead.rpt_id) THEN
				LET l_msgStr =  "Can not update PAT record with invalid GL-COA Code: ", trim(p_rec_rpthead.rpt_id)
				IF p_ui_mode > 0 THEN
					ERROR l_msgStr
				END IF
				RETURN -3
			END IF
							
		WHEN MODE_DELETE
			#rpt_id
			IF db_rpthead_pk_exists(UI_PK,p_op_mode,p_rec_rpthead.rpt_id) THEN
				LET l_msgStr =  "Can not delete PAT record which does not exist - rpt_id: ", trim(p_rec_rpthead.rpt_id)
				IF p_ui_mode > 0 THEN
					ERROR l_msgStr
				END IF
				RETURN -1 #PK NOT FOUND
			END IF			
	
	
	END CASE

	RETURN TRUE
	
	
END FUNCTION	
	
