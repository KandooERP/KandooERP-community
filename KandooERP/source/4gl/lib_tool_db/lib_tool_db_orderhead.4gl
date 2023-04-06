########################################################################################################################
# TABLE orderhead
# PK= compy_code nchar(2) , order_num integer
# FK= cust_code nchar(8) 
########################################################################################################################

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl"
			
############################################################
# FUNCTION db_orderhead_pk_exists(p_ui,p_order_num)
#
# Validate PK - Unique
############################################################
#	CONSTANT UI_OFF SMALLINT = 0
#	CONSTANT UI_ON SMALLINT = 1
#	CONSTANT UI_FK SMALLINT = 2
#	CONSTANT UI_PK SMALLINT = 3
############################################################
FUNCTION db_orderhead_pk_exists(p_ui_mode,p_op_mode,p_order_num)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_op_mode SMALLINT	
	DEFINE p_order_num LIKE orderhead.order_num
	DEFINE l_ret BOOLEAN
	DEFINE l_recCount INT
	DEFINE l_msgStr STRING

	IF p_order_num IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Order Code can not be empty"
		END IF
		RETURN FALSE
	END IF

	SELECT count(*) 
	INTO l_recCount 
	FROM orderhead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code				
	AND orderhead.order_num = p_order_num  
		
	IF l_recCount > 0 THEN
		LET l_ret = TRUE	
		CASE p_op_mode
			WHEN MODE_INSERT
				CASE p_ui_mode
					WHEN UI_PK
						ERROR "Orders Code already exists! (", trim(p_order_num), ")"
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
						ERROR "Order Code does not exist! (", trim(p_order_num), ")"
					OTHERWISE
						#No MESSAGE
				END CASE
			
			WHEN MODE_DELETE
				CASE p_ui_mode
					WHEN UI_PK
						#No MESSAGE
					WHEN UI_FK
						ERROR "Order Code does not exist! (", trim(p_order_num), ")"
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
						ERROR "Order Code does not exist! (", trim(p_order_num), ")"
					OTHERWISE
						#No MESSAGE
				END CASE

			WHEN MODE_UPDATE
				CASE p_ui_mode
					WHEN UI_PK
						ERROR "Order Code does not exist! (", trim(p_order_num), ")"
					WHEN UI_FK
						#No MESSAGE
					OTHERWISE
						#No MESSAGE
				END CASE

			WHEN MODE_DELETE
				CASE p_ui_mode
					WHEN UI_PK
						ERROR "Order Code does not exist! (", trim(p_order_num), ")"
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
# END FUNCTION db_orderhead_pk_exists(p_ui,p_order_num)
############################################################


############################################################
# FUNCTION db_orderhead_get_count()
#
# Return total number of rows in orderhead 
############################################################
FUNCTION db_orderhead_get_count()
	DEFINE l_ret_count INT

	SELECT count(*) 
	INTO l_ret_count 
	FROM orderhead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code				
			
	RETURN l_ret_count
END FUNCTION
############################################################
# END FUNCTION db_orderhead_get_count()
############################################################


############################################################
# FUNCTION db_orderhead_get_count_with_ord_ind(p_ord_ind)
#
# Return total number of rows in orderhead with ord_ind
############################################################
FUNCTION db_orderhead_get_count_with_ord_ind(p_ord_ind)
	DEFINE p_ord_ind LIKE orderhead.ord_ind
	DEFINE l_ret_count INT

	SELECT count(*) 
	INTO l_ret_count 
	FROM orderhead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code				
	AND orderhead.ord_ind = p_ord_ind
			
	RETURN l_ret_count
END FUNCTION
############################################################
# END FUNCTION db_orderhead_get_count_with_ord_ind(p_ord_ind)
############################################################



