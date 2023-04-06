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


#   subdwind.4gl - show_sub_dates
#                  Window FUNCTION FOR finding subissues records
#                  FUNCTION will RETURN issue_num TO calling program
#   FUNCTION IS called with p_mode variable.
#       p_mode = 0 CONSTRUCT on all fields
#       p_mode = 1 no CONSTRUCT - query criteria passed by calling program
GLOBALS "../common/glob_GLOBALS.4gl" 

FUNCTION show_sub_dates(p_cmpy,p_filter_text,p_mode) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_filter_text CHAR(200)
	DEFINE p_mode SMALLINT
	DEFINE l_msgresp LIKE language.yes_flag
	DEFINE l_rec_subproduct RECORD LIKE subproduct.*
	DEFINE l_rec_subissues RECORD LIKE subissues.*
	DEFINE l_arr_subissues ARRAY[100] OF RECORD
		scroll_flag CHAR(1), 
		plan_iss_date LIKE subissues.plan_iss_date, 
		desc_text LIKE subissues.desc_text, 
		issue_num LIKE subissues.issue_num, 
		act_iss_date LIKE subissues.act_iss_date 
	END RECORD 
	DEFINE l_arr_2_subissues ARRAY[100] OF RECORD 
		part_code CHAR(1), 
		desc_text LIKE subproduct.desc_text, 
		type_code LIKE subissues.type_code, 
		start_date LIKE subissues.start_date, 
		end_date LIKE subissues.end_date 
	END RECORD 
	DEFINE l_idx,l_scrn SMALLINT
	DEFINE l_query_text CHAR(2200)
	DEFINE l_where_text CHAR(2048) 

	IF p_filter_text IS NULL THEN 
		LET p_filter_text = "1=1" 
	END IF 
	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 
	OPEN WINDOW k145 with FORM "K145" 
	CALL windecoration_k("K145") -- albo kd-767 
	WHILE true 
		CLEAR FORM 
		LET l_where_text = NULL 
		IF p_mode = 0 THEN 
			LET l_msgresp = kandoomsg("U",1001,"") 
			#1001 " Enter Selection Criteria - ESC TO Continue"
			CONSTRUCT l_where_text ON subissues.part_code, 
			subissues.type_code, 
			subissues.start_date, 
			subissues.end_date, 
			subissues.plan_iss_date, 
			subissues.desc_text, 
			subissues.issue_num, 
			subissues.act_iss_date 
			FROM subissues.part_code, 
			subissues.type_code, 
			subissues.start_date, 
			subissues.end_date, 
			sr_dates[1].plan_iss_date, 
			sr_dates[1].desc_text, 
			sr_dates[1].issue_num, 
			sr_dates[1].act_iss_date 


				BEFORE CONSTRUCT 
					CALL publish_toolbar("kandoo","subiwind","construct-subissues") 
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
			END CONSTRUCT 


			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
				LET l_rec_subissues.part_code = NULL 
				EXIT WHILE 
			END IF 
		END IF 
		LET l_msgresp = kandoomsg("U",1002,"") 
		#1002 " Searching database - please wait"
		LET l_query_text = "SELECT * FROM subissues ", 
		"WHERE cmpy_code= '",p_cmpy,"' ", 
		"AND ",l_where_text CLIPPED," ", 
		"AND ",p_filter_text CLIPPED," ", 
		"ORDER BY part_code,issue_num" 
		WHENEVER ERROR CONTINUE 
		OPTIONS SQL interrupt ON 
		PREPARE s_subissues FROM l_query_text 
		DECLARE c_subissues CURSOR FOR s_subissues 
		LET l_idx = 0 
		FOREACH c_subissues INTO l_rec_subissues.* 
			LET l_idx = l_idx + 1 
			LET l_arr_subissues[l_idx].plan_iss_date = l_rec_subissues.plan_iss_date 
			LET l_arr_subissues[l_idx].desc_text = l_rec_subissues.desc_text 
			LET l_arr_subissues[l_idx].issue_num = l_rec_subissues.issue_num 
			LET l_arr_subissues[l_idx].act_iss_date = l_rec_subissues.act_iss_date 
			SELECT * INTO l_rec_subproduct.* 
			FROM subproduct 
			WHERE cmpy_code = p_cmpy 
			AND part_code = l_rec_subissues.part_code 
			LET l_arr_2_subissues[l_idx].part_code = l_rec_subissues.part_code 
			LET l_arr_2_subissues[l_idx].desc_text = l_rec_subproduct.desc_text 
			LET l_arr_2_subissues[l_idx].type_code = l_rec_subissues.type_code 
			LET l_arr_2_subissues[l_idx].start_date = l_rec_subissues.start_date 
			LET l_arr_2_subissues[l_idx].end_date = l_rec_subissues.end_date 
			IF l_idx = 100 THEN 
				LET l_msgresp = kandoomsg("U",6100,l_idx) 
				EXIT FOREACH 
			END IF 
		END FOREACH 
		LET l_msgresp = kandoomsg("U",9113,l_idx) 
		#9113 "l_idx records selected"
		IF l_idx = 0 THEN 
			LET l_idx = 1 
			INITIALIZE l_arr_subissues[1].* TO NULL 
		END IF 
		WHENEVER ERROR stop 
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
		LET l_msgresp = kandoomsg("U",1006,"") 
		#1006 " ESC on line TO SELECT - F10 TO Add"
		CALL set_count(l_idx) 
		INPUT ARRAY l_arr_subissues WITHOUT DEFAULTS FROM sr_dates.* 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","subiwind","input-arr-subissues") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			BEFORE ROW 
				LET l_idx = arr_curr() 
				LET l_scrn = scr_line() 
				IF l_arr_subissues[l_idx].plan_iss_date IS NOT NULL THEN 
					DISPLAY l_arr_subissues[l_idx].* TO sr_dates[l_scrn].* 

					DISPLAY l_arr_2_subissues[l_idx].part_code, 
					l_arr_2_subissues[l_idx].desc_text, 
					l_arr_2_subissues[l_idx].type_code, 
					l_arr_2_subissues[l_idx].start_date, 
					l_arr_2_subissues[l_idx].end_date 
					TO part_code, 
					sub_text, 
					type_code, 
					start_date, 
					end_date 

				END IF 
				NEXT FIELD scroll_flag 
			ON KEY (F10) 
				CALL run_prog("KZ2","","","","") 
				NEXT FIELD scroll_flag 
			AFTER FIELD scroll_flag 
				LET l_arr_subissues[l_idx].scroll_flag = NULL 
				IF fgl_lastkey() = fgl_keyval("down") 
				AND arr_curr() >= arr_count() THEN 
					LET l_msgresp = kandoomsg("U",9001,"") 
					NEXT FIELD scroll_flag 
				END IF 
			BEFORE FIELD plan_iss_date 
				LET l_rec_subissues.issue_num = l_arr_subissues[l_idx].issue_num 
				EXIT INPUT 
			AFTER ROW 
				DISPLAY l_arr_subissues[l_idx].* TO sr_dates[l_scrn].* 

			AFTER INPUT 
				LET l_rec_subissues.issue_num = l_arr_subissues[l_idx].issue_num 

		END INPUT 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_rec_subissues.issue_num = NULL 
			EXIT WHILE 
		ELSE 
			EXIT WHILE 
		END IF 
	END WHILE 
	CLOSE WINDOW k145 
	RETURN l_rec_subissues.issue_num 
END FUNCTION 


