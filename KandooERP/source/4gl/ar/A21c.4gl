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
# Requires
# common/dispgpfunc.4gl
###########################################################################

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl"
GLOBALS "../ar/A2_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/A20_GLOBALS.4gl"
GLOBALS "../ar/A21_GLOBALS.4gl"  

###########################################################################
# FUNCTION debug_show_invoicedetl(p_header_text,p_rec_invoicedetl)
#
#
###########################################################################
FUNCTION debug_show_invoicedetl(p_header_text,p_rec_invoicedetl)
	DEFINE p_header_text STRING
	DEFINE p_rec_invoicedetl RECORD LIKE invoicedetl.* 

	DISPLAY "###########################################"
	DISPLAY "# ", trim(p_header_text)
	DISPLAY "###########################################"
	DISPLAY "FUNCTION invoice_line_entry_dialog(p_rec_invoicedetl) "
	DISPLAY "p_rec_invoicedetl.inv_num=",        trim(p_rec_invoicedetl.inv_num)
	DISPLAY "p_rec_invoicedetl.cust_code=",      trim(p_rec_invoicedetl.cust_code)
	
	DISPLAY "p_rec_invoicedetl.line_num=",       trim(p_rec_invoicedetl.line_num)
	DISPLAY "p_rec_invoicedetl.part_code",       trim(p_rec_invoicedetl.part_code)
	DISPLAY "p_rec_invoicedetl.line_text=",      trim(p_rec_invoicedetl.line_text)
	DISPLAY "p_rec_invoicedetl.ship_qty=",       trim(p_rec_invoicedetl.ship_qty)
	DISPLAY "p_rec_invoicedetl.tax_code=",       trim(p_rec_invoicedetl.tax_code)
	DISPLAY ".........CUSTOMER.tax_code=",       trim(db_customer_get_tax_code(UI_OFF,p_rec_invoicedetl.cust_code))
	DISPLAY "p_rec_invoicedetl.unit_cost_amt=",  trim(p_rec_invoicedetl.unit_cost_amt)
	DISPLAY "p_rec_invoicedetl.list_price_amt=",  trim(p_rec_invoicedetl.list_price_amt)
	DISPLAY "p_rec_invoicedetl.ext_cost_amt=",   trim(p_rec_invoicedetl.ext_cost_amt)	
	DISPLAY "p_rec_invoicedetl.unit_sale_amt=",  trim(p_rec_invoicedetl.unit_sale_amt)	
	DISPLAY "p_rec_invoicedetl.ext_sale_amt=",   trim(p_rec_invoicedetl.ext_sale_amt)	
	DISPLAY "p_rec_invoicedetl.line_total_amt=", trim(p_rec_invoicedetl.line_total_amt)	
	DISPLAY "p_rec_invoicedetl.line_acct_code=", trim(p_rec_invoicedetl.line_acct_code)
	DISPLAY "p_rec_invoicedetl.level_code=",     trim(p_rec_invoicedetl.level_code)
	DISPLAY "p_rec_invoicedetl.line_acct_code=", trim(p_rec_invoicedetl.line_acct_code)
	DISPLAY "p_rec_invoicedetl.seq_nume=",       trim(p_rec_invoicedetl.seq_num)
	DISPLAY "..............................."
	CALL debug_show_keys("BEFORE FIELD part_code")
END FUNCTION		
###########################################################################
# END FUNCTION debug_show_invoicedetl(p_header_text,p_rec_invoicedetl)
###########################################################################


