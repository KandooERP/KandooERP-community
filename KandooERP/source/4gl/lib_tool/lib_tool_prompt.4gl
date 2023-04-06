# FUNCTION doneprompt(p_str_label,p_str_tooltip,p_id_icon) 
# - This is used for "press any key to continue". It basically allows the user to read
#   what is shown on the screen (fully enabled) and Accept click continues
# FUNCTION msgcontinue(p_msg1,p_msg2)
# - Only there for legacy support - do not use it if you don't have to..
#   basically a CALL fgl_winmessage(p_msg1,p_msg2,"info")  
# FUNCTION msgerror(p_msg1,p_msg2) 
# - Only there for legacy support - do not use it if you don't have to..
#   basically a CALL fgl_winmessage(p_msg1,p_msg2,"ERROR")
# FUNCTION promptinput(p_msg,p_defaultvalue,p_length)
# FUNCTION prompt_input(p_msg,p_default_value,p_length,p_line,p_col) 
# FUNCTION anykey(p_msg)
# FUNCTION promptYN(p_msg1,p_msg2,p_pre_choice) 
# FUNCTION promptTF(p_msg1,p_msg2,p_pre_choice) 
# FUNCTION promptYNC(p_msg1,p_msg2,p_pre_choice)
# FUNCTION prompt_YNC_int(p_msg1,p_msg2,p_pre_choice)  
# FUNCTION eventsuspend()
# FUNCTION eventoptions(p_event_model, p_ret)
# FUNCTION confirm_operation(l_xpos,l_ypos,l_msg) #By Eric - used in code generator 
######################################################################

######################################################################
# FUNCTION doneprompt(p_str_label,p_str_tooltip,p_id_icon)
#
#
######################################################################
FUNCTION doneprompt(p_str_label,p_str_tooltip,p_id_icon) 
	DEFINE p_str_label STRING 
	DEFINE p_str_tooltip STRING
	DEFINE p_id_icon STRING 
	DEFINE l_str_icon_uri STRING 

	IF p_str_label IS NULL THEN 
		LET p_str_label = "Done" 
	END IF 

	IF p_str_tooltip IS NULL THEN 
		LET p_str_tooltip = "Close current view AND continue..." 
	END IF 

	IF p_id_icon IS NULL THEN 
		LET p_id_icon = "ACCEPT" 
	END IF 
	
	CASE upshift(p_id_icon) 
		WHEN "ACCEPT" 
			LET l_str_icon_uri = fgl_getenv("TOOLBAR_PATH"),"ic_done_24px.svg" 
		WHEN "CANCEL" 
			LET l_str_icon_uri = fgl_getenv("TOOLBAR_PATH"),"ic_cancel_24px.svg" 
		WHEN "INFO" 
			LET l_str_icon_uri = fgl_getenv("TOOLBAR_PATH"),"ic_info_outline_24px.svg" 
		WHEN "ERROR" 
			LET l_str_icon_uri = fgl_getenv("TOOLBAR_PATH"),"ic_error_outline_24px.svg" 
		WHEN "QUESTION" 
			LET l_str_icon_uri = fgl_getenv("TOOLBAR_PATH"),"ic_help_24px.svg" 

		OTHERWISE 
			LET l_str_icon_uri = fgl_getenv("TOOLBAR_PATH"),"ic_done_24px.svg" 

	END CASE 

	MENU 
		BEFORE MENU 
			CALL fgl_dialog_setkeylabel("DONE",p_str_label,l_str_icon_uri,1,TRUE,p_str_tooltip) 
			CALL dialog.setActionHidden("ACCEPT",TRUE) 
			CALL dialog.setActionHidden("CANCEL",TRUE) 

		ON ACTION "DONE" 
			EXIT MENU 

	END MENU 

END FUNCTION 
######################################################################
# END FUNCTION doneprompt(p_str_label,p_str_tooltip,p_id_icon)
######################################################################


######################################################################
# FUNCTION msgcontinue(p_msg1,p_msg2)
#
#
######################################################################
FUNCTION msgcontinue(p_msg1,p_msg2) 
	DEFINE p_msg1 STRING 
	DEFINE p_msg2 STRING
	DEFINE l_msgstr STRING 

	#May be we can address with more grace later

	CALL fgl_winmessage(p_msg1,p_msg2,"info") 

END FUNCTION 
######################################################################
# END FUNCTION msgcontinue(p_msg1,p_msg2)
######################################################################


######################################################################
# FUNCTION msgerror(p_msg1,p_msg2)
#
# 
######################################################################
FUNCTION msgerror(p_msg1,p_msg2) 
	DEFINE p_msg1 STRING 
	DEFINE p_msg2 STRING
	DEFINE l_msgstr STRING 

	#May be we can address with more grace later

	CALL fgl_winmessage(p_msg1,p_msg2,"error") 

