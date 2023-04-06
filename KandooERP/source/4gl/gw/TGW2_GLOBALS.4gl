############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_DATABASE.4gl"
GLOBALS 

	DEFINE formname CHAR(15), 
	gv_progname CHAR(25), 
	gv_menupath CHAR(3), 
	gv_filename CHAR(60), 
	gv_security_ind LIKE kandoouser.security_ind, 
	gv_query_1 CHAR(500), 
	gv_scurs_hdr_open, 
	gv_array_size, 
	gv_num_rows INTEGER, 
	gr_rpthead RECORD LIKE rpthead.*, 
	gr_rptpos RECORD LIKE rptpos.*, 
	gr_rpttype RECORD LIKE rpttype.*, 
	gr_rndcode RECORD LIKE rndcode.*, 
	gr_signcode RECORD LIKE signcode.* 

END GLOBALS 