########################################################################
# FUNCTION invoice_line_entry_dialog(p_rec_invoicedetl)
#
# 	IF int_flag OR quit_flag THEN 
#			CALL invoicedetl_update_line(l_rec_invoicedetl.*) #Store none-modified invoice line in DB  ?? hmm
#			RETURN FALSE 
#		ELSE 
#			CALL invoicedetl_update_line(p_rec_invoicedetl.*) #Store modified invoice line in DB
#			RETURN TRUE
#		END IF
########################################################################
FUNCTION invoice_line_entry_dialog(p_rec_invoicedetl) 
	DEFINE p_rec_invoicedetl RECORD LIKE invoicedetl.* 
	DEFINE l_rec_invoicedetl RECORD LIKE invoicedetl.* 
	DEFINE l_save_level_ind LIKE invoicedetl.level_code 
	#DEFINE l_save_price_amt LIKE invoicedetl.unit_sale_amt
	DEFINE l_serial_flag LIKE product.serial_flag 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_lastkey INTEGER 
	DEFINE l_valid_ind SMALLINT 
	DEFINE i SMALLINT 
	DEFINE j SMALLINT 
	DEFINE l_price DECIMAL(16,2) 
	DEFINE l_errmsg CHAR(100) 
	DEFINE l_tab_cnt SMALLINT 
	DEFINE l_cnt SMALLINT 
	DEFINE l_specialprice SMALLINT 
	DEFINE l_ret_next_field STRING #next field to go to for possible validation return

	IF get_debug() THEN					
		CALL debug_show_invoicedetl("BEGIN - FUNCTION invoice_line_entry_dialog(p_rec_invoicedetl)",l_rec_invoicedetl.*) 
	END IF

	LET l_rec_invoicedetl.* = p_rec_invoicedetl.* 
	
	#-------------------------------------------------------
	# Take copy of RECORD TO reinstate IF user backs out

	OPEN WINDOW A145 with FORM "A145" 
	CALL windecoration_a("A145") 

	CALL display_line(p_rec_invoicedetl.*) 
	ERROR kandoomsg2("A",1066,"") #A1066 " CTRL-P TO product details & transfers " ATTRIBUTE(yellow)

	INPUT BY NAME p_rec_invoicedetl.part_code, 
	p_rec_invoicedetl.line_text, 
	p_rec_invoicedetl.ship_qty, 
	p_rec_invoicedetl.level_code, 
	p_rec_invoicedetl.unit_sale_amt WITHOUT DEFAULTS ATTRIBUTE(UNBUFFERED) 


		BEFORE INPUT 
			CALL publish_toolbar("kandoo","A21c","inp-invoicedetl") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield (part_code) 
			LET glob_temp_text= 
				"status_ind in ('1','4') ", 
				"AND part_code =", 
				"(SELECT part_code FROM prodstatus ", 
				"WHERE cmpy_code='",glob_rec_kandoouser.cmpy_code,"' ", 
				"AND part_code=product.part_code ", 
				"AND ware_code='",glob_rec_warehouse.ware_code,"' ", 
				"AND status_ind in('1','4'))" 
			
			LET glob_temp_text = show_part(glob_rec_kandoouser.cmpy_code,glob_temp_text) 
			
			IF glob_temp_text IS NOT NULL THEN 
				LET p_rec_invoicedetl.part_code = glob_temp_text 
				NEXT FIELD part_code 
			END IF 

			ON ACTION "NOTES" infield (line_text) --ON KEY (control-n) infield (line_text) 
			LET p_rec_invoicedetl.line_text = sys_noter(glob_rec_kandoouser.cmpy_code,p_rec_invoicedetl.line_text) 
			NEXT FIELD line_text 

		ON ACTION "Try me 1"
		--ON KEY (F8) 
			CALL pinvwind(glob_rec_kandoouser.cmpy_code,p_rec_invoicedetl.part_code) 

		ON ACTION "Try me 2"
		--ON KEY (control-p)  
			CALL dispgpfunc(
				glob_rec_invoicehead.currency_code, 
				p_rec_invoicedetl.ext_cost_amt, 
				p_rec_invoicedetl.ext_sale_amt) 

		# PART_CODE -----------------------------------------------------------
		BEFORE FIELD part_code 
			IF p_rec_invoicedetl.part_code IS NOT NULL THEN 
				SELECT serial_flag INTO l_serial_flag FROM product 
				WHERE part_code = p_rec_invoicedetl.part_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF l_serial_flag = 'Y' THEN 
					NEXT FIELD NEXT 
				END IF 
			END IF 

		AFTER FIELD part_code
			#Validate Field(s) and update temp invoice line	 
			CALL validate_field_and_update_temp_line("part_code",p_rec_invoicedetl.*) 
				RETURNING l_valid_ind,l_ret_next_field,p_rec_invoicedetl.* 
			IF NOT l_valid_ind THEN 
				NEXT FIELD part_code #Warehouse enabled - Part Code MUST be valid
			END IF 

			#SERIAL
			IF (p_rec_invoicedetl.part_code IS NOT NULL) AND (p_rec_invoicedetl.ware_code IS NOT NULL) THEN  #No partCode and Warehouse disabled 
				SELECT serial_flag INTO l_serial_flag FROM product 
				WHERE part_code = p_rec_invoicedetl.part_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	
				IF l_serial_flag = 'Y' THEN 
					LET l_tab_cnt = serial_count(	p_rec_invoicedetl.part_code,p_rec_invoicedetl.ware_code)
					 
					IF l_tab_cnt > p_rec_invoicedetl.ship_qty THEN 
	
						IF p_rec_invoicedetl.ship_qty = 0 THEN 
							ERROR kandoomsg2("I",9278,'') 				#9278 Product / Warehouse combination can only occur 1
							LET p_rec_invoicedetl.part_code = NULL 
							LET p_rec_invoicedetl.line_text = NULL 
							NEXT FIELD part_code 
						ELSE 
							ERROR kandoomsg2("I",9279,'') 						#9279 Error - INPUT Quantity NOT equal OUTPUT Quantity
							LET l_errmsg = "A21c - Qty supplied NOT= table qty ",	p_rec_invoicedetl.ship_qty , " <> ", l_tab_cnt 
							CALL errorlog(l_errmsg) 
							LET status = -2 
							EXIT PROGRAM 
						END IF 
	
					END IF 
	
				END IF
			END IF
			 
			CALL display_line(p_rec_invoicedetl.*) 

		# SHIP_QTY -----------------------------------------------------------
		BEFORE FIELD ship_qty 
			IF l_serial_flag = 'Y' THEN 
				LET l_lastkey = fgl_lastkey() 
				LET l_tab_cnt = serial_count(p_rec_invoicedetl.part_code, p_rec_invoicedetl.ware_code) 
				LET l_cnt = serial_input(p_rec_invoicedetl.part_code,p_rec_invoicedetl.ware_code,l_tab_cnt) 

				IF l_cnt < 0 THEN 
					IF l_cnt = -1 THEN 
						NEXT FIELD part_code 
					ELSE 
						CALL errorlog("A21b - Fatal error in serial_input ") 
						EXIT PROGRAM 
					END IF 

				ELSE 

					LET p_rec_invoicedetl.ship_qty = 
					p_rec_invoicedetl.ship_qty + l_cnt - l_tab_cnt 

					#Validate Field(s) and update temp invoice line
					CALL validate_field_and_update_temp_line("ship_qty",p_rec_invoicedetl.*) 
						RETURNING l_valid_ind,l_ret_next_field,p_rec_invoicedetl.* 

					IF NOT l_valid_ind THEN 
						NEXT FIELD part_code 
					ELSE 
						CALL display_line(p_rec_invoicedetl.*) 
						IF l_lastkey = fgl_keyval("up") 
						OR l_lastkey = fgl_keyval("left") THEN 
							NEXT FIELD previous 
						ELSE 
							NEXT FIELD NEXT 
						END IF 
					END IF 

				END IF 

			END IF 

			CALL display_line(p_rec_invoicedetl.*) 

		AFTER FIELD ship_qty 
			#Validate Field(s) and update temp invoice line
			CALL validate_field_and_update_temp_line("ship_qty",p_rec_invoicedetl.*) 
				RETURNING l_valid_ind,l_ret_next_field,p_rec_invoicedetl.* 

			IF get_debug() THEN					
				DISPLAY "..............................."
				DISPLAY "AFTER FIELD ship_qty"
				DISPLAY "l_valid_ind=", l_valid_ind
				DISPLAY "p_rec_invoicedetl.* =", p_rec_invoicedetl.* 
				DISPLAY "..............................."
				CALL debug_show_keys("BEFORE FIELD part_code")
			END IF

			IF NOT l_valid_ind THEN 
				NEXT FIELD ship_qty 
			END IF 

			CALL display_line(p_rec_invoicedetl.*) 

		# LEVEL_CODE -----------------------------------------------------------
		BEFORE FIELD level_code 
			IF p_rec_invoicedetl.part_code IS NULL THEN 
				#---------------------------------------
				# Level NOT valid FOR non-inventory items
				IF NOT get_is_screen_navigation_forward() THEN 
					NEXT FIELD previous 
				ELSE 
					NEXT FIELD NEXT 
				END IF 
			END IF 

			LET l_save_level_ind = p_rec_invoicedetl.level_code 

		AFTER FIELD level_code 
			IF p_rec_invoicedetl.level_code IS NULL THEN 
				LET p_rec_invoicedetl.level_code = l_rec_invoicedetl.level_code 
				NEXT FIELD level_code 
			END IF 

			IF p_rec_invoicedetl.level_code != l_save_level_ind THEN 
				LET p_rec_invoicedetl.unit_sale_amt = 
					unit_price(p_rec_invoicedetl.ware_code,	p_rec_invoicedetl.part_code, p_rec_invoicedetl.level_code) 

				LET p_rec_invoicedetl.disc_per = NULL 
				
				#---------------------------------------
				#Validate Field(s) and update temp invoice line
				CALL validate_field_and_update_temp_line("unit_sale_amt",p_rec_invoicedetl.*) RETURNING l_valid_ind,l_ret_next_field,p_rec_invoicedetl.* 
				IF l_valid_ind THEN 
					CALL display_line(p_rec_invoicedetl.*) 
				ELSE 
					NEXT FIELD unit_sale_amt 
				END IF 

			END IF 

		AFTER FIELD unit_sale_amt 
			LET p_rec_invoicedetl.disc_per = NULL
			#---------------------------------------
			#Validate Field(s) and update temp invoice line			 
			CALL validate_field_and_update_temp_line("unit_sale_amt",p_rec_invoicedetl.*) 
				RETURNING l_valid_ind,l_ret_next_field,p_rec_invoicedetl.* 

			IF l_valid_ind THEN 
				CALL display_line(p_rec_invoicedetl.*) 
			ELSE 
				NEXT FIELD unit_sale_amt 
			END IF 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				#---------------------------------------
				#Check for invoice line with NONE-Warehouse Product
				IF (p_rec_invoicedetl.line_total_amt > 0) AND (p_rec_invoicedetl.part_code IS NULL) THEN 
					LET p_rec_invoicedetl.line_acct_code = enter_acct(p_rec_invoicedetl.line_acct_code)  #none-warehouse products need to have a GL account associated 
					IF p_rec_invoicedetl.line_acct_code IS NULL THEN 
						CONTINUE INPUT 
					END IF 

				ELSE 
				IF get_debug() THEN					
					DISPLAY "..............................."
					DISPLAY "l_rec_invoicedetl.line_num=", l_rec_invoicedetl.line_num
					DISPLAY "..............................."
					CALL debug_show_keys("BEFORE FIELD part_code")
				END IF

					IF fgl_lastkey() != fgl_keyval("accept") THEN 
						IF kandoomsg("E",8006,"") = "N" THEN	#8006 Line Entry Complete. (Y/N)?
							NEXT FIELD part_code 
						END IF 
					END IF 
				END IF 

			END IF 

	END INPUT 
	###########################

	CLOSE WINDOW A145 
	OPTIONS INSERT KEY f1, 
	DELETE KEY f36 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		#---------------------------------------
		#Write invoice line record to DB
		CALL invoicedetl_update_line(l_rec_invoicedetl.*) #Store ??? invoice line in DB  ?? hmm
		RETURN FALSE 
	ELSE 
		#---------------------------------------
		#Write invoice line record to DB	
		CALL invoicedetl_update_line(p_rec_invoicedetl.*) #Store modified invoice line in DB
		RETURN TRUE
	END IF 

