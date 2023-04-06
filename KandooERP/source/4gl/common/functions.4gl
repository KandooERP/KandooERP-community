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

	Source code beautified by beautify.pl on 2020-01-02 10:35:11	$Id: $
}




GLOBALS "../common/glob_GLOBALS.4gl" 


FUNCTION interrupt_handler() 

	IF int_flag OR quit_flag THEN 
		LET int_flag = 0 
		LET quit_flag = 0 
		ERROR " Exiting Process " 
	END IF 

END FUNCTION 
# interrupt_handler()


############################################################################


FUNCTION error_handler(p_err_message) 
	DEFINE p_err_message CHAR(78) 
	DEFINE l_sql_message CHAR(78)
	DEFINE l_date DATE 
	DEFINE l_time DATETIME hour TO minute 
	DEFINE r_response CHAR(1)

	-- OPEN WINDOW s0_errors AT 6,6 WITH 11 ROWS, 70 COLUMNS   -- albo  KD-755
	--     ATTRIBUTE(BORDER, WHITE, MESSAGE LINE FIRST)

	IF int_flag OR quit_flag THEN 
		CALL interrupt_handler() 
		RETURN "N" 
	END IF 

	DISPLAY " Error Reporting Screen " at 2,20 
	DISPLAY " The following error has occured: " at 4,2 

	LET l_date = today 
	LET l_time = CURRENT hour TO minute 

	DISPLAY l_date USING "ddd dd mmm yyyy" at 11,2 
	DISPLAY l_time at 11,62 

	DISPLAY p_err_message at 6,3 attribute (RED) 

	IF sqlca.sqlerrd[2] = -107 THEN 
		DISPLAY " Another user IS currently updating OR deleting this record. " 
		at 8,3 
		DISPLAY " You can NOT both alter it AT the same time. " at 9,10 

	ELSE 
		DISPLAY "SQL Error Number ", sqlca.sqlcode at 7,3 attribute (RED) 
		LET l_sql_message = err_get(sqlca.sqlcode) 
		DISPLAY l_sql_message at 8,3 attribute (RED) 
		DISPLAY " Please note the error AND REPORT it TO the help desk. " at 10,8 

	END IF 

	-- PROMPT " Press <Y> TO retry OR any other key TO abort " FOR CHAR r_response -- albo
	LET r_response = promptInput(" Press <Y> TO retry OR any other key TO abort ","",1) -- albo 

	IF r_response IS NULL THEN 
		LET r_response = "N" 
	END IF 

	-- CLOSE WINDOW s0_errors  -- albo  KD-755

	RETURN upshift(r_response) 

END FUNCTION 
# error_handler()


############################################################################


FUNCTION cursor_boundary() 

	ERROR " No more records in this direction " 

END FUNCTION 
# cursor_boundary()


############################################################################


FUNCTION record_count_message(p_record_count) 
	DEFINE p_record_count INTEGER 

	IF p_record_count THEN 
		ERROR " ", p_record_count, " Record(s) selected " 
	ELSE 
		ERROR " No records were selected FROM the database " 
	END IF 

END FUNCTION 
# record_count_MESSAGE()


