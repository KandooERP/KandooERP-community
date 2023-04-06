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
GLOBALS "../common/glob_GLOBALS_userDataTypes.4gl"
GLOBALS "../ar/A_AR_GLOBALS.4gl" 
GLOBALS "../ar/A2_GROUP_GLOBALS.4gl"
GLOBALS "../ar/A20_GLOBALS.4gl"

############################################################################
# FUNCTION invoice_line_input_array()
#
# Manages/Adds the individual invoice detail rows
# DISPLAY Array works with l_arr_rec_invoicedetl_list
# AFTER Field writes value to l_rec_curr_row_invoicedetl
#
# db_st_invoicedetl_get_arr_rec_invoice_lines() returns ALL temp table DB invoice lines to display array 
# CALL db_st_invoicedetl_get_arr_rec_invoice_lines()RETURNING l_arr_rec_invoicedetl_list
############################################################################
FUNCTION invoice_line_input_array() 
	DEFINE l_rec_curr_row_invoicedetl RECORD LIKE invoicedetl.* #AFTER Field writes value to l_rec_curr_row_invoicedetl
	DEFINE l_rec_curr_row_invoicedetl_original RECORD LIKE invoicedetl.* 
	DEFINE l_arr_rec_invoicedetl_list DYNAMIC ARRAY OF dt_rec_invoicedetl_list
	DEFINE l_ret_next_field STRING #next field to go to for possible validation return
--	RECORD 
--	
--		scroll_flag CHAR(1), 
--		line_num LIKE invoicedetl.line_num, 
--		part_code LIKE invoicedetl.part_code, 
--		line_text LIKE invoicedetl.line_text, 
--		ship_qty LIKE invoicedetl.ship_qty, 
--		unit_sale_amt LIKE invoicedetl.unit_sale_amt, 
--		line_total_amt LIKE invoicedetl.line_total_amt 
--	END RECORD 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_idx SMALLINT --,scrn --,j
	DEFINE l_valid_ind SMALLINT --,scrn --,j
	--DEFINE i SMALLINT --,scrn --,j
	DEFINE l_errmsg CHAR(100) 
--	DEFINE l_lastkey INTEGER 
	DEFINE l_cnt INTEGER 
	DEFINE l_tab_cnt INTEGER 
	DEFINE l_part_code LIKE product.part_code
	DEFINE l_line_text LIKE invoicedetl.line_text 
	DEFINE l_query_text STRING 
	--DEFINE l_current_line_num LIKE invoicedetl.line_num
	DEFINE l_select_count SMALLINT
	DEFINE l_msg STRING
	DEFINE i SMALLINT
	DEFINE l_ui_cb ui.ComboBox 
	DEFINE l_navigation_forward BOOLEAN
	DEFINE l_mode_edit BOOLEAN
	DEFINE l_arr_rec_del_invoicedetl_list DYNAMIC ARRAY OF dt_rec_invoicedetl_list
	DEFINE l_del_idx SMALLINT
	DEFINE l_ret SMALLINT 	#Wizard Style Navigation NAV_BACKWARD=0 NAV_FORWARD SMALLINT=1 NAV_CANCEL SMALLINT=-1 NAV_DONE SMALLINT = 2

	LET l_ret = NAV_FORWARD
	#----------------
	# TabPage: Total
	
	# Invoice Tax Code
	DISPLAY glob_rec_invoicehead.tax_code TO invoicehead.tax_code
	DISPLAY db_tax_get_desc_text(UI_OFF,glob_rec_invoicehead.tax_code) TO invoicehead_tax_description

	--DISPLAY db_customer_get_tax_code(UI_OFF,glob_rec_invoicehead.tax_code) TO customer.tax_code


	--DISPLAY db_customer_get_tax_code(UI_OFF,glob_rec_invoicehead.cust_code) TO customer.tax_code
	DISPLAY glob_rec_invoicehead.currency_code TO customer.currency_code #HuHo: attribute(GREEN) #why with color / green ? I'll remove it

	#------------------
	# TabPage: Customer
	#Display invoiceheader ->Customer Record Details
	#Customer Code & Name		
	DISPLAY glob_rec_invoicehead.cust_code TO invoicehead.cust_code 
	DISPLAY glob_rec_customer.name_text TO customer.name_text
	
	#Customer Organisation
	DISPLAY glob_rec_customer.corp_cust_code TO customer.org_cust_code
	DISPLAY db_customer_get_name_text(UI_OFF,glob_rec_customer.corp_cust_code) TO org_name_text

	#Invoice Warehouse	
	DISPLAY glob_rec_warehouse.ware_code TO warehouse.ware_code
	DISPLAY db_warehouse_get_desc_text(UI_OFF,glob_rec_warehouse.ware_code) TO warehouse.desc_text

	#DISPLAY db_customer_get_ware_code(UI_OFF,glob_rec_invoicehead.cust_code) TO customer.ware_code
	#DISPLAY db_warehouse_get_desc_text(UI_OFF,glob_rec_invoicehead.ware_code) TO customer.desc_text

	# Customer Tax Code
	DISPLAY glob_rec_customer.tax_code TO customer.tax_code	
	DISPLAY db_tax_get_desc_text(UI_OFF,glob_rec_customer.tax_code) TO customer_tax_description


	#------------------
	# TabPage: GL Account	
	
	CALL l_arr_rec_invoicedetl_list.clear()
	CALL db_st_invoicedetl_get_arr_rec_invoice_lines()RETURNING l_arr_rec_invoicedetl_list
	
{
		DECLARE c1_invoicedetl CURSOR FOR 
		SELECT * FROM t_invoicedetl 
		ORDER BY line_num 

		LET l_idx = 0 
		FOREACH c1_invoicedetl INTO l_rec_curr_row_invoicedetl.* 
			LET l_idx = l_idx + 1 
			LET l_rec_curr_row_invoicedetl.ware_code = glob_rec_warehouse.ware_code 

			IF l_rec_curr_row_invoicedetl.line_num != l_idx THEN 
				UPDATE t_invoicedetl 
				SET line_num = l_idx 
				WHERE line_num = l_rec_curr_row_invoicedetl.line_num 
				LET l_rec_curr_row_invoicedetl.line_num = l_idx 
			END IF 

			LET l_arr_rec_invoicedetl_list[l_idx].line_num = l_rec_curr_row_invoicedetl.line_num 
			LET l_arr_rec_invoicedetl_list[l_idx].part_code = l_rec_curr_row_invoicedetl.part_code 
			LET l_arr_rec_invoicedetl_list[l_idx].line_text = l_rec_curr_row_invoicedetl.line_text 
			LET l_arr_rec_invoicedetl_list[l_idx].ship_qty = l_rec_curr_row_invoicedetl.ship_qty 
			LET l_arr_rec_invoicedetl_list[l_idx].unit_sale_amt = l_rec_curr_row_invoicedetl.unit_sale_amt 
			IF glob_rec_arparms.show_tax_flag = "Y" THEN 
				LET l_arr_rec_invoicedetl_list[l_idx].line_total_amt = l_rec_curr_row_invoicedetl.line_total_amt 
			ELSE 
				LET l_arr_rec_invoicedetl_list[l_idx].line_total_amt =l_rec_curr_row_invoicedetl.ext_sale_amt 
			END IF 
		END FOREACH 

		CALL set_count(l_idx)
} 
	--OPTIONS INSERT KEY f1 
	--DELETE KEY f36 

	#---------------------------------------------------------------------------------------------------------
	# INPUT ARRAY
	#---------------------------------------------------------------------------------------------------------
	MESSAGE kandoomsg2("A",1065,"") #A1065 "ESC TO complete invoice, F8 Detail Entry " 
	OPTIONS INPUT NO WRAP #We remove input wrap to have automated append row
	INPUT ARRAY l_arr_rec_invoicedetl_list WITHOUT DEFAULTS FROM sr_invoicedetl.* ATTRIBUTE(UNBUFFERED, INSERT ROW = FALSE, APPEND ROW=TRUE,DELETE ROW = FALSE, AUTO APPEND = FALSE) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","A21b","inp-arr-invoicedetl")
			CALL dialog.setActionHidden("ACCEPT",TRUE)
			#Update totals display
			CALL disp_total(l_rec_curr_row_invoicedetl.*) 
--		#Warehouse invoice uses part_code (FK), other use line_text	
--		IF glob_rec_warehouse.ware_code IS NULL THEN #Warehous disabled for this invoice
--			CALL set_fieldattribute_readonly("invoicedetl.part_code",TRUE)
--			CALL set_fieldattribute_readonly("invoicedetl.line_text",FALSE)				
--		ELSE
--			CALL set_fieldattribute_readonly("invoicedetl.part_code",FALSE)			
--			CALL set_fieldattribute_readonly("invoicedetl.line_text",TRUE)
--		END IF
			IF get_debug() THEN #nothing		
			END IF --		#We need to populate the comboBox for warehouse
--		WHENEVER ERROR CONTINUE 
--		LET l_ui_cb = ui.combobox.forname("invoicedetl.ware_code")
--		CALL l_ui_cb.clear()
--		IF glob_rec_warehouse.ware_code IS NOT NULL THEN #warehouse enabled
--			IF l_ui_cb IS NOT NULL THEN
--				CALL l_ui_cb.additem(NULL,"None") 
--				CALL l_ui_cb.additem(glob_rec_warehouse.ware_code,glob_rec_warehouse.ware_code)
--			ELSE
--				CALL l_ui_cb.additem(NULL,"None")				
--			END IF
--		END IF
--		WHENEVER ERROR STOP 
		
		
		#Depending on the tax_code and associated tax_calculation_method, we need to enable/disable fields
		#This is the global rule (will be overwritten by line rules
-- can not be done in BEFORE INPUT		CALL invoicedetl_enable_disable_fields(l_rec_curr_row_invoicedetl)
						
{				LET modu_last_row = DIALOG.getCurrentRow("sr_invoicedetl")
				DISPLAY "BI1 = ", modu_last_row 
				IF l_arr_rec_invoicedetl_list.getSize() > 0 THEN
					LET modu_last_row = 1
				ELSE
					LET modu_last_row = 0
				END IF 
				DISPLAY "BI2 = ", modu_last_row
				--CALL dialog.setActionHidden("CANCEL",TRUE)
}				
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "REFRESH"
			CALL fgl_dialog_setcurrline(1,1) 
			CALL db_st_invoicedetl_get_arr_rec_invoice_lines() RETURNING l_arr_rec_invoicedetl_list			
	
		ON ACTION "NAV_BACKWARD"
			LET l_ret = NAV_BACKWARD
			EXIT INPUT
			
		ON ACTION (ACCEPT,"NAV_FORWARD")
			LET l_ret = NAV_FORWARD
			ACCEPT INPUT
						
		ON ACTION "LOOKUP" infield(part_code)
			LET l_query_text= 
				"status_ind in ('1','4') ", 
				"AND part_code =", 
				"(SELECT part_code FROM prodstatus ", 
				"WHERE cmpy_code='",glob_rec_kandoouser.cmpy_code,"' ", 
				"AND part_code=product.part_code ", 
				"AND ware_code='",glob_rec_warehouse.ware_code,"' ", 
				"AND status_ind in('1','4'))" 
			LET glob_temp_text = choose_part_from_list(glob_rec_kandoouser.cmpy_code,l_query_text,l_arr_rec_invoicedetl_list[l_idx].part_code) 
			--OPTIONS INSERT KEY f1 
			--DELETE KEY f36 
			IF glob_temp_text IS NOT NULL THEN 
				LET l_arr_rec_invoicedetl_list[l_idx].part_code = glob_temp_text
				LET l_rec_curr_row_invoicedetl.part_code = l_arr_rec_invoicedetl_list[l_idx].part_code 
			END IF 

		#----------------------------------------------------------------------------------------------------------
		ON ACTION ("ADVANCED LOOKUP") infield(part_code)--ON KEY(F8) infield(part_code)
			LET glob_temp_text = "part_code"
			IF get_debug() THEN 
				CALL debug_info_invoice_line_input_array("#ON ACTION (\"ADVANCED LOOKUP\") infield(part_code)1",NULL,l_rec_curr_row_invoicedetl.line_num,l_arr_rec_invoicedetl_list[l_idx].line_num, l_idx,l_rec_curr_row_invoicedetl.*,l_rec_curr_row_invoicedetl_original.*,l_arr_rec_invoicedetl_list[l_idx].*)
			END IF
			
			LET l_rec_curr_row_invoicedetl.part_code = l_arr_rec_invoicedetl_list[l_idx].part_code
							 
--				LET l_rec_curr_row_invoicedetl.part_code = get_fldbuf(part_code) 
--				IF length(l_rec_curr_row_invoicedetl.part_code) = 0 THEN 
--					## get_fldbuf returns spaces instead of nulls
--					LET l_rec_curr_row_invoicedetl.part_code = NULL 
--				END IF 

			#----------------- This block is for each lookup event in the input array
			#Validate Field(s) and update temp invoice line
			CALL validate_field_and_update_temp_line("part_code",l_rec_curr_row_invoicedetl.*) RETURNING l_valid_ind,l_ret_next_field,l_rec_curr_row_invoicedetl.*
			CALL invoicedetl_morph_rec_to_list_line(l_rec_curr_row_invoicedetl.*) RETURNING l_arr_rec_invoicedetl_list[l_idx].* 