END FUNCTION 
######################################################################
# END FUNCTION msgerror(p_msg1,p_msg2)
######################################################################


######################################################################
# FUNCTION promptinput(p_msg,p_defaultvalue,p_length)
#
# albo 06.03.2019
# The function can assign a user-supplied value TO a variable.
# Parameters: p_msg          - Message TO the user
#             p_defaultvalue - Default text placed in input field
#             p_length       - Maximum input length
#             p_line         - Line position
#	          p_col          - Column position
# Unnecessary parameters can be omitted. For example:
# LET value_string = promptInput("Enter value please: ","",10)
# LET value_string = promptInput("Enter value please: ","Default value")
# LET value_string = promptInput("Enter value please: ")  etc.
######################################################################
FUNCTION promptinput(p_msg,p_defaultvalue,p_length) 
	DEFINE p_msg STRING
	DEFINE p_defaultvalue STRING 
	DEFINE p_length INTEGER 
	DEFINE l_ret_msg string 
	DEFINE p_line INTEGER 
	DEFINE p_col INTEGER 

	# Default position - In Web Based clients in center
	LET l_ret_msg = fgl_winprompt(p_col,p_line,p_msg,p_defaultvalue,0,0) 

	RETURN l_ret_msg 
END FUNCTION 
######################################################################
#END  FUNCTION promptinput(p_msg,p_defaultvalue,p_length)
######################################################################


######################################################################
# FUNCTION prompt_input(p_msg,p_default_value,p_length,p_line,p_col)
# albo 06.03.2019
# The function can assign a user-supplied value TO a variable.
# Parameters: p_msg          - Message TO the user
#             p_default_value - Default text placed in input field
#             p_length       - Maximum input length
#             p_line         - Line position
#	          p_col          - Column position
# Unnecessary parameters can be omitted. For example:
# LET value_string = promptInput("Enter value please: ","",10)
# LET value_string = promptInput("Enter value please: ","Default value")
# LET value_string = promptInput("Enter value please: ")  etc.
######################################################################
FUNCTION prompt_input(p_msg,p_default_value,p_length,p_line,p_col) 
	DEFINE p_msg STRING 
	DEFINE p_default_value STRING 
	DEFINE p_length INTEGER 
	DEFINE l_ret_msg STRING
	DEFINE p_line INTEGER 
	DEFINE p_col INTEGER 

	# Default position
	IF p_line IS NULL THEN LET p_line = 10 END IF 
		IF p_col IS NULL THEN LET p_col = 50 END IF 

			LET l_ret_msg = fgl_winprompt(p_col,p_line,p_msg,p_default_value,p_length,0) 

			RETURN l_ret_msg 
END FUNCTION 
######################################################################
# END FUNCTION prompt_input(p_msg,p_default_value,p_length,p_line,p_col)
######################################################################


######################################################################
# FUNCTION anykey(p_msg)
#
# albo 14.03.2019
# The function waits for a any key TO be pressed AND returns NULL.
# Parameters: p_msg  - MESSAGE TO the user
#             p_line - Line position
#	          p_col  - Column position
######################################################################
--FUNCTION anykey(p_msg,p_line,p_col) 
FUNCTION anykey(p_msg)
	DEFINE p_msg string 
	DEFINE p_line INTEGER 
	DEFINE p_col INTEGER 
	DEFINE l_width INTEGER
	DEFINE l_response CHAR(1) 

	LET p_line = 15 
	LET p_col = 50  


--	# Default position
--	IF p_line IS NULL THEN LET p_line = 15 END IF 
--		IF p_col IS NULL THEN LET p_col = 50 END IF 

			LET l_width = length(p_msg) 
			IF l_width < 20 THEN LET l_width = 20 END IF 

				OPEN WINDOW _ at p_line,p_col with 2 ROWS, l_width COLUMNS attribute(BORDER) 
				DISPLAY p_msg at 3,1 
				--   CALL fgl_settitle("")
				LET l_response = fgl_getkey() 
				LET l_response = NULL 
				CLOSE WINDOW _ 

				RETURN l_response 
END FUNCTION 
######################################################################
# END FUNCTION anykey(p_msg)
######################################################################


######################################################################
# FUNCTION promptds(p_msg1,p_msg2,p_pre_choice)
#
# Detailed or Summary Operation
######################################################################
FUNCTION promptds(p_msg1,p_msg2,p_pre_choice) 
	DEFINE p_msg1, p_msg2 STRING 
	DEFINE p_pre_choice STRING
	DEFINE l_msg STRING 
	DEFINE l_ret STRING 

	CASE p_pre_choice.toUpperCase() 
		WHEN "D" 
			LET l_ret = fgl_winbutton(p_msg1,p_msg2,"Detailed","Detailed|Summary","Question",1) 
		OTHERWISE 
			LET l_ret = fgl_winbutton(p_msg1,p_msg2,"Summary","Summary|Detailed","Question",1) 
	END CASE 

	CASE l_ret 
		WHEN "Detailed" 
			RETURN "D" 
		OTHERWISE #Summary
			RETURN "S" 
	END CASE 

