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
# \brief module GCL  Loads bank statement details directly FROM an interface
#              file provided by banking groups. Transactions will also
#              be reconciled WHERE sufficient information exists.
#

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

###########################################################################
# FUNCTION anz_stmt_load(p_type_code)
#
#
###########################################################################
FUNCTION anz_stmt_load(p_type_code)
	DEFINE p_type_code LIKE banktype.type_code
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_banktype RECORD LIKE banktype.* 	
	DEFINE l_rec_banktypedetl RECORD LIKE banktypedetl.* 
	DEFINE l_rec_bank RECORD LIKE bank.* 
	DEFINE l_rec_stmthead RECORD LIKE bankstatement.* 
	DEFINE l_rec_stmthead2 RECORD LIKE bankstatement.* 
	DEFINE l_rec_balance RECORD 
		balance_date DATE, 
		acc_num char(40), 
		acc_source char(10), 
		acc_num_format char(1), 
		acc_name char(40), 
		currency_code char(3), 
		open_bal decimal(16,2), 
		close_bal decimal(16,2), 
		dr_movement decimal(16,2), 
		no_debits INTEGER, 
		cr_movement decimal(16,2), 
		no_credits INTEGER, 
		dr_int_rate decimal(16,4), 
		cr_int_rate decimal(16,4), 
		overdraft_lmt decimal(16,2), 
		dr_int_arrd decimal(16,2), 
		cr_int_accrd decimal(16,2), 
		fid_accrd decimal(16,2), 
		badt_accrd decimal(16,2), 
		next_process_date DATE 
	END RECORD 
	DEFINE l_rec_transaction RECORD 
		tran_date DATE, 
		acc_num char(40), 
		acc_source char(10), 
		acc_num_format char(1), 
		acc_name char(40), 
		currency_code char(3), 
		subacc_name char(40), 
		trans_type char(10), 
		reference char(10), 
		amount decimal(16,2), 
		trans_text char(30), 
		effective_date DATE, 
		trace_id char(12), 
		tran_code char(3), 
		auxdom char(10) 
	END RECORD 
	DEFINE l_dr_cnt SMALLINT 
	DEFINE l_cr_cnt SMALLINT 
	DEFINE l_check_bal decimal(16,2) 
	DEFINE l_debit_amt decimal(16,2) 
	DEFINE l_credit_amt decimal(16,2) 

	DEFINE l_next_balance_date DATE 
	DEFINE l_act_file_tot INTEGER 
	DEFINE l_act_file_cnt SMALLINT 
	DEFINE l_rpt_output char(50) 
	DEFINE l_err_cnt SMALLINT 
	DEFINE l_err_message char(80) 
	DEFINE l_err_message2 char(80) 
	DEFINE l_length SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 


	MESSAGE kandoomsg2("G",1002,"") 
	SELECT * INTO p_rec_banktype.* FROM banktype 
	WHERE type_code = p_type_code 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
