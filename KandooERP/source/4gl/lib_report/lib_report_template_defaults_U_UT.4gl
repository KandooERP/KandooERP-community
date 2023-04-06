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
FUNCTION rpt_set_kandooreport_defaults_U_UT(p_rec_kandooreport)
	DEFINE p_rec_kandooreport RECORD LIKE kandooreport.*
	

	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	
	CASE upshift(p_rec_kandooreport.report_code)

		WHEN "U14"
			LET p_rec_kandooreport.header_text = "Kandoo log Message/Error Report" 
			LET p_rec_kandooreport.width_num = 80 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "U14" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N	
			LET p_rec_kandooreport.line1_text = "Menu Listing"
			
		WHEN "U18"
			LET p_rec_kandooreport.header_text = "U18 SQL Interface" 
			LET p_rec_kandooreport.width_num = 80 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "U18" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N	
			
		WHEN "U2A"
			LET p_rec_kandooreport.header_text = "ERP System - Menu List" 
			LET p_rec_kandooreport.width_num = 80 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "U2A" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N	
			LET p_rec_kandooreport.line1_text = "Menu Listing"

		WHEN "U2B"
			LET p_rec_kandooreport.header_text = "ERP System - User Security Report" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "U2B" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "N"	
			LET p_rec_kandooreport.line1_text = "Menu Listing"

		WHEN "U32-L"
			LET p_rec_kandooreport.header_text = "ERP System - Message Library Report - by Language" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "U32" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "N"	

		WHEN "U32-S"
			LET p_rec_kandooreport.header_text = "ERP System - Message Library Report - by Source/Message" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "U32" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "N"	

		WHEN "U51"
			LET p_rec_kandooreport.header_text = "U51 - Suburb Audit Log" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "U51" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "N"	

		WHEN "U55"
			LET p_rec_kandooreport.header_text = "U55 - Suburbs Automatically Loaded" 
			LET p_rec_kandooreport.width_num = 80 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "U55" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "N"
			LET p_rec_kandooreport.line1_text = "Suburbs Automatically Loaded FOR " #, pr_state_code

		WHEN "U56"
			LET p_rec_kandooreport.header_text = "Quadrant Transfer Error Report" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "U56" 
			LET p_rec_kandooreport.selection_flag = "N" 
			LET p_rec_kandooreport.line1_text = " Line Number Error Text" 

		WHEN "U57"
			LET p_rec_kandooreport.header_text = "Suburb Distances Error Report" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "U57" 
			LET p_rec_kandooreport.selection_flag = "N" 
			LET p_rec_kandooreport.line1_text = " Line Number Error Text" 

		WHEN "UN2"
			LET p_rec_kandooreport.header_text = "Notes" 
			LET p_rec_kandooreport.width_num = 80 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "UN2" 
			LET p_rec_kandooreport.selection_flag = "N" 
													
		OTHERWISE
			LET p_rec_kandooreport.header_text = "MISSING IN DEFAULT TEMPLATES"

	END CASE

	RETURN p_rec_kandooreport.* 		 
END FUNCTION 