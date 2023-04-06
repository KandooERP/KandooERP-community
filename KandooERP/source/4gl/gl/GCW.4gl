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

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl"
GLOBALS "../common/glob_GLOBALS_report.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl"
GLOBALS "../gl/GC_GROUP_GLOBALS.4gl" 
GLOBALS "../gl/GCW_GLOBALS.4gl"

GLOBALS 
	DEFINE glob_rec_loadstatus RECORD LIKE loadstatus.* 
	DEFINE glob_rec_loadxref RECORD LIKE loadxref.* 
	DEFINE glob_rec_structure RECORD LIKE structure.* 
	DEFINE glob_rec_journal RECORD LIKE journal.* 
	DEFINE glob_rec_whics_glalloc RECORD LIKE whics_glalloc.* 
	DEFINE glob_rec_allocation 
	RECORD 
		fund_ind LIKE whics_glalloc.fund_ind, 
		cmpy_code LIKE company.cmpy_code, 
		tran_type_ind LIKE batchdetl.tran_type_ind, 
		alloc_key LIKE whics_glalloc.com_text, 
		trans_date LIKE whics_glalloc.trans_date, 
		dr_acct_code LIKE batchdetl.acct_code, 
		dr_bank_flag SMALLINT, 
		dr_rowid INTEGER, 
		cr_acct_code LIKE batchdetl.acct_code, 
		cr_bank_flag SMALLINT, 
		cr_rowid INTEGER, 
		dr_cr_amt LIKE batchdetl.debit_amt 
	END RECORD 
	DEFINE l_curr_cmpy_code LIKE company.cmpy_code 
	DEFINE l_multiledger SMALLINT 
	DEFINE l_ledg_start LIKE structure.start_num 
	DEFINE l_ledg_length LIKE structure.length_num 
	DEFINE l_prev_file_text LIKE loadstatus.file_text 
	DEFINE l_prev_year_num LIKE loadstatus.year_num 
	DEFINE l_prev_period_num LIKE loadstatus.period_num 
--	DEFINE l_rpt_note LIKE rmsreps.report_text 
	DEFINE l_post_rpt_note LIKE rmsreps.report_text 

	--DEFINE l_post_rpt_pageno LIKE rmsreps.page_num 
	--DEFINE l_rpt_length LIKE rmsreps.page_length_num 
	--DEFINE l_post_rpt_length LIKE rmsreps.page_length_num 
	--DEFINE l_post_rpt_wid LIKE rmsreps.report_width_num 
	--DEFINE l_post_output char(60) 
	--DEFINE l_output1 char(60) 
	DEFINE l_display_text char(60) 
	DEFINE l_error_text char(65) 
	DEFINE l_record_count INTEGER 
	DEFINE l_valid_recs INTEGER 
	DEFINE l_invalid_recs INTEGER 
	DEFINE l_valid_amts LIKE whics_glalloc.dr_cr_amt 
	DEFINE l_invalid_amts LIKE whics_glalloc.dr_cr_amt 
	DEFINE l_insert_phase SMALLINT 
	DEFINE l_complete SMALLINT 
	DEFINE l_invalid_acct SMALLINT 
	DEFINE l_arr_comments array[9] OF char(60) 
	DEFINE l_try_again char(1) 
	DEFINE l_err_message char(80) 

END GLOBALS 
###########################################################################
# MODULE Scope Variables
###########################################################################

########################################################################
# MAIN
#
# Purpose : WHICS-OPEN GL AND Cash Book Interface Program  
########################################################################
MAIN 

	DEFER quit 
	DEFER interrupt 
	
	CALL setModuleId("GCW") 
	CALL ui_init(0) #initial ui init 
	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_g_gl() #init g/gl general ledger module 

	#
	# Initialise global variables -> ??? check var name and correct
	#
	LET l_record_count = 0 
	LET l_insert_phase = 1 
	LET l_complete = 99 

	--	CALL create_table("batchdetl","f_batchdetl","","N") #changed to normal table

	CREATE temp TABLE f_allocation( 
	fund_ind char(1), 
	cmpy_code char(2), 
	tran_type_ind char(3), 
	alloc_key char(30), 
	trans_date DATE, 
	dr_acct_code char(18), 
	dr_bank_flag SMALLINT, 
	dr_rowid INTEGER, 
	cr_acct_code char(18), 
	cr_bank_flag SMALLINT, 
	cr_rowid INTEGER, 
	dr_cr_amt decimal(16,2) 
	) 

	OPEN WINDOW G557 with FORM "G557" 
	CALL windecoration_g("G557") 

	MENU "WHICS GL load" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","GCW","menu-whics-gl-load") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "Load"	#COMMAND "Load" " Commence GL/Cash Book load process"
			IF start_load() THEN 
				IF update_status("Y") THEN 
					CALL insert_data() 
				END IF 
			END IF 

		ON ACTION "PRINT MANAGER"	#COMMAND KEY ("P",f11) "Print" " Print OR View using RMS"
			CALL run_prog("URS","","","","") 

		ON ACTION "Exit" #COMMAND KEY(interrupt,"E")"Exit" " Exit GL Load"
			LET int_flag = true 
			LET quit_flag = true 
			EXIT MENU 

	END MENU 

	CLOSE WINDOW G557 

END MAIN 
########################################################################
# END MAIN
########################################################################


########################################################################
# FUNCTION start_load()
#
#
########################################################################
FUNCTION start_load() 
	DEFINE l_filename char(80) 
	DEFINE l_msgresp LIKE language.yes_flag 
	#
	# Retrieve details of the previous load.
	#
	SELECT * INTO glob_rec_loadstatus.* FROM loadstatus 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND run_text = "GCW" 
	IF status = NOTFOUND THEN 
		# 7040 "Load STATUS  FOR GCW cannot be found - cannot load
		LET l_msgresp = kandoomsg("U",7040,"WHICS-OPEN GL") 
		RETURN false 
	END IF 
	#
	# IF this IS a new load run, save the previously entered details FOR
	# display. The file name IS SET TO NULL TO discourage previously loaded
	# files FROM being entered again by default.  IF it IS a restart, leave
	# details intact, as load details are NOT re-entered in this instance.
	#
	LET l_prev_file_text = glob_rec_loadstatus.file_text 
	LET l_prev_year_num = glob_rec_loadstatus.year_num 
	LET l_prev_period_num = glob_rec_loadstatus.period_num 

	IF glob_rec_loadstatus.jour_code IS NULL OR 
	glob_rec_loadstatus.jour_code = " " THEN 
		SELECT gj_code INTO glob_rec_loadstatus.jour_code FROM glparms 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND key_code = "1" 
	END IF 

	IF glob_rec_loadstatus.status_code = l_complete THEN 
		LET glob_rec_loadstatus.file_text = NULL 
		CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, today) 
		RETURNING glob_rec_loadstatus.year_num, glob_rec_loadstatus.period_num 
	END IF 

	DISPLAY 
		glob_rec_loadstatus.jour_code, 
		glob_rec_loadstatus.year_num, 
		glob_rec_loadstatus.period_num, 
		glob_rec_loadstatus.file_text, 
		glob_rec_loadstatus.path_text, 
		glob_rec_loadstatus.entry_code, 
		glob_rec_loadstatus.entry_time, 
		l_prev_file_text, 
		l_prev_year_num, 
		l_prev_period_num, 
		glob_rec_loadstatus.status_code, 
		glob_rec_loadstatus.status_time, 
		glob_rec_loadstatus.status_text 
	TO
		jour_code, 
		year_num, 
		period_num, 
		file_text, 
		path_text, 
		entry_code, 
		entry_time, 
		prev_file_text, 
		prev_year_num, 
		prev_period_num, 
		status_code, 
		status_time, 
		status_text 
	
	#
	# IF the load was NOT complete, need TO finish the previous load
	# before allowing new data TO be loaded INTO the table. Skip the
	# file entry section AND go straight TO processing.
	#
	SELECT count(*) INTO l_record_count 
	FROM whics_glalloc 
	IF l_record_count IS NULL THEN 
		LET l_record_count = 0 
	END IF 

	IF glob_rec_loadstatus.status_code < l_complete OR 
	l_record_count <> 0 THEN 
		LET l_msgresp = kandoomsg("U",7041,"") 
		#7041 Load incomplete - restarting.  Any key ...
		LET l_msgresp = kandoomsg("U",8028,"") 
		#8028 Begin Processing Load File records? (Y/N)
	ELSE 
		#
		# No previous load TO complete - get new load file name
		#
		IF open_file() THEN 
			CALL move_load_file() 
			LET l_msgresp = kandoomsg("U",8028,"") 
			#8028 Begin Processing Load File records? (Y/N)
		ELSE 
			LET l_msgresp = "N" 
		END IF 
	END IF 
	IF l_msgresp = "Y" THEN 
		RETURN true 
	ELSE 
		RETURN false 
	END IF 
