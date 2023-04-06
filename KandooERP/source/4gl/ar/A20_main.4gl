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
# 1. Default Invoice TAX Code Default is set to customers default tax code, but can be overwritten
# 2. Quantity can be empty; This an be used for comment lines
# 3. Customer "on hold" or "over the credit limit" can not be used
# 4. Tax Code is checked if it uses tax calculation method "X" - 
#    PLUS tax exemption dialog (code & date) will be prompted if it's not available (or current) in the customer properties 
# 5. Ensure, GL Accounts for sales/purchase tax are setup correctly in the tax code setup AZ1
# 6.  
###########################################################################
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl"
GLOBALS "../ar/A2_GROUP_GLOBALS.4gl"  
GLOBALS "../ar/A20_GLOBALS.4gl" 
############################################################################
# MAIN
#
# allows the user TO enter Accounts Receivable Invoices updating inventory
# Note: Tax Codes are retrieved from Customer
############################################################################
MAIN 
	DEFER QUIT 
	DEFER INTERRUPT 
	CALL setModuleId("A20") 
	CALL ui_init(0) #Initial UI Init

	CALL authenticate(getmoduleid()) 
	CALL init_a_ar() #init a/ar module 

	CALL A20_main()
	
END MAIN 
############################################################################
# END MAIN
############################################################################