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
#   PSU - External AP Voucher Load

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
############################################################
# Module Scope Variables
############################################################
DEFINE modu_output CHAR(50) 
DEFINE modu_load_file CHAR(100) 
DEFINE modu_kandoo_ap_cnt INTEGER 
DEFINE modu_kandoo_vo_cnt INTEGER 
DEFINE modu_kandoo_db_cnt INTEGER 
DEFINE modu_load_cnt INTEGER 
DEFINE modu_loadfile_cnt INTEGER 
DEFINE modu_rerun_cnt INTEGER 
DEFINE modu_err2_cnt INTEGER 
DEFINE modu_err_cnt INTEGER 
DEFINE modu_loadfile_ind SMALLINT 
DEFINE modu_unload_ind SMALLINT 
DEFINE modu_verbose_ind SMALLINT 
DEFINE modu_total_vouch_amt LIKE debithead.total_amt 
DEFINE modu_total_debit_amt LIKE debithead.total_amt 
DEFINE modu_ap_cnt INTEGER 
DEFINE modu_jmj_ap_cnt INTEGER 
DEFINE modu_process_cnt INTEGER 
DEFINE modu_rec_period RECORD LIKE period.* 
DEFINE modu_jmj_cmpy_code LIKE company.cmpy_code 
DEFINE modu_auto_cmpy_code LIKE company.cmpy_code 
DEFINE modu_file_text CHAR(20) 
DEFINE modu_path_text CHAR(60) 

############################################################
# MAIN
#
#
############################################################
MAIN 

	#Initial UI Init
	CALL setModuleId("PSU_J") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_p_ap() #init p/ap module 

	#huho this was done twice - #huho 14.03.2019
	#   SELECT * INTO pr_rec_kandoouser.* FROM kandoouser
	#    WHERE cmpy_code    = glob_rec_kandoouser.cmpy_code
	#      AND sign_on_code = glob_rec_kandoouser.sign_on_code
	#now done it CALL init_p_ap() #init P/AP module
	#   SELECT * INTO pr_apparms.* FROM apparms
	#    WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
	#   IF STATUS = NOTFOUND THEN
	#      LET l_msgresp=kandoomsg("P",5016,"")
	#      EXIT PROGRAM
	#   END IF
	#
	# Create temp tables reqd. FOR calls TO update_voucher_related_tables/debit
	#
	CALL create_table("debitdist","t_debitdist","","N") 
	CALL create_table("voucherdist","t_voucherdist","","N") 
	#
	#
	#
	--IF num_args() > 0 THEN
	IF get_url_load_file() IS NOT NULL THEN 
		#
		# run   PSU <load-file>
		#
		LET modu_verbose_ind = false 
		LET modu_loadfile_ind = true 
		CALL start_load() 
		CALL move_load_file() 
		EXIT PROGRAM( modu_err_cnt + modu_err2_cnt ) 
	ELSE 
		LET modu_verbose_ind = true 

		OPEN WINDOW p225 with FORM "P225" 
		CALL windecoration_p("P225") 

		MENU " AP Load" 

			BEFORE MENU 
				CALL publish_toolbar("kandoo","PSU_J","menu-ap_load-1") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			ON ACTION "Load" 
				#COMMAND "Load" " Commence load process"
				LET modu_unload_ind = false 
				LET modu_loadfile_ind = true 
				CALL start_load() 
				CALL move_load_file() 
				NEXT option "Print Manager" 

			ON ACTION "Rerun" 
				#COMMAND "Rerun" " Commence load FROM interim table"
				LET modu_unload_ind = false 
				LET modu_loadfile_ind = false 
				CALL start_load() 
				NEXT option "Print Manager" 

			ON ACTION "Unload" 
				#COMMAND "Unload" " Unload contents of interim table"
				LET modu_loadfile_ind = true 
				LET modu_unload_ind = true 
				CALL my_unload() 

			ON ACTION "Print Manager" 
				#COMMAND KEY ("P",f11) "Print" " Print OR View using RMS"
				CALL run_prog("URS","","","","") 
				NEXT option "Exit" 

			ON ACTION "CANCEL" 
				#COMMAND KEY(interrupt,"E")"Exit" " Exit AP Load"
				LET quit_flag = true 
				EXIT MENU 



		END MENU 

		CLOSE WINDOW p225 
	END IF 
END MAIN 


############################################################
# FUNCTION import_voucher()
#
#
############################################################
FUNCTION import_voucher() 
	DEFINE l_dummy_field CHAR(3) 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET modu_jmj_cmpy_code = '9' 
	LET modu_auto_cmpy_code = '5' 
	LET l_msgresp = kandoomsg("P",1062,"") 

	#1062 Enter AP Load Details - ESC TO Continue
	INPUT modu_file_text,modu_path_text,modu_jmj_cmpy_code,modu_auto_cmpy_code,l_dummy_field WITHOUT DEFAULTS 
	FROM file_text,path_text,jmj_cmpy_code,auto_cmpy_code,dummy_field  

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","PSU_J","inp-file-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE FIELD file_text 
			IF NOT modu_loadfile_ind THEN 
				NEXT FIELD jmj_cmpy_code 
			END IF 
		AFTER FIELD file_text 
			IF modu_file_text IS NULL THEN 
				LET l_msgresp = kandoomsg("A",9166,"") 
				#9166 File name must be entered
				NEXT FIELD file_text 
			END IF 
		AFTER FIELD path_text 
			IF modu_path_text IS NULL THEN 
				LET l_msgresp = kandoomsg("A",8015,"") 
				#8015 Warning: Current directory will be defaulted
			END IF 
			IF modu_unload_ind THEN 
				NEXT FIELD dummy_field 
			END IF 
		AFTER FIELD jmj_cmpy_code 
			IF modu_jmj_cmpy_code IS NULL THEN 
				LET modu_jmj_cmpy_code = '9' 
				NEXT FIELD jmj_cmpy_code 
			END IF 
			SELECT unique 1 FROM company 
			WHERE cmpy_code = modu_jmj_cmpy_code 
			IF sqlca.sqlcode = NOTFOUND THEN 
				LET l_msgresp = kandoomsg("A",9003,"") 
				#9003 Company NOT SET up
				NEXT FIELD jmj_cmpy_code 
			END IF 
			IF NOT modu_loadfile_ind THEN 
				IF fgl_lastkey() = fgl_keyval("left") 
				OR fgl_lastkey() = fgl_keyval("up") THEN 
					NEXT FIELD jmj_cmpy_code 
				END IF 
			END IF 
		AFTER FIELD auto_cmpy_code 
			IF modu_auto_cmpy_code IS NULL THEN 
				LET modu_auto_cmpy_code = '5' 
				NEXT FIELD auto_cmpy_code 
			END IF 
			SELECT unique 1 FROM company 
			WHERE cmpy_code = modu_auto_cmpy_code 
			IF sqlca.sqlcode = NOTFOUND THEN 
				LET l_msgresp = kandoomsg("A",9003,"") 
				#9003 Company NOT SET up
				NEXT FIELD auto_cmpy_code 
			END IF 
		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN 
				IF modu_loadfile_ind 
				OR modu_unload_ind THEN 
					IF modu_file_text IS NULL THEN 
						LET l_msgresp = kandoomsg("A",9166,"") 
						#9166 File name must be entered
						NEXT FIELD file_text 
					END IF 
				END IF 
				IF modu_jmj_cmpy_code IS NULL THEN 
					LET modu_jmj_cmpy_code = '9' 
					DISPLAY modu_jmj_cmpy_code TO jmj_cmpy_code  
				END IF 
				SELECT unique 1 FROM company 
				WHERE cmpy_code = modu_jmj_cmpy_code 
				IF sqlca.sqlcode = NOTFOUND THEN 
					LET l_msgresp = kandoomsg("A",9003,"") 
					#9003 Company NOT SET up
					NEXT FIELD jmj_cmpy_code 
				END IF 
				IF modu_auto_cmpy_code IS NULL THEN 
					LET modu_auto_cmpy_code = '5' 
					DISPLAY modu_auto_cmpy_code TO auto_cmpy_code  
				END IF 
				SELECT unique 1 FROM company 
				WHERE cmpy_code = modu_auto_cmpy_code 
				IF sqlca.sqlcode = NOTFOUND THEN 
					LET l_msgresp = kandoomsg("A",9003,"") 
					#9003 Company NOT SET up
					NEXT FIELD auto_cmpy_code 
				END IF 
				IF modu_loadfile_ind 
				OR modu_unload_ind THEN 
					IF NOT create_load_file( modu_path_text , 
					modu_file_text ) THEN 
						NEXT FIELD file_text 
					END IF 
				END IF 
			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET quit_flag = false 
		LET int_flag = false 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 



############################################################
# FUNCTION create_load_file( p_path_text, p_file_text )
#
#
############################################################
FUNCTION create_load_file(p_path_text,p_file_text) 
	DEFINE p_path_text CHAR(60) 
	DEFINE p_file_text CHAR(20) 
	DEFINE l_slash_text CHAR 
	DEFINE l_len_num INTEGER 
	DEFINE l_runner CHAR(100) 
	DEFINE l_ret_code INTEGER 

	LET l_len_num = length( p_path_text ) 
	INITIALIZE l_slash_text TO NULL 
	IF l_len_num > 0 THEN 
		IF p_path_text[l_len_num,l_len_num] != "\/" THEN 
			LET l_slash_text = "\/" 
		END IF 
	END IF 
	LET modu_load_file = p_path_text clipped, 
	l_slash_text clipped, 
	p_file_text clipped 
	LET modu_load_file = modu_load_file clipped 
	LET modu_load_file = valid_load_file( modu_load_file ) 
	IF modu_load_file IS NULL THEN 
		RETURN false 
	ELSE 
		IF modu_unload_ind THEN 
			#LET l_runner = " [ -d ",p_path_text clipped," ] 2>>", trim(get_settings_logFile())
			#run l_runner returning l_ret_code
			LET l_ret_code = os.path.exists(p_path_text) --huho changed TO os.path() method 
			IF l_ret_code THEN 
				ERROR " Directory does NOT exist - check pathname" 
				RETURN false 
			END IF 
		END IF 
		RETURN true 
	END IF 
