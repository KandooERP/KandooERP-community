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
GLOBALS "../gw/T_GW_GLOBALS.4gl" 
GLOBALS "../gw/TGW1_GLOBALS.4gl" 


############################################################
# FUNCTION colitem_amt(p_line_uid)
#
# FUNCTION:        COLUMN item amount
# Description:     FUNCTION TO FETCH AND RETURN COLUMN item amount
#                   defined by the user.
############################################################
FUNCTION colitem_amt(p_line_uid) 
	DEFINE p_line_uid LIKE rptline.line_uid 
	DEFINE l_curr_type LIKE rptcol.curr_type 
	DEFINE l_seq_num LIKE colitem.seq_num 
	DEFINE l_operator LIKE colitem.item_operator 
	DEFINE l_item_type LIKE mrwitem.item_type 
	DEFINE l_fmt_amt LIKE rptcoldesc.col_desc 
	DEFINE l_col_id LIKE rptcol.col_id 
	DEFINE l_col_amt DECIMAL(18,2) 
	DEFINE l_col_amt2 DECIMAL(18,2) 
	DEFINE l_col_total DECIMAL(18,2) 
	DEFINE l_col_total2 DECIMAL(18,2) 
	DEFINE l_status SMALLINT 
	DEFINE l_wksht_idx SMALLINT 
	DEFINE l_curr_type2 LIKE rptcol.curr_type 
	DEFINE l_item_cnt SMALLINT 
	DEFINE l_idx SMALLINT 



	LET l_col_total = 0 
	LET l_col_total2 = 0 
	LET l_status = 0 
	LET l_idx = 0 

	#Print worksheet totals
	IF gv_wksht_tots THEN 
		CALL get_col_accum() 
		RETURNING l_col_total, 
		l_fmt_amt, 
		l_status 
		RETURN l_col_total, l_fmt_amt, l_status 
	END IF 

	##l_item_cnt IS used TO find out IF there IS the END of COLUMN items
	##proccessing. Only AT the END of the COLUMN, WHEN all items are processed
	##the COLUMN total have TO be added TO the accumulator.

	SELECT count(*) 
	INTO l_item_cnt 
	FROM colitem, mrwitem 
	WHERE colitem.col_uid = gr_rptcol.col_uid 
	AND mrwitem.item_id = colitem.col_item 


	#Retrieve all COLUMN item details FOR calculation.
	DECLARE colitem_curs CURSOR FOR 
	SELECT colitem.seq_num, 
	colitem.item_operator, 
	mrwitem.item_type 
	FROM colitem, mrwitem 
	WHERE colitem.col_uid = gr_rptcol.col_uid 
	AND mrwitem.item_id = colitem.col_item 

	FOREACH colitem_curs INTO l_seq_num, l_operator, l_item_type 
		LET l_col_amt = 0 
		LET l_idx = l_idx + 1 
		CASE 
			WHEN l_item_type = gr_mrwparms.column_item_type 
				LET l_col_amt = fetch_column_amt(l_seq_num) 
				LET l_col_total = operator_calc(l_col_amt, 
				l_col_total, 
				l_operator) 
				IF l_idx = l_item_cnt THEN ##11194 vjk 
					IF gr_rptline.accum_id THEN 
						CALL updt_accum(gr_rptcol.col_uid, 
						l_col_total, 
						gv_col_curr_type, 
						1) 
					END IF 
				END IF 

			WHEN l_item_type = gr_mrwparms.value_item_type 
				LET l_col_amt = fetch_value_amt(l_seq_num) 
				LET l_col_total = operator_calc(l_col_amt, 
				l_col_total, 
				l_operator) 
				IF gr_rptline.accum_id THEN 
					IF l_idx = l_item_cnt THEN ##11194 vjk 
						CALL updt_accum(gr_rptcol.col_uid, 
						l_col_total, 
						gv_col_curr_type, 
						1) 
					END IF 
				END IF 

			WHEN gr_rptline.line_type = gr_mrwparms.gl_line_type 
				AND l_item_type = gr_mrwparms.time_item_type 
				CALL fetch_time_amt(l_seq_num, p_line_uid) 
				RETURNING l_col_amt, 
				l_col_amt2, 
				l_status 
				IF l_status THEN 
					RETURN l_col_total, l_fmt_amt, l_status 
				END IF 
				LET l_col_total = operator_calc(l_col_amt, 
				l_col_total, 
				l_operator) 
				IF gr_rptline.accum_id THEN 
					IF gr_entry_criteria.conv_flag = "Y" THEN 
						IF l_idx = l_item_cnt THEN 
							CALL updt_accum(gr_rptcol.col_uid, 
							l_col_total, 
							gv_col_curr_type, 
							1) 
						END IF 
					ELSE 
						LET l_col_total2 = operator_calc(l_col_amt2, 
						l_col_total2, 
						l_operator) 
						IF gv_col_curr_type = "B" THEN 
							LET l_curr_type = "B" 
							LET l_curr_type2 = "T" 
						ELSE 
							LET l_curr_type = "T" 
							LET l_curr_type2 = "B" 
						END IF 
						IF l_idx = l_item_cnt THEN 

							CALL updt_accum(gr_rptcol.col_uid, 
							l_col_total, 
							l_curr_type, 
							1) 
							CALL updt_accum(gr_rptcol.col_uid, 
							l_col_total2, 
							l_curr_type2, 
							1) 
						END IF 
					END IF 
				END IF 

			WHEN gr_rptline.line_type = gr_mrwparms.calc_line_type 
				CALL get_col_accum() 
				RETURNING l_col_total, 
				l_fmt_amt, 
				l_status 

			WHEN gr_rptline.line_type = gr_mrwparms.ext_link_line_type 
				CALL extline_calc() 
				RETURNING l_col_total, 
				l_fmt_amt 

		END CASE 

	END FOREACH 

	#Save COLUMN amount
	LET l_col_id = gr_rptcol.col_id 
	LET ga_colitem_amt[l_col_id] = l_col_total 

	LET l_fmt_amt = format_amount (l_col_total, 
	gr_rptcol.width, 
	gr_rptcol.amt_picture) 

	RETURN l_col_total, l_fmt_amt, l_status 

