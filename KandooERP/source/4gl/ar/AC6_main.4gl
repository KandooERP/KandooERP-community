# 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
#
###########################################################################
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl"
GLOBALS "../ar/AC_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/AC6_GLOBALS.4gl"
#####################################################################
# MAIN
#
# AC6 IS TO PRINT daily Bank Deposit Slips
#
# TO get the summary AT the top of the form we have TO do two passes.
# The first one outputs the cashreceipt TO a temp table AND updates the
# cashreceipt.banked_flag TO Y AND sets the banked_date TO today.
# It THEN calculates the summary totals.
# The second pass reads the temp table AND actually writes the REPORT.
# In this way we cover ourselves in the multi-user environment
# against another operator adding receipts WHILE the program runs.
#
# The temporary table IS created first thing in 'main' so it IS only
# ever created once in the running of the program.
#####################################################################
MAIN 
	DEFER interrupt 
	DEFER quit

	CALL setModuleId("AC6") 
	CALL ui_init(0) 	#Initial UI Init
	CALL authenticate(getmoduleid()) 
	CALL init_a_ar() #init a/ar module 
	CALL AC6_main() 
END MAIN 