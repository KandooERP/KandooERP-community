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
GLOBALS "../ar/A2_GROUP_GLOBALS.4gl"  
GLOBALS "../ar/A21_GLOBALS.4gl" 
GLOBALS "../ar/A22_GLOBALS.4gl" 
############################################################
# FUNCTION A22_main()
# allows the user TO enter Accounts Receivable Invoices
# updating inventory
############################################################
FUNCTION A22_main() 

	DEFER quit 
	DEFER interrupt 
	
	CALL setModuleId("A22") 

	##SELECT opparms
	CALL create_table("invoicedetl","t_invoicedetl","","N") 

	WHILE TRUE
	CALL process_invoice(NULL) #create new invoice - next step is to determine what method is used wizzard or classic
{
	CALL initialize_invoice(NULL) 

	## get SCREEN DISPLAY option "Y" FOR less INPUT screens
	IF get_kandoooption_feature_state("AR","IS") = "Y" THEN 

		## OPEN initial window
		OPEN WINDOW A137a with FORM "A137a" 
		CALL windecoration_a("A137a") 
		CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

		WHILE invoice_head_info_entry(MODE_CLASSIC_ADD) 
			CALL invoice_line_process(MODE_CLASSIC_ADD) 
			IF glob_rec_invoicehead.inv_num IS NOT NULL THEN 
				EXIT WHILE 
			END IF 
		END WHILE 

		IF glob_rec_invoicehead.inv_num IS NOT NULL THEN 
			IF glob_rec_invoicehead.inv_num > 0 THEN 
				MESSAGE kandoomsg2("A",7071,glob_rec_invoicehead.inv_num)		#A7071Invoice added successfully"
				CALL enter_cashreceipt(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,glob_rec_invoicehead.inv_num,1) 
				RETURNING glob_temp_text 
			END IF 
			CALL initialize_invoice("") 
		END IF 
		CLOSE WINDOW A137a 
	ELSE 
	
		## OPEN initial window
		OPEN WINDOW A137 with FORM "A137" 
		CALL windecoration_a("A137") 

		WHILE enter_new_invoice_cust_code(MODE_CLASSIC_ADD)
		 
			## OPEN shipping window
			OPEN WINDOW A138 with FORM "A138" 
			CALL windecoration_a("A138") 
			CALL comboList_customership_DOUBLE("ship_code",glob_rec_invoicehead.cust_code,COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT)
			#																	#(cb_field_name,pCust_code,pVariable,pSort,pSingle,pHint)

			WHILE enter_invoice_shipping_addr(MODE_CLASSIC_ADD) 
				OPEN WINDOW A139 with FORM "A139" 
				CALL windecoration_a("A139") 
				WHILE A21_enter_invoice_header(MODE_CLASSIC_ADD) 
					CALL invoice_line_process(MODE_CLASSIC_ADD) 
					IF glob_rec_invoicehead.inv_num IS NOT NULL THEN 
						EXIT WHILE 
					END IF 
				END WHILE 

				##close header window
				CLOSE WINDOW A139 
				IF glob_rec_invoicehead.inv_num IS NOT NULL THEN 
					EXIT WHILE 
				END IF 
			END WHILE 

			##close shipping window
			CLOSE WINDOW A138 
}

		IF glob_rec_invoicehead.inv_num IS NOT NULL THEN 
			IF glob_rec_invoicehead.inv_num > 0 THEN 
				MESSAGE kandoomsg2("A",7071,glob_rec_invoicehead.inv_num)		#A7071Invoice added successfully"
				CALL enter_cashreceipt(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,glob_rec_invoicehead.inv_num,1) 
				RETURNING glob_temp_text 
			END IF 
			CALL initialize_invoice("") 
		END IF 

	END WHILE 
	CLOSE WINDOW A137 

END FUNCTION
############################################################
# END FUNCTION A22_main()
############################################################