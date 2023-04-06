########################################################################################################################
# TABLE invoicedetl
#
# 3 Column PK cmpy, inv_num, line_num
########################################################################################################################

##########################################################
# GLOBAL Scope Variables
##########################################################
GLOBALS "../common/glob_GLOBALS.4gl"

############################################################
# FUNCTION db_invoicedetl_get_count()
#
# Return total number of rows in invoicedetl 
############################################################
FUNCTION db_invoicedetl_get_count()
	DEFINE l_ret INT

	SELECT count(*) 
	INTO l_ret 
	FROM invoicedetl 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code		
			
	RETURN l_ret
END FUNCTION
############################################################
# END FUNCTION db_invoicedetl_get_count()
############################################################

############################################################
# FUNCTION db_invoicedetl_get_line_count()
#
# Return total number of lines for an invoice  
############################################################
FUNCTION db_invoicedetl_get_line_count(p_inv_num)
	DEFINE p_inv_num LIKE invoicedetl.inv_num
	DEFINE l_ret_line_count INT

	IF p_inv_num < 1 OR p_inv_num IS NULL THEN
		ERROR "Invalid argument for inv_num"
		RETURN -1
	END IF
	
	SELECT count(*) 
	INTO l_ret_line_count 
	FROM invoicedetl 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
	AND invoicedetl.inv_num = p_inv_num 		
			
	RETURN l_ret_line_count
END FUNCTION
############################################################
# END FUNCTION db_invoicedetl_get_line_count()
############################################################

				
############################################################
# FUNCTION db_invoicedetl_pk_exists(p_ui,p_inv_num,p_line_num)
#
# Validate PK - Unique
############################################################
#	CONSTANT UI_OFF SMALLINT = 0
#	CONSTANT UI_ON SMALLINT = 1
#	CONSTANT UI_FK SMALLINT = 2
#	CONSTANT UI_PK SMALLINT = 3
############################################################
FUNCTION db_invoicedetl_pk_exists(p_ui,p_inv_num,p_line_num)
	DEFINE p_ui SMALLINT
	DEFINE p_line_num LIKE invoicedetl.line_num
	DEFINE p_inv_num LIKE invoicedetl.inv_num
	DEFINE l_ret BOOLEAN
	DEFINE l_recCount INT
	DEFINE l_msg STRING

	IF p_line_num IS NULL THEN
		IF p_ui != UI_OFF THEN
			ERROR "invoicedetl Code can not be empty"
			#LET msgresp = kandoomsg("G",9178,"")
			#9178 Bank/State/Branchs must NOT be NULL
		END IF
		RETURN FALSE
	END IF

	IF p_inv_num IS NULL THEN
		IF p_ui != UI_OFF THEN
			ERROR "invoicedetl inv_num can not be empty"
			#LET msgresp = kandoomsg("G",9178,"")
			#9178 Bank/State/Branchs must NOT be NULL
		END IF
		RETURN FALSE
	END IF

	SELECT count(*) 
	INTO l_recCount 
	FROM invoicedetl
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code			
	AND invoicedetl.line_num = p_line_num
	AND invoicedetl.inv_num = p_inv_num
		
	IF l_recCount <> 0 THEN
		LET l_ret = TRUE	
		IF p_ui = UI_ON THEN
			MESSAGE "invoicedetl Code with inv_num exists! (", trim(p_line_num), ")"
		END IF
		IF p_ui = UI_PK THEN
			MESSAGE "invoicedetl Code with inv_num already exists! (", trim(p_line_num), ")"
		END IF
	ELSE
		LET l_ret = FALSE	
		IF p_ui = UI_FK THEN
			MESSAGE "invoicedetl Code with inv_num does not exists! (", trim(p_line_num), ")"
		END IF
	END IF
	
	RETURN l_ret
END FUNCTION
############################################################
# END FUNCTION db_invoicedetl_pk_exists(p_ui,p_inv_num,p_line_num)
############################################################


