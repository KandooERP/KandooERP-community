############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl" 

{
############################################################
# FUNCTION rpt_kandooreport_set_report_code(p_report_code)
#
#	
############################################################
FUNCTION rpt_kandooreport_set_report_code(p_report_code)
	DEFINE p_report_code LIKE kandooreport.report_code 

	LET glob_rec_kandooreport.report_code = p_report_code
	
END FUNCTION

############################################################
# FUNCTION rpt_kandooreport_get_report_code()
#
# RETURN glob_rec_rpt_kandooreport_settings.rpt_kandooreport_note
############################################################
FUNCTION rpt_kandooreport_get_report_code()
	RETURN glob_rec_kandooreport.report_code
END FUNCTION

############################################################
# FUNCTION rpt_kandooreport_set_language_code(p_language_code)
#
#	
############################################################
FUNCTION rpt_kandooreport_set_language_code(p_language_code)
	DEFINE p_language_code LIKE kandooreport.language_code 

	LET glob_rec_kandooreport.language_code = p_language_code
	
END FUNCTION

############################################################
# FUNCTION rpt_kandooreport_get_language_code()
#
# RETURN glob_rec_rpt_kandooreport_settings.rpt_kandooreport_note
############################################################
FUNCTION rpt_kandooreport_get_language_code()
	RETURN glob_rec_kandooreport.language_code
END FUNCTION


############################################################
# FUNCTION rpt_kandooreport_set_header_text(p_header_text)
#
#	
############################################################
FUNCTION rpt_kandooreport_set_header_text(p_header_text)
	DEFINE p_header_text LIKE kandooreport.header_text 

	LET glob_rec_kandooreport.header_text = p_header_text
	
END FUNCTION

############################################################
# FUNCTION rpt_kandooreport_get_header_text()
#
# RETURN glob_rec_rpt_kandooreport_settings.rpt_kandooreport_note
############################################################
FUNCTION rpt_kandooreport_get_header_text()
	RETURN glob_rec_kandooreport.header_text
END FUNCTION



############################################################
# FUNCTION rpt_kandooreport_set_width_num(p_width_num)
#
#	
############################################################
FUNCTION rpt_kandooreport_set_width_num(p_width_num)
	DEFINE p_width_num LIKE kandooreport.width_num 

	LET glob_rec_kandooreport.width_num = p_width_num
	
END FUNCTION

############################################################
# FUNCTION rpt_kandooreport_get_width_num()
#
# RETURN glob_rec_rpt_kandooreport_settings.rpt_kandooreport_note
############################################################
FUNCTION rpt_kandooreport_get_width_num()
	RETURN glob_rec_kandooreport.width_num
END FUNCTION


############################################################
# FUNCTION rpt_kandooreport_set_menupath_text(p_menupath_text)
#
#	
############################################################
FUNCTION rpt_kandooreport_set_menupath_text(p_menupath_text)
	DEFINE p_menupath_text LIKE kandooreport.menupath_text 

	LET glob_rec_kandooreport.menupath_text = p_menupath_text
	
END FUNCTION

############################################################
# FUNCTION rpt_kandooreport_get_menupath_text()
#
# RETURN glob_rec_rpt_kandooreport_settings.rpt_kandooreport_note
############################################################
FUNCTION rpt_kandooreport_get_menupath_text()
	RETURN glob_rec_kandooreport.menupath_text
END FUNCTION


############################################################
# FUNCTION rpt_kandooreport_set_selection_flag(p_selection_flag)
#
#	
############################################################
FUNCTION rpt_kandooreport_set_selection_flag(p_selection_flag)
	DEFINE p_selection_flag LIKE kandooreport.selection_flag 

	LET glob_rec_kandooreport.selection_flag = p_selection_flag
	
END FUNCTION

############################################################
# FUNCTION rpt_kandooreport_get_selection_flag()
#
# RETURN glob_rec_rpt_kandooreport_settings.rpt_kandooreport_note
############################################################
FUNCTION rpt_kandooreport_get_selection_flag()
	RETURN glob_rec_kandooreport.selection_flag
END FUNCTION


############################################################
# FUNCTION rpt_kandooreport_set_line1_text(p_line1_text)
#
#	
############################################################
FUNCTION rpt_kandooreport_set_line1_text(p_line1_text)
	DEFINE p_line1_text LIKE kandooreport.line1_text 

	LET glob_rec_kandooreport.line1_text = p_line1_text
	
END FUNCTION

############################################################
# FUNCTION rpt_kandooreport_get_line1_text()
#
# RETURN glob_rec_rpt_kandooreport_settings.rpt_kandooreport_note
############################################################
FUNCTION rpt_kandooreport_get_line1_text()
	RETURN glob_rec_kandooreport.line1_text
END FUNCTION


############################################################
# FUNCTION rpt_kandooreport_set_line2_text(p_line2_text)
#
#	
############################################################
FUNCTION rpt_kandooreport_set_line2_text(p_line2_text)
	DEFINE p_line2_text LIKE kandooreport.line2_text 

	LET glob_rec_kandooreport.line2_text = p_line2_text
	
END FUNCTION

############################################################
# FUNCTION rpt_kandooreport_get_line2_text()
#
# RETURN glob_rec_rpt_kandooreport_settings.rpt_kandooreport_note
############################################################
FUNCTION rpt_kandooreport_get_line2_text()
	RETURN glob_rec_kandooreport.line2_text
END FUNCTION


############################################################
# FUNCTION rpt_kandooreport_set_line3_text(p_line3_text)
#
#	
############################################################
FUNCTION rpt_kandooreport_set_line3_text(p_line3_text)
	DEFINE p_line3_text LIKE kandooreport.line3_text 

	LET glob_rec_kandooreport.line3_text = p_line3_text
	
END FUNCTION

############################################################
# FUNCTION rpt_kandooreport_get_line3_text()
#
# RETURN glob_rec_rpt_kandooreport_settings.rpt_kandooreport_note
############################################################
FUNCTION rpt_kandooreport_get_line3_text()
	RETURN glob_rec_kandooreport.line3_text
END FUNCTION


############################################################
# FUNCTION rpt_kandooreport_set_line4_text(p_line4_text)
#
#	
############################################################
FUNCTION rpt_kandooreport_set_line4_text(p_line4_text)
	DEFINE p_line4_text LIKE kandooreport.line4_text 

	LET glob_rec_kandooreport.line4_text = p_line4_text
	
END FUNCTION

############################################################
# FUNCTION rpt_kandooreport_get_line4_text()
#
# RETURN glob_rec_rpt_kandooreport_settings.rpt_kandooreport_note
############################################################
FUNCTION rpt_kandooreport_get_line4_text()
	RETURN glob_rec_kandooreport.line4_text
END FUNCTION


############################################################
# FUNCTION rpt_kandooreport_set_line5_text(p_line5_text)
#
#	
############################################################
FUNCTION rpt_kandooreport_set_line5_text(p_line5_text)
	DEFINE p_line5_text LIKE kandooreport.line5_text 

	LET glob_rec_kandooreport.line5_text = p_line5_text
	
END FUNCTION

############################################################
# FUNCTION rpt_kandooreport_get_line5_text()
#
# RETURN glob_rec_rpt_kandooreport_settings.rpt_kandooreport_note
############################################################
FUNCTION rpt_kandooreport_get_line5_text()
	RETURN glob_rec_kandooreport.line5_text
END FUNCTION


############################################################
# FUNCTION rpt_kandooreport_set_line6_text(p_line6_text)
#
#	
############################################################
FUNCTION rpt_kandooreport_set_line6_text(p_line6_text)
	DEFINE p_line6_text LIKE kandooreport.line6_text 

	LET glob_rec_kandooreport.line6_text = p_line6_text
	
END FUNCTION

############################################################
# FUNCTION rpt_kandooreport_get_line6_text()
#
# RETURN glob_rec_rpt_kandooreport_settings.rpt_kandooreport_note
############################################################
FUNCTION rpt_kandooreport_get_line6_text()
	RETURN glob_rec_kandooreport.line6_text
END FUNCTION


############################################################
# FUNCTION rpt_kandooreport_set_line7_text(p_line7_text)
#
#	
############################################################
FUNCTION rpt_kandooreport_set_line7_text(p_line7_text)
	DEFINE p_line7_text LIKE kandooreport.line7_text 

	LET glob_rec_kandooreport.line7_text = p_line7_text
	
END FUNCTION

############################################################
# FUNCTION rpt_kandooreport_get_line7_text()
#
# RETURN glob_rec_rpt_kandooreport_settings.rpt_kandooreport_note
############################################################
FUNCTION rpt_kandooreport_get_line7_text()
	RETURN glob_rec_kandooreport.line7_text
END FUNCTION


############################################################
# FUNCTION rpt_kandooreport_set_line8_text(p_line8_text)
#
#	
############################################################
FUNCTION rpt_kandooreport_set_line8_text(p_line8_text)
	DEFINE p_line8_text LIKE kandooreport.line8_text 

	LET glob_rec_kandooreport.line8_text = p_line8_text
	
END FUNCTION

############################################################
# FUNCTION rpt_kandooreport_get_line8_text()
#
# RETURN glob_rec_rpt_kandooreport_settings.rpt_kandooreport_note
############################################################
FUNCTION rpt_kandooreport_get_line8_text()
	RETURN glob_rec_kandooreport.line8_text
END FUNCTION


############################################################
# FUNCTION rpt_kandooreport_set_line9_text(p_line9_text)
#
#	
############################################################
FUNCTION rpt_kandooreport_set_line9_text(p_line9_text)
	DEFINE p_line9_text LIKE kandooreport.line9_text 

	LET glob_rec_kandooreport.line9_text = p_line9_text
	
END FUNCTION

############################################################
# FUNCTION rpt_kandooreport_get_line9_text()
#
# RETURN glob_rec_rpt_kandooreport_settings.rpt_kandooreport_note
############################################################
FUNCTION rpt_kandooreport_get_line9_text()
	RETURN glob_rec_kandooreport.line9_text
END FUNCTION


############################################################
# FUNCTION rpt_kandooreport_set_line0_text(p_line0_text)
#
#	
############################################################
FUNCTION rpt_kandooreport_set_line0_text(p_line0_text)
	DEFINE p_line0_text LIKE kandooreport.line0_text 

	LET glob_rec_kandooreport.line0_text = p_line0_text
	
END FUNCTION

############################################################
# FUNCTION rpt_kandooreport_get_line0_text()
#
# RETURN glob_rec_rpt_kandooreport_settings.rpt_kandooreport_note
############################################################
FUNCTION rpt_kandooreport_get_line0_text()
	RETURN glob_rec_kandooreport.line0_text
END FUNCTION


############################################################
# FUNCTION rpt_kandooreport_set_exec_ind(p_exec_ind)
#
#	
############################################################
FUNCTION rpt_kandooreport_set_exec_ind(p_exec_ind)
	DEFINE p_exec_ind LIKE kandooreport.exec_ind 

	LET glob_rec_kandooreport.exec_ind = p_exec_ind
	
END FUNCTION

############################################################
# FUNCTION rpt_kandooreport_get_exec_ind()
#
# RETURN glob_rec_rpt_kandooreport_settings.rpt_kandooreport_note
############################################################
FUNCTION rpt_kandooreport_get_exec_ind()
	RETURN glob_rec_kandooreport.exec_ind
END FUNCTION


############################################################
# FUNCTION rpt_kandooreport_set_exec_flag(p_exec_flag)
#
#	
############################################################
FUNCTION rpt_kandooreport_set_exec_flag(p_exec_flag)
	DEFINE p_exec_flag LIKE kandooreport.exec_flag 

	LET glob_rec_kandooreport.exec_flag = p_exec_flag
	
END FUNCTION

############################################################
# FUNCTION rpt_kandooreport_get_exec_flag()
#
# RETURN glob_rec_rpt_kandooreport_settings.rpt_kandooreport_note
############################################################
FUNCTION rpt_kandooreport_get_exec_flag()
	RETURN glob_rec_kandooreport.exec_flag
END FUNCTION


############################################################
# FUNCTION rpt_kandooreport_set_l_report_code(p_l_report_code)
#
#	
############################################################
FUNCTION rpt_kandooreport_set_l_report_code(p_l_report_code)
	DEFINE p_l_report_code LIKE kandooreport.l_report_code 

	LET glob_rec_kandooreport.l_report_code = p_l_report_code
	
END FUNCTION

############################################################
# FUNCTION rpt_kandooreport_get_l_report_code()
#
# RETURN glob_rec_rpt_kandooreport_settings.rpt_kandooreport_note
############################################################
FUNCTION rpt_kandooreport_get_l_report_code()
	RETURN glob_rec_kandooreport.l_report_code
END FUNCTION

############################################################
# FUNCTION rpt_kandooreport_set_l_report_date(p_l_report_date)
#
#	
############################################################
FUNCTION rpt_kandooreport_set_l_report_date(p_l_report_date)
	DEFINE p_l_report_date LIKE kandooreport.l_report_date 

	LET glob_rec_kandooreport.l_report_date = p_l_report_date
	
END FUNCTION

############################################################
# FUNCTION rpt_kandooreport_get_l_report_date()
#
# RETURN glob_rec_rpt_kandooreport_settings.rpt_kandooreport_note
############################################################
FUNCTION rpt_kandooreport_get_l_report_date()
	RETURN glob_rec_kandooreport.l_report_date
END FUNCTION

############################################################
# FUNCTION rpt_kandooreport_set_l_report_time(p_l_report_time)
#
#	
############################################################
FUNCTION rpt_kandooreport_set_l_report_time(p_l_report_time)
	DEFINE p_l_report_time LIKE kandooreport.l_report_time 

	LET glob_rec_kandooreport.l_report_time = p_l_report_time
	
END FUNCTION

############################################################
# FUNCTION rpt_kandooreport_get_l_report_time()
#
# RETURN glob_rec_rpt_kandooreport_settings.rpt_kandooreport_note
############################################################
FUNCTION rpt_kandooreport_get_l_report_time()
	RETURN glob_rec_kandooreport.l_report_time
END FUNCTION

############################################################
# FUNCTION rpt_kandooreport_set_l_entry_code(p_l_entry_code)
#
#	
############################################################
FUNCTION rpt_kandooreport_set_l_entry_code(p_l_entry_code)
	DEFINE p_l_entry_code LIKE kandooreport.l_entry_code 

	LET glob_rec_kandooreport.l_entry_code = p_l_entry_code
	
END FUNCTION

############################################################
# FUNCTION rpt_kandooreport_get_l_entry_code()
#
# RETURN glob_rec_rpt_kandooreport_settings.rpt_kandooreport_note
############################################################
FUNCTION rpt_kandooreport_get_l_entry_code()
	RETURN glob_rec_kandooreport.l_entry_code
END FUNCTION
}