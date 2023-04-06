GLOBALS "lib_db_globals.4gl"
GLOBALS "setup_globals.4gl"

DEFINE mdNewInst BOOLEAN

##########################################################################################################
# MAIN
##########################################################################################################
MAIN
	DEFINE recCount SMALLINT
	DEFINE installType STRING
	#DEFINE recCompany RECORD LIKE company.*

	CALL initStrings() #installer ui label text
		
	OPTIONS INPUT WRAP
	CALL fgl_setkeylabel("Previous","Previous","{CONTEXT}/public/querix/icon/svg/24/ic_navigate_before_24px.svg",1)
	CALL fgl_setkeylabel("ACCEPT","Next","{CONTEXT}/public/querix/icon/svg/24/ic_navigate_next_24px.svg",2)

	LET continue_installation = TRUE
	LET gl_setupRec.silentMode = 1  --Silent Install	
	
	LET gl_setupRec_admin_rec_kandoouser.sign_on_code = "Admin"
	LET gl_setupRec_admin_rec_kandoouser.name_text = "Kandoo Administrator"

	
	# Step 00
	# Setup must query if this IS a demo installation (all data) OR a real installation (user IS prompted TO provide data)
	LET step_num = 0


	IF baseTablesNotEmpty() THEN
		 LET installType =  fgl_winbutton("Existing data found","Existing data have been found in the database!\nKandoo seems TO be installed on your system already!\n\nThis setup may NOT work for you ! Do you still want TO try it with your database ?\n(may NOT work AND data will be lost)\n\nDo you really want TO overwrite your existing installation ?", "New", "New|Update|Abort", "exclamation", 1)
		 CASE installType
				WHEN "New"
					LET mdNewInst = TRUE
				WHEN "Update"				
					LET mdNewInst = FALSE
				OTHERWISE --"Abort"
		  		CALL fgl_winmessage("Installation aborted","The installation was aborted on user request!","Info")
		  		EXIT PROGRAM
		  END CASE
	ELSE
		LET mdNewInst = TRUE		  
	END IF

	CALL silentMenuTableLoad()  --new LyciaMenu (note: does a db connection)
	CALL createTempTables(mdNewInst)  --temptables TO store temp setupData
	CALL initLookupDataSelection()  --checkBoxes for selecting what optional lookup data should be loaded
	
	#UNL --  something for later.. we need language strings
	#Installation already exists, language string data needd TO be deleted always (new AND UPDATE)
	#IF NOT mdNewInst THEN
	DELETE FROM langstr_gb WHERE 1=1		
	LOAD FROM "unl/langstr_GB.unl" INSERT INTO langstr_gb
	DELETE FROM langstr_aus WHERE 1=1		
	LOAD FROM "unl/langstr_AUS.unl" INSERT INTO langstr_aus
	#END IF

	#UNL via libs
	CALL libCountryLoad(mdNewInst)   --default country list (currently in English only)
	CALL libkandooMsgLoad(mdNewInst)    --load default MESSAGE strings (original MESSAGE strings with multi-language support)
	CALL libLanguageLoad(mdNewInst) --bug lyc-724  --load languages (names are currently only in English)
	CALL libCurrencyLoad(mdNewInst)	--Load Currencies (names are currently only in English)
	CALL libMenuLegacyLoad(mdNewInst)  --legacy menu - IS currently still required for security function -- handles all 4 legacy menu tables in one call
	CALL libkandooinfoLoad(mdNewInst)  --kandooinfo IS some kind of license information/data for the company
	CALL libToolbarLoad(mdNewInst)  --Dynamic DB Driven Toolbar
	CALL libkandoowordLoad(mdNewInst)  --Original kandooword table data  .. a big xxx of xxxxx


	
	LET step_num = step_num+1


	WHILE continue_installation
		CASE step_num
			WHEN 1 --STEP 1
				CALL languageSetup(mdNewInst)  --language AND Country
				LET step_num = step_num+1

				#BankType   --needs country code AND seems, we need this lookupData during/prior installation
				#bank/bic require bankType which in turn requires country
				#IF setupLookupDataRecord.banktype = 1 THEN

					#NEED TO check if data has changed... make global record.. It's easier/faster
					IF NOT mdNewInst THEN	--Update Installation
						IF NOT glRecCompany_orig.* = gl_setupRec_default_company.* THEN	--company data have changed
								CALL delete_banktypeAll()  #first delete the original table data		
								CALL import_banktype()--(TRUE,gl_setupRec_default_company.country_code)
						ELSE	--company data have NOT changed
							IF fgl_winbutton("Replace Banktype Table","Do you want TO replace the existing bank type data (No = keep existing data) ?", "No", "Yes|No", "exclamation", 1) = "Yes" THEN
								CALL delete_banktypeAll()  #first delete the original table data		
								CALL import_banktype()--(TRUE,gl_setupRec_default_company.country_code)
							END IF
						
						END IF
					ELSE  --new installation, simply load/import the bankType data
						CALL import_banktype()--(TRUE,gl_setupRec_default_company.country_code)						
					END IF
					
				#END IF

			
			WHEN 2 CALL glSetup(mdNewInst)
				
			WHEN 3 CALL CompanyInstall()  # + arparms + glparms population
				#LET gl_setupRec_default_company.cmpy_code = CompanyInstall()  # + arparms + glparms population
				#Import COA Chart of Accounts	List AND GroupInfo
				#Required for bank/account setup
				#IF setupLookupDataRecord.coa = 1 THEN

				IF gl_setupRec_default_company.cmpy_code IS NOT NULL THEN
					CALL db_coa_delete_all()
					CALL delete_groupinfo_all()
				END IF					
					
					#Delete existing entry (no UPDATE)
				  SELECT COUNT(*) INTO recCount FROM company WHERE cmpy_code = gl_setupRec_default_company.cmpy_code
				  IF recCount <> 0 THEN
				  	DELETE FROM company WHERE cmpy_code = gl_setupRec_default_company.cmpy_code
				  END IF
					
					#Company install 
					#SELECT * INTO recCompany.* FROM temp_Company		
					SELECT * INTO gl_setupRec_default_company.* FROM temp_Company		

					SELECT COUNT(*) INTO recCount FROM company WHERE cmpy_code = gl_setupRec_default_company.cmpy_code 
					#if data do NOT exist aleady, load/INSERT the data
					IF (recCount = 0) AND (gl_setupRec_default_company.cmpy_code IS NOT NULL) THEN
						#INSERT INTO COMPANY VALUES(recCompany.*)
						INSERT INTO COMPANY VALUES(gl_setupRec_default_company.*)
						
					CALL import_groupinfo()--(1, gl_setupRec_default_company.cmpy_code)  --Note: COA requires groupInfo
					CALL db_coa_import5()  --(gl_setupRec.start_year_num,gl_setupRec.start_period_num,gl_setupRec.end_year_num,gl_setupRec.end_period_num)
					##Import Journal List
					#IF setupLookupDataRecord.journal = 1 THEN
						CALL import_journal()--(TRUE,gl_setupRec_default_company.cmpy_code)  ##TRUE=silent mode
					#END IF
					#Credit Reasons - table: credreas
					#IF setupLookupDataRecord.credreas = 1 THEN
					#Required TO setup	Journals AND Dates		
						call import_credreas()
					#END IF
						
					END IF								
					



				#END IF
			WHEN 4
				LET gl_setupRec_default_company.module_text = enableCompanyKandooModules()
				
			WHEN 5 
				LET gl_setupRec_admin_rec_kandoouser.sign_on_code = kandoouserInstall() # + kandoomodule population
				CALL fgl_setenv("KANDOO_SIGN_ON_CODE",gl_setupRec_admin_rec_kandoouser.sign_on_code)


				#CALL fgl_setenv("KANDOO_PASSWORD_TEXT",KANDOO_PASSWORD_TEXT) NOT used yet
			
			WHEN 6 #First BIC entry AND iban Bank Account
				CALL setupBankAccount()
				
				
			WHEN 7				
				CALL setupAP_Parameter()

			WHEN 8				
				CALL setupAR_Parameter()
					
			WHEN 9  --Lookup-/List Data Selection
				IF chooseImportLookupData() > 0 THEN
				#Insert Administrator setup DATA INTO kandoouser AND company table
					CALL completeInstallationWriteData()
				END IF
								
			WHEN 10 
			
				OPEN WINDOW wSubModuleSetup WITH FORM "per/setup/setup_sub_modules"
				CALL updateConsole()				
				INPUT BY NAME run_submodule_list WITHOUT DEFAULTS ATTRIBUTES(UNBUFFERED)
					ON ACTION RUN
						RUN run_submodule_list
				END INPUT
				
				CLOSE WINDOW wSubModuleSetup

			#table: nextnumber for sequential transaction numbers
			CALL setupTransactionNextNumber()

				#Final Message
				LET continue_installation = FALSE
				CALL fgl_winmessage("Congratulations","You have successfully created initial database! ","info")
				
		#LET step_num = 99	
		#	WHEN 99

				
		END CASE
	END WHILE
