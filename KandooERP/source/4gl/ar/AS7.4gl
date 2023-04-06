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
# NOTE: REPORT file and OUTPUT to REPORT is managed in external function jourintf()

# FUNCTION send_invoices() -> create_gl_batches() -> jourintf()
# FUNCTION jm_cos_post() ->create_gl_batches() -> jourintf()
# FUNCTION send_credits()->create_gl_batches() -> jourintf()

# FUNCTION create_summ_batches()  ->jourintf2() (used to be jourintf())
# FUNCTION start_post() -> FUNCTION AS7_post_AR() 


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "../ar/A_AR_GLOBALS.4gl"
GLOBALS "../ar/AS_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/AS7_GLOBALS.4gl" 
GLOBALS "../common/postfunc_GLOBALS.4gl"
############################################################
# Module Scope Variables
############################################################
DEFINE modu_rpt_idx SMALLINT  #rmsreps array index
DEFINE modu_sl_id LIKE kandoouser.sign_on_code #??? this is strange, the value is somehting like module id group "AR" 
DEFINE modu_rec_journal RECORD LIKE journal.* 
DEFINE modu_rec_period RECORD LIKE period.* 
DEFINE modu_rec_customerhist RECORD LIKE customerhist.* 
DEFINE modu_rec_invoicedetl RECORD LIKE invoicedetl.* 
DEFINE modu_rec_credithead RECORD LIKE credithead.* 
DEFINE modu_rec_creditdetl RECORD LIKE creditdetl.* 
DEFINE modu_rec_cashreceipt RECORD LIKE cashreceipt.* 
DEFINE modu_passed_desc LIKE batchdetl.desc_text 

DEFINE modu_rec_bal 
RECORD 
	tran_type_ind LIKE batchdetl.tran_type_ind, 
	acct_code LIKE batchdetl.acct_code, 
	desc_text LIKE batchdetl.desc_text 
END RECORD 

--DEFINE modu_arr_rec_period DYNAMIC ARRAY OF #array[400] OF
--	RECORD
--		year_num SMALLINT,
--		period_num SMALLINT,
--		post_req CHAR(1)
--	END RECORD

#DEFINE glob_fisc_year SMALLINT
#DEFINE glob_fisc_period was fisc_per SMALLINT
DEFINE modu_foundit SMALLINT 
DEFINE modu_all_ok SMALLINT 
DEFINE modu_i SMALLINT 
--DEFINE modu_idx SMALLINT

#DEFINE modu_rec_customertype RECORD LIKE customertype.* #not used
DEFINE modu_prev_cust_type LIKE customer.type_code 
DEFINE modu_prev_ord_ind LIKE ordhead.ord_ind 

DEFINE modu_rec_docdata 
RECORD 
	ref_num LIKE batchdetl.ref_num, 
	ref_text LIKE batchdetl.ref_text, 
	tran_date DATE, 
	currency_code LIKE batchdetl.currency_code, 
	conv_qty LIKE batchdetl.conv_qty 
END RECORD 

DEFINE modu_rec_detldata 
RECORD 
	post_acct_code LIKE batchdetl.acct_code, 
	desc_text LIKE batchdetl.desc_text, 
	debit_amt LIKE batchdetl.debit_amt, 
	credit_amt LIKE batchdetl.credit_amt 
END RECORD 

DEFINE modu_rec_detltax 
RECORD 
	tax_code LIKE invoicedetl.tax_code, 
	ext_tax_amt LIKE invoicedetl.ext_tax_amt 
END RECORD 

DEFINE modu_rec_taxtemp 
RECORD 
	tax_acct_code LIKE batchdetl.acct_code, 
	tax_amt LIKE invoicedetl.ext_tax_amt 
END RECORD 

DEFINE modu_rec_current 
RECORD 
	cust_type LIKE customer.type_code, 
	ar_acct_code LIKE arparms.ar_acct_code, 
	freight_acct_code LIKE arparms.freight_acct_code, 
	lab_acct_code LIKE arparms.lab_acct_code, 
	tax_acct_code LIKE arparms.tax_acct_code, 
	disc_acct_code LIKE arparms.disc_acct_code, 
	exch_acct_code LIKE arparms.exch_acct_code, 
	bal_acct_code LIKE arparms.ar_acct_code, 
	tran_type_ind LIKE batchdetl.tran_type_ind, 
	freight_amt LIKE invoicehead.freight_amt, 
	freight_tax_code LIKE invoicehead.freight_tax_code, 
	freight_tax_amt LIKE invoicehead.freight_tax_amt, 
	hand_amt LIKE invoicehead.hand_amt, 
	hand_tax_code LIKE invoicehead.hand_tax_code, 
	hand_tax_amt LIKE invoicehead.hand_tax_amt, 
	disc_amt LIKE invoicehead.disc_amt, 
	jour_code LIKE batchhead.jour_code, 
	jour_num LIKE batchhead.jour_num, 
	ref_num LIKE batchdetl.ref_num, 
	base_debit_amt LIKE batchdetl.debit_amt, 
	base_credit_amt LIKE batchdetl.credit_amt, 
	currency_code LIKE currency.currency_code, 
	exch_ref_code LIKE exchangevar.ref_code 
END RECORD 

DEFINE modu_counter SMALLINT --scrn, 
DEFINE modu_per_post SMALLINT 
DEFINE modu_doit CHAR(1) 
DEFINE modu_try_again CHAR(1) 
DEFINE modu_sel_text CHAR(900) 
DEFINE modu_where_text STRING #char(900) 
DEFINE modu_client_cust_code LIKE customer.cust_code 
#DEFINE glob_rpt_date date #not used
DEFINE modu_rpt_time char(10) #only used in one LET statement... may be NOT really used.. 
DEFINE modu_its_ok INTEGER 
DEFINE modu_err_message CHAR(80) 
DEFINE modu_totaller money(15,2) 
DEFINE modu_cost_totaller money(15,2) 
DEFINE modu_disc_totaller money(15,2) 
#DEFINE glob_post_text CHAR(80)
#DEFINE glob_err_text CHAR(80)
DEFINE modu_inv_num LIKE invoicehead.inv_num 
DEFINE modu_cash_num LIKE cashreceipt.cash_num 
DEFINE modu_cred_num LIKE credithead.cred_num 
#DEFINE modu_rec_tmp_poststatus RECORD LIKE poststatus.* #not used
#DEFINE glob_rec_poststatus RECORD LIKE poststatus.*
DEFINE modu_stat_code LIKE poststatus.status_code 
#DEFINE modu_ans CHAR(1) #not used
#DEFINE glob_in_trans SMALLINT
DEFINE modu_posting_needed SMALLINT 
DEFINE modu_post_status LIKE poststatus.status_code 
#DEFINE glob_posted_journal LIKE batchhead.jour_num
DEFINE modu_select_text CHAR(3000) 
DEFINE modu_tran_type1_ind LIKE exchangevar.tran_type1_ind 
DEFINE modu_ref1_num LIKE exchangevar.ref1_num 
DEFINE modu_tran_type2_ind LIKE exchangevar.tran_type2_ind 
DEFINE modu_ref2_num LIKE exchangevar.ref2_num 
DEFINE modu_rec_exchangevar RECORD LIKE exchangevar.* 
#DEFINE glob_one_trans SMALLINT
DEFINE modu_set_retry SMALLINT 
#DEFINE glob_st_code SMALLINT
DEFINE modu_tmp_text CHAR(8) 
DEFINE modu_conv_qty LIKE invoicehead.conv_qty 
DEFINE modu_sv_conv_qty LIKE invoicehead.conv_qty 
DEFINE modu_again SMALLINT 

#######################################################
# FUNCTION AS7_main()
#
# \brief module : AS7.4gl
# Purpose : Customer History AND General Ledger Post Program
#######################################################
FUNCTION AS7_main()
	DEFER QUIT 
	DEFER INTERRUPT 
 
	CALL setModuleId("AS7") 
	CALL startlog(get_settings_logPath_forFile("postlog.AR")) 

	SELECT * INTO glob_rec_poststatus.* FROM poststatus 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND module_code = "AR" 

	IF STATUS THEN 
		CALL fgl_winmessage("Configuration Error - PostStatus not found",kandoomsg2("U",3507,""),"ERROR") # 3507 "Status cannot be found - cannot post - ABORTING!"
		EXIT PROGRAM 
	ELSE 
		LET glob_st_code = glob_rec_poststatus.status_code 
		LET modu_post_status = glob_rec_poststatus.status_code 
		IF glob_rec_poststatus.post_running_flag = "Y" THEN 
		#Hack to overcome my DB problem
			CALL fgl_winmessage("ERROR",kandoomsg2("U",7007,glob_rec_poststatus.user_code),"ERROR") #7007 "The user value IS already running this posting program."
			IF promptTF("Reset this poststatus?","Do you want reset this existing (if invalid) poststatus in the database ?\nNote: Only choose OK AFTER you have consulted with your database administrator",FALSE) THEN				
				UPDATE poststatus SET post_running_flag = "N" 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND module_code = "AR" 
				#DELETE FROM poststatus
				#WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				#AND module_code = "AR" 
			END IF
		#END OF HACK
			CALL fgl_winmessage("Exit","Exit this program module","info") 
			EXIT PROGRAM
		END IF 

		IF modu_post_status < 99 THEN 
			# 3509 "   Error Has Occurred In Previous Post - ",
			#      " Automatic Rollback will be commenced"
			CALL fgl_winmessage("ERROR",kandoomsg2("U",3509,""),"ERROR") 
			CALL disp_poststatus("AR") 
		END IF 

	END IF 

	LET modu_sl_id = "AR" 
	LET modu_all_ok = 1 

	IF glob_rec_arparms.detail_to_gl_flag IS NULL THEN 
		LET glob_rec_arparms.detail_to_gl_flag = "Y" 
	END IF 

	IF NOT fgl_find_table("posttemp") THEN	
		CREATE TEMP TABLE posttemp (ref_num INTEGER, 
		ref_text CHAR(10), 
		post_acct_code CHAR(18), 
		desc_text CHAR(40), 
		debit_amt money(14,2), 
		credit_amt money(14,2), 
		base_debit_amt money(14,2), 
		base_credit_amt money(14,2), 
		currency_code CHAR(3), 
		conv_qty FLOAT, 
		tran_date DATE, 
		stats_qty DECIMAL(15,3), 
		ar_acct_code CHAR(18) ) with no LOG 
		CREATE INDEX posttemp_idx1 ON posttemp(ar_acct_code) 
	END IF

	IF NOT fgl_find_table("taxtemp") THEN 
		CREATE TEMP TABLE taxtemp (
			tax_acct_code CHAR(18), 
		tax_amt money(16,2)
		) with no LOG 
	END IF

	IF NOT fgl_find_table("posterrors") THEN 
		CREATE TEMP TABLE posterrors(textline CHAR(80)) WITH NO LOG
	END IF 

	OPEN WINDOW A176 with FORM "A176" 
	CALL windecoration_a("A176") 
	CALL start_post() 
	CLOSE WINDOW A176 

END FUNCTION 
#######################################################
# END FUNCTION AS7_main()
#######################################################


#######################################################
# FUNCTION get_datasource_posting(p_filter)
#
#
#######################################################
FUNCTION get_datasource_posting(p_filter) 
	DEFINE p_filter boolean 
	DEFINE l_arr_rec_period DYNAMIC ARRAY OF RECORD #array[400] OF 
		year_num SMALLINT, 
		period_num SMALLINT, 
		post_req CHAR(1) 
	END RECORD 
	DEFINE l_idx SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	IF p_filter THEN 

		MESSAGE kandoomsg2("U",1001,"") #1001 Enter Selection Criteria;  OK TO Continue.
		CONSTRUCT BY NAME modu_where_text ON year_num, period_num 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","AS7","construct-customer") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET modu_where_text = " 1=1 " 
		END IF 

	ELSE 
		LET modu_where_text = " 1=1 " 
	END IF 

	LET modu_sel_text = "SELECT unique year_num, ", 
		" period_num ", 
		"FROM period ", 
		"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND ", modu_where_text CLIPPED, " ", 
		"ORDER BY year_num, period_num " 

	PREPARE q_period FROM modu_sel_text 
	DECLARE c_period CURSOR FOR q_period 

	LET l_idx = 0 

	FOREACH c_period INTO 
		modu_rec_period.year_num, 
		modu_rec_period.period_num 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_period[l_idx].year_num = modu_rec_period.year_num 
		LET l_arr_rec_period[l_idx].post_req = " " 
		LET l_arr_rec_period[l_idx].period_num = modu_rec_period.period_num 

		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF	
	END FOREACH 

	IF l_idx = 0 THEN 
		ERROR kandoomsg2("U",3512,"") # 3512 "You must SELECT a VALID year AND period"
		RETURN FALSE 
	END IF 

	RETURN l_arr_rec_period 
END FUNCTION 
#######################################################
# END FUNCTION get_datasource_posting(p_filter)
#######################################################


#######################################################
# FUNCTION start_post()
#
#
#######################################################
FUNCTION start_post() 
	DEFINE l_arr_rec_period DYNAMIC ARRAY OF RECORD #array[400] OF 
		year_num SMALLINT, 
		period_num SMALLINT, 
		post_req CHAR(1) 
	END RECORD 
	DEFINE l_idx SMALLINT 
	DEFINE l_j SMALLINT 
	DEFINE l_tmp_year LIKE period.year_num 
	DEFINE l_tmp_period LIKE period.period_num 

	LET modu_again = false 

	DISPLAY ARRAY l_arr_rec_period TO sr_period.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","AS7","inp-period") 
			CALL dialog.setActionHidden("ACCEPT",TRUE) #hide accept/apply 
			CALL l_arr_rec_period.clear() 
			CALL get_datasource_posting(false) RETURNING l_arr_rec_period 
			CALL check_for_post_required(l_arr_rec_period) RETURNING l_arr_rec_period 
			MESSAGE kandoomsg2("U",3526,"") #3526 Press ENTER on line TO post;  F10 TO Check.

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "FILTER" 
			CALL l_arr_rec_period.clear() 
			CALL get_datasource_posting(true) RETURNING l_arr_rec_period 
			CALL check_for_post_required(l_arr_rec_period) RETURNING l_arr_rec_period 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			#LET scrn = scr_line()

			--      AFTER FIELD year_num
			--         IF arr_curr() >= arr_count()
			--         AND fgl_lastkey() = fgl_keyval("down") THEN
			--            MESSAGE kandoomsg2("U",9001,"")
			--            #9001 There are no more rows in the direction you are going.
			--            NEXT FIELD year_num
			--         END IF

			{
						ON ACTION "Check" --Check available periods for cheque posting
			--ON KEY (F10) --Check available periods for cheque posting
			         LET l_idx = arr_curr()
			#LET scrn = scr_line()
			         MESSAGE kandoomsg2("R",1507,"")
			#1507 Checking posting periods;  Please wait.
			         FOR modu_i=1 TO arr_count()
			            LET modu_foundit = FALSE
			            LET l_arr_rec_period[modu_i].post_req = "N"
			            DECLARE postin CURSOR FOR
			               SELECT unique period_num INTO modu_per_post FROM invoicehead
			                WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
			                  AND posted_flag = "N"
			                  AND period_num = l_arr_rec_period[modu_i].period_num
			                  AND year_num = l_arr_rec_period[modu_i].year_num

			            FOREACH postin
			               LET l_arr_rec_period[modu_i].post_req = "Y"
			               LET modu_foundit = TRUE
			               EXIT FOREACH
			            END FOREACH

			            IF NOT modu_foundit THEN
			               DECLARE postmo CURSOR FOR
			                  SELECT unique period_num INTO modu_per_post FROM credithead
			                   WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
			                     AND posted_flag = "N"
			                     AND period_num = l_arr_rec_period[modu_i].period_num
			                     AND year_num = l_arr_rec_period[modu_i].year_num

			               FOREACH postmo
			                  LET l_arr_rec_period[modu_i].post_req = "Y"
			                  LET modu_foundit = TRUE
			                  EXIT FOREACH
			               END FOREACH

			            END IF

			            IF NOT modu_foundit THEN
			               DECLARE postcr CURSOR FOR
			               SELECT period_num INTO modu_per_post FROM cashreceipt
			                WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
			                  AND posted_flag = "N"
			                  AND period_num = l_arr_rec_period[modu_i].period_num
			                  AND year_num = l_arr_rec_period[modu_i].year_num
			               FOREACH postcr
			                  LET l_arr_rec_period[modu_i].post_req = "Y"
			                  LET modu_foundit = TRUE
			                  EXIT FOREACH
			               END FOREACH
			            END IF

			            IF modu_foundit = 0 THEN
			               DECLARE postex CURSOR FOR
			                  SELECT period_num INTO modu_per_post FROM exchangevar
			                   WHERE cmpy_code   = glob_rec_kandoouser.cmpy_code
			                     AND posted_flag = "N"
			                     AND period_num  = l_arr_rec_period[modu_i].period_num
			                     AND year_num    = l_arr_rec_period[modu_i].year_num
			                     AND source_ind = "A"
			               FOREACH postex
			                  LET l_arr_rec_period[modu_i].post_req = "Y"
			                  LET modu_foundit = 1
			                  EXIT FOREACH
			               END FOREACH
			            END IF

			            IF modu_foundit = 0 THEN
			               LET modu_posting_needed = 0
			               SELECT count(*) INTO modu_posting_needed FROM postinvhead
			                WHERE postinvhead.cmpy_code = glob_rec_kandoouser.cmpy_code
			                  AND (postinvhead.period_num = l_arr_rec_period[modu_i].period_num
			                       AND postinvhead.year_num = l_arr_rec_period[modu_i].year_num)
			               IF NOT modu_posting_needed THEN
			                  SELECT count(*) INTO modu_posting_needed FROM postcashrcpt
			                   WHERE postcashrcpt.cmpy_code = glob_rec_kandoouser.cmpy_code
			                     AND (postcashrcpt.period_num = l_arr_rec_period[modu_i].period_num
			                          AND postcashrcpt.year_num = l_arr_rec_period[modu_i].year_num)
			               END IF
			               IF NOT modu_posting_needed THEN
			                  SELECT count(*) INTO modu_posting_needed FROM postcredhead
			                   WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
			                     AND (postcredhead.period_num = l_arr_rec_period[modu_i].period_num
			                          AND postcredhead.year_num = l_arr_rec_period[modu_i].year_num)
			               END IF
			               IF NOT modu_posting_needed THEN
			                  SELECT count(*) INTO modu_posting_needed FROM postexchvar
			                   WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
			                     AND (postexchvar.period_num = l_arr_rec_period[modu_i].period_num
			                          AND postexchvar.year_num = l_arr_rec_period[modu_i].year_num)
			               END IF
			               IF modu_posting_needed THEN
			                  LET l_arr_rec_period[modu_i].post_req = "Y"
			               END IF
			            END IF
			         END FOR
			#LET l_j = 1
			#call fgl_winmessage("needs debugging","needs fixing","info")
			#FOR modu_i = (l_idx - scrn + 1) TO ((l_idx - scrn + 1) + 12 - 1)
			#   DISPLAY l_arr_rec_period[modu_i].* TO sr_period[l_j].*
			#
			#   LET l_j = l_j + 1
			#   IF l_arr_rec_period[modu_i+1].year_num = 0 THEN
			#      EXIT FOR
			#   END IF
			#END FOR
			         MESSAGE kandoomsg2("U",3526,"")
			#3526 Press ENTER on line TO post;  F10 TO Check.
			}

		ON ACTION ("POST","ACCEPT","DOUBLECLICK") #post ar transations FOR the CURRENT ROW (year/period) 
			LET l_idx = arr_curr() 
			--BEFORE FIELD period_num
			LET glob_fisc_period = l_arr_rec_period[l_idx].period_num 
			LET glob_fisc_year = l_arr_rec_period[l_idx].year_num 
			IF modu_post_status < 99 THEN 
				SELECT post_year_num,post_period_num 
				INTO l_tmp_year,l_tmp_period 
				FROM poststatus 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND module_code = "AR" 

				IF l_tmp_year != glob_fisc_year 
				OR l_tmp_period != glob_fisc_period THEN 

					LET modu_tmp_text = l_tmp_year USING "####"," ",l_tmp_period USING "###" 
					ERROR kandoomsg2("U",3516,modu_tmp_text) # 3516 "You must post ",l_tmp_year," ",l_tmp_period 
					CALL fgl_winmessage("Corrupted Data","Your data are not valid (may corrupted)\nExit Application","error") 
					LET modu_again = true 
					EXIT DISPLAY 
				END IF 
			END IF 

			SELECT * INTO glob_rec_poststatus.* FROM poststatus 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND module_code = "AR" 

			IF glob_rec_poststatus.post_running_flag = "Y" THEN 
				ERROR kandoomsg2("U",7007,glob_rec_poststatus.user_code) #7007 "The user value IS already running this posting program." 
				EXIT PROGRAM 
			END IF 

			UPDATE poststatus 
			SET post_running_flag = "Y" 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND module_code = "AR" 

			CALL AS7_post_AR() 
			UPDATE poststatus SET post_running_flag = "N" 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND module_code = "AR" 

	END DISPLAY 

	IF int_flag OR quit_flag THEN 
		LET quit_flag = false 
		LET int_flag = false 
	END IF 
	IF modu_again THEN 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 

END FUNCTION 
#######################################################
# END FUNCTION start_post()
#######################################################


#######################################################
# FUNCTION check_for_post_required()
#
# The code was extracted from FUNCTION start_post()
# It shows, what Year-Periods have got available AR transactions ready for posting
#######################################################
FUNCTION check_for_post_required(p_arr_rec_period) 
	DEFINE p_arr_rec_period DYNAMIC ARRAY OF RECORD #array[400] OF 
		year_num SMALLINT, 
		period_num SMALLINT, 
		post_req CHAR(1) 
	END RECORD 
	DEFINE l_msgresp LIKE language.yes_flag 

	--         LET l_idx = arr_curr()
	#LET scrn = scr_line()
	MESSAGE kandoomsg2("R",1507,"") #1507 Checking posting periods;  Please wait.

	FOR modu_i=1 TO p_arr_rec_period.getlength() --arr_count() 
		LET modu_foundit = false 
		LET p_arr_rec_period[modu_i].post_req = "N" 
		DECLARE fc_postin CURSOR FOR 
		SELECT unique period_num INTO modu_per_post FROM invoicehead 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND posted_flag = "N" 
		AND period_num = p_arr_rec_period[modu_i].period_num 
		AND year_num = p_arr_rec_period[modu_i].year_num 

		FOREACH fc_postin 
			LET p_arr_rec_period[modu_i].post_req = "Y" 
			LET modu_foundit = true 
			EXIT FOREACH 
		END FOREACH 

		IF NOT modu_foundit THEN 
			DECLARE fc_postmo CURSOR FOR 
			SELECT unique period_num INTO modu_per_post FROM credithead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND posted_flag = "N" 
			AND period_num = p_arr_rec_period[modu_i].period_num 
			AND year_num = p_arr_rec_period[modu_i].year_num 

			FOREACH fc_postmo 
				LET p_arr_rec_period[modu_i].post_req = "Y" 
				LET modu_foundit = true 
				EXIT FOREACH 
			END FOREACH 

		END IF 

		IF NOT modu_foundit THEN 
			DECLARE fc_postcr CURSOR FOR 
			SELECT period_num INTO modu_per_post FROM cashreceipt 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND posted_flag = "N" 
			AND period_num = p_arr_rec_period[modu_i].period_num 
			AND year_num = p_arr_rec_period[modu_i].year_num 
			FOREACH fc_postcr 
				LET p_arr_rec_period[modu_i].post_req = "Y" 
				LET modu_foundit = true 
				EXIT FOREACH 
			END FOREACH 
		END IF 

		IF modu_foundit = 0 THEN 
			DECLARE fc_postex CURSOR FOR 
			SELECT period_num INTO modu_per_post FROM exchangevar 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND posted_flag = "N" 
			AND period_num = p_arr_rec_period[modu_i].period_num 
			AND year_num = p_arr_rec_period[modu_i].year_num 
			AND source_ind = "A" 

			FOREACH fc_postex 
				LET p_arr_rec_period[modu_i].post_req = "Y" 
				LET modu_foundit = 1 
				EXIT FOREACH 
			END FOREACH 
		END IF 

		IF modu_foundit = 0 THEN 
			LET modu_posting_needed = 0 
			SELECT count(*) INTO modu_posting_needed FROM postinvhead 
			WHERE postinvhead.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND (postinvhead.period_num = p_arr_rec_period[modu_i].period_num 
			AND postinvhead.year_num = p_arr_rec_period[modu_i].year_num) 
			IF NOT modu_posting_needed THEN 
				SELECT count(*) INTO modu_posting_needed FROM postcashrcpt 
				WHERE postcashrcpt.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND (postcashrcpt.period_num = p_arr_rec_period[modu_i].period_num 
				AND postcashrcpt.year_num = p_arr_rec_period[modu_i].year_num) 
			END IF 

			IF NOT modu_posting_needed THEN 
				SELECT count(*) INTO modu_posting_needed FROM postcredhead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND (postcredhead.period_num = p_arr_rec_period[modu_i].period_num 
				AND postcredhead.year_num = p_arr_rec_period[modu_i].year_num) 
			END IF 
			IF NOT modu_posting_needed THEN 
				SELECT count(*) INTO modu_posting_needed FROM postexchvar 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND (postexchvar.period_num = p_arr_rec_period[modu_i].period_num 
				AND postexchvar.year_num = p_arr_rec_period[modu_i].year_num) 
			END IF 
			IF modu_posting_needed THEN 
				LET p_arr_rec_period[modu_i].post_req = "Y" 
			END IF 
		END IF 
	END FOR 

	RETURN p_arr_rec_period 

