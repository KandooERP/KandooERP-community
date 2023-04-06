############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_DATABASE.4gl"
GLOBALS 
	--	DEFINE gv_progname      CHAR(25)
	--	DEFINE gv_menupath      CHAR(3)
	DEFINE glob_security_ind LIKE kandoouser.security_ind --used but nowhere initialised/set 
	DEFINE glob_query_1 CHAR(500) 
	DEFINE glob_scurs_def_open INTEGER 
	--	DEFINE glob_array_size INTEGER
	--	DEFINE gv_num_rows      INTEGER
	DEFINE glob_rec_rpthead RECORD LIKE rpthead.* 
	DEFINE glob_rec_mrwparms RECORD LIKE mrwparms.* 
	DEFINE glob_from_line_id SMALLINT 


END GLOBALS 
