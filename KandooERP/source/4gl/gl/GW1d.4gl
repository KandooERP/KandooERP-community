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
GLOBALS "../gl/GW1_GLOBALS.4gl"
############################################################
# FUNCTION colitem_amt()
#
# COLUMN item amount
# Description:     FUNCTION TO FETCH AND RETURN COLUMN item amount
#                  DEFINE by the user.
############################################################
FUNCTION colitem_amt() 
	DEFINE l_seq_num LIKE colitem.seq_num 
	DEFINE l_operator LIKE colitem.item_operator 
	DEFINE l_item_type LIKE mrwitem.item_type 
	DEFINE l_fmt_amt LIKE rptcoldesc.col_desc 
	DEFINE l_col_id LIKE rptcol.col_id 
	DEFINE l_accum_id LIKE saveline.accum_id 
	DEFINE l_col_amt DECIMAL(18,2) 
	DEFINE l_col_total DECIMAL(18,2) 

	#Retrieve all COLUMN item details FOR calculation.
	DECLARE colitem_curs CURSOR FOR 
	SELECT colitem.seq_num, 
	colitem.item_operator, 
	mrwitem.item_type 
	FROM colitem, mrwitem 
	WHERE colitem.col_uid = glob_rec_rptcol.col_uid 
	AND mrwitem.item_id = colitem.col_item 
	AND colitem.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET l_col_total = 0 
	FOREACH colitem_curs INTO l_seq_num, l_operator, l_item_type 
		LET l_col_amt = 0 
		CASE 
			WHEN l_item_type = glob_rec_mrwparms.time_item_type 
				LET l_col_amt = fetch_time_amt(l_seq_num) 
				LET glob_col_amt = l_col_amt 
			WHEN l_item_type = glob_rec_mrwparms.column_item_type 
				LET l_col_amt = fetch_column_amt(l_seq_num) 
			WHEN l_item_type = glob_rec_mrwparms.value_item_type 
				LET l_col_amt = fetch_value_amt(l_seq_num) 
			WHEN l_item_type = "O" #hardcoded FOR now until decide what TO do 
				IF glob_rec_glline.print_in_offset = "Y" THEN 
					LET l_col_amt = glob_col_amt 
				END IF 
		END CASE 

		# Perform operator calculation.
		LET l_col_total = operator_calc(l_col_amt, 
		l_col_total, 
		l_operator ) 
	END FOREACH 

	# Place value INTO Accumulator.
	LET l_accum_id = col_accum() 
	IF l_accum_id THEN 
		CALL updt_accum( glob_rec_rptcol.col_uid, l_accum_id, l_col_total ) 
	END IF 

	#Save COLUMN amount
	LET l_col_id = glob_rec_rptcol.col_id 
	LET glob_arr_colitem_amt[l_col_id] = l_col_total 

	LET l_fmt_amt = format_amount( l_col_total, 
	glob_rec_rptcol.width, 
	glob_rec_rptcol.amt_picture ) 
	RETURN l_fmt_amt 

END FUNCTION 


