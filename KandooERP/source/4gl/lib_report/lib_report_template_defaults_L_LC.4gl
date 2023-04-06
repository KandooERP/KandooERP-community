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
FUNCTION rpt_set_kandooreport_defaults_L_LC(p_rec_kandooreport)
	DEFINE p_rec_kandooreport RECORD LIKE kandooreport.*
	

	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	
	CASE upshift(p_rec_kandooreport.report_code)

		WHEN "LA1" 
			LET p_rec_kandooreport.header_text = "Shipment Detail List " 
			LET p_rec_kandooreport.menupath_text = "LA1" 
			LET p_rec_kandooreport.width_num = 80  
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "N" #Supports background (none-ui) process Y/N
			LET p_rec_kandooreport.line1_text = ""
			LET p_rec_kandooreport.bottom_margin = 0
			LET p_rec_kandooreport.left_margin = 0
			LET p_rec_kandooreport.top_margin = 0
			--LET p_rec_kandooreport.page_length = 66
			LET p_rec_kandooreport.right_margin	= 80	

		WHEN "LA2" 
			LET p_rec_kandooreport.header_text = "Goods Receipt Binning List" 
			LET p_rec_kandooreport.menupath_text = "LA2" 
			LET p_rec_kandooreport.width_num = 80  
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "N" #Supports background (none-ui) process Y/N
			LET p_rec_kandooreport.line1_text = ""
			LET p_rec_kandooreport.bottom_margin = 0
			LET p_rec_kandooreport.left_margin = 0
			LET p_rec_kandooreport.top_margin = 0
			--LET p_rec_kandooreport.page_length = 66
			LET p_rec_kandooreport.right_margin	= 80	


		WHEN "LA3" 
			LET p_rec_kandooreport.header_text = "Detailed Receipt Report" 
			LET p_rec_kandooreport.menupath_text = "LA3" 
			LET p_rec_kandooreport.width_num = 120  
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "N" #Supports background (none-ui) process Y/N
			LET p_rec_kandooreport.line1_text = ""
			LET p_rec_kandooreport.bottom_margin = 0
			LET p_rec_kandooreport.left_margin = 0
			LET p_rec_kandooreport.top_margin = 0
			--LET p_rec_kandooreport.page_length = 66
			LET p_rec_kandooreport.right_margin	= 120	

		WHEN "LA4" 
			LET p_rec_kandooreport.header_text = "Shipments By Voucher" 
			LET p_rec_kandooreport.menupath_text = "LA4" 
			LET p_rec_kandooreport.width_num = 80  
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "N" #Supports background (none-ui) process Y/N
			LET p_rec_kandooreport.line1_text = ""
			LET p_rec_kandooreport.bottom_margin = 0
			LET p_rec_kandooreport.left_margin = 0
			LET p_rec_kandooreport.top_margin = 0
			--LET p_rec_kandooreport.page_length = 66
			LET p_rec_kandooreport.right_margin	= 80	


		WHEN "LA5" 
			LET p_rec_kandooreport.header_text = "Credit Shipment Detail Report" 
			LET p_rec_kandooreport.menupath_text = "LA5" 
			LET p_rec_kandooreport.width_num = 132  
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "N" #Supports background (none-ui) process Y/N
			LET p_rec_kandooreport.line1_text = ""
			LET p_rec_kandooreport.bottom_margin = 0
			LET p_rec_kandooreport.left_margin = 1
			LET p_rec_kandooreport.top_margin = 0
			--LET p_rec_kandooreport.page_length = 66
			LET p_rec_kandooreport.right_margin	= 132	

		WHEN "LA6" 
			LET p_rec_kandooreport.header_text = "Shipment Summary List" 
			LET p_rec_kandooreport.menupath_text = "LA6" 
			LET p_rec_kandooreport.width_num = 132  
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "N" #Supports background (none-ui) process Y/N
			LET p_rec_kandooreport.line1_text = ""
			LET p_rec_kandooreport.bottom_margin = 0
			LET p_rec_kandooreport.left_margin = 0
			LET p_rec_kandooreport.top_margin = 0
			--LET p_rec_kandooreport.page_length = 66
			LET p_rec_kandooreport.right_margin	= 132	
			
			
		WHEN "LA7" 
			LET p_rec_kandooreport.header_text = "Unpaid Vouchers By Shipment" 
			LET p_rec_kandooreport.menupath_text = "LA7" 
			LET p_rec_kandooreport.width_num = 80  
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "N" #Supports background (none-ui) process Y/N
			LET p_rec_kandooreport.line1_text = ""
			LET p_rec_kandooreport.bottom_margin = 0
			LET p_rec_kandooreport.left_margin = 0
			LET p_rec_kandooreport.top_margin = 0
			--LET p_rec_kandooreport.page_length = 66
			LET p_rec_kandooreport.right_margin	= 80	


		WHEN "LCJRINTF-1" #common module 
			LET p_rec_kandooreport.header_text = "Subsidiary Ledger Posting Journal Entries" 
			LET p_rec_kandooreport.menupath_text = "LS1" 
			LET p_rec_kandooreport.width_num = 132  
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "N" #Supports background (none-ui) process Y/N
			LET p_rec_kandooreport.line1_text = "LC Shipment Final Posting Report"
			LET p_rec_kandooreport.bottom_margin = 0
			LET p_rec_kandooreport.left_margin = 1
			LET p_rec_kandooreport.top_margin = 0
			--LET p_rec_kandooreport.page_length = 66
			LET p_rec_kandooreport.right_margin	= 80	
			
		WHEN "LCJRINTF-2" #common module 
			LET p_rec_kandooreport.header_text = "Subsidiary Ledger Posting Journal Entries" 
			LET p_rec_kandooreport.menupath_text = "LS2" 
			LET p_rec_kandooreport.width_num = 132  
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "N" #Supports background (none-ui) process Y/N
			LET p_rec_kandooreport.line1_text = "LC Shipment Final Posting Report"
			LET p_rec_kandooreport.bottom_margin = 0
			LET p_rec_kandooreport.left_margin = 1
			LET p_rec_kandooreport.top_margin = 0
			--LET p_rec_kandooreport.page_length = 66
			LET p_rec_kandooreport.right_margin	= 80																					
		OTHERWISE
			LET p_rec_kandooreport.header_text = "MISSING IN DEFAULT TEMPLATES"

	END CASE

	RETURN p_rec_kandooreport.* 		 
END FUNCTION 