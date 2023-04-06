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

	Source code beautified by beautify.pl on 2020-01-03 10:10:02	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gw/T_GW_GLOBALS.4gl" 
GLOBALS "../gw/TGW1_GLOBALS.4gl" 

############################################################
#FUNCTION upd_reports_dir(p_report_code,
#                         p_page_num,
#                         p_report_width_num,
#                         p_page_length_num)
#
#
#
############################################################
FUNCTION upd_reports_dir(p_report_code, 
	p_page_num, 
	p_report_width_num, 
	p_page_length_num) 

	DEFINE p_report_code CHAR(20) 
	DEFINE p_page_num LIKE rmsreps.page_num 
	DEFINE p_report_width_num LIKE rmsreps.report_width_num 
	DEFINE p_page_length_num LIKE rmsreps.page_length_num 
	DEFINE l_rec_rmsreps RECORD LIKE rmsreps.* 

	LET l_rec_rmsreps.report_code = p_report_code[15,20] clipped 

	UPDATE rmsreps 
	SET page_num = p_page_num, 
	report_width_num = p_report_width_num, 
	page_length_num = p_page_length_num, 
	status_text = "Sent TO Print" 
	WHERE report_code = l_rec_rmsreps.report_code 

END FUNCTION 


############################################################
# FUNCTION print_report(p_l_file_name, p_print_code)
#
#
############################################################
FUNCTION print_report(p_l_file_name, p_print_code) 
	DEFINE p_l_file_name CHAR(60) 
	DEFINE p_print_code LIKE printcodes.print_code 
	DEFINE l_runner CHAR(200) 
	DEFINE l_print_cmd CHAR(300) 
	DEFINE l_file_name CHAR(25) 
	DEFINE l_file_tmp1 CHAR(25) 
	DEFINE l_file_tmp2 CHAR(25) 
	DEFINE l_file_status SMALLINT 
	DEFINE l_ret_code INTEGER 
	DEFINE l_start_line INTEGER 
	DEFINE l_report_code INTEGER 
	DEFINE l_end_line INTEGER 
	DEFINE l_norm_on CHAR(100) 
	DEFINE l_comp_on CHAR(100) 
	DEFINE l_del_cmd CHAR(100) 
	DEFINE l_rec_rmsreps RECORD LIKE rmsreps.* 
	DEFINE l_rec_printcodes RECORD LIKE printcodes.* 
	DEFINE l_rec_print 
	RECORD 
		print_code LIKE printcodes.print_code, 
		copies SMALLINT, 
		comp CHAR(1), 
		page_length_num LIKE rmsreps.page_length_num, 
		start_page LIKE rmsreps.page_num, 
		print_pages LIKE rmsreps.page_num, 
		print_x CHAR(1) 
	END RECORD 

	LET l_report_code = p_l_file_name[15,20] clipped 

	SELECT * 
	INTO l_rec_rmsreps.* 
	FROM rmsreps 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND report_code = l_report_code 

	LET l_file_name = p_l_file_name 

	LET l_file_tmp1 = l_file_name clipped,".tmp1" 
	LET l_file_tmp2 = l_file_name clipped,".tmp2" 
	IF l_rec_print.print_code IS NULL THEN 
		LET l_rec_print.copies = 1 
		LET l_rec_print.print_x = "N" 
		LET l_rec_print.start_page = 1 
		LET l_rec_print.print_code = p_print_code 

		IF l_rec_rmsreps.page_length_num IS NULL 
		OR l_rec_rmsreps.page_length_num = 0 THEN 
			LET l_rec_print.page_length_num = l_rec_rmsreps.page_length_num 
		END IF 

		IF l_rec_rmsreps.page_num IS NULL 
		OR l_rec_rmsreps.page_num = 0 THEN 
			LET l_rec_print.print_pages = 9999 
		ELSE 
			LET l_rec_print.print_pages = l_rec_rmsreps.page_num 
		END IF 

		SELECT * 
		INTO l_rec_printcodes.* 
		FROM printcodes 
		WHERE print_code = p_print_code 

		IF status = notfound THEN 
			RETURN false 
		END IF 

		IF l_rec_printcodes.device_ind = "2" THEN 
			RETURN false 
		END IF 

		IF l_rec_rmsreps.report_width_num > l_rec_printcodes.width_num THEN 
			LET l_rec_print.comp = "Y" 
		ELSE 
			LET l_rec_print.comp = "N" 
		END IF 

		IF l_rec_print.page_length_num IS NULL 
		OR l_rec_print.page_length_num = 0 THEN 
			LET l_rec_print.page_length_num = l_rec_printcodes.length_num 
		END IF 
	END IF 

	IF l_rec_print.print_x = "Y" THEN 
		LET l_rec_print.print_pages = 2 
	END IF 

	IF l_rec_print.start_page = 1 THEN 
		LET l_start_line = 1 
		LET l_end_line = l_rec_print.print_pages 
		* l_rec_print.page_length_num 
	ELSE 
		LET l_start_line = (l_rec_print.start_page -1) 
		* l_rec_print.page_length_num + 1 
		LET l_end_line = l_start_line + (l_rec_print.print_pages 
		* l_rec_print.page_length_num) -1 
	END IF 

	IF l_end_line > 999999 THEN 
		LET l_end_line = 999999 
	END IF 

	IF l_start_line > 999999 THEN 
		LET l_start_line = 999999 
	END IF 

	LET l_runner = "sed -n \"",l_start_line using "<<<<<<" clipped,",", 
	l_end_line USING "<<<<<<" clipped," p\"", 
	" < ",l_file_name clipped, 
	" > ",l_file_tmp1 clipped," 2>>",trim(get_settings_logFile()) 
	RUN l_runner 

	# Insert blank lines TO pad out REPORT IF going TO 70 line (A4) printer
	IF (l_rec_print.page_length_num = 70 ) AND # a4 
	(l_rec_printcodes.length_num = 70 ) THEN 

		LET l_runner = "REPORT.padder ",l_file_tmp1 clipped," 66 4 > ", 
		l_file_tmp2 clipped, " 2>>",trim(get_settings_logFile()) 
		RUN l_runner 

		LET l_runner = "mv ",l_file_tmp2, " ",l_file_tmp1, " 2>>",trim(get_settings_logFile()) 
		RUN l_runner 

	END IF 

	IF l_rec_print.print_x = "Y" THEN 
		LET l_runner = "cat ",l_file_tmp1," | tr \"[!-~]\" \"[X*]\" > ", 
		l_file_tmp2," ; mv ",l_file_tmp2," ",l_file_tmp1," " 
		RUN l_runner 
		## The ASCII sequence of printable characters, starts AT "!"
		## AND ends AT "~". This l_runner relaces them with "X"
	END IF 

	IF l_rec_print.comp = "N" THEN 
		LET l_print_cmd = "F=",l_file_tmp1, 
		";C=",l_rec_print.copies USING "<<<<<", 
		";L=",l_rec_rmsreps.page_length_num USING "<<<<<", 
		";W=",l_rec_rmsreps.report_width_num USING "<<<<<", 
		";",l_rec_printcodes.print_text clipped," 2>>", trim(get_settings_logFile()), 
		"; STATUS=$? ", 
		" ; EXIT $STATUS " 
		LET l_del_cmd = "rm ",l_file_tmp1," " 

	ELSE 
		LET l_comp_on = ascii 34, 
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
		ascii l_rec_printcodes.compress_20, ascii 34 
		LET l_norm_on = ascii 34, 
		ascii l_rec_printcodes.normal_1, 
		ascii l_rec_printcodes.normal_2, 
		ascii l_rec_printcodes.normal_3, 
		ascii l_rec_printcodes.normal_4, 
		ascii l_rec_printcodes.normal_5, 
		ascii l_rec_printcodes.normal_6, 
		ascii l_rec_printcodes.normal_7, 
		ascii l_rec_printcodes.normal_8, 
		ascii l_rec_printcodes.normal_9, 
		ascii l_rec_printcodes.normal_10, ascii 34 
		LET l_runner = "echo ",l_comp_on clipped," > ",l_file_tmp2 clipped, 
		";cat ", l_file_tmp1 clipped, " >> ",l_file_tmp2 clipped, 
		";echo ", l_norm_on clipped, " >> ",l_file_tmp2 clipped, 
		" 2>>",trim(get_settings_logFile()) 
		RUN l_runner 

		LET l_print_cmd = "F=",l_file_tmp2, 
		" ;C=",l_rec_print.copies USING "<<<<<", 
		" ;L=",l_rec_rmsreps.page_length_num USING "<<<<<", 
		" ;W=",l_rec_rmsreps.report_width_num USING "<<<<<", 
		" ;",l_rec_printcodes.print_text clipped," 2>>",trim(get_settings_logFile()), 
		" ; STATUS=$? " 

		LET l_del_cmd = "rm ",l_file_tmp2," " 
	END IF 

	RUN l_print_cmd 
	RETURNING l_ret_code 

	RUN l_del_cmd 

	IF l_ret_code THEN 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 

END FUNCTION 
