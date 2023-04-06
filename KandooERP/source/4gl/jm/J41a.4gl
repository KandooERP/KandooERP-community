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

#GLOBALS "../common/glob_GLOBALS.4gl"
#used as GLOBALS FROM J41.4gl
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../jm/J_JM_GLOBALS.4gl" 
GLOBALS "../jm/J43_GLOBALS.4gl" 



FUNCTION select_job() 
	DEFINE 
	query_text CHAR(1000), 
	where_text CHAR(500), 
	pr_winds_text CHAR(40), 
	idx SMALLINT 

	CLEAR FORM 
	LET msgresp = kandoomsg("U",1020,TRAN_TYPE_JOB_JOB) #1020 Enter Job Details; OK TO Continue
	INPUT BY NAME pr_job.job_code WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","J41a","input-pr_job-1") -- alch kd-506 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "LOOKUP" --ON KEY (control-b) 
			LET pr_winds_text = showujobs(glob_rec_kandoouser.cmpy_code, pr_user_scan_code) 
			IF pr_winds_text IS NOT NULL THEN 
				LET pr_job.job_code = pr_winds_text 
			END IF 
			NEXT FIELD job_code 

		AFTER FIELD job_code 
			SELECT * INTO pr_job.* FROM job 
			WHERE job_code = pr_job.job_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND (acct_code matches pr_user_scan_code OR locked_ind <= "1") 
			IF status = notfound THEN 
				LET msgresp = kandoomsg("U",9105,"") #9105 RECORD Not Found; Try Window.
				NEXT FIELD job_code 
			END IF 
			
			IF pr_job.locked_ind = "0" THEN 
				LET msgresp = kandoomsg("J",9573,"") #9573 Cannot Edit Master Job
				NEXT FIELD job_code 
			END IF 
			
			DISPLAY pr_job.title_text TO job.title_text 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 
	
	LET msgresp = kandoomsg("U",1001,"") #1001 Enter Selection Critria; OK TO Continue
	
	CONSTRUCT where_text ON 
		var_code, 
		activity_code, 
		title_text, 
		est_comp_per, 
		finish_flag, 
		act_end_date, 
		baltocomp_amt 
	FROM 
		activity.var_code, 
		activity.activity_code, 
		activity.title_text, 
		activity.est_comp_per, 
		activity.finish_flag, 
		activity.act_end_date, 
		activity.baltocomp_amt 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","J41a","const-var_code-1") -- alch kd-506 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 
	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 
	LET query_text = "SELECT * FROM activity ", 
	" WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	" AND job_code = '",pr_job.job_code,"' ", 
	" AND ",where_text clipped," ", 
	" ORDER BY var_code, sort_text, activity_code" 
	PREPARE s_activity FROM query_text 
	DECLARE c_activity CURSOR FOR s_activity 
	RETURN true 
END FUNCTION 


