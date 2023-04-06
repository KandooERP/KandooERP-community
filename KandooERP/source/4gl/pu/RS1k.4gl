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

# FUNCTION po_print_06 prints purchase orders (FORMAT 06, B&P specific, 80 col )

FUNCTION po_print_06(p_cmpy, p_kandoouser_sign_on_code, where_text) 
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
					FINISH REPORT RS1_rpt_list_06
					CALL rpt_finish("RS1_rpt_list_06")
					#------------------------------------------------------------	 	

				END IF 
				LET rpt_note2 = "Purchase Order ", 
				pr_purchdetl.order_num USING "<<<<<<<<" clipped, " ", 
				pr_purchtype.desc_text clipped 
				LET pr_report_started = false 
			END IF 
			IF NOT pr_report_started THEN 

				#------------------------------------------------------------
				LET l_rpt_idx = rpt_start("RS1-06","RS1_rpt_list_06","N/A", RPT_SHOW_RMS_DIALOG)
				IF l_rpt_idx = 0 THEN #User pressed CANCEL
					RETURN FALSE
				END IF	

				CALL rpt_set_header_footer_line_2_append(rpt_rmsreps_idx_get_idx("RS1_rpt_list_06"),NULL, "pr_purchtype.desc_text")
					
				START REPORT RS1_rpt_list_06 TO rpt_get_report_file_with_path2(l_rpt_idx)
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
		OUTPUT TO REPORT RS1_rpt_list_06(l_rpt_idx,
		pr_purchdetl.*,first_line)  
		#---------------------------------------------------------			
 
	END FOREACH 
	
	--   CLOSE WINDOW w1  -- albo  KD-756
	IF pr_report_started THEN 

		#------------------------------------------------------------
		FINISH REPORT RS1_rpt_list_06
		CALL rpt_finish("RS1_rpt_list_06")
		#------------------------------------------------------------	 	

	END IF 
	RETURN pr_output, pr_interrupt_flag 
END FUNCTION 

REPORT RS1_rpt_list_06(pr_purchdetl,first_line) 
	DEFINE 
	pr_purchhead RECORD LIKE purchhead.*, 
	pr_purchdetl RECORD LIKE purchdetl.*, 
	pr_poaudit RECORD LIKE poaudit.*, 
	pr_vendor RECORD LIKE vendor.*, 
	pr_warehouse RECORD LIKE warehouse.*, 
	query_text CHAR(400), 
	pagcount, 
	pr_line_skip, 
	first_line INTEGER, 
	pr_print_qty CHAR(1), 
	note_text CHAR(120), 
	note_info CHAR(70), 
	a, b, y, x, cnt SMALLINT 

	OUTPUT 
