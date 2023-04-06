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

	Source code beautified by beautify.pl on 2020-01-03 10:10:04	$Id: $
}



############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "T_GW_GLOBALS.4gl" 
GLOBALS "TGW4_GLOBALS.4gl" 

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



FUNCTION accum_maint(fv_idx, fv_line_uid) 

	DEFINE fv_accum_id, 
	fv_idx, 
	fv_line_uid INTEGER, 
	#      fr_saveline        RECORD LIKE saveline.*,
	fr_rptline RECORD LIKE rptline.* 


	OPEN WINDOW g521 with FORM "TG521" 
	CALL windecoration_t("TG521") -- albo kd-768 

	#LET fv_accum_id = NULL

	#IF fv_line_uid > 0 AND fv_line_uid IS NOT NULL THEN
	#   SELECT accum_id INTO fr_saveline.accum_id
	#     FROM saveline
	#     WHERE line_uid = fv_line_uid
	#
	#END IF
	#
	#LET fv_accum_id = fr_saveline.accum_id
	#
	#INPUT BY NAME fr_saveline.accum_id WITHOUT DEFAULTS
	#   AFTER FIELD accum_id
	#     IF fr_saveline.accum_id = 0
	#       OR fr_saveline.accum_id = " " THEN
	#         LET fr_saveline.accum_id = NULL
	#     END IF
	#END INPUT
	#

	LET fr_rptline.accum_id = ga_rptline[fv_idx].accum_id 

	INPUT BY NAME fr_rptline.accum_id 
	WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","TGW4a","input-accum_id-1") -- albo kd-515 

		ON ACTION "WEB-HELP" -- albo kd-378 
			CALL onlinehelp(getmoduleid(),null) 

		AFTER FIELD accum_id 
			CASE 
				WHEN fr_rptline.accum_id = 0 
					ERROR "Accumulator, IF entered, must be > zero" 
					NEXT FIELD accum_id 
				WHEN fr_rptline.accum_id = " " 
					LET fr_rptline.accum_id = NULL 
			END CASE 
	END INPUT 

	IF NOT (int_flag OR quit_flag) THEN 
		LET ga_rptline[fv_idx].accum_id = fr_rptline.accum_id 
	END IF 

	LET int_flag = false 
	LET quit_flag = false 

	CLOSE WINDOW g521 

END FUNCTION 


#FUNCTION accum_line(fv_accum_id, fv_idx, fv_line_uid)

#DEFINE fv_accum_id,
#       fv_idx,
#       fv_line_uid,
#       fv_count       INTEGER
#
#DELETE FROM saveline
#   WHERE line_uid = fv_line_uid
#
#IF ga_rptline[fv_idx].accum_id IS NOT NULL THEN
#    INSERT INTO saveline VALUES (glob_rec_kandoouser.cmpy_code,
#                                 gr_rptlinegrp.line_code,
#                                 gr_rptline.line_id,
#                                 fv_line_uid,
#                                 ga_rptline[fv_idx].accum_id )
#END IF
#
#END FUNCTION


