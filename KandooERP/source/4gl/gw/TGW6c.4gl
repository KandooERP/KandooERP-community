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

	Source code beautified by beautify.pl on 2020-01-03 10:10:06	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "T_GW_GLOBALS.4gl" 
GLOBALS "TGW6_GLOBALS.4gl" 

# Purpose - This file contains the functions used TO
#           SELECT AND scroll through records AND SELECT one (for
#           updating, display-full SCREEN OR deleting) in the rpthead
#           table.  All these functions must be kept in the
#           same file because they use the same module variables,
#           i.e. the module ARRAY AND the CURSOR.

--- Module Variables Definitions



DEFINE ma_rpt array[100] OF RECORD 

	rpt_id LIKE rpthead.rpt_id, 
	rpt_text LIKE rpthead.rpt_text 

END RECORD 

--------------------------------------------------------------------------

FUNCTION query_rpt(pr_rptgrp_id) 

	DEFINE pr_rptgrp_id LIKE rpthead_group.rptgrp_id 
	DEFINE lr_dummy RECORD LIKE rpthead_group.* 
	DEFINE lv_ca_type_id CHAR(1) 
	DEFINE lv_select_string CHAR(500) 

	# WHENEVER ERROR CONTINUE

	--- Set up the form
	# CLEAR FORM


	--- Set up the SELECT statment

	# CLEAR FORM

	LET lv_select_string = 

	"SELECT UNIQUE rpthead.rpt_id, ", 
	" rpthead.rpt_text ", 
	" FROM rpthead_struct, rpthead ", 
	" WHERE rpthead_struct.cmpy_code = '", gv_cmpy_code, "' ", 
	" AND rpthead_struct.rptgrp_id = '", pr_rptgrp_id, "' ", 
	" AND rpthead.cmpy_code = rpthead_struct.cmpy_code ", 
	" AND rpthead.rpt_id = rpthead_struct.rpt_id " 


	PREPARE s_2 FROM lv_select_string 

	--- Now DECLARE a CURSOR FOR the relevant info in the rptgrpal govt region table

	DECLARE brrptgrp_curs CURSOR FOR s_2 

	IF error_trap(status) THEN 

		RETURN false 
	END IF 

	RETURN true 

END FUNCTION 
--- query_rpthead_group()

------------------------------------------------------------------------------
FUNCTION load_array_rpt() 

	DEFINE lv_pa_totsize SMALLINT 
	DEFINE pv_records_count INTEGER 

	LET lv_pa_totsize = 100 

	FOR pv_records_count = 1 TO lv_pa_totsize 

		INITIALIZE ma_rpt[pv_records_count].* TO NULL 
	END FOR 

	LET pv_records_count = 1 

	FOREACH brrptgrp_curs INTO ma_rpt[pv_records_count].* 

		IF int_flag OR quit_flag THEN 
			EXIT FOREACH 
		END IF 

		LET pv_records_count = pv_records_count + 1 

		IF pv_records_count > lv_pa_totsize THEN 

			MESSAGE "Only the first 100 records selected, " 
			attribute(YELLOW) 
			DISPLAY "Please limit your selection" at 2,1 
			attribute(YELLOW) 

			EXIT FOREACH 
		END IF 

	END FOREACH 

	LET pv_records_count = pv_records_count - 1 

	IF interrupted() THEN 
	END IF 

	RETURN pv_records_count 

END FUNCTION 
--- query_rpthead_group()

--------------------------------------------------------------------------