END FUNCTION 




############################################################
# FUNCTION valid_load_file( p_file_name )
#
#
# Test's performed :
#
#        1. File NOT found
#        2. No read permission
#        3. File IS Empty
#        4. OTHERWISE
#
############################################################
FUNCTION valid_load_file(p_file_name) 
	DEFINE p_file_name CHAR(100)
	DEFINE l_runner CHAR(100) 
 	DEFINE l_ret_code INTEGER 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_err_message CHAR(100)

	LET l_runner = " [ -f ",p_file_name clipped," ] 2>>", trim(get_settings_logFile()) 
	RUN l_runner RETURNING l_ret_code 
	LET l_ret_code = os.path.exists(p_file_name) --huho changed TO os.path() method 
	IF l_ret_code THEN 
		IF modu_unload_ind THEN 
			#
			# IF file does NOT exist FOR Unload THEN check directory
			#
			RETURN p_file_name 
		END IF 
		IF modu_verbose_ind THEN 
			LET l_msgresp = kandoomsg("A",9160,'') 
			#9160 Load file does NOT exist - check path AND filename
		END IF 
		LET modu_err2_cnt = modu_err2_cnt + 1 
		LET l_err_message = "Load file: ", p_file_name clipped, " does NOT exist"
		 
		#---------------------------------------------------------
		OUTPUT TO REPORT PSU_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("PSU_J_rpt_list_exception"),
		'', '', '', l_err_message ) 
		#---------------------------------------------------------	
 
		RETURN "" 
	ELSE 
		IF modu_unload_ind THEN 
			#
			# IF file exists THEN don't overwrite
			#
			ERROR " Unload file already exists in nominated directory" 
			RETURN "" 
		END IF 
	END IF 
	LET l_ret_code = os.path.readable(p_file_name) --huho changed TO os.path() method 
	#LET l_runner = " [ -r ",p_file_name clipped," ] 2>>", trim(get_settings_logFile())
	#run l_runner returning l_ret_code
	IF l_ret_code THEN 
		IF modu_verbose_ind THEN 
			LET l_msgresp = kandoomsg("A",9162,'') 
			#9162 Unable TO read load file
		END IF 
		LET modu_err2_cnt = modu_err2_cnt + 1 
		LET l_err_message = "Unable TO read load file: ",p_file_name clipped

		#---------------------------------------------------------
		OUTPUT TO REPORT PSU_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("PSU_J_rpt_list_exception"),
		'', '', '', l_err_message ) 
		#---------------------------------------------------------	

		RETURN "" 
	END IF 

	LET l_ret_code = os.path.size(p_file_name) --huho changed TO os.path() method 
	#LET l_runner = " [ -s ",p_file_name clipped," ] 2>>", trim(get_settings_logFile())
	#run l_runner returning l_ret_code
	IF l_ret_code THEN 
		IF modu_verbose_ind THEN 
			LET l_msgresp = kandoomsg("A",9161,'') 
			#9161 Load file IS empty
		END IF 
		LET modu_err2_cnt = modu_err2_cnt + 1 
		LET l_err_message = "Load file: ",p_file_name," IS empty" 

		#---------------------------------------------------------
		OUTPUT TO REPORT PSU_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("PSU_J_rpt_list_exception"),
		'', '', '', l_err_message ) 
		#---------------------------------------------------------	
		
 
		RETURN "" 
	ELSE 
		RETURN p_file_name 
	END IF 
END FUNCTION 


############################################################
# FUNCTION verify_acct( p_cmpy, p_account_code, p_year_num, p_period_num )
#
#
#
# - FUNCTION verify_acct() IS a clone of vacctfunc.4gl
# - changes reqd. b/c need TO remove user interaction
# - returns STATUS ( ie. error OR acct_code )
#
############################################################
FUNCTION verify_acct(p_cmpy,p_account_code,p_year_num,p_period_num) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_account_code LIKE coa.acct_code 
	DEFINE p_year_num LIKE coa.start_year_num 
	DEFINE p_period_num LIKE coa.start_period_num 
	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_err_message CHAR(50) 

	SELECT * INTO l_rec_coa.* 
	FROM coa 
	WHERE cmpy_code = p_cmpy 
	AND acct_code = p_account_code 
	IF status = NOTFOUND THEN 
		LET l_err_message = "Account: ",p_account_code clipped," NOT SET up ", 
		"FOR ", p_year_num USING "####", 
		"/", p_period_num USING "###" 
		RETURN ( l_err_message clipped ) 
	ELSE 
		CASE 
			WHEN ( l_rec_coa.start_year_num > p_year_num ) 
				LET l_err_message = "Account: ",p_account_code clipped," NOT OPEN ", 
				"FOR ", p_year_num USING "####", 
				"/", p_period_num USING "###" 
				RETURN ( l_err_message clipped ) 
			WHEN ( l_rec_coa.end_year_num < p_year_num ) 
				LET l_err_message = "Account: ",p_account_code clipped," closed ", 
				"FOR ", p_year_num USING "####", 
				"/", p_period_num USING "###" 
				RETURN ( l_err_message clipped ) 
			WHEN ( l_rec_coa.start_year_num = p_year_num AND 
				l_rec_coa.start_period_num > p_period_num ) 
				LET l_err_message = "Account: ",p_account_code clipped," NOT OPEN ", 
				"FOR ", p_year_num USING "####", 
				"/", p_period_num USING "###" 
				RETURN ( l_err_message clipped ) 
			WHEN ( l_rec_coa.end_year_num = p_year_num AND 
				l_rec_coa.end_period_num < p_period_num ) 
				LET l_err_message = "Account: ",p_account_code clipped," closed ", 
				"FOR ", p_year_num USING "####", 
				"/", p_period_num USING "###" 
				RETURN ( l_err_message clipped ) 
			OTHERWISE 
				RETURN l_rec_coa.acct_code 
		END CASE 
	END IF 
END FUNCTION 

{
############################################################
# FUNCTION start_ex_rep()
#
# Set up Exception REPORT
#
############################################################
FUNCTION start_ex_rep() 

	LET glob_rec_kandooreport.report_code = "PSU" 
	CALL kandooreport( glob_rec_kandoouser.cmpy_code, glob_rec_kandooreport.report_code ) 
	RETURNING glob_rec_kandooreport.* 
	CALL set1_defaults() 
	LET glob_rpt_output = init_report( glob_rec_kandoouser.cmpy_code, glob_rec_kandoouser.sign_on_code, glob_rec_kandooreport.header_text ) 
	START REPORT PSU_J_rpt_list_exception TO glob_rpt_output 
END FUNCTION 
}
{
############################################################
# FUNCTION finish_ex_rep()
#
#
#
############################################################
FUNCTION finish_ex_rep() 
	FINISH REPORT PSU_J_rpt_list_exception 
	CALL upd_reports( glob_rpt_output, glob_rpt_pageno, glob_rec_kandooreport.width_num, 
	glob_rec_kandooreport.length_num ) 
END FUNCTION 
}
############################################################
# REPORT PSU_J_rpt_list_exception(p_rpt_idx,p_cmpy_code, p_vend_code, p_ref_text, p_status )
#
#
#
############################################################
REPORT PSU_J_rpt_list_exception(p_rpt_idx,p_cmpy_code,p_vend_code,p_ref_text,p_status)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx] 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_vend_code LIKE vendor.vend_code 
	DEFINE p_ref_text CHAR(15) 
	DEFINE p_status CHAR(132) 
--	DEFINE l_arr_line ARRAY[4] OF CHAR(132)

	OUTPUT 
 
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			SKIP 3 LINES 

		ON EVERY ROW 
			PRINT COLUMN 01, p_cmpy_code, 
			COLUMN 08, p_vend_code, 
			COLUMN 17, p_ref_text USING "###############", 
			COLUMN 33, p_status[1,132-33] 

		ON LAST ROW 
			NEED 20 LINES 
			SKIP 3 LINES 
			#
			#
			# JMJ specific load will assign this variable TO a non-NULL value
			#
			#
			IF modu_rerun_cnt IS NULL THEN 
				LET modu_rerun_cnt = 0 
				SKIP 1 line 
			ELSE 
				PRINT COLUMN 10, "Total records TO be processed FROM Re-run : ",		modu_rerun_cnt 
			END IF 
			PRINT COLUMN 10, "Total records TO be processed FROM Load File: ",		modu_loadfile_cnt 
			PRINT COLUMN 55, "-------------" 
			PRINT COLUMN 55, ( modu_rerun_cnt + modu_loadfile_cnt ) USING "###########&" 
			SKIP 1 line 
			PRINT COLUMN 10, "Total records with validation errors : ",modu_err_cnt,	" ( SQL / File errors: ",modu_err2_cnt," )" 
			PRINT COLUMN 10, "Total records successfully processed : ", modu_load_cnt 
			PRINT COLUMN 10, "( total no. OF vouchers:", 
			COLUMN 39, modu_kandoo_vo_cnt USING "###########&", " )" 
			PRINT COLUMN 10, "( total no. OF debits :", 
			COLUMN 39, modu_kandoo_db_cnt USING "###########&", " )" 
			PRINT COLUMN 55, "-------------" 
			PRINT COLUMN 55, ( modu_err_cnt + modu_load_cnt ) USING "###########&" 
			SKIP 1 line 
			PRINT COLUMN 10, "Total voucher amounts :", 
			COLUMN 55, modu_total_vouch_amt USING "--------&.&&" 
			PRINT COLUMN 10, "Total debit amounts :", 
			COLUMN 55, modu_total_debit_amt USING "--------&.&&" 
			PRINT COLUMN 55, "-------------" 
			PRINT COLUMN 55, ( modu_total_vouch_amt + modu_total_debit_amt ) 
			USING "--------&.&&" 
			SKIP 2 LINES 
			
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			
			
