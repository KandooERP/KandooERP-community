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
	Source code beautified by beautify.pl on 2020-01-02 10:35:17	$Id: $
}
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

############################################################
# FUNCTION show_job(p_cmpy)
#
#        jobwind.4gl - show_job: Displays all available jobs
#                      showujobs: Displays all jobs user has access TO
#                      showpjobs: Show only public jobs that user has access TO
#                      showmjobs: Show only master jobs that user has access TO
############################################################
FUNCTION show_job(p_cmpy) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE l_rec_job RECORD LIKE job.* 
	DEFINE l_arr_rec_job array[300] OF 
				RECORD 
					scroll_flag CHAR(1), 
					job_code LIKE job.job_code, 
					title_text LIKE job.title_text, 
					type_code LIKE job.type_code, 
					cust_code LIKE job.cust_code, 
					locked_ind LIKE job.locked_ind 
				END RECORD 
	DEFINE l_idx,l_scrn SMALLINT 
	DEFINE l_query_text CHAR(2200) 
	DEFINE l_where_text CHAR(2048) 
	DEFINE l_msgresp LIKE language.yes_flag 

	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 

	OPEN WINDOW j111 with FORM "J111" 
	CALL winDecoration_j("J111") -- albo kd-758 
	WHILE true 
		CLEAR FORM 
		LET l_msgresp = kandoomsg("U",1001,"") 
		#1001 " Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON job_code, 
		title_text, 
		type_code, 
		cust_code, 
		locked_ind 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","jobwind","construct-job-1") 
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_rec_job.job_code = NULL 
			EXIT WHILE 
		END IF 
		LET l_msgresp = kandoomsg("U",1002,"") 
		#1002 " Searching database - please wait"
		LET l_query_text = "SELECT * FROM job ", 
		" WHERE cmpy_code = '",p_cmpy,"' ", 
		" AND ",l_where_text clipped," ", 
		" ORDER BY job_code" 
		WHENEVER ERROR CONTINUE 
		OPTIONS SQL interrupt ON 
		PREPARE s_job FROM l_query_text 
		DECLARE c_job CURSOR FOR s_job 
		LET l_idx = 0 
		FOREACH c_job INTO l_rec_job.* 
			LET l_idx = l_idx + 1 
			LET l_arr_rec_job[l_idx].job_code = l_rec_job.job_code 
			LET l_arr_rec_job[l_idx].title_text = l_rec_job.title_text 
			LET l_arr_rec_job[l_idx].type_code = l_rec_job.type_code 
			LET l_arr_rec_job[l_idx].cust_code = l_rec_job.cust_code 
			LET l_arr_rec_job[l_idx].locked_ind = l_rec_job.locked_ind 
			IF l_idx = 300 THEN 
				LET l_msgresp = kandoomsg("U",6100,l_idx) 
				EXIT FOREACH 
			END IF 
		END FOREACH 
		LET l_msgresp=kandoomsg("U",9113,l_idx) 
		#U9113 l_idx records selected
		IF l_idx = 0 THEN 
			LET l_idx = 1 
			INITIALIZE l_arr_rec_job[1].* TO NULL 
		END IF 
		WHENEVER ERROR stop 
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 

		LET l_msgresp = kandoomsg("U",1006,"") 
		#1006 " ESC on line TO SELECT - F10 TO Add"
		CALL set_count(l_idx) 
		INPUT ARRAY l_arr_rec_job WITHOUT DEFAULTS FROM sr_job.* 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","jobwind","input-arr-job-1") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			BEFORE ROW 
				LET l_idx = arr_curr() 
				LET l_scrn = scr_line() 
				IF l_arr_rec_job[l_idx].job_code IS NOT NULL THEN 
					DISPLAY l_arr_rec_job[l_idx].* TO sr_job[l_scrn].* 

				END IF 
				NEXT FIELD scroll_flag 
			ON KEY (F10) 
				CALL run_prog("J11","","","","") 
				NEXT FIELD scroll_flag 
			AFTER FIELD scroll_flag 
				LET l_arr_rec_job[l_idx].scroll_flag = NULL 
				IF fgl_lastkey() = fgl_keyval("down") 
				AND arr_curr() >= arr_count() THEN 
					LET l_msgresp = kandoomsg("U",9001,"") 
					NEXT FIELD scroll_flag 
				END IF 
			BEFORE FIELD job_code 
				IF l_arr_rec_job[l_idx].job_code IS NOT NULL THEN 
					CALL run_prog("J12",l_arr_rec_job[l_idx].job_code,"","","") 
					OPTIONS INSERT KEY f36, 
					DELETE KEY f36 
				END IF 
				NEXT FIELD scroll_flag 
			AFTER ROW 
				DISPLAY l_arr_rec_job[l_idx].* TO sr_job[l_scrn].* 

			AFTER INPUT 
				LET l_rec_job.job_code = l_arr_rec_job[l_idx].job_code 

		END INPUT 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		ELSE 
			EXIT WHILE 
		END IF 
	END WHILE 

	CLOSE WINDOW j111 

	RETURN l_rec_job.job_code 
