
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
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 
############################################################
# MODULE Scope Variables
############################################################
	DEFINE modu_rec_reporthead RECORD LIKE reporthead.* 
	DEFINE modu_rec_reportdetl RECORD LIKE reportdetl.* 
	DEFINE modu_scomp LIKE company.cmpy_code
	DEFINE modu_tcomp LIKE company.cmpy_code
	DEFINE modu_srep LIKE reporthead.report_code
	DEFINE modu_trep LIKE reporthead.report_code
	DEFINE modu_line_diff LIKE reportdetl.line_num
	DEFINE modu_last_line LIKE reportdetl.line_num
	DEFINE modu_ssline LIKE reportdetl.line_num
	DEFINE modu_seline LIKE reportdetl.line_num
	DEFINE modu_tsline LIKE reportdetl.line_num
	DEFINE modu_try_again CHAR(1)
	DEFINE modu_success_flag SMALLINT
	DEFINE modu_duplicate_flag SMALLINT
	DEFINE modu_first_line_flag SMALLINT
	DEFINE modu_equal_flag SMALLINT
	DEFINE modu_err_message CHAR(40) 
	DEFINE modu_answer CHAR(1) 
	--DEFINE modu_doit CHAR(1)

##############################################################
# MAIN
#
# Copy report instructions
##############################################################
MAIN 
	DEFINE l_ret SMALLINT 

	DEFER quit 
	DEFER interrupt 

	CALL setModuleId("GS9") 
	CALL ui_init(0) #initial ui init 
	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_g_gl() #init g/gl general ledger module 

	LET l_ret = 1 

	#LET modu_doit = "Y"
	LET modu_success_flag = 0 

	MENU
		BEFORE MENU 
			CALL publish_toolbar("kandoo","GS9","menu")
			CALL GL1_copy_report()
							
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null)
			 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 
				
		ON ACTION ("COPY","ACCEPT")
			CALL GL1_copy_report()   
			
		ON ACTION "CANCEL"
			EXIT MENU
	END MENU

END MAIN 


##############################################################
# FUNCTION report_check()
##############################################################
--FUNCTION report_check() 
--
--	LET modu_answer = promptYN("Delete","Report already exists - delete it?","Y") 
--
--END FUNCTION 


