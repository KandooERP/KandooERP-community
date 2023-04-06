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

	Source code beautified by beautify.pl on 2020-01-03 10:36:53	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "F_FA_GLOBALS.4gl" 

# Purpose   :   Create Fixed Asset Batches

GLOBALS 

	DEFINE 
	pr_fabatch RECORD LIKE fabatch.*, 
	pr_faparms RECORD LIKE faparms.*, 
	pr_faaudit RECORD LIKE faaudit.*, 
	pr_faaudit_from RECORD LIKE faaudit.*, 
	pa_faaudit array[2000] OF RECORD 
		batch_line_num LIKE faaudit.batch_line_num, 
		asset_code LIKE faaudit.asset_code, 
		add_on_code LIKE faaudit.add_on_code, 
		book_code LIKE faaudit.book_code, 
		auth_code LIKE faaudit.auth_code, 
		asset_amt LIKE faaudit.asset_amt, 
		depr_amt LIKE faaudit.depr_amt, 
		salvage_amt LIKE faaudit.salvage_amt, 
		sale_amt LIKE faaudit.sale_amt, 
		rem_life_num LIKE faaudit.rem_life_num, 
		location_code LIKE faaudit.location_code, 
		faresp_code LIKE faaudit.faresp_code, 
		facat_code LIKE faaudit.facat_code, 
		desc_text LIKE faaudit.desc_text 
	END RECORD, 
	next_seq INTEGER, 
	idx, failed, scrn, err_flag, arr_size, id_flag SMALLINT, 
	goon, ans CHAR(1), 
	pr_rec_kandoouser RECORD LIKE kandoouser.*, 
	try_again, date_entered CHAR (1), 
	mess CHAR(60), 
	err_message CHAR (40), 
	trans_header CHAR(24), 
	global_tran_code CHAR(1) 
END GLOBALS 

FUNCTION mainline(p_cmpy,p_kandoouser_sign_on_code) 
	DEFINE 
	long_arg_val CHAR(20), 
	short_arg_val CHAR(3), 
	p_kandoouser_sign_on_code CHAR(8), 
	p_cmpy LIKE company.cmpy_code 

	LET ans = "Y" 
	LET long_arg_val = get_baseprogname() 
	LET short_arg_val = long_arg_val[1,3] 
	LET mess = "" 

	CASE short_arg_val 
		WHEN "F21" 
			LET global_tran_code = "A" 
			LET trans_header = " Addition " 
		WHEN "F22" 
			LET global_tran_code = "J" 
			LET trans_header = " Adjustment " 
		WHEN "F23" 
			LET global_tran_code = "T" 
			LET trans_header = "Transfer - Intra Company" 
		WHEN "F24" 
			LET global_tran_code = "R" 
			LET trans_header = " Retirement " 
		WHEN "F25" 
			LET global_tran_code = "V" 
			LET trans_header = " Revaluation " 
		WHEN "F26" 
			LET global_tran_code = "S" 
			LET trans_header = " Sale " 
		WHEN "F27" 
			LET global_tran_code = "L" 
			LET trans_header = " Life Adjustment " 

		WHEN "F29" 
			LET global_tran_code = "C" 
			LET trans_header = "Depreciation Code Adjust" 
	END CASE 
	WHILE ans = "Y" 
		LET int_flag = 0 
		LET quit_flag = 0 
		CALL header(p_cmpy) 
		CASE 
			WHEN (global_tran_code = "A" OR 
				global_tran_code = "I") 
				CALL fafinadd(p_cmpy,global_tran_code) 
			WHEN (global_tran_code = "J" OR 
				global_tran_code = "L" OR 
				global_tran_code = "C") 
				CALL fafinadj(p_cmpy,global_tran_code) 
			WHEN (global_tran_code = "S" OR 
				global_tran_code = "R") 
				CALL fafintrn(p_cmpy,global_tran_code) 
			WHEN (global_tran_code = "T") 
				CALL fafintrn(p_cmpy,global_tran_code) 

			WHEN (global_tran_code = "V") 
				CALL fafintrn(p_cmpy,global_tran_code) 
		END CASE 
		IF int_flag = 0 AND quit_flag = 0 THEN 
			IF insertit(p_cmpy,p_kandoouser_sign_on_code) THEN 
				LET mess = " Batch ", pr_fabatch.batch_num USING "<<<<", 
				" added successfully" 
			ELSE 
				LET mess = " Batch NOT added - cannot add zero batch " 
			END IF 
		ELSE 
			LET mess = " Batch discarded " 
		END IF 
	END WHILE 
END FUNCTION {mainline} 

