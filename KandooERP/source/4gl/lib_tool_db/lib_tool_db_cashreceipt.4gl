########################################################################################################################
# TABLE cashreceipt
# PK= compy_code nchar(2) , cash_num   integer
# FK= cust_code nchar(8) 
########################################################################################################################

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl"
			
############################################################
# FUNCTION db_cashreceipt_pk_exists(p_ui_mode,p_op_mode,p_cash_num)
#
# Validate PK - Unique
############################################################
#	CONSTANT UI_OFF SMALLINT = 0
#	CONSTANT UI_ON SMALLINT = 1
#	CONSTANT UI_FK SMALLINT = 2
#	CONSTANT UI_PK SMALLINT = 3
############################################################
FUNCTION db_cashreceipt_pk_exists(p_ui_mode,p_op_mode,p_cash_num)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_op_mode SMALLINT	
	DEFINE p_cash_num LIKE cashreceipt.cash_num
	DEFINE l_ret BOOLEAN
	DEFINE l_recCount INT
	DEFINE l_msgStr STRING

	IF p_cash_num IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "\'Cash Receipt\' Code can not be empty"
		END IF
		RETURN FALSE
	END IF

	SELECT count(*) 
	INTO l_recCount 
	FROM cashreceipt 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code				
	AND cashreceipt.cash_num = p_cash_num  
		
	IF l_recCount > 0 THEN
		LET l_ret = TRUE	
		CASE p_op_mode
			WHEN MODE_INSERT
				CASE p_ui_mode
					WHEN UI_PK
						ERROR "\'Cash Receipt\'s Code already exists! (", trim(p_cash_num), ")"
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
						ERROR "\'Cash Receipt\' Code does not exist! (", trim(p_cash_num), ")"
					OTHERWISE
						#No MESSAGE
				END CASE
			
			WHEN MODE_DELETE
				CASE p_ui_mode
					WHEN UI_PK
						#No MESSAGE
					WHEN UI_FK
						ERROR "\'Cash Receipt\' Code does not exist! (", trim(p_cash_num), ")"
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
						ERROR "\'Cash Receipt\' Code does not exist! (", trim(p_cash_num), ")"
					OTHERWISE
						#No MESSAGE
				END CASE

			WHEN MODE_UPDATE
				CASE p_ui_mode
					WHEN UI_PK
						ERROR "\'Cash Receipt\' Code does not exist! (", trim(p_cash_num), ")"
					WHEN UI_FK
						#No MESSAGE
					OTHERWISE
						#No MESSAGE
				END CASE

			WHEN MODE_DELETE
				CASE p_ui_mode
					WHEN UI_PK
						ERROR "\'Cash Receipt\' Code does not exist! (", trim(p_cash_num), ")"
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
# END FUNCTION db_cashreceipt_pk_exists(p_ui,p_cash_num)
############################################################


############################################################
# FUNCTION db_cashreceipt_get_count()
#
# Return total number of rows in cashreceipt 
############################################################
FUNCTION db_cashreceipt_get_count()
	DEFINE l_ret_count INT

	SELECT count(*) 
	INTO l_ret_count 
	FROM cashreceipt 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code				
			
	RETURN l_ret_count
END FUNCTION
############################################################
# END FUNCTION db_cashreceipt_get_count()
############################################################


############################################################
# FUNCTION db_cashreceipt_get_rec(p_ui_mode,p_cash_num)
# RETURN l_rec_cashreceipt.*
# Get cashreceipt record
############################################################
FUNCTION db_cashreceipt_get_rec(p_ui_mode,p_cash_num)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_cash_num LIKE cashreceipt.cash_num
	DEFINE l_rec_cashreceipt RECORD LIKE cashreceipt.*

	IF p_cash_num IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Can not retrieve record with empty \'Cash Receipt\' Number (cash_num)"
		END IF
		RETURN NULL
	END IF

	SELECT * INTO l_rec_cashreceipt.*
	FROM cashreceipt
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code		        
	AND cash_num = p_cash_num
	
	IF sqlca.sqlcode != 0 THEN   		  
		INITIALIZE l_rec_cashreceipt.* TO NULL
		
		IF p_ui_mode != UI_OFF THEN
			ERROR "Could not retrieve the \'Cash Receipt\' Record (cashreceipt)"
		END IF                                                                                      
	ELSE		                                                                                                                    
		# all fine		                                                                                                
	END IF	         

	RETURN l_rec_cashreceipt.*		                                                                                                
