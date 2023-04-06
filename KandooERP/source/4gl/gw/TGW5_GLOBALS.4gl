############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_DATABASE.4gl"
GLOBALS 
	DEFINE formname CHAR(15), 

	gv_progname CHAR(25), 
	gv_menupath CHAR(3), 
	gv_security_ind LIKE kandoouser.security_ind, 
	gv_query_1 CHAR(500), 
	gv_scurs_def_open, 
	gv_array_size, 
	gv_num_rows INTEGER, 
	rpt_wid SMALLINT, 
	rpt_date DATE, 
	pr_output CHAR(60), 
	rpt_time CHAR(10), 
	rpt_note CHAR(80), 
--	rpt_pageno LIKE rmsreps.page_num, 
--	rpt_length LIKE rmsreps.page_length_num, 
	gr_rpthead RECORD LIKE rpthead.*, 
	gr_rptcolgrp RECORD LIKE rptcolgrp.*, 
	gr_rptlinegrp RECORD LIKE rptlinegrp.*, 
	gr_mrwparms RECORD LIKE mrwparms.*, 
	gv_from_line_id, 
	gv_to_line_id SMALLINT, 
	gv_test, 
	gv_colline CHAR(1) 

END GLOBALS 
