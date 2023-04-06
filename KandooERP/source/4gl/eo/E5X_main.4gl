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
GLOBALS "../eo/E5X_GLOBALS.4gl" 
###########################################################################
# \brief module E5X - Performs the automatical delivery cycle.
#                This cycle consiste of five steps:
#                Step 1: Generating of picking lists
#                Step 2: Confirming orders/generating invoices/credit notes
#                Step 3: Printing invoices
#                Step 4: Generating/printing consignment notes
#                Step 5: Printing shipping labels
###########################################################################
# MAIN
#
# Scheduler TO control the proceeding of the automated delivery cycle
###########################################################################
MAIN 
	DEFER QUIT 
	DEFER INTERRUPT 
	
	CALL setModuleId("E5X") 
	CALL ui_init(0) #Initial UI Init 

	CALL authenticate(getmoduleid()) 
	CALL init_e_eo() #init e/eo module/program 
	CALL init_E5_GROUP()
	
	CALL E5X_main()
END MAIN
###########################################################################
# END MAIN
###########################################################################