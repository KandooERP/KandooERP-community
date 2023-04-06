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

############################################################
# FUNCTION check_funds(p_cmpy_code, p_acct_code, p_tran_amt, p_line_num, p_year_num, p_period_num, p_module, p_ref_num, p_verbose_ind)
# Description: This FUNCTION checks the funds available FOR a particular
#              account.
# Passed:      account code
#              transaction amount
#              line number
#              year number
#              period number
#              module             - R = Purchasing, P = Payables, G = G/Ledger
#              reference number   - Purchase ORDER, voucher OR journal number.
#              verbose indicator  - TO DISPLAY error MESSAGEs OR NOT (Y/N).
# Returns:     valid transaction
#              available funds
#
# Note:        After RETURN, need TO re-DISPLAY kandoomsg.
############################################################
FUNCTION check_funds(p_cmpy_code, p_acct_code, p_tran_amt, p_line_num, p_year_num, p_period_num, p_module, p_ref_num, p_verbose_ind) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_acct_code LIKE coa.acct_code 
	DEFINE p_tran_amt LIKE poaudit.line_total_amt 
	DEFINE p_line_num LIKE purchdetl.line_num 
	DEFINE p_year_num LIKE purchhead.year_num 
	DEFINE p_period_num LIKE purchhead.period_num 
	DEFINE p_module LIKE language.yes_flag 
	DEFINE p_ref_num LIKE purchhead.order_num 
	DEFINE p_verbose_ind LIKE language.yes_flag 
	DEFINE l_funds_consumed LIKE fundsapproved.limit_amt 
	DEFINE l_exceeded_amt LIKE fundsapproved.limit_amt 
	DEFINE l_deduct_amt LIKE poaudit.line_total_amt 
	DEFINE l_add_amt LIKE poaudit.line_total_amt 
	DEFINE l_temp_text CHAR(30) 
	DEFINE l_query_text STRING 
	DEFINE l_rec_fundsapproved RECORD LIKE fundsapproved.* 
	DEFINE l_rec_poaudit RECORD LIKE poaudit.* 

	IF p_acct_code IS NULL THEN 
		IF p_verbose_ind = "Y" THEN 
			ERROR kandoomsg2("U",7039,"Account Code does NOT exist.")	#7039 Logic Error: Account Code does NOT exist.
		END IF 
		RETURN FALSE, 0 
	END IF 

	SELECT * INTO l_rec_fundsapproved.* FROM fundsapproved 
	WHERE cmpy_code = p_cmpy_code 
	AND acct_code = p_acct_code 
	IF status = notfound THEN 
		RETURN TRUE, "" 
	END IF 
	
	IF l_rec_fundsapproved.active_flag = "N" THEN 
		IF p_verbose_ind = "Y" THEN 
			ERROR kandoomsg2("U",9937,"")	#9937 The capital account IS currently NOT active;  Refer Menu GZ1.
		END IF 
		RETURN FALSE, 0 
	END IF 

	IF p_module = "G" AND p_ref_num IS NOT NULL THEN 
		SELECT unique(1) FROM batchhead 
		WHERE cmpy_code = p_cmpy_code 
		AND (batchhead.source_ind = 'P' 
		OR batchhead.source_ind = 'R') 
		AND batchhead.jour_num = p_ref_num 
		IF status != notfound THEN 
			IF p_verbose_ind = "Y" THEN 
				ERROR kandoomsg2("G",9603,"")		#9603 Cannot edit capital line.
			END IF 
			RETURN FALSE, 0 
		END IF 
	END IF 
	
	IF p_verbose_ind = "Y" THEN 
		ERROR kandoomsg2("U",1533,"")	#1533 Checking available funds;  Please wait.
	END IF 

	CASE 
		WHEN l_rec_fundsapproved.fund_type_ind = "CAP" 
			EXIT CASE 

		WHEN l_rec_fundsapproved.fund_type_ind[3] = "P" 
			CALL period_funds(p_cmpy_code, p_acct_code, p_year_num,		p_period_num, l_rec_fundsapproved.fund_type_ind) 
			RETURNING l_rec_fundsapproved.limit_amt 

			IF l_rec_fundsapproved.limit_amt IS NULL THEN 
				IF p_verbose_ind = "Y" THEN 
					LET l_temp_text = p_year_num USING "<<<<","/",p_period_num USING "<<<" 
					ERROR kandoomsg2("G",9606,l_temp_text)		#9606 Budget period XXXX/XXX has NOT been setup FOR account;
					#     Refer Menu G15.
				END IF 
				
				RETURN FALSE, 0 
			END IF 

		WHEN l_rec_fundsapproved.fund_type_ind[3] = "Y" 
			CALL year_funds(p_cmpy_code, p_acct_code, p_year_num,	l_rec_fundsapproved.fund_type_ind) 
			RETURNING l_rec_fundsapproved.limit_amt 
			IF l_rec_fundsapproved.limit_amt IS NULL THEN 
				IF p_verbose_ind = "Y" THEN 
					LET l_temp_text = p_year_num USING "<<<<","/",p_period_num USING "<<<" 
					ERROR kandoomsg2("G",9607,l_temp_text) 		#9607 Budget year XXXX has NOT been setup FOR account;   Refer Menu G15.
				END IF
				 
				RETURN FALSE, 0 
			END IF 

		WHEN l_rec_fundsapproved.fund_type_ind[3] = "T" 
			CALL year_to_date_funds(p_cmpy_code, p_acct_code, p_year_num,	p_period_num, l_rec_fundsapproved.fund_type_ind) 
			RETURNING l_rec_fundsapproved.limit_amt 
			
			IF l_rec_fundsapproved.limit_amt IS NULL THEN 
				IF p_verbose_ind = "Y" THEN 
					LET l_temp_text = p_year_num USING "<<<<","/",p_period_num USING "<<<" 
					ERROR kandoomsg2("G",9606,l_temp_text)		#9606 Budget period XXXX/XXX has NOT been setup FOR account;#     Refer Menu G15.
				END IF
				 
				RETURN FALSE, 0 
			END IF 
			
		OTHERWISE 
			IF p_verbose_ind = "Y" THEN 
				ERROR kandoomsg2("U",7039,"Funds type indicator does NOT exist.")	#7039 Logic Error: Funds type indicator does NOT exist.
			END IF 
			RETURN FALSE, 0 

	END CASE 

	LET l_funds_consumed = 0 
	LET l_exceeded_amt = 0 

	# SELECT Purchase Order using Account
	LET l_query_text = 
		"SELECT order_num, line_num ", 
		"FROM purchdetl ", 
		"WHERE cmpy_code = '",p_cmpy_code,"' ", 
		"AND acct_code = '",p_acct_code,"'" 

	IF p_module = "R"	AND p_ref_num IS NOT NULL THEN 
		LET l_query_text = 
			l_query_text clipped, " ", 
			"AND order_num != '",p_ref_num,"'" 
	END IF 
	
	PREPARE s_purchdetl FROM l_query_text 
	DECLARE c_purchdetl CURSOR FOR s_purchdetl 
	
	FOREACH c_purchdetl INTO l_rec_poaudit.po_num, l_rec_poaudit.line_num 
		CALL po_info(p_cmpy_code, l_rec_poaudit.po_num, l_rec_poaudit.line_num,	p_year_num, p_period_num, l_rec_fundsapproved.fund_type_ind) 
		RETURNING l_rec_poaudit.line_total_amt 
		
		LET l_funds_consumed = l_funds_consumed	+ l_rec_poaudit.line_total_amt 
	END FOREACH 

	# SELECT Purchase Order using account FROM temp table
	IF p_module = "R" THEN 
		LET l_query_text = 
			"SELECT sum(line_total_amt) ", 
			"FROM t_poaudit, t_purchdetl ", 
			"WHERE t_poaudit.line_num = t_purchdetl.line_num ", 
			"AND t_poaudit.line_num != '",p_line_num,"' ", 
			"AND t_purchdetl.acct_code = '",p_acct_code,"'" 

		CASE 
			WHEN l_rec_fundsapproved.fund_type_ind = "CAP" 
				EXIT CASE 

			WHEN l_rec_fundsapproved.fund_type_ind[3] = "P" 
				LET l_query_text = 
					l_query_text clipped, 
					"AND t_poaudit.year_num = '",p_year_num,"' ", 
					"AND t_poaudit.period_num = '",p_period_num,"'" 

			WHEN l_rec_fundsapproved.fund_type_ind[3] = "Y" 
				LET l_query_text = 
					l_query_text clipped, 
					"AND t_poaudit.year_num = '",p_year_num,"'" 

			WHEN l_rec_fundsapproved.fund_type_ind[3] = "T" 
				LET l_query_text = 
					l_query_text clipped, 
					"AND t_poaudit.year_num = '",p_year_num,"' ", 
					"AND t_poaudit.period_num <= '",p_period_num,"'" 

		END CASE 
		
		PREPARE s_tmp_purchdetl FROM l_query_text 
		DECLARE c_tmp_purchdetl CURSOR FOR s_tmp_purchdetl 
		OPEN c_tmp_purchdetl 
		FETCH c_tmp_purchdetl INTO l_deduct_amt 
		IF status = notfound	OR l_deduct_amt IS NULL THEN 
			LET l_deduct_amt = 0 
		END IF 
		
		LET l_funds_consumed = l_funds_consumed	+ l_deduct_amt	+ p_tran_amt 
	END IF 

	# SELECT Vouchers using account
	LET l_query_text = 
		"SELECT sum(voucherdist.dist_amt) ", 
		"FROM voucherdist, voucher ", 
		"WHERE voucherdist.cmpy_code = '",p_cmpy_code,"' ", 
		"AND voucher.cmpy_code = voucherdist.cmpy_code ", 
		"AND voucher.vouch_code = voucherdist.vouch_code ", 
		"AND acct_code = '",p_acct_code,"'" 
	IF p_module = "P"	AND p_ref_num IS NOT NULL THEN 
		LET l_query_text = 
			l_query_text clipped, " ", 
			"AND voucher.vouch_code != '",p_ref_num,"'" 
	END IF 

	CASE 
		WHEN l_rec_fundsapproved.fund_type_ind = "CAP" 
			EXIT CASE 

		WHEN l_rec_fundsapproved.fund_type_ind[3] = "P" #period 
			LET l_query_text = 
				l_query_text clipped, 
				"AND year_num = '",p_year_num,"' ", 
				"AND period_num = '",p_period_num,"'" 

		WHEN l_rec_fundsapproved.fund_type_ind[3] = "Y" #year 
			LET l_query_text = 
				l_query_text clipped, 
				"AND year_num = '",p_year_num,"'" 

		WHEN l_rec_fundsapproved.fund_type_ind[3] = "T" #year TO DATE 
			LET l_query_text = 
				l_query_text clipped, 
				"AND year_num = '",p_year_num,"' ", 
				"AND period_num <= '",p_period_num,"'" 

		END CASE 
	
	PREPARE s_voucherdist FROM l_query_text 
	DECLARE c_voucherdist CURSOR FOR s_voucherdist 
	OPEN c_voucherdist 
	FETCH c_voucherdist INTO l_deduct_amt 
	IF status = notfound OR l_deduct_amt IS NULL THEN 
		LET l_deduct_amt = 0 
	END IF 
	LET l_funds_consumed = l_funds_consumed	+ l_deduct_amt 

	# SELECT Vouchers using account FROM temp table
	IF p_module = "P" THEN 
		SELECT sum(dist_amt) INTO l_deduct_amt 
		FROM t_voucherdist 
		WHERE acct_code = p_acct_code 
		AND line_num != p_line_num 
		
		IF l_deduct_amt IS NULL THEN 
			LET l_deduct_amt = 0 
		END IF 
		
		LET l_funds_consumed = l_funds_consumed	+ l_deduct_amt+ p_tran_amt 
	END IF 

	# SELECT Journal Batches using account
	# Note : This process IS reducing debit amount by credit amount FOR CAPITAL
	#        items.
	IF l_rec_fundsapproved.fund_type_ind = "CAP" THEN 
		LET l_query_text = 
			"SELECT sum(batchdetl.for_debit_amt) - sum(batchdetl.for_credit_amt)", 
			"FROM batchhead, batchdetl ", 
			"WHERE batchhead.cmpy_code = '",p_cmpy_code,"' ", 
			"AND batchdetl.cmpy_code = '",p_cmpy_code,"' ", 
			"AND batchhead.jour_num = batchdetl.jour_num ", 
			"AND batchdetl.acct_code = '",p_acct_code,"' ", 
			"AND (batchhead.source_ind != 'P' ", 
			"AND batchhead.source_ind != 'R')" 

		IF p_module = "G" AND p_ref_num IS NOT NULL THEN 
			LET l_query_text = l_query_text clipped, 
				"AND batchhead.jour_num != '",p_ref_num,"'" 
		END IF 
		
		PREPARE s_batchamt FROM l_query_text 
		DECLARE c_batchamt CURSOR FOR s_batchamt 
		OPEN c_batchamt 
		FETCH c_batchamt INTO l_deduct_amt 
		IF status = notfound OR l_deduct_amt IS NULL THEN 
			LET l_deduct_amt = 0 
		END IF 
		
		LET l_funds_consumed = l_funds_consumed	+ l_deduct_amt 

		# SELECT Journal Batches using account FROM temp table
		# Note : This process IS reducing debit value by credit value.
		IF p_module = "G" THEN 
			SELECT sum(for_debit_amt) - sum(for_credit_amt) INTO l_deduct_amt 
			FROM t_batchdetl 
			WHERE acct_code = p_acct_code 
			AND seq_num != p_line_num 
			IF status = notfound OR l_deduct_amt IS NULL THEN 
				LET l_deduct_amt = 0 
			END IF 
			
			LET l_funds_consumed = l_funds_consumed	+ l_deduct_amt + p_tran_amt 
		END IF 
	END IF 

	# Reduce by any AP debits distributed TO account
	LET l_query_text = 
		"SELECT sum(debitdist.dist_amt) ", 
		"FROM debitdist, debithead ", 
		"WHERE debithead.cmpy_code = '",p_cmpy_code,"' ", 
		"AND debitdist.cmpy_code = '",p_cmpy_code,"' ", 
		"AND debitdist.debit_code = debithead.debit_num ", 
		"AND debitdist.acct_code = '",p_acct_code,"'" 

	CASE 
		WHEN l_rec_fundsapproved.fund_type_ind = "CAP" 
			EXIT CASE 

		WHEN l_rec_fundsapproved.fund_type_ind[3] = "P" #period 
			LET l_query_text = l_query_text clipped, 
				"AND year_num = '",p_year_num,"' ", 
				"AND period_num = '",p_period_num,"'" 

		WHEN l_rec_fundsapproved.fund_type_ind[3] = "Y" #year 
			LET l_query_text = l_query_text clipped, 
				"AND year_num = '",p_year_num,"'" 

		WHEN l_rec_fundsapproved.fund_type_ind[3] = "T" #year TO DATE 
			LET l_query_text = l_query_text clipped, 
				"AND year_num = '",p_year_num,"' ", 
				"AND period_num <= '",p_period_num,"'" 
	END CASE 

	PREPARE s_debitdist FROM l_query_text 
	DECLARE c_debitdist CURSOR FOR s_debitdist 
	OPEN c_debitdist 
	FETCH c_debitdist INTO l_add_amt
	 
	IF status = notfound OR l_add_amt IS NULL THEN 
		LET l_add_amt = 0 
	END IF 
	
	LET l_funds_consumed = l_funds_consumed - l_add_amt 

	LET l_exceeded_amt = l_rec_fundsapproved.limit_amt - l_funds_consumed 
	IF l_exceeded_amt < 0 THEN 
		# Convert the exceeded amount IF the available amount IS TO be displayed
		# i.e. G11, G14
		IF (p_module IS NOT NULL AND p_ref_num IS NOT null)	OR p_verbose_ind = "Y" THEN 
			LET l_exceeded_amt = l_exceeded_amt * -1 
		END IF 

		IF p_verbose_ind = "Y" THEN 
			ERROR kandoomsg2("U",9936,l_exceeded_amt)			#9936 The available funds FOR the capital account IS exceeded by ...
			LET l_exceeded_amt = 0 
		ELSE 
			IF p_verbose_ind = "N" THEN 
				LET l_exceeded_amt = 0 
			END IF 
		END IF 
		RETURN FALSE, l_exceeded_amt 
	END IF 

	RETURN TRUE, l_exceeded_amt 