END FUNCTION	
############################################################
# END FUNCTION db_cashreceipt_get_rec(p_ui_mode,p_cash_num)
############################################################


############################################################
# FUNCTION db_cashreceipt_get_cust_code(p_ui_mode,p_cash_num)
# RETURN l_ret_cust_code 
#
# Get description text of \'Cash Receipt\' record
############################################################
FUNCTION db_cashreceipt_get_cust_code(p_ui_mode,p_cash_num)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_cash_num LIKE cashreceipt.cash_num
	DEFINE l_ret_cust_code LIKE cashreceipt.cust_code

	IF p_cash_num IS NULL THEN
		IF p_ui_mode != UI_OFF THEN	
			ERROR "\'Cash Receipt\' Number (cash_num) can NOT be empty"
		END IF
			RETURN NULL
	END IF

	SELECT cust_code 
	INTO l_ret_cust_code 
	FROM cashreceipt
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code				 
	AND cashreceipt.cash_num = p_cash_num  		
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "\'Cash Receipt\' Description with Code ",trim(p_cash_num),  "NOT found"
		END IF			
		LET l_ret_cust_code = NULL
	ELSE
		#
	END IF	
	RETURN l_ret_cust_code
END FUNCTION
############################################################
# END FUNCTION db_cashreceipt_get_cust_code(p_ui_mode,p_cash_num)
############################################################


############################################################
# FUNCTION db_cashreceipt_get_cash_acct_code(p_ui_mode,p_cash_num)
# RETURN l_ret_cash_acct_code
#
# Get description text of Product record
############################################################
FUNCTION db_cashreceipt_get_cash_acct_code(p_ui_mode,p_cash_num)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_cash_num LIKE cashreceipt.cash_num
	DEFINE l_ret_cash_acct_code LIKE cashreceipt.cash_acct_code

	IF p_cash_num IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "\'Cash Receipt\' Number (cash_num) can NOT be empty"
		END IF
		RETURN NULL
	END IF

	SELECT cash_acct_code 
	INTO l_ret_cash_acct_code
	FROM cashreceipt 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code				
	AND cashreceipt.cash_num = p_cash_num  		
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "\'Cash Receipt\' Reference with \'Cash Receipt\' Number (cash_num) ",trim(p_cash_num),  "NOT found"
		END IF
		LET l_ret_cash_acct_code = NULL
	ELSE
		#	                                                                                                
	END IF	

	RETURN l_ret_cash_acct_code	                                                                                                
END FUNCTION
############################################################
# END FUNCTION db_cashreceipt_get_cash_acct_code(p_ui_mode,p_cash_num)
############################################################


########################################################################################################################
# 
# Get Array record data from DB
#
########################################################################################################################


