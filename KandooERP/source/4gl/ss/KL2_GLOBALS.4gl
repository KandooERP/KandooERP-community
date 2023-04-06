############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl"

GLOBALS 
	DEFINE 
	err_message,winds_text CHAR(40), 
	pr_subhead RECORD LIKE subhead.*, 
	pr_substype RECORD LIKE substype.*, 
	pr_tentinvhead RECORD LIKE tentinvhead.*, 
	pr_subdetl RECORD LIKE subdetl.*, 
	pr_company RECORD LIKE company.*, 
	invalid_period SMALLINT, 
	total_cost,total_sale,total_tax DECIMAL(16,2), 
	where_text,query_text CHAR(800), 
	rpt_wid SMALLINT, 
	rpt_time CHAR(8), 
	rpt_date CHAR(10), 
	rpt_length INTEGER, 
	rpt_pageno INTEGER, 
	pr_output, pr_output1, pr_output2 CHAR(40), 
	pr_tot_amt DECIMAL(16,2), 
	pr_temp_text CHAR(60) 
END GLOBALS 