############################################################
# FUNCTION FETCH_time_amt(p_seq_num)
#
#
############################################################
FUNCTION fetch_time_amt(p_seq_num) 
	DEFINE p_seq_num LIKE colitem.seq_num 

	DEFINE l_tabname LIKE itemattr.tabname 
	DEFINE l_colname LIKE itemattr.colname 
	DEFINE l_year_num LIKE accounthist.year_num 
	DEFINE l_period_num LIKE accounthist.period_num 
	DEFINE l_s1 CHAR(1600) 
	DEFINE l_slct CHAR(100) 
	DEFINE l_slct2 CHAR(500) 
	DEFINE l_qty CHAR(30) 
	DEFINE l_where CHAR(200) 
	DEFINE l_time CHAR(100) 
	DEFINE l_detail_clause CHAR(100) 
	DEFINE l_chart_amt DECIMAL(18,2) 
	DEFINE l_chart_total DECIMAL(18,2) 
	DEFINE l_chart_slct DECIMAL(18,2) 
	DEFINE l_analdown_clause CHAR(400) 
	DEFINE l_analacross_clause CHAR(400) 
	DEFINE l_chart_clause LIKE gllinedetl.chart_clause 
	DEFINE l_chart_operator LIKE gllinedetl.operator 
	DEFINE l_col_item LIKE colitem.col_item 

	LET l_chart_total = 0 

	IF glob_rec_rpthead.rpt_type = glob_rec_mrwparms.analacross_type THEN 
		LET l_analacross_clause = analacross_clause() 
	END IF 
	IF glob_rec_rpthead.rpt_type = glob_rec_mrwparms.analdown_type THEN 
		LET l_analdown_clause = analdown_clause() 
	END IF 

	IF glob_rec_entry_criteria.detailed_rpt = "D" THEN 
		LET l_detail_clause = "AND coa.acct_code = '",glob_account_code,"'" 
	ELSE 
		LET l_detail_clause = NULL 
	END IF 

	IF glob_consolidations_exist THEN 
		LET l_slct2 = l_s1 clipped, 
		" AND account.acct_code[",glob_start_num USING "&&",",", 
		glob_length_num USING "&&","] in ",glob_range clipped, " " 
	ELSE 
		LET l_slct2 = " AND 1=1 " 
	END IF 
	SELECT itemattr.tabname, itemattr.colname,colitem.col_item 
	INTO l_tabname, l_colname, l_col_item 
	FROM colitem, itemattr 
	WHERE colitem.col_uid = glob_rec_rptcol.col_uid 
	AND colitem.seq_num = p_seq_num 
	AND itemattr.item_id = colitem.col_item 
	AND colitem.cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF status != NOTFOUND THEN 
		IF glob_report_type = "2" THEN 
			IF l_colname matches "*bud*" 
			OR l_colname matches "stats*" THEN 
				#Cant SELECT budgets OR stats FROM accounthistcur
				LET l_slct = "SELECT 0 " 
			ELSE 
				LET l_slct = "SELECT SUM( accounthistcur.",l_colname clipped,") " 
			END IF 
		ELSE 
			IF glob_report_type = "1" THEN 
				LET l_slct = 
				"SELECT SUM( accounthist.",l_colname clipped,") * ", 
				glob_conv_qty," " 
			ELSE 
				LET l_slct = "SELECT SUM( accounthist.",l_colname clipped,") " 
			END IF 
		END IF 
		IF l_colname = "stats_qty" THEN 
			#This IS required TO overcome Accounts flagged TO Collect Quanties but
			#are NOT TRUE QTY Accounts ie (Actuals AND Quantities exist)
			#TRUE QTY Accounts have no actuals
			LET l_qty = "AND coa.uom_code = 'QTY' " 
		ELSE 
			LET l_qty = NULL 
		END IF 
		CALL build_time_clause(p_seq_num,l_col_item) RETURNING l_time, l_year_num 

		DECLARE gldetl_curs CURSOR FOR 
		SELECT chart_clause, operator, seq_num FROM gllinedetl 
		WHERE line_uid = glob_rec_rptline.line_uid 
		AND gllinedetl.cmpy_code = glob_rec_kandoouser.cmpy_code 

		FOREACH gldetl_curs INTO l_chart_clause, l_chart_operator 
			LET l_chart_slct = build_chart( l_chart_clause ) 
			IF glob_report_type = "2" THEN 
				LET l_s1 = l_slct clipped, " FROM coa, account, accounthistcur " 
			ELSE 
				LET l_s1 = l_slct clipped, " FROM coa, account, accounthist " 
			END IF 
			LET l_s1 = l_s1 clipped, 
			" WHERE ", glob_entry_criteria clipped, 
			" AND account.cmpy_code = coa.cmpy_code ", 
			" AND account.acct_code = coa.acct_code ", 
			" AND account.year_num = ", l_year_num," ", 
			l_chart_slct clipped 
			IF glob_report_type = "2" THEN 
				LET l_s1 = l_s1 clipped, 
				" AND accounthistcur.cmpy_code = account.cmpy_code ", 
				" AND accounthistcur.acct_code = account.acct_code ", 
				" AND accounthistcur.currency_code = '",glob_curr_code,"' " 
			ELSE 
				LET l_s1 = l_s1 clipped, 
				" AND accounthist.cmpy_code = account.cmpy_code ", 
				" AND accounthist.acct_code = account.acct_code " 
			END IF 
			LET l_s1 = l_s1 clipped, " ", glob_segment_criteria clipped, 
			l_analacross_clause clipped, 
			l_analdown_clause clipped, 
			l_detail_clause clipped, 
			l_qty clipped, 
			l_slct2 clipped, 
			l_time clipped 

			PREPARE s1_1 FROM l_s1 
			DECLARE s_1 CURSOR FOR s1_1 
			OPEN s_1 
			FETCH s_1 INTO l_chart_amt 
			CLOSE s_1 
			LET glob_full_criteria = l_s1 
			LET l_chart_total = operator_calc(l_chart_amt, 
			l_chart_total, 
			l_chart_operator ) 

		END FOREACH 
	END IF 

	RETURN l_chart_total 

