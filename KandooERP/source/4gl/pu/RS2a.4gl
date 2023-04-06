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
# \brief module RS2a  Detailed Purchasing Posting Process
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

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "../pu/R_PU_GLOBALS.4gl" 
GLOBALS "../common/postfunc_GLOBALS.4gl" 

GLOBALS 
	DEFINE 
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
	pa_period array[400] OF RECORD 
		year_num LIKE period.year_num, 
		period_num LIKE period.period_num, 
		post_req CHAR(1) 
	END RECORD, 
	pr_puparms RECORD LIKE puparms.*, 
	pr_period RECORD LIKE period.*, 
	pr_purchhead RECORD LIKE purchhead.*, 
	pr_purchdetl RECORD LIKE purchdetl.*, 
	pr_poaudit RECORD LIKE poaudit.*, 
	pr_journal RECORD LIKE journal.*, 
	pr_rec_kandoouser RECORD LIKE kandoouser.*, 
	doit CHAR(1), 
	sel_text CHAR(900), 
	where_part CHAR(900), 
	sel_stmt CHAR(900) 

	DEFINE l_its_ok INTEGER
	DEFINE l_all_ok INTEGER
	DEFINE rpt_wid SMALLINT, 
	pr_output CHAR(60), 
	try_again CHAR(1), 
	err_message CHAR(80), 
	temp_description CHAR(80) 
	#DEFINE glob_fisc_year SMALLINT
	DEFINE scrn SMALLINT 
	DEFINE i SMALLINT 
	DEFINE idx SMALLINT 
	#DEFINE glob_fisc_period  SMALLINT
	DEFINE counter SMALLINT 

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

	# SET glob_rec_kandoouser.sign_on_code TO PU so GL knows WHERE it came FROM
	#   LET glob_rec_kandoouser.sign_on_code = "PU"
	LET l_its_ok = 0 
	LET l_all_ok = true 
	SELECT * 
	INTO pr_puparms.* 
	FROM puparms 
	WHERE key_code = "1" 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF status = notfound THEN 
		ERROR " PU Parameters missing " 
		SLEEP 10 
		EXIT program 
	END IF 
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
	stats_qty DECIMAL(15,3)) with no LOG 
	CALL get_info() 
END MAIN 


FUNCTION get_info() 
	OPEN WINDOW wr150 with FORM "R150" 
	CALL  windecoration_r("R150") 

	MESSAGE "Enter selection - ESC TO search" 
	attribute (yellow) 
	CONSTRUCT BY NAME where_part ON 
	year_num, 
	period_num 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","RS2a","construct-year_period-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	LET sel_text = 
	"SELECT unique year_num, period_num ", 
	"FROM period WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
	where_part clipped, 
	"ORDER BY year_num, period_num " 
	IF int_flag OR quit_flag THEN 
		EXIT program 
	END IF 
	PREPARE getper FROM sel_text 
	DECLARE c_per CURSOR FOR getper 
	LET idx = 0 
	FOREACH c_per INTO pr_period.year_num, 
		pr_period.period_num 
		LET idx = idx + 1 
		LET pa_period[idx].year_num = pr_period.year_num 
		LET pa_period[idx].post_req = " " 
		LET pa_period[idx].period_num = pr_period.period_num 
		IF idx > 300 THEN 
			MESSAGE " Only first 300 selected " attribute(yellow) 
			SLEEP 4 
			EXIT FOREACH 
		END IF 
	END FOREACH 
	CALL set_count (idx) 
	MESSAGE "Press RETURN on line TO post - F10 TO check " 


	INPUT ARRAY pa_period WITHOUT DEFAULTS FROM sr_period.* ATTRIBUTE(UNBUFFERED) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","RS2a","inp-arr-period-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			IF arr_curr() > arr_count() THEN 
				ERROR "No more rows in the direction you are going" 
			END IF 
		ON KEY (F10) 
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

				AND purchhead.type_ind in ("1", "2","3") 
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
					AND poaudit.tran_code in ("GA", "GR") 
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
						END IF 
					END IF 
				END IF 
				IF i <= 12 THEN 
					DISPLAY pa_period[i].* TO sr_period[i].* 
				END IF 
			END FOR 
		BEFORE FIELD period_num 
			LET glob_fisc_period = pa_period[idx].period_num 
			LET glob_fisc_year = pa_period[idx].year_num 
			CALL post_pu() 
			NEXT FIELD year_num 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET quit_flag = false 
		LET int_flag = false 
	END IF 
	CLOSE WINDOW wr150 
