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
GLOBALS "../gl/GRK_GLOBALS.4gl" 
############################################################
# FUNCTION GRK_rpt_process_1_a_sc()
#
# Single currency
# GRKa Consolidated Summary Trial Balance - standard REPORT
#  with Year/Period TO Date & Actual/Preclose Options
############################################################
FUNCTION GRK_rpt_process_1_a_sc(p_rpt_idx,p_query_text) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_query_text STRING
	DEFINE l_rec_account RECORD LIKE account.* 
	DEFINE l_rec_report RECORD 
		consol_code LIKE consolhead.consol_code, 
		chart_code LIKE account.chart_code, 
		acct_code LIKE account.acct_code, 
		year_num LIKE period.year_num, 
		period_num LIKE period.period_num, 
		open_amt DECIMAL(16,2), 
		debit_amt DECIMAL(16,2), 
		credit_amt DECIMAL(16,2), 
		bal_amt DECIMAL(16,2) 
	END RECORD 

	PREPARE sa1_account FROM p_query_text 
	DECLARE ca1_account CURSOR FOR sa1_account 
	FOREACH ca1_account INTO l_rec_account.* 
		LET l_rec_report.consol_code = glob_rec_consolhead.consol_code 
		LET l_rec_report.chart_code = l_rec_account.chart_code 
		LET l_rec_report.acct_code = l_rec_account.acct_code 
		LET l_rec_report.open_amt = l_rec_account.open_amt 
		LET l_rec_report.year_num = glob_rec_period.year_num 
		LET l_rec_report.period_num = NULL 
		SELECT sum(debit_amt), 
		sum(credit_amt) 
		INTO l_rec_report.debit_amt, 
		l_rec_report.credit_amt 
		FROM accountledger 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND acct_code = l_rec_account.acct_code 
		AND year_num = glob_rec_period.year_num 
		AND period_num <= glob_rec_period.period_num 
		AND tran_type_ind != "CL" 
		IF l_rec_report.open_amt IS NULL THEN 
			LET l_rec_report.open_amt = 0 
		END IF 
		IF l_rec_report.debit_amt IS NULL THEN 
			LET l_rec_report.debit_amt = 0 
		END IF 
		IF l_rec_report.credit_amt IS NULL THEN 
			LET l_rec_report.credit_amt = 0 
		END IF 
		LET l_rec_report.bal_amt = l_rec_report.open_amt 
		+ l_rec_report.debit_amt 
		- l_rec_report.credit_amt 
		IF glob_zero_ind = "N" 
		AND l_rec_report.open_amt = 0 
		AND l_rec_report.debit_amt = 0 
		AND l_rec_report.credit_amt = 0 
		AND l_rec_report.bal_amt = 0 THEN 
			CONTINUE FOREACH 
		ELSE 
			LET l_rec_report.open_amt = l_rec_report.open_amt * glob_conv_qty 
			LET l_rec_report.debit_amt = l_rec_report.debit_amt * glob_conv_qty 
			LET l_rec_report.credit_amt = l_rec_report.credit_amt * glob_conv_qty 
			LET l_rec_report.bal_amt = l_rec_report.bal_amt * glob_conv_qty 

			#---------------------------------------------------------
			OUTPUT TO REPORT GRK_rpt_list_a_sc(p_rpt_idx,l_rec_report.*) 
			IF NOT rpt_int_flag_handler2("Account:",l_rec_account.acct_code, NULL,p_rpt_idx) THEN
				EXIT FOREACH 
			END IF 
			#---------------------------------------------------------

		END IF 
	END FOREACH 
END FUNCTION 


