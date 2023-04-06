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
GLOBALS "../ar/A27_GLOBALS.4gl" 


############################################################
# FUNCTION process_invoice(p_inv_num) 
#
# NOTE: p_inv_num IS NULL = new invoice, otherwise, edit/modify existing invoice
# kandooption AR/IS decides, what format for the INVOICE INPUT is used (different forms)
############################################################
FUNCTION process_invoice(p_inv_num) 
	DEFINE p_inv_num LIKE invoicehead.inv_num 
	DEFINE l_edit_req SMALLINT 
	DEFINE l_scrn_opt LIKE language.yes_flag 

	CALL initialize_invoice(p_inv_num) 

	#-----------------------------------------------
	## get SCREEN DISPLAY option "Y" FOR less INPUT screens
	LET l_scrn_opt = get_kandoooption_feature_state("AR","IS")
 
	IF l_scrn_opt = "Y" THEN  #Compact Invoice tool 
		CALL process_invoice_classic(p_inv_num)
	ELSE #Wizzard style Invoice tool
		CALL process_invoice_wizzard(p_inv_num) 
	END IF 
	
END FUNCTION
############################################################
# END FUNCTION process_invoice(p_inv_num) 
############################################################


############################################################
# FUNCTION process_invoice_wizzard(p_inv_num) 
#
#
############################################################
FUNCTION process_invoice_wizzard(p_inv_num) 
	DEFINE p_inv_num LIKE invoicehead.inv_num 
	DEFINE l_edit_req SMALLINT #??? what is this used for  ???
	DEFINE l_scrn_opt LIKE language.yes_flag
	DEFINE l_step  SMALLINT	
	DEFINE l_mode STRING
	DEFINE l_msg STRING
	DEFINE l_run_arg1 STRING
	DEFINE l_run_arg2 STRING
	DEFINE l_ret_nav SMALLINT 	#Wizard Style Navigation NAV_BACKWARD=0 NAV_FORWARD SMALLINT=1 NAV_CANCEL SMALLINT=-1 NAV_DONE SMALLINT = 2	
	
	#0/NULL argument instructs to create NEW invoice , otherwise, we know what invoice to modify
	IF p_inv_num = 0 OR p_inv_num IS NULL THEN
		LET l_mode = MODE_CLASSIC_ADD #New invoice
	ELSE
		LET l_mode = MODE_CLASSIC_EDIT #edit existing invoice
	END IF
	LET l_ret_nav = NAV_FORWARD
	LET l_edit_req = TRUE #????
--	IF enter_new_invoice_cust_code(l_mode) THEN

	LET l_step=0		
	#------------------------
	WHILE l_step >= 0 
	
		#CONSTANT NAV_BACKWARD SMALLINT = 0
		#CONSTANT NAV_FORWARD SMALLINT = 1
		#CONSTANT NAV_CANCEL SMALLINT = -1
		CASE l_step
			WHEN -1 #CANCEL/EXIT
				LET l_msg = "Step (", trim(l_step) , "/4)\nl_ret_nav = ", trim(l_ret_nav)
				--CALL fgl_winmessage(l_step,l_msg,"INFO")
				EXIT WHILE
				
			WHEN 0 #Enter Customer #User pressed previous screen on address input
--				IF l_mode = MODE_CLASSIC_ADD THEN
--					LET l_msg = "enter_new_invoice_cust_code()\nStep (", trim(l_step) , "/5)\nl_ret_nav = ", trim(l_ret_nav), " 0=B 1=F -1=C 2=D \nMode=", l_mode CLIPPED
--					CALL fgl_winmessage(l_step,l_msg,"INFO")
--
--					LET l_ret_nav = enter_new_invoice_cust_code(l_mode)  --??? this is twisted
--				ELSE
					LET l_msg = "display_custromer_credit_status()\nStep (", trim(l_step) , "/5)\nl_ret_nav = ", trim(l_ret_nav), " 0=B 1=F -1=C 2=D \nMode=", l_mode CLIPPED
					--CALL fgl_winmessage(l_step,l_msg,"INFO")

					LET l_ret_nav = display_custromer_credit_status(glob_rec_customer.cust_code,TRUE)					 
