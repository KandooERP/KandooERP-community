{
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

	Source code beautified by beautify.pl on 2020-01-03 10:10:01	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "T_GW_GLOBALS.4gl" 
GLOBALS "TGW1_GLOBALS.4gl" 

# Module variables
DEFINE mv_time CHAR(8), 
mv_kandoo_columns, 
mv_desc_pos1, 
mv_desc_pos2, 
mv_desc_pos3 INTEGER, 
mv_rpt_line, 
mv_col_desc1, 
mv_col_desc2, 
mv_col_desc3 char(330), #330 = maximum REPORT length. 
mv_date_1, 
mv_date_2 DATE, 
mv_period_desc CHAR(25) 


FUNCTION produce_rpt() 
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE fv_rpt_name CHAR(60), 
	fv_filename1 CHAR(20), 
	fv_print_cmd CHAR(37), 
	fv_count, 
	fv_idx SMALLINT, 

	fv_slct CHAR(100), 
	fv_where CHAR(200), 
	fv_time CHAR(100) 

	##########################################################################
	# Get REPORT runtime variables Section.
	##########################################################################

	LET mv_time = time 

	SELECT start_date, end_date 
	INTO mv_date_1, mv_date_2 
	FROM period 
	WHERE cmpy_code = gr_entry_criteria.cmpy_code 
	AND year_num = gr_entry_criteria.year_num 
	AND period_num = gr_entry_criteria.period_num 

	LET mv_period_desc = "FROM ", mv_date_1 USING "dd/mm/yy",	" TO ", mv_date_2 USING "dd/mm/yy" 

	#LET glob_rec_rmsreps.report_width_num = glob_rec_rmsreps.report_width_num() 
	LET mv_kandoo_columns = max_columns() 

{
	LET mv_rpt_line = rpt_line(glob_rec_rmsreps.report_width_num) 
	CALL desc_positions(glob_rec_rmsreps.report_width_num) RETURNING mv_desc_pos1, 
	mv_desc_pos2, 
	mv_desc_pos3 
}
	LET mv_col_desc1 = col_hdr_desc(1) 
	LET mv_col_desc2 = col_hdr_desc(2) 
	LET mv_col_desc3 = col_hdr_desc(3) 

	# SELECT sign code details INTO global variable
	SELECT * INTO gr_signcode.* 
	FROM signcode 
	WHERE sign_code = gr_rpthead.sign_code 

	##########################################################################
	# END of Get REPORT runtime variables Section.
	##########################################################################

	IF gr_entry_criteria.run_opt = "I" 
	THEN 
		MESSAGE " Clearing REPORT accumulators, please wait..." 
		attribute(yellow) 
	END IF 
	CALL clear_accum() 

	IF gr_entry_criteria.run_opt = "I" 
	THEN 
		MESSAGE " Selecting records information, please wait..." 
		attribute(yellow) 
	END IF 

	LET fv_rpt_name = "GL ", gr_rpthead.rpt_id clipped, " ", 	gr_rpthead.rpt_text clipped 

	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start(getmoduleid(),"TGW1_rpt_list","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT TGW1_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = 0, 
	BOTTOM MARGIN = 0, 
	LEFT MARGIN = 0, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	DECLARE rptline_curs CURSOR FOR 
	SELECT * 
	FROM rptline 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND line_code = gr_rptlinegrp.line_code 
	ORDER BY line_id 

	DECLARE rptcol_curs CURSOR FOR 
	SELECT * 
	FROM rptcol 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND col_code = gr_rptcolgrp.col_code 
	ORDER BY col_id 

	IF gv_acct_group IS NULL 
	OR gv_acct_group = " " THEN 
		LET gv_tempcoa_append = NULL 
		LET gv_tempcoa_clause = NULL 
	ELSE 
		LET gv_tempcoa_append = ", tempcoa" 
		LET gv_tempcoa_clause = " AND tempcoa.acct_code = AH.acct_code " 
	END IF 

	FOREACH rptline_curs INTO gr_rptline.* 
		IF int_flag OR quit_flag OR gv_aborted THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET gv_aborted = true 
			EXIT FOREACH 
		END IF 

		LET gv_wksht_tots = false 
		LET gv_first_line = true 
		LET gv_account_code = NULL 
		LET gv_curr_code = NULL 

		DELETE FROM colaccum 
		WHERE job_id = gv_job_id 
		AND rpt_id = gr_rpthead.rpt_id 
		AND accum_id = 0 #these records are used FOR calcline/ 
		#worksheet total line printing
		LET gv_account_code = NULL 
		LET gv_detl_flag = false 
		INITIALIZE gr_exthead.* TO NULL 
		INITIALIZE gr_glline.* TO NULL 
		INITIALIZE gr_calchead.* TO NULL 

		IF gr_rptline.line_type = gr_mrwparms.gl_line_type THEN 
			LET gv_analdown_clause = analdown_clause() 
		END IF 

		# Clear COLUMN item amounts.
		FOR fv_count = 1 TO mv_kandoo_columns 
			LET ga_colitem_amt[fv_count] = 0 
		END FOR 

		# Get the relevant line details
		CASE 
			WHEN gr_rptline.line_type = gr_mrwparms.gl_line_type 
				SELECT * 
				INTO gr_glline.* 
				FROM glline 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND line_uid = gr_rptline.line_uid 

				# IF currency selection on line clashes with currency selection
				# AT run time, nothing will meet the criteria!!
				IF gr_glline.curr_code IS NOT NULL 
				AND gr_entry_criteria.curr_slct IS NOT NULL 
				AND gr_glline.curr_code <> gr_entry_criteria.curr_slct THEN 
					CONTINUE FOREACH 
				END IF 

				IF gr_glline.curr_code IS NOT NULL THEN 
					LET gv_curr_slct = gr_glline.curr_code 
				ELSE 
					IF gr_entry_criteria.curr_slct IS NOT NULL THEN 
						LET gv_curr_slct = gr_entry_criteria.curr_slct 
					ELSE 
						LET gv_curr_slct = NULL 
					END IF 
				END IF 

				IF gr_glline.detl_flag = "D" THEN 
					LET gv_detl_flag = true 
				END IF 

			WHEN gr_rptline.line_type = gr_mrwparms.calc_line_type 
				SELECT * INTO gr_calchead.* 
				FROM calchead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND line_uid = gr_rptline.line_uid 

			WHEN gr_rptline.line_type = gr_mrwparms.ext_link_line_type 
				SELECT * INTO gr_exthead.* 
				FROM exthead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND line_uid = gr_rptline.line_uid 
		END CASE 

		IF gr_entry_criteria.worksheet_rpt = "W" THEN 
			LET gv_always_print = "Y" 
		ELSE 
			LET gv_always_print = NULL 

			CASE 
				WHEN gr_rptline.line_type = gr_mrwparms.gl_line_type 
					LET gv_always_print = gr_glline.always_print 
				WHEN gr_rptline.line_type = gr_mrwparms.ext_link_line_type 
					LET gv_always_print = gr_exthead.always_print 
				WHEN gr_rptline.line_type = gr_mrwparms.calc_line_type 
					LET gv_always_print = gr_calchead.always_print 
			END CASE 

			IF NOT (gr_rpthead.always_print_line IS NULL 
			OR gr_rpthead.always_print_line = " ") THEN 
				LET gv_always_print = gr_rpthead.always_print_line 
			END IF 

			IF gv_always_print = "N" THEN 
				IF gr_rptline.accum_id IS NULL THEN #don't NEED TO process this line 
					CONTINUE FOREACH 
				ELSE 
					LET gv_detl_flag = false #do NEED TO process, but NOT in detail 
				END IF 
			END IF 
		END IF 

		CASE 
			WHEN gr_rptline.line_type = gr_mrwparms.gl_line_type 
				IF gr_entry_criteria.worksheet_rpt = "W" 
				OR gv_detl_flag THEN 
					# Check currency flag as well
					IF pr_glparms.use_currency_flag != "Y" 
					OR (gr_entry_criteria.conv_flag = "Y" 
					AND gv_curr_slct IS null) THEN 
						CALL acct_proc() 
					ELSE 
						CALL acctcurr_proc() 
					END IF 
				ELSE 
					IF pr_glparms.use_currency_flag != "Y" 
					OR (gr_entry_criteria.conv_flag = "Y" 
					AND gv_curr_slct IS null) THEN 
						CALL rptcol_proc(rpt_rmsreps_idx_get_idx("TGW1_rpt_list"))  
					ELSE 
						CALL curr_proc() 
					END IF 
				END IF 

			WHEN gr_rptline.line_type = gr_mrwparms.calc_line_type 
				CALL calc_proc() 

			OTHERWISE 
				CALL rptcol_proc(rpt_rmsreps_idx_get_idx("TGW1_rpt_list"))  
		END CASE 

		IF gv_aborted THEN 
			EXIT FOREACH 
		END IF 

		IF gr_entry_criteria.worksheet_rpt = "W" 
		AND gr_rptline.line_type = gr_mrwparms.gl_line_type THEN 
			LET gv_wksht_tots = true 
			LET gv_first_line = true 
			CALL print_tots() 
		END IF 
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT TGW1_rpt_list
	CALL rpt_finish("TGW1_rpt_list")
	#------------------------------------------------------------

	CALL clear_accum() 
{
	IF gr_rptslect.print_code = " " 
	OR gr_rptslect.print_code IS NULL THEN 
		CALL upd_reports(fv_filename1, 
		glob_rec_rmsreps.page_num, 
		glob_rec_rmsreps.report_width_num, 
		glob_rec_rmsreps.page_length_num) 
	ELSE 
		WHENEVER ERROR CONTINUE 

		IF gv_aborted THEN 
			CALL upd_reports(fv_filename1, 
			glob_rec_rmsreps.page_num, 
			glob_rec_rmsreps.report_width_num, 
			glob_rec_rmsreps.page_length_num) 
			RETURN 
		ELSE 
			IF print_report(fv_filename1, gr_rptslect.print_code) THEN 
				# upd_reports_dir IS in TGW1e.  It sets STATUS = "Sent TO Print"
				CALL upd_reports_dir(fv_filename1, 
				glob_rec_rmsreps.page_num, 
				glob_rec_rmsreps.report_width_num, 
				glob_rec_rmsreps.page_length_num) 
			ELSE #unsuccesful printing OF REPORT 
				CALL upd_reports(fv_filename1, 
				glob_rec_rmsreps.page_num, 
				glob_rec_rmsreps.report_width_num, 
				glob_rec_rmsreps.page_length_num) 
			END IF 
		END IF 

		WHENEVER ERROR stop 
	END IF 
}
END FUNCTION 

##########################################################################
FUNCTION acct_proc() 

	DEFINE 
	fv_s1 CHAR(1600), 
	fv_chart_slct CHAR(100), 
	fv_chart_clause LIKE gllinedetl.chart_clause 

	DECLARE gldetl_curs1 CURSOR FOR 
	SELECT chart_clause, operator, seq_num 
	FROM gllinedetl 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND line_uid = gr_rptline.line_uid 
	ORDER BY seq_num 

	FOREACH gldetl_curs1 INTO fv_chart_clause, gv_chart_operator 
		LET fv_chart_slct = build_chart(fv_chart_clause) 

		LET fv_s1 
		= "SELECT unique A.acct_code ", 
		" FROM account A, accounthist AH", 
		gv_tempcoa_append clipped, 
		" WHERE A.cmpy_code = ", 
		"'", gr_entry_criteria.cmpy_code clipped, "'", 
		" AND AH.cmpy_code = ", 
		"'", gr_entry_criteria.cmpy_code clipped, "'", 
		fv_chart_slct clipped, 
		" AND A.acct_code = AH.acct_code", 
		" AND A.year_num = AH.year_num", 
		gv_tempcoa_clause clipped, 
		gv_segment_criteria clipped, 
		gv_analdown_clause clipped, 
		" ORDER BY A.acct_code " 

		PREPARE s_2 FROM fv_s1 
		DECLARE acct_curs CURSOR FOR s_2 
		###OPEN s_2
		LET gv_account_code = NULL 

		FOREACH acct_curs INTO gv_account_code 
			LET gv_first_line = true 
			CALL rptcol_proc(rpt_rmsreps_idx_get_idx("TGW1_rpt_list"))  
			IF gv_aborted THEN 
				EXIT FOREACH 
			END IF 
		END FOREACH #foreach account in chart_clause 

		###close s_2

		IF gv_aborted THEN 
			EXIT FOREACH 
		END IF 
	END FOREACH #foreach chart_clause in gl line 

	IF gr_entry_criteria.run_opt = "I" 
	THEN 
		DISPLAY "" at 3,2 
	END IF 

END FUNCTION 
##########################################################################

FUNCTION curr_proc() 

	IF gv_curr_slct IS NULL THEN 
		DECLARE tempcurr_curs1 CURSOR FOR 
		SELECT curr_code 
		FROM temp_curr 
		ORDER BY curr_code 

		FOREACH tempcurr_curs1 INTO gv_curr_code 
			CALL rptcol_proc(rpt_rmsreps_idx_get_idx("TGW1_rpt_list")) 
			IF gv_aborted THEN 
				EXIT FOREACH 
			END IF 
		END FOREACH 
	ELSE 
		DECLARE tempcurr_curs2 CURSOR FOR 
		SELECT curr_code 
		FROM temp_curr 
		WHERE curr_code = gv_curr_slct 
		ORDER BY curr_code 

		FOREACH tempcurr_curs2 INTO gv_curr_code 
			CALL rptcol_proc(rpt_rmsreps_idx_get_idx("TGW1_rpt_list"))  
			IF gv_aborted THEN 
				EXIT FOREACH 
			END IF 
		END FOREACH 
	END IF 

	IF gr_entry_criteria.run_opt = "I" 
	THEN 
		DISPLAY "" at 3,2 
	END IF 

END FUNCTION 


##########################################################################
FUNCTION acctcurr_proc() 

	DEFINE 
	fv_s1 CHAR(1600), 
	fv_chart_slct CHAR(100), 
	fv_chart_clause LIKE gllinedetl.chart_clause, 
	fv_curr_clause CHAR(100), 
	fv_prev_acct LIKE account.acct_code 

	IF gv_curr_slct IS NOT NULL THEN 
		LET fv_curr_clause = " AND AHC.currency_code = '", gv_curr_slct, "'" 
	END IF 

	DECLARE gldetl_curs2 CURSOR FOR 
	SELECT chart_clause, operator, seq_num 
	FROM gllinedetl 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND line_uid = gr_rptline.line_uid 
	ORDER BY seq_num 

	FOREACH gldetl_curs2 INTO fv_chart_clause, gv_chart_operator 
		LET fv_chart_slct = build_chart(fv_chart_clause) 

		LET fv_s1 
		= "SELECT unique A.acct_code, AHC.currency_code ", 
		" FROM account A, accounthist AH, accounthistcur AHC", 
		gv_tempcoa_append clipped, 
		" WHERE A.cmpy_code = ", 
		"'", gr_entry_criteria.cmpy_code clipped, "'", 
		" AND AH.cmpy_code = ", 
		"'", gr_entry_criteria.cmpy_code clipped, "'", 
		" AND AHC.cmpy_code = ", 
		"'", gr_entry_criteria.cmpy_code clipped, "'", 
		fv_chart_slct clipped, 
		" AND A.acct_code = AH.acct_code", 
		" AND A.acct_code = AHC.acct_code", 
		" AND A.year_num = AH.year_num", 
		" AND A.year_num = AHC.year_num", 
		" AND AH.period_num = AHC.period_num", 
		gv_tempcoa_clause clipped, 
		gv_segment_criteria clipped, 
		gv_analdown_clause clipped, 
		fv_curr_clause clipped, 
		" ORDER BY A.acct_code, AHC.currency_code " 

		PREPARE s_1 FROM fv_s1 
		DECLARE acctcurr_curs CURSOR FOR s_1 
		###OPEN s_1
		LET gv_account_code = NULL 
		LET fv_prev_acct = NULL 

		FOREACH acctcurr_curs INTO gv_account_code, gv_curr_code 
			IF fv_prev_acct IS NULL 
			OR fv_prev_acct <> gv_account_code THEN 
				LET gv_first_line = true 
			END IF 

			CALL rptcol_proc(rpt_rmsreps_idx_get_idx("TGW1_rpt_list"))  
			IF gv_aborted THEN 
				EXIT FOREACH 
			END IF 
			LET fv_prev_acct = gv_account_code 
		END FOREACH #foreach account in chart_clause 

		####close s_1

		IF gv_aborted THEN 
			EXIT FOREACH 
		END IF 
	END FOREACH #foreach chart_clause in gl line 

	IF gr_entry_criteria.run_opt = "I" 
	THEN 
		DISPLAY "" at 3,2 
	END IF 

END FUNCTION 


##########################################################################
FUNCTION calc_proc() 

	#  Totals are always stored in both base AND transaction currencies.
	#  They also have TO be fed INTO the rptline's accum_id in both base AND
	#  transaction currencies.
	#  They are TO PRINT out in base, OR transaction, depending on what has
	#  been specified in calchead.
	#  IF printing in transaction, there IS one line per currency code

	DEFINE fv_operator LIKE calcline.operator, 
	fv_accum_id LIKE calcline.accum_id, 
	fr_colaccum RECORD LIKE colaccum.*, 
	fr_colaccum2 RECORD LIKE colaccum.* 

	#Set up total line(s) - These are split by currency

	#Retrieve all COLUMN accumulator details FOR calculation.
	DECLARE calcline_curs CURSOR FOR 
	SELECT calcline.accum_id, 
	calcline.operator, 
	calcline.seq_num 
	FROM calcline 
	WHERE calcline.line_uid = gr_rptline.line_uid 
	ORDER BY calcline.seq_num 

	FOREACH calcline_curs INTO fv_accum_id, fv_operator 
		DECLARE tot_curs CURSOR FOR 
		SELECT * 
		FROM colaccum 
		WHERE job_id = gv_job_id 
		AND rpt_id = gr_rpthead.rpt_id 
		AND accum_id = fv_accum_id 
		ORDER BY curr_type, 
		curr_code 

		FOREACH tot_curs INTO fr_colaccum.* 
			SELECT * 
			INTO fr_colaccum2.* 
			FROM colaccum 
			WHERE job_id = gv_job_id 
			AND rpt_id = gr_rpthead.rpt_id 
			AND col_uid = fr_colaccum.col_uid 
			AND accum_id = 0 
			AND curr_type = fr_colaccum.curr_type 
			AND curr_code = fr_colaccum.curr_code 

			IF status THEN 
				LET fr_colaccum2.* = fr_colaccum.* 
				LET fr_colaccum2.accum_id = 0 
				LET fr_colaccum2.accum_amt = 0 
				INSERT INTO colaccum VALUES (fr_colaccum2.*) 
			END IF 

			# Perform operator calculation.
			LET fr_colaccum2.accum_amt = operator_calc(fr_colaccum.accum_amt, 
			fr_colaccum2.accum_amt, 
			fv_operator) 

			UPDATE colaccum 
			SET accum_amt = fr_colaccum2.accum_amt 
			WHERE job_id = gv_job_id 
			AND rpt_id = gr_rpthead.rpt_id 
			AND col_uid = fr_colaccum.col_uid 
			AND accum_id = 0 
			AND curr_type = fr_colaccum.curr_type 
			AND curr_code = fr_colaccum.curr_code 

		END FOREACH 
	END FOREACH 

	IF gr_rptline.accum_id IS NOT NULL 
	AND gr_rptline.accum_id <> 0 THEN 
		DECLARE accum_curs CURSOR FOR 
		SELECT * 
		FROM colaccum 
		WHERE job_id = gv_job_id 
		AND rpt_id = gr_rpthead.rpt_id 
		AND accum_id = 0 

		FOREACH accum_curs INTO fr_colaccum2.* 
			LET gv_curr_code = fr_colaccum2.curr_code 
			CALL updt_accum(fr_colaccum2.col_uid, 
			fr_colaccum2.accum_amt, 
			fr_colaccum2.curr_type, 
			0) 
		END FOREACH 
	END IF 

	CALL print_tots() 

END FUNCTION 


FUNCTION print_tots() 

	#Print out total lines
	DECLARE totline_curs CURSOR FOR 
	SELECT curr_type, 
	curr_code 
	FROM colaccum 
	WHERE job_id = gv_job_id 
	AND rpt_id = gr_rpthead.rpt_id 
	AND accum_id = 0 
	GROUP BY curr_type, 
	curr_code 
	ORDER BY curr_type, 
	curr_code 

	FOREACH totline_curs INTO gr_colaccum.curr_type, gv_curr_code 
		CALL rptcol_proc(rpt_rmsreps_idx_get_idx("TGW1_rpt_list"))  
	END FOREACH 

	LET gv_curr_code = NULL 

END FUNCTION 
##########################################################################

FUNCTION rptcol_proc(p_rpt_idx) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE 
	fv_count, 
	fv_wksht_idx, 
	fv_pos SMALLINT 

	LET fv_pos = 1 
	OPEN rptcol_curs 
	LET gv_desc_col_num = 0 
	#2708 - Clear COLUMN totals array
	FOR fv_count = 1 TO mv_kandoo_columns 
		LET ga_colitem_amt[fv_count] = 0 
	END FOR 

	IF gr_entry_criteria.run_opt = "I" 
	THEN 
		{
		     OPEN WINDOW wGW1 AT 14,10 with 2 rows, 50 columns  -- albo  KD-768
		            ATTRIBUTE(border, cyan)
		}
	END IF 

	FOREACH rptcol_curs INTO gr_rptcol.* 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET gv_aborted = true 
			EXIT FOREACH 
		END IF 

		CASE 
			WHEN gr_entry_criteria.conv_flag = "Y" 
				LET gv_col_curr_type = "B" 
			WHEN gr_rptline.line_type = gr_mrwparms.calc_line_type 
				IF gr_calchead.curr_type IS NULL THEN 
					LET gv_col_curr_type = gr_rptcol.curr_type 
				ELSE 
					LET gv_col_curr_type = gr_calchead.curr_type 
				END IF 
			WHEN gr_rptline.line_type = gr_mrwparms.gl_line_type 
				LET gv_col_curr_type = gr_rptcol.curr_type 
			OTHERWISE 
				LET gv_col_curr_type = gr_rptcol.curr_type 
		END CASE 

		IF gr_entry_criteria.run_opt = "I" 
		THEN 
			DISPLAY " Report:", gr_rpthead.rpt_id clipped, 
			" Line:", gr_rptline.line_id, 
			" Column:", gr_rptcol.col_id, 
			" ", gv_curr_code at 1,1 
		END IF 

		#---------------------------------------------------------
		OUTPUT TO REPORT TGW1_rpt_list(p_rpt_idx,
		gr_rptline.*,		
		gr_rptcol.*, 
		fv_pos, 
		gv_always_print) 
		#---------------------------------------------------------

		LET fv_wksht_idx = gr_rptcol.col_id 

		IF gr_rptcol.print_flag = "Y" THEN 
			LET fv_pos = fv_pos + gr_rptcol.width 
		END IF 
	END FOREACH 

	CLOSE rptcol_curs 
	IF gr_entry_criteria.run_opt = "I" 
	THEN 
		--     CLOSE WINDOW wGW1  -- albo  KD-768
	END IF 
END FUNCTION 

##########################################################################

REPORT TGW1_rpt_list(p_rpt_idx,rr_rptline, rr_rptcol, rv_pos, rv_always_print) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE rr_rptline RECORD LIKE rptline.*, 
	rr_rptcol RECORD LIKE rptcol.*, 
	rv_fmt_amt, 
	rv_line_desc, 
	rv_under_line LIKE descline.line_desc, 
	rv_always_print CHAR(1) 

	DEFINE rv_line_detl CHAR(500) 

	DEFINE rv_prn_flag, # PRINT line flag 
	rv_non_zero, 
	rv_counter, 
	rv_status, 
	rv_acct_fnd, 
	rv_pos SMALLINT, # COLUMN location position. 
	rv_print_curr CHAR(5), 
	rv_amt DECIMAL(18,2) 

	OUTPUT 
--	PAGE length 66 
--	left margin 0 
--	top margin 0 

	ORDER external BY rr_rptline.line_id, 
	rr_rptcol.col_id 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1

		BEFORE GROUP OF rr_rptcol.col_id 
			IF rr_rptcol.col_id = 1 THEN 
				IF gv_first_line AND gv_wksht_tots THEN 
					SKIP 1 line 
				END IF 

				IF gr_rptline.line_type = gr_mrwparms.gl_line_type 
				OR gr_rptline.line_type = gr_mrwparms.calc_line_type 
				OR gr_rptline.line_type = gr_mrwparms.ext_link_line_type THEN 
					LET rv_acct_fnd = false 
					IF gr_rptline.line_type = gr_mrwparms.gl_line_type THEN 
						#             IF gr_entry_criteria.worksheet_rpt = "W"
						#               OR gv_detl_flag = TRUE THEN
						LET rv_prn_flag = true #default PRINT flag TO true. 
						LET rv_non_zero = false 
						#             END IF
					END IF 
				END IF 
			END IF 

		BEFORE GROUP OF rr_rptline.line_id 
			LET rv_prn_flag = true #default PRINT flag TO true. 
			LET rv_acct_fnd = true #only used FOR gl/calc LINES 
			LET rv_non_zero = false 

		AFTER GROUP OF rr_rptline.line_id 
			# Number of lines TO drop.
			LET rr_rptline.drop_lines = rr_rptline.drop_lines - 1 
			IF rr_rptline.page_break_follow = "Y" THEN 
				SKIP TO top OF PAGE 
			ELSE 
				FOR rv_counter = 1 TO rr_rptline.drop_lines 
					PRINT 
				END FOR 
			END IF 


		ON EVERY ROW 


			#-----------------------------------------------------------------------------#
			# Report Header Section                                                       #
			#-----------------------------------------------------------------------------#

			IF lineno = 1 OR lineno = 0 THEN 
				IF gr_entry_criteria.std_head_per_page = "Y" OR pageno = 1 THEN 
					PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
					PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
					PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  
	
					IF NOT (gr_rpthead.rpt_desc1 IS NULL 
					OR gr_rpthead.rpt_desc1 = " ") THEN 
						PRINT COLUMN mv_desc_pos1, gr_rpthead.rpt_desc1 
					END IF 

					IF NOT (gr_rpthead.rpt_desc2 IS NULL 
					OR gr_rpthead.rpt_desc2 = " ") THEN 
						PRINT COLUMN mv_desc_pos2, gr_rpthead.rpt_desc2 
						-- Only PRINT the period default IF rpt_desc2 IS NULL.
						-- POW use this FOR date descriptions FOR reports that aren't FOR
						-- single periods.
					ELSE 
						PRINT COLUMN mv_desc_pos3, mv_period_desc 
					END IF 

					#PRINT COLUMN mv_desc_pos3, mv_period_desc

					PRINT COLUMN 01, mv_rpt_line clipped 
					SKIP 1 line 
				END IF 

				IF gr_entry_criteria.col_hdr_per_page = "Y" OR pageno = 1 THEN 
					IF gr_entry_criteria.std_head_per_page = "N" AND pageno > 1 THEN 
						PRINT COLUMN 01, mv_rpt_line clipped 
					END IF 

					# Column description lines.  Build in FUNCTION col_hdr_desc().
					IF length( mv_col_desc1 ) > 0 THEN 
						PRINT COLUMN 01, mv_col_desc1 clipped 
					END IF 
					IF length( mv_col_desc2 ) > 0 THEN 
						PRINT COLUMN 01, mv_col_desc2 clipped 
					END IF 
					IF length( mv_col_desc3 ) > 0 THEN 
						PRINT COLUMN 01, mv_col_desc3 clipped 
					END IF 
					PRINT COLUMN 01, mv_rpt_line clipped 
				END IF 
			END IF 

			#-----------------------------------------------------------------------------#
			# END of Report Header Section                                                #
			#-----------------------------------------------------------------------------#

			#-----------------------------------------------------------------------------#
			# Main Processing Section                                                     #
			#-----------------------------------------------------------------------------#

			IF rv_line_detl IS NULL THEN 
				LET rv_line_detl = " " 
			END IF 

			IF rv_pos > 1 THEN 
				LET rv_pos = rv_pos - 1 
			END IF 

			#  The CASE statement IS executed in the following ORDER:
			#    Underlines
			#    Currency code COLUMN
			#    Description (COLUMN)
			#    General Ledger
			#    Accumulator (Calc)
			#    External Link
			#    *** Text lines are picked up by Description processing

			CASE 
				WHEN rr_rptline.line_type = gr_mrwparms.under_line_type 
					IF rr_rptcol.width > 0 
					AND rr_rptcol.print_flag = "Y" THEN 
						LET rv_under_line = under_line(rr_rptline.line_uid, 
						rr_rptcol.col_uid, 
						rr_rptcol.width, 
						rr_rptcol.amt_picture) 
						IF rv_pos = 1 THEN 
							LET rv_line_detl = rv_under_line clipped 
						ELSE 
							LET rv_line_detl = rv_line_detl[1,rv_pos], 
							rv_under_line clipped 
						END IF 
					END IF 

				WHEN blank_col(rr_rptcol.col_uid) 

				WHEN curr_col(rr_rptcol.col_uid) 
					IF rr_rptcol.print_flag = "Y" THEN 
						IF rr_rptline.line_type = gr_mrwparms.gl_line_type 
						OR rr_rptline.line_type = gr_mrwparms.calc_line_type THEN 
							CASE 
								WHEN gr_entry_criteria.conv_flag = "Y" 
									LET rv_print_curr = gr_entry_criteria.conv_curr 
								WHEN rr_rptline.line_type = gr_mrwparms.calc_line_type 
									OR (rr_rptline.line_type = gr_mrwparms.gl_line_type 
									AND gv_wksht_tots) 
									LET rv_print_curr = gv_print_curr 
								WHEN rr_rptline.line_type = gr_mrwparms.gl_line_type 
									LET rv_print_curr = gv_curr_code 
							END CASE 
						ELSE 
							LET rv_print_curr = " " 
						END IF 

						LET rv_line_detl = rv_line_detl[1,rv_pos], 
						rv_print_curr 
					END IF 

				WHEN desc_col(rr_rptcol.col_uid) 
					IF rr_rptcol.print_flag = "Y" 
					AND gv_first_line 
					AND rr_rptcol.width > 0 THEN 
						CASE 
							WHEN rv_always_print = "N" 
							OTHERWISE 
								LET rv_line_desc = col_desc(rr_rptline.line_uid, 
								rr_rptcol.width) 
								IF rv_pos = 1 THEN 
									LET rv_line_detl = rv_line_desc clipped 
								ELSE 
									LET rv_line_detl = rv_line_detl[1,rv_pos], 
									rv_line_desc clipped 
								END IF 
						END CASE 
					END IF 


				WHEN rr_rptline.line_type = gr_mrwparms.gl_line_type 
					OR rr_rptline.line_type = gr_mrwparms.ext_link_line_type 
					OR (rr_rptline.line_type = gr_mrwparms.calc_line_type 
					AND gv_col_curr_type = gr_colaccum.curr_type) 

					CALL colitem_amt(rr_rptline.line_uid) 
					RETURNING rv_amt, 
					rv_fmt_amt, 
					rv_status 

					IF NOT rv_status THEN 
						LET rv_acct_fnd = true 
						IF rv_always_print = "N" THEN 
							LET rv_prn_flag = false 
						ELSE 
							IF rr_rptcol.print_flag = "Y" THEN 
								IF rv_pos = 1 THEN 
									LET rv_line_detl = rv_fmt_amt clipped 
								ELSE 
									LET rv_line_detl = rv_line_detl[1,rv_pos], 
									rv_fmt_amt clipped 
								END IF 
							END IF 

							# Check IF GL line IS TO be printed.(O=Only PRINT Non-Zeros).
							IF rv_always_print = "O" THEN 
								IF NOT rv_non_zero THEN 
									IF rv_amt <> 0 THEN 
										LET rv_prn_flag = true 
										LET rv_non_zero = true 
									ELSE 
										LET rv_prn_flag = false 
									END IF 
								END IF 
							END IF 
						END IF 
					END IF 

			END CASE 


			#Now Print Line.
			# rv_acct_fnd IS only used FOR glline/calc lines; AT the time of calling
			# colitem_amt, the account has been found using segment/line/account group
			# criteria, HOWEVER the analacross_clause isn't in effect AT this stage AND the
			# account might NOT meet this criteria, therefore it may NOT have TO be printed.
			# rv_acct_fnd IS SET WHEN the account has met AT the segment criteria, IF any,
			# of AT least one COLUMN
			# FOR those lines that aren't gl worksheet/detailed, rv_acct_flag IS SET TO TRUE
			# as a default

			IF rr_rptcol.col_id = mv_kandoo_columns THEN 
				IF rv_prn_flag 
				AND rv_acct_fnd THEN 
					PRINT rv_line_detl clipped 
					LET gv_first_line = false 
				END IF 
				LET rv_line_detl = " " 
			END IF 


			#-----------------------------------------------------------------------------#
			# END of Main Processing Section                                              #
			#-----------------------------------------------------------------------------#

		ON LAST ROW 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	

			SKIP 2 LINES 
			IF gv_aborted THEN 
				PRINT COLUMN 01, "---===== REPORT ABORTED =====---" 
			ELSE 
				PRINT COLUMN 01, "---===== END OF REPORT =====---" 
			END IF 


END REPORT 