END MAIN


#########################################################################################
# FUNCTION completeInstallationWriteData()
#########################################################################################
FUNCTION completeInstallationWriteData()
	DEFINE reckandoouser RECORD LIKE kandoouser.*

	DEFINE install CHAR(1)
	DEFINE countCompany, countkandoouser SMALLINT
	

	SELECT * INTO recKandooUser.* FROM temp_rec_kandoouser
	
	OPEN WINDOW publishInstallation WITH FORM "per/setup/setup_publish"
	CALL updateConsole()		
					
	LET install = fgl_winbutton("Data gathering complete", "Setup IS now ready do store all data in your database\nDo you want TO start the installation?", "Yes", "Yes|No|Back", "info", 1)
	
	CASE install
		WHEN "N"
			CALL interrupt_installation()
		WHEN "B"
			LET step_num = step_num - 1
			RETURN
		WHEN "Y"
			#We install
		
	END CASE 
	


	#NOT sure for what this table IS used.. only read/validation operations exist, but no INSERT/UPDATE operations..
	CALL addKandooProfile()



	#Default Location Record
	CALL addDefaultLocation()  --also setup default location record 

	SELECT COUNT(*) INTO countkandoouser FROM kandoouser WHERE sign_on_code = gl_setupRec_admin_rec_kandoouser.sign_on_code
	#if data do NOT exist aleady, load/INSERT the data
	IF countkandoouser = 0 THEN
		INSERT INTO kandoouser VALUES(reckandoouser.*)
	END IF
	
	#add user location entry (NOT sure for what this IS used yet)
	CALL addUserDefaultLocation()
					
	#kandoomodule table defines what modules can be used by this user/company
	CALL setUserkandoomoduleEntries()  --(recCompany.cmpy_code, reckandoouser.sign_on_code)

	#kandoouserCmpy table defines user GeneralLedger Access - what user can access what GL "organisation/branch/division  ??.???.????"
	CALL insertkandoousercmpy()  --(reckandoouser.sign_on_code, recCompany.cmpy_code, gl_setupRec_admin_rec_kandoouser.acct_mask_code,NULL)

	#Fiscal Periods
	CALL addFiscalPeriods()

	#Import UOM List
	IF setupLookupDataRecord.uom = 1 THEN
		CALL import_uom()--(TRUE,gl_setupRec_default_company.cmpy_code)  --Silent mode
	END IF
	



	#Hold Payment Reasons - table:holdpay 
	IF setupLookupDataRecord.holdpay = 1 THEN		
		call import_holdpay(NULL)
	END IF

	###########################################
	#Need TO decide when we load these - can#t say yet as we have NOT done all modules
	CALL import_vendortype()
	CALL import_help_url()   --html help table qxt_help_page
	CALL import_term()  --Payment terms for Invoice (Accounts Receivable)
	CALL import_tax(UI_OFF,NULL)  --Tax types (company based)
	CALL import_customerType()  --CustomerType (GL accounts are optional / on NULL, the default IS used)
	CALL import_jmj_debttype()  --Some kind of liability type (debt type) list
	CALL import_stnd_grp()  --standard Group... no idea what this IS used for - this IS NOT in the docs Management Module: AZ7
	CALL import_jmj_trantype()  --Transaction Types .. something for Ali
	CALL import_holdreas()   --Reasons TO put ORDER on hold
	CALL import_holdpay(NULL)   --Reasons TO put payment on hold
	CALL import_purchType()  --Purchase Order Type ?? strange REPORT formating OPTIONS

	#NOT optional imports/loads
	CALL setup_default_rate_exchange()  --Install currency will be exchange rate 1.0

	###########################################

	# Create/Write glParms record
	CALL addGLParms()
	
	#Load/Write GL-FlexCode Structure
	CALL import_structure()
	
	
	#Write initial bank account AND BIC entry
	CALL addBIC()
	CALL addBankAccount()
	
	#Write AP Accounts Payable record
	CALL write_apparms_to_db()

	#Write AR Accounts Payable record
	CALL write_arparms_to_db()



