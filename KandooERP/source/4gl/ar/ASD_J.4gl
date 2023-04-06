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
GLOBALS "../ar/A_AR_GLOBALS.4gl"
GLOBALS "../ar/AS_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/ASD_J_GLOBALS.4gl"
############################################################
# Module Scope Variables
############################################################
DEFINE modu_s_output CHAR(25) 
DEFINE modu_load_file CHAR(100) 
DEFINE modu_err_message CHAR(100) 
DEFINE modu_err_text CHAR(250) 
DEFINE modu_process_cnt INTEGER 
DEFINE modu_jmj_cust_cnt INTEGER 
DEFINE modu_kandoo_cust_cnt INTEGER 
DEFINE modu_err2_cnt INTEGER # -> meta-errors (eg. db updates,etc.) 
DEFINE modu_err_cnt INTEGER # -> RECORD level errors 
DEFINE modu_verbose_ind SMALLINT 
DEFINE modu_rerun_cnt INTEGER 
DEFINE modu_loadfile_cnt INTEGER 
#########################################################################
# FUNCTION ASD_J_main()
#
# ASD_J - Debtor Load
# ASD_J_valid_load_file(get_url_load_file()) returning modu_load_file
#
# Not completed.. program can be called with multiple file names as argumnents... need to add tokenizer or remove this feture
#########################################################################
FUNCTION ASD_J_main()
	DEFER QUIT 
	DEFER INTERRUPT 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 

	CALL setModuleId("ASD_J") 

	IF get_url_load_file() IS NOT NULL THEN #Load file argument 
		#
		# fglgo ASD_J <load-files>
		#
		LET modu_verbose_ind = false 
		LET modu_err_cnt = 0 
		LET modu_err2_cnt = 0 
		CALL ASD_J_start_report() 
		CALL ASD_J_load_routine() 
		CALL ASD_J_finish_report() 
		EXIT PROGRAM( modu_err_cnt + modu_err2_cnt ) 
	ELSE 
		LET modu_verbose_ind = true 

		OPEN WINDOW A636 with FORM "A636" 
		CALL windecoration_a("A636") 

		MENU " Debtor Load" 
			BEFORE MENU 
				CALL publish_toolbar("kandoo","ASD_J","menu-debtor-load") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
				
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			COMMAND "Load" " Commence load process" 
				LET modu_err_cnt = 0 
				LET modu_err2_cnt = 0 

				CALL ASD_J_start_report() 

				IF import_debtor() THEN 
					CALL ASD_J_load_routine() 
					IF ( modu_err_cnt + modu_err2_cnt ) THEN 
						CALL fgl_winmessage("Load Error",kandoomsg2("A",7058,(modu_err_cnt+modu_err2_cnt)),"ERROR")	#7058 Debtor Load Completed, Errors Encountered
					ELSE 
						IF modu_kandoo_cust_cnt > 0 THEN 
							CALL fgl_winmessage("Load successfull",kandoomsg2("A",7059,''),"INFO") #7059 Debtor Load Completed Successfully
						END IF 
					END IF 
				END IF 

				CALL ASD_J_finish_report()
				CALL rpt_rmsreps_reset(NULL) 

			ON ACTION "Print Manager"		#COMMAND KEY ("P",f11) "Print" " Print OR View using RMS"
				CALL run_prog("URS","","","","") 

			ON ACTION "CANCEL" #COMMAND KEY(interrupt,"E")"Exit" " Exit Debtor Load" 
				LET quit_flag = true 
				EXIT MENU 


		END MENU 
		CLOSE WINDOW A636 
	END IF 
	
END FUNCTION


#########################################################################
# FUNCTION import_debtor() 
#
#
#########################################################################
FUNCTION import_debtor() 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_file_text CHAR(20) 
	DEFINE l_path_text CHAR(60) 

	LET l_msgresp = kandoomsg("A",1057,"") 
	#1057 Enter Debtor Details - ESC TO Continue
	INPUT l_file_text, l_path_text WITHOUT DEFAULTS FROM l_file_text, l_path_text 


		BEFORE INPUT 
			CALL publish_toolbar("kandoo","ASD","inp-file-path") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER FIELD file_text 
			IF l_file_text IS NULL THEN 
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
				IF l_file_text IS NULL THEN 
					LET l_msgresp = kandoomsg("A",9166,"") 
					#9166 File name must be entered
					NEXT FIELD file_text 
				END IF 
				IF NOT ASD_J_create_load_file( l_path_text, l_file_text ) THEN 
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


