GLOBALS "../common/glob_GLOBALS.4gl"  
GLOBALS 
	DEFINE rpt_wid LIKE rmsreps.report_width_num, 
	rpt_length LIKE rmsreps.page_length_num, 
	rpt_pageno LIKE rmsreps.page_num, 
	pr_output CHAR(50), 
	pr_err_cnt,pr_inserted_rows SMALLINT, 
	directory, loadfile CHAR(60), 
	runner CHAR(300), 
	pr_menu_path CHAR(10), 
	pr_filename, pr_filename2 CHAR(100), 
	pr_window_name CHAR(40), 
	pr_report_name CHAR(60) 
END GLOBALS 
