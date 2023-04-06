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

	Source code beautified by beautify.pl on 2020-01-02 10:35:21	$Id: $
}



# FUNCTION FOR patching up a SELECT statement so it can be passed
# TO another program without any problems.
# AND following this IS the FUNCTION that undoes the SELECT statement etc.
GLOBALS "../common/glob_GLOBALS.4gl" 

FUNCTION parmset(p_query_text) 
	DEFINE p_query_text CHAR(2200) 
	DEFINE i SMALLINT 

	FOR i = 1 TO 512 
		IF p_query_text[i,i] = "\"" THEN 
			LET p_query_text[i,i] = "@" 
		END IF 
	END FOR 

	RETURN p_query_text 
END FUNCTION 

FUNCTION parmunset(p_query_text) 
	DEFINE p_query_text CHAR(2200) 
	DEFINE i SMALLINT 

	DISPLAY "parmunset() p_query_text= ", trim(p_query_text) 
	FOR i = 1 TO 512 
		IF p_query_text[i,i] = "@" THEN 
			LET p_query_text[i,i] = "\"" 
		END IF 
	END FOR 

	RETURN p_query_text 
END FUNCTION 


