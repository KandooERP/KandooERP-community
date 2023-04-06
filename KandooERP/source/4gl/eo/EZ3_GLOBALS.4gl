###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_DATABASE.4gl" 

GLOBALS 
	DEFINE glob_rec_year_type 
	RECORD 
		year_num LIKE statint.year_num, 
		type_code LIKE statint.type_code 
	END RECORD 
	DEFINE glob_temp_text VARCHAR(200) --char(200) 
END GLOBALS 