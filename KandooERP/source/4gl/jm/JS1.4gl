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
GLOBALS "../jm/J_JM_GLOBALS.4gl" 
GLOBALS "../common/postfunc_GLOBALS.4gl" 
# Purpose : General Ledger Post Program

GLOBALS 
	DEFINE formname CHAR(15) 
	DEFINE pr_rec_kandoouser RECORD LIKE kandoouser.* 
	DEFINE pr_jmparms RECORD LIKE jmparms.* 
	DEFINE pr_job RECORD LIKE job.* 
	DEFINE pr_jobledger RECORD LIKE jobledger.* 
	DEFINE pr_output CHAR(60) 
	DEFINE pr_glparms RECORD LIKE glparms.* 
	DEFINE bal_rec RECORD 
		tran_type_ind LIKE batchdetl.tran_type_ind, 
		acct_code LIKE batchdetl.acct_code, 
		desc_text LIKE batchdetl.desc_text 
	END RECORD 
	DEFINE pr_post_acct_code LIKE batchdetl.acct_code 
	DEFINE pr_activity_title LIKE activity.title_text 
	DEFINE doit CHAR(1) 
	DEFINE i SMALLINT 
	DEFINE sel_stmt CHAR(900) 
	DEFINE pr_sl_id LIKE kandoouser.sign_on_code 
--	DEFINE glob_rec_rmsreps.report_date DATE 
--	DEFINE glob_rec_rmsreps.report_time CHAR(10) 
--	DEFINE glob_rec_rmsreps.report_width_num SMALLINT 
	DEFINE foundit SMALLINT
	DEFINE l_all_ok SMALLINT  
	DEFINE its_ok INTEGER 
	DEFINE file_name CHAR(30) 
	DEFINE per_post SMALLINT 
	DEFINE try_again CHAR(1) 
	DEFINE err_message CHAR(80) 
	DEFINE sel_text, where_part CHAR(200) 
	#DEFINE glob_st_code SMALLINT
	DEFINE fisc_per SMALLINT 
	DEFINE idx SMALLINT 
	DEFINE scrn SMALLINT 

	DEFINE pr_period RECORD LIKE period.* 
	DEFINE pa_period DYNAMIC ARRAY OF RECORD --array[400] OF RECORD 
		year_num LIKE period.year_num, 
		period_num LIKE period.period_num, 
		post_req CHAR(1) 
	END RECORD 

	DEFINE tmp_poststatus RECORD LIKE poststatus.* 
	#DEFINE glob_rec_poststatus RECORD LIKE poststatus.*
	DEFINE stat_code LIKE poststatus.status_code 
	#DEFINE glob_in_trans SMALLINT
	DEFINE posting_needed SMALLINT 
	DEFINE post_status LIKE poststatus.status_code 
	#DEFINE glob_posted_journal LIKE batchhead.jour_num
	#DEFINE glob_post_text CHAR(80)
	#DEFINE glob_err_text CHAR(80)
	DEFINE inserted_some SMALLINT 
	DEFINE mx_ref_text CHAR(40) 
	DEFINE mx_ref_code CHAR(3) 
	#DEFINE glob_one_trans SMALLINT
	#DEFINE glob_st_code SMALLINT
	DEFINE again SMALLINT 
	DEFINE select_text CHAR(1200) 
	DEFINE pr_salestax_acct_code LIKE apparms.salestax_acct_code 
	DEFINE set_retry SMALLINT 
	DEFINE donesome SMALLINT 

END GLOBALS 


###########################################################################
# MAIN
#
#
###########################################################################
MAIN 
	DEFINE l_run_cmd STRING
	
	#Initial UI Init
	CALL setModuleId("JS1") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 


	CALL startlog(get_settings_logPath_forFile("postlog.JM")) 

	SELECT * 
	INTO glob_rec_poststatus.* 
	FROM poststatus 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND module_code = "JM" 

	IF status THEN 		
		ERROR kandoomsg2("U",3507,"") # 3507 "Status cannot be found - cannot post - ABORTING!"
		SLEEP 2 
		LET l_run_cmd = "cat postlog.JM >> ", trim(get_settings_logFile()) 
		RUN l_run_cmd
		EXIT program 
	ELSE 
		LET post_status = glob_rec_poststatus.status_code 

		IF glob_rec_poststatus.post_running_flag = "Y" THEN 			
			ERROR kandoomsg2("U",3508,"") # 3508 "Post IS already running - Cannot run"
			SLEEP 2 
		LET l_run_cmd = "cat postlog.JM >> ", trim(get_settings_logFile()) 
		RUN l_run_cmd
			EXIT program 
		END IF 

		IF post_status < 99 THEN 
			# 3509 "   Error Has Occurred In Previous Post - ",
			#      " Automatic Rollback will be commenced"
			ERROR kandoomsg2("U",3509,"") 
			SLEEP 2 
			CALL disp_poststatus("JM") 
		END IF 

	END IF 


	LET l_all_ok = 1 

	SELECT * 
	INTO pr_jmparms.* 
	FROM jmparms 
	WHERE key_code = "1" 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF status = notfound THEN 
		
		ERROR kandoomsg2("J",9527,"") # 9527 " JM parameters NOT found, see menu JZP"
		LET l_run_cmd = "cat postlog.JM >> ",trim(get_settings_logFile()) 
		RUN l_run_cmd		
		CALL fgl_winmessage("JM parameters NOT found",kandoomsg("J",9527,""),"ERROR")
		EXIT program 
	END IF 

	SELECT * 
	INTO pr_glparms.* 
	FROM glparms 
	WHERE key_code = "1" 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF status = notfound THEN 		
		ERROR kandoomsg2("U",3511,"")# 3511 "General Ledger parameters NOT found, see menu GZP" 
		SLEEP 3 
		LET l_run_cmd = "cat postlog.JM >> ",trim(get_settings_logFile()) 
		RUN l_run_cmd				
		EXIT program 
	END IF 

	IF pr_jmparms.gl_detail_flag IS NULL THEN 
		LET pr_jmparms.gl_detail_flag = "N" 
	END IF 


	LET pr_sl_id = "JM" 

	CREATE temp TABLE posttemp 
	( 
	tran_type_ind CHAR(3), 
	ref_num INTEGER, 
	ref_text CHAR(8), 
	acct_code CHAR(18), 
	desc_text CHAR(40), 
	for_debit_amt money(14,2), 
	for_credit_amt money(14,2), 
	base_debit_amt money(14,2), 
	base_credit_amt money(14,2), 
	currency_code CHAR(3), 
	conv_qty FLOAT, 
	tran_date DATE, 
	stats_qty DECIMAL(15,3) 
	) with no LOG 


	CREATE temp TABLE posterrors 
	( 
	textline CHAR(80) 
	) with no LOG 
	OPEN WINDOW j150 with FORM "J150" -- alch kd-747 
	CALL winDecoration_j("J150") -- alch kd-747 
	UPDATE poststatus SET post_running_flag = "Y" 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND module_code = "JM" 
	WHILE (true) 
		IF get_info() THEN 
			CONTINUE WHILE 
		END IF 
	END WHILE 
	UPDATE poststatus SET post_running_flag = "N" 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND module_code = "JM" 
	CLOSE WINDOW j150 
	
