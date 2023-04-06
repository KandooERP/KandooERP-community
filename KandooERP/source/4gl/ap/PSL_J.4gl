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
#   PSL_J - JMJ Vendor Load   ** SITE SPECIFIC **
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "../ap/P_AP_GLOBALS.4gl" 

############################################################
# MODULE Scope Variables
############################################################
DEFINE modu_rpt_idx_load SMALLINT 
DEFINE modu_rpt_idx_exception SMALLINT

DEFINE modu_output CHAR(25) 
DEFINE modu_load_file CHAR(100) 
DEFINE modu_file_text CHAR(20) 
DEFINE modu_err_message CHAR(100) 
DEFINE modu_err_text CHAR(250) 
DEFINE modu_rerun_cnt INTEGER 
DEFINE modu_loadfile_cnt INTEGER 
DEFINE modu_jmj_vend_cnt INTEGER 
DEFINE modu_max_vend_cnt INTEGER 
DEFINE modu_upd_cnt INTEGER 
DEFINE modu_err2_cnt INTEGER 
DEFINE modu_err_cnt INTEGER 
DEFINE modu_verbose_ind SMALLINT 

############################################################
# MAIN
#
#
############################################################
MAIN 
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE l_msgresp LIKE language.yes_flag 

	#Initial UI Init
	CALL setModuleId("PSL_J") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_p_ap() #init p/ap module 

	IF get_url_load_file() IS NOT NULL THEN
	--IF num_args() > 0 THEN 
		#
		# run   PSL_J <load-files>
		#
		LET modu_verbose_ind = false 
		LET modu_err_cnt = 0 
		LET modu_err2_cnt = 0 
		CALL start_report() RETURNING l_rpt_idx #idx for exception report
 
		CALL load_routine(l_rpt_idx) 
		CALL move_load_file() 
		CALL finish_report() 
		EXIT PROGRAM( modu_err_cnt + modu_err2_cnt ) 
	ELSE 
		LET modu_verbose_ind = true 

		OPEN WINDOW p215 with FORM "P215" 
		CALL windecoration_p("P215") 
		CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

		MENU " Vendor Load" 

			BEFORE MENU 
				CALL publish_toolbar("kandoo","PSL_J","menu-vendor_load-1") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			ON ACTION "Load" 				#COMMAND "Load" " Commence load process"
				LET modu_err_cnt = 0 
				LET modu_err2_cnt = 0 

				CALL start_report() RETURNING l_rpt_idx #idx for exception report

				IF import_vendor() THEN 
					CALL load_routine(l_rpt_idx) 
					CALL move_load_file() 
					IF ( modu_err_cnt + modu_err2_cnt ) THEN 
						LET l_msgresp = kandoomsg("P",7034,(modu_err_cnt+modu_err2_cnt)) 						#7034 Vendor Load Completed, Errors Encountered
					ELSE 
						IF modu_max_vend_cnt > 0 THEN 
							LET l_msgresp = kandoomsg("P",7035,'') 							#7035 Vendor Load Completed Successfully
						END IF 
					END IF 
				END IF 
				CALL finish_report() 
				NEXT option "Print Manager" 

			ON ACTION "Print Manager" 				#COMMAND KEY ("P",f11) "Print" " Print OR View using RMS"
				CALL run_prog("URS","","","","") 
				NEXT option "Exit" 

			ON ACTION "CANCEL" 				#COMMAND KEY(interrupt,"E")"Exit" " Exit Vendor Load"
				LET quit_flag = true 
				EXIT MENU 

		END MENU 

		CLOSE WINDOW P215 
	END IF 
END MAIN 

FUNCTION start_report()
	DEFINE ret_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	

		#------------------------------------------------------------
		LET modu_rpt_idx_load = rpt_start("PSL_J_LOAD","PSU_J_rpt_list_load","N/A", RPT_SHOW_RMS_DIALOG)
		IF modu_rpt_idx_load = 0 THEN #User pressed CANCEL
			RETURN FALSE
		END IF	
		START REPORT PSU_J_rpt_list_load TO rpt_get_report_file_with_path2(modu_rpt_idx_load)
		WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[modu_rpt_idx_load].page_length_num , 
		TOP MARGIN = glob_arr_rec_rpt_rmsreps[modu_rpt_idx_load].top_margin, 
		BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[modu_rpt_idx_load].bottom_margin, 
		LEFT MARGIN = glob_arr_rec_rpt_rmsreps[modu_rpt_idx_load].left_margin, 
		RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[modu_rpt_idx_load].report_width_num
		#------------------------------------------------------------
	
		#------------------------------------------------------------
		LET ret_rpt_idx = rpt_start("PSL_J_ERROR","PSU_J_rpt_list_exception","N/A", RPT_SHOW_RMS_DIALOG)
		IF ret_rpt_idx = 0 THEN #User pressed CANCEL
			RETURN FALSE
		END IF	
		START REPORT PSU_J_rpt_list_exception TO rpt_get_report_file_with_path2(ret_rpt_idx)
		WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[ret_rpt_idx].page_length_num , 
		TOP MARGIN = glob_arr_rec_rpt_rmsreps[ret_rpt_idx].top_margin, 
		BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[ret_rpt_idx].bottom_margin, 
		LEFT MARGIN = glob_arr_rec_rpt_rmsreps[ret_rpt_idx].left_margin, 
		RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[ret_rpt_idx].report_width_num
		#------------------------------------------------------------

	LET modu_rpt_idx_exception = ret_rpt_idx
	RETURN ret_rpt_idx