END FUNCTION 


############################################################
# FUNCTION FETCH_time_amt(p_seq_num,p_line_uid)
#
# FETCH account history amounts.
# Description:     FUNCTION TO retrieve GL amounts FROM accounthist table.
############################################################
FUNCTION fetch_time_amt(p_seq_num,p_line_uid) 
	DEFINE p_seq_num LIKE colitem.seq_num 
	DEFINE p_line_uid LIKE rptline.line_uid 

	DEFINE l_tabname LIKE itemattr.tabname 
	DEFINE l_fv_curr_code LIKE currency.currency_code 
	DEFINE l_end_date LIKE period.end_date 
	DEFINE l_conv_qty FLOAT 
	DEFINE l_colname1 CHAR(25) 
	DEFINE l_colname2 CHAR(25) 
	DEFINE l_s1 CHAR(1600) 
	DEFINE l_slct CHAR(200) 
	DEFINE l_where CHAR(200) 
	DEFINE l_time CHAR(100) 
	DEFINE l_status SMALLINT 
	DEFINE l_ret_status SMALLINT 
	DEFINE l_chart_amt1 DECIMAL(18,2) 
	DEFINE l_chart_amt2 DECIMAL(18,2) 
	DEFINE l_chart_total1 DECIMAL(18,2) 
	DEFINE l_chart_total2 DECIMAL(18,2) 
	DEFINE l_curr_clause CHAR(30) 
	DEFINE l_chart_slct CHAR(100) 
	DEFINE l_analacross_clause CHAR(500) 
	DEFINE l_chart_clause LIKE gllinedetl.chart_clause 
	DEFINE l_chart_operator LIKE gllinedetl.operator 
	DEFINE l_stathist_clause CHAR(200) 
	DEFINE l_stathist_append CHAR(10) 

	LET l_chart_total1 = 0 
	LET l_chart_total2 = 0 

	LET l_ret_status = 1 #notfound 

	SELECT itemattr.tabname, itemattr.colname 
	INTO l_tabname, l_colname1 
	FROM colitem, itemattr 
	WHERE colitem.col_uid = gr_rptcol.col_uid 
	AND colitem.seq_num = p_seq_num 
	AND itemattr.item_id = colitem.col_item 

	LET gv_itemattr_colname = l_colname1 ##11194 vjk 

	IF status = notfound THEN 
		RETURN l_chart_total1, 
		l_chart_total2, 
		l_ret_status 
	END IF 


	LET l_stathist_append = NULL 
	LET l_stathist_clause = NULL 

	CASE 
		WHEN l_tabname = "stathist" 
			LET l_tabname = "S" 
			LET l_stathist_append = ", stathist" 
			LET l_stathist_clause = " AND stathist.cmpy_code = AH.cmpy_code ", 
			"AND stathist.acct_code = AH.acct_code ", 
			"AND stathist.year_num = AH.year_num ", 
			"AND stathist.period_num = AH.period_num" 
			LET l_colname2 = l_colname1 
			LET l_fv_curr_code = gv_base_curr 

		WHEN l_tabname = "accounthist" 
			LET l_tabname = "AH" 
			LET l_colname2 = l_colname1 
			LET l_fv_curr_code = gv_base_curr 

		WHEN l_tabname = "accounthistcur" 
			LET l_tabname = "AHC" 

			IF gv_curr_code IS NOT NULL THEN 
				LET l_curr_clause = " AND AHC.currency_code = '", gv_curr_code, "'" 
				LET l_fv_curr_code = gv_curr_code 
			ELSE 
				LET l_curr_clause = NULL 
				LET l_fv_curr_code = gv_base_curr 
			END IF 

			IF gr_entry_criteria.conv_flag = "Y" THEN #get base amounts 
				LET l_colname1 = "base_", l_colname1 clipped 
				LET l_colname2 = l_colname1 
			ELSE 
				CASE 
					WHEN gr_rptcol.curr_type = "T" 
						LET l_colname2 = "base_", l_colname1 clipped 
						LET gv_print_curr = gv_curr_code 
					WHEN gr_rptcol.curr_type = "B" 
						LET l_colname2 = l_colname1 
						LET l_colname1 = "base_", l_colname1 clipped 
						LET gv_print_curr = gv_base_curr 
				END CASE 
			END IF 

			IF l_colname1 = "base_ytd_pre_close_amt" THEN 
				LET l_colname1 = "base_ytd_pc_amt" 
			END IF 
			IF l_colname2 = "base_ytd_pre_close_amt" THEN 
				LET l_colname2 = "base_ytd_pc_amt" 
			END IF 
	END CASE 

	IF gr_rptcolgrp.colrptg_type = gr_mrwparms.analacross_type THEN 
		LET l_analacross_clause = analacross_clause() 
	END IF 

	CALL build_time_clause(p_seq_num) RETURNING l_time, l_end_date 

	IF gr_entry_criteria.conv_flag = "Y" THEN 
		IF gr_entry_criteria.use_end_date = "Y" THEN 
			LET l_conv_qty = get_conv_rate(
				glob_rec_kandoouser.cmpy_code, 
				gr_entry_criteria.conv_curr, 
				l_end_date, 
				CASH_EXCHANGE_BUY) 
		ELSE 
			LET l_conv_qty = gr_entry_criteria.conv_qty 
		END IF 
	END IF 

	#  IF the REPORT IS worksheet, OR the glline IS detailed, the account
	#  has already been selected in produce_rpt using the REPORT/line criteria,
	#  ie gv_entry_criteria, gv_analdown_clause, chart_clause, etc

	IF gv_account_code IS NOT NULL THEN #detailed/worksheet line 
		LET l_chart_operator = gv_chart_operator 
		IF gr_entry_criteria.conv_flag = "Y" THEN #select sum OF base 
			LET l_slct = "SELECT sum (", l_tabname clipped, ".", l_colname1 clipped, "), ", 
			"sum(", l_tabname clipped, ".", l_colname2 clipped, ")" 
		ELSE 
			LET l_slct = "SELECT ", l_tabname clipped, ".", l_colname1 clipped, 
			", ", l_tabname clipped, ".", l_colname2 clipped 
		END IF 


		# Special SELECT FOR budget columns which dont include accounthistcur table
		# TO avoid multiplication of budget amount FOR every currency row in the
		# accounstcur table
		# Or IF currency flag IS NOT on
		IF pr_glparms.use_currency_flag != "Y" 
		OR l_colname1 matches "*budg*" THEN 

			LET l_s1 = l_slct clipped, 
			" FROM accounthist AH ", 
			l_stathist_append clipped, 
			" WHERE AH.cmpy_code = ", 
			"'", gr_entry_criteria.cmpy_code clipped, "'", 
			" AND AH.acct_code = '", gv_account_code, "'", 
			l_curr_clause clipped, 
			l_analacross_clause clipped, 
			l_time clipped, 
			l_stathist_clause clipped 

		ELSE 


			LET l_s1 = l_slct clipped, 
			" FROM accounthist AH, ", 
			"accounthistcur AHC ", 
			l_stathist_append clipped, 
			" WHERE AH.cmpy_code = ", 
			"'", gr_entry_criteria.cmpy_code clipped, "'", 
			" AND AHC.cmpy_code = ", 
			"'", gr_entry_criteria.cmpy_code clipped, "'", 
			" AND AH.acct_code = '", gv_account_code, "'", 
			" AND AHC.acct_code = '", gv_account_code, "'", 
			" AND AH.year_num = AHC.year_num", 
			" AND AH.period_num = AHC.period_num ", 
			l_curr_clause clipped, 
			l_analacross_clause clipped, 
			l_time clipped, 
			l_stathist_clause clipped 
		END IF 

		PREPARE s_detl2 FROM l_s1 
		DECLARE detl_curs CURSOR FOR s_detl2 
		--OPEN s_detl2
		OPEN detl_curs 
		--FETCH s_detl2 INTO l_chart_amt1, l_chart_amt2
		FETCH detl_curs INTO l_chart_amt1, l_chart_amt2 

		#   IF STATUS = NOTFOUND THEN    #Doesn't work FOR sum-type selects
		IF l_chart_amt1 IS NULL 
		OR l_chart_amt2 IS NULL THEN 
			LET l_status = 1 
		ELSE 
			LET l_status = 0 
			DISPLAY "Account:", gv_account_code at 2,2 
			attribute(yellow) 

			IF gr_entry_criteria.conv_flag = "Y" 
			AND gr_entry_criteria.conv_curr <> gv_base_curr THEN 
				#Convert FROM base TO conv-TO currency
				LET l_chart_amt1 = l_chart_amt1 * l_conv_qty 
				#           LET l_chart_amt1 = conv_currency
				#             ( l_chart_amt1,
				#               gr_entry_criteria.cmpy_code,
				#               gr_entry_criteria.conv_curr,
				#               "T",
				#               l_end_date,
				#               "B" )

				LET l_chart_amt2 = l_chart_amt1 
				LET l_chart_total1 = operator_calc(l_chart_amt1, 
				l_chart_total1, 
				l_chart_operator) 
				LET l_chart_total2 = l_chart_total1 
			ELSE 
				LET l_chart_total1 = operator_calc(l_chart_amt1, 
				l_chart_total1, 
				l_chart_operator) 
				LET l_chart_total2 = operator_calc(l_chart_amt2, 
				l_chart_total2, 
				l_chart_operator) 
			END IF 
		END IF 

		--close s_detl2
		CLOSE detl_curs 
		LET l_ret_status = l_status 
	ELSE #consolidated g/l line 
		LET l_slct = "SELECT sum(", l_tabname clipped, ".", 
		l_colname1 clipped, "), ", 
		"sum(", l_tabname clipped, ".", 
		l_colname2 clipped, ") " 

		DECLARE gldetl_curs CURSOR FOR 
		SELECT chart_clause, operator, seq_num 
		FROM gllinedetl 
		WHERE line_uid = p_line_uid 
		ORDER BY seq_num 

		FOREACH gldetl_curs INTO l_chart_clause, l_chart_operator 
			LET l_chart_slct = build_chart(l_chart_clause) 


			# Special SELECT FOR budget columns which dont include accounthistcur table
			# TO avoid multiplication of budget amount FOR every currency row in the
			# accounstcur table
			# Or IF currency flag IS off
			IF pr_glparms.use_currency_flag != "Y" 
			OR l_colname1 matches "*budg*" THEN 
				LET l_s1 = l_slct clipped, 
				" FROM account A, ", 
				"accounthist AH ", 
				l_stathist_append clipped, 
				gv_tempcoa_append clipped, 
				" WHERE A.cmpy_code = ", 
				"'", gr_entry_criteria.cmpy_code clipped, "'", 
				" AND AH.cmpy_code = ", 
				"'", gr_entry_criteria.cmpy_code clipped, "' ", 
				" AND A.acct_code = AH.acct_code ", 
				" AND A.year_num = AH.year_num ", 
				l_curr_clause clipped, 
				l_chart_slct clipped, 
				gv_segment_criteria clipped, 
				gv_analdown_clause clipped, 
				l_analacross_clause clipped, 
				l_time clipped, 
				l_stathist_clause clipped, 
				gv_tempcoa_clause clipped 
			ELSE 

				LET l_s1 = l_slct clipped, 
				" FROM account A, ", 
				"accounthist AH, ", 
				"accounthistcur AHC ", 
				l_stathist_append clipped, 
				gv_tempcoa_append clipped, 
				" WHERE A.cmpy_code = ", 
				"'", gr_entry_criteria.cmpy_code clipped, "'", 
				" AND AH.cmpy_code = ", 
				"'", gr_entry_criteria.cmpy_code clipped, "' ", 
				" AND AHC.cmpy_code = ", 
				"'", gr_entry_criteria.cmpy_code clipped, "' ", 
				" AND A.acct_code = AH.acct_code ", 
				" AND A.acct_code = AHC.acct_code ", 
				" AND A.year_num = AH.year_num ", 
				" AND A.year_num = AHC.year_num", 
				" AND AH.period_num = AHC.period_num ", 
				l_curr_clause clipped, 
				l_chart_slct clipped, 
				gv_segment_criteria clipped, 
				gv_analdown_clause clipped, 
				l_analacross_clause clipped, 
				l_time clipped, 
				l_stathist_clause clipped, 
				gv_tempcoa_clause clipped 
			END IF 
			PREPARE s_consl FROM l_s1 
			DECLARE mark_1 CURSOR FOR s_consl 

			OPEN mark_1 
			FETCH mark_1 INTO l_chart_amt1, l_chart_amt2 

			#       IF STATUS = NOTFOUND THEN    #Doesn't work FOR sum-type selects
			IF l_chart_amt1 IS NULL 
			OR l_chart_amt2 IS NULL THEN 
				LET l_status = 1 
			ELSE 
				LET l_status = 0 
				IF gr_entry_criteria.conv_flag = "Y" 
				AND gr_entry_criteria.conv_curr <> gv_base_curr THEN 
					#Convert FROM base TO conv-TO currency
					LET l_chart_amt1 = l_chart_amt1 * l_conv_qty 
					#               LET l_chart_amt1 = conv_currency
					#                 ( l_chart_amt1,
					#                   gr_entry_criteria.cmpy_code,
					#                   gr_entry_criteria.conv_curr,
					#                   "T",
					#                   l_end_date,
					#                   "B" )

					LET l_chart_amt2 = l_chart_amt1 
					LET l_chart_total1 = operator_calc(l_chart_amt1, 
					l_chart_total1, 
					l_chart_operator) 
					LET l_chart_total2 = l_chart_total1 
				ELSE 
					LET l_chart_total1 = operator_calc(l_chart_amt1, 
					l_chart_total1, 
					l_chart_operator) 
					LET l_chart_total2 = operator_calc(l_chart_amt2, 
					l_chart_total2, 
					l_chart_operator) 
				END IF 
			END IF 


			CLOSE mark_1 
			IF l_status = 0 THEN 
				LET l_ret_status = 0 
			END IF 
		END FOREACH 
	END IF 

	RETURN l_chart_total1, l_chart_total2,l_ret_status 
