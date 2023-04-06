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
# \brief module G32 - % Based recurring journal disbursement processing
#
#  This program uses local version of journal-interface(jourintf) due TO
#  the dubious nature of winds/jourintf since variable locking installed.
#
#  Multi-Currency Note
#  -------------------
#  The source of all disbursement batches created are GL accounts
#  (closing balance OR period movement).  Since all accounthist are
#  in base currency THEN all disbursement journals are in base currency.
#  The only conversion done IS TO convert base TO REPORT currency if
#  required.  The posting interface handles currency conversion TO
#  minimise the scope of any future change TO disburse the movements
#  of accounthistcurr.
#
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 
GLOBALS "../gl/G32_GLOBALS.4gl" 
############################################################
# MODULE Scope Variables
############################################################
DEFINE modu_rec_period RECORD LIKE period.* 
DEFINE modu_query_text CHAR(600) 
DEFINE modu_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]

############################################################
# FUNCTION G32_main()
#
#
############################################################
FUNCTION G32_main() 

	DEFER quit 
	DEFER interrupt 

	CALL setModuleId("G32") 

	CREATE temp TABLE t_posttemp(
		tran_type_ind CHAR(3), 
		ref_num INTEGER, 
		ref_text CHAR(8), 
		acct_code CHAR(18), 
		desc_text CHAR(40), 
		debit_amt money(10,2), 
		credit_amt money(10,2), 
		curr_code CHAR(3), 
		conv_qty float) with no LOG 

	OPEN WINDOW G461 with FORM "G461" 
	CALL windecoration_g("G461") 

	MENU " Journal Disbursements" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","G32","menu-journal-disbursements") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "UPDATE" 		#COMMAND "UPDATE"		#        " Enter selection criteria AND disburse TO gl journals"
			WHILE select_year() 

				IF db_disbhead_datasource_set_cursor() THEN 
					CALL generate_disb(true) 
					EXIT WHILE 
				END IF 

			END WHILE 

			NEXT option "Print Manager" 

		ON ACTION "Report" 		#COMMAND "Report"		#        " Selection criteria AND PRINT REPORT"
			WHILE select_year() 

				IF db_disbhead_datasource_set_cursor() THEN 
					CALL generate_disb(false) 
					EXIT WHILE 
				END IF 

			END WHILE 

		ON ACTION "Print Manager" 		#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
			CALL run_prog("URS","","","","") 

		ON ACTION "Exit" 		#COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus"
			LET quit_flag = false 
			LET int_flag = false 
			EXIT MENU 

	END MENU 

	CLOSE WINDOW G461 

END FUNCTION 
############################################################
# END FUNCTION G32_main()
############################################################


############################################################
# FUNCTION db_period_get_datasource(p_filter)
#
#
############################################################
FUNCTION db_period_get_datasource(p_filter)
	DEFINE p_filter BOOLEAN
	DEFINE l_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_arr_rec_period DYNAMIC ARRAY OF RECORD 
		scroll_flag CHAR(1), 
		year_num LIKE period.year_num, 
		period_num LIKE period.period_num 
	END RECORD 
		
	DEFINE l_idx SMALLINT 

	IF p_filter THEN
		MESSAGE kandoomsg2("U",1001,"")	#1001 " Selection Criteria "
		CONSTRUCT BY NAME l_where_text ON 
			year_num, 
			period_num 
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","G32","construct-year") 
	
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
	
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
	
		END CONSTRUCT 
		
		IF (int_flag OR quit_flag) THEN
			LET l_where_text = " 1=1 "
		END IF
	ELSE
		LET l_where_text = " 1=1 "
	END IF
		
	MESSAGE kandoomsg2("U",1002,"")	#1002 Searching database "

	LET l_query_text = 
		"SELECT * FROM period ", 
		"WHERE cmpy_code='",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND gl_flag='Y' ", 
		"AND ",l_where_text clipped," ", 
		"ORDER BY 1,2,3" 
		
	PREPARE s_period FROM l_query_text 
	DECLARE c_period CURSOR FOR s_period
			 
	LET l_idx = 0 
	FOREACH c_period INTO modu_rec_period.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_period[l_idx].scroll_flag = NULL 
		LET l_arr_rec_period[l_idx].year_num = modu_rec_period.year_num 
		LET l_arr_rec_period[l_idx].period_num = modu_rec_period.period_num 
		IF l_idx = 200 THEN 
			ERROR kandoomsg2("G",9040,"")		#9040" First 200 fiscal year & periods selected only "
			EXIT FOREACH 
		END IF 
	END FOREACH 
			
	IF l_idx = 0 THEN 
		ERROR kandoomsg2("G",9041,"")	#9041 No Fiscal year & Periods Selected
	END IF

	RETURN l_arr_rec_period
