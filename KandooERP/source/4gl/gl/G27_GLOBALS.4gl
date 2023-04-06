############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_DATABASE.4gl"
GLOBALS 
	DEFINE glob_rec_batchhead RECORD LIKE batchhead.* 
	DEFINE glob_err_message CHAR(70) 
	DEFINE glob_where_text CHAR(20) 
	DEFINE glob_load_file CHAR(100) 
	DEFINE glob_process_cnt INTEGER 
	DEFINE glob_kandoo_gl_cnt INTEGER 
	DEFINE glob_err_cnt INTEGER 
	DEFINE glob_err2_cnt INTEGER 
	DEFINE glob_total_db_amt LIKE batchhead.debit_amt 
	DEFINE glob_total_cr_amt LIKE batchhead.debit_amt 
	DEFINE glob_jmj_cmpy_code LIKE company.cmpy_code 
	DEFINE glob_auto_cmpy_code LIKE company.cmpy_code 
	DEFINE glob_verbose_ind LIKE batchhead.jour_num 
	DEFINE glob_jour_num LIKE batchhead.jour_num 
	DEFINE glob_load_file_ind SMALLINT ## glob_load_file_ind indicates IF we NEED TO 
	## LOAD FROM a load file
	## (reqd. b/c G27 can be invoked FROM ASI_J
	##  WHERE the LOAD FROM already performed )

	DEFINE glob_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx] lazy globals
END GLOBALS 
