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
GLOBALS "../gl/G_GL_GLOBALS.4gl" 
GLOBALS "../gl/GRG_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"

############################################################
# Summary Trial Balance - currency REPORT with Year/Period TO Date & Actual/Preclose Options
############################################################
############################################################
# FUNCTION GRG_rpt_process_b1()
#
#
############################################################
FUNCTION GRG_rpt_process_b1(p_rpt_idx,p_query_text,p_conv_qty,p_rec_period)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_query_text STRING
	DEFINE p_conv_qty LIKE rate_exchange.conv_sell_qty 
	DEFINE p_rec_period RECORD LIKE period.* 
	DEFINE l_zero_ind CHAR(1) 	
	DEFINE l_rec_accountcur RECORD LIKE accountcur.* 
	DEFINE l_rec_report RECORD 
		chart_code LIKE accountcur.chart_code, 
		acct_code LIKE accountcur.acct_code, 
		currency_code LIKE accountcur.currency_code, 
		year_num LIKE period.year_num, 
		period_num LIKE period.period_num, 
		open_amt DECIMAL(16,2), 
		debit_amt DECIMAL(16,2), 
		credit_amt DECIMAL(16,2), 
		bal_amt DECIMAL(16,2) 
	END RECORD 
	DEFINE l_rept_curr_code LIKE currency.currency_code #base currency	
	DEFINE l_rec_currency RECORD LIKE currency.*
	
	LET p_rec_period.year_num	 = glob_arr_rec_rpt_rmsreps[p_rpt_idx].ref1_num
	LET p_rec_period.period_num = glob_arr_rec_rpt_rmsreps[p_rpt_idx].ref2_num		
	LET l_rept_curr_code	 = glob_arr_rec_rpt_rmsreps[p_rpt_idx].ref1_code	#can not follow why we have 2 currency codes
	LET l_rec_currency.currency_code = glob_arr_rec_rpt_rmsreps[p_rpt_idx].ref2_code #can not follow why we have 2 currency codes		
	LET l_zero_ind = glob_rec_rpt_selector.ref3_ind  
	
	PREPARE sb1_account FROM p_query_text 
	DECLARE cb1_account CURSOR FOR sb1_account 
 
	FOREACH cb1_account INTO l_rec_accountcur.* 
		LET l_rec_report.chart_code = l_rec_accountcur.chart_code 
		LET l_rec_report.acct_code = l_rec_accountcur.acct_code 
		LET l_rec_report.currency_code = l_rec_accountcur.currency_code 
		LET l_rec_report.open_amt = l_rec_accountcur.open_amt 
		LET l_rec_report.year_num = p_rec_period.year_num 
		LET l_rec_report.period_num = NULL 
		SELECT sum(debit_amt), 
		sum(credit_amt) 
		INTO l_rec_report.debit_amt, 
		l_rec_report.credit_amt 
		FROM accountledger 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND acct_code = l_rec_accountcur.acct_code 
		AND year_num = p_rec_period.year_num 
		AND currency_code = glob_rec_currency.currency_code 
		AND period_num <= p_rec_period.period_num 
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
		IF l_zero_ind = "N" 
		AND l_rec_report.open_amt = 0 
		AND l_rec_report.debit_amt = 0 
		AND l_rec_report.credit_amt = 0 
		AND l_rec_report.bal_amt = 0 THEN 
			CONTINUE FOREACH 
		ELSE 
			#---------------------------------------------------------
			OUTPUT TO REPORT GRG_rpt_list_B_curr(p_rpt_idx,l_rec_report.*,p_rec_period.*) 
			IF NOT rpt_int_flag_handler2("GL-Acccount:",l_rec_accountcur.acct_code, NULL,p_rpt_idx) THEN
				EXIT FOREACH 
			END IF 
			#---------------------------------------------------------
		END IF 
	END FOREACH 
	
	IF int_flag THEN
		MESSAGE "Report Generation Canceled..."
		RETURN FALSE
	ELSE
		RETURN TRUE
	END IF 	 
END FUNCTION 


