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
{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module PC9b.4gl - EFT file extract REPORT FOR BANK Acceptance
#

############################################################
# GLOBAL SCOPE
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_GLOBALS.4gl"
GLOBALS "../common/glob_GLOBALS_report.4gl"  

########################################################################
# EFT File Format 1 - National Australia Bank
########################################################################
REPORT pc9f1_list(p_rpt_idx,p_rec_cheque,p_mods_flag) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_cheque RECORD LIKE cheque.* 
	DEFINE p_mods_flag CHAR(1) 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_company RECORD LIKE company.* 
	DEFINE l_rec_bank RECORD LIKE bank.* 
	DEFINE l_rec_vouchpayee RECORD LIKE vouchpayee.* 
	DEFINE l_accum_amt LIKE cheque.net_pay_amt 
	DEFINE l_acct_num CHAR(9) 
	DEFINE l_justified_bank CHAR(9)
	DEFINE l_justified_vend CHAR(9)
	DEFINE l_rpt_wid SMALLINT 
	DEFINE l_ind CHAR(1) 
	DEFINE l_cnt INTEGER 
	DEFINE x,y SMALLINT

	ORDER external BY p_rec_cheque.eft_run_num,p_rec_cheque.bank_code,p_rec_cheque.vend_code,p_rec_cheque.cheq_code 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,PAGENO) #update page number and report header line 1

		BEFORE GROUP OF p_rec_cheque.eft_run_num 
			LET l_rpt_wid = 120 
			LET l_accum_amt = 0 
			SELECT * INTO l_rec_company.* FROM company 
			WHERE cmpy_code = p_rec_cheque.cmpy_code 
			SELECT * INTO l_rec_bank.* FROM bank 
			WHERE cmpy_code = p_rec_cheque.cmpy_code 
			AND bank_code = p_rec_cheque.bank_code 
			PRINT COLUMN 01, "0", 
			COLUMN 19, "01", 
			COLUMN 21, l_rec_bank.type_code[1,3], 
			COLUMN 31, l_rec_bank.name_acct_text[1,26], 
			COLUMN 57, l_rec_bank.user_text, 
			COLUMN 63, "PAYMENTS ", 
			COLUMN 75, p_rec_cheque.cheq_date USING "ddmmyy", 
			COLUMN 81, " ", 
			COLUMN 82, " ", 
			#          "          1        2         3         "
			#          "123456789012345678901234567890123456789"
			COLUMN 121, ascii(13) #c/r 
			#COLUMN 122 Line feed    #Automatically get one in a REPORT
		ON EVERY ROW 
			SELECT * INTO l_rec_vendor.* FROM vendor 
			WHERE cmpy_code = p_rec_cheque.cmpy_code 
			AND vend_code = p_rec_cheque.vend_code 
			IF p_rec_cheque.source_ind = "S" THEN ## sundry voucher 
				SELECT * INTO l_rec_vouchpayee.* FROM vouchpayee 
				WHERE vend_code = p_rec_cheque.vend_code 
				AND vouch_code = p_rec_cheque.source_text 
				AND cmpy_code = p_rec_cheque.cmpy_code 
				LET l_rec_vendor.bank_acct_code = l_rec_vouchpayee.bank_acct_code 
				LET l_rec_vendor.name_text = l_rec_vouchpayee.name_text 
			END IF 
			LET l_accum_amt = l_accum_amt + (p_rec_cheque.net_pay_amt * 100) 
			###### RIGHT JUSTIFY VENDOR ACCOUNT ##########
			LET l_acct_num = l_rec_vendor.bank_acct_code[8,20] 
			LET l_justified_vend = NULL 
			LET y = 9 
			FOR x = 9 TO 1 step -1 
				IF l_acct_num[x] IS NULL 
				OR l_acct_num[x] = " " THEN 
					CONTINUE FOR 
				END IF 
				LET l_justified_vend[y] = l_acct_num[x] 
				LET y = y - 1 
			END FOR 
			###### RIGHT JUSTIFY BANK ACCOUNT ##########
			LET l_acct_num = l_rec_bank.iban[1,9] 
			LET l_justified_bank = NULL 
			LET y = 9 
			FOR x = 9 TO 1 step -1 
				IF l_acct_num[x] IS NULL 
				OR l_acct_num[x] = " " THEN 
					CONTINUE FOR 
				END IF 
				LET l_justified_bank[y] = l_acct_num[x] 
				LET y = y - 1 
			END FOR 
			LET l_ind = " " 
			IF p_mods_flag = "Y" THEN 
				LET l_ind = "N" # 'N' = new OR modified acct 
			END IF 
			LET l_rec_vendor.name_text = upshift(l_rec_vendor.name_text) 
			FOR x = 1 TO length(l_rec_vendor.name_text) 
				#       Valid character SET IS ONLY (- TO 9, A TO Z AND & AND *)
				IF l_rec_vendor.name_text[x] NOT matches "[--9A-Z&*]" THEN 
					LET l_rec_vendor.name_text[x] = " " 
				END IF 
			END FOR 
			PRINT COLUMN 01, "1", 
			COLUMN 02, l_rec_vendor.bank_acct_code[1,3],"-", 
			l_rec_vendor.bank_acct_code[4,6], 
			COLUMN 09, l_justified_vend, 
			COLUMN 18, l_ind, 
			COLUMN 19, "50", 
			COLUMN 21, p_rec_cheque.net_pay_amt *100 USING "&&&&&&&&&&", 
			COLUMN 31, l_rec_vendor.name_text, 
			COLUMN 63, p_rec_cheque.cheq_code USING "<<<<<<<<<", 
			COLUMN 81, l_rec_bank.bic_code[1,3],"-", 
			l_rec_bank.bic_code[4,6], 
			COLUMN 88, l_justified_bank, 
			COLUMN 97, l_rec_bank.remit_text[1,16], 
			COLUMN 113, "00000000", 
			COLUMN 121, ascii(13) #c/r 
			#COLUMN 122 Line feed    #Automatically get one in a REPORT
		AFTER GROUP OF p_rec_cheque.eft_run_num 
			###### RIGHT JUSTIFY BANK ACCOUNT ##########
			LET l_acct_num = l_rec_bank.iban 
			LET l_justified_bank = NULL 
			LET y = 9 
			FOR x = 9 TO 1 step -1 
				IF l_acct_num[x] IS NULL 
				OR l_acct_num[x] = " " THEN 
					CONTINUE FOR 
				END IF 
				LET l_justified_bank[y] = l_acct_num[x] 
				LET y = y - 1 
			END FOR 
			PRINT COLUMN 01, "1", 
			COLUMN 02, l_rec_bank.bic_code[1,3],"-", 
			l_rec_bank.bic_code[4,6], 
			COLUMN 09, l_justified_bank, 
			COLUMN 18, " ", 
			COLUMN 19, "13", 
			COLUMN 21, GROUP sum(p_rec_cheque.net_pay_amt)*100 USING "&&&&&&&&&&", 
			COLUMN 31, l_rec_bank.name_acct_text, 
			COLUMN 81, l_rec_bank.bic_code[1,3],"-", 
			l_rec_bank.bic_code[4,6], 
			COLUMN 88, l_justified_bank, 
			COLUMN 97, l_rec_bank.remit_text[1,16], 
			COLUMN 113, "00000000", 
			COLUMN 121, ascii(13) #c/r 
			#COLUMN 122 Line feed    #Automatically get one in a REPORT
		ON LAST ROW 
			LET l_accum_amt = l_accum_amt - (sum(p_rec_cheque.net_pay_amt * 100)) 
			LET l_cnt = count(*) + 1 
			PRINT COLUMN 01, "7", 
			COLUMN 02, "999-999", 
			COLUMN 21, l_accum_amt USING "&&&&&&&&&&", 
			COLUMN 31, sum(p_rec_cheque.net_pay_amt)*100 USING "&&&&&&&&&&", 
			COLUMN 41, sum(p_rec_cheque.net_pay_amt)*100 USING "&&&&&&&&&&", 
			COLUMN 75, l_cnt USING "&&&&&&", 
			COLUMN 81, " ", 
			#          "          1        2         3         4"
			#          "1234567890123456789012345678901234567890"
			COLUMN 121, ascii(13) #c/r 
			#COLUMN 122 Line feed    #Automatically get one in a REPORT
