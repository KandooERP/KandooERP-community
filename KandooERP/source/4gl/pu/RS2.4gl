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
GLOBALS "../pu/R_PU_GLOBALS.4gl" 
GLOBALS "../common/postfunc_GLOBALS.4gl" 
# Purpose : Purchasing Posting Process
#
##############################################################################
#
# RS2 Version II posts FROM the poaudit table up TO the General
# Ledger, lets look AT the postings FOR each type of poaudit
# transaction AND each type of Purchasing General Ledger Posting.
#
# Note the posting flag IS on the poaudit table.
#
#                                                  Post Steps
#    Poaudit types are  AA- Initial Line               - a
#                       AL- Add Line (Later)           - a
#                       CE- Closing                    - b
#                       CQ- Change Quantity            - a
#                       CP- Change Price               - a
#                       GA- Goods Receipt Adjustment   - b
#                       GR- Goods Receipt              - b
#                       VO- Voucher Entry              - c
#
#
#    Note 1 the system supports any combination of the
#           following on a purchase ORDER BY purchase ORDER
#           basis
#
#    Note 2 all the control accounts are SET up in RZP
#           which sets up the table puparms
#
#    Note 3 the purchdetl holds the acct_code FOR the expense
#
#    The types of purchase ORDER posting are
#
#    1. Commitment Accounting Method
#       This IS used FOR importers etc, etc.
#
#    a  WHEN PO IS raised OR editted
#         Goods on Order                dr
#         Commitment Account            cr
#
#
#    b  WHEN Goods Receipt occurs                 ***
#         Expense Account               dr
#         Goods on Order                cr
#
#
#    c  WHEN Voucher IS entered
#         Commitment Account            dr
#         Clearing Account              cr
#
#
#    2. Accrual Accounting Method
#
#    a  WHEN PO IS raised OR editted
#       nothing IS posted.
#
#
#    b  WHEN Goods Receipt occurs                 ***
#         Expense Account               dr
#         Accrued Expenses              cr
#
#
#    c  WHEN Voucher IS entered
#         Accrued Expenses              dr
#         Clearing Account              cr
#
#
#    3. Expense Accounting Method
#
#    a  WHEN PO IS raised OR editted
#       nothing IS posted.
#
#
#    b  WHEN Goods Receipt occurs
#       nothing IS posted.
#
#
#    c  WHEN Voucher IS entered                  ***
#         Expense Account               dr
#         Clearing Account              cr
#
#
#       *** = Detail IS posted OTHERWISE summary
#
GLOBALS 
	DEFINE 
	pr_sl_id LIKE kandoouser.sign_on_code, 
	pr_data RECORD 
		tran_type_ind LIKE batchdetl.tran_type_ind, 
		ref_num LIKE batchdetl.ref_num, 
		ref_text LIKE batchdetl.ref_text, 
		acct_code LIKE batchdetl.acct_code, 
		desc_text LIKE batchdetl.desc_text, 
		for_debit_amt LIKE batchdetl.for_debit_amt, 
		for_credit_amt LIKE batchdetl.for_credit_amt, 
		base_debit_amt LIKE batchdetl.debit_amt, 
		base_credit_amt LIKE batchdetl.credit_amt, 
		currency_code LIKE batchdetl.currency_code, 
		conv_qty LIKE batchdetl.conv_qty, 
		tran_date DATE, 
		stats_qty LIKE batchdetl.stats_qty 
	END RECORD, 
	bal_rec RECORD 
		tran_type_ind LIKE batchdetl.tran_type_ind, 
		acct_code LIKE batchdetl.acct_code, 
		desc_text LIKE batchdetl.desc_text 
	END RECORD, 
	pa_period array[300] OF RECORD 
		year_num LIKE period.year_num, 
		period_num LIKE period.period_num, 
		post_req CHAR(1) 
	END RECORD, 
	pr_puparms RECORD LIKE puparms.*, 
	pr_smparms RECORD LIKE smparms.*, 
	pr_period RECORD LIKE period.*, 
	pr_purchhead RECORD LIKE purchhead.*, 
	pr_purchdetl RECORD LIKE purchdetl.*, 
	pr_poaudit RECORD LIKE poaudit.*, 
	pr_journal RECORD LIKE journal.*, 
	pr_rec_kandoouser RECORD LIKE kandoouser.*, 
	doit CHAR(1), 
	sel_text, where_part, sel_stmt CHAR(900) 
	DEFINE l_all_ok INTEGER
	DEFINE l_its_ok INTEGER 
	DEFINE rpt_wid SMALLINT, 
--	pr_output CHAR(60), 
	try_again CHAR(1), 
	err_message CHAR(80), 
	temp_description CHAR(80), 
	#glob_fisc_year SMALLINT,
	scrn SMALLINT, 
	i SMALLINT, 
	idx SMALLINT, 
	fisc_per SMALLINT, 
	counter SMALLINT, 

	tmp_poststatus RECORD LIKE poststatus.*, 
	stat_code LIKE poststatus.status_code, 
	ans CHAR(1), 
	#glob_in_trans SMALLINT,
	posting_needed SMALLINT, 
	post_status LIKE poststatus.status_code, 
	#glob_posted_journal LIKE batchhead.jour_num,
	#glob_post_text CHAR(80),
	#glob_err_text CHAR(80),
	inserted_some SMALLINT, 
	pr_glparms RECORD LIKE glparms.*, 
	#glob_glob_one_trans SMALLINT,
	#    glob_st_code SMALLINT,
	again SMALLINT, 
	select_text CHAR(1200), 
	pr_salestax_acct_code LIKE apparms.salestax_acct_code, 
	set_retry SMALLINT 

END GLOBALS 
############################################################
# MODULE Scope Variables
############################################################
DEFINE modu_rpt_idx SMALLINT
#######################################################################
# MAIN
#
#
#######################################################################
MAIN 
	CALL setModuleId("RS2") -- albo 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_r_pu() #init r/pu purchase ORDER module 

	CALL startlog(get_settings_logPath_forFile("postlog.PU")) 

	SELECT * 
	INTO glob_rec_poststatus.* 
	FROM poststatus 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND module_code = "PU" 

	IF status THEN 
		ERROR kandoomsg2("U",3507,"") 		#3507 Status cannot be found;  Cannot post;  ABORTING.
		EXIT program 
	ELSE 
		LET post_status = glob_rec_poststatus.status_code 
		IF glob_rec_poststatus.post_running_flag = "Y" THEN 
			ERROR kandoomsg2("U",3508,"") 			#3508 Post IS already running;  Cannot run.
			SLEEP 2 
			EXIT program 
		END IF 
		IF post_status < 99 THEN 
			ERROR kandoomsg2("U",3509,"") 			#3509 Error Has Occurred In Previous Post - Automatic Rollback ...
			SLEEP 2 
			CALL disp_poststatus("PU") 
		END IF 
	END IF 


	# SET glob_rec_kandoouser.sign_on_code TO PU so GL knows WHERE it came FROM

	LET pr_sl_id = "PU" 
	LET l_its_ok = 0 
	LET l_all_ok = true 

	SELECT * 
	INTO pr_puparms.* 
	FROM puparms 
	WHERE key_code = "1" 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF status = notfound THEN 
		ERROR kandoomsg2("P",5018,"") #5018 Purchasing Parameters Not Set Up;  Refer Menu RZP.
		CALL fgl_winmessage("#5018 Purchasing Parameters Not Set Up",kandoomsg2("P",5018,""),"ERROR")
		EXIT program 
	END IF 

	SELECT * 
	INTO pr_glparms.* 
	FROM glparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND key_code = "1" 
	IF status = notfound THEN 
		ERROR kandoomsg2("P",5007,"") 	# 5007 General Ledger Parameters Not Set Up;  Refer Menu GZP.
		CALL fgl_winmessage("#5007 General Ledger Parameters Not Set Up",kandoomsg2("P",5007,""),"ERROR")
		EXIT program 
	END IF 

	INITIALIZE pr_smparms.* TO NULL 
	SELECT * INTO pr_smparms.* FROM smparms 
	WHERE key_num = "1" 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET rpt_wid = 132 

	CREATE temp TABLE posttemp 
	( tran_type_ind CHAR(3), 
	ref_num INTEGER, 
	ref_text CHAR(8), 
	acct_code CHAR(18), 
	desc_text CHAR(40), 
	for_debit_amt money(14,2), 
	for_credit_amt money(14,2), 
	base_debit_amt money(12,2), 
	base_credit_amt money(12,2), 
	currency_code CHAR(3), 
	conv_qty FLOAT, 
	tran_date DATE, 

	stats_qty DECIMAL(15,3)) 

	CREATE temp TABLE posterrors 
	( 
	textline CHAR(80) 
	) with no LOG 

	OPEN WINDOW wr150 with FORM "R150" 
	CALL  windecoration_r("R150") 


	UPDATE poststatus SET post_running_flag = "Y" 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND module_code = "PU" 

	WHILE (true) 
		IF get_info() THEN 
			EXIT WHILE 
		END IF 
	END WHILE 

	UPDATE poststatus SET post_running_flag = "N" 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND module_code = "PU" 

	CLOSE WINDOW wr150 
END MAIN 



