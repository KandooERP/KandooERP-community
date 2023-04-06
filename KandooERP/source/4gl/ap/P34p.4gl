{
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
}
# \brief module P34p Cheque Print Cloned FROM P34_C.4gl ( Curriculum Cheque Print )
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_P3_GLOBALS.4gl" 
GLOBALS "../ap/P34_GLOBALS.4gl"

############################################################
# FUNCTION convnum(p_n)
#
#
############################################################
FUNCTION convnum(p_n) 
	DEFINE p_n CHAR(10)
	DEFINE l_arr_small_num ARRAY[9] OF CHAR(6) 
	DEFINE l_arr_st_text ARRAY[7] OF CHAR(6) 
	DEFINE j, i INTEGER
	DEFINE r_chq_line CHAR(42)
	
	LET l_arr_small_num[1] =" ONE " 
	LET l_arr_small_num[2] =" TWO " 
	LET l_arr_small_num[3] ="THREE " 
	LET l_arr_small_num[4] =" FOUR " 
	LET l_arr_small_num[5] =" FIVE " 
	LET l_arr_small_num[6] =" SIX " 
	LET l_arr_small_num[7] ="SEVEN " 
	LET l_arr_small_num[8] ="EIGHT " 
	LET l_arr_small_num[9] =" NINE " 
	FOR i = 1 TO 7 
		IF p_n[i] = " " 
		OR p_n[i] = "0" THEN 
			LET l_arr_st_text[i] = " ZERO " 
		ELSE 
			LET j = p_n[i] 
			LET l_arr_st_text[i] = l_arr_small_num[j] 
		END IF 
	END FOR 
	LET r_chq_line = l_arr_st_text[1], l_arr_st_text[2], l_arr_st_text[3], l_arr_st_text[4], 
	l_arr_st_text[5], l_arr_st_text[6], l_arr_st_text[7] 
	RETURN r_chq_line 
END FUNCTION 

