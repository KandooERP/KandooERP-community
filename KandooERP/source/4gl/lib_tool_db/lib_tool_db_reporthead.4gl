########################################################################################################################
# TABLE reporthead
#
#
########################################################################################################################

##########################################################
# GLOBAL Scope Variables
##########################################################
GLOBALS "../common/glob_GLOBALS.4gl"


			
############################################################
# FUNCTION db_reporthead_pk_exists(p_ui,p_report_code)
#
# Validate PK - Unique
############################################################
#	CONSTANT UI_OFF SMALLINT = 0
#	CONSTANT UI_ON SMALLINT = 1
#	CONSTANT UI_FK SMALLINT = 2
#	CONSTANT UI_PK SMALLINT = 3
############################################################
FUNCTION db_reporthead_pk_exists(p_ui_mode,p_op_mode,p_report_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_op_mode SMALLINT	
	DEFINE p_report_code LIKE reporthead.report_code
	DEFINE ret BOOLEAN
	DEFINE recCount INT
	DEFINE msgStr STRING

	IF p_report_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Report Code can not be empty"
			#LET msgresp = kandoomsg("G",9178,"")
			#9178 Bank/State/Branchs must NOT be NULL
		END IF
		RETURN FALSE
	END IF

		SQL
			SELECT count(*) 
			INTO $recCount 
			FROM reporthead 
			WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code				
			AND reporthead.report_code = $p_report_code  
		END SQL
		
	IF recCount > 0 THEN
		LET ret = TRUE	
		CASE p_op_mode
			WHEN MODE_INSERT
				CASE p_ui_mode
					WHEN UI_PK
						ERROR "Reports Code already exists! (", trim(p_report_code), ")"
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
						ERROR "Report Code does not exist! (", trim(p_report_code), ")"
					OTHERWISE
						#No MESSAGE
				END CASE
			
			WHEN MODE_DELETE
				CASE p_ui_mode
					WHEN UI_PK
						#No MESSAGE
					WHEN UI_FK
						ERROR "Report Code does not exist! (", trim(p_report_code), ")"
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
						ERROR "Report Code does not exist! (", trim(p_report_code), ")"
					OTHERWISE
						#No MESSAGE
				END CASE

			WHEN MODE_UPDATE
				CASE p_ui_mode
					WHEN UI_PK
						ERROR "Report Code does not exist! (", trim(p_report_code), ")"
					WHEN UI_FK
						#No MESSAGE
					OTHERWISE
						#No MESSAGE
				END CASE

			WHEN MODE_DELETE
				CASE p_ui_mode
					WHEN UI_PK
						ERROR "Report Code does not exist! (", trim(p_report_code), ")"
					WHEN UI_FK
						#No MESSAGE
					OTHERWISE
						#No MESSAGE
				END CASE
				
		END CASE	
	END IF
	
	RETURN ret
END FUNCTION

FUNCTION db_reporthead_pk_exists_arg_cmpy_code(p_ui_mode,p_op_mode,p_report_code,p_cmpy_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_op_mode SMALLINT	
	DEFINE p_report_code LIKE reporthead.report_code
	DEFINE p_cmpy_code LIKE company.cmpy_code
	DEFINE ret BOOLEAN
	DEFINE recCount INT
	DEFINE msgStr STRING

	IF p_report_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Report Code can not be empty"
			#LET msgresp = kandoomsg("G",9178,"")
			#9178 Bank/State/Branchs must NOT be NULL
		END IF
		RETURN FALSE
	END IF

	IF p_cmpy_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Company Code can not be empty"
			#LET msgresp = kandoomsg("G",9178,"")
			#9178 Bank/State/Branchs must NOT be NULL
		END IF
		RETURN FALSE
	END IF

		SQL
			SELECT count(*) 
			INTO $recCount 
			FROM reporthead 
			WHERE cmpy_code = $p_cmpy_code			
			AND reporthead.report_code = $p_report_code  
		END SQL
		
	IF recCount > 0 THEN
		LET ret = TRUE	
		CASE p_op_mode
			WHEN MODE_INSERT
				CASE p_ui_mode
					WHEN UI_PK
						ERROR "Reports Code already exists! (", trim(p_report_code), ")"
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
						ERROR "Report Code does not exist! (", trim(p_report_code), ")"
					OTHERWISE
						#No MESSAGE
				END CASE
			
			WHEN MODE_DELETE
				CASE p_ui_mode
					WHEN UI_PK
						#No MESSAGE
					WHEN UI_FK
						ERROR "Report Code does not exist! (", trim(p_report_code), ")"
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
						ERROR "Report Code does not exist! (", trim(p_report_code), ")"
					OTHERWISE
						#No MESSAGE
				END CASE

			WHEN MODE_UPDATE
				CASE p_ui_mode
					WHEN UI_PK
						ERROR "Report Code does not exist! (", trim(p_report_code), ")"
					WHEN UI_FK
						#No MESSAGE
					OTHERWISE
						#No MESSAGE
				END CASE

			WHEN MODE_DELETE
				CASE p_ui_mode
					WHEN UI_PK
						ERROR "Report Code does not exist! (", trim(p_report_code), ")"
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
# FUNCTION db_reporthead_get_count()
#
# Return total number of rows in reporthead 
############################################################
FUNCTION db_reporthead_get_count()
	DEFINE ret INT

		SQL
			SELECT count(*) 
			INTO $ret 
			FROM reporthead 
			WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code				
		
		END SQL
			
	RETURN ret
END FUNCTION



############################################################
# FUNCTION db_reporthead_get_count(p_report_code)
#
# Return total number of rows in reporthead 
############################################################
FUNCTION db_reporthead_get_class_count(p_report_code)
	DEFINE p_report_code LIKE reporthead.report_code
	DEFINE l_ret INT

		SQL
			SELECT count(*) 
			INTO $l_ret 
			FROM reporthead 
			WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code				
			AND reporthead.report_code = $p_report_code
		
		END SQL
			
	RETURN l_ret
END FUNCTION


############################################################
# FUNCTION db_reporthead_get_rec(p_ui_mode,p_report_code)
# RETURN l_rec_reporthead.*
# Get reporthead/Part record
############################################################
FUNCTION db_reporthead_get_rec(p_ui_mode,p_report_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_report_code LIKE reporthead.report_code
	DEFINE l_rec_reporthead RECORD LIKE reporthead.*

	IF p_report_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Can not retrieve record with empty Product Adjustment Types Code"
		END IF
		RETURN NULL
	END IF

		SQL
			SELECT *
			INTO $l_rec_reporthead.*
			FROM reporthead
			WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code		        
			AND report_code = $p_report_code
		END SQL         
	
	IF sqlca.sqlcode != 0 THEN   		  
		INITIALIZE l_rec_reporthead.* TO NULL                                                                                      
	ELSE		                                                                                                                    
		#		                                                                                                
	END IF	         

	RETURN l_rec_reporthead.*		                                                                                                
END FUNCTION	


############################################################
# FUNCTION db_reporthead_get_desc_text(p_ui_mode,p_report_code)
# RETURN l_ret_desc_text 
#
# Get description text of Product Adjustment Types record
############################################################
FUNCTION db_reporthead_get_desc_text(p_ui_mode,p_report_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_report_code LIKE reporthead.report_code
	DEFINE l_ret_desc_text LIKE reporthead.desc_text

	IF p_report_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN	
			ERROR "Product Adjustment Types Code can NOT be empty"
		END IF
			RETURN NULL
	END IF

		SQL
			SELECT desc_text 
			INTO $l_ret_desc_text 
			FROM reporthead
			WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code				 
			AND reporthead.report_code = $p_report_code  		
		END SQL
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Product Adjustment Types Description with Code ",trim(p_report_code),  "NOT found"
		END IF			
		LET l_ret_desc_text = NULL
	ELSE
		#
	END IF	
	RETURN l_ret_desc_text
END FUNCTION

############################################################
# FUNCTION db_reporthead_get_column_num(p_ui_mode,p_report_code)
# RETURN l_ret_desc_text 
#
# Get description text of Product/Part record
############################################################
FUNCTION db_reporthead_get_column_num(p_ui_mode,p_report_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_report_code LIKE reporthead.report_code
	DEFINE l_ret_column_num LIKE reporthead.column_num

	IF p_report_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Product Adjustment Types Code can NOT be empty"
		END IF
		RETURN NULL
	END IF

		SQL
			SELECT column_num 
			INTO $l_ret_column_num
			FROM reporthead 
			WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code				
			AND reporthead.report_code = $p_report_code  		
		END SQL
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Product Adjustment Types Reference with Product Adjustment Types Code ",trim(p_report_code),  "NOT found"
		END IF
		LET l_ret_column_num = NULL
	ELSE
		#	                                                                                                
	END IF	

	RETURN l_ret_column_num	                                                                                                
END FUNCTION


############################################################
# FUNCTION db_reporthead_get_report_code(p_ui_mode,p_report_code)
# RETURN l_ret_desc_text 
#
# Get description text of reporthead/Part record
############################################################
FUNCTION db_reporthead_get_report_code(p_ui_mode,p_report_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_report_code LIKE reporthead.report_code
	DEFINE l_ret_report_code LIKE reporthead.report_code

	IF p_report_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Product Adjustment Types Code can NOT be empty"
		END IF
		RETURN NULL
	END IF

		SQL
			SELECT report_code 
			INTO $l_ret_report_code
			FROM reporthead
			WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code	
			AND reporthead.report_code = $p_report_code  		
		END SQL
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Product Adjustment Types Code ",trim(p_report_code),  "NOT found"
		END IF
		LET l_ret_report_code = NULL
	ELSE
		#	                                                                                                
	END IF	

	RETURN l_ret_report_code	                                                                                                
END FUNCTION


{
############################################################
# FUNCTION db_reporthead_get_cat_code(p_ui_mode,p_report_code)
# RETURN l_ret_desc_text 
#
# Get description text of Product/Part record
############################################################
FUNCTION db_reporthead_get_cat_code(p_ui_mode,p_report_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_report_code LIKE reporthead.report_code
	DEFINE l_ret_cat_code LIKE reporthead.cat_code

	IF p_report_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Product Adjustment Types Code can NOT be empty"
		END IF
		RETURN NULL
	END IF

		SQL
			SELECT cat_code 
			INTO $l_ret_cat_code
			FROM reporthead
			WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code				 
			AND reporthead.report_code = $p_report_code  		
		END SQL
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Product Adjustment Types Code ",trim(p_report_code),  "NOT found"
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
# FUNCTION db_reporthead_get_arr_rec(p_query_text)
#
#
############################################################
FUNCTION db_reporthead_get_arr_rec(p_query_type,p_query_or_where_text)
	DEFINE p_query_type SMALLINT
	DEFINE p_query_or_where_text STRING
	DEFINE l_query_text STRING
	DEFINE l_where_text STRING
	DEFINE l_arr_rec_reporthead DYNAMIC ARRAY OF RECORD LIKE reporthead.*		
	DEFINE l_rec_reporthead RECORD LIKE reporthead.*
	DEFINE l_idx SMALLINT

	IF p_query_type = FILTER_QUERY_WHERE AND p_query_or_where_text IS NULL THEN
		LET p_query_or_where_text = " 1=1 "
	END IF
		
	#p_query_text is optional
	CASE p_query_type
		WHEN FILTER_QUERY_OFF
			LET l_query_text = 
				"SELECT * FROM reporthead ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ",					
				"ORDER BY reporthead.report_code" 	

		WHEN FILTER_QUERY_WHERE
			LET l_where_text = p_query_or_where_text
			LET l_query_text = 
				"SELECT * FROM reporthead ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ",					
				"AND ", l_where_text clipped," ",
				"ORDER BY reporthead.report_code" 	

		WHEN FILTER_QUERY_SELECT
			LET l_query_text = p_query_or_where_text		
		
		OTHERWISE
			LET l_query_text = 
				"SELECT * FROM reporthead ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ",					
				"ORDER BY reporthead.report_code" 				
	END CASE

	PREPARE s_reporthead FROM l_query_text
	DECLARE c_reporthead CURSOR FOR s_reporthead


	LET l_idx = 0
	FOREACH c_reporthead INTO l_arr_rec_reporthead[l_idx].*
      LET l_idx = l_idx + 1

	END FOREACH

	IF sqlca.sqlcode < 0 THEN   	
		LET l_arr_rec_reporthead = NULL	                                                                                        
	ELSE		                                                                                                                    
		#		                                                                                                
	END IF	         

	RETURN l_arr_rec_reporthead		                                                                                                
END FUNCTION

{

############################################################
# FUNCTION db_reporthead_get_arr_rec(p_query_text)
#
#
############################################################
FUNCTION db_reporthead_get_arr_rec_ac_dt_ac_with_scrollflag(p_query_type,p_query_or_where_text)
	DEFINE p_query_type SMALLINT
	DEFINE p_query_or_where_text VARCHAR(500)
	DEFINE l_query_text STRING
	DEFINE l_where_text STRING
	DEFINE l_arr_rec_reporthead DYNAMIC ARRAY OF t_rec_reporthead_ac_dt_ac_with_scrollflag	
	DEFINE l_rec_reporthead t_rec_reporthead_ac_dt_ac
	DEFINE l_idx SMALLINT
	
	#p_query_text is optional
	IF p_query_or_where_text IS NULL THEN
		LET p_query_type = FILTER_QUERY_OFF
	END IF

	CASE p_query_type
		WHEN FILTER_QUERY_OFF
			LET l_query_text = 
				"SELECT report_code,desc_text,column_num FROM reporthead ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ",					
				"ORDER BY reporthead.report_code" 	


#		WHEN FILTER_QUERY_ON
#			LET l_query_text = p_query_or_where_text

		WHEN FILTER_QUERY_WHERE
			LET l_where_text = p_query_or_where_text
			LET l_query_text = 
				"SELECT report_code,desc_text,column_num FROM reporthead ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ",					
				"AND ", l_where_text clipped," ",
				"ORDER BY reporthead.report_code" 	

		WHEN FILTER_QUERY_SELECT
			LET l_query_text = p_query_or_where_text		
		
		OTHERWISE
			LET l_query_text = 
				"SELECT report_code,desc_text,column_num FROM reporthead ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ",					
				"ORDER BY reporthead.report_code" 				
	END CASE

	PREPARE s2_reporthead FROM l_query_text
	DECLARE c2_reporthead CURSOR FOR s2_reporthead


	LET l_idx = 0
	FOREACH c2_reporthead INTO l_rec_reporthead.*
		LET l_idx = l_idx + 1
		LET l_arr_rec_reporthead[l_idx].* = "",l_rec_reporthead.*
	END FOREACH

	IF sqlca.sqlcode < 0 THEN   	
		LET l_arr_rec_reporthead = NULL	                                                                                        
	ELSE		                                                                                                                    
		#		                                                                                                
	END IF	         

	RETURN l_arr_rec_reporthead		                                                                                                
END FUNCTION

}



########################################################################################################################
# 
# UPDATE INSERT DELETE row from DB
#
########################################################################################################################


############################################################
# FUNCTION db_reporthead_update(p_rec_reporthead)
#
#
############################################################
FUNCTION db_reporthead_update(p_ui_mode,p_pk_report_code,p_rec_reporthead)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_pk_report_code LIKE reporthead.report_code
	DEFINE p_rec_reporthead RECORD LIKE reporthead.*
	DEFINE l_ui_mode SMALLINT
	DEFINE ret INT
	DEFINE msgStr STRING
	
	IF p_ui_mode = UI_ON THEN
		LET l_ui_mode = UI_PK
	END IF

	IF p_pk_report_code IS NULL OR p_rec_reporthead.report_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET msgStr = "Product Adjustment Types code can not be empty ! (original Report Code=",trim(p_pk_report_code), " / new Report Code=", trim(p_rec_reporthead.report_code), ")"  
			ERROR msgStr
		END IF
		RETURN -1
	END IF
# Needs doing !!!!!!!!!! 	
#	IF db_XXXXXXXX_get_reporthead_count(p_pk_report_code) AND (p_pk_report_code <> p_rec_reporthead.report_code) THEN #PK report_code can only be changed if it's not used already
#		IF p_ui_mode > 0 THEN
#			ERROR "Can not change Product Adjustment Types ! It is already used in a configuration"
#		END IF
#		LET ret =  -1
#	ELSE
		
			SQL
				UPDATE reporthead
				SET * = $p_rec_reporthead.*
				WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code					
				AND report_code = $p_pk_report_code
			END SQL
			LET ret = status
		
#	END IF

	IF p_ui_mode != UI_OFF THEN #display MESSAGE if ui is enabled
		IF ret < 0 THEN   		
			LET msgStr = "Coud not modify Product Adjustment Types record ! /nOriginal Report", trim(p_pk_report_code), "New reporthead/Part ", trim(p_rec_reporthead.report_code),  "\nDatabase Error ", trim(ret)                                                                                        
			#ERROR msgStr 
			CALL fgl_winmessage("Error when trying to modify/update Product Adjustment Types record",msgStr,"error")
		ELSE
			LET msgStr = "Product Adjustment Typest record ", trim(p_rec_reporthead.report_code), " updated successfully !"   
			MESSAGE msgStr
		END IF                                           	
	END IF	
	
	RETURN ret
END FUNCTION        

   
############################################################
# FUNCTION db_reporthead_insert(p_rec_reporthead)
#
#
############################################################
FUNCTION db_reporthead_insert(p_ui_mode,p_rec_reporthead)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_rec_reporthead RECORD LIKE reporthead.*
	DEFINE ret INT
	DEFINE l_ui_mode SMALLINT
	DEFINE msgStr STRING	
	
	IF p_ui_mode = UI_ON THEN
		LET l_ui_mode = UI_PK
	END IF

	IF p_rec_reporthead.report_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET msgStr = "Product Adjustment Types code can not be empty ! (Report=", trim(p_rec_reporthead.report_code), ")"  
			ERROR msgStr
		END IF
		RETURN -1
	END IF

	LET p_rec_reporthead.cmpy_code = glob_rec_kandoouser.cmpy_code
	
	IF db_reporthead_pk_exists(UI_PK,NULL,p_rec_reporthead.report_code) THEN
		LET ret = -1
	ELSE
		
			INSERT INTO reporthead
	    VALUES(p_rec_reporthead.*)
	    LET ret = status
		
	END IF

	IF p_ui_mode != UI_OFF THEN #display MESSAGE if ui is enabled
		IF ret < 0 THEN   		
			LET msgStr = "Coud not create Product Adjustment Types record ", trim(p_rec_reporthead.report_code), " !\nDatabase Error ", trim(ret)                                                                                        
			#ERROR msgStr 
			CALL fgl_winmessage("Error when trying to create/insert Product Adjustment Types record",msgStr,"error")
		ELSE
			LET msgStr = "PProduct Adjustment Types record ", trim(p_rec_reporthead.report_code), " created successfully !"   
			MESSAGE msgStr
		END IF                                           	
	END IF
	
	RETURN ret
END FUNCTION


############################################################
# 
# FUNCTION db_reporthead_delete(p_report_code)
#
#
############################################################
FUNCTION db_reporthead_delete(p_ui_mode,p_confirm,p_report_code)
	DEFINE p_ui_mode SMALLINT #hide or show error/warning messages
	DEFINE p_confirm BOOLEAN #is operator requested to confirm this operation / independent of ui mode	
	DEFINE p_report_code LIKE reporthead.report_code
	DEFINE l_msgresp LIKE language.yes_flag	
	DEFINE ret SMALLINT	
	DEFINE msgStr STRING

	IF p_confirm = UI_CONFIRM_ON THEN
		LET msgStr = "Delete Product Adjustment Types configuration ", trim(p_report_code), " ?"
		IF NOT promptTF("Delete Report",msgStr,TRUE) THEN
			RETURN -2
		END IF
	END IF
	
	IF p_report_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET msgStr = "Product Adjustment Types code can not be empty ! (Report=", trim(p_report_code), ")"  
			ERROR msgStr
		END IF
		RETURN -1
	END IF
# Needs doing !!!!!!!!!! 
#	IF db_XXXXX_get_reporthead_count(p_report_code) THEN #PK report_code can only be deleted if it's not used already
#		IF p_ui_mode != UI_OFF THEN
#			LET msgStr = "Can not delete Product/Part ! ", trim(p_report_code), " It is already used in a bank configuration"
#			CALL fgl_winmessage("Can not delete Report ! ",msgStr,"error")
#		END IF
#		LET ret =  -1
#	ELSE
		
			SQL
				DELETE FROM reporthead
				WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code					
				AND report_code = $p_report_code
			END SQL
			LET ret = status
		
			
#	END IF
	
	IF p_ui_mode != UI_OFF THEN #display MESSAGE if ui is enabled
		IF ret < 0 THEN   		
			LET msgStr = "Could not delete Product Adjustment Types record ", trim(p_report_code), " !\nDatabase Error ", trim(ret)                                                                                        
			#ERROR msgStr 
			CALL fgl_winmessage("Error when trying to delete",msgStr,"error")
		ELSE
			LET msgStr = "Product Adjustment Types record ", trim(p_report_code), " deleted !"   
			MESSAGE msgStr
		END IF                                           	
	END IF		             

	RETURN ret	
		  
END FUNCTION
	

############################################################
# 
# FUNCTION db_reporthead_delete(p_report_code)
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
FUNCTION db_reporthead_rec_validation(p_ui_mode,p_op_mode,p_rec_reporthead)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_op_mode SMALLINT
	DEFINE p_rec_reporthead RECORD LIKE reporthead.*
	DEFINE l_ret SMALLINT
	DEFINE l_msgStr STRING
	DISPLAY "p_ui_mode=", p_ui_mode
	DISPLAY "p_op_mode=", p_op_mode
	CASE p_op_mode
		WHEN MODE_INSERT
			#report_code
			LET l_msgStr = "Can not create record. TAP Code already exists"  
			IF db_reporthead_pk_exists(UI_PK,p_op_mode,p_rec_reporthead.report_code) THEN
				RETURN -1 #PK Already exists
			END IF		

			#desc_text
			IF p_rec_reporthead.desc_text IS NULL THEN
				LET l_msgStr =  "Can not create Report record with empty description text - report_code: ", trim(p_rec_reporthead.report_code)
				IF p_ui_mode > 0 THEN
					ERROR l_msgStr
				END IF				
				RETURN -2
			END IF

			#column_num
			IF NOT db_coa_pk_exists(UI_FK,p_op_mode,p_rec_reporthead.column_num) THEN
				LET l_msgStr =  "Can not create Report record with invalid COA Code: ", trim(p_rec_reporthead.column_num)
				IF p_ui_mode > 0 THEN
					ERROR l_msgStr
				END IF
				RETURN -3
			END IF
				
		WHEN MODE_UPDATE
			#report_code
			IF NOT db_reporthead_pk_exists(UI_PK,p_op_mode,p_rec_reporthead.report_code) THEN
				LET l_msgStr = "Can not update record. TAP Code does not exist!"  			
				RETURN -1 #PK NOT FOUND
			END IF			

			#desc_text
			IF p_rec_reporthead.desc_text IS NULL THEN
				LET l_msgStr =  "Can not update Report record with empty description text - report_code: ", trim(p_rec_reporthead.report_code)
				IF p_ui_mode > 0 THEN
					ERROR l_msgStr
				END IF				
				RETURN -2
			END IF

			#column_num
			IF NOT db_coa_pk_exists(UI_FK,p_op_mode,p_rec_reporthead.column_num) THEN
				LET l_msgStr =  "Can not update Report record with invalid GL-COA Code: ", trim(p_rec_reporthead.column_num)
				IF p_ui_mode > 0 THEN
					ERROR l_msgStr
				END IF
				RETURN -3
			END IF
							
		WHEN MODE_DELETE
			#report_code
			IF db_reporthead_pk_exists(UI_PK,p_op_mode,p_rec_reporthead.report_code) THEN
				LET l_msgStr =  "Can not delete Report record which does not exist - report_code: ", trim(p_rec_reporthead.report_code)
				IF p_ui_mode > 0 THEN
					ERROR l_msgStr
				END IF
				RETURN -1 #PK NOT FOUND
			END IF			
	
	
	END CASE

	RETURN TRUE
	
	
END FUNCTION	
	
