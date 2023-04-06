############################################################
# MODULE Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

DEFINE modu_master_cmpy_code LIKE company.cmpy_code #Used by SYSTEM Admin and for loalized templates
	
	
	#NOTE: Currently, master company is ALWAYS "99"
	
FUNCTION mastercmpy_get_cmpy_code(p_country_code,p_language_code)
	DEFINE p_country_code LIKE company.country_code
	DEFINE p_language_code LIKE company.language_code
	
	#This needs completing when we have multiple master companies
	#For different countries etc..	
	LET modu_master_cmpy_code = "99" #For now, we return original-code master company
	RETURN modu_master_cmpy_code
END FUNCTION	