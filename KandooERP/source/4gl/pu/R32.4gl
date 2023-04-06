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

	Source code beautified by beautify.pl on 2020-01-02 17:06:16	Source code beautified by beautify.pl on 2020-01-02 17:03:26	$Id: $
}

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "R_PU_GLOBALS.4gl" 
GLOBALS "R31_GLOBALS.4gl" 

# DISPLAY oustanding by Job info


#######################################################################
# MAIN
#
#
#######################################################################
MAIN 

	CALL setModuleId("R32") -- albo 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_r_pu() #init r/pu purchase ORDER module 

	OPEN WINDOW r117 with FORM "R117" 
	CALL  windecoration_r("R117") 

	IF num_args() = 3 THEN 
		IF enter_job() THEN 
			CALL scan_commitments(where_text) 
		END IF 
	ELSE 
		WHILE enter_job() 
			CALL scan_commitments(where_text) 
		END WHILE 
	END IF 

	CLOSE WINDOW r117 
END MAIN 


FUNCTION enter_job() 
	DEFINE 
	pr_purchdetl RECORD LIKE purchdetl.* 

	CLEAR FORM 
	IF num_args() = 3 THEN 
		LET pr_purchdetl.job_code = arg_val(1) 
		LET pr_purchdetl.var_num = arg_val(2) 
		LET pr_purchdetl.activity_code = arg_val(3) 
		SELECT unique 1 FROM activity 
		WHERE job_code = pr_purchdetl.job_code 
		AND var_code = pr_purchdetl.var_num 
		AND activity_code = pr_purchdetl.activity_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		IF status = notfound THEN 
			RETURN false 
		END IF 
	ELSE 
		LET msgresp=kandoomsg("U",1020,"Job & Activity") 
		#U1020 Enter Job & Activity Details
		INPUT BY NAME pr_purchdetl.job_code, 
		pr_purchdetl.var_num, 
		pr_purchdetl.activity_code ATTRIBUTE(UNBUFFERED) 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","R32","inp-purchdetl-1") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 


			ON KEY (control-b) 
				CASE 
					WHEN infield(job_code) 
						LET pr_purchdetl.job_code = show_job(glob_rec_kandoouser.cmpy_code) 
						NEXT FIELD job_code 
					WHEN infield(var_num) 
						LET pr_purchdetl.var_num = 
						show_jobvars(glob_rec_kandoouser.cmpy_code,pr_purchdetl.job_code) 
						NEXT FIELD var_num 
					WHEN infield(activity_code) 
						LET pr_purchdetl.activity_code = 
						show_activity(glob_rec_kandoouser.cmpy_code,pr_purchdetl.job_code, 
						pr_purchdetl.var_num) 
						NEXT FIELD activity_code 
				END CASE 
			AFTER FIELD job_code 
				IF pr_purchdetl.job_code IS NOT NULL THEN 
					SELECT unique 1 FROM job 
					WHERE job_code = pr_purchdetl.job_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					IF status = notfound THEN 
						LET msgresp=kandoomsg("U",9105,"") 
						#U9105" Job NOT found"
						NEXT FIELD job_code 
					END IF 
				END IF 
			AFTER FIELD var_num 
				IF pr_purchdetl.var_num IS NULL THEN 
					LET pr_purchdetl.var_num = 0 
				END IF 
			AFTER FIELD activity_code 
				IF pr_purchdetl.activity_code IS NOT NULL THEN 
					SELECT unique 1 FROM activity 
					WHERE job_code = pr_purchdetl.job_code 
					AND var_code = pr_purchdetl.var_num 
					AND activity_code = pr_purchdetl.activity_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					IF status = notfound THEN 
						LET msgresp=kandoomsg("J",9512,"") 
						#9512 " Job / Activity combination NOT found"
						CONTINUE INPUT 
					END IF 
				END IF 
			AFTER INPUT 
				IF NOT (int_flag OR quit_flag) THEN 
					IF pr_purchdetl.job_code IS NULL THEN 
						LET msgresp=kandoomsg("U",9102,"") 
						NEXT FIELD job_code 
					END IF 
					IF pr_purchdetl.activity_code IS NULL THEN 
						LET msgresp=kandoomsg("U",9102,"") 
						NEXT FIELD activity_code 
					END IF 
					SELECT unique 1 FROM activity 
					WHERE job_code = pr_purchdetl.job_code 
					AND var_code = pr_purchdetl.var_num 
					AND activity_code = pr_purchdetl.activity_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					IF status = notfound THEN 
						LET msgresp=kandoomsg("J",9512,"") 
						#J9512 " Job / Activity combination NOT found"
						CONTINUE INPUT 
					END IF 
				END IF 
			ON KEY (control-w) 
				CALL kandoohelp("") 
		END INPUT 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			RETURN false 
		END IF 
	END IF 
	DISPLAY BY NAME pr_purchdetl.job_code, 
	pr_purchdetl.var_num, 
	pr_purchdetl.activity_code 

	LET where_text = "job_code= '",pr_purchdetl.job_code,"' ", 
	"AND purchdetl.var_num = '",pr_purchdetl.var_num,"' ", 
	"AND activity_code = '",pr_purchdetl.activity_code,"' ", 
	"AND purchdetl.type_ind = 'C' OR purchdetl.type_ind = 'J' " 

	RETURN true 
END FUNCTION 