FUNCTION get_info() 

	DEFINE 
	pr_year_num LIKE period.year_num, 
	tmp_year LIKE period.year_num, 
	tmp_period LIKE period.period_num, 
	tmp_text CHAR(10), 
	again SMALLINT 


	MESSAGE kandoomsg2("U",1503,"") #1503 Enter Selection Criteria;  OK TO Continue.
	CLEAR FORM 
	CONSTRUCT BY NAME where_part ON 
		year_num, 
		period_num 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","RS2","construct-year_period-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
			
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	LET sel_text = 
		"SELECT unique year_num, ", 
		" period_num ", 
		"FROM period ", 
		"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
		"AND ",where_part clipped, 
		"ORDER BY year_num, period_num " 

	IF int_flag OR quit_flag THEN 
		UPDATE poststatus SET post_running_flag = "N" 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND module_code = "PU" 
		EXIT program 
	END IF 

	PREPARE getper FROM sel_text 
	DECLARE c_per CURSOR FOR getper 

	LET idx = 0 
	FOREACH c_per INTO 
		pr_period.year_num, 
		pr_period.period_num
		 
		LET idx = idx + 1 
		LET pa_period[idx].year_num = pr_period.year_num 
		LET pa_period[idx].post_req = " " 
		LET pa_period[idx].period_num = pr_period.period_num 
		
		IF idx > 300 THEN 
			LET idx = 300 
			ERROR kandoomsg2("U",6001,idx)		#6001 First 300 selected records selected only.  More may be ...
			EXIT FOREACH 
		END IF 
	END FOREACH
	 
	CALL set_count(idx) 
	MESSAGE kandoomsg2("U",3526,"") #3526 Press ENTER on line TO post;  F10 TO check.
	LET again = false 
	
	OPTIONS INSERT KEY f36, 
	DELETE KEY f36
	 
	INPUT ARRAY pa_period WITHOUT DEFAULTS FROM sr_period.* ATTRIBUTE(UNBUFFERED) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","RS2","inp-arr-period-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			DISPLAY pa_period[idx].* TO sr_period[scrn].* 

		AFTER ROW 
			DISPLAY pa_period[idx].* TO sr_period[scrn].* 

		ON KEY (F10) 
			ERROR kandoomsg2("R",1507,"")			#1507 Checking posting periods;  Please wait.
			FOR i=1 TO arr_count() 
				LET pa_period[i].post_req = "N" 
				# check FOR each transaction type in conjunction with the purchase
				# ORDER type - see above FOR posting combinations
				SELECT count(*) 
				INTO counter 
				FROM poaudit, purchhead 
				WHERE poaudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND poaudit.year_num = pa_period[i].year_num 
				AND poaudit.period_num = pa_period[i].period_num 
				AND poaudit.posted_flag = "N" 
				AND poaudit.tran_code = "VO" 
				AND poaudit.cmpy_code = purchhead.cmpy_code 
				AND poaudit.po_num = purchhead.order_num 
				AND purchhead.type_ind in ("1","2","3")
				 
				IF counter > 0 THEN 
					LET pa_period[i].post_req = "Y" 
				ELSE 
					SELECT count(*) 
					INTO counter 
					FROM poaudit, purchhead 
					WHERE poaudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND poaudit.year_num = pa_period[i].year_num 
					AND poaudit.period_num = pa_period[i].period_num 
					AND poaudit.posted_flag = "N" 
					AND poaudit.cmpy_code = purchhead.cmpy_code 
					AND poaudit.po_num = purchhead.order_num 
					AND purchhead.type_ind in ("1", "2") 
					AND poaudit.tran_code in ("GA", "GR", "CE") 
				
					IF counter > 0 THEN 
						LET pa_period[i].post_req = "Y" 
					ELSE 
						SELECT count(*) 
						INTO counter 
						FROM poaudit, purchhead 
						WHERE poaudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND poaudit.year_num = pa_period[i].year_num 
						AND poaudit.period_num = pa_period[i].period_num 
						AND poaudit.posted_flag = "N" 
						AND poaudit.cmpy_code = purchhead.cmpy_code 
						AND poaudit.po_num = purchhead.order_num 
						AND purchhead.type_ind = "1" 
						AND poaudit.tran_code in ("AA", "AL", "CQ", "CP") 
				
						IF counter > 0 THEN 
							LET pa_period[i].post_req = "Y" 
						ELSE 

							LET posting_needed = 0 
							SELECT count(*) 
							INTO posting_needed 
							FROM postpoaudit 
							WHERE postpoaudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND postpoaudit.period_num = pa_period[i].period_num 
							AND postpoaudit.year_num = pa_period[i].year_num 
							IF posting_needed THEN 
								LET pa_period[i].post_req = "Y" 
							END IF 

						END IF 
					END IF 
				END IF 

				IF i <= 12 THEN 
					DISPLAY pa_period[i].* TO sr_period[i].* 
				END IF 
			END FOR 
			
			MESSAGE kandoomsg2("U",3526,"")		#3526 Press ENTER on line TO post;  F10 TO check.

		BEFORE FIELD year_num 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			LET pr_year_num = pa_period[idx].year_num 

		AFTER FIELD year_num 
			LET pa_period[idx].year_num = pr_year_num 
			IF arr_curr() >= arr_count() 
			AND (fgl_lastkey() = fgl_keyval("down") 
			OR fgl_lastkey() = fgl_keyval("right")) THEN 
				MESSAGE kandoomsg2("U",9001,"") 	#9001 There are no more rows in the direction you are going.
				NEXT FIELD year_num 
			END IF 
			
		BEFORE FIELD period_num 
			LET fisc_per = pa_period[idx].period_num 
			LET glob_fisc_year = pa_period[idx].year_num 

			IF post_status < 99 THEN 
				SELECT post_year_num,post_period_num 
				INTO tmp_year,tmp_period 
				FROM poststatus 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND module_code = "PU" 
				IF tmp_year != glob_fisc_year OR tmp_period != fisc_per THEN 
					LET tmp_text = tmp_year USING "####"," ", 
					tmp_period USING "###" 
					
					MESSAGE kandoomsg2("U",3516,tmp_text) # 3516 "You must post ",tmp_year," ",tmp_period 
					SLEEP 2 
					LET again = true 
					EXIT INPUT 
				END IF 
			END IF 

			CALL post_pu() 

			NEXT FIELD year_num 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET quit_flag = false 
		LET int_flag = false 
	END IF 

	IF again THEN 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 

END FUNCTION 



FUNCTION convert_post_amts() 

	CALL get_conv_rate(glob_rec_kandoouser.cmpy_code, 
	pr_data.currency_code, 
	pr_data.tran_date, 
	CASH_EXCHANGE_BUY) 
	RETURNING pr_data.conv_qty 

	LET pr_data.base_debit_amt = pr_data.for_debit_amt / pr_data.conv_qty 
	LET pr_data.base_credit_amt = pr_data.for_credit_amt / pr_data.conv_qty 

	# IF use currency flag IS "N" use only the base VALUES
	IF pr_glparms.use_currency_flag = "N" THEN 
		LET pr_data.for_debit_amt = pr_data.base_debit_amt 
		LET pr_data.for_credit_amt = pr_data.base_credit_amt 
		LET pr_data.currency_code = pr_glparms.base_currency_code 
		LET pr_data.conv_qty = 1 
	END IF 
END FUNCTION 



FUNCTION create_gl_batches(pr_journal_code, posting_type) 

	DEFINE 
	pr_journal_code LIKE journal.jour_code, 
	pr_currency_code LIKE currency.currency_code, 
	posting_type CHAR(2) 

	DISPLAY "" at 1,2 

	DECLARE curr_curs CURSOR with HOLD FOR 
	SELECT unique currency_code 
	INTO pr_currency_code 
	FROM posttemp 

	FOREACH curr_curs 
		# send debit first for_debit-amt > 0
		LET sel_stmt = 
			" SELECT *", 
			" FROM posttemp ", 
			" WHERE posttemp.currency_code = \"", 
			pr_currency_code, "\"", 
			" AND posttemp.for_debit_amt > 0"
		 
		LET l_its_ok = jourintf2(
			modu_rpt_idx,
			sel_stmt,		 
--		pr_sl_id, 
			bal_rec.*, 
			fisc_per, 
			glob_fisc_year, 
			pr_journal_code, 
			"R", 
			pr_currency_code, 
			"PU") 

		IF l_its_ok = 0 THEN {nothing posted} 
			ERROR kandoomsg2("U",3500,bal_rec.tran_type_ind)		# 3500 "No entries FOR type ",bal_rec.tran_type_ind," posted."
		END IF 

		IF l_its_ok < 0 THEN 
			LET l_all_ok = false 
			LET l_its_ok = 0 - l_its_ok 
		END IF 





		# flag the posted transactions with the journal number
		CALL flag_them(posting_type, pr_currency_code, "DR") 

		IF glob_posted_journal IS NOT NULL THEN 
			LET glob_posted_journal = NULL 
		END IF 

		# send credits second for_debit_amt < 0
		LET 
			sel_stmt = " SELECT *", 
			" FROM posttemp ", 
			" WHERE posttemp.currency_code = \"", 
			pr_currency_code, "\"", 
			" AND for_debit_amt < 0 " 
		LET l_its_ok = jourintf2(
			modu_rpt_idx,
			sel_stmt, 
--		glob_rec_kandoouser.cmpy_code, 
--		pr_sl_id, 
			bal_rec.*, 
			fisc_per, 
			glob_fisc_year, 
			pr_journal_code, 
			"R", 
			pr_currency_code, 
--		pr_output, 
			"PU") 

		IF l_its_ok = 0 THEN {nothing posted} 
			ERROR kandoomsg2("U",3500,bal_rec.tran_type_ind) # 3500 "No entries FOR type ",bal_rec.tran_type_ind," posted."
		END IF 
		IF l_its_ok < 0 THEN 
			LET l_all_ok = false 
			LET l_its_ok = 0 - l_its_ok 
		END IF 





		# flag the posted transactions with the journal number
		CALL flag_them(posting_type, pr_currency_code, TRAN_TYPE_CREDIT_CR) 

		IF glob_posted_journal IS NOT NULL THEN 
			LET glob_posted_journal = NULL 
		END IF 

	END FOREACH 

	DELETE FROM posttemp WHERE 1=1 