END FUNCTION 


############################################################
# FUNCTION FETCH_value_amt(p_seq_num)
#
# FETCH COLUMN item value amounts.
# Description:     FUNCTION TO retrieve COLUMN item value FROM colitemval.
############################################################
FUNCTION fetch_value_amt(p_seq_num) 
	DEFINE p_seq_num LIKE colitem.seq_num 
	DEFINE l_item_val LIKE colitemval.item_value 

	SELECT item_value INTO l_item_val FROM colitemval 
	WHERE col_uid = glob_rec_rptcol.col_uid 
	AND seq_num = p_seq_num 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 

	IF l_item_val IS NULL THEN 
		LET l_item_val = 0 
	END IF 

	RETURN l_item_val 

END FUNCTION 


############################################################
# FUNCTION FETCH_value_amt(p_seq_num)
#
# FETCH COLUMN identifier COLUMN amounts.
# Description:  FUNCTION TO retrieve COLUMN amount FROM a specified COLUMN.
############################################################
FUNCTION fetch_column_amt(p_seq_num) 
	DEFINE p_seq_num LIKE colitem.seq_num 
	DEFINE l_col_id LIKE colitemcolid.id_col_id 

	SELECT id_col_id INTO l_col_id FROM colitemcolid 
	WHERE col_uid = glob_rec_rptcol.col_uid 
	AND seq_num = p_seq_num 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 

	IF glob_arr_colitem_amt[l_col_id] IS NULL THEN 
		LET glob_arr_colitem_amt[l_col_id] = 0 
	END IF 
	RETURN glob_arr_colitem_amt[l_col_id] 

END FUNCTION 


############################################################
# FUNCTION build_time_clause( p_seq_num, p_col_item )
#
# Build financial year AND period time clause
# Description   FUNCTION TO RETURN 'WHERE clause', FOR retrieving the
#               financial year AND period.
############################################################
FUNCTION build_time_clause(p_seq_num, p_col_item) 
	DEFINE p_seq_num LIKE colitem.seq_num 
	DEFINE p_col_item LIKE colitem.col_item 

	DEFINE l_time_clause CHAR(100) 
	DEFINE l_rec_colitemdetl RECORD LIKE colitemdetl.* 

	LET l_time_clause = NULL 
	SELECT * INTO l_rec_colitemdetl.* FROM colitemdetl 
	WHERE col_uid = glob_rec_rptcol.col_uid 
	AND seq_num = p_seq_num 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 

	IF status != NOTFOUND THEN 
		IF l_rec_colitemdetl.year_type = glob_rec_mrwparms.offset_type THEN 
			LET l_rec_colitemdetl.year_num = (glob_rec_entry_criteria.year_num + 
			l_rec_colitemdetl.year_num) 
		END IF 
		IF l_rec_colitemdetl.period_type = glob_rec_mrwparms.offset_type THEN 
			LET l_rec_colitemdetl.period_num = (glob_rec_entry_criteria.period_num + 
			l_rec_colitemdetl.period_num) 
		END IF 
		IF p_col_item = "YQTY" THEN 
			IF glob_report_type = "2" THEN 
				LET l_time_clause = 
				" AND accounthistcur.year_num = ", l_rec_colitemdetl.year_num, 
				" AND accounthistcur.period_num <= ", l_rec_colitemdetl.period_num 
			ELSE 
				LET l_time_clause = 
				" AND accounthist.year_num = ", l_rec_colitemdetl.year_num, 
				" AND accounthist.period_num <= ", l_rec_colitemdetl.period_num 
			END IF 
		ELSE 
			IF glob_report_type = "2" THEN 
				LET l_time_clause = 
				" AND accounthistcur.year_num = ", l_rec_colitemdetl.year_num, 
				" AND accounthistcur.period_num = ", l_rec_colitemdetl.period_num 
			ELSE 
				LET l_time_clause = 
				" AND accounthist.year_num = ", l_rec_colitemdetl.year_num, 
				" AND accounthist.period_num = ", l_rec_colitemdetl.period_num 
			END IF 
		END IF 
	END IF 

	# RETURN the year_num TO be used as an index attribute.
	RETURN l_time_clause, l_rec_colitemdetl.year_num 

