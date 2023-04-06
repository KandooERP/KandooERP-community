############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_DATABASE.4gl"
GLOBALS 
	DEFINE glob_update_ind SMALLINT ## TRUE = UPDATE database, FALSE = REPORT only 
	DEFINE glob_rec_loadparms RECORD LIKE loadparms.* 
	DEFINE glob_load_file char(60) 
	DEFINE glob_err_message char(80) 
	DEFINE glob_err_cnt INTEGER 
	DEFINE glob_gv_background char(1) 
END GLOBALS 