END FUNCTION 



FUNCTION purch_post(posting_type) 

	DEFINE 
	posting_type CHAR(2) 

	GOTO bypass 
	LABEL recovery: 
	CALL update_poststatus(TRUE,STATUS,"PU") 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 

	# now post the commitment journal across
	# FOR type 1 purchase orders, i.e. commitment accounting method
	# note these are done in summary form
	# but with the jour num passed back


	LET bal_rec.tran_type_ind = "PO" 
	LET bal_rec.acct_code = pr_puparms.commit_acct_code 
	LET bal_rec.desc_text = " C1 Commitment A/C Summary" 

	IF post_status = 2 THEN 
		IF glob_rec_poststatus.jour_num IS NULL THEN 
			LET glob_rec_poststatus.jour_num = 0 
		END IF 
		LET select_text = 
			"SELECT sum(P.line_total_amt), ", 
			" P.tran_date, ", 
			" purchhead.curr_code ", 
			"FROM postpoaudit P, purchhead ", 
			"WHERE P.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
			"AND P.period_num = ",fisc_per," ", 
			"AND P.year_num = ",glob_fisc_year," ", 
			"AND P.posted_flag = \"N\" ", 
			"AND P.tran_code in ", 
			" (\"AA\", \"AL\", \"CQ\", \"CP\") ", 
			"AND purchhead.cmpy_code = P.cmpy_code ", 
			"AND purchhead.order_num = P.po_num ", 
	
			"AND purchhead.type_ind = \"1\" ", 
			"AND (P.jour_num = ",glob_rec_poststatus.jour_num," OR ", 
			" P.jour_num IS NULL OR ", 
			" P.jour_num = 0) ", 
			"group by P.tran_date, purchhead.curr_code " 
	ELSE 
		LET select_text = 
			"SELECT sum(P.line_total_amt), ", 
			" P.tran_date, ", 
			" purchhead.curr_code ", 
			"FROM postpoaudit P, purchhead ", 
			"WHERE P.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
			"AND P.period_num = ",fisc_per," ", 
			"AND P.year_num = ",glob_fisc_year," ", 
			"AND P.posted_flag = \"N\" ", 
			"AND P.tran_code in ", 
			" (\"AA\", \"AL\", \"CQ\", \"CP\") ", 
			"AND purchhead.cmpy_code = P.cmpy_code ", 
			"AND purchhead.order_num = P.po_num ", 
	
			"AND purchhead.type_ind = \"1\" ", 
			"group by P.tran_date, purchhead.curr_code " 
	END IF 

	LET pr_data.tran_type_ind = "PO" 
	LET pr_data.ref_num = 0 
	LET pr_data.ref_text = "Summary" 
	LET pr_data.acct_code = pr_puparms.goodsin_acct_code 
	LET pr_data.for_credit_amt = 0 
	LET inserted_some = false 

	PREPARE sel_purch FROM select_text 
	DECLARE po_head_curs CURSOR FOR sel_purch 

	LET glob_err_text = "FOREACH INTO posttemp - purchases" 
	FOREACH po_head_curs INTO 
		pr_data.for_debit_amt, 
		pr_data.tran_date, 
		pr_data.currency_code 

		CALL convert_post_amts() 
		LET pr_data.desc_text ="PO Goods On Order-Curr: ",pr_data.currency_code 

		LET inserted_some = true 
		INSERT INTO posttemp VALUES (pr_data.*) 
	END FOREACH 

	IF NOT inserted_some THEN 
		RETURN 
	END IF 

	CALL create_gl_batches(pr_puparms.commit_jour_code, posting_type) 

END FUNCTION 



FUNCTION receipt_post(post_type) 

	DEFINE 
	pr_type_ind LIKE purchhead.type_ind, 
	post_type CHAR(2), 
	gr_num LIKE poaudit.tran_num, 
	pr_purch_type_ind LIKE purchhead.type_ind, 
	post_journal_code LIKE journal.jour_code, 
	pr_tt, pr_drcr CHAR(50) 

	GOTO bypass 
	LABEL recovery: 
	CALL update_poststatus(TRUE,STATUS,"PU") 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 

	# Set up posting data AND selection criteria according TO the type
	# of transaction TO be posted
	CASE 
		WHEN post_type = "G1" 
			LET bal_rec.tran_type_ind = "GR" 
			LET bal_rec.desc_text = " G1 Goods Receipt Balancing Entry " 
			LET bal_rec.acct_code = pr_puparms.goodsin_acct_code 
			LET pr_purch_type_ind = "1" 
			LET pr_tt = " AND P.tran_code in (\"GA\", \"GR\") " 
			LET pr_drcr = " P.line_total_amt, 0, " 
		WHEN post_type = "G2" 
			LET err_message = " G2 Goods Receipt posting " 
			LET bal_rec.tran_type_ind = "GR" 
			LET bal_rec.desc_text = " G2 Goods Receipt Balancing Entry " 
			LET bal_rec.acct_code = pr_puparms.accrued_acct_code 
			LET pr_purch_type_ind = "2" 
			LET pr_tt = " AND P.tran_code in (\"GA\", \"GR\") " 
			LET pr_drcr = " P.line_total_amt, 0, " 
		WHEN post_type = "L1" 
			LET err_message = " CE Goods Receipt posting " 
			LET bal_rec.tran_type_ind = "GR" 
			LET bal_rec.acct_code = pr_puparms.commit_acct_code 
			LET bal_rec.desc_text = "L1 Reconciliation Balancing Entry " 
			LET pr_purch_type_ind = "1" 
			LET pr_tt = " AND P.tran_code in (\"CE\") " 
			LET pr_drcr = " P.line_total_amt*-1, 0, " 
		WHEN post_type = "L2" 
			LET err_message = " CE Goods Receipt posting " 
			LET bal_rec.tran_type_ind = "GR" 
			LET bal_rec.acct_code = pr_puparms.accrued_acct_code 
			LET bal_rec.desc_text = "L2 Reconciliation Balancing Entry " 
			LET pr_purch_type_ind = "2" 
			LET pr_tt = " AND P.tran_code in (\"CE\") " 
			LET pr_drcr = " P.line_total_amt*-1, 0, " 
	END CASE 

	# Now post the goods receipt journal across
	IF post_status = 4 
	OR post_status = 5 
	OR post_status = 6 
	OR post_status = 7 THEN 
		IF glob_rec_poststatus.jour_num IS NULL THEN 
			LET glob_rec_poststatus.jour_num = 0 
		END IF 
		LET select_text = 
			"SELECT P.tran_code, ", 
			" P.po_num, ", 
			" P.vend_code, ", 
			" purchdetl.acct_code, ", 
			" P.desc_text, ", 
			pr_drcr, 
			#"       P.line_total_amt, ",
			#"       0, ",
			" 0, ", 
			" 0, ", 
			" purchhead.curr_code, ", 
			" 0, ", 
			" P.tran_date, ", 
			" 0, ", 
			" P.tran_num ", 
			"FROM postpoaudit P, purchdetl, purchhead ", 
			"WHERE P.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
			"AND P.posted_flag = \"N\" ", 
			"AND P.period_num = ",fisc_per," ", 
			"AND P.year_num = ",glob_fisc_year," ", 
			pr_tt clipped , 
			" AND P.line_total_amt != 0 ", 
			"AND P.cmpy_code = purchhead.cmpy_code ", 
			"AND P.po_num = purchhead.order_num ", 
	
			"AND purchhead.type_ind = \"", 
			pr_purch_type_ind,"\" ", 
			"AND purchdetl.cmpy_code = P.cmpy_code ", 
			"AND purchdetl.order_num = P.po_num ", 
	
			"AND P.line_num = purchdetl.line_num ", 
			"AND (P.jour_num = ",glob_rec_poststatus.jour_num," OR ", 
			" P.jour_num IS NULL OR ", 
			" P.jour_num = 0) " 
	ELSE 
		LET select_text = 
			"SELECT P.tran_code, ", 
			" P.po_num, ", 
			" P.vend_code, ", 
			" purchdetl.acct_code, ", 
			" P.desc_text, ", 
			pr_drcr, 
			#"       P.line_total_amt, ",
			#"       0, ",
			" 0, ", 
			" 0, ", 
			" purchhead.curr_code, ", 
			" 0, ", 
			" P.tran_date, ", 
			" 0, ", 
			" P.tran_num ", 
			"FROM postpoaudit P, purchdetl, purchhead ", 
			"WHERE P.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
			"AND P.posted_flag = \"N\" ", 
			"AND P.period_num = ",fisc_per," ", 
			"AND P.year_num = ",glob_fisc_year," ", 
			pr_tt clipped, 
			" AND P.line_total_amt != 0 ", 
			"AND P.cmpy_code = purchhead.cmpy_code ", 
			"AND P.po_num = purchhead.order_num ", 
	
			"AND purchhead.type_ind = \"", 
			pr_purch_type_ind,"\" ", 
			"AND purchdetl.cmpy_code = P.cmpy_code ", 
			"AND purchdetl.order_num = P.po_num ", 
	
			"AND P.line_num = purchdetl.line_num " 
	END IF 

	LET inserted_some = false 

	PREPARE sel_gr FROM select_text 
	DECLARE po_gr_curs CURSOR FOR sel_gr 

	LET glob_err_text = "FOREACH INTO posttemp - Goods receipt" 
	FOREACH po_gr_curs INTO pr_data.*,gr_num 
		CALL convert_post_amts() 
		# IF the receipt came through Landed Costing, RECORD the
		# value INTO Goods-in-transit, NOT the purchase account.
		# The purchase ORDER only represents the FOB cost of the
		# goods. The TRUE value of the goods IS calculated by
		# Shipment Finalise.  Note that we need the text "Ship#"
		# FROM the poaudit.desc_text TO recognise this.
		#IF pr_data.desc_text[1,5] = "Ship#" THEN
		#LET pr_data.acct_code = pr_smparms.git_acct_code
		#END IF
		IF post_type = "L1" 
		OR post_type = "L2" THEN 
			LET temp_description = pr_data.desc_text 
		ELSE 
			LET temp_description = gr_num USING "########", " ", 
			pr_data.desc_text 
		END IF 
		LET pr_data.desc_text = temp_description 
		LET inserted_some = true 

		INSERT INTO posttemp VALUES (pr_data.*) 

	END FOREACH 

	IF NOT inserted_some THEN 
		RETURN 
	END IF 

	CALL create_gl_batches(pr_puparms.receipt_jour_code, post_type) 