END FUNCTION
############################################################
# END FUNCTION db_period_get_datasource(p_filter)
############################################################


############################################################
# FUNCTION select_year()
#
#
############################################################
FUNCTION select_year() 
	DEFINE l_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_arr_rec_period DYNAMIC ARRAY OF RECORD 
		scroll_flag CHAR(1), 
		year_num LIKE period.year_num, 
		period_num LIKE period.period_num 
	END RECORD 
		
	DEFINE l_idx SMALLINT 

	OPEN WINDOW G462 with FORM "G462" 
	CALL windecoration_g("G462") 

	CALL db_period_get_datasource(FALSE) RETURNING l_arr_rec_period

	IF l_arr_rec_period.getSize() = 0 THEN 
		ERROR kandoomsg2("G",9041,"")	#9041 No Fiscal year & Periods Selected
		LET quit_flag = true 
	ELSE 
		OPTIONS DELETE KEY f36, 
		INSERT KEY f36 
		
		MESSAGE kandoomsg2("G",1024,"") 	#1024 RETURN TO SELECT
		DISPLAY ARRAY l_arr_rec_period TO sr_period.* attributes(UNBUFFERED) 
			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","G32","input-arr-period") 

			BEFORE ROW 
				LET l_idx = arr_curr() 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			ON ACTION "FILTER"
			CALL l_arr_rec_period.clear()
			CALL db_period_get_datasource(TRUE) RETURNING l_arr_rec_period

			ON ACTION "REFRESH"
			CALL windecoration_g("G462")
			CALL l_arr_rec_period.clear()
			CALL db_period_get_datasource(FALSE) RETURNING l_arr_rec_period
	
		END DISPLAY 

	END IF 

	CLOSE WINDOW G462 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		INITIALIZE modu_rec_period.* TO NULL 
		RETURN FALSE 
	ELSE 
		LET modu_rec_period.year_num = l_arr_rec_period[l_idx].year_num 
		LET modu_rec_period.period_num = l_arr_rec_period[l_idx].period_num 
		LET glob_rec_rpt_selector.ref1_num = l_arr_rec_period[l_idx].year_num
		LET glob_rec_rpt_selector.ref2_num = l_arr_rec_period[l_idx].period_num 
		RETURN TRUE
	END IF 
END FUNCTION 
############################################################
# END FUNCTION select_year()
############################################################


############################################################
# FUNCTION db_disbhead_datasource_set_cursor()
#
#
############################################################
FUNCTION db_disbhead_datasource_set_cursor() 
	DEFINE l_where_text STRING --char(400) 

	CLEAR FORM 
	MESSAGE kandoomsg2("G",1001,"")#1001 " Selection Criteria "

	DISPLAY modu_rec_period.year_num TO s_year_num 
	DISPLAY modu_rec_period.period_num TO	s_period_num 

	CONSTRUCT BY NAME l_where_text ON 
		disb_code, 
		desc_text, 
		group_code, 
		jour_code, 
		acct_code, 
		type_ind, 
		dr_cr_ind, #Disburse Credit,Debit or Both
		run_num, 
		last_date, 
		last_jour_num, 
		year_num, 
		period_num, 
		total_qty, 
		disb_qty, 
		uom_code, 
		com1_text 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","G32","construct-disb") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		MESSAGE kandoomsg2("G",1002,"")	#1002 " Selection Criteria
		LET modu_query_text = 
			"SELECT * FROM disbhead ", 
			"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
			"AND disb_qty != 0 ", 
			"AND ",l_where_text clipped," ", 
			"ORDER BY 1,2" 
		PREPARE s_disbhead FROM modu_query_text 
		DECLARE c_disbhead CURSOR with HOLD FOR s_disbhead 
		RETURN true 
	END IF 
END FUNCTION 
############################################################
# END FUNCTION db_disbhead_datasource_set_cursor()
############################################################


############################################################
# FUNCTION generate_disb(p_update_ind)
#
#
############################################################
FUNCTION generate_disb(p_update_ind) 
	DEFINE p_update_ind SMALLINT 
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE l_rec_disbhead RECORD LIKE disbhead.* 
	DEFINE l_rec_disbdetl RECORD LIKE disbdetl.* 
	DEFINE l_rec_accounthist RECORD LIKE accounthist.* 
	DEFINE l_debit_amt LIKE batchdetl.debit_amt 
	DEFINE l_credit_amt LIKE batchdetl.credit_amt 
	DEFINE l_scaling_amt DECIMAL(16,6) 
	DEFINE l_rec_balance_rec RECORD 
		tran_type_ind LIKE batchdetl.tran_type_ind, 
		acct_code LIKE batchdetl.acct_code, 
		desc_text LIKE batchdetl.desc_text, 
		tran_amt LIKE batchdetl.debit_amt, 
		com1_text LIKE disbhead.com1_text 
	END RECORD 
	DEFINE l_err_continue CHAR(1) 
	DEFINE l_err_message CHAR(70) 
	#DEFINE l_rpt_output CHAR(25) 
	DEFINE l_cnt SMALLINT 

	LET l_cnt = 0 
	
	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
