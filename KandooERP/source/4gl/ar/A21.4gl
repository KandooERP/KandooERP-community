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
# 1. Default Invoice TAX Code Default is set to customers default tax code, but can be overwritten
# 2. Quantity can be empty; This an be used for comment lines
# 3. Customer "on hold" or "over the credit limit" can not be used
# 4. Tax Code is checked if it uses tax calculation method "X" - 
#    PLUS tax exemption dialog (code & date) will be prompted if it's not available (or current) in the customer properties 
# 5. Ensure, GL Accounts for sales/purchase tax are setup correctly in the tax code setup AZ1
# 6.  
###########################################################################
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl"
GLOBALS "../ar/A2_GROUP_GLOBALS.4gl"  
GLOBALS "../ar/A21_GLOBALS.4gl" 
############################################################################
# FUNCTION A21_main()
#
# allows the user TO enter Accounts Receivable Invoices updating inventory
# Note: Tax Codes are retrieved from Customer
############################################################################
FUNCTION A21_main() 
--	DEFINE l_run_arg1 STRING 
--	DEFINE l_run_arg2 STRING 
--	DEFINE l_msg STRING 

	DEFER QUIT 
	DEFER INTERRUPT 

	CALL setModuleId("A21") 

	
	CALL create_table("invoicedetl","t_invoicedetl","","N") 
--	CALL initialize_invoice("") 

	CALL process_invoice(NULL) #create new invoice - next step is to determine what method is used wizzard or classic

END FUNCTION 
############################################################################
# END FUNCTION A21_main()
############################################################################
{
############################################################
# FUNCTION new_invoice_classic(p_inv_num) 
#
#
############################################################
FUNCTION new_invoice_classic() 
	DEFINE l_new_req SMALLINT 
	DEFINE l_scrn_opt LIKE language.yes_flag

		#----------------------------------------
		# OPEN shipping window
		OPEN WINDOW A137a with FORM "A137a" 
		CALL windecoration_a("A137a") 

		WHILE invoice_head_info_entry(MODE_CLASSIC_ADD) 
			CALL invoice_line_process(MODE_CLASSIC_ADD) 
			IF glob_rec_invoicehead.inv_num IS NOT NULL THEN 
				EXIT WHILE 
			END IF 
		END WHILE 
		
		CLOSE WINDOW A137a

	 
END FUNCTION
}
############################################################
# END FUNCTION new_invoice_classic(p_inv_num) 
############################################################

{
############################################################
# FUNCTION new_invoice_wizzard(p_inv_num) 
#
#
############################################################
FUNCTION new_invoice_wizzard(p_mode) 
	DEFINE p_mode SMALLINT
	DEFINE l_new_req SMALLINT #??? what is this used for  ???
	DEFINE l_scrn_opt LIKE language.yes_flag
	DEFINE l_step  SMALLINT	
	DEFINE l_ret SMALLINT #0 = back, 1 = forward, 2 = cancel
	DEFINE l_msg STRING
	DEFINE l_run_arg1 STRING
	DEFINE l_run_arg2 STRING

	--LET p_mode = 	MODE_CLASSIC_ADD
	LET l_new_req = FALSE	
--------------------------------------------

	LET l_step=0		
	#------------------------
	WHILE l_step >= 0 

		#CONSTANT NAV_BACKWARD SMALLINT = 0
		#CONSTANT NAV_FORWARD SMALLINT = 1
		#CONSTANT NAV_CANCEL SMALLINT = -1
		CASE l_step
			WHEN -1 #CANCEL/EXIT
				EXIT WHILE
				
			WHEN 0 #Enter Customer #User pressed previous screen on address input
				LET l_ret = enter_new_invoice_cust_code(p_mode)

				CASE l_ret
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
				OPEN WINDOW A138 with FORM "A138" # OPEN shipping window 
				CALL windecoration_a("A138") 
				CALL comboList_customership_DOUBLE("ship_code",glob_rec_invoicehead.cust_code,COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT)
				 
				LET l_ret = enter_invoice_shipping_addr(p_mode)
				CLOSE WINDOW A138 #close shipping window 
				 
				CASE l_ret
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
				LET l_ret = A21_enter_invoice_header(p_mode)

				CASE l_ret
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
				LET l_ret = invoice_line_process(p_mode)

				CASE l_ret
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


				IF glob_rec_invoicehead.inv_num IS NOT NULL THEN 
--						EXIT WHILE 
				END IF 

			WHEN 4 #Invoice Summary
				LET l_ret = invoice_summary_wrapper_sum_print(l_mode)
				CASE l_ret
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

			WHEN 5 #Invoice SAVED DONE

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
				 


			OTHERWISE
				CALL fgl_winmessage("Internal 4gl error","Internal Error - contact support!\nError Code: #83782138","ERROR")
		END CASE
		
	END WHILE

	CLOSE WINDOW A137 

END FUNCTION
############################################################
# END FUNCTION new_invoice_wizzard(p_inv_num) 
############################################################
}