FUNCTION calcline_maint(fv_idx, fv_line_uid) 

	DEFINE fv_idx, 
	fv_line_uid INTEGER 

	DEFINE fv_count, 
	fv_calc_idx, 
	fv_calc_cnt INTEGER, 
	fr_calchead RECORD LIKE calchead.*, 
	fr_calcline RECORD LIKE calcline.*, 
	fa_calcline array[2000] OF RECORD 
		accum_id LIKE calcline.accum_id, 
		operator LIKE calcline.operator 
	END RECORD 

	OPEN WINDOW g522 with FORM "TG522" 
	CALL windecoration_t("TG522") -- albo kd-768 

	#SELECT calcline details IF they exist. ( WHEN updating )
	DECLARE calc_curs CURSOR FOR 
	SELECT accum_id, operator 
	FROM calcline 
	WHERE line_uid = fv_line_uid 


	LET fv_calc_cnt = 0 

	IF fv_line_uid > 0 AND fv_line_uid IS NOT NULL THEN 
		#SELECT calc. header details IF they exist. ( WHEN updating )
		SELECT always_print, 
		print_in_offset, 
		curr_type, 
		expected_sign 
		INTO fr_calchead.always_print, 
		fr_calchead.print_in_offset, 
		fr_calchead.curr_type, 
		fr_calchead.expected_sign 
		FROM calchead 
		WHERE line_uid = fv_line_uid 

		FOREACH calc_curs INTO fr_calcline.accum_id, fr_calcline.operator 
			LET fv_calc_cnt = fv_calc_cnt + 1 
			LET fa_calcline[fv_calc_cnt].accum_id = fr_calcline.accum_id 
			LET fa_calcline[fv_calc_cnt].operator = fr_calcline.operator 

			IF fv_calc_cnt < 11 THEN 
				DISPLAY fr_calcline.accum_id, fr_calcline.operator 
				TO sa_calcline[fv_calc_cnt].accum_id, 
				sa_calcline[fv_calc_cnt].operator 
			END IF 

		END FOREACH 
	END IF 

	IF fr_calchead.print_in_offset IS NULL THEN 
		LET fr_calchead.print_in_offset = "N" 
	END IF 

	# IF fr_calchead.curr_type IS NULL THEN
	#    LET fr_calchead.curr_type = "B"
	# END IF

	IF fr_calchead.expected_sign IS NULL THEN 
		LET fr_calchead.expected_sign = gr_mrwparms.add_op 
	END IF 

	#MESSAGE "ACC TO accept, INT TO cancel"
	LET msgresp = kandoomsg("A",1511," ") 

	INPUT BY NAME fr_calchead.always_print, 
	fr_calchead.print_in_offset, 
	fr_calchead.curr_type, 
	fr_calchead.expected_sign WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","TGW4a","input-always_print-1") -- albo kd-515 

		ON ACTION "WEB-HELP" -- albo kd-378 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE FIELD always_print 
			IF fr_calchead.always_print IS NULL THEN 
				LET fr_calchead.always_print= "Y" 
			END IF 

			#   BEFORE FIELD curr_type
			#      IF fr_calchead.curr_type IS NULL THEN
			#        LET fr_calchead.curr_type = "B"
			#      END IF

		BEFORE FIELD expected_sign 
			IF fr_calchead.expected_sign IS NULL THEN 
				LET fr_calchead.expected_sign = gr_mrwparms.add_op 
			END IF 

		AFTER FIELD always_print 
			IF fr_calchead.always_print IS NULL 
			OR fr_calchead.always_print = " " THEN 
				ERROR "The always-PRINT indicator must be entered" 
				NEXT FIELD always_print 
			END IF 

			IF NOT fr_calchead.always_print matches "[YNO]" THEN 
				ERROR "Enter Y, N OR O" 
				NEXT FIELD always_print 
			END IF 

		AFTER FIELD print_in_offset 
			IF fr_calchead.print_in_offset IS NULL 
			OR fr_calchead.print_in_offset = " " THEN 
				ERROR "This field must be entered" 
				NEXT FIELD print_in_offset 
			END IF 

			IF NOT fr_calchead.print_in_offset matches "[YN]" THEN 
				ERROR "Enter Y OR N" 
				NEXT FIELD print_in_offset 
			END IF 

		AFTER FIELD curr_type 
			#      IF fr_calchead.curr_type IS NULL
			#      OR fr_calchead.curr_type = " " THEN
			#          ERROR "The currency type must be entered"
			#          NEXT FIELD curr_type
			#      END IF

			IF fr_calchead.curr_type IS NOT NULL THEN 
				IF NOT fr_calchead.curr_type matches "[BT ]" THEN 
					ERROR "The currency type, IF entered, must be Base/Transaction" 
					NEXT FIELD curr_type 
				END IF 
			END IF 

		AFTER FIELD expected_sign 
			CASE 
				WHEN fr_calchead.expected_sign = gr_mrwparms.add_op 
				WHEN fr_calchead.expected_sign = gr_mrwparms.sub_op 
				OTHERWISE 
					ERROR "Invalid expected sign. Please try again" 
					NEXT FIELD expected_sign 
			END CASE 

	END INPUT 

	IF fr_calchead.curr_type = " " THEN 
		LET fr_calchead.curr_type = NULL 
	END IF 

	IF NOT (int_flag OR quit_flag) THEN 
		DELETE FROM calchead 
		WHERE line_uid = fv_line_uid 

		INSERT INTO calchead VALUES ( glob_rec_kandoouser.cmpy_code, 
		gr_rptlinegrp.line_code, 
		fv_line_uid, 
		fr_calchead.always_print, 
		fr_calchead.print_in_offset, 
		fr_calchead.expected_sign, 
		fr_calchead.curr_type) 
	ELSE 
		CLOSE WINDOW g522 
		RETURN 
	END IF 

	CALL set_count(fv_calc_cnt) 
	INPUT ARRAY fa_calcline WITHOUT DEFAULTS FROM sa_calcline.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","TGW4a","input-arr-fa_calcline-1") -- albo kd-515 

		ON ACTION "WEB-HELP" -- albo kd-378 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE ROW 
			LET fv_calc_idx = arr_curr() 
			LET fv_calc_cnt = arr_count() 
			IF fv_calc_cnt > 2000 THEN 
				ERROR "Maximum Number of lines IS 2000" 
				LET fv_calc_cnt = 2000 
				NEXT FIELD accum_id 
			END IF 

		AFTER FIELD accum_id 
			IF fv_calc_idx = 1 THEN 
				IF fa_calcline[fv_calc_idx].accum_id IS NULL 
				OR fa_calcline[fv_calc_idx].accum_id = " " THEN 
					ERROR "Accumulator id must be entered" 
					NEXT FIELD accum_id 
				END IF 
			END IF 

			IF fa_calcline[fv_calc_idx].accum_id IS NOT NULL AND 
			fa_calcline[fv_calc_idx].accum_id > 0 THEN 
				# Check that the accumulator exists FOR this REPORT.
				SELECT count(*) INTO fv_count 
				FROM rptline 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND line_code = gr_rptlinegrp.line_code 
				AND line_id < gr_rptline.line_id 
				AND accum_id = fa_calcline[fv_calc_idx].accum_id 

				IF fv_count = 0 OR fv_count IS NULL THEN 
					ERROR "Must be an accumulator FROM a previously defined line ", 
					"number" 
					NEXT FIELD accum_id 
				END IF 
			ELSE 
				LET fa_calcline[fv_calc_idx].accum_id = NULL 
			END IF 

		AFTER FIELD operator 
			IF fv_calc_idx = 1 THEN 
				IF fa_calcline[fv_calc_idx].operator IS NULL 
				OR fa_calcline[fv_calc_idx].operator IS NULL THEN 
					ERROR "Operator must be entered" 
					NEXT FIELD operator 
				END IF 
			ELSE 

				IF fa_calcline[fv_calc_idx].operator = gr_mrwparms.per_op THEN 
					ERROR "The % operator must be the only operator on a line" 
					NEXT FIELD operator 
				END IF 

			END IF 

			CASE 
				WHEN fa_calcline[fv_calc_idx].operator = gr_mrwparms.add_op 
				WHEN fa_calcline[fv_calc_idx].operator = gr_mrwparms.sub_op 
					# Allow multiply, divide AND percentage
				WHEN fa_calcline[fv_calc_idx].operator = gr_mrwparms.div_op 
				WHEN fa_calcline[fv_calc_idx].operator = gr_mrwparms.mult_op 
				WHEN fa_calcline[fv_calc_idx].operator = gr_mrwparms.per_op 
				OTHERWISE 
					IF fa_calcline[fv_calc_idx].accum_id IS NOT NULL 
					AND fa_calcline[fv_calc_idx].accum_id <> " " THEN 
						ERROR "Invalid mathematical operator. Please try again" 
						NEXT FIELD operator 
					ELSE 
						ERROR "An accumulator id must be entered with an operator" 
						NEXT FIELD accum_id 
					END IF 
			END CASE 
	END INPUT 


	IF NOT (int_flag OR quit_flag) THEN 
		DELETE FROM calcline 
		WHERE line_uid = fv_line_uid 

		FOR fv_calc_idx = 1 TO fv_calc_cnt 
			IF fa_calcline[fv_calc_idx].accum_id IS NOT NULL THEN 
				INSERT INTO calcline 
				VALUES ( glob_rec_kandoouser.cmpy_code, 
				gr_rptlinegrp.line_code, 
				fv_line_uid, 
				fv_calc_idx, 
				fa_calcline[fv_calc_idx].accum_id, 
				fa_calcline[fv_calc_idx].operator ) 

			END IF 
		END FOR 
	END IF 

	CLOSE WINDOW g522 

