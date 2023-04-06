############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

GLOBALS 
	DEFINE 
	where_text CHAR(500), 
	pr_company RECORD LIKE company.*, 
	pr_rec_kandoouser RECORD LIKE kandoouser.*, 
	pr_printcodes RECORD LIKE printcodes.*, 
	pr_purchtype RECORD LIKE purchtype.*, 
	rpt_note LIKE rmsreps.report_text, 
	rpt_width LIKE rmsreps.report_width_num, 
	rpt_length LIKE rmsreps.page_length_num, 
	rpt_pageno LIKE rmsreps.page_num, 
	pr_pageno LIKE rmsreps.page_num, 
	pr_temp_text, pr_output CHAR(50) 
END GLOBALS 
