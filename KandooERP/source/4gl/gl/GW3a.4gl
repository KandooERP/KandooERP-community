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

	Source code beautified by beautify.pl on 2020-01-03 14:28:56	$Id: $
}

############################################################
#    This module contains the functions needed TO add a
#    new RECORD TO the rptcol table.
#
############################################################

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 
GLOBALS "../gl/GW3_GLOBALS.4gl" 

############################################################
# FUNCTION col_add()
#
# Description         :   This FUNCTION allows the user TO add a new
#                         row TO the rptcol table. It performs the appropriate
#                         uniqueness AND NOT NULL checks on the VALUES entered
# Incoming parameters :   None
# RETURN parameters   :   None
# Impact GLOBALS      :   None
# perform screens     :   col_maint
############################################################
FUNCTION col_add() 
	DEFINE l_idx INTEGER 
	--	DEFINE fv_scrn INTEGER
	--	DEFINE l_cnt INTEGER
	--	DEFINE l_width_tot INTEGER
	--	DEFINE l_field CHAR(10)
	--	DEFINE l_rec_mrwitem RECORD LIKE mrwitem.*
	DEFINE l_msgresp LIKE language.yes_flag 

	CLEAR FORM 
	LET l_msgresp = kandoomsg("G",1081,"") 
	#1072 Enter Column Details; F7 Analysis; OK TO Continue.
	INITIALIZE glob_rec_rptcol TO NULL 

	#   assign the default VALUES
	LET glob_rec_rptcol.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET glob_rec_rptcol.rpt_id = glob_rec_rpthead.rpt_id 

	#Work out the next col_id number
	SELECT max(col_id) INTO glob_rec_rptcol.col_id FROM rptcol 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND rpt_id = glob_rec_rptcol.rpt_id 

	IF glob_rec_rptcol.col_id IS NULL OR glob_rec_rptcol.col_id = 0 THEN 
		LET glob_rec_rptcol.col_id = 1 
	ELSE 
		LET glob_rec_rptcol.col_id = glob_rec_rptcol.col_id + 1 
	END IF 

	LET glob_rec_rptcol.amt_picture = glob_rec_rpthead.amt_picture 

	DISPLAY BY NAME glob_rec_rpthead.rpt_id, 
	glob_rec_rpthead.rpt_text, 
	glob_rec_rptcol.col_id, 
	glob_rec_rptcol.amt_picture 


	#Clear rptcoldesc array
	FOR l_idx = 1 TO 3 
		INITIALIZE glob_arr_recrptcoldesc[l_idx] TO NULL 
	END FOR 

	#Clear colitem array
	FOR l_idx = 1 TO glob_colitem_cnt 
		INITIALIZE glob_arr_reccolitem[l_idx] TO NULL 
	END FOR 

	#Set Default add attributes
	LET glob_colitem_cnt = 0 

	CALL col_updt(false) 

	IF glob_scurs_col_open THEN 
		CALL col_curs() 
		CALL last_col() 
	END IF 

END FUNCTION 



{ FUNCTION:        seg_anal_across()
  Description:     FUNCTION FOR entry of analysis across section REPORT.
}


