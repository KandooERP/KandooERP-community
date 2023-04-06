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


#  RS1g - Customized Purchase Order PRINT program - FORMAT ind 01


FUNCTION po_print_01(p_cmpy,p_kandoouser_sign_on_code,where_text) 
	DEFINE 
	p_cmpy LIKE company.cmpy_code, 
	p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code, 
	where_text CHAR(550), 
	pr_purchhead RECORD LIKE purchhead.*, 
	pr_purchdetl RECORD LIKE purchdetl.*, 
	pr_save_order_num LIKE purchhead.order_num, 
	query_text CHAR(800), 
	rpt_note2 LIKE rmsreps.report_text, 
	pr_report_started, pr_interrupt_flag SMALLINT 
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]


	LET query_text = "SELECT purchhead.*,", 
	"purchdetl.* ", 
	"FROM purchdetl,", 
	"purchhead ", 
	" WHERE purchhead.cmpy_code='",p_cmpy,"' ", 
	"AND purchdetl.cmpy_code='",p_cmpy,"' ", 
	"AND purchhead.order_num=purchdetl.order_num ", 
	"AND ",where_text clipped, " ", 
	"ORDER BY purchdetl.order_num, purchdetl.line_num " 
	PREPARE s_purchdetl FROM query_text 
	DECLARE c_purchdetl CURSOR with HOLD FOR s_purchdetl 
	--   OPEN WINDOW w1 AT 15,15 with 1 rows, 40 columns  -- albo  KD-756
	--      ATTRIBUTE(border,cyan)
	LET pr_save_order_num = 0 
	LET pr_report_started = false 
	LET pr_interrupt_flag = false 
	FOREACH c_purchdetl INTO pr_purchhead.*, 
		pr_purchdetl.* 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			#8002 Do you wish TO quit (Y/N)?
			IF kandoomsg("U",8002,"") = 'Y' THEN 
				LET pr_interrupt_flag = true 
				EXIT FOREACH 
			END IF 
		END IF 
		IF pr_save_order_num != pr_purchhead.order_num THEN 
			LET pr_save_order_num = pr_purchhead.order_num 
			DISPLAY "" at 1,10 
			DISPLAY " Purchase Order: ", pr_save_order_num at 1,10 

			IF pr_purchhead.printed_flag != 'Y' THEN 
				WHENEVER ERROR CONTINUE ## printed_flag UPDATE NOT important 
				UPDATE purchhead 
				SET printed_flag = 'Y' 
				WHERE cmpy_code = pr_purchhead.cmpy_code 
				AND vend_code = pr_purchhead.vend_code 
				AND order_num = pr_purchhead.order_num 
				WHENEVER ERROR stop 
			END IF 
			# New PO number may mean new RMS file, depending on flag
			IF pr_purchtype.rms_flag = 'N' THEN 
				IF pr_report_started THEN 

					#------------------------------------------------------------
					FINISH REPORT RS1_rpt_list_01
					CALL rpt_finish("RS1_rpt_list_01")
					#------------------------------------------------------------	 

				END IF 
				LET rpt_note2 = "Purchase Order ", 
				pr_purchdetl.order_num USING "<<<<<<<<" clipped, " ", 
				pr_purchtype.desc_text clipped 
				LET pr_report_started = false 
			END IF 
			IF NOT pr_report_started THEN 
				#------------------------------------------------------------
				LET l_rpt_idx = rpt_start("RS1-01","RS1_rpt_list_01","N/A", RPT_SHOW_RMS_DIALOG)
				IF l_rpt_idx = 0 THEN #User pressed CANCEL
					RETURN FALSE
				END IF	

				CALL rpt_set_header_footer_line_2_append(rpt_rmsreps_idx_get_idx("RS1_rpt_list_01"),NULL, "pr_purchtype.desc_text")				
				
				START REPORT RS1_rpt_list_01 TO rpt_get_report_file_with_path2(l_rpt_idx)
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
		OUTPUT TO REPORT RS1_rpt_list_01(l_rpt_idx,
		pr_purchhead.*,pr_purchdetl.*)   
		#---------------------------------------------------------		

	END FOREACH 
	IF pr_report_started THEN 

		#------------------------------------------------------------
		FINISH REPORT RS1_rpt_list_01
		CALL rpt_finish("RS1_rpt_list_01")
		#------------------------------------------------------------	 

	END IF 
	--   CLOSE WINDOW w1  -- albo  KD-756
	RETURN pr_output, pr_interrupt_flag 
END FUNCTION 


