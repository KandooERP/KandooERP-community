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

	Source code beautified by beautify.pl on 2020-01-03 10:10:06	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "T_GW_GLOBALS.4gl" 

# This program monitors the queued Report Writer jobs, AND, depending on
# the time of day AND whether they are queued TO the day/night queue,
# starts them.  It IS called be a cron job which IS executed every 15
# minutes.

GLOBALS 
	DEFINE pr_rwqueues RECORD LIKE rwqueues.*, 
	pr_rptargs RECORD LIKE rptargs.*, 
	pv_time DATETIME hour TO minute 

END GLOBALS 


#######################################################################
# MAIN
#
#
#######################################################################
MAIN 
	DEFINE fv_runner CHAR(100) 
	DEFINE l_arg_str1 STRING 

	CALL setModuleId("GWS") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_t_gw() #init batch module 


	LET pv_time = CURRENT 

	DECLARE rptargs_curs CURSOR FOR 
	SELECT * 
	FROM rptargs 
	WHERE (run_opt = "Q" 
	OR run_opt = "N") 
	AND active_flag = "W" 
	FOR UPDATE OF active_flag 

	# The active flag IS SET because this program IS called every 15 minutes, AND
	# IF this FOREACH loop takes longer than 15 minutes there may OTHERWISE be
	# double-ups on jobs being run

	BEGIN WORK 

		FOREACH rptargs_curs INTO pr_rptargs.* 

			IF pr_rptargs.active_flag <> "W" THEN 
				CONTINUE FOREACH 
			END IF 

			SELECT * 
			INTO pr_rwqueues.* 
			FROM rwqueues 
			WHERE queue_code = pr_rptargs.run_opt 

			IF pr_rptargs.run_opt = "Q" THEN 
				IF pv_time >= pr_rwqueues.start_time 
				AND pv_time <= pr_rwqueues.end_time THEN 
					UPDATE rptargs 
					SET active_flag = "A" 
					WHERE CURRENT OF rptargs_curs 


					CALL fgl_winmessage("LegacyMessWarning","LegacyMessWarning - Please check this code","error") 

					#some information on 4js and or Aubit errors/bugs

					LET l_arg_str1 = "REPORT_ID=", trim(pr_rptargs.job_id) 
					#CALL run_prog("GW1", l_arg_str1, ">errfile", "2>&1", "&", "", "", "", "", "", "") 
					CALL run_prog("GW1", l_arg_str1, ">errfile", "2>&1", "&")
					--		 CALL run_prog("GW1", pr_rptargs.job_id, ">errfile", "2>&1", "&", "", "", "", "", "", "")


					#		 CALL run_prog("GW1", pr_rptargs.job_id, ">errfile",
					#		    "2>&1", "&", "", "", "", "", "", "")
					#                LET fv_runner = "fglgo ../prog/GW1.4gi ",
					#                                pr_rptargs.job_id,
					#                                "  > errfile 2>&1 &"
					#                run fv_runner   #userunprog
					# Changed back TO use the old way as there IS a bug in run_prog that
					# stop this running in background
					LET fv_runner = "fglgo ../prog/GW1.4gi ", 
					pr_rptargs.job_id, 
					" > errfile 2>&1 &" 
					RUN fv_runner #userunprog 

				END IF 
			ELSE # = "N" FOR night_queue 
				IF pv_time >= pr_rwqueues.start_time 
				OR pv_time <= pr_rwqueues.end_time THEN 
					UPDATE rptargs 
					SET active_flag = "A" 
					WHERE CURRENT OF rptargs_curs 

					LET fv_runner = "fglgo ../prog/GW1.4gi ", 
					pr_rptargs.job_id, 
					" > errfile 2>&1 &" 
					RUN fv_runner #userunprog 
				END IF 
			END IF 

		END FOREACH 


		CALL donePrompt("What IS this?","What IS this?","ACCEPT") 


	COMMIT WORK 

END MAIN 
