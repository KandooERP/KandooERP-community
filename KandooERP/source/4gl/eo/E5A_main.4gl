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
GLOBALS "../common/glob_GLOBALS_report.4gl" 
GLOBALS "../eo/E_EO_GLOBALS.4gl"
GLOBALS "../eo/E5_GROUP_GLOBALS.4gl"
GLOBALS "../eo/E5A_GLOBALS.4gl"

###########################################################################
# \brief module E5A - Monitors the proceeding of the delivery cycle in the
#               warehouses. Currently five OPTIONS are provided via a ring
#               menu.
#               Scroll: scrolls through generated delivery MESSAGEs with
#                       the option of RETURN on an error MESSAGE TO get a
#                       detailed explanation.
#               Run   : starts the delivery cycle(E5Aa) FOR every warehouse
#                       which has automated delivery cycle turned on.
#               Report: lets the user enter selection criteria TO PRINT a
#                       REPORT of the delivery(error) MESSAGEs
#               Delete: lets the user enter selection criteria TO delete
#                       delivery(error) MESSAGEs
#               Print : goes TO RMS
# inactive      Backgr: starts delivery cycle in background; interactive
# inactive              monitoring IS turned off
#               Exit  : stops program AND returns TO menu
###########################################################################
# MODULE Scope Variables
###########################################################################
DEFINE where_text char(200) 
###########################################################################
# MAIN
#
# E5A - Monitors the proceeding of the delivery cycle in the
#       warehouses. Currently five OPTIONS are provided via a ring menu.
###########################################################################
MAIN 
	DEFER QUIT 
	DEFER INTERRUPT 
	
	CALL setModuleId("E5A") 
	CALL ui_init(0) 	#Initial UI Init 

	CALL authenticate(getmoduleid()) 
	CALL init_e_eo() #init a/ar module/program 

	CALL authenticate(getmoduleid()) 

	CALL E5A_main()
END MAIN