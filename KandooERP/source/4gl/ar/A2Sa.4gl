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
# A2Sa  allows the user TO enter an Accounts Receivable Invoice
#             AND THEN choose the customer(s) the invoice IS TO be copied
#             TO updating inventory OR NOT depending on the Parameters File
#             settings.
###########################################################################
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl" 
GLOBALS "../ar/A2_GROUP_GLOBALS.4gl"
GLOBALS "../ar/A2S_GLOBALS.4gl" 
############################################################
# FUNCTION db_invoicehead_select_inv_num()
#
# Display all invoices, user can select or enter the invoice number directly inv_num
# Accept/Double clickk returns inv_num
# Cancel returns NULL
############################################################
FUNCTION db_invoicehead_select_inv_num()
	DEFINE l_ret_inv_num LIKE invoicehead.inv_num
	DEFINE l_arr_rec_invoicehead DYNAMIC ARRAY OF RECORD
		inv_num LIKE invoicehead.inv_num, 
		purchase_code LIKE invoicehead.purchase_code, 
		cust_code LIKE invoicehead.cust_code,
		org_cust_code LIKE invoicehead.org_cust_code,
		inv_date LIKE invoicehead.inv_date, 
		year_num LIKE invoicehead.year_num, 
		period_num LIKE invoicehead.period_num, 
		total_amt LIKE invoicehead.total_amt, 
		paid_amt LIKE invoicehead.paid_amt, 
		posted_flag LIKE invoicehead.posted_flag 
	END RECORD 	
	DEFINE l_rec_invoicehead RECORD LIKE invoicehead.*
	DEFINE l_idx SMALLINT
	DEFINE l_rec_customer RECORD LIKE customer.*
	
	DECLARE c_cust CURSOR FOR 
	SELECT * INTO l_rec_invoicehead.* FROM invoicehead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
--	AND cust_code = l_rec_invoicehead.cust_code 
--	AND inv_num >= l_rec_invoicehead.inv_num 
	ORDER BY inv_num 
	LET l_idx = 0 

	FOREACH c_cust 
--		IF glob_corp_cust THEN 
--			IF l_rec_invoicehead.org_cust_code IS NULL OR 
--			l_rec_invoicehead.org_cust_code != glob_rec_customer.cust_code THEN 
--				CONTINUE FOREACH 
--			END IF 
--		END IF 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_invoicehead[l_idx].inv_num = l_rec_invoicehead.inv_num 
		LET l_arr_rec_invoicehead[l_idx].purchase_code = l_rec_invoicehead.purchase_code 
		LET l_arr_rec_invoicehead[l_idx].cust_code = l_rec_invoicehead.cust_code
		LET l_arr_rec_invoicehead[l_idx].org_cust_code = l_rec_invoicehead.org_cust_code
		LET l_arr_rec_invoicehead[l_idx].inv_date = l_rec_invoicehead.inv_date 
		LET l_arr_rec_invoicehead[l_idx].year_num = l_rec_invoicehead.year_num 
		LET l_arr_rec_invoicehead[l_idx].period_num = l_rec_invoicehead.period_num 
		LET l_arr_rec_invoicehead[l_idx].total_amt = l_rec_invoicehead.total_amt 
		LET l_arr_rec_invoicehead[l_idx].paid_amt = l_rec_invoicehead.paid_amt 
		LET l_arr_rec_invoicehead[l_idx].posted_flag = l_rec_invoicehead.posted_flag 

