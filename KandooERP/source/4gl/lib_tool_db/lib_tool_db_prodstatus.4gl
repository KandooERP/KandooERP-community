##############################################################################################
#TABLE prodstatus  
#
# 3 Column PK cmpy, part_code, ware_code
##############################################################################################

##########################################################
# GLOBAL Scope Variables
##########################################################
GLOBALS "../common/glob_GLOBALS.4gl"



############################################################
# FUNCTION db_prodstatus_get_count()
#
# Return total number of rows in prodstatus 
############################################################
FUNCTION db_prodstatus_get_count()
	DEFINE l_ret INT

	SELECT count(*) 
	INTO l_ret 
	FROM prodstatus 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code		
			
	RETURN l_ret
END FUNCTION
############################################################
# END FUNCTION db_prodstatus_get_count()
############################################################

############################################################
# FUNCTION db_prodstatus_pk_exists(p_ui,p_part_code,p_ware_code)
#
# Validate PK - Unique
############################################################
#	CONSTANT UI_OFF SMALLINT = 0
#	CONSTANT UI_ON SMALLINT = 1
#	CONSTANT UI_FK SMALLINT = 2
#	CONSTANT UI_PK SMALLINT = 3
############################################################
FUNCTION db_prodstatus_pk_exists(p_ui,p_part_code,p_ware_code)
	DEFINE p_ui SMALLINT
	DEFINE p_part_code LIKE prodstatus.part_code
	DEFINE p_ware_code LIKE prodstatus.ware_code
	DEFINE l_ret BOOLEAN
	DEFINE l_recCount INT
	DEFINE l_msg STRING

	IF p_ware_code IS NULL THEN
		IF p_ui != UI_OFF THEN
			ERROR "PRODSTATUS Code can not be empty"
		END IF
		RETURN FALSE
	END IF

	IF p_part_code IS NULL THEN
		IF p_ui != UI_OFF THEN
			ERROR "PRODSTATUS part_code can not be empty"
		END IF
		RETURN FALSE
	END IF

	SELECT count(*) 
	INTO l_recCount 
	FROM prodstatus
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code			
	AND prodstatus.ware_code = p_ware_code
	AND prodstatus.part_code = p_part_code
		
	IF l_recCount <> 0 THEN
		LET l_ret = TRUE	
		IF p_ui = UI_ON THEN
			MESSAGE "Product (prodstatus) with part_code ", trim(p_part_code), " located in the warehouse ", trim(p_ware_code), " already exists!"
		END IF
		IF p_ui = UI_PK THEN
			MESSAGE "Product (prodstatus) with part_code ", trim(p_part_code), " located in the warehouse ", trim(p_ware_code), " already exists!"
		END IF
	ELSE
		LET l_ret = FALSE	
		IF p_ui = UI_FK THEN
			MESSAGE "Product does not exist!\nProduct (prodstatus) with part_code ", trim(p_part_code), " located in the warehouse ", trim(p_ware_code), " already exists!"
		END IF
	END IF
	
	RETURN l_ret
END FUNCTION
############################################################
# END FUNCTION db_prodstatus_pk_exists(p_ui,p_part_code,p_ware_code)
############################################################


