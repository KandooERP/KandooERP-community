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

	Source code beautified by beautify.pl on 2020-01-03 14:28:57	$Id: $
}



#  Non-text line accumulator maintenance
#  Used TO associate an accumulator with a non-text line.
#  Calculation line maintenance.
#  Used TO DEFINE the accumulators that will be used TO summed together.
#  Column description line maintenance.
#  Used TO DEFINE the COLUMN description in each line.
#  General Ledger line maintenance.
#  Used TO DEFINE the general ledger chart code range FOR the selected line.
#  text line maintenance.
#  Used TO DEFINE COLUMN description only lines.
#  Underline line maintenance.
#  Used TO DEFINE underline line.
#  Segment line analysis down.

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 
GLOBALS "../gl/GW4_GLOBALS.4gl" 


############################################################
# FUNCTION accum_maint(p_idx, p_line_uid)
#
# FUNCTION:        accumulator maintenance
# description:    INPUT the accumulator identifier.
#
############################################################
FUNCTION accum_maint(p_idx, p_line_uid) 
	DEFINE p_idx INTEGER 
	DEFINE p_line_uid INTEGER 
	DEFINE l_rec_saveline RECORD LIKE saveline.* 
	DEFINE l_msgresp LIKE language.yes_flag 

	#OPEN the maintenance window
	OPEN WINDOW g521 with FORM "G521" 
	CALL windecoration_g("G521") 

	IF p_line_uid > 0 AND p_line_uid IS NOT NULL THEN 
		SELECT accum_id INTO l_rec_saveline.accum_id FROM saveline 
		WHERE line_uid = p_line_uid 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	END IF 

	INPUT BY NAME l_rec_saveline.accum_id WITHOUT DEFAULTS 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GW4a","inp-saveline") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END INPUT 

	IF NOT (int_flag OR quit_flag) THEN 
		# Set rptline.accum_id array.
		LET glob_arr_rec_rptline[p_idx].accum_id = l_rec_saveline.accum_id 
		# Save accumulator line identifier.
		CALL accum_line(p_idx, p_line_uid) 
	END IF 

	LET int_flag = false 
	LET quit_flag = false 
	CLOSE WINDOW g521 

END FUNCTION 



############################################################
# FUNCTION accum_line(p_idx, p_line_uid)
#
# FUNCTION:     Accumulator line save.
# description:  This FUNCTION saves the accumulator id. that was entered
#                on the REPORT line.
############################################################
FUNCTION accum_line(p_idx, p_line_uid) 
	DEFINE p_idx INTEGER 
	DEFINE p_line_uid INTEGER 
	DEFINE l_msgresp LIKE language.yes_flag 

	#Delete existing saveline row.
	DELETE FROM saveline 
	WHERE line_uid = p_line_uid 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 

	INSERT INTO saveline VALUES ( glob_rec_kandoouser.cmpy_code, 
	glob_rec_rpthead.rpt_id, 
	p_line_uid, 
	glob_arr_rec_rptline[p_idx].accum_id ) 
END FUNCTION 



