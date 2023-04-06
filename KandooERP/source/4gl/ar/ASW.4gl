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
GLOBALS "../ar/ASW_GLOBALS.4gl"  
GLOBALS 
	DEFINE glob_rec_s_kandooreport RECORD LIKE kandooreport.* 
END GLOBALS 
############################################################
# Module Scope Variables
############################################################
DEFINE modu_s_output CHAR(50) 
DEFINE modu_load_file CHAR(100) 
DEFINE modu_err_message CHAR(110) 
--DEFINE l_query_text CHAR(400) 
DEFINE modu_err_text CHAR(250) 
DEFINE modu_kandoo_ar_cnt INTEGER 
DEFINE modu_kandoo_in_cnt INTEGER 
DEFINE modu_kandoo_rc_cnt INTEGER 
DEFINE modu_load_cnt INTEGER 
DEFINE modu_loadfile_cnt INTEGER 
DEFINE modu_rerun_cnt INTEGER 
DEFINE modu_err2_cnt INTEGER 
DEFINE modu_err_cnt INTEGER 
DEFINE modu_loadfile_ind SMALLINT 
DEFINE modu_unload_ind SMALLINT 
DEFINE modu_verbose_ind SMALLINT 
--DEFINE modu_rec_kandoouser RECORD LIKE kandoouser.* 
DEFINE modu_total_invoice_amt LIKE invoicehead.total_amt 
DEFINE modu_total_rec_amt LIKE invoicehead.total_amt 
DEFINE modu_load_ar_cnt INTEGER 
DEFINE modu_load_rc_cnt INTEGER 
DEFINE modu_load_in_cnt INTEGER 
DEFINE modu_tot_ar_cnt INTEGER 
DEFINE modu_process_cnt INTEGER 
DEFINE modu_ap_per DECIMAL(6,3) 
DEFINE modu_path_text LIKE loadparms.file_text 
DEFINE modu_load_ind LIKE loadparms.load_ind 


##########################################################################
# FUNCTION ASW_main()
#
# ASW - External AR Invoice/Receipt Load
##########################################################################
FUNCTION ASW_main() 
	DEFER QUIT 
	DEFER INTERRUPT 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

	CALL setModuleId("ASW") 

	CALL create_table("invoicedetl","t_invoicedetl","","N") 
	#huho 18.09.2019 change default to UI AND use argument from URL
	#IF num_args() > 0  THEN
	IF get_url_int1() > 0 THEN 
		### fglgo ASW <glob_rec_kandoouser.cmpy_code> <load-file> ###
		LET modu_verbose_ind = false 
		LET modu_loadfile_ind = true 
		IF ASW_start_load(false) THEN 
			CALL move_load_file() 
		END IF 
		EXIT PROGRAM( modu_err_cnt + modu_err2_cnt ) 
	ELSE 
		LET modu_verbose_ind = true 

		OPEN WINDOW A675 with FORM "A675" 
		CALL windecoration_a("A675") 

		MENU " AR Load" 

			BEFORE MENU 
				CALL publish_toolbar("kandoo","ASW","menu-ar-load") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			COMMAND "Load" " Commence Invoice/Receipt load process" 
				LET modu_unload_ind = false 
				LET modu_loadfile_ind = true 
				IF ASW_start_load(false) THEN 
					CALL move_load_file() 
				END IF 
				CALL rpt_rmsreps_reset(NULL)

			COMMAND "Rerun" " Commence Invoice/Receipt load FROM interim table" 
				LET modu_unload_ind = false 
				LET modu_loadfile_ind = false 
				CALL ASW_start_load(true)  
				CALL rpt_rmsreps_reset(NULL) 

			COMMAND "Unload" " Unload contents of interim table" 
				LET modu_unload_ind = true 
				LET modu_loadfile_ind = true 
				IF ASW_unload(1) THEN END IF 

			ON ACTION "Print Manager" 
				#COMMAND KEY ("P",f11) "Print" " Print OR View using RMS"
				CALL run_prog("URS","","","","") 
				NEXT option "Exit" 

			COMMAND KEY(interrupt,"E")"Exit" " Exit AR Load" 
				LET int_flag = true 
				LET quit_flag = true 
				EXIT MENU 

		END MENU 
		CLOSE WINDOW A675 
	END IF 
END FUNCTION 
##########################################################################
# END FUNCTION ASW_main()
##########################################################################


##########################################################################
# FUNCTION import_invcash(p_mode)
#
# Import the Invoice/Receipt File
##########################################################################
FUNCTION import_invcash(p_mode) 
	DEFINE p_mode SMALLINT 

	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_s_loadparms RECORD LIKE loadparms.* 
	DEFINE l_rec_loadparms RECORD LIKE loadparms.* 
	DEFINE l_rec_s_load_ind LIKE loadparms.load_ind 
	DEFINE l_lastkey INTEGER 

	### Collect AND DISPLAY the default load details ###
	SELECT * INTO l_rec_loadparms.* 
	FROM loadparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND module_code = 'AR' 
	AND load_ind = "WHI" 
	
	CALL ASW_display_parms(l_rec_loadparms.*) 
	
	IF p_mode THEN 
		LET l_msgresp = kandoomsg("U",1020,"Load File")		#U1020 Enter Load Details; OK TO Continue
	ELSE 
		LET l_msgresp = kandoomsg("U",1020,"Unload File")	#U1020 Enter Unload Details; OK TO Continue
	END IF 
	
	INPUT BY NAME 
		l_rec_loadparms.load_ind, 
		l_rec_loadparms.file_text, 
		l_rec_loadparms.path_text, 
		l_rec_loadparms.ref1_text, 
		l_rec_loadparms.ref2_text, 
		l_rec_loadparms.ref3_text WITHOUT DEFAULTS 


		BEFORE INPUT 
			CALL publish_toolbar("kandoo","ASW","inp-loadparms") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
			
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER FIELD load_ind 
			IF l_rec_loadparms.load_ind IS NULL THEN 
				LET l_msgresp = kandoomsg("U",9122,"")		#9208 Load indicator must be entered
				NEXT FIELD load_ind 
			ELSE 
				SELECT * INTO l_rec_s_loadparms.* 
				FROM loadparms 
				WHERE load_ind = l_rec_loadparms.load_ind 
				AND module_code = 'AR' 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF sqlca.sqlcode = NOTFOUND THEN 
					LET l_msgresp = kandoomsg("U",9123,"")				#9206 Invalid Load indicator
					NEXT FIELD load_ind 
				ELSE 
					CALL ASW_display_parms(l_rec_s_loadparms.*) 
				END IF 
			END IF 
			
		AFTER FIELD file_text 
			IF l_rec_loadparms.file_text IS NULL THEN 
				LET l_msgresp = kandoomsg("A",9166,"")		#9166 File name must be entered
				NEXT FIELD file_text 
			END IF 
			
		AFTER FIELD path_text 
			IF l_rec_loadparms.path_text IS NULL THEN 
				LET l_msgresp = kandoomsg("A",8015,"")				#8015 Warning: Current directory will be defaulted
			END IF 
			LET l_lastkey = fgl_lastkey() 
			
		BEFORE FIELD ref1_text 
			IF l_rec_loadparms.entry1_flag = 'N' THEN 
				CASE 
					WHEN l_lastkey = fgl_keyval("RETURN") 
						OR l_lastkey = fgl_keyval("right") 
						OR l_lastkey = fgl_keyval("tab") 
						OR l_lastkey = fgl_keyval("down") 
						NEXT FIELD NEXT 
					WHEN l_lastkey = fgl_keyval("left") 
						OR l_lastkey = fgl_keyval("up") 
						NEXT FIELD previous 
				END CASE 
			END IF
			 
		AFTER FIELD ref1_text 
			IF l_rec_loadparms.entry1_flag = 'Y' THEN 
				IF l_rec_loadparms.ref1_text IS NULL THEN 
					LET l_msgresp = kandoomsg("A",9164,"")				#9164 Invoice load reference must be entered
					NEXT FIELD ref1_text 
				END IF 
				LET l_lastkey = fgl_lastkey() 
			END IF 
			
		BEFORE FIELD ref2_text 
			IF l_rec_loadparms.entry2_flag = 'N' THEN 
				CASE 
					WHEN l_lastkey = fgl_keyval("RETURN") 
						OR l_lastkey = fgl_keyval("right") 
						OR l_lastkey = fgl_keyval("tab") 
						OR l_lastkey = fgl_keyval("down") 
						NEXT FIELD NEXT 
					WHEN l_lastkey = fgl_keyval("left") 
						OR l_lastkey = fgl_keyval("up") 
						NEXT FIELD previous 
				END CASE 
			END IF 
			
		AFTER FIELD ref2_text 
			IF l_rec_loadparms.entry2_flag = 'Y' THEN 
				IF l_rec_loadparms.ref2_text IS NULL THEN 
					LET l_msgresp = kandoomsg("A",9164,"")		#9164 Invoice load reference must be entered
					NEXT FIELD ref2_text 
				END IF 
				LET l_lastkey = fgl_lastkey() 
			END IF 
			
		BEFORE FIELD ref3_text 
			IF l_rec_loadparms.entry3_flag = 'N' THEN 
				NEXT FIELD load_ind 
			END IF 
			
		AFTER FIELD ref3_text 
			IF l_rec_loadparms.entry3_flag = 'Y' THEN 
				IF l_rec_loadparms.ref3_text IS NULL THEN 
					LET l_msgresp = kandoomsg("A",9164,"") 			#9164 Invoice load reference must be entered
					NEXT FIELD ref3_text 
				END IF 
				LET l_lastkey = fgl_lastkey() 
			END IF 
			
		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN 
				IF l_rec_loadparms.load_ind IS NULL THEN 
					LET l_msgresp = kandoomsg("A",9208,"") 			#9208 Load indicator must be entered
					NEXT FIELD load_ind 
				END IF 
				
				IF l_rec_loadparms.file_text IS NULL THEN 
					LET l_msgresp = kandoomsg("A",9166,"")				#9166 File name must be entered
					NEXT FIELD file_text 
				END IF 
				
				IF l_rec_loadparms.entry1_flag = 'Y' THEN 
					IF l_rec_loadparms.ref1_text IS NULL THEN 
						LET l_msgresp = kandoomsg("A",9164,"")					#9164 Invoice load reference must be entered
						NEXT FIELD ref1_text 
					END IF 
				END IF 
				IF l_rec_loadparms.entry2_flag = 'Y' THEN 
					IF l_rec_loadparms.ref2_text IS NULL THEN 
						LET l_msgresp = kandoomsg("A",9164,"") 					#9164 Invoice load reference must be entered
						NEXT FIELD ref2_text 
					END IF 
				END IF 
				
				IF l_rec_loadparms.entry3_flag = 'Y' THEN 
					IF l_rec_loadparms.ref3_text IS NULL THEN 
						LET l_msgresp = kandoomsg("A",9164,"")				#9164 Invoice load reference must be entered
						NEXT FIELD ref3_text 
					END IF 
				END IF 
				
				IF l_rec_loadparms.path_text IS NULL	OR length(l_rec_loadparms.path_text) = 0 THEN 
					LET l_rec_loadparms.path_text = "." 
				END IF 
				
				CALL valid_load(l_rec_loadparms.path_text, l_rec_loadparms.file_text)		RETURNING modu_load_file
				 
				IF modu_load_file IS NULL THEN 
					NEXT FIELD file_text 
				END IF 
			END IF 

	END INPUT 
	
	IF int_flag OR quit_flag THEN 
		LET quit_flag = false 
		LET int_flag = false 
		RETURN false 
	ELSE 
		LET modu_load_ind = l_rec_loadparms.load_ind 
		LET modu_path_text = l_rec_loadparms.path_text 
		RETURN true 
	END IF 
