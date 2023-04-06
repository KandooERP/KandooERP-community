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
# \brief module P96  Tax Payment Summary & Reconciliation Reports
#
#This file IS used as GLOBALS file FROM P96b.4gl
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/P9_GROUP_GLOBALS.4gl" 
GLOBALS "../ap/P96_GLOBALS.4gl"
###########################################################################
# MODULE Scope Variables
###########################################################################


############################################################
# MAIN
#
#
############################################################
MAIN 

	DEFER quit 
	DEFER interrupt 

	CALL setModuleId("P96") 
	CALL ui_init(0) 	#Initial UI Init 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_p_ap() #init p/ap module 

	CALL P96_main()
END MAIN 
############################################################
# END MAIN
############################################################