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

# Module     :    fafintrn.4gl
# Purpose    :    Retirements, Sale, Revaluation AND Transfer batch entry.

GLOBALS 
	DEFINE 
	pr_fabatch RECORD LIKE fabatch.*, 
	pr_faparms RECORD LIKE faparms.*, 
	pr_faaudit RECORD LIKE faaudit.*, 
	pt_faaudit RECORD LIKE faaudit.*, 
	pr_famast RECORD LIKE famast.*, 
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
	pb_faaudit array[2000] OF RECORD 
		batch_line_num LIKE faaudit.batch_line_num, 
		asset_code LIKE faaudit.asset_code, 
		add_on_code LIKE faaudit.add_on_code, 
		book_code LIKE faaudit.book_code, 
		asset_amt LIKE faaudit.asset_amt, 
		depr_amt LIKE faaudit.depr_amt 
	END RECORD, 
	pr_fastatus RECORD LIKE fastatus.*, 
	pr_fabook RECORD LIKE fabook.*, 
	pr_fabookdep RECORD LIKE fabookdep.*, 
	pr_falocation RECORD LIKE falocation.*, 
	pr_faresp RECORD LIKE faresp.*, 
	pr_facat RECORD LIKE facat.*, 
	temp1_book_code LIKE faaudit.book_code, 
	last_desc LIKE faaudit.desc_text, 
	trans_header CHAR(24), 
	trans_detl1 CHAR(20), 
	trans_detl2 CHAR(20), 
	trans_detl3 CHAR(20), 
	tempasset, tempdepr MONEY (15,2), 
	k, j, i, idx, scrn SMALLINT, 
	doit_once CHAR(1), 
	acount INTEGER, 
	nxtfld SMALLINT, 
	non_entry_flag, must_change_flag, asset_change_flag, 
	curs_close_flag SMALLINT, 
	new_arr_size INTEGER, 
	arr_size SMALLINT, 
	tran_type CHAR(1), 
	depn_code LIKE fabookdep.depn_code 
END GLOBALS 

