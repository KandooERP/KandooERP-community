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
GLOBALS "../pu/R_PU_GLOBALS.4gl" 
GLOBALS "../pu/RS_GROUP_GLOBALS.4gl"
GLOBALS "../pu/RS1_GLOBALS.4gl" 

# FUNCTION: po_print_03
# Description: prints purchase orders (FORMAT 03, B&P specific, 80 col )
#              using JETFORM printing.



FUNCTION po_print_03(p_cmpy, p_kandoouser_sign_on_code, where_text) 
	DEFINE 
	pr_purchdetl RECORD LIKE purchdetl.*, 
	p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code, 
	first_line INTEGER, 
	p_cmpy LIKE company.cmpy_code, 
	where_text CHAR(550), 
	query_text CHAR(900), 
	pr_save_order_num LIKE purchhead.order_num, 
	rpt_note2 LIKE rmsreps.report_text, 
	pr_report_started, pr_interrupt_flag SMALLINT 
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]


	LET query_text = "SELECT purchdetl.* FROM purchdetl, purchhead ", 
	"WHERE purchhead.cmpy_code = \"",p_cmpy,"\" ", 
	"AND purchhead.cmpy_code = purchdetl.cmpy_code ", 
	"AND purchhead.vend_code = purchdetl.vend_code ", 
	"AND purchhead.order_num = purchdetl.order_num ", 
	"AND ", where_text clipped, 
	" ORDER BY purchdetl.order_num, purchdetl.line_num " 
	PREPARE p_purchdetl FROM query_text 
	DECLARE c_purchdetl CURSOR with HOLD FOR p_purchdetl 
	LET first_line = 0 
	LET pr_save_order_num = 0 
	LET pr_report_started = false 
	LET pr_interrupt_flag = false 
	--   OPEN WINDOW w1 AT 15,15 with 1 rows, 40 columns  -- albo  KD-756
	--      ATTRIBUTE(border)
	FOREACH c_purchdetl INTO pr_purchdetl.* 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			#8002 Do you wish TO quit (Y/N)?
			IF kandoomsg("U",8002,"") = 'Y' THEN 
				LET pr_interrupt_flag = true 
				EXIT FOREACH 
			END IF 
		END IF 
		IF pr_save_order_num != pr_purchdetl.order_num THEN 
			LET pr_save_order_num = pr_purchdetl.order_num 
			DISPLAY "" at 1,10 
			DISPLAY " Purchase Order: ", pr_purchdetl.order_num at 1,10 

			# New PO number may mean new RMS file, depending on flag
			IF pr_purchtype.rms_flag = 'N' THEN 
				IF pr_report_started THEN 

					#------------------------------------------------------------
					FINISH REPORT RS1_rpt_list_03
					CALL rpt_finish("RS1_rpt_list_03")
					#------------------------------------------------------------	

				END IF 
				LET rpt_note2 = "Purchase Order ", 
				pr_purchdetl.order_num USING "<<<<<<<<" clipped, " ", 
				pr_purchtype.desc_text clipped 
				LET pr_report_started = false 
			END IF 
			IF NOT pr_report_started THEN 

				#------------------------------------------------------------
				LET l_rpt_idx = rpt_start("RS1-03","RS1_rpt_list_03","N/A", RPT_SHOW_RMS_DIALOG)
				IF l_rpt_idx = 0 THEN #User pressed CANCEL
					RETURN FALSE
				END IF	

				CALL rpt_set_header_footer_line_2_append(rpt_rmsreps_idx_get_idx("RS1_rpt_list_03"),NULL, "pr_purchtype.desc_text")
				
				START REPORT RS1_rpt_list_03 TO rpt_get_report_file_with_path2(l_rpt_idx)
				WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
				TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
				BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
				LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
				RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
				#------------------------------------------------------------		
				 
				LET pr_report_started = true 
			END IF 
		END IF 

		#---------------------------------------------------------		
		OUTPUT TO REPORT RS1_rpt_list_03(l_rpt_idx,
		pr_purchdetl.*,first_line) 
		#---------------------------------------------------------			
		
	END FOREACH 
	--   CLOSE WINDOW w1  -- albo  KD-756
	IF pr_report_started THEN 
		#------------------------------------------------------------
		FINISH REPORT RS1_rpt_list_03
		CALL rpt_finish("RS1_rpt_list_03")
		#------------------------------------------------------------	
	END IF 
	RETURN pr_output, pr_interrupt_flag 
