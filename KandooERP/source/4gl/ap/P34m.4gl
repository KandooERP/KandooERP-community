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
# \brief module P34m Cheque Print Cloned FROM P34l.4gl
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
	DEFINE l_cheque_amt LIKE vendor.bal_amt 
	DEFINE l_cheque_total LIKE vendor.bal_amt 
	DEFINE l_invoice_total LIKE vendor.bal_amt 
	DEFINE l_voucher_total LIKE vendor.bal_amt 
	DEFINE l_voucher2_total LIKE vendor.bal_amt 
	DEFINE l_prev_total LIKE vendor.bal_amt 
	DEFINE l_disc_total LIKE vendor.bal_amt 
	DEFINE l_tax_amt LIKE cheque.net_pay_amt 
	DEFINE l_tax2_total LIKE cheque.net_pay_amt 
	DEFINE l_tax_total LIKE cheque.net_pay_amt
	DEFINE l_arr_address ARRAY[5] OF CHAR(32) 
	DEFINE l_cheque_text CHAR(9) 
	DEFINE l_arr_words ARRAY[10] OF CHAR(5) 
	DEFINE l_hundthous, l_tensthous, l_thous, l_hund, l_tens, l_xunits CHAR(5) 
	DEFINE l_cents CHAR(2) 
	DEFINE l_line_cnt SMALLINT 
	DEFINE l_printchq_ind SMALLINT 
	DEFINE l_kandoo_line_cnt SMALLINT 
	DEFINE l_amount_text CHAR(17) 
	DEFINE l_pr_cents DECIMAL(16,2) 
	DEFINE c1, c2, c3, c4, c5, c6, c7, c9_10 INTEGER 
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
			LET l_printchq_ind = false 
			PRINT COLUMN 16, l_arr_address[1] 
			PRINT COLUMN 16, l_arr_address[2], 
			COLUMN 60, l_rec_vendor.vend_code CLIPPED 
			PRINT COLUMN 16, l_arr_address[3] 
			PRINT COLUMN 16, l_arr_address[4] 
			PRINT COLUMN 16, l_arr_address[5], 
			COLUMN 60, p_cheque_date USING "dd-mm-yy" 
			SKIP 2 LINES 
			PRINT COLUMN 04, "Date", 
			COLUMN 12, "Invoice No.", 
			COLUMN 29, "Inv.Total", 
			COLUMN 40, " Credits", 
			COLUMN 50, "Discount", 
			COLUMN 60, "PPT/Ret", 
			COLUMN 71, "Payment" 
			SKIP 1 line 

		BEFORE GROUP OF p_doc_id 
			SKIP TO top OF PAGE 
			LET l_voucher_total = 0 
			LET l_voucher2_total = 0 
			LET l_line_cnt = 0 
			LET l_disc_total = 0 
			LET l_cheque_amt = 0 
			LET l_invoice_total = 0 
			LET l_tax_total = 0 
			LET l_prev_total = 0 

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
				'1', 
				p_rec_tentpays.cmpy_code) 
				RETURNING l_voucher_total, 
				l_tax_amt 
				LET l_voucher2_total = l_voucher2_total + p_rec_tentpays.vouch_amt 
			ELSE 
				LET l_voucher_total = p_rec_tentpays.vouch_amt 
				LET l_tax_amt = 0 
			END IF 
			LET l_prev_total = l_prev_total+ l_rec_voucher.paid_amt 
			LET l_disc_total = l_disc_total+ p_rec_tentpays.taken_disc_amt 
			LET l_tax_total = l_tax_total + l_tax_amt 
			LET l_cheque_amt = l_cheque_amt+ l_voucher_total 
			LET l_invoice_total = l_invoice_total + l_rec_voucher.total_amt 
			IF l_rec_voucher.paid_amt = 0 THEN 
				LET l_rec_voucher.paid_amt = NULL 
			END IF 
			IF p_rec_tentpays.taken_disc_amt = 0 THEN 
				LET p_rec_tentpays.taken_disc_amt = NULL 
			END IF 
			IF l_tax_amt = 0 THEN 
				LET l_tax_amt = NULL 
			END IF 
			PRINT COLUMN 02, l_rec_voucher.vouch_date USING "dd/mm/yy", 
			COLUMN 11, l_rec_voucher.inv_text[1,16], 
			COLUMN 27, l_rec_voucher.total_amt USING "-------&.&&", 
			COLUMN 38, l_rec_voucher.paid_amt USING "-------&.&&", 
			COLUMN 49, p_rec_tentpays.taken_disc_amt USING "-----&.&&", 
			COLUMN 58, l_tax_amt USING "-----&.&&", 
			COLUMN 67, l_voucher_total USING "-------&.&&" 

		AFTER GROUP OF p_doc_id 
			LET l_pr_cents = 0.00 
			LET l_printchq_ind = true 
			LET l_page_num = pageno 
			IF l_tax_total <> 0 THEN 
				CALL wtaxcalc(l_voucher2_total, 
				p_rec_tentpays.tax_per, 
				p_rec_tentpays.withhold_tax_ind, 
				p_rec_tentpays.cmpy_code) 
				RETURNING l_cheque_amt, 
				l_tax2_total 
				IF l_tax2_total <> l_tax_total THEN 
					LET l_pr_cents = l_tax2_total - l_tax_total 
				END IF 
				LET l_tax_total = l_tax2_total 
			END IF 
			LET l_cheque_total = l_cheque_amt 
			UPDATE t_docid 
			SET page_no = l_page_num
			WHERE doc_id = p_doc_id 

			PAGE TRAILER 
				SKIP 1 line 
				IF l_printchq_ind THEN 
					IF l_pr_cents <> 0.00 THEN 
						PRINT 
						COLUMN 02,"PPT Rounding", 
						COLUMN 58,l_pr_cents     USING "-----&.&&", 
						COLUMN 67,0 - l_pr_cents USING "-------&.&&" 
					ELSE 
						SKIP 1 line 
					END IF 
					IF l_prev_total = 0 THEN 
						LET l_prev_total = NULL 
					END IF 
					IF l_disc_total = 0 THEN 
						LET l_disc_total = NULL 
					END IF 
					IF l_tax_total = 0 THEN 
						LET l_tax_total = NULL 
					END IF 
					PRINT 
					COLUMN 27, l_invoice_total  USING "-------&.&&", 
					COLUMN 38, l_prev_total     USING "-------&.&&", 
					COLUMN 49, l_disc_total     USING "-----&.&&", 
					COLUMN 58, l_tax_total      USING "-----&.&&", 
					COLUMN 67, l_cheque_amt     USING "-------&.&&" 
					SKIP 7 LINES 
					PRINT COLUMN 13, l_rec_vendor.name_text, 
					COLUMN 69, p_cheque_date    USING "dd/mm/yy" 
					SKIP 3 LINES 
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
					COLUMN 09, l_hundthous CLIPPED, 
					COLUMN 17, l_tensthous CLIPPED, 
					COLUMN 25, l_thous CLIPPED, 
					COLUMN 33, l_hund CLIPPED, 
					COLUMN 40, l_tens CLIPPED, 
					COLUMN 49, l_xunits CLIPPED, 
					COLUMN 60, l_cents USING "&&", 
					COLUMN 68, l_cheque_total   USING "######&.&&" 
					SKIP 5 LINES 
				ELSE 
					PRINT 
					COLUMN 48, "BALANCE B/F", 
					COLUMN 68, l_invoice_total  USING "------&.&&" 
					SKIP 8 LINES 
					PRINT COLUMN 13, "***VOID***", 
					COLUMN 69, "********" 
					SKIP 3 LINES 
					PRINT 
					COLUMN 09, "VOID", # 100,000's COLUMN 
					COLUMN 17, "VOID", # 10,000's COLUMN 
					COLUMN 25, "VOID", # 1,000's COLUMN 
					COLUMN 33, "VOID", # 100's COLUMN 
					COLUMN 40, "VOID", # 10's COLUMN 
					COLUMN 49, "VOID", # units COLUMN 
					COLUMN 60, "**", # l_cents COLUMN 
					COLUMN 68, "**********" # amount in numbers 
					SKIP 4 LINES 
					PRINT 
					COLUMN 09, "XXXXXXXXXXXXXXXXXXXXX", 
					COLUMN 60, "XXXXXXXXXXXXXXXXXXXXX" 
				END IF 

END REPORT 
