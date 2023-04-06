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

# Purpose - Manegement REPORT Groups Maintenance
# Purpose - This file contains the functions used in the picklist FOR
#           the table rpthead.


--- Module Variable Definitions

DEFINE ma_browse_rec array[100] OF RECORD 

	rpt_id LIKE rpthead.rpt_id, 
	rpt_text LIKE rpthead.rpt_text 

END RECORD 

-----------------------------------------------------------------------------

FUNCTION pick_rpt(pv_rptgrp_id) 

	DEFINE pv_rptgrp_id LIKE rpthead_group.rptgrp_id 
	DEFINE lv_record_count INTEGER 
	DEFINE lv_another_selection SMALLINT 
	DEFINE lv_cnt SMALLINT 

	# WHENEVER ERROR CONTINUE

	OPEN WINDOW w2_pick_rpt with FORM "TG567" 
	CALL windecoration_t("TG567") -- albo kd-768 

	WHILE true --- loop until user aborts OR selects a RECORD 

		CLEAR FORM 

		--- Allow user TO use QBE, IF aborted the RETURN NULLS TO calling FUNCTION

		IF w_query_rpt(pv_rptgrp_id) THEN 

			CLOSE WINDOW w2_pick_rpt 
			INITIALIZE ma_browse_rec[1].* TO NULL 
			RETURN ma_browse_rec[1].*, true 
		END IF 

		LET lv_record_count = w_load_rpt() 

		--- IF no records were found THEN DISPLAY a MESSAGE AND LET the user try again

		IF lv_record_count = 0 THEN 

			MESSAGE "No records found, please redefine your selection criteria" 
			attribute(YELLOW) 

			CONTINUE WHILE 
		END IF 

		--- IF only one RECORD was found THEN RETURN it TO the calling FUNCTION

		IF lv_record_count = 1 THEN 

			CLOSE WINDOW w2_pick_rpt 
			RETURN ma_browse_rec[1].*, false 
		END IF 

		LET lv_another_selection = false 

		MESSAGE "[ESC] TO SELECT, [INTERRUPT] TO abort" 
		attribute(YELLOW) 

		DISPLAY lv_record_count, " Records found" at 2,1 
		attribute (RED) 

		CALL set_count(lv_record_count) 

		DISPLAY ARRAY ma_browse_rec TO sa_browse_rec.* 
			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","TGW6e","display-arr-browse") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			ON KEY (F9) ---------- re-query ---------- 

				LET lv_another_selection = true 
				EXIT DISPLAY 

				{
				    ON KEY (CONTROL-M) ---- SELECT FROM PICK LIST KEY ---------

				        EXIT DISPLAY
				}

		END DISPLAY 

		LET lv_cnt = arr_curr() 

		IF interrupted() THEN --- make the FUNCTION RETURN nulls 

			INITIALIZE ma_browse_rec[lv_cnt].* TO NULL 
			CLOSE WINDOW w2_pick_rpt 
			RETURN ma_browse_rec[lv_cnt].*, true 
		END IF 

		IF lv_another_selection THEN 

			CONTINUE WHILE 
		END IF 

		CLOSE WINDOW w2_pick_rpt 
		RETURN ma_browse_rec[lv_cnt].*, false 

	END WHILE 

END FUNCTION 
--- pick_rpthead()

------------------------------------------------------------------------------

FUNCTION w_query_rpt(pv_rptgrp_id) 

	DEFINE pv_rptgrp_id LIKE rpthead_group.rptgrp_id 
	DEFINE lv_construct_fields, lv_win_query_text CHAR(600) 

	LET lv_construct_fields = "1=1" 

	MESSAGE "Enter your search criteria, " 
	attribute (YELLOW) 
	DISPLAY "[ESC] TO commence search, [INTERRUPT] TO EXIT" at 2,1 
	attribute (YELLOW) 

	CONSTRUCT BY NAME lv_construct_fields ON rpthead.rpt_id, 
	rpthead.rpt_text 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","TGW6e","construct-rpt_id-1") -- albo kd-515 

		ON ACTION "WEB-HELP" -- albo kd-378 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	IF interrupted() THEN 

		RETURN true 
	END IF 

	DISPLAY "" at 2,1 --- CLEAR 2nd line OF qbe-2line MESSAGE 

	MESSAGE "Retrieving Records. Please wait...." 
	attribute(YELLOW) 

	LET lv_win_query_text = 
	" SELECT UNIQUE rpt_id, rpt_text ", 
	" FROM rpthead, rptcolgrp", 
	" WHERE ", lv_construct_fields clipped, 
	" AND rpthead.cmpy_code = '", gv_cmpy_code, "' ", 
	" AND rpthead.col_code = rptcolgrp.col_code ", 
	" AND rpthead.cmpy_code = rptcolgrp.cmpy_code ", 
	" AND colrptg_type IN ('AA', 'AD') ", 
	" AND rpthead.rpt_id NOT IN ( ", 
	" SELECT tmp_rpthead.rpt_id ", 
	" FROM tmp_rpthead ", 
	" WHERE tmp_rpthead.cmpy_code = '", gv_cmpy_code, "' ", 
	" AND tmp_rpthead.rptgrp_id = '", pv_rptgrp_id ,"' ) ", 

	" ORDER BY rpt_id" 


	PREPARE browse_id FROM lv_win_query_text 
	DECLARE browse_curs CURSOR FOR browse_id 
	OPEN browse_curs 

	RETURN false 

END FUNCTION 
--- w_query_rpthead()

------------------------------------------------------------------------------

FUNCTION w_load_rpt() 

	DEFINE lv_idx SMALLINT 

	LET lv_idx = 1 

	FOREACH browse_curs INTO ma_browse_rec[lv_idx].* 

		LET lv_idx = lv_idx + 1 
		IF lv_idx > 100 THEN 

			--- Restrict the selection of records TO 100 as the ARRAY
			--- has been declared as
			--- 100 FOR system rpthead reasons


			MESSAGE "Only the first 100 records selected, " 
			attribute(YELLOW) 
			DISPLAY "Please limit your selection" at 2,1 
			attribute(YELLOW) 

			EXIT FOREACH 
		END IF 

	END FOREACH 

	CLOSE browse_curs 
	FREE browse_id 

	LET lv_idx = lv_idx -1 
	RETURN lv_idx 

END FUNCTION 

-------------------------------------------------------------------------

{ ###############

FUNCTION get_descript_rpt(pv_loc_code)

DEFINE pv_loc_code          LIKE rpthead.rpt_id
DEFINE pv_loc_desc          LIKE rpthead.rpt_text

INITIALIZE pv_loc_desc TO NULL

SELECT rpt_text
  INTO pv_loc_desc
  FROM rpthead
 WHERE rpt_id = pv_loc_code
   AND cmpy_code = gv_cmpy_code

IF STATUS = NOTFOUND THEN

    RETURN "", FALSE
END IF

IF error_trap(STATUS) THEN

    RETURN "", FALSE
END IF

RETURN pv_loc_desc, TRUE

END FUNCTION

############### }