--				IF NOT l_valid_ind THEN #@@@@ 
				#Open Window A145 to enter invoice line details /level_code
			IF invoice_line_entry_dialog(l_rec_curr_row_invoicedetl.*) THEN
				IF get_debug() THEN 
					CALL debug_info_invoice_line_input_array("#ON ACTION (\"ADVANCED LOOKUP\") infield(part_code)2",NULL,l_rec_curr_row_invoicedetl.line_num,l_arr_rec_invoicedetl_list[l_idx].line_num, l_idx,l_rec_curr_row_invoicedetl.*,l_rec_curr_row_invoicedetl_original.*,l_arr_rec_invoicedetl_list[l_idx].*)
				END IF
	
						CALL db_st_invoicedetl_get_row_by_line_num(l_arr_rec_invoicedetl_list[l_idx].line_num) RETURNING l_arr_rec_invoicedetl_list[l_idx].*, l_rec_curr_row_invoicedetl.*
	
				IF get_debug() THEN 
					CALL debug_info_invoice_line_input_array("#ON ACTION (\"ADVANCED LOOKUP\") infield(part_code)3",NULL,l_rec_curr_row_invoicedetl.line_num,l_arr_rec_invoicedetl_list[l_idx].line_num, l_idx,l_rec_curr_row_invoicedetl.*,l_rec_curr_row_invoicedetl_original.*,l_arr_rec_invoicedetl_list[l_idx].*)
				END IF

			END IF 

			-- #I'm not sure if this is required... keep it commented
			--			ON ACTION "Adv. Lookup" infield(scroll_flagpart_code)
			--      ON KEY(F8) infield(scroll_flag)
			--
				--     #       OTHERWISE
			--               LET glob_temp_text = "scroll_flag"
			--               SELECT * INTO l_rec_curr_row_invoicedetl.*
			--                 FROM t_invoicedetl
			--                WHERE line_num = l_arr_rec_invoicedetl_list[l_idx].line_num
			--         #END CASE
			--         #----------------- This block is for each lookup event in the input array
			--					#Validate Field(s) and update temp invoice line
			--         CALL validate_field_and_update_temp_line(glob_temp_text,l_ret_next_field,l_rec_curr_row_invoicedetl.*)
			--            returning l_valid_ind,l_rec_curr_row_invoicedetl.*
			--         IF l_valid_ind THEN
			--            IF invoice_line_entry_dialog(l_rec_curr_row_invoicedetl.*) THEN #Advanced Line item entry
			--               NEXT FIELD line_total_amt
			--            END IF
			--         END IF

			IF get_debug() THEN 
				CALL debug_show_keys("ADVANCED LOOKUP - infield(part_code)")
			END IF
			
			IF (l_arr_rec_invoicedetl_list[l_idx].part_code IS NULL) AND (l_arr_rec_invoicedetl_list.getSize() > 0) THEN
				CALL dialog.setActionHidden("APPEND",TRUE)
			ELSE
				CALL dialog.setActionHidden("APPEND",FALSE)
			END IF


		#----------------------------------------------------------------------------------------------------------
		ON ACTION ("ADVANCED LOOKUP") infield(ship_qty) 
			LET glob_temp_text = "ship_qty"
			IF get_debug() THEN 
				CALL debug_info_invoice_line_input_array("#ON ACTION (\"ADVANCED LOOKUP\") infield(ship_qty)1",NULL,l_rec_curr_row_invoicedetl.line_num,l_arr_rec_invoicedetl_list[l_idx].line_num, l_idx,l_rec_curr_row_invoicedetl.*,l_rec_curr_row_invoicedetl_original.*,l_arr_rec_invoicedetl_list[l_idx].*)
			END IF
			
			LET l_rec_curr_row_invoicedetl.ship_qty = l_arr_rec_invoicedetl_list[l_idx].ship_qty 
--				WHENEVER ERROR CONTINUE 
--				LET l_rec_curr_row_invoicedetl.ship_qty = get_fldbuf(ship_qty) 
--				WHENEVER ERROR stop 

			#Validate Field(s) and update temp invoice line
			CALL validate_field_and_update_temp_line("ship_qty",l_rec_curr_row_invoicedetl.*) RETURNING l_valid_ind,l_ret_next_field,l_rec_curr_row_invoicedetl.* 
			CALL invoicedetl_morph_rec_to_list_line(l_rec_curr_row_invoicedetl.*) RETURNING l_arr_rec_invoicedetl_list[l_idx].*

			IF get_debug() THEN 
				CALL debug_info_invoice_line_input_array("#ON ACTION (\"ADVANCED LOOKUP\") infield(ship_qty)2",NULL,l_rec_curr_row_invoicedetl.line_num,l_arr_rec_invoicedetl_list[l_idx].line_num, l_idx,l_rec_curr_row_invoicedetl.*,l_rec_curr_row_invoicedetl_original.*,l_arr_rec_invoicedetl_list[l_idx].*)
			END IF

			IF l_rec_curr_row_invoicedetl.ware_code IS NOT NULL THEN
				IF invoice_line_entry_dialog(l_rec_curr_row_invoicedetl.*) THEN 
					CALL db_st_invoicedetl_get_row_by_line_num(l_arr_rec_invoicedetl_list[l_idx].line_num) RETURNING l_arr_rec_invoicedetl_list[l_idx].*, l_rec_curr_row_invoicedetl.* 
				END IF 
			END IF
			
			IF get_debug() THEN 
				CALL debug_info_invoice_line_input_array("#ON ACTION (\"ADVANCED LOOKUP\") infield(ship_qty)3",NULL,l_rec_curr_row_invoicedetl.line_num,l_arr_rec_invoicedetl_list[l_idx].line_num, l_idx,l_rec_curr_row_invoicedetl.*,l_rec_curr_row_invoicedetl_original.*,l_arr_rec_invoicedetl_list[l_idx].*)
			END IF

			IF (l_arr_rec_invoicedetl_list[l_idx].part_code IS NULL) AND (l_arr_rec_invoicedetl_list.getSize() > 0) THEN
				CALL dialog.setActionHidden("APPEND",TRUE)
			ELSE
				CALL dialog.setActionHidden("APPEND",FALSE)
			END IF

		#----------------------------------------------------------------------------------------------------------
		ON ACTION ("ADVANCED LOOKUP") infield(unit_sale_amt) 
			LET glob_temp_text = "unit_sale_amt"
			IF get_debug() THEN 
				CALL debug_info_invoice_line_input_array("#ON ACTION (\"ADVANCED LOOKUP\\)1 infield(unit_sale_amt)",NULL,l_rec_curr_row_invoicedetl.line_num,l_arr_rec_invoicedetl_list[l_idx].line_num, l_idx,l_rec_curr_row_invoicedetl.*,l_rec_curr_row_invoicedetl_original.*,l_arr_rec_invoicedetl_list[l_idx].*)
			END IF
			
			LET l_rec_curr_row_invoicedetl.unit_sale_amt = l_arr_rec_invoicedetl_list[l_idx].unit_sale_amt
--				WHENEVER ERROR CONTINUE 
--				LET l_rec_curr_row_invoicedetl.unit_sale_amt = get_fldbuf(unit_sale_amt) 
--				WHENEVER ERROR stop 

			#Validate Field(s) and update temp invoice line
			CALL validate_field_and_update_temp_line("unit_sale_amt",l_rec_curr_row_invoicedetl.*) RETURNING l_valid_ind,l_ret_next_field,l_rec_curr_row_invoicedetl.* 
			CALL invoicedetl_morph_rec_to_list_line(l_rec_curr_row_invoicedetl.*) RETURNING l_arr_rec_invoicedetl_list[l_idx].*

			IF get_debug() THEN 
				CALL debug_info_invoice_line_input_array("#ON ACTION (\"ADVANCED LOOKUP\\)2 infield(unit_sale_amt)",NULL,l_rec_curr_row_invoicedetl.line_num,l_arr_rec_invoicedetl_list[l_idx].line_num, l_idx,l_rec_curr_row_invoicedetl.*,l_rec_curr_row_invoicedetl_original.*,l_arr_rec_invoicedetl_list[l_idx].*)
			END IF

			IF invoice_line_entry_dialog(l_rec_curr_row_invoicedetl.*) THEN 
				CALL db_st_invoicedetl_get_row_by_line_num(l_arr_rec_invoicedetl_list[l_idx].line_num) RETURNING l_arr_rec_invoicedetl_list[l_idx].*, l_rec_curr_row_invoicedetl.* 
			END IF 

			IF get_debug() THEN 
				CALL debug_info_invoice_line_input_array("#ON ACTION (\"ADVANCED LOOKUP\\)infield(unit_sale_amt)3",NULL,l_rec_curr_row_invoicedetl.line_num,l_arr_rec_invoicedetl_list[l_idx].line_num, l_idx,l_rec_curr_row_invoicedetl.*,l_rec_curr_row_invoicedetl_original.*,l_arr_rec_invoicedetl_list[l_idx].*)
			END IF


			IF (l_arr_rec_invoicedetl_list[l_idx].part_code IS NULL) AND (l_arr_rec_invoicedetl_list.getSize() > 0) THEN
				CALL dialog.setActionHidden("APPEND",TRUE)
			ELSE
				CALL dialog.setActionHidden("APPEND",FALSE)
			END IF

		#----------------------------------------------------------------------------------------------------------
		ON ACTION "DELETE" #ON KEY (F2) #DELETE
			LET l_idx = arr_curr()  
			IF get_debug() THEN 
				CALL debug_info_invoice_line_input_array("#ON ACTION \"DELETE\"",NULL,l_rec_curr_row_invoicedetl.line_num,l_arr_rec_invoicedetl_list[l_idx].line_num, l_idx,l_rec_curr_row_invoicedetl.*,l_rec_curr_row_invoicedetl_original.*,l_arr_rec_invoicedetl_list[l_idx].*)
			END IF
			
			--LET l_select_count = 0
			LET l_del_idx = 1
			CALL l_arr_rec_del_invoicedetl_list.clear()
			FOR i = 1 TO l_arr_rec_invoicedetl_list.getSize()
				IF l_arr_rec_invoicedetl_list[i].scroll_flag = "*" THEN
					--LET l_select_count = l_select_count + 1
					LET l_arr_rec_del_invoicedetl_list[l_del_idx].* = l_arr_rec_invoicedetl_list[i].*
					LET l_del_idx = l_del_idx + 1
				END IF
			END FOR
			
			IF l_arr_rec_del_invoicedetl_list.getSize() > 0 THEN #user selected row(s) using the row checkBox
				LET l_msg = "Are you sure, you want to delete ", trim(l_arr_rec_del_invoicedetl_list.getSize()) , " Line Items ?"
				IF promptTF("Delete",l_msg,FALSE) THEN
					LET l_del_idx = 1
					WHILE l_del_idx <= l_arr_rec_del_invoicedetl_list.getSize()
						#I have no idea YET how SERIAL works.. need the IN(Warehouse) app working to investigate this (can only guess)
						#Delete possible serial code for warehouse items
						IF l_arr_rec_del_invoicedetl_list[l_del_idx].ware_code IS NOT NULL THEN #Serial code works only with warehouse items
							CALL serial_delete(l_arr_rec_del_invoicedetl_list[l_del_idx].part_code, l_arr_rec_del_invoicedetl_list[l_del_idx].ware_code) #HuHo.. This is fully not-documented.. what is this ? it does operations on a table which is empty ? common/4gl file
						END IF
						#Delete row from invoice line temp table
						CALL db_st_invoicedetl_delete_row(l_arr_rec_del_invoicedetl_list[l_del_idx].line_num)
						#Delete from DELETE-program array
						CALL l_arr_rec_del_invoicedetl_list.delete(l_del_idx)
					END WHILE

--				FOR i = 1 TO l_arr_rec_del_invoicedetl_list.getLength()					
--					CALL serial_delete(l_arr_rec_invoicedetl_list[i].part_code, l_rec_curr_row_invoicedetl.ware_code) #HuHo.. This is fully not-documented.. what is this ? it does operations on a table which is empty ? common/4gl file
--					CALL db_st_invoicedetl_delete_row(l_arr_del_line_num[i])
--				END FOR
				END IF #End of PROMPT - do you really want to delete
			ELSE #NO row was selected using the checkBox - we delete the currently selected row
				--WHENEVER ERROR CONTINUE
				--	DELETE FROM t_invoicedetl 
				--	WHERE line_num = l_arr_rec_invoicedetl_list[l_idx].line_num
				--	CALL l_arr_rec_invoicedetl_list.delete(l_idx)
				#I have no idea YET how SERIAL works.. need the IN(Warehouse) app working to investigate this
						#Delete possible serial code for warehouse items
				IF l_arr_rec_del_invoicedetl_list[l_del_idx].ware_code IS NOT NULL THEN #Serial code works only with warehouse items
					CALL serial_delete(l_arr_rec_invoicedetl_list[i].part_code, l_rec_curr_row_invoicedetl.ware_code) #HuHo.. This is fully not-documented.. what is this ? it does operations on a table which is empty ? common/4gl file
				END IF
				CALL db_st_invoicedetl_delete_row(l_arr_rec_invoicedetl_list[l_idx].line_num)
--				CALL l_arr_rec_invoicedetl_list.clear() #clear existing array
--				CALL db_st_invoicedetl_get_arr_rec_invoice_lines RETURNING l_arr_rec_invoicedetl_list
--				CALL invoicedetl_morph_rec_to_list_line(l_rec_curr_row_invoicedetl.*) RETURNING l_arr_rec_invoicedetl_list[l_idx].*			 
--				CALL disp_total(l_rec_curr_row_invoicedetl.*) 

--				CALL l_arr_rec_invoicedetl_list.delete(l_idx)
--					WHENEVER ERROR STOP 
			END IF

			#Refresh & clean Data Array from DB
			CALL l_arr_rec_invoicedetl_list.clear()
			CALL db_st_invoicedetl_get_arr_rec_invoice_lines() RETURNING l_arr_rec_invoicedetl_list
			
