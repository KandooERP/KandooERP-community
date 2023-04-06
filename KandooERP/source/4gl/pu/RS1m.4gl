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

# Purpose - po_print_05 prints purchase orders in user specific FORMAT



FUNCTION po_print_05(p_cmpy, p_kandoouser_sign_on_code, where_text) 
	DEFINE 
	pr_purchdetl RECORD LIKE purchdetl.*, 
	where_text CHAR(550), 
	query_text CHAR(900), 
	p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code, 
	p_cmpy LIKE company.cmpy_code, 
	pr_save_order_num LIKE purchhead.order_num, 
	rpt_note2 LIKE rmsreps.report_text, 
	pr_report_started, pr_interrupt_flag SMALLINT 
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]

	SELECT company.* INTO pr_company.* FROM company 
	WHERE cmpy_code = p_cmpy 
	IF status = notfound THEN 
		LET msgresp = kandoomsg("U",5100,"") 	#5100 Company NOT SET up; Refer TO System Admin
		EXIT program 
	END IF 

	LET query_text = "SELECT purchdetl.* ", 
	"FROM purchdetl , purchhead ", 
	" WHERE purchhead.cmpy_code = \"",p_cmpy,"\" ", 
	"AND purchhead.cmpy_code = purchdetl.cmpy_code ", 
	"AND purchhead.vend_code = purchdetl.vend_code ", 
	"AND purchhead.order_num = purchdetl.order_num ", 
	"AND ", where_text clipped, 
	" ORDER BY purchdetl.order_num, purchdetl.line_num " 
	PREPARE s_purchdetl FROM query_text 
	DECLARE c_purchdetl CURSOR with HOLD FOR s_purchdetl 
	--   OPEN WINDOW w1 AT 15,15 with 1 rows, 40 columns  -- albo  KD-756
	--      ATTRIBUTE(border)
	LET pr_save_order_num = 0 
	LET pr_report_started = false 
	LET pr_interrupt_flag = false 
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
			LET pr_pageno = 0 
			LET pr_save_order_num = pr_purchdetl.order_num 
			DISPLAY "" at 1,10 
			DISPLAY " Purchase Order: ", pr_purchdetl.order_num at 1,10 

			IF pr_purchtype.rms_flag = 'N' THEN 
				IF pr_report_started THEN 

					#------------------------------------------------------------
					FINISH REPORT RS1_rpt_list_05
					CALL rpt_finish("RS1_rpt_list_05")
					#------------------------------------------------------------	 	

				END IF 
				LET rpt_note2 = "Purchase Order ", 
				pr_purchdetl.order_num USING "<<<<<<<<" clipped, " ", 
				pr_purchtype.desc_text clipped 
				LET pr_report_started = false 
			END IF 
			IF NOT pr_report_started THEN 

				#------------------------------------------------------------
				LET l_rpt_idx = rpt_start("RS1-05","RS1_rpt_list_05","N/A", RPT_SHOW_RMS_DIALOG)
				IF l_rpt_idx = 0 THEN #User pressed CANCEL
					RETURN FALSE
				END IF	

				CALL rpt_set_header_footer_line_2_append(rpt_rmsreps_idx_get_idx("RS1_rpt_list_05"),NULL, "pr_purchtype.desc_text")
					
				START REPORT RS1_rpt_list_05 TO rpt_get_report_file_with_path2(l_rpt_idx)
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
		OUTPUT TO REPORT RS1_rpt_list_05(l_rpt_idx,
		pr_purchdetl.*)
		#---------------------------------------------------------			

	END FOREACH 
	--   CLOSE WINDOW w1  -- albo  KD-756
	IF pr_report_started THEN 
		#------------------------------------------------------------
		FINISH REPORT RS1_rpt_list_05
		CALL rpt_finish("RS1_rpt_list_05")
		#------------------------------------------------------------	
	END IF 
	RETURN pr_output, pr_interrupt_flag 
END FUNCTION 


