##############################################################################################
#TABLE invoicehead
##############################################################################################

##########################################################
# GLOBAL Scope Variables
##########################################################
GLOBALS "../common/glob_GLOBALS.4gl"

			
############################################################
# FUNCTION db_invoicehead_pk_exists(p_ui,p_inv_num)
#
# Validate PK - Unique
############################################################
#	CONSTANT UI_OFF SMALLINT = 0
#	CONSTANT UI_ON SMALLINT = 1
#	CONSTANT UI_FK SMALLINT = 2
#	CONSTANT UI_PK SMALLINT = 3
############################################################
FUNCTION db_invoicehead_pk_exists(p_ui_mode,p_op_mode,p_inv_num)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_op_mode SMALLINT	
	DEFINE p_inv_num LIKE invoicehead.inv_num
	DEFINE l_ret BOOLEAN
	DEFINE l_recCount INT
	DEFINE msgStr STRING

	IF p_inv_num IS NULL THEN
		IF p_ui_mode >= UI_ON THEN
			ERROR "Invoice Code can not be empty"
			#ERROR kandoomsg2("G",9178,"")	#9178 Bank/State/Branchs must NOT be NULL
		END IF
		RETURN FALSE
	END IF

	SELECT count(*) 
	INTO l_recCount 
	FROM invoicehead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code				
	AND invoicehead.inv_num = p_inv_num  
		
	IF l_recCount > 0 THEN
		LET l_ret = TRUE	
		CASE p_op_mode
			WHEN MODE_INSERT
				CASE p_ui_mode
					WHEN UI_PK
						ERROR "Invoice Code already exists! (", trim(p_inv_num), ")"
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
						ERROR "Invoice Code does not exist! (", trim(p_inv_num), ")"
					OTHERWISE
						#No MESSAGE
				END CASE
			
			WHEN MODE_DELETE
				CASE p_ui_mode
					WHEN UI_PK
						#No MESSAGE
					WHEN UI_FK
						ERROR "Invoice Code does not exist! (", trim(p_inv_num), ")"
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
						ERROR "Invoice Code does not exist! (", trim(p_inv_num), ")"
					OTHERWISE
						#No MESSAGE
				END CASE

			WHEN MODE_UPDATE
				CASE p_ui_mode
					WHEN UI_PK
						ERROR "Invoice Code does not exist! (", trim(p_inv_num), ")"
					WHEN UI_FK
						#No MESSAGE
					OTHERWISE
						#No MESSAGE
				END CASE

			WHEN MODE_DELETE
				CASE p_ui_mode
					WHEN UI_PK
						ERROR "Invoice Code does not exist! (", trim(p_inv_num), ")"
					WHEN UI_FK
						#No MESSAGE
					OTHERWISE
						#No MESSAGE
				END CASE

			OTHERWISE
				CASE p_ui_mode
					WHEN UI_PK
						ERROR "Invoice Code does not exist! (", trim(p_inv_num), ")"
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
# END FUNCTION db_invoicehead_pk_exists(p_ui,p_inv_num)
############################################################


############################################################
# FUNCTION db_invoicehead_get_count()
#
# Return total number of rows in invoicehead 
############################################################
FUNCTION db_invoicehead_get_count()
	DEFINE l_ret INT

	SELECT count(*) 
	INTO l_ret 
	FROM invoicehead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code				
			
	RETURN l_ret
END FUNCTION
############################################################
# FUNCTION db_invoicehead_get_count()
############################################################


############################################################
# FUNCTION db_invoicehead_get_cust_code_count_not_posted(p_cust_code)
#
# Return total number of rows in invoicehead 
############################################################
FUNCTION db_invoicehead_get_cust_code_count_not_posted(p_cust_code)
	DEFINE p_cust_code LIKE invoicehead.cust_code
	DEFINE l_ret INT

	SELECT count(*) 
	INTO l_ret 
	FROM invoicehead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code				
	AND invoicehead.cust_code = p_cust_code
	AND invoicehead.posted_flag = 'N'			
	RETURN l_ret
END FUNCTION
############################################################
# END FUNCTION db_invoicehead_get_cust_code_count_not_posted(p_cust_code)
############################################################

