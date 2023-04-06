
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl" 

############################################################
# FUNCTION rpt_get_char_line(p_rpt_idx,p_width,p_symbol)
#
# Note: Most commonly used is 123 and 80 
# The rest will be calculated using an time expensive loop
############################################################
FUNCTION rpt_get_char_line(p_rpt_idx,p_width,p_symbol)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx] 
	DEFINE p_width SMALLINT
	DEFINE p_symbol NCHAR
	DEFINE i SMALLINT
	DEFINE l_ret_char_line STRING
	
	#IF NULL, we use the currently set report_width 
	IF p_width IS NULL THEN
		LET p_width = glob_arr_rec_rpt_rmsreps[p_rpt_idx].report_width_num
	END IF

	#IF width is still NULL, report error
	IF p_width IS NULL THEN
		CALL fgl_winmessage("Report Config Error","Report Width NULL is invalid!","ERROR")
	END IF
	
	
	CASE p_symbol
		WHEN "-"
			CASE p_width
				WHEN "80"
					LET l_ret_char_line =
					"----------------------------------------", 
					"----------------------------------------" 

				WHEN "85" #what a strange width
					LET l_ret_char_line =
					"----------------------------------------", 
					"----------------------------------------",
					"-----" 
				
				WHEN "132"
					LET l_ret_char_line =
					"----------------------------------------", 
					"----------------------------------------", 
					"----------------------------------------", 
					"------------" 
		
				OTHERWISE
					FOR i = 1 TO p_width							
						LET l_ret_char_line = l_ret_char_line CLIPPED, p_symbol
					END FOR
			END CASE

		WHEN "#"
			CASE p_width
				WHEN "14"
					LET l_ret_char_line =
					"=============="
				WHEN "80"
					LET l_ret_char_line =
					"========================================", 
					"========================================"
 
				WHEN "132"
					LET l_ret_char_line =
					"========================================", 
					"========================================", 
					"========================================", 
					"============" 
		
				OTHERWISE
					FOR i = 1 TO p_width							
						LET l_ret_char_line = l_ret_char_line CLIPPED, p_symbol
					END FOR
			END CASE

		
	END CASE
		
	RETURN l_ret_char_line
END FUNCTION


############################################################
# FUNCTION rpt_get_string_with_trailing_char_line(p_rpt_idx,p_string,p_symbol)
#
# Note: Takes the string and adds trailing symbols across the page (report width) 
############################################################
FUNCTION rpt_get_string_with_trailing_char_line(p_rpt_idx,p_string,p_symbol)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx] 
	DEFINE p_string STRING
	DEFINE p_symbol NCHAR
	DEFINE i SMALLINT
	DEFINE l_ret_char_line STRING
	DEFINE l_msg STRING
	DEFINE l_line_start SMALLINT
	#IF NULL, we use the currently set report_width 
	IF p_string IS NULL THEN
		LET l_msg = "NULL Argument pased to FUNCTION\nrpt_get_string_with_trailing_char_line(p_string,p_symbol)"
		CALL fgl_winmessage("Internal 4gl error",l_msg,"ERROR")
		--LET p_width = glob_rec_rmsreps.report_width_num
	ELSE
		LET p_string = p_string.trimRight()
		LET l_ret_char_line = p_string
	END IF

	#IF glob_rec_rmsreps.report_width_num is NULL, report error
	IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].report_width_num IS NULL THEN
		CALL fgl_winmessage("Report Config Error","Report Width NULL is invalid! (glob_rec_rmsreps.report_width_num)","ERROR")
	END IF

	LET l_line_start = p_string.getLength() +1
	 
	FOR i = l_line_start TO glob_arr_rec_rpt_rmsreps[p_rpt_idx].report_width_num
		LET l_ret_char_line = l_ret_char_line.append(p_symbol)
	END FOR

	RETURN l_ret_char_line
END FUNCTION


#########################################################
# FUNCTION rpt_get_align_start_pos(p_rpt_idx,p_alignment,p_string)
#
# Take argument string, calculate h-position to print center
# RETURN l_horizontal_pos, p_string
#########################################################
FUNCTION rpt_get_align_start_pos(p_rpt_idx,p_alignment,p_string)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_alignment SMALLINT
	DEFINE p_string STRING
	DEFINE l_column_start_pos SMALLINT

	CASE p_alignment
		WHEN align_left
			LET l_column_start_pos = 1
			
		WHEN align_center
			LET l_column_start_pos = (glob_arr_rec_rpt_rmsreps[p_rpt_idx].report_width_num/2) - (length (p_string) / 2) + 1

		WHEN align_right
			LET l_column_start_pos = (glob_arr_rec_rpt_rmsreps[p_rpt_idx].report_width_num) - length (p_string)
	
	END CASE
	
	RETURN l_column_start_pos
END FUNCTION

#########################################################
# WILL BE DROPPED !!!!!
# FUNCTION rpt_get_center_start_pos(p_string)
#
# Take argument string, calculate h-position to print center
# RETURN l_horizontal_pos, p_string
#########################################################
FUNCTION rpt_get_center_start_pos(p_rpt_idx,p_string)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_string STRING
	DEFINE l_horizontal_pos SMALLINT

	LET l_horizontal_pos = (glob_arr_rec_rpt_rmsreps[p_rpt_idx].report_width_num - length(p_string))/2

	RETURN l_horizontal_pos
END FUNCTION

#########################################################
# FUNCTION rpt_get_header_text_add_string(p_rpt_idx,p_string,p_fix_string_id)
#
# Take argument string, and wraps generic header texts/variables i.e. pagno
# RETURN l_line1
#########################################################
FUNCTION rpt_get_header_text_add_string(p_rpt_idx,p_string,p_fix_string_id)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_string STRING
	DEFINE p_fix_string_id SMALLINT
	DEFINE l_msg STRING
	DEFINE l_start_pos SMALLINT
	DEFINE l_line1 NCHAR(250)
	DEFINE l_temp_text STRING
	#LINE 1  Example:
	# 04/05/2020                                         KA KandooERP Computer Systems                                             Page: 1

	CASE p_fix_string_id
		WHEN 1 #Company
			LET p_string = p_string CLIPPED, " - ", glob_rec_company.cmpy_code clipped , " ", glob_rec_company.name_text clipped
		WHEN 2 #Report Title
			LET p_string = p_string CLIPPED, " - ", glob_arr_rec_rpt_rmsreps[p_rpt_idx].report_text clipped
		OTHERWISE 
			LET l_msg = "Invalid argument p_fix_string_id=", trim(p_fix_string_id), " in FUNCTION rpt_set_header_text_add_string(p_rpt_idx,p_string,p_fix_string_id)"
			CALL fgl_winmessage("Internal 4gl Error",l_msg,"ERROR")
	END CASE 

 
	LET l_line1 = today 
	LET l_start_pos = ((glob_arr_rec_rpt_rmsreps[p_rpt_idx].report_width_num - length(p_string)-4)/2)+1 
	LET l_line1[l_start_pos,glob_arr_rec_rpt_rmsreps[p_rpt_idx].report_width_num] = p_string 
--	LET l_temp_text =kandooword("Page", "044") 

	LET l_temp_text = kandooword("Page", "044") clipped,": ",glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num USING "<<<<" 
	LET l_start_pos = glob_arr_rec_rpt_rmsreps[p_rpt_idx].report_width_num  - length(l_temp_text) + 1 
	LET l_line1[l_start_pos,glob_arr_rec_rpt_rmsreps[p_rpt_idx].report_width_num] = l_temp_text clipped 

	RETURN l_line1
END FUNCTION