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
GLOBALS "../fa/F_FA_GLOBALS.4gl" 
GLOBALS "../common/postfunc_GLOBALS.4gl" 
# Purpose    :    Prepares batches FOR GL Integration - via jourintf

GLOBALS 
	DEFINE ans CHAR 
	DEFINE try_again CHAR(1) 
	DEFINE err_message CHAR(80) 
	DEFINE tester SMALLINT 
	DEFINE pr_glparms RECORD LIKE glparms.* 
	DEFINE pr_temp RECORD 
		tran_type_ind CHAR(3), 
		ref_num INTEGER, 
		ref_text CHAR(10), 
		acct_code CHAR(18), 
		desc_text CHAR(30), 
		for_debit_amt money(12,2), 
		for_credit_amt money(12,2), 
		base_debit_amt money(12,2), 
		base_credit_amt money(12,2), 
		currency_code CHAR(3), 
		conv_qty FLOAT, 
		tran_date DATE, 
		stats_qty DECIMAL(15,3) 
	END RECORD 
	DEFINE bal_rec RECORD 
		tran_type_ind CHAR(3), 
		acct_code CHAR(18), 
		desc_text CHAR(30) 
	END RECORD 
	DEFINE pr_fabatch RECORD LIKE fabatch.* 
	DEFINE pr_famast RECORD LIKE famast.* 
	DEFINE pr_fastatus RECORD LIKE fastatus.* 
	DEFINE pr_fabook RECORD LIKE fabook.* 
	DEFINE pr_rec_kandoouser RECORD LIKE kandoouser.* 
	DEFINE pr_faaudit RECORD LIKE faaudit.* 
	DEFINE pr_glasset RECORD LIKE glasset.* 
	DEFINE pr_output CHAR(60) 
	DEFINE pr_output1 CHAR(60) 
	DEFINE donesome SMALLINT 
	DEFINE sql_stmt CHAR(600) 
	DEFINE net_profit LIKE faaudit.asset_amt 
	DEFINE capr_profit LIKE faaudit.asset_amt 
	DEFINE loss_amt LIKE faaudit.asset_amt 
	DEFINE fa_jour_code LIKE faparms.asset_jnl_code 
	DEFINE start_batch LIKE faaudit.batch_num 
	DEFINE end_batch LIKE faaudit.batch_num 
	DEFINE err_msg CHAR(130) 
	DEFINE pr_company RECORD LIKE company.* 
	DEFINE pr_period RECORD LIKE period.* 
	DEFINE some_created SMALLINT 

	DEFINE tmp_poststatus RECORD LIKE poststatus.* 
	#DEFINE glob_rec_poststatus RECORD LIKE poststatus.*
	DEFINE stat_code LIKE poststatus.status_code 
	#glob_in_trans SMALLINT,
	DEFINE posting_needed SMALLINT 
	DEFINE post_status LIKE poststatus.status_code 
	#glob_posted_journal LIKE batchhead.jour_num,
	#glob_post_text,
	#glob_err_text CHAR(80),
	DEFINE inserted_some SMALLINT 

	#glob_one_trans SMALLINT,
	#glob_st_code SMALLINT,
	DEFINE again SMALLINT 
	DEFINE select_text CHAR(1200) 
	DEFINE pr_salestax_acct_code LIKE apparms.salestax_acct_code 
	DEFINE set_retry SMALLINT 
	#glob_fisc_year LIKE period.year_num,
	DEFINE fisc_per LIKE period.period_num 

END GLOBALS 