END MAIN 
###########################################################################
# END MAIN
###########################################################################


###########################################################################
# FUNCTION get_info()
#
#
###########################################################################
FUNCTION get_info() 
	DEFINE tmp_period LIKE period.period_num 
	DEFINE tmp_year LIKE period.year_num 
	DEFINE tmp_text CHAR(10) 
	DEFINE l_run_cmd STRING 
	
	
	ERROR kandoomsg2("U",1503,"") 
	CLEAR FORM 
	CONSTRUCT BY NAME where_part ON # 1503 "Enter selection - ESC TO search" attribute (yellow)
		year_num, 
		period_num 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","JS1","const-year_num-7") -- alch kd-506 
		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 
	END CONSTRUCT 

	LET sel_text = 
		"SELECT unique year_num, period_num ", 
		"FROM period ", 
		"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
		"AND ",where_part clipped, 
		"ORDER BY year_num, period_num " 

	IF int_flag OR quit_flag THEN 
		UPDATE poststatus SET post_running_flag = "N" 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND module_code = "JM" 
		LET l_run_cmd = "cat postlog.JM >> ", trim(get_settings_logFile())
		RUN l_run_cmd		 
		EXIT program 
	END IF 

	PREPARE getper FROM sel_text 
	DECLARE c_per CURSOR FOR getper 

	LET idx = 0 
	FOREACH c_per INTO pr_period.year_num, pr_period.period_num 
		LET idx = idx + 1 
		LET pa_period[idx].year_num = pr_period.year_num 
		LET pa_period[idx].post_req = " " 
		LET pa_period[idx].period_num = pr_period.period_num 
		IF idx > 300 THEN 			
			ERROR kandoomsg2("U",1505,"300") # 1505 " Only first 300 selected "
			SLEEP 4 
			EXIT FOREACH 
		END IF 
	END FOREACH 
	IF idx = 0 THEN 
		
		ERROR kandoomsg2("U",3512,"") # 3512 "You must enter a VALID year AND period"
		RETURN false 
	END IF 

	CALL set_count (idx) 

	
	ERROR kandoomsg2("U",3526,"") # 3526 "Press RETURN on line TO post, F10 TO check "

	LET again = false 
	INPUT ARRAY pa_period WITHOUT DEFAULTS FROM sr_period.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","JS1","input_arr-pa_period-1") -- alch kd-506 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE ROW 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			IF arr_curr() > arr_count() THEN 
				
				ERROR kandoomsg2("U",3513,"") # 3513  "No more rows in the direction you are going"
			END IF 

		ON KEY (F10) 
			FOR i=1 TO arr_count() 

				LET pa_period[i].post_req = "N" 
				LET foundit = false 

				DECLARE postvo CURSOR FOR 
				SELECT unique period_num 
				INTO per_post 
				FROM jobledger 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND (posted_flag = "N" OR posted_flag IS null) 
				AND period_num = pa_period[i].period_num 
				AND year_num = pa_period[i].year_num 

				FOREACH postvo 
					LET pa_period[i].post_req = "Y" 
					LET foundit = 1 
					EXIT FOREACH 
				END FOREACH 

				IF NOT foundit THEN 
					DECLARE postvo1 CURSOR FOR 
					SELECT unique period_num 
					INTO per_post 
					FROM postjobledger 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND (posted_flag = "N" OR posted_flag IS null) 
					AND period_num = pa_period[i].period_num 
					AND year_num = pa_period[i].year_num 

					FOREACH postvo1 
						LET pa_period[i].post_req = "Y" 
						LET foundit = 1 
						EXIT FOREACH 
					END FOREACH 
				END IF 

				IF i <= 12 THEN 
					DISPLAY pa_period[i].* TO sr_period[i].* 

				END IF 

			END FOR 

		BEFORE FIELD period_num 
			LET fisc_per = pa_period[idx].period_num 
			LET glob_st_code = pa_period[idx].year_num 

			IF post_status < 99 THEN 
				SELECT post_year_num,post_period_num 
				INTO tmp_year,tmp_period 
				FROM poststatus 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND module_code = "JM" 
				IF tmp_year != glob_st_code OR 
				tmp_period != fisc_per THEN 
					LET tmp_text = tmp_year USING "####"," ", 
					tmp_period USING "###" 					
					ERROR kandoomsg2("U",3516,tmp_text) # 3516 "You must post ",tmp_year," ",tmp_period
					SLEEP 2 
					LET again = true 
					EXIT INPUT 
				END IF 
			END IF 

			CALL post_jm() 

			NEXT FIELD year_num 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET quit_flag = 0 
		LET int_flag = 0 
	END IF 
	IF again THEN 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 

END FUNCTION 
###########################################################################
# END FUNCTION get_info()
#
#
###########################################################################


