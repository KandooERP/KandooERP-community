############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_DATABASE.4gl"
GLOBALS 
	DEFINE glob_rec_credithead RECORD LIKE credithead.* 
	DEFINE glob_rec_credheadaddr RECORD LIKE credheadaddr.* 
	DEFINE glob_rec_warehouse RECORD LIKE warehouse.* 
	DEFINE glob_rec_orig_cred_amt LIKE credithead.total_amt 
	--  glob_credithead RECORD LIKE credithead.*,
	--  glob_credheadaddr RECORD LIKE credheadaddr.*,
	--  glob_warehouse RECORD LIKE warehouse.*,
	--  glob_orig_cred_amt LIKE credithead.total_amt
	DEFINE glob_arr_rec_creditdetl DYNAMIC ARRAY OF RECORD LIKE creditdetl.* 
END GLOBALS 