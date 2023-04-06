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
GLOBALS "../common/glob_GLOBALS_report.4gl" 
GLOBALS "../eo/E_EO_GLOBALS.4gl"
GLOBALS "../eo/E5_GROUP_GLOBALS.4gl"
GLOBALS "../eo/E52_GLOBALS.4gl" 
#                FUNCTION print_pickslip()

###########################################################################
# REPORT E52_rpt_list_picklist(p_rpt_idx,p_rec_pickhead) 
#
# E52e - customized Packing Slip / Picking List Generation Program
###########################################################################
REPORT E52_rpt_list_picklist(p_rpt_idx,p_rec_pickhead) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE p_rec_pickhead RECORD LIKE pickhead.* 
	DEFINE l_rec_pickdetl RECORD LIKE pickdetl.* 
	DEFINE l_rec_orderhead RECORD LIKE orderhead.* 
	DEFINE l_rec_orderdetl RECORD LIKE orderdetl.* 
	DEFINE l_rec_carrier RECORD LIKE carrier.* 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_customerpart RECORD LIKE customerpart.* 
	DEFINE l_rec_notes RECORD LIKE notes.* 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_rec_product2 RECORD LIKE product.* 
	DEFINE l_rec_country RECORD LIKE country.* 
	DEFINE l_rec_warehouse RECORD LIKE warehouse.* 
	DEFINE l_bin_text LIKE prodstatus.bin1_text 
	DEFINE l_order_num LIKE orderhead.order_num 
	DEFINE l_note_code char(12) 
	DEFINE l_arr_address array[5] OF char(40) 
	DEFINE l_arr_ship_address array[5] OF char(30) 
	DEFINE l_arr_cust_address array[5] OF char(30) 
	DEFINE l_line array[4] OF char(109) 
	DEFINE l_desc_text char(60) 
	DEFINE i SMALLINT 
	DEFINE j SMALLINT 
	DEFINE idx SMALLINT 
	DEFINE l_query_text STRING

	OUTPUT 
 