#########################################################################
# FUNCTION ASD_J_load_routine()
#
#
#########################################################################
FUNCTION ASD_J_load_routine() 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_insert_ind SMALLINT 
	DEFINE l_null_cnt SMALLINT 
	DEFINE l_s_null_cnt SMALLINT 
	--DEFINE l_arg_num INTEGER
	--DEFINE l_file_name CHAR(100) 
	DEFINE l_rec_jmjcustomer RECORD LIKE jmj_customer.* 
	DEFINE l_rec_country RECORD LIKE country.* 

	LET modu_rerun_cnt = 0 
	LET modu_loadfile_cnt = 0 
	LET modu_kandoo_cust_cnt = 0 
	#
	# Validate jmj_customer table has been created through dbupgrade script
	#
	SELECT unique 1 FROM systables 
	WHERE tabname = "jmj_customer" 
	IF sqlca.sqlcode = NOTFOUND THEN 
		IF modu_verbose_ind THEN 
			LET l_msgresp = kandoomsg("A",9168,'') 
			#9168 Run SQL script TO create JMJ Debtor table first
		END IF 
		LET modu_err2_cnt = modu_err2_cnt + 1 
		LET modu_err_message = "Execute SQL script TO create JMJ Debtor table - ", "Load Aborted" 
		#---------------------------------------------------------
		OUTPUT TO REPORT ASD_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASD_J_rpt_list_exception"),'', '', modu_err_message )  
		#--------------------------------------------------------- 
		
		RETURN 
	END IF 
	LET modu_load_file = modu_load_file clipped 
	IF NOT ASD_J_rerun() THEN 
		RETURN 
	END IF 
	LET l_null_cnt = 0 
	LET l_insert_ind = true 
	WHILE l_insert_ind 
		IF modu_verbose_ind THEN 
			#
			# Perform 'INSERT' only once FOR interactive mode
			#
			LET l_insert_ind = false 
		ELSE 
			CALL ASD_J_valid_load_file(get_url_load_file()) RETURNING modu_load_file 
			IF NOT get_url_load_file() THEN 
				LET l_insert_ind = false 
			END IF 
		END IF 
		IF modu_load_file IS NOT NULL THEN 
			WHENEVER ERROR CONTINUE 
			LOAD FROM modu_load_file INSERT INTO jmj_customer 
			WHENEVER ERROR stop 
			WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
			IF sqlca.sqlcode = 0 THEN 
				#
				# Null Test's on data fields
				#
				SELECT count(*) INTO l_s_null_cnt 
				FROM jmj_customer 
				WHERE custno_01 IS NULL 
				OR ledgerx_01 IS NULL 
				OR process_group_01 IS NULL 
				OR custno_01 = ' ' 
				OR ledgerx_01 = ' ' 
				IF l_s_null_cnt IS NULL THEN 
					LET l_s_null_cnt = 0 
				END IF 
				IF ( l_s_null_cnt - l_null_cnt ) > 0 THEN 
					LET l_null_cnt = l_s_null_cnt 
					DECLARE c1_jmjcustomer CURSOR FOR 
					SELECT * FROM jmj_customer 
					WHERE process_group_01 IS NULL 
					OR custno_01 IS NULL 
					OR ledgerx_01 IS NULL 
					OR ledgerx_01 = ' ' 
					OR custno_01 = ' ' 
					FOREACH c1_jmjcustomer INTO l_rec_jmjcustomer.* 
						IF l_rec_jmjcustomer.process_group_01 IS NULL THEN 
							LET modu_err_cnt = modu_err_cnt + 1 
							LET modu_err_message = "Null Processing Group detected" 
							#---------------------------------------------------------
							OUTPUT TO REPORT ASD_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASD_J_rpt_list_exception"),
								l_rec_jmjcustomer.process_group_01, 
								l_rec_jmjcustomer.custno_01, 
								modu_err_message )  
							#--------------------------------------------------------- 
							CONTINUE FOREACH 
						END IF 
						IF l_rec_jmjcustomer.custno_01 IS NULL 
						OR l_rec_jmjcustomer.custno_01 = ' ' THEN 
							LET modu_err_cnt = modu_err_cnt + 1 
							LET modu_err_message = "Null Client Code detected" 
							#---------------------------------------------------------
							OUTPUT TO REPORT ASD_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASD_J_rpt_list_exception"),
								l_rec_jmjcustomer.process_group_01, 
								l_rec_jmjcustomer.custno_01, 
								modu_err_message )  
							#--------------------------------------------------------- 
							CONTINUE FOREACH 
						END IF 
						IF l_rec_jmjcustomer.ledgerx_01 IS NULL 
						OR l_rec_jmjcustomer.ledgerx_01 = ' ' THEN 
							LET modu_err_cnt = modu_err_cnt + 1 
							LET modu_err_message = "Null Ledger Code detected" 
							#---------------------------------------------------------
							OUTPUT TO REPORT ASD_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASD_J_rpt_list_exception"),
								l_rec_jmjcustomer.process_group_01, 
								l_rec_jmjcustomer.custno_01, 
								modu_err_message )  
							#---------------------------------------------------------
							CONTINUE FOREACH 
						END IF 
					END FOREACH 
				END IF 
			ELSE 
				LET modu_err2_cnt = modu_err2_cnt + 1 
				LET modu_err_message = "ASD_J - Refer ", trim(get_settings_logFile()), " FOR SQL Error: ",STATUS, 
				" in Load File: ",modu_load_file clipped 
				LET modu_err_text = "ASD_J - ",err_get(STATUS) 
				CALL errorlog( modu_err_text ) 
				#---------------------------------------------------------	
				OUTPUT TO REPORT ASD_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASD_J_rpt_list_exception"), '', '', modu_err_message ) 
				OUTPUT TO REPORT ASD_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASD_J_rpt_list_exception"), '', '', modu_err_text ) 
				#---------------------------------------------------------	
			END IF 
		END IF 
	END WHILE 
	SELECT count(*) INTO modu_process_cnt 
	FROM jmj_customer 
	IF modu_process_cnt IS NULL THEN 
		LET modu_process_cnt = 0 
	END IF 
	LET modu_loadfile_cnt = modu_process_cnt - modu_rerun_cnt 
	#
	# Perform SET up tests on static details of customer table
	#
	--SELECT * INTO glob_rec_country.* 
	--FROM country 
	--WHERE country_code = 'AUS' 
	--IF sqlca.sqlcode = NOTFOUND THEN 
	--	LET modu_err_cnt = modu_err_cnt + 1 
	--	LET modu_err_message = "Country: AUS NOT SET up - Load Aborted" 
	--	OUTPUT TO REPORT ASD_J_rpt_list_exception( '', '', modu_err_message ) 
	--	RETURN 
	--END IF 
	--IF glob_rec_country.country_text != 'Australia' THEN 
	--	LET modu_err_cnt = modu_err_cnt + 1 
	--	LET modu_err_message = "Australia NOT SET up FOR Country: AUS - Load Aborted " 
	--	OUTPUT TO REPORT ASD_J_rpt_list_exception( '', '', modu_err_message ) 
	--	RETURN 
	--END IF 
	SELECT * FROM language 
	WHERE language_code = 'ENG' 
	IF sqlca.sqlcode = NOTFOUND THEN 
		LET modu_err_cnt = modu_err_cnt + 1 
		LET modu_err_message = "Language: ENG NOT SET up - Load Aborted" 
		
		OUTPUT TO REPORT ASD_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASD_J_rpt_list_exception"), '', '', modu_err_message ) 
		RETURN 
	END IF 
	SELECT * FROM currency 
	WHERE currency_code = 'AUD' 
	IF sqlca.sqlcode = NOTFOUND THEN 
		LET modu_err_cnt = modu_err_cnt + 1 
		LET modu_err_message = "Currency: AUD NOT SET up - Load Aborted" 
		OUTPUT TO REPORT ASD_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASD_J_rpt_list_exception"), '', '', modu_err_message ) 
		RETURN 
	END IF 
	#
	# Initiate debtor load process
	#
	CALL debtor_load() 
	IF NOT ( modu_err_cnt + modu_err2_cnt ) 
	AND modu_kandoo_cust_cnt > 0 THEN 
		#---------------------------------------------------------
		OUTPUT TO REPORT ASD_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASD_J_rpt_list_exception"),
		'',
		'', 
		'debtor LOAD completed successfully' )  
		#---------------------------------------------------------		
	END IF 