END FUNCTION 
##########################################################################
# END FUNCTION import_invcash(p_mode)
##########################################################################


##########################################################################
# FUNCTION ASW_display_parms(p_rec_loadparms)
#
# DISPLAY the Load Parameter Values
##########################################################################
FUNCTION ASW_display_parms(p_rec_loadparms) 
	DEFINE p_rec_loadparms RECORD LIKE loadparms.* 

	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_prmpt1_text LIKE loadparms.prmpt1_text 
	DEFINE l_prmpt2_text LIKE loadparms.prmpt1_text 
	DEFINE l_prmpt3_text LIKE loadparms.prmpt1_text 

	LET l_prmpt1_text = ASW_make_prompt(p_rec_loadparms.prmpt1_text) 
	LET l_prmpt2_text = ASW_make_prompt(p_rec_loadparms.prmpt2_text) 
	LET l_prmpt3_text = ASW_make_prompt(p_rec_loadparms.prmpt3_text) 
	
	DISPLAY l_prmpt1_text TO loadparms.prmpt1_text attribute(white)
	DISPLAY l_prmpt2_text TO loadparms.prmpt2_text attribute(white)
	DISPLAY l_prmpt3_text TO loadparms.prmpt3_text attribute(white) 
	 
	DISPLAY BY NAME 
		p_rec_loadparms.load_ind, 
		p_rec_loadparms.desc_text, 
		p_rec_loadparms.seq_num, 
		p_rec_loadparms.load_date, 
		p_rec_loadparms.load_num, 
		p_rec_loadparms.seq_num, 
		p_rec_loadparms.load_date, 
		p_rec_loadparms.load_num, 
		p_rec_loadparms.file_text, 
		p_rec_loadparms.path_text, 
		p_rec_loadparms.ref1_text, 
		p_rec_loadparms.ref2_text, 
		p_rec_loadparms.ref3_text 

END FUNCTION 
##########################################################################
# END FUNCTION ASW_display_parms(p_rec_loadparms)
##########################################################################


##########################################################################
# FUNCTION ASW_make_prompt(p_ref_text)
#
# Make the Load Parameter Prompt
##########################################################################
FUNCTION ASW_make_prompt(p_ref_text) 
	DEFINE p_ref_text LIKE loadparms.ref1_text 
	DEFINE l_temp_text LIKE loadparms.ref1_text 

	IF p_ref_text IS NOT NULL THEN 
		RETURN p_ref_text 
	ELSE 
		LET l_temp_text = p_ref_text clipped,"..............." 
		RETURN l_temp_text 
	END IF 

END FUNCTION 
##########################################################################
# END FUNCTION ASW_make_prompt(p_ref_text)
##########################################################################


##########################################################################
# FUNCTION valid_load(p_path_name, p_file_name)
#
# Valid Load File
#
# Test's performed :             #
#        1. File NOT found       #
#        2. No read permission   #
#        3. File IS Empty        #
#        4. OTHERWISE            #
##########################################################################
FUNCTION valid_load(p_path_name, p_file_name) 
	DEFINE p_file_name CHAR(100) 
	DEFINE p_path_name CHAR(100) 

	DEFINE l_runner CHAR(100) 
	DEFINE l_load_file CHAR(100) 
	DEFINE l_ret_code INTEGER 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET l_load_file = p_path_name clipped, 	"/",p_file_name clipped 

	LET l_ret_code = os.path.exists(l_load_file) --huho changed TO os.path() methods 
	#LET l_runner = " [ -f ",l_load_file clipped," ] 2>>", trim(get_settings_logFile())
	#run l_runner returning l_ret_code
	IF l_ret_code THEN 
		IF modu_unload_ind THEN 
			### IF file does NOT exist FOR Unload THEN check directory ###
			IF p_path_name = "." THEN 
				RETURN l_load_file 
			ELSE 
				LET l_ret_code = os.path.exists(p_path_name) --huho changed TO os.path() methods 
				#LET l_runner = " [ -d ",p_path_name clipped," ] 2>>", trim(get_settings_logFile())
				#run l_runner returning l_ret_code
				IF l_ret_code THEN 
					IF modu_verbose_ind THEN 
						LET l_msgresp = kandoomsg("U",9107,'') 					#9107 Unload directory does NOT exist - check path
					END IF 
					RETURN "" 
				ELSE 
					RETURN l_load_file 
				END IF 
			END IF 
		END IF 

		IF modu_verbose_ind THEN 
			LET l_msgresp = kandoomsg("A",9160,'')			#9160 Load file does NOT exist - check path AND filename
		END IF 
		RETURN "" 
		
	ELSE 
	
		IF modu_unload_ind THEN 
			### IF file exists THEN don't overwrite
			LET l_msgresp = kandoomsg("P",9178,"") 		#P9178 Unload file already exists in nominated directory.
			RETURN "" 
		END IF 
	END IF 

	LET l_ret_code = os.path.readable(l_load_file) --huho changed TO os.path() methods 
	#LET l_runner = " [ -r ",l_load_file clipped," ] 2>>", trim(get_settings_logFile())
	#run l_runner returning l_ret_code
	IF l_ret_code THEN 
		IF modu_verbose_ind THEN 
			LET l_msgresp = kandoomsg("A",9162,'') 	#9162 Unable TO read load file
		END IF 
		RETURN "" 
	END IF 

	LET l_ret_code = os.path.size(l_load_file) --huho changed TO os.path() methods 
	#LET l_runner = " [ -s ",l_load_file clipped," ] 2>>", trim(get_settings_logFile())
	#run l_runner returning l_ret_code
	IF l_ret_code THEN 
		IF modu_verbose_ind THEN 
			LET l_msgresp = kandoomsg("A",9161,'') 	#9161 Load file IS empty
		END IF 
		RETURN "" 
	ELSE 
		RETURN l_load_file 
	END IF 
END FUNCTION 
##########################################################################
# END FUNCTION valid_load(p_path_name, p_file_name)
##########################################################################


##########################################################################
# FUNCTION verify_acct( p_cmpy_code, p_account_code, p_year_num, p_period_num )
#
#
# - FUNCTION verify_acct() IS a clone of vacctfunc.4gl
# - changes reqd. b/c need TO remove user interaction
# - returns STATUS ( ie. error OR acct_code )
#
##########################################################################
FUNCTION verify_acct( p_cmpy_code, p_account_code, p_year_num, p_period_num ) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_account_code LIKE coa.acct_code 
	DEFINE p_year_num LIKE coa.start_year_num 
	DEFINE p_period_num LIKE coa.start_period_num 
	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE modu_err_message CHAR(50) 

	SELECT * INTO l_rec_coa.* 
	FROM coa 
	WHERE cmpy_code = p_cmpy_code 
	AND acct_code = p_account_code 

	IF status = NOTFOUND THEN 
		LET modu_err_message = "Account: ",p_account_code clipped," NOT SET up ", 
		"FOR ", p_year_num USING "####", 
		"/", p_period_num USING "###" 
		RETURN ( modu_err_message clipped ) 

	ELSE 

		CASE 
			WHEN ( l_rec_coa.start_year_num > p_year_num ) 
				LET modu_err_message = "Account: ",p_account_code clipped," NOT OPEN ", 
				"FOR ", p_year_num USING "####", 
				"/", p_period_num USING "###" 
				RETURN ( modu_err_message clipped ) 
			WHEN ( l_rec_coa.end_year_num < p_year_num ) 
				LET modu_err_message = "Account: ",p_account_code clipped," closed ", 
				"FOR ", p_year_num USING "####", 
				"/", p_period_num USING "###" 
				RETURN ( modu_err_message clipped ) 
			WHEN ( l_rec_coa.start_year_num = p_year_num AND 
				l_rec_coa.start_period_num > p_period_num ) 
				LET modu_err_message = "Account: ",p_account_code clipped," NOT OPEN ", 
				"FOR ", p_year_num USING "####", 
				"/", p_period_num USING "###" 
				RETURN ( modu_err_message clipped ) 
			WHEN ( l_rec_coa.end_year_num = p_year_num AND 
				l_rec_coa.end_period_num < p_period_num ) 
				LET modu_err_message = "Account: ",p_account_code clipped," closed ", 
				"FOR ", p_year_num USING "####", 
				"/", p_period_num USING "###" 
				RETURN ( modu_err_message clipped ) 
			OTHERWISE 
				RETURN l_rec_coa.acct_code 
		END CASE 
	END IF 
END FUNCTION 
##########################################################################
# END FUNCTION verify_acct( p_cmpy_code, p_account_code, p_year_num, p_period_num )
##########################################################################


