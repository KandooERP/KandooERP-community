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

	Source code beautified by beautify.pl on 2020-01-03 10:37:02	$Id: $
}


GLOBALS "../common/glob_GLOBALS.4gl" 

# Module    :    fafinadj.4gl
# Purpose   :    Asset batch processing type 'J' - Adjustments

GLOBALS 
	DEFINE pr_fabatch RECORD LIKE fabatch.* 
	#DEFINE pr_faparms RECORD LIKE faparms.*
	DEFINE pr_faaudit RECORD LIKE faaudit.* 
	DEFINE pr_famast RECORD LIKE famast.* 
	DEFINE pr_fastatus RECORD LIKE fastatus.* 
	DEFINE pa_faaudit array[2000] OF RECORD 
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
	END RECORD 
	DEFINE pb_faaudit array[2000] OF RECORD 
		batch_line_num LIKE faaudit.batch_line_num, 
		asset_code LIKE faaudit.asset_code, 
		add_on_code LIKE faaudit.add_on_code, 
		book_code LIKE faaudit.book_code, 
		asset_amt LIKE faaudit.asset_amt, 
		depr_amt LIKE faaudit.depr_amt 
	END RECORD 
	DEFINE pr_fabook RECORD LIKE fabook.* 
	DEFINE pr_falocation RECORD LIKE falocation.* 
	DEFINE pr_faresp RECORD LIKE faresp.* 
	DEFINE pr_facat RECORD LIKE facat.* 
	DEFINE temp1_book_code LIKE faaudit.book_code 
	DEFINE temp1_rem_num LIKE faaudit.rem_life_num 
	DEFINE last_desc LIKE faaudit.desc_text 
	DEFINE tempasset, tempdepr MONEY (15,2) 
	DEFINE trans_header CHAR(24) 

	DEFINE trans_detl1 CHAR(20) 
	DEFINE trans_detl2 CHAR(20) 
	DEFINE trans_detl3 CHAR(20) 
	DEFINE j, i, idx, scrn SMALLINT 
	DEFINE doit_once CHAR(1) 
	DEFINE acount INTEGER 
	DEFINE nxtfld SMALLINT 
	DEFINE asset_change_flag, curs_close_flag SMALLINT 

	DEFINE arr_size SMALLINT 
	DEFINE depn_code LIKE fabookdep.depn_code 
	DEFINE save_desc_text LIKE faaudit.desc_text 
	DEFINE saved_desc_text LIKE faaudit.desc_text 
	DEFINE saved_desc LIKE faaudit.desc_text 
	DEFINE old_life_code LIKE fastatus.life_period_num 
	DEFINE old_depn_code LIKE fabookdep.depn_code 
END GLOBALS 

