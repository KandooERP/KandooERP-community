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

	Source code beautified by beautify.pl on 2020-01-02 10:35:38	$Id: $
}


# validate_string() - Validate that a string IS the correct length
#                     AND does NOT contain illegal characters
GLOBALS "../common/glob_GLOBALS.4gl" 

FUNCTION validate_string(p_string,p_min_length,p_max_length,p_verbose_ind) 
	DEFINE p_string CHAR(30) 
 	DEFINE p_min_length SMALLINT
	DEFINE p_max_length SMALLINT
	DEFINE p_verbose_ind SMALLINT
	DEFINE l_str_length SMALLINT
	DEFINE l_idx SMALLINT
	DEFINE l_cstring CHAR(1) 
	DEFINE l_msgresp LIKE language.yes_flag 

	#invalid character include the following
	# space
	# asterix *
	# pipe symbol |
	# comma ,
	# percentage %
	# opening square bracket [
	# closing square bracket ]
	# double quote "
	# single quote '
	# Exclimation Mark  !
	# greater than >
	# less than <
	# colon :
	# equals =
	# back slash \

	--IF fixed_ind
	IF length(p_string) < p_min_length 
	THEN 
		IF p_verbose_ind THEN 
			LET l_msgresp = kandoomsg("I",9530,p_min_length) 
			#9530 Must enter AT least ## characters
			RETURN FALSE 
		ELSE 
			RETURN FALSE 
		END IF 
	END IF 
	IF length(p_string) > p_max_length 
	THEN 
		IF p_verbose_ind THEN 
			LET l_msgresp = kandoomsg("I",9534,p_max_length) 
			#9534 Must enter no more than ## characters
			RETURN FALSE 
		ELSE 
			RETURN FALSE 
		END IF 
	END IF 
	LET l_str_length = length(p_string) 
	FOR l_idx = 1 TO l_str_length 
		LET l_cstring = p_string[l_idx] 
		IF l_cstring = " " 
		OR l_cstring = "*" 
		OR l_cstring = "|" 
		OR l_cstring = "," 
		OR l_cstring = "%" 
		OR l_cstring = "\[" 
		OR l_cstring = "\]" 
		OR l_cstring = '"' 
		OR l_cstring = "'" 
		OR l_cstring = "!" 
		OR l_cstring = ">" 
		OR l_cstring = "<" 
		OR l_cstring = ":" 
		OR l_cstring = "=" 
		OR l_cstring = "\\" 
		THEN 
			IF p_verbose_ind THEN 
				LET l_msgresp = kandoomsg("I",9531,"") 
				#9531 Invalid character in field
				RETURN FALSE 
			ELSE 
				RETURN FALSE 
			END IF 
		END IF 
	END FOR 
	RETURN TRUE 
END FUNCTION 


