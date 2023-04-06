############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS 

	DEFINE t_rec_print_report_dialog TYPE AS RECORD
		rpt_report_text LIKE rmsreps.report_text, 
		rpt_exec_ind LIKE rmsreps.exec_ind, 
		rpt_report_date LIKE rmsreps.report_date, 
		rpt_report_time LIKE rmsreps.report_time, 
		rpt_sel_flag LIKE rmsreps.sel_flag, 
		rpt_printnow_flag LIKE rmsreps.printnow_flag, 
		rpt_dest_print_text LIKE rmsreps.dest_print_text, 
		rpt_report_code LIKE kandooreport.l_report_code, 
		rpt_date LIKE kandooreport.l_report_date, 
		rpt_time LIKE kandooreport.l_report_time, 
		rpt_entry_code LIKE kandooreport.l_entry_code, 
		rpt_pgm_text LIKE rmsreps.report_pgm_text, 
		rpt_exec_flag LIKE kandooreport.exec_flag, 
		rpt_width LIKE rmsreps.report_width_num, 
		rpt_length LIKE rmsreps.page_length_num  
	END RECORD

	DEFINE dt_rec_rpt_selector TYPE AS RECORD 
		rpt_note STRING,
		rpt_header STRING,
		sel_text LIKE rmsreps.sel_text, #nchar(2000) #space for a full query ???
		sel_option1 LIKE rmsreps.sel_option1, #nvarchar(150,0)
		sel_option2 LIKE rmsreps.sel_option2, #nvarchar(150,0) 
		sel_option3 LIKE rmsreps.sel_option3, #nvarchar(150,0)
		sel_option4 LIKE rmsreps.sel_option4, #nvarchar(150,0)
		sel_option5 LIKE rmsreps.sel_option5, #nvarchar(150,0)
		sel_option6 LIKE rmsreps.sel_option6, #nvarchar(150,0)
		sel_order LIKE rmsreps.sel_order, #nvarchar(150,0) 
		--report_ord_flag LIKE rmsreps.report_ord_flag, #sel order using a flag
		sel_flag LIKE rmsreps.sel_flag,	 #nchar(1)	???????

		ref1_text LIKE rmsreps.ref1_text, # nvarchar(100,0)	
		ref1_code LIKE rmsreps.ref1_code, #nchar(10)
		ref1_num LIKE rmsreps.ref1_num, #integer
		ref1_date LIKE rmsreps.ref1_date, #date
		ref1_ind LIKE rmsreps.ref1_ind, #nchar(1)
		ref1_amt LIKE rmsreps.ref1_amt, #decimal(16,2)
		ref1_per LIKE rmsreps.ref1_per, #decimal(6,2)
		ref1_factor LIKE rmsreps.ref1_factor, #decimal(16,8)

		ref2_text LIKE rmsreps.ref2_text, # nvarchar(100,0)
		ref2_code LIKE rmsreps.ref2_code, #nchar(10
		ref2_num LIKE rmsreps.ref2_num, #integer
		ref2_date LIKE rmsreps.ref2_date, #date
		ref2_ind LIKE rmsreps.ref2_ind, #nchar(1)
		ref2_amt LIKE rmsreps.ref2_amt, #decimal(16,2)
		ref2_per LIKE rmsreps.ref2_per, #decimal(6,2)
		ref2_factor LIKE rmsreps.ref2_factor, #decimal(16,8)

		ref3_text LIKE rmsreps.ref3_text, # nvarchar(100,0)
		ref3_code LIKE rmsreps.ref3_code, #nchar(10
		ref3_num LIKE rmsreps.ref3_num, #integer
		ref3_date LIKE rmsreps.ref3_date, #date
		ref3_ind LIKE rmsreps.ref3_ind, #nchar(1)
		ref3_amt LIKE rmsreps.ref3_amt, #decimal(16,2)
		ref3_per LIKE rmsreps.ref3_per, #decimal(6,2)
		ref3_factor LIKE rmsreps.ref3_factor, #decimal(16,8)

		ref4_text LIKE rmsreps.ref4_text, # nvarchar(100,0)
		ref4_code LIKE rmsreps.ref4_code, #nchar(10
		ref4_num LIKE rmsreps.ref4_num, #integer
		ref4_date LIKE rmsreps.ref4_date, #date
		ref4_ind LIKE rmsreps.ref4_ind, #nchar(1)
		ref4_amt LIKE rmsreps.ref4_amt, #decimal(16,2)
		ref4_per LIKE rmsreps.ref4_per, #decimal(6,2)
		ref4_factor LIKE rmsreps.ref4_factor, #decimal(16,8)

		ref5_text LIKE rmsreps.ref5_text, # nvarchar(100,0)
		ref5_code LIKE rmsreps.ref5_code, #nchar(10
		ref5_num LIKE rmsreps.ref5_num, #integer
		ref5_date LIKE rmsreps.ref5_date, #date
		ref5_ind LIKE rmsreps.ref5_ind, #nchar(1)
		ref5_amt LIKE rmsreps.ref5_amt, #decimal(16,2)
		ref5_per LIKE rmsreps.ref5_per, #decimal(6,2)
		ref5_factor LIKE rmsreps.ref5_factor, #decimal(16,8)

		ref6_text LIKE rmsreps.ref6_text, # nvarchar(100,0)
		ref6_code LIKE rmsreps.ref6_code, #nchar(10
		ref6_num LIKE rmsreps.ref6_num, #integer
		ref6_date LIKE rmsreps.ref6_date, #date
		ref6_ind LIKE rmsreps.ref6_ind, #nchar(1)
		ref6_amt LIKE rmsreps.ref6_amt, #decimal(16,2)
		ref6_per LIKE rmsreps.ref6_per, #decimal(6,2)
		ref6_factor LIKE rmsreps.ref6_factor, #decimal(16,8)

		report_date LIKE rmsreps.report_date #date

	END RECORD 
	
	DEFINE t_rec_reporthead_rc_dt_cn_ph TYPE AS RECORD 
		report_code LIKE reporthead.report_code, 
		desc_text LIKE reporthead.desc_text, 
		column_num LIKE reporthead.column_num, 
		page_head_flag LIKE reporthead.page_head_flag 
	END RECORD 


	DEFINE t_rec_rpthead_id_tx_ty TYPE AS 	RECORD 
		rpt_id LIKE rpthead.rpt_id, 
		rpt_text LIKE rpthead.rpt_text, 
		rpt_type LIKE rpthead.rpt_type 
	END RECORD 

	DEFINE t_rec_rpt_header_footer_text TYPE AS	RECORD 
		header_1 STRING, #29/09/2020                                                DE Demo Company                                                    Page: 1  
		header_2 STRING, #15:04:23                                   AR Customer Address (by post code) (Menu AA5)
		header_3 STRING, #------------------------------------------------------------------------------------------------------------------------------------  
		line1_text STRING,
		line2_text STRING,
		line3_text STRING,
		line4_text STRING,
		line5_text STRING,
		footer_1 STRING,
		footer_2 STRING,
		footer_3 STRING,
		end_of_report STRING #           ***** END OF REPORT AA5 (DE.62) ***** 
	END RECORD 
	
	#DEFINE glob_in_trans SMALLINT we can not declare this in the report library !!! to whoever has added this global here 
	# ----------------------------------------------------------------------------------------
	# Multi Report Support requires dynamic array of report objects
	#They stay together - they are all joined / array index has to exist for each report instance
	DEFINE glob_arr_rmsreps_idx DYNAMIC ARRAY OF STRING
	DEFINE glob_arr_rec_rpt_kandooreport DYNAMIC ARRAY OF RECORD LIKE kandooreport.*
	DEFINE glob_arr_rec_rpt_rmsreps DYNAMIC ARRAY OF RECORD LIKE rmsreps.*
	DEFINE glob_arr_rec_rpt_printcodes DYNAMIC ARRAY OF RECORD LIKE printcodes.*
	DEFINE glob_arr_rec_rpt_header_footer DYNAMIC ARRAY OF t_rec_rpt_header_footer_text
