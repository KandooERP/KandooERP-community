############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

GLOBALS 

	DEFINE 
	pr_fabatch RECORD LIKE fabatch.*, 
	pr_faparms RECORD LIKE faparms.*, 
	pr_faaudit RECORD LIKE faaudit.*, 
	pr_faaudit_from RECORD LIKE faaudit.*, 
	pa_faaudit array[2000] OF RECORD 
		batch_line_num LIKE faaudit.batch_line_num, 
		asset_code LIKE faaudit.asset_code, 
		add_on_code LIKE faaudit.add_on_code, 
		book_code LIKE faaudit.book_code, 
		auth_code LIKE faaudit.auth_code, 
		asset_amt LIKE faaudit.asset_amt, 
		depr_amt LIKE faaudit.depr_amt, 
		salvage_amt LIKE faaudit.salvage_amt, 
		sale_amt LIKE faaudit.sale_amt, 
		rem_life_num LIKE faaudit.rem_life_num, 
		location_code LIKE faaudit.location_code, 
		faresp_code LIKE faaudit.faresp_code, 
		facat_code LIKE faaudit.facat_code, 
		desc_text LIKE faaudit.desc_text 
	END RECORD, 
	pass_batch LIKE faaudit.batch_num, 
	next_seq INTEGER, 
	idx, failed, scrn, err_flag, arr_size, id_flag SMALLINT, 
	goon, ans CHAR(1), 

	pr_rec_kandoouser RECORD LIKE kandoouser.*, 
	try_again, date_entered CHAR (1), 
	mess CHAR(60), 
	err_message CHAR (40), 
	global_tran_code CHAR(1), 
	trans_header CHAR(24), 
	success_flag SMALLINT 
END GLOBALS 