##############################################################
# FUNCTION GL1_copy_report()
##############################################################
FUNCTION GL1_copy_report() 
	DEFINE l_ret SMALLINT --return value
	DEFINE l_msg STRING 
	LET l_ret = 0 

	OPEN WINDOW G184 with FORM "G184" 
	CALL windecoration_g("G184") 

	IF modu_success_flag = 1 THEN 
		MESSAGE "All REPORT lines successfully copied" 
	END IF 
	LET modu_scomp = glob_rec_company.cmpy_code #init to current company
	INPUT 
		modu_scomp, 
		modu_srep, 
		modu_ssline, 
		modu_seline, 
		modu_tcomp, 
		modu_trep, 
		modu_tsline WITHOUT DEFAULTS 
	FROM
		scomp, 
		srep, 
		ssline, 
		seline, 
		tcomp, 
		trep, 
		tsline 
	
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GS9","inp-copy") 


		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		ON ACTION "LOOKUP" infield(modu_srep) 
			LET modu_srep = show_fin(glob_rec_kandoouser.cmpy_code) 
			DISPLAY modu_srep TO srep

			NEXT FIELD srep 

		ON ACTION "LOOKUP" infield(modu_trep) 
			LET modu_trep = show_fin(glob_rec_kandoouser.cmpy_code) 
			DISPLAY modu_trep TO trep

			NEXT FIELD trep 


		AFTER FIELD scomp 
			IF modu_scomp IS NULL THEN 
				ERROR "You must enter a source company" 
				NEXT FIELD scomp 
			ELSE 
				IF NOT db_company_pk_exists(UI_OFF,modu_scomp) THEN
					NEXT FIELD scomp 
				END IF 
			END IF 

		AFTER FIELD srep 
			IF modu_srep IS NULL THEN 
				ERROR "You must enter a source REPORT" 
				NEXT FIELD srep 
			ELSE 
				IF NOT db_reporthead_pk_exists_arg_cmpy_code(UI_OFF,NULL,modu_srep,modu_scomp) THEN
					ERROR "Report does NOT exist - please re-enter" 
					NEXT FIELD scomp 
				END IF 
			END IF 

		AFTER FIELD ssline 
			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
				RETURN FALSE 
			END IF 

			IF modu_ssline IS NULL 
			THEN 
				LET modu_ssline = 0 
				LET modu_seline = 999.99 
				NEXT FIELD tcomp 
			END IF 

		AFTER FIELD seline
      IF int_flag != 0  OR quit_flag != 0   THEN
         RETURN FALSE
      END IF

		AFTER FIELD tcomp 
			IF modu_tcomp IS NULL THEN 
				ERROR "You must enter a target company" 
				NEXT FIELD tcomp 
			ELSE 
				IF NOT db_company_pk_exists(UI_OFF,modu_tcomp) THEN
					NEXT FIELD tcomp 
				END IF 
			END IF 

		AFTER FIELD trep 
			LET modu_duplicate_flag = 0 

			IF modu_trep IS NULL THEN 
				ERROR "You must enter a target REPORT" 
				NEXT FIELD trep 
			ELSE 
				IF db_reporthead_pk_exists_arg_cmpy_code(UI_OFF,NULL,modu_trep,modu_tcomp) THEN			
					IF promptYN("Delete","Report already exists - delete it?","Y") = "Y"	THEN 

						BEGIN WORK 
							LET modu_err_message = "GS9 - Report Details delete" 
							DELETE FROM reporthead WHERE 
							cmpy_code = modu_tcomp AND 
							report_code = modu_trep 
							DELETE FROM reportdetl WHERE 
							cmpy_code = modu_tcomp AND 
							report_code = modu_trep 
						COMMIT WORK 

					ELSE 

						SELECT max(line_num) 
						INTO modu_last_line 
						FROM reportdetl 
						WHERE cmpy_code = modu_tcomp AND 
						report_code = modu_trep 
						MESSAGE "Last line of REPORT currently ", modu_last_line 
						LET modu_duplicate_flag = 1 
					END IF 
				END IF 
			END IF 


		AFTER FIELD tsline 
			LET modu_equal_flag = 0 

			IF modu_tsline IS NULL OR modu_tsline = 0 THEN 
				LET modu_equal_flag = 1 
			END IF 

		AFTER INPUT
			#FIELD scomp 
			IF modu_scomp IS NULL THEN 
				ERROR "You must enter a source company" 
				NEXT FIELD scomp 
			ELSE 
				IF NOT db_company_pk_exists(UI_OFF,modu_scomp) THEN
					NEXT FIELD scomp 
				END IF 
			END IF
			#FIELD srep
			IF modu_srep IS NULL THEN 
				ERROR "You must enter a source REPORT" 
				NEXT FIELD srep 
			ELSE 
				IF NOT db_reporthead_pk_exists_arg_cmpy_code(UI_OFF,NULL,modu_srep,modu_scomp) THEN
					ERROR "Report does NOT exist - please re-enter" 
					NEXT FIELD scomp 
				END IF 

			END IF 

			#FIELD tcomp 
			IF modu_tcomp IS NULL THEN 
				ERROR "You must enter a target company" 
				NEXT FIELD tcomp 
			ELSE 
				IF NOT db_company_pk_exists(UI_OFF,modu_tcomp) THEN
					NEXT FIELD tcomp 
				END IF 
			END IF 
			#FIELD trep
			IF modu_trep IS NULL THEN 
				ERROR "You must enter a target REPORT" 
				NEXT FIELD trep 
			END IF
			#Field tsline
			IF modu_tsline IS NULL OR modu_tsline = 0 THEN 
				LET modu_equal_flag = 1 
			END IF 

			
	END INPUT 
	#############################

	CLOSE WINDOW G184 
	LET modu_success_flag = 0 

	#HuHo please add some simple EXIT code without GOTO
	IF int_flag THEN 
		LET int_flag = false 
		RETURN FALSE 
	END IF 


	BEGIN WORK 
		#DISPLAY " Copying FROM: " , modu_rec_reporthead.report_code AT 11,10
		MESSAGE "Copying FROM: " , modu_rec_reporthead.report_code 

		IF modu_duplicate_flag = 0 THEN 
			SELECT * 
			INTO modu_rec_reporthead.* 
			FROM reporthead 
			WHERE cmpy_code = modu_scomp AND 
			report_code = modu_srep 

			LET modu_rec_reporthead.cmpy_code = modu_tcomp 
			LET modu_rec_reporthead.report_code = modu_trep 
			LET modu_err_message = "GS9 - Reporthead Insert" 
			INSERT INTO reporthead VALUES (modu_rec_reporthead.*) 
		END IF 

		DECLARE fini_curs CURSOR FOR 
		SELECT * 
		INTO modu_rec_reportdetl.* 
		FROM reportdetl 
		WHERE cmpy_code = modu_scomp AND 
		report_code = modu_srep AND 
		line_num >= modu_ssline AND 
		line_num <= modu_seline 
		ORDER BY line_num 

		LET modu_first_line_flag = 0 

		FOREACH fini_curs 
			IF modu_first_line_flag = 0 
			THEN 

				IF modu_equal_flag = 1 
				THEN 
					LET modu_tsline = modu_rec_reportdetl.line_num 
				END IF 

				LET modu_line_diff = modu_tsline - modu_rec_reportdetl.line_num 
				LET modu_first_line_flag = 1 
			END IF 

			#DISPLAY " Copying Line: " , modu_rec_reportdetl.line_num AT 12,10
			MESSAGE " Copying Line: " , modu_rec_reportdetl.line_num 

			LET modu_rec_reportdetl.cmpy_code = modu_tcomp 
			LET modu_rec_reportdetl.report_code = modu_trep 
			LET modu_rec_reportdetl.line_num = modu_rec_reportdetl.line_num + modu_line_diff 

			LET modu_err_message = "GS9 - Reportdetl Insert" 

			# This routine IS in a 'WHENEVER ERROR CONTINUE' so that it can trap
			#   any duplicate lines, AND give an error without going through a lockfunc
			#   routine

--			WHENEVER ERROR CONTINUE 

			INSERT INTO reportdetl VALUES (modu_rec_reportdetl.*) 

			CASE 
				WHEN status = 0 

				WHEN status = -239 
					LET l_msg = "Report line ",modu_rec_reportdetl.line_num,	" in REPORT ",modu_trep, " already exists"
					CALL fgl_winmessage("Error #1",l_msg,"ERROR") 
					ROLLBACK WORK 
					EXIT PROGRAM 

				OTHERWISE 
					LET l_msg = "Report line ",modu_rec_reportdetl.line_num,	" in REPORT ",modu_trep, " already exists"
					CALL fgl_winmessage("Error #2",l_msg,"ERROR") 
					ROLLBACK WORK 
					EXIT PROGRAM 
 
			END CASE 

		END FOREACH 

	COMMIT WORK 

	LET modu_success_flag = 1
	 
END FUNCTION