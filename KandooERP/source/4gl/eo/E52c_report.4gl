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
REPORT E52_rpt_list_picklist(p_rpt_idx, p_rec_pickhead) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE p_rec_pickhead RECORD LIKE pickhead.* 
	DEFINE l_rec_pickdetl RECORD LIKE pickdetl.* 
	DEFINE l_rec_pick_company RECORD LIKE company.* 
	DEFINE l_rec_orderhead RECORD LIKE orderhead.* 
	DEFINE l_rec_orderdetl RECORD LIKE orderdetl.* 
	DEFINE l_notes RECORD LIKE notes.* 
	DEFINE l_note_code LIKE notes.note_code 
	DEFINE l_carr_text LIKE carrier.name_text 
	DEFINE l_sale_text LIKE salesperson.name_text 
	DEFINE l_terr_text LIKE territory.desc_text 
	DEFINE l_arr_address array[2,4] OF char(36) 
	DEFINE l_header_text_text char(40) 
	DEFINE l_lsale_text LIKE prodstatus.bin1_text 
	DEFINE l_line_text char(115) 
	DEFINE l_netwgt_qty FLOAT 
	DEFINE l_pick_ind SMALLINT
	DEFINE i SMALLINT
	DEFINE l_line_cnt SMALLINT
	DEFINE l_page_num SMALLINT
	DEFINE l_order_num LIKE orderhead.order_num 
