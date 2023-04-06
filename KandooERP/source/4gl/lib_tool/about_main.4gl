############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

###########################################################################################################
# MAIN
#
# Just a wrapper for debug/system information
###########################################################################################################
MAIN 
	DEFER quit 
	DEFER interrupt 

	OPTIONS INPUT wrap 
	
	CALL setModuleId("A11") 
	CALL ui_init(0) 	#Initial UI Init 

	CALL authenticate(getmoduleid()) 

	CALL retrieveLyciaSystemEnvironment("F") 

END MAIN 
###########################################################################################################
# END MAIN ## Just a wrapper for debug/system information
###########################################################################################################