--	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
--		LET int_flag = false 
--		LET quit_flag = false
--		RETURN FALSE
--	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"G32_rpt_list","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT G32_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0
	--LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("G32_rpt_list")].sel_text
	#------------------------------------------------------------
	
	#in case of background process
	LET modu_rec_period.year_num = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref1_num 
	LET modu_rec_period.period_num = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref2_num 

	FOREACH c_disbhead INTO l_rec_disbhead.* 
		IF l_rec_disbhead.year_num IS NOT NULL THEN 

			IF l_rec_disbhead.year_num > modu_rec_period.year_num THEN 
				CONTINUE FOREACH 
			END IF 

			IF l_rec_disbhead.year_num = modu_rec_period.year_num THEN 
				IF l_rec_disbhead.period_num >= modu_rec_period.period_num THEN 
					CONTINUE FOREACH 
				END IF 
			END IF 
		END IF 

		SELECT * INTO l_rec_accounthist.* 
		FROM accounthist 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND acct_code = l_rec_disbhead.acct_code 
		AND year_num = modu_rec_period.year_num 
		AND period_num = modu_rec_period.period_num 
		IF status = 0 THEN 
			CASE l_rec_disbhead.type_ind 
				WHEN "1" 
					LET l_scaling_amt = 
					(l_rec_accounthist.open_amt + l_rec_accounthist.debit_amt - l_rec_accounthist.credit_amt) 
				WHEN "2" 
					LET l_scaling_amt = 
					(l_rec_accounthist.debit_amt - l_rec_accounthist.credit_amt) 
				WHEN "3" 
					LET l_scaling_amt = 0 
			END CASE 

			#Disburse Credit,Debit or Both
			IF (l_scaling_amt > 0 AND l_rec_disbhead.dr_cr_ind = DISBURSE_CDB_CREDIT_1) 
			OR (l_scaling_amt < 0 AND l_rec_disbhead.dr_cr_ind = DISBURSE_CDB_DEBIT_2) 
			OR (l_scaling_amt = 0) THEN 
				CONTINUE FOREACH 
			END IF 

			IF l_cnt = 0 THEN 

				IF p_update_ind THEN 
					MESSAGE kandoomsg2("G",1027,"") 
				ELSE 
					MESSAGE kandoomsg2("G",1028,"") #102[78] Process/Reporting Disbursements - Please Wait
				END IF 
			END IF 
			#DISPLAY l_rec_disbhead.disb_code at 1,40 need to put this somewhere 

			LET l_cnt = l_cnt + 1 

			DECLARE c1_disbdetl CURSOR FOR 
			SELECT * FROM disbdetl 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND disb_code = l_rec_disbhead.disb_code 
			ORDER BY 1,2,3 

			FOREACH c1_disbdetl INTO l_rec_disbdetl.* 
				IF l_scaling_amt < 0 THEN 
					LET l_credit_amt = (l_rec_disbdetl.disb_qty*(0 - l_scaling_amt)) / l_rec_disbhead.total_qty 
					LET l_debit_amt = 0 
				ELSE 
					LET l_credit_amt = 0 
					LET l_debit_amt = (l_scaling_amt * l_rec_disbdetl.disb_qty) / l_rec_disbhead.total_qty 
				END IF 

				INSERT INTO t_posttemp VALUES (
					"ADJ",
					0,
					l_rec_disbdetl.disb_code, 
					l_rec_disbdetl.acct_code, 
					l_rec_disbdetl.desc_text, 
					l_debit_amt, 
					l_credit_amt, 
					glob_rec_glparms.base_currency_code, 
					"1") 
			END FOREACH 

			LET l_rec_balance_rec.tran_type_ind = "ADJ" 
			LET l_rec_balance_rec.acct_code = l_rec_disbhead.acct_code 
			LET l_rec_balance_rec.tran_amt = l_scaling_amt 
			LET l_rec_balance_rec.com1_text = l_rec_disbhead.com1_text 

			SELECT desc_text INTO l_rec_balance_rec.desc_text 
			FROM coa 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND acct_code = l_rec_disbhead.acct_code 
			IF status = NOTFOUND THEN 
				LET l_rec_balance_rec.desc_text = "**** Account Not Found ****" 
			END IF 
			
			LET l_rec_disbhead.last_jour_num = cr_journal(
				p_update_ind, 
				l_rec_balance_rec.*, 
				l_rec_disbhead.jour_code) 
			CASE 
				WHEN l_rec_disbhead.last_jour_num < 0 
					LET l_rec_disbhead.last_jour_num = 0 - l_rec_disbhead.last_jour_num 
					DISPLAY l_rec_disbhead.last_jour_num USING "<<<<<<<<" TO lblabel2b 
					ERROR kandoomsg2("G",7013,l_rec_disbhead.last_jour_num)	## invalid/unopen accounts detected in batch 9999

				WHEN l_rec_disbhead.last_jour_num > 0 
					DISPLAY l_rec_disbhead.last_jour_num USING "<<<<<<<<" TO lblabel2b 

				OTHERWISE 
					LET p_update_ind = false 
			END CASE 

			IF p_update_ind THEN 
				UPDATE disbhead 
				SET 
					last_jour_num = l_rec_disbhead.last_jour_num, 
					last_date = today, 
					run_num = run_num + 1, 
					year_num = modu_rec_period.year_num, 
					period_num = modu_rec_period.period_num 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND disb_code = l_rec_disbhead.disb_code 
			END IF 
		END IF 

		DELETE FROM t_posttemp 
	END FOREACH 

	IF l_cnt = 0 THEN 
		ERROR kandoomsg2("G",7014,"") 	#7014 No disbursement journals selected FOR posting."
	END IF 
	
	#------------------------------------------------------------
	FINISH REPORT G32_rpt_list
	CALL rpt_finish("G32_rpt_list")
	#------------------------------------------------------------
 