END REPORT 
############################################################
# END REPORT PSU_J_rpt_list_exception(p_rpt_idx,p_cmpy_code, p_vend_code, p_ref_text, p_status )
############################################################



############################################################
# FUNCTION load_routine()
#
#
############################################################
FUNCTION load_routine() 

	LET modu_load_cnt = 0 
	LET modu_rerun_cnt = 0 
	LET modu_loadfile_cnt = 0 
	LET modu_ap_cnt = 0 
	LET modu_jmj_ap_cnt = 0 
	LET modu_kandoo_ap_cnt = 0 
	#
	# Delete any info FROM temporary tables
	#
	DELETE FROM t_voucherdist 
	DELETE FROM t_debitdist 
	#
	#
	IF chk_tables() THEN 
		IF rerun() THEN 
			IF modu_loadfile_ind THEN 
				CALL perform_load() 
			END IF 
			CALL null_tests() 
			IF chk_setup() THEN 
				CALL setup_cnt() 
				IF get_fiscal() THEN 
					CALL create_ap_entry() 
					IF modu_kandoo_ap_cnt > 0 THEN 
						IF NOT ( modu_err_cnt + modu_err2_cnt ) THEN 

							#---------------------------------------------------------
							OUTPUT TO REPORT PSU_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("PSU_J_rpt_list_exception"),
							'', '', '', 'ap LOAD completed successfully' ) 
							#---------------------------------------------------------	
 
						END IF 
					ELSE 
						#
						# Dummy line in REPORT TO force DISPLAY of Control Totals
						#

						#---------------------------------------------------------
						OUTPUT TO REPORT PSU_J_rpt_list_load(rpt_rmsreps_idx_get_idx("PSU_J_rpt_list_load"),
						 '', '', '', '', '', '' )
						#---------------------------------------------------------	

					END IF 
					LET modu_load_cnt = modu_kandoo_ap_cnt 
				END IF 
			END IF 
		END IF 
	END IF 
END FUNCTION 


############################################################
# FUNCTION perform_load()
#
#
############################################################
FUNCTION perform_load() 
	DEFINE l_err_text CHAR(250)
	DEFINE l_temp_file CHAR(100) 
	DEFINE l_runner CHAR(200) 
	DEFINE l_err_message CHAR(100)

	IF NOT modu_verbose_ind THEN 
		LET glob_rec_kandoouser.cmpy_code = get_url_company_code() #arg_val(1) 
		CALL valid_load_file(get_url_load_file())  #( arg_val(2) ) 
		RETURNING modu_load_file 
	END IF 
	IF modu_load_file IS NOT NULL THEN 
		#
		# Commence LOAD
		#
		LET modu_load_file = modu_load_file clipped 
		LET l_temp_file = modu_load_file clipped, ".tmp" 
		LET l_runner = "dos2ux ", modu_load_file clipped, " > ", 
		l_temp_file clipped 
		RUN l_runner 
		WHENEVER ERROR CONTINUE 
		LOAD FROM l_temp_file INSERT INTO jmj_voucher 
		WHENEVER ERROR stop 
		IF sqlca.sqlcode != 0 THEN 
			#
			# Dummy line in REPORT TO force DISPLAY of Control Totals
			#
			#---------------------------------------------------------
			OUTPUT TO REPORT PSU_J_rpt_list_load(rpt_rmsreps_idx_get_idx("PSU_J_rpt_list_load"),
			 '', '', '', '', '', '' )
			#---------------------------------------------------------	

			#
			# count total no. of vouchers TO be generated
			#
			SELECT count(*) INTO modu_process_cnt 
			FROM jmj_voucher 
			IF modu_process_cnt IS NULL THEN 
				LET modu_process_cnt = 0 
			END IF 
			LET modu_loadfile_cnt = modu_process_cnt - modu_rerun_cnt 
			#
			# REPORT error
			#
			LET modu_err2_cnt = modu_err2_cnt + 1 
			LET l_err_message = "Refer to", trim(get_settings_logFile()), " FOR SQL Error: ", modu_load_cnt, " ", 
			"in Load File:",modu_load_file clipped 

			#---------------------------------------------------------
			OUTPUT TO REPORT PSU_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("PSU_J_rpt_list_exception"),
			'', '', '', l_err_message ) 
			#---------------------------------------------------------	

			LET l_err_text = "PSU - ",err_get( modu_load_cnt ) 
			CALL errorlog( l_err_text ) 

			#---------------------------------------------------------
			OUTPUT TO REPORT PSU_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("PSU_J_rpt_list_exception"),
			'', '', '', l_err_text ) 
			#---------------------------------------------------------	


			#
			# FOR reporting purposes SET no. records processed
			#
			LET modu_load_cnt = 0 
		END IF 
	END IF 
END FUNCTION 


############################################################
# FUNCTION null_tests()
#
# Null Test's on data fields
############################################################
FUNCTION null_tests() 
	DEFINE l_rec_jmjvoucher RECORD LIKE jmj_voucher.* 
	DEFINE l_err_message CHAR(100)

	DECLARE c_jmjvoucher CURSOR FOR 
	SELECT * FROM jmj_voucher 
	WHERE ctrn_process_grp IS NULL 
	OR ctrn_no IS NULL 
	OR ctrn_age IS NULL 
	OR ctrn_datex IS NULL 
	OR ctrn_genled IS NULL 
	OR ctrn_amt IS NULL 
	OR ctrn_no = ' ' 
	OR ctrn_genled = ' ' 
	FOREACH c_jmjvoucher INTO l_rec_jmjvoucher.* 
		IF l_rec_jmjvoucher.ctrn_genled IS NULL 
		OR l_rec_jmjvoucher.ctrn_genled = ' ' THEN 
			LET modu_err_cnt = modu_err_cnt + 1 
			LET l_err_message = "Null GL Account detected" 

			#---------------------------------------------------------
			OUTPUT TO REPORT PSU_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("PSU_J_rpt_list_exception"),
			l_rec_jmjvoucher.ctrn_process_grp, 
			l_rec_jmjvoucher.ctrn_no, 
			l_rec_jmjvoucher.ctrn_pono, 
			l_err_message )  
			#---------------------------------------------------------	

			CONTINUE FOREACH 
		END IF 
		IF l_rec_jmjvoucher.ctrn_no IS NULL 
		OR l_rec_jmjvoucher.ctrn_no = ' ' THEN 
			LET modu_err_cnt = modu_err_cnt + 1 
			LET l_err_message = "Null Creditor Code detected" 

			#---------------------------------------------------------
			OUTPUT TO REPORT PSU_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("PSU_J_rpt_list_exception"),
			l_rec_jmjvoucher.ctrn_process_grp, 
			l_rec_jmjvoucher.ctrn_no, 
			l_rec_jmjvoucher.ctrn_pono, 
			l_err_message ) 
			#---------------------------------------------------------
			

			CONTINUE FOREACH 
		END IF 
		IF l_rec_jmjvoucher.ctrn_process_grp IS NULL THEN 
			LET modu_err_cnt = modu_err_cnt + 1 
			LET l_err_message = "Null Processing Group detected" 

			#---------------------------------------------------------
			OUTPUT TO REPORT PSU_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("PSU_J_rpt_list_exception"),
			l_rec_jmjvoucher.ctrn_process_grp, 
			l_rec_jmjvoucher.ctrn_no, 
			l_rec_jmjvoucher.ctrn_pono, 
			l_err_message ) 
			#---------------------------------------------------------
			
			CONTINUE FOREACH 
		END IF 
		IF l_rec_jmjvoucher.ctrn_age IS NULL THEN 
			LET modu_err_cnt = modu_err_cnt + 1 
			LET l_err_message = "Null Trans. Period detected" 

			#---------------------------------------------------------
			OUTPUT TO REPORT PSU_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("PSU_J_rpt_list_exception"),
			l_rec_jmjvoucher.ctrn_process_grp, 
			l_rec_jmjvoucher.ctrn_no, 
			l_rec_jmjvoucher.ctrn_pono, 
			l_err_message ) 
			#---------------------------------------------------------

			CONTINUE FOREACH 
		END IF 
		IF l_rec_jmjvoucher.ctrn_datex IS NULL THEN 
			LET modu_err_cnt = modu_err_cnt + 1 
			LET l_err_message = "Null Trans. Date detected" 

			#---------------------------------------------------------
			OUTPUT TO REPORT PSU_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("PSU_J_rpt_list_exception"),
			l_rec_jmjvoucher.ctrn_process_grp, 
			l_rec_jmjvoucher.ctrn_no, 
			l_rec_jmjvoucher.ctrn_pono, 
			l_err_message ) 
			#---------------------------------------------------------

			CONTINUE FOREACH 
		END IF 
		IF l_rec_jmjvoucher.ctrn_amt IS NULL THEN 
			LET modu_err_cnt = modu_err_cnt + 1 
			LET l_err_message = "Null Payment Value detected" 

			#---------------------------------------------------------
			OUTPUT TO REPORT PSU_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("PSU_J_rpt_list_exception"),
			l_rec_jmjvoucher.ctrn_process_grp, 
			l_rec_jmjvoucher.ctrn_no, 
			l_rec_jmjvoucher.ctrn_pono, 
			l_err_message ) 
			#---------------------------------------------------------

			CONTINUE FOREACH 
		END IF 
	END FOREACH 
