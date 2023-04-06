############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl" 
############################################################
# MODULE Scope Variables
############################################################
--DEFINE modu_rec_rpt_settings OF t_rec_report_settings
############################################################
# FYIO - Ongoing cleanup -> move report settings to lib_report library
# NOTE: Original Kandoo defines report settings on different kinds of scopes etc.. 
# Target is, to use these settings on one location only 
############################################################
{
############################################################
# FUNCTION rpt_rmsreps_get_rec()
#
# RETURN glob_rec_rmsreps.*
############################################################
FUNCTION rpt_rmsreps_get_rec()
	RETURN glob_rec_rmsreps.*
END FUNCTION


############################################################
# FUNCTION rpt_rmsreps_set_cmpy_code(p_rpt_rmsreps_cmpy_code)
#
############################################################
FUNCTION rpt_rmsreps_set_cmpy_code(p_rpt_rmsreps_cmpy_code)
	DEFINE p_rpt_rmsreps_cmpy_code LIKE rmsreps.cmpy_code  

	LET glob_rec_rmsreps.cmpy_code = p_rpt_rmsreps_cmpy_code
END FUNCTION

############################################################
# FUNCTION rpt_rmsreps_get_cmpy_code()
#
#	RETURN glob_rec_rpt_rmsreps_settings.rpt_rmsreps_cmpy_code
############################################################
FUNCTION rpt_rmsreps_get_cmpy_code()
	RETURN glob_rec_rmsreps.cmpy_code
END FUNCTION

############################################################
# FUNCTION rpt_rmsreps_set_report_code(p_report_code)
#
#	RETURN glob_rec_rpt_rmsreps_settings.rpt_rmsreps_offset2
#
# DANGEROUS - Kandoo uses the var name report_code for different purpose and dataType 
# INT=PK char(10) and char(20).. some kind of report name
#
# Here, we are woring with rpt_rmsreps_report_code LIKE rmsreps.report_code, #INT 
# in DB table kandooreport -> glob_rec_kandooreport.l_report_code (because here, report_code is char(10)
############################################################	
FUNCTION rpt_rmsreps_set_report_code(p_report_code)
	DEFINE p_report_code LIKE rmsreps.report_code
	
		LET glob_rec_rmsreps.report_code = p_report_code
	
END FUNCTION

############################################################
# FUNCTION rpt_rmsreps_get_report_code()
#
# RETURN glob_rec_rpt_rmsreps_settings.rpt_rmsreps_report_code
############################################################
FUNCTION rpt_rmsreps_get_report_code()
	RETURN glob_rec_rmsreps.report_code
END FUNCTION


############################################################
# FUNCTION rpt_rmsreps_set_status_text(p_status_text)
#
#	
############################################################
FUNCTION rpt_rmsreps_set_status_text(p_status_text)
	DEFINE p_status_text LIKE rmsreps.status_text 

	LET glob_rec_rmsreps.status_text = p_status_text
	
END FUNCTION

############################################################
# FUNCTION rpt_rmsreps_get_status_text()
#
# RETURN glob_rec_rpt_rmsreps_settings.rpt_rmsreps_note
############################################################
FUNCTION rpt_rmsreps_get_status_text()
	RETURN glob_rec_rmsreps.status_text
END FUNCTION

############################################################
# FUNCTION rpt_rmsreps_set_entry_code(p_entry_code)
#
#	
############################################################
FUNCTION rpt_rmsreps_set_entry_code(p_entry_code)
	DEFINE p_entry_code LIKE rmsreps.entry_code 

	LET glob_rec_rmsreps.entry_code = p_entry_code
	
END FUNCTION

############################################################
# FUNCTION rpt_rmsreps_get_entry_code()
#
# RETURN glob_rec_rpt_rmsreps_settings.rpt_rmsreps_note
############################################################
FUNCTION rpt_rmsreps_get_entry_code()
	RETURN glob_rec_rmsreps.entry_code
END FUNCTION



############################################################
# FUNCTION rpt_rmsreps_set_security_ind(p_security_ind)
#
#	
############################################################
FUNCTION rpt_rmsreps_set_security_ind(p_security_ind)
	DEFINE p_security_ind LIKE rmsreps.security_ind 

	LET glob_rec_rmsreps.security_ind = p_security_ind
	
END FUNCTION

############################################################
# FUNCTION rpt_rmsreps_get_security_ind()
#
# RETURN glob_rec_rpt_rmsreps_settings.rpt_rmsreps_note
############################################################
FUNCTION rpt_rmsreps_get_security_ind()
	RETURN glob_rec_rmsreps.security_ind
END FUNCTION



############################################################
# FUNCTION rpt_rmsreps_set_report_date(p_report_date)
#
#	
############################################################
FUNCTION rpt_rmsreps_set_report_date(p_report_date)
	DEFINE p_report_date LIKE rmsreps.report_date 

	LET glob_rec_rmsreps.report_date = p_report_date
	
END FUNCTION

############################################################
# FUNCTION rpt_rmsreps_get_report_date()
#
# RETURN glob_rec_rpt_rmsreps_settings.rpt_rmsreps_note
############################################################
FUNCTION rpt_rmsreps_get_report_date()
	RETURN glob_rec_rmsreps.report_date
END FUNCTION


############################################################
# FUNCTION rpt_rmsreps_set_report_pgm_text(p_report_pgm_text)
#
#	
############################################################
FUNCTION rpt_rmsreps_set_report_pgm_text(p_report_pgm_text)
	DEFINE p_report_pgm_text LIKE rmsreps.report_pgm_text 

	LET glob_rec_rmsreps.report_pgm_text = p_report_pgm_text
	
END FUNCTION

############################################################
# FUNCTION rpt_rmsreps_get_report_pgm_text()
#
# RETURN glob_rec_rpt_rmsreps_settings.rpt_rmsreps_note
############################################################
FUNCTION rpt_rmsreps_get_report_pgm_text()
	RETURN glob_rec_rmsreps.report_pgm_text
END FUNCTION


############################################################
# FUNCTION rpt_rmsreps_set_report_time(p_report_time)
#
#	
############################################################
FUNCTION rpt_rmsreps_set_report_time(p_report_time)
	DEFINE p_report_time LIKE rmsreps.report_time 

	LET glob_rec_rmsreps.report_time = p_report_time
	
END FUNCTION

############################################################
# FUNCTION rpt_rmsreps_get_report_time()
#
# RETURN glob_rec_rpt_rmsreps_settings.rpt_rmsreps_note
############################################################
FUNCTION rpt_rmsreps_get_report_time()
	RETURN glob_rec_rmsreps.report_time
END FUNCTION

############################################################
# FUNCTION rpt_rmsreps_set_report_width_num(p_report_width_num)
#
#	
############################################################
FUNCTION rpt_rmsreps_set_report_width_num(p_report_width_num)
	DEFINE p_report_width_num LIKE rmsreps.report_width_num 

	LET glob_rec_rmsreps.report_width_num = p_report_width_num
	
END FUNCTION

############################################################
# FUNCTION rpt_rmsreps_get_report_width_num()
#
# RETURN glob_rec_rpt_rmsreps_settings.rpt_rmsreps_note
############################################################
FUNCTION rpt_rmsreps_get_report_width_num()
	RETURN glob_rec_rmsreps.report_width_num
END FUNCTION


############################################################
# FUNCTION rpt_rmsreps_set_page_length_num(p_page_length_num)
#
#	
############################################################
FUNCTION rpt_rmsreps_set_page_length_num(p_page_length_num)
	DEFINE p_page_length_num LIKE rmsreps.page_length_num 

	LET glob_rec_rmsreps.page_length_num = p_page_length_num
	
END FUNCTION

############################################################
# FUNCTION rpt_rmsreps_get_page_length_num()
#
# RETURN glob_rec_rpt_rmsreps_settings.rpt_rmsreps_note
############################################################
FUNCTION rpt_rmsreps_get_page_length_num()
	RETURN glob_rec_rmsreps.page_length_num
END FUNCTION


############################################################
# FUNCTION rpt_rmsreps_set_page_size(p_rpt_width,p_rpt_length)
#
############################################################
FUNCTION rpt_rmsreps_set_page_size(p_report_width_num,p_page_length_num)
	DEFINE p_report_width_num LIKE rmsreps.report_width_num
	DEFINE p_page_length_num LIKE rmsreps.page_length_num

	LET glob_rec_rmsreps.report_width_num = p_report_width_num
	LET glob_rec_rmsreps.page_length_num = p_page_length_num		

END FUNCTION



############################################################
# FUNCTION rpt_rmsreps_set_page_num(p_page_num)
#
#	
############################################################
FUNCTION rpt_rmsreps_set_page_num(p_page_num)
	DEFINE p_page_num LIKE rmsreps.page_num 

	LET glob_rec_rmsreps.page_num = p_page_num
	
END FUNCTION

############################################################
# FUNCTION rpt_rmsreps_get_page_num()
#
# RETURN glob_rec_rpt_rmsreps_settings.rpt_rmsreps_note
############################################################
FUNCTION rpt_rmsreps_get_page_num()
	RETURN glob_rec_rmsreps.page_num
END FUNCTION

############################################################
# FUNCTION rpt_rmsreps_set_page_num_increment()
#
#	
############################################################
FUNCTION rpt_rmsreps_set_page_num_increment()
	LET glob_rec_rmsreps.page_num = glob_rec_rmsreps.page_num + 1
END FUNCTION
}
############################################################
# FUNCTION rpt_rmsreps_set_dest_print_text(p_dest_print_text)
#
#	
############################################################
FUNCTION rpt_rmsreps_set_dest_print_text(p_rpt_idx,p_dest_print_text)
	DEFINE p_rpt_idx SMALLINT
	DEFINE p_dest_print_text LIKE rmsreps.dest_print_text 

	LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].dest_print_text = p_dest_print_text
	