###########################################################################
# FUNCTION resource(pr_tran_type_indp_rpt_idx,p_rpt_idx)
#
#
###########################################################################
FUNCTION resource(pr_tran_type_ind,p_rpt_idx)
	DEFINE pr_tran_type_ind LIKE batchdetl.tran_type_ind 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]

	GOTO bypass 
	LABEL recovery: 
	CALL update_poststatus(TRUE,STATUS,"JM") 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 

	LET mx_ref_text = "Posting Resources & Timesheets" 
	LET mx_ref_code = "025" 
	LET glob_err_text = kandooword(mx_ref_text, mx_ref_code) 

	IF glob_err_text IS NULL THEN 
		LET glob_err_text = "Posting Resources & Timesheets" 
	END IF 

	DELETE FROM posttemp WHERE 1=1 

	CASE pr_tran_type_ind 
		WHEN ("RE") 
			ERROR kandoomsg2("J",1513,"") # 1513 "Posting Resources" 
			LET bal_rec.desc_text = "JM Resource Balancing entry" 
		WHEN ("TS") 
			ERROR kandoomsg2("J",1514,"") # 1514 "Posting Time Sheets" 
			LET bal_rec.desc_text = "JM Time Sheet Balancing entry" 
		WHEN ("VO") 
			ERROR kandoomsg2("J",1515,"") # 1515 "Posting Vouchers   " 
			LET bal_rec.desc_text = "JM Voucher Balancing entry" 
		WHEN ("DB") # 1515 "Posting Debits   " 
			ERROR kandoomsg2("J",1515,"") 
			LET bal_rec.desc_text = "JM Debits Balancing entry" 
		WHEN ("PU")			
			ERROR kandoomsg2("J",1516,"") # 1516 "Posting Purchase Orders" 
			LET bal_rec.desc_text = "JM Purchases Balancing entry" 
		WHEN ("IS")			
			ERROR kandoomsg2("J",1517,"") # 1517 "Posting Issues         " 
			LET bal_rec.desc_text = "JM Issues Balancing entry" 
	END CASE 

	# Post the jobledger across FOR resources "RE", Timesheets "TS" AND
	# Voucher "VO" Debits DB AND purchase ORDER receipts "PU" AND issues FROM
	# inventory "IS".


	# First credit the resource expense account


	DECLARE rs_curs CURSOR FOR 
	SELECT 
		p.trans_type_ind, 
		p.trans_source_num, 
		p.trans_source_text, 
		jmresource.acct_code, 
		p.desc_text, 
		p.trans_amt, 
		activity.acct_code 
	INTO 
		pr_jobledger.trans_type_ind, 
		pr_jobledger.trans_source_num, 
		pr_jobledger.trans_source_text, 
		pr_post_acct_code, 
		pr_jobledger.desc_text, 
		pr_jobledger.trans_amt, 
		pr_job.acct_code 
	FROM postjobledger p, jmresource, activity 
	WHERE p.cmpy_code = glob_rec_kandoouser.cmpy_code 
	# All records FOR a transaction type are in one batch hence IF it
	# craps out in that batch we delete AND redo the whole batch
	#    AND    P.posted_flag    = "N"
	AND p.year_num = glob_st_code 
	AND p.period_num = fisc_per 
	AND p.trans_type_ind = pr_tran_type_ind 
	AND jmresource.cmpy_code = p.cmpy_code 
	AND jmresource.res_code = p.trans_source_text 
	AND activity.cmpy_code = p.cmpy_code 
	AND activity.job_code = p.job_code 
	AND activity.activity_code = p.activity_code 
	AND activity.var_code = p.var_code 

	FOREACH rs_curs 
		CALL build_mask(glob_rec_kandoouser.cmpy_code, 
		pr_post_acct_code, 
		pr_job.acct_code) 
		RETURNING pr_post_acct_code 

		INSERT INTO posttemp VALUES (
			pr_jobledger.trans_type_ind, 
			pr_jobledger.trans_source_num, 
			pr_jobledger.trans_source_text, 
			pr_post_acct_code, 
			pr_jobledger.desc_text, 
			0, 
			pr_jobledger.trans_amt, 
			0, 
			pr_jobledger.trans_amt, 
			pr_glparms.base_currency_code, 
			1.0, 
			today, 
			0) 
	END FOREACH 


	# Debit the individual activity wip account


	DECLARE ac_curs CURSOR FOR 
	SELECT 
		p.trans_type_ind, 
		p.trans_source_num, 
		p.trans_source_text, 
	
		activity.wip_acct_code, 
		p.desc_text, 
		p.trans_amt 
	INTO 
		pr_jobledger.trans_type_ind, 
		pr_jobledger.trans_source_num, 
		pr_jobledger.trans_source_text, 
		pr_post_acct_code, 
		pr_jobledger.desc_text, 
		pr_jobledger.trans_amt 
	FROM postjobledger p, activity 
	WHERE p.cmpy_code = glob_rec_kandoouser.cmpy_code 
	# All records FOR a transaction type are in one batch hence IF it
	# craps out in that batch we delete AND redo the whole batch
	#    AND    jobledger.posted_flag    = "N"
	AND p.year_num = glob_st_code 
	AND p.period_num = fisc_per 
	AND p.trans_type_ind = pr_tran_type_ind 
	AND activity.cmpy_code = p.cmpy_code 
	AND activity.job_code = p.job_code 
	AND activity.activity_code = p.activity_code 
	AND activity.var_code = p.var_code 

	LET donesome = false 
	FOREACH ac_curs 
		LET donesome = true 
		INSERT INTO posttemp VALUES (
			pr_jobledger.trans_type_ind, 
			pr_jobledger.trans_source_num, 
			pr_jobledger.trans_source_text, 
			pr_post_acct_code, 
			pr_jobledger.desc_text, 
			pr_jobledger.trans_amt, 
			0, 
			pr_jobledger.trans_amt, 
			0, 
			pr_glparms.base_currency_code, 
			1.0, 
			today, 
			0) 
	END FOREACH 

	IF donesome THEN 
		LET bal_rec.tran_type_ind = pr_tran_type_ind #(re,ts OR db,vo, pu, is) 
		LET bal_rec.acct_code = pr_glparms.susp_acct_code 
		LET sel_stmt = " SELECT * FROM posttemp " 

		LET its_ok = jourintf2(p_rpt_idx, #p_rpt_idx,
		sel_stmt, #p_sel_stmt
		bal_rec.*, #p_rec_bal		RECORD tran_type_ind LIKE batchdetl.tran_type_ind,	acct_code LIKE batchdetl.acct_code, desc_text LIKE batchdetl.desc_text
		fisc_per, #p_periods
		glob_st_code, # p_year_num  !!! ??? !!!! TODO -> can this be right ????
		pr_jmparms.jm_jour_code, #p_sent_jour_code
		"J", #p_source_ind
		pr_glparms.base_currency_code, #p_currency_code
		"JM") #p_mod_code

