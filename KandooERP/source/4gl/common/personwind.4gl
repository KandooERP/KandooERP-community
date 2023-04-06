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



#   personwind.4gl - show_person
#                    Window FUNCTION FOR finding person records FOR timesheets
#                    Returns person_code.
GLOBALS "../common/glob_GLOBALS.4gl" 

FUNCTION show_person(p_cmpy) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE l_msgresp LIKE language.yes_flag
	DEFINE l_rec_person RECORD LIKE person.* 
	DEFINE l_arr_person array[100] OF RECORD 
		scroll_flag CHAR(1), 
		person_code LIKE person.person_code, 
		name_text LIKE person.name_text, 
		dept_code LIKE person.dept_code, 
		task_period_ind LIKE person.task_period_ind 
	END RECORD
	DEFINE l_idx,l_scrn SMALLINT 
	DEFINE l_query_text CHAR(2200) 
	DEFINE l_where_text CHAR(2048) 

	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 
	OPEN WINDOW j192 with FORM "J192" 
	CALL windecoration_j("J192") -- albo kd-767 

	WHILE true 
		CLEAR FORM 
		LET l_msgresp = kandoomsg("U",1001,"") 
		#1001 " Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON person_code, 
		name_text, 
		dept_code, 
		task_period_ind 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","personwind","construct-person") 
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
		END CONSTRUCT 


		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_rec_person.person_code = NULL 
			EXIT WHILE 
		END IF 
		LET l_msgresp = kandoomsg("U",1002,"") 
		#1002 " Searching database - please wait"
		LET l_query_text = "SELECT * FROM person ", 
		"WHERE cmpy_code = '",p_cmpy,"' ", 
		"AND ",l_where_text CLIPPED," ", 
		"ORDER BY person_code" 
		WHENEVER ERROR CONTINUE 
		OPTIONS SQL interrupt ON 
		PREPARE s_person FROM l_query_text 
		DECLARE c_person CURSOR FOR s_person 
		LET l_idx = 0 
		FOREACH c_person INTO l_rec_person.* 
			LET l_idx = l_idx + 1 
			LET l_arr_person[l_idx].scroll_flag = NULL 
			LET l_arr_person[l_idx].person_code = l_rec_person.person_code 
			LET l_arr_person[l_idx].name_text = l_rec_person.name_text 
			LET l_arr_person[l_idx].dept_code = l_rec_person.dept_code 
			LET l_arr_person[l_idx].task_period_ind = l_rec_person.task_period_ind 
			IF l_idx = 100 THEN 
				LET l_msgresp = kandoomsg("U",6100,l_idx) 
				EXIT FOREACH 
			END IF 
		END FOREACH 
		LET l_msgresp=kandoomsg("U",9113,l_idx) 
		#U9113 l_idx records selected
		IF l_idx = 0 THEN 
			LET l_idx = 1 
			INITIALIZE l_arr_person[1].* TO NULL 
		END IF 
		WHENEVER ERROR stop 
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

		LET l_msgresp = kandoomsg("U",1006,"") 
		#1006 " ESC on line TO SELECT - F10 TO Add"
		CALL set_count(l_idx) 
		INPUT ARRAY l_arr_person WITHOUT DEFAULTS FROM sr_person.* 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","personwind","input-arr-person") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 


			BEFORE ROW 
				LET l_idx = arr_curr() 
				LET l_scrn = scr_line() 
				IF l_arr_person[l_idx].person_code IS NOT NULL THEN 
					DISPLAY l_arr_person[l_idx].* TO sr_person[l_scrn].* 

				END IF 
				NEXT FIELD scroll_flag 
			ON KEY (F10) 
				CALL run_prog("J83","","","","") 
				NEXT FIELD scroll_flag 
			AFTER FIELD scroll_flag 
				LET l_arr_person[l_idx].scroll_flag = NULL 
				IF fgl_lastkey() = fgl_keyval("down") 
				AND arr_curr() >= arr_count() THEN 
					LET l_msgresp = kandoomsg("U",9001,"") 
					NEXT FIELD scroll_flag 
				END IF 
			BEFORE FIELD person_code 
				LET l_rec_person.person_code = l_arr_person[l_idx].person_code 
				EXIT INPUT 
			AFTER ROW 
				DISPLAY l_arr_person[l_idx].* TO sr_person[l_scrn].* 

			AFTER INPUT 
				LET l_rec_person.person_code = l_arr_person[l_idx].person_code 

		END INPUT 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		ELSE 
			EXIT WHILE 
		END IF 
	END WHILE 
	CLOSE WINDOW j192 
	RETURN l_rec_person.person_code 
END FUNCTION 