END FUNCTION

############################################################
# FUNCTION rpt_rmsreps_get_dest_print_text()
#
# RETURN glob_rec_rpt_rmsreps_settings.rpt_rmsreps_note
############################################################
FUNCTION rpt_rmsreps_get_dest_print_text(p_rpt_idx)
	DEFINE p_rpt_idx SMALLINT
	
	RETURN glob_arr_rec_rpt_rmsreps[p_rpt_idx].dest_print_text
END FUNCTION

{
############################################################
# FUNCTION rpt_rmsreps_set_status_ind(p_status_ind)
#
#	
############################################################
FUNCTION rpt_rmsreps_set_status_ind(p_status_ind)
	DEFINE p_status_ind LIKE rmsreps.status_ind 

	LET glob_rec_rmsreps.status_ind = p_status_ind
	
END FUNCTION

############################################################
# FUNCTION rpt_rmsreps_get_status_ind()
#
# RETURN glob_rec_rpt_rmsreps_settings.rpt_rmsreps_note
############################################################
FUNCTION rpt_rmsreps_get_status_ind()
	RETURN glob_rec_rmsreps.status_ind
END FUNCTION

############################################################
# FUNCTION rpt_rmsreps_set_exec_ind(p_exec_ind)
#
#	
############################################################
FUNCTION rpt_rmsreps_set_exec_ind(p_exec_ind)
	DEFINE p_exec_ind LIKE rmsreps.exec_ind 

	LET glob_rec_rmsreps.exec_ind = p_exec_ind
	
END FUNCTION

############################################################
# FUNCTION rpt_rmsreps_get_exec_ind()
#
# RETURN glob_rec_rpt_rmsreps_settings.rpt_rmsreps_note
############################################################
FUNCTION rpt_rmsreps_get_exec_ind()
	RETURN glob_rec_rmsreps.exec_ind
END FUNCTION



############################################################
# FUNCTION rpt_rmsreps_set_sel_text(p_sel_text)
#
#	
############################################################
FUNCTION rpt_rmsreps_set_sel_text(p_sel_text)
	DEFINE p_sel_text LIKE rmsreps.sel_text 

	LET glob_rec_rmsreps.sel_text = p_sel_text
	
END FUNCTION

############################################################
# FUNCTION rpt_rmsreps_get_sel_text()
#
# RETURN glob_rec_rpt_rmsreps_settings.rpt_rmsreps_note
############################################################
FUNCTION rpt_rmsreps_get_sel_text()
	RETURN glob_rec_rmsreps.sel_text
END FUNCTION


############################################################
# FUNCTION rpt_rmsreps_set_sel_flag(p_sel_flag)
#
#	
############################################################
FUNCTION rpt_rmsreps_set_sel_flag(p_sel_flag)
	DEFINE p_sel_flag LIKE rmsreps.sel_flag 

	LET glob_rec_rmsreps.sel_flag = p_sel_flag
	
END FUNCTION

############################################################
# FUNCTION rpt_rmsreps_get_sel_flag()
#
# RETURN glob_rec_rpt_rmsreps_settings.rpt_rmsreps_note
############################################################
FUNCTION rpt_rmsreps_get_sel_flag()
	RETURN glob_rec_rmsreps.sel_flag
END FUNCTION



############################################################
# FUNCTION rpt_rmsreps_set_file_text(p_file_text)
#
#	
############################################################
FUNCTION rpt_rmsreps_set_file_text(p_file_text)
	DEFINE p_file_text LIKE rmsreps.file_text 

	LET glob_rec_rmsreps.file_text = p_file_text
	
END FUNCTION

############################################################
# FUNCTION rpt_rmsreps_get_file_text()
#
# RETURN glob_rec_rpt_rmsreps_settings.rpt_rmsreps_note
############################################################
FUNCTION rpt_rmsreps_get_file_text()
	RETURN glob_rec_rmsreps.file_text
END FUNCTION

############################################################
# FUNCTION rpt_rmsreps_set_ref1_code(p_ref1_code)
#
#	
############################################################
FUNCTION rpt_rmsreps_set_ref1_code(p_ref1_code)
	DEFINE p_ref1_code LIKE rmsreps.ref1_code 

	LET glob_rec_rmsreps.ref1_code = p_ref1_code
	
END FUNCTION

############################################################
# FUNCTION rpt_rmsreps_get_ref1_code()
#
# RETURN glob_rec_rpt_rmsreps_settings.rpt_rmsreps_note
############################################################
FUNCTION rpt_rmsreps_get_ref1_code()
	RETURN glob_rec_rmsreps.ref1_code
END FUNCTION


############################################################
# FUNCTION rpt_rmsreps_set_ref2_code(p_ref2_code)
#
#	
############################################################
FUNCTION rpt_rmsreps_set_ref2_code(p_ref2_code)
	DEFINE p_ref2_code LIKE rmsreps.ref2_code 

	LET glob_rec_rmsreps.ref2_code = p_ref2_code
	
END FUNCTION

############################################################
# FUNCTION rpt_rmsreps_get_ref2_code()
#
# RETURN glob_rec_rpt_rmsreps_settings.rpt_rmsreps_note
############################################################
FUNCTION rpt_rmsreps_get_ref2_code()
	RETURN glob_rec_rmsreps.ref2_code
END FUNCTION

############################################################
# FUNCTION rpt_rmsreps_set_ref3_code(p_ref3_code)
#
#	
############################################################
FUNCTION rpt_rmsreps_set_ref3_code(p_ref3_code)
	DEFINE p_ref3_code LIKE rmsreps.ref3_code 

	LET glob_rec_rmsreps.ref3_code = p_ref3_code
	
END FUNCTION

############################################################
# FUNCTION rpt_rmsreps_get_ref3_code()
#
# RETURN glob_rec_rpt_rmsreps_settings.rpt_rmsreps_note
############################################################
FUNCTION rpt_rmsreps_get_ref3_code()
	RETURN glob_rec_rmsreps.ref3_code
END FUNCTION

############################################################
# FUNCTION rpt_rmsreps_set_ref4_code(p_ref4_code)
#
#	
############################################################
FUNCTION rpt_rmsreps_set_ref4_code(p_ref4_code)
	DEFINE p_ref4_code LIKE rmsreps.ref4_code 

	LET glob_rec_rmsreps.ref4_code = p_ref4_code
	
END FUNCTION

############################################################
# FUNCTION rpt_rmsreps_get_ref4_code()
#
# RETURN glob_rec_rpt_rmsreps_settings.rpt_rmsreps_note
############################################################
FUNCTION rpt_rmsreps_get_ref4_code()
	RETURN glob_rec_rmsreps.ref4_code
END FUNCTION


############################################################
# FUNCTION rpt_rmsreps_set_ref1_date(p_ref1_date)
#
#	
############################################################
FUNCTION rpt_rmsreps_set_ref1_date(p_ref1_date)
	DEFINE p_ref1_date LIKE rmsreps.ref1_date 

	LET glob_rec_rmsreps.ref1_date = p_ref1_date
	
END FUNCTION

############################################################
# FUNCTION rpt_rmsreps_get_ref1_date()
#
# RETURN glob_rec_rpt_rmsreps_settings.rpt_rmsreps_note
############################################################
FUNCTION rpt_rmsreps_get_ref1_date()
	RETURN glob_rec_rmsreps.ref1_date
END FUNCTION


############################################################
# FUNCTION rpt_rmsreps_set_ref2_date(p_ref2_date)
#
#	
############################################################
FUNCTION rpt_rmsreps_set_ref2_date(p_ref2_date)
	DEFINE p_ref2_date LIKE rmsreps.ref2_date 

	LET glob_rec_rmsreps.ref2_date = p_ref2_date
	
END FUNCTION

############################################################
# FUNCTION rpt_rmsreps_get_ref2_date()
#
# RETURN glob_rec_rpt_rmsreps_settings.rpt_rmsreps_note
############################################################
FUNCTION rpt_rmsreps_get_ref2_date()
	RETURN glob_rec_rmsreps.ref2_date
END FUNCTION

############################################################
# FUNCTION rpt_rmsreps_set_ref3_date(p_ref3_date)
#
#	
############################################################
FUNCTION rpt_rmsreps_set_ref3_date(p_ref3_date)
	DEFINE p_ref3_date LIKE rmsreps.ref3_date 

	LET glob_rec_rmsreps.ref3_date = p_ref3_date
	
END FUNCTION

############################################################
# FUNCTION rpt_rmsreps_get_ref3_date()
#
# RETURN glob_rec_rpt_rmsreps_settings.rpt_rmsreps_note
############################################################
FUNCTION rpt_rmsreps_get_ref3_date()
	RETURN glob_rec_rmsreps.ref3_date
END FUNCTION

############################################################
# FUNCTION rpt_rmsreps_set_ref4_date(p_ref4_date)
#
#	
############################################################
FUNCTION rpt_rmsreps_set_ref4_date(p_ref4_date)
	DEFINE p_ref4_date LIKE rmsreps.ref4_date 

	LET glob_rec_rmsreps.ref4_date = p_ref4_date
	
END FUNCTION

############################################################
# FUNCTION rpt_rmsreps_get_ref4_date()
#
# RETURN glob_rec_rpt_rmsreps_settings.rpt_rmsreps_note
############################################################
FUNCTION rpt_rmsreps_get_ref4_date()
	RETURN glob_rec_rmsreps.ref4_date
END FUNCTION

}