# FUNCTION jourintf2 (p_rpt_idx,
#										p_sel_stmt,
#                   p_rec_bal,
	#	DEFINE p_rec_bal 
	#		RECORD tran_type_ind LIKE batchdetl.tran_type_ind,	acct_code LIKE batchdetl.acct_code, desc_text LIKE batchdetl.desc_text 
	#		END RECORD 
#                   p_periods,
#                   p_year_num,
#                   p_sent_jour_code,
#                   p_source_ind,
#                   p_currency_code,
#                   p_mod_code)

		LET glob_posted_journal = its_ok 
		IF its_ok = 0 THEN {nothing posted} 
			ERROR kandoomsg2("U",3500,bal_rec.tran_type_ind) 
			# 3500 DISPLAY "No entries FOR type ",pr_tran_type_ind,
			#              "posted."
			SLEEP 1 
		END IF 
		IF its_ok < 0 THEN 
			LET l_all_ok = 0 
		END IF 
	END IF 


	DECLARE flag_curs CURSOR with HOLD FOR 
	SELECT * 
	FROM postjobledger 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND trans_type_ind = pr_tran_type_ind 

	FOREACH flag_curs INTO pr_jobledger.* 
		IF NOT glob_one_trans THEN 
			BEGIN WORK 
				LET glob_in_trans = false 
			END IF 
			DECLARE lock_ledger2 CURSOR FOR 
			SELECT * 
			FROM postjobledger 
			WHERE cmpy_code = pr_jobledger.cmpy_code 
			AND job_code = pr_jobledger.job_code 
			AND var_code = pr_jobledger.var_code 
			AND activity_code = pr_jobledger.activity_code 
			AND seq_num = pr_jobledger.seq_num 
			FOR UPDATE 

			# only one user TO post one company AT a time so no need
			# TO specifically check FOR lock in postjobledger
			OPEN lock_ledger2 
			FETCH lock_ledger2 


			LET mx_ref_text = "Update of posted flag (RES)" 
			LET mx_ref_code = "038" 
			LET glob_err_text = kandooword(mx_ref_text, mx_ref_code) 
			IF glob_err_text IS NULL THEN 
				LET glob_err_text = "Update of posted flag (RES)" 
			END IF 

			UPDATE postjobledger 
			SET 
				posted_flag = "Y", 
				jour_num = glob_posted_journal 
			WHERE CURRENT OF lock_ledger2 

			IF NOT glob_one_trans THEN 
			COMMIT WORK 
			LET glob_in_trans = false 
		END IF 
	END FOREACH 


	LET glob_posted_journal = NULL 

END FUNCTION 
###########################################################################
# END FUNCTION resource(pr_tran_type_ind,p_rpt_idx)
#
#
###########################################################################


###########################################################################
# FUNCTION adjustment(p_rpt_idx)
#
#
###########################################################################
FUNCTION adjustment(p_rpt_idx) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]

	GOTO bypass 
	LABEL recovery: 
	CALL update_poststatus(TRUE,STATUS,"JM") 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 

	LET err_message = "Posting JM Adjustments" 

	DELETE FROM posttemp WHERE 1=1 

	# now post the jobledger across FOR adjustments.
	# the jobledger has balancing pairs of transactions with opposite
	# signs, so we should be able TO post them all together.

	LET bal_rec.tran_type_ind = "JAD" 
	LET bal_rec.acct_code = pr_glparms.susp_acct_code 
	LET bal_rec.desc_text = "JM Adjustments Balancing Entry" 

	DISPLAY " Posting Adjustments " at 1,2 

	DECLARE adj_curs CURSOR FOR 
	SELECT p.trans_source_num, 
	p.trans_source_text, 

	activity.wip_acct_code, 
	activity.title_text, 
	p.trans_amt 
	INTO pr_jobledger.trans_source_num, 
	pr_jobledger.trans_source_text, 
	pr_post_acct_code, 
	pr_activity_title, 
	pr_jobledger.trans_amt 
	FROM postjobledger p, activity 
	WHERE p.cmpy_code = glob_rec_kandoouser.cmpy_code 


	AND p.year_num = glob_st_code 
	AND p.period_num = fisc_per 
	AND p.trans_type_ind = "AD" 
	AND activity.cmpy_code = p.cmpy_code 
	AND activity.job_code = p.job_code 
	AND activity.activity_code = p.activity_code 
	AND activity.var_code = p.var_code 

	LET donesome = false 
	FOREACH adj_curs 
		LET donesome = true 

		INSERT INTO posttemp VALUES ("JA", 
		pr_jobledger.trans_source_num, 
		pr_jobledger.trans_source_text, 
		pr_post_acct_code, 
		pr_activity_title, 
		pr_jobledger.trans_amt, 
		0, 
		pr_jobledger.trans_amt, 
		0, 
		pr_glparms.base_currency_code, 
		1.0, 
		today, 
		0) 
	END FOREACH 

	IF donesome THEN 
		LET sel_stmt = "SELECT * FROM posttemp" 
		LET its_ok = jourintf2(p_rpt_idx,
		sel_stmt, 
		bal_rec.*, 
		fisc_per, 
		glob_st_code, 
		pr_jmparms.adj_jour_code, 
		"J", 
		pr_glparms.base_currency_code, 
		"JM") 

		LET glob_posted_journal = its_ok 
		IF its_ok = 0 THEN {nothing posted} 
			ERROR kandoomsg2("U",3500,bal_rec.tran_type_ind) 
			# 3500 DISPLAY "No entries FOR type ",pr_tran_type_ind,
			#              "posted."
			SLEEP 1 
		END IF 
		IF its_ok < 0 THEN 
			LET l_all_ok = 0 
		END IF 
	END IF 


	DECLARE flag_curs1 CURSOR with HOLD FOR 
	SELECT * 
	FROM postjobledger 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND trans_type_ind = "AD" 

	FOREACH flag_curs1 INTO pr_jobledger.* 
		IF NOT glob_one_trans THEN 
			BEGIN WORK 
				LET glob_in_trans = true 
			END IF 
			DECLARE lock_ledger1 CURSOR FOR 
			SELECT * 
			FROM postjobledger 
			WHERE cmpy_code = pr_jobledger.cmpy_code 
			AND job_code = pr_jobledger.job_code 
			AND var_code = pr_jobledger.var_code 
			AND activity_code = pr_jobledger.activity_code 
			AND seq_num = pr_jobledger.seq_num 
			FOR UPDATE 

			# only one user TO post one company AT a time so no need
			# TO specifically check FOR lock in postjobledger
			OPEN lock_ledger1 
			FETCH lock_ledger1 


			LET mx_ref_text = "Update of posted flag (ADJ)" 
			LET mx_ref_code = "039" 
			LET glob_err_text = kandooword(mx_ref_text, mx_ref_code) 
			IF glob_err_text IS NULL THEN 
				LET glob_err_text = "Update of posted flag (ADJ)" 
			END IF 
			UPDATE postjobledger SET posted_flag = "Y", 
			jour_num = glob_posted_journal 
			WHERE CURRENT OF lock_ledger1 

			IF NOT glob_one_trans THEN 
			COMMIT WORK 
			LET glob_in_trans = false 
		END IF 
	END FOREACH 


	LET glob_posted_journal = NULL 