FUNCTION fafintrn(p_cmpy, typer) 
	DEFINE 
	p_cmpy LIKE company.cmpy_code, 
	typer CHAR(1), 
	acnt INTEGER, 
	x, 
	do_check, 
	oidx SMALLINT, 
	delete_flag, cont_disp_flag CHAR(1), 
	tmp_faaudit RECORD LIKE faaudit.*, 
	tmp_asset_code LIKE faaudit.asset_code, 
	tmp_add_on_code LIKE faaudit.add_on_code, 
	tmp_book_code LIKE faaudit.add_on_code 

	WHENEVER ERROR CONTINUE 
	OPTIONS DELETE KEY f36 
	CREATE temp TABLE tmp_check (asset_code CHAR(10), 
	add_on_code CHAR(10), 
	book_code CHAR(2)) 
	CREATE unique INDEX tc1 ON tmp_check(asset_code,add_on_code,book_code) 
	WHENEVER ERROR stop 
	LET tran_type = typer 
	OPEN WINDOW wf159 with FORM "F159" -- alch kd-757 
	CALL  winDecoration_f("F159") -- alch kd-757 

	CASE typer 
		WHEN "T" 
			LET trans_header = "Transfer - Intra Company" 
		WHEN "S" 
			LET trans_header = " Sale " 
			LET trans_detl1 = "Cost (Base Curr.)..." 
			LET trans_detl2 = "Sale Amount........." 
			LET trans_detl3 = "Remaining Life......" 
		WHEN "R" 
			LET trans_header = " Retirement " 
			LET trans_detl1 = "Cost (Base Curr.)..." 
			LET trans_detl2 = "Retirement Amount..." 
			LET trans_detl3 = "Remaining Life......" 
		WHEN "V" 
			LET trans_header = " Revaluation " 
			LET trans_detl1 = "New Net Book Value.." 
			LET trans_detl2 = "Revaluation Amount.." 
			LET trans_detl3 = "Remaining Life......" 
	END CASE 

	DISPLAY BY NAME trans_header 

	LET asset_change_flag = 0 
	LET curs_close_flag = 0 
	LET non_entry_flag = 0 
	LET must_change_flag = 0 
	LET delete_flag = "N" 
	LET cont_disp_flag = "Y" 

	WHILE cont_disp_flag = "Y" 
		LET cont_disp_flag = "N" 
		IF delete_flag = "N" THEN 
			DECLARE curser_item CURSOR FOR 
			SELECT faaudit.* 
			INTO pr_faaudit.* 
			FROM faaudit 
			WHERE cmpy_code = p_cmpy 
			AND batch_num = pr_fabatch.batch_num 
			AND desc_text != "Transfer - FROM" 

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
					LET pr_fabatch.actual_depr_amt = pr_fabatch.actual_depr_amt + 
					pr_faaudit.depr_amt 
				END IF 
				IF idx > 1990 THEN 
					EXIT FOREACH 
				END IF 
			END FOREACH 
			CALL set_count(idx) 
		ELSE 
			CALL set_count(new_arr_size) 
		END IF 
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
					CALL publish_toolbar("kandoo","fafintrn","inp_arr-pr_faaudith-4") -- alch kd-504 

						ON ACTION "LOOKUP" infield (asset_code) 
							#LET pb_faaudit[idx].asset_code = lookup_famast(p_cmpy)
							CALL lookup_famast(p_cmpy) RETURNING 
								pb_faaudit[idx].asset_code, 
								pb_faaudit[idx].add_on_code 

							DISPLAY pb_faaudit[idx].asset_code 	TO sr_faaudit[scrn].asset_code 
							DISPLAY pb_faaudit[idx].add_on_code		TO sr_faaudit[scrn].add_on_code 
							NEXT FIELD asset_code 
							#WHEN infield (book_code)
							#LET pb_faaudit[idx].book_code = lookup_book(p_cmpy)
							#DISPLAY pb_faaudit[idx].book_code
							#TO sr_faaudit[scrn].book_code
							#NEXT FIELD book_code


				BEFORE ROW 
					LET arr_size = arr_count() 
					LET idx = arr_curr() 
					LET scrn = scr_line() 
					LET pr_faaudit.batch_line_num = pa_faaudit[idx].batch_line_num 
					LET pr_faaudit.asset_code = pa_faaudit[idx].asset_code 
					LET pr_faaudit.add_on_code = pa_faaudit[idx].add_on_code 
					LET pr_faaudit.book_code = pa_faaudit[idx].book_code 
					LET pr_faaudit.auth_code = pa_faaudit[idx].auth_code 
					LET pr_faaudit.asset_amt = pa_faaudit[idx].asset_amt 
					LET pr_faaudit.depr_amt = pa_faaudit[idx].depr_amt 
					LET pr_faaudit.salvage_amt = pa_faaudit[idx].salvage_amt 
					LET pr_faaudit.sale_amt = pa_faaudit[idx].sale_amt 
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
					IF acount != 2000 THEN 
						FOR j = acount TO idx step -1 
							LET pa_faaudit[j+1].* = pa_faaudit[j].* 
							CALL renum() 
						END FOR 
						INITIALIZE pr_faaudit.* TO NULL 
						INITIALIZE pa_faaudit[idx].* TO NULL 
					END IF 
					LET pb_faaudit[idx].batch_line_num = idx 
					DISPLAY idx TO sr_faaudit[scrn].batch_line_num 

					IF pa_faaudit[idx].asset_code IS NULL AND idx > 1 THEN 
						LET pb_faaudit[idx].asset_code = pb_faaudit[idx-1].asset_code 
						LET pr_faaudit.asset_code = pb_faaudit[idx].asset_code 
						LET pb_faaudit[idx].add_on_code = pb_faaudit[idx-1].add_on_code 
						LET pr_faaudit.add_on_code = pb_faaudit[idx].add_on_code 

						DISPLAY pb_faaudit[idx].asset_code 
						TO sr_faaudit[scrn].asset_code 
						DISPLAY pb_faaudit[idx].add_on_code 
						TO sr_faaudit[scrn].add_on_code 
						IF asset_change_flag = 1 THEN 
							IF curs_close_flag = 0 THEN 
								DECLARE bookcurs1 SCROLL CURSOR FOR 
								SELECT unique book_code 
								INTO temp1_book_code 
								FROM fastatus 
								WHERE cmpy_code = p_cmpy 
								AND asset_code = pb_faaudit[idx].asset_code 
								AND add_on_code = pb_faaudit[idx].add_on_code 
								AND book_code <> pb_faaudit[idx-1].book_code 
								LET curs_close_flag = 1 
								OPEN bookcurs1 
							END IF 
							FETCH bookcurs1 
							IF status = notfound THEN 
								CLOSE bookcurs1 
								LET asset_change_flag = 0 
								LET non_entry_flag = 0 
								LET must_change_flag = 1 
								LET curs_close_flag = 0 
							ELSE 
								SELECT * 
								INTO pr_fastatus.* 
								FROM fastatus 
								WHERE cmpy_code = p_cmpy 
								AND asset_code = pb_faaudit[idx].asset_code 
								AND add_on_code = pb_faaudit[idx].add_on_code 
								AND book_code = temp1_book_code 

								LET non_entry_flag = 1 
								LET pr_faaudit.batch_line_num = 
								pb_faaudit[idx].batch_line_num 
								LET pr_faaudit.asset_code = pb_faaudit[idx].asset_code 
								LET pr_faaudit.add_on_code = 
								pa_faaudit[idx-1].add_on_code 
								LET pr_faaudit.book_code = temp1_book_code 
								LET pr_faaudit.auth_code = " " 
								LET pr_faaudit.asset_amt = NULL 
								LET pr_faaudit.depr_amt = NULL 
								LET pr_faaudit.salvage_amt = NULL 
								LET pr_faaudit.sale_amt = NULL 
								LET pr_faaudit.rem_life_num = 
								pa_faaudit[idx-1].rem_life_num 
								LET pr_faaudit.location_code = 
								pa_faaudit[idx-1].location_code 
								LET pr_faaudit.faresp_code = 
								pa_faaudit[idx-1].faresp_code 
								LET pr_faaudit.facat_code = pa_faaudit[idx-1].facat_code 
								LET pr_faaudit.desc_text = pa_faaudit[idx-1].desc_text 
								LET pa_faaudit[idx].batch_line_num = 
								pr_faaudit.batch_line_num 
								LET pa_faaudit[idx].asset_code = pr_faaudit.asset_code 
								LET pa_faaudit[idx].add_on_code = pr_faaudit.add_on_code 
								LET pa_faaudit[idx].book_code = pr_faaudit.book_code 
								LET pa_faaudit[idx].auth_code = pr_faaudit.auth_code 
								LET pa_faaudit[idx].asset_amt = pr_faaudit.asset_amt 
								LET pa_faaudit[idx].depr_amt = pr_faaudit.depr_amt 
								LET pa_faaudit[idx].salvage_amt = pr_faaudit.salvage_amt 
								LET pa_faaudit[idx].sale_amt = pr_faaudit.sale_amt 
								LET pa_faaudit[idx].rem_life_num = 
								pr_faaudit.rem_life_num 
								LET pa_faaudit[idx].location_code = 
								pr_faaudit.location_code 
								LET pa_faaudit[idx].faresp_code = pr_faaudit.faresp_code 
								LET pa_faaudit[idx].facat_code = pr_faaudit.facat_code 
								LET pa_faaudit[idx].desc_text = pr_faaudit.desc_text 

								LET pb_faaudit[idx].book_code = temp1_book_code 
								LET pb_faaudit[idx].asset_amt = 0 
								LET pb_faaudit[idx].depr_amt = 0 

								DISPLAY pb_faaudit[idx].book_code, 
								pb_faaudit[idx].asset_amt, 
								pb_faaudit[idx].depr_amt 
								TO sr_faaudit[scrn].book_code, 
								sr_faaudit[scrn].asset_amt, 
								sr_faaudit[scrn].depr_amt 
							END IF 
						END IF 
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
							MESSAGE "Asset ID NOT found - try window" attribute(yellow) 
							NEXT FIELD asset_code 
						ELSE 
							IF pr_famast.location_code IS NULL THEN 
								ERROR "This asset has NOT had financial details added" 
								NEXT FIELD asset_code 
							END IF 
						END IF 
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
							" has been sold - cannot change" 
							NEXT FIELD asset_code 
						END IF 
						IF tmp_faaudit.trans_ind = "R" THEN 
							ERROR "Asset :",pb_faaudit[idx].asset_code, 
							" has been retired - cannot change" 
							NEXT FIELD asset_code 
						END IF 
					END IF 


					IF pb_faaudit[idx].asset_code = pr_famast.asset_code AND 
					pb_faaudit[idx].add_on_code = pr_famast.add_on_code AND 
					pa_faaudit[idx].desc_text IS NULL THEN 
						LET pa_faaudit[idx].desc_text = pr_famast.desc_text 
					END IF 

					LET acnt = arr_count() 

					IF (idx = 1) THEN 

						IF (acnt = 1) THEN 

							LET asset_change_flag = 1 

							DECLARE bookcurs2 SCROLL CURSOR FOR 
							SELECT unique book_code 
							INTO temp1_book_code 
							FROM fastatus 
							WHERE cmpy_code = p_cmpy 
							AND asset_code = pb_faaudit[idx].asset_code 
							AND add_on_code = pb_faaudit[idx].add_on_code 

							OPEN bookcurs2 
							FETCH bookcurs2 

							SELECT * 
							INTO pr_fastatus.* 
							FROM fastatus 
							WHERE cmpy_code = p_cmpy 
							AND asset_code = pb_faaudit[idx].asset_code 
							AND add_on_code = pb_faaudit[idx].add_on_code 
							AND book_code = temp1_book_code 

							LET pb_faaudit[idx].book_code = pr_fastatus.book_code 
							DISPLAY pb_faaudit[idx].book_code TO 
							sr_faaudit[scrn].book_code 
							CLOSE bookcurs2 
							LET pr_faaudit.location_code = pr_famast.location_code 
							LET pr_faaudit.faresp_code = pr_famast.faresp_code 
							LET pr_faaudit.facat_code = pr_famast.facat_code 
						END IF 
					ELSE 
						IF (idx > 1) AND 
						(acnt = idx) AND 
						((pb_faaudit[idx].asset_code <> 
						pb_faaudit[idx-1].asset_code) OR 
						(pb_faaudit[idx].add_on_code <> 
						pb_faaudit[idx-1].add_on_code)) THEN 

							LET asset_change_flag = 1 

							DECLARE bookcurs3 SCROLL CURSOR FOR 
							SELECT unique book_code 
							INTO temp1_book_code 
							FROM fastatus 
							WHERE cmpy_code = p_cmpy 
							AND asset_code = pb_faaudit[idx].asset_code 
							AND add_on_code = pb_faaudit[idx].add_on_code 

							OPEN bookcurs3 
							FETCH bookcurs3 
							SELECT * 
							INTO pr_fastatus.* 
							FROM fastatus 
							WHERE cmpy_code = p_cmpy 
							AND asset_code = pb_faaudit[idx].asset_code 
							AND add_on_code = pb_faaudit[idx].add_on_code 
							AND book_code = temp1_book_code 

							LET pb_faaudit[idx].book_code = pr_fastatus.book_code 
							DISPLAY pb_faaudit[idx].book_code TO 
							sr_faaudit[scrn].book_code 
							CLOSE bookcurs3 
							LET pr_faaudit.location_code = pr_famast.location_code 
							LET pr_faaudit.faresp_code = pr_famast.faresp_code 
							LET pr_faaudit.facat_code = pr_famast.facat_code 
						END IF 
					END IF 

				BEFORE FIELD book_code 
					IF pb_faaudit[idx].book_code IS NULL THEN 
						ERROR "This asset/add on/book code IS Invalid!" 
						NEXT FIELD asset_code 
					END IF 
					IF check_dups() THEN 
						NEXT FIELD asset_code 
					END IF 
					IF (idx > 1) THEN 
						IF pb_faaudit[idx].asset_code = pb_faaudit[idx-1].asset_code AND 
						pb_faaudit[idx].add_on_code = 
						pb_faaudit[idx-1].add_on_code AND 
						pb_faaudit[idx].book_code IS NULL AND 
						must_change_flag = 1 THEN 

							CASE tran_type 
								WHEN "T" 
									ERROR "You have transfered all books FOR this asset" 
									NEXT FIELD asset_code 
								WHEN "S" 
									ERROR "You have sold all books FOR this asset" 
									NEXT FIELD asset_code 
								WHEN "R" 
									ERROR "You have retired all books FOR this asset" 
									NEXT FIELD asset_code 
							END CASE 
						ELSE 
							LET must_change_flag = 0 
						END IF 
					END IF 
					IF asset_change_flag <> 1 THEN 
						FOR k = 1 TO arr_count() 
							IF pa_faaudit[k].asset_code = pb_faaudit[idx].asset_code AND 
							pa_faaudit[k].add_on_code = 
							pb_faaudit[idx].add_on_code THEN 
								LET pr_faaudit.location_code = 
								pa_faaudit[k].location_code 
								LET pr_faaudit.faresp_code = pa_faaudit[k].faresp_code 
								LET pr_faaudit.facat_code = pa_faaudit[k].facat_code 
								LET non_entry_flag = 1 
							END IF 
						END FOR 
					END IF 
					CALL trn_fn(p_cmpy,typer) 
					IF (nxtfld = 1 AND idx > 1) THEN 
						LET pb_faaudit[idx].asset_code = pb_faaudit[idx-1].asset_code 
						LET pb_faaudit[idx].add_on_code = pb_faaudit[idx-1].add_on_code 
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
					FOR j = idx TO arr_count() 
						IF pa_faaudit[idx].asset_code = 
						pa_faaudit[j].asset_code AND 
						pa_faaudit[idx].add_on_code = 
						pa_faaudit[j].add_on_code THEN 
							IF pa_faaudit[idx].location_code <> 
							pa_faaudit[j].location_code 
							THEN 
								LET pa_faaudit[j].location_code = 
								pa_faaudit[idx].location_code 
							END IF 
							IF pa_faaudit[idx].facat_code <> pa_faaudit[j].facat_code 
							THEN 
								LET pa_faaudit[j].facat_code = pa_faaudit[idx].facat_code 
							END IF 
							IF pa_faaudit[idx].faresp_code <> pa_faaudit[j].faresp_code 
							THEN 
								LET pa_faaudit[j].faresp_code = 
								pa_faaudit[idx].faresp_code 
							END IF 
						END IF 
					END FOR 
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

				ON KEY (F2) 
					CALL delete_rows() 
					LET cont_disp_flag = "Y" 
					LET delete_flag = "Y" 
					EXIT INPUT 

				AFTER INPUT 
					LET arr_size = arr_count() 

				ON KEY (control-w) 
					CALL kandoohelp("") 
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
			END INPUT 

			LET do_check = false 
			IF int_flag OR quit_flag THEN 
				--            prompt " Are you sure you want TO cancel (y/n)? " -- albo
				--               FOR CHAR doit_once
				LET doit_once = promptYN(""," Are you sure you want TO cancel (y/n)? ","Y") -- albo 
				LET doit_once= upshift (doit_once) 
				IF doit_once = "N" THEN 
					LET int_flag = 0 
					LET quit_flag = 0 
				END IF 
			ELSE 
				LET doit_once= "Y" 
				LET do_check = true 
			END IF 
			IF do_check THEN 
				DELETE FROM tmp_check WHERE 1=1 
				FOR x = 1 TO arr_size 
					WHENEVER ERROR CONTINUE 
					IF (pa_faaudit[x].asset_amt != 0 AND 
					pa_faaudit[x].asset_amt IS NOT null) OR 
					(pa_faaudit[x].sale_amt != 0 AND 
					pa_faaudit[x].sale_amt IS NOT null) THEN 
						INSERT INTO tmp_check VALUES (pa_faaudit[x].asset_code, 
						pa_faaudit[x].add_on_code, 
						pa_faaudit[x].book_code) 
					END IF 
					IF status THEN 
						CONTINUE FOR 
					END IF 
					WHENEVER ERROR stop 
				END FOR 
				DECLARE tc_curs1 CURSOR FOR 
				SELECT unique asset_code,add_on_code 
				INTO tmp_asset_code,tmp_add_on_code 
				FROM tmp_check 

				FOREACH tc_curs1 
					DECLARE book_curs CURSOR FOR 
					SELECT * 
					FROM fabookdep 
					WHERE cmpy_code = p_cmpy 
					AND asset_code = tmp_asset_code 
					AND add_on_code = tmp_add_on_code 

					FOREACH book_curs INTO pr_fabookdep.* 
						SELECT * 
						FROM tmp_check 
						WHERE asset_code = pr_fabookdep.asset_code 
						AND add_on_code = pr_fabookdep.add_on_code 
						AND book_code = pr_fabookdep.book_code 
						IF status THEN 
							ERROR "Asset :",pr_fabookdep.asset_code clipped, 
							" Add on :",pr_fabookdep.add_on_code clipped, 
							" Book :",pr_fabookdep.book_code, 
							" MUST be in this batch" 
							SLEEP 1 
							# don't stop entry IF all books are NOT in the batch
							IF typer != "V" THEN 
								LET doit_once = "N" 
							ELSE 
								--                             prompt "Continue - Add batch anyway (y/n)? "  -- albo
								--                                      FOR CHAR doit_once
								LET doit_once = promptYN("","Continue - Add batch anyway (y/n)? ","Y") -- albo 
								LET doit_once= upshift (doit_once) 
								IF doit_once != "Y" THEN 
									LET doit_once = "N" 
								END IF 
							END IF 
						END IF 
					END FOREACH 
				END FOREACH 
			END IF 
		END WHILE # ans = "Y" 
	END WHILE # cont_disp_flag = "N" 
	CLEAR screen 
	CLOSE WINDOW wf159 

