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
# Purpose - Allows the user TO enter cash receipts FROM customers
# \brief module A32 IS the head program FOR cash receipting  (without application)

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl" 
GLOBALS "../ar/A3_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/A31_GLOBALS.4gl" 
GLOBALS "../ar/A32_GLOBALS.4gl" 

###########################################################################
# FUNCTION A32_main()
#
#
###########################################################################
FUNCTION A32_main() 

	CALL setModuleId("A32")  

	IF enter_cashreceipt(
		glob_rec_kandoouser.cmpy_code,
		glob_rec_kandoouser.sign_on_code,
		0, # invoice number
		0 # application indicator
		) THEN 

	END IF 

END FUNCTION 
###########################################################################
# END FUNCTION A32_main()
###########################################################################