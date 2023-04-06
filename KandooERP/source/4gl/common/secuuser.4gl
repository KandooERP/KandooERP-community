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

	Source code beautified by beautify.pl on 2020-01-02 10:35:33	$Id: $
}


#
{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
############################################################
# secuuser.4gl
# This FUNCTION retreives the user_mask_code FROM the
# kandoouser table AND returns two acct codes
# 1 acct_mask_code =    The l_rec_kandoouser acct mask code with
#                       all unresolved segments = "?"
# 2 l_user_scan_code = The l_rec_kandoouser acct mask code
#                       with all trailing "?" SET TO "*"
############################################################

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

############################################################
# FUNCTION user_security(p_cmpy, p_kandoouser_sign_on_code)
#----------------------------------------------------------
# This FUNCTION should be replaced by the user_mask_security() FUNCTION
#    which returns valid account masks according TO those defined
#    in the kandoomask table FOR the current user/module
############################################################
FUNCTION user_security(p_cmpy,p_kandoouser_sign_on_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code 
	DEFINE l_rec_kandoouser RECORD LIKE kandoouser.* 
	DEFINE l_user_scan_code LIKE kandoouser.acct_mask_code 
	DEFINE l_idx SMALLINT

	SELECT kandoouser.acct_mask_code 
	INTO l_rec_kandoouser.acct_mask_code 
	FROM kandoouser 
	WHERE kandoouser.cmpy_code = p_cmpy 
	AND kandoouser.sign_on_code = p_kandoouser_sign_on_code 
	IF STATUS = notfound THEN 
		INITIALIZE l_rec_kandoouser.acct_mask_code TO NULL 
	END IF 
	IF l_rec_kandoouser.acct_mask_code IS NULL 
	OR l_rec_kandoouser.acct_mask_code = " " THEN 
		CALL build_mask(p_cmpy,"??????????????????"," ") 
		RETURNING l_rec_kandoouser.acct_mask_code 
	END IF 
	LET l_user_scan_code = l_rec_kandoouser.acct_mask_code 
	FOR l_idx = 18 TO 1 
		step -1 
		IF l_user_scan_code[l_idx,l_idx] = " " 
		OR l_user_scan_code[l_idx,l_idx] = "?" 
		OR l_user_scan_code[l_idx,l_idx] IS NULL THEN 
			LET l_user_scan_code[l_idx,l_idx] = "*" 
		ELSE 
			EXIT FOR 
		END IF 
	END FOR 

	RETURN l_rec_kandoouser.acct_mask_code, 
	l_user_scan_code 
END FUNCTION {user_security} 



############################################################
# FUNCTION user_mask_security(p_cmpy,p_kandoouser_sign_on_code,p_prog_name,p_access_code)
#----------------------------------------------------------
# This FUNCTION replaces the user_security() FUNCTION TO take advantage
#    of the enhance security modifications. This FUNCTION returns all
#    valid account masks according TO those defined in the kandoomask table
#    FOR the current user/module. IF no kandoomask rows exist - the kandoouser
#    acct_mask_code IS be returned.
############################################################
FUNCTION user_mask_security(p_cmpy,p_kandoouser_sign_on_code,p_prog_name,p_access_code) 
	DEFINE p_cmpy LIKE coa.cmpy_code 
	DEFINE p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code 
	DEFINE p_prog_name CHAR(3) 
	DEFINE p_access_code CHAR(1) 
	DEFINE l_module_code CHAR(1) 
	DEFINE l_valid_mask CHAR(512) 
	DEFINE l_acct_code LIKE coa.acct_code 
	DEFINE l_acct_mask_code LIKE kandoomask.acct_mask_code 
	DEFINE l_rec_kandoouser RECORD LIKE kandoouser.* 
	DEFINE l_user_scan_code LIKE kandoouser.acct_mask_code 
	DEFINE l_rec_kandoomask RECORD LIKE kandoomask.* 
	DEFINE l_idx INTEGER 
	DEFINE l_cnt INTEGER 
	DEFINE i SMALLINT 
	DEFINE l_acct_valid SMALLINT 

	LET l_cnt = 0 
	LET l_module_code = p_prog_name[1,1] 

	SELECT kandoouser.acct_mask_code 
	INTO l_rec_kandoouser.acct_mask_code 
	FROM kandoouser 
	WHERE kandoouser.cmpy_code = p_cmpy 
	AND kandoouser.sign_on_code = p_kandoouser_sign_on_code 
	IF STATUS = notfound THEN 
		INITIALIZE l_rec_kandoouser.acct_mask_code TO NULL 
	END IF 
	IF l_rec_kandoouser.acct_mask_code IS NULL 
	OR l_rec_kandoouser.acct_mask_code = " " THEN 
		CALL build_mask(p_cmpy,"??????????????????"," ") 
		RETURNING l_rec_kandoouser.acct_mask_code 
	END IF 

	DECLARE c_validmask CURSOR FOR 
	SELECT * 
	INTO l_rec_kandoomask.* 
	FROM kandoomask 
	WHERE cmpy_code = p_cmpy 
	AND user_code = p_kandoouser_sign_on_code 
	AND module_code = l_module_code 

	FOREACH c_validmask 
		IF p_access_code = "3" OR 
		l_rec_kandoomask.access_type_code = "3" OR 
		l_rec_kandoomask.access_type_code = p_access_code 
		THEN 
			LET l_cnt = l_cnt + 1 
			IF l_cnt = 1 THEN 
				LET l_valid_mask = " AND (" 
			ELSE 
				LET l_valid_mask = l_valid_mask clipped, " OR " 
			END IF 
			LET l_valid_mask = l_valid_mask clipped, 
			" coa.acct_code matches \"", 
			l_rec_kandoomask.acct_mask_code, 
			"\" " 
			IF length(l_valid_mask) > 464 THEN 
				EXIT FOREACH 
			END IF 
		END IF 
	END FOREACH 

	IF l_cnt = 0 THEN 
		LET l_valid_mask = "AND coa.acct_code matches \"", 
		l_rec_kandoouser.acct_mask_code, 
		"\" " 
	ELSE 
		LET l_valid_mask = l_valid_mask clipped, ")" 
	END IF 

	RETURN l_rec_kandoouser.acct_mask_code, l_valid_mask clipped 
END FUNCTION 
