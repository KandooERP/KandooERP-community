############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_DATABASE.4gl"
GLOBALS 
	DEFINE glob_default_text CHAR(30)  
	DEFINE glob_default_ref LIKE batchdetl.ref_text
	DEFINE glob_default_anal LIKE batchdetl.analysis_text 
	DEFINE glob_rec_1_batchhead RECORD LIKE batchhead.* #header BEFORE edit 
	DEFINE glob_rec_2_batchhead RECORD LIKE batchhead.* #header BEFORE UPDATE 
	DEFINE glob_rec_batchhead RECORD LIKE batchhead.*  
	DEFINE glob_fv_cash_book CHAR(1) 
	DEFINE glob_desc_ind LIKE language.yes_flag
END GLOBALS 
