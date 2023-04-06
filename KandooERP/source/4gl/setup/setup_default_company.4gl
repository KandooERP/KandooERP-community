GLOBALS "lib_db_globals.4gl"


########################################################
# FUNCTION CompanyInstall()                    --Step 03
########################################################
FUNCTION CompanyInstall()

	DEFINE countCompany SMALLINT
		
	#check if record already exists (happens if the user navigates back/previous)
	SELECT COUNT(*) INTO countCompany FROM temp_Company 
	#if exists, load the data
	IF countCompany = 1 THEN
		SELECT * INTO gl_setupRec_default_company.* FROM temp_Company WHERE cmpy_code = gl_setupRec_default_company.cmpy_code
	ELSE
		IF db_company_pk_exists(UI_OFF,gl_setupRec_default_company.cmpy_code) THEN	
		#IF exist_company(gl_setupRec_default_company.cmpy_code) THEN
			SELECT * INTO gl_setupRec_default_company.* FROM company
				WHERE cmpy_code = gl_setupRec_default_company.cmpy_code
		ELSE
			#init default data
			LET gl_setupRec_default_company.language_code = gl_setupRec_default_company.language_code 
			LET gl_setupRec_default_company.country_code = gl_setupRec_default_company.country_code
			LET gl_setupRec_default_company.country_text = gl_setupRec_default_company.country_text
			LET gl_setupRec_default_company.curr_code = gl_setupRec_default_company.curr_code		
		END IF	
	END IF
	
	OPEN WINDOW company WITH FORM "per/setup/setup_company" #ATTRIBUTE (BORDER)
	#OPEN WINDOW company WITH FORM "per/setup/qxt_company_install" #ATTRIBUTE (BORDER)
	CALL updateConsole()
			
	#populate combobox with company,country_text,language_code,curr_code
	CALL db_company_populate_combo("cmpy_code")
	#CALL libPopulateCountry2Combo("country_text")
	CALL libPopulateLanguageCombo("language_code")
	CALL libPopulateCurrencyCombo("curr_code")

	
	#DISPLAY known/SET data
	DISPLAY BY NAME gl_setupRec_default_company.country_text
	DISPLAY BY NAME gl_setupRec_default_company.country_code
	DISPLAY BY NAME gl_setupRec_default_company.language_code
	DISPLAY BY NAME gl_setupRec_default_company.curr_code
			
	INPUT BY NAME gl_setupRec_default_company.cmpy_code,gl_setupRec_default_company.name_text,
								gl_setupRec_default_company.vat_code,gl_setupRec_default_company.vat_div_code,
								gl_setupRec_default_company.tax_text,
								gl_setupRec_default_company.addr1_text, gl_setupRec_default_company.addr2_text,
								gl_setupRec_default_company.city_text, gl_setupRec_default_company.state_code, gl_setupRec_default_company.post_code, 
								gl_setupRec_default_company.tele_text, gl_setupRec_default_company.fax_text	
									
								WITHOUT DEFAULTS ATTRIBUTE(UNBUFFERED)
		BEFORE INPUT
			DISPLAY getBankFormat(getCountryBankFormatCode(gl_setupRec_default_company.country_code)) TO bank_acc_format
		
		AFTER FIELD cmpy_code
			IF db_company_pk_exists(UI_OFF,gl_setupRec_default_company.cmpy_code) THEN
			#IF exist_company(gl_setupRec_default_company.cmpy_code) THEN
				SELECT * INTO gl_setupRec_default_company.* FROM company
				WHERE cmpy_code = gl_setupRec_default_company.cmpy_code
			END IF
																
			ON CHANGE country_text
				LET gl_setupRec_default_company.country_code = libGetCountryCodeByText(gl_setupRec_default_company.country_text) 
				DISPLAY BY NAME gl_setupRec_default_company.country_code
				
			ON ACTION CANCEL
				CALL interrupt_installation()

			ON ACTION "Previous"
				LET mdNavigatePrevious = TRUE
				EXIT INPUT				
				


		END INPUT

	IF int_flag = 1 THEN
		CALL interrupt_installation()
	ELSE
	#check if it exists
	#check if record already exists (happens if the user navigates back/previous)
	
#		#Does any record exist ?
#		SELECT COUNT(*) INTO countCompany FROM temp_Company
#		IF countCompany <> 0 THEN
#			DELETE FROM temp_Company
#		END IF
#		#Write latest company setup data TO temp table
#		INSERT INTO temp_Company VALUES(gl_setupRec_default_company.*)
	
		IF mdNavigatePrevious THEN
			LET step_num = step_num - 1
			LET mdNavigatePrevious = FALSE
		ELSE
			LET step_num = step_num + 1
		END IF
	END IF
		
	CLOSE WINDOW company 	
	#RETURN gl_setupRec_default_company.cmpy_code
END FUNCTION 