FUNCTION fafinadj(p_cmpy, typer) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE typer CHAR(1) 
	DEFINE x SMALLINT 
	DEFINE oidx SMALLINT 
	DEFINE tmp_faaudit RECORD LIKE faaudit.* 
	DEFINE batch LIKE faaudit.batch_num 
	DEFINE ln LIKE faaudit.batch_line_num 

	OPEN WINDOW wf159 with FORM "F159" -- alch kd-757 
	CALL  winDecoration_f("F159") -- alch kd-757 

	CASE typer 
		WHEN "J" 
			LET trans_header = " Adjustment " 

			LET trans_detl1 = "Adjustment Amount..." 
			LET trans_detl2 = "Sale Amount........." 
			LET trans_detl3 = "Remaining Life......" 
		WHEN "L" 
			LET trans_header = " Life Adjustment " 

			LET trans_detl1 = "Original Cost......." 
			LET trans_detl2 = "Net Book Value......" 
			LET trans_detl3 = "Remaining Life......" 

		WHEN "C" 
			LET trans_header = "Depreciation Code Adjust" 
			LET trans_detl1 = "Original Cost......." 
			LET trans_detl2 = "Net Book Value......" 
			LET trans_detl3 = "Remaining Life......" 
	END CASE 

	DISPLAY BY NAME trans_header 

	LET asset_change_flag = 0 
	LET curs_close_flag = 0 

	DECLARE curser_item CURSOR FOR 
	SELECT faaudit.* 
	INTO pr_faaudit.* 
	FROM faaudit 
	WHERE cmpy_code = p_cmpy AND 
	batch_num = pr_fabatch.batch_num 

	LET pr_fabatch.actual_asset_amt = 0 
	LET pr_fabatch.actual_depr_amt = 0 

	LET idx = 0 
	FOREACH curser_item 
		LET idx = idx + 1 
		LET pb_faaudit[idx].batch_line_num = pr_faaudit.batch_line_num 
		LET pb_faaudit[idx].asset_code = pr_faaudit.asset_code 
		LET pb_faaudit[idx].add_on_code = pr_faaudit.add_on_code 
		LET pb_faaudit[idx].book_code = pr_faaudit.book_code 
		LET pb_faaudit[idx].asset_amt = pr_faaudit.asset_amt 
		LET pb_faaudit[idx].depr_amt = pr_faaudit.depr_amt 


		LET pa_faaudit[idx].batch_line_num = pr_faaudit.batch_line_num 
		LET pa_faaudit[idx].asset_code = pr_faaudit.asset_code 
		LET pa_faaudit[idx].add_on_code = pr_faaudit.add_on_code 
		LET pa_faaudit[idx].book_code = pr_faaudit.book_code 
		LET pa_faaudit[idx].auth_code = pr_faaudit.auth_code 
		LET pa_faaudit[idx].asset_amt = pr_faaudit.asset_amt 
		LET pa_faaudit[idx].depr_amt = pr_faaudit.depr_amt 
		LET pa_faaudit[idx].salvage_amt = pr_faaudit.salvage_amt 
		LET pa_faaudit[idx].sale_amt = pr_faaudit.sale_amt 
		LET pa_faaudit[idx].rem_life_num = pr_faaudit.rem_life_num 
		LET pa_faaudit[idx].location_code = pr_faaudit.location_code 
		LET pa_faaudit[idx].faresp_code = pr_faaudit.faresp_code 
		LET pa_faaudit[idx].facat_code = pr_faaudit.facat_code 
		LET pa_faaudit[idx].desc_text = pr_faaudit.desc_text 

		IF pr_faaudit.asset_amt IS NOT NULL THEN 
			LET pr_fabatch. actual_asset_amt = pr_fabatch.actual_asset_amt + 
			pr_faaudit.asset_amt 
		END IF 
		IF pr_faaudit.depr_amt IS NOT NULL THEN 
			LET pr_fabatch. actual_depr_amt = pr_fabatch.actual_depr_amt + 
			pr_faaudit.depr_amt 
		END IF 
		IF idx > 1990 THEN 
			EXIT FOREACH 
		END IF 
	END FOREACH 
	CALL set_count(idx) 
	DISPLAY BY NAME 
	pr_fabatch.batch_num, 
	pr_fabatch.actual_asset_amt, 
	pr_fabatch.actual_depr_amt, 
	pr_faaudit.entry_date 


	MESSAGE " " 
	MESSAGE " F1 TO add,RETURN on line TO change" 
	attribute(yellow) 

	LET doit_once = "N" 
	WHILE doit_once = "N" 
		LET doit_once = "Y" 
		INITIALIZE pr_faaudit.* TO NULL 
		INPUT ARRAY pb_faaudit WITHOUT DEFAULTS FROM sr_faaudit.* 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","fafinadj","inp_arr-pb_faaudit-2") -- alch kd-504 

					ON ACTION "LOOKUP" infield (asset_code) 
						#LET pb_faaudit[idx].asset_code = lookup_famast(p_cmpy)
						CALL lookup_famast(p_cmpy) RETURNING pb_faaudit[idx].asset_code, 
						pb_faaudit[idx].add_on_code 
						DISPLAY pb_faaudit[idx].asset_code 
						TO sr_faaudit[scrn].asset_code 
						DISPLAY pb_faaudit[idx].add_on_code 
						TO sr_faaudit[scrn].add_on_code 

						NEXT FIELD asset_code 

					ON ACTION "LOOKUP" infield (book_code) 
						LET pb_faaudit[idx].book_code = lookup_stat_book(p_cmpy) 
						DISPLAY pb_faaudit[idx].book_code 
						TO sr_faaudit[scrn].book_code 

						NEXT FIELD book_code 


			BEFORE ROW 
				LET idx = arr_curr() 
				LET scrn = scr_line() 
				LET pr_faaudit.batch_line_num = pa_faaudit[idx].batch_line_num 
				LET pr_faaudit.asset_code = pa_faaudit[idx].asset_code 
				LET pr_faaudit.add_on_code = pa_faaudit[idx].add_on_code 
				LET pr_faaudit.book_code = pa_faaudit[idx].book_code 
				LET pr_faaudit.auth_code = pa_faaudit[idx].auth_code 
				LET pr_faaudit.asset_amt = pa_faaudit[idx].asset_amt 
				LET pr_faaudit.depr_amt = pa_faaudit[idx].depr_amt 
				LET pr_faaudit.sale_amt = pa_faaudit[idx].sale_amt 
				LET pr_faaudit.salvage_amt = pa_faaudit[idx].salvage_amt 
				LET pr_faaudit.rem_life_num = pa_faaudit[idx].rem_life_num 
				LET pr_faaudit.location_code = pa_faaudit[idx].location_code 
				LET pr_faaudit.faresp_code = pa_faaudit[idx].faresp_code 
				LET pr_faaudit.facat_code = pa_faaudit[idx].facat_code 
				LET pr_faaudit.desc_text = pa_faaudit[idx].desc_text 

				IF pr_fabatch.actual_asset_amt = pr_fabatch.control_asset_amt 
				AND pr_fabatch.actual_depr_amt = pr_fabatch.control_depr_amt 
				THEN 
					MESSAGE "This batch currently in balance - ESC TO UPDATE" 
					attribute(yellow) 
				ELSE 
					MESSAGE "ESC TO UPDATE " attribute(yellow) 
				END IF 
				NEXT FIELD asset_code 

			BEFORE INSERT 
				LET acount = arr_count() 
				IF acount = 2000 
				THEN 
				ELSE 
					FOR j = acount TO idx step -1 
						LET pa_faaudit[j+1].* = pa_faaudit[j].* 
						CALL renum() 
					END FOR 
					INITIALIZE pr_faaudit.* TO NULL 
					INITIALIZE pa_faaudit[idx].* TO NULL 
				END IF 
				LET pb_faaudit[idx].batch_line_num = idx 
				DISPLAY idx 
				TO sr_faaudit[scrn].batch_line_num 

				IF pa_faaudit[idx].asset_code IS NULL AND idx > 1 THEN 
					LET pb_faaudit[idx].asset_code = pb_faaudit[idx-1].asset_code 
					LET pr_faaudit.asset_code = pb_faaudit[idx].asset_code 
					LET pb_faaudit[idx].add_on_code = pb_faaudit[idx-1].add_on_code 
					LET pr_faaudit.add_on_code = pb_faaudit[idx].add_on_code 
					DISPLAY pb_faaudit[idx].asset_code 
					TO sr_faaudit[scrn].asset_code 
					DISPLAY pb_faaudit[idx].add_on_code 
					TO sr_faaudit[scrn].add_on_code 
				END IF 

			AFTER FIELD add_on_code 
				IF pb_faaudit[idx].asset_code IS NULL THEN 
					ERROR "Asset Code IS required, try window" 
					NEXT FIELD asset_code 
				END IF 
				IF (pr_faaudit.asset_code IS NULL OR 
				pb_faaudit[idx].asset_code <> pr_faaudit.asset_code OR 
				pb_faaudit[idx].add_on_code <> pr_faaudit.add_on_code) THEN 
					IF verify_asset_code(p_cmpy, pb_faaudit[idx].asset_code, 
					pb_faaudit[idx].add_on_code) = 1 THEN 
						MESSAGE "Asset ID NOT found - try window" 
						attribute(yellow) 
						NEXT FIELD asset_code 
					ELSE 
						IF pr_famast.location_code IS NULL THEN 
							ERROR "This asset has NOT had financial details added" 
							NEXT FIELD asset_code 
						END IF 
					END IF 
				END IF 

				IF pb_faaudit[idx].asset_code = pr_famast.asset_code AND 
				pb_faaudit[idx].add_on_code = pr_famast.add_on_code AND 
				pa_faaudit[idx].desc_text IS NULL THEN 
					LET pa_faaudit[idx].desc_text = pr_famast.desc_text 
				END IF 


				DECLARE sr_curs CURSOR FOR 
				SELECT * 
				INTO tmp_faaudit.* 
				FROM faaudit 
				WHERE cmpy_code = p_cmpy 
				AND (trans_ind = "S" OR 
				trans_ind = "R") 
				AND asset_code = pb_faaudit[idx].asset_code 
				AND add_on_code = pb_faaudit[idx].add_on_code 

				OPEN sr_curs 
				FETCH sr_curs 
				IF NOT status THEN 
					IF tmp_faaudit.trans_ind = "S" THEN 
						ERROR "Asset :",pb_faaudit[idx].asset_code, 
						" has been sold - cannot adjust" 
						NEXT FIELD asset_code 
					END IF 
					IF tmp_faaudit.trans_ind = "R" THEN 
						ERROR "Asset :",pb_faaudit[idx].asset_code, 
						" has been retired - cannot adjust" 
						NEXT FIELD asset_code 
					END IF 
				END IF 

			AFTER FIELD book_code 
				IF verify_book(p_cmpy,pb_faaudit[idx].book_code) = 1 THEN 
					NEXT FIELD book_code 
				END IF 

				IF typer = "J" THEN 
					# only one unposted adjustment TO an asset allowed AT a time
					DECLARE batch_curs CURSOR FOR 
					SELECT faaudit.batch_num,faaudit.batch_line_num 
					INTO batch,ln 
					FROM faaudit,fabatch 
					WHERE faaudit.cmpy_code = p_cmpy 
					AND faaudit.asset_code = pb_faaudit[idx].asset_code 
					AND faaudit.add_on_code = pb_faaudit[idx].add_on_code 
					AND faaudit.book_code = pb_faaudit[idx].book_code 
					AND faaudit.trans_ind = "J" 
					AND fabatch.cmpy_code = faaudit.cmpy_code 
					AND fabatch.batch_num = faaudit.batch_num 
					AND fabatch.post_asset_flag = "N" 
					OPEN batch_curs 
					FETCH batch_curs 
					IF NOT status THEN {batch exists - ie edit} 
						IF pr_fabatch.batch_num IS NOT NULL AND 
						pr_fabatch.batch_num != batch THEN 
							ERROR "An unposted adjustment exists FOR this asset. ", 
							"Batch ",batch USING "<<<<"," line ", 
							ln USING "<<<<"," Post required" 
							NEXT FIELD asset_code 
						END IF 
					END IF 
					FOR x = 1 TO acount 
						IF x = idx THEN 
							CONTINUE FOR 
						END IF 
						IF pb_faaudit[idx].asset_code = pb_faaudit[x].asset_code 
						AND pb_faaudit[idx].add_on_code = 
						pb_faaudit[x].add_on_code 
						AND pb_faaudit[idx].book_code = 
						pb_faaudit[x].book_code THEN 
							ERROR "Only one asset/add on/book combination per ", 
							"batch please. " 
							NEXT FIELD asset_code 
						END IF 
					END FOR 
				END IF 

				IF pa_faaudit[idx].rem_life_num IS NULL THEN 
					SELECT * 
					INTO pr_fastatus.* 
					FROM fastatus 
					WHERE cmpy_code = p_cmpy 
					AND asset_code = pb_faaudit[idx].asset_code 
					AND add_on_code = pb_faaudit[idx].add_on_code 
					AND book_code = pb_faaudit[idx].book_code 
					AND seq_num = (SELECT max(seq_num) 
					FROM fastatus 
					WHERE cmpy_code = p_cmpy 
					AND asset_code = 
					pb_faaudit[idx].asset_code 
					AND add_on_code = 
					pb_faaudit[idx].add_on_code 
					AND book_code = 
					pb_faaudit[idx].book_code) 
					IF status = notfound THEN 
						ERROR 
						"No financial details have been added FOR this asset/book" 
						NEXT FIELD book_code 
					ELSE 
						LET pr_faaudit.rem_life_num = pr_fastatus.rem_life_num 
					END IF 
				END IF 
				CALL adj_fn(p_cmpy,typer) 
				# IF there was an interrupt in add_fn() don't go TO next line of INPUT array
				IF (nxtfld = 1 AND idx > 1) THEN 
					LET pb_faaudit[idx].asset_code = 
					pb_faaudit[idx-1].asset_code 
					LET pb_faaudit[idx].add_on_code = 
					pb_faaudit[idx-1].add_on_code 
					DISPLAY pb_faaudit[idx].asset_code TO 
					sr_faaudit[scrn].asset_code 
					DISPLAY pb_faaudit[idx].add_on_code TO 
					sr_faaudit[scrn].add_on_code 
					NEXT FIELD asset_code 
				ELSE 
					LET nxtfld = 0 
					CALL set_faaudit() 

					LET pb_faaudit[idx].asset_amt = pa_faaudit[idx].asset_amt 
					LET pb_faaudit[idx].depr_amt = pa_faaudit[idx].depr_amt 
					DISPLAY pb_faaudit[idx].asset_amt, 
					pb_faaudit[idx].depr_amt 
					TO sr_faaudit[scrn].asset_amt, 
					sr_faaudit[scrn].depr_amt 

				END IF 
				NEXT FIELD depr_amt 

			AFTER ROW 
				LET tempasset = 0 
				LET tempdepr = 0 

				FOR i = 1 TO arr_count() 
					IF pa_faaudit[i].asset_amt IS NOT NULL THEN 
						LET tempasset = tempasset + pa_faaudit[i].asset_amt 
					END IF 
					IF pa_faaudit[i].depr_amt IS NOT NULL THEN 
						LET tempdepr = tempdepr + pa_faaudit[i].depr_amt 
					END IF 
				END FOR 
				LET pr_fabatch.actual_asset_amt = tempasset 
				LET pr_fabatch.actual_depr_amt = tempdepr 
				DISPLAY BY NAME 
				pr_fabatch.actual_asset_amt, 
				pr_fabatch.actual_depr_amt 

				CALL set_faaudit() 

			AFTER INSERT 
				CALL renum() 

			AFTER DELETE 

				LET acount = arr_count() 
				IF acount > 0 THEN 
					FOR j = idx TO (acount) 
						LET pa_faaudit[j].* = pa_faaudit[j+1].* 
					END FOR 
					INITIALIZE pa_faaudit[acount+1].* TO NULL 
				ELSE 
					INITIALIZE pa_faaudit[1].* TO NULL 
				END IF 
				CALL renum() 

			AFTER INPUT 

				LET arr_size = arr_count() 

			ON KEY (control-w) 
				CALL kandoohelp("") 
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
		END INPUT 

		IF int_flag != 0 OR quit_flag != 0 THEN 
			--         prompt " Are you sure you want TO cancel (y/n)? " -- albo
			--            FOR CHAR doit_once
			LET doit_once = promptYN(""," Are you sure you want TO cancel (y/n)? ","Y") -- albo 
			LET doit_once= upshift (doit_once) 
			IF doit_once = "N" 
			THEN 
				LET int_flag = 0 
				LET quit_flag = 0 
			END IF 
		ELSE 
			LET doit_once= "Y" 
		END IF 
	END WHILE # ans = "Y" 
	CLEAR screen 
	CLOSE WINDOW wf159 