############################################################
# FUNCTION GRK_rpt_process_2_a_sc()
#
# Single currency
############################################################
FUNCTION GRK_rpt_process_2_a_sc(p_rpt_idx,p_query_text) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_query_text STRING 
	DEFINE l_rec_account RECORD LIKE account.* 
	DEFINE l_rec_report RECORD 
		consol_code LIKE consolhead.consol_code, 
		chart_code LIKE account.chart_code, 
		acct_code LIKE account.acct_code, 
		year_num LIKE period.year_num, 
		period_num LIKE period.period_num, 
		open_amt DECIMAL(16,2), 
		debit_amt DECIMAL(16,2), 
		credit_amt DECIMAL(16,2), 
		bal_amt DECIMAL(16,2) 
	END RECORD 

	PREPARE sa2_account FROM p_query_text 
	DECLARE ca2_account CURSOR FOR sa2_account 
	FOREACH ca2_account INTO l_rec_account.* 
		LET l_rec_report.consol_code = glob_rec_consolhead.consol_code 
		LET l_rec_report.chart_code = l_rec_account.chart_code 
		LET l_rec_report.acct_code = l_rec_account.acct_code 
		LET l_rec_report.year_num = glob_rec_period.year_num 
		LET l_rec_report.open_amt = l_rec_account.open_amt 
		LET l_rec_report.period_num = NULL 
		SELECT sum(debit_amt), 
		sum(credit_amt) 
		INTO l_rec_report.debit_amt, 
		l_rec_report.credit_amt 
		FROM accounthist 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND acct_code = l_rec_account.acct_code 
		AND year_num = glob_rec_period.year_num 
		AND period_num <= glob_rec_period.period_num 
		IF l_rec_report.open_amt IS NULL THEN 
			LET l_rec_report.open_amt = 0 
		END IF 
		IF l_rec_report.debit_amt IS NULL THEN 
			LET l_rec_report.debit_amt = 0 
		END IF 
		IF l_rec_report.credit_amt IS NULL THEN 
			LET l_rec_report.credit_amt = 0 
		END IF 
		LET l_rec_report.bal_amt = l_rec_report.open_amt 
		+ l_rec_report.debit_amt 
		- l_rec_report.credit_amt 
		IF glob_zero_ind = "N" 
		AND l_rec_report.open_amt = 0 
		AND l_rec_report.debit_amt = 0 
		AND l_rec_report.credit_amt = 0 
		AND l_rec_report.bal_amt = 0 THEN 
			CONTINUE FOREACH 
		ELSE 
			LET l_rec_report.open_amt = l_rec_report.open_amt * glob_conv_qty 
			LET l_rec_report.debit_amt = l_rec_report.debit_amt * glob_conv_qty 
			LET l_rec_report.credit_amt = l_rec_report.credit_amt * glob_conv_qty 
			LET l_rec_report.bal_amt = l_rec_report.bal_amt * glob_conv_qty 

			#---------------------------------------------------------
			OUTPUT TO REPORT GRK_rpt_list_a_sc(p_rpt_idx,l_rec_report.*) 
			IF NOT rpt_int_flag_handler2("Account:",l_rec_account.acct_code, NULL,p_rpt_idx) THEN
				EXIT FOREACH 
			END IF 
			#---------------------------------------------------------

		END IF 
	END FOREACH 
END FUNCTION 



