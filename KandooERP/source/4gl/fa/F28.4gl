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

	Source code beautified by beautify.pl on 2020-01-03 10:36:54	$Id: $
}




# Purpose   :   Edit Fixed Asset Batches

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "F_FA_GLOBALS.4gl" 
GLOBALS "F28_GLOBALS.4gl" 

MAIN 

	#Initial UI Init
	CALL setModuleId("F28") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	LET ans = "Y" 
	LET success_flag = 0 
	WHILE ans = "Y" 
		LET int_flag = 0 
		LET quit_flag = 0 
		IF NOT header() THEN 
			IF int_flag OR quit_flag THEN 
				EXIT program 
			ELSE 
				CLOSE WINDOW f100 
				CONTINUE WHILE 
			END IF 
		END IF 
		IF int_flag OR quit_flag THEN 
			EXIT program 
		END IF 
		CASE 
			WHEN (global_tran_code = "A" OR 
				global_tran_code = "I") 
				CALL fafinadd(glob_rec_kandoouser.cmpy_code,global_tran_code) 
			WHEN (global_tran_code = "J" OR 
				global_tran_code = "L" OR 
				global_tran_code = "C") 
				CALL fafinadj(glob_rec_kandoouser.cmpy_code,global_tran_code) 
			WHEN (global_tran_code = "S" OR 
				global_tran_code = "T" OR 
				global_tran_code = "R" OR 
				global_tran_code = "V") 
				CALL fafintrn(glob_rec_kandoouser.cmpy_code,global_tran_code) 
		END CASE 
		IF int_flag = 0 AND quit_flag = 0 THEN 
			IF editit() THEN 
				LET mess = "Batch ",pr_fabatch.batch_num USING "<<<<<<<", 
				" edited successfully." 
				LET success_flag = 0 
			ELSE 
				LET mess = " Batch unchanged - cannot SET TO 0" 
			END IF 
		ELSE 
			LET mess = " Batch unchanged" 
		END IF 
	END WHILE 
END MAIN 