############################################################
# FUNCTION db_invoicedetl_get_rec(p_ui_mode,p_inv_num,p_line_num)
# RETURN l_rec_invoicedetl.*	
# Get invoicedetl record
############################################################
FUNCTION db_invoicedetl_get_rec(p_ui_mode,p_inv_num,p_line_num)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_inv_num LIKE invoicedetl.inv_num
	DEFINE p_line_num LIKE invoicedetl.line_num
	DEFINE l_rec_invoicedetl RECORD LIKE invoicedetl.*

	IF p_inv_num IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Can not retrieve record with empty invoicedetl inv_num code"
		END IF
		RETURN NULL
	END IF

	IF p_line_num IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Can not retrieve record with empty invoicedetl code"
		END IF
		RETURN NULL
	END IF

  SELECT *
    INTO l_rec_invoicedetl.*
    FROM invoicedetl
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code			
   AND inv_num = p_inv_num
   AND line_num = p_line_num
	
	IF sqlca.sqlcode != 0 THEN  		
   	IF p_ui_mode != UI_OFF THEN
      ERROR "invoicedetl with Code ", trim(p_inv_num), "/", trim(p_line_num), " NOT found"
		END IF	  
		INITIALIZE l_rec_invoicedetl.* TO NULL                                                                                      
	ELSE		                                                                                                                    
		#		                                                                                                
	END IF	         

	RETURN l_rec_invoicedetl.*		                                                                                                
END FUNCTION	
############################################################
# END FUNCTION db_invoicedetl_get_rec(p_ui_mode,p_inv_num,p_line_num)
############################################################


############################################################
# FUNCTION db_invoicedetl_get_part_code(p_ui_mode,p_inv_num,p_line_num)
# RETURN l_ret_part_code 
#
# Get description text of invoicedetl record
############################################################
FUNCTION db_invoicedetl_get_part_code(p_ui_mode,p_inv_num,p_line_num)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_line_num LIKE invoicedetl.line_num
	DEFINE p_inv_num LIKE invoicedetl.inv_num
	DEFINE l_ret_part_code LIKE invoicedetl.part_code

	IF p_inv_num IS NULL THEN
		IF p_ui_mode != UI_OFF THEN	
			ERROR "invoicedetl inv_num can NOT be empty"
		END IF
			RETURN NULL
	END IF

	IF p_line_num IS NULL THEN
		IF p_ui_mode != UI_OFF THEN	
			ERROR "invoicedetl Code can NOT be empty"
		END IF
			RETURN NULL
	END IF

	SELECT part_code 
	INTO l_ret_part_code 
	FROM invoicedetl 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code				
	AND invoicedetl.line_num = p_line_num
	AND invoicedetl.inv_num = p_inv_num

	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "invoicedetl Description with Code ",trim(p_line_num)," and inv_num ", trim(p_inv_num),  " NOT found"
		END IF			
		LET l_ret_part_code = NULL
	ELSE
		#
	END IF	
	
	RETURN l_ret_part_code
END FUNCTION
############################################################
# END FUNCTION db_invoicedetl_get_part_code(p_ui_mode,p_inv_num,p_line_num)
############################################################


########################################################################################################################
# 
# Get Array record data from DB
#
########################################################################################################################



########################################################################################################################
# 
# UPDATE INSERT DELETE row from DB
#
########################################################################################################################


############################################################
# FUNCTION db_invoicedetl_update(p_rec_invoicedetl)
#
#
############################################################
FUNCTION db_invoicedetl_update(p_ui_mode,p_pk_inv_num,p_pk_line_num,p_rec_invoicedetl)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_pk_inv_num LIKE invoicedetl.inv_num
	DEFINE p_pk_line_num LIKE invoicedetl.line_num
	DEFINE p_rec_invoicedetl RECORD LIKE invoicedetl.*
	DEFINE l_ui_mode SMALLINT
	DEFINE l_ret INT
	DEFINE l_msg STRING
	
	IF p_ui_mode = UI_ON THEN
		LET l_ui_mode = UI_PK
	END IF

	IF p_pk_inv_num IS NULL OR p_rec_invoicedetl.inv_num IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET l_msg = "invoicedetl inv_num code can not be empty ! (original inv_num=",trim(p_pk_inv_num), " / new inv_num=", trim(p_rec_invoicedetl.inv_num), ")"  
			ERROR l_msg
		END IF
		RETURN -1
	END IF

	IF p_pk_line_num IS NULL OR p_rec_invoicedetl.line_num IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET l_msg = "invoicedetl code can not be empty ! (original invoicedetl=",trim(p_pk_line_num), " / new invoicedetl=", trim(p_rec_invoicedetl.line_num), ")"  
			ERROR l_msg
		END IF
		RETURN -2
	END IF
	
#	IF db_product_get_class_count(p_pk_line_num) AND (p_pk_line_num <> p_rec_invoicedetl.line_num) THEN #PK line_num can only be changed if it's not used already
#		IF p_ui_mode > 0 THEN
#			ERROR "Can not change invoicedetl ! It is already used in a bank configuration"
#		END IF
#		LET l_ret =  -1
#	ELSE
		
	UPDATE invoicedetl
	SET * = p_rec_invoicedetl.*
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code				
	AND inv_num = p_pk_inv_num
	AND line_num = p_pk_line_num

	LET l_ret = status
		