############################################################
# FUNCTION seg_anal_across(p_col_uid)
#
#
############################################################
FUNCTION seg_anal_across(p_col_uid) 
	DEFINE p_col_uid INTEGER 

	DEFINE l_arr_rec_segcol DYNAMIC ARRAY OF RECORD --array[100] OF RECORD 
		start_num LIKE rptcolaa.start_num, 
		flex_clause LIKE rptcolaa.flex_clause 
	END RECORD 
	DEFINE l_rec_rptcolaa RECORD LIKE rptcolaa.* 
	DEFINE l_saa_cnt INTEGER 
	--	DEFINE  #fv_scrn INTEGER
	DEFINE l_idx INTEGER 
	DEFINE l_msgresp LIKE language.yes_flag 

	# Check IF the REPORT type IS of an analysis across type.
	IF glob_rec_rpthead.rpt_type != glob_rec_mrwparms.analacross_type THEN 
		LET l_msgresp = kandoomsg("G",9094,"") 
		#9094 "Report IS NOT an Analysis across type."
		RETURN 
	END IF 

	#OPEN the maintenance window
	OPEN WINDOW g527 with FORM "G527" 
	CALL windecoration_g("G527") 

	DECLARE segcol_curs CURSOR FOR 
	SELECT rptcolaa.* FROM rptcolaa 
	WHERE rptcolaa.col_uid = p_col_uid 
	AND rptcolaa.cmpy_code = glob_rec_kandoouser.cmpy_code 

	LET l_saa_cnt = 0 
	FOREACH segcol_curs INTO l_rec_rptcolaa.* 
		LET l_saa_cnt = l_saa_cnt + 1 
		LET l_arr_rec_segcol[l_saa_cnt].start_num = l_rec_rptcolaa.start_num 
		LET l_arr_rec_segcol[l_saa_cnt].flex_clause = l_rec_rptcolaa.flex_clause 
		--   IF l_saa_cnt < 6 THEN
		--      DISPLAY l_arr_rec_segcol[l_saa_cnt].start_num,
		--              l_arr_rec_segcol[l_saa_cnt].flex_clause
		--           TO sa_segcol[l_saa_cnt].start_num,
		--              sa_segcol[l_saa_cnt].flex_clause
		--
		--   END IF
	END FOREACH 

	--CALL set_count(l_saa_cnt)
	INPUT ARRAY l_arr_rec_segcol WITHOUT DEFAULTS FROM sa_segcol.* attributes(UNBUFFERED) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GW3a","inp-arr-segcol") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield(flex_clause) 
			CALL show_flex(glob_rec_kandoouser.cmpy_code, l_arr_rec_segcol[l_idx].start_num) 
			RETURNING l_arr_rec_segcol[l_idx].flex_clause 

			#DISPLAY l_arr_rec_segcol[l_idx].flex_clause
			#     TO sa_segcol[fv_scrn].flex_clause




		BEFORE ROW 
			LET l_idx = arr_curr() 
			#LET fv_scrn = scr_line()
			IF l_idx > 99 THEN 
				LET l_msgresp = kandoomsg("U",9916,"") 
				#9916 Cannot INSERT another row. The INPUT ARRAY IS full.
				LET l_idx = 100 
				NEXT FIELD start_num 
			END IF 

		BEFORE FIELD start_num 
			IF l_arr_rec_segcol[l_idx].start_num = 0 THEN 
				LET l_arr_rec_segcol[l_idx].start_num = NULL 
			END IF 

		AFTER FIELD start_num 
			IF l_arr_rec_segcol[l_idx].start_num IS NOT NULL THEN 
				# Check that this IS a valid start_num FROM within the structure table.
				SELECT * FROM structure 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND start_num = l_arr_rec_segcol[l_idx].start_num 
				IF status THEN 
					LET l_msgresp = kandoomsg("G",9217,"") 
					#9217 "Invalid start number FROM within the account structure."
					NEXT FIELD start_num 
				END IF 
			END IF 
			#   ON KEY (control-w)
			#      CALL kandoohelp("")
	END INPUT 

	LET l_saa_cnt = arr_count() 
	IF NOT (int_flag OR quit_flag) THEN 
		#Delete existing descline row.
		DELETE FROM rptcolaa 
		WHERE col_uid = p_col_uid 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		FOR l_idx = 1 TO l_saa_cnt 
			IF l_arr_rec_segcol[l_idx].flex_clause IS NOT NULL THEN 
				INSERT INTO rptcolaa VALUES ( glob_rec_kandoouser.cmpy_code, 
				glob_rec_rptcol.rpt_id, 
				p_col_uid, 
				l_idx, 
				l_arr_rec_segcol[l_idx].start_num, 
				l_arr_rec_segcol[l_idx].flex_clause) 
			END IF 
		END FOR 
	END IF 
	LET int_flag = false 
	LET quit_flag = false 

	CLOSE WINDOW g527 

END FUNCTION 