END FUNCTION 


############################################################
# FUNCTION showujobs(p_cmpy,p_acct_mask_code)
#
#
############################################################
FUNCTION showujobs(p_cmpy,p_acct_mask_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_acct_mask_code LIKE kandoouser.acct_mask_code 
	DEFINE l_rec_job RECORD LIKE job.* 
	DEFINE l_arr_rec_job array[300] OF 
	RECORD 
		scroll_flag CHAR(1), 
		job_code LIKE job.job_code, 
		title_text LIKE job.title_text, 
		type_code LIKE job.type_code, 
		cust_code LIKE job.cust_code, 
		locked_ind LIKE job.locked_ind 
	END RECORD 
	DEFINE l_idx,l_scrn SMALLINT 
	DEFINE l_query_text CHAR(800) 
	DEFINE l_where_text CHAR(400) 
	DEFINE l_msgresp LIKE language.yes_flag 

	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 

	OPEN WINDOW j111 with FORM "J111" 
	CALL windecoration_j("J111") -- albo kd-758 
	WHILE true 
		CLEAR FORM 
		LET l_msgresp = kandoomsg("U",1001,"") 
		#1001 " Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON job_code, 
		title_text, 
		type_code, 
		cust_code, 
		locked_ind 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","jobwind","construct-job-2") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END CONSTRUCT 


		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_rec_job.job_code = NULL 
			EXIT WHILE 
		END IF 
		LET l_msgresp = kandoomsg("U",1002,"") 
		#1002 " Searching database - please wait"
		LET l_query_text = "SELECT * FROM job ", 
		" WHERE cmpy_code = '",p_cmpy,"' ", 
		" AND ",l_where_text clipped," ", 
		" AND (job.acct_code matches \"",p_acct_mask_code,"\"", 
		" OR locked_ind <= \"1\")", 
		" ORDER BY job_code" 
		WHENEVER ERROR CONTINUE 
		OPTIONS SQL interrupt ON 
		PREPARE s_job1 FROM l_query_text 
		DECLARE c_job1 CURSOR FOR s_job1 
		LET l_idx = 0 
		FOREACH c_job1 INTO l_rec_job.* 
			LET l_idx = l_idx + 1 
			LET l_arr_rec_job[l_idx].job_code = l_rec_job.job_code 
			LET l_arr_rec_job[l_idx].title_text = l_rec_job.title_text 
			LET l_arr_rec_job[l_idx].type_code = l_rec_job.type_code 
			LET l_arr_rec_job[l_idx].cust_code = l_rec_job.cust_code 
			LET l_arr_rec_job[l_idx].locked_ind = l_rec_job.locked_ind 
			IF l_idx = 300 THEN 
				LET l_msgresp = kandoomsg("U",6100,l_idx) 
				EXIT FOREACH 
			END IF 
		END FOREACH 
		LET l_msgresp=kandoomsg("U",9113,l_idx) 
		#U9113 l_idx records selected
		IF l_idx = 0 THEN 
			LET l_idx = 1 
			INITIALIZE l_arr_rec_job[1].* TO NULL 
		END IF 
		WHENEVER ERROR stop 
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 

		LET l_msgresp = kandoomsg("U",1006,"") 
		#1006 " ESC on line TO SELECT - F10 TO Add"
		CALL set_count(l_idx) 
		INPUT ARRAY l_arr_rec_job WITHOUT DEFAULTS FROM sr_job.* 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","jobwind","input-arr-job-2") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 


			BEFORE ROW 
				LET l_idx = arr_curr() 
				LET l_scrn = scr_line() 
				IF l_arr_rec_job[l_idx].job_code IS NOT NULL THEN 
					DISPLAY l_arr_rec_job[l_idx].* TO sr_job[l_scrn].* 

				END IF 
				NEXT FIELD scroll_flag 

			ON KEY (F10) 
				CALL run_prog("J11","","","","") 
				NEXT FIELD scroll_flag 

			AFTER FIELD scroll_flag 
				LET l_arr_rec_job[l_idx].scroll_flag = NULL 
				IF fgl_lastkey() = fgl_keyval("down") 
				AND arr_curr() >= arr_count() THEN 
					LET l_msgresp = kandoomsg("U",9001,"") 
					NEXT FIELD scroll_flag 
				END IF 

			BEFORE FIELD job_code 
				IF l_arr_rec_job[l_idx].job_code IS NOT NULL THEN 
					CALL run_prog("J12",l_arr_rec_job[l_idx].job_code,"","","") 
					OPTIONS INSERT KEY f36, 
					DELETE KEY f36 
				END IF 
				NEXT FIELD scroll_flag 

			AFTER ROW 
				DISPLAY l_arr_rec_job[l_idx].* TO sr_job[l_scrn].* 

			AFTER INPUT 
				LET l_rec_job.job_code = l_arr_rec_job[l_idx].job_code 

		END INPUT 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		ELSE 
			EXIT WHILE 
		END IF 
	END WHILE 
	CLOSE WINDOW j111 
	RETURN l_rec_job.job_code 
END FUNCTION 


############################################################
# FUNCTION showpjobs(p_cmpy,p_acct_mask_code)
#
#
############################################################
FUNCTION showpjobs(p_cmpy,p_acct_mask_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_acct_mask_code LIKE kandoouser.acct_mask_code 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_job RECORD LIKE job.* 
	DEFINE l_arr_rec_job array[300] OF 
	RECORD 
		scroll_flag CHAR(1), 
		job_code LIKE job.job_code, 
		title_text LIKE job.title_text, 
		type_code LIKE job.type_code, 
		cust_code LIKE job.cust_code, 
		locked_ind LIKE job.locked_ind 
	END RECORD 
	DEFINE l_idx,l_scrn SMALLINT 
	DEFINE l_query_text CHAR(800) 
	DEFINE l_where_text CHAR(400) 

	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 

	OPEN WINDOW j111 with FORM "J111" 
	CALL windecoration_j("J111") -- albo kd-758 
	WHILE true 
		CLEAR FORM 
		LET l_msgresp = kandoomsg("U",1001,"") 
		#1001 " Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON job_code, 
		title_text, 
		type_code, 
		cust_code, 
		locked_ind 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","jobwind","construct-job-3") 
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END CONSTRUCT 


		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_rec_job.job_code = NULL 
			EXIT WHILE 
		END IF 
		LET l_msgresp = kandoomsg("U",1002,"") 
		#1002 " Searching database - please wait"
		LET l_query_text = "SELECT * FROM job ", 
		" WHERE cmpy_code = '",p_cmpy,"' ", 
		" AND ",l_where_text clipped," ", 
		" AND (job.acct_code matches \"",p_acct_mask_code,"\"", 
		" AND locked_ind > \"0\")", 
		" ORDER BY job_code" 
		WHENEVER ERROR CONTINUE 
		OPTIONS SQL interrupt ON 
		PREPARE s_job2 FROM l_query_text 
		DECLARE c_job2 CURSOR FOR s_job2 
		LET l_idx = 0 
		FOREACH c_job2 INTO l_rec_job.* 
			LET l_idx = l_idx + 1 
			LET l_arr_rec_job[l_idx].job_code = l_rec_job.job_code 
			LET l_arr_rec_job[l_idx].title_text = l_rec_job.title_text 
			LET l_arr_rec_job[l_idx].type_code = l_rec_job.type_code 
			LET l_arr_rec_job[l_idx].cust_code = l_rec_job.cust_code 
			LET l_arr_rec_job[l_idx].locked_ind = l_rec_job.locked_ind 
			IF l_idx = 300 THEN 
				LET l_msgresp = kandoomsg("U",6100,l_idx) 
				EXIT FOREACH 
			END IF 
		END FOREACH 
		LET l_msgresp=kandoomsg("U",9113,l_idx) 
		#U9113 l_idx records selected
		IF l_idx = 0 THEN 
			LET l_idx = 1 
			INITIALIZE l_arr_rec_job[1].* TO NULL 
		END IF 
		WHENEVER ERROR stop 
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 

		LET l_msgresp = kandoomsg("U",1006,"") 
		#1006 " ESC on line TO SELECT - F10 TO Add"
		CALL set_count(l_idx) 
		INPUT ARRAY l_arr_rec_job WITHOUT DEFAULTS FROM sr_job.* 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","jobwind","input-arr-job-3") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 


			BEFORE ROW 
				LET l_idx = arr_curr() 
				LET l_scrn = scr_line() 
				IF l_arr_rec_job[l_idx].job_code IS NOT NULL THEN 
					DISPLAY l_arr_rec_job[l_idx].* TO sr_job[l_scrn].* 

				END IF 
				NEXT FIELD scroll_flag 
			ON KEY (F10) 
				CALL run_prog("J11","","","","") 
				NEXT FIELD scroll_flag 
			AFTER FIELD scroll_flag 
				LET l_arr_rec_job[l_idx].scroll_flag = NULL 
				IF fgl_lastkey() = fgl_keyval("down") 
				AND arr_curr() >= arr_count() THEN 
					LET l_msgresp = kandoomsg("U",9001,"") 
					NEXT FIELD scroll_flag 
				END IF 
			BEFORE FIELD job_code 
				IF l_arr_rec_job[l_idx].job_code IS NOT NULL THEN 
					CALL run_prog("J12",l_arr_rec_job[l_idx].job_code,"","","") 
					OPTIONS INSERT KEY f36, 
					DELETE KEY f36 
				END IF 
				NEXT FIELD scroll_flag 
			AFTER ROW 
				DISPLAY l_arr_rec_job[l_idx].* TO sr_job[l_scrn].* 

			AFTER INPUT 
				LET l_rec_job.job_code = l_arr_rec_job[l_idx].job_code 

		END INPUT 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		ELSE 
			EXIT WHILE 
		END IF 
	END WHILE 
	CLOSE WINDOW j111 
	RETURN l_rec_job.job_code 
END FUNCTION 



############################################################
# FUNCTION showmjobs(p_cmpy,p_acct_mask_code)
#
#
############################################################
FUNCTION showmjobs(p_cmpy,p_acct_mask_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_job RECORD LIKE job.* 
	DEFINE l_arr_rec_job array[300] OF 
	RECORD 
		scroll_flag CHAR(1), 
		job_code LIKE job.job_code, 
		title_text LIKE job.title_text, 
		type_code LIKE job.type_code, 
		cust_code LIKE job.cust_code, 
		locked_ind LIKE job.locked_ind 
	END RECORD 
	DEFINE l_idx,l_scrn SMALLINT 
	DEFINE p_acct_mask_code LIKE kandoouser.acct_mask_code 
	DEFINE l_query_text CHAR(800) 
	DEFINE l_where_text CHAR(400) 

	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 
	OPEN WINDOW j111 with FORM "J111" 
	CALL windecoration_j("J111") -- albo kd-758 
	WHILE true 
		CLEAR FORM 
		LET l_msgresp = kandoomsg("U",1001,"") 
		#1001 " Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON job_code, 
		title_text, 
		type_code, 
		cust_code, 
		locked_ind 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","jobwind","construct-job-4") 
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
		END CONSTRUCT 


		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_rec_job.job_code = NULL 
			EXIT WHILE 
		END IF 
		LET l_msgresp = kandoomsg("U",1002,"") 
		#1002 " Searching database - please wait"
		LET l_query_text = "SELECT * FROM job ", 
		" WHERE cmpy_code = '",p_cmpy,"' ", 
		" AND ",l_where_text clipped," ", 
		" AND locked_ind = '0' ", 
		" ORDER BY job_code" 
		WHENEVER ERROR CONTINUE 
		OPTIONS SQL interrupt ON 
		PREPARE s_job3 FROM l_query_text 
		DECLARE c_job3 CURSOR FOR s_job3 
		LET l_idx = 0 
		FOREACH c_job3 INTO l_rec_job.* 
			LET l_idx = l_idx + 1 
			LET l_arr_rec_job[l_idx].job_code = l_rec_job.job_code 
			LET l_arr_rec_job[l_idx].title_text = l_rec_job.title_text 
			LET l_arr_rec_job[l_idx].type_code = l_rec_job.type_code 
			LET l_arr_rec_job[l_idx].cust_code = l_rec_job.cust_code 
			LET l_arr_rec_job[l_idx].locked_ind = l_rec_job.locked_ind 
			IF l_idx = 300 THEN 
				LET l_msgresp = kandoomsg("U",6100,l_idx) 
				EXIT FOREACH 
			END IF 
		END FOREACH 
		LET l_msgresp=kandoomsg("U",9113,l_idx) 
		#U9113 l_idx records selected
		IF l_idx = 0 THEN 
			LET l_idx = 1 
			INITIALIZE l_arr_rec_job[1].* TO NULL 
		END IF 
		WHENEVER ERROR stop 
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 

		LET l_msgresp = kandoomsg("U",1006,"") 
		#1006 " ESC on line TO SELECT - F10 TO Add"
		CALL set_count(l_idx) 
		INPUT ARRAY l_arr_rec_job WITHOUT DEFAULTS FROM sr_job.* 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","jobwind","input-arr-job-4") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 


			BEFORE ROW 
				LET l_idx = arr_curr() 
				LET l_scrn = scr_line() 
				IF l_arr_rec_job[l_idx].job_code IS NOT NULL THEN 
					DISPLAY l_arr_rec_job[l_idx].* TO sr_job[l_scrn].* 

				END IF 
				NEXT FIELD scroll_flag 
			ON KEY (F10) 
				CALL run_prog("J11","","","","") 
				NEXT FIELD scroll_flag 
			AFTER FIELD scroll_flag 
				LET l_arr_rec_job[l_idx].scroll_flag = NULL 
				IF fgl_lastkey() = fgl_keyval("down") 
				AND arr_curr() >= arr_count() THEN 
					LET l_msgresp = kandoomsg("U",9001,"") 
					NEXT FIELD scroll_flag 
				END IF 
			BEFORE FIELD job_code 
				IF l_arr_rec_job[l_idx].job_code IS NOT NULL THEN 
					CALL run_prog("J12",l_arr_rec_job[l_idx].job_code,"","","") 
					OPTIONS INSERT KEY f36, 
					DELETE KEY f36 
				END IF 
				NEXT FIELD scroll_flag 
			AFTER ROW 
				DISPLAY l_arr_rec_job[l_idx].* TO sr_job[l_scrn].* 

			AFTER INPUT 
				LET l_rec_job.job_code = l_arr_rec_job[l_idx].job_code 

		END INPUT 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		ELSE 
			EXIT WHILE 
		END IF 
	END WHILE 

	CLOSE WINDOW j111 

	RETURN l_rec_job.job_code 
END FUNCTION 
