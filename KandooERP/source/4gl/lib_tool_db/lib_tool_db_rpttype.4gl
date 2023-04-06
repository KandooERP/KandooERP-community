########################################################################################################################
# TABLE rpttype
#
#
########################################################################################################################

##########################################################
# GLOBAL Scope Variables
##########################################################
GLOBALS "../common/glob_GLOBALS.4gl"
GLOBALS "../common/glob_GLOBALS_userDataTypes.4gl"

			
############################################################
# FUNCTION db_rpttype_pk_exists(p_ui,p_rpttype_id)
#
# Validate PK - Unique
############################################################
#	CONSTANT UI_OFF SMALLINT = 0
#	CONSTANT UI_ON SMALLINT = 1
#	CONSTANT UI_FK SMALLINT = 2
#	CONSTANT UI_PK SMALLINT = 3
############################################################
FUNCTION db_rpttype_pk_exists(p_ui_mode,p_op_mode,p_rpttype_id)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_op_mode SMALLINT	
	DEFINE p_rpttype_id LIKE rpttype.rpttype_id
	DEFINE ret BOOLEAN
	DEFINE recCount INT
	DEFINE l_msgStr STRING

	IF p_rpttype_id IS NULL THEN
		IF p_ui_mode >= UI_ON THEN
			ERROR "Report Position (rpttype) ID can not be empty"
			#LET msgresp = kandoomsg("G",9178,"")
			#9178 Bank/State/Branchs must NOT be NULL
		END IF
		RETURN FALSE
	END IF

	
		SQL
			SELECT count(*) 
			INTO $recCount 
			FROM rpttype 
			WHERE rpttype.rpttype_id = $p_rpttype_id  
		END SQL
	
		
	IF recCount > 0 THEN
		LET ret = TRUE	
		CASE p_op_mode
			WHEN MODE_INSERT
				CASE p_ui_mode
					WHEN UI_PK
						ERROR "Report Position (rpttype)s Code already exists! (", trim(p_rpttype_id), ")"
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
						ERROR "Report Position (rpttype) ID does not exist! (", trim(p_rpttype_id), ")"
					OTHERWISE
						#No MESSAGE
				END CASE
			
			WHEN MODE_DELETE
				CASE p_ui_mode
					WHEN UI_PK
						#No MESSAGE
					WHEN UI_FK
						ERROR "Report Position (rpttype) ID does not exist! (", trim(p_rpttype_id), ")"
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
						ERROR "Report Position (rpttype) ID does not exist! (", trim(p_rpttype_id), ")"
					OTHERWISE
						#No MESSAGE
				END CASE

			WHEN MODE_UPDATE
				CASE p_ui_mode
					WHEN UI_PK
						ERROR "Report Position (rpttype) ID does not exist! (", trim(p_rpttype_id), ")"
					WHEN UI_FK
						#No MESSAGE
					OTHERWISE
						#No MESSAGE
				END CASE

			WHEN MODE_DELETE
				CASE p_ui_mode
					WHEN UI_PK
						ERROR "Report Position (rpttype) ID does not exist! (", trim(p_rpttype_id), ")"
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
# FUNCTION db_rpttype_get_count()
#
# Return total number of rows in rpttype 
############################################################
FUNCTION db_rpttype_get_count()
	DEFINE ret INT

	SELECT count(*) 
	INTO ret 
	FROM rpttype				
			
	RETURN ret
END FUNCTION



############################################################
# FUNCTION db_rpttype_get_count(p_rpttype_id)
#
# Return total number of rows in rpttype 
############################################################
FUNCTION db_rpttype_get_class_count(p_rpttype_id)
	DEFINE p_rpttype_id LIKE rpttype.rpttype_id
	DEFINE l_ret INT

	
		SQL
			SELECT count(*) 
			INTO $l_ret 
			FROM rpttype 
			WHERE rpttype.rpttype_id = $p_rpttype_id
		
		END SQL
	
			
	RETURN l_ret
END FUNCTION