END FUNCTION 
########################################################################
# END FUNCTION start_load()
########################################################################


########################################################################
# FUNCTION open_file()
#
#
########################################################################
FUNCTION open_file() 
	DEFINE l_filename char(80) 
	DEFINE l_invalid_flag SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	INPUT BY NAME 
		glob_rec_loadstatus.jour_code, 
		glob_rec_loadstatus.year_num, 
		glob_rec_loadstatus.period_num, 
		glob_rec_loadstatus.file_text, 
		glob_rec_loadstatus.path_text WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GCW","inp-loadstatus") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN 
				SELECT unique 1 FROM journal 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND jour_code = glob_rec_loadstatus.jour_code 
				IF status = NOTFOUND THEN 
					LET l_msgresp = kandoomsg("U",9105,"")				#9105 RECORD does NOT exist
					NEXT FIELD jour_code 
				END IF 

				CALL valid_period(
					glob_rec_kandoouser.cmpy_code, 
					glob_rec_loadstatus.year_num, 
					glob_rec_loadstatus.period_num, 
					'GL') 
				RETURNING 
					glob_rec_loadstatus.year_num, 
					glob_rec_loadstatus.period_num, 
					l_invalid_flag 

				IF l_invalid_flag THEN 
					NEXT FIELD year_num 
				END IF 
				IF NOT valid_file() THEN 
					NEXT FIELD file_text 
				END IF 
			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 
	RETURN true 
END FUNCTION 
########################################################################
# END FUNCTION open_file()
########################################################################


########################################################################
# FUNCTION valid_file()
#
#
########################################################################
FUNCTION valid_file() 
	DEFINE l_filename char(100) 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET l_filename = glob_rec_loadstatus.path_text clipped, "/", glob_rec_loadstatus.file_text clipped 
	WHENEVER ERROR CONTINUE 
	LOAD FROM l_filename INSERT INTO whics_glalloc 
	WHENEVER ERROR stop 

	IF status != 0 THEN 
		LET l_msgresp=kandoomsg("U",9115,"") 	#9115 Load file does NOT exist; Try again."
		RETURN false 
	END IF 

	SELECT unique 1 FROM whics_glalloc 
	IF status = NOTFOUND THEN 
		LET l_msgresp=kandoomsg("U",9119,"") 	#9119 Incorrect file FORMAT OR blank lines detected.
		RETURN false 
	END IF 

	RETURN true 
END FUNCTION 
########################################################################
# END FUNCTION valid_file()
########################################################################


########################################################################
# FUNCTION move_load_file()
#
#
########################################################################
FUNCTION move_load_file() 
	DEFINE l_move_path STRING 
	DEFINE l_move_file STRING 
	DEFINE l_load_file STRING 
	DEFINE l_runner STRING 
	DEFINE l_ret_code INTEGER 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET l_load_file = glob_rec_loadstatus.path_text clipped, "/", glob_rec_loadstatus.file_text clipped 
	LET l_move_path = glob_rec_loadstatus.path_text clipped, "/", glob_rec_loadstatus.file_text clipped, ".tmp" 

	WHILE true 

		LET l_ret_code = os.path.exists(l_move_path) --huho changed TO os.path() method 
		#LET l_runner = " [ -f ",l_move_path clipped," ] 2>>",trim(get_settings_logFile())
		#run l_runner returning l_ret_code
		IF l_ret_code THEN 
			EXIT WHILE 
		ELSE 
			LET l_msgresp=kandoomsg("P",9179,"")		#P9179 - Cannot move load file; File already exists
			LET l_move_file = "" 

			LET l_move_file = fgl_winprompt(5,5, "Enter Move file name", "", 40, 0) 

			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
				RETURN 
			ELSE 
				LET l_move_path = glob_rec_loadstatus.path_text clipped, "/",	l_move_file clipped 
			END IF 
		END IF 

	END WHILE 

	LET l_runner = " mv ", l_load_file clipped, " ", l_move_path clipped,	" 2> /dev/null" 
	RUN l_runner 
END FUNCTION 
########################################################################
# END FUNCTION move_load_file()
########################################################################


########################################################################
# FUNCTION update_status(p_mode)
#
#
########################################################################
FUNCTION update_status(p_mode) 
	DEFINE p_mode char(1) 
	DEFINE l_running_flag LIKE loadstatus.load_running_flag 
	DEFINE l_msgresp LIKE language.yes_flag 

	GOTO upd_bypass 

	LABEL upd_recovery: 
	IF error_recover(l_err_message, status) != "Y" THEN 
		RETURN false 
	END IF 

	LABEL upd_bypass: 
	WHENEVER ERROR GOTO upd_recovery 
	# Lock the loadstatus RECORD WHILE updating TO ensure that
	# load IS NOT running elsewhere
	BEGIN WORK 
		DECLARE c_loadstatus CURSOR FOR 
		SELECT load_running_flag FROM loadstatus 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND run_text = "GCW" 
		FOR UPDATE 

		OPEN c_loadstatus 
		FETCH c_loadstatus INTO l_running_flag 

		IF status <> 0 THEN 
			# 7036 "Load STATUS NOT SET up FOR WHICS-OPEN GL -
			# cannot run posting."
			LET l_msgresp = kandoomsg("U",7040,"WHICS-OPEN GL") 
			ROLLBACK WORK 
			RETURN false 
		END IF 

		IF p_mode = "Y" AND l_running_flag = "Y" THEN 
			# 7042 "Load IS already running."
			LET l_msgresp = kandoomsg("U",7042,"") 
			ROLLBACK WORK 
			RETURN false 
		END IF 

		# Set up STATUS flags according TO whether we are running, restarting
		# OR completing
		IF p_mode = "Y" THEN 
			IF glob_rec_loadstatus.status_code < l_complete THEN 
				LET glob_rec_loadstatus.status_time = CURRENT year TO second 
				LET glob_rec_loadstatus.status_text = 
				"GCW - load restarted by ", glob_rec_kandoouser.sign_on_code clipped 
				LET glob_rec_loadstatus.load_running_flag = "Y" 
			ELSE 
				LET glob_rec_loadstatus.entry_code = glob_rec_kandoouser.sign_on_code 
				LET glob_rec_loadstatus.entry_time = CURRENT year TO second 
				LET glob_rec_loadstatus.status_code = l_insert_phase 
				LET glob_rec_loadstatus.status_text = "GCW - commenced data insert" 
				LET glob_rec_loadstatus.status_time = CURRENT year TO second 
				LET glob_rec_loadstatus.load_running_flag = "Y" 
			END IF 
		ELSE 
			LET glob_rec_loadstatus.status_code = l_complete 
			LET glob_rec_loadstatus.status_text = "GCW - completed load" 
			LET glob_rec_loadstatus.status_time = CURRENT year TO second 
			LET glob_rec_loadstatus.load_running_flag = "N" 
		END IF 
		
		LET l_err_message = "GCW - Updating loadstatus post running flag"
		
		#---------------------------- 
		UPDATE loadstatus SET 
			entry_code = glob_rec_loadstatus.entry_code, 
			entry_time = glob_rec_loadstatus.entry_time, 
			status_code = glob_rec_loadstatus.status_code, 
			status_text = glob_rec_loadstatus.status_text, 
			status_time = glob_rec_loadstatus.status_time, 
			load_running_flag = glob_rec_loadstatus.load_running_flag, 
			file_text = glob_rec_loadstatus.file_text, 
			path_text = glob_rec_loadstatus.path_text, 
			year_num = glob_rec_loadstatus.year_num, 
			period_num = glob_rec_loadstatus.period_num, 
			jour_code = glob_rec_loadstatus.jour_code 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND run_text = "GCW" 

	COMMIT WORK 
	WHENEVER ERROR stop
	 
	RETURN true 
