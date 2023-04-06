########################################################################################################################
# TABLE creditdetl
#
# 3 Column PK cmpy, num, line_num
#
# cmpy_code	nchar	2			null  documentation of cmpy_code
# cred_num	integer	10			null Number identifying a credit note
# line_num	smallint	5			null documentation of line_num
########################################################################################################################

##########################################################
# GLOBAL Scope Variables
##########################################################
GLOBALS "../common/glob_GLOBALS.4gl"

############################################################
# FUNCTION db_creditdetl_get_count(p_cred_num)
#
# Return total number of rows in creditdetl 
############################################################
FUNCTION db_creditdetl_get_count(p_cred_num)
	DEFINE p_cred_num LIKE creditdetl.cred_num
	DEFINE l_ret INT

	SELECT count(*) 
	INTO l_ret 
	FROM creditdetl 
	WHERE creditdetl.cmpy_code = glob_rec_kandoouser.cmpy_code
	AND creditdetl.cred_num = p_cred_num		
			
	RETURN l_ret
END FUNCTION
############################################################
# END FUNCTION db_creditdetl_get_count(p_cred_num)
############################################################

				
############################################################
# FUNCTION db_creditdetl_pk_exists(p_ui,p_cred_num,p_line_num)
#
# Validate PK - Unique
############################################################
#	CONSTANT UI_OFF SMALLINT = 0
#	CONSTANT UI_ON SMALLINT = 1
#	CONSTANT UI_FK SMALLINT = 2
#	CONSTANT UI_PK SMALLINT = 3
############################################################
FUNCTION db_creditdetl_pk_exists(p_ui,p_cred_num,p_line_num)
	DEFINE p_ui SMALLINT
	DEFINE p_line_num LIKE creditdetl.line_num
	DEFINE p_cred_num LIKE creditdetl.cred_num
	DEFINE l_ret BOOLEAN
	DEFINE l_recCount INT

	IF p_line_num IS NULL THEN
		IF p_ui != UI_OFF THEN
			ERROR "creditdetl Code can not be empty"	
		END IF
		RETURN FALSE
	END IF

	IF p_cred_num IS NULL THEN
		IF p_ui != UI_OFF THEN
			ERROR "creditdetl cred_num can not be empty"
		END IF
		RETURN FALSE
	END IF

	SELECT count(*) 
	INTO l_recCount 
	FROM creditdetl
	WHERE creditdetl.cmpy_code = glob_rec_kandoouser.cmpy_code			
	AND creditdetl.line_num = p_line_num
	AND creditdetl.cred_num = p_cred_num
		
	IF l_recCount <> 0 THEN
		LET l_ret = TRUE	
		IF p_ui = UI_ON THEN
			MESSAGE "creditdetl Code with cred_num exists! (", trim(p_line_num), ")"
		END IF
		IF p_ui = UI_PK THEN
			MESSAGE "creditdetl Code with cred_num already exists! (", trim(p_line_num), ")"
		END IF
	ELSE
		LET l_ret = FALSE	
		IF p_ui = UI_FK THEN
			MESSAGE "creditdetl Code with cred_num does not exists! (", trim(p_line_num), ")"
		END IF
	END IF
	
	RETURN l_ret
END FUNCTION
############################################################
# END FUNCTION db_creditdetl_pk_exists(p_ui,p_cred_num,p_line_num)
############################################################