############################################################
# FUNCTION calcline_maint(p_line_uid)
#
# FUNCTION:        calculate line maintenance
# descripton:      INPUT FOR calculation lines.
#
############################################################
FUNCTION calcline_maint(p_line_uid) 
	DEFINE p_line_uid INTEGER 
	DEFINE l_count INTEGER 
	DEFINE l_calc_idx INTEGER 
	DEFINE l_calc_cnt INTEGER 
	DEFINE l_rec_calchead RECORD LIKE calchead.* 
	DEFINE l_rec_calcline RECORD LIKE calcline.* 
	DEFINE l_arr_rec_calcline DYNAMIC ARRAY OF RECORD -- array[2000] OF RECORD 
		accum_id LIKE calcline.accum_id, 
		operator LIKE calcline.operator 
	END RECORD 
	DEFINE l_msgresp LIKE language.yes_flag 

	#OPEN the maintenance window
	OPEN WINDOW g522 with FORM "G522" 
	CALL windecoration_g("G522") 

	#SELECT calcline details IF they exist. ( WHEN updating )
	DECLARE calc_curs CURSOR FOR 
	SELECT accum_id, operator FROM calcline 
	WHERE line_uid = p_line_uid 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	ORDER BY accum_id 
	LET l_calc_cnt = 0 
	IF p_line_uid > 0 AND p_line_uid IS NOT NULL THEN 

		#SELECT calc. header details IF they exist. ( WHEN updating )
		SELECT always_print, 
		print_in_offset, 
		expected_sign 
		INTO l_rec_calchead.always_print, 
		l_rec_calchead.print_in_offset, 
		l_rec_calchead.expected_sign 
		FROM calchead 
		WHERE line_uid = p_line_uid 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		FOREACH calc_curs INTO l_rec_calcline.accum_id, l_rec_calcline.operator 
			LET l_calc_cnt = l_calc_cnt + 1 
			LET l_arr_rec_calcline[l_calc_cnt].accum_id = l_rec_calcline.accum_id 
			LET l_arr_rec_calcline[l_calc_cnt].operator = l_rec_calcline.operator 

			IF l_calc_cnt < 11 THEN 
				DISPLAY l_rec_calcline.accum_id, l_rec_calcline.operator 
				TO sa_calcline[l_calc_cnt].accum_id, 
				sa_calcline[l_calc_cnt].operator 

			END IF 

		END FOREACH 
	END IF 

	IF l_rec_calchead.always_print IS NULL THEN 
		LET l_rec_calchead.always_print = glob_rec_rpthead.always_print_line 
	END IF 

	IF l_rec_calchead.print_in_offset IS NULL THEN 
		LET l_rec_calchead.print_in_offset = "N" 
	END IF 

	IF l_rec_calchead.expected_sign IS NULL THEN 
		LET l_rec_calchead.expected_sign = glob_rec_mrwparms.add_op 
	END IF 


	INPUT BY NAME l_rec_calchead.always_print, 
	l_rec_calchead.print_in_offset, 
	l_rec_calchead.expected_sign WITHOUT DEFAULTS 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GW4a","inp-calchead") 


		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE FIELD always_print 
			IF l_rec_calchead.always_print IS NULL THEN 
				LET l_rec_calchead.always_print= glob_rec_rpthead.always_print_line 
			END IF 

		BEFORE FIELD expected_sign 
			IF l_rec_calchead.expected_sign IS NULL THEN 
				LET l_rec_calchead.expected_sign = glob_rec_mrwparms.add_op 
			END IF 

		AFTER FIELD expected_sign 
			CASE 
				WHEN l_rec_calchead.expected_sign = glob_rec_mrwparms.add_op 
				WHEN l_rec_calchead.expected_sign = glob_rec_mrwparms.sub_op 
				OTHERWISE 
					LET l_msgresp = kandoomsg("U",9112,"expected sign. Valid VALUES are (+,-)") 
					#9112 "Invalid expected sign."
					NEXT FIELD expected_sign 
			END CASE 

			--   ON KEY (control-w)
			--      CALL kandoohelp("")
	END INPUT 

	IF NOT (int_flag OR quit_flag) THEN 

		#Delete existing calchead row.
		DELETE FROM calchead 
		WHERE line_uid = p_line_uid 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		INSERT INTO calchead VALUES ( glob_rec_kandoouser.cmpy_code, 
		glob_rec_rpthead.rpt_id, 
		p_line_uid, 
		l_rec_calchead.always_print, 
		l_rec_calchead.print_in_offset, 
		l_rec_calchead.expected_sign ) 
	ELSE 
		CLOSE WINDOW g522 
		RETURN 
	END IF 

	# Now INPUT calculation lines.

	CALL set_count(l_calc_cnt) 
	INPUT ARRAY l_arr_rec_calcline WITHOUT DEFAULTS FROM sa_calcline.* attributes(UNBUFFERED) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GW4a","inp-arr-calcline") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET l_calc_idx = arr_curr() 
			LET l_calc_cnt = arr_count() 

		AFTER ROW 
			IF l_calc_cnt > 2000 THEN 
				LET l_msgresp = kandoomsg("U",9001,"") 
				LET l_calc_cnt = 2000 
				NEXT FIELD accum_id 
			END IF 

		AFTER FIELD accum_id 
			IF l_arr_rec_calcline[l_calc_idx].accum_id IS NOT NULL AND 
			l_arr_rec_calcline[l_calc_idx].accum_id > 0 THEN 
				# Check that the accumulator exists FOR this REPORT.
				SELECT count(*) INTO l_count FROM saveline 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND rpt_id = glob_rec_rpthead.rpt_id 
				AND accum_id = l_arr_rec_calcline[l_calc_idx].accum_id 
				IF l_count = 0 OR l_count IS NULL THEN 
					LET l_msgresp = kandoomsg("U",9910,"") 
					#9910 RECORD NOT found.
					NEXT FIELD accum_id 
				END IF 
			ELSE 
				LET l_arr_rec_calcline[l_calc_idx].accum_id = NULL 
			END IF 

		AFTER FIELD operator 
			CASE 
				WHEN l_arr_rec_calcline[l_calc_idx].operator = glob_rec_mrwparms.add_op 
				WHEN l_arr_rec_calcline[l_calc_idx].operator = glob_rec_mrwparms.sub_op 
				OTHERWISE 
					IF l_arr_rec_calcline[l_calc_idx].accum_id IS NOT NULL THEN 
						LET l_msgresp = kandoomsg("U",9112,"expected sign. Valid VALUES are (+,-)") 
						#9112 "Invalid expected sign. Valid VALUES are (+,-)"
						NEXT FIELD operator 
					END IF 
			END CASE 

			--   ON KEY (control-w)
			--      CALL kandoohelp("")
	END INPUT 

	IF NOT (int_flag OR quit_flag) THEN 
		DELETE FROM calcline 
		WHERE line_uid = p_line_uid 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		FOR l_calc_idx = 1 TO l_calc_cnt 
			IF l_arr_rec_calcline[l_calc_idx].accum_id IS NOT NULL THEN 
				INSERT INTO calcline 
				VALUES ( glob_rec_kandoouser.cmpy_code, 
				glob_rec_rpthead.rpt_id, 
				p_line_uid, 
				l_calc_idx, 
				l_arr_rec_calcline[l_calc_idx].accum_id, 
				l_arr_rec_calcline[l_calc_idx].operator ) 
			END IF 
		END FOR 
	END IF 
	CLOSE WINDOW g522 

END FUNCTION 