END FUNCTION 
########################################################################
# END FUNCTION update_status(p_mode)
########################################################################


########################################################################
# FUNCTION insert_data()
#
#
########################################################################
FUNCTION insert_data() 
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE i SMALLINT 
	DEFINE l_status SMALLINT 
	DEFINE l_invalid_cmpy SMALLINT 
	DEFINE l_call_status INTEGER 
	DEFINE l_db_status INTEGER 
	DEFINE l_output STRING #report output file name inc. path

	#
	#  The WHICS-OPEN GL Interface loads details of the General Ledger
	#  allocations of WHICS transactions INTO database.  It also recognises
	#  GL allocations that relate TO banking entries (primarily receipts)
	#  AND creates the appropriate cash book reconciliation entries.
	#
	#  WHICS-OPEN allocates the various components of a membership
	#  transaction TO the correct GL accounts via a user-defined cross
	#  reference table.  The key TO the allocation cross-reference consists
	#  of a combination of transaction, product AND category AND each key
	#  has an associated debit AND credit account.  The WHICS-OPEN GL
	#  allocation process summarises the total value FOR each unique
	#  allocatiON KEY, AND outputs two records TO the interface file, one
	#  FOR the debit account AND one FOR the credit account.  The interface
	#  file contains allocations FOR more than one fund, which may translate
	#  TO separate companies WHEN loading.
	#
	#  The load process consists of the following steps:
	#
	#  1 - FOR each unique combination of fund, allocatiON KEY, date AND
	#      amount, read the debit/credit entries AND write a single entry
	#      TO a separate temporary table FOR each debit credit pair.
	#
	#  2 - Process the entries FOR each unique company code in the table
	#      in turn.  IF any of the parameters are invalid FOR the company
	#      code, skip all entries FOR that code.
	#
	#  3 - FOR each valid company, create a General Ledger journal
	#      containing all entries that are NOT related TO cash book.
	#
	#  4 - FOR the allocation entries that affect a bank GL account, create
	#      a separate cash book journal per transaction date AND create the
	#      associated cash book reconciliation entries.
	#
	#  5 - WHEN all entries are processed, check FOR any entries in the load
	#      table that were NOT selected FOR processing due TO interface file
	#      anomalies AND REPORT them.
	#
	#  6 - Delete the remaining entries FROM the load table.
	#
	#  Note that the process does NOT allow FOR restart - IF the program
	#  fails, the load file must be fully re-processed.  This should NOT
	#  cause significant operational problems  - since the interface file
	#  entries are already summarised, transaction volumes are low.

	GOTO bypass 
	LABEL recovery: 
	LET l_try_again = error_recover(l_err_message,status) 
	IF l_try_again != "Y" THEN 
		CALL gcw_exit_program() 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 

	--LET l_rpt_note = "WHICS-OPEN GL Load Exception Report - (Menu gcw)" 
	--LET l_output1 = init_report(glob_rec_kandoouser.cmpy_code, glob_rec_kandoouser.sign_on_code, l_rpt_note) 

	#START REPORT GCW_rpt_list_exception_report TO l_output1 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
--	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
--		LET int_flag = false 
--		LET quit_flag = false
--
--		RETURN FALSE
--	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"GCW_rpt_list_exception_report","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT GCW_rpt_list_exception_report TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0
	--LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GCW_rpt_list_exception_report")].sel_text
	#------------------------------------------------------------

	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start("CPOST-REPORT-2","post_report2","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT post_report2 TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0
	--LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("post_report2")].sel_text
	#------------------------------------------------------------

	--LET l_post_rpt_note = "WHICS-OPEN GL Batch Report - (Menu gcw)" 
	--LET l_post_output = init_report(glob_rec_kandoouser.cmpy_code, glob_rec_kandoouser.sign_on_code, l_post_rpt_note) 
	--START REPORT post_report TO l_post_output 

	FOR i = 1 TO 9 
		INITIALIZE l_arr_comments[i] TO NULL 
	END FOR 

	CALL create_posting_table() 
	LET l_valid_recs = 0 
	LET l_valid_amts = 0 
	LET l_invalid_recs = 0 
	LET l_invalid_amts = 0 
	LET l_invalid_cmpy = false 
	#
	#  All database processing IS contained in a single transaction
	#
	BEGIN WORK 
		DELETE FROM f_batchdetl WHERE 1=1 
		DECLARE c_company CURSOR FOR 
		SELECT unique cmpy_code FROM f_allocation 
		
		#-------------------------------------
		FOREACH c_company INTO l_curr_cmpy_code 
			LET l_display_text = "Creating GL allocations FOR Company ",	l_curr_cmpy_code 
			
			CALL display_progress(l_display_text) 
			
			IF NOT valid_company() THEN 
				LET l_invalid_cmpy = true 
				CONTINUE FOREACH 
			END IF 
			
			CALL create_gl_jnls(l_rpt_idx) 
			RETURNING l_call_status, l_db_status 
			
			IF l_call_status = false THEN 
				LET status = l_db_status 
				GOTO recovery 
			END IF 
			
			LET l_display_text = "Creating Cash Book journals FOR Company ",l_curr_cmpy_code 
			
			CALL display_progress(l_display_text) 
			CALL create_bank_jnls(l_rpt_idx) RETURNING l_call_status, l_db_status 
			
			IF l_call_status = false THEN 
				LET status = l_db_status 
				GOTO recovery 
			END IF 
		END FOREACH 
		#----------------------------------------

		CALL report_invalid_tx()	RETURNING l_call_status, l_db_status 
		IF l_call_status = false THEN 
			LET status = l_db_status 
			GOTO recovery 
		END IF 

	COMMIT WORK 

	LET l_error_text = l_valid_recs USING "#####&"," records loaded: Total value ",	l_valid_amts USING "--------&.&&" 

	OUTPUT TO REPORT GCW_rpt_list_exception_report(l_rpt_idx,l_error_text, false) 
	#---------------------------------------------------------
	OUTPUT TO REPORT GCW_rpt_list_exception_report(l_rpt_idx,l_error_text, false)  
	#---------------------------------------------------------

	LET l_error_text = l_invalid_recs USING "#####&", " records rejected: Total value ",l_invalid_amts USING "--------&.&&" 
	#---------------------------------------------------------
	OUTPUT TO REPORT GCW_rpt_list_exception_report(l_rpt_idx,l_error_text, TRUE)  
	#---------------------------------------------------------

	#------------------------------------------------------------
	FINISH REPORT GCW_rpt_list_exception_report
	CALL rpt_finish("GCW_rpt_list_exception_report")
	#------------------------------------------------------------

	#------------------------------------------------------------
	FINISH REPORT post_report
	CALL rpt_finish("post_report")
	#------------------------------------------------------------

	WHENEVER ERROR stop 

END FUNCTION 
########################################################################
# END FUNCTION insert_data()
########################################################################


