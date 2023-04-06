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

	Source code beautified by beautify.pl on 2020-01-02 10:35:08	$Id: $
}



#
{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module - compareuser.4gl
# Purpose - Provides a FUNCTION (compare_user_access) which allows one
#           sign_on_code access TO be tested against another users
#           sign_on_code
#

GLOBALS "../common/glob_GLOBALS.4gl" 

#FUNCTION PURPOSE:
#  This FUNCTION determines IF user "p_kandoouser_sign_on_code" has access TO the a given
#  user "fv_user_code". Access tested in the following method:
#  -Compares user security levels FOR the current module named (p_module_code)
#      Note: IF no module IS defined, the kandoouser security level IS used.
#  -Compares user GL access masks DEFINE FOR each module. FOR example,
#      IF p_kandoouser_sign_on_code has a mask defined as AK-???-???? AND p_user_code has only
#      a mask defined as AK-SAK-????. "p_kandoouser_sign_on_code" has a higher level than
#      "p_user_code" so access would be granted TO p_kandoouser_sign_on_code, but IF p_user_code
#      tried TO access p_kandoouser_sign_on_code, it would be denied.
#      Note: IF no module masks are defined, the kandoouser acct_mask_code will
#      be used FOR the testing.

FUNCTION compare_user_access(p_cmpy,p_kandoouser_sign_on_code,p_user_code,p_module_code,p_access_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_kandoouser_sign_on_code CHAR(8) 
	DEFINE p_user_code LIKE kandoouser.sign_on_code
	DEFINE p_module_code LIKE kandoomask.module_code
	DEFINE p_access_code LIKE kandoomask.access_type_code
	DEFINE l_msgresp LIKE language.yes_flag
	DEFINE l_found_flag SMALLINT 
	DEFINE l_found_mod_flag SMALLINT 
	DEFINE l_kandoouser1 RECORD LIKE kandoouser.* 
	DEFINE l_kandoouser2 RECORD LIKE kandoouser.* 
	DEFINE l_kandoomask1 RECORD LIKE kandoomask.* 
	DEFINE l_mask_code LIKE kandoomask.acct_mask_code 
	DEFINE l_security_1 LIKE kandoomodule.security_ind 
	DEFINE l_security_2 LIKE kandoomodule.security_ind 
	DEFINE i SMALLINT 

	SELECT * 
	INTO l_kandoouser1.* 
	FROM kandoouser 
	WHERE sign_on_code = p_kandoouser_sign_on_code 
	IF (status=notfound) THEN 
		#9200 "Unable TO find user <VALUE>"
		LET l_msgresp = kandoomsg("U", 9200, p_kandoouser_sign_on_code) 
		RETURN false 
	END IF 

	SELECT * 
	INTO l_kandoouser2.* 
	FROM kandoouser 
	WHERE sign_on_code = p_user_code 
	IF (status=notfound) THEN 
		#9200 "Unable TO find user <VALUE>"
		LET l_msgresp = kandoomsg("U", 9200, p_user_code) 
		RETURN false 
	END IF 

	SELECT security_ind 
	INTO l_security_1 
	FROM kandoomodule 
	WHERE cmpy_code = p_cmpy 
	AND user_code = p_kandoouser_sign_on_code 
	AND module_code= p_module_code 
	IF (status=notfound) THEN 
		LET l_security_1 = l_kandoouser1.security_ind 
	END IF 

	SELECT security_ind 
	INTO l_security_2 
	FROM kandoomodule 
	WHERE cmpy_code = p_cmpy 
	AND user_code = p_user_code 
	AND module_code = p_module_code 
	IF (status=notfound) THEN 
		LET l_security_2 = l_kandoouser2.security_ind 
	END IF 

	#CHECK SECURITY LEVELS FIRST
	IF l_security_1 < l_security_2 THEN 
		RETURN false 
	END IF 

	#CHECK IF ACCESS TO GL MASK STRUCTURE IS GREATER OR THE SAME
	DECLARE c_kandoomask CURSOR FOR 
	SELECT * 
	INTO l_kandoomask1.* 
	FROM kandoomask 
	WHERE cmpy_code = p_cmpy 
	AND user_code = p_kandoouser_sign_on_code 
	AND module_code = p_module_code 
	AND (access_type_code = p_access_code OR 
	access_type_code = "3") 

	LET l_found_flag = false 
	LET l_found_mod_flag = false 
	FOREACH c_kandoomask 
		LET l_found_flag = true 
		DECLARE c_kandoomask2 CURSOR FOR 
		SELECT acct_mask_code 
		INTO l_mask_code 
		FROM kandoomask 
		WHERE cmpy_code = p_cmpy 
		AND user_code = p_user_code 
		AND module_code = p_module_code 
		AND (access_type_code = p_access_code OR 
		access_type_code = "3") 
		FOREACH c_kandoomask2 
			LET l_found_mod_flag = true 
			IF compare_mask_code(l_kandoomask1.acct_mask_code, 
			l_mask_code) 
			THEN 
				RETURN true 
			END IF 
		END FOREACH 
		IF NOT l_found_mod_flag THEN #compare against user2 kandoouser acct_mask 
			IF compare_mask_code(l_kandoomask1.acct_mask_code, 
			l_kandoouser2.acct_mask_code) 
			THEN 
				RETURN true 
			END IF 
		END IF 
	END FOREACH 

	#IF NO GL MODULE MASK DEFINED - USE kandoouser ACCT_MASK_CODE
	IF NOT l_found_flag THEN 
		DECLARE c_kandoomask3 CURSOR FOR 
		SELECT acct_mask_code 
		INTO l_mask_code 
		FROM kandoomask 
		WHERE cmpy_code = p_cmpy 
		AND user_code = p_user_code 
		AND module_code = p_module_code 
		AND (access_type_code = p_access_code OR 
		access_type_code = "3") 
		FOREACH c_kandoomask3 
			LET l_found_mod_flag = true 
			IF compare_mask_code(l_kandoouser1.acct_mask_code, 
			l_mask_code) 
			THEN 
				RETURN true 
			END IF 
		END FOREACH 
		IF NOT l_found_mod_flag THEN #compare against user2 kandoouser acct_mask 
			IF compare_mask_code(l_kandoouser1.acct_mask_code, 
			l_kandoouser2.acct_mask_code) 
			THEN 
				RETURN true 
			END IF 
		END IF 
	END IF 

	RETURN false 

END FUNCTION {compare_user_access} 



FUNCTION compare_mask_code(p_mask1_code, p_mask2_code) 
	DEFINE p_mask1_code LIKE kandoomask.acct_mask_code 
	DEFINE p_mask2_code LIKE kandoomask.acct_mask_code 
	DEFINE i SMALLINT
	DEFINE r_valid_flag SMALLINT		 

	FOR i = 1 TO length(p_mask1_code) 
		IF p_mask1_code[i,i] = "?" OR 
		p_mask1_code[i,i] = p_mask2_code[i,i] 
		THEN 
			LET r_valid_flag = true 
		ELSE 
			LET r_valid_flag = false 
			EXIT FOR 
		END IF 
	END FOR 

	RETURN r_valid_flag 

END FUNCTION {compare_mask_code} 


