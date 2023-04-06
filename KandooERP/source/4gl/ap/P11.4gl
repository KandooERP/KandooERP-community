#Create new Vendor
{
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

	Source code beautified by beautify.pl on 2020-01-03 13:41:16	$Id: $
}
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" --all 
GLOBALS "../ap/P_AP_GLOBALS.4gl" ----accounts payable 
GLOBALS "../ap/P_AP_P1_GLOBALS.4gl" --ap vendor 
#GLOBALS "P11_GLOBALS.4gl"  --program only
############################################################
# Module Scope Variables
############################################################

############################################################
# MAIN
#
# Purpose - Allows the user TO enter new vendors
############################################################
MAIN 
	DEFINE l_process_status BOOLEAN
	CALL setModuleId("P11") 
	CALL ui_init(0) #initial ui init 


	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_p_ap() #init p/ap module 

	OPEN WINDOW p176 with FORM "P176" 
	CALL windecoration_p("P176") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
	LET l_process_status = TRUE
	WHILE l_process_status
		CALL process_vendor("P11","ADD","") RETURNING l_process_status
	END WHILE 


	CLOSE WINDOW p176 

END MAIN 