FUNCTION header() 

	DEFINE 
	err_code SMALLINT, 
	default_year, 
	tmp_year, 
	orig_year, 
	max_year LIKE period.year_num, 
	default_period, 
	tmp_period, 
	orig_period, 
	max_period LIKE period.period_num, 
	pr_tmp_text CHAR(10) 
	DEFINE msgresp LIKE language.yes_flag 

	LET err_code = true 

	OPEN WINDOW f100 with FORM "F100" -- alch kd-757 
	CALL  windecoration_f("F100") -- alch kd-757 

	MESSAGE mess attribute(yellow) 

	SELECT * INTO pr_faparms.* 
	FROM faparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 

	IF status = notfound THEN 
		LET msgresp = kandoomsg("U",5106,"") 
		#5106 Fixed Assets Paramters NOT SET up; Refer Menu FZP.
		CLOSE WINDOW f100 
		EXIT program 
	END IF 

	INITIALIZE pr_fabatch.* TO NULL 
	INPUT BY NAME pr_fabatch.batch_num, 
	pr_fabatch.year_num, 
	pr_fabatch.period_num, 
	pr_fabatch.com1_text, 
	pr_fabatch.com2_text, 
	pr_fabatch.control_line_num, 
	pr_fabatch.control_asset_amt, 
	pr_fabatch.control_depr_amt 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","F28","inp-pr_fabatch-3") -- alch kd-504 
			# next code so IF required they can enter journals in General Ledger
		BEFORE FIELD batch_num 
			IF num_args() > 0 THEN 
				LET pass_batch = arg_val(1) 
				SELECT * INTO pr_fabatch.* 
				FROM fabatch 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND batch_num = pass_batch 
				IF status = notfound THEN 
					LET msgresp = kandoomsg("G",9053,"") 
					#9053 Batch number NOT found.
					EXIT program 
				ELSE 
					DISPLAY BY NAME pr_fabatch.batch_num, 
					pr_fabatch.year_num, 
					pr_fabatch.period_num, 
					pr_fabatch.control_asset_amt, 
					pr_fabatch.control_depr_amt, 
					pr_fabatch.actual_asset_amt, 
					pr_fabatch.actual_depr_amt, 
					pr_fabatch.post_asset_flag, 
					pr_fabatch.post_gl_flag, 
					pr_fabatch.control_line_num, 
					pr_fabatch.actual_line_num, 
					pr_fabatch.cleared_flag, 
					pr_fabatch.jour_num, 
					pr_fabatch.com1_text, 
					pr_fabatch.com2_text 


					DECLARE tran_curs1 CURSOR FOR 
					SELECT trans_ind 
					FROM faaudit 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND batch_num = pr_fabatch.batch_num 

					OPEN tran_curs1 
					FETCH tran_curs1 INTO global_tran_code 
					CLOSE tran_curs1 

					CASE global_tran_code 
						WHEN "A" 
							LET trans_header = " Addition " 
						WHEN "J" 
							LET trans_header = " Adjustment " 
						WHEN "T" 
							LET trans_header = "Transfer - Intra Comapny" 
						WHEN "R" 
							LET trans_header = " Retirement " 
						WHEN "S" 
							LET trans_header = " Sale " 
						WHEN "L" 
							LET trans_header = " Life Adjustment " 
						WHEN "V" 
							LET trans_header = " Revaluation " 
						WHEN "D" 
							LET mess = "Depreciation batches cannot be edited" 
							LET err_code = false 
							EXIT INPUT 
						WHEN "C" 
							LET trans_header = "Depreciation Code Adjust" 
					END CASE 
					DISPLAY BY NAME trans_header 

					IF pr_fabatch.post_asset_flag = "Y" THEN 
						LET msgresp = kandoomsg("F",9532,"") 
						#9532 This batch has been posted. No changes allowed.
						NEXT FIELD batch_num 
					ELSE 
						IF pr_faparms.use_clear_flag = "Y" AND 
						pr_fabatch.cleared_flag = "Y" THEN 
							LET msgresp = kandoomsg("F",9533,"") 
							#9533 This batch has been cleared. No changes allowed.
							NEXT FIELD batch_num 
						END IF 
					END IF 
					NEXT FIELD year_num 
				END IF 
			END IF 

		AFTER FIELD batch_num 
			SELECT * INTO pr_fabatch.* FROM fabatch 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND batch_num = pr_fabatch.batch_num 
			LET default_year = pr_fabatch.year_num 
			LET orig_year = pr_fabatch.year_num 
			LET default_period = pr_fabatch.period_num 
			LET orig_period = pr_fabatch.period_num 

			IF status = notfound THEN 
				LET msgresp = kandoomsg("G",9053,"") 
				#9053 Batch number NOT found.
				NEXT FIELD batch_num 
			ELSE 
				DISPLAY BY NAME pr_fabatch.batch_num, 
				pr_fabatch.year_num, 
				pr_fabatch.period_num, 
				pr_fabatch.control_asset_amt, 
				pr_fabatch.control_depr_amt, 
				pr_fabatch.actual_asset_amt, 
				pr_fabatch.actual_depr_amt, 
				pr_fabatch.post_asset_flag, 
				pr_fabatch.post_gl_flag, 
				pr_fabatch.control_line_num, 
				pr_fabatch.actual_line_num, 
				pr_fabatch.cleared_flag, 
				pr_fabatch.jour_num, 
				pr_fabatch.com1_text, 
				pr_fabatch.com2_text 

			END IF 

			DECLARE tran_curs CURSOR FOR 
			SELECT trans_ind 
			FROM faaudit 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND batch_num = pr_fabatch.batch_num 

			OPEN tran_curs 
			FETCH tran_curs INTO global_tran_code 
			CLOSE tran_curs 

			CASE global_tran_code 
				WHEN "A" 
					LET trans_header = " Addition " 
				WHEN "J" 
					LET trans_header = " Adjustment " 
				WHEN "T" 
					LET trans_header = "Transfer - Intra Comapny" 
				WHEN "R" 
					LET trans_header = " Retirement " 
				WHEN "S" 
					LET trans_header = " Sale " 
				WHEN "L" 
					LET trans_header = " Life Adjustment " 
				WHEN "V" 
					LET trans_header = " Revaluation " 
				WHEN "D" 
					LET mess = "Depreciation batches cannot be edited" 
					LET err_code = false 
					EXIT INPUT 
				WHEN "C" 
					LET trans_header = "Depreciation Code Adjust" 
			END CASE 

			DISPLAY BY NAME trans_header 

			IF pr_fabatch.post_asset_flag = "Y" THEN 
				LET msgresp = kandoomsg("F",9532,"") 
				#9532 This batch has been posted. No changes allowed.
				NEXT FIELD batch_num 
			ELSE 
				IF pr_faparms.use_clear_flag = "Y" AND 
				pr_fabatch.cleared_flag = "Y" THEN 
					LET msgresp = kandoomsg("F",9533,"") 
					#9533 This batch has been cleared. No changes allowed.
					NEXT FIELD batch_num 
				END IF 
			END IF 


		AFTER FIELD period_num 
			CALL valid_period(
				glob_rec_kandoouser.cmpy_code,
				pr_fabatch.year_num, 
				pr_fabatch.period_num, 
				LEDGER_TYPE_GL) 
			RETURNING 
				pr_fabatch.year_num, 
				pr_fabatch.period_num, 
				failed 
			
			IF failed THEN 
				NEXT FIELD year_num 
			END IF 
			
			IF orig_year != pr_fabatch.year_num OR orig_period != pr_fabatch.period_num THEN 
				#check IF the year AND period are before the oldest y+p currently in
				# fabatch
				LET max_year = 0 
				LET max_period = 0 
				SELECT max(year_num) 
				INTO max_year 
				FROM fabatch 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND post_asset_flag = "Y" 

				SELECT max(period_num) 
				INTO max_period 
				FROM fabatch 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND year_num = max_year 
				AND post_asset_flag = "Y" 

				IF max_year IS NULL THEN 
					LET max_year = 0 
				END IF 
				IF max_period IS NULL THEN 
					LET max_period = 0 
				END IF 

				# check IF the maximum posted period IS before the current period
				IF max_year < default_year OR (max_year = default_year AND 
				max_period < default_period) THEN 
					# check FOR unposted batches in OR AFTER maximum posted y&p

					SELECT max(year_num) 
					INTO tmp_year 
					FROM fabatch 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND year_num > max_year OR 
					(year_num = max_year AND 
					period_num >= max_period) 
					AND post_asset_flag = "N" 

					SELECT max(period_num) 
					INTO tmp_period 
					FROM fabatch 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND period_num >= max_period 
					AND year_num = tmp_year 
					AND post_asset_flag = "N" 

					IF NOT (tmp_year IS NULL AND tmp_period IS null) THEN 
						{unposted batches in OR AFTER max posted}
						# IF unposted batches are AFTER current y&p THEN
						# they must be posted prior TO further batches being entered
						IF tmp_year > default_year OR 
						(tmp_year = default_year AND 
						tmp_period > default_period) THEN 
							LET pr_tmp_text = tmp_year USING "<<<<"," ", 
							tmp_period USING "<<<" 
							LET msgresp = kandoomsg("F",9534,pr_tmp_text) 
							#9534 The batches must be posted in XXXX XX before
							#     entering batches.
							NEXT FIELD year_num 
						END IF 
						LET max_year = tmp_year 
						LET max_period = tmp_period 
						IF pr_fabatch.year_num != max_year OR 
						pr_fabatch.period_num != max_period THEN 
							LET pr_tmp_text = max_year USING "<<<<"," ", 
							max_period USING "<<<" 
							LET msgresp = kandoomsg("F",9535,pr_tmp_text) 
							#9535 The batches must be posted TO XXXX XXX.
							NEXT FIELD year_num 
						END IF 
					ELSE {no unposted batches - post TO any period up TO current} 
						# cannot post TO before max_year AND period
						IF pr_fabatch.year_num < max_year OR 
						(pr_fabatch.year_num = max_year AND 
						pr_fabatch.period_num < max_period) THEN 
							LET pr_tmp_text = max_year USING "<<<<"," ", 
							max_period USING "<<<" 
							LET msgresp = kandoomsg("F",9536,pr_tmp_text) 
							#9536 The batches must AT least post TO XXXX XXX.
							NEXT FIELD year_num 
						END IF 
						# don't post past the current year AND period
						IF pr_fabatch.year_num > default_year OR 
						(pr_fabatch.year_num = default_year AND 
						pr_fabatch.period_num > default_period) THEN 
							LET pr_tmp_text = default_year USING "<<<<"," ", 
							default_period USING "<<<" 
							LET msgresp = kandoomsg("F",9537,pr_tmp_text) 
							#9537 The batches must AT least post TO XXXX XXX.
							NEXT FIELD year_num 
						END IF 
					END IF 
				ELSE 
					# maximum posted period IS AFTER current y&p
					# you can only post TO the mpp
					IF pr_fabatch.year_num != max_year OR 
					pr_fabatch.period_num != max_period THEN 
						LET pr_tmp_text = default_year USING "<<<<"," ", 
						default_period USING "<<<" 
						LET msgresp = kandoomsg("F",9535,pr_tmp_text) 
						NEXT FIELD year_num 
					END IF 
				END IF 
			END IF 

		AFTER FIELD control_line_num 
			IF pr_faparms.control_tot_flag = "N" THEN 
				EXIT INPUT 
			END IF 
			IF pr_fabatch.control_line_num IS NULL THEN 
				LET pr_fabatch.control_line_num = 0 
			END IF 
			IF pr_fabatch.control_line_num <= 0 THEN 
				LET msgresp = kandoomsg("F",9538,"") 
				#9538 Batch control line number must be greater than zero.
				NEXT FIELD control_line_num 
			END IF 

		AFTER FIELD control_asset_amt 
			IF pr_fabatch.control_asset_amt IS NULL THEN 
				LET pr_fabatch.control_asset_amt = 0 
			END IF 
			IF pr_faparms.control_tot_flag != "Y" THEN 
				LET pr_fabatch.control_asset_amt = 0 
			END IF 

		AFTER FIELD control_depr_amt 
			IF pr_fabatch.control_depr_amt IS NULL THEN 
				LET pr_fabatch.control_depr_amt = 0 
			END IF 
			IF pr_faparms.control_tot_flag != "Y" THEN 
				LET pr_fabatch.control_depr_amt = 0 
			END IF 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT program 
			ELSE 
				IF orig_year != pr_fabatch.year_num OR 
				orig_period != pr_fabatch.period_num THEN 
					#check IF the year AND period are before the oldest y+p currently in
					# fabatch
					LET max_year = 0 
					LET max_period = 0 
					SELECT max(year_num) 
					INTO max_year 
					FROM fabatch 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND post_asset_flag = "Y" 

					SELECT max(period_num) 
					INTO max_period 
					FROM fabatch 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND year_num = max_year 
					AND post_asset_flag = "Y" 

					IF max_year IS NULL THEN 
						LET max_year = 0 
					END IF 
					IF max_period IS NULL THEN 
						LET max_period = 0 
					END IF 

					# check IF the maximum posted period IS before the current period
					IF max_year < default_year OR (max_year = default_year AND 
					max_period < default_period) THEN 
						# check FOR unposted batches in OR AFTER maximum posted y&p

						SELECT max(year_num) 
						INTO tmp_year 
						FROM fabatch 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND year_num > max_year OR 
						(year_num = max_year AND 
						period_num >= max_period) 
						AND post_asset_flag = "N" 

						SELECT max(period_num) 
						INTO tmp_period 
						FROM fabatch 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND period_num >= max_period 
						AND year_num = tmp_year 
						AND post_asset_flag = "N" 

						IF NOT (tmp_year IS NULL AND tmp_period IS null) THEN 
							{unposted batches in OR AFTER max posted}
							# IF unposted batches are AFTER current y&p THEN
							# they must be posted prior TO further batches being entered
							IF tmp_year > default_year OR 
							(tmp_year = default_year AND 
							tmp_period > default_period) THEN 
								LET pr_tmp_text = tmp_year USING "<<<<"," ", 
								tmp_period USING "<<<" 
								LET msgresp = kandoomsg("F",9534,pr_tmp_text) 
								#9534 The batches must be posted in XXXX XX before
								#     entering batches.
								NEXT FIELD year_num 
							END IF 
							LET max_year = tmp_year 
							LET max_period = tmp_period 
							IF pr_fabatch.year_num != max_year OR 
							pr_fabatch.period_num != max_period THEN 
								LET pr_tmp_text = max_year USING "<<<<"," ", 
								max_period USING "<<<" 
								LET msgresp = kandoomsg("F",9535,pr_tmp_text) 
								#9535 The batches must be posted TO XXXX XXX.
								NEXT FIELD year_num 
							END IF 
						ELSE {no unposted batches - post TO any period up TO current} 
							# cannot post TO before max_year AND period
							IF pr_fabatch.year_num < max_year OR 
							(pr_fabatch.year_num = max_year AND 
							pr_fabatch.period_num < max_period) THEN 
								LET pr_tmp_text = max_year USING "<<<<"," ", 
								max_period USING "<<<" 
								LET msgresp = kandoomsg("F",9536,pr_tmp_text) 
								#9536 The batches must AT least post TO XXXX XXX.
								NEXT FIELD year_num 
							END IF 
							# don't post past the current year AND period
							IF pr_fabatch.year_num > default_year OR 
							(pr_fabatch.year_num = default_year AND 
							pr_fabatch.period_num > default_period) THEN 
								LET pr_tmp_text = default_year USING "<<<<"," ", 
								default_period USING "<<<" 
								LET msgresp = kandoomsg("F",9537,pr_tmp_text) 
								#9537 The batches must AT least post TO XXXX XXX.
								NEXT FIELD year_num 
							END IF 
						END IF 
					ELSE 
						# maximum posted period IS AFTER current y&p
						# you can only post TO the mpp
						IF pr_fabatch.year_num != max_year OR 
						pr_fabatch.period_num != max_period THEN 
							LET pr_tmp_text = default_year USING "<<<<"," ", 
							default_period USING "<<<" 
							LET msgresp = kandoomsg("F",9535,pr_tmp_text) 
							NEXT FIELD year_num 
						END IF 
					END IF 
				END IF 

				CALL valid_period(glob_rec_kandoouser.cmpy_code,pr_fabatch.year_num, 
				pr_fabatch.period_num, LEDGER_TYPE_GL) 
				RETURNING pr_fabatch.year_num, pr_fabatch.period_num, failed 
				IF failed THEN 
					NEXT FIELD year_num 
				END IF 

				IF pr_faparms.control_tot_flag != "Y" THEN 
					LET pr_fabatch.control_asset_amt = 0 
				END IF 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
	END INPUT 
	IF NOT err_code THEN 
		RETURN err_code 
	END IF 

	CLOSE WINDOW f100 

	IF int_flag OR quit_flag THEN 
		EXIT program 
	END IF 
	RETURN true 