########################################################################
# FUNCTION create_posting_table()
#
#  This FUNCTION consolidates the two records (debit AND credit) FROM
#  the load table FOR each allocatiON KEY INTO a single entry in a
#  temporary table.  It also determines IF it IS a banking transaction.
########################################################################
FUNCTION create_posting_table() 
	DEFINE l_cmpy_code LIKE company.cmpy_code 
	DEFINE l_rec_alloc_pair 
	RECORD 
		fund_ind LIKE whics_glalloc.fund_ind, 
		com_text LIKE whics_glalloc.com_text, 
		dr_acct_code LIKE whics_glalloc.acct_code, 
		dr_cr_amt LIKE whics_glalloc.dr_cr_amt, 
		trans_date LIKE whics_glalloc.trans_date, 
		dr_rowid INTEGER, 
		cr_acct_code LIKE whics_glalloc.acct_code, 
		cr_rowid INTEGER 
	END RECORD 

	LET l_display_text = "Creating posting records " 
	CALL display_progress(l_display_text) 
	DECLARE c1_whics_alloc CURSOR FOR 
	SELECT d.fund_ind, 
	d.com_text, 
	d.acct_code, 
	d.dr_cr_amt, 
	d.trans_date, 
	d.rowid, 
	c.acct_code, 
	c.rowid 
	FROM whics_glalloc d, whics_glalloc c 
	WHERE d.fund_ind = c.fund_ind 
	AND d.com_text = c.com_text 
	AND d.dr_cr_amt = c.dr_cr_amt 
	AND d.trans_date = c.trans_date 
	AND d.dr_cr_ind = "D" #mixup #Disburse Credit,Debit or Both ??? careless variable name usage ? dr_cr_ind
	AND c.dr_cr_ind = "C" #We should have 1,2 DISBURSE_CDB_CREDIT_1 SMALLINT = 1 DISBURSE_CDB_DEBIT_2

	FOREACH c1_whics_alloc INTO l_rec_alloc_pair.* 
		INITIALIZE glob_rec_allocation.* TO NULL 
		#
		# Retrieve the company code associated with the fund id.  IF no
		# RECORD exists, SET the company code field TO NULL FOR later
		# error reporting.
		#
		INITIALIZE glob_rec_loadxref.* TO NULL 
		SELECT * INTO glob_rec_loadxref.* FROM loadxref 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND run_text = "GCW" 
		AND type_code = "CO" 
		AND ext_code = l_rec_alloc_pair.fund_ind 

		LET glob_rec_allocation.cmpy_code = glob_rec_loadxref.int_code 
		LET glob_rec_allocation.fund_ind = l_rec_alloc_pair.fund_ind 
		LET glob_rec_allocation.alloc_key = l_rec_alloc_pair.com_text 
		LET glob_rec_allocation.trans_date = l_rec_alloc_pair.trans_date 
		LET glob_rec_allocation.dr_acct_code = l_rec_alloc_pair.dr_acct_code 
		LET glob_rec_allocation.dr_rowid = l_rec_alloc_pair.dr_rowid 
		LET glob_rec_allocation.cr_acct_code = l_rec_alloc_pair.cr_acct_code 
		LET glob_rec_allocation.cr_rowid = l_rec_alloc_pair.cr_rowid 
		LET glob_rec_allocation.dr_cr_amt = l_rec_alloc_pair.dr_cr_amt 
		#
		# IF either the debit OR credit account IS a bank GL account,
		# the transactions related TO a WHICS banking AND a cash book
		# journal IS required.  Set up different transaction type
		# indicators TO distinguish these entries.  Note that this
		# CALL will fail IF the company code IS NULL, but these records
		# will be rejected by later processing anyway.
		#
		LET glob_rec_allocation.dr_bank_flag = acct_type(
			glob_rec_allocation.cmpy_code, 
			glob_rec_allocation.dr_acct_code, 
			coa_account_required_is_control_bank, 
			"N") 
		LET glob_rec_allocation.cr_bank_flag = acct_type(
			glob_rec_allocation.cmpy_code, 
			glob_rec_allocation.cr_acct_code, 
			coa_account_required_is_control_bank, 
			"N") 
		
		IF glob_rec_allocation.dr_bank_flag OR glob_rec_allocation.cr_bank_flag THEN 
			LET glob_rec_allocation.tran_type_ind = "WHC" 
		ELSE 
			LET glob_rec_allocation.tran_type_ind = "WHG" 
		END IF 
		
		#--------------------------------------------------------
		INSERT INTO f_allocation VALUES (glob_rec_allocation.*) 
	END FOREACH 

END FUNCTION 
########################################################################
# END FUNCTION create_posting_table()
########################################################################


########################################################################
# FUNCTION valid_company()
#
#  This FUNCTION validates the company AND parameter details FOR the
#  given company code.  It also sets up the global parameter records
#  FOR the company currently being processed AND determines if
#  multi-ledger applies.
#
########################################################################
FUNCTION valid_company() 
	DEFINE l_fund_ind LIKE whics_glalloc.fund_ind 

	IF l_curr_cmpy_code IS NULL THEN 
		DECLARE c_fund_ind CURSOR FOR 
		SELECT unique fund_ind 
		FROM f_allocation WHERE cmpy_code IS NULL 
		FOREACH c_fund_ind INTO l_fund_ind 
			LET l_error_text = "No Company Code found FOR Fund ",	l_fund_ind 
			OUTPUT TO REPORT GCW_rpt_list_exception_report(l_error_text, false) 
		END FOREACH 
		RETURN false 
	END IF 

	SELECT * INTO glob_rec_company.* FROM company 
	WHERE cmpy_code = l_curr_cmpy_code 
	IF status = NOTFOUND THEN 
		LET l_error_text = "Invalid Company Code ", l_curr_cmpy_code clipped 
		OUTPUT TO REPORT GCW_rpt_list_exception_report(l_error_text, false) 
		RETURN false 
	END IF 

	SELECT * INTO glob_rec_glparms.* FROM glparms 
	WHERE key_code = "1" 
	AND cmpy_code = l_curr_cmpy_code 
	IF status = NOTFOUND THEN 
		LET l_error_text = "GL Parameters NOT SET up FOR Co. ",	l_curr_cmpy_code 
		OUTPUT TO REPORT GCW_rpt_list_exception_report(l_error_text, false) 
		RETURN false 
	END IF 

	SELECT * INTO glob_rec_journal.* FROM journal 
	WHERE cmpy_code = l_curr_cmpy_code 
	AND jour_code = glob_rec_loadstatus.jour_code 

	IF status = NOTFOUND THEN 
		LET l_error_text = "Journal code ", glob_rec_loadstatus.jour_code,	" NOT valid FOR Company ", l_curr_cmpy_code 
		OUTPUT TO REPORT GCW_rpt_list_exception_report(l_error_text, false) 
		RETURN false 
	END IF 

	IF NOT valid_period2(l_curr_cmpy_code, glob_rec_loadstatus.year_num, glob_rec_loadstatus.period_num, 'GL') THEN 
		LET l_error_text = "GL Parameters NOT SET up FOR Co. ", l_curr_cmpy_code 
		OUTPUT TO REPORT GCW_rpt_list_exception_report(l_error_text, false) 
		RETURN false 
	END IF 

	LET l_multiledger = true 
	SELECT * INTO glob_rec_structure.* FROM structure 
	WHERE cmpy_code = l_curr_cmpy_code 
	AND type_ind = "L" 
	IF status = NOTFOUND THEN 
		LET l_multiledger = false 
		LET l_ledg_start = 0 
		LET l_ledg_length = 0 
	ELSE 
		LET l_ledg_start = glob_rec_structure.start_num 
		LET l_ledg_length = glob_rec_structure.length_num 
	END IF 
	RETURN true 
END FUNCTION 
########################################################################
# END FUNCTION valid_company()
########################################################################


