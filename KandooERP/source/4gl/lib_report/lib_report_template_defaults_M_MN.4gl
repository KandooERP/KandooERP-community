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
FUNCTION rpt_set_kandooreport_defaults_M_MN(p_rec_kandooreport)
	DEFINE p_rec_kandooreport RECORD LIKE kandooreport.*
	

	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	
	CASE upshift(p_rec_kandooreport.report_code)

		WHEN "M18"
			LET p_rec_kandooreport.header_text = "MN Mass Product Replacement" 
			LET p_rec_kandooreport.menupath_text = "M18" 
			LET p_rec_kandooreport.width_num = 132  
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "N" #Supports background (none-ui) process Y/N

			LET p_rec_kandooreport.bottom_margin = 6
			LET p_rec_kandooreport.left_margin = 0
			LET p_rec_kandooreport.top_margin = 0
			--LET p_rec_kandooreport.page_length = 66
			LET p_rec_kandooreport.right_margin	= 132

		WHEN "M19"
			LET p_rec_kandooreport.header_text = "MN Mass Product Deletion" 
			LET p_rec_kandooreport.menupath_text = "M19" 
			LET p_rec_kandooreport.width_num = 132  
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "N" #Supports background (none-ui) process Y/N

			LET p_rec_kandooreport.bottom_margin = 6
			LET p_rec_kandooreport.left_margin = 0
			LET p_rec_kandooreport.top_margin = 0
			--LET p_rec_kandooreport.page_length = 66
			LET p_rec_kandooreport.right_margin	= 132

		WHEN "M27"
			LET p_rec_kandooreport.header_text = "MN Bill Of Resource Listing" 
			LET p_rec_kandooreport.menupath_text = "M27" 
			LET p_rec_kandooreport.width_num = 132  
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "N" #Supports background (none-ui) process Y/N

			LET p_rec_kandooreport.bottom_margin = 2
			LET p_rec_kandooreport.left_margin = 0
			LET p_rec_kandooreport.top_margin = 2
			--LET p_rec_kandooreport.page_length = 66
			LET p_rec_kandooreport.right_margin	= 132

		WHEN "M28"
			LET p_rec_kandooreport.header_text = "MN Indented Bill Of Resource Listing" 
			LET p_rec_kandooreport.menupath_text = "M28" 
			LET p_rec_kandooreport.width_num = 132  
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "N" #Supports background (none-ui) process Y/N

			LET p_rec_kandooreport.bottom_margin = 2
			LET p_rec_kandooreport.left_margin = 0
			LET p_rec_kandooreport.top_margin = 2
			--LET p_rec_kandooreport.page_length = 66
			LET p_rec_kandooreport.right_margin	= 132


		WHEN "M35"
			LET p_rec_kandooreport.header_text = "MN Shop Order Report" 
			LET p_rec_kandooreport.menupath_text = "M35" 
			LET p_rec_kandooreport.width_num = 132  
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "N" #Supports background (none-ui) process Y/N

			LET p_rec_kandooreport.bottom_margin = 2
			LET p_rec_kandooreport.left_margin = 0
			LET p_rec_kandooreport.top_margin = 2
			--LET p_rec_kandooreport.page_length = 66
			LET p_rec_kandooreport.right_margin	= 132

		WHEN "M41-PICKING"
			LET p_rec_kandooreport.header_text = "MN Picking List Report" 
			LET p_rec_kandooreport.menupath_text = "M41" 
			LET p_rec_kandooreport.width_num = 132  
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "N" #Supports background (none-ui) process Y/N

			LET p_rec_kandooreport.bottom_margin = 2
			LET p_rec_kandooreport.left_margin = 0
			LET p_rec_kandooreport.top_margin = 0
			--LET p_rec_kandooreport.page_length = 66
			LET p_rec_kandooreport.right_margin	= 132

		WHEN "M41-PACKET" #was M41B
			LET p_rec_kandooreport.header_text = "MN Packet Order List Report" 
			LET p_rec_kandooreport.menupath_text = "M41" 
			LET p_rec_kandooreport.width_num = 132  
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "N" #Supports background (none-ui) process Y/N

			LET p_rec_kandooreport.bottom_margin = 2
			LET p_rec_kandooreport.left_margin = 0
			LET p_rec_kandooreport.top_margin = 0
			--LET p_rec_kandooreport.page_length = 66
			LET p_rec_kandooreport.right_margin	= 132

		WHEN "M45" 
			LET p_rec_kandooreport.header_text = "MN Shop Order Shortage Listing " 
			LET p_rec_kandooreport.menupath_text = "M45" 
			LET p_rec_kandooreport.width_num = 132  
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "N" #Supports background (none-ui) process Y/N

			LET p_rec_kandooreport.bottom_margin = 2
			LET p_rec_kandooreport.left_margin = 2
			LET p_rec_kandooreport.top_margin = 2
			--LET p_rec_kandooreport.page_length = 66
			LET p_rec_kandooreport.right_margin	= 132

		WHEN "M47" 
			LET p_rec_kandooreport.header_text = "MN Shop Order Work In Progress Report" 
			LET p_rec_kandooreport.menupath_text = "M47" 
			LET p_rec_kandooreport.width_num = 80  
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "N" #Supports background (none-ui) process Y/N

			LET p_rec_kandooreport.bottom_margin = 2
			LET p_rec_kandooreport.left_margin = 2
			LET p_rec_kandooreport.top_margin = 2
			--LET p_rec_kandooreport.page_length = 66
			LET p_rec_kandooreport.right_margin	= 80							


		WHEN "M51" 
			LET p_rec_kandooreport.header_text = "MN Order Forecast Report" 
			LET p_rec_kandooreport.menupath_text = "M51" 
			LET p_rec_kandooreport.width_num = 80  
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "N" #Supports background (none-ui) process Y/N

			LET p_rec_kandooreport.bottom_margin = 4
			LET p_rec_kandooreport.left_margin = 0
			LET p_rec_kandooreport.top_margin = 2
			--LET p_rec_kandooreport.page_length = 66
			LET p_rec_kandooreport.right_margin	= 80	


		WHEN "M51-MPS" 
			LET p_rec_kandooreport.header_text = "MPS Pegging Report" 
			LET p_rec_kandooreport.menupath_text = "M51" 
			LET p_rec_kandooreport.width_num = 132  
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N

			LET p_rec_kandooreport.bottom_margin = 0
			LET p_rec_kandooreport.left_margin = 1
			LET p_rec_kandooreport.top_margin = 0
			--LET p_rec_kandooreport.page_length = 66
			LET p_rec_kandooreport.right_margin	= 80	

		WHEN "M51-BGR" 
			LET p_rec_kandooreport.header_text = "MPS Background Report" 
			LET p_rec_kandooreport.menupath_text = "M51" 
			LET p_rec_kandooreport.width_num = 132  
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N

			LET p_rec_kandooreport.bottom_margin = 0
			LET p_rec_kandooreport.left_margin = 1
			LET p_rec_kandooreport.top_margin = 0
			--LET p_rec_kandooreport.page_length = 66
			LET p_rec_kandooreport.right_margin	= 80	

				
		WHEN "M51-ERROR" 
			LET p_rec_kandooreport.header_text = "MN Order Forecast Report Exceptions" 
			LET p_rec_kandooreport.menupath_text = "M51" 
			LET p_rec_kandooreport.width_num = 80  
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "N" #Supports background (none-ui) process Y/N

			LET p_rec_kandooreport.bottom_margin = 4
			LET p_rec_kandooreport.left_margin = 0
			LET p_rec_kandooreport.top_margin = 2
			--LET p_rec_kandooreport.page_length = 66
			LET p_rec_kandooreport.right_margin	= 80	


		WHEN "M53-PEGGING" 
			LET p_rec_kandooreport.header_text = "MRP Pegging Report" 
			LET p_rec_kandooreport.menupath_text = "M53" 
			LET p_rec_kandooreport.width_num = 132  
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "N" #Supports background (none-ui) process Y/N

			LET p_rec_kandooreport.bottom_margin = 6
			LET p_rec_kandooreport.left_margin = 0
			LET p_rec_kandooreport.top_margin = 0
			--LET p_rec_kandooreport.page_length = 66
			LET p_rec_kandooreport.right_margin	= 132	


		WHEN "M53-ERROR" #was M53B
			LET p_rec_kandooreport.header_text = "MRP Exception Report" 
			LET p_rec_kandooreport.menupath_text = "M53" 
			LET p_rec_kandooreport.width_num = 132  
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "N" #Supports background (none-ui) process Y/N

			LET p_rec_kandooreport.bottom_margin = 6
			LET p_rec_kandooreport.left_margin = 0
			LET p_rec_kandooreport.top_margin = 0
			--LET p_rec_kandooreport.page_length = 66
			LET p_rec_kandooreport.right_margin	= 132	

		WHEN "M53-MRP-BG" 
			LET p_rec_kandooreport.header_text = "MRP Report" 
			LET p_rec_kandooreport.menupath_text = "M53" 
			LET p_rec_kandooreport.width_num = 80  
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "N" #Supports background (none-ui) process Y/N

			LET p_rec_kandooreport.bottom_margin = 4
			LET p_rec_kandooreport.left_margin = 0
			LET p_rec_kandooreport.top_margin = 2
			--LET p_rec_kandooreport.page_length = 66
			LET p_rec_kandooreport.right_margin	= 80	
										
		WHEN "M55" 
			LET p_rec_kandooreport.header_text = "MRP Exception Report" 
			LET p_rec_kandooreport.menupath_text = "M55" 
			LET p_rec_kandooreport.width_num = 80  
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "N" #Supports background (none-ui) process Y/N

			LET p_rec_kandooreport.bottom_margin = 4
			LET p_rec_kandooreport.left_margin = 0
			LET p_rec_kandooreport.top_margin = 0
			--LET p_rec_kandooreport.page_length = 66
			LET p_rec_kandooreport.right_margin	= 80	


		WHEN "M56" 
			LET p_rec_kandooreport.header_text = "MN Material Requirements Planning" 
			LET p_rec_kandooreport.menupath_text = "M56" 
			LET p_rec_kandooreport.width_num = 80  
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "N" #Supports background (none-ui) process Y/N
			LET p_rec_kandooreport.line1_text = "MN MRP Report"
			LET p_rec_kandooreport.bottom_margin = 4
			LET p_rec_kandooreport.left_margin = 0
			LET p_rec_kandooreport.top_margin = 0
			--LET p_rec_kandooreport.page_length = 66
			LET p_rec_kandooreport.right_margin	= 80	
													
										
		WHEN "M57" 
			LET p_rec_kandooreport.header_text = "Material Requirements Planning Listing" 
			LET p_rec_kandooreport.menupath_text = "M57" 
			LET p_rec_kandooreport.width_num = 132  
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "N" #Supports background (none-ui) process Y/N
			LET p_rec_kandooreport.line1_text = "MN MRP Report By Due Date"
			LET p_rec_kandooreport.bottom_margin = 6
			LET p_rec_kandooreport.left_margin = 0
			LET p_rec_kandooreport.top_margin = 0
			--LET p_rec_kandooreport.page_length = 66
			LET p_rec_kandooreport.right_margin	= 132	

		WHEN "M63" 
			LET p_rec_kandooreport.header_text = "MN Forecast Listing " 
			LET p_rec_kandooreport.menupath_text = "M63" 
			LET p_rec_kandooreport.width_num = 132  
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "N" #Supports background (none-ui) process Y/N
			LET p_rec_kandooreport.line1_text = "MN Forecast Listing"
			LET p_rec_kandooreport.bottom_margin = 6
			LET p_rec_kandooreport.left_margin = 0
			LET p_rec_kandooreport.top_margin = 0
			--LET p_rec_kandooreport.page_length = 66
			LET p_rec_kandooreport.right_margin	= 132	 										
		OTHERWISE
			LET p_rec_kandooreport.header_text = "MISSING IN DEFAULT TEMPLATES"

	END CASE

	RETURN p_rec_kandooreport.* 		 
END FUNCTION 