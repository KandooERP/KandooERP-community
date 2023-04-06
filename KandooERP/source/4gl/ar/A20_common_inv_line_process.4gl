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
# 
############################################################
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl" 
GLOBALS "../ar/A2_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/A20_GLOBALS.4gl"

########################################################################
# FUNCTION invoice_line_process(p_mode)
# new FUNCTION ??? MaxGuys ??? new and not completed.. great ! 
# TO seperate the line INPUT process, use FOR program A21, A22
# AND A27
########################################################################
FUNCTION invoice_line_process(p_mode) 
	DEFINE p_mode STRING 
	DEFINE l_msg STRING
	DEFINE l_ret_nav SMALLINT 	#Wizard Style Navigation NAV_BACKWARD=0 NAV_FORWARD SMALLINT=1 NAV_CANCEL SMALLINT=-1 NAV_DONE SMALLINT = 2	
	DEFINE l_run_arg1 STRING	#Used for RUN statements
	DEFINE l_run_arg2 STRING	#Used for RUN statements
	
	IF get_debug() THEN
		DISPLAY "###############################################"	
		LET l_msg = "BEGIN - invoice_line_process(p_mode=", trim(p_mode), ")" 					
		DISPLAY l_msg 
		DISPLAY "###############################################"
	END IF
	
	OPEN WINDOW A144 with FORM "A144" 
	CALL windecoration_a("A144") 
	
	IF glob_rec_warehouse.ware_code IS NOT NULL THEN #Invoice works with warehouse parts by default 
		DISPLAY glob_rec_warehouse.ware_code TO warehouse.ware_code
		DISPLAY db_warehouse_get_desc_text(UI_OFF,glob_rec_warehouse.ware_code) TO warehouse.desc_text
	ELSE
		DISPLAY NULL TO warehouse.ware_code
		DISPLAY NULL TO warehouse.desc_text 
	END IF	
	
	#------------------------------------------------------------------------
	#WHILE
	LET l_ret_nav = invoice_line_input_array() ## Uses invoice_line_input_array window A144 with invoice lines 
		#-----------------------------------
{
		# OPEN summmary window
		OPEN WINDOW A642 with FORM "A642" 
		CALL windecoration_a("A642") 
}
		#------------------------------------------------------------------------
		--LET l_ret_nav = invoice_summary(p_mode) #WHILE invoice_summary(p_mode) 
	--	LET l_ret_nav = A21_invoice_result_menu(p_mode)
{
			MENU "Invoice" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","A21a","menu-invoice") 
					#User can only print invoice or book receipt against invoice AFTER it's saved
--					CALL dialog.setActionHidden("SAVE", ,FALSE)
--					#CALL dialog.setActionHidden("SAVE2",FALSE)
--					CALL dialog.setActionHidden("PRINT",TRUE)
--					CALL dialog.setActionHidden("RECEIPT",TRUE)

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
					
				ON ACTION ("SAVE","SAVE2") #COMMAND "Save" " Commit invoice details TO database"
					LET glob_rec_invoicehead.inv_num = write_invoice(p_mode)

					IF glob_rec_invoicehead.inv_num IS NOT NULL THEN
						LET l_msg = "Invoice ", trim(glob_rec_invoicehead.inv_num), " for ", trim(glob_rec_invoicehead.currency_code), " ", trim(glob_rec_invoicehead.total_amt)
						
						IF p_mode = MODE_CLASSIC_EDIT  THEN #edit uses different message text
							LET l_msg = l_msg CLIPPED, " updated successfully!"
						ELSE  
							LET l_msg = l_msg CLIPPED, " created successfully!"
						END IF 

						CALL fgl_winmessage("Invoice Saved",l_msg,"info")

--						CALL dialog.setActionHidden("SAVE",TRUE)
--						CALL dialog.setActionHidden("SAVE2",TRUE)
--						CALL dialog.setActionHidden("PRINT",FALSE)
--						CALL dialog.setActionHidden("RECEIPT",FALSE)
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

			ON ACTION "RECEIPT"
				IF glob_rec_invoicehead.inv_num IS NOT NULL THEN 
					IF glob_rec_invoicehead.inv_num > 0 THEN 
						MESSAGE kandoomsg2("A",7071,glob_rec_invoicehead.inv_num)		#A7071Invoice added successfully"
						CALL enter_cashreceipt(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,glob_rec_invoicehead.inv_num,1) 
						RETURNING glob_temp_text 
					END IF 
					CALL initialize_invoice("") 
				END IF 
			
				
--					EXIT MENU 

					
				ON ACTION "Discard" #COMMAND "Discard" " Discard invoice details TO database"
					LET glob_rec_invoicehead.inv_num = 0
					LET l_ret_nav = NAV_CANCEL 
					EXIT MENU 

				ON ACTION ("NAV_BACKWARD") -- " RETURN TO invoice entry" #COMMAND KEY(interrupt,"E")"Exit" " RETURN TO invoice entry"
					LET l_ret_nav = NAV_BACKWARD 
					EXIT MENU 


				ON ACTION ("CANCEL") -- " RETURN TO invoice entry" #COMMAND KEY(interrupt,"E")"Exit" " RETURN TO invoice entry"
					LET glob_rec_invoicehead.inv_num = 0 
					LET quit_flag = true
					LET int_flag = TRUE
					LET l_ret_nav = NAV_CANCEL 
					EXIT MENU 


			END MENU 

			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false
				LET l_ret_nav = NAV_CANCEL 
			END IF 

--		END WHILE #WHILE invoice_summary(p_mode) 		
		#------------------------------------------------------------------------

		##close summary window
		CLOSE WINDOW A642 

		IF (glob_rec_invoicehead.inv_num != 0) 
		OR (glob_rec_invoicehead.inv_num IS NOT NULL)
		OR p_mode = MODE_CLASSIC_EDIT  THEN 
			#EXIT WHILE 
		END IF 
	#END WHILE #WHILE invoice_line_input_array() ## Uses invoice_line_input_array window A144 with invoice lines 
	#------------------------------------------------------------------------
}

	##close invoice_line_input_array window
	CLOSE WINDOW A144

	IF int_flag THEN 
		LET int_flag = FALSE
		LET l_ret_nav = NAV_CANCEL
	ELSE
		RETURN l_ret_nav #2
	END IF
END FUNCTION 
########################################################################
# END FUNCTION invoice_line_process(p_mode)
########################################################################