END FUNCTION 
############################################################
# END FUNCTION generate_disb(p_update_ind)
############################################################


############################################################
# FUNCTION cr_journal(p_update_ind,p_rec_bal_rec,l_jour_code)
#
#
############################################################
FUNCTION cr_journal(p_update_ind,p_rec_bal_rec,l_jour_code) 
	DEFINE p_update_ind SMALLINT ## true=update database, false=report only 
	DEFINE p_rec_bal_rec RECORD ## balancing RECORD entry 
		tran_type_ind LIKE batchdetl.tran_type_ind, 
		acct_code LIKE batchdetl.acct_code, 
		desc_text LIKE batchdetl.desc_text, 
		tran_amt LIKE batchdetl.debit_amt, 
		com1_text LIKE disbhead.com1_text 
	END RECORD 
	DEFINE l_jour_code LIKE batchhead.jour_code 
	DEFINE l_rec_glparms RECORD LIKE glparms.* 
	DEFINE l_rec_batchhead RECORD LIKE batchhead.* 
	DEFINE l_rec_batchdetl RECORD LIKE batchdetl.* 
	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_rec_posttemp RECORD 
		tran_type_ind LIKE batchdetl.tran_type_ind, 
		ref_num LIKE batchdetl.ref_num, 
		ref_text LIKE batchdetl.ref_text, 
		acct_code LIKE batchdetl.acct_code, 
		desc_text LIKE batchdetl.desc_text, 
		debit_amt LIKE batchdetl.debit_amt, 
		credit_amt LIKE batchdetl.credit_amt, 
		curr_code LIKE batchdetl.currency_code, 
		conv_qty LIKE batchdetl.conv_qty, 
		com1_text LIKE disbhead.com1_text 
	END RECORD 
	DEFINE l_err_message CHAR(40) 
	DEFINE l_err_cnt SMALLINT 

	GOTO bypass 
	LABEL recovery: 
	IF error_recover(l_err_message,status) != "Y" THEN 
		RETURN false 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	BEGIN WORK 
		LET l_err_cnt = 0 
		IF p_update_ind THEN 
			LET l_err_message = "G32 - Locking GL Parameters" 

			DECLARE c_glparms CURSOR FOR 
			SELECT * FROM glparms 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND key_code = "1" 
			FOR UPDATE 

			OPEN c_glparms 
			FETCH c_glparms INTO l_rec_glparms.* 

			LET l_err_message = "G32 - Updating GL Parameters" 

			UPDATE glparms 
			SET next_jour_num = next_jour_num + 1 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND key_code = "1" 
		ELSE 
			LET l_rec_glparms.next_jour_num = -1 ## jour_num IS zero 
		END IF 
		
		LET l_rec_batchhead.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET l_rec_batchhead.jour_code = l_jour_code 
		LET l_rec_batchhead.jour_num = l_rec_glparms.next_jour_num + 1 
		LET l_rec_batchhead.entry_code = glob_rec_kandoouser.sign_on_code 
		LET l_rec_batchhead.jour_date = today 
		LET l_rec_batchhead.year_num = modu_rec_period.year_num 
		LET l_rec_batchhead.period_num = modu_rec_period.period_num 
		LET l_rec_batchhead.debit_amt = 0 
		LET l_rec_batchhead.credit_amt = 0 
		LET l_rec_batchhead.for_debit_amt = 0 
		LET l_rec_batchhead.for_credit_amt = 0 
		LET l_rec_batchhead.source_ind = "G" 
		LET l_rec_batchhead.post_flag = "N" 
		LET l_rec_batchhead.seq_num = 0 
		
		IF l_rec_glparms.use_clear_flag = "Y" THEN 
			LET l_rec_batchhead.cleared_flag = "N" 
		ELSE 
			LET l_rec_batchhead.cleared_flag = "Y" 
		END IF 
		
		LET l_rec_batchhead.rate_type_ind = "B" 
		DECLARE c_batchdetl CURSOR FOR 
		SELECT * FROM t_posttemp 
		
		FOREACH c_batchdetl INTO l_rec_posttemp.* 
			LET l_rec_batchhead.currency_code = l_rec_posttemp.curr_code 
			LET l_rec_batchhead.conv_qty = get_conv_rate(
				glob_rec_kandoouser.cmpy_code,
				l_rec_posttemp.curr_code,
				today,
				"F") #WHY "F" ??? S or B  CASH_EXCHANGE_SELL or CASH_EXCHANGE_BUY ????

			LET l_rec_batchhead.seq_num = l_rec_batchhead.seq_num + 1 
			LET l_rec_batchdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET l_rec_batchdetl.jour_code = l_jour_code 
			LET l_rec_batchdetl.jour_num = l_rec_batchhead.jour_num 
			LET l_rec_batchdetl.seq_num = l_rec_batchhead.seq_num 
			LET l_rec_batchdetl.tran_type_ind = l_rec_posttemp.tran_type_ind 
			LET l_rec_batchdetl.tran_date = l_rec_batchhead.jour_date 
			LET l_rec_batchdetl.ref_text = l_rec_posttemp.ref_text 
			LET l_rec_batchdetl.ref_num = l_rec_posttemp.ref_num 
			LET l_rec_batchdetl.acct_code = l_rec_posttemp.acct_code 
			LET l_rec_batchdetl.desc_text = l_rec_posttemp.desc_text 
			LET l_rec_batchdetl.debit_amt = 0 
			LET l_rec_batchdetl.credit_amt = 0 
			LET l_rec_batchdetl.currency_code = l_rec_batchhead.currency_code 
			LET l_rec_batchdetl.conv_qty = l_rec_batchhead.conv_qty 
			LET l_rec_batchdetl.for_debit_amt = 0 
			LET l_rec_batchdetl.for_credit_amt = 0 
			
			CASE 
				WHEN (l_rec_posttemp.debit_amt > 0) 
					LET l_rec_batchdetl.for_debit_amt = l_rec_posttemp.debit_amt 
				WHEN (l_rec_posttemp.debit_amt < 0) 
					LET l_rec_batchdetl.for_credit_amt = 0 - l_rec_posttemp.debit_amt 
				WHEN (l_rec_posttemp.credit_amt > 0) 
					LET l_rec_batchdetl.for_credit_amt = l_rec_posttemp.credit_amt 
				WHEN (l_rec_posttemp.credit_amt < 0) 
					LET l_rec_batchdetl.for_debit_amt = 0 - l_rec_posttemp.credit_amt 
			END CASE 
			
			#----------------------------------
			# now convert the account currency
			LET l_rec_batchdetl.debit_amt = l_rec_batchdetl.for_debit_amt	/ l_rec_batchhead.conv_qty 
			LET l_rec_batchdetl.credit_amt = l_rec_batchdetl.for_credit_amt	/ l_rec_batchhead.conv_qty 
			
			#----------------------------------
			SELECT * INTO l_rec_coa.* 
			FROM coa 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND acct_code = l_rec_batchdetl.acct_code 
			
			IF status = NOTFOUND THEN 
				LET l_err_cnt = l_err_cnt + 1 
			ELSE 
				IF l_rec_coa.end_year_num < l_rec_batchhead.year_num 
				OR l_rec_coa.start_year_num > l_rec_batchhead.year_num 
				OR (l_rec_coa.end_year_num = l_rec_batchhead.year_num 
				AND	l_rec_coa.end_period_num < l_rec_batchhead.period_num) 
				OR (l_rec_coa.start_year_num = l_rec_batchhead.year_num 
				AND l_rec_coa.start_period_num > l_rec_batchhead.period_num) THEN 
					
					LET l_err_cnt = l_err_cnt + 1 
				END IF
				 
			END IF 
			#-------------------------------------
			# increment the batch header
			LET l_rec_batchhead.for_debit_amt = l_rec_batchhead.for_debit_amt	+ l_rec_batchdetl.for_debit_amt 
			LET l_rec_batchhead.for_credit_amt = l_rec_batchhead.for_credit_amt	+ l_rec_batchdetl.for_credit_amt
			 
			IF p_update_ind THEN 
				INSERT INTO batchdetl VALUES (l_rec_batchdetl.*) 
			ELSE 
				INSERT INTO t_batchdetl VALUES (l_rec_batchdetl.*, glob_rec_kandoouser.sign_on_code) 
			END IF
			 
		END FOREACH 
		
		IF l_rec_batchhead.seq_num > 0 THEN 
			IF l_rec_batchhead.for_debit_amt > 0 THEN 
				IF p_rec_bal_rec.tran_amt != l_rec_batchhead.for_debit_amt THEN 
					
					#---------------------------------------------------
					# Rounding error has occurred during disbursement
					IF p_update_ind THEN 
						UPDATE batchdetl 
						SET for_debit_amt = 
						for_debit_amt 
						+ p_rec_bal_rec.tran_amt 
						- l_rec_batchhead.for_debit_amt, 
						
						debit_amt = 
						(for_debit_amt 
						+ p_rec_bal_rec.tran_amt 
						- l_rec_batchhead.for_debit_amt)
						/conv_qty 
						
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND jour_num = l_rec_batchhead.jour_num 
						AND seq_num = l_rec_batchhead.seq_num 
					ELSE 
						UPDATE t_batchdetl 
						SET for_debit_amt = for_debit_amt 
						+ p_rec_bal_rec.tran_amt 
						- l_rec_batchhead.for_debit_amt,
						 
						debit_amt = 
						(for_debit_amt 
						+ p_rec_bal_rec.tran_amt 
						- l_rec_batchhead.for_debit_amt)/conv_qty 
						WHERE seq_num = l_rec_batchhead.seq_num
						 
					END IF 
					LET l_rec_batchhead.for_debit_amt = p_rec_bal_rec.tran_amt 
				END IF 
			ELSE 
				IF p_rec_bal_rec.tran_amt != l_rec_batchhead.for_credit_amt THEN 
					
					#-----------------------------------------------------
					# Rounding error has occurred during disbursement
					IF p_update_ind THEN 
						UPDATE batchdetl 
						SET for_credit_amt = 
						for_credit_amt 
						+ p_rec_bal_rec.tran_amt 
						- l_rec_batchhead.for_credit_amt,
						 
						credit_amt = for_credit_amt/conv_qty 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND jour_num = l_rec_batchhead.jour_num 
						AND seq_num = l_rec_batchhead.seq_num 
					ELSE 
						UPDATE t_batchdetl 
						SET for_credit_amt = 
						for_credit_amt 
						+ p_rec_bal_rec.tran_amt 
						- l_rec_batchhead.for_credit_amt,
						 
						credit_amt = for_credit_amt/conv_qty 
						WHERE seq_num = l_rec_batchhead.seq_num 
					END IF 
					LET l_rec_batchhead.for_credit_amt = p_rec_bal_rec.tran_amt 
				END IF 
			END IF 
			
			LET l_rec_batchhead.seq_num = l_rec_batchhead.seq_num + 1 
			LET l_rec_batchdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET l_rec_batchdetl.jour_code = l_jour_code 
			LET l_rec_batchdetl.jour_num = l_rec_batchhead.jour_num 
			LET l_rec_batchdetl.ref_text = " " 
			LET l_rec_batchdetl.ref_num = 0 
			LET l_rec_batchdetl.seq_num = l_rec_batchhead.seq_num 
			LET l_rec_batchdetl.tran_type_ind = p_rec_bal_rec.tran_type_ind 
			LET l_rec_batchdetl.acct_code = p_rec_bal_rec.acct_code 
			LET l_rec_batchdetl.desc_text = p_rec_bal_rec.desc_text 
			
			IF l_rec_batchhead.for_debit_amt > l_rec_batchhead.for_credit_amt THEN 
				LET l_rec_batchdetl.for_credit_amt = l_rec_batchhead.for_debit_amt - l_rec_batchhead.for_credit_amt 
				LET l_rec_batchdetl.for_debit_amt = 0 
			ELSE 
				LET l_rec_batchdetl.for_credit_amt = 0 
				LET l_rec_batchdetl.for_debit_amt = l_rec_batchhead.for_credit_amt - l_rec_batchhead.for_debit_amt 
			END IF 
			
			LET l_rec_batchdetl.debit_amt = l_rec_batchdetl.for_debit_amt	/ l_rec_batchhead.conv_qty 
			LET l_rec_batchdetl.credit_amt = l_rec_batchdetl.for_credit_amt	/ l_rec_batchhead.conv_qty 
			
			#-------------------------------------
			# Finalise batchhead
			LET l_rec_batchhead.for_debit_amt = l_rec_batchhead.for_debit_amt	+ l_rec_batchdetl.for_debit_amt 
			LET l_rec_batchhead.for_credit_amt = l_rec_batchhead.for_credit_amt	+ l_rec_batchdetl.for_credit_amt 
			LET l_rec_batchhead.control_amt = l_rec_batchhead.debit_amt 
			LET l_rec_batchhead.debit_amt = l_rec_batchhead.for_debit_amt / l_rec_batchhead.conv_qty 
			LET l_rec_batchhead.credit_amt = l_rec_batchhead.for_credit_amt	/ l_rec_batchhead.conv_qty 
			
			#----------------------------------------------
			IF l_rec_batchhead.credit_amt != l_rec_batchhead.debit_amt THEN 
				#--------------------------------------
				# Rounding error in currency conversion
				IF l_rec_batchhead.credit_amt > l_rec_batchhead.debit_amt THEN 
					LET l_rec_batchdetl.debit_amt = 
					l_rec_batchdetl.debit_amt 
					+ l_rec_batchhead.credit_amt 
					- l_rec_batchhead.debit_amt 
					LET l_rec_batchhead.debit_amt = l_rec_batchhead.credit_amt 
				ELSE 
					LET l_rec_batchdetl.credit_amt = 
					l_rec_batchdetl.credit_amt 
					- l_rec_batchhead.credit_amt 
					+ l_rec_batchhead.debit_amt 
					LET l_rec_batchhead.credit_amt = l_rec_batchhead.debit_amt 
				END IF 
			END IF
			 
			LET l_rec_batchhead.com1_text = p_rec_bal_rec.com1_text[01,40] 
			LET l_rec_batchhead.com2_text = p_rec_bal_rec.com1_text[41,80] 
			
			IF p_update_ind THEN 
				INSERT INTO batchdetl VALUES (l_rec_batchdetl.*) 
				CALL fgl_winmessage("10 Learning batch head codes - tell Hubert",l_rec_batchhead.source_ind,"info") 
				INSERT INTO batchhead VALUES (l_rec_batchhead.*) 
			ELSE 
				INSERT INTO t_batchdetl VALUES (l_rec_batchdetl.*, glob_rec_kandoouser.sign_on_code) 
			END IF 
		END IF 

	COMMIT WORK 

	WHENEVER ERROR stop 
	IF p_update_ind THEN 
		LET modu_query_text = 
			"SELECT * FROM batchdetl ", 
			"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
			"AND jour_num = '",l_rec_batchhead.jour_num,"' ", 
			"ORDER BY 1,2,3" 
	ELSE 
		LET modu_query_text = "SELECT * FROM t_batchdetl " 
	END IF 

	PREPARE s_batchdetl FROM modu_query_text 
	DECLARE c1_batchdetl CURSOR FOR s_batchdetl 

	FOREACH c1_batchdetl INTO l_rec_batchdetl.* 
		#---------------------------------------------------------
		OUTPUT TO REPORT GR1_rpt_list(modu_rpt_idx,l_rec_batchhead.*,l_rec_batchdetl.*) 
		#---------------------------------------------------------	
	END FOREACH 
	
	DELETE FROM t_batchdetl 
	WHERE username = glob_rec_kandoouser.sign_on_code 

	IF l_err_cnt > 0 THEN 
		RETURN(0 - l_rec_batchhead.jour_num) 
	ELSE 
		RETURN(l_rec_batchhead.jour_num) 
	END IF 
