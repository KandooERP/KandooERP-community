##############################################################################################
#TABLE customertype
##############################################################################################

##########################################################
# GLOBAL Scope Variables
##########################################################
GLOBALS "../common/glob_GLOBALS.4gl"

############################################################
# FUNCTION db_customertype_get_count()
#
# Return total number of rows in customertype FROM current company
############################################################
FUNCTION db_customertype_get_count()
	DEFINE l_ret INT
	
	SELECT count(*) 
	INTO l_ret 
	FROM customertype 
	WHERE customertype.cmpy_code = glob_rec_kandoouser.cmpy_code		

	RETURN l_ret
END FUNCTION
############################################################
# END FUNCTION db_customertype_get_count()
############################################################


############################################################
# FUNCTION db_customertype_get_type_text(p_ui_mode,p_type_code) 
# RETURN l_ret_type_text
#
# Get type_text FROM customertype record
############################################################
FUNCTION db_customertype_get_type_text(p_ui_mode,p_type_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_type_code LIKE customertype.type_code
	DEFINE l_ret_type_text LIKE customertype.type_text

	IF p_type_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "customertype Code can NOT be empty"
		END IF
		RETURN NULL
	END IF
		
	SELECT type_text 
	INTO l_ret_type_text 
	FROM customertype 

	WHERE customertype.type_code = p_type_code  		
	AND customertype.cmpy_code = glob_rec_kandoouser.cmpy_code

	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "customertype Description with Code ",trim(p_type_code),  "NOT found"
		END IF
		RETURN NULL
	ELSE
		RETURN l_ret_type_text	                                                                                                
	END IF	
END FUNCTION
############################################################
# FUNCTION db_customertype_get_type_text(p_ui_mode,p_type_code) 
############################################################


############################################################
# FUNCTION db_customertype_get_rec(p_ui_mode,p_customertype_code)
#
# Return customertype record matching PK type_code
############################################################
FUNCTION db_customertype_get_rec(p_ui_mode,p_customertype_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_customertype_code LIKE customertype.type_code
	DEFINE l_ret_rec_customertype RECORD LIKE customertype.*
	DEFINE l_msg STRING
	
	IF p_customertype_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "customertype Code can NOT be empty"
			RETURN NULL
		END IF
	END IF

	SELECT * 
	INTO l_ret_rec_customertype 
	FROM customertype 
	WHERE customertype.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND customertype.type_code = p_customertype_code  		
	
	IF sqlca.sqlcode != 0 THEN
		INITIALIZE l_ret_rec_customertype.* TO NULL 
		IF p_ui_mode != UI_OFF THEN 
			ERROR "Customertype with Code ",trim(p_customertype_code),  "NOT found"
		END IF
	END IF

	RETURN l_ret_rec_customertype.* 
END FUNCTION 
############################################################
# END FUNCTION db_customertype_get_rec(p_ui_mode,p_customertype_code)
############################################################