##############################################################################################
#TABLE salesmgr
##############################################################################################

##########################################################
# GLOBAL Scope Variables
##########################################################
GLOBALS "../common/glob_GLOBALS.4gl"

############################################################
# FUNCTION db_salesmgr_get_count()
#
# RETURN l_ret_count
# Return total number of rows in salesmgr FROM current company
############################################################
FUNCTION db_salesmgr_get_count()
	DEFINE l_ret_count INT

	SELECT count(*) 
	INTO l_ret_count 
	FROM salesmgr 
	WHERE salesmgr.cmpy_code = glob_rec_kandoouser.cmpy_code		

	RETURN l_ret_count
END FUNCTION
############################################################
# FUNCTION db_salesmgr_get_count()
############################################################


############################################################
# FUNCTION db_salesmgr_get_rec(p_ui_mode,p_mgr_code)
# RETURN l_rec_salesmgr.*
# Get salesmgr record
############################################################
FUNCTION db_salesmgr_get_rec(p_ui_mode,p_mgr_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_mgr_code LIKE salesmgr.mgr_code
	DEFINE l_rec_salesmgr RECORD LIKE salesmgr.*

	IF p_mgr_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Can not retrieve record with empty Sales Manager Number (mgr_code)"
		END IF
		RETURN NULL
	END IF

	SELECT * INTO l_rec_salesmgr.*
	FROM salesmgr
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code		        
	AND mgr_code = p_mgr_code
	
	IF sqlca.sqlcode != 0 THEN   		  
		INITIALIZE l_rec_salesmgr.* TO NULL
		
		IF p_ui_mode != UI_OFF THEN
			ERROR "Could not retrieve the Sales Manager Record (salesmgr)"
		END IF                                                                                      
	ELSE		                                                                                                                    
		# all fine		                                                                                                
	END IF	         

	RETURN l_rec_salesmgr.*		                                                                                                
END FUNCTION	
############################################################
# END FUNCTION db_salesmgr_get_rec(p_ui_mode,p_mgr_code)
############################################################


############################################################
# FUNCTION db_salesmgr_get_name_text(p_ui_mode,p_mgr_code)
# RETURN l_ret_name_text 
#
# Get description text of Product Adjustment Types record
############################################################
FUNCTION db_salesmgr_get_name_text(p_ui_mode,p_mgr_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_mgr_code LIKE salesmgr.mgr_code
	DEFINE l_ret_name_text LIKE salesmgr.name_text

	IF p_mgr_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN	
			ERROR "Sales Manager Code (mgr_code) can NOT be empty"
		END IF
			RETURN NULL
	END IF

	SELECT name_text 
	INTO l_ret_name_text 
	FROM salesmgr
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code				 
	AND salesmgr.mgr_code = p_mgr_code  		
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Sales Manager Name with Code ",trim(p_mgr_code),  "NOT found"
		END IF			
		LET l_ret_name_text = NULL
	ELSE
		#
	END IF	
	RETURN l_ret_name_text
END FUNCTION
############################################################
# END FUNCTION db_salesmgr_get_name_text(p_ui_mode,p_mgr_code)
############################################################