{
##########################################################################
# FUNCTION set1_defaults()
#
# Set Default parameters FOR Exception Report
#
##########################################################################
FUNCTION set1_defaults() 
	LET glob_rec_kandooreport.header_text = 
	"AR Invoice/Receipt Load Exception Report - ", today USING "dd/mm/yy" 
	CALL rpt_set_width(132) 
	CALL rpt_set_length(66) 
	LET glob_rec_kandooreport.menupath_text = "ASW" 
	LET glob_rec_kandooreport.selection_flag= "N" 
	LET glob_rec_kandooreport.line1_text = "WHICS", 14 spaces, 
	"Tran" 
	LET glob_rec_kandooreport.line2_text = "glob_rec_kandoouser.cmpy_code", 1 spaces, 
	"Date", 10 spaces, 
	"Type", 2 spaces, 
	"Status" 
	UPDATE kandooreport 
	SET * = glob_rec_kandooreport.* 
	WHERE report_code = glob_rec_kandooreport.report_code 
	AND language_code = glob_rec_kandooreport.language_code 
END FUNCTION 

}
##########################################################################
# FUNCTION ASW_load_routine()
#
# Load Routine
#
##########################################################################
FUNCTION ASW_load_routine() 
	DEFINE l_error_text CHAR(50) 
	DEFINE l_seq_num INTEGER 
	DEFINE l_today DATE 

	LET modu_rerun_cnt = 0 
	LET l_error_text = NULL 
	LET modu_loadfile_cnt = 0 

	### Delete any info FROM temporary tables ###
	DELETE FROM t_invoicedetl 
	IF chk_tables() THEN 
		IF modu_loadfile_ind THEN 
			IF NOT perform_load() THEN 
				LET l_error_text = "Transaction Load Problems" 
				RETURN l_error_text 
			END IF 
		END IF 

		IF setup_counts() THEN 
			CALL null_tests() 
			CALL chk_balance() 

			### Initial Update of Load Parameter Table ###
			IF (modu_load_ind IS NOT null) THEN 
				SELECT (seq_num+1) INTO l_seq_num FROM loadparms 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND module_code = "AR" 
				AND load_ind = modu_load_ind 

				WHENEVER ERROR CONTINUE 
				LET l_today = today 

				UPDATE loadparms 
				SET 
					seq_num = l_seq_num, 
					load_date = l_today 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND module_code = "AR" 
				AND load_ind = modu_load_ind 
				
				WHENEVER ERROR stop 
				WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
				
				DISPLAY l_seq_num TO loadparms.seq_num
				DISPLAY l_today TO loadparms.load_date 
				
			END IF 

			### Create the appropriate documents ###
			CALL ASW_create_ar_entry() 
			LET modu_load_cnt = modu_kandoo_ar_cnt 

			IF (modu_load_ind IS NOT null) THEN 

				### Final Update of Load Parameter Table ###
				WHENEVER ERROR CONTINUE 
				LET l_today = today 
				UPDATE loadparms 
				SET 
					load_date = l_today, 
					load_num = modu_load_cnt ### successful records ### 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND module_code = "AR" 
				AND load_ind = modu_load_ind 
				AND seq_num = l_seq_num 
				
				WHENEVER ERROR stop 
				WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
				
				DISPLAY modu_load_cnt TO loadparms.load_num 
				DISPLAY l_today TO loadparms.load_date 

			END IF 
			
			IF modu_kandoo_ar_cnt > 0 THEN 
				IF NOT ( modu_err_cnt + modu_err2_cnt ) THEN 

			#---------------------------------------------------------
			OUTPUT TO REPORT ASD_J_rpt_list_exception(
				rpt_rmsreps_idx_get_idx("ASD_J_rpt_list_exception"),
				'', 
				'', 
				'', 
				'ar LOAD completed successfully' )  
			#--------------------------------------------------------- 
					 
				END IF 
			ELSE 
				### Dummy line in REPORT TO force DISPLAY of Control Totals

			#---------------------------------------------------------
			OUTPUT TO REPORT ASD_J_rpt_list_exception(
				rpt_rmsreps_idx_get_idx("ASD_J_rpt_list_exception"),
				'', 
				'', 
				'', 
				'', 
				'', 
				'', 
				'',
				'') 
			#--------------------------------------------------------- 

			END IF 
		END IF 
	ELSE 
		LET l_error_text = "ASG SQL Tables do NOT exist." 
	END IF 
	RETURN l_error_text 
END FUNCTION 
##########################################################################
# FUNCTION ASW_load_routine()
##########################################################################


##########################################################################
# FUNCTION perform_load()
#
# Perform the Loading Routine
#
##########################################################################
FUNCTION perform_load() 
	--DEFINE l_temp_file CHAR(100) 
	DEFINE l_runner CHAR(200) 
	DEFINE l_status INTEGER 

	IF NOT modu_verbose_ind THEN 
		LET glob_rec_kandoouser.cmpy_code = get_url_company_code() 
		CALL valid_load(get_url_file_path(), get_url_file_name()) ### 2=path 3=file ### 
		RETURNING modu_load_file 
	END IF
	 
	IF modu_load_file IS NOT NULL THEN 

		### Commence LOAD ###
		LET modu_load_file = modu_load_file clipped 
		WHENEVER ERROR CONTINUE 
		LOAD FROM modu_load_file INSERT INTO asg_invcash 
		WHENEVER ERROR stop 
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

		IF sqlca.sqlcode != 0 THEN 
			LET l_status = sqlca.sqlcode 
			### Dummy line in REPORT TO force DISPLAY of Control Totals ###

			#---------------------------------------------------------
			OUTPUT TO REPORT ASD_J_rpt_list(
				rpt_rmsreps_idx_get_idx("ASD_J_rpt_list"),
				'',
				'', 
				'', 
				'', 
				'', 
				'', 
				'',
				'') 
			#--------------------------------------------------------- 


			### count total no. of invoice/receipts TO be generated ###
			CALL count_records() 
			RETURNING modu_process_cnt 
			LET modu_loadfile_cnt = modu_process_cnt - modu_rerun_cnt 
			
			### REPORT error ###
			LET modu_err2_cnt = modu_err2_cnt + 1 
			LET modu_err_message = "Refer ", trim(get_settings_logFile()), " FOR SQL Error: ", l_status, " ",	"in Load File:",modu_load_file clipped 

			#---------------------------------------------------------
			OUTPUT TO REPORT ASD_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASD_J_rpt_list_exception"),
				'', 
				'', 
				'', 
				modu_err_message ) 
			#--------------------------------------------------------- 
					 
			
			LET modu_err_text = "ASW - ",err_get(l_status) 
			CALL errorlog( modu_err_text ) 

			#---------------------------------------------------------
			OUTPUT TO REPORT ASW_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASD_J_rpt_list_exception"),
				'', 
				'', 
				'', 
				modu_err_text ) 
			#--------------------------------------------------------- 
			
			### FOR reporting purposes SET no. records processed ###
			LET modu_load_cnt = 0 
			RETURN false 
		ELSE 
			RETURN true 
		END IF 
	ELSE 
		RETURN false 
	END IF 
END FUNCTION 
##########################################################################
# END FUNCTION perform_load()
##########################################################################


##########################################################################
# FUNCTION count_records()
#
# Count how many asg_invcash records TO process
#
##########################################################################
FUNCTION count_records() 
	DEFINE l_dummy CHAR(20) 
	DEFINE l_cnt INTEGER 
	DEFINE l_count INTEGER 

	SELECT count(*) INTO l_cnt 
	FROM asg_invcash 
	IF l_cnt IS NULL THEN 
		LET l_cnt = 0 
	END IF 
	RETURN l_cnt 
END FUNCTION 
##########################################################################
# END FUNCTION count_records()
##########################################################################


##########################################################################
# FUNCTION null_tests()
#
# Perform NULL tests AND REPORT errors
#
##########################################################################
FUNCTION null_tests() 
	DEFINE l_rec_asg_invcash RECORD LIKE asg_invcash.* 

	### Null Test's on data fields ###
	DECLARE c_asgnullcheck CURSOR FOR 
	SELECT * FROM asg_invcash 
	WHERE cmpy_code IS NULL 
	OR tran_type_ind IS NULL 
	OR tran_date IS NULL 
	OR ref_text IS NULL 
	OR acct_code IS NULL 
	OR (for_debit_amt IS NULL AND for_credit_amt IS null) 
	OR cmpy_code = ' ' 
	OR tran_type_ind = ' ' 
	OR ref_text = ' ' 
	OR acct_code = ' ' 

	FOREACH c_asgnullcheck INTO l_rec_asg_invcash.* 
		IF l_rec_asg_invcash.cmpy_code IS NULL OR l_rec_asg_invcash.cmpy_code = ' ' THEN 
			LET modu_err_cnt = modu_err_cnt + 1 
			LET modu_err_message = "Null Company Code detected" 

			#---------------------------------------------------------
			OUTPUT TO REPORT ASW_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASD_J_rpt_list_exception"),
				l_rec_asg_invcash.cmpy_code, 
				l_rec_asg_invcash.tran_date, 
				l_rec_asg_invcash.ref_text, 
				modu_err_message )
			#--------------------------------------------------------- 
			
			CALL show_perc_comp(1) 
			CONTINUE FOREACH 
		END IF 

		IF l_rec_asg_invcash.tran_date IS NULL THEN 
			LET modu_err_cnt = modu_err_cnt + 1 
			LET modu_err_message = "Null Transaction Date Detected" 

			#---------------------------------------------------------
			OUTPUT TO REPORT ASW_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASD_J_rpt_list_exception"),
			 l_rec_asg_invcash.cmpy_code, 
			l_rec_asg_invcash.tran_date, 
			l_rec_asg_invcash.ref_text, 
			modu_err_message )
			#--------------------------------------------------------- 
 
			CALL show_perc_comp(1) 
			CONTINUE FOREACH 
		END IF 

		IF l_rec_asg_invcash.ref_text IS NULL THEN 
			LET modu_err_cnt = modu_err_cnt + 1 
			LET modu_err_message = "Null WHICS Cash Type Detected" 

			#---------------------------------------------------------
			OUTPUT TO REPORT ASW_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASD_J_rpt_list_exception"),
				l_rec_asg_invcash.cmpy_code, 
				l_rec_asg_invcash.tran_date, 
				l_rec_asg_invcash.ref_text, 
				modu_err_message )
			#--------------------------------------------------------- 

			CALL show_perc_comp(1) 
			CONTINUE FOREACH 
		END IF 

		IF (l_rec_asg_invcash.acct_code IS null) OR	(l_rec_asg_invcash.acct_code = ' ')	THEN 
			LET modu_err_cnt = modu_err_cnt + 1 
			LET modu_err_message = "Null Account Code Detected" 

			#---------------------------------------------------------
			OUTPUT TO REPORT ASW_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASD_J_rpt_list_exception"),
				l_rec_asg_invcash.cmpy_code, 
				l_rec_asg_invcash.tran_date, 
				l_rec_asg_invcash.ref_text, 
				modu_err_message )
			#--------------------------------------------------------- 
 
			CALL show_perc_comp(1) 
			CONTINUE FOREACH 
		END IF
		 
		IF l_rec_asg_invcash.for_debit_amt IS NULL THEN 
			LET modu_err_cnt = modu_err_cnt + 1 
			LET modu_err_message = "Null Debit Amount Detected" 

			#---------------------------------------------------------
			OUTPUT TO REPORT ASW_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASD_J_rpt_list_exception"),
				l_rec_asg_invcash.cmpy_code, 
				l_rec_asg_invcash.tran_date, 
				l_rec_asg_invcash.ref_text, 
				modu_err_message )
			#--------------------------------------------------------- 

			CALL show_perc_comp(1) 
			CONTINUE FOREACH 
		END IF
		 
		IF l_rec_asg_invcash.for_credit_amt IS NULL THEN 
			LET modu_err_cnt = modu_err_cnt + 1 
			LET modu_err_message = "Null Credit Amount Detected" 

			#---------------------------------------------------------
			OUTPUT TO REPORT ASW_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASD_J_rpt_list_exception"),
				l_rec_asg_invcash.cmpy_code, 
				l_rec_asg_invcash.tran_date, 
				l_rec_asg_invcash.ref_text, 
				modu_err_message )
			#--------------------------------------------------------- 

			CALL show_perc_comp(1) 
			CONTINUE FOREACH 
		END IF 
	END FOREACH 
	