############################################################
# FUNCTION db_rpttype_get_rec(p_ui_mode,p_rpttype_id)
# RETURN l_rec_rpttype.*
# Get rpttype/Part record
############################################################
FUNCTION db_rpttype_get_rec(p_ui_mode,p_rpttype_id)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_rpttype_id LIKE rpttype.rpttype_id
	DEFINE l_rec_rpttype RECORD LIKE rpttype.*

	IF p_rpttype_id IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Can not retrieve record with empty Report Position (rpttype) ID"
		END IF
		RETURN NULL
	END IF

	
		SQL
			SELECT *
			INTO $l_rec_rpttype.*
			FROM rpttype
			WHERE rpttype_id = $p_rpttype_id
		END SQL         
	
	
	IF sqlca.sqlcode != 0 THEN   		  
		INITIALIZE l_rec_rpttype.* TO NULL                                                                                      
	ELSE		                                                                                                                    
		#		                                                                                                
	END IF	         

	RETURN l_rec_rpttype.*		                                                                                                
END FUNCTION	


############################################################
# FUNCTION db_rpttype_get_rpt_text(p_ui_mode,p_rpttype_id)
# RETURN l_ret_rpt_text 
#
# Get description text of Report Position (rpttype) record
############################################################
FUNCTION db_rpttype_get_rpt_text(p_ui_mode,p_rpttype_id)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_rpttype_id LIKE rpttype.rpttype_id
	DEFINE l_ret_rpt_text LIKE rpttype.rpttype_desc

	IF p_rpttype_id IS NULL THEN
		IF p_ui_mode != UI_OFF THEN	
			ERROR "Report Position (rpttype) ID can NOT be empty"
		END IF
			RETURN NULL
	END IF

	
		SQL
			SELECT rpttype_desc 
			INTO $l_ret_rpt_text 
			FROM rpttype
			WHERE rpttype.rpttype_id = $p_rpttype_id  		
		END SQL
	
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Report Position (rpttype) Description with Code ",trim(p_rpttype_id),  "NOT found"
		END IF			
		LET l_ret_rpt_text = NULL
	ELSE
		#
	END IF	
	RETURN l_ret_rpt_text
END FUNCTION

############################################################
# FUNCTION db_rpttype_get_adj_acct_code(p_ui_mode,p_rpttype_id)
# RETURN l_ret_rpt_text 
#
# Get description text of Product/Part record
############################################################
FUNCTION db_rpttype_get_adj_acct_code(p_ui_mode,p_rpttype_id)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_rpttype_id LIKE rpttype.rpttype_id
	DEFINE l_ret_adj_acct_code LIKE rpttype.rpttype_id

	IF p_rpttype_id IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Report Position (rpttype) ID can NOT be empty"
		END IF
		RETURN NULL
	END IF

	
		SQL
			SELECT rpttype_id 
			INTO $l_ret_adj_acct_code
			FROM rpttype 
			WHERE rpttype.rpttype_id = $p_rpttype_id  		
		END SQL
	
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Report Position (rpttype) Reference with Report Position (rpttype) ID ",trim(p_rpttype_id),  "NOT found"
		END IF
		LET l_ret_adj_acct_code = NULL
	ELSE
		#	                                                                                                
	END IF	

	RETURN l_ret_adj_acct_code	                                                                                                
END FUNCTION


############################################################
# FUNCTION db_rpttype_get_adj_type_code(p_ui_mode,p_rpttype_id)
# RETURN l_ret_rpt_text 
#
# Get description text of rpttype/Part record
############################################################
FUNCTION db_rpttype_get_adj_type_code(p_ui_mode,p_rpttype_id)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_rpttype_id LIKE rpttype.rpttype_id
	DEFINE l_ret_adj_type_code LIKE rpttype.rpttype_id

	IF p_rpttype_id IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Report Position (rpttype) ID can NOT be empty"
		END IF
		RETURN NULL
	END IF

	
		SQL
			SELECT rpttype_id 
			INTO $l_ret_adj_type_code
			FROM rpttype
			WHERE rpttype.rpttype_id = $p_rpttype_id  		
		END SQL
	
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Report Position (rpttype) ID ",trim(p_rpttype_id),  "NOT found"
		END IF
		LET l_ret_adj_type_code = NULL
	ELSE
		#	                                                                                                
	END IF	

	RETURN l_ret_adj_type_code	                                                                                                
