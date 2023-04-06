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
GLOBALS "../ar/A2S_GLOBALS.4gl" 
############################################################
# MODULE Scope Variables
############################################################
DEFINE unit_tax MONEY (16,4) 
############################################################
# FUNCTION inv_window()
#
#
############################################################
FUNCTION inv_window() 
	DEFINE l_which CHAR(3)
	DEFINE l_price MONEY (10,2)
	DEFINE l_save_ware LIKE invoicedetl.ware_code
	DEFINE l_save_level LIKE invoicedetl.level_code
	DEFINE l_rec_savedetl RECORD LIKE invoicedetl.*
	DEFINE l_del_flag SMALLINT
	DEFINE l_spec_price_cust LIKE customer.cust_code
	DEFINE spec_price_level_ind LIKE customer.inv_level_ind 
	--DEFINE l_sav_sp_cust RECORD LIKE customer.* 
	DEFINE x SMALLINT
	DEFINE l_line_num SMALLINT
	DEFINE l_num_lines SMALLINT 

	OPEN WINDOW A145a with FORM "A145a" 
	CALL windecoration_a("A145a") 

	# save invoice details FROM glob_arr_rec_st_invoicedetl FOR reset IF "DEL" entered
	#note that VALUES in glob_arr_rec_st_invoicedetl are altered in this FUNCTION

	LET l_rec_savedetl.* = glob_arr_rec_st_invoicedetl[glob_idx].* 

	IF glob_rec_arparms.show_tax_flag = "Y" THEN 
		DISPLAY BY NAME glob_rec_invoicedetl.part_code, 
		glob_rec_invoicedetl.ship_qty, 
		glob_rec_invoicedetl.line_text, 
		glob_rec_invoicedetl.level_code, 
		glob_rec_invoicedetl.unit_sale_amt, 
		glob_rec_invoicedetl.unit_tax_amt, 
		glob_rec_invoicedetl.line_total_amt 

	ELSE 

		DISPLAY BY NAME glob_rec_invoicedetl.part_code, 
		glob_rec_invoicedetl.ship_qty, 
		glob_rec_invoicedetl.line_text, 
		glob_rec_invoicedetl.level_code, 
		glob_rec_invoicedetl.unit_sale_amt 

	END IF 
	DISPLAY glob_rec_warehouse.ware_code TO st_ware attribute(yellow) 

	MESSAGE " CTRL-P TO product details & transfers " attribute(yellow) 

	INPUT BY NAME glob_rec_invoicedetl.part_code, 
	glob_rec_invoicedetl.ship_qty, 
	glob_rec_invoicedetl.line_text, 
	glob_rec_invoicedetl.level_code, 
	glob_rec_invoicedetl.unit_sale_amt WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","A2Sc","inp-invoicedetl") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
			
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

			ON ACTION "NOTES" infield (line_text) --ON KEY (control-n) infield(line_text)  
				# We need the correct DELETE KEY in notes
				OPTIONS DELETE KEY f2 
				LET glob_rec_invoicedetl.line_text = 
				sys_noter(glob_rec_kandoouser.cmpy_code, glob_rec_invoicedetl.line_text) 
				WHENEVER ERROR CONTINUE 
				OPTIONS DELETE KEY f36 
				WHENEVER ERROR stop 
				WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
				DISPLAY glob_rec_invoicedetl.line_text TO invoicedetl.line_text 

				NEXT FIELD level_code 


		ON KEY (control-p) 
			CALL pinvwind(glob_rec_kandoouser.cmpy_code, glob_rec_invoicedetl.part_code) 

			# product id has already been entered so carry on.....

		BEFORE FIELD part_code 
			IF glob_rec_invoicedetl.part_code IS NULL THEN 
				INITIALIZE glob_rec_product.* TO NULL 
			ELSE 
				SELECT * 
				INTO glob_rec_product.* 
				FROM product 
				WHERE product.part_code = glob_rec_invoicedetl.part_code 
				AND product.cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF (status = NOTFOUND) THEN 
					ERROR "Product NOT found, try again" 
					SLEEP 4 
					LET glob_nxtfld = 1 
					LET glob_part_code = NULL 
					EXIT INPUT 
				END IF 
				
				IF glob_arr_rec_st_invoicedetl[glob_idx].part_code != glob_rec_invoicedetl.part_code 
				OR (glob_arr_rec_st_invoicedetl[glob_idx].part_code IS NULL	AND glob_rec_invoicedetl.part_code IS NOT null) THEN 
					LET glob_rec_invoicedetl.line_text = glob_rec_product.desc_text 
					LET glob_rec_invoicedetl.level_code = glob_rec_customer.inv_level_ind 
				END IF 
				
				LET l_save_level = glob_rec_invoicedetl.level_code 
				
				IF glob_rec_invoicedetl.uom_code IS NULL THEN 
					LET glob_rec_invoicedetl.uom_code = glob_rec_product.sell_uom_code 
				END IF 
				
				IF glob_rec_arparms.show_tax_flag = "Y" THEN 
					DISPLAY BY NAME 
						glob_rec_invoicedetl.part_code, 
						glob_rec_invoicedetl.line_text, 
						glob_rec_invoicedetl.uom_code, 
						glob_rec_invoicedetl.ship_qty, 
						glob_rec_invoicedetl.level_code, 
						glob_rec_invoicedetl.unit_sale_amt, 
						glob_rec_invoicedetl.unit_tax_amt 
				ELSE 
					DISPLAY BY NAME 
						glob_rec_invoicedetl.part_code, 
						glob_rec_invoicedetl.ship_qty, 
						glob_rec_invoicedetl.line_text, 
						glob_rec_invoicedetl.level_code, 
						glob_rec_invoicedetl.unit_sale_amt 

				END IF 

				SELECT category.* 
				INTO glob_rec_cat_codecat.* 
				FROM category 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cat_code = glob_rec_product.cat_code 
				IF (status = NOTFOUND) THEN 
					ERROR "Product Category FOR product NOT found" 
					SLEEP 4 
					LET glob_nxtfld = 1 
					EXIT INPUT 
				END IF 
				
				CALL display_stock() 
				
				IF glob_nxtfld = 1 THEN 
					SLEEP 4 
					EXIT INPUT 
				END IF 
				
				IF glob_arr_rec_st_invoicedetl[glob_idx].unit_sale_amt IS NULL THEN 
					CALL display_price() 
				END IF 
				
				CALL find_tax(
					glob_rec_invoicehead.tax_code, 
					glob_rec_invoicedetl.part_code, 
					glob_rec_invoicedetl.ware_code, 
					l_num_lines, 
					l_line_num, 
					glob_rec_invoicedetl.unit_sale_amt, 
					glob_rec_invoicedetl.ship_qty, 
					"L", 
					"", 
					"") 
				RETURNING 
					glob_rec_invoicedetl.ext_sale_amt, 
					glob_rec_invoicedetl.unit_tax_amt, 
					glob_rec_invoicedetl.ext_tax_amt, 
					glob_rec_invoicedetl.line_total_amt, 
					glob_rec_invoicedetl.tax_code 

				IF glob_rec_arparms.show_tax_flag = "Y" THEN 
					DISPLAY BY NAME 
						glob_rec_invoicedetl.unit_tax_amt, 
						glob_rec_invoicedetl.line_total_amt 
				ELSE 
					DISPLAY glob_rec_invoicedetl.ext_sale_amt TO line_total_amt 

				END IF 


				IF glob_nxtfld = 1 THEN 
					SLEEP 4 
					EXIT INPUT 
				END IF 
				LET glob_nxtfld = 0 
				NEXT FIELD ship_qty 
			END IF 

			--- modif ericv init # BEFORE FIELD ship_qty

		AFTER FIELD ship_qty 
			CALL qinv_proc(l_save_ware) RETURNING l_save_ware 

		AFTER FIELD level_code 
			IF glob_rec_invoicedetl.level_code != l_save_level THEN 

				CALL display_price() 
				
				CALL find_tax(
					glob_rec_invoicehead.tax_code, 
					glob_rec_invoicedetl.part_code, 
					glob_rec_invoicedetl.ware_code, 
					l_num_lines, 
					l_line_num, 
					glob_rec_invoicedetl.unit_sale_amt, 
					glob_rec_invoicedetl.ship_qty, 
					"L", 
					"", 
					"") 
				RETURNING 
					glob_rec_invoicedetl.ext_sale_amt, 
					glob_rec_invoicedetl.unit_tax_amt, 
					glob_rec_invoicedetl.ext_tax_amt, 
					glob_rec_invoicedetl.line_total_amt, 
					glob_rec_invoicedetl.tax_code 

				IF glob_rec_arparms.show_tax_flag = "Y" THEN 
					DISPLAY BY NAME glob_rec_invoicedetl.unit_tax_amt, 
					glob_rec_invoicedetl.line_total_amt 
				ELSE 
					DISPLAY glob_rec_invoicedetl.ext_sale_amt TO line_total_amt 

				END IF 

				LET l_save_level = glob_rec_invoicedetl.level_code 
			END IF 
		
		AFTER FIELD unit_sale_amt 
			IF glob_rec_invoicedetl.part_code IS NULL THEN 
				IF glob_rec_invoicedetl.unit_sale_amt <> 0 THEN 
					CALL get_acct() 
					RETURNING glob_del_yes 

				END IF 
			ELSE 
				IF glob_rec_invoicedetl.unit_sale_amt < 0 THEN 
					ERROR " Cannot sell inventory FOR less than zero" 
					NEXT FIELD unit_sale_amt 
				END IF 
			END IF 
			
			CALL find_tax(
				glob_rec_invoicehead.tax_code, 
				glob_rec_invoicedetl.part_code, 
				glob_rec_invoicedetl.ware_code, 
				l_num_lines, 
				l_line_num, 
				glob_rec_invoicedetl.unit_sale_amt, 
				glob_rec_invoicedetl.ship_qty, 
				"L", 
				"", 
				"") 
			RETURNING 
				glob_rec_invoicedetl.ext_sale_amt, 
				glob_rec_invoicedetl.unit_tax_amt, 
				glob_rec_invoicedetl.ext_tax_amt, 
				glob_rec_invoicedetl.line_total_amt, 
				glob_rec_invoicedetl.tax_code 

			IF glob_rec_arparms.show_tax_flag = "Y" THEN 
				DISPLAY BY NAME glob_rec_invoicedetl.unit_tax_amt, 
				glob_rec_invoicedetl.line_total_amt 
			ELSE 
				DISPLAY glob_rec_invoicedetl.ext_sale_amt TO line_total_amt 

			END IF 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 
			
			IF glob_rec_invoicedetl.ship_qty IS NULL THEN 
				LET glob_rec_invoicedetl.ship_qty = 0 
			END IF 
			
			CALL find_tax(
				glob_rec_invoicehead.tax_code, 
				glob_rec_invoicedetl.part_code, 
				glob_rec_invoicedetl.ware_code, 
				l_num_lines, 
				l_line_num, 
				glob_rec_invoicedetl.unit_sale_amt, 
				glob_rec_invoicedetl.ship_qty, 
				"L", 
				"", 
				"") 
			RETURNING 
				glob_rec_invoicedetl.ext_sale_amt, 
				glob_rec_invoicedetl.unit_tax_amt, 
				glob_rec_invoicedetl.ext_tax_amt, 
				glob_rec_invoicedetl.line_total_amt, 
				glob_rec_invoicedetl.tax_code 

			IF glob_rec_arparms.show_tax_flag = "Y" THEN 
				DISPLAY BY NAME glob_rec_invoicedetl.unit_tax_amt, 
				glob_rec_invoicedetl.line_total_amt 
			ELSE 
				DISPLAY glob_rec_invoicedetl.ext_sale_amt TO line_total_amt 

			END IF 

			# work out the extended tax AND prices
			LET l_which = TRAN_TYPE_INVOICE_IN 
			LET glob_rec_invoicedetl.seq_num = stat_res(
				glob_rec_kandoouser.cmpy_code, 
				glob_arr_rec_st_invoicedetl[glob_idx].ware_code, 
				glob_arr_rec_st_invoicedetl[glob_idx].part_code, 
				glob_arr_rec_st_invoicedetl[glob_idx].ship_qty, 
				l_which) 

			#   now read stock FOR UPDATE AND reduce onhand stock
			LET l_which = "OUT" 
			LET glob_rec_invoicedetl.seq_num = stat_res(
				glob_rec_kandoouser.cmpy_code, 
				glob_rec_invoicedetl.ware_code, 
				glob_rec_invoicedetl.part_code, 
				glob_rec_invoicedetl.ship_qty, 
				l_which) 
	END INPUT 
	CLOSE WINDOW A145a 

	# has interrupt OR quit been hit - IF so restore invoice details
	# FROM array

	IF glob_del_yes = "Y" THEN 
		LET glob_arr_rec_st_invoicedetl[glob_idx].* = l_rec_savedetl.* 
		LET glob_rec_invoicedetl.* = l_rec_savedetl.* 
		LET l_del_flag = true 
		LET glob_del_yes = "N" 
		RETURN (l_del_flag) 
	END IF 

	IF int_flag OR quit_flag THEN 
		LET glob_arr_rec_st_invoicedetl[glob_idx].* = l_rec_savedetl.* 
		LET glob_rec_invoicedetl.* = l_rec_savedetl.* 
		LET l_del_flag = true 
		LET int_flag = 0 
		LET quit_flag = 0 
	ELSE 
		LET l_del_flag = false 
	END IF 

	RETURN (l_del_flag) 
