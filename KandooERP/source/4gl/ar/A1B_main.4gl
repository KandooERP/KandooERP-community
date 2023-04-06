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

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl" 
GLOBALS "../ar/A1_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/A1B_GLOBALS.4gl" 

###########################################################################
# MAIN
#
# A1B - Customer Ledger Scan
#               Allows the user TO scan customer activity in either
#               transaction date OR entry sequence. Allows drill down
#               TO source transactions.
#
# Accepts (2) Arguments (both optional)
#
#    1.  ORDER BY Clause - (D) Date - (S) Entry Sequence(default)
#    2.  Customer Code
#
# This program called FROM main customer inquiry (A12) WHEN user SELECT
# ledger option FROM Detail window.
#
###########################################################################
MAIN 

	DEFER quit 
	DEFER interrupt 

	CALL setModuleId("A1B") 
	CALL ui_init(0) 
	CALL authenticate(getmoduleid()) 
	CALL init_a_ar() #init a/ar module 

	CALL A1B_main()
		 
END MAIN 
###########################################################################
# END MAIN
###########################################################################