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
	Source code beautified by beautify.pl on 2020-01-02 10:35:16	$Id: $
}
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 


############################################################
# FUNCTION show_jobvars(p_cmpy, p_job_code)
#
#         jobvarwind.4gl - show_jobvars
#                          Windows FUNCTION FOR finding job record
#                          FUNCTION will RETURN var_code
############################################################
FUNCTION show_jobvars(p_cmpy,p_job_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_job_code LIKE jobvars.job_code 
	DEFINE l_rec_job RECORD LIKE job.* 
	DEFINE l_rec_jobvars RECORD LIKE jobvars.* 
	DEFINE l_arr_rec_jobvars ARRAY[100] OF 
				RECORD 
					scroll_flag CHAR(1), 
					var_code LIKE jobvars.var_code, 
					title_text LIKE jobvars.title_text, 
					appro_date LIKE jobvars.appro_date 
				END RECORD 
	DEFINE l_idx,l_scrn SMALLINT 
	DEFINE l_query_text CHAR(2200) 
	DEFINE l_where_text CHAR(2048) 
	DEFINE l_msgresp LIKE language.yes_flag 

	SELECT title_text INTO l_rec_job.title_text 
	FROM job 
	WHERE cmpy_code = p_cmpy 
	AND job_code = p_job_code 
	IF status = notfound THEN 
		LET l_msgresp = kandoomsg("J",9628,"") 
		RETURN "" 
	END IF 

	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 

	OPEN WINDOW j119 with FORM "J119" 
	CALL winDecoration_j("J119") -- albo kd-756 
	WHILE true 
		CLEAR FORM 
		DISPLAY p_job_code, 
		l_rec_job.title_text 
		TO job.job_code, 
		job_title_text 

		LET l_msgresp = kandoomsg("U",1001,"") 
		#1001 " Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON var_code, 
		title_text, 
		appro_date 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","jobvarwind","construct-jobvars") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_rec_jobvars.var_code = NULL 
			EXIT WHILE 
		END IF 
		LET l_msgresp = kandoomsg("U",1002,"") 
		#1002 " Searching database - please wait"
		LET l_query_text = "SELECT * FROM jobvars ", 
		"WHERE cmpy_code = '",p_cmpy,"' ", 
		"AND ",l_where_text clipped," ", 
		"AND job_code = '",p_job_code,"' ", 
		"ORDER BY var_code" 
		WHENEVER ERROR CONTINUE 
		OPTIONS SQL interrupt ON 
		PREPARE s_jobvars FROM l_query_text 
		DECLARE c_jobvars CURSOR FOR s_jobvars 
		LET l_idx = 0 
		FOREACH c_jobvars INTO l_rec_jobvars.* 
			LET l_idx = l_idx + 1 
			LET l_arr_rec_jobvars[l_idx].var_code = l_rec_jobvars.var_code 
			LET l_arr_rec_jobvars[l_idx].title_text = l_rec_jobvars.title_text 
			LET l_arr_rec_jobvars[l_idx].appro_date = l_rec_jobvars.appro_date 
			IF l_idx = 100 THEN 
				LET l_msgresp = kandoomsg("U",6100,l_idx) 
				EXIT FOREACH 
			END IF 
		END FOREACH 

		LET l_msgresp=kandoomsg("U",9113,l_idx) 
		#U9113 l_idx records selected
		IF l_idx = 0 THEN 
			LET l_idx = 1 
			INITIALIZE l_arr_rec_jobvars[1].* TO NULL 
		END IF 
		WHENEVER ERROR stop 
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 


		LET l_msgresp = kandoomsg("U",1006,"") 
		#1006 " ESC on line TO SELECT - F10 TO Add"
		CALL set_count(l_idx) 
		INPUT ARRAY l_arr_rec_jobvars WITHOUT DEFAULTS FROM sr_jobvars.* 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","jobvarwind","input-arr-jobmvars") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			BEFORE ROW 
				LET l_idx = arr_curr() 
				LET l_scrn = scr_line() 
				IF l_arr_rec_jobvars[l_idx].var_code IS NOT NULL THEN 
					DISPLAY l_arr_rec_jobvars[l_idx].* TO sr_jobvars[l_scrn].* 

				END IF 
				NEXT FIELD scroll_flag 

			ON KEY (F10) 
				CALL run_prog("J61","","","","") 
				NEXT FIELD scroll_flag 

			AFTER FIELD scroll_flag 
				IF fgl_lastkey() = fgl_keyval("down") 
				AND arr_curr() >= arr_count() THEN 
					LET l_msgresp = kandoomsg("U",9001,"") 
					NEXT FIELD scroll_flag 
				END IF 

			BEFORE FIELD var_code 
				LET l_rec_jobvars.var_code = l_arr_rec_jobvars[l_idx].var_code 
				EXIT INPUT 

			AFTER ROW 
				DISPLAY l_arr_rec_jobvars[l_idx].* TO sr_jobvars[l_scrn].* 

			AFTER INPUT 
				LET l_rec_jobvars.var_code = l_arr_rec_jobvars[l_idx].var_code 

		END INPUT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_rec_jobvars.var_code = "" 
		ELSE 
			EXIT WHILE 
		END IF 
	END WHILE 

	CLOSE WINDOW j119 

	RETURN l_rec_jobvars.var_code 
END FUNCTION 


