GLOBALS "lib_db_globals.4gl"

MAIN
	DEFER INTERRUPT
	
	CALL setCurrentUser_cmpy_code("MA")
	CALL setCurrentUser_language_code("ENG")
	CALL setCurrentUser_country_code("GB")
	CALL setCurrentUser_currency_code("GBP")
	
	LET gl_setupRec.silentMode = 0  --0=no user interaction 1 = with User input
	LET gl_setupRec.unl_file_extension = "unl" --file extension for exporting/unloading db-table data

	
	#CALL setup_default_rate_exchange()
	CALL contractorMenu()
	
#CALL import_contractor()
#unload_contractor()
#import_contractor()
#delete_contractor_all()
#getcontractorCount() --Count all contractor rows FROM the current company	
 
END MAIN