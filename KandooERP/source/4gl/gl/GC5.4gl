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
GLOBALS "../gl/GC5_GLOBALS.4gl"
GLOBALS 
	DEFINE glob_rec_rpt_data_select RECORD 
		bank_code LIKE bank.bank_code, 
		name_acct_text LIKE bank.name_acct_text, 
		iban LIKE bank.iban, 
		acct_code LIKE bank.acct_code, 
		bank_currency_code LIKE bank.currency_code, 
		sheet_num LIKE bank.sheet_num, 
		sheet_date LIKE banking.bk_bankdt, 
		cb_bal_amt LIKE bank.state_base_bal_amt, 
		cb_close_amt LIKE bank.state_base_bal_amt, 
		year_num LIKE period.year_num, 
		period_num LIKE period.period_num, 
		end_date LIKE period.end_date, 
		gl_bal_amt LIKE bank.state_base_bal_amt, 
		gl_close_amt LIKE bank.state_base_bal_amt, 
		coa_text LIKE coa.desc_text, 
		detail_flag char(1) 
	END RECORD 
END GLOBALS 
###########################################################################
# MODULE Scope Variables
###########################################################################

###########################################################################
# FUNCTION GC5_main()
#
# GC5 Reconciliation Report
###########################################################################
FUNCTION GC5_main() 
	DEFINE l_msgresp LIKE language.yes_flag 

	DEFER quit 
	DEFER interrupt 
	
	CALL setModuleId("GC5") 

	IF NOT get_gl_setup_state() THEN 
		ERROR kandoomsg2("G",5007,"")	#5008 " General Ledger Parameters Not Set Up - Refer Menu GZP"
		EXIT PROGRAM 
	END IF 

	IF glob_rec_glparms.cash_book_flag != "Y" THEN 
		ERROR kandoomsg2("G",9502,"") 
		#G9502" Cash Book Facility IS NOT Available "
		EXIT PROGRAM 
	END IF 

	OPEN WINDOW G111 with FORM "G111" 
	CALL windecoration_g("G111") 

	MENU " Bank Reconciliation " 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","GC5","menu-bank-reconciliation") 
			CALL GC5_rpt_process(GC5_rpt_query()) 
			IF glob_rec_rpt_data_select.gl_close_amt != glob_rec_rpt_data_select.cb_close_amt THEN 
				CALL fgl_winmessage("Discrepancy Exists",kandoomsg2("G",7025,""),"ERROR") #G7025" Discrepancy Exists Between Cash Book & General Ledger"
			END IF 
			
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "Report"	#COMMAND "Report" " SELECT Criteria AND PRINT REPORT"
			CALL GC5_rpt_process(GC5_rpt_query()) 
			IF glob_rec_rpt_data_select.gl_close_amt != glob_rec_rpt_data_select.cb_close_amt THEN 
				CALL fgl_winmessage("Discrepancy Exists",kandoomsg2("G",7025,""),"ERROR") #G7025" Discrepancy Exists Between Cash Book & General Ledger"
			END IF 


		ON ACTION "PRINT MANAGER"		#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"  --Report File Management
			CALL run_prog("URS","","","","") 

		ON ACTION "Exit"	#COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus"
			EXIT MENU 

	END MENU 

	CLOSE WINDOW G111 
END FUNCTION 


