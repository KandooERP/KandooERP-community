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
# \file
# \brief module : A27
# Purpose : allows the user TO edit  Accounts Receivable Invoices
#           updating inventory
#
#
#   Some invoices can be edited AND some cannot.
#
#   InvInd  Source Allowed  Notes
#   ---------------------------------------------------------------------
#   1       AR A21  Yes     Normal AR invoice
#   2       OE O54  No      No longer used.
#   3       JM J31  No      Use Job Mgt Module
#   4       AR A2A  Yes     Debtor Adjustment
#   5       EO E53  Yes     Not recommended but no real reason why NOT.
#   6       EO E53  Yes     Not recommended but no real reason why NOT.
#   7       SS K11  No      Use Subscriptions module
#   8       AR A2R  No      Debtors Refund. Invoice must match voucher.
#   9       AR A21  Yes     AR Sundry Charge/Interest Charge
#   P       AP P29  No      AP Charge Thru Expense. Inv must equal voucher
#   X       AR ASL  Yes     Depends on invoice source. Needed TO fix probs.
#   S       WO W91  No      Check Building Products Module
#   L       WO W91  No      Check Building Products Module
#

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl"
GLOBALS "../ar/A2_GROUP_GLOBALS.4gl"  
GLOBALS "../ar/A20_GLOBALS.4gl" 
GLOBALS "../ar/A21_GLOBALS.4gl" 


########################################################################
# FUNCTION A21_invoice_result_menu(p_mode)
# new FUNCTION ??? MaxGuys ??? new and not completed.. great ! 
# TO seperate the line INPUT process, use FOR program A21, A22
# AND A27
########################################################################
FUNCTION A21_invoice_result_menu(p_mode) 
	DEFINE p_mode STRING 
	DEFINE l_msg STRING
	DEFINE l_ret SMALLINT 	#Wizard Style Navigation NAV_BACKWARD=0 NAV_FORWARD SMALLINT=1 NAV_CANCEL SMALLINT=-1 NAV_DONE SMALLINT = 2	
	DEFINE l_run_arg1 STRING	#Used for RUN statements
	DEFINE l_run_arg2 STRING	#Used for RUN statements
	
	IF get_debug() THEN
		DISPLAY "###############################################"	
		LET l_msg = "BEGIN - A21_invoice_result_menu(p_mode=", trim(p_mode), ")" 					
		DISPLAY l_msg 
		DISPLAY "###############################################"
	END IF

			MENU "Invoice" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","A21a","menu-invoice") 
					#User can only print invoice or book receipt against invoice AFTER it's saved
					CALL dialog.setActionHidden("SAVE",FALSE)
					CALL dialog.setActionHidden("NAV_BACKWARD",FALSE)
					CALL dialog.setActionHidden("ACCEPT",TRUE)
					CALL dialog.setActionHidden("DISCARD",FALSE)
					CALL dialog.setActionHidden("PRINT",TRUE)
					--CALL dialog.setActionHidden("RECEIPT",TRUE)					

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
					
				ON ACTION ("SAVE") #COMMAND "Save" " Commit invoice details TO database"
					LET glob_rec_invoicehead.inv_num = write_invoice(p_mode)

					IF glob_rec_invoicehead.inv_num IS NOT NULL THEN
						LET l_msg = "Invoice ", trim(glob_rec_invoicehead.inv_num), " for ", trim(glob_rec_invoicehead.currency_code), " ", trim(glob_rec_invoicehead.total_amt)
						
						IF p_mode = MODE_CLASSIC_EDIT  THEN #edit uses different message text
							LET l_msg = l_msg CLIPPED, " updated successfully!"
						ELSE  
							LET l_msg = l_msg CLIPPED, " created successfully!"
						END IF 

						CALL fgl_winmessage("Invoice Saved",l_msg,"info")

						CALL dialog.setActionHidden("SAVE",TRUE)
						CALL dialog.setActionHidden("NAV_BACKWARD",TRUE)
						CALL dialog.setActionHidden("DISCARD",TRUE)
						CALL dialog.setActionHidden("ACCEPT",FALSE)
						CALL dialog.setActionHidden("PRINT",FALSE)
						--CALL dialog.setActionHidden("RECEIPT",FALSE)
					ELSE
						CALL fgl_winmessage("Error","Could not save Invoice","ERROR")
					END IF
					

				ON ACTION "PRINT"
				IF glob_rec_invoicehead.inv_num > 0 THEN 
					MESSAGE kandoomsg2("A",7071,glob_rec_invoicehead.inv_num) #A7071Invoice added successfully"
					LET l_msg = "Invoice ", trim(glob_rec_invoicehead.inv_num), " created.\nDo you want TO View/Print this invoice now?" 

					IF promptYN("Invoice created - View/Print ?",l_msg,"Y") = "y" THEN 
						#Note, introduced invoice_number to clarify the argument
						LET l_run_arg1 = "INVOICE_TEXT=", trim(glob_rec_invoicehead.inv_num) #why can we NOT use normal invoice_num here ? invoice_text was char(400) BEFORE i changed it STRING seems invoice_text IS the invoice number ???? 
						LET l_run_arg2 = "INVOICE_NUMBER=", trim(glob_rec_invoicehead.inv_num) #why can we NOT use normal invoice_num here ? invoice_text was char(400) BEFORE i changed it STRING seems invoice_text IS the invoice number ???? 
						CALL run_prog("AS1",l_run_arg1,l_run_arg2,"","") -- invoice PRINT 
						--CALL run_prog("URS",l_run_arg1,l_run_arg2,"","") -- ON ACTION "Print Manager" 
					END IF 

				END IF
		
				
--					EXIT MENU 

					
				ON ACTION "DISCARD" #COMMAND "Discard" " Discard invoice details TO database"
					LET glob_rec_invoicehead.inv_num = 0
					LET l_ret = NAV_CANCEL 
					EXIT MENU 

				ON ACTION ("NAV_BACKWARD") -- " RETURN TO invoice entry" #COMMAND KEY(interrupt,"E")"Exit" " RETURN TO invoice entry"
					LET l_ret = NAV_BACKWARD 
					EXIT MENU 


				ON ACTION ("ACCEPT")
					LET glob_rec_invoicehead.inv_num = 0
					LET l_ret = NAV_DONE 
					EXIT MENU 


				ON ACTION ("CANCEL") -- " RETURN TO invoice entry" #COMMAND KEY(interrupt,"E")"Exit" " RETURN TO invoice entry"
					LET glob_rec_invoicehead.inv_num = 0 
					LET quit_flag = true
					LET int_flag = TRUE
					LET l_ret = NAV_CANCEL 
					EXIT MENU 


			END MENU 

			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false
				LET l_ret = NAV_CANCEL 
			END IF 


	IF int_flag THEN 
		LET int_flag = FALSE
		LET l_ret = NAV_CANCEL
	ELSE
		RETURN l_ret #2
	END IF
END FUNCTION 
########################################################################
# END FUNCTION A21_invoice_result_menu(p_mode)
########################################################################