END FUNCTION


{
############################################################
# FUNCTION db_rpttype_get_cat_code(p_ui_mode,p_rpttype_id)
# RETURN l_ret_rpt_text 
#
# Get description text of Product/Part record
############################################################
FUNCTION db_rpttype_get_cat_code(p_ui_mode,p_rpttype_id)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_rpttype_id LIKE rpttype.rpttype_id
	DEFINE l_ret_cat_code LIKE rpttype.cat_code

	IF p_rpttype_id IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Report Position (rpttype) ID can NOT be empty"
		END IF
		RETURN NULL
	END IF

	
		SQL
			SELECT cat_code 
			INTO $l_ret_cat_code
			FROM rpttype
			WHERE rpttype.rpttype_id = $p_rpttype_id  		
		END SQL
	
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Report Position (rpttype) ID ",trim(p_rpttype_id),  "NOT found"
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
# FUNCTION db_rpttype_get_arr_rec(p_query_text)
#
#
############################################################
FUNCTION db_rpttype_get_arr_rec(p_query_type,p_query_or_where_text)
	DEFINE p_query_type SMALLINT
	DEFINE p_query_or_where_text STRING
	DEFINE l_query_text STRING
	DEFINE l_where_text STRING
	DEFINE l_arr_rec_rpttype DYNAMIC ARRAY OF RECORD LIKE rpttype.*		
	DEFINE l_rec_rpttype RECORD LIKE rpttype.*
	DEFINE l_idx SMALLINT

	IF p_query_type = FILTER_QUERY_WHERE AND p_query_or_where_text IS NULL THEN
		LET p_query_or_where_text = " 1=1 "
	END IF
		
	#p_query_text is optional
	CASE p_query_type
		WHEN FILTER_QUERY_OFF
			LET l_query_text = 
				"SELECT * FROM rpttype ",
				"ORDER BY rpttype.rpttype_id" 	

		WHEN FILTER_QUERY_WHERE
			LET l_where_text = p_query_or_where_text
			LET l_query_text = 
				"SELECT * FROM rpttype ",
				"AND ", l_where_text clipped," ",
				"ORDER BY rpttype.rpttype_id" 	

		WHEN FILTER_QUERY_SELECT
			LET l_query_text = p_query_or_where_text		
		
		OTHERWISE
			LET l_query_text = 
				"SELECT * FROM rpttype ",
				"ORDER BY rpttype.rpttype_id" 				
	END CASE

	PREPARE s_rpttype FROM l_query_text
	DECLARE c_rpttype CURSOR FOR s_rpttype


	LET l_idx = 0
	FOREACH c_rpttype INTO l_arr_rec_rpttype[l_idx].*
      LET l_idx = l_idx + 1

	END FOREACH

	IF sqlca.sqlcode < 0 THEN   	
		LET l_arr_rec_rpttype = NULL	                                                                                        
	ELSE		                                                                                                                    
		#		                                                                                                
	END IF	         

	RETURN l_arr_rec_rpttype		                                                                                                
END FUNCTION



############################################################
# FUNCTION db_rpttype_get_arr_rec(p_query_text)
#
#
############################################################
FUNCTION db_rpttype_get_arr_rec_ac_dt_ac_with_scrollflag(p_query_type,p_query_or_where_text)
	DEFINE p_query_type SMALLINT
	DEFINE p_query_or_where_text VARCHAR(500)
	DEFINE l_query_text STRING
	DEFINE l_where_text STRING
	DEFINE l_arr_rec_rpttype DYNAMIC ARRAY OF t_rec_rpttype_id_de	
	DEFINE l_rec_rpttype t_rec_rpttype_id_de
	DEFINE l_idx SMALLINT
	
	#p_query_text is optional
	IF p_query_or_where_text IS NULL THEN
		LET p_query_type = FILTER_QUERY_OFF
	END IF

	CASE p_query_type
		WHEN FILTER_QUERY_OFF
			LET l_query_text = 
				"SELECT rpttype_id,rpttype_desc,rpttype_id FROM rpttype ",
				"ORDER BY rpttype.rpttype_id" 	


#		WHEN FILTER_QUERY_ON
#			LET l_query_text = p_query_or_where_text

		WHEN FILTER_QUERY_WHERE
			LET l_where_text = p_query_or_where_text
			LET l_query_text = 
				"SELECT rpttype_id,rpttype_desc,rpttype_id FROM rpttype ",
				"ORDER BY rpttype.rpttype_id" 	

		WHEN FILTER_QUERY_SELECT
			LET l_query_text = p_query_or_where_text		
		
		OTHERWISE
			LET l_query_text = 
				"SELECT rpttype_id,rpttype_desc,rpttype_id FROM rpttype ",
				"ORDER BY rpttype.rpttype_id" 				
	END CASE

	PREPARE s2_rpttype FROM l_query_text
	DECLARE c2_rpttype CURSOR FOR s2_rpttype


	LET l_idx = 0
	FOREACH c2_rpttype INTO l_rec_rpttype.*
		LET l_idx = l_idx + 1
		LET l_arr_rec_rpttype[l_idx].* = "",l_rec_rpttype.*
	END FOREACH

	IF sqlca.sqlcode < 0 THEN   	
		LET l_arr_rec_rpttype = NULL	                                                                                        
	ELSE		                                                                                                                    
		#		                                                                                                
	END IF	         

	RETURN l_arr_rec_rpttype		                                                                                                
END FUNCTION





########################################################################################################################
# 
# UPDATE INSERT DELETE row from DB
#
########################################################################################################################


############################################################
# FUNCTION db_rpttype_update(p_rec_rpttype)
#
#
############################################################
FUNCTION db_rpttype_update(p_ui_mode,p_pk_adj_type_code,p_rec_rpttype)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_pk_adj_type_code LIKE rpttype.rpttype_id
	DEFINE p_rec_rpttype RECORD LIKE rpttype.*
	DEFINE l_ui_mode SMALLINT
	DEFINE ret INT
	DEFINE l_msgStr STRING
	
	IF p_ui_mode = UI_ON THEN
		LET l_ui_mode = UI_PK
	END IF

	IF p_pk_adj_type_code IS NULL OR p_rec_rpttype.rpttype_id IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET l_msgStr = "Report Position (rpttype) ID can not be empty ! (original Report Position (rpttype) ID=",trim(p_pk_adj_type_code), " / new Report Position (rpttype) ID=", trim(p_rec_rpttype.rpttype_id), ")"  
			ERROR l_msgStr
		END IF
		RETURN -1
	END IF
# Needs doing !!!!!!!!!! 	
#	IF db_XXXXXXXX_get_rpttype_count(p_pk_adj_type_code) AND (p_pk_adj_type_code <> p_rec_rpttype.rpttype_id) THEN #PK rpttype_id can only be changed if it's not used already
#		IF p_ui_mode > 0 THEN
#			ERROR "Can not change Report Position (rpttype) ! It is already used in a configuration"
#		END IF
#		LET ret =  -1
#	ELSE
		
			SQL
				UPDATE rpttype
				SET * = $p_rec_rpttype.*
				WHERE rpttype_id = $p_pk_adj_type_code
			END SQL
			LET ret = status
		
#	END IF

	IF p_ui_mode != UI_OFF THEN #display MESSAGE if ui is enabled
		IF ret < 0 THEN   		
			LET l_msgStr = "Coud not modify Report Position (rpttype) record ! /nOriginal Report Position (rpttype)", trim(p_pk_adj_type_code), "New rpttype/Part ", trim(p_rec_rpttype.rpttype_id),  "\nDatabase Error ", trim(ret)                                                                                        
			#ERROR l_msgStr 
			CALL fgl_winmessage("Error when trying to modify/update Report Position (rpttype) record",l_msgStr,"error")
		ELSE
			LET l_msgStr = "Report Position (rpttype) Headt record ", trim(p_rec_rpttype.rpttype_id), " updated successfully !"   
			MESSAGE l_msgStr
		END IF                                           	
	END IF	
	
	RETURN ret
END FUNCTION        

   
############################################################
# FUNCTION db_rpttype_insert(p_rec_rpttype)
#
#
############################################################
FUNCTION db_rpttype_insert(p_ui_mode,p_rec_rpttype)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_rec_rpttype RECORD LIKE rpttype.*
	DEFINE ret INT
	DEFINE l_ui_mode SMALLINT
	DEFINE l_msgStr STRING	
	
	IF p_ui_mode = UI_ON THEN
		LET l_ui_mode = UI_PK
	END IF

	IF p_rec_rpttype.rpttype_id IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET l_msgStr = "Report Position (rpttype) ID can not be empty ! (Report Position (rpttype)=", trim(p_rec_rpttype.rpttype_id), ")"  
			ERROR l_msgStr
		END IF
		RETURN -1
	END IF


	IF db_rpttype_pk_exists(UI_PK,MODE_INSERT,p_rec_rpttype.rpttype_id) THEN
		LET ret = -1
	ELSE
		
			INSERT INTO rpttype
	    VALUES(p_rec_rpttype.*)
	    LET ret = status
		
	END IF

	IF p_ui_mode != UI_OFF THEN #display MESSAGE if ui is enabled
		IF ret < 0 THEN   		
			LET l_msgStr = "Coud not create Report Position (rpttype) record ", trim(p_rec_rpttype.rpttype_id), " !\nDatabase Error ", trim(ret)                                                                                        
			#ERROR l_msgStr 
			CALL fgl_winmessage("Error when trying to create/insert Report Position (rpttype) record",l_msgStr,"error")
		ELSE
			LET l_msgStr = "PReport Position (rpttype) record ", trim(p_rec_rpttype.rpttype_id), " created successfully !"   
			MESSAGE l_msgStr
		END IF                                           	
	END IF
	
	RETURN ret
END FUNCTION


############################################################
# 
# FUNCTION db_rpttype_delete(p_rpttype_id)
#
#
############################################################
FUNCTION db_rpttype_delete(p_ui_mode,p_confirm,p_rpttype_id)
	DEFINE p_ui_mode SMALLINT #hide or show error/warning messages
	DEFINE p_confirm BOOLEAN #is operator requested to confirm this operation / independent of ui mode	
	DEFINE p_rpttype_id LIKE rpttype.rpttype_id
	DEFINE l_msgresp LIKE language.yes_flag	
	DEFINE ret SMALLINT	
	DEFINE l_msgStr STRING

	IF p_confirm = UI_CONFIRM_ON THEN
		LET l_msgStr = "Delete Report Position (rpttype) configuration ", trim(p_rpttype_id), " ?"
		IF NOT promptTF("Delete Report Position (rpttype)",l_msgStr,TRUE) THEN
			RETURN -2
		END IF
	END IF
	
	IF p_rpttype_id IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET l_msgStr = "Report Position (rpttype) ID can not be empty ! (Report Position (rpttype)=", trim(p_rpttype_id), ")"  
			ERROR l_msgStr
		END IF
		RETURN -1
	END IF
# Needs doing !!!!!!!!!! 
#	IF db_XXXXX_get_rpttype_count(p_rpttype_id) THEN #PK rpttype_id can only be deleted if it's not used already
#		IF p_ui_mode != UI_OFF THEN
#			LET l_msgStr = "Can not delete Product/Part ! ", trim(p_rpttype_id), " It is already used in a bank configuration"
#			CALL fgl_winmessage("Can not delete Report Position (rpttype) ! ",l_msgStr,"error")
#		END IF
#		LET ret =  -1
#	ELSE
		
			SQL
				DELETE FROM rpttype
				WHERE rpttype_id = $p_rpttype_id
			END SQL
			LET ret = status
		
			
#	END IF
	
	IF p_ui_mode != UI_OFF THEN #display MESSAGE if ui is enabled
		IF ret < 0 THEN   		
			LET l_msgStr = "Could not delete Report Position (rpttype) record ", trim(p_rpttype_id), " !\nDatabase Error ", trim(ret)                                                                                        
			#ERROR l_msgStr 
			CALL fgl_winmessage("Error when trying to delete",l_msgStr,"error")
		ELSE
			LET l_msgStr = "Report Position (rpttype) record ", trim(p_rpttype_id), " deleted !"   
			MESSAGE l_msgStr
		END IF                                           	
	END IF		             

	RETURN ret	
		  
END FUNCTION
	

############################################################
# 
# FUNCTION db_rpttype_delete(p_rpttype_id)
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
FUNCTION db_rpttype_rec_validation(p_ui_mode,p_op_mode,p_rec_rpttype)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_op_mode SMALLINT
	DEFINE p_rec_rpttype RECORD LIKE rpttype.*
	DEFINE l_ret SMALLINT
	DEFINE l_msgStr STRING
	DISPLAY "p_ui_mode=", p_ui_mode
	DISPLAY "p_op_mode=", p_op_mode
	CASE p_op_mode
		WHEN MODE_INSERT
			#rpttype_id
			LET l_msgStr = "Can not create record. TAP Code already exists"  
			IF db_rpttype_pk_exists(UI_PK,p_op_mode,p_rec_rpttype.rpttype_id) THEN
				RETURN -1 #PK Already exists
			END IF		

			#rpttype_desc
			IF p_rec_rpttype.rpttype_desc IS NULL THEN
				LET l_msgStr =  "Can not create Report Position (rpttype) record with empty description text - rpttype_id: ", trim(p_rec_rpttype.rpttype_id)
				IF p_ui_mode > 0 THEN
					ERROR l_msgStr
				END IF				
				RETURN -2
			END IF

			#rpttype_id
			IF NOT db_coa_pk_exists(UI_FK,p_op_mode,p_rec_rpttype.rpttype_id) THEN
				LET l_msgStr =  "Can not create Report Position (rpttype) record with invalid COA Code: ", trim(p_rec_rpttype.rpttype_id)
				IF p_ui_mode > 0 THEN
					ERROR l_msgStr
				END IF
				RETURN -3
			END IF
				
		WHEN MODE_UPDATE
			#rpttype_id
			IF NOT db_rpttype_pk_exists(UI_PK,p_op_mode,p_rec_rpttype.rpttype_id) THEN
				LET l_msgStr = "Can not update record. TAP Code does not exist!"  			
				RETURN -1 #PK NOT FOUND
			END IF			

			#rpttype_desc
			IF p_rec_rpttype.rpttype_desc IS NULL THEN
				LET l_msgStr =  "Can not update Report Position (rpttype) record with empty description text - rpttype_id: ", trim(p_rec_rpttype.rpttype_id)
				IF p_ui_mode > 0 THEN
					ERROR l_msgStr
				END IF				
				RETURN -2
			END IF

			#rpttype_id
			IF NOT db_coa_pk_exists(UI_FK,p_op_mode,p_rec_rpttype.rpttype_id) THEN
				LET l_msgStr =  "Can not update Report Position (rpttype) record with invalid GL-COA Code: ", trim(p_rec_rpttype.rpttype_id)
				IF p_ui_mode > 0 THEN
					ERROR l_msgStr
				END IF
				RETURN -3
			END IF
							
		WHEN MODE_DELETE
			#rpttype_id
			IF db_rpttype_pk_exists(UI_PK,p_op_mode,p_rec_rpttype.rpttype_id) THEN
				LET l_msgStr =  "Can not delete Report Position (rpttype) record which does not exist - rpttype_id: ", trim(p_rec_rpttype.rpttype_id)
				IF p_ui_mode > 0 THEN
					ERROR l_msgStr
				END IF
				RETURN -1 #PK NOT FOUND
			END IF			
	
	
	END CASE

	RETURN TRUE
	
	
END FUNCTION	
	