############################################################
# FUNCTION db_cashreceipt_get_arr_rec(p_query_text)
#
#
############################################################
FUNCTION db_cashreceipt_get_arr_rec(p_query_type,p_query_or_where_text)
	DEFINE p_query_type SMALLINT
	DEFINE p_query_or_where_text STRING
	DEFINE l_query_text STRING
	DEFINE l_where_text STRING
	DEFINE l_arr_rec_cashreceipt DYNAMIC ARRAY OF RECORD LIKE cashreceipt.*		
	DEFINE l_rec_cashreceipt RECORD LIKE cashreceipt.*
	DEFINE l_idx SMALLINT

	IF p_query_type = FILTER_QUERY_WHERE AND p_query_or_where_text IS NULL THEN
		LET p_query_or_where_text = " 1=1 "
	END IF
		
	#p_query_text is optional
	CASE p_query_type
		WHEN FILTER_QUERY_OFF
			LET l_query_text = 
				"SELECT * FROM cashreceipt ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ",					
				"\'Cash Receipt\' BY cashreceipt.cash_num" 	

		WHEN FILTER_QUERY_WHERE
			LET l_where_text = p_query_or_where_text
			LET l_query_text = 
				"SELECT * FROM cashreceipt ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ",					
				"AND ", l_where_text clipped," ",
				"\'Cash Receipt\' BY cashreceipt.cash_num" 	

		WHEN FILTER_QUERY_SELECT
			LET l_query_text = p_query_or_where_text		
		
		OTHERWISE
			LET l_query_text = 
				"SELECT * FROM cashreceipt ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ",					
				"\'Cash Receipt\' BY cashreceipt.cash_num" 				
	END CASE

	PREPARE s_cashreceipt FROM l_query_text
	DECLARE c_cashreceipt CURSOR FOR s_cashreceipt


	LET l_idx = 0
	FOREACH c_cashreceipt INTO l_arr_rec_cashreceipt[l_idx].*
      LET l_idx = l_idx + 1

	END FOREACH

	IF sqlca.sqlcode < 0 THEN   	
		LET l_arr_rec_cashreceipt = NULL	                                                                                        
	ELSE		                                                                                                                    
		#		                                                                                                
	END IF	         

	RETURN l_arr_rec_cashreceipt		                                                                                                
END FUNCTION
############################################################
# END FUNCTION db_cashreceipt_get_arr_rec(p_query_text)
############################################################


########################################################################################################################
# 
# UPDATE INSERT DELETE row from DB
#
########################################################################################################################


############################################################
# FUNCTION db_cashreceipt_update(p_rec_cashreceipt)
#
#
############################################################
FUNCTION db_cashreceipt_update(p_ui_mode,p_pk_cash_num,p_rec_cashreceipt)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_pk_cash_num LIKE cashreceipt.cash_num
	DEFINE p_rec_cashreceipt RECORD LIKE cashreceipt.*
	DEFINE l_ui_mode SMALLINT
	DEFINE l_ret INT
	DEFINE l_msgStr STRING
	
	IF p_ui_mode = UI_ON THEN
		LET l_ui_mode = UI_PK
	END IF

	IF p_pk_cash_num IS NULL OR p_rec_cashreceipt.cash_num IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET l_msgStr = "\'Cash Receipt\' Number (cash_num) can not be empty ! (original \'Cash Receipt\' Code=",trim(p_pk_cash_num), " / new \'Cash Receipt\' Code=", trim(p_rec_cashreceipt.cash_num), ")"  
			ERROR l_msgStr
		END IF
		RETURN -1
	END IF
# Needs doing !!!!!!!!!! 	
#	IF db_XXXXXXXX_get_cashreceipt_count(p_pk_cash_num) AND (p_pk_cash_num <> p_rec_cashreceipt.cash_num) THEN #PK cash_num can only be changed if it's not used already
#		IF p_ui_mode > 0 THEN
#			ERROR "Can not change \'Cash Receipt\' ! It is already used in a configuration"
#		END IF
#		LET l_ret =  -1
#	ELSE
		WHENEVER ERROR CONTINUE
		UPDATE cashreceipt
		SET * = p_rec_cashreceipt.*
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code					
		AND cash_num = p_pk_cash_num
		LET l_ret = status
		WHENEVER ERROR STOP
#	END IF

	IF p_ui_mode != UI_OFF THEN #display MESSAGE if ui is enabled
		IF l_ret < 0 THEN   		
			LET l_msgStr = "Coud not modify \'Cash Receipt\' record ! /nOriginal \'Cash Receipt\'", trim(p_pk_cash_num), "New cashreceipt ", trim(p_rec_cashreceipt.cash_num),  "\nDatabase Error ", trim(l_ret)                                                                                        
			#ERROR l_msgStr 
			CALL fgl_winmessage("Error when trying to modify/update \'Cash Receipt\' record",l_msgStr,"error")
		ELSE
			LET l_msgStr = "\'Cash Receipt\'t record ", trim(p_rec_cashreceipt.cash_num), " updated successfully !"   
			MESSAGE l_msgStr
		END IF                                           	
	END IF	
	
	RETURN l_ret