#I have issues with deleting program array rows in an active input array.
#This section needs cleaning AFTER we get feedback on how to do this correctly 
#Ticket	https://querix.atlassian.net/browse/KD-1983		
 
			--LET l_idx = arr_curr() #just refresh current row index after delete operations
			LET l_idx = DIALOG.getCurrentRow("sr_invoicedetl")
			CALL fgl_dialog_setcurrline(1,1)
			CALL DIALOG.setCurrentRow("sr_invoicedetl",1)
			LET l_idx = DIALOG.getCurrentRow("sr_invoicedetl")
			IF l_arr_rec_invoicedetl_list.getSize() > 0 THEN
				CALL DIALOG.setCurrentRow("sr_invoicedetl",1)
				--LET l_idx = arr_curr() #just refresh current row index after delete operations
				LET l_idx = DIALOG.getCurrentRow("sr_invoicedetl")
			END IF
 
			LET l_idx = DIALOG.getCurrentRow("sr_invoicedetl")
						
			IF (l_idx > 0) AND (l_arr_rec_invoicedetl_list.getSize()) > 0 THEN
				CALL dialog.setActionHidden("APPEND",FALSE)
				CALL dialog.setActionHidden("DELETE",FALSE)

				SELECT * INTO l_rec_curr_row_invoicedetl.* 
				FROM t_invoicedetl 
				WHERE line_num = l_arr_rec_invoicedetl_list[l_idx].line_num 
				IF sqlca.sqlcode != 0 THEN
					INITIALIZE l_rec_curr_row_invoicedetl.* TO NULL 
				END IF 
			ELSE
				CALL dialog.setActionHidden("APPEND",FALSE)
				CALL dialog.setActionHidden("DELETE",TRUE)
			END IF

			CALL disp_total(l_rec_curr_row_invoicedetl.*)
			CALL fgl_dialog_setcurrline(1,1) 
			NEXT FIELD scroll_flag 

		#----------------------------------------------------------------------------------------------------------
		BEFORE INSERT
			IF get_debug() THEN 
				CALL debug_info_invoice_line_input_array("#BEFORE INSERT",NULL,l_rec_curr_row_invoicedetl.line_num,l_arr_rec_invoicedetl_list[l_idx].line_num, l_idx,l_rec_curr_row_invoicedetl.*,l_rec_curr_row_invoicedetl_original.*,l_arr_rec_invoicedetl_list[l_idx].*)
			END IF

			# line_num -> New row needs a new incrementing line_num done by insert_line calling ...
			IF l_rec_curr_row_invoicedetl.line_num IS NULL THEN 
				CALL insert_line(l_rec_curr_row_invoicedetl.*) RETURNING l_rec_curr_row_invoicedetl.* 
				CALL invoicedetl_morph_rec_to_list_line(l_rec_curr_row_invoicedetl.*) RETURNING l_arr_rec_invoicedetl_list[l_idx].*
				INITIALIZE l_rec_curr_row_invoicedetl_original.* TO NULL #New row has no backup / only on edit 
			ELSE #Edit existing line 
				LET l_rec_curr_row_invoicedetl_original.* = l_rec_curr_row_invoicedetl.* #create backup line
				CALL invoicedetl_morph_rec_to_list_line(l_rec_curr_row_invoicedetl.*) RETURNING l_arr_rec_invoicedetl_list[l_idx].*
			END IF 

			LET l_part_code = l_rec_curr_row_invoicedetl_original.part_code

			CALL disp_total(l_rec_curr_row_invoicedetl.*) 

		#########################################################################################################
		#BEFORE / AFTER ROW
		#########################################################################################################

		# BEFORE ROW --------------------------------------------------------------------------------
		BEFORE ROW  
			LET l_idx = arr_curr()
--			LET l_lastkey = NULL
			IF get_debug() THEN 
				CALL debug_info_invoice_line_input_array("#### BEFORE ROW",NULL,l_rec_curr_row_invoicedetl.line_num,l_arr_rec_invoicedetl_list[l_idx].line_num, l_idx,l_rec_curr_row_invoicedetl.*,l_rec_curr_row_invoicedetl_original.*,l_arr_rec_invoicedetl_list[l_idx].*)
			END IF

			#Handle line_num and event buttons
			IF l_idx < 1 THEN #array list could be empty (i.e. at the beginning OR after delete)
				CALL dialog.setActionHidden("APPEND",FALSE)
				CALL dialog.setActionHidden("DELETE",TRUE)
			ELSE
				CALL dialog.setActionHidden("DELETE",FALSE)
				IF (((l_arr_rec_invoicedetl_list[l_idx].ware_code IS NOT NULL) AND (l_arr_rec_invoicedetl_list[l_idx].part_code IS NOT NULL)) #WH needs part_code
				OR ((l_arr_rec_invoicedetl_list[l_idx].ware_code IS NULL) AND (l_arr_rec_invoicedetl_list[l_idx].line_text IS NOT NULL))) #None-WH needs line_text
				AND (l_arr_rec_invoicedetl_list.getSize() > 0) THEN #New Row
	
					CALL dialog.setActionHidden("APPEND",FALSE) #Existing Row
				ELSE
					CALL dialog.setActionHidden("APPEND",TRUE) #NEW Row
				END IF

				#Init backup row record
				INITIALIZE l_rec_curr_row_invoicedetl_original.* TO NULL #backup record is NULL for new rows

				#NEW ROW
				IF l_arr_rec_invoicedetl_list[l_idx].line_num IS NULL OR l_arr_rec_invoicedetl_list[l_idx].line_num = 0 THEN #NEW ROW
					LET l_mode_edit = FALSE #New row was created and needs to be completed or removed
					CALL init_rec_invoicedetl() RETURNING l_rec_curr_row_invoicedetl.*
{
					INITIALIZE l_rec_curr_row_invoicedetl.* TO NULL

					LET l_rec_curr_row_invoicedetl.cmpy_code = glob_rec_kandoouser.cmpy_code #company (user company)
					LET l_rec_curr_row_invoicedetl.cust_code = glob_rec_customer.cust_code #customer
					LET l_rec_curr_row_invoicedetl.ware_code = glob_rec_warehouse.ware_code #warehouse
					LET l_rec_curr_row_invoicedetl.tax_code = glob_rec_customer.tax_code #TaxCode from Customer

					LET l_rec_curr_row_invoicedetl.inv_num = 0 !!!!!!!!!!!!!!
					LET l_rec_curr_row_invoicedetl.ord_qty = 0
					LET l_rec_curr_row_invoicedetl.ship_qty = 0
					LET l_rec_curr_row_invoicedetl.prev_qty = 0
					LET l_rec_curr_row_invoicedetl.back_qty = 0
					LET l_rec_curr_row_invoicedetl.ser_qty = 0
					LET l_rec_curr_row_invoicedetl.unit_cost_amt = 0
					LET l_rec_curr_row_invoicedetl.ext_cost_amt = 0
					LET l_rec_curr_row_invoicedetl.unit_tax_amt = 0
					LET l_rec_curr_row_invoicedetl.ext_tax_amt = 0
					LET l_rec_curr_row_invoicedetl.line_total_amt = 0
					LET l_rec_curr_row_invoicedetl.seq_num = 0
					LET l_rec_curr_row_invoicedetl.comm_amt = 0
					LET l_rec_curr_row_invoicedetl.comp_per = 0
					LET l_rec_curr_row_invoicedetl.order_lin_num = 0
					LET l_rec_curr_row_invoicedetl.order_num = 0
					LET l_rec_curr_row_invoicedetl.disc_per = 0
					LET l_rec_curr_row_invoicedetl.sold_qty = 0
					LET l_rec_curr_row_invoicedetl.bonus_qty = 0
					LET l_rec_curr_row_invoicedetl.ext_bonust_amt = 0
					LET l_rec_curr_row_invoicedetl.ext_stats_amt = 0
					LET l_rec_curr_row_invoicedetl.list_price_amt = 0
					LET l_rec_curr_row_invoicedetl.var_code = 0
					LET l_rec_curr_row_invoicedetl.jobledger_seq_num = 0
					LET l_rec_curr_row_invoicedetl.contract_line_num = 0

					#Warehouse Dependencies				
					IF l_rec_curr_row_invoicedetl.ware_code IS NOT NULL THEN #GL account and Tax code will be initialized by Warehouse-Part
						#so far, I can not think about anything I need to do if I use a warehouse item - warehouse part provides me with all data
					ELSE #none-warehouse item
						LET l_rec_curr_row_invoicedetl.line_acct_code = db_category_get_first_sale_acct_code(UI_OFF)   #First available category sales account
						LET l_rec_curr_row_invoicedetl.tax_code = glob_rec_customer.tax_code
					END IF
}
					#Store initial data in DB
					CALL insert_line(l_rec_curr_row_invoicedetl.*) RETURNING l_rec_curr_row_invoicedetl.*

					#Retrieve data for List/Input Array data
					CALL invoicedetl_morph_rec_to_list_line(l_rec_curr_row_invoicedetl.*) RETURNING l_arr_rec_invoicedetl_list[l_idx].*

				ELSE #EDIT existing row		
					LET l_mode_edit = TRUE #Existing Row			
					LET l_rec_curr_row_invoicedetl_original.* = l_rec_curr_row_invoicedetl.* #edit existing row - create line record copy
					LET l_part_code = l_rec_curr_row_invoicedetl_original.part_code #check out the purpose of l_part_code and l_line_text
					LET l_line_text = l_rec_curr_row_invoicedetl_original.line_text #check out the purpose of l_part_code and l_line_text
					CALL db_st_invoicedetl_get_row_by_line_num(l_arr_rec_invoicedetl_list[l_idx].line_num)
					RETURNING l_arr_rec_invoicedetl_list[l_idx].*, l_rec_curr_row_invoicedetl.*
				END IF
			END IF

			#Enable/Disable fields depending on warehouse or free item
			CALL invoicedetl_enable_disable_fields(l_rec_curr_row_invoicedetl.*)
			#Update totals display
			CALL disp_total(l_rec_curr_row_invoicedetl.*)
			
--			IF l_arr_rec_invoicedetl_list[l_idx].ware_code IS NOT NULL THEN #warehouse item	
--				CALL set_fieldattribute_readonly("invoicedetl.part_code",FALSE)
--				CALL set_fieldattribute_readonly("invoicedetl.line_text",TRUE)
--			ELSE #Free Item (warehouse disabled for this row
--				CALL set_fieldattribute_readonly("invoicedetl.part_code",TRUE)
--				CALL set_fieldattribute_readonly("invoicedetl.line_text",FALSE)
--			END IF				

--			#Next Field depends on warehouse: NULL (free item) -> list_text  and with warehouse -> part_code 
--			IF l_arr_rec_invoicedetl_list[l_idx].ware_code IS NOT NULL THEN #warehouse is enabled
--				NEXT FIELD part_code
--			ELSE #warehouse is disabled			
--				NEXT FIELD line_text
--			END IF  
--					--LET l_lastkey = NULL #; IF (l_arr_rec_invoicedetl_list[l_idx].line_num != 0) AND (l_arr_rec_invoicedetl_list[l_idx].line_num IS NOT NULL) THEN  
--					SELECT * INTO l_rec_curr_row_invoicedetl.*  #copy row record from temp table into var_rec 
--					FROM t_invoicedetl 
--					WHERE line_num = l_arr_rec_invoicedetl_list[l_idx].line_num 	
--					IF sqlca.sqlcode = NOTFOUND THEN #on new row, (empty),
--						INITIALIZE l_rec_curr_row_invoicedetl.* TO NULL 
					--LET l_rec_curr_row_invoicedetl.line_num = NULL
--					LET l_rec_curr_row_invoicedetl.cmpy_code = glob_rec_kandoouser.cmpy_code   
--					LET l_rec_curr_row_invoicedetl.cust_code = glob_rec_customer.cust_code
--					--LET l_rec_curr_row_invoicedetl.corp_cust_code = glob_rec_customer.corp_cust_code
--					NEXT FIELD line_num 
--				ELSE 
--					CALL disp_total(l_rec_curr_row_invoicedetl.*) 
--					NEXT FIELD scroll_flag 
--				END IF 

		#------------------------------------------------------
		AFTER ROW
			LET l_idx = arr_curr()
			IF get_debug() THEN 
				CALL debug_info_invoice_line_input_array("#### AFTER ROW",NULL,l_rec_curr_row_invoicedetl.line_num,l_arr_rec_invoicedetl_list[l_idx].line_num, l_idx,l_rec_curr_row_invoicedetl.*,l_rec_curr_row_invoicedetl_original.*,l_arr_rec_invoicedetl_list[l_idx].*)
			END IF

			#User can press Cancel at any time during input
			IF int_flag = TRUE AND (l_arr_rec_invoicedetl_list.getSize() <= 1) THEN  #If the array is empty or only one line exists, Exit input 
				--LET int_flag = FALSE
				EXIT INPUT
			END IF

			--IF (l_arr_rec_invoicedetl_list[l_idx].line_num != 0) AND (l_arr_rec_invoicedetl_list[l_idx].part_code IS NULL) THEN  #User navigates away from new line.. temp table row must be removed too 
			IF l_idx > 0 THEN #save guard for delete the only one row... idx = 0

				#Validate Field(s) and update temp invoice line						 
				CALL validate_field_and_update_temp_line("all",l_rec_curr_row_invoicedetl.*)  RETURNING l_valid_ind,l_ret_next_field,l_rec_curr_row_invoicedetl.*
				IF l_valid_ind THEN
					CALL invoicedetl_morph_rec_to_list_line(l_rec_curr_row_invoicedetl.*) RETURNING l_arr_rec_invoicedetl_list[l_idx].*
				ELSE
					CASE l_ret_next_field
						WHEN A21_INV_LINE_FIELD_WARE_CODE
							NEXT FIELD WARE_CODE
						WHEN A21_INV_LINE_FIELD_PART_CODE
							NEXT FIELD PART_CODE
						WHEN A21_INV_LINE_FIELD_LINE_TEXT
							NEXT FIELD LINE_TEXT
						WHEN A21_INV_LINE_FIELD_LINE_ACCT_CODE
							NEXT FIELD LINE_ACCT_CODE														
					END CASE 

				END IF
{				
			#APPEND = last action ! Special Case: Empty row and user presses again APPEND/New Row
				IF (fgl_lastAction()= "append") OR (fgl_lastAction()= "insert") AND 
				(l_arr_rec_invoicedetl_list[l_idx].part_code IS NULL) AND (l_arr_rec_invoicedetl_list[l_idx].line_text IS NULL) ) THEN
					IF l_arr_rec_invoicedetl_list[l_idx].ware_code IS NOT NULL THEN #warehouse				
						NEXT FIELD part_code
					ELSE #free none warehouse item
						NEXT FIELD line_text 
					END IF
				END IF
}
				#User navigates aways from 'empty' row - temp table row must be removed too 
				#Warehous enabled for this invoice and Part Code is EMPTY
				IF ((l_rec_curr_row_invoicedetl.ware_code IS NOT NULL) AND (l_rec_curr_row_invoicedetl.part_code IS NULL)) #Warehouse-> partCode is NULL 
				OR ((l_rec_curr_row_invoicedetl.ware_code IS NULL)     AND (l_rec_curr_row_invoicedetl.line_text IS NULL)) #None Warehouse -> line_text is NULL
				THEN
					#Serical Code needs testing when we have got the WareHouse modules in testing stage
					CALL serial_delete(l_rec_curr_row_invoicedetl.part_code, l_rec_curr_row_invoicedetl.ware_code) #HuHo.. This is fully not-documented.. what is this ? it does operations on a table which is empty ? common/4gl file
					#Delete row from table
					CALL db_st_invoicedetl_delete_row(l_rec_curr_row_invoicedetl.line_num) #delete this none-valid row from temp table
					CALL l_arr_rec_invoicedetl_list.delete(l_idx) #delete is also from program data input array 
				ELSE #Final validation