############################################################
# FUNCTION GRG_rpt_process_b2()
#
#
############################################################
FUNCTION GRG_rpt_process_b2(p_rpt_idx,p_query_text,p_conv_qty,p_rec_period)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_query_text STRING
	DEFINE p_conv_qty LIKE rate_exchange.conv_sell_qty 
	DEFINE p_rec_period RECORD LIKE period.*
	DEFINE l_zero_ind CHAR(1) 	
	DEFINE l_rec_accountcur RECORD LIKE accountcur.* 
	DEFINE l_rec_report RECORD 
		chart_code LIKE accountcur.chart_code, 
		acct_code LIKE accountcur.acct_code, 
		currency_code LIKE accountcur.currency_code, 
		year_num LIKE period.year_num, 
		period_num LIKE period.period_num, 
		open_amt DECIMAL(16,2), 
		debit_amt DECIMAL(16,2), 
		credit_amt DECIMAL(16,2), 
		bal_amt DECIMAL(16,2) 
	END RECORD 
	DEFINE l_rept_curr_code LIKE currency.currency_code #base currency	
	DEFINE l_rec_currency RECORD LIKE currency.*
	
	LET p_rec_period.year_num	 = glob_arr_rec_rpt_rmsreps[p_rpt_idx].ref1_num
	LET p_rec_period.period_num = glob_arr_rec_rpt_rmsreps[p_rpt_idx].ref2_num		
	LET l_rept_curr_code	 = glob_arr_rec_rpt_rmsreps[p_rpt_idx].ref1_code	#can not follow why we have 2 currency codes
	LET l_rec_currency.currency_code = glob_arr_rec_rpt_rmsreps[p_rpt_idx].ref2_code #can not follow why we have 2 currency codes		
	LET l_zero_ind = glob_rec_rpt_selector.ref3_ind  
	
	PREPARE sb2_account FROM p_query_text 
	DECLARE cb2_account CURSOR FOR sb2_account 

	FOREACH cb2_account INTO l_rec_accountcur.* 
		LET l_rec_report.chart_code = l_rec_accountcur.chart_code 
		LET l_rec_report.acct_code = l_rec_accountcur.acct_code 
		LET l_rec_report.currency_code = l_rec_accountcur.currency_code 
		LET l_rec_report.year_num = p_rec_period.year_num 
		LET l_rec_report.open_amt = l_rec_accountcur.open_amt 
		LET l_rec_report.period_num = NULL 
		SELECT sum(debit_amt), 
		sum(credit_amt) 
		INTO l_rec_report.debit_amt, 
		l_rec_report.credit_amt 
		FROM accounthistcur 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND acct_code = l_rec_accountcur.acct_code 
		AND year_num = p_rec_period.year_num 
		AND currency_code = glob_rec_currency.currency_code 
		AND period_num <= p_rec_period.period_num 
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
		IF l_zero_ind = "N" 
		AND l_rec_report.open_amt = 0 
		AND l_rec_report.debit_amt = 0 
		AND l_rec_report.credit_amt = 0 
		AND l_rec_report.bal_amt = 0 THEN 
			CONTINUE FOREACH 
		ELSE 
			#---------------------------------------------------------
			OUTPUT TO REPORT GRG_rpt_list_B_curr(p_rpt_idx,l_rec_report.*,p_rec_period.*) 
			IF NOT rpt_int_flag_handler2("GL-Acccount:",l_rec_accountcur.acct_code, NULL,p_rpt_idx) THEN
				EXIT FOREACH 
			END IF 
			#---------------------------------------------------------
		END IF 
	END FOREACH 
	
	IF int_flag THEN
		MESSAGE "Report Generation Canceled..."
		RETURN FALSE
	ELSE
		RETURN TRUE
	END IF 	 
END FUNCTION 



