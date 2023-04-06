########################################################################################################################
# TABLE product
#
#
########################################################################################################################
##########################################################
# GLOBAL Scope Variables
##########################################################
GLOBALS "../common/glob_GLOBALS.4gl"
GLOBALS "../common/glob_GLOBALS_userDataTypes.4gl"
############################################################
# FUNCTION db_product_pk_exists(p_ui,p_part_code)
#
# Validate PK - Unique
############################################################
#	CONSTANT UI_OFF SMALLINT = 0
#	CONSTANT UI_ON SMALLINT = 1
#	CONSTANT UI_FK SMALLINT = 2
#	CONSTANT UI_PK SMALLINT = 3
############################################################
FUNCTION db_product_pk_exists(p_ui,p_part_code)
	DEFINE p_ui SMALLINT
	DEFINE p_part_code LIKE product.part_code
	DEFINE ret BOOLEAN
	DEFINE recCount INT
	DEFINE msgStr STRING

	IF p_part_code IS NULL THEN
		IF p_ui != UI_OFF THEN
			ERROR "Product/Part Code can not be empty"
			#LET msgresp = kandoomsg("G",9178,"")
			#9178 Bank/State/Branchs must NOT be NULL
		END IF
		RETURN FALSE
	END IF

	SELECT COUNT(*) INTO recCount FROM product 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code	AND 
	      product.part_code = p_part_code  
		
	IF recCount <> 0 THEN
		LET ret = TRUE	
		IF p_ui = UI_ON THEN
			MESSAGE "Product/Part Code exists! (", trim(p_part_code), ")"
		END IF
		IF p_ui = UI_PK THEN
			MESSAGE "Product/Part Code already exists! (", trim(p_part_code), ")"
		END IF
	ELSE
		LET ret = FALSE	
		IF p_ui = UI_FK THEN
			MESSAGE "Product/Part Code does not exists! (", trim(p_part_code), ")"
		END IF
	END IF
	
	RETURN ret
END FUNCTION
############################################################
# END FUNCTION db_product_pk_exists(p_ui,p_part_code)
############################################################


############################################################
# FUNCTION db_product_get_count()
#
# Return total number of rows in product 
############################################################
FUNCTION db_product_get_count()
	DEFINE ret INT

	SELECT COUNT(*) INTO ret FROM product 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code				
			
	RETURN ret
END FUNCTION
############################################################
# END FUNCTION db_product_get_count()
############################################################


############################################################
# FUNCTION db_product_get_count(p_class_code)
#
# Return total number of rows in product 
############################################################
FUNCTION db_product_get_class_count(p_class_code)
	DEFINE p_class_code LIKE product.class_code
	DEFINE ret INT

	SELECT COUNT(*) INTO ret FROM product 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code	AND 
	      product.class_code = p_class_code
			
	RETURN ret
END FUNCTION
############################################################
# END FUNCTION db_product_get_count(p_class_code)
############################################################