END FUNCTION 
############################################################
# END FUNCTION inv_window()
############################################################


############################################################
# FUNCTION set_invoicedetl()
#
#
############################################################
FUNCTION set_invoicedetl() 
	# SET up the invoice line

	LET glob_rec_invoicedetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET glob_rec_invoicedetl.cust_code = glob_rec_invoicehead.cust_code 

	IF glob_rec_invoicedetl.unit_sale_amt IS NULL THEN 
		LET glob_rec_invoicedetl.unit_sale_amt = 0 
	END IF 

	LET glob_rec_invoicedetl.cat_code = glob_rec_product.cat_code 

	IF glob_f_type = "I" THEN 
		LET glob_rec_invoicedetl.ord_qty = glob_rec_invoicedetl.ship_qty 
		LET glob_rec_invoicedetl.back_qty = 0 
		LET glob_rec_invoicedetl.prev_qty = 0 
	ELSE 
		IF glob_rec_invoicedetl.part_code = glob_arr_rec_st_invoicedetl[glob_idx].part_code THEN 
			LET glob_rec_invoicedetl.back_qty = glob_arr_rec_st_invoicedetl[glob_idx].back_qty 
			LET glob_rec_invoicedetl.prev_qty = glob_arr_rec_st_invoicedetl[glob_idx].prev_qty 
			LET glob_rec_invoicedetl.ord_qty = glob_arr_rec_st_invoicedetl[glob_idx].ord_qty 
		ELSE 
			LET glob_rec_invoicedetl.ord_qty = glob_rec_invoicedetl.ship_qty 
			LET glob_rec_invoicedetl.back_qty = 0 
			LET glob_rec_invoicedetl.prev_qty = 0 
		END IF 
	END IF 

	IF glob_rec_invoicedetl.part_code IS NULL THEN 
		LET glob_rec_invoicedetl.ser_flag = "N" 
	ELSE 
		LET glob_rec_invoicedetl.ser_flag = glob_rec_product.serial_flag 
	END IF 

	LET glob_rec_invoicedetl.ser_qty = 0 
	LET glob_rec_invoicedetl.uom_code = glob_rec_product.sell_uom_code 
	LET glob_rec_invoicedetl.unit_cost_amt = glob_rec_prodstatus.wgted_cost_amt * glob_rec_invoicehead.conv_qty 

	IF glob_rec_invoicedetl.unit_sale_amt IS NULL THEN 
		LET glob_rec_invoicedetl.unit_sale_amt = 0 
	END IF 

	IF glob_rec_invoicedetl.unit_cost_amt IS NULL THEN 
		LET glob_rec_invoicedetl.unit_cost_amt = 0 
	END IF 

	IF glob_rec_invoicedetl.ship_qty IS NULL THEN 
		LET glob_rec_invoicedetl.ship_qty = 0 
	END IF 

	LET glob_rec_invoicedetl.ext_cost_amt = glob_rec_invoicedetl.unit_cost_amt * glob_rec_invoicedetl.ship_qty 

	IF glob_rec_invoicedetl.ext_cost_amt IS NULL THEN 
		LET glob_rec_invoicedetl.ext_cost_amt = 0 
	END IF 

	LET glob_rec_invoicedetl.disc_amt = 0 

	IF glob_rec_invoicedetl.ext_sale_amt IS NULL THEN 
		LET glob_rec_invoicedetl.ext_sale_amt = 0 
	END IF 

	IF glob_rec_invoicedetl.line_acct_code IS NULL THEN 
		LET glob_rec_invoicedetl.line_acct_code = glob_rec_cat_codecat.sale_acct_code 
	END IF 

	IF glob_rec_invoicedetl.ext_tax_amt IS NULL THEN 
		LET glob_rec_invoicedetl.ext_tax_amt = 0 
	END IF 

	IF glob_rec_invoicehead.tax_amt IS NULL THEN 
		LET glob_rec_invoicehead.tax_amt = 0 
	END IF 

	#
	# SET up invoicedetl store array
	#
	LET glob_arr_rec_st_invoicedetl[glob_idx].* = glob_rec_invoicedetl.* 
	RETURN 
