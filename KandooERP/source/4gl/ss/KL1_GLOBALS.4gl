############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl"

GLOBALS 
	DEFINE 
	pr_subhead RECORD LIKE subhead.*, 
	pr_subdetl RECORD LIKE subdetl.*, 
	pr_subschedule RECORD LIKE subschedule.*, 
	pr_ssparms RECORD LIKE ssparms.*, 
	pr_sub_type LIKE substype.type_code, 
	pr_issue_date DATE, 
	pr_back_ind CHAR(1), 
	pr_issue_num INTEGER, 
	pr_temp_text CHAR(300), 
	pr_label RECORD 
		cust_code CHAR(8), 
		ship_code CHAR(8), 
		name_text CHAR(40), 
		sub_num INTEGER, 
		sub_line_num INTEGER, 
		part_code CHAR(15), 
		ware_code CHAR(3), 
		pr_issue_qty FLOAT, 
		issue_num INTEGER, 
		rev_num INTEGER 
	END RECORD, 
	pr_pcode RECORD 
		state_code CHAR(1), 
		post_code CHAR(4), 
		rec_cnt INTEGER 
	END RECORD, 
	query_text CHAR(500), 
	rpt_wid SMALLINT, 
	print_feeder SMALLINT, 
	rpt_time CHAR(8), 
	rpt_date CHAR(10), 
	rpt_length INTEGER, 
	rpt_pageno INTEGER, 
	pr_label_format CHAR(1), 
	pr_desc,pr_line1,pr_line2 CHAR(60), 
	pr_run_type CHAR(8), 
	pr_company RECORD LIKE company.*, 
	pr_arparms RECORD LIKE arparms.*, 
	where1_text,where2_text,where3_text CHAR(100) 
END GLOBALS 