END FUNCTION 


FUNCTION convert_post_amts() 

	CALL get_conv_rate(glob_rec_kandoouser.cmpy_code, 
	pr_data.currency_code, 
	pr_data.tran_date, 
	CASH_EXCHANGE_BUY) 
	RETURNING pr_data.conv_qty 
	LET pr_data.base_debit_amt = 
	pr_data.for_debit_amt / pr_data.conv_qty 
	LET pr_data.base_credit_amt = 
	pr_data.for_credit_amt / pr_data.conv_qty 

END FUNCTION 


FUNCTION create_gl_batches(pr_journal_code, posting_type) 

	DEFINE 
	pr_journal_code LIKE journal.jour_code, 
	pr_currency_code LIKE currency.currency_code, 
	posting_type CHAR(2) 

	DISPLAY "" at 1,2 
	DECLARE curr_curs CURSOR FOR 
	SELECT unique currency_code 
	INTO pr_currency_code 
	FROM posttemp 
	FOREACH curr_curs 
		LET sel_stmt = " SELECT *", 
		" FROM posttemp ", 
		" WHERE posttemp.currency_code = \"", 
		pr_currency_code, "\"" 

		LET l_its_ok = jourintf2(modu_rpt_idx,
		sel_stmt, 
		--glob_rec_kandoouser.cmpy_code, 
		--"PU", 
		bal_rec.*, 
		glob_fisc_period , 
		glob_fisc_year, 
		pr_journal_code, 
		"R", 
		pr_currency_code, 
		--pr_output, 
		"PU") 
		# see IF there IS a problem, IF so save
		IF l_its_ok < 0 THEN 
			LET l_all_ok = false 
			LET l_its_ok = 0 - l_its_ok # NEED TO reverse TO make +ve. 
		END IF 
		IF l_its_ok != 0 THEN 
			DISPLAY " Batch: ", l_its_ok, " " at 1,2 
		END IF 
		# flag the posted transactions with the journal number
		CALL flag_them(posting_type, pr_currency_code) 
	END FOREACH 
	# now delete all FROM the table
	DELETE FROM posttemp WHERE 1=1 
END FUNCTION 


FUNCTION post_pu()
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	 
--	CALL upd_rms(glob_rec_kandoouser.cmpy_code, 
--	glob_rec_kandoouser.sign_on_code, 
--	pr_rec_kandoouser.security_ind, 
--	glob_rec_rmsreps.report_width_num, 
--	"RS2", 
--	"PU Posting Report") 
--	RETURNING pr_output 
	GOTO bypass 
	LABEL recovery: 
	LET try_again = error_recover(err_message, status) 
	IF try_again != "Y" THEN 
		EXIT program 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	BEGIN WORK 
		LOCK TABLE puparms in share MODE 
		LOCK TABLE purchhead in share MODE 
		LOCK TABLE poaudit in share MODE 


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
			ERROR "Goods Receipt Journal NOT found" 
			SLEEP 3 
			EXIT program 
		END IF 
		SELECT * 
		INTO pr_journal.* 
		FROM journal 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND jour_code = pr_puparms.commit_jour_code 
		IF status = notfound THEN 
			ERROR " Commitments Journal NOT found " 
			SLEEP 3 
			EXIT program 
		END IF 
		SELECT * 
		INTO pr_journal.* 
		FROM journal 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND jour_code = pr_puparms.purch_jour_code 
		IF status = notfound THEN 
			ERROR " Purchasing Journal NOT found " 
			SLEEP 3 
			EXIT program 
		END IF 

		--   OPEN WINDOW shower AT 10,5 with 1 rows, 60 columns  -- albo  KD-756
		--      ATTRIBUTE(border, reverse)
		# do all the purchhead updates AND postings
		DISPLAY " Posting Purchases " at 3,2 
		CALL purch_post("C1") 
		CALL flag_them("CM", "") 
		# do all the goods receipt updates AND postings
		DISPLAY " Posting Receipts " at 3,2 
		CALL receipt_post("G1") 
		CALL receipt_post("G2") 
		CALL flag_them("G3", "") 
		# do all the voucher updates AND postings
		DISPLAY " Posting Vouchers " at 3,2 
		CALL summ_vouch_post("V1") 
		CALL summ_vouch_post("V2") 
		CALL vouch_post("V3") 

	#------------------------------------------------------------
	FINISH REPORT COM_jourintf_rpt_list_bd
	CALL rpt_finish("COM_jourintf_rpt_list_bd")
	#------------------------------------------------------------

		IF NOT l_all_ok THEN 
			CALL eventsuspend() --LET doit = AnyKey(" SUSPENSE ACCOUNTS USED, RETURN TO accept, BREAK TO cancel",13,10) -- albo 
						{  -- albo
						      prompt " SUSPENSE ACCOUNTS USED, RETURN TO accept, DEL TO cancel"
						         FOR CHAR doit

								BEFORE PROMPT
									CALL publish_toolbar("kandoo","RS2a","prompt-suspense_account-1")

								ON ACTION "WEB-HELP"
									CALL onlineHelp(getModuleId(),NULL)
									ON ACTION "actToolbarManager"
								 	CALL setupToolbar()

							END PROMPT
						}
			IF int_flag OR quit_flag THEN 
				ROLLBACK WORK 
			ELSE 
			COMMIT WORK 
		END IF 
	ELSE 
		CALL eventsuspend() --LET doit = AnyKey(" Posting complete - RETURN TO accept, BREAK TO cancel",13,10) -- albo 
				{  -- albo
				      prompt " Posting complete - RETURN TO accept, DEL TO cancel"
				         FOR CHAR doit

						BEFORE PROMPT
							CALL publish_toolbar("kandoo","RS2a","prompt-posting_complete-1")

						ON ACTION "WEB-HELP"
							CALL onlineHelp(getModuleId(),NULL)
							ON ACTION "actToolbarManager"
						 	CALL setupToolbar()

					END PROMPT
				}
		IF int_flag OR quit_flag THEN 
			ROLLBACK WORK 
		ELSE 
		COMMIT WORK 
	END IF 
