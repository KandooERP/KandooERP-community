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
GLOBALS "../ar/A2R_GLOBALS.4gl" 

############################################################
# MAIN
#
# \brief module A2R - Debtors Refund Entry
############################################################
MAIN 
	DEFINE l_tran_num INTEGER 

	DEFER quit 
	DEFER interrupt 

	CALL setModuleId("A2R") 
	CALL ui_init(0) 	#Initial UI Init 

	CALL authenticate(getmoduleid()) 
	CALL init_a_ar() #init a/ar module 

	OPEN WINDOW A221 with FORM "A221" 
	CALL windecoration_a("A221") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	WHILE enter_refund() 

		MENU " Refund Payment" 
			BEFORE MENU 
				CALL publish_toolbar("kandoo","A2R","menu-refund-payment") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			COMMAND "Save" " Save refund TO database" 
				MESSAGE kandoomsg2("A",1005,"")			#1005 Updating database pls wait
				LET l_tran_num = write_refund() 
				IF l_tran_num != 0 THEN 

					MENU " Refund Apply" 
						BEFORE MENU 
							CALL publish_toolbar("kandoo","A2R","menu-refund-apply") 

						ON ACTION "WEB-HELP" 
							CALL onlinehelp(getmoduleid(),null) 
						ON ACTION "actToolbarManager" 
							CALL setuptoolbar() 

						COMMAND "Receipts" " Apply Receipts" 
							CALL run_prog("A3A","","","","")
							 
						COMMAND "Credits" " Apply Credits" 
							CALL run_prog("A48","","","","")
							 
						COMMAND KEY(interrupt,"E")"Exit" 
							" Enter next refund transaction" 
							LET int_flag = false 
							LET quit_flag = false 
							EXIT MENU 

					END MENU 
 
				END IF 
				EXIT MENU
				 
			COMMAND KEY(interrupt,"E")"Exit" " Discard changes" 
				LET int_flag = false 
				LET quit_flag = false 
				EXIT MENU 

		END MENU 
	END WHILE 
	CLOSE WINDOW A221 
END MAIN 
############################################################
# END MAIN
############################################################