END FUNCTION 


############################################################
# FUNCTION FETCH_value_amt(p_seq_num)
#
# FUNCTION:        FETCH COLUMN item value amounts.
# Description:     FUNCTION TO retrieve COLUMN item value FROM colitemval.
############################################################
FUNCTION fetch_value_amt(p_seq_num) 
	DEFINE p_seq_num LIKE colitem.seq_num 
	DEFINE l_item_val LIKE colitemval.item_value 

	SELECT item_value INTO l_item_val 
	FROM colitemval 
	WHERE col_uid = gr_rptcol.col_uid 
	AND seq_num = p_seq_num 

	IF l_item_val IS NULL THEN 
		LET l_item_val = 0 
	END IF 

	RETURN l_item_val 

END FUNCTION 


############################################################
# FUNCTION FETCH_column_amt(p_seq_num)
#
# FUNCTION:        FETCH COLUMN identifier COLUMN amounts.
#  Description:     FUNCTION TO retrieve COLUMN amount FROM a specified COLUMN.
############################################################
FUNCTION fetch_column_amt(p_seq_num) 

	DEFINE p_seq_num LIKE colitem.seq_num, 
	l_col_id LIKE colitemcolid.id_col_id 

	SELECT id_col_id INTO l_col_id 
	FROM colitemcolid 
	WHERE col_uid = gr_rptcol.col_uid 
	AND seq_num = p_seq_num 

	IF ga_colitem_amt[l_col_id] IS NULL THEN 
		LET ga_colitem_amt[l_col_id] = 0 
	END IF 

	RETURN ga_colitem_amt[l_col_id] 

