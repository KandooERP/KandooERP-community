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

	Source code beautified by beautify.pl on 2020-01-02 10:35:18	$Id: $
}



#   lablwind.4gl - show_label
#                  Window FUNCTION FOR finding a labelhead record
#                  FUNCTION will RETURN label_code TO calling program
GLOBALS "../common/glob_GLOBALS.4gl" 

FUNCTION show_label(p_cmpy) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE pr_labelhead RECORD LIKE labelhead.* 
	DEFINE l_arr_labelhead ARRAY[100] OF RECORD 
				scroll_flag CHAR(1), 
				label_code LIKE labelhead.label_code, 
				desc_text LIKE labelhead.desc_text 
			 END RECORD 
	DEFINE l_idx,l_scrn SMALLINT 
	DEFINE l_query_text CHAR(2200) 
	DEFINE l_where_text CHAR(2048) 

	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 
	OPEN WINDOW i632 with FORM "I632" 
	CALL windecoration_i("I632") -- albo kd-767 

	WHILE true 
		CLEAR FORM 
		LET l_msgresp = kandoomsg("U",1001,"") 
		#1001 " Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON label_code, 
		desc_text 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","lablwind","construct-labelhead") 
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
		END CONSTRUCT 


		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET pr_labelhead.label_code = NULL 
			EXIT WHILE 
		END IF 
		LET l_msgresp = kandoomsg("U",1002,"") 
		#1002 " Searching database - please wait"
		LET l_query_text = "SELECT * FROM labelhead ", 
		"WHERE cmpy_code = '", p_cmpy, "' ", 
		"AND ", l_where_text CLIPPED," ", 
		"ORDER BY label_code" 
		WHENEVER ERROR CONTINUE 
		OPTIONS SQL interrupt ON 
		PREPARE s_labelhead FROM l_query_text 
		DECLARE c_labelhead CURSOR FOR s_labelhead 
		LET l_idx = 0 
		FOREACH c_labelhead INTO pr_labelhead.* 
			LET l_idx = l_idx + 1 
			LET l_arr_labelhead[l_idx].label_code = pr_labelhead.label_code 
			LET l_arr_labelhead[l_idx].desc_text = pr_labelhead.desc_text 
			IF l_idx = 100 THEN 
				LET l_msgresp = kandoomsg("U",6100,l_idx) 
				EXIT FOREACH 
			END IF 
		END FOREACH 
		LET l_msgresp = kandoomsg("U",9113,l_idx) 
		#U9113 l_idx records selected
		IF l_idx = 0 THEN 
			LET l_idx = 1 
			INITIALIZE l_arr_labelhead[1].* TO NULL 
		END IF 
		WHENEVER ERROR stop 
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 

		LET l_msgresp = kandoomsg("U",1006,"") 
		#1006 " ESC on line TO SELECT - F10 TO add
		CALL set_count(l_idx) 
		INPUT ARRAY l_arr_labelhead WITHOUT DEFAULTS FROM sr_labelhead.* 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","lablwind","input-arr-labelhead") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 


			BEFORE ROW 
				LET l_idx = arr_curr() 
				LET l_scrn = scr_line() 
				IF l_arr_labelhead[l_idx].label_code IS NOT NULL THEN 
					DISPLAY l_arr_labelhead[l_idx].* TO sr_labelhead[l_scrn].* 

				END IF 
				NEXT FIELD scroll_flag 
			AFTER FIELD scroll_flag 
				LET l_arr_labelhead[l_idx].scroll_flag = NULL 
				IF fgl_lastkey() = fgl_keyval("down") 
				AND arr_curr() >= arr_count() THEN 
					LET l_msgresp = kandoomsg("U",9001,"") 
					NEXT FIELD scroll_flag 
				END IF 
			BEFORE FIELD label_code 
				LET pr_labelhead.label_code = l_arr_labelhead[l_idx].label_code 
				EXIT INPUT 
			ON KEY (F10) 
				CALL run_prog("IZL","","","","") 
			AFTER ROW 
				DISPLAY l_arr_labelhead[l_idx].* TO sr_labelhead[l_scrn].* 

			AFTER INPUT 
				LET pr_labelhead.label_code = l_arr_labelhead[l_idx].label_code 

		END INPUT 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		ELSE 
			EXIT WHILE 
		END IF 
	END WHILE 
	CLOSE WINDOW i632 
	RETURN pr_labelhead.label_code 
END FUNCTION 