FUNCTION header(p_cmpy) 

	DEFINE 
	p_cmpy CHAR(2), 
	tmp_year, 
	default_year, 
	max_year LIKE period.year_num, 
	default_period, 
	tmp_period, 
	max_period LIKE period.period_num, 
	num_batch SMALLINT 

	OPEN WINDOW wf100 with FORM "F100" -- alch kd-757 
	CALL  windecoration_f("F100") -- alch kd-757 

	MESSAGE mess 

	SELECT faparms.* 
	INTO pr_faparms.* 
	FROM faparms 
	WHERE cmpy_code = p_cmpy 
	IF status = notfound THEN 
		ERROR "Fixed Asset Paramters NOT SET up - use FZP TO add" 
		SLEEP 2 
		EXIT program 
	END IF 
	DISPLAY BY NAME trans_header 

	INITIALIZE pr_fabatch.* TO NULL 

	LET pr_fabatch.cmpy_code = p_cmpy 
	LET pr_fabatch.batch_num = 0 
	LET pr_fabatch.control_asset_amt = 0 
	LET pr_fabatch.control_depr_amt = 0 
	LET pr_fabatch.actual_asset_amt = 0 
	LET pr_fabatch.actual_depr_amt = 0 
	LET pr_fabatch.post_asset_flag = "N" 
	LET pr_fabatch.post_gl_flag = "N" 
	LET pr_fabatch.control_line_num = 0 
	LET pr_fabatch.actual_line_num = 0 
	LET pr_fabatch.cleared_flag = "N" 
	LET pr_fabatch.jour_num = 0 


	INPUT BY NAME 
	pr_fabatch.year_num, 
	pr_fabatch.period_num, 
	pr_fabatch.com1_text, 
	pr_fabatch.com2_text, 
	pr_fabatch.control_line_num, 
	pr_fabatch.control_asset_amt, 
	pr_fabatch.control_depr_amt 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","F20","inp-pr_fabatch-1") -- alch kd-504 
			# next code so IF required they can enter journals in General Ledger
		BEFORE FIELD year_num 
			CALL db_period_what_period(p_cmpy, today) 
			RETURNING pr_fabatch.year_num, pr_fabatch.period_num 
			
			LET default_year = pr_fabatch.year_num 
			LET default_period = pr_fabatch.period_num 
			
			DISPLAY BY NAME 
				pr_fabatch.year_num, 
				pr_fabatch.period_num 
		
		AFTER FIELD period_num 
			CALL valid_period(
				p_cmpy,
				pr_fabatch.year_num, 
				pr_fabatch.period_num, 
				LEDGER_TYPE_GL) 
			RETURNING pr_fabatch.year_num, pr_fabatch.period_num, failed 
			IF failed THEN 
				NEXT FIELD year_num 
			END IF 


			# check IF the year AND period are before the oldest y+p currently in
			# fabatch
			LET max_year = 0 
			LET max_period = 0 
			SELECT max(year_num) 
			INTO max_year 
			FROM fabatch 
			WHERE cmpy_code = p_cmpy 
			AND post_asset_flag = "Y" 

			SELECT max(period_num) 
			INTO max_period 
			FROM fabatch 
			WHERE cmpy_code = p_cmpy 
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
				WHERE cmpy_code = p_cmpy 
				AND year_num > max_year OR 
				(year_num = max_year AND 
				period_num >= max_period) 
				AND post_asset_flag = "N" 

				SELECT max(period_num) 
				INTO tmp_period 
				FROM fabatch 
				WHERE cmpy_code = p_cmpy 
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
						ERROR "You MUST post the batches in ",tmp_year USING "####", 
						" ",tmp_period USING "##"," before entering batches" 
						SLEEP 2 
						NEXT FIELD year_num 
					END IF 
					LET max_year = tmp_year 
					LET max_period = tmp_period 
					IF pr_fabatch.year_num != max_year OR 
					pr_fabatch.period_num != max_period THEN 
						ERROR "You may only post TO ",max_year USING "####", 
						" ",max_period USING "##"," AT this time" 
						SLEEP 2 
						NEXT FIELD year_num 
					END IF 
				ELSE {no unposted batches - post TO any period up TO current} 
					# cannot post TO before max_year AND period
					IF pr_fabatch.year_num < max_year OR 
					(pr_fabatch.year_num = max_year AND 
					pr_fabatch.period_num < max_period) THEN 
						ERROR "You must post TO AT least ",max_year USING "####", 
						" ",max_period USING "##"," AT this time" 
						SLEEP 2 
						NEXT FIELD year_num 
					END IF 
					# don't post past the current year AND period
					IF pr_fabatch.year_num > default_year OR 
					(pr_fabatch.year_num = default_year AND 
					pr_fabatch.period_num > default_period) THEN 
						ERROR "You must NOT post past ",default_year USING "####", 
						" ",default_period USING "##"," AT this time" 
						SLEEP 2 
						NEXT FIELD year_num 
					END IF 
				END IF 
			ELSE 
				# maximum posted period IS AFTER current y&p
				# you can only post TO the mpp
				IF pr_fabatch.year_num != max_year OR 
				pr_fabatch.period_num != max_period THEN 
					ERROR "You may only post TO ",max_year USING "####", 
					" ",max_period USING "##"," AT this time" 
					SLEEP 2 
					NEXT FIELD year_num 
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
				ERROR "Batch control line numbers must be greater than 0" 
				NEXT FIELD control_line_num 
			END IF 

		AFTER FIELD control_asset_amt 
			IF pr_fabatch.control_asset_amt IS NULL THEN 
				LET pr_fabatch.control_asset_amt = 0 
			END IF 

		AFTER FIELD control_depr_amt 
			IF pr_fabatch.control_depr_amt IS NULL THEN 
				LET pr_fabatch.control_depr_amt = 0 
			END IF 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT program 
			END IF 

			CALL valid_period(
				p_cmpy,
				pr_fabatch.year_num, 
				pr_fabatch.period_num, 
				LEDGER_TYPE_GL) 
			RETURNING pr_fabatch.year_num, pr_fabatch.period_num, failed 
			IF failed THEN 
				NEXT FIELD year_num 
			END IF 


			# check IF the year AND period are before the oldest y+p currently in
			# fabatch
			LET max_year = 0 
			LET max_period = 0 
			SELECT max(year_num) 
			INTO max_year 
			FROM fabatch 
			WHERE cmpy_code = p_cmpy 
			AND post_asset_flag = "Y" 

			SELECT max(period_num) 
			INTO max_period 
			FROM fabatch 
			WHERE cmpy_code = p_cmpy 
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
				WHERE cmpy_code = p_cmpy 
				AND year_num > max_year OR 
				(year_num = max_year AND 
				period_num >= max_period) 
				AND post_asset_flag = "N" 

				SELECT max(period_num) 
				INTO tmp_period 
				FROM fabatch 
				WHERE cmpy_code = p_cmpy 
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
						ERROR "You MUST post the batches in ",tmp_year USING "####", 
						" ",tmp_period USING "##"," before entering batches" 
						SLEEP 2 
						NEXT FIELD year_num 
					END IF 
					LET max_year = tmp_year 
					LET max_period = tmp_period 
					IF pr_fabatch.year_num != max_year OR 
					pr_fabatch.period_num != max_period THEN 
						ERROR "You may only post TO ",max_year USING "####", 
						" ",max_period USING "##"," AT this time" 
						SLEEP 2 
						NEXT FIELD year_num 
					END IF 
				ELSE {no unposted batches - post TO any period up TO current} 
					# cannot post TO before max_year AND period
					IF pr_fabatch.year_num < max_year OR 
					(pr_fabatch.year_num = max_year AND 
					pr_fabatch.period_num < max_period) THEN 
						ERROR "You must post TO AT least ",max_year USING "####", 
						" ",max_period USING "##"," AT this time" 
						SLEEP 2 
						NEXT FIELD year_num 
					END IF 
					# don't post past the current year AND period
					IF pr_fabatch.year_num > default_year OR 
					(pr_fabatch.year_num = default_year AND 
					pr_fabatch.period_num > default_period) THEN 
						ERROR "You must NOT post past ",default_year USING "####", 
						" ",default_period USING "##"," AT this time" 
						SLEEP 2 
						NEXT FIELD year_num 
					END IF 
				END IF 
			ELSE 
				# maximum posted period IS AFTER current y&p
				# you can only post TO the mpp
				IF pr_fabatch.year_num != max_year OR 
				pr_fabatch.period_num != max_period THEN 
					ERROR "You may only post TO ",max_year USING "####", 
					" ",max_period USING "##"," AT this time" 
					SLEEP 2 
					NEXT FIELD year_num 
				END IF 
			END IF 

			IF pr_faparms.control_tot_flag != "Y" THEN 
				LET pr_fabatch.control_asset_amt = 0 
				LET pr_fabatch.control_depr_amt = 0 
				LET pr_fabatch.control_line_num = 0 
			ELSE 
				IF pr_fabatch.control_asset_amt IS NULL THEN 
					LET pr_fabatch.control_asset_amt = 0 
				END IF 
				IF pr_fabatch.control_depr_amt IS NULL THEN 
					LET pr_fabatch.control_depr_amt = 0 
				END IF 
				IF pr_fabatch.control_line_num IS NULL THEN 
					LET pr_fabatch.control_line_num = 0 
				END IF 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
	END INPUT 

	CLOSE WINDOW wf100 

	IF int_flag != 0 OR 
	quit_flag != 0 
	THEN 
		EXIT program 
	END IF 
