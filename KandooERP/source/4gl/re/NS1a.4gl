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
GLOBALS "../re/N_RE_GLOBALS.4gl"
GLOBALS "../re/NS_GROUP_GLOBALS.4gl"
GLOBALS "../re/NS1_GLOBALS.4gl" 
#           FUNCTION po_print prints purchase orders (80 col FORMAT)

--rpt_note LIKE rmsreps.report_text, 
--rpt_width LIKE rmsreps.report_width_num, 
--rpt_length LIKE rmsreps.page_length_num, 
--rpt_pageno LIKE rmsreps.page_num 

FUNCTION print_po(p_cmpy, p_kandoouser_sign_on_code, where_text) 
	DEFINE l_rpt_idx SMALLINT  #report array index
	DEFINE 
	p_cmpy LIKE company.cmpy_code, 
	p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code, 
	where_text CHAR(500), 
	pr_purchdetl RECORD LIKE purchdetl.*, 
--	pr_output CHAR(25), 
	query_text CHAR(1000) 

	SELECT company.* 
	INTO glob_rec_company.* 
	FROM company 
	WHERE cmpy_code = p_cmpy 
	IF status = notfound THEN 
		error" Company NOT found" 
		EXIT program 
	END IF 
	
	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF
	LET l_rpt_idx = rpt_start(getmoduleid(),"NS1_rpt_list_po_orderer",where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT NS1_rpt_list_po_orderer TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------
	
	LET query_text = 
	"SELECT purchdetl.* ", 
	"FROM purchdetl,", 
	"purchhead ", 
	" WHERE purchhead.cmpy_code = \"",p_cmpy,"\" ", 
	"AND purchhead.cmpy_code = purchdetl.cmpy_code ", 
	"AND purchhead.order_num = purchdetl.order_num ", 
	"AND ",where_text clipped," ", 
	"ORDER BY purchdetl.order_num,", 
	"purchdetl.line_num" 
	PREPARE s_purchdetl FROM query_text 
	DECLARE c_purchdetl CURSOR FOR s_purchdetl 
	{
	   OPEN WINDOW w1_NS1 AT 15,11 with 1 rows,50 columns     -- albo  KD-763
	      ATTRIBUTE(border,yellow)
	}
	DISPLAY " Printing Purchase Order: " at 1,1 

	FOREACH c_purchdetl INTO pr_purchdetl.* 

		SLEEP 2
		#---------------------------------------------------------
		OUTPUT TO REPORT NS1_rpt_list_po_orderer(l_rpt_idx,				 
		pr_purchdetl.*) 
		IF NOT rpt_int_flag_handler2("PO:",pr_purchdetl.order_num, NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 		
		#---------------------------------------------------------

	END FOREACH
	
	#------------------------------------------------------------
	FINISH REPORT NS1_rpt_list_po_orderer
	CALL rpt_finish("NS1_rpt_list_po_orderer")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 

END FUNCTION 


REPORT NS1_rpt_list_po_orderer(p_rpt_idx,pr_purchdetl) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE 
	pr_purchdetl RECORD LIKE purchdetl.*, 
	pr_vendor RECORD LIKE vendor.*, 
	pr_purchhead RECORD LIKE purchhead.*, 
	pr_poaudit RECORD LIKE poaudit.*, 
	pr_term RECORD LIKE term.*, 
	note_mark1, note_mark2 CHAR(3), 
	temp_text CHAR(10), 
	note_info CHAR(70), 
	pagcount INTEGER, 
	order_tot, tax_tot, received_tot, voucher_tot money(12,2), 
	cnt,lncounter SMALLINT 

	OUTPUT 
		bottom margin 0 
	
	ORDER external BY pr_purchdetl.order_num, pr_purchdetl.line_num 
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1

			SKIP 1 line 
			PRINT COLUMN 7,glob_rec_company.name_text clipped 
			PRINT COLUMN 7,glob_rec_company.addr1_text 
			IF glob_rec_company.addr2_text IS NOT NULL THEN 
				PRINT COLUMN 7, glob_rec_company.addr2_text 
				PRINT COLUMN 7, glob_rec_company.city_text clipped,", ", 
				glob_rec_company.state_code," ", 
				glob_rec_company.post_code clipped 
				PRINT COLUMN 7, glob_rec_company.tele_text 
			ELSE 
				PRINT COLUMN 7, glob_rec_company.city_text clipped, ", ", 
				glob_rec_company.state_code," ",glob_rec_company.post_code clipped 
				PRINT COLUMN 7, glob_rec_company.tele_text 
				SKIP 1 line 
			END IF 
			
			SKIP 1 line 
			SELECT * 
			INTO pr_vendor.* 
			FROM vendor 
			WHERE cmpy_code = pr_purchdetl.cmpy_code 
			AND vend_code = pr_purchdetl.vend_code
			 
			SELECT * 
			INTO pr_purchhead.* 
			FROM purchhead 
			WHERE cmpy_code = pr_purchdetl.cmpy_code 
			AND order_num = pr_purchdetl.order_num 
			
			PRINT COLUMN 26, pr_purchdetl.order_num USING "#######", 
			COLUMN 48, pr_purchhead.order_date USING "ddd dd mmm yy" 
			SKIP 4 LINES 
			
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
			
			SELECT term.desc_text 
			INTO pr_term.desc_text 
			FROM term 
			WHERE cmpy_code = pr_purchdetl.cmpy_code 
			AND term_code = pr_purchhead.term_code 
			SKIP 3 LINES 
			PRINT COLUMN 60, "Page: ",pagcount USING "###" 
			SKIP 6 LINES 
			
		BEFORE GROUP OF pr_purchdetl.order_num 
			SKIP TO top OF PAGE 
			
		ON EVERY ROW 
			CALL po_line_info(pr_purchdetl.cmpy_code, 
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
			LET note_mark1 = pr_purchdetl.desc_text[1,3] 
			LET note_mark2 = pr_purchdetl.desc_text[14,17] 
			IF pr_poaudit.order_qty IS NULL OR pr_poaudit.order_qty = 0 THEN 
				PRINT COLUMN 17, pr_purchdetl.desc_text 
			ELSE 
				PRINT COLUMN 5, pr_poaudit.order_qty USING "########.&", 
				COLUMN 17, pr_purchdetl.desc_text[1,28], 
				COLUMN 45, pr_poaudit.unit_cost_amt USING "-,---,--$.&&", 
				COLUMN 61, pr_poaudit.ext_cost_amt USING "-,---,--$.&&" 
			END IF 
			IF note_mark1 = "###" AND note_mark2 = "###" THEN 
				LET temp_text = pr_purchdetl.desc_text[4,14] 
				DECLARE no_curs CURSOR FOR 
				SELECT note_text, 
				note_num 
				INTO note_info, 
				cnt 
				FROM notes 
				WHERE cmpy_code = pr_purchdetl.cmpy_code 
				AND note_code = temp_text 
				ORDER BY note_num 
				FOREACH no_curs 
					PRINT COLUMN 22, note_info 
				END FOREACH 
			END IF 
			
		AFTER GROUP OF pr_purchdetl.order_num 
			LET lncounter = 0 
			LET pagcount = 0 
			UPDATE purchhead SET printed_flag = "Y" 
			WHERE cmpy_code = pr_purchdetl.cmpy_code 
			AND order_num = pr_purchhead.order_num 
			PAGE TRAILER 
				CALL po_head_info(pr_purchdetl.cmpy_code, 
				pr_purchhead.order_num) 
				RETURNING order_tot, 
				received_tot, 
				voucher_tot, 
				tax_tot 
				SKIP 3 LINES 
				PRINT COLUMN 61, tax_tot USING "-,---,--$.&&" 
				SKIP 3 LINES 
				PRINT COLUMN 25, pr_term.desc_text, 
				COLUMN 61, order_tot USING "-,---,--$.&&" 
				SKIP 2 LINES 
				
		ON LAST ROW 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4]
 				
END REPORT 
