############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_DATABASE.4gl" 
GLOBALS 
	DEFINE glob_update_ind SMALLINT ## true = UPDATE database, false = REPORT only 
--	DEFINE glob_rec_s_kandooreport RECORD LIKE kandooreport.*
	DEFINE glob_rec_loadparms RECORD LIKE loadparms.*
	DEFINE glob_s_output CHAR(50)
	DEFINE glob_load_file CHAR(60)
	DEFINE glob_err_message CHAR(80)
	DEFINE glob_err_cnt INTEGER
	DEFINE glob_err_text CHAR(80)  #was CHAR(200)
	DEFINE glob_verbose_indv SMALLINT 
	DEFINE glob_rec_invoicehead RECORD LIKE invoicehead.*
END GLOBALS 