############################################################
# FUNCTION desc_maint(p_idx, p_line_uid)
#
# FUNCTION:     Description line maintenance.
# desciption:   INPUT of desciption columns as SET within the COLUMN
#               maintenance program.
############################################################
FUNCTION desc_maint(p_idx, p_line_uid) 
	DEFINE p_idx INTEGER 
	DEFINE p_line_uid INTEGER 

	DEFINE l_col_uid INTEGER 
	DEFINE l_start_pos INTEGER 
	DEFINE l_end_pos INTEGER 
	DEFINE l_width INTEGER 
	DEFINE l_desc_len INTEGER 
	DEFINE l_desc_idx INTEGER 
	DEFINE l_desc_cnt INTEGER 
	DEFINE l_chart_clause LIKE gllinedetl.chart_clause 
	DEFINE l_slct CHAR(500) 
	DEFINE l_rec_descline RECORD 
		col_id LIKE rptcol.col_id, 
		line_desc LIKE descline.line_desc 
	END RECORD 

	DEFINE l_arr_rec_descline DYNAMIC ARRAY OF RECORD -- array[2000] OF RECORD 
		col_id LIKE rptcol.col_id, 
		line_desc LIKE descline.line_desc 
	END RECORD 

	DEFINE l_acct_code LIKE account.acct_code 
	DEFINE l_msgresp LIKE language.yes_flag 

	OPTIONS INSERT KEY f26 
	OPTIONS DELETE KEY f21 

	#OPEN the maintenance window
	OPEN WINDOW g523 with FORM "G523" 
	CALL windecoration_g("G523") 

	#SELECT description line details.

	DECLARE descline_curs CURSOR FOR 
	SELECT rptcol.col_id, 
	descline.line_desc 
	FROM rptcol, 
	colitem, 
	mrwitem, 
	outer(descline) 
	WHERE colitem.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND colitem.rpt_id = glob_rec_rpthead.rpt_id 
	AND rptcol.col_uid = colitem.col_uid 
	AND colitem.seq_num = 1 ## one entry only FOR desc LINES 
	AND mrwitem.item_id = colitem.col_item 
	AND mrwitem.item_type = glob_rec_mrwparms.constant_item_type 
	AND descline.line_uid = p_line_uid 
	AND descline.col_uid = colitem.col_uid 
	AND rptcol.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND descline.cmpy_code = glob_rec_kandoouser.cmpy_code 
	ORDER BY rptcol.col_id 

	LET l_desc_cnt = 0 
	FOREACH descline_curs INTO l_rec_descline.col_id, l_rec_descline.line_desc 
		LET l_desc_cnt = l_desc_cnt + 1 
		LET l_arr_rec_descline[l_desc_cnt].col_id = l_rec_descline.col_id 
		LET l_arr_rec_descline[l_desc_cnt].line_desc = l_rec_descline.line_desc 
		IF l_desc_cnt < 6 THEN 
			DISPLAY l_rec_descline.col_id, l_rec_descline.line_desc 
			TO sa_descline[l_desc_cnt].col_id, 
			sa_descline[l_desc_cnt].line_desc 

		END IF 
	END FOREACH 

	#IF a specific general ledger chart code has been nominated FOR the
	# line (Not a chart range) THEN default the first line_desc TO
	# coa.desc_text

	IF l_arr_rec_descline[1].line_desc IS NULL AND 
	glob_arr_rec_rptline[p_idx].line_type = glob_rec_mrwparms.gl_line_type THEN 

		INITIALIZE l_chart_clause TO NULL 

		SELECT chart_clause INTO l_chart_clause FROM gllinedetl 
		WHERE line_uid = p_line_uid 
		AND seq_num = 1 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		IF status != NOTFOUND THEN 
			SELECT start_num, (start_num+length_num) 
			INTO l_start_pos, l_end_pos 
			FROM structure 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND type_ind = "C" 
			LET l_slct = "SELECT desc_text ", 
			"FROM coa ", 
			"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"'", 
			" AND acct_code[",l_start_pos,",",l_end_pos,"]", 
			" matches '",l_chart_clause clipped,"'" 

			WHENEVER ERROR CONTINUE #if l_chart_clause IS invalid. 

			PREPARE s_1 FROM l_slct 
			DECLARE chart_curs CURSOR FOR s_1 

			OPEN chart_curs 
			FETCH chart_curs INTO l_arr_rec_descline[1].line_desc 
			CLOSE chart_curs 
			WHENEVER ERROR stop 
		END IF 

	END IF 

	CALL set_count(l_desc_cnt) 
	INPUT ARRAY l_arr_rec_descline WITHOUT DEFAULTS FROM sa_descline.* attributes(UNBUFFERED) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GW4a","inp-arr-descline") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET l_desc_idx = arr_curr() 
			IF l_desc_idx > l_desc_cnt THEN 
				LET l_msgresp = kandoomsg("U",9001,"") 
				#9001 No more rows in this direction.
				NEXT FIELD line_desc 
			END IF 


		AFTER FIELD line_desc 
			# Warn the user IF the line description exceeds the COLUMN width.
			SELECT width INTO l_width FROM rptcol 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND rpt_id = glob_rec_rpthead.rpt_id 
			AND col_id = l_arr_rec_descline[l_desc_idx].col_id 
			LET l_desc_len = length( l_arr_rec_descline[l_desc_idx].line_desc ) 
			IF l_desc_len > l_width THEN 
				LET l_msgresp = kandoomsg("G",6000,"") 
				#6000 "WARNING: Description length exceeds defined COLUMN width."
			END IF 

			--   ON KEY (control-w)
			--      CALL kandoohelp("")
	END INPUT 

	OPTIONS INSERT KEY f1 
	OPTIONS DELETE KEY f2 

	IF NOT (int_flag OR quit_flag) THEN 
		#Delete existing descline row.
		DELETE FROM descline 
		WHERE line_uid = p_line_uid 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		FOR l_desc_idx = 1 TO l_desc_cnt 
			IF l_arr_rec_descline[l_desc_idx].line_desc IS NOT NULL THEN 
				# SELECT the COLUMN unique identifier.
				SELECT col_uid INTO l_col_uid FROM rptcol 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND rpt_id = glob_rec_rpthead.rpt_id 
				AND col_id = l_arr_rec_descline[l_desc_idx].col_id 
				INSERT INTO descline VALUES ( glob_rec_kandoouser.cmpy_code, 
				glob_rec_rpthead.rpt_id, 
				p_line_uid, 
				l_col_uid, 
				l_arr_rec_descline[l_desc_idx].col_id, 
				l_arr_rec_descline[l_desc_idx].line_desc) 
			END IF 
		END FOR 

		# Set rptline.line_desc TO the first line_desc in the array.
		LET glob_arr_rec_rptline[p_idx].line_desc = l_arr_rec_descline[1].line_desc 

	ELSE 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 
	CLOSE WINDOW g523 