END FUNCTION 


#########################################################################
# FUNCTION ASD_J_create_load_file( p_path_text, p_file_text )
#
#
#########################################################################
FUNCTION ASD_J_create_load_file( p_path_text, p_file_text ) 
	DEFINE p_path_text CHAR(60) 
	DEFINE p_file_text CHAR(20) 
	DEFINE l_slash_text CHAR 
	DEFINE l_len_num INTEGER 
	DEFINE l_msgresp LIKE language.yes_flag 

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
	LET modu_load_file = ASD_J_valid_load_file( modu_load_file ) 
	
	IF modu_load_file IS NULL THEN 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 



#########################################################################
# FUNCTION ASD_J_valid_load_file( p_file_name ) 
#
#
#########################################################################
FUNCTION ASD_J_valid_load_file(p_file_name) 
	DEFINE l_msgresp LIKE language.yes_flag 
	#
	#        1. File NOT found
	#        2. No read permission
	#        3. File IS Empty
	#        4. OTHERWISE
	#
	DEFINE runner CHAR(100) 
	DEFINE p_file_name STRING --char(100) 
	DEFINE ret_code INTEGER 

	LET ret_code = os.path.exists(p_file_name) --huho changed TO os.path() 
	#LET runner = " [ -f ",p_file_name clipped," ] 2>>", trim(get_settings_logFile())
	#run runner returning ret_code
	IF ret_code THEN 
		IF modu_verbose_ind THEN 
			LET l_msgresp = kandoomsg("A",9160,'') 
			#9160 Load file does NOT exist - check path AND filename
		END IF 
		LET modu_err2_cnt = modu_err2_cnt + 1 
		LET modu_err_message = "Load file: ", p_file_name clipped, " does NOT exist" 
		#---------------------------------------------------------
		OUTPUT TO REPORT ASD_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASD_J_rpt_list_exception"), '', '', modu_err_message ) 
		#---------------------------------------------------------			
		RETURN "" 
	END IF 

	LET ret_code = os.path.readable(p_file_name) --huho changed TO os.path() 
	#LET runner = " [ -r ",p_file_name clipped," ] 2>>", trim(get_settings_logFile())
	#run runner returning ret_code
	IF ret_code THEN 
		IF modu_verbose_ind THEN 
			LET l_msgresp = kandoomsg("A",9162,'') 
			#9162 Unable TO read load file
		END IF 
		LET modu_err2_cnt = modu_err2_cnt + 1 
		LET modu_err_message = "Unable TO read load file: ",p_file_name clipped 
		#---------------------------------------------------------
		OUTPUT TO REPORT ASD_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASD_J_rpt_list_exception"), '', '', modu_err_message ) 
		#---------------------------------------------------------	
		RETURN "" 
	END IF 

	LET ret_code = os.path.size(p_file_name) --huho changed TO os.path() 
	#LET runner = " [ -s ",p_file_name clipped," ] 2>>",trim(get_settings_logFile())
	#run runner returning ret_code
	IF ret_code THEN 
		IF modu_verbose_ind THEN 
			LET l_msgresp = kandoomsg("A",9161,'') 
			#9161 Load file IS empty
		END IF 
		LET modu_err2_cnt = modu_err2_cnt + 1 
		LET modu_err_message = "Load file: ",p_file_name clipped," IS empty" 
		#---------------------------------------------------------
		OUTPUT TO REPORT ASD_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASD_J_rpt_list_exception"), '', '', modu_err_message ) 
		#---------------------------------------------------------	
		RETURN "" 
	ELSE 
		RETURN p_file_name 
	END IF 
