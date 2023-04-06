############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "../ar/A_AR_GLOBALS.4gl"
GLOBALS "../ar/AC_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/ACA_GLOBALS.4gl"
#####################################################################
# MAIN
#
# ACA - Unapplied Receipts Report
#####################################################################
MAIN 
	DEFER interrupt 
	DEFER quit 

	CALL setModuleId("ACA") 
	CALL ui_init(0) 	#Initial UI Init
	CALL authenticate(getmoduleid()) 
	CALL init_a_ar() #init a/ar module 
	
	CALL ACA_main()
END MAIN