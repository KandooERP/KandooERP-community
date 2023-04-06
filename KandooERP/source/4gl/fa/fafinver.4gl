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

	Source code beautified by beautify.pl on 2020-01-03 10:37:03	$Id: $
}


GLOBALS "../common/glob_GLOBALS.4gl" 

# Module   :   fafinver.4gl
# Purpose   :   verifies all data entered in a financial transaction

GLOBALS 
	DEFINE 
	pr_famast RECORD LIKE famast.*, 
	pr_faaudit RECORD LIKE faaudit.*, 
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
	pr_faresp RECORD LIKE faresp.*, 
	pr_facat RECORD LIKE facat.*, 
	idx, arr_size SMALLINT 
END GLOBALS 

FUNCTION verify_book( cmpy1, book ) 
	DEFINE book LIKE faaudit.book_code, 
	cmpy1 LIKE faresp.cmpy_code 

	SELECT * 
	INTO pr_fabook.* 
	FROM fabook 
	WHERE cmpy_code = cmpy1 
	AND book_code = book 

	IF status = notfound 
	THEN 
		ERROR " Book ID NOT found, try window " 
		RETURN 1 
	END IF 
	RETURN 0 

END FUNCTION 

FUNCTION verify_asset_code(cmpy1, 
	asseter, 
	addeter ) 
	DEFINE asseter LIKE famast.asset_code, 
	cmpy1 LIKE famast.cmpy_code, 
	addeter LIKE famast.add_on_code 

	SELECT * 
	INTO pr_famast.* 
	FROM famast 
	WHERE cmpy_code = cmpy1 
	AND asset_code = asseter 
	AND add_on_code = addeter 

	IF status = notfound 
	THEN 
		ERROR " Asset Code NOT found, try window " 
		RETURN 1 
	END IF 

	RETURN 0 
END FUNCTION 

FUNCTION verify_auth( cmpy1, auth ) 
	DEFINE auth LIKE faaudit.auth_code, 
	cmpy1 LIKE faresp.cmpy_code, 
	pr_faauth RECORD LIKE faauth.* 

	SELECT * 
	INTO pr_faauth.* 
	FROM faauth 
	WHERE cmpy_code = cmpy1 
	AND auth_code = auth 

	IF status = notfound 
	THEN 
		ERROR " Authority ID NOT found, try again " 
		RETURN 1 
	END IF 
	RETURN 0 

END FUNCTION 

FUNCTION verify_life( lifer ) 
	DEFINE lifer LIKE faaudit.rem_life_num 

	IF lifer IS NULL THEN 
		ERROR "Remaining Life cannot be NULL" 
		RETURN 1 
	END IF 

	IF lifer < 0 
	THEN 
		ERROR " Remaining Life in periods cannot be negative " 
		RETURN 1 
	END IF 

	RETURN 0 

END FUNCTION 

FUNCTION verify_loc( cmpy1, locer ) 
	DEFINE locer LIKE faaudit.location_code, 
	cmpy1 LIKE faresp.cmpy_code 

	SELECT * 
	INTO pr_falocation.* 
	FROM falocation 
	WHERE cmpy_code = cmpy1 
	AND location_code = locer 

	IF status = notfound 
	THEN 
		ERROR " Location Code NOT found, try window " 
		RETURN 1 
	END IF 
	RETURN 0 

END FUNCTION 

FUNCTION verify_resp( cmpy1, resper ) 
	DEFINE resper LIKE faaudit.faresp_code, 
	cmpy1 LIKE faresp.cmpy_code 

	SELECT * 
	INTO pr_faresp.* 
	FROM faresp 
	WHERE cmpy_code = cmpy1 
	AND faresp_code = resper 

	IF status = notfound 
	THEN 
		ERROR " Responsibility Code NOT found, try window " 
		RETURN 1 
	END IF 
	RETURN 0 

END FUNCTION 

FUNCTION verify_cat( cmpy1, cater ) 
	DEFINE cater LIKE faaudit.facat_code, 
	cmpy1 LIKE faresp.cmpy_code 

	SELECT * 
	INTO pr_facat.* 
	FROM facat 
	WHERE cmpy_code = cmpy1 
	AND facat_code = cater 

	IF status = notfound 
	THEN 
		ERROR " Category Code NOT found, try window " 
		RETURN 1 
	END IF 
	RETURN 0 

END FUNCTION 

FUNCTION set_faaudit() 

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
	RETURN 

END FUNCTION 