END FUNCTION        
############################################################
# END FUNCTION db_cashreceipt_update(p_rec_cashreceipt)
############################################################

   
############################################################
# FUNCTION db_cashreceipt_insert(p_rec_cashreceipt)
#
#
############################################################
FUNCTION db_cashreceipt_insert(p_ui_mode,p_rec_cashreceipt)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_rec_cashreceipt RECORD LIKE cashreceipt.*
	DEFINE l_ret INT
	DEFINE l_ui_mode SMALLINT
	DEFINE l_msgStr STRING	
	
	IF p_ui_mode = UI_ON THEN
		LET l_ui_mode = UI_PK
	END IF

	IF p_rec_cashreceipt.cash_num IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET l_msgStr = "\'Cash Receipt\' Number (cash_num) can not be empty ! (\'Cash Receipt\'=", trim(p_rec_cashreceipt.cash_num), ")"  
			ERROR l_msgStr
		END IF
		RETURN -1
	END IF

	LET p_rec_cashreceipt.cmpy_code = glob_rec_kandoouser.cmpy_code
	
	IF db_cashreceipt_pk_exists(UI_PK,MODE_INSERT,p_rec_cashreceipt.cash_num) THEN
		LET l_ret = -1
	ELSE
		WHENEVER ERROR CONTINUE
			INSERT INTO cashreceipt
	    VALUES(p_rec_cashreceipt.*)
	    LET l_ret = status
		WHENEVER ERROR STOP
	END IF

	IF p_ui_mode != UI_OFF THEN #display MESSAGE if ui is enabled
		IF l_ret < 0 THEN   		
			LET l_msgStr = "Coud not create \'Cash Receipt\' record ", trim(p_rec_cashreceipt.cash_num), " !\nDatabase Error ", trim(l_ret)                                                                                        
			#ERROR l_msgStr 
			CALL fgl_winmessage("Error when trying to create/insert \'Cash Receipt\' record",l_msgStr,"error")
		ELSE
			LET l_msgStr = "P\'Cash Receipt\' record ", trim(p_rec_cashreceipt.cash_num), " created successfully !"   
			MESSAGE l_msgStr
		END IF                                           	
	END IF
	
	RETURN l_ret
END FUNCTION
############################################################
# END FUNCTION db_cashreceipt_insert(p_rec_cashreceipt)
############################################################


############################################################
# FUNCTION db_cashreceipt_delete(p_cash_num)
#
#
############################################################
FUNCTION db_cashreceipt_delete(p_ui_mode,p_confirm,p_cash_num)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_confirm BOOLEAN #is operator requested to confirm this operation / independent of ui mode	
	DEFINE p_cash_num LIKE cashreceipt.cash_num
	DEFINE l_msgresp LIKE language.yes_flag	
	DEFINE l_ret SMALLINT	
	DEFINE l_msgStr STRING

	IF p_confirm = UI_CONFIRM_ON THEN
		LET l_msgStr = "Delete \'Cash Receipt\' ", trim(p_cash_num), " ?"
		IF NOT promptTF("Delete \'Cash Receipt\'",l_msgStr,TRUE) THEN
			RETURN -2
		END IF
	END IF
	
	IF p_cash_num IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET l_msgStr = "\'Cash Receipt\' code (cash_num) can not be empty ! (\'Cash Receipt\'=", trim(p_cash_num), ")"  
			ERROR l_msgStr
		END IF
		RETURN -1
	END IF
