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

	Source code beautified by beautify.pl on 2020-01-02 10:35:31	$Id: $
}



#          respwind.4gl - show_resp
#                         window FUNCTION FOR finding responsible records
#                         returns resp_code
GLOBALS "../common/glob_GLOBALS.4gl" 

FUNCTION show_resp(p_cmpy) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_responsible RECORD LIKE responsible.* 
	DEFINE l_arr_responsible array[100] OF RECORD 
		resp_code LIKE responsible.resp_code, 
		name_text LIKE responsible.name_text 
	END RECORD 
	DEFINE l_idx,l_scrn SMALLINT 
	DEFINE l_query_text CHAR(2200) 
	DEFINE l_where_text CHAR(2048) 

	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 
	OPEN WINDOW j110 with FORM "J110" 
	CALL windecoration_j("J110") -- albo kd-767 
	WHILE true 
		CLEAR FORM 
		LET l_msgresp = kandoomsg("U",1001,"") 
		#1001 " Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON resp_code, 
		name_text 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","respwind","construct-responsible") 
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
		END CONSTRUCT 


		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_rec_responsible.resp_code = NULL 
			EXIT WHILE 
		END IF 
		LET l_msgresp = kandoomsg("U",1002,"") 
		#1002 " Searching database - please wait"
		LET l_query_text = "SELECT * FROM responsible ", 
		"WHERE cmpy_code = '",p_cmpy,"' ", 
		"AND ",l_where_text CLIPPED," ", 
		"ORDER BY resp_code" 
		WHENEVER ERROR CONTINUE 
		OPTIONS SQL interrupt ON 
		PREPARE s_responsible FROM l_query_text 
		DECLARE c_responsible CURSOR FOR s_responsible 
		LET l_idx = 0 
		FOREACH c_responsible INTO l_rec_responsible.* 
			LET l_idx = l_idx + 1 
			LET l_arr_responsible[l_idx].resp_code = l_rec_responsible.resp_code 
			LET l_arr_responsible[l_idx].name_text = l_rec_responsible.name_text 
			IF l_idx = 100 THEN 
				LET l_msgresp = kandoomsg("U",6100,l_idx) 
				EXIT FOREACH 
			END IF 
		END FOREACH 
		LET l_msgresp=kandoomsg("U",9113,l_idx) 
		#U9113 l_idx records selected
		IF l_idx = 0 THEN 
			LET l_idx = 1 
			INITIALIZE l_arr_responsible[1].* TO NULL 
		END IF 
		WHENEVER ERROR stop 
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

		LET l_msgresp = kandoomsg("U",1006,"") 
		#1006 " ESC on line TO SELECT - F10 TO Add"
		CALL set_count(l_idx) 
		INPUT ARRAY l_arr_responsible WITHOUT DEFAULTS FROM sr_responsible.* 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","respwind","input-arr-responsible") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 


			BEFORE ROW 
				LET l_idx = arr_curr() 
				LET l_scrn = scr_line() 
				IF l_arr_responsible[l_idx].resp_code IS NOT NULL THEN 
					DISPLAY l_arr_responsible[l_idx].* TO sr_responsible[l_scrn].* 

				END IF 
				NEXT FIELD resp_code 
			ON KEY (F10) 
				CALL run_prog("JZ5","","","","") 
				NEXT FIELD resp_code 
			AFTER FIELD resp_code 
				IF fgl_lastkey() = fgl_keyval("down") 
				AND arr_curr() >= arr_count() THEN 
					LET l_msgresp = kandoomsg("U",9001,"") 
					NEXT FIELD resp_code 
				END IF 
			BEFORE FIELD name_text 
				LET l_rec_responsible.resp_code = l_arr_responsible[l_idx].resp_code 
				EXIT INPUT 
			AFTER ROW 
				DISPLAY l_arr_responsible[l_idx].* TO sr_responsible[l_scrn].* 

			AFTER INPUT 
				LET l_rec_responsible.resp_code = l_arr_responsible[l_idx].resp_code 

		END INPUT 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		ELSE 
			EXIT WHILE 
		END IF 
	END WHILE 
	CLOSE WINDOW j110 
	RETURN l_rec_responsible.resp_code 
END FUNCTION 


