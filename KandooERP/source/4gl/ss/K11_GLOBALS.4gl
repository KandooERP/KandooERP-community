############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl"
GLOBALS 
	DEFINE 
	yes_flag LIKE language.yes_flag, 
	no_flag LIKE language.no_flag, 
	pr_company RECORD LIKE company.*, 
	pr_rec_kandoouser RECORD LIKE kandoouser.*, 
	pr_ssparms RECORD LIKE ssparms.*, 
	pr_arparms RECORD LIKE arparms.*, 
	pr_glparms RECORD LIKE glparms.*, 
	pr_country RECORD LIKE country.*, 
	pr_subhead RECORD LIKE subhead.*, 
	pr_csubhead RECORD LIKE subhead.*, 
	pr_gsubdetl RECORD LIKE subdetl.*, 
	pr_customer RECORD LIKE customer.*, 
	pr_warehouse RECORD LIKE warehouse.*, 
	pr_inv_prompt CHAR(60), 
	pr_paid_amt DECIMAL(16,2), 
	err_message CHAR(40), 
	pr_credit SMALLINT, 
	pr_growid INTEGER, 
	rpt_wid SMALLINT, 
	rpt_time CHAR(8), 
	rpt_date CHAR(10), 
	rpt_length INTEGER, 
	rpt_pageno INTEGER, 
	pr_output CHAR(60), 
	pr_currsub_amt DECIMAL(16,2)#,## CURRENT ORDER total amount 
	#pr_temp_text CHAR(500)       ## Temp scratch pad variable
END GLOBALS 