########################################################################
# FUNCTION create_gl_jnls()
#
#  This FUNCTION sets up the details in the temporary table FOR
#  the non_banking allocations AND creates the journal.  In addition TO
#  the debit AND credit entries specified in WHICS-OPEN, it looks FOR
#  additional debit AND credit accounts FOR the same cross-reference
#  combination AND adds postings FOR those accounts as well.  FOR all
#  entries, IF multi_ledger rules apply, the inter-ledger postings will
#  also be created.
#
########################################################################
FUNCTION create_gl_jnls(p_rpt_idx) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE l_rec_dr_batchdetl RECORD LIKE batchdetl.* 
	DEFINE l_rec_cr_batchdetl RECORD LIKE batchdetl.* 
	DEFINE l_rec_ml_batchdetl RECORD LIKE batchdetl.* 
	DEFINE l_rec_whics_glxref RECORD LIKE whics_glxref.* 
	DEFINE l_call_status INTEGER 
	DEFINE l_db_status INTEGER 
	DEFINE l_jour_num LIKE batchdetl.jour_num 
	DEFINE l_ledg1_acct LIKE batchdetl.acct_code 
	DEFINE l_ledg2_acct LIKE batchdetl.acct_code 
	DEFINE l_err_msg char(80) 
	DEFINE l_alloc_count INTEGER 
	DEFINE l_detail_req SMALLINT 
	DEFINE l_module_text char(16) 
	DEFINE l_comment_text LIKE batchhead.com1_text 

	GOTO bypass 
	LABEL recovery: 
	RETURN false, status 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 

	LET l_alloc_count = 0 
	
	#--------------------------------
	DELETE FROM f_batchdetl WHERE 1=1 

	INITIALIZE l_rec_dr_batchdetl.* TO NULL 

	LET l_rec_dr_batchdetl.cmpy_code = l_curr_cmpy_code 
	LET l_rec_dr_batchdetl.jour_code = glob_rec_loadstatus.jour_code 
	LET l_rec_dr_batchdetl.currency_code = glob_rec_glparms.base_currency_code 
	LET l_rec_dr_batchdetl.conv_qty = 1.0 
	LET l_rec_dr_batchdetl.stats_qty = 0 

	DECLARE c1_allocation CURSOR FOR 
	SELECT * FROM f_allocation 
	WHERE cmpy_code = l_curr_cmpy_code 
	AND tran_type_ind = "WHG" 

	FOREACH c1_allocation INTO glob_rec_allocation.* 
		#
		# Debit entry
		#
		LET l_rec_dr_batchdetl.tran_type_ind = glob_rec_allocation.tran_type_ind 
		LET l_rec_dr_batchdetl.analysis_text = glob_rec_allocation.alloc_key[1,16] 
		LET l_rec_dr_batchdetl.tran_date = glob_rec_allocation.trans_date 
		LET l_rec_dr_batchdetl.ref_text = "Fund ", glob_rec_allocation.fund_ind 
		LET l_rec_dr_batchdetl.acct_code = glob_rec_allocation.dr_acct_code 
		LET l_rec_dr_batchdetl.debit_amt = glob_rec_allocation.dr_cr_amt 
		LET l_rec_dr_batchdetl.for_debit_amt = glob_rec_allocation.dr_cr_amt 
		LET l_rec_dr_batchdetl.credit_amt = 0 
		LET l_rec_dr_batchdetl.for_credit_amt = 0 
		LET l_err_message = "Inserting GL jnl debit entry" 
		
		#----------------------------------------------------
		INSERT INTO f_batchdetl VALUES (l_rec_dr_batchdetl.*) 
		#
		# Credit entry
		#
		LET l_rec_cr_batchdetl.* = l_rec_dr_batchdetl.* 
		LET l_rec_cr_batchdetl.acct_code = glob_rec_allocation.cr_acct_code 
		LET l_rec_cr_batchdetl.credit_amt = glob_rec_allocation.dr_cr_amt 
		LET l_rec_cr_batchdetl.for_credit_amt = glob_rec_allocation.dr_cr_amt 
		LET l_rec_cr_batchdetl.debit_amt = 0 
		LET l_rec_cr_batchdetl.for_debit_amt = 0 
		LET l_err_message = "Inserting GL jnl credit entry" 
		
		#---------------------------------------------------------
		INSERT INTO f_batchdetl VALUES (l_rec_cr_batchdetl.*) 
		#
		# IF multiledger applies, check TO see IF the debit/credit entries
		# cross ledger boundaries AND INSERT the appropriate inter-ledger
		# batch entries
		#
		IF l_multiledger THEN 
			CALL get_ledg_accts(
				l_curr_cmpy_code,
				l_rec_dr_batchdetl.acct_code, 
				l_rec_cr_batchdetl.acct_code, 
				l_ledg_start, 
				l_ledg_length) 
			RETURNING 
				l_ledg1_acct, 
				l_ledg2_acct 
			
			# Credit the debit entry inter_ledger account AND debit the
			# credit entry inter-ledger account
			IF l_ledg1_acct IS NOT NULL AND l_ledg2_acct IS NOT NULL THEN 
				LET l_rec_ml_batchdetl.* = l_rec_cr_batchdetl.* 
				LET l_rec_ml_batchdetl.acct_code = l_ledg1_acct 
				LET l_rec_ml_batchdetl.tran_type_ind = "ML" 
				LET l_err_message = "Inserting GL jnl ML credit entry" 
				
				#---------------------------------------------------------
				INSERT INTO f_batchdetl VALUES (l_rec_ml_batchdetl.*) 
				
				LET l_rec_ml_batchdetl.* = l_rec_dr_batchdetl.* 
				LET l_rec_ml_batchdetl.acct_code = l_ledg2_acct 
				LET l_rec_ml_batchdetl.tran_type_ind = "ML" 
				LET l_err_message = "Inserting GL jnl ML debit entry" 
				
				#---------------------------------------------------------
				INSERT INTO f_batchdetl VALUES (l_rec_ml_batchdetl.*) 
			END IF 
		END IF 
		
		DECLARE c_glxref CURSOR FOR 
		SELECT * FROM whics_glxref 
		WHERE fund_ind = glob_rec_allocation.fund_ind 
		AND xref_code = glob_rec_allocation.alloc_key 

		FOREACH c_glxref INTO l_rec_whics_glxref.* 
			#
			# Check the original debit AND credit accounts match the
			# current accounts FOR this allocatiON KEY. IF NOT, skip
			# the additional disbursements AND REPORT.
			#
			IF l_rec_whics_glxref.whics_dr_acct_code != glob_rec_allocation.dr_acct_code 
			OR l_rec_whics_glxref.whics_cr_acct_code != glob_rec_allocation.cr_acct_code THEN 
				LET l_error_text = "ERROR: Additional postings FOR ",	glob_rec_allocation.alloc_key clipped 
				
				#-------------------------------------------------------------------
				OUTPUT TO REPORT GCW_rpt_list_exception_report(l_error_text, false) 
				#-------------------------------------------------------------------
				
				LET l_error_text = "Initial DR AND CR accounts do NOT ", 	"match - no postings done"
				
				#------------------------------------------------------------------- 
				OUTPUT TO REPORT GCW_rpt_list_exception_report(l_error_text, true) 
				#-------------------------------------------------------------------

				CONTINUE FOREACH 
			END IF 

			#
			# Insert additional debit AND credit entries, replacing the
			# debit AND credit accounts with the cross_reference accounts
			#
			LET l_rec_dr_batchdetl.acct_code = l_rec_whics_glxref.other_dr_acct_code 
			LET l_err_message = "Inserting GL extra debit entry" 
			
			#-------------------------------------------------------
			INSERT INTO f_batchdetl VALUES (l_rec_dr_batchdetl.*) 
			
			LET l_rec_cr_batchdetl.acct_code = l_rec_whics_glxref.other_cr_acct_code 
			LET l_err_message = "Inserting GL extra credit entry" 
			
			#----------------------------------------------------------
			INSERT INTO f_batchdetl VALUES (l_rec_cr_batchdetl.*) 
			#
			# IF multiledger applies, check TO see IF the additional
			# debit/credit entries cross ledger boundaries AND INSERT the
			# appropriate inter-ledger batch entries.
			#
			IF l_multiledger THEN 
				CALL get_ledg_accts(
					l_curr_cmpy_code,
					l_rec_dr_batchdetl.acct_code, 
					l_rec_cr_batchdetl.acct_code, 
					l_ledg_start, 
					l_ledg_length) 
				RETURNING 
					l_ledg1_acct, 
					l_ledg2_acct 
				
				# Credit the debit entry inter_ledger account AND debit the
				# credit entry inter-ledger account
				IF l_ledg1_acct IS NOT NULL AND l_ledg2_acct IS NOT NULL THEN 
					LET l_rec_ml_batchdetl.* = l_rec_cr_batchdetl.* 
					LET l_rec_ml_batchdetl.acct_code = l_ledg1_acct 
					LET l_rec_ml_batchdetl.tran_type_ind = "ML" 
					LET l_err_message = "Inserting extra GL jnl ML credit entry" 
					
					#-----------------------------------------------------
					INSERT INTO f_batchdetl VALUES (l_rec_ml_batchdetl.*) 
					
					LET l_rec_ml_batchdetl.* = l_rec_dr_batchdetl.* 
					LET l_rec_ml_batchdetl.acct_code = l_ledg2_acct 
					LET l_rec_ml_batchdetl.tran_type_ind = "ML" 
					LET l_err_message = "Inserting extra GL jnl ML debit entry" 
					
					#-------------------------------------------------------
					INSERT INTO f_batchdetl VALUES (l_rec_ml_batchdetl.*) 
					
				END IF 
			END IF 
		END FOREACH 
		#
		# Add TO the valid RECORD totals.  Note: each allocation IS
		# comprised of a pair of transaction records FROM the WHICS
		# file.  Therefore RECORD counts AND totals are doubled TO match
		# the totals FROM the original WHICS extract process.
		#
		LET l_alloc_count = l_alloc_count + 2 
		LET l_valid_recs = l_valid_recs + 2 
		LET l_valid_amts = l_valid_amts + (glob_rec_allocation.dr_cr_amt * 2) 
		#
		# Delete the successfully processed allocation pair
		#
		DELETE FROM whics_glalloc WHERE rowid = glob_rec_allocation.dr_rowid 
		DELETE FROM whics_glalloc WHERE rowid = glob_rec_allocation.cr_rowid 
	END FOREACH 
	#
	# CALL the create journal FUNCTION TO create the GL journal batch
	#
	IF l_alloc_count > 0 THEN 
		LET l_detail_req = true 
		LET l_module_text = "WHICS GL i'face" 
		LET l_comment_text = "WHICS-OPEN GL interface" 
		CALL create_jnl_batch(
			l_curr_cmpy_code,
			glob_rec_kandoouser.sign_on_code,
			glob_rec_loadstatus.jour_code, 
			glob_rec_loadstatus.year_num, 
			glob_rec_loadstatus.period_num, 
			"G", 
			l_module_text, 
			l_comment_text, 
			l_module_text, 
			l_detail_req) 
		RETURNING 
			l_call_status, 
			l_db_status, 
			l_jour_num, 
			l_err_message 
		
		IF l_call_status = false THEN 
			LET status = l_db_status 
			GOTO recovery 
		END IF 
		
		LET l_error_text = "Company ", l_curr_cmpy_code," GL Allocations journal ", l_jour_num USING "<<<<<<<<" 
		OUTPUT TO REPORT GCW_rpt_list_exception_report(l_error_text, false) 
		CALL print_batch(p_rpt_idx,l_jour_num) 
	ELSE 
		LET l_error_text = "No GL allocations FOR ", "Company ", l_curr_cmpy_code 
		OUTPUT TO REPORT GCW_rpt_list_exception_report(l_error_text, false) 
	END IF 
	
	# Remove successfully processed allocations
	DELETE FROM f_allocation 
	WHERE cmpy_code = l_curr_cmpy_code 
	AND tran_type_ind = "WHG" 
	
	WHENEVER ERROR stop
	 
	RETURN true, 0 
