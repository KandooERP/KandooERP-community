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

	Source code beautified by beautify.pl on 2020-01-03 10:36:59	$Id: $
}



# Purpose    :    Batch Enquiry - Scans 'fabatch' AND 'faaudit'


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "F_FA_GLOBALS.4gl" 
GLOBALS "FBS_GLOBALS.4gl" 

MAIN 
	DEFINE bat_array DYNAMIC ARRAY OF RECORD --array[2000] OF RECORD 
		jour_num LIKE fabatch.jour_num, 
		batch_num LIKE fabatch.batch_num, 
		year_num LIKE fabatch.year_num, 
		period_num LIKE fabatch.period_num, 
		actual_asset_amt LIKE fabatch.actual_asset_amt, 
		control_asset_amt LIKE fabatch.control_asset_amt, 
		cleared_flag LIKE fabatch.cleared_flag, 
		post_asset_flag LIKE fabatch.post_asset_flag, 
		post_gl_flag LIKE fabatch.post_gl_flag 
	END RECORD 
	DEFINE p_fabatch RECORD LIKE fabatch.* 
	DEFINE pr_jour_num LIKE fabatch.jour_num 
	DEFINE query_text CHAR(600) 
	DEFINE scrn SMALLINT 
	DEFINE idx SMALLINT 
	DEFINE where_text CHAR(500) 
	DEFINE sel_text CHAR(900) 

	#Initial UI Init
	CALL setModuleId("FBS") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	WHILE true 
		OPEN WINDOW f151 with FORM "F151" -- alch kd-757 
		CALL  windecoration_f("F151") -- alch kd-757 
		#
		# An argument will be passed FROM the batch posting program
		#
		IF num_args() > 0 THEN 
			LET query_text = arg_val(1) 
		ELSE 
			LET msgresp = kandoomsg("U",1001,"") 
			CONSTRUCT BY NAME where_text ON fabatch.jour_num, 
			fabatch.batch_num, 
			fabatch.year_num, 
			fabatch.period_num, 
			fabatch.actual_asset_amt, 
			fabatch.control_asset_amt, 
			fabatch.cleared_flag, 
			fabatch.post_asset_flag, 
			fabatch.post_gl_flag 

				BEFORE CONSTRUCT 
					CALL publish_toolbar("kandoo","FBS","const-fabatch-3") -- alch kd-504 

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) -- alch kd-371 

			END CONSTRUCT 
			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
				EXIT program 
			END IF 
			LET query_text = "SELECT * ", 
			"FROM fabatch ", 
			"WHERE cmpy_code = \"", glob_rec_kandoouser.cmpy_code, "\" ", 
			"AND ",where_text clipped," ", 
			"ORDER BY batch_num" 
		END IF 

		PREPARE statement1 FROM query_text 
		DECLARE bat_curs CURSOR FOR statement1 

		LET idx = 0 
		FOREACH bat_curs INTO p_fabatch.* 
			LET idx = idx + 1 
			LET bat_array[idx].jour_num = p_fabatch.jour_num 
			LET bat_array[idx].batch_num = p_fabatch.batch_num 
			LET bat_array[idx].year_num = p_fabatch.year_num 
			LET bat_array[idx].period_num = p_fabatch.period_num 
			LET bat_array[idx].actual_asset_amt 
			= p_fabatch.actual_asset_amt 
			LET bat_array[idx].control_asset_amt 
			= p_fabatch.control_asset_amt 
			LET bat_array[idx].cleared_flag = p_fabatch.cleared_flag 
			LET bat_array[idx].post_asset_flag = p_fabatch.post_asset_flag 
			LET bat_array[idx].post_gl_flag = p_fabatch.post_gl_flag 
			--          IF idx = 2000 THEN
			--             LET msgresp = kandoomsg("U",6100,idx)
			--             #6100 First XXXX records selected only. More may be available.
			--             EXIT FOREACH
			--          END IF
		END FOREACH 
		--       CALL set_count(idx)
		LET msgresp = kandoomsg("U",9113,idx) 
		#9113 XXX records selected.
		OPTIONS INSERT KEY f36, 
		DELETE KEY f36 
		LET msgresp = kandoomsg("F",1512,"") 
		#1512 TAB TO view line; F5 Batch.

		INPUT ARRAY bat_array WITHOUT DEFAULTS FROM s_fabatch.* 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","FBS","inp_arr-bat_array-2") -- alch kd-504 

			AFTER ROW 
				DISPLAY bat_array[idx].* TO s_fabatch[scrn].* 

			BEFORE FIELD jour_num 
				LET idx = arr_curr() 
				LET scrn = scr_line() 
				LET pr_jour_num = bat_array[idx].jour_num 
				DISPLAY bat_array[idx].* TO s_fabatch[scrn].* 

			AFTER FIELD jour_num 
				LET bat_array[idx].jour_num = pr_jour_num 
				IF bat_array[idx+1].actual_asset_amt IS NULL 
				AND fgl_lastkey() = fgl_keyval("down") THEN 
					LET msgresp = kandoomsg("U",9001,"") 
					#9001 There are no more rows in the direction you are going.
					NEXT FIELD jour_num 
				END IF 

			BEFORE FIELD batch_num 
				IF bat_array[idx].actual_asset_amt IS NOT NULL THEN 
					CALL disp_audit(bat_array[idx].batch_num) 
				END IF 
				NEXT FIELD jour_num 

			ON KEY (F5) 
				IF bat_array[idx].jour_num IS NOT NULL THEN 
					IF bat_array[idx].jour_num != 0 THEN 
						LET sel_text = "\"QUERY_TEXT=SELECT * FROM batchhead ", 
						"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
						"AND jour_num = ",bat_array[idx].jour_num, 
						"\"" 

						CALL run_prog("G26",sel_text,"","","") 
					ELSE 
						LET msgresp = kandoomsg("F",9528,"") 
						#9528 No GL batch TO view.
					END IF 
				END IF 
			ON KEY (control-w) 
				CALL kandoohelp("") 
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
		END INPUT 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			IF num_args() > 0 THEN 
				EXIT program 
			END IF 
		END IF 
		CLOSE WINDOW f151 
	END WHILE 