END FUNCTION 


############################################################
# FUNCTION build_chart( p_chart_clause )
#
# Build Chart clause
# Description FUNCTION too RETURN 'WHERE clause' FOR retrieving the
#             account codes.
############################################################
FUNCTION build_chart(p_chart_clause) 
	DEFINE p_chart_clause LIKE gllinedetl.chart_clause 
	DEFINE l_chart_slct CHAR(100) 
	DEFINE l_fv_pos INTEGER 
	DEFINE l_fv_len INTEGER 


	LET l_fv_len = length(p_chart_clause) 

	FOR l_fv_pos = 1 TO l_fv_len 
		CASE 
			WHEN p_chart_clause[l_fv_pos,l_fv_pos] = ':' 
				LET l_chart_slct = " AND account.chart_code BETWEEN '", 
				p_chart_clause[1,(l_fv_pos-1)],"' AND '", 
				p_chart_clause[(l_fv_pos+1),l_fv_len],"'" 
				EXIT FOR 
			WHEN p_chart_clause[l_fv_pos,l_fv_pos] = '*' 
				LET l_chart_slct = " AND account.chart_code matches '", 
				p_chart_clause clipped,"'" 
				EXIT FOR 
		END CASE 
	END FOR 

	IF l_chart_slct IS NULL THEN 
		LET l_chart_slct = " AND account.chart_code = '", 
		p_chart_clause clipped,"'" 
	END IF 

	RETURN l_chart_slct 

END FUNCTION 


############################################################
# FUNCTION operator_calc( p_amt, p_total, p_operator )
#
# Operator calculator
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
		WHEN p_operator = glob_rec_mrwparms.add_op 
			LET p_total = p_total + p_amt 
		WHEN p_operator = glob_rec_mrwparms.sub_op 
			LET p_total = p_total - p_amt 
		WHEN p_operator = glob_rec_mrwparms.div_op 
			#Check FOR divide by zero
			IF p_amt = 0 OR p_total = 0 THEN 
				LET p_total = 0 
			ELSE 
				LET p_total = p_total / p_amt 
			END IF 
		WHEN p_operator = glob_rec_mrwparms.mult_op 
			LET p_total = p_total * p_amt 

	END CASE 

	RETURN p_total 
END FUNCTION 