END FUNCTION


############################################################
# FUNCTION import_vendor()
#
#
############################################################
FUNCTION import_vendor() 
	DEFINE l_path_text CHAR(60) 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET l_msgresp = kandoomsg("P",1043,"") #1043 Enter Vendor Details - ESC TO Continue

	INPUT modu_file_text, l_path_text WITHOUT DEFAULTS FROM file_text, path_text 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","PSL_J","inp-file-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER FIELD file_text 
			IF modu_file_text IS NULL THEN 
				LET l_msgresp = kandoomsg("A",9166,"") 
				#9166 File name must be entered
				NEXT FIELD file_text 
			END IF 

		AFTER FIELD path_text 
			IF l_path_text IS NULL THEN 
				LET l_msgresp = kandoomsg("A",8015,"") 
				#8015 Warning: Current directory will be defaulted
			END IF 

		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN 
				IF modu_file_text IS NULL THEN 
					LET l_msgresp = kandoomsg("A",9166,"") 				#9166 File name must be entered
					NEXT FIELD file_text 
				END IF 
				IF NOT create_load_file( l_path_text, modu_file_text ) THEN 
					NEXT FIELD file_text 
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
# FUNCTION load_routine(p_rpt_idx)
#
#
############################################################
FUNCTION load_routine(p_rpt_idx) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE l_process_cnt INTEGER
	DEFINE l_insert_ind SMALLINT 
	DEFINE l_r_null_cnt INTEGER 
	DEFINE l_s_null_cnt INTEGER 
	DEFINE l_file_name CHAR(100) 
	DEFINE l_rec_jmjvendor RECORD LIKE jmj_vendor.* 
	DEFINE l_rec_country RECORD LIKE country.* 

	LET modu_rerun_cnt = 0 
	LET modu_loadfile_cnt = 0 
	LET modu_max_vend_cnt = 0 
	#
	# Validate jmj_vendor table has been created through dbupgrade script
	#
	SELECT unique 1 FROM systables 
	WHERE tabname = "jmj_vendor" 
	IF sqlca.sqlcode = NOTFOUND THEN 
		IF modu_verbose_ind THEN 
			MESSAGE "Run SQL script TO create JMJ Vendor table first" 
		END IF 
		LET modu_err2_cnt = modu_err2_cnt + 1 
		LET modu_err_message = "Execute SQL script TO create JMJ Vendor table ", 	"- Load Aborted" 

		#---------------------------------------------------------
		OUTPUT TO REPORT PSL_J_rpt_list_exception(p_rpt_idx,
		'', '', modu_err_message ) 
		#---------------------------------------------------------

		RETURN 
	END IF 
	LET modu_load_file = modu_load_file clipped 
	IF NOT rerun() THEN 
		RETURN 
	END IF 
	LET l_r_null_cnt = 0 
	LET l_insert_ind = true 
	--LET pr_arg_num = num_args() 

	WHILE l_insert_ind 
		IF modu_verbose_ind THEN 
			#
			# Perform 'INSERT' only once FOR interactive mode
			#
			LET l_insert_ind = false 
		ELSE 
			CALL valid_load_file(get_url_load_file(),p_rpt_idx)  #( arg_val(pr_arg_num) ) 
			RETURNING modu_load_file 
			
			#???? what ?????
			--LET pr_arg_num = pr_arg_num - 1 
			--IF NOT pr_arg_num THEN
			IF get_url_load_file() IS NULL THEN
				LET l_insert_ind = false 
			END IF 
		END IF 
		
		IF modu_load_file IS NOT NULL THEN 
			WHENEVER ERROR CONTINUE 
			LOAD FROM modu_load_file INSERT INTO jmj_vendor 
			WHENEVER ERROR stop 
			IF sqlca.sqlcode = 0 THEN 
				#
				# Null Test's on data fields
				#
				SELECT count(*) INTO l_s_null_cnt 
				FROM jmj_vendor 
				WHERE cred_no IS NULL 
				OR cred_process_grp IS NULL 
				OR cred_no = ' ' 
				IF l_s_null_cnt IS NULL THEN 
					LET l_s_null_cnt = 0 
				END IF 
				IF ( l_s_null_cnt - l_r_null_cnt ) > 0 THEN 
					LET l_r_null_cnt = l_s_null_cnt 
					DECLARE c1_jmjvendor CURSOR FOR 
					SELECT * FROM jmj_vendor 
					WHERE cred_no IS NULL 
					OR cred_process_grp IS NULL 
					OR cred_no = ' ' 
					FOREACH c1_jmjvendor INTO l_rec_jmjvendor.* 
						IF l_rec_jmjvendor.cred_process_grp IS NULL THEN 
							LET modu_err_cnt = modu_err_cnt + 1 
							LET modu_err_message = "Null Processing Group detected" 

							#---------------------------------------------------------
							OUTPUT TO REPORT PSL_J_rpt_list_exception(p_rpt_idx,
							l_rec_jmjvendor.cred_process_grp, 
							l_rec_jmjvendor.cred_no, 
							modu_err_message ) 
							#---------------------------------------------------------

							CONTINUE FOREACH 
						END IF 
						IF l_rec_jmjvendor.cred_no IS NULL 
						OR l_rec_jmjvendor.cred_no = ' ' THEN 
							LET modu_err_cnt = modu_err_cnt + 1 
							LET modu_err_message = "Null Creditor No. detected" 

							#---------------------------------------------------------
							OUTPUT TO REPORT PSL_J_rpt_list_exception(p_rpt_idx,
							l_rec_jmjvendor.cred_process_grp, 
							l_rec_jmjvendor.cred_no, 
							modu_err_message ) 
							#---------------------------------------------------------
							
							CONTINUE FOREACH 
						END IF 
					END FOREACH 
				END IF 
			ELSE 
				LET modu_err2_cnt = modu_err2_cnt + 1 
				LET modu_err_message = "PSL - Refer to ", trim(get_settings_logFile()), " FOR SQL Error: ",STATUS, 
				" in Load File: ",modu_load_file clipped 
				LET modu_err_text = "PSL - ",err_get(STATUS) 
				CALL errorlog( modu_err_text ) 

				#---------------------------------------------------------
				OUTPUT TO REPORT PSL_J_rpt_list_exception(p_rpt_idx,
				'', '', modu_err_message ) 
				#---------------------------------------------------------
				

			END IF 
		END IF 
	END WHILE 

	SELECT count(*) INTO l_process_cnt 
	FROM jmj_vendor 
	IF l_process_cnt IS NULL THEN 
		LET l_process_cnt = 0 
	END IF 
	LET modu_loadfile_cnt = l_process_cnt - modu_rerun_cnt 
	#
	# Perform SET up tests on static details of vendor table
	#
	SELECT * INTO l_rec_country.* 
	FROM country 
	WHERE country_code = 'AUS' 
	IF sqlca.sqlcode = NOTFOUND THEN 
		LET modu_err_cnt = modu_err_cnt + 1 
		LET modu_err_message = "Country: AUS NOT SET up - Load Aborted" 

		#---------------------------------------------------------
		OUTPUT TO REPORT PSL_J_rpt_list_exception(p_rpt_idx,
		'', '', modu_err_message )
		#---------------------------------------------------------
 
		RETURN 
	END IF 
	
	IF l_rec_country.country_text != 'Australia' THEN  
		LET modu_err_cnt = modu_err_cnt + 1 
		LET modu_err_message = "Australia NOT SET up FOR Country: AUS - Load Aborted" 

		#---------------------------------------------------------
		OUTPUT TO REPORT PSL_J_rpt_list_exception(p_rpt_idx,
		'', '', modu_err_message )
		#---------------------------------------------------------

		RETURN 
	END IF 

	SELECT * FROM language 
	WHERE language_code = 'ENG' 
	IF sqlca.sqlcode = NOTFOUND THEN 
		LET modu_err_cnt = modu_err_cnt + 1 
		LET modu_err_message = "Language: ENG NOT SET up - Load Aborted" 

		#---------------------------------------------------------
		OUTPUT TO REPORT PSL_J_rpt_list_exception(p_rpt_idx,
		'', '', modu_err_message )
		#---------------------------------------------------------
		
		RETURN 
	END IF 

	SELECT * FROM currency 
	WHERE currency_code = 'AUD' 
	IF sqlca.sqlcode = NOTFOUND THEN 
		LET modu_err_cnt = modu_err_cnt + 1 
		LET modu_err_message = "Currency: AUD NOT SET up - Load Aborted" 

		#---------------------------------------------------------
		OUTPUT TO REPORT PSL_J_rpt_list_exception(p_rpt_idx,
		'', '', modu_err_message )
		#---------------------------------------------------------

		RETURN 
	END IF 
	#
	# Commence vendor load
	#
	CALL vendor_load(p_rpt_idx) 
	
	IF NOT ( modu_err_cnt + modu_err2_cnt ) 
	AND modu_max_vend_cnt > 0 THEN 

		#---------------------------------------------------------
		OUTPUT TO REPORT PSL_J_rpt_list_exception(p_rpt_idx,
		'', '',	'vendor LOAD completed successfully' )
		#---------------------------------------------------------
		 
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

	LET l_len_num = length( p_path_text ) 
	INITIALIZE l_slash_text TO NULL 
	IF l_len_num > 0 THEN 
		IF p_path_text[l_len_num,l_len_num] != "\/" THEN 
			LET l_slash_text = "\/" 
		END IF 
	END IF 
	LET modu_load_file = p_path_text clipped,	l_slash_text clipped,	p_file_text clipped 

	LET modu_load_file = modu_load_file clipped 
	
	LET modu_load_file = valid_load_file( modu_load_file,modu_rpt_idx_exception )
	 
	IF modu_load_file IS NULL THEN 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 