END FUNCTION { HEADER } 

FUNCTION editit() 

	DEFINE 
	insert_flag, 
	rt_code SMALLINT, 
	tmp_faaudit RECORD LIKE faaudit.*, 
	pr_net_book_val_amt LIKE faaudit.net_book_val_amt, 
	tmp_seq LIKE faaudit.status_seq_num 

	MESSAGE "Updating transactions now - please wait" 
	GOTO bypass 
	LABEL recovery: 
	LET try_again = error_recover(err_message, status) 
	IF try_again != "Y" THEN 
		EXIT program 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR 
	GOTO recovery 

	BEGIN WORK 

		LET pr_fabatch.actual_asset_amt = 0 
		LET pr_fabatch.actual_depr_amt = 0 
		LET next_seq = 1 
		LET insert_flag = 0 

		DELETE FROM faaudit WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND batch_num = pr_fabatch.batch_num 

		FOR idx = 1 TO arr_size 
			IF pa_faaudit[idx].asset_code IS NOT NULL THEN 
				LET pr_faaudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET pr_faaudit.asset_code = pa_faaudit[idx].asset_code 
				LET pr_faaudit.add_on_code = pa_faaudit[idx].add_on_code 
				LET pr_faaudit.book_code = pa_faaudit[idx].book_code 
				LET pr_faaudit.year_num = pr_fabatch.year_num 
				LET pr_faaudit.period_num = pr_fabatch.period_num 
				LET pr_faaudit.batch_line_num = next_seq 
				LET pr_faaudit.trans_ind = global_tran_code 
				LET pr_faaudit.entry_text = glob_rec_kandoouser.sign_on_code 
				LET pr_faaudit.entry_date = today 
				LET pr_faaudit.asset_amt = pa_faaudit[idx].asset_amt 
				LET pr_faaudit.depr_amt = pa_faaudit[idx].depr_amt 

				IF pr_faaudit.asset_amt IS NULL THEN 
					LET pr_faaudit.asset_amt = 0 
				END IF 
				IF pr_faaudit.depr_amt IS NULL THEN 
					LET pr_faaudit.depr_amt = 0 
				END IF 

				LET pr_net_book_val_amt = 0 

				SELECT net_book_val_amt 
				INTO pr_net_book_val_amt 
				FROM fastatus 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND asset_code = pr_faaudit.asset_code 
				AND add_on_code = pr_faaudit.add_on_code 
				AND book_code = pr_faaudit.book_code 

				IF pr_net_book_val_amt IS NULL THEN 
					LET pr_net_book_val_amt = 0 
				END IF 

				CASE pr_faaudit.trans_ind 
					WHEN "A" {addition} 
						LET pr_faaudit.net_book_val_amt = pa_faaudit[idx].asset_amt 
					WHEN "C" {depn code change} 
						LET pr_faaudit.net_book_val_amt = pr_net_book_val_amt 
					WHEN "L" {life change} 
						LET pr_faaudit.net_book_val_amt = pr_net_book_val_amt 
					WHEN "T" {transfer} 
						LET pr_faaudit.net_book_val_amt = pr_net_book_val_amt 
					WHEN "J" {adjustment} 
						LET pr_faaudit.net_book_val_amt = pr_net_book_val_amt + 
						pa_faaudit[idx].asset_amt - 
						pa_faaudit[idx].depr_amt 
					WHEN "V" {revaluation} 
						LET pr_faaudit.net_book_val_amt = pa_faaudit[idx].asset_amt 
					WHEN "S" {sale} 
						LET pr_faaudit.net_book_val_amt = 0 
					WHEN "R" {retirement} 
						LET pr_faaudit.net_book_val_amt = 0 
				END CASE 

				IF pr_faaudit.trans_ind = "A" THEN 
					LET pr_faaudit.status_seq_num = 1 {addition IS always first} 
				ELSE 
					DECLARE seq_curs CURSOR FOR 
					SELECT seq_num 
					FROM fastatus 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND asset_code = pr_faaudit.asset_code 
					AND add_on_code = pr_faaudit.add_on_code 
					AND book_code = pr_faaudit.book_code 
					FOR UPDATE 

					OPEN seq_curs 
					FETCH seq_curs INTO tmp_seq 

					IF NOT status THEN 
						LET pr_faaudit.status_seq_num = tmp_seq + 1 
						IF pr_faaudit.trans_ind = "T" THEN 
							LET pr_faaudit.status_seq_num = 
							pr_faaudit.status_seq_num + 1 
						END IF 

						UPDATE fastatus SET seq_num = pr_faaudit.status_seq_num 
						WHERE CURRENT OF seq_curs 
					END IF 
				END IF 


				LET pr_faaudit.rem_life_num = pa_faaudit[idx].rem_life_num 
				LET pr_faaudit.location_code = pa_faaudit[idx].location_code 
				LET pr_faaudit.faresp_code = pa_faaudit[idx].faresp_code 
				LET pr_faaudit.facat_code = pa_faaudit[idx].facat_code 
				LET pr_faaudit.batch_num = pr_fabatch.batch_num 

				LET pr_faaudit.desc_text = pa_faaudit[idx].desc_text 
				LET pr_faaudit.auth_code = pa_faaudit[idx].auth_code 
				LET pr_faaudit.salvage_amt = pa_faaudit[idx].salvage_amt 
				LET pr_faaudit.sale_amt = pa_faaudit[idx].sale_amt 

				IF NOT ((pr_faaudit.asset_amt = 0 AND 
				pr_faaudit.depr_amt = 0 AND 
				pr_faaudit.salvage_amt = 0 AND 
				global_tran_code <> "L") OR 
				(global_tran_code = "L" AND 
				pr_faaudit.rem_life_num IS null)) THEN 

					IF global_tran_code != "T" THEN {transfer} 
						IF global_tran_code = "C" THEN 
							IF pr_faaudit.desc_text IS NOT NULL THEN 
								INSERT INTO faaudit VALUES (pr_faaudit.*) 
								LET insert_flag = 1 
								LET next_seq = next_seq + 1 
							END IF 
						ELSE 
							INSERT INTO faaudit VALUES (pr_faaudit.*) 
							LET insert_flag = 1 
							LET next_seq = next_seq + 1 
						END IF 
					ELSE 
						SELECT location_code, 
						faresp_code, 
						facat_code 
						INTO tmp_faaudit.location_code, 
						tmp_faaudit.faresp_code, 
						tmp_faaudit.facat_code 
						FROM famast 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND asset_code = pr_faaudit.asset_code 
						AND add_on_code = pr_faaudit.add_on_code 

						IF NOT ((pr_faaudit.faresp_code=tmp_faaudit.faresp_code) AND 
						(pr_faaudit.location_code=tmp_faaudit.location_code) AND 
						(pr_faaudit.facat_code=tmp_faaudit.facat_code)) THEN 

							INSERT INTO faaudit VALUES (pr_faaudit.*) 
							LET next_seq = next_seq + 1 
							LET insert_flag = 1 

							LET pr_faaudit_from.* = pr_faaudit.* 
							LET pr_faaudit_from.status_seq_num = 
							(pr_faaudit.status_seq_num - 1) 
							LET pr_faaudit_from.asset_amt = 
							0 - pr_faaudit_from.asset_amt 
							LET pr_faaudit_from.depr_amt = 
							0 - pr_faaudit_from.depr_amt 
							LET pr_faaudit_from.net_book_val_amt = 0 
							LET pr_faaudit_from.desc_text = "Transfer - FROM" 
							LET pr_faaudit_from.batch_line_num = next_seq 
							LET pr_faaudit_from.faresp_code = 
							tmp_faaudit.faresp_code 
							LET pr_faaudit_from.location_code = 
							tmp_faaudit.location_code 
							LET pr_faaudit_from.facat_code = 
							tmp_faaudit.facat_code 

							INSERT INTO faaudit VALUES (pr_faaudit_from.*) 
							LET next_seq = next_seq + 1 
						END IF 
					END IF 
				END IF 

				LET pr_fabatch.actual_asset_amt = pr_fabatch.actual_asset_amt + 
				pr_faaudit.asset_amt 
				LET pr_fabatch.actual_depr_amt = pr_fabatch.actual_depr_amt + 
				pr_faaudit.depr_amt 
			END IF 
		END FOR 

		LET pr_fabatch.actual_line_num = next_seq - 1 
		LET pr_fabatch.control_line_num = pr_fabatch.actual_line_num 

		UPDATE fabatch SET fabatch.* = pr_fabatch.* 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND batch_num = pr_fabatch.batch_num 

		# dont add zero value batches

		IF insert_flag = 0 THEN 
			ROLLBACK WORK 
			LET rt_code = false 
		ELSE 
		COMMIT WORK 
		LET rt_code = true 
	END IF 
	WHENEVER ERROR stop 
	MESSAGE "" 
	LET success_flag = 1 
	RETURN rt_code 
END FUNCTION { editit } 