END FUNCTION 
#######################################################
# END FUNCTION check_for_post_required()
#######################################################


#######################################################
# FUNCTION get_cust_accts(p_ord_ind)
#
# Receivables control, handling, freight, tax (FOR NULL tax codes) AND
# discount posting accounts determined by customer type unless NULL
#######################################################
FUNCTION get_cust_accts(p_ord_ind) 
	DEFINE p_ord_ind LIKE ordhead.ord_ind 
	DEFINE l_msgresp LIKE language.yes_flag 
	--DEFINE l_ord_num LIKE invoicehead.ord_num 
	--DEFINE l_rma_num LIKE credithead.rma_num 
	DEFINE l_freight_acct_code LIKE customertype.freight_acct_code 

	IF get_debug() THEN 
		DISPLAY "#### FUNCTION get_cust_accts() START" 
	END IF 

	SELECT 
		ar_acct_code, 
		freight_acct_code, 
		lab_acct_code, 
		tax_acct_code, 
		disc_acct_code, 
		exch_acct_code 
	INTO 
		modu_rec_current.ar_acct_code, 
		modu_rec_current.freight_acct_code, 
		modu_rec_current.lab_acct_code, 
		modu_rec_current.tax_acct_code, 
		modu_rec_current.disc_acct_code, 
		modu_rec_current.exch_acct_code 
	FROM customertype 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND type_code = modu_rec_current.cust_type 

	IF status = NOTFOUND THEN 
		LET modu_rec_current.ar_acct_code = NULL 
		LET modu_rec_current.freight_acct_code = NULL 
		LET modu_rec_current.lab_acct_code = NULL 
		LET modu_rec_current.tax_acct_code = NULL 
		LET modu_rec_current.disc_acct_code = NULL 
		LET modu_rec_current.exch_acct_code = NULL 
	ELSE 
		IF p_ord_ind matches '[6-9]' AND p_ord_ind IS NOT NULL THEN 
			# Should only get ORDER type indicator account if
			# currently processing Invoices OR Credits.
			CALL get_ordacct(glob_rec_kandoouser.cmpy_code,"customertype","freight_acct_code", modu_rec_current.cust_type,p_ord_ind) 
			RETURNING l_freight_acct_code 
			IF l_freight_acct_code IS NOT NULL THEN 
				LET modu_rec_current.freight_acct_code = l_freight_acct_code 
			END IF 
		END IF 
	END IF 

	IF modu_rec_current.ar_acct_code IS NULL OR modu_rec_current.ar_acct_code = " " THEN 
		LET modu_rec_current.ar_acct_code = glob_rec_arparms.ar_acct_code 
	END IF 

	IF modu_rec_current.freight_acct_code IS NULL OR modu_rec_current.freight_acct_code = " " THEN 
		IF p_ord_ind matches '[6-9]' AND p_ord_ind IS NOT NULL THEN 
			CALL get_ordacct(glob_rec_kandoouser.cmpy_code,"arparms","freight_acct_code", "AZP",p_ord_ind) 
			RETURNING modu_rec_current.freight_acct_code 
		END IF 
		IF modu_rec_current.freight_acct_code IS NULL THEN 
			LET modu_rec_current.freight_acct_code = glob_rec_arparms.freight_acct_code 
		END IF 
	END IF 

	IF modu_rec_current.lab_acct_code IS NULL OR modu_rec_current.lab_acct_code = " " THEN 
		LET modu_rec_current.lab_acct_code = glob_rec_arparms.lab_acct_code 
	END IF 

	IF modu_rec_current.tax_acct_code IS NULL OR modu_rec_current.tax_acct_code = " " THEN 
		LET modu_rec_current.tax_acct_code = glob_rec_arparms.tax_acct_code 
	END IF 

	IF modu_rec_current.disc_acct_code IS NULL OR modu_rec_current.disc_acct_code = " " THEN 
		LET modu_rec_current.disc_acct_code = glob_rec_arparms.disc_acct_code 
	END IF 

	IF modu_rec_current.exch_acct_code IS NULL OR modu_rec_current.exch_acct_code = " " THEN 
		LET modu_rec_current.exch_acct_code = glob_rec_arparms.exch_acct_code 
	END IF 

	LET modu_prev_cust_type = modu_rec_current.cust_type 
	IF p_ord_ind IS NOT NULL THEN 
		LET modu_prev_ord_ind = p_ord_ind 
	END IF 

	IF get_debug() THEN 
		DISPLAY "#### FUNCTION get_cust_accts() END" 
	END IF 
END FUNCTION 
#######################################################
# END FUNCTION get_cust_accts(p_ord_ind)
#######################################################


#######################################################
# FUNCTION create_gl_batches()
#
#
#######################################################
FUNCTION create_gl_batches() 

	DEFINE l_rec_data RECORD 
		tran_type_ind LIKE batchdetl.tran_type_ind, 
		ref_num LIKE batchdetl.ref_num, 
		ref_text LIKE batchdetl.ref_text, 
		acct_code LIKE batchdetl.acct_code, 
		desc_text LIKE batchdetl.desc_text, 
		for_debit_amt LIKE batchdetl.for_debit_amt, 
		for_credit_amt LIKE batchdetl.for_credit_amt, 
		base_debit_amt LIKE batchdetl.debit_amt, 
		base_credit_amt LIKE batchdetl.credit_amt, 
		currency_code LIKE currency.currency_code, 
		conv_qty LIKE rate_exchange.conv_buy_qty, 
		tran_date DATE, 
		stats_qty LIKE batchdetl.stats_qty 
	END RECORD 
	DEFINE l_posted_some SMALLINT 
	DEFINE l_rec_count INTEGER 

	IF get_debug() THEN 
		DISPLAY "#### FUNCTION create_gl_batches() START" 
	END IF 

	GOTO bypass 
	LABEL recovery: 
	IF get_debug() THEN 
		DISPLAY "CALL update_poststatus(TRUE,", trim(STATUS),"\"AR\") - AS7.4gl - invoice()" 
	END IF 

	CALL update_poststatus(TRUE,STATUS,"AR") 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	# batch posting details according TO receivables control account AND
	# currency code (ie. all entries FOR the same currency AND
	# control/balancing account in one batch)
	#DISPLAY "" AT 1,2

	DECLARE p_curs CURSOR with HOLD FOR 
	SELECT unique posttemp.ar_acct_code, posttemp.currency_code 
	FROM posttemp 
	#
	#  - Ensure that all batches have one only balancing entry
	#             by selecting only the transactions that will post TO the
	#             credit OR debit side of the ledger respectively
	#             Note that zero value transactions are legitimate - they
	#             may be statistics only entries hence the third pass FOR
	#             stats only entries
	#
	LET l_posted_some = false 

	IF get_debug() THEN 
		DISPLAY "FOREACH p_curs INTO - FUNCTION create_gl_batches()" 
	END IF 

	FOREACH p_curs INTO modu_rec_current.bal_acct_code, modu_rec_current.currency_code 

		IF get_debug() THEN 
			DISPLAY "FOREACH 1st LINE p_curs INTO - FUNCTION create_gl_batches()" 
		END IF 

		SELECT count(*) INTO l_rec_count FROM posttemp 
		WHERE posttemp.ar_acct_code = modu_rec_current.bal_acct_code 
		AND (posttemp.base_credit_amt > 0 OR posttemp.base_debit_amt < 0) 
		AND posttemp.currency_code = modu_rec_current.currency_code 
		IF l_rec_count IS NULL OR l_rec_count = 0 THEN ELSE 
			LET l_posted_some = true 
			LET modu_rec_bal.acct_code = modu_rec_current.bal_acct_code 
			LET modu_sel_text = " SELECT ", " '", modu_rec_current.tran_type_ind CLIPPED, "', ", 
			" posttemp.ref_num, ", 
			" posttemp.ref_text, ", 
			" posttemp.post_acct_code, ", 
			" posttemp.desc_text, ", 
			" posttemp.debit_amt, ", 
			" posttemp.credit_amt, ", 
			" posttemp.base_debit_amt, ", 
			" posttemp.base_credit_amt, ", 
			" posttemp.currency_code, ", 
			" posttemp.conv_qty, ", 
			" posttemp.tran_date, ", 
			" posttemp.stats_qty ", 
			" FROM posttemp ", 
			" WHERE posttemp.ar_acct_code = '", modu_rec_bal.acct_code CLIPPED, "' ", 
			" AND (posttemp.base_credit_amt > 0 ", 
			"OR posttemp.base_debit_amt < 0) ", 
			" AND posttemp.currency_code = '", modu_rec_current.currency_code CLIPPED, "' " 

			LET modu_rec_current.jour_num = jourintf2(modu_rpt_idx,
			modu_sel_text, 
			modu_rec_bal.*, #	tran_type_ind LIKE batchdetl.tran_type_ind,	acct_code LIKE batchdetl.acct_code,	desc_text LIKE batchdetl.desc_text 
			glob_fisc_period, 
			glob_fisc_year, 
			modu_rec_current.jour_code, 
			"A", 
			modu_rec_current.currency_code, 
			"AR")

			IF modu_rec_current.jour_num = 0 THEN {nothing posted} 
				ERROR kandoomsg2("U",3500,modu_rec_current.tran_type_ind) 
				# 3500 DISPLAY "No entries FOR type ",modu_rec_current.tran_type_ind,
				#              "posted."
				SLEEP 1 
			END IF 
			PREPARE flag_it FROM modu_sel_text 
			DECLARE update_post CURSOR FOR flag_it 

			CASE modu_rec_current.tran_type_ind 
				WHEN TRAN_TYPE_INVOICE_IN {invoices} 
					FOREACH update_post INTO l_rec_data.* 
						UPDATE postinvhead 
						SET jour_num = glob_posted_journal 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND inv_num = l_rec_data.ref_num 
					END FOREACH 

				WHEN "CO" {jm cos} 
					FOREACH update_post INTO l_rec_data.* 
						UPDATE postinvhead 
						SET manifest_num = glob_posted_journal 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND inv_num = l_rec_data.ref_num 
					END FOREACH 

				WHEN TRAN_TYPE_RECEIPT_CA {cash} 
					FOREACH update_post INTO l_rec_data.* 
						UPDATE postcashrcpt 
						SET jour_num = glob_posted_journal 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND cash_num = l_rec_data.ref_num 
					END FOREACH 

				WHEN TRAN_TYPE_CREDIT_CR {credits} 
					FOREACH update_post INTO l_rec_data.* 
						UPDATE postcredhead SET jour_num = glob_posted_journal 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND cred_num = l_rec_data.ref_num 
					END FOREACH 

				WHEN "CCO" {jm cos credits} 
					FOREACH update_post INTO l_rec_data.* 
						UPDATE postcredhead 
						SET rma_num = glob_posted_journal 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND cred_num = l_rec_data.ref_num 
					END FOREACH 

				WHEN "EXA" {credits} 
					FOREACH update_post INTO l_rec_data.* 
						UPDATE postexchvar 
						SET jour_num = glob_posted_journal 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND ref1_num = l_rec_data.ref_num 
						AND ref2_num = l_rec_data.ref_text 
					END FOREACH 
			END CASE 

			IF glob_posted_journal IS NOT NULL THEN 
				LET glob_posted_journal = NULL 
			END IF 
			# check FOR -ve journal number - indicates an error in posting account
			# within the GL batch
			IF modu_rec_current.jour_num < 0 THEN 
				LET modu_all_ok = 0 
			END IF 
		END IF 

		# KC 9/2/96 Now do the debit entries
		SELECT count(*) INTO l_rec_count FROM posttemp 
		WHERE posttemp.ar_acct_code = modu_rec_current.bal_acct_code 
		AND (posttemp.base_debit_amt > 0 OR posttemp.base_credit_amt < 0) 
		AND posttemp.currency_code = modu_rec_current.currency_code 
		IF l_rec_count IS NULL OR l_rec_count = 0 THEN 
		ELSE 
			LET modu_rec_bal.acct_code = modu_rec_current.bal_acct_code 
			LET modu_sel_text = 
				" SELECT '", modu_rec_current.tran_type_ind CLIPPED, "' ,", 
				" posttemp.ref_num, ", 
				" posttemp.ref_text, ", 
				" posttemp.post_acct_code, ", 
				" posttemp.desc_text, ", 
				" posttemp.debit_amt, ", 
				" posttemp.credit_amt, ", 
				" posttemp.base_debit_amt, ", 
				" posttemp.base_credit_amt, ", 
				" posttemp.currency_code, ", 
				" posttemp.conv_qty, ", 
				" posttemp.tran_date, ", 
				" posttemp.stats_qty ", 
				" FROM posttemp ", 
				" WHERE posttemp.ar_acct_code = '", modu_rec_bal.acct_code CLIPPED, "' ", 
				" AND (posttemp.base_debit_amt > 0 OR posttemp.base_credit_amt < 0) ", 
				" AND posttemp.currency_code = '", modu_rec_current.currency_code, "' " 

			LET modu_rec_current.jour_num = jourintf2(
				modu_rpt_idx,
				modu_sel_text, 
				modu_rec_bal.*, 
				glob_fisc_period, 
				glob_fisc_year, 
				modu_rec_current.jour_code, 
				"A", 
				modu_rec_current.currency_code, 
				"AR")
			 
			IF modu_rec_current.jour_num = 0 THEN {nothing posted} 
				ERROR kandoomsg2("U",3500,modu_rec_current.tran_type_ind) 
				# 3500 DISPLAY "No entries FOR type ",modu_rec_current.tran_type_ind,
				#              "posted."
				SLEEP 1 
			END IF 
			PREPARE flag_db FROM modu_sel_text 
			DECLARE update_db CURSOR FOR flag_db 

			CASE modu_rec_current.tran_type_ind 
				WHEN TRAN_TYPE_INVOICE_IN {invoices} 
					FOREACH update_db INTO l_rec_data.* 
						UPDATE postinvhead 
						SET jour_num = glob_posted_journal 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND inv_num = l_rec_data.ref_num 
					END FOREACH 

				WHEN TRAN_TYPE_RECEIPT_CA {cash} 
					FOREACH update_db INTO l_rec_data.* 
						UPDATE postcashrcpt SET jour_num = glob_posted_journal 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND cash_num = l_rec_data.ref_num 
					END FOREACH 
					
				WHEN TRAN_TYPE_CREDIT_CR {credits} 
					FOREACH update_db INTO l_rec_data.* 
						UPDATE postcredhead 
						SET jour_num = glob_posted_journal 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND cred_num = l_rec_data.ref_num 
					END FOREACH 
					
				WHEN "EXA" {credits} 
					FOREACH update_db INTO l_rec_data.* 
						UPDATE postexchvar 
						SET jour_num = glob_posted_journal 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND ref1_num = l_rec_data.ref_num 
						AND ref2_num = l_rec_data.ref_text 
					END FOREACH 
			END CASE 

			IF glob_posted_journal IS NOT NULL THEN 
				LET glob_posted_journal = NULL 
			END IF 
			# check FOR -ve journal number - indicates an error in posting account
			# within the GL batch
			IF modu_rec_current.jour_num < 0 THEN 
				LET modu_all_ok = 0 
			END IF 
			# DISPLAY GL batches as created
		END IF 

		SELECT count(*) INTO l_rec_count FROM posttemp 
		WHERE posttemp.ar_acct_code = modu_rec_current.bal_acct_code 
		AND (posttemp.base_debit_amt = 0 AND posttemp.base_credit_amt = 0) 
		AND posttemp.stats_qty <> 0 
		AND posttemp.currency_code = modu_rec_current.currency_code 
		IF l_rec_count IS NULL OR l_rec_count = 0 THEN 
		ELSE 
			LET modu_rec_bal.acct_code = modu_rec_current.bal_acct_code 
			LET modu_sel_text = 
				" SELECT '", modu_rec_current.tran_type_ind CLIPPED, "' ,", 
				" posttemp.ref_num, ", 
				" posttemp.ref_text, ", 
				" posttemp.post_acct_code, ", 
				" posttemp.desc_text, ", 
				" posttemp.debit_amt, ", 
				" posttemp.credit_amt, ", 
				" posttemp.base_debit_amt, ", 
				" posttemp.base_credit_amt, ", 
				" posttemp.currency_code, ", 
				" posttemp.conv_qty, ", 
				" posttemp.tran_date, ", 
				" posttemp.stats_qty ", 
				" FROM posttemp ", 
				" WHERE posttemp.ar_acct_code = '", modu_rec_bal.acct_code CLIPPED, "' ", 
				" AND (posttemp.base_debit_amt = 0 ", "AND posttemp.base_credit_amt = 0) ", 
				" AND posttemp.stats_qty <> 0", 
				" AND posttemp.currency_code = '", modu_rec_current.currency_code, "' " 

			IF get_debug() THEN 
				DISPLAY "CALL jourintf2() 3 - FUNCTION create_gl_batches()" 
			END IF 

			LET modu_rec_current.jour_num = jourintf2(modu_rpt_idx,
			modu_sel_text, 
			modu_rec_bal.*, 
			glob_fisc_period, 
			glob_fisc_year, 
			modu_rec_current.jour_code, 
			"A", 
			modu_rec_current.currency_code, 
			"AR") 

			IF modu_rec_current.jour_num = 0 THEN {nothing posted} 
				ERROR kandoomsg2("U",3500,modu_rec_current.tran_type_ind) 
				# 3500 DISPLAY "No entries FOR type ",modu_rec_current.tran_type_ind,
				#              "posted."
				SLEEP 1 
			END IF 

			PREPARE flag_stat FROM modu_sel_text 
			DECLARE update_stat CURSOR FOR flag_stat 

			CASE modu_rec_current.tran_type_ind 
				WHEN TRAN_TYPE_INVOICE_IN {invoices} 
					FOREACH update_stat INTO l_rec_data.* 
						UPDATE postinvhead 
						SET jour_num = glob_posted_journal 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND inv_num = l_rec_data.ref_num 
					END FOREACH 

				WHEN TRAN_TYPE_RECEIPT_CA {cash} 
					FOREACH update_stat INTO l_rec_data.* 
						UPDATE postcashrcpt SET jour_num = glob_posted_journal 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND cash_num = l_rec_data.ref_num 
					END FOREACH 

				WHEN TRAN_TYPE_CREDIT_CR {credits} 
					FOREACH update_stat INTO l_rec_data.* 
						UPDATE postcredhead 
						SET jour_num = glob_posted_journal 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND cred_num = l_rec_data.ref_num 
					END FOREACH 

				WHEN "EXA" {credits} 
					FOREACH update_stat INTO l_rec_data.* 
						UPDATE postexchvar 
						SET jour_num = glob_posted_journal 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND ref1_num = l_rec_data.ref_num 
						AND ref2_num = l_rec_data.ref_text 
					END FOREACH 
			END CASE 

			IF glob_posted_journal IS NOT NULL THEN 
				LET glob_posted_journal = NULL 
			END IF 
			# check FOR -ve journal number - indicates an error in posting account
			# within the GL batch
			IF modu_rec_current.jour_num < 0 THEN 
				LET modu_all_ok = 0 
			END IF 
		END IF 

		IF get_debug() THEN 
			DISPLAY "FOREACH LAST LINE p_curs INTO - FUNCTION create_gl_batches()" 
		END IF 

	END FOREACH 

	IF get_debug() THEN 
		DISPLAY "FOREACH END LINE p_curs INTO - FUNCTION create_gl_batches()" 
	END IF 

	IF NOT l_posted_some THEN 
		ERROR kandoomsg2("U",3501,"") # 3501 "No rows found TO post"
		SLEEP 1 
	END IF 

	IF get_debug() THEN 
		DISPLAY "#### FUNCTION create_gl_batches() END" 
	END IF 
END FUNCTION 
#######################################################
# END FUNCTION create_gl_batches()
#######################################################