--				END IF

				CASE l_ret_nav
					WHEN NAV_BACKWARD
						LET l_step = l_step - 1
						EXIT WHILE #nav backward on first screen is also EXIT
					WHEN NAV_FORWARD
						LET l_step = l_step + 1
					WHEN NAV_CANCEL
						LET l_step = -1
						EXIT WHILE
					OTHERWISE
						CALL fgl_winmessage("Internal 4gl error","Internal Error - contact support!\nError Code: #837821371","ERROR")							
				END CASE
			
			WHEN 1 #enter shipping address
				LET l_msg = "enter_invoice_shipping_addr()\nStep (", trim(l_step) , "/5)\nl_ret_nav = ", trim(l_ret_nav), " 0=B 1=F -1=C 2=D \nMode=", l_mode CLIPPED 
				--CALL fgl_winmessage(l_step,l_msg,"INFO")

				OPEN WINDOW A138 with FORM "A138" # OPEN shipping window 
				CALL windecoration_a("A138") 
				CALL comboList_customership_DOUBLE("ship_code",glob_rec_invoicehead.cust_code,COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT)
				 
				LET l_ret_nav = enter_invoice_shipping_addr(l_mode)
				CLOSE WINDOW A138 #close shipping window 
				 
				CASE l_ret_nav
					WHEN NAV_BACKWARD
						LET l_step = l_step - 1
					WHEN NAV_FORWARD
						LET l_step = l_step + 1
					WHEN NAV_CANCEL
						LET l_step = -1
						EXIT WHILE
					OTHERWISE
						CALL fgl_winmessage("Internal 4gl error","Internal Error - contact support!\nError Code: #837821372","ERROR")							
				END CASE
			
			WHEN 2 #Enter Invoice Header
				LET l_msg = "A21_enter_invoice_header()\nStep (", trim(l_step) , "/5)\nl_ret_nav = ", trim(l_ret_nav), " 0=B 1=F -1=C 2=D \nMode=", l_mode CLIPPED 
				--CALL fgl_winmessage(l_step,l_msg,"INFO")

				LET l_ret_nav = A21_enter_invoice_header(l_mode)

				CASE l_ret_nav
					WHEN NAV_BACKWARD
						LET l_step = l_step - 1
					WHEN NAV_FORWARD
						LET l_step = l_step + 1
					WHEN NAV_CANCEL
						LET l_step = -1
						EXIT WHILE
					OTHERWISE
						CALL fgl_winmessage("Internal 4gl error","Internal Error - contact support!\nError Code: #837821373","ERROR")							
				END CASE

			WHEN 3 #Invoice line process
				LET l_msg = "invoice_line_process()\nStep (", trim(l_step) , "/5)\nl_ret_nav = ", trim(l_ret_nav), " 0=B 1=F -1=C 2=D \nMode=", l_mode CLIPPED 
				--CALL fgl_winmessage(l_step,l_msg,"INFO")

				LET l_ret_nav = invoice_line_process(l_mode)

				CASE l_ret_nav
					WHEN NAV_BACKWARD
						LET l_step = l_step - 1
					WHEN NAV_FORWARD
						LET l_step = l_step + 1
					WHEN NAV_CANCEL
						LET l_step = -1
						EXIT WHILE
					WHEN NAV_DONE
						EXIT WHILE
					OTHERWISE
						CALL fgl_winmessage("Internal 4gl error","Internal Error - contact support!\nError Code: #837821374","ERROR")							
				END CASE

			WHEN 4 #Invoice Summary
				LET l_msg = "invoice_summary()\nStep (", trim(l_step) , "/5)\nl_ret_nav = ", trim(l_ret_nav)
				--CALL fgl_winmessage(l_step,l_msg,"INFO")

				# OPEN summmary window
				OPEN WINDOW A642 with FORM "A642" 
				CALL windecoration_a("A642") 
		
				LET l_ret_nav = invoice_summary(l_mode) #LET l_ret_nav = invoice_summary_wrapper_sum_print(l_mode)
				CASE l_ret_nav
					WHEN NAV_BACKWARD
						CLOSE WINDOW A642
						LET l_step = l_step - 1
					WHEN NAV_FORWARD
						LET l_step = l_step + 1
					WHEN NAV_CANCEL
						LET l_step = -1
						EXIT WHILE
					WHEN NAV_DONE
						EXIT WHILE
					OTHERWISE
						CALL fgl_winmessage("Internal 4gl error","Internal Error - contact support!\nError Code: #837821374","ERROR")							
				END CASE
				
			WHEN 5 #Invoice SAVED DONE - Print ?
				LET l_msg = " A21_invoice_result_menu()\nStep (", trim(l_step) , "/5)\nl_ret_nav = ", trim(l_ret_nav)
				--CALL fgl_winmessage(l_step,l_msg,"INFO")