END FUNCTION 


############################################################
# FUNCTION glline_maint(p_line_uid)
#
# FUNCTION:     General ledger line maintenance.
# description:  INPUT FOR general ledger header details AND chart code
#                selection clause.
############################################################
FUNCTION glline_maint(p_line_uid) 
	DEFINE p_line_uid INTEGER 

	DEFINE l_idx INTEGER 
	DEFINE l_gldtl_cnt INTEGER 
	DEFINE l_glidx INTEGER 
	DEFINE l_rec_glline RECORD LIKE glline.* 
	DEFINE l_rec_gllinedetl RECORD LIKE gllinedetl.* 
	DEFINE l_arr_rec_gllinedetl DYNAMIC ARRAY OF RECORD -- array[2000] OF RECORD 
		operator LIKE gllinedetl.operator, 
		chart_clause LIKE gllinedetl.chart_clause 
	END RECORD 
	DEFINE l_msgresp LIKE language.yes_flag 

	#OPEN the maintenance window
	OPEN WINDOW g524 with FORM "G524" 
	CALL windecoration_g("G524") 

	IF p_line_uid > 0 AND p_line_uid IS NOT NULL THEN 
		#SELECT glline details IF they exist. ( WHEN updating )
		SELECT always_print, 
		print_in_offset, 
		expected_sign 
		INTO l_rec_glline.always_print, 
		l_rec_glline.print_in_offset, 
		l_rec_glline.expected_sign 
		FROM glline 
		WHERE line_uid = p_line_uid 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	END IF 

	IF l_rec_glline.always_print IS NULL THEN 
		LET l_rec_glline.always_print = glob_rec_rpthead.always_print_line 
	END IF 
	IF l_rec_glline.print_in_offset IS NULL THEN 
		LET l_rec_glline.print_in_offset = "N" 
	END IF 
	IF l_rec_glline.expected_sign IS NULL THEN 
		LET l_rec_glline.expected_sign = glob_rec_mrwparms.add_op 
	END IF 
	#SELECT gllinedetl details IF they exist FROM temp table. (WHEN updating)
	DECLARE gldetl_curs CURSOR FOR 
	SELECT chart_clause, operator FROM gllinedetl 
	WHERE line_uid = p_line_uid 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 

	LET l_gldtl_cnt = 0 
	FOREACH gldetl_curs INTO l_rec_gllinedetl.chart_clause, l_rec_gllinedetl.operator 
		LET l_gldtl_cnt = l_gldtl_cnt + 1 
		LET l_arr_rec_gllinedetl[l_gldtl_cnt].chart_clause = l_rec_gllinedetl.chart_clause 
		LET l_arr_rec_gllinedetl[l_gldtl_cnt].operator = l_rec_gllinedetl.operator 

		IF l_gldtl_cnt < 7 THEN 
			DISPLAY l_rec_gllinedetl.operator, l_rec_gllinedetl.chart_clause 
			TO sa_gllinedetl[l_gldtl_cnt].operator, 
			sa_gllinedetl[l_gldtl_cnt].chart_clause 

		END IF 

	END FOREACH 

	INPUT BY NAME l_rec_glline.always_print, 
	l_rec_glline.print_in_offset, 
	l_rec_glline.expected_sign WITHOUT DEFAULTS 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GW4a","inp-glline") 


		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE FIELD always_print 
			IF l_rec_glline.always_print IS NULL THEN 
				LET l_rec_glline.always_print= glob_rec_rpthead.always_print_line 
			END IF 

		BEFORE FIELD expected_sign 
			IF l_rec_glline.expected_sign IS NULL THEN 
				LET l_rec_glline.expected_sign = glob_rec_mrwparms.add_op 
			END IF 

		AFTER FIELD expected_sign 
			CASE 
				WHEN l_rec_glline.expected_sign = glob_rec_mrwparms.add_op 
				WHEN l_rec_glline.expected_sign = glob_rec_mrwparms.sub_op 
				OTHERWISE 
					LET l_msgresp = kandoomsg("U",9112,"expected sign. Valid VALUES are (+,-)") 
					#9112 "Invalid expected sign."
					NEXT FIELD expected_sign 
			END CASE 

			--   ON KEY (control-w)
			--      CALL kandoohelp("")
	END INPUT 

	IF int_flag OR quit_flag THEN 
		CLOSE WINDOW g524 
		RETURN 
	END IF 

	CALL set_count(l_gldtl_cnt) 
	INPUT ARRAY l_arr_rec_gllinedetl WITHOUT DEFAULTS FROM sa_gllinedetl.* attributes(UNBUFFERED) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GW4a","inp-arr-gllinedetl") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		BEFORE ROW 
			LET l_glidx = arr_curr() 
			LET l_gldtl_cnt = arr_count() 
			IF l_gldtl_cnt > 2000 THEN 
				LET l_msgresp = kandoomsg("U",9001,"") 
				#9001 No more rows in this direction
				LET l_gldtl_cnt = 2000 
				NEXT FIELD chart_code 
			END IF 

		BEFORE FIELD operator 
			IF l_arr_rec_gllinedetl[l_glidx].operator IS NULL THEN 
				LET l_arr_rec_gllinedetl[l_glidx].operator = glob_rec_mrwparms.add_op 
			END IF 


		AFTER FIELD operator 
			CASE 
				WHEN l_arr_rec_gllinedetl[l_glidx].operator = glob_rec_mrwparms.add_op 
				WHEN l_arr_rec_gllinedetl[l_glidx].operator = glob_rec_mrwparms.sub_op 
				WHEN l_arr_rec_gllinedetl[l_glidx].operator = glob_rec_mrwparms.div_op 
				WHEN l_arr_rec_gllinedetl[l_glidx].operator = glob_rec_mrwparms.mult_op 
				WHEN l_arr_rec_gllinedetl[l_glidx].operator = " " 
				WHEN l_arr_rec_gllinedetl[l_glidx].operator IS NULL 
				OTHERWISE 
					LET l_msgresp = kandoomsg("U",9112,"mathematical operator") 
					#9112 "Invalid mathematical operator."
					NEXT FIELD operator 
			END CASE 

		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN 
				FOR l_glidx = 1 TO l_gldtl_cnt 
					IF l_arr_rec_gllinedetl[l_glidx].chart_clause IS NOT NULL THEN 
						CASE 
							WHEN l_arr_rec_gllinedetl[l_glidx].operator = glob_rec_mrwparms.add_op 
							WHEN l_arr_rec_gllinedetl[l_glidx].operator = glob_rec_mrwparms.sub_op 
							WHEN l_arr_rec_gllinedetl[l_glidx].operator = glob_rec_mrwparms.div_op 
							WHEN l_arr_rec_gllinedetl[l_glidx].operator = glob_rec_mrwparms.mult_op 
							OTHERWISE 
								LET l_msgresp = kandoomsg("U",9112,"mathematical operator within the chart clauses") 
								#9112 "Invalid math operator within the chart clauses."
								NEXT FIELD operator 
						END CASE 
					END IF 
				END FOR 
			END IF 

			--   ON KEY (control-w)
			--      CALL kandoohelp("")
	END INPUT 

	IF NOT (int_flag OR quit_flag) THEN 
		#Delete existing glline row.
		DELETE FROM glline 
		WHERE line_uid = p_line_uid 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		INSERT INTO glline VALUES ( glob_rec_kandoouser.cmpy_code, 
		glob_rec_rpthead.rpt_id, 
		p_line_uid, 
		l_rec_glline.always_print, 
		l_rec_glline.print_in_offset, 
		l_rec_glline.expected_sign ) 
		DELETE FROM gllinedetl 
		WHERE line_uid = p_line_uid 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		FOR l_glidx = 1 TO l_gldtl_cnt 
			IF l_arr_rec_gllinedetl[l_glidx].chart_clause IS NOT NULL THEN 
				INSERT INTO gllinedetl 
				VALUES ( glob_rec_kandoouser.cmpy_code, 
				glob_rec_rpthead.rpt_id, 
				p_line_uid, 
				l_glidx, 
				l_arr_rec_gllinedetl[l_glidx].chart_clause, 
				l_arr_rec_gllinedetl[l_glidx].operator ) 
			END IF 
		END FOR 
	END IF 
	CLOSE WINDOW g524 

