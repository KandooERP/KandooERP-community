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

###########################################################################
# Comments:
#	1.2.2020 HuHo: Created the library lib_report which includes reptfunc.4gl, glob_GLOBALS_report.4gl  and rmsfunc.4gl
# Information below about include reptfunc.4gl in most report programs is outdated
# This file IS GLOBALS included in in most if NOT all REPORT modules
###########################################################################

#######################################
## Report Library Routine
#######################################
#This file IS used as GLOBALS file FROM lib_report
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl" 
GLOBALS "../common/postfunc_GLOBALS.4gl"
############################################################
# MODULE Scope Variables
############################################################


############################################################
# FUNCTION rpt_background_run_by_query(p_sel_text)
# RETURN void
# 
# Runs report in separate background process
# Interesting for long lasting report generations
############################################################
FUNCTION rpt_background_run_by_query(p_sel_text)
	DEFINE p_sel_text STRING
	
	CALL run_prog_with_wait_status_and_url_arg(getmoduleid(),FALSE,"SEL_TEXT",p_sel_text,"EXEC_IND","4",NULL,NULL,NULL,NULL)	
END FUNCTION


############################################################
# FUNCTION rpt_background_run_by_rmsreps_report_code(p_report_code)
# RETURN void
# 
# Runs report in separate background process
# Interesting for long lasting report generations
############################################################
FUNCTION rpt_background_run_by_rmsreps_report_code(p_report_code)
	DEFINE p_report_code LIKE rmsreps.report_code

	#glob_rec_rmsreps.exec_ind = 2 = background print -- url_report_code() # RECURSIVE !!!	
	CALL run_prog_with_wait_status_and_url_arg(get_prog_id(),FALSE,"REPORT_CODE",p_report_code,"EXEC_IND","2","MODULE_CHILD",getmoduleid(),NULL,NULL)	
END FUNCTION

############################################################
# FUNCTION rpt_rmsreps_reset(p_rpt_idx)
# RETURN void
#
# Prior to the report(s) generation, clear all report objects and temp data from the previous report
############################################################
FUNCTION rpt_rmsreps_reset(p_rpt_idx)
	DEFINE p_rpt_idx SMALLINT
	
	IF p_rpt_idx IS NULL OR p_rpt_idx < 1 THEN
		CALL glob_arr_rmsreps_idx.clear()
		CALL glob_arr_rec_rpt_kandooreport.clear()
		CALL glob_arr_rec_rpt_rmsreps.clear()
		CALL glob_arr_rec_rpt_printcodes.clear()
		CALL glob_arr_rec_rpt_header_footer.clear()
		CALL rpt_set_is_background_process(NULL) --was INITIALIZE glob_rpt_background_process TO NULL
		INITIALIZE glob_rec_rpt_selector TO NULL
	ELSE
		--INITIALIZE glob_arr_rmsreps_idx[p_rpt_idx] TO NULL
		INITIALIZE glob_arr_rec_rpt_kandooreport[p_rpt_idx].* TO NULL
		INITIALIZE glob_arr_rec_rpt_rmsreps[p_rpt_idx].* TO NULL
		INITIALIZE glob_arr_rec_rpt_printcodes[p_rpt_idx].* TO NULL
		INITIALIZE glob_arr_rec_rpt_header_footer[p_rpt_idx].* TO NULL
		--CALL rpt_set_is_background_process(NULL) 
		--INITIALIZE glob_rec_rpt_selector TO NULL
	
	END IF		
END FUNCTION

############################################################
# FUNCTION rpt_rmsreps_idx_get_idx(p_rep_func_name)
# RETURN i SMALLINT
# 
# Returns rpt array index of the corresponding report function
# to support multiple reports in one program
############################################################
FUNCTION rpt_rmsreps_idx_get_idx(p_rep_func_name)
	DEFINE l_ui_mode SMALLINT
	DEFINE p_rep_func_name STRING
	DEFINE i SMALLINT
	DEFINE l_msg STRING
	LET p_rep_func_name = p_rep_func_name.toUpperCase()
	LET l_ui_mode = UI_ON
	FOR i = 1 TO glob_arr_rmsreps_idx.getSize()
		IF glob_arr_rmsreps_idx[i] = p_rep_func_name THEN
			RETURN i
		END IF
	END FOR

	IF l_ui_mode != UI_OFF THEN	
		LET l_msg = "FUNCTION rpt_rmsreps_idx_get_idx(p_rep_func_name)\nReport Function name ", trim(p_rep_func_name), " not found\nrpt_rmsreps_idx_get_idx(p_rep_func_name)"
		DISPLAY "Available/Registerd report functions:"
		FOR i = 1 TO glob_arr_rmsreps_idx.getSize()
			DISPLAY glob_arr_rmsreps_idx[i]
		END FOR
		CALL fgl_winmessage("INTERNAL 4GL Error",l_msg,"ERROR")
	END IF
	RETURN 0
END FUNCTION

############################################################
# FUNCTION rpt_rmsreps_idx_funcname_exists(p_ui_mode,p_rep_func_name)
# RETURN i SMALLINT
# 
# Returns rpt array index of the corresponding report function
# to support multiple reports in one program
############################################################
FUNCTION rpt_rmsreps_idx_funcname_exists(p_ui_mode,p_rep_func_name)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_rep_func_name STRING
	DEFINE i SMALLINT
	DEFINE l_msg STRING
	
	LET p_rep_func_name = p_rep_func_name.toUpperCase()
	FOR i = 1 TO glob_arr_rmsreps_idx.getSize()
		IF glob_arr_rmsreps_idx[i].toUpperCase() = trim(p_rep_func_name.toUpperCase()) THEN
			RETURN i
		END IF
	END FOR

	IF p_ui_mode != UI_OFF THEN	
		LET l_msg = "Report Function name ", trim(p_rep_func_name), " not found\nrpt_rmsreps_idx_get_idx(p_rep_func_name)"
		DISPLAY "Available/Registerd report functions:"
		FOR i = 1 TO glob_arr_rmsreps_idx.getSize()
			DISPLAY glob_arr_rmsreps_idx[i]
		END FOR
		CALL fgl_winmessage("INTERNAL 4GL Error",l_msg,"ERROR")
	END IF
	RETURN 0
END FUNCTION



############################################################
# FUNCTION rpt_rmsreps_idx_get_all_ready_for_print()
# RETURN ret_all_ready BOOLEAN
# 
# Returns if all reports are ready for printing
############################################################
FUNCTION rpt_rmsreps_idx_get_all_ready_for_print()
	DEFINE ret_all_ready BOOLEAN
	DEFINE l_count SMALLINT
	DEFINE i SMALLINT
	

	IF glob_arr_rmsreps_idx.getSize() = 0 THEN
		CALL fgl_winmessage("Internal 4gl error","rpt_rmsreps_idx_get_all_ready_for_print()\nrmsreps array is empty!","ERROR")
		RETURN FALSE	
	END IF
	
	LET l_count = 0
	FOR i = 1 TO glob_arr_rmsreps_idx.getSize()
		DISPLAY "Array Element Index =", trim(i), " Status =", db_rmsreps_get_status_ind(UI_OFF,glob_arr_rec_rpt_rmsreps[i].report_code)
		IF db_rmsreps_get_status_ind(UI_OFF,glob_arr_rec_rpt_rmsreps[i].report_code) = "A" THEN
			LET l_count = l_count +1
		END IF
	END FOR

	IF glob_arr_rmsreps_idx.getSize() = l_count THEN #ALL reports are ready for printing
		LET ret_all_ready = TRUE
	ELSE
		LET ret_all_ready = FALSE
	END IF

	RETURN ret_all_ready
END FUNCTION

############################################################
# FUNCTION rpt_rmsreps_idx_get_rep_func_name(p_rpt_idx)
# RETURN glob_arr_rmsreps_idx[p_rpt_idx]   
# 
# Returns rpt array report function name by index
# to support multiple reports in one program
############################################################
FUNCTION rpt_rmsreps_idx_get_rep_func_name(p_rpt_idx)
	DEFINE p_rpt_idx SMALLINT
	
	RETURN glob_arr_rmsreps_idx[p_rpt_idx]   
END FUNCTION


############################################################
# FUNCTION rpt_rmsreps_idx_append(p_rep_func_name)
# RETURN i SMALLINT
# 
# Returns rpt array index of the corresponding report function
# to support multiple reports in one program
############################################################
FUNCTION rpt_rmsreps_idx_append(p_rep_func_name)
	DEFINE p_rep_func_name STRING
	DEFINE l_rpt_idx SMALLINT
	DEFINE i SMALLINT
	LET p_rep_func_name = p_rep_func_name.toUpperCase()
	#Check if the name was already used in previous sessions..
	LET l_rpt_idx = rpt_rmsreps_idx_funcname_exists(UI_OFF,p_rep_func_name)
	IF l_rpt_idx != 0 THEN #already exists - we will not add it again BUT we need to initialize existing variables and RETURN this array index
		--INITIALIZE glob_arr_rec_rpt_rmsreps[l_rpt_idx] TO NULL
		--INITIALIZE glob_arr_rec_rpt_kandooreport[l_rpt_idx] TO NULL
		--INITIALIZE glob_arr_rec_rpt_header_footer[l_rpt_idx] TO NULL
		--CALL rpt_rmsreps_reset(l_rpt_idx)
	ELSE
		CALL glob_arr_rmsreps_idx.append(p_rep_func_name.toUpperCase())
		LET l_rpt_idx = glob_arr_rmsreps_idx.getSize()
	END IF
	
	CALL rpt_rmsreps_reset(l_rpt_idx) #initialize existing report variables 
	
	RETURN l_rpt_idx
END FUNCTION

#########################################################
# FUNCTION rpt_get_report_file_with_path2(p_rpt_idx)
# p_rpt_idx = rmsreps array index
# Return the corresponding report file name inc. path
#########################################################
FUNCTION rpt_get_report_file_with_path2(p_rpt_idx)
	DEFINE p_rpt_idx SMALLINT #rpt array index
	DEFINE l_ret_path_file STRING
	
	LET l_ret_path_file = trim(get_settings_reportPath()), "/", trim(glob_rec_company.cmpy_code), "/", trim(glob_arr_rec_rpt_rmsreps[p_rpt_idx].file_text) 
	RETURN l_ret_path_file
END FUNCTION

#########################################################
# FUNCTION rpt_get_report_file2(p_rpt_idx)
# p_rpt_idx = rmsreps array index
# Return the corresponding report file name 
#########################################################
FUNCTION rpt_get_report_file2(p_rpt_idx)
	DEFINE p_rpt_idx SMALLINT
	DEFINE l_ret_path_file STRING
	
	LET l_ret_path_file = trim(get_settings_reportPath()), "/", trim(glob_arr_rec_rpt_rmsreps[p_rpt_idx].file_text) 
	RETURN l_ret_path_file
END FUNCTION


#########################################################
# FUNCTION rpt_start(p_kandooreport_code_text)
#
# Checks if int_flag is raised OR status_ind = "I"
# and sets the status_text / status_ind accordingly 
#########################################################
FUNCTION rpt_start(p_kandooreport_code_text,p_rpt_func_name,p_where_text,p_show_rmsreport_print_dialog)
	DEFINE p_kandooreport_code_text LIKE kandooreport.report_code # nchar(10),
	DEFINE p_rpt_func_name VARCHAR(30) 
	DEFINE p_where_text STRING
	DEFINE p_show_rmsreport_print_dialog BOOLEAN
	DEFINE l_rpt_idx SMALLINT
	DEFINE l_rec_kandooreport RECORD LIKE kandooreport.*
	#Variables use for background processing
	DEFINE l_status_ind LIKE rmsreps.status_ind 
	DEFINE l_report_code_num LIKE rmsreps.report_code
	DEFINE l_rec_rms_reps RECORD LIKE rmsreps.*
		
	#DISPLAY glob_arr_rec_rpt_rmsreps.appendelement()
	#LET l_idx = glob_arr_rec_rpt_rmsreps.getSize() 
	#LET glob_arr_rec_rpt_rmsreps[l_idx].