############################################################
# FUNCTION db_invoicehead_get_cust_code_count_not_paid(p_cust_code)
#
# Return total number of rows in invoicehead 
############################################################
FUNCTION db_invoicehead_get_cust_code_count_not_paid(p_cust_code)
	DEFINE p_cust_code LIKE invoicehead.cust_code
	DEFINE l_ret INT

	SELECT count(*) 
	INTO l_ret 
	FROM invoicehead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code				
	AND invoicehead.cust_code = p_cust_code
	AND invoicehead.paid_amt = 0			
	RETURN l_ret
END FUNCTION
############################################################
# END FUNCTION db_invoicehead_get_cust_code_count_not_paid(p_cust_code)
############################################################
############################################################
# FUNCTION db_invoicehead_get_cust_code_count(p_cust_code)
#
# Return total number of rows in invoicehead 
############################################################
FUNCTION db_invoicehead_get_cust_code_count(p_cust_code)
	DEFINE p_cust_code LIKE invoicehead.cust_code
	DEFINE l_ret INT

	SELECT count(*) 
	INTO l_ret 
	FROM invoicehead 
	WHERE invoicehead.cmpy_code = glob_rec_kandoouser.cmpy_code				
	AND invoicehead.cust_code = p_cust_code
			
	RETURN l_ret
END FUNCTION
############################################################
# FUNCTION db_invoicehead_get_cust_code_count(p_cust_code)
############################################################


############################################################
# FUNCTION db_invoicehead_get_org_cust_code_count(p_org_cust_code)
#
# Return total number of rows in invoicehead 
############################################################
FUNCTION db_invoicehead_get_org_cust_code_count(p_org_cust_code)
	DEFINE p_org_cust_code LIKE invoicehead.org_cust_code
	DEFINE l_ret INT

	SELECT count(*) 
	INTO l_ret 
	FROM invoicehead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code				
	AND invoicehead.org_cust_code = p_org_cust_code
			
	RETURN l_ret
END FUNCTION
############################################################
# FUNCTION db_invoicehead_get_org_cust_code_count(p_org_cust_code)
############################################################

############################################################
# FUNCTION db_invoicehead_get_cust_org_cust_code_count(p_cust_code,p_org_cust_code)
#
# Return total number of rows in invoicehead 
############################################################
FUNCTION db_invoicehead_get_cust_org_cust_code_count(p_cust_code,p_org_cust_code)
	DEFINE p_cust_code LIKE invoicehead.cust_code
	DEFINE p_org_cust_code LIKE invoicehead.org_cust_code
	DEFINE l_ret INT

	SELECT count(*) 
	INTO l_ret 
	FROM invoicehead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code				
	AND (invoicehead.org_cust_code = p_org_cust_code)
		OR (invoicehead.cust_code = p_cust_code)
			
	RETURN l_ret
END FUNCTION
############################################################
# END FUNCTION db_invoicehead_get_cust_org_cust_code_count(p_cust_code,p_org_cust_code)
############################################################

############################################################
# FUNCTION db_invoicehead_get_rec(p_ui_mode,p_inv_num)
# RETURN l_rec_invoicehead.*
# Get invoicehead/Part record
############################################################
FUNCTION db_invoicehead_get_rec(p_ui_mode,p_inv_num)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_inv_num LIKE invoicehead.inv_num
	DEFINE l_rec_invoicehead RECORD LIKE invoicehead.*

	IF p_inv_num IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Can not retrieve record with empty Invoice Code"
		END IF
		RETURN NULL
	END IF
	
	SELECT *
	INTO l_rec_invoicehead.*
	FROM invoicehead
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code		        
	AND inv_num = p_inv_num
	
	IF sqlca.sqlcode != 0 THEN   		  
		INITIALIZE l_rec_invoicehead.* TO NULL                                                                                      
	ELSE		                                                                                                                    
		#		                                                                                                
	END IF	         

	RETURN l_rec_invoicehead.*		                                                                                                
END FUNCTION	
############################################################
# END FUNCTION db_invoicehead_get_rec(p_ui_mode,p_inv_num)
############################################################


