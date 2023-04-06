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
GLOBALS "../pu/RS5_GLOBALS.4gl" 
# \brief module - Rs1c (RS5c !!!) copied FROM RS1m.4gl
# Purpose - po_print_07 prints purchase orders in site specific FORMAT


DEFINE 
esc CHAR(1), 
standouton CHAR(80), 
standoutmid CHAR(80), 
standoutsml CHAR(80), 
standoutoff CHAR(80), 
undscoreon CHAR(20), 
undscoreoff CHAR(20) 

FUNCTION po_print_07(p_cmpy, p_kandoouser_sign_on_code, where_text)
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx] 
	DEFINE 
	pr_purchdetl RECORD LIKE purchdetl.*, 
	where_text CHAR(550), 
	query_text CHAR(900), 
	p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code, 
	p_cmpy LIKE company.cmpy_code, 
	pr_save_order_num LIKE purchhead.order_num, 
	rpt_note2 LIKE rmsreps.report_text, 
	pr_report_started, pr_interrupt_flag SMALLINT 
	LET esc = ascii(27) 
	LET standouton = esc,"(s1p18v0s3b4101T",esc,"&l3D" 
	LET standoutmid = esc, "(s1p16v0s3b4101T",esc,"&l4D" 
	LET standoutsml = esc, "(s1p10v0s0b4101T",esc,"&l8D" 
	LET standoutoff = esc, "(s0p11v0s0b3T",esc,"&l8D" 
	#   LET undscoreon = esc, "&d3D"
	#   LET undscoreoff = esc, "&d@"

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

			DISPLAY " Purchase Order: ", pr_purchdetl.order_num at 1,10 

			IF pr_purchtype.rms_flag = 'N' THEN 
				IF pr_report_started THEN 

					#------------------------------------------------------------
					FINISH REPORT RS1_rpt_list_07
					CALL rpt_finish("RS1_rpt_list_07")
					#------------------------------------------------------------					
					
				END IF 
				LET rpt_note2 = "Purchase Order ", 
				pr_purchdetl.order_num USING "<<<<<<<<" clipped, " ", 
				pr_purchtype.desc_text clipped 
				LET pr_report_started = false 
			END IF 
			IF NOT pr_report_started THEN

				#------------------------------------------------------------
				LET l_rpt_idx = rpt_start("RS1-07","RS1_rpt_list_07","N/A", RPT_SHOW_RMS_DIALOG)
				IF l_rpt_idx = 0 THEN #User pressed CANCEL
					RETURN FALSE
				END IF	
				
				CALL rpt_set_header_footer_line_2_append(rpt_rmsreps_idx_get_idx("RS1_rpt_list_07"),NULL, "pr_purchtype.desc_text")
				
				START REPORT RS1_rpt_list_07 TO rpt_get_report_file_with_path2(l_rpt_idx)
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
		OUTPUT TO REPORT RS1_rpt_list_07(l_rpt_idx,
		pr_purchdetl.*)  
		#---------------------------------------------------------		

	END FOREACH 
	--   CLOSE WINDOW w1  -- albo  KD-756
	IF pr_report_started THEN 
	
		#------------------------------------------------------------
		FINISH REPORT RS1_rpt_list_07
		CALL rpt_finish("RS1_rpt_list_07")
		#------------------------------------------------------------	 
	END IF 
	RETURN pr_output, pr_interrupt_flag 
END FUNCTION 


REPORT RS1_rpt_list_07(p_rpt_idx,pr_purchdetl)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE 
	pr_purchhead RECORD LIKE purchhead.*, 
	pr_purchdetl RECORD LIKE purchdetl.*, 
	pr_purchtype RECORD LIKE purchtype.*, 
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
	pr_text CHAR(30), 

	pv_cont_text CHAR(40), 
	pv_ord_date LIKE purchhead.order_date, 
	pv_footer_text CHAR(200), 
	rpt_wid LIKE rmsreps.report_width_num, 
	line1 CHAR(30), 
	offset1, pv_name_len SMALLINT 


	OUTPUT 