############################################################
# FUNCTION GRG_rpt_process_b3()
#
#
############################################################
FUNCTION GRG_rpt_process_b3(p_rpt_idx,p_query_text,p_conv_qty,p_rec_period)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_query_text STRING
	DEFINE p_conv_qty LIKE rate_exchange.conv_sell_qty 
	DEFINE p_rec_period RECORD LIKE period.* 
	DEFINE l_zero_ind CHAR(1) 	
	DEFINE l_rec_accountcur RECORD LIKE accountcur.* 
	DEFINE l_temp_credit_amt DECIMAL(16,2) 
	DEFINE l_temp_debit_amt DECIMAL(16,2) 
	DEFINE l_rec_report RECORD 
		chart_code LIKE accountcur.chart_code, 
		acct_code LIKE accountcur.acct_code, 
		currency_code LIKE accountcur.currency_code, 
		year_num LIKE period.year_num, 
		period_num LIKE period.period_num, 
		open_amt DECIMAL(16,2), 
		debit_amt DECIMAL(16,2), 
		credit_amt DECIMAL(16,2), 
		bal_amt DECIMAL(16,2) 
	END RECORD 
	DEFINE l_rept_curr_code LIKE currency.currency_code #base currency	
	DEFINE l_rec_currency RECORD LIKE currency.*
	
	LET p_rec_period.year_num	 = glob_arr_rec_rpt_rmsreps[p_rpt_idx].ref1_num
	LET p_rec_period.period_num = glob_arr_rec_rpt_rmsreps[p_rpt_idx].ref2_num		
	LET l_rept_curr_code	 = glob_arr_rec_rpt_rmsreps[p_rpt_idx].ref1_code	#can not follow why we have 2 currency codes
	LET l_rec_currency.currency_code = glob_arr_rec_rpt_rmsreps[p_rpt_idx].ref2_code #can not follow why we have 2 currency codes		
	LET l_zero_ind = glob_rec_rpt_selector.ref3_ind  
	
	PREPARE sb3_account FROM p_query_text 
	DECLARE cb3_account CURSOR FOR sb3_account 

	FOREACH cb3_account INTO l_rec_accountcur.* 
		LET l_rec_report.chart_code = l_rec_accountcur.chart_code 
		LET l_rec_report.acct_code = l_rec_accountcur.acct_code 
		LET l_rec_report.currency_code = l_rec_accountcur.currency_code 
		LET l_rec_report.year_num = p_rec_period.year_num 
		LET l_rec_report.period_num = p_rec_period.period_num 
		SELECT sum(debit_amt), 
		sum(credit_amt) 
		INTO l_temp_debit_amt, 
		l_temp_credit_amt 
		FROM accountledger 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND acct_code = l_rec_accountcur.acct_code 
		AND currency_code = glob_rec_currency.currency_code 
		AND year_num = p_rec_period.year_num 
		AND period_num < p_rec_period.period_num 
		AND tran_type_ind != "CL" 
		LET l_rec_report.open_amt = l_rec_accountcur.open_amt 
		+ l_temp_debit_amt 
		- l_temp_credit_amt 
		SELECT sum(debit_amt), 
		sum(credit_amt) 
		INTO l_rec_report.debit_amt, 
		l_rec_report.credit_amt 
		FROM accountledger 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND acct_code = l_rec_accountcur.acct_code 
		AND currency_code = glob_rec_currency.currency_code 
		AND year_num = p_rec_period.year_num 
		AND period_num = p_rec_period.period_num 
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
		IF l_zero_ind = "N" 
		AND l_rec_report.open_amt = 0 
		AND l_rec_report.debit_amt = 0 
		AND l_rec_report.credit_amt = 0 
		AND l_rec_report.bal_amt = 0 THEN 
			CONTINUE FOREACH 
		ELSE 

			#---------------------------------------------------------
			OUTPUT TO REPORT GRG_rpt_list_B_curr(p_rpt_idx,l_rec_report.*,p_rec_period.*) 
			IF NOT rpt_int_flag_handler2("GL-Acccount:",l_rec_accountcur.acct_code, NULL,p_rpt_idx) THEN
				EXIT FOREACH 
			END IF 
			#---------------------------------------------------------

		END IF 
	END FOREACH 
	
	IF int_flag THEN
		MESSAGE "Report Generation Canceled..."
		RETURN FALSE
	ELSE
		RETURN TRUE
	END IF 	 
