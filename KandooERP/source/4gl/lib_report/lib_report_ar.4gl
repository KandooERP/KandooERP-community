############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl"

############################################################
# GFUNCTION init_report_ar()
#
# Retrieve default report header etc.. text from arparms
############################################################

FUNCTION init_report_ar()

	#have to get more information on the usage or report text 
	#this function is not completed yet - but used
	LET glob_rec_rpt_selector.ref1_text = glob_rec_arparms.inv_ref1_text
	LET glob_rec_rpt_selector.ref2_text = glob_rec_arparms.inv_ref2a_text
	
	#glob_rec_arparms.inv_ref1_text, 
	#glob_rec_arparms.inv_ref2a_text, 
	#glob_rec_arparms.inv_ref2b_text 
	#CALL rpt_update_rmsreps()
	
END FUNCTION