END FUNCTION 
######################################################################
# END FUNCTION promptds(p_msg1,p_msg2,p_pre_choice)
######################################################################


######################################################################
# FUNCTION promptyn(p_msg1,p_msg2,p_pre_choice)
#
# 
######################################################################
FUNCTION promptyn(p_msg1,p_msg2,p_pre_choice) 
	DEFINE p_msg1, p_msg2 STRING 
	DEFINE p_pre_choice STRING
	DEFINE l_msg STRING 
	DEFINE l_ret STRING 

	CASE p_pre_choice.toUpperCase() 
		WHEN "Y" 
			LET l_ret = fgl_winbutton(p_msg1,p_msg2,"Yes","Yes|No","Question",1) 
		OTHERWISE 
			LET l_ret = fgl_winbutton(p_msg1,p_msg2,"No","Yes|No","Question",1) 
	END CASE 

	CASE l_ret 
		WHEN "Yes" 
			RETURN "y" 
		OTHERWISE 
			RETURN "n" 
	END CASE 

END FUNCTION 
######################################################################
# END FUNCTION promptyn(p_msg1,p_msg2,p_pre_choice)
######################################################################


######################################################################
# FUNCTION promptTF(p_msg1,p_msg2,p_pre_choice) 
#
#
######################################################################
FUNCTION promptTF(p_msg1,p_msg2,p_pre_choice) 
	DEFINE p_msg1, p_msg2 STRING 
	DEFINE p_pre_choice BOOLEAN 
	DEFINE l_pre_choice_btn_text STRING
	DEFINE l_msg STRING 
	DEFINE l_ret STRING 

	CASE p_pre_choice 
		WHEN 1 
			LET l_pre_choice_btn_text = "Yes" 
		OTHERWISE 
			LET l_pre_choice_btn_text = "No" 
	END CASE 

	LET l_ret = fgl_winbutton(p_msg1,p_msg2,l_pre_choice_btn_text,"Yes|No","Question",1) 

	CASE l_ret 
		WHEN "Yes" 
			RETURN TRUE 
		OTHERWISE 
			RETURN FALSE 
	END CASE 
END FUNCTION 
######################################################################
# END FUNCTION promptTF(p_msg1,p_msg2,p_pre_choice) 
######################################################################


######################################################################
# FUNCTION promptync(p_msg1,p_msg2,p_pre_choice) 
#
#
######################################################################
FUNCTION promptync(p_msg1,p_msg2,p_pre_choice) 
	DEFINE p_msg1, p_msg2 STRING 
	DEFINE p_pre_choice STRING 
	DEFINE l_msg STRING 
	DEFINE l_ret STRING 

	CASE p_pre_choice.toUpperCase()
		WHEN "Y" 
			LET l_ret = fgl_winbutton(p_msg1,p_msg2,"Yes","Yes|No|Cancel","Question",1) 
		WHEN "C" 
			LET l_ret = fgl_winbutton(p_msg1,p_msg2,"Cancel","Yes|No|Cancel","Question",1) 
		OTHERWISE 
			LET l_ret = fgl_winbutton(p_msg1,p_msg2,"No","Yes|No|Cancel","Question",1) 
	END CASE 

	CASE l_ret 
		WHEN "Yes" 
			RETURN "y" 
		WHEN "No" 
			RETURN "n" 
		OTHERWISE --cancel returns NULL AND raises int_flag = 1 
			LET int_flag = true 
			RETURN NULL 
	END CASE 

END FUNCTION 
######################################################################
# END FUNCTION promptync(p_msg1,p_msg2,p_pre_choice) 
######################################################################


######################################################################
# FUNCTION prompt_YNC_int(p_msg1,p_msg2,p_pre_choice) 
######################################################################
FUNCTION prompt_YNC_int(p_msg1,p_msg2,p_pre_choice) 
	DEFINE p_msg1, p_msg2 STRING 
	DEFINE p_pre_choice SMALLINT 
	DEFINE l_msg STRING 
	DEFINE l_ret STRING 

	CASE p_pre_choice 
		WHEN 1 
			LET l_ret = fgl_winbutton(p_msg1,p_msg2,"Yes","Yes|No|Cancel","Question",1) 
		WHEN 3 
			LET l_ret = fgl_winbutton(p_msg1,p_msg2,"Cancel","Yes|No|Cancel","Question",1) 
		OTHERWISE 
			LET l_ret = fgl_winbutton(p_msg1,p_msg2,"No","Yes|No|Cancel","Question",1) 
	END CASE 

	CASE l_ret 
		WHEN "Yes" 
			RETURN 1 
		WHEN "No" 
			RETURN 0 
		OTHERWISE --cancel returns NULL AND raises int_flag = 1 
			LET int_flag = true 
			RETURN NULL 
	END CASE 