#	END IF

	IF p_ui_mode != UI_OFF THEN #display MESSAGE if ui is enabled
		IF l_ret < 0 THEN   		
			LET l_msg = "Coud not modify invoicedetl record ! /nOriginal inv_num/invoicedetl", trim(p_pk_inv_num), "/", trim(p_pk_line_num), "New inv_num/invoicedetl ", trim(p_rec_invoicedetl.inv_num), "/" , trim(p_rec_invoicedetl.line_num),  "\nDatabase Error ", trim(l_ret)                                                                                        
			#ERROR l_msg 
			CALL fgl_winmessage("Error when trying to modify/update invoicedetl record",l_msg,"error")
		ELSE
			LET l_msg = "invoicedetl record ", trim(p_rec_invoicedetl.line_num), "/", trim(p_rec_invoicedetl.inv_num),  " updated successfully !"   
			MESSAGE l_msg
		END IF                                           	
	END IF	
	
	RETURN l_ret
END FUNCTION        
############################################################
# END FUNCTION db_invoicedetl_update(p_rec_invoicedetl)
############################################################

   
############################################################
# FUNCTION db_invoicedetl_insert(p_rec_invoicedetl)
#
#
############################################################
FUNCTION db_invoicedetl_insert(p_ui_mode,p_rec_invoicedetl)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_rec_invoicedetl RECORD LIKE invoicedetl.*
	DEFINE l_ret INT
	DEFINE l_ui_mode SMALLINT
	DEFINE l_msg STRING	
	
	IF p_ui_mode = UI_ON THEN
		LET l_ui_mode = UI_PK
	END IF

	IF p_rec_invoicedetl.inv_num IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET l_msg = "invoicedetl inv_num can not be empty ! (invoicedetl inv_num=", trim(p_rec_invoicedetl.inv_num), ")"  
			ERROR l_msg
		END IF
		RETURN -1
	END IF
	
	IF p_rec_invoicedetl.line_num IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET l_msg = "invoicedetl code can not be empty ! (invoicedetl=", trim(p_rec_invoicedetl.line_num), ")"  
			ERROR l_msg
		END IF
		RETURN -2
	END IF
	
	IF db_invoicedetl_pk_exists(UI_PK,p_rec_invoicedetl.inv_num,p_rec_invoicedetl.line_num) THEN
		LET l_ret = -1
	ELSE
		
	INSERT INTO invoicedetl
  VALUES(p_rec_invoicedetl.*)
  
  LET l_ret = status
		
	END IF

	IF p_ui_mode != UI_OFF THEN #display MESSAGE if ui is enabled
		IF l_ret < 0 THEN   		
			LET l_msg = "Coud not create invoicedetl record ", trim(p_rec_invoicedetl.line_num),"/", trim(p_rec_invoicedetl.inv_num), " !\nDatabase Error ", trim(l_ret)                                                                                        
			#ERROR l_msg 
			CALL fgl_winmessage("Error when trying to create/insert invoicedetl record",l_msg,"error")
		ELSE
			LET l_msg = "invoicedetl record ", trim(p_rec_invoicedetl.line_num),"/", trim(p_rec_invoicedetl.inv_num), " created successfully !"   
			MESSAGE l_msg
		END IF                                           	
	END IF
	
	RETURN l_ret
END FUNCTION
############################################################
# END FUNCTION db_invoicedetl_insert(p_rec_invoicedetl)
############################################################


############################################################
# FUNCTION db_invoicedetl_delete(p_line_num)
#
#
############################################################
FUNCTION db_invoicedetl_delete(p_ui_mode,p_confirm,p_inv_num,p_line_num)
	DEFINE p_ui_mode SMALLINT #hide or show error/warning messages
	DEFINE p_confirm BOOLEAN #is operator requested to confirm this operation / independent of ui mode	
	DEFINE p_inv_num LIKE invoicedetl.inv_num
	DEFINE p_line_num LIKE invoicedetl.line_num
	DEFINE l_ret SMALLINT	
	DEFINE l_msg STRING

	IF p_confirm = UI_CONFIRM_ON THEN
		LET l_msg = "Delete invoicedetl configuration ", trim(p_inv_num), "/", trim(p_line_num), " ?"
		IF NOT promptTF("Delete invoicedetl",l_msg,TRUE) THEN
			RETURN -10
		END IF
	END IF
	
	IF p_inv_num IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET l_msg = "invoicedetl inv_num code can not be empty ! (inv_num/invoicedetl=", trim(p_inv_num), "/", trim(p_line_num), ")"  
			ERROR l_msg
		END IF
		RETURN -1
	END IF
	
	IF p_line_num IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET l_msg = "invoicedetl code can not be empty ! (invoicedetl=", trim(p_line_num), ")"  
			ERROR l_msg
		END IF
		RETURN -2
	END IF