############################################################
# FUNCTION db_invoicehead_get_name_text(p_ui_mode,p_inv_num)
# RETURN l_ret_name_text 
#
# Get description text of invoicehead record
############################################################
FUNCTION db_invoicehead_get_name_text(p_ui_mode,p_inv_num)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_inv_num LIKE invoicehead.inv_num
	DEFINE l_ret_name_text LIKE invoicehead.name_text

	IF p_inv_num IS NULL THEN
		IF p_ui_mode != UI_OFF THEN	
			ERROR "Invoice Code can NOT be empty"
		END IF
			RETURN NULL
	END IF

	SELECT name_text 
	INTO l_ret_name_text 
	FROM invoicehead
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code				 
	AND invoicehead.inv_num = p_inv_num  		
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Invoice Description with Code ",trim(p_inv_num),  "NOT found"
		END IF			
		LET l_ret_name_text = NULL
	ELSE
		#
	END IF	
	RETURN l_ret_name_text
END FUNCTION
############################################################
# FUNCTION db_invoicehead_get_name_text(p_ui_mode,p_inv_num)
############################################################


############################################################
# FUNCTION db_invoicehead_get_org_cust_code(p_ui_mode,p_inv_num)
# RETURN l_ret_name_text 
#
# Get description text of Product/Part record
############################################################
FUNCTION db_invoicehead_get_org_cust_code(p_ui_mode,p_inv_num)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_inv_num LIKE invoicehead.inv_num
	DEFINE l_ret_org_cust_code LIKE invoicehead.org_cust_code

	IF p_inv_num IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Invoice Code can NOT be empty"
		END IF
		RETURN NULL
	END IF

	SELECT org_cust_code 
	INTO l_ret_org_cust_code
	FROM invoicehead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code				
	AND invoicehead.inv_num = p_inv_num  		
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Cooperate Reference with Invoice Code ",trim(p_inv_num),  "NOT found"
		END IF
		LET l_ret_org_cust_code = NULL
	ELSE
		#	                                                                                                
	END IF	

	RETURN l_ret_org_cust_code	                                                                                                
END FUNCTION
############################################################
# END FUNCTION db_invoicehead_get_org_cust_code(p_ui_mode,p_inv_num)
############################################################


############################################################
# FUNCTION db_invoicehead_get_inv_num(p_ui_mode,p_inv_num)
# RETURN l_ret_name_text 
#
# Get description text of invoicehead/Part record
############################################################
FUNCTION db_invoicehead_get_inv_num(p_ui_mode,p_inv_num)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_inv_num LIKE invoicehead.inv_num
	DEFINE l_ret_inv_num LIKE invoicehead.inv_num

	IF p_inv_num IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Invoice Code can NOT be empty"
		END IF
		RETURN NULL
	END IF

	SELECT inv_num 
	INTO l_ret_inv_num
	FROM invoicehead
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code	
	AND invoicehead.inv_num = p_inv_num  		
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Invoice Code ",trim(p_inv_num),  "NOT found"
		END IF
		LET l_ret_inv_num = NULL
	ELSE
		#	                                                                                                
	END IF	

	RETURN l_ret_inv_num	                                                                                                
END FUNCTION
############################################################
# END FUNCTION db_invoicehead_get_inv_num(p_ui_mode,p_inv_num)
############################################################


############################################################
# FUNCTION db_invoicehead_get_purchase_code(p_ui_mode,p_inv_num)
# RETURN l_ret_name_text 
#
# Get Purchase Code (purchase_code) of invoicehead/Part record
############################################################
FUNCTION db_invoicehead_get_purchase_code(p_ui_mode,p_inv_num)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_inv_num LIKE invoicehead.inv_num
	DEFINE l_ret_purchase_code LIKE invoicehead.purchase_code

	IF p_inv_num IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Invoice Code can NOT be empty"
		END IF
		RETURN NULL
	END IF

	SELECT purchase_code 
	INTO l_ret_purchase_code
	FROM invoicehead
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code	
	AND invoicehead.inv_num = p_inv_num  		
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Invoice Code ",trim(p_inv_num),  "NOT found"
		END IF
		LET l_ret_purchase_code = NULL
	ELSE
		#	                                                                                                
	END IF	

	RETURN l_ret_purchase_code	                                                                                                
