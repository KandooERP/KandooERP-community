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

	Source code beautified by beautify.pl on 2020-01-02 10:35:42	$Id: $
}



# get warehouse group

GLOBALS "../common/glob_GLOBALS.4gl" 

FUNCTION get_waregrp(p_cmpy,p_kandoouser_sign_on_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_kandoouser_sign_on_code LIKE userlocn.sign_on_code 
	DEFINE l_rec_userlocn RECORD LIKE userlocn.* 
	DEFINE l_rec_location RECORD LIKE location.*
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE r_waregrp_code LIKE warehouse.waregrp_code

	LET r_waregrp_code = NULL 
	SELECT * INTO l_rec_userlocn.* FROM userlocn 
	WHERE cmpy_code = p_cmpy 
	AND sign_on_code = p_kandoouser_sign_on_code 
	SELECT * INTO l_rec_location.* FROM location 
	WHERE cmpy_code = p_cmpy 
	AND locn_code = l_rec_userlocn.locn_code 
	IF STATUS = NOTFOUND THEN 
		LET l_msgresp = kandoomsg("W",9401,"") 
	ELSE 
		SELECT waregrp_code INTO r_waregrp_code FROM warehouse 
		WHERE cmpy_code = p_cmpy 
		AND ware_code = l_rec_location.ware_code 
		IF STATUS = NOTFOUND THEN 
			LET l_msgresp = kandoomsg("W",9387,"") 
			#9387 No Warehouse Group exists. Use Warehouse Maintenance TO setup
		END IF 
	END IF 
	RETURN r_waregrp_code 
END FUNCTION 