END IF 
EXIT program 
--   CLOSE WINDOW shower  -- albo  KD-756
END FUNCTION 


FUNCTION purch_post(posting_type) 

	DEFINE 
	posting_type CHAR(2) 

	GOTO bypass 
	LABEL recovery: 
	LET try_again = error_recover(err_message, status) 
	IF try_again != "Y" THEN 
		EXIT program 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	#
	# now post the commitment journal across
	# FOR type 1 purchase orders, i.e. commitment accounting method
	# note these are done in summary form
	# but with the jour num passed back
	#
	LET bal_rec.tran_type_ind = "PO" 
	LET bal_rec.acct_code = pr_puparms.commit_acct_code 
	LET bal_rec.desc_text = " C1 Commitment A/C Summary" 
	DECLARE po_head_curs CURSOR FOR 
	SELECT sum(poaudit.line_total_amt), 
	poaudit.po_num, 
	purchhead.curr_code 
	FROM poaudit, purchhead 
	WHERE poaudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND poaudit.period_num = glob_fisc_period 
	AND poaudit.year_num = glob_fisc_year 
	AND poaudit.posted_flag = "N" 
	AND poaudit.tran_code in ("AA", "AL", "CQ", "CP") 
	AND purchhead.cmpy_code = poaudit.cmpy_code 
	AND purchhead.order_num = poaudit.po_num 

	AND purchhead.type_ind = "1" 
	GROUP BY po_num, curr_code 
	LET pr_data.tran_type_ind = "PO" 
	LET pr_data.ref_num = 0 
	LET pr_data.ref_text = "Summary" 
	LET pr_data.acct_code = pr_puparms.goodsin_acct_code 
	LET pr_data.for_credit_amt = 0 
	LET pr_data.tran_date = today 
	FOREACH po_head_curs INTO pr_data.for_debit_amt, 
		pr_poaudit.po_num, 
		pr_data.currency_code 
		CALL convert_post_amts() 
		LET pr_data.desc_text = "Goods On Order - PO ", 
		pr_poaudit.po_num USING "########" 
		INSERT INTO posttemp 
		VALUES (pr_data.*) 
	END FOREACH 
	CALL create_gl_batches(pr_puparms.commit_jour_code, posting_type) 
END FUNCTION 