END FUNCTION 
############################################################
# END FUNCTION set_invoicedetl()
############################################################


############################################################
# FUNCTION display_stock() 
#
#
############################################################
FUNCTION display_stock() 
	DEFINE l_cal_available_flag LIKE opparms.cal_available_flag 

	#
	# displays warehouse stocking & extension of line in A145..
	#
	IF glob_rec_invoicedetl.part_code IS NOT NULL THEN 
		SELECT * INTO glob_rec_prodstatus.* FROM prodstatus 
		WHERE part_code = glob_rec_invoicedetl.part_code 
		AND ware_code = glob_rec_invoicedetl.ware_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		IF (status = NOTFOUND) THEN 
			ERROR "Product NOT AT warehouse" 
			LET glob_nxtfld = 1 
			RETURN 
		END IF 

		LET glob_nxtfld = 0 

		CALL db_opparms_get_rec(UI_OFF,"1") RETURNING glob_rec_opparms.*

		IF glob_rec_opparms.key_num IS NULL AND glob_rec_opparms.cmpy_code IS NULL THEN 
				LET l_cal_available_flag = "N" 
			ELSE 
				LET l_cal_available_flag = glob_rec_opparms.cal_available_flag 
		END IF 
	
		IF l_cal_available_flag = "N" THEN 
			LET glob_available = glob_rec_prodstatus.onhand_qty - glob_rec_prodstatus.reserved_qty 
			- glob_rec_prodstatus.back_qty 
			- glob_rec_invoicedetl.ship_qty 
		ELSE 
			LET glob_available = glob_rec_prodstatus.onhand_qty - glob_rec_prodstatus.reserved_qty 
			- glob_rec_invoicedetl.ship_qty 
		END IF 

		LET glob_rec_prodstatus.reserved_qty = glob_rec_prodstatus.onhand_qty - glob_available 
		IF (glob_rec_invoicedetl.part_code = glob_arr_rec_st_invoicedetl[glob_idx].part_code 
		AND glob_rec_invoicedetl.ware_code = glob_arr_rec_st_invoicedetl[glob_idx].ware_code) THEN 
			LET glob_rec_prodstatus.reserved_qty = glob_rec_prodstatus.reserved_qty -	glob_arr_rec_st_invoicedetl[glob_idx].ship_qty 
			LET glob_available = glob_available + glob_arr_rec_st_invoicedetl[glob_idx].ship_qty 
		END IF 

		DISPLAY glob_available TO avail attribute (yellow) 
		DISPLAY BY NAME glob_rec_prodstatus.list_amt 
		DISPLAY BY NAME 
			glob_rec_prodstatus.onhand_qty, 
			glob_rec_prodstatus.reserved_qty attribute (yellow) 
	END IF 
