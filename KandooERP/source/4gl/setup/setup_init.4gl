GLOBALS "lib_db_globals.4gl"
 
 
###############################################
# FUNCTION initStrings()
###############################################
FUNCTION initStrings()

	LET gl_recStep[1].title =     "Location (Language, Country etc.)"
	LET gl_recStep[1].step_name = "Language/Location"
	LET gl_recStep[1].console =   "Specified Language, Country AND Curency"
		
	LET gl_recStep[2].title =     "GL Initial Parameter"
	LET gl_recStep[2].step_name = "GL Basics"
	LET gl_recStep[2].console =   "Initial GL Parameters including fiscal year/period"

	LET gl_recStep[3].title =     "Company Details"
	LET gl_recStep[3].step_name = "Company"
	LET gl_recStep[3].console =   "Company Base Data"	

	LET gl_recStep[4].title =     "Enable Modules"
	LET gl_recStep[4].step_name = "Modules"
	LET gl_recStep[4].console =   "Select/De-select which modules should be available for this company"	

	LET gl_recStep[5].title =     "Admin User Account"
	LET gl_recStep[5].step_name = "Administrator Account"
	LET gl_recStep[5].console =   "Adminisrator Password AND Email Address"	

	LET gl_recStep[6].title =     "Initial/First Bank Account Setup"
	LET gl_recStep[6].step_name = "Bank Account"
	LET gl_recStep[6].console = 	"Initial Bank Account Setup"	

	LET gl_recStep[7].title =     "AP-Accounts Payable Configuration/Parameters"
	LET gl_recStep[7].step_name = "AP-Accounts Payable"
	LET gl_recStep[7].console =   "Default Configuration/Parameter for the AP-Accounts Payable Modules"	

	LET gl_recStep[8].title =     "AR-Accounts Receivable Configuration/Parameters"
	LET gl_recStep[8].step_name = "AR-Accounts Receivable"
	LET gl_recStep[8].console =   "Default Configuration/Parameter for the AR-Accounts Receivable Modules"	

	LET gl_recStep[9].title =     "Load Default Lookup/List Data"
	LET gl_recStep[9].step_name = "Lookup Data Import"		
	LET gl_recStep[9].console = 	"Loading default lookup Data (for comboBoxes AND List's"	

	#LET gl_recStep[10].title =     "xxxxxp"
	#LET gl_recStep[10].step_name = "Finalize DB Population"
	#LET gl_recStep[10].console = "Writing Data TO the Database"	

	LET gl_recStep[10].title =     "Run Sub-Setup Modules"
	LET gl_recStep[10].step_name = "Sub-Setup Modules"
	LET gl_recStep[10].console =   "Choose the corresponding sub-module configuration tools"	


	
END FUNCTION