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


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "F_FA_GLOBALS.4gl" 

# Purpose    :    Batch Clearance
#                 culled FROM batch scan

GLOBALS 
	DEFINE p_fabatch RECORD LIKE fabatch.*, 
	p_faaudit RECORD LIKE faaudit.*, 
	counter SMALLINT, 
	counter2 SMALLINT, 
	sline SMALLINT, 
	where_text CHAR(500), 
	query_text CHAR(600), 
	ans CHAR(1) 

	DEFINE bat_array array[2000] OF 
	RECORD 
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

	DEFINE aud_array array[2000] OF 
	RECORD 
		batch_line_num LIKE faaudit.batch_line_num, 
		asset_code LIKE faaudit.asset_code, 
		book_code LIKE faaudit.book_code, 
		location_code LIKE faaudit.location_code, 
		faresp_code LIKE faaudit.faresp_code, 
		facat_code LIKE faaudit.facat_code, 
		asset_amt LIKE faaudit.asset_amt, 
		depr_amt LIKE faaudit.depr_amt 
	END RECORD 
END GLOBALS 

MAIN 
	DEFINE 
	pr_jour_num LIKE fabatch.jour_num 

	#Initial UI Init
	CALL setModuleId("FBC") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	WHILE true 
		OPEN WINDOW f151 with FORM "F151" 
		CALL  windecoration_f("F151") -- alch kd-757 
		DISPLAY "Batch Clearance" at 3,27 
		#
		# An argument will be passed FROM the batch posting program
		#
		IF num_args() > 0 THEN 
			LET query_text = arg_val(1) 
		ELSE 
			LET msgresp = kandoomsg("U",1001,"") 
			#1001 Enter Selection Criteria;  OK TO Continue.
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
					CALL publish_toolbar("kandoo","FBC","const-fabatch-2") -- alch kd-504 
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
			END CONSTRUCT 
			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
				EXIT program 
			END IF 

			LET query_text = "SELECT * FROM fabatch WHERE ", 
			"cmpy_code = \"", glob_rec_kandoouser.cmpy_code, "\" AND ", 
			"post_asset_flag = \"N\" AND ", 
			where_text clipped, " ORDER BY batch_num" 
		END IF 


		PREPARE statement1 FROM query_text 
		DECLARE bat_curs CURSOR FOR statement1 

		LET counter = 0 
		FOREACH bat_curs INTO p_fabatch.* 
			LET counter = counter + 1 
			IF counter > 2000 THEN 
				LET msgresp = kandoomsg("U",1505,counter) 
				#1505 Only first idx rows selected.
				EXIT FOREACH 
			END IF 
			LET bat_array[counter].jour_num = p_fabatch.jour_num 
			LET bat_array[counter].batch_num = p_fabatch.batch_num 
			LET bat_array[counter].year_num = p_fabatch.year_num 
			LET bat_array[counter].period_num = p_fabatch.period_num 
			LET bat_array[counter].actual_asset_amt 
			= p_fabatch.actual_asset_amt 
			LET bat_array[counter].control_asset_amt 
			= p_fabatch.control_asset_amt 
			LET bat_array[counter].cleared_flag = p_fabatch.cleared_flag 
			LET bat_array[counter].post_asset_flag = p_fabatch.post_asset_flag 
			LET bat_array[counter].post_gl_flag = p_fabatch.post_gl_flag 

		END FOREACH 

		IF counter = 0 THEN 
			LET msgresp = kandoomsg("P",9510,"") 
			#9510 No batches are ready TO be cleared.
			CLOSE WINDOW f151 
			IF num_args() > 0 THEN 
				EXIT program 
			ELSE 
				CONTINUE WHILE 
			END IF 
		END IF 
		CALL set_count(counter) 

		LET msgresp = kandoomsg("P",1511,"") 
		#1511 TAB FOR details; F7 Set cleared; OK TO UPDATE.
		LET msgresp = kandoomsg("U",9113,counter) 
		#9113 XXX records selected.
		OPTIONS INSERT KEY f36, 
		DELETE KEY f36 
		INPUT ARRAY bat_array WITHOUT DEFAULTS FROM s_fabatch.* 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","FBC","inp_arr-bat_array-1") -- alch kd-504 
			ON KEY (F7) 
				LET counter = arr_curr() 
				LET sline = scr_line() 
				IF bat_array[counter].cleared_flag = "N" THEN 
					CALL check_control() 
				ELSE 
					LET bat_array[counter].cleared_flag = "N" 
				END IF 
				DISPLAY bat_array[counter].cleared_flag TO 
				s_fabatch[sline].cleared_flag 
			AFTER ROW 
				DISPLAY bat_array[counter].* TO s_fabatch[sline].* 
			BEFORE FIELD jour_num 
				LET counter = arr_curr() 
				LET sline = scr_line() 
				LET pr_jour_num = bat_array[counter].jour_num 
				DISPLAY bat_array[counter].* TO s_fabatch[sline].* 
			AFTER FIELD jour_num 
				LET bat_array[counter].jour_num = pr_jour_num 
				IF bat_array[counter+1].actual_asset_amt IS NULL 
				AND fgl_lastkey() = fgl_keyval("down") THEN 
					LET msgresp = kandoomsg("U",9001,"") 
					#9001 There are no more rows in the direction you are going.
					NEXT FIELD jour_num 
				END IF 
			BEFORE FIELD batch_num 
				IF bat_array[counter].actual_asset_amt IS NOT NULL THEN 
					CALL disp_audit() 
				END IF 
				NEXT FIELD jour_num 
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

		LET counter = 0 
		FOREACH bat_curs INTO p_fabatch.* 
			LET counter = counter + 1 
			UPDATE fabatch 
			SET cleared_flag = bat_array[counter].cleared_flag WHERE 
			cmpy_code = glob_rec_kandoouser.cmpy_code AND 
			batch_num = bat_array[counter].batch_num AND 
			year_num = bat_array[counter].year_num AND 
			period_num = bat_array[counter].period_num 
		END FOREACH 
		CLOSE WINDOW f151 
	END WHILE 