END FUNCTION 
########################################################################
# END FUNCTION invoice_line_entry_dialog(p_rec_invoicedetl)
########################################################################


########################################################################
# FUNCTION display_line(p_rec_invoicedetl)
#
#
########################################################################
FUNCTION display_line(p_rec_invoicedetl) 
	DEFINE p_rec_invoicedetl RECORD LIKE invoicedetl.* 
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.* 
	DEFINE l_ship_qty LIKE prodstatus.onhand_qty 
	DEFINE l_cur_avail_qty LIKE prodstatus.onhand_qty 
	DEFINE l_fut_avail_qty LIKE prodstatus.onhand_qty 

	DISPLAY BY NAME 
		p_rec_invoicedetl.part_code, 
		p_rec_invoicedetl.line_text, 
		p_rec_invoicedetl.uom_code, 
		p_rec_invoicedetl.ship_qty, 
		p_rec_invoicedetl.level_code, 
		p_rec_invoicedetl.disc_per, 
		p_rec_invoicedetl.list_price_amt, 
		p_rec_invoicedetl.unit_sale_amt, 
		p_rec_invoicedetl.ext_sale_amt, 
		p_rec_invoicedetl.unit_tax_amt, 
		p_rec_invoicedetl.ext_tax_amt, 
		p_rec_invoicedetl.line_total_amt 

	DISPLAY glob_rec_invoicehead.currency_code TO currency_code #HuHo: attribute(GREEN) #why with color / green ? I'll remove it 

	SELECT * INTO l_rec_prodstatus.* 
	FROM prodstatus 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = p_rec_invoicedetl.part_code 
	AND ware_code = p_rec_invoicedetl.ware_code 

	IF l_rec_prodstatus.stocked_flag = "Y" THEN 
		IF glob_rec_invoicehead.inv_num IS NOT NULL THEN 

			#---------------------------------------------
			# Invoice edit
			# sum ship_qty already committed TO database.
			SELECT sum(ship_qty) INTO l_ship_qty 
			FROM invoicedetl 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND inv_num = glob_rec_invoicehead.inv_num 
			IF l_ship_qty IS NULL THEN 
				LET l_ship_qty = 0 
			END IF 
			LET l_rec_prodstatus.onhand_qty = l_rec_prodstatus.onhand_qty	+ l_ship_qty 
		END IF 

		LET l_rec_prodstatus.reserved_qty = l_rec_prodstatus.reserved_qty - p_rec_invoicedetl.ship_qty 

		IF glob_rec_opparms.cal_available_flag = "N" THEN 
			LET l_cur_avail_qty = l_rec_prodstatus.onhand_qty - l_rec_prodstatus.reserved_qty - l_rec_prodstatus.back_qty 
		ELSE 
			LET l_cur_avail_qty = l_rec_prodstatus.onhand_qty	- l_rec_prodstatus.reserved_qty 
		END IF 

		LET l_fut_avail_qty = l_cur_avail_qty + l_rec_prodstatus.onord_qty 

		DISPLAY 
		l_rec_prodstatus.ware_code, 
		l_rec_prodstatus.onhand_qty, 
		l_rec_prodstatus.reserved_qty, 
		l_rec_prodstatus.back_qty, 
		l_cur_avail_qty, 
		l_rec_prodstatus.onord_qty, 
		l_fut_avail_qty 
		TO 
			invoicedetl.ware_code, 
			prodstatus.onhand_qty, 
			prodstatus.reserved_qty, 
			prodstatus.back_qty, 
			avail_qty, 
			prodstatus.onord_qty, 
			fut_avail_qty attribute(yellow) 

	ELSE 

		DISPLAY "N/S" TO ware_code 

		CLEAR 
			invoicedetl.ware_code, 
			prodstatus.onhand_qty, 
			prodstatus.reserved_qty, 
			prodstatus.back_qty, 
			avail_qty, 
			prodstatus.onord_qty, 
			fut_avail_qty 
	END IF 

