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
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
{ 
#######################################################################################
# FUNCTION upd_rms(p_cmpy, p_kandoouser_sign_on_code, p_dummy1, p_dummy2, p_dummy3, p_report_text)
#
# ??? Some wrapper for FUNCTION init_report which doesn't do anything.... ????
#######################################################################################
FUNCTION upd_rms(p_cmpy,p_kandoouser_sign_on_code,p_rpt_security_ind,p_rpt_width,p_rpt_module_id,p_rpt_title1) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code 
	DEFINE p_rpt_security_ind LIKE kandoouser.security_ind 
	DEFINE p_rpt_width INTEGER
	DEFINE p_rpt_module_id VARCHAR(5)
 	DEFINE p_rpt_title1 LIKE rmsreps.report_text 
	DEFINE r_output CHAR(60) 
	DEFINE l_msg STRING
	# Leave this please / DO NOT comment or I'll kill you LOL!"	
	LET l_msg = "Function upd_rms() is only used in none-streamlined reports.\Please inform AR->@HuHo AP->@Alex C. IN->Eric/Alex B. GL->Alex B. UT->Eric\nProgram:", trim(getmoduleid())
	CALL fgl_winmessage("Report not adopted yet",l_msg,"ERROR")
	# EOF - Leave this please / DO NOT comment or I'll kill you LOL!"	

	#NULL arguments can be used for default values
	IF p_kandoouser_sign_on_code IS NULL THEN
		LET p_kandoouser_sign_on_code = glob_rec_kandoouser.sign_on_code
	END IF
	IF p_cmpy IS NULL THEN
		LET p_cmpy = glob_rec_kandoouser.cmpy_code
	END IF
	IF p_rpt_security_ind IS NULL THEN
		LET p_rpt_security_ind = glob_rec_kandoouser.security_ind
	END IF
	IF p_rpt_width IS NULL OR p_rpt_width = 0 THEN
		LET p_rpt_width = glob_rec_rmsreps.report_width_num #cirular LOL
	END IF
	IF p_rpt_module_id IS NULL THEN
		LET p_rpt_module_id = getmoduleid()
	END IF
	IF p_rpt_title1 IS NULL THEN
		LET p_rpt_title1 = rpt_get_report_header()
	END IF
	
	LET glob_rec_rmsreps.security_ind = p_rpt_security_ind
	LET glob_rec_rmsreps.report_width_num = p_rpt_width
	#LET glob_rec_rmsreps.menupath_text = p_rpt_module_id
	LET glob_rec_rmsreps.cmpy_code = p_cmpy
	LET glob_rec_rmsreps.entry_code = p_kandoouser_sign_on_code
	LET glob_rec_rmsreps.report_text = p_rpt_title1
	
	LET r_output = init_report(p_cmpy,p_kandoouser_sign_on_code,p_rpt_title1) 

	RETURN r_output 
END FUNCTION 
}

