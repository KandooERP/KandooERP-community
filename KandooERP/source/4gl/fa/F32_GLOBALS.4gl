############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl"

GLOBALS 
	DEFINE batch_numeric INTEGER 
	DEFINE program_name CHAR(40) 
	DEFINE screen_no CHAR(6) 
	DEFINE falocation_trn RECORD LIKE falocation.* 
	DEFINE ans CHAR(1) 
	DEFINE the_rowid INTEGER 
	DEFINE flag CHAR(1) 
	DEFINE counter SMALLINT 
	DEFINE switch_char CHAR(1) 
	DEFINE try_again CHAR(1) 
	DEFINE err_message CHAR(60) 
	DEFINE where_text CHAR(200) 
	DEFINE query_text CHAR(250) 
	DEFINE exist INTEGER 
	DEFINE not_found INTEGER 
	DEFINE array_rec ARRAY [200] OF 
	RECORD 
		location_code LIKE falocation.location_code, 
		location_text LIKE falocation.location_text 
	END RECORD 
	DEFINE array_rec2 ARRAY [200] OF 
	RECORD 
		manager_text LIKE falocation.manager_text, 
		loc_add1_text LIKE falocation.loc_add1_text, 
		loc_add2_text LIKE falocation.loc_add2_text, 
		loc_add3_text LIKE falocation.loc_add3_text, 
		loc_add4_text LIKE falocation.loc_add4_text 
	END RECORD 
END GLOBALS 