END FUNCTION 



FUNCTION summ_vouch_post(post_type) 

	DEFINE 
	post_type CHAR(2), 
	pr_purch_type_ind LIKE purchhead.type_ind 

	GOTO bypass 
	LABEL recovery: 
	CALL update_poststatus(TRUE,STATUS,"PU") 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 

	# Set up the posting data AND selection criteria according TO the type
	# of transaction TO be posted
	CASE 
		WHEN post_type = "V1" 
			LET bal_rec.tran_type_ind = "VP" 
			LET bal_rec.desc_text = " PO Voucher Clearing P.O. Type 1 " 
			LET bal_rec.acct_code = pr_puparms.clear_acct_code 
			LET pr_purch_type_ind = "1" 
			LET pr_data.tran_type_ind = "VP" 
			LET pr_data.ref_num = 0 
			LET pr_data.ref_text = "Summary" 
			LET pr_data.acct_code = pr_puparms.commit_acct_code 
			LET pr_data.for_credit_amt = 0 
			LET pr_data.tran_date = today 
		WHEN post_type = "V2" 
			LET bal_rec.tran_type_ind = "VP" 
			LET bal_rec.desc_text = " PO Voucher Clearing P.O. Type 2 " 
			LET bal_rec.acct_code = pr_puparms.clear_acct_code 
			LET pr_purch_type_ind = "2" 
			LET pr_data.tran_type_ind = "PO" 
			LET pr_data.ref_num = 0 
			LET pr_data.ref_text = "Summary" 
			LET pr_data.acct_code = pr_puparms.accrued_acct_code 
			LET pr_data.for_credit_amt = 0 
			LET pr_data.tran_date = today 
	END CASE 

	# Now post the vouchers journal across
	DECLARE po_vos_curs CURSOR FOR 
	SELECT sum(P.line_total_amt), 
	p.tran_date, 
	purchhead.curr_code 
	FROM purchhead, postpoaudit p 
	WHERE p.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND p.year_num = glob_fisc_year 
	AND p.period_num = fisc_per 
	AND p.posted_flag = "N" 
	AND p.tran_code = "VO" 
	AND purchhead.cmpy_code = p.cmpy_code 
	AND purchhead.order_num = p.po_num 

	AND purchhead.type_ind = pr_purch_type_ind 
	GROUP BY p.tran_date, purchhead.curr_code 

	LET glob_err_text = "FOREACH INTO postemp - V1/V2" 
	LET inserted_some = false 
	FOREACH po_vos_curs INTO pr_data.for_debit_amt, 
		pr_data.tran_date, 
		pr_data.currency_code 
		CALL convert_post_amts() 
		LET pr_data.desc_text = "PO VO Type ", pr_purch_type_ind clipped, 
		" - Curr: ", pr_data.currency_code 
		LET inserted_some = true 
		INSERT INTO posttemp VALUES (pr_data.*) 
	END FOREACH 

	IF NOT inserted_some THEN 
		RETURN 
	END IF 

	CALL create_gl_batches(pr_puparms.purch_jour_code, post_type) 

END FUNCTION 



FUNCTION vouch_post(post_type) 

	DEFINE 
	post_type CHAR(2) 

	GOTO bypass 
	LABEL recovery: 
	CALL update_poststatus(TRUE,STATUS,"PU") 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 

	LET bal_rec.tran_type_ind = "VP" 
	LET bal_rec.desc_text = " PO Voucher Clearing Type 3 " 
	LET bal_rec.acct_code = pr_puparms.clear_acct_code 

	DECLARE po_vod_curs CURSOR FOR 
	SELECT "VP", 
	p.po_num, 
	p.vend_code, 
	purchdetl.acct_code, 
	purchdetl.desc_text, 
	p.line_total_amt, 
	0, 
	0, 
	0, 
	purchhead.curr_code, 
	0, 
	p.tran_date, 
	0 
	FROM postpoaudit p, purchdetl, purchhead 
	WHERE p.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND p.year_num = glob_fisc_year 
	AND p.period_num = fisc_per 
	AND p.posted_flag = "N" 
	AND p.tran_code = "VO" 
	AND p.line_total_amt != 0 
	AND p.cmpy_code = purchhead.cmpy_code 
	AND p.po_num = purchhead.order_num 

	AND purchhead.type_ind = "3" 
	AND purchdetl.cmpy_code = p.cmpy_code 
	AND purchdetl.order_num = p.po_num 

	AND purchdetl.line_num = p.line_num 

	LET glob_err_text = "FOREACH INTO postemp - V3" 
	LET inserted_some = false 
	FOREACH po_vod_curs INTO pr_data.* 
		CALL convert_post_amts() 
		LET inserted_some = true 
		INSERT INTO posttemp VALUES (pr_data.*) 
	END FOREACH 

	IF NOT inserted_some THEN 
		RETURN 
	END IF 

	CALL create_gl_batches(pr_puparms.purch_jour_code, post_type) 

END FUNCTION 



