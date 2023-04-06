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
GLOBALS "../gl/GCL_GLOBALS.4gl"
###########################################################################
# MODULE Scope Variables
###########################################################################

############################################################
# FUNCTION westpac_stmt_load(p_type_code)
#
# GCL  Loads bank statement details directly FROM an interface
#              file provided by banking groups. Transactions will also
#              be reconciled WHERE sufficient information exists.
############################################################
FUNCTION westpac_stmt_load(p_type_code) 
	DEFINE p_type_code LIKE banktype.type_code
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	 
	DEFINE l_rec_banktype RECORD LIKE banktype.* 
	DEFINE l_rec_bank RECORD LIKE bank.* 
	DEFINE l_rec_stmthead RECORD LIKE bankstatement.* 
	DEFINE l_stmt_line char(250) 
	DEFINE l_trans_code char(3) 
	DEFINE l_rpt_output char(50) 
	DEFINE l_rec_type INTEGER 
	DEFINE l_prev_rec_type INTEGER 
	DEFINE l_dr_num INTEGER 
	DEFINE l_cr_num INTEGER 
	DEFINE l_ctl_dr_num INTEGER 
	DEFINE l_ctl_cr_num INTEGER 
	DEFINE l_ctl_tran_num INTEGER 
	DEFINE l_ctl_rows INTEGER 
	--DEFINE l_acct_dr_num INTEGER not used
	--DEFINE l_acct_cr_num INTEGER
	DEFINE l_acct_tran_num INTEGER 
	DEFINE l_file_tran_tot INTEGER 
	--DEFINE l_tot_accts INTEGER
	DEFINE l_interest decimal(16,2) 
	DEFINE l_fid decimal(16,2) 
	DEFINE l_bad decimal(16,2) 
	DEFINE l_limit_fee decimal(16,2) 
	DEFINE l_comp_fee decimal(16,2) 
	DEFINE l_dr_amt decimal(16,2) 
	DEFINE l_cr_amt decimal(16,2) 
	DEFINE l_ctl_dr_amt decimal(16,2) 
	DEFINE l_ctl_cr_amt decimal(16,2) 
	DEFINE l_tran_amt decimal(16,2) 
	DEFINE l_acct_dr_amt decimal(16,2) 
	DEFINE l_acct_cr_amt decimal(16,2) 
	DEFINE l_ctl_acct_tot decimal(16,2) 
	DEFINE l_ctl_file_tot decimal(16,2) 
	DEFINE l_ctl_tran_tot decimal(16,2) 
	DEFINE l_file_tot_amt decimal(16,2) 
	DEFINE l_ovdrt_amt decimal(16,2) 
	DEFINE l_acct_tot_amt decimal(16,2) 
	DEFINE l_acct_num char(17) 
	DEFINE l_stmt_year char(20) 
	DEFINE l_err_acct_cnt SMALLINT 
	DEFINE l_err_file_cnt SMALLINT 
	DEFINE l_err_cnt SMALLINT 
	DEFINE l_act_file_tot SMALLINT 
	DEFINE l_act_file_cnt SMALLINT 
	DEFINE i SMALLINT 
	DEFINE l_err_message char(80) 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET l_rec_type = NULL 


	MESSAGE kandoomsg2("G",1002,"") 	## Set up Banktype record
	SELECT * INTO l_rec_banktype.* 
	FROM banktype 
	WHERE type_code = p_type_code 
	## Commence OUTPUT REPORT

	
	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