############################################################
# FUNCTION format_amount( p_value, p_width, p_picture )
#
# FORMAT amount
# Description  This FUNCTION formats the 'value' passed by the 'picture'
#              AND COLUMN width also passed.
############################################################
FUNCTION format_amount(p_value, p_width, p_picture) 
	DEFINE p_value DECIMAL(18,2) 
	DEFINE p_width LIKE rptcol.width 
	DEFINE p_picture LIKE rptcol.amt_picture 
	DEFINE l_rnd_value LIKE rndcode.rnd_value 
	DEFINE l_expected_sign LIKE glline.expected_sign 
	DEFINE l_rec_signcode RECORD LIKE signcode.* 
	DEFINE l_formatted CHAR(60) 
	DEFINE l_tmp_value CHAR(60) 

	IF p_value IS NULL THEN 
		LET p_value = 0 
	END IF 

	IF glob_rec_glline.always_print = "O" 
	OR glob_rec_calchead.always_print = "O" THEN # only PRINT IF non-zero 
		IF p_value = 0 THEN 
			LET l_formatted = " " 
			RETURN l_formatted 
		END IF 
	END IF 

	IF p_width IS NULL OR p_width = 0 
	THEN 
		LET l_formatted = " " 
		RETURN l_formatted 
	END IF 

	SELECT rnd_value INTO l_rnd_value FROM rndcode 
	WHERE rnd_code = glob_rec_rpthead.rnd_code 

	IF l_rnd_value > 0 AND l_rnd_value IS NOT NULL THEN 
		LET l_tmp_value = ( p_value / l_rnd_value ) USING "-----------------&" 
		LET p_value = l_tmp_value 
	END IF 

	# Work out sign code FOR displaying information.
	IF glob_rec_rptline.line_type = glob_rec_mrwparms.gl_line_type THEN 
		LET l_expected_sign = glob_rec_glline.expected_sign 
	END IF 
	IF glob_rec_rptline.line_type = glob_rec_mrwparms.calc_line_type THEN 
		LET l_expected_sign = glob_rec_calchead.expected_sign 
	END IF 

	IF glob_rec_signcode.sign_base = "L" THEN # sign = + : reverse IF sign differs. 
		   { IF signs differ THEN calculate using the following.
		     Eg.  Value        Expected         out-Come
		            +             +                +
		            -             +                -
		            +             -                -
		            -             -                + }
		IF l_expected_sign = "-" THEN 
			LET p_value = -1 * p_value 
		END IF 
	ELSE 
		#Sign = "Y" : Reverse all value signs.
		IF l_rec_signcode.sign_base = 'D' AND l_rec_signcode.sign_change = '-' THEN 

			LET p_value = -1 * p_value 
		END IF 
	END IF 

	LET l_formatted = p_value USING p_picture 
	LET l_formatted = l_formatted[1,p_width] 
	RETURN l_formatted 

END FUNCTION 


############################################################
# FUNCTION format_amount( fv_value, fv_width, fv_picture )
#
# CLEAR all REPORT accumulators.
############################################################
FUNCTION clear_accum() 

	DELETE FROM t_colaccum 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND rpt_id = glob_rec_rpthead.rpt_id 

END FUNCTION 


############################################################
# FUNCTION col_accum()
#
# check IF accumulator COLUMN.
############################################################
FUNCTION col_accum() 
	DEFINE l_accum_id LIKE saveline.accum_id 

	SELECT accum_id INTO l_accum_id FROM saveline 
	WHERE line_uid = glob_rec_rptline.line_uid 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 

	IF l_accum_id IS NULL THEN 
		LET l_accum_id = 0 
	END IF 

	RETURN l_accum_id 

END FUNCTION 


############################################################
# FUNCTION updt_accum( p_col_uid, p_accum_id, p_accum_add )
#
# Save REPORT COLUMN accumulator.
############################################################
FUNCTION updt_accum(p_col_uid, p_accum_id, p_accum_add) 
	DEFINE p_col_uid LIKE rptcol.col_uid 
	DEFINE p_accum_id LIKE colaccum.accum_id 
	DEFINE p_accum_add LIKE colaccum.accum_amt 
	DEFINE l_accum_amt LIKE colaccum.accum_amt 

	IF p_accum_add IS NULL THEN 
		LET p_accum_add = 0 
	END IF 

	#Check IF accumulator exist IF so THEN add accumulator amount.
	SELECT accum_amt INTO l_accum_amt FROM t_colaccum 
	WHERE col_uid = p_col_uid 
	AND accum_id = p_accum_id 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 

	IF status = NOTFOUND THEN 
		INSERT INTO t_colaccum VALUES ( glob_rec_kandoouser.cmpy_code, 
		glob_rec_rpthead.rpt_id, 
		p_col_uid, 
		p_accum_id, 
		p_accum_add ) 
	ELSE 
		IF l_accum_amt IS NULL THEN 
			LET l_accum_amt = 0 
		END IF 
		UPDATE t_colaccum 
		SET accum_amt = ( l_accum_amt + p_accum_add ) 
		WHERE col_uid = p_col_uid 
		AND accum_id = p_accum_id 
	END IF 

