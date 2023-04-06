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
GLOBALS "../ar/A_AR_GLOBALS.4gl" 
GLOBALS "../ar/A2_GROUP_GLOBALS.4gl"
GLOBALS "../ar/A2S_GLOBALS.4gl"  
###########################################################################
# MODULE Scope Variables
###########################################################################
DEFINE modu_arr_rec_product array[50] OF RECORD 
	part_code LIKE product.part_code, 
	desc_text LIKE product.desc_text, 
	available LIKE prodstatus.onhand_qty 
END RECORD 
DEFINE modu_idx4 SMALLINT #scrn4, 
DEFINE modu_temp_cnt SMALLINT 
DEFINE modu_save_idx CHAR(3) 
DEFINE modu_found_it CHAR(1) 
###########################################################################
# FUNCTION lineitem() 
#
#
###########################################################################
FUNCTION lineitem() 
	DEFINE l_arr_rec_invoicedetl DYNAMIC ARRAY OF RECORD 
		part_code LIKE invoicedetl.part_code, 
		ship_qty LIKE invoicedetl.ship_qty, 
		line_text LIKE invoicedetl.line_text, 
		unit_sale_amt LIKE invoicedetl.unit_sale_amt, 
		line_total_amt LIKE invoicedetl.line_total_amt 
	END RECORD 
	DEFINE l_arr_rec_v_invoicedetl DYNAMIC ARRAY OF RECORD
		part_code LIKE invoicedetl.part_code, 
		ship_qty LIKE invoicedetl.ship_qty, 
		line_text LIKE invoicedetl.line_text, 
		unit_sale_amt LIKE invoicedetl.unit_sale_amt, 
		line_total_amt LIKE invoicedetl.line_total_amt 
	END RECORD 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_ans1 CHAR(1)
	DEFINE l_which CHAR(3)
	DEFINE l_cnt SMALLINT #scrn1, 
	DEFINE l_last_window SMALLINT #scrn, 
	DEFINE j SMALLINT
	DEFINE l_acount SMALLINT
	DEFINE l_ins_flag SMALLINT
	DEFINE l_del_flag SMALLINT
	DEFINE l_tax_idx SMALLINT
	DEFINE l_name_text LIKE customer.name_text
	DEFINE l_pos SMALLINT
	DEFINE l_start_idx SMALLINT
	DEFINE x SMALLINT #, fv_scrn_idx 
	DEFINE l_ext_price MONEY(10,2) 
	DEFINE l_saved_tot MONEY(10,2) 
	DEFINE l_cal_available_flag LIKE opparms.cal_available_flag 

	
	WHENEVER ERROR CONTINUE 
	OPTIONS DELETE KEY f36 
	WHENEVER ERROR stop 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

	LET glob_nxtfld = 0 
	LET glob_firstime = 1 
	LET l_ins_flag = 0 
	LET glob_rec_invoicedetl.ware_code = glob_rec_warehouse.ware_code 
	LET glob_rec_invoicedetl.level_code = glob_rec_stnd_parms.level_code 

	IF glob_ans = "Y" THEN 
		DECLARE curser_item CURSOR FOR 
		SELECT invoicedetl.* 
		INTO glob_rec_invoicedetl.* 
		FROM invoicedetl 
		WHERE inv_num = glob_rec_invoicehead.inv_num 
		AND cust_code = glob_rec_invoicehead.cust_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 

		LET glob_idx = 0 

		FOREACH curser_item 
			LET glob_idx = glob_idx + 1 
			LET modu_save_idx = glob_idx 
			LET glob_arr_rec_taxamt[glob_idx].tax_amt = 0 
			LET l_arr_rec_invoicedetl[glob_idx].part_code = glob_rec_invoicedetl.part_code 
			LET l_arr_rec_invoicedetl[glob_idx].ship_qty = glob_rec_invoicedetl.ship_qty 
			LET l_arr_rec_invoicedetl[glob_idx].line_text = glob_rec_invoicedetl.line_text 
			LET l_arr_rec_invoicedetl[glob_idx].unit_sale_amt = glob_rec_invoicedetl.unit_sale_amt 

			IF glob_rec_arparms.show_tax_flag = "Y" THEN 
				LET l_arr_rec_invoicedetl[glob_idx].line_total_amt = 
				glob_rec_invoicedetl.line_total_amt 
			ELSE 
				LET l_arr_rec_invoicedetl[glob_idx].line_total_amt = 
				glob_rec_invoicedetl.unit_sale_amt * glob_rec_invoicedetl.ship_qty 
			END IF 
			
			LET glob_arr_rec_st_invoicedetl[glob_idx].* = glob_rec_invoicedetl.* 
			LET l_arr_rec_v_invoicedetl[glob_idx].* = l_arr_rec_invoicedetl[glob_idx].* 

			CALL find_taxcode(glob_rec_invoicedetl.tax_code) RETURNING l_tax_idx 
			LET glob_arr_rec_taxamt[l_tax_idx].tax_amt = glob_arr_rec_taxamt[l_tax_idx].tax_amt +	glob_rec_invoicedetl.ext_tax_amt 
		END FOREACH 

		IF glob_show_inv_det = "Y" AND glob_image_inv IS NOT NULL OR glob_image_inv > 0 THEN 
			LET glob_rec_invoicehead.goods_amt = glob_rec_temp.goods_amt 
			LET glob_rec_invoicehead.cost_amt = glob_rec_temp.cost_amt 

			DECLARE stnd_item CURSOR FOR 
			SELECT invoicedetl.* 
			INTO glob_rec_invoicedetl.* 
			FROM invoicedetl 
			WHERE inv_num = glob_image_inv 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 

			LET glob_idx = 0 

			FOREACH stnd_item 
				LET glob_idx = glob_idx + 1 
				LET modu_save_idx = glob_idx 
				LET glob_arr_rec_taxamt[glob_idx].tax_amt = 0 
				LET l_arr_rec_invoicedetl[glob_idx].part_code = glob_rec_invoicedetl.part_code 
				LET l_arr_rec_invoicedetl[glob_idx].ship_qty = glob_rec_invoicedetl.ship_qty 
				LET l_arr_rec_invoicedetl[glob_idx].line_text = glob_rec_invoicedetl.line_text 
				LET l_arr_rec_invoicedetl[glob_idx].unit_sale_amt =	glob_rec_invoicedetl.unit_sale_amt 

				IF glob_rec_arparms.show_tax_flag = "Y" THEN 
					LET l_arr_rec_invoicedetl[glob_idx].line_total_amt =	glob_rec_invoicedetl.line_total_amt 
				ELSE 
					LET l_arr_rec_invoicedetl[glob_idx].line_total_amt =	glob_rec_invoicedetl.unit_sale_amt * glob_rec_invoicedetl.ship_qty 
				END IF 
				
				LET glob_arr_rec_st_invoicedetl[glob_idx].* = glob_rec_invoicedetl.* 

				INITIALIZE glob_arr_rec_st_invoicedetl[glob_idx].cust_code TO NULL 
				
				LET l_arr_rec_v_invoicedetl[glob_idx].* = l_arr_rec_invoicedetl[glob_idx].* 

				CALL find_taxcode(glob_rec_invoicedetl.tax_code) RETURNING l_tax_idx 
				LET glob_arr_rec_taxamt[l_tax_idx].tax_amt = glob_arr_rec_taxamt[l_tax_idx].tax_amt +		glob_rec_invoicedetl.ext_tax_amt 
				LET glob_rec_invoicehead.tax_amt = glob_rec_invoicehead.tax_amt +		glob_rec_invoicedetl.ext_tax_amt 
			END FOREACH 

			LET glob_rec_invoicehead.total_amt = glob_rec_invoicehead.goods_amt +	glob_rec_invoicehead.tax_amt 
			LET glob_show_inv_det = "N" 
		END IF 

		IF modu_save_idx IS NULL THEN 
			LET modu_save_idx = 0 
		END IF 

		LET glob_tot_lines = glob_idx 
		CALL find_taxcode(glob_rec_invoicehead.hand_tax_code) RETURNING l_tax_idx 
		LET glob_arr_rec_taxamt[l_tax_idx].tax_amt = glob_arr_rec_taxamt[l_tax_idx].tax_amt +	glob_rec_invoicehead.hand_tax_amt 
		CALL find_taxcode(glob_rec_invoicehead.freight_tax_code) RETURNING l_tax_idx 
		LET glob_arr_rec_taxamt[l_tax_idx].tax_amt = glob_arr_rec_taxamt[l_tax_idx].tax_amt + glob_rec_invoicehead.freight_tax_amt 
	ELSE 

		# this IS the CASE of a RETURN FROM the A2Sc module via DEL key
		FOR glob_i = 1 TO glob_arr_size 
			LET l_arr_rec_invoicedetl[glob_i].part_code = glob_arr_rec_st_invoicedetl[glob_i].part_code 
			LET l_arr_rec_invoicedetl[glob_i].ship_qty = glob_arr_rec_st_invoicedetl[glob_i].ship_qty 
			LET l_arr_rec_invoicedetl[glob_i].line_text = glob_arr_rec_st_invoicedetl[glob_i].line_text 
			LET l_arr_rec_invoicedetl[glob_i].unit_sale_amt = glob_arr_rec_st_invoicedetl[glob_i].unit_sale_amt 
			
			IF glob_rec_arparms.show_tax_flag = "Y" THEN 
				LET l_arr_rec_invoicedetl[glob_i].line_total_amt =	glob_arr_rec_st_invoicedetl[glob_i].line_total_amt 
			ELSE 
				LET l_arr_rec_invoicedetl[glob_i].line_total_amt = glob_arr_rec_st_invoicedetl[glob_i].unit_sale_amt * glob_arr_rec_st_invoicedetl[glob_i].ship_qty 
			END IF 
		END FOR 

		CALL set_count(glob_arr_size) 
		INITIALIZE glob_rec_invoicedetl.* TO NULL 
		
		LET glob_rec_invoicedetl.ware_code = glob_rec_warehouse.ware_code 
		LET glob_rec_invoicedetl.level_code = glob_rec_stnd_parms.level_code 
		LET glob_ans = "Y" 
	END IF 

	DISPLAY BY NAME 
		glob_rec_invoicehead.inv_date, 
		glob_rec_invoicehead.entry_code, 
		glob_rec_invoicehead.year_num, 
		glob_rec_invoicehead.period_num, 
		glob_rec_warehouse.ware_code, 
		glob_rec_invoicehead.tax_code, 
		glob_rec_invoicehead.currency_code, 
		glob_rec_invoicehead.conv_qty, 
		glob_rec_invoicehead.goods_amt, 
		glob_rec_invoicehead.tax_amt, 
		glob_rec_invoicehead.total_amt, 
		glob_rec_invoicedetl.level_code 

	DISPLAY glob_rec_invoicehead.currency_code TO formonly.currency_code 
	DISPLAY glob_rec_warehouse.desc_text TO warehouse.desc_text
	DISPLAY glob_rec_tax.desc_text TO tax.desc_text

	MESSAGE "Enter in invoice details, CTRL-F companion products"	attribute (yellow) 

	INPUT ARRAY l_arr_rec_invoicedetl 
	WITHOUT DEFAULTS FROM sr_invoicedetl.* ATTRIBUTE(UNBUFFERED, delete row = false) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","A2Sb","inp-arr-invoicedetl")
			 
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			# SET up ARRAY variables
			LET glob_idx = arr_curr() 
			LET glob_firstime = 1 
			LET l_last_window = 0 
			LET glob_part_code = l_arr_rec_invoicedetl[glob_idx].part_code 

		ON ACTION "LOOKUP" infield (part_code) 
					LET l_arr_rec_invoicedetl[glob_idx].part_code = show_item(glob_rec_kandoouser.cmpy_code) 
					#DISPLAY l_arr_rec_invoicedetl[glob_idx].part_code
					#    TO sr_invoicedetl[scrn].part_code
					# IF adding the last line AND using a window THEN flag
					LET l_last_window = 1 
					NEXT FIELD part_code 


			# control-f can only be used on a CLEAR line because OTHERWISE
			#    you must keep track of both INPUT arrays, AND indexes TO do a
			#    manual add INTO the ORDER array
		ON KEY (control-f) infield (part_code) 
				IF glob_idx > 1 THEN 
					IF l_arr_rec_invoicedetl[glob_idx].part_code IS NOT NULL THEN 
						ERROR "You can only get companion products on a CLEAR line" 
						SLEEP 2 
					ELSE 
						SELECT * 
						INTO glob_rec_product.* 
						FROM product 
						WHERE part_code = l_arr_rec_invoicedetl[glob_idx-1].part_code 
						AND cmpy_code = glob_rec_kandoouser.cmpy_code 
						IF status = NOTFOUND THEN 
							ERROR kandoomsg2("A",9119,"") 							#9119 Product NOT found - Try Window
							LET l_arr_rec_invoicedetl[glob_idx].part_code = " " 

							NEXT FIELD part_code 
						END IF 

						IF glob_rec_product.compn_part_code IS NULL THEN 
							MESSAGE " No companion products available " 
							SLEEP 2 
							MESSAGE "ESC-finish invoice, CTRL-F companion products" 
							attribute (yellow) 
						ELSE 
							LET glob_rec_invoicedetl.ware_code = glob_rec_warehouse.ware_code 
							LET glob_rec_invoicedetl.level_code = glob_rec_stnd_parms.level_code 
							CALL check_comp() RETURNING modu_found_it 
							IF modu_found_it = "N" THEN 
								MESSAGE " No companion products available " 
								SLEEP 2 
								MESSAGE "ESC-finish invoice, CTRL-F companion products" 
								attribute (yellow) 
							ELSE 
								LET modu_temp_cnt = arr_count() 
								CALL set_count(modu_idx4) 
								LET l_arr_rec_invoicedetl[glob_idx].part_code = display_comp() 
								CALL set_count(modu_temp_cnt) 
								#DISPLAY l_arr_rec_invoicedetl[glob_idx].part_code
								#    TO sr_invoicedetl[scrn].part_code
							END IF 
						END IF 
					END IF 
				ELSE 
					ERROR "No product currently selected" 
				END IF 


		AFTER FIELD part_code 
			IF l_arr_rec_invoicedetl[glob_idx].part_code IS NOT NULL THEN 
				SELECT * 
				INTO glob_rec_product.* 
				FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = l_arr_rec_invoicedetl[glob_idx].part_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("A",9119,"") 			#9119 Product NOT found - Try Window
					NEXT FIELD part_code 
				END IF 
				
				IF glob_rec_product.status_ind = "2" THEN 
					ERROR kandoomsg2("A",9146,"") 			#9146 Product IS on hold - Release before proceeding
					NEXT FIELD part_code 
				END IF 
				
				IF glob_rec_product.status_ind = "3" THEN 
					ERROR kandoomsg2("A",9147,"") 			#9147 Product IS marked FOR deletion - Unmark before proceeding
					NEXT FIELD part_code 
				END IF 
				
				SELECT * 
				INTO glob_rec_prodstatus.* 
				FROM prodstatus 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = l_arr_rec_invoicedetl[glob_idx].part_code 
				AND ware_code = glob_rec_warehouse.ware_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("A",9148,"") 				#9148 Productstatus FOR selected warehouse NOT found
					NEXT FIELD part_code 
				END IF 
				
				IF glob_rec_prodstatus.status_ind = "2" THEN 
					ERROR kandoomsg2("A",9146,"") 				#9146 Product IS on hold - Release before proceeding
					NEXT FIELD part_code 
				END IF 
				
				IF glob_rec_prodstatus.status_ind = "3" THEN 
					ERROR kandoomsg2("A",9147,"") 				#9147 Product IS marked FOR deletion - Unmark before proceeding
					NEXT FIELD part_code 
				END IF 
			END IF 

			IF glob_part_code = l_arr_rec_invoicedetl[glob_idx].part_code	OR 
			(glob_part_code IS NULL AND l_arr_rec_invoicedetl[glob_idx].part_code IS null) THEN 
			ELSE 
				NEXT FIELD ship_qty 
			END IF 

		BEFORE FIELD ship_qty 
			LET glob_part_code = NULL 

			# IF new product THEN initialise the DISPLAY line
			# this "if" IS this way around because of NULL "if" compares
			# ----change it AT your own peril .....
			IF glob_show_inv_det = "N" AND 
			(glob_arr_rec_st_invoicedetl[glob_idx].part_code = l_arr_rec_invoicedetl[glob_idx].part_code 
			OR (glob_arr_rec_st_invoicedetl[glob_idx].part_code IS NULL 
			AND l_arr_rec_invoicedetl[glob_idx].part_code IS null)) THEN 
				# IF the same product THEN SELECT previous entry....
				LET glob_rec_invoicedetl.* = glob_arr_rec_st_invoicedetl[glob_idx].* 
			ELSE 
				IF glob_arr_rec_st_invoicedetl[glob_idx].part_code matches l_arr_rec_invoicedetl[glob_idx].part_code THEN
				#? 
				ELSE 
					LET glob_rec_invoicedetl.part_code = l_arr_rec_invoicedetl[glob_idx].part_code 
					LET glob_rec_invoicedetl.ware_code = glob_rec_warehouse.ware_code 
					LET glob_rec_invoicedetl.level_code = glob_rec_stnd_parms.level_code 
					LET glob_rec_invoicedetl.ship_qty = 0 
					LET glob_rec_invoicedetl.line_text = NULL 
					LET glob_rec_invoicedetl.unit_sale_amt = 0 
					LET glob_rec_invoicedetl.unit_tax_amt = 0 
					LET glob_rec_invoicedetl.line_total_amt = 0 
				END IF 

				IF glob_show_inv_det = "Y" THEN 
					LET glob_rec_invoicedetl.part_code = glob_arr_rec_st_invoicedetl[glob_idx].part_code 
					LET glob_rec_invoicedetl.ship_qty = glob_arr_rec_st_invoicedetl[glob_idx].ship_qty 
					LET glob_rec_invoicedetl.line_text = glob_arr_rec_st_invoicedetl[glob_idx].line_text 
					LET glob_rec_invoicedetl.level_code = glob_arr_rec_st_invoicedetl[glob_idx].level_code 
					LET glob_rec_invoicedetl.unit_sale_amt = 
					glob_arr_rec_st_invoicedetl[glob_idx].unit_sale_amt 
					LET glob_rec_invoicedetl.line_total_amt = 
					glob_arr_rec_st_invoicedetl[glob_idx].line_total_amt 
				END IF 
			END IF 
			IF glob_rec_invoicedetl.part_code IS NOT NULL THEN 
				SELECT * 
				INTO glob_rec_product.* 
				FROM product 
				WHERE product.part_code = glob_rec_invoicedetl.part_code 
				AND product.cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("A",9119,"") 				#9119 Product NOT found - Try Window
					LET l_arr_rec_invoicedetl[glob_idx].part_code = " " 
					NEXT FIELD part_code 
				END IF 
				
				LET l_cnt = 0 
				WHILE l_cnt <> 20 
					IF glob_rec_product.super_part_code IS NOT NULL THEN 
						SELECT * 
						INTO glob_rec_prodstatus.* 
						FROM prodstatus 
						WHERE part_code = glob_rec_product.super_part_code 
						AND ware_code = glob_rec_invoicedetl.ware_code 
						AND cmpy_code = glob_rec_kandoouser.cmpy_code 
						IF status = NOTFOUND THEN 
							ERROR " This product IS no longer stocked " 
							SLEEP 2 
							LET l_arr_rec_invoicedetl[glob_idx].part_code = " " 
							NEXT FIELD part_code 
						ELSE 
							SELECT * 
							INTO l_rec_product.* 
							FROM product 
							WHERE part_code = glob_rec_product.super_part_code 
							AND cmpy_code = glob_rec_kandoouser.cmpy_code 

							IF l_rec_product.super_part_code IS NULL THEN 
								MESSAGE " Superceded stock item, replaced by ",	glob_rec_product.super_part_code 
								SLEEP 3 
								MESSAGE "ESC TO complete ORDER, ", 	"CTRL-F companion products"		attribute (yellow) 
								LET l_arr_rec_invoicedetl[glob_idx].part_code = glob_rec_product.super_part_code 
								#DISPLAY l_arr_rec_invoicedetl[glob_idx].part_code
								#   TO sr_invoicedetl[scrn].part_code
								NEXT FIELD part_code 
							ELSE 
								LET glob_rec_product.* = l_rec_product.* 
								LET l_cnt = l_cnt + 1 
							END IF 
						END IF 
					ELSE 
						EXIT WHILE 
					END IF 
				END WHILE 

				IF l_cnt = 20 THEN 
					ERROR " Supercession limit exceeded " 
					SLEEP 2 
					LET l_arr_rec_invoicedetl[glob_idx].part_code = " " 
					#DISPLAY l_arr_rec_invoicedetl[glob_idx].part_code
					#    TO sr_invoicedetl[scrn].part_code
					NEXT FIELD part_code 
				END IF 
				
				IF glob_rec_product.alter_part_code IS NOT NULL THEN 
					SELECT * 
					INTO glob_rec_prodstatus.* 
					FROM prodstatus 
					WHERE part_code = glob_rec_invoicedetl.part_code 
					AND ware_code = glob_rec_invoicedetl.ware_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					IF (status = NOTFOUND) THEN 
						CALL check_alternate() 
						RETURNING modu_found_it 
				
						IF modu_found_it <> "N" THEN 
							IF modu_found_it = "M" THEN 
								LET modu_temp_cnt = arr_count() 
								CALL set_count(modu_idx4) 
								LET l_arr_rec_invoicedetl[glob_idx].part_code = display_alternates() 
								CALL set_count(modu_temp_cnt) 
								#DISPLAY l_arr_rec_invoicedetl[glob_idx].part_code
								#    TO sr_invoicedetl[scrn].part_code
								NEXT FIELD part_code 
							ELSE 
								CALL alt_option(l_ans1) RETURNING l_ans1 
								IF l_ans1 = "y" THEN 
									LET l_arr_rec_invoicedetl[glob_idx].part_code = 
									glob_rec_product.alter_part_code 
									#DISPLAY l_arr_rec_invoicedetl[glob_idx].part_code
									#   TO sr_invoicedetl[scrn].part_code
									NEXT FIELD part_code 
								END IF 
							END IF 
				
						ELSE 
				
							ERROR "Product NOT AT warehouse" 
							LET l_arr_rec_invoicedetl[glob_idx].part_code = " " 
							#DISPLAY l_arr_rec_invoicedetl[glob_idx].part_code TO
							#             sr_invoicedetl[scrn].part_code
							NEXT FIELD part_code 
						END IF 
					ELSE 

						CALL db_opparms_get_rec(UI_OFF,"1") RETURNING glob_rec_opparms.*
						IF glob_rec_opparms.key_num IS NULL AND glob_rec_opparms.cmpy_code IS NULL THEN 
							LET l_cal_available_flag = "N" 
						ELSE 
							LET l_cal_available_flag = glob_rec_opparms.cal_available_flag 
						END IF 

						IF l_cal_available_flag = "N" THEN 
							LET glob_available = glob_rec_prodstatus.onhand_qty 
							- glob_rec_prodstatus.reserved_qty 
							- glob_rec_prodstatus.back_qty 
							- glob_rec_invoicedetl.ship_qty 
						ELSE 
							LET glob_available = glob_rec_prodstatus.onhand_qty 
							- glob_rec_prodstatus.reserved_qty 
							- glob_rec_invoicedetl.ship_qty 
						END IF 
				
						IF glob_available <= 0 THEN 
							CALL check_alternate()	RETURNING modu_found_it 
				
							IF modu_found_it <> "N" THEN 
								CALL alt_option(l_ans1) RETURNING l_ans1 
								IF l_ans1 = "y" THEN 
									IF modu_found_it = "M" THEN 
										LET modu_temp_cnt = arr_count() 
										CALL set_count(modu_idx4) 
										LET l_arr_rec_invoicedetl[glob_idx].part_code = display_alternates() 
										CALL set_count(modu_temp_cnt) 
										#DISPLAY l_arr_rec_invoicedetl[glob_idx].part_code TO
										#          sr_invoicedetl[scrn].part_code
										NEXT FIELD part_code 
									ELSE 
										LET l_arr_rec_invoicedetl[glob_idx].part_code = 
										glob_rec_product.alter_part_code 
										#DISPLAY l_arr_rec_invoicedetl[glob_idx].part_code TO
										#        sr_invoicedetl[scrn].part_code
										NEXT FIELD part_code 
									END IF 
								END IF 
							END IF 
						END IF 
					END IF 
				END IF 
			END IF 

			# take off the current line FROM invoice totals
			IF glob_firstime = 1 THEN 
				CALL minusline() 
				LET glob_firstime = 0 
			END IF 

			# pop up the window AND get the info...
			LET glob_tot_lines = arr_count() 
			CALL inv_window() 
			RETURNING l_del_flag 

			# check TO see IF interrupt hit
			# add line back TO header totals (deleted before call)
			IF l_del_flag THEN 
				LET l_arr_rec_invoicedetl[glob_idx].part_code = 
				glob_arr_rec_st_invoicedetl[glob_idx].part_code 
				#DISPLAY l_arr_rec_invoicedetl[glob_idx].part_code TO
				#   sr_invoicedetl[scrn].part_code
				LET glob_part_code = l_arr_rec_invoicedetl[glob_idx].part_code 
				CALL plusline() 
				NEXT FIELD part_code 
			END IF 

			CURRENT WINDOW IS wa2s 

			# did we RETURN with a problem
			IF glob_nxtfld = 1 THEN 
				LET l_arr_rec_invoicedetl[glob_idx].part_code = NULL 
				#DISPLAY l_arr_rec_invoicedetl[glob_idx].part_code TO
				#   sr_invoicedetl[scrn].part_code
				NEXT FIELD part_code 
			ELSE 
				LET glob_nxtfld = 0 
				# SET up the stored line
				CALL set_invoicedetl() 
				# SET up the SCREEN ARRAY line FROM the window
				LET l_arr_rec_invoicedetl[glob_idx].part_code = glob_arr_rec_st_invoicedetl[glob_idx].part_code 
				LET l_arr_rec_invoicedetl[glob_idx].ship_qty = glob_arr_rec_st_invoicedetl[glob_idx].ship_qty 
				
				IF l_arr_rec_invoicedetl[glob_idx].ship_qty = 0 THEN 
					LET l_arr_rec_invoicedetl[glob_idx].ship_qty = NULL 
				END IF 
				
				LET l_arr_rec_invoicedetl[glob_idx].line_text = glob_arr_rec_st_invoicedetl[glob_idx].line_text 
				LET l_arr_rec_invoicedetl[glob_idx].unit_sale_amt =	glob_arr_rec_st_invoicedetl[glob_idx].unit_sale_amt 
				
				IF l_arr_rec_invoicedetl[glob_idx].unit_sale_amt = 0 THEN 
					LET l_arr_rec_invoicedetl[glob_idx].unit_sale_amt = NULL 
				END IF 
				
				LET l_arr_rec_invoicedetl[glob_idx].line_total_amt =	glob_arr_rec_st_invoicedetl[glob_idx].line_total_amt 
				IF l_arr_rec_invoicedetl[glob_idx].line_total_amt = 0 THEN 
					LET l_arr_rec_invoicedetl[glob_idx].line_total_amt = NULL 
				END IF 

				IF glob_rec_arparms.show_tax_flag = "Y" THEN 
					#DISPLAY l_arr_rec_invoicedetl[glob_idx].part_code TO
					#                             sr_invoicedetl[scrn].part_code
					#DISPLAY l_arr_rec_invoicedetl[glob_idx].ship_qty TO
					#                             sr_invoicedetl[scrn].ship_qty
					#DISPLAY l_arr_rec_invoicedetl[glob_idx].line_text TO
					#                             sr_invoicedetl[scrn].line_text
					#DISPLAY l_arr_rec_invoicedetl[glob_idx].unit_sale_amt TO
					#                             sr_invoicedetl[scrn].unit_sale_amt
					#DISPLAY l_arr_rec_invoicedetl[glob_idx].line_total_amt TO
					#                             sr_invoicedetl[scrn].line_total_amt
				ELSE 
					LET l_ext_price = l_arr_rec_invoicedetl[glob_idx].ship_qty * 
					l_arr_rec_invoicedetl[glob_idx].unit_sale_amt 
					#DISPLAY l_arr_rec_invoicedetl[glob_idx].part_code TO
					#                             sr_invoicedetl[scrn].part_code
					#DISPLAY l_arr_rec_invoicedetl[glob_idx].ship_qty TO
					#                             sr_invoicedetl[scrn].ship_qty
					#DISPLAY l_arr_rec_invoicedetl[glob_idx].line_text TO
					#                             sr_invoicedetl[scrn].line_text
					#DISPLAY l_arr_rec_invoicedetl[glob_idx].unit_sale_amt TO
					#                             sr_invoicedetl[scrn].unit_sale_amt
					#DISPLAY l_ext_price TO sr_invoicedetl[scrn].line_total_amt
				END IF 
			END IF 

			LET l_arr_rec_v_invoicedetl[glob_idx].* = l_arr_rec_invoicedetl[glob_idx].* 
			LET l_ins_flag = 1 
			NEXT FIELD line_total_amt
			 
		ON KEY (F2) #DELETE 
			CALL minusline() 
			
			# put stock back in warehouse
			LET l_which = TRAN_TYPE_INVOICE_IN 
			LET glob_rec_invoicedetl.seq_num = stat_res(
				glob_rec_kandoouser.cmpy_code, 
				glob_arr_rec_st_invoicedetl[glob_idx].ware_code, 
				glob_arr_rec_st_invoicedetl[glob_idx].part_code, 
				glob_arr_rec_st_invoicedetl[glob_idx].ship_qty, 
				l_which) 
			
			# take row out of stored ARRAY - do NOT move l_acount=arr_count
			# as arr_count can alter without entering a BEFORE ROW-
			LET l_acount = arr_count() 
			FOR j = glob_idx TO (l_acount - 1) 
				LET glob_arr_rec_st_invoicedetl[j].* = glob_arr_rec_st_invoicedetl[j+1].* 
				LET l_arr_rec_invoicedetl[j].* = l_arr_rec_invoicedetl[j+1].* 
				LET l_arr_rec_v_invoicedetl[j].* = l_arr_rec_invoicedetl[j+1].* 
			END FOR 
			
			INITIALIZE glob_arr_rec_st_invoicedetl[l_acount].* TO NULL 
			INITIALIZE l_arr_rec_invoicedetl[l_acount].* TO NULL 
			# now redraw the SCREEN
			CALL set_count(l_acount - 1) 
			#LET scrn1 = scrn
			#LET fv_scrn_idx = glob_idx + (3 - scrn)
			#FOR glob_i = glob_idx TO fv_scrn_idx
			#    IF glob_rec_arparms.show_tax_flag = "Y" THEN
			#        DISPLAY l_arr_rec_invoicedetl[glob_i].part_code TO
			#           sr_invoicedetl[scrn1].part_code
			#        DISPLAY l_arr_rec_invoicedetl[glob_i].ship_qty TO
			#           sr_invoicedetl[scrn1].ship_qty
			#        DISPLAY l_arr_rec_invoicedetl[glob_i].line_text TO
			#           sr_invoicedetl[scrn1].line_text
			#        DISPLAY l_arr_rec_invoicedetl[glob_i].unit_sale_amt TO
			#           sr_invoicedetl[scrn1].unit_sale_amt
			#        DISPLAY l_arr_rec_invoicedetl[glob_i].line_total_amt TO
			#           sr_invoicedetl[scrn1].line_total_amt
			#    ELSE
			#        LET l_ext_price = l_arr_rec_invoicedetl[glob_idx].ship_qty *
			#                        l_arr_rec_invoicedetl[glob_idx].unit_sale_amt
			#        DISPLAY l_arr_rec_invoicedetl[glob_i].part_code TO
			#           sr_invoicedetl[scrn1].part_code
			#        DISPLAY l_arr_rec_invoicedetl[glob_i].ship_qty TO
			#           sr_invoicedetl[scrn1].ship_qty
			#        DISPLAY l_arr_rec_invoicedetl[glob_i].line_text TO
			#           sr_invoicedetl[scrn1].line_text
			#        DISPLAY l_arr_rec_invoicedetl[glob_i].unit_sale_amt TO
			#           sr_invoicedetl[scrn1].unit_sale_amt
			#        DISPLAY l_ext_price TO
			#           sr_invoicedetl[scrn1].line_total_amt
			#    END IF
			#    LET scrn1 = scrn1 + 1
			#END FOR
			#LET glob_part_code = l_arr_rec_invoicedetl[glob_idx].part_code

		BEFORE INSERT 
			# add room FOR line in array
			LET l_acount = arr_count() 
			--INITIALIZE glob_arr_rec_st_invoicedetl[glob_idx].* TO NULL 
			 
			
		AFTER ROW 
			# reconcile tax (total tax calculation)
			IF glob_arr_rec_st_invoicedetl[glob_idx].part_code != l_arr_rec_v_invoicedetl[glob_idx].part_code 
			OR glob_arr_rec_st_invoicedetl[glob_idx].ship_qty != l_arr_rec_v_invoicedetl[glob_idx].ship_qty 
			OR glob_arr_rec_st_invoicedetl[glob_idx].unit_sale_amt != l_arr_rec_v_invoicedetl[glob_idx].unit_sale_amt 
			OR glob_arr_rec_st_invoicedetl[glob_idx].line_total_amt != l_arr_rec_v_invoicedetl[glob_idx].line_total_amt THEN 

				IF glob_arr_rec_st_invoicedetl[glob_idx].line_total_amt IS NOT NULL THEN 
					IF glob_rec_tax.calc_method_flag = "T" THEN {invoice total tax} 
						LET glob_tot_lines = arr_count() 

						#LET l_start_idx = glob_idx - (scrn - 1)
						CALL find_taxcode(glob_rec_invoicedetl.tax_code) RETURNING l_tax_idx 
						LET glob_arr_rec_taxamt[l_tax_idx].tax_amt = glob_rec_invoicehead.freight_tax_amt	+ glob_rec_invoicehead.hand_tax_amt 
						LET glob_rec_invoicehead.goods_amt = 0 
						LET glob_rec_invoicehead.tax_amt = 0 

						IF glob_rec_invoicehead.tax_amt IS NULL THEN 
							LET glob_rec_invoicehead.tax_amt = 0 
						END IF 

						LET glob_rec_invoicehead.cost_amt = 0 
						LET glob_rec_invoicehead.total_amt = 0 

						FOR x = 1 TO glob_tot_lines 
							IF glob_arr_rec_st_invoicedetl[x].line_total_amt IS NOT NULL THEN 
								LET l_saved_tot = glob_arr_rec_st_invoicedetl[x].line_total_amt 
								CALL find_tax(
									glob_rec_invoicehead.tax_code, 
									glob_arr_rec_st_invoicedetl[x].part_code, 
									glob_arr_rec_st_invoicedetl[x].ware_code, 
									glob_tot_lines, 
									x, 
									glob_arr_rec_st_invoicedetl[x].unit_sale_amt, 
									glob_arr_rec_st_invoicedetl[x].ship_qty, 
									"L", 
									"", 
									"") 
								RETURNING 
									glob_arr_rec_st_invoicedetl[x].ext_sale_amt, 
									glob_arr_rec_st_invoicedetl[x].unit_tax_amt, 
									glob_arr_rec_st_invoicedetl[x].ext_tax_amt, 
									glob_arr_rec_st_invoicedetl[x].line_total_amt, 
									glob_arr_rec_st_invoicedetl[x].tax_code 
								
								CALL plusln(x) 
								
								IF x = glob_idx THEN 
									IF l_ins_flag THEN 
										CALL minusline() {gets added later on} 
									END IF 
								END IF 
								
								IF l_saved_tot != glob_arr_rec_st_invoicedetl[x].line_total_amt THEN 
									IF glob_rec_arparms.show_tax_flag = "Y" THEN 
										IF x >= l_start_idx 
										# Because the SCREEN ARRAY IS only 7
										# THEN the DISPLAY l_pos has TO be <= 7 OTHERWISE
										# the program falls over.
										AND x <= (l_start_idx + 6 ) THEN 
											#LET l_pos = scrn - (glob_idx - x)
											DISPLAY glob_arr_rec_st_invoicedetl[x].line_total_amt TO 
											sr_invoicedetl[l_pos].line_total_amt 
										END IF 
									END IF 
								END IF 
							END IF 
						END FOR 
					END IF 
				END IF 
			END IF 

			# adjust header totals
			IF l_ins_flag = 1 THEN 
				CALL plusline() 
				LET l_ins_flag = 0 
			END IF 
			MESSAGE "ESC-finish invoice, CTRL-F companion products"		attribute (yellow) 
			INITIALIZE glob_rec_invoicedetl.* TO NULL 

		AFTER INPUT 
			LET glob_arr_size = arr_count() 
			
			# in CASE window used on last line THEN arr_count IS 1 too low
			IF l_last_window = 1 AND glob_idx > glob_arr_size THEN 
				LET glob_arr_size = glob_arr_size + 1 
			END IF 
			
			# in CASE blank lines AT bottom of SCREEN - adjust number of lines
			IF glob_arr_size > 0 THEN 
				WHILE (l_arr_rec_invoicedetl[glob_arr_size].part_code IS NULL 
					AND l_arr_rec_invoicedetl[glob_arr_size].line_text IS NULL 
					AND (l_arr_rec_invoicedetl[glob_arr_size].line_total_amt = 0 OR 
					l_arr_rec_invoicedetl[glob_arr_size].line_total_amt IS null)) 
					LET glob_arr_size = glob_arr_size - 1 
					IF glob_arr_size = 0 THEN 
						EXIT WHILE 
					END IF 
				END WHILE 
				
				IF glob_arr_size = modu_save_idx THEN 
					LET glob_ins_line = 0 
				ELSE 
					LET glob_ins_line = 1 
				END IF 
				
				IF glob_arr_size = 0 THEN 
					LET glob_edit_line = 0 
				ELSE 
					LET glob_edit_line = 1 
				END IF 
			END IF 
			
			IF glob_arr_size = 0 THEN 
				IF int_flag = 0 THEN 
					ERROR " Invoice must have lines TO continue" 
					SLEEP 3 
					LET int_flag = 1 
				END IF 
			END IF 
	END INPUT 
	
	OPTIONS DELETE KEY f2 
	# has interrupt OR quit been hit
	IF int_flag OR quit_flag THEN 

		CALL windecoration_u("U999") 
		LET glob_ans = promptYN("Line Information","Do you wish TO hold line information?","Y") 

		LET glob_ans = upshift(glob_ans) 
		LET glob_arr_size = arr_count() 
		IF glob_ans = "Y" THEN 
			LET glob_ans = "C" 
			LET glob_show_inv_det = "N" 
		ELSE 
			LET glob_ans = "N" 
			LET glob_first_time = 1 
		END IF 
	END IF 

	RETURN 