FUNCTION do_tax() 

	DEFINE 
	pr_currency_code LIKE currency.currency_code 

	GOTO bypass 
	LABEL recovery: 
	CALL update_poststatus(TRUE,STATUS,"PU") 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 

	# This IS a TEMPORARY SOLUTION TO taxation within purchase orders.
	# note that currently only type '3' purchase orders will have the
	# taxation content posted.

	LET glob_err_text = "FUNCTION do_tax" 

	# balancing RECORD entry FOR tax on V3 vouchers
	LET bal_rec.tran_type_ind = "VP" 
	LET bal_rec.desc_text = " PO Voucher Clearing Type 3 " 
	LET bal_rec.acct_code = pr_puparms.clear_acct_code 

	SELECT salestax_acct_code 
	INTO pr_salestax_acct_code 
	FROM apparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parm_code = "1" 

	LET sel_stmt = " SELECT ","\"",bal_rec.tran_type_ind clipped,"\", ", 
	" P.po_num, ", 
	" P.vend_code, ", 
	" \"",pr_salestax_acct_code,"\", ", 
	" purchdetl.desc_text, ", 
	" P.ext_tax_amt, ", # foreign debit 
	" 0, ", # foreign credit 
	" 0, ", # base debit 
	" 0, ", # base credit 
	" purchhead.curr_code, ", # currency_code 
	" 0, ", # exchange rate 
	" P.tran_date, ", # transaction DATE 
	" 0 ", # stats qty 
	" FROM postpoaudit P, purchdetl, purchhead", 
	" WHERE P.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	" AND P.posted_flag = \"T\" ", 
	" AND P.tran_code = \"VO\" ", 
	" AND P.period_num = ",fisc_per," ", 
	" AND P.year_num = ",glob_fisc_year," ", 
	" AND purchdetl.cmpy_code = P.cmpy_code ", 
	" AND purchdetl.order_num = P.po_num ", 

	" AND purchdetl.line_num = P.line_num ", 
	" AND P.cmpy_code = purchhead.cmpy_code ", 

	" AND P.po_num = purchhead.order_num ", 
	" AND P.line_num = purchdetl.line_num ", 
	" AND purchhead.type_ind = \"3\" " 

	PREPARE check_sel2 FROM sel_stmt 
	DECLARE check_curs2 CURSOR FOR check_sel2 

	OPEN check_curs2 
	FETCH check_curs2 
	IF status THEN 
		RETURN 
	END IF 
	CLOSE check_curs2 

	# note that the FUNCTION convert_post_amts assigns the exchange rate
	# AND base debit AND credit amounts.

	LET glob_err_text = "FOREACH INTO posttemp - Tax" 
	FOREACH check_curs2 INTO pr_data.* 
		CALL convert_post_amts() 
		INSERT INTO posttemp VALUES (pr_data.*) 
	END FOREACH 

	DECLARE curr_curs1 CURSOR with HOLD FOR 
	SELECT unique currency_code 
	INTO pr_currency_code 
	FROM posttemp 

	FOREACH curr_curs1 
		LET sel_stmt = " SELECT *", 
		" FROM posttemp ", 
		# first send debits only
		" WHERE posttemp.currency_code = \"", 
		pr_currency_code, "\"", 
		" AND posttemp.for_debit_amt > 0" 


		LET l_its_ok = jourintf2(modu_rpt_idx,
		sel_stmt, 
		--glob_rec_kandoouser.cmpy_code, 
		--pr_sl_id, 
		bal_rec.*, 
		fisc_per, 
		glob_fisc_year, 
		pr_puparms.purch_jour_code, 
		"R", 
		pr_currency_code, 
		--pr_output, 
		"PU") 

		IF l_its_ok = 0 THEN {nothing posted} 
			ERROR kandoomsg2("U",3500,bal_rec.tran_type_ind) 		# 3500 "No entries FOR type ",bal_rec.tran_type_ind," posted."
		END IF 

		IF l_its_ok < 0 THEN 
			LET l_all_ok = 0 
			LET l_its_ok = 0 - l_its_ok 
		END IF 

		# second send credits only
		LET sel_stmt = " SELECT *", 
		" FROM posttemp ", 
		" WHERE posttemp.currency_code = \"", 
		pr_currency_code, "\"", 
		" AND posttemp.for_debit_amt < 0" 

		LET l_its_ok = jourintf2(modu_rpt_idx,
		sel_stmt, 
		--glob_rec_kandoouser.cmpy_code, 
		--pr_sl_id, 
		bal_rec.*, 
		fisc_per, 
		glob_fisc_year, 
		pr_puparms.purch_jour_code, 
		"R", 
		pr_currency_code, 
		--pr_output, 
		"PU") 

		IF l_its_ok = 0 THEN {nothing posted} 
			ERROR kandoomsg2("U",3500,bal_rec.tran_type_ind) 		# 3500 "No entries FOR type ",bal_rec.tran_type_ind," posted."
		END IF 

		IF l_its_ok < 0 THEN 
			LET l_all_ok = 0 
			LET l_its_ok = 0 - l_its_ok 
		END IF 
	END FOREACH 

	DELETE FROM posttemp WHERE 1=1 

END FUNCTION 



