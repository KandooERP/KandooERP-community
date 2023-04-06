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

	Source code beautified by beautify.pl on 2020-01-02 10:35:04	$Id: $
}



# assdepfunc.4gl used FOR lookups of depreciation categories AND addition
# of new ones
GLOBALS "../common/glob_GLOBALS.4gl" 

FUNCTION lookup_dep_code(p_cmpy) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_arr_pa_fadep array[60] OF RECORD 
		depn_code LIKE fadepmethod.depn_code, 
		depn_method_code LIKE fadepmethod.depn_method_code 
	END RECORD 
	DEFINE l_idx SMALLINT 
	DEFINE l_scrn SMALLINT 
	DEFINE l_where_text CHAR(2048) 
	DEFINE l_query_text CHAR(2200) 
	DEFINE r_depn_code LIKE fadepmethod.depn_code 

	OPEN WINDOW wf169 at 5,5 with FORM "F169" 
	CALL winDecoration_f("F169") -- albo kd-767 

	WHILE true 
		CLEAR FORM 
		LET l_msgresp = kandoomsg("U",1001,"") 
		#1001 Enter Selection Criteria - OK TO Continue
		CONSTRUCT l_where_text ON fadepmethod.depn_code, 
		fadepmethod.depn_method_code 
		FROM screen_rec[1].* 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","assdepfunc","construct-fadepmethod") 
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
		END CONSTRUCT 


		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			CLOSE WINDOW wf169 
			OPTIONS INSERT KEY f1, 
			DELETE KEY f2 
			RETURN " " 
		END IF 
		LET l_msgresp = kandoomsg("U",1002,"") 
		#1002 Searching Database - Please Wait
		LET l_query_text = " SELECT depn_code,depn_method_code ", 
		" FROM fadepmethod ", 
		" WHERE cmpy_code = \"", p_cmpy,"\" AND ", 
		l_where_text clipped, 
		" ORDER BY depn_code " 
		PREPARE s_fadepmethod FROM l_query_text 
		DECLARE c_fadepmethod CURSOR FOR s_fadepmethod 
		LET l_idx = 1 
		FOREACH c_fadepmethod INTO l_arr_pa_fadep[l_idx].* 
			LET l_idx = l_idx + 1 
			IF l_idx > 50 THEN 
				LET l_msgresp = kandoomsg("U",6100,l_idx-1) 
				#6100 First l_idx RECORDs selected
				EXIT FOREACH 
			END IF 
		END FOREACH 
		LET l_idx = l_idx - 1 
		LET l_msgresp = kandoomsg("U",9113,l_idx) 
		#9113 l_idx RECORDs selected
		IF l_idx = 0 THEN 
			LET l_msgresp = kandoomsg("F",8006,"") 
			#8006 No department satisfied selection criteria; Add?
			LET l_msgresp = upshift(l_msgresp) 
			IF l_msgresp = "Y" THEN 
				CALL run_prog("FDP","","","","") 
				CONTINUE WHILE 
			END IF 
		ELSE 
			CALL set_count(l_idx) 
			OPTIONS INSERT KEY f36, 
			DELETE KEY f36 
			LET l_msgresp = kandoomsg("U",1006,"") 

			#1006 Press OK TO SELECT; F10 TO Add.
			INPUT ARRAY l_arr_pa_fadep WITHOUT DEFAULTS FROM screen_rec.* 

				BEFORE INPUT 
					CALL publish_toolbar("kandoo","assdepfunc","input-arr-fadep") 


				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				ON KEY (F10) 
					CALL run_prog("FDP","","","","") 
				BEFORE ROW 
					LET l_idx = arr_curr() 
					LET l_scrn = scr_line() 
					LET r_depn_code = l_arr_pa_fadep[l_idx].depn_code 
					DISPLAY l_arr_pa_fadep[l_idx].* TO screen_rec[l_scrn].* 

				AFTER ROW 
					IF fgl_lastkey() = fgl_keyval("down") THEN 
						IF l_arr_pa_fadep[l_idx+1].depn_code IS NULL 
						OR arr_curr() >= arr_count() THEN 
							LET l_msgresp=kandoomsg("U",9001,"") 
							#9001 There no more rows...
							NEXT FIELD depn_code 
						END IF 
					END IF 
					DISPLAY l_arr_pa_fadep[l_idx].* TO screen_rec[l_scrn].* 

				BEFORE FIELD depn_method_code 
					NEXT FIELD depn_code 

			END INPUT 
		END IF 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET r_depn_code = " " 
			CONTINUE WHILE 
		END IF 
		EXIT WHILE 
	END WHILE 
	OPTIONS INSERT KEY f1, 
	DELETE KEY f2 
	CLOSE WINDOW wf169 
	LET int_flag = false 
	LET quit_flag = false 

	RETURN r_depn_code 
END FUNCTION 