END FUNCTION 
###########################################################################
# END FUNCTION lineitem() 
###########################################################################


############################################################
# FUNCTION alt_option(p_ans1) 
#
#
############################################################
FUNCTION alt_option(p_ans1) 
	DEFINE p_ans1 CHAR(1) 

	LET p_ans1 = promptYN("Choose alternate","Product NOT currently stocked - choose alternate?","Y") 
	LET p_ans1 = downshift(p_ans1) 

	RETURN p_ans1 
END FUNCTION 
############################################################
# END FUNCTION alt_option(p_ans1) 
############################################################


############################################################
# FUNCTION check_alternate()
#
#
############################################################
FUNCTION check_alternate() 
	DEFINE l_rec_s_product RECORD LIKE product.*
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.* 


	FOR glob_i = 1 TO 50 
		INITIALIZE modu_arr_rec_product[glob_i].part_code TO NULL 
		INITIALIZE modu_arr_rec_product[glob_i].desc_text TO NULL 
		INITIALIZE modu_arr_rec_product[glob_i].available TO NULL 
	END FOR 

	SELECT * 
	INTO l_rec_s_product.* 
	FROM product 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = glob_rec_product.alter_part_code 
	AND part_code <> glob_rec_product.part_code 

	IF status = NOTFOUND THEN 
		DECLARE prodcurs CURSOR FOR 
		SELECT * 
		INTO l_rec_s_product.* 
		FROM product 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND alter_part_code = glob_rec_product.alter_part_code 
		AND part_code <> glob_rec_product.part_code 
		LET modu_idx4 = 0 

		FOREACH prodcurs 
			SELECT * 
			INTO l_rec_prodstatus.* 
			FROM prodstatus 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = l_rec_s_product.part_code 
			AND ware_code = glob_rec_invoicedetl.ware_code 

			IF status = NOTFOUND THEN 
			ELSE 
				SELECT * 
				INTO glob_rec_opparms.* 
				FROM opparms 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND key_num = "1" 

				IF status = NOTFOUND THEN 
					CALL fgl_winmessage("ERROR", "Parmaters RECORD NOT found, Maintain Menu EZP!\nExit Program","ERROR") #HuHo 2.12.2020: Was "OZP" which we haven't got and I changed it to "EZP"
					EXIT PROGRAM 
				END IF 

				IF glob_rec_opparms.cal_available_flag = "N" THEN 
					LET glob_available = 
						l_rec_prodstatus.onhand_qty 
						-l_rec_prodstatus.reserved_qty 
						-l_rec_prodstatus.back_qty 
				ELSE 
					LET glob_available = l_rec_prodstatus.onhand_qty	- l_rec_prodstatus.reserved_qty 
				END IF 

				IF glob_available > 0 THEN 
					LET modu_idx4 = modu_idx4 + 1 
					LET modu_arr_rec_product[modu_idx4].part_code = l_rec_s_product.part_code 
					LET modu_arr_rec_product[modu_idx4].desc_text = l_rec_s_product.desc_text 
					LET modu_arr_rec_product[modu_idx4].available = glob_available 
				END IF 
			END IF 
		END FOREACH 
		IF modu_idx4 > 0 THEN 
			LET modu_found_it = "M" 
		ELSE 
			LET modu_found_it = "N" 
		END IF 
	ELSE 
		SELECT * 
		INTO l_rec_prodstatus.* 
		FROM prodstatus 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = l_rec_s_product.part_code 
		AND ware_code = glob_rec_invoicedetl.ware_code 

		IF status = NOTFOUND THEN 
			LET modu_found_it = "N" 
		ELSE 
			IF glob_rec_opparms.cal_available_flag = "N" THEN 
				LET glob_available = l_rec_prodstatus.onhand_qty 
					-l_rec_prodstatus.reserved_qty 
					-l_rec_prodstatus.back_qty 
					-glob_rec_invoicedetl.ship_qty 
			ELSE 
				LET glob_available = l_rec_prodstatus.onhand_qty 
					- l_rec_prodstatus.reserved_qty 
					- glob_rec_invoicedetl.ship_qty 
			END IF 

			IF glob_available > 0 THEN 
				LET modu_found_it = "S" 
			ELSE 
				LET modu_found_it = "N" 
			END IF 
		END IF 
	END IF 

	# "found" has three different VALUES returned FROM this FUNCTION
	#    = N signifies that no alternate products were found
	#    = M means that more than one alternate product was found so you must
	#        LET the user determine l_which product they wish use
	#    = S means that only one alternate product was found - so just use that one
	RETURN modu_found_it 