END FUNCTION 
########################################################################
# END FUNCTION create_gl_jnls()
########################################################################


########################################################################
# FUNCTION create_bank_jnls(p_rpt_idx)
#
#  This FUNCTION sets up the details in the temporary table FOR
#  the banking allocations AND creates the journal.  It also creates
#  cash book entries in the banking table TO match the journals.
#  A single journal IS created FOR each allocation RECORD as there
#  should be only one RECORD per payment type AND date.
#
########################################################################
FUNCTION create_bank_jnls(p_rpt_idx) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE l_rec_dr_batchdetl RECORD LIKE batchdetl.* 
	DEFINE l_rec_cr_batchdetl RECORD LIKE batchdetl.* 
	DEFINE l_rec_banking RECORD LIKE banking.* 
	DEFINE l_call_status INTEGER 
	DEFINE l_db_status INTEGER 
	DEFINE l_jour_num LIKE batchhead.jour_num 
	DEFINE l_detail_req SMALLINT 
	DEFINE l_module_text char(16) 
	DEFINE l_comment_text LIKE batchhead.com1_text 

	GOTO bypass 
	LABEL recovery: 
	RETURN false, status 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 

	LET l_error_text = "Company ", l_curr_cmpy_code, " banking" 
	OUTPUT TO REPORT GCW_rpt_list_exception_report(l_error_text, false) 
	LET l_error_text = "Account Jnl amount",	" source" 
	
	#----------------------------------------------------------------
	OUTPUT TO REPORT GCW_rpt_list_exception_report(l_error_text, true) 
	
	LET l_detail_req = true 
	LET l_module_text = "WHICS GL i'face" 
	LET l_comment_text = "WHICS-OPEN GL/CB interface" 
	#
	# Set up static data
	#
	INITIALIZE l_rec_dr_batchdetl.* TO NULL 
	
	LET l_rec_dr_batchdetl.cmpy_code = l_curr_cmpy_code 
	LET l_rec_dr_batchdetl.jour_code = glob_rec_glparms.cb_code 
	LET l_rec_dr_batchdetl.currency_code = glob_rec_glparms.base_currency_code 
	LET l_rec_dr_batchdetl.conv_qty = 1.0 
	LET l_rec_dr_batchdetl.stats_qty = 0 
	
	INITIALIZE l_rec_banking.* TO NULL 
	
	LET l_rec_banking.bk_cmpy = l_curr_cmpy_code 
	LET l_rec_banking.bk_year = glob_rec_loadstatus.year_num 
	LET l_rec_banking.bk_per = glob_rec_loadstatus.period_num 
	LET l_rec_banking.bk_enter = glob_rec_kandoouser.sign_on_code 
	LET l_rec_banking.doc_num = 0 
	
	DECLARE c2_allocation CURSOR FOR 
	SELECT * FROM f_allocation 
	WHERE cmpy_code = l_curr_cmpy_code 
	AND tran_type_ind = "WHC" 

	FOREACH c2_allocation INTO glob_rec_allocation.* 
		#
		# Empty the table - one gl journal batch per record
		#

		#--------------------------------
		DELETE FROM f_batchdetl WHERE 1=1 
		#
		# Debit entry
		#
		LET l_rec_dr_batchdetl.tran_type_ind = glob_rec_allocation.tran_type_ind 
		LET l_rec_dr_batchdetl.analysis_text = glob_rec_allocation.alloc_key[1,16] 
		LET l_rec_dr_batchdetl.tran_date = glob_rec_allocation.trans_date 
		LET l_rec_dr_batchdetl.ref_text = "Fund ", glob_rec_allocation.fund_ind 
		LET l_rec_dr_batchdetl.acct_code = glob_rec_allocation.dr_acct_code 
		LET l_rec_dr_batchdetl.debit_amt = glob_rec_allocation.dr_cr_amt 
		LET l_rec_dr_batchdetl.for_debit_amt = glob_rec_allocation.dr_cr_amt 
		LET l_rec_dr_batchdetl.credit_amt = 0 
		LET l_rec_dr_batchdetl.for_credit_amt = 0 
		LET l_err_message = "Inserting bank jnl debit entry" 
		
		#----------------------------------------------------
		INSERT INTO f_batchdetl VALUES (l_rec_dr_batchdetl.*) 
		#
		# Credit entry
		#
		LET l_rec_cr_batchdetl.* = l_rec_dr_batchdetl.* 
		LET l_rec_cr_batchdetl.acct_code = glob_rec_allocation.cr_acct_code 
		LET l_rec_cr_batchdetl.credit_amt = glob_rec_allocation.dr_cr_amt 
		LET l_rec_cr_batchdetl.for_credit_amt = glob_rec_allocation.dr_cr_amt 
		LET l_rec_cr_batchdetl.debit_amt = 0 
		LET l_rec_cr_batchdetl.for_debit_amt = 0 
		LET l_err_message = "Inserting bank jnl credit entry"
		
		#------------------------------------------------------- 
		INSERT INTO f_batchdetl VALUES (l_rec_cr_batchdetl.*) 
		#
		# CALL the create journal FUNCTION TO create the GL journal batch
		#

		CALL create_jnl_batch(
			l_curr_cmpy_code,
			glob_rec_kandoouser.sign_on_code, 
			glob_rec_glparms.cb_code, 
			glob_rec_loadstatus.year_num, 
			glob_rec_loadstatus.period_num, 
			"C", 
			l_module_text, 
			l_comment_text, 
			glob_rec_allocation.alloc_key[1,16], 
			l_detail_req) 
		RETURNING 
			l_call_status, 
			l_db_status, 
			l_jour_num, 
			l_err_message 
		
		IF l_call_status = false THEN 
			LET status = l_db_status 
			GOTO recovery 
		END IF 

		CALL print_batch(p_rpt_idx,l_jour_num) 
		#
		# IF both accounts are bank accounts, create transfer cash book
		# entries, OTHERWISE create a sundry debit OR credit
		#
		IF glob_rec_allocation.dr_bank_flag = true AND glob_rec_allocation.cr_bank_flag = false THEN 
			LET l_rec_banking.bk_acct = glob_rec_allocation.dr_acct_code 
			LET l_rec_banking.bk_type = "DP" 
			LET l_rec_banking.bk_bankdt = glob_rec_allocation.trans_date 
			LET l_rec_banking.bk_desc = "WHICS banking - ",	glob_rec_allocation.alloc_key clipped 
			LET l_rec_banking.bk_cred = glob_rec_allocation.dr_cr_amt 
			LET l_rec_banking.base_cred_amt = glob_rec_allocation.dr_cr_amt 
			LET l_rec_banking.bk_debit = 0 
			LET l_rec_banking.base_debit_amt = 0 
			LET l_rec_banking.bank_dep_num = l_jour_num 
			LET l_err_message = "Inserting deposit cash book entry"
			 
			#----------------------------------------------------
			INSERT INTO banking VALUES (l_rec_banking.*) 
			
			LET l_error_text = 
				l_rec_banking.bk_acct," ", 
				l_jour_num USING "#####&", 
				l_rec_banking.bk_cred USING "-------&.&&", " DR ", 
				glob_rec_allocation.alloc_key[1,27] 
			
			#---------------------------------------------------------------------
			OUTPUT TO REPORT GCW_rpt_list_exception_report(l_error_text, true) 
			
		END IF 

		IF glob_rec_allocation.cr_bank_flag = true AND glob_rec_allocation.dr_bank_flag = false THEN 
			LET l_rec_banking.bk_acct = glob_rec_allocation.cr_acct_code 
			LET l_rec_banking.bk_type = "BC" 
			LET l_rec_banking.bk_bankdt = glob_rec_allocation.trans_date 
			LET l_rec_banking.bk_desc = "WHICS banking - ",	glob_rec_allocation.alloc_key clipped 
			LET l_rec_banking.bk_debit = glob_rec_allocation.dr_cr_amt 
			LET l_rec_banking.base_debit_amt = glob_rec_allocation.dr_cr_amt 
			LET l_rec_banking.bk_cred = 0 
			LET l_rec_banking.base_cred_amt = 0 
			LET l_rec_banking.bank_dep_num = l_jour_num 
			LET l_err_message = "Inserting debit cash book entry" 

			#--------------------------------------------
			INSERT INTO banking VALUES (l_rec_banking.*) 
			
			LET l_error_text = 
				l_rec_banking.bk_acct," ", 
				l_jour_num USING "#####&", 
				l_rec_banking.bk_debit USING "-------&.&&", " CR ", 
				glob_rec_allocation.alloc_key[1,27] 
			#----------------------------------------------------------------------------
			OUTPUT TO REPORT GCW_rpt_list_exception_report(l_error_text, true) 
		END IF 

		IF glob_rec_allocation.dr_bank_flag = true AND glob_rec_allocation.cr_bank_flag = true THEN 
			LET l_rec_banking.bk_acct = glob_rec_allocation.dr_acct_code 
			LET l_rec_banking.bk_type = "TI" 
			LET l_rec_banking.bk_bankdt = glob_rec_allocation.trans_date 
			LET l_rec_banking.bk_desc = "WHICS transfer - ",glob_rec_allocation.alloc_key clipped 
			LET l_rec_banking.bk_cred = glob_rec_allocation.dr_cr_amt 
			LET l_rec_banking.base_cred_amt = glob_rec_allocation.dr_cr_amt 
			LET l_rec_banking.bk_debit = 0 
			LET l_rec_banking.base_debit_amt = 0 
			LET l_rec_banking.bank_dep_num = l_jour_num 
			LET l_err_message = "Inserting transfer in cash book entry" 

			INSERT INTO banking VALUES (l_rec_banking.*) 

			LET l_error_text = 
				l_rec_banking.bk_acct," ", 
				l_jour_num USING "#####&", 
				l_rec_banking.bk_cred USING "-------&.&&", " TI ", 
				glob_rec_allocation.alloc_key[1,27] 
			
			#-------------------------------------------------------------------
			OUTPUT TO REPORT GCW_rpt_list_exception_report(l_error_text, true) 
			
			LET l_rec_banking.bk_acct = glob_rec_allocation.cr_acct_code 
			LET l_rec_banking.bk_type = "TO" 
			LET l_rec_banking.bk_bankdt = glob_rec_allocation.trans_date 
			LET l_rec_banking.bk_desc = "WHICS transfer - ", glob_rec_allocation.alloc_key clipped 
			LET l_rec_banking.bk_debit = glob_rec_allocation.dr_cr_amt 
			LET l_rec_banking.base_debit_amt = glob_rec_allocation.dr_cr_amt 
			LET l_rec_banking.bk_cred = 0 
			LET l_rec_banking.base_cred_amt = 0 
			LET l_rec_banking.bank_dep_num = l_jour_num 
			LET l_err_message = "Inserting transfer out cash book entry" 
			
			#---------------------------------------------------------
			INSERT INTO banking VALUES (l_rec_banking.*) 
			
			LET l_error_text = 
				l_rec_banking.bk_acct," ", 
				l_jour_num USING "#####&", 
				l_rec_banking.bk_debit USING "-------&.&&", " TO ", 
				glob_rec_allocation.alloc_key[1,27] 

			#------------------------------------------------------------------
			OUTPUT TO REPORT GCW_rpt_list_exception_report(l_error_text, true) 

		END IF 

		#
		# Add TO the valid RECORD totals.  Note: each allocation IS
		# comprised of a pair of transaction records FROM the WHICS
		# file.  Therefore RECORD counts AND totals are doubled TO match
		# the totals FROM the original WHICS extract process.
		#
		LET l_valid_recs = l_valid_recs + 2 
		LET l_valid_amts = l_valid_amts + (glob_rec_allocation.dr_cr_amt * 2) 
		#
		# Delete the successfully processed allocation pair
		#
		DELETE FROM whics_glalloc WHERE rowid = glob_rec_allocation.dr_rowid 
		DELETE FROM whics_glalloc WHERE rowid = glob_rec_allocation.cr_rowid 
	END FOREACH 
	
	# Remove successfully processed allocations
	DELETE FROM f_allocation 
	WHERE cmpy_code = l_curr_cmpy_code 
	AND tran_type_ind = "WHC" 
	WHENEVER ERROR stop 

	RETURN true, 0 
