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
	Source code beautified by beautify.pl on 2020-01-02 10:35:03	$Id: $
}
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 


############################################################
# FUNCTION show_activity(p_cmpy, p_job_code, p_var_code)
#
# \brief module - actiwind
# Purpose - Activity Lookup Window FUNCTION FOR finding activity codes
#           FOR a given Job & Variation. FUNCTION returns activity_code
#           TO caller.
############################################################
FUNCTION show_activity(p_cmpy, p_job_code, p_var_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_job_code LIKE activity.job_code 
	DEFINE p_var_code LIKE activity.var_code 

	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_job RECORD LIKE job.* 
	DEFINE l_arr_rec_activity array[51] OF RECORD 
		activity_code LIKE activity.activity_code, 
		title_text LIKE activity.title_text, 
		resp_code LIKE activity.resp_code, 
		sort_text LIKE activity.sort_text, 
		est_end_date LIKE activity.est_end_date 
	END RECORD 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_jb_code CHAR(150) 
	DEFINE l_idx SMALLINT 
	DEFINE l_arr_size SMALLINT 
	DEFINE l_where_text CHAR(2048) 
	DEFINE l_query_text CHAR(2200) 

	OPEN WINDOW j118 with FORM "J118" 
	CALL winDecoration_j("J118") -- albo kd-756 
	WHILE true 
		CLEAR FORM 
		LET l_idx = 1 
		LET l_arr_size = 0 
		MESSAGE kandoomsg2("U",1001,"") 	#1001 "Enter Selection Criteria - ESC TO Continue"
		SELECT job.title_text, 
		job.cust_code, 
		customer.name_text 
		INTO l_rec_job.title_text, 
		l_rec_job.cust_code, 
		l_rec_customer.name_text 
		FROM job, 
		customer 
		WHERE job.cmpy_code = p_cmpy 
		AND customer.cmpy_code = p_cmpy 
		AND job.job_code = p_job_code 
		AND job.cust_code = customer.cust_code 

		DISPLAY p_job_code TO job_code 
		DISPLAY l_rec_job.title_text TO job.title_text 
		DISPLAY l_rec_job.cust_code TO job.cust_code 
		DISPLAY l_rec_customer.name_text TO customer.name_text 
		DISPLAY p_var_code TO var_code

		CONSTRUCT l_where_text ON activity_code, 
		activity.title_text, 
		resp_code, 
		sort_text, 
		est_end_date 
		FROM sr_activity[1].* 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","actiwind","construct-activity") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END CONSTRUCT 


		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_idx = arr_curr() 
			LET l_arr_rec_activity[l_idx].activity_code = NULL 
			EXIT WHILE 
		END IF 
		LET l_query_text = 
		"SELECT activity_code,", 
		"title_text,", 
		"resp_code,", 
		"sort_text,", 
		"est_end_date ", 
		"FROM activity ", 
		"WHERE cmpy_code = \"",p_cmpy,"\" ", 
		"AND job_code = \"",p_job_code,"\" ", 
		"AND ",l_where_text clipped," ", 
		"AND var_code = \"",p_var_code,"\" ", 
		"ORDER BY activity_code" 
		PREPARE s_activity FROM l_query_text 
		DECLARE c_activity CURSOR FOR s_activity 
		FOREACH c_activity INTO l_arr_rec_activity[l_idx].* 
			LET l_arr_size = l_arr_size + 1 
			LET l_idx = l_idx + 1 
			IF l_idx > 50 THEN 
				ERROR kandoomsg2("U",6100,l_arr_size) 			#6100 First l_idx records selected only
				EXIT FOREACH 
			END IF 
		END FOREACH 
		MESSAGE kandoomsg2("U",9113,l_arr_size) #9113 l_idx records selected
		IF l_arr_size = 0 THEN 
			CONTINUE WHILE 
		END IF 

		CALL set_count(l_arr_size) 
		MESSAGE kandoomsg2("U",1102,"") 	#1102 "ESC TO SELECT, F9 TO Re-SELECT, F10 TO Add, RETURN TO View "
		DISPLAY ARRAY l_arr_rec_activity TO sr_activity.* ATTRIBUTE(UNBUFFERED) 
			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","actiwind","display-arr-activity") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			ON KEY (F10) 
				CALL run_prog("J51",p_job_code,"","","") 

			ON KEY (F9) 
				LET int_flag = true 
				EXIT DISPLAY 

			ON KEY (tab) 
				LET l_idx = arr_curr() 
				LET l_jb_code = " job.job_code = '", p_job_code clipped, 
				"' AND activity.var_code = '", p_var_code, 
				"' AND activity.activity_code = '", 
				l_arr_rec_activity[l_idx].activity_code clipped, "' " 

				CALL run_prog("J52",l_jb_code,"","","") 
				
			ON KEY (RETURN) 
				--#         IF fgl_fglgui() THEN
				--#            EXIT display
				--#         END IF
				LET l_idx = arr_curr() 
				LET l_jb_code = " job.job_code = '", p_job_code clipped, 
				"' AND activity.var_code = '", p_var_code, 
				"' AND activity.activity_code = '", 
				l_arr_rec_activity[l_idx].activity_code clipped, "' " 

				CALL run_prog("J52",l_jb_code,"","","") 

		END DISPLAY 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		ELSE 
			EXIT WHILE 
		END IF 
	END WHILE 

	LET l_idx = arr_curr() 

	CLOSE WINDOW J118 

	RETURN l_arr_rec_activity[l_idx].activity_code 
END FUNCTION