##################################################
# Demo Data Load

	CALL import_salearea()
	CALL import_salesmgr()
	CALL import_territory() --Sales territory
	CALL import_salesperson() --Sales staff
	CALL import_condsale()  --sales conditions i.e. 10% discount for staff 	
	CALL import_vendor()
	CALL import_vendorgrp()
	CALL addDemoUser()								--add demo users
	CALL libkandoomoduleLoadDemoUsers()  --give demo users access TO all module groups
	CALL import_rmsparm()  --
	CALL import_waregrp()	-- Warehouse - Warehouse Group 
	CALL import_cartarea()  -- Warehouse
	CALL import_proddept()	-- Warehouse
	CALL import_category()	--Warehouse
	CALL import_class()	--Warehouse
	CALL import_warehouse() --Warehouse
	CALL import_ingroup() --Warehouse  
	CALL import_prodAdjType()  --Warehouse
	CALL import_maingrp()	--Warehouse - Main Product Group 
	CALL import_prodgrp()	--Warehouse - Product Group 
	CALL import_printcodes()	--Warehouse
	CALL import_labelhead()	--Warehouse - Product Label Formats
	CALL import_labeldetl()	--Warehouse
	CALL import_inParms()	--Warehouse Configuration/Parameter
	CALL import_transpType() --Warehouse
	CALL import_ipParms() --Warehouse - Product Schedule Parameters
	CALL import_product()  --Warehouse - Products
	#Do NOT delete - but comment it until UNL IS populated
	#CALL import_prodstructure()  --Warehouse - NOTE: UNL file IS empty
	CALL import_loadparms()  --AP Load
	CALL import_voucher()	--AP Voucher
	CALL import_cheque()	--AP Cheque
	CALL import_debitHead()	--AP Debit (DebitHead)
	CALL import_recurhead()--ap RECURING 
	CALL import_contractor() --AP Vendor which are Contractor(s)

	CALL import_customer()  --AR Customer
	CALL import_carrier()  --Carrier i.e. DHL, UPS...Ä
	CALL import_pricing()  --special promotions i.e. weekly offer 2018-23 - all Laser printer 10% off
	CALL import_custoffer()  --asignment/link customer with pricing (special offer for particular customer promotion)
	CALL import_customerPart()  --create pairs of original/vendor part (product) code with customer part (product) code
	CALL import_customerShip()  --Customer Shipping Addresses (double PK company AND customer)
	CALL import_prodstatus()  --Warehouse product attributes i.e. stock quantity, reorder level, purchase price, list sale price ....
	CALL import_invoiceHead()  --Demo Invoices
	CALL import_creditHead()  --Demo Credits (against demo invoices)
	CALL import_stateInfo()  --Demo .. currently NOT sure what this IS used for

	CALL import_posstation()  -- Demo Post Station
	CALL import_posstatdev()	-- Demo Post Station Devices
	CALL import_customerNote()  --Notes on/for customers

	#Module E Setup (ORDER Processing)
	CALL import_oPParms()	#Setup for ORDER processing parameters <opparams table>

	CALL import_offerSale()  --Sales offer table 

