############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_DATABASE.4gl"

#Report
DEFINE modu_report_file_text LIKE rmsreps.file_text
DEFINE modu_report_code LIKE rmsreps.report_code #INT
DEFINE modu_report_id LIKE rpthead.rpt_id 
DEFINE modu_report_date DATE 
DEFINE modu_exec_ind LIKE kandooreport.exec_ind #??? not sure, something with reporting 
DEFINE modu_printnow_flag LIKE rmsreps.printnow_flag
DEFINE modu_print_text LIKE kandoouser.print_text

###########################################################################
# FUNCTION set_url_report_code(p_report_code)
#
# Accessor Method for URL modu_report_code
###########################################################################
FUNCTION set_url_report_code(p_report_code) 
	DEFINE p_report_code LIKE rmsreps.report_code 
	LET modu_report_code = p_report_code 
END FUNCTION 

###########################################################################
# FUNCTION get_url_report_code()
#
# Accessor Method for URL modu_report_code
###########################################################################
FUNCTION get_url_report_code() 
	RETURN modu_report_code 
END FUNCTION 

--------------------------------------------------------

###########################################################################
# FUNCTION set_url_report_file_text(p_report_file_text)
#
# Accessor Method for URL modu_report_file_text
###########################################################################
FUNCTION set_url_report_file_text(p_report_file_text) 
	DEFINE p_report_file_text LIKE rmsreps.file_text
	LET modu_report_file_text = p_report_file_text 
END FUNCTION 
###########################################################################
# FUNCTION get_url_report_file_text()
#
# Accessor Method for URL modu_report_file_text
###########################################################################
FUNCTION get_url_report_file_text() 
	RETURN modu_report_file_text 
END FUNCTION 


--------------------------------------------------------

###########################################################################
# FUNCTION set_url_printnow(p_printnow)
#
# Accessor Method for URL modu_printnow
###########################################################################
FUNCTION set_url_printnow(p_printnow) 
	DEFINE p_printnow LIKE rmsreps.printnow_flag
	
	IF p_printnow matches "[YN]" THEN
		LET modu_printnow_flag = p_printnow
	ELSE
		LET modu_printnow_flag = "Y" #default
	END IF 
END FUNCTION 
###########################################################################
# FUNCTION get_url_printnow()
#
# Accessor Method for URL modu_printnow
###########################################################################
FUNCTION get_url_printnow() 
	IF modu_printnow_flag = " " OR modu_printnow_flag IS NULL THEN
		LET modu_printnow_flag = "Y" #default
	END IF
	RETURN modu_printnow_flag 
END FUNCTION 

--------------------------------------------------------

###########################################################################
# FUNCTION set_url_printconfig(p_print_text)
#
# Accessor Method for URL modu_printconfig
###########################################################################
FUNCTION set_url_printconfig(p_print_text) 
	DEFINE p_print_text LIKE rmsreps.dest_print_text

	LET modu_print_text = p_print_text

END FUNCTION 
###########################################################################
# FUNCTION get_url_printconfig()
#
# Accessor Method for URL modu_printconfig
###########################################################################
FUNCTION get_url_printconfig() 
	RETURN modu_print_text 
END FUNCTION 

--------------------------------------------------------

###########################################################################
# FUNCTION set_url_report_date(p_report_date)
#
# Accessor Method for URL modu_report_date
###########################################################################
FUNCTION set_url_report_date(p_report_date) 
	DEFINE p_report_date DATE 
	LET modu_report_date = p_report_date 
END FUNCTION 

###########################################################################
# FUNCTION get_url_report_date()
#
# Accessor Method for URL modu_report_date
###########################################################################
FUNCTION get_url_report_date() 
	RETURN modu_report_date 
END FUNCTION 

--------------------------------------------------------

###########################################################################
# FUNCTION set_url_report_id(p_report_id)
#
# Accessor Method for URL modu_report_id
###########################################################################
FUNCTION set_url_report_id(p_report_id) 
	DEFINE p_report_id LIKE rpthead.rpt_id #nchar(10) 
	LET modu_report_id = p_report_id 
END FUNCTION 

###########################################################################
# FUNCTION get_url_report_id()
#
# Accessor Method for URL modu_report_id
###########################################################################
FUNCTION get_url_report_id() 
	RETURN modu_report_id 
END FUNCTION 

--------------------------------------------------------



###########################################################################
# FUNCTION get_url_exec_ind()
#
# Accessor Method for URL modu_file_name
###########################################################################
FUNCTION get_url_exec_ind() 
	RETURN modu_exec_ind 
END FUNCTION 


###########################################################################
# FUNCTION set_url_exec_ind(p_modu_exec_ind)
#
# Accessor Method for URL modu_file_name
###########################################################################
FUNCTION set_url_exec_ind(p_modu_exec_ind) 
	DEFINE p_modu_exec_ind LIKE kandooreport.exec_ind 
	#we need to add validations after we know, what file_name symbols are used/required
	#so far, I have seen "D" and "S"
	LET modu_exec_ind = p_modu_exec_ind 
END FUNCTION 

