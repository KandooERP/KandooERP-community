############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl" 
############################################################
# MODULE Scope Variables
############################################################
DEFINE modu_rpt_background_process BOOLEAN
DEFINE modu_rpt_show_rmsreps_dialog BOOLEAN
--DEFINE modu_rec_rpt_settings OF t_rec_report_settings


############################################################
# FUNCTION rpt_get_is_background_process()
# RETURN modu_rpt_background_process BOOLEAN
# 
# Used for condition if report is running/processed in separate process / rmsreps already exists
############################################################
FUNCTION rpt_get_is_background_process()

	RETURN modu_rpt_background_process
END FUNCTION


############################################################
# FUNCTION rpt_set_is_background_process()
# RETURN modu_rpt_background_process BOOLEAN
# 
# Used for condition if report is running/processed in separate process / rmsreps already exists
############################################################
FUNCTION rpt_set_is_background_process(p_rpt_background_process)
	DEFINE p_rpt_background_process BOOLEAN

	LET modu_rpt_background_process = p_rpt_background_process

END FUNCTION


############################################################
# FUNCTION rpt_get_show_rmsreps_dialog()
# RETURN modu_rpt_show_rmsreps_dialog BOOLEAN
# 
# Used for condition to show/hide rmsreps report print dialog
############################################################
FUNCTION rpt_get_show_rmsreps_dialog()

	RETURN modu_rpt_show_rmsreps_dialog

END FUNCTION


############################################################
# FUNCTION rpt_get_show_rmsreps_dialog()
# RETURN modu_rpt_show_rmsreps_dialog BOOLEAN
# 
# Used for condition to show/hide rmsreps report print dialog
############################################################
FUNCTION rpt_set_show_rmsreps_dialog(p_rpt_show_rmsreps_dialog)
	DEFINE p_rpt_show_rmsreps_dialog BOOLEAN

	IF p_rpt_show_rmsreps_dialog IS NULL OR p_rpt_show_rmsreps_dialog = FALSE THEN
		LET modu_rpt_show_rmsreps_dialog = FALSE
	ELSE
		LET modu_rpt_show_rmsreps_dialog = TRUE
	END IF

END FUNCTION



