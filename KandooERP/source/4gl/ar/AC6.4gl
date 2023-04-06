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
GLOBALS "../ar/A_AR_GLOBALS.4gl"
GLOBALS "../ar/AC_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/AC6_GLOBALS.4gl"
############################################################
# MODULE Scope Variables
############################################################
DEFINE modu_bank_desc_text NCHAR(30)
#####################################################################
# FUNCTION AC6_main()
#
# AC6 IS TO PRINT daily Bank Deposit Slips
#
# TO get the summary AT the top of the form we have TO do two passes.
# The first one outputs the cashreceipt TO a temp table AND updates the
# cashreceipt.banked_flag TO Y AND sets the banked_date TO today.
# It THEN calculates the summary totals.
# The second pass reads the temp table AND actually writes the REPORT.
# In this way we cover ourselves in the multi-user environment
# against another operator adding receipts WHILE the program runs.
#
# The temporary table IS created first thing in 'main' so it IS only
# ever created once in the running of the program.
#
# Note:
#		LET glob_rec_rpt_selector.ref1_text = modu_bank_desc_text
#		LET glob_rec_rpt_selector.ref1_code = glob_rec_bank.bank_code
#		LET glob_rec_rpt_selector.ref2_code = l_option
#		LET glob_rec_rpt_selector.ref2_text = l_report_text 
#
#####################################################################
FUNCTION AC6_main() 
	DEFER quit 
	DEFER interrupt
	
	CALL setModuleId("AC6") 

	CALL create_table("cashreceipt","t_cashreceipt","","N") 
				
	SELECT * INTO glob_rec_userlocn.* FROM userlocn 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND sign_on_code = glob_rec_kandoouser.sign_on_code 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 
			OPEN WINDOW A174 with FORM "A174" 
			CALL windecoration_a("A174") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title
		

		
			MENU " Bank Deposit Slips" 
		
				BEFORE MENU 
					CALL publish_toolbar("kandoo","AC6","menu-bank-deposits") 
					CALL AC6_rpt_process(AC6_rpt_query())
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				ON ACTION "Report" #COMMAND "Run Report" " Generate the Bank Deposit Slips Report"
				CALL AC6_rpt_process(AC6_rpt_query())
				#	LET glob_option = "E" 
				#	CALL AC6_rpt_rep_or_upd() 
				#	IF glob_option = "E" THEN 
				#		EXIT MENU 
				#	END IF 
				#	IF AC6_rpt_process() THEN 
				#		NEXT option "Print " 
				#	END IF 
		
				ON ACTION "Print Manager" #COMMAND KEY ("P",f11) "Print" " Print OR View using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "CANCEL" #command  key (interrupt,"E")"Exit" " Exit the Program"
					EXIT MENU 
			END MENU 
			CLOSE WINDOW A174
	 
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL AC6_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW A174 with FORM "A174" 
			CALL windecoration_a("A174") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(AC6_rpt_query()) #save where clause in env 
			CLOSE WINDOW A174 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL AC6_rpt_process(get_url_sel_text())
	END CASE
	 	
END FUNCTION 
#####################################################################
# FUNCTION AC6_main()
#####################################################################


#####################################################################
# FUNCTION AC6_rpt_rep_or_upd()
#
# RETURN l_option, glob_rec_rmsreps.report_text
#####################################################################
FUNCTION AC6_rpt_rep_or_upd() 
	DEFINE l_option CHAR(1)
	DEFINE l_report_text LIKE rmsreps.report_text
	MENU "Bank Deposit Slips" 

		BEFORE MENU 
			CALL publish_toolbar("kandoo","AC6","menu-bank-deposit-slips") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "Report" #COMMAND "Report" "Generate Report Only"
			LET l_option = "R" 
			LET l_report_text = "AR Pre Bank Deposit Slips" 
			EXIT MENU 

		ON ACTION "UPDATE" #COMMAND "UPDATE" "Generate Report AND Update"
			LET l_option = "U" 
			LET l_report_text = "AR Bank Deposit Slips" 
			EXIT MENU 

		ON ACTION "CANCEL" #COMMAND "Exit" "Exit the Program"
			LET l_option = NULL
			LET l_report_text = NULL 

			EXIT MENU 

	END MENU

	IF int_flag THEN
		LET int_flag = FALSE
		
		LET glob_rec_rpt_selector.ref2_code = NULL
		LET glob_rec_rpt_selector.ref2_text = NULL 
	
	ELSE
		LET glob_rec_rpt_selector.ref2_code = l_option
		LET glob_rec_rpt_selector.ref2_text = l_report_text 
	END IF

	RETURN l_option
END FUNCTION 
#####################################################################
# END FUNCTION AC6_rpt_rep_or_upd()
#####################################################################


