############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_DATABASE.4gl"
GLOBALS 
	DEFINE glob_progname CHAR(25) 
	DEFINE glob_menupath CHAR(3) 
	DEFINE glob_filename CHAR(60) 
	DEFINE glob_security_ind LIKE kandoouser.security_ind 
	DEFINE glob_query_1 CHAR(500) 
	DEFINE glob_scurs_hdr_open INTEGER 
	DEFINE glob_array_size INTEGER 
	DEFINE glob_num_rows INTEGER 
	DEFINE glob_rec_rpthead RECORD LIKE rpthead.* 
	DEFINE glob_rec_rptpos RECORD LIKE rptpos.* 
	DEFINE glob_rec_rpttype RECORD LIKE rpttype.* 
	DEFINE glob_rec_rndcode RECORD LIKE rndcode.* 
	DEFINE glob_rec_signcode RECORD LIKE signcode.* 

END GLOBALS 
