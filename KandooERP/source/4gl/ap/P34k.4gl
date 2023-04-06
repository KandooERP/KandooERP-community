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
# \brief module P34k Cheque Print  Modified FOR Brick AND Pipe Industries Remittance section AT the top
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
	DEFINE l_rec_voucherpays RECORD LIKE voucherpays.* 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_invoice_total LIKE vendor.bal_amt 
	DEFINE l_tax_amt LIKE cheque.net_pay_amt 
	DEFINE l_vend_ref LIKE debithead.debit_text 
	DEFINE l_signature_text1 LIKE kandoouser.signature_text 
	DEFINE l_signature_text2 LIKE kandoouser.signature_text 
	DEFINE l_detail_count SMALLINT 
	DEFINE l_lines_reqd SMALLINT
	DEFINE l_skip_lines SMALLINT
	DEFINE l_statement_finished SMALLINT
	DEFINE l_first_page SMALLINT 
	DEFINE l_vend_ad1, l_vend_ad2, l_vend_ad3, l_vend_ad4, l_vend_ad5 CHAR(40) --huho FROM 35 TO 40 CHAR(35) TO match this variables defined in other files 
	#The program 'P34k' could NOT be created for the following reasons: The variable (l_vend_ad5) has been redefined with a different type OR length.
	#The variable that IS shown IS defined in the GLOBALS section of two OR
	#more modules, but it IS defined differently in some modules than in
	#others. Possibly modules were compiled at different times, with some
	#change TO the common GLOBALS file between. Possibly the variable IS
	#declared as a module variable in some module that does NOT include the
	#GLOBALS file.
	DEFINE l_bal_amt, l_chq_amt DECIMAL(10,2) 
	DEFINE l_amt_text CHAR(9) 
	DEFINE l_cents CHAR(2) 
	DEFINE l_arr_words ARRAY[10] OF CHAR(5) 
	DEFINE l_hundthous, l_tensthous, l_thous, l_hund, l_tens, l_xunits CHAR(5) 
	DEFINE c1, c2, c3, c4, c5, c6, c7, c9_10 INTEGER

	ORDER BY p_doc_id 

	FORMAT 
		FIRST PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,PAGENO) #update page number and report header line 1
			LET l_page_num = 0 
			LET l_first_page = 0 
			LET l_detail_count = 0 

		ON EVERY ROW 
			IF l_first_page = 0 THEN 
				PRINT "\^job CHEQUE" 
				LET l_first_page = l_first_page + 1 
			END IF 
			IF l_detail_count = 0 THEN 
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
				LET l_invoice_total = 0 
				LET l_detail_count = 0 
				PRINT "\^form CHEQUE.MDF" 
				PRINT "\^field CREDITOR" 
				PRINT l_rec_vendor.name_text 
				PRINT "\^field ACCOUNT" 
				PRINT l_rec_vendor.vend_code 
				PRINT "\^field DATE1" 
				PRINT p_cheque_date USING "dd/mm/yy" 
				PRINT "\^record CHEQUE" 
				PRINT "\^continue DATE2 11 01" 
				PRINT "\^continue YREF 21 12" 
				PRINT "\^continue OREF 08 33" 
				PRINT "\^continue AMOUNT1 14 41" 
			END IF 
			###BEFORE GROUP OF p_doc_id
			#        There are 31 lines FOR statement details on the cheque,
			#        including the carried forward balance
			IF l_detail_count = 31 THEN 
				LET l_detail_count = 0 
				PRINT 11 SPACES, "BALANCE C/F ",8 SPACES, 
				l_invoice_total USING "--,---,--&.&&" 
				PRINT "\^field HT" 
				PRINT "VOID" 
				PRINT "\^field TT" 
				PRINT "VOID" 
				PRINT "\^field TH" 
				PRINT "VOID" 
				PRINT "\^field H" 
				PRINT "VOID" 
				PRINT "\^field T" 
				PRINT "VOID" 
				PRINT "\^field U" 
				PRINT "VOID" 
				PRINT "\^field C" 
				PRINT "**" 
				PRINT "\^field DATE" 
				PRINT "***VOID***" 
				PRINT "\^field AMOUNT" 
				PRINT "**********" 
				PRINT "\^field ADDRESS" 
				PRINT "VOID" 
				PRINT "VOID" 
				PRINT "VOID" 
				PRINT "VOID" 
				PRINT "VOID" 
				PRINT "\^eject" 
				PRINT "\^field CREDITOR" 
				PRINT l_rec_vendor.name_text 
				PRINT "\^field ACCOUNT" 
				PRINT l_rec_vendor.vend_code 
				PRINT "\^field DATE1" 
				PRINT p_cheque_date USING "dd/mm/yy" 
				PRINT "\^record CHEQUE" 
				PRINT "\^continue DATE2 11 01" 
				PRINT "\^continue YREF 21 12" 
				PRINT "\^continue OREF 08 33" 
				PRINT "\^continue AMOUNT1 14 41" 
				PRINT 11 SPACES, "BALANCE B/F ",8 SPACES, 
				l_invoice_total USING "--,---,--&.&&" 
				LET l_detail_count = 1 
				LET l_page_num = l_page_num + 1 
				UPDATE t_docid 
				SET page_no = l_page_num 
				WHERE doc_id = p_doc_id 
			END IF 
			SELECT * INTO l_rec_voucher.* FROM voucher 
			WHERE cmpy_code = p_rec_tentpays.cmpy_code 
			AND vouch_code = p_rec_tentpays.vouch_code 
			AND vend_code = p_rec_tentpays.vend_code 
			PRINT l_rec_voucher.vouch_date USING "dd/mm/yy",3 SPACES, 
			l_rec_voucher.inv_text[1,20]," ", 
			l_rec_voucher.vouch_code USING "########", 
			l_rec_voucher.total_amt USING "---,---,---.&&" 
			LET l_detail_count = l_detail_count + 1 
			LET l_invoice_total = l_invoice_total + p_rec_tentpays.vouch_amt 
			IF p_rec_tentpays.taken_disc_amt != 0 THEN 
				IF l_detail_count = 31 THEN 
					LET l_detail_count = 0 
					PRINT 11 SPACES, "BALANCE C/F ",8 SPACES, 
					l_invoice_total USING "---,---,--&.&&" 
					PRINT "\^field HT" 
					PRINT "VOID" 
					PRINT "\^field TT" 
					PRINT "VOID" 
					PRINT "\^field TH" 
					PRINT "VOID" 
					PRINT "\^field H" 
					PRINT "VOID" 
					PRINT "\^field T" 
					PRINT "VOID" 
					PRINT "\^field U" 
					PRINT "VOID" 
					PRINT "\^field C" 
					PRINT "**" 
					PRINT "\^field DATE" 
					PRINT "***VOID***" 
					PRINT "\^field AMOUNT" 
					PRINT "**********" 
					PRINT "\^field ADDRESS" 
					PRINT "VOID" 
					PRINT "VOID" 
					PRINT "VOID" 
					PRINT "VOID" 
					PRINT "VOID" 
					PRINT "\^eject" 
					PRINT "\^field CREDITOR" 
					PRINT l_rec_vendor.name_text 
					PRINT "\^field ACCOUNT" 
					PRINT l_rec_vendor.vend_code 
					PRINT "\^field DATE1" 
					PRINT p_cheque_date USING "dd/mm/yy" 
					PRINT "\^record CHEQUE" 
					PRINT "\^continue DATE2 11 01" 
					PRINT "\^continue YREF 21 12" 
					PRINT "\^continue OREF 08 33" 
					PRINT "\^continue AMOUNT1 14 41" 
					PRINT 11 SPACES, "BALANCE B/F ",8 SPACES, 
					l_invoice_total USING "---,---,--&.&&" 
					LET l_detail_count = l_detail_count + 1 
					LET l_page_num = l_page_num + 1 
					UPDATE t_docid 
					SET page_no = l_page_num
					WHERE doc_id = p_doc_id 
				END IF 
				PRINT l_rec_voucher.disc_date USING "dd/mm/yy",3 SPACES, 
				"Discount",21 SPACES, 
				p_rec_tentpays.taken_disc_amt * -1 USING "---,---,---.&&" 
				LET l_detail_count = l_detail_count + 1 
			END IF 
			IF l_rec_voucher.paid_amt != 0 THEN 
				DECLARE c_voucherpays CURSOR FOR 
				SELECT * FROM voucherpays 
				WHERE cmpy_code = p_rec_tentpays.cmpy_code 
				AND vend_code = p_rec_tentpays.vend_code 
				AND vouch_code = p_rec_tentpays.vouch_code 
				AND rev_flag IS NULL 
				FOREACH c_voucherpays INTO l_rec_voucherpays.* 
					IF l_detail_count = 31 THEN 
						LET l_detail_count = 0 
						PRINT 11 SPACES, "BALANCE C/F ",8 SPACES, 
						l_invoice_total USING "---,---,--&.&&" 
						PRINT "\^field HT" 
						PRINT "VOID" 
						PRINT "\^field TT" 
						PRINT "VOID" 
						PRINT "\^field TH" 
						PRINT "VOID" 
						PRINT "\^field H" 
						PRINT "VOID" 
						PRINT "\^field T" 
						PRINT "VOID" 
						PRINT "\^field U" 
						PRINT "VOID" 
						PRINT "\^field C" 
						PRINT "**" 
						PRINT "\^field DATE" 
						PRINT "***VOID***" 
						PRINT "\^field AMOUNT" 
						PRINT "**********" 
						PRINT "\^field ADDRESS" 
						PRINT "VOID" 
						PRINT "VOID" 
						PRINT "VOID" 
						PRINT "VOID" 
						PRINT "VOID" 
						PRINT "\^eject" 
						PRINT "\^field CREDITOR" 
						PRINT l_rec_vendor.name_text 
						PRINT "\^field ACCOUNT" 
						PRINT l_rec_vendor.vend_code 
						PRINT "\^field DATE1" 
						PRINT p_cheque_date USING "dd/mm/yy" 
						PRINT "\^record CHEQUE" 
						PRINT "\^continue DATE2 11 01" 
						PRINT "\^continue YREF 21 12" 
						PRINT "\^continue OREF 08 33" 
						PRINT "\^continue AMOUNT1 14 41" 
						PRINT 11 SPACES, "BALANCE B/F ",8 SPACES, 
						l_invoice_total USING "---,---,--&.&&" 
						LET l_detail_count = 1 
						LET l_page_num = l_page_num + 1 
						UPDATE t_docid 
						SET page_no = l_page_num
						WHERE doc_id = p_doc_id 
					END IF 
					IF l_rec_voucherpays.pay_type_code = "CH" THEN 
						LET l_vend_ref = NULL 
						SELECT com3_text INTO l_vend_ref FROM cheque 
						WHERE cmpy_code = l_rec_voucherpays.cmpy_code 
						AND vend_code = l_rec_voucherpays.vend_code 
						AND cheq_code = l_rec_voucherpays.pay_num 
						AND bank_code = l_rec_voucherpays.bank_code 
						AND pay_meth_ind = "1" 
						PRINT l_rec_voucherpays.pay_date USING "dd/mm/yy",3 SPACES, 
						"CH ", 
						l_vend_ref[1,13]," ", 
						l_rec_voucherpays.pay_num USING "########", 
						l_rec_voucherpays.apply_amt * -1 USING "---,---,---.&&" 
					ELSE 
						LET l_vend_ref = NULL 
						SELECT debit_text INTO l_vend_ref FROM debithead 
						WHERE cmpy_code = l_rec_voucherpays.cmpy_code 
						AND vend_code = l_rec_voucherpays.vend_code 
						AND debit_num = l_rec_voucherpays.pay_num 
						PRINT l_rec_voucherpays.pay_date USING "dd/mm/yy",3 SPACES, 
						"DR ", 
						l_vend_ref[1,13]," ", 
						l_rec_voucherpays.pay_num USING "########", 
						l_rec_voucherpays.apply_amt * -1 USING "---,---,---.&&" 
					END IF 
					LET l_detail_count = l_detail_count + 1 
					IF l_rec_voucherpays.disc_amt !=0 THEN 
						IF l_detail_count = 31 THEN 
							LET l_detail_count = 0 
							PRINT 11 SPACES, "BALANCE C/F ",8 SPACES, 
							l_invoice_total USING "---,---,--&.&&" 
							PRINT "\^field HT" 
							PRINT "VOID" 
							PRINT "\^field TT" 
							PRINT "VOID" 
							PRINT "\^field TH" 
							PRINT "VOID" 
							PRINT "\^field H" 
							PRINT "VOID" 
							PRINT "\^field T" 
							PRINT "VOID" 
							PRINT "\^field U" 
							PRINT "VOID" 
							PRINT "\^field C" 
							PRINT "**" 
							PRINT "\^field DATE" 
							PRINT "***VOID***" 
							PRINT "\^field AMOUNT" 
							PRINT "**********" 
							PRINT "\^field ADDRESS" 
							PRINT "VOID" 
							PRINT "VOID" 
							PRINT "VOID" 
							PRINT "VOID" 
							PRINT "VOID" 
							PRINT "\^eject" 
							PRINT "\^field CREDITOR" 
							PRINT l_rec_vendor.name_text 
							PRINT "\^field ACCOUNT" 
							PRINT l_rec_vendor.vend_code 
							PRINT "\^field DATE1" 
							PRINT p_cheque_date USING "dd/mm/yy" 
							PRINT "\^record CHEQUE" 
							PRINT "\^continue DATE2 11 01" 
							PRINT "\^continue YREF 21 12" 
							PRINT "\^continue OREF 08 33" 
							PRINT "\^continue AMOUNT1 14 41" 
							PRINT 11 SPACES, "BALANCE B/F ",8 SPACES, 
							l_invoice_total USING "---,---,--&.&&" 
							LET l_detail_count = 1 
							LET l_page_num = l_page_num + 1 
							UPDATE t_docid 
							SET page_no = l_page_num
							WHERE doc_id = p_doc_id 
						END IF 
						PRINT l_rec_voucherpays.pay_date USING "dd/mm/yy",3 SPACES, 
						"Taken Discount",7 SPACES, 
						l_rec_voucherpays.pay_num USING "########", 
						l_rec_voucherpays.disc_amt * -1 USING "---,---,---.&&" 
						LET l_detail_count = l_detail_count + 1 
					END IF 
				END FOREACH 
			END IF 

		AFTER GROUP OF p_doc_id 
			#        Print any Unapplied Cheque OR Debit information
			SELECT unique 1 FROM cheque 
			WHERE cmpy_code = p_rec_tentpays.cmpy_code 
			AND vend_code = p_rec_tentpays.vend_code 
			AND pay_amt <> apply_amt 
			AND pay_meth_ind = "1" 
			CASE 
				WHEN get_kandoooption_feature_state('AP','CH') = 2 
					SELECT signature_text INTO l_signature_text1 FROM kandoouser 
					WHERE sign_on_code = glob_user_text1 
					SELECT signature_text INTO l_signature_text2 FROM kandoouser 
					WHERE sign_on_code = glob_user_text2 
				WHEN get_kandoooption_feature_state('AP','CH') = 1 
					SELECT signature_text INTO l_signature_text1 FROM kandoouser 
					WHERE sign_on_code = glob_user_text1 
					LET l_signature_text2 = NULL 
			END CASE 
			#        There are 32 lines in the statement body of which 32 are used.
			#        Subtracting the detail count FROM 32 gives the number of lines left
			#        TO the END of the remittance advice section.
			LET l_statement_finished = true 
			LET l_chq_amt = l_invoice_total 
			LET l_tax_amt = 0 
			LET l_lines_reqd = 4 
			IF p_rec_tentpays.withhold_tax_ind != "0" THEN 
				CALL wtaxcalc(l_invoice_total, 
				p_rec_tentpays.tax_per, 
				p_rec_tentpays.withhold_tax_ind, 
				p_rec_tentpays.cmpy_code) 
				RETURNING l_chq_amt, 
				l_tax_amt 
				LET l_lines_reqd = l_lines_reqd + 1 
			END IF 
			LET l_skip_lines = 32 - l_detail_count 
			IF l_skip_lines < l_lines_reqd THEN 
				PRINT 11 SPACES, "BALANCE C/F ",8 SPACES, 
				l_invoice_total USING "---,---,--&.&&" 
				PRINT "\^field HT" 
				PRINT "VOID" 
				PRINT "\^field TT" 
				PRINT "VOID" 
				PRINT "\^field TH" 
				PRINT "VOID" 
				PRINT "\^field H" 
				PRINT "VOID" 
				PRINT "\^field T" 
				PRINT "VOID" 
				PRINT "\^field U" 
				PRINT "VOID" 
				PRINT "\^field C" 
				PRINT "**" 
				PRINT "\^field DATE" 
				PRINT "***VOID***" 
				PRINT "\^field AMOUNT" 
				PRINT "**********" 
				PRINT "\^field ADDRESS" 
				PRINT "VOID" 
				PRINT "VOID" 
				PRINT "VOID" 
				PRINT "VOID" 
				PRINT "VOID" 
				PRINT "\^eject" 
				PRINT "\^field CREDITOR" 
				PRINT l_rec_vendor.name_text 
				PRINT "\^field ACCOUNT" 
				PRINT l_rec_vendor.vend_code 
				PRINT "\^field DATE1" 
				PRINT p_cheque_date USING "dd/mm/yy" 
				PRINT "\^record CHEQUE" 
				PRINT "\^continue DATE2 11 01" 
				PRINT "\^continue YREF 21 12" 
				PRINT "\^continue OREF 08 33" 
				PRINT "\^continue AMOUNT1 14 41" 
				PRINT 11 SPACES, "BALANCE B/F ",8 SPACES, 
				l_invoice_total USING "---,---,--&.&&" 
				LET l_page_num = l_page_num + 1 
				UPDATE t_docid 
				SET page_no = l_page_num
				WHERE doc_id = p_doc_id 
			END IF 
			#         PRINT 54 SPACES  #p4gl: P34k.4gl, Line 509: parse error
			SKIP 1 line 
			PRINT 11 SPACES, "CHEQUE ATTACHED ",8 SPACES, 
			l_chq_amt USING "---,---,--&.&&" 
			IF p_rec_tentpays.withhold_tax_ind != "0" THEN 
				PRINT 11 SPACES,"TAX AMOUNT ",8 SPACES, 
				l_tax_amt USING "---,---,--&.&&" 
			END IF 
			LET l_bal_amt = l_invoice_total - 
			l_chq_amt - 
			l_tax_amt 
			PRINT 11 SPACES,"BALANCE",22 SPACES, 
			l_bal_amt USING "---,---,--&.&&" 
			LET l_detail_count = 0 
			IF l_statement_finished 
			AND l_chq_amt < 1000000 THEN 
				#           Cannot PRINT millions on B+P stationary
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
				PRINT "\^field HT" 
				PRINT l_hundthous CLIPPED 
				PRINT "\^field TT" 
				PRINT l_tensthous CLIPPED 
				PRINT "\^field TH" 
				PRINT l_thous CLIPPED 
				PRINT "\^field H" 
				PRINT l_hund CLIPPED 
				PRINT "\^field T" 
				PRINT l_tens CLIPPED 
				PRINT "\^field U" 
				PRINT l_xunits CLIPPED 
				PRINT "\^field C" 
				PRINT l_cents USING "&&" 
				PRINT "\^field DATE" 
				PRINT p_cheque_date USING "dd/mm/yy" 
				PRINT "\^field AMOUNT" 
				PRINT l_chq_amt USING "*,***,**&.&&" 
				PRINT "\^field SIGN1" 
				PRINT "\^graph ",l_signature_text1 
				PRINT "\^field SIGN2" 
				PRINT "\^graph ",l_signature_text2 
				PRINT "\^field ADDRESS" 
				PRINT l_vend_ad1 
				PRINT l_vend_ad2 
				PRINT l_vend_ad3 
				PRINT l_vend_ad4 
				PRINT l_vend_ad5 
			ELSE 
				PRINT "\^field HT" 
				PRINT "VOID" 
				PRINT "\^field TT" 
				PRINT "VOID" 
				PRINT "\^field TH" 
				PRINT "VOID" 
				PRINT "\^field H" 
				PRINT "VOID" 
				PRINT "\^field T" 
				PRINT "VOID" 
				PRINT "\^field U" 
				PRINT "VOID" 
				PRINT "\^field C" 
				PRINT "**" 
				PRINT "\^field DATE" 
				PRINT "***VOID***" 
				PRINT "\^field AMOUNT" 
				PRINT "**********" 
				IF l_statement_finished THEN 
					PRINT "\^field ADDRESS" 
					PRINT l_vend_ad1 
					PRINT l_vend_ad2 
					PRINT l_vend_ad3 
					PRINT l_vend_ad4 
					PRINT l_vend_ad5 
				ELSE 
					PRINT "\^field ADDRESS" 
					PRINT "VOID" 
					PRINT "VOID" 
					PRINT "VOID" 
					PRINT "VOID" 
					PRINT "VOID" 
				END IF 
			END IF 
			LET l_page_num = l_page_num + 1 
			UPDATE t_docid 
			SET page_no = l_page_num 
			WHERE doc_id = p_doc_id 

END REPORT 