END FUNCTION 
###########################################################################
# END FUNCTION adjustment(p_rpt_idx)
###########################################################################


###########################################################################
# FUNCTION cost_xfers(p_rpt_idx)
#
# Cost Transfers
###########################################################################
FUNCTION cost_xfers(p_rpt_idx) 
	DEFINE p_rpt_idx SMALLINT
	 
	GOTO bypass 
	LABEL recovery: 
	CALL update_poststatus(TRUE,STATUS,"JM") 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 

	LET glob_err_text = "Posting Cost Transfers" 

	DELETE FROM posttemp WHERE 1=1 

	
	ERROR kandoomsg2("J",1543,"") # 1543 "Posting Cost Transfers "
	LET bal_rec.desc_text = "JM Transfer Balancing entry" 


	# First debit the Activity COS account


	DECLARE ctdb_curs CURSOR FOR 
	SELECT p.trans_type_ind, 
	p.trans_source_num, 
	#########P.trans_source_text,
	p.job_code, 
	activity.cos_acct_code, 
	p.desc_text, 
	(P.trans_amt * -1) 
	INTO pr_jobledger.trans_type_ind, 
	pr_jobledger.trans_source_num, 
	########pr_jobledger.trans_source_text,
	pr_jobledger.job_code, 
	pr_post_acct_code, 
	pr_jobledger.desc_text, 
	pr_jobledger.trans_amt 
	FROM postjobledger p, activity 
	WHERE p.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND p.year_num = glob_st_code 
	AND p.period_num = fisc_per 
	AND p.trans_type_ind = "CT" 
	AND activity.cmpy_code = p.cmpy_code 
	AND activity.job_code = p.job_code 
	AND activity.activity_code = p.activity_code 
	AND activity.var_code = p.var_code 

	FOREACH ctdb_curs 

		INSERT INTO posttemp VALUES (pr_jobledger.trans_type_ind, 
		pr_jobledger.trans_source_num, 
		##                     pr_jobledger.trans_source_text,
		pr_jobledger.job_code, 
		pr_post_acct_code, 
		pr_jobledger.desc_text, 
		pr_jobledger.trans_amt, 
		0, 
		pr_jobledger.trans_amt, 
		0, 
		pr_glparms.base_currency_code, 
		1.0, 
		today, 
		0) 
	END FOREACH 


	# Credit the individual activity wip account


	DECLARE ctcr1_curs CURSOR FOR 
	SELECT p.trans_type_ind, 
	p.trans_source_num, 
	########P.trans_source_text,
	p.job_code, 
	activity.wip_acct_code, 
	p.desc_text, 
	(P.trans_amt * -1) 
	INTO pr_jobledger.trans_type_ind, 
	pr_jobledger.trans_source_num, 
	######pr_jobledger.trans_source_text,
	pr_jobledger.job_code, 
	pr_post_acct_code, 
	pr_jobledger.desc_text, 
	pr_jobledger.trans_amt 
	FROM postjobledger p, activity 
	WHERE p.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND p.year_num = glob_st_code 
	AND p.period_num = fisc_per 
	AND p.trans_type_ind = "CT" 
	AND activity.cmpy_code = p.cmpy_code 
	AND activity.job_code = p.job_code 
	AND activity.activity_code = p.activity_code 
	AND activity.var_code = p.var_code 

	LET donesome = false 
	FOREACH ctcr1_curs 
		LET donesome = true 
		INSERT INTO posttemp VALUES (pr_jobledger.trans_type_ind, 
		pr_jobledger.trans_source_num, 
		##     pr_jobledger.trans_source_text,
		pr_jobledger.job_code, 
		pr_post_acct_code, 
		pr_jobledger.desc_text, 
		0, 
		pr_jobledger.trans_amt, 
		0, 
		pr_jobledger.trans_amt, 
		pr_glparms.base_currency_code, 
		1.0, 
		today, 
		0) 
	END FOREACH 

	IF donesome THEN 
		LET bal_rec.tran_type_ind = "CT" 
		LET bal_rec.acct_code = pr_glparms.susp_acct_code 
		LET bal_rec.desc_text = "JM Cost Transfer Intermediate Balance" 
		LET sel_stmt = " SELECT * FROM posttemp " 

		LET its_ok = jourintf2(p_rpt_idx,
		sel_stmt, 
		bal_rec.*, 
		fisc_per, 
		glob_st_code, 
		pr_jmparms.jm_jour_code, 
		"J", 
		pr_glparms.base_currency_code, 
		"JM") 

		LET glob_posted_journal = its_ok 
		IF its_ok = 0 THEN {nothing posted} 
			ERROR kandoomsg2("U",3500,bal_rec.tran_type_ind) 		# 3500 DISPLAY "No entries FOR type ",pr_tran_type_ind,   "posted."
			SLEEP 1 
		END IF 
		IF its_ok < 0 THEN 
			LET l_all_ok = 0 
		END IF 
	END IF 


	DECLARE fct_curs CURSOR with HOLD FOR 
	SELECT * 
	FROM postjobledger 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND trans_type_ind = "CT" 

	FOREACH fct_curs INTO pr_jobledger.* 
		IF NOT glob_one_trans THEN 
			BEGIN WORK 
				LET glob_in_trans = false 
			END IF 
			DECLARE lock_ledger3 CURSOR FOR 
			SELECT * 
			FROM postjobledger 
			WHERE cmpy_code = pr_jobledger.cmpy_code 
			AND job_code = pr_jobledger.job_code 
			AND var_code = pr_jobledger.var_code 
			AND activity_code = pr_jobledger.activity_code 
			AND seq_num = pr_jobledger.seq_num 
			FOR UPDATE 

			# only one user TO post one company AT a time so no need
			# TO specifically check FOR lock in postjobledger
			OPEN lock_ledger3 
			FETCH lock_ledger3 

			LET glob_err_text = "UPDATE of posted flag (CT)" 

			UPDATE postjobledger SET posted_flag = "Y", 
			jour_num = glob_posted_journal 
			WHERE CURRENT OF lock_ledger3 

			IF NOT glob_one_trans THEN 
			COMMIT WORK 
			LET glob_in_trans = false 
		END IF 
	END FOREACH 

	LET glob_posted_journal = NULL 