END FUNCTION 
############################################################
# END FUNCTION check_funds(p_cmpy_code, p_acct_code, p_tran_amt, p_line_num, p_year_num, p_period_num, p_module, p_ref_num, p_verbose_ind)
############################################################


############################################################
# FUNCTION period_funds(p_cmpy_code, p_acct_code, p_year_num, p_period_num,p_fund_type_ind)
#
# Description: This FUNCTION gets the funds available (limit) FOR a given
#              period in a particular year. The remaining funds do NOT
#              carry forward TO the next period(s).
############################################################
FUNCTION period_funds(p_cmpy_code, p_acct_code, p_year_num, p_period_num,p_fund_type_ind) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_acct_code LIKE fundsapproved.acct_code 
	DEFINE p_year_num LIKE purchhead.year_num 
	DEFINE p_period_num LIKE purchhead.period_num 
	DEFINE p_fund_type_ind LIKE fundsapproved.fund_type_ind 
	DEFINE l_limit_amt LIKE fundsapproved.limit_amt 
	DEFINE l_query_text CHAR(2200) 

	CASE p_fund_type_ind 
		WHEN "P1P" 
			LET l_query_text = "SELECT budg1_amt" 
		WHEN "P2P" 
			LET l_query_text = "SELECT budg2_amt" 
		WHEN "P3P" 
			LET l_query_text = "SELECT budg3_amt" 
		WHEN "P4P" 
			LET l_query_text = "SELECT budg4_amt" 
		WHEN "P5P" 
			LET l_query_text = "SELECT budg5_amt" 
		OTHERWISE 
			LET l_query_text = "SELECT budg6_amt" 
	END CASE 

	LET l_query_text = 
		l_query_text clipped, 
		" FROM accounthist ", 
		"WHERE acct_code = '",p_acct_code,"' ", 
		"AND year_num = '",p_year_num,"' ", 
		"AND period_num = '",p_period_num,"' ", 
		"AND cmpy_code = '",p_cmpy_code,"'" 

	PREPARE s_limit_amt FROM l_query_text 
	DECLARE c_limit_amt CURSOR FOR s_limit_amt 

	OPEN c_limit_amt 
	FETCH c_limit_amt INTO l_limit_amt 

	IF status = notfound THEN 
		RETURN "" 
	END IF 

	RETURN l_limit_amt 