{

	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start("PB1","PB1_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	ELSE
		IF glob_arr_rec_rpt_rmsreps[l_rpt_idx].status_ind = "Q" THEN #launch background process
			CALL rpt_background_run_by_rmsreps_report_code(glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_code) #Interesting for reports taking longer to process 
			RETURN #do we need some kind of value ?
		END IF	
	END IF
	START REPORT PB1_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
}
	#LET l_status_ind = get_url_status_ind() 
	LET l_report_code_num = get_url_report_code()
	CASE #keep case statement as we may need to add further cases easily
		WHEN (l_report_code_num != 0) #queued background process launch
			CALL db_rmsreps_get_rec(UI_OFF,l_report_code_num) 
				RETURNING l_rec_rms_reps.*
			CALL db_kandooreport_get_rec(UI_OFF,glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.country_code,glob_rec_kandoouser.language_code,getmoduleid(),p_kandooreport_code_text) 
				RETURNING l_rec_kandooreport.*
			LET l_rpt_idx = rpt_rmsreps_idx_append(p_rpt_func_name)		
			LET glob_arr_rec_rpt_rmsreps[l_rpt_idx].* = l_rec_rms_reps.*
			LET glob_arr_rec_rpt_rmsreps[l_rpt_idx].status_ind = "A" #Change from "Q"/Queued
			LET glob_arr_rec_rpt_rmsreps[l_rpt_idx].status_text = "In Progress" #Change from "Q"/Queued
			CALL rpt_update_rmsreps2(l_rpt_idx)

		OTHERWISE
			#LET l_report_code_num = p_kandooreport_code_text
			#CALL rpt_set_show_rmsreps_dialog(p_show_rmsreport_print_dialog) #init if user should be able to see/change rms-options
			CALL rpt_kandooreport_init2(p_kandooreport_code_text) RETURNING l_rec_kandooreport.*
			IF int_flag THEN #Did user press cancel 
				LET int_flag = FALSE
				RETURN 0 
			END IF	

			IF l_rec_kandooreport.report_code IS NOT NULL THEN
				CALL rpt_rmsreps_init2(p_rpt_func_name,l_rec_kandooreport.*) RETURNING l_rpt_idx
				IF NOT rpt_int_flag_handler2(NULL,NULL,NULL,l_rpt_idx)	THEN RETURN 0 END IF
			END IF

	END CASE

#---------------------------------------------------------------------
# NOW, we have an report array record with index l_rpt_idx
#---------------------------------------------------------------------
	IF l_rpt_idx != 0 AND l_rpt_idx IS NOT NULL THEN

		#Take sql WHERE sel_text from globals (can be provided by url or rpt_query_function()
		IF p_where_text IS NOT NULL THEN #Note: cater for background processes with report_code and no-sel_text
			LET glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text = p_where_text #silly report wants select where clause to be printed
		END IF
		#CALL db_rmsreps_set_status_text_and_status_ind(UI_ON,	glob_rec_rmsreps.report_code ,"In Progress","R")
		MESSAGE trim(glob_arr_rec_rpt_rmsreps[l_rpt_idx].status_text), " - ", trim(glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_text), ": ", trim(glob_arr_rec_rpt_rmsreps[l_rpt_idx].file_text)

		IF glob_arr_rec_rpt_rmsreps[l_rpt_idx].entry_type = 1 THEN #special container - sub reports
			LET glob_arr_rec_rpt_rmsreps[l_rpt_idx].status_text = "Container In Progress"
			LET glob_arr_rec_rpt_rmsreps[l_rpt_idx].status_ind = "A"
			CALL rpt_update_rmsreps2(l_rpt_idx)
		ELSE

			IF glob_arr_rec_rpt_rmsreps[l_rpt_idx].rmsdialog_flag != "N" AND (glob_arr_rec_rpt_rmsreps[l_rpt_idx].exec_ind = 1) THEN
				IF NOT rpt_rmsreps_dialog2(l_rpt_idx,0) THEN 
					RETURN 0 
				END IF 
				
				CASE rpt_get_is_background_process() #was glob_rpt_background_process 
					WHEN NULL #Error/Abbort
						RETURN 0
					WHEN FALSE
						#Proceed as normal
						#Report can now be generated - change status and update DB
						LET glob_arr_rec_rpt_rmsreps[l_rpt_idx].status_text = "In Progress"
						LET glob_arr_rec_rpt_rmsreps[l_rpt_idx].status_ind = "A"
						CALL rpt_init_report_header_footer(l_rpt_idx) #process/prepare header/footer/end of report text in glob_arr_rec_footer_header	
						CALL rpt_update_rmsreps2(l_rpt_idx)
	
					WHEN TRUE #Will be launched as background process recursive
						#Report will be queued for background
						LET glob_arr_rec_rpt_rmsreps[l_rpt_idx].status_text = "Queued for Background Process"
						LET glob_arr_rec_rpt_rmsreps[l_rpt_idx].status_ind = "Q"	
						CALL rpt_update_rmsreps2(l_rpt_idx)
						CALL rpt_background_run_by_rmsreps_report_code(glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_code)
						RETURN 0 #= cancel/exit sub-routine...		
	
				END CASE
			END IF 
		END IF
--		CALL rpt_init_report_header_footer(l_rpt_idx) #process/prepare header/footer/end of report text in glob_arr_rec_footer_header	
--		CALL rpt_update_rmsreps2(l_rpt_idx)
		
--		IF glob_arr_rec_rpt_rmsreps[l_rpt_idx].status_ind = "Q" THEN #Q=Queue for background process
--			CALL rpt_background_run_by_rmsreps_report_code(glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_code)
--			RETURN 0 #= cancel/exit sub-routine...		
--		END IF 
	ELSE
		CALL fgl_winmessage("4GL-Internal-Error","ERROR in rpt_start()\nREPORT_CODE OR MENUPATH_TEXT is empty (& l_rpt_idx) is empty/NULL!","ERROR")
		RETURN 0
	END IF

	RETURN l_rpt_idx
END FUNCTION


#######################################################################################
# FUNCTION rpt_rmsreps_init2(p_rpt_func_name,p_rec_kandooreport)
# Set the report file name and
# Updates table rmsreps with report settings
#######################################################################################
FUNCTION rpt_rmsreps_init2(p_rpt_func_name,p_rec_kandooreport)
	DEFINE p_rpt_func_name VARCHAR(30)
	DEFINE p_rec_kandooreport RECORD LIKE kandooreport.* 
	DEFINE l_rec_rmsreps RECORD LIKE rmsreps.*
	DEFINE l_cmpy LIKE rmsreps.cmpy_code
	DEFINE l_msg STRING	
	DEFINE l_rpt_idx SMALLINT
	DEFINE l_report_code LIKE rmsreps.report_code
	DEFINE l_ret_success BOOLEAN 
	DEFINE l_url_printnow LIKE rmsreps.printnow_flag
	
	LET l_rpt_idx = rpt_rmsreps_idx_append(p_rpt_func_name)
	LET l_rec_rmsreps.cmpy_code = glob_rec_kandoouser.cmpy_code
	LET l_rec_rmsreps.report_text = p_rec_kandooreport.header_text 
	LET l_rec_rmsreps.status_text = "Composing"
	LET l_rec_rmsreps.status_ind = "C"	
	LET l_rec_rmsreps.report_date = TODAY #p_rec_kandooreport.l_report_date 
	LET l_rec_rmsreps.report_time = CURRENT HOUR TO MINUTE #p_rec_kandooreport.l_report_time
	LET l_rec_rmsreps.report_pgm_text = p_rec_kandooreport.report_code #Template kandooreport.report_code 
	LET l_rec_rmsreps.report_modid_text = getmoduleid() #Kandoo Programm Module ID 
	LET l_rec_rmsreps.report_func_text = p_rpt_func_name #4GL report function name 

	LET l_rec_rmsreps.report_width_num = p_rec_kandooreport.width_num 
	LET l_rec_rmsreps.page_length_num = p_rec_kandooreport.length_num


	LET l_rec_rmsreps.col_pos_1 = p_rec_kandooreport.col_pos_1	
	LET l_rec_rmsreps.col_pos_2 = p_rec_kandooreport.col_pos_2	
	LET l_rec_rmsreps.col_pos_3 = p_rec_kandooreport.col_pos_3	
	LET l_rec_rmsreps.col_pos_4 = p_rec_kandooreport.col_pos_4	
	LET l_rec_rmsreps.col_pos_5 = p_rec_kandooreport.col_pos_5	
	LET l_rec_rmsreps.col_pos_6 = p_rec_kandooreport.col_pos_6	
	LET l_rec_rmsreps.col_pos_7 = p_rec_kandooreport.col_pos_7	
	LET l_rec_rmsreps.col_pos_8 = p_rec_kandooreport.col_pos_8	
	LET l_rec_rmsreps.col_pos_9 = p_rec_kandooreport.col_pos_9	


	--LET l_rec_rmsreps.sel_text = glob_rec_rpt_selector.sel_text
	LET l_rec_rmsreps.sel_option1 = glob_rec_rpt_selector.sel_option1
	LET l_rec_rmsreps.sel_option2 = glob_rec_rpt_selector.sel_option2
	LET l_rec_rmsreps.sel_option3 = glob_rec_rpt_selector.sel_option3
	LET l_rec_rmsreps.sel_option4 = glob_rec_rpt_selector.sel_option4
	LET l_rec_rmsreps.sel_option5 = glob_rec_rpt_selector.sel_option5
	LET l_rec_rmsreps.sel_option6 = glob_rec_rpt_selector.sel_option6

	LET l_rec_rmsreps.sel_order = glob_rec_rpt_selector.sel_order
	--LET l_rec_rmsreps.report_ord_flag = glob_rec_rpt_selector.report_ord_flag
	LET l_rec_rmsreps.sel_flag = p_rec_kandooreport.selection_flag

	LET l_rec_rmsreps.ref1_text = glob_rec_rpt_selector.ref1_text
	LET l_rec_rmsreps.ref1_code = glob_rec_rpt_selector.ref1_code
	LET l_rec_rmsreps.ref1_num = glob_rec_rpt_selector.ref1_num
	LET l_rec_rmsreps.ref1_date = glob_rec_rpt_selector.ref1_date
	LET l_rec_rmsreps.ref1_ind = glob_rec_rpt_selector.ref1_ind
	LET l_rec_rmsreps.ref1_amt = glob_rec_rpt_selector.ref1_amt
	LET l_rec_rmsreps.ref1_per = glob_rec_rpt_selector.ref1_per
	LET l_rec_rmsreps.ref1_factor = glob_rec_rpt_selector.ref1_factor
	
	LET l_rec_rmsreps.ref2_text = glob_rec_rpt_selector.ref2_text
	LET l_rec_rmsreps.ref2_code = glob_rec_rpt_selector.ref2_code
	LET l_rec_rmsreps.ref2_num = glob_rec_rpt_selector.ref2_num	
	LET l_rec_rmsreps.ref2_date = glob_rec_rpt_selector.ref2_date
	LET l_rec_rmsreps.ref2_ind = glob_rec_rpt_selector.ref2_ind
	LET l_rec_rmsreps.ref2_amt = glob_rec_rpt_selector.ref2_amt
	LET l_rec_rmsreps.ref2_per = glob_rec_rpt_selector.ref2_per
	LET l_rec_rmsreps.ref2_factor = glob_rec_rpt_selector.ref2_factor
	
	LET l_rec_rmsreps.ref3_text = glob_rec_rpt_selector.ref3_text #does not exist
	LET l_rec_rmsreps.ref3_code = glob_rec_rpt_selector.ref3_code
	LET l_rec_rmsreps.ref3_num = glob_rec_rpt_selector.ref3_num	
	LET l_rec_rmsreps.ref3_date = glob_rec_rpt_selector.ref3_date
	LET l_rec_rmsreps.ref3_ind = glob_rec_rpt_selector.ref3_ind
	LET l_rec_rmsreps.ref3_amt = glob_rec_rpt_selector.ref3_amt
	LET l_rec_rmsreps.ref3_per = glob_rec_rpt_selector.ref3_per
	LET l_rec_rmsreps.ref3_factor = glob_rec_rpt_selector.ref3_factor
		
	LET l_rec_rmsreps.ref4_text = glob_rec_rpt_selector.ref4_text #does not exist
	LET l_rec_rmsreps.ref4_code = glob_rec_rpt_selector.ref4_code
	LET l_rec_rmsreps.ref4_num = glob_rec_rpt_selector.ref4_num	
	LET l_rec_rmsreps.ref4_date = glob_rec_rpt_selector.ref4_date
	LET l_rec_rmsreps.ref4_ind = glob_rec_rpt_selector.ref4_ind
	LET l_rec_rmsreps.ref4_amt = glob_rec_rpt_selector.ref4_amt
	LET l_rec_rmsreps.ref4_per = glob_rec_rpt_selector.ref4_per
	LET l_rec_rmsreps.ref4_factor = glob_rec_rpt_selector.ref4_factor
		
	LET l_rec_rmsreps.ref5_text = glob_rec_rpt_selector.ref5_text #does not exist
	LET l_rec_rmsreps.ref5_code = glob_rec_rpt_selector.ref5_code
	LET l_rec_rmsreps.ref5_num = glob_rec_rpt_selector.ref5_num	
	LET l_rec_rmsreps.ref5_date = glob_rec_rpt_selector.ref5_date
	LET l_rec_rmsreps.ref5_ind = glob_rec_rpt_selector.ref5_ind
	LET l_rec_rmsreps.ref5_amt = glob_rec_rpt_selector.ref5_amt
	LET l_rec_rmsreps.ref5_per = glob_rec_rpt_selector.ref5_per
	LET l_rec_rmsreps.ref5_factor = glob_rec_rpt_selector.ref5_factor
	
	LET l_rec_rmsreps.ref6_text = glob_rec_rpt_selector.ref6_text #does not exist
	LET l_rec_rmsreps.ref6_code = glob_rec_rpt_selector.ref6_code
	LET l_rec_rmsreps.ref6_num = glob_rec_rpt_selector.ref6_num	
	LET l_rec_rmsreps.ref6_date = glob_rec_rpt_selector.ref6_date
	LET l_rec_rmsreps.ref6_ind = glob_rec_rpt_selector.ref6_ind
	LET l_rec_rmsreps.ref6_amt = glob_rec_rpt_selector.ref6_amt
	LET l_rec_rmsreps.ref6_per = glob_rec_rpt_selector.ref6_per
	LET l_rec_rmsreps.ref6_factor = glob_rec_rpt_selector.ref6_factor
	
	LET l_rec_rmsreps.report_date = glob_rec_rpt_selector.report_date
	LET l_rec_rmsreps.page_num = 0 #Page number 0 is the start If it stays 0, query returned 0 results	

	LET l_rec_rmsreps.entry_code = glob_rec_kandoouser.sign_on_code  --p_kandoouser_sign_on_code 
	LET l_rec_rmsreps.security_ind = glob_rec_kandoouser.security_ind 
	LET l_rec_rmsreps.dest_print_text = glob_rec_kandoouser.print_text

	#Some possible NULL values need default value


	IF p_rec_kandooreport.report_engine IS NULL THEN
		LET p_rec_kandooreport.report_engine = 0 #Default Report Engine "0" = Classic 4GL text report
	END IF
	LET l_rec_rmsreps.report_engine = p_rec_kandooreport.report_engine

	IF p_rec_kandooreport.titleedit_flag IS NULL THEN
		LET p_rec_kandooreport.titleedit_flag = "Y" #Default - user can edit report title
	END IF
	LET l_rec_rmsreps.titleedit_flag = p_rec_kandooreport.titleedit_flag

 	IF p_rec_kandooreport.exec_ind != 2 THEN
		IF p_rec_kandooreport.rmsdialog_flag IS NULL THEN
			LET p_rec_kandooreport.rmsdialog_flag = "Y" #Default - rmsReport dialog box opens
		END IF
	ELSE
		LET p_rec_kandooreport.rmsdialog_flag = "N" #NO Dialog boxes in background processes / batch modes
	END IF 	
	LET l_rec_rmsreps.rmsdialog_flag = p_rec_kandooreport.rmsdialog_flag

	IF p_rec_kandooreport.printnow_flag IS NULL THEN
		LET p_rec_kandooreport.printnow_flag = "Y" #Default - Report can directly be printed/viewed on client side
	END IF
	LET l_rec_rmsreps.printnow_flag = p_rec_kandooreport.printnow_flag

	IF p_rec_kandooreport.entry_type IS NULL THEN
		LET p_rec_kandooreport.entry_type = 0 #Default - entry type is normal report (not a special container)
	END IF
	LET l_rec_rmsreps.entry_type = p_rec_kandooreport.entry_type

	IF p_rec_kandooreport.top_margin IS NULL THEN
		LET p_rec_kandooreport.top_margin = 0
	END IF
	LET l_rec_rmsreps.top_margin = p_rec_kandooreport.top_margin
	
	IF p_rec_kandooreport.bottom_margin IS NULL THEN
		LET p_rec_kandooreport.bottom_margin = 0
	END IF
	LET l_rec_rmsreps.bottom_margin = p_rec_kandooreport.bottom_margin

	IF p_rec_kandooreport.left_margin IS NULL THEN
		LET p_rec_kandooreport.left_margin = 0
	END IF
	LET l_rec_rmsreps.left_margin = p_rec_kandooreport.left_margin

	IF p_rec_kandooreport.right_margin IS NULL THEN
		LET p_rec_kandooreport.right_margin = 0
	END IF
	LET l_rec_rmsreps.right_margin = p_rec_kandooreport.right_margin

	#Read possible argument/url values
	IF get_url_exec_ind() IS NOT NULL THEN
		LET l_rec_rmsreps.exec_ind = get_url_exec_ind()
		LET p_rec_kandooreport.exec_ind = l_rec_rmsreps.exec_ind
	END IF
	
	IF get_url_printnow() IS NOT NULL THEN
		LET l_rec_rmsreps.printnow_flag = get_url_printnow()
	END IF
	IF get_url_printconfig() IS NOT NULL THEN
		LET l_rec_rmsreps.dest_print_text = get_url_printconfig()
	END IF

	

	#Depending on exec_ind, 1=user sees report menu 2=background print with SQL-Where arg, 3=construct followed by print 4=program was called with DATA SQL Query...
	CASE l_rec_rmsreps.exec_ind 
		WHEN "4" 
			LET l_rec_rmsreps.sel_text = get_url_sel_text() --arg_val(3) 

		WHEN "3" #Was always commented - also in original. no idea what this is about 
			# Verify the prochead head entry
			# arg_val(2) = proc_code
			# arg_val(3) = seq_num

		WHEN "2" 
			LET l_rec_rmsreps.report_code = get_url_report_code() --arg_val(2) #INTEGER value

		OTHERWISE #Default: show report menu - User Interaction and local print...
			LET l_rec_rmsreps.exec_ind = "1"
			
			LET l_url_printnow = get_url_printnow()
			CASE l_url_printnow
				WHEN NULL OR "" OR " "
					LET l_rec_rmsreps.printnow_flag = "Y" #DEFAULT - Local print preview and print
				WHEN "Y"
					LET l_rec_rmsreps.printnow_flag = "Y" #Local print preview and print
				WHEN "N"
					LET l_rec_rmsreps.printnow_flag = "N"
				OTHERWISE
					LET l_msg = "rpt_rmsreps_init2()\nInvalid value in rmsreps.exec_ind =", trim(l_rec_rmsreps.exec_ind) 
					CALL fgl_winmessage("Internal 4gl error #3453",l_msg,"ERROR")
			END CASE

	END CASE 

	#--------------------------
	#Create the report_code INT
		WHENEVER SQLERROR CONTINUE
		IF NOT glob_in_trans THEN 
			BEGIN WORK
		END IF

			DECLARE c_get_report_code_rmsparm CURSOR FOR 
			SELECT next_report_num FROM rmsparm 
			WHERE cmpy_code = l_rec_rmsreps.cmpy_code 
			FOR UPDATE 
			OPEN c_get_report_code_rmsparm 
			FETCH c_get_report_code_rmsparm INTO l_report_code 
			IF status = notfound THEN 
				CALL fgl_winmessage("Setup Incorrect - Exit Program",kandoomsg2("G",5004,""),"ERROR") 
				#5004 Report Parameters NOT SET up - Get out
				EXIT program 
			END IF 
			IF l_report_code >= get_settings_maxRmsrepsHistorySize() THEN 
				LET l_report_code = 1 
			END IF 
	
			#Ensure again????, ... a bit strange to me. PK = cmpy_code AND report_code... so, there can only be ONE or NONE
			WHILE true 
				SELECT unique 1 FROM rmsreps 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code  
				AND report_code = l_report_code
				IF status = notfound THEN 
					EXIT WHILE 
				ELSE 
					LET l_report_code = l_report_code + 1 #use the next available report_code number
					IF l_report_code >= glob_rec_settings.maxReportHistorySize THEN #at the end, start from 1 again
					#IF l_report_code >= get_settings_maxRmsrepsHistorySize() THEN #at the end, start from 1 again
						LET l_report_code = 1 
					END IF 
				END IF 
			END WHILE 
	
			#Update next_report_num for the next available report_code id (to be used by the next report)
			
			UPDATE rmsparm 
			SET next_report_num = l_report_code + 1 
			WHERE cmpy_code = l_rec_rmsreps.cmpy_code  
		IF NOT glob_in_trans THEN 
			COMMIT WORK 
		END IF

		LET l_rec_rmsreps.report_code = l_report_code 
		LET l_rec_rmsreps.file_text = trim(l_rec_rmsreps.cmpy_code), ".", trim(l_rec_rmsreps.report_code)

	#-----------------------------------------
	#FINAL validation/check and if NULL, set default values
	IF l_rec_rmsreps.exec_ind IS NULL OR l_rec_rmsreps.exec_ind = " " THEN
		LET l_rec_rmsreps.exec_ind = "1" #menu	
	END IF

	IF l_rec_rmsreps.printnow_flag IS NULL OR l_rec_rmsreps.printnow_flag = " " THEN
		LET l_rec_rmsreps.printnow_flag = "Y" #menu	
	END IF

	IF l_rec_rmsreps.sel_flag IS NULL OR l_rec_rmsreps.sel_flag = " " THEN
		LET l_rec_rmsreps.sel_flag = "N" #Y/N = Print SQL Query WHERE clause in report	
	END IF

	IF l_rec_rmsreps.printonce_flag IS NULL OR l_rec_rmsreps.printonce_flag = " " THEN
		LET l_rec_rmsreps.printonce_flag = "N" #Y/N = Guess, if a report must only be printed once... but I have not seen the corresponding code yet
	END IF

	IF l_rec_rmsreps.dest_print_text IS NULL OR l_rec_rmsreps.dest_print_text = " " THEN
		CALL fgl_winmessage("ERROR","User has no default print configuration configured\nl_rec_rmsreps.dest_print_text IS NULL","ERROR")
	END IF

	IF l_rec_rmsreps.copy_num IS NULL OR l_rec_rmsreps.copy_num = 0 THEN
		LET l_rec_rmsreps.copy_num = 0
	END IF
	
	IF l_rec_rmsreps.start_page IS NULL OR l_rec_rmsreps.start_page = 0 THEN
		LET l_rec_rmsreps.start_page = 1
	END IF

	IF l_rec_rmsreps.align_ind IS NULL OR l_rec_rmsreps.align_ind = " " THEN
		LET l_rec_rmsreps.align_ind = "N" #Y/N = Print SQL Query WHERE clause in report	
	END IF


	#RMS Report code does not exist - start report - need to insert a record
	INSERT INTO rmsreps VALUES (l_rec_rmsreps.*) 
	IF sqlca.sqlcode != 0 THEN 
		LET l_msg = "ERROR: Could not insert RMSREPS record ", trim(l_rec_rmsreps.report_code)
		CALL fgl_winmessage("Internal 4gl error",l_msg,"ERROR")
		LET l_rpt_idx = 0
	ELSE
		LET glob_arr_rec_rpt_rmsreps[l_rpt_idx].* = l_rec_rmsreps.*
		LET l_msg = "RMSREPS record ", trim(l_rec_rmsreps.report_code), " inserted"
		LET glob_arr_rec_rpt_kandooreport[l_rpt_idx].* = p_rec_kandooreport.*
		MESSAGE l_msg
	END IF



--	#Load print code (something for Eric)
--	SELECT * INTO glob_arr_rec_rpt_printcodes[l_rpt_idx].* 
--	FROM printcodes 
--	WHERE print_code = p_inv_printer  -->  Variable 'p_inv_printer' not defined !!!  What is this variable? (albo)  
--	IF status = notfound THEN 
		INITIALIZE glob_arr_rec_rpt_printcodes[l_rpt_idx].* TO NULL 
--	END IF 
		
	RETURN l_rpt_idx
END FUNCTION 


#######################################################################################
# FUNCTION upd_reports2(p_report_code, p_page_num, p_report_width_num, p_page_length_num)
# Set the report file name and
# Updates table rmsreps with report settings
#######################################################################################
FUNCTION rpt_update_rmsreps2(p_rpt_idx) 
	DEFINE p_rpt_idx SMALLINT
	DEFINE l_msg STRING
	DEFINE l_rec_rmsreps RECORD LIKE rmsreps.*
	DEFINE l_ret_success BOOLEAN 

	LET l_rec_rmsreps.* = glob_arr_rec_rpt_rmsreps[p_rpt_idx].*
	IF db_rmsreps_pk_exists(UI_OFF,l_rec_rmsreps.report_code) THEN

		UPDATE rmsreps
		SET rmsreps.* = l_rec_rmsreps.* 
		WHERE report_code = l_rec_rmsreps.report_code 
		AND cmpy_code = l_rec_rmsreps.cmpy_code 

		LET l_ret_success = TRUE
	ELSE #RMS Report code does not exist - start report - need to insert a record
		LET l_msg = "ERROR: Could not update RMSREPS record - NOT Found\n", trim(l_rec_rmsreps.report_code)
		CALL fgl_winmessage("Internal 4gl error",l_msg,"ERROR")
		LET l_ret_success = FALSE
	END IF
	
	RETURN l_ret_success
END FUNCTION 



#########################################################
# FUNCTION rpt_kandooreport_init2(p_report_code_module_id)
#
# This FUNCTION initilises the l_rec_kandooreport & glob_rec_rmsreps records.
# I can still not follow, in what situation there should be a special program argument for this report init function...
#########################################################
FUNCTION rpt_kandooreport_init2(p_arg_report_code) #rpt_kandooreport_init(glob_rec_kandoouser.cmpy_code,getmoduleid(),getmoduleid()) 
	DEFINE p_arg_report_code STRING
	DEFINE l_report_code LIKE kandooreport.report_code # nchar(10),
	DEFINE l_module_id NCHAR(5)
	--DEFINE l_module_short_id NCHAR(3)
	DEFINE l_rec_kandooreport RECORD LIKE kandooreport.*
	DEFINE l_rec_kandooreport_dev_test RECORD LIKE kandooreport.*
	--DEFINE l_language_code LIKE kandoouser.language_code 
	DEFINE l_tmpmsg STRING 
	DEFINE l_msgresp LIKE language.yes_flag
	DEFINE i SMALLINT 
	DEFINE l_rpt_template_insert_required BOOLEAN
	DEFINE l_rpt_template_not_found BOOLEAN
	DEFINE l_ret_success BOOLEAN
	--DEFINE l_country_code LIKE country.country_code

	DEFINE l_url_exec_ind LIKE kandooreport.exec_ind
	DEFINE l_msg STRING

	LET l_module_id = getmoduleid()
#	LET l_module_short_id = l_module_id[1,5]  #rms only used char(4) now (5) module names

	IF p_arg_report_code.getLength() < 3 OR p_arg_report_code.getLength() > 10 THEN
		LET l_msg = "FUNCTION rpt_kandooreport_init2(p_arg_report_code=", trim(p_arg_report_code), ")\nReportCode can not be NULL OR < Char(3) and no longer than CHAR(10)"
		CALL fgl_winmessage("Internal 4gl error",l_msg, "ERROR")
	END IF
	
	IF p_arg_report_code IS NULL THEN
		LET p_arg_report_code = l_module_id
	END IF
	LET l_report_code	= p_arg_report_code
	

	#NOTE: Currently/Originally, PK was only kandooreport.report_code
	#But this means, All companies and ALL languages must work on the same template
	#Any template updates would be applied to all companies/languages..
	#Needs changing
	#Initialize variables	
	#LET l_rec_kandooreport.country_code = glob_rec_kandoouser.country_code
	#For later when DB-Schema kandooreport has been modernized/updated
	LET l_rec_kandooreport.menupath_text = l_module_id #legazy support
	LET l_rec_kandooreport.report_code = l_report_code #l_report_code #legazy support
	LET l_rec_kandooreport.language_code = glob_rec_kandoouser.language_code 
	#For later: table requires company and country
	LET l_rec_kandooreport.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET l_rec_kandooreport.country_code = glob_rec_kandoouser.country_code 

	#Kandoooption/Feature Settings can allow to change language for report
	LET l_url_exec_ind = get_url_exec_ind()
	IF get_kandoooption_feature_state("GW","D1") = "Y"
	AND (l_url_exec_ind = 0 OR l_url_exec_ind = 1 OR l_url_exec_ind IS NULL) THEN 

		OPEN WINDOW w_rpt_language_dialog WITH FORM "U960-rpt-language-dialog"
		CALL windecoration_u("U960-rpt-language-dialog")
	
		#Give user the choice to change the language for this report
		#We do not allow CANCEL in this dialog	
		INPUT l_rec_kandooreport.language_code,l_rec_kandooreport.country_code WITHOUT DEFAULTS FROM kandooreport.language_code,kandooreport.country_code ATTRIBUTE(UNBUFFERED)
			BEFORE INPUT
				DISPLAY l_rec_kandooreport.country_code TO country_code #l_rec_kandooreport TO country_code
				DISPLAY l_rec_kandooreport.menupath_text TO module_id
				DISPLAY l_rec_kandooreport.report_code TO report_code_module_id
				CALL dialog.setActionHidden("CANCEL",TRUE) #why do I need it twice
				CALL dialog.setActionHidden("CANCEL","TRUE")
		END INPUT	
		CLOSE WINDOW w_rpt_language_dialog
		--IF int_flag THEN
		--	INITIALIZE l_rec_kandooreport.* TO NULL
		--	RETURN l_rec_kandooreport.*
		--END IF
	ELSE
		LET l_rec_kandooreport.language_code = glob_rec_kandoouser.language_code
		LET l_rec_kandooreport.country_code = glob_rec_kandoouser.country_code
	END IF
	
	IF l_rec_kandooreport.menupath_text != getmoduleid() THEN
		LET l_msg = "Not sure if this is valid\nReport menupath_text != getmoduleid()\n",
				"l_rec_kandooreport.menupath_text=", trim(l_rec_kandooreport.menupath_text), "\n",
				"getmoduleid()=", trim(getmoduleid())				
		CALL fgl_winmessage("Internal 4GL Error",l_msg,"ERROR")
	END IF
	#-----------------------------------------
	# We pull the corresponding report configuration from the DB
	#
	CALL rpt_set_kandooreport_defaults(l_rec_kandooreport.*) RETURNING l_rec_kandooreport_dev_test.*
	IF l_rec_kandooreport_dev_test.report_code IS NULL THEN
		LET l_msg = "Dear Kandoo 4GL Developer, your choosen report has not default kandooreport templated defined\nPlease add it to lib_report_template"
		CALL fgl_winmessage("4GL Dev-Warning - Missing default kandooreport template",l_msg,"INFO")
	END IF		
	
	
	CASE 
		#Criteria company, module code, report_code and specified language
		WHEN db_kandooreport_template_exists(UI_OFF,
				l_rec_kandooreport.cmpy_code,
				l_rec_kandooreport.country_code,
				l_rec_kandooreport.language_code,
				l_rec_kandooreport.menupath_text,
				l_rec_kandooreport.report_code) 
			CALL db_kandooreport_get_rec(UI_OFF,
				l_rec_kandooreport.cmpy_code,
				l_rec_kandooreport.country_code,
				l_rec_kandooreport.language_code,
				l_rec_kandooreport.menupath_text,
				l_rec_kandooreport.report_code) RETURNING l_rec_kandooreport.*
				
			LET l_rpt_template_insert_required = FALSE

		#Not found.. try it with company 99	AND ENGLISH
		WHEN db_kandooreport_template_exists(UI_OFF,
				mastercmpy_get_cmpy_code(l_rec_kandooreport.country_code,"ENG"),
				#glob_rec_kandoouser.country_code, 
				l_rec_kandooreport.country_code,
				"ENG",
				l_rec_kandooreport.menupath_text,
				l_rec_kandooreport.report_code) 
			CALL db_kandooreport_get_rec(UI_OFF,
				mastercmpy_get_cmpy_code(l_rec_kandooreport.country_code,"ENG"),
				#glob_rec_kandoouser.country_code, 
				l_rec_kandooreport.country_code,
				"ENG",
				l_rec_kandooreport.menupath_text,
				l_rec_kandooreport.report_code) RETURNING l_rec_kandooreport.*
				
			LET l_rpt_template_insert_required = TRUE


		#NOT found.. use default 4gl-coded template
		OTHERWISE 
			
			CALL rpt_set_kandooreport_defaults(l_rec_kandooreport.*) RETURNING l_rec_kandooreport.*
			IF l_rec_kandooreport.report_code IS NOT NULL THEN
				LET l_rpt_template_insert_required = TRUE
			ELSE #nothing found... we use some temp values BUT DO NOT SAVE THEM to DB table kandooreport
				LET l_rec_kandooreport.report_code = getmoduleid()
				LET l_rec_kandooreport.menupath_text = getmoduleid()
				LET l_rpt_template_not_found = TRUE
				LET l_rpt_template_insert_required = FALSE
				#LET l_msg = "Report program is operating without module_id/report_code configuration\nReport Template Code:", trim(p_report_code_module_id), "\nnot found in DB or in internal report templates catalogue"
				#CALL fgl_winmessage("Internal Error",l_msg,"ERROR")
				LET l_rec_kandooreport.header_text = getmenuitemlabel(getmoduleid())
				LET l_rec_kandooreport.width_num = 132 
				LET l_rec_kandooreport.length_num = 66 
				LET l_rec_kandooreport.exec_ind = "1" 
				LET l_rec_kandooreport.exec_flag = "Y" 
				LET l_rec_kandooreport.selection_flag = "Y"
				LET l_rec_kandooreport.line1_text = " "
				LET l_rec_kandooreport.line2_text = " "
				LET l_rec_kandooreport.line3_text = " "	 
				LET l_rec_kandooreport.titleedit_flag = "Y"
				#FOR LATER
				LET l_rec_kandooreport.language_code = glob_rec_kandoouser.language_code 
				LET l_rec_kandooreport.cmpy_code = glob_rec_kandoouser.cmpy_code
			END IF		
	END CASE

	IF (l_rec_kandooreport.exec_ind IS NULL) or (l_rec_kandooreport.exec_ind = "0") THEN 
		LET l_rec_kandooreport.exec_ind = 1 #Default is show report menu 
	END IF
	
	IF (l_rec_kandooreport.exec_flag IS NULL) THEN  #Is report background Process compatible 
		LET l_rec_kandooreport.exec_flag="Y" 
	END IF
	IF (l_rec_kandooreport.printnow_flag IS NULL) THEN  #Print directly at the end - local print preview 
		LET l_rec_kandooreport.printnow_flag="Y" 
	END IF	
	IF (l_rec_kandooreport.titleedit_flag IS NULL) THEN  #Allow operator to change report title/header 
		LET l_rec_kandooreport.titleedit_flag="Y" 
	END IF	
	IF (l_rec_kandooreport.rmsdialog_flag IS NULL) THEN  #Show RMS Dialog Settings Box prior to execution
		LET l_rec_kandooreport.rmsdialog_flag="Y"
	END IF	
	
	WHENEVER ERROR STOP
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	IF l_rpt_template_insert_required = TRUE THEN
		#Final check, that record does not exist in DB
		IF NOT db_kandooreport_template_exists(UI_ON,
				l_rec_kandooreport.cmpy_code,
				l_rec_kandooreport.country_code,
				l_rec_kandooreport.language_code,
				l_rec_kandooreport.menupath_text,
				l_rec_kandooreport.report_code) THEN		 
			INSERT INTO kandooreport VALUES (l_rec_kandooreport.*)
			MESSAGE "Inserted new report template"
			--SLEEP 3
		ELSE 
			CALL fgl_winmessage("4GL Error","Something went fully wrong in rpt_kandooreport_init\nFirst, we did not find report template. now when inserting.. we find one.","ERROR")
		END IF 
	ELSE
		IF l_rec_kandooreport.l_report_code IS NULL THEN
			LET l_rec_kandooreport.l_report_code = 0 #can't insert NULL
		END IF
	END IF

	# exec_ind could have been set by program argument
	# We can not set it earlier, otherwise kandooreport table will be update
	#constantly with the program argument exec_ind
	#It will only be set for this session
	LET l_url_exec_ind = get_url_exec_ind()  #!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! I'm not happy with this !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	IF (l_url_exec_ind IS NOT NULL) AND (l_url_exec_ind != 0) THEN
		LET l_rec_kandooreport.exec_ind = l_url_exec_ind
	END IF

	#All operations on kandooreport (DB and glob_rec) are completed for now
	#In the next step/next function, we will initialize the rmsreps record (prog rec AND DB rec)

	RETURN l_rec_kandooreport.*
END FUNCTION 


#########################################################
# FUNCTION rpt_dialog_print2(p_rpt_idx)
#
# We don't need the cmpy and user arguments -they are global based on login security
#
# Derived from original function report6()
#########################################################
FUNCTION rpt_dialog_print2(p_rpt_idx) 
	DEFINE p_rpt_idx SMALLINT #report index
	DEFINE l_rec_printcodes RECORD LIKE printcodes.* 
	DEFINE l_msg STRING
	
	IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].entry_code != glob_rec_kandoouser.sign_on_code THEN --p_kandoouser_sign_on_code THEN 
		IF NOT check_report_auth_with_action(
			p_rpt_idx,
			glob_rec_kandoouser.cmpy_code,
			glob_rec_kandoouser.sign_on_code,
			"P") THEN 
			ERROR " No Authority TO Perform this Action" 
			RETURN false 
		END IF 
	END IF 

	IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].exec_ind = 1 THEN #Only display print dialog when working in attended/menu mode
		#This made no sense, l_rec_printcodes is local scope and at this stage always NULL - changd to global
		IF (glob_arr_rec_rpt_rmsreps[p_rpt_idx].report_width_num > glob_arr_rec_rpt_printcodes[p_rpt_idx].width_num) 
		AND glob_arr_rec_rpt_rmsreps[p_rpt_idx].comp_ind = "Y" THEN #Compress turned on
			LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].comp_ind = "Y" 
		ELSE 
			LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].comp_ind = "N" #Compress turned off
		END IF 
	
		IF rpt_rmsreps_get_dest_print_text(1) IS NULL THEN #0 is special legacy argument
			LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].copy_num = 1
			LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].align_ind = "N" 
			LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].start_page = 1 
			LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].dest_print_text = glob_rec_kandoouser.print_text
			
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num IS NULL 
			OR glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = 0 THEN 
				LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].print_page = 9999
			ELSE
				let glob_arr_rec_rpt_rmsreps[p_rpt_idx].print_page = glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num
			END IF 
			
		END IF 
	
		OPEN WINDOW u115 with FORM "U115" 
		CALL windecoration_u("U115") 
	
		MESSAGE kandoomsg2("U",1045,"") 
		#1045 Enter Print Options - ESC TO Continue
		IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].printonce_flag IS NULL THEN 
			LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].printonce_flag = "N" 
		END IF 
	
		DISPLAY BY NAME glob_arr_rec_rpt_rmsreps[p_rpt_idx].printonce_flag 
	
		INPUT BY NAME 
		glob_arr_rec_rpt_rmsreps[p_rpt_idx].dest_print_text, 
		glob_arr_rec_rpt_rmsreps[p_rpt_idx].copy_num, 
		glob_arr_rec_rpt_rmsreps[p_rpt_idx].comp_ind, 
		glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_length_num, 
		glob_arr_rec_rpt_rmsreps[p_rpt_idx].start_page, 
		glob_arr_rec_rpt_rmsreps[p_rpt_idx].print_page, 
		glob_arr_rec_rpt_rmsreps[p_rpt_idx].align_ind 
		WITHOUT DEFAULTS 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","reptfunc","input-PRINT-OPTIONS") 
	
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
				
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
	
			BEFORE FIELD dest_print_text 
				LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].print_page = 9999
				DISPLAY glob_arr_rec_rpt_rmsreps[p_rpt_idx].print_page TO print_page 
	
			AFTER FIELD dest_print_text 
				SELECT * INTO l_rec_printcodes.* FROM printcodes 
				WHERE print_code = glob_arr_rec_rpt_rmsreps[p_rpt_idx].dest_print_text 
	
				IF status = notfound THEN 
					error" Printer Configuration Not found - Try Window " 
					NEXT FIELD dest_print_text 
				END IF 
	
				IF l_rec_printcodes.device_ind = "2" THEN 
					ERROR l_rec_printcodes.print_code clipped, " IS configured as a Terminal" 
					NEXT FIELD dest_print_text 
				ELSE 
					IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].report_width_num > l_rec_printcodes.width_num THEN 
						LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].comp_ind = "Y" 
					ELSE 
						LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].comp_ind = "N" 
					END IF 
					IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_length_num IS NULL 
					OR glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_length_num = 0 THEN 
						LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_length_num = l_rec_printcodes.length_num 
					END IF 
					DISPLAY BY NAME glob_arr_rec_rpt_rmsreps[p_rpt_idx].comp_ind, 
					glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_length_num 
	
				END IF 
	
			AFTER FIELD page_length_num 
				IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].start_page != 1 THEN 
					IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_length_num = 0 
					OR glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_length_num IS NULL THEN 
						ERROR " Number of lines per page must be entered " 
						NEXT FIELD page_length_num 
					END IF 
				END IF 
	
			AFTER FIELD start_page 
				IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].start_page IS NULL 
				OR glob_arr_rec_rpt_rmsreps[p_rpt_idx].start_page = 0 THEN 
					ERROR " Starting page must be entered " 
					NEXT FIELD start_page 
				END IF 
	
			AFTER FIELD print_page 
				IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].print_page IS NULL THEN 
					LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].print_page = 9999 
					DISPLAY BY NAME glob_arr_rec_rpt_rmsreps[p_rpt_idx].print_page 
	
				END IF 
	
			ON ACTION "LOOKUP" infield (dest_print_text) 
				CALL rpt_rmsreps_set_dest_print_text(1,show_print2(glob_rec_kandoouser.cmpy_code))
				NEXT FIELD dest_print_text 
	
		END INPUT 
	
		CLOSE WINDOW u115 
	
		IF int_flag OR quit_flag THEN 
			LET quit_flag = false 
			LET int_flag = false 
			LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].status_text = "Aborted" 
			LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].status_ind = "I"
			CALL rpt_update_rmsreps2(p_rpt_idx) #Update rmsreps record
			MESSAGE "Printing canceled by user"			 				
			#RETURN false #HuHo: Not sure what we should do in this situation - report was already generated, just the print dialog was aborted 
		END IF 
	
		IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].align_ind = "Y" THEN 
			LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].print_page = 2 
		END IF 
	
		#Update rmsreps record
		CALL rpt_update_rmsreps2(p_rpt_idx)

	END IF
	
	RETURN true 