END FUNCTION 



############################################################
# FUNCTION setup_cnt()
#
# count total no. of vouchers TO be generated
############################################################
FUNCTION setup_cnt() 

	SELECT count(*) INTO modu_process_cnt 
	FROM jmj_voucher 
	IF modu_process_cnt IS NULL THEN 
		LET modu_process_cnt = 0 
	END IF 
	LET modu_loadfile_cnt = modu_process_cnt - modu_rerun_cnt 
END FUNCTION 




############################################################
# FUNCTION get_fiscal()
#
#
############################################################
FUNCTION get_fiscal() 
	IF modu_verbose_ind THEN 
		IF NOT enter_fiscal() THEN 

			#---------------------------------------------------------
			OUTPUT TO REPORT PSU_J_rpt_list_load(rpt_rmsreps_idx_get_idx("PSU_J_rpt_list_load"),
			 '', '', '', '', '', '' )
			#---------------------------------------------------------	
 
			RETURN false 
		END IF 
	ELSE 
		#
		# year / period defaulted TO today
		#
		CALL db_period_what_period( glob_rec_kandoouser.cmpy_code, today ) 
		RETURNING modu_rec_period.year_num, 
		modu_rec_period.period_num 
	END IF 
	RETURN true 
END FUNCTION 



############################################################
# FUNCTION create_ap_entry()
#
#
############################################################
FUNCTION create_ap_entry() 
	DEFINE l_rec_term RECORD LIKE term.* 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_voucher RECORD LIKE voucher.* 
	DEFINE l_rec_voucherdist RECORD LIKE voucherdist.* 
	DEFINE l_rec_debithead RECORD LIKE debithead.* 
	DEFINE l_rec_debitdist RECORD LIKE debitdist.* 
	DEFINE l_rec_vouchpayee RECORD LIKE vouchpayee.* 
	DEFINE l_ap_per DECIMAL(6,3) 
	DEFINE l_rec_jmjvoucher RECORD LIKE jmj_voucher.* 
	DEFINE l_acct_text CHAR(50) ## status OF coa account 
	DEFINE l_vouch_code LIKE voucher.vouch_code 
	DEFINE l_debit_num LIKE debithead.debit_num 
	DEFINE l_voucher_due_date LIKE voucher.due_date 
	DEFINE l_voucher_disc_date LIKE voucher.disc_date 
	DEFINE l_rowid INTEGER 
	DEFINE l_sel_01_ind SMALLINT 
	DEFINE l_sel_no_ind SMALLINT 
	DEFINE l_hold_01_ind SMALLINT 
	DEFINE l_hold_no_ind SMALLINT 
	DEFINE l_cmpy_code LIKE company.cmpy_code 
	DEFINE l_query_text CHAR(2200) 
	DEFINE l_err_message CHAR(100)

	LET l_sel_01_ind = 0 
	LET l_sel_no_ind = 0 
	LET modu_ap_cnt = 0 
	LET l_ap_per = 0 
	SELECT count(*) INTO modu_jmj_ap_cnt 
	FROM jmj_voucher 
	WHERE ctrn_process_grp IS NOT NULL 
	AND ctrn_no IS NOT NULL 
	AND ctrn_age IS NOT NULL 
	AND ctrn_datex IS NOT NULL 
	AND ctrn_genled IS NOT NULL 
	AND ctrn_amt IS NOT NULL 
	AND ctrn_no != ' ' 
	AND ctrn_genled != ' ' 
	IF modu_jmj_ap_cnt IS NULL THEN 
		LET modu_jmj_ap_cnt = 0 
	END IF 
	IF NOT modu_jmj_ap_cnt THEN 
		LET l_err_message = "No AP Vouchers TO be generated" 

		#---------------------------------------------------------
		OUTPUT TO REPORT PSU_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("PSU_J_rpt_list_exception"),
		'', '', '', l_err_message )
		#---------------------------------------------------------

		RETURN 
	END IF 
	IF modu_verbose_ind THEN 
		DISPLAY modu_kandoo_ap_cnt,modu_jmj_ap_cnt,l_ap_per TO max_ap_cnt,jmj_ap_cnt,ap_per   
	END IF 
	#
	# Declare dynamic CURSOR
	#
	LET l_query_text = " SELECT acct_code ", 
	" FROM jmj_glacct ", 
	" WHERE cmpy_code = ? ", 
	" AND gl_code = ? " 
	PREPARE s_glacct FROM l_query_text 
	DECLARE c_glacct CURSOR with HOLD FOR s_glacct 
	#
	#
	# Create AP Vouchers
	#
	#
	DECLARE c1_jmjvoucher CURSOR with HOLD FOR 
	SELECT rowid, * 
	FROM jmj_voucher 
	WHERE ctrn_process_grp IS NOT NULL 
	AND ctrn_no IS NOT NULL 
	AND ctrn_age IS NOT NULL 
	AND ctrn_datex IS NOT NULL 
	AND ctrn_genled IS NOT NULL 
	AND ctrn_amt IS NOT NULL 
	AND ctrn_no != ' ' 
	AND ctrn_genled != ' ' 
	AND ctrn_amt >= 0 
	FOREACH c1_jmjvoucher INTO l_rowid, 
		l_rec_jmjvoucher.* 
		IF int_flag OR quit_flag THEN 
			IF modu_verbose_ind THEN 
				#8004 Do you wish TO quit (Y/N) ?
				IF kandoomsg("A",8004,"") = 'Y' THEN 
					EXIT FOREACH 
				END IF 
			ELSE 
				EXIT FOREACH 
			END IF 
			LET int_flag = false 
			LET quit_flag = false 
		END IF 
		#
		# Calculate percentage complete
		#
		LET modu_ap_cnt = modu_ap_cnt + 1 
		LET l_ap_per = ( modu_ap_cnt / modu_jmj_ap_cnt ) * 100 
		IF modu_verbose_ind THEN 
			LET l_rec_vendor.vend_code = l_rec_jmjvoucher.ctrn_no 
			DISPLAY l_ap_per,modu_ap_cnt,l_rec_vendor.vend_code,l_rec_vendor.name_text TO ap_per,ap_cnt,vend_code,name_text   

		END IF 
		#
		# Retrieve glob_rec_kandoouser.cmpy_code
		#
		IF ( l_rec_jmjvoucher.ctrn_process_grp >= 20 
		AND l_rec_jmjvoucher.ctrn_process_grp <= 29 ) THEN 
			LET l_cmpy_code = modu_auto_cmpy_code 
		ELSE 
			LET l_cmpy_code = modu_jmj_cmpy_code 
		END IF 
		#
		# Validate year / period SET up FOR AP AT glob_rec_kandoouser.cmpy_code
		#
		IF NOT valid_period2( l_cmpy_code, 
		modu_rec_period.year_num, 
		modu_rec_period.period_num, 
		'AP' ) THEN 
			LET modu_err_cnt = modu_err_cnt + 1 
			LET l_err_message = "Accounting period IS closed OR NOT SET up ", 
			"FOR ",modu_rec_period.year_num,"/",modu_rec_period.period_num, 
			" AT Cmpy:",l_cmpy_code 

			#---------------------------------------------------------
			OUTPUT TO REPORT PSU_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("PSU_J_rpt_list_exception"),
			l_rec_jmjvoucher.ctrn_process_grp, 
			l_rec_jmjvoucher.ctrn_no, 
			l_rec_jmjvoucher.ctrn_pono, 
			l_err_message ) 
			#---------------------------------------------------------
			
			CONTINUE FOREACH 
		END IF 
		#
		#
		# Create Voucher
		#
		#
		INITIALIZE l_rec_vendor.* TO NULL 
		SELECT * INTO l_rec_vendor.* 
		FROM vendor 
		WHERE cmpy_code = l_cmpy_code 
		AND vend_code = l_rec_jmjvoucher.ctrn_no 
		IF sqlca.sqlcode = NOTFOUND THEN 
			LET modu_err_cnt = modu_err_cnt + 1 
			LET l_err_message = "Vendor:", l_rec_jmjvoucher.ctrn_no clipped, " ", 
			"NOT SET up AT Cmpy:",l_cmpy_code 

			#---------------------------------------------------------
			OUTPUT TO REPORT PSU_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("PSU_J_rpt_list_exception"),
			l_rec_jmjvoucher.ctrn_process_grp, 
			l_rec_jmjvoucher.ctrn_no, 
			l_rec_jmjvoucher.ctrn_pono, 
			l_err_message ) 
			#---------------------------------------------------------

			CONTINUE FOREACH 
		END IF 
		IF modu_verbose_ind THEN 
			DISPLAY BY NAME l_rec_vendor.vend_code, 
			l_rec_vendor.name_text 

		END IF 
		INITIALIZE l_rec_voucher.* TO NULL 
		INITIALIZE l_rec_vouchpayee.* TO NULL 
		LET l_rec_voucher.cmpy_code = l_cmpy_code 
		LET l_rec_voucher.vend_code = l_rec_jmjvoucher.ctrn_no 
		#
		# Null moved INTO inv_text b/c of problems in calling P29f
		# AND it's attempt TO INSERT INTO vendorinvs
		#
		LET l_rec_voucher.inv_text = l_rec_jmjvoucher.ctrn_pono 
		LET l_rec_voucher.po_num = NULL 
		LET l_rec_voucher.vouch_date = l_rec_jmjvoucher.ctrn_datex 
		LET l_rec_voucher.entry_code = glob_rec_kandoouser.sign_on_code 
		LET l_rec_voucher.entry_date = today 
		LET l_rec_voucher.sales_text = NULL 
		LET l_rec_voucher.term_code = l_rec_vendor.term_code 
		LET l_rec_voucher.tax_code = l_rec_vendor.tax_code 
		LET l_rec_voucher.goods_amt = l_rec_jmjvoucher.ctrn_amt 
		LET l_rec_voucher.tax_amt = 0 
		LET l_rec_voucher.total_amt = l_rec_jmjvoucher.ctrn_amt 
		LET l_rec_voucher.paid_amt = 0 
		LET l_rec_voucher.dist_qty = NULL 
		LET l_rec_voucher.dist_amt = 0 
		LET l_rec_voucher.taken_disc_amt = 0 
		LET l_rec_voucher.paid_date = NULL 
		
		CALL db_term_get_rec(UI_OFF,l_rec_voucher.term_code) RETURNING l_rec_term.*
		IF sqlca.sqlcode = 0 THEN 
			CALL get_due_and_discount_date( l_rec_term.*, l_rec_voucher.vouch_date ) 
			RETURNING l_voucher_due_date, l_voucher_disc_date 
		ELSE 
			LET modu_err_cnt = modu_err_cnt + 1 
			LET l_err_message = "Term code: ",l_rec_vendor.term_code, 
			" NOT SET up AT Cmpy: ", l_rec_vendor.cmpy_code 

			#---------------------------------------------------------
			OUTPUT TO REPORT PSU_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("PSU_J_rpt_list_exception"),
			l_rec_jmjvoucher.ctrn_process_grp, 
			l_rec_jmjvoucher.ctrn_no, 
			l_rec_jmjvoucher.ctrn_pono, 
			l_err_message) 
			#---------------------------------------------------------
			
		END IF 
		IF l_rec_jmjvoucher.ctrn_duedatex IS NULL THEN 
			LET l_rec_voucher.due_date = l_voucher_due_date 
		ELSE 
			LET l_rec_voucher.due_date = l_rec_jmjvoucher.ctrn_duedatex 
		END IF 
		IF l_rec_jmjvoucher.ctrn_discdtex IS NULL THEN 
			LET l_rec_voucher.disc_date = l_voucher_disc_date 
		ELSE 
			LET l_rec_voucher.disc_date = l_rec_jmjvoucher.ctrn_discdtex 
		END IF 
		IF l_rec_jmjvoucher.ctrn_discamt IS NULL THEN 
			IF l_rec_term.disc_day_num > 0 THEN 
				LET l_rec_voucher.poss_disc_amt = l_rec_voucher.total_amt 
				* l_rec_term.disc_per/100 
			ELSE 
				LET l_rec_voucher.poss_disc_amt = 0 
			END IF 
		ELSE 
			LET l_rec_voucher.poss_disc_amt = l_rec_jmjvoucher.ctrn_discamt 
		END IF 
		LET l_rec_voucher.hist_flag = 'N' 
		LET l_rec_voucher.jour_num = 0 
		LET l_rec_voucher.post_flag = 'N' 
		LET l_rec_voucher.year_num = modu_rec_period.year_num 
		LET l_rec_voucher.period_num = modu_rec_period.period_num 
		LET l_rec_voucher.pay_seq_num = 0 
		LET l_rec_voucher.line_num = 0 
		LET l_rec_voucher.com1_text = l_rec_jmjvoucher.ctrn_com 
		LET l_rec_voucher.com2_text = l_rec_jmjvoucher.ctrn_unpaidx 
		IF l_rec_jmjvoucher.ctrn_age = 9 THEN 
			LET l_rec_voucher.hold_code = '01' 
			#
			# Following code used TO reduce amount of DB I/O
			#
			IF NOT l_sel_01_ind THEN 
				SELECT 1 FROM holdpay 
				WHERE hold_code = l_rec_voucher.hold_code 
				AND cmpy_code = l_cmpy_code 
				IF sqlca.sqlcode = 0 THEN 
					LET l_sel_01_ind = true 
					LET l_hold_01_ind = true 
				ELSE 
					LET l_sel_01_ind = true 
					LET l_hold_01_ind = false 
				END IF 
			END IF 
			IF NOT l_hold_01_ind THEN 
				LET modu_err_cnt = modu_err_cnt + 1 
				LET l_err_message = "Hold code 01 NOT SET up AT Cmpy:",l_cmpy_code

				#---------------------------------------------------------
				OUTPUT TO REPORT PSU_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("PSU_J_rpt_list_exception"),
				l_rec_jmjvoucher.ctrn_process_grp, 
					l_rec_jmjvoucher.ctrn_no, 
					l_rec_jmjvoucher.ctrn_pono, 
					l_err_message ) 
				#---------------------------------------------------------

				CONTINUE FOREACH 
			END IF 
		ELSE 
			LET l_rec_voucher.hold_code = 'NO' 
			#
			# Following code used TO reduce amount of DB I/O
			#
			IF NOT l_sel_no_ind THEN 
				SELECT 1 FROM holdpay 
				WHERE hold_code = l_rec_voucher.hold_code 
				AND cmpy_code = l_cmpy_code 
				IF sqlca.sqlcode = 0 THEN 
					LET l_sel_no_ind = true 
					LET l_hold_no_ind = true 
				ELSE 
					LET l_sel_no_ind = true 
					LET l_hold_no_ind = false 
				END IF 
			END IF 
			
			IF NOT l_hold_no_ind THEN 
				LET modu_err_cnt = modu_err_cnt + 1 
				LET l_err_message = "Hold code NO NOT SET up AT Cmpy:",l_cmpy_code 

				#---------------------------------------------------------
				OUTPUT TO REPORT PSU_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("PSU_J_rpt_list_exception"),
				l_rec_jmjvoucher.ctrn_process_grp, 
				l_rec_jmjvoucher.ctrn_no, 
				l_rec_jmjvoucher.ctrn_pono, 
				l_err_message ) 
				#---------------------------------------------------------
				
				CONTINUE FOREACH 
			END IF 
		END IF 
		IF glob_rec_apparms.vouch_approve_flag = "Y" THEN 
			LET l_rec_voucher.approved_code = "N" 
		ELSE 
			LET l_rec_voucher.approved_code = "Y" 
		END IF 
		LET l_rec_voucher.approved_by_code = NULL 
		LET l_rec_voucher.approved_date = NULL 
		LET l_rec_voucher.split_from_num = 0 
		LET l_rec_voucher.currency_code = 'AUD' 
		LET l_rec_voucher.conv_qty = 1 
		LET l_rec_voucher.post_date = NULL 
		LET l_rec_voucher.source_ind = '1' 
		LET l_rec_voucher.source_text = NULL 
		LET l_rec_voucher.withhold_tax_ind = '0' 
		INITIALIZE l_rec_voucherdist.* TO NULL 
		LET l_rec_voucher.line_num = l_rec_voucher.line_num + 1 
		LET l_rec_voucherdist.cmpy_code = l_rec_voucher.cmpy_code 
		LET l_rec_voucherdist.vend_code = l_rec_voucher.vend_code 
		LET l_rec_voucherdist.vouch_code = l_rec_voucher.vouch_code 
		LET l_rec_voucherdist.line_num = l_rec_voucher.line_num 
		LET l_rec_voucherdist.type_ind = 'G' 
		OPEN c_glacct USING l_cmpy_code, 
		l_rec_jmjvoucher.ctrn_genled 
		FETCH c_glacct INTO l_rec_voucherdist.acct_code 
		IF sqlca.sqlcode = NOTFOUND THEN 
			LET modu_err_cnt = modu_err_cnt + 1 
			LET l_err_message = "Account code NOT SET up FOR GL Code:", 
			l_rec_jmjvoucher.ctrn_genled, " ",	"at Cmpy:",l_cmpy_code 
			
			#---------------------------------------------------------
			OUTPUT TO REPORT PSU_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("PSU_J_rpt_list_exception"),
			l_rec_jmjvoucher.ctrn_process_grp, 
			l_rec_jmjvoucher.ctrn_no, 
			l_rec_jmjvoucher.ctrn_pono, 
			l_err_message ) 
			#---------------------------------------------------------
			
			CONTINUE FOREACH 
		END IF 
		CALL verify_acct( l_rec_voucher.cmpy_code, 
		l_rec_voucherdist.acct_code, 
		l_rec_voucher.year_num, 
		l_rec_voucher.period_num ) 
		RETURNING l_acct_text 
		IF l_acct_text != l_rec_voucherdist.acct_code THEN 
			LET modu_err_cnt = modu_err_cnt + 1 
			LET l_err_message = l_acct_text 

			#---------------------------------------------------------
			OUTPUT TO REPORT PSU_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("PSU_J_rpt_list_exception"),
			l_rec_jmjvoucher.ctrn_process_grp, 
			l_rec_jmjvoucher.ctrn_no, 
			l_rec_jmjvoucher.ctrn_pono, 
			l_err_message ) 
			#---------------------------------------------------------
			
			CONTINUE FOREACH 
		END IF 
		IF NOT acct_type(l_rec_voucher.cmpy_code, l_rec_voucherdist.acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"N") THEN 
			LET modu_err_cnt = modu_err_cnt + 1 
			LET l_err_message = "Transaction Account: ",l_rec_voucherdist.acct_code,	"cannot be control OR bank account" 

			#---------------------------------------------------------
			OUTPUT TO REPORT PSU_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("PSU_J_rpt_list_exception"),
			l_rec_jmjvoucher.ctrn_process_grp, 
			l_rec_jmjvoucher.ctrn_no, 
			l_rec_jmjvoucher.ctrn_pono, 
			l_err_message ) 
			#---------------------------------------------------------

			CONTINUE FOREACH 
		END IF 
		LET l_rec_voucherdist.desc_text = 'fleet management system ', 
		l_rec_jmjvoucher.ctrn_genled 
		LET l_rec_voucherdist.dist_qty = NULL 
		LET l_rec_voucherdist.dist_amt = l_rec_jmjvoucher.ctrn_amt 
		LET l_rec_voucherdist.analysis_text = NULL 
		LET l_rec_voucherdist.res_code = NULL 
		LET l_rec_voucherdist.job_code = NULL 
		LET l_rec_voucherdist.var_code = NULL 
		LET l_rec_voucherdist.act_code = NULL 
		LET l_rec_voucherdist.po_num = NULL 
		LET l_rec_voucherdist.po_line_num = NULL 
		LET l_rec_voucherdist.trans_qty = NULL 
		LET l_rec_voucherdist.cost_amt = NULL 
		LET l_rec_voucherdist.charge_amt = NULL 
		INSERT INTO t_voucherdist VALUES ( l_rec_voucherdist.* ) 
		LET l_vouch_code = update_voucher_related_tables(l_rec_voucher.cmpy_code,glob_rec_kandoouser.sign_on_code, 
		'1', l_rec_voucher.*,l_rec_vouchpayee.* ) 
		IF l_vouch_code > 0 THEN 
			DELETE FROM jmj_voucher 
			WHERE rowid = l_rowid 
			SELECT * INTO l_rec_voucher.* 
			FROM voucher 
			WHERE vouch_code = l_vouch_code 
			AND cmpy_code = l_cmpy_code 
			IF sqlca.sqlcode = 0 THEN 
				LET modu_kandoo_ap_cnt = modu_kandoo_ap_cnt + 1 
				LET modu_kandoo_vo_cnt = modu_kandoo_vo_cnt + 1 
				IF modu_verbose_ind THEN 
					DISPLAY modu_kandoo_ap_cnt TO max_ap_cnt 
				END IF 

				#---------------------------------------------------------
				OUTPUT TO REPORT PSU_J_rpt_list_load(rpt_rmsreps_idx_get_idx("PSU_J_rpt_list_load"),
				l_rec_voucher.cmpy_code, 
				l_rec_voucher.vend_code , 
				l_rec_voucher.vouch_code, 
				'', 
				l_rec_voucher.line_num , 
				l_rec_voucher.total_amt ) 
				#---------------------------------------------------------	
				
			END IF 
		ELSE 
			LET modu_err2_cnt = modu_err2_cnt + 1 
			LET l_err_message = "Error inserting Voucher" 

			#---------------------------------------------------------
			OUTPUT TO REPORT PSU_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("PSU_J_rpt_list_exception"),
			l_rec_jmjvoucher.ctrn_process_grp, 
			l_rec_jmjvoucher.ctrn_no, 
			l_rec_jmjvoucher.ctrn_pono, 
			l_err_message ) 
			#---------------------------------------------------------
			
		END IF 
		DELETE FROM t_voucherdist WHERE 1 = 1 
	END FOREACH 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN 
	END IF 
	
	#
	#
	# Create Debit
	#
	#
	DECLARE c2_jmjvoucher CURSOR with HOLD FOR 
	SELECT rowid, * 
	FROM jmj_voucher 
	WHERE ctrn_process_grp IS NOT NULL 
	AND ctrn_no IS NOT NULL 
	AND ctrn_age IS NOT NULL 
	AND ctrn_datex IS NOT NULL 
	AND ctrn_genled IS NOT NULL 
	AND ctrn_amt IS NOT NULL 
	AND ctrn_no != ' ' 
	AND ctrn_genled != ' ' 
	AND ctrn_amt < 0 
	FOREACH c2_jmjvoucher INTO l_rowid, 
		l_rec_jmjvoucher.* 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			IF modu_verbose_ind THEN 
				#8004 Do you wish TO quit (Y/N) ?
				IF kandoomsg("A",8004,"") = 'Y' THEN 
					EXIT FOREACH 
				END IF 
			ELSE 
				EXIT FOREACH 
			END IF 
		END IF 
		#
		# Calculate percentage complete
		#
		LET modu_ap_cnt = modu_ap_cnt + 1 
		LET l_ap_per = ( modu_ap_cnt / modu_jmj_ap_cnt ) * 100 
		IF modu_verbose_ind THEN 
			LET l_rec_vendor.vend_code = l_rec_jmjvoucher.ctrn_no 
			DISPLAY l_ap_per,modu_ap_cnt,l_rec_vendor.vend_code,l_rec_vendor.name_text TO ap_per,ap_cnt,vend_code,name_text 

		END IF 
		#
		# Retrieve cmpy
		#
		IF ( l_rec_jmjvoucher.ctrn_process_grp >= 20 
		AND l_rec_jmjvoucher.ctrn_process_grp <= 29 ) THEN 
			LET l_cmpy_code = modu_auto_cmpy_code 
		ELSE 
			LET l_cmpy_code = modu_jmj_cmpy_code 
		END IF 
		#
		# Validate year / period SET up FOR AP AT cmpy
		#
		IF NOT valid_period2( l_cmpy_code, 
		modu_rec_period.year_num, 
		modu_rec_period.period_num, 
		'AP' ) THEN 
			LET modu_err_cnt = modu_err_cnt + 1 
			LET l_err_message = "Accounting period IS closed OR NOT SET up ", 
			"FOR ",modu_rec_period.year_num,"/",modu_rec_period.period_num, 
			" AT Cmpy:",l_cmpy_code 

			#---------------------------------------------------------
			OUTPUT TO REPORT PSU_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("PSU_J_rpt_list_exception"),
			l_rec_jmjvoucher.ctrn_process_grp, 
			l_rec_jmjvoucher.ctrn_no, 
			l_rec_jmjvoucher.ctrn_pono, 
			l_err_message ) 
			#---------------------------------------------------------

			CONTINUE FOREACH 
		END IF 
		#
		#
		# Create Debit
		#
		#
		INITIALIZE l_rec_vendor.* TO NULL 
		SELECT * INTO l_rec_vendor.* 
		FROM vendor 
		WHERE cmpy_code = l_cmpy_code 
		AND vend_code = l_rec_jmjvoucher.ctrn_no 
		IF sqlca.sqlcode = NOTFOUND THEN 
			LET modu_err_cnt = modu_err_cnt + 1 
			LET l_err_message = "Vendor:", l_rec_jmjvoucher.ctrn_no clipped, " ",		"NOT SET up AT Cmpy:",l_cmpy_code 

			#---------------------------------------------------------
			OUTPUT TO REPORT PSU_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("PSU_J_rpt_list_exception"),
			l_rec_jmjvoucher.ctrn_process_grp, 
			l_rec_jmjvoucher.ctrn_no, 
			l_rec_jmjvoucher.ctrn_pono, 
			l_err_message ) 
			#---------------------------------------------------------

			CONTINUE FOREACH 
		END IF 
		IF modu_verbose_ind THEN 
			DISPLAY BY NAME l_rec_vendor.vend_code, 
			l_rec_vendor.name_text 

		END IF 
		INITIALIZE l_rec_debithead.* TO NULL 
		LET l_rec_debithead.cmpy_code = l_cmpy_code 
		LET l_rec_debithead.vend_code = l_rec_jmjvoucher.ctrn_no 
		LET l_rec_debithead.debit_text = l_rec_jmjvoucher.ctrn_pono 
		LET l_rec_debithead.rma_num = NULL 
		LET l_rec_debithead.debit_date = l_rec_jmjvoucher.ctrn_datex 
		LET l_rec_debithead.entry_code = glob_rec_kandoouser.sign_on_code 
		LET l_rec_debithead.entry_date = today 
		LET l_rec_debithead.contact_text = NULL 
		LET l_rec_debithead.tax_code = l_rec_vendor.tax_code 
		LET l_rec_debithead.goods_amt = 0 - l_rec_jmjvoucher.ctrn_amt 
		LET l_rec_debithead.tax_amt = 0 
		LET l_rec_debithead.total_amt = 0 - l_rec_jmjvoucher.ctrn_amt 
		LET l_rec_debithead.dist_qty = 0 
		LET l_rec_debithead.dist_amt = 0 
		LET l_rec_debithead.apply_amt = 0 
		LET l_rec_debithead.disc_amt = 0 
		LET l_rec_debithead.hist_flag = 'N' 
		LET l_rec_debithead.jour_num = 0 
		LET l_rec_debithead.post_flag = 'N' 
		LET l_rec_debithead.year_num = modu_rec_period.year_num 
		LET l_rec_debithead.period_num = modu_rec_period.period_num 
		LET l_rec_debithead.appl_seq_num = 0 
		LET l_rec_debithead.com1_text = l_rec_jmjvoucher.ctrn_com 
		LET l_rec_debithead.com2_text = l_rec_jmjvoucher.ctrn_unpaidx 
		LET l_rec_debithead.currency_code = 'AUD' 
		LET l_rec_debithead.conv_qty = 1 
		LET l_rec_debithead.post_date = NULL 
		#
		# Debit Distribution
		#
		INITIALIZE l_rec_debitdist.* TO NULL 
		LET l_rec_debitdist.cmpy_code = l_rec_debithead.cmpy_code 
		LET l_rec_debitdist.vend_code = l_rec_debithead.vend_code 
		LET l_rec_debitdist.line_num = 1 
		OPEN c_glacct USING l_cmpy_code, 
		l_rec_jmjvoucher.ctrn_genled 
		FETCH c_glacct INTO l_rec_debitdist.acct_code 
		IF sqlca.sqlcode = NOTFOUND THEN 
			LET modu_err_cnt = modu_err_cnt + 1 
			LET l_err_message = "Account code NOT SET up FOR GL Code:",	l_rec_jmjvoucher.ctrn_genled, " ",	"at Cmpy:",l_cmpy_code 

			#---------------------------------------------------------
			OUTPUT TO REPORT PSU_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("PSU_J_rpt_list_exception"),
			l_rec_jmjvoucher.ctrn_process_grp, 
			l_rec_jmjvoucher.ctrn_no, 
			l_rec_jmjvoucher.ctrn_pono, 
			l_err_message ) 
			#---------------------------------------------------------
			
			CONTINUE FOREACH 
		END IF 
		
		CALL verify_acct( l_rec_debithead.cmpy_code, 
		l_rec_debitdist.acct_code, 
		l_rec_debithead.year_num, 
		l_rec_debithead.period_num ) 
		RETURNING l_acct_text 
		IF l_acct_text != l_rec_debitdist.acct_code THEN 
			LET modu_err_cnt = modu_err_cnt + 1 
			LET l_err_message = l_acct_text 

			#---------------------------------------------------------
			OUTPUT TO REPORT PSU_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("PSU_J_rpt_list_exception"),
			l_rec_jmjvoucher.ctrn_process_grp, 
			l_rec_jmjvoucher.ctrn_no, 
			l_rec_jmjvoucher.ctrn_pono, 
			l_err_message ) 
			#---------------------------------------------------------
						
			CONTINUE FOREACH 
		END IF 
		IF NOT acct_type(l_rec_debithead.cmpy_code, l_rec_debitdist.acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"N") THEN 
			LET modu_err_cnt = modu_err_cnt + 1 
			LET l_err_message = "Transaction Account: ",l_rec_debitdist.acct_code,		"cannot be control OR bank account" 

			#---------------------------------------------------------
			OUTPUT TO REPORT PSU_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("PSU_J_rpt_list_exception"),
			l_rec_jmjvoucher.ctrn_process_grp, 
			l_rec_jmjvoucher.ctrn_no, 
			l_rec_jmjvoucher.ctrn_pono, 
			l_err_message ) 
			#---------------------------------------------------------

			CONTINUE FOREACH 
		END IF 
		LET l_rec_debitdist.desc_text = 'fleet management system', 
		l_rec_jmjvoucher.ctrn_genled 
		LET l_rec_debitdist.dist_qty = 0 
		LET l_rec_debitdist.dist_amt = 0 - l_rec_jmjvoucher.ctrn_amt 
		LET l_rec_debitdist.analysis_text = NULL 
		INSERT INTO t_debitdist VALUES ( l_rec_debitdist.* ) 
		#
		# Insert debithead & debitdist
		#
		LET l_debit_num = update_debit( l_rec_debithead.cmpy_code, glob_rec_kandoouser.sign_on_code, 
		'1', l_rec_debithead.* ) 
		IF l_debit_num > 0 THEN 
			DELETE FROM jmj_voucher 
			WHERE rowid = l_rowid 
			SELECT * INTO l_rec_debithead.* 
			FROM debithead 
			WHERE debit_num = l_debit_num 
			AND cmpy_code = l_cmpy_code 
			IF sqlca.sqlcode = 0 THEN 
				LET modu_kandoo_ap_cnt = modu_kandoo_ap_cnt + 1 
				LET modu_kandoo_db_cnt = modu_kandoo_db_cnt + 1 
				IF modu_verbose_ind THEN 
					DISPLAY modu_kandoo_ap_cnt TO max_ap_cnt
				END IF 

				#---------------------------------------------------------
				OUTPUT TO REPORT PSU_J_rpt_list_load(rpt_rmsreps_idx_get_idx("PSU_J_rpt_list_load"),
				l_rec_debithead.cmpy_code, 
				l_rec_debithead.vend_code , 
				'', 
				l_rec_debithead.debit_num , 
				'1', 
				l_rec_debithead.total_amt ) 
				#---------------------------------------------------------	

			END IF 
		ELSE 
			LET modu_err2_cnt = modu_err2_cnt + 1 
			LET l_err_message = "Error inserting Debit" 

			#---------------------------------------------------------
			OUTPUT TO REPORT PSU_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("PSU_J_rpt_list_exception"),
			l_rec_jmjvoucher.ctrn_process_grp, 
			l_rec_jmjvoucher.ctrn_no, 
			l_rec_jmjvoucher.ctrn_pono, 
			l_err_message ) 
			#---------------------------------------------------------
			
		END IF 
		DELETE FROM t_debitdist WHERE 1 = 1 
	END FOREACH 