END FUNCTION 



############################################################
# FUNCTION txt_maint(p_idx, p_line_uid)
#
#
############################################################
FUNCTION txt_maint(p_idx, p_line_uid) 
	DEFINE p_idx INTEGER 
	DEFINE p_line_uid INTEGER 
	DEFINE l_msgresp LIKE language.yes_flag 

	CALL desc_maint(p_idx, p_line_uid) 

END FUNCTION 



############################################################
# FUNCTION underline_maint(p_idx, p_line_uid)
#
#
############################################################
FUNCTION underline_maint(p_idx, p_line_uid) 
	DEFINE p_idx INTEGER 
	DEFINE p_line_uid INTEGER 

	DEFINE l_txtidx INTEGER 
	DEFINE l_txttype_desc LIKE txttype.txttype_desc 
	DEFINE l_rec_txtline RECORD LIKE txtline.* 
	DEFINE l_msgresp LIKE language.yes_flag 

	#OPEN the maintenance window
	OPEN WINDOW g516 with FORM "G516" 
	CALL windecoration_g("G516") 

	IF p_line_uid > 0 AND p_line_uid IS NOT NULL THEN 
		SELECT txt_type INTO l_rec_txtline.txt_type FROM txtline 
		WHERE line_uid = p_line_uid 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	END IF 
	SELECT txttype_desc INTO l_txttype_desc FROM txttype 
	WHERE txttype_id = l_rec_txtline.txt_type 
	DISPLAY l_txttype_desc TO txttype_desc 

	INPUT BY NAME l_rec_txtline.txt_type WITHOUT DEFAULTS 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GW4a","inp-txtline") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON KEY ( control-b ) 
			LET l_rec_txtline.txt_type = show_txttype( l_rec_txtline.txt_type ) 
			IF l_rec_txtline.txt_type IS NOT NULL THEN 
				DISPLAY BY NAME l_rec_txtline.txt_type 

				SELECT txttype_desc INTO l_txttype_desc FROM txttype 
				WHERE txttype_id = l_rec_txtline.txt_type 
				IF status = NOTFOUND THEN 
					LET l_msgresp = kandoomsg("U",9105,"") 
					#9105 "Record NOT found. Try Window."
					NEXT FIELD txt_type 
				ELSE 
					DISPLAY l_txttype_desc TO txttype_desc 

				END IF 
			END IF 

		AFTER FIELD txt_type 
			IF l_rec_txtline.txt_type IS NOT NULL THEN 
				SELECT txttype_desc INTO l_txttype_desc FROM txttype 
				WHERE txttype_id = l_rec_txtline.txt_type 
				IF status = NOTFOUND THEN 
					LET l_msgresp = kandoomsg("U",9105,"") 
					#9105 "Record NOT found. Try Window."
					NEXT FIELD txt_type 
				ELSE 
					DISPLAY l_txttype_desc TO txttype_desc 

				END IF 
			END IF 
			--   ON KEY (control-w)
			--      CALL kandoohelp("")
	END INPUT 

	IF NOT (int_flag OR quit_flag) THEN 
		#Delete existing txtline row.
		DELETE FROM txtline 
		WHERE line_uid = p_line_uid 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		INSERT INTO txtline VALUES ( glob_rec_kandoouser.cmpy_code, 
		glob_rec_rpthead.rpt_id, 
		p_line_uid, 
		l_rec_txtline.txt_type ) 

		# Set rptline.line_desc TO the first line_desc in the array.
		LET glob_arr_rec_rptline[p_idx].line_desc = l_txttype_desc 
	END IF 

	LET int_flag = false 
	LET quit_flag = false 
	CLOSE WINDOW g516 

