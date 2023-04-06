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

	Source code beautified by beautify.pl on 2020-01-02 10:35:21	$Id: $
}



#    padjtypwin.4gl - show_adj_type_code
#                     Window FUNCTION FOR finding prodadjtypes
#                     returns source_code
GLOBALS "../common/glob_GLOBALS.4gl" 

FUNCTION show_adj_type_code(p_cmpy) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_prodadjtype RECORD LIKE prodadjtype.* 
	DEFINE l_arr_prodadjtype DYNAMIC ARRAY OF RECORD 
		scroll_flag CHAR(1), 
		source_code LIKE prodadjtype.adj_type_code, 
		desc_text LIKE prodadjtype.desc_text, 
		adj_acct_code LIKE prodadjtype.adj_acct_code 
	END RECORD 
	DEFINE l_idx,l_scrn SMALLINT 
	DEFINE l_query_text CHAR(2200) 
	DEFINE l_where_text CHAR(2048) 

	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 
	OPEN WINDOW i629 with FORM "I629" 
	CALL windecoration_i("I629") -- albo kd-758 
	WHILE true 
		CLEAR FORM 
		LET l_msgresp = kandoomsg("U",1001,"") 
		#1001 " Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON source_code, 
		desc_text, 
		adj_acct_code 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","padjtypwin","construct-prodadjtype") 
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
		END CONSTRUCT 


		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_rec_prodadjtype.adj_type_code = NULL 
			EXIT WHILE 
		END IF 
		LET l_msgresp = kandoomsg("U",1002,"") 
		#1002 " Searching database - please wait"
		LET l_query_text = "SELECT * FROM prodadjtype ", 
		"WHERE cmpy_code = '",p_cmpy,"' ", 
		"AND ",l_where_text CLIPPED," ", 
		"ORDER BY source_code" 
		WHENEVER ERROR CONTINUE 
		OPTIONS SQL interrupt ON 
		PREPARE s_prodadjtype FROM l_query_text 
		DECLARE c_prodadjtype CURSOR FOR s_prodadjtype 
		LET l_idx = 0 
		FOREACH c_prodadjtype INTO l_rec_prodadjtype.* 
			LET l_idx = l_idx + 1 
			LET l_arr_prodadjtype[l_idx].source_code = l_rec_prodadjtype.adj_type_code 
			LET l_arr_prodadjtype[l_idx].desc_text = l_rec_prodadjtype.desc_text 
			LET l_arr_prodadjtype[l_idx].adj_acct_code = l_rec_prodadjtype.adj_acct_code 
			IF l_idx = 100 THEN 
				LET l_msgresp = kandoomsg("U",6100,l_idx) 
				EXIT FOREACH 
			END IF 
		END FOREACH 
		LET l_msgresp=kandoomsg("U",9113,l_idx) 
		#U9113 l_idx records selected
		IF l_idx = 0 THEN 
			LET l_idx = 1 
			INITIALIZE l_arr_prodadjtype[1].* TO NULL 
		END IF 
		WHENEVER ERROR stop 
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 

		LET l_msgresp = kandoomsg("U",1006,"") 
		#1006 " ESC on line TO SELECT - F10 TO Add"
		CALL set_count(l_idx) 
		INPUT ARRAY l_arr_prodadjtype WITHOUT DEFAULTS FROM sr_prodadjtype.* 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","padjtypwin","input-arr-prodadjtype") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 


			BEFORE ROW 
				LET l_idx = arr_curr() 
				LET l_scrn = scr_line() 
				IF l_arr_prodadjtype[l_idx].source_code IS NOT NULL THEN 
					DISPLAY l_arr_prodadjtype[l_idx].* TO sr_prodadjtype[l_scrn].* 

				END IF 
				NEXT FIELD scroll_flag 
			ON KEY (F10) 
				CALL run_prog("IZA","","","","") 
				NEXT FIELD scroll_flag 
			AFTER FIELD scroll_flag 
				LET l_arr_prodadjtype[l_idx].scroll_flag = NULL 
				IF fgl_lastkey() = fgl_keyval("down") 
				AND arr_curr() >= arr_count() THEN 
					LET l_msgresp = kandoomsg("U",9001,"") 
					NEXT FIELD scroll_flag 
				END IF 
			BEFORE FIELD source_code 
				LET l_rec_prodadjtype.adj_type_code = l_arr_prodadjtype[l_idx].source_code 
				EXIT INPUT 
			AFTER ROW 
				DISPLAY l_arr_prodadjtype[l_idx].* TO sr_prodadjtype[l_scrn].* 

			AFTER INPUT 
				LET l_rec_prodadjtype.adj_type_code = l_arr_prodadjtype[l_idx].source_code 

		END INPUT 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		ELSE 
			EXIT WHILE 
		END IF 
	END WHILE 
	CLOSE WINDOW i629 
	RETURN l_rec_prodadjtype.adj_type_code 
END FUNCTION 