############################################################
# FUNCTION db_product_get_rec(p_ui_mode,p_part_code)
# RETURN l_rec_product.*
# Get Product/Part record
############################################################
FUNCTION db_product_get_rec(p_ui_mode,p_part_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_part_code LIKE product.part_code
	DEFINE l_rec_product RECORD LIKE product.*
	DEFINE l_msg STRING
	
	IF p_part_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Can not retrieve record with empty Product/Part code"
		END IF
		RETURN NULL
	END IF

	SELECT * INTO l_rec_product.* FROM product
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = p_part_code
	
	IF sqlca.sqlcode != 0 THEN 
		INITIALIZE l_rec_product.* TO NULL 
		IF p_ui_mode != UI_OFF THEN
			--LET l_msg = "Product with Part Code: ", trim(p_part_code), " not found"			
			--ERROR l_msg
			ERROR kandoomsg2("I",5010,p_part_code)	#5010" Logic Error: product NOT found"
		END IF
	END IF 

	RETURN l_rec_product.* 
END FUNCTION	
############################################################
# END FUNCTION db_product_get_rec(p_ui_mode,p_part_code)
############################################################


############################################################
# FUNCTION db_product_get_desc_text(p_ui_mode,p_part_code)
# RETURN l_ret_desc_text 
#
# Get description text of Product/Part record
############################################################
FUNCTION db_product_get_desc_text(p_ui_mode,p_part_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_part_code LIKE product.part_code
	DEFINE l_ret_desc_text LIKE product.desc_text

	IF p_part_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN	
			ERROR "Product/Part Code can NOT be empty"
		END IF
			RETURN NULL
	END IF

	SELECT desc_text INTO l_ret_desc_text FROM product
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
	      product.part_code = p_part_code  		
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Product/Part Description with Code ",trim(p_part_code),  "NOT found"
		END IF			
		LET l_ret_desc_text = NULL
	ELSE
	END IF	
	RETURN l_ret_desc_text
END FUNCTION
############################################################
# END FUNCTION db_product_get_desc_text(p_ui_mode,p_part_code)
############################################################


############################################################
# FUNCTION db_product_get_desc2_text(p_ui_mode,p_part_code)
# RETURN l_ret_desc_text 
#
# Get description text of Product/Part record
############################################################
FUNCTION db_product_get_desc2_text(p_ui_mode,p_part_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_part_code LIKE product.part_code
	DEFINE l_ret_desc2_text LIKE product.desc2_text

	IF p_part_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Product/Part Code can NOT be empty"
		END IF
		RETURN NULL
	END IF

	SELECT desc2_text	INTO l_ret_desc2_text FROM product 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
	      product.part_code = p_part_code  		
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Product/Part Bank Reference with Product/Part Code ",trim(p_part_code),  "NOT found"
		END IF
		LET l_ret_desc2_text = NULL
	ELSE
	END IF	

	RETURN l_ret_desc2_text	                                                                                                
END FUNCTION
############################################################
# END FUNCTION db_product_get_desc2_text(p_ui_mode,p_part_code)
############################################################


############################################################
# FUNCTION db_product_get_cat_code(p_ui_mode,p_part_code)
# RETURN l_ret_desc_text 
#
# Get description text of Product/Part record
############################################################
FUNCTION db_product_get_cat_code(p_ui_mode,p_part_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_part_code LIKE product.part_code
	DEFINE l_ret_cat_code LIKE product.cat_code

	IF p_part_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Product/Part Code can NOT be empty"
		END IF
		RETURN NULL
	END IF

	SELECT cat_code INTO l_ret_cat_code	FROM product
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code	AND 
	      product.part_code = p_part_code  		
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Product/Part Bank Reference with Product/Part Code ",trim(p_part_code),  "NOT found"
		END IF
		LET l_ret_cat_code = NULL
	ELSE
	END IF	

	RETURN l_ret_cat_code	                                                                                                
END FUNCTION
############################################################
# END FUNCTION db_product_get_cat_code(p_ui_mode,p_part_code)
############################################################


############################################################
# FUNCTION db_product_get_serial_flag(p_ui_mode,p_part_code)
# RETURN l_ret_desc_text 
#
# Get the serial_flag Y/N from the warehouse product
############################################################
FUNCTION db_product_get_serial_flag(p_ui_mode,p_part_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_part_code LIKE product.part_code
	DEFINE l_ret_serial_flag LIKE product.serial_flag

	IF p_part_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Product/Part Code can NOT be empty"
		END IF
		RETURN NULL
	END IF

	SELECT serial_flag INTO l_ret_serial_flag	FROM product
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code				 
	AND product.part_code = p_part_code  		
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Product/Part Bank Reference with Product/Part Code ",trim(p_part_code),  "NOT found"
		END IF
		LET l_ret_serial_flag = NULL
	ELSE
	END IF	

	RETURN l_ret_serial_flag	                                                                                                
END FUNCTION
############################################################
# END FUNCTION db_product_get_serial_flag(p_ui_mode,p_part_code)
############################################################


########################################################################################################################
# 
# Get Array record data from DB
#
########################################################################################################################

############################################################
# FUNCTION db_product_get_arr_rec(p_query_text)
#
#
############################################################
FUNCTION db_product_get_arr_rec(p_query_type,p_query_or_where_text)
	DEFINE p_query_type SMALLINT
	DEFINE p_query_or_where_text VARCHAR(500)
	DEFINE l_query_text VARCHAR(500)
	DEFINE l_where_text VARCHAR(500)
	DEFINE l_arr_rec_product DYNAMIC ARRAY OF RECORD LIKE product.*		
	DEFINE l_rec_product RECORD LIKE product.*
	DEFINE l_idx SMALLINT
	
	#p_query_text is optional
	CASE p_query_type
		WHEN FILTER_QUERY_OFF
			LET l_query_text = 
				"SELECT * FROM product ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ",					
				"ORDER BY product.part_code" 	


#		WHEN FILTER_QUERY_ON
#			LET l_query_text = p_query_or_where_text

		WHEN FILTER_QUERY_WHERE
			LET l_where_text = p_query_or_where_text
			LET l_query_text = 
				"SELECT * FROM product ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ",					
				"AND ", l_where_text clipped," ",
				"ORDER BY product.part_code" 	

		WHEN FILTER_QUERY_SELECT
			LET l_query_text = p_query_or_where_text		
		
		OTHERWISE
			LET l_query_text = 
				"SELECT * FROM product ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ",					
				"ORDER BY product.part_code" 				
	END CASE

	PREPARE s_product FROM l_query_text
	DECLARE c_product CURSOR FOR s_product


	LET l_idx = 0
	FOREACH c_product INTO l_arr_rec_product[l_idx].*
      LET l_idx = l_idx + 1

	END FOREACH

	IF sqlca.sqlcode < 0 THEN   	
		LET l_arr_rec_product = NULL	                                                                                        
	ELSE		                                                                                                                    
		#		                                                                                                
	END IF	         

	RETURN l_arr_rec_product		                                                                                                
END FUNCTION
############################################################
# END FUNCTION db_product_get_arr_rec(p_query_text)
############################################################


############################################################
# FUNCTION db_product_get_alter_arr_rec(p_group_type)
#
# Need this for the alternative product configuration
############################################################
FUNCTION db_product_get_alter_arr_rec(p_group_type, p_ingroup_code)
	DEFINE p_group_type CHAR
	DEFINE p_ingroup_code LIKE ingroup.ingroup_code
	DEFINE l_query_text VARCHAR(2200)
	DEFINE idx SMALLINT
	DEFINE l_arr_rec_product DYNAMIC ARRAY OF t_rec_product_alter_p_d
	DEFINE pr_product RECORD LIKE product.*	

	CASE
	   WHEN p_group_type = "A"
         # Alternate Product Group
         LET l_query_text = "SELECT * FROM product ",
                            "WHERE alter_part_code='",p_ingroup_code,"' AND ",
                                  "cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ",
                            "ORDER BY part_code "	   
	   WHEN p_group_type = "S"
         # Superseded Product Group
         LET l_query_text = "SELECT * FROM product ",
                            "WHERE super_part_code ='",p_ingroup_code,"' AND ",
                                  "cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ",
                            "ORDER BY part_code "	   
	   WHEN p_group_type = "C"
         # Companion Product Group
         LET l_query_text = "SELECT * FROM product ",
                            "WHERE compn_part_code ='",p_ingroup_code,"' AND ",
                                  "cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ",
                            "ORDER BY part_code "	      
	END CASE
   
   PREPARE s3_product FROM l_query_text
   DECLARE c3_product CURSOR FOR s3_product

   LET idx = 0
   FOREACH c3_product INTO pr_product.*
      LET idx = idx + 1
      LET l_arr_rec_product[idx].part_code = pr_product.part_code
      LET l_arr_rec_product[idx].product_text = pr_product.desc_text clipped," ",
                                         pr_product.desc2_text
   END FOREACH

	RETURN l_arr_rec_product   
END FUNCTION   
############################################################
# END FUNCTION db_product_get_alter_arr_rec(p_group_type)
############################################################
   

########################################################################################################################
# 
# UPDATE INSERT DELETE row from DB
#
########################################################################################################################


############################################################
# FUNCTION db_product_update(p_rec_product)
#
#
############################################################
FUNCTION db_product_update(p_ui_mode,p_pk_part_code,p_rec_product)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_pk_part_code LIKE product.part_code
	DEFINE p_rec_product RECORD LIKE product.*
	DEFINE l_ui_mode SMALLINT
	DEFINE ret INT
	DEFINE msgStr STRING
	
	IF p_ui_mode = UI_ON THEN
		LET l_ui_mode = UI_PK
	END IF

	IF p_pk_part_code IS NULL OR p_rec_product.part_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET msgStr = "Product/Part code can not be empty ! (original Product/Part=",trim(p_pk_part_code), " / new Product/Part=", trim(p_rec_product.part_code), ")"  
			ERROR msgStr
		END IF
		RETURN -1
	END IF
# Needs doing !!!!!!!!!! 	
#	IF db_XXXXXXXX_get_product_count(p_pk_part_code) AND (p_pk_part_code <> p_rec_product.part_code) THEN #PK part_code can only be changed if it's not used already
#		IF p_ui_mode > 0 THEN
#			ERROR "Can not change Product/Part ! It is already used in a bank configuration"
#		END IF
#		LET ret =  -1
#	ELSE
		
			UPDATE product	SET * = p_rec_product.*
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code	AND 
			      part_code = p_pk_part_code
			LET ret = status
		
#	END IF

	IF p_ui_mode != UI_OFF THEN #display MESSAGE if ui is enabled
		IF ret < 0 THEN   		
			LET msgStr = "Coud not modify Product/Part record ! /nOriginal Product/Part", trim(p_pk_part_code), "New Product/Part ", trim(p_rec_product.part_code),  "\nDatabase Error ", trim(ret)                                                                                        
			#ERROR msgStr 
			CALL fgl_winmessage("Error when trying to modify/update Product/Part record",msgStr,"error")
		ELSE
			LET msgStr = "Product/Part record ", trim(p_rec_product.part_code), " updated successfully !"   
			MESSAGE msgStr
		END IF                                           	
	END IF	
	
	RETURN ret
END FUNCTION        
############################################################
# END FUNCTION db_product_update(p_rec_product)
############################################################

   
############################################################
# FUNCTION db_product_insert(p_rec_product)
#
#
############################################################
FUNCTION db_product_insert(p_ui_mode,p_rec_product)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_rec_product RECORD LIKE product.*
	DEFINE ret INT
	DEFINE l_ui_mode SMALLINT
	DEFINE msgStr STRING	
	
	IF p_ui_mode = UI_ON THEN
		LET l_ui_mode = UI_PK
	END IF

	IF p_rec_product.part_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET msgStr = "Product/Part code can not be empty ! (Product/Part=", trim(p_rec_product.part_code), ")"  
			ERROR msgStr
		END IF
		RETURN -1
	END IF

	LET p_rec_product.cmpy_code = glob_rec_kandoouser.cmpy_code
	
	IF db_product_pk_exists(UI_PK,p_rec_product.part_code) THEN
		LET ret = -1
	ELSE
		
			INSERT INTO product VALUES(p_rec_product.*)
         LET ret = status
		
	END IF

	IF p_ui_mode != UI_OFF THEN #display MESSAGE if ui is enabled
		IF ret < 0 THEN   		
			LET msgStr = "Coud not create Product/Part record ", trim(p_rec_product.part_code), " !\nDatabase Error ", trim(ret)                                                                                        
			#ERROR msgStr 
			CALL fgl_winmessage("Error when trying to create/insert Product/Part record",msgStr,"error")
		ELSE
			LET msgStr = "Product/Part record ", trim(p_rec_product.part_code), " created successfully !"   
			MESSAGE msgStr
		END IF                                           	
	END IF
	
	RETURN ret
END FUNCTION
############################################################
# END FUNCTION db_product_insert(p_rec_product)
############################################################


############################################################
# 
# FUNCTION db_product_delete(p_part_code)
#
#
############################################################
FUNCTION db_product_delete(p_ui_mode,p_confirm,p_part_code)
	DEFINE p_ui_mode SMALLINT #hide or show error/warning messages
	DEFINE p_confirm BOOLEAN #is operator requested to confirm this operation / independent of ui mode
	DEFINE p_part_code LIKE product.part_code
	DEFINE l_msgresp LIKE language.yes_flag	
	DEFINE ret SMALLINT	
	DEFINE msgStr STRING

	IF p_confirm = UI_CONFIRM_ON THEN
		LET msgStr = "Delete Product/Part configuration ", trim(p_part_code), " ?"
		IF NOT promptTF("Delete Product/Part",msgStr,TRUE) THEN
			RETURN -2
		END IF
	END IF
	
	IF p_part_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET msgStr = "Product/Part code can not be empty ! (Product/Part=", trim(p_part_code), ")"  
			ERROR msgStr
		END IF
		RETURN -1
	END IF
# Needs doing !!!!!!!!!! 
#	IF db_XXXXX_get_product_count(p_part_code) THEN #PK part_code can only be deleted if it's not used already
#		IF p_ui_mode != UI_OFF THEN
#			LET msgStr = "Can not delete Product/Part ! ", trim(p_part_code), " It is already used in a bank configuration"
#			CALL fgl_winmessage("Can not delete Product/Part ! ",msgStr,"error")
#		END IF
#		LET ret =  -1
#	ELSE
		
			DELETE FROM product
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code	AND 
			      part_code = p_part_code
			LET ret = status
		
			
#	END IF
	
	IF p_ui_mode != UI_OFF THEN #display MESSAGE if ui is enabled
		IF ret < 0 THEN   		
			LET msgStr = "Coud not delete Product/Part record ", trim(p_part_code), " !\nDatabase Error ", trim(ret)                                                                                        
			#ERROR msgStr 
			CALL fgl_winmessage("Error when trying to delete",msgStr,"error")
		ELSE
			LET msgStr = "Product/Part record ", trim(p_part_code), " deleted !"   
			MESSAGE msgStr
		END IF                                           	
	END IF		             

	RETURN ret	
		  
END FUNCTION
############################################################
# END FUNCTION db_product_delete(p_part_code)
############################################################

# ericv 20201127: Starting rewriting some of those functions in a better way
# the original idea was good, but implementation of many of them is just useless

# FUNCTION check_prykey_exists_product: checks whether the primary key exists
# inbound: cmpy_code and part_code
# outbound: boolean true if exists, false if not exists
FUNCTION check_prykey_exists_product(p_cmpy_code,p_part_code)
	DEFINE p_cmpy_code LIKE product.cmpy_code
	DEFINE p_part_code LIKE product.part_code
	DEFINE prykey_exists BOOLEAN
	# initialize prykey_exists to false. If key is found, it is set to 'true'
	LET prykey_exists = FALSE
	SELECT TRUE
	INTO prykey_exists
	FROM product
	WHERE cmpy_code = p_cmpy_code
		AND part_code = p_part_code
	RETURN prykey_exists
END FUNCTION #check_prykey_exists_product()

# This function returns the category description
FUNCTION db_get_desc_product(p_cmpy_code,p_part_code)
	DEFINE p_cmpy_code LIKE product.cmpy_code
	DEFINE p_part_code LIKE product.part_code
	DEFINE l_product_desc LIKE product.desc_text
	DEFINE p_set_isolation_mode PREPARED
	LET l_product_desc = NULL

	SET ISOLATION TO DIRTY READ
	SELECT desc_text INTO l_product_desc
	FROM product
	WHERE cmpy_code = p_cmpy_code
	AND part_code = p_part_code

	IF sqlca.sqlcode = 0 THEN
		CALL reset_isolation_mode()	#  reset to default isolation mode
		RETURN l_product_desc,1
	ELSE
		CALL reset_isolation_mode()	#  reset to default isolation mode
		RETURN l_product_desc,0
	END IF
	
END FUNCTION # db_get_desc_product


FUNCTION db_product_get_arr_tree ()
	DEFINE idx SMALLINT
	DEFINE sql_statement STRING
	DEFINE l_arr_rec_product_tree DYNAMIC ARRAY OF RECORD # t_rec_product_for_tree
		description NCHAR(80),
		id LIKE product.part_code,
		parentid LIKE product.part_code
	END RECORD
	DEFINE l_arr_rec_element_type DYNAMIC ARRAY OF CHAR(1)	# determines if element is a Department,Main group, group of product
	DEFINE crs_scan_product_tree CURSOR

	# Now display the template in the tree view
	CALL l_arr_rec_product_tree.Clear()
	CALL l_arr_rec_element_type.Clear()
	
	LET sql_statement =
	"SELECT trim(dept_code|| '-' || desc_text),dept_code,NULL::NCHAR as parentid,'D' as elem_type,dept_code as sortkey ",
	" FROM proddept WHERE cmpy_code = ? ",
	" UNION ",
	" SELECT trim(maingrp_code||'-'||desc_text),maingrp_code,dept_code,'M',dept_code||maingrp_code ",
	" FROM maingrp WHERE cmpy_code = ? ",
	" UNION ",
	" SELECT trim(prodgrp_code||'-'||desc_text),prodgrp_code,maingrp_code,'G',dept_code||maingrp_code||prodgrp_code ",
	" FROM prodgrp WHERE cmpy_code = ? ",
	" UNION ",
	" SELECT trim(part_code||'-'||desc_text),part_code,prodgrp_code,'P',dept_code||maingrp_code||prodgrp_code||part_code ",
	" FROM product WHERE cmpy_code = ? ",
	" order by sortkey "
 
	CALL crs_scan_product_tree.Declare(sql_statement)
	CALL crs_scan_product_tree.Open(glob_rec_company.cmpy_code,glob_rec_company.cmpy_code,glob_rec_company.cmpy_code,glob_rec_company.cmpy_code)
	LET idx = 1

	WHILE crs_scan_product_tree.FetchNext(l_arr_rec_product_tree[idx].description,l_arr_rec_product_tree[idx].id,l_arr_rec_product_tree[idx].parentid,l_arr_rec_element_type[idx] ) = 0
		LET idx = idx + 1
	END WHILE

	RETURN l_arr_rec_product_tree,l_arr_rec_element_type

END FUNCTION		# db_product_get_arr_tree