############################################################
# FUNCTION GRK_rpt_process_3_a_sc()
#
# Single currency
############################################################
FUNCTION GRK_rpt_process_3_a_sc(p_rpt_idx,p_query_text) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_query_text STRING 
	DEFINE l_rec_account RECORD LIKE account.* 
	DEFINE l_temp_credit_amt DECIMAL(16,2) 
	DEFINE l_temp_debit_amt DECIMAL(16,2) 
	DEFINE l_rec_report RECORD 
		consol_code LIKE consolhead.consol_code, 
		chart_code LIKE account.chart_code, 
		acct_code LIKE account.acct_code, 
		year_num LIKE period.year_num, 
		period_num LIKE period.period_num, 
		open_amt DECIMAL(16,2), 
		debit_amt DECIMAL(16,2), 
		credit_amt DECIMAL(16,2), 
		bal_amt DECIMAL(16,2) 
	END RECORD 

	PREPARE sa3_account FROM p_query_text 
	DECLARE ca3_account CURSOR FOR sa3_account 
	FOREACH ca3_account INTO l_rec_account.* 
		LET l_rec_report.consol_code = glob_rec_consolhead.consol_code 
		LET l_rec_report.chart_code = l_rec_account.chart_code 
		LET l_rec_report.acct_code = l_rec_account.acct_code 
		LET l_rec_report.year_num = glob_rec_period.year_num 
		LET l_rec_report.period_num = glob_rec_period.period_num 
		SELECT sum(debit_amt), 
		sum(credit_amt) 
		INTO l_temp_debit_amt, 
		l_temp_credit_amt 
		FROM accountledger 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND acct_code = l_rec_account.acct_code 
		AND year_num = glob_rec_period.year_num 
		AND period_num < glob_rec_period.period_num 
		AND tran_type_ind != "CL" 
		LET l_rec_report.open_amt = l_rec_account.open_amt 
		+ l_temp_debit_amt 
		- l_temp_credit_amt 
		SELECT sum(debit_amt), 
		sum(credit_amt) 
		INTO l_rec_report.debit_amt, 
		l_rec_report.credit_amt 
		FROM accountledger 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND acct_code = l_rec_account.acct_code 
		AND year_num = glob_rec_period.year_num 
		AND period_num = glob_rec_period.period_num 
		AND tran_type_ind != "CL" 
		IF l_rec_report.open_amt IS NULL THEN 
			LET l_rec_report.open_amt = 0 
		END IF 
		IF l_rec_report.debit_amt IS NULL THEN 
			LET l_rec_report.debit_amt = 0 
		END IF 
		IF l_rec_report.credit_amt IS NULL THEN 
			LET l_rec_report.credit_amt = 0 
		END IF 
		LET l_rec_report.bal_amt = l_rec_report.open_amt 
		+ l_rec_report.debit_amt 
		- l_rec_report.credit_amt 
		IF glob_zero_ind = "N" 
		AND l_rec_report.open_amt = 0 
		AND l_rec_report.debit_amt = 0 
		AND l_rec_report.credit_amt = 0 
		AND l_rec_report.bal_amt = 0 THEN 
			CONTINUE FOREACH 
		ELSE 
			LET l_rec_report.open_amt = l_rec_report.open_amt * glob_conv_qty 
			LET l_rec_report.debit_amt = l_rec_report.debit_amt * glob_conv_qty 
			LET l_rec_report.credit_amt = l_rec_report.credit_amt * glob_conv_qty 
			LET l_rec_report.bal_amt = l_rec_report.bal_amt * glob_conv_qty 
			#---------------------------------------------------------
			OUTPUT TO REPORT GRK_rpt_list_a_sc(p_rpt_idx,l_rec_report.*) 
			IF NOT rpt_int_flag_handler2("Account:",l_rec_account.acct_code, NULL,p_rpt_idx) THEN
				EXIT FOREACH 
			END IF 
			#---------------------------------------------------------
			
		END IF 
	END FOREACH 
END FUNCTION 



