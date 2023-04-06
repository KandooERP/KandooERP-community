#GLOBALS file for ALL I/IN Warehouse modules (Inventory Management)
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_DATABASE.4gl" 
GLOBALS 
	DEFINE msgresp LIKE language.yes_flag #this joke needs TO GO as soon we cleanup all files/functions 
	DEFINE glob_rec_inparms RECORD LIKE inparms.*
END GLOBALS 