END FUNCTION 
########################################################################
# END FUNCTION create_bank_jnls(p_rpt_idx)
########################################################################


########################################################################
# FUNCTION report_invalid_tx()
#
#  This FUNCTION reads through any remaining records in the allocations
#  table AND reports them.  IF any records remain AFTER the General
#  Ledger AND Cash Book entries have been processed, it must be because
#  either the company code associated with the fund was NOT valid OR
#  they do NOT constitute matching DR/CR pairs.  This can only occur if
#  there IS a problem with SET up OR a change in the way in which the
#  WHICS file IS created.  Details are reported TO allow the journals
#  TO be created manually,IF required.
########################################################################
FUNCTION report_invalid_tx() 
	DEFINE l_rowid INTEGER 

	GOTO bypass 
	LABEL recovery: 
	RETURN false, status 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 

	LET l_error_text = "Checking FOR Invalid transactions" 

	#--------------------------------------------------------------------
	OUTPUT TO REPORT GCW_rpt_list_exception_report(l_error_text,false) 

	LET l_display_text = l_error_text clipped 
	CALL display_progress(l_display_text)
	 
	LET l_error_text = "TX Date Fund/Account ", "DR/CR - Amount - key" 

	#-------------------------------------------------------------------
	OUTPUT TO REPORT GCW_rpt_list_exception_report(l_error_text, true) 
	
	DECLARE c2_whics_glalloc CURSOR FOR 
	SELECT *, rowid FROM whics_glalloc 

	FOREACH c2_whics_glalloc INTO glob_rec_whics_glalloc.*, l_rowid 
		LET l_invalid_recs = l_invalid_recs + 1 
		LET l_invalid_amts = l_invalid_amts + glob_rec_whics_glalloc.dr_cr_amt 
		LET l_error_text = 
			glob_rec_whics_glalloc.trans_code, " ", 
			glob_rec_whics_glalloc.trans_date USING "dd/mm/yy"," ", 
			glob_rec_whics_glalloc.fund_ind, "/", 
			glob_rec_whics_glalloc.acct_code, " ", 
			glob_rec_whics_glalloc.dr_cr_ind, " ", 
			glob_rec_whics_glalloc.dr_cr_amt USING "--------&.&&", " ", 
			glob_rec_whics_glalloc.com_text[1,16] 
		
		OUTPUT TO REPORT GCW_rpt_list_exception_report(l_error_text,true) 
		
		#-------------------------------------------------
		DELETE FROM whics_glalloc WHERE rowid = l_rowid 
	END FOREACH 
	
	WHENEVER ERROR stop
	 
	RETURN true, 0 