END FUNCTION 
##########################################################################
# END FUNCTION null_tests()
##########################################################################


##########################################################################
# FUNCTION setup_counts()
#
# Set Up the Load File Count Value
#
##########################################################################
FUNCTION setup_counts() 
	### count total no. of invoices/receipts TO be generated ###
	CALL count_records() RETURNING modu_process_cnt
	 
	LET modu_load_cnt = 0 
	LET modu_load_ar_cnt = 0 
	LET modu_load_in_cnt = 0 
	LET modu_load_rc_cnt = 0 
	LET modu_kandoo_ar_cnt = 0 
	LET modu_kandoo_in_cnt = 0 
	LET modu_kandoo_rc_cnt = 0 
	LET modu_tot_ar_cnt = modu_process_cnt 
	LET modu_loadfile_cnt = modu_process_cnt - modu_rerun_cnt 
	LET modu_ap_per = 0 

	IF NOT modu_tot_ar_cnt THEN 
		LET modu_err_message = "No AR Cash Transactions TO be generated" 


			#---------------------------------------------------------
			OUTPUT TO REPORT ASW_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASD_J_rpt_list_exception"),
				'', 
				'', 
				'', 
				modu_err_message)
			#--------------------------------------------------------- 
		
 
		RETURN false 
	END IF
	 
	IF modu_verbose_ind THEN 
		DISPLAY modu_load_rc_cnt TO load_rc_cnt
		DISPLAY modu_load_in_cnt TO load_in_cnt
		DISPLAY modu_kandoo_rc_cnt TO kandoo_rc_cnt
		DISPLAY modu_kandoo_in_cnt TO kandoo_in_cnt 
		DISPLAY modu_tot_ar_cnt TO tot_ar_cnt
		DISPLAY modu_ap_per TO ap_per 

	END IF 
	RETURN true 
END FUNCTION 
##########################################################################
# END FUNCTION setup_counts()
##########################################################################


##########################################################################
# FUNCTION ASW_create_ar_entry()
#
# Create AR Entry FOR Invoice AND Receipt
#
##########################################################################
FUNCTION ASW_create_ar_entry() 
	DEFINE l_rec_cashreceipt RECORD LIKE cashreceipt.* 
	--DEFINE l_rec_invoicehead RECORD LIKE invoicehead.* 
	DEFINE l_cmpy_code LIKE asg_invcash.cmpy_code 
	DEFINE l_cust_code LIKE asg_invcash.analysis_text 
	DEFINE l_error_num SMALLINT 
	DEFINE l_count_trans SMALLINT 
	DEFINE l_status SMALLINT 
	DEFINE l_anal_text LIKE asg_invcash.analysis_text 
	DEFINE l_tran_type LIKE asg_invcash.ref_text 
	DEFINE l_tran_date LIKE asg_invcash.tran_date 
	DEFINE l_where_text CHAR(50) 
	DEFINE l_error_text CHAR(30) 

	#####################################################
	# Process WHICS AR transactions
	#####################################################
	DECLARE c1_asginvcash CURSOR with HOLD FOR 
	SELECT unique tran_date, ref_text, analysis_text, cmpy_code, count(*) 
	FROM asg_invcash 
	WHERE cmpy_code IS NOT NULL 
	AND tran_type_ind = "ADJ" 
	AND tran_date IS NOT NULL 
	AND analysis_text IS NOT NULL 
	AND ref_text IS NOT NULL 
	AND acct_code IS NOT NULL 
	AND ((for_debit_amt IS NOT NULL AND for_credit_amt IS null) OR 
	(for_debit_amt IS NULL AND for_credit_amt IS NOT null)) 
	GROUP BY 1,2,3,4 
	ORDER BY 1,2,3,4 

	FOREACH c1_asginvcash INTO l_tran_date, 
		l_tran_type, 
		l_anal_text, 
		l_cmpy_code, 
		l_count_trans 

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

		### IF there IS NOT an even number counted THEN this transaction ###
		### IS NOT complete                                              ###
		IF ((l_count_trans mod 2) > 0) THEN 
			LET modu_err_cnt = modu_err_cnt + l_count_trans 
			LET modu_err_message = 
				"Transaction:", l_tran_type, " with unique", 
				" code:", l_anal_text clipped, 
				" on ", l_tran_date, " FOR glob_rec_kandoouser.cmpy_code:", l_cmpy_code, 
				" has ", l_count_trans, " transactions." 


			#---------------------------------------------------------
			OUTPUT TO REPORT ASW_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASD_J_rpt_list_exception"),
				l_cmpy_code, 
				l_tran_date, 
				l_tran_type, 
				modu_err_message) 
			#--------------------------------------------------------- 

			LET modu_err_message = "Should be multiple of 2 transactions TO ",	"process correctly." 

			#---------------------------------------------------------
			OUTPUT TO REPORT ASW_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASD_J_rpt_list_exception"),
				"", 
				"", 
				"", 
				modu_err_message)
			#--------------------------------------------------------- 
			
			CALL show_counts(l_count_trans,"LR","") 
			CALL show_counts(l_count_trans,"LI","") 
			CALL show_perc_comp(l_count_trans) 
			CONTINUE FOREACH 
		END IF 
		
		IF (l_tran_type = "CN") OR(l_tran_type = "DD")	THEN 
			LET modu_err_cnt = modu_err_cnt + l_count_trans 
			LET modu_err_message = "WARNING: Cancellation transaction NOT processed.",	" Review transaction details." 

			#---------------------------------------------------------
			OUTPUT TO REPORT ASW_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASD_J_rpt_list_exception"),
				l_cmpy_code, 
				l_tran_date, 
				l_tran_type, 
				modu_err_message) 
			#--------------------------------------------------------- 
			
			### Increment the load Receipt/Invoice counters here ###
			CALL show_counts((l_count_trans/2),"LI","") 
			CALL show_counts((l_count_trans/2),"LR","") 
		ELSE 
			BEGIN WORK 
				
				CALL process_receipt_invoice(
					l_tran_date, 
					l_tran_type, 
					l_anal_text, 
					l_cmpy_code) 
				RETURNING 
					l_status, 
					l_rec_cashreceipt.*, 
					glob_rec_invoicehead.* 
				
				IF l_status THEN 
					CALL show_counts(2,"AR","") 
					CALL show_counts(1,"MI",glob_rec_invoicehead.inv_num) 
					CALL show_counts(1,"MR",l_rec_cashreceipt.cash_num) 

			#---------------------------------------------------------
			OUTPUT TO REPORT ASW_rpt_list(rpt_rmsreps_idx_get_idx("ASD_J_rpt_list"),
				glob_rec_invoicehead.cust_code , 
				glob_rec_invoicehead.inv_num, 
				l_rec_cashreceipt.cash_num, 
				glob_rec_invoicehead.line_num, 
				l_rec_cashreceipt.cash_amt, 
				glob_rec_invoicehead.total_amt, 
				l_tran_date) 
					
			#--------------------------------------------------------- 
					
					### Remove the appropriate rows FROM asg_invcash ###
					DELETE FROM asg_invcash 
					WHERE tran_date = l_tran_date 
					AND ref_text = l_tran_type 
					AND analysis_text = l_anal_text 
					AND cmpy_code = l_cmpy_code 
				COMMIT WORK 
			ELSE 
				ROLLBACK WORK 
			END IF 
		END IF
		 
		CALL show_perc_comp(l_count_trans) 
	END FOREACH 
END FUNCTION 
##########################################################################
# END FUNCTION ASW_create_ar_entry()
##########################################################################