############################################################
# FUNCTION valid_load_file(p_file_name,p_rpt_idx )
#
#
#        1. File NOT found
#        2. No read permission
#        3. File IS Empty
#        4. OTHERWISE
#
############################################################
FUNCTION valid_load_file(p_file_name,p_rpt_idx) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE p_file_name CHAR(100) 
	DEFINE l_ret_code INTEGER 
	DEFINE l_msgresp LIKE language.yes_flag 

	#huho changed TO os.path() methods
	#LET runner = " [ -f ",p_file_name clipped," ] 2>>", trim(get_settings_logFile())
	#run runner returning l_ret_code

	IF get_debug() THEN 
		DISPLAY "os.path.exists(p_file_name) returns->", os.Path.exists(p_file_name) 
		DISPLAY "os.path.exists(data/read/folderNOOOOOO) returns->", os.Path.exists("data/read/folderNOOOO") 
		DISPLAY "os.path.exists(data/read/folder1) returns->", os.Path.exists("data/read/folder1") 
		DISPLAY "os.path.exists(data/read/folder1/read_folder1.txt) returns->", os.Path.exists("data/read/folder1/read_folder1.txt") 
	END IF 

	LET l_ret_code = os.path.exists(p_file_name) 
	IF NOT l_ret_code THEN 
		IF modu_verbose_ind THEN 
			LET l_msgresp = kandoomsg("A",9160,'') 
			#9160 Load file does NOT exist - check path AND filename
		END IF 
		LET modu_err2_cnt = modu_err2_cnt + 1 
		LET modu_err_message = "Load file: ", p_file_name clipped, " does NOT exist" 
		
		#---------------------------------------------------------
		OUTPUT TO REPORT PSL_J_rpt_list_exception(p_rpt_idx,
		'', '', modu_err_message ) 
		#---------------------------------------------------------
		
		RETURN "" 
	END IF 

	LET l_ret_code = os.path.readable(p_file_name) 
	#LET runner = " [ -r ",p_file_name clipped," ] 2>>", trim(get_settings_logFile())
	#run runner returning l_ret_code
	IF NOT l_ret_code THEN 
		IF modu_verbose_ind THEN 
			LET l_msgresp = kandoomsg("A",9162,'') 
			#9162 Unable TO read load file
		END IF 
		LET modu_err2_cnt = modu_err2_cnt + 1 
		LET modu_err_message = "Unable TO read load file: ",p_file_name clipped

		#---------------------------------------------------------
		OUTPUT TO REPORT PSL_J_rpt_list_exception(p_rpt_idx,
		'', '', modu_err_message ) 
		#---------------------------------------------------------
 
		RETURN "" 
	END IF 

	LET l_ret_code = os.path.size(p_file_name) 
	#LET runner = " [ -s ",p_file_name clipped," ] 2>>",, trim(get_settings_logFile())
	#run runner returning l_ret_code
	IF l_ret_code = 0 THEN 
		IF modu_verbose_ind THEN 
			LET l_msgresp = kandoomsg("A",9161,'') 
			#9161 Load file IS empty
		END IF 
		LET modu_err2_cnt = modu_err2_cnt + 1 
		LET modu_err_message = "Load file: ",p_file_name clipped," IS empty" 

		#---------------------------------------------------------
		OUTPUT TO REPORT PSL_J_rpt_list_exception(p_rpt_idx,
		'', '', modu_err_message ) 
		#---------------------------------------------------------

		RETURN "" 
	ELSE 
		RETURN p_file_name 
	END IF 
