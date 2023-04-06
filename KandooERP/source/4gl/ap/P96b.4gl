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
# \brief module P96  Tax Payment Summary & Reconciliation Reports

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
# REPORT P96_rpt_list_paydetail(p_rpt_idx,pr_paydetail)
#
#
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
	DEFINE l_company_addr1, l_company_addr2 CHAR(35) 
	DEFINE l_company_addr3 CHAR(60) 
	DEFINE l_pay_amt_total LIKE vendor.bal_amt 
	DEFINE l_tax_amt_total LIKE vendor.bal_amt
	DEFINE l_net_amt_total LIKE vendor.bal_amt
	DEFINE l_max_detail_lines SMALLINT
	DEFINE l_detail_lines_printed SMALLINT
	DEFINE l_payee_page SMALLINT	
	DEFINE l_first_page SMALLINT
	DEFINE l_line_cnt SMALLINT
	DEFINE i SMALLINT

	OUTPUT 
	left margin 0 
	top margin 0 
	bottom margin 0 
--	PAGE length 1 
	ORDER external BY p_rec_paydetail.payee_vend_code, 
	p_rec_paydetail.cheq_date 

	FORMAT 
		FIRST PAGE HEADER 
			LET l_first_page = 0
			
		PAGE HEADER
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 			
			 
		BEFORE GROUP OF p_rec_paydetail.payee_vend_code 
			IF l_first_page = 0 THEN 
				PRINT "\^job PPS -z",rpt_get_dest_printer()
--				PRINT "\^job PPS -z",glob_arr_rec_rpt_rmsreps[p_rpt_idx].dest_print_text  
				LET l_first_page = l_first_page + 1 
			END IF 
			LET glob_payee_total = glob_payee_total + 1 
			LET l_payee_page = 0 
			LET l_detail_lines_printed = 0 
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
			
			## Payer address details
			LET l_company_addr1 = glob_rec_company.addr1_text clipped 
			LET l_company_addr2 = glob_rec_company.addr2_text clipped 
			LET l_company_addr3 = glob_rec_company.city_text 
			IF l_company_addr3 IS NOT NULL THEN 
				LET l_company_addr3 = l_company_addr3 clipped, ", ", 
				glob_rec_company.state_code clipped 
			ELSE 
				LET l_company_addr3 = glob_rec_company.state_code 
			END IF 
			IF l_company_addr3 IS NOT NULL THEN 
				LET l_company_addr3 = l_company_addr3 clipped, ", ", 
				glob_rec_company.post_code clipped 
			ELSE 
				LET l_company_addr3 = glob_rec_company.post_code 
			END IF 
			IF l_company_addr1 IS NULL THEN 
				LET l_company_addr1 = l_company_addr2 
				INITIALIZE l_company_addr2 TO NULL 
			END IF 
			IF l_company_addr2 IS NULL THEN 
				LET l_company_addr2 = l_company_addr3 
				INITIALIZE l_company_addr3 TO NULL 
			END IF 
			SELECT * INTO l_rec_contractor.* FROM contractor 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND vend_code = p_rec_paydetail.payee_vend_code 
			LET l_line_cnt = 0 
			PRINT "\^form PPS.MDF" 
			PRINT "\^field EDATE" 
			PRINT glob_year_end_date USING "dd mmm yyyy" 
			PRINT "\^field NAME" 
			PRINT l_rec_vendor.name_text 
			PRINT "\^field ADDRESS" 
			PRINT l_vend_addr1 
			PRINT l_vend_addr2 
			PRINT l_vend_addr3 
			PRINT l_vend_addr4 
			PRINT "\^field TFN" 
			PRINT l_rec_contractor.tax_no_text 
			PRINT "\^field VCN" 
			PRINT l_rec_contractor.variation_text 
			PRINT "\^field NAMEP" 
			PRINT glob_rec_company.name_text 
			PRINT "\^field ADDRESSP" 
			PRINT l_company_addr1 
			PRINT l_company_addr2 
			PRINT l_company_addr3 
			PRINT "\^field TFNP" 
			PRINT glob_rec_parameters.rrn_num 
			PRINT "\^record PPS" 
			PRINT "\^continue DATE 10 01" 
			PRINT "\^continue TAXR 13 11" 
			PRINT "\^continue GROSS 25 24" 
			PRINT "\^continue TAXD 19 49" 
			PRINT "\^continue NET 22 68" 
			LET l_max_detail_lines = 32 
			LET l_pay_amt_total = 0 
			LET l_tax_amt_total = 0 
			LET l_net_amt_total = 0 

		ON EVERY ROW 
			LET l_line_cnt = l_line_cnt + 1 
			IF l_line_cnt > l_max_detail_lines THEN 
				LET l_line_cnt = 1 
				LET l_max_detail_lines = 33 
				PRINT "\^form PPS1.MDF" 
				PRINT "\^field EDATE" 
				PRINT glob_year_end_date USING "dd mmm yyyy" 
				PRINT "\^field NAME" 
				PRINT l_rec_vendor.name_text 
				PRINT "\^field ADDRESS" 
				PRINT l_vend_addr1 
				PRINT l_vend_addr2 
				PRINT l_vend_addr3 
				PRINT l_vend_addr4 
				PRINT "\^record PPS" 
				PRINT "\^continue DATE 10 01" 
				PRINT "\^continue TAXR 13 11" 
				PRINT "\^continue GROSS 25 24" 
				PRINT "\^continue TAXD 19 49" 
				PRINT "\^continue NET 22 68" 
			END IF 
			PRINT p_rec_paydetail.cheq_date USING "dd/mm/yyyy",5 spaces, 
			p_rec_paydetail.tax_per USING "---&.&&%",7 spaces, 
			p_rec_paydetail.pay_amt USING "---,---,---,--&.&&",1 spaces, 
			p_rec_paydetail.tax_amt USING "---,---,---,--&.&&",4 spaces, 
			p_rec_paydetail.net_pay_amt USING "---,---,---,--&.&&" 
			LET l_pay_amt_total = l_pay_amt_total + p_rec_paydetail.pay_amt 
			LET l_tax_amt_total = l_tax_amt_total + p_rec_paydetail.tax_amt 
			LET l_net_amt_total = l_net_amt_total + p_rec_paydetail.net_pay_amt 

		AFTER GROUP OF p_rec_paydetail.payee_vend_code 
			LET l_payee_page = l_payee_page + 1 
			PRINT "\^field TOTAL" 
			PRINT "TOTAL" 
			PRINT "\^field TOTALG" 
			PRINT l_pay_amt_total USING "---,---,---,--&.&&" 
			PRINT "\^field TOTAL TD" 
			PRINT l_tax_amt_total USING "---,---,---,--&.&&" 
			PRINT "\^field TOTALN" 
			PRINT l_net_amt_total USING "---,---,---,--&.&&" 
			PRINT "\^field SIGN" 
			PRINT "SIGNATURE:" 
			PRINT "\^field SIGNATURE" 
			PRINT "\^graph ",glob_signature_file 
			PRINT "\^field DATET" 
			PRINT "DATE:" 
			PRINT "\^field TDATE" 
			PRINT glob_arr_rec_rpt_rmsreps[p_rpt_idx].ref1_date USING "dd/mm/yyyy" 

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