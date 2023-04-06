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
# \brief module P34a Cheque Print
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_P3_GLOBALS.4gl" 
GLOBALS "../ap/P34_GLOBALS.4gl" 

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
	DEFINE l_print_count INTEGER
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_amt_line_count SMALLINT 
	DEFINE l_line_count SMALLINT
	DEFINE l_chq_amt DECIMAL(11,2) 
	DEFINE l_payment_total LIKE cheque.net_pay_amt 
	DEFINE l_cheque_amt LIKE cheque.net_pay_amt
	DEFINE l_tax_amt LIKE cheque.net_pay_amt
	DEFINE l_ps_pageno INTEGER 
	DEFINE l_group_count INTEGER 
	DEFINE l_amt_text CHAR(200) 
	DEFINE l_line_1_offset, l_line_2_offset, l_line_3_offset SMALLINT 
	DEFINE l_line_1_text, l_line_2_text, l_line_3_text CHAR(80) 
	DEFINE l_disc_amt_total LIKE tentpays.taken_disc_amt 

	ORDER BY p_doc_id, 
	p_rec_tentpays.vend_code, 
	p_rec_tentpays.withhold_tax_ind, 
	p_source_ind, 
	p_source_text, 
	p_rec_tentpays.vouch_code 

	FORMAT 
		FIRST PAGE HEADER 
			## l_print_count use TO count the actual printed number of cheques
			LET l_print_count = 0 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,PAGENO) #update page number and report header line 1
			## l_group_count use TO split the cheques so that two cheques can be printed on each page
			LET l_group_count = 0 

		BEFORE GROUP OF p_doc_id 
			IF p_source_ind = "8" THEN 
				SELECT * INTO l_rec_customer.* FROM customer 
				WHERE cust_code = p_source_text 
				AND cmpy_code = p_rec_tentpays.cmpy_code 
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
			LET l_group_count = l_group_count + 1 
			IF l_group_count > 2 THEN 
				LET l_group_count = 0 
				SKIP TO top OF PAGE 
			END IF 
			{skip 6 lines TO first line of remittance section.}
		AFTER GROUP OF p_doc_id 
			      {IF we have printed 3 lines, l_line_count = 3 AND we are positioned on
			       line 4. There are 13 lines in the remittance section, so IF we
			       subtract FROM 13 the number of lines already printed, we will get the
			       number of lines left in the remittance advice section.
			       There are 11 lines FROM AFTER the last line of the remittance section
			       TO line 1 of the cheque.
			      }
			LET l_print_count = l_print_count + 1 
			PRINT PRINT PRINT PRINT PRINT PRINT 
			PRINT COLUMN 118, p_chq_prt_date USING "dd mm yyyy" 
			PRINT PRINT PRINT PRINT PRINT 
			LET l_payment_total = GROUP sum(p_rec_tentpays.vouch_amt) 
			LET l_disc_amt_total = GROUP sum (p_rec_tentpays.taken_disc_amt) 
			LET l_cheque_amt = l_payment_total - l_disc_amt_total 

			LET l_tax_amt = 0 
			IF p_rec_tentpays.withhold_tax_ind != "0" THEN 
				CALL wtaxcalc(l_cheque_amt, 
				p_rec_tentpays.tax_per, 
				p_rec_tentpays.withhold_tax_ind, 
				p_rec_tentpays.cmpy_code) 
				RETURNING l_cheque_amt, 
				l_tax_amt 
			END IF 
			IF l_tax_amt != 0 THEN 
				LET l_cheque_amt = l_cheque_amt - l_tax_amt 
			END IF 
			PRINT COLUMN 60, l_rec_vendor.name_text clipped 
			PRINT PRINT PRINT PRINT 
			PRINT COLUMN 114, l_cheque_amt USING "*********#.##" 
			LET l_chq_amt = l_cheque_amt USING "##########.##" 
			LET l_amt_text = l_chq_amt USING "##########.##" 

			CALL numto(l_amt_text, 50) 
			RETURNING l_amt_line_count, 
			l_line_1_offset, l_line_1_text, 
			l_line_2_offset, l_line_2_text, 
			l_line_3_offset, l_line_3_text 

			PRINT 
			PRINT COLUMN 60, l_line_1_text 
			PRINT 
			IF l_amt_line_count > 1 THEN 
				PRINT COLUMN 60, l_line_2_text 
			ELSE 
				PRINT 
			END IF 
			IF l_amt_line_count > 2 THEN 
				PRINT COLUMN 50, l_line_3_text 
			ELSE 
				PRINT 
			END IF 
			PRINT PRINT PRINT PRINT PRINT 
			PRINT PRINT PRINT PRINT 
			#
			# page no.'s are always a multiple of 48
			#
			LET l_ps_pageno = pageno / 48 
			UPDATE t_docid 
			SET page_no = l_print_count 
			WHERE doc_id = p_doc_id 

		ON LAST ROW 
			LET l_print_count = 0 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text CLIPPED WORDWRAP RIGHT MARGIN 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report 			
			LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = PAGENO

END REPORT 