--					#Validate Shipping Quantity #WHY do I need this here again ?
--					IF l_rec_curr_row_invoicedetl.ship_qty < 0 THEN
--						ERROR "Quantity can not be negative"
--						NEXT FIELD ship_qty
--					END IF
					
					#Line total must be calculated IF row data has changed				
					---------------------------------
					IF (
						l_rec_curr_row_invoicedetl_original.line_num != l_arr_rec_invoicedetl_list[l_idx].line_num OR
						NOT compare_pos_null_str(l_rec_curr_row_invoicedetl_original.ware_code, l_arr_rec_invoicedetl_list[l_idx].ware_code) OR
						NOT compare_pos_null_str(l_rec_curr_row_invoicedetl_original.part_code, l_arr_rec_invoicedetl_list[l_idx].part_code) OR
						NOT compare_pos_null_str(l_rec_curr_row_invoicedetl_original.line_text, l_arr_rec_invoicedetl_list[l_idx].line_text) OR
						NOT compare_pos_null_str(l_rec_curr_row_invoicedetl_original.line_acct_code, l_arr_rec_invoicedetl_list[l_idx].line_acct_code) OR
						NOT compare_pos_null_str(l_rec_curr_row_invoicedetl_original.tax_code, l_arr_rec_invoicedetl_list[l_idx].tax_code) OR
						l_rec_curr_row_invoicedetl_original.ship_qty != l_arr_rec_invoicedetl_list[l_idx].ship_qty OR
						l_rec_curr_row_invoicedetl_original.unit_sale_amt != l_arr_rec_invoicedetl_list[l_idx].unit_sale_amt OR
						l_rec_curr_row_invoicedetl_original.disc_amt != l_arr_rec_invoicedetl_list[l_idx].disc_amt OR
						l_rec_curr_row_invoicedetl_original.unit_tax_amt != l_arr_rec_invoicedetl_list[l_idx].unit_tax_amt 
					) THEN

						SELECT * INTO l_rec_curr_row_invoicedetl.*  #copy current temp table row to local record ??? This task is done many times.. is this really required ? 
							FROM t_invoicedetl 
							WHERE line_num = l_rec_curr_row_invoicedetl.line_num 

						LET l_arr_rec_invoicedetl_list[l_idx].part_code = l_rec_curr_row_invoicedetl.part_code 
						LET l_arr_rec_invoicedetl_list[l_idx].line_text = l_rec_curr_row_invoicedetl.line_text 
						LET l_arr_rec_invoicedetl_list[l_idx].ship_qty = l_rec_curr_row_invoicedetl.ship_qty 
						LET l_arr_rec_invoicedetl_list[l_idx].unit_sale_amt = l_rec_curr_row_invoicedetl.unit_sale_amt 
						LET l_arr_rec_invoicedetl_list[l_idx].unit_tax_amt =  l_rec_curr_row_invoicedetl.unit_tax_amt
						LET l_arr_rec_invoicedetl_list[l_idx].tax_code =  l_rec_curr_row_invoicedetl.tax_code 
						LET l_arr_rec_invoicedetl_list[l_idx].ext_sale_amt=l_rec_curr_row_invoicedetl.ext_sale_amt
						LET l_arr_rec_invoicedetl_list[l_idx].ext_tax_amt=l_rec_curr_row_invoicedetl.ext_tax_amt 
--						LET l_arr_rec_invoicedetl_list[l_idx].line_total_amt=l_rec_curr_row_invoicedetl.line_total_amt

						IF glob_rec_arparms.show_tax_flag = "N" THEN 
							LET l_arr_rec_invoicedetl_list[l_idx].line_total_amt = l_rec_curr_row_invoicedetl.ext_sale_amt 
						ELSE 
							LET l_arr_rec_invoicedetl_list[l_idx].line_total_amt = l_rec_curr_row_invoicedetl.line_total_amt 
						END IF 

						--CALL disp_total(l_rec_curr_row_invoicedetl.*) 
					END IF
				END IF
			END IF

			#Update totals display
			CALL disp_total(l_rec_curr_row_invoicedetl.*)

		#########################################################################################################
		# FIELD PROCESSING BEFORE/AFTER FIELD
		#########################################################################################################
		#--------------------------------------------
		# SCROLL_FLAG -------------------------------
		BEFORE FIELD scroll_flag
			IF get_debug() THEN 
				CALL debug_info_invoice_line_input_array("#BEFORE FIELD scroll_flag",NULL,l_rec_curr_row_invoicedetl.line_num,l_arr_rec_invoicedetl_list[l_idx].line_num, l_idx,l_rec_curr_row_invoicedetl.*,l_rec_curr_row_invoicedetl_original.*,l_arr_rec_invoicedetl_list[l_idx].*)
			END IF
			#NOTHING
	
		ON CHANGE scroll_flag
			IF get_debug() THEN 
				CALL debug_info_invoice_line_input_array("#ON CHANGE scroll_flag",NULL,l_rec_curr_row_invoicedetl.line_num,l_arr_rec_invoicedetl_list[l_idx].line_num, l_idx,l_rec_curr_row_invoicedetl.*,l_rec_curr_row_invoicedetl_original.*,l_arr_rec_invoicedetl_list[l_idx].*)
			END IF
			#NOTHING

		AFTER FIELD scroll_flag
			IF get_debug() THEN
				CALL debug_info_invoice_line_input_array("#AFTER FIELD scroll_flag",NULL,l_rec_curr_row_invoicedetl.line_num,l_arr_rec_invoicedetl_list[l_idx].line_num, l_idx,l_rec_curr_row_invoicedetl.*,l_rec_curr_row_invoicedetl_original.*,l_arr_rec_invoicedetl_list[l_idx].*)
			END IF				
			#NOTHING

		#--------------------------------------------
		# LINE_NUM (Read Only) ----------------------
		BEFORE FIELD line_num 
			IF get_debug() THEN 
				CALL debug_info_invoice_line_input_array("#BEFORE FIELD line_num",NULL,l_rec_curr_row_invoicedetl.line_num,l_arr_rec_invoicedetl_list[l_idx].line_num, l_idx,l_rec_curr_row_invoicedetl.*,l_rec_curr_row_invoicedetl_original.*,l_arr_rec_invoicedetl_list[l_idx].*)
			END IF
{
				IF l_rec_curr_row_invoicedetl.line_num IS NULL THEN 
					CALL insert_line(l_rec_curr_row_invoicedetl.*) RETURNING l_rec_curr_row_invoicedetl.* 
					INITIALIZE l_rec_curr_row_invoicedetl_original.* TO NULL 
					LET l_part_code = NULL 
					LET l_arr_rec_invoicedetl_list[l_idx].line_num = l_rec_curr_row_invoicedetl.line_num 
					LET l_arr_rec_invoicedetl_list[l_idx].part_code = l_rec_curr_row_invoicedetl.part_code 
					LET l_arr_rec_invoicedetl_list[l_idx].line_text = l_rec_curr_row_invoicedetl.line_text 
					LET l_arr_rec_invoicedetl_list[l_idx].ship_qty = l_rec_curr_row_invoicedetl.ship_qty 
					LET l_arr_rec_invoicedetl_list[l_idx].unit_sale_amt = l_rec_curr_row_invoicedetl.unit_sale_amt 
					LET l_arr_rec_invoicedetl_list[l_idx].line_total_amt =	l_rec_curr_row_invoicedetl.line_total_amt 
				ELSE 
					LET l_rec_curr_row_invoicedetl_original.* = l_rec_curr_row_invoicedetl.* #edit existing row - create line record copy
					LET l_part_code = l_rec_curr_row_invoicedetl_original.part_code #check out the purpose of l_part_code and l_line_text
					LET l_line_text = l_rec_curr_row_invoicedetl_original.line_text #check out the purpose of l_part_code and l_line_text
				END IF 
}
			CALL disp_total(l_rec_curr_row_invoicedetl.*) 

		AFTER FIELD line_num 
			IF get_debug() THEN 
				CALL debug_info_invoice_line_input_array("#AFTER FIELD line_num",NULL,l_rec_curr_row_invoicedetl.line_num,l_arr_rec_invoicedetl_list[l_idx].line_num, l_idx,l_rec_curr_row_invoicedetl.*,l_rec_curr_row_invoicedetl_original.*,l_arr_rec_invoicedetl_list[l_idx].*)
			END IF

			IF (l_idx > 0)  AND (l_rec_curr_row_invoicedetl_original.line_num != l_arr_rec_invoicedetl_list[l_idx].line_num) THEN
				#Nothing
			END IF

		#---------------------------------------
		# WARE_CODE ----------------------------
		BEFORE FIELD ware_code
			IF get_debug() THEN 
				CALL debug_info_invoice_line_input_array("#BEFORE FIELD ware_code",NULL,l_rec_curr_row_invoicedetl.line_num,l_arr_rec_invoicedetl_list[l_idx].line_num, l_idx,l_rec_curr_row_invoicedetl.*,l_rec_curr_row_invoicedetl_original.*,l_arr_rec_invoicedetl_list[l_idx].*)
			END IF
			#nothing

		ON CHANGE ware_code
			IF get_debug() THEN 
				CALL debug_info_invoice_line_input_array("#ON CHANGE ware_code",NULL,l_rec_curr_row_invoicedetl.line_num,l_arr_rec_invoicedetl_list[l_idx].line_num, l_idx,l_rec_curr_row_invoicedetl.*,l_rec_curr_row_invoicedetl_original.*,l_arr_rec_invoicedetl_list[l_idx].*)
			END IF			
			#nothing

		AFTER FIELD ware_code 
			LET l_idx = arr_curr()
			IF get_debug() THEN 
				CALL debug_info_invoice_line_input_array("#AFTER FIELD ware_code",NULL,l_rec_curr_row_invoicedetl.line_num,l_arr_rec_invoicedetl_list[l_idx].line_num, l_idx,l_rec_curr_row_invoicedetl.*,l_rec_curr_row_invoicedetl_original.*,l_arr_rec_invoicedetl_list[l_idx].*)
			END IF
	
			IF (l_idx > 0)  AND NOT compare_pos_null_str(l_rec_curr_row_invoicedetl_original.ware_code,l_arr_rec_invoicedetl_list[l_idx].ware_code) THEN
				LET l_rec_curr_row_invoicedetl.ware_code = l_arr_rec_invoicedetl_list[l_idx].ware_code

				#Validate Field(s) and update temp invoice line		
				CALL validate_field_and_update_temp_line("ware_code",l_rec_curr_row_invoicedetl.*) RETURNING l_valid_ind,l_ret_next_field,l_rec_curr_row_invoicedetl.*
				CALL invoicedetl_morph_rec_to_list_line(l_rec_curr_row_invoicedetl.*) RETURNING l_arr_rec_invoicedetl_list[l_idx].*			 
				CALL disp_total(l_rec_curr_row_invoicedetl.*) 

				IF l_valid_ind = FALSE THEN
					NEXT FIELD ware_code
				ELSE
					CALL invoicedetl_enable_disable_fields(l_rec_curr_row_invoicedetl.*)
					IF l_arr_rec_invoicedetl_list[l_idx].ware_code IS NULL THEN #Warehous disabled for this invoice - No Warehouse .. NO partCode
						LET l_rec_curr_row_invoicedetl.part_code = NULL
						CALL invoicedetl_morph_rec_to_list_line(l_rec_curr_row_invoicedetl.*) RETURNING l_arr_rec_invoicedetl_list[l_idx].*
						NEXT FIELD line_text
					ELSE
						NEXT FIELD part_code
					END IF
				END IF
			END IF

			CALL invoicedetl_enable_disable_fields(l_rec_curr_row_invoicedetl.*)


		#-------------------------------------------------
		# PART_CODE (Only with Warehouse) ----------------
		BEFORE FIELD part_code  
			LET l_idx = arr_curr()
			IF get_debug() THEN 
				CALL debug_info_invoice_line_input_array("#BEFORE FIELD part_code",NULL,l_rec_curr_row_invoicedetl.line_num,l_arr_rec_invoicedetl_list[l_idx].line_num, l_idx,l_rec_curr_row_invoicedetl.*,l_rec_curr_row_invoicedetl_original.*,l_arr_rec_invoicedetl_list[l_idx].*)
			END IF			
			
			#-------------------
			#warehouse disabled -> Disable part_code
			IF l_arr_rec_invoicedetl_list[l_idx].ware_code IS NULL THEN #Warehous disabled for this invoice - No Warehouse .. NO partCode
				NEXT FIELD line_text
			END IF

			LET l_part_code = l_rec_curr_row_invoicedetl.part_code  #for what do we need this l_part_code ? 

			#------------------
			#Warehouse operation - get product data
			IF l_idx >= 1 THEN	
				#Edit existing warehouse invoice line - load product part details
				IF l_arr_rec_invoicedetl_list[l_idx].part_code IS NOT NULL THEN   
					CALL db_product_get_rec(UI_OFF,l_arr_rec_invoicedetl_list[l_idx].part_code) RETURNING l_rec_product.* 
--
--					SELECT * INTO l_rec_product.* FROM product 
--					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
--					AND part_code = l_arr_rec_invoicedetl_list[l_idx].part_code 
					IF l_rec_product.serial_flag = 'Y' THEN 