FUNCTION receipt_post(post_type) 

	DEFINE 
	post_type CHAR(2), 
	gr_num LIKE poaudit.tran_num, 
	pr_purch_type_ind LIKE purchhead.type_ind, 
	post_journal_code LIKE journal.jour_code 

	GOTO bypass 
	LABEL recovery: 
	LET try_again = error_recover(err_message, status) 
	IF try_again != "Y" THEN 
		EXIT program 
	END IF 
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
		WHEN post_type = "G2" 
			LET err_message = " G2 Goods Receipt posting " 
			LET bal_rec.tran_type_ind = "GR" 
			LET bal_rec.desc_text = " G2 Goods Receipt Balancing Entry " 
			LET bal_rec.acct_code = pr_puparms.accrued_acct_code 
			LET pr_purch_type_ind = "2" 
	END CASE 

	# Now post the goods receipt journal across
	DECLARE po_gr_curs CURSOR FOR 
	SELECT poaudit.tran_code, 
	poaudit.po_num, 
	poaudit.vend_code, 
	purchdetl.acct_code, 
	poaudit.desc_text, 
	poaudit.line_total_amt, 
	0, 
	0, 
	0, 
	purchhead.curr_code, 
	0, 
	poaudit.tran_date, 
	0, 
	poaudit.tran_num 
	FROM poaudit, purchdetl, purchhead 
	WHERE poaudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND poaudit.posted_flag = "N" 
	AND poaudit.period_num = glob_fisc_period 
	AND poaudit.year_num = glob_fisc_year 
	AND poaudit.tran_code in ("GA", "GR") 
	AND poaudit.line_total_amt != 0 
	AND poaudit.cmpy_code = purchhead.cmpy_code 
	AND poaudit.po_num = purchhead.order_num 

	AND purchhead.type_ind = pr_purch_type_ind 
	AND purchdetl.cmpy_code = poaudit.cmpy_code 
	AND purchdetl.order_num = poaudit.po_num 

	AND poaudit.line_num = purchdetl.line_num 
	FOREACH po_gr_curs INTO pr_data.*, 
		gr_num 
		CALL convert_post_amts() 
		LET temp_description = gr_num USING "########", " ", 
		pr_data.desc_text 
		LET pr_data.desc_text = temp_description 
		INSERT INTO posttemp 
		VALUES (pr_data.*) 
	END FOREACH 

	CALL create_gl_batches(pr_puparms.receipt_jour_code, post_type) 
END FUNCTION 


FUNCTION summ_vouch_post(post_type) 

	DEFINE 
	post_type CHAR(2), 
	pr_purch_type_ind LIKE purchhead.type_ind 

	GOTO bypass 
	LABEL recovery: 
	LET try_again = error_recover(err_message, status) 
	IF try_again != "Y" THEN 
		EXIT program 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	# Set up the posting data AND selection criteria according TO the type
	# of transaction TO be posted
	CASE 
		WHEN post_type = "V1" 
			LET bal_rec.tran_type_ind = "VP" 
			LET bal_rec.desc_text = " Voucher Clearing P.O. Type 1 " 
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
			LET bal_rec.desc_text = " Voucher Clearing P.O. Type 2 " 
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
	SELECT sum(poaudit.line_total_amt), 
	poaudit.tran_num, 
	poaudit.po_num, 
	purchhead.curr_code 
	FROM purchhead, poaudit 
	WHERE poaudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND poaudit.year_num = glob_fisc_year 
	AND poaudit.period_num = glob_fisc_period 
	AND poaudit.posted_flag = "N" 
	AND poaudit.tran_code = "VO" 
	AND purchhead.cmpy_code = poaudit.cmpy_code 
	AND purchhead.order_num = poaudit.po_num 

	AND purchhead.type_ind = pr_purch_type_ind 
	GROUP BY tran_num, po_num, curr_code 
	FOREACH po_vos_curs INTO pr_data.for_debit_amt, 
		pr_poaudit.tran_num, 
		pr_poaudit.po_num, 
		pr_data.currency_code 
		CALL convert_post_amts() 
		LET pr_data.desc_text = "VO Type ", pr_purch_type_ind clipped, 
		" - VO ", 
		pr_poaudit.tran_num USING "########" 
		INSERT INTO posttemp 
		VALUES (pr_data.*) 
	END FOREACH 
	CALL create_gl_batches(pr_puparms.purch_jour_code, post_type) 

END FUNCTION 


