GLOBALS "lib_db_globals.4gl"

MAIN
	CALL setCurrentUser_cmpy_code("MA")
	CALL setCurrentUser_language_code("ENG")
	CALL setCurrentUser_country_code("GB")
	CALL setCurrentUser_currency_code("GBP")
	
	LET gl_setupRec.silentMode = 0  --0=no user interaction 1 = with User input
	LET gl_setupRec.unl_file_extension = "unl" --file extension for exporting/unloading db-table data
	
	CALL prodgrpMenu()
	
#CALL import_prodgrp()
#unload_prodgrp()
#import_prodgrp()
#delete_prodgrp_all()
#getprodgrpCount() --Count all prodgrp rows FROM the current company	
 
END MAIN