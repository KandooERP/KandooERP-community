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

	Source code beautified by beautify.pl on 2020-01-03 18:54:40	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl"
GLOBALS "../common/glob_GLOBALS_report.4gl" 
GLOBALS "../utility/U_UT_GLOBALS.4gl" 
GLOBALS "../utility/U14_GLOBALS.4gl" 


#######################################################################
# MAIN
#
#
#######################################################################
MAIN 
	DEFINE l_action_ind CHAR(1) 
	DEFINE l_ret_code SMALLINT 
	DEFINE l_log_folder STRING 
	DEFINE l_msgresp LIKE language.yes_flag
	
	CALL setModuleId("U14") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_u_ut() #init utility module 
	CALL fgl_winmessage("Archaic log management, wait for V Next","","error")
	
	EXIT PROGRAM

	LET glob_time_text = CURRENT hour TO second 
	LET l_log_folder = get_settings_logPath() 
	IF l_log_folder IS NULL THEN 
		LET l_log_folder = "data/log" 
	END IF 
	#LET glob_filename = "/tmp/",
	LET glob_filename = trim(get_settings_logPath()), "/", 
	glob_rec_kandoouser.sign_on_code clipped 
	--glob_time_text[1,2], 
	--glob_time_text[4,5], 
	--glob_time_text[7,8] 


	IF get_url_action() IS NOT NULL THEN
--	IF num_args() = 1 THEN # allow running as part OF eod scripts 
		LET l_action_ind = get_url_action() 
		CASE l_action_ind 
			WHEN "F" 
				CALL cleanse_kandoo_log() 
			WHEN "P" 
				CALL report_kandoo_log() 
			WHEN "C" 
				CALL delete_kandoo_log() 
		END CASE 
	ELSE 
		CALL afile_status2() RETURNING l_ret_code 

		OPEN WINDOW U108 with FORM "U108" 
		CALL windecoration_u("U108") 

		MENU " Kandoo-Log-File" 
			BEFORE MENU 
				CALL publish_toolbar("kandoo","U14","menu-kandoo-log") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			COMMAND KEY ("F",f18) "First" " View first lines of Kandoo Log File" 
				CASE l_ret_code 
					WHEN 0 
						CALL view_kandoolog("head -") 
					WHEN 1 
						LET l_msgresp = kandoomsg("H",9001,"") 
						#9001 Kandoo log NOT found
						NEXT option "Exit" 
					WHEN 2 
						LET l_msgresp = kandoomsg("H",9005,"") 
						#9005 You are NOT allowed TO view Kandoo log
						NEXT option "Exit" 
					WHEN 4 
						LET l_msgresp = kandoomsg("H",9002,"") 
						#9001 Kandoo log IS empty
						NEXT option "Exit" 
					OTHERWISE 
						CALL view_kandoolog("head -") 
				END CASE 

			COMMAND KEY ("L",f22) "Last" " View last lines of Kandoo-log" 
				CASE l_ret_code 
					WHEN 0 
						CALL view_kandoolog("tail -") 
					WHEN 1 
						LET l_msgresp = kandoomsg("H",9001,"") 
						#9001 Kandoo log NOT found
						NEXT option "Exit" 
					WHEN 2 
						LET l_msgresp = kandoomsg("H",9005,"") 
						#9005 You are NOT allowed TO view Kandoo log
						NEXT option "Exit" 
					WHEN 4 
						LET l_msgresp = kandoomsg("H",9002,"") 
						#9001 Kandoo log IS empty
						NEXT option "Exit" 
					OTHERWISE 
						CALL view_kandoolog("tail -") 
				END CASE 

			COMMAND "Cleanse" " Cleanse common locking MESSAGEs FROM Kandoo log" 
				CASE l_ret_code 
					WHEN 1 
						LET l_msgresp = kandoomsg("H",9001,"") 
						#9001 Kandoo log NOT found
						NEXT option "Exit" 
					WHEN 3 
						LET l_msgresp = kandoomsg("H",9006,"") 
						#9006 You are NOT allowed TO  Kandoo log
						NEXT option "Exit" 
					WHEN 4 
						LET l_msgresp = kandoomsg("H",9002,"") 
						#9001 Kandoo log IS empty
						NEXT option "Exit" 
					OTHERWISE 
						CALL cleanse_kandoo_log() 
						NEXT option "Last" 
				END CASE 

			COMMAND "DELETE" " Delete all Kandoo log entries FROM the system" 
				CASE l_ret_code 
					WHEN 1 
						LET l_msgresp = kandoomsg("H",9001,"") 
						#9001 Kandoo log NOT found
						NEXT option "Exit" 
					WHEN 3 
						LET l_msgresp = kandoomsg("H",9006,"") 
						#9006 You are NOT allowed TO CLEAR Kandoo log
						NEXT option "Exit" 
					
					WHEN 4 
						LET l_msgresp = kandoomsg("H",9002,"") 
						#9001 Kandoo log IS empty
						NEXT option "Exit" 
					
					OTHERWISE 
						IF promptTF("",kandoomsg2("H",8001,""),1)	THEN
							CALL delete_kandoo_log() 
						END IF 
				END CASE 

			COMMAND "Report" " Run kandoo log MESSAGE/error REPORT" 
				CASE l_ret_code 
					WHEN 1 
						LET l_msgresp = kandoomsg("H",9001,"") 
						#9001 Kandoo log NOT found
						NEXT option "Exit" 
					WHEN 2 
						LET l_msgresp = kandoomsg("H",9005,"") 
						#9005 You are NOT allowed TO view Kandoo log
						NEXT option "Exit" 
					WHEN 4 
						LET l_msgresp = kandoomsg("H",9002,"") 
						#9001 Kandoo log IS empty
						NEXT option "Exit" 
					OTHERWISE 
						CALL report_kandoo_log() 
						LET glob_errorlog_text = "Kandoo log printed by ", 
						glob_rec_kandoouser.sign_on_code clipped, 
						" - Refer ", 
						glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("U14_rpt_list_log")].file_text clipped 
						CALL errorlog(glob_errorlog_text) 
 
				END CASE 

			ON ACTION "Print Manager" #COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
				CALL run_prog("URS","","","","") 

			COMMAND KEY(interrupt,"E")"Exit" " RETURN TO menus" 
				EXIT MENU 

		END MENU 

		CLOSE WINDOW u108 

	END IF 