--							NEXT FIELD NEXT --do we need this GOTO really ?
					END IF 
				END IF 
			END IF

		ON CHANGE part_code
			IF get_debug() THEN 
				CALL debug_info_invoice_line_input_array("#ON CHANGE part_code",NULL,l_rec_curr_row_invoicedetl.line_num,l_arr_rec_invoicedetl_list[l_idx].line_num, l_idx,l_rec_curr_row_invoicedetl.*,l_rec_curr_row_invoicedetl_original.*,l_arr_rec_invoicedetl_list[l_idx].*)
			END IF			

			IF get_is_screen_navigation_forward() = TRUE THEN   
				IF (l_arr_rec_invoicedetl_list[l_idx].ware_code IS NOT NULL) AND (l_arr_rec_invoicedetl_list[l_idx].part_code IS NULL) THEN 
					ERROR "Disable Warehouse to enter one-warehouse products and services"
					NEXT FIELD ware_code 
				END IF
			END IF

		AFTER FIELD part_code -----------------------------------------------
			LET l_idx = arr_curr()
			LET l_navigation_forward = get_is_screen_navigation_forward()
			
			IF get_debug() THEN 
				CALL debug_info_invoice_line_input_array("#AFTER FIELD part_code",NULL,l_rec_curr_row_invoicedetl.line_num,l_arr_rec_invoicedetl_list[l_idx].line_num, l_idx,l_rec_curr_row_invoicedetl.*,l_rec_curr_row_invoicedetl_original.*,l_arr_rec_invoicedetl_list[l_idx].*)
			END IF			

			IF (l_idx > 0) AND NOT compare_pos_null_str(l_rec_curr_row_invoicedetl_original.part_code, l_arr_rec_invoicedetl_list[l_idx].part_code) THEN #Make sure, array is not NULL
				#First validation
				#warehouse enabled and empty part code is not possible
				IF l_navigation_forward = TRUE THEN  
					IF (l_arr_rec_invoicedetl_list[l_idx].ware_code IS NOT NULL) AND (l_arr_rec_invoicedetl_list[l_idx].part_code IS NULL) THEN
						ERROR "Disable the warehouse to enter free product items (none-part code)"
						NEXT FIELD ware_code 
					END IF
				END IF

				LET l_rec_curr_row_invoicedetl.part_code = l_arr_rec_invoicedetl_list[l_idx].part_code

				CASE
					#empty and navigation back/up
					WHEN (l_arr_rec_invoicedetl_list[l_idx].part_code IS NULL) AND (l_navigation_forward = FALSE)
						#User wants to change warehouse ware_code
					WHEN l_navigation_forward = TRUE
						--IF ((l_arr_rec_invoicedetl_list[l_idx].part_code IS NULL) AND (get_is_screen_navigation_forward() = FALSE)) THEN 
						---- #((get_is_screen_navigation_forward() IS FALSE) OR fgl_lastaction() = " THEN fgl_lastaction 
						--	CALL db_st_invoicedetl_delete_line(l_arr_rec_invoicedetl_list[l_idx].line_num)
						-- ELSE
						#delete current line

						--IF (l_arr_rec_invoicedetl_list[l_idx].part_code IS NOT NULL) AND (get_is_screen_navigation_forward() = TRUE) THEN
						IF l_part_code IS NULL OR l_rec_curr_row_invoicedetl.part_code != l_part_code THEN #what is l_part_code used for ? 
							##
							## WHEN part code changed (OR first entered) the price
							## AND description must be reset.
							##
		
							## IF part_code IS still NULL, do NOT reinitialise
							## price AND description - it may have been a
							## non-inventory line originally AND the description
							## AND privce are still valid
							##
							IF l_rec_curr_row_invoicedetl.part_code IS NOT NULL THEN 
								LET l_part_code = l_rec_curr_row_invoicedetl.part_code
								LET l_rec_curr_row_invoicedetl.line_text = NULL #??? why
								LET l_rec_curr_row_invoicedetl.unit_sale_amt = NULL #??? why
								 
							END IF 
						END IF 
						#--------------------- Line INPUT DIALOG SCREEN
						#No part code is entered and the user navigates forward - Show Line Entry DIALOG screen
--						IF get_is_screen_navigation_forward() AND l_rec_curr_row_invoicedetl.part_code IS NULL THEN
--							IF invoice_line_entry_dialog(l_rec_curr_row_invoicedetl.*) THEN 
--								CALL db_st_invoicedetl_get_row_by_line_num(l_arr_rec_invoicedetl_list[l_idx].line_num) RETURNING l_arr_rec_invoicedetl_list[l_idx].*,l_rec_curr_row_invoicedetl.*
--							END IF
--						END IF
						#--------------------- 
						#Validate Field(s) and update temp invoice line

						CALL validate_field_and_update_temp_line("part_code",l_rec_curr_row_invoicedetl.*)	RETURNING l_valid_ind,l_ret_next_field,l_rec_curr_row_invoicedetl.*
						CALL invoicedetl_morph_rec_to_list_line(l_rec_curr_row_invoicedetl.*) RETURNING l_arr_rec_invoicedetl_list[l_idx].* 
						CALL disp_total(l_rec_curr_row_invoicedetl.*) 

						--LET l_arr_rec_invoicedetl_list[l_idx].part_code				= l_rec_curr_row_invoicedetl.part_code 
						--LET l_arr_rec_invoicedetl_list[l_idx].line_text				= l_rec_curr_row_invoicedetl.line_text 
						--LET l_arr_rec_invoicedetl_list[l_idx].line_acct_code	= db_category_get_sale_acct_code(UI_OFF,db_product_get_cat_code(UI_OFF,l_rec_curr_row_invoicedetl.part_code)) 
						--LET l_arr_rec_invoicedetl_list[l_idx].unit_sale_amt		= l_rec_curr_row_invoicedetl.unit_sale_amt 
						--LET l_arr_rec_invoicedetl_list[l_idx].tax_code				= l_rec_curr_row_invoicedetl.tax_code		#prodstatus.tax_code
						--LET l_arr_rec_invoicedetl_list[l_idx].disc_amt				= l_rec_curr_row_invoicedetl.disc_amt
						--LET l_arr_rec_invoicedetl_list[l_idx].tax_per					= db_tax_get_tax_per(UI_OFF,l_rec_curr_row_invoicedetl.tax_code)		#prodstatus.tax_code
						--LET l_arr_rec_invoicedetl_list[l_idx].line_total_amt	= l_rec_curr_row_invoicedetl.line_total_amt 

						CASE 
							--WHEN NOT(l_valid_ind) 
							--	NEXT FIELD part_code 

--							WHEN l_lastkey=fgl_keyval("accept") 
--						NEXT FIELD line_total_amt 

							WHEN get_is_screen_navigation_forward() #if part_code is empty and user navigates FORWARD .- show part/product window 
							--l_lastkey=fgl_keyval("RETURN") 
								--OR l_lastkey=fgl_keyval("right") 
								--OR l_lastkey=fgl_keyval("tab") 
								--OR l_lastkey=fgl_keyval("down") 
								IF l_rec_curr_row_invoicedetl.part_code IS NULL THEN 
									IF get_debug() THEN					
										DISPLAY "..............................."
										DISPLAY "l_rec_curr_row_invoicedetl.line_num=", l_rec_curr_row_invoicedetl.line_num
										DISPLAY "l_arr_rec_invoicedetl_list[l_idx].line_num=", l_arr_rec_invoicedetl_list[l_idx].line_num
										DISPLAY "l_idx=", l_idx
										DISPLAY "..............................."
										CALL debug_show_keys("AFTER FIELD part_code")
									END IF

--								IF invoice_line_entry_dialog(l_rec_curr_row_invoicedetl.*) THEN 
--									CALL db_st_invoicedetl_get_row_by_line_num(l_arr_rec_invoicedetl_list[l_idx].line_num) RETURNING l_arr_rec_invoicedetl_list[l_idx].*,l_rec_curr_row_invoicedetl.* 
--		
--									IF get_debug() THEN					
--										DISPLAY "..............................."
--										DISPLAY "l_rec_curr_row_invoicedetl.line_num=", l_rec_curr_row_invoicedetl.line_num
--										DISPLAY "l_arr_rec_invoicedetl_list[l_idx].line_num=", l_arr_rec_invoicedetl_list[l_idx].line_num
--										DISPLAY "l_idx=", l_idx
--										DISPLAY "..............................."
--										CALL debug_show_keys("AFTER FIELD part_code")
--									END IF

	--							--	NEXT FIELD line_total_amt 
--								ELSE 
--									ERROR "Part Code is invalid"
--									NEXT FIELD part_code 
--								END IF 
							ELSE
								CALL db_product_get_rec(UI_OFF,l_rec_curr_row_invoicedetl.part_code) RETURNING l_rec_product.*
							END IF 

						END CASE 
				END CASE

			END IF
			CALL invoicedetl_enable_disable_fields(l_rec_curr_row_invoicedetl.*)


		#-------------------------------------------------
		# LINE_TEXT (only with warehouse disabled) -------
		BEFORE FIELD line_text
			IF get_debug() THEN 
				CALL debug_info_invoice_line_input_array("#BEFORE FIELD line_text",NULL,l_rec_curr_row_invoicedetl.line_num,l_arr_rec_invoicedetl_list[l_idx].line_num, l_idx,l_rec_curr_row_invoicedetl.*,l_rec_curr_row_invoicedetl_original.*,l_arr_rec_invoicedetl_list[l_idx].*)
			END IF			

			#In warehouse mode, disable line_text and navigate to quantity
			IF l_arr_rec_invoicedetl_list[l_idx].ware_code IS NOT NULL THEN #Warehouse is enabled for this invoice - Warehouse .. partCode defines line_text
				NEXT FIELD ship_qty
			END IF

			LET l_line_text = l_rec_curr_row_invoicedetl.line_text  #for what do we need this l_line_text ? 

		ON CHANGE line_text
			IF get_debug() THEN 
				CALL debug_info_invoice_line_input_array("#ON CHANGE line_text",NULL,l_rec_curr_row_invoicedetl.line_num,l_arr_rec_invoicedetl_list[l_idx].line_num, l_idx,l_rec_curr_row_invoicedetl.*,l_rec_curr_row_invoicedetl_original.*,l_arr_rec_invoicedetl_list[l_idx].*)
			END IF			

			IF get_is_screen_navigation_forward() = TRUE THEN 
				IF (l_arr_rec_invoicedetl_list[l_idx].ware_code IS NULL) AND (l_arr_rec_invoicedetl_list[l_idx].line_text IS NULL) THEN 
					ERROR "Disable Warehouse to enter warehouse products and services, Otherwise, enter description line text for none warehouse products and services"
					NEXT FIELD ware_code 
				END IF
			END IF
			#Save array element line_text to local record
			LET l_rec_curr_row_invoicedetl.line_text = l_arr_rec_invoicedetl_list[l_idx].line_text

--			IF l_rec_curr_row_invoicedetl.line_text IS NOT NULL THEN 
--				#Get first/default GL-Sales-Account
--				LET l_rec_curr_row_invoicedetl.line_acct_code = db_category_get_first_sale_acct_code(UI_OFF)
--			ELSE
--				LET l_rec_curr_row_invoicedetl.line_acct_code = NULL
--			END IF

			CALL invoicedetl_morph_rec_to_list_line(l_rec_curr_row_invoicedetl.*) RETURNING l_arr_rec_invoicedetl_list[l_idx].*

		AFTER FIELD line_text
			LET l_idx = arr_curr()
			LET l_navigation_forward = get_is_screen_navigation_forward()

			IF get_debug() THEN 
				CALL debug_info_invoice_line_input_array("#AFTER FIELD line_text",NULL,l_rec_curr_row_invoicedetl.line_num,l_arr_rec_invoicedetl_list[l_idx].line_num, l_idx,l_rec_curr_row_invoicedetl.*,l_rec_curr_row_invoicedetl_original.*,l_arr_rec_invoicedetl_list[l_idx].*)
			END IF

			IF (l_idx > 0) AND NOT compare_pos_null_str(l_rec_curr_row_invoicedetl_original.line_text, l_arr_rec_invoicedetl_list[l_idx].line_text) THEN #only if data array or l_idx is not 0 
				#warehouse disabled and empty part code is not possible
				IF (l_arr_rec_invoicedetl_list[l_idx].ware_code IS NULL) AND (l_arr_rec_invoicedetl_list[l_idx].line_text IS NULL) THEN
					ERROR "Warehouse disabled - Enable the Warehouse to enter warehouse product items OR enter line desription"
					NEXT FIELD ware_code 
				END IF
				LET l_rec_curr_row_invoicedetl.line_text = l_arr_rec_invoicedetl_list[l_idx].line_text

				CASE
					#empty and navigation back/up
					WHEN (l_arr_rec_invoicedetl_list[l_idx].line_text IS NULL) AND (l_navigation_forward = FALSE)
						CALL fgl_winmessage("error 1433","should never happen","error")
					WHEN (l_navigation_forward = TRUE)
						IF l_line_text IS NULL OR l_rec_curr_row_invoicedetl.line_text != l_line_text THEN #what is l_line_text and l_part_code used for ? 
							IF l_rec_curr_row_invoicedetl.line_text IS NOT NULL THEN
								LET l_rec_curr_row_invoicedetl.part_code = NULL 
								LET l_line_text = l_rec_curr_row_invoicedetl.line_text 
								LET l_rec_curr_row_invoicedetl.unit_sale_amt = NULL 
								 
							END IF 
						END IF 

						#Validate Field(s) and update temp invoice line
						CALL validate_field_and_update_temp_line("line_text",l_rec_curr_row_invoicedetl.*) RETURNING l_valid_ind,l_ret_next_field,l_rec_curr_row_invoicedetl.*
						CALL invoicedetl_morph_rec_to_list_line(l_rec_curr_row_invoicedetl.*) RETURNING l_arr_rec_invoicedetl_list[l_idx].* 
						CALL disp_total(l_rec_curr_row_invoicedetl.*) 