END FUNCTION { batadj } 

FUNCTION adj_fn(p_cmpy,typer) 
	DEFINE typer CHAR(1) 
	DEFINE p_cmpy LIKE company.cmpy_code 

	LET pr_faaudit.batch_line_num = pb_faaudit[idx].batch_line_num 
	LET pr_faaudit.asset_code = pb_faaudit[idx].asset_code 
	LET pr_faaudit.add_on_code = pb_faaudit[idx].add_on_code 
	LET pr_faaudit.book_code = pb_faaudit[idx].book_code 
	SELECT * 
	INTO pr_famast.* 
	FROM famast 
	WHERE cmpy_code = p_cmpy 
	AND asset_code = pr_faaudit.asset_code 
	AND add_on_code = pr_faaudit.add_on_code 
	LET pr_faaudit.location_code = pr_famast.location_code 
	LET pr_faaudit.faresp_code = pr_famast.faresp_code 
	LET pr_faaudit.facat_code = pr_famast.facat_code 

	IF typer = "L" OR typer = "C" THEN 
		SELECT * 
		INTO pr_fastatus.* 
		FROM fastatus 
		WHERE cmpy_code = p_cmpy 
		AND asset_code = pr_faaudit.asset_code 
		AND add_on_code = pr_faaudit.add_on_code 
		AND book_code = pr_faaudit.book_code 
		LET pr_faaudit.asset_amt = pr_fastatus.cur_depr_cost_amt 
		LET pr_faaudit.depr_amt = pr_fastatus.depr_amt 
		LET pr_faaudit.salvage_amt = pr_fastatus.salvage_amt 
		LET pr_faaudit.sale_amt = pr_fastatus.net_book_val_amt 
	END IF 

	SELECT * 
	INTO pr_fabook.* 
	FROM fabook 
	WHERE cmpy_code = p_cmpy 
	AND book_code = pr_faaudit.book_code 

	SELECT * 
	INTO pr_falocation.* 
	FROM falocation 
	WHERE cmpy_code = p_cmpy 
	AND location_code = pr_faaudit.location_code 

	SELECT * 
	INTO pr_faresp.* 
	FROM faresp 
	WHERE cmpy_code = p_cmpy 
	AND faresp_code = pr_faaudit.faresp_code 

	SELECT * 
	INTO pr_facat.* 
	FROM facat 
	WHERE cmpy_code = p_cmpy 
	AND facat_code = pr_faaudit.facat_code 


	IF typer = "S" THEN 
		LET pr_faaudit.sale_amt = 0 
	END IF 

	CALL adj_details(p_cmpy,typer) 

	CURRENT WINDOW IS wf159 