END MAIN 



#######################################################################
# FUNCTION delete_kandoo_log()
#
#
#######################################################################
FUNCTION delete_kandoo_log() 
	DEFINE l_msgresp LIKE language.yes_flag
	DEFINE l_run_cmd STRING
	
	LET l_run_cmd = "cat /dev/NULL > ", trim(get_settings_logFile()) 
	CALL report_kandoo_log() # save CURRENT LOG in rms BEFORE clearing 
	RUN l_run_cmd
	LET glob_errorlog_text = "*** Kandoo log deleted by ", 
	glob_rec_kandoouser.sign_on_code clipped, 
	" - Refer ", 
	glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("U14_rpt_list_log")].file_text clipped, 
	" ***" 
	CALL errorlog(glob_errorlog_text) 
END FUNCTION 



#######################################################################
# FUNCTION report_kandoo_log()
#
#
#######################################################################
FUNCTION report_kandoo_log() 
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]

	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start("U14-L","U14_rpt_list_log","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT U14_rpt_list_log TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = 0, 
	BOTTOM MARGIN = 0, 
	LEFT MARGIN = 0, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------
	
	#---------------------------------------------------------
	OUTPUT TO REPORT U14_rpt_list_log(l_rpt_idx) 	
	#---------------------------------------------------------
 
	#------------------------------------------------------------
	FINISH REPORT U14_rpt_list_log
	CALL rpt_finish("U14_rpt_list_log")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 



#######################################################################
# FUNCTION view_kandoolog(p_func_text)
#
#
#######################################################################
FUNCTION view_kandoolog(p_func_text) 
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_func_text CHAR(6) 
	DEFINE l_term_ind CHAR(10) 
	DEFINE l_device_ind LIKE printcodes.device_ind 
	DEFINE l_print_text LIKE printcodes.print_text 
	DEFINE l_tail_num SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag
	
	LET l_term_ind = fgl_getenv("TERM") 
	LET l_tail_num = 20 
	INPUT l_term_ind, 
	l_tail_num WITHOUT DEFAULTS 
	FROM term_ind, 
	tail_num 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","U14","input-term_ind") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		ON KEY (control-b) 
			LET l_term_ind = show_print(glob_rec_kandoouser.cmpy_code) 
			DISPLAY l_term_ind 
			TO term_ind 

		AFTER FIELD term_ind 
			SELECT device_ind, print_text 
			INTO l_device_ind, 
			l_print_text 
			FROM printcodes 
			WHERE print_code = l_term_ind 
			IF status = notfound THEN 
				LET l_msgresp = kandoomsg("H",9003,"") 
				# 9003 Terminal type does NOT exist - Default taken
				LET l_term_ind = fgl_getenv("TERM") 
				DISPLAY l_term_ind 
				TO term_ind 

				LET l_print_text = "more -p 'Page ''%d' $F" 
			END IF 
			IF l_print_text IS NULL THEN 
				LET l_print_text = "more -p 'Page ''%d' $F" 
			END IF 
			IF l_device_ind != 2 THEN 
				LET l_msgresp = kandoomsg("H",9004,"") 
				# 9004 This IS NOT a terminal
				NEXT FIELD term_ind 
			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN 
	END IF 

	CLEAR screen 


	LET glob_cmd = 
	p_func_text, 
	l_tail_num USING "<<<", 
	" ", trim(get_settings_logFile()), 
	" > ", 
	glob_filename clipped 

	RUN glob_cmd 


	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start("U14-V","U14_rpt_list_view","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT U14_rpt_list_view TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = 0, 
	BOTTOM MARGIN = 0, 
	LEFT MARGIN = 0, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	#---------------------------------------------------------
	OUTPUT TO REPORT U14_rpt_list_view(l_rpt_idx) 	
	#---------------------------------------------------------
	
	#------------------------------------------------------------
	FINISH REPORT U14_rpt_list_view
	CALL rpt_finish("U14_rpt_list_view")
	#------------------------------------------------------------
	
	LET glob_cmd = "rm ", 
	glob_filename clipped, 
	" 2>/dev/NULL" 
	RUN glob_cmd 

END FUNCTION 


#######################################################################
# REPORT U14_rpt_list_view()
#
#
#######################################################################
FUNCTION cleanse_kandoo_log() 
	DEFINE l_line_num INTEGER 
	DEFINE l_line_cnt INTEGER 
	DEFINE l_total_cnt INTEGER 
	DEFINE l_del_cnt INTEGER 
	DEFINE idx INTEGER 
	DEFINE l_runner CHAR(300) 
	DEFINE l_msgresp LIKE language.yes_flag
	DEFINE l_message STRING
	
	LET idx = 0 
	LET l_del_cnt = 0 
	LET l_line_cnt = 0 
	LET l_total_cnt = 0 
	##
	## Need TO delete blank lines before performing load.
	##
	LET l_runner = "cat ", trim(get_settings_logFile()), " | grep -v '^$' > ",	glob_filename 
	RUN l_runner 
	--   OPEN WINDOW w1 AT 10,10 with 2 rows,60 columns  -- albo  KD-764

	LET l_msgresp=kandoomsg("U",1005,"") 
	WHENEVER ERROR CONTINUE 

	CREATE temp TABLE t1_kandoolog(line_num SERIAL, 
	line_text CHAR(240)) with no log; 

	DELETE FROM t1_kandoolog 
	LOAD FROM glob_filename INSERT INTO t1_kandoolog (line_text); 
	WHENEVER ERROR stop 

 
	MESSAGE " Loaded lines FROM ", trim(get_settings_logFile()), " file : ",sqlca.sqlerrd[3] 

	CREATE INDEX i1_t1_kandoolog ON t1_kandoolog (line_text) 
	CREATE INDEX i2_t1_kandoolog ON t1_kandoolog (line_num) 

	SELECT count(*) INTO l_total_cnt FROM t1_kandoolog 
	WHERE line_text = "SQL statement error number -244." 
	OR line_text = "SQL statement error number -113." 
	OR line_text = "SQL statement error number -271." 
	OR line_text = "SQL statement error number -233." 
	OR line_text = "SQL statement error number -246." 
	OR line_text = "SQL statement error number -378." 
	OR line_text = "SQL statement error number -349." 

	LET l_message = " Lock errors in log file : ",l_total_cnt 
	DISPLAY l_message TO lbinfo1 

	DECLARE c_kandoolog CURSOR FOR 
	SELECT line_num FROM t1_kandoolog 
	WHERE line_text = "SQL statement error number -244." 
	OR line_text = "SQL statement error number -113." 
	OR line_text = "SQL statement error number -271." 
	OR line_text = "SQL statement error number -233." 
	OR line_text = "SQL statement error number -246." 
	OR line_text = "SQL statement error number -378." 
	OR line_text = "SQL statement error number -349." 
	FOREACH c_kandoolog INTO l_line_num 
		LET l_line_cnt = l_line_cnt + 1 

--		DISPLAY " Removing ERROR ",l_line_cnt USING "<<<<<<<<<"," of ",l_total_cnt USING "<<<<<<<<<" TO lbinfo1 
		MESSAGE " Removing ERROR ",l_line_cnt USING "<<<<<<<<<"," of ",l_total_cnt USING "<<<<<<<<<" 

		DELETE FROM t1_kandoolog 
		WHERE line_num between (l_line_num-2) AND (l_line_num+3) 
		LET l_del_cnt = l_del_cnt + sqlca.sqlerrd[3] 

	END FOREACH 

	DROP INDEX i1_t1_kandoolog 
	DROP INDEX i2_t1_kandoolog 
	UNLOAD TO glob_filename SELECT line_text FROM t1_kandoolog; 
	
	IF fgl_find_table("t1_kandoolog") THEN
		DROP TABLE t1_kandoolog 
	END IF

	--   CLOSE WINDOW w1  -- albo  KD-764

	LET l_runner = "cat ", glob_filename clipped, " | sed s/.$//p > ", trim(get_settings_logFile()) 
	RUN l_runner 
	LET glob_errorlog_text = "*** ", trim(get_settings_logFile()), " cleansed by ", glob_rec_kandoouser.sign_on_code clipped, " ***" 
	CALL errorlog(glob_errorlog_text) 
END FUNCTION 


#######################################################################
# FUNCTION afile_status2()
#
#  FUNCTION returns one of the following VALUES
#        1. File NOT found
#        2. No read permission
#        3. No write permission
#        4. File IS Empty
#        5. OTHERWISE
#######################################################################
FUNCTION afile_status2()
	DEFINE l_path STRING 


	LET l_path = trim(get_settings_logFile()) 
	IF NOT os.Path.exists(l_path) THEN --file does NOT exist 
		RETURN 1 
	END IF 

	IF NOT os.Path.readable(l_path) THEN --file does NOT read 
		RETURN 2 
	END IF 

	IF NOT os.Path.writable(l_path) THEN --file does NOT write 
		RETURN 3 
	END IF 

	IF NOT os.Path.size(l_path) THEN --file does NOT have size (0) 
		RETURN 4 
	END IF 

	RETURN 5 
		{
	#huho - these runner OPTIONS are NOT Lycia compatible
	   LET runner = " [ -f ",trim(get_settings_logFile())," ] "
	   run runner returning ret_code
	   IF ret_code THEN
	      RETURN 1
	   END IF
	   LET runner = " [ -r ",trim(get_settings_logFile())," ] "
	   run runner returning ret_code
	   IF ret_code THEN
	      RETURN 2
	   END IF
	   LET runner = " [ -w ",trim(get_settings_logFile())," ] "
	   run runner returning ret_code
	   IF ret_code THEN
	      RETURN 3
	   END IF
	   LET runner = " [ -s ",trim(get_settings_logFile())," ] "
	   run runner returning ret_code
	   IF ret_code THEN
	      RETURN 4
	   ELSE
	      RETURN 5
	   END IF
	}
END FUNCTION


#######################################################################
# REPORT U14_rpt_list_view()
#
#
#######################################################################
REPORT U14_rpt_list_view(p_rpt_idx) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	OUTPUT 
	PAGE length 22 
	top margin 0 
	left margin 0 
	bottom margin 0 
	right margin 256 # <suse> really uses this! 

	FORMAT 
		ON EVERY ROW 
			PRINT file trim(get_settings_logFile())
END REPORT 



#######################################################################
# REPORT U14_rpt_list_log()
#
#
#######################################################################
REPORT U14_rpt_list_log(p_rpt_idx) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE l_col SMALLINT 
	DEFINE l_line1 CHAR(130) 

	OUTPUT 
	left margin 0 
	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  

			SKIP 1 line 
		ON EVERY ROW 
			PRINT file trim(get_settings_logFile()) 
		ON LAST ROW 
			PRINT COLUMN 1, "----------------------------------------", 
			"----------------------------------------" 
			SKIP 1 line 
			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	

END REPORT 

 