############################################################
# FUNCTION time_maint(p_seq_num, p_col_uid)
#
#
############################################################
FUNCTION time_maint(p_seq_num, p_col_uid) 
	DEFINE p_seq_num INTEGER 
	DEFINE p_col_uid INTEGER 

	DEFINE l_idx INTEGER 
	DEFINE l_rec_colitemdetl RECORD LIKE colitemdetl.* 
	DEFINE l_msgresp LIKE language.yes_flag 

	#OPEN the maintenance window
	OPEN WINDOW g514 with FORM "G514" 
	CALL windecoration_g("G514") 

	IF p_col_uid > 0 AND p_col_uid IS NOT NULL THEN 
		SELECT * INTO l_rec_colitemdetl.* FROM colitemdetl 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND rpt_id = glob_rec_rptcol.rpt_id 
		AND col_uid = p_col_uid 
		AND seq_num = p_seq_num 
	END IF 

	# Set VALUES IF l_rec_colitemdetl IS NULL
	IF l_rec_colitemdetl.year_num IS NULL THEN 
		LET l_rec_colitemdetl.year_num = 0 
	END IF 
	IF l_rec_colitemdetl.year_num IS NULL THEN 
		LET l_rec_colitemdetl.year_type = glob_rec_mrwparms.offset_type 
	END IF 
	IF l_rec_colitemdetl.year_num IS NULL THEN 
		LET l_rec_colitemdetl.period_num = 0 
	END IF 
	IF l_rec_colitemdetl.year_num IS NULL THEN 
		LET l_rec_colitemdetl.period_type = glob_rec_mrwparms.offset_type 
	END IF 

	DISPLAY BY NAME glob_arr_reccolitem[p_seq_num].col_item, 
	glob_arr_reccolitem[p_seq_num].item_desc 
	IF l_rec_colitemdetl.year_type IS NULL THEN 
		LET l_rec_colitemdetl.year_type = "O" 
	END IF 
	IF l_rec_colitemdetl.period_type IS NULL THEN 
		LET l_rec_colitemdetl.period_type = "O" 
	END IF 
	LET l_msgresp = kandoomsg("W",1100,"") 
	#1100 Enter Year AND Period.
	INPUT BY NAME l_rec_colitemdetl.year_num, 
	l_rec_colitemdetl.year_type, 
	l_rec_colitemdetl.period_num, 
	l_rec_colitemdetl.period_type WITHOUT DEFAULTS 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GW3a","inp-colitemdetl") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER INPUT 
			CASE 
				WHEN l_rec_colitemdetl.year_num IS NULL 
					LET l_msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD year_num 
				WHEN l_rec_colitemdetl.year_type IS NULL 
					LET l_msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD year_type 
				WHEN l_rec_colitemdetl.period_num IS NULL 
					LET l_msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD period_num 
				WHEN l_rec_colitemdetl.period_type IS NULL 
					LET l_msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD period_type 
			END CASE 
			IF l_rec_colitemdetl.year_type = glob_rec_mrwparms.offset_type THEN 
				IF l_rec_colitemdetl.year_num >= -100 
				AND l_rec_colitemdetl.year_num <= 100 THEN 
				ELSE 
					LET l_msgresp = kandoomsg("G",9105,"") 
					#9105 "Invalid offset year range.  Valid range IS -100 TO 100."
					NEXT FIELD year_num 
				END IF 
			END IF 
			IF l_rec_colitemdetl.year_type = glob_rec_mrwparms.specific_type THEN 
				#Valid the year.
				SELECT unique year_num FROM period 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND year_num = l_rec_colitemdetl.year_num 
				IF status = NOTFOUND THEN 
					LET l_msgresp = kandoomsg("U",9111,"Year") 
					#9105 Year NOT found;
					NEXT FIELD year_num 
				END IF 
			END IF 
			IF l_rec_colitemdetl.period_type = glob_rec_mrwparms.specific_type THEN 
				#Valid the period.
				SELECT unique period_num FROM period 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND period_num = l_rec_colitemdetl.period_num 
				IF status = NOTFOUND THEN 
					LET l_msgresp = kandoomsg("U",9111,"Period") 
					#9105 Period NOT found;
					NEXT FIELD period_num 
				END IF 
			END IF 
			IF l_rec_colitemdetl.year_type = glob_rec_mrwparms.specific_type 
			AND l_rec_colitemdetl.period_type = glob_rec_mrwparms.specific_type THEN 
				SELECT * FROM period 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND year_num = l_rec_colitemdetl.year_num 
				AND period_num = l_rec_colitemdetl.period_num 
				IF status = NOTFOUND THEN 
					LET l_msgresp = kandoomsg("U",9111,"Period") 
					#9105 Period NOT found;
					NEXT FIELD period_num 
				END IF 
			END IF 
			#   ON KEY (control-w)
			#      CALL kandoohelp("")
	END INPUT 

	IF NOT (int_flag OR quit_flag) THEN 
		#Delete existing colitemdetl row.
		CALL delete_col_types(p_seq_num, p_col_uid) 
		INSERT INTO colitemdetl VALUES ( glob_rec_kandoouser.cmpy_code, 
		glob_rec_rptcol.rpt_id, 
		p_col_uid, 
		p_seq_num, 
		l_rec_colitemdetl.year_num, 
		l_rec_colitemdetl.year_type, 
		l_rec_colitemdetl.period_num, 
		l_rec_colitemdetl.period_type ) 
	END IF 
	LET int_flag = false 
	LET quit_flag = false 
	CLOSE WINDOW g514 

END FUNCTION 