############################################################
# FUNCTION db_creditdetl_get_rec(p_ui_mode,p_cred_num,p_line_num)
# RETURN l_rec_creditdetl.*	
# Get creditdetl record
############################################################
FUNCTION db_creditdetl_get_rec(p_ui_mode,p_cred_num,p_line_num)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_cred_num LIKE creditdetl.cred_num
	DEFINE p_line_num LIKE creditdetl.line_num
	DEFINE l_rec_creditdetl RECORD LIKE creditdetl.*

	IF p_cred_num IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Can not retrieve record with empty creditdetl cred_num code"
		END IF
		RETURN NULL
	END IF

	IF p_line_num IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Can not retrieve record with empty creditdetl code"
		END IF
		RETURN NULL
	END IF

  SELECT *
	INTO l_rec_creditdetl.*
	FROM creditdetl
	WHERE creditdetl.cmpy_code = glob_rec_kandoouser.cmpy_code			
	AND creditdetl.cred_num = p_cred_num
	AND creditdetl.line_num = p_line_num
	
	IF sqlca.sqlcode != 0 THEN  		
   	IF p_ui_mode != UI_OFF THEN
      ERROR "creditdetl with Code ", trim(p_cred_num), "/", trim(p_line_num), " NOT found"
		END IF	  
		INITIALIZE l_rec_creditdetl.* TO NULL                                                                                      
	ELSE		                                                                                                                    
		#		                                                                                                
	END IF	         

	RETURN l_rec_creditdetl.*		                                                                                                
END FUNCTION	
############################################################
# END FUNCTION db_creditdetl_get_rec(p_ui_mode,p_cred_num,p_line_num)
############################################################


############################################################
# FUNCTION db_creditdetl_get_cust_code(p_ui_mode,p_cred_num,p_line_num)
# RETURN l_ret_cust_code 
#
# Get description text of creditdetl record
############################################################
FUNCTION db_creditdetl_get_cust_code(p_ui_mode,p_cred_num,p_line_num)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_line_num LIKE creditdetl.line_num
	DEFINE p_cred_num LIKE creditdetl.cred_num
	DEFINE l_ret_cust_code LIKE creditdetl.cust_code

	IF p_cred_num IS NULL THEN
		IF p_ui_mode != UI_OFF THEN	
			ERROR "creditdetl cred_num can NOT be empty"
		END IF
			RETURN NULL
	END IF

	IF p_line_num IS NULL THEN
		IF p_ui_mode != UI_OFF THEN	
			ERROR "creditdetl Code can NOT be empty"
		END IF
			RETURN NULL
	END IF

	SELECT cust_code 
	INTO l_ret_cust_code 
	FROM creditdetl 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code				
	AND creditdetl.line_num = p_line_num
	AND creditdetl.cred_num = p_cred_num

	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "creditdetl Description with Code ",trim(p_line_num)," and cred_num ", trim(p_cred_num),  " NOT found"
		END IF			
		LET l_ret_cust_code = NULL
	ELSE
		#
	END IF	
	
	RETURN l_ret_cust_code
END FUNCTION
############################################################
# END FUNCTION db_creditdetl_get_cust_code(p_ui_mode,p_cred_num,p_line_num)
############################################################