END FUNCTION 




#########################################################################
# FUNCTION debtor_load()
#
#
#########################################################################
FUNCTION debtor_load() 

	SELECT count(*) INTO modu_jmj_cust_cnt 
	FROM jmj_customer 
	WHERE process_group_01 IS NOT NULL 
	AND custno_01 IS NOT NULL 
	AND ledgerx_01 IS NOT NULL 
	AND ledgerx_01 != ' ' 
	AND custno_01 != ' ' 
	IF modu_jmj_cust_cnt IS NULL THEN 
		LET modu_jmj_cust_cnt = 0 
	END IF 
	IF modu_jmj_cust_cnt = 0 THEN 
		LET modu_err_message = "No customers TO be generated" 
		#---------------------------------------------------------
		OUTPUT TO REPORT ASD_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASD_J_rpt_list_exception"), '', '', modu_err_message ) 
		#---------------------------------------------------------	
	ELSE 
		CALL create_debtor_entry() 
	END IF 
END FUNCTION 


#########################################################################
# FUNCTION debtor_load()
#
#
#########################################################################
FUNCTION create_debtor_entry() 
	DEFINE l_rec_customer    RECORD LIKE customer.*
	DEFINE l_rec_jmjcustomer RECORD LIKE jmj_customer.* 
	DEFINE l_query_text CHAR(100) 
	DEFINE l_cust_cnt INTEGER 
	DEFINE l_cust_per DECIMAL(6,3) 

	LET l_cust_cnt = 0 
	LET l_cust_per = 0 
	IF modu_verbose_ind THEN 
		DISPLAY modu_kandoo_cust_cnt TO kandoo_cust_cnt 
		DISPLAY l_cust_per TO cust_per 

	END IF 
	#
	#
	# Create Customer
	#
	#
	DECLARE c_jmjcustomer CURSOR with HOLD FOR 
	SELECT * FROM jmj_customer 
	WHERE process_group_01 IS NOT NULL 
	AND custno_01 IS NOT NULL 
	AND ledgerx_01 IS NOT NULL 
	AND ledgerx_01 != ' ' 
	AND custno_01 != ' ' 
	ORDER BY custno_01 
	FOREACH c_jmjcustomer INTO l_rec_jmjcustomer.* 
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
		LET l_cust_cnt = l_cust_cnt + 1 
		LET l_cust_per = ( l_cust_cnt / modu_jmj_cust_cnt ) * 100 
		IF modu_verbose_ind THEN 
		
			DISPLAY l_cust_per TO cust_per 

			DISPLAY l_rec_jmjcustomer.custno_01 TO customer.cust_code
			DISPLAY l_rec_jmjcustomer.name_01 TO customer.name_text 

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
						#strange... there is no LET for modu_err_message
						#---------------------------------------------------------
						OUTPUT TO REPORT ASD_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASD_J_rpt_list_exception"),
						l_rec_jmjcustomer.process_group_01, 
						l_rec_jmjcustomer.custno_01, 
						modu_err_message ) 
						#---------------------------------------------------------							
						CONTINUE FOREACH 
					END IF 
				ELSE 
					LET modu_err2_cnt = modu_err2_cnt + 1 
					LET modu_err_text = "ASD_J - ",err_get(STATUS) 
						#---------------------------------------------------------
						OUTPUT TO REPORT ASD_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASD_J_rpt_list_exception"),
						l_rec_jmjcustomer.process_group_01, 
						l_rec_jmjcustomer.custno_01, 
						modu_err_message ) 
						#---------------------------------------------------------	 

					CALL errorlog( modu_err_text ) 
					ROLLBACK WORK 
					CONTINUE FOREACH 
				END IF 
			END IF 
			LABEL bypass: 
			WHENEVER ERROR GOTO recovery 
			BEGIN WORK 
				INITIALIZE l_rec_customer.* TO NULL 
				IF l_rec_jmjcustomer.process_group_01 >= 20 
				AND l_rec_jmjcustomer.process_group_01 <= 29 THEN 
					LET l_rec_customer.cmpy_code = '5' 
				ELSE 
					LET l_rec_customer.cmpy_code = '9' 
				END IF 
				#
				# Validate 'target' company SET up
				#
				SELECT unique 1 FROM company 
				WHERE cmpy_code = l_rec_customer.cmpy_code 
				IF sqlca.sqlcode = NOTFOUND THEN 
					LET modu_err_cnt = modu_err_cnt + 1 
					LET modu_err_message = "Company: ",l_rec_customer.cmpy_code," NOT SET up" 
					#---------------------------------------------------------
					OUTPUT TO REPORT ASD_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASD_J_rpt_list_exception"),
						l_rec_jmjcustomer.process_group_01, 
						l_rec_jmjcustomer.custno_01, 
						modu_err_message ) 
					#---------------------------------------------------------	 					
					ROLLBACK WORK 
					CONTINUE FOREACH 
				END IF 
				LET l_rec_customer.cust_code = l_rec_jmjcustomer.custno_01 
				IF length( l_rec_customer.cust_code) < 5 THEN 
					LET modu_err_cnt = modu_err_cnt + 1 
					LET modu_err_message = "Invalid Customer Code FORMAT detected ", 
					"at glob_rec_kandoouser.cmpy_code: ", l_rec_customer.cmpy_code 
					#---------------------------------------------------------
					OUTPUT TO REPORT ASD_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASD_J_rpt_list_exception"),
						l_rec_jmjcustomer.process_group_01, 
						l_rec_jmjcustomer.custno_01, 
						modu_err_message ) 
					#---------------------------------------------------------						
					 
					ROLLBACK WORK 
					CONTINUE FOREACH 
				ELSE 
					SELECT 1 FROM customer 
					WHERE cust_code = l_rec_customer.cust_code 
					AND cmpy_code = l_rec_customer.cmpy_code 
					IF sqlca.sqlcode = 0 THEN 
						LET modu_err_cnt = modu_err_cnt + 1 
						LET modu_err_message = "Customer already SET up ", 
						"at glob_rec_kandoouser.cmpy_code: ", l_rec_customer.cmpy_code 
						
						#---------------------------------------------------------
						OUTPUT TO REPORT ASD_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASD_J_rpt_list_exception"),
							l_rec_jmjcustomer.process_group_01, 
							l_rec_jmjcustomer.custno_01, 
							modu_err_message ) 
						#---------------------------------------------------------	
						
						ROLLBACK WORK 
						CONTINUE FOREACH 
					END IF 
				END IF 
				#
				# Validate term code D-7
				#
				SELECT * FROM term 
				WHERE term_code = 'd-7' 
				AND cmpy_code = l_rec_customer.cmpy_code 
				IF sqlca.sqlcode = NOTFOUND THEN 
					LET modu_err_cnt = modu_err_cnt + 1 
					LET modu_err_message = "Term code: D-7 NOT SET up ", 
					"at glob_rec_kandoouser.cmpy_code: ",l_rec_customer.cmpy_code 
					
					#---------------------------------------------------------
					OUTPUT TO REPORT ASD_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASD_J_rpt_list_exception"),
						l_rec_jmjcustomer.process_group_01, 
						l_rec_jmjcustomer.custno_01, 
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
				AND cmpy_code = l_rec_customer.cmpy_code 
				IF sqlca.sqlcode = NOTFOUND THEN 
					LET modu_err_cnt = modu_err_cnt + 1 
					LET modu_err_message = "Tax code: EX NOT SET up ", 
					"at glob_rec_kandoouser.cmpy_code: ", l_rec_customer.cmpy_code 
					
					#---------------------------------------------------------
					OUTPUT TO REPORT ASD_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASD_J_rpt_list_exception"),
						l_rec_jmjcustomer.process_group_01, 
						l_rec_jmjcustomer.custno_01, 
						modu_err_message ) 
					#---------------------------------------------------------						 
					ROLLBACK WORK 
					CONTINUE FOREACH 
				END IF 
				#
				# Validate sale code 'JMJ'
				#
				SELECT * FROM salesperson 
				WHERE sale_code = 'JMJ' 
				AND cmpy_code = l_rec_customer.cmpy_code 
				IF sqlca.sqlcode = NOTFOUND THEN 
					LET modu_err_cnt = modu_err_cnt + 1 
					LET modu_err_message = "Salesperson: JMJ NOT SET up ", 
					"at glob_rec_kandoouser.cmpy_code: ", l_rec_customer.cmpy_code 
					
					#---------------------------------------------------------
					OUTPUT TO REPORT ASD_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASD_J_rpt_list_exception"),
						l_rec_jmjcustomer.process_group_01, 
						l_rec_jmjcustomer.custno_01, 
						modu_err_message ) 
					#---------------------------------------------------------	
					 
					ROLLBACK WORK 
					CONTINUE FOREACH 
				END IF 
				#
				# Validate dunning code 'STD'
				#
				SELECT * FROM stateinfo 
				WHERE dun_code = 'STD' 
				AND cmpy_code = l_rec_customer.cmpy_code 
				IF sqlca.sqlcode = NOTFOUND THEN 
					LET modu_err_cnt = modu_err_cnt + 1 
					LET modu_err_message = "Dunning code: STD NOT SET up ", 
					"at glob_rec_kandoouser.cmpy_code: ", l_rec_customer.cmpy_code 
					
					#---------------------------------------------------------
					OUTPUT TO REPORT ASD_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASD_J_rpt_list_exception"),
						l_rec_jmjcustomer.process_group_01, 
						l_rec_jmjcustomer.custno_01, 
						modu_err_message ) 
					#---------------------------------------------------------	
					 
					ROLLBACK WORK 
					CONTINUE FOREACH 
				END IF 
				#
				# Validate territory code '01'
				#
				SELECT * FROM territory 
				WHERE terr_code = '01' 
				AND cmpy_code = l_rec_customer.cmpy_code 
				IF sqlca.sqlcode = NOTFOUND THEN 
					LET modu_err_cnt = modu_err_cnt + 1 
					LET modu_err_message = "Territory: 01 NOT SET up ", 
					"at glob_rec_kandoouser.cmpy_code: ", l_rec_customer.cmpy_code 
					
					#---------------------------------------------------------
					OUTPUT TO REPORT ASD_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASD_J_rpt_list_exception"),
						l_rec_jmjcustomer.process_group_01, 
						l_rec_jmjcustomer.custno_01, 
						modu_err_message ) 
					#---------------------------------------------------------	
					 
					ROLLBACK WORK 
					CONTINUE FOREACH 
				END IF 
				LET l_rec_customer.corp_cust_code = NULL 
				LET l_rec_customer.name_text = l_rec_jmjcustomer.name_01 
				LET l_rec_customer.addr1_text = l_rec_jmjcustomer.addr1_01 
				LET l_rec_customer.addr2_text = l_rec_jmjcustomer.addr2_01 
				LET l_rec_customer.city_text = l_rec_jmjcustomer.addr3_01 
				LET l_rec_customer.state_code = l_rec_jmjcustomer.statex_01 
				LET l_rec_customer.post_code = l_rec_jmjcustomer.pcode_01 
