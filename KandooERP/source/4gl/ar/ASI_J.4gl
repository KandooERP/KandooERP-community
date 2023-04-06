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
GLOBALS "../ar/ASI_J_GLOBALS.4gl"
############################################################
# Module Scope Variables
############################################################
--DEFINE modu_t_output CHAR(50) 
DEFINE modu_s_output CHAR(50) 
DEFINE modu_load_file CHAR(100) 
DEFINE modu_err_message CHAR(100) 
DEFINE modu_query_text CHAR(400) 
DEFINE modu_err_text CHAR(250) 
DEFINE modu_rerun_cnt INTEGER 
DEFINE modu_loadfile_cnt INTEGER 
DEFINE modu_arload_cnt INTEGER 
DEFINE modu_glload_cnt INTEGER 
DEFINE modu_jmj_ar_cnt INTEGER 
DEFINE modu_jmj_cred_cnt INTEGER 
DEFINE modu_kandoo_ar_cnt INTEGER 
DEFINE modu_kandoo_in_cnt INTEGER 
DEFINE modu_kandoo_cr_cnt INTEGER 
DEFINE modu_process_cnt INTEGER 
DEFINE modu_err2_cnt INTEGER 
DEFINE modu_err_cnt INTEGER 
DEFINE modu_loadfile_ind SMALLINT 
DEFINE modu_glload_ind SMALLINT 
DEFINE modu_unload_ind SMALLINT 
DEFINE modu_move_ind SMALLINT 
DEFINE modu_verbose_ind SMALLINT 
DEFINE modu_total_in_amt LIKE invoicehead.total_amt 
DEFINE modu_total_cr_amt LIKE invoicehead.total_amt 
DEFINE modu_jmj_cmpy_code LIKE company.cmpy_code 
DEFINE modu_auto_cmpy_code LIKE company.cmpy_code 
DEFINE modu_file_text CHAR(20) 
DEFINE modu_path_text CHAR(60) 
#########################################################################
# FUNCTION ASI_J_main()
#
#   ASI_J - Invoice Detail Load   ** SITE SPECIFIC **
#########################################################################
FUNCTION ASI_J_main() 
	DEFER QUIT 
	DEFER INTERRUPT 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 
	
	CALL setModuleId("ASI_J") 
	#
	# create temp. table TO hold no. of invoices / credits TO be processed
	#
	CREATE temp TABLE t_trancnt 
	( tran_cnt INTEGER ) with no LOG 
	IF get_url_load_file() IS NOT NULL THEN 
		#
		# fglgo ASI_J <load-files>
		#
		LET modu_verbose_ind = false 
		LET modu_loadfile_ind = true 
		LET modu_unload_ind = false 
		CALL ASI_J_start_load() 
		#
		# Create GL Batch
		#
		CALL ASI_J_create_gl_entry() 
		CALL ASI_J_move_load_file() 
		EXIT PROGRAM( modu_err_cnt + modu_err2_cnt ) 
	ELSE 
		LET modu_verbose_ind = true 

		OPEN WINDOW A637 with FORM "A637" 
		CALL windecoration_a("A637") 

		MENU " Invoice Detail Load" 

			BEFORE MENU 
				CALL publish_toolbar("kandoo","ASI_J","menu-invoice-detail-load") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null)
				 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			COMMAND "Load" " Commence load process" 
				LET modu_loadfile_ind = true 
				LET modu_move_ind = true 
				LET modu_unload_ind = false 
				CALL ASI_J_start_load() 
				IF modu_move_ind THEN 
					CALL ASI_J_move_load_file() 
				END IF 
				CALL rpt_rmsreps_reset(NULL)
				 
			COMMAND "Rerun" " Commence load FROM interim table" 
				LET modu_loadfile_ind = false 
				LET modu_unload_ind = false 
				CALL ASI_J_start_load() 
				CALL rpt_rmsreps_reset(NULL)
				 
			COMMAND "Unload" " Unload contents of interim table" 
				LET modu_loadfile_ind = true 
				LET modu_unload_ind = true 
				CALL ASI_J_unload() 
				CALL rpt_rmsreps_reset(NULL)

			ON ACTION "Print Manager" #COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
				CALL run_prog("URS","","","","") 
				 
			COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus" 
				LET quit_flag = true 
				EXIT MENU 

		END MENU 
		CLOSE WINDOW A637 
	END IF 
END FUNCTION


#########################################################################
# FUNCTION ASI_J_import_invoice()
#
#
#########################################################################
FUNCTION ASI_J_import_invoice() 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_dummy_field CHAR(3) 

	LET modu_jmj_cmpy_code = '9' 
	LET modu_auto_cmpy_code = '5' 
	LET l_msgresp = kandoomsg("A",1058,"") 
	#1058 Enter Invoice Load Details - ESC TO Continue
	INPUT modu_file_text, 
	modu_path_text, 
	modu_jmj_cmpy_code, 
	modu_auto_cmpy_code, 
	l_dummy_field WITHOUT DEFAULTS 
	FROM
	modu_file_text, 
	modu_path_text, 
	modu_jmj_cmpy_code, 
	modu_auto_cmpy_code, 
	l_dummy_field 	
	

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","ASI","inp-file-path") 

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
					IF NOT ASI_J_create_load_file( modu_path_text , 
					modu_file_text ) THEN 
						NEXT FIELD file_text 
					END IF 
				END IF 
			END IF 

	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET quit_flag = false 
		LET int_flag = false 
		LET modu_move_ind = false 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 


#########################################################################
# FUNCTION ASI_J_load_routine()
#
#
#########################################################################
FUNCTION ASI_J_load_routine() 

	LET modu_rerun_cnt = 0 
	LET modu_loadfile_cnt = 0 

	IF ASI_J_chk_tables() THEN 
		IF ASI_J_rerun() THEN 
			IF modu_loadfile_ind THEN 
				CALL ASI_J_perform_load() 
			END IF 
			CALL ASI_J_null_tests() 
			IF ASI_J_chk_setup() THEN 
				CALL setup_cnt() 
				CALL ASI_J_create_ar_entry() 
				#
				#
				IF NOT ( modu_err_cnt + modu_err2_cnt ) 
				AND ( modu_kandoo_in_cnt + modu_kandoo_cr_cnt ) THEN 
				#---------------------------------------------------------
				OUTPUT TO REPORT ASI_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASI_J_rpt_list_exception"),
				'', '', '', 
					'invoice detail LOAD completed successfully' )  
				#--------------------------------------------------------- 
						
				END IF 
			END IF 
		END IF 
	END IF 
END FUNCTION 




#########################################################################
# FUNCTION ASI_J_create_load_file( p_path_text, p_file_text )
#
#
#########################################################################
FUNCTION ASI_J_create_load_file( p_path_text, p_file_text ) 
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
	LET modu_load_file = ASI_J_valid_load_file( modu_load_file ) 
	IF modu_load_file IS NULL THEN 
		RETURN false 
	ELSE 
		IF modu_unload_ind THEN 
			LET l_ret_code = os.path.exists(p_path_text) --huho changed TO os.path() 
			#LET l_runner = " [ -d ",p_path_text clipped," ] 2>>", trim(get_settings_logFile())
			#run l_runner returning l_ret_code
			IF l_ret_code THEN 
				ERROR " Directory does NOT exist - check pathname" 
				RETURN false 
			END IF 
		END IF 
		RETURN true 
	END IF 
END FUNCTION 



#########################################################################
# FUNCTION ASI_J_valid_load_file(p_file_name)
#
#
# Test's performed :
#
#        1. File NOT found
#        2. No read permission
#        3. File IS Empty
#        4. OTHERWISE
#
#########################################################################
FUNCTION ASI_J_valid_load_file(p_file_name) 
	DEFINE p_file_name CHAR(100) 

	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_runner CHAR(100) 
	DEFINE l_ret_code INTEGER 

	LET l_ret_code = os.path.exists(p_file_name) --huho changed TO os.path() methods 
	#LET l_runner = " [ -f ",p_file_name clipped," ] 2>>", trim(get_settings_logFile())
	#run l_runner returning l_ret_code
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
		LET modu_err_message = "Load file: ", p_file_name clipped, " does NOT exist" 
				#---------------------------------------------------------
				OUTPUT TO REPORT ASI_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASI_J_rpt_list_exception"),
				'', '', '', 
				modu_err_message)  
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

	LET l_ret_code = os.path.readable(p_file_name) --huho changed TO os.path() methods 
	#LET l_runner = " [ -r ",p_file_name clipped," ] 2>>", trim(get_settings_logFile())
	#run l_runner returning l_ret_code
	IF l_ret_code THEN 
		IF modu_verbose_ind THEN 
			LET l_msgresp = kandoomsg("A",9162,'') 
			#9162 Unable TO read load file
		END IF 
		LET modu_err2_cnt = modu_err2_cnt + 1 
		LET modu_err_message = "Unable TO read load file: ",p_file_name clipped 
				#---------------------------------------------------------
				OUTPUT TO REPORT ASI_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASI_J_rpt_list_exception"),
				'', '', '', 
				modu_err_message)  
				#--------------------------------------------------------- 		
		RETURN "" 
	END IF 

	LET l_ret_code = os.path.size(p_file_name) --huho changed TO os.path() methods 
	#LET l_runner = " [ -s ",p_file_name clipped," ] 2>>", trim(get_settings_logFile())
	#run l_runner returning l_ret_code
	IF l_ret_code THEN 
		IF modu_verbose_ind THEN 
			LET l_msgresp = kandoomsg("A",9161,'') 
			#9161 Load file IS empty
		END IF 
		LET modu_err2_cnt = modu_err2_cnt + 1 
		LET modu_err_message = "Load file: ",p_file_name," IS empty" 
		#---------------------------------------------------------
		OUTPUT TO REPORT ASI_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASI_J_rpt_list_exception"),
		'', '', '', 
		modu_err_message)  
		#--------------------------------------------------------- 		
		RETURN "" 
	ELSE 
		RETURN p_file_name 
	END IF 
END FUNCTION 


