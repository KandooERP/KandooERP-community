GLOBALS "lib_db_globals.4gl"
 
 
#####################################################
# FUNCTION updateConsole()                  --Utility
#####################################################	
FUNCTION updateConsole()
#	DEFINE consoleString STRING
	DEFINE stepString STRING
	DEFINE i SMALLINT

	DISPLAY gl_recStep[step_num].console TO console
	DISPLAY gl_recStep[step_num].title TO header_text
	LET stepString = "Step ", trim(step_num)
	DISPLAY stepString TO lbFormName

	#Show tick icons for the already done steps
	FOR i = step_num TO 10
		LET gl_recStep[i].step_done = NULL
	END FOR

	FOR i = 1 TO step_num -1
		LET gl_recStep[i].step_done = "{CONTEXT}/public/querix/icon/svg/24/ic_done_24px.svg"
	END FOR
	
	FOR i = 1 TO 10
		LET stepString = "Step ", trim(i)
		DISPLAY stepString TO scrStep[i].lb_step_no
		DISPLAY gl_recStep[i].step_name TO scrStep[i].lb_step_name
		DISPLAY gl_recStep[i].step_done TO scrStep[i].lb_step_done
	END FOR

END FUNCTION

#######################################################
# FUNCTION interrupt_installation()
#######################################################
FUNCTION interrupt_installation()
	IF fgl_winquestion("Cancel", "Do you really want TO interrupt installation?\nAll changes will be cancelled", "No", "Yes|No", "question", 1) = "Yes" THEN
		#ROLLBACK WORK
		EXIT PROGRAM
	END IF
END FUNCTION