#---------------------------------------


{

############################################################
# FUNCTION rpt_rmsreps_set_ref1_ind(p_ref1_ind)
#
#	
############################################################
FUNCTION rpt_rmsreps_set_ref1_ind(p_ref1_ind)
	DEFINE p_ref1_ind LIKE rmsreps.ref1_ind 

	LET glob_rec_rmsreps.ref1_ind = p_ref1_ind
	
END FUNCTION

############################################################
# FUNCTION rpt_rmsreps_get_ref1_ind()
#
# RETURN glob_rec_rpt_rmsreps_settings.rpt_rmsreps_note
############################################################
FUNCTION rpt_rmsreps_get_ref1_ind()
	RETURN glob_rec_rmsreps.ref1_ind
END FUNCTION


############################################################
# FUNCTION rpt_rmsreps_set_ref2_ind(p_ref2_ind)
#
#	
############################################################
FUNCTION rpt_rmsreps_set_ref2_ind(p_ref2_ind)
	DEFINE p_ref2_ind LIKE rmsreps.ref2_ind 

	LET glob_rec_rmsreps.ref2_ind = p_ref2_ind
	
END FUNCTION

############################################################
# FUNCTION rpt_rmsreps_get_ref2_ind()
#
# RETURN glob_rec_rpt_rmsreps_settings.rpt_rmsreps_note
############################################################
FUNCTION rpt_rmsreps_get_ref2_ind()
	RETURN glob_rec_rmsreps.ref2_ind
END FUNCTION

############################################################
# FUNCTION rpt_rmsreps_set_ref3_ind(p_ref3_ind)
#
#	
############################################################
FUNCTION rpt_rmsreps_set_ref3_ind(p_ref3_ind)
	DEFINE p_ref3_ind LIKE rmsreps.ref3_ind 

	LET glob_rec_rmsreps.ref3_ind = p_ref3_ind
	
END FUNCTION

############################################################
# FUNCTION rpt_rmsreps_get_ref3_ind()
#
# RETURN glob_rec_rpt_rmsreps_settings.rpt_rmsreps_note
############################################################
FUNCTION rpt_rmsreps_get_ref3_ind()
	RETURN glob_rec_rmsreps.ref3_ind
END FUNCTION

############################################################
# FUNCTION rpt_rmsreps_set_ref4_ind(p_ref4_ind)
#
#	
############################################################
FUNCTION rpt_rmsreps_set_ref4_ind(p_ref4_ind)
	DEFINE p_ref4_ind LIKE rmsreps.ref4_ind 

	LET glob_rec_rmsreps.ref4_ind = p_ref4_ind
	
END FUNCTION

############################################################
# FUNCTION rpt_rmsreps_get_ref4_ind()
#
# RETURN glob_rec_rpt_rmsreps_settings.rpt_rmsreps_note
############################################################
FUNCTION rpt_rmsreps_get_ref4_ind()
	RETURN glob_rec_rmsreps.ref4_ind
END FUNCTION


############################################################
# FUNCTION rpt_rmsreps_set_printnow_flag(p_printnow_flag)
#
#	
############################################################
FUNCTION rpt_rmsreps_set_printnow_flag(p_printnow_flag)
	DEFINE p_printnow_flag LIKE rmsreps.printnow_flag 

	LET glob_rec_rmsreps.printnow_flag = p_printnow_flag
	
END FUNCTION

############################################################
# FUNCTION rpt_rmsreps_get_printnow_flag()
#
# RETURN glob_rec_rpt_rmsreps_settings.rpt_rmsreps_note
############################################################
FUNCTION rpt_rmsreps_get_printnow_flag()
	RETURN glob_rec_rmsreps.printnow_flag
END FUNCTION

############################################################
# FUNCTION rpt_rmsreps_set_copy_num(p_copy_num)
#
#	
############################################################
FUNCTION rpt_rmsreps_set_copy_num(p_copy_num)
	DEFINE p_copy_num LIKE rmsreps.copy_num 

	LET glob_rec_rmsreps.copy_num = p_copy_num
	
END FUNCTION

############################################################
# FUNCTION rpt_rmsreps_get_copy_num()
#
# RETURN glob_rec_rpt_rmsreps_settings.rpt_rmsreps_note
############################################################
FUNCTION rpt_rmsreps_get_copy_num()
	RETURN glob_rec_rmsreps.copy_num
END FUNCTION



############################################################
# FUNCTION rpt_rmsreps_set_comp_ind(p_comp_ind)
#
#	
############################################################
FUNCTION rpt_rmsreps_set_comp_ind(p_comp_ind)
	DEFINE p_comp_ind LIKE rmsreps.comp_ind 

	LET glob_rec_rmsreps.comp_ind = p_comp_ind
	
END FUNCTION

############################################################
# FUNCTION rpt_rmsreps_get_comp_ind()
#
# RETURN glob_rec_rpt_rmsreps_settings.rpt_rmsreps_note
############################################################
FUNCTION rpt_rmsreps_get_comp_ind()
	RETURN glob_rec_rmsreps.comp_ind
END FUNCTION



############################################################
# FUNCTION rpt_rmsreps_set_start_page(p_start_page)
#
#	
############################################################
FUNCTION rpt_rmsreps_set_start_page(p_start_page)
	DEFINE p_start_page LIKE rmsreps.start_page 

	LET glob_rec_rmsreps.start_page = p_start_page
	
END FUNCTION

############################################################
# FUNCTION rpt_rmsreps_get_start_page()
#
# RETURN glob_rec_rpt_rmsreps_settings.rpt_rmsreps_note
############################################################
FUNCTION rpt_rmsreps_get_start_page()
	RETURN glob_rec_rmsreps.start_page
END FUNCTION

############################################################
# FUNCTION rpt_rmsreps_set_print_page(p_print_page)
#
#	
############################################################
FUNCTION rpt_rmsreps_set_print_page(p_print_page)
	DEFINE p_print_page LIKE rmsreps.print_page 

	LET glob_rec_rmsreps.print_page = p_print_page
	
END FUNCTION

############################################################
# FUNCTION rpt_rmsreps_get_print_page()
#
# RETURN glob_rec_rpt_rmsreps_settings.rpt_rmsreps_note
############################################################
FUNCTION rpt_rmsreps_get_print_page()
	RETURN glob_rec_rmsreps.print_page
END FUNCTION

############################################################
# FUNCTION rpt_rmsreps_set_align_ind(p_align_ind)
#
#	
############################################################
FUNCTION rpt_rmsreps_set_align_ind(p_align_ind)
	DEFINE p_align_ind LIKE rmsreps.align_ind 

	LET glob_rec_rmsreps.align_ind = p_align_ind
	
END FUNCTION

############################################################
# FUNCTION rpt_rmsreps_get_align_ind()
#
# RETURN glob_rec_rpt_rmsreps_settings.rpt_rmsreps_note
############################################################
FUNCTION rpt_rmsreps_get_align_ind()
	RETURN glob_rec_rmsreps.align_ind
END FUNCTION

############################################################
# FUNCTION rpt_rmsreps_set_ref1_num(p_ref1_num)
#
#	
############################################################
FUNCTION rpt_rmsreps_set_ref1_num(p_ref1_num)
	DEFINE p_ref1_num LIKE rmsreps.ref1_num 

	LET glob_rec_rmsreps.ref1_num = p_ref1_num
	
END FUNCTION

############################################################
# FUNCTION rpt_rmsreps_get_ref1_num()
#
# RETURN glob_rec_rpt_rmsreps_settings.rpt_rmsreps_note
############################################################
FUNCTION rpt_rmsreps_get_ref1_num()
	RETURN glob_rec_rmsreps.ref1_num
END FUNCTION

############################################################
# FUNCTION rpt_rmsreps_set_ref2_num(p_ref2_num)
#
#	
############################################################
FUNCTION rpt_rmsreps_set_ref2_num(p_ref2_num)
	DEFINE p_ref2_num LIKE rmsreps.ref2_num 

	LET glob_rec_rmsreps.ref2_num = p_ref2_num
	
END FUNCTION

############################################################
# FUNCTION rpt_rmsreps_get_ref2_num()
#
# RETURN glob_rec_rpt_rmsreps_settings.rpt_rmsreps_note
############################################################
FUNCTION rpt_rmsreps_get_ref2_num()
	RETURN glob_rec_rmsreps.ref2_num
END FUNCTION

############################################################
# FUNCTION rpt_rmsreps_set_ref3_num(p_ref3_num)
#
#	
############################################################
FUNCTION rpt_rmsreps_set_ref3_num(p_ref3_num)
	DEFINE p_ref3_num LIKE rmsreps.ref3_num 

	LET glob_rec_rmsreps.ref3_num = p_ref3_num
	
END FUNCTION

############################################################
# FUNCTION rpt_rmsreps_get_ref3_num()
#
# RETURN glob_rec_rpt_rmsreps_settings.rpt_rmsreps_note
############################################################
FUNCTION rpt_rmsreps_get_ref3_num()
	RETURN glob_rec_rmsreps.ref3_num
END FUNCTION

############################################################
# FUNCTION rpt_rmsreps_set_ref4_num(p_ref4_num)
#
#	
############################################################
FUNCTION rpt_rmsreps_set_ref4_num(p_ref4_num)
	DEFINE p_ref4_num LIKE rmsreps.ref4_num 

	LET glob_rec_rmsreps.ref4_num = p_ref4_num
	
END FUNCTION

############################################################
# FUNCTION rpt_rmsreps_get_ref4_num()
#
# RETURN glob_rec_rpt_rmsreps_settings.rpt_rmsreps_note
############################################################
FUNCTION rpt_rmsreps_get_ref4_num()
	RETURN glob_rec_rmsreps.ref4_num
END FUNCTION


############################################################
# FUNCTION rpt_rmsreps_set_ref1_text(p_ref1_text)
#
#	
############################################################
FUNCTION rpt_rmsreps_set_ref1_text(p_ref1_text)
	DEFINE p_ref1_text LIKE rmsreps.ref1_text 

	LET glob_rec_rmsreps.ref1_text = p_ref1_text
	
END FUNCTION

############################################################
# FUNCTION rpt_rmsreps_get_ref1_text()
#
# RETURN glob_rec_rpt_rmsreps_settings.rpt_rmsreps_note
############################################################
FUNCTION rpt_rmsreps_get_ref1_text()
	RETURN glob_rec_rmsreps.ref1_text
END FUNCTION

############################################################
# FUNCTION rpt_rmsreps_set_sub_dest(p_sub_dest)
#
#	
############################################################
FUNCTION rpt_rmsreps_set_sub_dest(p_sub_dest)
	DEFINE p_sub_dest LIKE rmsreps.sub_dest 

	LET glob_rec_rmsreps.sub_dest = p_sub_dest
	
END FUNCTION

############################################################
# FUNCTION rpt_rmsreps_get_sub_dest()
#
# RETURN glob_rec_rpt_rmsreps_settings.rpt_rmsreps_note
############################################################
FUNCTION rpt_rmsreps_get_sub_dest()
	RETURN glob_rec_rmsreps.sub_dest
END FUNCTION

############################################################
# FUNCTION rpt_rmsreps_set_printonce_flag(p_printonce_flag)
#
#	
############################################################
FUNCTION rpt_rmsreps_set_printonce_flag(p_printonce_flag)
	DEFINE p_printonce_flag LIKE rmsreps.printonce_flag 

	LET glob_rec_rmsreps.printonce_flag = p_printonce_flag
	
END FUNCTION

############################################################
# FUNCTION rpt_rmsreps_get_printonce_flag()
#
# RETURN glob_rec_rpt_rmsreps_settings.rpt_rmsreps_note
############################################################
FUNCTION rpt_rmsreps_get_printonce_flag()
	RETURN glob_rec_rmsreps.printonce_flag
END FUNCTION
}