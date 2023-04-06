####################################################################
# MAIN
#
#
####################################################################
MAIN	
	CALL setModuleId("IZ1") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_i_in() --init i/in warehouse inventory management module 
	CALL IZ1_MAIN()

END MAIN