END FUNCTION
############################################################
# END FUNCTION db_invoicehead_get_purchase_code(p_ui_mode,p_inv_num)
############################################################


############################################################
# FUNCTION db_invoicehead_get_total_amt(p_ui_mode,p_inv_num)
# RETURN l_ret_name_text 
#
# Get Total Amount (total_amt) of invoicehead/Part record
############################################################
FUNCTION db_invoicehead_get_total_amt(p_ui_mode,p_inv_num)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_inv_num LIKE invoicehead.inv_num
	DEFINE l_ret_total_amt LIKE invoicehead.total_amt

	IF p_inv_num IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Invoice Code can NOT be empty"
		END IF
		RETURN NULL
	END IF

	
	SELECT total_amt 
		INTO l_ret_total_amt
		FROM invoicehead
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code	
		AND invoicehead.inv_num = p_inv_num  		
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Invoice Code ",trim(p_inv_num),  "NOT found"
		END IF
		LET l_ret_total_amt = NULL
	ELSE
		#	                                                                                                
	END IF	

	RETURN l_ret_total_amt	                                                                                                
END FUNCTION
############################################################
# END FUNCTION db_invoicehead_get_total_amt(p_ui_mode,p_inv_num)
############################################################


############################################################
# FUNCTION db_invoicehead_get_due_date(p_ui_mode,p_inv_num)
# RETURN l_ret_name_text 
#
# Get Total Amount (due_date) of invoicehead/Part record
############################################################
FUNCTION db_invoicehead_get_due_date(p_ui_mode,p_inv_num)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_inv_num LIKE invoicehead.inv_num
	DEFINE l_ret_due_date LIKE invoicehead.due_date

	IF p_inv_num IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Invoice Code can NOT be empty"
		END IF
		RETURN NULL
	END IF

	SELECT due_date 
	INTO l_ret_due_date
	FROM invoicehead
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code	
	AND invoicehead.inv_num = p_inv_num  		
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Invoice Code ",trim(p_inv_num),  "NOT found"
		END IF
		LET l_ret_due_date = NULL
	ELSE
		#	                                                                                                
	END IF	

	RETURN l_ret_due_date	                                                                                                
END FUNCTION
############################################################
# END FUNCTION db_invoicehead_get_due_date(p_ui_mode,p_inv_num)
############################################################


############################################################
# FUNCTION db_invoicehead_get_story_flag(p_ui_mode,p_inv_num)
# RETURN l_ret_name_text 
#
# Get Total Amount (story_flag) of invoicehead/Part record
############################################################
FUNCTION db_invoicehead_get_story_flag(p_ui_mode,p_inv_num)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_inv_num LIKE invoicehead.inv_num
	DEFINE l_ret_story_flag LIKE invoicehead.story_flag

	IF p_inv_num IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Invoice Code can NOT be empty"
		END IF
		RETURN NULL
	END IF
	
	SELECT story_flag 
	INTO l_ret_story_flag
	FROM invoicehead
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code	
	AND invoicehead.inv_num = p_inv_num  		
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Invoice Code ",trim(p_inv_num),  "NOT found"
		END IF
		LET l_ret_story_flag = NULL
	ELSE
		#	                                                                                                
	END IF	

	RETURN l_ret_story_flag	                                                                                                
END FUNCTION
############################################################
# END FUNCTION db_invoicehead_get_story_flag(p_ui_mode,p_inv_num)
############################################################


########################################################################################################################
# 
# Get Array record data from DB
#
########################################################################################################################