#######################################################
# FUNCTION create_summ_batches()
#
#
#######################################################
FUNCTION create_summ_batches() 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_data RECORD 
		tran_type_ind LIKE batchdetl.tran_type_ind, 
		ref_num LIKE batchdetl.ref_num, 
		ref_text LIKE batchdetl.ref_text, 
		acct_code LIKE batchdetl.acct_code, 
		desc_text LIKE batchdetl.desc_text, 
		for_debit_amt LIKE batchdetl.for_debit_amt, 
		for_credit_amt LIKE batchdetl.for_credit_amt, 
		base_debit_amt LIKE batchdetl.debit_amt, 
		base_credit_amt LIKE batchdetl.credit_amt, 
		currency_code LIKE currency.currency_code, 
		conv_qty LIKE rate_exchange.conv_buy_qty, 
		tran_date DATE, 
		stats_qty LIKE batchdetl.stats_qty 
	END RECORD 
	DEFINE l_posted_some SMALLINT 
	DEFINE l_upd_sel_text CHAR(500) 
	DEFINE l_rec_count INTEGER 

	IF get_debug() THEN 
		DISPLAY "#### FUNCTION create_summ_batches()" 
	END IF 

	GOTO bypass 
	LABEL recovery: 

	IF get_debug() THEN 
		DISPLAY "CALL update_poststatus(TRUE,", trim(STATUS),"\"AR\") - AS7.4gl - invoice()" 
	END IF 

	CALL update_poststatus(TRUE,STATUS,"AR") 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 


	# batch posting details according TO receivables control account,
	# AND currency code but with one summary entry per
	# posting account/date combination

	#DISPLAY "" AT 1,2
	DECLARE s_curs CURSOR with HOLD FOR 
	SELECT unique posttemp.ar_acct_code, 
	posttemp.currency_code, 
	posttemp.conv_qty 
	FROM posttemp 

	#
	#  Ensure that all batches have one only balancing entry
	#             by selecting only the transactions that will post TO the
	#             credit OR debit side of the ledger respectively
	#             Note that zero value transactions are legitimate - they
	#             may be statistics only entries hence the third pass FOR
	#             zero debits AND credits

	LET l_posted_some = false 
	FOREACH s_curs INTO modu_rec_current.bal_acct_code, 
		modu_rec_current.currency_code, 
		modu_conv_qty 

		#
		# Check that there are details TO post before entering jourintf2, OTHERWISE
		# the batch number IS allocated AND unused
		#
		SELECT count(*) 
		INTO l_rec_count 
		FROM posttemp 
		WHERE posttemp.ar_acct_code = modu_rec_current.bal_acct_code 
		AND posttemp.currency_code = modu_rec_current.currency_code 
		AND posttemp.conv_qty = modu_conv_qty 
		AND (posttemp.base_credit_amt > 0 OR posttemp.base_debit_amt < 0) 

		IF l_rec_count IS NULL OR l_rec_count = 0 THEN ELSE 
			LET l_posted_some = true 
			LET modu_rec_bal.acct_code = modu_rec_current.bal_acct_code 
			LET modu_sel_text = 
				" SELECT '", modu_rec_current.tran_type_ind CLIPPED, "' ,", 
				" 0, ", 
				" 'Summary', ", 
				" posttemp.post_acct_code, ", 
				" '", modu_passed_desc CLIPPED, "' ,", 
				" sum(posttemp.debit_amt), ", 
				" sum(posttemp.credit_amt), ", 
				" sum(posttemp.base_debit_amt), ", 
				" sum(posttemp.base_credit_amt), ", 
				" posttemp.currency_code, ", 
				" posttemp.conv_qty, ", 
				" posttemp.tran_date, ", 
				" sum(posttemp.stats_qty) ", 
				" FROM posttemp ", 
				" WHERE posttemp.ar_acct_code = '", modu_rec_bal.acct_code CLIPPED, "' ", 
				" AND posttemp.currency_code = '", modu_rec_current.currency_code, "' ", 
				" AND posttemp.conv_qty = ",modu_conv_qty, 
				" AND (posttemp.base_credit_amt > 0 OR posttemp.base_debit_amt < 0)", 
				" group by posttemp.currency_code, ", 
				" posttemp.conv_qty, ", 
				" posttemp.post_acct_code, posttemp.tran_date" 

			IF get_debug() THEN 
				DISPLAY "CALL jourintf2() 4 - FUNCTION create_gl_batches()" 
			END IF 

			LET modu_rec_current.jour_num = jourintf2(modu_rpt_idx,
			modu_sel_text, 
			modu_rec_bal.*, 
			glob_fisc_period, 
			glob_fisc_year, 
			modu_rec_current.jour_code, 
			"A", 
			modu_rec_current.currency_code, 
			"AR") 

			IF modu_rec_current.jour_num = 0 THEN 
				ERROR kandoomsg2("U",3500,modu_rec_current.tran_type_ind) 
				# 3500 "No entries FOR type ",modu_rec_current.tran_type_ind,
				#      "posted."
				SLEEP 1 
			END IF 

			LET l_upd_sel_text = 
				" SELECT posttemp.ref_num, ", 
				" posttemp.ref_text ", 
				" FROM posttemp ", 
				" WHERE posttemp.ar_acct_code = '", modu_rec_bal.acct_code CLIPPED, "' ", 
				" AND posttemp.currency_code = '", modu_rec_current.currency_code, "' ", 
				" AND posttemp.conv_qty = ",modu_conv_qty, 
				" AND (posttemp.base_credit_amt > 0 OR posttemp.base_debit_amt < 0)" 

			PREPARE flag_it1 FROM l_upd_sel_text 
			DECLARE update_post1 CURSOR FOR flag_it1 

			CASE modu_rec_current.tran_type_ind 
				WHEN TRAN_TYPE_INVOICE_IN {invoices} 
					FOREACH update_post1 INTO l_rec_data.ref_num, 
						l_rec_data.ref_text 
						UPDATE postinvhead SET jour_num = glob_posted_journal 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND inv_num = l_rec_data.ref_num 
					END FOREACH 

				WHEN TRAN_TYPE_RECEIPT_CA {cash} 
					FOREACH update_post1 INTO l_rec_data.ref_num, 
						l_rec_data.ref_text 
						UPDATE postcashrcpt SET jour_num = glob_posted_journal 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND cash_num = l_rec_data.ref_num 
					END FOREACH 

				WHEN TRAN_TYPE_CREDIT_CR {credits} 
					FOREACH update_post1 INTO l_rec_data.ref_num, 
						l_rec_data.ref_text 
						UPDATE postcredhead SET jour_num = glob_posted_journal 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND cred_num = l_rec_data.ref_num 
					END FOREACH 

				WHEN "EXA" {credits} 
					FOREACH update_post1 INTO l_rec_data.ref_num, 
						l_rec_data.ref_text 
						UPDATE postexchvar SET jour_num = glob_posted_journal 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND ref1_num = l_rec_data.ref_num 
						AND ref2_num = l_rec_data.ref_text 
					END FOREACH 
			END CASE 

			IF glob_posted_journal IS NOT NULL THEN 
				LET glob_posted_journal = NULL 
			END IF 

			# check FOR -ve journal number - indicates an error in posting account
			# within the GL batch

			IF modu_rec_current.jour_num < 0 THEN 
				LET modu_all_ok = 0 
			END IF 

			# DISPLAY each batch number as created

		END IF 

		#
		# Now do Debits
		SELECT count(*) 
		INTO l_rec_count 
		FROM posttemp 
		WHERE posttemp.ar_acct_code = modu_rec_current.bal_acct_code 
		AND posttemp.currency_code = modu_rec_current.currency_code 
		AND posttemp.conv_qty = modu_conv_qty 
		AND (posttemp.base_debit_amt > 0 OR posttemp.base_credit_amt < 0) 

		IF l_rec_count IS NULL OR l_rec_count = 0 THEN ELSE 
			LET l_posted_some = true 
			LET modu_rec_bal.acct_code = modu_rec_current.bal_acct_code 
			LET modu_sel_text = " SELECT '", modu_rec_current.tran_type_ind CLIPPED, "' ,", 
			" 0, ", 
			" 'Summary' , ", 
			" posttemp.post_acct_code, ", 
			" '", modu_passed_desc CLIPPED, "' ,", 
			" sum(posttemp.debit_amt), ", 
			" sum(posttemp.credit_amt), ", 
			" sum(posttemp.base_debit_amt), ", 
			" sum(posttemp.base_credit_amt), ", 
			" posttemp.currency_code, ", 
			" posttemp.conv_qty, ", 
			" posttemp.tran_date, ", 
			" sum(posttemp.stats_qty) ", 
			" FROM posttemp ", 
			" WHERE posttemp.ar_acct_code = '", modu_rec_bal.acct_code clipped, "' ", 
			" AND posttemp.currency_code = '", modu_rec_current.currency_code, "' ", 
			" AND posttemp.conv_qty = ",modu_conv_qty, 
			" AND (posttemp.base_debit_amt > 0 OR posttemp.base_credit_amt < 0)", 
			" group by posttemp.currency_code, ", 
			" posttemp.conv_qty, ", 
			" posttemp.post_acct_code, posttemp.tran_date" 

			IF get_debug() THEN 
				DISPLAY "CALL jourintf2() 5 - FUNCTION create_gl_batches()" 
			END IF 

			LET modu_rec_current.jour_num = jourintf2(modu_rpt_idx,
			modu_sel_text, 
			modu_rec_bal.*, 
			glob_fisc_period, 
			glob_fisc_year, 
			modu_rec_current.jour_code, 
			"A", 
			modu_rec_current.currency_code, 
			"AR") 

			IF modu_rec_current.jour_num = 0 THEN 
				ERROR kandoomsg2("U",3500,modu_rec_current.tran_type_ind) 
				# 3500 "No entries FOR type ",modu_rec_current.tran_type_ind,
				#      "posted."
				SLEEP 1 
			END IF 


			LET l_upd_sel_text = 
			" SELECT posttemp.ref_num, ", 
			" posttemp.ref_text ", 
			" FROM posttemp ", 
			" WHERE posttemp.ar_acct_code = '", modu_rec_bal.acct_code CLIPPED, "' ", 
			" AND posttemp.currency_code = '", modu_rec_current.currency_code, "' ", 
			" AND posttemp.conv_qty = ",modu_conv_qty, 
			" AND (posttemp.base_debit_amt > 0 OR posttemp.base_credit_amt < 0)" 
			PREPARE flag_it2 FROM l_upd_sel_text 
			DECLARE update_post2 CURSOR FOR flag_it2 

			CASE modu_rec_current.tran_type_ind 
				WHEN TRAN_TYPE_INVOICE_IN {invoices} 
					FOREACH update_post2 INTO l_rec_data.ref_num, 
						l_rec_data.ref_text 
						UPDATE postinvhead SET jour_num = glob_posted_journal 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND inv_num = l_rec_data.ref_num 
					END FOREACH 
				WHEN TRAN_TYPE_RECEIPT_CA {cash} 
					FOREACH update_post2 INTO l_rec_data.ref_num, 
						l_rec_data.ref_text 
						UPDATE postcashrcpt SET jour_num = glob_posted_journal 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND cash_num = l_rec_data.ref_num 
					END FOREACH 
				WHEN TRAN_TYPE_CREDIT_CR {credits} 
					FOREACH update_post2 INTO l_rec_data.ref_num, 
						l_rec_data.ref_text 
						UPDATE postcredhead SET jour_num = glob_posted_journal 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND cred_num = l_rec_data.ref_num 
					END FOREACH 
				WHEN "EXA" {credits} 
					FOREACH update_post2 INTO l_rec_data.ref_num, 
						l_rec_data.ref_text 
						UPDATE postexchvar SET jour_num = glob_posted_journal 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND ref1_num = l_rec_data.ref_num 
						AND ref2_num = l_rec_data.ref_text 
					END FOREACH 
			END CASE 

			IF glob_posted_journal IS NOT NULL THEN 
				LET glob_posted_journal = NULL 
			END IF 


			# check FOR -ve journal number - indicates an error in posting account
			# within the GL batch

			IF modu_rec_current.jour_num < 0 THEN 
				LET modu_all_ok = 0 
			END IF 

			# DISPLAY each batch number as created


		END IF 

		#
		# Now do Statistics
		SELECT count(*) 
		INTO l_rec_count 
		FROM posttemp 
		WHERE posttemp.ar_acct_code = modu_rec_current.bal_acct_code 
		AND posttemp.currency_code = modu_rec_current.currency_code 
		AND posttemp.conv_qty = modu_conv_qty 
		AND (posttemp.base_debit_amt = 0 AND posttemp.base_credit_amt = 0) 
		AND posttemp.stats_qty <> 0 

		IF l_rec_count IS NULL 
		OR l_rec_count = 0 THEN ELSE 
			LET l_posted_some = true 
			LET modu_rec_bal.acct_code = modu_rec_current.bal_acct_code 

			LET modu_sel_text = " SELECT ","\"", modu_rec_current.tran_type_ind clipped, "\",", 
			" 0, ", 
			" \"Summary\", ", 
			" posttemp.post_acct_code, ", 
			" \"", modu_passed_desc clipped, "\",", 
			" sum(posttemp.debit_amt), ", 
			" sum(posttemp.credit_amt), ", 
			" sum(posttemp.base_debit_amt), ", 
			" sum(posttemp.base_credit_amt), ", 
			" posttemp.currency_code, ", 

			" posttemp.conv_qty, ", 
			" posttemp.tran_date, ", 
			" sum(posttemp.stats_qty) ", 
			" FROM posttemp ", 
			" WHERE posttemp.ar_acct_code = ", 
			"\"", modu_rec_bal.acct_code clipped, "\"", 
			" AND posttemp.currency_code = \"", 
			modu_rec_current.currency_code, "\"", 
			" AND posttemp.conv_qty = ",modu_conv_qty, 
			" AND (posttemp.base_debit_amt = 0 ", 
			"AND posttemp.base_credit_amt = 0)", 
			" AND posttemp.stats_qty <> 0", 
			" group by posttemp.currency_code, ", 
			" posttemp.conv_qty, ", 
			" posttemp.post_acct_code, posttemp.tran_date" 


			CALL fgl_winmessage("jourintf2()","jourintf()\n7","INFO") 


			LET modu_rec_current.jour_num = jourintf2(modu_rpt_idx,
			modu_sel_text, 
			modu_rec_bal.*, 
			glob_fisc_period, 
			glob_fisc_year, 
			modu_rec_current.jour_code, 
			"A", 
			modu_rec_current.currency_code, 
			"AR") 

			IF modu_rec_current.jour_num = 0 THEN 
				ERROR kandoomsg2("U",3500,modu_rec_current.tran_type_ind) 
				# 3500 "No entries FOR type ",modu_rec_current.tran_type_ind,
				#      "posted."
				SLEEP 1 
			END IF 


			LET l_upd_sel_text = 
			" SELECT posttemp.ref_num, ", 
			" posttemp.ref_text ", 
			" FROM posttemp ", 
			" WHERE posttemp.ar_acct_code = ", 
			"\"", modu_rec_bal.acct_code clipped, "\"", 
			" AND posttemp.currency_code = \"", 
			modu_rec_current.currency_code, "\"", 
			" AND posttemp.conv_qty = ",modu_conv_qty, 
			" AND (posttemp.base_debit_amt = 0 ", 
			"AND posttemp.base_credit_amt = 0)", 
			" AND posttemp.stats_qty <> 0" 
			PREPARE flag_it3 FROM l_upd_sel_text 
			DECLARE update_post3 CURSOR FOR flag_it3 

			CASE modu_rec_current.tran_type_ind 
				WHEN TRAN_TYPE_INVOICE_IN {invoices} 
					FOREACH update_post3 INTO l_rec_data.ref_num, 
						l_rec_data.ref_text 
						UPDATE postinvhead SET jour_num = glob_posted_journal 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND inv_num = l_rec_data.ref_num 
					END FOREACH 
				WHEN TRAN_TYPE_RECEIPT_CA {cash} 
					FOREACH update_post3 INTO l_rec_data.ref_num, 
						l_rec_data.ref_text 
						UPDATE postcashrcpt SET jour_num = glob_posted_journal 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND cash_num = l_rec_data.ref_num 
					END FOREACH 
				WHEN TRAN_TYPE_CREDIT_CR {credits} 
					FOREACH update_post3 INTO l_rec_data.ref_num, 
						l_rec_data.ref_text 
						UPDATE postcredhead SET jour_num = glob_posted_journal 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND cred_num = l_rec_data.ref_num 
					END FOREACH 
				WHEN "EXA" {credits} 
					FOREACH update_post3 INTO l_rec_data.ref_num, 
						l_rec_data.ref_text 
						UPDATE postexchvar SET jour_num = glob_posted_journal 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND ref1_num = l_rec_data.ref_num 
						AND ref2_num = l_rec_data.ref_text 
					END FOREACH 
			END CASE 

			IF glob_posted_journal IS NOT NULL THEN 
				LET glob_posted_journal = NULL 
			END IF 

			# check FOR -ve journal number - indicates an error in posting account
			# within the GL batch

			IF modu_rec_current.jour_num < 0 THEN 
				LET modu_all_ok = 0 
			END IF 

		END IF 
	END FOREACH 

	IF NOT l_posted_some THEN 
		# 3501 "No rows found TO post"
		ERROR kandoomsg2("U",3501,"") 
		SLEEP 1 
	END IF 

	IF get_debug() THEN 
		DISPLAY "#### FUNCTION create_summ_batches() END" 
	END IF 

END FUNCTION 
#######################################################
# END FUNCTION create_summ_batches()
#######################################################


#######################################################
# FUNCTION invoice()
#
#
######################################################
FUNCTION invoice() 
	DEFINE l_msgresp LIKE language.yes_flag 

	IF get_debug() THEN 
		DISPLAY "#### FUNCTION invoice() START" 
	END IF 

	GOTO bypass 
	LABEL recovery: 

	IF get_debug() THEN 
		DISPLAY "CALL update_poststatus(TRUE,", trim(STATUS),"\"AR\") - AS7.4gl - invoice()" 
	END IF 

	CALL update_poststatus(TRUE,STATUS,"AR") 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 

	# IF an error has occurred AND it was NOT in this part of the post THEN
	# walk on by ...
	IF modu_post_status > 6 AND modu_post_status < 99 THEN 
		RETURN 
	END IF 

	LET glob_err_text = "Commenced invoice post" 
	IF modu_post_status = 1 THEN {error in invoice post} 
		# 3503 "Rolling back postinvhead AND invoicehead tables"
		ERROR kandoomsg2("A",3503,"") 
		SLEEP 2 
		LET glob_err_text = "Reversing previous invoices" 

		IF NOT glob_one_trans THEN 
			BEGIN WORK 

				IF get_debug() THEN 
					DISPLAY "BEGIN WORK - AS7.4gl - invoice()" 
				END IF 



				LET glob_in_trans = true 

				IF get_debug() THEN 
					DISPLAY "glob_in_trans = ",trim(glob_in_trans) , " as7.4gl - invoice()" 
				END IF 
			END IF 

			IF glob_rec_poststatus.online_ind != "L" THEN 
				LOCK TABLE postinvhead in share MODE 
				LOCK TABLE invoicehead in share MODE 
			END IF 

			DECLARE inv_undo CURSOR FOR 
			SELECT inv_num 
			FROM postinvhead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			FOR UPDATE 

			FOREACH inv_undo INTO modu_inv_num 

				UPDATE invoicehead SET posted_flag = "N" 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND inv_num = modu_inv_num 

				DELETE FROM postinvhead WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND inv_num = modu_inv_num 

			END FOREACH 
			IF NOT glob_one_trans THEN 

				IF get_debug() THEN 
					DISPLAY "COMMIT WORK - AS7.4gl - invoice()" 
				END IF 

			COMMIT WORK 
			LET glob_in_trans = false 

			IF get_debug() THEN 
				DISPLAY "glob_in_trans = ",trim(glob_in_trans) , " as7.4gl - invoice()" 
			END IF 

		END IF 
	END IF 

	LET glob_st_code = 1 
	LET glob_post_text = "Commenced INSERT INTO postinvhead" 

	IF get_debug() THEN 
		DISPLAY "CALL update_poststatus(FALSE,", "0","\"AR\") - AS7.4gl - invoice()" 
	END IF 

	CALL update_poststatus(FALSE,0,"AR") 

	IF modu_post_status = 1 OR modu_post_status = 99 THEN 
		# SELECT the invoices FOR posting AND INSERT them INTO postinvhead
		# table THEN UPDATE them as posted so they won't be touched by
		# anyone ELSE
		LET glob_err_text = "Invoice SELECT FOR INSERT" 
		DECLARE inv_curs CURSOR with HOLD FOR 
		SELECT h.inv_num 
		FROM invoicehead h 
		WHERE h.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND h.posted_flag = "N" 
		AND h.year_num = glob_fisc_year 
		AND h.period_num = glob_fisc_period 

		LET glob_err_text = "Invoice FOREACH FOR INSERT" 
		FOREACH inv_curs INTO modu_inv_num 
			LET modu_set_retry = retry_lock(glob_rec_kandoouser.cmpy_code,0) 
			WHILE (true) 
				IF NOT glob_one_trans THEN 
					BEGIN WORK 

						IF get_debug() THEN 
							DISPLAY "BEGIN WORK - AS7.4gl - invoice()" 
						END IF 

						LET glob_in_trans = true 

						IF get_debug() THEN 
							DISPLAY "glob_in_trans = ",trim(glob_in_trans) , " as7.4gl - invoice()" 
						END IF 

					END IF 

					WHENEVER ERROR CONTINUE 

					DECLARE insert_curs CURSOR FOR 
					SELECT * 
					FROM invoicehead 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND inv_num = modu_inv_num 
					FOR UPDATE 

					LET glob_err_text = "Invoice lock FOR INSERT" 

					OPEN insert_curs 
					FETCH insert_curs INTO glob_rec_invoicehead.* 
					LET modu_stat_code = status 
					IF modu_stat_code THEN 
						IF modu_stat_code = NOTFOUND THEN 
							IF NOT glob_one_trans THEN 

								IF get_debug() THEN 
									DISPLAY "COMMIT WORK - AS7.4gl - invoice()" 
								END IF 
							COMMIT WORK 
						END IF 
						CONTINUE FOREACH 
					END IF 
					LET modu_set_retry = retry_lock(glob_rec_kandoouser.cmpy_code,modu_stat_code) 
					IF modu_set_retry <= 0 THEN 
						# one transaction users cannot retry since
						# we cannot resurrect the transaction which
						# has been rolled back
						IF NOT glob_one_trans THEN 
							LET modu_try_again = error_recover("Invoice INSERT", 
							modu_stat_code) 
							IF modu_try_again != "Y" THEN 
								LET glob_in_trans = false 

								IF get_debug() THEN 
									DISPLAY "glob_in_trans = ",trim(glob_in_trans) , " as7.4gl - invoice()" 
									DISPLAY "CALL update_poststatus(TRUE,", trim(modu_stat_code),"\"AR\") - AS7.4gl - invoice()" 
								END IF 
								CALL update_poststatus(TRUE,modu_stat_code,"AR") 
							ELSE 
								ROLLBACK WORK 
								CONTINUE WHILE 
							END IF 
						ELSE 

							IF get_debug() THEN 
								DISPLAY "CALL update_poststatus(TRUE,", trim(modu_stat_code),"\"AR\") - AS7.4gl - invoice()" 
							END IF 
							CALL update_poststatus(TRUE,modu_stat_code,"AR") 
						END IF 
					ELSE 
						IF NOT glob_one_trans THEN 

							IF get_debug() THEN 
								DISPLAY "COMMIT WORK - AS7.4gl - invoice()" 
							END IF 

						COMMIT WORK 
					END IF 
					CONTINUE WHILE 
				END IF 
			END IF 
			EXIT WHILE 
		END WHILE 
		LET modu_set_retry = retry_lock(glob_rec_kandoouser.cmpy_code,0) 

		WHENEVER ERROR GOTO recovery 
		IF glob_rec_invoicehead.currency_code IS NULL THEN 
			LET glob_rec_invoicehead.currency_code = glob_rec_glparms.base_currency_code 
			LET glob_rec_invoicehead.conv_qty = 1 
		END IF 
		IF glob_rec_invoicehead.conv_qty IS NULL THEN 
			LET glob_rec_invoicehead.conv_qty = 1 
		END IF 

		LET glob_rec_invoicehead.manifest_num = NULL 
		LET glob_err_text = "PP1 - Insert INTO postinvhead" 

		IF get_debug() THEN 
			DISPLAY "INSERT INTO postinvhead (only one instance)" 
		END IF 

		INSERT INTO postinvhead VALUES (glob_rec_invoicehead.*) 

		LET glob_err_text = "PP1 - Invoicehead post flag SET" 
		UPDATE invoicehead SET posted_flag = "Y" 
		WHERE CURRENT OF insert_curs 

		IF NOT glob_one_trans THEN 

			IF get_debug() THEN 
				DISPLAY "COMMIT WORK - AS7.4gl - invoice()" 
			END IF 
		COMMIT WORK 
		LET glob_in_trans = false 

		IF get_debug() THEN 
			DISPLAY "glob_in_trans = ",trim(glob_in_trans) , " as7.4gl - invoice()" 
		END IF 
	END IF 
END FOREACH 
END IF 

LET glob_err_text = "Create gl batch - invoices" 
LET glob_st_code = 2 
LET glob_post_text = "Completed INSERT TO postinvhead" 

IF get_debug() THEN 
	DISPLAY "CALL update_poststatus(FALSE,", "0","\"AR\") - AS7.4gl - invoice()" 
END IF 

CALL update_poststatus(FALSE,0,"AR") 

IF modu_post_status <= 2 OR modu_post_status = 99 THEN 
LET glob_err_text = "History SELECT on invoice " 
DECLARE cust_curs CURSOR with HOLD FOR 
SELECT cust_code, 
count(*), 
sum(total_amt), 
sum(cost_amt) 
INTO modu_client_cust_code, 
modu_counter, 
modu_totaller, 
modu_cost_totaller 
FROM postinvhead 
WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
AND posted_flag != "H" 
AND period_num = glob_fisc_period 
AND year_num = glob_fisc_year 
GROUP BY cust_code 