# End of Demo Data Load	
##################################################	
	
	MESSAGE "Data FROM Temp Table written TO DB"
	#LET step_num = step_num + 1
	
	CLOSE WINDOW publishInstallation
	
END FUNCTION



###########################################################################
# FUNCTION baseTablesNotEmpty()
# If one of the base tabels IS populated with data, offer TO overwrite them without
# any further prompts... this function checks, if any of theses tables
# holds data
###########################################################################
FUNCTION baseTablesNotEmpty()

	SELECT 1 FROM SYSTABLES WHERE tabid = 1 AND EXISTS (SELECT 1 FROM country)
	IF STATUS <> NOTFOUND THEN
		RETURN TRUE
	END IF

	SELECT 1 FROM SYSTABLES WHERE tabid = 1 AND EXISTS (SELECT 1 FROM kandoomsg)
	IF STATUS <> NOTFOUND THEN
		RETURN TRUE
	END IF
	
	SELECT 1 FROM SYSTABLES WHERE tabid = 1 AND EXISTS (SELECT 1 FROM language)
	IF STATUS <> NOTFOUND THEN
		RETURN TRUE
	END IF
	
	SELECT 1 FROM SYSTABLES WHERE tabid = 1 AND EXISTS (SELECT 1 FROM currency)
	IF STATUS <> NOTFOUND THEN
		RETURN TRUE
	END IF	
	
	SELECT 1 FROM SYSTABLES WHERE tabid = 1 AND EXISTS (SELECT 1 FROM menu1)
	IF STATUS <> NOTFOUND THEN
		RETURN TRUE
	END IF	

	SELECT 1 FROM SYSTABLES WHERE tabid = 1 AND EXISTS (SELECT 1 FROM menu2)
	IF STATUS <> NOTFOUND THEN
		RETURN TRUE
	END IF	

	SELECT 1 FROM SYSTABLES WHERE tabid = 1 AND EXISTS (SELECT 1 FROM menu3)
	IF STATUS <> NOTFOUND THEN
		RETURN TRUE
	END IF	

	SELECT 1 FROM SYSTABLES WHERE tabid = 1 AND EXISTS (SELECT 1 FROM menu4)
	IF STATUS <> NOTFOUND THEN
		RETURN TRUE
	END IF	
	
	SELECT 1 FROM SYSTABLES WHERE tabid = 1 AND EXISTS (SELECT 1 FROM kandooinfo)
	IF STATUS <> NOTFOUND THEN
		RETURN TRUE
	END IF	
	
	
	SELECT 1 FROM SYSTABLES WHERE tabid = 1 AND EXISTS (SELECT 1 FROM qxt_toolbar)
	IF STATUS <> NOTFOUND THEN
		RETURN TRUE
	END IF	
	
	
	SELECT 1 FROM SYSTABLES WHERE tabid = 1 AND EXISTS (SELECT 1 FROM kandooword)
	IF STATUS <> NOTFOUND THEN
		RETURN TRUE
	END IF	
	
	
	RETURN FALSE

END FUNCTION


{
###############################################################
# FUNCTION loadExistingDataFromDB()
# If kandoo was already installed, 
# read the existing table configuration AND use for default VALUES
###############################################################
FUNCTION loadExistingDataFromDB()
	CALL read_arparms_from_db()  --AR Accounts Receivable Parameters
	CALL read_apparms_from_db()  --AR Accounts Payable Parameters

END FUNCTION

}