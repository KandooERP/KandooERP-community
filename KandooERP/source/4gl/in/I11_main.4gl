#####################################################################
# MAIN
#
# Program wrapper for I16
#####################################################################
MAIN 
	DEFER QUIT 
	DEFER INTERRUPT 
	#Initial UI Init
	CALL setModuleId("I11") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_i_in() --init i/in warehouse inventory management module 

	CALL I11_main()
END MAIN
 