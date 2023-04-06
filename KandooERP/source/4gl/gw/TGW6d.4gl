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
#           updating, display-full SCREEN OR deleting) in the rpthead_group
#           group table.  All these functions must be kept in the
#           same file because they use the same module variables,
#           i.e. the module ARRAY AND the CURSOR.

--- Module Variables Definitions



DEFINE ma_rpthead_group array[100] OF RECORD 

	rptgrp_id LIKE rpthead_group.rptgrp_id, 
	rptgrp_text LIKE rpthead_group.rptgrp_text 

END RECORD 

--------------------------------------------------------------------------

FUNCTION query_rptgrp() 

	DEFINE lr_rpthead_group RECORD LIKE rpthead_group.* 
	DEFINE lv_query_1 CHAR(400) 
	DEFINE lv_ca_type_id CHAR(1) 
	DEFINE lv_select_string CHAR(500) 

	LET int_flag = false 
	LET quit_flag = false 

	# WHENEVER ERROR CONTINUE

	--- Set up the form
	CLEAR FORM 

	MESSAGE "Enter search criteria, [ESC] Accept, [INTERRUPT] Exit" 
	attribute (YELLOW) 

	DISPLAY "" at 2,1 

	--- Get the users criteria

	INITIALIZE lv_query_1 TO NULL 

	CONSTRUCT BY NAME lv_query_1 ON rpthead_group.rptgrp_id, 
	rpthead_group.rptgrp_text, 
	rpthead_group.rptgrp_desc2 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","TGW6d","construct-rptgrp_id-1") -- albo kd-515 

		ON ACTION "WEB-HELP" -- albo kd-378 
			CALL onlinehelp(getmoduleid(),null) 

		#ON ACTION "LOOKUP" ---------- pick lists ---------- 

			{ The browse IS only performed on foreign keys }
			#     CASE
			#        WHEN INFIELD(rptgrp_id)
			#            CALL pick_rptgrp() RETURNING lr_rpthead_group.rptgrp_id,
			#                                      lr_rpthead_group.rptgrp_text
			#            DISPLAY BY NAME lr_rpthead_group.rptgrp_id,
			#                            lr_rpthead_group.rptgrp_text
			#
			#        OTHERWISE

		#	ERROR "There IS no browse window available FOR this field" 
		#	attribute(YELLOW, reverse) 

			#    END CASE

	END CONSTRUCT 

	IF interrupted() THEN 

		RETURN false 
	END IF 

	--- Set up the SELECT statment

	CLEAR FORM 

	LET lv_select_string = 
	" SELECT rptgrp_id, rptgrp_text ", 
	" FROM rpthead_group ", 
	" WHERE ", lv_query_1 clipped, 
	" AND cmpy_code = '", gv_cmpy_code, "' ", 
	" ORDER BY rptgrp_id" 

	PREPARE s_1 FROM lv_select_string 

	--- Now DECLARE a CURSOR FOR the relevant info in the rptgrpal govt region table

	DECLARE rptgrpstr_curs CURSOR FOR s_1 

	IF error_trap(status) THEN 

		RETURN false 
	END IF 

	RETURN true 

END FUNCTION 
--- query_rpthead_group()

------------------------------------------------------------------------------
FUNCTION load_array_rptgrp() 

	DEFINE lv_pa_totsize SMALLINT 
	DEFINE pv_records_count INTEGER 

	LET lv_pa_totsize = 100 

	FOR pv_records_count = 1 TO lv_pa_totsize 

		INITIALIZE ma_rpthead_group[pv_records_count].* TO NULL 
	END FOR 

	LET pv_records_count = 1 

	FOREACH rptgrpstr_curs INTO ma_rpthead_group[pv_records_count].* 

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