#####################################################################
# FUNCTION AC6_rpt_query() 
#
#
#####################################################################
FUNCTION AC6_rpt_query() 
	DEFINE l_where_text STRING
	CLEAR FORM 
	MESSAGE kandoomsg2("A",1055,"") #1055 Enter Banking Details"

	IF NOT AC6_rpt_rep_or_upd() THEN
		MESSAGE "User aborted query"
		RETURN NULL
	END IF

	INPUT 
		glob_rec_bank.bank_code,
		modu_bank_desc_text WITHOUT DEFAULTS 
	FROM 
		bank_code,
		desc_text ATTRIBUTE(UNBUFFERED)

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","AC6","inp-bank") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null)
			 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield (bank_code) 
			CALL show_bank(glob_rec_kandoouser.cmpy_code) 
			RETURNING glob_rec_bank.bank_code, glob_rec_bank.acct_code 
			NEXT FIELD bank_code 

		AFTER FIELD bank_code 
			IF glob_rec_bank.bank_code IS NULL THEN 
				ERROR " You must Specify a Bank" 
				NEXT FIELD bank_code 
			ELSE 
				SELECT * INTO glob_rec_bank.* FROM bank 
				WHERE bank_code = glob_rec_bank.bank_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = NOTFOUND THEN 
					error" Bank ",glob_rec_bank.bank_code clipped," NOT found" 
					NEXT FIELD bank_code 
				END IF 
			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false
		MESSAGE "Report aborted by the user" 
		RETURN NULL 
	END IF 

	MESSAGE kandoomsg2("A",1001,"") #1001 Enter Selection criteria - Esc TO continue"
	CONSTRUCT BY NAME l_where_text ON entry_date, 
	cash_date, 
	cash_type_ind, 
	cheque_text, 
	drawer_text, 
	order_num, 
	locn_code, 
	entry_code 

		BEFORE CONSTRUCT 
			DISPLAY glob_rec_userlocn.locn_code TO locn_code 
			CALL publish_toolbar("kandoo","AC6","construct-invoicepay") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false		
		LET quit_flag = false
		
		LET glob_rec_rpt_selector.ref1_text = NULL
		LET glob_rec_rpt_selector.ref1_code = NULL	 
		RETURN NULL
	ELSE
		--LET  = modu_bank_desc_text #what are we doing with modu_bank_desc_text ?
		LET glob_rec_rpt_selector.ref1_text = modu_bank_desc_text
		LET glob_rec_rpt_selector.ref1_code = glob_rec_bank.bank_code
		RETURN l_where_text 
	END IF 
	
END FUNCTION
#####################################################################
# END FUNCTION AC6_rpt_query() 
#####################################################################


#####################################################################
# FUNCTION AC6_rpt_process(p_where_text) 
#
#
#####################################################################
FUNCTION AC6_rpt_process(p_where_text) 
	DEFINE p_where_text STRING
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT   
--	DEFINE l_where_part STRING 

	DEFINE l_rec_cashreceipt RECORD LIKE cashreceipt.*
	DEFINE l_rec_banking RECORD LIKE banking.*
	DEFINE l_cash_amt DECIMAL(16,4)
	DEFINE l_base_cash_amt DECIMAL(16,4)
	DEFINE l_bank_cash_amt DECIMAL(16,4)	
	DEFINE l_banking_reqd SMALLINT
	DEFINE l_rowid INTEGER
	DEFINE l_err_message CHAR(40)

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"AC6_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT AC6_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	#1002 Searching db - pls wait
--	GOTO bypass 
--	LABEL recovery: 

--	IF error_recover(l_err_message, status) != "Y" THEN 
--		RETURN false 
--	END IF 