#########################################################################
# FUNCTION ASI_J_create_ar_entry()
#
#
#########################################################################
FUNCTION ASI_J_create_ar_entry() 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_customer    RECORD LIKE customer.*
	DEFINE l_rec_jmj_invdetl RECORD LIKE jmj_invoicedetail.* 
	DEFINE l_rec_invoicehead RECORD LIKE invoicehead.* 
	DEFINE l_rec_invoicedetl RECORD LIKE invoicedetl.* 
	DEFINE l_rec_credithead RECORD LIKE credithead.* 
	DEFINE l_rec_creditdetl RECORD LIKE creditdetl.* 
	DEFINE l_rec_term RECORD LIKE term.* 
	DEFINE l_rec_araudit RECORD LIKE araudit.* 
	DEFINE l_cmpy_code LIKE company.cmpy_code 
	DEFINE l_process_grp LIKE jmj_invoicedetail.expdrs_process_grp 
	DEFINE l_cust_code LIKE jmj_invoicedetail.expdrs_client 
	DEFINE l_s_cust_code LIKE jmj_invoicedetail.expdrs_client 
	DEFINE l_inv_num LIKE jmj_invoicedetail.expdrs_invoice_no 
	DEFINE l_s_trans_num LIKE invoicehead.inv_num 
	DEFINE l_line_text LIKE invoicedetl.line_text 
	DEFINE l_line_acct_code LIKE invoicedetl.line_acct_code 
	DEFINE l_invoicehead_due_date LIKE invoicehead.due_date 
	DEFINE l_invoicehead_disc_date LIKE invoicehead.disc_date 
	DEFINE l_ar_per DECIMAL(6,3) 
	DEFINE l_cred_per DECIMAL(6,3) 
	DEFINE l_ar_cnt DECIMAL(6,3) 
	DEFINE ls_ar_cnt INTEGER 
	DEFINE l_setup_head_ind SMALLINT 
	DEFINE l_inv_text CHAR(8) 
	DEFINE l_mask_code LIKE customertype.acct_mask_code 
	DEFINE l_date DATE 
	DEFINE l_acct_text CHAR(50) 
	DEFINE l_status INTEGER 

	LET l_ar_cnt = 0 
	LET modu_jmj_ar_cnt = 0 
	LET l_ar_per = 0 
	LET l_cred_per = 0 

	DELETE FROM t_trancnt 
	INSERT INTO t_trancnt SELECT count(*) 
	FROM jmj_invoicedetail 
	WHERE expdrs_record_type != 'C' 
	AND expdrs_imprest != 'W' 
	AND expdrs_record_type IS NOT NULL 
	AND expdrs_record_type != ' ' 
	AND expdrs_imprest IS NOT NULL 
	AND expdrs_imprest != ' ' 
	AND expdrs_client IS NOT NULL 
	AND expdrs_invoice_no IS NOT NULL 
	AND expdrs_date IS NOT NULL 
	AND expdrs_process_grp IS NOT NULL 
	AND expdrs_trans_type IS NOT NULL 
	AND expdrs_amount IS NOT NULL 
	AND expdrs_client != ' ' 
	AND expdrs_amount >= 0 
	GROUP BY expdrs_process_grp, 
	expdrs_client, 
	expdrs_invoice_no, 
	expdrs_date 
	SELECT count(*) INTO ls_ar_cnt 
	FROM t_trancnt 
	IF ls_ar_cnt IS NULL THEN 
		LET ls_ar_cnt = 0 
	END IF 
	#
	# possible no. of invoices TO be generated
	#
	LET modu_jmj_ar_cnt = modu_jmj_ar_cnt + ls_ar_cnt 
	DELETE FROM t_trancnt 
	INSERT INTO t_trancnt SELECT count(*) 
	FROM jmj_invoicedetail 
	WHERE expdrs_record_type != 'C' 
	AND expdrs_imprest != 'W' 
	AND expdrs_record_type IS NOT NULL 
	AND expdrs_record_type != ' ' 
	AND expdrs_imprest IS NOT NULL 
	AND expdrs_imprest != ' ' 
	AND expdrs_client IS NOT NULL 
	AND expdrs_invoice_no IS NOT NULL 
	AND expdrs_date IS NOT NULL 
	AND expdrs_process_grp IS NOT NULL 
	AND expdrs_trans_type IS NOT NULL 
	AND expdrs_amount IS NOT NULL 
	AND expdrs_client != ' ' 
	AND expdrs_amount < 0 
	GROUP BY expdrs_process_grp, 
	expdrs_client, 
	expdrs_invoice_no, 
	expdrs_date 
	SELECT count(*) INTO ls_ar_cnt 
	FROM t_trancnt 
	IF ls_ar_cnt IS NULL THEN 
		LET ls_ar_cnt = 0 
	END IF 
	#
	# possible no. of credits TO be generated
	#
	LET modu_jmj_ar_cnt = modu_jmj_ar_cnt + ls_ar_cnt 
	IF NOT modu_jmj_ar_cnt THEN 
		LET modu_err_message = "No AR transactions TO be generated" 
		#---------------------------------------------------------
		OUTPUT TO REPORT ASI_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASI_J_rpt_list_exception"),
		'', '', '', 
		modu_err_message)  
		#--------------------------------------------------------- 		
		RETURN 
	END IF 
	IF modu_verbose_ind THEN 
		DISPLAY modu_kandoo_ar_cnt TO kandoo_ar_cnt
		DISPLAY modu_jmj_ar_cnt TO jmj_ar_cnt
		DISPLAY l_ar_per TO ar_per

	END IF 
	#
	# Declare dynamic CURSOR
	#
	LET modu_query_text = " SELECT * FROM customer ", 
	" WHERE cmpy_code = ? ", 
	" AND cust_code = ? ", 
	" AND delete_flag = 'N' ", 
	" FOR UPDATE " 
	PREPARE s1_customer FROM modu_query_text 
	DECLARE c1_customer CURSOR with HOLD FOR s1_customer 
	#
	#
	#
	LET modu_query_text = "SELECT acct_mask_code ", 
	"FROM customertype, customer ", 
	"WHERE customer.cmpy_code = ? ", 
	"AND customer.cust_code = ? ", 
	"AND customertype.cmpy_code = customer.cmpy_code ", 
	"AND customertype.type_code = customer.type_code ", 
	"AND customertype.acct_mask_code IS NOT NULL " 
	PREPARE s_custtype FROM modu_query_text 
	DECLARE c_custtype CURSOR with HOLD FOR s_custtype 
	#
	#
	# Create AR Invoices
	#
	#
	DECLARE c_jmjinvdetl CURSOR with HOLD FOR 
	SELECT unique expdrs_process_grp, 
	expdrs_client, 
	expdrs_invoice_no, 
	expdrs_date 
	FROM jmj_invoicedetail 
	WHERE expdrs_record_type != 'C' 
	AND expdrs_imprest != 'W' 
	AND expdrs_record_type IS NOT NULL 
	AND expdrs_record_type != ' ' 
	AND expdrs_imprest IS NOT NULL 
	AND expdrs_imprest != ' ' 
	AND expdrs_client IS NOT NULL 
	AND expdrs_invoice_no IS NOT NULL 
	AND expdrs_date IS NOT NULL 
	AND expdrs_process_grp IS NOT NULL 
	AND expdrs_trans_type IS NOT NULL 
	AND expdrs_amount IS NOT NULL 
	AND expdrs_client != ' ' 
	AND expdrs_amount >= 0 
	ORDER BY 1, 2, 3 
	FOREACH c_jmjinvdetl INTO l_process_grp, 
		l_s_cust_code, 
		l_inv_num, 
		l_date 
		IF int_flag OR quit_flag THEN 
			IF modu_verbose_ind THEN 
				#8004 Do you wish TO quit (Y/N) ?
				IF kandoomsg("A",8004,"") = 'Y' THEN 
					EXIT FOREACH 
				END IF 
			ELSE 
				EXIT FOREACH 
			END IF 
			#
			# INT / quit-flag placed here so as NOT TO trigger
			# generation of credits
			#
			LET int_flag = false 
			LET quit_flag = false 
		END IF 
		#
		# Calculate percentage complete
		#
		LET l_ar_cnt = l_ar_cnt + 1 
		LET l_ar_per = ( l_ar_cnt / modu_jmj_ar_cnt ) * 100 
		IF modu_verbose_ind THEN 
			DISPLAY l_ar_per TO ar_per 
			DISPLAY l_ar_cnt TO ar_cnt

		END IF 
		#
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
						OUTPUT TO REPORT ASI_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASI_J_rpt_list_exception"),
						l_process_grp, 
								l_s_cust_code , 
								l_inv_num , 
								modu_err_message )  
						#--------------------------------------------------------- 						
 
						CONTINUE FOREACH 
					END IF 
				ELSE 
					LET modu_err2_cnt = modu_err2_cnt + 1 
					#---------------------------------------------------------
					OUTPUT TO REPORT ASI_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASI_J_rpt_list_exception"),
					l_process_grp, 
					l_s_cust_code , 
					l_inv_num , 
					modu_err_message )  
					#--------------------------------------------------------- 						
					LET modu_err_text = "ASI_J - ",err_get(STATUS) 
					CALL errorlog( modu_err_text ) 
					ROLLBACK WORK 
					CONTINUE FOREACH 
				END IF 
			END IF 
			LABEL bypass: 
			WHENEVER ERROR GOTO recovery 
			BEGIN WORK 
				INITIALIZE l_rec_customer.* TO NULL 
				#
				# Indicate that header needs TO be setup
				#
				LET l_setup_head_ind = false 
				#
				DECLARE c_invdetl CURSOR FOR 
				SELECT * FROM jmj_invoicedetail 
				WHERE expdrs_process_grp = l_process_grp 
				AND expdrs_client = l_s_cust_code 
				AND expdrs_invoice_no = l_inv_num 
				AND expdrs_date = l_date 
				AND expdrs_record_type!= 'C' 
				AND expdrs_imprest != 'W' 
				AND expdrs_amount >= 0 
				OPEN c_invdetl 
				WHILE true 
					FETCH c_invdetl INTO l_rec_jmj_invdetl.* 
					IF sqlca.sqlcode = NOTFOUND THEN 
						EXIT WHILE 
					END IF 
					IF NOT l_setup_head_ind THEN 
						#
						# Retrieve glob_rec_kandoouser.cmpy_code
						#
						IF l_rec_jmj_invdetl.expdrs_process_grp >= 20 
						AND l_rec_jmj_invdetl.expdrs_process_grp <= 29 THEN 
							LET l_cmpy_code = modu_auto_cmpy_code 
						ELSE 
							LET l_cmpy_code = modu_jmj_cmpy_code 
						END IF 

						#
						# Retrieve customer
						#
						CASE 
							WHEN length( l_s_cust_code ) = 0 
								LET modu_err_cnt = modu_err_cnt + 1 
								LET modu_err_message = "No customer code specified ", 
								"at glob_rec_kandoouser.cmpy_code: ",l_cmpy_code 
								#---------------------------------------------------------
								OUTPUT TO REPORT ASI_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASI_J_rpt_list_exception"),
								l_process_grp, 
											l_s_cust_code , 
											l_inv_num , 
											modu_err_message )  
								#--------------------------------------------------------- 												
 
								ROLLBACK WORK 
								CONTINUE FOREACH 
							WHEN length( l_s_cust_code ) > 5 
								#
								# Retrieve 'TRUE' debtor code
								#
								SELECT cust_code INTO l_cust_code 
								FROM jmj_truedebtor 
								WHERE cmpy_code = l_cmpy_code 
								AND client_code = l_s_cust_code 
								IF sqlca.sqlcode = NOTFOUND 
								OR (sqlca.sqlcode = 0 AND (length(l_cust_code)=0)) THEN 
									LET l_status = sqlca.sqlcode 
									LET modu_err_cnt = modu_err_cnt + 1 
									LET modu_err_message = 
									"TRUE debtor code NOT SET up FOR primary debtor", 
									" AT glob_rec_kandoouser.cmpy_code:", l_cmpy_code
								#---------------------------------------------------------
								OUTPUT TO REPORT ASI_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASI_J_rpt_list_exception"),
									l_process_grp, 
									l_s_cust_code , 
									l_inv_num , 
									modu_err_message ) 
								#--------------------------------------------------------- 										 

									ROLLBACK WORK 
									#
									# Insert dummy entry
									#
									IF l_status != 0 THEN 
										INSERT INTO jmj_truedebtor VALUES 
										( l_cmpy_code, 
										l_s_cust_code, 
										l_rec_jmj_invdetl.expdrs_name, 
										'' ) 
									END IF 
									CONTINUE FOREACH 
								END IF 
							OTHERWISE 
								LET l_cust_code = l_s_cust_code 
						END CASE 
						OPEN c1_customer USING l_cmpy_code, 
						l_cust_code 
						FETCH c1_customer INTO l_rec_customer.* 
						IF sqlca.sqlcode = NOTFOUND THEN 
							#
							# all related detail lines will be skipped
							#
							IF modu_verbose_ind THEN 
								#
								# Hide previous descriptions
								#
								DISPLAY l_rec_customer.name_text TO name_text 

							END IF 
							LET modu_err_cnt = modu_err_cnt + 1 
							LET modu_err_message = "Customer code NOT SET up ", 
							"at glob_rec_kandoouser.cmpy_code: ",l_cmpy_code 
							#---------------------------------------------------------
							OUTPUT TO REPORT ASI_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASI_J_rpt_list_exception"),
								l_process_grp, 
								l_cust_code , 
								l_inv_num , 
								modu_err_message ) 
							#--------------------------------------------------------- 							
							ROLLBACK WORK 
							CONTINUE FOREACH 
						END IF 
						IF modu_verbose_ind THEN 
							DISPLAY l_rec_customer.cust_code TO cust_code
							DISPLAY l_rec_customer.name_text TO name_text

						END IF 
						#
						# Set up Invoicehead
						#
						INITIALIZE l_rec_invoicehead.* TO NULL 
						LET l_rec_invoicehead.cmpy_code = l_cmpy_code 
						LET l_rec_invoicehead.cust_code = l_cust_code 
						LET l_rec_invoicehead.org_cust_code = l_rec_customer.corp_cust_code 
						IF l_rec_invoicehead.org_cust_code IS NOT NULL THEN 
							SELECT unique 1 FROM customer 
							WHERE cmpy_code = l_rec_invoicehead.cmpy_code 
							AND cust_code = l_rec_invoicehead.org_cust_code 
							IF sqlca.sqlcode = 0 THEN 
								LET l_rec_invoicehead.org_cust_code = 
								l_rec_invoicehead.cust_code 
								LET l_rec_invoicehead.cust_code = 
								l_rec_customer.corp_cust_code 
							END IF 
						END IF 
						IF l_inv_num <= 999999 THEN 
							LET l_inv_text = l_inv_num USING "&&&&&&", "00" 
							LET l_rec_invoicehead.inv_num = l_inv_text clipped 
							LET l_s_trans_num = next_tran_num( 'l_i', 
							l_cmpy_code, 
							l_rec_invoicehead.inv_num ) 
						ELSE 
							IF l_inv_num > 999999 THEN 
								SELECT unique 1 FROM invoicehead 
								WHERE inv_num = l_inv_num 
								AND cmpy_code = l_cmpy_code 
								IF status != NOTFOUND THEN 
									LET l_s_trans_num = NULL 
								ELSE 
									LET l_rec_invoicehead.inv_num = l_inv_num 
									LET l_s_trans_num = l_inv_num 
								END IF 
							END IF 
						END IF 
						CASE 
							WHEN l_s_trans_num IS NULL 
								#
								# Cannot retrieve an invoice no.
								#
								LET modu_err_cnt = modu_err_cnt + 1 
								LET modu_err_message = 
								"Error generating invoice number FOR ", 
								"JMJ Invoice AT glob_rec_kandoouser.cmpy_code: ",l_cmpy_code
							#---------------------------------------------------------
							OUTPUT TO REPORT ASI_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASI_J_rpt_list_exception"),
								l_process_grp, 
								l_s_cust_code , 
								l_inv_num , 
								modu_err_message ) 
							#--------------------------------------------------------- 									 
								ROLLBACK WORK 
								CONTINUE FOREACH 
							WHEN l_s_trans_num != l_rec_invoicehead.inv_num 
								#
								# JMJ Invoice No. has been modified
								#
								LET modu_err_message = 
								"JMJ Invoice No.: ",l_rec_invoicehead.inv_num 
								USING "<<<<<<<<"," ", 
								"mapped TO Invoice No.: ",l_s_trans_num 
								USING "<<<<<<<<" 
							#---------------------------------------------------------
							OUTPUT TO REPORT ASI_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASI_J_rpt_list_exception"),
								l_process_grp, 
								l_s_cust_code , 
								l_inv_num , 
								modu_err_message ) 
							#--------------------------------------------------------- 										

						END CASE 
						LET l_rec_invoicehead.inv_num = l_s_trans_num 
						LET l_rec_invoicehead.ord_num = NULL 
						#
						# Transaction Type Translation Table
						#
						SELECT desc_text, 
						cr_acct_code, 
						debt_type_code 
						INTO l_line_text, 
						l_line_acct_code, 
						l_rec_invoicehead.purchase_code 
						FROM jmj_trantype 
						WHERE cmpy_code = l_rec_invoicehead.cmpy_code 
						AND trans_code = l_rec_jmj_invdetl.expdrs_trans_type 
						AND record_ind = l_rec_jmj_invdetl.expdrs_record_type 
						AND imprest_ind = l_rec_jmj_invdetl.expdrs_imprest 
						IF sqlca.sqlcode = NOTFOUND THEN 
							LET modu_err_cnt = modu_err_cnt + 1 
							LET modu_err_message = 
							"No entry in VMS Trans. table FOR ", 
							"Trans. :",l_rec_jmj_invdetl.expdrs_trans_type USING "&&", 
							" RECORD Ind. :",l_rec_jmj_invdetl.expdrs_record_type, 
							" Imprest Ind.:",l_rec_jmj_invdetl.expdrs_imprest, 
							" glob_rec_kandoouser.cmpy_code.:",l_rec_invoicehead.cmpy_code 
							#---------------------------------------------------------
							OUTPUT TO REPORT ASI_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASI_J_rpt_list_exception"),
								l_process_grp, 
							l_s_cust_code , 
							l_inv_num , 
							modu_err_message ) 
							#--------------------------------------------------------- 								

							ROLLBACK WORK 
							CONTINUE FOREACH 
						END IF 
						LET l_rec_invoicehead.job_code = NULL 
						LET l_rec_invoicehead.inv_date = l_rec_jmj_invdetl.expdrs_date 
						LET l_rec_invoicehead.entry_code = glob_rec_kandoouser.sign_on_code 
						LET l_rec_invoicehead.entry_date = today 
						LET l_rec_invoicehead.sale_code = l_rec_customer.sale_code 
						LET l_rec_invoicehead.term_code = l_rec_customer.term_code 
						LET l_rec_invoicehead.disc_per = 0 
						LET l_rec_invoicehead.tax_code = l_rec_customer.tax_code 
						LET l_rec_invoicehead.tax_per = 0 
						LET l_rec_invoicehead.goods_amt = 0 
						LET l_rec_invoicehead.hand_amt = 0 
						LET l_rec_invoicehead.hand_tax_code = l_rec_customer.tax_code 
						LET l_rec_invoicehead.hand_tax_amt = 0 
						LET l_rec_invoicehead.freight_amt = 0 
						LET l_rec_invoicehead.freight_tax_code = l_rec_customer.tax_code 
						LET l_rec_invoicehead.freight_tax_amt = 0 
						LET l_rec_invoicehead.tax_amt = 0 
						LET l_rec_invoicehead.disc_amt = 0 
						LET l_rec_invoicehead.total_amt = 0 
						LET l_rec_invoicehead.cost_amt = 0 
						LET l_rec_invoicehead.paid_amt = 0 
						LET l_rec_invoicehead.paid_date = NULL 
						LET l_rec_invoicehead.disc_taken_amt = 0 
						LET l_rec_invoicehead.expected_date = NULL 
						LET l_rec_invoicehead.on_state_flag = 'N' 
						LET l_rec_invoicehead.posted_flag = 'N' 
						LET l_rec_invoicehead.seq_num = 0 
						LET l_rec_invoicehead.line_num = 0 
						LET l_rec_invoicehead.printed_num = 1 
						LET l_rec_invoicehead.story_flag = 'N' 
						LET l_rec_invoicehead.rev_date = today 
						LET l_rec_invoicehead.rev_num = 0 
						LET l_rec_invoicehead.ship_code = NULL 
						LET l_rec_invoicehead.name_text = NULL 
						LET l_rec_invoicehead.addr1_text = NULL 
						LET l_rec_invoicehead.addr2_text = NULL 
						LET l_rec_invoicehead.city_text = NULL 
						LET l_rec_invoicehead.state_code = NULL 
						LET l_rec_invoicehead.post_code = NULL 
						LET l_rec_invoicehead.country_code = NULL --@db-patch_2020_10_04--
						LET l_rec_invoicehead.ship1_text = NULL 
						LET l_rec_invoicehead.ship2_text = NULL 
						LET l_rec_invoicehead.ship_date = NULL 
						LET l_rec_invoicehead.fob_text = NULL 
						LET l_rec_invoicehead.prepaid_flag = NULL 
						LET l_rec_invoicehead.com1_text = NULL 
						LET l_rec_invoicehead.com2_text = NULL 
						LET l_rec_invoicehead.cost_ind = 'L' 
						LET l_rec_invoicehead.currency_code = 'AUD' 
						LET l_rec_invoicehead.conv_qty = 1 
						LET l_rec_invoicehead.inv_ind = "X" 
						LET l_rec_invoicehead.prev_paid_amt = 0 
						LET l_rec_invoicehead.acct_override_code = NULL 
						#
						# Acct. Masking : CUSTOMERTYPE
						#
						OPEN c_custtype USING l_rec_invoicehead.cmpy_code, 
						l_rec_invoicehead.cust_code 
						FETCH c_custtype INTO l_mask_code 
						IF status = 0 THEN 
							LET l_rec_invoicehead.acct_override_code = 
							build_mask( l_rec_invoicehead.cmpy_code, 
							l_rec_invoicehead.acct_override_code, 
							l_mask_code ) 
						END IF 
						LET l_rec_invoicehead.price_tax_flag = '0' 
						LET l_rec_invoicehead.contact_text = NULL 
						LET l_rec_invoicehead.tele_text = NULL 
						LET l_rec_invoicehead.mobile_phone = NULL
						LET l_rec_invoicehead.email = NULL
						LET l_rec_invoicehead.invoice_to_ind = 
						l_rec_customer.invoice_to_ind 
						LET l_rec_invoicehead.territory_code = 
						l_rec_customer.territory_code 
						LET l_rec_invoicehead.cond_code = l_rec_customer.cond_code 
						LET l_rec_invoicehead.scheme_amt = 0 
						LET l_rec_invoicehead.jour_num = NULL 
						LET l_rec_invoicehead.post_date = NULL 
						LET l_rec_invoicehead.carrier_code = NULL 
						LET l_rec_invoicehead.manifest_num = NULL 
						LET l_rec_invoicehead.stat_date = NULL 
						SELECT mgr_code INTO l_rec_invoicehead.mgr_code 
						FROM salesperson 
						WHERE cmpy_code = l_rec_invoicehead.cmpy_code 
						AND sale_code = l_rec_customer.sale_code 
						SELECT area_code INTO l_rec_invoicehead.area_code 
						FROM territory 
						WHERE cmpy_code = l_rec_invoicehead.cmpy_code 
						AND terr_code = l_rec_customer.territory_code 
						CALL get_fiscal_year_period_for_date( l_rec_invoicehead.cmpy_code, 
						l_rec_invoicehead.inv_date ) 
						RETURNING l_rec_invoicehead.year_num, 
						l_rec_invoicehead.period_num 
						IF l_rec_invoicehead.year_num IS NULL 
						OR l_rec_invoicehead.period_num IS NULL THEN 
							LET modu_err_cnt = modu_err_cnt + 1 
							LET modu_err_message = 
							"Fiscal Year/Period NOT SET up ", 
							"at glob_rec_kandoouser.cmpy_code: ", l_rec_invoicehead.cmpy_code," ", 
							"FOR Inv. Date:",l_rec_invoicehead.inv_date 
							USING "dd/mm/yy" 
							#---------------------------------------------------------
							OUTPUT TO REPORT ASI_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASI_J_rpt_list_exception"),
							l_process_grp, 
							l_cust_code , 
							l_inv_num , 
							modu_err_message ) 
							#---------------------------------------------------------							

							ROLLBACK WORK 
							CONTINUE FOREACH 
						END IF 
						
						LET l_rec_invoicehead.due_date = l_rec_jmj_invdetl.expdrs_due_date
						
						CALL db_term_get_rec(UI_OFF,l_rec_invoicehead.term_code) RETURNING l_rec_term.*
						IF sqlca.sqlcode = 0 THEN 
							CALL get_due_and_discount_date( l_rec_term.*, l_rec_invoicehead.inv_date ) 
							RETURNING l_invoicehead_due_date, 
							l_invoicehead_disc_date 
						ELSE 
							LET modu_err_cnt = modu_err_cnt + 1 
							LET modu_err_message = "Term code: ",l_rec_invoicehead.term_code,	" NOT SET up AT glob_rec_kandoouser.cmpy_code: ",	l_rec_invoicehead.cmpy_code 
							#---------------------------------------------------------
							OUTPUT TO REPORT ASI_J_rpt_list_exception(
								rpt_rmsreps_idx_get_idx("ASI_J_rpt_list_exception"),
								l_process_grp, 
								l_cust_code , 
								l_inv_num , 
								modu_err_message ) 
							#---------------------------------------------------------								

						END IF 
						IF l_rec_jmj_invdetl.expdrs_due_date IS NULL THEN 
							LET l_rec_invoicehead.due_date = l_invoicehead_due_date 
						ELSE 
							LET l_rec_invoicehead.due_date = l_rec_jmj_invdetl.expdrs_due_date 
						END IF 
						LET l_rec_invoicehead.disc_date = l_rec_invoicehead.inv_date 
						LET l_setup_head_ind = true 
					END IF 
					#
					# Invoicedetl
					#
					INITIALIZE l_rec_invoicedetl.* TO NULL 
					LET l_rec_invoicehead.line_num = l_rec_invoicehead.line_num + 1 
					LET l_rec_invoicedetl.cmpy_code = l_rec_invoicehead.cmpy_code 
					LET l_rec_invoicedetl.cust_code = l_rec_invoicehead.cust_code 
					LET l_rec_invoicedetl.inv_num = l_rec_invoicehead.inv_num 
					LET l_rec_invoicedetl.line_num = l_rec_invoicehead.line_num 
					LET l_rec_invoicedetl.part_code = NULL 
					LET l_rec_invoicedetl.ware_code = NULL 
					LET l_rec_invoicedetl.cat_code = l_rec_jmj_invdetl.expdrs_trans_type 
					LET l_rec_invoicedetl.ord_qty = 0 
					LET l_rec_invoicedetl.ship_qty = 1 
					LET l_rec_invoicedetl.prev_qty = 0 
					LET l_rec_invoicedetl.back_qty = 0 
					LET l_rec_invoicedetl.ser_flag = 'N' 
					LET l_rec_invoicedetl.ser_qty = 0 
					LET l_rec_invoicedetl.line_text = l_s_cust_code clipped, 
					' ', 
					l_rec_jmj_invdetl.expdrs_name 
					#
					# Acct. Masking : CUSTOMERTYPE
					#
					OPEN c_custtype USING l_rec_invoicedetl.cmpy_code, 
					l_rec_invoicedetl.cust_code 
					FETCH c_custtype INTO l_mask_code 
					IF status = 0 THEN 
						LET l_rec_invoicedetl.line_acct_code = 
						build_mask( l_rec_invoicedetl.cmpy_code, 
						l_rec_invoicedetl.line_acct_code, 
						l_mask_code ) 
					END IF 
					LET l_rec_invoicedetl.line_acct_code = 
					build_mask( l_rec_invoicedetl.cmpy_code, 
					l_rec_invoicedetl.line_acct_code, 
					l_line_acct_code ) 
					CALL ASI_J_verify_acct( l_rec_invoicehead.cmpy_code, 
					l_rec_invoicedetl.line_acct_code, 
					l_rec_invoicehead.year_num, 
					l_rec_invoicehead.period_num ) 
					RETURNING l_acct_text 
					IF l_acct_text != l_rec_invoicedetl.line_acct_code THEN 
						LET modu_err_cnt = modu_err_cnt + 1 
						LET modu_err_message = l_acct_text 
							#---------------------------------------------------------
							OUTPUT TO REPORT ASI_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASI_J_rpt_list_exception"),
							l_process_grp, 
							l_cust_code , 
							l_inv_num , 
							modu_err_message ) 
							#---------------------------------------------------------									

						ROLLBACK WORK 
						CONTINUE FOREACH 
					END IF 
					IF NOT acct_type(l_rec_invoicehead.cmpy_code, l_rec_invoicedetl.line_acct_code, COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"N") THEN 
						LET modu_err_cnt = modu_err_cnt + 1 
						LET modu_err_message = "Transaction Account: ", 
						l_rec_invoicedetl.line_acct_code," cannot be ", 
						"control OR bank account." 
						#---------------------------------------------------------
						OUTPUT TO REPORT ASI_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASI_J_rpt_list_exception"),
						l_process_grp, 
						l_cust_code , 
						l_inv_num , 
						modu_err_message ) 
						#---------------------------------------------------------							
 
						ROLLBACK WORK 
						CONTINUE FOREACH 
					END IF 
					LET l_rec_invoicedetl.uom_code = NULL 
					LET l_rec_invoicedetl.unit_cost_amt = 0 
					LET l_rec_invoicedetl.ext_cost_amt = 0 
					LET l_rec_invoicedetl.disc_amt = 0 
					LET l_rec_invoicedetl.disc_per = 0 
					LET l_rec_invoicedetl.unit_sale_amt = l_rec_jmj_invdetl.expdrs_amount 
					LET l_rec_invoicedetl.ext_sale_amt = l_rec_jmj_invdetl.expdrs_amount 
					LET l_rec_invoicedetl.unit_tax_amt = 0 
					LET l_rec_invoicedetl.ext_tax_amt = 0 
					LET l_rec_invoicedetl.line_total_amt = l_rec_jmj_invdetl.expdrs_amount 
					LET l_rec_invoicedetl.seq_num = NULL 
					LET l_rec_invoicedetl.level_code = 'L' 
					LET l_rec_invoicedetl.comm_amt = 0 
					LET l_rec_invoicedetl.comp_per = NULL 
					LET l_rec_invoicedetl.tax_code = l_rec_customer.tax_code 
					LET l_rec_invoicedetl.order_line_num = NULL 
					LET l_rec_invoicedetl.order_num = NULL 
					LET l_rec_invoicedetl.offer_code = NULL 
					LET l_rec_invoicedetl.sold_qty = NULL 
					LET l_rec_invoicedetl.bonus_qty = NULL 
					LET l_rec_invoicedetl.ext_bonus_amt = NULL 
					LET l_rec_invoicedetl.ext_stats_amt = NULL 
					LET l_rec_invoicedetl.list_price_amt = 0 
					#
					# Invoicedetl INSERT
					#
					LET modu_err_message = "ASI - Error inserting Invoice detail" 

					#INSERT invoiceDetl Record
					IF db_invoicedetl_rec_validation(UI_ON,MODE_INSERT,l_rec_invoicedetl.*) THEN
						INSERT INTO invoicedetl VALUES (l_rec_invoicedetl.*)		
					ELSE
						DISPLAY l_rec_invoicedetl.*
						CALL fgl_winmessage("Error","Could not insert new invoiceDetl record","ERROR")
					END IF 

					#
					LET l_rec_invoicehead.cost_amt = l_rec_invoicehead.cost_amt 
					+ l_rec_invoicedetl.ext_cost_amt 
					LET l_rec_invoicehead.goods_amt = l_rec_invoicehead.goods_amt 
					+ l_rec_invoicedetl.ext_sale_amt 
					LET l_rec_invoicehead.tax_amt = l_rec_invoicehead.tax_amt 
					+ l_rec_invoicedetl.ext_tax_amt 
				END WHILE 
				#
				# Araudit / Customer dependent upon Invoicehead
				#
				LET l_rec_invoicehead.total_amt = l_rec_invoicehead.goods_amt	+ l_rec_invoicehead.tax_amt 
				LET modu_err_message = 
					"ASI - Error inserting Invoice:", 
					l_rec_invoicehead.inv_num, " ", 
					"FOR Customer: ", l_cust_code," ", 
					"at glob_rec_kandoouser.cmpy_code: ", l_cmpy_code 

				#INSERT invoicehead Record
				IF db_invoicehead_rec_validation(UI_ON,MODE_INSERT,l_rec_invoicehead.*) THEN
					INSERT INTO invoicehead VALUES (l_rec_invoicehead.*)			
				ELSE
					DISPLAY l_rec_invoicehead.*
					CALL fgl_winmessage("Error","Could not insert new invoicehead record","ERROR")
				END IF 

				#-------------------------------------------------------
				# Araudit
				#
				INITIALIZE l_rec_araudit.* TO NULL
				 
				LET l_rec_araudit.cmpy_code = l_rec_invoicehead.cmpy_code 
				LET l_rec_araudit.tran_date = l_rec_invoicehead.inv_date 
				LET l_rec_araudit.cust_code = l_rec_invoicehead.cust_code 
				LET l_rec_araudit.seq_num = l_rec_customer.next_seq_num + 1 
				LET l_rec_araudit.tran_type_ind = 'IN' 
				LET l_rec_araudit.source_num = l_rec_invoicehead.inv_num 
				LET l_rec_araudit.tran_text = 'jmj invoice' 
				LET l_rec_araudit.tran_amt = l_rec_invoicehead.total_amt 
				LET l_rec_araudit.entry_code = l_rec_invoicehead.entry_code 
				LET l_rec_araudit.sales_code = l_rec_invoicehead.sale_code 
				LET l_rec_araudit.bal_amt = l_rec_customer.bal_amt 
				+ l_rec_invoicehead.total_amt 
				LET l_rec_araudit.year_num = l_rec_invoicehead.year_num 
				LET l_rec_araudit.period_num = l_rec_invoicehead.period_num 
				LET l_rec_araudit.currency_code = l_rec_invoicehead.currency_code 
				LET l_rec_araudit.conv_qty = l_rec_invoicehead.conv_qty 
				LET l_rec_araudit.entry_date = l_rec_invoicehead.entry_date 
				LET modu_err_message = "ASI - Error inserting AR audit entry " , 
				"FOR Customer: ", l_cust_code," ", 
				"at glob_rec_kandoouser.cmpy_code: ", l_cmpy_code 
				INSERT INTO araudit VALUES (l_rec_araudit.*) 
				#
				# Update customer details
				#
				LET l_rec_customer.curr_amt = l_rec_customer.curr_amt 
				+ l_rec_invoicehead.total_amt 
				LET l_rec_customer.next_seq_num = l_rec_customer.next_seq_num + 1 
				LET l_rec_customer.bal_amt = l_rec_customer.bal_amt 
				+ l_rec_invoicehead.total_amt 
				LET l_rec_customer.cred_bal_amt = l_rec_customer.cred_limit_amt 
				- l_rec_customer.bal_amt 
				IF l_rec_customer.bal_amt > l_rec_customer.highest_bal_amt THEN 
					LET l_rec_customer.highest_bal_amt = l_rec_customer.bal_amt 
				END IF 
				IF year( l_rec_invoicehead.inv_date ) 
				> year( l_rec_customer.last_inv_date ) THEN 
					LET l_rec_customer.ytds_amt = 0 
					LET l_rec_customer.mtds_amt = 0 
				END IF 
				IF month( l_rec_invoicehead.inv_date ) 
				> month( l_rec_customer.last_inv_date ) THEN 
					LET l_rec_customer.mtds_amt = 0 
				END IF 
				LET l_rec_customer.ytds_amt = l_rec_customer.ytds_amt 
				+ l_rec_invoicehead.total_amt 
				LET l_rec_customer.mtds_amt = l_rec_customer.mtds_amt 
				+ l_rec_invoicehead.total_amt 
				LET l_rec_customer.last_inv_date = l_rec_invoicehead.inv_date 
				LET modu_err_message = "ASI - Error updating Customer: ",l_cust_code, 
				"at glob_rec_kandoouser.cmpy_code: ", l_cmpy_code 
				UPDATE customer 
				SET next_seq_num = l_rec_customer.next_seq_num, 
				bal_amt = l_rec_customer.bal_amt, 
				curr_amt = l_rec_customer.curr_amt, 
				highest_bal_amt = l_rec_customer.highest_bal_amt, 
				cred_bal_amt = l_rec_customer.cred_bal_amt, 
				last_inv_date = l_rec_customer.last_inv_date, 
				ytds_amt = l_rec_customer.ytds_amt, 
				mtds_amt = l_rec_customer.mtds_amt 
				WHERE cmpy_code = l_cmpy_code 
				AND cust_code = l_cust_code 
				OUTPUT TO REPORT ASI_J_rpt_list( l_rec_invoicehead.cmpy_code, 
				l_s_cust_code, 
				l_rec_invoicehead.cust_code, 
				l_rec_invoicehead.org_cust_code, 
				l_rec_invoicehead.inv_num, 
				l_rec_invoicehead.inv_date, 
				l_rec_invoicehead.line_num, 
				l_rec_invoicehead.total_amt, 
				'l_i' ) 
				#
				# Delete JMJ invoice / credit FROM holding table
				#
				DELETE FROM jmj_invoicedetail 
				WHERE expdrs_process_grp = l_process_grp 
				AND expdrs_client = l_s_cust_code 
				AND expdrs_invoice_no = l_inv_num 
				AND expdrs_date = l_date 
				AND expdrs_record_type!= 'C' 
				AND expdrs_imprest != 'W' 
				AND expdrs_amount >= 0 
			COMMIT WORK 
			WHENEVER ERROR stop 
			WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
			LET modu_kandoo_ar_cnt = modu_kandoo_ar_cnt + 1 
			LET modu_kandoo_in_cnt = modu_kandoo_in_cnt + 1 
			IF modu_verbose_ind THEN 
				DISPLAY modu_kandoo_ar_cnt TO kandoo_ar_cnt  

			END IF 
		END FOREACH 
		
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			RETURN 
		END IF 
		#
		#
		# Create AR Credits
		#
		#
		DECLARE c2_jmjinvdetl CURSOR with HOLD FOR 
		SELECT unique expdrs_process_grp, 
		expdrs_client, 
		expdrs_invoice_no, 
		expdrs_date 
		FROM jmj_invoicedetail 
		WHERE expdrs_record_type != 'C' 
		AND expdrs_imprest != 'W' 
		AND expdrs_record_type IS NOT NULL 
		AND expdrs_record_type != ' ' 
		AND expdrs_imprest IS NOT NULL 
		AND expdrs_imprest != ' ' 
		AND expdrs_client IS NOT NULL 
		AND expdrs_invoice_no IS NOT NULL 
		AND expdrs_date IS NOT NULL 
		AND expdrs_process_grp IS NOT NULL 
		AND expdrs_trans_type IS NOT NULL 
		AND expdrs_amount IS NOT NULL 
		AND expdrs_client != ' ' 
		AND expdrs_amount < 0 
		ORDER BY 1, 2, 3, 4 
		FOREACH c2_jmjinvdetl INTO l_process_grp, 
			l_s_cust_code, 
			l_inv_num, 
			l_date 
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
			LET l_ar_cnt = l_ar_cnt + 1 
			LET l_ar_per = ( l_ar_cnt / modu_jmj_ar_cnt ) * 100 
			IF modu_verbose_ind THEN 
				DISPLAY l_ar_per  TO ar_per
				DISPLAY l_ar_cnt  TO ar_cnt

			END IF 
			#
			#
			#
			IF retry_lock(glob_rec_kandoouser.cmpy_code,0) THEN END IF 
				GOTO bypass1 
				LABEL recovery1: 
				IF retry_lock(glob_rec_kandoouser.cmpy_code,status) > 0 THEN 
					ROLLBACK WORK 
				ELSE 
					IF modu_verbose_ind THEN 
						IF error_recover(modu_err_message,status) != 'Y' THEN 
							LET modu_err2_cnt = modu_err2_cnt + 1 
							#---------------------------------------------------------
							OUTPUT TO REPORT ASI_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASI_J_rpt_list_exception"),
							l_process_grp, 
							l_s_cust_code , 
							l_inv_num , 
							modu_err_message ) 
							#---------------------------------------------------------								

							CONTINUE FOREACH 
						END IF 
					ELSE 
						LET modu_err2_cnt = modu_err2_cnt + 1
						#---------------------------------------------------------
						OUTPUT TO REPORT ASI_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASI_J_rpt_list_exception"),
						l_process_grp, 
						l_s_cust_code , 
						l_inv_num , 
						modu_err_message ) 
						#---------------------------------------------------------								
						LET modu_err_text = "ASI_J - ",err_get(STATUS) 
						CALL errorlog( modu_err_text ) 
						ROLLBACK WORK 
						CONTINUE FOREACH 
					END IF 
				END IF 
				LABEL bypass1: 
				WHENEVER ERROR GOTO recovery1 
				BEGIN WORK 
					INITIALIZE l_rec_customer.* TO NULL 
					#
					# Indicate that header needs TO be setup
					#
					LET l_setup_head_ind = false 
					#
					DECLARE c2_invdetl CURSOR FOR 
					SELECT * FROM jmj_invoicedetail 
					WHERE expdrs_process_grp = l_process_grp 
					AND expdrs_client = l_s_cust_code 
					AND expdrs_invoice_no = l_inv_num 
					AND expdrs_date = l_date 
					AND expdrs_record_type!= 'C' 
					AND expdrs_imprest != 'W' 
					AND expdrs_amount < 0 
					OPEN c2_invdetl 
					WHILE true 
						FETCH c2_invdetl INTO l_rec_jmj_invdetl.* 
						IF sqlca.sqlcode = NOTFOUND THEN 
							EXIT WHILE 
						END IF 
						IF NOT l_setup_head_ind THEN 
							#
							# Retrieve glob_rec_kandoouser.cmpy_code
							#
							IF l_rec_jmj_invdetl.expdrs_process_grp >= 20 
							AND l_rec_jmj_invdetl.expdrs_process_grp <= 29 THEN 
								LET l_cmpy_code = modu_auto_cmpy_code 
							ELSE 
								LET l_cmpy_code = modu_jmj_cmpy_code 
							END IF 
							#
							# Retrieve customer
							#
							CASE 
								WHEN length( l_s_cust_code ) = 0 
									LET modu_err_cnt = modu_err_cnt + 1 
									LET modu_err_message = "No customer code specified ", 
									"at glob_rec_kandoouser.cmpy_code: ",l_cmpy_code 
									#---------------------------------------------------------
									OUTPUT TO REPORT ASI_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASI_J_rpt_list_exception"),
									l_process_grp, 
									l_s_cust_code , 
									l_inv_num , 
									modu_err_message ) 
									#---------------------------------------------------------								
									
									ROLLBACK WORK 
									CONTINUE FOREACH 
								WHEN length( l_s_cust_code ) > 5 
									#
									# Retrieve 'TRUE' debtor code
									#
									SELECT cust_code INTO l_cust_code 
									FROM jmj_truedebtor 
									WHERE cmpy_code = l_cmpy_code 
									AND client_code = l_s_cust_code 
									IF sqlca.sqlcode = NOTFOUND THEN 
										LET modu_err_cnt = modu_err_cnt + 1 
										LET modu_err_message = 
										"TRUE debtor code NOT SET up FOR primary debtor", 
										" AT glob_rec_kandoouser.cmpy_code:", l_cmpy_code 
										#---------------------------------------------------------
										OUTPUT TO REPORT ASI_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASI_J_rpt_list_exception"),
										l_process_grp, 
										l_s_cust_code , 
										l_inv_num , 
										modu_err_message ) 
										#---------------------------------------------------------												
 
										ROLLBACK WORK 
										CONTINUE FOREACH 
									END IF 
								OTHERWISE 
									LET l_cust_code = l_s_cust_code 
							END CASE 
							OPEN c1_customer USING l_cmpy_code, 
							l_cust_code 
							FETCH c1_customer INTO l_rec_customer.* 
							IF sqlca.sqlcode = NOTFOUND THEN 
								#
								# all related detail lines will be skipped
								#
								IF modu_verbose_ind THEN 
									#
									# Hide previous descriptions
									#
									DISPLAY l_rec_customer.name_text TO name_text

								END IF 
								LET modu_err_cnt = modu_err_cnt + 1 
								LET modu_err_message = "Customer code NOT SET up ", 
								"at glob_rec_kandoouser.cmpy_code: ",l_cmpy_code 
								#---------------------------------------------------------
								OUTPUT TO REPORT ASI_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASI_J_rpt_list_exception"),
								l_process_grp, 
								l_s_cust_code , 
								l_inv_num , 
								modu_err_message ) 
								#---------------------------------------------------------										

								ROLLBACK WORK 
								CONTINUE FOREACH 
							END IF 
							IF modu_verbose_ind THEN 
								DISPLAY l_rec_customer.cust_code TO cust_code
								DISPLAY l_rec_customer.name_text TO name_text

							END IF 
							#
							# Set up Credithead
							#
							INITIALIZE l_rec_credithead.* TO NULL 
							LET l_rec_credithead.cmpy_code = l_cmpy_code 
							LET l_rec_credithead.cust_code = l_cust_code 
							LET l_rec_credithead.org_cust_code = l_rec_customer.corp_cust_code 
							IF l_rec_credithead.org_cust_code IS NOT NULL THEN 
								SELECT unique 1 FROM customer 
								WHERE cmpy_code = l_rec_credithead.cmpy_code 
								AND cust_code = l_rec_credithead.org_cust_code 
								IF sqlca.sqlcode = 0 THEN 
									LET l_rec_credithead.org_cust_code = 
									l_rec_credithead.cust_code 
									LET l_rec_credithead.cust_code = 
									l_rec_customer.corp_cust_code 
								END IF 
							END IF 
							LET l_rec_credithead.acct_override_code = NULL 
							#
							# Acct. Masking : CUSTOMERTYPE
							#
							OPEN c_custtype USING l_rec_credithead.cmpy_code, 
							l_rec_credithead.cust_code 
							FETCH c_custtype INTO l_mask_code 
							IF status = 0 THEN 
								LET l_rec_credithead.acct_override_code = 
								build_mask( l_rec_credithead.cmpy_code, 
								l_rec_credithead.acct_override_code, 
								l_mask_code ) 
							END IF 
							IF l_inv_num <= 999999 THEN 
								LET l_inv_text = l_inv_num USING "&&&&&&", "00" 
								LET l_rec_credithead.cred_num = l_inv_text 
								LET l_s_trans_num = next_tran_num( 'C', 
								l_cmpy_code, 
								l_rec_credithead.cred_num ) 
							ELSE 
								IF l_inv_num > 999999 THEN 
									SELECT unique 1 FROM credithead 
									WHERE cred_num = l_inv_num 
									AND cmpy_code = l_cmpy_code 
									IF status != NOTFOUND THEN 
										LET l_s_trans_num = NULL 
									ELSE 
										LET l_rec_credithead.cred_num = l_inv_text 
										LET l_s_trans_num = l_inv_num 
									END IF 
								END IF 
							END IF 
							CASE 
								WHEN l_s_trans_num IS NULL 
									#
									# Cannot retrieve a credit no.
									#
									LET modu_err_cnt = modu_err_cnt + 1 
									LET modu_err_message = 
									"Error generating credit number FOR ", 
									"JMJ Credit AT glob_rec_kandoouser.cmpy_code: ",l_cmpy_code 
									#---------------------------------------------------------
									OUTPUT TO REPORT ASI_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASI_J_rpt_list_exception"),
									l_process_grp, 
									l_s_cust_code , 
									l_inv_num , 
									modu_err_message ) 
									#---------------------------------------------------------											

									ROLLBACK WORK 
									CONTINUE FOREACH 
								WHEN l_s_trans_num != l_rec_credithead.cred_num 
									#
									# Exception
									#
									LET modu_err_message = 
									"JMJ Credit No.: ",l_rec_credithead.cred_num 
									USING "<<<<<<<<"," ", 
									"mapped TO Invoice No.: ",l_s_trans_num 
									USING "<<<<<<<<" 
									#---------------------------------------------------------
									OUTPUT TO REPORT ASI_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASI_J_rpt_list_exception"),
									l_process_grp, 
									l_s_cust_code , 
									l_inv_num , 
									modu_err_message ) 
									#---------------------------------------------------------											

							END CASE 
							LET l_rec_credithead.cred_num = l_s_trans_num 
							#
							# Transaction Type Translation Table
							#
							SELECT desc_text, 
							cr_acct_code, 
							debt_type_code 
							INTO l_line_text, 
							l_line_acct_code, 
							l_rec_credithead.cred_text 
							FROM jmj_trantype 
							WHERE cmpy_code = l_rec_credithead.cmpy_code 
							AND trans_code = l_rec_jmj_invdetl.expdrs_trans_type 
							AND record_ind = l_rec_jmj_invdetl.expdrs_record_type 
							AND imprest_ind = l_rec_jmj_invdetl.expdrs_imprest 
							IF sqlca.sqlcode = NOTFOUND THEN 
								LET modu_err_cnt = modu_err_cnt + 1 
								LET modu_err_message = 
								"No entry in VMS Trans. table FOR ", 
								"Trans. :",l_rec_jmj_invdetl.expdrs_trans_type USING "&&", 
								" RECORD Ind. :",l_rec_jmj_invdetl.expdrs_record_type, 
								" Imprest Ind.:",l_rec_jmj_invdetl.expdrs_imprest, 
								" glob_rec_kandoouser.cmpy_code.:",l_rec_credithead.cmpy_code
								#---------------------------------------------------------
								OUTPUT TO REPORT ASI_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASI_J_rpt_list_exception"),
								l_process_grp, 
								l_s_cust_code , 
								l_inv_num , 
								modu_err_message ) 
								#---------------------------------------------------------		
							 
								ROLLBACK WORK 
								CONTINUE FOREACH 
							END IF 
							LET l_rec_credithead.cred_date = l_rec_jmj_invdetl.expdrs_date 
							LET l_rec_credithead.rma_num = 0 
							LET l_rec_credithead.job_code = NULL 
							LET l_rec_credithead.entry_code = glob_rec_kandoouser.sign_on_code 
							LET l_rec_credithead.entry_date = today 
							LET l_rec_credithead.cred_ind = 'X' 
							LET l_rec_credithead.sale_code = l_rec_customer.sale_code 
							LET l_rec_credithead.tax_code = l_rec_customer.tax_code 
							LET l_rec_credithead.tax_per = 0 
							LET l_rec_credithead.cost_amt = 0 
							LET l_rec_credithead.goods_amt = 0 
							LET l_rec_credithead.tax_amt = 0 
							LET l_rec_credithead.hand_amt = 0 
							LET l_rec_credithead.hand_tax_code = l_rec_customer.tax_code 
							LET l_rec_credithead.hand_tax_amt = 0 
							LET l_rec_credithead.freight_amt = 0 
							LET l_rec_credithead.freight_tax_code = l_rec_customer.tax_code 
							LET l_rec_credithead.freight_tax_amt = 0 
							LET l_rec_credithead.appl_amt = 0 
							LET l_rec_credithead.disc_amt = 0 
							LET l_rec_credithead.posted_flag = 'N' 
							LET l_rec_credithead.on_state_flag = 'N' 
							LET l_rec_credithead.next_num = 0 
							LET l_rec_credithead.line_num = 0 
							LET l_rec_credithead.com1_text = NULL 
							LET l_rec_credithead.com2_text = NULL 
							LET l_rec_credithead.rev_date = NULL 
							LET l_rec_credithead.rev_num = NULL 
							LET l_rec_credithead.cost_ind = NULL 
							LET l_rec_credithead.currency_code = 'AUD' 
							LET l_rec_credithead.conv_qty = 1 
							LET l_rec_credithead.price_tax_flag = NULL 
							LET l_rec_credithead.printed_num = 0 
							LET l_rec_credithead.reason_code = NULL 
							LET l_rec_credithead.jour_num = NULL 
							LET l_rec_credithead.post_date = NULL 
							LET l_rec_credithead.stat_date = NULL 
							LET l_rec_credithead.address_to_ind = NULL 
							LET l_rec_credithead.cond_code = NULL 
							CALL get_fiscal_year_period_for_date( l_rec_credithead.cmpy_code, 
							l_rec_credithead.cred_date ) 
							RETURNING l_rec_credithead.year_num, 
							l_rec_credithead.period_num 
							IF l_rec_credithead.year_num IS NULL 
							OR l_rec_credithead.period_num IS NULL THEN 
								LET modu_err_cnt = modu_err_cnt + 1 
								LET modu_err_message = 
								"Fiscal Year/Period NOT SET up ", 
								"at glob_rec_kandoouser.cmpy_code: ", l_rec_credithead.cmpy_code," ", 
								"FOR Cred. Date:",l_rec_credithead.cred_date 
								USING "dd/mm/yy" 
								#---------------------------------------------------------
								OUTPUT TO REPORT ASI_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASI_J_rpt_list_exception"),
								l_process_grp, 
								l_s_cust_code , 
								l_inv_num , 
								modu_err_message ) 
								#---------------------------------------------------------		
								
								ROLLBACK WORK 
								CONTINUE FOREACH 
							END IF 
							SELECT mgr_code INTO l_rec_credithead.mgr_code 
							FROM salesperson 
							WHERE cmpy_code = l_rec_credithead.cmpy_code 
							AND sale_code = l_rec_customer.sale_code 
							SELECT area_code INTO l_rec_credithead.area_code 
							FROM territory 
							WHERE cmpy_code = l_rec_credithead.cmpy_code 
							AND terr_code = l_rec_customer.territory_code 
							#
							#
							#
							LET l_setup_head_ind = true 
						END IF 
						#
						# Creditdetl
						#
						INITIALIZE l_rec_creditdetl.* TO NULL 
						LET l_rec_credithead.line_num = l_rec_credithead.line_num + 1 
						LET l_rec_creditdetl.cmpy_code = l_rec_credithead.cmpy_code 
						LET l_rec_creditdetl.cust_code = l_rec_credithead.cust_code 
						LET l_rec_creditdetl.cred_num = l_rec_credithead.cred_num 
						LET l_rec_creditdetl.line_num = l_rec_credithead.line_num 
						LET l_rec_creditdetl.line_text = l_s_cust_code clipped, 
						' ', 
						l_rec_jmj_invdetl.expdrs_name 
						LET l_rec_creditdetl.part_code = NULL 
						LET l_rec_creditdetl.ware_code = NULL 
						LET l_rec_creditdetl.cat_code = l_rec_jmj_invdetl.expdrs_trans_type 
						LET l_rec_creditdetl.ship_qty = 1 
						LET l_rec_creditdetl.ser_ind = 'N' 
						#
						# Acct. Masking : CUSTOMERTYPE
						#
						OPEN c_custtype USING l_rec_creditdetl.cmpy_code, 
						l_rec_creditdetl.cust_code 
						FETCH c_custtype INTO l_mask_code 
						IF status = 0 THEN 
							LET l_rec_creditdetl.line_acct_code = 
							build_mask( l_rec_credithead.cmpy_code, 
							l_rec_creditdetl.line_acct_code, 
							l_mask_code ) 
						END IF 
						LET l_rec_creditdetl.line_acct_code = 
						build_mask( l_rec_credithead.cmpy_code, 
						l_rec_creditdetl.line_acct_code, 
						l_line_acct_code ) 
						CALL ASI_J_verify_acct( l_rec_credithead.cmpy_code, 
						l_rec_creditdetl.line_acct_code, 
						l_rec_credithead.year_num, 
						l_rec_credithead.period_num ) 
						RETURNING l_acct_text 
						IF l_acct_text != l_rec_creditdetl.line_acct_code THEN 
							LET modu_err_cnt = modu_err_cnt + 1 
							LET modu_err_message = l_acct_text 
							#---------------------------------------------------------
							OUTPUT TO REPORT ASI_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASI_J_rpt_list_exception"),
							l_process_grp, 
							l_s_cust_code , 
							l_inv_num , 
							modu_err_message ) 
							#---------------------------------------------------------								
							ROLLBACK WORK 
							CONTINUE FOREACH 
						END IF 
						IF NOT acct_type(l_rec_credithead.cmpy_code, l_rec_creditdetl.line_acct_code, COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"N") THEN 
							LET modu_err_cnt = modu_err_cnt + 1 
							LET modu_err_message = "Transaction Account: ", 
							l_rec_creditdetl.line_acct_code," cannot be ", 
							"control OR bank account." 
							#---------------------------------------------------------
							OUTPUT TO REPORT ASI_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASI_J_rpt_list_exception"),
							l_process_grp, 
							l_s_cust_code , 
							l_inv_num , 
							modu_err_message ) 
							#---------------------------------------------------------									
							ROLLBACK WORK 
							CONTINUE FOREACH 
						END IF 
						LET l_rec_creditdetl.uom_code = NULL 
						LET l_rec_creditdetl.unit_cost_amt = 0 
						LET l_rec_creditdetl.ext_cost_amt = 0 
						LET l_rec_creditdetl.disc_amt = 0 
						LET l_rec_creditdetl.unit_sales_amt = 0 
						- l_rec_jmj_invdetl.expdrs_amount 
						LET l_rec_creditdetl.ext_sales_amt = 0 
						- l_rec_jmj_invdetl.expdrs_amount 
						LET l_rec_creditdetl.unit_tax_amt = 0 
						LET l_rec_creditdetl.ext_tax_amt = 0 
						LET l_rec_creditdetl.line_total_amt = 0 
						- l_rec_jmj_invdetl.expdrs_amount 
						LET l_rec_creditdetl.seq_num = NULL 
						LET l_rec_creditdetl.job_code = NULL 
						LET l_rec_creditdetl.level_code = 'L' 
						LET l_rec_creditdetl.comm_amt = 0 
						LET l_rec_creditdetl.tax_code = l_rec_customer.tax_code 
						LET l_rec_creditdetl.reason_code = NULL 
						LET l_rec_creditdetl.received_qty = l_rec_creditdetl.ship_qty 
						LET l_rec_creditdetl.invoice_num = 0 
						LET l_rec_creditdetl.inv_line_num = 0 
						LET l_rec_creditdetl.price_uom_code = NULL 
						LET l_rec_creditdetl.km_qty = 0 
						#
						# Creditdetl INSERT
						#
						LET modu_err_message = "ASI - Error inserting Credit detail" 
						INSERT INTO creditdetl VALUES ( l_rec_creditdetl.* ) 
						#
						#
						#
						LET l_rec_credithead.goods_amt = l_rec_credithead.goods_amt 
						+ l_rec_creditdetl.ext_sales_amt 
						LET l_rec_credithead.cost_amt = l_rec_credithead.cost_amt 
						+ l_rec_creditdetl.ext_cost_amt 
						LET l_rec_credithead.tax_amt = l_rec_credithead.tax_amt 
						+ l_rec_creditdetl.ext_tax_amt 
					END WHILE 
					#
					# Araudit / Customer dependent upon Credithead
					#
					LET l_rec_credithead.total_amt = l_rec_credithead.goods_amt 
					+ l_rec_credithead.tax_amt 
					LET modu_err_message = "ASI - Error inserting Credit:", 
					l_rec_credithead.cred_num, " ", 
					"FOR Customer: ", l_cust_code," ", 
					"at glob_rec_kandoouser.cmpy_code: ", l_cmpy_code 
					INSERT INTO credithead VALUES ( l_rec_credithead.* ) 
					#
					# Araudit
					#
					INITIALIZE l_rec_araudit.* TO NULL 
					LET l_rec_araudit.cmpy_code = l_rec_credithead.cmpy_code 
					LET l_rec_araudit.tran_date = l_rec_credithead.cred_date 
					LET l_rec_araudit.cust_code = l_rec_credithead.cust_code 
					LET l_rec_araudit.seq_num = l_rec_customer.next_seq_num + 1 
					LET l_rec_araudit.tran_type_ind = 'CR' 
					LET l_rec_araudit.source_num = l_rec_credithead.cred_num 
					LET l_rec_araudit.tran_text = "JMJ Credit" 
					LET l_rec_araudit.tran_amt = 0 - l_rec_credithead.total_amt 
					LET l_rec_araudit.entry_code = l_rec_credithead.entry_code 
					LET l_rec_araudit.year_num = l_rec_credithead.year_num 
					LET l_rec_araudit.period_num = l_rec_credithead.period_num 
					LET l_rec_araudit.bal_amt = l_rec_customer.bal_amt 
					- l_rec_credithead.total_amt 
					LET l_rec_araudit.currency_code = l_rec_customer.currency_code 
					LET l_rec_araudit.conv_qty = l_rec_credithead.conv_qty 
					LET l_rec_araudit.entry_date = l_rec_credithead.entry_date 
					LET modu_err_message = "ASI - Error inserting AR audit entry " , 
					"FOR Customer: ", l_cust_code," ", 
					"at glob_rec_kandoouser.cmpy_code: ", l_cmpy_code 
					INSERT INTO araudit VALUES ( l_rec_araudit.* ) 
					#
					# Update customer details
					#
					LET l_rec_customer.next_seq_num = l_rec_customer.next_seq_num + 1 
					LET l_rec_customer.bal_amt = l_rec_customer.bal_amt 
					- l_rec_credithead.total_amt 
					LET l_rec_customer.cred_bal_amt = l_rec_customer.cred_limit_amt 
					- l_rec_customer.bal_amt 
					LET l_rec_customer.curr_amt = l_rec_customer.curr_amt 
					- l_rec_credithead.total_amt 
					LET l_rec_customer.ytds_amt = l_rec_customer.ytds_amt 
					- l_rec_credithead.total_amt 
					LET l_rec_customer.mtds_amt = l_rec_customer.mtds_amt 
					- l_rec_credithead.total_amt 
					IF l_rec_customer.bal_amt > l_rec_customer.highest_bal_amt THEN 
						LET l_rec_customer.highest_bal_amt = l_rec_customer.bal_amt 
					END IF 
					LET modu_err_message = "ASI - Error updating Customer: ",l_cust_code, 
					"at glob_rec_kandoouser.cmpy_code: ", l_cmpy_code 
					UPDATE customer 
					SET next_seq_num = l_rec_customer.next_seq_num, 
					bal_amt = l_rec_customer.bal_amt, 
					curr_amt = l_rec_customer.curr_amt, 
					highest_bal_amt = l_rec_customer.highest_bal_amt, 
					cred_bal_amt = l_rec_customer.cred_bal_amt, 
					last_inv_date = l_rec_customer.last_inv_date, 
					ytds_amt = l_rec_customer.ytds_amt, 
					mtds_amt = l_rec_customer.mtds_amt 
					WHERE cmpy_code = l_cmpy_code 
					AND cust_code = l_cust_code 

					#---------------------------------------------------------
					# OUTPUT FOR the ONLY real/positive report 
					#---------------------------------------------------------
					OUTPUT TO REPORT ASI_J_rpt_list(rpt_rmsreps_idx_get_idx("ASI_J_rpt_list"),
					l_rec_credithead.cmpy_code, 
					l_s_cust_code, 
					l_rec_credithead.cust_code, 
					l_rec_credithead.org_cust_code, 
					l_rec_credithead.cred_num, 
					l_rec_credithead.cred_date, 
					l_rec_credithead.line_num, 
					l_rec_credithead.total_amt, 
					'C' )
					#--------------------------------------------------------- 			
 				#
					# Delete JMJ credit FROM holding table
					#
					DELETE FROM jmj_invoicedetail 
					WHERE expdrs_process_grp = l_process_grp 
					AND expdrs_client = l_s_cust_code 
					AND expdrs_invoice_no = l_inv_num 
					AND expdrs_date = l_date 
					AND expdrs_record_type!= 'C' 
					AND expdrs_imprest != 'W' 
					AND expdrs_amount < 0 
				COMMIT WORK 
				WHENEVER ERROR stop 
				WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
				LET modu_kandoo_ar_cnt = modu_kandoo_ar_cnt + 1 
				LET modu_kandoo_cr_cnt = modu_kandoo_cr_cnt + 1 
				IF modu_verbose_ind THEN 
					DISPLAY modu_kandoo_ar_cnt TO kandoo_ar_cnt 
				END IF 
			END FOREACH 