FOREACH cust_curs 
	CALL init_hist() 

	LET modu_set_retry = retry_lock(glob_rec_kandoouser.cmpy_code,0) 
	WHILE (true) 
		IF NOT glob_one_trans THEN 
			BEGIN WORK 

				IF get_debug() THEN 
					DISPLAY "BEGIN WORK - AS7.4gl - invoice()" 
					DISPLAY "glob_in_trans = ",trim(glob_in_trans) , " as7.4gl - invoice()" 
				END IF 
				LET glob_in_trans = true 

			END IF 

			DECLARE chist_upd CURSOR FOR 
			SELECT * 
			FROM customerhist 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cust_code = modu_client_cust_code 
			AND year_num = glob_fisc_year 
			AND period_num = glob_fisc_period 
			FOR UPDATE 

			LET glob_err_text = " Customer History UPDATE " 

			WHENEVER ERROR CONTINUE 

			OPEN chist_upd 
			FETCH chist_upd INTO modu_rec_customerhist.* 
			LET modu_stat_code = status 
			IF modu_stat_code THEN 
				IF modu_stat_code = NOTFOUND THEN 
					IF NOT glob_one_trans THEN 

						IF get_debug() THEN 
							DISPLAY "COMMIT WORK - AS7.4gl - invoice()" 
						END IF 
					COMMIT WORK 
					LET glob_in_trans = false 

					IF get_debug() THEN 
						DISPLAY "glob_in_trans = ",trim(glob_in_trans) , " as7.4gl - invoice()" 
					END IF 
				END IF 
				CONTINUE FOREACH 
			END IF 
			LET modu_set_retry = retry_lock(glob_rec_kandoouser.cmpy_code,modu_stat_code) 
			IF modu_set_retry <= 0 THEN 
				# glob_one_trans users cannot retry
				IF NOT glob_one_trans THEN 
					LET modu_try_again = error_recover("Chist invoice", 
					modu_stat_code) 
					IF modu_try_again != "Y" THEN 
						LET glob_in_trans = false 

						IF get_debug() THEN 
							DISPLAY "glob_in_trans = ",trim(glob_in_trans) , " as7.4gl - invoice()" 
							DISPLAY "CALL update_poststatus(TRUE,", trim(modu_stat_code),"\"AR\") - AS7.4gl - invoice()" 
						END IF 
						CALL update_poststatus(TRUE,modu_stat_code,"AR") 
					ELSE 
						IF NOT glob_one_trans THEN 
							ROLLBACK WORK 
							LET glob_in_trans = false 

							IF get_debug() THEN 
								DISPLAY "glob_in_trans = ",trim(glob_in_trans) , " as7.4gl - invoice()" 
							END IF 
						END IF 
						CONTINUE WHILE 
					END IF 
				ELSE 

					IF get_debug() THEN 
						DISPLAY "CALL update_poststatus(TRUE,", trim(modu_stat_code),"\"AR\") - AS7.4gl - invoice()" 
					END IF 


					CALL update_poststatus(TRUE,modu_stat_code,"AR") 
				END IF 
			ELSE 
				IF NOT glob_one_trans THEN 

					IF get_debug() THEN 
						DISPLAY "COMMIT WORK - AS7.4gl - invoice()" 
					END IF 
					COMMIT WORK 
					LET glob_in_trans = false 

					IF get_debug() THEN 
						DISPLAY "glob_in_trans = ",trim(glob_in_trans) , " as7.4gl - invoice()" 
					END IF 


				END IF 
				CONTINUE WHILE 
			END IF 
		END IF 
		EXIT WHILE 
	END WHILE 

	LET modu_set_retry = retry_lock(glob_rec_kandoouser.cmpy_code,0) 
	
	WHENEVER ERROR GOTO recovery 

	UPDATE customerhist 
	SET sales_num = customerhist.sales_num + modu_counter, 
	sales_qty = customerhist.sales_qty + modu_totaller, 
	sale_cost_amt = customerhist.sale_cost_amt + modu_cost_totaller 
	WHERE CURRENT OF chist_upd 

	UPDATE postinvhead SET posted_flag = "H" 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cust_code = modu_client_cust_code 

	CLOSE chist_upd 
	IF NOT glob_one_trans THEN 
		IF get_debug() THEN 
			DISPLAY "COMMIT WORK - AS7.4gl - invoice()" 
		END IF 
		COMMIT WORK 
		LET glob_in_trans = false 

		IF get_debug() THEN 
			DISPLAY "glob_in_trans = ",trim(glob_in_trans) , " as7.4gl - invoice()" 
		END IF 

	END IF 
END FOREACH 

END IF 

LET glob_st_code = 3 
LET glob_post_text = "Completed history post" 

IF get_debug() THEN 
	DISPLAY "CALL update_poststatus(FALSE,", "0","\"AR\") - AS7.4gl - invoice()" 
END IF 
CALL update_poststatus(FALSE,0,"AR") 

IF glob_rec_arparms.gl_flag = "Y" THEN 
	IF modu_post_status <= 3 OR modu_post_status = 99 THEN 




		MESSAGE kandoomsg2("A",3504,"") # 3504 "Posting Invoices..."
		SLEEP 1 
		CALL send_invoices() 
		LET glob_st_code = 4 
		LET glob_post_text = "Commenced invoice post" 

		IF get_debug() THEN 
			DISPLAY "CALL update_poststatus(FALSE,", "0","\"AR\") - AS7.4gl - invoice()" 
		END IF 
		CALL update_poststatus(FALSE,0,"AR") 
	END IF 
	IF modu_post_status <= 4 OR modu_post_status = 99 THEN 




		MESSAGE kandoomsg2("A",3509,"") # 3509 "Posting JM cos..."
		SLEEP 1 
		CALL jm_cos_post() 
		LET glob_st_code = 5 
		LET glob_post_text = "Commenced jm cos post" 

		IF get_debug() THEN 
			DISPLAY "CALL update_poststatus(FALSE,", "0","\"AR\") - AS7.4gl - invoice()" 
		END IF 
		CALL update_poststatus(FALSE,0,"AR") 
	END IF 
END IF 

LET glob_st_code = 5 
LET glob_post_text = "Commenced UPDATE jour_num FROM postinvhead" 

IF get_debug() THEN 
	DISPLAY "CALL update_poststatus(FALSE,", "0","\"AR\") - AS7.4gl - invoice()" 
END IF 

CALL update_poststatus(FALSE,0,"AR") 

IF modu_post_status != 6 THEN 
	LET glob_err_text = "Update jour_num in invoicehead" 
	DECLARE update_jour CURSOR with HOLD FOR 
	SELECT * 
	FROM postinvhead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 

	FOREACH update_jour INTO glob_rec_invoicehead.* 
		IF NOT glob_one_trans THEN 
			BEGIN WORK 
	
			IF get_debug() THEN 
				DISPLAY "BEGIN WORK - AS7.4gl - invoice()" 
			END IF 
	
			LET glob_in_trans = true 
	
	
			IF get_debug() THEN 
				DISPLAY "glob_in_trans = ",trim(glob_in_trans) , " as7.4gl - invoice()" 
			END IF 
	
		END IF 
		
		UPDATE invoicehead SET jour_num = glob_rec_invoicehead.jour_num, post_date = today 
		WHERE cmpy_code = glob_rec_invoicehead.cmpy_code 
		AND cust_code = glob_rec_invoicehead.cust_code 
		AND inv_num = glob_rec_invoicehead.inv_num 
		IF NOT glob_one_trans THEN 
	
			IF get_debug() THEN 
				DISPLAY "COMMIT WORK - AS7.4gl - invoice()" 
			END IF 
	
			COMMIT WORK 
			LET glob_in_trans = false 
	
			IF get_debug() THEN 
				DISPLAY "glob_in_trans = ",trim(glob_in_trans) , " as7.4gl - invoice()" 
			END IF 
	
		END IF 
	END FOREACH 
END IF 

LET glob_st_code = 6 
LET glob_post_text = "Commenced DELETE FROM postinvhead" 

IF get_debug() THEN 
	DISPLAY "CALL update_poststatus(FALSE,", "0","\"AR\") - AS7.4gl - invoice()" 
END IF 

CALL update_poststatus(FALSE,0,"AR") 

LET glob_err_text = "DELETE FROM postinvhead" 
IF NOT glob_one_trans THEN 
	BEGIN WORK 

	IF get_debug() THEN 
		DISPLAY "BEGIN WORK - AS7.4gl - invoice()" 
	END IF 

	LET glob_in_trans = true 

	IF get_debug() THEN 
		DISPLAY "glob_in_trans = ",trim(glob_in_trans) , " as7.4gl - invoice()" 
	END IF 

END IF 
IF glob_rec_poststatus.online_ind != "L" THEN 
	LOCK TABLE postinvhead in share MODE 
END IF 
DELETE FROM postinvhead WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
IF NOT glob_one_trans THEN 

IF get_debug() THEN 
DISPLAY "COMMIT WORK - AS7.4gl - invoice()" 
END IF 

COMMIT WORK 
LET glob_in_trans = false 

IF get_debug() THEN 
DISPLAY "glob_in_trans = ",trim(glob_in_trans) , " as7.4gl - invoice()" 
END IF 

END IF 

LET glob_st_code = 99 
LET glob_post_text = "Invoice posting completed correctly" 

IF get_debug() THEN 
	DISPLAY "CALL update_poststatus(FALSE,0,\"AR\") - AS7.4gl - invoice()" 
END IF 

CALL update_poststatus(FALSE,0,"AR") 

WHENEVER ERROR stop
WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 

IF get_debug() THEN 
DISPLAY "#### FUNCTION invoice() END" 
END IF 

END FUNCTION 
#######################################################
# END FUNCTION invoice()
######################################################


#######################################################
# FUNCTION init_hist()
#
#
######################################################
FUNCTION init_hist() 

	IF get_debug() THEN 
		DISPLAY "#### FUNCTION init_hist() START" 
	END IF 


	LET modu_err_message = " Customer History SELECT " 
	SELECT * 
	INTO modu_rec_customerhist.* 
	FROM customerhist 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cust_code = modu_client_cust_code 
	AND year_num = glob_fisc_year 
	AND period_num = glob_fisc_period 

	IF status = NOTFOUND THEN 
		INITIALIZE modu_rec_customerhist.* TO NULL 
		LET modu_rec_customerhist.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET modu_rec_customerhist.cust_code = modu_client_cust_code 
		LET modu_rec_customerhist.year_num = glob_fisc_year 
		LET modu_rec_customerhist.period_num = glob_fisc_period 
		LET modu_rec_customerhist.sales_num = 0 
		LET modu_rec_customerhist.sales_qty = 0 
		LET modu_rec_customerhist.sale_cost_amt = 0 
		LET modu_rec_customerhist.cred_qty = 0 
		LET modu_rec_customerhist.cred_amt = 0 
		LET modu_rec_customerhist.cred_cost_amt = 0 
		LET modu_rec_customerhist.cash_qty = 0 
		LET modu_rec_customerhist.cash_amt = 0 
		LET modu_rec_customerhist.disc_amt = 0 
		LET modu_rec_customerhist.gross_per = 0 
		LET modu_err_message = " Customer History INSERT" 

		IF get_debug() THEN 
			DISPLAY "INSERT INTO customerhist (there is only one instance)" 
		END IF 

		INSERT INTO customerhist VALUES (modu_rec_customerhist.*) 
	END IF 

	IF get_debug() THEN 
		DISPLAY "#### FUNCTION init_hist() END" 
	END IF 

END FUNCTION 
#######################################################
# END FUNCTION init_hist()
######################################################



#######################################################
# FUNCTION send_invoices()
#
#
######################################################
FUNCTION send_invoices() 
	DEFINE l_cmpy_code LIKE company.cmpy_code 
	DEFINE l_ord_num LIKE invoicehead.ord_num 
	DEFINE l_ord_ind LIKE ordhead.ord_ind 

	IF get_debug() THEN 
		DISPLAY "#### FUNCTION send_invoices() START" 
	END IF 

	LET modu_prev_cust_type = "z" 
	LET modu_prev_ord_ind = NULL 
	LET modu_rec_current.tran_type_ind = TRAN_TYPE_INVOICE_IN 
	LET modu_rec_current.jour_code = glob_rec_arparms.sales_jour_code 
	LET modu_rec_current.base_debit_amt = 0 

	# SELECT all unposted invoices FOR the required period

	IF modu_post_status = 3 THEN {crapped PUT in invoice post} 
		LET modu_select_text = "SELECT H.cmpy_code, ", 
		" H.inv_num, ", 
		" H.cust_code, ", 
		" H.inv_date, ", 
		" H.currency_code, ", 
		" H.conv_qty, ", 
		" C.type_code, ", 
		" H.freight_amt, ", 
		" H.freight_tax_code, ", 
		" H.freight_tax_amt, ", 
		" H.hand_amt, ", 
		" H.hand_tax_code, ", 
		" H.hand_tax_amt ", 
		"FROM postinvhead H, customer C ", 
		"WHERE H.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND H.posted_flag != 'Y' ", 
		"AND H.year_num = ",glob_fisc_year," ", 
		"AND H.period_num = ",glob_fisc_period," ", 
		"AND H.cmpy_code = C.cmpy_code ", 
		"AND H.cust_code = C.cust_code " 
		IF glob_rec_poststatus.jour_num IS NULL THEN 
			LET modu_select_text = modu_select_text clipped, 
			" AND (H.jour_num IS NULL", 
			" OR H.jour_num = 0)", 
			" ORDER BY H.cmpy_code, H.cust_code, H.inv_num" 
		ELSE 
			LET modu_select_text = modu_select_text clipped, 
			" AND (H.jour_num = ", glob_rec_poststatus.jour_num, 
			" OR H.jour_num IS NULL", 
			" OR H.jour_num = 0)", 
			" ORDER BY H.cmpy_code, H.cust_code, H.inv_num" 
		END IF 
	ELSE 
		LET modu_select_text = "SELECT H.cmpy_code, ", 
		" H.inv_num, ", 
		" H.cust_code, ", 
		" H.inv_date, ", 
		" H.currency_code, ", 
		" H.conv_qty, ", 
		" C.type_code, ", 
		" H.freight_amt, ", 
		" H.freight_tax_code, ", 
		" H.freight_tax_amt, ", 
		" H.hand_amt, ", 
		" H.hand_tax_code, ", 
		" H.hand_tax_amt ", 
		"FROM postinvhead H, customer C ", 
		"WHERE H.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
		"AND H.posted_flag != \"Y\" ", 
		"AND H.year_num = ",glob_fisc_year," ", 
		"AND H.period_num = ",glob_fisc_period," ", 
		"AND H.cmpy_code = C.cmpy_code ", 
		"AND H.cust_code = C.cust_code ", 
		"ORDER BY H.cmpy_code, H.cust_code, H.inv_num " 
	END IF 

	PREPARE inv_sel FROM modu_select_text 
	DECLARE in_curs CURSOR FOR inv_sel 

	LET glob_err_text = "FOREACH INTO posttemp - invoicehead" 
	FOREACH in_curs INTO l_cmpy_code, 
		modu_rec_docdata.*, 
		modu_rec_current.cust_type, 
		modu_rec_current.freight_amt, 
		modu_rec_current.freight_tax_code, 
		modu_rec_current.freight_tax_amt, 
		modu_rec_current.hand_amt, 
		modu_rec_current.hand_tax_code, 
		modu_rec_current.hand_tax_amt 

		LET l_ord_ind = NULL 
		SELECT ord_ind INTO l_ord_ind FROM invheadext 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND inv_num = modu_rec_docdata.ref_num 
		IF status = NOTFOUND 
		OR l_ord_ind IS NULL THEN 
			SELECT ord_num INTO l_ord_num FROM invoicehead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND inv_num = modu_rec_docdata.ref_num 
			IF status != NOTFOUND THEN 
				SELECT ord_ind INTO l_ord_ind FROM ordhead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND order_num = l_ord_num 
				IF status = NOTFOUND THEN 
					LET l_ord_ind = NULL 
				END IF 
			END IF 
		END IF 
		IF (modu_rec_current.cust_type != modu_prev_cust_type OR 
		(modu_rec_current.cust_type IS NULL AND modu_prev_cust_type IS NOT null) OR 
		(modu_rec_current.cust_type IS NOT NULL AND modu_prev_cust_type IS null)) 
		OR (l_ord_ind != modu_prev_ord_ind OR 
		(l_ord_ind IS NOT NULL AND modu_prev_ord_ind IS null)) THEN 
			CALL get_cust_accts(l_ord_ind) 
		END IF 

		# INSERT posting data FOR the Invoice freight AND handling amounts

		IF modu_rec_current.freight_amt != 0 THEN 
			IF modu_rec_docdata.conv_qty IS NOT NULL THEN 
				IF modu_rec_docdata.conv_qty != 0 THEN 
					LET modu_rec_current.base_credit_amt = modu_rec_current.freight_amt / 
					modu_rec_docdata.conv_qty 
				END IF 
			END IF 

			# IF use_currency_flag IS 'N' THEN any source documents in foreign
			# currency need TO be converted TO base, AND a base batch created.
			IF glob_rec_glparms.use_currency_flag = "N" THEN 
				LET modu_rec_current.freight_amt = modu_rec_current.base_credit_amt 

				LET modu_rec_docdata.currency_code = glob_rec_glparms.base_currency_code 
				LET modu_sv_conv_qty = 1 
			ELSE 
				LET modu_sv_conv_qty = modu_rec_docdata.conv_qty 
			END IF 

			IF get_debug() THEN 
				DISPLAY "INSERT INTO posttemp 1" 
			END IF 

			INSERT INTO posttemp VALUES 
			(modu_rec_docdata.ref_num, # invoice number 
			modu_rec_docdata.ref_text, # customer code 
			modu_rec_current.freight_acct_code, # freight control account 
			modu_rec_docdata.ref_num, # invoice number 
			0, 
			modu_rec_current.freight_amt, # invoice freight amount 
			modu_rec_current.base_debit_amt, # zero FOR freight 
			modu_rec_current.base_credit_amt, # converted freight amt 
			modu_rec_docdata.currency_code, # invoice currency code 

			modu_sv_conv_qty, 
			modu_rec_docdata.tran_date, # invoice DATE 
			0, # stats qty NOT yet in use 
			modu_rec_current.ar_acct_code) # ar control account 

		END IF 

		IF modu_rec_current.hand_amt != 0 THEN 
			IF modu_rec_docdata.conv_qty IS NOT NULL THEN 
				IF modu_rec_docdata.conv_qty != 0 THEN 
					LET modu_rec_current.base_credit_amt = modu_rec_current.hand_amt / 
					modu_rec_docdata.conv_qty 
				END IF 
			END IF 

			# IF use_currency_flag IS 'N' THEN any source documents in foreign
			# currency need TO be converted TO base, AND a base batch created.
			IF glob_rec_glparms.use_currency_flag = "N" THEN 
				LET modu_rec_current.hand_amt = modu_rec_current.base_credit_amt 

				LET modu_rec_docdata.currency_code = glob_rec_glparms.base_currency_code 
				LET modu_sv_conv_qty = 1 
			ELSE 
				LET modu_sv_conv_qty = modu_rec_docdata.conv_qty 
			END IF 

			IF get_debug() THEN 
				DISPLAY "INSERT INTO posttemp 2" 
			END IF 

			INSERT INTO posttemp VALUES 
			(modu_rec_docdata.ref_num, # invoice number 
			modu_rec_docdata.ref_text, # customer code 
			modu_rec_current.lab_acct_code, # handling control account 
			modu_rec_docdata.ref_num, # invoice number 
			0, 
			modu_rec_current.hand_amt, # invoice handling amount 
			modu_rec_current.base_debit_amt, # zero FOR handling 
			modu_rec_current.base_credit_amt, # converted handling amt 
			modu_rec_docdata.currency_code, # invoice currency code 

			modu_sv_conv_qty, 
			modu_rec_docdata.tran_date, # invoice DATE 
			0, # stats qty NOT yet in use 
			modu_rec_current.ar_acct_code) # ar control account 

		END IF 

		# accumulate handling AND freight tax

		IF modu_rec_current.freight_tax_amt != 0 THEN 
			CALL add_tax(modu_rec_current.freight_tax_code, 
			modu_rec_current.freight_tax_amt) 
		END IF 

		IF modu_rec_current.hand_tax_amt != 0 THEN 
			CALL add_tax(modu_rec_current.hand_tax_code, 
			modu_rec_current.hand_tax_amt) 
		END IF 

		# create posting details FOR the line items FOR the selected invoices

		DECLARE id_curs CURSOR FOR 
		SELECT line_acct_code, 
		line_text, 
		0, 
		ext_sale_amt, 
		tax_code, 
		ext_tax_amt 
		FROM invoicedetl 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND inv_num = modu_rec_docdata.ref_num 
		AND cust_code = modu_rec_docdata.ref_text 

		FOREACH id_curs INTO modu_rec_detldata.*, 
			modu_rec_detltax.* 

			IF modu_rec_docdata.conv_qty IS NOT NULL THEN 
				IF modu_rec_docdata.conv_qty != 0 THEN 
					LET modu_rec_current.base_credit_amt = modu_rec_detldata.credit_amt / 
					modu_rec_docdata.conv_qty 
				END IF 
			END IF 

			# IF use_currency_flag IS 'N' THEN any source documents in foreign
			# currency need TO be converted TO base, AND a base batch created.
			IF glob_rec_glparms.use_currency_flag = "N" THEN 
				LET modu_rec_detldata.credit_amt = modu_rec_current.base_credit_amt 

				LET modu_rec_docdata.currency_code = glob_rec_glparms.base_currency_code 
				LET modu_sv_conv_qty = 1 
			ELSE 
				LET modu_sv_conv_qty = modu_rec_docdata.conv_qty 
			END IF 

			IF get_debug() THEN 
				DISPLAY "INSERT INTO posttemp 3" 
			END IF 

			INSERT INTO posttemp VALUES 
			(modu_rec_docdata.ref_num, # invoice number 
			modu_rec_docdata.ref_text, # customer code 
			modu_rec_detldata.post_acct_code, # line item gl account 
			modu_rec_detldata.desc_text, # line item desc 
			modu_rec_detldata.debit_amt, # zero FOR TRAN_TYPE_INVOICE_IN 
			modu_rec_detldata.credit_amt, # line item sale amount 
			modu_rec_current.base_debit_amt, # zero FOR TRAN_TYPE_INVOICE_IN 
			modu_rec_current.base_credit_amt, # converted sale amount 
			modu_rec_docdata.currency_code, # invoice currency code 

			modu_sv_conv_qty, 
			modu_rec_docdata.tran_date, # invoice DATE 
			0, # stats qty NOT yet in use 
			modu_rec_current.ar_acct_code) # ar control account 

			IF modu_rec_detltax.ext_tax_amt != 0 THEN 
				CALL add_tax(modu_rec_detltax.tax_code, 
				modu_rec_detltax.ext_tax_amt) 
			END IF 
		END FOREACH 

		# now INSERT the accumulated tax postings

		CALL tax_postings(TRAN_TYPE_CREDIT_CR) 
	END FOREACH 

	LET modu_rec_bal.tran_type_ind = TRAN_TYPE_INVOICE_IN 
	LET modu_rec_bal.desc_text = "AR Invoice Balancing Entry" 

	IF modu_post_status = 3 AND 
	glob_rec_poststatus.jour_num != 0 THEN 
		LET glob_posted_journal = glob_rec_poststatus.jour_num 
	ELSE 
		LET glob_posted_journal = NULL 
	END IF 

	IF glob_rec_arparms.detail_to_gl_flag = "N" THEN 
		LET modu_passed_desc = "Summary AR Invoices ",glob_fisc_year USING "<<<<", " ", 
		glob_fisc_period USING "<<" 
		CALL create_summ_batches() 
	ELSE 

		IF get_debug() THEN 
			DISPLAY "CALL create_gl_batches() 1" 
		END IF 

		CALL create_gl_batches() 
	END IF 

	DELETE FROM posttemp WHERE 1=1 

	IF get_debug() THEN 
		DISPLAY "#### FUNCTION send_invoices() END" 
	END IF 

