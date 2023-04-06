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
# \file
# \brief module GCEg - European Cash Book Entry & Reconciliation
#                      Close & Post FUNCTION
###########################################################################

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl"
GLOBALS "../gl/GC_GROUP_GLOBALS.4gl" 
GLOBALS "../gl/GCE_GLOBALS.4gl"
###########################################################################
# MODULE Scope Variables
###########################################################################

###########################################################################
# FUNCTION close_sheet()
#
#
###########################################################################
FUNCTION close_sheet() 
	DEFINE l_rec_cbaudit RECORD LIKE cbaudit.* 
	DEFINE l_rec_banking RECORD LIKE banking.* 
	DEFINE l_rec_batchhead RECORD LIKE batchhead.* 
	DEFINE l_rec_batchdetl RECORD LIKE batchdetl.* 
	DEFINE l_rec_bankdetails RECORD LIKE bankdetails.* 
	DEFINE l_rec_bankstatement RECORD LIKE bankstatement.* 
	DEFINE l_rec_t_bankstatement RECORD LIKE bankstatement.* 
	DEFINE l_rec_cashreceipt RECORD LIKE cashreceipt.* 
	DEFINE l_rec_s_cashreceipt RECORD LIKE cashreceipt.* 
	DEFINE l_rec_userlocn RECORD LIKE userlocn.* 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_corpcust RECORD LIKE customer.* 
	DEFINE l_rec_araudit RECORD LIKE araudit.* 
	DEFINE l_rec_invoicehead RECORD LIKE invoicehead.* 
	DEFINE l_rec_invoicepay RECORD LIKE invoicepay.* 
	DEFINE l_rec_s_invoicepay RECORD LIKE invoicepay.* 
	DEFINE l_rec_cheque RECORD LIKE cheque.* 
	DEFINE l_rec_arparms RECORD LIKE arparms.* 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_apaudit RECORD LIKE apaudit.* 
	DEFINE l_rec_voucher RECORD LIKE voucher.* 
	DEFINE l_rec_voucherpays RECORD LIKE voucherpays.* 
	DEFINE l_rec_exchangevar RECORD LIKE exchangevar.* 
	DEFINE l_err_message char(60) 
	DEFINE l_err_continue char(1) 
	DEFINE l_audit_amt LIKE bankstatement.tran_amt 
	DEFINE l_difference LIKE bankstatement.tran_amt 
	DEFINE l_cust_code LIKE customer.cust_code 
	DEFINE l_last_cbaudit_row INTEGER 
	DEFINE l_cleared_flag LIKE batchhead.cleared_flag 
	DEFINE l_acct_mask LIKE customertype.acct_mask_code 
	DEFINE l_cred_days_given LIKE customer.cred_taken_num 
	DEFINE l_cred_days_taken LIKE customer.cred_taken_num 

	DEFINE l_late_pay LIKE customer.late_pay_num 
	DEFINE l_total_applied LIKE invoicehead.total_amt 
	DEFINE l_total_disc LIKE invoicehead.total_amt 

	DEFINE l_base_apply_amt1 LIKE exchangevar.exchangevar_amt 
	DEFINE l_base_apply_amt2 LIKE exchangevar.exchangevar_amt 

	DEFINE l_error_line char(80) 
	DEFINE l_prev_entry_type LIKE bankstatement.entry_type_code 
	DEFINE l_create_new_batch SMALLINT 
	DEFINE l_no_of_lines SMALLINT 

	DEFINE l_invoice_age INTEGER 
	DEFINE l_receipt_age INTEGER 

	DEFINE l_pay_doc_num INTEGER 
	DEFINE l_call_status INTEGER 
	DEFINE l_db_status INTEGER 

	DEFINE l_jour_num LIKE glparms.next_jour_num 
	DEFINE l_call_message char(80) 
	DEFINE l_com1_text LIKE cancelcheq.com1_text 
	DEFINE l_com2_text LIKE cancelcheq.com1_text 
	DEFINE l_msgresp LIKE language.yes_flag 

	SELECT * INTO l_rec_arparms.* 
	FROM arparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parm_code = "1" 
	IF sqlca.sqlcode = NOTFOUND THEN 
		LET l_msgresp = kandoomsg("A",5002,"") 
		#5002 " AR Parameters are NOT found"
		RETURN false 
	END IF 

	--	OPEN WINDOW w1_GCEg WITH FORM "U999" ATTRIBUTES(BORDER)
	--	CALL windecoration_u("U999")

	SELECT max(seq_num) INTO l_no_of_lines 
	FROM bankstatement 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND bank_code = glob_rec_bank.bank_code 
	AND sheet_num = glob_rec_bank.sheet_num 
	#   DISPLAY "  Closing Bank Statement Sheet Number: ",
	#             glob_rec_bank.sheet_num using "<<<<<" TO lbLabel1
	#
	#   DISPLAY " Updating Bank Statement Line No:" TO lbLabel2
	#
	#   DISPLAY " of ",l_no_of_lines using "<<<<<" TO lbLabel2b
	MESSAGE "Closing Bank Statement Sheet Number: ", glob_rec_bank.sheet_num USING "<<<<<" , " Updating Bank Statement Line no:", trim(0), " of ", l_no_of_lines USING "<<<<<" #need TO find the variable which represents the line no 

	GOTO bypass 
	LABEL recovery: 
	LET l_err_continue = error_recover(l_err_message, status) 
	IF l_err_continue != "Y" THEN 
		EXIT PROGRAM 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	BEGIN WORK 
		LET l_err_message = "Locking Banking tables" 
		LOCK TABLE bankstatement in share MODE 
		LOCK TABLE bankdetails in share MODE 
		DECLARE c_glparms CURSOR FOR 
		SELECT glparms.* FROM glparms 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND key_code = "1" 
		FOR UPDATE 
		OPEN c_glparms 
		FETCH c_glparms INTO glob_rec_glparms.* 
		#
		# IF batch clearing IS required, SET all batch cleared flags TO "N"
		#
		IF glob_rec_glparms.use_clear_flag = "Y" THEN 
			LET l_cleared_flag = "N" 
		ELSE 
			LET l_cleared_flag = "Y" 
		END IF 
		LET l_prev_entry_type = "zz" 
		DECLARE c2_bankstatement CURSOR FOR 
		SELECT * FROM bankstatement 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND bank_code = glob_rec_bank.bank_code 
		AND sheet_num = glob_rec_bank.sheet_num 
		AND seq_num != 0 ## exclude HEADER recs 
		ORDER BY entry_type_code, seq_num 
		FOREACH c2_bankstatement INTO l_rec_bankstatement.* 
			IF l_rec_bankstatement.entry_type_code != l_prev_entry_type THEN 
				LET l_prev_entry_type = l_rec_bankstatement.entry_type_code 
				LET l_create_new_batch = true 
			END IF 
			DISPLAY l_rec_bankstatement.seq_num USING "<<<<" TO lblabel2b 

			INITIALIZE l_rec_batchdetl.* TO NULL 
			INITIALIZE l_rec_banking.* TO NULL 
			INITIALIZE l_rec_cbaudit.* TO NULL 
			CASE 
			#
			# BC - Bank Charges
			#
				WHEN l_rec_bankstatement.entry_type_code = "BC" 
					##
					## BC transactions either create an entry OR tick off
					## an entry created in GC2.  IF only a tiack off IS required
					## THEN the doc_num contains a serial number of banking entry.
					##
					IF l_rec_bankstatement.doc_num > 0 THEN 
						LET l_err_message = "Updating Banking Table - bc" 
						UPDATE banking 
						SET bk_rec_part = null, 
						bk_sh_no = glob_rec_bank.sheet_num, 
						bk_seq_no = l_rec_bankstatement.seq_num 
						WHERE doc_num = l_rec_bankstatement.doc_num 
					ELSE 
						IF l_create_new_batch THEN 
							LET l_create_new_batch = false 
							LET l_audit_amt = 0 
							INITIALIZE l_rec_batchhead.* TO NULL 
							LET glob_rec_glparms.next_jour_num = glob_rec_glparms.next_jour_num + 1 
							LET l_rec_batchhead.cmpy_code = l_rec_bankstatement.cmpy_code 
							LET l_rec_batchhead.jour_code = glob_rec_glparms.cb_code 
							LET l_rec_batchhead.jour_num = glob_rec_glparms.next_jour_num 
							LET l_rec_batchhead.entry_code = l_rec_bankstatement.entry_code 
							LET l_rec_batchhead.jour_date = today 
							LET l_rec_batchhead.year_num = l_rec_bankstatement.year_num 
							LET l_rec_batchhead.period_num = l_rec_bankstatement.period_num 
							LET l_rec_batchhead.control_amt = 0 
							LET l_rec_batchhead.debit_amt = 0 
							LET l_rec_batchhead.credit_amt = 0 
							LET l_rec_batchhead.control_qty = 0 
							LET l_rec_batchhead.stats_qty = 0 
							LET l_rec_batchhead.currency_code = 
							l_rec_bankstatement.bank_currency_code 
							LET l_rec_batchhead.conv_qty = l_rec_bankstatement.conv_qty 
							LET l_rec_batchhead.for_debit_amt = 0 
							LET l_rec_batchhead.for_credit_amt = 0 
							LET l_rec_batchhead.source_ind = "C" 
							LET l_rec_batchhead.post_flag = "N" 
							LET l_rec_batchhead.seq_num = 0 
							LET l_rec_batchhead.com1_text = l_rec_bankstatement.com1_text 
							LET l_rec_batchhead.com2_text = l_rec_bankstatement.com2_text 
							LET l_rec_batchhead.cleared_flag = l_cleared_flag 
							LET l_rec_batchhead.post_run_num = 0 
							LET l_rec_batchhead.consol_num = 0 
							LET l_rec_batchhead.rate_type_ind = "S" 
							LET l_err_message= "Inserting Batch Header Table - bc" 

							CALL fgl_winmessage("14 Learning batch head codes - tell Hubert",l_rec_batchhead.source_ind,"info") 
							INSERT INTO batchhead VALUES (l_rec_batchhead.*) 
						END IF 
						LET l_rec_banking.bk_cmpy = glob_rec_kandoouser.cmpy_code 
						LET l_rec_banking.bk_acct = l_rec_bankstatement.acct_code 
						LET l_rec_banking.bk_type = l_rec_bankstatement.entry_type_code 
						LET l_rec_banking.bk_bankdt = l_rec_bankstatement.tran_date 
						LET l_rec_banking.bk_desc = "Direct charges" 
						LET l_rec_banking.bk_sh_no = l_rec_bankstatement.sheet_num 
						LET l_rec_banking.bk_seq_no = l_rec_bankstatement.seq_num 
						INITIALIZE l_rec_banking.bk_rec_part TO NULL 
						LET l_rec_banking.bk_year = l_rec_bankstatement.year_num 
						LET l_rec_banking.bk_per = l_rec_bankstatement.period_num 
						LET l_rec_banking.bk_debit = l_rec_bankstatement.tran_amt 
						LET l_rec_banking.bk_enter = l_rec_bankstatement.entry_code 
						LET l_rec_banking.doc_num = 0 
						LET l_err_message = "Inserting Banking Table - bc" 
						INSERT INTO banking VALUES (l_rec_banking.*) 
						LET l_rec_batchdetl.cmpy_code = l_rec_batchhead.cmpy_code 
						LET l_rec_batchdetl.jour_code = l_rec_batchhead.jour_code 
						LET l_rec_batchdetl.jour_num = l_rec_batchhead.jour_num 
						LET l_rec_batchhead.seq_num = l_rec_batchhead.seq_num + 1 
						LET l_rec_batchdetl.seq_num = l_rec_batchhead.seq_num 
						LET l_rec_batchdetl.tran_type_ind = "CB" 
						LET l_rec_batchdetl.analysis_text = NULL 
						LET l_rec_batchdetl.tran_date = l_rec_bankstatement.tran_date 
						LET l_rec_batchdetl.ref_text = "CB Charges balance" 
						LET l_rec_batchdetl.ref_num = 0 
						LET l_rec_batchdetl.acct_code = l_rec_bankstatement.acct_code 
						LET l_rec_batchdetl.desc_text = l_rec_bankstatement.desc_text 
						LET l_rec_batchdetl.stats_qty = 0 
						LET l_rec_batchdetl.debit_amt = 0 
						LET l_rec_batchdetl.credit_amt = l_rec_bankstatement.tran_amt 
						/ l_rec_bankstatement.conv_qty 
						LET l_rec_batchdetl.currency_code = l_rec_batchhead.currency_code 
						LET l_rec_batchdetl.conv_qty = l_rec_bankstatement.conv_qty 
						LET l_rec_batchdetl.for_debit_amt = 0 
						LET l_rec_batchdetl.for_credit_amt = l_rec_bankstatement.tran_amt 
						LET l_rec_batchdetl.stats_qty = 0 
						IF glob_rec_glparms.use_currency_flag = "N" THEN 
							LET l_rec_batchdetl.for_debit_amt = l_rec_batchdetl.debit_amt 
							LET l_rec_batchdetl.for_credit_amt = l_rec_batchdetl.credit_amt 
							LET l_rec_batchdetl.currency_code = glob_rec_glparms.base_currency_code 
							LET l_rec_batchdetl.conv_qty = 1 
						END IF 
						LET l_err_message="Inserting Batch details Table - bc" 
						INSERT INTO batchdetl VALUES (l_rec_batchdetl.*) 
						LET l_rec_batchhead.credit_amt = l_rec_batchhead.credit_amt 
						+ l_rec_batchdetl.credit_amt 
						LET l_rec_batchhead.for_credit_amt = l_rec_batchhead.for_credit_amt 
						+ l_rec_batchdetl.for_credit_amt 
						DECLARE c1_bankdetails CURSOR FOR 
						SELECT bankdetails.* FROM bankdetails 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND bank_code = l_rec_bankstatement.bank_code 
						AND sheet_num = l_rec_bankstatement.sheet_num 
						AND seq_num = l_rec_bankstatement.seq_num 
						FOREACH c1_bankdetails INTO l_rec_bankdetails.* 
							INITIALIZE l_rec_batchdetl.* TO NULL 
							LET l_rec_batchdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
							LET l_rec_batchdetl.jour_code = l_rec_batchhead.jour_code 
							LET l_rec_batchdetl.jour_num = l_rec_batchhead.jour_num 
							LET l_rec_batchhead.seq_num = l_rec_batchhead.seq_num + 1 
							LET l_rec_batchdetl.seq_num = l_rec_batchhead.seq_num 
							LET l_rec_batchdetl.tran_type_ind = "BC" 
							LET l_rec_batchdetl.analysis_text = l_rec_bankdetails.ref_text 
							LET l_rec_batchdetl.tran_date = l_rec_bankstatement.tran_date 
							LET l_rec_batchdetl.ref_text = "Dir. debit" 
							LET l_rec_batchdetl.ref_num = 0 
							LET l_rec_batchdetl.acct_code = l_rec_bankdetails.acct_code 
							LET l_rec_batchdetl.desc_text = l_rec_bankdetails.desc_text 
							LET l_rec_batchdetl.stats_qty = 0 
							LET l_rec_batchdetl.debit_amt = l_rec_bankdetails.tran_amt 
							/ l_rec_bankstatement.conv_qty 
							LET l_rec_batchdetl.credit_amt = 0 
							LET l_rec_batchdetl.currency_code = l_rec_batchhead.currency_code 
							LET l_rec_batchdetl.conv_qty = l_rec_bankstatement.conv_qty 
							LET l_rec_batchdetl.for_debit_amt = l_rec_bankdetails.tran_amt 
							LET l_rec_batchdetl.for_credit_amt = 0 
							LET l_rec_batchdetl.stats_qty = 0 
							IF glob_rec_glparms.use_currency_flag = "N" THEN 
								LET l_rec_batchdetl.for_debit_amt = l_rec_batchdetl.debit_amt 
								LET l_rec_batchdetl.for_credit_amt = l_rec_batchdetl.credit_amt 
								LET l_rec_batchdetl.currency_code = 
								glob_rec_glparms.base_currency_code 
								LET l_rec_batchdetl.conv_qty = 1 
							END IF 
							LET l_err_message= "Inserting Bank Batch Details Table - bc" 
							INSERT INTO batchdetl VALUES (l_rec_batchdetl.*) 
							LET l_rec_batchhead.debit_amt = l_rec_batchhead.debit_amt 
							+ l_rec_batchdetl.debit_amt 
							LET l_rec_batchhead.for_debit_amt = l_rec_batchhead.for_debit_amt 
							+ l_rec_batchdetl.for_debit_amt 
							LET l_audit_amt = l_audit_amt + l_rec_batchdetl.debit_amt 
							LET l_rec_cbaudit.cmpy_code = l_rec_bankstatement.cmpy_code 
							LET l_rec_cbaudit.tran_date = l_rec_bankstatement.tran_date 
							LET l_rec_cbaudit.tran_type_ind =l_rec_bankstatement.entry_type_code 
							LET l_rec_cbaudit.sheet_num = l_rec_bankstatement.sheet_num 
							LET l_rec_cbaudit.line_num = l_rec_bankstatement.seq_num 
							LET l_rec_cbaudit.year_num = l_rec_bankstatement.year_num 
							LET l_rec_cbaudit.period_num = l_rec_bankstatement.period_num 
							LET l_rec_cbaudit.source_num = glob_rec_glparms.next_jour_num 
							LET l_rec_cbaudit.tran_text = "Direct charges" 
							LET l_rec_cbaudit.tran_amt = l_rec_batchdetl.debit_amt 
							LET l_rec_cbaudit.entry_code = l_rec_bankstatement.entry_code 
							LET l_rec_cbaudit.bank_code = l_rec_bankstatement.bank_code 
							LET l_err_message = "Inserting CB Audit Table - bc" 
							INSERT INTO cbaudit VALUES (l_rec_cbaudit.*) 
							LET l_last_cbaudit_row = sqlca.sqlerrd[6] 
						END FOREACH 
						FREE c1_bankdetails 
						IF l_audit_amt != l_rec_batchhead.credit_amt THEN 
							LET l_difference = l_audit_amt - l_rec_batchhead.credit_amt 
							UPDATE batchdetl 
							SET debit_amt = debit_amt - l_difference 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND jour_code = l_rec_batchhead.jour_code 
							AND jour_num = l_rec_batchhead.jour_num 
							AND seq_num = l_rec_batchhead.seq_num 
							LET l_rec_batchhead.debit_amt = l_rec_batchhead.debit_amt 
							- l_difference 
							UPDATE cbaudit 
							SET tran_amt = tran_amt - l_difference 
							WHERE rowid = l_last_cbaudit_row 
						END IF 
						IF glob_rec_glparms.use_currency_flag = "N" THEN 
							LET l_rec_batchhead.for_debit_amt = l_rec_batchhead.debit_amt 
							LET l_rec_batchhead.for_credit_amt = l_rec_batchhead.credit_amt 
							LET l_rec_batchhead.currency_code = glob_rec_glparms.base_currency_code 
							LET l_rec_batchhead.conv_qty = 1 
						END IF 
						LET l_rec_batchhead.control_amt = l_rec_batchhead.for_debit_amt 
						LET l_err_message= "Updating Batch Header Table - bc" 
						UPDATE batchhead 
						SET * = l_rec_batchhead.* 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND jour_code = l_rec_batchhead.jour_code 
						AND jour_num = l_rec_batchhead.jour_num 
					END IF 
					#
					# BD - Bank Deposits
					#
				WHEN l_rec_bankstatement.entry_type_code = "BD" 
					LET l_err_message = "Updating Banking Table - bd" 
					UPDATE banking 
					SET bk_rec_part = null, 
					bk_sh_no = glob_rec_bank.sheet_num, 
					bk_seq_no = l_rec_bankstatement.seq_num 
					WHERE doc_num = l_rec_bankstatement.doc_num 
					#
					# CH - Cheques
					#
				WHEN l_rec_bankstatement.entry_type_code = "CH" 
					LET l_err_message = "Updating Cheque Table - ch" 
					UPDATE cheque 
					SET recon_flag = "Y", 
					part_recon_flag = null, 
					rec_state_num = glob_rec_bank.sheet_num, 
					rec_line_num = l_rec_bankstatement.seq_num 
					WHERE doc_num = l_rec_bankstatement.doc_num 
					#
					# EF - Eletronic Funds Transfer
					#
				WHEN l_rec_bankstatement.entry_type_code = "EF" 
					LET l_err_message = "Updating Cheque Table - ef" 
					UPDATE cheque SET recon_flag = "Y", 
					part_recon_flag = null, 
					rec_state_num = glob_rec_bank.sheet_num, 
					rec_line_num = l_rec_bankstatement.seq_num 
					WHERE eft_run_num = l_rec_bankstatement.ref_code 
					AND pay_meth_ind = "3" 
					AND bank_code = glob_rec_bank.bank_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					#
					# SC - Sundry Credits
					#
				WHEN l_rec_bankstatement.entry_type_code = "SC" 
					IF l_rec_bankstatement.doc_num > 0 THEN 
						LET l_err_message = "Updating Banking Table - cc" 
						UPDATE banking 
						SET bk_rec_part = null, 
						bk_sh_no = glob_rec_bank.sheet_num, 
						bk_seq_no = l_rec_bankstatement.seq_num 
						WHERE doc_num = l_rec_bankstatement.doc_num 
					ELSE 
						IF l_create_new_batch THEN 
							LET l_create_new_batch = false 
							LET l_audit_amt = 0 
							INITIALIZE l_rec_batchhead.* TO NULL 
							LET glob_rec_glparms.next_jour_num = glob_rec_glparms.next_jour_num + 1 
							LET l_rec_batchhead.cmpy_code = glob_rec_kandoouser.cmpy_code 
							LET l_rec_batchhead.jour_code = glob_rec_glparms.cb_code 
							LET l_rec_batchhead.jour_num = glob_rec_glparms.next_jour_num 
							LET l_rec_batchhead.entry_code = l_rec_bankstatement.entry_code 
							LET l_rec_batchhead.jour_date = today 
							LET l_rec_batchhead.year_num = l_rec_bankstatement.year_num 
							LET l_rec_batchhead.period_num = l_rec_bankstatement.period_num 
							LET l_rec_batchhead.control_amt = 0 
							LET l_rec_batchhead.credit_amt = 0 
							LET l_rec_batchhead.debit_amt = 0 
							LET l_rec_batchhead.control_qty = 0 
							LET l_rec_batchhead.stats_qty = 0 
							LET l_rec_batchhead.currency_code = 
							l_rec_bankstatement.bank_currency_code 
							LET l_rec_batchhead.conv_qty = l_rec_bankstatement.conv_qty 
							LET l_rec_batchhead.for_debit_amt = 0 
							LET l_rec_batchhead.for_credit_amt = 0 
							LET l_rec_batchhead.source_ind = "C" 
							LET l_rec_batchhead.post_flag = "N" 
							LET l_rec_batchhead.seq_num = 0 
							LET l_rec_batchhead.com1_text = l_rec_bankstatement.com1_text 
							LET l_rec_batchhead.com2_text = l_rec_bankstatement.com2_text 
							LET l_rec_batchhead.cleared_flag = l_cleared_flag 
							LET l_rec_batchhead.post_run_num = 0 
							LET l_rec_batchhead.consol_num = 0 
							LET l_rec_batchhead.rate_type_ind = "S" 

							LET l_err_message = "Inserting Batch Header Table - sc" 
							CALL fgl_winmessage("15 Learning batch head codes - tell Hubert",l_rec_batchhead.source_ind,"info") 
							INSERT INTO batchhead VALUES (l_rec_batchhead.*) 
						END IF 
						LET l_rec_banking.bk_cmpy = glob_rec_kandoouser.cmpy_code 
						LET l_rec_banking.bk_acct = l_rec_bankstatement.acct_code 
						IF l_rec_bankstatement.type_code = "S" THEN 
							LET l_rec_banking.bk_type = "SC" 
							LET l_rec_banking.bk_desc = "Sundry credit" 
						ELSE 
							LET l_rec_banking.bk_type = "DP" 
							LET l_rec_banking.bk_desc = "Deposit" 
						END IF 
						LET l_rec_banking.bk_bankdt = l_rec_bankstatement.tran_date 
						LET l_rec_banking.bk_sh_no = l_rec_bankstatement.sheet_num 
						LET l_rec_banking.bk_seq_no = l_rec_bankstatement.seq_num 
						INITIALIZE l_rec_banking.bk_rec_part TO NULL 
						LET l_rec_banking.bk_year = l_rec_bankstatement.year_num 
						LET l_rec_banking.bk_per = l_rec_bankstatement.period_num 
						LET l_rec_banking.bk_cred = l_rec_bankstatement.tran_amt 
						LET l_rec_banking.bk_enter = l_rec_bankstatement.entry_code 
						LET l_rec_banking.doc_num = 0 
						LET l_err_message = "Inserting Banking Table - sc" 
						INSERT INTO banking VALUES (l_rec_banking.*) 
						LET l_rec_batchdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
						LET l_rec_batchdetl.jour_code = l_rec_batchhead.jour_code 
						LET l_rec_batchdetl.jour_num = l_rec_batchhead.jour_num 
						LET l_rec_batchhead.seq_num = l_rec_batchhead.seq_num + 1 
						LET l_rec_batchdetl.seq_num = l_rec_batchhead.seq_num 
						LET l_rec_batchdetl.tran_type_ind = "CB" 
						LET l_rec_batchdetl.analysis_text = NULL 
						LET l_rec_batchdetl.tran_date = l_rec_bankstatement.tran_date 
						LET l_rec_batchdetl.ref_text = "CB Deposit balance" 
						LET l_rec_batchdetl.ref_num = 0 
						LET l_rec_batchdetl.acct_code = l_rec_bankstatement.acct_code 
						LET l_rec_batchdetl.desc_text = l_rec_bankstatement.desc_text 
						LET l_rec_batchdetl.debit_amt = l_rec_bankstatement.tran_amt 
						/ l_rec_bankstatement.conv_qty 
						LET l_rec_batchdetl.credit_amt = 0 
						LET l_rec_batchdetl.currency_code = l_rec_batchhead.currency_code 
						LET l_rec_batchdetl.conv_qty = l_rec_bankstatement.conv_qty 
						LET l_rec_batchdetl.for_debit_amt =l_rec_bankstatement.tran_amt 
						LET l_rec_batchdetl.for_credit_amt = 0 
						LET l_rec_batchdetl.stats_qty = 0 
						IF glob_rec_glparms.use_currency_flag = "N" THEN 
							LET l_rec_batchdetl.for_debit_amt = l_rec_batchdetl.debit_amt 
							LET l_rec_batchdetl.for_credit_amt = l_rec_batchdetl.credit_amt 
							LET l_rec_batchdetl.currency_code = glob_rec_glparms.base_currency_code 
							LET l_rec_batchdetl.conv_qty = 1 
						END IF 
						LET l_err_message="Inserting Batch details Table - sc" 
						INSERT INTO batchdetl VALUES (l_rec_batchdetl.*) 
						LET l_rec_batchhead.debit_amt = l_rec_batchhead.debit_amt 
						+ l_rec_batchdetl.debit_amt 
						LET l_rec_batchhead.for_debit_amt = l_rec_batchhead.for_debit_amt 
						+ l_rec_batchdetl.for_debit_amt 
						DECLARE c2_bankdetails CURSOR FOR 
						SELECT * FROM bankdetails 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND bank_code = l_rec_bankstatement.bank_code 
						AND sheet_num = l_rec_bankstatement.sheet_num 
						AND seq_num = l_rec_bankstatement.seq_num 
						FOREACH c2_bankdetails INTO l_rec_bankdetails.* 
							INITIALIZE l_rec_batchdetl.* TO NULL 
							LET l_rec_batchdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
							LET l_rec_batchdetl.jour_code = l_rec_batchhead.jour_code 
							LET l_rec_batchdetl.jour_num = l_rec_batchhead.jour_num 
							LET l_rec_batchhead.seq_num = l_rec_batchhead.seq_num + 1 
							LET l_rec_batchdetl.seq_num = l_rec_batchhead.seq_num 
							LET l_rec_batchdetl.tran_type_ind = "CB" 
							LET l_rec_batchdetl.analysis_text = l_rec_bankdetails.ref_text 
							LET l_rec_batchdetl.tran_date = l_rec_bankstatement.tran_date 
							IF l_rec_bankstatement.type_code = "S" THEN 
								LET l_rec_batchdetl.ref_text = "Sund.Cr" 
							ELSE 
								LET l_rec_batchdetl.ref_text = "Dir dep" 
							END IF 
							LET l_rec_batchdetl.ref_num = 0 
							LET l_rec_batchdetl.acct_code = l_rec_bankdetails.acct_code 
							LET l_rec_batchdetl.desc_text = l_rec_bankdetails.desc_text 
							LET l_rec_batchdetl.debit_amt = 0 
							LET l_rec_batchdetl.credit_amt = l_rec_bankdetails.tran_amt 
							/ l_rec_bankstatement.conv_qty 
							LET l_rec_batchdetl.currency_code = l_rec_batchhead.currency_code 
							LET l_rec_batchdetl.conv_qty = l_rec_bankstatement.conv_qty 
							LET l_rec_batchdetl.for_debit_amt = 0 
							LET l_rec_batchdetl.for_credit_amt = l_rec_bankdetails.tran_amt 
							LET l_rec_batchdetl.stats_qty = 0 
							IF glob_rec_glparms.use_currency_flag = "N" THEN 
								LET l_rec_batchdetl.for_debit_amt = l_rec_batchdetl.debit_amt 
								LET l_rec_batchdetl.for_credit_amt = l_rec_batchdetl.credit_amt 
								LET l_rec_batchdetl.currency_code = 
								glob_rec_glparms.base_currency_code 
								LET l_rec_batchdetl.conv_qty = 1 
							END IF 
							LET l_err_message= "Inserting Bank Batch Details Table - sc" 
							INSERT INTO batchdetl VALUES (l_rec_batchdetl.*) 
							LET l_rec_batchhead.credit_amt = l_rec_batchhead.credit_amt 
							+ l_rec_batchdetl.credit_amt 
							LET l_rec_batchhead.for_credit_amt = l_rec_batchhead.for_credit_amt 
							+ l_rec_batchdetl.for_credit_amt 
							LET l_audit_amt = l_audit_amt + l_rec_batchdetl.credit_amt 
							LET l_rec_cbaudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
							LET l_rec_cbaudit.tran_date = l_rec_bankstatement.tran_date 
							LET l_rec_cbaudit.tran_type_ind = l_rec_banking.bk_type 
							LET l_rec_cbaudit.sheet_num = l_rec_bankstatement.sheet_num 
							LET l_rec_cbaudit.line_num = l_rec_bankstatement.seq_num 
							LET l_rec_cbaudit.year_num = l_rec_bankstatement.year_num 
							LET l_rec_cbaudit.period_num = l_rec_bankstatement.period_num 
							LET l_rec_cbaudit.source_num = glob_rec_glparms.next_jour_num 
							IF l_rec_bankstatement.type_code = "S" THEN 
								LET l_rec_cbaudit.tran_text = "Sundry credit" 
							ELSE 
								LET l_rec_cbaudit.tran_text = "Direct deposit" 
							END IF 
							LET l_rec_cbaudit.tran_amt = l_rec_batchdetl.credit_amt 
							LET l_rec_cbaudit.entry_code = l_rec_bankstatement.entry_code 
							LET l_rec_cbaudit.bank_code = l_rec_bankstatement.bank_code 
							LET l_err_message = "Inserting CB Audit Table - sc" 
							INSERT INTO cbaudit VALUES (l_rec_cbaudit.*) 
							LET l_last_cbaudit_row = sqlca.sqlerrd[6] 
						END FOREACH 
						FREE c2_bankdetails 
						#
						# Total of details may NOT match converted transaction total, due TO
						# rounding errors.  Adjust last batch detail AND corresponding cbaudit.
						#
						IF l_audit_amt != l_rec_batchhead.debit_amt THEN 
							LET l_difference = l_rec_batchhead.debit_amt - l_audit_amt 
							UPDATE batchdetl 
							SET credit_amt = credit_amt + l_difference 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND jour_code = l_rec_batchhead.jour_code 
							AND jour_num = l_rec_batchhead.jour_num 
							AND seq_num = l_rec_batchhead.seq_num 
							LET l_rec_batchhead.credit_amt = l_rec_batchhead.credit_amt 
							+ l_difference 
							UPDATE cbaudit 
							SET tran_amt = tran_amt + l_difference 
							WHERE rowid = l_last_cbaudit_row 
						END IF 
						IF glob_rec_glparms.use_currency_flag = "N" THEN 
							LET l_rec_batchhead.for_debit_amt = l_rec_batchhead.debit_amt 
							LET l_rec_batchhead.for_credit_amt = l_rec_batchhead.credit_amt 
							LET l_rec_batchhead.currency_code = glob_rec_glparms.base_currency_code 
							LET l_rec_batchhead.conv_qty = 1 
						END IF 
						LET l_rec_batchhead.control_amt = l_rec_batchhead.for_debit_amt 
						UPDATE batchhead 
						SET * = l_rec_batchhead.* 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND jour_code = l_rec_batchhead.jour_code 
						AND jour_num = l_rec_batchhead.jour_num 
					END IF 
					#
					# RE - Receipts
					#
				WHEN l_rec_bankstatement.entry_type_code = "RE" 
					LET l_err_message = "Inserting Receipt Header - re" 
					INITIALIZE l_rec_cashreceipt.* TO NULL 
					SELECT * INTO l_rec_customer.* 
					FROM customer 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cust_code = l_rec_bankstatement.ref_code 
					IF status = NOTFOUND THEN 
						LET l_error_line = 
						" Customer ",l_rec_bankstatement.ref_code," does NOT exist " 
						CALL trans_error(l_rec_bankstatement.sheet_num, 
						l_rec_bankstatement.seq_num, 
						l_rec_bankstatement.entry_type_code, 
						l_error_line) 
						RETURN 
					END IF 
					LET l_cust_code = l_rec_bankstatement.ref_code 
					IF l_rec_customer.corp_cust_code IS NOT NULL 
					AND l_rec_customer.corp_cust_ind = "1" THEN 
						SELECT * INTO l_rec_corpcust.* 
						FROM customer 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND cust_code = l_rec_customer.corp_cust_code 
						AND delete_flag = "N" 
						IF sqlca.sqlcode = 0 THEN 
							LET l_cust_code = l_rec_customer.corp_cust_code 
							LET l_rec_customer.* = l_rec_corpcust.* 
						END IF 
					END IF 
					SELECT acct_mask_code INTO l_acct_mask 
					FROM customertype 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND type_code = l_rec_customer.type_code 
					LET l_rec_cashreceipt.cash_num = 
					next_trans_num(glob_rec_kandoouser.cmpy_code,TRAN_TYPE_RECEIPT_CA,l_acct_mask) 
					IF l_rec_cashreceipt.cash_num < 0 THEN 
						LET status = l_rec_cashreceipt.cash_num 
						LET l_err_message ="Error in Receipt Next Number update" 
						GOTO recovery 
					END IF 
					LET l_rec_cashreceipt.cmpy_code = glob_rec_kandoouser.cmpy_code 
					LET l_rec_cashreceipt.cust_code = l_cust_code 
					LET l_rec_cashreceipt.cheque_text = 
					l_rec_bankstatement.ref_num USING "<<<<<<<<<<" 
					LET l_rec_cashreceipt.cash_acct_code = l_rec_bankstatement.acct_code 
					LET l_rec_cashreceipt.entry_code = l_rec_bankstatement.entry_code 
					LET l_rec_cashreceipt.entry_date = l_rec_bankstatement.entry_date 
					LET l_rec_cashreceipt.cash_date = l_rec_bankstatement.tran_date 
					LET l_rec_cashreceipt.year_num = l_rec_bankstatement.year_num 
					LET l_rec_cashreceipt.period_num = l_rec_bankstatement.period_num 
					IF l_rec_bankstatement.bank_currency_code = 
					l_rec_bankstatement.ref_currency_code THEN 
						LET l_rec_cashreceipt.cash_amt = l_rec_bankstatement.tran_amt 
					ELSE 
						LET l_rec_cashreceipt.cash_amt = l_rec_bankstatement.other_amt 
					END IF 
					LET l_rec_cashreceipt.applied_amt = 0 
					LET l_rec_cashreceipt.disc_amt = 0 
					LET l_rec_cashreceipt.on_state_flag = "N" 
					LET l_rec_cashreceipt.posted_flag = CASHRECEIPT_POST_FLAG_STATUS_NOT_POSTED_N 
					LET l_rec_cashreceipt.next_num = 1 
					LET l_rec_cashreceipt.com1_text = l_rec_bankstatement.com1_text 
					LET l_rec_cashreceipt.com2_text = l_rec_bankstatement.com2_text 
					LET l_rec_cashreceipt.bank_text = l_rec_bankstatement.ref_text 
					LET l_rec_cashreceipt.cash_type_ind = "E" ## electronic 
					LET l_rec_cashreceipt.chq_date = l_rec_bankstatement.tran_date 
					LET l_rec_cashreceipt.drawer_text =l_rec_bankstatement.desc_text[1,20] 
					LET l_rec_cashreceipt.branch_text =l_rec_bankstatement.desc_text[21,30] 
					LET l_rec_cashreceipt.banked_flag = "Y" 
					LET l_rec_cashreceipt.banked_date = l_rec_bankstatement.tran_date 
					LET l_rec_cashreceipt.currency_code = 
					l_rec_bankstatement.ref_currency_code 
					LET l_rec_cashreceipt.conv_qty = l_rec_bankstatement.conv_qty 
					LET l_rec_cashreceipt.bank_code = glob_rec_bank.bank_code 
					LET l_rec_cashreceipt.bank_currency_code = 
					l_rec_bankstatement.bank_currency_code 
					SELECT * INTO l_rec_userlocn.* FROM userlocn 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND sign_on_code = glob_rec_kandoouser.sign_on_code 
					LET l_rec_cashreceipt.locn_code = l_rec_userlocn.locn_code 
					LET l_rec_cashreceipt.order_num = NULL 
					LET l_err_message = "Inserting Banking Table - re" 
					LET l_rec_banking.bk_cmpy = glob_rec_kandoouser.cmpy_code 
					LET l_rec_banking.bk_acct = l_rec_bankstatement.acct_code 
					LET l_rec_banking.bk_type = l_rec_bankstatement.entry_type_code 
					LET l_rec_banking.bk_bankdt = l_rec_bankstatement.tran_date 
					LET l_rec_banking.bk_desc = "Receipts" 
					LET l_rec_banking.bk_sh_no = l_rec_bankstatement.sheet_num 
					LET l_rec_banking.bk_seq_no = l_rec_bankstatement.seq_num 
					LET l_rec_banking.bk_rec_part = NULL 
					LET l_rec_banking.bk_year = l_rec_bankstatement.year_num 
					LET l_rec_banking.bk_per = l_rec_bankstatement.period_num 
					LET l_rec_banking.bk_cred = l_rec_bankstatement.tran_amt 
					LET l_rec_banking.bk_enter = l_rec_bankstatement.entry_code 
					LET l_rec_banking.doc_num = 0 
					INSERT INTO banking VALUES (l_rec_banking.*) 
					LET l_total_applied = 0 
					LET l_total_disc = 0 
					LET l_cred_days_given = 0 
					LET l_cred_days_taken = 0 
					LET l_late_pay = 0 
					LET l_receipt_age = l_rec_arparms.cust_age_date 
					- l_rec_cashreceipt.cash_date 
					CASE 
						WHEN l_receipt_age <= 0 
							LET l_rec_customer.curr_amt = l_rec_customer.curr_amt 
							- l_rec_cashreceipt.cash_amt 
						WHEN (l_receipt_age >=1 AND l_receipt_age <=30 ) 
							LET l_rec_customer.over1_amt = l_rec_customer.over1_amt 
							- l_rec_cashreceipt.cash_amt 
						WHEN l_receipt_age >=31 AND l_receipt_age <=60 
							LET l_rec_customer.over30_amt = l_rec_customer.over30_amt 
							- l_rec_cashreceipt.cash_amt 
						WHEN l_receipt_age >=61 AND l_receipt_age <=90 
							LET l_rec_customer.over60_amt = l_rec_customer.over60_amt 
							- l_rec_cashreceipt.cash_amt 
						OTHERWISE 
							LET l_rec_customer.over90_amt = l_rec_customer.over90_amt 
							- l_rec_cashreceipt.cash_amt 
					END CASE 
					LET l_err_message= "Inserting Application Details - re" 
					DECLARE c3_bankdetails CURSOR FOR 
					SELECT * FROM bankdetails 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND bank_code = l_rec_bankstatement.bank_code 
					AND sheet_num = l_rec_bankstatement.sheet_num 
					AND seq_num = l_rec_bankstatement.seq_num 
					FOREACH c3_bankdetails INTO l_rec_bankdetails.* 
						DECLARE c1_invoicehead CURSOR FOR 
						SELECT * FROM invoicehead 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND inv_num = l_rec_bankdetails.ref_num 
						FOR UPDATE 
						OPEN c1_invoicehead 
						FETCH c1_invoicehead INTO l_rec_invoicehead.* 
						LET l_rec_invoicehead.paid_amt = l_rec_invoicehead.paid_amt 
						+ l_rec_bankdetails.tran_amt 
						+ l_rec_bankdetails.disc_amt 
						IF l_rec_invoicehead.disc_taken_amt IS NULL THEN 
							LET l_rec_invoicehead.disc_taken_amt = 0 
						END IF 
						LET l_rec_invoicehead.seq_num = l_rec_invoicehead.seq_num + 1 
						LET l_rec_invoicehead.disc_taken_amt = 
						l_rec_invoicehead.disc_taken_amt + l_rec_bankdetails.disc_amt 
						IF l_rec_invoicehead.total_amt = l_rec_invoicehead.paid_amt THEN 
							LET l_rec_invoicehead.paid_date = l_rec_cashreceipt.cash_date 
							LET l_cred_days_given = l_cred_days_given + 
							(l_rec_invoicehead.due_date - l_rec_invoicehead.inv_date) 
							LET l_cred_days_taken = l_cred_days_taken + 
							(l_rec_cashreceipt.cash_date - l_rec_invoicehead.inv_date) 
						END IF 
						UPDATE invoicehead 
						SET paid_amt = l_rec_invoicehead.paid_amt, 
						paid_date = l_rec_invoicehead.paid_date, 
						seq_num = l_rec_invoicehead.seq_num, 
						disc_taken_amt = l_rec_invoicehead.disc_taken_amt 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND inv_num = l_rec_bankdetails.ref_num 
						LET l_invoice_age = l_rec_arparms.cust_age_date 
						- l_rec_invoicehead.due_date 
						LET l_total_applied = l_total_applied + l_rec_bankdetails.tran_amt 
						LET l_total_disc = l_total_disc + l_rec_bankdetails.disc_amt 
						IF l_rec_cashreceipt.cash_date > l_rec_invoicehead.due_date THEN 
							LET l_late_pay = l_late_pay + 1 
						END IF 
						LET l_rec_invoicepay.cmpy_code = glob_rec_kandoouser.cmpy_code 
						LET l_rec_invoicepay.cust_code = l_rec_cashreceipt.cust_code 
						LET l_rec_invoicepay.inv_num = l_rec_invoicehead.inv_num 
						LET l_rec_invoicepay.ref_num = l_rec_cashreceipt.cash_num 
						LET l_rec_invoicepay.appl_num = 0 
						LET l_rec_invoicepay.pay_text = l_rec_cashreceipt.cheque_text 
						LET l_rec_invoicepay.apply_num = l_rec_cashreceipt.next_num 
						LET l_rec_invoicepay.pay_type_ind = TRAN_TYPE_RECEIPT_CA 
						LET l_rec_invoicepay.pay_date = l_rec_cashreceipt.cash_date 
						LET l_rec_invoicepay.pay_amt = l_rec_bankdetails.tran_amt 
						LET l_rec_invoicepay.disc_amt =l_rec_bankdetails.disc_amt 
						LET l_err_message = " Invoicepay table INSERT - re" 
						INSERT INTO invoicepay VALUES (l_rec_invoicepay.*) 
						LET l_base_apply_amt1 = 
						l_rec_invoicepay.pay_amt / l_rec_invoicehead.conv_qty 
						LET l_base_apply_amt2 = 
						l_rec_invoicepay.pay_amt / l_rec_cashreceipt.conv_qty 
						LET l_rec_exchangevar.exchangevar_amt = 
						l_base_apply_amt1 - l_base_apply_amt2 
						IF l_rec_exchangevar.exchangevar_amt != 0 THEN 
							LET l_rec_exchangevar.cmpy_code = glob_rec_kandoouser.cmpy_code 
							LET l_rec_exchangevar.year_num = l_rec_cashreceipt.year_num 
							LET l_rec_exchangevar.period_num =l_rec_cashreceipt.period_num 
							LET l_rec_exchangevar.source_ind = "A" 
							LET l_rec_exchangevar.tran_date = l_rec_cashreceipt.cash_date 
							LET l_rec_exchangevar.ref_code = l_rec_cashreceipt.cust_code 
							LET l_rec_exchangevar.tran_type1_ind = TRAN_TYPE_INVOICE_IN 
							LET l_rec_exchangevar.ref1_num = l_rec_invoicehead.inv_num 
							LET l_rec_exchangevar.tran_type2_ind = TRAN_TYPE_RECEIPT_CA 
							LET l_rec_exchangevar.ref2_num = l_rec_cashreceipt.cash_num 
							LET l_rec_exchangevar.currency_code = 
							l_rec_cashreceipt.currency_code 
							LET l_rec_exchangevar.posted_flag = "N" 
							LET l_err_message ="Exchangevar table INSERT - re" 
							INSERT INTO exchangevar VALUES (l_rec_exchangevar.*) 
						END IF 
						IF l_receipt_age <= 0 
						AND l_invoice_age <=0 
						AND l_rec_invoicepay.disc_amt = 0 THEN 
						ELSE 
							CASE 
								WHEN l_receipt_age <= 0 
									LET l_rec_customer.curr_amt = l_rec_customer.curr_amt 
									+ l_rec_invoicepay.pay_amt 
								WHEN (l_receipt_age >=1 AND l_receipt_age <=30 ) 
									LET l_rec_customer.over1_amt = l_rec_customer.over1_amt 
									+ l_rec_invoicepay.pay_amt 
								WHEN l_receipt_age >=31 AND l_receipt_age <=60 
									LET l_rec_customer.over30_amt = l_rec_customer.over30_amt 
									+ l_rec_invoicepay.pay_amt 
								WHEN l_receipt_age >=61 AND l_receipt_age <=90 
									LET l_rec_customer.over60_amt = l_rec_customer.over60_amt 
									+ l_rec_invoicepay.pay_amt 
								OTHERWISE 
									LET l_rec_customer.over90_amt = l_rec_customer.over90_amt 
									+ l_rec_invoicepay.pay_amt 
							END CASE 
							CASE 
								WHEN l_invoice_age <= 0 
									LET l_rec_customer.curr_amt = l_rec_customer.curr_amt 
									- l_rec_invoicepay.pay_amt 
								WHEN l_invoice_age >=1 AND l_invoice_age <=30 
									LET l_rec_customer.over1_amt = l_rec_customer.over1_amt 
									- l_rec_invoicepay.pay_amt 
								WHEN l_invoice_age >=31 AND l_invoice_age <=60 
									LET l_rec_customer.over30_amt = l_rec_customer.over30_amt 
									- l_rec_invoicepay.pay_amt 
								WHEN l_invoice_age >=61 AND l_invoice_age <=90 
									LET l_rec_customer.over60_amt = l_rec_customer.over60_amt 
									- l_rec_invoicepay.pay_amt 
								OTHERWISE 
									LET l_rec_customer.over90_amt = l_rec_customer.over90_amt 
									- l_rec_invoicepay.pay_amt 
							END CASE 
							IF l_rec_invoicepay.disc_amt <> 0 THEN 
								CASE 
									WHEN l_invoice_age <= 0 
										LET l_rec_customer.curr_amt = l_rec_customer.curr_amt 
										- l_rec_invoicepay.disc_amt 
									WHEN l_invoice_age >=1 AND l_invoice_age <=30 
										LET l_rec_customer.over1_amt = l_rec_customer.over1_amt 
										- l_rec_invoicepay.disc_amt 
									WHEN l_invoice_age >=31 AND l_invoice_age <=60 
										LET l_rec_customer.over30_amt = l_rec_customer.over30_amt 
										- l_rec_invoicepay.disc_amt 
									WHEN l_invoice_age >=61 AND l_invoice_age <=90 
										LET l_rec_customer.over60_amt = l_rec_customer.over60_amt 
										- l_rec_invoicepay.disc_amt 
									OTHERWISE 
										LET l_rec_customer.over90_amt = l_rec_customer.over90_amt 
										- l_rec_invoicepay.disc_amt 
								END CASE 
							END IF 
						END IF 
						FREE c1_invoicehead 
					END FOREACH 
					FREE c3_bankdetails 
					LET l_rec_customer.bal_amt = l_rec_customer.bal_amt 
					- l_rec_cashreceipt.cash_amt 
					LET l_rec_customer.next_seq_num = l_rec_customer.next_seq_num + 1 
					IF year(l_rec_cashreceipt.cash_date) > 
					year(l_rec_customer.last_pay_date) THEN 
						LET l_rec_customer.mtdp_amt = 0 
						LET l_rec_customer.ytdp_amt = 0 
					END IF 
					IF month(l_rec_cashreceipt.cash_date) > 
					month(l_rec_customer.last_pay_date) THEN 
						LET l_rec_customer.mtdp_amt = 0 
					END IF 
					LET l_rec_customer.last_pay_date = l_rec_cashreceipt.cash_date 
					LET l_rec_customer.ytdp_amt = l_rec_customer.ytdp_amt 
					+ l_rec_cashreceipt.cash_amt 
					LET l_rec_customer.mtdp_amt = l_rec_customer.mtdp_amt 
					+ l_rec_cashreceipt.cash_amt 
					LET l_rec_araudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
					LET l_rec_araudit.tran_date = l_rec_cashreceipt.cash_date 
					LET l_rec_araudit.cust_code = l_rec_cashreceipt.cust_code 
					LET l_rec_araudit.seq_num = l_rec_customer.next_seq_num 
					LET l_rec_araudit.tran_type_ind = TRAN_TYPE_RECEIPT_CA 
					LET l_rec_araudit.source_num = l_rec_cashreceipt.cash_num 
					LET l_rec_araudit.tran_text = "Cash receipt" 
					LET l_rec_araudit.tran_amt = 0 - l_rec_cashreceipt.cash_amt 
					LET l_rec_araudit.entry_code = glob_rec_kandoouser.sign_on_code 
					LET l_rec_araudit.year_num = l_rec_cashreceipt.year_num 
					LET l_rec_araudit.period_num = l_rec_cashreceipt.period_num 
					LET l_rec_araudit.bal_amt = l_rec_customer.bal_amt 
					LET l_rec_araudit.currency_code = l_rec_customer.currency_code 
					LET l_rec_araudit.conv_qty = l_rec_cashreceipt.conv_qty 
					LET l_rec_araudit.entry_date = today 
					LET l_err_message = "Inserting AR Audit Table - re" 
					INSERT INTO araudit VALUES (l_rec_araudit.*) 
					#
					# IF discounts taken, adjust customer balances accordingly AND
					# OUTPUT an araudit entry FOR the discount
					#
					IF l_total_disc > 0 THEN 
						LET l_rec_customer.bal_amt = l_rec_customer.bal_amt - l_total_disc 
						LET l_rec_customer.ytdp_amt = l_rec_customer.ytdp_amt + l_total_disc 
						LET l_rec_customer.mtdp_amt = l_rec_customer.mtdp_amt + l_total_disc 
						LET l_rec_customer.next_seq_num = l_rec_customer.next_seq_num + 1 
						IF l_rec_customer.cred_given_num IS NULL THEN 
							LET l_rec_customer.cred_given_num = 0 
						END IF 
						LET l_rec_customer.cred_given_num = 
						l_rec_customer.cred_given_num + l_cred_days_given 
						IF l_rec_customer.cred_taken_num IS NULL THEN 
							LET l_rec_customer.cred_taken_num = 0 
						END IF 
						LET l_rec_customer.cred_taken_num = 
						l_rec_customer.cred_taken_num + l_cred_days_taken 
						LET l_rec_customer.late_pay_num = 
						l_rec_customer.late_pay_num + l_late_pay 
						LET l_err_message = "Inserting AR audit table (2) - re" 
						LET l_rec_araudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
						LET l_rec_araudit.tran_date = l_rec_cashreceipt.cash_date 
						LET l_rec_araudit.cust_code = l_rec_cashreceipt.cust_code 
						LET l_rec_araudit.seq_num = l_rec_customer.next_seq_num 
						LET l_rec_araudit.tran_type_ind = TRAN_TYPE_RECEIPT_CA 
						LET l_rec_araudit.source_num = l_rec_cashreceipt.cash_num 
						LET l_rec_araudit.tran_text = "Apply discount" 
						LET l_rec_araudit.tran_amt = 0 - l_total_disc 
						LET l_rec_araudit.entry_code = l_rec_cashreceipt.entry_code 
						LET l_rec_araudit.year_num = l_rec_cashreceipt.year_num 
						LET l_rec_araudit.period_num = l_rec_cashreceipt.period_num 
						LET l_rec_araudit.bal_amt = l_rec_customer.bal_amt 
						LET l_rec_araudit.currency_code = l_rec_customer.currency_code 
						LET l_rec_araudit.conv_qty = l_rec_cashreceipt.conv_qty 
						LET l_rec_araudit.entry_date = today 
						INSERT INTO araudit VALUES (l_rec_araudit.*) 
					END IF 
					LET l_err_message = "Updating Customer Table - re" 
					UPDATE customer 
					SET bal_amt = l_rec_customer.bal_amt, 
					curr_amt = l_rec_customer.curr_amt, 
					over1_amt = l_rec_customer.over1_amt, 
					over30_amt = l_rec_customer.over30_amt, 
					over60_amt = l_rec_customer.over60_amt, 
					over90_amt = l_rec_customer.over90_amt, 
					cred_bal_amt = l_rec_customer.cred_limit_amt 
					- l_rec_customer.bal_amt, 
					mtdp_amt = l_rec_customer.mtdp_amt, 
					ytdp_amt = l_rec_customer.ytdp_amt, 
					l_late_pay_num = l_rec_customer.late_pay_num, 
					next_seq_num = l_rec_customer.next_seq_num, 
					last_pay_date = l_rec_customer.last_pay_date, 
					cred_taken_num = l_rec_customer.cred_taken_num, 
					cred_given_num = l_rec_customer.cred_given_num 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cust_code = l_rec_cashreceipt.cust_code 
					LET l_err_message = "Inserting Cash Receipt - re" 
					LET l_rec_cashreceipt.applied_amt = l_rec_cashreceipt.applied_amt 
					+ l_total_applied 
					LET l_rec_cashreceipt.disc_amt = l_rec_cashreceipt.disc_amt 
					+ l_total_disc 
					IF l_rec_cashreceipt.applied_amt > l_rec_cashreceipt.cash_amt 
					OR l_rec_cashreceipt.applied_amt < 0 THEN 
						LET l_error_line = 
						"Sum of Receipt Applications Exceeds Receipt amount" 
						CALL trans_error(l_rec_bankstatement.sheet_num, 
						l_rec_bankstatement.seq_num, 
						l_rec_bankstatement.entry_type_code, 
						l_error_line) 
						RETURN 
					ELSE 
						UPDATE bankstatement 
						SET applied_amt = l_rec_cashreceipt.applied_amt 
						WHERE cmpy_code = l_rec_bankstatement.cmpy_code 
						AND bank_code = l_rec_bankstatement.bank_code 
						AND sheet_num = l_rec_bankstatement.sheet_num 
						AND seq_num = l_rec_bankstatement.seq_num 
					END IF 
					LET l_err_message = "Inserting Cash Receipt table - re" 
					INSERT INTO cashreceipt VALUES (l_rec_cashreceipt.*) 
					#
					# DC - Dishonoured Cheques
					#
					## Use cashreceipt.job_code TO link a dishonoured cheque
					## back TO the original cheque
				WHEN l_rec_bankstatement.entry_type_code = "DC" 
					INITIALIZE l_rec_cashreceipt.* TO NULL ## new cashreceipt(-) 
					INITIALIZE l_rec_s_cashreceipt.* TO NULL ## old cashreceipt(+) 
					### SELECT original cashreceipt
					SELECT * INTO l_rec_s_cashreceipt.* 
					FROM cashreceipt 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cash_num = l_rec_bankstatement.doc_num 
					IF status = NOTFOUND THEN 
						LET l_error_line = 
						" Original Cash Receipt does NOT exist " 
						CALL trans_error(l_rec_bankstatement.sheet_num, 
						l_rec_bankstatement.seq_num, 
						l_rec_bankstatement.entry_type_code, 
						l_error_line) 
						RETURN 
					END IF 
					### SELECT customer entry
					SELECT * INTO l_rec_customer.* FROM customer 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cust_code = l_rec_s_cashreceipt.cust_code 
					IF status = NOTFOUND THEN 
						LET l_error_line = 
						" Customer ",l_rec_s_cashreceipt.cust_code," does NOT exist " 
						CALL trans_error(l_rec_bankstatement.sheet_num, 
						l_rec_bankstatement.seq_num, 
						l_rec_bankstatement.entry_type_code, 
						l_error_line) 
						RETURN 
					END IF 
					## Obtain next cash receipt number
					SELECT acct_mask_code INTO l_acct_mask FROM customertype 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND type_code = l_rec_customer.type_code 
					LET l_rec_cashreceipt.cash_num = 
					next_trans_num(glob_rec_kandoouser.cmpy_code,TRAN_TYPE_RECEIPT_CA,l_acct_mask) 
					IF l_rec_cashreceipt.cash_num < 0 THEN 
						LET status = l_rec_cashreceipt.cash_num 
						LET l_err_message ="Error in Receipt Next Number update" 
						GOTO recovery 
					END IF 
					LET l_rec_cashreceipt.cmpy_code = glob_rec_kandoouser.cmpy_code 
					LET l_rec_cashreceipt.cust_code = l_rec_s_cashreceipt.cust_code 
					LET l_rec_cashreceipt.cheque_text = l_rec_s_cashreceipt.cheque_text 
					LET l_rec_cashreceipt.cash_acct_code = l_rec_bankstatement.acct_code 
					LET l_rec_cashreceipt.entry_code = l_rec_bankstatement.entry_code 
					LET l_rec_cashreceipt.entry_date = l_rec_bankstatement.entry_date 
					LET l_rec_cashreceipt.cash_date = l_rec_bankstatement.tran_date 
					LET l_rec_cashreceipt.year_num = l_rec_bankstatement.year_num 
					LET l_rec_cashreceipt.period_num = l_rec_bankstatement.period_num 
					LET l_rec_cashreceipt.cash_amt = 0 - l_rec_s_cashreceipt.cash_amt 
					LET l_rec_cashreceipt.applied_amt = 0 
					LET l_rec_cashreceipt.disc_amt = 0 - l_rec_s_cashreceipt.disc_amt 
					LET l_rec_cashreceipt.job_code = l_rec_s_cashreceipt.cash_num 
					LET l_rec_cashreceipt.on_state_flag = "N" 
					LET l_rec_cashreceipt.posted_flag = CASHRECEIPT_POST_FLAG_STATUS_NOT_POSTED_N 
					LET l_rec_cashreceipt.next_num = 1 
					LET l_rec_cashreceipt.com1_text = l_rec_s_cashreceipt.com1_text 
					LET l_rec_cashreceipt.com2_text = l_rec_s_cashreceipt.com2_text 
					LET l_rec_cashreceipt.bank_text = l_rec_bankstatement.ref_text 
					LET l_rec_cashreceipt.cash_type_ind = "R" ## reversal 
					LET l_rec_cashreceipt.chq_date = l_rec_bankstatement.tran_date 
					LET l_rec_cashreceipt.drawer_text = l_rec_s_cashreceipt.drawer_text 
					LET l_rec_cashreceipt.branch_text = l_rec_s_cashreceipt.branch_text 
					LET l_rec_cashreceipt.banked_flag = "Y" 
					LET l_rec_cashreceipt.banked_date = l_rec_bankstatement.tran_date 
					LET l_rec_cashreceipt.currency_code = 
					l_rec_bankstatement.ref_currency_code 
					LET l_rec_cashreceipt.conv_qty = l_rec_bankstatement.conv_qty 
					LET l_rec_cashreceipt.bank_code = glob_rec_bank.bank_code 
					LET l_rec_cashreceipt.bank_currency_code = 
					l_rec_bankstatement.bank_currency_code 
					SELECT * INTO l_rec_userlocn.* FROM userlocn 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND sign_on_code = glob_rec_kandoouser.sign_on_code 
					LET l_rec_cashreceipt.locn_code = l_rec_userlocn.locn_code 
					LET l_rec_cashreceipt.order_num = NULL 
					LET l_rec_banking.bk_cmpy = glob_rec_kandoouser.cmpy_code 
					LET l_rec_banking.bk_acct = l_rec_bankstatement.acct_code 
					LET l_rec_banking.bk_type = l_rec_bankstatement.entry_type_code 
					LET l_rec_banking.bk_bankdt = l_rec_bankstatement.tran_date 
					LET l_rec_banking.bk_desc = "Dishon. cheque" 
					LET l_rec_banking.bk_sh_no = l_rec_bankstatement.sheet_num 
					LET l_rec_banking.bk_seq_no = l_rec_bankstatement.seq_num 
					LET l_rec_banking.bk_rec_part = NULL 
					LET l_rec_banking.bk_year = l_rec_bankstatement.year_num 
					LET l_rec_banking.bk_per = l_rec_bankstatement.period_num 
					LET l_rec_banking.bk_cred = 0 
					LET l_rec_banking.bk_debit = l_rec_bankstatement.tran_amt 
					LET l_rec_banking.bk_enter = l_rec_bankstatement.entry_code 
					LET l_rec_banking.doc_num = 0 
					LET l_receipt_age = l_rec_arparms.cust_age_date 
					- l_rec_cashreceipt.cash_date 
					CASE 
						WHEN l_receipt_age <= 0 
							LET l_rec_customer.curr_amt = l_rec_customer.curr_amt 
							- l_rec_cashreceipt.cash_amt 
						WHEN (l_receipt_age >=1 AND l_receipt_age <=30 ) 
							LET l_rec_customer.over1_amt = l_rec_customer.over1_amt 
							- l_rec_cashreceipt.cash_amt 
						WHEN l_receipt_age >=31 AND l_receipt_age <=60 
							LET l_rec_customer.over30_amt = l_rec_customer.over30_amt 
							- l_rec_cashreceipt.cash_amt 
						WHEN l_receipt_age >=61 AND l_receipt_age <=90 
							LET l_rec_customer.over60_amt = l_rec_customer.over60_amt 
							- l_rec_cashreceipt.cash_amt 
						OTHERWISE 
							LET l_rec_customer.over90_amt = l_rec_customer.over90_amt 
							- l_rec_cashreceipt.cash_amt 
					END CASE 
					LET l_err_message = "Inserting Banking Table - dc" 
					INSERT INTO banking VALUES (l_rec_banking.*) 
					LET l_total_applied = 0 
					DECLARE c_invoicepay CURSOR FOR 
					SELECT * FROM invoicepay 
					WHERE cmpy_code = l_rec_s_cashreceipt.cmpy_code 
					AND cust_code = l_rec_s_cashreceipt.cust_code 
					AND ref_num = l_rec_s_cashreceipt.cash_num 
					AND pay_type_ind = TRAN_TYPE_RECEIPT_CA 
					FOREACH c_invoicepay INTO l_rec_s_invoicepay.* 
						DECLARE c2_invoicehead CURSOR FOR 
						SELECT * FROM invoicehead 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND inv_num = l_rec_s_invoicepay.inv_num 
						FOR UPDATE 
						OPEN c2_invoicehead 
						FETCH c2_invoicehead INTO l_rec_invoicehead.* 
						LET l_rec_invoicehead.paid_amt = l_rec_invoicehead.paid_amt 
						- l_rec_s_invoicepay.pay_amt 
						- l_rec_s_invoicepay.disc_amt 
						LET l_rec_invoicehead.seq_num = l_rec_invoicehead.seq_num + 1 
						UPDATE invoicehead 
						SET paid_amt = l_rec_invoicehead.paid_amt, 
						paid_date = null, 
						disc_taken_amt=disc_taken_amt-l_rec_s_invoicepay.disc_amt, 
						seq_num = l_rec_invoicehead.seq_num 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND inv_num = l_rec_s_invoicepay.inv_num 
						LET l_invoice_age = l_rec_arparms.cust_age_date 
						- l_rec_invoicehead.due_date 
						LET l_total_applied = l_total_applied - l_rec_s_invoicepay.pay_amt 
						LET l_rec_invoicepay.cmpy_code = glob_rec_kandoouser.cmpy_code 
						LET l_rec_invoicepay.cust_code = l_rec_cashreceipt.cust_code 
						LET l_rec_invoicepay.inv_num = l_rec_invoicehead.inv_num 
						LET l_rec_invoicepay.ref_num = l_rec_cashreceipt.cash_num 
						LET l_rec_invoicepay.appl_num = 0 
						LET l_rec_invoicepay.pay_text = l_rec_cashreceipt.cheque_text 
						LET l_rec_invoicepay.apply_num = l_rec_cashreceipt.next_num 
						LET l_rec_invoicepay.pay_type_ind = TRAN_TYPE_RECEIPT_CA 
						LET l_rec_invoicepay.pay_date = l_rec_cashreceipt.cash_date 
						LET l_rec_invoicepay.pay_amt = 0 - l_rec_s_invoicepay.pay_amt 
						LET l_rec_invoicepay.disc_amt = 0 - l_rec_s_invoicepay.disc_amt 
						LET l_err_message = " Invoicepay table INSERT - dc" 
						INSERT INTO invoicepay VALUES (l_rec_invoicepay.*) 
						LET l_base_apply_amt1 = 
						l_rec_invoicepay.pay_amt / l_rec_invoicehead.conv_qty 
						LET l_base_apply_amt2 = 
						l_rec_invoicepay.pay_amt / l_rec_cashreceipt.conv_qty 
						LET l_rec_exchangevar.exchangevar_amt = 
						l_base_apply_amt1 - l_base_apply_amt2 
						IF l_rec_exchangevar.exchangevar_amt != 0 THEN 
							LET l_rec_exchangevar.cmpy_code = glob_rec_kandoouser.cmpy_code 
							LET l_rec_exchangevar.year_num = l_rec_cashreceipt.year_num 
							LET l_rec_exchangevar.period_num=l_rec_cashreceipt.period_num 
							LET l_rec_exchangevar.source_ind = "A" 
							LET l_rec_exchangevar.tran_date = l_rec_cashreceipt.cash_date 
							LET l_rec_exchangevar.ref_code = l_rec_cashreceipt.cust_code 
							LET l_rec_exchangevar.tran_type1_ind = TRAN_TYPE_INVOICE_IN 
							LET l_rec_exchangevar.ref1_num = l_rec_invoicehead.inv_num 
							LET l_rec_exchangevar.tran_type2_ind = TRAN_TYPE_RECEIPT_CA 
							LET l_rec_exchangevar.ref2_num = l_rec_cashreceipt.cash_num 
							LET l_rec_exchangevar.currency_code = 
							l_rec_cashreceipt.currency_code 
							LET l_rec_exchangevar.posted_flag = "N" 
							LET l_err_message ="Exchangevar table INSERT - dc" 
							INSERT INTO exchangevar VALUES (l_rec_exchangevar.*) 
						END IF 
						IF l_receipt_age <= 0 
						AND l_invoice_age <=0 
						AND l_rec_invoicepay.disc_amt = 0 THEN 
						ELSE 
							CASE 
								WHEN l_receipt_age <= 0 
									LET l_rec_customer.curr_amt = l_rec_customer.curr_amt 
									+ l_rec_invoicepay.pay_amt 
								WHEN (l_receipt_age >=1 AND l_receipt_age <=30 ) 
									LET l_rec_customer.over1_amt = l_rec_customer.over1_amt 
									+ l_rec_invoicepay.pay_amt 
								WHEN l_receipt_age >=31 AND l_receipt_age <=60 
									LET l_rec_customer.over30_amt = l_rec_customer.over30_amt 
									+ l_rec_invoicepay.pay_amt 
								WHEN l_receipt_age >=61 AND l_receipt_age <=90 
									LET l_rec_customer.over60_amt = l_rec_customer.over60_amt 
									+ l_rec_invoicepay.pay_amt 
								OTHERWISE 
									LET l_rec_customer.over90_amt = l_rec_customer.over90_amt 
									+ l_rec_invoicepay.pay_amt 
							END CASE 
							CASE 
								WHEN l_invoice_age <= 0 
									LET l_rec_customer.curr_amt = l_rec_customer.curr_amt 
									- l_rec_invoicepay.pay_amt 
								WHEN l_invoice_age >=1 AND l_invoice_age <=30 
									LET l_rec_customer.over1_amt = l_rec_customer.over1_amt 
									- l_rec_invoicepay.pay_amt 
								WHEN l_invoice_age >=31 AND l_invoice_age <=60 
									LET l_rec_customer.over30_amt = l_rec_customer.over30_amt 
									- l_rec_invoicepay.pay_amt 
								WHEN l_invoice_age >=61 AND l_invoice_age <=90 
									LET l_rec_customer.over60_amt = l_rec_customer.over60_amt 
									- l_rec_invoicepay.pay_amt 
								OTHERWISE 
									LET l_rec_customer.over90_amt = l_rec_customer.over90_amt 
									- l_rec_invoicepay.pay_amt 
							END CASE 
							IF l_rec_invoicepay.disc_amt <> 0 THEN 
								CASE 
									WHEN l_invoice_age <= 0 
										LET l_rec_customer.curr_amt = l_rec_customer.curr_amt 
										- l_rec_invoicepay.disc_amt 
									WHEN l_invoice_age >=1 AND l_invoice_age <=30 
										LET l_rec_customer.over1_amt = l_rec_customer.over1_amt 
										- l_rec_invoicepay.disc_amt 
									WHEN l_invoice_age >=31 AND l_invoice_age <=60 
										LET l_rec_customer.over30_amt = l_rec_customer.over30_amt 
										- l_rec_invoicepay.disc_amt 
									WHEN l_invoice_age >=61 AND l_invoice_age <=90 
										LET l_rec_customer.over60_amt = l_rec_customer.over60_amt 
										- l_rec_invoicepay.disc_amt 
									OTHERWISE 
										LET l_rec_customer.over90_amt = l_rec_customer.over90_amt 
										- l_rec_invoicepay.disc_amt 
								END CASE 
							END IF 
						END IF 
						CLOSE c2_invoicehead 
					END FOREACH 
					FREE c_invoicepay 
					LET l_rec_customer.bal_amt = l_rec_customer.bal_amt 
					- l_rec_cashreceipt.cash_amt 
					LET l_rec_customer.next_seq_num = l_rec_customer.next_seq_num + 1 
					IF year(l_rec_cashreceipt.cash_date) > 
					year(l_rec_customer.last_pay_date) THEN 
						LET l_rec_customer.ytdp_amt = 0 
					END IF 
					IF (year(l_rec_cashreceipt.cash_date) > 
					year(l_rec_customer.last_pay_date) 
					OR month(l_rec_cashreceipt.cash_date) > 
					month(l_rec_customer.last_pay_date)) THEN 
						LET l_rec_customer.mtdp_amt = 0 
					END IF 
					LET l_rec_customer.ytdp_amt = 
					l_rec_customer.ytdp_amt + l_rec_cashreceipt.cash_amt 
					LET l_rec_customer.mtdp_amt = 
					l_rec_customer.mtdp_amt + l_rec_cashreceipt.cash_amt 
					LET l_rec_araudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
					LET l_rec_araudit.tran_date = l_rec_cashreceipt.cash_date 
					LET l_rec_araudit.cust_code = l_rec_cashreceipt.cust_code 
					LET l_rec_araudit.seq_num = l_rec_customer.next_seq_num 
					LET l_rec_araudit.tran_type_ind = TRAN_TYPE_RECEIPT_CA 
					LET l_rec_araudit.source_num = l_rec_cashreceipt.cash_num 
					LET l_rec_araudit.tran_text = "Dishon.Cheque" 
					LET l_rec_araudit.tran_amt = 0 - l_rec_cashreceipt.cash_amt 
					LET l_rec_araudit.entry_code = glob_rec_kandoouser.sign_on_code 
					LET l_rec_araudit.year_num = l_rec_cashreceipt.year_num 
					LET l_rec_araudit.period_num = l_rec_cashreceipt.period_num 
					LET l_rec_araudit.bal_amt = l_rec_customer.bal_amt 
					LET l_rec_araudit.currency_code = l_rec_customer.currency_code 
					LET l_rec_araudit.conv_qty = l_rec_cashreceipt.conv_qty 
					LET l_rec_araudit.entry_date = today 
					LET l_err_message = "Inserting AR Audit Table - dc" 
					INSERT INTO araudit VALUES (l_rec_araudit.*) 
					IF l_rec_cashreceipt.disc_amt != 0 THEN 
						LET l_rec_customer.bal_amt = l_rec_customer.bal_amt 
						- l_rec_cashreceipt.disc_amt 
						LET l_rec_customer.next_seq_num = l_rec_customer.next_seq_num + 1 
						LET l_rec_araudit.seq_num = l_rec_customer.next_seq_num 
						LET l_rec_araudit.tran_amt = 0 - l_rec_cashreceipt.disc_amt 
						LET l_rec_araudit.bal_amt = l_rec_customer.bal_amt 
						LET l_rec_araudit.tran_text = "Reverse disc." 
						LET l_err_message = "Inserting AR Audit Table - dc" 
						INSERT INTO araudit VALUES (l_rec_araudit.*) 
					END IF 
					LET l_err_message = "Updating Customer Table - dc" 
					UPDATE customer 
					SET bal_amt = l_rec_customer.bal_amt, 
					curr_amt = l_rec_customer.curr_amt, 
					over1_amt = l_rec_customer.over1_amt, 
					over30_amt = l_rec_customer.over30_amt, 
					over60_amt = l_rec_customer.over60_amt, 
					over90_amt = l_rec_customer.over90_amt, 
					cred_bal_amt = l_rec_customer.cred_limit_amt 
					- l_rec_customer.bal_amt, 
					mtdp_amt = l_rec_customer.mtdp_amt, 
					ytdp_amt = l_rec_customer.ytdp_amt, 
					next_seq_num = l_rec_customer.next_seq_num 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cust_code = l_rec_cashreceipt.cust_code 
					LET l_err_message = "Inserting Cash Receipt - dc" 
					LET l_rec_cashreceipt.applied_amt = l_total_applied 
					IF l_rec_cashreceipt.applied_amt > 0 
					AND l_rec_cashreceipt.applied_amt > l_rec_cashreceipt.cash_amt THEN 
						LET l_error_line = 
						"Sum of Receipt Applications Exceeds Receipt amount" 
						CALL trans_error(l_rec_bankstatement.sheet_num, 
						l_rec_bankstatement.seq_num, 
						l_rec_bankstatement.entry_type_code, 
						l_error_line) 
						RETURN 
					ELSE 
						UPDATE bankstatement 
						SET applied_amt = l_rec_cashreceipt.applied_amt 
						WHERE cmpy_code = l_rec_bankstatement.cmpy_code 
						AND bank_code = l_rec_bankstatement.bank_code 
						AND sheet_num = l_rec_bankstatement.sheet_num 
						AND seq_num = l_rec_bankstatement.seq_num 
					END IF 
					LET l_err_message = "Inserting Cash Receipt table - dc" 
					INSERT INTO cashreceipt VALUES (l_rec_cashreceipt.*) 
					LET l_err_message = "Updating Cash Receipt table - dc" 
					UPDATE cashreceipt SET job_code = l_rec_cashreceipt.cash_num 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cash_num = l_rec_s_cashreceipt.cash_num 
					#
					# PA - Payments
					#
				WHEN l_rec_bankstatement.entry_type_code = "PA" 
					LET l_err_message = "Inserting Payment Header - pa" 
					INITIALIZE l_rec_cheque.* TO NULL 
					SELECT * INTO l_rec_vendor.* 
					FROM vendor 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND vend_code = l_rec_bankstatement.ref_code 
					IF status = NOTFOUND THEN 
						LET l_error_line = 
						" Vendor ", l_rec_bankstatement.ref_code clipped, 
						" does NOT exist" 
						CALL trans_error(l_rec_bankstatement.sheet_num, 
						l_rec_bankstatement.seq_num, 
						l_rec_bankstatement.entry_type_code, 
						l_error_line) 
						RETURN 
					END IF 
					LET l_rec_cheque.cmpy_code = glob_rec_kandoouser.cmpy_code 
					LET l_rec_cheque.vend_code = l_rec_bankstatement.ref_code 
					LET l_rec_cheque.cheq_code = l_rec_bankstatement.ref_num 
					LET l_rec_cheque.pay_meth_ind = "4" ### direct payments 
					LET l_rec_cheque.doc_num = 0 
					LET l_rec_cheque.com3_text = l_rec_bankstatement.ref_code 
					LET l_rec_cheque.bank_acct_code = l_rec_bankstatement.acct_code 
					LET l_rec_cheque.entry_code = l_rec_bankstatement.entry_code 
					LET l_rec_cheque.entry_date = l_rec_bankstatement.entry_date 
					LET l_rec_cheque.cheq_date = l_rec_bankstatement.tran_date 
					LET l_rec_cheque.year_num = l_rec_bankstatement.year_num 
					LET l_rec_cheque.period_num = l_rec_bankstatement.period_num 
					IF l_rec_bankstatement.bank_currency_code = 
					l_rec_bankstatement.ref_currency_code THEN 
						LET l_rec_cheque.pay_amt = l_rec_bankstatement.tran_amt 
					ELSE 
						LET l_rec_cheque.pay_amt = l_rec_bankstatement.other_amt 
					END IF 
					LET l_rec_cheque.apply_amt = 0 
					LET l_rec_cheque.disc_amt = 0 
					LET l_rec_cheque.post_flag = "N" 
					LET l_rec_cheque.recon_flag = "Y" 
					LET l_rec_cheque.next_appl_num = 1 
					LET l_rec_cheque.com1_text = l_rec_bankstatement.com1_text 
					LET l_rec_cheque.com2_text = l_rec_bankstatement.com2_text 
					LET l_rec_cheque.rec_state_num = l_rec_bankstatement.sheet_num 
					LET l_rec_cheque.rec_line_num = l_rec_bankstatement.seq_num 
					LET l_rec_cheque.currency_code = l_rec_bankstatement.ref_currency_code 
					LET l_rec_cheque.conv_qty = l_rec_bankstatement.conv_qty 
					LET l_rec_cheque.bank_code = glob_rec_bank.bank_code 
					LET l_rec_cheque.bank_currency_code = 
					l_rec_bankstatement.bank_currency_code 
					LET l_rec_cheque.net_pay_amt = l_rec_cheque.pay_amt 
					LET l_rec_cheque.withhold_tax_ind = "0" 
					LET l_rec_cheque.tax_per = 0 
					LET l_rec_cheque.tax_amt = 0 
					LET l_rec_cheque.contra_amt = 0 
					LET l_rec_cheque.whtax_rep_ind = "0" 
					LET l_rec_cheque.source_ind = "1" 
					LET l_rec_cheque.source_text = l_rec_cheque.vend_code 
					LET l_total_applied = 0 
					LET l_total_disc = 0 

					DECLARE c4_bankdetails CURSOR FOR 
					SELECT * FROM bankdetails 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND bank_code = l_rec_bankstatement.bank_code 
					AND sheet_num = l_rec_bankstatement.sheet_num 
					AND seq_num = l_rec_bankstatement.seq_num 

					FOREACH c4_bankdetails INTO l_rec_bankdetails.* 
						DECLARE c1_voucher CURSOR FOR 
						SELECT * FROM voucher 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND vouch_code = l_rec_bankdetails.ref_num 
						FOR UPDATE 
						FOREACH c1_voucher INTO l_rec_voucher.* 
							LET l_rec_voucher.paid_amt = l_rec_voucher.paid_amt 
							+ l_rec_bankdetails.tran_amt 
							+ l_rec_bankdetails.disc_amt 
							IF l_rec_voucher.paid_amt > l_rec_voucher.total_amt THEN 
								LET l_error_line = "Voucher no.", 
								l_rec_bankdetails.ref_num USING "<<<<<<<<", 
								" Paid Amount Exceeds Total Voucher Amount " 
								CALL trans_error(l_rec_bankstatement.sheet_num, 
								l_rec_bankstatement.seq_num, 
								l_rec_bankstatement.entry_type_code, 
								l_error_line) 
								RETURN 
							END IF 
							IF l_rec_voucher.taken_disc_amt IS NULL THEN 
								LET l_rec_voucher.taken_disc_amt = 0 
							END IF 
							LET l_rec_voucher.pay_seq_num = l_rec_voucher.pay_seq_num + 1 
							LET l_rec_voucher.taken_disc_amt = l_rec_voucher.taken_disc_amt 
							+ l_rec_bankdetails.disc_amt 
							IF l_rec_voucher.total_amt = l_rec_voucher.paid_amt THEN 
								LET l_rec_voucher.paid_date = l_rec_cheque.cheq_date 
							END IF 
							LET l_err_message = "Updating Voucher table - pa" 

							UPDATE voucher 
							SET paid_amt = l_rec_voucher.paid_amt, 
							pay_seq_num = l_rec_voucher.pay_seq_num, 
							taken_disc_amt = l_rec_voucher.taken_disc_amt, 
							paid_date = l_rec_voucher.paid_date 
							WHERE CURRENT OF c1_voucher 
							LET l_total_applied = l_total_applied + l_rec_bankdetails.tran_amt 
							LET l_total_disc = l_total_disc + l_rec_bankdetails.disc_amt 
							LET l_rec_voucherpays.cmpy_code = glob_rec_kandoouser.cmpy_code 
							LET l_rec_voucherpays.vend_code = l_rec_cheque.vend_code 
							LET l_rec_voucherpays.vouch_code = l_rec_voucher.vouch_code 
							LET l_rec_voucherpays.seq_num = 0 
							LET l_rec_voucherpays.pay_num = l_rec_cheque.cheq_code 
							LET l_rec_voucherpays.apply_num = l_rec_voucher.pay_seq_num 
							LET l_rec_voucherpays.pay_type_code = "CH" 
							LET l_rec_voucherpays.pay_date = l_rec_cheque.cheq_date 
							LET l_rec_voucherpays.apply_amt = l_rec_bankdetails.tran_amt 
							LET l_rec_voucherpays.disc_amt = l_rec_bankdetails.disc_amt 
							LET l_rec_voucherpays.pay_meth_ind = l_rec_cheque.pay_meth_ind 
							LET l_rec_voucherpays.bank_code = l_rec_cheque.bank_code 
							LET l_rec_voucherpays.rev_flag = NULL 
							LET l_rec_voucherpays.remit_doc_num = 0 
							LET l_err_message = "Inserting Voucherpays table - pa" 

							INSERT INTO voucherpays VALUES (l_rec_voucherpays.*) 
							LET l_base_apply_amt1 = 
							l_rec_voucherpays.apply_amt / l_rec_voucher.conv_qty 
							LET l_base_apply_amt2 = 
							l_rec_voucherpays.apply_amt / l_rec_cheque.conv_qty 
							LET l_rec_exchangevar.exchangevar_amt = 
							l_base_apply_amt1 - l_base_apply_amt2 
							IF l_rec_exchangevar.exchangevar_amt != 0 THEN 
								LET l_rec_exchangevar.cmpy_code = glob_rec_kandoouser.cmpy_code 
								LET l_rec_exchangevar.year_num = l_rec_cheque.year_num 
								LET l_rec_exchangevar.period_num = l_rec_cheque.period_num 
								LET l_rec_exchangevar.source_ind = "P" 
								LET l_rec_exchangevar.tran_date = l_rec_cheque.cheq_date 
								LET l_rec_exchangevar.ref_code = l_rec_cheque.vend_code 
								LET l_rec_exchangevar.tran_type1_ind = "VO" 
								LET l_rec_exchangevar.ref1_num = l_rec_voucher.vouch_code 
								LET l_rec_exchangevar.tran_type2_ind = "CH" 
								LET l_rec_exchangevar.ref2_num = l_rec_cheque.cheq_code 
								LET l_rec_exchangevar.currency_code=l_rec_voucher.currency_code 
								LET l_rec_exchangevar.posted_flag = "N" 
								INSERT INTO exchangevar VALUES (l_rec_exchangevar.*) 
							END IF 
						END FOREACH 
						FREE c1_voucher 
					END FOREACH 
					FREE c4_bankdetails 
					IF l_rec_cheque.cheq_date > l_rec_vendor.last_payment_date THEN 
						LET l_rec_vendor.last_payment_date = l_rec_cheque.cheq_date 
					END IF 
					LET l_rec_vendor.bal_amt = l_rec_vendor.bal_amt - l_rec_cheque.pay_amt 
					LET l_rec_vendor.curr_amt = l_rec_vendor.curr_amt - l_rec_cheque.pay_amt 
					LET l_rec_vendor.next_seq_num = l_rec_vendor.next_seq_num + 1 
					LET l_rec_apaudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
					LET l_rec_apaudit.tran_date = l_rec_cheque.cheq_date 
					LET l_rec_apaudit.vend_code = l_rec_cheque.vend_code 
					LET l_rec_apaudit.seq_num = l_rec_vendor.next_seq_num 
					LET l_rec_apaudit.trantype_ind = "CH" 
					LET l_rec_apaudit.source_num = l_rec_cheque.cheq_code 
					LET l_rec_apaudit.tran_text = "Direct payment" 
					LET l_rec_apaudit.tran_amt = 0 - l_rec_cheque.pay_amt 
					LET l_rec_apaudit.entry_code = l_rec_cheque.entry_code 
					LET l_rec_apaudit.year_num = l_rec_cheque.year_num 
					LET l_rec_apaudit.period_num = l_rec_cheque.period_num 
					LET l_rec_apaudit.bal_amt = l_rec_vendor.bal_amt 
					LET l_rec_apaudit.currency_code = l_rec_cheque.currency_code 
					LET l_rec_apaudit.conv_qty = l_rec_cheque.conv_qty 
					LET l_rec_apaudit.entry_date = today 
					LET l_err_message = "Inserting AP audit table 1 - pa" 

					INSERT INTO apaudit VALUES (l_rec_apaudit.*) 
					IF l_total_disc > 0 THEN 
						LET l_rec_vendor.curr_amt = l_rec_vendor.curr_amt - l_total_disc 
						LET l_rec_vendor.bal_amt = l_rec_vendor.bal_amt - l_total_disc 
						LET l_rec_vendor.next_seq_num = l_rec_vendor.next_seq_num + 1 
						LET l_rec_apaudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
						LET l_rec_apaudit.tran_date = l_rec_cheque.cheq_date 
						LET l_rec_apaudit.vend_code = l_rec_cheque.vend_code 
						LET l_rec_apaudit.seq_num = l_rec_vendor.next_seq_num 
						LET l_rec_apaudit.trantype_ind = "CH" 
						LET l_rec_apaudit.year_num = l_rec_cheque.year_num 
						LET l_rec_apaudit.period_num = l_rec_cheque.period_num 
						LET l_rec_apaudit.source_num = l_rec_cheque.cheq_code 
						LET l_rec_apaudit.tran_text = "Apply discount" 
						LET l_rec_apaudit.tran_amt = 0 - l_total_disc 
						LET l_rec_apaudit.entry_code = l_rec_cheque.entry_code 
						LET l_rec_apaudit.bal_amt = l_rec_vendor.bal_amt 
						LET l_rec_apaudit.currency_code = l_rec_cheque.currency_code 
						LET l_rec_apaudit.conv_qty = l_rec_cheque.conv_qty 
						LET l_rec_apaudit.entry_date = today 
						LET l_err_message = "Inserting AP audit table 2 - pa" 
						INSERT INTO apaudit VALUES (l_rec_apaudit.*) 
					END IF 
					LET l_err_message = "Vendor table UPDATE - pa" 

					UPDATE vendor 
					SET bal_amt = l_rec_vendor.bal_amt, 
					curr_amt = l_rec_vendor.curr_amt, 
					last_payment_date = l_rec_vendor.last_payment_date, 
					next_seq_num = l_rec_vendor.next_seq_num 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND vend_code = l_rec_cheque.vend_code 
					LET l_err_message = "Inserting Chequ table - pa" 
					LET l_rec_cheque.apply_amt = l_rec_cheque.apply_amt + l_total_applied 
					LET l_rec_cheque.disc_amt = l_rec_cheque.disc_amt + l_total_disc 
					IF l_rec_cheque.apply_amt > l_rec_cheque.pay_amt THEN 
						## what ???
					END IF 
					INSERT INTO cheque VALUES (l_rec_cheque.*) 
					##
					## DO NOT MOVE THE NEXT LINE - VALUE MUST BE RESULT
					## OF LAST DATABASE ACTION
					LET l_pay_doc_num = sqlca.sqlerrd[2] 
					##
					UPDATE voucherpays 
					SET pay_doc_num = l_pay_doc_num 
					WHERE vend_code = l_rec_cheque.vend_code 
					AND pay_num = l_rec_cheque.cheq_code 
					AND pay_meth_ind = l_rec_cheque.pay_meth_ind 
					AND bank_code = l_rec_cheque.bank_code 
					AND pay_type_code = 'CH' 
					#
					# TO - Transfers Out
					#
				WHEN l_rec_bankstatement.entry_type_code = "TO" 
					LET l_err_message = "Updating Banking Table - to" 
					UPDATE banking 
					SET bk_rec_part = null, 
					bk_sh_no = glob_rec_bank.sheet_num, 
					bk_seq_no = l_rec_bankstatement.seq_num 
					WHERE doc_num = l_rec_bankstatement.doc_num 
					#
					# TI - Transfers In
					#
				WHEN l_rec_bankstatement.entry_type_code = "TI" 
					LET l_err_message = "Updating Banking Table - ti" 
					UPDATE banking 
					SET bk_rec_part = null, 
					bk_sh_no = glob_rec_bank.sheet_num, 
					bk_seq_no = l_rec_bankstatement.seq_num 
					WHERE doc_num = l_rec_bankstatement.doc_num 
					#
					# ER - Rejected EFT's
					#
				WHEN l_rec_bankstatement.entry_type_code = "ER" 
					SELECT * INTO l_rec_cheque.* 
					FROM cheque 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cheq_code = l_rec_bankstatement.ref_code 
					AND bank_code = glob_rec_bank.bank_code 
					AND pay_meth_ind = '3' 
					LET l_com1_text = "EFT returned" 
					LET l_com2_text = "Statement ", l_rec_bankstatement.sheet_num 
					USING "<<<<<<", "/", l_rec_bankstatement.seq_num USING "<<<<" 
					CALL cancel_payment(glob_rec_kandoouser.cmpy_code, 
					glob_rec_kandoouser.sign_on_code, 
					l_rec_cheque.bank_code, 
					l_rec_cheque.cheq_code, 
					'3', 
					l_com1_text, 
					l_com2_text, 
					l_rec_cheque.rec_state_num, 
					glob_rec_glparms.*) 
					RETURNING l_call_status, l_db_status, l_call_message, 
					l_jour_num 
					IF l_call_status = -2 THEN 
						LET l_err_message = l_call_message 
						LET status = l_db_status 
						GOTO recovery 
					END IF 
					IF l_call_status = 0 THEN 
						LET glob_rec_glparms.next_jour_num = l_jour_num 
					ELSE 
						CALL trans_error(l_rec_bankstatement.sheet_num, 
						l_rec_bankstatement.seq_num, 
						l_rec_bankstatement.entry_type_code, 
						l_call_message) 
						RETURN 
					END IF 
				OTHERWISE 
					EXIT CASE 
			END CASE 
		END FOREACH 

		FREE c2_bankstatement 
		LET l_err_message= "Updating GL Parameters " 

		UPDATE glparms 
		SET next_jour_num = glob_rec_glparms.next_jour_num 
		WHERE CURRENT OF c_glparms 

		CLOSE c_glparms 
		LET l_err_message= "Updating Bank Statement " 

		UPDATE bankstatement 
		SET recon_ind = "2" 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND bank_code = glob_rec_bank.bank_code 
		AND sheet_num = glob_rec_bank.sheet_num 

		LET l_err_message= "Updating Bank table" 

		UPDATE bank 
		SET sheet_num = glob_rec_bank.sheet_num, 
		state_bal_amt = glob_rec_trans_head.close_bal_amt 
		WHERE bank_code = glob_rec_bank.bank_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 

		LET l_err_message= "Inserting Opening INTO banking" 
		INITIALIZE l_rec_banking.* TO NULL 
		LET l_rec_banking.bk_cmpy = glob_rec_kandoouser.cmpy_code 
		LET l_rec_banking.bk_acct = glob_rec_bank.acct_code 
		LET l_rec_banking.bk_type = "XO" 
		LET l_rec_banking.bk_bankdt = today 
		LET l_rec_banking.bk_desc = "Opening balance" 
		LET l_rec_banking.bk_sh_no = glob_rec_bank.sheet_num 
		LET l_rec_banking.bk_seq_no = 0 
		INITIALIZE l_rec_banking.bk_rec_part TO NULL 
		CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,today) 
		RETURNING l_rec_banking.bk_year, 
		l_rec_banking.bk_per 
		LET l_rec_banking.bk_cred = glob_rec_trans_head.open_bal_amt 
		LET l_rec_banking.bk_enter = glob_rec_kandoouser.sign_on_code 
		LET l_rec_banking.doc_num = 0 

		INSERT INTO banking VALUES (l_rec_banking.*) 

		LET l_err_message= "Inserting Closing INTO banking" 
		INITIALIZE l_rec_banking.* TO NULL 
		LET l_rec_banking.bk_cmpy = glob_rec_kandoouser.cmpy_code 
		LET l_rec_banking.bk_acct = glob_rec_bank.acct_code 
		LET l_rec_banking.bk_type = "XC" 
		LET l_rec_banking.bk_bankdt = today 
		LET l_rec_banking.bk_desc = "Closing balance" 
		LET l_rec_banking.bk_sh_no = glob_rec_bank.sheet_num 
		LET l_rec_banking.bk_seq_no = 0 
		INITIALIZE l_rec_banking.bk_rec_part TO NULL 
		CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,today) 
		RETURNING l_rec_banking.bk_year, 
		l_rec_banking.bk_per 
		LET l_rec_banking.bk_debit = glob_rec_trans_head.close_bal_amt 
		LET l_rec_banking.bk_enter = glob_rec_kandoouser.sign_on_code 
		LET l_rec_banking.doc_num = 0 

		INSERT INTO banking VALUES (l_rec_banking.*) 

	COMMIT WORK 

	WHENEVER ERROR stop 

	#   CLOSE WINDOW w1_GCEg

