############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_DATABASE.4gl"
GLOBALS 
	DEFINE glob_rec_userlocn RECORD LIKE userlocn.* 
	DEFINE glob_rec_bank RECORD LIKE bank.* 
	DEFINE glob_bank_dep_num INTEGER 
	--DEFINE glob_option CHAR(1) 
END GLOBALS