##########################################################################
# FUNCTION process_receipt_invoice(p_tran_date,	p_tran_type,p_anal_text,p_cmpy_code)
#
# Process Receipt AND Invoice routine
#
##########################################################################
FUNCTION process_receipt_invoice(p_tran_date,	p_tran_type,p_anal_text,p_cmpy_code) 
	DEFINE p_tran_date LIKE asg_invcash.tran_date
	DEFINE p_tran_type LIKE asg_invcash.ref_text
	DEFINE p_anal_text LIKE asg_invcash.analysis_text
	DEFINE p_cmpy_code LIKE asg_invcash.cmpy_code
	DEFINE l_rec_s_cashreceipt RECORD LIKE cashreceipt.*
	DEFINE l_rec_cashreceipt RECORD LIKE cashreceipt.*
	DEFINE l_rec_customer RECORD LIKE customer.*
	DEFINE l_rec_invoicehead RECORD LIKE invoicehead.*
	DEFINE l_rec_bank RECORD LIKE bank.*
	DEFINE l_rec_asgreceipt RECORD LIKE asg_invcash.*
	DEFINE l_return CHAR(30)
	DEFINE l_error_text CHAR(30)
	DEFINE l_cash_num LIKE cashreceipt.cash_num
	DEFINE l_where_text CHAR(50) 

	### Increment the process receipt counter here ###
	CALL show_counts(1,"LR","") 

	INITIALIZE l_rec_cashreceipt.* TO NULL 
	INITIALIZE l_rec_customer.* TO NULL 
	INITIALIZE glob_rec_invoicehead.* TO NULL 

	WHENEVER ERROR CONTINUE 

	SELECT * INTO l_rec_asgreceipt.* FROM asg_invcash 
	WHERE cmpy_code IS NOT NULL 
	AND tran_type_ind = "ADJ" 
	AND cmpy_code = p_cmpy_code 
	AND tran_date = p_tran_date 
	AND ref_text = p_tran_type 
	AND analysis_text = p_anal_text 
	AND acct_code IS NOT NULL 
	AND (for_debit_amt IS NOT NULL AND for_credit_amt IS null) 

	IF status <> 0 THEN 

		WHENEVER ERROR stop 
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
		LET modu_err_cnt = modu_err_cnt + 2 
		LET modu_err_message = "Failed TO retrieve details of WHICS-Open Receipt.",	"A Review of the WHICS-OPen Transaction IS needed." 

			#---------------------------------------------------------
			OUTPUT TO REPORT ASW_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASD_J_rpt_list_exception"),
			l_rec_asgreceipt.cmpy_code, 
			l_rec_asgreceipt.tran_date, 
			l_rec_asgreceipt.ref_text, 
			modu_err_message) 
			#--------------------------------------------------------- 
		
		CALL show_counts(1,"LI","") 
		RETURN false, l_rec_cashreceipt.*, glob_rec_invoicehead.* 
	ELSE 
		WHENEVER ERROR stop 
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
		LET l_rec_cashreceipt.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET l_rec_cashreceipt.cash_date = l_rec_asgreceipt.tran_date 
		CALL get_fiscal_year_period_for_date(l_rec_cashreceipt.cmpy_code,l_rec_cashreceipt.cash_date) 
		RETURNING l_rec_cashreceipt.year_num, 
		l_rec_cashreceipt.period_num 
		IF l_rec_cashreceipt.year_num IS NULL 
		OR l_rec_cashreceipt.period_num IS NULL THEN 
			LET modu_err_cnt = modu_err_cnt + 2 
			LET modu_err_message = "Transaction Date ", l_rec_cashreceipt.cash_date, 
			" IS NOT in a valid year/period ", 
			" under glob_rec_kandoouser.cmpy_code: ", l_rec_cashreceipt.cmpy_code 

			#---------------------------------------------------------
			OUTPUT TO REPORT ASW_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASD_J_rpt_list_exception"),
			l_rec_asgreceipt.cmpy_code, 
			l_rec_asgreceipt.tran_date, 
			l_rec_asgreceipt.ref_text, 
			modu_err_message) 
			#--------------------------------------------------------- 
		
					 
			LET modu_err_message = "Review WHICS-Open transaction date AND/OR ", 
			"Year/Period setup." 

			#---------------------------------------------------------
			OUTPUT TO REPORT ASW_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASD_J_rpt_list_exception"),
			"", "", "", modu_err_message)
			#--------------------------------------------------------- 

			 
			CALL show_counts(1,"LI","") 
			RETURN false, l_rec_cashreceipt.*, glob_rec_invoicehead.* 
		END IF 
		### Validate the Account Code ie: Should be in the GL AND Bank Account ##
		IF NOT acct_type(l_rec_cashreceipt.cmpy_code, l_rec_asgreceipt.acct_code, coa_account_required_is_control_bank, "N")THEN 
			LET modu_err_cnt = modu_err_cnt + 2 
			LET modu_err_message = 
				"Account Code ", l_rec_asgreceipt.acct_code, 
				" IS NOT a Bank Account Code", 
				" in glob_rec_kandoouser.cmpy_code: ", l_rec_cashreceipt.cmpy_code, "."


			#---------------------------------------------------------
			OUTPUT TO REPORT ASW_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASD_J_rpt_list_exception"),
				l_rec_asgreceipt.cmpy_code, 
				l_rec_asgreceipt.tran_date, 
				l_rec_asgreceipt.ref_text, 
				modu_err_message) 
			#--------------------------------------------------------- 
				
			LET modu_err_message = "Review WHICS-Open translated Account Code." 


			#---------------------------------------------------------
			OUTPUT TO REPORT ASW_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASD_J_rpt_list_exception"),
				"", 
				"", 
				"", 
				modu_err_message) 
			#--------------------------------------------------------- 

			CALL show_counts(1,"LI","") 
			RETURN false, l_rec_cashreceipt.*, glob_rec_invoicehead.* 
		END IF
		 
		SELECT * INTO l_rec_bank.* FROM bank 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND acct_code = l_rec_asgreceipt.acct_code 
		IF status = NOTFOUND THEN 
			LET modu_err_cnt = modu_err_cnt + 2 
			LET modu_err_message = "The bank FOR account code ",	l_rec_asgreceipt.acct_code,	" IS NOT setup ",	" under glob_rec_kandoouser.cmpy_code: ", l_rec_cashreceipt.cmpy_code 
			
			#---------------------------------------------------------
			OUTPUT TO REPORT ASW_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASD_J_rpt_list_exception"),
				l_rec_asgreceipt.cmpy_code, 
				l_rec_asgreceipt.tran_date, 
				l_rec_asgreceipt.ref_text, 
				modu_err_message)
			#--------------------------------------------------------- 
							
			 
			CALL show_counts(1,"LI","") 
			RETURN false, l_rec_cashreceipt.*, glob_rec_invoicehead.* 
		END IF
		
		CALL db_customer_get_rec(UI_OFF,l_rec_bank.bank_code ) RETURNING l_rec_customer.*  # Sundry debtor has cust_code = bank_code
--		SELECT * INTO l_rec_customer.* FROM customer 
--		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
--		AND cust_code = l_rec_bank.bank_code 
		IF l_rec_customer.cust_code IS NULL THEN
		--IF status = NOTFOUND THEN 
			LET modu_err_cnt = modu_err_cnt + 2 
			LET modu_err_message = "The Customer Code ", l_rec_bank.bank_code, 
			" has NOT been setup ", 
			" under glob_rec_kandoouser.cmpy_code: ", l_rec_cashreceipt.cmpy_code
			 
			 			
			#---------------------------------------------------------
			OUTPUT TO REPORT ASW_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASD_J_rpt_list_exception"),
				l_rec_asgreceipt.cmpy_code, 
				l_rec_asgreceipt.tran_date, 
				l_rec_asgreceipt.ref_text, 
				modu_err_message)
			#--------------------------------------------------------- 
							
		 
			LET modu_err_message = "Ensure the Customer ", l_rec_bank.bank_code clipped,	" exists before processing WHICS-Open AR",	" Transactions." 
			 			
			#---------------------------------------------------------
			OUTPUT TO REPORT ASW_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASD_J_rpt_list_exception"),
				"", 
				"", 
				"", 
				modu_err_message)
			#--------------------------------------------------------- 

			 
			CALL show_counts(1,"LI","") 
			RETURN false, l_rec_cashreceipt.*, glob_rec_invoicehead.* 
		END IF 

		### Verify the receipt amount being processed ###
		IF (l_rec_asgreceipt.for_debit_amt <= 0) THEN 
			LET modu_err_cnt = modu_err_cnt + 2 
			LET modu_err_message = "The WHICS-Open transaction receipt amount <=0.", 
			" Review WHICS-Open transaction details." 

			#---------------------------------------------------------
			OUTPUT TO REPORT ASW_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASD_J_rpt_list_exception"),
				l_rec_asgreceipt.cmpy_code, 
				l_rec_asgreceipt.tran_date, 
				l_rec_asgreceipt.ref_text, 
				modu_err_message)
			#--------------------------------------------------------- 
			
			 
			LET modu_err_message = "Review the WHICS-Open transaction details." 

			#---------------------------------------------------------
			OUTPUT TO REPORT ASW_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASD_J_rpt_list_exception"),
				"", 
				"", 
				"", 
				modu_err_message)
			#--------------------------------------------------------- 
			 
			CALL show_counts(1,"LI","") 
			RETURN false, l_rec_cashreceipt.*, glob_rec_invoicehead.* 
		END IF 

		##################################################
		###          Setup the receipt detail          ###
		##################################################
		CALL cash_initialize(
			glob_rec_kandoouser.cmpy_code, 
			l_rec_bank.bank_code, 
			glob_rec_kandoouser.sign_on_code, 
			l_rec_cashreceipt.cash_date, 
			"", 
			l_rec_bank.bank_code, 
			"") 
		RETURNING 
			l_return, 
			l_rec_s_cashreceipt.*, 
			l_error_text
			 
		IF NOT l_return THEN 
			LET modu_err2_cnt = modu_err2_cnt + 2 
			LET modu_err_message = "Error Setting up Receipt",	" (", l_error_text clipped, ")." 

			#---------------------------------------------------------
			OUTPUT TO REPORT ASW_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASD_J_rpt_list_exception"),
				l_rec_asgreceipt.cmpy_code, 
				l_rec_asgreceipt.tran_date, 
				l_rec_asgreceipt.ref_text, 
				modu_err_message) 
			#--------------------------------------------------------- 
			
			LET modu_err_message = "Note the error AND contact System Administrator."
			 
			#---------------------------------------------------------
			OUTPUT TO REPORT ASW_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASD_J_rpt_list_exception"),
				"", 
				"", 
				"", 
				modu_err_message) 
			#--------------------------------------------------------- 
			 
			CALL show_counts(1,"LI","") 
			RETURN false, l_rec_s_cashreceipt.*, glob_rec_invoicehead.* 
		END IF 

		LET l_rec_s_cashreceipt.cash_amt = l_rec_asgreceipt.for_debit_amt 
		LET l_rec_s_cashreceipt.cash_type_ind = "C" 
		LET l_rec_s_cashreceipt.com1_text = "WHICS AR Cash Receipt" 
		LET l_rec_s_cashreceipt.com2_text = "Detail:", p_tran_type clipped, 
		"-", p_tran_date 
		##################################################
		###    Process AND Add the Invoice Details     ###
		##################################################
		CALL ASW_process_invoice(
			p_cmpy_code, 
			p_tran_date, 
			p_tran_type, 
			p_anal_text, 
			l_rec_s_cashreceipt.*) 
		RETURNING 
			l_return, 
			glob_rec_invoicehead.*
		 
		IF l_return THEN 
			##################################################
			###          Add the Receipt Details           ###
			##################################################
			CALL cash_add(l_rec_s_cashreceipt.*,0) 
			RETURNING 
				l_return, 
				l_rec_s_cashreceipt.cash_num, 
				l_error_text 
			
			IF l_return THEN 
				SELECT * INTO l_rec_cashreceipt.* FROM cashreceipt 
				WHERE cmpy_code = l_rec_s_cashreceipt.cmpy_code 
				AND cash_num = l_rec_s_cashreceipt.cash_num 
				##################################################
				###      Apply Receipt TO Invoice Details      ###
				##################################################
				LET l_where_text = "inv_num = ", glob_rec_invoicehead.inv_num
				 
				CALL auto_cash_apply(
					glob_rec_invoicehead.cmpy_code, 
					glob_rec_invoicehead.entry_code, 
					l_rec_cashreceipt.cash_num, 
					l_where_text, 
					false) 
				RETURNING 
					l_return, 
					l_error_text 
				
				IF NOT l_return THEN 
					LET modu_err2_cnt = modu_err2_cnt + 2 
					LET modu_err_message = "Error in Applying Cash Receipt TO Invoice.", 
					"(", l_error_text[1,30], ")", 
					". Invoice AND Receipt NOT Created. "


			#---------------------------------------------------------
			OUTPUT TO REPORT ASW_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASD_J_rpt_list_exception"),
				'', 
				'', 
				'', 
				modu_err_message) 
			#--------------------------------------------------------- 

					RETURN false, l_rec_cashreceipt.*, glob_rec_invoicehead.* 
				END IF 
			ELSE 
				LET modu_err2_cnt = modu_err2_cnt + 2 
				LET modu_err_message = "Error Creating Receipt",	" (", l_error_text clipped, ")",". Invoice AND Receipt NOT created." 


			#---------------------------------------------------------
			OUTPUT TO REPORT ASW_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASD_J_rpt_list_exception"),
				l_rec_asgreceipt.cmpy_code, 
				l_rec_asgreceipt.tran_date, 
				l_rec_asgreceipt.ref_text, 
				modu_err_message)
			#--------------------------------------------------------- 				
				 
			END IF 
		ELSE 
			### Error MESSAGE found in ASW_process_invoice below ###
			RETURN false, l_rec_cashreceipt.*, glob_rec_invoicehead.* 
		END IF 
		RETURN true, l_rec_cashreceipt.*, glob_rec_invoicehead.* 
	END IF 