--						CASE 
--							--WHEN NOT(l_valid_ind) 
--							--	NEXT FIELD part_code 
--		
-- --							WHEN l_lastkey=fgl_keyval("accept") 
--		
--							WHEN l_navigation_forward = TRUE #if part_code is empty and user navigates FORWARD .- show part/product window 
--								IF l_arr_rec_invoicedetl_list[l_idx].line_text IS NULL THEN 
--									IF get_debug() THEN					
--										DISPLAY "..............................."
--										DISPLAY "l_rec_curr_row_invoicedetl.line_num=", l_rec_curr_row_invoicedetl.line_num
--										DISPLAY "l_arr_rec_invoicedetl_list[l_idx].line_num=", l_arr_rec_invoicedetl_list[l_idx].line_num
--										DISPLAY "l_idx=", l_idx
--										DISPLAY "..............................."
--										CALL debug_show_keys("AFTER FIELD part_code")
--									END IF
--		
-- --										IF invoice_line_entry_dialog(l_rec_curr_row_invoicedetl.*) THEN 
-- --											CALL db_st_invoicedetl_get_row_by_line_num(l_arr_rec_invoicedetl_list[l_idx].line_num) RETURNING l_arr_rec_invoicedetl_list[l_idx].*,l_rec_curr_row_invoicedetl.* 
-- --			
-- --											IF get_debug() THEN					
-- --												DISPLAY "..............................."
-- --												DISPLAY "l_rec_curr_row_invoicedetl.line_num=", l_rec_curr_row_invoicedetl.line_num
-- --												DISPLAY "l_arr_rec_invoicedetl_list[l_idx].line_num=", l_arr_rec_invoicedetl_list[l_idx].line_num
-- --												DISPLAY "l_idx=", l_idx
-- --												DISPLAY "..............................."
-- --												CALL debug_show_keys("AFTER FIELD part_code")
-- --											END IF
-- --										ELSE 
--										ERROR "Line Item Description can not be empty"--	NEXT FIELD part_code 
--									--END IF 
--								ELSE 
-- 
-- --									SELECT * INTO l_rec_product.* 
-- --									FROM product 
-- --									WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
-- --									AND part_code = l_arr_rec_invoicedetl_list[l_idx].part_code 
-- --									NEXT FIELD NEXT 
--							END IF 
--
--						END CASE 
				END CASE

			END IF
			CALL invoicedetl_enable_disable_fields(l_rec_curr_row_invoicedetl.*)


		#########################################################################################################
		# LINE_ACCT_CODE (GL-Account) --------------------------------------------------------------------------------
		# warehouse=read only - retrieved from product
		# none-warehouse - Either enter sales account code OR leave empty in case of line comment
		#########################################################################################################
		BEFORE FIELD line_acct_code
			IF get_debug() THEN 
				CALL debug_info_invoice_line_input_array("#BEFORE FIELD line_acct_code",NULL,l_rec_curr_row_invoicedetl.line_num,l_arr_rec_invoicedetl_list[l_idx].line_num, l_idx,l_rec_curr_row_invoicedetl.*,l_rec_curr_row_invoicedetl_original.*,l_arr_rec_invoicedetl_list[l_idx].*)
			END IF

			--IF l_rec_curr_row_invoicedetl.ware_code IS NOT NULL THEN #enabled warehouse - GL-Sales-Account is set by warehouse 
			--	NEXT FIELD tax_code
			--END IF
			#nothing 

		ON CHANGE line_acct_code
			IF get_debug() THEN 
				CALL debug_info_invoice_line_input_array("#ON CHANGE line_acct_code",NULL,l_rec_curr_row_invoicedetl.line_num,l_arr_rec_invoicedetl_list[l_idx].line_num, l_idx,l_rec_curr_row_invoicedetl.*,l_rec_curr_row_invoicedetl_original.*,l_arr_rec_invoicedetl_list[l_idx].*)
			END IF

				LET l_rec_curr_row_invoicedetl.line_acct_code = l_arr_rec_invoicedetl_list[l_idx].line_acct_code 
				#Validate Field(s) and update temp invoice line
				CALL validate_field_and_update_temp_line("line_acct_code",l_rec_curr_row_invoicedetl.*) RETURNING l_valid_ind,l_ret_next_field,l_rec_curr_row_invoicedetl.* 
				CALL invoicedetl_morph_rec_to_list_line(l_rec_curr_row_invoicedetl.*) RETURNING l_arr_rec_invoicedetl_list[l_idx].*
 
		AFTER FIELD line_acct_code #GL account code
			IF get_debug() THEN 
				CALL debug_info_invoice_line_input_array("#AFTER FIELD line_acct_code",NULL,l_rec_curr_row_invoicedetl.line_num,l_arr_rec_invoicedetl_list[l_idx].line_num, l_idx,l_rec_curr_row_invoicedetl.*,l_rec_curr_row_invoicedetl_original.*,l_arr_rec_invoicedetl_list[l_idx].*)
			END IF

			IF (l_idx > 0) AND NOT compare_pos_null_str(l_rec_curr_row_invoicedetl_original.line_acct_code, l_arr_rec_invoicedetl_list[l_idx].line_acct_code) THEN #only if data array or l_idx is not 0		
				LET l_rec_curr_row_invoicedetl.line_acct_code = l_arr_rec_invoicedetl_list[l_idx].line_acct_code  

				#Validate Field(s) and update temp invoice line
				CALL validate_field_and_update_temp_line("line_acct_code",l_rec_curr_row_invoicedetl.*) RETURNING l_valid_ind,l_ret_next_field,l_rec_curr_row_invoicedetl.* 
				CALL invoicedetl_morph_rec_to_list_line(l_rec_curr_row_invoicedetl.*) RETURNING l_arr_rec_invoicedetl_list[l_idx].*

				IF l_valid_ind = FALSE THEN 
						ERROR "Invalid GL-Sales-Account Code"
						NEXT FIELD line_acct_code 
				END IF

				CALL disp_total(l_rec_curr_row_invoicedetl.*) 
				#No Warehouse
				IF l_rec_curr_row_invoicedetl.ware_code IS NULL AND l_rec_curr_row_invoicedetl.line_acct_code IS NULL THEN
					LET l_rec_curr_row_invoicedetl.tax_code = NULL
					CALL validate_field_and_update_temp_line("line_acct_code",l_rec_curr_row_invoicedetl.*) RETURNING l_valid_ind,l_ret_next_field,l_rec_curr_row_invoicedetl.* 
					CALL invoicedetl_morph_rec_to_list_line(l_rec_curr_row_invoicedetl.*) RETURNING l_arr_rec_invoicedetl_list[l_idx].*
					NEXT FIELD ship_qty
				END IF
			END IF

			#IF NO GL account is used -> this is a comment line ->set tax code and amount to ZERO
			IF l_rec_curr_row_invoicedetl.line_acct_code IS NULL THEN
				LET l_rec_curr_row_invoicedetl.tax_code = NULL
				LET l_rec_curr_row_invoicedetl.unit_sale_amt = 0
				LET l_rec_curr_row_invoicedetl.disc_amt = 0
				LET l_rec_curr_row_invoicedetl.unit_tax_amt = 0
				LET l_rec_curr_row_invoicedetl.ext_sale_amt = 0 
				LET l_rec_curr_row_invoicedetl.ext_tax_amt = 0
				LET l_rec_curr_row_invoicedetl.line_total_amt = 0
					CALL validate_field_and_update_temp_line("line_acct_code",l_rec_curr_row_invoicedetl.*) RETURNING l_valid_ind,l_ret_next_field,l_rec_curr_row_invoicedetl.* 
					CALL invoicedetl_morph_rec_to_list_line(l_rec_curr_row_invoicedetl.*) RETURNING l_arr_rec_invoicedetl_list[l_idx].*
					--NEXT FIELD line_total_amt
			END IF
			CALL invoicedetl_enable_disable_fields(l_rec_curr_row_invoicedetl.*)

		#########################################################################################################
		# TAX_CODE --------------------------------------------------------------------------------
		# warehouse items work only with tax code - (Feature Request Ali) free items can enter tax_code or tax_unit_amt
		#########################################################################################################
		BEFORE FIELD tax_code
			IF get_debug() THEN 
				CALL debug_info_invoice_line_input_array("#BEFORE FIELD tax_code",NULL,l_rec_curr_row_invoicedetl.line_num,l_arr_rec_invoicedetl_list[l_idx].line_num, l_idx,l_rec_curr_row_invoicedetl.*,l_rec_curr_row_invoicedetl_original.*,l_arr_rec_invoicedetl_list[l_idx].*)
			END IF

			#nothing 

		ON CHANGE tax_code 
			IF get_debug() THEN 
				CALL debug_info_invoice_line_input_array("#ON CHANGE tax_code",NULL,l_rec_curr_row_invoicedetl.line_num,l_arr_rec_invoicedetl_list[l_idx].line_num, l_idx,l_rec_curr_row_invoicedetl.*,l_rec_curr_row_invoicedetl_original.*,l_arr_rec_invoicedetl_list[l_idx].*)
			END IF
		
				LET l_rec_curr_row_invoicedetl.tax_code = l_arr_rec_invoicedetl_list[l_idx].tax_code 

				#Validate Field(s) and update temp invoice line
				CALL validate_field_and_update_temp_line("tax_code",l_rec_curr_row_invoicedetl.*) RETURNING l_valid_ind,l_ret_next_field,l_rec_curr_row_invoicedetl.* 
				CALL invoicedetl_morph_rec_to_list_line(l_rec_curr_row_invoicedetl.*) RETURNING l_arr_rec_invoicedetl_list[l_idx].*
				CALL disp_total(l_rec_curr_row_invoicedetl.*) 

		AFTER FIELD tax_code 
			IF get_debug() THEN 
				CALL debug_info_invoice_line_input_array("#AFTER FIELD tax_code ",NULL,l_rec_curr_row_invoicedetl.line_num,l_arr_rec_invoicedetl_list[l_idx].line_num, l_idx,l_rec_curr_row_invoicedetl.*,l_rec_curr_row_invoicedetl_original.*,l_arr_rec_invoicedetl_list[l_idx].*)
			END IF

			IF (l_idx > 0) AND NOT compare_pos_null_str(l_rec_curr_row_invoicedetl_original.tax_code, l_arr_rec_invoicedetl_list[l_idx].tax_code) THEN #only if data array or l_idx is not 0		

				LET l_rec_curr_row_invoicedetl.tax_code = l_arr_rec_invoicedetl_list[l_idx].tax_code 

				#Validate Field(s) and update temp invoice line
				CALL validate_field_and_update_temp_line("tax_code",l_rec_curr_row_invoicedetl.*) RETURNING l_valid_ind,l_ret_next_field,l_rec_curr_row_invoicedetl.* 
				CALL invoicedetl_morph_rec_to_list_line(l_rec_curr_row_invoicedetl.*) RETURNING l_arr_rec_invoicedetl_list[l_idx].*
				CALL disp_total(l_rec_curr_row_invoicedetl.*) 

				IF l_valid_ind = FALSE THEN 
						ERROR "Invalid Tax Code"
						NEXT FIELD tax_code 
				ELSE
					CALL invoicedetl_enable_disable_fields(l_rec_curr_row_invoicedetl.*)
					IF l_rec_curr_row_invoicedetl.tax_code IS NULL THEN #none warehouse item - and no tax code choosen - free tax amount entry
						NEXT FIELD unit_tax_amt
					ELSE
						#Condition Tax Calc Method
						CASE db_tax_get_calc_method_flag(UI_OFF,l_rec_curr_row_invoicedetl.tax_code)
							WHEN "D" #Method "D" The amount of sales tax is dictated by the (Dollar) tax amount associated with the Product.
								NEXT FIELD unit_tax_amt
							OTHERWISE
								NEXT FIELD ship_qty  #ext_sale_amt #Line Amt excl. VAT
						END CASE	
					END IF
				END IF
			END IF
			CALL invoicedetl_enable_disable_fields(l_rec_curr_row_invoicedetl.*)




		#########################################################################################################
		# TAX_PER (READ BONLY & is always retrieved from DB tax_code) --------------------------------------------------------------------------------
		#########################################################################################################
		BEFORE FIELD tax_per
			IF get_debug() THEN 
				CALL debug_info_invoice_line_input_array("#BEFORE FIELD tax_per",NULL,l_rec_curr_row_invoicedetl.line_num,l_arr_rec_invoicedetl_list[l_idx].line_num, l_idx,l_rec_curr_row_invoicedetl.*,l_rec_curr_row_invoicedetl_original.*,l_arr_rec_invoicedetl_list[l_idx].*)
			END IF
			#nothing 

		ON CHANGE tax_per
			IF get_debug() THEN 
				CALL debug_info_invoice_line_input_array("#ON CHANGE tax_per",NULL,l_rec_curr_row_invoicedetl.line_num,l_arr_rec_invoicedetl_list[l_idx].line_num, l_idx,l_rec_curr_row_invoicedetl.*,l_rec_curr_row_invoicedetl_original.*,l_arr_rec_invoicedetl_list[l_idx].*)
			END IF
			#nothing 

		AFTER FIELD tax_per
			IF get_debug() THEN 
				CALL debug_info_invoice_line_input_array("#AFTER FIELD tax_per",NULL,l_rec_curr_row_invoicedetl.line_num,l_arr_rec_invoicedetl_list[l_idx].line_num, l_idx,l_rec_curr_row_invoicedetl.*,l_rec_curr_row_invoicedetl_original.*,l_arr_rec_invoicedetl_list[l_idx].*)
			END IF
			#nothing 

		#########################################################################################################
		# SHIP_QTY 
		# Warehouse products need value > 0
		# None-Warehouse products/services ->Value 0 makes invoice line a COMMENT invoice line) --------------------------------------------------------------------------------
		#########################################################################################################
		BEFORE FIELD ship_qty 
			IF get_debug() THEN 
				CALL debug_info_invoice_line_input_array("#BEFORE FIELD ship_qty",NULL,l_rec_curr_row_invoicedetl.line_num,l_arr_rec_invoicedetl_list[l_idx].line_num, l_idx,l_rec_curr_row_invoicedetl.*,l_rec_curr_row_invoicedetl_original.*,l_arr_rec_invoicedetl_list[l_idx].*)
			END IF

			IF l_rec_product.serial_flag = 'Y' THEN 
				# we need TO manually count records because a RETURN may
				# have been done of one of the serial items.
				LET l_tab_cnt = serial_count(l_arr_rec_invoicedetl_list[l_idx].part_code,l_rec_curr_row_invoicedetl.ware_code) 
				IF l_tab_cnt > l_arr_rec_invoicedetl_list[l_idx].ship_qty THEN 
					IF l_arr_rec_invoicedetl_list[l_idx].ship_qty = 0 THEN 
						ERROR kandoomsg2("I",9278,'') #9278 Product / Warehouse combination can only occur 1
						LET l_arr_rec_invoicedetl_list[l_idx].part_code = NULL 
						LET l_rec_curr_row_invoicedetl.part_code = NULL 
						LET l_rec_curr_row_invoicedetl.line_text = NULL 
						CALL disp_total(l_rec_curr_row_invoicedetl.*) 
						NEXT FIELD part_code 
					ELSE 
						CALL fgl_winmessage("#9279 Error",kandoomsg2("I",9279,''),"ERROR") #9279 Error - INPUT Quantity NOT equal OUTPUT Quantity
						LET l_errmsg = "A21b - Qty supplied NOT= table qty ", l_arr_rec_invoicedetl_list[l_idx].ship_qty , " <> ", l_tab_cnt 
						CALL errorlog(l_errmsg) 
						LET status = -2 
						EXIT PROGRAM 
					END IF 
				END IF 

				LET l_cnt = serial_input(l_arr_rec_invoicedetl_list[l_idx].part_code, l_rec_curr_row_invoicedetl.ware_code,	l_tab_cnt ) 

				OPTIONS INSERT KEY f1, 
				DELETE KEY f36

				IF l_cnt < 0 THEN 
					IF l_cnt = -1 THEN 
						LET l_rec_curr_row_invoicedetl.part_code = NULL
						CALL invoicedetl_morph_rec_to_list_line(l_rec_curr_row_invoicedetl.*) RETURNING l_arr_rec_invoicedetl_list[l_idx].* 
						NEXT FIELD scroll_flag 
					ELSE 
						CALL errorlog("A21b - Fatal error in serial_input ") 
						EXIT PROGRAM 
					END IF 
				ELSE 
					LET l_rec_curr_row_invoicedetl.ship_qty	= l_arr_rec_invoicedetl_list[l_idx].ship_qty + l_cnt - l_tab_cnt 
					#Validate Field(s) and update temp invoice line						 
					CALL validate_field_and_update_temp_line("ship_qty",l_rec_curr_row_invoicedetl.*)  RETURNING l_valid_ind,l_ret_next_field,l_rec_curr_row_invoicedetl.*
					CALL invoicedetl_morph_rec_to_list_line(l_rec_curr_row_invoicedetl.*) RETURNING l_arr_rec_invoicedetl_list[l_idx].*					 

					CASE 
						WHEN NOT(l_valid_ind) 
							NEXT FIELD ship_qty 
					END CASE 
				END IF 
			END IF 

		#----------------
		ON CHANGE ship_qty
			IF get_debug() THEN 
				CALL debug_info_invoice_line_input_array("#ON CHANGE ship_qty",NULL,l_rec_curr_row_invoicedetl.line_num,l_arr_rec_invoicedetl_list[l_idx].line_num, l_idx,l_rec_curr_row_invoicedetl.*,l_rec_curr_row_invoicedetl_original.*,l_arr_rec_invoicedetl_list[l_idx].*)
			END IF

			#Warehouse items must have a quantity 1 or more
			IF (l_arr_rec_invoicedetl_list[l_idx].ware_code IS NOT NULL) AND (l_arr_rec_invoicedetl_list[l_idx].ship_qty < 1) THEN
				ERROR "Warehouse products require a quantity of 1 or more"
				NEXT FIELD ship_qty
			END IF

			#No item warehouse/free/comment can have a negative quantity
			IF l_arr_rec_invoicedetl_list[l_idx].ship_qty < 0 THEN #check for negative quantity
				ERROR "You can not specify negative quantities"
				NEXT FIELD ship_qty
			END IF

			#only valid for comment - GL account must be NULL
			IF (l_arr_rec_invoicedetl_list[l_idx].ware_code IS NULL) AND l_arr_rec_invoicedetl_list[l_idx].ship_qty = 0 THEN 
				IF l_rec_curr_row_invoicedetl.line_acct_code IS NOT NULL THEN
					ERROR "Quantiy 0 indicates invoice line comment. You need to remove the GL-Sales-Account for this line"
					NEXT FIELD line_acct_code
				END IF
			END IF

		AFTER FIELD ship_qty 
			IF get_debug() THEN 
				CALL debug_info_invoice_line_input_array("#AFTER FIELD ship_qty *1",NULL,l_rec_curr_row_invoicedetl.line_num,l_arr_rec_invoicedetl_list[l_idx].line_num, l_idx,l_rec_curr_row_invoicedetl.*,l_rec_curr_row_invoicedetl_original.*,l_arr_rec_invoicedetl_list[l_idx].*)
			END IF

			#Warehouse items must have a quantity 1 or more
			# IF settings do not permit 0
			IF get_kandoooption_feature_state("AR","IQ") = "N" THEN 
				IF (l_arr_rec_invoicedetl_list[l_idx].ware_code IS NOT NULL) AND (l_arr_rec_invoicedetl_list[l_idx].ship_qty < 1) THEN
					ERROR "Warehouse products require a quantity of 1 or more"
					NEXT FIELD ship_qty
				END IF
			END IF
			#If the array list quantity is different to the current row record quantity update/sync values
			IF (l_idx > 0) AND (l_rec_curr_row_invoicedetl.ship_qty != l_arr_rec_invoicedetl_list[l_idx].ship_qty) THEN #only if data array or l_idx is not 0		

				LET l_rec_curr_row_invoicedetl.ship_qty = l_arr_rec_invoicedetl_list[l_idx].ship_qty 

				#User can enter invoice comment lines - these have 0 quantity and GL-Account IS NULL
				IF l_arr_rec_invoicedetl_list[l_idx].ship_qty = 0 THEN #this is an invoice comment line
					LET l_rec_curr_row_invoicedetl.line_acct_code = NULL #must not have amount or
					LET l_rec_curr_row_invoicedetl.unit_sale_amt = 0
					LET l_rec_curr_row_invoicedetl.line_total_amt = 0
					LET l_rec_curr_row_invoicedetl.tax_code = NULL
					LET l_rec_curr_row_invoicedetl.disc_amt = 0
					LET l_rec_curr_row_invoicedetl.line_total_amt = 0
				END IF

				#Validate Field(s) and update temp invoice line
				CALL validate_field_and_update_temp_line("ship_qty",l_rec_curr_row_invoicedetl.*) RETURNING l_valid_ind,l_ret_next_field,l_rec_curr_row_invoicedetl.* 
				CALL invoicedetl_morph_rec_to_list_line(l_rec_curr_row_invoicedetl.*) RETURNING l_arr_rec_invoicedetl_list[l_idx].*
				CALL disp_total(l_rec_curr_row_invoicedetl.*)

				IF get_debug() THEN 
					CALL debug_info_invoice_line_input_array("#AFTER FIELD ship_qty *1",NULL,l_rec_curr_row_invoicedetl.line_num,l_arr_rec_invoicedetl_list[l_idx].line_num, l_idx,l_rec_curr_row_invoicedetl.*,l_rec_curr_row_invoicedetl_original.*,l_arr_rec_invoicedetl_list[l_idx].*)
				END IF

	