############################################################
# FUNCTION db_invoicehead_get_arr_rec(p_query_text)
#
#
############################################################
FUNCTION db_invoicehead_get_arr_rec(p_query_type,p_query_or_where_text)
	DEFINE p_query_type SMALLINT
	DEFINE p_query_or_where_text STRING
	DEFINE l_query_text STRING
	DEFINE l_where_text STRING
	DEFINE l_arr_rec_invoicehead DYNAMIC ARRAY OF RECORD LIKE invoicehead.*		
	DEFINE l_rec_invoicehead RECORD LIKE invoicehead.*
	DEFINE l_idx SMALLINT

	IF p_query_type = FILTER_QUERY_WHERE AND p_query_or_where_text IS NULL THEN
		LET p_query_or_where_text = " 1=1 "
	END IF
		
	#p_query_text is optional
	CASE p_query_type
		WHEN FILTER_QUERY_OFF
			LET l_query_text = 
				"SELECT * FROM invoicehead ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ",					
				"ORDER BY invoicehead.inv_num" 	

		WHEN FILTER_QUERY_WHERE
			LET l_where_text = p_query_or_where_text
			LET l_query_text = 
				"SELECT * FROM invoicehead ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ",					
				"AND ", l_where_text clipped," ",
				"ORDER BY invoicehead.inv_num" 	

		WHEN FILTER_QUERY_SELECT
			LET l_query_text = p_query_or_where_text		
		
		OTHERWISE
			LET l_query_text = 
				"SELECT * FROM invoicehead ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ",					
				"ORDER BY invoicehead.inv_num" 				
	END CASE

	PREPARE s_invoicehead FROM l_query_text
	DECLARE c_invoicehead CURSOR FOR s_invoicehead


	LET l_idx = 0
	FOREACH c_invoicehead INTO l_arr_rec_invoicehead[l_idx].*
      LET l_idx = l_idx + 1

	END FOREACH

	IF sqlca.sqlcode < 0 THEN   	
		LET l_arr_rec_invoicehead = NULL	                                                                                        
	ELSE		                                                                                                                    
		#		                                                                                                
	END IF	         

	RETURN l_arr_rec_invoicehead		                                                                                                
END FUNCTION
############################################################
# END FUNCTION db_invoicehead_get_arr_rec(p_query_text)
############################################################


########################################################################################################################
# 
# UPDATE INSERT DELETE row from DB
#
########################################################################################################################


############################################################
# FUNCTION db_invoicehead_update(p_rec_invoicehead)
#
#
############################################################
FUNCTION db_invoicehead_update(p_ui_mode,p_pk_inv_num,p_rec_invoicehead)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_pk_inv_num LIKE invoicehead.inv_num
	DEFINE p_rec_invoicehead RECORD LIKE invoicehead.*
	DEFINE l_ui_mode SMALLINT
	DEFINE l_ret INT
	DEFINE msgStr STRING
	
	IF p_ui_mode = UI_ON THEN
		LET l_ui_mode = UI_PK
	END IF

	IF p_pk_inv_num IS NULL OR p_rec_invoicehead.inv_num IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET msgStr = "Invoice code can not be empty ! (original Invoice Code=",trim(p_pk_inv_num), " / new Invoice Code=", trim(p_rec_invoicehead.inv_num), ")"  
			ERROR msgStr
		END IF
		RETURN -1
	END IF
# Needs doing !!!!!!!!!! 	
#	IF db_XXXXXXXX_get_invoicehead_count(p_pk_inv_num) AND (p_pk_inv_num <> p_rec_invoicehead.inv_num) THEN #PK inv_num can only be changed if it's not used already
#		IF p_ui_mode > 0 THEN
#			ERROR "Can not change Invoice ! It is already used in a configuration"
#		END IF
#		LET l_ret =  -1
#	ELSE

	UPDATE invoicehead
	SET * = p_rec_invoicehead.*
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code					
	AND inv_num = p_pk_inv_num

	LET l_ret = status
		
#	END IF

	IF p_ui_mode != UI_OFF THEN #display MESSAGE if ui is enabled
		IF l_ret < 0 THEN   		
			LET msgStr = "Coud not modify Invoice record ! /nOriginal PAT", trim(p_pk_inv_num), "New invoicehead/Part ", trim(p_rec_invoicehead.inv_num),  "\nDatabase Error ", trim(l_ret)                                                                                        
			#ERROR msgStr 
			CALL fgl_winmessage("Error when trying tInvoiceAdjustment Types record",msgStr,"error")
		ELSE
			LET msgStr = "Invoice record ", trim(p_rec_invoicehead.inv_num), " updated successfully !"   
			MESSAGE msgStr
		END IF                                           	
	END IF	
	
	RETURN l_ret
