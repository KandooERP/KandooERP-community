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

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl"
GLOBALS "../common/glob_GLOBALS_report.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl"
GLOBALS "../gl/GC_GROUP_GLOBALS.4gl" 
GLOBALS "../gl/GCP_GLOBALS.4gl"
 GLOBALS 
	DEFINE glob_where_text STRING 
	DEFINE glob_temp_text VARCHAR(200) 
END GLOBALS 

###########################################################################
# MODULE Scope Variables
###########################################################################

############################################################
# FUNCTION GCP_main()
#
# GCP - Print Statements entered thru GCE Only...
############################################################
FUNCTION GCP_main() 
	DEFINE l_msgresp LIKE language.yes_flag 

	DEFER quit 
	DEFER interrupt
	
	CALL setModuleId("GCP") 


	OPEN WINDOW G420 with FORM "G420" 
	CALL windecoration_g("G420") 

	IF get_gl_setup_cash_book_installed() != "Y" THEN 
		CALL fgl_winmessage("Cashbook Error",kandoomsg2("G",9502,""),"ERROR") #9502 "Cash Book IS NOT installed"
		EXIT PROGRAM 
	END IF
		
	MENU " Statement print" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","GCP","menu-statement-PRINT") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "Run"		#COMMAND "Run" " SELECT criteria AND PRINT REPORT"
			IF GCP_rpt_query() THEN 
			END IF 

		ON ACTION "PRINT MANAGER"		#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
			CALL run_prog("URS","","","","") 

		ON ACTION "Exit"		#COMMAND KEY(interrupt,"E")"Exit" " RETURN TO menus"
			EXIT MENU 

	END MENU 

	CLOSE WINDOW G420 
END FUNCTION


############################################################
# FUNCTION GCP_rpt_query()
#
#
############################################################
FUNCTION GCP_rpt_query() 
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE l_rec_bankstatement RECORD LIKE bankstatement.* 
	DEFINE l_query_text STRING 
	--DEFINE glob_rpt_output STRING 
	DEFINE l_msgresp LIKE language.yes_flag 

	MESSAGE kandoomsg2("G",1001,"") #1001 Enter Selection Criteria - ESC TO Continue
	CONSTRUCT BY NAME glob_where_text ON bank.bank_code, 
	bank.name_acct_text, 
	bank.iban, 
	bankstatement.sheet_num, 
	bank.state_bal_amt 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","GCP","construct-bank") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null)
			 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 
	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