{
		# DISPLAY originating customer code AND name TO SCREEN
		SELECT customer.name_text INTO glob_t_name_text FROM customer 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = l_rec_invoicehead.org_cust_code 
		IF NOT status THEN 
			LET glob_arr_rec_nametext[l_idx].name_text = glob_t_name_text 
			LET glob_arr_rec_nametext[l_idx].cust_code = l_rec_invoicehead.org_cust_code 
		ELSE 
			LET glob_arr_rec_nametext[l_idx].name_text = NULL 
			LET glob_arr_rec_nametext[l_idx].cust_code = NULL 
		END IF 
--		IF l_idx = 300 THEN 
--			MESSAGE kandoomsg2("U",6100,l_idx) 	#6100 "First l_idx records selected "
--			EXIT FOREACH 
--		END IF 
}
	END FOREACH 
	
	LET l_ret_inv_num = NULL

	OPEN WINDOW A970 WITH FORM "A970"

	DIALOG ATTRIBUTE(UNBUFFERED)
	
	DISPLAY ARRAY l_arr_rec_invoicehead TO sr_invoicehead.* 
		BEFORE ROW 
			LET l_idx = arr_curr() 
			IF l_idx > 0 THEN
				LET l_ret_inv_num = l_arr_rec_invoicehead[l_idx].inv_num
				DISPLAY l_arr_rec_invoicehead[l_idx].inv_num TO fo_inv_num
				DISPLAY l_arr_rec_invoicehead[l_idx].cust_code TO fo_cust_code
				DISPLAY l_arr_rec_invoicehead[l_idx].org_cust_code TO fo_org_cust_code 
				CALL db_customer_get_rec(UI_OFF,l_arr_rec_invoicehead[l_idx].cust_code) RETURNING l_rec_customer.*
				DISPLAY l_rec_customer.name_text TO customer.name_text
			END IF
			
		ON ACTION ("ACCEPT","COUBLECLICK")
			IF (l_idx > 0) AND (l_idx <= l_arr_rec_invoicehead.getSize()) THEN
				LET l_ret_inv_num =  l_arr_rec_invoicehead[l_idx].inv_num
				EXIT DIALOG
			END IF
	
	END DISPLAY

	INPUT l_ret_inv_num FROM fo_inv_num
	
	END INPUT

		ON ACTION ("ACCEPT","COUBLECLICK")
			IF (l_idx > 0) AND (l_idx <= l_arr_rec_invoicehead.getSize()) THEN
				LET l_ret_inv_num =  l_arr_rec_invoicehead[l_idx].inv_num
				EXIT DIALOG
			END IF
			
		ON ACTION "CANCEL"
			EXIT DIALOG
			
	END DIALOG
	
	IF int_flag THEN
		LET int_flag = FALSE
		LET l_ret_inv_num = NULL
	END IF
	
	CLOSE WINDOW A970
	RETURN l_ret_inv_num
END FUNCTION
############################################################
# END FUNCTION db_invoicehead_select_inv_num()
############################################################


############################################################
# FUNCTION A2S_header() 
#
#
############################################################
FUNCTION A2S_header() 
	--DEFINE l_rec_glparms RECORD LIKE glparms.*
	--DEFINE l_rec_structure RECORD LIKE structure.*
	--DEFINE l_mask_code LIKE account.acct_code
	--DEFINE l_acct_override_code LIKE account.acct_code
	DEFINE l_save_conv LIKE invoicehead.conv_qty
	DEFINE l_save_ware LIKE warehouse.ware_code
	DEFINE l_save_ship LIKE invoicehead.ship_code
	--DEFINE l_ref_text LIKE arparms.inv_ref1_text
	--DEFINE l_temp_text CHAR(32)
	--DEFINE l_enter_seg CHAR(1)
	DEFINE l_conv_flag SMALLINT
	DEFINE l_failed_it SMALLINT
	DEFINE l_invalid SMALLINT 
	DEFINE i SMALLINT 
	DEFINE j SMALLINT 
	DEFINE x SMALLINT 

	LET l_invalid = true 

	IF glob_prmt = "Y" THEN 
--		OPEN WINDOW prev_info with FORM "U999" 
--		CALL windecoration_u("U999") 

		WHILE l_invalid = true 
			--LET glob_image_inv = fgl_winprompt(5,5, "Please Enter the invoice you wish TO image", "", 25, 0)

			LET glob_image_inv = db_invoicehead_select_inv_num()
			IF glob_image_inv IS NULL THEN
				MESSAGE "Application aborted"
				EXIT PROGRAM
			END IF
						
			IF glob_image_inv IS NULL 
			OR glob_image_inv = 0 THEN 
				LET glob_recalc = "N" 
				LET l_invalid = false 
			ELSE 
				SELECT inv_num 
				FROM invoicehead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND inv_num = glob_image_inv 

				IF status = NOTFOUND THEN 
					ERROR "l_invalid invoice try again " 
					attribute (YELLOW) 
				ELSE 
					LET glob_recalc = "Y" 
					LET l_invalid = false 
				END IF 
			END IF 
		END WHILE 

		IF glob_image_inv IS NULL OR 
		glob_image_inv = 0 THEN 
			LET glob_show_inv_det = "N" 
		ELSE 
			LET glob_show_inv_det = "Y" 
		END IF 

