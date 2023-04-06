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
GLOBALS "../gl/G_GL_GLOBALS.4gl" 
############################################################
# MODULE Scope Variables
############################################################
DEFINE modu_sel_text CHAR(500)
--DEFINE modu_max_year SMALLINT 
DEFINE modu_debit_amt DECIMAL(15,2) 
DEFINE modu_credit_amt DECIMAL(15,2) 
DEFINE modu_acct_bal_amt DECIMAL(15,2) 
DEFINE modu_tot_bal_amt DECIMAL(15,2) 
DEFINE modu_tot_n_debit DECIMAL(15,2) 
DEFINE modu_tot_n_credit DECIMAL(15,2) 
DEFINE modu_bat_debit DECIMAL(15,2) 
DEFINE modu_bat_credit DECIMAL(15,2) 
DEFINE modu_tot_debit DECIMAL(15,2) 
DEFINE modu_tot_credit DECIMAL(15,2) 
DEFINE modu_net_sub DECIMAL(15,2) 
DEFINE modu_net_bat DECIMAL(15,2) 
DEFINE modu_net_unp DECIMAL(15,2) 
DEFINE modu_ledg_var DECIMAL(15,2) 
DEFINE modu_tot_ledg_amt DECIMAL(15,2) 
DEFINE modu_sub_ledg_amt DECIMAL(15,2)
DEFINE modu_tax_debits DECIMAL(15,2)
DEFINE modu_unp_tax_debit DECIMAL(15,2)
DEFINE modu_tax_credits DECIMAL(15,2)
DEFINE modu_unp_tax_credit DECIMAL(15,2) 
DEFINE modu_net_tax DECIMAL(15,2) 
DEFINE modu_tax_vendor LIKE vendortype.tax_vend_code 


###############################################################
# FUNCTION GP6_main()
#
# GP6    (Menu path GP6)
# This program IS run TO take INTO account all
# exchange variances in outstanding creditors AND debtors
# AND produces a REPORT.
###############################################################
FUNCTION GP6_main() 

	DEFER quit 
	DEFER interrupt 
	
	CALL setModuleId("GP6") 

	LET modu_tot_n_debit = 0 
	LET modu_tot_n_credit = 0 
	LET modu_tot_debit = 0 
	LET modu_tot_credit = 0 
	LET modu_bat_debit = 0 
	LET modu_bat_credit = 0 
	LET modu_ledg_var = 0 
	LET modu_net_bat = 0 
	LET modu_net_sub = 0 
	LET modu_net_unp = 0 
	LET modu_tot_ledg_amt = 0 
	LET modu_sub_ledg_amt = 0 
	LET modu_unp_tax_debit = 0 
	LET modu_unp_tax_credit = 0 
	LET modu_net_tax = 0 

	SELECT * INTO glob_rec_company.* FROM company 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 		

			OPEN WINDOW w01 with FORM "U999" attributes(BORDER) 
			CALL windecoration_u("U999") 

			MENU " Period END Reconciliation" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","GP6","menu-period-end-reconciliation") 
					CALL GP6_rpt_process(GP6_rpt_query())
					
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				ON ACTION "Report" 		#COMMAND "Run Report" "Run AND PRINT REPORT x"
					CALL GP6_rpt_process(GP6_rpt_query()) 

				ON ACTION "Print Manager" 				#COMMAND KEY ("P",f11) "Print Report" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "Exit"					#COMMAND KEY (interrupt,"E")"Exit" " Exit TO menu"
					EXIT MENU 

			END MENU 
	 
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL GP6_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			#OPEN WINDOW A134 with FORM "A134" 
			#CALL windecoration_a("A134") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(GP6_rpt_query()) #save where clause in env 
			#CLOSE WINDOW A134 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL GP6_rpt_process(get_url_sel_text())
	END CASE 	

END FUNCTION 
###############################################################
# END FUNCTION GP6_main()
###############################################################


###############################################################
# FUNCTION GP6_rpt_query()
#
#
###############################################################
FUNCTION GP6_rpt_query()

	RETURN "N/A" 
--	IF report1(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,0) THEN 
--		RETURN true 
--	ELSE 
--		RETURN false 
--	END IF 
END FUNCTION 


