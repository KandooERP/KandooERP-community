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
# \brief module P62 allows the user TO enter Payables debits , distribute the
# debits TO G/L accounts

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/P6_GROUP_GLOBALS.4gl"
GLOBALS "../ap/P62_GLOBALS.4gl"
###########################################################################
# MODULE Scope Variables
###########################################################################

############################################################
# MAIN
############################################################
MAIN 
	DEFINE l_rec_debithead RECORD LIKE debithead.*
	DEFINE l_msgresp LIKE language.yes_flag 

	#Initial UI Init
	CALL setModuleId("P62") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_p_ap() #init p/ap module 

	OPEN WINDOW p117 with FORM "P117" 
	CALL windecoration_p("P117") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	#now done it CALL init_p_ap() #init P/AP module
	#SELECT * INTO pr_apparms.* FROM apparms
	# WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
	#   AND parm_code = "1"
	#IF STATUS = NOTFOUND THEN
	#   LET l_msgresp=kandoomsg("P",5016,"")
	#   EXIT PROGRAM
	#END IF
	CALL create_table("debitdist","t_debitdist","","Y") 
	WHILE true 
		CLEAR FORM 
		CALL enter_debit(glob_rec_kandoouser.cmpy_code, glob_rec_kandoouser.sign_on_code,"","") 
		RETURNING l_rec_debithead.* 
		IF l_rec_debithead.vend_code IS NULL THEN 
			EXIT WHILE 
		ELSE 


			MENU " Debits" 

				BEFORE MENU 
					CALL publish_toolbar("kandoo","P62","menu-debits-1") 

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				COMMAND "Save" " Save new debit TO database" 
					LET l_rec_debithead.debit_num = 
					update_debit(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,"1",l_rec_debithead.*) 
					IF l_rec_debithead.debit_num = 0 THEN 
						LET l_msgresp=kandoomsg("P",7022,"") 
						#7022 Errors occurred during debit add"
					ELSE 
						LET l_msgresp=kandoomsg("P",7021,l_rec_debithead.debit_num) 
						#7021 Debit successfully created"
					END IF 
					EXIT MENU 
				COMMAND "Distribution" " Enter account distribution FOR this debit" 
					OPEN WINDOW wp170 at 2,3 with FORM "P170" 
					CALL windecoration_p("P170") 

					IF NOT dist_debit(glob_rec_kandoouser.cmpy_code, glob_rec_kandoouser.sign_on_code, l_rec_debithead.*) THEN 
						DELETE FROM t_debitdist 
					END IF 
					CLOSE WINDOW wp170 
				COMMAND KEY(interrupt,"E")"Exit" " Enter another Debit" 
					LET int_flag = false 
					LET quit_flag = false 
					EXIT MENU 

			END MENU 

			DELETE FROM t_debitdist 
		END IF 
	END WHILE 
	CLOSE WINDOW p117 
END MAIN 


