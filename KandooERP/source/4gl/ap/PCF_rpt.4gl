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
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/PC_GROUP_GLOBALS.4gl"

############################################################
# REPORT PCF_rpt_list(p_rpt_idx,p_rec_cheque)
#
# PCF - Report Definition/Layout
############################################################
REPORT PCF_rpt_list(p_rpt_idx, p_rec_cheque) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_cheque RECORD LIKE cheque.* 
	DEFINE l_rec_voucherpays RECORD LIKE voucherpays.* 
	DEFINE l_rec_voucher RECORD LIKE voucher.* 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_vend_ad1, l_vend_ad2, l_vend_ad3, l_vend_ad4, l_vend_ad5 CHAR(40) 
	DEFINE l_page_num INTEGER 
	DEFINE l_pay_text CHAR(5) 

	OUTPUT 
		ORDER EXTERNAL BY p_rec_cheque.bank_code, 
			p_rec_cheque.pay_meth_ind, 
			p_rec_cheque.cheq_code 
	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno)  #update page number
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]
		
--			PRINT COLUMN 14,"***** R E M I T T A N C E A D V I C E *****" 
--			SKIP 2 LINES 
			SELECT * INTO l_rec_vendor.* FROM vendor 
			WHERE cmpy_code = p_rec_cheque.cmpy_code 
			AND vend_code = p_rec_cheque.vend_code 
			LET l_vend_ad1 = l_rec_vendor.name_text clipped 
			LET l_vend_ad2 = l_rec_vendor.addr1_text clipped 
			LET l_vend_ad3 = l_rec_vendor.addr2_text clipped 
			LET l_vend_ad4 = l_rec_vendor.addr3_text clipped 
			LET l_vend_ad5 = l_rec_vendor.city_text 
			IF l_vend_ad5 IS NULL THEN 
				LET l_vend_ad5 = l_rec_vendor.state_code 
			ELSE 
				IF l_rec_vendor.state_code IS NOT NULL THEN 
					LET l_vend_ad5 = l_vend_ad5 clipped, ", ", 
					l_rec_vendor.state_code clipped 
				END IF 
			END IF 
			IF l_vend_ad5 IS NULL THEN 
				LET l_vend_ad5 = l_rec_vendor.post_code 
			ELSE 
				IF l_rec_vendor.post_code IS NOT NULL THEN 
					LET l_vend_ad5 = l_vend_ad5 clipped, ", ", 
					l_rec_vendor.post_code clipped 
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
			LET l_pay_text = NULL 
			IF p_rec_cheque.pay_meth_ind = "3" THEN 
				LET l_pay_text = "(EFT)" 
			END IF 
			PRINT COLUMN 08, l_vend_ad1, 
			COLUMN 53, "Cheque:", 
			COLUMN 63, p_rec_cheque.cheq_code USING "########&", 
			COLUMN 73, l_pay_text 
			PRINT COLUMN 08, l_vend_ad2, 
			COLUMN 53, "Account:", 
			COLUMN 62, p_rec_cheque.vend_code 
			PRINT COLUMN 08, l_vend_ad3, 
			COLUMN 53, "Date:", 
			COLUMN 62, today USING "dd/mm/yyyy" 
			LET l_page_num = l_page_num + 1 
			PRINT COLUMN 08, l_vend_ad4, 
			COLUMN 53, "Page:", 
			COLUMN 62, l_page_num USING "<<<" 
			PRINT COLUMN 08, l_vend_ad5 
			SKIP 1 LINES 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			PRINT COLUMN 12, "DATE YOUR REFERENCE", 
			COLUMN 42, "OUR REF TOTAL" 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

		BEFORE GROUP OF p_rec_cheque.cheq_code 
			LET l_page_num = 0 
			SKIP TO top OF PAGE 

		ON EVERY ROW 
			DECLARE c_voucherpays CURSOR FOR 
			SELECT * FROM voucherpays 
			WHERE cmpy_code = p_rec_cheque.cmpy_code 
			AND pay_num = p_rec_cheque.cheq_code 
			AND vend_code = p_rec_cheque.vend_code 
			AND pay_meth_ind = p_rec_cheque.pay_meth_ind 
			AND bank_code = p_rec_cheque.bank_code 
			AND pay_type_code = "CH" 
			AND rev_flag IS NULL 
			FOREACH c_voucherpays INTO l_rec_voucherpays.* 
				SELECT * INTO l_rec_voucher.* FROM voucher 
				WHERE cmpy_code = l_rec_voucherpays.cmpy_code 
				AND vouch_code = l_rec_voucherpays.vouch_code 
				AND vend_code = l_rec_voucherpays.vend_code 
				PRINT COLUMN 10, l_rec_voucherpays.pay_date USING "dd/mm/yy", 
				COLUMN 20, l_rec_voucher.inv_text, 
				COLUMN 41, l_rec_voucher.vouch_code USING "########", 
				COLUMN 50, l_rec_voucherpays.apply_amt USING "--,---,--&.&&" 
			END FOREACH 

		AFTER GROUP OF p_rec_cheque.cheq_code 
			IF p_rec_cheque.withhold_tax_ind != "0" 
			AND p_rec_cheque.pay_amt > p_rec_cheque.net_pay_amt THEN 
				PRINT COLUMN 20, " Tax Deducted", 
				COLUMN 50, (p_rec_cheque.net_pay_amt - p_rec_cheque.pay_amt) 
				USING "--,---,--&.&&" 
			END IF 
			NEED 4 LINES 
			SKIP 1 line 
			PRINT COLUMN 49, " =============" 
			PRINT COLUMN 49, p_rec_cheque.net_pay_amt USING "---,---,--&.&&" 

		ON LAST ROW 
			SKIP 2 LINES
			
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN #Optional Query Where part print
				PRINT COLUMN 01,"Selection Criteria:"
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100
			END IF
			#End Of Report
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #Let's use the same END of report line whenever it's required/possible			
			
END REPORT 
