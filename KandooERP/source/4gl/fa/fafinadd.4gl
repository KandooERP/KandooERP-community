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

{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module :    fafinadd.4gl
# Purpose    :    Asset additions

GLOBALS 
	DEFINE 
	pr_fabatch RECORD LIKE fabatch.*, 
	pr_faparms RECORD LIKE faparms.*, 
	pr_faaudit RECORD LIKE faaudit.*, 
	pr_famast RECORD LIKE famast.*, 
	pr_fastatus RECORD LIKE fastatus.*, 
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
	pr_fabook RECORD LIKE fabook.*, 
	pr_falocation RECORD LIKE falocation.*, 
	b_return CHAR(20), 
	pr_faresp RECORD LIKE faresp.*, 
	pr_facat RECORD LIKE facat.*, 
	temp1_book_code LIKE faaudit.book_code, 
	last_desc LIKE faaudit.desc_text, 
	tempasset, tempdepr MONEY (15,2), 
	trans_header CHAR(24), 

	trans_detl1 CHAR(20), 
	trans_detl2 CHAR(20), 
	trans_detl3 CHAR(20), 
	k, j, i, idx, scrn SMALLINT, 
	doit_once CHAR(1), 
	acount INTEGER, 
	nxtfld SMALLINT, 
	non_entry_flag, asset_change_flag, curs_close_flag, 
	arr_size SMALLINT, 
	depn_code LIKE fabookdep.depn_code 

END GLOBALS 

FUNCTION fafinadd(p_cmpy, typer) 

	DEFINE 
	p_cmpy LIKE company.cmpy_code, 
	typer CHAR(1), 
	oidx SMALLINT, 
	batch LIKE faaudit.batch_num, 
	ln LIKE faaudit.batch_line_num, 
	nolines SMALLINT 

	OPEN WINDOW wf159 with FORM "F159" -- alch kd-757 
	CALL  winDecoration_f("F159") -- alch kd-757 
	CASE typer 
		WHEN "A" 
			LET trans_header = " Addition " 
			LET trans_detl1 = "Asset Net book value." 
			LET trans_detl2 = "Sale Amount.........." 
			LET trans_detl3 = "Remaining Life......." 
	END CASE 

	DISPLAY BY NAME trans_header 

	LET asset_change_flag = 0 
	LET curs_close_flag = 0 

	DECLARE curser_item CURSOR FOR 
	SELECT * 
	INTO pr_faaudit.* 
	FROM faaudit 
	WHERE cmpy_code = p_cmpy 
	AND batch_num = pr_fabatch.batch_num 

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

	LET nolines = idx 
	CALL set_count(idx) 
	DISPLAY BY NAME 
	pr_fabatch.batch_num, 
	pr_fabatch.actual_asset_amt, 
	pr_fabatch.actual_depr_amt, 
	pr_faaudit.entry_date 


	MESSAGE " " 
	MESSAGE " F1 TO add, RETURN on line TO change, ESC TO UPDATE" 
	attribute(yellow) 

	LET doit_once = "N" 
	WHILE doit_once = "N" 
		LET doit_once = "Y" 
		INITIALIZE pr_faaudit.* TO NULL 
		INPUT ARRAY pb_faaudit WITHOUT DEFAULTS FROM sr_faaudit.* 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","fafinadd","inp-pb_faaudit-1") -- alch kd-504 
			

					ON ACTION "LOOKUP" infield (asset_code) 
						CALL lookup_famast(p_cmpy) RETURNING pb_faaudit[idx].asset_code, 
						pb_faaudit[idx].add_on_code 
						DISPLAY pb_faaudit[idx].asset_code 
						TO sr_faaudit[scrn].asset_code 

						DISPLAY pb_faaudit[idx].add_on_code 
						TO sr_faaudit[scrn].add_on_code 


						NEXT FIELD asset_code 

					ON ACTION "LOOKUP" infield (book_code) 
						LET pb_faaudit[idx].book_code = lookup_book(p_cmpy) 
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
				LET pr_faaudit.salvage_amt = pa_faaudit[idx].salvage_amt 
				LET pr_faaudit.sale_amt = pa_faaudit[idx].sale_amt 
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
					MESSAGE " F1 TO add, RETURN on line TO change, ESC TO UPDATE" 
					attribute(yellow) 
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

					DISPLAY pb_faaudit[idx].asset_code TO sr_faaudit[scrn].asset_code 
					DISPLAY pb_faaudit[idx].add_on_code TO sr_faaudit[scrn].add_on_code 
					IF asset_change_flag = 1 THEN 
						IF curs_close_flag = 0 THEN 
							DECLARE bookcurs CURSOR FOR 
							SELECT book_code 
							INTO temp1_book_code 
							FROM fabook 
							WHERE cmpy_code = p_cmpy 
							AND book_code <> pb_faaudit[idx-1].book_code 
							AND NOT exists (SELECT * 
							FROM fastatus 
							WHERE cmpy_code = p_cmpy 
							AND asset_code = 
							pr_faaudit.asset_code 
							AND add_on_code = 
							pr_faaudit.add_on_code 
							AND book_code = fabook.book_code) 

							LET curs_close_flag = 1 
							OPEN bookcurs 
						END IF 
						FETCH bookcurs 
						IF status = notfound THEN 
							CLOSE bookcurs 
							LET asset_change_flag = 0 
							LET curs_close_flag = 0 
						ELSE 
							LET pr_faaudit.batch_line_num = 
							pb_faaudit[idx].batch_line_num 
							LET pr_faaudit.asset_code = pb_faaudit[idx].asset_code 
							LET pr_faaudit.add_on_code = pa_faaudit[idx-1].add_on_code 
							LET pr_faaudit.book_code = temp1_book_code 
							LET pr_faaudit.auth_code = " " 
							LET pr_faaudit.asset_amt = NULL 
							LET pr_faaudit.depr_amt = NULL 
							LET pr_faaudit.salvage_amt = NULL 
							LET pr_faaudit.sale_amt = NULL 
							LET pr_faaudit.rem_life_num = pa_faaudit[idx-1].rem_life_num 
							LET pr_faaudit.location_code = pa_faaudit[idx-1].location_code 
							LET pr_faaudit.faresp_code = pa_faaudit[idx-1].faresp_code 
							LET pr_faaudit.facat_code = pa_faaudit[idx-1].facat_code 
							LET pr_faaudit.desc_text = pa_faaudit[idx-1].desc_text 

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
				IF verify_asset_code(p_cmpy, pb_faaudit[idx].asset_code, 
				pb_faaudit[idx].add_on_code) THEN 
					MESSAGE "Asset ID NOT found - try window" attribute(yellow) 
					NEXT FIELD asset_code 
				END IF 
				IF pb_faaudit[idx].asset_code = pr_famast.asset_code AND 
				pb_faaudit[idx].add_on_code = pr_famast.add_on_code AND 
				pa_faaudit[idx].desc_text IS NULL THEN 
					LET pa_faaudit[idx].desc_text = pr_famast.desc_text 
				END IF 

			BEFORE FIELD book_code 
				LET non_entry_flag = 0 
				IF asset_change_flag = 1 THEN 
					IF (idx > 1) THEN 
						IF (pb_faaudit[idx].asset_code = 
						pb_faaudit[idx-1].asset_code) AND 
						(pb_faaudit[idx].add_on_code = 
						pb_faaudit[idx-1].add_on_code) 
						THEN 
							LET non_entry_flag = 1 
							CALL add_fn(p_cmpy) 
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

								LET pb_faaudit[idx].asset_amt = 
								pa_faaudit[idx].asset_amt 
								LET pb_faaudit[idx].depr_amt = 
								pa_faaudit[idx].depr_amt 
								DISPLAY pb_faaudit[idx].asset_amt, 
								pb_faaudit[idx].depr_amt 
								TO sr_faaudit[scrn].asset_amt, 
								sr_faaudit[scrn].depr_amt 

							END IF 
							NEXT FIELD depr_amt 
						END IF 
					END IF 
				END IF 

			AFTER FIELD book_code 
				IF verify_book(p_cmpy,pb_faaudit[idx].book_code) = 1 THEN 
					NEXT FIELD book_code 
				ELSE 
					SELECT * 
					INTO pr_fastatus.* 
					FROM fastatus 
					WHERE cmpy_code = p_cmpy 
					AND asset_code = pb_faaudit[idx].asset_code 
					AND add_on_code = pb_faaudit[idx].add_on_code 
					AND book_code = pb_faaudit[idx].book_code 

					DECLARE batch_curs CURSOR FOR 
					SELECT batch_num,batch_line_num 
					INTO batch,ln 
					FROM faaudit 
					WHERE cmpy_code = p_cmpy 
					AND asset_code = pb_faaudit[idx].asset_code 
					AND add_on_code = pb_faaudit[idx].add_on_code 
					AND book_code = pb_faaudit[idx].book_code 
					OPEN batch_curs 
					FETCH batch_curs 
					IF NOT status AND NOT nolines THEN 
						ERROR "Financial details already added. Batch ", 
						batch USING "<<<<"," line ",ln USING "<<<<" 
						NEXT FIELD book_code 
					END IF 
				END IF 

				IF pr_famast.location_code IS NOT NULL THEN 
					MESSAGE 
					"Location, responsibility AND category already established" 
					attribute(yellow) 
					SLEEP 2 
					LET pr_faaudit.location_code = pr_famast.location_code 
					LET pr_faaudit.faresp_code = pr_famast.faresp_code 
					LET pr_faaudit.facat_code = pr_famast.facat_code 
					LET non_entry_flag = 1 
				END IF 
				IF idx = 1 THEN 
					LET asset_change_flag = 1 
				ELSE 
					IF (idx > 1) AND 
					(pb_faaudit[idx].asset_code <> pb_faaudit[idx-1].asset_code) 
					AND (pb_faaudit[idx].add_on_code <> pb_faaudit[idx-1].add_on_code) 
					THEN 
						LET asset_change_flag = 1 
					END IF 
				END IF 
				FOR k = 1 TO arr_count() 
					IF pa_faaudit[k].asset_code = pb_faaudit[idx].asset_code 
					AND pa_faaudit[k].add_on_code = pb_faaudit[idx].add_on_code 
					AND pa_faaudit[k].book_code = pb_faaudit[idx].book_code 
					AND k <> idx 
					THEN 
						ERROR "This asset/book has already been entered" 
						NEXT FIELD book_code 
					END IF 
				END FOR 
				FOR k = 1 TO idx 
					IF pa_faaudit[k].asset_code = pb_faaudit[idx].asset_code 
					AND pa_faaudit[k].add_on_code = pb_faaudit[idx].add_on_code 
					THEN 
						LET pr_faaudit.location_code = pa_faaudit[k].location_code 
						LET pr_faaudit.faresp_code = pa_faaudit[k].faresp_code 
						LET pr_faaudit.facat_code = pa_faaudit[k].facat_code 
					END IF 
				END FOR 
				CALL add_fn(p_cmpy) 
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
					IF (pa_faaudit[idx].asset_code = 
					pa_faaudit[j].asset_code) AND 
					(pa_faaudit[idx].add_on_code = 
					pa_faaudit[j].add_on_code) THEN 
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

END FUNCTION { batadd } 

FUNCTION add_fn(p_cmpy) 
	DEFINE p_cmpy LIKE company.cmpy_code 

	LET pr_faaudit.batch_line_num = pb_faaudit[idx].batch_line_num 
	LET pr_faaudit.asset_code = pb_faaudit[idx].asset_code 
	LET pr_faaudit.book_code = pb_faaudit[idx].book_code 
	LET pr_faaudit.add_on_code = pb_faaudit[idx].add_on_code 
	IF pr_faaudit.desc_text IS NULL THEN 
		LET pr_faaudit.desc_text = pr_famast.desc_text 
	END IF 


	IF pr_faaudit.faresp_code IS NULL THEN 
		LET pr_faaudit.faresp_code = pr_famast.faresp_code 
	END IF 

	LET pr_faaudit.sale_amt = 0 
	CALL add_details(p_cmpy) 
	CURRENT WINDOW IS wf159 
END FUNCTION 



FUNCTION add_details(p_cmpy) 
	DEFINE 
	p_cmpy LIKE company.cmpy_code, 
	field_no SMALLINT, 
	tmp_depr LIKE faaudit.depr_amt 

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

	DISPLAY pr_faaudit.batch_line_num, 
	pr_faaudit.asset_code, 
	pr_faaudit.add_on_code, 
	pr_famast.desc_text, 
	pr_faaudit.book_code, 
	pr_fabook.book_text, 
	pr_faaudit.desc_text 
	TO faaudit.batch_line_num, 
	faaudit.asset_code, 
	faaudit.add_on_code, 
	famast.desc_text, 
	faaudit.book_code, 
	fabook.book_text, 
	faaudit.desc_text 


	INPUT pr_faaudit.auth_code, 
	pr_faaudit.asset_amt, 
	pr_faaudit.depr_amt, 
	pr_faaudit.salvage_amt, 
	pr_faaudit.rem_life_num, 
	pr_faaudit.location_code, 
	pr_faaudit.faresp_code, 
	pr_faaudit.facat_code, 
	pr_faaudit.desc_text 
	WITHOUT DEFAULTS 
	FROM faaudit.auth_code, 
	faaudit.asset_amt, 
	faaudit.depr_amt, 
	faaudit.salvage_amt, 
	faaudit.rem_life_num, 
	faaudit.location_code, 
	faaudit.faresp_code, 
	faaudit.facat_code, 
	faaudit.desc_text 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","fafinadd","inp-pr_faaudit-2") -- alch kd-504 
		
		ON ACTION "NOTES" infield (desc_text) --ON KEY (control-n) 
				LET pr_faaudit.desc_text = sys_noter(p_cmpy,pr_faaudit.desc_text) 
				DISPLAY pr_faaudit.desc_text TO 
				faaudit.desc_text 

				NEXT FIELD faaudit.desc_text 
 
		ON KEY (control-b) 
			CASE 
			#WHEN infield (add_on_code)
			#LET pr_faaudit.add_on_code = show_add_on(p_cmpy,
			#pr_faaudit.add_on_code)
			#DISPLAY pr_faaudit.add_on_code
			#TO faaudit.add_on_code
			#
			#NEXT FIELD faaudit.add_on_code
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
				WHEN infield (faresp_code) 
					LET pr_faaudit.faresp_code = lookup_resp(p_cmpy) 
					DISPLAY pr_faaudit.faresp_code 
					TO faaudit.faresp_code 
					NEXT FIELD faaudit.faresp_code 
			END CASE 
		AFTER FIELD auth_code 
			IF int_flag OR quit_flag THEN 
				LET nxtfld = 1 
				LET int_flag = 0 
				LET quit_flag = 0 
				CLOSE WINDOW wf101 
			ELSE 
				IF verify_auth(p_cmpy,pr_faaudit.auth_code) = 1 THEN 
					NEXT FIELD faaudit.auth_code 
				ELSE 
					IF asset_change_flag = 1 AND 
					curs_close_flag = 1 THEN 
						DISPLAY pr_faaudit.asset_amt, 
						pr_faaudit.depr_amt, 
						pr_faaudit.salvage_amt, 
						pr_faaudit.rem_life_num, 
						pr_faaudit.location_code, 
						pr_falocation.location_text, 
						pr_faaudit.faresp_code, 
						pr_faresp.faresp_text, 
						pr_faaudit.facat_code, 
						pr_facat.facat_text, 
						pr_faaudit.desc_text 
						TO faaudit.asset_amt, 
						faaudit.depr_amt, 
						faaudit.salvage_amt, 
						faaudit.rem_life_num, 
						faaudit.location_code, 
						falocation.location_text, 
						faaudit.faresp_code, 
						faresp.faresp_text, 
						faaudit.facat_code, 
						facat.facat_text, 
						faaudit.desc_text 
					END IF 
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
				DISPLAY pr_faaudit.asset_amt 
				TO faaudit.asset_amt 
			ELSE 
				IF pr_faaudit.asset_amt < 0 THEN 
					ERROR " Amount must be positive " 
					NEXT FIELD faaudit.asset_amt 
				ELSE 
					IF pr_faaudit.depr_amt IS NULL THEN 
						LET pr_faaudit.depr_amt = 0 
						DISPLAY pr_faaudit.depr_amt TO 
						faaudit.depr_amt 
					END IF 
				END IF 
			END IF 
		AFTER FIELD depr_amt 
			IF pr_faaudit.depr_amt IS NULL THEN 
				LET pr_faaudit.depr_amt = 0 
				DISPLAY pr_faaudit.depr_amt TO faaudit.depr_amt 
			ELSE 
				IF pr_faaudit.depr_amt < 0 THEN 
					ERROR " Amount must be positive " 
					NEXT FIELD faaudit.depr_amt 
				END IF 
			END IF 
			IF pr_faaudit.depr_amt > pr_fastatus.net_book_val_amt THEN 
				ERROR "Depreciation cannot exceed ",pr_fastatus.net_book_val_amt, 
				" (NBV must be >= 0)" 
				SLEEP 2 
				NEXT FIELD faaudit.depr_amt 
			END IF 
			IF pr_faaudit.salvage_amt IS NULL THEN 
				LET pr_faaudit.salvage_amt = 0 
				DISPLAY pr_faaudit.salvage_amt TO faaudit.salvage_amt 
			END IF 
			# check that what they are entering matches what's on the asset master
			IF pr_famast.orig_cost_amt IS NULL THEN 
				LET pr_famast.orig_cost_amt = 0 
			END IF 
			IF pr_faaudit.asset_amt + pr_faaudit.depr_amt != 
			pr_famast.orig_cost_amt THEN 
				ERROR "Total asset value must equal : ",pr_famast.orig_cost_amt, 
				" (F11)" 
				SLEEP 2 
				NEXT FIELD faaudit.asset_amt 
			END IF 
			LET field_no = 10 
		AFTER FIELD salvage_amt 
			IF pr_faaudit.salvage_amt IS NULL THEN 
				LET pr_faaudit.salvage_amt = 0 
				DISPLAY pr_faaudit.salvage_amt TO faaudit.salvage_amt 
			END IF 
			IF pr_faaudit.salvage_amt < 0 THEN 
				ERROR "Salvage amount cannot be less than 0" 
				SLEEP 2 
				NEXT FIELD faaudit.salvage_amt 
			END IF 
			LET pr_faaudit.sale_amt = 0 
			DISPLAY pr_faaudit.sale_amt TO faaudit.sale_amt 
			IF field_no > 20 THEN 
				LET field_no = 20 
				NEXT FIELD faaudit.depr_amt 
			ELSE 
				LET field_no = 20 
				NEXT FIELD faaudit.rem_life_num 
			END IF 
		AFTER FIELD rem_life_num 
			IF verify_life(pr_faaudit.rem_life_num) = 1 THEN 
				NEXT FIELD faaudit.rem_life_num 
			END IF 
			IF (idx > 1) THEN 
				IF (pr_faaudit.asset_code = pa_faaudit[idx-1].asset_code) AND 
				(pr_faaudit.add_on_code = pa_faaudit[idx-1].add_on_code) AND 
				field_no = 20 THEN 
					NEXT FIELD faaudit.desc_text 
				END IF 
			END IF 
			IF non_entry_flag = 1 AND field_no = 20 THEN 
				NEXT FIELD faaudit.desc_text 
			END IF 
			LET field_no = 30 
		AFTER FIELD location_code 
			IF verify_loc(p_cmpy, pr_faaudit.location_code) = 1 THEN 
				NEXT FIELD faaudit.location_code 
			ELSE 
				DISPLAY BY NAME pr_falocation.location_text 
			END IF 
			LET field_no = 40 
		AFTER FIELD faresp_code 
			IF verify_resp(p_cmpy, pr_faaudit.faresp_code) = 1 THEN 
				NEXT FIELD faaudit.faresp_code 
			ELSE 
				DISPLAY BY NAME pr_faresp.faresp_text 
			END IF 
			LET field_no = 50 
		BEFORE FIELD facat_code 
			IF ((curs_close_flag = 1 AND non_entry_flag = 1) OR 
			(non_entry_flag = 1)) AND field_no < 100 THEN 
				NEXT FIELD faaudit.desc_text 
			ELSE 
				IF field_no =100 THEN 
					NEXT FIELD faaudit.rem_life_num 
				END IF 
			END IF 
		AFTER FIELD facat_code 
			IF verify_cat(p_cmpy, pr_faaudit.facat_code) = 1 THEN 
				NEXT FIELD faaudit.facat_code 
			ELSE 
				DISPLAY BY NAME pr_facat.facat_text 
			END IF 
			LET field_no = 60 
		BEFORE FIELD desc_text 
			# IF just account AND a last desc use that description
			IF pa_faaudit[idx].desc_text = pr_famast.desc_text 
			AND last_desc IS NOT NULL THEN 
				LET pa_faaudit[idx].desc_text = last_desc 
				DISPLAY pr_faaudit.desc_text TO faaudit.desc_text 
			END IF 
		AFTER FIELD desc_text 
			IF pr_famast.desc_text != pr_faaudit.desc_text THEN 
				LET last_desc = pr_faaudit.desc_text 
			END IF 
			LET field_no = 100 
		AFTER INPUT 
			IF NOT int_flag THEN 
				IF pr_faaudit.asset_amt IS NULL THEN 
					LET pr_faaudit.asset_amt = 0 
				ELSE 
					IF pr_faaudit.asset_amt < 0 THEN 
						ERROR " Asset amount must be positive " 
						NEXT FIELD faaudit.asset_amt 
					ELSE 
						IF pr_faaudit.depr_amt IS NULL THEN 
							LET pr_faaudit.depr_amt = 0 
							DISPLAY pr_faaudit.depr_amt TO faaudit.depr_amt 
						END IF 
					END IF 
				END IF 
				IF pr_faaudit.depr_amt IS NULL THEN 
					LET pr_faaudit.depr_amt = 0 
				ELSE 
					IF pr_faaudit.depr_amt < 0 THEN 
						ERROR " Amount must be positive " 
						NEXT FIELD faaudit.depr_amt 
					END IF 
				END IF 
				IF pr_faaudit.salvage_amt IS NULL THEN 
					LET pr_faaudit.salvage_amt = 0 
				END IF 
				# check that what they are entering matches what's on the asset master
				SELECT * 
				INTO pr_famast.* 
				FROM famast 
				WHERE cmpy_code = p_cmpy 
				AND asset_code = pr_faaudit.asset_code 
				AND add_on_code = pr_faaudit.add_on_code 
				IF pr_famast.orig_cost_amt IS NULL THEN 
					LET pr_famast.orig_cost_amt = 0 
				END IF 
				IF pr_faaudit.asset_amt + pr_faaudit.depr_amt != 
				pr_famast.orig_cost_amt THEN 
					ERROR "Total asset value must equal : ",pr_famast.orig_cost_amt, " (F11)" 
					SLEEP 2 
					NEXT FIELD faaudit.asset_amt 
				END IF 
				IF pr_faaudit.salvage_amt IS NULL THEN 
					LET pr_faaudit.salvage_amt = 0 
				END IF 
				IF pr_faaudit.salvage_amt < 0 THEN 
					ERROR "Salvage amount cannot be less than 0" 
					SLEEP 2 
					NEXT FIELD faaudit.salvage_amt 
				END IF 
				IF verify_life(pr_faaudit.rem_life_num) = 1 THEN 
					NEXT FIELD faaudit.rem_life_num 
				END IF 
				IF verify_loc(p_cmpy, pr_faaudit.location_code) = 1 THEN 
					NEXT FIELD faaudit.location_code 
				END IF 
				IF verify_resp(p_cmpy, pr_faaudit.faresp_code) = 1 THEN 
					NEXT FIELD faaudit.faresp_code 
				END IF 
				IF verify_cat(p_cmpy, pr_faaudit.facat_code) = 1 THEN 
					NEXT FIELD faaudit.facat_code 
				END IF 
			ELSE {del} 
				IF pr_faaudit.salvage_amt < 0 THEN 
					LET pr_faaudit.salvage_amt = 0 
				END IF 
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