###############################################################
# FUNCTION GP6_rpt_process(p_where_text) 
#
#
###############################################################
FUNCTION GP6_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING	
	DEFINE l_rpt_idx SMALLINT  #report array index 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"GP6_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	

	START REPORT GP6_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0
	#------------------------------------------------------------

	SELECT sum((voucher.total_amt-voucher.paid_amt) / voucher.conv_qty) 
	INTO modu_tot_credit 
	FROM voucher 
	WHERE voucher.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND voucher.total_amt != voucher.paid_amt 

	IF modu_tot_credit IS NULL THEN 
		LET modu_tot_credit = 0 
	END IF 

	SELECT sum((debithead.total_amt-debithead.apply_amt) /debithead.conv_qty) 
	INTO modu_debit_amt 
	FROM debithead 
	WHERE debithead.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND debithead.total_amt != debithead.apply_amt 

	IF modu_debit_amt IS NULL THEN 
		LET modu_debit_amt = 0 
	END IF 

	LET modu_tot_debit = modu_tot_debit + modu_debit_amt 

	SELECT sum((cheque.pay_amt-cheque.apply_amt) /cheque.conv_qty) 
	INTO modu_debit_amt 
	FROM cheque 
	WHERE cheque.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cheque.pay_amt != cheque.apply_amt 

	IF modu_debit_amt IS NULL THEN 
		LET modu_debit_amt = 0 
	END IF 

	LET modu_tot_debit = modu_tot_debit + modu_debit_amt 

	SELECT sum(voucher.total_amt / voucher.conv_qty) 
	INTO modu_tot_n_credit 
	FROM voucher 
	WHERE voucher.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND voucher.post_flag = "N" 

	IF modu_tot_n_credit IS NULL THEN 
		LET modu_tot_n_credit = 0 
	END IF 

	SELECT sum(debithead.total_amt / debithead.conv_qty) 
	INTO modu_debit_amt 
	FROM debithead 
	WHERE debithead.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND debithead.post_flag = "N" 

	IF modu_debit_amt IS NULL THEN 
		LET modu_debit_amt = 0 
	END IF 

	LET modu_tot_n_debit = modu_tot_n_debit + modu_debit_amt 

	SELECT sum(cheque.pay_amt / cheque.conv_qty) 
	INTO modu_debit_amt 
	FROM cheque 
	WHERE cheque.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cheque.post_flag = "N" 

	IF modu_debit_amt IS NULL THEN 
		LET modu_debit_amt = 0 
	END IF 

	LET modu_tot_n_debit = modu_tot_n_debit + modu_debit_amt 
	# determine the total value of control account postings in unposted
	# tax vouchers AND debits

	DECLARE c_taxvendor CURSOR FOR 

	SELECT unique tax_vend_code 
	FROM vendortype 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 


	FOREACH c_taxvendor INTO modu_tax_vendor 
		SELECT sum(total_amt / conv_qty) INTO modu_tax_debits FROM voucher 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND vend_code = modu_tax_vendor 
		AND post_flag = "N" 

		IF modu_tax_debits IS NULL THEN 
			LET modu_tax_debits = 0 
		END IF 

		SELECT sum(total_amt / conv_qty) INTO modu_tax_credits FROM debithead 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND vend_code = modu_tax_vendor 
		AND post_flag = "N" 

		IF modu_tax_credits IS NULL THEN 
			LET modu_tax_credits = 0 
		END IF 

		LET modu_unp_tax_debit = modu_unp_tax_debit + modu_tax_debits 
		LET modu_unp_tax_credit = modu_unp_tax_credit + modu_tax_credits 

	END FOREACH 

	LET modu_net_sub = modu_tot_debit - modu_tot_credit 
	LET modu_net_unp = modu_tot_n_debit - modu_tot_n_credit 

		#---------------------------------------------------------
		OUTPUT TO REPORT GP6_rpt_list(l_rpt_idx,"Creditors")
		#---------------------------------------------------------

	LET modu_tot_n_debit = 0 
	LET modu_tot_n_credit = 0 
	LET modu_tot_debit = 0 
	LET modu_tot_credit = 0 
	LET modu_bat_debit = 0 
	LET modu_bat_credit = 0 
	LET modu_ledg_var = 0 
	LET modu_net_bat = 0 
	LET modu_net_unp = 0 
	LET modu_net_sub = 0 

	SELECT sum((invoicehead.total_amt-invoicehead.paid_amt)	/invoicehead.conv_qty) 
	INTO modu_tot_debit 
	FROM invoicehead 
	WHERE invoicehead.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND invoicehead.total_amt != invoicehead.paid_amt 

	IF modu_tot_debit IS NULL THEN 
		LET modu_tot_debit = 0 
	END IF 

	SELECT sum((credithead.total_amt-credithead.appl_amt)	/credithead.conv_qty) 
	INTO modu_credit_amt 
	FROM credithead 
	WHERE credithead.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND credithead.total_amt != credithead.appl_amt 

	IF modu_credit_amt IS NULL THEN 
		LET modu_credit_amt = 0 
	END IF 

	LET modu_tot_credit = modu_tot_credit + modu_credit_amt 

	SELECT sum((cashreceipt.cash_amt-cashreceipt.applied_amt)	/cashreceipt.conv_qty) 
	INTO modu_credit_amt 
	FROM cashreceipt 
	WHERE cashreceipt.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cashreceipt.cash_amt != cashreceipt.applied_amt 

	IF modu_credit_amt IS NULL THEN 
		LET modu_credit_amt = 0 
	END IF 

	LET modu_tot_credit = modu_tot_credit + modu_credit_amt 

	SELECT sum(invoicehead.total_amt /invoicehead.conv_qty) 
	INTO modu_tot_n_debit 
	FROM invoicehead 
	WHERE invoicehead.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND invoicehead.posted_flag = "N" 

	IF modu_tot_n_debit IS NULL THEN 
		LET modu_tot_n_debit = 0 
	END IF 

	SELECT sum(credithead.total_amt /credithead.conv_qty) 
	INTO modu_credit_amt 
	FROM credithead 
	WHERE credithead.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND credithead.posted_flag = "N" 

	IF modu_credit_amt IS NULL THEN 
		LET modu_credit_amt = 0 
	END IF 

	LET modu_tot_n_credit = modu_tot_n_credit + modu_credit_amt 

	SELECT sum(cashreceipt.cash_amt /cashreceipt.conv_qty) 
	INTO modu_credit_amt 
	FROM cashreceipt 
	WHERE cashreceipt.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cashreceipt.posted_flag = CASHRECEIPT_POST_FLAG_STATUS_NOT_POSTED_N 

	IF modu_credit_amt IS NULL THEN 
		LET modu_credit_amt = 0 
	END IF 

	LET modu_tot_n_credit = modu_tot_n_credit + modu_credit_amt 
	LET modu_net_sub = modu_tot_debit - modu_tot_credit 
	LET modu_net_unp = modu_tot_n_debit - modu_tot_n_credit 

	#---------------------------------------------------------
	OUTPUT TO REPORT GP6_rpt_list(l_rpt_idx,"Debtors")
	#---------------------------------------------------------

	#------------------------------------------------------------
	FINISH REPORT GP6_rpt_list
	CALL rpt_finish("GP6_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 
###############################################################
# END FUNCTION GP6_rpt_query()
###############################################################


###############################################################
# REPORT GP6_rpt_list(p_ledg_type)
#
#
###############################################################
REPORT GP6_rpt_list(p_rpt_idx,p_ledg_type) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE p_ledg_type CHAR(18)
	DEFINE l_ledg_acct LIKE account.acct_code 
	DEFINE l_arr_line array[4] OF CHAR(132) 

	OUTPUT	left margin 0 

	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		ON EVERY ROW 
			SKIP 1 line 
			PRINT COLUMN 1, "Subsidiary ", p_ledg_type 
			PRINT COLUMN 5, "Balance ", 
			COLUMN 80, modu_net_sub USING "-,---,---,---,---.&&" 

			PRINT COLUMN 5, "Credits", 
			COLUMN 40, modu_tot_credit USING "-,---,---,---.&&" 

			PRINT COLUMN 5, "Debits ", 
			COLUMN 40, modu_tot_debit USING "-,---,---,---.&&" 
			SKIP 1 line 

			PRINT COLUMN 3, "General Ledger" 
			LET modu_tot_bal_amt = 0 

			IF p_ledg_type = "Creditors" THEN 
				LET modu_sel_text = 
					"SELECT unique pay_acct_code ", 
					" FROM vendortype ", 
					" WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code, "\" " 
			ELSE 
				LET modu_sel_text = 
					"SELECT unique ar_acct_code ", 
					" FROM customertype ", 
					" WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code, "\" " 
			END IF 

			PREPARE sel_curs FROM modu_sel_text 
			DECLARE c_account CURSOR FOR sel_curs 

			FOREACH c_account INTO l_ledg_acct 
				SELECT sum(bal_amt - open_amt) INTO modu_acct_bal_amt FROM account 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND acct_code = l_ledg_acct 

				IF modu_acct_bal_amt IS NULL THEN 
					LET modu_acct_bal_amt = 0 
				END IF 

				PRINT COLUMN 5, l_ledg_acct clipped, 
				COLUMN 20, " Closing Balance ", 
				COLUMN 60, modu_acct_bal_amt USING "-,---,---,---,---.&&" 

				LET modu_tot_bal_amt = modu_tot_bal_amt + modu_acct_bal_amt 

				SELECT sum(batchdetl.debit_amt), sum(batchdetl.credit_amt) 
				INTO modu_bat_debit, modu_bat_credit 
				FROM batchdetl, batchhead 
				WHERE batchhead.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND batchdetl.cmpy_code = batchhead.cmpy_code 
				AND batchdetl.jour_code = batchhead.jour_code 
				AND batchdetl.jour_num = batchhead.jour_num 
				AND batchhead.post_flag = "N" 
				AND batchdetl.acct_code = l_ledg_acct 

				IF modu_bat_debit IS NULL THEN 
					LET modu_bat_debit = 0 
				END IF 

				IF modu_bat_credit IS NULL THEN 
					LET modu_bat_credit = 0 
				END IF 

				LET modu_net_bat = modu_net_bat + (modu_bat_debit - modu_bat_credit) 

				PRINT COLUMN 21, "Batch Credits ", 
				COLUMN 40, modu_bat_credit USING "-,---,---,---,---.&&" 

				PRINT COLUMN 21, "Batch Debits ", 
				COLUMN 40, modu_bat_debit USING "-,---,---,---,---.&&" 
				SKIP 1 line 

			END FOREACH 

			LET modu_sub_ledg_amt = modu_net_bat + modu_tot_bal_amt 

			PRINT COLUMN 60, "================" 
			PRINT COLUMN 60, modu_sub_ledg_amt USING "-,---,---,---,---.&&" 
			PRINT COLUMN 5, "Subsidiary " 
			PRINT COLUMN 5, "Unposted Credits ", 
				COLUMN 40, modu_tot_n_credit USING "-,---,---,---,---.&&" 

			PRINT COLUMN 5, "Unposted Debits ", 
				COLUMN 40, modu_tot_n_debit USING "-,---,---,---,---.&&" 

			IF p_ledg_type = "Creditors" THEN 
				LET modu_net_tax = modu_unp_tax_debit - modu_unp_tax_credit 
				PRINT COLUMN 5, "Unposted Tax Credits ", 
					COLUMN 40, modu_unp_tax_credit USING "-,---,---,---,---.&&" 
	
				PRINT COLUMN 5, "Unposted Tax Debits ", 
					COLUMN 40, modu_unp_tax_debit USING "-,---,---,---,---.&&" 
			ELSE 
				LET modu_net_tax = 0 
			END IF 

			LET modu_tot_ledg_amt = modu_net_unp + modu_net_tax + modu_sub_ledg_amt 
			LET modu_ledg_var = modu_net_sub - (modu_net_unp + modu_net_tax + modu_net_bat + modu_tot_bal_amt) 

			PRINT COLUMN 60, "================" 
			PRINT COLUMN 60, modu_tot_ledg_amt USING "-,---,---,---,---.&&" 
			PRINT COLUMN 21, "Variance ", 
				COLUMN 60, modu_ledg_var USING "-,---,---,---,---.&&" 

			SKIP 1 line 
			PRINT COLUMN 10, "Total ", p_ledg_type clipped,		" Control accounts should equal ", 
				COLUMN 80, (modu_ledg_var + modu_net_unp + modu_net_tax + modu_net_bat + modu_tot_bal_amt)	USING "-,---,---,---,---.&&" 

			SKIP TO top OF PAGE 

		ON LAST ROW 
			SKIP 1 line 

			LET modu_tot_n_debit = 0 
			LET modu_tot_debit = 0 
			LET modu_tot_credit = 0 
			LET modu_bat_debit = 0 
			LET modu_bat_credit = 0 
			LET modu_ledg_var = 0 
			LET modu_net_bat = 0 
		#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			

			LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = pageno

END REPORT
###############################################################
# END REPORT GP6_rpt_list(p_ledg_type)
###############################################################