########################################################################################################################
# 
# Get Array record data from DB
#
########################################################################################################################
{
############################################################
# FUNCTION db_creditdetl_get_arr_rec(p_query_text)
#
#
############################################################
FUNCTION db_creditdetl_get_arr_rec(p_query_type,p_query_or_where_text)
	DEFINE p_query_type SMALLINT
	DEFINE p_query_or_where_text VARCHAR(500)
	DEFINE l_query_text VARCHAR(500)
	DEFINE l_where_text VARCHAR(500)
	DEFINE l_arr_rec_creditdetl DYNAMIC ARRAY OF t_rec_creditdetl_i_d_t	
#	DEFINE l_rec_creditdetl t_rec_creditdetl_i_d_t
	DEFINE l_idx SMALLINT
	
	#p_query_text is optional
	CASE p_query_type
		WHEN FILTER_QUERY_OFF
			LET l_query_text = 
				"SELECT line_num,desc_text,cred_num FROM creditdetl ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ", 
				"ORDER BY creditdetl.cred_num, creditdetl.line_num" 	


#		WHEN FILTER_QUERY_ON
#			LET l_query_text = p_query_or_where_text

		WHEN FILTER_QUERY_WHERE
			LET l_where_text = p_query_or_where_text
			LET l_query_text = 
				"SELECT line_num,desc_text,cred_num FROM creditdetl ",
				"WHERE ", l_where_text clipped," ",
				"AND cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ", 				
				"ORDER BY creditdetl.cred_num, creditdetl.line_num" 	

		WHEN FILTER_QUERY_SELECT
			LET l_query_text = p_query_or_where_text		
		
		OTHERWISE
			LET l_query_text = 
				"SELECT line_num,desc_text,cred_num FROM creditdetl ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ", 
				"ORDER BY creditdetl.cred_num, creditdetl.line_num"
				 				
	END CASE

	PREPARE s_creditdetl FROM l_query_text
	DECLARE c_creditdetl CURSOR FOR s_creditdetl


	LET l_idx = 1
	FOREACH c_creditdetl INTO l_arr_rec_creditdetl[l_idx].*
		LET l_idx = l_idx + 1
	END FOREACH

	IF sqlca.sqlcode < 0 THEN   	
		LET l_arr_rec_creditdetl = NULL	                                                                                        
	ELSE		                                                                                                                    
		#		                                                                                                
	END IF	         

	RETURN l_arr_rec_creditdetl		                                                                                                
END FUNCTION
############################################################
# END FUNCTION db_creditdetl_get_arr_rec(p_query_text)
############################################################


############################################################
# FUNCTION db_creditdetl_get_arr_rec_i_d(p_query_type,p_query_or_where_text)
#
#
############################################################
FUNCTION db_creditdetl_get_arr_rec_i_d(p_query_type,p_query_or_where_text)
	DEFINE p_query_type SMALLINT
	DEFINE p_query_or_where_text VARCHAR(500)
	DEFINE l_query_text VARCHAR(500)
	DEFINE l_where_text VARCHAR(500)
	DEFINE l_arr_rec_creditdetl DYNAMIC ARRAY OF t_rec_creditdetl_i_d		
	DEFINE l_rec_creditdetl RECORD LIKE creditdetl.*
	DEFINE l_idx SMALLINT
	
	IF p_query_or_where_text IS NULL THEN #save guard
		LET p_query_or_where_text = " 1=1 "
	END IF	
	
	#p_query_text is optional
	CASE p_query_type
		WHEN FILTER_QUERY_OFF
			LET l_query_text = 
				"SELECT line_num, desc_text FROM creditdetl ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ", 
				"ORDER BY creditdetl.line_num" 	


#		WHEN FILTER_QUERY_ON
#			LET l_query_text = p_query_or_where_text

		WHEN FILTER_QUERY_WHERE
			LET l_where_text = p_query_or_where_text
			LET l_query_text = 
				"SELECT line_num, desc_text FROM creditdetl ",
				"WHERE ", l_where_text clipped," ",
				"AND cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ", 				
				"ORDER BY creditdetl.line_num" 	

		WHEN FILTER_QUERY_SELECT
			LET l_query_text = p_query_or_where_text		
		
		OTHERWISE
			LET l_query_text = 
				"SELECT line_num, desc_text FROM creditdetl ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ", 
				"ORDER BY creditdetl.line_num"
				 				
	END CASE

	PREPARE s2_creditdetl FROM l_query_text
	DECLARE c2_creditdetl CURSOR FOR s2_creditdetl


	LET l_idx = 1
	FOREACH c2_creditdetl INTO l_arr_rec_creditdetl[l_idx].*
		LET l_idx = l_idx + 1
	END FOREACH

	IF sqlca.sqlcode < 0 THEN   	
		LET l_arr_rec_creditdetl = NULL	                                                                                        
	ELSE		                                                                                                                    
		#		                                                                                                
	END IF	         

	RETURN l_arr_rec_creditdetl		                                                                                                
END FUNCTION
############################################################
# END FUNCTION db_creditdetl_get_arr_rec_i_d(p_query_type,p_query_or_where_text)
############################################################
}

########################################################################################################################
# 
# UPDATE INSERT DELETE row from DB
#
########################################################################################################################