############################################################
# FUNCTION GC5_rpt_query()
#
#
############################################################
FUNCTION GC5_rpt_query() 
	DEFINE l_rec_bank RECORD LIKE bank.* 
	#DEFINE l_rec_banking RECORD LIKE banking.* #not used
	DEFINE l_rec_bankstatement RECORD LIKE bankstatement.* 

	INITIALIZE glob_rec_rpt_data_select.* TO NULL 
	LET glob_rec_rpt_data_select.cb_bal_amt = 0 
	LET glob_rec_rpt_data_select.cb_close_amt = 0 
	LET glob_rec_rpt_data_select.gl_bal_amt = 0 
	LET glob_rec_rpt_data_select.gl_close_amt = 0 

	MESSAGE kandoomsg2("U",1020,"Bank & fiscal Period")	#U1020 Enter Bank & Fiscal Period Detail - ESC TO Continue
	INPUT BY NAME glob_rec_rpt_data_select.bank_code, 
	glob_rec_rpt_data_select.year_num, 
	glob_rec_rpt_data_select.period_num 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GC5","inp-globalrec") 
			CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,today) 
			RETURNING glob_rec_rpt_data_select.year_num, 
			glob_rec_rpt_data_select.period_num 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP"
			CALL show_bank(glob_rec_kandoouser.cmpy_code) RETURNING glob_rec_rpt_data_select.bank_code, 
			l_rec_bank.acct_code 
			NEXT FIELD bank_code 

		BEFORE FIELD bank_code 
			CLEAR name_acct_text, 
			iban 

		AFTER FIELD bank_code 
			IF glob_rec_rpt_data_select.bank_code IS NULL THEN 
				ERROR kandoomsg2("U",9102,"") 
				#9102 Value must be entered.
				NEXT FIELD bank_code 
			END IF 
			SELECT * INTO l_rec_bank.* FROM bank 
			WHERE bank_code = glob_rec_rpt_data_select.bank_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF status = NOTFOUND THEN 
				ERROR kandoomsg2("U",9105,"") 
				#U9105 Bank Code does NOT Exist - Try Window "
				NEXT FIELD bank_code 
			END IF 
			LET glob_rec_rpt_data_select.name_acct_text = l_rec_bank.name_acct_text 
			LET glob_rec_rpt_data_select.iban = l_rec_bank.iban 
			LET glob_rec_rpt_data_select.acct_code = l_rec_bank.acct_code 
			LET glob_rec_rpt_data_select.bank_currency_code = l_rec_bank.currency_code 
			DISPLAY BY NAME glob_rec_rpt_data_select.name_acct_text, 
			glob_rec_rpt_data_select.iban 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				IF glob_rec_rpt_data_select.bank_code IS NULL THEN 
					ERROR kandoomsg2("U",9102,"") 
					#U9102 Value must be entered
					NEXT FIELD bank_code 
				END IF 
				SELECT end_date INTO glob_rec_rpt_data_select.end_date FROM period 
				WHERE year_num = glob_rec_rpt_data_select.year_num 
				AND period_num = glob_rec_rpt_data_select.period_num 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("U",3512,"") 
					#3512 You must SELECT a VALID year AND period
					NEXT FIELD year_num 
				END IF 
			END IF 
	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL 
	ELSE 

	LET glob_rec_rpt_selector.ref1_code = glob_rec_rpt_data_select.bank_code 
	LET glob_rec_rpt_selector.ref1_num = glob_rec_rpt_data_select.year_num 
	LET glob_rec_rpt_selector.ref2_num = glob_rec_rpt_data_select.period_num 
	
		##
		## Need TO setup rest of global record
		##
		## The only place in which the actual statement date IS recorded IS the
		## Statement header entry in the bankstatement table - the closing AND
		## opening entries in the banking table have a NULL bank date (refer GC3).
		## This program will require a modification in future TO allow entry of a
		## sheet number FOR those sites NOT using GCE OR an amendment TO GC3 TO
		## utilise the bank statement tables.
		##
		## Obtain sheet number AND closing balance FROM last closed sheet
		## prior TO period END date
		##
		DECLARE c_bankstatement CURSOR FOR 
		SELECT * FROM bankstatement 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND bank_code = glob_rec_rpt_data_select.bank_code 
		AND entry_type_code = "SH" 
		AND recon_ind = "2" 
		AND tran_date <= glob_rec_rpt_data_select.end_date 
		ORDER BY sheet_num desc 
		OPEN c_bankstatement 
		FETCH c_bankstatement INTO l_rec_bankstatement.* 
		IF status = NOTFOUND THEN 
			LET glob_rec_rpt_data_select.cb_bal_amt = 0 
			LET glob_rec_rpt_data_select.sheet_num = 0 
			LET glob_rec_rpt_data_select.sheet_date = NULL 
		ELSE 
			LET glob_rec_rpt_data_select.sheet_date = l_rec_bankstatement.tran_date 
			LET glob_rec_rpt_data_select.sheet_num = l_rec_bankstatement.sheet_num 
			LET glob_rec_rpt_data_select.sheet_date = l_rec_bankstatement.tran_date 
			LET glob_rec_rpt_data_select.cb_bal_amt = l_rec_bankstatement.tran_amt 
		END IF 
		IF glob_rec_glparms.use_currency_flag = "Y" AND 
		glob_rec_rpt_data_select.bank_currency_code <> glob_rec_glparms.base_currency_code THEN 
			SELECT close_amt INTO glob_rec_rpt_data_select.gl_bal_amt FROM accounthistcur 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND acct_code = glob_rec_rpt_data_select.acct_code 
			AND year_num = glob_rec_rpt_data_select.year_num 
			AND period_num = glob_rec_rpt_data_select.period_num 
			AND currency_code = glob_rec_rpt_data_select.bank_currency_code 
			IF status = NOTFOUND THEN 
				LET glob_rec_rpt_data_select.gl_bal_amt = 0 
			END IF 
		ELSE 
			SELECT close_amt INTO glob_rec_rpt_data_select.gl_bal_amt FROM accounthist 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND acct_code = glob_rec_rpt_data_select.acct_code 
			AND year_num = glob_rec_rpt_data_select.year_num 
			AND period_num = glob_rec_rpt_data_select.period_num 
			IF status = NOTFOUND THEN 
				LET glob_rec_rpt_data_select.gl_bal_amt = 0 
			END IF 
		END IF 
		
		SELECT desc_text INTO glob_rec_rpt_data_select.coa_text FROM coa 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND acct_code = glob_rec_rpt_data_select.acct_code 

		DISPLAY BY NAME glob_rec_rpt_data_select.name_acct_text, 
		glob_rec_rpt_data_select.iban, 
		glob_rec_rpt_data_select.sheet_num, 
		glob_rec_rpt_data_select.sheet_date, 
		glob_rec_rpt_data_select.cb_bal_amt, 
		glob_rec_rpt_data_select.acct_code, 
		glob_rec_rpt_data_select.end_date, 
		glob_rec_rpt_data_select.gl_bal_amt 

		LET glob_rec_rpt_data_select.detail_flag = kandoomsg("G",8023,"")

		#----------------------------
		#prepare data for rmsreps
		LET glob_rec_rpt_selector.ref1_code = glob_rec_rpt_data_select.bank_code #LIKE bank.bank_code,
		LET glob_rec_rpt_selector.ref2_code = glob_rec_rpt_data_select.bank_currency_code #LIKE bank.currency_code, 

		LET glob_rec_rpt_selector.ref1_text = glob_rec_rpt_data_select.name_acct_text #LIKE bank.name_acct_text, 
		LET glob_rec_rpt_selector.ref2_text = glob_rec_rpt_data_select.iban #LIKE bank.iban, 
		LET glob_rec_rpt_selector.ref3_text = glob_rec_rpt_data_select.acct_code #LIKE bank.acct_code, 

		LET glob_rec_rpt_selector.ref1_num = glob_rec_rpt_data_select.year_num 
		LET glob_rec_rpt_selector.ref2_num = glob_rec_rpt_data_select.period_num 
		LET glob_rec_rpt_selector.ref3_num = glob_rec_rpt_data_select.sheet_num #LIKE bank.sheet_num, 
		LET glob_rec_rpt_selector.ref4_num = glob_rec_rpt_data_select.year_num #LIKE period.year_num, 
		LET glob_rec_rpt_selector.ref5_num = glob_rec_rpt_data_select.period_num #LIKE period.period_num, 

		LET glob_rec_rpt_selector.ref1_date = glob_rec_rpt_data_select.sheet_date #LIKE banking.bk_bankdt, 
		LET glob_rec_rpt_selector.ref2_date = glob_rec_rpt_data_select.end_date #LIKE period.end_date, 

		LET glob_rec_rpt_selector.ref1_amt = glob_rec_rpt_data_select.cb_bal_amt #LIKE bank.state_base_bal_amt, 
		LET glob_rec_rpt_selector.ref2_amt = glob_rec_rpt_data_select.cb_close_amt #LIKE bank.state_base_bal_amt, 
		LET glob_rec_rpt_selector.ref3_amt = glob_rec_rpt_data_select.gl_bal_amt #LIKE bank.state_base_bal_amt, 
		LET glob_rec_rpt_selector.ref4_amt = glob_rec_rpt_data_select.gl_close_amt #LIKE bank.state_base_bal_amt, 

		LET glob_rec_rpt_selector.ref1_ind = glob_rec_rpt_data_select.detail_flag #char(1) 		

		LET glob_rec_rpt_selector.sel_option1 = glob_rec_rpt_data_select.coa_text #LIKE coa.desc_text, 

		 
		RETURN "N/A" #we have no construct where clause but NULL would abbort 
	END IF 
END FUNCTION 



