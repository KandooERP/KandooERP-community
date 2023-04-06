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
# GLOBAL SCOPE
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/PC_GROUP_GLOBALS.4gl"
########################################################################
# REPORT PC9z_rpt_list(p_rpt_idx, p_bic_code,p_rec_cheque)
#
# Report Definition/Layout
#
# This REPORT need only be run once (see FILE CLEANSING PROCEDURES)...
# but may be setup TO run FOR each EFT payment cycle
# Control = bank.eft_rpt_ind (<0> Never Print, <1> Print Once, <2> Always)
###########################################################################
REPORT PC9z_rpt_list(p_rpt_idx, p_bic_code,p_rec_cheque) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_bic_code LIKE bic.bic_code 
	DEFINE p_rec_cheque RECORD LIKE cheque.* 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_company RECORD LIKE company.* 
	DEFINE l_rec_bic RECORD LIKE bic.* 
	-- DEFINE l_line1 CHAR(132) #, l_line2 
	-- DEFINE l_offset1, l_offset2 SMALLINT 
	DEFINE l_acct_num, l_justified_vend CHAR(11) 
	-- DEFINE l_rpt_wid SMALLINT 
	DEFINE x,y SMALLINT

	OUTPUT 
		ORDER external BY p_bic_code, p_rec_cheque.vend_code 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno)  #update page number
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]
			PRINT COLUMN 01, "BIC No", 
			COLUMN 09, "Branch Name", 
			COLUMN 40, "Account Name", 
			COLUMN 70, "Account No" 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

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
			SKIP 2 LINES
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN #Optional Query Where part print
				PRINT COLUMN 01,"Selection Criteria:"
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100
			END IF
			#End Of Report
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #Let's use the same END of report line whenever it's required/possible			

END REPORT 


