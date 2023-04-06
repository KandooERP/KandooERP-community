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

	Source code beautified by beautify.pl on 2020-01-02 10:35:36	$Id: $
}


#   subdwind.4gl - show_subhead
#                  Window FUNCTION FOR finding subhead records
#                  FUNCTION will RETURN sub_num TO calling program
GLOBALS "../common/glob_GLOBALS.4gl" 

FUNCTION show_subhead(p_cmpy,p_filter_text) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_filter_text CHAR(200)
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_subhead RECORD LIKE subhead.* 
	DEFINE l_arr_subhead array[100] OF RECORD 
		scroll_flag CHAR(1), 
		sub_num LIKE subhead.sub_num, 
		sub_type_code LIKE subhead.sub_type_code, 
		sub_date LIKE subhead.sub_date, 
		start_date LIKE subhead.start_date, 
		end_date LIKE subhead.end_date, 
		status_ind LIKE subhead.status_ind 
	END RECORD 
	DEFINE l_idx,l_scrn SMALLINT 
	DEFINE l_query_text CHAR(2200) 
	DEFINE l_where_text CHAR(2048) 

	IF p_filter_text IS NULL THEN 
		LET p_filter_text = "1=1" 
	END IF 
	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 
	OPEN WINDOW k137 with FORM "K137" 
	CALL windecoration_k("K137") -- albo kd-767 
	WHILE true 
		CLEAR FORM 
		LET l_where_text = NULL 
		LET l_msgresp = kandoomsg("U",1001,"") 
		#1001 " Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON sub_num, 
		sub_type_code, 
		sub_date, 
		start_date, 
		end_date, 
		status_ind 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","subhwind","construct-subhead") 
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
		END CONSTRUCT 


		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			EXIT WHILE 
		END IF 
		LET l_msgresp = kandoomsg("U",1002,"") 
		#1002 " Searching database - please wait"
		LET l_query_text = "SELECT * FROM subhead ", 
		"WHERE cmpy_code= '",p_cmpy,"' ", 
		"AND ",l_where_text CLIPPED," ", 
		"AND ",p_filter_text CLIPPED," ", 
		"ORDER BY sub_num" 
		WHENEVER ERROR CONTINUE 
		OPTIONS SQL interrupt ON 
		PREPARE s_subhead FROM l_query_text 
		DECLARE c_subhead CURSOR FOR s_subhead 
		LET l_idx = 0 
		FOREACH c_subhead INTO l_rec_subhead.* 
			LET l_idx = l_idx + 1 
			LET l_arr_subhead[l_idx].sub_type_code = l_rec_subhead.sub_type_code 
			LET l_arr_subhead[l_idx].sub_date = l_rec_subhead.sub_date 
			LET l_arr_subhead[l_idx].sub_num = l_rec_subhead.sub_num 
			LET l_arr_subhead[l_idx].start_date = l_rec_subhead.start_date 
			LET l_arr_subhead[l_idx].end_date = l_rec_subhead.end_date 
			LET l_arr_subhead[l_idx].status_ind = l_rec_subhead.status_ind 
			IF l_idx = 100 THEN 
				LET l_msgresp = kandoomsg("U",6100,l_idx) 
				EXIT FOREACH 
			END IF 
		END FOREACH 
		LET l_msgresp = kandoomsg("U",9113,l_idx) 
		#9113 "l_idx records selected"
		IF l_idx = 0 THEN 
			LET l_idx = 1 
			INITIALIZE l_arr_subhead[1].* TO NULL 
		END IF 
		WHENEVER ERROR stop 
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

		LET l_msgresp = kandoomsg("U",1006,"") 
		#1006 " ESC on line TO SELECT - F10 TO Add"
		CALL set_count(l_idx) 
		INPUT ARRAY l_arr_subhead WITHOUT DEFAULTS FROM sr_subhead.* 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","subhwind","input-arr-subhead") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			BEFORE ROW 
				LET l_idx = arr_curr() 
				LET l_scrn = scr_line() 
				IF l_arr_subhead[l_idx].sub_num IS NOT NULL THEN 
					DISPLAY l_arr_subhead[l_idx].* TO sr_subhead[l_scrn].* 

				END IF 
				NEXT FIELD scroll_flag 
			ON KEY (F10) 
				CALL run_prog("K11","","","","") 
				NEXT FIELD scroll_flag 
			AFTER FIELD scroll_flag 
				LET l_arr_subhead[l_idx].scroll_flag = NULL 
				IF fgl_lastkey() = fgl_keyval("down") 
				AND arr_curr() >= arr_count() THEN 
					LET l_msgresp = kandoomsg("U",9001,"") 
					NEXT FIELD scroll_flag 
				END IF 
			BEFORE FIELD sub_num 
				LET l_rec_subhead.sub_num = l_arr_subhead[l_idx].sub_num 
				EXIT INPUT 
			AFTER ROW 
				DISPLAY l_arr_subhead[l_idx].* TO sr_subhead[l_scrn].* 

			AFTER INPUT 
				LET l_rec_subhead.sub_num = l_arr_subhead[l_idx].sub_num 

		END INPUT 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		ELSE 
			EXIT WHILE 
		END IF 
	END WHILE 
	CLOSE WINDOW k137 
	RETURN l_rec_subhead.sub_num 
END FUNCTION 


