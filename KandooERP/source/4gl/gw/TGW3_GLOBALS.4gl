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
	gv_scurs_col_open, 
	gv_array_size, 
	gv_coldesc_cnt, 
	gv_colitem_cnt, 
	gv_ptr_id, 
	gv_num_rows INTEGER, 
	gv_id_col_id LIKE colitemcolid.id_col_id, 
	gr_rptcol RECORD LIKE rptcol.*, 
	gr_rptcoldesc RECORD LIKE rptcoldesc.*, 
	gr_colitem RECORD LIKE colitem.*, 
	gr_mrwitem RECORD LIKE mrwitem.*, 
	gr_mrwparms RECORD LIKE mrwparms.*, 
	gr_rptcolgrp RECORD LIKE rptcolgrp.*, 
	gr_rpttype RECORD LIKE rpttype.* 

	DEFINE ga_rptcoldesc array[4] OF RECORD 
		col_desc LIKE rptcoldesc.col_desc 
	END RECORD 

	DEFINE ga_colitem array[20] OF RECORD 
		seq_num LIKE colitem.seq_num, 
		id_col_id LIKE colitemcolid.id_col_id, 
		item_operator LIKE colitem.item_operator, 
		col_item LIKE colitem.col_item, 
		item_desc LIKE mrwitem.item_desc 
	END RECORD 

END GLOBALS 