--				display l_valid_ind
	
# We no longer use this setting - we have enough space to show both columns permanently
--			IF glob_rec_arparms.show_tax_flag = "N" THEN 
--				LET l_arr_rec_invoicedetl_list[l_idx].line_total_amt = l_rec_curr_row_invoicedetl.ext_sale_amt 
--			ELSE 
--				LET l_arr_rec_invoicedetl_list[l_idx].line_total_amt = l_rec_curr_row_invoicedetl.line_total_amt 
--			END IF 
	
				CASE 
					WHEN NOT(l_valid_ind)
						ERROR "Invalid shipping quantity" 
						NEXT FIELD ship_qty 
				END CASE 
			END IF

			IF get_debug() THEN 
				CALL debug_info_invoice_line_input_array("#AFTER FIELD ship_qty ","****END of AFTER Field****",l_rec_curr_row_invoicedetl.line_num,l_arr_rec_invoicedetl_list[l_idx].line_num, l_idx,l_rec_curr_row_invoicedetl.*,l_rec_curr_row_invoicedetl_original.*,l_arr_rec_invoicedetl_list[l_idx].*)
			END IF


		#########################################################################################################
		# UNIT_SALE_AMT Editable for warehouse and none warehouse products --------------------------------------------------------------------------------
		# Warehouse products suggest amount from warehouse product, but this can be modified
		#########################################################################################################

		ON ACTION "net_amount" infield(unit_sale_amt)
			IF get_debug() THEN 
				CALL debug_info_invoice_line_input_array("#ON ACTION net_amount",NULL,l_rec_curr_row_invoicedetl.line_num,l_arr_rec_invoicedetl_list[l_idx].line_num, l_idx,l_rec_curr_row_invoicedetl.*,l_rec_curr_row_invoicedetl_original.*,l_arr_rec_invoicedetl_list[l_idx].*)
			END IF
			LET l_arr_rec_invoicedetl_list[l_idx].unit_sale_amt = l_arr_rec_invoicedetl_list[l_idx].unit_sale_amt / (100 + l_arr_rec_invoicedetl_list[l_idx].tax_per) *100

		BEFORE FIELD unit_sale_amt
			IF get_debug() THEN 
				CALL debug_info_invoice_line_input_array("#BEFORE FIELD unit_sale_amt",NULL,l_rec_curr_row_invoicedetl.line_num,l_arr_rec_invoicedetl_list[l_idx].line_num, l_idx,l_rec_curr_row_invoicedetl.*,l_rec_curr_row_invoicedetl_original.*,l_arr_rec_invoicedetl_list[l_idx].*)
			END IF
			#nothing

		ON CHANGE unit_sale_amt
			IF get_debug() THEN 
				CALL debug_info_invoice_line_input_array("#ON CHANGE unit_sale_amt",NULL,l_rec_curr_row_invoicedetl.line_num,l_arr_rec_invoicedetl_list[l_idx].line_num, l_idx,l_rec_curr_row_invoicedetl.*,l_rec_curr_row_invoicedetl_original.*,l_arr_rec_invoicedetl_list[l_idx].*)
			END IF
			LET l_rec_curr_row_invoicedetl.unit_sale_amt = l_arr_rec_invoicedetl_list[l_idx].unit_sale_amt 

		AFTER FIELD unit_sale_amt 
			IF get_debug() THEN 
				CALL debug_info_invoice_line_input_array("#AFTER FIELD unit_sale_am",NULL,l_rec_curr_row_invoicedetl.line_num,l_arr_rec_invoicedetl_list[l_idx].line_num, l_idx,l_rec_curr_row_invoicedetl.*,l_rec_curr_row_invoicedetl_original.*,l_arr_rec_invoicedetl_list[l_idx].*)
			END IF

			#IF unit_sale_amt has changed
--			IF (l_idx > 0) AND (l_rec_curr_row_invoicedetl.unit_sale_amt != l_arr_rec_invoicedetl_list[l_idx].unit_sale_amt) THEN #only if data array or l_idx is not 0		and amount has changed with 
--				IF get_debug() THEN
--					DISPLAY "Value has changed from ", trim(l_rec_curr_row_invoicedetl_original.unit_sale_amt), " TO ", trim(l_arr_rec_invoicedetl_list[l_idx].unit_sale_amt)
--				END IF
				#Update changed unit_sale_amt in current row record
				LET l_rec_curr_row_invoicedetl.unit_sale_amt = l_arr_rec_invoicedetl_list[l_idx].unit_sale_amt 
	
				#Validate Field(s) and update temp invoice line
				CALL validate_field_and_update_temp_line("unit_sale_amt",l_rec_curr_row_invoicedetl.*) RETURNING l_valid_ind,l_ret_next_field,l_rec_curr_row_invoicedetl.* 
				CALL invoicedetl_morph_rec_to_list_line(l_rec_curr_row_invoicedetl.*) RETURNING l_arr_rec_invoicedetl_list[l_idx].*
				CALL disp_total(l_rec_curr_row_invoicedetl.*) 
	
				IF l_valid_ind = FALSE THEN
					ERROR "Invalid unit price"
					NEXT FIELD unit_sale_amt
				ELSE #for later, when we know more about tax handling rules				
--				CASE db_tax_get_calc_method_flag(UI_OFF,l_rec_curr_row_invoicedetl.tax_code)
--						 WHEN "P" #Method "P" The amount of sales tax is dictated by the tax Percentage associated with the Product.
--						 	NEXT FIELD line_total						 
--						 WHEN "T" #Method "T" The amount of sales tax is a flat percentage of the Transaction Total (ie. invoice or voucher) based on the Customer’s (or Vendor’s) tax rate.
--						 	NEXT FIELD line_total
--						 WHEN "N" #Method "P"” The amount of sales tax is dictated by the tax Percentage associated with the Product.
--						 	NEXT FIELD line_total						 
--					 OTHERWISE
--						 	NEXT FIELD line_total_amt @huho: commented on 10.03.2021 due to input issue: user enters item price, presses any nav key and line get's removed
--				END CASE
				END IF 
