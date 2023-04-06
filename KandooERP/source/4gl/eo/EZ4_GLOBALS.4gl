###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_DATABASE.4gl" 
# Maintainence Program FOR Carriers.
GLOBALS 
	DEFINE glob_country_code LIKE country.country_code #not used 
	DEFINE glob_state_code LIKE carrier.state_code #not used 
	DEFINE glob_rec_country RECORD LIKE country.* 
	DEFINE glob_rec_carrier RECORD LIKE carrier.* 
END GLOBALS 