END FUNCTION 


############################################################
# REPORT PSU_J_rpt_list_load(p_rpt_idx, p_cmpy_code, p_vend_code, p_vouch_code,
#                  p_debit_num, p_line_num , p_total_amt   )
#
#
############################################################
REPORT PSU_J_rpt_list_load(p_rpt_idx,p_cmpy_code,p_vend_code,p_vouch_code,p_debit_num,p_line_num,p_total_amt)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_vend_code LIKE customer.cust_code 
	DEFINE p_vouch_code LIKE voucher.vouch_code 
	DEFINE p_debit_num LIKE debithead.debit_num 
	DEFINE p_line_num LIKE voucher.line_num 
	DEFINE p_total_amt LIKE voucher.total_amt 
--	DEFINE l_arr_line ARRAY[4] OF CHAR(132)

	OUTPUT 

	ORDER external BY p_cmpy_code, 
	p_vend_code, 
	p_vouch_code, 
	p_debit_num
	 
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			SKIP 3 LINES
			 
		ON EVERY ROW 
			PRINT COLUMN 01, p_cmpy_code, 
			COLUMN 14, p_vend_code, 
			COLUMN 28, p_vouch_code USING "########" , 
			COLUMN 47, p_debit_num USING "########" , 
			COLUMN 77, p_line_num USING "########" , 
			COLUMN 116, p_total_amt USING "#############&.&&" 
			IF p_vouch_code IS NOT NULL THEN 
				LET modu_total_vouch_amt = modu_total_vouch_amt + p_total_amt 
			END IF 
			IF p_debit_num IS NOT NULL THEN 
				LET modu_total_debit_amt = modu_total_debit_amt + p_total_amt 
			END IF 

		ON LAST ROW 
			NEED 3 LINES 
			SKIP 2 LINES 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			