END FUNCTION 
###########################################################################
# END FUNCTION cost_xfers(p_rpt_idx)
###########################################################################


###########################################################################
# FUNCTION post_jm()
#
# 
###########################################################################
FUNCTION post_jm() 
	DEFINE l_run_cmd STRING
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]

	GOTO bypass 
	LABEL recovery: 
	CALL update_poststatus(TRUE,STATUS,"JM") 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 

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
	--LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("COM_jourintf_rpt_list_bd")].sel_text
	#------------------------------------------------------------
	LET file_name = "rpt", glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_time
	#------------------------------------------------------------

	# IF this IS a properly configured online site (ie correct # locks
	# THEN they may wish TO run one big transaction. In which CASE
	# poststatus.online_ind = "Y". Just TO be flexible you may also
	# run the program in the 'old' lock table mode. This will still use
	# the post tables but will allow single glob_rec_kandoouser.cmpy_code sites TO ensure
	# absolute integrity of data.

	LET glob_one_trans = false 
	IF glob_rec_poststatus.online_ind = "Y" OR glob_rec_poststatus.online_ind = "L" THEN 
		BEGIN WORK 
			LET glob_one_trans = true 
			LET glob_in_trans = true 
		END IF 

		# lock tables IF program IS TO run in Lock mode
		IF glob_rec_poststatus.online_ind = "L" THEN 
			LOCK TABLE jmparms in share MODE 
			LOCK TABLE jobledger in share MODE 
			LOCK TABLE postjobledger in share MODE 
		END IF 

		LET err_message = " JM Parameter UPDATE " 

		UPDATE jmparms SET last_post_date = today 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND key_code = "1" 
		#    OPEN WINDOW show_post AT 10,10 with 5 rows, 50 columns
		#                          ATTRIBUTE(border,prompt line last)      -- alch KD-747

		LET mx_ref_text = "Commenced jobledger post" 
		LET mx_ref_code = "026" 
		LET glob_err_text = kandooword(mx_ref_text, mx_ref_code) 

		IF glob_err_text IS NULL THEN 
			LET glob_err_text = "Commenced jobledger post" 
		END IF 

		IF post_status = 1 THEN {error in jobledger post TO postjobledger}			
			ERROR kandoomsg2("J",9534,"") # 9534 "Rolling back jobledger AND postjobledger"
			SLEEP 2 

			LET mx_ref_text = "Reversing previous jobledger" 
			LET mx_ref_code = "027" 
			LET glob_err_text = kandooword(mx_ref_text, mx_ref_code) 
			IF glob_err_text IS NULL THEN 
				LET glob_err_text = "Reversing previous jobledger" 
			END IF 

			IF NOT glob_one_trans THEN 
				BEGIN WORK 
					LET glob_in_trans = true 
				END IF 

				IF glob_rec_poststatus.online_ind != "L" THEN 
					LOCK TABLE postjobledger in share MODE 
					LOCK TABLE jobledger in share MODE 
				END IF 

				DECLARE jobledger_undo CURSOR FOR 
				SELECT * 
				FROM postjobledger 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				FOR UPDATE 

				FOREACH jobledger_undo INTO pr_jobledger.* 


					UPDATE jobledger 
					SET posted_flag = "N" 
					WHERE cmpy_code = pr_jobledger.cmpy_code 
					AND job_code = pr_jobledger.job_code 
					AND var_code = pr_jobledger.var_code 
					AND activity_code = pr_jobledger.activity_code 
					AND trans_date = pr_jobledger.trans_date 
					AND year_num = pr_jobledger.year_num 
					AND period_num = pr_jobledger.period_num 
					AND seq_num = pr_jobledger.seq_num 
					AND trans_type_ind = pr_jobledger.trans_type_ind 
					AND trans_source_num = pr_jobledger.trans_source_num 

					DELETE FROM postjobledger WHERE CURRENT OF jobledger_undo 

				END FOREACH 
				IF NOT glob_one_trans THEN 
				COMMIT WORK 
				LET glob_in_trans = false 
			END IF 
		END IF 

		LET glob_st_code = 1 

		LET mx_ref_text = "Commenced INSERT INTO postjobledger" 
		LET mx_ref_code = "028" 
		LET glob_post_text = kandooword(mx_ref_text, mx_ref_code) 
		IF glob_post_text IS NULL THEN 
			LET glob_post_text = "Commenced INSERT INTO postjobledger" 
		END IF 
		
		CALL update_poststatus(FALSE,0,"JM") 

		IF post_status = 1 OR post_status = 99 THEN 

			LET mx_ref_text = "Jobledger SELECT FOR INSERT" 
			LET mx_ref_code = "029" 
			LET glob_err_text = kandooword(mx_ref_text, mx_ref_code) 
			IF glob_err_text IS NULL THEN 
				LET glob_err_text = "Jobledger SELECT FOR INSERT" 
			END IF 

			DECLARE jobledger_curs CURSOR with HOLD FOR 
			SELECT * 
			FROM jobledger 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND posted_flag = "N" 
			AND year_num = glob_st_code 
			AND period_num = fisc_per 

			FOREACH jobledger_curs INTO pr_jobledger.* 
				LET set_retry = retry_lock(glob_rec_kandoouser.cmpy_code,0) 
				WHILE (true) 
					IF NOT glob_one_trans THEN 
						BEGIN WORK 
							LET glob_in_trans = true 
						END IF 
						WHENEVER ERROR CONTINUE 

						DECLARE insert_curs CURSOR FOR 
						SELECT * 
						FROM jobledger 
						WHERE cmpy_code = pr_jobledger.cmpy_code 
						AND job_code = pr_jobledger.job_code 
						AND var_code = pr_jobledger.var_code 
						AND activity_code = pr_jobledger.activity_code 
						AND seq_num = pr_jobledger.seq_num 
						FOR UPDATE 

						OPEN insert_curs 
						FETCH insert_curs INTO pr_jobledger.* 
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
								LET try_again = error_recover("Jobledger INSERT", stat_code) 
								IF try_again != "Y" THEN 
									LET glob_in_trans = false 
									CALL update_poststatus(TRUE,stat_code,"JM") 
								ELSE 
									ROLLBACK WORK 
									CONTINUE WHILE 
								END IF 
							ELSE 

								CALL update_poststatus(TRUE,stat_code,"JM") 

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

			LET mx_ref_text = "JS1 - Insert INTO Postjobledger" 
			LET mx_ref_code = "030" 
			LET glob_err_text = kandooword(mx_ref_text, mx_ref_code) 
			IF glob_err_text IS NULL THEN 
				LET glob_err_text = "JS1 - Insert INTO Postjobledger" 
			END IF 
			
			INSERT INTO postjobledger VALUES (pr_jobledger.*)

			LET mx_ref_text = "JS1 - Jobledger post flag SET" 
			LET mx_ref_code = "031" 
			LET glob_err_text = kandooword(mx_ref_text, mx_ref_code) 
			IF glob_err_text IS NULL THEN 
				LET glob_err_text = "JS1 - Jobledger post flag SET" 
			END IF 
			UPDATE jobledger SET posted_flag = "Y" 
			WHERE CURRENT OF insert_curs 

			IF NOT glob_one_trans THEN 
				COMMIT WORK 
				LET glob_in_trans = false 
			END IF 
		END FOREACH 
	END IF 
	
	LET glob_st_code = 2 
	
	LET mx_ref_text = "Completed INSERT INTO postjobledger" 
	LET mx_ref_code = "042" 
	LET glob_post_text = kandooword(mx_ref_text, mx_ref_code) 

	IF glob_post_text IS NULL THEN 
		LET glob_post_text = "Completed INSERT INTO postjobledger" 
	END IF 

	CALL update_poststatus(FALSE,0,"JM") 
	
	