END FUNCTION 



#########################################################################
# FUNCTION next_tran_num( p_tran_type, p_cmpy_code, p_cred_num )
#
# Refer " Duplicate AR Invoice Number Resolution "
#########################################################################
FUNCTION next_tran_num(p_tran_type, p_cmpy_code, p_cred_num) 
	DEFINE p_tran_type CHAR(1) 
	DEFINE p_cmpy_code LIKE credithead.cmpy_code 
	DEFINE p_cred_num LIKE credithead.cred_num 
	DEFINE l_s_cred_num LIKE credithead.cred_num 
	DEFINE l_num_text CHAR(8) 
	DEFINE l_i SMALLINT 
	DEFINE l_len SMALLINT 
	DEFINE l_prefix SMALLINT 
	DEFINE l_suffix SMALLINT 

	LET l_s_cred_num = p_cred_num 
	LET l_num_text = p_cred_num 
	LET l_len = length( l_num_text ) 
	#
	# Pad out number's less than 8 digits with '0'
	#
	IF l_len < 8 THEN 
		FOR l_i = 1 TO ( 8 - l_len ) 
			LET l_num_text[l_i,l_i] = '0' 
		END FOR 
		LET l_num_text[(8-l_len+1),8] = l_s_cred_num 
	END IF 
	LET l_prefix = l_num_text[1,1] 
	WHILE true 
		CASE p_tran_type 
			WHEN 'l_i' 
				SELECT 1 FROM invoicehead 
				WHERE inv_num = l_num_text 
				AND cmpy_code = p_cmpy_code 
				IF sqlca.sqlcode = NOTFOUND THEN 
					EXIT WHILE 
				END IF 
			WHEN 'C' 
				SELECT 1 FROM credithead 
				WHERE cred_num = l_num_text 
				AND cmpy_code = p_cmpy_code 
				IF sqlca.sqlcode = NOTFOUND THEN 
					EXIT WHILE 
				END IF 
		END CASE 
		LET l_suffix = l_num_text[7,8] 
		LET l_suffix = l_suffix + 1 
		CASE 
			WHEN l_suffix < 10 
				LET l_num_text[8,8] = l_suffix 
			WHEN l_suffix > 99 
				LET l_num_text = l_num_text[1,6] 
				LET l_prefix = l_prefix + 1 
				IF l_prefix > 9 THEN 
					LET l_prefix = 0 
				END IF 
				LET l_num_text[1,1] = l_prefix 
				LET l_num_text[7,8] = "00" 
			OTHERWISE 
				LET l_num_text[7,8] = l_suffix 
		END CASE 
		IF l_num_text = l_s_cred_num THEN 
			#
			# All possible numbering combinations have been exhausted
			#
			LET l_num_text = NULL 
		END IF 
	END WHILE 
	
	RETURN l_num_text 