END REPORT 
############################################################
# END REPORT PSU_J_rpt_list_load(p_rpt_idx, p_cmpy_code, p_vend_code, p_vouch_code, p_debit_num, p_line_num , p_total_amt   )
############################################################


{
############################################################
# FUNCTION start_load_rep()
#
#
############################################################
FUNCTION start_load_rep() 
	LET glob_rec_kandooreport.report_code = "PSU" 
	CALL kandooreport( glob_rec_kandoouser.cmpy_code, glob_rec_kandooreport.report_code ) 
	RETURNING glob_rec_kandooreport.* 
	CALL set2_defaults() 
	LET modu_output = init_report( glob_rec_kandoouser.cmpy_code, glob_rec_kandoouser.sign_on_code, glob_rec_kandooreport.header_text ) 
	START REPORT PSU_J_rpt_list_load TO modu_output 

	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start(getmoduleid(),"PSU_J_rpt_list_load","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT PSU_J_rpt_list_load TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

END FUNCTION 
}
{
############################################################
# FUNCTION finish_load_rep()
#
#
############################################################
FUNCTION finish_load_rep() 
	FINISH REPORT PSU_J_rpt_list_load 
	CALL upd_reports( modu_output, glob_rpt_pageno2, glob_rec_kandooreport.width_num, 
	glob_rec_kandooreport.length_num ) 
END FUNCTION 
}

############################################################
# FUNCTION enter_fiscal()
#
#
############################################################
FUNCTION enter_fiscal() 
	DEFINE l_msgresp LIKE language.yes_flag 

	OPEN WINDOW p218 with FORM "P218" 
	CALL windecoration_p("P218") 

	LET l_msgresp=kandoomsg("P",1063,"") 
	#1063 Enter Voucher Load details - ESC TO Continue
	CALL db_period_what_period( glob_rec_kandoouser.cmpy_code, today ) 
	RETURNING modu_rec_period.year_num, 
	modu_rec_period.period_num 

	INPUT BY NAME modu_rec_period.year_num, 
	modu_rec_period.period_num WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","PSU_J","inp-period-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 
	END INPUT 

	CLOSE WINDOW p218 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 


############################################################
# FUNCTION rerun()
#
#
############################################################
FUNCTION rerun() 
	DEFINE r_rerun_ind SMALLINT 

	LET r_rerun_ind = true 
	SELECT count(*) INTO modu_rerun_cnt 
	FROM jmj_voucher 
	IF modu_rerun_cnt IS NULL THEN 
		LET modu_rerun_cnt = 0 
	END IF 
	IF modu_verbose_ind THEN 
		IF modu_rerun_cnt > 0 THEN 
			#7060 Warning: X entries detected in holding table. Continue (Y/N)?
			IF kandoomsg("A",7060,modu_rerun_cnt) = 'N' THEN 
				LET r_rerun_ind = false 
			END IF 
		END IF 
	END IF 
	RETURN r_rerun_ind 
END FUNCTION 



############################################################
# FUNCTION init_values()
#
# INITIALIZE default VALUES
############################################################
FUNCTION init_values() 
	LET modu_err_cnt = 0 
	LET modu_err2_cnt = 0 
	LET modu_kandoo_vo_cnt = 0 
	LET modu_kandoo_db_cnt = 0 
	LET modu_total_vouch_amt = 0 
	LET modu_total_debit_amt = 0 
	LET modu_rerun_cnt = NULL 
END FUNCTION 



############################################################
# FUNCTION start_load()
#
# standard execution ( used TO reduce duplication of code )
############################################################
FUNCTION start_load() 
	DEFINE l_rpt_idx SMALLINT  #report array index
	DEFINE l_msgresp LIKE language.yes_flag 

	--CALL start_ex_rep() 
	--CALL start_load_rep()

	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start("PSU_J_LOAD","PSU_J_rpt_list_load","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT PSU_J_rpt_list_load TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start("PSU_J_ERROR","PSU_J_rpt_list_exception","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT PSU_J_rpt_list_exception TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------
	 
	CALL init_values() 
	IF modu_verbose_ind THEN 
		IF import_voucher() THEN 
			CALL load_routine() 
			IF ( modu_err_cnt + modu_err2_cnt ) THEN 
				LET l_msgresp = kandoomsg("P",7036,(modu_err_cnt+modu_err2_cnt)) 
				#7036 AP Load Completed, Errors Encountered
			ELSE 
				IF modu_kandoo_ap_cnt > 0 THEN 
					LET l_msgresp = kandoomsg("P",7037,'') 
					#7037 AP Load Completed Successfully
				END IF 
			END IF 
		END IF 
	ELSE 
		#
		# Non-interactive load
		#
		CALL load_routine() 
	END IF 
	#
	# FINISH REPORT load_list() first b/c we need TO trigger 'ON LAST ROW'
	#        of PSU_J_rpt_list_exception() REPORT with Control Totals
	#
	--CALL finish_load_rep()
	--CALL finish_ex_rep()

	#------------------------------------------------------------
	FINISH REPORT PSU_J_rpt_list_load
	CALL rpt_finish("PSU_J_rpt_list_load")
	#------------------------------------------------------------
	#------------------------------------------------------------
	FINISH REPORT PSU_J_rpt_list_exception
	CALL rpt_finish("PSU_J_rpt_list_exception")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = FALSE 
		ERROR " Printing was aborted" 
		RETURN FALSE 
	ELSE 
		RETURN TRUE 
	END IF 
		 
END FUNCTION 



############################################################
# FUNCTION chk_tables()
#
# JMJ specific check's
############################################################
FUNCTION chk_tables() 
	DEFINE l_err_message CHAR(100)

	SELECT unique 1 FROM systables 
	WHERE tabname = "jmj_voucher" 
	IF sqlca.sqlcode = NOTFOUND THEN 
		LET modu_err2_cnt = modu_err2_cnt + 1 
		LET l_err_message = "Execute SQL script TO create JMJ Voucher table first ",	" Load Aborted"

		#---------------------------------------------------------
		OUTPUT TO REPORT PSU_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("PSU_J_rpt_list_exception"),
		'', '', '', l_err_message ) 
		#---------------------------------------------------------		 
 
		IF modu_verbose_ind THEN 
			ERROR l_err_message 
		END IF 

		#
		# Dummy line in REPORT TO force DISPLAY of Control Totals
		#
		#---------------------------------------------------------
		OUTPUT TO REPORT PSU_J_rpt_list_load(rpt_rmsreps_idx_get_idx("PSU_J_rpt_list_load"),
		 '', '', '', '', '', '' )
		#---------------------------------------------------------		  
		RETURN false 
	END IF 
	SELECT unique 1 FROM systables 
	WHERE tabname = "jmj_glacct" 
	IF sqlca.sqlcode = NOTFOUND THEN 
		LET modu_err2_cnt = modu_err2_cnt + 1 
		LET l_err_message = "Execute SQL script TO create JMJ GL table first ",	"- Load Aborted"

		#---------------------------------------------------------
		OUTPUT TO REPORT PSU_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("PSU_J_rpt_list_exception"),
		'', '', '', l_err_message ) 
		#---------------------------------------------------------	
 
		IF modu_verbose_ind THEN 
			ERROR "Execute SQL script TO create JMJ GL table first" 
		END IF 

		#---------------------------------------------------------
		OUTPUT TO REPORT PSU_J_rpt_list_load(rpt_rmsreps_idx_get_idx("PSU_J_rpt_list_load"),
		 '', '', '', '', '', '' )
		#---------------------------------------------------------	
		
		RETURN false 
	END IF 

	RETURN true 