END FUNCTION 



############################################################
# FUNCTION vendor_load(p_rpt_idx)
#
#
############################################################
FUNCTION vendor_load(p_rpt_idx) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	

	SELECT count(*) INTO modu_jmj_vend_cnt 
	FROM jmj_vendor 
	WHERE cred_no IS NOT NULL 
	AND cred_process_grp IS NOT NULL 
	AND cred_no != ' ' 
	IF modu_jmj_vend_cnt IS NULL THEN 
		LET modu_jmj_vend_cnt = 0 
	END IF 
	IF modu_jmj_vend_cnt = 0 THEN 
		LET modu_err_message = "No vendors TO be generated" 

		#---------------------------------------------------------
		OUTPUT TO REPORT PSL_J_rpt_list_exception(modu_rpt_idx_load,
		'', '', modu_err_message ) 
		#---------------------------------------------------------
 
	ELSE 
		CALL create_vendor_entry(p_rpt_idx) 
	END IF 
END FUNCTION 



############################################################
# FUNCTION create_vendor_entry(p_rpt_idx)
#
#
############################################################
FUNCTION create_vendor_entry(p_rpt_idx)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	 
	DEFINE l_rec_jmjvendor RECORD LIKE jmj_vendor.* 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_vend_cnt INTEGER 
	DEFINE l_vend_per DECIMAL(6,3) 
	DEFINE l_db_flag CHAR(1) 
	DEFINE l_bank_code LIKE bank.bank_code 

	LET l_vend_cnt = 0 
	LET l_vend_per = 0 
	IF modu_verbose_ind THEN 
		DISPLAY modu_max_vend_cnt,modu_upd_cnt,l_vend_per TO max_vend_cnt,upd_cnt,vend_per  

	END IF 
	#
	#
	# Create Vendor
	#
	#
	DECLARE c_jmjvendor CURSOR with HOLD FOR 
	SELECT * FROM jmj_vendor 
	WHERE cred_no IS NOT NULL 
	AND cred_process_grp IS NOT NULL 
	AND cred_no != ' ' 
	ORDER BY cred_process_grp, 
	cred_no 
	FOREACH c_jmjvendor INTO l_rec_jmjvendor.* 
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
		LET l_vend_cnt = l_vend_cnt + 1 
		LET l_vend_per = ( l_vend_cnt / modu_jmj_vend_cnt ) * 100 
		IF modu_verbose_ind THEN 
			DISPLAY l_vend_per TO vend_per 

			DISPLAY l_rec_jmjvendor.cred_no, 
			l_rec_jmjvendor.cred_name 
			TO vendor.vend_code, 
			vendor.name_text 

		END IF 
		#
		#
		IF retry_lock(glob_rec_kandoouser.cmpy_code,0) THEN END IF 
			GOTO bypass 
			LABEL recovery: 
			IF retry_lock(glob_rec_kandoouser.cmpy_code,status) > 0 THEN 
				ROLLBACK WORK 
			ELSE 
				IF modu_verbose_ind THEN 
					IF error_recover(modu_err_message,status) != 'Y' THEN 
						LET modu_err2_cnt = modu_err2_cnt + 1 

						#---------------------------------------------------------
						OUTPUT TO REPORT PSL_J_rpt_list_exception(p_rpt_idx,
						l_rec_jmjvendor.cred_process_grp, 
						l_rec_jmjvendor.cred_no, 
						modu_err_message )
						#---------------------------------------------------------

						CONTINUE FOREACH 
					END IF 
				ELSE 
					LET modu_err2_cnt = modu_err2_cnt + 1 

					#---------------------------------------------------------
					OUTPUT TO REPORT PSL_J_rpt_list_exception(p_rpt_idx,
					l_rec_jmjvendor.cred_process_grp, 
					l_rec_jmjvendor.cred_no, 
					modu_err_message ) 
					#---------------------------------------------------------
					
					LET modu_err_text = "PSL - ",err_get(STATUS) 
					CALL errorlog( modu_err_text ) 
					ROLLBACK WORK 
					CONTINUE FOREACH 
				END IF 
			END IF 
			LABEL bypass: 
			WHENEVER ERROR GOTO recovery 
			BEGIN WORK 
				INITIALIZE l_rec_vendor.* TO NULL 
				IF ( l_rec_jmjvendor.cred_process_grp >= 20 
				AND l_rec_jmjvendor.cred_process_grp <= 29 ) THEN 
					LET l_rec_vendor.cmpy_code = '5' 
				ELSE 
					LET l_rec_vendor.cmpy_code = '9' 
				END IF 
				LET l_rec_vendor.vend_code = l_rec_jmjvendor.cred_no clipped, '-', 
				l_rec_jmjvendor.cred_process_grp USING "<<" 
				LET l_rec_vendor.name_text = l_rec_jmjvendor.cred_name 
				LET l_rec_vendor.addr1_text = l_rec_jmjvendor.cred_add1 
				LET l_rec_vendor.city_text = l_rec_jmjvendor.cred_add2 
				LET l_rec_vendor.state_code = l_rec_jmjvendor.cred_statex 
				LET l_rec_vendor.post_code = l_rec_jmjvendor.cred_post 
				LET l_rec_vendor.tele_text = l_rec_jmjvendor.cred_phone 
				LET l_rec_vendor.fax_text = l_rec_jmjvendor.cred_fax 
				LET l_db_flag = 'U' 
				LET modu_err_message = "PSL - Error updating Vendor: ", 
				l_rec_vendor.vend_code clipped, " ", 
				"at Cmpy:", l_rec_vendor.cmpy_code clipped 
				UPDATE vendor 
				SET ( name_text , 
				addr1_text , 
				city_text , 
				state_code , 
				post_code , 
				tele_text , 
				fax_text ) 
				= 
				( l_rec_vendor.name_text , 
				l_rec_vendor.addr1_text , 
				l_rec_vendor.city_text , 
				l_rec_vendor.state_code , 
				l_rec_vendor.post_code , 
				l_rec_vendor.tele_text , 
				l_rec_vendor.fax_text ) 
				WHERE cmpy_code = l_rec_vendor.cmpy_code 
				AND vend_code = l_rec_vendor.vend_code 
				IF sqlca.sqlerrd[3] = 0 THEN 
					#
					# Validate 'target' company SET up
					#
					SELECT unique 1 FROM company 
					WHERE cmpy_code = l_rec_vendor.cmpy_code 
					IF sqlca.sqlcode = NOTFOUND THEN 
						LET modu_err_cnt = modu_err_cnt + 1 
						LET modu_err_message = "Company: ",l_rec_vendor.cmpy_code," NOT SET up" 

						#---------------------------------------------------------
						OUTPUT TO REPORT PSL_J_rpt_list_exception(p_rpt_idx,
						l_rec_jmjvendor.cred_process_grp, 
						l_rec_jmjvendor.cred_no, 
						modu_err_message ) 
						#---------------------------------------------------------					
					
						ROLLBACK WORK 
						CONTINUE FOREACH 
					END IF 
					#
					# Validate term code D40
					#
					SELECT * FROM term 
					WHERE term_code = 'd40' 
					AND cmpy_code = l_rec_vendor.cmpy_code 
					IF sqlca.sqlcode = NOTFOUND THEN 
						LET modu_err_cnt = modu_err_cnt + 1 
						LET modu_err_message = "Term code: D40 NOT SET up ", 
						"at Cmpy: ",l_rec_vendor.cmpy_code 

						#---------------------------------------------------------
						OUTPUT TO REPORT PSL_J_rpt_list_exception(p_rpt_idx,
						l_rec_jmjvendor.cred_process_grp, 
						l_rec_jmjvendor.cred_no, 
						modu_err_message ) 
						#---------------------------------------------------------					

						ROLLBACK WORK 
						CONTINUE FOREACH 
					END IF 
					#
					# Validate tax code EX
					#
					SELECT * FROM tax 
					WHERE tax_code = 'EX' 
					AND cmpy_code = l_rec_vendor.cmpy_code 
					IF sqlca.sqlcode = NOTFOUND THEN 
						LET modu_err_cnt = modu_err_cnt + 1 
						LET modu_err_message = "Tax code: EX NOT SET up ",						"at Cmpy: ", l_rec_vendor.cmpy_code 

						#---------------------------------------------------------
						OUTPUT TO REPORT PSL_J_rpt_list_exception(p_rpt_idx,
						l_rec_jmjvendor.cred_process_grp, 
						l_rec_jmjvendor.cred_no, 
						modu_err_message ) 
						#---------------------------------------------------------		
						
						ROLLBACK WORK 
						CONTINUE FOREACH 
					END IF 
					#
					# Validate hold code NO
					#
					SELECT 1 FROM holdpay 
					WHERE hold_code = 'NO' 
					AND cmpy_code = l_rec_vendor.cmpy_code 
					IF sqlca.sqlcode = NOTFOUND THEN 
						LET modu_err_cnt = modu_err_cnt + 1 
						LET modu_err_message = "Hold code: NO NOT SET up ",			"at Cmpy: ", l_rec_vendor.cmpy_code 

						#---------------------------------------------------------
						OUTPUT TO REPORT PSL_J_rpt_list_exception(p_rpt_idx,
						l_rec_jmjvendor.cred_process_grp, 
						l_rec_jmjvendor.cred_no, 
						modu_err_message ) 
						#---------------------------------------------------------	

						ROLLBACK WORK 
						CONTINUE FOREACH 
					END IF 
					#
					# Validate bank code ANZ & NABJ
					#
					IF l_rec_vendor.cmpy_code = "9" THEN 
						LET l_bank_code = 'NABJ' 
					ELSE 
						LET l_bank_code = 'ANZ' 
					END IF 
					SELECT * FROM bank 
					WHERE bank_code = l_bank_code 
					AND currency_code = 'AUD' 
					AND cmpy_code = l_rec_vendor.cmpy_code 
					IF sqlca.sqlcode = NOTFOUND THEN 
						LET modu_err_cnt = modu_err_cnt + 1 
						LET modu_err_message = "Bank: ", l_bank_code, 
						" NOT SET up FOR Currency: AUD ", 
						" AT Cmpy: ", l_rec_vendor.cmpy_code 
						
						#---------------------------------------------------------
						OUTPUT TO REPORT PSL_J_rpt_list_exception(p_rpt_idx,
						l_rec_jmjvendor.cred_process_grp, 
						l_rec_jmjvendor.cred_no, 
						modu_err_message ) 
						#---------------------------------------------------------	
						
						ROLLBACK WORK 
						CONTINUE FOREACH 
					END IF 
					LET l_rec_vendor.addr2_text = NULL 
					--LET l_rec_vendor.country_text = "Australia" --@db-patch_2020_10_04--
					LET l_rec_vendor.country_code = "AUS" 
					LET l_rec_vendor.language_code = "ENG" 
					CASE 
						WHEN l_rec_jmjvendor.cred_process_grp >= 10 
							AND l_rec_jmjvendor.cred_process_grp <= 19 
							LET l_rec_vendor.type_code = "J10" 
						WHEN l_rec_jmjvendor.cred_process_grp >= 20 
							AND l_rec_jmjvendor.cred_process_grp <= 29 
							LET l_rec_vendor.type_code = "A20" 
						WHEN l_rec_jmjvendor.cred_process_grp >= 30 
							AND l_rec_jmjvendor.cred_process_grp <= 39 
							LET l_rec_vendor.type_code = "F30" 
						WHEN l_rec_jmjvendor.cred_process_grp >= 60 
							AND l_rec_jmjvendor.cred_process_grp <= 69 
							LET l_rec_vendor.type_code = "B60" 
						WHEN l_rec_jmjvendor.cred_process_grp >= 70 
							AND l_rec_jmjvendor.cred_process_grp <= 79 
							LET l_rec_vendor.type_code = "V70" 
						WHEN l_rec_jmjvendor.cred_process_grp >= 80 
							AND l_rec_jmjvendor.cred_process_grp <= 89 
							LET l_rec_vendor.type_code = "N80" 
						WHEN l_rec_jmjvendor.cred_process_grp = 90 
							LET l_rec_vendor.type_code = "J90" 
						WHEN l_rec_jmjvendor.cred_process_grp = 91 
							LET l_rec_vendor.type_code = "J91" 
						WHEN l_rec_jmjvendor.cred_process_grp = 92 
							LET l_rec_vendor.type_code = "J92" 
						WHEN l_rec_jmjvendor.cred_process_grp = 95 
							LET l_rec_vendor.type_code = "W95" 
						OTHERWISE 
							LET modu_err_cnt = modu_err_cnt + 1 
							LET modu_err_message = 
							"Vendor type: ",l_rec_jmjvendor.cred_process_grp, 
							" NOT SET up ", 
							"at Cmpy: ", l_rec_vendor.cmpy_code 

							#---------------------------------------------------------
							OUTPUT TO REPORT PSL_J_rpt_list_exception(p_rpt_idx,
							l_rec_jmjvendor.cred_process_grp, 
							l_rec_jmjvendor.cred_no, 
							modu_err_message )	
							#---------------------------------------------------------
								
							ROLLBACK WORK 
							CONTINUE FOREACH 
					END CASE 
					SELECT * FROM vendortype 
					WHERE type_code = l_rec_vendor.type_code 
					AND cmpy_code = l_rec_vendor.cmpy_code 
					IF sqlca.sqlcode = NOTFOUND THEN 
						LET modu_err_cnt = modu_err_cnt + 1 
						LET modu_err_message = "Vendor type: ",l_rec_vendor.type_code, 
						" NOT SET up", 
						" AT Cmpy: ", l_rec_vendor.cmpy_code 

						#---------------------------------------------------------
						OUTPUT TO REPORT PSL_J_rpt_list_exception(p_rpt_idx,
						l_rec_jmjvendor.cred_process_grp, 
						l_rec_jmjvendor.cred_no, 
						modu_err_message ) 
						#---------------------------------------------------------

						ROLLBACK WORK 
						CONTINUE FOREACH 
					END IF 
					LET l_rec_vendor.term_code = "D40" 
					LET l_rec_vendor.tax_code = "EX" 
					LET l_rec_vendor.setup_date = l_rec_jmjvendor.cred_rate_date 
					IF l_rec_vendor.setup_date IS NULL THEN 
						LET l_rec_vendor.setup_date = today 
					END IF 
					LET l_rec_vendor.last_mail_date = NULL 
					LET l_rec_vendor.tax_text = NULL 
					LET l_rec_vendor.our_acct_code = NULL 
					LET l_rec_vendor.contact_text = NULL 
					LET l_rec_vendor.extension_text = NULL 
					LET l_rec_vendor.acct_text = NULL 
					LET l_rec_vendor.limit_amt = 0 
					LET l_rec_vendor.bal_amt = 0 
					IF l_rec_jmjvendor.cred_ly IS NULL THEN 
						LET l_rec_jmjvendor.cred_ly = 0 
					END IF 
					IF l_rec_jmjvendor.cred_ytd IS NULL THEN 
						LET l_rec_jmjvendor.cred_ytd = 0 
					END IF 
					IF l_rec_jmjvendor.cred_ytd < l_rec_jmjvendor.cred_ly THEN 
						LET l_rec_vendor.highest_bal_amt = l_rec_jmjvendor.cred_ly 
					ELSE 
						LET l_rec_vendor.highest_bal_amt = l_rec_jmjvendor.cred_ytd 
					END IF 
					LET l_rec_vendor.curr_amt = 0 
					LET l_rec_vendor.over1_amt = 0 
					LET l_rec_vendor.over30_amt = 0 
					LET l_rec_vendor.over60_amt = 0 
					LET l_rec_vendor.over90_amt = 0 
					LET l_rec_vendor.onorder_amt = 0 
					LET l_rec_vendor.avg_day_paid_num = 0 
					LET l_rec_vendor.last_debit_date = NULL 
					LET l_rec_vendor.last_po_date = NULL 
					LET l_rec_vendor.last_vouc_date = NULL 
					LET l_rec_vendor.last_payment_date = NULL 
					LET l_rec_vendor.next_seq_num = 0 
					LET l_rec_vendor.hold_code = 'NO' 
					LET l_rec_vendor.usual_acct_code = NULL 
					LET l_rec_vendor.ytd_amt = l_rec_jmjvendor.cred_ytd 
					LET l_rec_vendor.min_ord_amt = 0 
					LET l_rec_vendor.drop_flag = 'N' 
					LET l_rec_vendor.finance_per = 'N' 
					LET l_rec_vendor.currency_code = 'AUD' 
					LET l_rec_vendor.bank_acct_code = NULL 
					LET l_rec_vendor.bank_code = l_bank_code 
					LET l_rec_vendor.pay_meth_ind = '1' # auto / manual cheques 
					#initialise extra vendor fields
					LET l_rec_vendor.bkdetls_mod_flag = "N" 
					LET l_rec_vendor.po_var_per = 0 
					LET l_rec_vendor.po_var_amt = 0 
					LET l_rec_vendor.def_exp_ind = "G" 
					#
					# Adding new vendor
					#
					LET l_db_flag = 'I' 
					LET modu_err_message = "PSL - Error inserting Vendor: ", 
					l_rec_vendor.vend_code clipped, " ", 
					"at Cmpy:", l_rec_vendor.cmpy_code clipped 
					INSERT INTO vendor VALUES ( l_rec_vendor.* ) 
				END IF 
				
			COMMIT WORK 
			WHENEVER ERROR stop 
			SELECT * INTO l_rec_vendor.* 
			FROM vendor 
			WHERE cmpy_code = l_rec_vendor.cmpy_code 
			AND vend_code = l_rec_vendor.vend_code 

			#---------------------------------------------------------
			OUTPUT TO REPORT PSL_J_rpt_list_load(modu_rpt_idx_load,
			l_rec_vendor.*, l_db_flag )
			#---------------------------------------------------------
			 
			#
			# Delete JMJ vendor FROM holding table
			#
			DELETE FROM jmj_vendor 
			WHERE cred_no = l_rec_jmjvendor.cred_no 
			AND cred_process_grp = l_rec_jmjvendor.cred_process_grp 
			IF l_db_flag = 'I' THEN 
				LET modu_max_vend_cnt = modu_max_vend_cnt + 1 
				IF modu_verbose_ind THEN 
					DISPLAY modu_max_vend_cnt TO max_vend_cnt 

				END IF 
			ELSE 
				LET modu_upd_cnt = modu_upd_cnt + 1 
				IF modu_verbose_ind THEN 
					DISPLAY modu_upd_cnt TO upd_cnt 

				END IF 
			END IF 
		END FOREACH 
