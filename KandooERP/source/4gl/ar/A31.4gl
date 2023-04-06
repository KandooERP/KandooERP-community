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
# \brief module A31 IS the head program FOR cash receipting with application

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl" 
GLOBALS "../ar/A31_GLOBALS.4gl" 
GLOBALS "../ar/A3_GROUP_GLOBALS.4gl" 

###########################################################################
# FUNCTION A31_main()
#
#
###########################################################################
FUNCTION A31_main()

	DEFER quit 
	DEFER interrupt 

	CALL setModuleId("A31") 

	IF enter_cashreceipt(
		glob_rec_kandoouser.cmpy_code,
		glob_rec_kandoouser.sign_on_code,
		0,
		1) THEN 
		# invoice number
	END IF 
	
END FUNCTION 
###########################################################################
# END FUNCTION A31_main() 
###########################################################################