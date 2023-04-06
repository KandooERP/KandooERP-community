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

# Purpose - po_print_00 prints purchase orders (FORMAT ind 00, 80 col )



FUNCTION po_print_00(p_cmpy, p_kandoouser_sign_on_code, where_text) 
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
	--      ATTRIBUTE(border,cyan)
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

			# New PO number may mean new RMS file, depending on flag
			IF pr_purchtype.rms_flag = 'N' THEN 
				IF pr_report_started THEN 
					#------------------------------------------------------------
					FINISH REPORT RS1_rpt_list_00
					CALL rpt_finish("RS1_rpt_list_00")
					#------------------------------------------------------------	 
				
				END IF 
				LET rpt_note2 = "Purchase Order ", 
				pr_purchdetl.order_num USING "<<<<<<<<" clipped, " ", 
				pr_purchtype.desc_text clipped 
				LET pr_report_started = false 
			END IF 
			IF NOT pr_report_started THEN 

				#------------------------------------------------------------
				LET l_rpt_idx = rpt_start("RS1-00","RS1_rpt_list_00","N/A", RPT_SHOW_RMS_DIALOG)
				IF l_rpt_idx = 0 THEN #User pressed CANCEL
					RETURN FALSE
				END IF	
				
				CALL rpt_set_header_footer_line_2_append(rpt_rmsreps_idx_get_idx("RS1_rpt_list_00"),NULL, "pr_purchtype.desc_text")
				--LET rpt_note = "Purchase Orders - ", pr_purchtype.desc_text clipped 
				
				START REPORT RS1_rpt_list_00 TO rpt_get_report_file_with_path2(l_rpt_idx)
				WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
				TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
				BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
				LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
				RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
				#------------------------------------------------------------
			
--				LET pr_output = init_report(p_cmpy,p_kandoouser_sign_on_code,rpt_note2) 
--				START REPORT RS1_rpt_list_00 TO pr_output
				 
				LET pr_report_started = true 
			END IF 
		END IF 
		
		#---------------------------------------------------------		
		OUTPUT TO REPORT RS1_rpt_list_00(l_rpt_idx,
		pr_purchdetl.*) 
		#---------------------------------------------------------
		
	END FOREACH 
	--   CLOSE WINDOW w1  -- albo  KD-756

	IF pr_report_started THEN
		#------------------------------------------------------------
		FINISH REPORT RS1_rpt_list_00
		CALL rpt_finish("RS1_rpt_list_00")
		#------------------------------------------------------------	 
	END IF 

	RETURN pr_output, pr_interrupt_flag 
END FUNCTION 

