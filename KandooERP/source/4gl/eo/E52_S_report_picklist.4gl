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
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_notes RECORD LIKE notes.* 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_bin_text LIKE prodstatus.bin1_text 
	DEFINE l_pick_ind SMALLINT
	DEFINE l_line_cnt SMALLINT
	DEFINE l_page_num SMALLINT
	DEFINE l_order_num LIKE orderhead.order_num 
	DEFINE sel_text char(600) 
	DEFINE l_str STRING	
	DEFINE l_picked_qty LIKE pickdetl.picked_qty 
	DEFINE i SMALLINT

-- Unused declared variables
--	DEFINE l_rec_picklist_company RECORD LIKE company.* 
--	DEFINE l_note_code LIKE notes.note_code 
--	DEFINE l_arr_address array[2,4] OF char(36) 
--	DEFINE l_header_text_text char(40) 
--	DEFINE l_line_text LIKE product.desc_text 
--	DEFINE l_netwgt_qty FLOAT 
--	DEFINE line1 char(80) 
--	DEFINE offset1, offset2 SMALLINT 


	OUTPUT 

	ORDER external BY 
		p_rec_pickhead.cmpy_code, 
		p_rec_pickhead.ware_code, 
		p_rec_pickhead.pick_num 

	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			LET l_line_cnt = 0 
 
			SELECT * INTO l_rec_customer.* FROM customer 
			WHERE cmpy_code = p_rec_pickhead.cmpy_code 
			AND cust_code = p_rec_pickhead.cust_code 

			## need TO know first ORDER num of shipment
			DECLARE c_pickhead cursor FOR 
			SELECT order_num FROM pickdetl 
			WHERE cmpy_code = p_rec_pickhead.cmpy_code 
			AND ware_code = p_rec_pickhead.ware_code 
			AND pick_num = p_rec_pickhead.pick_num 
			OPEN c_pickhead 
			FETCH c_pickhead INTO l_order_num 

			SELECT * INTO l_rec_orderhead.* FROM orderhead 
			WHERE cmpy_code = p_rec_pickhead.cmpy_code 
			AND order_num = l_order_num 
			PRINT COLUMN 01, "ALLOCATION batch:", 
			COLUMN 12, p_rec_pickhead.batch_num USING "<<<<<<<" 

			IF p_rec_pickhead.printed_num > 1 THEN 
				PRINT COLUMN 01, "ALLOCATION No. (",p_rec_pickhead.ware_code, 
				":",p_rec_pickhead.pick_num USING "<<<<<<<",")", 
				" *reprint(",p_rec_pickhead.printed_num USING "<<",")*" 
			ELSE 
				PRINT COLUMN 01, "ALLOCATION No. (",p_rec_pickhead.ware_code, 
				":",p_rec_pickhead.pick_num USING "<<<<<<<",")" 
			END IF 
			PRINT COLUMN 01, "Del.Date:", 
			COLUMN 12, l_rec_orderhead.ship_date USING "dd mmm yy" 
			SKIP 1 line 
			PRINT COLUMN 01, "Store No: ",l_rec_customer.cust_code clipped, 
			COLUMN 20, l_rec_customer.name_text clipped 
			SKIP 1 line 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]
 
			PRINT COLUMN 01, 'Sku No.', 
			COLUMN 10, 'Style', 
			COLUMN 21, 'Description', 
			COLUMN 52, 'Clr', 
			COLUMN 56, 'Size', 
			COLUMN 62, 'Tk', 
			COLUMN 68, 'Ref No.', 
			COLUMN 78, 'Qty', 
			COLUMN 82, 'Vendor', 
			COLUMN 91, 'Order No', 
			COLUMN 100, 'Line' 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]
 
			LET l_page_num = l_page_num + 1 
			LET l_line_cnt = l_line_cnt + 12 

		BEFORE GROUP OF p_rec_pickhead.pick_num 
			LET l_pick_ind = FALSE 
			SKIP TO top OF PAGE 

		ON EVERY ROW 
			--DISPLAY "EXIT: disabled code because of <Anton Dickinson> ecp issue with outer" 
			--DISPLAY "see eo/e52d.4gl" 
			--EXIT PROGRAM (1) 

			LET l_str = 
			"SELECT pickdetl.*, prodstatus.bin1_text ", 
			" FROM pickdetl, outer prodstatus ", 
			" WHERE pickdetl.cmpy_code =", p_rec_pickhead.cmpy_code, 
			" AND pickdetl.ware_code =", p_rec_pickhead.ware_code, 
			" AND pickdetl.pick_num =", p_rec_pickhead.pick_num, 
			" AND prodstatus.cmpy_code =", p_rec_pickhead.cmpy_code, 
			" AND prodstatus.ware_code =", p_rec_pickhead.ware_code, 
			" AND prodstatus.part_code = pickdetl.part_code ", 
			" ORDER BY prodstatus.bin1_text, ", 
			" pickdetl.part_code" 

			PREPARE dert FROM l_str 
			DECLARE c_pickdetl_1 cursor FOR dert 

			FOREACH c_pickdetl_1 INTO l_rec_pickdetl.*, 
				l_bin_text 
				SELECT * INTO l_rec_product.* FROM product 
				WHERE cmpy_code = p_rec_pickhead.cmpy_code 
				AND part_code = l_rec_pickdetl.part_code 
				NEED 2 LINES 
				
				PRINT COLUMN 01, l_rec_pickdetl.part_code[1,8], 
					COLUMN 10, l_rec_product.short_desc_text[1,10], 
					COLUMN 21, l_rec_product.desc_text, 
					COLUMN 52, l_rec_product.desc2_text[1,23], 
					COLUMN 76, l_rec_pickdetl.picked_qty USING "----&", 
					COLUMN 82, l_rec_product.vend_code, 
					COLUMN 91, l_rec_pickdetl.order_num USING "########", 
					COLUMN 100, l_rec_pickdetl.order_line_num USING "###"
					 
				LET l_line_cnt = l_line_cnt + 1 
				INITIALIZE l_rec_orderdetl.* TO NULL 
				
				SELECT * INTO l_rec_orderdetl.* FROM orderdetl 
				WHERE line_num = l_rec_pickdetl.order_line_num 
				AND order_num = l_rec_pickdetl.order_num 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				
				IF l_rec_orderdetl.desc_text[1,3] = "###" 
				AND l_rec_orderdetl.desc_text[16,18] = "###" THEN 
					LET glob_arr_rec_rpt_kandooreport[p_rpt_idx].line3_text = l_rec_orderdetl.desc_text[4,15] 
					#LET l_note_code = l_rec_orderdetl.desc_text[4,15] 
					DECLARE c_notes2 cursor FOR 
					SELECT * INTO l_rec_notes.* FROM notes 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND note_code = l_note_code 

					FOREACH c_notes2 INTO l_rec_notes.* 
						PRINT COLUMN 21, l_rec_notes.note_text wordwrap right margin 50 
						LET l_line_cnt = l_line_cnt + 1 
						IF l_rec_notes.note_text[31,60] THEN 
							LET l_line_cnt = l_line_cnt + 1 
						END IF 
					END FOREACH 

				END IF 
			END FOREACH 
			
			PAGE TRAILER 
				IF l_line_cnt = 33 THEN 
					SKIP 1 LINES 
				ELSE 
					SKIP 1 LINES 
				END IF 
				IF l_pick_ind THEN 
					SELECT sum(picked_qty) INTO l_picked_qty FROM pickdetl 
					WHERE cmpy_code = p_rec_pickhead.cmpy_code 
					AND pick_num = p_rec_pickhead.pick_num 
					IF l_picked_qty IS NULL THEN 
						LET l_picked_qty = 0 
					END IF 
					SKIP 1 LINES 
					
					PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]
 
					PRINT COLUMN 1, "Store Totals: Pages: ", 
					COLUMN 22, l_page_num USING "--&", 
					COLUMN 27, l_rec_customer.name_text clipped, 
					COLUMN 58, "Total Pairs: ", 
					COLUMN 71, l_picked_qty USING "--------&" 

					PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]
 
					SKIP 1 line 
					PRINT COLUMN 01, "CHARGED BY: ___________________" 
					SKIP 1 LINES 
					PRINT COLUMN 01, "PICKED BY: ___________________" 
					SKIP 1 LINES 
					PRINT COLUMN 01, "PACKED BY: ___________________", 
					COLUMN 40, "TOTAL CTNS: ___________________" 
				ELSE 
					SKIP 10 LINES 
				END IF 
				SKIP 1 LINES 
		AFTER GROUP OF p_rec_pickhead.pick_num 
			LET l_pick_ind = TRUE 
			FOR i = l_line_cnt TO 33 
				LET l_line_cnt = i 
				SKIP 1 line 
			END FOR 
			LET l_page_num = 0
			 
		ON LAST ROW 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			
END REPORT
###########################################################################
# END REPORT E52_rpt_list_picklist(p_rpt_idx,p_rec_pickhead) 
###########################################################################