END FUNCTION 
#######################################################
# END FUNCTION send_invoices()
######################################################


#######################################################
# FUNCTION jm_cos_post()
#
# debit the activity cost of sales accounts.
# AND credit the individual activity wip AND
######################################################
FUNCTION jm_cos_post() 
	DEFINE l_jm_cos_acct_code LIKE batchdetl.acct_code 
	DEFINE l_jm_wip_acct_code LIKE batchdetl.acct_code 
	DEFINE l_currency_code LIKE batchdetl.currency_code 
	DEFINE modu_conv_qty LIKE batchdetl.conv_qty 
	DEFINE l_base_amt LIKE batchdetl.debit_amt 
	DEFINE l_inv_date LIKE invoicehead.inv_date 
	DEFINE l_ref_text CHAR(10) 
	DEFINE l_rec_jmparms RECORD LIKE jmparms.* 

	IF get_debug() THEN 
		DISPLAY "#### FUNCTION jm_cos_post() START" 
	END IF 



	SELECT * 
	INTO l_rec_jmparms.* 
	FROM jmparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 

	IF status = NOTFOUND THEN 
		RETURN 
	END IF 

	# first debit the activity cos account.
	LET modu_err_message = "Posting Cost of Sales" 
	LET modu_rec_bal.tran_type_ind = "COS" 
	LET modu_rec_bal.desc_text = "JM COS Balancing entry " 
	LET modu_rec_current.tran_type_ind = "CO" 
	LET modu_rec_current.jour_code = glob_rec_arparms.sales_jour_code 

	IF modu_post_status = 4 THEN {post crapped out ON jm cos post} 
		LET modu_select_text = "SELECT H.inv_num, ", 
		" D.line_num, ", 
		" D.activity_code, ", 
		" A.cos_acct_code, ", 
		" A.wip_acct_code, ", 
		" D.ext_cost_amt, ", 
		" A.title_text, ", 
		" H.currency_code, ", 
		" H.conv_qty, ", 
		" H.inv_date ", 
		"FROM postinvhead H, invoicedetl D, activity A ", 
		"WHERE H.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
		"AND H.posted_flag != \"Y\" ", 
		"AND H.period_num = ",glob_fisc_period," ", 
		"AND H.year_num = ",glob_fisc_year," ", 
		"AND H.inv_ind = \"3\" ", 
		"AND D.cmpy_code = H.cmpy_code ", 
		"AND D.cust_code = H.cust_code ", 
		"AND D.inv_num = H.inv_num ", 
		"AND A.cmpy_code = D.cmpy_code ", 
		"AND A.job_code = H.job_code ", 
		"AND A.activity_code = D.activity_code ", 
		"AND A.var_code = D.var_code " 
		IF glob_rec_poststatus.jour_num IS NULL THEN 
			LET modu_select_text = modu_select_text clipped, 
			" AND (H.manifest_num IS NULL", 
			" OR H.manifest_num = 0)" 
		ELSE 
			LET modu_select_text = modu_select_text clipped, 
			" AND (H.manifest_num = ", glob_rec_poststatus.jour_num, 
			" OR H.manifest_num IS NULL", 
			" OR H.manifest_num = 0)" 
		END IF 
		LET modu_select_text = modu_select_text clipped, 
		" union SELECT H.inv_num, ", 
		" D.line_num, ", 
		" D.activity_code, ", 
		" A.cos_acct_code, ", 
		" A.wip_acct_code, ", 
		" D.ext_cost_amt, ", 
		" A.title_text, ", 
		" H.currency_code, ", 
		" H.conv_qty, ", 
		" H.inv_date ", 
		"FROM postinvhead H, invoicedetl D, activity A, ", 
		" contractdetl C ", 
		"WHERE H.cmpy_code = \"", glob_rec_kandoouser.cmpy_code, "\" ", 
		"AND H.posted_flag != \"Y\" ", 
		"AND H.period_num = ", glob_fisc_period, " ", 
		"AND H.year_num = ", glob_fisc_year, " ", 
		"AND H.inv_ind = \"D\" ", 
		"AND D.cmpy_code = H.cmpy_code ", 
		"AND D.cust_code = H.cust_code ", 
		"AND D.inv_num = H.inv_num ", 
		"AND A.cmpy_code = D.cmpy_code ", 
		"AND A.activity_code = D.activity_code ", 
		"AND A.var_code = D.var_code ", 
		"AND H.cmpy_code = C.cmpy_code ", 
		"AND H.contract_code = C.contract_code ", 
		"AND D.contract_line_num = C.line_num ", 
		"AND A.job_code = C.job_code" 
		IF glob_rec_poststatus.jour_num IS NULL THEN 
			LET modu_select_text = modu_select_text clipped, 
			" AND (H.manifest_num IS NULL", 
			" OR H.manifest_num = 0)" 
		ELSE 
			LET modu_select_text = modu_select_text clipped, 
			" AND (H.manifest_num = ", glob_rec_poststatus.jour_num, 
			" OR H.manifest_num IS NULL", 
			" OR H.manifest_num = 0)" 
		END IF 
	ELSE 
		LET modu_select_text = "SELECT H.inv_num, ", 
		" D.line_num, ", 
		" D.activity_code, ", 
		" A.cos_acct_code, ", 
		" A.wip_acct_code, ", 
		" D.ext_cost_amt, ", 
		" A.title_text, ", 
		" H.currency_code, ", 
		" H.conv_qty, ", 
		" H.inv_date ", 
		"FROM postinvhead H, invoicedetl D, activity A ", 
		"WHERE H.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
		"AND H.posted_flag != \"Y\" ", 
		"AND H.period_num = ",glob_fisc_period," ", 
		"AND H.year_num = ",glob_fisc_year," ", 
		"AND H.inv_ind = \"3\" ", 
		"AND D.cmpy_code = H.cmpy_code ", 
		"AND D.cust_code = H.cust_code ", 
		"AND D.inv_num = H.inv_num ", 
		"AND A.cmpy_code = D.cmpy_code ", 
		"AND A.job_code = H.job_code ", 
		"AND A.activity_code = D.activity_code ", 
		"AND A.var_code = D.var_code", 
		" union ", 
		"SELECT H.inv_num, ", 
		" D.line_num, ", 
		" D.activity_code, ", 
		" A.cos_acct_code, ", 
		" A.wip_acct_code, ", 
		" D.ext_cost_amt, ", 
		" A.title_text, ", 
		" H.currency_code, ", 
		" H.conv_qty, ", 
		" H.inv_date ", 
		"FROM postinvhead H, invoicedetl D, activity A, ", 
		" contractdetl C ", 
		"WHERE H.cmpy_code = \"", glob_rec_kandoouser.cmpy_code, "\" ", 
		"AND H.posted_flag != \"Y\" ", 
		"AND H.period_num = ", glob_fisc_period, " ", 
		"AND H.year_num = ", glob_fisc_year, " ", 
		"AND H.inv_ind = \"D\" ", 
		"AND D.cmpy_code = H.cmpy_code ", 
		"AND D.cust_code = H.cust_code ", 
		"AND D.inv_num = H.inv_num ", 
		"AND A.cmpy_code = D.cmpy_code ", 
		"AND A.activity_code = D.activity_code ", 
		"AND A.var_code = D.var_code ", 
		"AND H.cmpy_code = C.cmpy_code ", 
		"AND H.contract_code = C.contract_code ", 
		"AND D.contract_line_num = C.line_num ", 
		"AND A.job_code = C.job_code" 
	END IF 

	PREPARE sel_cos FROM modu_select_text 
	DECLARE jm_cos_c CURSOR FOR sel_cos 

	LET glob_err_text = "FOREACH INTO postemp - jm cos" 
	FOREACH jm_cos_c INTO glob_rec_invoicehead.inv_num, 
		modu_rec_invoicedetl.line_num, 
		modu_rec_invoicedetl.activity_code, 
		l_jm_cos_acct_code, 
		l_jm_wip_acct_code, 
		modu_rec_invoicedetl.ext_cost_amt, 
		glob_rec_invoicehead.com1_text, 
		l_currency_code, 
		modu_conv_qty, 
		l_inv_date 

		# note the activity name IS in batchdetl(posttemp).desc_text
		# put the invoice line number INTO batchdetl(posttemp).ref_text
		LET l_ref_text = "Line ", modu_rec_invoicedetl.line_num USING "<<<" 

		IF modu_rec_invoicedetl.ext_cost_amt != 0 OR l_base_amt != 0 THEN 
			IF modu_conv_qty IS NOT NULL THEN 
				IF modu_conv_qty != 0 THEN 
					LET l_base_amt = modu_rec_invoicedetl.ext_cost_amt / modu_conv_qty 
				END IF 
			END IF 

			# IF use_currency_flag IS 'N' THEN any source documents in foreign
			# currency need TO be converted TO base, AND a base batch created.
			IF glob_rec_glparms.use_currency_flag = "N" THEN 
				LET modu_rec_invoicedetl.ext_cost_amt = l_base_amt 
				LET modu_conv_qty = 1 
				LET l_currency_code = glob_rec_glparms.base_currency_code 
			END IF 

			IF get_debug() THEN 
				DISPLAY "INSERT INTO posttemp 4" 
			END IF 

			INSERT INTO posttemp VALUES (glob_rec_invoicehead.inv_num, 
			l_ref_text, 
			l_jm_cos_acct_code, 
			glob_rec_invoicehead.com1_text, 
			modu_rec_invoicedetl.ext_cost_amt, 
			0, 
			l_base_amt, 
			0, 
			l_currency_code, 
			modu_conv_qty, 
			l_inv_date, 
			0, 
			glob_rec_glparms.susp_acct_code) 

			IF get_debug() THEN 
				DISPLAY "INSERT INTO posttemp 5" 
			END IF 

			# Now credit the activity wip
			INSERT INTO posttemp VALUES (glob_rec_invoicehead.inv_num, 
			l_ref_text, 
			l_jm_wip_acct_code, 
			glob_rec_invoicehead.com1_text, 
			0, 
			modu_rec_invoicedetl.ext_cost_amt, 
			0, 
			l_base_amt, 
			l_currency_code, 
			modu_conv_qty, 
			l_inv_date, 
			0, 
			glob_rec_glparms.susp_acct_code) 

		END IF 

	END FOREACH 

	IF modu_post_status = 4 AND 
	glob_rec_poststatus.jour_num != 0 THEN 
		LET glob_posted_journal = glob_rec_poststatus.jour_num 
	ELSE 
		LET glob_posted_journal = NULL 
	END IF 

	IF get_debug() THEN 
		DISPLAY "CALL create_gl_batches() 2" 
	END IF 

	CALL create_gl_batches() 

	IF get_debug() THEN 
		DISPLAY "DELETE FROM posttemp WHERE 1=1" 
	END IF 

	DELETE FROM posttemp WHERE 1 = 1 

	IF get_debug() THEN 
		DISPLAY "#### FUNCTION jm_cos_post() END" 
	END IF 

END FUNCTION 
#######################################################
# END FUNCTION jm_cos_post()
######################################################


#######################################################
# FUNCTION credit()
#
#
######################################################
FUNCTION credit() 
	DEFINE l_cmpy_code LIKE company.cmpy_code 
	DEFINE l_msgresp LIKE language.yes_flag 

	IF get_debug() THEN 
		DISPLAY "#### FUNCTION credit() START" 
	END IF 

	GOTO bypass 
	LABEL recovery: 
	CALL update_poststatus(TRUE,STATUS,"AR") 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 

	# IF an error has occurred AND it was NOT in this part of the post THEN
	# walk on by ...
	IF modu_post_status > 12 AND modu_post_status < 99 THEN 
		RETURN 
	END IF 

	LET glob_err_text = "Commenced credit post" 
	IF modu_post_status = 7 THEN {error in credit post} 
		# 3505 "Rolling back postcredhead AND credithead tables"
		ERROR kandoomsg2("A",3505,"") 
		SLEEP 2 
		LET glob_err_text = "Reversing previous credits" 

		IF NOT glob_one_trans THEN 
			BEGIN WORK 
				LET glob_in_trans = true 
			END IF 

			IF glob_rec_poststatus.online_ind != "L" THEN 
				LOCK TABLE postcredhead in share MODE 
				LOCK TABLE credithead in share MODE 
			END IF 

			DECLARE cred_undo CURSOR FOR 
			SELECT cred_num 
			FROM postcredhead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			FOR UPDATE 

			FOREACH cred_undo INTO modu_cred_num 

				UPDATE credithead SET posted_flag = "N" 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cred_num = modu_cred_num 

				DELETE FROM postcredhead WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cred_num = modu_cred_num 

			END FOREACH 
			IF NOT glob_one_trans THEN 
			COMMIT WORK 
			LET glob_in_trans = false 
		END IF 
	END IF 

	LET glob_st_code = 7 
	LET glob_post_text = "Commenced INSERT INTO postcredhead " 
	CALL update_poststatus(FALSE,0,"AR") 

	IF modu_post_status = 7 OR modu_post_status = 99 THEN 
		# SELECT the credits FOR posting AND INSERT them INTO postcredhead
		# table THEN UPDATE them as posted so they won't be touched by
		# anyone ELSE
		LET glob_err_text = "Credit SELECT FOR INSERT" 
		DECLARE credit_curs CURSOR with HOLD FOR 
		SELECT h.cred_num 
		FROM credithead h 
		WHERE h.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND h.posted_flag = "N" 
		AND h.year_num = glob_fisc_year 
		AND h.period_num = glob_fisc_period 

		LET glob_err_text = "Credit FOREACH FOR INSERT" 
		FOREACH credit_curs INTO modu_cred_num 
			LET modu_set_retry = retry_lock(glob_rec_kandoouser.cmpy_code,0) 
			WHILE (true) 
				IF NOT glob_one_trans THEN 
					BEGIN WORK 
						LET glob_in_trans = true 
					END IF 

					WHENEVER ERROR CONTINUE 

					DECLARE insert1_curs CURSOR FOR 
					SELECT * 
					FROM credithead 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cred_num = modu_cred_num 
					FOR UPDATE 

					LET glob_err_text = "Credit lock FOR INSERT" 

					OPEN insert1_curs 
					FETCH insert1_curs INTO modu_rec_credithead.* 
					LET modu_stat_code = status 
					IF modu_stat_code THEN 
						IF modu_stat_code = NOTFOUND THEN 
							IF NOT glob_one_trans THEN 
							COMMIT WORK 
						END IF 
						CONTINUE FOREACH 
					END IF 
					LET modu_set_retry = retry_lock(glob_rec_kandoouser.cmpy_code,modu_stat_code) 
					IF modu_set_retry <= 0 THEN 
						# one transaction users cannot retry since
						# we cannot resurrect the transaction which
						# has been rolled back
						IF NOT glob_one_trans THEN 
							LET modu_try_again = error_recover("Credit INSERT", 
							modu_stat_code) 
							IF modu_try_again != "Y" THEN 
								LET glob_in_trans = false 
								CALL update_poststatus(TRUE,modu_stat_code,"AR") 
							ELSE 
								ROLLBACK WORK 
								CONTINUE WHILE 
							END IF 
						ELSE 
							CALL update_poststatus(TRUE,modu_stat_code,"AR") 
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
		LET modu_set_retry = retry_lock(glob_rec_kandoouser.cmpy_code,0) 

--		WHENEVER ERROR GOTO recovery 

		IF modu_rec_credithead.currency_code IS NULL THEN 
			LET modu_rec_credithead.currency_code = glob_rec_glparms.base_currency_code 
			LET modu_rec_credithead.conv_qty = 1 
		END IF 
		IF modu_rec_credithead.conv_qty IS NULL THEN 
			LET modu_rec_credithead.conv_qty = 1 
		END IF 
		LET modu_rec_credithead.rma_num = NULL 
		LET glob_err_text = "AS7 - Insert INTO postcredhead " 

		IF get_debug() THEN 
			DISPLAY "INSERT INTO postcredhead (there is only one instance)" 
		END IF 

		INSERT INTO postcredhead VALUES (modu_rec_credithead.*) 

		LET glob_err_text = "AS7 - Credithead post flag SET" 
		UPDATE credithead SET posted_flag = "Y" 
		WHERE CURRENT OF insert1_curs 

		IF NOT glob_one_trans THEN 
		COMMIT WORK 
		LET glob_in_trans = false 
	END IF 
END FOREACH 
END IF 

LET glob_err_text = "Create gl batch - credits" 
LET glob_st_code = 8 
LET glob_post_text = "Completed INSERT TO postcredhead" 
CALL update_poststatus(FALSE,0,"AR") 

IF modu_post_status <= 8 OR modu_post_status = 99 THEN 
LET glob_err_text = "History SELECT on credits " 

DECLARE clnt1_curs CURSOR with HOLD FOR 
SELECT cust_code, 
count(*), 
sum(total_amt), 
sum(disc_amt), 
sum(cost_amt) 
INTO modu_client_cust_code, 
modu_counter, 
modu_totaller, 
modu_disc_totaller, 
modu_cost_totaller 
FROM postcredhead 
WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
AND posted_flag != "H" 
AND period_num = glob_fisc_period 
AND year_num = glob_fisc_year 
GROUP BY cust_code 

FOREACH clnt1_curs 
	CALL init_hist() 

	LET glob_err_text = " Customer History UPDATE - credits" 

	LET modu_set_retry = retry_lock(glob_rec_kandoouser.cmpy_code,0) 
	WHILE (true) 
		IF NOT glob_one_trans THEN 
			BEGIN WORK 
				LET glob_in_trans = true 
			END IF 

			DECLARE chist_upd1 CURSOR FOR 
			SELECT * 
			FROM customerhist 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cust_code = modu_client_cust_code 
			AND year_num = glob_fisc_year 
			AND period_num = glob_fisc_period 
			FOR UPDATE 


			WHENEVER ERROR CONTINUE 

			OPEN chist_upd1 
			FETCH chist_upd1 INTO modu_rec_customerhist.* 
			LET modu_stat_code = status 
			IF modu_stat_code THEN 
				IF modu_stat_code = NOTFOUND THEN 
					IF NOT glob_one_trans THEN 
					COMMIT WORK 
					LET glob_in_trans = false 
				END IF 
				CONTINUE FOREACH 
			END IF 
			LET modu_set_retry = retry_lock(glob_rec_kandoouser.cmpy_code,modu_stat_code) 
			IF modu_set_retry <= 0 THEN 
				# glob_one_trans users cannot retry
				IF NOT glob_one_trans THEN 
					LET modu_try_again = error_recover("Chist credit", 
					modu_stat_code) 
					IF modu_try_again != "Y" THEN 
						LET glob_in_trans = false 
						CALL update_poststatus(TRUE,modu_stat_code,"AR") 
					ELSE 
						IF NOT glob_one_trans THEN 
							ROLLBACK WORK 
							LET glob_in_trans = false 
						END IF 
						CONTINUE WHILE 
					END IF 
				ELSE 
					CALL update_poststatus(TRUE,modu_stat_code,"AR") 
				END IF 
			ELSE 
				IF NOT glob_one_trans THEN 
				COMMIT WORK 
				LET glob_in_trans = false 
			END IF 
			CONTINUE WHILE 
		END IF 
	END IF 
	EXIT WHILE 
END WHILE 

LET modu_set_retry = retry_lock(glob_rec_kandoouser.cmpy_code,0) 

WHENEVER ERROR GOTO recovery 

LET modu_err_message = " Customer History UPDATE - credits " 
UPDATE customerhist 
SET cred_qty = customerhist.cred_qty + modu_counter, 
cred_amt = customerhist.cred_amt + modu_totaller, 
disc_amt = customerhist.disc_amt + modu_disc_totaller, 
cred_cost_amt = customerhist.cred_cost_amt + 
modu_cost_totaller 
WHERE CURRENT OF chist_upd1 

UPDATE postcredhead SET posted_flag = "H" 
WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
AND cust_code = modu_client_cust_code 

CLOSE chist_upd1 
IF NOT glob_one_trans THEN 
COMMIT WORK 
LET glob_in_trans = false 
END IF 


END FOREACH 
END IF 

LET glob_st_code = 9 
LET glob_post_text = "Create GL batch - credits" 
CALL update_poststatus(FALSE,0,"AR") 

IF glob_rec_arparms.gl_flag = "Y" THEN 
IF modu_post_status <= 9 OR modu_post_status = 99 THEN 



#3506 "Posting Credits.........."
MESSAGE kandoomsg2("A",3506,"") 
SLEEP 1 
CALL send_credits() 
LET glob_st_code = 10 
LET glob_post_text = "Commenced credit post" 
CALL update_poststatus(FALSE,0,"AR") 
END IF 
IF modu_post_status <= 10 OR modu_post_status = 99 THEN 



#3509 "Posting JM cos.........."
MESSAGE kandoomsg2("A",3509,"") 
SLEEP 1 
CALL jm_cos_postc() 
LET glob_st_code = 11 
LET glob_post_text = "Commenced jm cos post" 
CALL update_poststatus(FALSE,0,"AR") 
END IF 
END IF 

LET glob_st_code = 11 
LET glob_post_text = "Commenced UPDATE jour_num FROM postcredhead" 
CALL update_poststatus(FALSE,0,"AR") 

IF modu_post_status != 12 THEN 
LET glob_err_text = "Update jour_num in credithead" 
DECLARE update_jour1 CURSOR with HOLD FOR 
SELECT * 
FROM postcredhead 
WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 

FOREACH update_jour1 INTO modu_rec_credithead.* 
IF NOT glob_one_trans THEN 
BEGIN WORK 
	LET glob_in_trans = true 
END IF 
UPDATE credithead SET jour_num = modu_rec_credithead.jour_num, 
post_date = today 
WHERE cmpy_code = modu_rec_credithead.cmpy_code 
AND cust_code = modu_rec_credithead.cust_code 
AND cred_num = modu_rec_credithead.cred_num 
IF NOT glob_one_trans THEN 
COMMIT WORK 
LET glob_in_trans = false 
END IF 
END FOREACH 
END IF 

LET glob_st_code = 12 
LET glob_post_text = "Commenced DELETE FROM postcredhead" 
CALL update_poststatus(FALSE,0,"AR") 

LET glob_err_text = "DELETE FROM postcredhead" 
IF NOT glob_one_trans THEN 
BEGIN WORK 
LET glob_in_trans = true 
END IF 
IF glob_rec_poststatus.online_ind != "L" THEN 
LOCK TABLE postcredhead in share MODE 
END IF 
DELETE FROM postcredhead WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
IF NOT glob_one_trans THEN 
COMMIT WORK 
LET glob_in_trans = false 
END IF 

LET glob_st_code = 99 
LET glob_post_text = "Credit posting completed correctly" 
CALL update_poststatus(FALSE,0,"AR") 

WHENEVER ERROR stop 
WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

IF get_debug() THEN 
DISPLAY "#### FUNCTION credit() END" 
END IF 
END FUNCTION 