END FUNCTION 


############################################################
# FUNCTION build_time_clause(p_seq_num)
#
# FUNCTION:     Build financial year AND period time clause
# Description   FUNCTION TO RETURN 'WHERE clause', FOR retrieving the
#                financial year AND period.
############################################################
FUNCTION build_time_clause(p_seq_num) 
	DEFINE p_seq_num LIKE colitem.seq_num 
	DEFINE l_time_clause CHAR(400) 
	DEFINE l_rec_colitemdetl RECORD LIKE colitemdetl.* 
	DEFINE l_end_date LIKE period.end_date 

	SELECT * INTO l_rec_colitemdetl.* 
	FROM colitemdetl 
	WHERE col_uid = gr_rptcol.col_uid 
	AND seq_num = p_seq_num 

	LET l_time_clause = NULL 
	IF status <> notfound THEN 
		IF l_rec_colitemdetl.year_type = gr_mrwparms.offset_type THEN 
			LET l_rec_colitemdetl.year_num = (gr_entry_criteria.year_num + 
			l_rec_colitemdetl.year_num) 
		END IF 
		IF l_rec_colitemdetl.period_type = gr_mrwparms.offset_type THEN 
			LET l_rec_colitemdetl.period_num = (gr_entry_criteria.period_num + 
			l_rec_colitemdetl.period_num) 
		END IF 
		LET l_time_clause = " AND AH.year_num = ", 
		l_rec_colitemdetl.year_num USING "<<<<<<" clipped, 
		" AND AH.period_num = ", 
		l_rec_colitemdetl.period_num USING "<<<<<<" clipped 
	END IF 

	SELECT end_date 
	INTO l_end_date 
	FROM period 
	WHERE cmpy_code = gr_entry_criteria.cmpy_code 
	AND year_num = l_rec_colitemdetl.year_num 
	AND period_num = l_rec_colitemdetl.period_num 

	# RETURN the year_num TO be used as an index attribute.
	RETURN l_time_clause, l_end_date 
END FUNCTION 


