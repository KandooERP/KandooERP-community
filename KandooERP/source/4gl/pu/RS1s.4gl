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

# Purpose - po_print_04 prints purchase orders (FORMAT ind 04)
# Layout  - Page length = 66
#           Page width  = 86
#           Other features: Utilises compressed/emphasized/double space
#                           ASCII PRINT commands


FUNCTION po_print_04(p_cmpy, p_kandoouser_sign_on_code, where_text) 
	DEFINE 
	pr_purchdetl RECORD LIKE purchdetl.*, 
	where_text CHAR(550), 
	query_text CHAR(900), 
	p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code, 
	p_cmpy LIKE company.cmpy_code, 
	pr_save_order_num LIKE purchhead.order_num, 
	rpt_note2 LIKE rmsreps.report_text, 
	pr_report_started, pr_interrupt_flag, pr_showtots SMALLINT 
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]

	SELECT company.* 
	INTO pr_company.* 
	FROM company 
	WHERE cmpy_code = p_cmpy 
	IF status = notfound THEN 
		ERROR "Company NOT found" 
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

	PREPARE p_order FROM query_text 
	DECLARE po_curs CURSOR with HOLD FOR p_order 

	--   OPEN WINDOW w1 AT 15,15 with 1 rows, 40 columns  -- albo  KD-756
	--      ATTRIBUTE(border)
	LET pr_save_order_num = 0 
	LET pr_report_started = false 
	LET pr_interrupt_flag = false 
	FOREACH po_curs INTO pr_purchdetl.* 
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

			IF pr_purchtype.rms_flag = 'N' THEN 
				IF pr_report_started THEN 

					#------------------------------------------------------------
					FINISH REPORT RS1_rpt_list_04
					CALL rpt_finish("RS1_rpt_list_04")
					#------------------------------------------------------------	
				
				END IF 
				LET rpt_note2 = "Purchase Order ", 
				pr_purchdetl.order_num USING "<<<<<<<<" clipped, " ", 
				pr_purchtype.desc_text clipped 
				LET pr_report_started = false 
			END IF 
			IF NOT pr_report_started THEN 

				#------------------------------------------------------------
				LET l_rpt_idx = rpt_start("RS1-04","RS1_rpt_list_04","N/A", RPT_SHOW_RMS_DIALOG)
				IF l_rpt_idx = 0 THEN #User pressed CANCEL
					RETURN FALSE
				END IF	

				CALL rpt_set_header_footer_line_2_append(rpt_rmsreps_idx_get_idx("RS1_rpt_list_04"),NULL, "pr_purchtype.desc_text")
								
				START REPORT RS1_rpt_list_04 TO rpt_get_report_file_with_path2(l_rpt_idx)
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
		OUTPUT TO REPORT RS1_rpt_list_04(l_rpt_idx,
		pr_purchdetl.*) 
		#---------------------------------------------------------
 
	END FOREACH 
	--   CLOSE WINDOW w1  -- albo  KD-756

	IF pr_report_started THEN 

		#------------------------------------------------------------
		FINISH REPORT RS1_rpt_list_04
		CALL rpt_finish("RS1_rpt_list_04")
		#------------------------------------------------------------	

	END IF 

	RETURN pr_output, pr_interrupt_flag 
END FUNCTION 