END MAIN 


FUNCTION disp_audit(pr_batch_num) 
	DEFINE 
	p_faaudit RECORD LIKE faaudit.*, 
	aud_array array[2000] OF RECORD 
		batch_line_num LIKE faaudit.batch_line_num, 
		asset_code LIKE faaudit.asset_code, 
		book_code LIKE faaudit.book_code, 
		location_code LIKE faaudit.location_code, 
		faresp_code LIKE faaudit.faresp_code, 
		facat_code LIKE faaudit.facat_code, 
		asset_amt LIKE faaudit.asset_amt, 
		depr_amt LIKE faaudit.depr_amt 
	END RECORD, 
	pr_batch_line_num LIKE faaudit.batch_line_num, 
	pr_batch_num LIKE fabatch.batch_num, 
	idx, 
	scrn SMALLINT 

	OPEN WINDOW f152 with FORM "F152" -- alch kd-757 
	CALL  windecoration_f("F152") -- alch kd-757 

	LET msgresp = kandoomsg("U",1534,"") 
	#1534 TAB TO view line; OK TO continue.
	DECLARE aud_curs CURSOR FOR 
	SELECT * FROM faaudit 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND batch_num = pr_batch_num 
	LET idx = 0 
	FOREACH aud_curs INTO p_faaudit.* 
		LET idx = idx + 1 
		IF idx > 2000 THEN 
			EXIT FOREACH 
		END IF 
		LET aud_array[idx].batch_line_num = p_faaudit.batch_line_num 
		LET aud_array[idx].asset_code = p_faaudit.asset_code 
		LET aud_array[idx].book_code = p_faaudit.book_code 
		LET aud_array[idx].location_code = p_faaudit.location_code 
		LET aud_array[idx].faresp_code = p_faaudit.faresp_code 
		LET aud_array[idx].facat_code = p_faaudit.facat_code 
		LET aud_array[idx].asset_amt = p_faaudit.asset_amt 
		LET aud_array[idx].depr_amt = p_faaudit.depr_amt 
	END FOREACH 
	CALL set_count(idx) 
	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 
	INPUT ARRAY aud_array WITHOUT DEFAULTS FROM s_faaudit.* 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","FBS","inp_arr-aud_array-2") -- alch kd-504 
		AFTER ROW 
			DISPLAY aud_array[idx].* TO s_faaudit[scrn].* 
		BEFORE FIELD batch_line_num 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			LET pr_batch_line_num = aud_array[idx].batch_line_num 
			DISPLAY aud_array[idx].* TO s_faaudit[scrn].* 

		AFTER FIELD batch_line_num 
			LET aud_array[idx].batch_line_num = pr_batch_line_num 
			IF aud_array[idx+1].asset_code IS NULL 
			AND fgl_lastkey() = fgl_keyval("down") THEN 
				LET msgresp = kandoomsg("U",9001,"")	#9001 There are no more rows in the direction you are going.
				NEXT FIELD batch_line_num 
			END IF 

		BEFORE FIELD asset_code 
			IF aud_array[idx].asset_code IS NOT NULL THEN 
				CALL FBS_disp_faaudit_detail(pr_batch_num, aud_array[idx].batch_line_num) 
			END IF 
			NEXT FIELD batch_line_num 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
	END INPUT 

	CLOSE WINDOW f152 

	LET int_flag = false 
	LET quit_flag = false 
END FUNCTION 


FUNCTION FBS_disp_faaudit_detail(pr_batch_num, pr_batch_line_num) 
	DEFINE p_faaudit RECORD LIKE faaudit.* 
	DEFINE pr_batch_num LIKE fabatch.batch_num 
	DEFINE pr_batch_line_num LIKE faaudit.batch_line_num 

	OPEN WINDOW f153 with FORM "F153" -- alch kd-757 
	CALL  windecoration_f("F153") -- alch kd-757 

	SELECT * INTO p_faaudit.* FROM faaudit 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND batch_num = pr_batch_num 
	AND batch_line_num = pr_batch_line_num 

	DISPLAY BY NAME p_faaudit.batch_num, 
	p_faaudit.batch_line_num, 
	p_faaudit.asset_code, 
	p_faaudit.book_code, 
	p_faaudit.year_num, 
	p_faaudit.period_num, 
	p_faaudit.trans_ind, 
	p_faaudit.entry_text, 
	p_faaudit.entry_date, 
	p_faaudit.asset_amt, 
	p_faaudit.depr_amt, 
	p_faaudit.net_book_val_amt, 
	p_faaudit.rem_life_num, 
	p_faaudit.location_code, 
	p_faaudit.faresp_code, 
	p_faaudit.facat_code, 
	p_faaudit.desc_text 

	LET msgresp = kandoomsg("U",2,"") 
	#2 Any Key TO Continue.
	CLOSE WINDOW f153 
END FUNCTION 
