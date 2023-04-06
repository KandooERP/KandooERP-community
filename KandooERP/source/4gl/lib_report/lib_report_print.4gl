############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl" 
GLOBALS "../common/postfunc_GLOBALS.4gl"
----------------------------------------------------------------------------------------


###################################################################
# FUNCTION direct_print_by_rpt_idx(p_rpt_idx,p_report_type) 
###################################################################
FUNCTION direct_print_by_rpt_idx(p_rpt_idx,p_report_type) 
	DEFINE p_rpt_idx SMALLINT 
	DEFINE p_report_type STRING
	DEFINE l_rec_rmsreps RECORD LIKE rmsreps.* 
	DEFINE l_rec_printcodes RECORD LIKE printcodes.* 
	DEFINE l_normal_text NCHAR(20) 
	DEFINE l_compress_text NCHAR(20) 
	DEFINE l_file_name STRING 
	DEFINE l_err_message NCHAR(55) 
	DEFINE l_pr_view NCHAR(100) 
	DEFINE l_hostname NCHAR(40) 
	DEFINE l_view_type NCHAR(20) 
	DEFINE l_runner NCHAR(90) 
	DEFINE ir INTEGER 
	DEFINE j INTEGER 
	DEFINE l_line_counter INTEGER 
	DEFINE l_counter INTEGER 
	DEFINE l_ans NCHAR(1) 
	DEFINE l_msg STRING --just FOR temp messages 
	DEFINE l_buffer STRING 
	DEFINE l_bufferline STRING 
	DEFINE l_input_pipe NCHAR(20) 
	DEFINE rf SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_outpipe NCHAR(10) 

	IF p_rpt_idx IS NULL OR p_rpt_idx < 1 OR p_rpt_idx > glob_arr_rmsreps_idx.getSize() THEN
		LET l_msg = "Array Index out of range\np_rpt_idx=", trim(p_rpt_idx), "\nFUNCTION direct_print_by_rpt_idx(p_rpt_idx,p_report_type)"
		CALL fgl_winmessage("Inernal 4gl Error",l_msg,"ERROR")
		RETURN FALSE
	END IF
	
	LET l_rec_rmsreps.* = glob_arr_rec_rpt_rmsreps[p_rpt_idx].*

	#Report Owner can view it - other's need to check permission
	IF l_rec_rmsreps.entry_code != glob_rec_kandoouser.sign_on_code THEN
		IF NOT check_auth_with_idx_or_code(p_rpt_idx,l_rec_rmsreps.report_code,"V") THEN 
			LET l_msgresp = kandoomsg("U",5006,"") 
			#5006 Access denied - See System Administrator
			RETURN 
		END IF
	END IF 
	LET l_file_name = trim(rpt_add_path_to_report_file(l_rec_rmsreps.file_text))

	LET p_report_type = p_report_type.toLowerCase()

	CALL fgl_report_type(p_report_type,"text") 
	
	IF fgl_channel_open_file("stream", l_file_name, "r") = 0 THEN 
		LET l_msg = "Can NOT OPEN the file ", trim(l_file_name), "\nStatus=", status 
		CALL fgl_winmessage("Error",l_msg, "error") 
	ELSE 
		LET l_outpipe = "screen" 
		START REPORT rep_display_report TO pipe l_outpipe 
		WHILE fgl_channel_read("stream",l_bufferLine) 
			OUTPUT TO REPORT rep_display_report(l_bufferline) 
		END WHILE 
		CALL fgl_channel_close("stream") 
		FINISH REPORT rep_display_report 
	END IF 
 
	LET l_rec_rmsreps.status_ind = "L"
	LET l_rec_rmsreps.status_text = "Printed Locally"

	CASE l_rec_rmsreps.printonce_flag
		WHEN "N"
			#Nothing to be done in this case - can be re-printed freely
		WHEN "Y"
			LET l_rec_rmsreps.printonce_flag = "D"
		WHEN "D"
			CALL fgl_winmessage("Can only be printed once","Copy was printed","INFO")
		OTHERWISE
			LET l_msg = "Report/Print property printonce_flag=",trim(l_rec_rmsreps.printonce_flag), " is invalid"
			CALL fgl_winmessage("Internal 4GL Error",l_msg,"ERROR")
	END CASE
	 
	LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].* = l_rec_rmsreps.*
	CALL rpt_update_rmsreps2(p_rpt_idx) 
 
	CALL doneprompt("Close Preview","Close Preview","ACCEPT")
