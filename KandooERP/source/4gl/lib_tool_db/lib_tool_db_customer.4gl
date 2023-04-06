##############################################################################################
#TABLE invoicehead
##############################################################################################

##########################################################
# GLOBAL Scope Variables
##########################################################
GLOBALS "../common/glob_GLOBALS.4gl"
##########################################################
# MODULE Scope Variables
##########################################################
CONSTANT DB_TABLE STRING = "Customer"
CONSTANT DB_PK STRING = "Customer Code"
CONSTANT DB_RECORD STRING = "Customer"

############################################################
# FUNCTION db_customer_pk_exists(p_ui_mode,p_op_mode,p_cust_code)
#
# Validate PK - Unique
############################################################
#	CONSTANT UI_OFF SMALLINT = 0
#	CONSTANT UI_ON SMALLINT = 1
#	CONSTANT UI_FK SMALLINT = 2
#	CONSTANT UI_PK SMALLINT = 3
############################################################
FUNCTION db_customer_pk_exists(p_ui_mode,p_op_mode,p_cust_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_op_mode SMALLINT	
	DEFINE p_cust_code LIKE customer.cust_code
	DEFINE ret BOOLEAN
	DEFINE recCount INT
	DEFINE msgStr STRING

	IF p_cust_code IS NULL THEN
		ERROR lib_tool_db_get_msg_NULL(p_ui_mode,NULL,DB_RECORD)
		RETURN FALSE
	END IF

	SELECT count(*) 
	INTO recCount 
	FROM customer 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code				
	AND customer.cust_code = p_cust_code
	AND customer.delete_flag != "Y"  
		
	IF recCount > 0 THEN
		LET ret = TRUE	
		
		--CALL lib_tool_db_get_message(p_ui_mode,p_op_mode,DB_TABLE,p_column,p_val1,p_val2)
		
		CASE p_op_mode
			WHEN MODE_INSERT
				CASE p_ui_mode
					WHEN UI_PK
						ERROR "Customer Code already exists! (", trim(p_cust_code), ")"
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
						ERROR "Customer Code does not exist! (", trim(p_cust_code), ")"
					OTHERWISE
						#No MESSAGE
				END CASE
			
			WHEN MODE_DELETE
				CASE p_ui_mode
					WHEN UI_PK
						#No MESSAGE
					WHEN UI_FK
						ERROR "Customer Code does not exist! (", trim(p_cust_code), ")"
					OTHERWISE
						#No MESSAGE
				END CASE

			WHEN MODE_SELECT
				CASE p_ui_mode
					WHEN UI_OFF
						#No MESSAGE
					WHEN UI_ON
						ERROR "Customer Code does not exist! (", trim(p_cust_code), ")"
					WHEN UI_PK
						#No MESSAGE
					WHEN UI_FK
						ERROR "Customer Code does not exist! (", trim(p_cust_code), ")"
					OTHERWISE
						#No MESSAGE
				END CASE

			OTHERWISE
				CASE p_ui_mode
					WHEN UI_OFF
						#No MESSAGE
					WHEN UI_ON
						ERROR "Customer Code does not exist! (", trim(p_cust_code), ")"
					WHEN UI_PK
						#No MESSAGE
					WHEN UI_FK
						ERROR "Customer Code does not exist! (", trim(p_cust_code), ")"
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
						ERROR "Customer Code does not exist! (", trim(p_cust_code), ")"
					OTHERWISE
						#No MESSAGE
				END CASE

			WHEN MODE_UPDATE
				CASE p_ui_mode
					WHEN UI_PK
						ERROR "Customer Code does not exist! (", trim(p_cust_code), ")"
					WHEN UI_FK
						#No MESSAGE
					OTHERWISE
						#No MESSAGE
				END CASE

			WHEN MODE_DELETE
				CASE p_ui_mode
					WHEN UI_PK
						ERROR "Customer Code does not exist! (", trim(p_cust_code), ")"
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
# END FUNCTION db_customer_pk_exists(p_ui_mode,p_op_mode,p_cust_code)
############################################################


############################################################
# FUNCTION db_customer_get_count()
#
# Return total number of rows in customer 
############################################################
FUNCTION db_customer_get_count()
	DEFINE ret INT

	SELECT count(*) 
	INTO ret 
	FROM customer 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code				
	AND customer.delete_flag != "Y"
			
	RETURN ret
END FUNCTION
############################################################
# END FUNCTION db_customer_get_count()
############################################################


############################################################
# FUNCTION db_customer_get_corp_cust_count(p_corp_cust_code)
#
# Return total number of rows in customer 
############################################################
FUNCTION db_customer_get_corp_cust_count(p_corp_cust_code)
	DEFINE p_corp_cust_code LIKE customer.corp_cust_code
	DEFINE l_ret INT

	SELECT count(*) 
	INTO l_ret 
	FROM customer 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code				
	AND customer.corp_cust_code = p_corp_cust_code
	AND customer.delete_flag != "Y"			
	RETURN l_ret
END FUNCTION
############################################################
# END FUNCTION db_customer_get_corp_cust_count(p_corp_cust_code)
############################################################


############################################################
# FUNCTION db_customer_get_rec(p_ui_mode,p_cust_code)
# RETURN l_rec_customer.*
# Get customer/Part record
############################################################
FUNCTION db_customer_get_rec(p_ui_mode,p_cust_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_cust_code LIKE customer.cust_code
	DEFINE l_rec_customer RECORD LIKE customer.*
	DEFINE l_msg STRING
	
	IF p_cust_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Can not retrieve record with empty Customer Code"
		END IF
		RETURN NULL
	END IF

	SELECT *
	INTO l_rec_customer.*
	FROM customer
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cust_code = p_cust_code
	
	IF sqlca.sqlcode != 0 THEN 
		INITIALIZE l_rec_customer.* TO NULL
		IF p_ui_mode != UI_OFF THEN
			LET l_msg = "Can not retrieve record with Customer Code ", trim(p_cust_code) 
			ERROR l_msg
		END IF
	END IF
	
	RETURN l_rec_customer.*
END FUNCTION
############################################################
# END FUNCTION db_customer_get_rec(p_ui_mode,p_cust_code)
############################################################


############################################################
# FUNCTION db_customer_get_rec(p_ui_mode,p_cust_code)
# RETURN l_rec_customer.*
# Get customer/Part record
############################################################
FUNCTION db_customer_get_rec_not_deleted(p_ui_mode,p_cust_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_cust_code LIKE customer.cust_code
	DEFINE l_rec_customer RECORD LIKE customer.*

	IF p_cust_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Can not retrieve record with empty Customer Code"
		END IF
		RETURN NULL
	END IF

	SELECT *
	INTO l_rec_customer.*
	FROM customer
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code		        
	AND cust_code = p_cust_code
	AND delete_flag = "N"
	
	IF sqlca.sqlcode != 0 THEN   		  
		IF p_ui_mode != UI_OFF THEN
			ERROR "Can not retrieve/find record with Customer Code: ", trim(p_cust_code)
		END IF
		RETURN NULL                                                                                      
	END IF	         

	RETURN l_rec_customer.*		                                                                                                
END FUNCTION	
############################################################
# END FUNCTION db_customer_get_rec(p_ui_mode,p_cust_code)
############################################################


############################################################
# FUNCTION db_customer_get_name_text(p_ui_mode,p_cust_code)
# RETURN l_ret_name_text 
#
# Get description text of Customer record
############################################################
FUNCTION db_customer_get_name_text(p_ui_mode,p_cust_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_cust_code LIKE customer.cust_code
	DEFINE l_ret_name_text LIKE customer.name_text

	IF p_cust_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN	
			ERROR "Customer Code can NOT be empty"
		END IF
			RETURN NULL
	END IF

	SELECT name_text 
	INTO l_ret_name_text 
	FROM customer
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code				 
	AND customer.cust_code = p_cust_code  		
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Customer Description with Code ",trim(p_cust_code),  "NOT found"
		END IF			
		LET l_ret_name_text = NULL
	ELSE
		#
	END IF	
	RETURN l_ret_name_text
END FUNCTION
############################################################
# END FUNCTION db_customer_get_name_text(p_ui_mode,p_cust_code)
############################################################


############################################################
# FUNCTION db_customer_get_corp_cust_code(p_ui_mode,p_cust_code)
# RETURN l_ret_name_text 
#
# Get description text of Product/Part record
############################################################
FUNCTION db_customer_get_corp_cust_code(p_ui_mode,p_cust_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_cust_code LIKE customer.cust_code
	DEFINE l_ret_corp_cust_code LIKE customer.corp_cust_code

	IF p_cust_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Customer Code can NOT be empty"
		END IF
		RETURN NULL
	END IF

	SELECT corp_cust_code 
	INTO l_ret_corp_cust_code
	FROM customer 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code				
	AND customer.cust_code = p_cust_code  		

	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Cooperate Reference with Customer Code ",trim(p_cust_code),  "NOT found"
		END IF
		LET l_ret_corp_cust_code = NULL
	ELSE
		#	                                                                                                
	END IF	

	RETURN l_ret_corp_cust_code	                                                                                                
END FUNCTION
############################################################
# END FUNCTION db_customer_get_corp_cust_code(p_ui_mode,p_cust_code)
############################################################


############################################################
# FUNCTION db_customer_get_addr1_text(p_ui_mode,p_cust_code)
# RETURN l_ret_name_text 
#
# Get description text of customer/Part record
############################################################
FUNCTION db_customer_get_addr1_text(p_ui_mode,p_cust_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_cust_code LIKE customer.cust_code
	DEFINE l_ret_addr1_text LIKE customer.addr1_text

	IF p_cust_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Customer Code can NOT be empty"
		END IF
		RETURN NULL
	END IF

	SELECT addr1_text 
	INTO l_ret_addr1_text
	FROM customer
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code	
	AND customer.cust_code = p_cust_code  		
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Customer Code ",trim(p_cust_code),  "addr1_text NOT found or is empty"
		END IF
		LET l_ret_addr1_text = NULL
	ELSE
		#	                                                                                                
	END IF	

	RETURN l_ret_addr1_text	                                                                                                
END FUNCTION
############################################################
# END FUNCTION db_customer_get_addr1_text(p_ui_mode,p_cust_code)
############################################################


############################################################
# FUNCTION db_customer_get_addr2_text(p_ui_mode,p_cust_code)
# RETURN l_ret_name_text 
#
# Get description text of customer/Part record
############################################################
FUNCTION db_customer_get_addr2_text(p_ui_mode,p_cust_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_cust_code LIKE customer.cust_code
	DEFINE l_ret_addr2_text LIKE customer.addr2_text

	IF p_cust_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Customer Code can NOT be empty"
		END IF
		RETURN NULL
	END IF

	SELECT addr2_text 
	INTO l_ret_addr2_text
	FROM customer
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code	
	AND customer.cust_code = p_cust_code  		
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Customer Code ",trim(p_cust_code),  "addr2_text NOT found or is empty"
		END IF
		LET l_ret_addr2_text = NULL
	ELSE
		#	                                                                                                
	END IF	

	RETURN l_ret_addr2_text	                                                                                                
END FUNCTION
############################################################
# END FUNCTION db_customer_get_addr2_text(p_ui_mode,p_cust_code)
############################################################


############################################################
# FUNCTION db_customer_get_city_text(p_ui_mode,p_cust_code)
# RETURN l_ret_name_text 
#
# Get description text of customer/Part record
############################################################
FUNCTION db_customer_get_city_text(p_ui_mode,p_cust_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_cust_code LIKE customer.cust_code
	DEFINE l_ret_city_text LIKE customer.city_text

	IF p_cust_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Customer Code can NOT be empty"
		END IF
		RETURN NULL
	END IF

	SELECT city_text 
	INTO l_ret_city_text
	FROM customer
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code	
	AND customer.cust_code = p_cust_code  		
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Customer Code ",trim(p_cust_code),  "city_text NOT found or is empty"
		END IF
		LET l_ret_city_text = NULL
	ELSE
		#	                                                                                                
	END IF	

	RETURN l_ret_city_text	                                                                                                
END FUNCTION
############################################################
# END FUNCTION db_customer_get_city_text(p_ui_mode,p_cust_code)
############################################################


############################################################
# FUNCTION db_customer_get_state_code(p_ui_mode,p_cust_code)
# RETURN l_ret_name_text 
#
# Get description text of customer/Part record
############################################################
FUNCTION db_customer_get_state_code(p_ui_mode,p_cust_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_cust_code LIKE customer.cust_code
	DEFINE l_ret_state_code LIKE customer.state_code

	IF p_cust_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Customer Code can NOT be empty"
		END IF
		RETURN NULL
	END IF

	SELECT state_code 
	INTO l_ret_state_code
	FROM customer
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code	
	AND customer.cust_code = p_cust_code  		
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Customer Code ",trim(p_cust_code),  "state_code NOT found or is empty"
		END IF
		LET l_ret_state_code = NULL
	ELSE
		#	                                                                                                
	END IF	

	RETURN l_ret_state_code	                                                                                                
END FUNCTION
############################################################
# END FUNCTION db_customer_get_state_code(p_ui_mode,p_cust_code)
############################################################



############################################################
# FUNCTION db_customer_get_post_code(p_ui_mode,p_cust_code)
# RETURN l_ret_name_text 
#
# Get description text of customer/Part record
############################################################
FUNCTION db_customer_get_post_code(p_ui_mode,p_cust_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_cust_code LIKE customer.cust_code
	DEFINE l_ret_post_code LIKE customer.post_code

	IF p_cust_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Customer Code can NOT be empty"
		END IF
		RETURN NULL
	END IF

	SELECT post_code 
	INTO l_ret_post_code
	FROM customer
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code	
	AND customer.cust_code = p_cust_code  		
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Customer Code ",trim(p_cust_code),  "post_code NOT found or is empty"
		END IF
		LET l_ret_post_code = NULL
	ELSE
		#	                                                                                                
	END IF	

	RETURN l_ret_post_code	                                                                                                
END FUNCTION
############################################################
# END FUNCTION db_customer_get_post_code(p_ui_mode,p_cust_code)
############################################################


############################################################
# FUNCTION db_customer_get_country_code(p_ui_mode,p_cust_code)
# RETURN l_ret_name_text 
#
# Get country code of customer
############################################################
FUNCTION db_customer_get_country_code(p_ui_mode,p_cust_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_cust_code LIKE customer.cust_code
	DEFINE l_ret_country_code LIKE customer.country_code

	IF p_cust_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Customer Code can NOT be empty"
		END IF
		RETURN NULL
	END IF

	SELECT country_code 
	INTO l_ret_country_code
	FROM customer
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code	
	AND customer.cust_code = p_cust_code  		
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Customer Code ",trim(p_cust_code),  "country_code NOT found or is empty"
		END IF
		LET l_ret_country_code = NULL
	ELSE
		#	                                                                                                
	END IF	

	RETURN l_ret_country_code	                                                                                                
END FUNCTION
############################################################
# END FUNCTION db_customer_get_country_code(p_ui_mode,p_cust_code)
############################################################


############################################################
# FUNCTION db_customer_get_country_text(p_ui_mode,p_cust_code)
# RETURN l_ret_name_text 
#
# Get description text of customer/Part record
############################################################
FUNCTION db_customer_get_country_text(p_ui_mode,p_cust_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_cust_code LIKE customer.cust_code
	DEFINE l_ret_country_text LIKE country.country_text

	IF p_cust_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Customer Code can NOT be empty"
		END IF
		RETURN NULL
	END IF

	SELECT country.country_text 
	INTO l_ret_country_text
	FROM country, customer
	WHERE customer.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND customer.cust_code = p_cust_code 
	AND country.country_code = customer.country_code
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Customer Code ",trim(p_cust_code),  "country_text NOT found or is empty"
		END IF
		LET l_ret_country_text = NULL
	ELSE
		#	                                                                                                
	END IF	

	RETURN l_ret_country_text	                                                                                                
END FUNCTION
############################################################
# END FUNCTION db_customer_get_country_text(p_ui_mode,p_cust_code)
############################################################


############################################################
# FUNCTION db_customer_get_hold_code(p_ui_mode,p_cust_code)
# RETURN l_ret_name_text 
#
# Get description text of customer/Part record
############################################################
FUNCTION db_customer_get_hold_code(p_ui_mode,p_cust_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_cust_code LIKE customer.cust_code
	DEFINE l_ret_hold_code LIKE customer.hold_code

	IF p_cust_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Customer Code can NOT be empty"
		END IF
		RETURN NULL
	END IF

	SELECT hold_code 
	INTO l_ret_hold_code
	FROM customer
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code	
	AND customer.cust_code = p_cust_code  		
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Customer Code ",trim(p_cust_code),  "hold_code NOT found or is empty"
		END IF
		LET l_ret_hold_code = NULL
	ELSE
		#	                                                                                                
	END IF	

	RETURN l_ret_hold_code	                                                                                                
END FUNCTION
############################################################
# END FUNCTION db_customer_get_hold_code(p_ui_mode,p_cust_code)
############################################################


############################################################
# FUNCTION db_customer_get_tax_code(p_ui_mode,p_cust_code)
# RETURN l_ret_name_text 
#
# Get customers default tax-code
############################################################
FUNCTION db_customer_get_tax_code(p_ui_mode,p_cust_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_cust_code LIKE customer.cust_code
	DEFINE l_ret_tax_code LIKE customer.tax_code

	IF p_cust_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Customer Code can NOT be empty"
		END IF
		RETURN NULL
	END IF

	SELECT tax_code 
	INTO l_ret_tax_code
	FROM customer
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code	
	AND customer.cust_code = p_cust_code  		
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Customer Code ",trim(p_cust_code),  "tax_code NOT found or is empty"
		END IF
		LET l_ret_tax_code = NULL
	ELSE
		#	                                                                                                
	END IF	

	RETURN l_ret_tax_code	                                                                                                
END FUNCTION
############################################################
# END FUNCTION db_customer_get_tax_code(p_ui_mode,p_cust_code)
############################################################


############################################################
# FUNCTION db_customer_get_currency_code(p_ui_mode,p_cust_code)
# RETURN l_ret_name_text 
#
# Get description text of customer/Part record
############################################################
FUNCTION db_customer_get_currency_code(p_ui_mode,p_cust_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_cust_code LIKE customer.cust_code
	DEFINE l_ret_currency_code LIKE customer.currency_code

	IF p_cust_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Customer Code can NOT be empty"
		END IF
		RETURN NULL
	END IF

	SELECT currency_code 
	INTO l_ret_currency_code
	FROM customer
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code	
	AND customer.cust_code = p_cust_code  		
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Customer Code ",trim(p_cust_code),  "currency_code NOT found or is empty"
		END IF
		LET l_ret_currency_code = NULL
	ELSE
		#	                                                                                                
	END IF	

	RETURN l_ret_currency_code	                                                                                                
END FUNCTION
############################################################
# END FUNCTION db_customer_get_currency_code(p_ui_mode,p_cust_code)
############################################################


############################################################
# FUNCTION db_customer_get_curr_amt(p_ui_mode,p_cust_code)
# RETURN l_ret_name_text 
#
# Get description text of customer/Part record
############################################################
FUNCTION db_customer_get_curr_amt(p_ui_mode,p_cust_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_cust_code LIKE customer.cust_code
	DEFINE l_ret_curr_amt LIKE customer.curr_amt

	IF p_cust_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Customer Code can NOT be empty"
		END IF
		RETURN NULL
	END IF

	SELECT curr_amt 
	INTO l_ret_curr_amt
	FROM customer
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code	
	AND customer.cust_code = p_cust_code  		
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Customer Code ",trim(p_cust_code),  "curr_amt NOT found or is empty"
		END IF
		LET l_ret_curr_amt = NULL
	ELSE
		#	                                                                                                
	END IF	

	RETURN l_ret_curr_amt	                                                                                                
END FUNCTION
############################################################
# END FUNCTION db_customer_get_curr_amt(p_ui_mode,p_cust_code)
############################################################


############################################################
# FUNCTION db_customer_get_over1_amt(p_ui_mode,p_cust_code)
# RETURN l_ret_name_text 
#
# Get description text of customer/Part record
############################################################
FUNCTION db_customer_get_over1_amt(p_ui_mode,p_cust_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_cust_code LIKE customer.cust_code
	DEFINE l_ret_over1_amt LIKE customer.over1_amt

	IF p_cust_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Customer Code can NOT be empty"
		END IF
		RETURN NULL
	END IF

	SELECT over1_amt 
	INTO l_ret_over1_amt
	FROM customer
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code	
	AND customer.cust_code = p_cust_code  		
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Customer Code ",trim(p_cust_code),  "over1_amt NOT found or is empty"
		END IF
		LET l_ret_over1_amt = NULL
	ELSE
		#	                                                                                                
	END IF	

	RETURN l_ret_over1_amt	                                                                                                
END FUNCTION
############################################################
# END FUNCTION db_customer_get_over1_amt(p_ui_mode,p_cust_code)
############################################################


############################################################
# FUNCTION db_customer_over30_amt(p_ui_mode,p_cust_code)
# RETURN l_ret_name_text 
#
# Get description text of customer/Part record
############################################################
FUNCTION db_customer_over30_amt(p_ui_mode,p_cust_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_cust_code LIKE customer.cust_code
	DEFINE l_ret_over30_amt LIKE customer.over30_amt

	IF p_cust_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Customer Code can NOT be empty"
		END IF
		RETURN NULL
	END IF

	SELECT over30_amt 
	INTO l_ret_over30_amt
	FROM customer
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code	
	AND customer.cust_code = p_cust_code  		
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Customer Code ",trim(p_cust_code),  "over30_amt NOT found or is empty"
		END IF
		LET l_ret_over30_amt = NULL
	ELSE
		#	                                                                                                
	END IF	

	RETURN l_ret_over30_amt	                                                                                                
END FUNCTION
############################################################
# END FUNCTION db_customer_over30_amt(p_ui_mode,p_cust_code)
############################################################


############################################################
# FUNCTION db_customer_over60_amt(p_ui_mode,p_cust_code)
# RETURN l_ret_name_text 
#
# Get description text of customer/Part record
############################################################
FUNCTION db_customer_over60_amt(p_ui_mode,p_cust_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_cust_code LIKE customer.cust_code
	DEFINE l_ret_over60_amt LIKE customer.over60_amt

	IF p_cust_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Customer Code can NOT be empty"
		END IF
		RETURN NULL
	END IF

	SELECT over60_amt 
	INTO l_ret_over60_amt
	FROM customer
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code	
	AND customer.cust_code = p_cust_code  		
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Customer Code ",trim(p_cust_code),  "over60_amt NOT found or is empty"
		END IF
		LET l_ret_over60_amt = NULL
	ELSE
		#	                                                                                                
	END IF	

	RETURN l_ret_over60_amt	                                                                                                
END FUNCTION
############################################################
# END FUNCTION db_customer_over60_amt(p_ui_mode,p_cust_code)
############################################################


############################################################
# FUNCTION db_customer_bal_amt(p_ui_mode,p_cust_code)
# RETURN l_ret_name_text 
#
# Get description text of customer/Part record
############################################################
FUNCTION db_customer_bal_amt(p_ui_mode,p_cust_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_cust_code LIKE customer.cust_code
	DEFINE l_ret_bal_amt LIKE customer.bal_amt

	IF p_cust_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Customer Code can NOT be empty"
		END IF
		RETURN NULL
	END IF

	SELECT bal_amt 
	INTO l_ret_bal_amt
	FROM customer
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code	
	AND customer.cust_code = p_cust_code  		
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Customer Code ",trim(p_cust_code),  "bal_amt NOT found or is empty"
		END IF
		LET l_ret_bal_amt = NULL
	ELSE
		#	                                                                                                
	END IF	

	RETURN l_ret_bal_amt	                                                                                                
END FUNCTION
############################################################
# END FUNCTION db_customer_bal_amt(p_ui_mode,p_cust_code)
############################################################


############################################################
# FUNCTION db_customer_get_cred_limit_amt(p_ui_mode,p_cust_code)
# RETURN l_ret_name_text 
#
# Get description text of customer/Part record
############################################################
FUNCTION db_customer_get_cred_limit_amt(p_ui_mode,p_cust_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_cust_code LIKE customer.cust_code
	DEFINE l_ret_cred_limit_amt LIKE customer.cred_limit_amt

	IF p_cust_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Customer Code can NOT be empty"
		END IF
		RETURN NULL
	END IF
	
	SELECT cred_limit_amt 
	INTO l_ret_cred_limit_amt
	FROM customer
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code	
	AND customer.cust_code = p_cust_code  		
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Customer Code ",trim(p_cust_code),  "cred_limit_amt NOT found or is empty"
		END IF
		LET l_ret_cred_limit_amt = NULL
	ELSE
		#	                                                                                                
	END IF	

	RETURN l_ret_cred_limit_amt	                                                                                                
END FUNCTION
############################################################
# END FUNCTION db_customer_get_cred_limit_amt(p_ui_mode,p_cust_code)
############################################################


############################################################
# FUNCTION db_customer_get_delete_flag(p_ui_mode,p_cust_code)
# RETURN l_ret_name_text 
#
# Get description text of customer/Part record
############################################################
FUNCTION db_customer_get_delete_flag(p_ui_mode,p_cust_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_cust_code LIKE customer.cust_code
	DEFINE l_ret_delete_flag LIKE customer.delete_flag

	IF p_cust_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Customer Code can NOT be empty"
		END IF
		RETURN NULL
	END IF
	
	SELECT delete_flag 
	INTO l_ret_delete_flag
	FROM customer
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code	
	AND customer.cust_code = p_cust_code  		
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Customer Code ",trim(p_cust_code),  "delete_flag NOT found or is empty"
		END IF
		LET l_ret_delete_flag = NULL
	ELSE
		#	                                                                                                
	END IF	

	RETURN l_ret_delete_flag	                                                                                                
END FUNCTION
############################################################
# END FUNCTION db_customer_get_delete_flag(p_ui_mode,p_cust_code)
############################################################


{
############################################################
# FUNCTION db_customer_bal_amt(p_ui_mode,p_cust_code)
# RETURN l_ret_name_text 
#
# Get description text of customer/Part record
############################################################
FUNCTION db_customer_bal_amt(p_ui_mode,p_cust_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_cust_code LIKE customer.cust_code
	DEFINE l_ret_bal_amt LIKE customer.bal_amt

	IF p_cust_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Customer Code can NOT be empty"
		END IF
		RETURN NULL
	END IF

	
			SELECT bal_amt 
			INTO l_ret_bal_amt
			FROM customer
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code	
			AND customer.cust_code = p_cust_code  		
	
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Customer Code ",trim(p_cust_code),  "bal_amt NOT found or is empty"
		END IF
		LET l_ret_bal_amt = NULL
	ELSE
		#	                                                                                                
	END IF	

	RETURN l_ret_bal_amt	                                                                                                
END FUNCTION
############################################################
# END FUNCTION db_customer_bal_amt(p_ui_mode,p_cust_code)
############################################################


}


############################################################
# FUNCTION db_customer_onorder_amt(p_ui_mode,p_cust_code)
# RETURN l_ret_name_text 
#
# Get description text of customer/Part record
############################################################
FUNCTION db_customer_onorder_amt(p_ui_mode,p_cust_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_cust_code LIKE customer.cust_code
	DEFINE l_ret_onorder_amt LIKE customer.onorder_amt

	IF p_cust_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Customer Code can NOT be empty"
		END IF
		RETURN NULL
	END IF

	SELECT onorder_amt 
	INTO l_ret_onorder_amt
	FROM customer
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code	
	AND customer.cust_code = p_cust_code  		
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Customer Code ",trim(p_cust_code),  "onorder_amt NOT found or is empty"
		END IF
		LET l_ret_onorder_amt = NULL
	ELSE
		#	                                                                                                
	END IF	

	RETURN l_ret_onorder_amt	                                                                                                
END FUNCTION
############################################################
# END FUNCTION db_customer_onorder_amt(p_ui_mode,p_cust_code)
############################################################


############################################################
# FUNCTION db_customer_over90_amt(p_ui_mode,p_cust_code)
# RETURN l_ret_name_text 
#
# Get description text of customer/Part record
############################################################
FUNCTION db_customer_over90_amt(p_ui_mode,p_cust_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_cust_code LIKE customer.cust_code
	DEFINE l_ret_over90_amt LIKE customer.over90_amt

	IF p_cust_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Customer Code can NOT be empty"
		END IF
		RETURN NULL
	END IF

	SELECT over90_amt 
	INTO l_ret_over90_amt
	FROM customer
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code	
	AND customer.cust_code = p_cust_code  		
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Customer Code ",trim(p_cust_code),  "over90_amt NOT found or is empty"
		END IF
		LET l_ret_over90_amt = NULL
	ELSE
		#	                                                                                                
	END IF	

	RETURN l_ret_over90_amt	                                                                                                
END FUNCTION
############################################################
# END FUNCTION db_customer_over90_amt(p_ui_mode,p_cust_code)
############################################################


{
############################################################
# FUNCTION db_customer_get_cat_code(p_ui_mode,p_cust_code)
# RETURN l_ret_name_text 
#
# Get description text of Product/Part record
############################################################
FUNCTION db_customer_get_cat_code(p_ui_mode,p_cust_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_cust_code LIKE customer.cust_code
	DEFINE l_ret_cat_code LIKE customer.cat_code

	IF p_cust_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Customer Code can NOT be empty"
		END IF
		RETURN NULL
	END IF

			SELECT cat_code 
			INTO l_ret_cat_code
			FROM customer
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code				 
			AND customer.cust_code = p_cust_code  		
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Customer Code ",trim(p_cust_code),  "NOT found"
		END IF
		LET l_ret_cat_code = NULL
	ELSE
		#	                                                                                                
	END IF	

	RETURN l_ret_cat_code	                                                                                                
END FUNCTION
############################################################
# END FUNCTION db_customer_get_cat_code(p_ui_mode,p_cust_code)
############################################################


}

########################################################################################################################
# 
# Get Array record data from DB
#
########################################################################################################################

############################################################
# FUNCTION db_customer_get_arr_rec(p_query_text)
#
#
############################################################
FUNCTION db_customer_get_arr_rec(p_query_type,p_query_or_where_text)
	DEFINE p_query_type SMALLINT
	DEFINE p_query_or_where_text STRING
	DEFINE l_query_text STRING
	DEFINE l_where_text STRING
	DEFINE l_arr_rec_customer DYNAMIC ARRAY OF RECORD LIKE customer.*		
	DEFINE l_rec_customer RECORD LIKE customer.*
	DEFINE l_idx SMALLINT

	IF p_query_type = FILTER_QUERY_WHERE AND p_query_or_where_text IS NULL THEN
		LET p_query_or_where_text = " 1=1 "
	END IF
		
	#p_query_text is optional
	CASE p_query_type
		WHEN FILTER_QUERY_OFF
			LET l_query_text = 
				"SELECT * FROM customer ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ",					
				"ORDER BY customer.cust_code" 	

		WHEN FILTER_QUERY_WHERE
			LET l_where_text = p_query_or_where_text
			LET l_query_text = 
				"SELECT * FROM customer ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ",					
				"AND ", l_where_text clipped," ",
				"ORDER BY customer.cust_code" 	

		WHEN FILTER_QUERY_SELECT
			LET l_query_text = p_query_or_where_text		
		
		OTHERWISE
			LET l_query_text = 
				"SELECT * FROM customer ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ",					
				"ORDER BY customer.cust_code" 				
	END CASE

	PREPARE s_customer FROM l_query_text
	DECLARE c_customer CURSOR FOR s_customer


	LET l_idx = 0
	FOREACH c_customer INTO l_arr_rec_customer[l_idx].*
      LET l_idx = l_idx + 1

	END FOREACH

	IF sqlca.sqlcode < 0 THEN   	
		LET l_arr_rec_customer = NULL	                                                                                        
	ELSE		                                                                                                                    
		#		                                                                                                
	END IF	         

	RETURN l_arr_rec_customer		                                                                                                
END FUNCTION
############################################################
# END FUNCTION db_customer_get_arr_rec(p_query_text)
############################################################


{
############################################################
# FUNCTION db_customer_get_arr_rec_ac_dt_ac_with_scrollflag(p_query_type,p_query_or_where_text)
#
#
############################################################
FUNCTION db_customer_get_arr_rec_ac_dt_ac_with_scrollflag(p_query_type,p_query_or_where_text)
	DEFINE p_query_type SMALLINT
	DEFINE p_query_or_where_text VARCHAR(500)
	DEFINE l_query_text STRING
	DEFINE l_where_text STRING
	DEFINE l_arr_rec_customer DYNAMIC ARRAY OF t_rec_customer_ac_dt_ac_with_scrollflag	
	DEFINE l_rec_customer t_rec_customer_ac_dt_ac
	DEFINE l_idx SMALLINT
	
	#p_query_text is optional
	IF p_query_or_where_text IS NULL THEN
		LET p_query_type = FILTER_QUERY_OFF
	END IF

	CASE p_query_type
		WHEN FILTER_QUERY_OFF
			LET l_query_text = 
				"SELECT cust_code,name_text,corp_cust_code FROM customer ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ",					
				"ORDER BY customer.cust_code" 	


#		WHEN FILTER_QUERY_ON
#			LET l_query_text = p_query_or_where_text

		WHEN FILTER_QUERY_WHERE
			LET l_where_text = p_query_or_where_text
			LET l_query_text = 
				"SELECT cust_code,name_text,corp_cust_code FROM customer ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ",					
				"AND ", l_where_text clipped," ",
				"ORDER BY customer.cust_code" 	

		WHEN FILTER_QUERY_SELECT
			LET l_query_text = p_query_or_where_text		
		
		OTHERWISE
			LET l_query_text = 
				"SELECT cust_code,name_text,corp_cust_code FROM customer ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ",					
				"ORDER BY customer.cust_code" 				
	END CASE

	PREPARE s2_customer FROM l_query_text
	DECLARE c2_customer CURSOR FOR s2_customer


	LET l_idx = 0
	FOREACH c2_customer INTO l_rec_customer.*
		LET l_idx = l_idx + 1
		LET l_arr_rec_customer[l_idx].* = "",l_rec_customer.*
	END FOREACH

	IF sqlca.sqlcode < 0 THEN   	
		LET l_arr_rec_customer = NULL	                                                                                        
	ELSE		                                                                                                                    
		#		                                                                                                
	END IF	         

	RETURN l_arr_rec_customer		                                                                                                
END FUNCTION
############################################################
# END FUNCTION db_customer_get_arr_rec_ac_dt_ac_with_scrollflag(p_query_type,p_query_or_where_text)
############################################################


}



########################################################################################################################
# 
# UPDATE INSERT DELETE row from DB
#
########################################################################################################################


############################################################
# FUNCTION db_customer_update(p_rec_customer)
#
#
############################################################
FUNCTION db_customer_update(p_ui_mode,p_pk_cust_code,p_rec_customer)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_pk_cust_code LIKE customer.cust_code
	DEFINE p_rec_customer RECORD LIKE customer.*
	DEFINE l_ui_mode SMALLINT
	DEFINE ret INT
	DEFINE msgStr STRING
	
	IF p_ui_mode = UI_ON THEN
		LET l_ui_mode = UI_PK
	END IF

	IF p_pk_cust_code IS NULL OR p_rec_customer.cust_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET msgStr = "Customer code can not be empty ! (original Customer Code=",trim(p_pk_cust_code), " / new Customer Code=", trim(p_rec_customer.cust_code), ")"  
			ERROR msgStr
		END IF
		RETURN -1
	END IF
# Needs doing !!!!!!!!!! 	
#	IF db_XXXXXXXX_get_customer_count(p_pk_cust_code) AND (p_pk_cust_code <> p_rec_customer.cust_code) THEN #PK cust_code can only be changed if it's not used already
#		IF p_ui_mode > 0 THEN
#			ERROR "Can not change Customer ! It is already used in a configuration"
#		END IF
#		LET ret =  -1
#	ELSE
	
	UPDATE customer
	SET * = p_rec_customer.*
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code					
	AND cust_code = p_pk_cust_code

	LET ret = status
		
#	END IF

	IF p_ui_mode != UI_OFF THEN #display MESSAGE if ui is enabled
		IF ret < 0 THEN   		
			LET msgStr = "Coud not modify Customer record ! /nOriginal PAT", trim(p_pk_cust_code), "New customer/Part ", trim(p_rec_customer.cust_code),  "\nDatabase Error ", trim(ret)                                                                                        
			#ERROR msgStr 
			CALL fgl_winmessage("Error when trying tCustomerAdjustment Types record",msgStr,"error")
		ELSE
			LET msgStr = "Customer record ", trim(p_rec_customer.cust_code), " updated successfully !"   
			MESSAGE msgStr
		END IF                                           	
	END IF	
	
	RETURN ret
END FUNCTION        
############################################################
# END FUNCTION db_customer_update(p_rec_customer)
############################################################

   
############################################################
# FUNCTION db_customer_insert(p_rec_customer)
#
#
############################################################
FUNCTION db_customer_insert(p_ui_mode,p_rec_customer)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_rec_customer RECORD LIKE customer.*
	DEFINE ret INT
	DEFINE l_ui_mode SMALLINT
	DEFINE msgStr STRING	
	
	IF p_ui_mode = UI_ON THEN
		LET l_ui_mode = UI_PK
	END IF

	IF p_rec_customer.cust_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET msgStr = "Customer code can not be empty ! (PAT=", trim(p_rec_customer.cust_code), ")"  
			ERROR msgStr
		END IF
		RETURN -1
	END IF

	LET p_rec_customer.cmpy_code = glob_rec_kandoouser.cmpy_code
	
	IF db_customer_pk_exists(UI_PK,MODE_INSERT,p_rec_customer.cust_code) THEN
		LET ret = -1
	ELSE
		
			INSERT INTO customer
	    VALUES(p_rec_customer.*)
	    LET ret = status
		
	END IF

	IF p_ui_mode != UI_OFF THEN #display MESSAGE if ui is enabled
		IF ret < 0 THEN   		
			LET msgStr = "Coud not create Customer record ", trim(p_rec_customer.cust_code), " !\nDatabase Error ", trim(ret)                                                                                        
			#ERROR msgStr 
			CALL fgl_winmessage("Error when trying to create/insert Customer record",msgStr,"error")
		ELSE
			LET msgStr = "Customer record ", trim(p_rec_customer.cust_code), " created successfully !"   
			MESSAGE msgStr
		END IF                                           	
	END IF
	
	RETURN ret
END FUNCTION
############################################################
# END FUNCTION db_customer_insert(p_rec_customer)
############################################################


############################################################
# FUNCTION db_customer_delete(p_cust_code)
#
#
############################################################
FUNCTION db_customer_delete(p_ui_mode,p_confirm,p_cust_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_confirm BOOLEAN #is operator requested to confirm this operation / independent of ui mode	
	DEFINE p_cust_code LIKE customer.cust_code
	DEFINE l_msgresp LIKE language.yes_flag	
	DEFINE ret SMALLINT	
	DEFINE msgStr STRING

	IF p_confirm = UI_CONFIRM_ON THEN
		LET msgStr = "Delete Customer configuration ", trim(p_cust_code), " ?"
		IF NOT promptTF("Delete PAT",msgStr,TRUE) THEN
			RETURN -2
		END IF
	END IF
	
	IF p_cust_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET msgStr = "Customer code can not be empty ! (PAT=", trim(p_cust_code), ")"  
			ERROR msgStr
		END IF
		RETURN -1
	END IF
# Needs doing !!!!!!!!!! 
#	IF db_XXXXX_get_customer_count(p_cust_code) THEN #PK cust_code can only be deleted if it's not used already
#		IF p_ui_mode != UI_OFF THEN
#			LET msgStr = "Can not delete Product/Part ! ", trim(p_cust_code), " It is already used in a bank configuration"
#			CALL fgl_winmessage("Can not delete PAT ! ",msgStr,"error")
#		END IF
#		LET ret =  -1
#	ELSE
		

	DELETE FROM customer
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code					
	AND cust_code = p_cust_code

	LET ret = status
		
			
#	END IF
	
	IF p_ui_mode != UI_OFF THEN #display MESSAGE if ui is enabled
		IF ret < 0 THEN   		
			LET msgStr = "Could not delete Customer record ", trim(p_cust_code), " !\nDatabase Error ", trim(ret)                                                                                        
			#ERROR msgStr 
			CALL fgl_winmessage("Error when trying to delete",msgStr,"error")
		ELSE
			LET msgStr = "Customer record ", trim(p_cust_code), " deleted !"   
			MESSAGE msgStr
		END IF                                           	
	END IF		             

	RETURN ret	
		  
END FUNCTION
############################################################
# END FUNCTION db_customer_delete(p_cust_code)
############################################################
	

############################################################
# FUNCTION db_customer_delete(p_cust_code)
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
FUNCTION db_customer_rec_validation(p_ui_mode,p_op_mode,p_rec_customer)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_op_mode SMALLINT
	DEFINE p_rec_customer RECORD LIKE customer.*
	DEFINE l_ret SMALLINT
	DEFINE l_msgStr STRING
	DISPLAY "p_ui_mode=", p_ui_mode
	DISPLAY "p_op_mode=", p_op_mode
	CASE p_op_mode
		WHEN MODE_INSERT
			#cust_code
			LET l_msgStr = "Can not create record. TAP Code already exists"  
			IF db_customer_pk_exists(UI_PK,p_op_mode,p_rec_customer.cust_code) THEN
				RETURN -1 #PK Already exists
			END IF		

			#name_text
			IF p_rec_customer.name_text IS NULL THEN
				LET l_msgStr =  "Can not create PAT record with empty description text - cust_code: ", trim(p_rec_customer.cust_code)
				IF p_ui_mode > 0 THEN
					ERROR l_msgStr
				END IF				
				RETURN -2
			END IF

			#corp_cust_code
			IF NOT db_coa_pk_exists(UI_FK,p_op_mode,p_rec_customer.corp_cust_code) THEN
				LET l_msgStr =  "Can not create PAT record with invalid COA Code: ", trim(p_rec_customer.corp_cust_code)
				IF p_ui_mode > 0 THEN
					ERROR l_msgStr
				END IF
				RETURN -3
			END IF
				
		WHEN MODE_UPDATE
			#cust_code
			IF NOT db_customer_pk_exists(UI_PK,p_op_mode,p_rec_customer.cust_code) THEN
				LET l_msgStr = "Can not update record. TAP Code does not exist!"  			
				RETURN -1 #PK NOT FOUND
			END IF			

			#name_text
			IF p_rec_customer.name_text IS NULL THEN
				LET l_msgStr =  "Can not update PAT record with empty description text - cust_code: ", trim(p_rec_customer.cust_code)
				IF p_ui_mode > 0 THEN
					ERROR l_msgStr
				END IF				
				RETURN -2
			END IF

			#corp_cust_code
			IF NOT db_coa_pk_exists(UI_FK,p_op_mode,p_rec_customer.corp_cust_code) THEN
				LET l_msgStr =  "Can not update PAT record with invalid GL-COA Code: ", trim(p_rec_customer.corp_cust_code)
				IF p_ui_mode > 0 THEN
					ERROR l_msgStr
				END IF
				RETURN -3
			END IF
							
		WHEN MODE_DELETE
			#cust_code
			IF db_customer_pk_exists(UI_PK,p_op_mode,p_rec_customer.cust_code) THEN
				LET l_msgStr =  "Can not delete PAT record which does not exist - cust_code: ", trim(p_rec_customer.cust_code)
				IF p_ui_mode > 0 THEN
					ERROR l_msgStr
				END IF
				RETURN -1 #PK NOT FOUND
			END IF			
	
	END CASE

	RETURN TRUE
	
END FUNCTION	
############################################################
# END FUNCTION db_customer_delete(p_cust_code)
############################################################