END FUNCTION { fafintrn } 

FUNCTION trn_fn(p_cmpy,typer) 
	DEFINE 
	typer CHAR(1), 
	p_cmpy LIKE company.cmpy_code 

	LET pr_faaudit.batch_line_num = pb_faaudit[idx].batch_line_num 
	LET pr_faaudit.asset_code = pb_faaudit[idx].asset_code 
	LET pr_faaudit.add_on_code = pb_faaudit[idx].add_on_code 
	LET pr_faaudit.book_code = pb_faaudit[idx].book_code 
	LET pr_faaudit.auth_code = " " 

	IF pr_fastatus.asset_code IS NULL THEN 
		SELECT * 
		INTO pr_fastatus.* 
		FROM fastatus 
		WHERE cmpy_code = p_cmpy 
		AND asset_code = pr_faaudit.asset_code 
		AND add_on_code = pr_faaudit.add_on_code 
		AND book_code = pr_faaudit.book_code 
	END IF 


	IF pr_faaudit.depr_amt IS NULL THEN 
		LET pr_faaudit.depr_amt = pa_faaudit[idx].depr_amt 
	END IF 

	IF pr_faaudit.faresp_code IS NULL THEN 
		LET pr_faaudit.faresp_code = pa_faaudit[idx].faresp_code 
	END IF 
	IF pr_faaudit.facat_code IS NULL THEN 
		LET pr_faaudit.facat_code = pa_faaudit[idx].facat_code 
	END IF 
	IF pr_faaudit.location_code IS NULL THEN 
		LET pr_faaudit.location_code = pa_faaudit[idx].location_code 
	END IF 

	LET pr_faaudit.salvage_amt = pr_fastatus.salvage_amt 
	IF typer = "V" THEN 
		LET pr_faaudit.sale_amt = 0 
	ELSE 
		LET pr_faaudit.sale_amt = pr_fastatus.net_book_val_amt 
	END IF 
	LET pr_faaudit.rem_life_num = pr_fastatus.rem_life_num 
	IF pr_faaudit.desc_text IS NULL THEN 
		LET pr_faaudit.desc_text = pr_famast.desc_text 
	END IF 

	SELECT * 
	INTO pr_fabook.* 
	FROM fabook 
	WHERE cmpy_code = p_cmpy AND 
	book_code = pr_faaudit.book_code 

	SELECT * 
	INTO pr_falocation.* 
	FROM falocation 
	WHERE cmpy_code = p_cmpy AND 
	location_code = pr_faaudit.location_code 

	SELECT * 
	INTO pr_faresp.* 
	FROM faresp 
	WHERE cmpy_code = p_cmpy AND 
	faresp_code = pr_faaudit.faresp_code 

	SELECT * 
	INTO pr_facat.* 
	FROM facat 
	WHERE cmpy_code = p_cmpy AND 
	facat_code = pr_faaudit.facat_code 

	CALL trn_details(p_cmpy,typer) 
	CURRENT WINDOW IS wf159 