--	LABEL bypass: 
--	WHENEVER ERROR GOTO recovery 

	BEGIN WORK 
		IF glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref2_code = "U" THEN 
			# This IS TO avoid running out of locks, especially on
			# a SET-up WHEN there may be lots of undeposited cheques.

			LOCK TABLE cashreceipt in share MODE 
			LOCK TABLE banking in share MODE
			 
			SELECT next_bank_dep_num INTO glob_bank_dep_num FROM arparms 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND parm_code = "1" 
			
			IF glob_bank_dep_num IS NULL 
			OR glob_bank_dep_num = 0 THEN 
				LET glob_bank_dep_num = 1 
			END IF 
			UPDATE arparms 
			SET next_bank_dep_num = glob_bank_dep_num + 1 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND parm_code = "1" 
		END IF 

		LET l_cash_amt = 0 
		LET l_base_cash_amt = 0 
		LET l_banking_reqd = false 
		LET l_query_text = "SELECT rowid, cashreceipt.* FROM cashreceipt ", 
		"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code clipped,"' ", 
		"AND cash_acct_code = '",glob_rec_bank.acct_code,"' ", 
		"AND (banked_flag = 'N' OR banked_flag IS NULL)", 
		"AND (chq_date <= '",today,"' OR chq_date IS NULL) ", 
		"AND ",glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AC6_rpt_list")].sel_text clipped, 
		" ORDER BY cash_num, cmpy_code" 

		PREPARE s_cashreceipt FROM l_query_text 
		DECLARE c_cashreceipt CURSOR FOR s_cashreceipt 
		FOREACH c_cashreceipt INTO l_rowid, l_rec_cashreceipt.* 
			LET l_banking_reqd = true 
			IF l_rec_cashreceipt.conv_qty IS NULL 
			OR l_rec_cashreceipt.conv_qty = 0 THEN 
				LET l_rec_cashreceipt.conv_qty = 1 
			END IF 
			IF l_rec_cashreceipt.cash_amt IS NULL THEN 
				LET l_rec_cashreceipt.cash_amt = 0 
			END IF 
			IF l_rec_cashreceipt.currency_code != glob_rec_bank.currency_code THEN 
				LET l_bank_cash_amt = l_rec_cashreceipt.cash_amt / 
				l_rec_cashreceipt.conv_qty 
			ELSE 
				LET l_bank_cash_amt = l_rec_cashreceipt.cash_amt 
			END IF 
			LET l_cash_amt = l_cash_amt + l_bank_cash_amt 
			LET l_base_cash_amt = l_base_cash_amt + 
			(l_rec_cashreceipt.cash_amt / l_rec_cashreceipt.conv_qty) 
			IF l_rec_cashreceipt.cash_type_ind = 'C' THEN 
				LET l_rec_cashreceipt.next_num = 2 
			ELSE 
				LET l_rec_cashreceipt.next_num = 1 
			END IF 
			LET l_err_message = "AC6 - Updating cashreceipt" 
			IF glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref2_code = "U" THEN 
				UPDATE cashreceipt 
				SET banked_flag = "Y", 
				banked_date = today, 
				bank_dep_num = glob_bank_dep_num 
				WHERE rowid = l_rowid 
			END IF 
			LET l_err_message = "AC6 - Inserting INTO t_cashreceipt" 
			INSERT INTO t_cashreceipt VALUES (l_rec_cashreceipt.*) 
		END FOREACH 

		IF glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref2_code = "U" AND l_banking_reqd THEN 
			INITIALIZE l_rec_banking.* TO NULL 
			LET l_rec_banking.bk_cmpy = glob_rec_kandoouser.cmpy_code 
			LET l_rec_banking.bk_acct = glob_rec_bank.acct_code 
			LET l_rec_banking.bk_type = "CD" 
			LET l_rec_banking.bk_bankdt = today 
			LET l_rec_banking.bk_desc = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref1_text 
			LET l_rec_banking.bk_cred = l_cash_amt 
			LET l_rec_banking.base_cred_amt = l_base_cash_amt 
			LET l_rec_banking.bk_enter = "Bankdeps" 
			LET l_rec_banking.bank_dep_num = glob_bank_dep_num 
			LET l_rec_banking.doc_num = 0 
			LET l_err_message = "AC6 - Inserting banking" 
			INSERT INTO banking VALUES (l_rec_banking.*) 
		END IF 

	COMMIT WORK 

	WHENEVER ERROR stop 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

	IF NOT l_banking_reqd THEN 
		MESSAGE kandoomsg2("A",7501,"") 
		#7501 No Deposits Exist FOR this Bank"
		RETURN false 
	END IF 

	DECLARE c_curs2 CURSOR FOR 
	SELECT * FROM t_cashreceipt 
	ORDER BY next_num, 
	cash_type_ind, 
	bank_text, 
	branch_text 

	FOREACH c_curs2 INTO l_rec_cashreceipt.* 
		#---------------------------------------------------------
		OUTPUT TO REPORT AC6_rpt_list(l_rpt_idx,l_rec_cashreceipt.*)  
		IF NOT rpt_int_flag_handler2("Receipt:",l_rec_cashreceipt.cash_acct_code, l_rec_cashreceipt.cust_code,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------		
	END FOREACH 

	  	
	DELETE FROM t_cashreceipt 

	#------------------------------------------------------------
	FINISH REPORT AC6_rpt_list
	RETURN rpt_finish("AC6_rpt_list")
	#------------------------------------------------------------
	 
END FUNCTION 
#####################################################################
# END FUNCTION AC6_rpt_process(p_where_text) 
#####################################################################


#####################################################################
# REPORT AC6_rpt_list(p_rpt_idx,p_rec_cashreceipt)
#
#
#####################################################################
REPORT AC6_rpt_list(p_rpt_idx,p_rec_cashreceipt) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_cashreceipt RECORD LIKE cashreceipt.* 
	DEFINE l_rec_company RECORD LIKE company.* 
	DEFINE l_cash_amt LIKE cashreceipt.cash_amt 
	DEFINE l_bank_cash_amt DECIMAL(16,4) 
	DEFINE l_first_cheque SMALLINT
	DEFINE l_first_other SMALLINT

	OUTPUT 
--	left margin 0 
--	PAGE length 66 
	ORDER BY p_rec_cashreceipt.next_num,p_rec_cashreceipt.cash_type_ind 
	FORMAT 
		FIRST PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  

			LET l_first_cheque = true 
			LET l_first_other = true 

			PRINT COLUMN 1,"Credit of: ",glob_rec_company.name_text; 
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].ref2_code = "U" THEN 
				PRINT COLUMN 60, "Deposit slip No: ", 
				glob_bank_dep_num USING "<<<<<<<<" 
			ELSE 
				SKIP 1 line 
			END IF 
			PRINT glob_rec_bank.name_acct_text 
			PRINT "Account: ", glob_rec_bank.iban 
			PRINT "Currency: " , glob_rec_bank.currency_code 

			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].ref2_code = "U" THEN 
				PRINT COLUMN 1, "Bank Deposit Listing FOR ", 
				today USING "dd mmm, yyyy" 
			ELSE 
				PRINT COLUMN 1, "Pre Bank Deposit Listing FOR ", 
				today USING "dd mmm, yyyy" 
			END IF 

			SKIP 1 line 

			SELECT sum(cash_amt) INTO l_cash_amt FROM t_cashreceipt 
			WHERE (cash_type_ind = "C" AND cheque_text IS null) 
			OR cash_type_ind = "D" 
			PRINT COLUMN 71, "Cash Total", 
			COLUMN 85, l_cash_amt USING "$---------&.&&" 

			SELECT sum(cash_amt) INTO l_cash_amt FROM t_cashreceipt 
			WHERE (cash_type_ind = "C" AND cheque_text IS NOT null) 
			PRINT COLUMN 71, "Cheque Total", 
			COLUMN 85, l_cash_amt USING "$---------&.&&" 

			SELECT sum(cash_amt) INTO l_cash_amt FROM t_cashreceipt 
			WHERE cash_type_ind != "C" 
			AND cash_type_ind != "D" 
			PRINT COLUMN 71, "Other", 
			COLUMN 85, l_cash_amt USING "$---------&.&&" 
			SKIP 1 line 

			SELECT sum(cash_amt) INTO l_cash_amt FROM t_cashreceipt 
			PRINT COLUMN 71, "GRAND TOTAL", 
			COLUMN 85, l_cash_amt USING "$---------&.&&" 
			SKIP 1 line 

		ON EVERY ROW 
			IF (p_rec_cashreceipt.cash_type_ind = "C" 
			AND p_rec_cashreceipt.cheque_text IS null) 
			OR p_rec_cashreceipt.cash_type_ind = "D" THEN 
			ELSE 
				IF p_rec_cashreceipt.currency_code != glob_rec_bank.currency_code THEN 
					LET l_bank_cash_amt = p_rec_cashreceipt.cash_amt / 
					p_rec_cashreceipt.conv_qty 
				ELSE 
					LET l_bank_cash_amt = p_rec_cashreceipt.cash_amt 
				END IF 
				IF p_rec_cashreceipt.next_num = "2" THEN 
					IF l_first_cheque THEN 
						LET l_first_cheque = false 
						PRINT COLUMN 01, "DRAWER", 
						COLUMN 23, "BANK", 
						COLUMN 42, "BRANCH", 
						COLUMN 63, "NUMBER" 
						SKIP 1 line 
					END IF 
					PRINT COLUMN 01, p_rec_cashreceipt.drawer_text, 
					COLUMN 23, p_rec_cashreceipt.bank_text, 
					COLUMN 42, p_rec_cashreceipt.branch_text clipped, 
					COLUMN 63, p_rec_cashreceipt.cheque_text, 
					COLUMN 85, l_bank_cash_amt USING "----------&.&&" 
				ELSE 
					IF l_first_other THEN 
						LET l_first_other = false 
						SKIP 2 LINES 
						PRINT COLUMN 01, "DRAWER", 
						COLUMN 23, "TYPE", 
						COLUMN 63, "CARD NUMBER" 
						SKIP 1 line 
					END IF 
					PRINT COLUMN 01, p_rec_cashreceipt.drawer_text, 
					COLUMN 23, p_rec_cashreceipt.bank_text, 
					COLUMN 63, p_rec_cashreceipt.branch_text clipped, 
					COLUMN 85, l_bank_cash_amt USING "----------&.&&" 
				END IF 
			END IF 

		ON LAST ROW 
			SKIP 4 LINES 
			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	

END REPORT
#####################################################################
# REPORT AC6_rpt_list(p_rpt_idx,p_rec_cashreceipt)
##################################################################### 