END FUNCTION 


############################################################
# FUNCTION column_accum_amt()
#
# COLUMN accumulated amount
# Description:     FUNCTION TO FETCH AND RETURN COLUMN accumulated amounts.
############################################################
FUNCTION column_accum_amt() 
	DEFINE l_operator LIKE calcline.operator 
	DEFINE l_accum_id LIKE calcline.accum_id 
	DEFINE l_col_id LIKE rptcol.col_id 
	DEFINE l_fmt_amt LIKE rptcoldesc.col_desc 
	DEFINE l_col_amt DECIMAL(18,2) 
	DEFINE l_col_total DECIMAL(18,2) 

	#Retrieve all COLUMN accumulator details FOR calculation.
	DECLARE calcline_curs CURSOR FOR 
	SELECT calcline.accum_id, 
	calcline.operator, 
	calcline.seq_num 
	FROM calcline 
	WHERE calcline.line_uid = glob_rec_rptline.line_uid 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	ORDER BY calcline.seq_num 


	LET l_col_total = 0 

	FOREACH calcline_curs INTO l_accum_id, l_operator 
		LET l_col_amt = 0 
		LET l_col_amt = fetch_colaccum_amt(l_accum_id) 
		# Perform operator calculation.
		LET l_col_total = operator_calc(l_col_amt, 
		l_col_total, 
		l_operator ) 
	END FOREACH 

	# Place value INTO Accumulator.
	LET l_accum_id = col_accum() 
	IF l_accum_id THEN 
		CALL updt_accum( glob_rec_rptcol.col_uid, l_accum_id, l_col_total ) 
	END IF 

	#Save COLUMN amount

	LET l_col_id = glob_rec_rptcol.col_id 
	LET glob_arr_colitem_amt[l_col_id] = l_col_total 
	LET l_fmt_amt = format_amount( l_col_total, 
	glob_rec_rptcol.width, 
	glob_rec_rptcol.amt_picture ) 
	RETURN l_fmt_amt 

END FUNCTION 


############################################################
# FUNCTION FETCH_colaccum_amt(p_accum_id)
#
# FETCH COLUMN accumulator amounts.
# Description:     FUNCTION TO retrieve accumlator amounts.
############################################################
FUNCTION fetch_colaccum_amt(p_accum_id) 
	DEFINE p_accum_id LIKE colaccum.accum_id 
	DEFINE l_accum_amt LIKE colaccum.accum_amt 

	SELECT accum_amt INTO l_accum_amt FROM t_colaccum 
	WHERE col_uid = glob_rec_rptcol.col_uid 
	AND accum_id = p_accum_id 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 

	RETURN l_accum_amt 

END FUNCTION 