END FUNCTION { HEADER } 

FUNCTION insertit(p_cmpy,p_kandoouser_sign_on_code) 
	DEFINE 

	rt_code, 
	insert_flag SMALLINT, 
	p_cmpy CHAR(2), 
	p_kandoouser_sign_on_code CHAR(8), 

	tmp_faaudit RECORD LIKE faaudit.*, 
	pr_net_book_val_amt LIKE fastatus.net_book_val_amt, 
	tmp_seq LIKE faaudit.status_seq_num 

	MESSAGE " Adding transactions now - please wait" 
	GOTO bypass 
	LABEL recovery: 
	LET try_again = error_recover(err_message, status) 
	IF try_again != "Y" THEN 
		EXIT program 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 

	LET insert_flag = 0 
	BEGIN WORK 
		DECLARE update_fa CURSOR FOR 
		SELECT faparms.* 
		FROM faparms 
		WHERE faparms.cmpy_code = p_cmpy 
		FOR UPDATE OF next_batch_num 
		OPEN update_fa 
		FETCH update_fa INTO pr_faparms.* 
		IF status = notfound THEN 
			MESSAGE " " 
			ERROR "Fixed Asset Paramters NOT SET up - use FZP TO add" 
			SLEEP 2 
			EXIT program 
		END IF 
		LET pr_faparms.next_batch_num = pr_faparms.next_batch_num + 1 
		UPDATE faparms 
		SET faparms.next_batch_num = pr_faparms.next_batch_num 
		WHERE CURRENT OF update_fa 
		CLOSE update_fa 

		LET pr_fabatch.actual_asset_amt = 0 
		LET pr_fabatch.actual_depr_amt = 0 
		LET next_seq = 1 

		FOR idx = 1 TO arr_size 
			IF pa_faaudit[idx].asset_code IS NOT NULL THEN 
				LET pr_faaudit.cmpy_code = p_cmpy 
				LET pr_faaudit.asset_code = pa_faaudit[idx].asset_code 
				LET pr_faaudit.add_on_code = pa_faaudit[idx].add_on_code 
				LET pr_faaudit.auth_code = pa_faaudit[idx].auth_code 
				LET pr_faaudit.book_code = pa_faaudit[idx].book_code 
				LET pr_faaudit.year_num = pr_fabatch.year_num 
				LET pr_faaudit.period_num = pr_fabatch.period_num 
				LET pr_faaudit.batch_line_num = next_seq 
				LET pr_faaudit.trans_ind = global_tran_code 
				LET pr_faaudit.entry_text = p_kandoouser_sign_on_code 
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
				WHERE cmpy_code = p_cmpy 
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
					WHERE cmpy_code = p_cmpy 
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
				LET pr_faaudit.batch_num = pr_faparms.next_batch_num 
				LET pr_faaudit.desc_text = pa_faaudit[idx].desc_text 
				LET pr_faaudit.salvage_amt = pa_faaudit[idx].salvage_amt 
				LET pr_faaudit.sale_amt = pa_faaudit[idx].sale_amt 
				# IF both zero dont add

				IF NOT ((pr_faaudit.asset_amt = 0 AND 
				pr_faaudit.depr_amt = 0 AND 
				pr_faaudit.salvage_amt = 0 AND 
				global_tran_code <> "L") OR 
				(global_tran_code = "L" AND 
				pr_faaudit.rem_life_num IS null)) THEN 
					IF global_tran_code != "T" THEN 
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
						WHERE cmpy_code = p_cmpy 
						AND asset_code = pr_faaudit.asset_code 
						AND add_on_code = pr_faaudit.add_on_code 

						IF NOT ((pr_faaudit.faresp_code=tmp_faaudit.faresp_code) AND 
						(pr_faaudit.location_code=tmp_faaudit.location_code) AND 
						(pr_faaudit.facat_code=tmp_faaudit.facat_code)) THEN 

							INSERT INTO faaudit VALUES (pr_faaudit.*) 
							LET insert_flag = 1 
							LET next_seq = next_seq + 1 

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

		LET pr_fabatch.batch_num = pr_faparms.next_batch_num 
		LET pr_fabatch.control_line_num = next_seq - 1 
		LET pr_fabatch.actual_line_num = next_seq - 1 

		# IF this IS a change depn rate batch THEN we don't want any GL
		# post TO occur
		IF pr_faaudit.trans_ind = "C" THEN 
			LET pr_fabatch.post_gl_flag = "Y" 
		END IF 

		INSERT INTO fabatch VALUES (pr_fabatch.*) 

		# dont add zero value batches

		IF insert_flag = 0 THEN {no faaudit inserted} 
			ROLLBACK WORK 
			LET rt_code = false 
		ELSE 
		COMMIT WORK 
		LET rt_code = true 
	END IF 
	WHENEVER ERROR stop 
	MESSAGE "" 
	RETURN rt_code 
END FUNCTION { insertit } 

