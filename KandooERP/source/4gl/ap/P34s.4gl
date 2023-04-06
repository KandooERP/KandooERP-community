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
# Description: Program P34s Cheque Print Without JETFORM enhancements Remittance section AT the top
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
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_ucherpays RECORD LIKE voucherpays.* 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_invoice_total LIKE vendor.bal_amt 
	DEFINE l_tax_amt LIKE cheque.net_pay_amt 
	DEFINE l_vend_ref LIKE debithead.debit_text 
	DEFINE l_detail_count SMALLINT 
	DEFINE l_lines_reqd SMALLINT
	DEFINE l_skip_lines SMALLINT
	DEFINE l_statement_finished SMALLINT
	DEFINE l_vend_ad1, l_vend_ad2, l_vend_ad3, l_vend_ad4, l_vend_ad5 CHAR(40) 
	DEFINE l_bal_amt, l_chq_amt DECIMAL(10,2) 
	DEFINE l_amt_text CHAR(9) 
	DEFINE l_cents CHAR(2) 
	DEFINE l_arr_words ARRAY[10] OF CHAR(5) 
	DEFINE l_hundthous, l_tensthous, l_thous, l_hund, l_tens, l_xunits CHAR(5) 
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
			LET l_arr_words[10]= " NINE" 
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
			LET l_vend_ad1 = l_rec_vendor.name_text CLIPPED 
			LET l_vend_ad2 = l_rec_vendor.addr1_text CLIPPED 
			LET l_vend_ad3 = l_rec_vendor.addr2_text CLIPPED 
			LET l_vend_ad4 = l_rec_vendor.addr3_text CLIPPED 
			LET l_vend_ad5 = l_rec_vendor.city_text 
			IF l_vend_ad5 IS NULL THEN 
				LET l_vend_ad5 = l_rec_vendor.state_code 
			ELSE 
				IF l_rec_vendor.state_code IS NOT NULL THEN 
					LET l_vend_ad5 = l_vend_ad5 CLIPPED, ", ", 
					l_rec_vendor.state_code CLIPPED 
				END IF 
			END IF 
			IF l_vend_ad5 IS NULL THEN 
				LET l_vend_ad5 = l_rec_vendor.post_code 
			ELSE 
				IF l_rec_vendor.post_code IS NOT NULL THEN 
					LET l_vend_ad5 = l_vend_ad5 CLIPPED, ", ", 
					l_rec_vendor.post_code CLIPPED 
				END IF 
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
			LET l_statement_finished = false 
			PRINT COLUMN 18, l_rec_vendor.name_text 
			SKIP 2 LINES 

		BEFORE GROUP OF p_doc_id 
			SKIP TO top OF PAGE 
			LET l_invoice_total = 0 
			LET l_detail_count = 0 

		ON EVERY ROW 
			#        There are 33 lines FOR statement details on the cheque,
			#        including the carried forward balance
			IF l_detail_count = 32 THEN 
				PRINT 
				COLUMN 20, "BALANCE C/F", 
				COLUMN 40, l_invoice_total USING "--,---,--&.&&" 
				SKIP 1 LINE 
				PRINT 
				COLUMN 20, "BALANCE B/F", 
				COLUMN 40, l_invoice_total USING "--,---,--&.&&", 
				COLUMN 57, l_rec_vendor.vend_code, 
				COLUMN 67, p_cheque_date   USING "dd/mm/yy" 
				LET l_detail_count = 1 
			END IF 
			SELECT * INTO l_rec_voucher.* FROM voucher 
			WHERE cmpy_code = p_rec_tentpays.cmpy_code 
			AND vouch_code = p_rec_tentpays.vouch_code 
			AND vend_code = p_rec_tentpays.vend_code 
			LET l_detail_count = l_detail_count + 1 
			PRINT 
			COLUMN 05, l_rec_voucher.vouch_date USING "dd/mm/yy", 
			COLUMN 15, l_rec_voucher.inv_text[1,16], 
			COLUMN 32, l_rec_voucher.vouch_code USING "########", 
			COLUMN 40, l_rec_voucher.total_amt  USING "--,---,--&.&&"; 
			IF l_detail_count = 1 THEN # FIRST detail in statement 
				PRINT 
				COLUMN 57, l_rec_vendor.vend_code, 
				COLUMN 67, p_cheque_date         USING "dd/mm/yy" 
			ELSE 
				PRINT "" 
			END IF 
			LET l_invoice_total = l_invoice_total + p_rec_tentpays.vouch_amt 
			IF p_rec_tentpays.taken_disc_amt != 0 THEN 
				IF l_detail_count = 32 THEN 
					PRINT 
					COLUMN 20, "BALANCE C/F", 
					COLUMN 40, l_invoice_total    USING "--,---,--&.&&" 
					SKIP 1 LINE 
					PRINT 
					COLUMN 20, "BALANCE B/F", 
					COLUMN 40, l_invoice_total    USING "--,---,--&.&&", 
					COLUMN 57, l_rec_vendor.vend_code, 
					COLUMN 67, p_cheque_date      USING "dd/mm/yy" 
					LET l_detail_count = 1 
				END IF 
				LET l_detail_count = l_detail_count + 1 
				PRINT 
				COLUMN 05, l_rec_voucher.disc_date            USING "dd/mm/yy", 
				COLUMN 15, "Discount", 
				COLUMN 40, p_rec_tentpays.taken_disc_amt * -1 USING "--,---,---.&&" 
			END IF 
			IF l_rec_voucher.paid_amt != 0 THEN 
				DECLARE c_voucherpays CURSOR FOR 
				SELECT * FROM voucherpays 
				WHERE cmpy_code = p_rec_tentpays.cmpy_code 
				AND vend_code = p_rec_tentpays.vend_code 
				AND vouch_code = p_rec_tentpays.vouch_code 
				AND rev_flag IS NULL 
				FOREACH c_voucherpays INTO l_rec_ucherpays.* 
					IF l_detail_count = 32 THEN 
						PRINT 
						COLUMN 20, "BALANCE C/F", 
						COLUMN 40, l_invoice_total USING "--,---,--&.&&" 
						SKIP 1 LINE 
						PRINT 
						COLUMN 20, "BALANCE B/F", 
						COLUMN 40, l_invoice_total USING "--,---,--&.&&", 
						COLUMN 57, l_rec_vendor.vend_code, 
						COLUMN 67, p_cheque_date   USING "dd/mm/yy" 
						LET l_detail_count = 1 
					END IF 
					LET l_detail_count = l_detail_count + 1 
					PRINT COLUMN 05, l_rec_ucherpays.pay_date USING "dd/mm/yy"; 
					IF l_rec_ucherpays.pay_type_code = "CH" THEN 
						LET l_vend_ref = NULL 
						SELECT com3_text INTO l_vend_ref FROM cheque 
						WHERE cmpy_code = l_rec_ucherpays.cmpy_code 
						AND vend_code = l_rec_ucherpays.vend_code 
						AND cheq_code = l_rec_ucherpays.pay_num 
						AND bank_code = l_rec_ucherpays.bank_code 
						AND pay_meth_ind = "1" 
						PRINT COLUMN 15, "CH "; 
					ELSE 
						LET l_vend_ref = NULL 
						SELECT debit_text INTO l_vend_ref FROM debithead 
						WHERE cmpy_code = l_rec_ucherpays.cmpy_code 
						AND vend_code = l_rec_ucherpays.vend_code 
						AND debit_num = l_rec_ucherpays.pay_num 
						PRINT COLUMN 15, "DR "; 
					END IF 
					PRINT 
					COLUMN 18, l_vend_ref[1,13], 
					COLUMN 31, l_rec_ucherpays.pay_num        USING "#########", 
					COLUMN 40, l_rec_ucherpays.apply_amt * -1	USING "--,---,---.&&" 
					IF l_rec_ucherpays.disc_amt !=0 THEN 
						IF l_detail_count = 32 THEN 
							PRINT 
							COLUMN 20, "BALANCE C/F", 
							COLUMN 40, l_invoice_total          USING "--,---,--&.&&" 
							SKIP 1 LINE 
							PRINT 
							COLUMN 20, "BALANCE B/F", 
							COLUMN 40, l_invoice_total          USING "--,---,--&.&&", 
							COLUMN 57, l_rec_vendor.vend_code, 
							COLUMN 67, p_cheque_date            USING "dd/mm/yy" 
							LET l_detail_count = 1 
						END IF 
						LET l_detail_count = l_detail_count + 1 
						PRINT 
						COLUMN 05, l_rec_ucherpays.pay_date    USING "dd/mm/yy", 
						COLUMN 15, "Taken Discount", 
						COLUMN 31, l_rec_ucherpays.pay_num     USING "#########", 
						COLUMN 40, l_rec_ucherpays.disc_amt * -1 
						USING "--,---,---.&&" 
					END IF 
				END FOREACH 
			END IF 

		AFTER GROUP OF p_doc_id 
			#        Print any Unapplied Cheque OR Debit information
			SELECT UNIQUE 1 FROM cheque 
			WHERE cmpy_code = p_rec_tentpays.cmpy_code 
			AND vend_code = p_rec_tentpays.vend_code 
			AND pay_amt <> apply_amt 
			AND pay_meth_ind = "1" 

			#        There are 34 lines in the statement body of which 33 are used.
			#        Subtracting the detail count FROM 34 gives the number of lines left
			#        TO the END of the remittance advice section.
			LET l_statement_finished = true 
			LET l_chq_amt = l_invoice_total 
			LET l_tax_amt = 0 
			LET l_lines_reqd = 3 
			IF p_rec_tentpays.withhold_tax_ind != "0" THEN 
				CALL wtaxcalc(l_invoice_total, 
				p_rec_tentpays.tax_per, 
				p_rec_tentpays.withhold_tax_ind, 
				p_rec_tentpays.cmpy_code) 
				RETURNING l_chq_amt, 
				l_tax_amt 
				LET l_lines_reqd = l_lines_reqd + 1 
			END IF 
			LET l_skip_lines = 34 - l_detail_count 
			IF l_skip_lines < l_lines_reqd THEN 
				PRINT 
				COLUMN 20, "BALANCE C/F", 
				COLUMN 40, l_invoice_total USING "--,---,--&.&&" 
				LET l_skip_lines = l_skip_lines - 1 
				FOR cnt = 1 TO l_skip_lines 
					SKIP 1 LINE 
				END FOR 
				PRINT 
				COLUMN 20, "BALANCE B/F", 
				COLUMN 40, l_invoice_total USING "--,---,--&.&&", 
				COLUMN 57, l_rec_vendor.vend_code, 
				COLUMN 67, p_cheque_date   USING "dd/mm/yy" 
				LET l_detail_count = 1 #LINE count IS the LINE TO be printed NEXT 
			END IF 
			SKIP 1 LINE 
			PRINT 
			COLUMN 15, "CHEQUE ATTACHED", 
			COLUMN 39, l_chq_amt          USING "---,---,--&.&&" 
			LET l_detail_count = l_detail_count + 2 
			IF p_rec_tentpays.withhold_tax_ind != "0" THEN 
				PRINT 
				COLUMN 15, "TAX AMOUNT", 
				COLUMN 39, l_tax_amt       USING "---,---,--&.&&" 
				LET l_detail_count = l_detail_count + 1 
			END IF 
			LET l_bal_amt = l_invoice_total - 
			l_chq_amt - 
			l_tax_amt 
			PRINT 
			COLUMN 20, "BALANCE", 
			COLUMN 39, l_bal_amt          USING "---,---,--&.&&" 
			LET l_detail_count = l_detail_count + 1 
			LET l_skip_lines = 34 - l_detail_count 
			FOR cnt = 1 TO l_skip_lines 
				SKIP 1 LINE 
			END FOR 
			PAGE TRAILER 
				IF l_statement_finished 
				AND l_chq_amt < 1000000 THEN 
					#           Cannot PRINT millions on B+P stationary
					SKIP 10 LINES 
					LET l_amt_text = l_chq_amt USING "&&&&&&.&&" 
					LET c1 = l_amt_text[1] 
					LET c2 = l_amt_text[2] 
					LET c3 = l_amt_text[3] 
					LET c4 = l_amt_text[4] 
					LET c5 = l_amt_text[5] 
					LET c6 = l_amt_text[6] 
					LET c7 = l_amt_text[8,9] 
					LET l_hundthous = l_arr_words[c1+1] 
					LET l_tensthous = l_arr_words[c2+1] 
					LET l_thous = l_arr_words[c3+1] 
					LET l_hund = l_arr_words[c4+1] 
					LET l_tens = l_arr_words[c5+1] 
					LET l_xunits = l_arr_words[c6+1] 
					LET l_cents = c7 
					PRINT COLUMN 09, l_hundthous CLIPPED, 
					COLUMN 16, l_tensthous CLIPPED, 
					COLUMN 22, l_thous CLIPPED, 
					COLUMN 28, l_hund CLIPPED, 
					COLUMN 34, l_tens CLIPPED, 
					COLUMN 40, l_xunits CLIPPED, 
					COLUMN 46, l_cents       USING "&&", 
					COLUMN 54, p_cheque_date USING "dd/mm/yy", 
					COLUMN 64, l_chq_amt     USING "*,***,**&.&&" 
					LET l_page_num = pageno 
					UPDATE t_docid 
					SET page_no = l_page_num
					WHERE doc_id = p_doc_id 
					SKIP 2 LINES 
					PRINT COLUMN 12, l_vend_ad1 
					PRINT COLUMN 12, l_vend_ad2 
					PRINT COLUMN 12, l_vend_ad3 
					PRINT COLUMN 12, l_vend_ad4 
					PRINT COLUMN 12, l_vend_ad5 
				ELSE 
					SKIP 10 LINES 
					PRINT COLUMN 10, "VOID", # 100,000's COLUMN 
					COLUMN 17, "VOID", # 10,000's COLUMN 
					COLUMN 23, "VOID", # 1,000's COLUMN 
					COLUMN 29, "VOID", # 100's COLUMN 
					COLUMN 35, "VOID", # 10's COLUMN 
					COLUMN 41, "VOID", # units COLUMN 
					COLUMN 46, "**", # l_cents COLUMN 
					COLUMN 54, "**VOID**", # DATE 
					COLUMN 64, "*************" # amount in numbers 
					SKIP 2 LINES 
					IF l_statement_finished THEN 
						PRINT COLUMN 12, l_vend_ad1 
						PRINT COLUMN 12, l_vend_ad2 
						PRINT COLUMN 12, l_vend_ad3 
						PRINT COLUMN 12, l_vend_ad4 
						PRINT COLUMN 12, l_vend_ad5 
					ELSE 
						PRINT COLUMN 12, "VOID" 
						PRINT COLUMN 12, "VOID" 
						PRINT COLUMN 12, "VOID" 
						PRINT COLUMN 12, "VOID" 
						PRINT COLUMN 12, "VOID" 
					END IF 
				END IF 
END REPORT 
