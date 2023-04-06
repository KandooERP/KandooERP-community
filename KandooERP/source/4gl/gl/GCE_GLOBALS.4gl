############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_DATABASE.4gl"
GLOBALS 
	DEFINE glob_rec_bank RECORD LIKE bank.* 
	DEFINE glob_rec_trans_head RECORD 
		tran_date DATE, 
		open_bal_amt LIKE bank.state_bal_amt, 
		close_bal_amt LIKE bank.state_bal_amt, 
		ref_text DATE 
	END RECORD
	DEFINE glob_temp_amt decimal(16,2) 
--	DEFINE glob_temp_text char(40) 
	DEFINE glob_debug_rec_bankstatement RECORD LIKE bankstatement.*
END GLOBALS 