FUNCTION flag_them(flag_ind, pr_currency_code,pr_ind) 

	DEFINE 
	pr_ind, flag_ind CHAR(2), 
	pr_currency_code LIKE currency.currency_code, 
	row_id INTEGER 

	GOTO bypass 
	LABEL recovery: 
	CALL update_poststatus(TRUE,STATUS,"PU") 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 

	LET glob_err_text = "FUNCTION flag_them" 

	CASE 
		WHEN flag_ind = "C1" # commitment 
			LET err_message = " C1 poaudit UPDATE" 
			IF l_its_ok <> 0 THEN 
				DECLARE po_comm_curs CURSOR FOR 
				SELECT p.rowid 
				INTO row_id 
				FROM postpoaudit p, purchhead 
				WHERE p.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND p.period_num = fisc_per 
				AND p.year_num = glob_fisc_year 
				AND p.posted_flag = "N" 
				AND p.tran_code in ("AA", "AL", "CQ", "CP") 
				AND purchhead.cmpy_code = p.cmpy_code 
				AND purchhead.order_num = p.po_num 

				AND purchhead.type_ind = "1" 
				AND purchhead.curr_code = pr_currency_code 
				FOREACH po_comm_curs 
					UPDATE postpoaudit SET posted_flag = "Y", 
					jour_num = l_its_ok 
					WHERE rowid = row_id 
				END FOREACH 
			END IF 
			# now do the commitment transactions that do NOT post
		WHEN flag_ind = "CM" 
			LET err_message = " other poaudit UPDATE" 
			UPDATE postpoaudit SET posted_flag = "Y", 
			jour_num = 0 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND posted_flag = "N" 
			AND period_num = fisc_per 
			AND year_num = glob_fisc_year 
			AND tran_code in ("AA", "AL", "CQ", "CP") 

		WHEN flag_ind = "G2" # goods receipt 
			IF pr_ind = TRAN_TYPE_CREDIT_CR THEN 
				DECLARE po_rec2_curs CURSOR FOR 
				SELECT p.rowid 
				INTO row_id 
				FROM postpoaudit p, purchhead 
				WHERE p.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND p.posted_flag = "N" 
				AND p.tran_code in ("GA","GR") 
				AND p.period_num = fisc_per 
				AND p.year_num = glob_fisc_year 
				AND p.cmpy_code = purchhead.cmpy_code 
				AND p.po_num = purchhead.order_num 

				AND p.received_qty < 0 
				AND purchhead.type_ind = "2" 
				AND purchhead.curr_code = pr_currency_code 
				FOREACH po_rec2_curs 
					LET err_message = " G2 poaudit UPDATE" 
					UPDATE postpoaudit SET posted_flag = "Y", 
					jour_num = l_its_ok 
					WHERE rowid = row_id 
				END FOREACH 
			ELSE 
				DECLARE po_rec2_cur2 CURSOR FOR 
				SELECT p.rowid 
				INTO row_id 
				FROM postpoaudit p, purchhead 
				WHERE p.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND p.posted_flag = "N" 
				AND p.tran_code in ("GA","GR") 
				AND p.period_num = fisc_per 
				AND p.year_num = glob_fisc_year 
				AND p.cmpy_code = purchhead.cmpy_code 
				AND p.po_num = purchhead.order_num 

				AND p.received_qty >= 0 
				AND purchhead.type_ind = "2" 
				AND purchhead.curr_code = pr_currency_code 
				FOREACH po_rec2_cur2 
					LET err_message = " G2 poaudit UPDATE" 
					UPDATE postpoaudit SET posted_flag = "Y", 
					jour_num = l_its_ok 
					WHERE rowid = row_id 
				END FOREACH 
			END IF 

		WHEN flag_ind = "G1" # goods receipt 
			IF pr_ind = TRAN_TYPE_CREDIT_CR THEN 
				DECLARE po_rec1_curs CURSOR FOR 
				SELECT p.rowid 
				INTO row_id 
				FROM postpoaudit p, purchhead 
				WHERE p.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND p.posted_flag = "N" 
				AND p.tran_code in ("GA","GR") 
				AND p.period_num = fisc_per 
				AND p.year_num = glob_fisc_year 
				AND p.cmpy_code = purchhead.cmpy_code 
				AND p.po_num = purchhead.order_num 

				AND p.received_qty < 0 
				AND purchhead.type_ind = "1" 
				AND purchhead.curr_code = pr_currency_code 
				FOREACH po_rec1_curs 
					LET err_message = " G1 poaudit UPDATE" 
					UPDATE postpoaudit SET posted_flag = "Y", 
					jour_num = l_its_ok 
					WHERE rowid = row_id 
				END FOREACH 
			ELSE 
				DECLARE po_rec1_cur2 CURSOR FOR 
				SELECT p.rowid 
				INTO row_id 
				FROM postpoaudit p, purchhead 
				WHERE p.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND p.posted_flag = "N" 
				AND p.tran_code in ("GA","GR") 
				AND p.period_num = fisc_per 
				AND p.year_num = glob_fisc_year 
				AND p.cmpy_code = purchhead.cmpy_code 
				AND p.po_num = purchhead.order_num 

				AND p.received_qty >= 0 
				AND purchhead.type_ind = "1" 
				AND purchhead.curr_code = pr_currency_code 
				FOREACH po_rec1_cur2 
					LET err_message = " G1 poaudit UPDATE" 
					UPDATE postpoaudit SET posted_flag = "Y", 
					jour_num = l_its_ok 
					WHERE rowid = row_id 
				END FOREACH 
			END IF 

		WHEN flag_ind = "L1" # purchase ORDER closing FOR type 1 orders 
			IF pr_ind = TRAN_TYPE_CREDIT_CR THEN 
				DECLARE po_rec3_curs CURSOR FOR 
				SELECT p.rowid 
				INTO row_id 
				FROM postpoaudit p, purchhead 
				WHERE p.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND p.posted_flag = "N" 
				AND p.tran_code in ("CE") 
				AND p.period_num = fisc_per 
				AND p.year_num = glob_fisc_year 
				AND p.cmpy_code = purchhead.cmpy_code 
				AND p.po_num = purchhead.order_num 

				AND p.received_qty < 0 
				AND purchhead.type_ind = "1" 
				AND purchhead.curr_code = pr_currency_code 
				FOREACH po_rec3_curs 
					LET err_message = " CE poaudit UPDATE" 
					UPDATE postpoaudit SET posted_flag = "Y", 
					jour_num = l_its_ok 
					WHERE rowid = row_id 
				END FOREACH 
			ELSE 
				DECLARE po_rec3_cur2 CURSOR FOR 
				SELECT p.rowid 
				INTO row_id 
				FROM postpoaudit p, purchhead 
				WHERE p.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND p.posted_flag = "N" 
				AND p.tran_code in ("CE") 
				AND p.period_num = fisc_per 
				AND p.year_num = glob_fisc_year 
				AND p.cmpy_code = purchhead.cmpy_code 
				AND p.po_num = purchhead.order_num 

				AND p.received_qty >= 0 
				AND purchhead.type_ind = "1" 
				AND purchhead.curr_code = pr_currency_code 
				FOREACH po_rec3_cur2 
					LET err_message = " CE poaudit UPDATE" 
					UPDATE postpoaudit SET posted_flag = "Y", 
					jour_num = l_its_ok 
					WHERE rowid = row_id 
				END FOREACH 
			END IF 

		WHEN flag_ind = "L2" # purchase ORDER closing FOR type 2 orders 
			IF pr_ind = TRAN_TYPE_CREDIT_CR THEN 
				DECLARE po_recl2_curs CURSOR FOR 
				SELECT p.rowid 
				INTO row_id 
				FROM postpoaudit p, purchhead 
				WHERE p.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND p.posted_flag = "N" 
				AND p.tran_code in ("CE") 
				AND p.period_num = fisc_per 
				AND p.year_num = glob_fisc_year 
				AND p.cmpy_code = purchhead.cmpy_code 
				AND p.po_num = purchhead.order_num 

				AND p.received_qty < 0 
				AND purchhead.type_ind = "2" 
				AND purchhead.curr_code = pr_currency_code 
				FOREACH po_recl2_curs 
					LET err_message = " CE poaudit UPDATE" 
					UPDATE postpoaudit SET posted_flag = "Y", 
					jour_num = l_its_ok 
					WHERE rowid = row_id 
				END FOREACH 
			ELSE 
				DECLARE po_recl2_cur2 CURSOR FOR 
				SELECT p.rowid 
				INTO row_id 
				FROM postpoaudit p, purchhead 
				WHERE p.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND p.posted_flag = "N" 
				AND p.tran_code in ("CE") 
				AND p.period_num = fisc_per 
				AND p.year_num = glob_fisc_year 
				AND p.cmpy_code = purchhead.cmpy_code 
				AND p.po_num = purchhead.order_num 

				AND p.received_qty >= 0 
				AND purchhead.type_ind = "2" 
				AND purchhead.curr_code = pr_currency_code 
				FOREACH po_recl2_cur2 
					LET err_message = " CE poaudit UPDATE" 
					UPDATE postpoaudit SET posted_flag = "Y", 
					jour_num = l_its_ok 
					WHERE rowid = row_id 
				END FOREACH 
			END IF 


		WHEN flag_ind = "G3" # the dont post type OF gr 
			LET err_message = " G3 poaudit UPDATE" 
			UPDATE postpoaudit SET posted_flag = "Y", 
			jour_num = 0 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND posted_flag = "N" 
			AND tran_code in ("GA","GR") 
			AND period_num = fisc_per 
			AND year_num = glob_fisc_year 

		WHEN flag_ind = "V1" # voucher type 1 
			IF pr_ind = TRAN_TYPE_CREDIT_CR THEN 
				DECLARE po_vou1_curs CURSOR FOR 
				SELECT p.rowid 
				INTO row_id 
				FROM postpoaudit p, purchhead 
				WHERE p.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND p.period_num = fisc_per 
				AND p.year_num = glob_fisc_year 
				AND p.posted_flag = "N" 
				AND p.tran_code in ("VO") 
				AND p.voucher_qty < 0 
				AND purchhead.cmpy_code = p.cmpy_code 
				AND purchhead.order_num = p.po_num 

				AND purchhead.type_ind = "1" 
				AND purchhead.curr_code = pr_currency_code 
				FOREACH po_vou1_curs 
					LET err_message = " V1 poaudit UPDATE" 
					UPDATE postpoaudit SET posted_flag = "Y", 
					jour_num = l_its_ok 
					WHERE rowid = row_id 
				END FOREACH 
			ELSE 
				DECLARE po_vou1_cur2 CURSOR FOR 
				SELECT p.rowid 
				INTO row_id 
				FROM postpoaudit p, purchhead 
				WHERE p.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND p.period_num = fisc_per 
				AND p.year_num = glob_fisc_year 
				AND p.posted_flag = "N" 
				AND p.tran_code in ("VO") 
				AND p.voucher_qty >= 0 
				AND purchhead.cmpy_code = p.cmpy_code 
				AND purchhead.order_num = p.po_num 

				AND purchhead.type_ind = "1" 
				AND purchhead.curr_code = pr_currency_code 
				FOREACH po_vou1_cur2 
					LET err_message = " V1 poaudit UPDATE" 
					UPDATE postpoaudit SET posted_flag = "Y", 
					jour_num = l_its_ok 
					WHERE rowid = row_id 
				END FOREACH 
			END IF 

		WHEN flag_ind = "V2" # voucher type 2 
			IF pr_ind = TRAN_TYPE_CREDIT_CR THEN 
				DECLARE po_vou2_curs CURSOR FOR 
				SELECT p.rowid 
				INTO row_id 
				FROM postpoaudit p, purchhead 
				WHERE p.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND p.period_num = fisc_per 
				AND p.year_num = glob_fisc_year 
				AND p.posted_flag = "N" 
				AND p.tran_code in ("VO") 
				AND p.voucher_qty < 0 
				AND purchhead.cmpy_code = p.cmpy_code 
				AND purchhead.order_num = p.po_num 

				AND purchhead.type_ind = "2" 
				AND purchhead.curr_code = pr_currency_code 
				FOREACH po_vou2_curs 
					LET err_message = " V2 poaudit UPDATE" 
					UPDATE postpoaudit SET posted_flag = "Y", 
					jour_num = l_its_ok 
					WHERE rowid = row_id 
				END FOREACH 
			ELSE 
				DECLARE po_vou2_cur2 CURSOR FOR 
				SELECT p.rowid 
				INTO row_id 
				FROM postpoaudit p, purchhead 
				WHERE p.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND p.period_num = fisc_per 
				AND p.year_num = glob_fisc_year 
				AND p.posted_flag = "N" 
				AND p.tran_code in ("VO") 
				AND p.voucher_qty >= 0 
				AND purchhead.cmpy_code = p.cmpy_code 
				AND purchhead.order_num = p.po_num 

				AND purchhead.type_ind = "2" 
				AND purchhead.curr_code = pr_currency_code 
				FOREACH po_vou2_cur2 
					LET err_message = " V2 poaudit UPDATE" 
					UPDATE postpoaudit SET posted_flag = "Y", 
					jour_num = l_its_ok 
					WHERE rowid = row_id 
				END FOREACH 
			END IF 

		WHEN flag_ind = "V3" # voucher type 3 
			IF pr_ind = TRAN_TYPE_CREDIT_CR THEN 
				DECLARE po_vou3_curs CURSOR FOR 
				SELECT p.rowid 
				INTO row_id 
				FROM postpoaudit p, purchhead 
				WHERE p.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND p.period_num = fisc_per 
				AND p.year_num = glob_fisc_year 
				AND p.posted_flag = "N" 
				AND p.tran_code = "VO" 
				AND p.voucher_qty < 0 
				AND p.cmpy_code = purchhead.cmpy_code 
				AND p.po_num = purchhead.order_num 

				AND purchhead.type_ind = "3" 
				AND purchhead.curr_code = pr_currency_code 
				FOREACH po_vou3_curs 
					LET err_message = " V3 poaudit UPDATE" 
					# flag SET TO 'T' FOR tax processing temporary
					# fix FOR type 3 purchase orders only.
					UPDATE postpoaudit SET posted_flag = "T", 
					jour_num = l_its_ok 
					WHERE rowid = row_id 
				END FOREACH 
			ELSE 
				DECLARE po_vou3_cur2 CURSOR FOR 
				SELECT p.rowid 
				INTO row_id 
				FROM postpoaudit p, purchhead 
				WHERE p.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND p.period_num = fisc_per 
				AND p.year_num = glob_fisc_year 
				AND p.posted_flag = "N" 
				AND p.tran_code = "VO" 
				AND p.voucher_qty >= 0 
				AND p.cmpy_code = purchhead.cmpy_code 
				AND p.po_num = purchhead.order_num 

				AND purchhead.type_ind = "3" 
				AND purchhead.curr_code = pr_currency_code 
				FOREACH po_vou3_cur2 
					LET err_message = " V3 poaudit UPDATE" 
					# flag SET TO 'T' FOR tax processing temporary
					# fix FOR type 3 purchase orders only.
					UPDATE postpoaudit SET posted_flag = "T", 
					jour_num = l_its_ok 
					WHERE rowid = row_id 
				END FOREACH 
			END IF 
	END CASE 