END FUNCTION 

FUNCTION trn_details(p_cmpy,typer) 
	DEFINE 
	typer CHAR(1), 
	p_cmpy LIKE company.cmpy_code, 
	from_location LIKE famast.location_code, 
	from_category LIKE famast.facat_code, 
	from_resp LIKE famast.faresp_code, 
	field_no SMALLINT 



	IF typer = "T" THEN 
		OPEN WINDOW wf101 with FORM "F103" -- alch kd-757 
		CALL  winDecoration_f("F103") -- alch kd-757 
		SELECT location_code, 
		facat_code, 
		faresp_code 
		INTO from_location, 
		from_category, 
		from_resp 
		FROM famast 
		WHERE cmpy_code = p_cmpy 
		AND asset_code = pr_faaudit.asset_code 
		AND add_on_code = pr_faaudit.add_on_code 

		DISPLAY from_location TO from_location_code 
		DISPLAY from_category TO from_facat_code 
		DISPLAY from_resp TO from_faresp_code 
	ELSE 
		OPEN WINDOW wf101 with FORM "F101" -- alch kd-757 
		CALL  winDecoration_f("F101") -- alch kd-757 
	END IF 

	DISPLAY BY NAME trans_header 

	IF typer != "T" THEN 
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
	END IF 



	IF typer = "T" THEN 
		DISPLAY pr_faaudit.batch_line_num, 
		pr_faaudit.asset_code, 
		pr_faaudit.add_on_code, 
		pr_famast.desc_text, 
		pr_faaudit.book_code, 
		pr_fabook.book_text, 
		pr_faaudit.asset_amt, 
		pr_faaudit.depr_amt, 
		pr_faaudit.salvage_amt, 
		pr_faaudit.sale_amt, 
		pr_faaudit.rem_life_num, 
		pr_faaudit.location_code, 

		pr_faaudit.faresp_code, 

		pr_faaudit.facat_code, 

		pr_faaudit.desc_text 
		TO faaudit.batch_line_num, 
		faaudit.asset_code, 
		faaudit.add_on_code, 
		famast.desc_text, 
		faaudit.book_code, 
		fabook.book_text, 
		faaudit.asset_amt, 
		faaudit.depr_amt, 
		faaudit.salvage_amt, 
		faaudit.sale_amt, 
		faaudit.rem_life_num, 
		faaudit.location_code, 

		faaudit.faresp_code, 

		faaudit.facat_code, 

		faaudit.desc_text 

	ELSE 
		DISPLAY pr_faaudit.batch_line_num, 
		pr_faaudit.asset_code, 
		pr_faaudit.add_on_code, 
		pr_famast.desc_text, 
		pr_faaudit.book_code, 
		pr_fabook.book_text, 
		pr_faaudit.asset_amt, 
		pr_faaudit.depr_amt, 
		pr_faaudit.salvage_amt, 
		pr_faaudit.sale_amt, 
		pr_faaudit.rem_life_num, 
		pr_faaudit.location_code, 
		pr_falocation.location_text, 
		pr_faaudit.faresp_code, 
		pr_faresp.faresp_text, 
		pr_faaudit.facat_code, 
		pr_facat.facat_text, 
		pr_faaudit.desc_text 
		TO faaudit.batch_line_num, 
		faaudit.asset_code, 
		faaudit.add_on_code, 
		famast.desc_text, 
		faaudit.book_code, 
		fabook.book_text, 
		faaudit.asset_amt, 
		faaudit.depr_amt, 
		faaudit.salvage_amt, 
		faaudit.sale_amt, 
		faaudit.rem_life_num, 
		faaudit.location_code, 
		falocation.location_text, 
		faaudit.faresp_code, 
		faresp.faresp_text, 
		faaudit.facat_code, 
		facat.facat_text, 
		faaudit.desc_text 

	END IF 

	INPUT pr_faaudit.asset_amt, 
	pr_faaudit.sale_amt, 
	pr_faaudit.location_code, 

	pr_faaudit.facat_code, 
	pr_faaudit.desc_text 
	WITHOUT DEFAULTS 
	FROM faaudit.asset_amt, 
	faaudit.sale_amt, 
	faaudit.location_code, 

	faaudit.facat_code, 
	faaudit.desc_text 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","fafintrn","inp-pr_faaudit-5") -- alch kd-504 
		ON ACTION "NOTES" infield (desc_text) --ON KEY (control-n) 
				LET pr_faaudit.desc_text = sys_noter(p_cmpy,pr_faaudit.desc_text) 
				DISPLAY pr_faaudit.desc_text TO 
				faaudit.desc_text 

				NEXT FIELD faaudit.desc_text 

		ON KEY (control-b) 
			CASE 
				WHEN infield (location_code) 
					LET pr_faaudit.location_code = lookup_location(p_cmpy) 
					DISPLAY pr_faaudit.location_code 
					TO faaudit.location_code 

					NEXT FIELD faaudit.location_code 

				WHEN infield (facat_code) 
					LET pr_faaudit.facat_code = lookup_facat_code(p_cmpy) 
					DISPLAY pr_faaudit.facat_code 
					TO faaudit.facat_code 

					NEXT FIELD faaudit.facat_code 

			END CASE 

		BEFORE FIELD asset_amt 
			IF typer = "V" THEN 
				IF pr_faaudit.asset_amt IS NULL THEN 
					LET pr_faaudit.asset_amt = 0 
					DISPLAY pr_faaudit.asset_amt TO faaudit.asset_amt 

				END IF 
			ELSE 
				IF pr_faaudit.asset_amt IS NULL OR pr_faaudit.asset_amt = 0 THEN 
					LET pr_faaudit.asset_amt = pr_fastatus.cur_depr_cost_amt 
					DISPLAY pr_faaudit.asset_amt TO faaudit.asset_amt 

				END IF 
			END IF 
			IF pr_faaudit.depr_amt IS NULL OR pr_faaudit.depr_amt = 0 THEN 
				SELECT depr_amt 
				INTO pr_faaudit.depr_amt 
				FROM fastatus 
				WHERE cmpy_code = p_cmpy 
				AND asset_code = pr_faaudit.asset_code 
				AND add_on_code = pr_faaudit.add_on_code 
				AND book_code = pr_faaudit.book_code 
				DISPLAY pr_faaudit.depr_amt TO faaudit.depr_amt 
			END IF 

			IF typer = "S" THEN 
				NEXT FIELD faaudit.sale_amt 
			END IF 

		AFTER FIELD asset_amt 

			LET field_no = 10 
			IF pr_faaudit.asset_amt IS NULL THEN 
				LET pr_faaudit.asset_amt = 0 
				DISPLAY pr_faaudit.asset_amt TO faaudit.asset_amt 

			END IF 

			IF pr_fastatus.cur_depr_cost_amt IS NULL THEN 
				LET pr_fastatus.cur_depr_cost_amt = 0 
			END IF 

			IF typer = "R" THEN 
				IF pr_fastatus.cur_depr_cost_amt != pr_faaudit.asset_amt THEN 
					ERROR "Retire value must equal : ",pr_fastatus.cur_depr_cost_amt, 
					" (F11)" 
					SLEEP 2 
					NEXT FIELD faaudit.asset_amt 
				END IF 
			END IF 


			IF pr_fastatus.depr_amt IS NULL THEN 
				LET pr_fastatus.depr_amt = 0 
			END IF 
			IF pr_faaudit.depr_amt IS NULL THEN 
				LET pr_faaudit.depr_amt = pr_fastatus.depr_amt 
			END IF 
			DISPLAY BY NAME pr_faaudit.depr_amt 


			IF typer = "S" THEN 
				NEXT FIELD faaudit.sale_amt 
			END IF 

			IF typer = "V" THEN 
				LET pr_faaudit.sale_amt = pr_faaudit.asset_amt - 
				pr_fastatus.cur_depr_cost_amt 

				DISPLAY BY NAME pr_faaudit.sale_amt 
				NEXT FIELD faaudit.desc_text 
			END IF 


		AFTER FIELD sale_amt 
			LET field_no = 20 
			IF typer = "V" THEN 
				IF pr_fastatus.net_book_val_amt + pr_faaudit.sale_amt < 0 THEN 
					ERROR "Can't revalue an asset TO less than NBV (", 
					pr_fastatus.net_book_val_amt,")" 
					NEXT FIELD faaudit.sale_amt 
				END IF 
			END IF 

			IF typer = "S" THEN 
				NEXT FIELD faaudit.desc_text 
			END IF 

		BEFORE FIELD location_code 
			IF typer = "V" THEN 
				IF field_no > 20 THEN 
					NEXT FIELD faaudit.sale_amt 
				ELSE 
					NEXT FIELD faaudit.desc_text 
				END IF 
			END IF 

		AFTER FIELD location_code 
			LET field_no = 30 
			IF verify_loc(p_cmpy, pr_faaudit.location_code) = 1 
			THEN 
				NEXT FIELD faaudit.location_code 
			ELSE 

				IF typer != "T" THEN 
					DISPLAY BY NAME pr_falocation.location_text 
				END IF 
			END IF 


		BEFORE FIELD facat_code 
			IF (typer = "R") OR non_entry_flag = 1 THEN 
				NEXT FIELD faaudit.desc_text 
			END IF 

			IF typer = "S" AND field_no > 40 THEN 
				NEXT FIELD faaudit.sale_amt 
			END IF 

			IF typer = "V" THEN 
				IF field_no = 60 THEN 
					NEXT FIELD faaudit.asset_amt 
				END IF 
			END IF 


		AFTER FIELD facat_code 
			LET field_no = 50 
			IF verify_cat(p_cmpy, pr_faaudit.facat_code) = 1 THEN 
				NEXT FIELD faaudit.facat_code 
			ELSE 

				IF typer != "T" THEN 
					DISPLAY BY NAME pr_facat.facat_text 
				END IF 


			END IF 

		BEFORE FIELD desc_text 
			# IF just account AND a last desc use that description
			IF pa_faaudit[idx].desc_text = pr_famast.desc_text 
			AND last_desc IS NOT NULL THEN 
				LET pa_faaudit[idx].desc_text = last_desc 
				DISPLAY pr_faaudit.desc_text TO faaudit.desc_text 
			END IF 

		AFTER FIELD desc_text 
			LET field_no = 60 
			IF pr_famast.desc_text != pr_faaudit.desc_text THEN 
				LET last_desc = pr_faaudit.desc_text 
			END IF 

		ON KEY (control-w) 
			CALL kandoohelp("") 
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
	END INPUT 
	IF int_flag != 0 OR 
	quit_flag != 0 
	THEN 
		LET int_flag = 0 
		LET quit_flag = 0 
		LET nxtfld = 1 
	ELSE 
		LET nxtfld = 0 
	END IF 

	CLOSE WINDOW wf101 
	RETURN 
