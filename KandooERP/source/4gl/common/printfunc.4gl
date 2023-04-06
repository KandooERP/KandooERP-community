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

###########################################################################
#   Purpose: TO PRINT a file on a device using the command specified in
#            the printcodes table.  FUNCTION returns TRUE OR FALSE.
#
#   Possible Enhancement: Replace PRINT in URS with calls TO this FUNCTION
#
#   NB: The UPDATE of rmsreps IS contained with a WHENEVER ERROR cont.
#   The UPDATE of the PRINT STATUS IS considered NOT critical AND calling
#   programs crash IF lock occurs.
###########################################################################

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

###########################################################################
# FUNCTION rms_print(p_cmpy,p_file_text,p_print_code)
#
#
###########################################################################
FUNCTION rms_print(p_cmpy,p_file_text,p_print_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_file_text CHAR(20) 
	DEFINE p_print_code LIKE printcodes.print_code 
	DEFINE l_rec_printcodes RECORD LIKE printcodes.* 
	DEFINE l_rec_rmsreps RECORD LIKE rmsreps.* 
	DEFINE l_report_code LIKE rmsreps.report_code 
	DEFINE l_temp_text CHAR(30) 
	DEFINE l_print_cmd CHAR(300) 
	DEFINE l_ret_code INTEGER 
	DEFINE x SMALLINT 
	DEFINE y SMALLINT 

	SELECT * INTO l_rec_printcodes.* 
	FROM printcodes 
	WHERE print_code = p_print_code 
	IF status = notfound THEN 
		RETURN false 
	ELSE 
		LET x = length(p_file_text) 
		FOR y = x TO 1 step -1 
			IF p_file_text[y,y] = "." THEN 
				WHENEVER ERROR CONTINUE ## TO handle alpa REPORT codes 
				LET l_report_code = p_file_text[y+1,x] 
				WHENEVER ERROR stop ## TO handle alpa REPORT codes 
				WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
				EXIT FOR 
			END IF 
		END FOR 
		SELECT * INTO l_rec_rmsreps.* 
		FROM rmsreps 
		WHERE cmpy_code = p_cmpy 
		AND report_code = l_report_code 
		LET l_print_cmd= "F=",p_file_text,";C=1", 
		";L=",l_rec_rmsreps.page_length_num USING "<<<<<", 
		";W=",l_rec_rmsreps.report_width_num USING "<<<<<", 
		";",l_rec_printcodes.print_text clipped," 2>>", trim(get_settings_logFile()), 
		"; STATUS=$? ; EXIT $STATUS " 
		RUN l_print_cmd RETURNING l_ret_code 

		IF l_ret_code THEN 
			RETURN false 
		ELSE 
			LET l_temp_text = kandooword("rmsreps.status_text","2") 
			WHENEVER ERROR CONTINUE 
			UPDATE rmsreps 
			SET status_text = l_temp_text 
			WHERE cmpy_code = p_cmpy 
			AND report_code = l_report_code 
			WHENEVER ERROR stop 
			WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
			RETURN true 
		END IF 
	END IF 
END FUNCTION 
###########################################################################
# END FUNCTION rms_print(p_cmpy,p_file_text,p_print_code)
###########################################################################