--	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
--		LET int_flag = false 
--		LET quit_flag = false
--
--		RETURN FALSE
--	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"GCP_rpt_list","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT GCP_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0
	--LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GCP_rpt_list")].sel_text
	#------------------------------------------------------------

	LET l_query_text = "SELECT bankstatement.* FROM bankstatement, bank ", 
	"WHERE bankstatement.cmpy_code = '",glob_rec_kandoouser.cmpy_code CLIPPED,"' ", 
	"AND bank.cmpy_code = '",glob_rec_kandoouser.cmpy_code CLIPPED,"' ", 
	"AND bankstatement.bank_code = bank.bank_code ", 
	"AND ",glob_where_text clipped," ", 
	"ORDER BY bankstatement.bank_code, ", 
	"bankstatement.sheet_num, ", 
	"bankstatement.seq_num " 

	PREPARE s_bankstatement FROM l_query_text 
	DECLARE c_bankstatement CURSOR FOR s_bankstatement 

	#MESSAGE kandoomsg2("G",1038,"") #1038 Reporting on Account...
	FOREACH c_bankstatement INTO l_rec_bankstatement.* 
		MESSAGE l_rec_bankstatement.bank_code 

		#---------------------------------------------------------
		OUTPUT TO REPORT GCP_rpt_list(l_rpt_idx,l_rec_bankstatement.*) 
		IF NOT rpt_int_flag_handler2("Bank Statement:",l_rec_bankstatement.bank_code , NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------	
	END FOREACH 
	
	#------------------------------------------------------------
	FINISH REPORT GCP_rpt_list
	CALL rpt_finish("GCP_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF  
END FUNCTION 


############################################################
# REPORT GCP_rpt_list(p_rec_bankstatement)
#
#
############################################################
REPORT GCP_rpt_list(p_rpt_idx,p_rec_bankstatement) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_bankstatement RECORD LIKE bankstatement.* 
	DEFINE l_rec_bank RECORD LIKE bank.* 
	DEFINE l_close_bal LIKE bankstatement.tran_amt 
	DEFINE l_stmt_date LIKE bankstatement.tran_date 
	DEFINE l_dr_amt LIKE bank.state_bal_amt 
	DEFINE l_cr_amt LIKE bank.state_bal_amt 
	DEFINE l_open_bal LIKE bank.state_bal_amt 
	DEFINE l_bal_amt LIKE bank.state_bal_amt 
	DEFINE l_recon_ind char(1) 
	DEFINE l_cmpy_head char(132) 
	DEFINE l_i SMALLINT 
	DEFINE l_col2 SMALLINT 
	DEFINE l_col SMALLINT 
	DEFINE l_current_stmt SMALLINT 

	OUTPUT 
	left margin 0 
	ORDER external BY p_rec_bankstatement.bank_code, 
	p_rec_bankstatement.sheet_num, 
	p_rec_bankstatement.seq_num 
	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  

			LET l_stmt_date = NULL
			 
			SELECT tran_date INTO l_stmt_date FROM bankstatement 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND bank_code = p_rec_bankstatement.bank_code 
			AND entry_type_code = "SH" 
			AND sheet_num = p_rec_bankstatement.sheet_num 
			
			IF status = NOTFOUND THEN 
				SELECT bk_bankdt INTO l_stmt_date FROM banking 
				WHERE bk_cmpy = glob_rec_kandoouser.cmpy_code 
				AND bk_acct = l_rec_bank.acct_code 
				AND bk_sh_no = p_rec_bankstatement.sheet_num 
				AND bk_type = "XO" 
			END IF
			 
			SELECT * INTO l_rec_bank.* FROM bank 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND bank_code = p_rec_bankstatement.bank_code
			 
			PRINT COLUMN 01,"Bank: ", 
			COLUMN 07,l_rec_bank.bank_code, 
			COLUMN 17,l_rec_bank.name_acct_text, 
			COLUMN 66,"Statement" 
			PRINT COLUMN 01,"Account number:", 
			COLUMN 17,l_rec_bank.iban[1,16], 
			COLUMN 34,"Statement date:", 
			COLUMN 50,l_stmt_date USING "dd/mm/yy", 
			COLUMN 65,"Page number:", 
			COLUMN 77,p_rec_bankstatement.sheet_num USING "###&" 
			PRINT COLUMN 01,"----------------------------------------", 
			"----------------------------------------" 
			PRINT COLUMN 01,"Type", 
			COLUMN 08,"Date", 
			COLUMN 15,"Reference", 
			COLUMN 31,"Reconciled", 
			COLUMN 47,"Debit/Cheque", 
			COLUMN 61,"Credit/Deposit" 
			PRINT COLUMN 01,"----------------------------------------", 
			"----------------------------------------" 
		BEFORE GROUP OF p_rec_bankstatement.bank_code 
			SKIP TO top OF PAGE
			 
		BEFORE GROUP OF p_rec_bankstatement.sheet_num 
			SKIP TO top OF PAGE 
			LET l_current_stmt = false 
			LET l_open_bal = NULL 
			SELECT bk_cred INTO l_open_bal FROM banking 
			WHERE bk_cmpy = glob_rec_kandoouser.cmpy_code 
			AND bk_acct = l_rec_bank.acct_code 
			AND bk_sh_no = p_rec_bankstatement.sheet_num 
			AND bk_type = "XO" 
			IF status != NOTFOUND THEN 
				SKIP 1 line 
				PRINT COLUMN 65, "Opening bal" 
				PRINT COLUMN 65, "-----------" 
				PRINT COLUMN 61, l_open_bal USING "----,---,--&.&&" 
				SKIP 1 line
				 
			ELSE
			 
				SELECT tran_amt INTO l_open_bal FROM bankstatement 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND bank_code = p_rec_bankstatement.bank_code 
				AND entry_type_code = "SH" 
				AND sheet_num = p_rec_bankstatement.sheet_num - 1 
				IF status != NOTFOUND THEN 
					LET l_current_stmt = true 
					SKIP 1 line 
					PRINT COLUMN 65, "Opening bal" 
					PRINT COLUMN 65, "-----------" 
					PRINT COLUMN 61, l_open_bal USING "----,---,--&.&&" 
					SKIP 1 line 
				ELSE 
					LET l_open_bal = 0 
				END IF 
			END IF 
			LET l_bal_amt = l_open_bal
			 
		ON EVERY ROW 
			IF p_rec_bankstatement.entry_type_code != "SH" THEN 
				IF p_rec_bankstatement.recon_ind = "2" THEN 
					LET l_recon_ind = "Y" 
				ELSE 
					LET l_recon_ind = "N" 
				END IF 
				IF p_rec_bankstatement.entry_type_code = "CH" 
				OR p_rec_bankstatement.entry_type_code = "EF" 
				OR p_rec_bankstatement.entry_type_code = "BC" 
				OR p_rec_bankstatement.entry_type_code = "DC" 
				OR p_rec_bankstatement.entry_type_code = "PA" 
				OR p_rec_bankstatement.entry_type_code = "TO" THEN 
					LET l_bal_amt = l_bal_amt - p_rec_bankstatement.tran_amt 
					LET l_dr_amt = p_rec_bankstatement.tran_amt 
					LET l_cr_amt = NULL 
				ELSE 
					LET l_bal_amt = l_bal_amt + p_rec_bankstatement.tran_amt 
					LET l_cr_amt = p_rec_bankstatement.tran_amt 
					LET l_dr_amt = NULL 
				END IF 
				PRINT COLUMN 01, p_rec_bankstatement.entry_type_code, 
				COLUMN 06, p_rec_bankstatement.tran_date USING "dd/mm/yy", 
				COLUMN 15, p_rec_bankstatement.ref_code, 
				COLUMN 36, l_recon_ind, 
				COLUMN 44, l_dr_amt USING "----,---,--&.&&", 
				COLUMN 61, l_cr_amt USING "----,---,--&.&&" 
			END IF 

		AFTER GROUP OF p_rec_bankstatement.sheet_num 
			NEED 5 LINES 
			LET l_close_bal = NULL 
			SELECT bk_debit INTO l_close_bal FROM banking 
			WHERE bk_cmpy = glob_rec_kandoouser.cmpy_code 
			AND bk_acct = p_rec_bankstatement.acct_code 
			AND bk_sh_no = p_rec_bankstatement.sheet_num 
			AND bk_type = "XC"
			 
			IF status = NOTFOUND THEN 
				SELECT tran_amt INTO l_close_bal FROM bankstatement 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND bank_code = p_rec_bankstatement.bank_code 
				AND entry_type_code = "SH" 
				AND sheet_num = p_rec_bankstatement.sheet_num - 1 
			END IF
			 
			SKIP 1 line 
			PRINT COLUMN 65, "Closing bal" 
			PRINT COLUMN 65, "-----------" 
			PRINT COLUMN 61, l_bal_amt USING "----,---,--&.&&"
			 
			IF l_current_stmt 
			AND l_bal_amt != l_close_bal THEN 
				NEED 5 LINES 
				SKIP 1 line 
				PRINT COLUMN 58, "System Closing bal" 
				PRINT COLUMN 58, "------------------" 
				PRINT COLUMN 61, l_close_bal USING "----,---,--&.&&" 
			END IF 

		ON LAST ROW 
			NEED 7 LINES 
			SKIP 3 LINES 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	
			
			 
END REPORT