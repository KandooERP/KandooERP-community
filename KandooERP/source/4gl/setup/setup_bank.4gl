GLOBALS "lib_db_globals.4gl"


FUNCTION setupBankAccount()

	OPEN WINDOW wBankAccount WITH FORM "per/setup/setup_bank_account"
	CALL updateConsole()
	LET gl_setupRec_bank.cmpy_code = gl_setupRec_default_company.cmpy_code
	LET gl_setupRec_bank.currency_code = gl_setupRec_default_company.curr_code
	LET gl_setupRec_bank.bic_code = gl_setupRec_bic.bic_code
	LET gl_setupRec_bank.next_cheque_num = 1  --default, could be added TO the installer but would make it too long
	LET gl_setupRec_bank.next_eft_run_num = 1  --default, could be added TO the installer but would make it too long
	LET gl_setupRec_bank.next_eft_ref_num = 1  --default, could be added TO the installer but would make it too long
	LET gl_setupRec_bank.next_cheq_run_num = 1  --default, could be added TO the installer but would make it too long
	LET gl_setupRec_bank.ext_file_ind = 0  --default, could be added TO the installer but would make it too long
	LET gl_setupRec_bank.acct_code = "1200"
	LET gl_setupRec_bank.type_code = "CHE"
	CALL comboList_banktype("type_code",0,0,0,3)  --Bank Type
	CALL comboList_currency("currency_code",0,0,0,3)
	CALL comboList_coa_account("acct_code",0,0,0,3)  --COA
	
	
	DISPLAY BY NAME gl_setupRec_bank.currency_code  --initial setup will use company/country currency
	DISPLAY getCountryBankFormatText(gl_setupRec_default_company.country_code) TO bank_acc_format
	
	DIALOG ATTRIBUTE(UNBUFFERED)
		 #BIC table
		INPUT BY NAME
			gl_setupRec_bank.bank_code, gl_setupRec_bank.iban, 
			gl_setupRec_bank.name_acct_text,
			gl_setupRec_bank.type_code, gl_setupRec_bank.acct_code WITHOUT DEFAULTS
		END INPUT			
		
		#BANK table
		INPUT BY NAME gl_setupRec_bic.* WITHOUT DEFAULTS
			AFTER FIELD bic_code
				LET gl_setupRec_bank.bic_code = gl_setupRec_bic.bic_code
		END INPUT


		ON ACTION CANCEL
			CALL interrupt_installation()

		ON ACTION "Previous"
			LET mdNavigatePrevious = TRUE
			EXIT DIALOG
			
		ON ACTION ACCEPT
			EXIT DIALOG		

		
	END DIALOG	
	IF int_flag = 1 THEN
		CALL interrupt_installation()
	ELSE
		IF mdNavigatePrevious THEN
			LET step_num = step_num - 1
			LET mdNavigatePrevious = FALSE
		ELSE
			LET step_num = step_num + 1
		END IF
	END IF
				
	CLOSE WINDOW wBankAccount				


END FUNCTION



###############################################################
# FUNCTION addBankAccount()
# If kandoo was already installed, 
# read the existing table configuration AND use for default VALUES
###############################################################
FUNCTION addBankAccount()
	DEFINE recCount SMALLINT

	SELECT COUNT(*) INTO recCount FROM bank
	WHERE cmpy_code = gl_setupRec_bank.cmpy_code
	AND bank_code = gl_setupRec_bank.bank_code
 
 	IF recCount = 1 THEN
 		DELETE FROM bank
		WHERE cmpy_code = gl_setupRec_bank.cmpy_code
		AND bank_code = gl_setupRec_bank.bank_code 		
 	END IF

	#check again AND on success, create the record
	SELECT COUNT(*) INTO recCount FROM bank
	WHERE cmpy_code = gl_setupRec_bank.cmpy_code
	AND bank_code = gl_setupRec_bank.bank_code 
	
	IF recCount = 0 THEN
		INSERT INTO bank VALUES(gl_setupRec_bank.*)
	END IF
	
END FUNCTION

###############################################################
# FUNCTION addBIC()
# write dataToTable
###############################################################
FUNCTION addBIC()
	DEFINE recCount SMALLINT

	SELECT COUNT(*) INTO recCount FROM bic
	WHERE bic_code = gl_setupRec_bic.bic_code
 
	IF recCount = 0 THEN
		INSERT INTO bic VALUES(gl_setupRec_bic.*)
	END IF

	
END FUNCTION





