############################################################
# FUNCTION db_orderhead_get_rec(p_ui_mode,p_order_num)
# RETURN l_rec_orderhead.*
# Get orderhead record
############################################################
FUNCTION db_orderhead_get_rec(p_ui_mode,p_order_num)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_order_num LIKE orderhead.order_num
	DEFINE l_rec_orderhead RECORD LIKE orderhead.*

	IF p_order_num IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Can not retrieve record with empty Product Adjustment Types Code"
		END IF
		RETURN NULL
	END IF

	WHENEVER ERROR CONTINUE
	SELECT * INTO l_rec_orderhead.*
	FROM orderhead
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code		        
	AND order_num = p_order_num
	
	WHENEVER ERROR STOP
	
	IF sqlca.sqlcode != 0 THEN   		  
		INITIALIZE l_rec_orderhead.* TO NULL                                                                                      
	ELSE		                                                                                                                    
		#		                                                                                                
	END IF	         

	RETURN l_rec_orderhead.*		                                                                                                
END FUNCTION	
############################################################
# END FUNCTION db_orderhead_get_rec(p_ui_mode,p_order_num)
############################################################


############################################################
# FUNCTION db_orderhead_get_cust_code(p_ui_mode,p_order_num)
# RETURN l_ret_cust_code 
#
# Get description text of Product Adjustment Types record
############################################################
FUNCTION db_orderhead_get_cust_code(p_ui_mode,p_order_num)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_order_num LIKE orderhead.order_num
	DEFINE l_ret_cust_code LIKE orderhead.cust_code

	IF p_order_num IS NULL THEN
		IF p_ui_mode != UI_OFF THEN	
			ERROR "Product Adjustment Types Code can NOT be empty"
		END IF
			RETURN NULL
	END IF

	SELECT cust_code 
	INTO l_ret_cust_code 
	FROM orderhead
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code				 
	AND orderhead.order_num = p_order_num  		
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Product Adjustment Types Description with Code ",trim(p_order_num),  "NOT found"
		END IF			
		LET l_ret_cust_code = NULL
	ELSE
		#
	END IF	
	RETURN l_ret_cust_code
END FUNCTION
############################################################
# END FUNCTION db_orderhead_get_cust_code(p_ui_mode,p_order_num)
############################################################


############################################################
# FUNCTION db_orderhead_get_sales_code(p_ui_mode,p_order_num)
# RETURN l_ret_sales_code
#
# Get description text of Product record
############################################################
FUNCTION db_orderhead_get_sales_code(p_ui_mode,p_order_num)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_order_num LIKE orderhead.order_num
	DEFINE l_ret_sales_code LIKE orderhead.sales_code

	IF p_order_num IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Product Adjustment Types Code can NOT be empty"
		END IF
		RETURN NULL
	END IF

	SELECT sales_code 
	INTO l_ret_sales_code
	FROM orderhead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code				
	AND orderhead.order_num = p_order_num  		
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Product Adjustment Types Reference with Product Adjustment Types Code ",trim(p_order_num),  "NOT found"
		END IF
		LET l_ret_sales_code = NULL
	ELSE
		#	                                                                                                
	END IF	

	RETURN l_ret_sales_code	                                                                                                
END FUNCTION
############################################################
# END FUNCTION db_orderhead_get_sales_code(p_ui_mode,p_order_num)
############################################################


############################################################
# FUNCTION db_orderhead_get_order_num(p_ui_mode,p_order_num)
# RETURN l_ret_order_num
#
# Get description text of orderhead record
############################################################
FUNCTION db_orderhead_get_order_num(p_ui_mode,p_order_num)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_order_num LIKE orderhead.order_num
	DEFINE l_ret_order_num LIKE orderhead.order_num

	IF p_order_num IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Product Adjustment Types Code can NOT be empty"
		END IF
		RETURN NULL
	END IF

	SELECT order_num
	INTO l_ret_order_num
	FROM orderhead
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code	
	AND orderhead.order_num = p_order_num  		
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Product Adjustment Types Code ",trim(p_order_num),  "NOT found"
		END IF
		LET l_ret_order_num = NULL
	ELSE
		#	                                                                                                
	END IF	

	RETURN l_ret_order_num	                                                                                                