FUNCTION vouch_post(post_type) 
	DEFINE 
	post_type CHAR(2) 

	GOTO bypass 
	LABEL recovery: 
	LET try_again = error_recover(err_message, status) 
	IF try_again != "Y" THEN 
		EXIT program 
	END IF 
	LABEL bypass: 
	LET bal_rec.tran_type_ind = "VP" 
	LET bal_rec.desc_text = " Voucher Clearing Type 3 " 
	LET bal_rec.acct_code = pr_puparms.clear_acct_code 
	DECLARE po_vod_curs CURSOR FOR 
	SELECT "VP", 
	poaudit.po_num, 
	poaudit.vend_code, 
	purchdetl.acct_code, 
	purchdetl.desc_text, 
	poaudit.line_total_amt, 
	0, 
	0, 
	0, 
	purchhead.curr_code, 
	0, 
	poaudit.tran_date, 
	0, 
	poaudit.tran_num 
	FROM poaudit , purchdetl, purchhead 
	WHERE poaudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND poaudit.year_num = glob_fisc_year 
	AND poaudit.period_num = glob_fisc_period 
	AND poaudit.posted_flag = "N" 
	AND poaudit.tran_code = "VO" 
	AND poaudit.line_total_amt != 0 
	AND poaudit.cmpy_code = purchhead.cmpy_code 
	AND poaudit.po_num = purchhead.order_num 

	AND purchhead.type_ind = "3" 
	AND purchdetl.cmpy_code = poaudit.cmpy_code 
	AND purchdetl.order_num = poaudit.po_num 

	AND purchdetl.line_num = poaudit.line_num 
	FOREACH po_vod_curs INTO pr_data.*, 
		pr_poaudit.tran_num 
		CALL convert_post_amts() 
		LET temp_description = pr_poaudit.tran_num USING "########", 
		" ", pr_data.desc_text 
		LET pr_data.desc_text = temp_description 
		INSERT INTO posttemp 
		VALUES (pr_data.*) 
	END FOREACH 
	CALL create_gl_batches(pr_puparms.purch_jour_code, post_type) 
END FUNCTION 