FUNCTION renum () 
	DEFINE 
	pa_curr, 
	pa_total, 
	sc_curr, 
	sc_total, 
	k SMALLINT 
	LET pa_curr = arr_curr() 
	LET pa_total = arr_count() 
	LET sc_curr = scr_line() 
	LET sc_total = 10 
	FOR k = pa_curr TO pa_total 
		LET pa_faaudit[k].batch_line_num = k 
		LET pb_faaudit[k].batch_line_num = k 
		IF sc_curr <= sc_total THEN 
			DISPLAY pb_faaudit[k].* TO sr_faaudit[sc_curr].* 

			LET sc_curr = sc_curr + 1 
		END IF 
	END FOR 
END FUNCTION {renum} 

FUNCTION lookup_stat_book(p_cmpy) 
	DEFINE 
	pa_fabook array[60] OF RECORD 
		book_code LIKE fabook.book_code, 
		book_text LIKE fabook.book_text 
	END RECORD, 
	p_cmpy LIKE company.cmpy_code, 
	idx1, cnt1, scrn1 SMALLINT, 
	ans, try_another CHAR(1), 
	ret_book_code LIKE fabook.book_code, 
	where_part, query_text CHAR(400) 

	OPEN WINDOW wf110 with FORM "F110" -- alch kd-757 
	CALL  winDecoration_f("F110") -- alch kd-757 

	LABEL another_go1: 
	LET try_another = "N" 
	MESSAGE "Enter criteria press ESC" attribute(yellow) 

	CONSTRUCT where_part ON fabook.book_code, 
	fabook.book_text 
	FROM sr_fabook[1].* 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","fafinver","const-fabook-1") -- alch kd-504 
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
	END CONSTRUCT 
	LET query_text = 
	" SELECT book_code, book_text ", 
	" FROM fabook ", 
	" WHERE cmpy_code = \"", p_cmpy,"\" AND ", 
	" exists (SELECT * FROM fastatus ", 
	" WHERE cmpy_code = fabook.cmpy_code AND ", 
	" book_code = fabook.book_code) AND ", 
	where_part clipped, 
	" ORDER BY book_code " 

	IF (int_flag != 0 OR 
	quit_flag != 0) 
	THEN 
		LET int_flag = 0 
		LET quit_flag = 0 
		LET ret_book_code = " " 
	ELSE 
		PREPARE choice1 FROM query_text 
		DECLARE selcurs1 CURSOR FOR choice1 

		LET idx1 = 1 
		FOREACH selcurs1 INTO pa_fabook[idx1].* 
			LET idx1 = idx1 + 1 
			IF idx1 > 50 THEN 
				MESSAGE "Only first 50 records selected" 
				EXIT FOREACH 
			END IF 
		END FOREACH 
		LET idx1 = idx1 - 1 

		IF idx1 = 0 THEN 
			--prompt "No books satisfied your selection criteria - Add (Y/N)"  -- albo
			--FOR CHAR ans
			LET ans = promptYN("","No books satisfied your selection criteria - Add (Y/N)","Y") -- albo 
			LET ans = downshift(ans) 
			IF ans <> "n" THEN 
				CALL run_prog("F31","","","","") 
			END IF 
		ELSE 
			LET cnt1 = idx1 
			CALL set_count(idx1) 
			MESSAGE "Cursor TO book - press ESC, F9 reselect, F10 TO add" 
			attribute(yellow) 
			INPUT ARRAY pa_fabook WITHOUT DEFAULTS FROM sr_fabook.* 
				BEFORE INPUT 
					CALL publish_toolbar("kandoo","fafinver","inp_arr-pa_fabook-2") -- alch kd-504 
				ON KEY (F10) 
					CALL run_prog("F31","","","","") 
				ON KEY (F9) 
					LET try_another = "Y" 
					EXIT INPUT 
				BEFORE ROW 
					LET idx1 = arr_curr() 
					LET scrn1 = scr_line() 
					LET ret_book_code = pa_fabook[idx1].book_code 
				BEFORE FIELD book_text 
					NEXT FIELD book_code 
				AFTER INPUT 
					LET arr_size = arr_count() 
					IF (int_flag != 0 OR 
					quit_flag != 0) THEN 
						LET int_flag = 0 
						LET quit_flag = 0 
						LET ret_book_code = " " 
					END IF 
				ON KEY (control-w) 
					CALL kandoohelp("") 
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
			END INPUT 
		END IF 
	END IF 

	IF try_another = "Y" THEN 
		CLEAR FORM 
		GOTO another_go1 
	END IF 

	LET idx1 = arr_curr() 
	CLOSE WINDOW wf110 
	LET int_flag = 0 
	LET quit_flag = 0 
	RETURN ret_book_code 
END FUNCTION 