END FUNCTION 


FUNCTION desc_maint(fv_idx, fv_line_uid) 
	# desciption:   INPUT of desciption columns as SET within the COLUMN
	#               maintenance program.
	DEFINE fv_idx, 
	fv_col_uid, 
	fv_line_uid, 
	fv_start_pos, 
	fv_end_pos INTEGER 

	DEFINE fv_width, 
	fv_desc_len, 
	fv_desc_idx, 
	fv_desc_cnt, 
	fv_scrn INTEGER, 
	fv_chart_clause LIKE gllinedetl.chart_clause, 
	fv_slct CHAR(500), 
	fr_descline RECORD 
		seq_num LIKE descline.seq_num, 
		line_desc LIKE descline.line_desc 
	END RECORD, 

	fa_descline array[20] OF RECORD 
		seq_num SMALLINT, 
		line_desc LIKE descline.line_desc 
	END RECORD 

	DEFINE fv_acct_code LIKE account.acct_code 

	OPTIONS INSERT KEY f26 
	OPTIONS DELETE KEY f21 

	OPEN WINDOW g523 with FORM "TG523" 
	CALL windecoration_t("TG523") -- albo kd-768 

	DECLARE descline_curs CURSOR FOR 
	SELECT seq_num, line_desc 
	FROM descline 
	WHERE line_uid = fv_line_uid 
	ORDER BY seq_num 

	LET fv_desc_cnt = 0 
	FOREACH descline_curs INTO fr_descline.seq_num, fr_descline.line_desc 
		LET fv_desc_cnt = fv_desc_cnt + 1 
		LET fa_descline[fv_desc_cnt].seq_num = fr_descline.seq_num 
		LET fa_descline[fv_desc_cnt].line_desc = fr_descline.line_desc 
		IF fv_desc_cnt < 6 THEN 
			DISPLAY fr_descline.seq_num, 
			fr_descline.line_desc 
			TO sa_descline[fv_desc_cnt].seq_num, 
			sa_descline[fv_desc_cnt].line_desc 
		END IF 
	END FOREACH 

	#IF a specific general ledger chart code has been nominated FOR the
	# line (NOT a chart range) THEN default the first line_desc TO
	# coa.desc_text

	IF fa_descline[1].line_desc IS NULL AND 
	ga_rptline[fv_idx].line_type = gr_mrwparms.gl_line_type THEN 

		INITIALIZE fv_chart_clause TO NULL 

		SELECT chart_clause INTO fv_chart_clause 
		FROM gllinedetl 
		WHERE line_uid = fv_line_uid 
		AND seq_num = 1 

		IF status <> notfound THEN 
			SELECT start_num, (start_num + length_num - 1) 
			INTO fv_start_pos, fv_end_pos 
			FROM structure 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND type_ind = "C" 

			LET fv_slct = "SELECT desc_text ", 
			"FROM coa ", 
			"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"'", 
			" AND acct_code[",fv_start_pos,",",fv_end_pos,"]", 
			" = '",fv_chart_clause clipped,"'" 

			WHENEVER ERROR CONTINUE #if fv_chart_clause IS invalid. 

			PREPARE s_1 FROM fv_slct 
			DECLARE chart_curs CURSOR FOR s_1 

			OPEN chart_curs 
			FETCH chart_curs INTO fa_descline[1].line_desc 
			LET fa_descline[1].seq_num = 1 
			LET fv_desc_cnt = 1 
			DISPLAY fa_descline[1].seq_num, 
			fa_descline[1].line_desc 
			TO sa_descline[1].seq_num, 
			sa_descline[1].line_desc 
			--- modif ericv init # close s_1
			WHENEVER ERROR stop 

		END IF 

	END IF 

	CALL set_count(fv_desc_cnt) 
	INPUT ARRAY fa_descline 
	WITHOUT DEFAULTS 
	FROM sa_descline.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","TGW4a","input-fa_descline-1") -- albo kd-515 

		ON ACTION "WEB-HELP" -- albo kd-378 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE ROW 
			LET fv_desc_idx = arr_curr() 
			LET fv_scrn = scr_line() 
			IF fv_desc_idx > 20 THEN 
				ERROR "You can have a maximum of 20 columns on any REPORT" 
				LET fv_desc_idx = 20 
				NEXT FIELD line_desc 
			END IF 

		BEFORE FIELD line_desc 
			IF fa_descline[fv_desc_idx].seq_num IS NULL 
			OR fa_descline[fv_desc_idx].seq_num = "0" THEN 
				LET fa_descline[fv_desc_idx].seq_num = fv_desc_idx 
				DISPLAY fa_descline[fv_desc_idx].seq_num 
				TO sa_descline[fv_desc_idx].seq_num 
			END IF 

	END INPUT 

	OPTIONS INSERT KEY f1 
	OPTIONS DELETE KEY f2 

	IF NOT (int_flag OR quit_flag) THEN 
		DELETE FROM descline 
		WHERE line_uid = fv_line_uid 

		FOR fv_desc_idx = 1 TO 20 
			IF fa_descline[fv_desc_idx].line_desc IS NOT NULL THEN 

				INSERT INTO descline VALUES ( glob_rec_kandoouser.cmpy_code, 
				gr_rptlinegrp.line_code, 
				fv_line_uid, 
				fv_desc_idx, 
				fa_descline[fv_desc_idx].line_desc) 
			END IF 
		END FOR 

		# Set rptline.line_desc TO the first line_desc in the array.
		LET ga_rptline[fv_idx].line_desc = fa_descline[1].line_desc 

		# The calling FUNCTION needs TO know IF int_flag/quit_flag has been SET:
	END IF 

	CLOSE WINDOW g523 

