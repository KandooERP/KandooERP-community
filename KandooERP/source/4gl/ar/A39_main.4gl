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
GLOBALS "../ar/A_AR_GLOBALS.4gl" 
GLOBALS "../ar/A3_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/A39_GLOBALS.4gl" 

################################################################
# MAIN
#
# \brief module A39 - Cash Receipt Unapply
# \brief module provides a scan SCREEN of applied receipts
#                    allowing user TO SELECT a receipts FOR unapplying
################################################################
MAIN 

	DEFER quit 
	DEFER interrupt 

	CALL setModuleId("A39") 
	CALL ui_init(0) 	#Initial UI Init 

	CALL authenticate(getmoduleid()) 
	CALL init_a_ar() #init a/ar module 

	CALL A39_main()
	
END MAIN 
################################################################
# END MAIN
################################################################