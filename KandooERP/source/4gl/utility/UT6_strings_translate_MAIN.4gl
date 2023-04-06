MAIN		
	DEFER INTERRUPT		
		
	-- WHENEVER SQLERROR CALL error_mngmt		

	CALL setModuleId("UT6")			# put program name here (1 letter 2 or 3 digits)		
	CALL ui_init(0)		#Initial UI Init		
	CALL authenticate(getModuleId()) #authenticate		
	DEFER QUIT		
	DEFER INTERRUPT		
		
	CALL main_UT6_strings_translate()		
		
END MAIN		