END FUNCTION 

FUNCTION delete_rows() 
	DEFINE 
	ans CHAR(1), 
	asset_del_code LIKE faaudit.asset_code, 
	add_on_del_code LIKE faaudit.add_on_code, 
	pa_curr, pa_total, 
	sc_curr, sc_total, k, a SMALLINT 

	#OPEN WINDOW w1 AT 10,4 with 1 rows, 57 columns
	#ATTRIBUTE(border, white)  -- alch KD-757


	CASE tran_type 
		WHEN "T" 
			--           prompt "Remove all books FROM transfer of this asset (y/n)?" -- albo
			--           FOR CHAR ans
			LET ans = promptYN("","Remove all books FROM transfer of this asset (y/n)?","Y") -- albo 
		WHEN "S" 
			--           prompt "Remove all books FROM sale of this asset (y/n)?" -- albo
			--           FOR CHAR ans
			LET ans = promptYN("","Remove all books FROM sale of this asset (y/n)?","Y") -- albo 
		WHEN "R" 
			--           prompt "Remove all books FROM retirement of this asset (y/n)?" -- albo
			--           FOR CHAR ans
			LET ans = promptYN("","Remove all books FROM retirement of this asset (y/n)?","Y") -- albo 
		WHEN "V" 
			--           prompt "Remove all books FROM revaluation of this asset (y/n)?"  -- albo
			--           FOR CHAR ans
			LET ans = promptYN("","Remove all books FROM revaluation of this asset (y/n)?","Y") -- albo 
	END CASE 
	LET ans = downshift(ans) 
	#CLOSE WINDOW w1  -- alch KD-757

	IF ans = "y" THEN 

		LET asset_del_code = pb_faaudit[idx].asset_code 
		LET add_on_del_code = pb_faaudit[idx].add_on_code 

		LET acount = arr_count() 

		FOR j = 1 TO (acount-1) 
			WHILE (pb_faaudit[j].asset_code = asset_del_code AND 
				pb_faaudit[j].add_on_code = add_on_del_code) 
				FOR k = j TO (acount - 1) 
					LET pb_faaudit[k].* = pb_faaudit[k+1].* 
					LET pa_faaudit[k].* = pa_faaudit[k+1].* 
				END FOR 
				INITIALIZE pa_faaudit[acount].* TO NULL 
				INITIALIZE pb_faaudit[acount].* TO NULL 
			END WHILE 
		END FOR 

		INITIALIZE pr_faaudit.* TO NULL 
		IF curs_close_flag = 1 THEN 
			CLOSE bookcurs1 
			LET asset_change_flag = 0 
			LET curs_close_flag = 0 
			LET non_entry_flag = 0 
		END IF 
		IF arr_count() = 1 THEN 
			LET new_arr_size = 0 
		ELSE 
			FOR a = 1 TO arr_count() 
				IF pb_faaudit[a].asset_code IS NULL THEN 
					LET new_arr_size = a - 1 
					EXIT FOR 
				END IF 
			END FOR 
		END IF 
		LET pa_total = arr_count() 
		LET sc_curr = scr_line() 
		LET sc_total = 10 
		FOR k = 1 TO pa_total 
			LET pa_faaudit[k].batch_line_num = k 
			LET pb_faaudit[k].batch_line_num = k 
		END FOR 
	ELSE 
		LET new_arr_size = arr_count() 
	END IF 

END FUNCTION 


FUNCTION check_dups() 

	DEFINE 
	x SMALLINT 

	FOR x = 1 TO arr_size 
		IF x = idx THEN 
			CONTINUE FOR 
		END IF 
		IF pb_faaudit[x].asset_code = pb_faaudit[idx].asset_code AND 
		pb_faaudit[x].add_on_code = pb_faaudit[idx].add_on_code AND 
		pb_faaudit[x].book_code = pb_faaudit[idx].book_code THEN 
			ERROR "Asset/Add On/Book Code combination already entered" 
			LET pb_faaudit[idx].asset_code = " " 
			LET pb_faaudit[idx].add_on_code = " " 
			LET pb_faaudit[idx].book_code = " " 
			DISPLAY pb_faaudit[idx].asset_code, 
			pb_faaudit[idx].add_on_code, 
			pb_faaudit[idx].book_code 
			TO sr_faaudit[scrn].asset_code, 
			sr_faaudit[scrn].add_on_code, 
			sr_faaudit[scrn].book_code 
			RETURN true 
		END IF 
	END FOR 
	RETURN false 
END FUNCTION 
