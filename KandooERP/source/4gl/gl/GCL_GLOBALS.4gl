############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

GLOBALS 
	DEFINE glob_tot_rows INTEGER 
	DEFINE glob_bank_code LIKE bank.bank_code 
	DEFINE glob_pagehead_date DATE
	DEFINE glob_stmt_date DATE
	DEFINE glob_pagehead_time char(5) 
	DEFINE glob_pagehead_group char(8) 
	DEFINE glob_pagehead_recv char(4) 
	DEFINE glob_temp_text char(100) 
END GLOBALS 