END FUNCTION 
############################################################
# END FUNCTION display_stock() 
############################################################
 

############################################################
# FUNCTION qinv_proc(p_save_ware) 
#
#
############################################################
FUNCTION qinv_proc(p_save_ware) 
	DEFINE p_save_ware LIKE invoicedetl.ware_code 
	
	CALL display_stock() 
	IF glob_rec_invoicedetl.unit_tax_amt IS NULL THEN 
		LET glob_rec_invoicedetl.unit_tax_amt = 0 
	END IF 
	IF glob_rec_invoicedetl.unit_tax_amt = 0 THEN 
		LET unit_tax = 0 
	END IF 

	LET glob_rec_invoicedetl.line_total_amt = (glob_rec_invoicedetl.unit_sale_amt + unit_tax) * glob_rec_invoicedetl.ship_qty 

	DISPLAY BY NAME glob_rec_invoicedetl.line_total_amt 

	# check TO see IF over available credit
	IF (glob_rec_invoicehead.total_amt + glob_rec_invoicedetl.line_total_amt) > glob_rec_customer.cred_bal_amt THEN 

		CALL fgl_winmessage("Credit Limit","Customer has gone over credit allowed","ERROR") 
		 
#		CLOSE WINDOW w51a 
	END IF 

	LET p_save_ware = glob_rec_invoicedetl.ware_code 

	RETURN p_save_ware 
END FUNCTION 
############################################################
# END FUNCTION qinv_proc(p_save_ware) 
############################################################