############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_DATABASE.4gl"
GLOBALS 

	DEFINE formname CHAR(15), 
	gv_progname CHAR(25), 
	gv_menupath CHAR(3), 
	gv_filename CHAR(60), 
	gv_security_ind LIKE kandoouser.security_ind, 
	gv_query_1 CHAR(500), 
	gv_query_2 CHAR(500), 
	gv_line_added, 
	gv_scurs_line_open, 
	gv_array_size, 
	gv_line_cnt, 
	gv_num_rows INTEGER, 
	gr_rptcol RECORD LIKE rptcol.*, 
	gr_rptline RECORD LIKE rptline.*, 
	gr_mrwparms RECORD LIKE mrwparms.*, 
	gr_glline RECORD LIKE glline.*, 
	gr_txtline RECORD LIKE txtline.*, 
	gr_rptlinegrp RECORD LIKE rptlinegrp.* 

	DEFINE ga_rptline array[2000] OF RECORD 
		line_id LIKE rptline.line_id, 
		line_type LIKE rptline.line_type, 
		line_desc LIKE descline.line_desc, 
		accum_id LIKE rptline.accum_id, 
		page_break_follow LIKE rptline.page_break_follow, 
		drop_lines LIKE rptline.drop_lines 
	END RECORD 

END GLOBALS 