--	top margin 1 
---	bottom margin 6 
--	PAGE length 51 
	ORDER external BY 
		p_rec_pickhead.cmpy_code, 
		p_rec_pickhead.ware_code, 
		p_rec_pickhead.pick_num 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			 
			INITIALIZE l_rec_warehouse.* TO NULL 
			INITIALIZE l_rec_orderhead.* TO NULL 
			INITIALIZE l_rec_carrier.* TO NULL 
			INITIALIZE l_rec_customer.* TO NULL 

			SELECT * INTO l_rec_warehouse.* FROM warehouse 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND ware_code = p_rec_pickhead.ware_code 

			SELECT * INTO l_rec_customer.* FROM customer 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cust_code = p_rec_pickhead.cust_code 
			DECLARE c_ordernum cursor FOR 

			SELECT order_num FROM pickdetl 
			WHERE cmpy_code = p_rec_pickhead.cmpy_code 
			AND ware_code = p_rec_pickhead.ware_code 
			AND pick_num = p_rec_pickhead.pick_num 

			OPEN c_ordernum 
			FETCH c_ordernum INTO l_order_num 
			CLOSE c_ordernum 

			SELECT * INTO l_rec_orderhead.* FROM orderhead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND order_num = l_order_num 

			SELECT * INTO l_rec_carrier.* FROM carrier 
			WHERE carrier_code = p_rec_pickhead.carrier_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 

			INITIALIZE l_rec_country.* TO NULL 
			SELECT * INTO l_rec_country.* FROM country 
			WHERE country_code = l_rec_warehouse.country_code 

			FOR j = 1 TO 5 
				INITIALIZE l_arr_address[j] TO NULL 
			END FOR 
			
			CALL pack_address(
				l_rec_warehouse.desc_text, 
				l_rec_warehouse.addr1_text, 
				l_rec_warehouse.addr2_text, 
				l_rec_warehouse.city_text, 
				l_rec_warehouse.state_code, 
				l_rec_warehouse.post_code, 
				l_rec_country.country_code) --@db-patch_2020_10_04--
			RETURNING 
				l_arr_address[1], 
				l_arr_address[2], 
				l_arr_address[3], 
				l_arr_address[4], 
				l_arr_address[5] 
			
			PRINT COLUMN 74, l_arr_address[1][1,37] 
			PRINT COLUMN 74, l_arr_address[2][1,37] 
			PRINT COLUMN 74, l_arr_address[3][1,37] 
			PRINT COLUMN 74, l_arr_address[4][1,37] 

			SKIP 1 line 
			PRINT COLUMN 10, "CHARGE to:", 

			COLUMN 43, "DOCUMENT details:", 
			COLUMN 69, "DELIVER to:"; 

			IF l_rec_orderhead.delivery_ind = "2" THEN 
				PRINT COLUMN 100, "BREAKDOWN" 
			ELSE 
				PRINT COLUMN 100, "ROUTINE" 
			END IF 

			SKIP 1 line 

			FOR j = 1 TO 5 
				INITIALIZE l_arr_ship_address[j] TO NULL 
				INITIALIZE l_arr_cust_address[j] TO NULL 
			END FOR 

			CALL pack_address(
				l_rec_customer.name_text, 
				l_rec_customer.addr1_text, 
				l_rec_customer.addr2_text, 
				l_rec_customer.city_text, 
				l_rec_customer.state_code, 
				l_rec_customer.post_code, 
				l_rec_customer.country_code) --@db-patch_2020_10_04--
			RETURNING 
				l_arr_cust_address[1], 
				l_arr_cust_address[2], 
				l_arr_cust_address[3], 
				l_arr_cust_address[4], 
				l_arr_cust_address[5] 

			CALL pack_address(
				l_rec_orderhead.ship_name_text, 
				l_rec_orderhead.ship_addr1_text, 
				l_rec_orderhead.ship_addr2_text, 
				l_rec_orderhead.ship_city_text, 
				l_rec_orderhead.state_code, 
				l_rec_orderhead.post_code, 
				l_rec_orderhead.country_code) --@db-patch_2020_10_04--
			RETURNING 
				l_arr_ship_address[1], 
				l_arr_ship_address[2], 
				l_arr_ship_address[3], 
				l_arr_ship_address[4], 
				l_arr_ship_address[5] 

			IF l_rec_customer.invoice_to_ind = "1" THEN 
				PRINT COLUMN 10, l_arr_cust_address[1]; 
			ELSE 
				PRINT COLUMN 10, l_arr_ship_address[1]; 
			END IF 

			PRINT COLUMN 43, "PICK NO: ",p_rec_pickhead.pick_num USING "<<<<<<<<", 
			COLUMN 69, l_arr_ship_address[1] 
			IF l_rec_customer.invoice_to_ind = "1" THEN 
				PRINT COLUMN 10, l_arr_cust_address[2]; 
			ELSE 
				PRINT COLUMN 10, l_arr_ship_address[2]; 
			END IF 

			PRINT COLUMN 43, "DATE: ",p_rec_pickhead.pick_date USING "dd/mm/yyyy", 
			COLUMN 69, l_arr_ship_address[2] 
			IF l_rec_customer.invoice_to_ind = "1" THEN 
				PRINT COLUMN 10, l_arr_cust_address[3]; 
			ELSE 
				PRINT COLUMN 10, l_arr_ship_address[3]; 
			END IF 

			PRINT COLUMN 43, "PAGE NO: ",glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num USING "<<<<<", 
			COLUMN 69, l_arr_ship_address[3] 
			IF l_rec_customer.invoice_to_ind = "1" THEN 
				PRINT COLUMN 10, l_arr_cust_address[4]; 
			ELSE 
				PRINT COLUMN 10, l_arr_ship_address[4]; 
			END IF 

			PRINT COLUMN 69, l_arr_ship_address[4] 
			SKIP 1 line 

			PRINT COLUMN 02, "CUSTOMER CODE: ",l_rec_orderhead.cust_code, 
			COLUMN 42, "OUR REF: ",l_rec_orderhead.order_num USING "<<<<<<<<", 
			COLUMN 79, l_rec_carrier.name_text 

			PRINT COLUMN 02, "YOUR REF: ",l_rec_orderhead.ord_text, 
			COLUMN 42, "ORDER DATE: ",l_rec_orderhead.order_date USING "dd/mm/yyyy", 
			COLUMN 79, l_rec_orderhead.ship1_text[1,30] 

			PRINT COLUMN 02, "TAX EXEMPT CERT: ",l_rec_customer.tax_num_text, 
			COLUMN 42, "WAREHOUSE: ",p_rec_pickhead.ware_code, 
			COLUMN 79, l_rec_orderhead.ship1_text[31,60] 
			SKIP 1 line 

			PRINT COLUMN 20, "PRODUCT details", 
			COLUMN 65, "QUANTITIES", 
			COLUMN 92, "LABELS" 
			SKIP 1 line 

			PRINT COLUMN 02, "LINE", 
			COLUMN 07, "PRODUCT", 
			COLUMN 27, "BIN text", 
			COLUMN 47, "UOM", 
			COLUMN 61, "ORDER", 
			COLUMN 69, "BACK", 
			COLUMN 77, "PICK", 
			COLUMN 83, "SUPPLIED" 
			SKIP 1 line 

		BEFORE GROUP OF p_rec_pickhead.ware_code 
			SKIP TO top OF PAGE 

		BEFORE GROUP OF p_rec_pickhead.pick_num 
			SKIP TO top OF PAGE 
		ON EVERY ROW 


			--DISPLAY "EXIT: disabled code because of <Anton Dickinson> ecp issue with outer" 
			--DISPLAY "see common/collwind.4gl" 
			#EXIT PROGRAM (1)
 
			LET l_query_text = 
				"SELECT pickdetl.*, prodstatus.bin1_text ", 
				" FROM pickdetl, outer prodstatus ", 
				" WHERE pickdetl.cmpy_code = ",p_rec_pickhead.cmpy_code, 
				" AND pickdetl.ware_code = ",p_rec_pickhead.ware_code, 
				" AND pickdetl.pick_num = ", p_rec_pickhead.pick_num, 
				" AND prodstatus.cmpy_code = ",p_rec_pickhead.cmpy_code, 
				" AND prodstatus.ware_code = ",p_rec_pickhead.ware_code, 
				" AND prodstatus.part_code = pickdetl.part_code", 
				" ORDER BY pickdetl.order_line_num" 

			PREPARE xxy FROM l_query_text 
			DECLARE c_pickdetl cursor FOR xxy 

			FOREACH c_pickdetl INTO l_rec_pickdetl.*, l_bin_text 
				SELECT * INTO l_rec_product.* FROM product 
				WHERE cmpy_code = p_rec_pickhead.cmpy_code 
				AND part_code = l_rec_pickdetl.part_code 

				SELECT * INTO l_rec_orderdetl.* FROM orderdetl 
				WHERE order_num = l_rec_pickdetl.order_num 
				AND line_num = l_rec_pickdetl.order_line_num 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 

				FOR i = 1 TO 4 
					INITIALIZE l_line[i] TO NULL 
				END FOR 
				NEED 4 LINES 
				LET idx = 1 

				IF l_rec_orderdetl.part_code IS NULL 
				AND l_rec_orderdetl.line_tot_amt = 0 
				AND l_rec_orderdetl.desc_text[1,3] = "###" 
				AND l_rec_orderdetl.desc_text[16,18] = "###" THEN 
					LET l_line[idx] = l_rec_pickdetl.order_line_num USING "####" 
				ELSE 
					LET l_line[idx] = 
						l_rec_pickdetl.order_line_num USING "####"," ", 
						l_rec_pickdetl.part_code," ", 
						l_bin_text," ", 
						l_rec_orderdetl.uom_code," ", 
						l_rec_orderdetl.order_qty USING "###&.&"," ", 
						l_rec_orderdetl.back_qty USING "###&.&"," ", 
						l_rec_pickdetl.picked_qty USING "####&.&"," ", 
						p_rec_pickhead.cust_code," ", 
						l_rec_pickdetl.order_num USING "########" 
				END IF 

				IF l_rec_orderdetl.part_code IS NULL THEN 
					IF l_rec_orderdetl.desc_text[1,3] = "###" 
					AND l_rec_orderdetl.desc_text[16,18] = "###" 
					AND l_rec_orderdetl.line_tot_amt = 0 THEN 
						LET l_note_code = l_rec_orderdetl.desc_text[4,15] 
						DECLARE c_notes cursor FOR 
						SELECT * INTO l_rec_notes.* FROM notes 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND note_code = l_note_code 

						LET idx = 0 
						FOREACH c_notes INTO l_rec_notes.* 
							LET idx = idx + 1 
							LET l_line[idx][6,66] = l_rec_notes.note_text 
							IF idx = 4 THEN 
								FOR i = 1 TO 4 
									PRINT COLUMN 02, l_line[i] 
									INITIALIZE l_line[i] TO NULL 
								END FOR 
								LET idx = 0 
							END IF 
						END FOREACH 

						IF (l_line[1] IS NOT NULL AND l_line[1] != " ") 
						OR (l_line[2] IS NOT NULL AND l_line[2] != " ") 
						OR (l_line[3] IS NOT NULL AND l_line[3] != " ") 
						OR (l_line[4] IS NOT NULL AND l_line[4] != " ") THEN 
							FOR i = 1 TO 4 
								PRINT COLUMN 02, l_line[i] 
								INITIALIZE l_line[i] TO NULL 
							END FOR 
						END IF 
					ELSE 
						LET idx = idx + 1 
						LET l_line[idx] = " ",l_rec_orderdetl.desc_text 
						FOR i = 1 TO 4 
							PRINT COLUMN 02, l_line[i] 
							INITIALIZE l_line[i] TO NULL 
						END FOR 
					END IF 
				ELSE 
					LET l_desc_text = l_rec_product.desc_text clipped," ",	l_rec_product.desc2_text 
					LET l_line[2] = " ",l_desc_text, 20 spaces, l_rec_pickdetl.part_code 
					
					INITIALIZE l_rec_product2.* TO NULL 
					DECLARE c_supersede cursor FOR 
					SELECT * FROM product 
					WHERE super_part_code = l_rec_product.part_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					OPEN c_supersede 
					FETCH c_supersede INTO l_rec_product2.* 
					CLOSE c_supersede 
					INITIALIZE l_rec_customerpart.* TO NULL 
					SELECT * INTO l_rec_customerpart.* FROM customerpart 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = l_rec_pickdetl.part_code 
					AND cust_code = p_rec_pickhead.cust_code 
					IF l_rec_product2.part_code IS NULL THEN 
						LET i = length(l_rec_customerpart.custpart_code) 
						LET i = (20 - i) + 36 
						LET l_line[3] = i spaces, l_rec_customerpart.custpart_code clipped,	29 spaces, l_rec_product.short_desc_text 
					ELSE 
						LET i = length(l_rec_customerpart.custpart_code) 
						LET i = (20 - i) + 4 
						LET l_line[3] = 5 spaces, "SUPERSEDES: ",l_rec_product2.part_code, 	i spaces, l_rec_customerpart.custpart_code clipped,	29 spaces, l_rec_product.short_desc_text 
					END IF 

					LET l_line[4] = 85 spaces, l_rec_customerpart.custpart_code 
					FOR i = 1 TO 4 
						PRINT COLUMN 02, l_line[i] 
						INITIALIZE l_line[i] TO NULL 
					END FOR 
					LET idx = 0 
				END IF 

				IF l_rec_orderdetl.part_code IS NOT NULL THEN 
					IF l_rec_orderdetl.desc_text[1,3] = "###" 
					AND l_rec_orderdetl.desc_text[16,18] = "###" THEN 
						LET l_note_code = l_rec_orderdetl.desc_text[4,15] 
						DECLARE c_notes2 cursor FOR 
						SELECT * INTO l_rec_notes.* FROM notes 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND note_code = l_note_code 

						FOREACH c_notes2 INTO l_rec_notes.* 
							LET idx = idx + 1 
							LET l_line[idx] = l_rec_notes.note_text 
							IF idx = 4 THEN 
								FOR i = 1 TO 4 
									PRINT COLUMN 07, l_line[i] 
									INITIALIZE l_line[i] TO NULL 
								END FOR 
								LET idx = 0 
							END IF 
						END FOREACH 
						
						IF (l_line[1] IS NOT NULL AND l_line[1] != " ") 
						OR (l_line[2] IS NOT NULL AND l_line[2] != " ") 
						OR (l_line[3] IS NOT NULL AND l_line[3] != " ") 
						OR (l_line[4] IS NOT NULL AND l_line[4] != " ") THEN 
							FOR i = 1 TO 4 
								PRINT COLUMN 07, l_line[i] 
								INITIALIZE l_line[i] TO NULL 
							END FOR 
						END IF 
					END IF 
				END IF 
			END FOREACH 
END REPORT
###########################################################################
# END REPORT E52_rpt_list_picklist(p_rpt_idx,p_rec_pickhead) 
########################################################################### 