############################################################
# FUNCTION GRK_rpt_process_4_a_sc()
#
# Single currency
############################################################
FUNCTION GRK_rpt_process_4_a_sc(p_rpt_idx,p_query_text) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_query_text STRING 
	DEFINE l_rec_account RECORD LIKE account.* 
	DEFINE l_rec_report RECORD 
		consol_code LIKE consolhead.consol_code, 
		chart_code LIKE account.chart_code, 
		acct_code LIKE account.acct_code, 
		year_num LIKE period.year_num, 
		period_num LIKE period.period_num, 
		open_amt DECIMAL(16,2), 
		debit_amt DECIMAL(16,2), 
		credit_amt DECIMAL(16,2), 
		bal_amt DECIMAL(16,2) 
	END RECORD 

	PREPARE sa4_account FROM p_query_text 
	DECLARE ca4_account CURSOR FOR sa4_account 
	FOREACH ca4_account INTO l_rec_account.* 
		LET l_rec_report.consol_code = glob_rec_consolhead.consol_code 
		LET l_rec_report.chart_code = l_rec_account.chart_code 
		LET l_rec_report.acct_code = l_rec_account.acct_code 
		LET l_rec_report.year_num = l_rec_account.year_num 
		LET l_rec_report.period_num = glob_rec_period.period_num 
		SELECT open_amt, 
		debit_amt, 
		credit_amt 
		INTO l_rec_report.open_amt, 
		l_rec_report.debit_amt, 
		l_rec_report.credit_amt 
		FROM accounthist 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND acct_code = l_rec_report.acct_code 
		AND year_num = l_rec_report.year_num 
		AND period_num = l_rec_report.period_num 
		IF l_rec_report.open_amt IS NULL THEN 
			LET l_rec_report.open_amt = 0 
		END IF 
		IF l_rec_report.debit_amt IS NULL THEN 
			LET l_rec_report.debit_amt = 0 
		END IF 
		IF l_rec_report.credit_amt IS NULL THEN 
			LET l_rec_report.credit_amt = 0 
		END IF 
		LET l_rec_report.bal_amt = l_rec_report.open_amt 
		+ l_rec_report.debit_amt 
		- l_rec_report.credit_amt 
		IF glob_zero_ind = "N" 
		AND l_rec_report.open_amt = 0 
		AND l_rec_report.debit_amt = 0 
		AND l_rec_report.credit_amt = 0 
		AND l_rec_report.bal_amt = 0 THEN 
			CONTINUE FOREACH 
		ELSE 
			LET l_rec_report.open_amt = l_rec_report.open_amt * glob_conv_qty 
			LET l_rec_report.debit_amt = l_rec_report.debit_amt * glob_conv_qty 
			LET l_rec_report.credit_amt = l_rec_report.credit_amt * glob_conv_qty 
			LET l_rec_report.bal_amt = l_rec_report.bal_amt * glob_conv_qty 
			#---------------------------------------------------------
			OUTPUT TO REPORT GRK_rpt_list_a_sc(p_rpt_idx,l_rec_report.*) 
			IF NOT rpt_int_flag_handler2("Account:",l_rec_account.acct_code, NULL,p_rpt_idx) THEN
				EXIT FOREACH 
			END IF 
			#---------------------------------------------------------
		END IF 
	END FOREACH 
END FUNCTION 


############################################################
# REPORT GRK_rpt_list_a_sc(p_rpt_idx,p_rec_report) 
#
# Single currency
############################################################
REPORT GRK_rpt_list_a_sc(p_rpt_idx,p_rec_report) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_report RECORD 
		consol_code LIKE consolhead.consol_code, 
		chart_code LIKE account.chart_code, 
		acct_code LIKE account.acct_code, 
		year_num LIKE period.year_num, 
		period_num LIKE period.period_num, 
		open_amt DECIMAL(16,2), 
		debit_amt DECIMAL(16,2), 
		credit_amt DECIMAL(16,2), 
		bal_amt DECIMAL(16,2) 
	END RECORD 
	DEFINE l_rec_consolhead RECORD LIKE consolhead.* 
	DEFINE l_todate_head CHAR(14) 
	DEFINE l_period_head CHAR(6) 
	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_open_tot CHAR(20) 
	DEFINE l_bal_tot CHAR(20) 
	DEFINE l_offset1 SMALLINT 
	DEFINE l_offset2 SMALLINT 
	DEFINE l_offset3 SMALLINT 
	DEFINE l_cmpy_head CHAR(130) 
	DEFINE l_line1 CHAR(130) 
	DEFINE l_line2 CHAR(130) 

	OUTPUT 