END FUNCTION 


#########################################################
# FUNCTION rpt_set_page_num(p_rpt_idx,p_page_num)
#
# Update rms_reps page_num and report header text macro for line 1 
#########################################################
FUNCTION rpt_set_page_num(p_rpt_idx,p_page_num)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_page_num LIKE rmsreps.page_num
	DEFINE l_line1 NCHAR(250) 
	DEFINE l_line_text NCHAR(250) 
	DEFINE l_temp_text NCHAR(20) 
	DEFINE l_msg STRING
	DEFINE l_start_pos SMALLINT

	#Argument validation
	IF p_rpt_idx < 1 OR p_rpt_idx IS NULL THEN
		LET l_msg = "Report INDEX can not be 0 or NULL", "\nFUNCTION rpt_set_page_num(p_rpt_idx=",trim(p_rpt_idx)," , p_page_num=", trim(p_page_num), ")"
		CALL fgl_winmessage("Invalid Report Property #001",l_msg,"error")
		RETURN NULL
	END IF

	IF p_rpt_idx > glob_arr_rec_rpt_rmsreps.getSize() THEN
		LET l_msg = "Report INDEX can not greater than report object array", "\nFUNCTION rpt_set_page_num(p_rpt_idx=",trim(p_rpt_idx)," , p_page_num=", trim(p_page_num), ")"
		CALL fgl_winmessage("Invalid Report Property #002",l_msg,"error")
		RETURN NULL
	END IF
	
	IF p_page_num < 1 OR p_page_num IS NULL THEN
		LET l_msg = "Report page can not be 0 or NULL", "\nFUNCTION rpt_set_page_num(p_rpt_idx=",trim(p_rpt_idx)," , p_page_num=", trim(p_page_num), ")"
		CALL fgl_winmessage("Invalid Report Property #003",l_msg,"error")
		RETURN NULL
	END IF
	
	LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = p_page_num
	LET l_line_text = glob_rec_company.name_text 


	#LINE 1
	LET l_line1 = today 
	LET l_start_pos = ((glob_arr_rec_rpt_rmsreps[p_rpt_idx].report_width_num - length(l_line_text)-4)/2)+1 
	LET l_line1[l_start_pos,glob_arr_rec_rpt_rmsreps[p_rpt_idx].report_width_num] = glob_arr_rec_rpt_rmsreps[p_rpt_idx].cmpy_code," ",l_line_text 
	LET l_temp_text =kandooword("Page", "044") 
	LET l_temp_text =l_temp_text clipped,": ",glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num USING "<<<<" 
	LET l_start_pos = glob_arr_rec_rpt_rmsreps[p_rpt_idx].report_width_num  - length(l_temp_text) + 1 
	LET l_line1[l_start_pos,glob_arr_rec_rpt_rmsreps[p_rpt_idx].report_width_num ] = l_temp_text clipped 
	LET glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 = l_line1

#	CALL rpt_update_rmsreps2(p_rpt_idx)
	
END FUNCTION