END FUNCTION 



FUNCTION undo_flag() 

	DEFINE row_id INTEGER 

	# This FUNCTION along with do tax AND flagging Voucher V3 posted_flag
	# TO 'T' are a temporary solution TO tax posting FROM type 3
	#  purchase orders.

	GOTO bypass 
	LABEL recovery: 
	CALL update_poststatus(TRUE,STATUS,"PU") 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 

	LET glob_err_text = "Update post flag FROM T TO Y" 

	DECLARE undo_curs CURSOR FOR 
	SELECT postpoaudit.rowid 
	INTO row_id 
	FROM postpoaudit 
	WHERE postpoaudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND postpoaudit.posted_flag = "T" 

	FOREACH undo_curs 
		LET glob_err_text = "Resetting Post Flag TO Y" 
		UPDATE postpoaudit SET posted_flag = "Y" 
		WHERE rowid = row_id 
	END FOREACH 

END FUNCTION 



FUNCTION post_pu() 
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE pl_rowid INTEGER 

	GOTO bypass 
	LABEL recovery: 
	CALL update_poststatus(TRUE,STATUS,"PU") 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
{
	CALL upd_rms(glob_rec_kandoouser.cmpy_code, 
	glob_rec_kandoouser.sign_on_code, 
	pr_rec_kandoouser.security_ind, 
	glob_rec_rmsreps.report_width_num, 
	"RS2", 
	"PU Posting Report") 
	RETURNING pr_output 
}
	# IF this IS a properly configured online site (ie correct # locks
	# THEN they may wish TO run one big transaction. In which CASE
	# poststatus.online_ind = "Y". Just TO be flexible you may also
	# run the program in the 'old' lock table mode. This will still use
	# the post tables but will allow single glob_rec_kandoouser.cmpy_code sites TO ensure
	# absolute integrity of data.

	LET glob_one_trans = false 
	IF glob_rec_poststatus.online_ind = "Y" OR 
	glob_rec_poststatus.online_ind = "L" THEN 
		BEGIN WORK 
			LET glob_one_trans = true 
			LET glob_in_trans = true 
		END IF 

		# lock tables IF program IS TO run in Lock mode
		IF glob_rec_poststatus.online_ind = "L" THEN 
			LOCK TABLE puparms in share MODE 
			LOCK TABLE purchhead in share MODE 
			LOCK TABLE poaudit in share MODE 
			LOCK TABLE postpoaudit in share MODE 
		END IF 

--		START REPORT  TO pr_output 
			#------------------------------------------------------------
			LET l_rpt_idx = rpt_start(getmoduleid(),"COM_jourintf_rpt_list_bd","N/A", RPT_SHOW_RMS_DIALOG)
			IF l_rpt_idx = 0 THEN #User pressed CANCEL
				RETURN FALSE
			END IF	
			START REPORT COM_jourintf_rpt_list_bd TO rpt_get_report_file_with_path2(l_rpt_idx)
			WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
			TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
			BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
			LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
			RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
			#------------------------------------------------------------
		LET modu_rpt_idx = l_rpt_idx

		# Check that the journals are present
		SELECT * 
		INTO pr_journal.* 
		FROM journal 
		WHERE jour_code = pr_puparms.receipt_jour_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		IF status = notfound THEN 			
			ERROR kandoomsg2("R",9502,"") # 9502 "Goods Receipt Journal NOT found"
			SLEEP 3 
			UPDATE poststatus SET post_running_flag = "N" 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND module_code = "PU" 
			EXIT program 
		END IF 

		SELECT * 
		INTO pr_journal.* 
		FROM journal 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND jour_code = pr_puparms.commit_jour_code 
		IF status = notfound THEN 			
			ERROR kandoomsg2("R",9503,"") # 9503 " Commitments Journal NOT found "
			SLEEP 3 
			UPDATE poststatus SET post_running_flag = "N" 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND module_code = "PU" 
			EXIT program 
		END IF 

		SELECT * 
		INTO pr_journal.* 
		FROM journal 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND jour_code = pr_puparms.purch_jour_code 
		IF status = notfound THEN 			
			ERROR kandoomsg2("R",9504,"") # 9504 " Purchasing Journal NOT found "
			SLEEP 3 
			UPDATE poststatus SET post_running_flag = "N" 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND module_code = "PU" 
			EXIT program 
		END IF 

		--    OPEN WINDOW show_post AT 10,10 with 5 rows, 50 columns  -- albo  KD-756
		--                          ATTRIBUTE(border,prompt line 5)

		# all the poaudits are selected together AND saved INTO postpoaudit
		# THEN each FUNCTION will be performed on them

		LET glob_err_text = "Commenced poaudit post" 
		IF post_status = 1 THEN {error in poaudit post TO postpoaudit} 			
			ERROR kandoomsg2("R",9505,"") #9505 "Rolling back poaudit AND postpoaudit"
			SLEEP 2 
			LET glob_err_text = "Reversing previous Poaudit" 

			IF NOT glob_one_trans THEN 
				BEGIN WORK 
					LET glob_in_trans = true 
				END IF 

				IF glob_rec_poststatus.online_ind != "L" THEN 
					LOCK TABLE postpoaudit in share MODE 
					LOCK TABLE poaudit in share MODE 
				END IF 

				DECLARE poaudit_undo CURSOR FOR 
				SELECT * 
				FROM postpoaudit 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				FOR UPDATE 

				FOREACH poaudit_undo INTO pr_poaudit.* 

					UPDATE poaudit SET posted_flag = "N" 
					WHERE cmpy_code = pr_poaudit.cmpy_code 
					AND po_num = pr_poaudit.po_num 
					AND line_num = pr_poaudit.line_num 
					AND seq_num = pr_poaudit.seq_num 

					DELETE FROM postpoaudit WHERE CURRENT OF poaudit_undo 

				END FOREACH 
				IF NOT glob_one_trans THEN 
				COMMIT WORK 
				LET glob_in_trans = false 
			END IF 
		END IF 

		LET glob_st_code = 1 
		LET glob_post_text = "Commenced INSERT INTO postpoaudit" 
		CALL update_poststatus(FALSE,0,"PU") 

		IF post_status = 1 OR post_status = 99 THEN 
			LET glob_err_text = "Poaudit SELECT FOR INSERT" 

			DECLARE poaudit_curs CURSOR with HOLD FOR 
			SELECT * 
			INTO pr_poaudit.* 
			FROM poaudit 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND posted_flag = "N" 
			AND year_num = glob_fisc_year 
			AND period_num = fisc_per 

			LET glob_err_text = "Poaudit FOREACH FOR INSERT" 
			FOREACH poaudit_curs INTO pr_poaudit.* 
				LET set_retry = retry_lock(glob_rec_kandoouser.cmpy_code,0) 
				WHILE (true) 
					IF NOT glob_one_trans THEN 
						BEGIN WORK 
							LET glob_in_trans = true 
						END IF 
						WHENEVER ERROR CONTINUE 

						DECLARE insert_curs CURSOR FOR 
						SELECT * 
						FROM poaudit 
						WHERE cmpy_code = pr_poaudit.cmpy_code 
						AND po_num = pr_poaudit.po_num 
						AND line_num = pr_poaudit.line_num 
						AND seq_num = pr_poaudit.seq_num 
						FOR UPDATE 

						LET glob_err_text = "Poaudit lock FOR INSERT" 
						OPEN insert_curs 
						FETCH insert_curs INTO pr_poaudit.* 
						LET stat_code = status 
						IF stat_code THEN 
							IF stat_code = notfound THEN 
								IF NOT glob_one_trans THEN 
								COMMIT WORK 
							END IF 
							CONTINUE FOREACH 
						END IF 
						LET set_retry = retry_lock(glob_rec_kandoouser.cmpy_code,stat_code) 
						IF set_retry <= 0 THEN 
							# one transaction users cannot rollback
							IF NOT glob_one_trans THEN 
								LET try_again = error_recover("Poaudit INSERT", 
								stat_code) 
								IF try_again != "Y" THEN 
									LET glob_in_trans = false 
									CALL update_poststatus(TRUE,stat_code,"PU") 
								ELSE 
									ROLLBACK WORK 
									CONTINUE WHILE 
								END IF 
							ELSE 
								CALL update_poststatus(TRUE,stat_code,"PU") 
							END IF 
						ELSE 
							IF NOT glob_one_trans THEN 
							COMMIT WORK 
						END IF 
						CONTINUE WHILE 
					END IF 
				END IF 
				EXIT WHILE 
			END WHILE 
			LET set_retry = retry_lock(glob_rec_kandoouser.cmpy_code,0) 

			WHENEVER ERROR GOTO recovery 

			LET glob_err_text = "RS2 - Insert INTO postpoaudit" 
			INSERT INTO postpoaudit VALUES (pr_poaudit.*) 

			LET glob_err_text = "RS2 - Poaudit post flag SET" 
			UPDATE poaudit SET posted_flag = "Y" 
			WHERE cmpy_code = pr_poaudit.cmpy_code 
			AND po_num = pr_poaudit.po_num 
			AND line_num = pr_poaudit.line_num 
			AND seq_num = pr_poaudit.seq_num 
			#WHERE current of insert_curs

			IF NOT glob_one_trans THEN 
			COMMIT WORK 
			LET glob_in_trans = false 
		END IF 
	END FOREACH 