#######################################################
# FUNCTION send_credits()
#
# New processing AND functions TO cope with WIP AND COS postings
######################################################
FUNCTION send_credits() 
	DEFINE l_ord_ind LIKE ordhead.ord_ind 
	DEFINE l_rma_num LIKE credithead.rma_num 
	DEFINE l_cmpy_code LIKE company.cmpy_code 
	DEFINE l_msgresp LIKE language.yes_flag 

	IF get_debug() THEN 
		DISPLAY "#### FUNCTION send_credits() START" 
	END IF 

	LET modu_prev_cust_type = "z" 
	LET modu_prev_ord_ind = NULL 
	LET modu_rec_current.tran_type_ind = TRAN_TYPE_CREDIT_CR 
	LET modu_rec_current.jour_code = glob_rec_arparms.sales_jour_code 
	LET modu_rec_current.base_credit_amt = 0 

	# SELECT all unposted credits FOR the required period

	IF modu_post_status = 9 THEN {crapped out in credit post TO gl} 
		LET modu_select_text = "SELECT H.cmpy_code, ", 
		" H.cred_num, ", 
		" H.cust_code, ", 
		" H.cred_date, ", 
		" H.currency_code, ", 
		" H.conv_qty, ", 
		" C.type_code, ", 
		" H.freight_amt, ", 
		" H.freight_tax_code, ", 
		" H.freight_tax_amt, ", 
		" H.hand_amt, ", 
		" H.hand_tax_code, ", 
		" H.hand_tax_amt, ", 
		" H.disc_amt ", 
		"FROM postcredhead H, customer C ", 
		"WHERE H.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
		"AND H.posted_flag != \"Y\" ", 
		"AND H.year_num = ",glob_fisc_year," ", 
		"AND H.period_num = ",glob_fisc_period," ", 
		"AND H.cmpy_code = C.cmpy_code ", 
		"AND H.cust_code = C.cust_code " 
		IF glob_rec_poststatus.jour_num IS NULL THEN 
			LET modu_select_text = modu_select_text clipped, 
			" AND (H.jour_num IS NULL", 
			" OR H.jour_num = 0)", 
			" ORDER BY H.cmpy_code, H.cust_code,", 
			" H.cred_num " 
		ELSE 
			LET modu_select_text = modu_select_text clipped, 
			" AND (H.jour_num = ", 
			glob_rec_poststatus.jour_num, 
			" OR H.jour_num IS NULL", 
			" OR H.jour_num = 0)", 
			" ORDER BY H.cmpy_code, H.cust_code,", 
			" H.cred_num " 
		END IF 
	ELSE 
		LET modu_select_text = "SELECT H.cmpy_code, ", 
		" H.cred_num, ", 
		" H.cust_code, ", 
		" H.cred_date, ", 
		" H.currency_code, ", 
		" H.conv_qty, ", 
		" C.type_code, ", 
		" H.freight_amt, ", 
		" H.freight_tax_code, ", 
		" H.freight_tax_amt, ", 
		" H.hand_amt, ", 
		" H.hand_tax_code, ", 
		" H.hand_tax_amt, ", 
		" H.disc_amt ", 
		"FROM postcredhead H, customer C ", 
		"WHERE H.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
		"AND H.posted_flag != \"Y\" ", 
		"AND H.year_num = ",glob_fisc_year," ", 
		"AND H.period_num = ",glob_fisc_period," ", 
		"AND H.cmpy_code = C.cmpy_code ", 
		"AND H.cust_code = C.cust_code ", 
		"ORDER BY H.cmpy_code, H.cust_code,", 
		" H.cred_num " 
	END IF 

	PREPARE sel_cred FROM modu_select_text 
	DECLARE cr_curs CURSOR FOR sel_cred 

	LET glob_err_text = "FOREACH INTO posttemp - credits" 
	FOREACH cr_curs INTO l_cmpy_code, 
		modu_rec_docdata.*, 
		modu_rec_current.cust_type, 
		modu_rec_current.freight_amt, 
		modu_rec_current.freight_tax_code, 
		modu_rec_current.freight_tax_amt, 
		modu_rec_current.hand_amt, 
		modu_rec_current.hand_tax_code, 
		modu_rec_current.hand_tax_amt, 
		modu_rec_current.disc_amt 

		LET l_ord_ind = NULL 
		SELECT ord_ind INTO l_ord_ind FROM creditheadext 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND credit_num = modu_rec_docdata.ref_num 
		IF status = NOTFOUND 
		OR l_ord_ind IS NULL THEN 
			SELECT rma_num INTO l_rma_num FROM credithead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cred_num = modu_rec_docdata.ref_num 
			IF status != NOTFOUND THEN 
				SELECT ord_ind INTO l_ord_ind FROM ordhead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND order_num = l_rma_num 
				IF status = NOTFOUND THEN 
					LET l_ord_ind = NULL 
				END IF 
			END IF 
		END IF 
		IF (modu_rec_current.cust_type != modu_prev_cust_type 
		OR (modu_rec_current.cust_type IS NULL AND modu_prev_cust_type IS NOT null) 
		OR (modu_rec_current.cust_type IS NOT NULL 
		AND modu_prev_cust_type IS null)) 
		OR (l_ord_ind != modu_prev_ord_ind OR 
		(l_ord_ind IS NOT NULL AND modu_prev_ord_ind IS null)) THEN 
			CALL get_cust_accts(l_ord_ind) 
		END IF 

		# INSERT posting data FOR the Credit freight,
		# handling AND discount amounts

		IF modu_rec_current.freight_amt != 0 THEN 
			IF modu_rec_docdata.conv_qty IS NOT NULL THEN 
				IF modu_rec_docdata.conv_qty != 0 THEN 
					LET modu_rec_current.base_debit_amt = 
					modu_rec_current.freight_amt / 
					modu_rec_docdata.conv_qty 
				END IF 
			END IF 

			# IF use_currency_flag IS 'N' THEN any source documents in foreign
			# currency need TO be converted TO base, AND a base batch created.
			IF glob_rec_glparms.use_currency_flag = "N" THEN 
				LET modu_rec_current.freight_amt = modu_rec_current.base_debit_amt 

				LET modu_rec_docdata.currency_code = 
				glob_rec_glparms.base_currency_code 
				LET modu_sv_conv_qty = 1 
			ELSE 
				LET modu_sv_conv_qty = modu_rec_docdata.conv_qty 
			END IF 

			IF get_debug() THEN 
				DISPLAY "INSERT INTO posttemp 6" 
			END IF 
			INSERT INTO posttemp VALUES 
			(modu_rec_docdata.ref_num, # credit number 
			modu_rec_docdata.ref_text, # customer code 
			modu_rec_current.freight_acct_code, # freight control acct 
			modu_rec_docdata.ref_num, # credit number 
			modu_rec_current.freight_amt, # credit freight amount 
			0, 
			modu_rec_current.base_debit_amt, # converted freight amt 
			modu_rec_current.base_credit_amt, # zero FOR credits 
			modu_rec_docdata.currency_code, # credit currency code 

			modu_sv_conv_qty, 
			modu_rec_docdata.tran_date, # credit DATE 
			0, # stats qty NOT in use 
			modu_rec_current.ar_acct_code) # ar control account 

		END IF 

		IF modu_rec_current.hand_amt != 0 THEN 
			IF modu_rec_docdata.conv_qty IS NOT NULL THEN 
				IF modu_rec_docdata.conv_qty != 0 THEN 
					LET modu_rec_current.base_debit_amt = 
					modu_rec_current.hand_amt / 
					modu_rec_docdata.conv_qty 
				END IF 
			END IF 

			# IF use_currency_flag IS 'N' THEN any source documents in foreign
			# currency need TO be converted TO base, AND a base batch created.
			IF glob_rec_glparms.use_currency_flag = "N" THEN 
				LET modu_rec_current.hand_amt = modu_rec_current.base_debit_amt 

				LET modu_rec_docdata.currency_code = 
				glob_rec_glparms.base_currency_code 
				LET modu_sv_conv_qty = 1 
			ELSE 
				LET modu_sv_conv_qty = modu_rec_docdata.conv_qty 
			END IF 

			IF get_debug() THEN 
				DISPLAY "INSERT INTO posttemp 7" 
			END IF 
			INSERT INTO posttemp VALUES 
			(modu_rec_docdata.ref_num, # credit number 
			modu_rec_docdata.ref_text, # customer code 
			modu_rec_current.lab_acct_code, # handling control acct 
			modu_rec_docdata.ref_num, # credit number 
			modu_rec_current.hand_amt, # credit handling amount 
			0, 
			modu_rec_current.base_debit_amt, # converted freight amt 
			modu_rec_current.base_credit_amt, # zero FOR credits 
			modu_rec_docdata.currency_code, # credit currency code 

			modu_sv_conv_qty, 
			modu_rec_docdata.tran_date, # credit DATE 
			0, # stats qty NOT in use 
			modu_rec_current.ar_acct_code) # ar control account 

		END IF 

		IF modu_rec_current.disc_amt IS NOT NULL AND 
		modu_rec_current.disc_amt != 0 THEN 
			IF modu_rec_docdata.conv_qty IS NOT NULL THEN 
				IF modu_rec_docdata.conv_qty != 0 THEN 
					LET modu_rec_current.base_debit_amt = 
					modu_rec_current.disc_amt / 
					modu_rec_docdata.conv_qty 
				END IF 
			END IF 

			# IF use_currency_flag IS 'N' THEN any source documents in foreign
			# currency need TO be converted TO base, AND a base batch created.
			IF glob_rec_glparms.use_currency_flag = "N" THEN 
				LET modu_rec_current.disc_amt = modu_rec_current.base_debit_amt 

				LET modu_rec_docdata.currency_code = 
				glob_rec_glparms.base_currency_code 
				LET modu_sv_conv_qty = 1 
			ELSE 
				LET modu_sv_conv_qty = modu_rec_docdata.conv_qty 
			END IF 

			IF get_debug() THEN 
				DISPLAY "INSERT INTO posttemp 8" 
			END IF 

			INSERT INTO posttemp VALUES 
			(modu_rec_docdata.ref_num, # credit number 
			modu_rec_docdata.ref_text, # customer code 
			modu_rec_current.disc_acct_code, # discount control acct 
			modu_rec_docdata.ref_num, # credit number 
			modu_rec_current.disc_amt, # credit discount amount 
			0, 
			modu_rec_current.base_debit_amt, # converted discount amt 
			modu_rec_current.base_credit_amt, # zero FOR credits 
			modu_rec_docdata.currency_code, # credit currency code 

			modu_sv_conv_qty, 
			modu_rec_docdata.tran_date, # credit DATE 
			0, # stats qty NOT in use 
			modu_rec_current.ar_acct_code) # ar control account 

		END IF 

		# accumulate handling AND freight tax

		IF modu_rec_current.freight_tax_amt != 0 THEN 
			CALL add_tax(modu_rec_current.freight_tax_code, 
			modu_rec_current.freight_tax_amt) 
		END IF 

		IF modu_rec_current.hand_tax_amt != 0 THEN 
			CALL add_tax(modu_rec_current.hand_tax_code, 
			modu_rec_current.hand_tax_amt) 
		END IF 

		# create posting details FOR the line items
		# FOR the selected credits

		DECLARE cd_curs CURSOR FOR 
		SELECT line_acct_code, 
		line_text, 
		ext_sales_amt, 
		0, 
		tax_code, 
		ext_tax_amt 
		FROM creditdetl 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cred_num = modu_rec_docdata.ref_num 
		AND cust_code = modu_rec_docdata.ref_text 

		FOREACH cd_curs INTO modu_rec_detldata.*, 
			modu_rec_detltax.* 

			IF modu_rec_docdata.conv_qty IS NOT NULL THEN 
				IF modu_rec_docdata.conv_qty != 0 THEN 
					LET modu_rec_current.base_debit_amt = 
					modu_rec_detldata.debit_amt / 
					modu_rec_docdata.conv_qty 
				END IF 
			END IF 

			# IF use_currency_flag IS 'N' THEN any source documents in foreign
			# currency need TO be converted TO base, AND a base batch created.
			IF glob_rec_glparms.use_currency_flag = "N" THEN 
				LET modu_rec_detldata.debit_amt = modu_rec_current.base_debit_amt 

				LET modu_rec_docdata.currency_code = 
				glob_rec_glparms.base_currency_code 
				LET modu_sv_conv_qty = 1 
			ELSE 
				LET modu_sv_conv_qty = modu_rec_docdata.conv_qty 
			END IF 

			IF get_debug() THEN 
				DISPLAY "INSERT INTO posttemp 9" 
			END IF 
			INSERT INTO posttemp VALUES 
			(modu_rec_docdata.ref_num, # credit number 
			modu_rec_docdata.ref_text, # customer code 
			modu_rec_detldata.post_acct_code, # line item gl account 
			modu_rec_detldata.desc_text, # line item desc 
			modu_rec_detldata.debit_amt, # line item sale amount 
			modu_rec_detldata.credit_amt, # zero FOR TRAN_TYPE_CREDIT_CR 
			modu_rec_current.base_debit_amt, # converted amt 
			modu_rec_current.base_credit_amt, # zero FOR credits 
			modu_rec_docdata.currency_code, # credit currency code 

			modu_sv_conv_qty, 
			modu_rec_docdata.tran_date, # credit DATE 
			0, # stats qty NOT in use 
			modu_rec_current.ar_acct_code) # ar control account 

			IF modu_rec_detltax.ext_tax_amt != 0 THEN 
				CALL add_tax(modu_rec_detltax.tax_code,modu_rec_detltax.ext_tax_amt) 
			END IF 
		END FOREACH 

		# now INSERT the accumulated tax postings

		CALL tax_postings("DR") 
	END FOREACH 

	LET modu_rec_bal.tran_type_ind = TRAN_TYPE_CREDIT_CR 
	LET modu_rec_bal.desc_text = "AR Credit Balancing Entry" 

	IF modu_post_status = 9 AND 
	glob_rec_poststatus.jour_num != 0 THEN 
		LET glob_posted_journal = glob_rec_poststatus.jour_num 
	ELSE 
		LET glob_posted_journal = NULL 
	END IF 

	MESSAGE " " 
	# 3506 "Posting Credits..."
	MESSAGE kandoomsg2("A",3506,"") 
	SLEEP 1 

	IF glob_rec_arparms.detail_to_gl_flag = "N" THEN 
		LET modu_passed_desc = "Summary AR Credits ", 
		glob_fisc_year USING "<<<<", " ", 
		glob_fisc_period USING "<<" 
		CALL create_summ_batches() 
	ELSE 

		IF get_debug() THEN 
			DISPLAY "CALL create_gl_batches() 3 - FUNCTION send_credits()" 
		END IF 

		CALL create_gl_batches() 
	END IF 

	DELETE FROM posttemp WHERE 1 = 1 

	IF get_debug() THEN 
		DISPLAY "#### FUNCTION send_credits() END" 
	END IF 

END FUNCTION 


#######################################################
# FUNCTION jm_cos_postc()
#
# debit the activity cost of sales accounts.
# AND credit the individual activity wip AND
#######################################################
FUNCTION jm_cos_postc() 
	DEFINE l_jm_cos_acct_code LIKE batchdetl.acct_code 
	DEFINE l_jm_wip_acct_code LIKE batchdetl.acct_code 
	DEFINE l_currency_code LIKE batchdetl.currency_code 
	DEFINE l_conv_qty LIKE batchdetl.conv_qty 
	DEFINE l_base_amt LIKE batchdetl.debit_amt 
	DEFINE l_inv_date LIKE invoicehead.inv_date 
	DEFINE l_ref_text CHAR(10) 
	DEFINE l_rec_jmparms RECORD LIKE jmparms.* 

	IF get_debug() THEN 
		DISPLAY "#### FUNCTION jm_cos_postc() START" 
	END IF 


	SELECT * 
	INTO l_rec_jmparms.* 
	FROM jmparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 

	IF status = NOTFOUND THEN 
		RETURN 
	END IF 

	# first credit the activity cos account.
	LET modu_err_message = "Posting Cost of Sales" 
	LET modu_rec_bal.tran_type_ind = "COS" 
	LET modu_rec_bal.desc_text = "JM COS Balancing entry " 
	LET modu_rec_current.tran_type_ind = "CCO" 
	LET modu_rec_current.jour_code = glob_rec_arparms.sales_jour_code 

	IF modu_post_status = 10 THEN {post crapped out ON jm cos post} 
		LET modu_select_text = "SELECT H.cred_num, ", 
		" D.line_num, ", 
		" D.activity_code, ", 
		" A.cos_acct_code, ", 
		" A.wip_acct_code, ", 
		" D.ext_cost_amt, ", 
		" A.title_text, ", 
		" H.currency_code, ", 
		" H.conv_qty, ", 
		" H.cred_date ", 
		"FROM postcredhead H, creditdetl D, activity A ", 
		"WHERE H.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
		"AND H.posted_flag != \"Y\" ", 
		"AND H.period_num = ",glob_fisc_period," ", 
		"AND H.year_num = ",glob_fisc_year," ", 
		"AND H.cred_ind = \"3\" ", 
		"AND D.cmpy_code = H.cmpy_code ", 
		"AND D.cust_code = H.cust_code ", 
		"AND D.cred_num = H.cred_num ", 
		"AND A.cmpy_code = D.cmpy_code ", 
		"AND A.job_code = H.job_code ", 
		"AND A.activity_code = D.activity_code ", 
		"AND A.var_code = D.var_code ", 
		"AND D.ext_cos_amt != 0 " 
		IF glob_rec_poststatus.jour_num IS NULL THEN 
			LET modu_select_text = modu_select_text clipped, 
			" AND (H.rma_num IS NULL", 
			" OR H.rma_num = 0)" 
		ELSE 
			LET modu_select_text = modu_select_text clipped, 
			" AND (H.rma_num = ", glob_rec_poststatus.jour_num, 
			" OR H.rma_num IS NULL", 
			" OR H.rma_num = 0)" 
		END IF 
	ELSE 
		LET modu_select_text = "SELECT H.cred_num, ", 
		" D.line_num, ", 
		" D.activity_code, ", 
		" A.cos_acct_code, ", 
		" A.wip_acct_code, ", 
		" D.ext_cost_amt, ", 
		" A.title_text, ", 
		" H.currency_code, ", 
		" H.conv_qty, ", 
		" H.cred_date ", 
		"FROM postcredhead H, creditdetl D, activity A ", 
		"WHERE H.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
		"AND H.posted_flag != \"Y\" ", 
		"AND H.period_num = ",glob_fisc_period," ", 
		"AND H.year_num = ",glob_fisc_year," ", 
		"AND H.cred_ind = \"3\" ", 
		"AND D.cmpy_code = H.cmpy_code ", 
		"AND D.cust_code = H.cust_code ", 
		"AND D.cred_num = H.cred_num ", 
		"AND A.cmpy_code = D.cmpy_code ", 
		"AND A.job_code = H.job_code ", 
		"AND A.activity_code = D.activity_code ", 
		"AND D.ext_cost_amt != 0 ", 
		"AND A.var_code = D.var_code " 
	END IF 

	PREPARE sel_cosc FROM modu_select_text 
	DECLARE jm_cos_cc CURSOR FOR sel_cosc 

	LET glob_err_text = "FOREACH INTO postemp - jm cos" 
	FOREACH jm_cos_cc INTO modu_rec_credithead.cred_num, 
		modu_rec_creditdetl.line_num, 
		modu_rec_creditdetl.activity_code, 
		l_jm_cos_acct_code, 
		l_jm_wip_acct_code, 
		modu_rec_creditdetl.ext_cost_amt, 
		modu_rec_credithead.com1_text, 
		l_currency_code, 
		l_conv_qty, 
		l_inv_date 

		# note the activity name IS in batchdetl(posttemp).desc_text
		# put the invoice line number INTO batchdetl(posttemp).ref_text
		LET l_ref_text = "Line ", modu_rec_creditdetl.line_num USING "<<<" 

		IF modu_rec_creditdetl.ext_cost_amt != 0 OR l_base_amt != 0 THEN 
			IF l_conv_qty IS NOT NULL THEN 
				IF l_conv_qty != 0 THEN 
					LET l_base_amt = modu_rec_creditdetl.ext_cost_amt / l_conv_qty 
				END IF 
			END IF 

			# IF use_currency_flag IS 'N' THEN any source documents in foreign
			# currency need TO be converted TO base, AND a base batch created.
			IF glob_rec_glparms.use_currency_flag = "N" THEN 
				LET modu_rec_creditdetl.ext_cost_amt = l_base_amt 
				LET l_conv_qty = 1 
				LET l_currency_code = glob_rec_glparms.base_currency_code 
			END IF 

			IF get_debug() THEN 
				DISPLAY "INSERT INTO posttemp 10" 
			END IF 
			INSERT INTO posttemp VALUES (modu_rec_credithead.cred_num, 
			l_ref_text, 
			l_jm_cos_acct_code, 
			modu_rec_credithead.com1_text, 
			0, 
			modu_rec_creditdetl.ext_cost_amt, 
			0, 
			l_base_amt, 
			l_currency_code, 
			l_conv_qty, 
			l_inv_date, 
			0, 
			glob_rec_glparms.susp_acct_code) 

			IF get_debug() THEN 
				DISPLAY "INSERT INTO posttemp 11" 
			END IF 
			# Now debit the activity wip
			INSERT INTO posttemp VALUES (modu_rec_credithead.cred_num, 
			l_ref_text, 
			l_jm_wip_acct_code, 
			modu_rec_credithead.com1_text, 
			modu_rec_creditdetl.ext_cost_amt, 
			0, 
			l_base_amt, 
			0, 
			l_currency_code, 
			l_conv_qty, 
			l_inv_date, 
			0, 
			glob_rec_glparms.susp_acct_code) 

		END IF 

	END FOREACH 

	IF modu_post_status = 10 AND 
	glob_rec_poststatus.jour_num != 0 THEN 
		LET glob_posted_journal = glob_rec_poststatus.jour_num 
	ELSE 
		LET glob_posted_journal = NULL 
	END IF 

	IF get_debug() THEN 
		DISPLAY "CALL create_gl_batches() 4 FUNCTION jm_cos_postc()" 
	END IF 

	CALL create_gl_batches() 

	DELETE FROM posttemp WHERE 1 = 1 

	IF get_debug() THEN 
		DISPLAY "#### FUNCTION jm_cos_postc() END" 
	END IF 
END FUNCTION 


