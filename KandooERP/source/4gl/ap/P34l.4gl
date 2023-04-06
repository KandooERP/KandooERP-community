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
# \brief module P34l Cheque Print Remittance section AT the top
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
	DEFINE l_invoice_total LIKE vendor.bal_amt 
	DEFINE l_voucher_total LIKE vendor.bal_amt
	DEFINE l_disc_total LIKE vendor.bal_amt
	DEFINE l_tax_amt LIKE cheque.net_pay_amt 
	DEFINE l_printchq_ind SMALLINT 
	DEFINE l_line_cnt SMALLINT
	DEFINE l_kandoo_line_cnt SMALLINT
	DEFINE l_vend_ad1, l_vend_ad2, l_vend_ad3, l_vend_ad4, l_vend_ad5 CHAR(40) 
	DEFINE l_cheque_amt DECIMAL(10,2) 
	DEFINE l_cheque_text CHAR(9) 
	DEFINE l_cents CHAR(2) 
	DEFINE l_arr_words ARRAY[10] OF CHAR(5) 
	DEFINE l_hundthous, l_tensthous, l_thous, l_hund, l_tens, l_xunits CHAR(5) 
   DEFINE cnt SMALLINT
	DEFINE c1, c2, c3, c4, c5, c6, c7, c9_10 INTEGER

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
			LET l_kandoo_line_cnt = 22 
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
				SELECT * INTO l_rec_vendor.* 
				FROM vendor 
				WHERE cmpy_code = p_rec_tentpays.cmpy_code 
				AND vend_code = p_rec_tentpays.vend_code 
			END IF 
			LET l_vend_ad1 = l_rec_vendor.name_text CLIPPED 
			LET l_vend_ad2 = l_rec_vendor.addr1_text CLIPPED 
			LET l_vend_ad3 = l_rec_vendor.addr2_text CLIPPED 
			LET l_vend_ad4 = l_rec_vendor.addr3_text CLIPPED 
			LET l_vend_ad5 = l_rec_vendor.city_text 
			IF l_vend_ad5 IS NULL THEN 
				LET l_vend_ad5 = l_rec_vendor.state_code 
			ELSE 
				LET l_vend_ad5 = l_vend_ad5 CLIPPED, ", ",l_rec_vendor.state_code CLIPPED 
			END IF 
			IF l_vend_ad5 IS NULL THEN 
				LET l_vend_ad5 = l_rec_vendor.post_code 
			ELSE 
				LET l_vend_ad5 = l_vend_ad5 CLIPPED, ", ", l_rec_vendor.post_code CLIPPED 
			END IF 
			IF l_vend_ad2 IS NULL THEN 
				LET l_vend_ad2 = l_vend_ad3 
				INITIALIZE l_vend_ad3 TO NULL 
			END IF 
			IF l_vend_ad3 IS NULL THEN 
				LET l_vend_ad3 = l_vend_ad4 
				INITIALIZE l_vend_ad4 TO NULL 
			END IF 
			IF l_vend_ad4 IS NULL THEN 
				LET l_vend_ad4 = l_vend_ad5 
				INITIALIZE l_vend_ad5 TO NULL 
			END IF 
			LET l_printchq_ind = false 
			PRINT COLUMN 08, l_vend_ad1 
			PRINT COLUMN 08, l_vend_ad2 
			PRINT COLUMN 08, l_vend_ad3 
			PRINT COLUMN 08, l_vend_ad4 
			PRINT COLUMN 08, l_vend_ad5 
			SKIP 3 LINES 

		BEFORE GROUP OF p_doc_id 
			SKIP TO top OF PAGE 
			LET l_invoice_total = 0 
			LET l_voucher_total = 0 
			LET l_disc_total = 0 
			LET l_line_cnt = 0 

		ON EVERY ROW 
			#
			# The last line in the body of the statement IS reserved FOR
			# carried forward balance AND tax amount PRINT lines
			IF l_line_cnt = (l_kandoo_line_cnt - 1) THEN 
				PRINT COLUMN 25, "BALANCE C/F", 
				COLUMN 63, l_invoice_total USING "----,---,--&.&&" 
				SKIP 3 LINES 
				PRINT COLUMN 25, "BALANCE B/F", 
				COLUMN 63, l_invoice_total USING "----,---,--&.&&" 
				LET l_line_cnt = 1 
			END IF 
			SELECT * INTO l_rec_voucher.* 
			FROM voucher 
			WHERE cmpy_code = p_rec_tentpays.cmpy_code 
			AND vouch_code = p_rec_tentpays.vouch_code 
			AND vend_code = p_rec_tentpays.vend_code 
			LET l_line_cnt = l_line_cnt + 1 
			PRINT 
			COLUMN 03, l_rec_voucher.vouch_date USING "dd/mm/yy", 
			COLUMN 14, l_rec_voucher.inv_text, 
			COLUMN 37, l_rec_voucher.vouch_code USING "#########", 
			COLUMN 47, l_rec_voucher.paid_amt   USING "---,--&.&&", 
			COLUMN 63, p_rec_tentpays.vouch_amt USING "----,---,--&.&&" 
			LET l_invoice_total = l_invoice_total + p_rec_tentpays.vouch_amt 
			LET l_voucher_total = l_voucher_total 
			+ l_rec_voucher.total_amt 
			- l_rec_voucher.paid_amt 
			- l_rec_voucher.taken_disc_amt 
			LET l_disc_total = l_disc_total + p_rec_tentpays.taken_disc_amt 

		AFTER GROUP OF p_doc_id 
			LET l_printchq_ind = true 
			LET l_cheque_amt = l_invoice_total 
			IF p_rec_tentpays.withhold_tax_ind != "0" THEN 
				LET l_tax_amt = 0 
				CALL wtaxcalc(l_invoice_total,p_rec_tentpays.tax_per, 
				p_rec_tentpays.withhold_tax_ind, 
				p_rec_tentpays.cmpy_code) 
				RETURNING l_cheque_amt, 
				l_tax_amt 
				# There will always be one line left FOR the tax total as
				# the voucher details will always move TO a new page one
				# line before the max possible
				PRINT COLUMN 27, "LESS TAX:", 
				COLUMN 63, (0 - l_tax_amt) USING "----,---,--&.&&" 
				LET l_line_cnt = l_line_cnt + 1 
			END IF 
			FOR cnt = 1 TO (l_kandoo_line_cnt - l_line_cnt + 2) 
				SKIP 1 LINE 
			END FOR 
			LET l_page_num = pageno 
			UPDATE t_docid 
			SET page_no = l_page_num
			WHERE doc_id = p_doc_id 

			PAGE TRAILER 
				IF l_printchq_ind THEN 
					PRINT 
					COLUMN 13, l_rec_vendor.vend_code CLIPPED, 
					COLUMN 35, l_voucher_total USING "---,--&.&&", 
					COLUMN 47, l_disc_total    USING "----,---,--&.&&", 
					COLUMN 63, l_cheque_amt    USING "----,---,--&.&&" 
					SKIP 10 LINES 
					PRINT 
					COLUMN 16, p_cheque_date   USING "dd/mm/yy", 
					COLUMN 26, l_rec_vendor.name_text 
					SKIP 2 LINES 
					LET l_cheque_text = l_cheque_amt USING "&&&&&&.&&" 
					LET c1 = l_cheque_text[1] 
					LET c2 = l_cheque_text[2] 
					LET c3 = l_cheque_text[3] 
					LET c4 = l_cheque_text[4] 
					LET c5 = l_cheque_text[5] 
					LET c6 = l_cheque_text[6] 
					LET c7 = l_cheque_text[8,9] 
					LET l_hundthous = l_arr_words[c1+1] 
					LET l_tensthous = l_arr_words[c2+1] 
					LET l_thous = l_arr_words[c3+1] 
					LET l_hund = l_arr_words[c4+1] 
					LET l_tens = l_arr_words[c5+1] 
					LET l_xunits = l_arr_words[c6+1] 
					LET l_cents = c7 
					PRINT 
					COLUMN 16, l_hundthous CLIPPED, 
					COLUMN 22, l_tensthous CLIPPED, 
					COLUMN 29, l_thous CLIPPED, 
					COLUMN 36, l_hund CLIPPED, 
					COLUMN 43, l_tens CLIPPED, 
					COLUMN 49, l_xunits CLIPPED, 
					COLUMN 57, l_cents      USING "&&", 
					COLUMN 61, l_cheque_amt USING "******&.&&" 
					SKIP 4 LINES 
				ELSE 
					PRINT COLUMN 13, "**VOID**", 
					COLUMN 35, "***VOID***", 
					COLUMN 48, "*****VOID*****", 
					COLUMN 64, "*****VOID*****" 
					SKIP 10 LINES 
					PRINT COLUMN 16, "***VOID***", 
					COLUMN 26, "***********************************" 
					SKIP 2 LINES 
					PRINT COLUMN 18, "VOID", # 100,000's COLUMN 
					COLUMN 24, "VOID", # 10,000's COLUMN 
					COLUMN 31, "VOID", # 1,000's COLUMN 
					COLUMN 38, "VOID", # 100's COLUMN 
					COLUMN 45, "VOID", # 10's COLUMN 
					COLUMN 50, "VOID", # units COLUMN 
					COLUMN 57, "**", # l_cents COLUMN 
					COLUMN 61, "**********" # amount in numbers 
					SKIP 3 LINES 
					PRINT 
					COLUMN 16, "XXXXXXXXXXXXXXXXXXXXX", 
					COLUMN 57, "XXXXXXXXXXXXXXXXXXXXX" 
				END IF 

END REPORT 