END REPORT 

########################################################################
# EFT File Format 2 - ANZ
########################################################################
REPORT pc9f2_list(p_rpt_idx,p_rec_cheque) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_cheque RECORD LIKE cheque.* 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_vouchpayee RECORD LIKE vouchpayee.* 

	ORDER external BY p_rec_cheque.eft_run_num,p_rec_cheque.bank_code,p_rec_cheque.vend_code,p_rec_cheque.cheq_code 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,PAGENO) #update page number and report header line 1

		ON EVERY ROW 
			SELECT * INTO l_rec_vendor.* FROM vendor 
			WHERE cmpy_code = p_rec_cheque.cmpy_code 
			AND vend_code = p_rec_cheque.vend_code 
			IF p_rec_cheque.source_ind = "S" THEN ## sundry voucher 
				SELECT * INTO l_rec_vouchpayee.* FROM vouchpayee 
				WHERE vend_code = p_rec_cheque.vend_code 
				AND vouch_code = p_rec_cheque.source_text 
				AND cmpy_code = p_rec_cheque.cmpy_code 
				LET l_rec_vendor.bank_acct_code = l_rec_vouchpayee.bank_acct_code 
				LET l_rec_vendor.name_text = l_rec_vouchpayee.name_text 
			END IF 
			PRINT "\"",p_rec_cheque.cheq_code using "<<<<<<<<<","\"","\,", 
			"\"",l_rec_vendor.name_text clipped,"\"","\,", 
			"\"",l_rec_vendor.bank_acct_code[1,3],"-",l_rec_vendor.bank_acct_code[4,6],"\"","\,", 
			"\"",l_rec_vendor.bank_acct_code[8,16],"\"","\,", 
			p_rec_cheque.net_pay_amt USING "<<<<<<<&.&&","\,", 
			"\"",l_rec_vendor.vend_code clipped,"\"" 