END FUNCTION 
############################################################
# END FUNCTION check_alternate()
############################################################


############################################################
# FUNCTION check_comp() 
#
#
############################################################
FUNCTION check_comp() 
	DEFINE ps_product RECORD LIKE product.*
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.* 

	CALL db_opparms_get_rec(UI_OFF,"1") RETURNING glob_rec_opparms.*
	IF glob_rec_opparms.key_num IS NULL AND glob_rec_opparms.cmpy_code IS NULL THEN 
		CALL fgl_winmessage("Configuration Error - Operational Parameters missing (Program EZP)",kandoomsg2("E",5003,""),"ERROR") #HuHo 2.12.2020: Was "OZP" which we haven't got and I changed it to "EZP"
		EXIT PROGRAM 
	END IF 
	
	FOR glob_i = 1 TO 50 
		INITIALIZE modu_arr_rec_product[glob_i].part_code TO NULL 
		INITIALIZE modu_arr_rec_product[glob_i].desc_text TO NULL 
		INITIALIZE modu_arr_rec_product[glob_i].available TO NULL 
	END FOR 

	SELECT * 
	INTO ps_product.* 
	FROM product 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = glob_rec_product.compn_part_code 
	AND part_code <> glob_rec_product.part_code 

	IF status = NOTFOUND THEN 
		DECLARE prod1curs CURSOR FOR 
		SELECT * 
		INTO ps_product.* 
		FROM product 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND compn_part_code = glob_rec_product.compn_part_code 
		AND part_code <> glob_rec_product.part_code 

		LET modu_idx4 = 0 
		FOREACH prod1curs 
			SELECT * 
			INTO l_rec_prodstatus.* 
			FROM prodstatus 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = ps_product.part_code 
			AND ware_code = glob_rec_invoicedetl.ware_code 

			IF status = NOTFOUND THEN 
			ELSE 
				IF glob_rec_opparms.cal_available_flag = "N" THEN 
					LET glob_available = l_rec_prodstatus.onhand_qty 
					-l_rec_prodstatus.reserved_qty 
					-l_rec_prodstatus.back_qty 
				ELSE 
					LET glob_available = l_rec_prodstatus.onhand_qty 
					- l_rec_prodstatus.reserved_qty 
				END IF 

				LET modu_idx4 = modu_idx4 + 1 
				LET modu_arr_rec_product[modu_idx4].part_code = ps_product.part_code 
				LET modu_arr_rec_product[modu_idx4].desc_text = ps_product.desc_text 
				LET modu_arr_rec_product[modu_idx4].available = glob_available 
			END IF 
		END FOREACH 
		IF modu_idx4 > 0 THEN 
			LET modu_found_it = "Y" 
		ELSE 
			LET modu_found_it = "N" 
		END IF 
	ELSE 
		SELECT * 
		INTO l_rec_prodstatus.* 
		FROM prodstatus 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = ps_product.part_code 
		AND ware_code = glob_rec_invoicedetl.ware_code 
		IF status = NOTFOUND THEN 
			LET modu_found_it = "N" 
		ELSE 
			IF glob_rec_opparms.cal_available_flag = "N" THEN 
				LET glob_available = l_rec_prodstatus.onhand_qty 
					-l_rec_prodstatus.reserved_qty 
					-l_rec_prodstatus.back_qty 
					-glob_rec_invoicedetl.ship_qty 
			ELSE 
				LET glob_available = l_rec_prodstatus.onhand_qty 
					- l_rec_prodstatus.reserved_qty 
					- glob_rec_invoicedetl.ship_qty 
			END IF 

			LET modu_found_it = "Y" 
			LET modu_idx4 = 1 
			LET modu_arr_rec_product[modu_idx4].part_code = ps_product.part_code 
			LET modu_arr_rec_product[modu_idx4].desc_text = ps_product.desc_text 
			LET modu_arr_rec_product[modu_idx4].available = glob_available 
		END IF 
	END IF 

	# "found" has two different VALUES returned FROM this FUNCTION
	#    = N signifies that no companion products were found
	#    = Y means that companion products were found so DISPLAY the window
	RETURN modu_found_it 