REPORT RS1_rpt_list_01(p_rpt_idx,pr_purchhead,pr_purchdetl)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx] 
	DEFINE 
	pr_purchhead RECORD LIKE purchhead.*, 
	pr_purchdetl RECORD LIKE purchdetl.*, 
	#pr_warehouse RECORD LIKE warehouse.*,
	pr_vendor RECORD LIKE vendor.*, 
	pr_poaudit RECORD LIKE poaudit.*, 
	pr_order_total DECIMAL(9,2), 
	pr_vend_ad1,pr_vend_ad2,pr_vend_ad3,pr_vend_ad4 CHAR(32), 
	pr_line_text CHAR(29), 
	pr_note_text LIKE notes.note_text, 
	pr_note_code LIKE notes.note_code, 
	pr_page_num INTEGER, 
	pr_crry_fwd_text CHAR(5), 
	pr_linecnt,pr_purch_cnt SMALLINT, 
	i SMALLINT 

	OUTPUT 
#	PAGE length 66 
#	#top margin 11
#	top margin 00 
#	bottom margin 13 
#	left margin 0 
	ORDER external BY pr_purchdetl.order_num, 
	pr_purchdetl.line_num 
	FORMAT 
		PAGE HEADER 
			LET pr_linecnt = 0 
			SKIP 1 line 
			PRINT COLUMN 48,'purchase order'; 
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
			SKIP 1 line 
			SELECT * INTO pr_vendor.* FROM vendor 
			WHERE cmpy_code = p_cmpy 
			AND vend_code = pr_purchdetl.vend_code 
			IF sqlca.sqlcode = notfound THEN 
				LET pr_vendor.name_text = "*** Vendor NOT SET up ***" 
			END IF 
			LET pr_vend_ad1 = pr_vendor.addr1_text clipped 
			LET pr_vend_ad2 = pr_vendor.addr2_text clipped 
			LET pr_vend_ad3 = pr_vendor.addr3_text clipped 
			LET pr_vend_ad4 = pr_vendor.city_text clipped," ", 
			pr_vendor.state_code clipped," ", 
			pr_vendor.post_code clipped 
			IF pr_vend_ad3 IS NULL THEN 
				LET pr_vend_ad3 = pr_vend_ad4 
				INITIALIZE pr_vend_ad4 TO NULL 
			END IF 
			IF pr_vend_ad2 IS NULL THEN 
				LET pr_vend_ad2 = pr_vend_ad3 
				INITIALIZE pr_vend_ad3 TO NULL 
			END IF 
			LET pr_page_num = pr_page_num + 1 
			PRINT COLUMN 87, "Page No:", 
			COLUMN 97, pr_page_num USING "<<<<<<<<" 
			PRINT COLUMN 14, pr_vendor.name_text, 
			COLUMN 52, pr_purchhead.del_name_text[1,32] clipped, 
			COLUMN 87, "Order No:", 
			COLUMN 97, pr_purchdetl.order_num USING "########" 
			PRINT COLUMN 14, pr_vend_ad1 clipped, 
			COLUMN 52, pr_purchhead.del_addr1_text[1,32], 
			COLUMN 87, "Account:", 
			COLUMN 97, pr_purchdetl.vend_code 
			PRINT COLUMN 14, pr_vend_ad2 clipped, 
			COLUMN 52, pr_purchhead.del_addr2_text[1,32], 
			COLUMN 87, "Date:", 
			COLUMN 97, pr_purchhead.order_date USING "dd-mm-yyyy" 
			PRINT COLUMN 14, pr_vend_ad3 clipped, 
			COLUMN 52, pr_purchhead.del_addr3_text[1,32], 
			COLUMN 87, "Due Date:", 
			COLUMN 97, pr_purchhead.due_date USING "dd-mm-yyyy" 
			PRINT COLUMN 14, pr_vend_ad4 clipped, 
			COLUMN 52, pr_purchhead.del_addr4_text[1,32], 
			COLUMN 87, "Our Ref:", 
			COLUMN 97, pr_purchhead.authorise_code 
			SKIP 1 line 
			PRINT COLUMN 06, "Product", 
			COLUMN 22, "Description", 
			COLUMN 52, "OEM", 
			COLUMN 70, "Quantity" , 
			COLUMN 90, "Cost", 
			COLUMN 101,"Total" 
			SKIP 1 LINES 
		BEFORE GROUP OF pr_purchdetl.order_num 
			SKIP TO top OF PAGE 
			LET pr_order_total = 0 
			LET pr_crry_fwd_text = 'c/fwd' 
		ON EVERY ROW 
			#  LET pr_linecnt = pr_linecnt + 1
			#  IF pr_linecnt >= 19 THEN
			#    LET pr_crry_fwd_text = 'C/Fwd'
			#     skip TO top of page
			#  ELSE
			#     LET pr_crry_fwd_text = NULL
			#  END IF
			INITIALIZE pr_poaudit.* TO NULL 
			CALL po_line_info(glob_rec_kandoouser.cmpy_code,pr_purchdetl.order_num, 
			pr_purchdetl.line_num) 
			RETURNING pr_poaudit.order_qty, 
			pr_poaudit.received_qty, 
			pr_poaudit.voucher_qty, 
			pr_poaudit.unit_cost_amt, 
			pr_poaudit.ext_cost_amt, 
			pr_poaudit.unit_tax_amt, 
			pr_poaudit.ext_tax_amt, 
			pr_poaudit.line_total_amt 
			IF pr_purchdetl.desc_text[1,3] = "###" 
			AND pr_purchdetl.desc_text[16,18] = "###" THEN 
				LET pr_line_text = NULL 
				LET pr_note_code = pr_purchdetl.desc_text[4,15] 
				IF pr_purchdetl.type_ind = "I" THEN 
					SELECT desc_text INTO pr_line_text 
					FROM product 
					WHERE cmpy_code = pr_purchdetl.cmpy_code 
					AND part_code = pr_purchdetl.ref_text 
				END IF 
			ELSE 
				LET pr_note_code = NULL 
				LET pr_line_text = pr_purchdetl.desc_text 
			END IF 
			PRINT COLUMN 06, pr_purchdetl.ref_text clipped, 
			COLUMN 22, pr_line_text, 
			COLUMN 52, pr_purchdetl.oem_text clipped, 
			COLUMN 68, pr_poaudit.order_qty USING "-------&.&", 
			COLUMN 79, pr_purchdetl.uom_code, 
			COLUMN 84, pr_poaudit.unit_cost_amt USING "----&.&&&&", 
			COLUMN 95, pr_poaudit.line_total_amt USING "-------&.&&" 
			LET pr_order_total = pr_order_total + pr_poaudit.line_total_amt 
			IF pr_note_code IS NOT NULL THEN 
				DECLARE c_notes CURSOR FOR 
				SELECT note_text, note_num 
				FROM notes 
				WHERE cmpy_code = pr_purchdetl.cmpy_code 
				AND note_code = pr_note_code 
				ORDER BY note_num 
				FOREACH c_notes INTO pr_note_text, i 
					PRINT COLUMN 22, pr_note_text 
				END FOREACH 
			END IF 
		AFTER GROUP OF pr_purchdetl.order_num 
			IF pr_purchtype.footer1_text IS NOT NULL THEN 
				LET pr_purch_cnt = pr_purch_cnt + 1 
			END IF 
			IF pr_purchtype.footer2_text IS NOT NULL THEN 
				LET pr_purch_cnt = pr_purch_cnt + 1 
			END IF 
			IF pr_purchtype.footer3_text IS NOT NULL THEN 
				LET pr_purch_cnt = pr_purch_cnt + 1 
			END IF 
			IF pr_purch_cnt != 0 THEN 
				LET pr_purch_cnt = pr_purch_cnt + 2 
				NEED pr_purch_cnt LINES 
				SKIP 2 LINES 
				IF pr_purchtype.footer1_text IS NOT NULL THEN 
					PRINT COLUMN 22, pr_purchtype.footer1_text 
				END IF 
				IF pr_purchtype.footer2_text IS NOT NULL THEN 
					PRINT COLUMN 22, pr_purchtype.footer2_text 
				END IF 
				IF pr_purchtype.footer3_text IS NOT NULL THEN 
					PRINT COLUMN 22, pr_purchtype.footer3_text 
				END IF 
			END IF 
			LET pr_crry_fwd_text = NULL 
			LET pr_purch_cnt = 0 
			LET pr_page_num = 0 
			PAGE TRAILER 
				SKIP 1 LINES 
				IF pr_crry_fwd_text IS NULL THEN 
					PRINT COLUMN 80, "Order Total:", 
					COLUMN 93, pr_order_total USING "---------&.&&" 
				ELSE 
					PRINT COLUMN 98, pr_crry_fwd_text 
				END IF 
				SKIP 6 LINES 
				PRINT COLUMN 70, 'Printed',' ',today USING "dd-mm-yyyy",' ',time 
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
		ON LAST ROW 
			LET rpt_pageno=pageno 
			LET rpt_width=132 
			LET rpt_length=66 
END REPORT 