--@db-patch_2020_10_04--				LET l_rec_customer.country_text = "Australia" 
				LET l_rec_customer.country_code = "AUS" 
				LET l_rec_customer.language_code = "ENG" 
				CASE l_rec_jmjcustomer.ledgerx_01 
					WHEN "C01" 
						LET l_rec_customer.type_code = "COM" 
					WHEN "C02" 
						LET l_rec_customer.type_code = "FMS" 
					WHEN "C03" 
						LET l_rec_customer.type_code = "BWC" 
					WHEN "G01" 
						LET l_rec_customer.type_code = "VGV" 
					WHEN "G02" 
						LET l_rec_customer.type_code = "NGV" 
					OTHERWISE 
						LET modu_err_cnt = modu_err_cnt + 1 
						LET modu_err_message = 
						"Customer type: ",l_rec_jmjcustomer.ledgerx_01," NOT SET up ", 
						"at glob_rec_kandoouser.cmpy_code: ", l_rec_customer.cmpy_code 
						
					#---------------------------------------------------------
					OUTPUT TO REPORT ASD_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASD_J_rpt_list_exception"),
						l_rec_jmjcustomer.process_group_01, 
						l_rec_jmjcustomer.custno_01, 
						modu_err_message ) 
					#---------------------------------------------------------	
						 
						ROLLBACK WORK 
						CONTINUE FOREACH 
				END CASE 
				SELECT * FROM customertype 
				WHERE type_code = l_rec_customer.type_code 
				AND cmpy_code = l_rec_customer.cmpy_code 
				IF sqlca.sqlcode = NOTFOUND THEN 
					LET modu_err_cnt = modu_err_cnt + 1 
					LET modu_err_message = 
					"Customer type: ",l_rec_customer.type_code," NOT SET up ", 
					"at glob_rec_kandoouser.cmpy_code: ", l_rec_customer.cmpy_code 
					
					#---------------------------------------------------------
					OUTPUT TO REPORT ASD_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASD_J_rpt_list_exception"),
						l_rec_jmjcustomer.process_group_01, 
						l_rec_jmjcustomer.custno_01, 
						modu_err_message ) 
					#---------------------------------------------------------	
					 
					ROLLBACK WORK 
					CONTINUE FOREACH 
				END IF 
				LET l_rec_customer.sale_code = "JMJ" 
				LET l_rec_customer.term_code = "D-7" 
				LET l_rec_customer.tax_code = "EX" 
				LET l_rec_customer.inv_addr_flag = "O" 
				LET l_rec_customer.sales_anly_flag = "O" 
				LET l_rec_customer.credit_chk_flag = "O" 
				LET l_rec_customer.setup_date = today 
				LET l_rec_customer.last_mail_date = NULL 
				LET l_rec_customer.tax_num_text = NULL 
				LET l_rec_customer.contact_text = l_rec_jmjcustomer.comments_01 
				LET l_rec_customer.tele_text = l_rec_jmjcustomer.telephone_01 
				--LET l_rec_customer.mobile_phone = l_rec_jmjcustomer.mobile_phone
				--LET l_rec_customer.email = l_rec_jmjcustomer.email							
				LET l_rec_customer.cred_limit_amt = 0 
				LET l_rec_customer.cred_bal_amt = 0 
				LET l_rec_customer.bal_amt = 0 
				LET l_rec_customer.highest_bal_amt = 0 
				LET l_rec_customer.curr_amt = 0 
				LET l_rec_customer.over1_amt = 0 
				LET l_rec_customer.over30_amt = 0 
				LET l_rec_customer.over60_amt = 0 
				LET l_rec_customer.over90_amt = 0 
				LET l_rec_customer.onorder_amt = 0 
				LET l_rec_customer.inv_level_ind = "L" 
				LET l_rec_customer.dun_code = "STD" 
				LET l_rec_customer.avg_cred_day_num = 0 
				LET l_rec_customer.last_inv_date = l_rec_jmjcustomer.last_sold_01 
				LET l_rec_customer.last_pay_date = l_rec_jmjcustomer.last_chq_01 
				LET l_rec_customer.next_seq_num = 0 
				LET l_rec_customer.partial_ship_flag = "N" 
				LET l_rec_customer.back_order_flag = "N" 
				LET l_rec_customer.currency_code = "AUD" 
				LET l_rec_customer.int_chge_flag = "N" 
				LET l_rec_customer.stmnt_ind = "N" 
				LET l_rec_customer.ytds_amt = l_rec_jmjcustomer.sales_ytd_01 
				IF l_rec_customer.ytds_amt IS NULL THEN 
					LET l_rec_customer.ytds_amt = 0 
				END IF 
				LET l_rec_customer.mtds_amt = l_rec_jmjcustomer.sales_mtd_01 
				IF l_rec_customer.mtds_amt IS NULL THEN 
					LET l_rec_customer.mtds_amt = 0 
				END IF 
				LET l_rec_customer.ytdp_amt = 0 
				LET l_rec_customer.mtdp_amt = 0 
				LET l_rec_customer.late_pay_num = 0 
				LET l_rec_customer.cred_given_num = 0 
				LET l_rec_customer.cred_taken_num = 0 
				LET l_rec_customer.fax_text = NULL 
				LET l_rec_customer.interest_per = 0 
				LET l_rec_customer.territory_code = "01" 
				LET l_rec_customer.billing_ind = NULL 
				LET l_rec_customer.bank_acct_code = NULL 
				LET l_rec_customer.delete_flag = "N" 
				LET l_rec_customer.delete_date = NULL 
				LET l_rec_customer.show_disc_flag = "N" 
				LET l_rec_customer.consolidate_flag = "N" 
				LET l_rec_customer.cond_code = NULL 
				LET l_rec_customer.pay_ind = "1" 
				LET l_rec_customer.hold_code = NULL 
				LET l_rec_customer.share_flag = "N" 
				LET l_rec_customer.scheme_amt = NULL 
				LET l_rec_customer.invoice_to_ind = "1" 
				LET l_rec_customer.ref1_code = l_rec_jmjcustomer.rep_01 
				LET l_rec_customer.ref2_code = NULL 
				LET l_rec_customer.ref3_code = NULL 
				LET l_rec_customer.ref4_code = NULL 
				LET l_rec_customer.ref5_code = NULL 
				LET l_rec_customer.ref6_code = NULL 
				LET l_rec_customer.ref7_code = NULL 
				LET l_rec_customer.ref8_code = NULL 
				LET modu_err_message = "ASD_J - Error inserting Customer: ", 
				l_rec_customer.cust_code clipped, " ", 
				"at glob_rec_kandoouser.cmpy_code:", l_rec_customer.cmpy_code clipped 
				INSERT INTO customer VALUES ( l_rec_customer.* ) 
				#
				# Delete JMJ customer FROM holding table
				#
				DELETE FROM jmj_customer 
				WHERE custno_01 = l_rec_jmjcustomer.custno_01 
				AND process_group_01 = l_rec_jmjcustomer.process_group_01 
			COMMIT WORK 
			WHENEVER ERROR stop
			WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
				
				#---------------------------------------------------------
				# OUTPUT FOR the ONLY real/positive report 
				#---------------------------------------------------------
				OUTPUT TO REPORT ASD_J_rpt_list(rpt_rmsreps_idx_get_idx("ASD_J_rpt_list"),l_rec_customer.* )
				#--------------------------------------------------------- 			
 
			LET modu_kandoo_cust_cnt = modu_kandoo_cust_cnt + 1 
			IF modu_verbose_ind THEN 
				DISPLAY modu_kandoo_cust_cnt TO kandoo_cust_cnt 

			END IF 
		END FOREACH 
