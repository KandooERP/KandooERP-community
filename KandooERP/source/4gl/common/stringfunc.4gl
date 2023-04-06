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

}



{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file stringfunc
# \brief This module contains string methods written in 4gl
# 
#

FUNCTION pad_string (p_instring,p_inchar,p_max_length,p_pad_direction)
DEFINE p_instring STRING		# in string
DEFINE r_outstring STRING		# string returned
DEFINE p_inchar NCHAR(1)        # character to be repeated
DEFINE p_max_length	SMALLINT			# maximum length of returned string
DEFINE ind SMALLINT
DEFINE p_padd_direction	CHAR(1)	# left pad or right pad (L/R)
DEFINE nchars_to_add SMALLINT
DEFINE pad_string STRING
DEFINE p_pad_direction CHAR(1)
LET nchars_to_add = p_max_length - length(p_instring)
LET r_outstring = p_instring clipped

# build the pad string block
INITIALIZE pad_string TO NULL
FOR ind = 1 TO nchars_to_add
	LET pad_string = pad_string CLIPPED,p_inchar
END FOR
	
CASE p_pad_direction
	WHEN "R"
		LET r_outstring = p_instring CLIPPED,pad_string CLIPPED
		RETURN r_outstring
	WHEN "L"
		LET r_outstring = pad_string CLIPPED,p_instring CLIPPED
		RETURN r_outstring
	OTHERWISE
		RETURN "-1"
END CASE
END FUNCTION