############################################################
# FUNCTION GC5_rpt_process()
#
#
############################################################
FUNCTION GC5_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT  
	DEFINE l_rec_report 
	RECORD 
		type_ind char(1), 
		seq_ind SMALLINT, 
		tran_date DATE, 
		tran_num INTEGER, 
		tran_code char(8), 
		tran_text char(30), 
		dr_tran_amt decimal(16,2), 
		cr_tran_amt decimal(16,2), 
		prompt_text char(40), 
		recon_ind char(1) 
	END RECORD 
	DEFINE l_rec_cheque RECORD LIKE cheque.* 
	DEFINE l_rec_cancelcheq RECORD LIKE cancelcheq.* 
	DEFINE l_rec_cashreceipt RECORD LIKE cashreceipt.* 
	DEFINE l_rec_batchdetl RECORD LIKE batchdetl.* 
	DEFINE l_rec_banking RECORD LIKE banking.* 
	DEFINE l_rec_tentbankhead RECORD LIKE tentbankhead.* 
	DEFINE l_pay_amt LIKE tentbankdetl.tran_amt 
	DEFINE l_tran_date DATE 
	DEFINE l_year_num SMALLINT 
	DEFINE l_period_num SMALLINT 
	DEFINE l_rpt_output char(25) 
	DEFINE l_msgresp LIKE language.yes_flag 


	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"GC5_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT GC5_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0
	LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GC5_rpt_list")].sel_text
	#------------------------------------------------------------

		#----------------------------
		#prepare data for rmsreps
		LET glob_rec_rpt_data_select.bank_code  = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GC5_rpt_list")].ref1_code #LIKE bank.bank_code,
		LET glob_rec_rpt_data_select.bank_currency_code = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GC5_rpt_list")].ref2_code  #LIKE bank.currency_code, 

		LET glob_rec_rpt_data_select.name_acct_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GC5_rpt_list")].ref1_text  #LIKE bank.name_acct_text, 
		LET glob_rec_rpt_data_select.iban = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GC5_rpt_list")].ref2_text  #LIKE bank.iban, 
		LET glob_rec_rpt_data_select.acct_code = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GC5_rpt_list")].ref3_text  #LIKE bank.acct_code, 

		LET glob_rec_rpt_data_select.year_num = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GC5_rpt_list")].ref1_num   
		LET glob_rec_rpt_data_select.period_num  = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GC5_rpt_list")].ref2_num 
		LET glob_rec_rpt_data_select.sheet_num = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GC5_rpt_list")].ref3_num   #LIKE bank.sheet_num, 
		LET glob_rec_rpt_data_select.year_num = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GC5_rpt_list")].ref4_num  #LIKE period.year_num, 
		LET glob_rec_rpt_data_select.period_num = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GC5_rpt_list")].ref5_num  #LIKE period.period_num, 

		LET glob_rec_rpt_data_select.sheet_date = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GC5_rpt_list")].ref1_date  #LIKE banking.bk_bankdt, 
		LET glob_rec_rpt_data_select.end_date = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GC5_rpt_list")].ref2_date  #LIKE period.end_date, 

		LET glob_rec_rpt_data_select.cb_bal_amt = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GC5_rpt_list")].ref1_amt  #LIKE bank.state_base_bal_amt, 
		LET glob_rec_rpt_data_select.cb_close_amt = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GC5_rpt_list")].ref2_amt  #LIKE bank.state_base_bal_amt, 
		LET glob_rec_rpt_data_select.gl_bal_amt = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GC5_rpt_list")].ref3_amt  #LIKE bank.state_base_bal_amt, 
		LET glob_rec_rpt_data_select.gl_close_amt = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GC5_rpt_list")].ref4_amt  #LIKE bank.state_base_bal_amt, 

		LET glob_rec_rpt_data_select.detail_flag = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GC5_rpt_list")].ref1_ind  #char(1) 		

		LET glob_rec_rpt_data_select.coa_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GC5_rpt_list")].sel_option1 #LIKE coa.desc_text, 

	

	##
	## General Ledger Transactions
	## ---------------------------
	##
	##
	## OUTPUT an empty transaction FOR each type indicator, TO SET up headings
	## AND balances - OTHERWISE IF no unreconciled items are present no REPORT
	## IS produced.
	##
	INITIALIZE l_rec_report.* TO NULL 
	LET l_rec_report.type_ind = "G" 
	LET l_rec_report.seq_ind = 0 
	LET l_rec_report.dr_tran_amt = 0 
	LET l_rec_report.cr_tran_amt = 0 

	#---------------------------------------------------------
	OUTPUT TO REPORT GC5_rpt_list(l_rpt_idx,l_rec_report.*)  
	#---------------------------------------------------------	
	##
	## GL - Retrieve unposted cashreceipts
	##
	DECLARE c_cashreceipt CURSOR FOR 
	SELECT * FROM cashreceipt 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cash_acct_code = glob_rec_rpt_data_select.acct_code 
	AND (posted_flag = "N" OR posted_flag IS null) 
	AND (year_num < glob_rec_rpt_data_select.year_num 
	or(year_num = glob_rec_rpt_data_select.year_num 
	AND cashreceipt.period_num <= glob_rec_rpt_data_select.period_num)) 

	FOREACH c_cashreceipt INTO l_rec_cashreceipt.* 
		INITIALIZE l_rec_report.* TO NULL 
		LET l_rec_report.type_ind = "G" 
		LET l_rec_report.seq_ind = 1 
		LET l_rec_report.prompt_text = "Unposted receipt(s)" 
		LET l_rec_report.tran_date = l_rec_cashreceipt.cash_date 
		LET l_rec_report.tran_num = l_rec_cashreceipt.cash_num 
		LET l_rec_report.tran_code = l_rec_cashreceipt.cust_code 
		SELECT name_text INTO l_rec_report.tran_text FROM customer 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = l_rec_cashreceipt.cust_code 
		IF l_rec_cashreceipt.cash_amt >= 0 THEN 

			IF l_rec_cashreceipt.currency_code != glob_rec_rpt_data_select.bank_currency_code THEN 
				LET l_rec_report.dr_tran_amt = l_rec_cashreceipt.cash_amt/ 
				l_rec_cashreceipt.conv_qty 
			ELSE 
				LET l_rec_report.dr_tran_amt = l_rec_cashreceipt.cash_amt 
			END IF 
			LET l_rec_report.cr_tran_amt = 0 
		ELSE 
			LET l_rec_report.dr_tran_amt = 0 
			IF l_rec_cashreceipt.currency_code != glob_rec_rpt_data_select.bank_currency_code THEN 
				LET l_rec_report.cr_tran_amt = (0 - l_rec_cashreceipt.cash_amt)/ 
				l_rec_cashreceipt.conv_qty 
			ELSE 
				LET l_rec_report.cr_tran_amt = 0 - l_rec_cashreceipt.cash_amt 
			END IF 
		END IF 

		#---------------------------------------------------------
		OUTPUT TO REPORT GC5_rpt_list(l_rpt_idx,l_rec_report.*) 
		#---------------------------------------------------------		
 
	END FOREACH 
	##
	## GL - Retrieve unposted cheques
	##
	DECLARE c_cheque CURSOR FOR 
	SELECT * FROM cheque 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND bank_acct_code = glob_rec_rpt_data_select.acct_code 
	AND bank_code = glob_rec_rpt_data_select.bank_code 
	AND cheq_code != 0 
	AND cheq_code IS NOT NULL 
	AND post_flag = "N" 
	AND (year_num < glob_rec_rpt_data_select.year_num 
	or(year_num = glob_rec_rpt_data_select.year_num 
	AND period_num <= glob_rec_rpt_data_select.period_num)) 

	FOREACH c_cheque INTO l_rec_cheque.* 
		INITIALIZE l_rec_report.* TO NULL 
		LET l_rec_report.type_ind = "G" 
		LET l_rec_report.seq_ind = 2 
		LET l_rec_report.tran_date = l_rec_cheque.cheq_date 
		LET l_rec_report.prompt_text = "Unposted cheque(s)" 
		LET l_rec_report.tran_num = l_rec_cheque.cheq_code 
		LET l_rec_report.tran_code = l_rec_cheque.vend_code 
		SELECT name_text INTO l_rec_report.tran_text FROM vendor 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND vend_code = l_rec_cheque.vend_code 
		IF l_rec_cheque.net_pay_amt >= 0 THEN 
			LET l_rec_report.dr_tran_amt = 0 
			IF l_rec_cheque.currency_code != glob_rec_rpt_data_select.bank_currency_code THEN 
				LET l_rec_report.cr_tran_amt = l_rec_cheque.net_pay_amt / 
				l_rec_cheque.conv_qty 
			ELSE 
				LET l_rec_report.cr_tran_amt = l_rec_cheque.net_pay_amt 
			END IF 
		ELSE 
			LET l_rec_report.dr_tran_amt = 0 - l_rec_cheque.net_pay_amt 
			IF l_rec_cheque.currency_code != glob_rec_rpt_data_select.bank_currency_code THEN 
				LET l_rec_report.dr_tran_amt = l_rec_report.dr_tran_amt / 
				l_rec_cheque.conv_qty 
			END IF 
			LET l_rec_report.cr_tran_amt = 0 
		END IF 


		#---------------------------------------------------------
		OUTPUT TO REPORT GC5_rpt_list(l_rpt_idx,l_rec_report.*) 
		#---------------------------------------------------------		

	END FOREACH 
	##
	## GL - Retrieve unposted cancelled cheques
	##
	DECLARE c_cancelcheq CURSOR FOR 
	SELECT * FROM cancelcheq 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND bank_acct_code = glob_rec_rpt_data_select.acct_code 
	AND bank_code = glob_rec_rpt_data_select.bank_code 
	AND orig_posted_flag = "Y" 
	AND (orig_year_num < glob_rec_rpt_data_select.year_num 
	or(orig_year_num = glob_rec_rpt_data_select.year_num 
	AND orig_period_num <= glob_rec_rpt_data_select.period_num)) 
	AND (cancel_year_num > glob_rec_rpt_data_select.year_num 
	or(cancel_year_num = glob_rec_rpt_data_select.year_num 
	AND cancel_period_num > glob_rec_rpt_data_select.period_num)) 

	FOREACH c_cancelcheq INTO l_rec_cancelcheq.* 
		INITIALIZE l_rec_report.* TO NULL 
		LET l_rec_report.type_ind = "G" 
		LET l_rec_report.seq_ind = 3 
		LET l_rec_report.tran_date = l_rec_cancelcheq.cheq_date 
		LET l_rec_report.prompt_text = "Cancelled cheque(s)" 
		LET l_rec_report.tran_num = l_rec_cancelcheq.cheq_code 
		LET l_rec_report.tran_code = l_rec_cancelcheq.vend_code 
		SELECT name_text INTO l_rec_report.tran_text FROM vendor 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND vend_code = l_rec_cancelcheq.vend_code 
		IF l_rec_cancelcheq.net_pay_amt >= 0 THEN 
			LET l_rec_report.cr_tran_amt = 0 
			LET l_rec_report.dr_tran_amt = l_rec_cancelcheq.net_pay_amt 
			IF l_rec_cancelcheq.orig_curr_code != 
			glob_rec_rpt_data_select.bank_currency_code THEN 
				LET l_rec_report.dr_tran_amt = l_rec_report.dr_tran_amt / 
				l_rec_cancelcheq.orig_conv_qty 
			END IF 
		ELSE 
			LET l_rec_report.cr_tran_amt = 0 - l_rec_cancelcheq.net_pay_amt 
			LET l_rec_report.dr_tran_amt = 0 
			IF l_rec_cancelcheq.orig_curr_code != 
			glob_rec_rpt_data_select.bank_currency_code THEN 
				LET l_rec_report.cr_tran_amt = l_rec_report.cr_tran_amt / 
				l_rec_cancelcheq.orig_conv_qty 
			END IF 
		END IF 
		#---------------------------------------------------------
		OUTPUT TO REPORT GC5_rpt_list(l_rpt_idx,l_rec_report.*) 
		#---------------------------------------------------------
	END FOREACH 
	##
	## GL - Retrieve unposted journals
	##
	DECLARE c_batchdetl CURSOR FOR 
	SELECT batchdetl.* 
	FROM batchdetl, 
	batchhead 
	WHERE batchhead.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND batchhead.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND batchdetl.jour_num = batchhead.jour_num 
	AND batchdetl.jour_code = batchhead.jour_code 
	AND batchdetl.acct_code = glob_rec_rpt_data_select.acct_code 
	AND post_flag = "N" 
	AND (year_num < glob_rec_rpt_data_select.year_num 
	or(year_num = glob_rec_rpt_data_select.year_num 
	AND period_num <= glob_rec_rpt_data_select.period_num)) 

	FOREACH c_batchdetl INTO l_rec_batchdetl.* 
		INITIALIZE l_rec_report.* TO NULL 
		LET l_rec_report.type_ind = "G" 
		LET l_rec_report.seq_ind = 4 
		LET l_rec_report.tran_date = l_rec_batchdetl.tran_date 
		LET l_rec_report.prompt_text = "Unposted journal(s)" 
		LET l_rec_report.tran_num = l_rec_batchdetl.jour_num 
		LET l_rec_report.tran_code = l_rec_batchdetl.ref_text 
		LET l_rec_report.tran_text = l_rec_batchdetl.desc_text 
		LET l_rec_report.dr_tran_amt = l_rec_batchdetl.for_debit_amt 
		LET l_rec_report.cr_tran_amt = l_rec_batchdetl.for_credit_amt 
		#---------------------------------------------------------
		OUTPUT TO REPORT GC5_rpt_list(l_rpt_idx,l_rec_report.*) 
		#---------------------------------------------------------
	END FOREACH 
	###
	###  Unposted GL Cash POS Entries
	###
	CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,today) 
	RETURNING l_year_num, 
	l_period_num 
	IF l_year_num = glob_rec_rpt_data_select.year_num 
	AND l_period_num = glob_rec_rpt_data_select.period_num THEN 
		DECLARE c_pospmnts CURSOR FOR 
		SELECT sum(pay_amount),tran_date FROM pospmnts 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND bank_code = glob_rec_rpt_data_select.bank_code 
		AND posted = "N" 
		AND banked = "Y" 
		AND cash_num IS NULL 
		GROUP BY tran_date 
		ORDER BY tran_date 

		FOREACH c_pospmnts INTO l_pay_amt, l_tran_date 
			INITIALIZE l_rec_report.* TO NULL 
			LET l_rec_report.type_ind = "G" 
			LET l_rec_report.seq_ind = 5 
			LET l_rec_report.tran_date = l_tran_date 
			LET l_rec_report.prompt_text = "POS banking" 
			IF l_pay_amt < 0 THEN 
				LET l_rec_report.dr_tran_amt = 0 
				LET l_rec_report.cr_tran_amt = l_pay_amt 
			ELSE 
				LET l_rec_report.dr_tran_amt = l_pay_amt 
				LET l_rec_report.cr_tran_amt = 0 
			END IF 
		#---------------------------------------------------------
		OUTPUT TO REPORT GC5_rpt_list(l_rpt_idx,l_rec_report.*) 
		#---------------------------------------------------------
		END FOREACH 

	END IF 

	##
	## Cashbook Transactions
	## ---------------------
	##
	## Inital transaction FOR Cash Book (as per GL)
	##
	INITIALIZE l_rec_report.* TO NULL 
	LET l_rec_report.type_ind = "C" 
	LET l_rec_report.seq_ind = 0 
	LET l_rec_report.dr_tran_amt = 0 
	LET l_rec_report.cr_tran_amt = 0 
		#---------------------------------------------------------
		OUTPUT TO REPORT GC5_rpt_list(l_rpt_idx,l_rec_report.*) 
		#---------------------------------------------------------
	##
	## CB - Retrieve Unreconciled Deposits
	##
	DECLARE c1_banking CURSOR FOR 
	## Those still outstanding
	SELECT * FROM banking 
	WHERE bk_cmpy = glob_rec_kandoouser.cmpy_code 
	AND bk_acct = glob_rec_rpt_data_select.acct_code 
	AND bk_type NOT in ("XO","XC") 
	AND ((bk_sh_no IS NULL OR bk_rec_part = "Y") 
	OR (bk_sh_no > glob_rec_rpt_data_select.sheet_num)) 
	AND bk_bankdt <= glob_rec_rpt_data_select.end_date 

	FOREACH c1_banking INTO l_rec_banking.* 
		INITIALIZE l_rec_report.* TO NULL 
		LET l_rec_report.type_ind = "C" 
		LET l_rec_report.seq_ind = 6 
		LET l_rec_report.tran_date = l_rec_banking.bk_bankdt 
		LET l_rec_report.tran_code = l_rec_banking.bk_type 
		LET l_rec_report.prompt_text = "Unreconciled Banking item(s)" 
		IF l_rec_banking.bk_sh_no IS NOT NULL THEN 
			LET l_rec_report.recon_ind = "*" 
		END IF 

		CASE l_rec_banking.bk_type 
			WHEN "SC" 
				LET l_rec_report.tran_text = "Sundry credit" 
			WHEN "BD" 
				LET l_rec_report.tran_text = "Bank deposit" 
			WHEN "DP" 
				LET l_rec_report.tran_text = "Bank deposit" 
			WHEN "CD" 
				LET l_rec_report.tran_text = "Cash deposit" 
			WHEN "BC" 
				LET l_rec_report.tran_text = "Bank charge" 
			WHEN "TI" 
				LET l_rec_report.tran_text = "Transfer in" 
			WHEN "TO" 
				LET l_rec_report.tran_text = "Transfer out" 
			OTHERWISE 
				LET l_rec_report.tran_text = "** Error **" 
		END CASE 

		LET l_rec_report.tran_text = l_rec_report.tran_text clipped, " ", 
		l_rec_banking.bk_desc clipped 
		LET l_rec_report.tran_num = l_rec_banking.bank_dep_num 
		LET l_rec_report.dr_tran_amt = l_rec_banking.bk_debit 
		LET l_rec_report.cr_tran_amt = l_rec_banking.bk_cred 
		IF l_rec_report.cr_tran_amt IS NULL THEN 
			LET l_rec_report.cr_tran_amt = 0 
		END IF 
		IF l_rec_report.dr_tran_amt IS NULL THEN 
			LET l_rec_report.dr_tran_amt = 0 
		END IF 
		## Do NOT list zero value bankings as unreconciled
		IF l_rec_report.dr_tran_amt <> 0 OR l_rec_report.cr_tran_amt <> 0 THEN 
		#---------------------------------------------------------
		OUTPUT TO REPORT GC5_rpt_list(l_rpt_idx,l_rec_report.*) 
		#---------------------------------------------------------
		END IF 
	END FOREACH 
	##
	## CB - Retrieve Unpresented Cheques
	##

	DECLARE c2_cheque CURSOR FOR 
	SELECT * FROM cheque 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND bank_acct_code = glob_rec_rpt_data_select.acct_code 
	AND bank_code = glob_rec_rpt_data_select.bank_code 
	AND ((rec_state_num IS NULL OR part_recon_flag = "Y") 
	OR (rec_state_num > glob_rec_rpt_data_select.sheet_num AND recon_flag = "Y")) 
	AND (year_num < glob_rec_rpt_data_select.year_num 
	or(year_num = glob_rec_rpt_data_select.year_num 
	AND period_num <= glob_rec_rpt_data_select.period_num)) 

	FOREACH c2_cheque INTO l_rec_cheque.* 
		INITIALIZE l_rec_report.* TO NULL 
		LET l_rec_report.type_ind = "C" 
		LET l_rec_report.seq_ind = 7 
		LET l_rec_report.tran_date = l_rec_cheque.cheq_date 
		LET l_rec_report.prompt_text = "Un-Presented cheque(s)" 
		LET l_rec_report.tran_num = l_rec_cheque.cheq_code 
		LET l_rec_report.tran_code = l_rec_cheque.vend_code 
		IF l_rec_cheque.rec_state_num IS NOT NULL THEN 
			LET l_rec_report.recon_ind = "*" 
		END IF 
		SELECT name_text INTO l_rec_report.tran_text FROM vendor 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND vend_code = l_rec_cheque.vend_code 
		IF l_rec_cheque.net_pay_amt >= 0 THEN 
			LET l_rec_report.cr_tran_amt = 0 
			LET l_rec_report.dr_tran_amt = l_rec_cheque.net_pay_amt 
			IF l_rec_cheque.currency_code != 
			glob_rec_rpt_data_select.bank_currency_code THEN 
				LET l_rec_report.dr_tran_amt = l_rec_report.dr_tran_amt / 
				l_rec_cheque.conv_qty 
			END IF 
		ELSE 
			LET l_rec_report.cr_tran_amt = 0 - l_rec_cheque.net_pay_amt 
			LET l_rec_report.dr_tran_amt = 0 
			IF l_rec_cheque.currency_code != 
			glob_rec_rpt_data_select.bank_currency_code THEN 
				LET l_rec_report.cr_tran_amt = l_rec_report.cr_tran_amt / 
				l_rec_cheque.conv_qty 
			END IF 
		END IF 
		#---------------------------------------------------------
		OUTPUT TO REPORT GC5_rpt_list(l_rpt_idx,l_rec_report.*) 
		#---------------------------------------------------------
	END FOREACH 
	##
	## CB - Retrieve unbanked cashreceipts OR receipts NOT banked
	##      through AR AND outside
	##      the selection statement date
	##

	DECLARE c2_cashreceipt CURSOR FOR 
	SELECT * FROM cashreceipt 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cash_acct_code = glob_rec_rpt_data_select.acct_code 
	AND ((banked_flag = "N") 
	or(banked_flag = "Y" 
	AND bank_dep_num IS NULL 
	AND banked_date > glob_rec_rpt_data_select.end_date)) 
	AND (year_num < glob_rec_rpt_data_select.year_num 
	or(year_num = glob_rec_rpt_data_select.year_num 
	AND cashreceipt.period_num <= glob_rec_rpt_data_select.period_num)) 

	FOREACH c2_cashreceipt INTO l_rec_cashreceipt.* 
		INITIALIZE l_rec_report.* TO NULL 
		LET l_rec_report.type_ind = "C" 
		LET l_rec_report.seq_ind = 8 
		LET l_rec_report.tran_date = l_rec_cashreceipt.cash_date 
		LET l_rec_report.prompt_text = "Unbanked receipt(s)" 
		LET l_rec_report.tran_num = l_rec_cashreceipt.cash_num 
		LET l_rec_report.tran_code = l_rec_cashreceipt.cust_code 
		IF l_rec_cashreceipt.banked_flag = "Y" THEN 
			LET l_rec_report.recon_ind = "*" 
		END IF 
		SELECT name_text INTO l_rec_report.tran_text FROM customer 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = l_rec_cashreceipt.cust_code 
		IF l_rec_cashreceipt.cash_amt >= 0 THEN 
			LET l_rec_report.cr_tran_amt = l_rec_cashreceipt.cash_amt 
			LET l_rec_report.dr_tran_amt = 0 
			IF l_rec_cashreceipt.currency_code != 
			glob_rec_rpt_data_select.bank_currency_code THEN 
				LET l_rec_report.cr_tran_amt = l_rec_report.cr_tran_amt / 
				l_rec_cashreceipt.conv_qty 
			END IF 
		ELSE 
			LET l_rec_report.cr_tran_amt = 0 
			LET l_rec_report.dr_tran_amt = 0 - l_rec_cashreceipt.cash_amt 
			IF l_rec_cashreceipt.currency_code != 
			glob_rec_rpt_data_select.bank_currency_code THEN 
				LET l_rec_report.dr_tran_amt = l_rec_report.dr_tran_amt / 
				l_rec_cashreceipt.conv_qty 
			END IF 
		END IF 

		#---------------------------------------------------------
		OUTPUT TO REPORT GC5_rpt_list(l_rpt_idx,l_rec_report.*) 
		#---------------------------------------------------------
	END FOREACH 

	##
	## CB - Retrieve banked cashreceipts that are reconciled outside
	## the selected statement period - all these receipts are flagged as
	## reconciled in a future period
	##
	DECLARE c3_cashreceipt CURSOR FOR 
	SELECT distinct c.cash_num FROM cashreceipt c, banking b 
	WHERE c.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND b.bk_cmpy = glob_rec_kandoouser.cmpy_code 
	AND c.cash_acct_code = glob_rec_rpt_data_select.acct_code 
	AND b.bk_acct = glob_rec_rpt_data_select.acct_code 
	AND c.bank_dep_num IS NOT NULL 
	AND c.bank_dep_num = b.bank_dep_num 
	AND b.bk_bankdt > glob_rec_rpt_data_select.end_date 
	AND (b.bk_sh_no IS NULL OR b.bk_sh_no > glob_rec_rpt_data_select.sheet_num) 
	AND (c.year_num < glob_rec_rpt_data_select.year_num 
	or(c.year_num = glob_rec_rpt_data_select.year_num 
	AND c.period_num <= glob_rec_rpt_data_select.period_num)) 

	FOREACH c3_cashreceipt INTO l_rec_cashreceipt.cash_num 
		INITIALIZE l_rec_report.* TO NULL 
		SELECT * INTO l_rec_cashreceipt.* FROM cashreceipt 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cash_num = l_rec_cashreceipt.cash_num 
		LET l_rec_report.type_ind = "C" 
		LET l_rec_report.seq_ind = 9 
		LET l_rec_report.prompt_text = "Unbanked receipt(s)" 
		LET l_rec_report.tran_date = l_rec_cashreceipt.cash_date 
		LET l_rec_report.tran_num = l_rec_cashreceipt.cash_num 
		LET l_rec_report.tran_code = l_rec_cashreceipt.cust_code 
		LET l_rec_report.recon_ind = "*" 
		SELECT name_text INTO l_rec_report.tran_text FROM customer 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = l_rec_cashreceipt.cust_code 
		IF l_rec_cashreceipt.cash_amt >= 0 THEN 
			LET l_rec_report.cr_tran_amt = l_rec_cashreceipt.cash_amt 
			LET l_rec_report.dr_tran_amt = 0 
			IF l_rec_cashreceipt.currency_code != 
			glob_rec_rpt_data_select.bank_currency_code THEN 
				LET l_rec_report.cr_tran_amt = l_rec_report.cr_tran_amt / 
				l_rec_cashreceipt.conv_qty 
			END IF 
		ELSE 
			LET l_rec_report.cr_tran_amt = 0 
			LET l_rec_report.dr_tran_amt = 0 - l_rec_cashreceipt.cash_amt 
			IF l_rec_cashreceipt.currency_code != 
			glob_rec_rpt_data_select.bank_currency_code THEN 
				LET l_rec_report.dr_tran_amt = l_rec_report.dr_tran_amt / 
				l_rec_cashreceipt.conv_qty 
			END IF 
		END IF 
		#---------------------------------------------------------
		OUTPUT TO REPORT GC5_rpt_list(l_rpt_idx,l_rec_report.*) 
		#---------------------------------------------------------
	END FOREACH 

	###
	###  POS Unbanked Receipts
	###
	CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,today) 
	RETURNING l_year_num, 
	l_period_num 
	IF l_year_num = glob_rec_rpt_data_select.year_num 
	AND l_period_num = glob_rec_rpt_data_select.period_num THEN 
		DECLARE c2_pospmnts CURSOR FOR 
		SELECT sum(pay_amount),tran_date FROM pospmnts 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND posted = "Y" 
		AND banked = "N" 
		AND bank_code = glob_rec_rpt_data_select.bank_code 
		GROUP BY tran_date 
		ORDER BY tran_date 
		FOREACH c2_pospmnts INTO l_pay_amt, l_tran_date 
			INITIALIZE l_rec_report.* TO NULL 
			LET l_rec_report.type_ind = "C" 
			LET l_rec_report.seq_ind = 10 
			LET l_rec_report.tran_date = l_tran_date 
			LET l_rec_report.prompt_text = "POS Unbanked receipts" 
			IF l_pay_amt < 0 THEN 
				LET l_rec_report.dr_tran_amt = l_pay_amt 
				LET l_rec_report.cr_tran_amt = 0 
			ELSE 
				LET l_rec_report.dr_tran_amt = 0 
				LET l_rec_report.cr_tran_amt = l_pay_amt 
			END IF 
		#---------------------------------------------------------
		OUTPUT TO REPORT GC5_rpt_list(l_rpt_idx,l_rec_report.*) 
		#---------------------------------------------------------
		END FOREACH 
	END IF 

	###
	###  Incomplete Banking Entries
	###
	CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,today) 
	RETURNING l_year_num, 
	l_period_num 
	IF l_year_num = glob_rec_rpt_data_select.year_num 
	AND l_period_num = glob_rec_rpt_data_select.period_num THEN 
		DECLARE c3_tentbankhead CURSOR FOR 
		SELECT * FROM tentbankhead 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND bank_code = glob_rec_rpt_data_select.bank_code 
		FOREACH c3_tentbankhead INTO l_rec_tentbankhead.* 
			SELECT sum(tran_amt) INTO l_pay_amt 
			FROM tentbankdetl 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND bank_dep_num = l_rec_tentbankhead.bank_dep_num 
			IF l_pay_amt IS NULL THEN 
				LET l_pay_amt = 0 
			END IF 
			INITIALIZE l_rec_report.* TO NULL 
			LET l_rec_report.type_ind = "C" 
			LET l_rec_report.seq_ind = 11 
			LET l_rec_report.tran_date = l_rec_tentbankhead.entry_date 
			LET l_rec_report.prompt_text = "Incomplete banking" 
			LET l_rec_report.tran_num = l_rec_tentbankhead.bank_dep_num 
			LET l_rec_report.tran_text = l_rec_tentbankhead.desc_text 
			IF l_pay_amt < 0 THEN 
				LET l_rec_report.dr_tran_amt = l_pay_amt 
				LET l_rec_report.cr_tran_amt = 0 
			ELSE 
				LET l_rec_report.dr_tran_amt = 0 
				LET l_rec_report.cr_tran_amt = l_pay_amt 
			END IF
			
		#---------------------------------------------------------
		OUTPUT TO REPORT GC5_rpt_list(l_rpt_idx,l_rec_report.*) 
		#---------------------------------------------------------
			 
		END FOREACH 
	END IF 
	
	#------------------------------------------------------------
	FINISH REPORT GC5_rpt_list
	CALL rpt_finish("GC5_rpt_list")
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
# REPORT GC5_rpt_list(p_rpt_idx,l_rec_report)
#
#
############################################################
REPORT GC5_rpt_list(p_rpt_idx,l_rec_report)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx] 
	DEFINE l_rec_report 
	RECORD 
		type_ind char(1), 
		seq_ind SMALLINT, 
		tran_date DATE, 
		tran_num INTEGER, 
		tran_code char(8), 
		tran_text char(30), 
		dr_tran_amt decimal(16,2), 
		cr_tran_amt decimal(16,2), 
		prompt_text char(40), 
		recon_ind char(1) 
	END RECORD 
	DEFINE l_arr_line array[4] OF char(132) 
	DEFINE l_arr_rec_trans array[11] OF 
	RECORD 
		tran_text char(40), 
		tran_cnt INTEGER, 
		dr_tran_amt decimal(16,2), 
		cr_tran_amt decimal(16,2) 
	END RECORD 
	DEFINE l_curr_code LIKE bank.currency_code 
	DEFINE l_tmp_amt LIKE bank.state_base_bal_amt 
	DEFINE l_idx SMALLINT 
	#DEFINE l_temp_text CHAR(100) #not used

	OUTPUT 
