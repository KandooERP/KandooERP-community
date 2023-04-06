############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_DATABASE.4gl" 

GLOBALS 
	DEFINE glob_rec_opparms RECORD LIKE opparms.* 
	DEFINE glob_rec_corpcust RECORD LIKE customer.* 
	DEFINE glob_rec_warehouse RECORD LIKE warehouse.* 
	DEFINE glob_rec_customership RECORD LIKE customership.* 
	DEFINE glob_curr_inv_amt LIKE invoicehead.total_amt 
	DEFINE glob_overdue LIKE customer.over1_amt 
	DEFINE glob_baddue LIKE customer.over1_amt
	
	#Field list for validation and navigation
	CONSTANT A21_INV_LINE_FIELD_WARE_CODE STRING = "ware_code"
	CONSTANT A21_INV_LINE_FIELD_PART_CODE STRING = "part_code"
	CONSTANT A21_INV_LINE_FIELD_LINE_TEXT STRING = "line_text"
	CONSTANT A21_INV_LINE_FIELD_LINE_ACCT_CODE STRING = "line_acct_code"
				
END GLOBALS 
