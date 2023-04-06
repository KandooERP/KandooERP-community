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

	Source code beautified by beautify.pl on 2020-01-02 10:35:32	$Id: $
}

GLOBALS "../common/glob_GLOBALS.4gl" 

FUNCTION show_maingrp_code(p_cmpy) 
	{ Window FUNCTION FOR finding glrepmaingrps AND will RETURN maingrp_code TO caller}
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE l_arr_glrepmaingrp ARRAY[100] OF RECORD 
		scroll_flag CHAR(1), 
		maingrp_code LIKE glrepmaingrp.maingrp_code, 
		desc_text LIKE glrepmaingrp.desc_text 
	END RECORD 
	DEFINE l_rec_glrepmaingrp RECORD LIKE glrepmaingrp.* 
	DEFINE l_idx SMALLINT 
	DEFINE l_cnt SMALLINT 
	DEFINE l_scrn SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_query_text CHAR(2200)
	DEFINE l_where_text CHAR(2048)	 

	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 
	OPEN WINDOW g541 with FORM "G541" 
	CALL windecoration_g("G541") -- albo kd-767 
	WHILE true 
		CLEAR FORM 
		LET l_msgresp = kandoomsg("W",1001,"") 
		#1001 " Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON maingrp_code, 
		desc_text 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","rptmwind","construct-glrepmaingrp") 
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
		END CONSTRUCT 


		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_rec_glrepmaingrp.maingrp_code = NULL 
			EXIT WHILE 
		END IF 
		LET l_msgresp = kandoomsg("W",1002,"") 
		#1002 " Searching database - please wait"
		LET l_query_text = "SELECT * FROM glrepmaingrp ", 
		"WHERE cmpy_code = '", p_cmpy, "' ", 
		"AND ", l_where_text CLIPPED," ", 
		"ORDER BY glrepmaingrp.maingrp_code" 
		PREPARE s_glrepmaingrp FROM l_query_text 
		DECLARE c_glrepmaingrp CURSOR FOR s_glrepmaingrp 
		LET l_idx = 0 
		FOREACH c_glrepmaingrp INTO l_rec_glrepmaingrp.* 
			LET l_idx = l_idx + 1 
			LET l_arr_glrepmaingrp[l_idx].maingrp_code = l_rec_glrepmaingrp.maingrp_code 
			LET l_arr_glrepmaingrp[l_idx].desc_text = l_rec_glrepmaingrp.desc_text 
			IF l_idx = 100 THEN 
				LET l_msgresp = kandoomsg("W",9021,l_idx) 
				#9021 " First ??? entries Selected Only"
				EXIT FOREACH 
			END IF 
		END FOREACH 
		IF l_idx = 0 THEN 
			LET l_msgresp = kandoomsg("W",9024,"") 
			#9024 No entries satsified selection criteria
			LET l_idx = 1 
			INITIALIZE l_arr_glrepmaingrp[1].* TO NULL 
		END IF 

		LET l_cnt = l_idx 
		CALL set_count(l_idx) 
		LET l_msgresp = kandoomsg("W",1006,"") 
		#1006 "ESC TO SELECT - F10 add"
		INPUT ARRAY l_arr_glrepmaingrp WITHOUT DEFAULTS FROM sr_maingrp.* 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","rptmwind","input-arr-glrepmaingrp") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 


			ON KEY (F10) 
				CALL run_prog("GL3","","","","") 
			BEFORE ROW 
				LET l_idx = arr_curr() 
				LET l_scrn = scr_line() 
				IF l_idx <= l_cnt THEN 
					DISPLAY l_arr_glrepmaingrp[l_idx].* TO sr_maingrp[l_scrn].* 

				END IF 
			AFTER ROW 
				IF l_idx <= l_cnt THEN 
					DISPLAY l_arr_glrepmaingrp[l_idx].* TO sr_maingrp[l_scrn].* 

				END IF 
			AFTER INPUT 
				LET l_rec_glrepmaingrp.maingrp_code 
				= l_arr_glrepmaingrp[l_idx].maingrp_code 

		END INPUT 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		ELSE 
			EXIT WHILE 
		END IF 
	END WHILE 
	CLOSE WINDOW g541 
	RETURN l_rec_glrepmaingrp.maingrp_code 
END FUNCTION 