END FUNCTION 



############################################################
# FUNCTION GRG_rpt_process_b4()
#
#
############################################################
FUNCTION GRG_rpt_process_b4(p_rpt_idx,p_query_text,p_conv_qty,p_rec_period)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_query_text STRING
	DEFINE p_conv_qty LIKE rate_exchange.conv_sell_qty 
	DEFINE p_rec_period RECORD LIKE period.* 
	DEFINE l_zero_ind CHAR(1) 	
	DEFINE l_rec_accountcur RECORD LIKE accountcur.* 
	DEFINE l_rec_report RECORD 
		chart_code LIKE accountcur.chart_code, 
		acct_code LIKE accountcur.acct_code, 
		currency_code LIKE accountcur.currency_code, 
		year_num LIKE period.year_num, 
		period_num LIKE period.period_num, 
		open_amt DECIMAL(16,2), 
		debit_amt DECIMAL(16,2), 
		credit_amt DECIMAL(16,2), 
		bal_amt DECIMAL(16,2) 
	END RECORD 
	DEFINE l_rept_curr_code LIKE currency.currency_code #base currency	
	DEFINE l_rec_currency RECORD LIKE currency.*
	
	LET p_rec_period.year_num	 = glob_arr_rec_rpt_rmsreps[p_rpt_idx].ref1_num
	LET p_rec_period.period_num = glob_arr_rec_rpt_rmsreps[p_rpt_idx].ref2_num		
	LET l_rept_curr_code	 = glob_arr_rec_rpt_rmsreps[p_rpt_idx].ref1_code	#can not follow why we have 2 currency codes
	LET l_rec_currency.currency_code = glob_arr_rec_rpt_rmsreps[p_rpt_idx].ref2_code #can not follow why we have 2 currency codes		
	LET l_zero_ind = glob_rec_rpt_selector.ref3_ind  
	
	PREPARE sb4_account FROM p_query_text 
	DECLARE cb4_account CURSOR FOR sb4_account 

	FOREACH cb4_account INTO l_rec_accountcur.* 
		LET l_rec_report.chart_code = l_rec_accountcur.chart_code 
		LET l_rec_report.acct_code = l_rec_accountcur.acct_code 
		LET l_rec_report.currency_code = l_rec_accountcur.currency_code 
		LET l_rec_report.year_num = l_rec_accountcur.year_num 
		LET l_rec_report.period_num = p_rec_period.period_num 
		SELECT open_amt, 
		debit_amt, 
		credit_amt 
		INTO l_rec_report.open_amt, 
		l_rec_report.debit_amt, 
		l_rec_report.credit_amt 
		FROM accounthistcur 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND acct_code = l_rec_report.acct_code 
		AND currency_code = glob_rec_currency.currency_code 
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
		IF l_zero_ind = "N" 
		AND l_rec_report.open_amt = 0 
		AND l_rec_report.debit_amt = 0 
		AND l_rec_report.credit_amt = 0 
		AND l_rec_report.bal_amt = 0 THEN 
			CONTINUE FOREACH 
		ELSE 
			#---------------------------------------------------------
			OUTPUT TO REPORT GRG_rpt_list_B_curr(p_rpt_idx,l_rec_report.*,p_rec_period.*) 
			IF NOT rpt_int_flag_handler2("GL-Acccount:",l_rec_accountcur.acct_code, NULL,p_rpt_idx) THEN
				EXIT FOREACH 
			END IF 
			#---------------------------------------------------------
		END IF 
	END FOREACH 
	
	IF int_flag THEN
		MESSAGE "Report Generation Canceled..."
		RETURN FALSE
	ELSE
		RETURN TRUE
	END IF 	 
END FUNCTION 