{				IF glob_rec_invoicehead.inv_num > 0 THEN 
					MESSAGE kandoomsg2("A",7071,glob_rec_invoicehead.inv_num) #A7071Invoice added successfully"
					LET l_msg = "Do you want to print Invoice ", trim(glob_rec_invoicehead.inv_num), " now ?" 

					IF promptYN("Invoice created - View/Print ?",l_msg,"Y") = "y" THEN 
						#Note, introduced invoice_number to clarify the argument
						LET l_run_arg1 = "INVOICE_TEXT=", trim(glob_rec_invoicehead.inv_num)  
						LET l_run_arg2 = "INVOICE_NUMBER=", trim(glob_rec_invoicehead.inv_num)  
						CALL run_prog("AS1",l_run_arg1,l_run_arg2,"","") -- invoice PRINT 
						--CALL run_prog("URS",l_run_arg1,l_run_arg2,"","") -- ON ACTION "Print Manager" 
					END IF 

				END IF
}


				LET l_ret_nav = A21_invoice_result_menu(l_mode)
				CASE l_ret_nav
					WHEN NAV_BACKWARD
						LET l_step = l_step - 1
					WHEN NAV_FORWARD
						CLOSE WINDOW A642
						LET l_step = l_step + 1
					WHEN NAV_CANCEL
						LET l_step = -1
						EXIT WHILE
					WHEN NAV_DONE
						EXIT WHILE
					OTHERWISE
						CALL fgl_winmessage("Internal 4gl error","Internal Error - contact support!\nError Code: #837821374","ERROR")							
				END CASE


		
			OTHERWISE
				CALL fgl_winmessage("Internal 4gl error","Internal Error - contact support!\nError Code: #83782138","ERROR")
		END CASE
		
	END WHILE

	LET l_msg = "END OF Steps (", trim(l_step) , "/4)\nl_ret_nav = ", trim(l_ret_nav)
	--CALL fgl_winmessage(l_step,l_msg,"INFO")
		
--		END IF
		#-----------------------------
{		 
			#----------------------------------------
			
			OPEN WINDOW A138 with FORM "A138" # OPEN shipping window
			CALL windecoration_a("A138") 
			CALL comboList_customership_DOUBLE("ship_code",glob_rec_invoicehead.cust_code,COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT)
			 
			WHILE enter_invoice_shipping_addr(l_mode) 
				OPEN WINDOW A139 with FORM "A139" 
				CALL windecoration_a("A139") 

				WHILE A21_enter_invoice_header(l_mode) 
					CALL invoice_line_process(l_mode) 
				END WHILE 

				#----------------------------------------
				#close header window
				CLOSE WINDOW A139 

				IF NOT l_edit_req THEN 
					EXIT WHILE 
				END IF 
			END WHILE
			
			CLOSE WINDOW A138 #close shipping window 
		END IF

		CLOSE WINDOW A137 #Invoice Header Window
	}	
END FUNCTION
############################################################
# END FUNCTION process_invoice_wizzard(p_inv_num) 
############################################################



############################################################
# FUNCTION process_invoice_classic(p_inv_num) 
#
#
############################################################
FUNCTION process_invoice_classic(p_inv_num) 
	DEFINE p_inv_num LIKE invoicehead.inv_num 
	DEFINE l_edit_req SMALLINT 
	DEFINE l_scrn_opt LIKE language.yes_flag

		#----------------------------------------
		# OPEN shipping window
		OPEN WINDOW A137a with FORM "A137a" 
		CALL windecoration_a("A137a") 

		WHILE invoice_head_info_entry(MODE_CLASSIC_EDIT) 
			CALL invoice_line_process(MODE_CLASSIC_EDIT) 
			IF glob_rec_invoicehead.inv_num IS NOT NULL THEN 
				EXIT WHILE 
			END IF 
		END WHILE 
		
		CLOSE WINDOW A137a

	 
END FUNCTION
############################################################
# END FUNCTION process_invoice_classic(p_inv_num) 
############################################################