END FUNCTION 


{
#########################################################################
# FUNCTION set1_defaults()
#
#
#########################################################################
FUNCTION set1_defaults() 

	LET glob_rec_kandooreport.header_text = "Invoice Detail Load - ", 
	today USING "dd/mm/yy" 
	CALL rpt_set_width(132) 
	CALL rpt_set_length(66) 
	LET glob_rec_kandooreport.menupath_text = "ASI" 
	LET glob_rec_kandooreport.selection_flag = "N" 
	LET glob_rec_kandooreport.line1_text = "Company", 2 spaces, 
	"Client Code", 2 spaces, 
	"Customer", 2 spaces, 
	"Corporate Debtor Code", 3 spaces, 
	"Transaction No.", 8 spaces, 
	"Date", 8 spaces, 
	"Total Lines", 9 spaces, 
	"Total Amount" 
	UPDATE kandooreport 
	SET * = glob_rec_kandooreport.* 
	WHERE report_code = glob_rec_kandooreport.report_code 
	AND language_code = glob_rec_kandooreport.language_code 
END FUNCTION 


#########################################################################
# FUNCTION set2_defaults()
#
#
#########################################################################
FUNCTION set2_defaults() 

	LET glob_rec_s_kandooreport.header_text = "Invoice Detail Exception Report - ", 
	today USING "dd/mm/yy" 
	LET glob_rec_s_kandooreport.width_num = 132 
	LET glob_rec_s_kandooreport.length_num = 66 
	LET glob_rec_s_kandooreport.menupath_text = "ASI" 
	LET glob_rec_s_kandooreport.selection_flag = "N" 
	LET glob_rec_s_kandooreport.line1_text = "Processing Group", 2 spaces, 
	"Client Code", 2 spaces, 
	"JMJ Inv.No", 2 spaces, 
	"Status" 
	UPDATE kandooreport 
	SET * = glob_rec_s_kandooreport.* 
	WHERE report_code = glob_rec_s_kandooreport.report_code 
	AND language_code = glob_rec_s_kandooreport.language_code 
END FUNCTION 
}

