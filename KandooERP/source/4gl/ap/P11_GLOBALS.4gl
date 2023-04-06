GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS 
	DEFINE glob_rec_vendorgrp RECORD LIKE vendorgrp.* 
	DEFINE glob_rec_country RECORD LIKE country.* 
	DEFINE glob_temp_text VARCHAR(200) 
	DEFINE glob_winds_text CHAR(20) --huho confirmed 
	DEFINE glob_sundry_vend_flag CHAR(1) --huho confirmed 

END GLOBALS 