FUNCTION scroll_rpt(pv_records_count, pr_rpthead_group) 

	DEFINE lv_scrn SMALLINT 
	DEFINE lv_cnt SMALLINT 
	DEFINE lv_forcnt SMALLINT 
	DEFINE lv_idx SMALLINT 
	DEFINE lv_arr_cnt SMALLINT 
	DEFINE lv_flag CHAR(3) 
	DEFINE lv_copy LIKE rpthead_group.rptgrp_id 
	DEFINE lv_last_key INTEGER 
	DEFINE lv_error_flag SMALLINT 
	DEFINE lv_delete_success_flg SMALLINT 
	DEFINE pv_records_count INTEGER 
	DEFINE lv_found_flag INTEGER 
	DEFINE pr_rpthead_group RECORD LIKE rpthead_group.* 
	DEFINE lv_pa_totsize SMALLINT 
	DEFINE lv_counter SMALLINT 
	DEFINE lv_mesgno CHAR(1) 

	DEFINE lr_copy RECORD 

		rpt_id LIKE rpthead.rpt_id, 
		rpt_text LIKE rpthead.rpt_text 

	END RECORD 

	LET lv_pa_totsize = 100 
	LET lv_flag = NULL 
	LET lv_forcnt = "0" 

	CREATE temp TABLE tmp_rpthead 
	( 
	cmpy_code CHAR(2), 
	rptgrp_id CHAR(10), 
	rpt_id CHAR(10) 
	) 

	OPEN WINDOW w1_rpt with FORM "TG567" 
	CALL windecoration_t("TG567") -- albo kd-768 

	CALL set_options() 

	OPTIONS DELETE KEY f2, 
	INSERT KEY f1 

	DISPLAY " INPUT" at 4, 9 
	attribute(WHITE) 

	MESSAGE "[CTRL-B]=brwse,[ESC]=accpt,[F2]=del,[F1]=ins" 
	attribute(YELLOW) 

	DISPLAY pv_records_count, " Records found" at 2,1 
	attribute (RED) 

	DISPLAY pv_records_count, " Records found" at 2,1 
	attribute (RED) 

	CALL set_count(pv_records_count) 

	INPUT ARRAY ma_rpt WITHOUT DEFAULTS FROM sa_browse_rec.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","TGW6c","input-arr-ma_rpt-1") -- albo kd-515 

		BEFORE ROW ---------------------- section ---------------------- 

			LET lv_idx = arr_curr() 
			LET lv_scrn = scr_line() 
			LET pv_records_count = arr_count() 

			DISPLAY ma_rpt[lv_idx].* TO sa_browse_rec[lv_scrn].* 		attribute(RED, reverse) 

		AFTER ROW ---------------------- section ---------------------- 

			LET lv_idx = arr_curr() 
			LET lv_scrn = scr_line() 
			LET pv_records_count = arr_count() 

			DISPLAY ma_rpt[lv_idx].* TO sa_browse_rec[lv_scrn].* 


		ON ACTION "WEB-HELP" -- albo kd-378 
			CALL onlinehelp(getmoduleid(),null) 

		AFTER FIELD rpt_id ---------- AFTER FIELD section --------- 

			LET lv_idx = arr_curr() 
			LET lv_scrn = scr_line() 

			#   LET lv_cnt = "0"
			#   LET lv_found_flag = FALSE
			LET lv_arr_cnt = lv_idx 

			FOR lv_idx = 1 TO arr_count() 

				IF lv_idx != lv_arr_cnt 
				AND ma_rpt[lv_idx].rpt_id IS NOT NULL THEN 

					IF ma_rpt[lv_idx].rpt_id = ma_rpt[lv_arr_cnt].rpt_id THEN 

						ERROR "This REPORT has already been selected" 
						attribute(RED) 

						NEXT FIELD rpt_id 
					END IF 
				END IF 
			END FOR 

			LET lv_idx = lv_arr_cnt 

			IF ma_rpt[lv_idx].rpt_id IS NOT NULL THEN 

				CALL valid_rpt(ma_rpt[lv_idx].*) 
				RETURNING ma_rpt[lv_idx].*, lv_found_flag 

				IF lv_found_flag THEN 

					LET lv_found_flag = false 
					NEXT FIELD rpt_id 
				END IF 
			END IF 

			DISPLAY ma_rpt[lv_idx].* TO sa_browse_rec[lv_scrn].* 
			attribute(RED, reverse) 

			LET lv_last_key = fgl_lastkey() 

			LET pv_records_count = arr_count() 

			IF (lv_idx >= pv_records_count AND lv_last_key = FGL_KEYVAL("DOWN")) 
			OR (lv_idx >= pv_records_count - 5 --- (= screen ARRAY size-1) 
			AND lv_last_key= fgl_keyval("NEXTPAGE")) THEN 

				ERROR " There are no more rows in the direction you are going " 
				attribute (RED) 

				NEXT FIELD previous 
			END IF 


		BEFORE FIELD rpt_text 
			NEXT FIELD NEXT 


		--ON KEY (CONTROL-B) ---------- browse KEY ---------- 
		--	LET lv_idx = arr_curr() 
		--	LET lv_scrn = scr_line() 


				ON ACTION "LOOKUP" infield(rpt_id) 

					DELETE FROM tmp_rpthead 

					FOR lv_cnt = 1 TO arr_count() 
						IF ma_rpt[lv_cnt].rpt_id IS NULL THEN 
							LET ma_rpt[lv_cnt].rpt_id = "###" 
						END IF 
						INSERT INTO tmp_rpthead 
						VALUES 
						(gv_cmpy_code,pr_rpthead_group.rptgrp_id,ma_rpt[lv_cnt].rpt_id) 
					END FOR 

					LET lr_copy.* = ma_rpt[lv_idx].* 

					CALL pick_rpt(pr_rpthead_group.rptgrp_id) 
					RETURNING ma_rpt[lv_idx].*, lv_found_flag 

					CURRENT WINDOW IS w1_rpt 

					IF lv_found_flag THEN 

						LET ma_rpt[lv_idx].* = lr_copy.* 

					END IF 

					CALL set_count(pv_records_count) 

					DISPLAY ma_rpt[lv_idx].* TO sa_browse_rec[lv_scrn].* 
					attribute(RED, reverse) 

					CALL set_count(pv_records_count) 



		ON KEY (DELETE) --------- DELETE KEY ---------- 

			LET lv_idx = arr_curr() 
			LET lv_scrn = scr_line() 

			IF pv_records_count <= 1 THEN 

				INITIALIZE ma_rpt[1].* TO NULL 
				DISPLAY ma_rpt[1].* TO sa_browse_rec[1].* 

			ELSE 

				LET pv_records_count = arr_count() 

				FOR lv_counter = arr_curr() TO (pv_records_count -1) 

					LET ma_rpt[lv_counter].* = ma_rpt[lv_counter+1].* 
				END FOR 

				INITIALIZE ma_rpt[pv_records_count].* TO NULL 

				LET pv_records_count = pv_records_count - 1 

				IF lv_idx > pv_records_count THEN 

					LET lv_idx = lv_idx -1 
					LET lv_scrn = lv_scrn -1 
				END IF 

				IF lv_idx = 0 THEN 
					EXIT INPUT 
				END IF 

				DISPLAY pv_records_count, " Records found" at 2,1 
				attribute (RED) 

				CALL set_count(pv_records_count) 

				LET pv_records_count = arr_count() 

				FOR lv_counter = scr_line() TO 6 --- screen ARRAY size 

					DISPLAY ma_rpt[lv_idx + lv_counter - lv_scrn].* 
					TO sa_browse_rec[lv_counter].* 

				END FOR 

				DISPLAY ma_rpt[lv_idx].* TO sa_browse_rec[lv_scrn].* 			attribute(RED, reverse) 
			END IF 


			NEXT FIELD previous 





		BEFORE INSERT 
			INITIALIZE ma_rpt[lv_idx].* TO NULL 

			DISPLAY ma_rpt[lv_idx].* TO sa_browse_rec[lv_scrn].* 
			attribute(RED, reverse) 


		AFTER INPUT 

			CALL set_options() 

			IF interrupted() THEN 
				LET lv_flag = "ESC" 
				EXIT INPUT 
			END IF 


			DELETE FROM rpthead_struct 
			WHERE rpthead_struct.rptgrp_id = pr_rpthead_group.rptgrp_id 
			AND rpthead_struct.cmpy_code = gv_cmpy_code 


			FOR lv_idx = 1 TO arr_count() 

				IF ma_rpt[lv_idx].rpt_id IS NOT NULL THEN 

					LET lv_cnt = "0" 

					SELECT count(*) 
					INTO lv_cnt 
					FROM rpthead_struct 
					WHERE rpthead_struct.cmpy_code = gv_cmpy_code 
					AND rpthead_struct.rptgrp_id = pr_rpthead_group.rptgrp_id 
					AND rpthead_struct.rpt_id = ma_rpt[lv_idx].rpt_id 

					IF lv_cnt <= "0" THEN 

						INSERT INTO rpthead_struct 
						VALUES (gv_cmpy_code, pr_rpthead_group.rptgrp_id, ma_rpt[lv_idx].rpt_id ) 
					END IF 


				END IF 

			END FOR 

			EXIT INPUT 


	END INPUT 

	CLOSE WINDOW w1_rpt 

	IF fgl_find_table("tmp_rpthead") THEN
		DROP TABLE tmp_rpthead 
	END IF	 

	IF lv_flag IS NULL THEN 
		RETURN true 
	ELSE 
		RETURN false 
	END IF 