--	DEFINE glob_rpt_background_process NCHAR(1) #replaced by rpt_get_is_background_process()/rpt_set_is_background_process()
	DEFINE glob_rec_rpt_selector OF dt_rec_rpt_selector
	# ----------------------------------------------------------------------------------------
#########################################################################################
# FROM HERE
# !!! These have to go after we streamlined reports
#########################################################################################
{

	DEFINE t_rec_report_settings TYPE AS RECORD 
		rpt_cmpy_code LIKE company.cmpy_code,
		rpt_report_code LIKE rmsreps.report_code, #INT 
		rpt_name LIKE kandooreport.report_code, #nchar(10)
		rpt_file_name NVARCHAR(100),
		rpt_file_path_name NVARCHAR(150),
		rpt_file_text LIKE rmsreps.file_text,
		rpt_module_id LIKE reporthead.report_code, #nchar(3)
		rpt_title1 LIKE rmsreps.report_text,
		rpt_title2 LIKE rmsreps.report_text,
		rpt_entry_code LIKE kandoouser.sign_on_code,
		rpt_security_ind LIKE kandoouser.security_ind,
		rpt_language_code LIKE kandoouser.language_code,
		rpt_width LIKE rmsreps.report_width_num, 
		rpt_length LIKE rmsreps.page_length_num ,
		rpt_pageno LIKE rmsreps.page_num , 
		rpt_pageno2 LIKE rmsreps.page_num , #this needs changing
		#rpt_wid SMALLINT, #what the f.. is this ? there were rpt_wid and rpt_width in the sources... renamed them to rpt_width
		rpt_note LIKE rmsreps.report_text,
		rpt_date DATE, 
		rpt_time CHAR(10), 
		--rpt_line1 CHAR(80), 
		--rpt_line2 CHAR(80), 
		rpt_offset1 SMALLINT, 
		rpt_offset2 SMALLINT, 
		rpt_output STRING, --CHAR(25)	
		rpt_status_text LIKE rmsreps.status_text,
		rpt_pgm_text LIKE rmsreps.report_pgm_text,

		rpt_status_ind LIKE rmsreps.status_ind,
		rpt_exec_ind LIKE rmsreps.exec_ind,
		rpt_sel_text LIKE rmsreps.sel_text,
		rpt_sel_flag LIKE rmsreps.sel_flag,
		
		rpt_dest_printer LIKE rmsreps.dest_print_text,
		rpt_align_ind LIKE rmsreps.align_ind,
		rpt_copy_num LIKE rmsreps.copy_num,
		rpt_start_page LIKE rmsreps.start_page,
								
		#more from kandooreport.. usage not known yet...
    rpt_line1_text LIKE kandooreport.line1_text, #so far, used for rpt_note = (line1_text and line2_text)
    rpt_line2_text LIKE kandooreport.line2_text, #so far, used for rpt_note = (line1_text and line2_text)
    rpt_line3_text LIKE kandooreport.line3_text,
    rpt_line4_text LIKE kandooreport.line4_text,
    rpt_line5_text LIKE kandooreport.line5_text,
    rpt_line6_text LIKE kandooreport.line6_text,
    rpt_line7_text LIKE kandooreport.line7_text,
    rpt_line8_text LIKE kandooreport.line8_text,
    rpt_line9_text LIKE kandooreport.line9_text,
    rpt_line0_text LIKE kandooreport.line0_text,

		rpt_ref1_code LIKE rmsreps.ref1_code,
		rpt_ref2_code LIKE rmsreps.ref2_code,
		rpt_ref3_code LIKE rmsreps.ref3_code,
		rpt_ref4_code LIKE rmsreps.ref4_code,
		rpt_ref1_date LIKE rmsreps.ref1_date,
		rpt_ref2_date LIKE rmsreps.ref2_date,
		rpt_ref3_date LIKE rmsreps.ref3_date,
		rpt_ref4_date LIKE rmsreps.ref4_date,

		rpt_ref1_ind LIKE rmsreps.ref1_ind,
		rpt_ref2_ind LIKE rmsreps.ref2_ind,
		rpt_ref3_ind LIKE rmsreps.ref3_ind,
		rpt_ref4_ind LIKE rmsreps.ref4_ind,

		rpt_ref1_num LIKE rmsreps.ref1_num,
		rpt_ref2_num LIKE rmsreps.ref2_ind,
		rpt_ref3_num LIKE rmsreps.ref3_num,
		rpt_ref4_num LIKE rmsreps.ref4_num,

		rpt_printnow_flag LIKE rmsreps.printnow_flag,
		rpt_comp_ind LIKE rmsreps.comp_ind,

		rpt_print_page LIKE rmsreps.print_page,
		rpt_ref1_text LIKE rmsreps.ref1_text,
		rpt_sub_dest LIKE rmsreps.sub_dest,
		rpt_printonce_flag LIKE rmsreps.printonce_flag
        	    		
	END RECORD 

}
-- alch remove later.
{	DEFINE glob_rec_kandooreport RECORD LIKE kandooreport.* 
	DEFINE glob_rec_rmsreps RECORD LIKE rmsreps.* 
	DEFINE glob_rpt_note LIKE rmsreps.report_text  #title line 1 text
	DEFINE glob_rpt_note2 LIKE rmsreps.report_text #title line 2 text	
	DEFINE glob_rpt_line1 LIKE rmsreps.report_text 
	DEFINE glob_rpt_line2 LIKE rmsreps.report_text
	DEFINE glob_rpt_offset1 SMALLINT
	DEFINE glob_rpt_offset2 SMALLINT
	DEFINE glob_rpt_pageno LIKE rmsreps.page_num 
	DEFINE glob_rpt_pageno2 LIKE rmsreps.page_num #hardly used
	DEFINE glob_rpt_width LIKE rmsreps.report_width_num
	DEFINE glob_rpt_length LIKE rmsreps.page_length_num 
	DEFINE glob_rpt_date DATE 
	DEFINE glob_rpt_time CHAR(10) 
	DEFINE glob_rpt_output VARCHAR(60)  --CHAR(25)
	DEFINE glob_rpt_output2 VARCHAR(60)	
	DEFINE glob_rpt_output3 VARCHAR(60)
}
{
	DEFINE glob_rec_rpt_settings OF t_rec_report_settings  #New report settings record
	DEFINE glob_rpt_code_char LIKE kandooreport.report_code #nchar(10) should be LIKE rmsreps.report_code INT #
	DEFINE glob_rpt_code_int LIKE rmsreps.report_code #nchar(10) should be LIKE rmsreps.report_code INT #
	DEFINE glob_report_identifier STRING 
	#Title line 1 and 2 
	
	DEFINE glob_rpt_date2 DATE	
	
	DEFINE glob_rpt_time2 CHAR(10)
	
	DEFINE glob_rpt_offset3 SMALLINT	 
	
	#File name / output file name / file_text
	
	DEFINE glob_rpt_output1 VARCHAR(60)

	DEFINE glob_rpt_output4 VARCHAR(60)
}	
	CONSTANT align_left SMALLINT = 0
	CONSTANT align_center SMALLINT = 1
	CONSTANT align_right SMALLINT = 2
	
	CONSTANT RPT_OP_MENU CHAR = "1"
	CONSTANT RPT_OP_BATCH CHAR = "2"
	CONSTANT RPT_OP_CONSTRUCT CHAR = "3"
	CONSTANT RPT_OP_QUERY CHAR = "4" #up for removal/drop
#########################################################################################
# ABOVE HERE
# !!! These have to go after we streamlined reports
#########################################################################################
			
END GLOBALS

{
glob_rec_rmsreps.file_text  #report file name inc. incremental path WAS: glob_rpt_output
glob_rec_rmsreps.report_text #Title/Header Text  WAS: glob_rpt_note
}