END FUNCTION        
############################################################
# FUNCTION db_invoicehead_update(p_rec_invoicehead)
############################################################

   
############################################################
# FUNCTION db_invoicehead_insert(p_rec_invoicehead)
#
#
############################################################
FUNCTION db_invoicehead_insert(p_ui_mode,p_rec_invoicehead)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_rec_invoicehead RECORD LIKE invoicehead.*
	DEFINE l_ret INT
	DEFINE l_ui_mode SMALLINT
	DEFINE msgStr STRING	
	
	IF p_ui_mode = UI_ON THEN
		LET l_ui_mode = UI_PK
	END IF

	IF p_rec_invoicehead.inv_num IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET msgStr = "Invoice code can not be empty ! (PAT=", trim(p_rec_invoicehead.inv_num), ")"  
			ERROR msgStr
		END IF
		RETURN -1
	END IF

	LET p_rec_invoicehead.cmpy_code = glob_rec_kandoouser.cmpy_code
	
	IF db_invoicehead_pk_exists(UI_PK,MODE_INSERT,p_rec_invoicehead.inv_num) THEN
		LET l_ret = -1
	ELSE
		
	INSERT INTO invoicehead
  VALUES(p_rec_invoicehead.*)

  LET l_ret = status
		
	END IF

	IF p_ui_mode != UI_OFF THEN #display MESSAGE if ui is enabled
		IF l_ret < 0 THEN   		
			LET msgStr = "Coud not create Invoice record ", trim(p_rec_invoicehead.inv_num), " !\nDatabase Error ", trim(l_ret)                                                                                        
			#ERROR msgStr 
			CALL fgl_winmessage("Error when trying to create/insert Invoice record",msgStr,"error")
		ELSE
			LET msgStr = "Invoice record ", trim(p_rec_invoicehead.inv_num), " created successfully !"   
			MESSAGE msgStr
		END IF                                           	
	END IF
	
	RETURN l_ret
END FUNCTION
############################################################
# END FUNCTION db_invoicehead_insert(p_rec_invoicehead)
############################################################


############################################################
# FUNCTION db_invoicehead_delete(p_inv_num)
#
#
############################################################
FUNCTION db_invoicehead_delete(p_ui_mode,p_confirm,p_inv_num)
	DEFINE p_ui_mode SMALLINT #hide or show error/warning messages
	DEFINE p_confirm BOOLEAN #is operator requested to confirm this operation / independent of ui mode	
	DEFINE p_inv_num LIKE invoicehead.inv_num
	DEFINE l_msgresp LIKE language.yes_flag	
	DEFINE l_ret SMALLINT	
	DEFINE msgStr STRING

	IF p_confirm = UI_CONFIRM_ON THEN
		LET msgStr = "Delete Invoice configuration ", trim(p_inv_num), " ?"
		IF NOT promptTF("Delete PAT",msgStr,TRUE) THEN
			RETURN -2
		END IF
	END IF
	
	IF p_inv_num IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET msgStr = "Invoice code can not be empty ! (PAT=", trim(p_inv_num), ")"  
			ERROR msgStr
		END IF
		RETURN -1
	END IF
	
# Needs doing !!!!!!!!!! 
#	IF db_XXXXX_get_invoicehead_count(p_inv_num) THEN #PK inv_num can only be deleted if it's not used already
#		IF p_ui_mode != UI_OFF THEN
#			LET msgStr = "Can not delete Product/Part ! ", trim(p_inv_num), " It is already used in a bank configuration"
#			CALL fgl_winmessage("Can not delete PAT ! ",msgStr,"error")
#		END IF
#		LET l_ret =  -1
#	ELSE

	DELETE FROM invoicehead
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code					
	AND inv_num = p_inv_num

	LET l_ret = status
		
			