# Needs doing !!!!!!!!!! 
#	IF db_XXXXX_get_cashreceipt_count(p_cash_num) THEN #PK cash_num can only be deleted if it's not used already
#		IF p_ui_mode != UI_OFF THEN
#			LET l_msgStr = "Can not delete Product ! ", trim(p_cash_num), " It is already used in a bank configuration"
#			CALL fgl_winmessage("Can not delete \'Cash Receipt\' ! ",l_msgStr,"error")
#		END IF
#		LET l_ret =  -1
#	ELSE
		WHENEVER ERROR CONTINUE
		DELETE FROM cashreceipt
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code					
			AND cash_num = p_cash_num
			LET l_ret = status
		WHENEVER ERROR STOP
			
#	END IF
	
	IF p_ui_mode != UI_OFF THEN #display MESSAGE if ui is enabled
		IF l_ret < 0 THEN   		
			LET l_msgStr = "Could not delete \'Cash Receipt\' record ", trim(p_cash_num), " !\nDatabase Error ", trim(l_ret)                                                                                        
			#ERROR l_msgStr 
			CALL fgl_winmessage("Error when trying to delete",l_msgStr,"error")
		ELSE
			LET l_msgStr = "\'Cash Receipt\' ", trim(p_cash_num), " deleted !"   
			MESSAGE l_msgStr
		END IF                                           	
	END IF		             

	RETURN l_ret		  
END FUNCTION
############################################################
# END FUNCTION db_cashreceipt_delete(p_cash_num)
############################################################
	

############################################################
# 
# FUNCTION db_cashreceipt_delete(p_cash_num)
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
############################################################
FUNCTION db_cashreceipt_rec_validation(p_ui_mode,p_op_mode,p_rec_cashreceipt)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_op_mode SMALLINT
	DEFINE p_rec_cashreceipt RECORD LIKE cashreceipt.*
	DEFINE l_ret SMALLINT
	DEFINE l_msgStr STRING
	DISPLAY "p_ui_mode=", p_ui_mode
	DISPLAY "p_op_mode=", p_op_mode
	CASE p_op_mode
		WHEN MODE_INSERT
			#cash_num
			LET l_msgStr = "Can not create record. \'Cash Receipt\' Code already exists"  
			IF db_cashreceipt_pk_exists(UI_PK,p_op_mode,p_rec_cashreceipt.cash_num) THEN
				RETURN -1 #PK Already exists
			END IF		

			#cust_code
			IF p_rec_cashreceipt.cust_code IS NULL THEN
				LET l_msgStr =  "Can not create \'Cash Receipt\' record (cashreceipt) with empty cust_code! cash_num: ", trim(p_rec_cashreceipt.cash_num)
				IF p_ui_mode > 0 THEN
					ERROR l_msgStr
				END IF				
				RETURN -2
			END IF

		WHEN MODE_UPDATE
			#cash_num
			IF NOT db_cashreceipt_pk_exists(UI_PK,p_op_mode,p_rec_cashreceipt.cash_num) THEN
				LET l_msgStr = "Can not update record. TAP Code does not exist!"  			
				RETURN -1 #PK NOT FOUND
			END IF			

			#cust_code
			IF p_rec_cashreceipt.cust_code IS NULL THEN
				LET l_msgStr =  "Can not update \'Cash Receipt\' record (cashreceipt) with empty cust_code! cash_num: ", trim(p_rec_cashreceipt.cash_num)
				IF p_ui_mode > 0 THEN
					ERROR l_msgStr
				END IF				
				RETURN -2
			END IF
							
		WHEN MODE_DELETE
			#cash_num
			IF db_cashreceipt_pk_exists(UI_PK,p_op_mode,p_rec_cashreceipt.cash_num) THEN
				LET l_msgStr =  "Can not delete \'Cash Receipt\' record (cashreceipt) which does not exist - cash_num: ", trim(p_rec_cashreceipt.cash_num)
				IF p_ui_mode > 0 THEN
					ERROR l_msgStr
				END IF
				RETURN -1 #PK NOT FOUND
			END IF			
	
	END CASE

	RETURN TRUE
	
END FUNCTION	
############################################################
# END FUNCTION db_cashreceipt_delete(p_cash_num)
############################################################