END FUNCTION 


{
#########################################################################
# FUNCTION set1_defaults() 
#
#
#########################################################################
FUNCTION set1_defaults() 

 
	LET glob_rec_kandooreport.menupath_text = "ASD" 
	LET glob_rec_kandooreport.selection_flag = "N" 
	LET glob_rec_kandooreport.line1_text = "glob_rec_kandoouser.cmpy_code Code", 2 spaces, 
	"Customer", 33 spaces, 
	"Type", 4 spaces, 
	"YTD Sales", 3 spaces, 
	"MTD Sales", 2 spaces, 
	"Creditor Controller ID" 
	UPDATE kandooreport 
	SET * = glob_rec_kandooreport.* 
	WHERE report_code = glob_rec_kandooreport.report_code 
	AND language_code = glob_rec_kandooreport.language_code 
END FUNCTION 


FUNCTION set2_defaults() 
	LET glob_rec_s_kandooreport.header_text = "Debtor Exception Report - ", today USING "dd/mm/yy" 
	LET glob_rec_s_kandooreport.width_num = 132 
	LET glob_rec_s_kandooreport.length_num = 66 
	LET glob_rec_s_kandooreport.menupath_text = "ASD" 
	LET glob_rec_s_kandooreport.selection_flag = "N" 
	LET glob_rec_s_kandooreport.line1_text = "Processing Group", 2 spaces, 
	"Client Code", 14 spaces, 
	"Status" 
	UPDATE kandooreport 
	SET * = glob_rec_s_kandooreport.* 
	WHERE report_code = glob_rec_s_kandooreport.report_code 
	AND language_code = glob_rec_s_kandooreport.language_code 
END FUNCTION 


}