END FUNCTION 


FUNCTION adj_details(p_cmpy,typer) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE typer CHAR(1) 
	DEFINE field_num SMALLINT 
	DEFINE tmp_depr LIKE faaudit.depr_amt 

	OPEN WINDOW wf101 with FORM "F101" -- alch kd-757 
	CALL  winDecoration_f("F101") -- alch kd-757 

	DISPLAY BY NAME trans_header 

	DISPLAY BY NAME trans_detl1, 
	trans_detl2, 
	trans_detl3 

	SELECT fabookdep.depn_code 
	INTO depn_code 
	FROM fabookdep 
	WHERE cmpy_code = p_cmpy 
	AND asset_code = pr_faaudit.asset_code 
	AND add_on_code = pr_faaudit.add_on_code 
	AND book_code = pr_faaudit.book_code 
	DISPLAY BY NAME depn_code 

	#huho these are GLOBALS AND are NOT modified in this module OR local scope
	DISPLAY pr_faaudit.batch_line_num, 
	pr_faaudit.asset_code, 
	pr_faaudit.add_on_code, 
	pr_famast.desc_text, 
	pr_faaudit.book_code, 
	pr_fabook.book_text, 
	pr_faaudit.rem_life_num, 
	pr_faaudit.location_code, 
	pr_falocation.location_text, 
	pr_faaudit.faresp_code, 
	pr_faresp.faresp_text, 
	pr_faaudit.facat_code, 
	pr_facat.facat_text, 
	pr_faaudit.desc_text, 

	pr_faaudit.sale_amt 
	TO faaudit.batch_line_num, 
	faaudit.asset_code, 
	faaudit.add_on_code, 
	famast.desc_text, 
	faaudit.book_code, 
	fabook.book_text, 
	faaudit.rem_life_num, 
	faaudit.location_code, 
	falocation.location_text, 
	faaudit.faresp_code, 
	faresp.faresp_text, 
	faaudit.facat_code, 
	facat.facat_text, 
	faaudit.desc_text, 

	faaudit.sale_amt 


	IF typer = "C" THEN 
		LET saved_desc_text = pr_faaudit.desc_text 
		SELECT fabookdep.depn_code 
		INTO old_depn_code 
		FROM fabookdep 
		WHERE cmpy_code = p_cmpy 
		AND asset_code = pr_faaudit.asset_code 
		AND add_on_code = pr_faaudit.add_on_code 
		AND book_code = pr_faaudit.book_code 
	END IF 

	IF typer = "L" THEN 
		LET save_desc_text = pr_faaudit.desc_text 
		SELECT fastatus.life_period_num 
		INTO old_life_code 
		FROM fastatus 
		WHERE cmpy_code = p_cmpy 
		AND asset_code = pr_faaudit.asset_code 
		AND add_on_code = pr_faaudit.add_on_code 
		AND book_code = pr_faaudit.book_code 
	END IF 

	INPUT pr_faaudit.auth_code, 
	pr_faaudit.asset_amt, 
	pr_faaudit.depr_amt, 
	pr_faaudit.salvage_amt, 
	pr_faaudit.rem_life_num, 
	pr_faaudit.desc_text 
	WITHOUT DEFAULTS 
	FROM faaudit.auth_code, 
	faaudit.asset_amt, 
	faaudit.depr_amt, 
	faaudit.salvage_amt, 
	faaudit.rem_life_num, 
	faaudit.desc_text 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","fafinadj","inp-pr_faaudit-3") -- alch kd-504 
		
		ON ACTION "NOTES" infield (desc_text) --ON KEY (control-n) 
				LET pr_faaudit.desc_text = sys_noter(p_cmpy,pr_faaudit.desc_text) 
				DISPLAY pr_faaudit.desc_text TO 
				faaudit.desc_text 

				NEXT FIELD faaudit.desc_text 

		BEFORE FIELD auth_code 
			IF typer = "L" OR typer = "C" THEN 
				NEXT FIELD faaudit.rem_life_num 
			END IF 

		AFTER FIELD auth_code 
			IF int_flag != 0 OR 
			quit_flag != 0 
			THEN 
				LET nxtfld = 1 
				LET int_flag = 0 
				LET quit_flag = 0 
				CLOSE WINDOW wf101 
			ELSE 
				IF verify_auth(p_cmpy,pr_faaudit.auth_code) THEN 
					NEXT FIELD faaudit.auth_code 
				END IF 
			END IF 

		BEFORE FIELD asset_amt 
			IF pr_faaudit.asset_amt IS NULL THEN 
				LET pr_faaudit.asset_amt = 0 
				DISPLAY pr_faaudit.asset_amt 
				TO faaudit.asset_amt 

			END IF 

		AFTER FIELD asset_amt 
			IF pr_faaudit.asset_amt IS NULL THEN 
				LET pr_faaudit.asset_amt = 0 
				DISPLAY pr_faaudit.asset_amt TO faaudit.asset_amt 


			END IF 
			IF pr_faaudit.depr_amt IS NULL THEN 
				LET pr_faaudit.depr_amt = 0 
				DISPLAY pr_faaudit.depr_amt TO faaudit.depr_amt 


			END IF 
			IF pr_fastatus.cur_depr_cost_amt + pr_faaudit.asset_amt < 0 THEN 
				ERROR "Asset cost adjutments cannot make ", 
				"cost < 0 (current cost ",pr_fastatus.cur_depr_cost_amt,")" 
				NEXT FIELD faaudit.asset_amt 
			END IF 



		AFTER FIELD depr_amt 
			IF pr_faaudit.depr_amt IS NULL THEN 
				LET pr_faaudit.depr_amt = 0 
				DISPLAY pr_faaudit.depr_amt TO faaudit.depr_amt 
			END IF 

			IF pr_fastatus.depr_amt + pr_faaudit.depr_amt < 0 THEN 
				ERROR "Depr adjustments cannot make ", 
				"Acc Depn < 0 (current ADepn ",pr_fastatus.depr_amt,")" 
				NEXT FIELD faaudit.depr_amt 
			END IF 
			IF pr_fastatus.net_book_val_amt + 
			(pr_faaudit.asset_amt - pr_faaudit.depr_amt) < 0 THEN 
				ERROR "The Net adjustment cannot make ", 
				"NBV < 0 (current NBV ",pr_fastatus.net_book_val_amt,")" 
				NEXT FIELD faaudit.asset_amt 
			END IF 

			IF pr_faaudit.salvage_amt IS NULL THEN 
				LET pr_faaudit.salvage_amt = 0 
				DISPLAY pr_faaudit.salvage_amt TO faaudit.salvage_amt 
			END IF 

		BEFORE FIELD salvage_amt 
			IF typer = "L" THEN 
				NEXT FIELD faaudit.rem_life_num 
			END IF 

		AFTER FIELD salvage_amt 
			LET field_num = 80 
			IF pr_faaudit.salvage_amt IS NULL THEN 
				LET pr_faaudit.salvage_amt = 0 
				DISPLAY pr_faaudit.salvage_amt TO faaudit.salvage_amt 

			END IF 

			IF pr_fastatus.salvage_amt + pr_faaudit.salvage_amt < 0 THEN 
				ERROR "You may NOT decrease salvage amount TO less than ", 
				pr_fastatus.salvage_amt 
				NEXT FIELD faaudit.salvage_amt 
			END IF 
			IF (pr_fastatus.salvage_amt + pr_faaudit.salvage_amt) > 
			pr_fastatus.net_book_val_amt THEN 
				ERROR "You may NOT amend salvage amount TO > NBV (", 
				pr_fastatus.net_book_val_amt,")" 
				NEXT FIELD faaudit.salvage_amt 
			END IF 

		BEFORE FIELD rem_life_num 
			IF typer = "J" THEN 
				IF field_num < 90 THEN 
					NEXT FIELD faaudit.desc_text 

				ELSE 
					NEXT FIELD faaudit.salvage_amt 
				END IF 
			END IF 
			IF typer = "C" THEN 
				IF get_depn(p_cmpy) THEN 
					DISPLAY pr_faaudit.desc_text TO faaudit.desc_text 
					NEXT FIELD faaudit.desc_text 
				ELSE 
					EXIT INPUT 
				END IF 
			END IF 

		AFTER FIELD rem_life_num 

			LET field_num = 90 
			IF typer = "L" THEN 
				IF verify_life(pr_faaudit.rem_life_num) THEN 
					NEXT FIELD faaudit.rem_life_num 
				END IF 
				LET pr_faaudit.desc_text = "Life amended FROM ", 
				old_life_code USING "<<<<"," TO ", 
				pr_faaudit.rem_life_num USING "<<<<" 
				DISPLAY pr_faaudit.desc_text TO faaudit.desc_text 
			END IF 

		BEFORE FIELD desc_text 
			# don't allow description change IF depn code being changed
			# allow them INTO this field so they can check what they have done
			IF typer = "C" OR typer = "L" THEN 
				LET saved_desc = pr_faaudit.desc_text 
			END IF 
			# IF just account AND a last desc use that description
			IF pa_faaudit[idx].desc_text = pr_famast.desc_text 
			AND last_desc IS NOT NULL 
			THEN 
				LET pa_faaudit[idx].desc_text = last_desc 
				DISPLAY pr_faaudit.desc_text 
				TO faaudit.desc_text 
			END IF 

		AFTER FIELD desc_text 

			LET field_num = 100 
			IF pr_famast.desc_text != pr_faaudit.desc_text THEN 
				LET last_desc = pr_faaudit.desc_text 
			END IF 
			IF typer = "C" OR typer = "L" THEN 
				LET pr_faaudit.desc_text = saved_desc 
				DISPLAY pr_faaudit.desc_text TO faaudit.desc_text 
			END IF 

		ON KEY (control-w) 
			CALL kandoohelp("") 
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = 0 
		LET quit_flag = 0 
		LET nxtfld = 1 
	ELSE 
		LET nxtfld = 0 
	END IF 

	CLOSE WINDOW wf101 
	RETURN 