#######################################################
# FUNCTION receipt()
#
#
#######################################################
FUNCTION receipt() 
	DEFINE l_cmpy_code LIKE company.cmpy_code 
	DEFINE l_msgresp LIKE language.yes_flag 

	IF get_debug() THEN 
		DISPLAY "#### FUNCTION receipt() START" 
	END IF 

	GOTO bypass 
	LABEL recovery: 
	CALL update_poststatus(TRUE,STATUS,"AR") 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 

	# IF an error has occurred AND it was NOT in this part of the post THEN
	# walk on by ...
	IF modu_post_status > 17 AND modu_post_status < 99 THEN 
		RETURN 
	END IF 

	LET glob_err_text = "Commenced receipt post" 
	IF modu_post_status = 13 THEN {error in receipt post} 
		# 3507 "Rolling back postcashreceipt AND cashreceipt tables"
		ERROR kandoomsg2("A",3507,"") 
		SLEEP 2 
		LET glob_err_text = "Reversing previous cashreceipts" 

		IF NOT glob_one_trans THEN 
			BEGIN WORK 
				LET glob_in_trans = true 
			END IF 

			IF glob_rec_poststatus.online_ind != "L" THEN 
				LOCK TABLE postcashrcpt in share MODE 
				LOCK TABLE cashreceipt in share MODE 
			END IF 

			DECLARE cash_undo CURSOR FOR 
			SELECT cash_num 
			FROM postcashrcpt 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			FOR UPDATE 

			FOREACH cash_undo INTO modu_cash_num 

				UPDATE cashreceipt SET posted_flag = "N" 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cash_num = modu_cash_num 

				DELETE FROM postcashrcpt WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cash_num = modu_cash_num 

			END FOREACH 
			IF NOT glob_one_trans THEN 
			COMMIT WORK 
			LET glob_in_trans = false 
		END IF 
	END IF 

	LET glob_st_code = 13 
	LET glob_post_text = "Commenced INSERT INTO postcashrcpt " 
	CALL update_poststatus(FALSE,0,"AR") 

	IF modu_post_status = 13 OR modu_post_status = 99 THEN 
		# SELECT the credits FOR posting AND INSERT them INTO postcredhead
		# table THEN UPDATE them as posted so they won't be touched by
		# anyone ELSE
		LET glob_err_text = "Cashreceipt SELECT FOR INSERT" 
		DECLARE cash_curs CURSOR with HOLD FOR 
		SELECT h.cash_num 
		FROM cashreceipt h 
		WHERE h.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND h.posted_flag = "N" 
		AND h.year_num = glob_fisc_year 
		AND h.period_num = glob_fisc_period 

		LET glob_err_text = "Cash FOREACH FOR INSERT" 
		FOREACH cash_curs INTO modu_cash_num 
			LET modu_set_retry = retry_lock(glob_rec_kandoouser.cmpy_code,0) 
			WHILE (true) 
				IF NOT glob_one_trans THEN 
					BEGIN WORK 
						LET glob_in_trans = true 
					END IF 

					WHENEVER ERROR CONTINUE 

					DECLARE insert3_curs CURSOR FOR 
					SELECT * 
					FROM cashreceipt 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cash_num = modu_cash_num 
					FOR UPDATE 

					LET glob_err_text = "Cash lock FOR INSERT" 

					OPEN insert3_curs 
					FETCH insert3_curs INTO modu_rec_cashreceipt.* 
					LET modu_stat_code = status 
					IF modu_stat_code THEN 
						IF modu_stat_code = NOTFOUND THEN 
							IF NOT glob_one_trans THEN 
							COMMIT WORK 
						END IF 
						CONTINUE FOREACH 
					END IF 
					LET modu_set_retry = retry_lock(glob_rec_kandoouser.cmpy_code,modu_stat_code) 
					IF modu_set_retry <= 0 THEN 
						# one transaction users cannot retry since
						# we cannot resurrect the transaction which
						# has been rolled back
						IF NOT glob_one_trans THEN 
							LET modu_try_again = error_recover("Cash INSERT", 
							modu_stat_code) 
							IF modu_try_again != "Y" THEN 
								LET glob_in_trans = false 
								CALL update_poststatus(TRUE,modu_stat_code,"AR") 
							ELSE 
								ROLLBACK WORK 
								CONTINUE WHILE 
							END IF 
						ELSE 
							CALL update_poststatus(TRUE,modu_stat_code,"AR") 
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
		
		LET modu_set_retry = retry_lock(glob_rec_kandoouser.cmpy_code,0) 

		WHENEVER ERROR GOTO recovery 

		IF modu_rec_cashreceipt.currency_code IS NULL THEN 
			LET modu_rec_cashreceipt.currency_code = glob_rec_glparms.base_currency_code 
			LET modu_rec_cashreceipt.conv_qty = 1 
		END IF 
		IF modu_rec_cashreceipt.conv_qty IS NULL THEN 
			LET modu_rec_cashreceipt.conv_qty = 1 
		END IF 
		LET glob_err_text = "AS7 - Insert INTO postcashrcpt " 

		IF get_debug() THEN 
			DISPLAY "INSERT INTO postcashrcpt (there is only one instance)" 
		END IF 

		INSERT INTO postcashrcpt VALUES (modu_rec_cashreceipt.*) 

		LET glob_err_text = "AS7 - cashreceipt post flag SET" 
		UPDATE cashreceipt SET posted_flag = "Y" 
		WHERE CURRENT OF insert3_curs 

		IF NOT glob_one_trans THEN 
		COMMIT WORK 
		LET glob_in_trans = false 
	END IF 
END FOREACH 
END IF 

LET glob_err_text = "Update history - credits" 
LET glob_st_code = 14 
LET glob_post_text = "Completed INSERT TO postcashrcpt" 
CALL update_poststatus(FALSE,0,"AR") 

IF modu_post_status <= 14 OR modu_post_status = 99 THEN 
LET glob_err_text = "History SELECT on cash " 

DECLARE cheq1_curs CURSOR with HOLD FOR 
SELECT cust_code, 
count(*), 
sum(cash_amt), 
sum(disc_amt) 
INTO modu_client_cust_code, 
modu_counter, 
modu_totaller, 
modu_disc_totaller 
FROM postcashrcpt p 
WHERE p.cmpy_code = glob_rec_kandoouser.cmpy_code 
AND p.posted_flag != "H" 
AND p.period_num = glob_fisc_period 
AND p.year_num = glob_fisc_year 
GROUP BY cust_code 

FOREACH cheq1_curs 
	CALL init_hist() 

	LET modu_set_retry = retry_lock(glob_rec_kandoouser.cmpy_code,0) 
	WHILE (true) 
		IF NOT glob_one_trans THEN 
			BEGIN WORK 

				--SET CONSTRAINTS DEFERRED #Eric Tip
				EXECUTE immediate "SET CONSTRAINTS ALL deferred" 

				LET glob_in_trans = true 
			END IF 

			DECLARE chist_upd2 CURSOR FOR 
			SELECT * 
			FROM customerhist 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cust_code = modu_client_cust_code 
			AND year_num = glob_fisc_year 
			AND period_num = glob_fisc_period 
			FOR UPDATE 

			LET glob_err_text = " Customer History UPDATE receipts" 

			WHENEVER ERROR CONTINUE 

			OPEN chist_upd2 
			FETCH chist_upd2 INTO modu_rec_customerhist.* 
			LET modu_stat_code = status 
			IF modu_stat_code THEN 
				IF modu_stat_code = NOTFOUND THEN 
					IF NOT glob_one_trans THEN 
					COMMIT WORK 
					LET glob_in_trans = false 
				END IF 
				CONTINUE FOREACH 
			END IF 
			LET modu_set_retry = retry_lock(glob_rec_kandoouser.cmpy_code,modu_stat_code) 
			IF modu_set_retry <= 0 THEN 
				# glob_one_trans users cannot retry
				IF NOT glob_one_trans THEN 
					LET modu_try_again = error_recover("Chist receipt", 
					modu_stat_code) 
					IF modu_try_again != "Y" THEN 
						LET glob_in_trans = false 
						CALL update_poststatus(TRUE,modu_stat_code,"AR") 
					ELSE 
						IF NOT glob_one_trans THEN 
							ROLLBACK WORK 
							LET glob_in_trans = false 
						END IF 
						CONTINUE WHILE 
					END IF 
				ELSE 
					CALL update_poststatus(TRUE,modu_stat_code,"AR") 
				END IF 
			ELSE 
				IF NOT glob_one_trans THEN 
				COMMIT WORK 
				LET glob_in_trans = false 
			END IF 
			CONTINUE WHILE 
		END IF 
	END IF 
	EXIT WHILE 
END WHILE 
LET modu_set_retry = retry_lock(glob_rec_kandoouser.cmpy_code,0) 

WHENEVER ERROR GOTO recovery 

IF get_debug() THEN 
	DISPLAY "UPDATE customerhist" 
END IF 
UPDATE customerhist 
SET cash_qty = customerhist.cash_qty + modu_counter, 
cash_amt = customerhist.cash_amt + modu_totaller, 
disc_amt = customerhist.disc_amt + modu_disc_totaller 
WHERE CURRENT OF chist_upd2 

IF get_debug() THEN 
	DISPLAY "UPDATE postcashrcpt" 
END IF 

UPDATE postcashrcpt SET posted_flag = "H" 
WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
AND cust_code = modu_client_cust_code 

CLOSE chist_upd2 
IF NOT glob_one_trans THEN 
COMMIT WORK 
LET glob_in_trans = false 
END IF 


END FOREACH 
END IF 

LET glob_st_code = 15 
LET glob_post_text = "Completed history post" 
CALL update_poststatus(FALSE,0,"AR") 

IF modu_post_status <= 15 OR modu_post_status = 99 THEN 
IF glob_rec_arparms.gl_flag = "Y" THEN 
LET modu_prev_cust_type = "z" 
LET modu_rec_current.tran_type_ind = TRAN_TYPE_RECEIPT_CA 
LET modu_rec_current.jour_code = glob_rec_arparms.cash_jour_code 
LET modu_rec_current.base_credit_amt = 0 

# SELECT all unposted cash receipts FOR the required period

IF modu_post_status = 15 THEN {crapped out in receipt post} 
LET modu_select_text = "SELECT R.cmpy_code, ", 
" R.cash_num, ", 
" R.cust_code, ", 
" R.cash_date, ", 
" R.currency_code, ", 
" R.conv_qty, ", 
" C.type_code, ", 
" R.cash_acct_code, ", 
" R.cash_num, ", 
" R.cash_amt, ", 
" 0, ", 
" R.disc_amt ", 
"FROM postcashrcpt R, customer C ", 
"WHERE R.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
"AND R.posted_flag != \"Y\" ", 
"AND R.year_num = ",glob_fisc_year," ", 
"AND R.period_num = ",glob_fisc_period," ", 
"AND R.cmpy_code = C.cmpy_code ", 
"AND R.cust_code = C.cust_code " 
IF glob_rec_poststatus.jour_num IS NULL THEN 
	LET modu_select_text = modu_select_text clipped, 
	" AND (R.jour_num IS NULL", 
	" OR R.jour_num = 0)", 
	" ORDER BY R.cmpy_code, R.cust_code,", 
	" R.cash_num" 
ELSE 
	LET modu_select_text = modu_select_text clipped, 
	" AND (R.jour_num = ", 
	glob_rec_poststatus.jour_num, 
	" OR R.jour_num IS NULL", 
	" OR R.jour_num = 0)", 
	" ORDER BY R.cmpy_code, R.cust_code,", 
	" R.cash_num" 
END IF 
ELSE 
LET modu_select_text = "SELECT R.cmpy_code, ", 
" R.cash_num, ", 
" R.cust_code, ", 
" R.cash_date, ", 
" R.currency_code, ", 
" R.conv_qty, ", 
" C.type_code, ", 
" R.cash_acct_code, ", 
" R.cash_num, ", 
" R.cash_amt, ", 
" 0, ", 
" R.disc_amt ", 
"FROM postcashrcpt R, customer C ", 
"WHERE R.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
"AND R.posted_flag != \"Y\" ", 
"AND R.year_num = ",glob_fisc_year," ", 
"AND R.period_num = ",glob_fisc_period," ", 
"AND R.cmpy_code = C.cmpy_code ", 
"AND R.cust_code = C.cust_code ", 
"ORDER BY R.cmpy_code, R.cust_code, ", 
" R.cash_num " 
END IF 

PREPARE sel_cash FROM modu_select_text 
DECLARE ca_curs CURSOR FOR sel_cash 

LET glob_err_text = "FOREACH INTO posttemp - cash" 

IF get_debug() THEN 
DISPLAY "BEFORE FOR EACH" 
END IF 
FOREACH ca_curs INTO l_cmpy_code, 
modu_rec_docdata.*, 
modu_rec_current.cust_type, 
modu_rec_detldata.*, 
modu_rec_current.disc_amt 

IF get_debug() THEN 
	DISPLAY "FIRST Line of FOR EACH" 
END IF 

IF modu_rec_current.cust_type != modu_prev_cust_type OR 
(modu_rec_current.cust_type IS NULL AND 
modu_prev_cust_type IS NOT null) OR 
(modu_rec_current.cust_type IS NOT NULL AND 
modu_prev_cust_type IS null) THEN 
	CALL get_cust_accts("") 
END IF 

# INSERT posting data FOR the Receipt discount amount

IF modu_rec_current.disc_amt IS NOT NULL AND 
modu_rec_current.disc_amt != 0 THEN 
	IF modu_rec_docdata.conv_qty IS NOT NULL THEN 
		IF modu_rec_docdata.conv_qty != 0 THEN 
			LET modu_rec_current.base_debit_amt = 
			modu_rec_current.disc_amt / 
			modu_rec_docdata.conv_qty 
		END IF 
	END IF 

	# IF use_currency_flag IS 'N' THEN any source documents in foreign
	# currency need TO be converted TO base, AND a base batch created.
	IF glob_rec_glparms.use_currency_flag = "N" THEN 
		LET modu_rec_current.disc_amt = modu_rec_current.base_debit_amt 

		LET modu_rec_docdata.currency_code = 
		glob_rec_glparms.base_currency_code 
		LET modu_sv_conv_qty = 1 
	ELSE 
		LET modu_sv_conv_qty = modu_rec_docdata.conv_qty 
	END IF 

	IF get_debug() THEN 
		DISPLAY "INSERT INTO posttemp 12" 
	END IF 
	INSERT INTO posttemp VALUES 
	(modu_rec_docdata.ref_num, # receipt number 
	modu_rec_docdata.ref_text, # customer code 
	modu_rec_current.disc_acct_code, # discount control acct 
	modu_rec_docdata.ref_num, # receipt number 
	modu_rec_current.disc_amt, # receipt disc amount 
	0, 
	modu_rec_current.base_debit_amt, # converted discount amt 
	modu_rec_current.base_credit_amt, # 0 FOR receipts 
	modu_rec_docdata.currency_code, # receipt currency code 

	modu_sv_conv_qty, 
	modu_rec_docdata.tran_date, # receipt DATE 
	0, # stats qty NOT in use 
	modu_rec_current.ar_acct_code) # ar control account 
END IF 

# create posting details FOR the selected receipts

IF modu_rec_docdata.conv_qty IS NOT NULL THEN 
	IF modu_rec_docdata.conv_qty != 0 THEN 
		LET modu_rec_current.base_debit_amt = modu_rec_detldata.debit_amt / 
		modu_rec_docdata.conv_qty 
	END IF 
END IF 

# IF use_currency_flag IS 'N' THEN any source documents in foreign
# currency need TO be converted TO base, AND a base batch created.
IF glob_rec_glparms.use_currency_flag = "N" THEN 
	LET modu_rec_detldata.debit_amt = modu_rec_current.base_debit_amt 

	LET modu_rec_docdata.currency_code = glob_rec_glparms.base_currency_code 
	LET modu_sv_conv_qty = 1 
ELSE 
	LET modu_sv_conv_qty = modu_rec_docdata.conv_qty 
END IF 

IF get_debug() THEN 
	DISPLAY "INSERT INTO posttemp 13" 
END IF 
INSERT INTO posttemp VALUES 
(modu_rec_docdata.ref_num, # receipt number 
modu_rec_docdata.ref_text, # customer code 
modu_rec_detldata.post_acct_code, # cash receipt gl account 
modu_rec_detldata.desc_text, # recipt number 
modu_rec_detldata.debit_amt, # receipt amount 
modu_rec_detldata.credit_amt, # zero FOR TRAN_TYPE_RECEIPT_CA 
modu_rec_current.base_debit_amt, # converted receipt amt 
modu_rec_current.base_credit_amt, # 0 FOR receipts 
modu_rec_docdata.currency_code, # receipt currency code 

modu_sv_conv_qty, 
modu_rec_docdata.tran_date, # receipt DATE 
0, # stats qty NOT yet in use 
modu_rec_current.ar_acct_code) # ar control account 

IF get_debug() THEN 
	DISPLAY "Last Line of FOR EACH" 
END IF 

END FOREACH 

IF get_debug() THEN 
DISPLAY "AFTER END FOR EACH" 
END IF 

LET modu_rec_bal.tran_type_ind = TRAN_TYPE_RECEIPT_CA 
LET modu_rec_bal.desc_text = "AR Receipt Balancing Entry" 

IF modu_post_status = 15 AND 
glob_rec_poststatus.jour_num != 0 THEN 
LET glob_posted_journal = glob_rec_poststatus.jour_num 
ELSE 
LET glob_posted_journal = NULL 
END IF 

MESSAGE " " 
# 3508 "Posting cash"
MESSAGE kandoomsg2("A",3508,"") 
SLEEP 1 

IF glob_rec_arparms.detail_to_gl_flag = "N" THEN 
LET modu_passed_desc = "Summary AR Receipts ", 
glob_fisc_year USING "<<<<", " ", 
glob_fisc_period USING "<<" 
CALL create_summ_batches() 
ELSE 

IF get_debug() THEN 
	DISPLAY "CALL create_gl_batches() 5 FROM FUNCTION receipt()" 
END IF 

CALL create_gl_batches() 
END IF 

DELETE FROM posttemp WHERE 1 = 1 
END IF 
END IF 

LET glob_st_code = 16 
LET glob_post_text = "Commenced UPDATE jour_num FROM postcashrcpt" 
CALL update_poststatus(FALSE,0,"AR") 

IF modu_post_status != 17 THEN 
LET glob_err_text = "Update jour_num in cashreceipt" 
DECLARE update_jour3 CURSOR with HOLD FOR 
SELECT * 
FROM postcashrcpt 
WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 

FOREACH update_jour3 INTO modu_rec_cashreceipt.* 
IF NOT glob_one_trans THEN 
BEGIN WORK 



	LET glob_in_trans = true 
END IF 
UPDATE cashreceipt SET jour_num = modu_rec_cashreceipt.jour_num, 
post_date = today 
WHERE cmpy_code = modu_rec_cashreceipt.cmpy_code 
AND cust_code = modu_rec_cashreceipt.cust_code 
AND cash_num = modu_rec_cashreceipt.cash_num 

IF NOT glob_one_trans THEN 
COMMIT WORK 
LET glob_in_trans = false 
END IF 
END FOREACH 
END IF 

LET glob_st_code = 17 
LET glob_post_text = "Commenced DELETE FROM postcashrcpt" 
CALL update_poststatus(FALSE,0,"AR") 

LET glob_err_text = "DELETE FROM postcashrcpt" 
IF NOT glob_one_trans THEN 
BEGIN WORK 



LET glob_in_trans = true 
END IF 
IF glob_rec_poststatus.online_ind != "L" THEN 
LOCK TABLE postcashrcpt in share MODE 
END IF 
DELETE FROM postcashrcpt WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
IF NOT glob_one_trans THEN 
COMMIT WORK 
LET glob_in_trans = false 
END IF 

LET glob_st_code = 99 
LET glob_post_text = "Cash posting completed correctly" 
CALL update_poststatus(FALSE,0,"AR") 

WHENEVER ERROR stop 
WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

IF get_debug() THEN 
DISPLAY "#### FUNCTION receipt() END" 
END IF 
END FUNCTION 



#######################################################
# FUNCTION exch_var()
#
#
#######################################################
FUNCTION exch_var() 
	DEFINE l_rowid INTEGER 
	DEFINE l_rowid_num INTEGER 
	DEFINE l_msgresp LIKE language.yes_flag 

	IF get_debug() THEN 
		DISPLAY "#### FUNCTION exch_var() START" 
	END IF 

	GOTO bypass 
	LABEL recovery: 
	CALL update_poststatus(TRUE,STATUS,"AR") 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 


	#      Changed the way the program selected exchangevar TO use rowid. This IS
	#      cause using the old way, it did NOT work due TO duplicates.


	# IF an error has occurred AND it was NOT in this part of the post
	# THEN 'baby walk on by, just walk on by (etc)'
	IF modu_post_status > 22 AND modu_post_status < 99 THEN 
		RETURN 
	END IF 

	LET glob_err_text = "Commenced exchange post" 
	IF modu_post_status = 18 THEN {error in exchangevar post} 
		# 3520 "Rolling back postexchvar AND exchangevar tables"
		ERROR kandoomsg2("P",3520,"") 
		SLEEP 2 
		LET glob_err_text = "Reversing previous Invoices" 

		IF NOT glob_one_trans THEN 
			BEGIN WORK 



				LET glob_in_trans = true 
			END IF 

			IF glob_rec_poststatus.online_ind != "L" THEN 
				LOCK TABLE postexchvar in share MODE 
				LOCK TABLE exchangevar in share MODE 
			END IF 

			LET glob_in_trans = true 
			DECLARE exch_undo CURSOR FOR 
			SELECT rowid, #the rowid FROM postexchvar 
			rowid_num, #the rowid FROM exchangevar 
			tran_type1_ind, 
			ref1_num, 
			tran_type2_ind, 
			ref2_num 
			FROM postexchvar 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			FOR UPDATE 

			FOREACH exch_undo 
				INTO l_rowid, #the rowid FROM postexchvar 
				l_rowid_num, #the rowid FROM exchangevar 
				modu_tran_type1_ind, 
				modu_ref1_num, 
				modu_tran_type2_ind, 
				modu_ref2_num 

				UPDATE exchangevar SET posted_flag = "N" 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND rowid = l_rowid_num 





				DELETE FROM postexchvar WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND rowid = l_rowid 




			END FOREACH 
			IF NOT glob_one_trans THEN 
			COMMIT WORK 
			LET glob_in_trans = false 
		END IF 
	END IF 

	LET glob_st_code = 18 
	LET glob_post_text = "Commenced INSERT INTO postexchvar" 
	CALL update_poststatus(FALSE,0,"AR") 

	IF modu_post_status = 18 OR modu_post_status = 99 THEN 
		# SELECT the exchangevars FOR posting AND INSERT them INTO the
		# postexchvar table THEN UPDATE them as posted so they won't be touched
		# by anyone.
		LET glob_err_text = "Exchangevar SELECT FOR INSERT" 
		DECLARE exch_curs CURSOR with HOLD FOR 
		SELECT rowid, 
		tran_type1_ind, 
		ref1_num, 
		tran_type2_ind, 
		ref2_num 
		FROM exchangevar 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND posted_flag = "N" 
		AND period_num = glob_fisc_period 
		AND year_num = glob_fisc_year 
		AND source_ind = "A" 

		LET glob_err_text = "Exchangevar FOREACH FOR INSERT" 
		FOREACH exch_curs INTO l_rowid, 
			modu_tran_type1_ind, 
			modu_ref1_num, 
			modu_tran_type2_ind, 
			modu_ref2_num 
			LET modu_set_retry = retry_lock(glob_rec_kandoouser.cmpy_code,0) 
			WHILE (true) 
				IF NOT glob_one_trans THEN 
					BEGIN WORK 



						LET glob_in_trans = true 
					END IF 
					WHENEVER ERROR CONTINUE 

					DECLARE insert4_curs CURSOR FOR 
					SELECT * 
					FROM exchangevar 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND rowid = l_rowid 




					FOR UPDATE 

					LET glob_err_text = "Exchangevar lock FOR INSERT" 
					OPEN insert4_curs 
					FETCH insert4_curs INTO modu_rec_exchangevar.* 
					LET modu_stat_code = status 
					IF modu_stat_code THEN 
						IF modu_stat_code = NOTFOUND THEN 
							IF NOT glob_one_trans THEN 
							COMMIT WORK 
						END IF 
						CONTINUE FOREACH 
					END IF 
					LET modu_set_retry = retry_lock(glob_rec_kandoouser.cmpy_code,modu_stat_code) 
					IF modu_set_retry <= 0 THEN 
						# one transaction users cannot retry since
						# we cannot resurrect the transaction which
						# has been rolled back
						IF NOT glob_one_trans THEN 
							LET modu_try_again = error_recover("Exchvar INSERT", 
							modu_stat_code) 
							IF modu_try_again != "Y" THEN 
								LET glob_in_trans = false 
								CALL update_poststatus(TRUE,modu_stat_code,"AR") 
							ELSE 
								ROLLBACK WORK 
								CONTINUE WHILE 
							END IF 
						ELSE 
							CALL update_poststatus(TRUE,modu_stat_code,"AR") 
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
		LET modu_set_retry = retry_lock(glob_rec_kandoouser.cmpy_code,0) 

		WHENEVER ERROR GOTO recovery 

		LET glob_err_text = "PP1 - Post Exchangevar INSERT" 

		IF get_debug() THEN 
			DISPLAY "INSERT INTO postexchvar (there is only one instance)" 
		END IF 

		INSERT INTO postexchvar VALUES (modu_rec_exchangevar.*, 
		l_rowid) 

		LET glob_err_text = "PP1 - Exchangevar post flag SET" 
		UPDATE exchangevar SET posted_flag = "Y" 
		WHERE CURRENT OF insert4_curs 

		IF NOT glob_one_trans THEN 
		COMMIT WORK 
		LET glob_in_trans = false 
	END IF 