END FUNCTION 


###################################################################
# FUNCTION direct_print(p_rec_rmsreps,p_report_type) 
###################################################################
FUNCTION direct_print(p_rec_rmsreps,p_report_type) 
	DEFINE p_idx SMALLINT 
	DEFINE p_report_type STRING
	DEFINE p_rec_rmsreps RECORD LIKE rmsreps.* 
	DEFINE l_rec_printcodes RECORD LIKE printcodes.* 
	DEFINE l_normal_text NCHAR(20) 
	DEFINE l_compress_text NCHAR(20) 
	DEFINE l_file_name STRING 
	DEFINE l_err_message NCHAR(55) 
	DEFINE l_pr_view NCHAR(100) 
	DEFINE l_hostname NCHAR(40) 
	DEFINE l_view_type NCHAR(20) 
	DEFINE l_runner NCHAR(90) 
	DEFINE ir INTEGER 
	DEFINE j INTEGER 
	DEFINE l_line_counter INTEGER 
	DEFINE l_counter INTEGER 
	DEFINE l_ans NCHAR(1) 
	DEFINE l_tempmsg STRING --just FOR temp messages 
	DEFINE l_buffer STRING 
	DEFINE l_bufferline STRING 
	DEFINE l_input_pipe NCHAR(20) 
	DEFINE rf SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_outpipe NCHAR(10) 

	#Report Owner can view it - other's need to check permission
	IF p_rec_rmsreps.entry_code != glob_rec_kandoouser.sign_on_code THEN
		IF NOT check_auth_with_idx_or_code(p_idx,p_rec_rmsreps.report_code,"V") THEN 
			LET l_msgresp = kandoomsg("U",5006,"") 
			#5006 Access denied - See System Administrator
			RETURN 
		END IF
	END IF 
	LET l_file_name = trim(rpt_add_path_to_report_file(p_rec_rmsreps.file_text))

	LET p_report_type = p_report_type.toLowerCase()

	CALL fgl_report_type(p_report_type,"text") 
	
	IF fgl_channel_open_file("stream", l_file_name, "r") = 0 THEN 
		LET l_tempmsg = "Can NOT OPEN the file ", trim(l_file_name), "\nStatus=", status 
		CALL fgl_winmessage("Error",l_tempMsg, "error") 
	ELSE 
		LET l_outpipe = "screen" 
		START REPORT rep_display_report TO pipe l_outpipe 
		WHILE fgl_channel_read("stream",l_bufferLine) 
			OUTPUT TO REPORT rep_display_report(l_bufferline) 
		END WHILE 
		CALL fgl_channel_close("stream") 
		FINISH REPORT rep_display_report 
	END IF 
 
	IF NOT glob_in_trans THEN 
		BEGIN WORK 
	END IF 

		LET l_err_message = "rmsfunc.4gl - Update printonce flag" 

		UPDATE rmsreps 
		SET status_ind = "L", status_text = "Printed Locally"  
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND report_code = p_rec_rmsreps.report_code 

	IF NOT glob_in_trans THEN 
		COMMIT WORK 
	END IF 
 
	#CALL rpt_update_rmsreps2(l_rpt_idx) 
 
	CALL doneprompt("Close Preview","Close Preview","ACCEPT")
END FUNCTION 

###################################################################
# REPORT rep_display_report(p_rep_line)
#

###################################################################
REPORT rep_display_report(p_rep_line) 
	DEFINE p_rep_line STRING 

	FORMAT 
		ON EVERY ROW PRINT p_rep_line clipped 

END REPORT


  