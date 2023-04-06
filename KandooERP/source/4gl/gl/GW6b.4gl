{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module - GW6b.4gl
# Purpose - Manegement REPORT Groups Maintenance

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 
GLOBALS "../gl/GW6_GLOBALS.4gl" 


############################################################
# FUNCTION error_trap(p_error_code)
#
#
############################################################
FUNCTION error_trap(p_error_code) 
	DEFINE l_msgstr STRING 
	DEFINE p_error_code INTEGER 
	DEFINE l_sql_message CHAR(78) 
	DEFINE l_dummy CHAR(1) 
	DEFINE l_date_stamp DATE 
	DEFINE l_time_stamp DATETIME hour TO second 
	DEFINE l_ret_val SMALLINT 


	IF p_error_code = 0 THEN 

		RETURN false 
	END IF 

	#OPEN WINDOW w0_errors WITH FORM "U999" ATTRIBUTES(BORDER)
	#		CALL windecoration_u("U999")

	IF int_flag OR quit_flag THEN 

		CALL interrupted() RETURNING l_ret_val 
		CLOSE WINDOW w0_errors 
		RETURN true 
	END IF 

	LET l_msgstr = "Please REPORT the following error TO the Help Desk:\n" 
	#DISPLAY " Error Reporting Screen " TO lbLabel1 -- 4,20
	#DISPLAY " Please REPORT the following error TO the Help Desk: " TO lbLabel2  -- 5,12


	LET l_date_stamp = today 
	LET l_time_stamp = time 

	LET l_msgstr = l_msgstr, l_date_stamp USING "dd/mm/yyyy", "\n" # TO lblabel3 -- 11,2 

	LET l_msgstr = l_msgstr, trim(l_time_stamp) # TO lblabel1b -- 11,62 


	--- IF this IS a locking error THEN explain that the user can NOT UPDATE
	--- OR delete a RECORD locked by another user OTHERWISE display
	--- a full error MESSAGE with a "REPORT TO help desk" MESSAGE

	CASE 
		WHEN p_error_code = -67 # invalid argument 
			LET l_msgstr = l_msgstr, "An unknown approval type was passed TO the program" 

		WHEN p_error_code = -68 # no RECORD was found TO UPDATE 
			LET l_msgstr = l_msgstr, "An invalid option SET was passed TO the menu FUNCTION" 

		WHEN p_error_code = -69 # no RECORD was found TO UPDATE 
			LET l_msgstr = l_msgstr, "No RECORD was found TO UPDATE" 

		WHEN p_error_code = -459 # informix-online was shut down. 
			LET l_msgstr = l_msgstr, "Your session has been terminated.\n" 
			LET l_msgstr = l_msgstr, "Please log off AND log back in TO restart." 
			CALL fgl_winmessage("Error",l_msgStr,"error") 
			EXIT PROGRAM 

		WHEN sqlca.sqlerrd[2] = -144 
			LET l_msgstr = l_msgstr, "Another user has locked this record.\n" 
			LET l_msgstr = l_msgstr, "You can NOT access it AT the same time." 

		WHEN sqlca.sqlerrd[2] = -107 
			LET l_msgstr = l_msgstr, "Another user IS currently updating OR deleting this record.\n" 
			LET l_msgstr = l_msgstr, "You can NOT both alter it AT the same time." 

		WHEN sqlca.sqlerrd[2] = -113 
			LET l_msgstr = l_msgstr, "Another user has locked this table exclusively. \n" 
			LET l_msgstr = l_msgstr, "You can NOT use it AT the same time. " 

		WHEN p_error_code = 100 
			LET l_msgstr = l_msgstr, "SQL Error Number 100, RECORD Not Found. \n" 
			LET l_msgstr = l_msgstr, "Please note the error AND REPORT it TO the Help Desk." 

		OTHERWISE 
			LET l_msgstr = l_msgstr, "SQL Error Number:\n", trim(p_error_code), "\n" 
			LET l_msgstr = l_msgstr, "ISAM Error Number ", trim(sqlca.sqlerrd[2]), "\n" 

			LET l_msgstr = l_msgstr, trim(err_get(p_error_code)), "\n" 
			LET l_msgstr = l_msgstr, l_sql_message 
	END CASE 

	CALL fgl_winmessage("Error",l_msgStr,"error") 

	RETURN true 

END FUNCTION 

------------------------------------------------------------------------------


############################################################
# FUNCTION interrupted()
#
#
############################################################
FUNCTION interrupted() 

	IF int_flag OR quit_flag THEN 

		LET int_flag = false 
		LET quit_flag = false 
		OPTIONS MESSAGE line LAST 
		MESSAGE "Current Process Interrupted" 
		SLEEP 1 
		OPTIONS MESSAGE line FIRST 
		RETURN true 
	END IF 

	RETURN false 

END FUNCTION 



############################################################
# FUNCTION set_options()
#
#
############################################################
FUNCTION set_options() 

	OPTIONS #accept KEY esc, 
	INPUT wrap, 
	#INSERT KEY F1,
	#DELETE KEY F20, --- disable the delete FUNCTION
	--- in the INPUT ARRAY (delete IS now handled with the
	--- ON KEY clause.
	#NEXT KEY F3,
	#PREVIOUS KEY F4,
	FIELD ORDER unconstrained 

	--- Set the lock mode TO time out with an "Unable TO obtain Lock" MESSAGE

	SET LOCK MODE TO NOT wait 

END FUNCTION 

------------------------------------------------------------------------