#	END IF
	
	IF p_ui_mode != UI_OFF THEN #display MESSAGE if ui is enabled
		IF l_ret < 0 THEN   		
			LET msgStr = "Could not delete Invoice record ", trim(p_inv_num), " !\nDatabase Error ", trim(l_ret)                                                                                        
			#ERROR msgStr 
			CALL fgl_winmessage("Error when trying to delete",msgStr,"error")
		ELSE
			LET msgStr = "Invoice record ", trim(p_inv_num), " deleted !"   
			MESSAGE msgStr
		END IF                                           	
	END IF		             

	RETURN l_ret	
		  
END FUNCTION
############################################################
# END FUNCTION db_invoicehead_delete(p_inv_num)
############################################################
	

############################################################
# FUNCTION db_invoicehead_rec_validation(p_ui_mode,p_op_mode,p_rec_invoicehead)
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
FUNCTION db_invoicehead_rec_validation(p_ui_mode,p_op_mode,p_rec_invoicehead)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_op_mode SMALLINT
	DEFINE p_rec_invoicehead RECORD LIKE invoicehead.*
	DEFINE l_ret SMALLINT
	DEFINE l_msgStr STRING

	CASE p_op_mode
		WHEN MODE_INSERT
			#inv_num
			LET l_msgStr = "Can not create record. TAP Code already exists"  
			IF db_invoicehead_pk_exists(UI_PK,p_op_mode,p_rec_invoicehead.inv_num) THEN
				RETURN -1 #PK Already exists
			END IF		

			#name_text
			IF p_rec_invoicehead.name_text IS NULL THEN
				LET l_msgStr =  "Can not create InvoiceHead record with empty description text - inv_num: ", trim(p_rec_invoicehead.inv_num)
				IF p_ui_mode > 0 THEN
					ERROR l_msgStr
				END IF				
				RETURN -2
			END IF

			#org_cust_code
			IF p_rec_invoicehead.org_cust_code IS NOT NULL THEN
				IF NOT db_coa_pk_exists(UI_FK,p_op_mode,p_rec_invoicehead.org_cust_code) THEN
					LET l_msgStr =  "Can not create InvoiceHead record with invalid COA Code: ", trim(p_rec_invoicehead.org_cust_code)
					IF p_ui_mode > 0 THEN
						ERROR l_msgStr
					END IF
					RETURN -3
				END IF
			END IF
			
		WHEN MODE_UPDATE
			#inv_num
			IF NOT db_invoicehead_pk_exists(UI_PK,p_op_mode,p_rec_invoicehead.inv_num) THEN
				LET l_msgStr = "Can not update record. TAP Code does not exist!"  			
				RETURN -1 #PK NOT FOUND
			END IF			

			#name_text
			IF p_rec_invoicehead.name_text IS NULL THEN
				LET l_msgStr =  "Can not update InvoiceHead record with empty description text - inv_num: ", trim(p_rec_invoicehead.inv_num)
				IF p_ui_mode > 0 THEN
					ERROR l_msgStr
				END IF				
				RETURN -2
			END IF

			#org_cust_code
			IF NOT db_coa_pk_exists(UI_FK,p_op_mode,p_rec_invoicehead.org_cust_code) THEN
				LET l_msgStr =  "Can not update InvoiceHead record with invalid GL-COA Code: ", trim(p_rec_invoicehead.org_cust_code)
				IF p_ui_mode > 0 THEN
					ERROR l_msgStr
				END IF
				RETURN -3
			END IF
							
		WHEN MODE_DELETE
			#inv_num
			IF db_invoicehead_pk_exists(UI_PK,p_op_mode,p_rec_invoicehead.inv_num) THEN
				LET l_msgStr =  "Can not delete InvoiceHead record which does not exist - inv_num: ", trim(p_rec_invoicehead.inv_num)
				IF p_ui_mode > 0 THEN
					ERROR l_msgStr
				END IF
				RETURN -1 #PK NOT FOUND
			END IF			
	
	END CASE

	RETURN TRUE #validated
	
END FUNCTION	
############################################################
# FUNCTION db_invoicehead_rec_validation(p_ui_mode,p_op_mode,p_rec_invoicehead)
############################################################