#########################################################
# FUNCTION rpt_set_header_footer_line_2_append(p_rpt_idx,p_str_left, p_str_right)
# RETURN VOID
# Appends/Prefixes string argument before/after header line text
# Update line5 text based ond the 3 arguments
#########################################################
FUNCTION rpt_set_header_footer_line_2_append(p_rpt_idx,p_str_left, p_str_right)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_line SMALLINT #header line1-5 
	DEFINE p_str_left STRING
	DEFINE p_str_right STRING
	DEFINE l_line_with_time NCHAR(250)
	DEFINE l_line_X NCHAR(250) 
	DEFINE l_line_text NCHAR(250) 
	DEFINE l_temp_text NCHAR(20) 
	DEFINE l_msg STRING
	DEFINE l_start_pos SMALLINT
	DEFINE l_page_width LIKE rmsreps.report_width_num

	IF p_rpt_idx < 1 OR p_rpt_idx IS NULL THEN
		#must not happen
		CALL fgl_winmessage("Internal 4gl Error","p_rpt_idx = 0/NULL FUNCTION rpt_set_header_footer_line_2_append(p_rpt_idx,p_str_left, p_str_right)","ERROR")
	END IF

	IF p_str_left IS NULL AND p_str_right IS NULL THEN
		LET l_msg = "FUNCTION rpt_set_header_footer_line_2_append(p_rpt_idx,p_str_left, p_str_right) was called with 2 NULL arguments"
		CALL fgl_winmessage("Internal 4gl Error",l_msg,"ERROR")
		RETURN 		
	END IF
	
	LET l_page_width = glob_arr_rec_rpt_rmsreps[p_rpt_idx].report_width_num
	# LINE 2
	# Example:
	# 11:29:56                                         YYYYYYCustomer Summary Aging (Menu AAB)XXXXXX

	LET l_line_text = trim(glob_arr_rec_rpt_rmsreps[p_rpt_idx].report_text), 
	" (", trim(kandooword("Menu", "043")), 
	" ",trim(getmoduleid()), #	" ",trim(glob_arr_rec_rpt_rmsreps[p_rpt_idx].report_pgm_text), 
	")" 
	
	IF p_str_left IS NOT NULL THEN
		LET l_line_text = trim(p_str_left) , l_line_text
	END IF

	IF p_str_right IS NOT NULL THEN
		LET l_line_text = trim(l_line_text) , " - ", trim(p_str_right)
	END IF

	LET l_start_pos = ((l_page_width - length(l_line_text))/2)+1
	
	
	LET l_line_text[l_start_pos,l_page_width] = l_line_text clipped	
	
	LET l_line_with_time = time 
	LET l_line_with_time[l_start_pos,l_page_width] = l_line_text clipped 
	LET glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 = l_line_with_time
	
END FUNCTION

#########################################################
# FUNCTION rpt_set_header_footer_line_x(p_rpt_idx,p_line,p_str_left, p_str_center, p_str_right)
#
# Update line5 text based ond the 3 arguments
#########################################################
FUNCTION rpt_set_header_footer_line_x(p_rpt_idx,p_line,p_str_left, p_str_center, p_str_right)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_line SMALLINT #header line1-5 
	DEFINE p_str_left STRING
	DEFINE p_str_center STRING
	DEFINE p_str_right STRING
	
	DEFINE p_page_num LIKE rmsreps.page_num
	DEFINE l_line_X NCHAR(250) 
	DEFINE l_line_text NCHAR(250) 
	DEFINE l_temp_text NCHAR(20) 
	DEFINE l_msg STRING
	DEFINE l_start_pos SMALLINT

	#Argument validation
	IF p_rpt_idx < 1 OR p_rpt_idx IS NULL THEN
		LET l_msg = "Report INDEX can not be 0 or NULL", "\nFUNCTION rpt_set_page_num(p_rpt_idx=",trim(p_rpt_idx),"p_page_num=", trim(p_page_num), ")"
		CALL fgl_winmessage("Invalid Report Property #004",l_msg,"error")
		RETURN NULL
	END IF

	IF p_rpt_idx > glob_arr_rec_rpt_rmsreps.getSize() THEN
		LET l_msg = "Report INDEX can not greater than report object array", "\nFUNCTION rpt_set_page_num(p_rpt_idx=",trim(p_rpt_idx),"p_page_num=", trim(p_page_num), ")"
		CALL fgl_winmessage("Invalid Report Property #005",l_msg,"error")
		RETURN NULL
	END IF
	
	IF p_page_num < 1 OR p_page_num IS NULL THEN
		LET l_msg = "Report page can not be 0 or NULL", "\nFUNCTION rpt_set_page_num(p_rpt_idx=",trim(p_rpt_idx),"p_page_num=", trim(p_page_num), ")"
		CALL fgl_winmessage("Invalid Report Property #006 ",l_msg,"error")
		RETURN NULL
	END IF
	
	LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = p_page_num
	LET l_line_text = glob_rec_company.name_text 


	#LINE 5
	LET l_line_X = p_str_left 
	LET l_start_pos = ((glob_arr_rec_rpt_rmsreps[p_rpt_idx].report_width_num - length(l_line_text)-4)/2)+1 
	LET l_line_X[l_start_pos,glob_arr_rec_rpt_rmsreps[p_rpt_idx].report_width_num] = p_str_center 
	LET l_temp_text =kandooword("Page", "044") 
	LET l_temp_text =p_str_right USING "<<<<<<<<<<<<<<<" 
	LET l_start_pos = glob_arr_rec_rpt_rmsreps[p_rpt_idx].report_width_num  - length(l_temp_text) + 1 
	LET l_line_X[l_start_pos,glob_arr_rec_rpt_rmsreps[p_rpt_idx].report_width_num ] = l_temp_text clipped
	
	CASE p_line
		WHEN 1 
			LET glob_arr_rec_rpt_header_footer[p_rpt_idx].line1_text = l_line_X
		WHEN 2 
			LET glob_arr_rec_rpt_header_footer[p_rpt_idx].line2_text = l_line_X
		WHEN 3 
			LET glob_arr_rec_rpt_header_footer[p_rpt_idx].line3_text = l_line_X
		WHEN 4 
			LET glob_arr_rec_rpt_header_footer[p_rpt_idx].line4_text = l_line_X
		WHEN 5 
			LET glob_arr_rec_rpt_header_footer[p_rpt_idx].line5_text = l_line_X
		OTHERWISE
			LET l_msg =  "p_line argument is invalid\n",
			"rpt_set_line_5(p_rpt_idx=",trim(p_rpt_idx), ",p_line=", trim(p_line),
			"p_str_left=", trim(p_str_left), " p_str_center=",trim(p_str_center), "p_str_right=", trim(p_str_right), ")"
			CALL fgl_winmessage("Internal 4gl error",l_msg,"ERROR")
	END CASE

	
END FUNCTION

#########################################################
# FUNCTION rpt_init_report_header_footer(p_rpt_idx) 
#
# Populates Return 4 lines of text for the invoice 
# Line 1-4 Examples
# 04/05/2020                                         KA KandooERP Computer Systems                                             Page: 1   
# 11:29:56                                         Customer Summary Aging (Menu AAB)
# ------------------------------------------------------------------------------------------------------------------------------------
# Derived from original FUNCTION report5()                                                                    
#########################################################
FUNCTION rpt_init_report_header_footer(p_rpt_idx) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_line1 NCHAR(250) 
	DEFINE l_line2 NCHAR(250) 
	DEFINE l_line3 NCHAR(250) 
	DEFINE l_line4 NCHAR(250) 
	DEFINE l_line_text NCHAR(250) 
	DEFINE l_temp_text NCHAR(20) 
	DEFINE l_page_width SMALLINT 
	DEFINE l_start_pos SMALLINT 
	DEFINE l_msg STRING
	
	IF p_rpt_idx IS NULL OR p_rpt_idx < 1 OR p_rpt_idx > glob_arr_rmsreps_idx.getSize() THEN
		LET l_msg = "Function Argument for Array Index out of range\np_rpt_idx=", trim(p_rpt_idx), "\nFunction: rpt_init_report_header_footer(p_rpt_idx)"
		CALL fgl_winmessage("Internal 4GL Error",l_msg,"ERROR")
	END IF

	IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].report_text IS NULL THEN
		LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].report_text = "<Report Header/Title missing in KandooReport>"
	END IF
	LET l_page_width = glob_arr_rec_rpt_rmsreps[p_rpt_idx].report_width_num 
	###
	# Building the first linrmsreps
	LET l_line_text = glob_rec_company.name_text 
{
	Has to be done dynamically in the REPORT BLOCK - otherwise, we havent got the correct page number	
	#LINE 1
	# Example:
	# 04/05/2020                                         KA KandooERP Computer Systems                                             Page: 1
	LET l_line1 = today 
	LET l_start_pos = ((glob_arr_rec_rpt_rmsreps[p_rpt_idx].report_width_num - length(l_line_text)-4)/2)+1 
	LET l_line1[l_start_pos,glob_arr_rec_rpt_rmsreps[p_rpt_idx].report_width_num] = glob_arr_rec_rpt_rmsreps[p_rpt_idx].cmpy_code," ",l_line_text 
	LET l_temp_text =kandooword("Page", "044") 
	LET l_temp_text =l_temp_text clipped,": ",glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num USING "<<<<" 
	LET l_start_pos = l_page_width - length(l_temp_text) + 1 
	LET l_line1[l_start_pos,l_page_width] = l_temp_text clipped 
	LET glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 = l_line1
}
	# LINE 2
	# Example:
	# 11:29:56                                         Customer Summary Aging (Menu AAB)
	LET l_line2 = time 
	LET l_temp_text = kandooword("Menu", "043") 
	LET l_line_text = glob_arr_rec_rpt_rmsreps[p_rpt_idx].report_text clipped, 
	" (", l_temp_text clipped, 
	" ",glob_arr_rec_rpt_rmsreps[p_rpt_idx].report_pgm_text clipped, 
	")" 
	LET l_start_pos = ((l_page_width - length(l_line_text))/2)+1 
	LET l_line2[l_start_pos,l_page_width] = l_line_text clipped 
	LET glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 = l_line2
	###

	#LINE 3 - Dashed horizontal line
	# Example:
	# ------------------------------------------------------------------------------------------------------------------------------------
	FOR l_start_pos=1 TO glob_arr_rec_rpt_rmsreps[p_rpt_idx].report_width_num 
		LET l_line3[l_start_pos]="-" 
	END FOR 
	LET glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 = l_line3	

	#LINE 4 - End of report string
	# Example:

	LET l_temp_text = kandooword("END OF REPORT","045") 
	LET l_line_text = "***** ",l_temp_text clipped, 
	" ",glob_arr_rec_rpt_rmsreps[p_rpt_idx].report_pgm_text clipped, 
	" (",glob_arr_rec_rpt_rmsreps[p_rpt_idx].file_text clipped,")", 
	" *****" 
	LET l_start_pos = (l_page_width - length(l_line_text))/2 + 1 
	LET l_line4[l_start_pos,l_page_width] = l_line_text 
	LET glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report = l_line4
	###
	# returning all four lines
	#RETURN l_line1,l_line2,l_line3,l_line4 
END FUNCTION # report_header() 



#########################################################
# FUNCTION rpt_get_report_header_4_text_lines() 
#
# Return 4 lines of text for the invoice 
# Line 1-4 Examples
# 04/05/2020                                         KA KandooERP Computer Systems                                             Page: 1   
# 11:29:56                                         Customer Summary Aging (Menu AAB)
# ------------------------------------------------------------------------------------------------------------------------------------
# Derived from original FUNCTION report5()                                                                    
#########################################################
FUNCTION rpt_get_report_header_footer_4_text_lines(p_rpt_idx) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_line1 NCHAR(250) 
	DEFINE l_line2 NCHAR(250) 
	DEFINE l_line3 NCHAR(250) 
	DEFINE l_line4 NCHAR(250) 
	DEFINE l_line_text NCHAR(250) 
	DEFINE l_temp_text NCHAR(20) 
	DEFINE l_page_width SMALLINT 
	DEFINE l_start_pos SMALLINT 
	DEFINE l_msg STRING
	# Leave this please / DO NOT comment or I'll kill you LOL!"	
	LET l_msg = "Function report5() is only used in none-streamlined reports.\Please inform AR->@HuHo AP->@Alex C. IN->Eric/Alex B. GL->Alex B. UT->Eric\nProgram:", trim(getmoduleid())
	CALL fgl_winmessage("Report not adopted yet",l_msg,"ERROR")
	# EOF - Leave this please / DO NOT comment or I'll kill you LOL!"	

	LET l_page_width = glob_arr_rec_rpt_rmsreps[p_rpt_idx].report_width_num 
	###
	# Building the first linrmsreps
	LET l_line_text = glob_rec_company.name_text 
	
	#LINE 1
	#DATE text
	LET l_line1 = today 
	LET l_start_pos = ((glob_arr_rec_rpt_rmsreps[p_rpt_idx].report_width_num - length(l_line_text)-4)/2)+1 
	LET l_line1[l_start_pos,glob_arr_rec_rpt_rmsreps[p_rpt_idx].report_width_num] = glob_arr_rec_rpt_rmsreps[p_rpt_idx].cmpy_code," ",l_line_text 
	LET l_temp_text =kandooword("Page", "044") 
	LET l_temp_text =l_temp_text clipped,": ",glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num USING "<<<<" 
	LET l_start_pos = l_page_width - length(l_temp_text) + 1 
	LET l_line1[l_start_pos,l_page_width] = l_temp_text clipped 
	
	# LINE 2
	LET l_line2 = time 
	LET l_temp_text = kandooword("Menu", "043") 
	LET l_line_text = glob_arr_rec_rpt_rmsreps[p_rpt_idx].report_text clipped, 
	" (", l_temp_text clipped, 
	" ",glob_arr_rec_rpt_rmsreps[p_rpt_idx].report_pgm_text clipped, 
	")" 
	LET l_start_pos = ((l_page_width - length(l_line_text))/2)+1 
	LET l_line2[l_start_pos,l_page_width] = l_line_text clipped 
	###

	#LINE 3 - Dashed horizontal line
	FOR l_start_pos=1 TO glob_arr_rec_rpt_rmsreps[p_rpt_idx].report_width_num 
		LET l_line3[l_start_pos]="-" 
	END FOR 
	
	#LINE 4 - End of report string
	LET l_temp_text = kandooword("END OF REPORT","045") 
	LET l_line_text = "***** ",l_temp_text clipped, 
	" ",glob_arr_rec_rpt_rmsreps[p_rpt_idx].report_pgm_text clipped, 
	" (",glob_arr_rec_rpt_rmsreps[p_rpt_idx].file_text clipped,")", 
	" *****" 
	LET l_start_pos = (l_page_width - length(l_line_text))/2 + 1 
	LET l_line4[l_start_pos,l_page_width] = l_line_text 
	###
	# returning all four lines
	RETURN l_line1,l_line2,l_line3,l_line4 
END FUNCTION # report_header() 

#########################################################
# FUNCTION rpt_rmsreps_dialog2( p_rpt_idx,p_print_flag)
# RETURN FALSE/TRUE (error)
# Derived/Extracted from report1() 
#########################################################
FUNCTION rpt_rmsreps_dialog2(p_rpt_idx,p_print_flag) 
	DEFINE p_print_flag SMALLINT
	DEFINE p_rpt_idx SMALLINT
	#DEFINE l_rec_procdetl RECORD LIKE procdetl.* 
	DEFINE l_exec_text CHAR(20) 
	DEFINE l_ret_code INTEGER 
	DEFINE l_msg STRING
	DEFINE l_rpt_background_process BOOLEAN #background proccess variable for INPUT 
--	DEFINE l_try_again LIKE language.yes_flag	 
--	DEFINE i SMALLINT


--	MESSAGE kandoomsg2("U",1009,"") 
--	#1009 Enter Report Options - ESC TO Continue
	CASE glob_arr_rec_rpt_kandooreport[p_rpt_idx].exec_ind  #we need to ensure, that compression is not active for direct print
		WHEN 1 #menu mode
			CASE glob_arr_rec_rpt_rmsreps[p_rpt_idx].printnow_flag
				WHEN NULL
					LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].printnow_flag = "Y" #client side direct print
					LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].comp_ind = "N" #compress only for none-direct-print / no client side print
				WHEN "Y" #client side direct print
					LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].printnow_flag = "Y" #client side direct print
					LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].comp_ind = "N" 
				WHEN "N" #no client side direct print
					LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].printnow_flag = "N" #client side direct print
					LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].comp_ind = "Y"
				OTHERWISE
					CALL fgl_winmessage("Internal 4gl Error","rpt_rmsreps_dialog2(p_rpt_idx,p_print_flag)\#48237","ERROR")
			END CASE

			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].titleedit_flag IS NULL THEN
				LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].titleedit_flag = "Y"
			END IF
			
		WHEN 2 #background print / unatended
			LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].printnow_flag = "Y" #client side direct print
			LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].comp_ind = "N" 

		WHEN 3 #CONSTRUCT/DATA Selection ONLY  PS: have not seen it being used yet
			LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].printnow_flag = "N" #client side direct print
			LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].comp_ind = "N" 

		WHEN 4 #Prog was called with url_sel_text  PS: have not seen it being used yet - also have no idea YET how it should be done/make working...
			CASE glob_arr_rec_rpt_rmsreps[p_rpt_idx].printnow_flag
				WHEN NULL
					LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].printnow_flag = "Y" #client side direct print
					LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].comp_ind = "N" 
				WHEN "Y" #client side direct print
					LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].printnow_flag = "Y" #client side direct print
					LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].comp_ind = "N" 
				WHEN "N" #no client side direct print
					LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].printnow_flag = "N" #client side direct print
					LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].comp_ind = "Y"
				OTHERWISE
					CALL fgl_winmessage("Internal 4gl Error","rpt_rmsreps_dialog2(p_rpt_idx,p_print_flag)\#48237","ERROR")
			END CASE

		OTHERWISE
			LET l_msg = "FUNCTION rpt_rmsreps_dialog2(p_rpt_idx,p_print_flag)\#48238"
			LET l_msg = l_msg, "\n", "exec_ind=",trim(glob_arr_rec_rpt_kandooreport[p_rpt_idx].exec_ind) 
			LET l_msg = l_msg, "\n", "p_rpt_idx=",trim(p_rpt_idx)
			LET l_msg = l_msg, "\n", "p_print_flag=",trim(p_print_flag)			
			CALL fgl_winmessage("Internal 4gl Error",l_msg,"ERROR")
			
	END CASE

	CALL rpt_set_is_background_process(FALSE) #was LET glob_rpt_background_process = "N"
	LET l_rpt_background_process = FALSE
	
	IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].rmsdialog_flag != "N" THEN 
		OPEN WINDOW U510 WITH FORM "U510" 
		CALL windecoration_u("U510") 
	
		INPUT 
			glob_arr_rec_rpt_rmsreps[p_rpt_idx].report_text, 
			glob_arr_rec_rpt_rmsreps[p_rpt_idx].exec_ind, 
			glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag, 
			glob_arr_rec_rpt_rmsreps[p_rpt_idx].printnow_flag, 
			glob_arr_rec_rpt_rmsreps[p_rpt_idx].dest_print_text, 
			glob_arr_rec_rpt_rmsreps[p_rpt_idx].report_pgm_text, 
			glob_arr_rec_rpt_kandooreport[p_rpt_idx].exec_flag, 
			l_rpt_background_process, #was glob_rpt_background_process,
			glob_arr_rec_rpt_rmsreps[p_rpt_idx].report_width_num, 
			glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_length_num WITHOUT DEFAULTS 
		FROM
			report_text, 
			exec_ind, 
			sel_flag, 
			printnow_flag, 
			dest_print_text, 
			report_pgm_text, 
			exec_flag, 
			background_process,
			report_width_num, 
			page_length_num 
		ATTRIBUTE(UNBUFFERED)
	
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","reptfunc","input-REPORT-OPTIONS") 
				DISPLAY glob_arr_rec_rpt_rmsreps[p_rpt_idx].report_date TO report_date 
				DISPLAY glob_arr_rec_rpt_rmsreps[p_rpt_idx].report_time TO report_time 
				
				DISPLAY	glob_arr_rec_rpt_kandooreport[p_rpt_idx].l_report_code TO l_report_code
				DISPLAY glob_arr_rec_rpt_kandooreport[p_rpt_idx].l_report_date TO l_report_date 
				DISPLAY glob_arr_rec_rpt_kandooreport[p_rpt_idx].l_report_time TO l_report_time 
				DISPLAY glob_arr_rec_rpt_kandooreport[p_rpt_idx].l_entry_code TO l_entry_code 
				
				IF glob_arr_rec_rpt_kandooreport[p_rpt_idx].exec_flag = "N" THEN
					CALL Dialog.setFieldActive("background_process",FALSE)
				END IF
	
				IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].titleedit_flag = "N" THEN
					CALL Dialog.setFieldActive("report_text",FALSE)
				END IF
	
			ON CHANGE "background_process"
				IF l_rpt_background_process = TRUE THEN
					LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].exec_ind = "2"
				ELSE
					LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].exec_ind = "1"				
				END IF

			ON CHANGE "exec_ind"
				IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].exec_ind = "2" THEN
					LET l_rpt_background_process = TRUE
				ELSE
					LET l_rpt_background_process = FALSE
				END IF

				
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
	
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
	
			AFTER FIELD report_text 
				IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].report_text IS NULL THEN 
					LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].report_text = glob_arr_rec_rpt_kandooreport[p_rpt_idx].header_text 
					DISPLAY BY NAME glob_arr_rec_rpt_rmsreps[p_rpt_idx].report_text 
					ERROR "Report Title can not be empty"
					NEXT FIELD report_text 
				END IF 
	
	
			AFTER FIELD exec_ind 
				LET l_exec_text = kandooword("rmsreps.exec_ind",glob_arr_rec_rpt_rmsreps[p_rpt_idx].exec_ind) 
				IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].exec_ind != "1" AND glob_arr_rec_rpt_kandooreport[p_rpt_idx].exec_flag = "N" THEN 
					LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].exec_ind = "1" #No direct execution = show menu for user (cant have batchprocess but user menu...)
				END IF 
				DISPLAY l_exec_text TO exec_text 
	
			ON CHANGE rpt_background_process
				IF l_rpt_background_process = TRUE THEN #kandooreport configuration can forbid/prohibit background process report generation
					IF glob_arr_rec_rpt_kandooreport[p_rpt_idx].exec_flag = "Y" THEN 
						LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].exec_ind = 2
					ELSE
						CALL fgl_winmessage("Error",kandoomsg2("U",1025,""),"ERROR")
						LET l_rpt_background_process = FALSE
					END IF						
				END IF
				
			AFTER INPUT 
				IF not(int_flag OR quit_flag) THEN 
					IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].exec_ind = 2 THEN 
						IF glob_arr_rec_rpt_kandooreport[p_rpt_idx].exec_flag = "N" THEN 
							CALL fgl_winmessage("Error",kandoomsg2("U",1025,""),"ERROR")		#1025 Unattending Processing NOT permitted
							CALL rpt_set_is_background_process(FALSE)
							CONTINUE INPUT 
						ELSE
							CALL rpt_set_is_background_process(TRUE)
						END IF 
					END IF 
				END IF 
				IF l_rpt_background_process = TRUE THEN
				#?????
				END IF
	
		END INPUT 
		CLOSE WINDOW U510
	
	END IF
 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
			LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].status_text = "Aborted" 
			LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].status_ind = "I"
			CALL rpt_update_rmsreps2(p_rpt_idx) #Update rmsreps record
		RETURN FALSE
	END IF 

	#glob_arr_rec_rpt_kandooreport[p_rpt_idx].exec_ind = 3 = CONSTRUCT/DATA Selection and print or just make it available in rms_reps.. ?
	IF glob_arr_rec_rpt_kandooreport[p_rpt_idx].exec_ind = "3" THEN
		# exec_ind = "3" = ONLY sql query.. but I can not see what happens with it.. it was never called or code completed
		# SET up procdetl FROM rmsreps AND arg_val(2) & arg_val(3)
	ELSE 
		# need TO SELECT kandoouser entry here TO help setup rmsreps record.

		IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].dest_print_text IS NULL THEN
			LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].dest_print_text = glob_rec_kandoouser.print_text
		END IF
		
		IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].report_text IS NULL THEN 
			LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].report_text = "Unknown Report Name" 
		END IF
		 
		IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].report_date IS NULL THEN 
			LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].report_date = today 
		END IF 

		IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text IS NULL THEN 
			LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text = " 1=1 " 
		END IF 

	END IF 

	CALL rpt_update_rmsreps2(p_rpt_idx) #Update changes to DB 

	RETURN TRUE 
