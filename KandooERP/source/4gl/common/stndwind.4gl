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
# This module IF FOR the Standing Invoice Run. It allows the user TO
# SELECT a group code FROM a valid group code list.

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

###########################################################################
# FUNCTION show_group(p_cmpy)
#
#
###########################################################################
FUNCTION show_group(p_cmpy) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE l_arr_stnd_grp ARRAY[100] OF RECORD 
		group_code LIKE stnd_grp.group_code, 
		desc_text LIKE stnd_grp.desc_text 
	END RECORD 
	DEFINE l_idx SMALLINT 
	DEFINE l_cnt SMALLINT 
	DEFINE l_scrn SMALLINT 
	DEFINE l_query_text CHAR(2200)
	DEFINE l_sel_text CHAR(2048)
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_formname CHAR(15) 

	OPEN WINDOW stndwind with FORM "U159" 
	CALL windecoration_u("U159") 

	WHILE true 
		MESSAGE " Enter criteria AND press ESC" attribute (yellow) 

		CONSTRUCT BY NAME l_query_text ON group_code, 
		desc_text 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","stndwind","construct-stnd_grp") 
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			EXIT WHILE 
		END IF 

		MESSAGE "Searching Database Please wait......." 
		SLEEP 2 

		LET l_sel_text = 
		"SELECT group_code, desc_text ", 
		"FROM stnd_grp ", 
		"WHERE ", l_query_text CLIPPED, 
		" AND cmpy_code = '", p_cmpy, "' ", 
		" ORDER BY group_code" 

		PREPARE stdgroup FROM l_sel_text 
		DECLARE grpcurs CURSOR FOR stdgroup 

		LET l_idx = 1 
		FOREACH grpcurs INTO l_arr_stnd_grp[l_idx].* 
			LET l_idx = l_idx + 1 
			IF l_idx > 25 THEN 
				EXIT FOREACH 
			END IF 
			IF l_idx = 100 THEN 
				MESSAGE "Only the first 100 groups selected"
				EXIT FOREACH 
			END IF 
		END FOREACH 

		LET l_idx = l_idx - 1 
		IF l_idx > 0 THEN 
			EXIT WHILE 
		END IF 

		MESSAGE "No Customer group codes satisfy query" attribute (yellow) 

		EXIT WHILE 
	END WHILE 

	IF int_flag OR quit_flag THEN 
		GOTO abandon 
	END IF 

	LET l_cnt = l_idx 
	CALL set_count(l_idx) 

	MESSAGE "Move CURSOR TO group - ESC" attribute (yellow) 
	CALL set_count(l_idx) 

	INPUT ARRAY l_arr_stnd_grp WITHOUT DEFAULTS FROM sr_stdgrp.* 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","stndwind","input-arr-stnd_grp") 


		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			LET l_scrn = scr_line() 

			IF l_arr_stnd_grp[l_idx].group_code IS NOT NULL THEN 
				DISPLAY l_arr_stnd_grp[l_idx].* TO sr_stdgrp[l_scrn].* 

			END IF 
			NEXT FIELD group_code 

		AFTER ROW 
			DISPLAY l_arr_stnd_grp[l_idx].* TO sr_stdgrp[l_scrn].* 


		AFTER FIELD group_code 
			IF fgl_lastkey() = fgl_keyval("down") 
			AND arr_curr() = arr_count() THEN 
				LET l_msgresp = kandoomsg("U",9001,"") 			#9001 There are no more rows in the direction you are going.
				NEXT FIELD group_code 
			END IF 
	END INPUT 
	LET l_idx = arr_curr() 

	LABEL abandon: 

	CLOSE WINDOW stndwind 

	IF int_flag OR quit_flag THEN 
		LET int_flag = 0 
		LET quit_flag = 0 
		RETURN "" 
	END IF 

	RETURN l_arr_stnd_grp[l_idx].group_code 
END FUNCTION 
###########################################################################
# END FUNCTION show_group(p_cmpy)
###########################################################################