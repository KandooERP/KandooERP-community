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
# FUNCTION reconcile calls the appropriate reconciliation procedure FOR
# the selected bank statement transaction AND returns the result TO the
# main entry FUNCTION

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
# FUNCTION reconcile(p_seq_num)
#
# This FUNCTION validates a cashbook entry TO ensure
#  1.  Entry has valid cross reference with another transaction
#  2.  Entry IS of the correct bank
#  3.  Entry IS of the correct currency
#  4.  Entry has corresponding amount of Xreferenced transaction
#  5.  Entry has appropraite date - ie: Not presented before it originated.
#  6.  Entry does NOT appear on another bank sheet
#
###########################################################################
FUNCTION reconcile(p_seq_num) 
	DEFINE p_seq_num INTEGER 
	DEFINE l_reconcile_flag SMALLINT 
	DEFINE l_rec_bankstatement RECORD LIKE bankstatement.* 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_cashreceipt RECORD LIKE cashreceipt.* 
	DEFINE l_rec_invoicehead RECORD LIKE invoicehead.* 
	DEFINE l_rec_banking RECORD LIKE banking.* 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_voucher RECORD LIKE voucher.* 
	DEFINE l_rec_cheque RECORD LIKE cheque.* 
	DEFINE l_desc_text char(40) 
	DEFINE l_err_message char(60) 
	--DEFINE l_cnt SMALLINT
	--DEFINE l_withhold_tax_ind LIKE vendortype.withhold_tax_ind
	DEFINE l_tot_net_pay_amt LIKE cheque.net_pay_amt 
	--DEFINE l_num_ref_code LIKE cheque.eft_run_num
	DEFINE l_msgresp LIKE language.yes_flag 

	SELECT * INTO l_rec_bankstatement.* 
	FROM t_bkstate 
	WHERE seq_num = p_seq_num 

	LET l_reconcile_flag = false 
	CASE l_rec_bankstatement.entry_type_code 
	##
		WHEN "BC" 
			##
			## Bank Charges
			##
			IF l_rec_bankstatement.doc_num > 0 THEN 
				## Possible serial number Xref TO "banking" entry
				SELECT * INTO l_rec_banking.* 
				FROM banking 
				WHERE doc_num = l_rec_bankstatement.doc_num 
				IF status = NOTFOUND THEN 
					LET l_rec_bankstatement.doc_num = 0 
				END IF 
				IF l_rec_banking.bk_cmpy != glob_rec_kandoouser.cmpy_code 
				OR l_rec_banking.bk_acct != glob_rec_bank.acct_code 
				OR l_rec_banking.bk_debit != l_rec_bankstatement.tran_amt 
				OR l_rec_banking.bk_type != "BC" THEN 
					## Something has changed so break Xreference
					LET l_rec_bankstatement.doc_num = 0 
				END IF 
				IF (l_rec_banking.bk_sh_no IS NOT NULL 
				OR l_rec_banking.bk_seq_no IS NOT null) 
				AND (l_rec_banking.bk_sh_no != l_rec_bankstatement.sheet_num 
				OR l_rec_banking.bk_seq_no != l_rec_bankstatement.seq_num) THEN 
					## Entry has been reconciled on another sheet so break Xref
					LET l_rec_bankstatement.doc_num = 0 
				END IF 
			END IF 
			IF l_rec_bankstatement.doc_num = 0 THEN 
				DECLARE c1_banking CURSOR FOR 
				SELECT doc_num FROM banking 
				WHERE bk_cmpy = glob_rec_kandoouser.cmpy_code 
				AND bk_acct = glob_rec_bank.acct_code 
				AND bk_type = "BC" 
				AND bk_debit = l_rec_bankstatement.tran_amt 
				AND bk_sh_no IS NULL 
				OPEN c1_banking 
				FETCH c1_banking INTO l_rec_bankstatement.doc_num 
				IF status = NOTFOUND THEN 
					LET l_rec_bankstatement.doc_num = 0 
				END IF 
			END IF 
			IF l_rec_bankstatement.doc_num = 0 THEN 
				LET l_reconcile_flag = direct_banking(l_rec_bankstatement.*, 
				p_seq_num) 
			ELSE 
				LET l_reconcile_flag = true 
			END IF 

		WHEN "BD" 
			##
			## Bank Deposit
			##
			IF l_rec_bankstatement.doc_num > 0 THEN 
				## Possible serial number Xref TO "banking" entry
				SELECT * INTO l_rec_banking.* 
				FROM banking 
				WHERE doc_num = l_rec_bankstatement.doc_num 
				IF status = NOTFOUND THEN 
					LET l_rec_bankstatement.doc_num = 0 
				END IF 
				IF l_rec_banking.bk_cmpy != glob_rec_kandoouser.cmpy_code 
				OR l_rec_banking.bk_acct != glob_rec_bank.acct_code 
				OR (l_rec_banking.bk_type != "CD" AND l_rec_banking.bk_type!="DP") 
				OR l_rec_banking.bk_cred != l_rec_bankstatement.tran_amt THEN 
					## Something has changed so break Xreference
					LET l_rec_bankstatement.doc_num = 0 
				END IF 
				IF (l_rec_banking.bk_sh_no IS NOT NULL 
				OR l_rec_banking.bk_seq_no IS NOT null) 
				AND (l_rec_banking.bk_sh_no != l_rec_bankstatement.sheet_num 
				OR l_rec_banking.bk_seq_no != l_rec_bankstatement.seq_num) THEN 
					## Entry has been reconciled on another sheet so break Xref
					LET l_rec_bankstatement.doc_num = 0 
				END IF 
			END IF 
			IF l_rec_bankstatement.doc_num = 0 THEN 
				DECLARE c2_banking CURSOR FOR 
				SELECT doc_num FROM banking 
				WHERE bk_cmpy = glob_rec_kandoouser.cmpy_code 
				AND bk_acct = glob_rec_bank.acct_code 
				AND bk_type in ("CD","DP") 
				AND bk_cred = l_rec_bankstatement.tran_amt 
				AND bk_sh_no IS NULL 
				OPEN c2_banking 
				FETCH c2_banking INTO l_rec_bankstatement.doc_num 
				IF status = NOTFOUND THEN 
					LET l_rec_bankstatement.doc_num = 0 
				END IF 
			END IF 
			IF l_rec_bankstatement.doc_num = 0 THEN 
				LET l_reconcile_flag = false 
			ELSE 
				LET l_reconcile_flag = true 
			END IF 
			
		WHEN "CH" 
			##
			## AP Cheques
			##
			IF l_rec_bankstatement.doc_num > 0 THEN 
				## Possible serial number Xref TO "cheque" entry
				SELECT * INTO l_rec_cheque.* 
				FROM cheque 
				WHERE doc_num = l_rec_bankstatement.doc_num 
				CASE 
					WHEN status = NOTFOUND 
						## Serial number Xref invalid
						LET l_rec_bankstatement.doc_num = 0 
					WHEN l_rec_cheque.cheq_code != l_rec_bankstatement.ref_code 
						OR l_rec_cheque.bank_code != glob_rec_bank.bank_code 
						OR l_rec_cheque.pay_meth_ind NOT matches "[12]" 
						## Details do NOT match so break Xref
						LET l_rec_bankstatement.doc_num = 0 
				END CASE 
			END IF 
			IF NOT numeric_value(l_rec_bankstatement.ref_code) THEN 
				LET l_err_message = "Cheque Code IS NOT numeric" 
				LET l_rec_bankstatement.doc_num = 0 
			ELSE 
				SELECT * INTO l_rec_cheque.* 
				FROM cheque 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cheq_code = l_rec_bankstatement.ref_code 
				AND bank_code = glob_rec_bank.bank_code 
				AND pay_meth_ind in ("1","2") 
				
				CASE 
					WHEN status = NOTFOUND 
						LET l_err_message = "Cheque Code does NOT exist" 
						LET l_rec_bankstatement.doc_num = 0 
					WHEN l_rec_cheque.currency_code != glob_rec_bank.currency_code 
						AND glob_rec_bank.currency_code != glob_rec_glparms.base_currency_code 
						LET l_err_message = 
						"Currency of Cheque IS Invalid FOR this bank" 
						LET l_rec_bankstatement.doc_num = 0 
					WHEN l_rec_cheque.currency_code = glob_rec_bank.currency_code 
						AND l_rec_cheque.net_pay_amt != l_rec_bankstatement.tran_amt 
						LET l_err_message = "Cheque Amount does NOT match entry" 
						LET l_rec_bankstatement.doc_num = 0 
					WHEN l_rec_cheque.cheq_date > l_rec_bankstatement.tran_date 
						LET l_err_message = 
						" Cheque No. ",l_rec_cheque.cheq_code USING "<<<<<<<<<", 
						" cannot be presented before ", 
						l_rec_cheque.cheq_date USING "dd mmm yy"," " 
						LET l_rec_bankstatement.doc_num = 0 
					WHEN l_rec_cheque.recon_flag = "Y" 
						LET l_err_message = "Cheque IS already reconciled" 
						LET l_rec_bankstatement.doc_num = 0 
					WHEN l_rec_cheque.part_recon_flag = "Y" 
						AND l_rec_cheque.rec_state_num != glob_rec_bank.sheet_num 
						LET l_err_message = 
						"Cheque has been tentatively reconciled on Another statement" 
						LET l_rec_bankstatement.doc_num = 0 
					WHEN l_rec_cheque.currency_code != glob_rec_bank.currency_code 
						AND glob_rec_bank.currency_code = glob_rec_glparms.base_currency_code 
						LET l_rec_cheque.net_pay_amt = l_rec_cheque.net_pay_amt 
						/ l_rec_cheque.conv_qty 
						IF l_rec_bankstatement.tran_amt != l_rec_cheque.net_pay_amt THEN 
							LET l_err_message="Cheque Amount IS Invalid FOR this bank" 
							LET l_rec_bankstatement.doc_num = 0 
						ELSE 
							LET l_rec_bankstatement.doc_num = l_rec_cheque.doc_num 
						END IF 
					OTHERWISE 
						LET l_rec_bankstatement.doc_num = l_rec_cheque.doc_num 
				END CASE 
			END IF 
			IF l_rec_bankstatement.doc_num = 0 THEN 
				LET l_reconcile_flag = false 
			ELSE 
				LET l_reconcile_flag = true 
			END IF 
			##

		WHEN "PA" 
			##
			## Electronic Payments - Direct Debits
			##
			IF l_rec_bankstatement.doc_num > 0 THEN 
				## Possible serial number Xref TO "cheque" entry
				SELECT * INTO l_rec_voucher.* 
				FROM voucher 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND vouch_code = l_rec_bankstatement.doc_num 
				CASE 
					WHEN status = NOTFOUND 
						## Serial number Xref invalid
						LET l_rec_bankstatement.doc_num = 0 
					WHEN l_rec_voucher.vend_code != l_rec_bankstatement.ref_code 
						## Details do NOT match so break Xref
						LET l_rec_bankstatement.doc_num = 0 
				END CASE 
			END IF 
			SELECT vendor.* INTO l_rec_vendor.* 
			FROM vendor 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND vend_code = l_rec_bankstatement.ref_code 
			CASE 
				WHEN status = NOTFOUND 
					LET l_err_message = "Vendor does NOT exist" 
				WHEN glob_rec_bank.currency_code != glob_rec_glparms.base_currency_code 
					AND l_rec_vendor.currency_code != glob_rec_bank.currency_code 
					LET l_err_message = "Vendor Currency Code invalid" 
				OTHERWISE 
					LET l_reconcile_flag = 
					payment_entry(l_rec_bankstatement.*, p_seq_num) 
			END CASE 
			
		WHEN "RE" 
			##
			## Electronic Receipts - Direct Credit
			##
			IF l_rec_bankstatement.doc_num > 0 THEN 
				## Possible serial number Xref TO "invoicehead" entry
				SELECT * INTO l_rec_invoicehead.* 
				FROM invoicehead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND inv_num = l_rec_bankstatement.doc_num 
				CASE 
					WHEN status = NOTFOUND 
						## Serial number Xref invalid
						LET l_rec_bankstatement.doc_num = 0 
					WHEN l_rec_invoicehead.cust_code != l_rec_bankstatement.ref_code 
						## Details do NOT match so break Xref
						LET l_rec_bankstatement.doc_num = 0 
				END CASE 
			END IF 
			SELECT * INTO l_rec_customer.* 
			FROM customer 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cust_code = l_rec_bankstatement.ref_code 
			CASE 
				WHEN status = NOTFOUND 
					LET l_err_message = "Customer does NOT exist" 
				WHEN glob_rec_bank.currency_code != glob_rec_glparms.base_currency_code 
					AND l_rec_customer.currency_code != glob_rec_bank.currency_code 
					LET l_err_message = "Customer Currency Code invalid" 
				OTHERWISE 
					LET l_reconcile_flag = 
					receipt_entry(l_rec_bankstatement.*, p_seq_num) 
			END CASE 
			
		WHEN "SC" 
			##
			## Sundry Credits (interest/reversals etc)
			##
			IF l_rec_bankstatement.doc_num > 0 THEN 
				## Possible serial number Xref TO "banking" entry
				SELECT * INTO l_rec_banking.* 
				FROM banking 
				WHERE doc_num = l_rec_bankstatement.doc_num 
				IF status = NOTFOUND THEN 
					LET l_rec_bankstatement.doc_num = 0 
				END IF 
				IF l_rec_banking.bk_cmpy != glob_rec_kandoouser.cmpy_code 
				OR l_rec_banking.bk_acct != glob_rec_bank.acct_code 
				OR l_rec_banking.bk_cred != l_rec_bankstatement.tran_amt 
				OR l_rec_banking.bk_type != "SC" THEN 
					## Something has changed so break Xreference
					LET l_rec_bankstatement.doc_num = 0 
				END IF 
				IF (l_rec_banking.bk_sh_no IS NOT NULL 
				OR l_rec_banking.bk_seq_no IS NOT null) 
				AND (l_rec_banking.bk_sh_no != l_rec_bankstatement.sheet_num 
				OR l_rec_banking.bk_seq_no != l_rec_bankstatement.seq_num) THEN 
					## Entry has been reconciled on another sheet so break Xref
					LET l_rec_bankstatement.doc_num = 0 
				END IF 
			END IF 
			IF l_rec_bankstatement.doc_num = 0 THEN 
				DECLARE c3_banking CURSOR FOR 
				SELECT doc_num FROM banking 
				WHERE bk_cmpy = glob_rec_kandoouser.cmpy_code 
				AND bk_acct = glob_rec_bank.acct_code 
				AND bk_type in ("SC", "DP") 
				AND bk_cred = l_rec_bankstatement.tran_amt 
				AND bk_sh_no IS NULL 
				OPEN c3_banking 
				FETCH c3_banking INTO l_rec_bankstatement.doc_num 
				IF status = NOTFOUND THEN 
					LET l_rec_bankstatement.doc_num = 0 
				END IF 
			END IF 
			IF l_rec_bankstatement.doc_num = 0 THEN 
				LET l_reconcile_flag = direct_banking(l_rec_bankstatement.*, 
				p_seq_num) 
			ELSE 
				LET l_reconcile_flag = true 
			END IF 
			##

		WHEN "TI" 
			##
			## Bank Transfer IN - (These transactions must be selected FROM
			##                     a lookup window)
			IF l_rec_bankstatement.doc_num > 0 THEN 
				## Possible serial number Xref TO "banking" entry
				SELECT * INTO l_rec_banking.* 
				FROM banking 
				WHERE doc_num = l_rec_bankstatement.doc_num 
				IF status = NOTFOUND THEN 
					LET l_rec_bankstatement.doc_num = 0 
				END IF 
				IF l_rec_banking.bk_cmpy != glob_rec_kandoouser.cmpy_code 
				OR l_rec_banking.bk_acct != glob_rec_bank.acct_code 
				OR l_rec_banking.bk_cred != l_rec_bankstatement.tran_amt 
				OR l_rec_banking.bk_type != "TI" THEN 
					## Something has changed so break Xreference
					LET l_rec_bankstatement.doc_num = 0 
				END IF 
				IF (l_rec_banking.bk_sh_no IS NOT NULL 
				OR l_rec_banking.bk_seq_no IS NOT null) 
				AND (l_rec_banking.bk_sh_no != l_rec_bankstatement.sheet_num 
				OR l_rec_banking.bk_seq_no != l_rec_bankstatement.seq_num) THEN 
					## Entry has been reconciled on another sheet so break Xref
					LET l_rec_bankstatement.doc_num = 0 
				END IF 
			END IF 
			IF l_rec_bankstatement.doc_num = 0 THEN 
				DECLARE c4_banking CURSOR FOR 
				SELECT doc_num FROM banking 
				WHERE bk_cmpy = glob_rec_kandoouser.cmpy_code 
				AND bk_acct = glob_rec_bank.acct_code 
				AND bk_type = "TI" 
				AND bk_cred = l_rec_bankstatement.tran_amt 
				AND bk_sh_no IS NULL 
				OPEN c4_banking 
				FETCH c4_banking INTO l_rec_bankstatement.doc_num 
				IF status = NOTFOUND THEN 
					LET l_rec_bankstatement.doc_num = 0 
				END IF 
			END IF 
			IF l_rec_bankstatement.doc_num = 0 THEN 
				LET l_reconcile_flag = false 
			ELSE 
				LET l_reconcile_flag = true 
			END IF 
			##

		WHEN "TO" 
			##
			## Bank Transfer OUT -
			##
			IF l_rec_bankstatement.doc_num > 0 THEN 
				## Possible serial number Xref TO "banking" entry
				SELECT * INTO l_rec_banking.* 
				FROM banking 
				WHERE doc_num = l_rec_bankstatement.doc_num 
				IF status = NOTFOUND THEN 
					LET l_rec_bankstatement.doc_num = 0 
				END IF 
				IF l_rec_banking.bk_cmpy != glob_rec_kandoouser.cmpy_code 
				OR l_rec_banking.bk_acct != glob_rec_bank.acct_code 
				OR l_rec_banking.bk_debit != l_rec_bankstatement.tran_amt 
				OR l_rec_banking.bk_type != "TO" THEN 
					## Something has changed so break Xreference
					LET l_rec_bankstatement.doc_num = 0 
				END IF 
				IF l_rec_banking.bk_sh_no IS NOT NULL 
				OR l_rec_banking.bk_seq_no IS NOT NULL THEN 
					## Entry has been reconciled on another sheet so break Xref
					LET l_rec_bankstatement.doc_num = 0 
				END IF 
			END IF 
			IF l_rec_bankstatement.doc_num = 0 THEN 
				DECLARE c5_banking CURSOR FOR 
				SELECT doc_num FROM banking 
				WHERE bk_cmpy = glob_rec_kandoouser.cmpy_code 
				AND bk_acct = glob_rec_bank.acct_code 
				AND bk_type = "TO" 
				AND bk_debit = l_rec_bankstatement.tran_amt 
				AND bk_sh_no IS NULL 
				OPEN c5_banking 
				FETCH c5_banking INTO l_rec_bankstatement.doc_num 
				IF status = NOTFOUND THEN 
					LET l_rec_bankstatement.doc_num = 0 
				END IF 
			END IF 
			IF l_rec_bankstatement.doc_num = 0 THEN 
				LET l_reconcile_flag = false 
			ELSE 
				LET l_reconcile_flag = true 
			END IF 
			
		WHEN "DC" 
			##
			## Dishnoured Cheques
			##
			IF l_rec_bankstatement.doc_num > 0 THEN 
				## Possible serial number Xref TO "cashreceipt" entry
				SELECT * INTO l_rec_cashreceipt.* 
				FROM cashreceipt 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cash_num = l_rec_bankstatement.doc_num 
				CASE 
					WHEN status = NOTFOUND 
						## Serial number Xref invalid
						LET l_rec_bankstatement.doc_num = 0 
					WHEN l_rec_cashreceipt.cheque_text != l_rec_bankstatement.ref_code 
						## Details do NOT match so break Xref
						LET l_rec_bankstatement.doc_num = 0 
				END CASE 
			END IF 
			IF l_rec_bankstatement.doc_num = 0 THEN 
				DECLARE c_cashreceipt CURSOR FOR 
				SELECT * FROM cashreceipt 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cash_acct_code = glob_rec_bank.acct_code 
				AND cash_amt = l_rec_bankstatement.tran_amt 
				AND banked_flag = "Y" 
				AND banked_date IS NOT NULL 
				AND cheque_text = l_rec_bankstatement.ref_code 
				AND job_code IS NULL 
				OPEN c_cashreceipt 
				FETCH c_cashreceipt INTO l_rec_cashreceipt.* 
				IF status = NOTFOUND THEN 
					LET l_rec_bankstatement.doc_num = 0 
				ELSE 
					LET l_rec_bankstatement.doc_num = l_rec_cashreceipt.cash_num 
				END IF 
				CLOSE c_cashreceipt 
			END IF 
			
			IF l_rec_bankstatement.doc_num > 0 THEN 
				SELECT customer.* INTO l_rec_customer.* 
				FROM customer 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cust_code = l_rec_cashreceipt.cust_code 
				CASE 
					WHEN status = NOTFOUND 
						LET l_err_message = "Customer does NOT exist" 
						LET l_rec_bankstatement.doc_num = 0 
					WHEN glob_rec_bank.currency_code != glob_rec_glparms.base_currency_code 
						AND l_rec_customer.currency_code != glob_rec_bank.currency_code 
						LET l_rec_bankstatement.doc_num = 0 
						LET l_err_message = "Customer Currency Code invalid" 
					OTHERWISE 
						UPDATE t_bkstate 
						SET doc_num = l_rec_cashreceipt.cash_num, 
						ref_currency_code = l_rec_cashreceipt.currency_code, 
						conv_qty = l_rec_cashreceipt.conv_qty, 
						desc_text = l_desc_text 
						WHERE seq_num = p_seq_num 
				END CASE 
			END IF 
			IF l_rec_bankstatement.doc_num = 0 THEN 
				LET l_reconcile_flag = false 
			ELSE 
				LET l_reconcile_flag = true 
			END IF 
			
		WHEN "EF" 
			IF NOT numeric_value(l_rec_bankstatement.ref_code) THEN 
				LET l_err_message = "Cheque Code IS NOT numeric" 
				LET l_rec_bankstatement.doc_num = 0 
			ELSE 
				IF l_rec_bankstatement.ref_code IS NULL THEN 
					LET l_rec_bankstatement.ref_code = l_rec_bankstatement.doc_num 
				END IF 
				IF l_rec_bankstatement.doc_num = 0 THEN 
					WHENEVER ERROR CONTINUE 
					LET l_rec_bankstatement.doc_num = l_rec_bankstatement.ref_code 
					WHENEVER ERROR stop 
				END IF 
				## Possible serial number Xref TO "cheque" entry
				IF glob_rec_bank.currency_code = glob_rec_glparms.base_currency_code THEN 
					SELECT sum(net_pay_amt/conv_qty) INTO l_tot_net_pay_amt 
					FROM cheque 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND eft_run_num = l_rec_bankstatement.doc_num 
					AND bank_code = glob_rec_bank.bank_code 
					AND pay_meth_ind = "3" 
				ELSE 
					SELECT sum(net_pay_amt) INTO l_tot_net_pay_amt 
					FROM cheque 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND eft_run_num = l_rec_bankstatement.doc_num 
					AND bank_code = glob_rec_bank.bank_code 
					AND pay_meth_ind = "3" 
				END IF 
				
				IF l_tot_net_pay_amt IS NULL THEN 
					LET l_tot_net_pay_amt = 0 
				END IF 
				
				IF l_tot_net_pay_amt != l_rec_bankstatement.tran_amt THEN 
					## Serial number Xref invalid
					LET l_err_message = "EFT Amount different FROM Bank sheet" 
					LET l_rec_bankstatement.doc_num = 0 
				END IF 
				IF l_rec_bankstatement.doc_num > 0 THEN 
					LET l_rec_cheque.eft_run_num = l_rec_bankstatement.doc_num 
					DECLARE c3_cheque CURSOR FOR 
					SELECT * FROM cheque 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND eft_run_num = l_rec_cheque.eft_run_num 
					AND bank_code = glob_rec_bank.bank_code 
					AND pay_meth_ind = '3' 
					OPEN c3_cheque 
					FETCH c3_cheque INTO l_rec_cheque.* 
					CASE 
						WHEN l_rec_cheque.currency_code != glob_rec_bank.currency_code 
							AND glob_rec_bank.currency_code != glob_rec_glparms.base_currency_code 
							LET l_err_message = "Currency of EFT IS Invalid FOR this bank" 
							LET l_rec_bankstatement.doc_num = 0 
						WHEN l_rec_cheque.cheq_date > l_rec_bankstatement.tran_date 
							LET l_err_message = 
							" EFT No. ",l_rec_cheque.cheq_code USING "<<<<<<<<<", 
							" cannot be presented before ", 
							l_rec_cheque.cheq_date USING "dd mmm yy"," " 
							LET l_rec_bankstatement.doc_num = 0 
						WHEN l_rec_cheque.recon_flag = "Y" 
							LET l_err_message = "EFT IS already reconciled" 
							LET l_rec_bankstatement.doc_num = 0 
						WHEN l_rec_cheque.part_recon_flag = "Y" 
							AND l_rec_cheque.rec_state_num != glob_rec_bank.sheet_num 
							LET l_err_message = 
							"EFT has been reconciled on Another statement" 
							LET l_rec_bankstatement.doc_num = 0 
					END CASE 
				END IF 
			END IF 
			IF l_rec_bankstatement.doc_num = 0 THEN 
				LET l_reconcile_flag = false 
			ELSE 
				LET l_reconcile_flag = true 
			END IF 
			
		WHEN "ER" 
			##
			## AP Payments via EFT rejected by receiving bank
			##
			IF l_rec_bankstatement.doc_num > 0 THEN 
				## Possible serial number Xref TO "cheque" entry
				SELECT * INTO l_rec_cheque.* 
				FROM cheque 
				WHERE doc_num = l_rec_bankstatement.doc_num 
				CASE 
					WHEN status = NOTFOUND 
						## Serial number Xref invalid
						LET l_rec_bankstatement.doc_num = 0 
					WHEN l_rec_cheque.cheq_code != l_rec_bankstatement.ref_code 
						OR l_rec_cheque.bank_code != glob_rec_bank.bank_code 
						OR l_rec_cheque.pay_meth_ind != '3' 
						## Details do NOT match so break Xref
						LET l_rec_bankstatement.doc_num = 0 
				END CASE 
			END IF 
			IF NOT numeric_value(l_rec_bankstatement.ref_code) THEN 
				LET l_err_message = "Payment Number IS NOT numeric" 
				LET l_rec_bankstatement.doc_num = 0 
			ELSE 
				SELECT * INTO l_rec_cheque.* 
				FROM cheque 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cheq_code = l_rec_bankstatement.ref_code 
				AND bank_code = glob_rec_bank.bank_code 
				AND pay_meth_ind = '3' 
				CASE 
					WHEN status = NOTFOUND 
						LET l_err_message = "EFT payment does NOT exist" 
						LET l_rec_bankstatement.doc_num = 0 
					WHEN l_rec_cheque.currency_code != glob_rec_bank.currency_code 
						AND glob_rec_bank.currency_code != glob_rec_glparms.base_currency_code 
						LET l_err_message = 
						"Currency of Payment IS Invalid FOR this bank" 
						LET l_rec_bankstatement.doc_num = 0 
						
					WHEN l_rec_cheque.currency_code = glob_rec_bank.currency_code 
						AND l_rec_cheque.net_pay_amt != l_rec_bankstatement.tran_amt 
						LET l_err_message = "Payment Amount does NOT match entry" 
						LET l_rec_bankstatement.doc_num = 0 
					WHEN l_rec_cheque.cheq_date > l_rec_bankstatement.tran_date 
					
						LET l_err_message = 
						" Payment No. ",l_rec_cheque.cheq_code USING "<<<<<<<<<", 
						" cannot be cancelled before ", 
						l_rec_cheque.cheq_date USING "dd mmm yy"," " 
						LET l_rec_bankstatement.doc_num = 0 
						
					WHEN l_rec_cheque.currency_code != glob_rec_bank.currency_code 
						AND glob_rec_bank.currency_code = glob_rec_glparms.base_currency_code 
						LET l_rec_cheque.net_pay_amt = l_rec_cheque.net_pay_amt 
						/ l_rec_cheque.conv_qty 
						IF l_rec_bankstatement.tran_amt != l_rec_cheque.net_pay_amt THEN 
							LET l_err_message="Payment Amount IS Invalid FOR this bank" 
							LET l_rec_bankstatement.doc_num = 0 
						ELSE 
							LET l_rec_bankstatement.doc_num = l_rec_cheque.doc_num 
						END IF 
						
					OTHERWISE 
						LET l_rec_bankstatement.doc_num = l_rec_cheque.doc_num 
				END CASE 
				
			END IF 
			IF l_rec_bankstatement.doc_num = 0 THEN 
				LET l_reconcile_flag = false 
			ELSE 
				LET l_reconcile_flag = true 
			END IF 
			##
	END CASE 
	
	IF l_rec_bankstatement.doc_num > 0 THEN 
		## Final vaildation test TO see IF this transaction appears on
		## this statemnet more than once.
		SELECT unique 1 FROM t_bkstate 
		WHERE entry_type_code = l_rec_bankstatement.entry_type_code 
		AND doc_num = l_rec_bankstatement.doc_num 
		AND seq_num != p_seq_num 
		IF status = 0 THEN 
			LET l_err_message = "This Transaction has already been entered" 
			LET l_rec_bankstatement.doc_num = 0 
			LET l_reconcile_flag = false 
		END IF 
	END IF 
	IF length(l_err_message) > 0 THEN 
		ERROR l_err_message clipped 
	END IF 
	UPDATE t_bkstate SET doc_num = l_rec_bankstatement.doc_num 
	WHERE seq_num = p_seq_num 

	RETURN l_reconcile_flag 
END FUNCTION 
