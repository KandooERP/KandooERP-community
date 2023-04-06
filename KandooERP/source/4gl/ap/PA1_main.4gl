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
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/PA0_GLOBALS.4gl"
############################################################
# MAIN
#
# Vendor List Report
############################################################
MAIN 

	DEFER quit 
	DEFER interrupt 

	CALL setModuleId("PA1") 	#Initial UI Init
	CALL ui_init(0) 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_p_ap() #init p/ap module 
	
	OPEN WINDOW P105 with FORM "P105" 
	CALL windecoration_p("P105") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	MENU " Vendor Report" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","PA1","menu-vendor-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "Report"		#COMMAND "Report" " SELECT Criteria AND PRINT REPORT"
			CALL PA1_rpt_process(PA1_rpt_query()) 

		ON ACTION "Print Manager" #COMMAND KEY("P", f11) "Print" " Print OR View using RMS"
			CALL run_prog("URS", "", "", "", "") 

		ON ACTION "CANCEL" #COMMAND KEY(interrupt, "E") "Exit" " Exit TO menus"
			EXIT MENU 

	END MENU 

END MAIN 
############################################################
#END  MAIN
############################################################