END FUNCTION 



############################################################
# FUNCTION chk_setup()
#
# IF currency AUD NOT SET up THEN do NOT perform load
############################################################
FUNCTION chk_setup() 
	DEFINE l_err_message CHAR(100)

	SELECT 1 FROM currency 
	WHERE currency_code = 'AUD' 
	IF sqlca.sqlcode = NOTFOUND THEN 
		LET modu_err_cnt = modu_err_cnt + 1 
		LET l_err_message = "Currency: AUD NOT SET up - Load Aborted" 

		#---------------------------------------------------------
		OUTPUT TO REPORT PSU_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("PSU_J_rpt_list_exception"),
		'', '', '', l_err_message ) 
		#---------------------------------------------------------	
 
		RETURN false 
	END IF 
	RETURN true 
END FUNCTION 



############################################################
# FUNCTION my_unload()
#
# UNLOAD contents of interim table
############################################################
FUNCTION my_unload() 
	DEFINE l_temp_file CHAR(100) 
	DEFINE l_runner CHAR(300) 
	DEFINE l_unload_cnt INTEGER 

	IF import_voucher() THEN 
		LET l_temp_file = modu_load_file clipped, ".tmp" 
		#
		# Need TO SET l_runner here b/c of Informix Bug
		#
		# Informix Bug: After executing unload statement
		#               any subsequent references TO l_temp_file go screwy
		#
		LET l_runner = "ux2dos ", l_temp_file clipped, 
		" > ", modu_load_file clipped 
		UNLOAD TO l_temp_file SELECT * FROM jmj_voucher 
		LET sqlca.sqlcode = 0 
		IF sqlca.sqlcode = 0 THEN 
			LET l_unload_cnt = sqlca.sqlerrd[3] 
			IF l_unload_cnt IS NULL THEN 
				LET l_unload_cnt = 0 
			END IF 
			RUN l_runner 
			IF kandoomsg("A",8020,l_unload_cnt) = 'Y' THEN 
				#8020 <VALUE> records unloaded FROM table. Confirm TO CLEAR (Y/N)?
				DELETE FROM jmj_voucher 
			END IF 
		END IF 
	END IF 