############################################################
# FYIO - Ongoing cleanup -> move report settings to lib_report library
# NOTE: Original Kandoo defines report settings on different kinds of scopes etc.. 
# Target is, to use these settings on one location only 
############################################################
{
############################################################
# FUNCTION rpt_get_rec_settings()
#
# RETURN glob_rec_rpt_settings.* 
############################################################
FUNCTION rpt_get_rec_settings()
	RETURN glob_rec_rpt_settings.*
END FUNCTION

############################################################
# FUNCTION rpt_set_page_size(p_rpt_width,p_rpt_length)
#
############################################################
FUNCTION rpt_set_page_size(p_rpt_width,p_rpt_length)
	DEFINE p_rpt_width LIKE kandooreport.width_num
	DEFINE p_rpt_length LIKE kandooreport.length_num
	IF p_rpt_width != 0 AND p_rpt_width IS NOT NULL THEN
		# glob_rec_rpt_settings
		LET glob_rec_rpt_settings.rpt_width  = p_rpt_width 
		# Individual Globals
		LET glob_rpt_width  = glob_rec_rpt_settings.rpt_width 
		# glob_rec_kandooreport
		LET glob_rec_kandooreport.width_num = glob_rec_rpt_settings.rpt_width
		# glob_rec_rmsreps
		LET glob_rec_rmsreps.report_width_num = glob_rec_rpt_settings.rpt_width
	END IF

	IF p_rpt_length != 0 AND p_rpt_length IS NOT NULL THEN
		# glob_rec_rpt_settings
		LET glob_rec_rmsreps.page_length_num = p_rpt_length	
		# Individual Globals
		LET glob_rpt_length = glob_rec_rmsreps.page_length_num	
		# glob_rec_kandooreport
		LET glob_rec_kandooreport.length_num = glob_rec_rmsreps.page_length_num		
		# glob_rec_rmsreps
		LET glob_rec_rmsreps.page_length_num = glob_rec_rmsreps.page_length_num			
	END IF
END FUNCTION
}
{
############################################################
# FUNCTION rpt_set_width(p_width)
#
#
############################################################
FUNCTION rpt_set_width(p_width)
	DEFINE p_width LIKE rmsreps.report_width_num

	LET glob_rec_rpt_settings.rpt_width = p_width #MASTER

	LET glob_rpt_width = glob_rec_rpt_settings.rpt_width
	LET glob_rec_kandooreport.width_num = glob_rec_rpt_settings.rpt_width
	LET glob_rec_rmsreps.report_width_num = glob_rec_rpt_settings.rpt_width
END FUNCTION

############################################################
# FUNCTION glob_rec_rmsreps.report_width_num
#
#	RETURN glob_rec_rpt_settings.rpt_width
############################################################
FUNCTION glob_rec_rmsreps.report_width_num
	RETURN glob_rec_rpt_settings.rpt_width
END FUNCTION

############################################################
# FUNCTION rpt_set_length(p_length)
#
#
############################################################
FUNCTION rpt_set_length(p_length)
	DEFINE p_length LIKE rmsreps.page_length_num

	LET glob_rec_rmsreps.page_length_num = p_length
	
	LET glob_rpt_length = glob_rec_rmsreps.page_length_num
	LET glob_rec_kandooreport.length_num = glob_rec_rmsreps.page_length_num		
	LET glob_rec_rmsreps.page_length_num = glob_rec_rmsreps.page_length_num	
END FUNCTION
}
{
############################################################
# FUNCTION glob_rec_rmsreps.page_length_num
#
#	RETURN glob_rec_rmsreps.page_length_num
############################################################
FUNCTION glob_rec_rmsreps.page_length_num
	RETURN glob_rec_rmsreps.page_length_num
END FUNCTION
}
{
############################################################
# FUNCTION rpt_rmsreps_set_page_num(p_pageno)
#
#	
############################################################
FUNCTION rpt_rmsreps_set_page_num(p_pageno)
	DEFINE p_pageno LIKE rmsreps.page_num 

	LET glob_rec_rpt_settings.rpt_pageno = p_pageno
	
	LET glob_rpt_pageno = glob_rec_rpt_settings.rpt_pageno
	LET glob_rec_rmsreps.page_num = glob_rec_rpt_settings.rpt_pageno
	#NOT in glob_rec_kandooreport
	
END FUNCTION

############################################################
# FUNCTION rpt_set_pageno_increment()
#
#	
############################################################
FUNCTION rpt_set_pageno_increment()
	LET glob_rec_rpt_settings.rpt_pageno = glob_rec_rpt_settings.rpt_pageno + 1
	
	LET glob_rpt_pageno = glob_rec_rpt_settings.rpt_pageno
	LET glob_rec_rmsreps.page_num = glob_rec_rpt_settings.rpt_pageno
END FUNCTION

############################################################
# FUNCTION glob_rec_rmsreps.page_num
#
#	RETURN glob_rec_rpt_settings.rpt_pageno
############################################################
FUNCTION glob_rec_rmsreps.page_num
	RETURN glob_rec_rpt_settings.rpt_pageno
END FUNCTION
}
{
############################################################
# FUNCTION rpt_set_note(p_note)
#
#	
############################################################
FUNCTION rpt_set_note(p_note)
	DEFINE p_note LIKE rmsreps.report_text 

	LET glob_rec_rpt_settings.rpt_note = p_note #MASTER
	
	LET glob_rpt_note = glob_rec_rpt_settings.rpt_note
	
END FUNCTION

############################################################
# FUNCTION rpt_get_note()
#
# RETURN glob_rec_rpt_settings.rpt_note
############################################################
FUNCTION rpt_get_note()
	RETURN glob_rec_rpt_settings.rpt_note
END FUNCTION

############################################################
# FUNCTION rpt_set_output(p_output)
#
# Report filname inc. rel. path
############################################################
FUNCTION rpt_set_output(p_output)
	DEFINE p_output STRING 

	LET glob_rec_rpt_settings.rpt_file_path_name = p_output #MASTER file name inc. rel path

	LET glob_rec_rmsreps.file_text = glob_rec_rpt_settings.rpt_file_path_name
	LET glob_rec_rpt_settings.rpt_output = glob_rec_rpt_settings.rpt_file_path_name
	LET glob_rpt_output = glob_rec_rpt_settings.rpt_file_path_name
	
END FUNCTION

############################################################
# FUNCTION rpt_get_output()
#
#	RETURN glob_rec_rpt_settings.rpt_file_path_name
############################################################
FUNCTION rpt_get_output()
	RETURN glob_rec_rpt_settings.rpt_file_path_name
END FUNCTION

############################################################
# FUNCTION rpt_set_report_header(p_rpt_header)
#
#	Kandoo uses report_text, line1_text, rpt_title1, header_text and rpt_note  #what a mess
############################################################
FUNCTION rpt_set_report_header(p_rpt_header)
	DEFINE p_rpt_header STRING
	
	LET glob_rec_rpt_settings.rpt_title1 = p_rpt_header
	LET glob_rec_rpt_settings.rpt_note = glob_rec_rpt_settings.rpt_title1	
	
	LET glob_rpt_note = glob_rec_rpt_settings.rpt_title1
	
	#DB rmsreps
	LET glob_rec_rmsreps.report_text =  glob_rec_rpt_settings.rpt_title1  #HuHo - I believe glob_rpt_note is identical to glob_rec_rmsreps.report_text and glob_rec_rpt_settings.rpt_note (Paramater p_rpt_note) 	
	
	#DB kandooreport
	LET glob_rec_kandooreport.header_text = glob_rec_rpt_settings.rpt_title1
	LET glob_rec_kandooreport.line1_text = glob_rec_rpt_settings.rpt_title1
	
	LET glob_rpt_note =  glob_rec_rpt_settings.rpt_title1  #title line 1 text 
	#LET glob_rpt_note2 = glob_rec_rpt_settings.rpt_title2 #title line 2 text	
	LET glob_rpt_line1 = glob_rec_rpt_settings.rpt_title1  #title line 1 text 
	#LET glob_rpt_line2 = glob_rec_rpt_settings.rpt_title2 #title line 2 text
	
	#Report Header = report_text AND line1_text...			
END FUNCTION	

############################################################
# FUNCTION rpt_set_report_header()
#
#	RETURN glob_rec_rpt_settings.rpt_title1
############################################################
FUNCTION rpt_get_report_header()
	RETURN glob_rec_rpt_settings.rpt_title1
END FUNCTION

############################################################
# FUNCTION rpt_set_line1_text(p_line1)
#
#	RETURN glob_rec_rpt_settings.rpt_file_path_name
############################################################
FUNCTION rpt_set_line1_text(p_line1)
	DEFINE p_line1 STRING 

	LET glob_rec_rpt_settings.rpt_title1 = p_line1
	LET glob_rec_rpt_settings.rpt_line1_text = glob_rec_rpt_settings.rpt_title1
	LET glob_rpt_line1 = glob_rec_rpt_settings.rpt_title1
	LET glob_rec_rmsreps.report_text = glob_rec_rpt_settings.rpt_title1
	LET glob_rec_kandooreport.header_text = glob_rec_rpt_settings.rpt_title1	
END FUNCTION

############################################################
# FUNCTION rpt_get_line1_text()
#
#	RETURN glob_rec_rpt_settings.rpt_title1
############################################################
FUNCTION rpt_get_line1_text()
	RETURN glob_rec_rpt_settings.rpt_title1
END FUNCTION

############################################################
# FUNCTION rpt_set_line2_text(p_line2)
#
#	
############################################################
FUNCTION rpt_set_line2_text(p_line2)
	DEFINE p_line2 STRING 
	LET glob_rec_rpt_settings.rpt_title2 = p_line2
	LET glob_rec_rpt_settings.rpt_line2_text = glob_rec_rpt_settings.rpt_title2
	LET glob_rpt_line2 = glob_rec_rpt_settings.rpt_title2
	
END FUNCTION

############################################################
# FUNCTION rpt_get_line2_text()
#
#	RETURN glob_rec_rpt_settings.rpt_title1
############################################################
FUNCTION rpt_get_line2_text()
	RETURN glob_rec_rpt_settings.rpt_title2
END FUNCTION


############################################################
# FUNCTION rpt_set_offset1(p_offset1)
#
#	Used to calc and store the center location for report header 1
#
# NOTE: This should be replaced by a simple return-location function 
# no reason to store this value
############################################################
FUNCTION rpt_set_offset1(p_offset1)
	DEFINE p_offset1 SMALLINT

	LET glob_rec_rpt_settings.rpt_offset1 = p_offset1
	LET glob_rpt_offset1 = glob_rec_rpt_settings.rpt_offset1
	
END FUNCTION

############################################################
# FUNCTION rpt_get_offset1()
#
#	RETURN glob_rec_rpt_settings.rpt_offset1
############################################################
FUNCTION rpt_get_offset1()
	RETURN glob_rec_rpt_settings.rpt_offset1
END FUNCTION

############################################################
# FUNCTION rpt_set_offset1(p_offset1)
#
#	Used to calc and store the center location for report header 2
#
# NOTE: This should be replaced by a simple return-location function 
# no reason to store this value
############################################################
FUNCTION rpt_set_offset2(p_offset2)
	DEFINE p_offset2 SMALLINT 

	LET glob_rec_rpt_settings.rpt_offset2 = p_offset2
	LET glob_rpt_offset2 = glob_rec_rpt_settings.rpt_offset2
	
END FUNCTION

############################################################
# FUNCTION rpt_get_offset2()
#
#	RETURN glob_rec_rpt_settings.rpt_offset2
############################################################
FUNCTION rpt_get_offset2()
	RETURN glob_rec_rpt_settings.rpt_offset2
END FUNCTION


############################################################
# FUNCTION rpt_set_report_code(p_report_code)
#
#	RETURN glob_rec_rpt_settings.rpt_offset2
#
# DANGEROUS - Kandoo uses the var name report_code for different purpose and dataType 
# INT=PK char(10) and char(20).. some kind of report name
#
# Here, we are woring with rpt_report_code LIKE rmsreps.report_code, #INT 
# in DB table kandooreport -> glob_rec_kandooreport.l_report_code (because here, report_code is char(10)
############################################################	
FUNCTION rpt_set_report_code(p_report_code)
	DEFINE p_report_code LIKE rmsreps.report_code
	
	IF p_report_code IS NOT NULL THEN
		LET glob_rec_rpt_settings.rpt_report_code = p_report_code
		LET glob_rpt_code_int = glob_rec_rpt_settings.rpt_report_code #Individual globals
		LET glob_rec_rmsreps.report_code = glob_rec_rpt_settings.rpt_report_code #glob_rec_rmsreps
		LET glob_rec_kandooreport.l_report_code = glob_rec_rpt_settings.rpt_report_code #glob_rec_kandooreport
	ELSE
		LET glob_rec_rpt_settings.rpt_report_code = 0
		LET glob_rpt_code_int = 0 #Individual globals
		LET glob_rec_rmsreps.report_code = 0 #glob_rec_rmsreps
		LET glob_rec_kandooreport.l_report_code = 0 #glob_rec_kandooreport	
	END IF
	
END FUNCTION

############################################################
# FUNCTION rpt_get_report_code()
#
# RETURN glob_rec_rpt_settings.rpt_report_code
############################################################
FUNCTION rpt_get_report_code()
	RETURN glob_rec_rpt_settings.rpt_report_code
END FUNCTION


############################################################
# FUNCTION rpt_set_file_text(p_file_text)
#
# RETURN glob_rec_rpt_settings.rpt_report_code
############################################################
FUNCTION rpt_set_file_text(p_file_text)
	DEFINE p_file_text LIKE rmsreps.file_text #nchar(20)
	
	LET	glob_rec_rpt_settings.rpt_file_name = p_file_text #NVARCHAR(100)
	LET glob_rec_rmsreps.file_text = glob_rec_rpt_settings.rpt_file_name
	LET glob_rec_rpt_settings.rpt_file_path_name = trim(get_settings_reportPath()), "/", glob_rec_rpt_settings.rpt_file_name CLIPPED
	#LET glob_rec_rpt_settings.rpt_file_path_name = trim(get_settings_reportPath()), "/", glob_rec_rpt_settings.rpt_cmpy_code clipped, ".",glob_rec_rpt_settings.rpt_report_code clipped USING "<<<<<<<<" 
	#LET rpt_file_path_name = ???# NVARCHAR(150),	
	
	#not sure about this one...
	LET glob_rec_kandooreport.report_code = glob_rec_rmsreps.file_text #??? #report_code nchar(10)
	LET glob_rec_rmsreps.file_text = glob_rec_rmsreps.file_text

END FUNCTION


############################################################
# FUNCTION rpt_set_date_time(p_date,p_time)
#
# 
############################################################
FUNCTION rpt_set_date_time(p_date,p_time)
	DEFINE p_date LIKE rmsreps.report_date
	DEFINE p_time LIKE rmsreps.report_time
	
	IF p_date IS NOT NULL THEN
		LET glob_rec_rmsreps.report_date = p_date
	ELSE
		LET glob_rec_rmsreps.report_date = today
	END IF

	IF p_time IS NOT NULL THEN
		LET glob_rec_rpt_settings.rpt_time = p_time
	ELSE
		LET glob_rec_rpt_settings.rpt_time = today
	END IF

	#---------------------------
	#Individual Globals
	#---------------------------
	LET glob_rpt_date = glob_rec_rmsreps.report_date
	LET glob_rpt_date2 = glob_rec_rmsreps.report_date
	LET glob_rpt_time = glob_rec_rpt_settings.rpt_time
	LET glob_rpt_time2 = glob_rec_rpt_settings.rpt_time
	#---------------------------
	#glob_rec_rmsreps
	#---------------------------
	LET glob_rec_rmsreps.report_date = glob_rec_rmsreps.report_date
	LET glob_rec_rmsreps.report_time = glob_rec_rpt_settings.rpt_time
	#---------------------------
	#glob_rec_kandooreport
	#---------------------------
	LET glob_rec_kandooreport.l_report_date = glob_rec_rmsreps.report_date
	LET glob_rec_kandooreport.l_report_time = glob_rec_rpt_settings.rpt_time
		
END FUNCTION

############################################################
# FUNCTION rpt_set_security_ind(p_security_ind)
#
############################################################
FUNCTION rpt_set_security_ind(p_security_ind)
	DEFINE p_security_ind LIKE kandoouser.security_ind 

	LET glob_rec_rpt_settings.rpt_security_ind = p_security_ind
	#LET glob_rpt_security_ind = glob_rec_rpt_settings.rpt_security_ind
	LET glob_rec_rmsreps.security_ind = glob_rec_rpt_settings.rpt_security_ind
END FUNCTION

############################################################
# FUNCTION rpt_get_security_ind()
#
#	RETURN glob_rec_rpt_settings.rpt_security_ind
############################################################
FUNCTION rpt_get_security_ind()
	RETURN glob_rec_rpt_settings.rpt_security_ind
END FUNCTION

############################################################
# FUNCTION rpt_set_module_id(p_rpt_module_id)
#
############################################################
FUNCTION rpt_set_module_id(p_rpt_module_id)
	DEFINE p_rpt_module_id VARCHAR(5) 
	#NOTE: DB-kandoouser defines menu path as nchar(4) but we need char(5) !!!!!!!!!!!!!!!!!!!
	LET glob_rec_rpt_settings.rpt_module_id = p_rpt_module_id
	LET glob_rec_kandooreport.menupath_text = glob_rec_rpt_settings.rpt_module_id 	
END FUNCTION

############################################################
# FUNCTION rpt_get_module_id()
#
#	RETURN glob_rec_rpt_settings.rpt_module_id
############################################################
FUNCTION rpt_get_module_id()
	RETURN glob_rec_rpt_settings.rpt_module_id
END FUNCTION

############################################################
# FUNCTION rpt_set_entry_code(p_rpt_entry_code)
#
############################################################
FUNCTION rpt_set_entry_code(p_rpt_entry_code)
	DEFINE p_rpt_entry_code LIKE kandoouser.sign_on_code  

	LET glob_rec_rpt_settings.rpt_entry_code = p_rpt_entry_code
	LET glob_rec_kandooreport.l_entry_code = glob_rec_rpt_settings.rpt_entry_code	
END FUNCTION

############################################################
# FUNCTION rpt_get_entry_code()
#
#	RETURN glob_rec_rpt_settings.rpt_entry_code
############################################################
FUNCTION rpt_get_entry_code()
	RETURN glob_rec_rpt_settings.rpt_entry_code
END FUNCTION


############################################################
# FUNCTION rpt_set_cmpy_code(p_rpt_cmpy_code)
#
############################################################
FUNCTION rpt_set_cmpy_code(p_rpt_cmpy_code)
	DEFINE p_rpt_cmpy_code LIKE kandoouser.sign_on_code  

	LET glob_rec_rpt_settings.rpt_cmpy_code = p_rpt_cmpy_code #MASTER

	LET glob_rec_rmsreps.cmpy_code = glob_rec_rpt_settings.rpt_cmpy_code
END FUNCTION

############################################################
# FUNCTION rpt_get_cmpy_code()
#
#	RETURN glob_rec_rpt_settings.rpt_cmpy_code
############################################################
FUNCTION rpt_get_cmpy_code()
	RETURN glob_rec_rpt_settings.rpt_cmpy_code
END FUNCTION


############################################################
# FUNCTION rpt_set_status_text(p_rpt_status_text)
#
############################################################
FUNCTION rpt_set_status_text(p_rpt_status_text)
	DEFINE p_rpt_status_text LIKE rmsreps.status_text  

	LET glob_rec_rpt_settings.rpt_status_text = p_rpt_status_text #MASTER

	LET glob_rec_rmsreps.status_text = glob_rec_rpt_settings.rpt_status_text
END FUNCTION

############################################################
# FUNCTION rpt_get_status_text()
#
#	RETURN glob_rec_rpt_settings.rpt_status_text
############################################################
FUNCTION rpt_get_status_text()
	RETURN glob_rec_rpt_settings.rpt_status_text
END FUNCTION

############################################################
# FUNCTION rpt_set_pgm_text(p_rpt_pgm_text)
#
############################################################
FUNCTION rpt_set_pgm_text(p_rpt_pgm_text)
	DEFINE p_rpt_pgm_text LIKE rmsreps.report_pgm_text  

	LET glob_rec_rpt_settings.rpt_pgm_text = p_rpt_pgm_text #MASTER

	LET glob_rec_rmsreps.report_pgm_text = glob_rec_rpt_settings.rpt_pgm_text
END FUNCTION

############################################################
# FUNCTION rpt_get_pgm_text()
#
#	RETURN glob_rec_rpt_settings.rpt_pgm_text
############################################################
FUNCTION rpt_get_pgm_text()
	RETURN glob_rec_rpt_settings.rpt_pgm_text
END FUNCTION

############################################################
# FUNCTION rpt_get_next_report_num()
#
# Retrieves next report number and increments rmsparm.next_report_num++
#	RETURN l_ret_report_num
############################################################
FUNCTION rpt_get_next_report_num()
	DEFINE l_ret_report_num LIKE rmsreps.report_code
	
	WHENEVER SQLERROR CONTINUE
	BEGIN WORK 
		DECLARE c2_rmsparm CURSOR FOR 
		SELECT next_report_num FROM rmsparm 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		FOR UPDATE 
		OPEN c2_rmsparm 
		FETCH c2_rmsparm INTO l_ret_report_num 
		IF status = notfound THEN 
			CALL fgl_winmessage("Setup Incorrect - Exit Program",kandoomsg2("G",5004,""),"ERROR") 
			#5004 Report Parameters NOT SET up - Get out
			EXIT program 
		END IF 
		IF l_ret_report_num >= 99999000 THEN 
			LET l_ret_report_num = 1 
		END IF 

		#Ensure again????, ... a bit strange to me. PK = cmpy_code AND report_code... so, there can only be ONE or NONE
		WHILE true 
			SELECT unique 1 FROM rmsreps 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code  
			AND report_code = l_ret_report_num
			IF status = notfound THEN 
				EXIT WHILE 
			ELSE 
				LET l_ret_report_num = l_ret_report_num + 1 #use the next available report_code number
				IF l_ret_report_num >= 99999000 THEN #at the end, start from 1 again
					LET l_ret_report_num = 1 
				END IF 
			END IF 
		END WHILE 

		#Update next_report_num for the next available report_code id (to be used by the next report)
		UPDATE rmsparm 
		SET next_report_num = l_ret_report_num + 1 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code  

	COMMIT WORK 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	
	CALL rpt_set_report_code(l_ret_report_num)
	
	RETURN l_ret_report_num	 
END FUNCTION


############################################################
# FUNCTION rpt_set_dest_printer_default()
#
############################################################
FUNCTION rpt_set_dest_printer_default()
	DEFINE p_rpt_dest_printer LIKE rmsreps.dest_print_text  

	LET glob_rec_rpt_settings.rpt_dest_printer = glob_rec_kandoouser.print_text #MASTER

	LET glob_rec_rmsreps.dest_print_text = glob_rec_rpt_settings.rpt_dest_printer
END FUNCTION


############################################################
# FUNCTION rpt_set_dest_printer(p_rpt_dest_printer)
#
############################################################
FUNCTION rpt_set_dest_printer(p_rpt_dest_printer)
	DEFINE p_rpt_dest_printer LIKE rmsreps.dest_print_text  

	LET glob_rec_rpt_settings.rpt_dest_printer = p_rpt_dest_printer #MASTER

	LET glob_rec_rmsreps.dest_print_text = glob_rec_rpt_settings.rpt_dest_printer
END FUNCTION

--############################################################
--# FUNCTION rpt_get_dest_printer()
--#
--#	RETURN glob_rec_rpt_settings.rpt_dest_printer
--############################################################
--FUNCTION rpt_get_dest_printer(p_rpt_idx)
--	DEFINE p_rpt_idx SMALLINT #rpt array index
--	RETURN glob_rec_rpt_settings.rpt_dest_printer
--END FUNCTION


############################################################
# FUNCTION rpt_set_start_page(p_rpt_start_page)
#
############################################################
FUNCTION rpt_set_start_page(p_rpt_start_page)
	DEFINE p_rpt_start_page LIKE rmsreps.start_page  

	LET glob_rec_rpt_settings.rpt_start_page = p_rpt_start_page #MASTER

	LET glob_rec_rmsreps.dest_print_text = glob_rec_rpt_settings.rpt_start_page
END FUNCTION

############################################################
# FUNCTION rpt_get_start_page()
#
#	RETURN glob_rec_rpt_settings.rpt_start_page
############################################################
FUNCTION rpt_get_start_page()
	RETURN glob_rec_rpt_settings.rpt_start_page
END FUNCTION

############################################################
# FUNCTION rpt_set_align_ind(p_rpt_align_ind)
#
############################################################
FUNCTION rpt_set_align_ind(p_rpt_align_ind)
	DEFINE p_rpt_align_ind LIKE rmsreps.align_ind  

	LET glob_rec_rpt_settings.rpt_align_ind = p_rpt_align_ind #MASTER

	LET glob_rec_rmsreps.dest_print_text = glob_rec_rpt_settings.rpt_align_ind
END FUNCTION

############################################################
# FUNCTION rpt_get_align_ind()
#
#	RETURN glob_rec_rpt_settings.rpt_align_ind
############################################################
FUNCTION rpt_get_align_ind()
	RETURN glob_rec_rpt_settings.rpt_align_ind
END FUNCTION

############################################################
# FUNCTION rpt_set_copy_num(p_rpt_copy_num)
#
############################################################
FUNCTION rpt_set_copy_num(p_rpt_copy_num)
	DEFINE p_rpt_copy_num LIKE rmsreps.copy_num  

	LET glob_rec_rpt_settings.rpt_copy_num = p_rpt_copy_num #MASTER

	LET glob_rec_rmsreps.dest_print_text = glob_rec_rpt_settings.rpt_copy_num
END FUNCTION

############################################################
# FUNCTION rpt_get_copy_num()
#
#	RETURN glob_rec_rpt_settings.rpt_copy_num
############################################################
FUNCTION rpt_get_copy_num()
	RETURN glob_rec_rpt_settings.rpt_copy_num
END FUNCTION

############################################################
# FUNCTION rpt_set_ref1_code(p_rpt_ref1_code)
#
############################################################
FUNCTION rpt_set_ref1_code(p_rpt_ref1_code)
	DEFINE p_rpt_ref1_code LIKE rmsreps.ref1_code  

	LET glob_rec_rpt_settings.rpt_ref1_code = p_rpt_ref1_code #MASTER

	LET glob_rec_rmsreps.dest_print_text = glob_rec_rpt_settings.rpt_ref1_code
END FUNCTION

############################################################
# FUNCTION rpt_get_ref1_code()
#
#	RETURN glob_rec_rpt_settings.rpt_ref1_code
############################################################
FUNCTION rpt_get_ref1_code()
	RETURN glob_rec_rpt_settings.rpt_ref1_code
END FUNCTION

############################################################
# FUNCTION rpt_set_ref2_code(p_rpt_ref2_code)
#
############################################################
FUNCTION rpt_set_ref2_code(p_rpt_ref2_code)
	DEFINE p_rpt_ref2_code LIKE rmsreps.ref2_code  

	LET glob_rec_rpt_settings.rpt_ref2_code = p_rpt_ref2_code #MASTER

	LET glob_rec_rmsreps.dest_print_text = glob_rec_rpt_settings.rpt_ref2_code
END FUNCTION

############################################################
# FUNCTION rpt_get_ref2_code()
#
#	RETURN glob_rec_rpt_settings.rpt_ref2_code
############################################################
FUNCTION rpt_get_ref2_code()
	RETURN glob_rec_rpt_settings.rpt_ref2_code
END FUNCTION

############################################################
# FUNCTION rpt_set_ref3_code(p_rpt_ref3_code)
#
############################################################
FUNCTION rpt_set_ref3_code(p_rpt_ref3_code)
	DEFINE p_rpt_ref3_code LIKE rmsreps.ref3_code  

	LET glob_rec_rpt_settings.rpt_ref3_code = p_rpt_ref3_code #MASTER

	LET glob_rec_rmsreps.dest_print_text = glob_rec_rpt_settings.rpt_ref3_code
END FUNCTION

############################################################
# FUNCTION rpt_get_ref3_code()
#
#	RETURN glob_rec_rpt_settings.rpt_ref3_code
############################################################
FUNCTION rpt_get_ref3_code()
	RETURN glob_rec_rpt_settings.rpt_ref3_code
END FUNCTION

############################################################
# FUNCTION rpt_set_ref4_code(p_rpt_ref4_code)
#
############################################################
FUNCTION rpt_set_ref4_code(p_rpt_ref4_code)
	DEFINE p_rpt_ref4_code LIKE rmsreps.ref4_code  

	LET glob_rec_rpt_settings.rpt_ref4_code = p_rpt_ref4_code #MASTER

	LET glob_rec_rmsreps.dest_print_text = glob_rec_rpt_settings.rpt_ref4_code
END FUNCTION

############################################################
# FUNCTION rpt_get_ref4_code()
#
#	RETURN glob_rec_rpt_settings.rpt_ref4_code
############################################################
FUNCTION rpt_get_ref4_code()
	RETURN glob_rec_rpt_settings.rpt_ref4_code
END FUNCTION

############################################################
# FUNCTION rpt_set_ref1_date(p_rpt_ref1_date)
#
############################################################
FUNCTION rpt_set_ref1_date(p_rpt_ref1_date)
	DEFINE p_rpt_ref1_date LIKE rmsreps.ref1_date  

	LET glob_rec_rpt_settings.rpt_ref1_date = p_rpt_ref1_date #MASTER

	LET glob_rec_rmsreps.dest_print_text = glob_rec_rpt_settings.rpt_ref1_date
END FUNCTION

############################################################
# FUNCTION rpt_get_ref1_date()
#
#	RETURN glob_rec_rpt_settings.rpt_ref1_date
############################################################
FUNCTION rpt_get_ref1_date()
	RETURN glob_rec_rpt_settings.rpt_ref1_date
END FUNCTION

############################################################
# FUNCTION rpt_set_ref2_date(p_rpt_ref2_date)
#
############################################################
FUNCTION rpt_set_ref2_date(p_rpt_ref2_date)
	DEFINE p_rpt_ref2_date LIKE rmsreps.ref2_date  

	LET glob_rec_rpt_settings.rpt_ref2_date = p_rpt_ref2_date #MASTER

	LET glob_rec_rmsreps.dest_print_text = glob_rec_rpt_settings.rpt_ref2_date
END FUNCTION

############################################################
# FUNCTION rpt_get_ref2_date()
#
#	RETURN glob_rec_rpt_settings.rpt_ref2_date
############################################################
FUNCTION rpt_get_ref2_date()
	RETURN glob_rec_rpt_settings.rpt_ref2_date
END FUNCTION
############################################################
# FUNCTION rpt_set_ref3_date(p_rpt_ref3_date)
#
############################################################
FUNCTION rpt_set_ref3_date(p_rpt_ref3_date)
	DEFINE p_rpt_ref3_date LIKE rmsreps.ref3_date  

	LET glob_rec_rpt_settings.rpt_ref3_date = p_rpt_ref3_date #MASTER

	LET glob_rec_rmsreps.dest_print_text = glob_rec_rpt_settings.rpt_ref3_date
END FUNCTION

############################################################
# FUNCTION rpt_get_ref3_date()
#
#	RETURN glob_rec_rpt_settings.rpt_ref3_date
############################################################
FUNCTION rpt_get_ref3_date()
	RETURN glob_rec_rpt_settings.rpt_ref3_date
END FUNCTION
############################################################
# FUNCTION rpt_set_ref4_date(p_rpt_ref4_date)
#
############################################################
FUNCTION rpt_set_ref4_date(p_rpt_ref4_date)
	DEFINE p_rpt_ref4_date LIKE rmsreps.ref4_date  

	LET glob_rec_rpt_settings.rpt_ref4_date = p_rpt_ref4_date #MASTER

	LET glob_rec_rmsreps.dest_print_text = glob_rec_rpt_settings.rpt_ref4_date
END FUNCTION

############################################################
# FUNCTION rpt_get_ref4_date()
#
#	RETURN glob_rec_rpt_settings.rpt_ref4_date
############################################################
FUNCTION rpt_get_ref4_date()
	RETURN glob_rec_rpt_settings.rpt_ref4_date
END FUNCTION


############################################################
# FUNCTION rpt_set_ref1_ind(p_rpt_ref1_ind)
#
############################################################
FUNCTION rpt_set_ref1_ind(p_rpt_ref1_ind)
	DEFINE p_rpt_ref1_ind LIKE rmsreps.ref1_ind  

	LET glob_rec_rpt_settings.rpt_ref1_ind = p_rpt_ref1_ind #MASTER

	LET glob_rec_rmsreps.dest_print_text = glob_rec_rpt_settings.rpt_ref1_ind
END FUNCTION

############################################################
# FUNCTION rpt_get_ref1_ind()
#
#	RETURN glob_rec_rpt_settings.rpt_ref1_ind
############################################################
FUNCTION rpt_get_ref1_ind()
	RETURN glob_rec_rpt_settings.rpt_ref1_ind
END FUNCTION


############################################################
# FUNCTION rpt_set_ref2_ind(p_rpt_ref2_ind)
#
############################################################
FUNCTION rpt_set_ref2_ind(p_rpt_ref2_ind)
	DEFINE p_rpt_ref2_ind LIKE rmsreps.ref2_ind  

	LET glob_rec_rpt_settings.rpt_ref2_ind = p_rpt_ref2_ind #MASTER

	LET glob_rec_rmsreps.dest_print_text = glob_rec_rpt_settings.rpt_ref2_ind
END FUNCTION

############################################################
# FUNCTION rpt_get_ref2_ind()
#
#	RETURN glob_rec_rpt_settings.rpt_ref2_ind
############################################################
FUNCTION rpt_get_ref2_ind()
	RETURN glob_rec_rpt_settings.rpt_ref2_ind
END FUNCTION


############################################################
# FUNCTION rpt_set_ref3_ind(p_rpt_ref3_ind)
#
############################################################
FUNCTION rpt_set_ref3_ind(p_rpt_ref3_ind)
	DEFINE p_rpt_ref3_ind LIKE rmsreps.ref3_ind  

	LET glob_rec_rpt_settings.rpt_ref3_ind = p_rpt_ref3_ind #MASTER

	LET glob_rec_rmsreps.dest_print_text = glob_rec_rpt_settings.rpt_ref3_ind
END FUNCTION

############################################################
# FUNCTION rpt_get_ref3_ind()
#
#	RETURN glob_rec_rpt_settings.rpt_ref3_ind
############################################################
FUNCTION rpt_get_ref3_ind()
	RETURN glob_rec_rpt_settings.rpt_ref3_ind
END FUNCTION


############################################################
# FUNCTION rpt_set_ref4_ind(p_rpt_ref4_ind)
#
############################################################
FUNCTION rpt_set_ref4_ind(p_rpt_ref4_ind)
	DEFINE p_rpt_ref4_ind LIKE rmsreps.ref4_ind  

	LET glob_rec_rpt_settings.rpt_ref4_ind = p_rpt_ref4_ind #MASTER

	LET glob_rec_rmsreps.dest_print_text = glob_rec_rpt_settings.rpt_ref4_ind
END FUNCTION

############################################################
# FUNCTION rpt_get_ref4_ind()
#
#	RETURN glob_rec_rpt_settings.rpt_ref4_ind
############################################################
FUNCTION rpt_get_ref4_ind()
	RETURN glob_rec_rpt_settings.rpt_ref4_ind
END FUNCTION

#---------------------

############################################################
# FUNCTION rpt_set_ref1_num(p_rpt_ref1_num)
#
############################################################
FUNCTION rpt_set_ref1_num(p_rpt_ref1_num)
	DEFINE p_rpt_ref1_num LIKE rmsreps.ref1_num  

	LET glob_rec_rpt_settings.rpt_ref1_num = p_rpt_ref1_num #MASTER

	LET glob_rec_rmsreps.dest_print_text = glob_rec_rpt_settings.rpt_ref1_num
END FUNCTION

############################################################
# FUNCTION rpt_get_ref1_num()
#
#	RETURN glob_rec_rpt_settings.rpt_ref1_num
############################################################
FUNCTION rpt_get_ref1_num()
	RETURN glob_rec_rpt_settings.rpt_ref1_num
END FUNCTION

############################################################
# FUNCTION rpt_set_ref2_num(p_rpt_ref2_num)
#
############################################################
FUNCTION rpt_set_ref2_num(p_rpt_ref2_num)
	DEFINE p_rpt_ref2_num LIKE rmsreps.ref2_num  

	LET glob_rec_rpt_settings.rpt_ref2_num = p_rpt_ref2_num #MASTER

	LET glob_rec_rmsreps.dest_print_text = glob_rec_rpt_settings.rpt_ref2_num
END FUNCTION

############################################################
# FUNCTION rpt_get_ref2_num()
#
#	RETURN glob_rec_rpt_settings.rpt_ref2_num
############################################################
FUNCTION rpt_get_ref2_num()
	RETURN glob_rec_rpt_settings.rpt_ref2_num
END FUNCTION

############################################################
# FUNCTION rpt_set_ref3_num(p_rpt_ref3_num)
#
############################################################
FUNCTION rpt_set_ref3_num(p_rpt_ref3_num)
	DEFINE p_rpt_ref3_num LIKE rmsreps.ref3_num  

	LET glob_rec_rpt_settings.rpt_ref3_num = p_rpt_ref3_num #MASTER

	LET glob_rec_rmsreps.dest_print_text = glob_rec_rpt_settings.rpt_ref3_num
END FUNCTION

############################################################
# FUNCTION rpt_get_ref3_num()
#
#	RETURN glob_rec_rpt_settings.rpt_ref3_num
############################################################
FUNCTION rpt_get_ref3_num()
	RETURN glob_rec_rpt_settings.rpt_ref3_num
END FUNCTION

############################################################
# FUNCTION rpt_set_ref4_num(p_rpt_ref4_num)
#
############################################################
FUNCTION rpt_set_ref4_num(p_rpt_ref4_num)
	DEFINE p_rpt_ref4_num LIKE rmsreps.ref4_num  

	LET glob_rec_rpt_settings.rpt_ref4_num = p_rpt_ref4_num #MASTER

	LET glob_rec_rmsreps.dest_print_text = glob_rec_rpt_settings.rpt_ref4_num
END FUNCTION

############################################################
# FUNCTION rpt_get_ref4_num()
#
#	RETURN glob_rec_rpt_settings.rpt_ref4_num
############################################################
FUNCTION rpt_get_ref4_num()
	RETURN glob_rec_rpt_settings.rpt_ref4_num
END FUNCTION

#----------------------------------------------------------------
############################################################
# FUNCTION rpt_set_printnow_flag(p_rpt_printnow_flag)
#
############################################################
FUNCTION rpt_set_printnow_flag(p_rpt_printnow_flag)
	DEFINE p_rpt_printnow_flag LIKE rmsreps.printnow_flag  

	LET glob_rec_rpt_settings.rpt_printnow_flag = p_rpt_printnow_flag #MASTER

	LET glob_rec_rmsreps.dest_print_text = glob_rec_rpt_settings.rpt_printnow_flag
END FUNCTION

############################################################
# FUNCTION rpt_get_printnow_flag()
#
#	RETURN glob_rec_rpt_settings.rpt_printnow_flag
############################################################
FUNCTION rpt_get_printnow_flag()
	RETURN glob_rec_rpt_settings.rpt_printnow_flag
END FUNCTION



############################################################
# FUNCTION rpt_set_comp_ind(p_rpt_comp_ind)
#
############################################################
FUNCTION rpt_set_comp_ind(p_rpt_comp_ind)
	DEFINE p_rpt_comp_ind LIKE rmsreps.comp_ind  

	LET glob_rec_rpt_settings.rpt_comp_ind = p_rpt_comp_ind #MASTER

	LET glob_rec_rmsreps.dest_print_text = glob_rec_rpt_settings.rpt_comp_ind
END FUNCTION

############################################################
# FUNCTION rpt_get_comp_ind()
#
#	RETURN glob_rec_rpt_settings.rpt_comp_ind
############################################################
FUNCTION rpt_get_comp_ind()
	RETURN glob_rec_rpt_settings.rpt_comp_ind
END FUNCTION


#-------------------------------------


############################################################
# FUNCTION rpt_set_print_page(p_rpt_print_page)
#
############################################################
FUNCTION rpt_set_print_page(p_rpt_print_page)
	DEFINE p_rpt_print_page LIKE rmsreps.print_page  

	LET glob_rec_rpt_settings.rpt_print_page = p_rpt_print_page #MASTER

	LET glob_rec_rmsreps.dest_print_text = glob_rec_rpt_settings.rpt_print_page
END FUNCTION

############################################################
# FUNCTION rpt_get_print_page()
#
#	RETURN glob_rec_rpt_settings.rpt_print_page
############################################################
FUNCTION rpt_get_print_page()
	RETURN glob_rec_rpt_settings.rpt_print_page
END FUNCTION



############################################################
# FUNCTION rpt_set_ref1_text(p_rpt_ref1_text)
#
############################################################
FUNCTION rpt_set_ref1_text(p_rpt_ref1_text)
	DEFINE p_rpt_ref1_text LIKE rmsreps.ref1_text  

	LET glob_rec_rpt_settings.rpt_ref1_text = p_rpt_ref1_text #MASTER

	LET glob_rec_rmsreps.dest_print_text = glob_rec_rpt_settings.rpt_ref1_text
END FUNCTION

############################################################
# FUNCTION rpt_get_ref1_text()
#
#	RETURN glob_rec_rpt_settings.rpt_ref1_text
############################################################
FUNCTION rpt_get_ref1_text()
	RETURN glob_rec_rpt_settings.rpt_ref1_text
END FUNCTION



############################################################
# FUNCTION rpt_set_rpt_sub_dest(p_rpt_sub_dest)
#
############################################################
FUNCTION rpt_set_rpt_sub_dest(p_rpt_sub_dest)
	DEFINE p_rpt_sub_dest LIKE rmsreps.sub_dest  

	LET glob_rec_rpt_settings.rpt_sub_dest = p_rpt_sub_dest #MASTER

	LET glob_rec_rmsreps.dest_print_text = glob_rec_rpt_settings.rpt_sub_dest
END FUNCTION

############################################################
# FUNCTION rpt_get_rpt_sub_dest()
#
#	RETURN glob_rec_rpt_settings.rpt_sub_dest
############################################################
FUNCTION rpt_get_rpt_sub_dest()
	RETURN glob_rec_rpt_settings.rpt_sub_dest
END FUNCTION



############################################################
# FUNCTION rpt_set_printonce_flag(p_rpt_printonce_flag)
#
############################################################
FUNCTION rpt_set_printonce_flag(p_rpt_printonce_flag)
	DEFINE p_rpt_printonce_flag LIKE rmsreps.printonce_flag  

	LET glob_rec_rpt_settings.rpt_printonce_flag = p_rpt_printonce_flag #MASTER

	LET glob_rec_rmsreps.dest_print_text = glob_rec_rpt_settings.rpt_printonce_flag
END FUNCTION

############################################################
# FUNCTION rpt_get_printonce_flag()
#
#	RETURN glob_rec_rpt_settings.rpt_printonce_flag
############################################################
FUNCTION rpt_get_printonce_flag()
	RETURN glob_rec_rpt_settings.rpt_printonce_flag
END FUNCTION

#-------------------------------------------------------------------------------------
FUNCTION rpt_get_rmsreps_rec()
	DEFINE l_rec_rmsreps RECORD LIKE rmsreps.*

    LET l_rec_rmsreps.cmpy_code = glob_rec_rpt_settings.rpt_cmpy_code #nchar(2)
    LET l_rec_rmsreps.report_code = glob_rec_rpt_settings.rpt_report_code #INT
    LET l_rec_rmsreps.report_text = glob_rec_rpt_settings.rpt_title1 #nvarchar(60)
    LET l_rec_rmsreps.status_text = glob_rec_rpt_settings.rpt_status_text  #nvarchar(13)
    LET l_rec_rmsreps.entry_code = glob_rec_rpt_settings.rpt_entry_code # nchar(8),
    LET l_rec_rmsreps.security_ind = glob_rec_rpt_settings.rpt_security_ind # nchar(1),
    LET l_rec_rmsreps.report_date = glob_rec_rmsreps.report_date # date,
    LET l_rec_rmsreps.report_pgm_text = glob_rec_rpt_settings.rpt_pgm_text # nvarchar(10),
    LET l_rec_rmsreps.report_time = glob_rec_rpt_settings.rpt_time #  nchar(8),
    LET l_rec_rmsreps.report_width_num = glob_rec_rpt_settings.rpt_width #  smallint,
    LET l_rec_rmsreps.page_length_num = glob_rec_rmsreps.page_length_num #  smallint,
    LET l_rec_rmsreps.page_num = glob_rec_rpt_settings.rpt_pageno #  integer,
    LET l_rec_rmsreps.dest_print_text = glob_rec_rpt_settings.rpt_dest_printer #  nvarchar(20),

    LET l_rec_rmsreps.status_ind = glob_rec_rpt_settings.rpt_status_ind #nchar(1),
    LET l_rec_rmsreps.exec_ind = glob_rec_rpt_settings.rpt_exec_ind #nchar(1),
    LET l_rec_rmsreps.sel_text = glob_rec_rpt_settings.rpt_sel_text #nchar(2000),
    LET l_rec_rmsreps.sel_flag = glob_rec_rpt_settings.rpt_sel_flag #nchar(1),
    LET l_rec_rmsreps.file_text = glob_rec_rpt_settings.rpt_file_name #nchar(20),

    LET l_rec_rmsreps.ref1_code = glob_rec_rpt_settings.rpt_ref1_code #  nchar(10),
    LET l_rec_rmsreps.ref2_code = glob_rec_rpt_settings.rpt_ref2_code #  nchar(10),
    LET l_rec_rmsreps.ref3_code = glob_rec_rpt_settings.rpt_ref3_code #  nchar(10),
    LET l_rec_rmsreps.ref4_code = glob_rec_rpt_settings.rpt_ref4_code #  nchar(10),
    LET l_rec_rmsreps.ref1_date = glob_rec_rpt_settings.rpt_ref1_date #  date,
    LET l_rec_rmsreps.ref2_date = glob_rec_rpt_settings.rpt_ref2_date #  date,
    LET l_rec_rmsreps.ref3_date = glob_rec_rpt_settings.rpt_ref3_date #  date,
    LET l_rec_rmsreps.ref4_date = glob_rec_rpt_settings.rpt_ref4_date #  date,
    LET l_rec_rmsreps.ref1_ind  = glob_rec_rpt_settings.rpt_ref1_ind # nchar(1),
    LET l_rec_rmsreps.ref2_ind  = glob_rec_rpt_settings.rpt_ref2_ind # nchar(1),
    LET l_rec_rmsreps.ref3_ind  = glob_rec_rpt_settings.rpt_ref3_ind # nchar(1),
    LET l_rec_rmsreps.ref4_ind  = glob_rec_rpt_settings.rpt_ref4_ind # nchar(1),

    LET l_rec_rmsreps.ref1_num  = glob_rec_rpt_settings.rpt_ref1_num # integer,
    LET l_rec_rmsreps.ref2_num  = glob_rec_rpt_settings.rpt_ref2_num # integer,
    LET l_rec_rmsreps.ref3_num  = glob_rec_rpt_settings.rpt_ref3_num # integer,
    LET l_rec_rmsreps.ref4_num  = glob_rec_rpt_settings.rpt_ref4_num # integer,

    LET l_rec_rmsreps.printnow_flag  = glob_rec_rpt_settings.rpt_printnow_flag #nchar(1),
    LET l_rec_rmsreps.copy_num  = glob_rec_rpt_settings.rpt_copy_num #smallint,
    LET l_rec_rmsreps.comp_ind  = glob_rec_rpt_settings.rpt_comp_ind #nchar(1),
}            
{
 = glob_rec_rpt_settings.rpt_xxxxxxxxxxxxxxx # 






    LET l_rec_rmsreps.start_page smallint,
    LET l_rec_rmsreps.print_page smallint,
    LET l_rec_rmsreps.align_ind nchar(1),

    LET l_rec_rmsreps.ref1_text nvarchar(100),
    LET l_rec_rmsreps.sub_dest nvarchar(40),
    LET l_rec_rmsreps.printonce_flag nchar(1)
}
{
	RETURN l_rec_rmsreps.*
END FUNCTION
}