END FUNCTION 
############################################################
# END FUNCTION period_funds(p_cmpy_code, p_acct_code, p_year_num, p_period_num,p_fund_type_ind)
############################################################


############################################################
# FUNCTION year_funds(p_cmpy_code, p_acct_code, p_year_num, p_fund_type_ind)
#
# FUNCTION: year_funds
# Description: This FUNCTION gets the funds available (limit) FOR a given
#              year.  The full annual budget IS available.
############################################################
FUNCTION year_funds(p_cmpy_code, p_acct_code, p_year_num, p_fund_type_ind) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_acct_code LIKE fundsapproved.acct_code 
	DEFINE p_year_num LIKE purchhead.year_num 
	DEFINE p_fund_type_ind LIKE fundsapproved.fund_type_ind 
	DEFINE l_ret_limit_amt LIKE fundsapproved.limit_amt 
	DEFINE l_query_text STRING

	CASE p_fund_type_ind 
		WHEN "P1Y" 
			LET l_query_text = "SELECT budg1_amt" 
		WHEN "P2Y" 
			LET l_query_text = "SELECT budg2_amt" 
		WHEN "P3Y" 
			LET l_query_text = "SELECT budg3_amt" 
		WHEN "P4Y" 
			LET l_query_text = "SELECT budg4_amt" 
		WHEN "P5Y" 
			LET l_query_text = "SELECT budg5_amt" 
		OTHERWISE 
			LET l_query_text = "SELECT budg6_amt" 
	END CASE 

	LET l_query_text = 
		l_query_text clipped, 
		" FROM account ", 
		"WHERE acct_code = '",p_acct_code,"' ", 
		"AND year_num = '",p_year_num,"' ", 
		"AND cmpy_code = '",p_cmpy_code,"'" 

	PREPARE s_limit_amt2 FROM l_query_text 
	DECLARE c_limit_amt2 CURSOR FOR s_limit_amt2 

	OPEN c_limit_amt2 
	FETCH c_limit_amt2 INTO l_ret_limit_amt 
	IF status = notfound THEN 
		RETURN "" 
	END IF 

	RETURN l_ret_limit_amt 