#########################################################################
# FUNCTION ASI_J_start_report()
#
# Set up Exception / Invoice Detail Load file
#########################################################################
FUNCTION ASI_J_start_report() 
	DEFINE l_rpt_idx SMALLINT

	#------------------------------------------------------------
	# Report for exceptions
	LET l_rpt_idx = rpt_start("ASI_J-ERROR","ASI_J_rpt_list_exception","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT ASI_J_rpt_list_exception TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ASI_J_rpt_list_exception")].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0

	#Report for success
	LET l_rpt_idx = rpt_start("ASI_J","ASI_J_rpt_list","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT ASI_J_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ASI_J_rpt_list")].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0
	#LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ASI_J_rpt_list")].sel_text
	#------------------------------------------------------------

--	START REPORT ASI_J_rpt_list TO glob_rec_rmsreps.file_text 
--	START REPORT ASI_J_rpt_list_exception TO modu_s_output

	#------------------------------------------------------------
		 
END FUNCTION 


#########################################################################
# FUNCTION ASI_J_finish_report()
#
#
#########################################################################
FUNCTION ASI_J_finish_report() 

	#------------------------------------------------------------
	# Actual (positive) report
	FINISH REPORT ASI_J_rpt_list
	CALL rpt_finish("ASI_J_rpt_list")
	#------------------------------------------------------------

	#------------------------------------------------------------
	# ERROR/Exception Report
	FINISH REPORT ASI_J_rpt_list_exception
	CALL rpt_finish("ASI_J_rpt_list_exception")
	#------------------------------------------------------------