--	left margin 0 
--	right margin 120 
--	top margin 0 
--	bottom margin 0 
--	  page length 51
	PAGE length 66 
	ORDER external BY pr_purchdetl.order_num, pr_purchdetl.line_num
	 
	FORMAT 
		FIRST PAGE HEADER 

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
			
			INITIALIZE pr_purchtype.* TO NULL 
			SELECT * INTO pr_purchtype.* FROM purchtype 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND purchtype_code = pr_purchhead.purchtype_code 

						  {    CALL pack_address(pr_vendor.name_text,
						                        pr_vendor.addr1_text,
						                        pr_vendor.addr2_text,
						                        pr_vendor.city_text,
						                        pr_vendor.state_code,
						                        pr_vendor.post_code,
						                        pr_vendor.country_code)--@db-patch_2020_10_04--
						         returning pa_vendor_addr[1],
						                   pa_vendor_addr[2],
						                   pa_vendor_addr[3],
						                   pa_vendor_addr[4],
						                   pa_vendor_addr[5]                 }
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

			IF pr_purchhead.salesperson_text IS NOT NULL THEN 
				LET pv_cont_text = pr_purchhead.salesperson_text 
			ELSE 
				LET pv_cont_text = pr_vendor.contact_text 
			END IF 
			PRINT standoutoff clipped 
			SKIP 9 LINES 
			PRINT COLUMN 21, "To", 
			COLUMN 25, pv_cont_text clipped, 
			COLUMN 65," A/c: ", pr_vendor.our_acct_code clipped 
			SKIP 1 line 
			PRINT COLUMN 16, "Company", COLUMN 25, pr_vendor.name_text 
			SKIP 1 line 
			PRINT COLUMN 19, "FROM", 
			COLUMN 25, pr_rec_kandoouser.name_text clipped, 
			COLUMN 65, standoutsml clipped, "Delivery instructions", 
			standoutoff clipped 
			PRINT COLUMN 65, standoutsml clipped, "below - Include the", 
			standoutoff clipped 
			PRINT COLUMN 17, "E-mail", 
			COLUMN 25, pr_rec_kandoouser.email clipped, 
			COLUMN 65, standoutsml clipped, "contact person as stated", 
			standoutoff clipped 
			PRINT COLUMN 65, standoutsml clipped, "in the delivery instructions", 
			standoutoff clipped 
			PRINT COLUMN 19, "Date", 
			COLUMN 25, pr_purchhead.order_date USING "ddd, dd mmm yyyy" 
			SKIP 1 line 
			PRINT COLUMN 10, "Number Called", COLUMN 25, pr_vendor.fax_text; 



			PRINT COLUMN 50, standouton clipped, 
			" Order Number: ", 
			pr_purchhead.order_num USING "<<<<<<", 
			standoutoff clipped 



			PRINT COLUMN 5, "_____________________________________________________________________________________" 
			PRINT 
			PRINT COLUMN 5, "Qty", 
			COLUMN 10, "Product ID", 
			COLUMN 27, "Product Description", 
			COLUMN 68,"Unit Price"; 
			PRINT COLUMN 79,"Total Price" 
			PRINT COLUMN 5, "_____________________________________________________________________________________" 
			SKIP 1 line 

		PAGE HEADER 
			SKIP 10 LINES 
			PRINT COLUMN 50, standouton clipped, 
			" Order Number: ", 
			pr_purchhead.order_num USING "<<<<<<", 
			standoutoff clipped 
			PRINT COLUMN 5, "_____________________________________________________________________________________" 
			PRINT 
			PRINT COLUMN 5, "Qty", 
			COLUMN 10, "Product ID", 
			COLUMN 27, "Product Description", 
			COLUMN 68,"Unit Price"; 
			PRINT COLUMN 79,"Total Price" 
			PRINT COLUMN 5, "_____________________________________________________________________________________" 
			SKIP 1 line 
			LET pr_line_num = 0 

		BEFORE GROUP OF pr_purchdetl.order_num 

			SELECT count(*) INTO pr_detl_count FROM purchdetl 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND order_num = pr_purchdetl.order_num 
			LET pr_detl2_count = 0 
			LET pr_purchase_total = 0 
		ON EVERY ROW 
			#      need 12 lines
			LET rpt_wid = 100 
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

			IF pr_purchdetl.type_ind = "J" 
			OR pr_purchdetl.type_ind = "G" THEN 
				PRINT COLUMN 5, pr_poaudit.order_qty USING "<<<<<<", 
				COLUMN 10, pr_purchdetl.oem_text clipped; 
			ELSE 
				PRINT COLUMN 5, pr_poaudit.order_qty USING "<<<<<<", 
				COLUMN 10, pr_purchdetl.ref_text clipped; 
			END IF 
			PRINT COLUMN 27, pr_purchdetl.desc_text ; 
			PRINT COLUMN 68, pr_poaudit.unit_cost_amt USING "---,--&.&&" clipped, 
			COLUMN 77, pr_poaudit.line_total_amt USING "---,--&.&&" 
			IF pr_purchdetl.desc2_text IS NOT NULL THEN 
				PRINT COLUMN 27, pr_purchdetl.desc2_text 
			END IF 

			IF pr_purchdetl.type_ind = "J" 
			OR pr_purchdetl.type_ind = "C" 
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
					PRINT COLUMN 25, pr_note_text 
					LET pr_note2_count = pr_note2_count + 1 
					LET pr_line_num = pr_line_num + 1 








				END FOREACH 
			END IF 

			PAGE TRAILER 

				PRINT COLUMN 60, "Signed:___________________" 
				PRINT COLUMN 5, "__________________________________________________________________________________" 

				PRINT standoutsml clipped 
				PRINT COLUMN 5, "Note: Please be sure TO add the contact person AND notes stated in the delivery address on your" 
				PRINT COLUMN 5, "delievery details. Our ORDER number must be still be quoted as the official ORDER number" 
				PRINT standoutoff clipped 


				PRINT COLUMN 5, upshift(pr_purchtype.footer1_text) 
				PRINT COLUMN 5, upshift(pr_purchtype.footer2_text) 
				PRINT COLUMN 5, upshift(pr_purchtype.footer3_text); 
				PRINT standouton clipped 

				PRINT COLUMN 5, "DELIVERY TO", standoutoff clipped 
				PRINT standoutmid clipped 
				PRINT COLUMN 50, pa_purchase_addr[1] clipped 
				PRINT COLUMN 50, pa_purchase_addr[2] clipped 
				PRINT COLUMN 50, pa_purchase_addr[3] clipped 
				PRINT COLUMN 50, pa_purchase_addr[4] clipped 
				PRINT COLUMN 50, pa_purchase_addr[5] 
				PRINT COLUMN 50, pr_purchhead.tele_text clipped 
				PRINT COLUMN 38, "Attention: ", 
				COLUMN 50, pr_purchhead.contact_text, standoutoff clipped 
				PRINT standoutoff clipped 

			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN
				PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	
			

END REPORT