END IF 

LET glob_st_code = 2 
LET glob_post_text = "Completed INSERT INTO postpoaudit" 
CALL update_poststatus(FALSE,0,"PU") 



#
# Purchhead updates AND postings
#

ERROR kandoomsg2("R",1500,"") # 1500 " Posting Purchases... "

IF post_status <= 2 OR post_status = 99 THEN 
	IF post_status = 2 THEN 
		LET glob_posted_journal = glob_rec_poststatus.jour_num 
	ELSE 
		LET glob_posted_journal = NULL 
	END IF 

	CALL purch_post("C1") 

	LET glob_st_code = 3 
	LET glob_post_text = "Completed purch_post (C1)" 
	CALL update_poststatus(FALSE,0,"PU") 
END IF 

IF post_status <= 3 OR post_status = 99 THEN 
	IF post_status = 3 THEN 
		LET glob_posted_journal = glob_rec_poststatus.jour_num 
	ELSE 
		LET glob_posted_journal = NULL 
	END IF 

	CALL flag_them("CM", "", "") 

	LET glob_st_code = 4 
	LET glob_post_text = "Completed flag_them (CM)" 
	CALL update_poststatus(FALSE,0,"PU") 
END IF 


#
# Goods Receipt updates AND postings
#



ERROR kandoomsg2("R",1501,"")# 1501 " Posting Receipts " 

IF post_status <= 4 OR post_status = 99 THEN 
	IF post_status = 4 THEN 
		LET glob_posted_journal = glob_rec_poststatus.jour_num 
	ELSE 
		LET glob_posted_journal = NULL 
	END IF 

	CALL receipt_post("G1") 
	LET glob_st_code = 5 
	LET glob_post_text = "Completed receipt_post G1" 
	CALL update_poststatus(FALSE,0,"PU") 
END IF 

IF post_status <= 5 OR post_status = 99 THEN 
	IF post_status = 5 THEN 
		LET glob_posted_journal = glob_rec_poststatus.jour_num 
	ELSE 
		LET glob_posted_journal = NULL 
	END IF 

	CALL receipt_post("G2") 

	LET glob_st_code = 6 
	LET glob_post_text = "Completed receipt_post G2" 
	CALL update_poststatus(FALSE,0,"PU") 
END IF 


#
# Closing/Clearing entry  updates AND postings
#



ERROR kandoomsg2("R",1508,"") # 1501 " Posting Closing entries "

IF post_status <= 6 OR post_status = 99 THEN 
	IF post_status = 6 THEN 
		LET glob_posted_journal = glob_rec_poststatus.jour_num 
	ELSE 
		LET glob_posted_journal = NULL 
	END IF 

	CALL receipt_post("L1") 

	LET glob_st_code = 7 
	LET glob_post_text = "Completed receipt_post L1" 
	CALL update_poststatus(FALSE,0,"PU") 
END IF 

IF post_status <= 7 OR post_status = 99 THEN 
	IF post_status = 7 THEN 
		LET glob_posted_journal = glob_rec_poststatus.jour_num 
	ELSE 
		LET glob_posted_journal = NULL 
	END IF 

	CALL receipt_post("L2") 

	LET glob_st_code = 8 
	LET glob_post_text = "Completed receipt_post L2" 
	CALL update_poststatus(FALSE,0,"PU") 
END IF 


IF post_status <= 8 OR post_status = 99 THEN 
	IF post_status = 8 OR post_status = 99 THEN 
		LET glob_posted_journal = glob_rec_poststatus.jour_num 
	ELSE 
		LET glob_posted_journal = NULL 
	END IF 

	CALL flag_them("G3", "", "") 

	LET glob_st_code = 9 
	LET glob_post_text = "Completed flag_them G3" 
	CALL update_poststatus(FALSE,0,"PU") 
END IF 


#
# Voucher updates AND postings
#


ERROR kandoomsg2("R",1502,"") # 1502 " Posting Vouchers "

IF post_status <= 9 OR post_status = 99 THEN 
	IF post_status = 9 THEN 
		LET glob_posted_journal = glob_rec_poststatus.jour_num 
	ELSE 
		LET glob_posted_journal = NULL 
	END IF 

	CALL summ_vouch_post("V1") 

	LET glob_st_code = 10 
	LET glob_post_text = "Completed voucher post V1" 
	CALL update_poststatus(FALSE,0,"PU") 
END IF 

IF post_status <= 10 OR post_status = 99 THEN 
	IF post_status = 10 THEN 
		LET glob_posted_journal = glob_rec_poststatus.jour_num 
	ELSE 
		LET glob_posted_journal = NULL 
	END IF 

	CALL summ_vouch_post("V2") 

	LET glob_st_code = 11 
	LET glob_err_text = "Completed voucher post V2" 
	CALL update_poststatus(FALSE,0,"PU") 
END IF 

IF post_status <= 11 OR post_status = 99 THEN 
	IF post_status = 11 THEN 
		LET glob_posted_journal = glob_rec_poststatus.jour_num 
	ELSE 
		LET glob_posted_journal = NULL 
	END IF 

	CALL vouch_post("V3") 

	LET glob_st_code = 12 
	LET glob_post_text = "Completed vouch_post V3" 
	CALL update_poststatus(FALSE,0,"PU") 
END IF 


#
# Tax udpate AND post FOR type 3 vouchers only (Temporary)
#


IF post_status <= 12 OR post_status = 99 THEN 
	IF post_status = 12 THEN 
		LET glob_posted_journal = glob_rec_poststatus.jour_num 
	ELSE 
		LET glob_posted_journal = NULL 
	END IF 

	CALL do_tax() 

	LET glob_st_code = 13 
	LET glob_post_text = "Completed tax post V3" 
	CALL update_poststatus(FALSE,0,"PU") 
END IF 

IF post_status <= 13 OR post_status = 99 THEN 
	IF post_status = 13 THEN 
		LET glob_posted_journal = glob_rec_poststatus.jour_num 
	ELSE 
		LET glob_posted_journal = NULL 
	END IF 

	CALL undo_flag() 

	LET glob_st_code = 14 
	LET glob_post_text = "Completed undo_flag (Tax V3)" 
	CALL update_poststatus(FALSE,0,"PU") 
END IF 



LET glob_st_code = 15 
LET glob_post_text = "Commenced UPDATE jour_num FROM postpoaudit" 
CALL update_poststatus(FALSE,0,"PU") 

IF post_status != 16 THEN 
	LET glob_err_text = "Update jour_num in postpoaudit" 
	DECLARE update_jour CURSOR with HOLD FOR 
	SELECT * 
	FROM postpoaudit 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 

	FOREACH update_jour INTO pr_poaudit.* 
		IF NOT glob_one_trans THEN 
			BEGIN WORK 
				LET glob_in_trans = true 
			END IF 
			UPDATE poaudit SET jour_num = pr_poaudit.jour_num 
			WHERE cmpy_code = pr_poaudit.cmpy_code 
			AND po_num = pr_poaudit.po_num 
			AND line_num = pr_poaudit.line_num 
			AND seq_num = pr_poaudit.seq_num 

			IF NOT glob_one_trans THEN 
			COMMIT WORK 
			LET glob_in_trans = false 
		END IF 
	END FOREACH 
END IF 

LET glob_st_code = 16 
LET glob_post_text = "Commenced DELETE FROM postpoaudit" 
CALL update_poststatus(FALSE,0,"PU") 

LET glob_err_text = "DELETE FROM postpoaudit" 
IF NOT glob_one_trans THEN 
	BEGIN WORK 
		LET glob_in_trans = true 
	END IF 
	IF glob_rec_poststatus.online_ind != "L" THEN 
		LOCK TABLE postpoaudit in share MODE 
	END IF 
	DELETE FROM postpoaudit WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF NOT glob_one_trans THEN 
	COMMIT WORK 
	LET glob_in_trans = false 
END IF 

LET glob_st_code = 99 
LET glob_post_text = "Purchasing posting completed correctly" 
CALL update_poststatus(FALSE,0,"PU") 

WHENEVER ERROR stop 

	#------------------------------------------------------------
	FINISH REPORT COM_jourintf_rpt_list_bd
	CALL rpt_finish("COM_jourintf_rpt_list_bd")
	#------------------------------------------------------------


IF l_all_ok = 0 THEN 
	ERROR kandoomsg2("U",3527,"") #3527 SUSPENSE ACCOUNTS USED; Press ENTER.
ELSE 
	ERROR kandoomsg2("U",3528,"") #3528 Posting completed; Press ENTER.
END IF 

UPDATE poststatus SET post_running_flag = "N" 
WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
AND module_code = "PU" 

IF glob_one_trans THEN 
	LET msgresp = kandoomsg("U",8502,"") #8502 Accept Posting? (Y/N):
	IF msgresp = "N" THEN 
		ROLLBACK WORK 
		LET glob_in_trans = false 
		UPDATE poststatus SET post_running_flag = "N" 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND module_code = "PU" 
	ELSE 
	COMMIT WORK 
	LET glob_in_trans = false 
END IF 
END IF 
--    CLOSE WINDOW show_post  -- albo  KD-756
EXIT program 
END FUNCTION 