END FUNCTION 


#########################################################################
# FUNCTION ASI_J_verify_acct(p_cmpy_code, p_account_code, p_year_num, p_period_num) 
#
#
#
# - FUNCTION ASI_J_verify_acct() IS a clone of vacctfunc.4gl
# - changes reqd. b/c need TO remove user interaction
# - returns STATUS ( ie. error OR acct_code )
#
#########################################################################
FUNCTION ASI_J_verify_acct(p_cmpy_code, p_account_code, p_year_num, p_period_num) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_account_code LIKE coa.acct_code 
	DEFINE p_year_num LIKE coa.start_year_num 
	DEFINE p_period_num LIKE coa.start_period_num 
	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_err_message CHAR(50) 

	SELECT * INTO l_rec_coa.* 
	FROM coa 
	WHERE cmpy_code = p_cmpy_code 
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


#########################################################################
# FUNCTION ASI_J_create_gl_entry()
#
#
#########################################################################
FUNCTION ASI_J_create_gl_entry() 
	DEFINE l_runner CHAR(100) 
	DEFINE l_arg_auto_company_code STRING 
	DEFINE l_arg_jmj_company_code STRING 
	DEFINE l_arg_verbose STRING 

	#
	# Invoke G27_J with modu_verbose_ind TO indicate user interaction ???huho we have no _J
	#

	LET l_arg_auto_company_code = "AUTO_COMPANY_CODE=", trim(modu_auto_cmpy_code) 
	LET l_arg_jmj_company_code = "JMJ_COMPANY_CODE=", trim(modu_jmj_cmpy_code) 
	LET l_arg_verbose = "VERBOSE=", trim(modu_verbose_ind) 


	CALL run_prog("G27",l_arg_verbose,l_arg_auto_company_code,l_arg_jmj_company_code,"") 