{
#######################################################################################
# FUNCTION init_report(p_cmpy, p_kandoouser_sign_on_code, p_rpt_title1)
#
# 1.Validates security
# 2. Get next available report id (report_code) for new report
#
# RETURN report path/filename
#######################################################################################
FUNCTION init_report(p_cmpy,p_kandoouser_sign_on_code,p_rpt_title1) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code 
	DEFINE p_rpt_title1 LIKE rmsreps.report_text 
	#DEFINE #pr_report_width_num LIKE rmsreps.report_width_num
	#DEFINE #pr_report_pgm_text LIKE rmsreps.report_pgm_text
	--DEFINE l_rec_rmsreps RECORD LIKE rmsreps.* 
	#DEFINE #l_rec_rmsparm RECORD LIKE rmsparm.*
	DEFINE l_err_message CHAR(40) 
	DEFINE l_try_again CHAR(1) 
	DEFINE i SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_ret_rpt_output CHAR(60)
	DEFINE l_msg STRING
	DEFINE l_rec_rmsreps RECORD LIKE rmsreps.* #used for SQL INSERT statement

	# Leave this please / DO NOT comment or I'll kill you LOL!"	
	LET l_msg = "Function init_report() is only used in none-streamlined reports.\Please inform AR->@HuHo AP->@Alex C. IN->Eric/Alex B. GL->Alex B. UT->Eric\nProgram:", trim(getmoduleid())
	CALL fgl_winmessage("Report not adopted yet",l_msg,"ERROR")
	# EOF - Leave this please / DO NOT comment or I'll kill you LOL!"	



	#NULL arguments can be used for default values
	IF p_cmpy IS NULL THEN
		LET p_cmpy = glob_rec_kandoouser.cmpy_code
	END IF
	IF p_kandoouser_sign_on_code IS NULL THEN
		LET p_kandoouser_sign_on_code = glob_rec_kandoouser.sign_on_code
	END IF
	IF p_rpt_title1 IS NULL THEN
		LET p_rpt_title1 = rpt_get_report_header()
	END IF

	CALL rpt_set_cmpy_code(p_cmpy)	
	CALL rpt_set_entry_code(p_kandoouser_sign_on_code)
	CALL rpt_set_report_header(p_rpt_title1)
	
	#Get security level of User
	CASE glob_rec_kandoouser.security_ind # @security needs to be completed later
		WHEN NULL
			LET l_msg = "User ", trim(glob_rec_kandoouser.sign_on_code), " could not be authenticated !"
			CALL fgl_winmessage("Authentication Error",l_msg,"Error")
			EXIT PROGRAM		
		#@Eric - your security rules/handler are required here
	END CASE

	#Get next available report id (report_code) for new report

	IF rpt_get_next_report_num() = 0 THEN
		ERROR "Could not retrieve next report code number" 
	END IF
	 
	CALL rpt_set_status_text("To be Printed") 

	CALL rpt_set_date_time(NULL,NULL)
	CALL rpt_set_pgm_text(getmoduleid())
	CALL rpt_get_rmsreps_rec() RETURNING l_rec_rmsreps.*

	INSERT INTO rmsreps VALUES (l_rec_rmsreps.*)
	 
	LET l_ret_rpt_output = trim(get_settings_reportPath()), "/", p_cmpy clipped, ".",glob_rec_rmsreps.report_code clipped USING "<<<<<<<<"
	 
	RETURN l_ret_rpt_output 
END FUNCTION 
}
{
#######################################################################################
# FUNCTION upd_reports(p_report_code, p_page_num, p_report_width_num, p_page_length_num)
# Set the report file name and
# Updates table rmsreps with report settings
#######################################################################################
FUNCTION rpt_update_rmsreps() 
	DEFINE l_cmpy LIKE rmsreps.cmpy_code
	DEFINE l_msg STRING
	DEFINE l_rec_rmsreps RECORD LIKE rmsreps.*
	DEFINE l_ret_success BOOLEAN 

	# Leave this please / DO NOT comment or I'll kill you LOL!"	
	LET l_msg = "Function rpt_update_rmsreps() is only used in none-streamlined reports.\Please inform AR->@HuHo AP->@Alex C. IN->Eric/Alex B. GL->Alex B. UT->Eric\nProgram:", trim(getmoduleid())
	CALL fgl_winmessage("Report not adopted yet",l_msg,"ERROR")
	# EOF - Leave this please / DO NOT comment or I'll kill you LOL!"	

	IF db_rmsreps_pk_exists(UI_OFF,glob_rec_rmsreps.report_code) THEN
--		SELECT * INTO l_rec_rmsreps.* FROM rmsreps 
--		WHERE cmpy_code = l_cmpy 
--		AND report_code = l_rec_rmsreps.report_code 
		#IF TRUE THEN  #this does nothing...
		#END IF

--		WHENEVER SQLERROR CONTINUE
			UPDATE rmsreps 
			SET page_num = glob_rec_rmsreps.page_num, 
			report_width_num = glob_rec_rmsreps.report_width_num, 
			page_length_num = glob_rec_rmsreps.page_length_num 
			WHERE report_code = glob_rec_rmsreps.report_code 
			AND cmpy_code = glob_rec_rmsreps.cmpy_code 
--		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
		
		IF glob_rec_rmsreps.printnow_flag = "Y" 
		AND glob_rec_rmsreps.dest_print_text IS NOT NULL THEN 
			IF report7(glob_rec_rmsreps.cmpy_code,glob_rec_rmsreps.report_code) THEN 

				LET glob_rec_rmsreps.status_text = "Sent TO Print" 
				#CALL db_rmsreps_set_status_text(UI_OFF,glob_rec_rmsreps.report_code,glob_rec_rmsreps.status_text)
		
				UPDATE rmsreps 
				SET * = glob_rec_rmsreps.* 
				WHERE report_code = glob_rec_rmsreps.report_code
				AND cmpy_code = glob_rec_rmsreps.cmpy_code 

				IF sqlca.sqlcode != 0 THEN 
					LET l_msg = "RMSREPS record ", trim(glob_rec_rmsreps.report_code), " updated"
					MESSAGE l_msg
					LET l_ret_success = TRUE			
				ELSE
					LET l_msg = "ERROR: Could not update RMSREPS record ", trim(glob_rec_rmsreps.report_code)
					CALL fgl_winmessage("Internal 4gl error",l_msg,"ERROR")
					LET l_ret_success = FALSE
				END IF

		
			END IF 
		END IF 
		LET l_ret_success = TRUE
	ELSE #RMS Report code does not exist - start report - need to insert a record
		INSERT INTO rmsreps VALUES (glob_rec_rmsreps.*) 
		IF sqlca.sqlcode != 0 THEN 
			LET l_msg = "ERROR: Could not insert RMSREPS record ", trim(glob_rec_rmsreps.report_code)
			CALL fgl_winmessage("Internal 4gl error",l_msg,"ERROR")
			LET l_ret_success = FALSE
		ELSE
			LET l_msg = "RMSREPS record ", trim(glob_rec_rmsreps.report_code), " inserted"
			MESSAGE l_msg
			LET l_ret_success = TRUE			
		END IF
		
	END IF
	
	RETURN l_ret_success
END FUNCTION 
}



