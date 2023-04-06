############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 


GLOBALS 
	DEFINE 

	pr_printcodes RECORD LIKE printcodes.*, 
	rpt_width,rpt_length,rpt_pageno SMALLINT, 
	rpt_note CHAR(60), 
	pr_temp_text CHAR(32), 
	pr_single_rms_flag CHAR(1) 
END GLOBALS 
