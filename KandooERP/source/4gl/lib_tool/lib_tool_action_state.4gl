###########################################################################
# Screen Cursor functions 
#
#
###########################################################################

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

############################################################
# FUNCTION get_screen_navigation()
#
# Detect the screen cursor navigation direction
############################################################
FUNCTION get_action_is_save() --returns true for Save/ACCEPT
	DEFINE l_last_key SMALLINT
	DEFINE l_ret_save SMALLINT --BOOLEAN
	DEFINE l_msg STRING
	CALL set_debug(TRUE)
	IF get_debug() THEN 
		LET l_msg = 
				"Screeen Cursor Navigation Direction",
				" fgl_lastkey()=", trim(fgl_lastkey()), 
				" fgl_keyname()=", trim(fgl_keyname(fgl_lastkey())),
				" int_flag = ", trim(int_flag),
				" fgl_lastaction()=", trim(fgl_lastaction())
	DISPLAY "-------------------------------------------"
	DISPLAY "FUNCTION get_is_screen_navigation_forward()"
	DISPLAY l_msg
	DISPLAY "-------------------------------------------"
	END IF
	CALL set_debug(FALSE)

	CASE 
		WHEN int_flag = TRUE														LET l_ret_save = FALSE
		WHEN fgl_lastkey() =  FGL_KEYVAL("CANCEL")			LET l_ret_save = FALSE  #special case cancel 
		WHEN fgl_lastAction() = "delete"                LET l_ret_save = FALSE
		
		WHEN fgl_lastkey() = FGL_KEYVAL("ACCEPT")				LET l_ret_save = TRUE  #special case accept
		WHEN fgl_lastkey() = FGL_KEYVAL("INSERT")				LET l_ret_save = TRUE  #special case accept
		WHEN fgl_lastAction() = "append"                LET l_ret_save = TRUE
		WHEN fgl_lastAction() = "insert"                LET l_ret_save = TRUE
		WHEN fgl_lastAction() = "save"                  LET l_ret_save = TRUE	
		OTHERWISE 
			LET l_ret_save = FALSE 
	END CASE
	
	RETURN 	l_ret_save
END FUNCTION