END REPORT 


########################################################################
# EFT File Format 3 -  Reserved FOR future use
########################################################################
#REPORT PC9f3_list(l_rec_cheque)
#   DEFINE
#      l_rec_cheque RECORD LIKE cheque.*,
#      l_rpt_wid SMALLINT
#
#   OUTPUT
#      left margin 0
#
#END REPORT


###########################################################################
# This REPORT need only be run once (see FILE CLEANSING PROCEDURES)...
# but may be setup TO run FOR each EFT payment cycle
# Control = bank.eft_rpt_ind (<0> Never Print, <1> Print Once, <2> Always)
###########################################################################
REPORT pc9z_list(p_rpt_idx,p_bic_code,p_rec_cheque,p_rpt_note) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_bic_code LIKE bic.bic_code 
	DEFINE p_rec_cheque RECORD LIKE cheque.* 
	DEFINE p_rpt_note CHAR(80) 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_company RECORD LIKE company.* 
	DEFINE l_rec_bic RECORD LIKE bic.* 
	DEFINE l_line1 CHAR(132) #, l_line2 
	DEFINE l_offset1, l_offset2 SMALLINT 
	DEFINE l_acct_num, l_justified_vend CHAR(11) 
	DEFINE l_rpt_wid SMALLINT 
	DEFINE x,y SMALLINT

	ORDER external BY p_bic_code,p_rec_cheque.vend_code 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,PAGENO) #update page number and report header line 1
			LET l_rpt_wid = 80 
			SELECT * INTO l_rec_company.* FROM company 
			WHERE cmpy_code = p_rec_cheque.cmpy_code 
			LET l_line1 = l_rec_company.cmpy_code, " ", l_rec_company.name_text clipped 
			LET l_offset1 = (l_rpt_wid/2) - (length (l_line1) / 2) + 1 
			LET l_offset2 = (l_rpt_wid/2) - (length (p_rpt_note) / 2) + 1 
			PRINT COLUMN 01, today USING "DD MMM YYYY", 
			COLUMN l_offset1, l_line1 clipped, 
			COLUMN (l_rpt_wid -10), "Page :", 
			COLUMN (l_rpt_wid - 3), pageno USING "##&" 
			PRINT COLUMN 01, time, 
			COLUMN l_offset2, p_rpt_note 
			PRINT COLUMN 1,"----------------------------------------", 
			"----------------------------------------" 
			PRINT COLUMN 01, "BIC No", 
			COLUMN 09, "Branch Name", 
			COLUMN 40, "Account Name", 
			COLUMN 70, "Account No" 
			PRINT COLUMN 1,"----------------------------------------", 
			"----------------------------------------" 
		BEFORE GROUP OF p_bic_code 
			SKIP TO top OF PAGE 
		ON EVERY ROW 
			SELECT * INTO l_rec_vendor.* FROM vendor 
			WHERE cmpy_code = p_rec_cheque.cmpy_code 
			AND vend_code = p_rec_cheque.vend_code 
			###### RIGHT JUSTIFY VENDOR ACCOUNT ##########
			LET l_acct_num = l_rec_vendor.bank_acct_code[8,20] 
			LET l_justified_vend = NULL 
			LET y = 11 
			FOR x = 11 TO 1 step -1 
				IF l_acct_num[x] IS NULL 
				OR l_acct_num[x] = " " THEN 
					CONTINUE FOR 
				END IF 
				LET l_justified_vend[y] = l_acct_num[x] 
				LET y = y - 1 
			END FOR 
			SELECT * INTO l_rec_bic.* FROM bic 
			WHERE bic_code = p_bic_code 
			LET l_rec_vendor.name_text = upshift(l_rec_vendor.name_text) 
			FOR x = 1 TO length(l_rec_vendor.name_text) 
				#       Valid character SET IS ONLY (- TO 9, A TO Z AND & AND *)
				IF l_rec_vendor.name_text[x] NOT matches "[--9A-Z&*]" THEN 
					LET l_rec_vendor.name_text[x] = " " 
				END IF 
			END FOR 
			PRINT COLUMN 01, l_rec_vendor.bank_acct_code[1,3],"-", 
			l_rec_vendor.bank_acct_code[4,6], 
			COLUMN 09, l_rec_bic.desc_text, 
			COLUMN 40, l_rec_vendor.name_text[1,29], 
			COLUMN 70, l_justified_vend 

		ON LAST ROW 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text CLIPPED WORDWRAP RIGHT MARGIN 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report 			
			LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = PAGENO

END REPORT 