END FUNCTION 



#########################################################################
# FUNCTION ASI_J_rerun()
#
#
#########################################################################
FUNCTION ASI_J_rerun() 
	DEFINE l_rerun_ind SMALLINT 

	LET l_rerun_ind = true 
	SELECT count(*) INTO modu_rerun_cnt 
	FROM jmj_invoicedetail 
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
# FUNCTION ASI_J_chk_tables()
#
#
#########################################################################
FUNCTION ASI_J_chk_tables() 
	#
	# Validate existence of jmj_trantype translation table
	#
	SELECT unique 1 FROM systables 
	WHERE tabname = "jmj_truedebtor" 
	IF sqlca.sqlcode = NOTFOUND THEN 
		LET modu_err2_cnt = modu_err2_cnt + 1 
		LET modu_err_message = 
		"Run SQL script TO create JMJ TRUE Debtor table first - Load Aborted"
		#---------------------------------------------------------
		OUTPUT TO REPORT ASI_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASI_J_rpt_list_exception"),
		'', '', '', modu_err_message ) 
		#---------------------------------------------------------		
		 
		IF modu_verbose_ind THEN 
			ERROR modu_err_message 
		END IF 
		RETURN false 
	END IF 
	#
	# Validate existence of jmj_trantype translation table
	#
	SELECT unique 1 FROM systables 
	WHERE tabname = "jmj_trantype" 
	IF sqlca.sqlcode = NOTFOUND THEN 
		LET modu_err2_cnt = modu_err2_cnt + 1 
		LET modu_err_message = 
		"Run SQL script TO create JMJ Translation table first - Load Aborted" 
		#---------------------------------------------------------
		OUTPUT TO REPORT ASI_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASI_J_rpt_list_exception"),
		'', '', '', modu_err_message ) 
		#---------------------------------------------------------		
		IF modu_verbose_ind THEN 
			ERROR modu_err_message 
		END IF 
		RETURN false 
	END IF 
	#
	# Validate existence of jmj_invoicedetail table
	#
	SELECT unique 1 FROM systables 
	WHERE tabname = "jmj_invoicedetail" 
	IF sqlca.sqlcode = NOTFOUND THEN 
		LET modu_err2_cnt = modu_err2_cnt + 1 
		LET modu_err_message = 
		"Run SQL script TO create JMJ Invoice table first - Load Aborted" 
		#---------------------------------------------------------
		OUTPUT TO REPORT ASI_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASI_J_rpt_list_exception"),
		'', '', '', modu_err_message ) 
		#---------------------------------------------------------		
		IF modu_verbose_ind THEN 
			ERROR modu_err_message 
		END IF 
		RETURN false 
	END IF 
	RETURN true 
END FUNCTION 


#########################################################################
# FUNCTION ASI_J_chk_setup()
#
# IF currency AUD NOT SET up THEN do NOT perform load
#########################################################################
FUNCTION ASI_J_chk_setup() 
	SELECT 1 FROM currency 
	WHERE currency_code = 'AUD' 
	IF sqlca.sqlcode = NOTFOUND THEN 
		LET modu_err_cnt = modu_err_cnt + 1 
		LET modu_err_message = "Currency: AUD NOT SET up - Load Aborted" 
		#---------------------------------------------------------
		OUTPUT TO REPORT ASI_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASI_J_rpt_list_exception"),
		'', '', '', modu_err_message ) 
		#---------------------------------------------------------		
		RETURN false 
	END IF 
	RETURN true 
END FUNCTION 


#########################################################################
# FUNCTION ASI_J_perform_load()
#
#
#########################################################################
FUNCTION ASI_J_perform_load() 
	DEFINE l_insert_ind SMALLINT 
	DEFINE l_arg_num INTEGER 
	DEFINE l_temp_file CHAR(100) 
	DEFINE l_runner CHAR(200) 
	--DEFINE l_arg_num_idx SMALLINT

	LET l_insert_ind = true 
	LET modu_load_file = modu_load_file clipped 
	LET l_arg_num = get_url_file_list_count() #was numx_args() 



	WHILE l_insert_ind 
		IF modu_verbose_ind THEN 
			#
			# Perform 'INSERT' only once FOR interactive mode
			#
			LET l_insert_ind = false 
		ELSE 
			CALL ASI_J_valid_load_file( get_url_load_file() ) 
			RETURNING modu_load_file 
			LET l_arg_num = l_arg_num - 1 
			IF l_arg_num = 0 THEN 
				LET l_insert_ind = false 
			END IF 
		END IF 
		IF modu_load_file IS NOT NULL THEN 
			LET l_temp_file = modu_load_file clipped, ".tmp" 
			LET l_runner = "dos2ux ", modu_load_file clipped, " > ", 
			l_temp_file clipped 
			RUN l_runner 
			WHENEVER ERROR CONTINUE 
			LOAD FROM l_temp_file INSERT INTO jmj_invoicedetail 
			WHENEVER ERROR stop 
			WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
			IF sqlca.sqlcode != 0 THEN 
				LET modu_err2_cnt = modu_err2_cnt + 1 
				LET modu_err_message = "ASI_J - Refer ", trim(get_settings_logFile()), " FOR SQL Error: ",STATUS, 
				" in Load File: ",modu_load_file clipped 
				LET modu_err_text = " ",err_get(STATUS) 
				CALL errorlog( modu_err_text ) 
				#---------------------------------------------------------
				OUTPUT TO REPORT ASI_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASI_J_rpt_list_exception"),
				'', '', '', modu_err_message ) 
				#---------------------------------------------------------		
				#---------------------------------------------------------
				OUTPUT TO REPORT ASI_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASI_J_rpt_list_exception"),
				'', '', '', modu_err_text ) 
				#---------------------------------------------------------		
				
			END IF 
		END IF 
	END WHILE 
END FUNCTION 


#########################################################################
# FUNCTION ASI_J_null_tests()
#
# Perform NULL test's on data fields
#########################################################################
FUNCTION ASI_J_null_tests() 
	DEFINE l_rec_jmj_invdetl RECORD LIKE jmj_invoicedetail.* 

	DECLARE c1_jmjinvdetl CURSOR FOR 
	SELECT * FROM jmj_invoicedetail 
	WHERE expdrs_record_type != 'C' 
	AND expdrs_imprest != 'W' 
	AND ( expdrs_client IS NULL 
	OR expdrs_invoice_no IS NULL 
	OR expdrs_date IS NULL 
	OR expdrs_process_grp IS NULL 
	OR expdrs_trans_type IS NULL 
	OR expdrs_record_type IS NULL 
	OR expdrs_imprest IS NULL 
	OR expdrs_amount IS NULL 
	OR expdrs_client = ' ' 
	OR expdrs_record_type = ' ' 
	OR expdrs_imprest = ' ' ) 
	FOREACH c1_jmjinvdetl INTO l_rec_jmj_invdetl.* 
		IF l_rec_jmj_invdetl.expdrs_process_grp IS NULL THEN 
			LET modu_err_cnt = modu_err_cnt + 1 
			LET modu_err_message = "Null Processing Group detected" 
			#---------------------------------------------------------
			OUTPUT TO REPORT ASI_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASI_J_rpt_list_exception"),
			l_rec_jmj_invdetl.expdrs_process_grp, 
			l_rec_jmj_invdetl.expdrs_client, 
			l_rec_jmj_invdetl.expdrs_invoice_no, 
			modu_err_message )
			#---------------------------------------------------------					

			CONTINUE FOREACH 
		END IF 
		IF l_rec_jmj_invdetl.expdrs_client IS NULL 
		OR l_rec_jmj_invdetl.expdrs_client = ' ' THEN 
			LET modu_err_cnt = modu_err_cnt + 1 
			LET modu_err_message = "Null Client Code detected"
			#---------------------------------------------------------
			OUTPUT TO REPORT ASI_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASI_J_rpt_list_exception"),
			l_rec_jmj_invdetl.expdrs_process_grp, 
			l_rec_jmj_invdetl.expdrs_client, 
			l_rec_jmj_invdetl.expdrs_invoice_no, 
			modu_err_message )
			#---------------------------------------------------------					
			 
			CONTINUE FOREACH 
		END IF 
		
		IF l_rec_jmj_invdetl.expdrs_invoice_no IS NULL THEN 
			LET modu_err_cnt = modu_err_cnt + 1 
			LET modu_err_message = "Null Invoice No. detected" 
			#---------------------------------------------------------
			OUTPUT TO REPORT ASI_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASI_J_rpt_list_exception"),
			l_rec_jmj_invdetl.expdrs_process_grp, 
			l_rec_jmj_invdetl.expdrs_client, 
			l_rec_jmj_invdetl.expdrs_invoice_no, 
			modu_err_message )
			#---------------------------------------------------------					

			CONTINUE FOREACH 
		END IF 
		
		IF l_rec_jmj_invdetl.expdrs_date IS NULL THEN 
			LET modu_err_cnt = modu_err_cnt + 1 
			LET modu_err_message = "Null Invoice date detected" 
			#---------------------------------------------------------
			OUTPUT TO REPORT ASI_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASI_J_rpt_list_exception"),
			l_rec_jmj_invdetl.expdrs_process_grp, 
			l_rec_jmj_invdetl.expdrs_client, 
			l_rec_jmj_invdetl.expdrs_invoice_no, 
			modu_err_message )
			#---------------------------------------------------------					

			CONTINUE FOREACH 
		END IF 
		
		IF l_rec_jmj_invdetl.expdrs_trans_type IS NULL THEN 
			LET modu_err_cnt = modu_err_cnt + 1 
			LET modu_err_message = "Null Transaction group detected" 
			#---------------------------------------------------------
			OUTPUT TO REPORT ASI_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASI_J_rpt_list_exception"),
			l_rec_jmj_invdetl.expdrs_process_grp, 
			l_rec_jmj_invdetl.expdrs_client, 
			l_rec_jmj_invdetl.expdrs_invoice_no, 
			modu_err_message )
			#---------------------------------------------------------					
			
			CONTINUE FOREACH 
		END IF 
		
		IF l_rec_jmj_invdetl.expdrs_record_type IS NULL 
		OR l_rec_jmj_invdetl.expdrs_record_type = ' ' THEN 
			LET modu_err_cnt = modu_err_cnt + 1 
			LET modu_err_message = "Null RECORD type detected" 
			#---------------------------------------------------------
			OUTPUT TO REPORT ASI_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASI_J_rpt_list_exception"),
			l_rec_jmj_invdetl.expdrs_process_grp, 
			l_rec_jmj_invdetl.expdrs_client, 
			l_rec_jmj_invdetl.expdrs_invoice_no, 
			modu_err_message )
			#---------------------------------------------------------					

			CONTINUE FOREACH 
		END IF 
		
		IF l_rec_jmj_invdetl.expdrs_imprest IS NULL 
		OR l_rec_jmj_invdetl.expdrs_imprest = ' ' THEN 
			LET modu_err_cnt = modu_err_cnt + 1 
			LET modu_err_message = "Null Imprest indicator detected" 
			#---------------------------------------------------------
			OUTPUT TO REPORT ASI_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASI_J_rpt_list_exception"),
			l_rec_jmj_invdetl.expdrs_process_grp, 
			l_rec_jmj_invdetl.expdrs_client, 
			l_rec_jmj_invdetl.expdrs_invoice_no, 
			modu_err_message )
			#---------------------------------------------------------					
			
			CONTINUE FOREACH 
		END IF 
		IF l_rec_jmj_invdetl.expdrs_amount IS NULL THEN 
			LET modu_err_cnt = modu_err_cnt + 1 
			LET modu_err_message = "Null Invoice detail amount detected" 
			#---------------------------------------------------------
			OUTPUT TO REPORT ASI_J_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASI_J_rpt_list_exception"),
			l_rec_jmj_invdetl.expdrs_process_grp, 
			l_rec_jmj_invdetl.expdrs_client, 
			l_rec_jmj_invdetl.expdrs_invoice_no, 
			modu_err_message )
			#---------------------------------------------------------					
			
			CONTINUE FOREACH 
		END IF 
	END FOREACH 