############################################################
# FUNCTION build_chart(p_chart_clause)
#
# FUNCTION:     Build Chart clause
# Description   FUNCTION TO RETURN 'WHERE clause' FOR retrieving the
#                account codes.
############################################################
FUNCTION build_chart(p_chart_clause) 
	DEFINE p_chart_clause LIKE gllinedetl.chart_clause 
	DEFINE l_chart_slct CHAR(100) 
	DEFINE l_pos INTEGER 
	DEFINE l_len INTEGER 
	DEFINE l_chart_len INTEGER 
	DEFINE l_first_time INTEGER 

	SELECT length_num 
	INTO l_chart_len 
	FROM structure 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND type_ind = "C" 

	LET l_len = length(p_chart_clause) 

	LET l_first_time = true 
	FOR l_pos = 1 TO l_len 
		CASE 
			WHEN p_chart_clause[l_pos,l_pos] = ':' 
				LET l_chart_slct 
				= " AND A.chart_code between '", 
				p_chart_clause[1,(l_pos-1)], 
				"' AND '", p_chart_clause[(l_pos+1),l_len],"'" 
				EXIT FOR 

			WHEN p_chart_clause[l_pos,l_pos] = '*' 
				LET l_chart_slct 
				= " AND A.chart_code matches '", p_chart_clause clipped,"'" 
				EXIT FOR 

			WHEN p_chart_clause[l_pos,l_pos] = '|' 
				IF l_first_time THEN 
					LET l_chart_slct 
					= " AND A.chart_code in ('", 
					p_chart_clause[1, (l_pos - 1)], "','", 
					p_chart_clause[(l_pos+1), (l_pos + l_chart_len)], "'" 
					LET l_first_time = false 
				ELSE 
					LET l_chart_slct = l_chart_slct clipped, ",'", 
					p_chart_clause[(l_pos+1), (l_pos + l_chart_len)], "'" 
				END IF 

		END CASE 
	END FOR 

	IF NOT l_first_time THEN 
		LET l_chart_slct = l_chart_slct clipped, ") " 
	END IF 

	IF l_chart_slct IS NULL THEN 
		LET l_chart_slct 
		= " AND A.chart_code = '", p_chart_clause clipped, "'" 
	END IF 

	RETURN l_chart_slct 

END FUNCTION 


############################################################
# FUNCTION operator_calc(p_amt, p_total, p_operator)
#
# FUNCTION:     Operator calculator
# Description   FUNCTION TO calculate using operator
############################################################
FUNCTION operator_calc(p_amt, p_total, p_operator) 
	DEFINE p_amt DECIMAL(18,2) 
	DEFINE p_total DECIMAL(18,2) 
	DEFINE p_operator CHAR(1) 

	IF p_total IS NULL THEN 
		LET p_total = 0 
	END IF 

	IF p_amt IS NULL THEN 
		LET p_amt = 0 
	END IF 

	CASE 
		WHEN p_operator = gr_mrwparms.add_op 
			LET p_total = p_total + p_amt 
		WHEN p_operator = gr_mrwparms.sub_op 
			LET p_total = p_total - p_amt 
		WHEN p_operator = gr_mrwparms.div_op 
			#Check FOR divide by zero
			IF p_amt = 0 OR p_total = 0 THEN 
				LET p_total = 0 
			ELSE 
				LET p_total = p_total / p_amt 
			END IF 
		WHEN p_operator = gr_mrwparms.mult_op 
			LET p_total = p_total * p_amt 
			#2174
		WHEN p_operator = gr_mrwparms.per_op 
			LET p_total = p_amt * 100 

	END CASE 

	RETURN p_total 
END FUNCTION 


############################################################
# FUNCTION operator_calc(fv_amt, fv_total, l_operator)
#
# FORMAT amount
# Description   This FUNCTION formats the 'value' passed by the 'picture'
#               AND COLUMN width also passed.
############################################################
FUNCTION format_amount(p_value, p_width, p_picture) 
	DEFINE p_value DECIMAL(18,2) 
	DEFINE p_width LIKE rptcol.width 
	DEFINE p_picture LIKE rptcol.amt_picture 

	DEFINE l_rnd_value LIKE rndcode.rnd_value 
	DEFINE l_expected_sign LIKE glline.expected_sign 
	DEFINE l_formatted CHAR(60) 
	DEFINE l_tmp_value CHAR(60) 
	DEFINE l_wksht_idx SMALLINT 

	IF p_value IS NULL THEN 
		LET p_value = 0 
	END IF 

	IF gr_glline.always_print = "O" 
	OR gr_calchead.always_print = "O" THEN # only PRINT IF non-zero 
		IF p_value = 0 THEN 
			LET l_formatted = " " 
			RETURN l_formatted 
		END IF 
	END IF 

	IF p_width IS NULL OR p_width = 0 THEN 
		LET l_formatted = " " 
		RETURN l_formatted 
	END IF 


	LET p_value = round_vals(p_value) 

	# Work out sign code FOR displaying information.
	CASE 
		WHEN gr_rptline.line_type = gr_mrwparms.gl_line_type 
			LET l_expected_sign = gr_glline.expected_sign 

		WHEN gr_rptline.line_type = gr_mrwparms.calc_line_type 
			LET l_expected_sign = gr_calchead.expected_sign 

		WHEN gr_rptline.line_type = gr_mrwparms.ext_link_line_type 
			LET l_expected_sign = gr_exthead.expected_sign 
	END CASE 

	IF gr_signcode.sign_base = "L" THEN # sign = + : reverse IF sign differs. 
		   { IF signs differ THEN calculate using the following.
		     Eg.  Value        Expected         outcome
		            +             +                +
		            -             +                -
		            +             -                -
		            -             -                + }
		IF l_expected_sign = "-" THEN 
			LET p_value = -1 * p_value 
		END IF 
	ELSE 
		#Sign = "Y" : Reverse all value signs.
		IF gr_signcode.sign_base = 'D' AND gr_signcode.sign_change = '-' THEN 

			LET p_value = -1 * p_value 
		END IF 
	END IF 

	LET l_formatted = p_value USING p_picture 
	LET l_formatted = l_formatted[1,p_width] 

	LET l_wksht_idx = gr_rptcol.col_id 

	RETURN l_formatted 

END FUNCTION 


############################################################
# FUNCTION clear_accum()
#
# CLEAR all REPORT accumulators.
############################################################
FUNCTION clear_accum() 

	DELETE FROM colaccum 
	WHERE job_id = gv_job_id 
	AND rpt_id = gr_rpthead.rpt_id 