############################################################
# REPORT P34A_rpt_list(p_rpt_idx,p_rec_tentpays,p_chq_prt_date,p_source_ind,p_source_text,p_doc_id)
#
#
############################################################
REPORT P34A_rpt_list(p_rpt_idx,p_rec_tentpays,p_chq_prt_date,p_source_ind,p_source_text,p_doc_id) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_tentpays RECORD LIKE tentpays.* 
	DEFINE p_chq_prt_date DATE 
	DEFINE p_source_ind LIKE voucher.source_ind 
	DEFINE p_source_text LIKE voucher.source_text 
	DEFINE p_doc_id INTEGER
 	DEFINE l_rec_voucher RECORD LIKE voucher.* 
	DEFINE l_rec_vendor RECORD LIKE vendor.*
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_arr_addr ARRAY[6] OF RECORD 
		l_line CHAR(30) 
	END RECORD
	DEFINE l_skip_lines SMALLINT
	DEFINE l_line_count SMALLINT
	DEFINE l_chq_amt DECIMAL(10,2)
	DEFINE l_amt_text CHAR(10)
	DEFINE l_cheque_line CHAR(42) 
	DEFINE i, j, cnt SMALLINT
	DEFINE l_pageno SMALLINT  #report page number

	ORDER BY p_doc_id 

	FORMAT 
		FIRST PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,PAGENO) #update page number and report header line 1

		BEFORE GROUP OF p_doc_id 
			IF p_source_ind = "8" THEN 
				#refund customer instead of vendor
				SELECT * INTO l_rec_customer.* FROM customer 
				WHERE cmpy_code = p_rec_tentpays.cmpy_code 
				AND cust_code = p_source_text 
				IF STATUS = NOTFOUND THEN 
					LET l_arr_addr[1].l_line = p_source_text 
					LET l_arr_addr[2].l_line = "*Customer code does NOT exist*" 
					LET l_arr_addr[3].l_line = NULL 
					LET l_arr_addr[4].l_line = NULL 
					LET l_arr_addr[5].l_line = NULL 
					LET l_arr_addr[6].l_line = NULL 
				ELSE 
					LET l_arr_addr[1].l_line = l_rec_customer.name_text 
					LET l_arr_addr[2].l_line = l_rec_customer.addr1_text 
					LET l_arr_addr[3].l_line = l_rec_customer.addr2_text 
					LET l_arr_addr[4].l_line = l_rec_customer.city_text CLIPPED, 
					" ", 
					l_rec_customer.state_code CLIPPED, 
					" ", 
					l_rec_customer.post_code CLIPPED 
					LET l_arr_addr[5].l_line = NULL 
					LET l_arr_addr[6].l_line = NULL 
				END IF 
			ELSE 
				SELECT * INTO l_rec_vendor.* FROM vendor 
				WHERE cmpy_code = p_rec_tentpays.cmpy_code 
				AND vend_code = p_rec_tentpays.vend_code 
				IF STATUS = NOTFOUND THEN 
					LET l_arr_addr[1].l_line = p_rec_tentpays.vend_code 
					LET l_arr_addr[2].l_line = "*Vendor code does NOT exist*" 
					LET l_arr_addr[3].l_line = NULL 
					LET l_arr_addr[4].l_line = NULL 
					LET l_arr_addr[5].l_line = NULL 
					LET l_arr_addr[6].l_line = NULL 
				ELSE 
					LET l_arr_addr[1].l_line = l_rec_vendor.name_text 
					LET l_arr_addr[2].l_line = l_rec_vendor.addr1_text 
					LET l_arr_addr[3].l_line = l_rec_vendor.addr2_text 
					LET l_arr_addr[4].l_line = l_rec_vendor.addr3_text 
					LET l_arr_addr[5].l_line = l_rec_vendor.city_text CLIPPED, 
					" ", 
					l_rec_vendor.state_code CLIPPED, 
					" ", 
					l_rec_vendor.post_code CLIPPED 
					LET l_arr_addr[6].l_line = NULL 
				END IF 
			END IF 
			FOR i = 1 TO 5 
				LET j = 1 
				WHILE (l_arr_addr[i].l_line IS NULL OR l_arr_addr[i].l_line = " ") 
					LET l_arr_addr[i].l_line = l_arr_addr[i+j].l_line 
					INITIALIZE l_arr_addr[i+j].l_line TO NULL 
					LET j = j+1 
					IF i + j > 6 THEN 
						EXIT WHILE 
					END IF 
				END WHILE 
				IF i + j > 5 THEN 
					EXIT FOR 
				END IF 
			END FOR
			LET l_pageno = 1
			SKIP 5 LINES 
			PRINT COLUMN 10, l_arr_addr[1].l_line 
			PRINT COLUMN 10, l_arr_addr[2].l_line 
			PRINT COLUMN 10, l_arr_addr[3].l_line 
			PRINT COLUMN 10, l_arr_addr[4].l_line, 
			COLUMN 64, p_rec_tentpays.vend_code 
			PRINT COLUMN 10, l_arr_addr[5].l_line, 
			COLUMN 64, TODAY USING "dd/mm/yy" 
			PRINT COLUMN 64, l_pageno USING "###" 
			SKIP 3 LINES 
			LET l_line_count = 14 

		ON EVERY ROW 
			LET l_line_count = l_line_count + 1 
			IF l_line_count = 41 THEN 
				LET l_line_count = 1 
				SKIP 1 LINES 
				PRINT COLUMN 62, "c/fwd" 
				SKIP 10 LINES 
				PRINT COLUMN 12, "VOID", 
				COLUMN 61, "VOID" 
				SKIP 3 LINES 
				PRINT COLUMN 12, "*********************************************** ", 
				"***********" 
				SKIP 9 LINES 
				LET l_pageno = l_pageno + 1
				SKIP 5 LINES 
				PRINT COLUMN 10, l_arr_addr[1].l_line 
				PRINT COLUMN 10, l_arr_addr[2].l_line 
				PRINT COLUMN 10, l_arr_addr[3].l_line 
				IF p_source_ind = "8" THEN 
					PRINT COLUMN 10, l_arr_addr[4].l_line, 
					COLUMN 64, p_rec_tentpays.vend_code 
				ELSE 
					PRINT COLUMN 10, l_arr_addr[4].l_line 
				END IF 
				PRINT COLUMN 10, l_arr_addr[5].l_line, 
				COLUMN 64, TODAY USING "dd/mm/yy" 
				PRINT COLUMN 64, l_pageno USING "###" 
				SKIP 3 LINES 
				LET l_line_count = 15 
			END IF 
			SELECT * INTO l_rec_voucher.* FROM voucher 
			WHERE cmpy_code = p_rec_tentpays.cmpy_code 
			AND vouch_code = p_rec_tentpays.vouch_code 
			AND vend_code = p_rec_tentpays.vend_code 

			IF p_source_ind = "8" THEN 
				PRINT 
				COLUMN 10, l_rec_voucher.vouch_date USING "dd mmm yy", 
				COLUMN 21, "Overpayment Refund ", 
				COLUMN 56, p_rec_tentpays.vouch_amt USING "--,---,---.&&" 
			ELSE 
				PRINT 
				COLUMN 10, l_rec_voucher.vouch_date USING "dd mmm yy", 
				COLUMN 21, "Invoice: ", 
				COLUMN 30, l_rec_voucher.inv_text, 
				COLUMN 56, p_rec_tentpays.vouch_amt USING "--,---,---.&&" 
			END IF 

		AFTER GROUP OF p_doc_id 
			LET l_skip_lines = 41 - (l_line_count) 
			FOR cnt = 1 TO l_skip_lines 
				SKIP 1 LINE 
			END FOR 
			PRINT COLUMN 56, GROUP SUM(p_rec_tentpays.vouch_amt) USING "$$$,$$$,$$$.&&" 
			SKIP 10 LINES 
			PRINT COLUMN 12, l_arr_addr[1].l_line, 
			COLUMN 61, TODAY USING "dd/mm/yy" 
			SKIP 3 LINES 
			LET l_chq_amt = GROUP SUM( p_rec_tentpays.vouch_amt) USING "########.##" 
			LET l_amt_text = l_chq_amt USING "#######.##" 
			CALL convnum(l_amt_text) RETURNING l_cheque_line 
			PRINT COLUMN 11, l_cheque_line, 
			COLUMN 55, l_amt_text[9,10], 
			COLUMN 57, GROUP SUM (p_rec_tentpays.vouch_amt)      USING "$$$,$$$,$$$.&&" 
			LET l_pageno= pageno #l_ps_pageno = pageno 
			UPDATE t_docid 
			SET page_no = l_pageno 
			WHERE doc_id = p_doc_id 
			SKIP 9 LINES 

END REPORT 
