GLOBALS "lib_db_globals.4gl"

MAIN
	DEFER INTERRUPT
	
	CALL setCurrentUser_cmpy_code("MA")
	CALL setCurrentUser_language_code("ENG")
	CALL setCurrentUser_country_code("GB")
	CALL setCurrentUser_currency_code("GBP")
	
	LET gl_setupRec.silentMode = 0  --0=no user interaction 1 = with User input
	
	CALL UserMsgMenu()
	
#CALL import_UserMsg()
#unload_UserMsg()
#import_UserMsg()
#delete_UserMsg_all()
#getUserMsgCount() --Count all UserMsg rows FROM the current company	
 
END MAIN