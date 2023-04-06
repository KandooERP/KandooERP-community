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
GLOBALS "../ar/A20_GLOBALS.4gl" 
############################################################################
# FUNCTION A20_main()
#
# allows the user TO enter Accounts Receivable Invoices updating inventory
# Note: Tax Codes are retrieved from Customer
############################################################################
FUNCTION A20_main() 
	DEFINE l_msg STRING
	DEFINE l_run_arg1 STRING	#Used for RUN statements
	DEFINE l_run_arg2 STRING	#Used for RUN statements

	DEFER QUIT 
	DEFER INTERRUPT 

	CALL setModuleId("A20") 

	CALL create_table("invoicedetl","t_invoicedetl","","N") 
--	CALL initialize_invoice("") 

	MENU
		BEFORE MENU
			CALL dialog.setActionHidden("ACCEPT",TRUE)

		ON ACTION "NEW INVOICE"
			CALL process_invoice(NULL) #create new invoice - next step is to determine what method is used wizzard or classic
		
		ON ACTION "EDIT INVOICE"
			OPEN WINDOW A135 WITH FORM "A135" 
			CALL windecoration_a("A135") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
		
			CALL scan_invoices_by_customer() 
		
			CLOSE WINDOW A135
		
		--ON ACTION "INVOICE RECEIPT"
		
		ON ACTION "PRINT"
			IF glob_rec_invoicehead.inv_num != 0 AND glob_rec_invoicehead.inv_num IS NOT NULL THEN
				LET l_msg = "Do you want TO View/Print invoice ", trim(glob_rec_invoicehead.inv_num), " now?"
	
				IF promptYN("Invoice created - View/Print ?",l_msg,"Y") = "y" THEN 
					#Note, introduced invoice_number to clarify the argument
					LET l_run_arg1 = "INVOICE_TEXT=", trim(glob_rec_invoicehead.inv_num) #why can we NOT use normal invoice_num here ? invoice_text was char(400) BEFORE i changed it STRING seems invoice_text IS the invoice number ???? 
					LET l_run_arg2 = "INVOICE_NUMBER=", trim(glob_rec_invoicehead.inv_num) #why can we NOT use normal invoice_num here ? invoice_text was char(400) BEFORE i changed it STRING seems invoice_text IS the invoice number ???? 
					CALL run_prog("AS1",l_run_arg1,l_run_arg2,"","") -- invoice PRINT
				END IF
			ELSE
				CALL run_prog("AS1",NULL,NULL,NULL,NULL) -- invoice PRINT
			END IF

		ON ACTION "PRINT MANAGER" 
			CALL run_prog("URS",l_run_arg1,l_run_arg2,"","") -- ON ACTION "Print Manager" 

			 
		ON ACTION "EXIT"
			EXIT MENU
			
	END MENU

	

END FUNCTION 
############################################################################
# END FUNCTION A21_main()
############################################################################