END FOREACH 
END IF 

LET glob_err_text = "Create gl batch - exchangevar" 
LET glob_st_code = 19 
CALL update_poststatus(FALSE,0,"AR") 

IF modu_post_status <= 19 OR modu_post_status = 99 THEN 
LET modu_prev_cust_type = "z" 
LET modu_rec_current.tran_type_ind = "EXA" 
LET modu_rec_current.jour_code = glob_rec_arparms.cash_jour_code 

# INSERT posting data FOR the Receivables exchange variances
# positive VALUES post as debits, negative VALUES as credits
# with sign reversed

IF modu_post_status = 19 THEN {post crapped out in ar vars} 
	LET modu_select_text = 
	"SELECT E.ref1_num, ", 
	" E.ref2_num, ", 
	" E.tran_date, ", 
	" E.currency_code, ", 
	" 1, ", 
	" E.ref_code, ", 
	" E.exchangevar_amt, ", 
	" C.type_code ", 
	"FROM postexchvar E, customer C ", 
	"WHERE E.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND E.posted_flag = \"N\" ", 
	"AND E.year_num = ",glob_fisc_year," ", 
	"AND E.period_num = ",glob_fisc_period," ", 
	"AND E.source_ind = \"A\" ", 
	"AND E.cmpy_code = C.cmpy_code ", 
	"AND E.ref_code = C.cust_code ", 
	"AND E.exchangevar_amt > 0 " 
	IF glob_rec_poststatus.jour_num IS NULL THEN 
		LET modu_select_text = modu_select_text clipped, 
		" AND (E.jour_num IS NULL", 
		" OR E.jour_num = 0)", 
		" ORDER BY E.ref_code" 
	ELSE 
		LET modu_select_text = modu_select_text clipped, 
		" AND (E.jour_num = ", 
		glob_rec_poststatus.jour_num, 
		" OR E.jour_num IS NULL", 
		" OR E.jour_num = 0)", 
		" ORDER BY E.ref_code" 
	END IF 
ELSE {normal post} 
	LET modu_select_text = 
	"SELECT E.ref1_num, ", 
	" E.ref2_num, ", 
	" E.tran_date, ", 
	" E.currency_code, ", 
	" 1, ", 
	" E.ref_code, ", 
	" E.exchangevar_amt, ", 
	" C.type_code ", 
	"FROM postexchvar E, customer C ", 
	"WHERE E.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND E.posted_flag = \"N\" ", 
	"AND E.year_num = ",glob_fisc_year," ", 
	"AND E.period_num = ",glob_fisc_period," ", 
	"AND E.source_ind = \"A\" ", 
	"AND E.cmpy_code = C.cmpy_code ", 
	"AND E.ref_code = C.cust_code ", 
	"AND E.exchangevar_amt > 0 ", 
	"ORDER BY E.ref_code " 
END IF 

PREPARE exch_sel FROM modu_select_text 
DECLARE exd_curs CURSOR FOR exch_sel 

LET glob_err_text = "FOREACH AR (+ve) exchangevar" 
FOREACH exd_curs INTO modu_rec_docdata.*, 
	modu_rec_current.exch_ref_code, 
	modu_rec_current.base_debit_amt, 
	modu_rec_current.cust_type 

	IF modu_rec_current.cust_type != modu_prev_cust_type OR 
	(modu_rec_current.cust_type IS NULL AND modu_prev_cust_type IS NOT null) OR 
	(modu_rec_current.cust_type IS NOT NULL AND modu_prev_cust_type IS null) THEN 
		CALL get_cust_accts("") 
	END IF 

	IF get_debug() THEN 
		DISPLAY "INSERT INTO posttemp 14" 
	END IF 
	INSERT INTO posttemp VALUES 
	(modu_rec_docdata.ref_num, # exch var ref 1 
	modu_rec_docdata.ref_text, # exch var ref 2 
	modu_rec_current.exch_acct_code, # exchange control account 
	modu_rec_current.exch_ref_code, # customer code FOR source_ind "A" 
	modu_rec_current.base_debit_amt, # exchange var foreign amount - always in base 
	0, 
	modu_rec_current.base_debit_amt, # exch var amount IF +ve, 
	0, 
	glob_rec_glparms.base_currency_code, # base currency code 
	modu_rec_docdata.conv_qty, # exch var conversion rate 
	modu_rec_docdata.tran_date, # exch var DATE 
	0, # stats qty - NOT yet in use 
	modu_rec_current.ar_acct_code) # control account 
END FOREACH 

LET modu_rec_bal.tran_type_ind = "EXA" 
LET modu_rec_bal.desc_text = " AR Exch Var Balancing Entry" 

IF modu_post_status = 19 AND 
glob_rec_poststatus.jour_num != 0 THEN 
	LET glob_posted_journal = glob_rec_poststatus.jour_num 
ELSE 
	LET glob_posted_journal = NULL 
END IF 

MESSAGE "" 
# 3506 " Posting exch var..."
MESSAGE kandoomsg2("P",3506,"") 
SLEEP 1 

IF get_debug() THEN 
	DISPLAY "CALL create_gl_batches() 6 function exch_var()" 
END IF 

CALL create_gl_batches() 

DELETE FROM posttemp WHERE 1 = 1 
END IF 
LET glob_st_code = 20 
LET glob_post_text = "Commenced part 2 of exchangevar" 
CALL update_poststatus(FALSE,0,"AR") 

IF modu_post_status <= 20 OR modu_post_status = 99 THEN 
LET modu_prev_cust_type = "z" 
LET modu_rec_current.tran_type_ind = "EXA" 
LET modu_rec_current.jour_code = glob_rec_arparms.cash_jour_code 
IF modu_post_status = 20 THEN {postcrapped out here OR above} 
	LET modu_select_text = 
	"SELECT E.ref1_num, ", 
	" E.ref2_num, ", 
	" E.tran_date, ", 
	" E.currency_code, ", 
	" 1, ", 
	" E.ref_code, ", 
	" E.exchangevar_amt, ", 
	" C.type_code ", 
	"FROM postexchvar E, customer C ", 
	"WHERE E.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND E.posted_flag = \"N\" ", 
	"AND E.year_num = ",glob_fisc_year," ", 
	"AND E.period_num = ",glob_fisc_period," ", 
	"AND E.source_ind = \"A\" ", 
	"AND E.cmpy_code = C.cmpy_code ", 
	"AND E.ref_code = C.cust_code ", 
	"AND E.exchangevar_amt < 0 " 
	IF glob_rec_poststatus.jour_num IS NULL THEN 
		LET modu_select_text = modu_select_text clipped, 
		" AND (E.jour_num IS NULL", 
		" OR E.jour_num = 0)", 
		" ORDER BY E.ref_code" 
	ELSE 
		LET modu_select_text = modu_select_text clipped, 
		" AND (E.jour_num = ", 
		glob_rec_poststatus.jour_num, 
		" OR E.jour_num IS NULL", 
		" OR E.jour_num = 0)", 
		" ORDER BY E.ref_code" 
	END IF 
ELSE {normal post} 
	LET modu_select_text = 
	"SELECT E.ref1_num, ", 
	" E.ref2_num, ", 
	" E.tran_date, ", 
	" E.currency_code, ", 
	" 1, ", 
	" E.ref_code, ", 
	" E.exchangevar_amt, ", 
	" C.type_code ", 
	"FROM postexchvar E, customer C ", 
	"WHERE E.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND E.posted_flag = \"N\" ", 
	"AND E.year_num = ",glob_fisc_year," ", 
	"AND E.period_num = ",glob_fisc_period," ", 
	"AND E.source_ind = \"A\" ", 
	"AND E.cmpy_code = C.cmpy_code ", 
	"AND E.ref_code = C.cust_code ", 
	"AND E.exchangevar_amt < 0 ", 
	"ORDER BY E.ref_code " 
END IF 

PREPARE exc_sel FROM modu_select_text 
DECLARE exc_curs CURSOR FOR exc_sel 

LET glob_err_text = "FOREACH AR (-ve) exch variation" 
FOREACH exc_curs INTO modu_rec_docdata.*, 
	modu_rec_current.exch_ref_code, 
	modu_rec_current.base_credit_amt, 
	modu_rec_current.cust_type 

	IF modu_rec_current.cust_type != modu_prev_cust_type OR 
	(modu_rec_current.cust_type IS NULL AND modu_prev_cust_type IS NOT null) OR 
	(modu_rec_current.cust_type IS NOT NULL AND modu_prev_cust_type IS null) THEN 
		CALL get_cust_accts("") 
	END IF 

	LET modu_rec_current.base_credit_amt = 0 - modu_rec_current.base_credit_amt - 0 


	IF get_debug() THEN 
		DISPLAY "INSERT INTO posttemp 15" 
	END IF 

	INSERT INTO posttemp VALUES 
	(modu_rec_docdata.ref_num, # exch var ref 1 
	modu_rec_docdata.ref_text, # exch var ref 2 
	modu_rec_current.exch_acct_code, # exchange control account 
	modu_rec_current.exch_ref_code, # customer code FOR source_ind "A" 
	0, 
	modu_rec_current.base_credit_amt, # exchange var foreign amount - always in base 
	0, 
	modu_rec_current.base_credit_amt, # exch var amount 
	# IF -ve (sign reversed)
	glob_rec_glparms.base_currency_code, # base currency code 
	modu_rec_docdata.conv_qty, # exch var conversion rate 
	modu_rec_docdata.tran_date, # exch var DATE 
	0, # stats qty - NOT yet in use 
	modu_rec_current.ar_acct_code) # control account 
END FOREACH 

LET modu_rec_bal.tran_type_ind = "EXA" 
LET modu_rec_bal.desc_text = " AR Exch Var Balancing Entry" 

IF modu_post_status = 20 AND 
glob_rec_poststatus.jour_num != 0 THEN 
	LET glob_posted_journal = glob_rec_poststatus.jour_num 
ELSE 
	LET glob_posted_journal = NULL 
END IF 

MESSAGE "" 
# 3506 " Posting exch var..." AT 1,1
MESSAGE kandoomsg2("P",3506,"") 
SLEEP 1 

#call fgl_winmessage("CALL create_gl_batches()","CALL create_gl_batches() \n7","info")

IF get_debug() THEN 
	DISPLAY "CALL create_gl_batches() 7 FUNCTION exch_var()" 
END IF 

CALL create_gl_batches() 
END IF 


LET glob_st_code = 21 
LET glob_post_text = "Commenced upd jour_num FROM postexchvar" 
CALL update_poststatus(FALSE,0,"AR") 

IF modu_post_status != 22 THEN 
LET glob_err_text = "Update jour_num in exchangevar" 
DECLARE update_exchvar CURSOR with HOLD FOR 
SELECT * #including rowid_num, e.g. rowid FROM exchangevar 
FROM postexchvar 
WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 

FOREACH update_exchvar INTO modu_rec_exchangevar.*, l_rowid 
	IF NOT glob_one_trans THEN 
		BEGIN WORK 




			LET glob_in_trans = true 
		END IF 
		UPDATE exchangevar 
		SET jour_num = modu_rec_exchangevar.jour_num, 
		post_date = today 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND rowid = l_rowid 




		IF NOT glob_one_trans THEN 
		COMMIT WORK 
		LET glob_in_trans = false 
	END IF 
END FOREACH 
END IF 

LET glob_st_code = 22 
LET glob_post_text = "Commenced DELETE FROM postexchvar" 
CALL update_poststatus(FALSE,0,"AR") 

LET glob_err_text = "DELETE FROM postexchvar" 

IF NOT glob_one_trans THEN 
	BEGIN WORK 
	LET glob_in_trans = true 
END IF 

IF glob_rec_poststatus.online_ind != "L" THEN 
	LOCK TABLE postexchvar in share MODE 
END IF 
DELETE FROM postexchvar WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
IF NOT glob_one_trans THEN 
COMMIT WORK 
LET glob_in_trans = false 
END IF 

LET glob_st_code = 99 
LET glob_post_text = "Exchange var posting completed correctly" 
CALL update_poststatus(FALSE,0,"AR") 

IF get_debug() THEN 
DISPLAY "#### FUNCTION exch_var() END" 
END IF 

END FUNCTION 



#######################################################
# FUNCTION add_tax(p_tax_code, p_tax_amt)
#
#
#######################################################
FUNCTION add_tax(p_tax_code, p_tax_amt) 
	DEFINE p_tax_code LIKE tax.tax_code 
	DEFINE p_tax_amt LIKE invoicedetl.ext_tax_amt 
	DEFINE l_t_rowid SMALLINT 

	IF get_debug() THEN 
		DISPLAY "#### FUNCTION add_tax() START" 
	END IF 

	GOTO bypass 
	LABEL recovery: 
	CALL update_poststatus(TRUE,STATUS,"AR") 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 

	# Posting account IS current FOR type IF tax code IS NULL OR FROM
	# tax table (defaulting TO current) OTHERWISE

	IF p_tax_code IS NULL THEN 
		LET modu_rec_taxtemp.tax_acct_code = modu_rec_current.tax_acct_code 
	ELSE 
		SELECT sell_acct_code 
		INTO modu_rec_taxtemp.tax_acct_code 
		FROM tax 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND tax_code = p_tax_code 
		IF status = NOTFOUND THEN 
			LET modu_rec_taxtemp.tax_acct_code = NULL 
		END IF 
		IF modu_rec_taxtemp.tax_acct_code IS NULL 
		OR modu_rec_taxtemp.tax_acct_code = " " THEN 
			LET modu_rec_taxtemp.tax_acct_code = modu_rec_current.tax_acct_code 
		END IF 
	END IF 

	# IF a total already exists FOR this account, add TO it, OTHERWISE
	# INSERT it
	SELECT rowid 
	INTO l_t_rowid 
	FROM taxtemp 
	WHERE tax_acct_code = modu_rec_taxtemp.tax_acct_code 
	IF status = NOTFOUND THEN 
		LET modu_rec_taxtemp.tax_amt = p_tax_amt 

		IF get_debug() THEN 
			DISPLAY "INSERT INTO taxtemp (there is only one instance)" 
		END IF 
		INSERT INTO taxtemp VALUES (modu_rec_taxtemp.*) 
	ELSE 
		UPDATE taxtemp SET tax_amt = tax_amt + p_tax_amt 
		WHERE rowid = l_t_rowid 
	END IF 

	IF get_debug() THEN 
		DISPLAY "#### FUNCTION add_tax() END" 
	END IF 
END FUNCTION 


#######################################################
# FUNCTION tax_postings(p_post_type)
#
#
#######################################################
FUNCTION tax_postings(p_post_type) 
	DEFINE p_post_type CHAR(2) 
	DEFINE l_rnd_tax_amt_cr LIKE batchdetl.credit_amt 
	DEFINE l_rnd_tax_amt_dr LIKE batchdetl.debit_amt 

	IF get_debug() THEN 
		DISPLAY "#### FUNCTION tax_postings() START" 
	END IF 

	GOTO bypass 
	LABEL recovery: 
	CALL update_poststatus(TRUE,STATUS,"AR") 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 


	DECLARE c_taxtemp CURSOR FOR 
	SELECT * 
	INTO modu_rec_taxtemp.* 
	FROM taxtemp 
	WHERE tax_amt != 0 

	FOREACH c_taxtemp 
		IF p_post_type = TRAN_TYPE_CREDIT_CR THEN 
			IF modu_rec_docdata.conv_qty IS NOT NULL THEN 
				IF modu_rec_docdata.conv_qty != 0 THEN 
					LET modu_rec_current.base_credit_amt = modu_rec_taxtemp.tax_amt / 
					modu_rec_docdata.conv_qty 
				END IF 
			END IF 

			LET l_rnd_tax_amt_cr = modu_rec_taxtemp.tax_amt * 1 
			LET l_rnd_tax_amt_dr = 0 
			# IF use_currency_flag IS 'N' THEN any source documents in foreign
			# currency need TO be converted TO base, AND a base batch created.
			IF glob_rec_glparms.use_currency_flag = "N" THEN 
				LET l_rnd_tax_amt_cr = modu_rec_current.base_credit_amt 

				LET modu_rec_docdata.currency_code = glob_rec_glparms.base_currency_code 
				LET modu_sv_conv_qty = 1 
			ELSE 
				LET modu_sv_conv_qty = modu_rec_docdata.conv_qty 
			END IF 
		ELSE 
			IF modu_rec_docdata.conv_qty IS NOT NULL THEN 
				IF modu_rec_docdata.conv_qty != 0 THEN 
					LET modu_rec_current.base_debit_amt = modu_rec_taxtemp.tax_amt / 
					modu_rec_docdata.conv_qty 
				END IF 
			END IF 

			LET l_rnd_tax_amt_dr = modu_rec_taxtemp.tax_amt * 1 
			LET l_rnd_tax_amt_cr = 0 
			# IF use_currency_flag IS 'N' THEN any source documents in foreign
			# currency need TO be converted TO base, AND a base batch created.
			IF glob_rec_glparms.use_currency_flag = "N" THEN 
				LET l_rnd_tax_amt_dr = modu_rec_current.base_debit_amt 
				LET modu_rec_docdata.conv_qty = 1 
				LET modu_rec_docdata.currency_code = glob_rec_glparms.base_currency_code 
				LET modu_sv_conv_qty = 1 
			ELSE 
				LET modu_sv_conv_qty = modu_rec_docdata.conv_qty 
			END IF 
		END IF 

		IF get_debug() THEN 
			DISPLAY "INSERT INTO posttemp 16" 
		END IF 

		INSERT INTO posttemp VALUES 
		(modu_rec_docdata.ref_num, # inv/cred number 
		modu_rec_docdata.ref_text, # customer code 
		modu_rec_taxtemp.tax_acct_code, # tax posting account 
		modu_rec_docdata.ref_num, # inv/cred number 
		l_rnd_tax_amt_dr, # rounded tax amount FOR 
		l_rnd_tax_amt_cr, # this account 
		modu_rec_current.base_debit_amt, # converted tax amt 
		modu_rec_current.base_credit_amt, # converted tax amt 
		modu_rec_docdata.currency_code, # inv/cred currency code 

		modu_sv_conv_qty, 
		modu_rec_docdata.tran_date, # inv/cred DATE 
		0, # stats qty NOT yet in use 
		modu_rec_current.ar_acct_code) # ar control account 
	END FOREACH 

	DELETE FROM taxtemp WHERE 1 = 1 

	IF get_debug() THEN 
		DISPLAY "#### FUNCTION tax_postings() END" 
	END IF 
	
END FUNCTION 


#######################################################
# FUNCTION AS7_post_AR()
#
#
#######################################################
FUNCTION AS7_post_AR() 
	DEFINE l_msgresp LIKE language.yes_flag 

	IF get_debug() THEN 
		DISPLAY "#### FUNCTION AS7_post_AR() START" 
	END IF 

	GOTO bypass 
	LABEL recovery: 
	CALL update_poststatus(TRUE,0,"AR") 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 

	#------------------------------------------------------------
	#rmsreps entries
	LET glob_rec_rpt_selector.sel_text = modu_sel_text
	LET glob_rec_rpt_selector.ref1_num = glob_fisc_period
	LET glob_rec_rpt_selector.ref2_num = glob_fisc_year
	
	LET glob_rec_rpt_selector.ref1_code = modu_rec_current.jour_code
	LET glob_rec_rpt_selector.ref2_code = modu_rec_current.currency_code
	LET glob_rec_rpt_selector.ref3_code = modu_rec_bal.acct_code
	LET glob_rec_rpt_selector.ref4_code = modu_rec_bal.tran_type_ind #LIKE batchdetl.tran_type_ind #nchar(3)

	LET glob_rec_rpt_selector.ref2_text = modu_rec_bal.desc_text #LIKE batchdetl.desc_text
				
	LET glob_rec_rpt_selector.ref1_amt = modu_sl_id
	#------------------------------------------------------------
	LET modu_rpt_idx = rpt_start(getmoduleid(),"COM_jourintf_rpt_list_bd",modu_sel_text, RPT_SHOW_RMS_DIALOG)
	IF modu_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT COM_jourintf_rpt_list_bd TO rpt_get_report_file_with_path2(modu_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[modu_rpt_idx].page_length_num , 
	TOP MARGIN = 0, 
	BOTTOM MARGIN = 0, 
	LEFT MARGIN = 0, 
	RIGHT MARGIN = 0
	#------------------------------------------------------------

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
		LOCK TABLE arparms in share MODE 
		LOCK TABLE glparms in share MODE 
		LOCK TABLE customer in share MODE 
		LOCK TABLE customerhist in share MODE 
		LOCK TABLE invoicehead in share MODE 
		LOCK TABLE invoicedetl in share MODE 
		LOCK TABLE credithead in share MODE 
		LOCK TABLE creditdetl in share MODE 
		LOCK TABLE cashreceipt in share MODE 
		LOCK TABLE exchangevar in share MODE 
		LOCK TABLE postinvhead in share MODE 
		LOCK TABLE postcashrcpt in share MODE 
		LOCK TABLE postcredhead in share MODE 
		LOCK TABLE postexchvar in share MODE 
	END IF 

	LET modu_err_message = " AR Parameter UPDATE " 

	UPDATE arparms 
		SET last_post_date = TODAY 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND parm_code = "1" 

	# Check that the journals are present
	LET modu_err_message = " Journal Verify " 
	SELECT * 
		INTO modu_rec_journal.* 
		FROM journal 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND jour_code = glob_rec_arparms.cash_jour_code 

	IF STATUS = NOTFOUND THEN 
		CALL fgl_winmessage("Configuration Error - Cash Journal NOT found","Cash Journal NOT found","ERROR") # 3507 "Status cannot be found - cannot post - ABORTING!"
		EXIT PROGRAM 
	END IF 

	SELECT * 
		INTO modu_rec_journal.* 
		FROM journal 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND jour_code = glob_rec_arparms.sales_jour_code 

	IF STATUS = NOTFOUND THEN 
		CALL fgl_winmessage("Configuration Error - Sales Journal NOT found","Sales Journal NOT found","ERROR") # 3507 "Status cannot be found - cannot post - ABORTING!"
		EXIT PROGRAM 
	END IF 

	CALL invoice() # do all the invoice history updates AND postings 
	CALL credit() # do all the credit history updates AND postings 
	CALL receipt() # do all the receipts history updates AND postings 
	IF glob_rec_arparms.gl_flag = "Y" THEN # post exchange variances only IF post TO GL required 
		CALL exch_var() # post exchange variances
	END IF 

	#------------------------------------------------------------
	FINISH REPORT COM_jourintf_rpt_list_bd
	CALL rpt_finish("COM_jourintf_rpt_list_bd")
	#------------------------------------------------------------

	IF modu_all_ok = 0 THEN 
		# 3527 " SUSPENSE ACCOUNTS USED, RETURN TO accept, DEL TO cancel"
		ERROR kandoomsg2("U",3527,"") 
	ELSE 
		# 3528 " Posting completed - RETURN TO accept, DEL TO cancel"
		MESSAGE kandoomsg2("U",3528,"") 
	END IF 

	UPDATE poststatus SET post_running_flag = "N" 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND module_code = "AR" 

	IF glob_one_trans THEN 
			# 8502 "Accept Posting (Y/N) "
		IF kandoomsg("U",8502,"") = "N" THEN 
			ROLLBACK WORK 
			LET glob_in_trans = false 
			UPDATE poststatus SET post_running_flag = "N" 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND module_code = "AR" 
		ELSE 
			COMMIT WORK 
			LET glob_in_trans = false 
		END IF 
	END IF 

	IF get_debug() THEN 
		DISPLAY "#### FUNCTION AS7_post_AR() END" 
	END IF 
	CALL fgl_winmessage("Completed","Posting completed\nApplication closing","info") 

	EXIT PROGRAM 

END FUNCTION 