END FUNCTION 
############################################################
# END FUNCTION check_comp() 
############################################################


############################################################
# FUNCTION display_alternates()  
#
#
############################################################
FUNCTION display_alternates() 

	OPEN WINDOW A198 with FORM "A198" 
	CALL windecoration_a("A198") 

	MESSAGE " ESC on line TO SELECT product " attribute(yellow) 
	INPUT ARRAY modu_arr_rec_product WITHOUT DEFAULTS FROM sr_product.* ATTRIBUTE(UNBUFFERED) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","A2Sb","inp-arr-product-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET modu_idx4 = arr_curr() 
			#LET scrn4 = scr_line()

			IF arr_curr() > arr_count() THEN 
				ERROR "No more rows in the direction you are going" 
			END IF 
	END INPUT 

	LET modu_idx4 = arr_curr() 
	
	CLOSE WINDOW A198

	LET int_flag = 0 
	LET quit_flag = 0 
	 
	RETURN modu_arr_rec_product[modu_idx4].part_code 
END FUNCTION 
############################################################
# END FUNCTION display_alternates()  
############################################################


############################################################
# FUNCTION display_comp() 
#
#
############################################################
FUNCTION display_comp() 

	OPEN WINDOW A199 with FORM "A199" 
	CALL windecoration_a("A199") 

	MESSAGE " ESC on line TO SELECT product " attribute(yellow) 
	INPUT ARRAY modu_arr_rec_product WITHOUT DEFAULTS FROM sr_product.* ATTRIBUTE(UNBUFFERED) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","A2Sb","inp-arr-product-2") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET modu_idx4 = arr_curr() 
			#LET scrn4 = scr_line()

			IF arr_curr() > arr_count() THEN 
				ERROR "No more rows in the direction you are going" 
			END IF 
	END INPUT 

	LET modu_idx4 = arr_curr() 
	CLOSE WINDOW A199 

	IF int_flag OR quit_flag THEN 
		LET modu_arr_rec_product[modu_idx4].part_code = " " 
	END IF 

	LET int_flag = 0 
	LET quit_flag = 0 

	RETURN modu_arr_rec_product[modu_idx4].part_code 
END FUNCTION 
############################################################
# END FUNCTION display_comp() 
############################################################