END FUNCTION 


FUNCTION glline_maint(fv_idx, fv_line_uid) 

	DEFINE fv_idx, 
	fv_gldtl_cnt, 
	fv_line_uid INTEGER 

	DEFINE fv_glidx INTEGER, 
	fr_glline RECORD LIKE glline.*, 
	fr_gllinedetl RECORD LIKE gllinedetl.*, 
	fa_gllinedetl array[2000] OF RECORD 
		operator LIKE gllinedetl.operator, 
		chart_clause LIKE gllinedetl.chart_clause 
	END RECORD 

	OPEN WINDOW g524 with FORM "TG524" 
	CALL windecoration_t("TG524") -- albo kd-768 

	IF fv_line_uid > 0 AND fv_line_uid IS NOT NULL THEN 
		#SELECT glline details IF they exist. ( WHEN updating )
		SELECT always_print, 
		print_in_offset, 
		expected_sign, 
		detl_flag, 
		curr_code 
		INTO fr_glline.always_print, 
		fr_glline.print_in_offset, 
		fr_glline.expected_sign, 
		fr_glline.detl_flag, 
		fr_glline.curr_code 
		FROM glline 
		WHERE line_uid = fv_line_uid 
	END IF 

	IF fr_glline.always_print IS NULL THEN 
		LET fr_glline.always_print = "Y" 
	END IF 

	IF fr_glline.print_in_offset IS NULL THEN 
		LET fr_glline.print_in_offset = "N" 
	END IF 

	IF fr_glline.expected_sign IS NULL THEN 
		LET fr_glline.expected_sign = gr_mrwparms.add_op 
	END IF 

	IF fr_glline.detl_flag IS NULL THEN 
		LET fr_glline.detl_flag = "C" 
	END IF 

	#SELECT gllinedetl details IF they exist FROM temp table. (WHEN updating)
	DECLARE gldetl_curs CURSOR FOR 
	SELECT chart_clause, operator 
	FROM gllinedetl 
	WHERE line_uid = fv_line_uid 

	LET fv_gldtl_cnt = 0 
	FOREACH gldetl_curs INTO fr_gllinedetl.chart_clause, fr_gllinedetl.operator 
		LET fv_gldtl_cnt = fv_gldtl_cnt + 1 
		LET fa_gllinedetl[fv_gldtl_cnt].chart_clause = fr_gllinedetl.chart_clause 
		LET fa_gllinedetl[fv_gldtl_cnt].operator = fr_gllinedetl.operator 

		IF fv_gldtl_cnt < 7 THEN 
			DISPLAY fr_gllinedetl.operator, fr_gllinedetl.chart_clause 
			TO sa_gllinedetl[fv_gldtl_cnt].operator, 
			sa_gllinedetl[fv_gldtl_cnt].chart_clause 
		END IF 

	END FOREACH 

	#MESSAGE "ACC TO accept, INT TO cancel"
	LET msgresp = kandoomsg("A",1511," ") 

	INPUT BY NAME fr_glline.always_print, 
	fr_glline.print_in_offset, 
	fr_glline.expected_sign, 
	fr_glline.detl_flag, 
	fr_glline.curr_code 
	WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","TGW4a","input-always_print-1") -- albo kd-515 

		ON ACTION "WEB-HELP" -- albo kd-378 
			CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "LOOKUP" ---------- browse infield(curr_code) 
					LET fr_glline.curr_code = show_curr(glob_rec_kandoouser.cmpy_code) 
					DISPLAY BY NAME fr_glline.curr_code 

		BEFORE FIELD expected_sign 
			IF fr_glline.expected_sign IS NULL THEN 
				LET fr_glline.expected_sign = gr_mrwparms.add_op 
			END IF 

		BEFORE FIELD detl_flag 
			IF fr_glline.detl_flag IS NULL THEN 
				LET fr_glline.detl_flag = "C" 
			END IF 

		AFTER FIELD always_print 
			IF fr_glline.always_print IS NULL 
			OR fr_glline.always_print = " " THEN 
				ERROR "Always Print indicator must be entered" 
				NEXT FIELD always_print 
			END IF 

			IF NOT fr_glline.always_print matches "[YNO]" THEN 
				ERROR "Invalid Always-Print Indicator" 
				NEXT FIELD always_print 
			END IF 

		AFTER FIELD print_in_offset 
			IF fr_glline.print_in_offset IS NULL 
			OR fr_glline.print_in_offset = " " THEN 
				ERROR "Print In Offset indicator must be entered" 
				NEXT FIELD print_in_offset 
			END IF 

			IF NOT fr_glline.print_in_offset matches "[YN]" THEN 
				ERROR "Invalid Offset-Print Indicator" 
				NEXT FIELD print_in_offset 
			END IF 

		AFTER FIELD expected_sign 
			CASE 
				WHEN fr_glline.expected_sign = gr_mrwparms.add_op 
				WHEN fr_glline.expected_sign = gr_mrwparms.sub_op 
				OTHERWISE 
					ERROR "Invalid expected sign. Please try again" 
					NEXT FIELD expected_sign 
			END CASE 

		AFTER FIELD detl_flag 
			IF fr_glline.detl_flag IS NULL 
			OR fr_glline.detl_flag = " " THEN 
				NEXT FIELD detl_flag 
			END IF 

			IF NOT fr_glline.detl_flag matches "[CD]" THEN 
				ERROR "Invalid Detail flag - C=Consolidated, D=Detailed" 
				NEXT FIELD detl_flag 
			END IF 

		AFTER FIELD curr_code 
			IF fr_glline.curr_code IS NOT NULL THEN 
				SELECT 1 
				FROM currency 
				WHERE currency_code = fr_glline.curr_code 

				IF status = notfound THEN 
					ERROR "Invalid currency code - try lookup" 
					NEXT FIELD curr_code 
				END IF 
			END IF 
	END INPUT 

	IF int_flag OR quit_flag THEN 
		CLOSE WINDOW g524 
		RETURN 
	END IF 

	IF fr_glline.curr_code = " " THEN 
		LET fr_glline.curr_code = NULL 
	END IF 

	CALL set_count(fv_gldtl_cnt) 
	INPUT ARRAY fa_gllinedetl WITHOUT DEFAULTS FROM sa_gllinedetl.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","TGW4a","input-arr-fa_gllinedetl-1") -- albo kd-515 

		ON ACTION "WEB-HELP" -- albo kd-378 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE ROW 
			LET fv_glidx = arr_curr() 
			LET fv_gldtl_cnt = arr_count() 
			IF fv_gldtl_cnt > 2000 THEN 
				ERROR "Maximum Number of lines IS 2000" 
				LET fv_gldtl_cnt = 2000 
				NEXT FIELD chart_code 
			END IF 

		BEFORE FIELD operator 
			IF fa_gllinedetl[fv_glidx].operator IS NULL THEN 
				LET fa_gllinedetl[fv_glidx].operator = gr_mrwparms.add_op 
			END IF 


		AFTER FIELD operator 
			CASE 
				WHEN fa_gllinedetl[fv_glidx].operator = gr_mrwparms.add_op 
				WHEN fa_gllinedetl[fv_glidx].operator = gr_mrwparms.sub_op 
				WHEN fa_gllinedetl[fv_glidx].operator = gr_mrwparms.div_op 
				WHEN fa_gllinedetl[fv_glidx].operator = gr_mrwparms.mult_op 
				WHEN fa_gllinedetl[fv_glidx].operator = " " 
				WHEN fa_gllinedetl[fv_glidx].operator IS NULL 
				OTHERWISE 
					ERROR "Invalid mathematical operator. Please try again" 
					NEXT FIELD operator 
			END CASE 

		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN 
				FOR fv_glidx = 1 TO fv_gldtl_cnt 
					IF fa_gllinedetl[fv_glidx].chart_clause IS NOT NULL THEN 
						CASE 
							WHEN fa_gllinedetl[fv_glidx].operator = gr_mrwparms.add_op 
							WHEN fa_gllinedetl[fv_glidx].operator = gr_mrwparms.sub_op 
							WHEN fa_gllinedetl[fv_glidx].operator = gr_mrwparms.div_op 
							WHEN fa_gllinedetl[fv_glidx].operator = gr_mrwparms.mult_op 
							OTHERWISE 
								ERROR "There IS an invalid mathematical operator ", 
								"within the chart clauses. " 
								NEXT FIELD operator 
						END CASE 
					END IF 
				END FOR 
			END IF 

	END INPUT 

	IF NOT (int_flag OR quit_flag) THEN 
		DELETE FROM glline 
		WHERE line_uid = fv_line_uid 

		INSERT INTO glline VALUES ( glob_rec_kandoouser.cmpy_code, 
		gr_rptlinegrp.line_code, 
		fv_line_uid, 
		fr_glline.always_print, 
		fr_glline.print_in_offset, 
		fr_glline.expected_sign, 
		fr_glline.detl_flag, 
		fr_glline.curr_code) 

		DELETE FROM gllinedetl 
		WHERE line_uid = fv_line_uid 

		FOR fv_glidx = 1 TO fv_gldtl_cnt 
			IF fa_gllinedetl[fv_glidx].chart_clause IS NOT NULL THEN 

				INSERT INTO gllinedetl 
				VALUES ( glob_rec_kandoouser.cmpy_code, 
				gr_rptlinegrp.line_code, 
				fv_line_uid, 
				fv_glidx, 
				fa_gllinedetl[fv_glidx].chart_clause, 
				fa_gllinedetl[fv_glidx].operator ) 
			END IF 
		END FOR 

	END IF 

	CLOSE WINDOW g524 

