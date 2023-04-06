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



#     resgwind.4gl - show_resg
#                    Window FUNCTION FOR finding resource group records
#                    FUNCTION will RETURN resgrp_code TO calling program
GLOBALS "../common/glob_GLOBALS.4gl" 

FUNCTION show_resg(p_cmpy) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_resgrp RECORD LIKE resgrp.* 
	DEFINE l_arr_resgrp ARRAY[100] OF RECORD 
		scroll_flag CHAR(1), 
		resgrp_code LIKE resgrp.resgrp_code, 
		resgrp_text LIKE resgrp.resgrp_text, 
		res_type_ind LIKE resgrp.res_type_ind 
	END RECORD 
	DEFINE l_idx,l_scrn SMALLINT 
	DEFINE l_query_text CHAR(2200) 
	DEFINE l_where_text CHAR(2048) 

	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 
	OPEN WINDOW j199 with FORM "J199" 
	CALL windecoration_j("J199") -- albo kd-767 
	WHILE true 
		CLEAR FORM 
		LET l_msgresp = kandoomsg("U",1001,"") 
		#1001 " Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON resgrp_code, 
		resgrp_text, 
		res_type_ind 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","resgwind","construct-resgrp") 
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
		END CONSTRUCT 


		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_rec_resgrp.resgrp_code = NULL 
			EXIT WHILE 
		END IF 
		LET l_msgresp = kandoomsg("U",1002,"") 
		#1002 " Searching database - please wait"
		LET l_query_text = "SELECT * FROM resgrp ", 
		"WHERE cmpy_code = '",p_cmpy,"' ", 
		"AND ",l_where_text CLIPPED," ", 
		"ORDER BY resgrp_code" 
		WHENEVER ERROR CONTINUE 
		OPTIONS SQL INTERRUPT ON 
		PREPARE s_resgrp FROM l_query_text 
		DECLARE c_resgrp CURSOR FOR s_resgrp 
		LET l_idx = 0 
		FOREACH c_resgrp INTO l_rec_resgrp.* 
			LET l_idx = l_idx + 1 
			LET l_arr_resgrp[l_idx].resgrp_code = l_rec_resgrp.resgrp_code 
			LET l_arr_resgrp[l_idx].resgrp_text = l_rec_resgrp.resgrp_text 
			LET l_arr_resgrp[l_idx].res_type_ind = l_rec_resgrp.res_type_ind 
			IF l_idx = 100 THEN 
				LET l_msgresp = kandoomsg("U",6100,l_idx) 
				EXIT FOREACH 
			END IF 
		END FOREACH 
		LET l_msgresp=kandoomsg("U",9113,l_idx) 
		#U9113 l_idx records selected
		IF l_idx = 0 THEN 
			LET l_idx = 1 
			INITIALIZE l_arr_resgrp[1].* TO NULL 
		END IF 
		WHENEVER ERROR stop 
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

		LET l_msgresp = kandoomsg("U",1006,"") 
		#1006 " ESC on line TO SELECT - F10 TO Add"
		CALL set_count(l_idx) 
		INPUT ARRAY l_arr_resgrp WITHOUT DEFAULTS FROM sr_resgrp.* 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","resgwind","input-arr-resgrp") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 


			BEFORE ROW 
				LET l_idx = arr_curr() 
				LET l_scrn = scr_line() 
				DISPLAY l_arr_resgrp[l_idx].* TO sr_resgrp[l_scrn].* 

				NEXT FIELD scroll_flag 
			ON KEY (F10) 
				CALL run_prog("JZ1","","","","") 
				NEXT FIELD scroll_flag 
			AFTER FIELD scroll_flag 
				LET l_arr_resgrp[l_idx].scroll_flag = NULL 
				IF fgl_lastkey() = fgl_keyval("down") 
				AND arr_curr() >= arr_count() THEN 
					LET l_msgresp = kandoomsg("U",9001,"") 
					NEXT FIELD scroll_flag 
				END IF 
			BEFORE FIELD resgrp_code 
				LET l_rec_resgrp.resgrp_code = l_arr_resgrp[l_idx].resgrp_code 
				EXIT INPUT 
			AFTER ROW 
				DISPLAY l_arr_resgrp[l_idx].* TO sr_resgrp[l_scrn].* 

			AFTER INPUT 
				LET l_rec_resgrp.resgrp_code = l_arr_resgrp[l_idx].resgrp_code 

		END INPUT 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		ELSE 
			EXIT WHILE 
		END IF 
	END WHILE 
	CLOSE WINDOW j199 
	RETURN l_rec_resgrp.resgrp_code 
END FUNCTION 