{
#######################################################################################
# FUNCTION upd_reports(p_report_code, p_page_num, p_report_width_num, p_page_length_num)
#
# Updates table rmsreps with report settings
#######################################################################################
FUNCTION upd_reports(p_report_code,p_page_num,p_report_width_num,p_page_length_num) 
	DEFINE p_report_code CHAR(20) 
	DEFINE p_page_num LIKE rmsreps.page_num 
	DEFINE p_report_width_num LIKE rmsreps.report_width_num 
	DEFINE p_page_length_num LIKE rmsreps.page_length_num 
	DEFINE l_cmpy LIKE rmsreps.cmpy_code
	DEFINE l_msg STRING
	DEFINE l_rec_rmsreps RECORD LIKE rmsreps.*
	DEFINE l_ret_success BOOLEAN 

	# Leave this please / DO NOT comment or I'll kill you LOL!"	
	LET l_msg = "Function upd_reports() is only used in none-streamlined reports.\Please inform AR->@HuHo AP->@Alex C. IN->Eric/Alex B. GL->Alex B. UT->Eric\nProgram:", trim(getmoduleid())
	CALL fgl_winmessage("Report not adopted yet",l_msg,"ERROR")
	# EOF - Leave this please / DO NOT comment or I'll kill you LOL!"	
	
	#	DEFINE i,x SMALLINT
	#
	#   LET x = length(p_report_code)
	#   FOR i = length(12) TO x
	#      IF p_report_code[i,i] = "." THEN
	#         LET l_cmpy = p_report_code[length(12),i-1]
	#         LET l_rec_rmsreps.report_code = p_report_code[i+1,x]
	#         EXIT FOR
	#      END IF
	#   END FOR
	#
	# huho 01.10.2019 - replaced with
	DISPLAY "RPT_DEBUG ----------------------------------------------"
	DISPLAY "p_report_code = ", trim(p_report_code)
	DISPLAY "p_page_num = ", trim(p_page_num)
	DISPLAY "p_report_width_num = ", trim(p_report_width_num)
	DISPLAY "p_page_length_num = ", trim(p_page_length_num)

		
	IF p_report_code IS NULL THEN
		LET l_msg = "upd_reports() - Argument p_report_code must not be NULL"		
		CALL fgl_winmessage("Internal 4gl Error",l_msg,"error")
		RETURN FALSE
	END IF

	LET l_cmpy = os.path.basename(p_report_code) 
	LET l_rec_rmsreps.report_code = os.path.extension(p_report_code) 

	DISPLAY "l_cmpy = ", trim(l_cmpy)
	DISPLAY "l_rec_rmsreps.report_code = ", trim(l_rec_rmsreps.report_code)

	## DO NOT REMOVE NEXT LINE <Suse> BUG
	IF db_rmsreps_pk_exists(UI_OFF,l_rec_rmsreps.report_code) THEN
--		SELECT * INTO l_rec_rmsreps.* FROM rmsreps 
--		WHERE cmpy_code = l_cmpy 
--		AND report_code = l_rec_rmsreps.report_code 
		#IF TRUE THEN  #this does nothing...
		#END IF

		WHENEVER SQLERROR CONTINUE
			UPDATE rmsreps 
			SET page_num = p_page_num, 
			report_width_num = p_report_width_num, 
			page_length_num = p_page_length_num 
			WHERE report_code = l_rec_rmsreps.report_code 
			AND cmpy_code = l_cmpy 
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
		
		IF l_rec_rmsreps.printnow_flag = "Y" 
		AND l_rec_rmsreps.dest_print_text IS NOT NULL THEN 
			IF report7(l_cmpy,l_rec_rmsreps.report_code) THEN 
				LET l_rec_rmsreps.status_text = "Sent TO Print" 
		
				UPDATE rmsreps 
				SET status_text = l_rec_rmsreps.status_text 
				WHERE report_code = l_rec_rmsreps.report_code 
				AND cmpy_code = l_cmpy 
		
			END IF 
		END IF 
		LET l_ret_success = TRUE
	ELSE #Error Invalid p_report_code
		LET l_msg = "upd_reports() could not found record in table rmsreps"
		CALL fgl_winmessage("Internal 4gl error",l_msg,"ERROR")
		LET l_ret_success = FALSE
	END IF

	DISPLAY "l_ret_success = ", trim(l_ret_success)
	DISPLAY "RPT_DEBUG ----------------------------------------------"
	
	RETURN l_ret_success
END FUNCTION 
}
{

#######################################################################################
# FUNCTION kandooreport(p_kandoouser_sign_on_code,p_report_code)
#
# RETURN l_rec_kandooreport.*
#######################################################################################
FUNCTION kandooreport(p_kandoouser_sign_on_code,p_report_code) 
	DEFINE p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code 
	DEFINE p_report_code LIKE kandooreport.report_code 
	DEFINE l_language_code LIKE kandoouser.language_code 
	DEFINE l_rec_kandooreport RECORD LIKE kandooreport.* 
	DEFINE l_msg STRING
	# Leave this please / DO NOT comment or I'll kill you LOL!"	
	LET l_msg = "kandooreport() is only used in none-streamlined reports.\Please inform AR->@HuHo AP->@Alex C. IN->Eric/Alex B. GL->Alex B. UT->Eric\nProgram:", trim(getmoduleid())
	CALL fgl_winmessage("Report not adopted yet",l_msg,"ERROR")
	# EOF - Leave this please / DO NOT comment or I'll kill you LOL!"	

	SELECT language_code INTO l_language_code FROM kandoouser 
--	WHERE sign_on_code = user -- Do not use OS user variable
		WHERE sign_on_code = glob_rec_kandoouser.sign_on_code
 

	SELECT * INTO l_rec_kandooreport.* FROM kandooreport 
	WHERE report_code = p_report_code 
	AND language_code = l_language_code 

	IF status = notfound THEN 
		SELECT * INTO l_rec_kandooreport.* 
		FROM kandooreport 
		WHERE report_code = p_report_code 
		AND language_code = "ENG" 
		IF status = notfound THEN 
			LET l_rec_kandooreport.report_code = p_report_code 
			LET l_rec_kandooreport.language_code = "ENG" 
			INSERT INTO kandooreport VALUES (l_rec_kandooreport.*) 
		END IF 
	END IF 

	RETURN l_rec_kandooreport.* 
END FUNCTION # kandooreport 

}
{

#######################################################################################
# FUNCTION report_header(p_cmpy,p_rec_kandooreport,p_pageno)
# Forms the up to 4 lines of text for the report header
#
# RETURN l_line1,l_line2,l_line3,l_line4
#######################################################################################
FUNCTION report_header(p_cmpy,p_rec_kandooreport,p_pageno) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_rec_kandooreport RECORD LIKE kandooreport.* 
	DEFINE p_pageno SMALLINT 
	DEFINE l_line1 CHAR(132) 
	DEFINE l_line2 CHAR(132) 
	DEFINE l_line3 CHAR(132) 
	DEFINE l_line4 CHAR(132) 
	DEFINE l_line_text CHAR(115) 
	DEFINE l_temp_text CHAR(20) 
	DEFINE x,y SMALLINT 
	DEFINE l_msg STRING
	# Leave this please / DO NOT comment or I'll kill you LOL!"	
	LET l_msg = "Function report_header() is only used in none-streamlined reports.\Please inform AR->@HuHo AP->@Alex C. IN->Eric/Alex B. GL->Alex B. UT->Eric\nProgram:", trim(getmoduleid())
	CALL fgl_winmessage("Report not adopted yet",l_msg,"ERROR")
	# EOF - Leave this please / DO NOT comment or I'll kill you LOL!"	
	
DISPLAY "@DEBUG=p_rec_kandooreport.menupath_text=", trim(p_rec_kandooreport.menupath_text)
	LET x = p_rec_kandooreport.width_num 
	###
	# Building the first line: Company, page etc...
	SELECT name_text INTO l_line_text FROM company 
	WHERE cmpy_code = p_cmpy 
	LET l_line1 = today 
	LET y = ((x - length(l_line_text)-4)/2)+1 
	LET l_line1[y,x] = p_cmpy," ",l_line_text 
	LET l_temp_text = kandooword("Page", "044") 
	LET l_temp_text = l_temp_text clipped,": ",p_pageno USING "<<<<" 
	LET y = x - length(l_temp_text) + 1 
	LET l_line1[y,x] = l_temp_text clipped 
	###
	# Building the second line: Time, module_id / menu path etc...
	LET l_line2 = time 
	LET l_temp_text = kandooword("Menu", "043") 
	LET l_line_text = p_rec_kandooreport.header_text clipped, 
	" (", l_temp_text clipped, 
	" ",p_rec_kandooreport.menupath_text clipped, 
	")" 
	LET y = ((x - length(l_line_text))/2)+1 
	LET l_line2[y,x] = l_line_text clipped 
	###
	# Building the third line: Line "----------"
	FOR y=1 TO p_rec_kandooreport.width_num 
		LET l_line3[y]="-" 
	END FOR 

	###
	# Building the last line: End of report line/message text
	LET l_temp_text = kandooword("END OF REPORT","045") 
	LET l_line_text = "***** ",l_temp_text clipped," - ", 
	p_rec_kandooreport.menupath_text," *****" 
	LET y = (x - length(l_line_text))/2 + 1 
	LET l_line4[y,x] = l_line_text 
	###
	# returning all four lines
	RETURN l_line1,l_line2,l_line3,l_line4 
END FUNCTION # report_header() 

}
{

#######################################################################################
# FUNCTION enter_MESSAGE(p_rec_kandooreport)
#
#
#######################################################################################
FUNCTION enter_message(p_rec_kandooreport) 
	DEFINE p_rec_kandooreport RECORD LIKE kandooreport.* 
	DEFINE l_rec_s_kandooreport RECORD LIKE kandooreport.* 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_msg STRING
	# Leave this please / DO NOT comment or I'll kill you LOL!"	
	LET l_msg = "Function enter_message() is only used in none-streamlined reports.\Please inform AR->@HuHo AP->@Alex C. IN->Eric/Alex B. GL->Alex B. UT->Eric\nProgram:", trim(getmoduleid())
	CALL fgl_winmessage("Report not adopted yet",l_msg,"ERROR")
	# EOF - Leave this please / DO NOT comment or I'll kill you LOL!"	

	DISPLAY "@DEBUG=p_rec_kandooreport.menupath_text=", trim(p_rec_kandooreport.menupath_text)

	LET l_rec_s_kandooreport.* = p_rec_kandooreport.* 

	OPEN WINDOW u505 with FORM "U505" 
	CALL windecoration_u("U505") 

	LET l_msgresp=kandoomsg("U",1009,"") 
	#1009 Enter the new Report Header
	DISPLAY BY NAME l_rec_s_kandooreport.width_num, 
	l_rec_s_kandooreport.length_num, 
	l_rec_s_kandooreport.report_code 

	INPUT BY NAME l_rec_s_kandooreport.header_text, 
	l_rec_s_kandooreport.selection_flag, 
	l_rec_s_kandooreport.menupath_text 
	WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","rmsfunc","input-kandooreport") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER FIELD header_text 
			IF l_rec_s_kandooreport.header_text IS NULL THEN 
				LET l_rec_s_kandooreport.header_text = p_rec_kandooreport.header_text 
				NEXT FIELD header_text 
			END IF 


	END INPUT 

	CLOSE WINDOW u505 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN p_rec_kandooreport.* 
	ELSE 
		RETURN l_rec_s_kandooreport.* 
	END IF 
END FUNCTION # enter_message 


{


#######################################################################################
# FUNCTION line_merge(p_text_line, p_data_line)
#
#
#######################################################################################
FUNCTION line_merge(p_text_line,p_data_line) 
	DEFINE p_text_line CHAR(132) 
	DEFINE p_data_line CHAR(132) 
	DEFINE l_result_line CHAR(132) 
	DEFINE l_idx SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	IF p_text_line IS NULL THEN 
		LET p_text_line = " " 
	END IF 

	IF p_data_line IS NULL THEN 
		LET p_data_line = " " 
	END IF 

	LET l_idx = 1 
	WHILE l_idx < 133 
		CASE 
			WHEN p_text_line[l_idx] = ' ' AND p_data_line[l_idx] = ' ' 
				LET l_result_line[l_idx] = ' ' 
			WHEN p_text_line[l_idx] = '~' AND p_data_line[l_idx] = ' ' 
				LET l_result_line[l_idx] = ' ' 
			WHEN p_text_line[l_idx] != ' ' AND p_data_line[l_idx] = ' ' 
				LET l_result_line[l_idx] = p_text_line[l_idx] 
			WHEN p_data_line[l_idx] != ' ' 
				LET l_result_line[l_idx] = p_data_line[l_idx] 
		END CASE 
		LET l_idx = l_idx + 1 
	END WHILE 

	RETURN l_result_line 
END FUNCTION # line_merge 








############################################################################################################
#
#
# LEGACY BELOW - WILL BE DROPPED SOON  LEGACY BELOW - WILL BE DROPPED SOON LEGACY BELOW - WILL BE DROPPED SOON
# LEGACY BELOW - WILL BE DROPPED SOON  LEGACY BELOW - WILL BE DROPPED SOON LEGACY BELOW - WILL BE DROPPED SOON
# LEGACY BELOW - WILL BE DROPPED SOON  LEGACY BELOW - WILL BE DROPPED SOON LEGACY BELOW - WILL BE DROPPED SOON
# LEGACY BELOW - WILL BE DROPPED SOON  LEGACY BELOW - WILL BE DROPPED SOON LEGACY BELOW - WILL BE DROPPED SOON
# LEGACY BELOW - WILL BE DROPPED SOON  LEGACY BELOW - WILL BE DROPPED SOON LEGACY BELOW - WILL BE DROPPED SOON
#
#
############################################################################################################


#######################################################################################
# FUNCTION printonce(p_output, p_flag)
#
#
#######################################################################################
FUNCTION printonce(p_output,p_flag) 
	DEFINE p_output CHAR(100) 
	DEFINE p_flag CHAR(1) 
	DEFINE l_cmpy LIKE company.cmpy_code 
	DEFINE l_report_code LIKE rmsreps.report_code 
	DEFINE l_err_message CHAR(60) 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE x, i SMALLINT
	DEFINE l_msg STRING
	# Leave this please / DO NOT comment or I'll kill you LOL!"	
	LET l_msg = "Function printonce() (unclear what it really does) is only used in none-streamlined reports.\Please inform AR->@HuHo AP->@Alex C. IN->Eric/Alex B. GL->Alex B. UT->Eric\nProgram:", trim(getmoduleid())
	CALL fgl_winmessage("Report not adopted yet",l_msg,"ERROR")
	# EOF - Leave this please / DO NOT comment or I'll kill you LOL!"	

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
	BEGIN WORK 

		LET l_err_message = "rmsfunc.4gl - Update printonce flag" 

		UPDATE rmsreps 
		SET printonce_flag = p_flag 
		WHERE cmpy_code = l_cmpy 
		AND report_code = l_report_code 
	COMMIT WORK 

	WHENEVER ERROR stop 

END FUNCTION


#######################################################################################
# FUNCTION file_status(p_file_name)
#
#
#######################################################################################
FUNCTION file_status(p_file_name) 
	######
	##  FUNCTION returns one ofthe following VALUES
	##        1. File NOT found
	##        2. No read permission
	##        3. No write permission
	##        4. File IS Empty
	##        5. OTHERWISE
	######
	DEFINE p_file_name CHAR(60) 
	DEFINE l_runner CHAR(100) 
	DEFINE l_ret_code INTEGER 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_msg STRING
	# Leave this please / DO NOT comment or I'll kill you LOL!"	
	LET l_msg = "Function file_status() in lib_report_rmsfunc.4gl is only used in none-streamlined reports.\Please inform AR->@HuHo AP->@Alex C. IN->Eric/Alex B. GL->Alex B. UT->Eric\nProgram:", trim(getmoduleid())
	CALL fgl_winmessage("Report not adopted yet",l_msg,"ERROR")
	# EOF - Leave this please / DO NOT comment or I'll kill you LOL!"	

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

	#   LET rul_runner " [ -f ",p_file_name clipped," ] 2>>",trim(get_settings_logFile())
	#   run l_runner returning l_ret_code
	#   IF l_ret_code THEN
	#      RETURN 1
	#   END IF
	#   LET l_runner = " [ -r ",p_file_name clipped," ] 2>>",trim(get_settings_logFile())
	#   run l_runner returning l_ret_code
	#   IF l_ret_code THEN
	#      RETURN 2
	#   END IF
	#   LET l_runner = " [ -w ",p_file_name clipped," ] 2>>",trim(get_settings_logFile())
	#   run l_runner returning l_ret_code
	#   IF l_ret_code THEN
	#      RETURN 3
	#   END IF
	#   LET l_runner = " [ -s ",p_file_name clipped," ] 2>>",trim(get_settings_logFile())
	#   run l_runner returning l_ret_code
	#   IF l_ret_code THEN
	#      RETURN 4
	#   ELSE
	#      RETURN 5
	#   END IF
END FUNCTION 

#######################################################################################
# FUNCTION autoprint(p_printer_text,p_output)
#
# NOTE: HuHO - this function was never called from anywhere...
#######################################################################################
FUNCTION autoprint(p_printer_text,p_output) 
	DEFINE p_printer_text CHAR(20) 
	DEFINE p_output CHAR(100) 
	DEFINE l_cmpy LIKE company.cmpy_code 
	DEFINE l_report_code LIKE rmsreps.report_code 
	DEFINE x, i SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_msg STRING
	# Leave this please / DO NOT comment or I'll kill you LOL!"	
	LET l_msg = "Function autoprint() is only used in none-streamlined reports.\Please inform AR->@HuHo AP->@Alex C. IN->Eric/Alex B. GL->Alex B. UT->Eric\nProgram:", trim(getmoduleid())
	CALL fgl_winmessage("Report not adopted yet",l_msg,"ERROR")
	# EOF - Leave this please / DO NOT comment or I'll kill you LOL!"	

	IF p_printer_text IS NULL 
	OR p_output IS NULL THEN 
		RETURN 
	END IF 
	LET x = length(p_output) 
	FOR i = 12 TO x 
		IF p_output[i,i] = "." THEN 
			LET l_cmpy = p_output[12,i-1] 
			LET l_report_code = p_output[i+1,x] 
			EXIT FOR 
		END IF 
		#   END FOR;
	END FOR 

	#<Suse> will get confused by the abowe "END FOR" as it IS followed by "UPDATE",
	#so please don't delete this "sleep" - separating with ";" will fail with
	#4js compiler ...
	SLEEP 0 

	UPDATE rmsreps 
	SET printnow_flag = "Y", 
	dest_print_text = p_printer_text, 
	start_page = 1, 
	print_page = 9999, 
	copy_num = 1, 
	comp_ind = "N" 
	WHERE report_code = l_report_code 
	AND cmpy_code = l_cmpy 
END FUNCTION 


#######################################################################################
# FUNCTION report7(p_cmpy,p_report_code)
#
#
#######################################################################################
FUNCTION report7(p_cmpy,p_report_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_report_code LIKE rmsreps.report_code 
	DEFINE l_rec_rmsreps RECORD LIKE rmsreps.* 
	DEFINE l_rec_printcodes RECORD LIKE printcodes.* 
	DEFINE l_runner CHAR(200) 
	DEFINE l_print_cmd CHAR(300) 
	DEFINE l_del_cmd CHAR(100) 
	DEFINE l_err_message CHAR(50) 
	DEFINE l_file_name, l_file_tmp1, l_file_tmp2 CHAR(25) 
	DEFINE l_file_status SMALLINT 
	DEFINE l_ret_code, l_start_line, l_end_line INTEGER 
	DEFINE l_norm_on, comp_on CHAR(100) 
	--DEFINE l_thirty_four SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_msg STRING
	# Leave this please / DO NOT comment or I'll kill you LOL!"	
	LET l_msg = "Function report7() is only used in none-streamlined reports.\Please inform AR->@HuHo AP->@Alex C. IN->Eric/Alex B. GL->Alex B. UT->Eric\nProgram:", trim(getmoduleid())
	CALL fgl_winmessage("Report not adopted yet",l_msg,"ERROR")
	# EOF - Leave this please / DO NOT comment or I'll kill you LOL!"	

	--LET l_thirty_four = 34 
	SELECT * INTO l_rec_rmsreps.* FROM rmsreps 
	WHERE report_code = p_report_code 
	AND cmpy_code = p_cmpy 

	SELECT * INTO l_rec_printcodes.* FROM printcodes 
	WHERE print_code = l_rec_rmsreps.dest_print_text 
	LET l_file_name = trim(get_settings_reportPath()), "/",l_rec_rmsreps.cmpy_code clipped, 
	".",l_rec_rmsreps.report_code USING "<<<<<<<<" 
	LET l_file_tmp1 = l_file_name clipped,".tmp1" 
	LET l_file_tmp2 = l_file_name clipped,".tmp2" 
	IF l_rec_rmsreps.start_page = 1 THEN 
		LET l_start_line = 1 
		LET l_end_line = l_rec_rmsreps.print_page * l_rec_rmsreps.page_length_num 
	ELSE 
		LET l_start_line = (l_rec_rmsreps.start_page -1) 
		* l_rec_rmsreps.page_length_num + 1 
		LET l_end_line = l_start_line + (l_rec_rmsreps.print_page 
		* l_rec_rmsreps.page_length_num) -1 
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

	CALL fgl_winmessage("RUN l_runner",l_runner,"info") 

	RUN l_runner 

	CALL file_status(l_file_tmp1) RETURNING l_file_status 
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
		LET l_msgresp = kandoomsg("U",1,l_err_message) 
		#1 Press any key TO continue
		IF l_file_status = 1 THEN 
			RETURN false 
		END IF 
	END IF 

	IF l_rec_rmsreps.align_ind = "Y" THEN 
		LET l_runner = "cat ",l_file_tmp1," | tr \"[!-~]\" \"[X*]\" > ", 
		l_file_tmp2," ; mv ",l_file_tmp2," ",l_file_tmp1," " 
		RUN l_runner 
		## The ASCII sequence of printable characters, starts AT "!"
		## AND ends AT "~". This l_runner relaces them with "X"
	END IF 
	IF l_rec_rmsreps.comp_ind = "N" THEN 
		LET l_print_cmd = "F=",l_file_tmp1, 
		";C=",l_rec_rmsreps.copy_num USING "<<<<<", 
		";L=",l_rec_rmsreps.page_length_num USING "<<<<<", 
		";W=",l_rec_rmsreps.report_width_num USING "<<<<<", 
		";",l_rec_printcodes.print_text clipped," 2>>", trim(get_settings_logFile()), 
		"; STATUS=$? ", 
		" ; EXIT $STATUS " 
		LET l_del_cmd = "rm ",l_file_tmp1," " 
	ELSE 
		LET comp_on = ascii ASCII_QUOTATION_MARK, 
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
		ascii l_rec_printcodes.compress_20, ascii ASCII_QUOTATION_MARK 
		LET l_norm_on = ascii ASCII_QUOTATION_MARK, 
		ascii l_rec_printcodes.normal_1, 
		ascii l_rec_printcodes.normal_2, 
		ascii l_rec_printcodes.normal_3, 
		ascii l_rec_printcodes.normal_4, 
		ascii l_rec_printcodes.normal_5, 
		ascii l_rec_printcodes.normal_6, 
		ascii l_rec_printcodes.normal_7, 
		ascii l_rec_printcodes.normal_8, 
		ascii l_rec_printcodes.normal_9, 
		ascii l_rec_printcodes.normal_10, ascii ASCII_QUOTATION_MARK 
		LET l_runner = "echo ",comp_on clipped," > ",l_file_tmp2 clipped, 
		";cat ", l_file_tmp1 clipped, " >> ",l_file_tmp2 clipped, 
		";echo ", l_norm_on clipped, " >> ",l_file_tmp2 clipped, 
		" 2>>", trim(get_settings_logFile()) 
		RUN l_runner 
		LET l_print_cmd = "F=",l_file_tmp2, 
		" ;C=",l_rec_rmsreps.copy_num USING "<<<<<", 
		" ;L=",l_rec_rmsreps.page_length_num USING "<<<<<", 
		" ;W=",l_rec_rmsreps.report_width_num USING "<<<<<", 
		" ;",l_rec_printcodes.print_text clipped," 2>>", trim(get_settings_logFile()), 
		" ; STATUS=$? " 
		LET l_del_cmd = "rm ",l_file_tmp2, " " 
	END IF 
	RUN l_print_cmd RETURNING l_ret_code 
	IF l_ret_code THEN 

		CALL fgl_winmessage("Print Problem"," An error has occurred during printing.\nCheck PRINT command - Refer Menu U1P","ERROR") 
		#DISPLAY " An error has occurred during printing. " AT 1,1
		#DISPLAY " Check PRINT command - Refer Menu U1P   " AT 2,1
		##prompt "        Any Key TO Continue" FOR CHAR ans

		RUN l_del_cmd 
		IF l_rec_rmsreps.comp_ind = "Y" THEN 
			LET l_del_cmd = "rm ",l_file_tmp1, " " 
			RUN l_del_cmd 
		END IF 
		RETURN false 
	ELSE 
		RUN l_del_cmd 
		IF l_rec_rmsreps.comp_ind = "Y" THEN 
			LET l_del_cmd = "rm ",l_file_tmp1, " " 
			RUN l_del_cmd 
		END IF 
		RETURN true 
	END IF 

END FUNCTION 

