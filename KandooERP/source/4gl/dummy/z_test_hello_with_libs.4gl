MAIN
	DEFINE budg1_text STRING
	
	CALL setModuleId("G11")
	CALL ui_init(0)	#Initial UI Init

	DEFER QUIT
  DEFER INTERRUPT
  
	CALL authenticate(getModuleId()) #authenticate
	CALL init_g_gl() #init G/GL General Ledger module
	
   OPEN WINDOW G100 WITH FORM "G100"
   CALL winDecoration("G100")
   
	INPUT BY NAME budg1_text WITHOUT DEFAULTS
END MAIN