END FUNCTION 

###############################################################################
{ FUNCTION:     check IF accumulator COLUMN.
}
#FUNCTION col_accum()

#DEFINE fv_accum_id     LIKE rptline.accum_id

#SELECT accum_id INTO fv_accum_id
#  FROM saveline
#  WHERE line_uid = gr_rptline.line_uid

#IF fv_accum_id IS NULL THEN
#   LET fv_accum_id = 0
#END IF

#LET fv_accum_id = gr_rptline.accum_id
#RETURN fv_accum_id

#END FUNCTION


############################################################
# FUNCTION updt_accum(p_col_uid,
#                    p_accum_add,
#                    p_curr_type,
#                    p_updt_tot_sw)
#
# Save REPORT COLUMN accumulator.
############################################################
FUNCTION updt_accum(p_col_uid, 
	p_accum_add, 
	p_curr_type, 
	p_updt_tot_sw) 

	DEFINE p_col_uid LIKE rptcol.col_uid 
	DEFINE p_accum_add LIKE colaccum.accum_amt 
	DEFINE p_curr_type LIKE rptcol.curr_type 
	DEFINE p_updt_tot_sw SMALLINT 

	DEFINE l_accum_amt LIKE colaccum.accum_amt 
	DEFINE l_fv_curr_code LIKE currency.currency_code 
	DEFINE l_debug SMALLINT 

	IF p_accum_add IS NULL THEN 
		LET p_accum_add = 0 
	END IF 


	LET p_accum_add = round_vals(p_accum_add) 


	IF p_accum_add IS NULL THEN 
		LET p_accum_add = 0 
	END IF 

	IF gr_entry_criteria.conv_flag = "Y" THEN 
		LET l_fv_curr_code = gr_entry_criteria.conv_curr 
	ELSE 
		IF p_curr_type = "B" THEN 
			--This IS a hack TO cater FOR the fact that  the structure
			--of the the database does NOT carry budgets AT a multicurrency
			--level.  Should any other COLUMN in the accounthist RECORD (OR
			--any other ) ever get called '*budg*' THEN
			--the program will be in error AT this point.


			IF gv_base_curr != gv_curr_code 
			AND gv_itemattr_colname matches "*budg*" THEN 
				RETURN 
			END IF 


			LET l_fv_curr_code = gv_base_curr 
		ELSE 
			IF pr_glparms.use_currency_flag = "Y" THEN 
				LET l_fv_curr_code = gv_curr_code 
			ELSE 
				LET l_fv_curr_code = gv_base_curr 
			END IF 
		END IF 
	END IF 


	#Check IF accumulator exists, IF so THEN add accumulator amount.
	SELECT accum_amt INTO l_accum_amt 
	FROM colaccum 
	WHERE job_id = gv_job_id 
	AND rpt_id = gr_rpthead.rpt_id 
	AND col_uid = p_col_uid 
	AND accum_id = gr_rptline.accum_id 
	AND curr_type = p_curr_type 
	AND curr_code = l_fv_curr_code 

	IF status = notfound THEN 
		INSERT INTO colaccum VALUES (gv_job_id, 
		gr_rpthead.rpt_id, 
		p_col_uid, 
		gr_rptline.accum_id, 
		p_accum_add, 
		p_curr_type, 
		l_fv_curr_code) 
	ELSE 
		IF l_accum_amt IS NULL THEN 
			LET l_accum_amt = 0 
		END IF 
		UPDATE colaccum 
		SET accum_amt = (l_accum_amt + p_accum_add) 
		WHERE job_id = gv_job_id 
		AND rpt_id = gr_rpthead.rpt_id 
		AND col_uid = p_col_uid 
		AND accum_id = gr_rptline.accum_id 
		AND curr_type = p_curr_type 
		AND curr_code = l_fv_curr_code 
	END IF 

	#Also add INTO worksheet total RECORD (accum-id = 0), IF required
	IF gr_entry_criteria.worksheet_rpt = "W" 
	AND p_updt_tot_sw THEN 
		SELECT accum_amt INTO l_accum_amt 
		FROM colaccum 
		WHERE job_id = gv_job_id 
		AND rpt_id = gr_rpthead.rpt_id 
		AND col_uid = p_col_uid 
		AND accum_id = 0 
		AND curr_type = p_curr_type 
		AND curr_code = l_fv_curr_code 

		IF status = notfound THEN 
			INSERT INTO colaccum VALUES (gv_job_id, 
			gr_rpthead.rpt_id, 
			p_col_uid, 
			0, 
			p_accum_add, 
			p_curr_type, 
			l_fv_curr_code) 
		ELSE 
			IF l_accum_amt IS NULL THEN 
				LET l_accum_amt = 0 
			END IF 
			UPDATE colaccum 
			SET accum_amt = (l_accum_amt + p_accum_add) 
			WHERE job_id = gv_job_id 
			AND rpt_id = gr_rpthead.rpt_id 
			AND col_uid = p_col_uid 
			AND accum_id = 0 
			AND curr_type = p_curr_type 
			AND curr_code = l_fv_curr_code 
		END IF 
	END IF 

END FUNCTION 