############################################################
# FUNCTION column_maint(p_seq_num, p_col_uid)
#
#
############################################################
FUNCTION column_maint(p_seq_num, p_col_uid) 
	DEFINE p_col_uid INTEGER 
	DEFINE p_seq_num INTEGER 
	DEFINE l_rec_colitemcolid RECORD LIKE colitemcolid.* 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_idx INTEGER 

	#OPEN the maintenance window
	OPEN WINDOW g512 with FORM "G512" 
	CALL windecoration_g("G512") 

	IF p_col_uid > 0 AND p_col_uid IS NOT NULL THEN 
		SELECT * INTO l_rec_colitemcolid.* FROM colitemcolid 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND rpt_id = glob_rec_rptcol.rpt_id 
		AND col_uid = p_col_uid 
		AND seq_num = p_seq_num 
	END IF 

	DISPLAY BY NAME glob_arr_reccolitem[p_seq_num].col_item, 
	glob_arr_reccolitem[p_seq_num].item_desc 


	LET l_msgresp = kandoomsg("G",1072,"") 
	#1072 Enter Column Details; OK TO Continue.

	INPUT BY NAME l_rec_colitemcolid.id_col_id WITHOUT DEFAULTS 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GW3a","inp-colitemid") 


		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER FIELD id_col_id 
			IF l_rec_colitemcolid.id_col_id < glob_rec_rptcol.col_id THEN 
				SELECT col_id FROM rptcol 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND rpt_id = glob_rec_rptcol.rpt_id 
				AND col_id = l_rec_colitemcolid.id_col_id 
				IF status = NOTFOUND THEN 
					LET l_msgresp = kandoomsg("U",9910,"") 
					#9910 RECORD NOT found;
					LET l_rec_colitemcolid.id_col_id = 0 
					NEXT FIELD id_col_id 
				END IF 
			ELSE 
				LET l_msgresp = kandoomsg("G",9095,glob_rec_rptcol.col_id) 
				#9095 "Column identifier must be less than the current COLUMN id."
				LET l_rec_colitemcolid.id_col_id = 0 
				NEXT FIELD id_col_id 
			END IF 
			#   ON KEY (control-w)
			#      CALL kandoohelp("")
	END INPUT 

	IF NOT (int_flag OR quit_flag) THEN 
		LET glob_arr_reccolitem[p_seq_num].id_col_id = l_rec_colitemcolid.id_col_id 
		#Delete existing colitemcolid row.
		CALL delete_col_types(p_seq_num, p_col_uid) 
		INSERT INTO colitemcolid VALUES ( glob_rec_kandoouser.cmpy_code, 
		glob_rec_rptcol.rpt_id, 
		p_col_uid, 
		p_seq_num, 
		l_rec_colitemcolid.id_col_id ) 
	END IF 
	LET int_flag = false 
	LET quit_flag = false 
	CLOSE WINDOW g512 

END FUNCTION 



############################################################
# FUNCTION value_maint(p_seq_num, p_col_uid)
#
#
############################################################
FUNCTION value_maint(p_seq_num, p_col_uid) 
	DEFINE p_seq_num INTEGER 
	DEFINE p_col_uid INTEGER 

	DEFINE l_idx INTEGER 
	DEFINE l_rec_colitemval RECORD LIKE colitemval.* 
	DEFINE l_msgresp LIKE language.yes_flag 

	OPEN WINDOW g515 with FORM "G515" 
	CALL windecoration_g("G515") 

	IF p_col_uid > 0 AND p_col_uid IS NOT NULL THEN 
		SELECT * INTO l_rec_colitemval.* FROM colitemval 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND rpt_id = glob_rec_rptcol.rpt_id 
		AND col_uid = p_col_uid 
		AND seq_num = p_seq_num 
	END IF 

	DISPLAY BY NAME glob_arr_reccolitem[p_seq_num].col_item, 
	glob_arr_reccolitem[p_seq_num].item_desc 


	LET l_msgresp = kandoomsg("G",1073,"") 
	#1073 Enter Item Value; OK TO Continue.
	INPUT BY NAME l_rec_colitemval.item_value WITHOUT DEFAULTS 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GW3a","inp-colitemval") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END INPUT 

	IF NOT (int_flag OR quit_flag) THEN 
		#Delete existing colitemval row.
		CALL delete_col_types(p_seq_num, p_col_uid) 
		INSERT INTO colitemval VALUES ( glob_rec_kandoouser.cmpy_code, 
		glob_rec_rptcol.rpt_id, 
		p_col_uid, 
		p_seq_num, 
		l_rec_colitemval.item_value ) 
	END IF 
	LET int_flag = false 
	LET quit_flag = false 
	CLOSE WINDOW g515 

END FUNCTION 