--	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
--		LET int_flag = false 
--		LET quit_flag = false
--
--		RETURN FALSE
--	END IF

	LET l_rpt_idx = rpt_start("GCL-C","GCL_rpt_list_c_anz","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT GCL_rpt_list_c_anz TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0
--	LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GCL_rpt_list_c_anz")].sel_text
	#------------------------------------------------------------
	
	##
	## Work through each line of the load file
	##
	DECLARE c_balance CURSOR FOR 
	SELECT * FROM t_balance 
	ORDER BY balance_date 
	SELECT count(*) INTO l_act_file_tot FROM t_balance 
	LET l_err_cnt = 0 
	FOREACH c_balance INTO l_rec_balance.* 
		LET l_err_message = NULL 
		LET l_err_message2 = NULL 
		INITIALIZE l_rec_stmthead.* TO NULL 
		LET l_act_file_cnt = l_act_file_cnt + 1 
		DISPLAY " Validating Sheet ",l_act_file_cnt," OF ",l_act_file_tot TO lblabel2 

		LET glob_stmt_date = l_rec_balance.balance_date 
		LET l_length = length(l_rec_balance.acc_num) 
		CALL validate_anz_bank(l_rec_balance.acc_num[1,6], 
		l_rec_balance.acc_num[7,l_length], 
		l_rec_balance.currency_code) 
		RETURNING l_rec_bank.*, l_err_message 
		LET l_rec_stmthead.cmpy_code = l_rec_bank.cmpy_code 
		LET l_rec_stmthead.bank_code = l_rec_bank.bank_code 
		LET l_rec_stmthead.sheet_num = NULL 
		##
		## Allocate sheet number FROM max(t_stmthead) in CASE
		## two entries FOR same bank OTHERWISE use bankstatement
		##
		SELECT (max(sheet_num)+1) INTO l_rec_stmthead.sheet_num FROM t_stmthead 
		WHERE cmpy_code = l_rec_bank.cmpy_code 
		AND bank_code = l_rec_bank.bank_code 
		AND entry_type_code = "SH" 
		IF l_rec_stmthead.sheet_num IS NULL THEN 
			SELECT (max(sheet_num)+1) INTO l_rec_stmthead.sheet_num FROM bankstatement 
			WHERE cmpy_code = l_rec_bank.cmpy_code 
			AND bank_code = l_rec_bank.bank_code 
			AND entry_type_code = "SH" 
			IF l_rec_stmthead.sheet_num IS NULL THEN 
				LET l_rec_stmthead.sheet_num = 1 
			END IF 
		END IF 
		LET l_rec_stmthead.seq_num = 0 
		LET l_rec_stmthead.entry_type_code = "SH" 
		LET l_rec_stmthead.tran_date = l_rec_balance.balance_date 
		LET l_rec_stmthead.tran_amt = l_rec_balance.close_bal 
		LET l_rec_stmthead.bank_currency_code = l_rec_bank.currency_code 
		LET l_rec_stmthead.ref_currency_code = l_rec_bank.currency_code 
		LET l_rec_stmthead.acct_code = l_rec_bank.acct_code 
		IF l_rec_stmthead.tran_amt IS NULL THEN 
			LET l_rec_stmthead.tran_amt = 0 
		END IF 
		LET l_rec_stmthead.desc_text = "Statement header" 
		LET l_rec_stmthead.doc_num = 0 
		LET l_rec_stmthead.ref_text = l_rec_balance.next_process_date 
		IF l_rec_stmthead.sheet_num > 1 THEN 
			SELECT * INTO l_rec_stmthead2.* FROM t_stmthead 
			WHERE cmpy_code = l_rec_bank.cmpy_code 
			AND bank_code = l_rec_bank.bank_code 
			AND entry_type_code = "SH" 
			AND sheet_num = l_rec_stmthead.sheet_num - 1 
			IF status = NOTFOUND THEN 
				SELECT * INTO l_rec_stmthead2.* FROM bankstatement 
				WHERE cmpy_code = l_rec_bank.cmpy_code 
				AND bank_code = l_rec_bank.bank_code 
				AND entry_type_code = "SH" 
				AND sheet_num = l_rec_stmthead.sheet_num - 1 
			END IF 
			LET l_next_balance_date = l_rec_stmthead2.ref_text 
			IF l_next_balance_date != l_rec_balance.balance_date THEN 
				LET l_err_cnt = l_err_cnt + 1 
				LET l_err_message2 = "## statement date does not", 
				" match next date FROM last sheet" 
				OUTPUT TO REPORT GCL_rpt_list_c_anz(p_rec_banktype.type_code, 
				l_rec_stmthead.*, 
				l_rec_balance.*, 
				l_rec_transaction.*, 
				l_err_message,l_err_message2) 
				EXIT FOREACH 
			END IF 
		END IF 
		IF l_rec_bank.bank_code IS NOT NULL THEN 
			INSERT INTO t_stmthead VALUES (l_rec_stmthead.*) 
		ELSE 
			LET l_err_cnt = l_err_cnt + 1 
		END IF 
		OUTPUT TO REPORT GCL_rpt_list_c_anz(p_rec_banktype.type_code,l_rec_stmthead.*, 
		l_rec_balance.*,l_rec_transaction.*, 
		l_err_message,l_err_message2) 
		DECLARE c_transaction CURSOR FOR 
		SELECT * FROM t_transaction 
		WHERE tran_date = l_rec_balance.balance_date 
		AND acc_num = l_rec_balance.acc_num 
		AND acc_source = l_rec_balance.acc_source 
		AND acc_num_format = l_rec_balance.acc_num_format 
		LET l_dr_cnt = 0 
		LET l_cr_cnt = 0 
		LET l_debit_amt = 0 
		LET l_credit_amt = 0 
		FOREACH c_transaction INTO l_rec_transaction.* 
			LET l_rec_stmthead.seq_num = l_rec_stmthead.seq_num + 1 
			LET l_rec_stmthead.desc_text = l_rec_transaction.trans_text 
			LET l_rec_stmthead.tran_date = l_rec_transaction.tran_date 
			SELECT * INTO l_rec_banktypedetl.* FROM banktypedetl 
			WHERE type_code = p_rec_banktype.type_code 
			AND bank_ref_code = l_rec_transaction.trans_type 
			IF status = NOTFOUND THEN 
				IF l_rec_transaction.amount < 0 THEN 
					LET l_rec_stmthead.entry_type_code = "BC" 
				ELSE 
					LET l_rec_stmthead.entry_type_code = "SC" 
				END IF 
				LET l_err_cnt = l_err_cnt + 1 
			ELSE 
				LET l_rec_stmthead.entry_type_code = l_rec_banktypedetl.max_ref_code 
			END IF 
			IF l_rec_stmthead.entry_type_code = "CH" THEN 
				LET l_rec_stmthead.ref_code = l_rec_transaction.reference 
			ELSE 
				LET l_rec_stmthead.ref_code = NULL 
			END IF 
			LET l_rec_stmthead.ref_text = l_rec_transaction.reference 
			IF l_rec_transaction.amount < 0 THEN 
				LET l_rec_stmthead.tran_amt = l_rec_transaction.amount * -1 
				LET l_dr_cnt = l_dr_cnt + 1 
				LET l_debit_amt = l_debit_amt + l_rec_stmthead.tran_amt 
			ELSE 
				LET l_rec_stmthead.tran_amt = l_rec_transaction.amount 
				LET l_cr_cnt = l_cr_cnt + 1 
				LET l_credit_amt = l_credit_amt + l_rec_stmthead.tran_amt 
			END IF 
			LET l_length = length(l_rec_transaction.acc_num) 
			CALL validate_anz_bank(l_rec_transaction.acc_num[1,6], 
			l_rec_transaction.acc_num[7,l_length], 
			l_rec_transaction.currency_code) 
			RETURNING l_rec_bank.*, l_err_message 
			IF l_rec_bank.bank_code IS NOT NULL THEN 
				INSERT INTO t_stmthead VALUES (l_rec_stmthead.*) 
			ELSE 
				LET l_err_cnt = l_err_cnt + 1 
			END IF 
			OUTPUT TO REPORT GCL_rpt_list_c_anz(p_rec_banktype.type_code,l_rec_stmthead.*, 
			l_rec_balance.*,l_rec_transaction.*, 
			l_err_message,l_err_message2) 
		END FOREACH 
		LET l_check_bal = l_rec_balance.open_bal + l_credit_amt - l_debit_amt 
		IF l_dr_cnt != l_rec_balance.no_debits 
		OR l_cr_cnt != l_rec_balance.no_credits 
		OR l_debit_amt != l_rec_balance.dr_movement 
		OR l_credit_amt != l_rec_balance.cr_movement 
		OR l_check_bal != l_rec_balance.close_bal THEN 
			LET l_err_cnt = l_err_cnt + 1 
		END IF 
		LET l_rec_stmthead.entry_type_code = "##" 
		OUTPUT TO REPORT GCL_rpt_list_c_anz(p_rec_banktype.type_code,l_rec_stmthead.*, 
		l_rec_balance.*,l_rec_transaction.*, 
		l_err_message,l_err_message2) 
	END FOREACH 


	#------------------------------------------------------------
	FINISH REPORT GCL_rpt_list_c_anz
	CALL rpt_finish("GCL_rpt_list_c_anz")
	#------------------------------------------------------------	
	
	IF l_err_cnt > 0 THEN 
		CALL fgl_winmessage("Error",kandoomsg2("G",7024,""),"ERROR")	#7024 " ERRORS encountered during ANZ load - Refer audit REPORT"
	END IF 
END FUNCTION 


############################################################
# FUNCTION validate_anz_bank(p_bic_code,p_acct_code,p_curr_code)
#
#
# This FUNCTION identifies that "bank" table entry corresponding
# TO the account being loaded.
#
############################################################
FUNCTION validate_anz_bank(p_bic_code,p_acct_code,p_curr_code) 
	DEFINE p_acct_code LIKE bank.iban 
	DEFINE p_bic_code LIKE bank.bic_code 
	DEFINE p_curr_code LIKE bank.currency_code 
	DEFINE l_rec_bank RECORD LIKE bank.* 
	DEFINE l_rec_bankstatement RECORD LIKE bankstatement.* 
	DEFINE l_bank_cnt SMALLINT 
	DEFINE l_err_message char(80) 

	##
	## Need TO know how many times this bank has been setup in KandooERP
	##
	LET l_bank_cnt = 0 
	SELECT count(*) INTO l_bank_cnt FROM bank 
	WHERE iban = p_acct_code 
	AND bic_code = p_bic_code 
	AND currency_code = p_curr_code 
	CASE 
		WHEN l_bank_cnt = 0 
			## Bank NOT setup
			LET l_err_message = 
			" Account no. ",p_acct_code clipped," does NOT exist **" 
		WHEN l_bank_cnt = 1 
			## Bank setup once
			SELECT * INTO l_rec_bank.* FROM bank 
			WHERE iban = p_acct_code 
			AND bic_code = p_bic_code 
			AND currency_code = p_curr_code 
		OTHERWISE 
			## Bank setup multiple times
			## IF it IS setup FOR the current company THEN use this entry.
			## OTHERWISE do NOT make assumptions AND REPORT an error.
			DECLARE c_bank CURSOR FOR 
			SELECT * FROM bank 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND iban = p_acct_code 
			AND bic_code = p_bic_code 
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
		AND tran_date = glob_stmt_date 
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
# REPORT GCL_rpt_list_c_anz(p_type_code,p_rec_stmthead,p_rec_balance, p_rec_transaction,p_err_message,p_err_message2)
#
#
############################################################
REPORT GCL_rpt_list_c_anz(p_rpt_idx,p_type_code,p_rec_stmthead,p_rec_balance, p_rec_transaction,p_err_message,p_err_message2)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_type_code LIKE banktype.type_code 
	DEFINE p_rec_stmthead RECORD LIKE bankstatement.* 
	DEFINE p_err_message char(80) 
	DEFINE p_err_message2 char(80) 
	DEFINE p_rec_balance 
	RECORD 
		balance_date DATE, 
		acc_num char(40), 
		acc_source char(10), 
		acc_num_format char(1), 
		acc_name char(40), 
		currency_code char(3), 
		open_bal decimal(16,2), 
		close_bal decimal(16,2), 
		dr_movement decimal(16,2), 
		no_debits INTEGER, 
		cr_movement decimal(16,2), 
		no_credits INTEGER, 
		dr_int_rate decimal(16,4), 
		cr_int_rate decimal(16,4), 
		overdraft_lmt decimal(16,2), 
		dr_int_arrd decimal(16,2), 
		cr_int_accrd decimal(16,2), 
		fid_accrd decimal(16,2), 
		badt_accrd decimal(16,2), 
		next_process_date DATE 
	END RECORD 
	DEFINE p_rec_transaction RECORD 
		tran_date DATE, 
		acc_num char(40), 
		acc_source char(10), 
		acc_num_format char(1), 
		acc_name char(40), 
		currency_code char(3), 
		subacc_name char(40), 
		trans_type char(10), 
		reference char(10), 
		amount decimal(16,2), 
		trans_text char(30), 
		effective_date DATE, 
		trace_id char(12), 
		tran_code char(3), 
		auxdom char(10) 
	END RECORD 

	DEFINE l_head_reqd SMALLINT 
	DEFINE l_arr_line array[4] OF char(132) 
	DEFINE l_diff_amt LIKE bankstatement.tran_amt 
	DEFINE l_check_bal LIKE bankstatement.tran_amt 
	DEFINE l_dr_cnt SMALLINT 
	DEFINE l_cr_cnt SMALLINT 
	DEFINE l_debit_amt decimal(16,2) 
	DEFINE l_credit_amt decimal(16,2) 
	DEFINE l_length SMALLINT 

	OUTPUT 
	left margin 0 
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			LET l_head_reqd = true 
		ON EVERY ROW 
			CASE p_rec_stmthead.entry_type_code 
				WHEN "SH" 
					SKIP TO top OF PAGE 
					LET l_length = length(p_rec_balance.acc_num) 
					PRINT COLUMN 01, "Statement Date - ", 
					COLUMN 18, p_rec_balance.balance_date USING "dd/mm/yy" 
					PRINT COLUMN 01, "Account - ", 
					COLUMN 11, p_rec_balance.acc_num[7,l_length], 
					COLUMN 32, "Opening Bal - ", 
					COLUMN 46, p_rec_balance.open_bal USING "--,---,--&.&&" 
					PRINT COLUMN 01, "Currency - ", 
					COLUMN 12, p_rec_balance.currency_code, 
					COLUMN 37, "Credits:", 
					COLUMN 46, p_rec_balance.cr_movement USING "--,---,--&.&&", 
					COLUMN 60, "Trans - ", 
					COLUMN 68, p_rec_balance.no_credits USING "######&" 
					PRINT COLUMN 37, "Debits:", 
					COLUMN 46, p_rec_balance.dr_movement USING "--,---,--&.&&", 
					COLUMN 60, "Trans - ", 
					COLUMN 68, p_rec_balance.no_debits USING "######&" 
					PRINT COLUMN 32, "Closing Bal - ", 
					COLUMN 46, p_rec_balance.close_bal USING "--,---,--&.&&" 
					SKIP 1 LINES 
					IF p_rec_stmthead.bank_code IS NULL THEN 
						PRINT COLUMN 01,"** This Bank Sheet will NOT be loaded INTO ", 
						"database. Transaction are listed FOR REPORT purposes only." 
						SKIP 1 line 
					END IF 
					IF p_err_message IS NOT NULL THEN 
						PRINT COLUMN 01, p_err_message 
						SKIP 1 line 
					END IF 
					IF p_err_message2 IS NOT NULL THEN 
						PRINT COLUMN 01, p_err_message2 
						SKIP 1 line 
					END IF 
					PRINT COLUMN 01,"--------------------------------------------", 
					"--------------------------------------------" 
					PRINT COLUMN 01,"Type", 
					COLUMN 06,"Trans code", 
					COLUMN 25,"Debit", 
					COLUMN 38,"Credit", 
					COLUMN 45,"Reference", 
					COLUMN 57,"Text" 
					PRINT COLUMN 01,"--------------------------------------------", 
					"--------------------------------------------" 
					LET l_head_reqd = false 
				WHEN "##" 
					SKIP 1 LINES 
					SELECT count(*) INTO l_dr_cnt FROM t_transaction 
					WHERE tran_date = p_rec_balance.balance_date 
					AND acc_num = p_rec_balance.acc_num 
					AND acc_source = p_rec_balance.acc_source 
					AND acc_num_format = p_rec_balance.acc_num_format 
					AND amount < 0 
					IF l_dr_cnt != p_rec_balance.no_debits THEN 
						PRINT COLUMN 01, "## Number of debits computed out of balance" 
					END IF 
					SELECT count(*) INTO l_cr_cnt FROM t_transaction 
					WHERE tran_date = p_rec_balance.balance_date 
					AND acc_num = p_rec_balance.acc_num 
					AND acc_source = p_rec_balance.acc_source 
					AND acc_num_format = p_rec_balance.acc_num_format 
					AND amount > 0 
					IF l_cr_cnt != p_rec_balance.no_credits THEN 
						PRINT COLUMN 01, "## Number of credits computed out of balance" 
					END IF 
					SELECT (sum(amount)*-1) INTO l_debit_amt FROM t_transaction 
					WHERE tran_date = p_rec_balance.balance_date 
					AND acc_num = p_rec_balance.acc_num 
					AND acc_source = p_rec_balance.acc_source 
					AND acc_num_format = p_rec_balance.acc_num_format 
					AND amount < 0 
					IF l_debit_amt != p_rec_balance.dr_movement THEN 
						PRINT COLUMN 01, "## Debit total out of balance" 
					END IF 
					SELECT sum(amount) INTO l_credit_amt FROM t_transaction 
					WHERE tran_date = p_rec_balance.balance_date 
					AND acc_num = p_rec_balance.acc_num 
					AND acc_source = p_rec_balance.acc_source 
					AND acc_num_format = p_rec_balance.acc_num_format 
					AND amount > 0 
					IF l_credit_amt != p_rec_balance.cr_movement THEN 
						PRINT COLUMN 01, "## Credit total out of balance" 
					END IF 
					LET l_check_bal = p_rec_balance.open_bal + l_credit_amt - l_debit_amt 
					IF l_check_bal != p_rec_balance.close_bal THEN 
						IF l_check_bal > p_rec_balance.close_bal THEN 
							LET l_diff_amt = l_check_bal - p_rec_balance.close_bal 
						ELSE 
							LET l_diff_amt = p_rec_balance.close_bal - l_check_bal 
						END IF 
						PRINT COLUMN 01, "## Computed balance differs FROM ", 
						"closing balance by: ", 
						COLUMN 54, l_diff_amt USING "--,---,--&.&&" 
					END IF 
				OTHERWISE 
					NEED 3 LINES 
					LET l_length = length(p_rec_balance.acc_num) 
					IF l_head_reqd THEN 
						PRINT COLUMN 01, "Statement Date - ", 
						COLUMN 18, p_rec_balance.balance_date USING "dd/mm/yy" 
						PRINT COLUMN 01, "Account - ", 
						COLUMN 11, p_rec_balance.acc_num[7,l_length], 
						COLUMN 32, "Opening Bal - ", 
						COLUMN 46, p_rec_balance.open_bal USING "--,---,--&.&&" 
						PRINT COLUMN 01, "Currency - ", 
						COLUMN 12, p_rec_balance.currency_code, 
						COLUMN 37, "Credits:", 
						COLUMN 46, p_rec_balance.cr_movement USING "--,---,--&.&&", 
						COLUMN 60, "Trans - ", 
						COLUMN 68, p_rec_balance.no_credits USING "######&" 
						PRINT COLUMN 37, "Debits:", 
						COLUMN 46, p_rec_balance.dr_movement USING "--,---,--&.&&", 
						COLUMN 60, "Trans - ", 
						COLUMN 68, p_rec_balance.no_debits USING "######&" 
						PRINT COLUMN 32, "Closing Bal - ", 
						COLUMN 46, p_rec_balance.close_bal USING "--,---,--&.&&" 
						SKIP 1 LINES 
						IF p_rec_stmthead.bank_code IS NULL THEN 
							PRINT COLUMN 01,"** This Bank Sheet will NOT be loaded INTO ", 
							"database. Transaction are listed FOR REPORT purposes only." 
							SKIP 1 line 
						END IF 
						IF p_err_message IS NOT NULL THEN 
							PRINT COLUMN 01, p_err_message 
							SKIP 1 line 
						END IF 
						IF p_err_message2 IS NOT NULL THEN 
							PRINT COLUMN 01, p_err_message2 
							SKIP 1 line 
						END IF 
						PRINT COLUMN 01,"--------------------------------------------", 
						"--------------------------------------------" 
						PRINT COLUMN 01,"Type", 
						COLUMN 06,"Trans code", 
						COLUMN 25,"Debit", 
						COLUMN 38,"Credit", 
						COLUMN 45,"Reference", 
						COLUMN 57,"Text" 
						PRINT COLUMN 01,"--------------------------------------------", 
						"--------------------------------------------" 
						LET l_head_reqd = false 
					END IF 
					IF p_rec_transaction.amount < 0 THEN 
						PRINT COLUMN 01, p_rec_stmthead.entry_type_code, 
						COLUMN 06, p_rec_transaction.trans_type, 
						COLUMN 17, p_rec_stmthead.tran_amt USING "--,---,--&.&&", 
						COLUMN 45, p_rec_transaction.reference, 
						COLUMN 57, p_rec_stmthead.desc_text 
					ELSE 
						PRINT COLUMN 01, p_rec_stmthead.entry_type_code, 
						COLUMN 06, p_rec_transaction.trans_type, 
						COLUMN 31, p_rec_stmthead.tran_amt USING "--,---,--&.&&", 
						COLUMN 45, p_rec_transaction.reference, 
						COLUMN 57, p_rec_stmthead.desc_text 
					END IF 
					SELECT * FROM banktypedetl 
					WHERE type_code = p_type_code 
					AND bank_ref_code = p_rec_transaction.trans_type 
					IF status = NOTFOUND THEN 
						PRINT COLUMN 01, "Transaction Type NOT found - Default bc/sc", 
						" used - Refer menu path gzt" 
					END IF 
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