REPORT RS1_rpt_list_04(p_rpt_idx, pr_purchdetl)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx] 
	DEFINE 
	pr_purchhead RECORD LIKE purchhead.*, 
	pr_purchdetl RECORD LIKE purchdetl.*, 
	pr_poaudit RECORD LIKE poaudit.*, 
	pr_vendor RECORD LIKE vendor.*, 
	pr_product RECORD LIKE product.*, 
	pr_term_desc LIKE term.desc_text, 
	pr_note_mark1, pr_note_mark2 CHAR(3), 
	pr_temp_text CHAR(12), 
	pr_note_info CHAR(70), 
	pr_page, pr_pagecnt INTEGER, 
	pr_cost_total DECIMAL(16,2), 
	pr_order_tot, 
	pr_tax_tot, 
	pr_received_tot, 
	pr_vouch_tot, 
	pr_unit_tax DECIMAL(12,2), 
	pr_cnt,pr_linecnt,pr_showtots SMALLINT 

	OUTPUT 


	ORDER external BY pr_purchdetl.order_num, pr_purchdetl.line_num 

	FORMAT 
		AFTER GROUP OF pr_purchdetl.order_num 
			LET pr_showtots = true 
			LET pr_linecnt = 0 
			LET pr_pagecnt = 0 

			UPDATE purchhead SET printed_flag = "Y" 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND order_num = pr_purchhead.order_num 

			LET pr_pagecnt = 0 

		BEFORE GROUP OF pr_purchdetl.order_num 
			LET pr_cost_total = 0 
			SKIP TO top OF PAGE 

		PAGE HEADER 
			LET pr_page = pr_page + 1 
			LET pr_pagecnt = pr_pagecnt + 1 
			SKIP 10 LINES 
			### Special ASCII commands FOR Emphasized/Enlarged printing AT ASG###
			PRINT ascii(pr_printcodes.compress_11), 
			ascii(pr_printcodes.compress_12), 
			ascii(pr_printcodes.compress_13), 
			ascii(pr_printcodes.compress_14), 
			ascii(pr_printcodes.compress_15), 
			ascii(pr_printcodes.compress_16), 
			ascii(pr_printcodes.compress_17), 
			ascii(pr_printcodes.compress_18), 
			ascii(pr_printcodes.compress_19), 
			ascii(pr_printcodes.compress_20); 
			PRINT COLUMN 026, "PURCHASE ORDER" 
			PRINT ascii(pr_printcodes.normal_1), 
			ascii(pr_printcodes.normal_2), 
			ascii(pr_printcodes.normal_3), 
			ascii(pr_printcodes.normal_4), 
			ascii(pr_printcodes.normal_5), 
			ascii(pr_printcodes.normal_6), 
			ascii(pr_printcodes.normal_7), 
			ascii(pr_printcodes.normal_8), 
			ascii(pr_printcodes.normal_9), 
			ascii(pr_printcodes.normal_10) 
			### Special ASCII commands FOR Emphasized/Enlarged printing AT ASG###

			SELECT * INTO pr_vendor.* 
			FROM vendor 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND vend_code = pr_purchdetl.vend_code 

			SELECT * INTO pr_purchhead.* 
			FROM purchhead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND vend_code = pr_purchdetl.vend_code 
			AND order_num = pr_purchdetl.order_num 

			PRINT COLUMN 054, "Order No:", 
			COLUMN 065, pr_purchdetl.order_num USING "<<<<<<<<<<" 
			PRINT COLUMN 054, "Date:", 
			COLUMN 065, pr_purchhead.order_date USING "dd-mmm-yy" 
			PRINT COLUMN 054, "Page No:", 
			COLUMN 063, pr_pagecnt USING "##&" 
			SKIP 2 line 
			### Special ASCII commands FOR Emphasized printing AT ASG###
			PRINT COLUMN 016, pr_vendor.contact_text clipped, 
			COLUMN 054, "Delivery Address:" 
			PRINT COLUMN 016, pr_vendor.name_text clipped, 
			COLUMN 054, pr_purchhead.del_name_text 
			PRINT COLUMN 016, pr_vendor.addr1_text clipped, 
			COLUMN 054, pr_purchhead.del_addr1_text clipped 
			IF (pr_vendor.addr2_text IS NOT NULL OR 
			pr_purchhead.del_addr2_text IS NOT null) THEN 
				PRINT COLUMN 016, pr_vendor.addr2_text clipped, 
				COLUMN 054, pr_purchhead.del_addr2_text clipped 
				PRINT COLUMN 016, pr_vendor.city_text clipped, " ", 
				pr_vendor.state_code, " ", pr_vendor.post_code, 
				COLUMN 054, pr_purchhead.del_addr3_text clipped 
			ELSE 
				PRINT COLUMN 016, pr_vendor.city_text clipped, " ", 
				pr_vendor.state_code, 
				2 spaces, pr_vendor.post_code, 
				COLUMN 054, pr_purchhead.del_addr3_text clipped 
				SKIP 1 line 
			END IF 
			### Special ASCII commands FOR Emphasized printing AT ASG###
			PRINT ascii(pr_printcodes.compress_1), 
			ascii(pr_printcodes.compress_2), 
			ascii(pr_printcodes.compress_3), 
			ascii(pr_printcodes.compress_4), 
			ascii(pr_printcodes.compress_5), 
			ascii(pr_printcodes.compress_6), 
			ascii(pr_printcodes.compress_7), 
			ascii(pr_printcodes.compress_8), 
			ascii(pr_printcodes.compress_9), 
			ascii(pr_printcodes.compress_10) 
			SELECT term.desc_text 
			INTO pr_term_desc 
			FROM term 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND term_code = pr_purchhead.term_code 

			SKIP 3 LINES 

			PRINT COLUMN 013, "Qty", 
			COLUMN 022, "Code", 
			COLUMN 039, "Description", 
			COLUMN 077, "Unit", 
			COLUMN 089, "Line", 
			COLUMN 100, "Sales", 
			COLUMN 113, "Line" 
			PRINT COLUMN 076, "Price", 
			COLUMN 089, "Cost", 
			COLUMN 101, "Tax", 
			COLUMN 112, "Total" 
			SKIP 1 line 

		ON EVERY ROW 
			LET pr_showtots = false 
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

			NEED 3 LINES 
			WHENEVER ERROR stop 
			IF pr_poaudit.order_qty IS NULL 
			OR pr_poaudit.order_qty = 0 
			THEN 
				PRINT COLUMN 039, pr_purchdetl.desc_text clipped 
				SKIP 1 line 
			ELSE 
				LET pr_cost_total = pr_cost_total + pr_poaudit.ext_cost_amt 
				IF pr_purchdetl.type_ind = "I" THEN 
					SELECT * INTO pr_product.* FROM product 
					WHERE part_code = pr_purchdetl.ref_text 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					PRINT COLUMN 011, pr_poaudit.order_qty USING "####&", 
					COLUMN 022, pr_product.part_code, 
					COLUMN 039, pr_product.desc_text clipped, 
					COLUMN 071, pr_poaudit.unit_cost_amt USING "---,--&.&&", 
					COLUMN 083, pr_poaudit.ext_cost_amt USING "---,--&.&&", 
					COLUMN 095, pr_poaudit.ext_tax_amt USING "---,--&.&&", 
					COLUMN 107, pr_poaudit.line_total_amt USING "---,--&.&&" 
					PRINT COLUMN 039, pr_product.desc2_text clipped 
				ELSE 
					PRINT COLUMN 011, pr_poaudit.order_qty USING "###&", 
					COLUMN 039, pr_purchdetl.desc_text, 
					COLUMN 071, pr_poaudit.unit_cost_amt USING "--,--&.&&", 
					COLUMN 083, pr_poaudit.ext_cost_amt USING "---,--&.&&", 
					COLUMN 095, pr_poaudit.ext_tax_amt USING "---,--&.&&", 
					COLUMN 107, pr_poaudit.line_total_amt USING "---,--&.&&" 
					PRINT COLUMN 039, pr_purchdetl.desc_text[26,40] 
				END IF 
			END IF 
			LET pr_temp_text = "" 
			IF pr_purchdetl.desc_text[1,3] = "###" 
			AND pr_purchdetl.desc_text[16,18] = "###" THEN 
				LET pr_temp_text = pr_purchdetl.desc_text[4,16] 
			ELSE 
				IF pr_purchdetl.note_code IS NOT NULL THEN 
					LET pr_temp_text = pr_purchdetl.note_code 
				END IF 
			END IF 
			IF pr_temp_text IS NOT NULL THEN 
				DECLARE no_curs CURSOR FOR 
				SELECT note_text, note_num 
				INTO pr_note_info, pr_cnt 
				FROM notes 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND note_code = pr_temp_text 
				ORDER BY note_num 
				FOREACH no_curs 
					PRINT COLUMN 039, pr_note_info 
				END FOREACH 
			END IF 

			PAGE TRAILER 
				SKIP 3 LINES 
				IF pr_showtots THEN 
					CALL po_head_info(glob_rec_kandoouser.cmpy_code,pr_purchhead.order_num) 
					RETURNING pr_order_tot, pr_received_tot, 
					pr_vouch_tot, pr_tax_tot 
					PRINT COLUMN 093, "Cost ", 
					COLUMN 105, pr_cost_total USING "-,---,--&.&&" 
					PRINT COLUMN 093, "Sales Tax ", 
					COLUMN 105, pr_tax_tot USING "-,---,--&.&&" 
					PRINT COLUMN 105, "------------" 
					PRINT COLUMN 058, pr_term_desc clipped, 
					COLUMN 093, "Total Cost ", 
					COLUMN 105, pr_order_tot USING "-,---,--&.&&" 
					PRINT COLUMN 105, "============" 
					PRINT COLUMN 001, " " 
					LET pr_showtots = false 
				ELSE 
					PRINT COLUMN 001, " " 
					PRINT COLUMN 001, " " 
					PRINT COLUMN 001, " " 
					PRINT COLUMN 001, " " 
					PRINT COLUMN 001, " " 
					PRINT COLUMN 050, "*** Continued Next Page ***" 
				END IF 
				PRINT ascii(pr_printcodes.normal_1), 
				ascii(pr_printcodes.normal_2), 
				ascii(pr_printcodes.normal_3), 
				ascii(pr_printcodes.normal_4), 
				ascii(pr_printcodes.normal_5), 
				ascii(pr_printcodes.normal_6), 
				ascii(pr_printcodes.normal_7), 
				ascii(pr_printcodes.normal_8), 
				ascii(pr_printcodes.normal_9), 
				ascii(pr_printcodes.normal_10) 
				SKIP 2 LINES 

		ON LAST ROW 
			LET rpt_pageno = pr_page 
			LET rpt_length = 66 
			LET pr_page = 0 

END REPORT 