END FUNCTION
############################################################
# END FUNCTION db_orderhead_get_order_num(p_ui_mode,p_order_num)
############################################################


########################################################################################################################
# 
# Get Array record data from DB
#
########################################################################################################################


############################################################
# FUNCTION db_orderhead_get_arr_rec(p_query_text)
#
#
############################################################
FUNCTION db_orderhead_get_arr_rec(p_query_type,p_query_or_where_text)
	DEFINE p_query_type SMALLINT
	DEFINE p_query_or_where_text STRING
	DEFINE l_query_text STRING
	DEFINE l_where_text STRING
	DEFINE l_arr_rec_orderhead DYNAMIC ARRAY OF RECORD LIKE orderhead.*		
	DEFINE l_rec_orderhead RECORD LIKE orderhead.*
	DEFINE l_idx SMALLINT

	IF p_query_type = FILTER_QUERY_WHERE AND p_query_or_where_text IS NULL THEN
		LET p_query_or_where_text = " 1=1 "
	END IF
		
	#p_query_text is optional
	CASE p_query_type
		WHEN FILTER_QUERY_OFF
			LET l_query_text = 
				"SELECT * FROM orderhead ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ",					
				"ORDER BY orderhead.order_num" 	

		WHEN FILTER_QUERY_WHERE
			LET l_where_text = p_query_or_where_text
			LET l_query_text = 
				"SELECT * FROM orderhead ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ",					
				"AND ", l_where_text clipped," ",
				"ORDER BY orderhead.order_num" 	

		WHEN FILTER_QUERY_SELECT
			LET l_query_text = p_query_or_where_text		
		
		OTHERWISE
			LET l_query_text = 
				"SELECT * FROM orderhead ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ",					
				"ORDER BY orderhead.order_num" 				
	END CASE

	PREPARE s_orderhead FROM l_query_text
	DECLARE c_orderhead CURSOR FOR s_orderhead


	LET l_idx = 0
	FOREACH c_orderhead INTO l_arr_rec_orderhead[l_idx].*
      LET l_idx = l_idx + 1

	END FOREACH

	IF sqlca.sqlcode < 0 THEN   	
		LET l_arr_rec_orderhead = NULL	                                                                                        
	ELSE		                                                                                                                    
		#		                                                                                                
	END IF	         

	RETURN l_arr_rec_orderhead		                                                                                                
END FUNCTION
############################################################
# END FUNCTION db_orderhead_get_arr_rec(p_query_text)
############################################################


########################################################################################################################
# 
# UPDATE INSERT DELETE row from DB
#
########################################################################################################################


############################################################
# FUNCTION db_orderhead_update(p_rec_orderhead)
#
#
############################################################
FUNCTION db_orderhead_update(p_ui_mode,p_pk_order_num,p_rec_orderhead)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_pk_order_num LIKE orderhead.order_num
	DEFINE p_rec_orderhead RECORD LIKE orderhead.*
	DEFINE l_ui_mode SMALLINT
	DEFINE l_ret INT
	DEFINE l_msgStr STRING
	
	IF p_ui_mode = UI_ON THEN
		LET l_ui_mode = UI_PK
	END IF

	IF p_pk_order_num IS NULL OR p_rec_orderhead.order_num IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET l_msgStr = "Product Adjustment Types code can not be empty ! (original Order Code=",trim(p_pk_order_num), " / new Order Code=", trim(p_rec_orderhead.order_num), ")"  
			ERROR l_msgStr
		END IF
		RETURN -1
	END IF
# Needs doing !!!!!!!!!! 	
#	IF db_XXXXXXXX_get_orderhead_count(p_pk_order_num) AND (p_pk_order_num <> p_rec_orderhead.order_num) THEN #PK order_num can only be changed if it's not used already
#		IF p_ui_mode > 0 THEN
#			ERROR "Can not change Product Adjustment Types ! It is already used in a configuration"
#		END IF
#		LET l_ret =  -1
#	ELSE
		WHENEVER ERROR CONTINUE
		UPDATE orderhead
		SET * = p_rec_orderhead.*
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code					
		AND order_num = p_pk_order_num
		LET l_ret = status
		WHENEVER ERROR STOP