END FUNCTION 
############################################################
# END FUNCTION cr_journal(p_update_ind,p_rec_bal_rec,l_jour_code)
############################################################


############################################################
# REPORT G32_rpt_list(p_rpt_idx,p_rec_batchhead,p_rec_batchdetl)
#
#
############################################################
REPORT G32_rpt_list(p_rpt_idx,p_rec_batchhead,p_rec_batchdetl) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_batchdetl RECORD LIKE batchdetl.* 
	DEFINE p_rec_batchhead RECORD LIKE batchhead.* 
	DEFINE l_arr_line array[4] OF CHAR(132) 

	OUTPUT 
--	PAGE length 66 
--	left margin 0 
	ORDER external BY 
		p_rec_batchdetl.jour_num, 
		p_rec_batchdetl.tran_type_ind, 
		p_rec_batchdetl.seq_num 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text #line1_text
			PRINT COLUMN 02, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text #line1_text

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
		
			PRINT COLUMN 01,l_arr_line[3] 

			IF p_rec_batchhead.jour_num > 0 THEN 
				PRINT COLUMN 01, "Batch Number: ",p_rec_batchhead.jour_num USING "<<<<<<<<" 
			ELSE 
				SKIP 1 line 
			END IF 

			PRINT COLUMN 01, "Disbursement: ",p_rec_batchdetl.ref_text, 

			COLUMN 25, "Posting Year: ",p_rec_batchhead.year_num USING "####", 
			COLUMN 48, "Source: ",p_rec_batchhead.source_ind, 
			COLUMN 69, "Base Currency : ",glob_rec_glparms.base_currency_code, 
			COLUMN 98, "Batch Currency : ",p_rec_batchhead.currency_code 

			PRINT COLUMN 02, "Date: ", p_rec_batchhead.jour_date, 
			COLUMN 31, "Period: ",p_rec_batchhead.period_num USING "<<<", 
			COLUMN 48, "FROM : ",p_rec_batchhead.entry_code 

			PRINT COLUMN 29, "Comments:", 
			COLUMN 39, p_rec_batchhead.com1_text 
			PRINT COLUMN 39, p_rec_batchhead.com2_text 

		BEFORE GROUP OF p_rec_batchdetl.jour_num 
			SKIP TO top OF PAGE 

		ON EVERY ROW 
			SELECT * FROM coa 
			WHERE cmpy_code = p_rec_batchdetl.cmpy_code 
			AND acct_code = p_rec_batchdetl.acct_code 

			IF status = NOTFOUND THEN 
				LET p_rec_batchdetl.desc_text = "**** Account Not Found ****" 
			ELSE 
				SELECT * FROM coa 
				WHERE cmpy_code = p_rec_batchdetl.cmpy_code 
				AND acct_code = p_rec_batchdetl.acct_code 
				AND end_year_num >= p_rec_batchhead.year_num 
				AND start_year_num <= p_rec_batchhead.year_num 
				AND (end_period_num >= p_rec_batchhead.period_num 
				OR end_year_num > p_rec_batchhead.year_num) 
				AND (start_period_num <= p_rec_batchhead.period_num 
				OR start_year_num < p_rec_batchhead.year_num) 
				IF status = NOTFOUND THEN 
					LET p_rec_batchdetl.desc_text = "**** Account Not Open ****" 
				END IF 
			END IF 

			PRINT COLUMN 1, p_rec_batchdetl.seq_num USING "####", 
			COLUMN 6 , p_rec_batchdetl.tran_type_ind, 
			COLUMN 11, p_rec_batchdetl.acct_code , 
			COLUMN 30, p_rec_batchdetl.desc_text, 
			COLUMN 60, p_rec_batchdetl.debit_amt USING "-----------&.&&", 
			COLUMN 75, p_rec_batchdetl.credit_amt USING "-----------&.&&", 
			COLUMN 90, p_rec_batchdetl.for_debit_amt USING "-----------&.&&", 
			COLUMN 105,p_rec_batchdetl.for_credit_amt USING "-----------&.&&", 
			COLUMN 121,p_rec_batchdetl.conv_qty USING "---&.&&&" 

		AFTER GROUP OF p_rec_batchdetl.jour_num 
			PRINT COLUMN 60, "---------------", 
			COLUMN 75, "---------------", 
			COLUMN 90, " --------------", 
			COLUMN 105,"---------------" 
			PRINT COLUMN 10, "Batch Totals :", 

			COLUMN 60, GROUP sum(p_rec_batchdetl.debit_amt)	USING "-----------&.&&", 
			COLUMN 75, GROUP sum(p_rec_batchdetl.credit_amt)USING "-----------&.&&", 
			COLUMN 90, GROUP sum(p_rec_batchdetl.for_debit_amt)	USING "-----------&.&&", 
			COLUMN 105,group sum(p_rec_batchdetl.for_credit_amt)	USING "-----------&.&&" 

		ON LAST ROW 
			SKIP 2 LINES 
			PRINT COLUMN 60, "===============", 
			COLUMN 75, "===============", 
			COLUMN 90, " ==============", 
			COLUMN 105,"===============" 
			PRINT COLUMN 10, "Report Totals :", 
			COLUMN 60, sum(p_rec_batchdetl.debit_amt) USING "-----------&.&&", 
			COLUMN 75, sum(p_rec_batchdetl.credit_amt) USING "-----------&.&&", 
			COLUMN 90, sum(p_rec_batchdetl.for_debit_amt) USING "-----------&.&&", 
			COLUMN 105,sum(p_rec_batchdetl.for_credit_amt) USING "-----------&.&&" 
			SKIP 1 line 
			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 

END REPORT
############################################################
# END REPORT G32_rpt_list(p_rpt_idx,p_rec_batchhead,p_rec_batchdetl)
############################################################