END MAIN 


FUNCTION disp_audit() 
	DEFINE 
	pr_batch_line_num LIKE faaudit.batch_line_num, 
	scrn SMALLINT 

	OPEN WINDOW w_f152 with FORM "F152" -- alch kd-757 
	CALL  windecoration_f("F152") -- alch kd-757 
	LET msgresp = kandoomsg("U",1000,"DISPLAY all details") 
	#1000 ENTER on line TO DISPLAY all details.
	DECLARE aud_curs CURSOR FOR 
	SELECT * FROM faaudit 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND batch_num = bat_array[counter].batch_num 

	LET counter2 = 0 
	FOREACH aud_curs INTO p_faaudit.* 
		LET counter2 = counter2 + 1 
		IF counter2 > 2000 THEN 
			EXIT FOREACH 
		END IF 
		LET aud_array[counter2].batch_line_num = p_faaudit.batch_line_num 
		LET aud_array[counter2].asset_code = p_faaudit.asset_code 
		LET aud_array[counter2].book_code = p_faaudit.book_code 
		LET aud_array[counter2].location_code = p_faaudit.location_code 
		LET aud_array[counter2].faresp_code = p_faaudit.faresp_code 
		LET aud_array[counter2].facat_code = p_faaudit.facat_code 
		LET aud_array[counter2].asset_amt = p_faaudit.asset_amt 
		LET aud_array[counter2].depr_amt = p_faaudit.depr_amt 
	END FOREACH 
	CALL set_count(counter2) 
	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 
	INPUT ARRAY aud_array WITHOUT DEFAULTS FROM s_faaudit.* 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","FBC","inp_arr-aud_array-1") -- alch kd-504 
		AFTER ROW 
			DISPLAY aud_array[counter2].* TO s_faaudit[scrn].* 
		BEFORE FIELD batch_line_num 
			LET counter2 = arr_curr() 
			LET scrn = scr_line() 
			LET pr_batch_line_num = aud_array[counter2].batch_line_num 
			DISPLAY aud_array[counter2].* TO s_faaudit[scrn].* 
		AFTER FIELD batch_line_num 
			LET aud_array[counter2].batch_line_num = pr_batch_line_num 
			IF aud_array[counter2+1].asset_code IS NULL 
			AND fgl_lastkey() = fgl_keyval("down") THEN 
				LET msgresp = kandoomsg("U",9001,"") 
				#9001 There are no more rows in the direction you are going.
				NEXT FIELD batch_line_num 
			END IF 
			
		BEFORE FIELD asset_code 
			IF aud_array[counter2].asset_code IS NOT NULL THEN 
				CALL FBC_disp_faaudit_detail() 
			END IF 
			NEXT FIELD batch_line_num 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) -- alch kd-371 

	END INPUT 

	CLOSE WINDOW w_f152 
END FUNCTION 

FUNCTION FBC_disp_faaudit_detail() 
	OPEN WINDOW w_f153 with FORM "F153" -- alch kd-757 
	CALL  windecoration_f("F153") -- alch kd-757 

	SELECT * INTO p_faaudit.* FROM faaudit 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND batch_num = bat_array[counter].batch_num AND 
	batch_line_num = aud_array[counter2].batch_line_num 

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
	#2 Any key TO continue.
	CLOSE WINDOW w_f153 
END FUNCTION 

FUNCTION check_control() 
	DEFINE 
	pr_fabatch RECORD LIKE fabatch.*, 
	ans CHAR(1), 
	runner CHAR(100) 

	SELECT * INTO pr_fabatch.* 
	FROM fabatch 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND batch_num = bat_array[counter].batch_num 
	AND year_num = bat_array[counter].year_num 
	AND period_num = bat_array[counter].period_num 

	IF pr_fabatch.control_asset_amt <> pr_fabatch.actual_asset_amt OR 
	pr_fabatch.control_depr_amt <> pr_fabatch.actual_depr_amt OR 
	pr_fabatch.control_line_num <> pr_fabatch.actual_line_num THEN 
		LET ans = kandoomsg("F",8011,"") 
		#8011 Batch IS out of balance. Edit batch?
		IF ans = "Y" THEN 
			CALL run_prog("F28",pr_fabatch.batch_num,pr_fabatch.year_num,pr_fabatch.period_num,"") 
		ELSE 
			LET msgresp = kandoomsg("F",9531,"") 
			#9531 Cleared flag will NOT be updated until batch IS in balance.
		END IF 
	ELSE 
		LET bat_array[counter].cleared_flag = "Y" 
	END IF 
END FUNCTION 