REPORT RS1_rpt_list_05(pr_purchdetl) 
	DEFINE 
	pr_purchhead RECORD LIKE purchhead.*, 
	pr_purchdetl RECORD LIKE purchdetl.*, 
	pr_poaudit RECORD LIKE poaudit.*, 
	pr_product RECORD LIKE product.*, 
	pr_prodstatus RECORD LIKE prodstatus.*, 
	pr_vendor RECORD LIKE vendor.*, 
	pr_warehouse RECORD LIKE warehouse.*, 
	pr_term RECORD LIKE term.*, 
	pr_notes RECORD LIKE notes.*, 
	pr_unit_cost, pr_list_price, 
	pr_purchase_total LIKE poaudit.line_total_amt, 
	pr_desc_text LIKE purchdetl.desc_text, 
	pr_note_code LIKE notes.note_code, 
	pr_detl_count, pr_detl2_count, pr_line_num, i SMALLINT, 
	pr_note_count, pr_note2_count SMALLINT, 
	pr_note_text LIKE notes.note_text, 
	pa_vendor_addr array[6] OF CHAR(40), 
	pa_purchase_addr array[6] OF CHAR(40), 
	query_text CHAR(400), 
	pr_text CHAR(30) 

	OUTPUT 
	left margin 0 
	top margin 6 
	bottom margin 6 
	PAGE length 51 
	ORDER external BY pr_purchdetl.order_num, 
	pr_purchdetl.line_num 
	FORMAT 
		PAGE HEADER 

			LET pr_pageno = pr_pageno + 1 
			LET rpt_pageno = pageno 
			INITIALIZE pr_purchhead.* TO NULL 
			SELECT * INTO pr_purchhead.* FROM purchhead 
			WHERE order_num = pr_purchdetl.order_num 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			INITIALIZE pr_warehouse.* TO NULL 
			SELECT * INTO pr_warehouse.* FROM warehouse 
			WHERE ware_code = pr_purchhead.ware_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			INITIALIZE pr_vendor.* TO NULL 
			SELECT * INTO pr_vendor.* FROM vendor 
			WHERE vend_code = pr_purchhead.vend_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			INITIALIZE pr_term.* TO NULL 
			SELECT * INTO pr_term.* FROM term 
			WHERE term_code = pr_purchhead.term_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			CALL pack_address(pr_vendor.name_text, 
			pr_vendor.addr1_text, 
			pr_vendor.addr2_text, 
			pr_vendor.city_text, 
			pr_vendor.state_code, 
			pr_vendor.post_code, 
			pr_vendor.country_code) --@db-patch_2020_10_04--
			RETURNING pa_vendor_addr[1], 
			pa_vendor_addr[2], 
			pa_vendor_addr[3], 
			pa_vendor_addr[4], 
			pa_vendor_addr[5] 
			CALL pack_4lines(pr_purchhead.del_name_text, 
			pr_purchhead.del_addr1_text, 
			pr_purchhead.del_addr2_text, 
			pr_purchhead.del_addr3_text, 
			pr_purchhead.del_addr4_text, 
			pr_purchhead.del_country_code) 
			RETURNING pa_purchase_addr[1], 
			pa_purchase_addr[2], 
			pa_purchase_addr[3], 
			pa_purchase_addr[4], 
			pa_purchase_addr[5], 
			pa_purchase_addr[6] 
			PRINT COLUMN 10, "SUPPLIER:", 
			COLUMN 43, "PURCHASE ORDER:", 
			COLUMN 68, "DELIVER TO:" 
			PRINT " " 
			PRINT COLUMN 10, pa_vendor_addr[1][1,31], 
			COLUMN 43, "OUR ORDER NO: ",pr_purchhead.order_num 
			USING "<<<<<<<<", 
			COLUMN 68, pa_purchase_addr[1] 
			PRINT COLUMN 10, pa_vendor_addr[2][1,31], 
			COLUMN 43, "DATE: ",pr_purchhead.order_date USING "dd/mm/yyyy", 
			COLUMN 68, pa_purchase_addr[2] 
			PRINT COLUMN 10, pa_vendor_addr[3][1,31], 
			COLUMN 43, "PAGE NO: ",pr_pageno USING "<<<<", 
			COLUMN 68, pa_purchase_addr[3] 
			PRINT COLUMN 10, pa_vendor_addr[4] clipped," ",pr_vendor.country_code, 
			COLUMN 68, pa_purchase_addr[4] clipped," ", 
			pr_purchhead.del_country_code[1,3] 
			PRINT " " 
			PRINT COLUMN 02, "SUPPLIER CODE: ",pr_vendor.vend_code, 
			COLUMN 42, "OUR CONTACT: ",pr_purchhead.contact_text[1,23], 
			COLUMN 79, pr_purchhead.com1_text[1,30] 
			PRINT COLUMN 02, "YOUR CONTACT: ",pr_purchhead.salesperson_text[1,25], 
			COLUMN 42, "PHONE: ",pr_purchhead.tele_text, 
			COLUMN 79, pr_purchhead.com1_text[31,60] 
			PRINT COLUMN 02, "YOUR REF: ",pr_purchhead.order_text, 
			COLUMN 42, "SALES TAX NO: ",pr_company.tax_text[1,23], 
			COLUMN 79, pr_purchhead.com1_text[61,70] 
			PRINT " " 
			PRINT " " 
			PRINT " " 
			PRINT COLUMN 02, "LINE", 
			COLUMN 07, "PRODUCT", 
			COLUMN 33, "UOM", 
			COLUMN 38, "LIST PRICE", 
			COLUMN 51, "DISC %", 
			COLUMN 66, "ORDER QTY", 
			COLUMN 84, "UNIT COST", 
			COLUMN 96, "LINE TOTAL" 
			PRINT " " 
			LET pr_line_num = 0 
		BEFORE GROUP OF pr_purchdetl.order_num 
			SKIP TO top OF PAGE 
			SELECT count(*) INTO pr_detl_count FROM purchdetl 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND order_num = pr_purchdetl.order_num 
			LET pr_detl2_count = 0 
			LET pr_purchase_total = 0 
		ON EVERY ROW 
			LET pr_note2_count = 0 
			LET pr_note_count = 0 
			LET pr_detl2_count = pr_detl2_count + 1 
			LET pr_note_code = NULL 
			IF pr_purchdetl.note_code IS NOT NULL THEN 
				LET pr_note_code = pr_purchdetl.note_code 
			ELSE 
				IF (pr_purchdetl.desc_text[1,3] = "###" 
				AND pr_purchdetl.desc_text[16,18] = "###") THEN 
					LET pr_note_code = pr_purchdetl.desc_text[4,15] 
				END IF 
			END IF 
			IF pr_note_code IS NOT NULL THEN 
				SELECT count(*) INTO pr_note_count FROM notes 
				WHERE note_code = pr_note_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			END IF 
			CALL po_line_info(glob_rec_kandoouser.cmpy_code, 
			pr_purchdetl.order_num, 
			pr_purchdetl.line_num) 
			RETURNING pr_poaudit.order_qty, 
			pr_poaudit.received_qty, 
			pr_poaudit.voucher_qty, 
			pr_poaudit.unit_cost_amt, 
			pr_poaudit.ext_cost_amt, 
			pr_poaudit.unit_tax_amt, 
			pr_poaudit.ext_tax_amt, 
			pr_poaudit.line_total_amt 
			INITIALIZE pr_product.* TO NULL 
			INITIALIZE pr_prodstatus.* TO NULL 
			LET pr_desc_text = NULL 
			IF pr_purchdetl.type_ind = "I" THEN 
				SELECT * INTO pr_product.* FROM product 
				WHERE part_code = pr_purchdetl.ref_text 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				SELECT * INTO pr_prodstatus.* FROM prodstatus 
				WHERE part_code = pr_purchdetl.ref_text 
				AND ware_code = pr_purchhead.ware_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF pr_purchdetl.note_code IS NOT NULL THEN 
					LET pr_desc_text = pr_purchdetl.desc_text 
				ELSE 
					IF pr_purchdetl.desc_text[1,3] = "###" 
					AND pr_purchdetl.desc_text[16,18] = "###" THEN 
						LET pr_desc_text = pr_purchdetl.desc_text[4,15] 
						LET pr_purchdetl.desc_text = pr_product.desc_text clipped, 
						pr_product.desc2_text 
					END IF 
				END IF 
			END IF 
			IF pr_purchdetl.type_ind = "J" 
			OR pr_purchdetl.type_ind = "G" THEN 
				IF pr_purchdetl.note_code IS NOT NULL THEN 
					LET pr_desc_text = pr_purchdetl.desc_text 
				ELSE 
					IF pr_purchdetl.desc_text[1,3] = "###" 
					AND pr_purchdetl.desc_text[16,18] = "###" THEN 
						LET pr_desc_text = pr_purchdetl.desc_text[4,15] 
					END IF 
				END IF 
			END IF 
			IF pr_poaudit.line_total_amt IS NULL 
			AND pr_purchdetl.ref_text IS NULL THEN 
				IF pr_note_count > 0 THEN 
					PRINT COLUMN 02, pr_purchdetl.line_num USING "###&"; 
				END IF 
			ELSE 
				IF pr_purchdetl.type_ind = "J" THEN 
					# FOR 'J' types, do NOT want TO PRINT ref_text AT all
					LET pr_text = pr_purchdetl.oem_text 
				ELSE 
					LET pr_text = pr_purchdetl.ref_text 
				END IF 
				LET pr_unit_cost = pr_poaudit.unit_cost_amt 
				+ pr_poaudit.unit_tax_amt 
				PRINT COLUMN 02, pr_purchdetl.line_num USING "###&", 
				COLUMN 07, pr_text, 
				COLUMN 33, pr_purchdetl.uom_code, 
				COLUMN 38, pr_purchdetl.list_cost_amt USING "---,--&.&&", 
				COLUMN 51, pr_purchdetl.disc_per USING "##&.&&", 
				COLUMN 65, pr_poaudit.order_qty USING "###,##&.&&", 
				COLUMN 83, pr_unit_cost USING "---,--&.&&", 
				COLUMN 96, pr_poaudit.line_total_amt USING "---,--&.&&" 
				LET pr_purchase_total = pr_purchase_total + pr_poaudit.line_total_amt 
				LET pr_line_num = pr_line_num + 1 
			END IF 
			IF pr_line_num = 22 THEN 
				IF pr_note_count != pr_note2_count 
				OR pr_detl_count != pr_detl2_count THEN 
					PRINT COLUMN 40, "CARRIED FORWARD:", 
					COLUMN 94, pr_purchase_total USING "-,---,--&.&&" 
					SKIP TO top OF PAGE 
				END IF 
			END IF 
			IF (pr_poaudit.line_total_amt IS NOT NULL 
			OR pr_purchdetl.ref_text IS NOT null) 
			AND pr_purchdetl.desc_text IS NOT NULL THEN 
				PRINT COLUMN 07, pr_purchdetl.desc_text clipped 
				LET pr_line_num = pr_line_num + 1 
			END IF 
			IF pr_line_num = 22 THEN 
				IF pr_note_count != pr_note2_count 
				OR pr_detl_count != pr_detl2_count THEN 
					PRINT COLUMN 40, "CARRIED FORWARD:", 
					COLUMN 94, pr_purchase_total USING "-,---,--&.&&" 
					SKIP TO top OF PAGE 
				END IF 
			END IF 
			IF (pr_poaudit.line_total_amt IS NOT NULL 
			OR pr_purchdetl.ref_text IS NOT null) 
			AND pr_purchdetl.desc2_text IS NOT NULL THEN 
				PRINT COLUMN 07, pr_purchdetl.desc2_text clipped 
				LET pr_line_num = pr_line_num + 1 
			END IF 
			IF pr_line_num = 22 THEN 
				IF pr_note_count != pr_note2_count 
				OR pr_detl_count != pr_detl2_count THEN 
					PRINT COLUMN 40, "CARRIED FORWARD:", 
					COLUMN 94, pr_purchase_total USING "-,---,--&.&&" 
					SKIP TO top OF PAGE 
				END IF 
			END IF 
			IF pr_purchdetl.type_ind = "I" 
			OR pr_purchdetl.type_ind = "G" THEN 
				IF pr_poaudit.line_total_amt IS NOT NULL 
				OR pr_purchdetl.ref_text IS NOT NULL THEN 
					PRINT COLUMN 07, pr_purchdetl.oem_text 
					LET pr_line_num = pr_line_num + 1 
				END IF 
			END IF 
			IF pr_line_num = 22 THEN 
				IF pr_note_count != pr_note2_count 
				OR pr_detl_count != pr_detl2_count THEN 
					PRINT COLUMN 40, "CARRIED FORWARD:", 
					COLUMN 94, pr_purchase_total USING "-,---,--&.&&" 
					SKIP TO top OF PAGE 
				END IF 
			END IF 
			LET query_text = NULL 
			IF pr_purchdetl.note_code IS NOT NULL THEN 
				LET query_text = "SELECT note_text, note_num FROM notes ", 
				"WHERE cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
				"AND note_code = '",pr_purchdetl.note_code, "' ", 
				"ORDER BY note_num" 
			ELSE 
				IF pr_desc_text IS NOT NULL THEN 
					LET query_text = "SELECT note_text, note_num FROM notes ", 
					"WHERE cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
					"AND note_code = '", pr_desc_text, "' ", 
					"ORDER BY note_num" 
				END IF 
			END IF 
			IF query_text IS NOT NULL THEN 
				PREPARE p_notes FROM query_text 
				DECLARE c_notes CURSOR FOR p_notes 
				FOREACH c_notes INTO pr_note_text 
					PRINT COLUMN 07, pr_note_text 
					LET pr_note2_count = pr_note2_count + 1 
					LET pr_line_num = pr_line_num + 1 
					IF pr_line_num = 22 THEN 
						IF pr_note_count != pr_note2_count 
						OR pr_detl_count != pr_detl2_count THEN 
							PRINT COLUMN 40, "CARRIED FORWARD:", 
							COLUMN 94, pr_purchase_total USING "-,---,--&.&&" 
							SKIP TO top OF PAGE 
						END IF 
					END IF 
				END FOREACH 
			END IF 
		AFTER GROUP OF pr_purchdetl.order_num 
			IF pr_purchhead.note_code IS NOT NULL THEN 
				LET pr_note2_count = 0 
				LET pr_note_count = 0 
				LET pr_note_code = pr_purchhead.note_code 
				IF pr_note_code IS NOT NULL THEN 
					SELECT count(*) INTO pr_note_count FROM notes 
					WHERE note_code = pr_note_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				END IF 
				PRINT " " 
				LET pr_line_num = pr_line_num + 1 
				IF pr_line_num = 22 THEN 
					IF pr_note_count != pr_note2_count 
					OR pr_detl_count != pr_detl2_count THEN 
						PRINT COLUMN 40, "CARRIED FORWARD:", 
						COLUMN 94, pr_purchase_total USING "-,---,--&.&&" 
						SKIP TO top OF PAGE 
					END IF 
				END IF 
				DECLARE c_notes2 CURSOR FOR 
				SELECT * INTO pr_notes.* FROM notes 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND note_code = pr_note_code 
				FOREACH c_notes2 INTO pr_notes.* 
					PRINT COLUMN 07, pr_notes.note_text 
					LET pr_note2_count = pr_note2_count + 1 
					LET pr_line_num = pr_line_num + 1 
					IF pr_line_num = 22 THEN 
						IF pr_note_count != pr_note2_count 
						OR pr_detl_count != pr_detl2_count THEN 
							PRINT COLUMN 40, "CARRIED FORWARD:", 
							COLUMN 94, pr_purchase_total USING "-,---,--&.&&" 
							SKIP TO top OF PAGE 
						END IF 
					END IF 
				END FOREACH 
				IF pr_note_count > 0 THEN 
					PRINT " " 
					LET pr_line_num = pr_line_num + 1 
					IF pr_line_num = 22 THEN 
						IF pr_note_count != pr_note2_count 
						OR pr_detl_count != pr_detl2_count THEN 
							PRINT COLUMN 40, "CARRIED FORWARD:", 
							COLUMN 94, pr_purchase_total USING "-,---,--&.&&" 
							SKIP TO top OF PAGE 
						END IF 
					END IF 
				END IF 
			END IF 
			FOR i = pr_line_num TO 22 
				PRINT " " 
			END FOR 
			PRINT COLUMN 10,"TERMS: ", pr_term.desc_text, 
			COLUMN 94,pr_purchase_total USING "-,---,--&.&&" 
			LET pr_purchase_total = 0 
			UPDATE purchhead 
			SET printed_flag = "Y" 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND order_num = pr_purchhead.order_num 
END REPORT 