############################################################
# FUNCTION db_creditdetl_update(p_rec_creditdetl)
#
#
############################################################
FUNCTION db_creditdetl_update(p_ui_mode,p_pk_cred_num,p_pk_line_num,p_rec_creditdetl)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_pk_cred_num LIKE creditdetl.cred_num
	DEFINE p_pk_line_num LIKE creditdetl.line_num
	DEFINE p_rec_creditdetl RECORD LIKE creditdetl.*
	DEFINE l_ui_mode SMALLINT
	DEFINE l_ret INT
	DEFINE l_msg STRING
	
	IF p_ui_mode = UI_ON THEN
		LET l_ui_mode = UI_PK
	END IF

	IF p_pk_cred_num IS NULL OR p_rec_creditdetl.cred_num IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET l_msg = "creditdetl cred_num code can not be empty ! (original cred_num=",trim(p_pk_cred_num), " / new cred_num=", trim(p_rec_creditdetl.cred_num), ")"  
			ERROR l_msg
		END IF
		RETURN -1
	END IF

	IF p_pk_line_num IS NULL OR p_rec_creditdetl.line_num IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET l_msg = "creditdetl code can not be empty ! (original creditdetl=",trim(p_pk_line_num), " / new creditdetl=", trim(p_rec_creditdetl.line_num), ")"  
			ERROR l_msg
		END IF
		RETURN -2
	END IF
	
#	IF db_product_get_class_count(p_pk_line_num) AND (p_pk_line_num <> p_rec_creditdetl.line_num) THEN #PK line_num can only be changed if it's not used already
#		IF p_ui_mode > 0 THEN
#			ERROR "Can not change creditdetl ! It is already used in a bank configuration"
#		END IF
#		LET l_ret =  -1
#	ELSE
		
	UPDATE creditdetl
	SET * = p_rec_creditdetl.*
	WHERE creditdetl.cmpy_code = glob_rec_kandoouser.cmpy_code				
	AND creditdetl.cred_num = p_pk_cred_num
	AND creditdetl.line_num = p_pk_line_num

	LET l_ret = status
		
#	END IF

	IF p_ui_mode != UI_OFF THEN #display MESSAGE if ui is enabled
		IF l_ret < 0 THEN   		
			LET l_msg = "Coud not modify creditdetl record ! /nOriginal cred_num/creditdetl", trim(p_pk_cred_num), "/", trim(p_pk_line_num), "New cred_num/creditdetl ", trim(p_rec_creditdetl.cred_num), "/" , trim(p_rec_creditdetl.line_num),  "\nDatabase Error ", trim(l_ret)                                                                                        
			#ERROR l_msg 
			CALL fgl_winmessage("Error when trying to modify/update creditdetl record",l_msg,"error")
		ELSE
			LET l_msg = "creditdetl record ", trim(p_rec_creditdetl.line_num), "/", trim(p_rec_creditdetl.cred_num),  " updated successfully !"   
			MESSAGE l_msg
		END IF                                           	
	END IF	
	
	RETURN l_ret
END FUNCTION        
############################################################
# END FUNCTION db_creditdetl_update(p_rec_creditdetl)
############################################################

   
############################################################
# FUNCTION db_creditdetl_insert(p_rec_creditdetl)
#
#
############################################################
FUNCTION db_creditdetl_insert(p_ui_mode,p_rec_creditdetl)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_rec_creditdetl RECORD LIKE creditdetl.*
	DEFINE l_ret INT
	DEFINE l_ui_mode SMALLINT
	DEFINE l_msg STRING	
	
	IF p_ui_mode = UI_ON THEN
		LET l_ui_mode = UI_PK
	END IF

	IF p_rec_creditdetl.cred_num IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET l_msg = "creditdetl cred_num can not be empty ! (creditdetl cred_num=", trim(p_rec_creditdetl.cred_num), ")"  
			ERROR l_msg
		END IF
		RETURN -1
	END IF
	
	IF p_rec_creditdetl.line_num IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET l_msg = "creditdetl code can not be empty ! (creditdetl=", trim(p_rec_creditdetl.line_num), ")"  
			ERROR l_msg
		END IF
		RETURN -2
	END IF
	
	IF db_creditdetl_pk_exists(UI_PK,p_rec_creditdetl.cred_num,p_rec_creditdetl.line_num) THEN
		LET l_ret = -1
	ELSE
		
	INSERT INTO creditdetl
  VALUES(p_rec_creditdetl.*)
  
  LET l_ret = status
		
	END IF

	IF p_ui_mode != UI_OFF THEN #display MESSAGE if ui is enabled
		IF l_ret < 0 THEN   		
			LET l_msg = "Coud not create creditdetl record ", trim(p_rec_creditdetl.line_num),"/", trim(p_rec_creditdetl.cred_num), " !\nDatabase Error ", trim(l_ret)                                                                                        
			#ERROR l_msg 
			CALL fgl_winmessage("Error when trying to create/insert creditdetl record",l_msg,"error")
		ELSE
			LET l_msg = "creditdetl record ", trim(p_rec_creditdetl.line_num),"/", trim(p_rec_creditdetl.cred_num), " created successfully !"   
			MESSAGE l_msg
		END IF                                           	
	END IF
	
	RETURN l_ret