END FUNCTION 



############################################################
# REPORT PSL_J_rpt_list_load(p_rpt_idx, p_rec_vendor, p_db_flag )
#
#
############################################################
REPORT PSL_J_rpt_list_load(p_rpt_idx,p_rec_vendor,p_db_flag) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE p_rec_vendor RECORD LIKE vendor.* 
	DEFINE p_db_flag CHAR(1) 
--	DEFINE l_arr_line ARRAY[4] OF CHAR(132)

	OUTPUT 

	ORDER external BY p_rec_vendor.cmpy_code,	p_rec_vendor.vend_code 

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
			PRINT COLUMN 1, p_rec_vendor.cmpy_code, 
			COLUMN 11, p_rec_vendor.vend_code, 
			COLUMN 22, p_rec_vendor.name_text, 
			COLUMN 55, p_rec_vendor.type_code, 
			COLUMN 62, p_rec_vendor.highest_bal_amt USING "###########&.&&", 
			COLUMN 80, p_rec_vendor.ytd_amt USING "##########&.&&", 
			COLUMN 97, p_rec_vendor.fax_text, 
			COLUMN 126, p_db_flag 

		ON LAST ROW 
			NEED 15 LINES 
			SKIP 3 LINES 
			PRINT COLUMN 10, "Total records TO be processed FROM Re-run : ", 			modu_rerun_cnt 
			PRINT COLUMN 10, "Total records TO be processed FROM Load File: ", 			modu_loadfile_cnt 
			PRINT COLUMN 55, "-------------" 
			PRINT COLUMN 55, ( modu_rerun_cnt + modu_loadfile_cnt ) USING "###########&" 
			SKIP 1 line 
			PRINT COLUMN 10, "Total records with validation errors : ",modu_err_cnt, 			" ( SQL / File FORMAT errors: ",modu_err2_cnt," )" 
			PRINT COLUMN 10, "Total records successfully processed :", 
			COLUMN 55, ( modu_max_vend_cnt + modu_upd_cnt ) USING "###########&" 
			PRINT COLUMN 55, "-------------" 
			PRINT COLUMN 55, (modu_err_cnt + modu_max_vend_cnt + modu_upd_cnt) 
			USING "###########&" 
			SKIP 2 LINES 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			