END FUNCTION 
##########################################################################
# END FUNCTION process_receipt_invoice(p_tran_date,	p_tran_type,p_anal_text,p_cmpy_code)
##########################################################################


##########################################################################
# FUNCTION ASW_process_invoice(p_cmpy_code,p_tran_date,p_tran_type,p_anal_text,p_rec_cashreceipt)
#
# Process AR Invoice
#
##########################################################################
FUNCTION ASW_process_invoice(p_cmpy_code,p_tran_date,p_tran_type,p_anal_text,p_rec_cashreceipt) 

	DEFINE p_cmpy_code LIKE asg_invcash.cmpy_code 
	DEFINE p_tran_date LIKE asg_invcash.tran_date 
	DEFINE p_tran_type LIKE asg_invcash.ref_text 
	DEFINE p_anal_text LIKE asg_invcash.analysis_text 
	DEFINE p_rec_cashreceipt RECORD LIKE cashreceipt.* 
	DEFINE l_rec_s_invoicehead RECORD LIKE invoicehead.* 
	DEFINE l_rec_invoicehead RECORD LIKE invoicehead.* 
	#DEFINE glob_rec_customer    RECORD LIKE customer.*
	DEFINE l_rec_term RECORD LIKE term.* 
	DEFINE l_rec_invoicedetl RECORD LIKE invoicedetl.* 
	DEFINE l_rec_asginvoice RECORD LIKE asg_invcash.* 
	DEFINE l_acct_text CHAR(110) 
	DEFINE l_error_text CHAR(30) 
	DEFINE l_status SMALLINT 

	### Increment the load invoice counter here ###
	CALL show_counts(1,"LI","") 
	SELECT * INTO l_rec_asginvoice.* 
	FROM asg_invcash 
	WHERE cmpy_code = p_cmpy_code 
	AND tran_type_ind = "ADJ" 
	AND tran_date = p_tran_date 
	AND ref_text = p_tran_type 
	AND analysis_text = p_anal_text 
	AND acct_code IS NOT NULL 
	AND (for_debit_amt IS NULL AND for_credit_amt IS NOT null) 

	IF status = NOTFOUND THEN 
		LET l_error_text = "Failed TO SELECT WHICS Details" 
		RETURN false, glob_rec_invoicehead.*, l_error_text 
	ELSE 
		INITIALIZE glob_rec_invoicehead.* TO NULL 
		INITIALIZE l_rec_invoicedetl.* TO NULL 
		INITIALIZE l_rec_term.* TO NULL 

		IF (l_rec_asginvoice.for_credit_amt != p_rec_cashreceipt.cash_amt) THEN 
			LET modu_err_cnt = modu_err_cnt + 2 ### 2 transactions ### 
			LET modu_err_message = 
				"Invoice amount: ", l_rec_asginvoice.for_credit_amt, 
				" NOT EQUAL Receipt amount:", 
				l_rec_asginvoice.for_debit_amt, 
				". Invoice AND Receipt NOT created." 

			#---------------------------------------------------------
			OUTPUT TO REPORT ASW_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASD_J_rpt_list_exception"),
				l_rec_asginvoice.cmpy_code, 
				l_rec_asginvoice.tran_date, 
				l_rec_asginvoice.ref_text, 
				modu_err_message)
			#--------------------------------------------------------- 				

			 
			RETURN false, glob_rec_invoicehead.* 
		END IF
		 
		########################################################
		###      Create an INITIALIZEd invoicehead RECORD    ###
		########################################################
		CALL invoice_initialize(p_rec_cashreceipt.cmpy_code, 
			p_rec_cashreceipt.cust_code, 
			"", 
			"", 
			glob_rec_kandoouser.sign_on_code, 
			p_rec_cashreceipt.cash_date, 
			1) 
		RETURNING 
			l_status, 
			glob_rec_invoicehead.*, 
			l_error_text 

		IF NOT l_status THEN 
			LET modu_err2_cnt = modu_err2_cnt + 2 
			LET modu_err_message = "Error Setting up Invoice"," (", l_error_text clipped, ")"," Review WHICS transaction." 
			
			#---------------------------------------------------------
			OUTPUT TO REPORT ASW_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASD_J_rpt_list_exception"),
				l_rec_asginvoice.cmpy_code, 
				l_rec_asginvoice.tran_date, 
				l_rec_asginvoice.ref_text, 
				modu_err_message)
			#--------------------------------------------------------- 				

			 
			RETURN false, glob_rec_invoicehead.* 
		END IF 

		CALL verify_acct(
			glob_rec_invoicehead.cmpy_code, 
			l_rec_asginvoice.acct_code, 
			glob_rec_invoicehead.year_num, 
			glob_rec_invoicehead.period_num) 
		RETURNING l_acct_text 

		IF l_acct_text != l_rec_asginvoice.acct_code THEN 
			LET modu_err_cnt = modu_err_cnt + 2 
			LET modu_err_message = l_acct_text clipped,	". Invoice AND Receipt NOT created.",	" Review WHICS Transaction." 
			
			#---------------------------------------------------------
			OUTPUT TO REPORT ASW_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASD_J_rpt_list_exception"),
				p_cmpy_code, 
				p_tran_date, 
				p_tran_type, 
				modu_err_message) 
			#--------------------------------------------------------- 				
			RETURN false, glob_rec_invoicehead.* 
		END IF 

		LET glob_rec_invoicehead.currency_code = p_rec_cashreceipt.currency_code 
		LET glob_rec_invoicehead.conv_qty = p_rec_cashreceipt.conv_qty 
		LET glob_rec_invoicehead.com1_text = "WHICS AR Invoice" 
		LET glob_rec_invoicehead.com2_text = "Detail:", p_tran_type 

		INITIALIZE l_rec_invoicedetl.* TO NULL 

		LET glob_rec_invoicehead.line_num = glob_rec_invoicehead.line_num + 1 
		LET l_rec_invoicedetl.cmpy_code = glob_rec_invoicehead.cmpy_code 
		LET l_rec_invoicedetl.cust_code = glob_rec_invoicehead.cust_code 
		LET l_rec_invoicedetl.inv_num = glob_rec_invoicehead.inv_num 
		LET l_rec_invoicedetl.line_num = glob_rec_invoicehead.line_num 
		LET l_rec_invoicedetl.ord_qty = 1 
		LET l_rec_invoicedetl.ship_qty = 1 
		LET l_rec_invoicedetl.prev_qty = 0 
		LET l_rec_invoicedetl.back_qty = 0 
		LET l_rec_invoicedetl.ser_flag = 'N' 
		LET l_rec_invoicedetl.ser_qty = 0 
		LET l_rec_invoicedetl.line_text = "WHICS AR Invoice Load" 
		LET l_rec_invoicedetl.unit_cost_amt = 0 
		LET l_rec_invoicedetl.ext_cost_amt = 0 
		LET l_rec_invoicedetl.disc_amt = 0 
		LET l_rec_invoicedetl.disc_per = 0 
		LET l_rec_invoicedetl.unit_sale_amt = l_rec_asginvoice.for_credit_amt 
		LET l_rec_invoicedetl.ext_sale_amt = l_rec_asginvoice.for_credit_amt 
		LET l_rec_invoicedetl.unit_tax_amt = 0 
		LET l_rec_invoicedetl.ext_tax_amt = 0 
		LET l_rec_invoicedetl.line_total_amt = l_rec_asginvoice.for_credit_amt 
		LET l_rec_invoicedetl.line_acct_code = l_rec_asginvoice.acct_code 
		LET l_rec_invoicedetl.level_code = 'L' 
		LET l_rec_invoicedetl.comm_amt = 0 
		LET l_rec_invoicedetl.tax_code = glob_rec_customer.tax_code 
		LET l_rec_invoicedetl.sold_qty = 1 
		LET l_rec_invoicedetl.bonus_qty = 0 
		LET l_rec_invoicedetl.ext_bonus_amt = 0 
		LET l_rec_invoicedetl.ext_stats_amt = 0 
		LET l_rec_invoicedetl.list_price_amt = 0 

		INSERT INTO t_invoicedetl VALUES (l_rec_invoicedetl.*) 

		### Parse the invoicehead AND t_invoicedetl records through the ###
		### setup routine TO ensure the default VALUES are SET.         ###
		CALL invoice_verify(glob_rec_invoicehead.*)
		RETURNING 
			l_status, 
			l_rec_s_invoicehead.*, 
			l_error_text 
		
		IF l_status THEN 
			### Insert invoice & invoicedetl ###
			CALL write_invoice(glob_rec_invoicehead.*, MODE_CLASSIC_ADD) 
			RETURNING 
				l_status, 
				glob_rec_invoicehead.inv_num, 
				l_error_text 
			
			IF l_status THEN 
				CALL db_invoicehead_get_rec(UI_OFF,glob_rec_invoicehead.inv_num) RETURNING glob_rec_invoicehead.*
				--SELECT * INTO glob_rec_invoicehead.* 
				--FROM invoicehead 
				--WHERE inv_num = glob_rec_invoicehead.inv_num 
				--AND cmpy_code = glob_rec_invoicehead.cmpy_code 
			ELSE 
				LET modu_err2_cnt = modu_err2_cnt + 1 
				LET modu_err_message = 
					"Error Creating Invoice (", 
					l_error_text clipped, ")", 
					". Invoice AND Receipt NOT Created.", 
					" Review WHICS Transaction details."
				 
			#---------------------------------------------------------
			OUTPUT TO REPORT ASW_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASD_J_rpt_list_exception"),
				l_rec_asginvoice.cmpy_code, 
				l_rec_asginvoice.tran_date, 
				l_rec_asginvoice.ref_text, 
				modu_err_message)
			#--------------------------------------------------------- 			
				 
				DELETE FROM t_invoicedetl WHERE 1=1
				 
				RETURN false, glob_rec_invoicehead.* 
			END IF 

		ELSE 

			LET modu_err2_cnt = modu_err2_cnt + 1 
			LET modu_err_message = 
				"Error in Invoice Verification (", 
				l_error_text clipped, ")", 
				". Invoice AND Receipt NOT Created.", 
				" Review WHICS Transaction details." 
			 
			#---------------------------------------------------------
			OUTPUT TO REPORT ASW_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASD_J_rpt_list_exception"),
				l_rec_asginvoice.cmpy_code, 
				l_rec_asginvoice.tran_date, 
				l_rec_asginvoice.ref_text, 
				modu_err_message) 
			#--------------------------------------------------------- 			

			DELETE FROM t_invoicedetl WHERE 1=1 

			RETURN false, glob_rec_invoicehead.* 
		END IF 
	END IF
	 
	DELETE FROM t_invoicedetl WHERE 1=1 
	
	RETURN true, glob_rec_invoicehead.* 
