
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
GLOBALS "../common/glob_GLOBALS_report.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl"
GLOBALS "../ar/AA_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/AAG_GLOBALS.4gl"
#####################################################################
# MAIN
#
# AAG - Summary Aging Report by currency
#####################################################################
MAIN 
	DEFER quit 
	DEFER interrupt 
		
	CALL setModuleId("AAG") 
	CALL ui_init(0) #Initial UI Init
	CALL authenticate(getmoduleid()) 
	CALL init_a_ar() #init a/ar module 

	CALL AAG_main()
	
END MAIN