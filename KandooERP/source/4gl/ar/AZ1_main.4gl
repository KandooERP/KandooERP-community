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
###########################################################################
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl" 
GLOBALS "../ar/AZ_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/AZ1_GLOBALS.4gl" 

############################################################
# Module Scope Variables
############################################################

##############################################################################
# MAIN
#
# Facility TO SET up AND maintain all tax codes that are used throughout KandooERP.  One tax code should be SET up for each unique rate AND method that IS used TO calculate tax.
# These codes are then linked TO particular Customers, Vendors AND Products as required.  The use of codes (rather than entering the actual percentage), ensures accuracy WHILE still enabling rates TO be changed easily.
# The same Tax Codes are used by the AR, AP AND Inventory Systems.  Therefore, take care when changing OR deleting codes since a change TO a code in one system will apply TO all systems in which it IS used.
##############################################################################
MAIN 

	DEFER quit 
	DEFER interrupt 

	CALL setModuleId("AZ1") 
	CALL ui_init(0) #initial ui init 
	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_a_ar() #init a/ar module #KD-2113

	CALL AZ1_main()
	
END MAIN 
##############################################################################
# END MAIN
##############################################################################