############################################################
# FUNCTION db_prodstatus_get_rec(p_ui_mode,p_ware_code,p_part_code)
# RETURN l_rec_prodstatus.*
# Get prodstatus record
############################################################
FUNCTION db_prodstatus_get_rec(p_ui_mode,p_ware_code,p_part_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_ware_code LIKE prodstatus.ware_code
	DEFINE p_part_code LIKE prodstatus.part_code
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.*
	DEFINE l_msg STRING
	
	IF p_part_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Can not retrieve record with empty Product/Part code"
		END IF
		RETURN NULL
	END IF

	SELECT *
	INTO l_rec_prodstatus.*
	FROM prodstatus
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code	
	AND ware_code = p_ware_code	        
	AND part_code = p_part_code
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN
			LET l_msg = "Product ", trim(p_part_code), " not found!"
			ERROR l_msg
		END IF   		  
		INITIALIZE l_rec_prodstatus.* TO NULL                                                                                      
	END IF	         

	RETURN l_rec_prodstatus.*		                                                                                                
END FUNCTION	
############################################################
# END FUNCTION db_prodstatus_get_rec(p_ui_mode,p_ware_code,p_part_code)
############################################################


############################################################
# FUNCTION db_prodstatus_get_onhand_qty(p_ui_mode,p_ware_code, p_part_code)
# RETURN l_ret_onhand_qty 
#
# Get prodstatus default tax-code
############################################################
FUNCTION db_prodstatus_get_onhand_qty(p_ui_mode,p_ware_code, p_part_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_ware_code LIKE prodstatus.ware_code
	DEFINE p_part_code LIKE prodstatus.part_code

	DEFINE l_ret_onhand_qty LIKE prodstatus.onhand_qty

	IF p_ware_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Warehouse Code can NOT be empty"
		END IF
		RETURN NULL
	END IF

	IF p_part_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Product Part Code can NOT be empty"
		END IF
		RETURN NULL
	END IF
	
	SELECT onhand_qty 
	INTO l_ret_onhand_qty
	FROM prodstatus
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code	
	AND prodstatus.ware_code = p_ware_code
	AND prodstatus.part_code = p_part_code  		

	IF sqlca.sqlcode != 0 THEN   		  
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Product/Part Code ",trim(p_ware_code), "/", trim(p_part_code),  ": Tax_code NOT found or is empty"
		END IF
		LET l_ret_onhand_qty = NULL
	END IF	

	RETURN l_ret_onhand_qty	                                                                                                
END FUNCTION
############################################################
# END FUNCTION db_prodstatus_get_onhand_qty(p_ui_mode,p_ware_code, p_part_code)
############################################################


############################################################
# FUNCTION db_prodstatus_get_tax_code(p_ui_mode,p_cust_code)
# RETURN l_ret_sale_tax_code 
#
# Get prodstatus default tax-code
############################################################
FUNCTION db_prodstatus_get_sale_tax_code(p_ui_mode,p_ware_code, p_part_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_ware_code LIKE prodstatus.ware_code
	DEFINE p_part_code LIKE prodstatus.part_code

	DEFINE l_ret_sale_tax_code LIKE prodstatus.sale_tax_code

	IF p_ware_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Warehouse Code can NOT be empty"
		END IF
		RETURN NULL
	END IF

	IF p_part_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Product Part Code can NOT be empty"
		END IF
		RETURN NULL
	END IF
	
	SELECT sale_tax_code 
	INTO l_ret_sale_tax_code
	FROM prodstatus
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code	
	AND prodstatus.ware_code = p_ware_code
	AND prodstatus.part_code = p_part_code  		

	IF sqlca.sqlcode != 0 THEN   		  
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Product/Part Code ",trim(p_ware_code), "/", trim(p_part_code),  ": Tax_code NOT found or is empty"
		END IF
		LET l_ret_sale_tax_code = NULL
	END IF	

	RETURN l_ret_sale_tax_code	                                                                                                
END FUNCTION
############################################################
# END FUNCTION db_prodstatus_get_tax_code(p_ui_mode,p_cust_code)
############################################################

############################################################
# FUNCTION db_prodstatus_get_list_amt(p_ui_mode,p_cust_code)
# RETURN l_ret_list_amt
#
# Get product list price/amount
############################################################
FUNCTION db_prodstatus_get_list_amt(p_ui_mode,p_ware_code, p_part_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_ware_code LIKE prodstatus.ware_code
	DEFINE p_part_code LIKE prodstatus.part_code

	DEFINE l_ret_list_amt LIKE prodstatus.list_amt

	IF p_ware_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Warehouse Code can NOT be empty"
		END IF
		RETURN NULL
	END IF

	IF p_part_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Product Part Code can NOT be empty"
		END IF
		RETURN NULL
	END IF
	
	SELECT list_amt 
	INTO l_ret_list_amt
	FROM prodstatus
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code	
	AND prodstatus.ware_code = p_ware_code
	AND prodstatus.part_code = p_part_code  		

	IF sqlca.sqlcode != 0 THEN   		  
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Product/Part Code ",trim(p_ware_code), "/", trim(p_part_code),  ": List Price/Amount (list_amt) NOT found or is empty"
		END IF
		LET l_ret_list_amt = NULL
	END IF	

	RETURN l_ret_list_amt	                                                                                                
END FUNCTION
############################################################
# END FUNCTION db_prodstatus_get_list_amt(p_ui_mode,p_cust_code)
############################################################


############################################################
# FUNCTION db_prodstatus_get_min_list_amt_by_group_code(p_ui_mode, p_part_code,p_prodgrp_code,p_maingrp_code)
# RETURN l_ret_list_amt
#
# Get product list price/amount
############################################################
FUNCTION db_prodstatus_get_min_list_amt_by_group_code(p_ui_mode,p_prodgrp_code,p_maingrp_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_prodgrp_code LIKE proddisc.prodgrp_code 
	DEFINE p_maingrp_code LIKE proddisc.maingrp_code 

	DEFINE l_ret_list_amt LIKE prodstatus.list_amt

	IF p_prodgrp_code IS NULL AND p_maingrp_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Product Group and Main Group Code can not be both empty"
		END IF
		RETURN NULL
	END IF	

	IF p_prodgrp_code IS NOT NULL THEN 

		SELECT min(list_amt) INTO l_ret_list_amt 
		FROM prodstatus,product 
		WHERE product.prodgrp_code = p_prodgrp_code 
		AND product.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND prodstatus.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND prodstatus.part_code = product.part_code 
		AND prodstatus.ware_code = l_rec_inparms.mast_ware_code 

		IF sqlca.sqlcode != 0 THEN   		  
			IF p_ui_mode != UI_OFF THEN		
				ERROR "Product Group Code ", trim(p_prodgrp_code),  ": Min List Price/Amount (list_amt) NOT found for this product group code"
			END IF
			LET l_ret_list_amt = NULL
		END IF

	ELSE 
		IF p_maingrp_code IS NOT NULL THEN 
			SELECT min(list_amt) INTO l_ret_list_amt 
			FROM prodstatus,product 
			WHERE product.maingrp_code = p_maingrp_code 
			AND product.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND prodstatus.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND prodstatus.part_code = product.part_code 
			AND prodstatus.ware_code = l_rec_inparms.mast_ware_code 
		END IF 

		IF sqlca.sqlcode != 0 THEN   		  
			IF p_ui_mode != UI_OFF THEN		
				ERROR "Main Group Code ", trim(p_maingrp_code),  ": Min List Price/Amount (list_amt) NOT found for this main group code"
			END IF
			LET l_ret_list_amt = NULL
		END IF

	END IF 

	RETURN l_ret_list_amt	                                                                                                
END FUNCTION
############################################################
# END FUNCTION db_prodstatus_get_list_amt(p_ui_mode,p_cust_code)
############################################################