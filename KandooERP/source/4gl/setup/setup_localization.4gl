GLOBALS "lib_db_globals.4gl"

#####################################################
# FUNCTION languageSetup()                  --Step 01
#####################################################
FUNCTION languageSetup(pNewInst)
	DEFINE pNewInst BOOLEAN  --TRUE IS UPDATE installation

	IF pNewInst THEN  --new installation initialises
		LET gl_setupRec_default_company.language_code="ENG"
		LET gl_setupRec_default_company.country_code="GB"
		LET gl_setupRec_default_company.curr_code="GBP"
	ELSE	--UPDATE reads existing table data
		SELECT * INTO gl_setupRec_default_company FROM temp_company
	END IF

	OPEN WINDOW wLanguage WITH FORM "per/setup/setup_location"
	CALL updateConsole()	
	#OPEN WINDOW wLanguage WITH FORM "per/setup/qxt_language_country"

	CALL libPopulateLanguageCombo("language_code")	
	CALL libPopulateCountry2Combo("country_code")
	CALL libPopulateCurrencyCombo("curr_code")
	DISPLAY getBankFormat(getCountryBankFormatCode(gl_setupRec_default_company.country_code)) TO bank_acc_format
	
	INPUT BY NAME gl_setupRec_default_company.language_code, gl_setupRec_default_company.country_code, gl_setupRec_default_company.curr_code WITHOUT DEFAULTS ATTRIBUTES(UNBUFFERED)
		AFTER FIELD country_code
			DISPLAY getBankFormat(getCountryBankFormatCode(gl_setupRec_default_company.country_code)) TO bank_acc_format
	END INPUT
	
	IF int_flag = 1 THEN
		CALL interrupt_installation()
	ELSE
		LET gl_setupRec_default_company.country_text = libGetCountryTextByCode(gl_setupRec_default_company.country_code)
	END IF
	
	CLOSE WINDOW wLanguage
END FUNCTION
