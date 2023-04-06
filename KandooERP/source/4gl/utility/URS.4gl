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
	Source code beautified by beautify.pl on 2020-01-03 18:54:47	$Id: $
}
#            URS IS the Report Management System
#
# Printing - Passes the REPORT file through the page selection filter
#            INTO a temp file(.temp1).IF NOT compressed PRINT it THEN
#            prints the temp1 file. IF compressed PRINT chosen THEN it
#            passes the ascii compression chars TO a second temporary
#            file(.temp2), cats the first temporary file in AND
#            appends the non-compression chars INTO the second temp
#            file AND prints it. All temp files are deleted.


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "../utility/U_UT_GLOBALS.4gl" 
GLOBALS "../utility/UR_GROUP_GLOBALS.4gl"
GLOBALS "../utility/URS_GLOBALS.4gl" 

###################################################################
# MAIN
#
#
###################################################################
MAIN 
	DEFINE l_runner CHAR(100) 
	DEFINE l_rep_criteria CHAR(200) 
	DEFINE l_cancel CHAR(16) 
	DEFINE l_version CHAR(1) 
	DEFINE l_ans CHAR(1) 
	DEFINE i SMALLINT 
	DEFINE l_file_cmd CHAR(20) 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_report_code LIKE rmsreps.report_code
	DEFINE l_file_text LIKE rmsreps.file_text

	DEFINE l_rec_rmsreps RECORD LIKE rmsreps.*

	DEFER quit 
	DEFER interrupt 
		
	#Initial UI Init
	CALL setModuleId("URS") 
	CALL ui_init(0) #initial ui init 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_u_ut() #init utility module 

	#   SELECT kandoo_type INTO l_version FROM kandooinfo
	#   SELECT * INTO glob_rec_kandoouser.* FROM kandoouser
	#     WHERE sign_on_code = glob_rec_kandoouser.sign_on_code

--	WHENEVER ERROR CONTINUE 
	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 

	LET l_rep_criteria = NULL 
	--LET glob_thirty_four = 34 --very interesting 

	CALL set_os_arch() 

	OPEN WINDOW u113 with FORM "U113" 
	CALL windecoration_u("U113") 
	CALL displaymoduletitle(NULL)
	
	LET l_report_code = get_url_report_code()
	LET l_file_text = get_url_report_file_text()

	IF l_report_code IS NOT NULL AND l_report_code != 0 THEN
		SELECT *
		INTO l_rec_rmsreps.* 
		FROM rmsreps	
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
		AND report_code = l_report_code
		IF status != notfound THEN
			CALL direct_print(l_rec_rmsreps.*,"screen")
		END IF
	ELSE	
		IF l_file_text IS NOT NULL THEN
			SELECT *
			INTO l_rec_rmsreps.* 
			FROM rmsreps	
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
			AND file_text = l_file_text
			IF status != notfound THEN
				CALL direct_print(l_rec_rmsreps.*,"screen")
			END IF
		ELSE
			#We continue with the report file/print manager

				

	CALL scan_reps(l_rep_criteria) 
	###
	WHILE sel_line("V") 
		#IF sel_line("V") THEN
		IF tagged() THEN 
			IF upd_tags() THEN 
				CURRENT WINDOW IS u113 
				CALL scan_reps(l_rep_criteria) 
			ELSE 
				CURRENT WINDOW IS u113 
			END IF 
		END IF 
		#END IF
		CALL check_for_memo() 
	END WHILE 
	####

	{
	   menu "URS"
	      	BEFORE MENU
	      	 	CALL publish_toolbar("kandoo","URS","menu-urs")

					ON ACTION "WEB-HELP"
				CALL onlineHelp(getModuleId(),NULL)

				ON ACTION "actToolbarManager"
					 	CALL setupToolbar()

				ON ACTION "ACCEPT"
	         IF sel_line("V") THEN
	            IF tagged() THEN
	               IF upd_tags() THEN
	                  CURRENT WINDOW IS U113
	                  CALL scan_reps(l_rep_criteria)
	               ELSE
	                  CURRENT WINDOW IS U113
	               END IF
	            END IF
	         END IF
	         CALL check_for_memo()


	#      COMMAND "View" "DISPLAY a Report TO Screen"
	#         IF sel_line("V") THEN
	#            IF tagged() THEN
	#               IF upd_tags() THEN
	#                  CURRENT WINDOW IS U113
	#                  CALL scan_reps(l_rep_criteria)
	#               ELSE
	#                  CURRENT WINDOW IS U113
	#               END IF
	#            END IF
	#         END IF
	#         CALL check_for_memo()

	#      COMMAND KEY ("P",f11) "Print" "Print a Report TO the Printer"
	#         IF sel_line("P") THEN
	#            IF tagged() THEN
	#               IF upd_tags() THEN
	#                  CURRENT WINDOW IS U113
	#                  CALL scan_reps(l_rep_criteria)
	#               ELSE
	#                  CURRENT WINDOW IS U113
	#               END IF
	#            END IF
	#         END IF
	#         CALL check_for_memo()

	#      COMMAND "Bulk-Print" "Tag a Report FOR Bulk Printing"
	#         IF sel_line("B") THEN
	#            IF tagged() THEN
	#               IF upd_tags() THEN
	#                  CURRENT WINDOW IS U113
	#                  CALL scan_reps(l_rep_criteria)
	#               ELSE
	#                  CURRENT WINDOW IS U113
	#               END IF
	#            END IF
	#         END IF
	#         CALL check_for_memo()

	#     COMMAND "DELETE" "Delete a Report"
	#        IF sel_line("D") THEN
	#           IF tagged() THEN
	#              IF upd_tags() THEN
	#                 CURRENT WINDOW IS U113
	#                 CALL scan_reps(l_rep_criteria)
	#              ELSE
	#                 CURRENT WINDOW IS U113
	#              END IF
	#           END IF
	#        END IF
	#        CALL check_for_memo()

	#     COMMAND "File" "Copy a REPORT (ASCII/TAB Format)"
	#        IF sel_line("F") THEN
	#           IF tagged() THEN
	#              IF upd_tags() THEN
	#                 CURRENT WINDOW IS U113
	#                 CALL scan_reps(l_rep_criteria)
	#              ELSE
	#                 CURRENT WINDOW IS U113
	#              END IF
	#           END IF
	#        END IF
	#        CALL check_for_memo()

	      COMMAND "Status" "DISPLAY Printer Status"
		      CALL fgl_winmessage("Needs sorting - original code for Linux only","Please look AT background Unix window FOR printer STATUS ","info")

	        run "lpstat -t 2>>", trim(get_settings_logFile()) 
	        CURRENT WINDOW IS U113
	#DISPLAY "" AT 2,1
	# prompt " Press RETURN TO continue"
	#   FOR CHAR l_ans
	         CALL check_for_memo()

	      COMMAND "Cancel Printer" "Cancel a printer"

	#prompt " Printer ID?....." FOR l_cancel
	#LET l_runner = "cancel ",l_cancel," 2>>",trim(get_settings_logFile()) 
	#run l_runner
	         CALL check_for_memo()

	      COMMAND "Sort" "Sort/Order REPORT listings"
	         LET l_rep_criteria = f_sort()
	         IF l_rep_criteria IS NOT NULL THEN
	            CALL scan_reps(l_rep_criteria)
	         END IF
	         CALL check_for_memo()

	      ON ACTION "Filter"
	#COMMAND "Query" "Limit DISPLAY of Reports"
	         LET l_rep_criteria = f_query()
	         IF l_rep_criteria IS NOT NULL THEN
	            CALL scan_reps(l_rep_criteria)
	         END IF
	         CALL check_for_memo()

				ON ACTION "CANCEL"
	#COMMAND KEY (interrupt,"E") "Exit" "RETURN TO Menus "
	         EXIT MENU

	      COMMAND KEY (control-w)
	         CALL kandoohelp("")

	   END MENU
	}
	CLEAR screen 
	CLOSE WINDOW u113 

	LET int_flag = false 
	LET quit_flag = false

		END IF
	END IF
	 
END MAIN 


