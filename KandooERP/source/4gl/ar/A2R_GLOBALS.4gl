############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_DATABASE.4gl"

GLOBALS 
	DEFINE glob_rec_invoicedetl RECORD LIKE invoicedetl.*
	DEFINE glob_rec_voucher RECORD LIKE voucher.*
	DEFINE glob_rec_bank RECORD LIKE bank.* 
END GLOBALS 