############################################################
# REPORT GRG_rpt_list_B_curr(p_rec_report)
#
#
############################################################
REPORT GRG_rpt_list_B_curr(p_rpt_idx,p_rec_report,p_rec_period) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_report RECORD 
		chart_code LIKE accountcur.chart_code, 
		acct_code LIKE accountcur.acct_code, 
		currency_code LIKE accountcur.currency_code, 
		year_num LIKE period.year_num, 
		period_num LIKE period.period_num, 
		open_amt DECIMAL(16,2), 
		debit_amt DECIMAL(16,2), 
		credit_amt DECIMAL(16,2), 
		bal_amt DECIMAL(16,2) 
	END RECORD 
	DEFINE p_rec_period RECORD LIKE period.*
	DEFINE l_todate_head CHAR(14) 
	DEFINE p_rec_period_head CHAR(6) 
	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_open_tot CHAR(20) 
	DEFINE l_bal_tot CHAR(20) 
	DEFINE l_offset1 SMALLINT 
	DEFINE l_offset2 SMALLINT 
	DEFINE l_offset3 SMALLINT 
	DEFINE l_line1 CHAR(130) 
	DEFINE l_line2 CHAR(130) 

	OUTPUT 
	left margin 0 
	ORDER BY p_rec_report.chart_code 
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2]
			PRINT COLUMN 01, "Values in Currency: ", p_rec_report.currency_code 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			
{		
			LET l_line1 = today clipped,10 spaces, glob_rec_company.cmpy_code, 
			2 spaces,glob_rec_company.name_text clipped,10 spaces, 
			"Page :",pageno USING "####" 
			IF glob_totals_ind = "Y" THEN 
				LET l_todate_head = "Year TO Date" 
				LET p_rec_period_head = NULL 
			ELSE 
				LET l_todate_head = "Period TO Date" 
				LET p_rec_period_head = "Period" 
			END IF 
			LET l_line2 = glob_rpt_note clipped," (Menu - GRG)" 
			LET l_offset1 = (glob_rpt_width - length(l_line1))/2 
			LET l_offset2 = (glob_rpt_width - length(l_line2))/2 
			LET l_offset3 = l_offset2 + length(l_line2) + 10 
			PRINT COLUMN l_offset1, l_line1 clipped 
			PRINT COLUMN l_offset2, l_line2 clipped, 
			COLUMN l_offset3, "Values in Currency: ", p_rec_report.currency_code 
			PRINT COLUMN 01,"--------------------------------------------", 
			"--------------------------------------------", 
			"--------------------------------------------" 
}	
		PRINT COLUMN 01, "Account", 
			COLUMN 40, "Year", 
			COLUMN 45, p_rec_period_head, 
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

		ON LAST ROW 
			NEED 12 LINES 
			SKIP 1 line 
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
				PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 
				PRINT COLUMN 25, "YTD/PTD - ", glob_arr_rec_rpt_rmsreps[p_rpt_idx].ref2_ind 
				PRINT COLUMN 25, "Actuals/Preclose - ", glob_arr_rec_rpt_rmsreps[p_rpt_idx].ref1_ind 
				PRINT COLUMN 25, "Print zero a/cs - ", glob_rec_rpt_selector.ref3_ind  #	l_zero_ind  
				PRINT COLUMN 25, "Year/period - ", p_rec_period.year_num, "/", 
				p_rec_period.period_num USING "<<<<<" 
				PRINT COLUMN 25, "Currency code - ", glob_arr_rec_rpt_rmsreps[p_rpt_idx].ref2_code
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 

{			
			PRINT COLUMN 50," ***** END OF REPORT GRG ***** " 
			SKIP 2 LINES 
			
			PRINT COLUMN 1, "Selection Criteria - ", 
			COLUMN 25, "YTD/PTD - ", glob_timing_ind 
			PRINT COLUMN 25, "Actuals/Preclose - ", glob_totals_ind 
			PRINT COLUMN 25, "Print zero a/cs - ", glob_zero_ind 
			PRINT COLUMN 25, "Year/period - ", p_rec_period.year_num, "/", 
			p_rec_period.period_num USING "<<<<<" 
			PRINT COLUMN 25, "Currency code - ", glob_rec_currency.currency_code 
			PRINT COLUMN 5, glob_where_text[1,100] 
			PRINT COLUMN 5, glob_where_text[101,200] 
			LET glob_rec_rmsreps.page_num = pageno 
}
END REPORT 
