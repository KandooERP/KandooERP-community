############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_DATABASE.4gl" 
GLOBALS 
	DEFINE glob_rec_arparms RECORD LIKE arparms.*  #AR (Accounts Receivable) Configuration record
	DEFINE glob_rec_statparms RECORD LIKE statparms.*  #Statistics Configuration record
END GLOBALS 