############################################################
# FUNCTION external_amt(p_line_uid, p_col_uid)
#
# external REPORT accumulated amount
# Description:     FUNCTION TO FETCH AND RETURN external REPORT
#                  COLUMN accumulated amounts.
############################################################
FUNCTION external_amt(p_line_uid, p_col_uid) 
	DEFINE p_line_uid LIKE rptline.line_uid 
	DEFINE p_col_uid LIKE rptcol.col_uid 

	DEFINE l_accum_id LIKE calcline.accum_id 
	DEFINE l_col_id LIKE rptcol.col_id 
	DEFINE l_fmt_amt LIKE rptcoldesc.col_desc 
	DEFINE l_col_amt DECIMAL(18,2) 

	#Retrieve COLUMN accumulator amount FROM external link.
	SELECT t_colaccum.accum_amt 
	INTO l_col_amt 
	FROM extline, t_colaccum 
	WHERE extline.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND extline.rpt_id = glob_rec_rpthead.rpt_id 
	AND extline.col_uid = p_col_uid 
	AND extline.line_uid = p_line_uid 
	AND t_colaccum.cmpy_code = extline.ext_cmpy_code 
	AND t_colaccum.rpt_id = extline.ext_rpt_id 
	AND t_colaccum.col_uid = extline.ext_col_uid 
	AND t_colaccum.accum_id = extline.ext_accum_id 

	# Place value INTO Accumulator.
	LET l_accum_id = col_accum() 
	IF l_accum_id THEN 
		CALL updt_accum( glob_rec_rptcol.col_uid, l_accum_id, l_col_amt ) 
	END IF 

	#Save COLUMN amount
	LET l_col_id = glob_rec_rptcol.col_id 
	LET glob_arr_colitem_amt[l_col_id] = l_col_amt 
	LET l_fmt_amt = format_amount( l_col_amt, 
	glob_rec_rptcol.width, 
	glob_rec_rptcol.amt_picture ) 
	RETURN l_fmt_amt 

END FUNCTION 


