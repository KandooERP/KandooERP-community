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
# \brief module : PSA
# Purpose : WHICS-OPEN AP Interface Program

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl" 
GLOBALS "../ap/P_AP_GLOBALS.4gl" 

############################################################
# MODULE Scope Variables
############################################################
DEFINE modu_rec_loadstatus RECORD LIKE loadstatus.* 
DEFINE modu_rec_bank RECORD LIKE bank.* 
DEFINE modu_rec_vendor RECORD LIKE vendor.* 
DEFINE modu_rec_voucher RECORD LIKE voucher.* 
DEFINE modu_trans_cmpy_code LIKE company.cmpy_code 
DEFINE modu_fund_num LIKE whics_payments.fund_num 
DEFINE modu_dr_acct_code LIKE whics_payments.dr_acct_code 
DEFINE modu_cr_acct_code LIKE whics_payments.cr_acct_code 
DEFINE modu_trans_date LIKE whics_payments.proc_date 
DEFINE modu_rpt1_note LIKE rmsreps.report_text 
DEFINE modu_rpt1_wid LIKE rmsreps.report_width_num
DEFINE modu_error_text CHAR(60)
DEFINE modu_record_count INTEGER 
DEFINE modu_valid_recs INTEGER
DEFINE modu_invalid_recs INTEGER
DEFINE modu_valid_amts LIKE voucher.total_amt 
DEFINE modu_invalid_amts LIKE voucher.total_amt
DEFINE modu_insert_phase SMALLINT 
DEFINE modu_complete SMALLINT
DEFINE modu_arr_comments ARRAY[9] OF CHAR(60) 
DEFINE modu_err_message CHAR(80) 

