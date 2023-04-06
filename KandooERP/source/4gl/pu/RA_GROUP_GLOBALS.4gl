############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

GLOBALS 
	DEFINE level CHAR(1) 
	DEFINE msg CHAR(40)
	DEFINE prog CHAR(40)	 
	DEFINE cmd CHAR(3) 
	DEFINE itis DATE 
	DEFINE query_text STRING 
	DEFINE where_part STRING
	DEFINE pr_company RECORD LIKE company.* 
	DEFINE pr_rec_kandoouser RECORD LIKE kandoouser.* 
	DEFINE prg_name CHAR(7) 
END GLOBALS