#	top margin 0 
#	bottom margin 0 
#	left margin 0 
#	PAGE length 66 
	ORDER external BY pr_purchdetl.order_num,	pr_purchdetl.line_num
	 
	FORMAT 
		BEFORE GROUP OF pr_purchdetl.order_num 
			SKIP TO top OF PAGE 
		AFTER GROUP OF pr_purchdetl.order_num 
			LET first_line = 0 
			LET pagcount = 0 
			UPDATE purchhead SET printed_flag = "Y" 
			WHERE cmpy_code = p_cmpy 
			AND order_num = pr_purchhead.order_num 
		PAGE HEADER 
			PRINT "" 
			PRINT "" 
			PRINT "" 
			PRINT "" 
			PRINT "" 
			PRINT "" 
			PRINT "" 
			PRINT "" 
			PRINT "" 
			PRINT "" 
			LET pagcount = pagcount + 1 
			SELECT * INTO pr_vendor.* FROM vendor 
			WHERE cmpy_code = p_cmpy 
			AND vend_code = pr_purchdetl.vend_code 
			SELECT * INTO pr_purchhead.* FROM purchhead 
			WHERE cmpy_code = p_cmpy 
			AND vend_code = pr_purchdetl.vend_code 
			AND order_num = pr_purchdetl.order_num 
			PRINT COLUMN 65, pr_purchdetl.order_num USING "#######" 
			SKIP 2 LINES 
			PRINT COLUMN 10, pr_vendor.name_text, 
			COLUMN 65, pr_purchhead.order_date USING "dd mmm yy" 
			PRINT COLUMN 10, pr_vendor.addr1_text 
			IF pr_vendor.addr2_text IS NOT NULL THEN 
				PRINT COLUMN 10, pr_vendor.addr2_text 
				IF pr_vendor.addr3_text IS NOT NULL THEN 
					PRINT COLUMN 10, pr_vendor.addr3_text 
					PRINT COLUMN 10, pr_vendor.city_text clipped, " ", 
					pr_vendor.state_code, 2 spaces, 
					pr_vendor.post_code, 
					COLUMN 65, "Page: ", pagcount USING "###" 
				ELSE 
					PRINT COLUMN 10, pr_vendor.city_text clipped, " ", 
					pr_vendor.state_code, 2 spaces, 
					pr_vendor.post_code 
					PRINT COLUMN 65, "Page: ", pagcount USING "###" 
				END IF 
			ELSE 
				IF pr_vendor.addr3_text IS NOT NULL THEN 
					PRINT COLUMN 10, pr_vendor.addr3_text 
					PRINT COLUMN 10, pr_vendor.city_text clipped, " ", 
					pr_vendor.state_code, 2 spaces, 
					pr_vendor.post_code 
					PRINT COLUMN 65, "Page: ", pagcount USING "###" 
				ELSE 
					PRINT COLUMN 10, pr_vendor.city_text clipped, " ", 
					pr_vendor.state_code, 2 spaces, 
					pr_vendor.post_code 
					SKIP 1 line 
					PRINT COLUMN 65, "Page: ", pagcount USING "###" 
				END IF 
			END IF 
			SKIP 2 LINES 
			PRINT COLUMN 65, pr_vendor.vend_code 
			SKIP 2 LINES 
			LET rpt_pageno = rpt_pageno + 1 
		ON EVERY ROW 
			CALL po_line_info(glob_rec_kandoouser.cmpy_code, pr_purchdetl.order_num, 
			pr_purchdetl.line_num) 
			RETURNING pr_poaudit.order_qty, pr_poaudit.received_qty, 
			pr_poaudit.voucher_qty, pr_poaudit.unit_cost_amt, 
			pr_poaudit.ext_cost_amt, pr_poaudit.unit_tax_amt, 
			pr_poaudit.ext_tax_amt, pr_poaudit.line_total_amt 
			SKIP 1 line 
			LET query_text = NULL 
			IF (pr_purchdetl.desc_text[1,3] = "###" 
			AND pr_purchdetl.desc_text[16,18] = "###") THEN 
				LET query_text = "SELECT note_text, note_num FROM notes ", 
				"WHERE cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
				"AND note_code = '",pr_purchdetl.desc_text[4,15],"' ", 
				"ORDER BY note_num" 
				LET pr_print_qty = true 
			ELSE 
				PRINT COLUMN 3, pr_poaudit.order_qty USING "#######&.&&", 
				COLUMN 16, pr_purchdetl.desc_text 
				IF pr_purchdetl.desc2_text IS NOT NULL 
				AND pr_purchdetl.desc2_text != " " THEN 
					PRINT COLUMN 16, pr_purchdetl.desc2_text 
				END IF 
				IF pr_purchdetl.note_code IS NOT NULL THEN 
					LET query_text = "SELECT note_text, note_num FROM notes ", 
					"WHERE cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
					"AND note_code = '",pr_purchdetl.note_code, "' ", 
					"ORDER BY note_num" 
					LET pr_print_qty = false 
				END IF 
			END IF 
			IF query_text IS NOT NULL THEN 
				PREPARE p_notes FROM query_text 
				DECLARE c_notes CURSOR FOR p_notes 
				LET a = 29 
				LET note_text = "" 
				FOREACH c_notes INTO note_info, cnt 
					IF note_text IS NULL THEN 
						LET note_text = note_info clipped 
					ELSE 
						LET note_text = note_text clipped, " ", note_info clipped 
					END IF 
					LET y = length(note_text) 
					IF y > 0 THEN 
						WHILE y > 0 
							FOR b = a TO 1 step -1 
								IF note_text[b] = " " THEN 
									IF pr_print_qty THEN 
										LET pr_print_qty = false 
										PRINT COLUMN 3, pr_poaudit.order_qty USING "#######&.&&", 
										COLUMN 16, note_text[1,b] clipped; 
									ELSE 
										PRINT COLUMN 16, note_text[1,b] clipped; 
									END IF 
									LET x = length(note_text) 
									IF x > b THEN 
										PRINT 
										LET note_text = note_text[b+1,x] 
										LET a = 29 
									ELSE 
										LET a = 29 - length(note_text) 
										LET note_text = " " 
									END IF 
									EXIT FOR 
								END IF 
								IF b = 1 THEN 
									LET b = a - 1 
									IF pr_print_qty THEN 
										LET pr_print_qty = false 
										PRINT COLUMN 3, pr_poaudit.order_qty USING "#######&.&&", 
										COLUMN 16, note_text[1,b] clipped; 
									ELSE 
										PRINT COLUMN 16, note_text[1,b] clipped; 
									END IF 
									LET x = length(note_text) 
									IF x > b THEN 
										PRINT 
										LET note_text = note_text[b+1,x] 
										LET a = 29 
									ELSE 
										LET note_text = " " 
										LET a = 29 
									END IF 
									EXIT FOR 
								END IF 
							END FOR 
							LET y = length(note_text) 
						END WHILE 
					ELSE 
						PRINT 
					END IF 
				END FOREACH 
				PRINT 
			END IF 
			PAGE TRAILER 
				PRINT COLUMN 2, pr_purchhead.com1_text 
				PRINT COLUMN 2, pr_purchhead.com2_text 
				PRINT 
				PRINT "Delivery Address:" 
				PRINT COLUMN 2, pr_purchhead.del_name_text 
				PRINT COLUMN 2, pr_purchhead.del_addr1_text 
				PRINT COLUMN 2, pr_purchhead.del_addr2_text 
				PRINT COLUMN 2, pr_purchhead.del_addr3_text clipped, " ", 
				pr_purchhead.del_addr4_text 
				SKIP 1 LINES 
				INITIALIZE pr_warehouse.* TO NULL 
				SELECT * INTO pr_warehouse.* FROM warehouse 
				WHERE ware_code = pr_purchhead.ware_code 
				AND cmpy_code = p_cmpy 
				PRINT "Delivery Date: ", 
				pr_purchhead.due_date USING "dd/mm/yyyy" 
				PRINT "Contact: ", pr_warehouse.contact_text clipped, " ", 
				"Ph: ", pr_warehouse.tele_text 
				SKIP 5 LINES 
END REPORT 


