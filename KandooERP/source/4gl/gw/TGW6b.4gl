{
###########################################################################
# This program IS free software; you can redistribute it AND/OR modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 2 of the License, OR (at your
# option) any later version.
#
# This program IS distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License FOR more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; IF NOT, write TO the Free Software Foundation, Inc.,
# 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
#
###########################################################################

	Source code beautified by beautify.pl on 2020-01-03 10:10:06	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "T_GW_GLOBALS.4gl" 
GLOBALS "TGW6_GLOBALS.4gl" 

# Purpose - Manegement REPORT Groups Maintenance

FUNCTION error_trap(pv_error_code) 
	DEFINE msgstr STRING 
	DEFINE pv_error_code INTEGER 
	DEFINE lv_sql_message CHAR(78) 
	DEFINE lv_dummy CHAR(1) 
	DEFINE lv_date_stamp DATE 
	DEFINE lv_time_stamp DATETIME hour TO second 
	DEFINE ret_val SMALLINT 


	IF pv_error_code = 0 THEN 

		RETURN false 
	END IF 

	#OPEN WINDOW w0_errors AT 6,4 WITH 11 ROWS, 70 COLUMNS
	#            ATTRIBUTE(BORDER, WHITE)

	IF int_flag OR quit_flag THEN 

		CALL interrupted() RETURNING ret_val 
		#CLOSE WINDOW w0_errors
		RETURN true 
	END IF 

	#DISPLAY "     Error Reporting Screen " AT 4,20
	LET msgstr = msgstr, "Please REPORT the following error TO the Help Desk: \n" 


	LET lv_date_stamp = today 
	LET lv_time_stamp = time 

	LET msgstr = msgstr, lv_date_stamp USING "dd/mm/yyyy" , "\n" 
	LET msgstr = msgstr, lv_time_stamp , "\n" 


	--- IF this IS a locking error THEN explain that the user can NOT UPDATE
	--- OR delete a RECORD locked by another user OTHERWISE display
	--- a full error MESSAGE with a "REPORT TO help desk" MESSAGE

	CASE 
		WHEN pv_error_code = -67 # invalid argument 
			LET msgstr = msgstr, "An unknown approval type was passed TO the program" 

		WHEN pv_error_code = -68 # no RECORD was found TO UPDATE 
			LET msgstr = msgstr, "An invalid option SET was passed TO the menu FUNCTION" 

		WHEN pv_error_code = -69 # no RECORD was found TO UPDATE 
			LET msgstr = msgstr, "No RECORD was found TO UPDATE" 

		WHEN pv_error_code = -459 # informix-online was shut down. 
			LET msgstr = msgstr, "Your session has been terminated." 

			LET msgstr = msgstr, "Please log off AND log back in TO restart." 
			CALL fgl_winmessage("Error",msgStr,"error") 
			EXIT program 

		WHEN sqlca.sqlerrd[2] = -144 
			LET msgstr = msgstr, "Another user has locked this record. " 

			LET msgstr = msgstr, "You can NOT access it AT the same time." 

		WHEN sqlca.sqlerrd[2] = -107 
			LET msgstr = msgstr, "Another user IS currently updating OR deleting this record. " 
			LET msgstr = msgstr, "You can NOT both alter it AT the same time." 

		WHEN sqlca.sqlerrd[2] = -113 
			LET msgstr = msgstr, "Another user has locked this table exclusively. " 
			LET msgstr = msgstr, "You can NOT use it AT the same time. " 

		WHEN pv_error_code = 100 
			LET msgstr = msgstr, "SQL Error Number 100, RECORD Not Found. " 
			LET msgstr = msgstr, "Please note the error AND REPORT it TO the Help Desk. " 

		OTHERWISE 
			LET msgstr = msgstr, "SQL Error Number ", trim(pv_error_code) ,"\n", 
			"ISAM Error Number ", trim(SQLCA.SQLERRD[2]),"\n" 

			LET msgstr = msgstr, err_get(pv_error_code) 



	END CASE 
	CALL fgl_winmessage("Warning",msgStr,"warning") 

	#CLOSE WINDOW w0_errors

	RETURN true 

END FUNCTION 

------------------------------------------------------------------------------

FUNCTION interrupted() 

	IF int_flag OR quit_flag THEN 

		LET int_flag = false 
		LET quit_flag = false 
		# ERROR "Current Process Interrupted" ATTRIBUTE(YELLOW, REVERSE)
		OPTIONS MESSAGE line LAST 
		MESSAGE "Current Process Interrupted" attribute(YELLOW, reverse) 
		SLEEP 1 
		OPTIONS MESSAGE line FIRST 
		RETURN true 
	END IF 

	RETURN false 

END FUNCTION 


------------------------------------------------------------------------------

FUNCTION set_options() 
	OPTIONS INPUT wrap 
	OPTIONS FIELD ORDER unconstrained 
	#ACCEPT KEY ESC,
	#MESSAGE LINE FIRST,
	#PROMPT LINE 2,
	#COMMENT LINE LAST,
	#INPUT WRAP#,
	#INSERT KEY F1,
	#DELETE KEY F20, --- disable the delete FUNCTION
	--- in the INPUT ARRAY (delete IS now handled with the
	--- ON KEY clause.
	#NEXT KEY F3,
	#PREVIOUS KEY F4,
	#FIELD ORDER UNCONSTRAINED

	--- Set the lock mode TO time out with an "Unable TO obtain Lock" MESSAGE

	SET LOCK MODE TO NOT wait 

END FUNCTION 

------------------------------------------------------------------------
