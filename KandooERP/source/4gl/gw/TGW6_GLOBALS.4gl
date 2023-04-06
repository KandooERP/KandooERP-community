############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_DATABASE.4gl"
# Purpose - This program maintains the Report Writer Groups.

GLOBALS 
	# Common global variables.
	DEFINE gv_cmpy_code LIKE company.cmpy_code, 
	gv_username LIKE kandoouser.sign_on_code, 
	gr_rec_kandoouser RECORD LIKE kandoouser.*, 
	gv_menupath CHAR(3), 
	formname CHAR(15), 
	gv_progname CHAR(25) 

END GLOBALS 