END FUNCTION 


------------------------------------------------------------------------------

FUNCTION valid_rpt(pr_rpt) 

	DEFINE pr_rpt RECORD 

		rpt_id LIKE rpthead.rpt_id, 
		rpt_text LIKE rpthead.rpt_text 

	END RECORD 

	SELECT unique rpthead.rpt_id, rpthead.rpt_text 
	INTO pr_rpt.rpt_id, 
	pr_rpt.rpt_text 
	FROM rpthead, rptcolgrp 
	WHERE rpthead.rpt_id = pr_rpt.rpt_id 
	AND rpthead.cmpy_code = gv_cmpy_code 
	AND rptcolgrp.colrptg_type in ("AA", "AD") 
	AND rpthead.col_code = rptcolgrp.col_code 
	AND rpthead.cmpy_code = rptcolgrp.cmpy_code 

	IF status = notfound THEN 

		ERROR "This REPORT does NOT exist in the database" 
		attribute(RED) 

		RETURN pr_rpt.rpt_id, 
		pr_rpt.rpt_text, 
		true 
	ELSE 

		RETURN pr_rpt.rpt_id, 
		pr_rpt.rpt_text, 
		false 

	END IF 

END FUNCTION 

------------------------------------------------------------------------------

FUNCTION init_array_rpt() 

	DEFINE lv_idx INTEGER 
	DEFINE lv_arr_size INTEGER 

	LET lv_arr_size = "100" 

	FOR lv_idx = 1 TO lv_arr_size 
		INITIALIZE ma_rpt[lv_idx].* TO NULL 
	END FOR 

END FUNCTION 

------------------------------------------------------------------------------

FUNCTION close_cursor_rpt() 

	CLOSE brrptgrp_curs 

	FREE s_2 

END FUNCTION 

------------------------------------------------------------------------------