END REPORT 


############################################################
# REPORT PSL_J_rpt_list_exception( p_process_grp, p_client_code, p_status )
#
#
############################################################
REPORT PSL_J_rpt_list_exception(p_rpt_idx,p_process_grp,p_client_code,p_status)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	 
	DEFINE p_process_grp LIKE jmj_vendor.cred_process_grp 
	DEFINE p_client_code LIKE jmj_vendor.cred_no 
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
			PRINT COLUMN 01, p_process_grp, 
			COLUMN 19, p_client_code, 
			COLUMN 44, p_status[1,132-44] 

		ON LAST ROW 
			NEED 15 LINES 
			SKIP 3 LINES 
			PRINT COLUMN 10, "Total records TO be processed FROM Re-run : ", 	modu_rerun_cnt 
			PRINT COLUMN 10, "Total records TO be processed FROM Load File: ", modu_loadfile_cnt 
			PRINT COLUMN 55, "-------------" 
			PRINT COLUMN 55, ( modu_rerun_cnt + modu_loadfile_cnt ) USING "###########&" 
			SKIP 1 line 
			PRINT COLUMN 10, "Total records with validation errors : ",modu_err_cnt, " ( SQL / File FORMAT errors: ",modu_err2_cnt," )" 
			PRINT COLUMN 10, "Total records successfully processed :", 
			COLUMN 55, ( modu_max_vend_cnt + modu_upd_cnt ) USING "###########&" 
			PRINT COLUMN 55, "-------------" 
			PRINT COLUMN 55, (modu_err_cnt + modu_max_vend_cnt + modu_upd_cnt) 
			USING "###########&" 
			SKIP 2 LINES 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			