#	END IF

	IF p_ui_mode != UI_OFF THEN #display MESSAGE if ui is enabled
		IF l_ret < 0 THEN   		
			LET l_msgStr = "Coud not modify Product Adjustment Types record ! /nOriginal Order", trim(p_pk_order_num), "New orderhead ", trim(p_rec_orderhead.order_num),  "\nDatabase Error ", trim(l_ret)                                                                                        
			#ERROR l_msgStr 
			CALL fgl_winmessage("Error when trying to modify/update Product Adjustment Types record",l_msgStr,"error")
		ELSE
			LET l_msgStr = "Product Adjustment Typest record ", trim(p_rec_orderhead.order_num), " updated successfully !"   
			MESSAGE l_msgStr
		END IF                                           	
	END IF	
	
	RETURN l_ret
END FUNCTION        
############################################################
# END FUNCTION db_orderhead_update(p_rec_orderhead)
############################################################

   
############################################################
# FUNCTION db_orderhead_insert(p_rec_orderhead)
#
#
############################################################
FUNCTION db_orderhead_insert(p_ui_mode,p_rec_orderhead)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_rec_orderhead RECORD LIKE orderhead.*
	DEFINE l_ret INT
	DEFINE l_ui_mode SMALLINT
	DEFINE l_msgStr STRING	
	
	IF p_ui_mode = UI_ON THEN
		LET l_ui_mode = UI_PK
	END IF

	IF p_rec_orderhead.order_num IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET l_msgStr = "Product Adjustment Types code can not be empty ! (Order=", trim(p_rec_orderhead.order_num), ")"  
			ERROR l_msgStr
		END IF
		RETURN -1
	END IF

	LET p_rec_orderhead.cmpy_code = glob_rec_kandoouser.cmpy_code
	
	IF db_orderhead_pk_exists(UI_PK,MODE_INSERT,p_rec_orderhead.order_num) THEN
		LET l_ret = -1
	ELSE
		WHENEVER ERROR CONTINUE
			INSERT INTO orderhead
	    VALUES(p_rec_orderhead.*)
	    LET l_ret = status
		WHENEVER ERROR STOP
	END IF

	IF p_ui_mode != UI_OFF THEN #display MESSAGE if ui is enabled
		IF l_ret < 0 THEN   		
			LET l_msgStr = "Coud not create Product Adjustment Types record ", trim(p_rec_orderhead.order_num), " !\nDatabase Error ", trim(l_ret)                                                                                        
			#ERROR l_msgStr 
			CALL fgl_winmessage("Error when trying to create/insert Product Adjustment Types record",l_msgStr,"error")
		ELSE
			LET l_msgStr = "PProduct Adjustment Types record ", trim(p_rec_orderhead.order_num), " created successfully !"   
			MESSAGE l_msgStr
		END IF                                           	
	END IF
	
	RETURN l_ret
END FUNCTION
############################################################
# END FUNCTION db_orderhead_insert(p_rec_orderhead)
############################################################


############################################################
# FUNCTION db_orderhead_delete(p_order_num)
#
#
############################################################
FUNCTION db_orderhead_delete(p_ui_mode,p_confirm,p_order_num)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_confirm BOOLEAN #is operator requested to confirm this operation / independent of ui mode	
	DEFINE p_order_num LIKE orderhead.order_num
	DEFINE l_msgresp LIKE language.yes_flag	
	DEFINE l_ret SMALLINT	
	DEFINE l_msgStr STRING

	IF p_confirm = UI_CONFIRM_ON THEN
		LET l_msgStr = "Delete order ", trim(p_order_num), " ?"
		IF NOT promptTF("Delete Order",l_msgStr,TRUE) THEN
			RETURN -2
		END IF
	END IF
	
	IF p_order_num IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET l_msgStr = "Order code (order_num) can not be empty ! (Order=", trim(p_order_num), ")"  
			ERROR l_msgStr
		END IF
		RETURN -1
	END IF
