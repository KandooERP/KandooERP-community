GLOBALS "lib_db_globals.4gl"

MAIN
	CALL setCurrentUser_cmpy_code("MA")
	CALL setCurrentUser_language_code("ENG")
	CALL setCurrentUser_country_code("GB")
	CALL setCurrentUser_currency_code("GBP")
	
	LET gl_setupRec.silentMode = 0  --0=no user interaction 1 = with User input
	LET gl_setupRec.unl_file_extension = "unl" --file extension for exporting/unloading db-table data
	
	CALL stnd_grpMenu()
	
#CALL import_stnd_grp()
#unload_stnd_grp()
#import_stnd_grp()
#delete_stnd_grp_all()
#getstnd_grpCount() --Count all stnd_grp rows FROM the current company	
 
END MAIN