END FUNCTION 

#########################################################
# FUNCTION rpt_finish(p_rpt_func_name)
#
# Checks if int_flag is raised OR status_ind = "I"
# and sets the status_text / status_ind accordingly 
#########################################################
FUNCTION rpt_finish(p_rpt_func_name)
	DEFINE p_rpt_func_name NVARCHAR(30)
	DEFINE l_rpt_idx SMALLINT
	
	LET l_rpt_idx = rpt_rmsreps_idx_get_idx(p_rpt_func_name)

	IF int_flag THEN
		CALL fgl_winmessage("Report generation canceled","The report generation was canceled","INFO")
		LET glob_arr_rec_rpt_rmsreps[l_rpt_idx].status_ind = "I"
		LET glob_arr_rec_rpt_rmsreps[l_rpt_idx].status_text = "Aborted"
	ELSE
		IF glob_arr_rec_rpt_rmsreps[l_rpt_idx].status_ind = "I" OR int_flag = TRUE THEN 
			LET glob_arr_rec_rpt_rmsreps[l_rpt_idx].status_text = "Aborted" 
		ELSE 
			LET glob_arr_rec_rpt_rmsreps[l_rpt_idx].status_text = "To Be Printed" 
			LET glob_arr_rec_rpt_rmsreps[l_rpt_idx].status_ind = "A" 
		END IF
	END IF

	MESSAGE "Report - ", trim(glob_arr_rec_rpt_rmsreps[l_rpt_idx].status_text), ": ", trim(glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_text), ": ", trim(rpt_add_path_to_report_file(glob_arr_rec_rpt_rmsreps[l_rpt_idx].file_text))
	
	#---------------------------------------
	# Update history in kandooreport record
	LET glob_arr_rec_rpt_kandooreport[l_rpt_idx].l_report_code = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_code 
	LET glob_arr_rec_rpt_kandooreport[l_rpt_idx].l_report_date = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_date 
	LET glob_arr_rec_rpt_kandooreport[l_rpt_idx].l_report_time = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_time 
	LET glob_arr_rec_rpt_kandooreport[l_rpt_idx].l_entry_code =  glob_arr_rec_rpt_rmsreps[l_rpt_idx].entry_code 

	UPDATE kandooreport 
	SET l_report_code = glob_arr_rec_rpt_kandooreport[l_rpt_idx].l_report_code, 
	l_report_date = glob_arr_rec_rpt_kandooreport[l_rpt_idx].l_report_date, 
	l_report_time = glob_arr_rec_rpt_kandooreport[l_rpt_idx].l_report_time, 
	l_entry_code = glob_arr_rec_rpt_kandooreport[l_rpt_idx].l_entry_code
	WHERE report_code = glob_arr_rec_rpt_kandooreport[l_rpt_idx].report_code 
  AND language_code = glob_arr_rec_rpt_kandooreport[l_rpt_idx].language_code
  #---------------------------------------

	#Update rms-report record
	CALL rpt_update_rmsreps2(l_rpt_idx)	

	#ONLY for DEBUG during report streamlining work for developers and testers
	CALL db_rmsreps_show_record(glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_code)


	#IF query did not produce data for report, do not print

	IF glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_num != 0 THEN #NOT empty report


		#Direct client side / Local Print/Preview
		IF (
			(glob_arr_rec_rpt_rmsreps[l_rpt_idx].exec_ind = "1") 
			OR (glob_arr_rec_rpt_rmsreps[l_rpt_idx].exec_ind = "2")) 
		AND (glob_arr_rec_rpt_rmsreps[l_rpt_idx].printnow_flag = "Y") THEN #menu 
				#CALL direct_print(glob_arr_rec_rpt_rmsreps[l_rpt_idx].*,"screen")
				CALL direct_print_by_rpt_idx(l_rpt_idx,"screen")
		ELSE #Server Side Print
			#---- Optional Compression
			IF (glob_arr_rec_rpt_rmsreps[l_rpt_idx].printnow_flag = "N") AND (glob_arr_rec_rpt_rmsreps[l_rpt_idx].dest_print_text IS NOT NULL) THEN 
				#IF report7(l_rec_rmsreps.cmpy_code,l_rec_rmsreps.report_code) THEN 
				IF glob_arr_rec_rpt_rmsreps[l_rpt_idx].comp_ind = "Y" THEN
					IF rpt_compress_add_printcodes2(l_rpt_idx) THEN
						LET glob_arr_rec_rpt_rmsreps[l_rpt_idx].status_text = "Sent TO Print" 
						#CALL db_rmsreps_set_status_text(UI_OFF,glob_rec_rmsreps.report_code,glob_rec_rmsreps.status_text)
					END IF
				END IF 
			END IF 
	
			#- UPDATE ------------------------	
			CALL rpt_update_rmsreps2(l_rpt_idx) #Update rms-report record	
			CALL rpt_dialog_print2(l_rpt_idx)	
			
			RETURN glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_num
		END IF
	ELSE
			CALL fgl_winmessage("No Data Found","No data found using your filter criteria.\nNo report for printing was created","INFO")
			RETURN 0
			
	END IF

	IF int_flag THEN
		LET glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_num = 0
		LET int_flag = FALSE
	END IF
		
	RETURN glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_num	
END FUNCTION


#########################################################
# FUNCTION rpt_compress_add_printcodes2()
#
# Derived from original function report7()
#########################################################
FUNCTION rpt_compress_add_printcodes2(p_rpt_idx) 
	DEFINE p_rpt_idx SMALLINT
	DEFINE l_rec_printcodes RECORD LIKE printcodes.* 
	DEFINE l_runner CHAR(200) 
	DEFINE l_print_cmd CHAR(300) 
	DEFINE l_del_cmd CHAR(100) 
	DEFINE l_err_message CHAR(50) 
	DEFINE l_ans CHAR(1) 
	DEFINE l_file_name CHAR(25) 
	DEFINE l_file_tmp1 CHAR(25) 
	DEFINE l_file_tmp2 CHAR(25) 
	DEFINE l_file_status SMALLINT 
	DEFINE l_ret_code INTEGER 
	DEFINE l_start_line INTEGER 
	DEFINE l_end_line INTEGER 
	DEFINE l_norm_on CHAR(100) 
	DEFINE l_comp_on CHAR(100) 
	DEFINE l_print_code LIKE printcodes.print_code
	
	LET l_print_code = rpt_rmsreps_get_dest_print_text(p_rpt_idx)
	CALL db_printcodes_get_rec(UI_OFF,glob_arr_rec_rpt_rmsreps[p_rpt_idx].dest_print_text) RETURNING l_rec_printcodes.*

	LET l_file_name = trim(get_settings_reportPath()), "/", glob_arr_rec_rpt_rmsreps[p_rpt_idx].file_text   #glob_arr_rec_rpt_rmsreps[p_rpt_idx].cmpy_code clipped, ".",glob_arr_rec_rpt_rmsreps[p_rpt_idx].report_code USING "<<<<<<<<" 
	LET l_file_tmp1 = l_file_name clipped,".tmp1" 
	LET l_file_tmp2 = l_file_name clipped,".tmp2" 

	IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].start_page = 1 THEN 
		LET l_start_line = 1 
		LET l_end_line = glob_arr_rec_rpt_rmsreps[p_rpt_idx].print_page * glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_length_num 
	ELSE 
		LET l_start_line = (glob_arr_rec_rpt_rmsreps[p_rpt_idx].start_page -1) * glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_length_num + 1 
		LET l_end_line = l_start_line + (glob_arr_rec_rpt_rmsreps[p_rpt_idx].print_page * glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_length_num) -1 
	END IF 

	IF l_end_line > 999999 THEN 
		LET l_end_line = 999999 
	END IF 

	IF l_start_line > 999999 THEN 
		LET l_start_line = 999999 
	END IF 

#	LET l_runner = "sed -n \"",l_start_line using "<<<<<<" clipped,",", 
#	l_end_line USING "<<<<<<" clipped," p\"", 
#	" < ",l_file_name clipped, " > ",l_file_tmp1 clipped," 2>>", trim(get_settings_logFile()) 

#	RUN l_runner 

	CALL afile_status(l_file_tmp1) RETURNING l_file_status 

	CASE l_file_status 
		WHEN 1 
			LET l_err_message = " Report File Does Not Exist - Cannot Print" 
		WHEN 2 
			LET l_err_message = "Report File has Invalid Attributes - Cannot Print" 
		WHEN 4 
			LET l_err_message = " Report File Contains No Data - Cannot Print" 
		OTHERWISE 
			LET l_err_message = NULL 
	END CASE 

	IF l_err_message IS NOT NULL THEN 
		IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].exec_ind = "1" 
		OR glob_arr_rec_rpt_rmsreps[p_rpt_idx].exec_ind = "4" THEN 

			ERROR l_err_message  
			--         prompt "            Any Key TO Continue" FOR CHAR l_ans  -- albo
			--LET l_ans = promptInput(" Any Key TO Continue","",1) -- albo 
			CALL fgl_winmessage("Error",l_err_message,"error") 
			#CLOSE WINDOW w1_errmess
		ELSE 
			LET l_err_message = l_err_message clipped,": Report ", 
			glob_arr_rec_rpt_rmsreps[p_rpt_idx].cmpy_code, 
			".",glob_arr_rec_rpt_rmsreps[p_rpt_idx].report_code USING "<<<<<<<<" 
			CALL errorlog(l_err_message) 
		END IF 

		IF l_file_status = 1 THEN 
			RETURN false 
		END IF 

	END IF 

	IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].align_ind = "Y" THEN 
		LET l_runner = "cat ",l_file_tmp1," | tr \"[!-~]\" \"[X*]\" > ", 
		l_file_tmp2," ; mv ",l_file_tmp2," ",l_file_tmp1," " 
		RUN l_runner 
		## The ASCII sequence of printable characters, starts AT "!"
		## AND ends AT "~". This l_runner relaces them with "X"
	END IF 

	IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].comp_ind = "N" THEN 
		LET l_print_cmd = "F=",l_file_tmp1, 
		";C=",glob_arr_rec_rpt_rmsreps[p_rpt_idx].copy_num USING "<<<<<", 
		";L=",glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_length_num USING "<<<<<", 
		";W=",glob_arr_rec_rpt_rmsreps[p_rpt_idx].report_width_num USING "<<<<<", 
		";",l_rec_printcodes.print_text clipped," 2>>", trim(get_settings_logFile()), 
		"; STATUS=$? ", 
		" ; EXIT $STATUS " 
		LET l_del_cmd = "rm ",l_file_tmp1," " 
	ELSE 
		--#      LET l_comp_on = ascii ASCII_QUOTATION_MARK,
		--#         ascii l_rec_printcodes.compress_1,
		--#         ascii l_rec_printcodes.compress_2,
		--#         ascii l_rec_printcodes.compress_3,
		--#         ascii l_rec_printcodes.compress_4,
		--#         ascii l_rec_printcodes.compress_5,
		--#         ascii l_rec_printcodes.compress_6,
		--#         ascii l_rec_printcodes.compress_7,
		--#         ascii l_rec_printcodes.compress_8,
		--#         ascii l_rec_printcodes.compress_9,
		--#         ascii l_rec_printcodes.compress_10,
		--#         ascii l_rec_printcodes.compress_11,
		--#         ascii l_rec_printcodes.compress_12,
		--#         ascii l_rec_printcodes.compress_13,
		--#         ascii l_rec_printcodes.compress_14,
		--#         ascii l_rec_printcodes.compress_15,
		--#         ascii l_rec_printcodes.compress_16,
		--#         ascii l_rec_printcodes.compress_17,
		--#         ascii l_rec_printcodes.compress_18,
		--#         ascii l_rec_printcodes.compress_19,
		--#         ascii l_rec_printcodes.compress_20, ascii ASCII_QUOTATION_MARK
		--#      LET l_norm_on = ascii ASCII_QUOTATION_MARK,
		--#         ascii l_rec_printcodes.normal_1,
		--#         ascii l_rec_printcodes.normal_2,
		--#         ascii l_rec_printcodes.normal_3,
		--#         ascii l_rec_printcodes.normal_4,
		--#         ascii l_rec_printcodes.normal_5,
		--#         ascii l_rec_printcodes.normal_6,
		--#         ascii l_rec_printcodes.normal_7,
		--#         ascii l_rec_printcodes.normal_8,
		--#         ascii l_rec_printcodes.normal_9,
		--#         ascii l_rec_printcodes.normal_10, ascii ASCII_QUOTATION_MARK

		LET l_runner = "echo ",l_comp_on clipped," > ",l_file_tmp2 clipped, 
		";cat ", l_file_tmp1 clipped, " >> ",l_file_tmp2 clipped, 
		";echo ", l_norm_on clipped, " >> ",l_file_tmp2 clipped, 
		" 2>>", trim(get_settings_logFile())

		RUN l_runner 

		LET l_print_cmd = "F=",l_file_tmp2, 
		" ;C=",glob_arr_rec_rpt_rmsreps[p_rpt_idx].copy_num USING "<<<<<", 
		" ;L=",glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_length_num USING "<<<<<", 
		" ;W=",glob_arr_rec_rpt_rmsreps[p_rpt_idx].report_width_num USING "<<<<<", 
		" ;",l_rec_printcodes.print_text clipped," 2>>", trim(get_settings_logFile()), 
		" ; STATUS=$? " 

		LET l_del_cmd = "rm ",l_file_tmp2, " " 

	END IF 

	RUN l_print_cmd RETURNING l_ret_code 

	IF l_ret_code THEN #Error handler 

		IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].exec_ind = "1" 
		OR glob_arr_rec_rpt_rmsreps[p_rpt_idx].exec_ind = "4" THEN 
			CALL fgl_winmessage("Print Error","An error has occurred during printing.\nCheck PRINT command - Refer Menu U1P!","error") 
		ELSE 
			LET l_err_message = " An error has occurred during printing REPORT " , 
			glob_arr_rec_rpt_rmsreps[p_rpt_idx].cmpy_code, 
			".",glob_arr_rec_rpt_rmsreps[p_rpt_idx].report_code USING "<<<<<<<<" 
			CALL errorlog(l_err_message) 
		END IF 

		RUN l_del_cmd 

		IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].comp_ind = "Y" THEN 
			LET l_del_cmd = "rm ",l_file_tmp1, " " 
			RUN l_del_cmd 
		END IF 

		RETURN false 

	ELSE 

		RUN l_del_cmd 

		IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].comp_ind = "Y" THEN 
			LET l_del_cmd = "rm ",l_file_tmp1, " " 
			RUN l_del_cmd 
		END IF 

		LET glob_arr_rec_rpt_printcodes[p_rpt_idx].* = l_rec_printcodes.* #Add record to corresponding report array
		
		RETURN true 

	END IF 

END FUNCTION 




#########################################################
# FUNCTION rpt_int_flag_handler2(p_rpt_idx) 
# RETURN CANCEL = FALSE CONTINUE = TRUE
# DERIVED by FUNCTION report3(p_text1,p_text2,p_text3)
#########################################################
FUNCTION rpt_int_flag_handler2(p_text1,p_text2,p_text3,p_rpt_idx) 
	DEFINE p_text1 NCHAR(30) #legacy text arg 1
	DEFINE p_text2 NCHAR(30) #legacy text arg 2
	DEFINE p_text3 NCHAR(30) #legacy text arg 3
	DEFINE p_rpt_idx SMALLINT #Report Array index (if it was already created, otherwise it will be 0
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_msg STRING

	IF int_flag THEN
		LET l_msg = "Report aborted by user\n", trim(p_text1), " ",trim(p_text2), " ", trim(p_text3), "\nExit..."  
		CALL fgl_winmessage("Report aborted",l_msg,"INFO")
		LET int_flag = false
		
		IF p_rpt_idx IS NOT NULL AND p_rpt_idx > 0 THEN #before actual START REPORT & no updates/inserts to rmsreps
			LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].status_text = "Aborted" 
			LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].status_ind = "I"
			CALL rpt_update_rmsreps2(p_rpt_idx) #Update rmsreps record		
		END IF
		
		RETURN FALSE #CANCEL SIGNAL - stop/don't CONTINUE (this silly error= true check = continue is from original code)
	ELSE
		RETURN TRUE  #ALL OK.. CONTINUE... no cancel
	END IF

