############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_DATABASE.4gl"
GLOBALS
	DEFINE glob_amt DECIMAL(16,2) 
	DEFINE glob_disc DECIMAL(16,2) 
	DEFINE glob_paid DECIMAL(16,2) 
	DEFINE glob_toty_amt DECIMAL(16,2) 
	DEFINE glob_toty_paid DECIMAL(16,2) 
	DEFINE glob_toty_disc DECIMAL(16,2) 
--	DEFINE glob_totp_amt DECIMAL(16,2) 
	DEFINE glob_totp_paid DECIMAL(16,2) 
	DEFINE glob_totp_disc DECIMAL(16,2) 
#glob_rec_arparms record
#   glob_inv_ref2a_text LIKE arparms.inv_ref2a_text,
#   glob_inv_ref2b_text LIKE arparms.inv_ref2b_text
#END RECORD
END GLOBALS