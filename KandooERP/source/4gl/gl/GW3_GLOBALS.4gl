############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_DATABASE.4gl"
GLOBALS 

	DEFINE glob_progname CHAR(25) 
	DEFINE glob_menupath CHAR(3) 
	DEFINE glob_filename CHAR(60) 
	DEFINE glob_security_ind LIKE kandoouser.security_ind 
	DEFINE glob_query_1 CHAR(500) 
	DEFINE glob_scurs_col_open INTEGER 
	DEFINE glob_array_size INTEGER 
	DEFINE glob_coldesc_cnt INTEGER 
	DEFINE glob_colitem_cnt INTEGER 
	DEFINE glob_ptr_id INTEGER 
	DEFINE glob_num_rows INTEGER 
	DEFINE glob_id_col_id LIKE colitemcolid.id_col_id 
	DEFINE glob_rec_rpthead RECORD LIKE rpthead.* 
	DEFINE glob_rec_rptcol RECORD LIKE rptcol.* 
	DEFINE glob_rec_rptcoldesc RECORD LIKE rptcoldesc.* 
	DEFINE glob_rec_colitem RECORD LIKE colitem.* 
	DEFINE glob_rec_mrwitem RECORD LIKE mrwitem.* 
	DEFINE glob_rec_mrwparms RECORD LIKE mrwparms.* 

	DEFINE glob_arr_recrptcoldesc array[4] OF 
	RECORD 
		col_desc LIKE rptcoldesc.col_desc 
	END RECORD 

	DEFINE glob_arr_reccolitem array[20] OF 
	RECORD 
		seq_num LIKE colitem.seq_num, 
		id_col_id LIKE colitemcolid.id_col_id, 
		item_operator LIKE colitem.item_operator, 
		col_item LIKE colitem.col_item, 
		item_desc LIKE mrwitem.item_desc 
	END RECORD 

END GLOBALS 
