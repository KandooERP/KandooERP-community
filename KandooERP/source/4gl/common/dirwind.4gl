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

	Source code beautified by beautify.pl on 2020-01-02 10:35:10	$Id: $
}




#
# Show the Directory will list out the contents of the directory entered
#

FUNCTION show_directory() 
	DEFINE l_directory CHAR(50) 
	DEFINE l_string CHAR(256) 

	DEFER QUIT 
	DEFER INTERRUPT 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 
	--   OPEN WINDOW unix_win1 AT 5,10  -- albo  KD-758
	--      with 2 rows, 50 columns
	--      ATTRIBUTE(border)
	--   prompt "Enter UNIX Pathname: " FOR l_directory --albo
	LET l_directory = promptInput("Enter UNIX Pathname: ","",50) -- albo 
	IF int_flag OR quit_flag 
	OR l_directory IS NULL THEN 
		LET int_flag = false 
		LET quit_flag = false 
		LET l_directory = NULL 
	ELSE 
		LET l_string = "ls -f ",l_directory clipped,"| sort |pg" 
		RUN l_string 
	END IF 
	--   CLOSE WINDOW unix_win1  -- albo  KD-758
END FUNCTION 


