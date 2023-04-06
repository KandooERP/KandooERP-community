#TODO : should be replaced by 4gl/ap/PC9a_rpt.4gl

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
	Source code beautified by beautify.pl on 2020-01-03 13:41:41	$Id: $
}
############################################################
# GLOBAL SCOPE
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS 

END GLOBALS 

############################################################
# REPORT PC9a_list(p_rec_cheque, p_rec_vendor, p_rpt_note)
#
# \brief module PC9a - EFT Payments Report - List of EFT Payments FOR xref
#                This FUNCTION IS called FROM P34 AND PC9
############################################################
REPORT pc9a_list(p_rpt_idx,p_rec_cheque,p_rec_vendor,p_rpt_note) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_cheque RECORD LIKE cheque.* 
	DEFINE p_rec_vendor RECORD LIKE vendor.* 
	DEFINE p_rpt_note CHAR(80) 
	DEFINE l_rec_company RECORD LIKE company.* 
	DEFINE l_rec_bank RECORD LIKE bank.* 
	DEFINE l_line1, l_line2 CHAR(132) 
	DEFINE l_offset1, l_offset2 SMALLINT 
	#DEFINE l_rpt_date date
	DEFINE l_rpt_wid,l_len SMALLINT 

	ORDER BY p_rec_cheque.eft_run_num, 
	p_rec_cheque.bank_code, 
	p_rec_vendor.name_text, 
	p_rec_cheque.cheq_code 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,PAGENO) #update page number and report header line 1
			LET l_rpt_wid = 132 
			SELECT * INTO l_rec_company.* FROM company 
			WHERE cmpy_code = p_rec_cheque.cmpy_code 
			LET l_line1 = l_rec_company.cmpy_code, " ", l_rec_company.name_text clipped 
			LET l_offset1 = (l_rpt_wid/2) - (length (l_line1) / 2) + 1 
			LET l_offset2 = (l_rpt_wid/2) - (length (p_rpt_note) / 2) + 1 
			PRINT COLUMN 01, today USING "DD MMM YYYY", 
			COLUMN l_offset1, l_line1 clipped, 
			COLUMN (l_rpt_wid -10), "Page :", 
			COLUMN (l_rpt_wid - 3), pageno USING "###&" 
			PRINT COLUMN 01, time, 
			COLUMN l_offset2, p_rpt_note 
			PRINT COLUMN 1,"---------------------------------------------", 
			"---------------------------------------------", 
			"---------------------------------------------" 
			PRINT COLUMN 01, "Reference", 
			COLUMN 11, "BIC", 
			COLUMN 19, "Vendor", 
			COLUMN 34, "Vendor", 
			COLUMN 42, "Vendor", 
			COLUMN 68, "Our", 
			COLUMN 99, "Base", 
			COLUMN 112,"Amount", 
			COLUMN 133,"Net" 
			PRINT COLUMN 01, " Number", 
			COLUMN 11, "Number", 
			COLUMN 19, "Account", 
			COLUMN 34, "Code", 
			COLUMN 42, "Name", 
			COLUMN 68, "Account", 
			COLUMN 97, "Amount", 
			COLUMN 111,"Applied", 
			COLUMN 130,"Amount" 
			PRINT COLUMN 1,"---------------------------------------------", 
			"---------------------------------------------", 
			"---------------------------------------------" 
		BEFORE GROUP OF p_rec_cheque.eft_run_num 
			SKIP TO top OF PAGE 
			PRINT COLUMN 01, "EFT Run Number: ", 
			COLUMN 17, p_rec_cheque.eft_run_num USING "<<<<<" 
			PRINT COLUMN 05,"Date: ", p_rec_cheque.cheq_date USING "dd/mm/yy" 
		BEFORE GROUP OF p_rec_cheque.bank_code 
			SELECT * INTO l_rec_bank.* FROM bank 
			WHERE cmpy_code = p_rec_cheque.cmpy_code 
			AND bank_code = p_rec_cheque.bank_code 
			SKIP 1 line 
			PRINT COLUMN 05,"Bank: ", l_rec_bank.bank_code clipped, " ", 
			l_rec_bank.name_acct_text clipped, " (", 
			l_rec_bank.currency_code clipped,")" 
			PRINT COLUMN 05,"BIC : ", l_rec_bank.bic_code[1,3], "-", 
			l_rec_bank.bic_code[4,6] 
			SKIP 1 line 
		ON EVERY ROW 
			LET l_len = length(p_rec_vendor.bank_acct_code) 
			PRINT COLUMN 01, p_rec_cheque.cheq_code USING "########&"; 
			IF l_len > 6 THEN 
				PRINT COLUMN 11, p_rec_vendor.bank_acct_code[1,6]; 
				IF l_len > 10 THEN 
					PRINT COLUMN 19, p_rec_vendor.bank_acct_code[8,l_len-2] clipped, 
					"-", 
					p_rec_vendor.bank_acct_code[l_len-1,l_len]; 
				END IF 
			ELSE 
				IF l_len >= 1 THEN 
					PRINT COLUMN 11, p_rec_vendor.bank_acct_code[1,l_len]; 
				END IF 
			END IF 
			PRINT COLUMN 34, p_rec_vendor.vend_code, 
			COLUMN 42, p_rec_vendor.name_text[1,27], 
			COLUMN 69, p_rec_vendor.our_acct_code, 
			COLUMN 89, p_rec_cheque.pay_amt USING "---,---,--&.&&", 
			COLUMN 106, p_rec_cheque.apply_amt USING "---,---,--&.&&", 
			COLUMN 122, p_rec_cheque.net_pay_amt USING "---,---,--&.&&" 
		AFTER GROUP OF p_rec_cheque.eft_run_num 
			NEED 6 LINES 
			SKIP 1 line 
			PRINT COLUMN 23, "Run Number Total: ", 
			COLUMN 89, GROUP sum(p_rec_cheque.pay_amt) USING "----,---,--&.&&", 
			COLUMN 105,group sum(p_rec_cheque.apply_amt) USING "----,---,--&.&&", 
			COLUMN 121,group sum(p_rec_cheque.net_pay_amt) USING "----,---,--&.&&" 
			SKIP 3 line 

		ON LAST ROW 
			NEED 5 LINES 
			PRINT COLUMN 17, "EFT Payments Total: ", count(*) USING "####", 
			COLUMN 89, sum(p_rec_cheque.pay_amt) USING "----,---,--&.&&", 
			COLUMN 105,sum(p_rec_cheque.apply_amt) USING "----,---,--&.&&", 
			COLUMN 121,sum(p_rec_cheque.net_pay_amt) USING "----,---,--&.&&" 
			SKIP 2 LINES 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text CLIPPED WORDWRAP RIGHT MARGIN 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report 			
			LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = PAGENO

END REPORT 