--		CLOSE WINDOW prev_info 
		LET glob_prmt = "N" 
	END IF 

	# in CASE coming back FROM DELETE KEY
	LET l_conv_flag = false 
	IF glob_first_time = 1 THEN 
		IF glob_f_type = "I" THEN 
			LET l_conv_flag = true 
		END IF 
		LET glob_first_time = 0 
		LET l_save_ship = "zzzzz" 
		LET glob_edit_line = 1 
		LET glob_ins_line = 0 
	END IF 

	# initialise variables IF new invoice
	IF glob_f_type = "I" THEN
	 
		CALL init_a_ar()

		IF glob_show_inv_det = "Y" THEN 
			SELECT * 
			INTO glob_rec_temp.* 
			FROM invoicehead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND inv_num = glob_image_inv 

			#This IS so we can get the ware_code AND the level_code FROM the
			#Invoice we are imaging.
			SELECT ware_code, level_code 
			INTO glob_rec_invoicedetl.ware_code, glob_rec_invoicedetl.level_code 
			FROM invoicedetl 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND inv_num = glob_image_inv 
			AND line_num = '1' 

			LET glob_goon = "Y" 
			LET glob_rec_invoicehead.currency_code = glob_rec_temp.currency_code 
			
			DISPLAY BY NAME glob_rec_invoicehead.currency_code #HuHo: attribute(GREEN) #why with color / green ? I'll remove it

			IF int_flag != 0 OR quit_flag != 0 THEN 
				LET glob_ans = "N" 
				CLOSE WINDOW wa2s 
				RETURN 
			END IF 

			LET glob_rec_invoicehead.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET glob_rec_invoicehead.inv_date = today 
			LET glob_rec_invoicehead.entry_date = today 
			LET glob_rec_invoicehead.entry_code = glob_rec_kandoouser.sign_on_code 
			LET glob_rec_invoicehead.tax_code = glob_rec_temp.tax_code 
			LET glob_rec_invoicehead.tax_per = glob_rec_temp.tax_per 
			LET glob_rec_invoicehead.goods_amt = '0' 
			LET glob_rec_invoicehead.tax_amt = '0' 
			LET glob_rec_invoicehead.total_amt = '0' 
			LET glob_rec_invoicehead.freight_amt = glob_rec_temp.freight_amt 
			LET glob_rec_invoicehead.freight_tax_code = glob_rec_temp.freight_tax_code 
			LET glob_rec_invoicehead.hand_amt = glob_rec_temp.hand_amt 
			LET glob_rec_invoicehead.hand_amt = glob_rec_temp.hand_amt 
			LET glob_rec_invoicehead.hand_tax_code = glob_rec_temp.hand_tax_code 
			LET glob_rec_invoicehead.conv_qty = glob_rec_temp.conv_qty 

		ELSE 
			SELECT * 
			INTO glob_rec_stnd_parms.* 
			FROM stnd_parms 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 

			LET glob_goon = "Y" 
			LET glob_rec_invoicehead.currency_code = glob_rec_stnd_parms.currency_code 

			DISPLAY BY NAME glob_rec_invoicehead.currency_code #HuHo: attribute(GREEN) #why with color / green ? I'll remove it 

			IF int_flag != 0 OR quit_flag != 0 THEN 
				LET glob_ans = "N" 
				CLOSE WINDOW wa2s 
				RETURN 
			END IF 

			LET glob_rec_invoicehead.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET glob_rec_invoicehead.inv_date = today 
			LET glob_rec_invoicehead.entry_date = today 
			LET glob_rec_invoicehead.entry_code = glob_rec_kandoouser.sign_on_code 
			LET glob_rec_invoicehead.currency_code = glob_rec_stnd_parms.currency_code 
			LET glob_rec_invoicehead.tax_code = glob_rec_stnd_parms.tax_code 
			LET glob_rec_invoicehead.goods_amt = '0' 
			LET glob_rec_invoicehead.tax_amt = '0' 
			LET glob_rec_invoicehead.total_amt = '0' 
			LET glob_rec_invoicedetl.ware_code = glob_rec_stnd_parms.ware_code 
			LET glob_rec_invoicedetl.level_code = glob_rec_stnd_parms.level_code 

		END IF {glob_show_inv_det} 

		CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, glob_rec_invoicehead.inv_date) 
		RETURNING	glob_rec_invoicehead.year_num, glob_rec_invoicehead.period_num 

		CALL get_conv_rate(
			glob_rec_kandoouser.cmpy_code, 
			glob_rec_invoicehead.currency_code, 
			glob_rec_invoicehead.inv_date, 
			CASH_EXCHANGE_SELL) 
		RETURNING glob_rec_invoicehead.conv_qty 

		#IF the user uses <DEL> TO break out of the invoicedetl window (A145),
		#have entered invoice lines AND answered Yes TO save line info, we can't
		#LET LET them change the warehouse. OTHERWISE the user IS able TO change
		#the warehouse.

		# This IS here OTHERWISE the warehouse stays the same as what was
		# entered previously
		IF glob_ins_line != 1 AND glob_show_inv_det = "N" THEN 
			LET glob_rec_warehouse.ware_code = glob_rec_stnd_parms.ware_code 
		ELSE 
			IF glob_show_inv_det = "Y" THEN 
				LET glob_rec_warehouse.ware_code = glob_rec_invoicedetl.ware_code 
			END IF 
		END IF 

	END IF {glob_f_type = "I"} 

	SELECT * 
	INTO glob_rec_tax.* 
	FROM tax 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND tax_code = glob_rec_invoicehead.tax_code 

	SELECT * 
	INTO glob_rec_warehouse.* 
	FROM warehouse 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND ware_code = glob_rec_stnd_parms.ware_code 

	LET l_save_conv = glob_rec_invoicehead.conv_qty 

	DISPLAY BY NAME 
		glob_rec_invoicehead.inv_date, 
		glob_rec_invoicehead.entry_code, 
		glob_rec_invoicehead.year_num, 
		glob_rec_invoicehead.period_num, 
		glob_rec_warehouse.ware_code, 
		glob_rec_invoicedetl.level_code, 
		glob_rec_invoicehead.tax_code, 
		glob_rec_invoicehead.currency_code, 
		glob_rec_invoicehead.conv_qty, 
		glob_rec_invoicehead.goods_amt, 
		glob_rec_invoicehead.tax_amt, 
		glob_rec_invoicehead.total_amt 

	DISPLAY glob_rec_invoicehead.currency_code TO formonly.currency_code 
	DISPLAY glob_rec_warehouse.desc_text TO warehouse.desc_text 
	DISPLAY glob_rec_tax.desc_text TO tax.desc_text  

	INPUT BY NAME 
		glob_rec_invoicehead.inv_date, 
		glob_rec_invoicehead.year_num, 
		glob_rec_invoicehead.period_num, 
		glob_rec_warehouse.ware_code, 
		glob_rec_invoicehead.tax_code, 
		glob_rec_invoicedetl.level_code, 
		glob_rec_invoicehead.currency_code, 
		glob_rec_invoicehead.conv_qty WITHOUT DEFAULTS 


		BEFORE INPUT 
			CALL publish_toolbar("kandoo","A2Sa","inp-invoicehead") 
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
			
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield (ware_code) 
					LET glob_rec_warehouse.ware_code = show_ware(glob_rec_kandoouser.cmpy_code) 
					DISPLAY BY NAME glob_rec_warehouse.ware_code 
					NEXT FIELD ware_code 
					
		ON ACTION "LOOKUP" infield (tax_code) 
					LET glob_rec_invoicehead.tax_code = show_tax(glob_rec_kandoouser.cmpy_code) 
					DISPLAY BY NAME glob_rec_invoicehead.tax_code 
					NEXT FIELD tax_code
					 
		ON ACTION "LOOKUP" infield (currency_code) 
					LET glob_rec_invoicehead.currency_code = show_curr(glob_rec_kandoouser.cmpy_code) 
					DISPLAY BY NAME glob_rec_invoicehead.currency_code 

					DISPLAY glob_rec_invoicehead.currency_code TO currency_code 
					NEXT FIELD currency_code 

		AFTER FIELD inv_date 
			IF glob_rec_invoicehead.inv_date IS NULL THEN 
				LET glob_rec_invoicehead.inv_date = today 
			END IF 

			CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, glob_rec_invoicehead.inv_date) 
			RETURNING glob_rec_invoicehead.year_num, glob_rec_invoicehead.period_num 

			IF l_conv_flag AND l_save_conv = glob_rec_invoicehead.conv_qty THEN 
				CALL get_conv_rate(
					glob_rec_kandoouser.cmpy_code, 
					glob_rec_invoicehead.currency_code, 
					glob_rec_invoicehead.inv_date, CASH_EXCHANGE_SELL) 
				RETURNING glob_rec_invoicehead.conv_qty
				 
				LET l_save_conv = glob_rec_invoicehead.conv_qty 
			END IF 

			DISPLAY BY NAME 
				glob_rec_invoicehead.year_num, 
				glob_rec_invoicehead.period_num, 
				glob_rec_invoicehead.conv_qty 

		AFTER FIELD period_num 
			CALL valid_period(
				glob_rec_kandoouser.cmpy_code, 
				glob_rec_invoicehead.year_num, 
				glob_rec_invoicehead.period_num, 
				LEDGER_TYPE_AR) 
			RETURNING 
				glob_rec_invoicehead.year_num, 
				glob_rec_invoicehead.period_num, 
				l_failed_it 

			IF l_failed_it = 1 THEN 
				NEXT FIELD year_num 
			END IF 

			# save the warehouse because cannot change this in edit mode
		BEFORE FIELD ware_code 
			LET l_save_ware = glob_rec_warehouse.ware_code 

		AFTER FIELD ware_code 
			IF glob_f_type != "I" AND 
			l_save_ware != glob_rec_warehouse.ware_code AND 
			glob_edit_line = 1 THEN 
				ERROR " Warehouse cannot be changed in an edit, delete lines THEN re-enter" 
					LET glob_rec_warehouse.ware_code = l_save_ware 
					DISPLAY BY NAME glob_rec_warehouse.ware_code 
					NEXT FIELD ware_code 
				END IF 
				# IF user <DEL> out of entering invoice lines (window A145), AND answers
				# Yes TO "Save line info", THEN they connot change the warehouse
				# IF they have entered invoice lines.
				# Invoice Enter.
				IF l_save_ware != glob_rec_warehouse.ware_code 
				AND glob_f_type = "I" 
				AND glob_ins_line = 1 THEN 
					ERROR "Warehouse cannot be changed WHEN Invoice lines have been Entered" 
					LET glob_rec_warehouse.ware_code = l_save_ware 
					DISPLAY BY NAME glob_rec_warehouse.ware_code 
					NEXT FIELD ware_code 
				END IF 

				IF glob_rec_warehouse.ware_code IS NULL THEN 
					ERROR "A warehouse code must be entered" 
					LET glob_rec_warehouse.ware_code = l_save_ware 
					NEXT FIELD ware_code 
				ELSE 
					SELECT warehouse.* 
					INTO glob_rec_warehouse.* 
					FROM warehouse 
					WHERE warehouse.ware_code = glob_rec_warehouse.ware_code 
					AND warehouse.cmpy_code = glob_rec_kandoouser.cmpy_code 

					IF (status = NOTFOUND) THEN 
						ERROR "Warehouse Code NOT found, try window" 
						NEXT FIELD ware_code 
					ELSE 
						DISPLAY glob_rec_warehouse.desc_text TO warehouse.desc_text 

					END IF 
				END IF 

		AFTER FIELD tax_code 
			IF glob_rec_invoicehead.tax_code IS NULL THEN 
				ERROR " Must enter a tax code, try window" 
				NEXT FIELD tax_code 
			ELSE 
				SELECT * 
				INTO glob_rec_tax.* 
				FROM tax 
				WHERE tax.tax_code = glob_rec_invoicehead.tax_code 
				AND tax.cmpy_code = glob_rec_kandoouser.cmpy_code 

				IF status = NOTFOUND THEN 
					ERROR "Tax Code NOT found, try window" 
					NEXT FIELD tax_code 
				END IF 
			END IF 

			DISPLAY glob_rec_tax.desc_text TO tax.desc_text 

		AFTER FIELD conv_qty 

			IF glob_rec_glparms.base_currency_code = glob_rec_invoicehead.currency_code AND glob_rec_invoicehead.conv_qty != 1.0 THEN 
				LET glob_rec_invoicehead.conv_qty = 1.0 
				DISPLAY BY NAME glob_rec_invoicehead.conv_qty 
				ERROR " Rate cannot be altered foreign currency does NOT apply " 
				NEXT FIELD conv_qty 
			END IF 

			IF NOT l_conv_flag AND l_save_conv != glob_rec_invoicehead.conv_qty THEN 
				LET glob_rec_invoicehead.conv_qty = l_save_conv 
				DISPLAY BY NAME glob_rec_invoicehead.conv_qty 
				ERROR " Exchange rate cannot be altered " 
				NEXT FIELD conv_qty 
			END IF 

			IF glob_rec_invoicehead.conv_qty IS NULL THEN 
				ERROR " Exchange Rate must have a value " 
				NEXT FIELD conv_qty 
			END IF 

			IF glob_rec_invoicehead.conv_qty <= 0 THEN 
				ERROR " Exchange Rate must be greater than zero " 
				NEXT FIELD conv_qty 
			END IF 

			IF int_flag != 0 OR quit_flag != 0 THEN 
				LET glob_ans = "N" 
				CLOSE WINDOW wa2s 
				RETURN 
			END IF 

		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN 
				IF glob_rec_invoicehead.inv_date IS NULL THEN 
					LET glob_rec_invoicehead.inv_date = today 
					
					CALL db_period_what_period(
						glob_rec_kandoouser.cmpy_code, 
						glob_rec_invoicehead.inv_date) 
					RETURNING glob_rec_invoicehead.year_num, glob_rec_invoicehead.period_num 
					
					DISPLAY BY NAME 
						glob_rec_invoicehead.period_num, 
						glob_rec_invoicehead.year_num 
				END IF 

				CALL valid_period(
					glob_rec_kandoouser.cmpy_code, 
					glob_rec_invoicehead.year_num, 
					glob_rec_invoicehead.period_num, 
					LEDGER_TYPE_AR) 
				RETURNING 
					glob_rec_invoicehead.year_num, 
					glob_rec_invoicehead.period_num, 
					l_failed_it 

				IF l_failed_it = 1 THEN 
					NEXT FIELD year_num 
				END IF 

				IF glob_rec_warehouse.ware_code IS NULL THEN 
					LET glob_rec_warehouse.desc_text = " No Warehouse Selected" 
				ELSE 
					SELECT warehouse.* 
					INTO glob_rec_warehouse.* 
					FROM warehouse 
					WHERE warehouse.ware_code = glob_rec_warehouse.ware_code 
					AND warehouse.cmpy_code = glob_rec_kandoouser.cmpy_code 

					IF (status = NOTFOUND) THEN 
						ERROR "Warehouse Code NOT found, try window" 
						NEXT FIELD ware_code 
					END IF 
				END IF 

				IF glob_rec_invoicehead.tax_code IS NULL THEN 
					ERROR " Must enter a tax code, try window" 
					NEXT FIELD tax_code 
				ELSE 
					SELECT * 
					INTO glob_rec_tax.* 
					FROM tax 
					WHERE tax.tax_code = glob_rec_invoicehead.tax_code 
					AND tax.cmpy_code = glob_rec_kandoouser.cmpy_code 

					IF status = NOTFOUND THEN 
						ERROR "Tax Code NOT found, try window" 
						NEXT FIELD tax_code 
					END IF 
					DISPLAY glob_rec_tax.desc_text TO tax.desc_text 
				END IF 

				LET glob_rec_invoicehead.cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF glob_f_type = "I" THEN 
					LET glob_rec_invoicehead.entry_date = today 
					LET glob_rec_invoicehead.inv_ind = "1" 
				END IF 
				LET glob_rec_invoicehead.tax_per = glob_rec_tax.tax_per 

			END IF 
	END INPUT 

	IF int_flag != 0 OR quit_flag != 0 THEN 
		LET glob_ans = "N" 
		CLOSE WINDOW wa2s 
		RETURN 
	END IF 

	LET glob_rec_invoicehead.hand_tax_code = glob_rec_invoicehead.tax_code 
	LET glob_rec_invoicehead.freight_tax_code = glob_rec_invoicehead.tax_code 

END FUNCTION 
############################################################
# END FUNCTION A2S_header() 
############################################################