END FUNCTION 



############################################################
# FUNCTION move_load_file()
#
#
############################################################
FUNCTION move_load_file() 
	DEFINE l_move_path CHAR(50) 
	DEFINE l_move_file CHAR(100) 
	DEFINE l_runner CHAR(300) 
	DEFINE l_file_name CHAR(100) 
	DEFINE l_ret_code INTEGER 

	LET l_move_path = "process" 
	LET l_move_file = l_move_path clipped, "/", modu_file_text 

	LET l_ret_code = os.path.exists(l_move_path) --huho changed TO os.path() 
	#LET l_runner = " [ -d ",l_move_path clipped," ] 2>>", trim(get_settings_logFile())
	#run l_runner returning l_ret_code
	IF l_ret_code THEN 
		IF modu_verbose_ind THEN 
			ERROR " Directory process does NOT exist" 
		END IF 
		RETURN 
	END IF 

	#LET l_runner = " [ -w ",l_move_path clipped," ] 2>>", trim(get_settings_logFile())
	#run l_runner returning l_ret_code
	LET l_ret_code = os.path.writable(l_move_path) --huho changed TO os.path() 
	IF l_ret_code THEN 
		ERROR " No permission TO write TO directory" 
		RETURN 
	END IF 
	WHILE true 
		#LET l_runner = " [ -f ",l_move_file clipped," ] 2>>", trim(get_settings_logFile())
		#run l_runner returning l_ret_code
		LET l_ret_code = os.path.exists(l_move_file) --huho changed TO os.path() 
		IF l_ret_code THEN 
			EXIT WHILE 
		ELSE 
			IF modu_verbose_ind THEN 
				ERROR " Cannot move load file - File already exists" 
				LET l_file_name = fgl_winprompt(5,5, "Cannot move load file - File already exists\nEnter target file name", "", 50, 0) 

				IF int_flag OR quit_flag THEN 
					LET int_flag = false 
					LET quit_flag = false 
					RETURN 
				ELSE 
					LET l_move_file = l_move_path clipped, "/", l_file_name clipped 
				END IF 
			ELSE 
				RETURN 
			END IF 
		END IF 
	END WHILE 
	LET l_runner = " mv ", modu_load_file clipped, " ", l_move_file clipped, 
	" 2> /dev/NULL" 
	RUN l_runner 
END FUNCTION 