############################################################
# FUNCTION analdown_clause()
#
# Analysis Down Clause
# Description   FUNCTION TO RETURN 'WHERE clause' FOR retrieving the
#               account codes.
############################################################
FUNCTION analdown_clause() 
	DEFINE l_rec_segline RECORD LIKE segline.* 
	DEFINE l_rec_structure RECORD LIKE structure.* 
	DEFINE l_flex_slct CHAR(400) 
	DEFINE l_clause_slct CHAR(400) 
	DEFINE l_flex_clause LIKE segline.flex_clause 
	DEFINE l_first_time SMALLINT 
	DEFINE l_pos INTEGER 
	DEFINE l_len INTEGER 
	DEFINE l_structure_length LIKE structure.length_num 
	DEFINE l_structure_end SMALLINT 

	DECLARE andwn_curs CURSOR FOR 
	SELECT * 
	FROM segline 
	WHERE line_uid = gr_rptline.line_uid 

	LET l_flex_clause = NULL 
	LET l_clause_slct = NULL 

	FOREACH andwn_curs INTO l_rec_segline.* 
		SELECT * INTO l_rec_structure.* 
		FROM structure 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND start_num = l_rec_segline.start_num 

		LET l_flex_clause = l_rec_segline.flex_clause 
		LET l_flex_slct = NULL 
		LET l_first_time = true 

		IF status <> notfound THEN 
			LET l_structure_length = l_rec_structure.length_num 
			LET l_structure_end 
			= l_rec_structure.start_num + l_rec_structure.length_num - 1 

			LET l_len = length(l_flex_clause) 

			FOR l_pos = 1 TO l_len 
				CASE 
					WHEN l_flex_clause[l_pos,l_pos] = ':' 
						LET l_flex_slct = 
						" AND AH.acct_code[", 
						l_rec_structure.start_num USING "<<<<<<", ",", 
						l_structure_end USING "<<<<<<", "] between ", "'", 
						l_flex_clause[1,(l_pos-1)], "'", 
						" AND ", "'", l_flex_clause[(l_pos+1),l_len], "'" 
						EXIT FOR 

					WHEN l_flex_clause[l_pos,l_pos] = '*' 
						LET l_flex_slct = 
						" AND AH.acct_code[", 
						l_rec_structure.start_num USING "<<<<<<", ",", 
						l_structure_end USING "<<<<<<", "] matches '", 
						l_flex_clause clipped, "'" 
						EXIT FOR 

					WHEN l_flex_clause[l_pos,l_pos] = '|' 
						IF l_first_time THEN 
							LET l_flex_slct = 
							" AND AH.acct_code[", 
							l_rec_structure.start_num USING "<<<<<<", ",", 
							l_structure_end USING "<<<<<<", "] in ('", 
							l_flex_clause[1, (l_pos-1)], "','", 
							l_flex_clause[(l_pos+1), 
							(l_pos + l_structure_length)], "'" 
							LET l_first_time = false 
						ELSE 
							LET l_flex_slct = 
							l_flex_slct clipped, ",'", 
							l_flex_clause[(l_pos+1), 
							(l_pos + l_structure_length)], "'" 
						END IF 

				END CASE 
			END FOR 

			IF NOT l_first_time THEN 
				LET l_flex_slct = l_flex_slct clipped, ") " 
			END IF 

			IF l_flex_slct IS NULL THEN 
				LET l_flex_slct = " AND AH.acct_code[", 
				l_rec_structure.start_num USING "<<<<<<", 
				",", l_structure_end USING "<<<<<<", "]", 
				" = '", l_flex_clause clipped,"'" 

			END IF 

			LET l_clause_slct = l_clause_slct clipped, 
			l_flex_slct clipped 

		END IF 

	END FOREACH 

	RETURN l_clause_slct 

END FUNCTION 


############################################################
# FUNCTION analacross_clause()
#
# Analysis Across Clause
#  Description   FUNCTION TO RETURN 'WHERE clause' FOR retrieving the
#                account codes.
############################################################
FUNCTION analacross_clause() 
	DEFINE l_rec_rptcolaa RECORD LIKE rptcolaa.* 
	DEFINE l_rec_structure RECORD LIKE structure.* 
	DEFINE l_flex_slct CHAR(400) 
	DEFINE l_clause_slct CHAR(400) 
	DEFINE l_flex_clause LIKE segline.flex_clause 
	DEFINE l_first_time SMALLINT 
	DEFINE l_pos INTEGER 
	DEFINE l_len INTEGER 
	DEFINE l_structure_length LIKE structure.length_num 
	DEFINE l_structure_end SMALLINT 

	DECLARE anacr_curs CURSOR FOR 
	SELECT * 
	FROM rptcolaa 
	WHERE col_uid = gr_rptcol.col_uid 

	LET l_flex_clause = NULL 

	FOREACH anacr_curs INTO l_rec_rptcolaa.* 
		SELECT * INTO l_rec_structure.* 
		FROM structure 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND start_num = l_rec_rptcolaa.start_num 

		LET l_flex_clause = l_rec_rptcolaa.flex_clause 
		LET l_flex_slct = NULL 
		LET l_first_time = true 

		IF status <> notfound THEN 
			LET l_structure_length = l_rec_structure.length_num 
			LET l_structure_end 
			= l_rec_structure.start_num + l_rec_structure.length_num - 1 
			LET l_len = length(l_flex_clause) 

			FOR l_pos = 1 TO l_len 
				CASE 
					WHEN l_flex_clause[l_pos,l_pos] = ':' 
						LET l_flex_slct = 
						" AND AH.acct_code[", 
						l_rec_structure.start_num USING "<<<<<<", 
						",", l_structure_end USING "<<<<<<", 
						"] between '", l_flex_clause[1,(l_pos-1)], 
						"' AND '", l_flex_clause[(l_pos+1),l_len], "'" 
						EXIT FOR 
					WHEN l_flex_clause[l_pos,l_pos] = '*' 
						LET l_flex_slct = 
						" AND AH.acct_code[", 
						l_rec_structure.start_num USING "<<<<<<", 
						",", l_structure_end USING "<<<<<<", 
						"] matches '", l_flex_clause clipped, "'" 
						EXIT FOR 
					WHEN l_flex_clause[l_pos,l_pos] = '|' 
						IF l_first_time THEN 
							LET l_flex_slct = 
							" AND AH.acct_code[", 
							l_rec_structure.start_num USING "<<<<<<", ",", 
							l_structure_end USING "<<<<<<", 
							"] in ('", l_flex_clause[1,(l_pos-1)], "','", 
							l_flex_clause[(l_pos+1), 
							(l_pos + l_structure_length)], "'" 
							LET l_first_time = false 
						ELSE 
							LET l_flex_slct = 
							l_flex_slct clipped, ",'", 
							l_flex_clause[(l_pos+1), 
							(l_pos + l_structure_length)], "'" 
						END IF 
				END CASE 
			END FOR 

			IF NOT l_first_time THEN 
				LET l_flex_slct = l_flex_slct clipped, ") " 
			END IF 

			IF l_flex_slct IS NULL THEN 
				LET l_flex_slct 
				= " AND AH.acct_code[", 
				l_rec_structure.start_num USING "<<<<<<", ",", 
				l_structure_end USING "<<<<<<", "]", 
				" = '", l_flex_clause clipped,"'" 

			END IF 

			LET l_clause_slct = l_clause_slct clipped, 
			l_flex_slct clipped 

		END IF 

	END FOREACH 

	RETURN l_clause_slct 

