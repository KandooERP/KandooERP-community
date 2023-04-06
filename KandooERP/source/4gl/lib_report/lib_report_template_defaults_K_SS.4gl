############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl" 

#####################################################################
# FUNCTION rpt_set_kandooreport_defaults(NULL)
#
# Set the default report parameters
#####################################################################
FUNCTION rpt_set_kandooreport_defaults_K_SS(p_rec_kandooreport)
	DEFINE p_rec_kandooreport RECORD LIKE kandooreport.*
	

	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	
	CASE upshift(p_rec_kandooreport.report_code)

		WHEN "K15"
			LET p_rec_kandooreport.header_text = "Corporate Subscription entry"
			LET p_rec_kandooreport.line1_text = "Corporate Subscription renewal"
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "K15"
			LET p_rec_kandooreport.selection_flag= "N" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "N" 

		WHEN "KA1"
			LET p_rec_kandooreport.header_text = "KA1 Proposed Subscriptions"
			LET p_rec_kandooreport.line1_text = ""
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "KA1"
			LET p_rec_kandooreport.selection_flag= "N" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "N" 

		WHEN "KA1-OK"
			LET p_rec_kandooreport.header_text = "Successfully Generated Subscription log"
			LET p_rec_kandooreport.line1_text = ""
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "KA1"
			LET p_rec_kandooreport.selection_flag= "N" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "N" 

		WHEN "KA1-ERROR"
			LET p_rec_kandooreport.header_text = "Subscription Generation Error log"
			LET p_rec_kandooreport.line1_text = "KA1 Generated Invoice log"
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "KA1"
			LET p_rec_kandooreport.selection_flag= "N" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "N" 			


		WHEN "KL1-EXCEP"
			LET p_rec_kandooreport.header_text = "Successfully Generated Subscription log"
			LET p_rec_kandooreport.line1_text = ""
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "KL1"
			LET p_rec_kandooreport.selection_flag= "N" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "N" 

		WHEN "KL1-INVOICE"
			LET p_rec_kandooreport.header_text = "Successfully Generated Subscription log"
			LET p_rec_kandooreport.line1_text = ""
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "KL1"
			LET p_rec_kandooreport.selection_flag= "N" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "N" 
			
		WHEN "KL1-SUB-LABEL"
			LET p_rec_kandooreport.header_text = "Successfully Generated Subscription log"
			LET p_rec_kandooreport.line1_text = ""
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "KL1"
			LET p_rec_kandooreport.selection_flag= "N" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "N" 		
			
		WHEN "KL1-DATA-LABEL"
			LET p_rec_kandooreport.header_text = "Successfully Generated Subscription log"
			LET p_rec_kandooreport.line1_text = ""
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "KL1"
			LET p_rec_kandooreport.selection_flag= "N" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "N" 					

		WHEN "KL1-PO-CODE"
			LET p_rec_kandooreport.header_text = "Successfully Generated Subscription log"
			LET p_rec_kandooreport.line1_text = ""
			LET p_rec_kandooreport.width_num = 60 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "KL1"
			LET p_rec_kandooreport.selection_flag= "N" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "N" 

		WHEN "KL1-CUST"
			LET p_rec_kandooreport.header_text = "Successfully Generated Subscription log"
			LET p_rec_kandooreport.line1_text = ""
			LET p_rec_kandooreport.width_num = 80 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "KL1"
			LET p_rec_kandooreport.selection_flag= "N" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "N"				

		WHEN "KL2-INV_ERROR"
			LET p_rec_kandooreport.header_text = "Invoice Generation Error log"
			LET p_rec_kandooreport.line1_text = ""
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "KL2"
			LET p_rec_kandooreport.selection_flag= "N" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "N" 

		WHEN "KL2-INV_SUCCESS"
			LET p_rec_kandooreport.header_text = "Successfully Generated Invoice log"
			LET p_rec_kandooreport.line1_text = ""
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "KL2"
			LET p_rec_kandooreport.selection_flag= "N" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "N" 

		WHEN "KL2-INV_PROPOSAL"
			LET p_rec_kandooreport.header_text = "Proposed Invoice Generation (SUBS)"
			LET p_rec_kandooreport.line1_text = "KL2 Proposed Subscription Invoices"
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "KL2"
			LET p_rec_kandooreport.selection_flag= "N" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "N" 


		WHEN "KR1"
			LET p_rec_kandooreport.header_text = "Customer Subscription Listing"
			LET p_rec_kandooreport.line1_text = ""
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "KR1"
			LET p_rec_kandooreport.selection_flag= "N" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "N" 

		WHEN "KR2"
			LET p_rec_kandooreport.header_text = "Customer Subscription Audit listing"
			LET p_rec_kandooreport.line1_text = ""
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "KR2"
			LET p_rec_kandooreport.selection_flag= "N" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "N" 

		WHEN "KS1"
			LET p_rec_kandooreport.header_text = "Customer Subscription Listing"
			LET p_rec_kandooreport.line1_text = ""
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "KS1"
			LET p_rec_kandooreport.selection_flag= "N" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "N" 

		WHEN "KS2-ERROR"
			LET p_rec_kandooreport.header_text = "Subscription Load Error Report"
			LET p_rec_kandooreport.line1_text = ""
			LET p_rec_kandooreport.width_num = 80 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "KS2"
			LET p_rec_kandooreport.selection_flag= "N" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "N" 

		WHEN "KS2-SUBSCRIPTION"
			LET p_rec_kandooreport.header_text = "Subscription Load Subscription Report"
			LET p_rec_kandooreport.line1_text = ""
			LET p_rec_kandooreport.width_num = 80 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "KS2"
			LET p_rec_kandooreport.selection_flag= "N" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "N" 

		WHEN "KS2-INVOICE"
			LET p_rec_kandooreport.header_text = "Subscription Load Invoice Report"
			LET p_rec_kandooreport.line1_text = ""
			LET p_rec_kandooreport.width_num = 80 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "KS2"
			LET p_rec_kandooreport.selection_flag= "N" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "N" 



		OTHERWISE
			LET p_rec_kandooreport.header_text = "MISSING IN DEFAULT TEMPLATES"

	END CASE

	RETURN p_rec_kandooreport.* 		 
END FUNCTION  