--	DEFINE l_sel_text char(600) 
	DEFINE l_str STRING 

	OUTPUT 

	ORDER external BY 
		p_rec_pickhead.cmpy_code, 
		p_rec_pickhead.ware_code, 
		p_rec_pickhead.pick_num 
	
	FORMAT 
		PAGE HEADER 
			LET l_line_cnt = 0 
			IF pageno < 2 THEN 
				SELECT * INTO l_rec_pick_company.* 
				FROM company 
				WHERE cmpy_code = p_rec_pickhead.cmpy_code 
				LET l_arr_address[1,1] = l_rec_pick_company.addr1_text
				 
				IF l_rec_pick_company.addr2_text IS NOT NULL THEN 
					LET l_arr_address[1,2] = l_rec_pick_company.addr2_text 
					LET l_arr_address[1,3] = l_rec_pick_company.city_text[1,20]," ",l_rec_pick_company.state_code clipped," ",l_rec_pick_company.post_code clipped 
					LET l_arr_address[1,4] = l_rec_pick_company.country_code --@db-patch_2020_10_04--
				ELSE 
					LET l_arr_address[1,2] = l_rec_pick_company.city_text[1,20]," ", l_rec_pick_company.state_code clipped," ", l_rec_pick_company.post_code clipped 
					LET l_arr_address[1,3] = l_rec_pick_company.country_code --@db-patch_2020_10_04--
					LET l_arr_address[1,4] = NULL 
				END IF 
			END IF 
			
			#-------------------------------------------
			# need TO know first ORDER num of shipment
			DECLARE c_pickhead cursor FOR 
			SELECT order_num FROM pickdetl 
			WHERE cmpy_code = p_rec_pickhead.cmpy_code 
			AND ware_code = p_rec_pickhead.ware_code 
			AND pick_num = p_rec_pickhead.pick_num
			 
			OPEN c_pickhead 
			FETCH c_pickhead INTO l_order_num 
			SELECT * INTO l_rec_orderhead.* 
			FROM orderhead 
			WHERE cmpy_code = p_rec_pickhead.cmpy_code 
			AND order_num = l_order_num 
			
			LET l_arr_address[2,1] = l_rec_orderhead.ship_name_text 
			LET l_arr_address[2,2] = l_rec_orderhead.ship_addr1_text 
			
			IF l_rec_orderhead.ship_addr2_text IS NULL THEN 
				LET l_arr_address[2,3] = l_rec_orderhead.ship_city_text[1,20]," ", l_rec_orderhead.state_code," ",l_rec_orderhead.post_code 
				LET l_arr_address[2,4] = NULL 
			ELSE 
				LET l_arr_address[2,3] = l_rec_orderhead.ship_addr2_text 
				LET l_arr_address[2,4] = l_rec_orderhead.ship_city_text[1,20]," ", l_rec_orderhead.state_code," ",l_rec_orderhead.post_code 
			END IF 

			SELECT desc_text INTO l_terr_text 
			FROM territory 
			WHERE cmpy_code = p_rec_pickhead.cmpy_code 
			AND terr_code = p_rec_pickhead.terr_code 

			SELECT name_text INTO l_sale_text 
			FROM salesperson 
			WHERE cmpy_code = p_rec_pickhead.cmpy_code 
			AND sale_code = p_rec_pickhead.sale_code 

			SELECT name_text INTO l_carr_text 
			FROM carrier 
			WHERE cmpy_code = p_rec_pickhead.cmpy_code 
			AND carrier_code = p_rec_pickhead.carrier_code 

			SELECT sum(picked_qty*weight_qty) INTO l_netwgt_qty 
			FROM pickdetl, product 
			WHERE pickdetl.cmpy_code = p_rec_pickhead.cmpy_code 
			AND pickdetl.ware_code = p_rec_pickhead.ware_code 
			AND pickdetl.pick_num = p_rec_pickhead.pick_num 
			AND product.cmpy_code = p_rec_pickhead.cmpy_code 
			AND product.part_code = pickdetl.part_code 
			
			LET l_page_num = l_page_num + 1 

			PRINT COLUMN 02, l_rec_pick_company.name_text clipped, 
			COLUMN 44, l_arr_address[1,1] 

			PRINT COLUMN 02,"------------------------------", 
			COLUMN 44, l_arr_address[1,2] 

			PRINT COLUMN 44, l_arr_address[1,3] 

			PRINT COLUMN 02, l_arr_address[2,1], 
			COLUMN 44, l_arr_address[1,4] 

			PRINT COLUMN 02, l_arr_address[2,2], 
			COLUMN 44, l_header_text_text 

			PRINT COLUMN 02, l_arr_address[2,3], 
			COLUMN 72, l_page_num USING "Page: <<<" 

			PRINT COLUMN 02, l_arr_address[2,4] 
			
			IF p_rec_pickhead.printed_num > 1 THEN 
				PRINT COLUMN 44, "PICKING LIST (",p_rec_pickhead.ware_code,":",p_rec_pickhead.pick_num USING "<<<<<<<",")", 
				COLUMN 67, "*REPRINT(",p_rec_pickhead.printed_num USING "<<",")*" 
			ELSE 
				PRINT COLUMN 44, "PICKING LIST (",p_rec_pickhead.ware_code,":",p_rec_pickhead.pick_num USING "<<<<<<<",")" 
			END IF 

			PRINT COLUMN 02, "State :", 
			COLUMN 12, l_rec_orderhead.state_code, 
			COLUMN 44, "------------------------------------" 

			PRINT COLUMN 02, "Territy.:", 
			COLUMN 12, l_terr_text, 
			COLUMN 44, "| Customer | Print Date | Salesman |" 

			PRINT COLUMN 02, "Salesmn.:", 
			COLUMN 12, l_sale_text, 
			COLUMN 44, "| ",p_rec_pickhead.cust_code," ", 
			"| ",today USING "dd/mm/yy"," ", 
			"| ",p_rec_pickhead.sale_code," |" 

			PRINT COLUMN 02, "Carrier :", 
			COLUMN 12, l_carr_text, 
			COLUMN 44, "------------------------------------" 

			PRINT COLUMN 02, "Instrtn.:", 
			COLUMN 12, l_rec_orderhead.ship1_text[1,30], 
			COLUMN 44, "| Nett Wgt | Gross Wgt. | Territy. |" 

			PRINT COLUMN 12, l_rec_orderhead.ship1_text[31,60], 
			COLUMN 44, "| ",l_netwgt_qty USING "-&&&&.&&"," ", 
			"| ", 
			"| ",p_rec_pickhead.terr_code," |" 

			PRINT COLUMN 2, "Del.Date:", 
			COLUMN 12, l_rec_orderhead.ship_date USING "dd mmm yy", 
			COLUMN 44, "------------------------------------" 
			SKIP 1 line 

			PRINT COLUMN 1,"----------------------------------------","----------------------------------------" 

			PRINT COLUMN 01, '|', 
			COLUMN 03, 'Bin Loc.', 
			COLUMN 12, '|', 
			COLUMN 18, 'Product', 
			COLUMN 29, '|', 
			COLUMN 32, 'Qty.', 
			COLUMN 39, '|', 
			COLUMN 49, 'Description', 
			COLUMN 70, '|', 
			COLUMN 71, 'Order No.', 
			COLUMN 80, '|' 

			PRINT COLUMN 1,"----------------------------------------","----------------------------------------" 
			LET l_line_cnt = l_line_cnt + 19 

		BEFORE GROUP OF p_rec_pickhead.pick_num 
			LET l_pick_ind = FALSE 
			SKIP TO top OF PAGE 

		ON EVERY ROW 

			#DISPLAY "EXIT: disabled code because of <Anton Dickinson> ecp issue with outer" 
			#DISPLAY "see eo/e52c.4gl" 
			#EXIT PROGRAM (1) 


			LET l_str = 
			"SELECT pickdetl.*, prodstatus.bin1_text ", 
			" FROM pickdetl, outer prodstatus ", 
			"WHERE pickdetl.cmpy_code = '",p_rec_pickhead.cmpy_code CLIPPED, "' ", 
			" AND pickdetl.ware_code = '",p_rec_pickhead.ware_code CLIPPED, "' ", 
			" AND pickdetl.pick_num = '",p_rec_pickhead.pick_num CLIPPED, "' ", 
			" AND prodstatus.cmpy_code = '", p_rec_pickhead.cmpy_code CLIPPED, "' ", 
			" AND prodstatus.ware_code = '",p_rec_pickhead.ware_code CLIPPED, "' ", 
			" AND prodstatus.part_code = pickdetl.part_code ", 
			" ORDER BY prodstatus.bin1_text, ", 
			" pickdetl.part_code" 

			PREPARE cew FROM l_str 
			DECLARE c_pickdetl cursor FOR cew 
			FOREACH c_pickdetl INTO 
				l_rec_pickdetl.*,	
				l_lsale_text 

				SELECT desc_text INTO l_line_text 
				FROM product 
				WHERE cmpy_code = p_rec_pickhead.cmpy_code 
				AND part_code = l_rec_pickdetl.part_code
				 
				NEED 2 LINES 
				PRINT COLUMN 01, '|', 
				COLUMN 03, l_lsale_text[1,7], 
				COLUMN 11, l_rec_pickdetl.carry_ind, 
				COLUMN 12, '|', 
				COLUMN 14, l_rec_pickdetl.part_code, 
				COLUMN 29, '|', 
				COLUMN 31, l_rec_pickdetl.picked_qty USING "<<<<<<<", 
				COLUMN 39, '|', 
				COLUMN 40, l_line_text, 
				COLUMN 70, '|', 
				COLUMN 71, l_rec_pickdetl.order_num USING "########", 
				COLUMN 80, '|' 
				
				LET l_line_cnt = l_line_cnt + 1 
				INITIALIZE l_rec_orderdetl.* TO NULL 
				SELECT * INTO l_rec_orderdetl.* FROM orderdetl 
				WHERE line_num = l_rec_pickdetl.order_line_num 
				AND order_num = l_rec_pickdetl.order_num 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				
				IF l_rec_orderdetl.desc_text[1,3] = "###"	AND l_rec_orderdetl.desc_text[16,18] = "###" THEN 
					LET l_note_code = l_rec_orderdetl.desc_text[4,15]
					 
					DECLARE c_notes2 cursor FOR 
					SELECT * INTO l_notes.* FROM notes 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND note_code = l_note_code
					 
					FOREACH c_notes2 INTO l_notes.* 
						PRINT COLUMN 01, '|', 
						COLUMN 12, '|', 
						COLUMN 29, '|', 
						COLUMN 39, '|', 
						COLUMN 40, l_notes.note_text[1,30], 
						COLUMN 70, '|', 
						COLUMN 80, '|' 
						LET l_line_cnt = l_line_cnt + 1
						 
						IF l_notes.note_text[31,60] != " " THEN 
							PRINT COLUMN 01, '|', 
							COLUMN 12, '|', 
							COLUMN 29, '|', 
							COLUMN 39, '|', 
							COLUMN 40, l_notes.note_text[31,60], 
							COLUMN 70, '|', 
							COLUMN 80, '|' 
							LET l_line_cnt = l_line_cnt + 1 
						END IF 
					END FOREACH
					 
				END IF 
			END FOREACH 
			
			PAGE TRAILER 
				IF l_line_cnt = 54 THEN 
					PRINT COLUMN 1,"----------------------------------------", 
					"----------------------------------------" 
				ELSE 
					SKIP 1 line 
				END IF 
				SKIP 1 LINES 
				IF l_pick_ind THEN 
					PRINT COLUMN 1,"Items on backorder are NOT printed on ", 	"this picking list. They will be supplied" 
					PRINT COLUMN 1,"as soon as they become available." 
					PRINT COLUMN 1,"----------------------------------------","----------------------------------------" 
					PRINT COLUMN 1,"| Pick Date | Picked By. | Packed By. ","| Invoice. | Parcels | Checked By |" 
					PRINT COLUMN 1,"----------------------------------------","----------------------------------------" 
					PRINT COLUMN 1,"| | | ","| | | |" 
					PRINT COLUMN 1,"| | | ","| | | |" 
					PRINT COLUMN 1,"----------------------------------------","----------------------------------------" 
				ELSE 
					SKIP 8 LINES 
				END IF 
				SKIP 1 LINES 

		AFTER GROUP OF p_rec_pickhead.pick_num 
			LET l_pick_ind = TRUE 
			FOR i = l_line_cnt TO 54 
				LET l_line_cnt = i 
				PRINT COLUMN 01, '|', 
				COLUMN 12, '|', 
				COLUMN 29, '|', 
				COLUMN 39, '|', 
				COLUMN 70, '|', 
				COLUMN 80, '|' 
			END FOR 
			LET l_page_num = 0 
			
		ON LAST ROW 
			SKIP 1 line 
			
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = pageno
END REPORT
###########################################################################
# END REPORT E52_rpt_list_picklist(p_rpt_idx,p_rec_pickhead)###########################################################################