#Temporary.. will be moved to DB later - this is, why we use accessor & constants
#	CONSTANT rpt_width_a3_p SMALLINT = 132
#	CONSTANT rpt_width_a3_l SMALLINT = 188
#	CONSTANT rpt_width_a4_p SMALLINT = 80
#	CONSTANT rpt_width_a4_l SMALLINT = 132
#	CONSTANT rpt_width_a5_p SMALLINT = 40
#	CONSTANT rpt_width_a5_l SMALLINT = 66
#	CONSTANT rpt_width_a6_p SMALLINT = 20
#	CONSTANT rpt_width_a6_l SMALLINT = 33
#	CONSTANT rpt_width_label1_p SMALLINT = 15
#	CONSTANT rpt_width_label1_l SMALLINT = 30
#	CONSTANT rpt_width_label2_p SMALLINT = 10
#	CONSTANT rpt_width_label2_l SMALLINT = 20
	
{	
FUNCTION rpt_paper_get_char_size(p_paper_size)
	DEFINE p_paper_size STRING
	DEFINE l_tmp_msg STRING
		
	CASE p_paper_size
	WHEN "rpt_width_a3_p" #SMALLINT = 132
		RETURN rpt_width_a3_p
	WHEN "rpt_width_a3_l" #SMALLINT = 188
		RETURN rpt_width_a3_l
	WHEN "rpt_width_a4_p" #SMALLINT = 80
		RETURN rpt_width_a4_p
	WHEN "rpt_width_a4_l" #SMALLINT = 132
		RETURN rpt_width_a4_l
	WHEN "rpt_width_a5_p" #SMALLINT = 40
		RETURN rpt_width_a5_p
	WHEN "rpt_width_a5_l" #SMALLINT = 66
		RETURN rpt_width_a5_l
	WHEN "rpt_width_a6_p" #SMALLINT = 20
		RETURN rpt_width_a6_p
	WHEN "rpt_width_a6_l" #SMALLINT = 33
		RETURN rpt_width_a6_l
	WHEN "rpt_width_label1_p" #SMALLINT = 15
		RETURN rpt_width_label1_p
	WHEN "rpt_width_label1_l" #SMALLINT = 30
		RETURN rpt_width_label1_l
	WHEN "rpt_width_label2_p" #SMALLINT = 10
		RETURN rpt_width_label2_p
	WHEN "rpt_width_label2_l" #SMALLINT = 20
		RETURN rpt_width_label2_l
	OTHERWISE
		LET l_tmp_msg = "Invalid argument specified for paper size: ", trim(p_paper_size), "\nin function rpt_paper_get_char_size(p_paper_size)" 
		CALL fgl_winmessage("Error in rpt_paper_get_char_size(p_paper_size)",l_tmp_msg,"error")
	END CASE

	END FUNCTION
}	
	{
#-------------------------------------------------------------------
# Accessor for print report config dialog
FUNCTION rpt_get_rec_print_report_dialog()
	DEFINE l_rec_rpt_print_dialog RECORD OF t_rec_print_report_dialog
	
	LET l_rec_rpt_print_dialog.rpt_report_text = glob_rec_rpt_settings.rpt_report_text #  LIKE rmsreps.report_text, 
	LET l_rec_rpt_print_dialog.rpt_exec_ind = glob_rec_rpt_settings.rpt_exec_ind #  LIKE rmsreps.exec_ind, 
	LET l_rec_rpt_print_dialog.rpt_report_date = glob_rec_rpt_settings.rpt_report_date #  LIKE rmsreps.report_date, 
	LET l_rec_rpt_print_dialog.rpt_report_time = glob_rec_rpt_settings.XXXXXXXXXXXXXXXX #  LIKE rmsreps.report_time, 
	LET l_rec_rpt_print_dialog.rpt_sel_flag = glob_rec_rpt_settings.XXXXXXXXXXXXXXXX #  LIKE rmsreps.sel_flag, 
	LET l_rec_rpt_print_dialog.rpt_printnow_flag = glob_rec_rpt_settings.XXXXXXXXXXXXXXXX #  LIKE rmsreps.printnow_flag, 
	LET l_rec_rpt_print_dialog.rpt_dest_print_text = glob_rec_rpt_settings.XXXXXXXXXXXXXXXX #  LIKE rmsreps.dest_print_text, 
	LET l_rec_rpt_print_dialog.rpt_report_code = glob_rec_rpt_settings.XXXXXXXXXXXXXXXX #  LIKE kandooreport.l_report_code, 
	LET l_rec_rpt_print_dialog.rpt_date = glob_rec_rpt_settings.XXXXXXXXXXXXXXXX #  LIKE kandooreport.l_report_date, 
	LET l_rec_rpt_print_dialog.rpt_time = glob_rec_rpt_settings.XXXXXXXXXXXXXXXX #  LIKE kandooreport.l_report_time, 
	LET l_rec_rpt_print_dialog.rpt_entry_code = glob_rec_rpt_settings.XXXXXXXXXXXXXXXX #  LIKE kandooreport.l_entry_code, 
	LET l_rec_rpt_print_dialog.rpt_pgm_text = glob_rec_rpt_settings.XXXXXXXXXXXXXXXX #  LIKE rmsreps.report_pgm_text, 
	LET l_rec_rpt_print_dialog.rpt_exec_flag = glob_rec_rpt_settings.XXXXXXXXXXXXXXXX #  LIKE kandooreport.exec_flag, 
	LET l_rec_rpt_print_dialog.rpt_width = glob_rec_rpt_settings.XXXXXXXXXXXXXXXX #  LIKE rmsreps.report_width_num, 
	LET l_rec_rpt_print_dialog.rpt_length = glob_rec_rpt_settings.XXXXXXXXXXXXXXXX #  LIKE rmsreps.page_length_num
 	
	RETURN l_rec_rpt_print_dialog.*  
END FUNCTION
}