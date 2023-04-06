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

	Source code beautified by beautify.pl on 2020-01-02 10:35:22	$Id: $
}



#   pdeptwind.4gl - show_deptgrp
#                   Window FUNCTION FOR finding proddept records
#                   FUNCTION will RETURN dept_code TO calling program
#                   filter will always be 1 FOR department
#                                         2 FOR subdepartment
GLOBALS "../common/glob_GLOBALS.4gl" 

FUNCTION show_deptgrp(p_cmpy,p_filter_text) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_filter_text CHAR(300)
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_proddept RECORD LIKE proddept.* 
	DEFINE l_arr_proddept ARRAY[100] OF RECORD 
		scroll_flag CHAR(1), 
		dept_code LIKE proddept.dept_code, 
		desc_text LIKE proddept.desc_text 
	END RECORD
	DEFINE l_idx,l_scrn SMALLINT 
	DEFINE l_query_text CHAR(2200) 
	DEFINE l_where_text CHAR(2048) 

	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 
	IF p_filter_text IS NULL THEN 
		LET p_filter_text = "1=1" 
	END IF 
	OPEN WINDOW i609 with FORM "I609" 
	CALL windecoration_i("I609") -- albo kd-758 
	WHILE true 
		CLEAR FORM 
		LET l_msgresp = kandoomsg("U",1001,"") 
		#1001 " Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON dept_code, 
		desc_text 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","pdeptwind","construct-proddept") 
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
		END CONSTRUCT 


		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_rec_proddept.dept_code = NULL 
			EXIT WHILE 
		END IF 
		LET l_msgresp = kandoomsg("U",1002,"") 
		#1002 " Searching database - please wait"
		LET l_query_text = "SELECT * FROM proddept ", 
		"WHERE cmpy_code = \"",p_cmpy,"\" ", 
		"AND ",l_where_text CLIPPED," ", 
		"AND ",p_filter_text CLIPPED," ", 
		"ORDER BY dept_code" 
		WHENEVER ERROR CONTINUE 
		OPTIONS SQL interrupt ON 
		PREPARE s_deptgrp FROM l_query_text 
		DECLARE c_deptgrp CURSOR FOR s_deptgrp 
		LET l_idx = 0 
		FOREACH c_deptgrp INTO l_rec_proddept.* 
			LET l_idx = l_idx + 1 
			LET l_arr_proddept[l_idx].dept_code = l_rec_proddept.dept_code 
			LET l_arr_proddept[l_idx].desc_text = l_rec_proddept.desc_text 
			IF l_idx = 100 THEN 
				LET l_msgresp = kandoomsg("U",9113,l_idx) 
				EXIT FOREACH 
			END IF 
		END FOREACH 
		LET l_msgresp = kandoomsg("U",9113,l_idx) 
		#9113 " l_idx records selected "
		IF l_idx = 0 THEN 
			LET l_idx = 1 
			INITIALIZE l_arr_proddept[1].* TO NULL 
		END IF 
		WHENEVER ERROR stop 
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 

		LET l_msgresp = kandoomsg("U",1006,"") 
		#1006 " ESC on line TO SELECT - F10 TO Add"
		CALL set_count(l_idx) 
		INPUT ARRAY l_arr_proddept WITHOUT DEFAULTS FROM sr_proddept.* ATTRIBUTE(UNBUFFERED) 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","pdeptwind","input-arr-proddept") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 


			BEFORE ROW 
				LET l_idx = arr_curr() 
				LET l_scrn = scr_line() 
				IF l_arr_proddept[l_idx].dept_code IS NOT NULL THEN 
					DISPLAY l_arr_proddept[l_idx].* TO sr_proddept[l_scrn].* 

				END IF 
				NEXT FIELD scroll_flag 
			ON KEY (F10) 
				CALL run_prog("IZD","","","","") 
				NEXT FIELD scroll_flag 
			AFTER FIELD scroll_flag 
				LET l_arr_proddept[l_idx].scroll_flag = NULL 
				IF fgl_lastkey() = fgl_keyval("down") 
				AND arr_curr() >= arr_count() THEN 
					LET l_msgresp=kandoomsg("U",9001,"") 
					NEXT FIELD scroll_flag 
				END IF 
			BEFORE FIELD dept_code 
				LET l_rec_proddept.dept_code = l_arr_proddept[l_idx].dept_code 
				EXIT INPUT 
			AFTER ROW 
				DISPLAY l_arr_proddept[l_idx].* TO sr_proddept[l_scrn].* 

			AFTER INPUT 
				LET l_rec_proddept.dept_code = l_arr_proddept[l_idx].dept_code 

		END INPUT 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		ELSE 
			EXIT WHILE 
		END IF 
	END WHILE 
	CLOSE WINDOW i609 

	RETURN l_rec_proddept.dept_code 
END FUNCTION 