FUNCTION flag_them(flag_ind, pr_currency_code) 

	DEFINE 
	flag_ind CHAR(2), 
	pr_currency_code LIKE currency.currency_code, 
	row_id INTEGER 

	GOTO bypass 
	LABEL recovery: 
	LET try_again = error_recover(err_message, status) 
	IF try_again != "Y" THEN 
		EXIT program 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	CASE 
		WHEN flag_ind = "C1" # commitment 
			LET err_message = " C1 poaudit UPDATE" 
			DECLARE po_comm_curs CURSOR FOR 
			SELECT poaudit.rowid 
			INTO row_id 
			FROM poaudit, purchhead 
			WHERE poaudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND poaudit.period_num = glob_fisc_period 
			AND poaudit.year_num = glob_fisc_year 
			AND poaudit.posted_flag = "N" 
			AND poaudit.tran_code in ("AA", "AL", "CQ", "CP") 
			AND purchhead.cmpy_code = poaudit.cmpy_code 
			AND purchhead.order_num = poaudit.po_num 

			AND purchhead.type_ind = "1" 
			AND purchhead.curr_code = pr_currency_code 
			FOREACH po_comm_curs 
				UPDATE poaudit 
				SET posted_flag = "Y", 
				jour_num = l_its_ok 
				WHERE rowid = row_id 
			END FOREACH 

			# now do the commitment transactions that do NOT post
		WHEN flag_ind = "CM" 
			LET err_message = " other poaudit UPDATE" 
			UPDATE poaudit 
			SET posted_flag = "Y", 
			jour_num = 0 
			WHERE poaudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND poaudit.posted_flag = "N" 
			AND poaudit.period_num = glob_fisc_period 
			AND poaudit.year_num = glob_fisc_year 
			AND poaudit.tran_code in ("AA", "AL", "CQ", "CP") 

		WHEN flag_ind = "G2" # goods receipt 
			DECLARE po_rec2_curs CURSOR FOR 
			SELECT poaudit.rowid 
			INTO row_id 
			FROM poaudit, purchhead 
			WHERE poaudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND poaudit.posted_flag = "N" 
			AND poaudit.tran_code in ("GA","GR") 
			AND poaudit.period_num = glob_fisc_period 
			AND poaudit.year_num = glob_fisc_year 
			AND poaudit.cmpy_code = purchhead.cmpy_code 
			AND poaudit.po_num = purchhead.order_num 

			AND purchhead.type_ind = "2" 
			AND purchhead.curr_code = pr_currency_code 
			FOREACH po_rec2_curs 
				LET err_message = " G2 poaudit UPDATE" 
				UPDATE poaudit 
				SET posted_flag = "Y", 
				jour_num = l_its_ok 
				WHERE rowid = row_id 
			END FOREACH 

		WHEN flag_ind = "G1" # goods receipt 
			DECLARE po_rec1_curs CURSOR FOR 
			SELECT poaudit.rowid 
			INTO row_id 
			FROM poaudit, purchhead 
			WHERE poaudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND poaudit.posted_flag = "N" 
			AND poaudit.tran_code in ("GA","GR") 
			AND poaudit.period_num = glob_fisc_period 
			AND poaudit.year_num = glob_fisc_year 
			AND poaudit.cmpy_code = purchhead.cmpy_code 
			AND poaudit.po_num = purchhead.order_num 

			AND purchhead.type_ind = "1" 
			AND purchhead.curr_code = pr_currency_code 
			FOREACH po_rec1_curs 
				LET err_message = " G1 poaudit UPDATE" 
				UPDATE poaudit 
				SET posted_flag = "Y", 
				jour_num = l_its_ok 
				WHERE rowid = row_id 
			END FOREACH 

		WHEN flag_ind = "G3" # the dont post type OF gr 
			LET err_message = " G3 poaudit UPDATE" 
			UPDATE poaudit 
			SET posted_flag = "Y", 
			jour_num = 0 
			WHERE poaudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND poaudit.posted_flag = "N" 
			AND poaudit.tran_code in ("GA","GR") 
			AND poaudit.period_num = glob_fisc_period 
			AND poaudit.year_num = glob_fisc_year 

		WHEN flag_ind = "V1" # voucher type 1 
			DECLARE po_vou1_curs CURSOR FOR 
			SELECT poaudit.rowid 
			INTO row_id 
			FROM poaudit, purchhead 
			WHERE poaudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND poaudit.period_num = glob_fisc_period 
			AND poaudit.year_num = glob_fisc_year 
			AND poaudit.posted_flag = "N" 
			AND poaudit.tran_code in ("VO") 
			AND purchhead.cmpy_code = poaudit.cmpy_code 
			AND purchhead.order_num = poaudit.po_num 

			AND purchhead.type_ind = "1" 
			AND purchhead.curr_code = pr_currency_code 
			FOREACH po_vou1_curs 
				LET err_message = " V1 poaudit UPDATE" 
				UPDATE poaudit 
				SET posted_flag = "Y", 
				jour_num = l_its_ok 
				WHERE rowid = row_id 
			END FOREACH 

		WHEN flag_ind = "V2" # voucher type 2 
			DECLARE po_vou2_curs CURSOR FOR 
			SELECT poaudit.rowid 
			INTO row_id 
			FROM poaudit, purchhead 
			WHERE poaudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND poaudit.period_num = glob_fisc_period 
			AND poaudit.year_num = glob_fisc_year 
			AND poaudit.posted_flag = "N" 
			AND poaudit.tran_code in ("VO") 
			AND purchhead.cmpy_code = poaudit.cmpy_code 
			AND purchhead.order_num = poaudit.po_num 

			AND purchhead.type_ind = "2" 
			AND purchhead.curr_code = pr_currency_code 
			FOREACH po_vou2_curs 
				LET err_message = " V2 poaudit UPDATE" 
				UPDATE poaudit 
				SET posted_flag = "Y", 
				jour_num = l_its_ok 
				WHERE rowid = row_id 
			END FOREACH 

		WHEN flag_ind = "V3" # voucher type 3 
			DECLARE po_vou3_curs CURSOR FOR 
			SELECT poaudit.rowid 
			INTO row_id 
			FROM poaudit, purchhead 
			WHERE poaudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND poaudit.period_num = glob_fisc_period 
			AND poaudit.year_num = glob_fisc_year 
			AND poaudit.posted_flag = "N" 
			AND poaudit.tran_code = "VO" 
			AND poaudit.cmpy_code = purchhead.cmpy_code 
			AND poaudit.po_num = purchhead.order_num 

			AND purchhead.type_ind = "3" 
			AND purchhead.curr_code = pr_currency_code 
			FOREACH po_vou3_curs 
				LET err_message = " V3 poaudit UPDATE" 
				UPDATE poaudit 
				SET posted_flag = "Y", 
				jour_num = l_its_ok 
				WHERE rowid = row_id 
			END FOREACH 
	END CASE 
END FUNCTION 