# do all the resource postings
	
	
	IF post_status <= 2 OR post_status = 99 THEN 
	
		IF post_status = 2 
		AND glob_rec_poststatus.jour_num != 0 THEN 
			LET glob_posted_journal = glob_rec_poststatus.jour_num 
		ELSE 
			LET glob_posted_journal = NULL 
		END IF 
	
		CALL resource("RE",l_rpt_idx) 
	END IF 
	
	LET glob_st_code = 3 
	
	LET mx_ref_text = "Completed RE post" 
	LET mx_ref_code = "032" 
	LET glob_post_text = kandooword(mx_ref_text, mx_ref_code) 
	
	IF glob_post_text IS NULL THEN 
		LET glob_post_text = "Completed RE post" 
	END IF 
	
	CALL update_poststatus(FALSE,0,"JM") 
	
	
	
# do all the timesheet postings
	
	
	IF post_status <= 3 OR post_status = 99 THEN 
	
		IF post_status = 3 
		AND glob_rec_poststatus.jour_num != 0 THEN 
			LET glob_posted_journal = glob_rec_poststatus.jour_num 
		ELSE 
			LET glob_posted_journal = NULL 
		END IF 
	
		CALL resource("TS",l_rpt_idx) 
	END IF 
	
	LET glob_st_code = 4 
	
	LET mx_ref_text = "Completed TS post" 
	LET mx_ref_code = "033" 
	LET glob_post_text = kandooword(mx_ref_text, mx_ref_code) 
	
	IF glob_post_text IS NULL THEN 
		LET glob_post_text = "Completed TS post" 
	END IF 
	
	CALL update_poststatus(FALSE,0,"JM") 
	
	
	
	
# do all the adjustment postings
	
	
	IF post_status <= 4 OR post_status = 99 THEN 
	
		IF post_status = 4 
		AND glob_rec_poststatus.jour_num != 0 THEN 
			LET glob_posted_journal = glob_rec_poststatus.jour_num 
		ELSE 
			LET glob_posted_journal = NULL 
		END IF 
	
		CALL adjustment(l_rpt_idx) 
	END IF 
	
	LET glob_st_code = 5 
	
	LET mx_ref_text = "Completed adjustment post" 
	LET mx_ref_code = "034" 
	LET glob_post_text = kandooword(mx_ref_text, mx_ref_code) 
	
	IF glob_post_text IS NULL THEN 
		LET glob_post_text = "Completed adjustment post" 
	END IF 
	
	CALL update_poststatus(FALSE,0,"JM") 
	
	
	
# do all the vouchers postings
	
	
	IF post_status <= 5 OR post_status = 99 THEN 
	
		IF post_status = 5 
		AND glob_rec_poststatus.jour_num != 0 THEN 
			LET glob_posted_journal = glob_rec_poststatus.jour_num 
		ELSE 
			LET glob_posted_journal = NULL 
		END IF 
	
		CALL resource("VO",l_rpt_idx) 
	END IF 
	
	LET glob_st_code = 6 
	
	LET mx_ref_text = "Completed VO post" 
	LET mx_ref_code = "035" 
	LET glob_post_text = kandooword(mx_ref_text, mx_ref_code) 
	
	IF glob_post_text IS NULL THEN 
		LET glob_post_text = "Completed VO post" 
	END IF 
	
	CALL update_poststatus(FALSE,0,"JM") 
	
	
	
# do all the debits postings
	
	
	IF post_status <= 6 OR post_status = 99 THEN 
		IF post_status = 6 THEN 
			LET glob_posted_journal = glob_rec_poststatus.jour_num 
		ELSE 
			LET glob_posted_journal = NULL 
		END IF 
	
		CALL resource("DB",l_rpt_idx) 
	
		LET glob_st_code = 7 
	
		LET mx_ref_text = "Completed DB Post" 
		LET mx_ref_code = "054" 
		LET glob_post_text = kandooword(mx_ref_text, mx_ref_code) 
		IF glob_post_text IS NULL THEN 
			LET glob_post_text = "Completed DB post" 
		END IF 
		CALL update_poststatus(FALSE,0,"JM") 
	
	END IF 
	