END FUNCTION 



FUNCTION txt_maint(fv_idx, fv_line_uid) 
	DEFINE fv_idx, 
	fv_line_uid INTEGER 

	CALL desc_maint(fv_idx, fv_line_uid) 

END FUNCTION 


FUNCTION underline_maint(fv_idx, fv_line_uid) 
	DEFINE fv_idx, 
	fv_line_uid INTEGER 

	DEFINE 
	fv_txtidx INTEGER , 
	fv_txttype_desc LIKE txttype.txttype_desc, 
	fr_txtline RECORD LIKE txtline.* 

	OPEN WINDOW g516 with FORM "TG516" 
	CALL windecoration_t("TG516") -- albo kd-768 

	IF fv_line_uid > 0 AND fv_line_uid IS NOT NULL THEN 
		SELECT txt_type INTO fr_txtline.txt_type 
		FROM txtline 
		WHERE line_uid = fv_line_uid 
	END IF 

	SELECT txttype_desc INTO fv_txttype_desc 
	FROM txttype 
	WHERE txttype_id = fr_txtline.txt_type 

	DISPLAY fv_txttype_desc TO txttype_desc 

	INPUT BY NAME fr_txtline.txt_type WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","TGW4a","input-xt_type-1") -- albo kd-515 

		ON ACTION "WEB-HELP" -- albo kd-378 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY ( control-b ) 
			LET fr_txtline.txt_type = show_txttype( fr_txtline.txt_type ) 
			IF fr_txtline.txt_type IS NOT NULL THEN 

				DISPLAY BY NAME fr_txtline.txt_type 
				SELECT txttype_desc INTO fv_txttype_desc 
				FROM txttype 
				WHERE txttype_id = fr_txtline.txt_type 
				IF status = notfound THEN 
					ERROR "Invalid text type identifier." 
					NEXT FIELD txt_type 
				ELSE 
					DISPLAY fv_txttype_desc TO txttype_desc 
				END IF 
			END IF 

		AFTER FIELD txt_type 
			IF fr_txtline.txt_type IS NULL THEN 
				ERROR "Text type must be entered - try window" 
				NEXT FIELD txt_type 
			ELSE 
				SELECT txttype_desc INTO fv_txttype_desc 
				FROM txttype 
				WHERE txttype_id = fr_txtline.txt_type 

				IF status = notfound THEN 
					ERROR "Invalid text type identifier" 
					NEXT FIELD txt_type 
				ELSE 
					DISPLAY fv_txttype_desc TO txttype_desc 
				END IF 
			END IF 
	END INPUT 

	IF NOT (int_flag OR quit_flag) THEN 
		DELETE FROM txtline 
		WHERE line_uid = fv_line_uid 

		INSERT INTO txtline VALUES ( glob_rec_kandoouser.cmpy_code, 
		gr_rptlinegrp.line_code, 
		fv_line_uid, 
		fr_txtline.txt_type ) 

		# Set rptline.line_desc TO the first line_desc in the array.
		LET ga_rptline[fv_idx].line_desc = fv_txttype_desc 

	END IF 

	CLOSE WINDOW g516 