FUNCTION edit_status(pr_reactivate_flag) 
	DEFINE pa_activity array[320] OF RECORD 
		scroll_flag CHAR(1), 
		var_code LIKE activity.var_code , 
		activity_code LIKE activity.activity_code , 
		title_text LIKE activity.title_text , 
		est_comp_per LIKE activity.est_comp_per, 
		finish_flag LIKE activity.finish_flag, 
		act_end_date LIKE activity.act_end_date, 
		baltocomp_amt LIKE activity.baltocomp_amt 
	END RECORD 
	DEFINE pr_activity RECORD LIKE activity.*, 
	pr_reactivate_flag, idx, scrn, i SMALLINT, 
	pr_runner CHAR(150), 
	pr_scroll_flag, 
	finish_job_flag, pr_old_finish_flag, pr_priority CHAR(1) 

	LET idx = 0 
	FOREACH c_activity INTO pr_activity.* 
		LET idx = idx + 1 
		LET pa_activity[idx].var_code = pr_activity.var_code 
		LET pa_activity[idx].activity_code = pr_activity.activity_code 
		LET pa_activity[idx].title_text = pr_activity.title_text 
		LET pa_activity[idx].est_comp_per = pr_activity.est_comp_per 
		LET pa_activity[idx].finish_flag = pr_activity.finish_flag 
		LET pa_activity[idx].act_end_date = pr_activity.act_end_date 
		LET pa_activity[idx].baltocomp_amt = pr_activity.baltocomp_amt 
		IF idx = 300 THEN 
			LET msgresp = kandoomsg("U",6100,idx) 
			#6100 First idx records selected
			EXIT FOREACH 
		END IF 
	END FOREACH 
	LET msgresp = kandoomsg("U",9113,idx) 
	#9113 idx records selected
	IF idx = 0 THEN 
		LET idx = 1 
		INITIALIZE pa_activity[idx].* TO NULL 
	END IF 
	LET msgresp = kandoomsg("J",1007,"") 
	#1007 F9 TO View Job/Activity Details; ENTER on Line TO Edit
	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 
	CALL set_count(idx) 
	INPUT ARRAY pa_activity WITHOUT DEFAULTS FROM sr_activity.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","J41a","input-pa_activity-1") -- alch kd-506 
	
		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE FIELD scroll_flag 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			LET pr_scroll_flag = pa_activity[idx].scroll_flag 
			LET pr_activity.var_code = pa_activity[idx].var_code 
			LET pr_activity.activity_code = pa_activity[idx].activity_code 
			LET pr_activity.title_text = pa_activity[idx].title_text 
			LET pr_activity.est_comp_per = pa_activity[idx].est_comp_per 
			LET pr_activity.finish_flag = pa_activity[idx].finish_flag 
			LET pr_activity.act_end_date = pa_activity[idx].act_end_date 
			LET pr_activity.baltocomp_amt = pa_activity[idx].baltocomp_amt 
			DISPLAY pa_activity[idx].* TO sr_activity[scrn].* 

		AFTER FIELD scroll_flag 
			LET pa_activity[idx].scroll_flag = pr_scroll_flag 
			DISPLAY pa_activity[idx].* TO sr_activity[scrn].* 

			IF fgl_lastkey() = fgl_keyval("down") 
			AND arr_curr() >= arr_count() THEN 
				LET msgresp = kandoomsg("U",9001,"") 
				#9001 There no more rows...
				NEXT FIELD scroll_flag 
			END IF 
			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF pa_activity[idx+1].activity_code IS NULL THEN 
					LET msgresp = kandoomsg("U",9001,"") 
					#9001 There no more rows...
					NEXT FIELD scroll_flag 
				END IF 
			END IF 
			IF fgl_lastkey() = fgl_keyval("nextpage") 
			AND pa_activity[idx+12].activity_code IS NULL THEN 
				LET msgresp = kandoomsg("U",9001,"") 
				#9001 No more rows in this direction
				NEXT FIELD scroll_flag 
			END IF 
		ON KEY (F5) 
			CALL run_prog("J12",pr_job.job_code,"","","") 
			OPTIONS INSERT KEY f36, 
			DELETE KEY f36 
		ON KEY (F6) 
			LET pr_runner = " job.job_code = '", pr_job.job_code clipped, 
			"' AND activity.var_code = '", 
			pa_activity[idx].var_code, 
			"' AND activity.activity_code = '", 
			pa_activity[idx].activity_code clipped,"'" 
			CALL run_prog("J52",pr_runner,"","","") 
			OPTIONS INSERT KEY f36, 
			DELETE KEY f36 
		BEFORE FIELD est_comp_per 
			SELECT finish_flag, priority_ind 
			INTO pr_old_finish_flag, pr_priority FROM activity 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND job_code = pr_job.job_code 
			AND var_code = pa_activity[idx].var_code 
			AND activity_code = pa_activity[idx].activity_code 
			IF pr_old_finish_flag = "Y" 
			AND NOT pr_reactivate_flag THEN 
				LET msgresp = kandoomsg("J",9608,"") 
				#9608 Not Permitted TO Re-Activate Activity
				NEXT FIELD scroll_flag 
			END IF 
		AFTER FIELD est_comp_per 
			IF fgl_lastkey() = fgl_keyval("right") 
			OR fgl_lastkey() = fgl_keyval("down") 
			OR fgl_lastkey() = fgl_keyval("RETURN") 
			OR fgl_lastkey() = fgl_keyval("tab") 
			OR fgl_lastkey() = fgl_keyval("accept") THEN 
				IF pa_activity[idx].est_comp_per IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD est_comp_per 
				END IF 
				IF pa_activity[idx].est_comp_per > 100 THEN 
					LET msgresp = kandoomsg("A",9222,"") 
					#9222 Percentage cannot be greater than 100
					NEXT FIELD est_comp_per 
				END IF 
				IF pa_activity[idx].est_comp_per < 0 THEN 
					LET msgresp = kandoomsg("U",9907,"0") 
					#9907 Value must be greater than OR equal TO 0
					NEXT FIELD est_comp_per 
				END IF 
				IF pa_activity[idx].est_comp_per != 100 THEN 
					LET pa_activity[idx].finish_flag = "N" 
					LET pa_activity[idx].act_end_date = NULL 
					DISPLAY pa_activity[idx].* TO sr_activity[scrn].* 

				END IF 
				IF fgl_lastkey() = fgl_keyval("accept") THEN 
					NEXT FIELD scroll_flag 
				END IF 
			ELSE 
				NEXT FIELD est_comp_per 
			END IF 
		BEFORE FIELD finish_flag 
			IF pa_activity[idx].est_comp_per != 100 THEN 
				IF fgl_lastkey() = fgl_keyval("up") 
				OR fgl_lastkey() = fgl_keyval("left") THEN 
					NEXT FIELD est_comp_per 
				ELSE 
					NEXT FIELD baltocomp_amt 
				END IF 
			END IF 
		AFTER FIELD finish_flag 
			IF pa_activity[idx].finish_flag = "N" THEN 
				LET pa_activity[idx].act_end_date = NULL 
				DISPLAY pa_activity[idx].* TO sr_activity[scrn].* 

			ELSE 
				IF pa_activity[idx].act_end_date IS NULL THEN 
					LET pa_activity[idx].act_end_date = today 
				END IF 
				LET pa_activity[idx].baltocomp_amt = 0 
				DISPLAY pa_activity[idx].* TO sr_activity[scrn].* 

			END IF 
			IF fgl_lastkey() = fgl_keyval("accept") THEN 
				NEXT FIELD scroll_flag 
			END IF 
			IF fgl_lastkey() = fgl_keyval("up") 
			OR fgl_lastkey() = fgl_keyval("left") THEN 
				NEXT FIELD est_comp_per 
			ELSE 
				NEXT FIELD act_end_date 
			END IF 
		BEFORE FIELD act_end_date 
			IF fgl_lastkey() = fgl_keyval("up") 
			OR fgl_lastkey() = fgl_keyval("left") THEN 
				NEXT FIELD est_comp_per 
			ELSE 
				IF pa_activity[idx].finish_flag = "N" THEN 
					NEXT FIELD baltocomp_amt 
				END IF 
			END IF 
		AFTER FIELD act_end_date 
			IF pa_activity[idx].act_end_date IS NULL THEN 
				LET pa_activity[idx].act_end_date = today 
			END IF 
			IF fgl_lastkey() = fgl_keyval("up") 
			OR fgl_lastkey() = fgl_keyval("left") THEN 
				NEXT FIELD finish_flag 
			ELSE 
				NEXT FIELD scroll_flag 
			END IF 
		AFTER FIELD baltocomp_amt 
			IF pa_activity[idx].baltocomp_amt IS NULL THEN 
				LET pa_activity[idx].baltocomp_amt = 0 
			END IF 
			IF pr_priority = "C" 
			AND pa_activity[idx].baltocomp_amt <> 0 THEN 
				LET msgresp = kandoomsg("J",9610,"") 
				#9610 Balance TO completion must be 0 FOR contributions
				NEXT FIELD baltocomp_amt 
			END IF 
			IF fgl_lastkey() = fgl_keyval("up") 
			OR fgl_lastkey() = fgl_keyval("left") THEN 
				NEXT FIELD est_comp_per 
			ELSE 
				NEXT FIELD scroll_flag 
			END IF 
		AFTER ROW 
			DISPLAY pa_activity[idx].* TO sr_activity[scrn].* 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				IF NOT infield(scroll_flag) THEN 
					LET int_flag = false 
					LET quit_flag = false 
					LET pa_activity[idx].var_code = pr_activity.var_code 
					LET pa_activity[idx].activity_code = pr_activity.activity_code 
					LET pa_activity[idx].title_text = pr_activity.title_text 
					LET pa_activity[idx].est_comp_per = pr_activity.est_comp_per 
					LET pa_activity[idx].finish_flag = pr_activity.finish_flag 
					LET pa_activity[idx].act_end_date = pr_activity.act_end_date 
					LET pa_activity[idx].baltocomp_amt = pr_activity.baltocomp_amt 
					NEXT FIELD scroll_flag 
				END IF 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN 
	END IF 
	LET finish_job_flag = "Y" 
	WHENEVER ERROR CONTINUE 
	BEGIN WORK 
		FOR idx = 1 TO arr_count() 
			UPDATE activity 
			SET (est_comp_per , 
			finish_flag, 
			act_end_date, 
			baltocomp_amt) 
			= (pa_activity[idx].est_comp_per, 
			pa_activity[idx].finish_flag, 
			pa_activity[idx].act_end_date, 
			pa_activity[idx].baltocomp_amt) 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND job_code = pr_job.job_code 
			AND var_code = pa_activity[idx].var_code 
			AND activity_code = pa_activity[idx].activity_code 
			#IF any activity IS still OPEN THEN job cannot be closed
			IF pa_activity[idx].finish_flag != "Y" THEN 
				LET finish_job_flag = "N" 
			END IF 
		END FOR 
		#close job
		IF finish_job_flag = "Y" THEN 
			IF kandoomsg("J",8007,"") = "N" THEN 
				#8007 Activities Finished. Confirm TO Finish Job?
				LET finish_job_flag = "N" 
			END IF 
		END IF 
		UPDATE job 
		SET finish_flag = finish_job_flag 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND job_code = pr_job.job_code 
	COMMIT WORK 
	WHENEVER ERROR stop 
END FUNCTION 