END FUNCTION 
########################################################################
# FUNCTION report_invalid_tx()
########################################################################


########################################################################
# FUNCTION print_batch(p_rpt_idx,p_jour_num)
#
#
########################################################################
FUNCTION print_batch(p_rpt_idx,p_jour_num)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx] 
	DEFINE p_jour_num LIKE batchhead.jour_num 
	DEFINE l_rec_batchdetl RECORD LIKE batchdetl.* 

	#
	#  The field invalid_acct IS a global, which IS SET TO TRUE by
	#  the posting REPORT IF any of the accounts are either invalid
	#  OR NOT OPEN FOR the posting period.
	#
	LET l_invalid_acct = false 
	DECLARE c_batchdetl CURSOR FOR 
	SELECT * 
	FROM batchdetl 
	WHERE jour_num = p_jour_num 
	AND cmpy_code = l_curr_cmpy_code 
	ORDER BY jour_num,seq_num 

	FOREACH c_batchdetl INTO l_rec_batchdetl.* 
		OUTPUT TO REPORT post_report2(p_rpt_idx,
		l_rec_batchdetl.*, 
		glob_rec_kandoouser.sign_on_code, 
		glob_rec_loadstatus.year_num, 
		glob_rec_loadstatus.period_num, 
		glob_rec_glparms.base_currency_code) 
	END FOREACH 

	IF l_invalid_acct THEN 
		LET l_error_text = "WARNING: Invalid OR closed account in batch ", p_jour_num USING "<<<<<<<<" 
		OUTPUT TO REPORT GCW_rpt_list_exception_report(l_error_text,false) 
	END IF 

END FUNCTION 
########################################################################
# END FUNCTION print_batch(p_rpt_idx,p_jour_num)
########################################################################


########################################################################
# FUNCTION display_progress(p_text_line)
#
#
########################################################################
FUNCTION display_progress(p_text_line) 
	DEFINE p_text_line char(60) 
	DEFINE l_idx SMALLINT 

	FOR l_idx = 1 TO 9 
		IF l_arr_comments[l_idx] IS NULL THEN 
			EXIT FOR 
		END IF 
	END FOR 
	# IF the comment ARRAY IS full, CLEAR AND start again AT the top
	IF l_idx > 9 THEN 
		FOR l_idx = 1 TO 9 
			INITIALIZE l_arr_comments[l_idx] TO NULL 
		END FOR 
		LET l_idx = 1 
	END IF 
	LET l_arr_comments[l_idx] = p_text_line 
	DISPLAY l_arr_comments[l_idx] TO sr_comments[l_idx].comments 

END FUNCTION 
########################################################################
# END FUNCTION display_progress(p_text_line)
########################################################################


########################################################################
# FUNCTION GCW_exit_program()
#
#
########################################################################
FUNCTION gcw_exit_program() 

	#  Allows the user TO abandon the load IF there IS a lock AND
	#  restart later
	LET l_error_text = "Load IS incomplete - restart required" 

	#-------------------------------------------------------------------
	OUTPUT TO REPORT GCW_rpt_list_exception_report(l_error_text, false) 
	
	LET l_display_text = l_error_text clipped 
	CALL display_progress(l_display_text) 
	
	ERROR kandoomsg2("U",7016,"")	#7016 Error Occurred. Refer TO REPORT FOR more information.
	WHENEVER ERROR CONTINUE 

	UPDATE loadstatus 
	SET load_running_flag = "N" 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND run_text = "GCW" 

	WHENEVER ERROR stop 

	EXIT PROGRAM 
END FUNCTION 
########################################################################
#END FUNCTION GCW_exit_program()
########################################################################


########################################################################
# REPORT GCW_rpt_list_exception_report(p_report_text,p_follow_line)
#
#
########################################################################
REPORT GCW_rpt_list_exception_report(p_rpt_idx,p_report_text,p_follow_line)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx] 
	DEFINE p_report_text char(65) 
	DEFINE p_follow_line SMALLINT 
	DEFINE l_offset1 SMALLINT 
	DEFINE l_offset2 SMALLINT 
	DEFINE l_line1 char(132) 
	DEFINE l_time DATETIME hour TO second 

	OUTPUT 
	left margin 1 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 01, "Time", 
			COLUMN 11, "Comments" 
			
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 


		ON EVERY ROW 
			IF p_follow_line THEN 
				PRINT COLUMN 011, p_report_text clipped 
			ELSE 
				SKIP 1 line 
				LET l_time = CURRENT 
				PRINT COLUMN 001, l_time, 
				COLUMN 011, p_report_text clipped 
			END IF 

		ON LAST ROW 
			SKIP 1 line 
			PRINT COLUMN 011, "WHICS-OPEN GL Load complete" 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	
		

END REPORT 

########################################################################
# END REPORT GCW_rpt_list_exception_report(p_report_text,p_follow_line)
########################################################################