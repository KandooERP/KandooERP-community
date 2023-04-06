############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 
############################################################
# MODULE Scope Variables
############################################################
DEFINE modu_rec_rpt_total RECORD 
	limit_amt LIKE fundsapproved.limit_amt, 
	po_amt LIKE poaudit.line_total_amt, 
	vouch_amt LIKE voucherdist.dist_amt, 
	debit_amt LIKE debitdist.dist_amt, 
	gl_amt LIKE batchdetl.debit_amt, 
	consumed_amt LIKE fundsapproved.limit_amt, 
	available_amt LIKE fundsapproved.limit_amt 
END RECORD
############################################################
# MAIN
#
#Capital Account Report
#manu say it's Approved Funds Account Details
############################################################
MAIN 
	DEFER quit 
	DEFER interrupt 

	CALL setModuleId("GRL") 
	CALL ui_init(0) #initial ui init 
	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_g_gl() #init g/gl general ledger module 
	CALL GRL_main()
END MAIN