END FUNCTION 
##########################################################################
# END FUNCTION ASW_process_invoice(p_cmpy_code,p_tran_date,p_tran_type,p_anal_text,p_rec_cashreceipt)
##########################################################################


##########################################################################
# FUNCTION set2_defaults()
#
# Set defaults FOR AR Load Exception Report
#
##########################################################################
FUNCTION set2_defaults()
{ 
	LET glob_rec_s_kandooreport.header_text = "AR Invoice/Receipt Load - ", 
	today USING "dd/mm/yyyy" 
	LET glob_rec_s_kandooreport.width_num = 132 
	LET glob_rec_s_kandooreport.length_num = 66 
	LET glob_rec_s_kandooreport.menupath_text = "ASW" 
	LET glob_rec_s_kandooreport.selection_flag = "N" 
	LET glob_rec_s_kandooreport.line1_text = "Company", 2 spaces, 
	"Customer", 2 spaces, 
	"Tran. Date", 2 spaces, 
	"Invoice No.", 4 spaces, 
	"Receipt No.", 18 spaces, 
	"Inv.Lines", 7 spaces, 
	"Debit Amount", 6 spaces, 
	"Credit Amount" 
	UPDATE kandooreport 
	SET * = glob_rec_s_kandooreport.* 
	WHERE report_code = glob_rec_s_kandooreport.report_code 
	AND language_code = glob_rec_s_kandooreport.language_code 
	}
END FUNCTION 
##########################################################################
# END FUNCTION set2_defaults()
##########################################################################


##########################################################################
# FUNCTION ASW_rpt_start()
#
# INITIALIZE AND SET defaults FOR the AR Load Report
#
##########################################################################
FUNCTION ASW_rpt_start() 
	DEFINE l_rpt_idx SMALLINT

	#------------------------------------------------------------
	# Report for exceptions
	LET l_rpt_idx = rpt_start("ASW-ERROR","ASW_rpt_list_exception","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT ASW_rpt_list_exception TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ASW_rpt_list_exception")].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0

	#Report for success
	LET l_rpt_idx = rpt_start("ASW","ASW_rpt_list","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT ASW_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ASW_rpt_list")].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0
	#LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ASW_rpt_list")].sel_text
	#------------------------------------------------------------

END FUNCTION 
##########################################################################
# END FUNCTION ASW_rpt_start()
##########################################################################


#########################################################################
# FUNCTION ASW_finish_report()
#
#
#########################################################################
FUNCTION ASW_finish_report() 

	#------------------------------------------------------------
	# Actual (positive) report
	FINISH REPORT ASW_rpt_list
	CALL rpt_finish("ASW_rpt_list")
	#------------------------------------------------------------

	#------------------------------------------------------------
	# ERROR/Exception Report
	FINISH REPORT ASW_rpt_list_exception
	CALL rpt_finish("ASW_rpt_list_exception")
	#------------------------------------------------------------
	  	 
END FUNCTION 
#########################################################################
# END FUNCTION ASW_finish_report()
#########################################################################


##########################################################################
# FUNCTION ASW_rerun()
#
# Rerun the AR processing
#
##########################################################################
FUNCTION ASW_rerun() 
	DEFINE l_rerun_ind SMALLINT 

	LET l_rerun_ind = true 
	CALL count_records() 
	RETURNING modu_rerun_cnt 
	IF modu_verbose_ind THEN 
		IF modu_rerun_cnt > 0 THEN 
			
			IF kandoomsg("A",7060,modu_rerun_cnt) = 'N' THEN #7060 Warning: X entries detected in holding table. Unload (Y/N)? 
				LET l_rerun_ind = false 
			END IF 
		END IF 
	END IF 
	RETURN l_rerun_ind 
END FUNCTION 
##########################################################################
# END FUNCTION ASW_rerun()
##########################################################################


##########################################################################
# FUNCTION init_values()
#
# INITIALIZE Counters
#
##########################################################################
FUNCTION init_values() 
	### INITIALIZE default VALUES ###
	LET modu_err_cnt = 0 
	LET modu_err2_cnt = 0 
	LET modu_kandoo_in_cnt = 0 
	LET modu_kandoo_rc_cnt = 0 
	LET modu_total_invoice_amt = 0 
	LET modu_total_rec_amt = 0 
	LET modu_rerun_cnt = NULL 
END FUNCTION 
##########################################################################
# END FUNCTION init_values()
##########################################################################


##########################################################################
# FUNCTION ASW_start_load(l_rerun_flag)
#
# Start Load
#
##########################################################################
FUNCTION ASW_start_load(l_rerun_flag) 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rerun_flag SMALLINT 
	DEFINE l_error_text CHAR(50) 

	CALL init_values() 
	IF modu_verbose_ind THEN 
		IF NOT l_rerun_flag THEN 
			IF ASW_rerun() THEN 
				LET modu_unload_ind = true 
				IF NOT ASW_unload(0) THEN 
					RETURN false 
				END IF 
				LET modu_unload_ind = false 
			ELSE 
				RETURN false 
			END IF 
			IF NOT import_invcash(true) THEN 
				RETURN false 
			END IF 
		END IF 

		CALL ASW_rpt_start() 
		CALL ASW_load_routine()	RETURNING l_error_text 

		IF (l_error_text IS NOT null) THEN 
			LET l_msgresp = kandoomsg("A",7089,l_error_text)		#7046 AR File Load Aborted. ????????
		ELSE 
			IF (modu_err_cnt + modu_err2_cnt) THEN 
				LET l_msgresp = kandoomsg("A",7090,(modu_err_cnt+modu_err2_cnt))		#7047 AR Load Completed, Errors Encountered
			ELSE 
				IF modu_kandoo_ar_cnt > 0 THEN 
					LET l_msgresp = kandoomsg("A",7091,'') 		#7048 AR Load Completed Successfully
				ELSE 
					LET l_msgresp = kandoomsg("A",7092,'') 		#7049 There are NO AR transactions TO process
				END IF 
			END IF 
		END IF 
		
	ELSE
	 
		#
		# Non-interactive load
		#
		CALL ASW_rpt_start() 
		CALL ASW_load_routine() RETURNING l_error_text 
	END IF 

	#
	# FINISH REPORT load_list() first b/c we need TO trigger 'ON LAST ROW'
	#        of ASW_rpt_list_exception() REPORT with Control Totals
	#
	CALL ASW_finish_report() 

	IF l_error_text THEN 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 
##########################################################################
# END FUNCTION ASW_start_load(l_rerun_flag)
##########################################################################


##########################################################################
# FUNCTION chk_tables()
#
# Check the permanent table that are used specifically FOR this routine
#
##########################################################################
FUNCTION chk_tables() 
	DEFINE l_msgresp LIKE language.yes_flag 
	#
	# ASG specific check's on the permanent tables FOR load routine
	#
	### IF the ASG Invoice/Receipt table does NOT exist abort load ###
	SELECT unique 1 FROM systables 
	WHERE tabname = "asg_invcash" 
	IF sqlca.sqlcode = NOTFOUND THEN 
		LET modu_err2_cnt = modu_err2_cnt + 1 
		LET modu_err_message = "Execute SQL script TO create ASG tables first ",	" Load Aborted" 

			#---------------------------------------------------------
			OUTPUT TO REPORT ASW_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASD_J_rpt_list_exception"),
				'', 
				'', 
				'', 
				modu_err_message )
			#--------------------------------------------------------- 			
		 
		IF modu_verbose_ind THEN 
			ERROR modu_err_message 
		END IF 
		#
		# Dummy line in REPORT TO force DISPLAY of Control Totals
		#
			#---------------------------------------------------------
			OUTPUT TO REPORT ASW_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASD_J_rpt_list_exception"),
				'', 
				'', 
				'', 
				'', 
				'', 
				'', 
				'',
				'') 
			#--------------------------------------------------------- 
 
		RETURN false 
	END IF 
	RETURN true 
END FUNCTION 
##########################################################################
# END FUNCTION chk_tables()
##########################################################################


##########################################################################
# FUNCTION chk_balance()
#
# Check Balance of Debits versus Credits
#
##########################################################################
FUNCTION chk_balance() 
	DEFINE l_msgresp LIKE language.yes_flag 
	#
	# As stated by WHICS - each transaction will have a debit AND credit
	# entry therefore we should expect sum of all debits = sum of all credits
	#
	DEFINE l_sum_of_debits DECIMAL(16,2)
	DEFINE l_sum_of_credits DECIMAL(16,2) 

	SELECT sum(for_debit_amt), sum(for_credit_amt) 
	INTO l_sum_of_debits, l_sum_of_credits 
	FROM asg_invcash 

	IF l_sum_of_debits IS NULL THEN 
		LET l_sum_of_debits = 0 
	END IF 

	IF l_sum_of_credits IS NULL THEN 
		LET l_sum_of_credits = 0 
	END IF 

	### Verify the Debit versus Credits - But do NOT stop processing ###
	IF (l_sum_of_debits != l_sum_of_credits) THEN 
		LET modu_err_message = 
			"Warning: Debits = ", l_sum_of_debits, 
			" NOT EQUAL Credits = ", l_sum_of_credits 

			#---------------------------------------------------------
			OUTPUT TO REPORT ASW_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASD_J_rpt_list_exception"),
			'', '', '', modu_err_message ) 
			#--------------------------------------------------------- 

		
	END IF 
END FUNCTION 
##########################################################################
# FUNCTION chk_balance()
##########################################################################


