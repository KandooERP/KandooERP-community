############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl"  
GLOBALS 
	DEFINE glob_arr_rec_rpt_rmsreps_list DYNAMIC ARRAY OF RECORD 
		scroll_flag CHAR(1), 
		report_pgm_text LIKE rmsreps.report_pgm_text,
		report_text LIKE rmsreps.report_text, 
		report_date LIKE rmsreps.report_date, 
		report_time LIKE rmsreps.report_time, 
		status_text LIKE rmsreps.status_text,
		status_ind LIKE rmsreps.status_ind, #NCHAR(1)
		printed_ind NCHAR(1), 
		report_code LIKE rmsreps.report_code
	END RECORD 

	DEFINE glob_arr_rec_rms_code DYNAMIC ARRAY OF RECORD 
		report_code LIKE rmsreps.report_code, 
		status_text LIKE rmsreps.status_text, 
		action_text NCHAR(6) 
	END RECORD 

	DEFINE glob_rec_print 
	RECORD 
		print_code LIKE printcodes.print_code, 
		copies SMALLINT, 
		comp CHAR(1), 
		page_length_num LIKE rmsreps.page_length_num, 
		start_page LIKE rmsreps.page_num, 
		print_pages LIKE rmsreps.page_num, 
		print_x CHAR(1) 
	END RECORD 
	DEFINE glob_rec_printcodes RECORD LIKE printcodes.* 
	--DEFINE glob_thirty_four SMALLINT 
	#DEFINE glob_arr_size SMALLINT,
	DEFINE glob_term_type CHAR(20) 
	DEFINE glob_arr_rec_file DYNAMIC ARRAY OF #array [100] OF RECORD 
		RECORD 
			filename CHAR(25), 
			report_text LIKE rmsreps.report_text, 
			report_code LIKE rmsreps.report_code 
		END RECORD 
		DEFINE glob_file_idx SMALLINT 
END GLOBALS 