END FUNCTION 




#########################################################
# FUNCTION exec_report(p_rec_rmsreps) 
#
# Some legacy print report
#########################################################
FUNCTION exec_report(p_rec_rmsreps) 
	DEFINE p_rec_rmsreps RECORD LIKE rmsreps.*
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_datetime DATETIME year TO minute 
	DEFINE l_time_text CHAR(20) 
	DEFINE l_suse SMALLINT 
	DEFINE l_fglrun CHAR(30) 
	DEFINE l_run_text CHAR(80) 
	DEFINE l_runner CHAR(200) 

#########################################################
	#Purpose seems to be batch reporting / unattended 
	CALL fgl_winmessage("Needs changing or dumping","Legacy FUNCTION exec_report() \nNeeds changing or dumping!","error")
#########################################################

	IF get_url_report_code() IS NULL THEN
		CALL fgl_winmessage("Invalid Argument","Report Code NULL was used as argument\nExit Program","ERROR")
		EXIT PROGRAM
	END IF

	SELECT * INTO p_rec_rmsreps.* FROM rmsreps 
	WHERE report_code = get_url_report_code()  
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 

	IF status = notfound THEN 
		CALL fgl_winmessage("Invalid Argument","REPORT has been deleted BEFORE running it\nExit Program","ERROR")
		EXIT program ## REPORT has been deleted BEFORE running it 
	END IF 

	LET l_time_text = p_rec_rmsreps.report_date USING "yyyy-mm-dd"," ", p_rec_rmsreps.report_time 
	LET l_datetime = l_time_text 

	IF l_datetime <= CURRENT + 1 units minute THEN 
		LET l_time_text = "now + 1 minutes" 
	ELSE 
		LET l_time_text = p_rec_rmsreps.report_time," ", p_rec_rmsreps.report_date USING "mm/dd/yy" 
	END IF 
	##
	## Build default run text.
	CALL fgl_winmessage("check code here","check code here - RUNNER stuff...","info")
	LET l_suse = false 
	--#    LET l_suse = TRUE
	--#    LET l_fglrun = fgl_getenv("FGLRUN")
	--#    IF length(l_fglrun) = 0 THEN
	--#       LET l_fglrun = 'fglrun'
	--#    END IF
	--#    LET l_run_text = "FGLGUI=0;export FGLGUI;",l_fglrun clipped," ../gprog/",p_rec_rmsreps.report_pgm_text,
	--#               " 2 ",p_rec_rmsreps.report_code using "<<<<<<<<"
	IF l_suse = false THEN 
		LET l_run_text = "fglgo ../prog/",p_rec_rmsreps.report_pgm_text, " 2 ",p_rec_rmsreps.report_code USING "<<<<<<<<" 
	END IF 

	LET l_runner = "echo '",l_run_text clipped,"' | AT ",l_time_text clipped, " 2>> ", trim(get_settings_logFile())  

	RUN l_runner WITHOUT waiting 

END FUNCTION 


