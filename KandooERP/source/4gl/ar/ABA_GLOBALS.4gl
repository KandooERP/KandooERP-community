############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_DATABASE.4gl"
GLOBALS
#glob_rec_arparms record
#   inv_ref1_text LIKE arparms.inv_ref1_text,
#   inv_ref2a_text LIKE arparms.inv_ref2a_text,
#   inv_ref2b_text LIKE arparms.inv_ref2b_text
#END RECORD,
	DEFINE glob_ref_text LIKE arparms.inv_ref1_text 
END GLOBALS