--	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
--		LET int_flag = false 
--		LET quit_flag = false
--
--		RETURN FALSE
--	END IF

	LET l_rpt_idx = rpt_start("GCL-B","GCL_rpt_list_b_westpac","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT GCL_rpt_list_b_westpac TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0
	--LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GCL_rpt_list_b_westpac")].sel_text
	#------------------------------------------------------------
	
	 
	##
	## Work through each line of the load file
	##
	DECLARE c_stmtload SCROLL CURSOR FOR 
	SELECT * FROM t_stmtload 
	OPEN c_stmtload 
	SELECT count(*) INTO l_act_file_tot 
	FROM t_stmtload 
	WHILE true 
		FETCH c_stmtload INTO l_stmt_line 
		IF sqlca.sqlcode = NOTFOUND THEN 
			EXIT WHILE 
		END IF 
		##
		LET l_act_file_cnt = l_act_file_cnt + 1 
		DISPLAY " Validating line ",l_act_file_cnt," OF ",l_act_file_tot TO lblabel2 #at 2,2 

		##
		LET l_prev_rec_type = l_rec_type 
		CALL validate_record_format(l_stmt_line[1,2],l_prev_rec_type) 
		RETURNING l_rec_type, 
		l_err_message 
		IF l_rec_type IS NULL THEN 
			LET l_stmt_line = l_stmt_line[1,109],"##",l_err_message clipped 

			#---------------------------------------------------------			
			OUTPUT TO REPORT GCL_rpt_list_b_westpac(l_rpt_idx,l_rec_stmthead.*,l_stmt_line) 
			#---------------------------------------------------------			

			CALL msgContinue("Invalid RECORD type ","Invalid RECORD type - process Aborted") 
			DELETE FROM t_stmthead 
			EXIT WHILE 
		END IF 

		CASE l_rec_type 
		WHEN 0 ### initial RECORD 
			LET l_err_cnt = 0 
			LET glob_tot_rows = 0 ## NOT glob_tot_rows = 1 
			LET l_file_tran_tot = 0 
			LET l_file_tot_amt = 0 
			CONTINUE WHILE 
			
			WHEN 01 ### file HEADER 
				LET glob_tot_rows = glob_tot_rows + 1 
				LET l_stmt_year = '01/01/', l_stmt_line[8,11] 
				LET glob_stmt_date = l_stmt_year 
				LET glob_stmt_date = glob_stmt_date+(l_stmt_line[12,14]-1) 
			WHEN 02 ### account HEADER 1 
				LET glob_tot_rows = glob_tot_rows + 1 
				LET l_cr_num = 0 
				LET l_dr_num = 0 
				LET l_cr_amt = 0 
				LET l_dr_amt = 0 
				LET l_acct_tot_amt = l_stmt_line[28,42] 
				IF l_acct_tot_amt IS NULL THEN 
					LET l_acct_tot_amt = 0 
				ELSE 
					IF l_stmt_line[43,43] = '-' THEN 
						LET l_acct_tot_amt = l_acct_tot_amt * -1 
					END IF 
				END IF 
				LET l_ovdrt_amt = l_stmt_line[44,56] 
				IF l_ovdrt_amt IS NULL THEN 
					LET l_ovdrt_amt = 0 
				END IF 
				## overdraft  IS expressed as whole dollars - multiply
				##         by 100 TO express as cents, as per other VALUES which
				##         make up the control total
				LET l_ovdrt_amt = l_ovdrt_amt * 100 
				LET l_interest = l_stmt_line[57,71] 
				IF l_interest IS NULL THEN 
					LET l_interest = 0 
				ELSE 
					IF l_stmt_line[72,72] = '-' THEN 
						LET l_interest = l_interest * -1 
					END IF 
				END IF 
				LET l_fid = l_stmt_line[73,87] 
				IF l_fid IS NULL THEN 
					LET l_fid = 0 
				ELSE 
					IF l_stmt_line[88,88] = '-' THEN 
						LET l_fid = l_fid * -1 
					END IF 
				END IF 
				LET l_bad = l_stmt_line[89,103] 
				IF l_bad IS NULL THEN 
					LET l_bad = 0 
				ELSE 
					IF l_stmt_line[104,104] = '-' THEN 
						LET l_bad = l_bad * -1 
					END IF 
				END IF 
				LET l_acct_tot_amt = l_acct_tot_amt 
				+ l_ovdrt_amt 
				+ l_interest 
				+ l_fid 
				+ l_bad 
				LET l_acct_tran_num = 0 
				CALL validate_bank(l_stmt_line[8,24],l_stmt_line[25,27]) 
				RETURNING l_rec_bank.*, 
				l_err_message 
				LET l_rec_stmthead.cmpy_code = l_rec_bank.cmpy_code 
				LET l_rec_stmthead.bank_code = l_rec_bank.bank_code 
				LET l_rec_stmthead.sheet_num = NULL 
				##
				## Allocate sheet number FROM max(t_stmthead) in CASE
				## two entries FOR same bank OTHERWISE use bankstatement
				##
				SELECT (max(sheet_num)+1) INTO l_rec_stmthead.sheet_num 
				FROM t_stmthead 
				WHERE cmpy_code = l_rec_bank.cmpy_code 
				AND bank_code = l_rec_bank.bank_code 
				AND entry_type_code = "SH" 
				IF l_rec_stmthead.sheet_num IS NULL THEN 
					SELECT (max(sheet_num)+1) INTO l_rec_stmthead.sheet_num 
					FROM bankstatement 
					WHERE cmpy_code = l_rec_bank.cmpy_code 
					AND bank_code = l_rec_bank.bank_code 
					AND entry_type_code = "SH" 
					IF l_rec_stmthead.sheet_num IS NULL THEN 
						LET l_rec_stmthead.sheet_num = 1 
					END IF 
				END IF 
				LET l_rec_stmthead.seq_num = 0 
				LET l_rec_stmthead.entry_type_code = "SH" 
				LET l_rec_stmthead.tran_date = glob_stmt_date 
				LET l_rec_stmthead.tran_amt=l_stmt_line[28,42]/100 ##convert TO $ 
				LET l_rec_stmthead.bank_currency_code = l_rec_bank.currency_code 
				LET l_rec_stmthead.ref_currency_code = l_rec_bank.currency_code 
				LET l_rec_stmthead.acct_code = l_rec_bank.acct_code 
				IF l_rec_stmthead.tran_amt IS NULL THEN 
					LET l_rec_stmthead.tran_amt = 0 
				ELSE 
					IF l_stmt_line[43,43] = '-' THEN 
						LET l_rec_stmthead.tran_amt = l_rec_stmthead.tran_amt * -1 
					END IF 
				END IF 
				LET l_rec_stmthead.desc_text = "Statement header" 
				LET l_rec_stmthead.doc_num = 0 
				IF l_rec_bank.bank_code IS NULL THEN 
					LET l_stmt_line = l_stmt_line[1,109],"**",l_err_message clipped 
				ELSE 
					INSERT INTO t_stmthead VALUES (l_rec_stmthead.*) 
				END IF 
				
			WHEN 03 # account HEADER 2 
				LET glob_tot_rows = glob_tot_rows + 1 
				LET l_limit_fee = l_stmt_line[3,17] 
				IF l_limit_fee IS NULL THEN 
					LET l_limit_fee = 0 
				ELSE 
					IF l_stmt_line[18,18] = '-' THEN 
						LET l_limit_fee = l_limit_fee * -1 
					END IF 
				END IF 
				LET l_comp_fee = l_stmt_line[19,33] 
				IF l_comp_fee IS NULL THEN 
					LET l_comp_fee = 0 
				ELSE 
					IF l_stmt_line[34,34] = '-' THEN 
						LET l_comp_fee = l_comp_fee * -1 
					END IF 
				END IF 
				LET l_acct_tot_amt = l_acct_tot_amt 
				+ l_limit_fee 
				+ l_comp_fee 
				
				WHEN 05 ### transaction RECORD 
					LET glob_tot_rows = glob_tot_rows + 1 
					LET l_acct_tran_num = l_acct_tran_num +1 
					LET l_tran_amt = l_stmt_line[3,17] 
					IF l_tran_amt IS NULL THEN 
						LET l_tran_amt = 0 
					END IF 
					IF l_stmt_line[18,18] = '-' THEN 
						LET l_dr_num = l_dr_num + 1 
						LET l_dr_amt = l_dr_amt + l_tran_amt 
						LET l_tran_amt = l_tran_amt * -1 
					ELSE 
						LET l_cr_num = l_cr_num + 1 
						LET l_cr_amt = l_cr_amt + l_tran_amt 
					END IF 
					LET l_acct_tot_amt = l_acct_tot_amt + l_tran_amt 
					LET l_rec_stmthead.seq_num = l_rec_stmthead.seq_num + 1 
					LET l_rec_stmthead.recon_ind = "0" 
					## Transaction Type
					LET l_trans_code = l_stmt_line[19,21] 
					SELECT max_ref_code INTO l_rec_stmthead.entry_type_code 
					FROM banktypedetl 
					WHERE type_code = l_rec_banktype.type_code 
					AND bank_ref_code = l_trans_code 
					IF status = NOTFOUND THEN 
						## IF mapping does NOT exist THEN default TO general value
						IF l_tran_amt < 0 THEN 
							LET l_rec_stmthead.entry_type_code = "BC" 
						ELSE 
							LET l_rec_stmthead.entry_type_code = "SC" 
						END IF 
					END IF 
					## Move trans type back INTO l_stmt_line as its used TO REPORT
					LET l_stmt_line[110,111] = l_rec_stmthead.entry_type_code 
					LET l_rec_stmthead.tran_date = glob_stmt_date ## global 
					LET l_rec_stmthead.tran_amt = l_stmt_line[3,17]/100 #convert TO $ 
					LET l_rec_stmthead.ref_code = l_stmt_line[64,70] 
					LET l_rec_stmthead.doc_num = 0 
					LET l_rec_stmthead.desc_text= l_stmt_line[22,53] 
					IF l_rec_bank.bank_code IS NOT NULL THEN 
						##
						## Do NOT perform any line item load IF the bank IS valid
						##
						INSERT INTO t_stmthead VALUES (l_rec_stmthead.*) 
					END IF 
					
			WHEN 07 # account TRAILER 
				LET l_err_acct_cnt = 0 
				LET glob_tot_rows = glob_tot_rows + 1 
				LET l_ctl_acct_tot = l_stmt_line[43,58] 
				IF l_ctl_acct_tot IS NULL THEN 
					LET l_ctl_acct_tot = 0 
				ELSE 
					IF l_stmt_line[59,59] = '-' THEN 
						LET l_ctl_acct_tot = l_ctl_acct_tot * -1 
					END IF 
				END IF 
				LET l_ctl_dr_amt = l_stmt_line[3,17] 
				IF l_ctl_dr_amt IS NULL THEN 
					LET l_ctl_dr_amt = 0 
				END IF 
				LET l_ctl_dr_num = l_stmt_line[18,22] 
				IF l_ctl_dr_num IS NULL THEN 
					LET l_ctl_dr_num = 0 
				END IF 
				LET l_ctl_cr_amt = l_stmt_line[23,37] 
				IF l_ctl_cr_amt IS NULL THEN 
					LET l_ctl_cr_amt = 0 
				END IF 
				LET l_ctl_cr_num = l_stmt_line[38,42] 
				IF l_ctl_cr_num IS NULL THEN 
					LET l_ctl_cr_num = 0 
				END IF 
				LET l_ctl_tran_num = l_stmt_line[60,65] 
				IF l_ctl_tran_num IS NULL THEN 
					LET l_ctl_tran_num = 0 
				END IF 
				LET l_stmt_line[110,124] = l_dr_amt 
				LET l_stmt_line[125,129] = l_dr_num 
				LET l_stmt_line[130,144] = l_cr_amt 
				LET l_stmt_line[145,149] = l_cr_num 
				LET l_stmt_line[150,166] = l_acct_tot_amt 
				LET l_stmt_line[167,172] = l_acct_tran_num 
				LET l_file_tran_tot = l_file_tran_tot + l_acct_tran_num 
				LET l_file_tot_amt = l_file_tot_amt + l_acct_tot_amt 
				FOR i = 1 TO 6 
					CASE i 
						WHEN 1 
						WHEN 2 
							IF l_ctl_tran_num != l_acct_tran_num THEN 
								LET l_stmt_line = l_stmt_line[1,172], 
								'2', "No. of transactions out of balance" 
							END IF 
						WHEN 3 
							IF l_ctl_dr_num != l_dr_num THEN 
								LET l_stmt_line = l_stmt_line[1,172], 
								'3', "No. of debits computed out of balance" 
							END IF 
						WHEN 4 
							IF l_ctl_dr_amt != l_dr_amt THEN 
								LET l_stmt_line = l_stmt_line[1,172], 
								'4', "Debit total out of balance" 
							END IF 
						WHEN 5 
							IF l_ctl_cr_num != l_cr_num THEN 
								LET l_stmt_line = l_stmt_line[1,172], 
								'5', "No. of credits computed out of balance" 
							END IF 
						WHEN 6 
							IF l_ctl_cr_amt != l_cr_amt THEN 
								LET l_stmt_line = l_stmt_line[1,172], 
								'6', "Credit total out of balance" 
							END IF 
					END CASE 
					IF l_stmt_line[173,173] = i THEN 
						LET l_err_acct_cnt = l_err_acct_cnt + 1 
						#---------------------------------------------------------			
						OUTPUT TO REPORT GCL_rpt_list_b_westpac(l_rpt_idx,l_rec_stmthead.*,l_stmt_line) 
						#---------------------------------------------------------			

					END IF 
				END FOR 
				IF l_err_acct_cnt THEN 
					IF l_rec_bank.bank_code IS NOT NULL THEN 
						DELETE FROM t_stmthead 
						WHERE bank_code = l_rec_bank.bank_code 
						AND sheet_num = l_rec_stmthead.sheet_num 
					END IF 
					LET l_err_cnt = l_err_cnt + l_err_acct_cnt 
					LET l_stmt_line[173,173] = 7 
				END IF 
				
			WHEN 90 # DELETE account 
			WHEN 99 # file TRAILER 
		END CASE 

		#---------------------------------------------------------			
		OUTPUT TO REPORT GCL_rpt_list_b_westpac(l_rpt_idx,l_rec_stmthead.*,l_stmt_line) 
		#---------------------------------------------------------			
 
	END WHILE 


	

	#------------------------------------------------------------
	FINISH REPORT GCL_rpt_list_b_westpac
	CALL rpt_finish("GCL_rpt_list_b_westpac")
	#------------------------------------------------------------
	
END FUNCTION 


############################################################
# FUNCTION validate_record_format(p_load_type,l_prev_rec_type)
#
#
# This FUNCTION accepts two arguments.
#   1) A bank RECORD type which IS converted TO a Max. RECORD type
#   2) The Max. RECORD type of the previous record.
# This FUNCTION performs two tasks.
#   1) Validates first RECORD type
#   2) Checks that the RECORD type of the current RECORD IS allowed
#      TO follow the previous RECORD type.
#
############################################################
FUNCTION validate_record_format(p_load_type,l_prev_rec_type) 
	DEFINE p_load_type char(2) 
	DEFINE l_prev_rec_type SMALLINT 
	DEFINE l_rec_type SMALLINT 
	DEFINE l_valid_ind SMALLINT 
	DEFINE l_err_message char(80) 

	CASE 
		WHEN p_load_type = '#b' 
			LET l_rec_type = 0 
		WHEN p_load_type = '#e' 
			LET l_rec_type = 100 
		WHEN p_load_type = '01' 
			OR p_load_type = '02' 
			OR p_load_type = '03' 
			OR p_load_type = '05' 
			OR p_load_type = '07' 
			OR p_load_type = '90' 
			OR p_load_type = '99' 
			LET l_rec_type = p_load_type 
		OTHERWISE 
			LET l_err_message = 
			'##invalid RECORD type ',p_load_type, 
			' loaded AFTER ',l_prev_rec_type USING "&&" 
			RETURN "",l_err_message 
	END CASE 
	##
	## Check each RECORD type against the previous TO ensure
	## nothing IS missing.
	##
	CASE l_rec_type 
		WHEN 0 
			IF l_prev_rec_type IS NULL 
			OR l_prev_rec_type = 100 THEN 
				LET l_valid_ind = true 
			ELSE 
				LET l_valid_ind = false 
			END IF 
		WHEN 01 
			IF l_prev_rec_type = 0 THEN 
				LET l_valid_ind = true 
			ELSE 
				LET l_valid_ind = false 
			END IF 
		WHEN 02 
			IF l_prev_rec_type = 01 THEN 
				LET l_valid_ind = true 
			ELSE 
				LET l_valid_ind = false 
			END IF 
		WHEN 03 
			IF l_prev_rec_type = 02 THEN 
				LET l_valid_ind = true 
			ELSE 
				LET l_valid_ind = false 
			END IF 
		WHEN 05 
			IF l_prev_rec_type = 03 
			OR l_prev_rec_type = 05 THEN 
				LET l_valid_ind = true 
			ELSE 
				LET l_valid_ind = false 
			END IF 
		WHEN 07 
			IF l_prev_rec_type = 03 
			OR l_prev_rec_type = 05 THEN 
				LET l_valid_ind = true 
			ELSE 
				LET l_valid_ind = false 
			END IF 
		WHEN 90 
			IF l_prev_rec_type = 01 THEN 
				LET l_valid_ind = true 
			ELSE 
				LET l_valid_ind = false 
			END IF 
		WHEN 99 
			IF l_prev_rec_type = 01 
			OR l_prev_rec_type = 07 
			OR l_prev_rec_type = 90 THEN 
				LET l_valid_ind = true 
			ELSE 
				LET l_valid_ind = false 
			END IF 
		WHEN 100 
			IF l_prev_rec_type = 0 
			OR l_prev_rec_type = 99 THEN 
				LET l_valid_ind = true 
			ELSE 
				LET l_valid_ind = false 
			END IF 
	END CASE 
	IF NOT l_valid_ind THEN 
		LET l_err_message = 
		"##Invalid BAI sequence - RECORD type ",l_rec_type USING "&&", 
		" loaded AFTER ", l_prev_rec_type USING "&&" 
		RETURN "",l_err_message 
	ELSE 
		RETURN l_rec_type,l_err_message 
	END IF 
END FUNCTION 


############################################################
# FUNCTION validate_bank(p_acct_code,p_curr_code)
#
#
# This FUNCTION identifies that "bank" table entry corresponding
# TO the account being loaded.
#
############################################################
FUNCTION validate_bank(p_acct_code,p_curr_code) 
	DEFINE p_acct_code LIKE bank.iban 
	DEFINE p_curr_code LIKE bank.currency_code 
	DEFINE l_bic_code LIKE bank.bic_code 
	DEFINE l_acct_num LIKE bank.iban 
	DEFINE l_rec_bank RECORD LIKE bank.* 
	DEFINE l_rec_bankstatement RECORD LIKE bankstatement.* 
	DEFINE l_bank_cnt SMALLINT 
	DEFINE l_err_message char(80) 

	##
	## Need TO know how many times this bank has been setup in KandooERP
	##
	## account code in file actually consists of the last 4
	## digits of the bic code in positions 8-11 AND the bank account
	## number in the remaining portion.  Selection has been amended
	## TO allow proper SET up in Bank Maintenance. The account number
	## was formerly entered as per the load file account (ie. with the
	## bic as a prefix), but this IS incompatible with the required
	## FORMAT FOR the Westpac bank EFT file.
	##
	LET l_bic_code = "??", p_acct_code[1,4] 
	LET l_acct_num = p_acct_code[5,40] 
	LET l_bank_cnt = 0 
	SELECT count(*) INTO l_bank_cnt 
	FROM bank 
	WHERE iban = l_acct_num 
	AND bic_code matches l_bic_code 
	AND currency_code = p_curr_code 
	CASE 
		WHEN l_bank_cnt = 0 
			## Bank NOT setup
			LET l_err_message = 
			" Account no. ",p_acct_code clipped," does NOT exist **" 
		WHEN l_bank_cnt = 1 
			## Bank setup once
			SELECT * INTO l_rec_bank.* 
			FROM bank 
			WHERE iban = l_acct_num 
			AND bic_code matches l_bic_code 
			AND currency_code = p_curr_code 
		OTHERWISE 
			## Bank setup multiple times
			## IF it IS setup FOR the current company THEN use this entry.
			## OTHERWISE do NOT make assumptions AND REPORT an error.
			DECLARE c_bank CURSOR FOR 
			SELECT * FROM bank 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND iban = l_acct_num 
			AND bic_code matches l_bic_code 
			AND currency_code = p_curr_code 
			OPEN c_bank 
			FETCH c_bank INTO l_rec_bank.* 
			IF sqlca.sqlcode = NOTFOUND THEN 
				LET l_err_message = 
				" Account no.",p_acct_code clipped," has multiple setups **" 
			END IF 
	END CASE 
	IF l_rec_bank.bank_code IS NOT NULL THEN 
		SELECT unique 1 FROM bankstatement 
		WHERE cmpy_code = l_rec_bank.cmpy_code 
		AND bank_code = l_rec_bank.bank_code 
		AND tran_date = glob_stmt_date # global - '01'[8,14] 
		AND entry_type_code = "SH" 
		IF sqlca.sqlcode = 0 THEN 
			INITIALIZE l_rec_bank.* TO NULL 
			LET l_err_message = 
			" Account no.",p_acct_code clipped," already loaded **" 
		ELSE 
			##
			## Following CURSOR retrieves date of last statement
			##
			DECLARE c_bankstatement CURSOR FOR 
			SELECT * FROM bankstatement 
			WHERE cmpy_code = l_rec_bank.cmpy_code 
			AND bank_code = l_rec_bank.bank_code 
			AND entry_type_code = "SH" 
			AND seq_num = 0 
			ORDER BY bank_code,sheet_num desc 
			OPEN c_bankstatement 
			FETCH c_bankstatement INTO l_rec_bankstatement.* 
			IF sqlca.sqlcode = 0 THEN 
				IF l_rec_bankstatement.tran_date > glob_stmt_date THEN 
					INITIALIZE l_rec_bank.* TO NULL 
					LET l_err_message = " Account no.",p_acct_code clipped, 
					" out of sequence. Loading statement of ",glob_stmt_date 
				END IF 
			END IF 
		END IF 
	END IF 
	RETURN l_rec_bank.*, l_err_message 
END FUNCTION 


############################################################
# REPORT GCL_rpt_list_b_westpac(p_rec_stmthead,p_stmt_line)
#
#
#
############################################################
REPORT GCL_rpt_list_b_westpac(p_rec_stmthead,p_stmt_line) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_stmthead RECORD LIKE bankstatement.* 
	DEFINE p_stmt_line char(250) 

	DEFINE l_cmpy_head char(80) 
	DEFINE i SMALLINT 
	DEFINE x SMALLINT 
	DEFINE y SMALLINT 
	DEFINE l_head_reqd SMALLINT 
	DEFINE l_arr_line array[4] OF char(132) 
	DEFINE l_bank_id LIKE bank.bank_code 
	DEFINE l_acct_no LIKE bank.acct_code 
	DEFINE l_curr_code LIKE bank.currency_code 
	DEFINE l_acct_tot LIKE bank.state_bal_amt 
	DEFINE l_tran_amt LIKE bank.state_bal_amt 
	DEFINE l_bal_amt LIKE bank.state_bal_amt 

	OUTPUT 
	--left margin 0
 
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			LET l_head_reqd = true 
		ON EVERY ROW 
			CASE p_stmt_line[1,2] 
				WHEN '##' 
					NEED 3 LINES 
					SKIP 2 LINES 
					PRINT COLUMN 28, p_stmt_line[3,250] clipped 
				WHEN '02' 
					SKIP TO top OF PAGE 
					PRINT COLUMN 01, "Westpac", 
					COLUMN 25, "Westpac Account no.", 
					COLUMN 46, "Sheet no.", 
					COLUMN 60, "Closing balance", 
					COLUMN 118, "Statement date" 
					PRINT COLUMN 01,l_arr_line[3] 
					LET l_bank_id = p_stmt_line[3,7] 
					LET l_acct_no = p_stmt_line[8,24] 
					LET l_curr_code = p_stmt_line[25,27] 
					LET l_bal_amt = ( p_stmt_line[28,42] ) / 100 
					IF p_stmt_line[43,43] = '-' THEN 
						LET l_bal_amt = l_bal_amt * -1 
					END IF 
					PRINT COLUMN 01, l_bank_id, 
					COLUMN 15, p_rec_stmthead.bank_code, 
					COLUMN 25, l_acct_no, 
					COLUMN 45, p_rec_stmthead.sheet_num, 
					COLUMN 60, l_bal_amt USING "------------&.&&", 
					COLUMN 77, l_curr_code, 
					COLUMN 118, glob_stmt_date USING "dd mmm yyyy" 
					SKIP 2 LINES 
					IF p_stmt_line[110,111] = '**' THEN 
						PRINT COLUMN 01,"** This Bank Sheet will NOT be loaded INTO ", 
						"database. Transaction are listed FOR REPORT purposes only." 
						PRINT COLUMN 01, p_stmt_line[110,250] clipped 
						SKIP 1 line 
					END IF 
					PRINT COLUMN 20,"------- Transaction ------------------------", 
					"--------------------------------------------" 
					PRINT COLUMN 20,"Line", 
					COLUMN 28,"Type", 
					COLUMN 35,"Code", 
					COLUMN 42,"Reference", 
					COLUMN 63,"Amount", 
					COLUMN 72,"Recon.", 
					COLUMN 80,"Comments" 
					PRINT COLUMN 20,"--------------------------------------------", 
					"--------------------------------------------" 
					LET l_head_reqd = false 

				WHEN '05' 
					NEED 3 LINES 
					IF l_head_reqd THEN 
						PRINT COLUMN 01, "Westpac", 
						COLUMN 25, "Westpac Account no.", 
						COLUMN 46, "Sheet no.", 
						COLUMN 60, "Closing balance", 
						COLUMN 118, "Statement date" 
						PRINT COLUMN 01, l_arr_line[3] 
						PRINT COLUMN 01, l_bank_id, 
						COLUMN 15, p_rec_stmthead.bank_code, 
						COLUMN 25, l_acct_no, 
						COLUMN 45, p_rec_stmthead.sheet_num, 
						COLUMN 60, l_bal_amt USING "------------&.&&", 
						COLUMN 77, l_curr_code, 
						COLUMN 118, glob_stmt_date USING "dd mmm yyyy" 
						SKIP 2 LINES 
						PRINT COLUMN 20,"------- Transaction ------------------------", 
						"--------------------------------------------" 
						PRINT COLUMN 20,"Line", 
						COLUMN 28,"Type", 
						COLUMN 35,"Code", 
						COLUMN 42,"Reference", 
						COLUMN 63,"Amount", 
						COLUMN 72,"Recon.", 
						COLUMN 80,"Comments" 
						PRINT COLUMN 20,"--------------------------------------------", 
						"--------------------------------------------" 
						LET l_head_reqd = false 
					END IF 
					LET l_tran_amt = p_stmt_line[3,17] / 100 
					IF p_stmt_line[18,18] = '-' THEN 
						LET l_tran_amt = l_tran_amt * -1 
					END IF 
					PRINT COLUMN 20, p_rec_stmthead.seq_num USING "#####", 
					COLUMN 28, p_stmt_line[110,111], 
					COLUMN 35, p_stmt_line[19,21], 
					COLUMN 42, p_stmt_line[64,70], 
					COLUMN 53, l_tran_amt USING "------------&.&&", 
					COLUMN 72, p_stmt_line[112,112]; 
					#
					# Check FOR errors during reconciliation
					#
					IF p_stmt_line[113,113] = ' ' THEN 
						PRINT COLUMN 80, p_stmt_line[22,63] clipped ## narrative 
					ELSE 
						#
						# Error detected
						#
						PRINT COLUMN 80, p_stmt_line[113,250] clipped 
					END IF 
				WHEN '07' 
					NEED 4 LINES 
					IF l_head_reqd THEN 
						PRINT COLUMN 01, "Westpac", 
						COLUMN 25, "Westpac Account no.", 
						COLUMN 46, "Sheet no.", 
						COLUMN 60, "Closing balance", 
						COLUMN 118, "Statement date" 
						PRINT COLUMN 01, l_arr_line[3] 
						PRINT COLUMN 01, l_bank_id, 
						COLUMN 15, p_rec_stmthead.bank_code, 
						COLUMN 25, l_acct_no, 
						COLUMN 45, p_rec_stmthead.sheet_num, 
						COLUMN 60, l_bal_amt USING "------------&.&&", 
						COLUMN 77, l_curr_code, 
						COLUMN 118, glob_stmt_date USING "dd mmm yyyy" 
						SKIP 1 line 
						LET l_head_reqd = false 
					END IF 
					LET l_tran_amt = p_stmt_line[43,58] / 100 
					IF p_stmt_line[59,59] = '-' THEN 
						LET l_tran_amt = l_tran_amt * -1 
					END IF 
					LET x = p_stmt_line[60,65] USING "#####&" 
					IF x = 0 THEN 
						PRINT COLUMN 20, "No transactions exist on this sheet" 
					END IF 
					PRINT COLUMN 53, "----------------" 
					CASE p_stmt_line[173,173] 
						WHEN '1' 
							PRINT COLUMN 20, "Account total:", 
							COLUMN 53, l_tran_amt USING "------------&.&&" 
							PRINT COLUMN 20, "Comp. total:", 
							COLUMN 53, ( p_stmt_line[150,166] /100 ) 
							USING "------------&.&&", 
							COLUMN 80, p_stmt_line[174,250] clipped 
						WHEN '2' 
							PRINT COLUMN 20, "No. of transactions:", 
							COLUMN 63, p_stmt_line[60,65] USING "#####&" 
							PRINT COLUMN 20, "No. of transactions computed:", 
							COLUMN 63, p_stmt_line[167,172] USING "#####&", 
							COLUMN 80, p_stmt_line[174,250] clipped 
						WHEN '3' 
							PRINT COLUMN 20, "No. of debits:", 
							COLUMN 65, p_stmt_line[18,22] USING "###&" 
							PRINT COLUMN 20, "No. of Debits computed:", 
							COLUMN 65, p_stmt_line[125,129] USING "###&", 
							COLUMN 80, p_stmt_line[174,250] clipped 
						WHEN '4' 
							PRINT COLUMN 20, "Debit total:", 
							COLUMN 53, ( p_stmt_line[3,17] / 100 ) 
							USING "------------&.&&" 
							PRINT COLUMN 20, "Comp. total:", 
							COLUMN 53, ( p_stmt_line[110,124] / 100 ) 
							USING "------------&.&&", 
							COLUMN 80, p_stmt_line[174,250] clipped 
						WHEN '5' 
							PRINT COLUMN 20, "No. of credits:", 
							COLUMN 65, p_stmt_line[38,42] USING "###&" 
							PRINT COLUMN 20, "No. of Credits computed:", 
							COLUMN 65, p_stmt_line[145,149] USING "###&", 
							COLUMN 80, p_stmt_line[174,250] clipped 
						WHEN '6' 
							PRINT COLUMN 20, "Cred. total:", 
							COLUMN 53, ( p_stmt_line[23,37] / 100 ) 
							USING "------------&.&&" 
							PRINT COLUMN 20, "Comp. total:", 
							COLUMN 53, ( p_stmt_line[130,144] / 100 ) 
							USING "------------&.&&", 
							COLUMN 80, p_stmt_line[174,250] clipped 
						WHEN '7' 
							PRINT COLUMN 01, "** This Bank Sheet will NOT be loaded INTO ", 
							"database. Transaction are listed FOR REPORT purposes only." 
						OTHERWISE 
							PRINT COLUMN 20, "Account total:", 
							COLUMN 53, l_tran_amt USING "------------&.&&", 
							COLUMN 80, "Account IS in balance" 
					END CASE 
				WHEN '90' 
				WHEN '99' 
			END CASE 

		ON LAST ROW 
			NEED 6 LINES 
			SKIP 4 LINES 
			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	
			
END REPORT 