###################################################################
# FUNCTION scan_reps(p_where_text)
#
#
###################################################################
FUNCTION scan_reps(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_rec_rmsreps RECORD LIKE rmsreps.* 
	DEFINE l_query_text STRING 
	DEFINE i SMALLINT 
	DEFINE l_idx SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	CLEAR FORM 

	CALL glob_arr_rec_rpt_rmsreps_list.clear() 
	CALL glob_arr_rec_rms_code.clear() 

	IF p_where_text IS NULL 
	OR p_where_text = " " THEN 
		LET p_where_text = " entry_code = \"",glob_rec_kandoouser.sign_on_code, 
		"\" ORDER BY report_date desc,", 
		"report_time desc" 
	END IF 

	LET l_query_text = "SELECT * FROM rmsreps ", 
	"WHERE cmpy_code =\"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND ",p_where_text clipped 
	PREPARE s_rmsreps FROM l_query_text 
	DECLARE c_rmsreps CURSOR FOR s_rmsreps 



	LET l_idx = 0 
	FOREACH c_rmsreps INTO l_rec_rmsreps.* 
		LET l_idx = l_idx + 1 
		LET glob_arr_rec_rpt_rmsreps_list[l_idx].scroll_flag = NULL 
		LET glob_arr_rec_rpt_rmsreps_list[l_idx].report_pgm_text = l_rec_rmsreps.report_pgm_text
		LET glob_arr_rec_rpt_rmsreps_list[l_idx].report_text = l_rec_rmsreps.report_text[1,55] 
		LET glob_arr_rec_rpt_rmsreps_list[l_idx].report_date = l_rec_rmsreps.report_date
		LET glob_arr_rec_rpt_rmsreps_list[l_idx].report_time = l_rec_rmsreps.report_time
#		LET glob_arr_rec_rpt_rmsreps_list[l_idx].printed_ind = l_rec_rmsreps.printed_ind 
		LET glob_arr_rec_rpt_rmsreps_list[l_idx].status_text = l_rec_rmsreps.status_text
		LET glob_arr_rec_rpt_rmsreps_list[l_idx].status_ind = l_rec_rmsreps.status_ind 
		LET glob_arr_rec_rpt_rmsreps_list[l_idx].report_code = l_rec_rmsreps.report_code
		LET glob_arr_rec_rms_code[l_idx].report_code = l_rec_rmsreps.report_code 
		
		#Detailed View - on current row 
		IF l_rec_rmsreps.status_text[1,1] = "S" THEN 
			LET glob_arr_rec_rpt_rmsreps_list[l_idx].printed_ind = "S" 
		ELSE 
			LET glob_arr_rec_rpt_rmsreps_list[l_idx].printed_ind = " " 
		END IF 

		LET glob_arr_rec_rms_code[l_idx].status_text = l_rec_rmsreps.status_text 
		LET glob_arr_rec_rms_code[l_idx].action_text = NULL 

		#IF l_idx = 200 THEN
		#   LET l_msgresp = kandoomsg("U",6100,l_idx)
		#   EXIT FOREACH
		#END IF

		#      IF l_idx <= 11 THEN
		#         IF glob_arr_rec_rms_code[l_idx].report_code IS NULL
		#         OR glob_arr_rec_rms_code[l_idx].report_code = 0 THEN
		#            INITIALIZE glob_arr_rec_rpt_rmsreps_list[l_idx].* TO NULL
		#         END IF
		#      END IF

		# LET arr_size = l_idx

	END FOREACH 


	#   IF arr_size > 11 THEN  --??? what the fXxx?
	#      LET arr_size = 11
	#   END IF
	# The reason this DISPLAY statement AND its accompanying code are outside the
	# the FOREACH IS due TO an informix "random" bug  affecting all releases
	# AFTER 4.14 that causes pcode errors WHEN same code IS run in different
	# versions.

	IF glob_arr_rec_rms_code.getlength() = 0 THEN 
		CALL glob_arr_rec_rpt_rmsreps_list.clear() 
		#FOR i = 1 TO 11
		#INITIALIZE glob_arr_rec_rpt_rmsreps_list[i].* TO NULL
		#          DISPLAY glob_arr_rec_rpt_rmsreps_list[i].* TO sr_rms[i].*
		#
		#END FOR
	ELSE 

		#     FOR i = 1 TO arr_size
		#
		#       DISPLAY glob_arr_rec_rpt_rmsreps_list[i].* TO sr_rms[i].*
		#
		#     END FOR
	END IF 

	--LET l_msgresp = kandoomsg("U",9113,l_idx) # message = n rows selected 
	# LET arr_size = l_idx

	CALL disp_report_properties(1) 
END FUNCTION 


###################################################################
# FUNCTION sel_line(p_output_option)
#
# RETURNS
###################################################################
FUNCTION sel_line(p_output_option) 
	DEFINE p_output_option CHAR(1) 
	DEFINE l_email CHAR(100) 
	DEFINE l_file_name STRING 
	DEFINE l_ps_file_name STRING 
	DEFINE l_runner CHAR(300) 
	DEFINE l_run_string1 STRING 
	DEFINE l_run_string2 STRING 
	DEFINE l_run_string3 STRING 
	DEFINE l_run_string4 STRING 
	DEFINE l_script_text CHAR(100) 
	DEFINE l_report_text LIKE rmsreps.report_text 
	DEFINE h SMALLINT 
	DEFINE x SMALLINT 
	DEFINE j SMALLINT 
	DEFINE y SMALLINT 
	DEFINE i SMALLINT 
	DEFINE l_idx SMALLINT 
	DEFINE l_len SMALLINT 
	DEFINE l_rep_criteria CHAR(200) 
	DEFINE l_msgresp LIKE language.yes_flag 


	#huho
	DISPLAY p_output_option TO output_option 
	CALL ui.interface.refresh() 
	IF p_output_option IS NULL THEN 
		LET p_output_option = "V" --make REPORT VIEW the default 
	END IF 

	#   CALL set_count(arr_size)
--	LET l_msgresp = kandoomsg("U",1040,"") 
	#DISPLAY "Hello1"
	#1040 RETURN TO view REPORT
	--CALL d_msg(p_output_option) #no longer used/required

	#DISPLAY "Hello2"
	#INPUT ARRAY glob_arr_rec_rpt_rmsreps_list WITHOUT DEFAULTS FROM sr_rms.* ATTRIBUTE(UNBUFFERED)
	#---------------------------------------------------------------------------------
	DIALOG ATTRIBUTE(UNBUFFERED) 

	DISPLAY ARRAY glob_arr_rec_rpt_rmsreps_list TO sr_rms.* 
		BEFORE ROW 
			LET l_idx = arr_curr() 
			CALL disp_report_properties(l_idx) --update RECORD detail section (row preview) 
			--DISPLAY p_output_option TO output_option
			--CALL ui.interface.refresh() 
{
		ON ACTION "ACCEPT" --depends ON PRINT option state "D" (delete) OR b(Bulk) (..., could it be PRINT option v / p/ b / d / f ) 
			CASE p_output_option 
			#DEFAULT/Otherwise
			#WHEN "V" --View
			#	LET l_report_text = glob_arr_rec_rpt_rmsreps_list[l_idx].report_text
			#	CALL disp_report_properties(l_idx)
			#	CALL urs_line_select_process(l_idx,p_output_option)

				WHEN "D" --delete 
					IF (glob_arr_rec_rpt_rmsreps_list[l_idx].status_ind IS NULL OR 
					glob_arr_rec_rpt_rmsreps_list[l_idx].status_ind != "D") 
					AND glob_arr_rec_rms_code[l_idx].report_code IS NOT NULL --? 
					AND glob_arr_rec_rms_code[l_idx].report_code != 0 THEN --? 
						IF check_auth_with_idx_or_code(l_idx,NULL,"D") THEN 
							LET glob_arr_rec_rpt_rmsreps_list[l_idx].status_ind = "D" 
							LET glob_arr_rec_rms_code[l_idx].action_text = MODE_CLASSIC_DELETE 
							LET glob_arr_rec_rms_code[l_idx].status_text = "To Delete" 
						ELSE 
							#No password entered
							#don't change anything
						END IF 

					ELSE 

						IF glob_arr_rec_rpt_rmsreps_list[l_idx].status_ind = "D" THEN 
							LET glob_arr_rec_rpt_rmsreps_list[l_idx].status_ind = NULL 
							LET glob_arr_rec_rms_code[l_idx].action_text = NULL 
						END IF 
					END IF

				OTHERWISE 
					LET l_report_text = glob_arr_rec_rpt_rmsreps_list[l_idx].report_text 
					CALL disp_report_properties(l_idx) 
					CALL urs_line_select_process(l_idx,p_output_option)

			END CASE 
}

			# ON ACTION ACCEPT  #New huho
			#     LET l_report_text = glob_arr_rec_rpt_rmsreps_list[l_idx].report_text
			#    CALL disp_report_properties(l_idx)
			#
			#         CALL urs_line_select_process(l_idx,p_output_option)

			#      BEFORE FIELD report_text
			#
			#				CALL urs_line_select_process(l_idx,p_output_option)
			{
			#huho
							DISPLAY BY NAME p_output_option

			         CASE p_output_option

			            WHEN "V"
			               IF glob_arr_rec_rms_code[l_idx].report_code IS NOT NULL
			               AND glob_arr_rec_rms_code[l_idx].report_code != 0 THEN
			                  CALL f_view(l_idx)
			               END IF

			            WHEN "P"
			               IF glob_arr_rec_rms_code[l_idx].report_code IS NOT NULL
			               AND glob_arr_rec_rms_code[l_idx].report_code != 0 THEN
			                  SELECT unique 1 FROM rmsreps
			                   WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
			                     AND report_code  = glob_arr_rec_rms_code[l_idx].report_code
			                     AND status_text = "Sent TO Print"
			                     AND printonce_flag = "Y"

			                  IF STATUS = 0 THEN
			                     LET l_msgresp = kandoomsg("U",9048,"")
			#9048 Cannot PRINT reportl; Already Printed
			                     NEXT FIELD scroll_flag
			                  END IF

			                  INITIALIZE glob_rec_print.* TO NULL

			                  IF f_print(l_idx) THEN
			                     IF glob_rec_print.print_x != "Y" THEN
			                        UPDATE rmsreps
			                          SET status_text = "Sent TO Print"
			                          WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
			                            AND report_code  = glob_arr_rec_rms_code[l_idx].report_code
			                        LET glob_arr_rec_rpt_rmsreps_list[l_idx].printed_ind = "S"
			                        LET glob_arr_rec_rpt_rmsreps_list[l_idx].status_ind  = NULL
			                        LET glob_arr_rec_rms_code[l_idx].status_text = "Sent TO Print"
			                     END IF
			                  END IF

			               END IF

			            WHEN "B"
			               IF (glob_arr_rec_rpt_rmsreps_list[l_idx].status_ind IS NULL OR
			                  glob_arr_rec_rpt_rmsreps_list[l_idx].status_ind != "P")
			               AND glob_arr_rec_rms_code[l_idx].report_code IS NOT NULL
			               AND glob_arr_rec_rms_code[l_idx].report_code != 0 THEN

			                  IF check_auth_with_idx_or_code(l_idx,NULL,"P") THEN
			                     SELECT unique 1 FROM rmsreps
			                      WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
			                        AND report_code  = glob_arr_rec_rms_code[l_idx].report_code
			                        AND status_text = "Sent TO Print"
			                        AND printonce_flag = "Y"

			                     IF STATUS = 0 THEN
			                        LET l_msgresp = kandoomsg("U",9048,"")
			#9048 Cannot PRINT reportl; Already Printed
			                        NEXT FIELD scroll_flag
			                     END IF

			                     LET glob_arr_rec_rpt_rmsreps_list[l_idx].status_ind = "P"
			                     LET glob_arr_rec_rms_code[l_idx].action_text = "Print"
			                     LET glob_arr_rec_rms_code[l_idx].status_text = "To Print"
			                  END IF

			               ELSE

			                  IF glob_arr_rec_rpt_rmsreps_list[l_idx].status_ind = "P" THEN
			                     LET glob_arr_rec_rpt_rmsreps_list[l_idx].status_ind = NULL
			                     LET glob_arr_rec_rms_code[l_idx].action_text = NULL
			                     LET glob_arr_rec_rms_code[l_idx].status_text = NULL
			                  END IF

			               END IF

			            WHEN "D"
			               IF (glob_arr_rec_rpt_rmsreps_list[l_idx].status_ind IS NULL OR
			                  glob_arr_rec_rpt_rmsreps_list[l_idx].status_ind != "D")
			               AND glob_arr_rec_rms_code[l_idx].report_code IS NOT NULL
			               AND glob_arr_rec_rms_code[l_idx].report_code != 0 THEN
			                  IF check_auth_with_idx_or_code(l_idx,NULL,"D") THEN
			                     LET glob_arr_rec_rpt_rmsreps_list[l_idx].status_ind = "D"
			                     LET glob_arr_rec_rms_code[l_idx].action_text = MODE_CLASSIC_DELETE
			                     LET glob_arr_rec_rms_code[l_idx].status_text = "To Delete"
			                  END IF

			               ELSE

			                  IF glob_arr_rec_rpt_rmsreps_list[l_idx].status_ind = "D" THEN
			                     LET glob_arr_rec_rpt_rmsreps_list[l_idx].status_ind = NULL
			                     LET glob_arr_rec_rms_code[l_idx].action_text = NULL
			                     LET glob_arr_rec_rms_code[l_idx].status_text = NULL
			                  END IF
			               END IF

			            WHEN "F"
			               IF (glob_arr_rec_rpt_rmsreps_list[l_idx].status_ind IS NULL OR
			                  glob_arr_rec_rpt_rmsreps_list[l_idx].status_ind != "F")
			               AND glob_arr_rec_rms_code[l_idx].report_code IS NOT NULL
			               AND glob_arr_rec_rms_code[l_idx].report_code != 0 THEN
			                  LET glob_arr_rec_rpt_rmsreps_list[l_idx].status_ind = "F"
			                  LET glob_arr_rec_rms_code[l_idx].action_text = "File"
			                  LET glob_arr_rec_rms_code[l_idx].status_text = "To File"

			               ELSE

			                  IF glob_arr_rec_rpt_rmsreps_list[l_idx].status_ind = "F" THEN
			                     LET glob_arr_rec_rpt_rmsreps_list[l_idx].status_ind = NULL
			                     LET glob_arr_rec_rms_code[l_idx].action_text = NULL
			                     LET glob_arr_rec_rms_code[l_idx].status_text = NULL
			                  END IF
			               END IF

			            WHEN "M"
			               IF glob_arr_rec_rms_code[l_idx].report_code IS NOT NULL
			               AND glob_arr_rec_rms_code[l_idx].report_code != 0 THEN

			                  SELECT email
			                    INTO l_email
			                    FROM kandoouser
			                   WHERE sign_on_code = glob_rec_kandoouser.sign_on_code

			                  LET l_file_name = fgl_getenv("KANDOODIR")
			                  LET l_file_name = l_file_name clipped,
			                               "/reports/", glob_rec_kandoouser.cmpy_code clipped, ".",
			                               glob_arr_rec_rms_code[l_idx].report_code using "<<<<<<<<"
			                  LET l_runner = 'perl /apps/misc/bin/send_attach ',
			                               l_email clipped, ' ',
			                               l_file_name clipped, ' "',
			                               glob_arr_rec_rpt_rmsreps_list[l_idx].report_text clipped, '"'

			                  run l_runner without waiting

			                  LET glob_arr_rec_rpt_rmsreps_list[l_idx].printed_ind = "M"
			                  LET glob_arr_rec_rpt_rmsreps_list[l_idx].status_ind  = NULL
			                  LET glob_arr_rec_rms_code[l_idx].status_text = "Sent TO Email"

			               END IF

			         END CASE
			         LET int_flag = FALSE
			         LET quit_flag = FALSE

			#DISPLAY glob_arr_rec_rpt_rmsreps_list[l_idx].* TO sr_rms[scrn].*

			         NEXT FIELD scroll_flag
			}
			#AFTER ROW
			#DISPLAY glob_arr_rec_rpt_rmsreps_list[l_idx].* TO sr_rms[scrn].*
			 {
			      ON KEY(F2)  --delete marker
			         IF (glob_arr_rec_rpt_rmsreps_list[l_idx].status_ind IS NULL OR
			             glob_arr_rec_rpt_rmsreps_list[l_idx].status_ind != "D")
			         AND glob_arr_rec_rms_code[l_idx].report_code IS NOT NULL
			         AND glob_arr_rec_rms_code[l_idx].report_code != 0 THEN
			            IF check_auth_with_idx_or_code(l_idx,NULL,"D") THEN
			               LET glob_arr_rec_rpt_rmsreps_list[l_idx].status_ind = "D"
			               LET glob_arr_rec_rms_code[l_idx].action_text = MODE_CLASSIC_DELETE
			               LET glob_arr_rec_rms_code[l_idx].status_text = "To Delete"
			            END IF

			         ELSE

			            IF glob_arr_rec_rpt_rmsreps_list[l_idx].status_ind = "D" THEN
			               LET glob_arr_rec_rpt_rmsreps_list[l_idx].status_ind = NULL
			               LET glob_arr_rec_rms_code[l_idx].action_text = NULL
			            END IF
			         END IF

			         LET int_flag = FALSE
			         LET quit_flag = FALSE

			         NEXT FIELD scroll_flag
			}
			{
			      ON KEY(F8) --Depends on PRINT option state "D" (delete) OR B(Bulk)  (..., could it be PRINT option V / P/ B / D / F )
			--D = Delete
			--P = Print
			         IF p_output_option = "D" THEN

			#FOR i = 1 TO 200
			            FOR i = 1 TO glob_arr_rec_rpt_rmsreps_list.getLength()

			               IF (glob_arr_rec_rpt_rmsreps_list[i].status_ind IS NULL OR
			                   glob_arr_rec_rpt_rmsreps_list[i].status_ind != "D")
			               AND glob_arr_rec_rms_code[i].report_code IS NOT NULL
			               AND glob_arr_rec_rms_code[i].report_code != 0 THEN
			                  IF check_auth_with_idx_or_code(i,NULL,"D") THEN
			                     LET glob_arr_rec_rpt_rmsreps_list[i].status_ind = "D"
			                     LET glob_arr_rec_rms_code[i].action_text = MODE_CLASSIC_DELETE
			                     LET glob_arr_rec_rms_code[i].status_text = "To Delete"
			                  ELSE
			#No password entered
			                     EXIT FOR
			                  END IF

			               ELSE

			                  IF glob_arr_rec_rpt_rmsreps_list[i].status_ind = "D" THEN
			                     LET glob_arr_rec_rpt_rmsreps_list[i].status_ind = NULL
			                     LET glob_arr_rec_rms_code[i].action_text = NULL
			                  END IF
			               END IF

			               IF glob_arr_rec_rpt_rmsreps_list[i].report_text IS NULL THEN
			                  EXIT FOR
			               END IF

			            END FOR

			#LET h = arr_curr()
			#LET x = scr_line()
			#LET j = 11 - x
			#LET y = (h - x) + 1
			#LET scrn = 1

			#FOR i = y TO (y + 12)
			#   IF i <= arr_count() THEN
			#      IF scrn <= 11 THEN
			#         DISPLAY glob_arr_rec_rpt_rmsreps_list[i].* TO sr_rms[scrn].*
			#
			#         LET scrn = scrn + 1
			#      END IF
			#   END IF
			#END FOR

			#LET scrn = scr_line()
			         END IF

			#Print Option ="B"
			         IF p_output_option = "B" THEN
			#FOR i = 1 TO 200
			            FOR i = 1 TO glob_arr_rec_rpt_rmsreps_list.getLength()
			               IF (glob_arr_rec_rpt_rmsreps_list[i].status_ind IS NULL OR
			                   glob_arr_rec_rpt_rmsreps_list[i].status_ind != "P")
			               AND glob_arr_rec_rms_code[i].report_code IS NOT NULL
			               AND glob_arr_rec_rms_code[i].report_code != 0 THEN

			                  SELECT unique 1 FROM rmsreps
			                   WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
			                     AND report_code  = glob_arr_rec_rms_code[i].report_code
			                     AND status_text = "Sent TO Print"
			                     AND printonce_flag = "Y"

			                  IF STATUS = 0 THEN
			                     continue FOR
			                  END IF

			                  IF check_auth_with_idx_or_code(i,NULL,"P") THEN
			                     LET glob_arr_rec_rpt_rmsreps_list[i].status_ind = "P"
			                     LET glob_arr_rec_rms_code[i].action_text = "Print"
			                     LET glob_arr_rec_rms_code[i].status_text = "To Print"
			                  ELSE
			#No password entered
			                     EXIT FOR
			                  END IF

			               ELSE

			                  IF glob_arr_rec_rpt_rmsreps_list[i].status_ind = "P" THEN
			                     LET glob_arr_rec_rpt_rmsreps_list[i].status_ind = NULL
			                     LET glob_arr_rec_rms_code[i].action_text = NULL
			                  END IF

			               END IF

			               IF glob_arr_rec_rpt_rmsreps_list[i].report_text IS NULL THEN
			                  EXIT FOR
			               END IF

			            END FOR

			#LET h = arr_curr()
			#LET x = scr_line()
			#LET j = 11 - x
			#LET y = (h - x) + 1
			#LET scrn = 1

			#FOR i = y TO (y + 12)
			#   IF i <= arr_count() THEN
			#      IF scrn <= 11 THEN
			#         DISPLAY glob_arr_rec_rpt_rmsreps_list[i].* TO sr_rms[scrn].*
			#
			#         LET scrn = scrn + 1
			#      END IF
			#   END IF
			#END FOR

			#LET scrn = scr_line()

			         END IF

			         NEXT FIELD scroll_flag
			}
			 {
			      ON KEY(F10)  --change PRINT option V / P/ B / D / F
			         CASE p_output_option
			            WHEN "V"
			               LET p_output_option = "P"
			            WHEN "P"
			               LET p_output_option = "B"
			            WHEN "B"
			               LET p_output_option = "D"
			            WHEN "D"
			               LET p_output_option = "F"
			            WHEN "F"
			               LET p_output_option = "V"
			         END CASE

			#huho added TO see what's going on
			         DISPLAY BY NAME p_output_option

			         CALL d_msg(p_output_option)
			}
			#      ON KEY (control-w)
			#         CALL kandoohelp("")

	END DISPLAY 

	###############################################################################################################

	INPUT p_output_option WITHOUT DEFAULTS FROM output_option 
		ON CHANGE output_option 
			--CALL d_msg(p_output_option) #no longer required - we use a listbox with labels  
	END INPUT 

	################################################################################################################

	#DIALOG ACTIONS

		ON ACTION "ACCEPT" --depends ON PRINT option state "D" (delete) OR b(Bulk) (..., could it be PRINT option v / p/ b / d / f ) 
			CASE p_output_option 
			#DEFAULT/Otherwise
			#WHEN "V" --View
			#	LET l_report_text = glob_arr_rec_rpt_rmsreps_list[l_idx].report_text
			#	CALL disp_report_properties(l_idx)
			#	CALL urs_line_select_process(l_idx,p_output_option)

				WHEN "D" --delete 
					IF (glob_arr_rec_rpt_rmsreps_list[l_idx].status_ind IS NULL OR 
					glob_arr_rec_rpt_rmsreps_list[l_idx].status_ind != "D") 
					AND glob_arr_rec_rms_code[l_idx].report_code IS NOT NULL --? 
					AND glob_arr_rec_rms_code[l_idx].report_code != 0 THEN --? 
						IF check_auth_with_idx_or_code(l_idx,NULL,"D") THEN 
							LET glob_arr_rec_rpt_rmsreps_list[l_idx].status_ind = "D" 
							LET glob_arr_rec_rms_code[l_idx].action_text = MODE_CLASSIC_DELETE 
							LET glob_arr_rec_rms_code[l_idx].status_text = "To Delete" 
						ELSE 
							#No password entered
							#don't change anything
						END IF 

					ELSE 

						IF glob_arr_rec_rpt_rmsreps_list[l_idx].status_ind = "D" THEN 
							LET glob_arr_rec_rpt_rmsreps_list[l_idx].status_ind = NULL 
							LET glob_arr_rec_rms_code[l_idx].action_text = NULL 
						END IF 
					END IF

				OTHERWISE 
					LET l_report_text = glob_arr_rec_rpt_rmsreps_list[l_idx].report_text 
					CALL disp_report_properties(l_idx) 
					CALL urs_line_select_process(l_idx,p_output_option)

			END CASE 


	ON KEY (F8) --depends ON PRINT option state "D" (delete) OR b (Bulk) (..., could it be PRINT option v / p/ b / d / f ) 
		--D = Delete
		--P = Print

		CALL fgl_winmessage("p_output_option",p_output_option,"info") 
		#call fgl_winmessage("F8","F8","info")
		#call fgl_winmessage("ACCEPT","ACCEPT","info")


		---------- V = VIEW ------------------------------------------------------

		IF p_output_option = "V" THEN 
			LET l_report_text = glob_arr_rec_rpt_rmsreps_list[l_idx].report_text 
			CALL disp_report_properties(l_idx) 
			CALL urs_line_select_process(l_idx,p_output_option) 
		END IF 

		---------- D = DELETE ------------------------------------------------------

		IF p_output_option = "D" THEN 

			#FOR i = 1 TO 200
			FOR i = 1 TO glob_arr_rec_rpt_rmsreps_list.getlength() 

				IF (glob_arr_rec_rpt_rmsreps_list[i].status_ind IS NULL OR 
				glob_arr_rec_rpt_rmsreps_list[i].status_ind != "D") 
				AND glob_arr_rec_rms_code[i].report_code IS NOT NULL 
				AND glob_arr_rec_rms_code[i].report_code != 0 THEN 
					IF check_auth_with_idx_or_code(i,NULL,"D") THEN 
						LET glob_arr_rec_rpt_rmsreps_list[i].status_ind = "D" 
						LET glob_arr_rec_rms_code[i].action_text = MODE_CLASSIC_DELETE 
						LET glob_arr_rec_rms_code[i].status_text = "To Delete" 
					ELSE 
						#No password entered
						EXIT FOR 
					END IF 

				ELSE 

					IF glob_arr_rec_rpt_rmsreps_list[i].status_ind = "D" THEN 
						LET glob_arr_rec_rpt_rmsreps_list[i].status_ind = NULL 
						LET glob_arr_rec_rms_code[i].action_text = NULL 
					END IF 
				END IF 

				IF glob_arr_rec_rpt_rmsreps_list[i].report_text IS NULL THEN 
					EXIT FOR 
				END IF 

			END FOR 

			#LET h = arr_curr()
			#LET x = scr_line()
			#LET j = 11 - x
			#LET y = (h - x) + 1
			#LET scrn = 1

			#FOR i = y TO (y + 12)
			#   IF i <= arr_count() THEN
			#      IF scrn <= 11 THEN
			#         DISPLAY glob_arr_rec_rpt_rmsreps_list[i].* TO sr_rms[scrn].*
			#
			#         LET scrn = scrn + 1
			#      END IF
			#   END IF
			#END FOR

			#LET scrn = scr_line()
		END IF 

		--------------- B = BULK ---------------------------------------------------
		#Print Option ="B"
		IF p_output_option = "B" THEN 
			#FOR i = 1 TO 200
			FOR i = 1 TO glob_arr_rec_rpt_rmsreps_list.getlength() 
				IF (glob_arr_rec_rpt_rmsreps_list[i].status_ind IS NULL OR 
				glob_arr_rec_rpt_rmsreps_list[i].status_ind != "P") 
				AND glob_arr_rec_rms_code[i].report_code IS NOT NULL 
				AND glob_arr_rec_rms_code[i].report_code != 0 THEN 

					SELECT unique 1 FROM rmsreps 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND report_code = glob_arr_rec_rms_code[i].report_code 
					AND status_text = "Sent TO Print" 
					AND printonce_flag = "Y" 

					IF status = 0 THEN 
						CONTINUE FOR 
					END IF 

					IF check_auth_with_idx_or_code(i,NULL,"P") THEN 
						LET glob_arr_rec_rpt_rmsreps_list[i].status_ind = "P" 
						LET glob_arr_rec_rms_code[i].action_text = "Print" 
						LET glob_arr_rec_rms_code[i].status_text = "To Print" 
					ELSE 
						#No password entered
						EXIT FOR 
					END IF 

				ELSE 

					IF glob_arr_rec_rpt_rmsreps_list[i].status_ind = "P" THEN 
						LET glob_arr_rec_rpt_rmsreps_list[i].status_ind = NULL 
						LET glob_arr_rec_rms_code[i].action_text = NULL 
					END IF 

				END IF 

				IF glob_arr_rec_rpt_rmsreps_list[i].report_text IS NULL THEN 
					EXIT FOR 
				END IF 

			END FOR 

		END IF 


	ON ACTION "CANCEL" 
		EXIT dialog 

	ON ACTION "WEB-HELP" 
		CALL onlinehelp(getmoduleid(),null) 

	ON ACTION "actToolbarManager" 
		CALL setuptoolbar() 

	ON ACTION "Filter" 
		#COMMAND "Query" "Limit DISPLAY of Reports"
		LET l_rep_criteria = f_query() 
		IF l_rep_criteria IS NOT NULL THEN 
			CALL scan_reps(l_rep_criteria) 
		END IF 
		CALL check_for_memo() 

		LET int_flag = false 
		EXIT dialog 


	BEFORE DIALOG 
		#DISPLAY "BEFORE INPUT"
		CALL publish_toolbar("kandoo","URS","input-arr-rmsreps") 
--		CALL publish_toolbar("kandoo","URS","input-p_output_option-1") -- albo kd-511 
--		CALL publish_toolbar("kandoo","URS","display_arr-glob_arr_rec_rpt_rmsreps_list-1") -- albo kd-511 


	END DIALOG
	#---------------------------------------------------------------


	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 

END FUNCTION 


###################################################################
# FUNCTION urs_line_select_process(p_idx,p_output_option) 
###################################################################
FUNCTION urs_line_select_process(p_idx,p_output_option) 
	DEFINE p_idx SMALLINT --array INDEX 
	DEFINE p_output_option CHAR --print option 
	DEFINE l_file_name STRING --string 
	DEFINE l_runner STRING --char(300), 
	DEFINE l_email CHAR(100) --used in SQL 
	DEFINE l_msgresp LIKE language.yes_flag 

	DISPLAY p_output_option TO output_option 
	CASE p_output_option 

		WHEN "V" #View / direct print / Local print
			IF glob_arr_rec_rms_code[p_idx].report_code IS NOT NULL 
			AND glob_arr_rec_rms_code[p_idx].report_code != 0 THEN 
				CALL f_view(p_idx,"screen") 
			END IF 

		WHEN "P" 
			IF glob_arr_rec_rms_code[p_idx].report_code IS NOT NULL 
			AND glob_arr_rec_rms_code[p_idx].report_code != 0 THEN 
				SELECT unique 1 
				FROM rmsreps 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND report_code = glob_arr_rec_rms_code[p_idx].report_code 
				AND status_text = "Sent TO Print" 
				AND printonce_flag = "Y" 
				IF status = 0 THEN 
					LET l_msgresp = kandoomsg("U",9048,"") 
					#9048 Cannot PRINT reportl; Already Printed
					#NEXT FIELD scroll_flag
				END IF 
				INITIALIZE glob_rec_print.* TO NULL 
				IF f_print(p_idx) THEN 
					IF glob_rec_print.print_x != "Y" THEN 
						UPDATE rmsreps 
						SET status_text = "Sent TO Print" 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND report_code = glob_arr_rec_rms_code[p_idx].report_code 
						LET glob_arr_rec_rpt_rmsreps_list[p_idx].printed_ind = "S" 
						LET glob_arr_rec_rpt_rmsreps_list[p_idx].status_ind = NULL 
						LET glob_arr_rec_rms_code[p_idx].status_text = "Sent TO Print" 
					END IF 
				END IF 
			END IF 

			CALL f_view(p_idx,"print")

		WHEN "B" 
			IF (glob_arr_rec_rpt_rmsreps_list[p_idx].status_ind IS NULL OR 
			glob_arr_rec_rpt_rmsreps_list[p_idx].status_ind != "P") 
			AND glob_arr_rec_rms_code[p_idx].report_code IS NOT NULL 
			AND glob_arr_rec_rms_code[p_idx].report_code != 0 THEN 
				IF check_auth_with_idx_or_code(p_idx,NULL,"P") THEN 
					SELECT unique 1 
					FROM rmsreps 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND report_code = glob_arr_rec_rms_code[p_idx].report_code 
					AND status_text = "Sent TO Print" 
					AND printonce_flag = "Y" 
					IF status = 0 THEN 
						LET l_msgresp = kandoomsg("U",9048,"") 
						#9048 Cannot PRINT reportl; Already Printed
						#NEXT FIELD scroll_flag
					END IF 
					LET glob_arr_rec_rpt_rmsreps_list[p_idx].status_ind = "P" 
					LET glob_arr_rec_rms_code[p_idx].action_text = "Print" 
					LET glob_arr_rec_rms_code[p_idx].status_text = "To Print" 
				END IF 
			ELSE 
				IF glob_arr_rec_rpt_rmsreps_list[p_idx].status_ind = "P" THEN 
					LET glob_arr_rec_rpt_rmsreps_list[p_idx].status_ind = NULL 
					LET glob_arr_rec_rms_code[p_idx].action_text = NULL 
					LET glob_arr_rec_rms_code[p_idx].status_text = NULL 
				END IF 
			END IF 

		WHEN "D" 
			IF (glob_arr_rec_rpt_rmsreps_list[p_idx].status_ind IS NULL OR 
			glob_arr_rec_rpt_rmsreps_list[p_idx].status_ind != "D") 
			AND glob_arr_rec_rms_code[p_idx].report_code IS NOT NULL 
			AND glob_arr_rec_rms_code[p_idx].report_code != 0 THEN 
				IF check_auth_with_idx_or_code(p_idx,NULL,"D") THEN 
					LET glob_arr_rec_rpt_rmsreps_list[p_idx].status_ind = "D" 
					LET glob_arr_rec_rms_code[p_idx].action_text = MODE_CLASSIC_DELETE 
					LET glob_arr_rec_rms_code[p_idx].status_text = "To Delete" 
				END IF 
			ELSE 
				IF glob_arr_rec_rpt_rmsreps_list[p_idx].status_ind = "D" THEN 
					LET glob_arr_rec_rpt_rmsreps_list[p_idx].status_ind = NULL 
					LET glob_arr_rec_rms_code[p_idx].action_text = NULL 
					LET glob_arr_rec_rms_code[p_idx].status_text = NULL 
				END IF 
			END IF 

		WHEN "F" 
			IF (glob_arr_rec_rpt_rmsreps_list[p_idx].status_ind IS NULL OR 
			glob_arr_rec_rpt_rmsreps_list[p_idx].status_ind != "F") 
			AND glob_arr_rec_rms_code[p_idx].report_code IS NOT NULL 
			AND glob_arr_rec_rms_code[p_idx].report_code != 0 THEN 
				LET glob_arr_rec_rpt_rmsreps_list[p_idx].status_ind = "F" 
				LET glob_arr_rec_rms_code[p_idx].action_text = "File" 
				LET glob_arr_rec_rms_code[p_idx].status_text = "To File" 
			ELSE 
				IF glob_arr_rec_rpt_rmsreps_list[p_idx].status_ind = "F" THEN 
					LET glob_arr_rec_rpt_rmsreps_list[p_idx].status_ind = NULL 
					LET glob_arr_rec_rms_code[p_idx].action_text = NULL 
					LET glob_arr_rec_rms_code[p_idx].status_text = NULL 
				END IF 
			END IF 

			CALL f_view(p_idx,"download")


		WHEN "M" 
			IF glob_arr_rec_rms_code[p_idx].report_code IS NOT NULL 
			AND glob_arr_rec_rms_code[p_idx].report_code != 0 THEN 
				SELECT email 
				INTO l_email 
				FROM kandoouser 
				WHERE sign_on_code = glob_rec_kandoouser.sign_on_code 
				LET l_file_name = fgl_getenv("KANDOODIR") 
				LET l_file_name = l_file_name clipped, 
				"/reports/", glob_rec_kandoouser.cmpy_code clipped, ".", 
				glob_arr_rec_rms_code[p_idx].report_code USING "<<<<<<<<" 
				LET l_runner = 'perl /apps/misc/bin/send_attach ', 
				l_email clipped, ' ', 
				l_file_name clipped, ' "', 
				glob_arr_rec_rpt_rmsreps_list[p_idx].report_text clipped, '"' 
				RUN l_runner WITHOUT waiting 
				LET glob_arr_rec_rpt_rmsreps_list[p_idx].printed_ind = "M" 
				LET glob_arr_rec_rpt_rmsreps_list[p_idx].status_ind = NULL 
				LET glob_arr_rec_rms_code[p_idx].status_text = "Sent TO Email" 
			END IF 
	END CASE 
	LET int_flag = false 
	LET quit_flag = false 
	#DISPLAY glob_arr_rec_rpt_rmsreps_list[p_idx].* TO sr_rms[scrn].*
	#NEXT FIELD scroll_flag

	RETURN l_file_name 

END FUNCTION 


###################################################################
# FUNCTION disp_report_properties(p_idx)
###################################################################
FUNCTION disp_report_properties(p_idx) 
	DEFINE p_idx SMALLINT 
	DEFINE l_rec_rmsreps RECORD LIKE rmsreps.* 
	DEFINE l_report_text LIKE rmsreps.report_text 
	DEFINE l_size_text CHAR(10) 
	DEFINE l_report_code CHAR(8) 
	DEFINE l_msgresp LIKE language.yes_flag 
	CALL db_rmsreps_get_rec(UI_ON,glob_arr_rec_rms_code[p_idx].report_code) RETURNING l_rec_rmsreps.* 
--	SELECT * INTO l_rec_rmsreps.* 
--	FROM rmsreps 
--	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
--	AND report_code = glob_arr_rec_rms_code[p_idx].report_code 
	LET l_report_text = l_rec_rmsreps.report_text 
	IF glob_arr_rec_rms_code[p_idx].status_text IS NOT NULL THEN 
		LET l_rec_rmsreps.status_text = glob_arr_rec_rms_code[p_idx].status_text 
	END IF 
	IF l_rec_rmsreps.page_length_num IS NULL #Default length if record is corrupted 
	OR l_rec_rmsreps.page_length_num = 0 THEN 
		LET l_rec_rmsreps.page_length_num = 66 
	END IF 
	IF l_rec_rmsreps.report_width_num IS NULL  #Default width if record is corrupted 
	OR l_rec_rmsreps.report_width_num = 0 THEN 
		LET l_rec_rmsreps.report_width_num = 132 
	END IF 

	LET l_size_text = l_rec_rmsreps.page_length_num USING "<<<<<" 
	LET l_size_text = l_size_text clipped,"/", l_rec_rmsreps.report_width_num USING "<<<<<" 
	LET l_report_code = l_rec_rmsreps.report_code USING "<<<<<<<<"
	 
	DISPLAY l_size_text TO size_text 
	DISPLAY l_report_code TO report_code_detail 
	DISPLAY l_rec_rmsreps.entry_code TO entry_code
	DISPLAY l_report_text TO report_text 
	DISPLAY l_rec_rmsreps.status_text TO status_text
	DISPLAY l_rec_rmsreps.report_pgm_text TO detail_report_pgm_text 
	DISPLAY l_rec_rmsreps.page_num TO page_num 

END FUNCTION 

----------------------------------------------------------------------------------------
{
###################################################################
# FUNCTION direct_print(p_rec_rmsreps,p_report_type) 
###################################################################
FUNCTION direct_print(p_rec_rmsreps,p_report_type) 
	DEFINE p_idx SMALLINT 
	DEFINE p_report_type STRING
	DEFINE p_rec_rmsreps RECORD LIKE rmsreps.* 
	DEFINE l_rec_printcodes RECORD LIKE printcodes.* 
	DEFINE l_normal_text CHAR(20) 
	DEFINE l_compress_text CHAR(20) 
	DEFINE l_file_name STRING 
	DEFINE l_err_message CHAR(55) 
	DEFINE l_pr_view CHAR(100) 
	DEFINE l_hostname CHAR(40) 
	DEFINE l_view_type CHAR(20) 
	DEFINE l_runner CHAR(90) 
	DEFINE ir INTEGER 
	DEFINE j INTEGER 
	DEFINE l_line_counter INTEGER 
	DEFINE l_counter INTEGER 
	DEFINE l_ans CHAR(1) 
	DEFINE l_tempmsg STRING --just FOR temp messages 
	DEFINE l_buffer STRING 
	#DEFINE buffer_temp  CHAR(200)
	DEFINE l_bufferline STRING 
	DEFINE l_input_pipe CHAR(20) 
	DEFINE rf SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_outpipe CHAR(10) 


	IF NOT check_auth_with_idx_or_code(p_idx,p_rec_rmsreps.report_code,"V") THEN 
		LET l_msgresp = kandoomsg("U",5006,"") 
		#5006 Access denied - See System Administrator
		RETURN 
	END IF 
	LET l_file_name = trim(rpt_add_path_to_report_file(p_rec_rmsreps.file_text))
	#LET l_file_name = trim(get_settings_reportPath()), "/",glob_rec_kandoouser.cmpy_code clipped, ".",p_rec_rmsreps.report_code USING "<<<<<<<<" 
	#LET l_file_name = trim(l_file_name) 
	
	LET p_report_type = p_report_type.toLowerCase()

	CALL fgl_report_type(p_report_type,"text") 
	
	IF fgl_channel_open_file("stream", l_file_name, "r") = 0 THEN 
		LET l_tempmsg = "Can NOT OPEN the file ", trim(l_file_name), "\nStatus=", status 
		CALL fgl_winmessage("Error",l_tempMsg, "error") 
	ELSE 
		LET l_outpipe = "screen" 
		START REPORT rep_display_report TO pipe l_outpipe 
		WHILE fgl_channel_read("stream",l_bufferLine) 
			#DISPLAY l_bufferLine
			#LET l_buffer = l_buffer CLIPPED, "\n", l_bufferLine
			OUTPUT TO REPORT rep_display_report(l_bufferline) 
		END WHILE 
		CALL fgl_channel_close("stream") 
		FINISH REPORT rep_display_report 
	END IF 

END FUNCTION 
}
----------------------------------------------------------------------------------------
###################################################################
# FUNCTION f_view(p_idx,p_report_type)
###################################################################
FUNCTION f_view(p_idx,p_report_type) 
	DEFINE p_idx SMALLINT 
	DEFINE p_report_type STRING
	DEFINE l_rec_rmsreps RECORD LIKE rmsreps.* 
	DEFINE l_rec_printcodes RECORD LIKE printcodes.* 
	DEFINE l_normal_text CHAR(20) 
	DEFINE l_compress_text CHAR(20) 
	DEFINE l_file_name STRING 
	DEFINE l_err_message CHAR(55) 
	DEFINE l_pr_view CHAR(100) 
	DEFINE l_hostname CHAR(40) 
	DEFINE l_view_type CHAR(20) 
	DEFINE l_runner CHAR(90) 
	DEFINE ir INTEGER 
	DEFINE j INTEGER 
	DEFINE l_line_counter INTEGER 
	DEFINE l_counter INTEGER 
	DEFINE l_ans CHAR(1) 
	DEFINE l_tempmsg STRING --just FOR temp messages 
	DEFINE l_buffer STRING 
	#DEFINE buffer_temp  CHAR(200)
	DEFINE l_bufferline STRING 
	DEFINE l_input_pipe CHAR(20) 
	DEFINE rf SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_outpipe CHAR(10) 


	IF NOT check_auth_with_idx_or_code(p_idx,NULL,"V") THEN 
		LET l_msgresp = kandoomsg("U",5006,"") 
		#5006 Access denied - See System Administrator
		RETURN 
	END IF 

	#Retrieve the report properties from the DB
	CALL db_rmsreps_get_rec(UI_ON,glob_arr_rec_rms_code[p_idx].report_code ) RETURNING l_rec_rmsreps.* 
--	SELECT * INTO l_rec_rmsreps.* 
--	FROM rmsreps 
--	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
--	AND report_code = glob_arr_rec_rms_code[p_idx].report_code
	LET l_file_name =  rpt_report_file_name_and_path_by_report_code(l_rec_rmsreps.report_code)
	LET p_report_type = p_report_type.toLowerCase()

	#@huho
	#Fully changed - but only a temp hack/fix
	# we need an easy way TO send any server file TO
	# server printer
	# client browser PRINT dialog
	# pdf export
	# file download
	--CALL fgl_report_type("screen","text") original 
	CALL fgl_report_type(p_report_type,"text") 
	
	IF fgl_channel_open_file("stream", l_file_name, "r") = 0 THEN 
		LET l_tempmsg = "Can NOT OPEN the file ", trim(l_file_name), "\nStatus=", status 
		CALL fgl_winmessage("Error",l_tempMsg, "error") 
	ELSE 
		LET l_outpipe = "screen" 
		START REPORT rep_display_report TO pipe l_outpipe 
		WHILE fgl_channel_read("stream",l_bufferLine) 
			#DISPLAY l_bufferLine
			#LET l_buffer = l_buffer CLIPPED, "\n", l_bufferLine
			OUTPUT TO REPORT rep_display_report(l_bufferline) 
		END WHILE 
		CALL fgl_channel_close("stream") 
		FINISH REPORT rep_display_report 
	END IF 

	 {

	--# IF fgl_fglgui() THEN
	--#    LET l_hostname = fgl_getenv("KANDOOUNC")
	--#    LET l_view_type = fgl_getenv("KANDOOVEW")
	--#    IF l_view_type != "TERMINAL"
	--#    OR l_view_type IS NULL THEN
	--#       IF length(l_hostname) > 0 THEN
	--#          IF length(l_view_type) > 0 THEN
	--#             LET l_runner = l_view_type," ",l_hostname clipped,"/reports/",
	--#                          glob_rec_kandoouser.cmpy_code clipped, ".",
	--#                          l_rec_rmsreps.report_code using "<<<<<<<<"
	--#          ELSE
	--#             LET l_runner = "write ",l_hostname clipped,"/reports/",
	--#                          glob_rec_kandoouser.cmpy_code clipped, ".",
	--#                          l_rec_rmsreps.report_code using "<<<<<<<<"
	--#          END IF
	--#          LET l_line_counter = winexec(l_runner)
	--#       END IF
	--#       RETURN
	--#    END IF
	--# END IF

	   WHILE TRUE
	      LET term_type = fgl_getenv("TERM")

	      SELECT * INTO l_rec_printcodes.* FROM printcodes
	         WHERE print_code = term_type

	      CASE
	         WHEN STATUS = NOTFOUND
	            LET l_err_message = " Terminal Type ",term_type clipped,
	                              " has NOT been Configured"
	         WHEN l_rec_printcodes.device_ind != "2"
	            LET l_err_message = " Terminal Type ",term_type clipped,
	                              " IS NOT configured as a terminal"
	         OTHERWISE
	            EXIT WHILE
	      END CASE

	      OPEN WINDOW w1 AT 10,12 with 3 rows,58 columns

	      DISPLAY l_err_message clipped AT 3,1

	      menu "Terminal Configuration Not Set Up"
	      	BEFORE MENU
	      	 	CALL publish_toolbar("kandoo","URS","menu-terminal_config")

					ON ACTION "WEB-HELP"
				CALL onlineHelp(getModuleId(),NULL)
				ON ACTION "actToolbarManager"
					 	CALL setupToolbar()


	         COMMAND "ADD" " Add Terminal Configuration"
	            CALL run_prog("URP","","","","")
	            EXIT MENU

	         COMMAND "Continue" " Use Default Configuration"
	            LET l_rec_printcodes.print_text = "pg -f -23 -p \"Page:%d\" $F"
	            LET l_rec_printcodes.device_ind = "2"
	            EXIT MENU

	         COMMAND KEY(interrupt,"E") "Exit" " RETURN TO REPORT Scan"
	            LET quit_flag = TRUE
	            EXIT MENU

	         COMMAND KEY (control-w)
	            CALL kandoohelp("")

	      END MENU

	      CLOSE WINDOW w1

	      IF int_flag OR quit_flag THEN
	         LET int_flag = FALSE
	         LET quit_flag = FALSE
	         RETURN
	      END IF

	      IF l_rec_printcodes.device_ind = "2" THEN
	         EXIT WHILE
	      END IF

	   END WHILE


	   IF l_rec_rmsreps.report_width_num > l_rec_printcodes.width_num THEN
	      LET glob_rec_print.comp = "Y"
	   ELSE
	      LET glob_rec_print.comp = "N"
	   END IF

	   LET l_pr_view = "F=",l_file_name clipped,
	                 " ; ",l_rec_printcodes.print_text clipped
	   LET l_compress_text =
	        ascii l_rec_printcodes.compress_1,
	        ascii l_rec_printcodes.compress_2,
	        ascii l_rec_printcodes.compress_3,
	        ascii l_rec_printcodes.compress_4,
	        ascii l_rec_printcodes.compress_5,
	        ascii l_rec_printcodes.compress_6,
	        ascii l_rec_printcodes.compress_7,
	        ascii l_rec_printcodes.compress_8,
	        ascii l_rec_printcodes.compress_9,
	        ascii l_rec_printcodes.compress_10,
	        ascii l_rec_printcodes.compress_11,
	        ascii l_rec_printcodes.compress_12,
	        ascii l_rec_printcodes.compress_13,
	        ascii l_rec_printcodes.compress_14,
	        ascii l_rec_printcodes.compress_15,
	        ascii l_rec_printcodes.compress_16,
	        ascii l_rec_printcodes.compress_17,
	        ascii l_rec_printcodes.compress_18,
	        ascii l_rec_printcodes.compress_19,
	        ascii l_rec_printcodes.compress_20

	   IF glob_rec_print.comp = "Y" THEN
	      DISPLAY l_compress_text
	      sleep 1
	      run l_pr_view

	# Assume that everyone has terminals SET AT 80char.
	# Always SET back TO normal AFTER viewing.

	   LET l_normal_text =
	        ascii l_rec_printcodes.normal_1,
	        ascii l_rec_printcodes.normal_2,
	        ascii l_rec_printcodes.normal_3,
	        ascii l_rec_printcodes.normal_4,
	        ascii l_rec_printcodes.normal_5,
	        ascii l_rec_printcodes.normal_6,
	        ascii l_rec_printcodes.normal_7,
	        ascii l_rec_printcodes.normal_8,
	        ascii l_rec_printcodes.normal_9,
	        ascii l_rec_printcodes.normal_10
	       DISPLAY l_normal_text
	       sleep 1
	   END IF
	   LET l_normal_text =
	        ascii l_rec_printcodes.normal_1,
	        ascii l_rec_printcodes.normal_2,
	        ascii l_rec_printcodes.normal_3,
	        ascii l_rec_printcodes.normal_4,
	        ascii l_rec_printcodes.normal_5,
	        ascii l_rec_printcodes.normal_6,
	        ascii l_rec_printcodes.normal_7,
	        ascii l_rec_printcodes.normal_8,
	        ascii l_rec_printcodes.normal_9,
	        ascii l_rec_printcodes.normal_10
	   IF glob_rec_print.comp = "N" THEN
	      DISPLAY l_normal_text
	      sleep 1
	      run l_pr_view
	   END IF

	   }
END FUNCTION 


###################################################################
# FUNCTION f_print(p_idx)
###################################################################
FUNCTION f_print(p_idx) 
	DEFINE p_idx SMALLINT 
	DEFINE l_rec_rmsreps RECORD LIKE rmsreps.* 
	DEFINE l_runner CHAR(200) 
	DEFINE l_print_cmd STRING 
	DEFINE l_del_cmd CHAR(100) 
	DEFINE l_err_message CHAR(50) 
	DEFINE l_ans CHAR(1) 
	DEFINE l_file_name STRING 
	DEFINE l_file_tmp1 STRING 
	DEFINE l_file_tmp2 STRING 
	DEFINE l_file_status SMALLINT 
	DEFINE l_print_copies INTEGER 
	DEFINE l_ret_code INTEGER 
	DEFINE l_start_line INTEGER 
	DEFINE l_end_line INTEGER 
	DEFINE l_norm_on CHAR(100) 
	DEFINE l_comp_on CHAR(100) 
	DEFINE l_msgresp LIKE language.yes_flag 

	IF NOT check_auth_with_idx_or_code(p_idx,NULL,"P") THEN 
		LET l_msgresp = kandoomsg("U",5006,"") 
		#5006 Access denied - See System Administrator
		RETURN false 
	END IF 
	INITIALIZE l_rec_rmsreps.* TO NULL
	 
	SELECT * INTO l_rec_rmsreps.* 
	FROM rmsreps 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND report_code = glob_arr_rec_rms_code[p_idx].report_code
	LET l_file_name = rpt_report_file_name_and_path_by_report_code(l_rec_rmsreps.report_code) 
	IF get_os_arch() = 1 THEN --nt=1 
		LET l_file_name = replace_string(l_file_name,"/","\\\\") 
	END IF
	 
	LET l_file_tmp1 = l_file_name clipped,".tmp1" 
	LET l_file_tmp2 = l_file_name clipped,".tmp2"
	 
	IF l_rec_rmsreps.dest_print_text IS NULL THEN 
		LET l_rec_rmsreps.copy_num = 1 
		LET l_rec_rmsreps.align_ind = "N" 
		LET l_rec_rmsreps.start_page = 1 
		LET l_rec_rmsreps.dest_print_text = glob_rec_kandoouser.print_text 
		IF l_rec_rmsreps.page_length_num IS NULL 
		OR l_rec_rmsreps.page_length_num = 0 THEN 
			LET l_rec_rmsreps.page_length_num = l_rec_rmsreps.page_length_num 
		END IF 
		IF l_rec_rmsreps.page_num IS NULL 
		OR l_rec_rmsreps.page_num = 0 THEN 
			LET l_rec_rmsreps.print_page = 9999 
		ELSE 
			LET l_rec_rmsreps.print_page = l_rec_rmsreps.page_num 
		END IF 
	END IF
	 
	SELECT * 
	INTO glob_rec_printcodes.* 
	FROM printcodes 
	WHERE print_code = l_rec_rmsreps.dest_print_text
	 
	IF l_rec_rmsreps.report_width_num > glob_rec_printcodes.width_num THEN 
		LET l_rec_rmsreps.comp_ind = "Y" 
	ELSE 
		LET l_rec_rmsreps.comp_ind = "N" 
	END IF 
	IF glob_rec_print.print_code IS NULL THEN 
		OPEN WINDOW u115 with FORM "U115" 
		CALL windecoration_u("U115") 
		LET l_msgresp = kandoomsg("U",1045,"") 
		#1045 Enter Print Options - ESC TO Continue
		IF l_rec_rmsreps.printonce_flag IS NULL THEN 
			LET l_rec_rmsreps.printonce_flag = "N" 
		END IF 

		DISPLAY l_rec_rmsreps.printonce_flag TO printonce_flag

		INPUT BY NAME l_rec_rmsreps.dest_print_text, 
		l_rec_rmsreps.copy_num, 
		l_rec_rmsreps.comp_ind, 
		l_rec_rmsreps.page_length_num, 
		l_rec_rmsreps.start_page, 
		l_rec_rmsreps.print_page, 
		l_rec_rmsreps.align_ind 
		WITHOUT DEFAULTS 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","URS","input-rmsreps") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			BEFORE FIELD dest_print_text 
				LET l_rec_rmsreps.print_page = 9999 
				DISPLAY l_rec_rmsreps.print_page TO print_page

			AFTER FIELD dest_print_text 
				SELECT * 
				INTO glob_rec_printcodes.* 
				FROM printcodes 
				WHERE print_code = l_rec_rmsreps.dest_print_text 
				IF status = notfound THEN 
					LET l_msgresp = kandoomsg("W",9301,"") 
					NEXT FIELD dest_print_text 
				END IF 
				IF glob_rec_printcodes.device_ind = "2" THEN 
					LET l_msgresp = kandoomsg("U",7018,glob_rec_printcodes.print_code) 
					NEXT FIELD dest_print_text 
				ELSE 
					IF l_rec_rmsreps.report_width_num > glob_rec_printcodes.width_num THEN 
						LET l_rec_rmsreps.comp_ind = "Y" 
					ELSE 
						LET l_rec_rmsreps.comp_ind = "N" 
					END IF 
					IF l_rec_rmsreps.page_length_num IS NULL 
					OR l_rec_rmsreps.page_length_num = 0 THEN 
						LET l_rec_rmsreps.page_length_num = glob_rec_printcodes.length_num 
					END IF 
					DISPLAY l_rec_rmsreps.comp_ind TO comp_ind
					DISPLAY l_rec_rmsreps.page_length_num TO page_length_num 
				END IF 

			BEFORE FIELD copy_num 
				IF l_rec_rmsreps.printonce_flag = "Y" THEN 
					IF fgl_lastkey() = fgl_keyval("up") 
					OR fgl_lastkey() = fgl_keyval("left") THEN 
						NEXT FIELD previous 
					ELSE 
						NEXT FIELD NEXT 
					END IF 
				END IF 

			AFTER FIELD page_length_num 
				IF l_rec_rmsreps.start_page != 1 THEN 
					IF l_rec_rmsreps.page_length_num = 0 
					OR l_rec_rmsreps.page_length_num IS NULL THEN 
						LET l_msgresp = kandoomsg("U",9008,"") 
						#9008 Number of lines per page must be entered
						NEXT FIELD page_length_num 
					END IF 
				END IF 

			AFTER FIELD start_page 
				IF l_rec_rmsreps.start_page IS NULL 
				OR l_rec_rmsreps.start_page = 0 THEN 
					LET l_msgresp = kandoomsg("I",9141,"") 
					#9141 Starting Number must be entered "
					NEXT FIELD start_page 
				END IF 

			AFTER FIELD print_page 
				IF l_rec_rmsreps.print_page IS NULL THEN 
					LET l_rec_rmsreps.print_page = 9999 
					DISPLAY l_rec_rmsreps.print_page TO print_page
				END IF 

			ON KEY (control-b) 
				IF infield(dest_print_text) THEN 
					LET l_rec_rmsreps.dest_print_text = show_print(glob_rec_kandoouser.cmpy_code) 
					NEXT FIELD dest_print_text 
				END IF 

		END INPUT 
		############################

		CLOSE WINDOW u115 

		LET glob_rec_print.print_code = l_rec_rmsreps.dest_print_text 
		LET glob_rec_print.copies = l_rec_rmsreps.copy_num 
		LET glob_rec_print.comp = l_rec_rmsreps.comp_ind 
		LET glob_rec_print.page_length_num = l_rec_rmsreps.page_length_num 
		LET glob_rec_print.start_page = l_rec_rmsreps.start_page 
		LET glob_rec_print.print_pages = l_rec_rmsreps.print_page 
		LET glob_rec_print.print_x = l_rec_rmsreps.align_ind 

	END IF 

	IF int_flag OR quit_flag THEN 
		LET quit_flag = false 
		LET int_flag = false 
		LET glob_rec_print.print_code = NULL 
		RETURN false 
	END IF 

	IF glob_rec_print.print_x = "Y" THEN 
		LET glob_rec_print.print_pages = 2 
	END IF 

	IF glob_rec_print.start_page = 1 THEN 
		LET l_start_line = 1 
		LET l_end_line = glob_rec_print.print_pages * glob_rec_print.page_length_num 
	ELSE 
		LET l_start_line = (glob_rec_print.start_page -1) * glob_rec_print.page_length_num + 1 
		LET l_end_line = l_start_line + (glob_rec_print.print_pages * glob_rec_print.page_length_num) -1 
	END IF 

	IF l_end_line > 999999 THEN 
		LET l_end_line = 999999 
	END IF 

	IF l_start_line > 999999 THEN 
		LET l_start_line = 999999 
	END IF 

	CALL fgl_winmessage("need help here","This part needs TO be done by some kind of sysAdmin devloper - output file TO printer\but depending on choosen printer device","info") 

	IF get_os_arch() = 1 THEN --nt=1 --alch will NOT WORK ON windows WITHOUT cygwin 
		LET l_runner = "sed -n \"",l_start_line using "<<<<<<" clipped,",", 
		l_end_line USING "<<<<<<" clipped," p\"", 
		" < ",l_file_name clipped, "| sed \"s/$/\/\" > ", 
		l_file_tmp1 clipped," 2>>",trim(get_settings_logFile())  
		RUN l_runner 
	ELSE 
		LET l_runner = "sed -n \"",l_start_line using "<<<<<<" clipped,",", 
		l_end_line USING "<<<<<<" clipped," p\"", 
		" < ",l_file_name clipped, " > ",l_file_tmp1 clipped," 2>>", trim(get_settings_logFile())  
		RUN l_runner 
	END IF 

	CALL afile_status(l_file_tmp1) RETURNING l_file_status 

	CASE l_file_status 
		WHEN 1 
			LET l_err_message = 
			" Report File Does Not Exist - Cannot Print" 
		WHEN 2 
			LET l_err_message = 
			"Report File has Invalid Attributes - Cannot Print" 
		WHEN 4 
			LET l_err_message = 
			" Report File Contains No Data - Cannot Print" 
		OTHERWISE 
			LET l_err_message = NULL 
	END CASE 

	IF l_err_message IS NOT NULL THEN 
		LET l_msgresp = kandoomsg("U",1,l_err_message) 

		IF l_file_status = 1 THEN 
			RETURN true 
		ELSE 
			RETURN false 
		END IF 

	END IF 

	IF glob_rec_print.print_x = "Y" THEN 
		LET l_runner = "cat ",l_file_tmp1," | tr \"[!-~]\" \"[X*]\" > ", 
		l_file_tmp2," ; mv ",l_file_tmp2," ",l_file_tmp1," " 
		RUN l_runner 
		## The ASCII sequence of printable characters, starts AT "!"
		## AND ends AT "~". This l_runner relaces them with "X"
	END IF 

	IF l_rec_rmsreps.printonce_flag = "Y" THEN 
		LET l_print_copies = 1 
	ELSE 
		LET l_print_copies = glob_rec_print.copies 
	END IF 

	IF get_os_arch() = 1 THEN --nt=1 
		LET l_print_cmd = glob_rec_printcodes.print_text clipped," ", 
		l_file_tmp1 
		DISPLAY l_print_cmd 
		SLEEP 5 
		LET l_del_cmd = "rm ",l_file_tmp1," " 

	ELSE 

		IF glob_rec_print.comp = "N" THEN 
			LET l_print_cmd = "F=",l_file_tmp1, 
			";C=",l_print_copies USING "<<<<<", 
			";L=",l_rec_rmsreps.page_length_num USING "<<<<<", 
			";W=",l_rec_rmsreps.report_width_num USING "<<<<<", 
			";",glob_rec_printcodes.print_text clipped," 2>>", trim(get_settings_logFile()) , 
			"; STATUS=$? ", 
			" ; EXIT $STATUS " 
			LET l_del_cmd = "rm ",l_file_tmp1," " 

		ELSE 
			LET l_comp_on = ascii ASCII_QUOTATION_MARK, 
			ascii glob_rec_printcodes.compress_1, 
			ascii glob_rec_printcodes.compress_2, 
			ascii glob_rec_printcodes.compress_3, 
			ascii glob_rec_printcodes.compress_4, 
			ascii glob_rec_printcodes.compress_5, 
			ascii glob_rec_printcodes.compress_6, 
			ascii glob_rec_printcodes.compress_7, 
			ascii glob_rec_printcodes.compress_8, 
			ascii glob_rec_printcodes.compress_9, 
			ascii glob_rec_printcodes.compress_10, 
			ascii glob_rec_printcodes.compress_11, 
			ascii glob_rec_printcodes.compress_12, 
			ascii glob_rec_printcodes.compress_13, 
			ascii glob_rec_printcodes.compress_14, 
			ascii glob_rec_printcodes.compress_15, 
			ascii glob_rec_printcodes.compress_16, 
			ascii glob_rec_printcodes.compress_17, 
			ascii glob_rec_printcodes.compress_18, 
			ascii glob_rec_printcodes.compress_19, 
			ascii glob_rec_printcodes.compress_20, ascii ASCII_QUOTATION_MARK 
			LET l_norm_on = ascii ASCII_QUOTATION_MARK, 
			ascii glob_rec_printcodes.normal_1, 
			ascii glob_rec_printcodes.normal_2, 
			ascii glob_rec_printcodes.normal_3, 
			ascii glob_rec_printcodes.normal_4, 
			ascii glob_rec_printcodes.normal_5, 
			ascii glob_rec_printcodes.normal_6, 
			ascii glob_rec_printcodes.normal_7, 
			ascii glob_rec_printcodes.normal_8, 
			ascii glob_rec_printcodes.normal_9, 
			ascii glob_rec_printcodes.normal_10, ascii ASCII_QUOTATION_MARK 
			LET l_runner = "echo ",l_comp_on clipped," > ",l_file_tmp2 clipped, 
			";cat ", l_file_tmp1 clipped, " >> ",l_file_tmp2 clipped, 
			";echo ", l_norm_on clipped, " >> ",l_file_tmp2 clipped, 
			" 2>>",trim(get_settings_logFile())  
			RUN l_runner 
			LET l_print_cmd = "F=",l_file_tmp2, 
			" ;C=",l_print_copies USING "<<<<<", 
			" ;L=",l_rec_rmsreps.page_length_num USING "<<<<<", 
			" ;W=",l_rec_rmsreps.report_width_num USING "<<<<<", 
			" ;",glob_rec_printcodes.print_text clipped," 2>>", trim(get_settings_logFile()) , 
			" ; STATUS=$? " 
			LET l_del_cmd = "rm ",l_file_tmp2, " " 
		END IF 

	END IF 

	RUN l_print_cmd RETURNING l_ret_code 

	IF l_ret_code THEN 
		LET l_msgresp = kandoomsg("U",9042,"") 
		RUN l_del_cmd 
		IF glob_rec_print.comp = "Y" THEN 
			LET l_del_cmd = "rm ",l_file_tmp1, " " 
			RUN l_del_cmd 
		END IF 
		RETURN false 
	ELSE 
		RUN l_del_cmd 
		IF glob_rec_print.comp = "Y" THEN 
			LET l_del_cmd = "rm ",l_file_tmp1, " " 
			RUN l_del_cmd 
		END IF 
		RETURN true 
	END IF 
END FUNCTION 


###################################################################
# FUNCTION f_sort()
###################################################################
FUNCTION f_sort() 
	DEFINE l_sort_text STRING 
	DEFINE l_buttonret CHAR --button RETURN value 
	DEFINE l_tmpmsg STRING --message STRING 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET l_buttonret = fgl_winbutton("Sort Reports", "Sort reports by Title, User OR Date", "Date", "Title|User|Date|None", "exclamation", 1) 

	CASE l_buttonret 
		WHEN "T" --description / title 
			LET l_sort_text = "ORDER BY report_text,", 
			"report_date desc,", 
			"report_time desc" 

		WHEN "U" --user 
			LET l_sort_text = "ORDER BY entry_code,", 
			"report_date desc,", 
			"report_time desc" 

		WHEN "D" --date 
			LET l_sort_text = "ORDER BY report_date desc,", 
			"report_time desc,", 
			"report_text" 


		OTHERWISE 
			LET int_flag = true --exit, don't re-sort 
	END CASE 


	{
	   menu "Sort Reports"
	      	BEFORE MENU
	      	 	CALL publish_toolbar("kandoo","URS","menu-sort_reports")

					ON ACTION "WEB-HELP"
				CALL onlineHelp(getModuleId(),NULL)
				ON ACTION "actToolbarManager"
					 	CALL setupToolbar()


	      COMMAND "Title" "Sort reports by description"
	          LET l_sort_text = "ORDER BY report_text,",
	                                      "report_date desc,",
	                                      "report_time desc"
	          EXIT MENU
	      COMMAND "User" "Sort reports by user"
	          LET l_sort_text = "ORDER BY entry_code,",
	                                      "report_date desc,",
	                                      "report_time desc"
	          EXIT MENU
	      COMMAND "Date" "Sort reports by creation date/time"
	          LET l_sort_text = "ORDER BY report_date desc,",
	                                      "report_time desc,",
	                                      "report_text"
	          EXIT MENU

	      COMMAND KEY (interrupt,"E") "Exit" " RETURN TO Menus "
	         LET int_flag = TRUE
	         EXIT MENU

	      COMMAND KEY (control-w)
	         CALL kandoohelp("")

	   END MENU
	}
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		LET l_sort_text = NULL 
	ELSE 
		LET l_sort_text ="cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ",l_sort_text clipped 
	END IF 

	RETURN l_sort_text 

END FUNCTION 


###################################################################
# FUNCTION f_query()
#
#
###################################################################
FUNCTION f_query() 
	DEFINE l_where_text CHAR(200) 
	DEFINE l_msgresp LIKE language.yes_flag 

	OPEN WINDOW u114 with FORM "U114" 
	CALL windecoration_u("U114") 

	LET l_msgresp = kandoomsg("U",1001,"") 

	CONSTRUCT l_where_text ON report_text, 
	entry_code, 
	report_date, 
	status_text 
	FROM report_text, 
	entry_code, 
	report_date, 
	status_text 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","URS","construct-REPORT") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	CLOSE WINDOW u114 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		LET l_where_text = NULL 
	ELSE 
		LET l_where_text = l_where_text clipped, " ORDER BY report_date desc, report_time desc " 
	END IF 

	RETURN l_where_text 
END FUNCTION 


###################################################################
# FUNCTION tagged()
#
# checks if an output/report file is tagged for action
###################################################################
FUNCTION tagged() 
	DEFINE l_file_cnt SMALLINT 
	DEFINE l_del_cnt SMALLINT 
	DEFINE l_print_cnt SMALLINT 
	DEFINE l_idx SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET l_del_cnt = 0 
	LET l_print_cnt = 0 
	LET l_file_cnt = 0 

	FOR l_idx = 1 TO glob_arr_rec_rms_code.getlength() 
		IF glob_arr_rec_rms_code[l_idx].action_text = MODE_CLASSIC_DELETE THEN 
			LET l_del_cnt = l_del_cnt +1 
		END IF 
		IF glob_arr_rec_rms_code[l_idx].action_text = "Print" THEN 
			LET l_print_cnt = l_print_cnt +1 
		END IF 
		IF glob_arr_rec_rms_code[l_idx].action_text = "File" THEN 
			LET l_file_cnt = l_file_cnt +1 
		END IF 
	END FOR 

	IF l_print_cnt OR l_del_cnt OR l_file_cnt THEN 

--		OPEN WINDOW w1 with FORM "U999" 
--		CALL windecoration_u("U999") 

		DISPLAY l_del_cnt TO del_cnt #" Report/s TO be Deleted " 
		DISPLAY l_print_cnt TO print_cnt #" Report/s TO be Printed "  
		DISPLAY l_file_cnt TO file_cnt #" Report/s TO be Copied " 

		MENU " Confirmation of Report Deletion & Printing" 
			BEFORE MENU 
				CALL publish_toolbar("kandoo","URS","menu-confirmation") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 


			COMMAND "Yes" "" 
				EXIT MENU 

			COMMAND KEY(interrupt,"N")"No" "" 
				LET quit_flag = true 
				EXIT MENU 

		END MENU 

--		CLOSE WINDOW w1 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			RETURN false 
		ELSE 
			RETURN true 
		END IF 

	ELSE 
		RETURN false 
	END IF 
END FUNCTION 


###################################################################
# FUNCTION upd_tags()
###################################################################
FUNCTION upd_tags() 
	DEFINE i SMALLINT 
	DEFINE l_idx SMALLINT 
	DEFINE l_delete CHAR(100) 
	DEFINE l_file_name STRING 
	DEFINE l_err_message CHAR(50) 
	DEFINE l_ans CHAR(1) 
	DEFINE l_ret_code INTEGER 
	DEFINE l_file_status INTEGER 
	DEFINE l_msgresp LIKE language.yes_flag 

	INITIALIZE glob_rec_print.* TO NULL 
	INITIALIZE glob_arr_rec_file TO NULL 
	LET glob_file_idx = 0 

	CLEAR screen 

	FOR l_idx = 1 TO glob_arr_rec_rms_code.getlength() 
		IF glob_arr_rec_rms_code[l_idx].action_text = MODE_CLASSIC_DELETE THEN 
			# DISPLAY "Deleting : ",glob_arr_rec_rpt_rmsreps_list[l_idx].report_text #  AT 4,3
			MESSAGE "Deleting : ",glob_arr_rec_rpt_rmsreps_list[l_idx].report_text 
			LET l_file_name = rpt_report_file_name_and_path_by_report_code(glob_arr_rec_rms_code[l_idx].report_code)
			IF afile_status(l_file_name) = 1 THEN 
				DELETE FROM rmsreps 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND report_code = glob_arr_rec_rms_code[l_idx].report_code 
			ELSE 
				LET l_delete = " rm -f ",l_file_name clipped," 2>>", trim(get_settings_logFile())  
				RUN l_delete RETURNING l_ret_code 
				IF l_ret_code THEN 
					LET l_msgresp = kandoomsg("U",9043,l_file_name) 
				ELSE 
					DELETE FROM rmsreps 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND report_code = glob_arr_rec_rms_code[l_idx].report_code 
				END IF 
			END IF 
		END IF 

		IF glob_arr_rec_rms_code[l_idx].action_text = "Print" THEN 
			SELECT unique 1 FROM rmsreps 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND report_code = glob_arr_rec_rms_code[l_idx].report_code 
			AND status_text = "Sent TO Print" 
			AND printonce_flag = "Y"
			 
			IF status = notfound THEN 
				MESSAGE "Printing : ",glob_arr_rec_rpt_rmsreps_list[l_idx].report_text 
				--SLEEP 1 
				
				IF f_print(l_idx) THEN 
					IF glob_rec_print.print_x != "Y" THEN 
						UPDATE rmsreps 
						SET status_text = "Sent TO Print" 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND report_code = glob_arr_rec_rms_code[l_idx].report_code 
					END IF 
				ELSE 
					LET glob_arr_rec_rpt_rmsreps_list[l_idx].status_ind = NULL 
					LET glob_arr_rec_rms_code[l_idx].action_text = NULL 
					LET glob_arr_rec_rms_code[l_idx].status_text = "To be Printed" 
				END IF 
			END IF 
		END IF 



		IF glob_arr_rec_rms_code[l_idx].action_text = "File" THEN 
			LET glob_file_idx = glob_file_idx + 1 
			LET glob_arr_rec_file[glob_file_idx].filename = 	rpt_report_base_file_name(glob_arr_rec_rms_code[l_idx].report_code)  
			LET glob_arr_rec_file[glob_file_idx].report_code = glob_arr_rec_rms_code[l_idx].report_code 
			LET glob_arr_rec_file[glob_file_idx].report_text = glob_arr_rec_rpt_rmsreps_list[l_idx].report_text 
			LET l_file_name = rpt_add_path_to_report_file(glob_arr_rec_file[glob_file_idx].filename) 
			LET l_file_status = afile_status(l_file_name) 

			CASE l_file_status 
				WHEN 1 
					LET l_err_message = " Report File Does Not Exist - Cannot Copy" 
				WHEN 2 
					LET l_err_message = " Report File has Invalid Attributes - Cannot Copy" 
				WHEN 4 
					LET l_err_message = " Report File Contains No Data - Cannot Copy" 
				OTHERWISE 
					LET l_err_message = NULL 
			END CASE 

			IF l_err_message IS NOT NULL THEN 
--				OPEN WINDOW w1 with FORM "U999" 
--				CALL windecoration_u("U999") 
				DISPLAY l_err_message TO err_message 
				ERROR l_err_message 
				CALL msgContinue("Error",l_err_message) 
--				CLOSE WINDOW w1 
				RETURN false 
			END IF 
		END IF 

	END FOR 

	IF glob_file_idx > 0 THEN 
		CALL file_option() 
	END IF 
	CLEAR screen 

--	FOR i = 1 TO 11 
--		INITIALIZE glob_arr_rec_rpt_rmsreps_list[i].* TO NULL 
--		DISPLAY glob_arr_rec_rpt_rmsreps_list[i].* TO sr_rms[i].* 
--	END FOR 

	RETURN true 
END FUNCTION 

{
Makes no sense anymore since we already use a radiobutton list
###################################################################
# FUNCTION d_msg(p_output_option)
###################################################################
FUNCTION d_msg(p_output_option) 
	DEFINE p_output_option CHAR(1) 
	DEFINE l_message CHAR(7) 
	DEFINE l_message1 CHAR(7) 
	DEFINE l_message2 CHAR(7) 
	DEFINE l_msgresp LIKE language.yes_flag 

	CASE p_output_option 
		WHEN "V" 
			LET l_msgresp = kandoomsg("U",1042,"") 
		WHEN "P" 
			LET l_msgresp = kandoomsg("U",1043,"") 
		WHEN "B" 
			LET l_msgresp = kandoomsg("U",1044,"") 
		WHEN "D" 
			LET l_msgresp = kandoomsg("U",1041,"") 
		WHEN "F" 
			LET l_msgresp = kandoomsg("U",9946,"") 
		WHEN "M" 
			LET l_msgresp = kandoomsg("U",9945,"") 
	END CASE 
END FUNCTION 
}
{
###################################################################
# FUNCTION check_auth_with_idx_or_code(p_idx,p_action)
###################################################################
FUNCTION check_auth_with_idx_or_code(p_idx,p_report_code,p_action) 
	DEFINE p_idx SMALLINT 
	DEFINE p_report_code LIKE rmsreps.report_code
	DEFINE p_action CHAR(1) 
	DEFINE l_name_text CHAR(30) 
	#DEFINE glob_rec_kandoouser RECORD LIKE kandoouser.*
	DEFINE l_rec_rmsreps RECORD LIKE rmsreps.* 
	DEFINE l_temp_password LIKE kandoouser.password_text 
	DEFINE l_temp_sec_ind LIKE kandoouser.security_ind 
	DEFINE l_return SMALLINT 
	DEFINE l_cnt SMALLINT 

	DEFINE l_char CHAR(1) 
	DEFINE l_loop INTEGER 
	DEFINE l_message CHAR(32) 
	DEFINE l_entered CHAR(20) 
	DEFINE l_ret_value INTEGER 
	DEFINE l_msgresp LIKE language.yes_flag 

	IF p_report_code IS NOT NULL THEN

		SELECT * INTO l_rec_rmsreps.* FROM rmsreps 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND report_code = p_report_code
		
		IF status = NOTFOUND THEN
			RETURN FALSE
		END IF 
	
	ELSE

		SELECT * INTO l_rec_rmsreps.* FROM rmsreps 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND report_code = glob_arr_rec_rms_code[p_idx].report_code 
	
	END IF

	IF l_rec_rmsreps.entry_code = glob_rec_kandoouser.sign_on_code THEN 
		RETURN true 
	END IF 
	
	SELECT security_ind INTO l_temp_sec_ind FROM kandoouser 

	WHERE sign_on_code = glob_rec_kandoouser.sign_on_code 

	IF status = notfound THEN 
		RETURN true 
	END IF 

	SELECT * INTO glob_rec_kandoouser.* FROM kandoouser 
	WHERE sign_on_code = l_rec_rmsreps.entry_code 

	IF status = notfound THEN 
		RETURN true 
	END IF 

	#LET glob_rec_kandoouser.password_text = glob_rec_kandoouser.password_text clipped #??????

	IF l_temp_sec_ind < glob_rec_kandoouser.security_ind 
	OR l_temp_sec_ind < l_rec_rmsreps.security_ind THEN 
		IF glob_rec_kandoouser.password_text IS NULL 
		OR glob_rec_kandoouser.password_text = " " THEN 
			RETURN false 
		END IF 

	ELSE 

		IF glob_rec_kandoouser.password_text IS NULL 
		OR glob_rec_kandoouser.password_text = " " THEN 
			RETURN true 
		END IF 

	END IF 

	CASE p_action 
		WHEN "D" 
			LET l_name_text = "Deleting Report File" 
		WHEN "V" 
			LET l_name_text = "Viewing Report File " 
		WHEN "P" 
			LET l_name_text = "Printing Report File" 
		WHEN "F" 
			LET l_name_text = "Coping Report File" 
	END CASE 

	OPEN WINDOW u129 with FORM "U129" 
	CALL windecoration_u("U129") 
	-- albo --
	INPUT l_entered FROM password_text 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","URS","input-l_entered-1") -- albo kd-511 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
				LET l_ret_value = false 
				EXIT INPUT 
			END IF 
			IF l_entered = glob_rec_kandoouser.password_text THEN 
				LET l_ret_value = true 
				EXIT INPUT 
			ELSE 
				LET l_msgresp = kandoomsg("U",9002,"") 
				CONTINUE INPUT 
			END IF 
	END INPUT 
	----------
	{   -- albo
		CALL fgl_winmessage("this needs fixing URS.4gl","this needs fixing URS.4gl","info")

	   DISPLAY BY NAME l_name_text
	--huho OPTIONS INPUT ATTRIBUTE(invisible)

	   OPTIONS prompt line 7

	   FOR l_cnt = 1 TO 3
	      LET l_MESSAGE = "      Enter password......" clipped
	      LET l_entered = ""
	      FOR l_loop = 1 TO 8
	         IF l_loop > 20 THEN
	             EXIT FOR
	         END IF
	         prompt l_MESSAGE clipped FOR CHAR l_char  -- no need TO replace yet -- albo
	         IF l_char IS NULL THEN
	             EXIT FOR
	         END IF
	         LET l_entered[l_loop] = l_char
	         LET l_MESSAGE = l_MESSAGE clipped, "x"
	      END FOR

	      IF int_flag OR quit_flag THEN
	         LET int_flag = FALSE
	         LET quit_flag = FALSE
	         EXIT FOR
	      END IF

	      IF l_entered = glob_rec_kandoouser.password_text THEN
	         CLOSE WINDOW U129

	         RETURN TRUE
	      ELSE
	         LET l_msgresp = kandoomsg("U",9002,"")
	      END IF

	   END FOR
	}
{
	CLOSE WINDOW u129 

	RETURN l_ret_value 

END FUNCTION 
}
{
###################################################################
# FUNCTION file_status(p_file_name)
#
#  FUNCTION returns one ofthe following VALUES
#        1. File NOT found
#        2. No read permission
#        3. No write permission
#        4. File IS Empty
#        5. OTHERWISE
###################################################################
FUNCTION file_status(p_file_name) 
	DEFINE p_file_name CHAR(60) 
	DEFINE l_runner CHAR(100) 
	DEFINE l_ret_code INTEGER 
	DEFINE l_msgresp LIKE language.yes_flag 

	IF get_os_arch() = 1 THEN --nt=1 
		RETURN 5 
	END IF 

	IF NOT os.path.exists(p_file_name) THEN --file does NOT exist 
		RETURN 1 
	END IF 

	IF NOT os.path.readable(p_file_name) THEN --file does NOT read 
		RETURN 2 
	END IF 

	IF NOT os.path.writable(p_file_name) THEN --file does NOT write 
		RETURN 3 
	END IF 

	IF NOT os.path.size(p_file_name) THEN --file does NOT have size (0) 
		RETURN 4 
	END IF 

	RETURN 5 


	#   LET l_runner = " [ -f ",p_file_name clipped," ] 2>>", trim(get_settings_logFile()) 
	#   run l_runner returning l_ret_code
	#   IF l_ret_code THEN
	#      RETURN 1
	#   END IF
	#   LET l_runner = " [ -r ",p_file_name clipped," ] 2>>", trim(get_settings_logFile()) 
	#   run l_runner returning l_ret_code
	#   IF l_ret_code THEN
	#      RETURN 2
	#   END IF
	#   LET l_runner = " [ -w ",p_file_name clipped," ] 2>>", trim(get_settings_logFile()) 
	#   run l_runner returning l_ret_code
	#   IF l_ret_code THEN
	#      RETURN 3
	#   END IF
	#   LET l_runner = " [ -s ",p_file_name clipped," ] 2>>", trim(get_settings_logFile()) 
	#   run l_runner returning l_ret_code
	#   IF l_ret_code THEN
	#      RETURN 4
	#   ELSE
	#      RETURN 5
	#   END IF
END FUNCTION 
}