END FUNCTION
############################################################
# END FUNCTION db_creditdetl_insert(p_rec_creditdetl)
############################################################


############################################################
# FUNCTION db_creditdetl_delete(p_line_num)
#
#
############################################################
FUNCTION db_creditdetl_delete(p_ui_mode,p_confirm,p_cred_num,p_line_num)
	DEFINE p_ui_mode SMALLINT #hide or show error/warning messages
	DEFINE p_confirm BOOLEAN #is operator requested to confirm this operation / independent of ui mode	
	DEFINE p_cred_num LIKE creditdetl.cred_num
	DEFINE p_line_num LIKE creditdetl.line_num
	DEFINE l_ret SMALLINT	
	DEFINE l_msg STRING

	IF p_confirm = UI_CONFIRM_ON THEN
		LET l_msg = "Delete creditdetl configuration ", trim(p_cred_num), "/", trim(p_line_num), " ?"
		IF NOT promptTF("Delete creditdetl",l_msg,TRUE) THEN
			RETURN -10
		END IF
	END IF
	
	IF p_cred_num IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET l_msg = "creditdetl cred_num code can not be empty ! (cred_num/creditdetl=", trim(p_cred_num), "/", trim(p_line_num), ")"  
			ERROR l_msg
		END IF
		RETURN -1
	END IF
	
	IF p_line_num IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET l_msg = "creditdetl code can not be empty ! (creditdetl=", trim(p_line_num), ")"  
			ERROR l_msg
		END IF
		RETURN -2
	END IF

#	IF db_bank_get_class_count(p_line_num) THEN #PK line_num can only be deleted if it's not used already
#		IF p_ui_mode != UI_OFF THEN
#			LET l_msg = "Can not delete creditdetl ! ", trim(p_line_num), " It is already used in a bank configuration"
#			CALL fgl_winmessage("Can not delete creditdetl ! ",l_msg,"error")
#		END IF
#		LET l_ret =  -1
#	ELSE
		
	DELETE FROM creditdetl
	WHERE creditdetl.cmpy_code = glob_rec_kandoouser.cmpy_code
	AND creditdetl.cred_num = p_cred_num
	AND creditdetl.line_num = p_line_num

	LET l_ret = status
		
			
#	END IF
	
	IF p_ui_mode != UI_OFF THEN #display MESSAGE if ui is enabled
		IF l_ret < 0 THEN   		
			LET l_msg = "Coud not delete cred_num/creditdetl=", trim(p_cred_num), "/", trim(p_line_num), " !\nDatabase Error ", trim(l_ret)                                                                                        
			#ERROR l_msg 
			CALL fgl_winmessage("Error when trying to delete",l_msg,"error")
		ELSE
			LET l_msg = "creditdetl record ", trim(p_cred_num), "/", trim(p_line_num), " deleted !"   
			MESSAGE l_msg
		END IF                                           	
	END IF		             

	RETURN l_ret	
		  
END FUNCTION
############################################################
# END FUNCTION db_creditdetl_delete(p_line_num)
############################################################