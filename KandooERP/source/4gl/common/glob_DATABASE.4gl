#Actual name of the runtime database will be SET FROM 'configure' OR as runtime argument
#This IS only used for the compilation time
############################################################
# GLOBAL Scope Variables - NONE
############################################################
--DATABASE kandoodb
SCHEMA kandoodb 
GLOBALS
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
END GLOBALS
