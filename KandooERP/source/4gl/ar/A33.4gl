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
GLOBALS "../ar/A_AR_GLOBALS.4gl" 
GLOBALS "../ar/A3_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/A31_GLOBALS.4gl" 
GLOBALS "../ar/A33_GLOBALS.4gl" 

###########################################################################
# FUNCTION A33_main()
#
# \brief module A33 - Sundry receipt Entry
###########################################################################
FUNCTION A33_main() 

	DEFER quit 
	DEFER interrupt 

	CALL setModuleId("A33") 

	CALL create_table("invoicedetl","t_invoicedetl","","Y") 

	OPEN WINDOW A639 with FORM "A639" #receipt entry WINDOW 
	CALL windecoration_a("A639") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	WHILE A33_enter_receipt() 

		OPEN WINDOW A640 with FORM "A640" 
		CALL windecoration_a("A640") 

		IF dist_receipt() THEN 

			MENU " Sundry Receipt" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","A33","menu-sundry-receipt") 

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				COMMAND "SAVE" " Save receipt TO database" 
					MESSAGE kandoomsg2("U",1005,"") 				#1005 Updating database pls wait
					LET glob_tran_num = write_receipt() 
					CASE 
						WHEN glob_tran_num = 0 
							## error occurred
						
						WHEN glob_rec_cashreceipt.cash_amt < 0 
							ERROR kandoomsg2("A",7065,glob_rec_cashreceipt.cash_num) 
						
						WHEN glob_rec_cashreceipt.cash_amt > 0 
							IF receipt_apply(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,glob_rec_cashreceipt.cash_num, glob_tran_num, glob_rec_cashreceipt.cash_amt,0) THEN 
								ERROR kandoomsg2("A",7065,glob_rec_cashreceipt.cash_num) 
							ELSE 
								ERROR kandoomsg2("A",7066,glob_rec_cashreceipt.cash_num) 			#7066 WARNING: Sundry receipt added successfully.
								#     Application TO invoice unsuccessfull.
								#Apply manually;  Refer menu A39.
							END IF 
					END CASE 
					EXIT MENU 

				COMMAND KEY(interrupt,"E")"Exit" " Discard changes" 
					LET int_flag = false 
					LET quit_flag = false 
					EXIT MENU 

			END MENU 

			INITIALIZE glob_rec_cashreceipt.* TO NULL
			
			#------------------------------------
			#DELETE Temp table  
			DELETE FROM t_invoicedetl WHERE 1=1 
		END IF 

		CLOSE WINDOW A640 

	END WHILE 

	CLOSE WINDOW A639 
	
END FUNCTION 
###########################################################################
# END FUNCTION A33_main()
###########################################################################