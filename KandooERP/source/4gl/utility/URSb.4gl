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

	Source code beautified by beautify.pl on 2020-01-03 18:54:48	$Id: $
}
{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module - URSb.4gl
# Purpose - This option will convert an ascii REPORT file TO a tab
#           delimitered file. This has been requested so that reports
#           generated can be transferred in a spread sheet.
#           It IS expected that headings AND text will NOT be neatly
#           converted but the numbers in columns will be.
#
#           All reports will be put INTO the users REPORT directory
#           this REPORT directory will be defined by the environment
#           variable REPORTDIR.
#

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "../utility/U_UT_GLOBALS.4gl" 
GLOBALS "../utility/UR_GROUP_GLOBALS.4gl"
GLOBALS "../utility/URS_GLOBALS.4gl" 

############################################################
# MODULE Scope Variables
############################################################
DEFINE modu_filename CHAR(60) 
DEFINE modu_directory CHAR(60) 
DEFINE modu_ans CHAR(1) 

###################################################################
# FUNCTION file_option()
#
#
###################################################################
FUNCTION file_option() 

	LET glob_file_idx = 1 

	IF NOT glob_arr_rec_file[glob_file_idx].filename IS NULL THEN 
		LET modu_directory = fgl_getenv("KANDOO_REPORT_PATH") 
		LET modu_filename = modu_directory clipped,	"/",	glob_arr_rec_file[glob_file_idx].filename clipped 

		OPEN WINDOW wu222 with FORM "U222" 
		CALL windecoration_u("U222") 

		DISPLAY glob_arr_rec_file[glob_file_idx].filename TO filename 
		DISPLAY glob_arr_rec_file[glob_file_idx].report_text TO report_text 
		DISPLAY modu_filename TO filename

		MENU "Copy Report" 
			BEFORE MENU 
				CALL publish_toolbar("kandoo","URSb","menu-copy_report") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			COMMAND "TAB" "Create TAB Formatted Report" 
				CALL tab_rep() 
				LET glob_file_idx = glob_file_idx + 1 

				IF glob_arr_rec_file[glob_file_idx].filename IS NULL THEN 
					EXIT MENU 
				END IF 

				LET modu_filename = modu_directory clipped, "/", 
				glob_arr_rec_file[glob_file_idx].filename clipped 
				DISPLAY BY NAME glob_arr_rec_file[glob_file_idx].filename, 
				glob_arr_rec_file[glob_file_idx].report_text 

				DISPLAY BY NAME modu_filename 

			COMMAND "ASCII" "Create ASCII Formatted Report" 
				CALL ascii_rep() 
				LET glob_file_idx = glob_file_idx + 1 
				IF glob_arr_rec_file[glob_file_idx].filename IS NULL THEN 
					EXIT MENU 
				END IF 
				LET modu_filename = modu_directory clipped, "/", 
				glob_arr_rec_file[glob_file_idx].filename clipped 

				DISPLAY BY NAME glob_arr_rec_file[glob_file_idx].filename, 
				--- modif ericv init #glob_arr_rec_file[glob_file_idx].report_text[1,40]
				glob_arr_rec_file[glob_file_idx].report_text 

				DISPLAY BY NAME modu_filename 

			COMMAND "DOS" "Create diskette copy" 
				CALL dos_rep() 
				LET glob_file_idx = glob_file_idx + 1 
				IF glob_arr_rec_file[glob_file_idx].filename IS NULL THEN 
					EXIT MENU 
				END IF 
				LET modu_filename = modu_directory clipped, "/", 
				glob_arr_rec_file[glob_file_idx].filename clipped 

				DISPLAY BY NAME glob_arr_rec_file[glob_file_idx].filename, 
				--- modif ericv init #glob_arr_rec_file[glob_file_idx].report_text[1,40]
				glob_arr_rec_file[glob_file_idx].report_text 

			COMMAND KEY(interrupt, "E") "Exit" "Exit FROM this program" 
				EXIT MENU 

		END MENU 

		CLOSE WINDOW wu222 

	END IF 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 

END FUNCTION {file_option} 


###################################################################
# FUNCTION get_filename(p_input)
#
#
###################################################################
FUNCTION get_filename(p_input) 
	DEFINE p_input CHAR(1) 
	DEFINE l_file_status INTEGER 
	DEFINE l_msgresp LIKE language.yes_flag 

	#1519 " Enter New Directory/Filename, - ESC TO continue - DEL TO Exit "
	LET l_msgresp = kandoomsg("U", 1519, "") 

	INPUT BY NAME modu_filename WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","URSb","input-filename") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		AFTER FIELD modu_filename 
			IF p_input = "D" THEN 
				IF modu_filename IS NULL THEN 
					LET modu_filename = glob_arr_rec_file[glob_file_idx].filename clipped,".TXT" 
				END IF 
			ELSE 
				LET l_file_status = afile_status(modu_filename) 
				IF l_file_status THEN 
					CASE l_file_status 
						WHEN 1 
							#Everything IS OK
						WHEN 5 
							#8505 "Over writing an existing file (Y/N).",
							LET l_msgresp = kandoomsg("U", 8505, "") 
							IF l_msgresp = "N" THEN 
								NEXT FIELD modu_filename 
							END IF 
						OTHERWISE 
							#9542 " Error in filename.  Please Try Again."
							LET l_msgresp = kandoomsg("U", 7500, "") 
							NEXT FIELD modu_filename 
					END CASE 
				END IF 
			END IF 
	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 

	RETURN true 
END FUNCTION {get_filename} 


###################################################################
# FUNCTION tab_rep()
###################################################################
FUNCTION tab_rep() 
	DEFINE l_run CHAR(1300) 
	DEFINE l_substitute CHAR(250)
	DEFINE l_error INTEGER 
	DEFINE l_msgresp LIKE language.yes_flag 


	IF get_filename("T") THEN 
		#1520 "Compiling Report Please Wait"
		LET l_msgresp = kandoomsg("U", 1521, "") 

		LET l_substitute = "s\/ *\/",ASCII(9),"\/g" 
		LET l_run = "sed '", 
		l_substitute clipped, 
		"' ", 
		trim(get_settings_reportPath()), 
		glob_arr_rec_file[glob_file_idx].filename clipped, 
		" > ", 
		modu_filename 

		RUN l_run RETURNING l_error 

		IF l_error THEN 
			#7500 "Completed with an error. Press Any Key TO Cont ..
			LET l_msgresp = kandoomsg("U", 7500, "") 
		ELSE 
			#2500 "Completed Sucessfully"
			LET l_msgresp = kandoomsg("U", 2500, "") 
		END IF 

	END IF 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 

END FUNCTION {tab_rep} 


###################################################################
# FUNCTION ascii_rep()
###################################################################
FUNCTION ascii_rep() 
	DEFINE l_run CHAR(70) 
	DEFINE l_ans CHAR(1) 
	DEFINE l_error INTEGER 
	DEFINE l_msgresp LIKE language.yes_flag 

	IF get_filename("A") THEN 
		LET l_run = 'cp ', 
		trim(get_settings_reportPath()), 
		glob_arr_rec_file[glob_file_idx].filename clipped, 
		' ', 
		modu_filename 

		RUN l_run RETURNING l_error 
		IF l_error THEN 
			#7500 "Completed with an error. Press Any Key TO Cont ..
			LET l_msgresp = kandoomsg("U", 7500, "") 
		ELSE 
			#2500 "Completed Sucessfully"
			LET l_msgresp = kandoomsg("U", 2500, "") 
		END IF 
	END IF 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 

END FUNCTION {ascii_rep} 


###################################################################
# FUNCTION dos_rep()
#
# doswrite FUNCTION
###################################################################
FUNCTION dos_rep() 
	DEFINE l_run CHAR(70) 
	DEFINE l_ans CHAR(1)
--	DEFINE l_dev_name CHAR(10) 
	DEFINE l_error INTEGER 
	DEFINE l_msgresp LIKE language.yes_flag 

	IF get_filename("D") THEN 
		LET l_msgresp = kandoomsg("U",1501,"") 
		# "Insert diskette AND continue (Y/N) "

		IF upshift(l_msgresp) = "Y" THEN 

			LET l_msgresp = kandoomsg("U",1521,"") 
			# MESSAGE "Writing REPORT TO diskette....please wait"

			LET l_run = "doswrite -av ", trim(get_settings_reportPath()), "/", 
			glob_arr_rec_file[glob_file_idx].filename clipped, 
			" ", modu_filename clipped 
			RUN l_run RETURNING l_error 

			IF l_error = 0 THEN 
				UPDATE rmsreps 
				SET status_text = "Diskette" 
				WHERE report_code = glob_arr_rec_file[glob_file_idx].report_code 
				#2500 "Completed Sucessfully"
				LET l_msgresp = kandoomsg("U", 2500, "") 
			ELSE 
				#7500 "Completed with an error. Press Any Key TO Cont ..
				LET l_msgresp = kandoomsg("U", 7500, "") 
			END IF 

			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
			END IF 

		END IF 

	END IF 
END FUNCTION {dos_rep}