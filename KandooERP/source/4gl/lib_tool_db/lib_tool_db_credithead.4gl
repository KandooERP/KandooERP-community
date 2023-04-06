############################################################
# TABLE credithead
############################################################

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl"

############################################################
# FUNCTION db_credithead_cred_num_exist(p_cred_num)
############################################################
FUNCTION db_credithead_cred_num_exist(p_cred_num)
	DEFINE p_cred_num LIKE credithead.cred_num
	DEFINE l_count SMALLINT
	
	SELECT count(*) INTO l_count 
	FROM credithead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cred_num = p_cred_num 

	IF l_count > 0 THEN
		RETURN TRUE
	ELSE
		RETURN FALSE
	END IF
 	
END FUNCTION
############################################################
# END FUNCTION db_credithead_cred_num_exist(p_cred_num)
############################################################


############################################################
# FUNCTION db_credithead_get_rec(p_ui_mode,p_cred_num)
# RETURN l_rec_credithead.*
# Get credithead record
############################################################
FUNCTION db_credithead_get_rec(p_ui_mode,p_cred_num)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_cred_num LIKE credithead.cred_num
	DEFINE l_rec_credithead RECORD LIKE credithead.*

	IF p_cred_num IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Can not retrieve record with empty \'Cash Receipt\' Number (cred_num)"
		END IF
		RETURN NULL
	END IF

	SELECT * INTO l_rec_credithead.*
	FROM credithead
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code		        
	AND cred_num = p_cred_num
	
	IF sqlca.sqlcode != 0 THEN   		  
		INITIALIZE l_rec_credithead.* TO NULL
		
		IF p_ui_mode != UI_OFF THEN
			ERROR "Could not retrieve the \'Cash Receipt\' Record (credithead)"
		END IF                                                                                      
	ELSE		                                                                                                                    
		# all fine		                                                                                                
	END IF	         

	RETURN l_rec_credithead.*		                                                                                                
END FUNCTION	
############################################################
# END FUNCTION db_credithead_get_rec(p_ui_mode,p_cred_num)
############################################################
