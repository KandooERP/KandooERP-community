############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_DATABASE.4gl"
GLOBALS 
	DEFINE glob_tot_appl DECIMAL(16,2) 
	DEFINE glob_totp_appl DECIMAL(16,2) 
	DEFINE glob_ref_text LIKE arparms.credit_ref1_text 
	
	DEFINE glob_amt DECIMAL(16,2) 
	DEFINE glob_appl DECIMAL(16,2) 
	DEFINE glob_toty_amt DECIMAL(16,2) 
	DEFINE glob_toty_appl DECIMAL(16,2) 
--glob_rec_arparms record
--   credit_ref1_text LIKE arparms.credit_ref1_text,
--   credit_ref2a_text LIKE arparms.credit_ref2a_text,
--   credit_ref2b_text LIKE arparms.credit_ref2b_text
--END RECORD,

END GLOBALS