END FUNCTION 

FUNCTION get_depn(p_cmpy) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE ln1 SMALLINT 
	DEFINE fill1 CHAR(1) 

	# OUTPUT IS a description in FORMAT as follows
	# "Depn code amended, xxx TO yyy"
	LET depn_code = pr_faaudit.desc_text[27,29] 


	INPUT BY NAME depn_code WITHOUT DEFAULTS 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","fafinadj","inp-depn_code-1") -- alch kd-504 
		
		ON ACTION "LOOKUP" 
			LET depn_code = lookup_dep_code(p_cmpy) 
			DISPLAY BY NAME depn_code
			 
		AFTER FIELD depn_code 
			IF depn_code IS NOT NULL THEN 
				SELECT * 
				FROM fadepmethod 
				WHERE fadepmethod.cmpy_code = p_cmpy 
				AND fadepmethod.depn_code = depn_code 
				IF status THEN 
					ERROR "Depreciation code NOT found" 
					NEXT FIELD depn_code 
				END IF 
			END IF 
			IF old_depn_code = depn_code THEN 
				ERROR "You must key a depn code that differs FROM current code" 
				NEXT FIELD depn_code 
			END IF 
		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				SELECT * 
				FROM fadepmethod 
				WHERE fadepmethod.cmpy_code = p_cmpy 
				AND fadepmethod.depn_code = depn_code 
				IF status THEN 
					ERROR "Depreciation code NOT found" 
					NEXT FIELD depn_code 
				END IF 
				IF old_depn_code = depn_code THEN 
					ERROR "You must key a depn code that differs", 
					" FROM current code" 
					NEXT FIELD depn_code 
				END IF 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
	END INPUT 

	IF int_flag OR quit_flag THEN 
		SELECT fadepmethod.depn_code 
		FROM fadepmethod 
		WHERE fadepmethod.cmpy_code = p_cmpy 
		AND fadepmethod.depn_code = depn_code 
		# line will NOT be inserted INTO batch IF faaudit.desc_text IS NULL
		IF depn_code IS NULL OR status THEN 
			LET pr_faaudit.desc_text = NULL 
			DISPLAY pr_faaudit.desc_text TO faaudit.desc_text 
		END IF 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 

	IF saved_desc_text IS NULL OR saved_desc_text = " " THEN 
		LET ln1 = length(old_depn_code) 
		LET fill1 = " " 
		IF ln1 = 1 THEN 
			LET pr_faaudit.desc_text = "Depn code amended, ",old_depn_code, 
			fill1,fill1," TO ",depn_code 
		END IF 
		IF ln1 = 2 THEN 
			LET pr_faaudit.desc_text = "Depn code amended, ",old_depn_code, 
			fill1," TO ",depn_code 
		END IF 
	ELSE 
		LET pr_faaudit.desc_text = pr_faaudit.desc_text[1,26],depn_code 
	END IF 

	RETURN true 

END FUNCTION 