# do all the purchase orders
	
	
	IF post_status <= 7 OR post_status = 99 THEN 
	
		IF post_status = 7 
		AND glob_rec_poststatus.jour_num != 0 THEN 
			LET glob_posted_journal = glob_rec_poststatus.jour_num 
		ELSE 
			LET glob_posted_journal = NULL 
		END IF 
	
		CALL resource("PU",l_rpt_idx) 
	END IF 
	
	LET glob_st_code = 8 
	
	LET mx_ref_text = "Completed PU post" 
	LET mx_ref_code = "036" 
	LET glob_post_text = kandooword(mx_ref_text, mx_ref_code) 
	
	IF glob_post_text IS NULL THEN 
		LET glob_post_text = "Completed PU post" 
	END IF 
	
	CALL update_poststatus(FALSE,0,"JM") 
	
	
	
	
# do all the product issues
	
	
	IF post_status <= 8 OR post_status = 99 THEN 
	
		IF post_status = 8 
		AND glob_rec_poststatus.jour_num != 0 THEN 
			LET glob_posted_journal = glob_rec_poststatus.jour_num 
		ELSE 
			LET glob_posted_journal = NULL 
		END IF 
	
		CALL resource("IS",l_rpt_idx) 
	END IF 
	
	LET glob_st_code = 9 
	
	LET mx_ref_text = "Completed IS post" 
	LET mx_ref_code = "037" 
	LET glob_post_text = kandooword(mx_ref_text, mx_ref_code) 
	
	IF glob_post_text IS NULL THEN 
		LET glob_post_text = "Completed IS post" 
	END IF 
	
	CALL update_poststatus(FALSE,0,"JM") 
	
	
# Cost Transfer processing
	
# do all the cost transfers
	
	
	IF post_status <= 9 OR post_status = 99 THEN 
	
		IF post_status = 9 
		AND glob_rec_poststatus.jour_num != 0 THEN 
			LET glob_posted_journal = glob_rec_poststatus.jour_num 
		ELSE 
			LET glob_posted_journal = NULL 
		END IF 
	
		CALL cost_xfers(l_rpt_idx) 
	
	
	
		LET glob_post_text = "Completed CT post" 
	
		CALL update_poststatus(FALSE,0,"JM") 
	END IF 
	
	
	
	
#  postjobledger now flagged as processed
	
	LET glob_st_code = 10 
	LET mx_ref_text = "Commenced UPDATE jour_num FROM postjobledger" 
	CALL update_poststatus(FALSE,0,"JM") 
	
	IF post_status <= 10 OR post_status = 99 THEN 
		LET glob_err_text = "Update jour_num in jobledger" 
		DECLARE update_jour CURSOR with HOLD FOR 
		SELECT * 
		FROM postjobledger 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	
		FOREACH update_jour INTO pr_jobledger.* 
			IF NOT glob_one_trans THEN 
				BEGIN WORK 
					LET glob_in_trans = true 
				END IF 
				UPDATE jobledger SET jour_num = pr_jobledger.jour_num, 
				post_date = today 
				WHERE cmpy_code = pr_jobledger.cmpy_code 
				AND job_code = pr_jobledger.job_code 
				AND var_code = pr_jobledger.var_code 
				AND activity_code = pr_jobledger.activity_code 
				AND seq_num = pr_jobledger.seq_num 
				IF NOT glob_one_trans THEN 
				COMMIT WORK 
				LET glob_in_trans = false 
			END IF 
		END FOREACH 
	END IF 
	
	LET glob_st_code = 11 
	
	LET mx_ref_text = "Commenced DELETE FROM postjobledger" 
	LET mx_ref_code = "040" 
	LET glob_post_text = kandooword(mx_ref_text, mx_ref_code) 
	IF glob_post_text IS NULL THEN 
		LET glob_post_text = "Commenced DELETE FROM postjobledger" 
	END IF 
	CALL update_poststatus(FALSE,0,"JM") 
	
	
	IF post_status <= 11 OR post_status = 99 THEN 
		IF NOT glob_one_trans THEN 
			BEGIN WORK 
				LET glob_in_trans = true 
			END IF 
			IF glob_rec_poststatus.online_ind != "L" THEN 
				LOCK TABLE postjobledger in share MODE 
			END IF 
			DELETE FROM postjobledger WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF NOT glob_one_trans THEN 
			COMMIT WORK 
			LET glob_in_trans = false 
		END IF 
	END IF 
	
	LET glob_st_code = 99 
	
	LET mx_ref_text = "Job Management post" 
	LET mx_ref_code = "041" 
	LET glob_post_text = kandooword(mx_ref_text, mx_ref_code) 
	IF glob_post_text IS NULL THEN 
		LET glob_post_text = "Job Management post completed correctly" 
	END IF 
	
	CALL update_poststatus(FALSE,0,"JM") 
	
	WHENEVER ERROR stop 

	#------------------------------------------------------------
	FINISH REPORT COM_jourintf_rpt_list_bd
	CALL rpt_finish("COM_jourintf_rpt_list_bd")
	#------------------------------------------------------------
	 
	 	
	IF l_all_ok = 0 THEN 		
		ERROR kandoomsg2("U",3527,"") # 3527 " SUSPENSE ACCOUNTS USED, RETURN TO accept, DEL TO cancel"
	ELSE 		
		ERROR kandoomsg2("U",3528,"") # 3528 " Posting completed - RETURN TO accept, DEL TO cancel"
	END IF 

	UPDATE poststatus SET post_running_flag = "N" 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND module_code = "JM" 
	
	IF glob_one_trans THEN 		
		ERROR kandoomsg2("U",8502,"") # 8502 "Accept Posting (Y/N) "
		IF msgresp = "N" THEN 
			ROLLBACK WORK 
			LET glob_in_trans = false 
			UPDATE poststatus SET post_running_flag = "N" 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND module_code = "JM" 
		ELSE 
		COMMIT WORK 
		LET glob_in_trans = false 
	END IF 
END IF 
	#    CLOSE WINDOW show_post      -- alch KD-747

	LET l_run_cmd = "cat postlog.JM >> ",trim(get_settings_logFile()) 
	RUN l_run_cmd

	EXIT program 

END FUNCTION

###########################################################################
# END FUNCTION post_jm()
###########################################################################