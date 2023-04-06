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

	Source code beautified by beautify.pl on 2020-01-02 10:35:35	$Id: $
}



#   FUNCTION sqrt(x)
#                  - accepts as an argument a (14,4) DECIMAL AND a verbose
#                    indicator which should equal 1 FOR DISPLAY MESSAGEs OR
#                    0 FOR do NOT DISPLAY MESSAGEs.
#                  - returns the square root as a floating point DECIMAL
#                    with maximum accuracy TO six DECIMAL places
#renamed because of the conflict with <Anton Dickinson> built-in FUNCTION

GLOBALS "../common/glob_GLOBALS.4gl" 

FUNCTION sqrt_func(p_x,p_verbose) 
	DEFINE p_x DECIMAL(16,6)
	DEFINE p_verbose SMALLINT
	DEFINE l_msgresp LIKE language.yes_flag
	DEFINE y, s DECIMAL(32,12) 
	DEFINE u, l, t DECIMAL(16,6)
	DEFINE l_cnt SMALLINT
	DEFINE l_inverse SMALLINT	 

	CASE 
		WHEN p_x IS NULL 
			RETURN 0 
		WHEN p_x = 0 
			RETURN 0 
		WHEN p_x = 1 
			RETURN 1 
		WHEN p_x < 0 
			IF p_verbose THEN 
				LET l_msgresp = kandoomsg("U",9924,"") 
				#9924 " Cannot calculate the square root of a negative number"
			END IF 
			RETURN 0 
		WHEN p_x < 1 
			LET l_inverse = true 
			LET p_x = 1/p_x 
			EXIT CASE 
		WHEN p_x > 1 
			LET l_inverse = false 
			EXIT CASE 
		OTHERWISE 
			IF p_verbose THEN 
				LET l_msgresp = kandoomsg("U",9925,"") 
				#9925 "Cannot Calculate the Square Root of a non-numeric value."
			END IF 
			RETURN 0 
	END CASE 
	LET l_cnt = 0 
	LET s = 0 
	LET l = 0 
	LET u = p_x 
	LET y = p_x 
	WHILE s != y 
		LET l_cnt = l_cnt + 1 
		LET y = s 
		LET t = (l+u)/2 
		LET s = t * t 
		IF s < p_x THEN 
			LET l = t 
		END IF 
		IF s > p_x THEN 
			LET u = t 
		END IF 
		IF l_cnt > 32 THEN 
			EXIT WHILE 
		END IF 
	END WHILE 
	IF l_inverse THEN 
		LET t = 1/t 
	END IF 
	RETURN t 
END FUNCTION 


