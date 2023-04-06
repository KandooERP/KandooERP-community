############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 

GLOBALS 
	--	DEFINE glob_progname CHAR(25)
	--	DEFINE glob_menupath CHAR(3)
	--	DEFINE gv_filename CHAR(60)
	--	DEFINE gv_security_ind LIKE kandoouser.security_ind
	DEFINE glob_query_1 CHAR(500) 
	DEFINE glob_query_2 CHAR(500) 
	DEFINE gv_scurs_line_open INTEGER 
	--	DEFINE glob_array_size INTEGER
	DEFINE glob_line_cnt INTEGER 
	--	DEFINE gv_num_rows INTEGER
	DEFINE glob_rec_rpthead RECORD LIKE rpthead.* 
	--	DEFINE glob_rptcol RECORD LIKE rptcol.*
	DEFINE glob_rec_rptline RECORD LIKE rptline.* 
	DEFINE glob_rec_mrwparms RECORD LIKE mrwparms.* 
	--	DEFINE glob_rec_glline RECORD LIKE glline.*
	--	DEFINE glob_rec_txtline RECORD LIKE txtline.*

	DEFINE glob_arr_rec_rptline DYNAMIC ARRAY OF RECORD --array[2000] OF RECORD 
		line_id LIKE rptline.line_id, 
		line_type LIKE rptline.line_type, 
		line_desc LIKE descline.line_desc, 
		accum_id LIKE saveline.accum_id, 
		page_break_follow LIKE rptline.page_break_follow, 
		drop_lines LIKE rptline.drop_lines 
	END RECORD 

END GLOBALS 