#########################################################################
# FUNCTION ASD_J_start_report()
#
# Set up Exception / Debtor Load file
#########################################################################
FUNCTION ASD_J_start_report() 
	DEFINE l_rpt_idx SMALLINT

	#------------------------------------------------------------
	# Report for exceptions
	LET l_rpt_idx = rpt_start("ASD_J-ERROR","ASD_J_rpt_list_exception","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT ASD_J_rpt_list_exception TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ASD_J_rpt_list_exception")].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0

	#Report for success
	LET l_rpt_idx = rpt_start("ASD_J","ASD_J_rpt_list","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT ASD_J_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ASD_J_rpt_list")].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0
	#LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ASD_J_rpt_list")].sel_text
	#------------------------------------------------------------

--	START REPORT ASD_J_rpt_list TO glob_rec_rmsreps.file_text 
--	START REPORT ASD_J_rpt_list_exception TO modu_s_output 
END FUNCTION 


#########################################################################
# FUNCTION ASD_J_finish_report()
#
#
#########################################################################
FUNCTION ASD_J_finish_report() 

	#------------------------------------------------------------
	# Actual (positive) report
	FINISH REPORT ASD_J_rpt_list
	CALL rpt_finish("ASD_J_rpt_list")
	#------------------------------------------------------------

	#------------------------------------------------------------
	# ERROR/Exception Report
	FINISH REPORT ASD_J_rpt_list_exception
	CALL rpt_finish("ASD_J_rpt_list_exception")
	#------------------------------------------------------------
	  	 