############################################################
# FUNCTION analdown_clause()
#
# Analysis Down Clause
# Description   FUNCTION too RETURN 'WHERE clause' FOR retrieving the
#               account codes.
############################################################
FUNCTION analdown_clause() 
	DEFINE l_rec_segline RECORD LIKE segline.* 
	DEFINE l_rec_structure RECORD LIKE structure.* 
	DEFINE l_flex_slct CHAR(400) 
	DEFINE l_clause_slct CHAR(400) 
	DEFINE l_flex_clause LIKE segline.flex_clause 
	DEFINE l_first_time SMALLINT 
	DEFINE l_fv_pos INTEGER 
	DEFINE l_fv_len INTEGER 

	DECLARE andwn_curs CURSOR FOR 
	SELECT * FROM segline 
	WHERE line_uid = glob_rec_rptline.line_uid 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 

	LET l_flex_clause = NULL 
	LET l_clause_slct = NULL 

	FOREACH andwn_curs INTO l_rec_segline.* 
		SELECT * INTO l_rec_structure.* FROM structure 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND start_num = l_rec_segline.start_num 
		LET l_flex_clause = l_rec_segline.flex_clause 
		LET l_flex_slct = NULL 
		LET l_first_time = true 

		IF status != NOTFOUND THEN 

			LET l_fv_len = length(l_flex_clause) 

			FOR l_fv_pos = 1 TO l_fv_len 
				CASE 
					WHEN l_flex_clause[l_fv_pos,l_fv_pos] = ':' 
						LET l_flex_slct = 
						" AND account.acct_code[", l_rec_structure.start_num,",", 
						(l_rec_structure.start_num +l_rec_structure.length_num)-1, 
						"] between ", "'", l_flex_clause[1,(l_fv_pos-1)], "'", 
						" AND ", "'", l_flex_clause[(l_fv_pos+1),l_fv_len], "'" 
						EXIT FOR 
					WHEN l_flex_clause[l_fv_pos,l_fv_pos] = '*' 
						LET l_flex_slct = 
						" AND account.acct_code[", l_rec_structure.start_num, ",", 
						(l_rec_structure.start_num +l_rec_structure.length_num)-1, 
						"] matches '", l_flex_clause clipped, "'" 
						EXIT FOR 
					WHEN l_flex_clause[l_fv_pos,l_fv_pos] = '|' 
						IF l_first_time THEN 
							LET l_flex_slct = 
							" AND account.acct_code[", l_rec_structure.start_num, ",", 
							(l_rec_structure.start_num +l_rec_structure.length_num)-1, 
							"] in ('", l_flex_clause[1,(l_fv_pos-1)], "','", 
							l_flex_clause[(l_fv_pos+1),(l_fv_pos+2)], "'" 
							LET l_first_time = false 
						ELSE 
							LET l_flex_slct = 
							l_flex_slct clipped, ",'", 
							l_flex_clause[(l_fv_pos+1),(l_fv_pos+2)], "'" 
						END IF 
				END CASE 
			END FOR 

			IF NOT l_first_time THEN 
				LET l_flex_slct = l_flex_slct clipped, ") " 
			END IF 

			IF l_flex_slct IS NULL THEN 
				LET l_flex_slct = " AND account.acct_code[",l_rec_structure.start_num, 
				",", 
				(l_rec_structure.start_num+l_rec_structure.length_num)-1, 
				"]", 
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
# Description   FUNCTION too RETURN 'WHERE clause' FOR retrieving the
#               account codes.
############################################################
FUNCTION analacross_clause() 
	DEFINE l_rec_rptcolaa RECORD LIKE rptcolaa.* 
	DEFINE l_rec_structure RECORD LIKE structure.* 
	DEFINE l_flex_slct CHAR(400) 
	DEFINE l_clause_slct CHAR(400) 
	DEFINE l_flex_clause LIKE segline.flex_clause 
	DEFINE l_first_time SMALLINT 
	DEFINE l_fv_pos INTEGER 
	DEFINE l_fv_len INTEGER 

	DECLARE anacr_curs CURSOR FOR 
	SELECT * FROM rptcolaa 
	WHERE col_uid = glob_rec_rptcol.col_uid 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET l_flex_clause = NULL 
	FOREACH anacr_curs INTO l_rec_rptcolaa.* 
		SELECT * INTO l_rec_structure.* FROM structure 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND start_num = l_rec_rptcolaa.start_num 
		LET l_flex_clause = l_rec_rptcolaa.flex_clause 
		LET l_flex_slct = NULL 
		LET l_first_time = true 

		IF status != NOTFOUND THEN 

			LET l_fv_len = length(l_flex_clause) 

			FOR l_fv_pos = 1 TO l_fv_len 
				CASE 
					WHEN l_flex_clause[l_fv_pos,l_fv_pos] = ':' 
						LET l_flex_slct = 
						" AND account.acct_code[", l_rec_structure.start_num,",", 
						(l_rec_structure.start_num +l_rec_structure.length_num)-1, 
						"] between '", l_flex_clause[1,(l_fv_pos-1)], 
						"' AND '", l_flex_clause[(l_fv_pos+1),l_fv_len], "'" 
						EXIT FOR 
					WHEN l_flex_clause[l_fv_pos,l_fv_pos] = '*' 
						LET l_flex_slct = 
						" AND account.acct_code[", l_rec_structure.start_num, ",", 
						(l_rec_structure.start_num +l_rec_structure.length_num)-1, 
						"] matches '", l_flex_clause clipped, "'" 
						EXIT FOR 
					WHEN l_flex_clause[l_fv_pos,l_fv_pos] = '|' 
						IF l_first_time THEN 
							LET l_flex_slct = 
							" AND account.acct_code[", l_rec_structure.start_num, ",", 
							(l_rec_structure.start_num +l_rec_structure.length_num)-1, 
							"] in ('", l_flex_clause[1,(l_fv_pos-1)], "','", 
							l_flex_clause[(l_fv_pos+1),(l_fv_pos+2)], "'" 
							LET l_first_time = false 
						ELSE 
							LET l_flex_slct = 
							l_flex_slct clipped, ",'", 
							l_flex_clause[(l_fv_pos+1),(l_fv_pos+2)], "'" 
						END IF 
				END CASE 
			END FOR 

			IF NOT l_first_time THEN 
				LET l_flex_slct = l_flex_slct clipped, ") " 
			END IF 

			IF l_flex_slct IS NULL THEN 
				LET l_flex_slct =" AND account.acct_code[",l_rec_structure.start_num, 
				",", 
				(l_rec_structure.start_num+l_rec_structure.length_num)-1, 
				"]", 
				" = '", l_flex_clause clipped,"'" 

			END IF 

			LET l_clause_slct = l_clause_slct clipped, 
			l_flex_slct clipped 

		END IF 

	END FOREACH 

	RETURN l_clause_slct 

END FUNCTION 
