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

	Source code beautified by beautify.pl on 2020-01-02 10:35:02	$Id: $
}


# FUNCTION ac_format allows the user TO FORMAT the account OUTPUT

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

#######################################################################
# FUNCTION ac_form(p_cmpy, p_value_amt, p_type_ind, p_style)
#
#
#######################################################################
FUNCTION ac_form(p_cmpy, p_value_amt, p_type_ind, p_style) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_value_amt money(16,2) 
	DEFINE p_type_ind CHAR(1) 
	DEFINE p_style LIKE glparms.style_ind 
	DEFINE l_return_look CHAR(20) 
	DEFINE l_retry SMALLINT 


	LABEL anothergo: 
	LET l_retry = 0 
	CASE 
		WHEN (p_style = 1) 
			# change around the Income, Liability & Networth
			IF p_type_ind = "I" 
			OR p_type_ind = "L" 
			OR p_type_ind = "N" THEN 
				LET p_value_amt = 0 - p_value_amt + 0 
			END IF 
			LET l_return_look = p_value_amt USING "(((,(((,(((,((&.&&)" 
		WHEN (p_style = 2) 
			LET l_return_look = p_value_amt USING "##,###,###,##&.&&" 
			IF p_value_amt < 0 THEN 
				LET l_return_look = l_return_look[1,17], " CR" 
			ELSE 
				LET l_return_look = l_return_look[1,17], " DR" 
			END IF 
		WHEN (p_style = 3) 
			LET l_return_look = p_value_amt USING "----,---,---,--&.&&" 
		WHEN (p_style = 4) 
			LET l_return_look = p_value_amt USING "$$$$,$$$,$$$,$$&.&&" 
		WHEN (p_style = 5) 
			LET l_return_look = p_value_amt USING "####,###,###,##&.&&" 
		WHEN (p_style = 6) 
			LET l_return_look = p_value_amt USING "----,---,---,--&.&&" 
		WHEN (p_style = 7) 
			LET l_return_look = p_value_amt USING "(((,(((,(((,($&.&&)" 
		OTHERWISE 

			SELECT style_ind INTO p_style FROM glparms 
			WHERE cmpy_code = p_cmpy 
			AND key_code = "1" 

			IF p_style < 1 
			OR p_style > 7 THEN 
				LET p_style = 1 
			END IF 
			LET l_retry = 1 

	END CASE 
	IF l_retry = 1 THEN 
		GOTO anothergo 
	END IF 

	RETURN (l_return_look) 
END FUNCTION 