REPORT RS1_rpt_list_00(p_rpt_idx,pr_purchdetl) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE pr_purchhead RECORD LIKE purchhead.* 
	DEFINE pr_purchdetl RECORD LIKE purchdetl.* 
	DEFINE pr_poaudit RECORD LIKE poaudit.* 
	DEFINE linecnt SMALLINT 
	DEFINE pr_vendor RECORD LIKE vendor.* 
	DEFINE pr_term RECORD LIKE term.* 
	DEFINE note_mark1 CHAR(3) 
	DEFINE note_mark2 CHAR(3) 

	DEFINE temp_text CHAR(12) 
	DEFINE note_info CHAR(70) 
	DEFINE lab_frt money(12,2) 
	DEFINE l_PAGE INTEGER 
	DEFINE pagcount INTEGER 
	DEFINE order_tot money(12,2) 
	DEFINE tax_tot money(12,2)
	DEFINE received_tot money(12,2)
	DEFINE voucher_tot money(12,2)	
	DEFINE cnt SMALLINT 
	DEFINE lncounter SMALLINT 

	OUTPUT 

	ORDER external BY pr_purchdetl.order_num, pr_purchdetl.line_num 

	FORMAT 

		AFTER GROUP OF pr_purchdetl.order_num 
			LET lncounter = 0 
			LET pagcount = 0 

			UPDATE purchhead SET printed_flag = "Y" 
			WHERE cmpy_code = p_cmpy 
			AND order_num = pr_purchhead.order_num 

			LET pagcount = 0 

		BEFORE GROUP OF pr_purchdetl.order_num 
			SKIP TO top OF PAGE 

		PAGE HEADER 
			LET l_PAGE = l_page + 1 
			LET pagcount = pagcount + 1 
			SKIP 1 line 
			PRINT COLUMN 7, 
			pr_company.name_text clipped 
			PRINT COLUMN 7, pr_company.addr1_text 
			IF pr_company.addr2_text IS NOT NULL THEN 
				PRINT COLUMN 7, pr_company.addr2_text 
				PRINT COLUMN 7, pr_company.city_text clipped, ", ", 
				pr_company.state_code, " ", pr_company.post_code clipped 
				PRINT COLUMN 7, pr_company.tele_text 
			ELSE 
				PRINT COLUMN 7, pr_company.city_text clipped, ", ", 
				pr_company.state_code, " ", pr_company.post_code clipped 
				PRINT COLUMN 7, pr_company.tele_text 
				SKIP 1 line 
			END IF 
			SKIP 1 line 

			SELECT * INTO pr_vendor.* 
			FROM vendor 
			WHERE cmpy_code = p_cmpy 
			AND vend_code = pr_purchdetl.vend_code 

			SELECT * INTO pr_purchhead.* 
			FROM purchhead 
			WHERE cmpy_code = p_cmpy 
			AND vend_code = pr_purchdetl.vend_code 
			AND order_num = pr_purchdetl.order_num 

			PRINT COLUMN 26, pr_purchdetl.order_num USING "#######", 
			COLUMN 48, pr_purchhead.order_date USING "ddd dd mmm yy" 
			SKIP 4 LINES 

			#       PRINT COLUMN 11, "Bill TO:",
			#             COLUMN 45, "Deliver TO:"
			PRINT COLUMN 11, pr_vendor.name_text, 
			COLUMN 45, pr_purchhead.del_name_text 
			PRINT COLUMN 11, pr_vendor.addr1_text, 
			COLUMN 45, pr_purchhead.del_addr1_text 
			IF (pr_vendor.addr2_text IS NOT NULL OR 
			pr_purchhead.del_addr2_text IS NOT null) THEN 
				PRINT COLUMN 11, pr_vendor.addr2_text, 
				COLUMN 45, pr_purchhead.del_addr2_text 
				PRINT COLUMN 11, pr_vendor.city_text clipped, " ", 
				pr_vendor.state_code, 2 spaces, 
				pr_vendor.post_code, 
				COLUMN 45, pr_purchhead.del_addr3_text clipped 
			ELSE 
				PRINT COLUMN 11, pr_vendor.city_text clipped, " ", 
				pr_vendor.state_code, 
				2 spaces, pr_vendor.post_code, 
				COLUMN 45, pr_purchhead.del_addr3_text clipped 
				SKIP 1 line 
			END IF 

			INITIALIZE pr_term.* TO NULL 

			SELECT term.desc_text 
			INTO pr_term.desc_text 
			FROM term 
			WHERE cmpy_code = p_cmpy 
			AND term_code = pr_purchhead.term_code 

			SKIP 3 LINES 
			PRINT COLUMN 60, "Page: ", pagcount USING "###" 
			SKIP 6 LINES 

		ON EVERY ROW 
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

			IF pr_poaudit.order_qty IS NULL 
			OR pr_poaudit.order_qty = 0 THEN 
				PRINT COLUMN 17, pr_purchdetl.desc_text 
			ELSE 
				PRINT COLUMN 5, pr_poaudit.order_qty USING "########.&", 
				COLUMN 17, pr_purchdetl.desc_text[1,28], 
				COLUMN 45, pr_poaudit.unit_cost_amt USING "-,---,--&.&&", 
				COLUMN 61, pr_poaudit.ext_cost_amt USING "-,---,--&.&&" 
			END IF 
			IF pr_purchdetl.desc2_text IS NOT NULL THEN 
				PRINT COLUMN 17, pr_purchdetl.desc2_text[1,28] 
			END IF 
			IF pr_purchdetl.note_code IS NOT NULL THEN 
				DECLARE c_notes CURSOR FOR 
				SELECT note_text, note_num FROM notes 
				WHERE cmpy_code = p_cmpy 
				AND note_code = pr_purchdetl.note_code 
				ORDER BY note_num 
				FOREACH c_notes INTO note_info 
					PRINT COLUMN 22, note_info 
				END FOREACH 
			END IF 

			PAGE TRAILER 
				CALL po_head_info(glob_rec_kandoouser.cmpy_code,pr_purchhead.order_num) 
				RETURNING order_tot, received_tot, voucher_tot, tax_tot 
				SKIP 3 LINES 
				PRINT COLUMN 61, tax_tot USING "-,---,--&.&&" 
				SKIP 3 LINES 
				PRINT COLUMN 25, pr_term.desc_text, 
				COLUMN 61, order_tot USING "-,---,--&.&&" 
				SKIP 2 LINES 

			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	
			

END REPORT 