--	left margin 0 
--	PAGE length 66 
	ORDER external BY l_rec_report.type_ind desc, 
	l_rec_report.seq_ind, 
	l_rec_report.tran_date 

	FORMAT 
		FIRST PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  

			FOR l_idx = 1 TO 11 
				LET l_arr_rec_trans[l_idx].tran_text = NULL 
				LET l_arr_rec_trans[l_idx].tran_cnt = 0 
				LET l_arr_rec_trans[l_idx].dr_tran_amt = 0 
				LET l_arr_rec_trans[l_idx].cr_tran_amt = 0 
			END FOR 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  

		BEFORE GROUP OF l_rec_report.type_ind 
			IF l_rec_report.type_ind = "G" THEN 
				LET l_curr_code = NULL 
				SELECT currency_code INTO l_curr_code FROM bank 
				WHERE bank_code = glob_rec_rpt_data_select.bank_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF glob_rec_rpt_data_select.detail_flag = "Y" THEN 
					SKIP 2 line 
					PRINT COLUMN 01,"========= General Ledger Detail =========" 
					SKIP 1 line 
					PRINT COLUMN 01,"GL Account :", 
					COLUMN 16, glob_rec_rpt_data_select.acct_code 
					PRINT COLUMN 15, ":",glob_rec_rpt_data_select.coa_text 
					PRINT COLUMN 01,"Fiscal Year :", 
					COLUMN 16, glob_rec_rpt_data_select.year_num USING "&&&&" 
					PRINT COLUMN 08,"Period :", 
					COLUMN 16, glob_rec_rpt_data_select.period_num USING "<<<" 
					PRINT COLUMN 01,"Period Ending :", 
					COLUMN 16, glob_rec_rpt_data_select.end_date USING "dd/mm/yy" 
					PRINT COLUMN 01,"Currency :", l_curr_code 
					SKIP 1 line 
					PRINT COLUMN 01,glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text
					SKIP 1 line 
					PRINT COLUMN 01,"General Ledger balance:"; 
					IF glob_rec_rpt_data_select.gl_bal_amt >= 0 THEN 
						PRINT COLUMN 60, glob_rec_rpt_data_select.gl_bal_amt USING "--------&.&&" 
					ELSE 
						PRINT COLUMN 67, 0-glob_rec_rpt_data_select.gl_bal_amt USING "--------&.&&" 
					END IF 
				END IF 
				LET glob_rec_rpt_data_select.gl_close_amt = glob_rec_rpt_data_select.gl_bal_amt 
			ELSE 
				IF glob_rec_rpt_data_select.detail_flag = "Y" THEN 
					SKIP 4 line 
					PRINT COLUMN 01,"========= Cashbook Detail ===============" 
					SKIP 1 line 
					PRINT COLUMN 01,"Bank Code :", 
					COLUMN 16, glob_rec_rpt_data_select.bank_code 
					PRINT COLUMN 15, ":",glob_rec_rpt_data_select.name_acct_text 
					PRINT COLUMN 01,"Account No. :", 
					COLUMN 16, glob_rec_rpt_data_select.iban 
					PRINT COLUMN 01,"Sheet Number :", 
					COLUMN 16, glob_rec_rpt_data_select.sheet_num USING "<<<<<" 
					PRINT COLUMN 01,"Statement date:", 
					COLUMN 16, glob_rec_rpt_data_select.sheet_date USING "dd/mm/yy" 
					PRINT COLUMN 01,"Currency :", l_curr_code 
					SKIP 1 line 
					PRINT COLUMN 01,glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
					SKIP 1 line 
					PRINT COLUMN 01,"Cashbook balance:"; 
					IF glob_rec_rpt_data_select.cb_bal_amt >= 0 THEN 
						PRINT COLUMN 67, glob_rec_rpt_data_select.cb_bal_amt USING "--------&.&&" 
					ELSE 
						PRINT COLUMN 60, 0-glob_rec_rpt_data_select.cb_bal_amt USING "--------&.&&" 
					END IF 
				END IF 
				LET glob_rec_rpt_data_select.cb_close_amt = glob_rec_rpt_data_select.cb_bal_amt 
			END IF 

		BEFORE GROUP OF l_rec_report.seq_ind 
			##
			## IF detail mode IS selected, do NOT PRINT initial trigger transaction
			##
			IF glob_rec_rpt_data_select.detail_flag = "Y" AND l_rec_report.seq_ind > 0 THEN 
				SKIP 1 line 
				PRINT COLUMN 01,l_rec_report.prompt_text clipped,":" 
			END IF 

		ON EVERY ROW 
			##
			## IF detail mode IS selected, do NOT PRINT initial trigger transaction
			##
			IF glob_rec_rpt_data_select.detail_flag = "Y" AND l_rec_report.seq_ind > 0 THEN 
				## Accumulate running balance
				IF l_rec_report.type_ind = "G" THEN 
					LET glob_rec_rpt_data_select.gl_close_amt = glob_rec_rpt_data_select.gl_close_amt 
					+ l_rec_report.dr_tran_amt 
					- l_rec_report.cr_tran_amt 
					LET l_tmp_amt = glob_rec_rpt_data_select.gl_close_amt 
				ELSE 
					LET glob_rec_rpt_data_select.cb_close_amt = glob_rec_rpt_data_select.cb_close_amt 
					- l_rec_report.dr_tran_amt 
					+ l_rec_report.cr_tran_amt 
					LET l_tmp_amt = glob_rec_rpt_data_select.cb_close_amt 
				END IF 
				IF l_rec_report.dr_tran_amt = 0 THEN 
					LET l_rec_report.dr_tran_amt = NULL 
				END IF 
				IF l_rec_report.cr_tran_amt = 0 THEN 
					LET l_rec_report.cr_tran_amt = NULL 
				END IF 
				PRINT COLUMN 01,l_rec_report.tran_date USING "dd/mm/yy", 
				COLUMN 10,l_rec_report.tran_num USING "#########", 
				COLUMN 20,l_rec_report.tran_code, 
				COLUMN 29,l_rec_report.tran_text; 
				IF l_rec_report.dr_tran_amt != 0 THEN 
					PRINT COLUMN 60,l_rec_report.dr_tran_amt USING "--------&.&&"; 
				END IF 
				IF l_rec_report.cr_tran_amt != 0 THEN 
					PRINT COLUMN 67,l_rec_report.cr_tran_amt USING "--------&.&&"; 
				END IF 
				PRINT COLUMN 80,l_rec_report.recon_ind 
			END IF 
			IF l_rec_report.seq_ind > 0 THEN 
				LET l_idx = l_rec_report.seq_ind 
				LET l_arr_rec_trans[l_idx].tran_text = l_rec_report.prompt_text 
			END IF 
		AFTER GROUP OF l_rec_report.seq_ind 
			IF l_rec_report.seq_ind > 0 THEN 
				LET l_idx = l_rec_report.seq_ind 
				LET l_arr_rec_trans[l_idx].tran_cnt = GROUP count(*) 
				LET l_arr_rec_trans[l_idx].cr_tran_amt = GROUP sum(l_rec_report.cr_tran_amt) 
				LET l_arr_rec_trans[l_idx].dr_tran_amt = GROUP sum(l_rec_report.dr_tran_amt) 
			END IF 
		AFTER GROUP OF l_rec_report.type_ind 
			IF glob_rec_rpt_data_select.detail_flag = "Y" THEN 
				IF l_rec_report.type_ind = "G" THEN 
					LET l_tmp_amt = glob_rec_rpt_data_select.gl_close_amt 
					IF l_tmp_amt >= 0 THEN 
						PRINT COLUMN 59,"-------------" 
						PRINT COLUMN 01, "Computed total:", 
						COLUMN 59,l_tmp_amt USING "#########&.&&" 
					ELSE 
						PRINT COLUMN 66,"-------------" 
						PRINT COLUMN 01, "Computed total:", 
						COLUMN 66,0-l_tmp_amt USING "#########&.&&" 
					END IF 
				ELSE 
					LET l_tmp_amt = glob_rec_rpt_data_select.cb_close_amt 
					IF l_tmp_amt >= 0 THEN 
						PRINT COLUMN 66,"-------------" 
						PRINT COLUMN 01, "Computed total:", 
						COLUMN 66,l_tmp_amt USING "#########&.&&" 
					ELSE 
						PRINT COLUMN 59,"-------------" 
						PRINT COLUMN 01, "Computed total:", 
						COLUMN 59,0-l_tmp_amt USING "#########&.&&" 
					END IF 
				END IF 
			END IF 
		ON LAST ROW 
			SKIP TO top OF PAGE 
			SKIP 2 LINES 
			PRINT COLUMN 01,"GL Account :", 
			COLUMN 16, glob_rec_rpt_data_select.acct_code 
			PRINT COLUMN 15, ":",glob_rec_rpt_data_select.coa_text 
			PRINT COLUMN 01,"Fiscal Year :", 
			COLUMN 16, glob_rec_rpt_data_select.year_num USING "&&&&" 
			PRINT COLUMN 08,"Period :", 
			COLUMN 16, glob_rec_rpt_data_select.period_num USING "<<<" 
			PRINT COLUMN 01,"Period Ending :", 
			COLUMN 16, glob_rec_rpt_data_select.end_date USING "dd/mm/yy" 
			PRINT COLUMN 01,"Currency :", l_curr_code 
			SKIP 1 line 
			PRINT COLUMN 01, "General Ledger position", 
			COLUMN 56, "Debit amt", 
			COLUMN 69, "Credit amt" 
			PRINT COLUMN 01, "=======================", 
			COLUMN 52, "=============", 
			COLUMN 66, "=============" 
			SKIP 1 line 
			PRINT COLUMN 01,"Closing Balance of GL account"; 
			IF glob_rec_rpt_data_select.gl_bal_amt >= 0 THEN 
				PRINT COLUMN 52,glob_rec_rpt_data_select.gl_bal_amt USING "#########&.&&" 
			ELSE 
				PRINT COLUMN 66,0-glob_rec_rpt_data_select.gl_bal_amt USING "#########&.&&" 
			END IF 
			LET glob_rec_rpt_data_select.gl_close_amt = glob_rec_rpt_data_select.gl_bal_amt 
			FOR l_idx = 1 TO 5 
				IF l_arr_rec_trans[l_idx].tran_cnt IS NULL THEN 
					LET l_arr_rec_trans[l_idx].tran_cnt = 0 
				END IF 
				IF l_arr_rec_trans[l_idx].cr_tran_amt IS NULL THEN 
					LET l_arr_rec_trans[l_idx].cr_tran_amt = 0 
				END IF 
				IF l_arr_rec_trans[l_idx].dr_tran_amt IS NULL THEN 
					LET l_arr_rec_trans[l_idx].dr_tran_amt = 0 
				END IF 
				IF l_arr_rec_trans[l_idx].tran_cnt >0 THEN 
					PRINT COLUMN 01,l_arr_rec_trans[l_idx].tran_cnt USING "########", 
					COLUMN 10,l_arr_rec_trans[l_idx].tran_text; 
					IF l_arr_rec_trans[l_idx].dr_tran_amt != 0 THEN 
						PRINT COLUMN 52,l_arr_rec_trans[l_idx].dr_tran_amt USING "#########&.&&"; 
					END IF 
					IF l_arr_rec_trans[l_idx].cr_tran_amt != 0 THEN 
						PRINT COLUMN 66,l_arr_rec_trans[l_idx].cr_tran_amt USING "#########&.&&"; 
					END IF 
					PRINT "" 
				END IF 
				LET glob_rec_rpt_data_select.gl_close_amt = glob_rec_rpt_data_select.gl_close_amt 
				+ l_arr_rec_trans[l_idx].dr_tran_amt 
				- l_arr_rec_trans[l_idx].cr_tran_amt 
			END FOR 
			PRINT COLUMN 01,"Computed GL Account balance"; 
			IF glob_rec_rpt_data_select.gl_close_amt >= 0 THEN 
				PRINT COLUMN 52,glob_rec_rpt_data_select.gl_close_amt USING "#########&.&&" 
			ELSE 
				PRINT COLUMN 66,0-glob_rec_rpt_data_select.gl_close_amt USING "#########&.&&" 
			END IF 
			SKIP 2 LINES 
			PRINT COLUMN 01,"Bank Code :", 
			COLUMN 16, glob_rec_rpt_data_select.bank_code 
			PRINT COLUMN 15, ":",glob_rec_rpt_data_select.name_acct_text 
			PRINT COLUMN 01,"Account No. :", 
			COLUMN 16, glob_rec_rpt_data_select.iban 
			PRINT COLUMN 01,"Sheet Number :", 
			COLUMN 16, glob_rec_rpt_data_select.sheet_num USING "<<<<<" 
			PRINT COLUMN 01,"Statement date:", 
			COLUMN 16, glob_rec_rpt_data_select.sheet_date USING "dd/mm/yy" 
			PRINT COLUMN 01,"Currency :", l_curr_code 
			SKIP 1 line 
			PRINT COLUMN 01, "Cash Book position", 
			COLUMN 56, "Debit amt", 
			COLUMN 69, "Credit amt" 
			PRINT COLUMN 01, "==================", 
			COLUMN 52, "=============", 
			COLUMN 66, "=============" 
			SKIP 1 line 
			PRINT COLUMN 01,"Closing Balance of statement"; 
			IF glob_rec_rpt_data_select.cb_bal_amt >= 0 THEN 
				PRINT COLUMN 66,glob_rec_rpt_data_select.cb_bal_amt USING "#########&.&&" 
			ELSE 
				PRINT COLUMN 52,0-glob_rec_rpt_data_select.cb_bal_amt USING "#########&.&&" 
			END IF 
			LET glob_rec_rpt_data_select.cb_close_amt = glob_rec_rpt_data_select.cb_bal_amt 
			FOR l_idx = 6 TO 11 
				IF l_arr_rec_trans[l_idx].tran_cnt IS NULL THEN 
					LET l_arr_rec_trans[l_idx].tran_cnt = 0 
				END IF 
				IF l_arr_rec_trans[l_idx].cr_tran_amt IS NULL THEN 
					LET l_arr_rec_trans[l_idx].cr_tran_amt = 0 
				END IF 
				IF l_arr_rec_trans[l_idx].dr_tran_amt IS NULL THEN 
					LET l_arr_rec_trans[l_idx].dr_tran_amt = 0 
				END IF 
				IF l_arr_rec_trans[l_idx].tran_cnt >0 THEN 
					PRINT COLUMN 01,l_arr_rec_trans[l_idx].tran_cnt USING "########", 
					COLUMN 10,l_arr_rec_trans[l_idx].tran_text; 
					IF l_arr_rec_trans[l_idx].dr_tran_amt != 0 THEN 
						PRINT COLUMN 52,l_arr_rec_trans[l_idx].dr_tran_amt USING "#########&.&&"; 
					END IF 
					IF l_arr_rec_trans[l_idx].cr_tran_amt != 0 THEN 
						PRINT COLUMN 66,l_arr_rec_trans[l_idx].cr_tran_amt USING "#########&.&&"; 
					END IF 
					PRINT "" 
				END IF 
				LET glob_rec_rpt_data_select.cb_close_amt = glob_rec_rpt_data_select.cb_close_amt 
				- l_arr_rec_trans[l_idx].dr_tran_amt 
				+ l_arr_rec_trans[l_idx].cr_tran_amt 
			END FOR 
			PRINT COLUMN 01,"Computed Bank Account balance"; 
			IF glob_rec_rpt_data_select.cb_close_amt >= 0 THEN 
				PRINT COLUMN 66,glob_rec_rpt_data_select.cb_close_amt USING "#########&.&&" 
			ELSE 
				PRINT COLUMN 52,0-glob_rec_rpt_data_select.cb_close_amt USING "#########&.&&" 
			END IF 
			IF glob_rec_rpt_data_select.cb_close_amt != glob_rec_rpt_data_select.gl_close_amt THEN 
				PRINT l_arr_line[3] 
				PRINT " WARNING: Discrepancy exists between General Ledger & cashbook" 
			END IF 

			FOR l_idx = 1 TO 7 
				INITIALIZE l_arr_rec_trans[l_idx].* TO NULL 
			END FOR 
			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	
			
			
END REPORT 