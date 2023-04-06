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
###########################################################################

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl"

################################################################################
# FUNCTION show_maingrp(p_cmpy,p_filter_text)
#
#   mainwind.4gl - show_maingrp
#                  Window FUNCTION FOR finding a maingrp records
#                  FUNCTION will RETURN maingrp_code TO calling program
################################################################################
FUNCTION show_maingrp(p_cmpy,p_filter_text) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_filter_text STRING
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_maingrp RECORD LIKE maingrp.*
	DEFINE l_arr_maingrp DYNAMIC ARRAY OF RECORD 
		scroll_flag CHAR(1), 
		maingrp_code LIKE maingrp.maingrp_code, 
		desc_text LIKE maingrp.desc_text 
	END RECORD 
	DEFINE l_idx SMALLINT 
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 

	IF p_filter_text IS NULL THEN 
		LET p_filter_text = "1=1" 
	END IF 

	OPEN WINDOW I602 with FORM "I602" 
	CALL windecoration_i("I602") 

	WHILE true 
		CLEAR FORM 
		MESSAGE kandoomsg2("U",1001,"") 	#1001 " Enter Selection Criteria - ESC TO Continue"

		---------------------------------------------------
		CONSTRUCT BY NAME l_where_text ON 
			maingrp_code, 
			desc_text 
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","mgrpwind","construct-maingrp") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END CONSTRUCT 
		-----------------------------------

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_rec_maingrp.maingrp_code = NULL 
			EXIT WHILE 
		END IF 
		
		MESSAGE kandoomsg2("U",1002,"")	#1002 " Searching database - please wait"
		LET l_query_text = "SELECT * FROM maingrp ", 
		"WHERE cmpy_code = \"",p_cmpy,"\" ", 
		"AND ",l_where_text CLIPPED," ", 
		"AND ",p_filter_text CLIPPED," ", 
		"ORDER BY maingrp_code" 

		WHENEVER ERROR CONTINUE 

		OPTIONS SQL interrupt ON 

		PREPARE s_maingrp FROM l_query_text 
		DECLARE c_maingrp CURSOR FOR s_maingrp 

		LET l_idx = 0 
		FOREACH c_maingrp INTO l_rec_maingrp.* 
			LET l_idx = l_idx + 1 
			LET l_arr_maingrp[l_idx].maingrp_code = l_rec_maingrp.maingrp_code 
			LET l_arr_maingrp[l_idx].desc_text = l_rec_maingrp.desc_text 
		END FOREACH 

		MESSAGE kandoomsg2("U",9113,l_idx)	#l_idx records selected
		IF l_idx = 0 THEN 
			LET l_idx = 1 
			INITIALIZE l_arr_maingrp[1].* TO NULL 
		END IF 

		WHENEVER ERROR stop 
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

		MESSAGE kandoomsg2("U",1006,"") 	#1006 " ESC on line TO SELECT - F10 TO Add"
		DISPLAY ARRAY l_arr_maingrp TO sr_maingrp.* ATTRIBUTE(UNBUFFERED) 
			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","mgrpwind","input-arr-maingrp") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			BEFORE ROW 
				LET l_idx = arr_curr() 
				LET l_rec_maingrp.maingrp_code = l_arr_maingrp[l_idx].maingrp_code
				
			ON KEY (F10) 
				CALL run_prog("IZM","","","","") --main product GROUP maintenance 

		END DISPLAY 
		---------------------------------------------------------------------

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		ELSE 
			EXIT WHILE 
		END IF 

	END WHILE 

	CLOSE WINDOW I602 

	RETURN l_rec_maingrp.maingrp_code 
END FUNCTION 
################################################################################
# END FUNCTION show_maingrp(p_cmpy,p_filter_text)
################################################################################