--	left margin 0 
	ORDER BY p_rec_report.consol_code, p_rec_report.chart_code 
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		  PRINT COLUMN 01, "Values in Currency: ", glob_rept_curr_code, COLUMN 40, "Exchange Rate: ", glob_conv_qty USING "<<<.<<<" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

			IF glob_totals_ind = "Y" THEN 
				LET l_todate_head = "Year TO Date" 
				LET l_period_head = NULL 
			ELSE 
				LET l_todate_head = "Period TO Date" 
				LET l_period_head = "Period" 
			END IF 
			PRINT COLUMN 01, "Account", 
			COLUMN 40, "Year", 
			COLUMN 45, l_period_head, 
			COLUMN 59, "Opening", 
			COLUMN 75, l_todate_head, 
			COLUMN 94, l_todate_head, 
			COLUMN 118,"Ending" 
			PRINT COLUMN 01, "Number", 
			COLUMN 15, "Name", 
			COLUMN 59, "Balance", 
			COLUMN 78, "Debits", 
			COLUMN 98,"Credits", 
			COLUMN 118,"Balance" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

			SELECT * INTO l_rec_consolhead.* FROM consolhead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND consol_code = p_rec_report.consol_code 
			PRINT COLUMN 01, "Consolidation Code: ", 
			l_rec_consolhead.consol_code clipped, " ", 
			l_rec_consolhead.desc_text 
			SKIP 1 line 

		BEFORE GROUP OF p_rec_report.consol_code 
			SKIP TO top OF PAGE 

		AFTER GROUP OF p_rec_report.chart_code 
			NEED 2 LINES 
			SELECT * 
			INTO l_rec_coa.* 
			FROM coa 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND acct_code = p_rec_report.acct_code 
			LET l_open_tot = ac_form(glob_rec_kandoouser.cmpy_code, GROUP sum(p_rec_report.open_amt), 
			l_rec_coa.type_ind, glob_rec_glparms.style_ind) 
			LET l_bal_tot = ac_form(glob_rec_kandoouser.cmpy_code, GROUP sum(p_rec_report.bal_amt), 
			l_rec_coa.type_ind, glob_rec_glparms.style_ind) 
			PRINT COLUMN 1, p_rec_report.chart_code, 
			COLUMN 40, p_rec_report.year_num USING "####", 
			COLUMN 45, p_rec_report.period_num USING "###", 
			COLUMN 50, l_open_tot, 
			COLUMN 70, GROUP sum(p_rec_report.debit_amt) 
			USING "----,---,---,--&.&&", 
			COLUMN 86, GROUP sum(p_rec_report.credit_amt) 
			USING "----,---,---,--&.&&", 
			COLUMN 107, l_bal_tot 
			PRINT COLUMN 15, l_rec_coa.desc_text[1,40] 

		AFTER GROUP OF p_rec_report.consol_code 
			NEED 2 LINES 
			SKIP 1 line 
			LET l_open_tot = ac_form(glob_rec_kandoouser.cmpy_code, GROUP sum(p_rec_report.open_amt), 
			l_rec_coa.type_ind, glob_rec_glparms.style_ind) 
			LET l_bal_tot = ac_form(glob_rec_kandoouser.cmpy_code, GROUP sum(p_rec_report.bal_amt), 
			l_rec_coa.type_ind, glob_rec_glparms.style_ind) 
			PRINT COLUMN 1, " Total:", 
			COLUMN 50, l_open_tot, 
			COLUMN 70, GROUP sum(p_rec_report.debit_amt) 
			USING "----,---,---,--&.&&", 
			COLUMN 86, GROUP sum(p_rec_report.credit_amt) 
			USING "----,---,---,--&.&&", 
			COLUMN 107, l_bal_tot 

		ON LAST ROW 
			NEED 17 LINES 
			SKIP 2 line 
			LET l_open_tot = ac_form(glob_rec_kandoouser.cmpy_code, sum(p_rec_report.open_amt), 
			l_rec_coa.type_ind, glob_rec_glparms.style_ind) 
			LET l_bal_tot = ac_form(glob_rec_kandoouser.cmpy_code, sum(p_rec_report.bal_amt), 
			l_rec_coa.type_ind, glob_rec_glparms.style_ind) 
			PRINT COLUMN 1, "Grand Total:", 
			COLUMN 50, l_open_tot, 
			COLUMN 70, sum(p_rec_report.debit_amt) 
			USING "----,---,---,--&.&&", 
			COLUMN 86, sum(p_rec_report.credit_amt) 
			USING "----,---,---,--&.&&", 
			COLUMN 107, l_bal_tot 
			SKIP 1 line 
			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 

				PRINT COLUMN 25, "YTD/PTD - ", glob_totals_ind 
				PRINT COLUMN 25, "Actuals/Preclose - ", glob_timing_ind 
				PRINT COLUMN 25, "Print zero a/cs - ", glob_zero_ind 
				PRINT COLUMN 25, "Year/period - ", glob_rec_period.year_num, "/",	glob_rec_period.period_num USING "<<<<" 
				PRINT COLUMN 8, "Segments - ",glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text 
				PRINT COLUMN 8, "Consolidations - ",glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_option1
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 
 
END REPORT 