--			END IF
--			BEFORE FIELD line_total_amt 
--				SELECT * INTO l_rec_curr_row_invoicedetl.* 
--				FROM t_invoicedetl 
--				WHERE line_num = l_rec_curr_row_invoicedetl.line_num 
--
--				LET l_arr_rec_invoicedetl_list[l_idx].part_code = l_rec_curr_row_invoicedetl.part_code 
--				LET l_arr_rec_invoicedetl_list[l_idx].line_text = l_rec_curr_row_invoicedetl.line_text 
--				LET l_arr_rec_invoicedetl_list[l_idx].ship_qty = l_rec_curr_row_invoicedetl.ship_qty 
--				LET l_arr_rec_invoicedetl_list[l_idx].unit_sale_amt = l_rec_curr_row_invoicedetl.unit_sale_amt 
--				LET l_arr_rec_invoicedetl_list[l_idx].line_total_amt=l_rec_curr_row_invoicedetl.line_total_amt 
--				IF glob_rec_arparms.show_tax_flag = "N" THEN 
--					LET l_arr_rec_invoicedetl_list[l_idx].line_total_amt = 
--					l_rec_curr_row_invoicedetl.ext_sale_amt 
--				ELSE 
--					LET l_arr_rec_invoicedetl_list[l_idx].line_total_amt = 
--					l_rec_curr_row_invoicedetl.line_total_amt 
--				END IF 
--
--				CALL disp_total(l_rec_curr_row_invoicedetl.*) 
--				IF l_lastkey = fgl_keyval("interrupt") 
--				OR l_lastkey = fgl_keyval("accept") THEN 
--					## IF line entry NOT complete THEN RETURN TO scroll flag
--					NEXT FIELD scroll_flag 
--				END IF 

		#########################################################################################################
		# DISC_AMT  -------------------------------------------------------------------------------- 
		#(I have not dealt with discounts yet... no idea where this comes from and how it should be used)
		#########################################################################################################
		BEFORE FIELD disc_amt
			IF get_debug() THEN 
				CALL debug_info_invoice_line_input_array("#BEFORE FIELD disc_amt",NULL,l_rec_curr_row_invoicedetl.line_num,l_arr_rec_invoicedetl_list[l_idx].line_num, l_idx,l_rec_curr_row_invoicedetl.*,l_rec_curr_row_invoicedetl_original.*,l_arr_rec_invoicedetl_list[l_idx].*)
			END IF
			#nothing

		ON CHANGE disc_amt
			IF get_debug() THEN 
				CALL debug_info_invoice_line_input_array("#ON CHANGE disc_amt",NULL,l_rec_curr_row_invoicedetl.line_num,l_arr_rec_invoicedetl_list[l_idx].line_num, l_idx,l_rec_curr_row_invoicedetl.*,l_rec_curr_row_invoicedetl_original.*,l_arr_rec_invoicedetl_list[l_idx].*)
			END IF
			#nothing

		AFTER FIELD disc_amt
			IF get_debug() THEN 
				CALL debug_info_invoice_line_input_array("#AFTER FIELD disc_amt",NULL,l_rec_curr_row_invoicedetl.line_num,l_arr_rec_invoicedetl_list[l_idx].line_num, l_idx,l_rec_curr_row_invoicedetl.*,l_rec_curr_row_invoicedetl_original.*,l_arr_rec_invoicedetl_list[l_idx].*)
			END IF

			IF (l_idx > 0) AND (l_rec_curr_row_invoicedetl_original.disc_amt != l_arr_rec_invoicedetl_list[l_idx].disc_amt) THEN #only if data array or l_idx is not 0		
				#Nothing yet
			END IF		 

		#########################################################################################################
		# UNIT_TAX_AMT --------------------------------------------------------------------------------
		# None-Warehouse products can specify tax via tax_code OR unit_tax_amount
		#########################################################################################################
		BEFORE FIELD unit_tax_amt
			IF get_debug() THEN 
				CALL debug_info_invoice_line_input_array("#BEFORE FIELD unit_tax_amt",NULL,l_rec_curr_row_invoicedetl.line_num,l_arr_rec_invoicedetl_list[l_idx].line_num, l_idx,l_rec_curr_row_invoicedetl.*,l_rec_curr_row_invoicedetl_original.*,l_arr_rec_invoicedetl_list[l_idx].*)
			END IF
			#Nothing

		ON CHANGE unit_tax_amt
			IF get_debug() THEN 
				CALL debug_info_invoice_line_input_array("#ON CHANGE unit_tax_amt",NULL,l_rec_curr_row_invoicedetl.line_num,l_arr_rec_invoicedetl_list[l_idx].line_num, l_idx,l_rec_curr_row_invoicedetl.*,l_rec_curr_row_invoicedetl_original.*,l_arr_rec_invoicedetl_list[l_idx].*)
			END IF
			#Nothing
		
		AFTER FIELD unit_tax_amt 
			IF get_debug() THEN 
				CALL debug_info_invoice_line_input_array("#AFTER FIELD unit_tax_amt ",NULL,l_rec_curr_row_invoicedetl.line_num,l_arr_rec_invoicedetl_list[l_idx].line_num, l_idx,l_rec_curr_row_invoicedetl.*,l_rec_curr_row_invoicedetl_original.*,l_arr_rec_invoicedetl_list[l_idx].*)
			END IF

			IF (l_idx > 0) AND (l_rec_curr_row_invoicedetl_original.unit_tax_amt != l_arr_rec_invoicedetl_list[l_idx].unit_tax_amt) THEN #only if data array or l_idx is not 0		

				LET l_rec_curr_row_invoicedetl.unit_tax_amt = l_arr_rec_invoicedetl_list[l_idx].unit_tax_amt 
	
				#Validate Field(s) and update temp invoice line
				CALL validate_field_and_update_temp_line("unit_tax_amt",l_rec_curr_row_invoicedetl.*) RETURNING l_valid_ind,l_ret_next_field,l_rec_curr_row_invoicedetl.* 
				CALL invoicedetl_morph_rec_to_list_line(l_rec_curr_row_invoicedetl.*) RETURNING l_arr_rec_invoicedetl_list[l_idx].*
				CALL disp_total(l_rec_curr_row_invoicedetl.*) 
	
				CASE 
					WHEN NOT(l_valid_ind) 
						ERROR "Invalid Tax Amount"
						NEXT FIELD unit_tax_amt 
				END CASE 
	
				--IF l_valid_ind THEN
				--	CALL invoicedetl_enable_disable_fields(l_rec_curr_row_invoicedetl.*)
				--END IF
			END IF
			
		#########################################################################################################
		# EXT_SALE_AMT --------------------------------------------------------------------------------
		# Read Only
		#########################################################################################################
		BEFORE FIELD ext_sale_amt
			IF get_debug() THEN 
				CALL debug_info_invoice_line_input_array("#BEFORE FIELD ext_sale_amt",NULL,l_rec_curr_row_invoicedetl.line_num,l_arr_rec_invoicedetl_list[l_idx].line_num, l_idx,l_rec_curr_row_invoicedetl.*,l_rec_curr_row_invoicedetl_original.*,l_arr_rec_invoicedetl_list[l_idx].*)
			END IF
			#nothing

		ON CHANGE ext_sale_amt
			IF get_debug() THEN 
				CALL debug_info_invoice_line_input_array("#ON CHANGE ext_sale_amt",NULL,l_rec_curr_row_invoicedetl.line_num,l_arr_rec_invoicedetl_list[l_idx].line_num, l_idx,l_rec_curr_row_invoicedetl.*,l_rec_curr_row_invoicedetl_original.*,l_arr_rec_invoicedetl_list[l_idx].*)
			END IF
			#nothing

		AFTER FIELD ext_sale_amt
			IF get_debug() THEN 
				CALL debug_info_invoice_line_input_array("#AFTER FIELD ext_sale_amt",NULL,l_rec_curr_row_invoicedetl.line_num,l_arr_rec_invoicedetl_list[l_idx].line_num, l_idx,l_rec_curr_row_invoicedetl.*,l_rec_curr_row_invoicedetl_original.*,l_arr_rec_invoicedetl_list[l_idx].*)
			END IF
			IF (l_idx > 0) AND (l_rec_curr_row_invoicedetl_original.ext_sale_amt != l_arr_rec_invoicedetl_list[l_idx].ext_sale_amt) THEN #only if data array or l_idx is not 0		
				#nothing
			END IF

		#########################################################################################################
		# EXT_TAX_AMT --------------------------------------------------------------------------------
		# Read Only
		#########################################################################################################
		BEFORE FIELD ext_tax_amt
			IF get_debug() THEN 
				CALL debug_info_invoice_line_input_array("#BEFORE FIELD ext_tax_amt",NULL,l_rec_curr_row_invoicedetl.line_num,l_arr_rec_invoicedetl_list[l_idx].line_num, l_idx,l_rec_curr_row_invoicedetl.*,l_rec_curr_row_invoicedetl_original.*,l_arr_rec_invoicedetl_list[l_idx].*)
			END IF
			#nothing

		ON CHANGE ext_tax_amt
			IF get_debug() THEN 
				CALL debug_info_invoice_line_input_array("#ON CHANGE ext_tax_amt",NULL,l_rec_curr_row_invoicedetl.line_num,l_arr_rec_invoicedetl_list[l_idx].line_num, l_idx,l_rec_curr_row_invoicedetl.*,l_rec_curr_row_invoicedetl_original.*,l_arr_rec_invoicedetl_list[l_idx].*)
			END IF
			#nothing

		AFTER FIELD ext_tax_amt 
			IF get_debug() THEN 
				CALL debug_info_invoice_line_input_array("#AFTER FIELD ext_tax_amt",NULL,l_rec_curr_row_invoicedetl.line_num,l_arr_rec_invoicedetl_list[l_idx].line_num, l_idx,l_rec_curr_row_invoicedetl.*,l_rec_curr_row_invoicedetl_original.*,l_arr_rec_invoicedetl_list[l_idx].*)
			END IF

			IF (l_idx > 0) AND (l_rec_curr_row_invoicedetl_original.ext_tax_amt != l_arr_rec_invoicedetl_list[l_idx].ext_tax_amt) THEN #only if data array or l_idx is not 0		
				#nothing
			END IF

		#########################################################################################################
		#LINE_TOTAL_AMT --------------------------------------------------------------------------------
		#########################################################################################################
		# Read Only !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
		BEFORE FIELD line_total_amt
			IF get_debug() THEN 
				CALL debug_info_invoice_line_input_array("#BEFORE FIELD line_total_amt",NULL,l_rec_curr_row_invoicedetl.line_num,l_arr_rec_invoicedetl_list[l_idx].line_num, l_idx,l_rec_curr_row_invoicedetl.*,l_rec_curr_row_invoicedetl_original.*,l_arr_rec_invoicedetl_list[l_idx].*)
			END IF

			#Validate Field(s) and update temp invoice line						 
			CALL validate_field_and_update_temp_line("all",l_rec_curr_row_invoicedetl.*)  RETURNING l_valid_ind,l_ret_next_field,l_rec_curr_row_invoicedetl.*
			IF l_valid_ind THEN
				CALL invoicedetl_morph_rec_to_list_line(l_rec_curr_row_invoicedetl.*) RETURNING l_arr_rec_invoicedetl_list[l_idx].*
			ELSE
				CONTINUE INPUT	
			END IF
			

		ON CHANGE line_total_amt
			IF get_debug() THEN 
				CALL debug_info_invoice_line_input_array("#ON CHANGE line_total_amt",NULL,l_rec_curr_row_invoicedetl.line_num,l_arr_rec_invoicedetl_list[l_idx].line_num, l_idx,l_rec_curr_row_invoicedetl.*,l_rec_curr_row_invoicedetl_original.*,l_arr_rec_invoicedetl_list[l_idx].*)
			END IF		
			#nothing

		AFTER FIELD line_total_amt 
			IF get_debug() THEN 
				CALL debug_info_invoice_line_input_array("#AFTER FIELD line_total_amt",NULL,l_rec_curr_row_invoicedetl.line_num,l_arr_rec_invoicedetl_list[l_idx].line_num, l_idx,l_rec_curr_row_invoicedetl.*,l_rec_curr_row_invoicedetl_original.*,l_arr_rec_invoicedetl_list[l_idx].*)
			END IF	
							
			IF (l_idx > 0) AND (l_rec_curr_row_invoicedetl_original.line_total_amt != l_arr_rec_invoicedetl_list[l_idx].line_total_amt) THEN #only if data array or l_idx is not 0
				#nothing yet		
			END IF				
 
		#########################################################################################################
		# AFTER INPUT
		#########################################################################################################
		AFTER INPUT ------------------------------------------------------ 
			IF get_debug() THEN 
				CALL debug_info_invoice_line_input_array("#AFTER INPUT",NULL,l_rec_curr_row_invoicedetl.line_num,l_arr_rec_invoicedetl_list[l_idx].line_num, l_idx,l_rec_curr_row_invoicedetl.*,l_rec_curr_row_invoicedetl_original.*,l_arr_rec_invoicedetl_list[l_idx].*)
			END IF

			#ON CANCEL, we need to re-instate the modified line OR delete the new line
			IF int_flag OR quit_flag THEN #CANCEL
				IF l_arr_rec_invoicedetl_list.getSize() > 0 AND l_idx > 0 THEN #not to be done if array is empty 
					#----------------------------------------
					#CANCEL NEW LINE - We are processing a NEW invoice line
					IF l_rec_curr_row_invoicedetl_original.line_num IS NULL THEN 
					
						CALL db_st_invoicedetl_delete_row(l_arr_rec_invoicedetl_list[l_idx].line_num)
						--CALL l_arr_rec_invoicedetl_list.delete(i)
						--DELETE FROM t_invoicedetl 
						--WHERE line_num = l_arr_rec_invoicedetl_list[l_idx].line_num
						
						 
						FOR l_idx = arr_curr() TO l_arr_rec_invoicedetl_list.getSize() 
							IF l_arr_rec_invoicedetl_list[l_idx+1].line_num IS NOT NULL THEN 
								LET l_arr_rec_invoicedetl_list[l_idx].* = l_arr_rec_invoicedetl_list[l_idx+1].* 
							ELSE 
								INITIALIZE l_arr_rec_invoicedetl_list[l_idx].* TO NULL 
							END IF 
						END FOR
						
					#----------------------------------------
					#CANCEL EDIT LINE - We are processing/EDIT an EXISTING invoice line 
					ELSE 
						IF db_product_get_serial_flag(UI_OFF,l_rec_curr_row_invoicedetl_original.part_code) != "Y" THEN
							LET l_rec_curr_row_invoicedetl_original.ship_qty = l_arr_rec_invoicedetl_list[l_idx].ship_qty 
						END IF 

						#Write invoice line record to DB							
						CALL invoicedetl_update_line(l_rec_curr_row_invoicedetl_original.*)

						LET l_arr_rec_invoicedetl_list[l_idx].line_num =				l_rec_curr_row_invoicedetl_original.line_num
						LET l_arr_rec_invoicedetl_list[l_idx].ware_code =				l_rec_curr_row_invoicedetl_original.ware_code
						LET l_arr_rec_invoicedetl_list[l_idx].part_code =				l_rec_curr_row_invoicedetl_original.part_code
						LET l_arr_rec_invoicedetl_list[l_idx].line_text =				l_rec_curr_row_invoicedetl_original.line_text
						LET l_arr_rec_invoicedetl_list[l_idx].line_acct_code =	l_rec_curr_row_invoicedetl_original.line_acct_code
						LET l_arr_rec_invoicedetl_list[l_idx].tax_code = 				l_rec_curr_row_invoicedetl_original.tax_code
						LET l_arr_rec_invoicedetl_list[l_idx].tax_per = 				db_tax_get_tax_per(UI_OFF,l_rec_curr_row_invoicedetl_original.tax_code) #value is not stored in DB - only tax_code
						LET l_arr_rec_invoicedetl_list[l_idx].ship_qty = 				l_rec_curr_row_invoicedetl_original.ship_qty
						LET l_arr_rec_invoicedetl_list[l_idx].unit_sale_amt = 	l_rec_curr_row_invoicedetl_original.unit_sale_amt
						LET l_arr_rec_invoicedetl_list[l_idx].disc_amt =				l_rec_curr_row_invoicedetl_original.disc_amt
						LET l_arr_rec_invoicedetl_list[l_idx].unit_tax_amt =		l_rec_curr_row_invoicedetl_original.unit_tax_amt
						LET l_arr_rec_invoicedetl_list[l_idx].ext_sale_amt =		l_rec_curr_row_invoicedetl_original.ext_sale_amt
						LET l_arr_rec_invoicedetl_list[l_idx].ext_tax_amt =			l_rec_curr_row_invoicedetl_original.ext_tax_amt
						LET l_arr_rec_invoicedetl_list[l_idx].line_total_amt =	l_rec_curr_row_invoicedetl_original.line_total_amt	
					END IF 

					CALL disp_total(l_rec_curr_row_invoicedetl_original.*)
				END IF 
			END IF 
		
	END INPUT 

	OPTIONS INPUT WRAP  #We turn input wrap back on 

	CALL db_st_invoicedetl_delete_invalid_rows()
	 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false
		LET l_ret = NAV_CANCEL
		 
		IF db_st_invoicedetl_get_count() > 0 THEN
			IF kandoomsg("A",8011,"") = "N" THEN	#8011  Do you wish TO hold line information?
				DELETE FROM t_invoicedetl WHERE 1=1 
				CALL serial_init(glob_rec_kandoouser.cmpy_code, "S", "0", '') 
				LET glob_rec_invoicehead.line_num = 0 #??? is this used ? do we need this really ?
			END IF
		ELSE
			#Still make sure, serial is reset
			CALL serial_init(glob_rec_kandoouser.cmpy_code, "S", "0", '') 
			LET glob_rec_invoicehead.line_num = 0 #??? is this used ? do we need this really ?
		END IF
		 
	ELSE 
		#nothing
	END IF 
	
	RETURN l_ret
END FUNCTION 
############################################################################
# END FUNCTION invoice_line_input_array()
############################################################################
