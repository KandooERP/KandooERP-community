GLOBALS "../common/glob_GLOBALS.4gl"

DEFINE rec_clipboard RECORD LIKE clipboard.*

FUNCTION clear_table_clipboard()
	define i like kandoouser.sign_on_code
	DELETE FROM clipboard WHERE 1=1

END FUNCTION


FUNCTION clear_user_clipboard()
	DEFINE l_sign_on_code LIKE clipboard.sign_on_code  --CHAR(8)
	
	LET l_sign_on_code = getCurrentUser_sign_on_code()
	
	DELETE FROM clipboard 
	WHERE sign_on_code = l_sign_on_code
	
	INITIALIZE rec_clipboard.* TO NULL
	
END FUNCTION

########################################################################
# FUNCTION get_db_clipboard_string_val()
#
#
########################################################################
FUNCTION get_db_clipboard_string_val()
	DEFINE l_sign_on_code LIKE clipboard.sign_on_code  --CHAR(8)
	DEFINE ret_string_val LIKE clipboard.string_val
	
	LET l_sign_on_code = getCurrentUser_sign_on_code()
	
	SELECT string_val 
	INTO ret_string_val 
	FROM clipboard 
	WHERE sign_on_code = l_sign_on_code
	
	RETURN ret_string_val
END FUNCTION    


########################################################################
# FUNCTION set_db_clipboard_string_val(p_string_val)
#
#
########################################################################
FUNCTION set_db_clipboard_string_val(p_string_val)
	DEFINE l_sign_on_code LIKE clipboard.sign_on_code  --CHAR(8)
	DEFINE p_string_val LIKE clipboard.string_val

	CALL init_db_clipboard()  --CLEAR module AND db record for current user

	#LET rec_clipboard.sign_on_code = getCurrentUser_sign_on_code()
	LET rec_clipboard.string_val = p_string_val
	
	 
		INSERT INTO clipboard VALUES (rec_clipboard.*)	
	

	IF sqlca.sqlcode != 0 THEN
		CALL fgl_winmessage("Error Clipboard","Could NOT store clipboard data in database","Stop")
		RETURN FALSE
	ELSE
		RETURN TRUE
	END IF 
	
END FUNCTION    

----------------------------------------

########################################################################
# FUNCTION init_db_clipboard()
#
#
########################################################################
FUNCTION init_db_clipboard()
	CALL clear_user_clipboard()		
	LET rec_clipboard.sign_on_code = getCurrentUser_sign_on_code()
	
END FUNCTION