END FUNCTION 


############################################################
# FUNCTION trans_error(p_sheet_num,
#                     p_seq_num,
#                     p_trans_type,
#                     p_msg_text)
#
#
############################################################
FUNCTION trans_error(p_sheet_num, 
	p_seq_num, 
	p_trans_type, 
	p_msg_text) 
	DEFINE p_sheet_num LIKE bankstatement.sheet_num 
	DEFINE p_seq_num LIKE bankstatement.seq_num 
	DEFINE p_trans_type LIKE bankstatement.entry_type_code 
	DEFINE p_msg_text char(80) 

	DEFINE l_arr_error_text array[3] OF char(80) 
	DEFINE l_l_msgresp LIKE language.yes_flag 

	ROLLBACK WORK 
	CLEAR WINDOW w1_gceg 
	LET l_arr_error_text[1] = " Cash Book Update Error - bank:",glob_rec_bank.bank_code 
	LET l_arr_error_text[2] = " Sheet ",p_sheet_num USING "<<<<<<" clipped, 
	" - Line ",p_seq_num USING "<<<<<" clipped, 
	" - Line Type ",p_trans_type 
	LET l_arr_error_text[3] = " location:",p_msg_text 
	DISPLAY l_arr_error_text[1] at 1,1 
	CALL errorlog(l_arr_error_text[1]) 
	CALL errorlog(l_arr_error_text[2]) 
	DISPLAY l_arr_error_text[2] at 2,1 
	CALL errorlog(l_arr_error_text[3]) 
	DISPLAY l_arr_error_text[3] at 3,1 

	CALL eventsuspend() # LET l_l_msgresp=kandoomsg("U",1,"") 
	CLOSE WINDOW w1_gceg 
END FUNCTION 


