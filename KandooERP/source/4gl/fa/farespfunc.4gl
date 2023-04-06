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

# respfunc.4gl used FOR lookups of responsibility codes AND addition of new ones

FUNCTION lookup_resp(p_cmpy) 
	DEFINE 
	pa_faresp array[60] OF RECORD 
		faresp_code LIKE faresp.faresp_code, 
		faresp_text LIKE faresp.faresp_text 
	END RECORD, 
	p_cmpy LIKE company.cmpy_code, 
	idx1, cnt1, scrn1 SMALLINT, 
	ans, try_another CHAR(1), 
	ret_faresp_code LIKE faresp.faresp_code, 
	where_part, query_text CHAR(400) 

	OPEN WINDOW wf113 with FORM "F113" -- alch kd-757 
	CALL  winDecoration_f("F113") -- alch kd-757 

	LABEL another_go1: 
	LET try_another = "N" 
	MESSAGE "Enter criteria press ESC" attribute(yellow) 

	CONSTRUCT where_part ON faresp.faresp_code, 
	faresp.faresp_text 
	FROM sr_faresp[1].* 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","farespfunc","const-farest-1") -- alch kd-504 
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
	END CONSTRUCT 
	LET query_text = 
	" SELECT faresp_code, faresp_text ", 
	" FROM faresp ", 
	" WHERE cmpy_code = \"", p_cmpy,"\" AND ", 
	where_part clipped, 
	" ORDER BY faresp_code " 

	IF (int_flag != 0 OR 
	quit_flag != 0) 
	THEN 
		LET int_flag = 0 
		LET quit_flag = 0 
		LET ret_faresp_code = " " 
	ELSE 
		PREPARE choice1 FROM query_text 
		DECLARE selcurs1 CURSOR FOR choice1 

		LET idx1 = 1 
		FOREACH selcurs1 INTO pa_faresp[idx1].* 
			LET idx1 = idx1 + 1 
			IF idx1 > 50 THEN 
				MESSAGE "Only first 50 records selected" 
				EXIT FOREACH 
			END IF 
		END FOREACH 
		LET idx1 = idx1 - 1 

		IF idx1 = 0 THEN 
			--         prompt
			--            "No responsibility satisfied your selection criteria - Add (y/n)"
			--         FOR CHAR ans
			LET ans = promptYN("","No responsibility satisfied your selection criteria - Add (y/n)","Y") -- albo 
			LET ans = downshift(ans) 
			IF ans <> "n" THEN 
				CALL run_prog("F35","","","","") 
				LET try_another = "Y" 
			END IF 
		ELSE 
			LET cnt1 = idx1 
			CALL set_count(idx1) 
			MESSAGE "Cursor TO responsibility - press ESC, F9 reselect, F10 TO add" 
			attribute(yellow) 
			INPUT ARRAY pa_faresp WITHOUT DEFAULTS FROM sr_faresp.* 
				BEFORE INPUT 
					CALL publish_toolbar("kandoo","farespfunc","inp_arr-pa_faresp-5") -- alch kd-504 
				ON KEY (F10) 
					CALL run_prog("F35","","","","") 
				ON KEY (F9) 
					LET try_another = "Y" 
					EXIT INPUT 

				BEFORE ROW 
					LET idx1 = arr_curr() 
					LET scrn1 = scr_line() 
					LET ret_faresp_code = pa_faresp[idx1].faresp_code 

				BEFORE FIELD faresp_text 
					NEXT FIELD faresp_code 

				AFTER INPUT 
					IF (int_flag != 0 OR 
					quit_flag != 0) THEN 
						LET int_flag = 0 
						LET quit_flag = 0 
						LET ret_faresp_code = " " 
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
	CLOSE WINDOW wf113 
	LET int_flag = 0 
	LET quit_flag = 0 
	RETURN ret_faresp_code 
END FUNCTION 