END FUNCTION 


############################################################
# FUNCTION underline_maint(l_idx, p_line_uid)
#
# FUNCTION:        seg_anal_down()
# Description:     FUNCTION FOR entry of analysis down section REPORT.
############################################################
FUNCTION seg_anal_down(p_line_id, p_line_uid) 
	DEFINE p_line_id INTEGER 
	DEFINE p_line_uid INTEGER 

	DEFINE l_arr_rec_segline DYNAMIC ARRAY OF RECORD -- array[100] OF RECORD 
		start_num LIKE segline.start_num, 
		flex_clause LIKE segline.flex_clause 
	END RECORD 
	DEFINE l_segline RECORD LIKE segline.* 
	DEFINE l_sad_cnt INTEGER 
	--	DEFINE fv_scrn INTEGER
	DEFINE l_idx INTEGER 
	DEFINE l_msgresp LIKE language.yes_flag 

	# Check IF the REPORT type IS of an analysis across type.
	IF glob_rec_rpthead.rpt_type != glob_rec_mrwparms.analdown_type THEN 
		LET l_msgresp = kandoomsg("G",9207,"") 
		#9207 "Report IS NOT an Analysis down type."
		RETURN 
	END IF 

	#OPEN the maintenance window
	OPEN WINDOW g526 with FORM "G526" 
	CALL windecoration_g("G526") 

	#SELECT segment COLUMN details.

	DECLARE segline_curs CURSOR FOR 
	SELECT segline.* FROM segline 
	WHERE segline.line_uid = p_line_uid 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 

	LET l_sad_cnt = 0 
	FOREACH segline_curs INTO l_segline.* 
		LET l_sad_cnt = l_sad_cnt + 1 
		LET l_arr_rec_segline[l_sad_cnt].start_num = l_segline.start_num 
		LET l_arr_rec_segline[l_sad_cnt].flex_clause = l_segline.flex_clause 
		IF l_sad_cnt < 6 THEN 
			DISPLAY l_arr_rec_segline[l_sad_cnt].start_num, 
			l_arr_rec_segline[l_sad_cnt].flex_clause 
			TO sa_segline[l_sad_cnt].start_num, 
			sa_segline[l_sad_cnt].flex_clause 

		END IF 
	END FOREACH 

	DISPLAY p_line_id TO line_id 

	CALL set_count(l_sad_cnt) 
	INPUT ARRAY l_arr_rec_segline WITHOUT DEFAULTS FROM sa_segline.* attributes(UNBUFFERED) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GW4a","inp-arr-segline") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield(flex_clause) 
			CALL show_flex(glob_rec_kandoouser.cmpy_code, l_arr_rec_segline[l_idx].start_num) 
			RETURNING l_arr_rec_segline[l_idx].flex_clause 
			#DISPLAY l_arr_rec_segline[l_idx].flex_clause
			#     TO sa_segline[fv_scrn].flex_clause


		BEFORE ROW 
			LET l_idx = arr_curr() 
			#LET fv_scrn = scr_line()
			IF l_idx > 99 THEN 
				LET l_msgresp = kandoomsg("U",9001,"") 
				#9001 No more rows in that direction
				LET l_idx = 100 
				NEXT FIELD start_num 
			END IF 

		BEFORE FIELD start_num 
			IF l_arr_rec_segline[l_idx].start_num = 0 THEN 
				LET l_arr_rec_segline[l_idx].start_num = NULL 
			END IF 

		AFTER FIELD start_num 
			IF l_arr_rec_segline[l_idx].start_num IS NOT NULL THEN 
				# Check that this IS a valid start_num FROM within the structure table.
				SELECT * FROM structure 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND start_num = l_arr_rec_segline[l_idx].start_num 
				IF status THEN 
					LET l_msgresp = kandoomsg("U",9112,"start number FROM within the account structure") 
					#9112 "Invalid start number FROM within the account structure."
					NEXT FIELD start_num 
				END IF 
			END IF 
			--   ON KEY (control-w)
			--      CALL kandoohelp("")
	END INPUT 

	LET l_sad_cnt = arr_count() 
	IF NOT (int_flag OR quit_flag) THEN 
		#Delete existing descline row.
		DELETE FROM segline 
		WHERE line_uid = p_line_uid 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 

		FOR l_idx = 1 TO l_sad_cnt 
			IF l_arr_rec_segline[l_idx].flex_clause IS NOT NULL THEN 
				INSERT INTO segline VALUES ( glob_rec_kandoouser.cmpy_code, 
				gr_rptline.rpt_id, 
				p_line_uid, 
				l_idx, 
				l_arr_rec_segline[l_idx].start_num, 
				l_arr_rec_segline[l_idx].flex_clause) 
			END IF 
		END FOR 

	END IF 

	LET int_flag = false 
	LET quit_flag = false 
	CLOSE WINDOW g526 