{
#########################################################
# FUNCTION report5()
#
# Return 4 lines of text for the invoice 
# Line 1-4 Examples
# 04/05/2020                                         KA KandooERP Computer Systems                                             Page: 1   
# 11:29:56                                         Customer Summary Aging (Menu AAB)
# ------------------------------------------------------------------------------------------------------------------------------------
#                                                                     
#########################################################
FUNCTION report5() 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_line1 NCHAR(150) 
	DEFINE l_line2 NCHAR(150) 
	DEFINE l_line3 NCHAR(150) 
	DEFINE l_line4 NCHAR(150) 
	DEFINE l_line_text NCHAR(115) 
	DEFINE l_temp_text NCHAR(20) 
	DEFINE l_page_width SMALLINT 
	DEFINE l_start_pos SMALLINT 

	LET l_page_width = glob_rec_rmsreps.report_width_num 
	###
	# Building the first linrmsreps
	LET l_line_text = glob_rec_company.name_text 
	
	#LINE 1
	#DATE text
	LET l_line1 = today 
	LET l_start_pos = ((glob_rec_rmsreps.report_width_num - length(l_line_text)-4)/2)+1 
	LET l_line1[l_start_pos,glob_rec_rmsreps.report_width_num] = glob_rec_rmsreps.cmpy_code," ",l_line_text 
	LET l_temp_text =kandooword("Page", "044") 
	LET l_temp_text =l_temp_text clipped,": ",glob_rec_rmsreps.page_num USING "<<<<" 
	LET l_start_pos = l_page_width - length(l_temp_text) + 1 
	LET l_line1[l_start_pos,l_page_width] = l_temp_text clipped 
	
	# LINE 2
	LET l_line2 = time 
	LET l_temp_text = kandooword("Menu", "043") 
	LET l_line_text = glob_rec_rmsreps.report_text clipped, 
	" (", l_temp_text clipped, 
	" ",glob_rec_rmsreps.report_pgm_text clipped, 
	")" 
	LET l_start_pos = ((l_page_width - length(l_line_text))/2)+1 
	LET l_line2[l_start_pos,l_page_width] = l_line_text clipped 
	###

	#LINE 3 - Dashed horizontal line
	FOR l_start_pos=1 TO glob_rec_rmsreps.report_width_num 
		LET l_line3[l_start_pos]="-" 
	END FOR 
	
	#LINE 4 - End of report string
	LET l_temp_text = kandooword("END OF REPORT","045") 
	LET l_line_text = "***** ",l_temp_text clipped, 
	" ",glob_rec_rmsreps.report_pgm_text clipped, 
	" (",glob_rec_rmsreps.file_text clipped,")", 
	" *****" 
	LET l_start_pos = (l_page_width - length(l_line_text))/2 + 1 
	LET l_line4[l_start_pos,l_page_width] = l_line_text 
	###
	# returning all four lines
	RETURN l_line1,l_line2,l_line3,l_line4 
END FUNCTION # report_header() 
}
{
#########################################################
# FUNCTION report6(p_cmpy,p_kandoouser_sign_on_code)
#
# We don't need the cmpy and user arguments -they are global based on login security
#########################################################
FUNCTION report6(p_cmpy,p_kandoouser_sign_on_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code 
	DEFINE l_rec_printcodes RECORD LIKE printcodes.* 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_msg STRING
	# Leave this please / DO NOT comment or I'll kill you LOL!"	
	LET l_msg = "Function report6() is only used in none-streamlined reports.\Please inform AR->@HuHo AP->@Alex C. IN->Eric/Alex B. GL->Alex B. UT->Eric\nProgram:", trim(getmoduleid())
	CALL fgl_winmessage("Report not adopted yet",l_msg,"ERROR")
	# EOF - Leave this please / DO NOT comment or I'll kill you LOL!"	

	IF glob_rec_rmsreps.entry_code != glob_rec_kandoouser.sign_on_code THEN --p_kandoouser_sign_on_code THEN 
		IF NOT check_report_auth_with_action(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,"P") THEN 
			ERROR " No Authority TO Perform this Action" 
			RETURN false 
		END IF 
	END IF 

	#This made no sense, l_rec_printcodes is local scope and at this stage always NULL - changd to global
	IF glob_rec_rmsreps.report_width_num > l_rec_printcodes.width_num 
	AND glob_rec_rmsreps.comp_ind = "Y" THEN 
		LET glob_rec_rmsreps.comp_ind = "Y" 
	ELSE 
		LET glob_rec_rmsreps.comp_ind = "N" 
	END IF 

	IF rpt_rmsreps_get_dest_print_text(1) IS NULL THEN #0 is special legacy argument
		CALL rpt_rmsreps_set_copy_num(1) --LET glob_rec_rmsreps.copy_num = 1 
		CALL rpt_rmsreps_set_align_ind("N") --LET glob_rec_rmsreps.align_ind = "N" 
		CALL rpt_rmsreps_set_start_page(1) --LET glob_rec_rmsreps.start_page = 1 
		CALL rpt_rmsreps_set_dest_print_text(1,glob_rec_kandoouser.print_text ) --LET glob_rec_rmsreps.dest_print_text = glob_rec_kandoouser.print_text 

		
		IF glob_rec_rmsreps.page_num IS NULL 
		OR glob_rec_rmsreps.page_num = 0 THEN 
			LET glob_rec_rmsreps.print_page = 9999
		ELSE
			let glob_rec_rmsreps.print_page = glob_rec_rmsreps.page_num
		END IF 
		
	END IF 

	OPEN WINDOW u115 with FORM "U115" 
	CALL windecoration_u("U115") 

	CALL kandoomsg2("U",1045,"") 

	#1045 Enter Print Options - ESC TO Continue
	IF glob_rec_rmsreps.printonce_flag IS NULL THEN 
		LET glob_rec_rmsreps.printonce_flag = "N" 
	END IF 

	DISPLAY BY NAME glob_rec_rmsreps.printonce_flag 

	INPUT BY NAME glob_rec_rmsreps.dest_print_text, 
	glob_rec_rmsreps.copy_num, 
	glob_rec_rmsreps.comp_ind, 
	glob_rec_rmsreps.page_length_num, 
	glob_rec_rmsreps.start_page, 
	glob_rec_rmsreps.print_page, 
	glob_rec_rmsreps.align_ind 
	WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","reptfunc","input-PRINT-OPTIONS") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
			
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE FIELD dest_print_text 
			CALL rpt_rmsreps_set_print_page(9999)
			DISPLAY rpt_rmsreps_get_print_page() TO print_page 

		AFTER FIELD dest_print_text 
			SELECT * INTO l_rec_printcodes.* FROM printcodes 
			WHERE print_code = glob_rec_rmsreps.dest_print_text 

			IF status = notfound THEN 
				error" Printer Configuration Not found - Try Window " 
				NEXT FIELD dest_print_text 
			END IF 

			IF l_rec_printcodes.device_ind = "2" THEN 
				ERROR l_rec_printcodes.print_code clipped, " IS configured as a Terminal" 
				NEXT FIELD dest_print_text 
			ELSE 
				IF glob_rec_rmsreps.report_width_num > l_rec_printcodes.width_num THEN 
					LET glob_rec_rmsreps.comp_ind = "Y" 
				ELSE 
					LET glob_rec_rmsreps.comp_ind = "N" 
				END IF 
				IF glob_rec_rmsreps.page_length_num IS NULL 
				OR glob_rec_rmsreps.page_length_num = 0 THEN 
					LET glob_rec_rmsreps.page_length_num = l_rec_printcodes.length_num 
				END IF 
				DISPLAY BY NAME glob_rec_rmsreps.comp_ind, 
				glob_rec_rmsreps.page_length_num 

			END IF 

		AFTER FIELD page_length_num 
			IF glob_rec_rmsreps.start_page != 1 THEN 
				IF glob_rec_rmsreps.page_length_num = 0 
				OR glob_rec_rmsreps.page_length_num IS NULL THEN 
					ERROR " Number of lines per page must be entered " 
					NEXT FIELD page_length_num 
				END IF 
			END IF 

		AFTER FIELD start_page 
			IF glob_rec_rmsreps.start_page IS NULL 
			OR glob_rec_rmsreps.start_page = 0 THEN 
				ERROR " Starting page must be entered " 
				NEXT FIELD start_page 
			END IF 

		AFTER FIELD print_page 
			IF glob_rec_rmsreps.print_page IS NULL THEN 
				LET glob_rec_rmsreps.print_page = 9999 
				DISPLAY BY NAME glob_rec_rmsreps.print_page 

			END IF 

		ON ACTION "LOOKUP" infield (dest_print_text) 
			CALL rpt_rmsreps_set_dest_print_text(1,show_print2(p_cmpy))
			NEXT FIELD dest_print_text 

	END INPUT 

	CLOSE WINDOW u115 

	IF int_flag OR quit_flag THEN 
		LET quit_flag = false 
		LET int_flag = false 
		RETURN false 
	END IF 

	IF glob_rec_rmsreps.align_ind = "Y" THEN 
		LET glob_rec_rmsreps.print_page = 2 
	END IF 

	RETURN true 
END FUNCTION 
}
{
#########################################################
# FUNCTION report_7()
#
#
#########################################################
FUNCTION report_7() 
	DEFINE l_rec_printcodes RECORD LIKE printcodes.* 
	DEFINE l_runner CHAR(200) 
	DEFINE l_print_cmd CHAR(300) 
	DEFINE l_del_cmd CHAR(100) 
	DEFINE l_err_message CHAR(50) 
	DEFINE l_ans CHAR(1) 
	DEFINE l_file_name CHAR(25) 
	DEFINE l_file_tmp1 CHAR(25) 
	DEFINE l_file_tmp2 CHAR(25) 
	DEFINE l_file_status SMALLINT 
	DEFINE l_ret_code INTEGER 
	DEFINE l_start_line INTEGER 
	DEFINE l_end_line INTEGER 
	DEFINE l_norm_on CHAR(100) 
	DEFINE l_comp_on CHAR(100) 
	--DEFINE l_thirty_four SMALLINT 
	DEFINE l_print_code LIKE printcodes.print_code
	DEFINE l_msg STRING
	# Leave this please / DO NOT comment or I'll kill you LOL!"	
	LET l_msg = "Function report_7 is only used in none-streamlined reports.\Please inform AR->@HuHo AP->@Alex C. IN->Eric/Alex B. GL->Alex B. UT->Eric\nProgram:", trim(getmoduleid())
	CALL fgl_winmessage("Report not adopted yet",l_msg,"ERROR")
	# EOF - Leave this please / DO NOT comment or I'll kill you LOL!"	
	
	LET l_print_code = rpt_rmsreps_get_dest_print_text(1) #0 is special legacy argument

	CALL db_printcodes_get_rec(UI_OFF,rpt_get_dest_printer()) RETURNING l_rec_printcodes.*

	LET l_file_name = trim(get_settings_reportPath()), "/",glob_rec_rmsreps.cmpy_code clipped, ".",glob_rec_rmsreps.report_code USING "<<<<<<<<" 
	LET l_file_tmp1 = l_file_name clipped,".tmp1" 
	LET l_file_tmp2 = l_file_name clipped,".tmp2" 

	IF glob_rec_rmsreps.start_page = 1 THEN 
		LET l_start_line = 1 
		LET l_end_line = glob_rec_rmsreps.print_page * glob_rec_rmsreps.page_length_num 
	ELSE 
		LET l_start_line = (glob_rec_rmsreps.start_page -1) * glob_rec_rmsreps.page_length_num + 1 
		LET l_end_line = l_start_line + (glob_rec_rmsreps.print_page * glob_rec_rmsreps.page_length_num) -1 
	END IF 

	IF l_end_line > 999999 THEN 
		LET l_end_line = 999999 
	END IF 

	IF l_start_line > 999999 THEN 
		LET l_start_line = 999999 
	END IF 

	LET l_runner = "sed -n \"",l_start_line using "<<<<<<" clipped,",", 
	l_end_line USING "<<<<<<" clipped," p\"", 
	" < ",l_file_name clipped, " > ",l_file_tmp1 clipped," 2>>", trim(get_settings_logFile()) 

	RUN l_runner 

	CALL afile_status(l_file_tmp1) RETURNING l_file_status 

	CASE l_file_status 
		WHEN 1 
			LET l_err_message = " Report File Does Not Exist - Cannot Print" 
		WHEN 2 
			LET l_err_message = "Report File has Invalid Attributes - Cannot Print" 
		WHEN 4 
			LET l_err_message = " Report File Contains No Data - Cannot Print" 
		OTHERWISE 
			LET l_err_message = NULL 
	END CASE 

	IF l_err_message IS NOT NULL THEN 
		IF glob_rec_rmsreps.exec_ind = "1" 
		OR glob_rec_rmsreps.exec_ind = "4" THEN 

			DISPLAY l_err_message at 1,2 
			--         prompt "            Any Key TO Continue" FOR CHAR l_ans  -- albo
			LET l_ans = promptInput(" Any Key TO Continue","",1) -- albo 
			CALL fgl_winbutton("Error",l_err_message,"error") 
			#CLOSE WINDOW w1_errmess
		ELSE 
			LET l_err_message = l_err_message clipped,": Report ", 
			glob_rec_rmsreps.cmpy_code, 
			".",glob_rec_rmsreps.report_code USING "<<<<<<<<" 
			CALL errorlog(l_err_message) 
		END IF 

		IF l_file_status = 1 THEN 
			RETURN false 
		END IF 

	END IF 

	IF glob_rec_rmsreps.align_ind = "Y" THEN 
		LET l_runner = "cat ",l_file_tmp1," | tr \"[!-~]\" \"[X*]\" > ", 
		l_file_tmp2," ; mv ",l_file_tmp2," ",l_file_tmp1," " 
		RUN l_runner 
		## The ASCII sequence of printable characters, starts AT "!"
		## AND ends AT "~". This l_runner relaces them with "X"
	END IF 

	IF glob_rec_rmsreps.comp_ind = "N" THEN 
		LET l_print_cmd = "F=",l_file_tmp1, 
		";C=",glob_rec_rmsreps.copy_num USING "<<<<<", 
		";L=",glob_rec_rmsreps.page_length_num USING "<<<<<", 
		";W=",glob_rec_rmsreps.report_width_num USING "<<<<<", 
		";",l_rec_printcodes.print_text clipped," 2>>", trim(get_settings_logFile()), 
		"; STATUS=$? ", 
		" ; EXIT $STATUS " 
		LET l_del_cmd = "rm ",l_file_tmp1," " 
	ELSE 
		--#      LET l_comp_on = ascii ASCII_QUOTATION_MARK,
		--#         ascii l_rec_printcodes.compress_1,
		--#         ascii l_rec_printcodes.compress_2,
		--#         ascii l_rec_printcodes.compress_3,
		--#         ascii l_rec_printcodes.compress_4,
		--#         ascii l_rec_printcodes.compress_5,
		--#         ascii l_rec_printcodes.compress_6,
		--#         ascii l_rec_printcodes.compress_7,
		--#         ascii l_rec_printcodes.compress_8,
		--#         ascii l_rec_printcodes.compress_9,
		--#         ascii l_rec_printcodes.compress_10,
		--#         ascii l_rec_printcodes.compress_11,
		--#         ascii l_rec_printcodes.compress_12,
		--#         ascii l_rec_printcodes.compress_13,
		--#         ascii l_rec_printcodes.compress_14,
		--#         ascii l_rec_printcodes.compress_15,
		--#         ascii l_rec_printcodes.compress_16,
		--#         ascii l_rec_printcodes.compress_17,
		--#         ascii l_rec_printcodes.compress_18,
		--#         ascii l_rec_printcodes.compress_19,
		--#         ascii l_rec_printcodes.compress_20, ascii ASCII_QUOTATION_MARK
		--#      LET l_norm_on = ascii ASCII_QUOTATION_MARK,
		--#         ascii l_rec_printcodes.normal_1,
		--#         ascii l_rec_printcodes.normal_2,
		--#         ascii l_rec_printcodes.normal_3,
		--#         ascii l_rec_printcodes.normal_4,
		--#         ascii l_rec_printcodes.normal_5,
		--#         ascii l_rec_printcodes.normal_6,
		--#         ascii l_rec_printcodes.normal_7,
		--#         ascii l_rec_printcodes.normal_8,
		--#         ascii l_rec_printcodes.normal_9,
		--#         ascii l_rec_printcodes.normal_10, ascii ASCII_QUOTATION_MARK

		LET l_runner = "echo ",l_comp_on clipped," > ",l_file_tmp2 clipped, 
		";cat ", l_file_tmp1 clipped, " >> ",l_file_tmp2 clipped, 
		";echo ", l_norm_on clipped, " >> ",l_file_tmp2 clipped, 
		" 2>>", trim(get_settings_logFile())

		RUN l_runner 

		LET l_print_cmd = "F=",l_file_tmp2, 
		" ;C=",glob_rec_rmsreps.copy_num USING "<<<<<", 
		" ;L=",glob_rec_rmsreps.page_length_num USING "<<<<<", 
		" ;W=",glob_rec_rmsreps.report_width_num USING "<<<<<", 
		" ;",l_rec_printcodes.print_text clipped," 2>>", trim(get_settings_logFile()), 
		" ; STATUS=$? " 

		LET l_del_cmd = "rm ",l_file_tmp2, " " 

	END IF 

	RUN l_print_cmd RETURNING l_ret_code 

	IF l_ret_code THEN 

		IF glob_rec_rmsreps.exec_ind = "1" 
		OR glob_rec_rmsreps.exec_ind = "4" THEN 
			CALL fgl_winmessage("Print Error","An error has occurred during printing.\nCheck PRINT command - Refer Menu U1P!","error") 
		ELSE 
			LET l_err_message = " An error has occurred during printing REPORT " , 
			glob_rec_rmsreps.cmpy_code, 
			".",glob_rec_rmsreps.report_code USING "<<<<<<<<" 
			CALL errorlog(l_err_message) 
		END IF 

		RUN l_del_cmd 

		IF glob_rec_rmsreps.comp_ind = "Y" THEN 
			LET l_del_cmd = "rm ",l_file_tmp1, " " 
			RUN l_del_cmd 
		END IF 

		RETURN false 

	ELSE 

		RUN l_del_cmd 

		IF glob_rec_rmsreps.comp_ind = "Y" THEN 
			LET l_del_cmd = "rm ",l_file_tmp1, " " 
			RUN l_del_cmd 
		END IF 

		RETURN true 

	END IF 

END FUNCTION 
}

#########################################################
# FUNCTION check_report_auth_with_action(p_cmpy,p_kandoouser_sign_on_code,p_action)
#
#
#########################################################
FUNCTION check_report_auth_with_action(p_rpt_idx,p_cmpy,p_kandoouser_sign_on_code,p_action)
	DEFINE p_rpt_idx SMALLINT 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code 
	DEFINE p_action CHAR(1) 
	DEFINE l_name_text CHAR(30) 
	DEFINE l_temp_sec_ind LIKE kandoouser.security_ind 
	DEFINE l_entered CHAR(20) 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE r_ret_value INTEGER

	SELECT security_ind INTO l_temp_sec_ind FROM kandoouser 
	WHERE cmpy_code = p_cmpy 
	AND sign_on_code = p_kandoouser_sign_on_code 

	IF status = notfound THEN 
		RETURN true 
	END IF 

	IF status = notfound THEN 
		RETURN true 
	END IF 

	IF l_temp_sec_ind < glob_rec_kandoouser.security_ind 
	OR l_temp_sec_ind < glob_arr_rec_rpt_rmsreps[p_rpt_idx].security_ind THEN 
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
	END CASE 

	OPEN WINDOW u129 with FORM "U129" 
	CALL windecoration_u("U129") 

	INPUT l_entered FROM password_text 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","reptfunc","input-pr_entered_1") 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
				LET r_ret_value = false 
				EXIT INPUT 
			END IF 
			IF l_entered = glob_rec_kandoouser.password_text THEN 
				LET r_ret_value = true 
				EXIT INPUT 
			ELSE 
				LET l_msgresp = kandoomsg("U",9002,"") 
				CONTINUE INPUT 
			END IF 
	END INPUT 
	CLOSE WINDOW u129 

	RETURN r_ret_value 

END FUNCTION 


#########################################################
# FUNCTION afile_status(pr_file_name)
#
# returns one ofthe following VALUES
#        1. File NOT found
#        2. No read permission
#        3. No write permission
#        4. File IS Empty
#        5. OTHERWISE
#########################################################
FUNCTION afile_status(p_file_name) 
	DEFINE p_file_name CHAR(60) 
	
	IF NOT os.path.exists(p_file_name) THEN --huho changed TO os.path() methods 
		RETURN 1 
	END IF 

	IF NOT os.path.readable(p_file_name) THEN --huho changed TO os.path() methods 
		RETURN 2 
	END IF 

	IF NOT os.path.writable(p_file_name) THEN --huho changed TO os.path() methods 
		RETURN 3 
	END IF 

	IF NOT os.path.size(p_file_name) THEN --huho changed TO os.path() methods 
		RETURN 4 
	END IF 

	RETURN 5 

	#   LET l_runner = " [ -f ",p_file_name clipped," ] 2>>", trim(get_settings_logFile())"
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


#########################################################
# FUNCTION show_print2(p_cmpy)
#
#
#########################################################
FUNCTION show_print2(p_cmpy) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE l_rec_printcodes RECORD LIKE printcodes.* 
	DEFINE l_arr_printcodes DYNAMIC ARRAY OF 
		RECORD --array[100] OF RECORD 
			print_code LIKE printcodes.print_code, 
			desc_text LIKE printcodes.desc_text, 
			width_num LIKE printcodes.width_num, 
			length_num LIKE printcodes.length_num 
		END RECORD 
	DEFINE l_idx SMALLINT 
	DEFINE l_query_text CHAR(700) 
	DEFINE l_where_text CHAR(500) 
	DEFINE l_msgresp LIKE language.yes_flag 

	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 

	OPEN WINDOW u103 with FORM "U103" 
	CALL windecoration_u("U103") 

	WHILE true 
		CLEAR FORM 
		LET l_msgresp = kandoomsg("U",1001,"") 
		#1001 " Enter Selection Criteria - ESC TO Continue"

		CONSTRUCT BY NAME l_where_text ON print_code, 
		desc_text, 
		width_num, 
		length_num 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","reptfunc","construct-printcodes") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END CONSTRUCT

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_rec_printcodes.print_code = NULL 
			EXIT WHILE 
		END IF 

		LET l_msgresp = kandoomsg("U",1002,"") 
		#1002 " Searching database - please wait"
		LET l_query_text = "SELECT * FROM printcodes ", 
		"WHERE ",l_where_text clipped," ", 
		"ORDER BY print_code" 

		WHENEVER ERROR CONTINUE 

		OPTIONS SQL interrupt ON 

		PREPARE s_printcodes FROM l_query_text 
		DECLARE c_printcodes CURSOR FOR s_printcodes 

		LET l_idx = 0 
		FOREACH c_printcodes INTO l_rec_printcodes.* 
			LET l_idx = l_idx + 1 
			LET l_arr_printcodes[l_idx].print_code = l_rec_printcodes.print_code 
			LET l_arr_printcodes[l_idx].desc_text = l_rec_printcodes.desc_text 
			LET l_arr_printcodes[l_idx].width_num = l_rec_printcodes.width_num 
			LET l_arr_printcodes[l_idx].length_num = l_rec_printcodes.length_num 

		END FOREACH 

		LET l_msgresp=kandoomsg("U",9113,l_idx) 
		#U9113 l_idx records selected


		WHENEVER ERROR stop 

		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 

		LET l_msgresp = kandoomsg("U",1519,"") 
		#1006 " ESC on line TO SELECT - RETURN TO View - F10 TO Add"
--		CALL set_count(l_idx) 

#		INPUT ARRAY l_arr_printcodes WITHOUT DEFAULTS FROM sr_printcodes.* 
		DISPLAY ARRAY l_arr_printcodes TO sr_printcodes.* ATTRIBUTE(UNBUFFERED)
			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","reptfunc","input-arr-printcodes") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			BEFORE ROW 
				LET l_idx = arr_curr()
				LET l_rec_printcodes.print_code = l_arr_printcodes[l_idx].print_code 
				 

			ON KEY (F10) 
				CALL run_prog("U1P","","","","") 
				NEXT FIELD print_code 


			ON ACTION ("ACCEPT","DOUBLECLICK")
				CALL disp_device(l_arr_printcodes[l_idx].print_code) 
				NEXT FIELD print_code 

		END DISPLAY 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		ELSE 
			EXIT WHILE 
		END IF 

	END WHILE 

	CLOSE WINDOW u103 

	RETURN l_rec_printcodes.print_code 
END FUNCTION 


#########################################################
# FUNCTION disp_device(p_printcode)
#
#
#########################################################
FUNCTION disp_device(p_printcode) 
	DEFINE p_printcode LIKE printcodes.print_code 
	DEFINE l_rec_printcodes RECORD LIKE printcodes.* 
	DEFINE l_msgresp LIKE language.yes_flag 

	OPEN WINDOW u102 with FORM "U102" 
	CALL windecoration_u("U102") 

	SELECT * INTO l_rec_printcodes.* 
	FROM printcodes 
	WHERE printcodes.print_code = p_printcode 

	DISPLAY BY NAME l_rec_printcodes.* 

	CALL eventsuspend() 

	CLOSE WINDOW u102 

	LET int_flag = false 
	LET quit_flag = false 
END FUNCTION 


#########################################################
# FUNCTION auto_print(p_printer_text,p_output)
#
#
#########################################################
FUNCTION auto_print(p_printer_text,p_output) 
	DEFINE p_printer_text CHAR(20) 
	DEFINE p_output CHAR(100) 

	IF p_printer_text IS NULL THEN 
		RETURN 
	END IF 

	UPDATE rmsreps 
	SET printnow_flag = "Y", 
	dest_print_text = p_printer_text, 
	start_page = 1, 
	print_page = 9999, 
	copy_num = 1, 
	comp_ind = "N", 
	align_ind = "N" 
	WHERE report_code = glob_rec_rmsreps.report_code 
	AND cmpy_code = glob_rec_rmsreps.cmpy_code 
END FUNCTION 


#########################################################
# FUNCTION printonce2(p_output, p_flag)
#
#
#########################################################
FUNCTION printonce2(p_output,p_flag) 
	DEFINE p_output CHAR(100)
	DEFINE p_flag CHAR(1)
	DEFINE l_cmpy LIKE company.cmpy_code 
	DEFINE l_report_code LIKE rmsreps.report_code 
	DEFINE l_err_message CHAR(60) 
	DEFINE i SMALLINT 
	DEFINE x SMALLINT 

	LET x = length(p_output) 

	FOR i = 12 TO x 
		IF p_output[i,i] = "." THEN 
			LET l_cmpy = p_output[12,i-1] 
			LET l_report_code = p_output[i+1,x] 
			EXIT FOR 
		END IF 
	END FOR 

	GOTO bypass3 

	LABEL recovery3: 
	IF error_recover(l_err_message, status) != "Y" THEN 
		EXIT program 
	END IF 

	LABEL bypass3: 
	WHENEVER ERROR GOTO recovery3 

	IF NOT glob_in_trans THEN 
		BEGIN WORK
	END IF 

		LET l_err_message = "reptfunc.4gl - Update printonce flag" 

		UPDATE rmsreps 
		SET printonce_flag = p_flag 
		WHERE cmpy_code = l_cmpy 
		AND report_code = l_report_code 
	
	IF NOT glob_in_trans THEN 
		COMMIT WORK 
	END IF

	WHENEVER ERROR stop 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

END FUNCTION

#########################################################
# FUNCTION rpt_get_report_file_with_path(p_report_filename)
#
# Take file name as an argument and returns is with the default kandoo report path
#########################################################
FUNCTION rpt_get_report_file_with_path(p_rpt_idx)
	DEFINE p_rpt_idx SMALLINT
	DEFINE l_ret_path_file STRING
	DEFINE l_msg STRING
	
	IF p_rpt_idx IS NULL OR p_rpt_idx < 1 OR p_rpt_idx > glob_arr_rmsreps_idx.getSize() THEN
		LET l_msg = "Function Argument for Array Index out of range\np_rpt_idx=", trim(p_rpt_idx), "\nFunction: rpt_get_report_file_with_path(p_rpt_idx)"
		CALL fgl_winmessage("Internal 4GL Error",l_msg,"ERROR")
	END IF
	
	LET l_ret_path_file = trim(get_settings_reportPath()), "/",trim(glob_rec_company.cmpy_code), "/", trim(glob_arr_rec_rpt_rmsreps[p_rpt_idx].file_text) 
	RETURN l_ret_path_file
END FUNCTION

#########################################################
# FUNCTION rpt_add_path_to_report_file(p_report_filename)
#
# Take file name as an argument and returns is with the default kandoo report path
#########################################################
FUNCTION rpt_add_path_to_report_file(p_report_filename)
	DEFINE p_report_filename LIKE rmsreps.file_text
	DEFINE l_ret_path_file STRING
	IF p_report_filename IS NULL THEN
		CALL fgl_winmessage("4GL_ERROR","rpt_get_report_file_with_path(p_report_file_name) parameter can not be NULL!","error")
	ELSE 
		LET l_ret_path_file = trim(get_settings_reportPath()), "/",trim(glob_rec_company.cmpy_code), "/", trim(p_report_filename) 
	END IF 
	RETURN l_ret_path_file
END FUNCTION

#########################################################
# FUNCTION rpt_report_base_file_name(p_report_filename)
#
# Take report_code as an argument and returns is with leading cmpy_code. -> "cmpy_code.<rmsreps.report_code>"
#########################################################
FUNCTION rpt_report_base_file_name(p_report_code)
	DEFINE p_report_code LIKE rmsreps.report_code
	DEFINE l_ret_report_filename LIKE rmsreps.file_text

	IF p_report_code IS NULL THEN
		CALL fgl_winmessage("4GL_ERROR","FUNCTION rpt_report_base_file_name(p_report_code) parameter can not be NULL!","error")
	ELSE 
		LET l_ret_report_filename = glob_rec_kandoouser.cmpy_code clipped, ".",p_report_code USING "<<<<<<<<"
	END IF 
	RETURN l_ret_report_filename
END FUNCTION

#########################################################
# FUNCTION rpt_report_file_name_and_path_by_report_code(p_report_code)
#
# Take report_code as an argument and returns is with full path including cmpy_code based file name leading cmpy_code. -> "cmpy_code.<rmsreps.report_code>"
#########################################################
FUNCTION rpt_report_file_name_and_path_by_report_code(p_report_code)
	DEFINE p_report_code LIKE rmsreps.report_code
	DEFINE l_ret_path_file STRING

	IF p_report_code IS NULL THEN
		CALL fgl_winmessage("4GL_ERROR","FUNCTION rpt_report_base_file_name(p_report_code) parameter can not be NULL!","error")
	ELSE 
		LET l_ret_path_file = trim(get_settings_reportPath()), "/",trim(glob_rec_company.cmpy_code), "/", trim(rpt_report_base_file_name(p_report_code)) 
	END IF 
	RETURN l_ret_path_file
END FUNCTION




#########################################################
# FUNCTION rpt_choice_print_run_urs(p_report_code)
#	RETURN l_ret_print BOOLEAN #Did user chooose to print
#
# Prompts the user if the report should be printed
#########################################################
FUNCTION rpt_choice_print_run_urs(p_report_code)
	DEFINE p_report_code LIKE rmsreps.report_code
	#DEFINE l_cmd_arg STRING
	DEFINE l_ret_print BOOLEAN
	
	IF promptTF("Print","Do you want to print this report now ?",TRUE) THEN
		#LET l_cmd_arg = "REPORT_CODE=",trim(glob_rec_rmsreps.report_code)
		CALL run_prog_with_url_arg("URS","REPORT_CODE",trim(p_report_code),NULL,NULL,NULL,NULL,NULL,NULL) 
		#CALL run_prog("URS",l_cmd_arg,"","","")
		LET l_ret_print = TRUE
	END IF
	
	RETURN l_ret_print	 
END FUNCTION

##################################################################################################################
##################################################################################################################
##################################################################################################################
##################################################################################################################
##################################################################################################################
#
#
#
# LEGACY !!! Can be removed when we stremlined all reports
#
#
#
##################################################################################################################
##################################################################################################################
##################################################################################################################
##################################################################################################################
##################################################################################################################



{
#########################################################
# FUNCTION report1(p_cmpy,p_kandoouser_sign_on_code,p_print_flag)
#########################################################
FUNCTION report1(p_cmpy,p_kandoouser_sign_on_code,p_print_flag) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code 
	DEFINE p_print_flag SMALLINT
	#DEFINE l_rec_procdetl RECORD LIKE procdetl.* 
	DEFINE l_rec_s_rmsreps RECORD LIKE rmsreps.* #not used ? 
	DEFINE l_current CHAR(30) 
	DEFINE l_exec_text CHAR(20) 
	DEFINE l_runner CHAR(200) 
	DEFINE l_ret_code INTEGER 
	DEFINE l_err_message CHAR(40) 
	DEFINE l_msgresp LIKE language.yes_flag
	DEFINE l_try_again LIKE language.yes_flag	 
	DEFINE i SMALLINT
	DEFINE l_msg STRING

	# Leave this please / DO NOT comment or I'll kill you LOL!"	
	LET l_msg = "Function report1() is only used in none-streamlined reports.\Please inform AR->@HuHo AP->@Alex C. IN->Eric/Alex B. GL->Alex B. UT->Eric\nProgram:", trim(getmoduleid())
	CALL fgl_winmessage("Report not adopted yet",l_msg,"ERROR")
	# EOF - Leave this please / DO NOT comment or I'll kill you LOL!"	


	LET l_current = CURRENT 

	OPEN WINDOW u510 with FORM "U510" 
	CALL windecoration_u("U510") 

	MESSAGE kandoomsg2("U",1009,"") 
	#1009 Enter Report Options - ESC TO Continue
	LET glob_rec_rmsreps.cmpy_code = glob_rec_kandoouser.cmpy_code --p_cmpy 
	LET glob_rec_rmsreps.report_text = glob_rec_kandooreport.header_text 
--	LET glob_rec_rmsreps.status_text = "Scheduled" 
	LET glob_rec_rmsreps.entry_code = glob_rec_kandoouser.sign_on_code  --p_kandoouser_sign_on_code 
	LET glob_rec_rmsreps.security_ind = glob_rec_kandoouser.security_ind 
	LET glob_rec_rmsreps.report_date = today 
	LET glob_rec_rmsreps.report_pgm_text = glob_rec_kandooreport.report_code 
	LET glob_rec_rmsreps.report_time = l_current[12,16] 
	LET glob_rec_rmsreps.report_width_num = glob_rec_kandooreport.width_num 
	LET glob_rec_rmsreps.page_length_num = glob_rec_kandooreport.length_num 
	LET glob_rec_rmsreps.page_num = 0 
	LET glob_rec_rmsreps.status_ind = "S" 

	IF p_print_flag THEN 
		LET glob_rec_rmsreps.printnow_flag = "Y" 
		LET glob_rec_rmsreps.comp_ind = "N" 
	ELSE 
		LET glob_rec_rmsreps.printnow_flag = "N" 
		LET glob_rec_rmsreps.comp_ind = "Y" 
	END IF 

	LET glob_rec_rmsreps.sel_flag = glob_rec_kandooreport.selection_flag 
	LET l_exec_text = kandooword("rmsreps.exec_ind",glob_rec_rmsreps.exec_ind) 
	DISPLAY l_exec_text TO exec_text 

	INPUT BY NAME glob_rec_rmsreps.report_text, 
	glob_rec_rmsreps.exec_ind, 
	glob_rec_rmsreps.report_date, 
	glob_rec_rmsreps.report_time, 
	glob_rec_rmsreps.sel_flag, 
	glob_rec_rmsreps.printnow_flag, 
	glob_rec_rmsreps.dest_print_text, 
	glob_rec_kandooreport.l_report_code, 
	glob_rec_kandooreport.l_report_date, 
	glob_rec_kandooreport.l_report_time, 
	glob_rec_kandooreport.l_entry_code, 
	glob_rec_rmsreps.report_pgm_text, 
	glob_rec_kandooreport.exec_flag, 
	glob_rec_rmsreps.report_width_num, 
	glob_rec_rmsreps.page_length_num WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","reptfunc","input-REPORT-OPTIONS") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER FIELD report_text 
			IF glob_rec_rmsreps.report_text IS NULL THEN 
				LET glob_rec_rmsreps.report_text = glob_rec_kandooreport.header_text 
				DISPLAY BY NAME glob_rec_rmsreps.report_text 

				NEXT FIELD report_text 
			END IF 

		AFTER FIELD report_date 
			IF glob_rec_rmsreps.report_date IS NULL THEN 
				LET glob_rec_rmsreps.report_date = today 
				DISPLAY BY NAME glob_rec_rmsreps.report_date 

				LET l_msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered
				NEXT FIELD report_date 
			END IF 

		AFTER FIELD report_time 
			IF glob_rec_rmsreps.report_time IS NULL THEN 
				LET glob_rec_rmsreps.report_time = l_current[12,16] 
				DISPLAY BY NAME glob_rec_rmsreps.report_time 

				LET l_msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered
				NEXT FIELD report_time 
			ELSE 
				IF glob_rec_rmsreps.report_time[1,2] >= "24" 
				OR glob_rec_rmsreps.report_time[4,5] >= "60" THEN 
					LET l_msgresp = kandoomsg("W",9449,"") 
					#9449 Time NOT in 24 hours FORMAT
					NEXT FIELD report_time 
				END IF 
			END IF 

		AFTER FIELD exec_ind 
			LET l_exec_text = kandooword("rmsreps.exec_ind",glob_rec_rmsreps.exec_ind) 
			IF glob_rec_rmsreps.exec_ind != "1" AND glob_rec_kandooreport.exec_flag = "N" THEN 
				LET glob_rec_rmsreps.exec_ind = "1" 
			END IF 
			DISPLAY l_exec_text TO exec_text 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				IF glob_rec_rmsreps.exec_ind = 2 THEN 
					IF glob_rec_kandooreport.exec_flag = "N" THEN 
						LET l_msgresp = kandoomsg("U",1025,"") 
						#1025 Unattending Processing NOT permitted
						CONTINUE INPUT 
					END IF 
					LET l_runner = "at -l", " 2>/dev/NULL 1>/dev/NULL" 
					RUN l_runner RETURNING l_ret_code 
					IF l_ret_code THEN 
						LET l_msgresp = kandoomsg("U",1025,"") 
						#1025 Unattended processing NOT permitted
						CONTINUE INPUT 
					END IF 
				END IF 
				IF glob_rec_rmsreps.printnow_flag = 'Y' THEN 
					IF NOT report6(p_cmpy,p_kandoouser_sign_on_code) THEN 
						CONTINUE INPUT 
					END IF 
				END IF 
			END IF 



	END INPUT 

	CLOSE WINDOW u510 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 

	IF glob_rec_rmsreps.exec_ind = "3" THEN 
		##
		## SET up procdetl FROM rmsreps AND arg_val(2) & arg_val(3)
		##
		#LET l_rec_procdetl.cmpy_code = p_cmpy 
		#LET l_rec_procdetl.menu_code = glob_rec_rmsreps.report_code 
		#LET l_rec_procdetl.run_ind = glob_rec_rmsreps.exec_ind 
		#LET l_rec_procdetl.report_text = glob_rec_rmsreps.report_text 
		#LET l_rec_procdetl.sel_text = glob_rec_rmsreps.sel_text 
	ELSE 
		##
		## need TO SELECT kandoouser entry here TO help setup rmsreps record.
		##
		GOTO bypass 

		LABEL recovery: 
		LET l_try_again = error_recover(l_err_message, status) 
		IF l_try_again != "Y" THEN 
			RETURN false 
		END IF 

		LABEL bypass: 
		WHENEVER ERROR GOTO recovery 
		BEGIN WORK 
			DECLARE c_rmsparm CURSOR FOR 
			SELECT next_report_num FROM rmsparm 
			WHERE cmpy_code = p_cmpy 
			FOR UPDATE 

			OPEN c_rmsparm 
			FETCH c_rmsparm INTO glob_rec_rmsreps.report_code 

			IF status = notfound THEN 
				CALL fgl_winmessage("Report Parameters NOT SET up", kandoomsg2("G",5004,""),"ERROR") 
				#5004 Report Parameters NOT SET up - Get out
			END IF 

			IF glob_rec_rmsreps.report_code >= get_settings_maxRmsrepsHistorySize() THEN 
				LET glob_rec_rmsreps.report_code = 1 
			END IF 

			WHILE true 
				SELECT unique 1 FROM rmsreps 
				WHERE cmpy_code = p_cmpy 
				AND report_code = glob_rec_rmsreps.report_code 
				IF status = notfound THEN 
					EXIT WHILE 
				ELSE 
					LET glob_rec_rmsreps.report_code = glob_rec_rmsreps.report_code + 1 

					IF glob_rec_rmsreps.report_code >= get_settings_maxRmsrepsHistorySize() THEN 
						LET glob_rec_rmsreps.report_code = 1 
					END IF 

				END IF 

			END WHILE 

			UPDATE rmsparm 
			SET next_report_num = glob_rec_rmsreps.report_code + 1 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 

		COMMIT WORK 
		WHENEVER ERROR stop 

		LET glob_rec_rmsreps.dest_print_text = glob_rec_kandoouser.print_text
		#LET glob_rec_rmsreps.file_text = trim(get_settings_reportPath()), "/",p_cmpy clipped, ".",glob_rec_rmsreps.report_code USING "<<<<<<<<" 
		LET glob_rec_rmsreps.file_text = p_cmpy clipped, ".",glob_rec_rmsreps.report_code USING "<<<<<<<<" 

		IF glob_rec_rmsreps.report_text IS NULL THEN 
			LET glob_rec_rmsreps.report_text = "Unknown Report Name" 
		END IF 
		IF glob_rec_rmsreps.report_date IS NULL THEN 
			LET glob_rec_rmsreps.report_date = today 
		END IF 
		IF glob_rec_rmsreps.report_time IS NULL THEN 
			LET l_current = CURRENT 
			LET glob_rec_rmsreps.report_time = l_current[12,19] 
		END IF 
		IF glob_rec_rmsreps.sel_text IS NULL THEN 
			LET glob_rec_rmsreps.sel_text = "1=1" 
		END IF 
		
		INSERT INTO rmsreps VALUES (glob_rec_rmsreps.*) 
	END IF 
	RETURN true 
END FUNCTION 
}
{

#########################################################
# FUNCTION report1_no_io(p_cmpy,p_kandoouser_sign_on_code,p_print_flag)
#
# This FUNCTION accepts run parameters AND creates an entry INTO the
# rmsreps table (exec_ind = 1) OR procdetl table (exec_ind = 3)
#########################################################
FUNCTION report1_no_io(p_cmpy,p_kandoouser_sign_on_code,p_print_flag) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code 
	DEFINE p_print_flag SMALLINT 
	DEFINE l_rec_rmsparm RECORD LIKE rmsparm.* 
	#DEFINE l_rec_procdetl RECORD LIKE procdetl.* 
	DEFINE l_rec_s_rmsreps RECORD LIKE rmsreps.* #not used ? 
	DEFINE l_current CHAR(30) 
	DEFINE l_exec_text CHAR(20) 
	DEFINE l_err_message CHAR(40) 
	DEFINE l_try_again LIKE language.yes_flag 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE i SMALLINT
	DEFINE l_msg STRING
	
	# Leave this please / DO NOT comment or I'll kill you LOL!"	
	LET l_msg = "Function report1_no_io() is only used in none-streamlined reports.\Please inform AR->@HuHo AP->@Alex C. IN->Eric/Alex B. GL->Alex B. UT->Eric\nProgram:", trim(getmoduleid())
	CALL fgl_winmessage("Report not adopted yet",l_msg,"ERROR")
	# EOF - Leave this please / DO NOT comment or I'll kill you LOL!"	


	LET glob_rec_rmsreps.cmpy_code = p_cmpy 
	LET glob_rec_rmsreps.report_text = glob_rec_kandooreport.header_text 
	LET glob_rec_rmsreps.status_text = "Scheduled" 
	LET glob_rec_rmsreps.entry_code = glob_rec_kandoouser.sign_on_code  --p_kandoouser_sign_on_code 
	LET glob_rec_rmsreps.security_ind = glob_rec_kandoouser.security_ind  
	LET glob_rec_rmsreps.report_date = today 
	LET glob_rec_rmsreps.report_pgm_text = glob_rec_kandooreport.report_code 
	LET glob_rec_rmsreps.report_time = l_current[12,16] 
	LET glob_rec_rmsreps.report_width_num = glob_rec_kandooreport.width_num 
	LET glob_rec_rmsreps.page_length_num = glob_rec_kandooreport.length_num 
	LET glob_rec_rmsreps.page_num = 0 
	LET glob_rec_rmsreps.status_ind = "S" 

	IF p_print_flag THEN 
		LET glob_rec_rmsreps.printnow_flag = "Y" 
		LET glob_rec_rmsreps.comp_ind = "N" 
	ELSE 
		LET glob_rec_rmsreps.printnow_flag = "N" 
		LET glob_rec_rmsreps.comp_ind = "Y" 
	END IF 

	LET glob_rec_rmsreps.sel_flag = glob_rec_kandooreport.selection_flag 
	LET l_exec_text = kandooword("rmsreps.exec_ind",glob_rec_rmsreps.exec_ind) 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 

	IF glob_rec_rmsreps.exec_ind = "3" THEN 
		##
		## SET up procdetl FROM rmsreps AND arg_val(2) & arg_val(3)
		##
		#LET l_rec_procdetl.cmpy_code = glob_rec_kandoouser.cmpy_code --p_cmpy 
		#LET l_rec_procdetl.menu_code = glob_rec_rmsreps.report_code 
		#LET l_rec_procdetl.run_ind = glob_rec_rmsreps.exec_ind 
		#LET l_rec_procdetl.report_text = glob_rec_rmsreps.report_text 
		#LET l_rec_procdetl.sel_text = glob_rec_rmsreps.sel_text 
	ELSE 
		##
		## need TO SELECT kandoouser entry here TO help setup rmsreps record.
		##

		GOTO bypass 

		LABEL recovery: 
		LET l_try_again = error_recover(l_err_message, status) 
		IF l_try_again != "Y" THEN 
			RETURN false 
		END IF 

		LABEL bypass: 
		WHENEVER ERROR GOTO recovery 

		BEGIN WORK 
			DECLARE c_rmsparm2 CURSOR FOR 
			SELECT next_report_num FROM rmsparm 
			WHERE cmpy_code = p_cmpy 
			FOR UPDATE 

			OPEN c_rmsparm2 
			FETCH c_rmsparm2 INTO glob_rec_rmsreps.report_code 

			IF status = notfound THEN 
				LET l_msgresp=kandoomsg("G",5004,"") 
				#5004 Report Parameters NOT SET up - Get out
			END IF 

			IF glob_rec_rmsreps.report_code >= get_settings_maxRmsrepsHistorySize() THEN 
				LET glob_rec_rmsreps.report_code = 1 
			END IF 

			WHILE true 

				SELECT unique 1 FROM rmsreps 
				WHERE cmpy_code = p_cmpy 
				AND report_code = glob_rec_rmsreps.report_code 
				IF status = notfound THEN 
					EXIT WHILE 
				ELSE 
					LET glob_rec_rmsreps.report_code = glob_rec_rmsreps.report_code + 1 
					IF glob_rec_rmsreps.report_code >= get_settings_maxRmsrepsHistorySize() THEN 
						LET glob_rec_rmsreps.report_code = 1 
					END IF 
				END IF 

			END WHILE 

			UPDATE rmsparm 
			SET next_report_num = glob_rec_rmsreps.report_code + 1 
			WHERE cmpy_code = p_cmpy 

		COMMIT WORK 
		WHENEVER ERROR stop 

		LET glob_rec_rmsreps.file_text = trim(get_settings_reportPath()), "/",p_cmpy clipped, 	".",glob_rec_rmsreps.report_code USING "<<<<<<<<" 
		IF glob_rec_rmsreps.report_text IS NULL THEN 
			LET glob_rec_rmsreps.report_text = "Unknown Report Name" 
		END IF 
		IF glob_rec_rmsreps.report_date IS NULL THEN 
			LET glob_rec_rmsreps.report_date = today 
		END IF 
		IF glob_rec_rmsreps.report_time IS NULL THEN 
			LET l_current = CURRENT 
			LET glob_rec_rmsreps.report_time = l_current[12,19] 
		END IF 
		IF glob_rec_rmsreps.sel_text IS NULL THEN 
			LET glob_rec_rmsreps.sel_text = "1=1" 
		END IF 

		INSERT INTO rmsreps VALUES (glob_rec_rmsreps.*) 

	END IF 

	RETURN true 
END FUNCTION 
}
{

#########################################################
# FUNCTION report2()
#
# All what it does is updating the status_text and status_ind
# TO "In Progress","R"
#########################################################
FUNCTION report2() 
	DEFINE l_msg STRING
	# Leave this please / DO NOT comment or I'll kill you LOL!"	
	LET l_msg = "Function report2() is only used in none-streamlined reports.\Please inform AR->@HuHo AP->@Alex C. IN->Eric/Alex B. GL->Alex B. UT->Eric\nProgram:", trim(getmoduleid())
	CALL fgl_winmessage("Report not adopted yet",l_msg,"ERROR")
	
	#THIS function does not need modernizing.. it needs dumping.. doesn't do anything anymore
	
	
	# EOF - Leave this please / DO NOT comment or I'll kill you LOL!"	
	 
	#Get the report management data stored in rmsreps
	IF db_rmsreps_pk_exists(UI_OFF,glob_rec_rmsreps.report_code) THEN
		CALL db_rmsreps_get_rec(UI_OFF,glob_rec_rmsreps.report_code) RETURNING glob_rec_rmsreps.*
		IF glob_rec_rmsreps.exec_ind = "1" 
		OR glob_rec_rmsreps.exec_ind = "4" THEN 
			## Running in foreground
			--LET l_msgresp=kandoomsg("U",1002,"") 
			#U1002 Searching database - please wait
		#??? guess, this was another plan which never happened
		END IF 
		##############################################
		MESSAGE "Process Report - ", trim(glob_rec_rmsreps.report_text), ": ", trim(glob_rec_rmsreps.file_text)
--		START REPORT rpt_list TO glob_rec_rmsreps.file_text 
		
		CALL db_rmsreps_set_status_text_and_status_ind(UI_ON,	glob_rec_rmsreps.report_code ,"In Progress","R")
		
	ELSE
		LET l_msg = "REPORT ", trim(glob_rec_rmsreps.report_code), " has been deleted BEFORE running it!\nExiting Program " 
		CALL fgl_winmessage("Exit Program",l_msg,"ERROR")
		EXIT program ## REPORT has been deleted BEFORE running it 
	END IF 

END FUNCTION 
}
{
#########################################################
# FUNCTION report3(p_text1,p_text2,p_text3)
#
#
#########################################################
FUNCTION report3(p_text1,p_text2,p_text3) 
	DEFINE p_text1 CHAR(30) 
	DEFINE p_text2 CHAR(30) 
	DEFINE p_text3 CHAR(30) 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_msg STRING
	# Leave this please / DO NOT comment or I'll kill you LOL!"	
	LET l_msg = "Function report3() is only used in none-streamlined reports.\Please inform AR->@HuHo AP->@Alex C. IN->Eric/Alex B. GL->Alex B. UT->Eric\nProgram:", trim(getmoduleid())
	CALL fgl_winmessage("Report not adopted yet",l_msg,"ERROR")
	# EOF - Leave this please / DO NOT comment or I'll kill you LOL!"	

	IF glob_rec_rmsreps.exec_ind = "1" 
	OR glob_rec_rmsreps.exec_ind = "4" THEN 
		## Interactive
		--DISPLAY " Reporting on ",p_text1 AT 1,1
		--DISPLAY "              ",p_text2 AT 2,1
		--DISPLAY "              ",p_text3 AT 3,1
		MESSAGE " Reporting on ",trim(p_text1) 
		IF int_flag OR quit_flag THEN 
			#8503 Continue Report(Y/N)
			IF kandoomsg("U",8503,"") = "N" THEN 
				#9501 Report Terminated
				LET l_msgresp=kandoomsg("U",9501,"") 
				LET glob_rec_rmsreps.status_text = "Aborted" 
				LET glob_rec_rmsreps.status_ind = "I" 
				RETURN false 
			END IF 
		END IF 
	END IF 

	RETURN true 

END FUNCTION 
}
{
#########################################################
# FUNCTION report4()
#
#
#########################################################
FUNCTION report4() 
	DEFINE l_tmpmsg STRING 
	DEFINE l_msg STRING
	# Leave this please / DO NOT comment or I'll kill you LOL!"	
	LET l_msg = "Function report4() is only used in none-streamlined reports.\Please inform AR->@HuHo AP->@Alex C. IN->Eric/Alex B. GL->Alex B. UT->Eric\nProgram:", trim(getmoduleid())
	CALL fgl_winmessage("Report not adopted yet",l_msg,"ERROR")
	# EOF - Leave this please / DO NOT comment or I'll kill you LOL!"	

	IF glob_rec_rmsreps.exec_ind = "1" 
	OR glob_rec_rmsreps.exec_ind = "4" THEN 
		## Interactive
		#CLOSE WINDOW w1_rpt
	END IF 

	IF glob_rec_rmsreps.status_ind = "I" THEN 
		LET glob_rec_rmsreps.status_text = "Aborted" 
	ELSE 
		LET glob_rec_rmsreps.status_text = "To Be Printed" 
		LET glob_rec_rmsreps.status_ind = "A" 
	END IF 

	UPDATE rmsreps 
	SET status_text = glob_rec_rmsreps.status_text, 
	status_ind = glob_rec_rmsreps.status_ind, 
	page_num = glob_rec_rmsreps.page_num 
	WHERE report_code = glob_rec_rmsreps.report_code 
	AND cmpy_code = glob_rec_rmsreps.cmpy_code 
	
	LET glob_rec_kandooreport.l_report_code = glob_rec_rmsreps.report_code 
	LET glob_rec_kandooreport.l_report_date = glob_rec_rmsreps.report_date 
	LET glob_rec_kandooreport.l_report_time = glob_rec_rmsreps.report_time 
	LET glob_rec_kandooreport.l_entry_code = glob_rec_rmsreps.entry_code 

	UPDATE kandooreport 
	SET l_report_code = glob_rec_rmsreps.report_code, 
	l_report_date = glob_rec_rmsreps.report_date, 
	l_report_time = glob_rec_rmsreps.report_time, 
	l_entry_code = glob_rec_rmsreps.entry_code 
	WHERE report_code = glob_rec_kandooreport.report_code 
  AND language_code = glob_rec_kandooreport.language_code
  
	IF glob_rec_rmsreps.printnow_flag = "Y" 
	AND glob_rec_rmsreps.status_ind != "I" THEN 

		IF report_7() THEN 
			LET glob_rec_rmsreps.status_text = "Sent TO Print" 

			UPDATE rmsreps 
			SET status_text = glob_rec_rmsreps.status_text 
			WHERE report_code = glob_rec_rmsreps.report_code 
			AND cmpy_code = glob_rec_rmsreps.cmpy_code 
		END IF 

	END IF 

END FUNCTION 
}