#	IF db_bank_get_class_count(p_line_num) THEN #PK line_num can only be deleted if it's not used already
#		IF p_ui_mode != UI_OFF THEN
#			LET l_msg = "Can not delete invoicedetl ! ", trim(p_line_num), " It is already used in a bank configuration"
#			CALL fgl_winmessage("Can not delete invoicedetl ! ",l_msg,"error")
#		END IF
#		LET l_ret =  -1
#	ELSE
		
	DELETE FROM invoicedetl
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
	AND inv_num = p_inv_num
	AND line_num = p_line_num

	LET l_ret = status
		
			
#	END IF
	
	IF p_ui_mode != UI_OFF THEN #display MESSAGE if ui is enabled
		IF l_ret < 0 THEN   		
			LET l_msg = "Coud not delete inv_num/invoicedetl=", trim(p_inv_num), "/", trim(p_line_num), " !\nDatabase Error ", trim(l_ret)                                                                                        
			#ERROR l_msg 
			CALL fgl_winmessage("Error when trying to delete",l_msg,"error")
		ELSE
			LET l_msg = "invoicedetl record ", trim(p_inv_num), "/", trim(p_line_num), " deleted !"   
			MESSAGE l_msg
		END IF                                           	
	END IF		             

	RETURN l_ret	
		  
END FUNCTION
############################################################
# END FUNCTION db_invoicedetl_delete(p_line_num)
############################################################



############################################################
# FUNCTION db_invoicedetl_rec_validation(p_ui_mode,p_op_mode,p_rec_invoicedetl)
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
FUNCTION db_invoicedetl_rec_validation(p_ui_mode,p_op_mode,p_rec_invoicedetl)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_op_mode SMALLINT
	DEFINE p_rec_invoicedetl RECORD LIKE invoicedetl.*
	DEFINE l_ret SMALLINT
	DEFINE l_msgStr STRING

	CASE p_op_mode
		WHEN MODE_INSERT
			#inv_num
			LET l_msgStr = "Can not create record. Invoice Code already exists"  
			IF db_invoicedetl_pk_exists(UI_PK,p_op_mode,p_rec_invoicedetl.inv_num) THEN
				RETURN -1 #PK Already exists
			END IF		

			#line_num
			IF p_rec_invoicedetl.line_num IS NULL THEN
				LET l_msgStr =  "Can not create InvoiceDetail (Line) record with empty description text - inv_num: ", trim(p_rec_invoicedetl.inv_num)
				IF p_ui_mode > 0 THEN
					ERROR l_msgStr
				END IF				
				RETURN -2
			END IF

				
		WHEN MODE_UPDATE
			#inv_num
			IF NOT db_invoicedetl_pk_exists(UI_PK,p_op_mode,p_rec_invoicedetl.inv_num) THEN
				LET l_msgStr = "Can not update record. Invoice Code does not exist!"  			
				RETURN -1 #PK NOT FOUND
			END IF			

			#line_num
			IF p_rec_invoicedetl.line_num IS NULL THEN
				LET l_msgStr =  "Can not update InvoiceDetail (Line) record with empty description text - inv_num: ", trim(p_rec_invoicedetl.inv_num)
				IF p_ui_mode > 0 THEN
					ERROR l_msgStr
				END IF				
				RETURN -2
			END IF

							
		WHEN MODE_DELETE
			#inv_num
			IF db_invoicedetl_pk_exists(UI_PK,p_op_mode,p_rec_invoicedetl.inv_num) THEN
				LET l_msgStr =  "Can not delete InvoiceDetail (Line) record which does not exist - inv_num: ", trim(p_rec_invoicedetl.inv_num)
				IF p_ui_mode > 0 THEN
					ERROR l_msgStr
				END IF
				RETURN -1 #PK NOT FOUND
			END IF			
	
	END CASE

	RETURN TRUE #validated
	
END FUNCTION	
############################################################
# END FUNCTION db_invoicedetl_rec_validation(p_ui_mode,p_op_mode,p_rec_invoicedetl)
############################################################