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

	Source code beautified by beautify.pl on 2020-01-02 19:48:10	$Id: $
}




{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module J61  This Program allows the user TO enter AND maintain
# Variation Codes  FOR Job Management


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "J_JM_GLOBALS.4gl" 
GLOBALS "J61_GLOBALS.4gl" 

MAIN 
	#Initial UI Init
	CALL setModuleId("J61") -- albo 
	CALL ui_init(0) 
	DEFER quit 
	DEFER interrupt 
	CALL authenticate(getmoduleid()) 
	OPEN WINDOW j119 with FORM "J119" -- alch kd-747 
	CALL winDecoration_j("J119") -- alch kd-747 
	WHILE true 
		CLEAR FORM 
		IF num_args() = 0 THEN 
			LET msgresp = kandoomsg("U", 1058, "Job Code") 
			#1058 Enter Job Code;  OK TO Continue.
			DISPLAY pr_jobvars.job_code TO job.job_code 

			INPUT pr_jobvars.job_code 
			FROM job.job_code 

				BEFORE INPUT 
					CALL publish_toolbar("kandoo","J61","input-pr_jobvars-1") -- alch kd-506 

				ON ACTION "WEB-HELP" -- albo kd-373 
					CALL onlinehelp(getmoduleid(),null) 

				ON KEY (control-b) 
					IF infield(job_code) THEN 
						LET pr_jobvars.job_code = show_job(glob_rec_kandoouser.cmpy_code) 
						SELECT title_text INTO pr_job.title_text 
						FROM job 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND job_code = pr_jobvars.job_code 
						DISPLAY pr_jobvars.job_code, 
						pr_job.title_text TO job.job_code, 
						job_title_text 

					END IF 
					OPTIONS INSERT KEY f1, 
					DELETE KEY f2 
				AFTER FIELD job_code 
					SELECT title_text INTO pr_job.title_text 
					FROM job 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND job.job_code = pr_jobvars.job_code 
					IF status = notfound THEN 
						LET pr_job.title_text = "" 
						DISPLAY pr_job.title_text TO job_title_text 

						LET msgresp = kandoomsg("J", 9558, "") 
						#9558 Job code NOT found;  Try Window.
						NEXT FIELD job_code 
					END IF 
					DISPLAY pr_job.title_text TO job_title_text 

					IF int_flag OR quit_flag THEN 
					ELSE 
						CALL scan_vars(glob_rec_kandoouser.cmpy_code, pr_jobvars.job_code) 
						CLEAR FORM 
						NEXT FIELD job_code 
					END IF 
				ON KEY (control-w) 
					CALL kandoohelp("") 
			END INPUT 
			IF int_flag 
			OR quit_flag THEN 
				EXIT WHILE 
			END IF 
		ELSE 
			LET pr_jobvars.job_code = arg_val(1) 
			SELECT title_text INTO pr_job.title_text 
			FROM job 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND job.job_code = pr_jobvars.job_code 
			IF status = notfound THEN 
				LET msgresp = kandoomsg("J", 7506, "") 
				#7506 Job NOT found.
				EXIT WHILE 
			END IF 
			DISPLAY pr_job.title_text TO job_title_text 

			CALL scan_vars(glob_rec_kandoouser.cmpy_code, pr_jobvars.job_code) 
			EXIT WHILE 
		END IF 
	END WHILE 
END MAIN 


FUNCTION scan_vars(p_cmpy, pr_job_code) 
	DEFINE 
	pa_jobvars ARRAY [40] OF RECORD 
		scroll_flag CHAR(1), 
		var_code LIKE jobvars.var_code, 
		title_text LIKE jobvars.title_text, 
		appro_date LIKE jobvars.appro_date 
	END RECORD, 
	p_cmpy LIKE company.cmpy_code, 
	pr_job_code LIKE job.job_code, 
	pr_scroll_flag CHAR(1), 
	del_cnt INTEGER 

	LET msgresp = kandoomsg("U", 1002, "") 
	#1002 Searching database;  Please wait.

	OPTIONS INSERT KEY f1, 
	DELETE KEY f36 
	DECLARE varsurs CURSOR FOR 
	SELECT * INTO pr_jobvars.* 
	FROM jobvars 
	WHERE cmpy_code = p_cmpy 
	AND jobvars.job_code = pr_jobvars.job_code 
	ORDER BY var_code 

	FOR idx = 1 TO 40 
		INITIALIZE pa_jobvars[idx].* TO NULL 
	END FOR 
	LET idx = 0 
	FOREACH varsurs 
		LET idx = idx + 1 
		LET pa_jobvars[idx].scroll_flag = "" 
		LET pa_jobvars[idx].var_code = pr_jobvars.var_code 
		LET pa_jobvars[idx].title_text = pr_jobvars.title_text 
		LET pa_jobvars[idx].appro_date = pr_jobvars.appro_date 
		IF idx > 39 THEN 
			EXIT FOREACH 
		END IF 
	END FOREACH 

	LET msgresp=kandoomsg("U",9113,idx) 
	#9113 "idx" records selected.
	CALL set_count(idx) 
	LET msgresp=kandoomsg("U",1003,"100") 
	#1003 F1 TO Add;  F2 TO delete;  ENTER on line TO Edit.
	INPUT ARRAY pa_jobvars WITHOUT DEFAULTS FROM sr_jobvars.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","J61","input_arr-pa_jobvars-1") -- alch kd-506 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE ROW 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			NEXT FIELD scroll_flag 
		BEFORE FIELD scroll_flag 
			LET pr_scroll_flag = pa_jobvars[idx].scroll_flag 
			DISPLAY pa_jobvars[idx].* 
			TO sr_jobvars[scrn].* 

		AFTER FIELD scroll_flag 
			LET pa_jobvars[idx].scroll_flag = pr_scroll_flag 
			IF fgl_lastkey() = fgl_keyval("down") 
			AND pa_jobvars[idx+1].var_code IS NULL THEN 
				LET msgresp=kandoomsg("J",9001,"") 
				#9001 There are no more rows in the direction you are going.
				NEXT FIELD scroll_flag 
			END IF 
			IF fgl_lastkey() = fgl_keyval("down") 
			AND arr_curr() >= arr_count() THEN 
				LET msgresp=kandoomsg("J",9001,"") 
				#9001 There are no more rows in the direction you are going.
				NEXT FIELD scroll_flag 
			END IF 
		BEFORE FIELD var_code 
			IF pa_jobvars[idx].var_code IS NOT NULL THEN 
				NEXT FIELD title_text 
			END IF 
		AFTER FIELD var_code 
			IF pa_jobvars[idx].var_code IS NULL THEN 
				LET msgresp=kandoomsg("J",9488,"") 
				#9488 Variation number must be entered.
				NEXT FIELD var_code 
			ELSE 
				SELECT unique 1 FROM jobvars 
				WHERE cmpy_code = p_cmpy 
				AND job_code = pr_job_code 
				AND var_code = pa_jobvars[idx].var_code 
				IF status = 0 THEN 
					LET msgresp=kandoomsg("J",9487,"") 
					#9487 Variation Number already exists;  Please Re Enter.
					LET pa_jobvars[idx].var_code = NULL 
					NEXT FIELD var_code 
				END IF 
				NEXT FIELD title_text 
			END IF 
		AFTER FIELD title_text 
			IF pa_jobvars[idx].title_text IS NULL THEN 
				LET msgresp=kandoomsg("J",9485,"") 
				#9485 Details must be entered
				NEXT FIELD title_text 
			END IF 
		AFTER FIELD appro_date 
			IF fgl_lastkey() = fgl_keyval("down") 
			OR fgl_lastkey() = fgl_keyval("accept") 
			OR fgl_lastkey() = fgl_keyval("RETURN") 
			OR fgl_lastkey() = fgl_keyval("tab") THEN 
				NEXT FIELD scroll_flag 
			END IF 
		BEFORE INSERT 
			INITIALIZE pa_jobvars[idx].* TO NULL 
			IF arr_curr() < arr_count() THEN 
				NEXT FIELD var_code 
			END IF 
		AFTER ROW 
			LET pr_jobvars.cmpy_code = p_cmpy 
			IF pa_jobvars[idx].var_code IS NOT NULL THEN 
				UPDATE jobvars 
				SET title_text = pa_jobvars[idx].title_text, 
				appro_date = pa_jobvars[idx].appro_date 
				WHERE cmpy_code = p_cmpy 
				AND job_code = pr_job_code 
				AND var_code = pa_jobvars[idx].var_code 
				IF sqlca.sqlerrd[3] = 0 THEN 
					INSERT INTO jobvars VALUES (p_cmpy,pr_job_code, 
					pa_jobvars[idx].var_code, 
					pa_jobvars[idx].title_text, 
					pa_jobvars[idx].appro_date) 
				END IF 
			ELSE 
				INITIALIZE pa_jobvars[idx].* TO NULL 
			END IF 
			DISPLAY pa_jobvars[idx].* 
			TO sr_jobvars[scrn].* 

		ON KEY (F2) 
			IF pa_jobvars[idx].var_code IS NOT NULL THEN 
				IF pa_jobvars[idx].scroll_flag IS NULL THEN 
					IF jobvars_inuse(p_cmpy,pr_job_code, 
					pa_jobvars[idx].var_code) THEN 
						LET msgresp=kandoomsg("J",9489,"") 
						#9489 Unit Code in use; Delete NOT allowed.
					ELSE 
						LET pa_jobvars[idx].scroll_flag = "*" 
						LET del_cnt = del_cnt + 1 
					END IF 
				ELSE 
					LET pa_jobvars[idx].scroll_flag = NULL 
					LET del_cnt = del_cnt - 1 
				END IF 
			END IF 
			NEXT FIELD scroll_flag 
		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				IF pa_jobvars[idx].var_code IS NULL THEN 
					FOR idx = arr_curr() TO arr_count() 
						LET pa_jobvars[idx].* = pa_jobvars[idx+1].* 
						IF arr_curr() = arr_count() THEN 
							INITIALIZE pa_jobvars[idx].* TO NULL 
							EXIT FOR 
						END IF 
						IF scrn <= 5 THEN 
							DISPLAY pa_jobvars[idx].* 
							TO sr_jobvars[scrn].* 

							LET scrn = scrn + 1 
						END IF 
					END FOR 
					LET idx =arr_curr() 
					LET int_flag = false 
					LET quit_flag = false 
					NEXT FIELD scroll_flag 
				END IF 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	ELSE 
		IF del_cnt > 0 THEN 
			LET msgresp=kandoomsg("J",8016,del_cnt) 
			#8015 Confirmation TO Delete del_cnt Variations (Y/N)?:
			IF msgresp = "Y" THEN 
				FOR idx = 1 TO arr_count() 
					IF pa_jobvars[idx].scroll_flag IS NOT NULL THEN 
						IF jobvars_inuse(p_cmpy,pr_job_code, 
						pa_jobvars[idx].var_code) THEN 
							LET msgresp=kandoomsg("J",7015,pa_jobvars[idx].var_code) 
							#7015 jobvars code in use delete NOT allowed.
							#     Any key TO continue.
						ELSE 
							DELETE FROM jobvars 
							WHERE cmpy_code = p_cmpy 
							AND var_code = pa_jobvars[idx].var_code 
						END IF 
						LET pa_jobvars[idx].scroll_flag = "" 
					END IF 
				END FOR 
			END IF 
		END IF 
	END IF 
	OPTIONS INSERT KEY f1, 
	DELETE KEY f2 
END FUNCTION 


FUNCTION jobvars_inuse(p_cmpy,pr_job_code,pr_var_code) 
	DEFINE 
	p_cmpy LIKE company.cmpy_code, 
	pr_job_code LIKE job.job_code, 
	pr_var_code LIKE jobvars.var_code 

	SELECT unique 1 FROM activity 
	WHERE cmpy_code = p_cmpy 
	AND var_code = pr_var_code 
	AND job_code = pr_job_code 
	IF status = 0 THEN 
		RETURN true 
	END IF 
	RETURN false 
END FUNCTION 

