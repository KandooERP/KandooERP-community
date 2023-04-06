############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "../ar/A_AR_GLOBALS.4gl"
GLOBALS "../ar/AS_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/ASAa_GLOBALS.4gl" 
############################################################
# Module Scope Variables
############################################################
--DEFINE modu_where_part CHAR(700) 
--DEFINE modu_query_text CHAR(700) 
--DEFINE modu_answer CHAR(1)
--DEFINE modu_ans CHAR(1)
--DEFINE modu_id_flag SMALLINT 
--DEFINE modu_idx SMALLINT 
--DEFINE modu_cnt SMALLINT 
--DEFINE modu_err_flag SMALLINT 
--DEFINE modu_mrow SMALLINT 
DEFINE modu_exist SMALLINT 
DEFINE modu_chosen SMALLINT 
DEFINE modu_number_labels SMALLINT 
#########################################################################
# MAIN
#
# \brief module ASA Allows the user TO PRINT mailing labels FOR Customers
# Printing labels FOR design warehouse
#########################################################################
MAIN 
	DEFER quit 
	DEFER interrupt 
	
	CALL setModuleId("ASA") 
	CALL ui_init(0) #initial ui init 
	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_a_ar() #init a/ar module 

	CALL ASAa_main() 
END MAIN 