END FUNCTION 

REPORT RS1_rpt_list_03(pr_purchdetl,first_line) 
	DEFINE 
	pr_purchhead RECORD LIKE purchhead.*, 
	pr_purchdetl RECORD LIKE purchdetl.*, 
	pr_poaudit RECORD LIKE poaudit.*, 
	pr_vendor RECORD LIKE vendor.*, 
	pr_notes RECORD LIKE notes.*, 
	pr_warehouse RECORD LIKE warehouse.*, 
	note_mark1, note_mark2 CHAR(3), 
	temp_text CHAR(12), 
	note_info CHAR(70), 
	query_text CHAR(400), 
	pr_pagecount INTEGER, 
	first_line, pr_det_line, pr_kandoo_detaillines INTEGER, 
	note_text CHAR(120), 
	pr_line_count, 
	pr_first_page_flag, 
	cnt,a, b, y, x SMALLINT, 
	pr_total_lines, pr_total_pages DECIMAL(16,4) 

	OUTPUT 

	ORDER external BY pr_purchdetl.order_num,	pr_purchdetl.line_num
	 
	FORMAT 
		FIRST PAGE HEADER 
			LET pr_first_page_flag = true 
			LET pr_pagecount = 0 
		BEFORE GROUP OF pr_purchdetl.order_num 
			IF pr_first_page_flag THEN 
				PRINT "\^job PORDER -z", pr_printcodes.print_code 
				LET pr_first_page_flag = false 
			END IF 
			LET pr_pagecount = pr_pagecount + 1 
			LET pr_line_count = 0 
			SELECT * INTO pr_vendor.* FROM vendor 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND vend_code = pr_purchdetl.vend_code 
			SELECT * INTO pr_purchhead.* FROM purchhead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND vend_code = pr_purchdetl.vend_code 
			AND order_num = pr_purchdetl.order_num 
			SELECT count(*) 
			INTO pr_total_lines 
			FROM purchdetl 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND vend_code = pr_purchdetl.vend_code 
			AND order_num = pr_purchdetl.order_num 
			# Calculate number of pages
			IF pr_total_lines > 7 THEN 
				LET pr_total_lines = pr_total_lines - 7 
				LET pr_total_pages = 1 + rounding("2",pr_total_lines/15) 
			ELSE 
				LET pr_total_pages = 1 
			END IF 

			PRINT "\^form PORDER.MDF" 
			PRINT "\^field PORDER" 
			PRINT pr_purchdetl.order_num USING "#######" 
			PRINT "\^field VENDOR" 
			PRINT pr_vendor.name_text 
			PRINT "\^field DATE" 
			PRINT pr_purchhead.order_date USING "dd mmm yy" 
			PRINT "\^field ADD1" 
			PRINT pr_vendor.addr1_text 
			PRINT "\^field ADD2" 
			PRINT pr_vendor.addr2_text 
			PRINT "\^field ADD3" 
			PRINT pr_vendor.addr3_text 
			PRINT "\^field CITY" 
			PRINT pr_vendor.city_text 
			PRINT "\^field STATE" 
			PRINT pr_vendor.state_code 
			PRINT "\^field POSTCODE" 
			PRINT pr_vendor.post_code 
			PRINT "\^field PAGE" 
			PRINT pr_pagecount USING "###", " of", pr_total_pages USING "###" 
			PRINT "\^field VEN_CODE" 
			PRINT pr_vendor.vend_code 
			#trailing information
			PRINT "\^field DEL_NAME" 
			PRINT pr_purchhead.del_name_text 
			PRINT "\^field DEL_ADD1" 
			PRINT pr_purchhead.del_addr1_text 
			PRINT "\^field DEL_ADD2" 
			PRINT pr_purchhead.del_addr2_text 
			PRINT "\^field DEL_ADD3" 
			PRINT pr_purchhead.del_addr3_text 
			PRINT "\^field DEL_ADD4" 
			PRINT pr_purchhead.del_addr4_text 
			LET pr_warehouse.contact_text = NULL 
			LET pr_warehouse.tele_text = NULL 
			SELECT contact_text, tele_text INTO pr_warehouse.contact_text, 
			pr_warehouse.tele_text 
			FROM warehouse 
			WHERE ware_code = pr_purchhead.ware_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			PRINT "\^field CONTACT" 
			PRINT pr_warehouse.contact_text 
			PRINT "\^field CONTPHONE" 
			PRINT pr_warehouse.tele_text 
			PRINT "\^record PORDER" 
			PRINT "\^continue QUANTITY 11 01" 
			PRINT "\^continue VENDOR_REF 30 12" 
			PRINT "\^continue REF_TEXT 25 42" 
			PRINT "\^continue DESC_TEXT 40 67" 
			PRINT "\^continue NOTE_TEXT 45 107" 
			LET rpt_pageno = rpt_pageno + 1 
			LET pr_kandoo_detaillines = 7 
		AFTER GROUP OF pr_purchdetl.order_num 
			LET first_line = 0 
			LET pr_pagecount = 0 
			UPDATE purchhead SET printed_flag = "Y" 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND order_num = pr_purchhead.order_num 
		ON EVERY ROW 
			LET pr_line_count = pr_line_count + 1 
			IF pr_line_count > pr_kandoo_detaillines THEN 
				PRINT "\^form PORDER1.MDF" 
				PRINT "\^field PORDER" 
				PRINT pr_purchdetl.order_num USING "#######" 
				LET pr_pagecount = pr_pagecount + 1 
				PRINT "\^field PAGE" 
				PRINT pr_pagecount USING "###", " of", pr_total_pages USING "###" 
				LET pr_kandoo_detaillines = 15 
				LET pr_line_count = 1 
				PRINT "\^record PORDER" 
				PRINT "\^continue QUANTITY 11 01" 
				PRINT "\^continue VENDOR_REF 30 12" 
				PRINT "\^continue REF_TEXT 25 42" 
				PRINT "\^continue DESC_TEXT 40 67" 
				PRINT "\^continue NOTE_TEXT 45 107" 
			END IF 
			CALL po_line_info(glob_rec_kandoouser.cmpy_code, pr_purchdetl.order_num, 
			pr_purchdetl.line_num) 
			RETURNING pr_poaudit.order_qty, pr_poaudit.received_qty, 
			pr_poaudit.voucher_qty, pr_poaudit.unit_cost_amt, 
			pr_poaudit.ext_cost_amt, pr_poaudit.unit_tax_amt, 
			pr_poaudit.ext_tax_amt, pr_poaudit.line_total_amt 
			PRINT pr_poaudit.order_qty USING "#######&.&&"; 
			PRINT pr_purchdetl.oem_text; 
			PRINT pr_purchdetl.ref_text; 
			IF pr_purchdetl.desc_text[1,3] = "###" 
			AND pr_purchdetl.desc_text[16,18] = "###" THEN 
				PRINT " "; 
			ELSE 
				PRINT pr_purchdetl.desc_text; 
			END IF 
			LET temp_text = "" 
			IF (pr_purchdetl.desc_text[1,3] = "###" 
			AND pr_purchdetl.desc_text[16,18] = "###") THEN 
				LET temp_text = pr_purchdetl.desc_text[4,15] 
			ELSE 
				IF pr_purchdetl.note_code IS NOT NULL THEN 
					LET temp_text = pr_purchdetl.note_code 
				END IF 
			END IF 
			IF temp_text IS NOT NULL THEN 
				LET query_text = "SELECT * FROM notes ", 
				"WHERE cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
				"AND note_code = '", temp_text, "' ", 
				"ORDER BY note_num" 
				PREPARE p_notes FROM query_text 
				DECLARE c_notes CURSOR FOR p_notes 
				OPEN c_notes 
				FETCH c_notes INTO pr_notes.* 
				IF status != notfound THEN 
					PRINT pr_notes.note_text[1,45] 
				ELSE 
					PRINT " " 
				END IF 
			ELSE 
				PRINT " " 
			END IF 
END REPORT 