FUNCTION scroll_rptgrp(pv_records_count) 

	DEFINE lv_scrn SMALLINT 
	DEFINE lv_idx SMALLINT 
	DEFINE lv_copy LIKE rpthead_group.rptgrp_id 
	DEFINE lv_last_key INTEGER 
	DEFINE lv_error_flag SMALLINT 
	DEFINE lv_delete_success_flg SMALLINT 
	DEFINE pv_records_count INTEGER 
	DEFINE pv_found_flag INTEGER 
	DEFINE pr_rpthead_group RECORD LIKE rpthead_group.* 
	DEFINE lv_pa_totsize SMALLINT 
	DEFINE lv_counter SMALLINT 

	#OPTIONS ACCEPT KEY F31

	LET lv_pa_totsize = 100 

	IF pv_records_count = 1 THEN 

		#    OPTIONS ACCEPT KEY ESCAPE

		CALL get_rptgrp(ma_rpthead_group[1].rptgrp_id) 
		RETURNING pr_rpthead_group.rptgrp_id, 
		pr_rpthead_group.rptgrp_text, 
		pr_rpthead_group.rptgrp_desc1, 
		pr_rpthead_group.rptgrp_desc2, 
		pv_found_flag 


		CALL modify_rptgrp(pr_rpthead_group.*) 
		RETURNING ma_rpthead_group[1].*, 
		pr_rpthead_group.rptgrp_desc2 


		####   CALL display_rpthead_group(pr_rpthead_group.*)



		RETURN 
	END IF 

	OPEN WINDOW w1_rptgrpstr with FORM "TG568" 
	CALL windecoration_t("TG568") -- albo kd-768 

	MESSAGE "[ESC]=UPDATE,[INTERRUPT]=abort,[F2]=delete" 
	attribute(YELLOW) 

	DISPLAY pv_records_count, " Records found" at 2,1 
	attribute (RED) 

	CALL set_count(pv_records_count) 

	OPTIONS INSERT KEY f28, 
	accept KEY f31 

	INPUT ARRAY ma_rpthead_group WITHOUT DEFAULTS FROM sa_browse_rec.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","TGW6d","input-arr-ma_rpthead_group-1") -- albo kd-515 

		ON ACTION "WEB-HELP" -- albo kd-378 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE FIELD rptgrp_id -------------- section ------------- 

			--- stop user FROM overtyping the field

			LET lv_copy = ma_rpthead_group[lv_idx].rptgrp_id 

		AFTER FIELD rptgrp_id ---------- AFTER FIELD section --------- 

			--- stop user FROM overtyping the field AND accessing blank lines

			LET ma_rpthead_group[lv_idx].rptgrp_id = lv_copy 

			DISPLAY ma_rpthead_group[lv_idx].* TO sa_browse_rec[lv_scrn].* 
			attribute(RED, reverse) 

			LET lv_last_key = fgl_lastkey() 

			IF (lv_idx >= pv_records_count AND lv_last_key = FGL_KEYVAL("DOWN")) 
			OR (lv_idx >= pv_records_count - 5 --- (= screen ARRAY size-1) 
			AND lv_last_key= fgl_keyval("NEXTPAGE")) THEN 

				ERROR " There are no more rows in the direction you are going " 
				attribute (RED) 

				NEXT FIELD rptgrp_id 
			END IF 

		BEFORE FIELD rptgrp_text -------- BEFORE FIELD section --------- 

			--- stop user FROM accessing other fields

			NEXT FIELD previous 

		ON KEY (ESCAPE) ---------- accept KEY ---------- 

			#OPTIONS ACCEPT KEY ESCAPE

			CALL get_rptgrp(ma_rpthead_group[lv_idx].rptgrp_id) 
			RETURNING pr_rpthead_group.rptgrp_id, 
			pr_rpthead_group.rptgrp_text, 
			pr_rpthead_group.rptgrp_desc1, 
			pr_rpthead_group.rptgrp_desc2, 
			pv_found_flag 

			CALL modify_rptgrp(pr_rpthead_group.*) 
			RETURNING ma_rpthead_group[lv_idx].*, 

			pr_rpthead_group.rptgrp_desc2 

			#    CALL display_rpthead_group(ma_rpthead_group[lv_idx].*)

			#OPTIONS ACCEPT KEY F31

			CURRENT WINDOW IS w1_rptgrpstr 

			DISPLAY ma_rpthead_group[lv_idx].* TO sa_browse_rec[lv_scrn].* 
			attribute(RED, reverse) 

		ON KEY (F2) --------- DELETE KEY ---------- 

			#    CALL no_delete_msg()
			#    NEXT FIELD PREVIOUS

			#OPTIONS ACCEPT KEY ESCAPE

			CALL get_rptgrp(ma_rpthead_group[lv_idx].rptgrp_id) 
			RETURNING pr_rpthead_group.rptgrp_id, 
			pr_rpthead_group.rptgrp_text, 
			pr_rpthead_group.rptgrp_desc1, 
			pr_rpthead_group.rptgrp_desc2, 
			pv_found_flag 

			LET lv_delete_success_flg = remove_rptgrp(pr_rpthead_group.*) 

			#OPTIONS ACCEPT KEY F31

			CURRENT WINDOW IS w1_rptgrpstr 

			IF lv_delete_success_flg THEN 

				IF pv_records_count = 1 THEN 

					INITIALIZE ma_rpthead_group[1].* TO NULL 
					DISPLAY ma_rpthead_group[1].* TO sa_browse_rec[1].* 

				ELSE 

					FOR lv_counter = arr_curr() TO (pv_records_count -1) 

						LET ma_rpthead_group[lv_counter].* = ma_rpthead_group[lv_counter+1].* 
					END FOR 

					INITIALIZE ma_rpthead_group[pv_records_count].* TO NULL 

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

					FOR lv_counter = scr_line() TO 6 --- screen ARRAY size 

						DISPLAY ma_rpthead_group[lv_idx + lv_counter - lv_scrn].* 
						TO sa_browse_rec[lv_counter].* 

					END FOR 

					DISPLAY ma_rpthead_group[lv_idx].* TO sa_browse_rec[lv_scrn].* 
					attribute(RED, reverse) 
				END IF 

				OPTIONS MESSAGE line LAST 
				MESSAGE "Record Deleted Successfully" attribute (YELLOW) 
				SLEEP 1 
				OPTIONS MESSAGE line FIRST 

			END IF 

			NEXT FIELD rptgrp_id 

		BEFORE ROW ---------------------- section ---------------------- 

			LET lv_idx = arr_curr() 
			LET lv_scrn = scr_line() 

			DISPLAY ma_rpthead_group[lv_idx].* TO sa_browse_rec[lv_scrn].* 
			attribute(RED, reverse) 

		AFTER ROW ---------------------- section ---------------------- 

			DISPLAY ma_rpthead_group[lv_idx].* TO sa_browse_rec[lv_scrn].* 


			{ --- use of [ACCEPT] TO UPDATE IS disabled

			AFTER INPUT -------------------- SECTION ----------------------

			    IF interrupted() THEN
			        EXIT INPUT
			    END IF

			    OPTIONS ACCEPT KEY ESCAPE

			    CALL get_rptgrp(ma_rpthead_group[lv_idx].rpthead_group_id)
			         RETURNING pr_rpthead_group.*, pv_found_flag

			    CALL modify_rptgrp(pr_rpthead_group.*)
			        RETURNING ma_rpthead_group[lv_idx].*,
			                 pr_rpthead_group.rptgrp_desc2

			#   CALL display_rpthead_group(ma_rpthead_group[lv_idx].*)

			    LET lv_idx = ARR_CURR()

			    OPTIONS ACCEPT KEY F31

			    CURRENT WINDOW IS w1_rptgrpstr

			    DISPLAY ma_rpthead_group[lv_idx].* TO sa_browse_rec[lv_scrn].*
			            ATTRIBUTE(RED, REVERSE)

			    NEXT FIELD PREVIOUS
			}

	END INPUT 

	CALL set_options() 

	CLOSE WINDOW w1_rptgrpstr 

END FUNCTION 
--- scroll_rpthead_group(pv_records_count)

------------------------------------------------------------------------------

FUNCTION close_cursor_rptgrp() 

	CLOSE rptgrpstr_curs 

	FREE s_1 

END FUNCTION 
--- close_cursor_rpthead_group()

------------------------------------------------------------------------------