END FUNCTION 


############################################################
# FUNCTION extline_maint(p_line_id, p_line_uid)
#
#  FUNCTION:        external_link()
#  Description:     FUNCTION FOR entry of external links
############################################################
FUNCTION extline_maint(p_line_id, p_line_uid) 
	DEFINE p_line_id INTEGER 
	DEFINE p_line_uid INTEGER 

	DEFINE l_arr_rec_extline DYNAMIC ARRAY OF RECORD -- array[100] OF RECORD 
		col_id LIKE rptcol.col_id, 
		ext_cmpy_code LIKE extline.cmpy_code, 
		ext_rpt_id LIKE extline.rpt_id, 
		ext_col_id LIKE rptcol.col_id, 
		ext_accum_id LIKE extline.ext_accum_id 
	END RECORD 

	DEFINE l_rec_extline RECORD LIKE extline.* 
	DEFINE l_rec_rptcol RECORD LIKE rptcol.* 
	DEFINE l_count INTEGER 
	DEFINE l_col_id INTEGER 
	DEFINE l_ext_col_uid INTEGER 
	DEFINE l_col_uid INTEGER 
	DEFINE l_ext_cnt INTEGER 
	--	DEFINE fv_scrn INTEGER
	DEFINE l_idx INTEGER 
	DEFINE l_msgresp LIKE language.yes_flag 

	OPTIONS INSERT KEY f26, 
	DELETE KEY f21 

	#OPEN the maintenance window
	OPEN WINDOW g528 with FORM "G528" 
	CALL windecoration_g("G528") 

	#SELECT COLUMN details.
	DECLARE rptcol_curs CURSOR FOR 
	SELECT unique rptcol.col_uid FROM rptcol, colitem, mrwitem 
	WHERE rptcol.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND colitem.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND rptcol.rpt_id = glob_rec_rpthead.rpt_id 
	AND colitem.col_uid = rptcol.col_uid 
	AND mrwitem.item_id = colitem.col_item 
	AND mrwitem.item_type != glob_rec_mrwparms.constant_item_type 
	LET l_ext_cnt = 0 

	FOREACH rptcol_curs INTO l_col_uid 
		LET l_ext_cnt = l_ext_cnt + 1 
		IF l_ext_cnt > 100 THEN 
			LET l_msgresp = kandoomsg("U",6100,l_ext_cnt) 
			#6100 First l_ext_cnt records selected.
			EXIT FOREACH 
		END IF 
		SELECT * INTO l_rec_rptcol.* FROM rptcol 
		WHERE col_uid = l_col_uid 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET l_arr_rec_extline[l_ext_cnt].col_id = l_rec_rptcol.col_id 
		#SELECT external link details FOR this COLUMN.
		SELECT * INTO l_rec_extline.* FROM extline 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND rpt_id = glob_rec_rpthead.rpt_id 
		AND line_uid = p_line_uid 
		AND col_uid = l_col_uid 
		IF status = NOTFOUND THEN 
			LET l_arr_rec_extline[l_ext_cnt].ext_cmpy_code = NULL 
			LET l_arr_rec_extline[l_ext_cnt].ext_rpt_id = NULL 
			LET l_arr_rec_extline[l_ext_cnt].ext_accum_id = NULL 
			LET l_arr_rec_extline[l_ext_cnt].ext_col_id = NULL 
		ELSE 
			LET l_arr_rec_extline[l_ext_cnt].ext_cmpy_code = l_rec_extline.ext_cmpy_code 
			LET l_arr_rec_extline[l_ext_cnt].ext_rpt_id = l_rec_extline.ext_rpt_id 
			LET l_arr_rec_extline[l_ext_cnt].ext_accum_id = l_rec_extline.ext_accum_id 
			# Column id FOR this col_uid
			SELECT col_id INTO l_arr_rec_extline[l_ext_cnt].ext_col_id FROM rptcol 
			WHERE col_uid = l_rec_extline.ext_col_uid 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		END IF 
		IF l_ext_cnt < 6 THEN 
			DISPLAY l_arr_rec_extline[l_ext_cnt].col_id, 
			l_arr_rec_extline[l_ext_cnt].ext_cmpy_code, 
			l_arr_rec_extline[l_ext_cnt].ext_rpt_id, 
			l_arr_rec_extline[l_ext_cnt].ext_col_id, 
			l_arr_rec_extline[l_ext_cnt].ext_accum_id 
			TO sa_extline[l_ext_cnt].col_id, 
			sa_extline[l_ext_cnt].ext_cmpy_code, 
			sa_extline[l_ext_cnt].ext_rpt_id, 
			sa_extline[l_ext_cnt].ext_col_id, 
			sa_extline[l_ext_cnt].ext_accum_id 

		END IF 
	END FOREACH 

	LET l_msgresp = kandoomsg("U",9113,l_ext_cnt) 
	#9113 l_ext_cnt records selected.
	DISPLAY glob_rec_kandoouser.cmpy_code, glob_rec_rpthead.rpt_id, p_line_id 
	TO cmpy_code, rpt_id, line_id 

	CALL set_count(l_ext_cnt) 
	INPUT ARRAY l_arr_rec_extline WITHOUT DEFAULTS FROM sa_extline.* attributes(UNBUFFERED) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GW4a","inp-arr-extline") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		BEFORE ROW 
			LET l_idx = arr_curr() 
			#LET fv_scrn = scr_line()
			IF l_idx > 99 THEN 
				LET l_msgresp = kandoomsg("U",9001,"") 
				#9001 "There are no more rows in the direction you are going."
				LET l_idx = 100 
				NEXT FIELD ext_cmpy_code 
			END IF 
			IF l_idx > l_ext_cnt THEN 
				LET l_msgresp = kandoomsg("U",9001,"") 
				#9001 "There are no more rows in the direction you are going."
			END IF 

		AFTER FIELD ext_cmpy_code 
			IF l_arr_rec_extline[l_idx].ext_cmpy_code IS NOT NULL THEN 
				# Check that this IS a valid cmpy_code FROM within the company table.
				SELECT * FROM company 
				WHERE cmpy_code = l_arr_rec_extline[l_idx].ext_cmpy_code 
				IF status THEN 
					LET l_msgresp = kandoomsg("U",9910,"") 
					#9910 RECORD NOT found
					NEXT FIELD ext_cmpy_code 
				END IF 
			END IF 

		AFTER FIELD ext_rpt_id 
			IF l_arr_rec_extline[l_idx].ext_rpt_id IS NOT NULL THEN 
				# Check that this IS a valid report_id FROM within the company table.
				SELECT * FROM rpthead 
				WHERE cmpy_code = l_arr_rec_extline[l_idx].ext_cmpy_code 
				AND rpt_id = l_arr_rec_extline[l_idx].ext_rpt_id 
				IF status THEN 
					LET l_msgresp = kandoomsg("U",9910,"") 
					#9910 RECORD NOT found
					NEXT FIELD ext_rpt_id 
				END IF 
			END IF 

		AFTER FIELD ext_col_id 
			IF l_arr_rec_extline[l_idx].ext_col_id IS NOT NULL THEN 
				# Check that this IS a column_id FROM within the rptcol table.
				SELECT * FROM rptcol 
				WHERE cmpy_code = l_arr_rec_extline[l_idx].ext_cmpy_code 
				AND rpt_id = l_arr_rec_extline[l_idx].ext_rpt_id 
				AND col_id = l_arr_rec_extline[l_idx].ext_col_id 
				IF status THEN 
					LET l_msgresp = kandoomsg("U",9910,"") 
					#9910 RECORD NOT found
					NEXT FIELD ext_col_id 
				END IF 
			END IF 
			--   ON KEY (control-w)
			--      CALL kandoohelp("")
	END INPUT 

	IF NOT (int_flag OR quit_flag) THEN 
		#Delete existing extline row.
		DELETE FROM extline 
		WHERE line_uid = p_line_uid 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		FOR l_idx = 1 TO l_ext_cnt 
			IF l_arr_rec_extline[l_idx].ext_cmpy_code IS NOT NULL THEN 
				SELECT col_uid INTO l_col_uid FROM rptcol 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND rpt_id = gr_rptline.rpt_id 
				AND col_id = l_arr_rec_extline[l_idx].col_id 
				SELECT col_uid INTO l_ext_col_uid FROM rptcol 
				WHERE cmpy_code = l_arr_rec_extline[l_idx].ext_cmpy_code 
				AND rpt_id = l_arr_rec_extline[l_idx].ext_rpt_id 
				AND col_id = l_arr_rec_extline[l_idx].ext_col_id 
				INSERT INTO extline VALUES ( glob_rec_kandoouser.cmpy_code, 
				gr_rptline.rpt_id, 
				l_col_uid, 
				p_line_uid, 
				l_arr_rec_extline[l_idx].ext_cmpy_code, 
				l_arr_rec_extline[l_idx].ext_rpt_id, 
				l_ext_col_uid, 
				l_arr_rec_extline[l_idx].ext_accum_id) 
			END IF 
		END FOR 
	END IF 

	LET int_flag = false 
	LET quit_flag = false 
	CLOSE WINDOW g528 
	OPTIONS INSERT KEY f1, 
	DELETE KEY f2 

END FUNCTION 