END FUNCTION 




#########################################################################
# FUNCTION setup_cnt()
#
# Total records TO be processed FROM load file
#########################################################################
FUNCTION setup_cnt() 

	SELECT count(*) INTO modu_process_cnt 
	FROM jmj_invoicedetail 
	IF modu_process_cnt IS NULL THEN 
		LET modu_process_cnt = 0 
	END IF 
	LET modu_loadfile_cnt = modu_process_cnt - modu_rerun_cnt 
	#
	# No. of records TO be processed FROM GL Load
	#
	SELECT count(*) INTO modu_glload_cnt 
	FROM jmj_invoicedetail 
	WHERE ( expdrs_record_type = 'C' 
	AND expdrs_record_type != ' ' 
	AND expdrs_record_type IS NOT NULL ) 
	OR ( expdrs_imprest = 'W' 
	AND expdrs_imprest != ' ' 
	AND expdrs_imprest IS NOT NULL ) 
	IF modu_glload_cnt IS NULL THEN 
		LET modu_glload_cnt = 0 
	END IF 
	#
	# No. of records TO be processed FROM AR Load
	#
	LET modu_arload_cnt = modu_process_cnt - modu_glload_cnt 
END FUNCTION 


#########################################################################
# FUNCTION setup_cnt()
#
# INITIALIZE VALUES ( used TO reduce duplication of code )
#########################################################################
FUNCTION ASI_J_init_values() 

	LET modu_err_cnt = 0 
	LET modu_err2_cnt = 0 
	LET modu_arload_cnt = 0 
	LET modu_glload_cnt = 0 
	LET modu_kandoo_ar_cnt = 0 
	LET modu_kandoo_in_cnt = 0 
	LET modu_kandoo_cr_cnt = 0 
	LET modu_total_in_amt = 0 
	LET modu_total_cr_amt = 0 
END FUNCTION 


#########################################################################
# FUNCTION setup_cnt()
#
# INITIALIZE VALUES ( used TO reduce duplication of code )
#########################################################################
FUNCTION ASI_J_unload() 
	DEFINE l_temp_file CHAR(100) 
	DEFINE l_runner CHAR(600) 
	DEFINE l_unload_cnt INTEGER 
	#
	# UNLOAD contents of interim table
	#
	IF ASI_J_import_invoice() THEN 
		LET l_temp_file = modu_load_file clipped, ".tmp" 
		#
		# Need TO SET l_runner here b/c of Informix Bug
		#
		# Informix Bug: After executing unload statement
		#               any subsequent references TO l_temp_file go screwy
		#
		LET l_runner = "ux2dos ", l_temp_file clipped, 
		" > ", modu_load_file clipped 
		UNLOAD TO l_temp_file SELECT * FROM jmj_invoicedetail 
		LET sqlca.sqlcode = 0 
		IF sqlca.sqlcode = 0 THEN 
			LET l_unload_cnt = sqlca.sqlerrd[3] 
			IF l_unload_cnt IS NULL THEN 
				LET l_unload_cnt = 0 
			END IF 
			RUN l_runner 
			IF kandoomsg("A",8020,l_unload_cnt) = 'Y' THEN 
				#8020 <VALUE> records unloaded FROM table. Confirm TO CLEAR (Y/N)?
				DELETE FROM jmj_invoicedetail 
				#
				# delete all entries ( NB. both AR AND GL )
				#
			END IF 
		END IF 
	END IF 
END FUNCTION 


#########################################################################
# FUNCTION setup_cnt()
#
# ( used TO reduce duplication of code )
#########################################################################
FUNCTION ASI_J_start_load() 
	DEFINE l_msgresp LIKE language.yes_flag

	CALL ASI_J_start_report() 
	CALL ASI_J_init_values() 
	IF modu_verbose_ind THEN 
		IF ASI_J_import_invoice() THEN 
			CALL ASI_J_load_routine() 
			IF ( modu_err_cnt + modu_err2_cnt ) THEN 
				LET l_msgresp = kandoomsg("A",7061,(modu_err_cnt+modu_err2_cnt)) 
				#7061 Invoice Load Completed, Errors Encountered
			ELSE 
				IF ( modu_kandoo_in_cnt + modu_kandoo_cr_cnt ) THEN 
					LET l_msgresp = kandoomsg("A",7062,'') 
					#7062 Invoice Load Completed Successfully
				END IF 
			END IF 
			#
			# Create GL Batch
			#
			IF modu_glload_cnt THEN 
				CALL ASI_J_create_gl_entry() 
			END IF 
		END IF 
	ELSE 
		CALL ASI_J_load_routine() 
	END IF 
	CALL ASI_J_finish_report() 
END FUNCTION 


#########################################################################
# FUNCTION ASI_J_move_load_file()
#
#
#########################################################################
FUNCTION ASI_J_move_load_file() 
	DEFINE l_move_path CHAR(50) 
	DEFINE l_move_file CHAR(100) 
	DEFINE l_runner CHAR(300) 
	DEFINE l_file CHAR(100) 
	DEFINE l_ret_code INTEGER 

	LET l_move_path = "process" 
	LET l_move_file = l_move_path clipped, "/", modu_file_text 

	LET l_ret_code = os.path.exists(l_move_path) --huho changed TO os.path() methods 
	#LET l_runner = " [ -d ",l_move_path clipped," ] 2>>", trim(get_settings_logFile())
	#run l_runner returning l_ret_code
	IF l_ret_code THEN 
		IF modu_verbose_ind THEN 
			ERROR " Directory process does NOT exist" 
		END IF 
		RETURN 
	END IF 

	LET l_ret_code = os.path.writable(l_move_path) --huho changed TO os.path() methods 
	#LET l_runner = " [ -w ",l_move_path clipped," ] 2>>", trim(get_settings_logFile())
	#run l_runner returning l_ret_code
	IF l_ret_code THEN 
		ERROR " No permission TO write TO directory" 
		RETURN 
	END IF 
	WHILE true 

		LET l_ret_code = os.path.exists(l_move_file) --huho changed TO os.path() methods 
		#LET l_runner = " [ -f ",l_move_file clipped," ] 2>>", trim(get_settings_logFile())
		#run l_runner returning l_ret_code
		IF l_ret_code THEN 
			EXIT WHILE 
		ELSE 
			IF modu_verbose_ind THEN 
				ERROR " Cannot move load l_file - l_file already exists" 
				LET l_file = "" 


				LET l_file = fgl_winprompt(5,5, "Enter target l_file name", "", 25, 0) 


				IF int_flag OR quit_flag THEN 
					LET int_flag = false 
					LET quit_flag = false 
					RETURN 
				ELSE 
					LET l_move_file = l_move_path clipped, "/", l_file clipped 
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



#########################################################################
# REPORT ASI_J_rpt_list(p_rpt_idx, p_cmpy_code, p_client_code, p_cust_code, p_org_cust_code,
#                  p_trans_num, p_tran_date,   p_line_num,  p_total_amt,
#                  p_trans_flag )
#
#
#########################################################################
REPORT ASI_J_rpt_list(p_rpt_idx,p_cmpy_code, p_client_code, p_cust_code, p_org_cust_code, 
	p_trans_num, p_tran_date, p_line_num, p_total_amt, 
	p_trans_flag) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE p_cmpy_code LIKE invoicehead.cmpy_code 
	DEFINE p_client_code LIKE jmj_invoicedetail.expdrs_client 
	DEFINE p_cust_code LIKE invoicehead.cust_code 
	DEFINE p_org_cust_code LIKE invoicehead.org_cust_code 
	DEFINE p_trans_num LIKE invoicehead.inv_num 
	DEFINE p_tran_date LIKE invoicehead.inv_date 
	DEFINE p_line_num LIKE invoicehead.line_num 
	DEFINE p_total_amt LIKE invoicehead.total_amt 
	DEFINE p_trans_flag CHAR(1) 

	OUTPUT 
--	left margin 0 
	ORDER external BY p_cmpy_code, 
	p_cust_code, 
	p_trans_num 
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
			COLUMN 10, p_client_code, 
			COLUMN 23, p_cust_code, 
			COLUMN 33, p_org_cust_code, 
			COLUMN 57, p_trans_flag, 
			COLUMN 64, p_trans_num USING "########", 
			COLUMN 75, p_tran_date USING "dd/mm/yy", 
			COLUMN 92, p_line_num USING "########", 
			COLUMN 106, p_total_amt USING "###########&.&&" 
			IF p_trans_flag = 'l_i' THEN 
				LET modu_total_in_amt = modu_total_in_amt + p_total_amt 
			ELSE 
				LET modu_total_cr_amt = modu_total_cr_amt + p_total_amt 
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


#########################################################################
# REPORT ASI_J_rpt_list_exception(p_rpt_idx,p_process_grp, p_client_code, p_inv_num, p_status)
#
#
#########################################################################
REPORT ASI_J_rpt_list_exception(p_rpt_idx,p_process_grp, p_client_code, p_inv_num, p_status)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	 
	DEFINE p_process_grp LIKE jmj_invoicedetail.expdrs_process_grp 
	DEFINE p_client_code LIKE jmj_invoicedetail.expdrs_client 
	DEFINE p_inv_num LIKE jmj_invoicedetail.expdrs_invoice_no 
	DEFINE p_status CHAR(132) 

	OUTPUT 
--	left margin 0 
	
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
			COLUMN 32, p_inv_num USING "########", 
			COLUMN 44, p_status[1,132-44] 
			
		ON LAST ROW 
			NEED 20 LINES 
			PRINT COLUMN 10, "Total records TO be processed FROM Re-run : ", modu_rerun_cnt 
			PRINT COLUMN 10, "Total records TO be processed FROM Load File: ", modu_loadfile_cnt 
			PRINT COLUMN 55, "-------------" 
			PRINT COLUMN 55, ( modu_rerun_cnt + modu_loadfile_cnt ) USING "###########&" 
			SKIP 1 line 
			PRINT COLUMN 10, "Total records TO be processed FROM AR Load : ", modu_arload_cnt 
			PRINT COLUMN 10, "Total records TO be processed FROM GL Load : ", modu_glload_cnt 
			PRINT COLUMN 55, "-------------" 
			PRINT COLUMN 55, ( modu_arload_cnt + modu_glload_cnt ) USING "###########&" 
			SKIP 1 line 
			PRINT COLUMN 10, "Total records with validation errors : ",modu_err_cnt, 
			" ( SQL / File errors: ",modu_err2_cnt," )" 
			PRINT COLUMN 10, "Total AR records successfully processed : ", 	modu_kandoo_ar_cnt 
			PRINT COLUMN 10, "( total no. OF invoices:", 
			COLUMN 39, modu_kandoo_in_cnt USING "###########&", " )" 
			PRINT COLUMN 10, "( total no. OF credits :", 
			COLUMN 39, modu_kandoo_cr_cnt USING "###########&", " )" 
			PRINT COLUMN 55, "-------------" 
			PRINT COLUMN 55, ( modu_err_cnt + modu_kandoo_ar_cnt ) USING "###########&" 
			SKIP 1 line 
			PRINT COLUMN 10, "Total invoice amounts : ", 
			COLUMN 55, modu_total_in_amt USING "--------&.&&" 
			PRINT COLUMN 10, "Total credit amounts : ", 
			COLUMN 55, modu_total_cr_amt USING "--------&.&&" 
			PRINT COLUMN 55, "-------------" 
			PRINT COLUMN 55, (modu_total_in_amt + modu_total_cr_amt) USING "--------&.&&" 
			SKIP 2 LINES
			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			
END REPORT 
