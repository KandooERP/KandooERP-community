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
# Description: Modified P34k TO create P34r Remittance section AT the top
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl" 
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_P3_GLOBALS.4gl" 
GLOBALS "../ap/P34_GLOBALS.4gl"

############################################################
# REPORT P34A_rpt_list(p_rpt_idx,p_rec_tentpays,p_cheque_date,p_source_ind,p_source_text,p_doc_id)
#
#
############################################################
REPORT P34A_rpt_list(p_rpt_idx,p_rec_tentpays,p_cheque_date,p_source_ind,p_source_text,p_doc_id) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_tentpays RECORD LIKE tentpays.* 
	DEFINE p_cheque_date DATE 
	DEFINE p_source_ind LIKE voucher.source_ind 
	DEFINE p_source_text LIKE voucher.source_text 
	DEFINE p_doc_id INTEGER
	DEFINE l_page_num LIKE rmsreps.page_num
	DEFINE l_rec_voucher RECORD LIKE voucher.* 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_cheque_amt LIKE vendor.bal_amt 
	DEFINE l_cheque_total LIKE vendor.bal_amt 
	DEFINE l_voucher_total LIKE vendor.bal_amt 
	DEFINE l_tax_amt LIKE cheque.net_pay_amt 
	DEFINE l_arr_address ARRAY[5] OF CHAR(32) 
	DEFINE l_cheque_text CHAR(10) 
	DEFINE l_arr_words ARRAY[10] OF CHAR(5) 
	DEFINE l_millions CHAR(5) 
	DEFINE l_hundthous CHAR(5) 
	DEFINE l_tensthous CHAR(5) 
	DEFINE l_thous, l_hund, l_tens, l_xunits CHAR(5) 
	DEFINE l_cents CHAR(2) 
	DEFINE l_page_number SMALLINT 
	DEFINE l_printchq_ind SMALLINT 
	DEFINE c1, c2, c3, c4, c5, c6, c7, c8 INTEGER 
	DEFINE cnt SMALLINT 

	ORDER BY p_doc_id 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,PAGENO) #update page number and report header line 1
			LET l_arr_words[1] = " ZERO" 
			LET l_arr_words[2] = " ONE" 
			LET l_arr_words[3] = " TWO" 
			LET l_arr_words[4] = "THREE" 
			LET l_arr_words[5] = " FOUR" 
			LET l_arr_words[6] = " FIVE" 
			LET l_arr_words[7] = " SIX" 
			LET l_arr_words[8] = "SEVEN" 
			LET l_arr_words[9] = "EIGHT" 
			LET l_arr_words[10] = " NINE" 
			IF p_source_ind = "8" THEN 
				SELECT * INTO l_rec_customer.* FROM customer 
				WHERE cust_code = p_source_text 
				AND cmpy_code = p_rec_tentpays.cmpy_code 
				LET l_rec_vendor.vend_code = l_rec_customer.cust_code 
				LET l_rec_vendor.name_text = l_rec_customer.name_text 
				LET l_rec_vendor.addr1_text = l_rec_customer.addr1_text 
				LET l_rec_vendor.addr2_text = l_rec_customer.addr2_text 
				LET l_rec_vendor.addr3_text = NULL 
				LET l_rec_vendor.city_text = l_rec_customer.city_text 
				LET l_rec_vendor.state_code = l_rec_customer.state_code 
				LET l_rec_vendor.post_code = l_rec_customer.post_code 
				LET l_rec_vendor.country_code = l_rec_customer.country_code --@db-patch_2020_10_04--
			ELSE 
				SELECT * INTO l_rec_vendor.* FROM vendor 
				WHERE cmpy_code = p_rec_tentpays.cmpy_code 
				AND vend_code = p_rec_tentpays.vend_code 
			END IF 
			LET l_arr_address[1] = l_rec_vendor.name_text CLIPPED 
			LET l_arr_address[2] = l_rec_vendor.addr1_text CLIPPED 
			LET l_arr_address[3] = l_rec_vendor.addr2_text CLIPPED 
			LET l_arr_address[4] = l_rec_vendor.addr3_text CLIPPED 
			LET l_arr_address[5] = l_rec_vendor.city_text CLIPPED," ", 
			l_rec_vendor.state_code CLIPPED," ", 
			l_rec_vendor.post_code CLIPPED 
			FOR cnt = 1 TO 4 
				IF length(l_arr_address[cnt]) = 0 THEN 
					LET l_arr_address[cnt] = l_arr_address[cnt+1] 
					LET l_arr_address[cnt+1] = NULL 
				END IF 
			END FOR 
			LET l_printchq_ind = FALSE 
			###-First time through page number IS 0-###
			IF l_page_number = 0 THEN 
				LET l_page_number = 1 
			END IF 
			PRINT 
			COLUMN 005, l_rec_vendor.vend_code CLIPPED, 
			COLUMN 015, l_arr_address[1], ###-name text-### 
			COLUMN 047, TODAY         USING "dd/mm/yy", 
			COLUMN 059, l_page_number USING "##&" 
			SKIP 6 LINES 

		BEFORE GROUP OF p_doc_id 
			LET l_voucher_total = 0 
			LET l_rec_cheque_amt = 0 
			LET l_page_number = 1 
			SKIP TO top OF PAGE 

		ON EVERY ROW 
			SELECT * INTO l_rec_voucher.* 
			FROM voucher 
			WHERE cmpy_code = p_rec_tentpays.cmpy_code 
			AND vouch_code = p_rec_tentpays.vouch_code 
			AND vend_code = p_rec_tentpays.vend_code 
			NEED 2 LINES 
			IF p_rec_tentpays.withhold_tax_ind != "0" THEN 
				LET l_tax_amt = 0 
				CALL wtaxcalc(p_rec_tentpays.vouch_amt, 
				p_rec_tentpays.tax_per, 
				p_rec_tentpays.withhold_tax_ind, 
				p_rec_tentpays.cmpy_code) 
				RETURNING l_voucher_total, 
				l_tax_amt 
			ELSE 
				LET l_voucher_total = p_rec_tentpays.vouch_amt 
				LET l_tax_amt = 0 
			END IF 
			LET l_rec_cheque_amt = l_rec_cheque_amt+ l_voucher_total 
			PRINT 
			COLUMN 007, l_rec_voucher.vouch_date USING "dd/mm/yy", 
			COLUMN 020, l_rec_voucher.inv_text[1,15], 
			COLUMN 035, l_voucher_total          USING "--,---,--&.&&", 
			COLUMN 050, l_rec_voucher.vouch_code USING "<<<<<<<<<<<<" 

		AFTER GROUP OF p_doc_id 
			LET l_printchq_ind = TRUE 
			LET l_cheque_total = l_rec_cheque_amt 
			LET l_page_num = pageno 
			UPDATE t_docid 
			SET page_no = l_page_num
			WHERE doc_id = p_doc_id 

			PAGE TRAILER 
				SKIP 1 LINE 
				IF l_printchq_ind THEN 
					###-Print the totals-###
					PRINT COLUMN 035, l_cheque_total USING "--,---,--&.&&", 
					COLUMN 050, "" 
					SKIP 8 LINES 
					###-Print the cheque portion-###
					###-Line 50-###
					PRINT COLUMN 013, l_cheque_total USING "--,---,--&.&&" 
					SKIP 2 LINE 
					###-Logic FOR producing the l_arr_words on cheque-###
					LET l_cheque_text = l_cheque_total USING "&&&&&&&.&&" 
					LET c1 = l_cheque_text[1] 
					LET c2 = l_cheque_text[2] 
					LET c3 = l_cheque_text[3] 
					LET c4 = l_cheque_text[4] 
					LET c5 = l_cheque_text[5] 
					LET c6 = l_cheque_text[6] 
					LET c7 = l_cheque_text[7] 
					LET c8 = l_cheque_text[9,10] 
					LET l_millions = l_arr_words[c1+1] 
					LET l_hundthous = l_arr_words[c2+1] 
					LET l_tensthous = l_arr_words[c3+1] 
					LET l_thous = l_arr_words[c4+1] 
					LET l_hund = l_arr_words[c5+1] 
					LET l_tens = l_arr_words[c6+1] 
					LET l_xunits = l_arr_words[c7+1] 
					LET l_cents = c8 
					PRINT 
					COLUMN 002, l_millions CLIPPED, 
					COLUMN 009, l_hundthous CLIPPED, 
					COLUMN 016, l_tensthous CLIPPED, 
					COLUMN 023, l_thous CLIPPED, 
					COLUMN 030, l_hund CLIPPED, 
					COLUMN 037, l_tens CLIPPED, 
					COLUMN 044, l_xunits CLIPPED, 
					COLUMN 050, l_cents        USING "&&", 
					COLUMN 060, TODAY          USING "dd/mm/yy", 
					COLUMN 069, l_cheque_total USING "***,**&.&&" 
					SKIP 2 LINES 
					###-Line 57-###
					PRINT COLUMN 012, l_arr_address[1] 
					PRINT COLUMN 012, l_arr_address[2] 
					PRINT COLUMN 012, l_arr_address[3] 
					PRINT COLUMN 012, l_arr_address[4] 
					PRINT COLUMN 012, l_arr_address[5] 
				ELSE 
					LET l_page_number = l_page_number + 1 
					###-Print the totals-###
					PRINT COLUMN 035, l_rec_cheque_amt USING "-,---,--&.&&", 
					COLUMN 050, "<Continued Over Page>" 
					SKIP 8 LINES 
					###-Line 50-###
					PRINT COLUMN 013, "*****VOID*****" 
					SKIP 2 LINE 
					###-Need TO PRINT VOID through the Cheque portion -###
					PRINT COLUMN 002, "VOID", 
					COLUMN 009, "VOID", 
					COLUMN 016, "VOID", 
					COLUMN 023, "VOID", 
					COLUMN 030, "VOID", 
					COLUMN 037, "VOID", 
					COLUMN 044, "VOID", 
					COLUMN 050, "**", 
					COLUMN 060, "***VOID***", 
					COLUMN 070, "***VOID***" 
					SKIP 2 LINES 
					###-Line 57-###
					PRINT COLUMN 012, "VOID" 
					PRINT COLUMN 012, "VOID" 
					PRINT COLUMN 012, "VOID" 
					PRINT COLUMN 012, "VOID" 
					PRINT COLUMN 012, "VOID" 
				END IF 

END REPORT 