END FUNCTION 


#########################################################################
# FUNCTION ASD_J_rerun()
#
# This function may be dropped
#########################################################################
FUNCTION ASD_J_rerun() 
	DEFINE l_rerun_ind SMALLINT 

	LET l_rerun_ind = true 
	SELECT count(*) INTO modu_rerun_cnt 
	FROM jmj_customer 
	IF modu_rerun_cnt IS NULL THEN 
		LET modu_rerun_cnt = 0 
	END IF 
	IF modu_verbose_ind THEN 
		IF modu_rerun_cnt > 0 THEN 
			#7060 Warning: X entries detected in holding table. Continue (Y/N)?
			IF kandoomsg("A",7060,modu_rerun_cnt) = 'N' THEN 
				LET l_rerun_ind = false 
			END IF 
		END IF 
	END IF 
	RETURN l_rerun_ind 
END FUNCTION 


#########################################################################
# REPORT ASD_J_rpt_list( p_rec_customer )
#
#
#########################################################################
REPORT ASD_J_rpt_list(p_rpt_idx,p_rec_customer) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE p_rec_customer RECORD LIKE customer.* 

	OUTPUT 
--	left margin 0 
	ORDER external BY p_rec_customer.cmpy_code, 
	p_rec_customer.cust_code 
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
			PRINT COLUMN 01, p_rec_customer.cmpy_code, 
			COLUMN 12, p_rec_customer.cust_code, 
			COLUMN 21, p_rec_customer.name_text, 
			COLUMN 53, p_rec_customer.type_code, 
			COLUMN 60, p_rec_customer.ytds_amt USING "######&.&&", 
			COLUMN 71, p_rec_customer.mtds_amt USING "######&.&&", 
			COLUMN 89, p_rec_customer.ref1_code 
		ON LAST ROW 
			NEED 15 LINES 
			SKIP 3 LINES 
			PRINT COLUMN 10, "Total records TO be processed FROM Re-run : ", 
			modu_rerun_cnt 
			PRINT COLUMN 10, "Total records TO be processed FROM Load File: ", 
			modu_loadfile_cnt 
			PRINT COLUMN 55, "-------------" 
			PRINT COLUMN 59, ( modu_rerun_cnt + modu_loadfile_cnt ) USING "-------&" 
			SKIP 1 line 
			PRINT COLUMN 10, "Total records with validation errors : ",modu_err_cnt, 
			" ( SQL / File errors: ",modu_err2_cnt," )" 
			PRINT COLUMN 10, "Total records successfully processed : ", 
			modu_kandoo_cust_cnt 
			PRINT COLUMN 55, "-------------" 
			PRINT COLUMN 59, ( modu_err_cnt + modu_kandoo_cust_cnt ) USING "-------&" 
			SKIP 2 LINES 
			
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			
			
END REPORT 



#########################################################################
# REPORT ASD_J_rpt_list_exception( p_process_grp, p_client_code, p_status )
#
#
#########################################################################
REPORT ASD_J_rpt_list_exception(p_rpt_idx,p_process_grp, p_client_code, p_status) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE p_process_grp LIKE jmj_customer.process_group_01 
	DEFINE p_client_code LIKE jmj_customer.custno_01 
	DEFINE p_status CHAR(132) 
	DEFINE l_arr_line array[4] OF CHAR(132) 

	OUTPUT 
	left margin 0 
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
			PRINT COLUMN 10, "Total records TO be processed FROM Re-run : ", 
			modu_rerun_cnt 
			PRINT COLUMN 10, "Total records TO be processed FROM Load File: ", 
			modu_loadfile_cnt 
			PRINT COLUMN 55, "-------------" 
			PRINT COLUMN 59, ( modu_rerun_cnt + modu_loadfile_cnt ) USING "-------&" 
			SKIP 1 line 
			PRINT COLUMN 10, "Total records with validation errors : ",modu_err_cnt, 
			" ( SQL / File errors: ",modu_err2_cnt," )" 
			PRINT COLUMN 10, "Total records successfully processed : ", modu_kandoo_cust_cnt 
			PRINT COLUMN 55, "-------------" 
			PRINT COLUMN 59, ( modu_err_cnt + modu_kandoo_cust_cnt ) USING "-------&" 
			SKIP 2 LINES 
			
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			
END REPORT 