##########################################################################
# FUNCTION ASW_unload(p_show_message)
#
#
#
##########################################################################
FUNCTION ASW_unload(p_show_message) 
	DEFINE p_show_message SMALLINT 

	DEFINE l_unload_cnt INTEGER 
	DEFINE l_msgresp LIKE language.yes_flag
	 	
	#
	# ASW_unload UNLOAD contents of interim table
	#
	IF count_records() THEN 
		IF import_invcash(false) THEN 
			WHENEVER ERROR CONTINUE 
			UNLOAD TO modu_load_file SELECT * FROM asg_invcash 
			WHENEVER ERROR stop 
			WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
			IF sqlca.sqlcode = 0 THEN 
				LET l_unload_cnt = sqlca.sqlerrd[3] 
				IF l_unload_cnt IS NULL THEN 
					LET l_unload_cnt = 0 
				END IF 

				IF kandoomsg("A",8020,l_unload_cnt) = 'Y' THEN		#8020 <VALUE> records unloaded FROM table. Confirm TO CLEAR (Y/N)?
					DELETE FROM asg_invcash WHERE 1=1 
					RETURN true 
				ELSE 
					RETURN false 
				END IF 

			ELSE 
				RETURN false 
			END IF 
		ELSE 
			RETURN false 
		END IF 

	ELSE 

		IF p_show_message THEN 
			LET l_msgresp = kandoomsg("P",7049,'') 
			#7050 There are NO AP transactions TO generate
		END IF 
		RETURN true 
	END IF 
END FUNCTION 
##########################################################################
# FUNCTION ASW_unload(p_show_message)
##########################################################################


##########################################################################
# FUNCTION move_load_file()
#
# Move the original Load File TO another filename
#
##########################################################################
FUNCTION move_load_file() 
	DEFINE l_move_file CHAR(100)
	DEFINE l_move_text CHAR(200)
	DEFINE l_move_path CHAR(100) 
	DEFINE l_runner CHAR(300)
	DEFINE l_ret_code INTEGER 

	LET l_move_path = modu_path_text 
	LET l_move_text = modu_load_file clipped, ".tmp" 
	WHILE true 

		LET l_ret_code = os.path.exists(l_move_text) --huho changed TO os.path() methods 
		#LET l_runner = " [ -f ",l_move_text clipped," ] 2>>", trim(get_settings_logFile())
		#run l_runner returning l_ret_code
		IF l_ret_code THEN 
			EXIT WHILE 
		ELSE 
			IF modu_verbose_ind THEN 
				ERROR " Cannot move load file - File already exists" 
				LET l_move_file = "" 

				LET l_move_file = fgl_winprompt(5,5, "Enter Move file name", "", 25, 0) 

				IF int_flag OR quit_flag THEN 
					LET int_flag = false 
					LET quit_flag = false 
					RETURN 
				ELSE 
					LET l_move_text = modu_path_text clipped, 
					"/", l_move_file clipped 
				END IF 
			ELSE 
				RETURN 
			END IF 
		END IF 
	END WHILE 

	LET l_runner = " mv ", modu_load_file clipped, " ", l_move_text clipped, " 2> /dev/NULL" 
	RUN l_runner 
END FUNCTION 
##########################################################################
# END FUNCTION move_load_file()
##########################################################################


##########################################################################
# FUNCTION show_perc_comp(p_count_value)
#
# Show Percentage Complete
#
##########################################################################
FUNCTION show_perc_comp(p_count_value) 
	DEFINE p_count_value SMALLINT 

	### Show percentage complete ###
	LET modu_load_ar_cnt = modu_load_ar_cnt + p_count_value 
	LET modu_ap_per = ( modu_load_ar_cnt / modu_tot_ar_cnt ) * 100 
	IF modu_verbose_ind THEN 
		DISPLAY modu_ap_per TO ap_per  
	END IF 
END FUNCTION 
##########################################################################
# END FUNCTION show_perc_comp(p_count_value)
##########################################################################


##########################################################################
# FUNCTION show_counts(p_count,p_which_one,p_entity_value)
#
# Show Counts
#
##########################################################################
FUNCTION show_counts(p_count,p_which_one,p_entity_value) 
	DEFINE p_count SMALLINT 
	DEFINE p_which_one CHAR(2) 
	DEFINE p_entity_value CHAR(20) 

	CASE p_which_one 
		WHEN "LI" LET modu_load_in_cnt = modu_load_in_cnt + p_count 
		WHEN "LR" LET modu_load_rc_cnt = modu_load_rc_cnt + p_count 
		WHEN "MI" LET modu_kandoo_in_cnt = modu_kandoo_in_cnt + p_count 
		WHEN "MR" LET modu_kandoo_rc_cnt = modu_kandoo_rc_cnt + p_count 
		WHEN "AR" LET modu_kandoo_ar_cnt = modu_kandoo_ar_cnt + p_count 
	END CASE 

	IF modu_verbose_ind THEN 
		DISPLAY modu_load_rc_cnt TO load_rc_cnt
		DISPLAY modu_load_in_cnt TO load_in_cnt
		DISPLAY modu_kandoo_rc_cnt TO rc_cnt 
		DISPLAY modu_kandoo_in_cnt TO in_cnt 

		IF p_entity_value IS NOT NULL AND	p_entity_value != " "	THEN 
			CASE p_which_one 
				WHEN "LI" DISPLAY p_entity_value TO inv_num 

				WHEN "LR" DISPLAY p_entity_value TO cash_num 

				WHEN "MI" DISPLAY p_entity_value TO inv_num 

				WHEN "MR" DISPLAY p_entity_value TO cash_num 

			END CASE 
		END IF 
	END IF 
END FUNCTION 
##########################################################################
# END FUNCTION show_counts(p_count,p_which_one,p_entity_value)
##########################################################################


##########################################################################
# REPORT ASW_rpt_list(p_rpt_idx, p_cmpy_code, p_cust_code, p_inv_num, p_cash_num,	p_line_num, p_debit_amt, p_credit_amt, p_tran_date)
#
# AR Load Report
#
##########################################################################
REPORT ASW_rpt_list(p_rpt_idx, p_cmpy_code, p_cust_code, p_inv_num, p_cash_num,	p_line_num, p_debit_amt, p_credit_amt, p_tran_date)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx] 
	DEFINE p_cmpy_code LIKE company.cmpy_code
	DEFINE p_cust_code LIKE customer.cust_code
	DEFINE p_tran_date LIKE asg_invcash.tran_date
	DEFINE p_inv_num LIKE invoicehead.inv_num
	DEFINE p_cash_num LIKE cashreceipt.cash_num
	DEFINE p_line_num LIKE invoicehead.line_num
	DEFINE p_debit_amt LIKE cashreceipt.cash_amt
	DEFINE p_credit_amt LIKE invoicehead.total_amt 
	
	OUTPUT 
--	left margin 0 
	ORDER external BY 
		p_cmpy_code, 
		p_cust_code, 
		p_inv_num, 
		p_cash_num
	 
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
			PRINT COLUMN 001, p_cmpy_code, 
			COLUMN 010, p_cust_code, 
			COLUMN 020, p_tran_date USING "dd/mm/yyyy", 
			COLUMN 033, p_inv_num USING "##########", 
			COLUMN 048, p_cash_num USING "##########", 
			COLUMN 078, p_line_num USING "###", 
			COLUMN 087, p_debit_amt USING "#############&.&&", 
			COLUMN 106, p_credit_amt USING "#############&.&&" 
			IF p_inv_num IS NOT NULL THEN 
				LET modu_total_invoice_amt = modu_total_invoice_amt + p_credit_amt 
			END IF 
			IF p_cash_num IS NOT NULL THEN 
				LET modu_total_rec_amt = modu_total_rec_amt + p_debit_amt 
			END IF 
		ON LAST ROW 
			NEED 10 LINES 
			SKIP 2 LINES 
			PRINT COLUMN 087, "-------------------------------------" 
			PRINT COLUMN 087, modu_total_rec_amt USING "#############&.&&", 
			COLUMN 106, modu_total_invoice_amt USING "#############&.&&" 
			PRINT COLUMN 087, "-------------------------------------" 
			SKIP 1 line 
			
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
	
END REPORT 
##########################################################################
# END REPORT ASW_rpt_list(p_rpt_idx, p_cmpy_code, p_cust_code, p_inv_num, p_cash_num,	p_line_num, p_debit_amt, p_credit_amt, p_tran_date)
##########################################################################


##########################################################################
# REPORT ASW_rpt_list_exception(p_rpt_idx,p_cmpy_code,p_tran_date,p_ref_text,p_status)
#
##########################################################################
REPORT ASW_rpt_list_exception(p_rpt_idx,p_cmpy_code,p_tran_date,p_ref_text,p_status)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_tran_date LIKE asg_invcash.tran_date 
	DEFINE p_ref_text LIKE asg_invcash.ref_text 
	DEFINE p_status CHAR(110) 

	OUTPUT 
--	left margin 0 
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text
			 			 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]
			
			SKIP 3 LINES 

		ON EVERY ROW 
			PRINT COLUMN 01, p_cmpy_code, 
			COLUMN 06, p_tran_date, 
			COLUMN 20, p_ref_text clipped, 
			COLUMN 26, p_status clipped 

		ON LAST ROW 
			NEED 20 LINES 
			SKIP 3 LINES 
			PRINT COLUMN 10, "Total records TO be processed : ", 
			modu_loadfile_cnt 
			SKIP 1 line 
			PRINT COLUMN 10, "Total records with validation errors : ",modu_err_cnt 
			PRINT COLUMN 10, "Total records with SQL/File errors : ",modu_err2_cnt 
			PRINT COLUMN 10, "Total records successfully processed : ", 
			modu_load_cnt 
			PRINT COLUMN 10, "( total no. OF Invoices:", 
			COLUMN 39, modu_kandoo_in_cnt USING "###########&", " )" 
			PRINT COLUMN 10, "( total no. OF Receipts:", 
			COLUMN 39, modu_kandoo_rc_cnt USING "###########&", " )" 
			PRINT COLUMN 55, "-------------" 
			PRINT COLUMN 55, ( modu_err_cnt + modu_err2_cnt + modu_load_cnt ) USING "###########&" 
			SKIP 1 line 
			PRINT COLUMN 10, "Total invoice amounts :", 
			COLUMN 55, modu_total_invoice_amt USING "--------&.&&" 
			PRINT COLUMN 10, "Total receipt amounts :", 
			COLUMN 55, modu_total_rec_amt USING "--------&.&&" 
			PRINT COLUMN 55, "-------------" 
			PRINT COLUMN 55, ( modu_total_invoice_amt + modu_total_rec_amt) 
			USING "--------&.&&" 
			SKIP 2 LINES 
			
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			
END REPORT 
##########################################################################
# END REPORT ASW_rpt_list_exception(p_rpt_idx,p_cmpy_code,p_tran_date,p_ref_text,p_status)
##########################################################################