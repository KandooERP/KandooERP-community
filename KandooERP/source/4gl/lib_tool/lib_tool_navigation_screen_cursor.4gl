###########################################################################
# Screen Cursor functions 
#
#
###########################################################################

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

###########################################################################
# FUNCTION get_screen_navigation()
#
# Detect the screen cursor navigation direction
###########################################################################
FUNCTION get_is_screen_navigation_forward() --returns FALSE if it moves back and TRUE if it moves forward
	DEFINE l_last_key SMALLINT
	DEFINE l_ret_direction SMALLINT --BOOLEAN
	DEFINE l_msg STRING
	
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
	
	LET l_ret_direction = 99
	CASE 
		--WHEN fgl_lastAction("nextfield") LET l_ret_direction = DIR_FORWARD
		--WHEN fgl_lastAction("prevfield") LET l_ret_direction = DIR_BACKWARD
		WHEN int_flag = TRUE														LET l_ret_direction = DIR_BACKWARD 
		WHEN fgl_lastkey() = FGL_KEYVAL("ACCEPT")				LET l_ret_direction = DIR_FORWARD  #special case accept
		WHEN fgl_lastkey() =  FGL_KEYVAL("CANCEL")			LET l_ret_direction = DIR_BACKWARD  #special case cancel
		WHEN fgl_lastkey() =  FGL_KEYVAL("RETURN")			LET l_ret_direction = DIR_FORWARD
		WHEN fgl_lastkey() =  FGL_KEYVAL("DOWN")				LET l_ret_direction = DIR_FORWARD
		WHEN fgl_lastkey() =  FGL_KEYVAL("UP")					LET l_ret_direction = DIR_BACKWARD
		WHEN fgl_lastkey() =  FGL_KEYVAL("RIGHT")				LET l_ret_direction = DIR_FORWARD
		WHEN fgl_lastkey() =  FGL_KEYVAL("ARROW RIGHT")	LET l_ret_direction = DIR_FORWARD
		WHEN fgl_lastkey() =  FGL_KEYVAL("LEFT")				LET l_ret_direction = DIR_BACKWARD
		WHEN fgl_lastkey() =  FGL_KEYVAL("ARROW LEFT")	LET l_ret_direction = DIR_BACKWARD  #2002
		WHEN fgl_lastkey() =  FGL_KEYVAL("PAGEDOWN")		LET l_ret_direction = DIR_FORWARD
		WHEN fgl_lastkey() =  FGL_KEYVAL("PAGEUP")			LET l_ret_direction = DIR_BACKWARD
		WHEN fgl_lastkey() =  FGL_KEYVAL("END")					LET l_ret_direction = DIR_FORWARD
		WHEN fgl_lastkey() =  FGL_KEYVAL("HOME")				LET l_ret_direction = DIR_BACKWARD
		WHEN fgl_lastkey() =  FGL_KEYVAL("ENTER")				LET l_ret_direction = DIR_FORWARD
		WHEN fgl_lastkey() =  FGL_KEYVAL("TAB")					LET l_ret_direction = DIR_FORWARD
		WHEN fgl_lastkey() =  FGL_KEYVAL("SHIFT-TAB")		LET l_ret_direction = DIR_BACKWARD
		WHEN fgl_lastkey() =  FGL_KEYVAL("F2")					LET l_ret_direction = DIR_BACKWARD --delete
		WHEN fgl_lastkey() =  FGL_KEYVAL("DELETE")			LET l_ret_direction = DIR_BACKWARD --delete
		WHEN fgl_lastkey() =  FGL_KEYVAL("F1")					LET l_ret_direction = DIR_FORWARD --insert/append

		OTHERWISE #something I'm still unsure.. how to handle best with legacy code
			IF l_ret_direction = 99 THEN 
				CASE
					WHEN fgl_lastAction() = "append" LET l_ret_direction = DIR_FORWARD #NULL
					WHEN fgl_lastAction() = "insert" LET l_ret_direction = DIR_FORWARD #NULL
					WHEN fgl_lastAction() = "delete" LET l_ret_direction = DIR_BACKWARD # NULL
				END CASE
			END IF

			IF l_ret_direction = 99 THEN
				LET l_msg = 
					"Could not detect screen cursor navigation direction!\n",
					"FUNCTION get_screen_navigation()\n",
					"fgl_lastkey()=", trim(fgl_lastkey()), " fgl_keyname()=", trim(fgl_keyname(fgl_lastkey()))
				CALL fgl_winmessage("HuHo Error", l_msg,"error")
				--LET l_msg =
				--	"Could not detect screen cursor navigation direction!\n",	"FUNCTION get_screen_navigation()\n",
				--	"fgl_lastkey()=", trim(fgl_lastkey()), " fgl_keyname()=", trim(fgl_keyname(fgl_lastkey()))
				--ERROR l_msg
				LET l_ret_direction = DIR_BACKWARD #conflict default direction
			END IF
	END CASE

	RETURN l_ret_direction
END FUNCTION
###########################################################################
# END FUNCTION get_screen_navigation()
###########################################################################