END FUNCTION 



{ FUNCTION:        seg_anal_down()
  Description:     FUNCTION FOR entry of analysis down section REPORT.
}
FUNCTION seg_anal_down(fv_line_id, fv_line_uid) 

	DEFINE fa_segline array[100] OF RECORD 
		start_num LIKE segline.start_num, 
		flex_clause LIKE segline.flex_clause 
	END RECORD 

	DEFINE fr_segline RECORD LIKE segline.*, 
	fv_line_id, 
	fv_line_uid, 
	fv_sad_cnt, 
	fv_scrn, 
	fv_idx INTEGER 

	OPEN WINDOW g572 with FORM "TG572" 
	CALL windecoration_t("TG572") -- albo kd-768 

	DECLARE segline_curs CURSOR FOR 
	SELECT segline.* 
	FROM segline 
	WHERE segline.line_uid = fv_line_uid 

	LET fv_sad_cnt = 0 
	FOREACH segline_curs INTO fr_segline.* 
		LET fv_sad_cnt = fv_sad_cnt + 1 
		LET fa_segline[fv_sad_cnt].start_num = fr_segline.start_num 
		LET fa_segline[fv_sad_cnt].flex_clause = fr_segline.flex_clause 
		IF fv_sad_cnt < 6 THEN 
			DISPLAY fa_segline[fv_sad_cnt].start_num, 
			fa_segline[fv_sad_cnt].flex_clause 
			TO sa_segline[fv_sad_cnt].start_num, 
			sa_segline[fv_sad_cnt].flex_clause 
		END IF 
	END FOREACH 

	DISPLAY fv_line_id TO line_id 

	CALL set_count(fv_sad_cnt) 
	INPUT ARRAY fa_segline WITHOUT DEFAULTS FROM sa_segline.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","TGW4a","input-arr-fa_segline-2") -- albo kd-515 

		ON ACTION "WEB-HELP" -- albo kd-378 
			CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "LOOKUP" infield(start_num)  ---------- browse infield(start_num) 
					LET fa_segline[fv_idx].start_num = strucdwind(glob_rec_kandoouser.cmpy_code) 
					DISPLAY fa_segline[fv_idx].start_num TO sa_segline[fv_scrn].start_num 

				ON ACTION "LOOKUP" infield(flex_clause)  ---------- browse infield(flex_clause) 
					CALL show_flex(glob_rec_kandoouser.cmpy_code, fa_segline[fv_idx].start_num) 
					RETURNING fa_segline[fv_idx].flex_clause
					 
					DISPLAY fa_segline[fv_idx].flex_clause TO sa_segline[fv_scrn].flex_clause 


		BEFORE ROW 
			LET fv_idx = arr_curr() 
			LET fv_scrn = scr_line() 
			IF fv_idx > 99 THEN 
				ERROR "Maximum number of rows IS 100." 
				LET fv_idx = 100 
				NEXT FIELD start_num 
			END IF 


		BEFORE FIELD start_num 
			IF fa_segline[fv_idx].start_num = 0 THEN 
				LET fa_segline[fv_idx].start_num = NULL 
			END IF 

		AFTER FIELD start_num 
			IF fa_segline[fv_idx].start_num IS NULL THEN 
				#         ERROR "Start number must be entered - try lookup"
				#         NEXT FIELD start_num
			ELSE 
				# Check that this IS a valid start_num FROM within the structure table.
				SELECT * 
				FROM structure 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND start_num = fa_segline[fv_idx].start_num 
				AND type_ind = "S" 

				IF status THEN 
					ERROR "Invalid start number FROM within the account structure", 
					" - must be segment" 
					NEXT FIELD start_num 
				END IF 
			END IF 

		AFTER FIELD flex_clause 
			IF fa_segline[fv_idx].start_num IS NULL THEN 
				ERROR "Start number must be entered - try lookup" 
				NEXT FIELD start_num 
			ELSE 
				IF fa_segline[fv_idx].flex_clause IS NULL THEN 
					ERROR "Segment clause must be entered" 
					NEXT FIELD flex_clause 
				END IF 
			END IF 
	END INPUT 

	LET fv_sad_cnt = arr_count() 

	IF NOT (int_flag OR quit_flag) THEN 
		DELETE FROM segline 
		WHERE line_uid = fv_line_uid 

		FOR fv_idx = 1 TO fv_sad_cnt 
			IF fa_segline[fv_idx].start_num IS NOT NULL 
			AND fa_segline[fv_idx].flex_clause IS NOT NULL THEN 
				INSERT INTO segline VALUES ( glob_rec_kandoouser.cmpy_code, 
				gr_rptline.line_code, 
				fv_line_uid, 
				fv_idx, 
				fa_segline[fv_idx].start_num, 
				fa_segline[fv_idx].flex_clause) 
			END IF 
		END FOR 

	END IF 

	LET int_flag = false 
	LET quit_flag = false 


	CLOSE WINDOW g572 