MAIN 
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]

	OPTIONS PROMPT line 2 

	#Initial UI Init
	CALL setModuleId("FGL") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	CALL startlog(get_settings_logPath_forFile("postlog.FA")) 


	SELECT * INTO glob_rec_poststatus.* FROM poststatus 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND module_code = "FA" 

	IF status THEN 
		LET msgresp = kandoomsg("U",3507,"") 
		# 3507 "Status cannot be found - cannot post - ABORTING!"
		SLEEP 5 
		EXIT program 
	ELSE 
		LET post_status = glob_rec_poststatus.status_code 
		IF glob_rec_poststatus.post_running_flag = "Y" THEN 
			LET msgresp = kandoomsg("U",3508,"") 
			# 3508 "Post IS already running - Cannot run"
			SLEEP 2 
			EXIT program 
		END IF 

		IF post_status < 99 THEN 
			LET msgresp = kandoomsg("U",3509,"") 
			# 3509 "   Error Has Occurred In Previous Post - ",
			#      " Automatic Rollback will be commenced"
			SLEEP 2 
			CALL disp_poststatus("FA") 
		END IF 
	END IF 



	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start("FGL-BDT","COM_jourintf_rpt_list_bd","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT COM_jourintf_rpt_list_bd TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	--LET where_part = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------



	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start("FGL-AUDIT","FGL_rpt_list_audit","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT FGL_rpt_list_audit TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	--LET where_part = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------



	SELECT asset_jnl_code 
	INTO fa_jour_code 
	FROM faparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF status THEN 
		LET msgresp = kandoomsg("F",9500,"") 
		CALL fgl_winmessage("Incomplete Setup","No asset journal code setup - use FZP\nAbborting Program","error") 
		# 9500 "No asset journal code setup - use FZP"
		SLEEP 2 
		EXIT program 
	END IF 
	SELECT jour_code 
	FROM journal 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND jour_code = fa_jour_code 
	IF status THEN 
		LET msgresp = kandoomsg("F",9501,"") 
		# 9501 "Invalid journal code in parms - see FZP"
		SLEEP 2 
		EXIT program 
	END IF 



	CREATE temp TABLE posttab 
	( 
	tran_type_ind CHAR(3), 
	ref_num INTEGER, 
	ref_text CHAR(10), 
	acct_code CHAR(18), 
	desc_text CHAR(30), 
	for_debit_amt money(12,2), 
	for_credit_amt money(12,2), 
	base_debit_amt money(12,2), 
	base_credit_amt money(12,2), 
	currency_code CHAR(3), 
	conv_qty FLOAT, 
	tran_date DATE, 
	stats_qty DECIMAL(15,3) 
	) 

	CREATE temp TABLE tempbatch 
	( 
	batch_num INTEGER 
	) 

	CREATE temp TABLE posterrors 
	( 
	textline CHAR(80) 
	) with no LOG 

	OPEN WINDOW f155 with FORM "F155" -- alch kd-757 
	CALL  windecoration_f("F155") -- alch kd-757 

	UPDATE poststatus SET post_running_flag = "Y" 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND module_code = "FA" 

	WHILE (true) 
		CALL get_info() 
		IF int_flag OR quit_flag THEN 
			EXIT WHILE 
		END IF 
	END WHILE 
	#------------------------------------------------------------
	FINISH REPORT FGL_rpt_list_audit
	CALL rpt_finish("FGL_rpt_list_audit")
	#------------------------------------------------------------
	#------------------------------------------------------------
	FINISH REPORT COM_jourintf_rpt_list_bd
	CALL rpt_finish("COM_jourintf_rpt_list_bd")
	#------------------------------------------------------------

	UPDATE poststatus SET post_running_flag = "N" 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND module_code = "FA" 
	CLOSE WINDOW F155 


	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
		
END MAIN 



FUNCTION get_info() 

	DEFINE 
	where_part,sel_text CHAR(1200), 
	pa_period array[300] OF RECORD 
		year_num LIKE period.year_num, 
		period_num LIKE period.period_num 
	END RECORD, 
	idx SMALLINT, 
	tmp_year LIKE period.year_num, 
	tmp_period LIKE period.period_num, 
	tmp_text CHAR(10) 

	LET msgresp = kandoomsg("U",1503,"") 
	# 1503 "Enter Selection Criteria;  OK TO Continue.

	CLEAR FORM 
	CONSTRUCT BY NAME where_part ON year_num, 
	period_num 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","FGL","const-year_num-1") -- alch kd-504 
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
	END CONSTRUCT 

	LET sel_text = "SELECT unique B.year_num,B.period_num ", 
	"FROM fabatch B ", 
	"WHERE B.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND B.post_asset_flag = \"Y\" ", 
	"AND B.post_gl_flag != \"Y\" ", 
	"AND ",where_part clipped," ", 
	"union ", 
	"SELECT unique P.year_num,P.period_num ", 
	"FROM postfabatch P ", 
	"WHERE P.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"ORDER BY 1,2 " 

	IF int_flag OR quit_flag THEN 
		UPDATE poststatus SET post_running_flag = "N" 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND module_code = "FA" 
		RETURN 
	END IF 

	PREPARE getper FROM sel_text 
	DECLARE c_per CURSOR FOR getper 

	LET idx = 0 
	FOREACH c_per INTO pr_period.year_num, pr_period.period_num 
		LET idx = idx + 1 
		LET pa_period[idx].year_num = pr_period.year_num 
		LET pa_period[idx].period_num = pr_period.period_num 
		IF idx > 300 THEN 
			LET msgresp = kandoomsg("U",1505,idx) 
			# 1505 Only first 300 rows selected.
			EXIT FOREACH 
		END IF 
	END FOREACH 

	CALL set_count (idx) 

	IF idx = 0 THEN 
		LET msgresp = kandoomsg("F",1500,"") 
		# 1500 No FA Batches ready TO be posted.
		LET msgresp = kandoomsg("F",9502,"") 
		# 9502 Press OK TO reselect;  CANCEL TO EXIT.
	ELSE 
		LET msgresp = kandoomsg("F",1501,"") 
		# 1501 Press RETURN on line TO post.
	END IF 

	INPUT ARRAY pa_period WITHOUT DEFAULTS FROM sr_period.* 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","FGL","inp_arr-pa_period-1") -- alch kd-504 
		BEFORE ROW 
			LET idx = arr_curr() 
		BEFORE FIELD period_num 
			CALL get_batch() 
			LET some_created = false 
			LET glob_fisc_year = pa_period[idx].year_num 
			LET fisc_per = pa_period[idx].period_num 
			IF post_status < 99 THEN 
				SELECT post_year_num,post_period_num 
				INTO tmp_year,tmp_period 
				FROM poststatus 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND module_code = "FA" 
				AND post_status != 99 
				IF tmp_year != glob_fisc_year OR 
				tmp_period != fisc_per THEN 
					LET tmp_text = tmp_year USING "####"," ",tmp_period USING "###" 
					# 3516 "You must post ",tmp_year," ",tmp_period
					LET msgresp = kandoomsg("U",3516,tmp_text) 
					SLEEP 2 
					EXIT INPUT 
				END IF 
			END IF 
			#OPEN WINDOW show_post AT 10,10 with 5 rows, 50 columns
			#ATTRIBUTE(border, prompt line 5)  -- alch KD-757
			CALL create_gl_batch(pa_period[idx].year_num, 
			pa_period[idx].period_num) 
			#CLOSE WINDOW show_post  -- alch KD-757
			NEXT FIELD year_num 
		ON KEY (control-w) 
			CALL kandoohelp("") 
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
	END INPUT 
END FUNCTION 

# Audit REPORT

REPORT FGL_rpt_list_audit(r_faaudit, r_status, mess) 

	DEFINE 
	r_faaudit RECORD LIKE faaudit.*, 
	r_status CHAR(35) , 
	r_cmpy CHAR(2), 
	r_compname CHAR(40), 
	mess CHAR(80) 

	OUTPUT 
	PAGE length 66 

	FORMAT 

		PAGE HEADER 

			SELECT name_text 
			INTO pr_company.name_text 
			FROM company 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 

			PRINT COLUMN 12, today USING "DD/MM/YY", 
			COLUMN 40, glob_rec_kandoouser.cmpy_code, " ", 
			pr_company.name_text, 
			COLUMN 80, "Page ", 
			pageno 

			PRINT COLUMN 40, "GL Batch prep - Audit Trail (Menu FP3)" 
			PRINT "----------------------------------------------------", 
			"----------------------------------------------------", 
			"----------------------" 

			PRINT COLUMN 1, "Batch", 
			COLUMN 11, "Line", 
			COLUMN 22, "Asset", 
			COLUMN 35, "Book", 
			COLUMN 40, "Year", 
			COLUMN 50, "Period", 
			COLUMN 63, "Trans", 
			COLUMN 73, "Asset", 
			COLUMN 89, "Depr" 

			PRINT COLUMN 1, "Batch", 
			COLUMN 11, "Num", 
			COLUMN 22, "Code", 
			COLUMN 35, "ID", 
			COLUMN 40, "Num", 
			COLUMN 50, "Num", 
			COLUMN 63, "Type", 
			COLUMN 73, "Amount", 
			COLUMN 89, "Amount", 
			COLUMN 98, "Status" 

			PRINT "----------------------------------------------------", 
			"----------------------------------------------------", 
			"----------------------" 

		ON EVERY ROW 
			IF r_status = "CREATED" THEN 
				LET r_status = NULL 
			END IF 

			IF r_faaudit.cmpy_code IS NOT NULL THEN 
				PRINT COLUMN 1, r_faaudit.batch_num USING "######", 
				COLUMN 11, r_faaudit.batch_line_num USING "####", 
				COLUMN 22, r_faaudit.asset_code, 
				COLUMN 35, r_faaudit.book_code, 
				COLUMN 40, r_faaudit.year_num USING "####", 
				COLUMN 50, r_faaudit.period_num USING "####", 
				COLUMN 64, r_faaudit.trans_ind, 
				COLUMN 68, r_faaudit.asset_amt USING "$$$,$$$,$$$.##", 
				COLUMN 83, r_faaudit.depr_amt USING "$$$,$$$,$$$.##", 
				COLUMN 98, r_status clipped 
			END IF 

			IF mess IS NOT NULL THEN 
				PRINT COLUMN 1, "***WARNING ",mess 
			END IF 

END REPORT 


FUNCTION create_posttemp(y_num,p_num) 
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE 
	ref_text LIKE batchdetl.ref_text, 
	y_num LIKE fabatch.year_num, 
	p_num LIKE fabatch.period_num, 
	no_line_err SMALLINT, 
	tmp_text1, 
	tmp_text2, 
	tmp_text3, 
	display_text1, 
	display_text2, 
	display_text3, 
	display_text4, 
	display_text5, 
	display_text6 CHAR(40) 

	GOTO bypass 
	LABEL recovery: 
	CALL update_poststatus(TRUE,STATUS,"FA") 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 

	# IF an error has occurred in previous post THEN
	# walk on by...
	IF post_status > 2 AND post_status < 99 THEN 
		RETURN true 
	END IF 

	LET glob_err_text = "Commenced fabatch post" 
	IF post_status = 1 THEN {error in fabatch post TO postfabatch} 
		# 9503 "Rolling back fabatch AND postfabatch"
		LET msgresp = kandoomsg("F",9503,"") 
		SLEEP 2 
		LET glob_err_text = kandooword("Reversing previous fabatch","001") 
		IF glob_err_text IS NULL THEN 
			LET glob_err_text = "Reversing previous fabatch" 
		END IF 

		IF NOT glob_one_trans THEN 
			BEGIN WORK 
				LET glob_in_trans = true 
			END IF 

			IF glob_rec_poststatus.online_ind != "L" THEN 
				LOCK TABLE postfabatch in share MODE 
				LOCK TABLE fabatch in share MODE 
			END IF 

			DECLARE fabatch_undo CURSOR FOR 
			SELECT * 
			FROM postfabatch 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			FOR UPDATE 

			FOREACH fabatch_undo INTO pr_fabatch.* 

				UPDATE fabatch SET post_gl_flag = "N" 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND batch_num = pr_fabatch.batch_num 

				DELETE FROM postfabatch WHERE CURRENT OF fabatch_undo 

			END FOREACH 
			IF NOT glob_one_trans THEN 
			COMMIT WORK 
			LET glob_in_trans = false 
		END IF 
	END IF 

	LET glob_st_code = 1 
	LET glob_post_text = kandooword("Commenced INSERT INTO postfabatch","022") 
	IF glob_post_text IS NULL THEN 
		LET glob_post_text = "Commenced INSERT INTO postfabatch" 
	END IF 
	CALL update_poststatus(FALSE,0,"FA") 

	IF post_status = 1 OR post_status = 99 THEN 
		LET glob_err_text = kandooword("Fabatch SELECT FOR INSERT","002") 
		IF glob_err_text IS NULL THEN 
			LET glob_err_text = "Fabatch SELECT FOR INSERT" 
		END IF 

		DECLARE fabatch_curs CURSOR with HOLD FOR 
		SELECT * 
		FROM fabatch 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND post_asset_flag = "Y" 
		AND post_gl_flag = "N" 
		AND batch_num between start_batch AND end_batch 
		AND year_num = y_num 
		AND period_num = p_num 

		LET glob_err_text = kandooword("Fabatch FOREACH FOR INSERT","004") 
		IF glob_err_text IS NULL THEN 
			LET glob_err_text = "Fabatch FOREACH FOR INSERT" 
		END IF 
		FOREACH fabatch_curs INTO pr_fabatch.* 
			LET set_retry = retry_lock(glob_rec_kandoouser.cmpy_code,0) 
			WHILE (true) 
				IF NOT glob_one_trans THEN 
					BEGIN WORK 
						LET glob_in_trans = true 
					END IF 

					WHENEVER ERROR CONTINUE 

					DECLARE insert_curs CURSOR FOR 
					SELECT * 
					FROM fabatch 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND batch_num = pr_fabatch.batch_num 
					FOR UPDATE 

					LET glob_err_text = kandooword("Fabatch lock FOR INSERT","023") 
					IF glob_err_text IS NULL THEN 
						LET glob_err_text = "Fabatch lock FOR INSERT" 
					END IF 
					OPEN insert_curs 
					FETCH insert_curs INTO pr_fabatch.* 
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
						# one_transaction users can't rollback !
						IF NOT glob_one_trans THEN 
							LET try_again = error_recover("Fabatch INSERT", 
							stat_code) 
							IF try_again != "Y" THEN 
								LET glob_in_trans = false 
								CALL update_poststatus(TRUE,stat_code,"FA") 
							ELSE 
								ROLLBACK WORK 
								CONTINUE WHILE 
							END IF 
						ELSE 
							CALL update_poststatus(TRUE,stat_code,"FA") 
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

		LET glob_err_text = kandooword("FGL - Insert INTO postfabatch","024") 
		IF glob_err_text IS NULL THEN 
			LET glob_err_text = "FGL - Insert INTO postfabatch" 
		END IF 
		INSERT INTO postfabatch VALUES (pr_fabatch.*) 

		LET glob_err_text = kandooword("FGL - fabatch post flag SET","005") 
		IF glob_err_text IS NULL THEN 
			LET glob_err_text = "FGL - fabatch post flag SET" 
		END IF 
		UPDATE fabatch SET post_gl_flag = "Y" 
		WHERE CURRENT OF insert_curs 

		IF NOT glob_one_trans THEN 
		COMMIT WORK 
		LET glob_in_trans = false 
	END IF 
END FOREACH 
END IF 

LET glob_st_code = 2 
LET glob_post_text = kandooword("Completed INSERT INTO postfabatch","006") 
IF glob_post_text IS NULL THEN 
LET glob_post_text = "Completed INSERT INTO postfabatch" 
END IF 
CALL update_poststatus(FALSE,0,"FA") 


IF post_status <= 2 OR post_status = 99 THEN 

DELETE FROM posttab WHERE 1=1 
DELETE FROM tempbatch WHERE 1=1 

IF post_status = 2 THEN 
	LET select_text = "SELECT * ", 
	"FROM postfabatch ", 
	"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND post_asset_flag = \"Y\" ", 
	"AND post_gl_flag = \"N\" ", 
	"AND batch_num between ",start_batch," ", 
	" AND ",end_batch," ", 
	"AND year_num = ",y_num," ", 
	"AND period_num = ",p_num," ", 
	"AND (jour_num = ",glob_rec_poststatus.jour_num," OR ", 
	" jour_num IS NULL OR ", 
	" jour_num = 0) " 
ELSE 
	LET select_text = "SELECT * ", 
	"FROM postfabatch ", 
	"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND post_asset_flag = \"Y\" ", 
	"AND post_gl_flag = \"N\" ", 
	"AND batch_num between ",start_batch," ", 
	" AND ",end_batch," ", 
	"AND year_num = ",y_num," ", 
	"AND period_num = ",p_num 
END IF 

PREPARE sel_stmt FROM select_text 
DECLARE c_batch CURSOR FOR sel_stmt 

OPEN c_batch 
FETCH c_batch INTO pr_fabatch.* 
IF status THEN 
	LET tmp_text1 = kandooword("No Fixed Asset batches","007") 
	IF tmp_text1 IS NULL THEN 
		LET tmp_text1 = "No Fixed Asset batches found TO PREPARE FOR GL." 
	END IF 
	LET tmp_text2 = kandooword("No Fixed Asset batches","008") 
	IF tmp_text2 IS NULL THEN 
		LET tmp_text2 = "Batches are : Not posted TO asset" 
	END IF 
	LET tmp_text3 = kandooword("No Fixed Asset batches","009") 
	IF tmp_text3 IS NULL THEN 
		LET tmp_text3 = "OR Don't exist OR Already posted - see (F28) " 
	END IF 
	LET err_msg = tmp_text1 clipped," ", 
	tmp_text2 clipped," ", 
	tmp_text3 clipped 
	
	#---------------------------------------------------------
	OUTPUT TO REPORT FGL_rpt_list_audit(l_rpt_idx,
	pr_faaudit.*,"PROBLEM",err_msg)
	#---------------------------------------------------------	
	 
	RETURN false 
END IF 

# get base currency FROM gl parameters - company record
SELECT curr_code 
INTO pr_temp.currency_code 
FROM company 
WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
IF status THEN 
	# 9503 "Cannot find base currency code ! - Aborting"
	LET msgresp = kandoomsg("U",9503,"") 
	SLEEP 2 
	UPDATE poststatus SET post_running_flag = "N" 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND module_code = "FA" 
	EXIT program 
END IF 

LET donesome = false 

FOREACH c_batch INTO pr_fabatch.* 

	DECLARE c_audit CURSOR FOR 
	SELECT * 
	FROM faaudit 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND batch_num = pr_fabatch.batch_num 

	LET no_line_err = true 

	FOREACH c_audit INTO pr_faaudit.* 

		LET ref_text = pr_fabatch.batch_num USING "<<<<",":", 
		pr_faaudit.batch_line_num USING "<<<<" 

		SELECT * 
		INTO pr_fabook.* 
		FROM fabook 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND book_code = pr_faaudit.book_code 
		IF status THEN 
			LET tmp_text1 = kandooword("Cannot find RECORD FOR book :","015") 
			IF tmp_text1 IS NULL THEN 
				LET tmp_text1 = "Cannot find RECORD FOR book :" 
			END IF 
			LET err_msg = tmp_text1 clipped,pr_faaudit.book_code

			#---------------------------------------------------------
			OUTPUT TO REPORT FGL_rpt_list_audit(l_rpt_idx,
			pr_faaudit.*,"PROBLEM",err_msg)
			#---------------------------------------------------------	
			 
			LET no_line_err = false 
			CONTINUE FOREACH 
		END IF 

		IF pr_fabook.gl_output_flag = "N" THEN 
			LET err_msg = "" 

			#---------------------------------------------------------
			OUTPUT TO REPORT FGL_rpt_list_audit(l_rpt_idx,
			pr_faaudit.*,"NO POST",err_msg)
			#---------------------------------------------------------				
			 
			CONTINUE FOREACH 
		END IF 

		SELECT * 
		INTO pr_famast.* 
		FROM famast 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND asset_code = pr_faaudit.asset_code 
		AND add_on_code = pr_faaudit.add_on_code 

		SELECT * 
		INTO pr_glasset.* 
		FROM glasset 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND book_code = pr_faaudit.book_code 
		AND facat_code = pr_faaudit.facat_code 
		AND location_code = pr_faaudit.location_code 

		IF status THEN 
			LET tmp_text1 = kandooword("GL accounts NOT SET up","016") 
			IF tmp_text1 IS NULL THEN 
				LET tmp_text1 = "GL accounts NOT SET up FOR Book : " 
			END IF 
			LET tmp_text2 = kandooword(" Cat :","017") 
			IF tmp_text2 IS NULL THEN 
				LET tmp_text2 = " Cat : " 
			END IF 
			LET tmp_text3 = kandooword(" Loc : ","018") 
			IF tmp_text3 IS NULL THEN 
				LET tmp_text3 = " Loc : " 
			END IF 
			LET err_msg = tmp_text1 clipped," ", 
			pr_faaudit.book_code,tmp_text2 clipped," ", 
			pr_famast.facat_code,tmp_text3 clipped," ", 
			pr_faaudit.location_code 
			
			#---------------------------------------------------------
			OUTPUT TO REPORT FGL_rpt_list_audit(l_rpt_idx,
			pr_faaudit.*,"PROBLEM",err_msg)
			#---------------------------------------------------------	
			 
			LET no_line_err = false 
			CONTINUE FOREACH 
		END IF 

		#SET ref_num TO batch number FOR deletion of failed batches
		LET pr_temp.ref_num = pr_fabatch.batch_num 
		LET pr_temp.ref_text = ref_text 
		LET pr_temp.tran_date = pr_faaudit.entry_date 

		LET pr_temp.conv_qty = 1 
		LET pr_temp.stats_qty = 0 

		SELECT * 
		INTO pr_famast.* 
		FROM famast 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND asset_code = pr_faaudit.asset_code 
		AND add_on_code = pr_faaudit.add_on_code 

		# net_book_val_amt IS held on the fastatus record
		# AND the corresponding history IS held on the
		# depreciation batch faaudit record.

		SELECT * 
		INTO pr_fastatus.* 
		FROM fastatus 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND asset_code = pr_famast.asset_code 
		AND add_on_code = pr_famast.add_on_code 
		AND book_code = pr_faaudit.book_code 

		CASE pr_faaudit.trans_ind 





			WHEN "A" {asset addition - purchase/setup} 

				# debit the original cost account
				# equals the asset amount keyed plus the depreciation
				# amount keyed. Note that this should also be equal TO
				# original cost amount AT batch entry time this orig cost
				# can subsequently be changed by an adjustment batch hence
				# the asset + depr amount used TO post.
				LET pr_temp.tran_type_ind = "AA" 
				LET pr_temp.acct_code = pr_glasset.orig_cost_code 
				LET pr_temp.base_debit_amt = (pr_faaudit.asset_amt + 
				pr_faaudit.depr_amt) 
				LET pr_temp.base_credit_amt = 0 
				LET pr_temp.for_debit_amt = pr_temp.base_debit_amt 
				LET pr_temp.for_credit_amt = pr_temp.base_credit_amt 
				LET pr_temp.desc_text = "Asset Addition" 

				INSERT INTO posttab VALUES (pr_temp.*) 
				LET donesome = true 

				# credit the capital purchases account
				# with the asset amount keyed in batch
				LET pr_temp.tran_type_ind = "AA" 
				LET pr_temp.acct_code = pr_glasset.cpip_acct_code 
				LET pr_temp.base_debit_amt = 0 
				LET pr_temp.base_credit_amt = pr_faaudit.asset_amt 
				LET pr_temp.for_debit_amt = pr_temp.base_debit_amt 
				LET pr_temp.for_credit_amt = pr_temp.base_credit_amt 
				LET pr_temp.desc_text = "Asset Addition" 

				INSERT INTO posttab VALUES (pr_temp.*) 
				LET donesome = true 

				# credit the accumulated depreciation  account
				# FOR assets that are partially depreciated
				# credit the depreciation amount
				IF pr_faaudit.depr_amt > 0 THEN 
					LET pr_temp.tran_type_ind = "AA" 
					LET pr_temp.acct_code = pr_glasset.accum_depr_code 
					LET pr_temp.base_debit_amt = 0 
					LET pr_temp.base_credit_amt = pr_faaudit.depr_amt 
					LET pr_temp.for_debit_amt = pr_temp.base_debit_amt 
					LET pr_temp.for_credit_amt = pr_temp.base_credit_amt 
					LET pr_temp.desc_text = "Asset Addition" 

					INSERT INTO posttab VALUES (pr_temp.*) 
					LET donesome = true 
				END IF 

			WHEN "S" {asset sales} 
				# first determine the type of sale we are dealing with
				# 1. sold AT net book value
				# 2. sold below net book value
				# 3. sold above nbv - no capital gain (ie below orig cost)
				# 4. sold above nbv - capital gain (ie over orig cost)

				CASE 
				{type 1.}
					WHEN (pr_faaudit.sale_amt = pr_fastatus.net_book_val_amt) 
						# debit the asset proceeds account
						LET pr_temp.tran_type_ind = "AS" 
						LET pr_temp.acct_code = pr_glasset.asset_proc_code 
						LET pr_temp.base_debit_amt = pr_faaudit.sale_amt 
						LET pr_temp.base_credit_amt = 0 
						LET pr_temp.for_debit_amt = pr_temp.base_debit_amt 
						LET pr_temp.for_credit_amt = pr_temp.base_credit_amt 
						LET pr_temp.desc_text = "Asset Sale" 

						INSERT INTO posttab VALUES (pr_temp.*) 
						LET donesome = true 

						# debit the accumulated depreciation account
						LET pr_temp.tran_type_ind = "AS" 
						LET pr_temp.acct_code = pr_glasset.accum_depr_code 
						LET pr_temp.base_debit_amt = pr_faaudit.depr_amt 
						LET pr_temp.base_credit_amt = 0 
						LET pr_temp.for_debit_amt = pr_temp.base_debit_amt 
						LET pr_temp.for_credit_amt = pr_temp.base_credit_amt 
						LET pr_temp.desc_text = "Asset Sale" 

						INSERT INTO posttab VALUES (pr_temp.*) 
						LET donesome = true 

						# credit the original cost account
						LET pr_temp.tran_type_ind = "AS" 
						LET pr_temp.acct_code = pr_glasset.orig_cost_code 
						LET pr_temp.base_debit_amt = 0 
						LET pr_temp.base_credit_amt = 
						pr_fastatus.cur_depr_cost_amt 
						LET pr_temp.for_debit_amt = pr_temp.base_debit_amt 
						LET pr_temp.for_credit_amt = pr_temp.base_credit_amt 
						LET pr_temp.desc_text = "Asset Sale" 

						INSERT INTO posttab VALUES (pr_temp.*) 
						LET donesome = true 

						{type 2.}
					WHEN (pr_faaudit.sale_amt < pr_fastatus.net_book_val_amt) 
						LET loss_amt = pr_fastatus.net_book_val_amt - 
						pr_faaudit.sale_amt 
						# debit the asset proceeds account
						LET pr_temp.tran_type_ind = "AS" 
						LET pr_temp.acct_code = pr_glasset.asset_proc_code 
						LET pr_temp.base_debit_amt = pr_faaudit.sale_amt 
						LET pr_temp.base_credit_amt = 0 
						LET pr_temp.for_debit_amt = pr_temp.base_debit_amt 
						LET pr_temp.for_credit_amt = pr_temp.base_credit_amt 
						LET pr_temp.desc_text = "Asset Sale" 

						INSERT INTO posttab VALUES (pr_temp.*) 
						LET donesome = true 

						# debit the loss on sale account
						LET pr_temp.tran_type_ind = "AS" 
						LET pr_temp.acct_code = pr_glasset.loss_on_sale_code 
						LET pr_temp.base_debit_amt = loss_amt 
						LET pr_temp.base_credit_amt = 0 
						LET pr_temp.for_debit_amt = pr_temp.base_debit_amt 
						LET pr_temp.for_credit_amt = pr_temp.base_credit_amt 
						LET pr_temp.desc_text = "Asset Sale" 

						INSERT INTO posttab VALUES (pr_temp.*) 
						LET donesome = true 

						# debit the accumulated depreciation account
						LET pr_temp.tran_type_ind = "AS" 
						LET pr_temp.acct_code = pr_glasset.accum_depr_code 
						LET pr_temp.base_debit_amt = pr_faaudit.depr_amt 
						LET pr_temp.base_credit_amt = 0 
						LET pr_temp.for_debit_amt = pr_temp.base_debit_amt 
						LET pr_temp.for_credit_amt = pr_temp.base_credit_amt 
						LET pr_temp.desc_text = "Asset Sale" 

						INSERT INTO posttab VALUES (pr_temp.*) 
						LET donesome = true 

						# credit the original cost account
						LET pr_temp.tran_type_ind = "AS" 
						LET pr_temp.acct_code = pr_glasset.orig_cost_code 
						LET pr_temp.base_debit_amt = 0 
						LET pr_temp.base_credit_amt = 
						pr_fastatus.cur_depr_cost_amt 
						LET pr_temp.for_debit_amt = pr_temp.base_debit_amt 
						LET pr_temp.for_credit_amt = pr_temp.base_credit_amt 
						LET pr_temp.desc_text = "Asset Sale" 

						INSERT INTO posttab VALUES (pr_temp.*) 
						LET donesome = true 

						{type 3. & type 4}
					WHEN (pr_faaudit.sale_amt > 
						pr_fastatus.net_book_val_amt) 
						IF pr_faaudit.sale_amt <= 
						pr_famast.orig_cost_amt THEN 

							# type 3
							# no capital gain

							LET net_profit = pr_faaudit.sale_amt - 
							pr_fastatus.net_book_val_amt 

							# debit the asset proceeds account
							LET pr_temp.tran_type_ind = "AS" 
							LET pr_temp.acct_code = 
							pr_glasset.asset_proc_code 
							LET pr_temp.base_debit_amt = pr_faaudit.sale_amt 
							LET pr_temp.base_credit_amt = 0 
							LET pr_temp.for_debit_amt = 
							pr_temp.base_debit_amt 
							LET pr_temp.for_credit_amt = 
							pr_temp.base_credit_amt 
							LET pr_temp.desc_text = "Asset Sale" 

							INSERT INTO posttab VALUES (pr_temp.*) 
							LET donesome = true 

							# debit the accumulated depreciation account
							LET pr_temp.tran_type_ind = "AS" 
							LET pr_temp.acct_code = 
							pr_glasset.accum_depr_code 
							LET pr_temp.base_debit_amt = pr_faaudit.depr_amt 
							LET pr_temp.base_credit_amt = 0 
							LET pr_temp.for_debit_amt = 
							pr_temp.base_debit_amt 
							LET pr_temp.for_credit_amt = 
							pr_temp.base_credit_amt 
							LET pr_temp.desc_text = "Asset Sale" 

							INSERT INTO posttab VALUES (pr_temp.*) 
							LET donesome = true 

							# credit the original cost account
							LET pr_temp.tran_type_ind = "AS" 
							LET pr_temp.acct_code = 
							pr_glasset.orig_cost_code 
							LET pr_temp.base_debit_amt = 0 
							LET pr_temp.base_credit_amt = 
							pr_fastatus.cur_depr_cost_amt 
							LET pr_temp.for_debit_amt = 
							pr_temp.base_debit_amt 
							LET pr_temp.for_credit_amt = 
							pr_temp.base_credit_amt 
							LET pr_temp.desc_text = "Asset Sale" 

							INSERT INTO posttab VALUES (pr_temp.*) 
							LET donesome = true 

							# credit the profit on sale account
							LET pr_temp.tran_type_ind = "AS" 
							LET pr_temp.acct_code = 
							pr_glasset.prof_on_sale_code 
							LET pr_temp.base_debit_amt = 0 
							LET pr_temp.base_credit_amt = net_profit 
							LET pr_temp.for_debit_amt = 
							pr_temp.base_debit_amt 
							LET pr_temp.for_credit_amt = 
							pr_temp.base_credit_amt 
							LET pr_temp.desc_text = "Asset Sale" 

							INSERT INTO posttab VALUES (pr_temp.*) 
							LET donesome = true 
						ELSE 
							# type 4
							# capital gain

							LET net_profit = pr_faaudit.sale_amt - 
							pr_fastatus.cur_depr_cost_amt 

							LET capr_profit = pr_faaudit.depr_amt 

							# debit the asset proceeds account
							LET pr_temp.tran_type_ind = "AS" 
							LET pr_temp.acct_code = 
							pr_glasset.asset_proc_code 
							LET pr_temp.base_debit_amt = pr_faaudit.sale_amt 
							LET pr_temp.base_credit_amt = 0 
							LET pr_temp.for_debit_amt = 
							pr_temp.base_debit_amt 
							LET pr_temp.for_credit_amt = 
							pr_temp.base_credit_amt 
							LET pr_temp.desc_text = "Asset Sale" 

							INSERT INTO posttab VALUES (pr_temp.*) 
							LET donesome = true 

							# debit the accumulated depreciation account
							LET pr_temp.tran_type_ind = "AS" 
							LET pr_temp.acct_code = 
							pr_glasset.accum_depr_code 
							LET pr_temp.base_debit_amt = pr_faaudit.depr_amt 
							LET pr_temp.base_credit_amt = 0 
							LET pr_temp.for_debit_amt = 
							pr_temp.base_debit_amt 
							LET pr_temp.for_credit_amt = 
							pr_temp.base_credit_amt 
							LET pr_temp.desc_text = "Asset Sale" 

							INSERT INTO posttab VALUES (pr_temp.*) 
							LET donesome = true 

							# credit the original cost account
							LET pr_temp.tran_type_ind = "AS" 
							LET pr_temp.acct_code =pr_glasset.orig_cost_code 
							LET pr_temp.base_debit_amt = 0 
							LET pr_temp.base_credit_amt = 
							pr_fastatus.cur_depr_cost_amt 
							LET pr_temp.for_debit_amt = 
							pr_temp.base_debit_amt 
							LET pr_temp.for_credit_amt = 
							pr_temp.base_credit_amt 
							LET pr_temp.desc_text = "Asset Sale" 

							INSERT INTO posttab VALUES (pr_temp.*) 
							LET donesome = true 

							# credit the profit on sale account
							LET pr_temp.tran_type_ind = "AS" 
							LET pr_temp.acct_code = 
							pr_glasset.prof_on_sale_code 
							LET pr_temp.base_debit_amt = 0 
							LET pr_temp.base_credit_amt = capr_profit 
							LET pr_temp.for_debit_amt = 
							pr_temp.base_debit_amt 
							LET pr_temp.for_credit_amt = 
							pr_temp.base_credit_amt 
							LET pr_temp.desc_text = "Asset Sale" 

							INSERT INTO posttab VALUES (pr_temp.*) 
							LET donesome = true 

							# credit the capital profit account
							LET pr_temp.tran_type_ind = "AS" 
							LET pr_temp.acct_code = 
							pr_glasset.capital_prof_code 
							LET pr_temp.base_debit_amt = 0 
							LET pr_temp.base_credit_amt = net_profit 
							LET pr_temp.for_debit_amt = 
							pr_temp.base_debit_amt 
							LET pr_temp.for_credit_amt = 
							pr_temp.base_credit_amt 
							LET pr_temp.desc_text = "Asset Sale" 

							INSERT INTO posttab VALUES (pr_temp.*) 
							LET donesome = true 
						END IF 
				END CASE 

			WHEN "V" {asset revaluation} 
				# debit the accumulated depreciation account
				LET pr_temp.tran_type_ind = "AV" 
				LET pr_temp.acct_code = pr_glasset.accum_depr_code 
				LET pr_temp.base_debit_amt = pr_faaudit.depr_amt 
				LET pr_temp.base_credit_amt = 0 
				LET pr_temp.for_debit_amt = pr_temp.base_debit_amt 
				LET pr_temp.for_credit_amt = pr_temp.base_credit_amt 
				LET pr_temp.desc_text = "Asset Revaluation" 

				INSERT INTO posttab VALUES (pr_temp.*) 
				LET donesome = true 

				# credit the original cost account with
				# the accumulated depreciation.
				LET pr_temp.tran_type_ind = "AV" 
				LET pr_temp.acct_code = pr_glasset.orig_cost_code 
				LET pr_temp.base_debit_amt = 0 
				LET pr_temp.base_credit_amt = pr_faaudit.depr_amt 
				LET pr_temp.for_debit_amt = pr_temp.base_debit_amt 
				LET pr_temp.for_credit_amt = pr_temp.base_credit_amt 
				LET pr_temp.desc_text = "Asset Revaluation" 

				INSERT INTO posttab VALUES (pr_temp.*) 
				LET donesome = true 

				# debit the original cost account with
				# the revalue amount.
				LET pr_temp.tran_type_ind = "AV" 
				LET pr_temp.acct_code = pr_glasset.orig_cost_code 
				LET pr_temp.base_debit_amt = pr_faaudit.sale_amt 
				LET pr_temp.base_credit_amt = 0 
				LET pr_temp.for_debit_amt = pr_temp.base_debit_amt 
				LET pr_temp.for_credit_amt = pr_temp.base_credit_amt 
				LET pr_temp.desc_text = "Asset Revaluation" 

				INSERT INTO posttab VALUES (pr_temp.*) 
				LET donesome = true 

				# credit the revaluation reserve account
				# with the revalue amount.
				LET pr_temp.tran_type_ind = "AV" 
				LET pr_temp.acct_code = pr_glasset.reval_res_code 
				LET pr_temp.base_debit_amt = 0 
				LET pr_temp.base_credit_amt = pr_faaudit.sale_amt 
				LET pr_temp.for_debit_amt = pr_temp.base_debit_amt 
				LET pr_temp.for_credit_amt = pr_temp.base_credit_amt 
				LET pr_temp.desc_text = "Asset Revaluation" 

				INSERT INTO posttab VALUES (pr_temp.*) 
				LET donesome = true 

			WHEN "R" {asset retirement} 
				# debit the accumulated depreciation with the
				# accumulated depreciation FROM the batch which
				# should contain accumulated depreciation ex the
				# fastatus record.
				LET pr_temp.tran_type_ind = "AR" 
				LET pr_temp.acct_code = pr_glasset.accum_depr_code 
				LET pr_temp.base_debit_amt = pr_faaudit.depr_amt 
				LET pr_temp.base_credit_amt = 0 
				LET pr_temp.for_debit_amt = pr_temp.base_debit_amt 
				LET pr_temp.for_credit_amt = pr_temp.base_credit_amt 
				LET pr_temp.desc_text = "Asset Retirement" 

				INSERT INTO posttab VALUES (pr_temp.*) 
				LET donesome = true 

				# debit the loss on sale account with the
				# net book value - entered as sale amount
				LET pr_temp.tran_type_ind = "AR" 
				LET pr_temp.acct_code = pr_glasset.loss_on_sale_code 
				LET pr_temp.base_debit_amt = pr_faaudit.sale_amt 
				LET pr_temp.base_credit_amt = 0 
				LET pr_temp.for_debit_amt = pr_temp.base_debit_amt 
				LET pr_temp.for_credit_amt = pr_temp.base_credit_amt 
				LET pr_temp.desc_text = "Asset Retirement" 

				INSERT INTO posttab VALUES (pr_temp.*) 
				LET donesome = true 

				# credit the original cost account with
				# the original cost. batch entry makes sure
				# asset_amt = orig_cost_amt
				LET pr_temp.tran_type_ind = "AR" 
				LET pr_temp.acct_code = pr_glasset.orig_cost_code 
				LET pr_temp.base_debit_amt = 0 
				LET pr_temp.base_credit_amt = pr_faaudit.asset_amt 
				LET pr_temp.for_debit_amt = pr_temp.base_debit_amt 
				LET pr_temp.for_credit_amt = pr_temp.base_credit_amt 
				LET pr_temp.desc_text = "Asset Retirement" 

				INSERT INTO posttab VALUES (pr_temp.*) 
				LET donesome = true 

			WHEN "T" {asset transfer - intra company} 
				IF pr_faaudit.asset_amt < 0 THEN 
					# transfer 'FROM' leg

					# debit accumulated depreciation
					# note that accum depreciation IS negative therefore
					# feed the accumulated depreciation as a credit
					# TO jourintf, jourintf IS smart enough TO
					# reverse a negative FROM a credit TO a debit
					LET pr_temp.tran_type_ind = "AT" 
					LET pr_temp.acct_code = pr_glasset.accum_depr_code 
					LET pr_temp.base_debit_amt = 0 
					LET pr_temp.base_credit_amt = pr_faaudit.depr_amt 
					LET pr_temp.for_debit_amt = pr_temp.base_debit_amt 
					LET pr_temp.for_credit_amt = pr_temp.base_credit_amt 
					LET pr_temp.desc_text = "Asset transfer - FROM" 

					INSERT INTO posttab VALUES (pr_temp.*) 
					LET donesome = true 

					# debit inter plant clearing
					LET pr_temp.tran_type_ind = "AT" 
					LET pr_temp.acct_code = pr_glasset.int_plant_cl_code 
					LET pr_temp.base_debit_amt = 
					pr_fastatus.net_book_val_amt 
					LET pr_temp.base_credit_amt = 0 
					LET pr_temp.for_debit_amt = pr_temp.base_debit_amt 
					LET pr_temp.for_credit_amt = pr_temp.base_credit_amt 
					LET pr_temp.desc_text = "Asset transfer - FROM" 

					INSERT INTO posttab VALUES (pr_temp.*) 
					LET donesome = true 

					# credit original cost account
					LET pr_temp.tran_type_ind = "AT" 
					LET pr_temp.acct_code = pr_glasset.orig_cost_code 
					LET pr_temp.base_debit_amt = 0 
					LET pr_temp.base_credit_amt = 
					pr_fastatus.cur_depr_cost_amt 
					LET pr_temp.for_debit_amt = pr_temp.base_debit_amt 
					LET pr_temp.for_credit_amt = pr_temp.base_credit_amt 
					LET pr_temp.desc_text = "Asset transfer - FROM" 

					INSERT INTO posttab VALUES (pr_temp.*) 
					LET donesome = true 

				ELSE 

					# transfer 'TO' leg
					# credit accumulated depreciation
					LET pr_temp.tran_type_ind = "AT" 
					LET pr_temp.acct_code = pr_glasset.accum_depr_code 
					LET pr_temp.base_debit_amt = 0 
					LET pr_temp.base_credit_amt = pr_faaudit.depr_amt 
					LET pr_temp.for_debit_amt = pr_temp.base_debit_amt 
					LET pr_temp.for_credit_amt = pr_temp.base_credit_amt 
					LET pr_temp.desc_text = "Asset transfer - TO" 

					INSERT INTO posttab VALUES (pr_temp.*) 
					LET donesome = true 

					# credit inter plant clearing
					LET pr_temp.tran_type_ind = "AT" 
					LET pr_temp.acct_code = pr_glasset.int_plant_cl_code 
					LET pr_temp.base_debit_amt = 0 
					LET pr_temp.base_credit_amt = 
					pr_fastatus.net_book_val_amt 
					LET pr_temp.for_debit_amt = pr_temp.base_debit_amt 
					LET pr_temp.for_credit_amt = pr_temp.base_credit_amt 
					LET pr_temp.desc_text = "Asset transfer - TO" 

					INSERT INTO posttab VALUES (pr_temp.*) 
					LET donesome = true 

					# debit original cost account
					LET pr_temp.tran_type_ind = "AT" 
					LET pr_temp.acct_code = pr_glasset.orig_cost_code 
					LET pr_temp.base_debit_amt = 
					pr_fastatus.cur_depr_cost_amt 
					LET pr_temp.base_credit_amt = 0 
					LET pr_temp.for_debit_amt = pr_temp.base_debit_amt 
					LET pr_temp.for_credit_amt = pr_temp.base_credit_amt 
					LET pr_temp.desc_text = "Asset transfer - TO" 

					INSERT INTO posttab VALUES (pr_temp.*) 
					LET donesome = true 
				END IF 

			WHEN "J" {asset adjustment} 
				IF pr_faaudit.asset_amt != 0 THEN 
					# asset value adjustment
					LET pr_temp.tran_type_ind = "AJ" 
					LET pr_temp.acct_code = pr_glasset.orig_cost_code 
					LET pr_temp.base_debit_amt = pr_faaudit.asset_amt 
					LET pr_temp.base_credit_amt = 0 
					LET pr_temp.for_debit_amt = pr_temp.base_debit_amt 
					LET pr_temp.for_credit_amt = pr_temp.base_credit_amt 
					LET pr_temp.desc_text = "Asset adjustment" 

					INSERT INTO posttab VALUES (pr_temp.*) 
					LET donesome = true 

					LET pr_temp.tran_type_ind = "AJ" 
					LET pr_temp.acct_code = pr_glasset.cpip_acct_code 
					LET pr_temp.base_debit_amt = 0 
					LET pr_temp.base_credit_amt = pr_faaudit.asset_amt 
					LET pr_temp.for_debit_amt = pr_temp.base_debit_amt 
					LET pr_temp.for_credit_amt = pr_temp.base_credit_amt 
					LET pr_temp.desc_text = "Asset adjustment" 

					INSERT INTO posttab VALUES (pr_temp.*) 
					LET donesome = true 
				END IF 

				IF pr_faaudit.depr_amt != 0 THEN 
					# asset depreciation adjustment
					LET pr_temp.tran_type_ind = "AJ" 
					LET pr_temp.acct_code = pr_glasset.depr_exp_code 
					LET pr_temp.base_debit_amt = pr_faaudit.depr_amt 
					LET pr_temp.base_credit_amt = 0 
					LET pr_temp.for_debit_amt = pr_temp.base_debit_amt 
					LET pr_temp.for_credit_amt = pr_temp.base_credit_amt 
					LET pr_temp.desc_text = "Asset adjustment" 

					INSERT INTO posttab VALUES (pr_temp.*) 
					LET donesome = true 

					LET pr_temp.tran_type_ind = "AJ" 
					LET pr_temp.acct_code = pr_glasset.accum_depr_code 
					LET pr_temp.base_debit_amt = 0 
					LET pr_temp.base_credit_amt = pr_faaudit.depr_amt 
					LET pr_temp.for_debit_amt = pr_temp.base_debit_amt 
					LET pr_temp.for_credit_amt = pr_temp.base_credit_amt 
					LET pr_temp.desc_text = "Asset adjustment" 

					INSERT INTO posttab VALUES (pr_temp.*) 
					LET donesome = true 
				END IF 

			WHEN "D" {depreciation } 

				# debit the depreciation expense account
				LET pr_temp.tran_type_ind = "AD" 
				LET pr_temp.acct_code = pr_glasset.depr_exp_code 
				LET pr_temp.base_debit_amt = pr_faaudit.depr_amt 
				LET pr_temp.base_credit_amt = 0 
				LET pr_temp.for_debit_amt = pr_temp.base_debit_amt 
				LET pr_temp.for_credit_amt = pr_temp.base_credit_amt 
				LET pr_temp.desc_text = "Asset Depreciation Calc" 

				INSERT INTO posttab VALUES (pr_temp.*) 
				LET donesome = true 

				# credit the accumulated depreciation account
				LET pr_temp.tran_type_ind = "AD" 
				LET pr_temp.acct_code = pr_glasset.accum_depr_code 
				LET pr_temp.base_debit_amt = 0 
				LET pr_temp.base_credit_amt = pr_faaudit.depr_amt 
				LET pr_temp.for_debit_amt = pr_temp.base_debit_amt 
				LET pr_temp.for_credit_amt = pr_temp.base_credit_amt 
				LET pr_temp.desc_text = "Asset Depreciation Calc" 

				INSERT INTO posttab VALUES (pr_temp.*) 
				LET donesome = true 

		END CASE 

		LET err_msg = "" 

		#---------------------------------------------------------
		OUTPUT TO REPORT FGL_rpt_list_audit(l_rpt_idx,
		pr_faaudit.*,"",err_msg)
		#---------------------------------------------------------


	END FOREACH {faaudit ROW FOR batch} 

	IF no_line_err THEN 
		# store batch number FOR UPDATE with journal number
		INSERT INTO tempbatch VALUES (pr_fabatch.batch_num) 




	ELSE 
		# IF a gl account code error has occurred in a batch THEN
		# dump the whole batch FROM posttab continue with next batch
		# batch post flag won't be updated so it will be picked up next post
		DELETE FROM posttab WHERE ref_num = pr_fabatch.batch_num 
	END IF 

END FOREACH {fabatch row} 
END IF 

RETURN donesome 

END FUNCTION 



FUNCTION get_batch() 

	GOTO bypass 
	LABEL recovery: 
	CALL update_poststatus(TRUE,STATUS,"FA") 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 


	# determine the years AND periods we are dealing with
	#OPEN WINDOW getinfo AT 14,5 with 1 rows, 68 columns
	#attribute (border, reverse, MESSAGE line last)  -- alch KD-757

	--          prompt "Enter beginning batch number OR RETURN FOR all: "  -- albo
	--                 FOR start_batch
	LET start_batch = promptInput("Enter beginning batch number OR RETURN FOR all: ","",11) -- albo 

	IF int_flag OR quit_flag THEN 
		EXIT program 
	END IF 

	IF start_batch IS NULL THEN 
		LET start_batch = 0 
		LET end_batch = 999999999 
	ELSE 
		--              prompt "Enter ending batch number OR RETURN FOR last: " -- albo
		--                     FOR end_batch
		LET end_batch = promptInput("Enter ending batch number OR RETURN FOR last: ","",11) -- albo 
		IF int_flag OR quit_flag THEN 
			EXIT program 
		END IF 
		IF end_batch IS NULL THEN 
			LET end_batch = 999999999 
		END IF 
	END IF 

	#CLOSE WINDOW getinfo  -- alch KD-757

END FUNCTION 



FUNCTION create_gl_batch(y_num,p_num) 

	DEFINE 
	y_num LIKE fabatch.year_num, 
	p_num LIKE fabatch.period_num, 
	b_num LIKE fabatch.batch_num 


	GOTO bypass 
	LABEL recovery: 
	CALL update_poststatus(TRUE,STATUS,"FA") 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 

	# IF this IS a properly configured online site (ie correct # locks
	# THEN they may wish TO run one big transaction. In which CASE
	# poststatus.online_ind = "Y". Just TO be flexible you may also
	# run the program in the 'old' lock table mode (online_ind = "L".
	# This will still use the post tables but will allow single glob_rec_kandoouser.cmpy_code
	# sites TO ensure absolute integrity of data.

	LET glob_one_trans = false 
	IF glob_rec_poststatus.online_ind = "Y" OR 
	glob_rec_poststatus.online_ind = "L" THEN 
		BEGIN WORK 
			LET glob_one_trans = true 
			LET glob_in_trans = true 
		END IF 

		# lock tables IF program IS TO run in Lock mode
		IF glob_rec_poststatus.online_ind = "L" THEN 
			LOCK TABLE glparms in share MODE 
			LOCK TABLE fabatch in share MODE 
			LOCK TABLE faaudit in share MODE 
			LOCK TABLE fastatus in share MODE 
			LOCK TABLE glasset in share MODE 
			LOCK TABLE postfabatch in share MODE 
		END IF 

		# 1502 "Posting Fixed Assets Batches"
		LET msgresp = kandoomsg("F","1502","") 

		IF create_posttemp(y_num,p_num) THEN 



			SELECT * 
			INTO pr_glparms.* 
			FROM glparms 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 

			LET bal_rec.tran_type_ind = "AB" 
			LET bal_rec.acct_code = pr_glparms.susp_acct_code 
			LET bal_rec.desc_text = "Asset Suspense Balancing Entry" 

			LET sql_stmt = "SELECT * FROM posttab " 

			IF post_status = 2 THEN 
				LET glob_posted_journal = glob_rec_poststatus.jour_num 
			ELSE 
				LET glob_posted_journal = NULL 
			END IF 

			LET tester = jourintf(sql_stmt, 
			glob_rec_kandoouser.cmpy_code, 
			glob_rec_kandoouser.sign_on_code, 
			bal_rec.*, 
			p_num, 
			y_num, 
			fa_jour_code, 
			"F", 
			pr_temp.currency_code, 
			pr_output, 
			"FA") 


			IF tester < 0 THEN 
				# 3527 "SUSPENSE ACCOUNTS USED, Press RETURN "
				LET msgresp = kandoomsg("U",3527,"") 
			ELSE 
				IF tester = 0 THEN 
					# 9504 "NO GL BATCH CREATED....... - press RETURN"
					CALL update_flag(pr_fabatch.batch_num) 
					LET msgresp = kandoomsg("U",9504,"") 
				ELSE 
					# 3528 "Posting complete - Press RETURN"
					LET msgresp = kandoomsg("U",3528,"") 
				END IF 
			END IF 

		ELSE 
			# 9504 "No FA batch lines processed - Check Audit REPORT"
			LET msgresp = kandoomsg("F",9504,"") 
			CALL update_flag(pr_fabatch.batch_num) 
			SLEEP 2 
		END IF 

		LET glob_st_code = 3 
		LET glob_post_text = kandooword("Commenced UPDATE of jour_num","019") 
		IF glob_post_text IS NULL THEN 
			LET glob_post_text = "Commenced UPDATE of jour_num in fabatch" 
		END IF 
		CALL update_poststatus(FALSE,0,"FA") 

		# only one batch created per post AT this stage
		IF post_status <= 3 OR post_status = 99 THEN 
			DECLARE b_curs CURSOR with HOLD FOR 
			SELECT * 
			FROM tempbatch 

			FOREACH b_curs INTO b_num 
				IF NOT glob_one_trans THEN 
					BEGIN WORK 
						LET glob_in_trans = true 
					END IF 


					UPDATE fabatch SET jour_num = tester, 
					post_gl_flag = "Y" 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND batch_num = b_num 

					IF NOT glob_one_trans THEN 
					COMMIT WORK 
					LET glob_in_trans = false 
				END IF 
			END FOREACH 
		END IF 

		LET glob_st_code = 4 
		LET glob_post_text = kandooword("Commenced DELETE FROM postfabatch","020") 
		IF glob_post_text IS NULL THEN 
			LET glob_post_text = "Commenced DELETE FROM postfabatch" 
		END IF 
		CALL update_poststatus(FALSE,0,"FA") 

		IF post_status <= 4 OR post_status = 99 THEN 
			LET glob_err_text = kandooword("DELETE FROM postfabatch","021") 
			IF glob_err_text IS NULL THEN 
				LET glob_err_text = "DELETE FROM postfabatch" 
			END IF 
			IF NOT glob_one_trans THEN 
				BEGIN WORK 
					LET glob_in_trans = true 
				END IF 
				IF glob_rec_poststatus.online_ind != "L" THEN 
					LOCK TABLE postfabatch in share MODE 
				END IF 
				DELETE FROM postfabatch WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF NOT glob_one_trans THEN 
				COMMIT WORK 
				LET glob_in_trans = false 
			END IF 
		END IF 

		LET glob_st_code = 99 
		LET glob_post_text = "FA posting completed correctly" 
		CALL update_poststatus(FALSE,0,"FA") 

		WHENEVER ERROR stop 

		UPDATE poststatus SET post_running_flag = "N" 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND module_code = "FA" 

		IF glob_one_trans THEN 
			# 8502 "Accept Posting (Y/N) "
			LET msgresp = kandoomsg("U",8502,"") 
			IF msgresp = "N" THEN 
				ROLLBACK WORK 
				LET glob_in_trans = false 
				UPDATE poststatus SET post_running_flag = "N" 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND module_code = "FA" 
			ELSE 
			COMMIT WORK 
			LET glob_in_trans = false 
		END IF 
	END IF 

END FUNCTION 

FUNCTION update_flag(pr_batch_num) 
	DEFINE 
	pr_fabatch RECORD LIKE fabatch.*, 
	pr_batch_num LIKE fabatch.batch_num 

	IF glob_rec_poststatus.online_ind = "N" THEN 
		BEGIN WORK 
		END IF 

		DECLARE update_curs CURSOR FOR 
		SELECT * 
		FROM fabatch 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND batch_num = pr_batch_num 
		FOR UPDATE 

		OPEN update_curs 
		FETCH update_curs INTO pr_fabatch.* 
		IF status != notfound THEN 
			UPDATE fabatch SET post_gl_flag = "N" 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND batch_num = pr_batch_num 
		END IF 

		LET glob_err_text = kandooword("FGL - fabatch post flag SET","005") 
		IF glob_err_text IS NULL THEN 
			LET glob_err_text = "FGL - fabatch post flag SET" 
		END IF 

		IF glob_rec_poststatus.online_ind = "N" THEN 
		COMMIT WORK 
	END IF 

END FUNCTION 