# Needs doing !!!!!!!!!! 
#	IF db_XXXXX_get_orderhead_count(p_order_num) THEN #PK order_num can only be deleted if it's not used already
#		IF p_ui_mode != UI_OFF THEN
#			LET l_msgStr = "Can not delete Product ! ", trim(p_order_num), " It is already used in a bank configuration"
#			CALL fgl_winmessage("Can not delete Order ! ",l_msgStr,"error")
#		END IF
#		LET l_ret =  -1
#	ELSE
		WHENEVER ERROR CONTINUE
		DELETE FROM orderhead
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code					
			AND order_num = p_order_num
			LET l_ret = status
		WHENEVER ERROR STOP
			
#	END IF
	
	IF p_ui_mode != UI_OFF THEN #display MESSAGE if ui is enabled
		IF l_ret < 0 THEN   		
			LET l_msgStr = "Could not delete order record ", trim(p_order_num), " !\nDatabase Error ", trim(l_ret)                                                                                        
			#ERROR l_msgStr 
			CALL fgl_winmessage("Error when trying to delete",l_msgStr,"error")
		ELSE
			LET l_msgStr = "Order ", trim(p_order_num), " deleted !"   
			MESSAGE l_msgStr
		END IF                                           	
	END IF		             

	RETURN l_ret		  
END FUNCTION
############################################################
# END FUNCTION db_orderhead_delete(p_order_num)
############################################################
	

############################################################
# 
# FUNCTION db_orderhead_delete(p_order_num)
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
FUNCTION db_orderhead_rec_validation(p_ui_mode,p_op_mode,p_rec_orderhead)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_op_mode SMALLINT
	DEFINE p_rec_orderhead RECORD LIKE orderhead.*
	DEFINE l_ret SMALLINT
	DEFINE l_msgStr STRING
	DISPLAY "p_ui_mode=", p_ui_mode
	DISPLAY "p_op_mode=", p_op_mode
	CASE p_op_mode
		WHEN MODE_INSERT
			#order_num
			LET l_msgStr = "Can not create record. Order Code already exists"  
			IF db_orderhead_pk_exists(UI_PK,p_op_mode,p_rec_orderhead.order_num) THEN
				RETURN -1 #PK Already exists
			END IF		

			#cust_code
			IF p_rec_orderhead.cust_code IS NULL THEN
				LET l_msgStr =  "Can not create Order record (orderhead) with empty cust_code! Order_Num: ", trim(p_rec_orderhead.order_num)
				IF p_ui_mode > 0 THEN
					ERROR l_msgStr
				END IF				
				RETURN -2
			END IF

		WHEN MODE_UPDATE
			#order_num
			IF NOT db_orderhead_pk_exists(UI_PK,p_op_mode,p_rec_orderhead.order_num) THEN
				LET l_msgStr = "Can not update record. TAP Code does not exist!"  			
				RETURN -1 #PK NOT FOUND
			END IF			

			#cust_code
			IF p_rec_orderhead.cust_code IS NULL THEN
				LET l_msgStr =  "Can not update Order record (orderhead) with empty cust_code! Order_Num: ", trim(p_rec_orderhead.order_num)
				IF p_ui_mode > 0 THEN
					ERROR l_msgStr
				END IF				
				RETURN -2
			END IF
							
		WHEN MODE_DELETE
			#order_num
			IF db_orderhead_pk_exists(UI_PK,p_op_mode,p_rec_orderhead.order_num) THEN
				LET l_msgStr =  "Can not delete Order record (orderhead) which does not exist - order_num: ", trim(p_rec_orderhead.order_num)
				IF p_ui_mode > 0 THEN
					ERROR l_msgStr
				END IF
				RETURN -1 #PK NOT FOUND
			END IF			
	
	END CASE

	RETURN TRUE
	
END FUNCTION	
############################################################
# END FUNCTION db_orderhead_delete(p_order_num)
############################################################