END FUNCTION 




{ FUNCTION:        external_link()
  Description:     FUNCTION FOR entry of external links
}
FUNCTION extline_maint(fv_line_id, fv_line_uid) 

	DEFINE fa_extline array[100] OF RECORD 
		ext_cmpy_code LIKE extline.cmpy_code, 
		ext_line_code LIKE extline.line_code, 
		ext_accum_id LIKE extline.ext_accum_id 
	END RECORD 

	DEFINE fr_exthead RECORD LIKE exthead.*, 
	fr_extline RECORD LIKE extline.*, 
	fr_rptcol RECORD LIKE rptcol.*, 
	fv_count, 
	fv_col_id, 
	fv_ext_col_uid, 
	fv_col_uid, 
	fv_line_id, 
	fv_line_uid, 
	fv_ext_cnt, 
	fv_scrn, 
	fv_idx INTEGER 

	OPEN WINDOW g573 with FORM "TG573" 
	CALL windecoration_t("TG573") -- albo kd-768 

	FOR fv_idx = 1 TO 100 
		INITIALIZE fa_extline[fv_idx].* TO NULL 
	END FOR 

	SELECT * 
	INTO fr_exthead.* 
	FROM exthead 
	WHERE line_uid = fv_line_uid 

	IF fr_exthead.always_print IS NULL THEN 
		LET fr_exthead.always_print = "Y" 
	END IF 

	IF fr_exthead.expected_sign IS NULL THEN 
		LET fr_exthead.expected_sign = gr_mrwparms.add_op 
	END IF 

	DISPLAY BY NAME gr_rptlinegrp.cmpy_code, 
	gr_rptlinegrp.line_code, 
	fv_line_id, 
	fr_exthead.always_print, 
	fr_exthead.expected_sign 

	LET fv_ext_cnt = 0 

	#SELECT external link details FOR this line.
	DECLARE ext_curs CURSOR FOR 
	SELECT * 
	FROM extline 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND line_code = gr_rptlinegrp.line_code 
	AND line_uid = fv_line_uid 

	FOREACH ext_curs INTO fr_extline.* 
		LET fv_ext_cnt = fv_ext_cnt + 1 
		LET fa_extline[fv_ext_cnt].ext_cmpy_code = fr_extline.ext_cmpy_code 
		LET fa_extline[fv_ext_cnt].ext_line_code = fr_extline.ext_line_code 
		LET fa_extline[fv_ext_cnt].ext_accum_id = fr_extline.ext_accum_id 

		IF fv_ext_cnt < 6 THEN 
			DISPLAY fa_extline[fv_ext_cnt].ext_cmpy_code, 
			fa_extline[fv_ext_cnt].ext_line_code, 
			fa_extline[fv_ext_cnt].ext_accum_id 
			TO sa_extline[fv_ext_cnt].ext_cmpy_code, 
			sa_extline[fv_ext_cnt].ext_line_code, 
			sa_extline[fv_ext_cnt].ext_accum_id 
		END IF 
	END FOREACH 

	INPUT BY NAME fr_exthead.always_print, 
	fr_exthead.expected_sign 
	WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","TGW4a","input-always_print-2") -- albo kd-515 

		ON ACTION "WEB-HELP" -- albo kd-378 
			CALL onlinehelp(getmoduleid(),null) 

		AFTER FIELD always_print 
			IF fr_exthead.always_print IS NULL 
			OR fr_exthead.always_print = " " THEN 
				ERROR "Always Print must be entered" 
				NEXT FIELD always_print 
			END IF 

			IF NOT fr_exthead.always_print matches "[YNO]" THEN 
				ERROR "Must enter Y, N OR O" 
				NEXT FIELD always_print 
			END IF 

		AFTER FIELD expected_sign 
			IF fr_exthead.expected_sign IS NULL 
			OR fr_exthead.expected_sign = " " THEN 
				ERROR "Expected sign must be entered" 
				NEXT FIELD expected_sign 
			END IF 

			CASE 
				WHEN fr_exthead.expected_sign = gr_mrwparms.add_op 
				WHEN fr_exthead.expected_sign = gr_mrwparms.sub_op 
				OTHERWISE 
					ERROR "Invalid sign - please enter another" 
			END CASE 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		GOTO end_extline_maint 
	END IF 

	MESSAGE "F1 TO add, F2 TO delete, RETURN TO UPDATE" 
	attribute(yellow) 

	CALL set_count(fv_ext_cnt) 
	INPUT ARRAY fa_extline WITHOUT DEFAULTS FROM sa_extline.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","TGW4a","input-arr-fa_extline-2") -- albo kd-515 

		ON ACTION "WEB-HELP" -- albo kd-378 
			CALL onlinehelp(getmoduleid(),null) 


				ON ACTION "LOOKUP" ---------- browse infield(ext_line_code) 
					CALL show_linegrps(fa_extline[fv_idx].ext_cmpy_code, 
					fa_extline[fv_idx].ext_line_code) 
					RETURNING fa_extline[fv_idx].ext_line_code 
					DISPLAY fa_extline[fv_idx].ext_line_code 
					TO sa_extline[fv_scrn].ext_line_code 


		BEFORE ROW 
			LET fv_idx = arr_curr() 
			LET fv_scrn = scr_line() 
			IF fv_idx > 19 THEN 
				ERROR "Maximum number of rows IS 20." 
				LET fv_idx = 20 
				NEXT FIELD ext_cmpy_code 
			END IF 

		BEFORE FIELD ext_line_code 
			IF fa_extline[fv_idx].ext_cmpy_code IS NULL 
			OR fa_extline[fv_idx].ext_cmpy_code = " " THEN 
				LET fa_extline[fv_idx].ext_cmpy_code = glob_rec_kandoouser.cmpy_code 
				DISPLAY fa_extline[fv_idx].ext_cmpy_code 
				TO sa_extline[fv_scrn].ext_cmpy_code 
			END IF 

			SELECT * 
			FROM company 
			WHERE cmpy_code = fa_extline[fv_idx].ext_cmpy_code 

			IF status THEN 
				ERROR "Invalid company code." 
				NEXT FIELD ext_cmpy_code 
			END IF 

		AFTER FIELD ext_line_code 
			IF fa_extline[fv_idx].ext_line_code IS NULL THEN 
				ERROR "External line code must be entered" 
				NEXT FIELD ext_line_code 
			END IF 

			IF fa_extline[fv_idx].ext_cmpy_code = gr_rptlinegrp.cmpy_code 
			AND fa_extline[fv_idx].ext_line_code = gr_rptlinegrp.line_code THEN 
				ERROR "You must specifiy an external line code" 
				NEXT FIELD ext_line_code 
			END IF 

			SELECT * 
			FROM rptlinegrp 
			WHERE cmpy_code = fa_extline[fv_idx].ext_cmpy_code 
			AND line_code = fa_extline[fv_idx].ext_line_code 

			IF status THEN 
				ERROR "Invalid line code - use lookup" 
				NEXT FIELD ext_line_code 
			END IF 

		AFTER FIELD ext_accum_id 
			IF fa_extline[fv_idx].ext_accum_id IS NULL 
			OR fa_extline[fv_idx].ext_accum_id = " " THEN 
				ERROR "Accumulator id must be entered" 
				NEXT FIELD ext_accum_id 
			END IF 

			SELECT count(*) 
			INTO fv_count 
			FROM rptline 
			WHERE cmpy_code = fa_extline[fv_idx].ext_cmpy_code 
			AND line_code = fa_extline[fv_idx].ext_line_code 
			AND accum_id = fa_extline[fv_idx].ext_accum_id 
			AND line_type = gr_mrwparms.gl_line_type 

			IF NOT fv_count > 0 THEN 
				ERROR "Invalid accumulator FOR this line group - must be GL line(s)" 
				NEXT FIELD ext_accum_id 
			END IF 

	END INPUT 

	IF NOT (int_flag OR quit_flag) THEN 
		DELETE FROM exthead 
		WHERE line_uid = fv_line_uid 

		DELETE FROM extline 
		WHERE line_uid = fv_line_uid 

		LET fv_ext_cnt = 0 
		FOR fv_idx = 1 TO 20 

			IF fa_extline[fv_idx].ext_cmpy_code IS NULL 
			OR fa_extline[fv_idx].ext_line_code IS NULL 
			OR fa_extline[fv_idx].ext_accum_id IS NULL THEN 
				EXIT FOR 
			END IF 

			LET fv_ext_cnt = fv_idx 

			INSERT INTO extline VALUES ( glob_rec_kandoouser.cmpy_code, 
			gr_rptlinegrp.line_code, 
			fv_line_uid, 
			fa_extline[fv_idx].ext_cmpy_code, 
			fa_extline[fv_idx].ext_line_code, 
			fa_extline[fv_idx].ext_accum_id) 
		END FOR 

		IF fv_idx > 1 THEN 
			INSERT INTO exthead VALUES ( glob_rec_kandoouser.cmpy_code, 
			gr_rptlinegrp.line_code, 
			fv_line_uid, 
			fr_exthead.always_print, 
			fr_exthead.expected_sign) 
		END IF 

	END IF 

	LABEL end_extline_maint: 

	CLOSE WINDOW g573 

	RETURN fv_ext_cnt 

END FUNCTION 

