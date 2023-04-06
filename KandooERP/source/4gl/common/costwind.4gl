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

	Source code beautified by beautify.pl on 2020-01-02 10:35:09	$Id: $
}



# FUNCTION show_costtype - Shows the valid ship cost types in the
# control -b lookup window

GLOBALS "../common/glob_GLOBALS.4gl" 

FUNCTION show_costtype(p_cmpy) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE l_arr_shipcosttype ARRAY[51] OF RECORD 
		cost_type_code LIKE shipcosttype.cost_type_code, 
		desc_text LIKE shipcosttype.desc_text 
		END RECORD 
	DEFINE l_idx SMALLINT 
	DEFINE l_scrn SMALLINT 
	DEFINE l_cnt SMALLINT 
	DEFINE l_query_text CHAR(2048) 
	DEFINE l_sel_text CHAR(2200) 

	OPEN WINDOW l140 with FORM "L140" 
	CALL winDecoration_l("L140") -- albo kd-752 

	WHILE true 
		LET l_cnt = 0 
		LET l_idx = 1 
		CLEAR FORM 
		MESSAGE " Enter Selection Criteria - ESC TO Continue" 
		attribute (yellow) 
		CONSTRUCT l_query_text 
		ON cost_type_code, 
		desc_text 
		FROM sr_sct[1].cost_type_code, 
		sr_sct[1].desc_text 


			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","costwind","construct-cost") 
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
		END CONSTRUCT 



		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			EXIT WHILE 
		END IF 
		LET l_sel_text = 
		"SELECT cost_type_code,", 
		" desc_text", 
		" FROM shipcosttype WHERE ", 
		l_query_text CLIPPED, 
		" AND cmpy_code = \"",p_cmpy,"\"", 
		" ORDER BY cost_type_code" 
		PREPARE shipcosttype FROM l_sel_text 
		DECLARE shipcurs CURSOR FOR shipcosttype 
		FOREACH shipcurs INTO l_arr_shipcosttype[l_idx].* 
			IF l_idx > 50 THEN 
				MESSAGE " First 50 only selected " 
				attribute (yellow) 
				EXIT FOREACH 
			END IF 
			LET l_idx = l_idx + 1 
			LET l_cnt = l_cnt + 1 
		END FOREACH 
		IF l_cnt > 0 THEN 
			MESSAGE " ESC TO SELECT - F9 Reselect - F10 Add" 
			attribute (yellow) 
		ELSE 
			ERROR "No Shipment Cost Types Satisfy Criteria" 
			SLEEP 3 
			CONTINUE WHILE 
		END IF 

		CALL set_count(l_cnt) 
		INPUT ARRAY l_arr_shipcosttype WITHOUT DEFAULTS FROM sr_sct.* 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","costwind","input-arr-shipcosttype") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			BEFORE ROW 
				LET l_idx = arr_curr() 
				LET l_scrn = scr_line() 
				IF l_idx <= l_cnt THEN 
					DISPLAY l_arr_shipcosttype[l_idx].* TO sr_sct[l_scrn].* 

				END IF 
			BEFORE FIELD desc_text 
				EXIT INPUT 
			AFTER ROW 
				IF l_idx <= l_cnt THEN 
					DISPLAY l_arr_shipcosttype[l_idx].* TO sr_sct[l_scrn].* 

				END IF 
			ON KEY (F9) 
				LET quit_flag = true 
				EXIT INPUT 
			ON KEY (F10) 
				ERROR "We have written this yet" 
				#run "fglgo JZ4.4gi"

		END INPUT 
		LET l_idx = arr_curr() 
		EXIT WHILE 
	END WHILE 
	CLOSE WINDOW l140 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN 0, "zz" 
	ELSE 
		RETURN 1, l_arr_shipcosttype[l_idx].cost_type_code 
	END IF 
END FUNCTION 



