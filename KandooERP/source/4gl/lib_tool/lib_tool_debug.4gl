###########################################################################
# Debug / Error functions 
#
# Not for exception handling... but to give information on current situation
###########################################################################

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

###########################################################################
# FUNCTION get_screen_navigation()
#
# Detect the screen cursor navigation direction
# return void
###########################################################################
FUNCTION get_debug_information(p_error_message) #return void
	DEFINE p_error_message STRING 
	DEFINE l_last_key SMALLINT
	DEFINE l_ret_direction SMALLINT --BOOLEAN
	DEFINE l_msg STRING

	OPEN WINDOW Z101 WITH FORM "Z101_debug_current_status"

	DISPLAY int_flag TO int_flag
	DISPLAY trim(fgl_keyname(fgl_lastkey())) TO last_key_name
	DISPLAY fgl_lastkey() TO last_key_value
	DISPLAY fgl_lastaction() TO last_action
	DISPLAY status TO status
	DISPLAY sqlca.sqlcode TO sqlca_sqlcode
	IF get_is_screen_navigation_forward() THEN
		DISPLAY "Forward/Down" TO screen_navigation_direction
	ELSE
		DISPLAY "Backward/UP" TO screen_navigation_direction
	END IF
	DISPLAY p_error_message TO error_message

	CALL eventsuspend()
	
	CLOSE WINDOW Z101
END FUNCTION
###########################################################################
# END FUNCTION get_screen_navigation()
###########################################################################