END FUNCTION 
######################################################################
# END FUNCTION prompt_YNC_int(p_msg1,p_msg2,p_pre_choice) 
######################################################################


######################################################################
# FUNCTION huhoneedsfixing(p_msg1,p_msg2)
#
#
######################################################################
FUNCTION huhoneedsfixing(p_msg1,p_msg2) 
	DEFINE p_msg1, p_msg2 STRING 
	DEFINE l_msg STRING 

	LET l_msg = "HuHo - This needs fixing\n", p_msg1 clipped, "\n4GL-File:", p_msg2 

	CALL fgl_winmessage("HuHo - This needs fixing",l_msg,"alert") 

END FUNCTION 
######################################################################
# END FUNCTION huhoneedsfixing(p_msg1,p_msg2)
######################################################################


######################################################################
# Option 1 - classic "press any key TO continue - TO view a form/windows as long the user wants TO.,.
#
#
######################################################################
FUNCTION eventsuspend() 

	MENU 
		ON ACTION "Done" 
			EXIT MENU 
	END MENU 

END FUNCTION 
######################################################################
# END Option 1 - classic "press any key TO continue - TO view a form/windows as long the user wants TO.,.
######################################################################


######################################################################
# FUNCTION eventoptions(p_event_model, p_ret)
#
#	huho 15.09.2018
#
# Option 1 - classic "press any key TO continue - TO view a form/windows as long the user wants TO.,.
#
# toolbar buttons too choose FROM i.e. 1/2   Yes/No   show/close
######################################################################
FUNCTION eventoptions(p_event_model, p_ret) 
	DEFINE p_event_model STRING 
	DEFINE p_ret STRING
	DEFINE l_ret STRING 
	DEFINE l_msgstr STRING 
	DEFINE i int 
	DEFINE l_arr_ret DYNAMIC ARRAY OF CHAR(1) 

	FOR i = 1 TO length(p_ret) 
		LET l_arr_ret[i] = p_ret[i] 
	END FOR 
	#CALL fgl_setkeylabel("Option1",argLabel1)
	#CALL fgl_setkeylabel("Option2",argLabel2)

	LET p_event_model = p_event_model.touppercase() 

	CASE p_event_model 
		WHEN "DONEDETAILS" 
			MENU 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","lib_tool_prompt","eventOptions") 

					#ON ACTION "WEB-HELP"
					#	CALL onlineHelp(getModuleId(),NULL)

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				ON ACTION "Done" 
					LET l_ret = p_ret[1] 
					EXIT MENU 

				ON ACTION "DETAILS" 
					LET l_ret = p_ret[2] 
					EXIT MENU 

			END MENU 

		OTHERWISE 
			LET l_msgstr = "Invalid argument <eventModel> ->", trim(p_event_model), "<- used for function eventOptions" 
			CALL fgl_winmessage("Error",l_msgstr,"error") 
			LET l_ret = p_ret[1] 

	END CASE 

	LET int_flag = false 
	LET quit_flag = false 

	RETURN l_ret 

END FUNCTION 
######################################################################
# END FUNCTION eventoptions(p_event_model, p_ret)
######################################################################


######################################################################
# FUNCTION confirm_operation(l_xpos,l_ypos,l_msg)
#
#	#Eric - Used by Code Generator
#
# Option 1 - classic "press any key TO continue - TO view a form/windows as long the user wants TO.,.
#
# toolbar buttons too choose FROM i.e. 1/2   Yes/No   show/close
######################################################################
FUNCTION confirm_operation(l_xpos,l_ypos,l_msg) 
	DEFINE l_xpos SMALLINT
	DEFINE l_ypos SMALLINT
	DEFINE l_msg char(40) 
	DEFINE l_reply CHAR(5) 
	DEFINE l_xaction SMALLINT	 
	DEFINE l_prpmsg char(60) 
	
	LET l_reply = fgl_winbutton("",l_msg,"Yes","Yes|No|Cancel","question",0) 
	CASE 
		WHEN l_reply = "Yes" 
			LET l_xaction= 2 
		WHEN l_reply = "No" 
			LET l_xaction= 1 
		WHEN l_reply = "Cancel" 
			LET l_xaction= 0 
		OTHERWISE 
			LET l_xaction= 1 
	END CASE 
	RETURN l_xaction 
END FUNCTION ## confirm_operation 
######################################################################
# END FUNCTION confirm_operation(l_xpos,l_ypos,l_msg)
######################################################################