END FUNCTION 


############################################################
# FUNCTION extline_calc()
#
#
############################################################
FUNCTION extline_calc() 
	DEFINE l_amt_dec DECIMAL(18,2) 
	DEFINE l_col_total DECIMAL(18,2) 
	DEFINE l_col_id LIKE rptcol.col_id 
	DEFINE l_fmt_amt LIKE rptcoldesc.col_desc 
	DEFINE l_rec_exthead RECORD LIKE exthead.* 
	DEFINE l_rec_extline RECORD LIKE extline.* 
	DEFINE l_rec_rptline RECORD LIKE rptline.* 
	DEFINE l_rec_s_rptline RECORD LIKE rptline.* 
	DEFINE l_status SMALLINT 
	DEFINE l_curr_type LIKE rptcol.curr_type 

	LET l_col_total = 0 
	LET gv_detl_flag = false 

	SELECT * 
	FROM exthead 
	WHERE line_uid = gr_rptline.line_uid 

	DECLARE f_extline_curs 
	CURSOR FOR 
	SELECT * 
	FROM extline 
	WHERE line_uid = gr_rptline.line_uid 

	LET l_rec_s_rptline.* = gr_rptline.* 
	FOREACH f_extline_curs INTO l_rec_extline.* 
		DECLARE f_rptline_curs 
		CURSOR FOR 
		SELECT * 
		FROM rptline 
		WHERE cmpy_code = l_rec_extline.ext_cmpy_code 
		AND line_code = l_rec_extline.ext_line_code 
		AND accum_id = l_rec_extline.ext_accum_id 
		AND line_type = gr_mrwparms.gl_line_type 

		FOREACH f_rptline_curs INTO l_rec_rptline.* 
			SELECT * 
			INTO gr_glline.* 
			FROM glline 
			WHERE line_uid = l_rec_rptline.line_uid 

			LET gr_rptline.* = l_rec_rptline.* 

			IF gv_curr_slct IS NULL THEN 
				DECLARE extcurr_curs1 CURSOR FOR 
				SELECT curr_code 
				FROM temp_curr 
				FOREACH extcurr_curs1 INTO gv_curr_code 
					CALL colitem_amt(l_rec_rptline.line_uid) 
					RETURNING l_amt_dec, 
					l_fmt_amt, 
					l_status 
				END FOREACH 
			ELSE 
				DECLARE extcurr_curs2 CURSOR FOR 
				SELECT curr_code 
				FROM temp_curr 
				WHERE curr_code = gv_curr_slct 
				FOREACH extcurr_curs2 INTO gv_curr_code 
					CALL colitem_amt(l_rec_rptline.line_uid) 
					RETURNING l_amt_dec, 
					l_fmt_amt, 
					l_status 
				END FOREACH 
			END IF 
			LET l_col_total = l_col_total + l_amt_dec 
		END FOREACH 
	END FOREACH 
	LET gr_rptline.* = l_rec_s_rptline.* 

	INITIALIZE gr_glline.* TO NULL 

	## Place value INTO Accumulator.
	#IF gr_rptline.accum_id THEN
	#   CALL updt_accum(gr_rptcol.col_uid,
	#                   l_col_total,
	#                   l_curr_type)
	#                   l_curr_type,
	#                   0)
	#END IF

	#Save COLUMN amount
	LET l_col_id = gr_rptcol.col_id 
	LET ga_colitem_amt[l_col_id] = l_col_total 

	LET l_fmt_amt = format_amount(l_col_total, 
	gr_rptcol.width, 
	gr_rptcol.amt_picture) 

	RETURN l_col_total, l_fmt_amt 

END FUNCTION 


############################################################
# FUNCTION get_col_accum()
#
#
############################################################
FUNCTION get_col_accum() 
	DEFINE l_amt DECIMAL(18,2) 
	DEFINE l_fmt_amt LIKE descline.line_desc 
	DEFINE l_status SMALLINT 

	SELECT accum_amt 
	INTO l_amt 
	FROM colaccum 
	WHERE job_id = gv_job_id 
	AND rpt_id = gr_rpthead.rpt_id 
	AND col_uid = gr_rptcol.col_uid 
	AND accum_id = 0 
	AND curr_type = gr_colaccum.curr_type 
	AND curr_code = gv_curr_code 

	IF status THEN 
		LET l_status = true 
	ELSE 
		LET l_status = false 
		LET l_fmt_amt = format_amount(l_amt, 
		gr_rptcol.width, 
		gr_rptcol.amt_picture) 
		IF gr_colaccum.curr_type = "B" THEN 
			LET gv_print_curr = gr_entry_criteria.base_lit 
		ELSE 
			LET gv_print_curr = gv_curr_code 
		END IF 
	END IF 

	RETURN l_amt, l_fmt_amt, l_status 

END FUNCTION 


############################################################
# FUNCTION round_vals(p_value)
#
#
############################################################
FUNCTION round_vals(p_value) 
	DEFINE p_value DECIMAL(18,02) 

	DEFINE l_rnd_value LIKE rndcode.rnd_value 
	DEFINE l_temp_value CHAR(60) 

	SELECT rnd_value INTO l_rnd_value 
	FROM rndcode 
	WHERE rnd_code = gr_rpthead.rnd_code 

	IF l_rnd_value > 00 AND l_rnd_value IS NOT NULL THEN 
		LET l_temp_value = ( p_value / l_rnd_value ) 
		USING "-----------------&" 
		LET p_value = l_temp_value 
	END IF 

	RETURN p_value 

END FUNCTION 