END FUNCTION 
############################################################
# END FUNCTION year_funds(p_cmpy_code, p_acct_code, p_year_num, p_fund_type_ind)
############################################################


############################################################
# FUNCTION year_to_date_funds(p_cmpy_code, p_acct_code, p_year_num, p_period_num, p_fund_type_ind)
#
# Description: This FUNCTION gets the funds available (limit) up TO a given
#              period in a particular year. Any unused funds carry forward
#              TO future periods within the fiscal year.
############################################################
FUNCTION year_to_date_funds(p_cmpy_code, p_acct_code, p_year_num, p_period_num, p_fund_type_ind) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_acct_code LIKE fundsapproved.acct_code 
	DEFINE p_year_num LIKE purchhead.year_num 
	DEFINE p_period_num LIKE purchhead.period_num 
	DEFINE p_fund_type_ind LIKE fundsapproved.fund_type_ind 
	DEFINE l_query_text STRING
	DEFINE r_limit_amt LIKE fundsapproved.limit_amt 

	CASE p_fund_type_ind 
		WHEN "P1T" 
			LET l_query_text = "SELECT sum(budg1_amt)" 
		WHEN "P2T" 
			LET l_query_text = "SELECT sum(budg2_amt)" 
		WHEN "P3T" 
			LET l_query_text = "SELECT sum(budg3_amt)" 
		WHEN "P4T" 
			LET l_query_text = "SELECT sum(budg4_amt)" 
		WHEN "P5T" 
			LET l_query_text = "SELECT sum(budg5_amt)" 
		OTHERWISE 
			LET l_query_text = "SELECT sum(budg6_amt)" 
	END CASE 

	LET l_query_text = 
		l_query_text clipped, 
		" FROM accounthist ", 
		"WHERE acct_code = '",p_acct_code,"' ", 
		"AND year_num = '",p_year_num,"' ", 
		"AND period_num <= '",p_period_num,"' ", 
		"AND cmpy_code = '",p_cmpy_code,"'" 

	PREPARE s_limit_amt3 FROM l_query_text 
	DECLARE c_limit_amt3 CURSOR FOR s_limit_amt3 
	OPEN c_limit_amt3 
	FETCH c_limit_amt3 INTO r_limit_amt 
	IF status = notfound THEN 
		RETURN "" 
	END IF 

	RETURN r_limit_amt 
