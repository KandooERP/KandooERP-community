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
# \file
# \brief module P96  Tax Payment Summary & Reconciliation Reports
#
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/P9_GROUP_GLOBALS.4gl" 
GLOBALS "../ap/P96_GLOBALS.4gl"
###########################################################################
# MODULE Scope Variables
###########################################################################

############################################################
# MODULE SCOPE VARIABLES
############################################################

############################################################
# REPORT P96_rpt_list_paydetail(p_rpt_idx,p_rec_paydetail) 
############################################################
REPORT P96_rpt_list_paydetail(p_rpt_idx,p_rec_paydetail) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_paydetail RECORD 
		payee_vend_code LIKE vendor.vend_code, 
		cheq_date LIKE cheque.cheq_date, 
		tax_per LIKE cheque.tax_per, 
		pay_amt LIKE cheque.pay_amt, 
		net_pay_amt LIKE cheque.net_pay_amt, 
		tax_amt LIKE cheque.net_pay_amt, 
		tax_ind LIKE cheque.withhold_tax_ind 
	END RECORD 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_contractor RECORD LIKE contractor.* 
	DEFINE l_vend_addr1, l_vend_addr2, l_vend_addr3 CHAR(35) 
	DEFINE l_vend_addr4 CHAR(60) 
	DEFINE l_pay_amt_total LIKE vendor.bal_amt 
	DEFINE l_tax_amt_total LIKE vendor.bal_amt
	DEFINE l_max_detail_lines SMALLINT
	DEFINE l_detail_lines_printed SMALLINT
	DEFINE l_payee_page SMALLINT
	DEFINE i SMALLINT

	OUTPUT 
	top OF PAGE "^L" 
	PAGE length 60 
	top margin 0 
	bottom margin 0 
	left margin 0 
	ORDER external BY p_rec_paydetail.payee_vend_code, 
	p_rec_paydetail.cheq_date 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
		
			SELECT * INTO l_rec_vendor.* FROM vendor 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND vend_code = p_rec_paydetail.payee_vend_code 

			LET l_vend_addr1 = l_rec_vendor.addr1_text clipped 
			LET l_vend_addr2 = l_rec_vendor.addr2_text clipped 
			LET l_vend_addr3 = l_rec_vendor.addr3_text clipped 
			LET l_vend_addr4 = l_rec_vendor.city_text 

			IF l_vend_addr4 IS NOT NULL THEN 
				LET l_vend_addr4 = l_vend_addr4 clipped, ", ", 
				l_rec_vendor.state_code clipped 
			ELSE 
				LET l_vend_addr4 = l_rec_vendor.state_code 
			END IF 
			IF l_vend_addr4 IS NOT NULL THEN 
				LET l_vend_addr4 = l_vend_addr4 clipped, ", ", 
				l_rec_vendor.post_code clipped 
			ELSE 
				LET l_vend_addr4 = l_rec_vendor.post_code 
			END IF 

			IF l_vend_addr2 IS NULL THEN 
				LET l_vend_addr2 = l_vend_addr3 
				INITIALIZE l_vend_addr3 TO NULL 
			END IF 

			IF l_vend_addr3 IS NULL THEN 
				LET l_vend_addr3 = l_vend_addr4 
				INITIALIZE l_vend_addr4 TO NULL 
			END IF 

			SELECT * INTO l_rec_contractor.* FROM contractor 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND vend_code = p_rec_paydetail.payee_vend_code 

			PRINT COLUMN 24, "Prescribed Payments System (PPS)" 
			SKIP 1 line 
			PRINT COLUMN 32, "Payment Summary" 
			SKIP 1 line 
			PRINT COLUMN 24, "FOR the year ending ", glob_year_end_date USING "dd mmm yyyy" 
			SKIP 2 LINES 
			PRINT COLUMN 01, "PAYEE DETAILS", 
			COLUMN 37, "PAYER DETAILS" 
			SKIP 1 line 
			PRINT COLUMN 01, "Name", 
			COLUMN 37, "Tax File Number ", glob_rec_parameters.rrn_num 
			PRINT COLUMN 01, glob_uline4 
			PRINT COLUMN 01, l_rec_vendor.name_text 
			SKIP 1 line 
			PRINT COLUMN 01, "Postal Address", 
			COLUMN 37, "Name" 
			PRINT COLUMN 01, glob_uline4, 
			COLUMN 37, glob_uline4 
			PRINT COLUMN 01, l_vend_addr1, 
			COLUMN 37, glob_rec_company.name_text 
			PRINT COLUMN 01, l_vend_addr2 
			PRINT COLUMN 01, l_vend_addr3 
			PRINT COLUMN 01, l_vend_addr4 
			PRINT COLUMN 01, "Tax File Number ", l_rec_contractor.tax_no_text, 
			COLUMN 37, "DECLARATION" 
			PRINT COLUMN 37, "I DECLARE that the information given" 
			PRINT COLUMN 01, "Deduction Exemption OR", 
			COLUMN 37, "on this form IS complete AND correct" 
			PRINT COLUMN 01, "Variation Certificate Number" 
			PRINT COLUMN 01, glob_uline28, 
			COLUMN 37, "Signature............................." 
			PRINT COLUMN 01, l_rec_contractor.variation_text 
			PRINT COLUMN 42, "Date............" 
			SKIP 1 line 
			PRINT COLUMN 01, glob_uline74 
			PRINT COLUMN 01, "|", 
			COLUMN 05, "DATE", 
			COLUMN 12, "|", 
			COLUMN 14, "TAX RATE", 
			COLUMN 23, "|", 
			COLUMN 27, "GROSS AMOUNT OF PAYMENT", 
			COLUMN 50, "|", 
			COLUMN 52, "AMOUNT OF TAX DEDUCTED", 
			COLUMN 74, "|" 
			PRINT COLUMN 01, glob_uline74 
			LET l_max_detail_lines = 27 
			LET l_detail_lines_printed = 0 
			LET l_pay_amt_total = 0 
			LET l_tax_amt_total = 0 

		BEFORE GROUP OF p_rec_paydetail.payee_vend_code 
			LET glob_payee_total = glob_payee_total + 1 
			LET l_payee_page = 0 
			LET l_detail_lines_printed = 0 

		ON EVERY ROW 
			IF l_detail_lines_printed = l_max_detail_lines THEN 
				LET l_payee_page = l_payee_page + 1 
				PRINT COLUMN 01, glob_uline74 
				PRINT COLUMN 01, "|", 
				COLUMN 03, "Page ", l_payee_page USING "###", 
				COLUMN 12, "|", 
				COLUMN 17, "TOTAL", 
				COLUMN 23,"|", 
				COLUMN 32, l_pay_amt_total USING "---,---,---,--&.&&", 
				COLUMN 50, "|"; 
				PRINT COLUMN 56, l_tax_amt_total USING "---,---,---,--&.&&", 
				COLUMN 74,"|" 
				PRINT COLUMN 01, glob_uline74 
			END IF 
			PRINT COLUMN 01, "|", 
			COLUMN 03, p_rec_paydetail.cheq_date USING "dd/mm/yy", 
			COLUMN 12, "|", 
			COLUMN 15, p_rec_paydetail.tax_per USING "---&.&&%", 
			COLUMN 23, "|", 
			COLUMN 32, p_rec_paydetail.pay_amt USING "---,---,---,--&.&&", 
			COLUMN 50, "|"; 
			PRINT COLUMN 56, p_rec_paydetail.tax_amt USING "---,---,---,--&.&&", 
			COLUMN 74, "|" 
			LET l_detail_lines_printed = l_detail_lines_printed + 1 
			LET l_pay_amt_total = l_pay_amt_total + p_rec_paydetail.pay_amt 
			LET l_tax_amt_total = l_tax_amt_total + p_rec_paydetail.tax_amt 

		AFTER GROUP OF p_rec_paydetail.payee_vend_code 
			FOR i = 1 TO (l_max_detail_lines - l_detail_lines_printed) 
				PRINT COLUMN 01, "|", 
				COLUMN 12, "|", 
				COLUMN 23, "|", 
				COLUMN 50, "|", 
				COLUMN 74, "|" 
			END FOR 
			LET l_payee_page = l_payee_page + 1 
			PRINT COLUMN 01, glob_uline74 
			PRINT COLUMN 01, "|", 
			COLUMN 03, "Page ", l_payee_page USING "###", 
			COLUMN 12, "|", 
			COLUMN 17, "TOTAL", 
			COLUMN 23,"|", 
			COLUMN 32, l_pay_amt_total USING "---,---,---,--&.&&", 
			COLUMN 50, "|"; 
			PRINT COLUMN 56, l_tax_amt_total USING "---,---,---,--&.&&", 
			COLUMN 74,"|" 
			PRINT COLUMN 01, glob_uline74 

		ON LAST ROW 
			LET glob_payee_amt_total = sum(p_rec_paydetail.pay_amt) 
			LET glob_payee_tax_total = sum(p_rec_paydetail.tax_amt) 

			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	
			
			
END REPORT 