END REPORT 



############################################################
# FUNCTION finish_report()
#
#
############################################################
FUNCTION finish_report() 

	#------------------------------------------------------------
	FINISH REPORT PSL_J_rpt_list_load
	CALL rpt_finish("PSL_J_rpt_list_load")
	#------------------------------------------------------------

	#------------------------------------------------------------
	FINISH REPORT PSL_J_rpt_list_exception
	CALL rpt_finish("PSL_J_rpt_list_exception")
	#------------------------------------------------------------
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
	FROM jmj_vendor 
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

	IF NOT os.path.exists(l_move_path) THEN 
		ERROR "Directory process does NOT exist" 
		RETURN 1 
		#	ELSE
		#		RETURN 0
	END IF 

	# LET l_runner = " [ -d ",l_move_path clipped," ] 2>>", trim(get_settings_logFile())
	# run l_runner returning l_ret_code
	#IF l_ret_code THEN
	#   IF modu_verbose_ind THEN
	#      ERROR " Directory process does NOT exist"
	#   END IF
	#   RETURN
	#END IF

	IF NOT os.path.writable(l_move_path) THEN 
		ERROR "No permission TO write TO directory" 
		RETURN 1 
		#	ELSE
		#		RETURN 0
	END IF 


	#   LET l_runner = " [ -w ",l_move_path clipped," ] 2>>", trim(get_settings_logFile())
	#   run l_runner returning l_ret_code
	#   IF l_ret_code THEN
	#      ERROR " No permission TO write TO directory"
	#      RETURN
	#   END IF

	WHILE true 
		IF os.path.exists(l_move_path) THEN 
			ERROR "No permission TO write TO directory\nthis needs changing HUHO" 
			EXIT WHILE 
		ELSE 


			#LET l_runner = " [ -f ",l_move_file clipped," ] 2>>", trim(get_settings_logFile())
			#run l_runner returning l_ret_code
			#IF l_ret_code THEN
			#   EXIT WHILE
			#ELSE
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

	IF os.path.copy(trim(modu_load_file), trim(l_move_file)) THEN 
		CALL os.path.delete(modu_load_file) 
	END IF 

	#LET l_runner = " mv ", modu_load_file clipped, " ", l_move_file clipped,
	#             " 2> /dev/NULL"
	#run l_runner
END FUNCTION 