END FUNCTION 
############################################################
# END FUNCTION year_to_date_funds(p_cmpy_code, p_acct_code, p_year_num, p_period_num, p_fund_type_ind)
############################################################


############################################################
# FUNCTION po_info(p_cmpy_code, p_order_num, p_line_num, p_year_num,p_period_num, p_fund_type_ind)
#
# Description: This FUNCTION IS a based on po_line_info (postwind)
#              AND gets the purchase ORDER line details FROM the
#              poaudit table.
############################################################
FUNCTION po_info(p_cmpy_code, p_order_num, p_line_num, p_year_num,p_period_num, p_fund_type_ind) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_order_num LIKE purchhead.order_num 
	DEFINE p_line_num LIKE purchdetl.line_num 
	DEFINE p_year_num LIKE poaudit.year_num 
	DEFINE p_period_num LIKE poaudit.period_num 
	DEFINE p_fund_type_ind LIKE fundsapproved.fund_type_ind 
	DEFINE l_query_text CHAR(2200) 
	DEFINE r_line_total_amt LIKE poaudit.line_total_amt 

	LET r_line_total_amt = 0 

	LET l_query_text = 
		"SELECT sum(line_total_amt) ", 
		"FROM poaudit ", 
		"WHERE cmpy_code = '",p_cmpy_code,"' ", 
		"AND po_num = '",p_order_num,"' ", 
		"AND line_num = '",p_line_num,"' ", 
		"AND order_qty != 0 ", 
		"AND tran_code in ('CQ','AL','AA','CP')"
	 
	# Ignore "CE" - Closing reconciliation entries only
	CASE 
		WHEN p_fund_type_ind = "CAP" 
			EXIT CASE 
		WHEN p_fund_type_ind[3] = "P" #period 
			LET l_query_text = 
				l_query_text clipped, 
				" AND year_num = '",p_year_num,"' ", 
				"AND period_num = '",p_period_num,"'" 
		WHEN p_fund_type_ind[3] = "Y" #year 
			LET l_query_text = 
				l_query_text clipped, 
				" AND year_num = '",p_year_num,"'" 
		WHEN p_fund_type_ind[3] = "T" #year TO DATE 
			LET l_query_text = 
				l_query_text clipped, 
				" AND year_num = '",p_year_num,"' ", 
				"AND period_num <= '",p_period_num,"'" 
	END CASE 

	PREPARE s_poaudit FROM l_query_text 
	DECLARE c_poaudit CURSOR FOR s_poaudit 
	OPEN c_poaudit 
	FETCH c_poaudit INTO r_line_total_amt 
	IF status = notfound OR r_line_total_amt IS NULL THEN 
		LET r_line_total_amt = 0 
	END IF 

	RETURN r_line_total_amt 
END FUNCTION 
############################################################
# END FUNCTION po_info(p_cmpy_code, p_order_num, p_line_num, p_year_num,p_period_num, p_fund_type_ind)
############################################################