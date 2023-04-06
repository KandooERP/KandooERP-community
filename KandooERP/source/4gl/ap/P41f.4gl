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
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_P4_GLOBALS.4gl" 

############################################################
# Module Scope Variables
############################################################


############################################################
# FUNCTION FUNCTION get_whold_tax(p_cmpy_code,p_vend_code,p_vend_type)
#
# Purpose  - get_whold_tax accepts a vendor code AND vendor type AND
#            retrieves the associated withholding tax method, code AND
#            rate, IF applicable.
############################################################
FUNCTION get_whold_tax(p_cmpy_code,p_vend_code,p_vend_type) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_vend_code LIKE vendor.vend_code 
	DEFINE p_vend_type LIKE vendor.type_code 
	DEFINE l_msgresp LIKE language.yes_flag
	DEFINE r_tax_ind LIKE vendortype.withhold_tax_ind 
	DEFINE r_tax_code LIKE tax.tax_code 
	DEFINE r_tax_per LIKE tax.tax_per 

	LET r_tax_code = NULL 
	LET r_tax_per = 0 

	SELECT withhold_tax_ind 
	INTO r_tax_ind 
	FROM vendortype 
	WHERE cmpy_code = p_cmpy_code 
	AND type_code = p_vend_type 

	IF STATUS = NOTFOUND OR 
	r_tax_ind IS NULL THEN 
		LET r_tax_ind = "0" 
	END IF 

	IF r_tax_ind != "0" THEN 
		SELECT tax_code 
		INTO r_tax_code 
		FROM contractor 
		WHERE cmpy_code = p_cmpy_code 
		AND vend_code = p_vend_code 
		IF NOT (STATUS = NOTFOUND) THEN 
			SELECT tax_per 
			INTO r_tax_per 
			FROM tax 
			WHERE cmpy_code = cmp_cmpy 
			AND tax_code = r_tax_code 
			IF STATUS = NOTFOUND THEN 
				LET r_tax_per = 0 
			END IF 
		END IF 
	END IF 

	RETURN r_tax_ind, r_tax_code, r_tax_per 
END FUNCTION