############################################################
# MAIN
#
#
############################################################
MAIN 

	#Initial UI Init
	CALL setModuleId("PSA") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_p_ap() #init p/ap module 

	SELECT * INTO glob_rec_company.* 
	FROM company 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	#
	# Initialise global variables
	#
	LET modu_record_count = 0 
	LET modu_insert_phase = 1 
	LET modu_complete = 99 

	OPEN WINDOW wp241 with FORM "P241" 
	CALL windecoration_p("P241") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 


	MENU " WHICS AP Load" 

		BEFORE MENU 
			CALL publish_toolbar("kandoo","PSA","menu-whics_ap_load-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "Load" 
			#  COMMAND "Load" " Commence Voucher/Cheque load process"
			IF start_load() THEN 
				IF update_status("Y") THEN 
					CALL insert_data() 
					NEXT option "Print Manager" 
				END IF 
			END IF 


		ON ACTION "Print Manager" 
			#COMMAND KEY ("P",f11) "Print" " Print OR View using RMS"
			CALL run_prog("URS","","","","") 
			NEXT option "Exit" 

		ON ACTION "CANCEL" 
			#COMMAND KEY(interrupt,"E")"Exit" " Exit AP Load"
			LET int_flag = true 
			LET quit_flag = true 
			EXIT MENU 


	END MENU 

	CLOSE WINDOW wp241 

END MAIN 


############################################################
# FUNCTION start_load()
#
#
############################################################
FUNCTION start_load() 
	DEFINE l_prev_file_text LIKE loadstatus.file_text	
	DEFINE l_msgresp LIKE language.yes_flag 

	#
	# Retrieve details of the previous load.
	#
	SELECT * INTO modu_rec_loadstatus.* FROM loadstatus 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND run_text = "PSA" 
	IF status = NOTFOUND THEN 
		# 7040 "Load STATUS  FOR PSA cannot be found - cannot load
		LET l_msgresp = kandoomsg("U",7040,"WHICS-OPEN AP") 
		RETURN false 
	END IF 
	#
	# IF this IS a new load run, save the previously entered file name FOR
	# DISPLAY AND THEN SET TO NULL TO discourage the already loaded name
	# being entered again by default.  IF it IS a restart, leave name
	# intact, as file name IS NOT re-entered in this instance.
	#
	LET l_prev_file_text = modu_rec_loadstatus.file_text 
	IF modu_rec_loadstatus.status_code = modu_complete THEN 
		LET modu_rec_loadstatus.file_text = NULL 
	END IF 
	DISPLAY BY NAME modu_rec_loadstatus.file_text, 
	modu_rec_loadstatus.path_text, 
	modu_rec_loadstatus.entry_code, 
	modu_rec_loadstatus.entry_time, 
	l_prev_file_text, 
	modu_rec_loadstatus.status_code, 
	modu_rec_loadstatus.status_time, 
	modu_rec_loadstatus.status_text 

	#
	# IF the load was NOT complete, need TO finish the previous load
	# before allowing new data TO be loaded INTO the table. Skip the
	# file entry section AND go straight TO processing.
	#
	SELECT count(*) INTO modu_record_count 
	FROM whics_payments 
	IF modu_record_count IS NULL THEN 
		LET modu_record_count = 0 
	END IF 
	IF modu_rec_loadstatus.status_code < modu_complete OR 
	modu_record_count <> 0 THEN 
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



############################################################
# FUNCTION open_file()
#
#
############################################################
FUNCTION open_file() 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET l_msgresp = kandoomsg("U",1020,"Load File") 
	#1020 Enter Load File details; Ok TO continue.
	INPUT BY NAME modu_rec_loadstatus.file_text, 
	modu_rec_loadstatus.path_text WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","PSA","inp-load_status-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN 
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


############################################################
# FUNCTION valid_file()
#
#
############################################################
FUNCTION valid_file() 
	DEFINE l_filename CHAR(80) 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET l_filename = modu_rec_loadstatus.path_text clipped, "/", 
	modu_rec_loadstatus.file_text clipped 
	WHENEVER ERROR CONTINUE 
	LOAD FROM l_filename INSERT INTO whics_payments 
	WHENEVER ERROR stop 
	IF status != 0 THEN 
		LET l_msgresp=kandoomsg("U",9115,"") 
		#9115 Load file does NOT exist; Try again."
		RETURN false 
	END IF 
	SELECT unique 1 FROM whics_payments 
	IF status = NOTFOUND THEN 
		LET l_msgresp=kandoomsg("U",9119,"") 
		#9119 Incorrect file FORMAT OR blank lines detected.
		RETURN false 
	END IF 
	RETURN true 
END FUNCTION 

############################################################
# FUNCTION move_load_file()
#
#
############################################################
FUNCTION move_load_file() 
	DEFINE l_move_path CHAR(100) 
	DEFINE l_move_file CHAR(100) 
	DEFINE l_load_file CHAR(100) 
	DEFINE l_runner CHAR(300) 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET l_load_file = modu_rec_loadstatus.path_text clipped, "/", 
	modu_rec_loadstatus.file_text clipped 
	LET l_move_path = modu_rec_loadstatus.path_text clipped, "/", 
	modu_rec_loadstatus.file_text clipped, ".tmp" 
	WHILE true 
		#huho changed TO os.path() method
		IF os.path.exists(l_move_path) THEN 
			#LET l_runner = " [ -f ",l_move_path clipped," ] 2>>", trim(get_settings_logFile())
			#run l_runner returning ret_code
			#IF ret_code THEN
			EXIT WHILE 
		ELSE 
			LET l_msgresp=kandoomsg("P",9179,"") 
			#P9179 - Cannot move load file; File already exists
			LET l_move_file = fgl_winprompt(5,5, "Enter Move file name", "", 50, 0) 


			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
				RETURN 
			ELSE 
				LET l_move_path = modu_rec_loadstatus.path_text clipped, "/", 
				l_move_file clipped 
			END IF 
		END IF 
	END WHILE 
	LET l_runner = " mv ", l_load_file clipped, " ", l_move_path clipped, 
	" 2> /dev/NULL" 

	RUN l_runner 

END FUNCTION 

############################################################
# FUNCTION update_status(p_mode)
#
#
############################################################
FUNCTION update_status(p_mode) 
	DEFINE p_mode CHAR(1) 
	DEFINE l_load_running_flag LIKE loadstatus.load_running_flag 
	DEFINE l_msgresp LIKE language.yes_flag 

	GOTO upd_bypass 
	LABEL upd_recovery: 
	IF error_recover(modu_err_message, status) != "Y" THEN 
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
		AND run_text = "PSA" 
		FOR UPDATE 
		OPEN c_loadstatus 
		FETCH c_loadstatus INTO l_load_running_flag 
		IF status <> 0 THEN 
			# 7036 "Load STATUS NOT SET up FOR WHICS-OPEN AP -
			# cannot run posting."
			LET l_msgresp = kandoomsg("U",7040,"WHICS-OPEN AP") 
			ROLLBACK WORK 
			RETURN false 
		END IF 
		IF p_mode = "Y" AND l_load_running_flag = "Y" THEN 
			# 7042 "Load IS already running."
			LET l_msgresp = kandoomsg("U",7042,"") 
			ROLLBACK WORK 
			RETURN false 
		END IF 
		# Set up STATUS flags according TO whether we are running, restarting
		# OR completing
		IF p_mode = "Y" THEN 
			IF modu_rec_loadstatus.status_code < modu_complete THEN 
				LET modu_rec_loadstatus.status_time = CURRENT year TO second 
				LET modu_rec_loadstatus.status_text = 
				"PSA - load restarted by ", glob_rec_kandoouser.sign_on_code clipped 
				LET modu_rec_loadstatus.load_running_flag = "Y" 
			ELSE 
				LET modu_rec_loadstatus.entry_code = glob_rec_kandoouser.sign_on_code 
				LET modu_rec_loadstatus.entry_time = CURRENT year TO second 
				LET modu_rec_loadstatus.status_code = modu_insert_phase 
				LET modu_rec_loadstatus.status_text = "PSA - commenced data INSERT" 
				LET modu_rec_loadstatus.status_time = CURRENT year TO second 
				LET modu_rec_loadstatus.load_running_flag = "Y" 
				LET modu_rec_loadstatus.file_text = modu_rec_loadstatus.file_text 
			END IF 
		ELSE 
			LET modu_rec_loadstatus.status_code = modu_complete 
			LET modu_rec_loadstatus.status_text = "PSA - completed load" 
			LET modu_rec_loadstatus.status_time = CURRENT year TO second 
			LET modu_rec_loadstatus.load_running_flag = "N" 
		END IF 
		LET modu_err_message = "PSA - Updating loadstatus post running flag" 
		UPDATE loadstatus 
		SET entry_code = modu_rec_loadstatus.entry_code, 
		entry_time = modu_rec_loadstatus.entry_time, 
		status_code = modu_rec_loadstatus.status_code, 
		status_text = modu_rec_loadstatus.status_text, 
		status_time = modu_rec_loadstatus.status_time, 
		load_running_flag = modu_rec_loadstatus.load_running_flag, 
		file_text = modu_rec_loadstatus.file_text, 
		path_text = modu_rec_loadstatus.path_text 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND run_text = "PSA" 

	COMMIT WORK 

	WHENEVER ERROR stop 

	RETURN true 
END FUNCTION 

############################################################
# FUNCTION insert_data()
#
#
#  The WHICS-OPEN AP Interface loads details of cheques created via
#  the WHICS-OPEN membership system AND records them in database FOR
#  the purpose of cash book reconciliation.  As individual payee
#  details are maintained in WHICS, the cheques are all allocated TO
#  a Sundry Vendor which IS synonomous with a bank account.  WHICS
#  provides details of the cheque number AND amount, the account
#  which IS TO be credited AND the account which IS TO be debited.
#  Within KandooERP, the credit account must match a bank code with an
#  associated vendor code.  TO maintain AP ledger integrity, the debit
#  posted IS achieved by raising a voucher, distributed TO the debit
#  account, against which the cheque(s) are applied.  TO reduce the
#  number of transactions transferred, a single voucher IS created FOR
#  each combination of bank/vendor (credit account) debit account AND
#  date AND each cheque matching those accounts IS applied TO the
#  voucher.  There IS an additional translation step that matches the
#  fund TO which the cheque belongs TO a given company code in KandooERP.
#
#  The load process consists of the following steps:
#
#  1 - SELECT each unique combination of fund, debit account, credit
#      account AND date
#  2 - FOR each combination, validate the associated company code,
#      bank AND vendor codes.  IF no valid company/bank/vendor
#      can be found, all cheques with that combination are rejected.
#  3 - Initialise the voucher RECORD based on vendor AND date defaults.
#      IF the  program cannot establish valid voucher default details,
#      all cheques with that company/bank/vendor/date combination are
#      rejected.  Note that cheques are grouped by date as the date
#      determines the year AND period TO which the transactions are
#      allocated AND the cheques AND voucher must post TO the same
#      period.  Any given interface file may contain cheques FROM
#      more than one processing date.
#  4 - FOR each cheque matching the company/bank/vendor/DATE, ensure
#      that the cheque number IS unique FOR that bank AND that the
#      payment details are valid.  IF so, add the cheque TO the
#      KandooERP table.  WHEN all cheques have been successfully
#      processed, a voucher AND distribution are created FOR the total
#      of those cheques.  IF any error occurs, no cheques are inserted
#      AND the voucher IS NOT created.
#  5 - Successfully processed cheques are deleted FROM the load table.
#      IF any payments remain in the load table AFTER processing, the
#      load IS regarded as incomplete.  The records will remain in the
#      table until the reasons FOR rejection are resolved OR they
#      are explicity deleted (FOR instance, IF the same file has been
#      loaded twice, it may be necessary TO delete the load table
#      contents).  A new file cannot be loaded until the table IS empty.
#
############################################################
FUNCTION insert_data() 
--	DEFINE l_output1 CHAR(60)
	DEFINE l_status SMALLINT 
	DEFINE l_reject_count INTEGER 
	DEFINE l_reject_amt LIKE voucher.total_amt 
--	DEFINE l_rpt1_length LIKE rmsreps.page_length_num
	DEFINE i SMALLINT
--	DEFINE l_page_num LIKE rmsreps.page_num
	DEFINE l_rpt_idx SMALLINT  #report array index	

	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start(getmoduleid(),"PSA_rpt_list_exception","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT PSA_rpt_list_exception TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	FOR i = 1 TO 9 
		INITIALIZE modu_arr_comments[i] TO NULL 
	END FOR 
	OPEN WINDOW U157 with FORM "U157" 
	CALL winDecoration_u("U157") 

	LET modu_valid_recs = 0 
	LET modu_valid_amts = 0 
	LET modu_invalid_recs = 0 
	LET modu_invalid_amts = 0 

	DECLARE c_whics_voucher CURSOR with HOLD FOR 
	SELECT unique fund_num, dr_acct_code, cr_acct_code, proc_date 
	FROM whics_payments 

	FOREACH c_whics_voucher 
		INTO modu_fund_num, 
		modu_dr_acct_code, 
		modu_cr_acct_code, 
		modu_trans_date 

		IF set_up_vendor_voucher(l_rpt_idx) THEN 
			CALL create_cheques_and_voucher(l_rpt_idx) 
		ELSE 
			LET modu_error_text = "Payments skipped FOR ", 
			modu_fund_num USING "&&", 
			" - CR ", modu_cr_acct_code clipped, 
			" - DR ", modu_dr_acct_code clipped

			#---------------------------------------------------------
			OUTPUT TO REPORT PSA_rpt_list_exception(l_rpt_idx,
			modu_error_text, true)
			#---------------------------------------------------------
			 
			SELECT count(*), sum(pay_amt) 
			INTO l_reject_count, l_reject_amt 
			FROM whics_payments 
			WHERE fund_num = modu_fund_num 
			AND dr_acct_code = modu_dr_acct_code 
			AND cr_acct_code = modu_cr_acct_code 
			AND proc_date = modu_trans_date 
			LET modu_invalid_recs = modu_invalid_recs + l_reject_count 
			LET modu_invalid_amts = modu_invalid_amts + l_reject_amt 
			CONTINUE FOREACH 
		END IF 
	END FOREACH 

	LET modu_error_text = modu_valid_recs USING "#####&", 
	" cheques loaded: Total value ", 
	modu_valid_amts USING "--------&.&&" 

	#---------------------------------------------------------
	OUTPUT TO REPORT PSA_rpt_list_exception(l_rpt_idx,
	modu_error_text, false) 
	#---------------------------------------------------------
 
	LET modu_error_text = modu_invalid_recs USING "#####&",	" cheques rejected: Total value ", 
	modu_invalid_amts USING "--------&.&&" 

	#---------------------------------------------------------
	OUTPUT TO REPORT PSA_rpt_list_exception(l_rpt_idx,
	modu_error_text, true) 
	#---------------------------------------------------------
 
	IF modu_invalid_recs <> 0 THEN 
		LET modu_error_text = "Load incomplete - restart required " 

		#---------------------------------------------------------
		OUTPUT TO REPORT PSA_rpt_list_exception(l_rpt_idx,
		modu_error_text, false) 
		#---------------------------------------------------------

	ELSE 
		LET modu_error_text = "Load completed successfully" 

		#---------------------------------------------------------
		OUTPUT TO REPORT PSA_rpt_list_exception(l_rpt_idx,
		modu_error_text, false) 
		#---------------------------------------------------------
		
	END IF 

	CLOSE WINDOW U157 

	#------------------------------------------------------------
	FINISH REPORT PSA_rpt_list_exception
	CALL rpt_finish("PSA_rpt_list_exception")
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
# FUNCTION set_up_vendor_voucher(p_rpt_idx)
#
#  This step performs the required look-up AND edit processing TO
#  determine the correct vendor AND bank code FOR the cheque payments
#  with the current combination of fund (ie. company), credit account
#  code (ie. bank account).  It also ensures that the debit account
#  IS valid within KandooERP.  IF any of these edits fail, a "FALSE"
#  STATUS IS returned AND AND the transactions matching this combination
#  are skipped.
############################################################
FUNCTION set_up_vendor_voucher(p_rpt_idx) 
	DEFINE p_rpt_idx SMALLINT  #report array index
	DEFINE l_rec_loadxref RECORD LIKE loadxref.*
	DEFINE l_text_line CHAR(60) 
	DEFINE l_call_status SMALLINT 

	LET l_text_line = "Validating Fund ", modu_fund_num USING "&&", 
	" CR ", modu_cr_acct_code clipped, 
	" DR ", modu_dr_acct_code clipped 
	CALL display_progress(l_text_line) 
	INITIALIZE l_rec_loadxref.* TO NULL 
	LET l_rec_loadxref.ext_code = modu_fund_num USING "&&" 
	SELECT * INTO l_rec_loadxref.* FROM loadxref 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND run_text = "PSA" 
	AND type_code = "CO" 
	AND ext_code = l_rec_loadxref.ext_code 
	IF status = NOTFOUND THEN 
		LET modu_error_text = "No Company Code found FOR Fund ",		l_rec_loadxref.ext_code clipped 

		#---------------------------------------------------------
		OUTPUT TO REPORT PSA_rpt_list_exception(p_rpt_idx,
		modu_error_text, false) 
		#---------------------------------------------------------

		RETURN false 
	END IF 
	LET modu_trans_cmpy_code = l_rec_loadxref.int_code 
	SELECT unique 1 FROM company 
	WHERE cmpy_code = modu_trans_cmpy_code 
	IF status = NOTFOUND THEN 
		LET modu_error_text = "Invalid Company Code ", 
		l_rec_loadxref.int_code clipped, 
		" FOR Fund ", l_rec_loadxref.ext_code clipped 

		#---------------------------------------------------------
		OUTPUT TO REPORT PSA_rpt_list_exception(p_rpt_idx,
		modu_error_text, false) 
		#---------------------------------------------------------
		
		RETURN false 
	END IF 
	#
	# NOTE: The details in the INPUT files may affect more than one
	# KandooERP company.  The module parameters are therefore retrieved
	# here AFTER establishing the current transaction company code, NOT
	# AT the start of the program.  One KandooERP company needs TO be
	# nominated as the company in which the loads are done, so that
	# the translation table IS kept in one place only.
	#
	SELECT * INTO glob_rec_glparms.* FROM glparms 
	WHERE key_code = "1" 
	AND cmpy_code = modu_trans_cmpy_code 
	IF status = NOTFOUND THEN 
		LET modu_error_text = "GL Parameters NOT SET up FOR Co. ",		modu_trans_cmpy_code 

		#---------------------------------------------------------
		OUTPUT TO REPORT PSA_rpt_list_exception(p_rpt_idx,
		modu_error_text, false) 
		#---------------------------------------------------------

		RETURN false 
	END IF 
	SELECT * INTO glob_rec_apparms.* FROM apparms 
	WHERE parm_code = "1" 
	AND cmpy_code = modu_trans_cmpy_code 
	IF status = NOTFOUND THEN 
		LET modu_error_text = "AP Parameters NOT SET up FOR Co. ",	modu_trans_cmpy_code 

		#---------------------------------------------------------
		OUTPUT TO REPORT PSA_rpt_list_exception(p_rpt_idx,
		modu_error_text, false) 
		#---------------------------------------------------------
 
		RETURN false 
	END IF 
	
	LET modu_error_text = "No Bank Code FOR account ", modu_cr_acct_code clipped, " in Company ", modu_trans_cmpy_code 
	IF acct_type(modu_trans_cmpy_code, modu_cr_acct_code, coa_account_required_is_control_bank, "N") THEN 
		SELECT * INTO modu_rec_bank.* FROM bank 
		WHERE acct_code = modu_cr_acct_code 
		AND cmpy_code = modu_trans_cmpy_code 
		IF status = NOTFOUND THEN 

			#---------------------------------------------------------
			OUTPUT TO REPORT PSA_rpt_list_exception(p_rpt_idx,
			modu_error_text, false) 
			#---------------------------------------------------------

			RETURN false 
		END IF 
	ELSE 
		#---------------------------------------------------------
		OUTPUT TO REPORT PSA_rpt_list_exception(p_rpt_idx,
		modu_error_text, false) 
		#---------------------------------------------------------
	
		RETURN false 
	END IF 

	SELECT * INTO modu_rec_vendor.* FROM vendor 
	WHERE vend_code = modu_rec_bank.bank_code 
	AND cmpy_code = modu_trans_cmpy_code 
	IF status = NOTFOUND THEN 
		LET modu_error_text = "No Vendor Code FOR Bank ", 
		modu_rec_bank.bank_code clipped, 
		" - Acct ", modu_rec_bank.acct_code clipped 

		#---------------------------------------------------------
		OUTPUT TO REPORT PSA_rpt_list_exception(p_rpt_idx,
		modu_error_text, false) 
		#---------------------------------------------------------

		RETURN false 
	END IF 
	IF modu_rec_vendor.currency_code <> modu_rec_bank.currency_code THEN 
		LET modu_error_text = "Vendor Code AND Bank ", 
		modu_rec_bank.bank_code clipped, 
		" have different currency" 

		#---------------------------------------------------------
		OUTPUT TO REPORT PSA_rpt_list_exception(p_rpt_idx,
		modu_error_text, false) 
		#---------------------------------------------------------
 
		RETURN false 
	END IF 
	
	SELECT unique 1 FROM coa 
	WHERE acct_code = modu_dr_acct_code 
	AND cmpy_code = modu_trans_cmpy_code 
	IF status = NOTFOUND THEN 
		LET modu_error_text = "Debit Account ", modu_dr_acct_code clipped,	" does NOT exist" 

		#---------------------------------------------------------
		OUTPUT TO REPORT PSA_rpt_list_exception(p_rpt_idx,
		modu_error_text, false) 
		#---------------------------------------------------------
 
		RETURN false 
	END IF 
	IF NOT acct_type(modu_trans_cmpy_code, modu_dr_acct_code, coa_account_required_can_be_normal_transaction, "N") THEN 
		LET modu_error_text = "Debit Account ", modu_dr_acct_code clipped,	" cannot be a control account" 

		#---------------------------------------------------------
		OUTPUT TO REPORT PSA_rpt_list_exception(p_rpt_idx,
		modu_error_text, false) 
		#---------------------------------------------------------
 
		RETURN false 
	END IF 
	#
	# Initialise the voucher record
	#
	CALL init_voucher(modu_trans_cmpy_code,glob_rec_kandoouser.sign_on_code,modu_rec_vendor.vend_code, 
	modu_trans_date, glob_rec_glparms.base_currency_code, 
	glob_rec_apparms.vouch_approve_flag) 
	RETURNING l_call_status, modu_rec_voucher.*, modu_error_text 
	IF NOT l_call_status THEN 

		#---------------------------------------------------------
		OUTPUT TO REPORT PSA_rpt_list_exception(p_rpt_idx,
		modu_error_text, false) 
		#---------------------------------------------------------
 
		RETURN false 
	END IF 
	RETURN true 

END FUNCTION 


############################################################
# FUNCTION create_cheques_and_voucher(p_rpt_idx)
#
#  This step will INSERT a cheque RECORD FOR each RECORD in the WHICS
#  payments file FOR the unique combination of company, bank AND
#  voucher distribution account (ie. fund, CR account AND DR account)
#  AND create a voucher with a single distribution. FOR the total of
#  those payments.  Each cheque IS applied TO the voucher.
#  Any cheque that IS NOT fails the validation tests will be skipped,
#  OTHERWISE the payment RECORD IS deleted.
############################################################
FUNCTION create_cheques_and_voucher(p_rpt_idx) 
	DEFINE p_rpt_idx SMALLINT  #report array index
	DEFINE l_rec_whics_payments RECORD LIKE whics_payments.*
	DEFINE l_cheque RECORD LIKE cheque.*
	DEFINE l_call_status SMALLINT 
	DEFINE l_db_status INTEGER 
	DEFINE l_rowid INTEGER 
	DEFINE l_cheq_code INTEGER 
	DEFINE l_cheque_text CHAR(11) 
	DEFINE l_rec_voucherdist RECORD LIKE voucherdist.* 
	DEFINE l_total_pay_amt LIKE voucher.total_amt 
	DEFINE l_cheque_count INTEGER 

	CALL display_progress("Inserting cheque AND voucher records") 

	GOTO bypass 
	LABEL recovery: 
	IF error_recover(modu_err_message,status) != "Y" THEN 
		CALL psa_exit_program(p_rpt_idx) 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 

	BEGIN WORK 
		LET l_total_pay_amt = 0 
		LET l_cheque_count = 0 
		#
		# Lock the bank vendor FOR UPDATE
		#
		DECLARE c_vendor CURSOR FOR 
		SELECT * FROM vendor 
		WHERE vend_code = modu_rec_vendor.vend_code 
		AND cmpy_code = modu_rec_vendor.cmpy_code 
		FOR UPDATE 
		OPEN c_vendor 
		FETCH c_vendor INTO modu_rec_vendor.* 
		#
		# Create the voucher with a zero amount intially, so we have a
		# transaction number TO apply each cheque against. The voucher
		# RECORD IS initialised in the vendor SET up routine.
		#
		DECLARE c_apparms CURSOR FOR 
		SELECT * FROM apparms 
		WHERE apparms.parm_code = "1" 
		AND apparms.cmpy_code = modu_trans_cmpy_code 
		FOR UPDATE 
		OPEN c_apparms 
		FETCH c_apparms INTO glob_rec_apparms.* 
		LET modu_rec_voucher.vouch_code = glob_rec_apparms.next_vouch_num 
		LET modu_err_message = "PSA - Updating AP Parameters Voucher Number" 
		UPDATE apparms 
		SET next_vouch_num = glob_rec_apparms.next_vouch_num + 1 
		WHERE cmpy_code = modu_trans_cmpy_code 
		AND parm_code = "1" 
		LET modu_rec_voucher.com1_text = "WHICS-OPEN AP Load - ", 
		today USING "dd/mm/yy" 
		LET modu_err_message = "PSA - Inserting voucher RECORD (1)" 
		INSERT INTO voucher VALUES (modu_rec_voucher.*) 

		DECLARE c_whics_payments CURSOR FOR 
		SELECT rowid, * FROM whics_payments 
		WHERE fund_num = modu_fund_num 
		AND dr_acct_code = modu_dr_acct_code 
		AND cr_acct_code = modu_cr_acct_code 
		AND proc_date = modu_trans_date 
		FOR UPDATE 

		FOREACH c_whics_payments INTO l_rowid, l_rec_whics_payments.* 
			LET l_cheque_text = l_rec_whics_payments.cheq_code USING 
			"&&&&&&&&&" 
			LET l_cheq_code = NULL 
			WHENEVER ERROR CONTINUE 
			LET l_cheq_code = l_cheque_text[2,9] 
			WHENEVER ERROR GOTO recovery 
			IF status != 0 THEN 
				LET modu_error_text = 
				"Cheque No ", l_cheque_text, 
				" invalid - Bank ", modu_rec_bank.bank_code clipped 

				#---------------------------------------------------------
				OUTPUT TO REPORT PSA_rpt_list_exception(p_rpt_idx,
				modu_error_text, false) 
				#---------------------------------------------------------
				
				LET modu_invalid_recs = modu_invalid_recs + 1 
				LET modu_invalid_amts = 
				modu_invalid_amts + l_rec_whics_payments.pay_amt 
				CONTINUE FOREACH 
			END IF 

			SELECT unique 1 FROM cheque 
			WHERE cheq_code = l_cheq_code 
			AND bank_code = modu_rec_bank.bank_code 
			AND pay_meth_ind = modu_rec_vendor.pay_meth_ind 
			AND cmpy_code = modu_trans_cmpy_code 

			IF status != NOTFOUND THEN 
				LET modu_error_text = 
				"Cheque No ", l_cheq_code USING "<<<<<<<<", 
				" already exists FOR bank ", modu_rec_bank.bank_code clipped 

				#---------------------------------------------------------
				OUTPUT TO REPORT PSA_rpt_list_exception(p_rpt_idx,
				modu_error_text, false) 
				#---------------------------------------------------------
				
				LET modu_invalid_recs = modu_invalid_recs + 1 
				LET modu_invalid_amts = 
				modu_invalid_amts + l_rec_whics_payments.pay_amt 
				CONTINUE FOREACH 
			END IF 

			IF l_cheq_code IS NULL OR l_cheq_code = 0 THEN 
				LET modu_error_text = 
				"Cheque No ", l_cheque_text clipped, 
				" FOR bank ", modu_rec_bank.bank_code clipped, 
				" - IS NULL OR 0" 

				#---------------------------------------------------------
				OUTPUT TO REPORT PSA_rpt_list_exception(p_rpt_idx,
				modu_error_text, false) 
				#---------------------------------------------------------
 
				LET modu_invalid_recs = modu_invalid_recs + 1 
				LET modu_invalid_amts = 
				modu_invalid_amts + l_rec_whics_payments.pay_amt 
				CONTINUE FOREACH 
			END IF 

			IF l_rec_whics_payments.pay_amt <= 0 OR 
			l_rec_whics_payments.pay_amt IS NULL THEN 
				LET modu_error_text = 
				"Cheque No ", l_cheq_code USING "<<<<<<<<", 
				" FOR bank ", modu_rec_bank.bank_code clipped, 
				" - invalid amount" 

				#---------------------------------------------------------
				OUTPUT TO REPORT PSA_rpt_list_exception(p_rpt_idx,
				modu_error_text, false) 
				#---------------------------------------------------------
 
				LET modu_invalid_recs = modu_invalid_recs + 1 
				LET modu_invalid_amts = 
				modu_invalid_amts + l_rec_whics_payments.pay_amt 
				CONTINUE FOREACH 
			END IF 

			CALL init_cheque(modu_trans_cmpy_code, glob_rec_kandoouser.sign_on_code, modu_rec_vendor.vend_code, 
			l_cheq_code, l_rec_whics_payments.proc_date, 
			modu_rec_bank.bank_code, glob_rec_glparms.base_currency_code) 
			RETURNING l_call_status, l_cheque.*, modu_error_text 

			IF NOT l_call_status THEN 

				#---------------------------------------------------------
				OUTPUT TO REPORT PSA_rpt_list_exception(p_rpt_idx,
				modu_error_text, false) 
				#---------------------------------------------------------
 
				LET modu_invalid_recs = modu_invalid_recs + 1 
				LET modu_invalid_amts = 		modu_invalid_amts + l_rec_whics_payments.pay_amt 
				CONTINUE FOREACH 
			END IF 
			#
			# Set up actual VALUES in cheque fields AND INSERT the cheque.
			# The cheque IS TO be fully applied TO the voucher created AND
			# discount does NOT apply.  Put WHICS member numbers AND payee
			# details INTO the comment fields.
			#
			LET l_cheque.pay_amt = l_rec_whics_payments.pay_amt 
			LET l_cheque.apply_amt = l_rec_whics_payments.pay_amt 
			CALL wtaxcalc(l_cheque.pay_amt, l_cheque.tax_per, l_cheque.withhold_tax_ind, l_cheque.cmpy_code) 
			RETURNING l_cheque.net_pay_amt, l_cheque.tax_amt 
			LET l_cheque.com3_text = l_rec_whics_payments.member_code 
			LET l_cheque.next_appl_num = l_cheque.next_appl_num + 1 
			LET l_cheque.com1_text = l_rec_whics_payments.payee_text 
			LET l_cheque.com2_text = "WHICS AP Load - ", 
			today USING "dd/mm/yy" 
			LET modu_err_message = "PSA - Inserting cheque record" 

			INSERT INTO cheque VALUES (l_cheque.*) 
			#NOTE: the serial doc number field IS needed FOR subsequent tx.
			LET l_cheque.doc_num = sqlca.sqlerrd[2] 

			#
			# Insert the appropriate apaudit records
			#
			CALL ins_chq_apaudit(l_cheque.*, modu_rec_vendor.next_seq_num, 
			modu_rec_vendor.bal_amt, "0") 
			RETURNING l_call_status, l_db_status, modu_error_text, 
			modu_rec_vendor.next_seq_num, modu_rec_vendor.bal_amt 
			IF l_call_status < 0 THEN 
				LET status = l_db_status 
				GOTO recovery 
			END IF 

			#
			# Insert the appropriate voucherpays records
			#
			LET modu_rec_voucher.pay_seq_num = modu_rec_voucher.pay_seq_num + 1 
			CALL ins_voucherpay(modu_rec_voucher.*, "CH", l_cheque.cheq_code, 
			l_cheque.pay_amt, 0, l_cheque.currency_code, 
			l_cheque.conv_qty,glob_rec_kandoouser.sign_on_code,modu_rec_vendor.next_seq_num, 
			modu_rec_vendor.bal_amt,l_cheque.*) 
			RETURNING l_call_status, l_db_status, modu_error_text, 
			modu_rec_vendor.next_seq_num, modu_rec_vendor.bal_amt 
			IF l_call_status < 0 THEN 
				LET status = l_db_status 
				GOTO recovery 
			END IF 
			#
			# Add TO voucher AND cheque totals AND TO the overall
			# totals FOR the run.
			#
			LET l_total_pay_amt = 
			l_total_pay_amt + l_rec_whics_payments.pay_amt 
			LET l_cheque_count = l_cheque_count + 1 
			LET modu_valid_recs = modu_valid_recs + 1 
			LET modu_valid_amts = modu_valid_amts + l_rec_whics_payments.pay_amt 


			#
			# Delete this row FROM the load table
			#
			LET modu_err_message = "PSA - Deleting payments record" 
			DELETE FROM whics_payments 
			WHERE fund_num = modu_fund_num 
			AND dr_acct_code = modu_dr_acct_code 
			AND cr_acct_code = modu_cr_acct_code 
			AND proc_date = modu_trans_date 
			AND rowid = l_rowid 

		END FOREACH 
		#
		#  WHEN all related payments have been processed, the total
		#  amount represents the total of all payments AND therefore the
		#  voucher amount.  IF the voucher total IS zero, all the payments
		#  must have been rejected - the transaction IS rolled back AND no
		#  cheques are created.  OTHERWISE, the voucher IS updated with the
		#  TRUE total, apaudit AND voucherdist records are inserted AND the
		# vendor balance IS updated.
		#
		IF l_cheque_count = 0 THEN 
			LET modu_error_text = "No cheques OR voucher created FOR CO. ", 
			modu_trans_cmpy_code, " Bank ", modu_rec_bank.bank_code clipped 
			
			#---------------------------------------------------------
			OUTPUT TO REPORT PSA_rpt_list_exception(p_rpt_idx,
			modu_error_text, false) 
			#---------------------------------------------------------
			
			ROLLBACK WORK 
		ELSE 
			LET modu_rec_voucher.total_amt = l_total_pay_amt 
			LET modu_rec_voucher.goods_amt = l_total_pay_amt 
			LET modu_rec_voucher.paid_amt = l_total_pay_amt 
			LET modu_rec_voucher.dist_amt = l_total_pay_amt 
			LET modu_rec_voucher.paid_date = today 
			LET modu_rec_voucher.pay_seq_num = modu_rec_voucher.pay_seq_num 
			LET modu_rec_voucher.line_num = 1 
			LET modu_err_message = "PSA - Updating voucher record" 

			UPDATE voucher 
			SET total_amt = modu_rec_voucher.total_amt, 
			goods_amt = modu_rec_voucher.goods_amt, 
			paid_amt = modu_rec_voucher.paid_amt, 
			dist_amt = modu_rec_voucher.dist_amt, 
			paid_date = modu_rec_voucher.paid_date, 
			pay_seq_num = modu_rec_voucher.pay_seq_num, 
			line_num = modu_rec_voucher.line_num 
			WHERE vouch_code = modu_rec_voucher.vouch_code 
			AND cmpy_code = modu_rec_voucher.cmpy_code 

			CALL ins_vouch_apaudit(modu_rec_voucher.*, modu_rec_vendor.next_seq_num, 
			modu_rec_vendor.bal_amt, "0") 
			RETURNING l_call_status, l_db_status, modu_error_text, 
			modu_rec_vendor.next_seq_num, modu_rec_vendor.bal_amt 
			IF l_call_status < 0 THEN 
				LET status = l_db_status 
				GOTO recovery 
			END IF 
			#
			# Insert a single voucher distribution FOR the entire amount
			#
			INITIALIZE l_rec_voucherdist.* TO NULL 
			LET l_rec_voucherdist.cmpy_code = modu_rec_voucher.cmpy_code 
			LET l_rec_voucherdist.vend_code = modu_rec_voucher.vend_code 
			LET l_rec_voucherdist.vouch_code = modu_rec_voucher.vouch_code 
			LET l_rec_voucherdist.line_num = 1 
			LET l_rec_voucherdist.type_ind = "G" 
			LET l_rec_voucherdist.acct_code = modu_dr_acct_code 
			LET l_rec_voucherdist.desc_text = "WHICS-OPEN AP Load - ", 
			today USING "dd/mm/yy" 
			LET l_rec_voucherdist.dist_qty = 1 
			LET l_rec_voucherdist.dist_amt = modu_rec_voucher.total_amt 
			LET modu_err_message = "PSA - Inserting voucherdist record" 
			INSERT INTO voucherdist VALUES (l_rec_voucherdist.*) 
			#
			# Only the vendor next sequence number, last voucher date AND last
			# payment date need TO be updated - the vendor balance remains
			# unchanged as the voucher AND payments totals are equal.
			#
			LET modu_err_message = "PSA - updating vendor record" 
			UPDATE vendor 
			SET next_seq_num = modu_rec_vendor.next_seq_num, 
			last_vouc_date = today, 
			last_payment_date = today 
			WHERE vend_code = modu_rec_vendor.vend_code 
			AND cmpy_code = modu_rec_vendor.cmpy_code 
			#
			# Report the voucher AND number of cheques created
			#
			LET modu_error_text = "Co. ", modu_rec_voucher.cmpy_code clipped, 
			" Bank ", modu_rec_voucher.vend_code clipped, " - ", 
			l_cheque_count USING "<<<<<<<<", " cheques FOR ", 
			modu_rec_voucher.vouch_date USING "dd/mm/yyyy" 

			#---------------------------------------------------------
			OUTPUT TO REPORT PSA_rpt_list_exception(p_rpt_idx,
			modu_error_text, false) 
			#---------------------------------------------------------

			LET modu_error_text = "Voucher ", 
			modu_rec_voucher.vouch_code USING "<<<<<<<<", " total amount = ", 
			modu_rec_voucher.total_amt USING "---,---,--&.&&" 

			#---------------------------------------------------------
			OUTPUT TO REPORT PSA_rpt_list_exception(p_rpt_idx,
			modu_error_text, false) 
			#---------------------------------------------------------
 
		COMMIT WORK 


	END IF 

	WHENEVER ERROR stop 

END FUNCTION 

############################################################
# FUNCTION display_progress(p_text_line)
#
#
############################################################
FUNCTION display_progress(p_text_line) 
	DEFINE p_text_line CHAR(60) 
	DEFINE idx SMALLINT 

	FOR idx = 1 TO 9 
		IF modu_arr_comments[idx] IS NULL THEN 
			EXIT FOR 
		END IF 
	END FOR 
	# IF the comment ARRAY IS full, CLEAR AND start again AT the top
	IF idx > 9 THEN 
		FOR idx = 1 TO 9 
			INITIALIZE modu_arr_comments[idx] TO NULL 
		END FOR 
		LET idx = 1 
	END IF 
	LET modu_arr_comments[idx] = p_text_line 
	DISPLAY modu_arr_comments[idx] TO sr_comments[idx].comments 

END FUNCTION 

############################################################
# FUNCTION PSA_exit_program(p_rpt_idx)
#
#  Allows the user TO abandon the load IF there IS a lock AND
#  restart later
############################################################
FUNCTION psa_exit_program(p_rpt_idx) 
	DEFINE p_rpt_idx SMALLINT  #report array index
	DEFINE l_msgresp LIKE language.yes_flag 

	LET modu_error_text = "Load IS incomplete - restart required" 

	#---------------------------------------------------------
	OUTPUT TO REPORT PSA_rpt_list_exception(p_rpt_idx,
	modu_error_text, false) 
	#---------------------------------------------------------

	CALL display_progress(modu_error_text) 
	LET l_msgresp = kandoomsg("U",7016,"") #7016 Error Occurred. Refer TO REPORT FOR more information.
	WHENEVER ERROR CONTINUE 
	UPDATE loadstatus 
	SET load_running_flag = "N" 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND run_text = "PSA" 
	WHENEVER ERROR stop 

	EXIT PROGRAM 

END FUNCTION 

############################################################
# REPORT PSA_rpt_list_exception(p_rpt_idx,p_error_text,p_follow_line)
#
#
############################################################
REPORT PSA_rpt_list_exception(p_rpt_idx,p_error_text,p_follow_line) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_error_text CHAR(60) 
	DEFINE p_follow_line SMALLINT 
--	DEFINE l_rpt_offset1 SMALLINT 
--	DEFINE l_rpt_offset2 SMALLINT 
--	DEFINE l_rpt_line1 CHAR(132) 
	DEFINE l_time DATETIME hour TO second 

	OUTPUT 

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
				PRINT COLUMN 011, p_error_text clipped 
			ELSE 
				SKIP 1 line 
				LET l_time = CURRENT 
				PRINT COLUMN 001, l_time, 
				COLUMN 011, p_error_text clipped 
			END IF 
			
		ON LAST ROW 
			SKIP 1 line 
			PRINT COLUMN 011, "WHICS-OPEN AP Load Complete" 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			

END REPORT