END FUNCTION 
########################################################################
# END FUNCTION display_line(p_rec_invoicedetl)
########################################################################


########################################################################
# FUNCTION unit_price(p_ware_code,p_part_code,p_level_ind)
#
#
########################################################################
FUNCTION unit_price(p_ware_code,p_part_code,p_level_ind) 
	DEFINE p_ware_code LIKE prodstatus.ware_code 
	DEFINE p_part_code LIKE prodstatus.part_code 
	DEFINE p_level_ind LIKE customer.inv_level_ind 
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.* 

	SELECT * INTO l_rec_prodstatus.* 
	FROM prodstatus 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND ware_code = p_ware_code 
	AND part_code = p_part_code 

	IF sqlca.sqlcode = NOTFOUND THEN 
		RETURN 0 
	ELSE 
		CASE p_level_ind 
			WHEN "1" RETURN(l_rec_prodstatus.price1_amt*glob_rec_invoicehead.conv_qty) 
			WHEN "2" RETURN(l_rec_prodstatus.price2_amt*glob_rec_invoicehead.conv_qty) 
			WHEN "3" RETURN(l_rec_prodstatus.price3_amt*glob_rec_invoicehead.conv_qty) 
			WHEN "4" RETURN(l_rec_prodstatus.price4_amt*glob_rec_invoicehead.conv_qty) 
			WHEN "5" RETURN(l_rec_prodstatus.price5_amt*glob_rec_invoicehead.conv_qty) 
			WHEN "6" RETURN(l_rec_prodstatus.price6_amt*glob_rec_invoicehead.conv_qty) 
			WHEN "7" RETURN(l_rec_prodstatus.price7_amt*glob_rec_invoicehead.conv_qty) 
			WHEN "8" RETURN(l_rec_prodstatus.price8_amt*glob_rec_invoicehead.conv_qty) 
			WHEN "9" RETURN(l_rec_prodstatus.price9_amt*glob_rec_invoicehead.conv_qty) 
			WHEN "L" RETURN(l_rec_prodstatus.list_amt*glob_rec_invoicehead.conv_qty) 
			WHEN "C" RETURN(l_rec_prodstatus.wgted_cost_amt*glob_rec_invoicehead.conv_qty) 
			OTHERWISE RETURN(l_rec_prodstatus.list_amt*glob_rec_invoicehead.conv_qty) 
		END CASE 
	END IF 

END FUNCTION 
########################################################################
# END FUNCTION unit_price(p_ware_code,p_part_code,p_level_ind)
########################################################################