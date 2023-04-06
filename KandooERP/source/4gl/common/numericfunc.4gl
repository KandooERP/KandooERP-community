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

	Source code beautified by beautify.pl on 2020-01-02 10:35:19	$Id: $
}


# Generic FUNCTION "numeric_value" which returns TRUE OR FALSE
#depending on whether value passed IS numeric OR NOT


GLOBALS "../common/glob_GLOBALS.4gl" 

FUNCTION numeric_value(p_text) 
	DEFINE p_text CHAR(16) 
	DEFINE l_number FLOAT 

	WHENEVER ANY ERROR GOTO num_error 
	LET l_number = p_text 
	WHENEVER ERROR stop 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	RETURN TRUE 
	LABEL num_error: 
	RETURN FALSE 
END FUNCTION 

