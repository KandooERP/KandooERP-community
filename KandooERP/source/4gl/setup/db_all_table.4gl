GLOBALS "lib_db_globals.4gl"

MAIN
	DEFER INTERRUPT
	
	CALL setCurrentUser_cmpy_code("MA")
	CALL setCurrentUser_language_code("ENG")
	CALL setCurrentUser_country_code("GB")
	CALL setCurrentUser_currency_code("GBP")
	
	LET gl_setupRec.silentMode = 0  --0=no user interaction 1 = with User input
	LET gl_setupRec.unl_file_extension = "unl"
	
	MENU "DB"
		ON ACTION "Export All"
			CALL db_export_all(gl_setupRec.silentMode,gl_setupRec.unl_file_extension)
	
		ON ACTION "Exit"
			EXIT MENU
	END MENU

END MAIN

#################################################
# FUNCTION db_export_all(FALSE,"exp")
#
#
#################################################
FUNCTION db_export_all(p_silentMode,p_fileExtension)
	DEFINE p_silentMode BOOLEAN
	DEFINE p_fileExtension STRING
	
	CALL unload_aRParmExt(gl_setupRec.silentMode,p_fileExtension)
	CALL unload_aRParms(gl_setupRec.silentMode,p_fileExtension)
END FUNCTION

