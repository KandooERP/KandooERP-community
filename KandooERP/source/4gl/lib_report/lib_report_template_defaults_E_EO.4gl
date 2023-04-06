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
FUNCTION rpt_set_kandooreport_defaults_E_EO(p_rec_kandooreport)
	DEFINE p_rec_kandooreport RECORD LIKE kandooreport.*
	

	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	
	CASE upshift(p_rec_kandooreport.report_code)

	

		######################################################################
		# EO 
		#
		######################################################################
		WHEN "E32"
			LET p_rec_kandooreport.header_text = "Back Order Allocation report" 
			LET p_rec_kandooreport.width_num = 80 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "E32" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
			#1234567890123456789012345678901234567890
			LET p_rec_kandooreport.line1_text = " Bin Product Pick Qty description" 

		WHEN "E52" #Picking Slip Generation
			LET p_rec_kandooreport.header_text = "Picking Slip Generation" 
			LET p_rec_kandooreport.width_num = 80 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "E52" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
			#1234567890123456789012345678901234567890
			LET p_rec_kandooreport.line1_text = "" 

		WHEN "E52_M" #Picking Slip Generation
			LET p_rec_kandooreport.header_text = "Picking Slip Generation" 
			LET p_rec_kandooreport.width_num = 103
			LET p_rec_kandooreport.length_num = 47 
			LET p_rec_kandooreport.menupath_text = "E52_M" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
			#1234567890123456789012345678901234567890
			LET p_rec_kandooreport.line1_text = "" 

		WHEN "E52_S" #Picking Slip Generation
			LET p_rec_kandooreport.header_text = "Store Allocation report - Picking Slip Generation" 
			LET p_rec_kandooreport.width_num = 80 
			LET p_rec_kandooreport.length_num = 47 
			LET p_rec_kandooreport.menupath_text = "E52_S" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
			#1234567890123456789012345678901234567890
			LET p_rec_kandooreport.line1_text = "Store Allocation report" 
			LET p_rec_kandooreport.line1_text = "Picking Slip Generation" 

		WHEN "E53"
			LET p_rec_kandooreport.header_text    = "E54 - Consignment Note Generation"
			LET p_rec_kandooreport.width_num      = 132
			LET p_rec_kandooreport.length_num     = 66
			LET p_rec_kandooreport.menupath_text  = "E53"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.bottom_margin = 0
			LET p_rec_kandooreport.left_margin = 0
			LET p_rec_kandooreport.top_margin = 5
			--LET p_rec_kandooreport.page_length = 33
			--LET p_rec_kandooreport.right_margin	= 80

			LET p_rec_kandooreport.exec_flag = "N"
																		#1234567890123456789012345678901234567890
			LET p_rec_kandooreport.line1_text = ""

		WHEN "E54-f1"
			LET p_rec_kandooreport.header_text    = "E54 - Consignment Note Generation"
			LET p_rec_kandooreport.width_num      = 70 #96
			LET p_rec_kandooreport.length_num     = 33
			LET p_rec_kandooreport.menupath_text  = "E54"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.bottom_margin = 0
			LET p_rec_kandooreport.left_margin = 0
			LET p_rec_kandooreport.top_margin = 5
--			LET p_rec_kandooreport.page_length = 33
			#LET p_rec_kandooreport.right_margin	= 80

			LET p_rec_kandooreport.exec_flag = "N"
																		#1234567890123456789012345678901234567890
			LET p_rec_kandooreport.line1_text = ""
			
		WHEN "E54-f2"
			LET p_rec_kandooreport.header_text    = "E54 - Consignment Note Generation"
			LET p_rec_kandooreport.width_num      = 96
			LET p_rec_kandooreport.length_num     = 44 #33
			LET p_rec_kandooreport.menupath_text  = "E54"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.bottom_margin = 0
			LET p_rec_kandooreport.left_margin = 0
			LET p_rec_kandooreport.top_margin = 4
--			LET p_rec_kandooreport.page_length = 33
			#LET p_rec_kandooreport.right_margin	= 80

			LET p_rec_kandooreport.exec_flag = "N"
																		#1234567890123456789012345678901234567890
			LET p_rec_kandooreport.line1_text = ""

		WHEN "E55"
			LET p_rec_kandooreport.header_text    = "EO - Shipping labels - Warehouse: "
			LET p_rec_kandooreport.width_num      = 101
			LET p_rec_kandooreport.length_num     = 18
			LET p_rec_kandooreport.bottom_margin = 0
			LET p_rec_kandooreport.left_margin = 0
			LET p_rec_kandooreport.top_margin = 2
						
			LET p_rec_kandooreport.menupath_text  = "E55"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N
																		#1234567890123456789012345678901234567890
			LET p_rec_kandooreport.line1_text = ""
			
		WHEN "E5A"
			LET p_rec_kandooreport.header_text    = "EO - Delivery MESSAGE/error report"
			LET p_rec_kandooreport.width_num      = 96
			LET p_rec_kandooreport.length_num     = 66
			LET p_rec_kandooreport.menupath_text  = "E5A"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N
																		#1234567890123456789012345678901234567890
			LET p_rec_kandooreport.line1_text = ""

		
		WHEN "E5B"
			LET p_rec_kandooreport.header_text    = "Bulk Pick List"
			LET p_rec_kandooreport.width_num      = 80
			LET p_rec_kandooreport.length_num     = 66
			LET p_rec_kandooreport.menupath_text  = "E5B"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N
																		#1234567890123456789012345678901234567890
			LET p_rec_kandooreport.line1_text = "  Bin              Product          Pick Qty     Description"

		WHEN "E5X"
			LET p_rec_kandooreport.header_text    = "Bulk Pick List"
			LET p_rec_kandooreport.width_num      = 101
			LET p_rec_kandooreport.length_num     = 18
			LET p_rec_kandooreport.menupath_text  = "E5X"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N
																		#1234567890123456789012345678901234567890
			LET p_rec_kandooreport.line1_text = ""

		WHEN "E84-DET"
			LET p_rec_kandooreport.header_text = "EO - Detailed Sales Commission report" 
			LET p_rec_kandooreport.width_num = 80 
			LET p_rec_kandooreport.length_num = 72 
			LET p_rec_kandooreport.menupath_text = "E84" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N

		WHEN "E84-SUM"
			LET p_rec_kandooreport.header_text = "EO - Summary Sales Commission report" 
			LET p_rec_kandooreport.width_num = 80 
			LET p_rec_kandooreport.length_num = 72 
			LET p_rec_kandooreport.menupath_text = "E84" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N
			
		WHEN "E85"
			LET p_rec_kandooreport.header_text = "EO - Detailed Sales Commission report" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "E85" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N

		WHEN "E91"
			LET p_rec_kandooreport.header_text = "EO Customer Orders listing" 
			LET p_rec_kandooreport.width_num = 80 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "E91" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N

		WHEN "E92"
			LET p_rec_kandooreport.header_text = "EO Sales Orders (by number)" 
			LET p_rec_kandooreport.width_num = 80 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "E92" 
			LET p_rec_kandooreport.selection_flag = "Y" 
				
		WHEN "E93"
			LET p_rec_kandooreport.header_text = "Orders By Shipping Date" 
			LET p_rec_kandooreport.width_num = 80 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "E93" 
			LET p_rec_kandooreport.selection_flag = "Y" 
				
		WHEN "E94"
			LET p_rec_kandooreport.header_text = "Orders By Shipping Date" 
			LET p_rec_kandooreport.width_num = 80 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "E94" 
			LET p_rec_kandooreport.selection_flag = "Y" 
				
		WHEN "E95"
			LET p_rec_kandooreport.header_text = "Order detail" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "E95" 
			LET p_rec_kandooreport.selection_flag = "Y"
			 			
		WHEN "E96"
			LET p_rec_kandooreport.header_text = "Order Detail By product" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "E96" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
			LET p_rec_kandooreport.line1_text = "Date     Client      Order       Ordered     Shipped   Backorder Description                           Unit        Unit     Extended"
			LET p_rec_kandooreport.line2_text = "          ID        Number          Qty        Qty        Qty                                       Measure       Price       Price"

		WHEN "E97"
			LET p_rec_kandooreport.header_text = "Product BackOrder report" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "E97" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
			LET p_rec_kandooreport.line1_text = "Line   Item           Ordered   Shipped ",
			                              "  Backorder        Description          ",
			                              "              Unit   Unit Price         ",
			                              " Extended"
			LET p_rec_kandooreport.line2_text = " No.    ID              Qty       Qty   ",
			                              "    Qty                                 ",
			                              "                                        ",
			                              "    Price"

		WHEN "E98"
			LET p_rec_kandooreport.header_text = "Back Order Detail By Product" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "E98" 
			LET p_rec_kandooreport.selection_flag = "Y"

						
		WHEN "E99"
			LET p_rec_kandooreport.header_text = "Back Order Detail By Due date" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "E99" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
			LET p_rec_kandooreport.line1_text = "Date     Client    Order        Ordered   Shipped   Backorder Description                             Unit Unit Price       Extended"
			LET p_rec_kandooreport.line2_text = "          ID       Number         Qty       Qty       Qty                                                                    Price"

		WHEN "E9A"
			LET p_rec_kandooreport.header_text = "Current Order Detail List" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "E9A" 
			LET p_rec_kandooreport.selection_flag = "Y"

		WHEN "E9B"
			LET p_rec_kandooreport.header_text = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxx" 
			LET p_rec_kandooreport.width_num = 80 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "E9B" 
			LET p_rec_kandooreport.selection_flag = "Y"

		WHEN "E9C"
			LET p_rec_kandooreport.header_text = "Orders By GL/Sales" 
			LET p_rec_kandooreport.width_num = 80 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "E9C" 
			LET p_rec_kandooreport.selection_flag = "Y"
						
		WHEN "E9D-C"
			LET p_rec_kandooreport.header_text = "Completed Order Status Report (Menu-E9D) - VALUES exclude tax" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "E9D" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 

		WHEN "E9D-I"
			LET p_rec_kandooreport.header_text = "Incomplete Order Status Report (Menu-E9D) - VALUES exclude tax" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "E9D" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 

		WHEN "E9E"
			LET p_rec_kandooreport.header_text = "Picking Slip Summary " 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "E9E" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 


		WHEN "ER1"
			LET p_rec_kandooreport.header_text = "Summary Held Order report" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "ER1" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N
			CALL fgl_winmessage("kandooreport template","needs adjusting ER1","info")
			#LET p_rec_kandooreport.line1_text = "Customer  Ord.Date  Ord. No.  ",pr_arparms.inv_ref1_text,"     Condition  Warehouse   Order Amount     Held Reason"			
			LET p_rec_kandooreport.line7_text = "Customer  Ord.Date  Ord. No.  "
			LET p_rec_kandooreport.line8_text = "     Condition  Warehouse   Order Amount     Held Reason"			 
			#LET p_rec_kandooreport.line1_text = "Customer  Ord.Date  Ord. No.  ",pr_arparms.inv_ref1_text,"     Condition  Warehouse   Order Amount     Held Reason"

		
			#IMPORANT TO DO
			# @needs fixing and adding -> pr_arparms
			#LET p_rec_kandooreport.line1_text = "Customer Ord.Date Ord. No. ",pr_arparms.inv_ref1_text," condition warehouse ORDER amount held Reason" 	

		WHEN "ER2"	
			LET p_rec_kandooreport.header_text = "Detailed Held Order report" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "ER2" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
			LET p_rec_kandooreport.line1_text = "Customer Ord.Date ord.no"
		
			#IMPORANT TO DO
			# @needs fixing and adding -> pr_arparms	 
			#LET p_rec_kandooreport.line4_text = pr_arparms.inv_ref1_text
		 
				LET p_rec_kandooreport.line1_text = "Customer  Ord.Date    Ord.No"
				CALL fgl_winmessage("kandooreport template","needs adjusting ER2","info")				
				#LET p_rec_kandooreport.line4_text = pr_arparms.inv_ref1_text
				LET p_rec_kandooreport.line5_text = "Condition  Warehouse   Order ",
																			"Amount     Held Reason"
				LET p_rec_kandooreport.line2_text = "  Spec.Offer   Product                  ",
																			"                                   Sold ",
																			"   Bonus   Unit Price       Disc%  Tax  "
				LET p_rec_kandooreport.line3_text = "  ----------   -------                  ",
																			"                                   ---- ",
																			"   -----   ----------       -----  ---  "

		WHEN "ES1"	
			LET p_rec_kandooreport.header_text = "EO Sales statistics extraction report" 
			LET p_rec_kandooreport.width_num = 80 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "ES1" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
			LET p_rec_kandooreport.line1_text = 2 spaces,"Product",9 spaces,"Description",22 spaces,"Quantity" 


		WHEN "ES2"	
			LET p_rec_kandooreport.header_text = "EO Statistics - Purge of year" 
			LET p_rec_kandooreport.width_num = 60 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "ES2" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 

		WHEN "ES4"	
			LET p_rec_kandooreport.header_text = "Profit Order Amendments Unload summary" 
			LET p_rec_kandooreport.width_num = 60 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "ES4" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 


		WHEN "ES5"	
			LET p_rec_kandooreport.header_text = "EO Order Confirmation summary" 
			LET p_rec_kandooreport.width_num = 80 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "ES5" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
			LET p_rec_kandooreport.line1_text = 2 spaces,"Product",9 spaces,"Description",22 spaces,"Quantity" 

		WHEN "ES5_S"	
			LET p_rec_kandooreport.header_text    = "EO Order Confirmation Summary"
			LET p_rec_kandooreport.width_num      = 80
			LET p_rec_kandooreport.length_num     = 66
			LET p_rec_kandooreport.menupath_text  = "ES5"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N
			LET p_rec_kandooreport.line1_text =	2 spaces,"Product",9 spaces,"Description",22 spaces,"Quantity"

		WHEN "ESL_E"	
			LET p_rec_kandooreport.header_text = 	"External Order Load Exceptions" # - (Load no:" #,		pr_loadparms.seq_num USING "<<<<<",")" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "ESL" 
			LET p_rec_kandooreport.selection_flag = "N" 
			LET p_rec_kandooreport.line1_text = "Customer", 2 spaces, 
			"Product", 10 spaces, 
			"Ord.Ref", 5 spaces, 
			"Status" 
			LET p_rec_kandooreport.line3_text = "Profit Import Orders Details" #LET pr_report_header3 = "Profit Import Orders Details (Load No: ",	pr_loadparms.seq_num USING "<<<<<",")" 

		WHEN "ES5_I"	
			LET p_rec_kandooreport.header_text    = "Profit Order Import Summary"
			LET p_rec_kandooreport.width_num      = 80
			LET p_rec_kandooreport.length_num     = 66
			LET p_rec_kandooreport.menupath_text  = "ESL"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N
			LET p_rec_kandooreport.line1_text =	2 spaces,"Product",9 spaces,"Description",22 spaces,"Quantity"
			LET p_rec_kandooreport.line2_text =	"Store Allocation report"

		WHEN "ESL_D"	
			LET p_rec_kandooreport.header_text = 	"Profit Order Import List" # - (Load no:" #,		pr_loadparms.seq_num USING "<<<<<",")" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "ESL" 
			LET p_rec_kandooreport.selection_flag = "N" 
			LET p_rec_kandooreport.line1_text = "Customer", 2 spaces, 
			"Product", 10 spaces, 
			"Ord.Ref", 5 spaces, 
			"Status" 
			LET p_rec_kandooreport.line3_text = "Profit Import Orders Details" #LET pr_report_header3 = "Profit Import Orders Details (Load No: ",	pr_loadparms.seq_num USING "<<<<<",")" 


		WHEN "ESV"	
			LET p_rec_kandooreport.header_text    = "Verify"
			LET p_rec_kandooreport.width_num      = 132
			LET p_rec_kandooreport.length_num     = 66
			LET p_rec_kandooreport.menupath_text  = "ESV"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N
			LET p_rec_kandooreport.line1_text =	""
			LET p_rec_kandooreport.line2_text =	""

		WHEN "ET1"
			LET p_rec_kandooreport.header_text = "Salesperson Weekly activity" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "ET1" 
			LET p_rec_kandooreport.selection_flag = "Y" 
			LET p_rec_kandooreport.line1_text = " ------ Date ------ Gross Nett Disc Target Achiev Orders Credits Avg order" 
			LET p_rec_kandooreport.line2_text = " Interval Reference Start END Turnover Turnover % Turnover % Value " 


		WHEN "ET2"
			LET p_rec_kandooreport.header_text = "Sales Manager Weekly turnover" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "ET2" 
			LET p_rec_kandooreport.selection_flag = "Y" 
			LET p_rec_kandooreport.line1_text = " Gross Nett Disc Target Achiev Orders Credits Avg order" 
			LET p_rec_kandooreport.line2_text = " Turnover Turnover % Turnover % Value " 


		WHEN "ET3"
			LET p_rec_kandooreport.header_text = "Sales Manager Monthly turnover" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "ET3" 
			LET p_rec_kandooreport.selection_flag = "Y" 
			LET p_rec_kandooreport.line1_text = 57 spaces,"Gross Nett Disc Target Achiev Orders Credits Avg order" 
			LET p_rec_kandooreport.line2_text = 57 spaces,"Turnover Turnover % Turnover % Value " 

		WHEN "ET4"	
			LET p_rec_kandooreport.header_text = "Salesperson Inventory turnover" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "ET4" 
			LET p_rec_kandooreport.selection_flag = "Y" 
			LET p_rec_kandooreport.line1_text=55 spaces,"----------- Current Month ----------", 	3 spaces,"----------- Year TO Date -----------" 
			LET p_rec_kandooreport.line2_text=51 spaces, 	"Year Sales Gross Nett disc", 9 spaces,"Sales Gross Nett disc" 
			LET p_rec_kandooreport.line3_text= 59 spaces,"Qty Amount Amount percnt", 09 spaces,"Qty Amount Amount percnt" 

		WHEN "ET5"	
			LET p_rec_kandooreport.header_text = "Salesperson Turnover comparison" 
			LET p_rec_kandooreport.width_num = 80 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "ET5" 
			LET p_rec_kandooreport.selection_flag = "Y" 
			LET p_rec_kandooreport.line1_text = "Month Nett Disc Nett Disc Nett Disc increase" 
			LET p_rec_kandooreport.line2_text = " Turnover Percent Turnover Percent Turnover Percent turnover" 

		WHEN "ET6"
			LET p_rec_kandooreport.header_text = "Salesperson Customer ranking" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "ET6" 
			LET p_rec_kandooreport.selection_flag = "Y" 
			LET p_rec_kandooreport.line1_text = "Customer details",27 spaces, 
			"JAN FEB MAR APR MAY JUN ", 
			"JUL AUG SEP OCT NOV DEC ytd" 

		WHEN "ET7"
			LET p_rec_kandooreport.header_text = "Special Offer results" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "ET7" 
			LET p_rec_kandooreport.selection_flag = "Y" 
			LET p_rec_kandooreport.line1_text=40 spaces,"--------------------------------", 
			" Special Offer Sales Quantity --------------------------------" 

		WHEN "ET8"
			LET p_rec_kandooreport.header_text = "New Vs Repeat Sales report" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "ET8" 
			LET p_rec_kandooreport.selection_flag = "Y" 
			LET p_rec_kandooreport.line1_text = " " 
			LET p_rec_kandooreport.line2_text=" " 

		WHEN "ET9"
			LET p_rec_kandooreport.header_text = "Salesperson Performance report" 
			LET p_rec_kandooreport.width_num = 160 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "ET9" 
			LET p_rec_kandooreport.selection_flag = "Y" 
			LET p_rec_kandooreport.line1_text = "Salesperson Interval ----- Year TO Date ----- ---- Month TO Date --- ------- Pending Sales ------ Avg Ord Day Sales profit" 
			LET p_rec_kandooreport.line2_text= " Actual Budget Achv% Actual Budget Achv% B/O Held Other Total Orders Credits Value % " 

		WHEN "ETA"
			LET p_rec_kandooreport.header_text = "Salesperson Contribution report" 
			LET p_rec_kandooreport.width_num = 80 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "ETA" 
			LET p_rec_kandooreport.selection_flag = "Y" 
			LET p_rec_kandooreport.line1_text= 	" --- Current Month --- --- Year TO Date ---" 
			LET p_rec_kandooreport.line2_text= 	" Actual % Actual % " 

		WHEN "ETB"
			LET p_rec_kandooreport.header_text = "Salesperson Distribution report" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "ETB" 
			LET p_rec_kandooreport.selection_flag = "Y" 
			LET p_rec_kandooreport.line1_text=66 spaces," ----- Current Month ----- ----- Year TO Date ------" 
			LET p_rec_kandooreport.line2_text=" Inventory Item Description Year Customer Items Nett Buying Items Nett buying" 
			LET p_rec_kandooreport.line3_text=" % Sold Turnover Cust. Sold Turnover cust." 

		WHEN "EU1"	
			LET p_rec_kandooreport.header_text = "Yearly Inventory turnover" 
			LET p_rec_kandooreport.width_num = 85 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "EU1" 
			LET p_rec_kandooreport.selection_flag = "Y" 
			LET p_rec_kandooreport.line1_text = 	"Product details",47 spaces,"--- -- --- --" 

		WHEN "EU2"
			LET p_rec_kandooreport.header_text = "Inventory/Customer Monthly Turnover report" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "EU2" 
			LET p_rec_kandooreport.selection_flag = "Y" 
			LET p_rec_kandooreport.line1_text=" Customer name/suburb",33 spaces,"----------- Current Month ---------- ----------- Year TO Date -----------" 
			LET p_rec_kandooreport.line2_text=52 spaces,"Year Quantity Gross Nett Disc% Quantity Gross Nett disc%" 

		WHEN "EU4"
			LET p_rec_kandooreport.header_text = "Inventory Monthly Turnover (by volume)" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "EU4" 
			LET p_rec_kandooreport.selection_flag = "Y" 
			LET p_rec_kandooreport.line1_text=" ",28 spaces,"------------ Current Month ----------- ------------ Year TO Date -------------" 
			LET p_rec_kandooreport.line2_text=" Quantity Gross Nett Disc% Quantity Gross Nett disc%" 
			LET p_rec_kandooreport.line3_text=" ",28 spaces,"-------------------------------------------------------------------------------" 

									
		WHEN "EU5"	
			LET p_rec_kandooreport.header_text = "Product Monthly Turnover report" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "EU5" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
			LET p_rec_kandooreport.line1_text="                                                              Current    Previous       Period     Current    Previous        YTD"
			LET p_rec_kandooreport.line2_text="            PTD        PTD         Variance      YTD        YTD         Variance"
			LET p_rec_kandooreport.line3_text="                                                          --------------------------------------------------------------------------"


		WHEN "EU6"	
			LET p_rec_kandooreport.header_text = "Product Monthly Turnover by Net value" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "EU6" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
			LET p_rec_kandooreport.line1_text="                                                              Current    Previous       Period     Current    Previous        YTD"
			LET p_rec_kandooreport.line2_text="            PTD        PTD         Variance      YTD        YTD         Variance"
			LET p_rec_kandooreport.line3_text="                                                          --------------------------------------------------------------------------"

		WHEN "EV1"	
			LET p_rec_kandooreport.header_text = "Customer Yearly turnover" 
			LET p_rec_kandooreport.width_num = 80 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "EV1" 
			LET p_rec_kandooreport.selection_flag = "Y" 
			LET p_rec_kandooreport.line1_text = "Customer details",41 spaces,"--- -- --- --" 

		WHEN "EV2"
			LET p_rec_kandooreport.header_text = "Customer Yearly Turnover by Sales territory" 
			LET p_rec_kandooreport.width_num = 80 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "EV2" 
			LET p_rec_kandooreport.selection_flag = "Y" 
			LET p_rec_kandooreport.line1_text = "Customer details",41 spaces,"--- -- --- --" 

		WHEN "EV3"
			LET p_rec_kandooreport.header_text = "Customer Yearly Turnover by Sales area" 
			LET p_rec_kandooreport.width_num = 80 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "EV3" 
			LET p_rec_kandooreport.selection_flag = "Y" 
			LET p_rec_kandooreport.line1_text = "Customer details",41 spaces,"--- -- --- --" 			

		WHEN "EV4"
			LET p_rec_kandooreport.header_text = "Customer Yearly Turnover by salesperson" 
			LET p_rec_kandooreport.width_num = 80 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "EV4" 
			LET p_rec_kandooreport.selection_flag = "Y" 
			LET p_rec_kandooreport.line1_text = "Customer details",41 spaces,"--- -- --- --" 

		WHEN "EV5"
			LET p_rec_kandooreport.header_text = "Customer sales" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "EV5" 
			LET p_rec_kandooreport.selection_flag = "Y" 
			LET p_rec_kandooreport.line1_text="Inventory Item Description -------Gross Amt------ -------Net Amt------ -------Disc %------- -------profit-------" 
			LET p_rec_kandooreport.line2_text=" Curr Prev Diff% Curr Prev Diff% Curr Prev Diff% Curr Prev diff%" 					

		WHEN "EV6"
			LET p_rec_kandooreport.header_text = "Top Customers turnover" 
			LET p_rec_kandooreport.width_num = 100 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "EV6" 
			LET p_rec_kandooreport.selection_flag = "Y" 
			LET p_rec_kandooreport.line1_text = " No. Customer details",27 spaces,"Gross Amt Net Amt Total% Disc% accumulated" 

		WHEN "EW1"
			LET p_rec_kandooreport.header_text = "Sales Area distribution" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "EW1" 
			LET p_rec_kandooreport.selection_flag = "Y" 
			LET p_rec_kandooreport.line1_text=66 spaces," ----- Current Month ----- ----- Year TO Date ------" 
			LET p_rec_kandooreport.line2_text=" Inventory Item Description Year Customer Items Nett Buying Items Nett buying" 
			LET p_rec_kandooreport.line3_text=" % Sold Turnover Cust. Sold Turnover cust." 

		WHEN "EW2"
			LET p_rec_kandooreport.header_text = "Sales Area Distribution trends" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "EW2" 
			LET p_rec_kandooreport.selection_flag = "Y" 
			LET p_rec_kandooreport.line1_text=" Inventory Item description" 
			LET p_rec_kandooreport.line2_text=" " 

		WHEN "EY1"
			LET p_rec_kandooreport.header_text = "Company distribution" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "EY1" 
			LET p_rec_kandooreport.selection_flag = "Y" 
			LET p_rec_kandooreport.line1_text=66 spaces," ----- Current Month ----- ----- Year TO Date ------" 
			LET p_rec_kandooreport.line2_text=" Inventory Item Description Year Customer Items Nett Buying Items Nett buying" 
			LET p_rec_kandooreport.line3_text=" % Sold Turnover Cust. Sold Turnover cust." 

		WHEN "EY2"	
			LET p_rec_kandooreport.header_text = "Company Distribution trends" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "EY2" 
			LET p_rec_kandooreport.selection_flag = "Y" 
			LET p_rec_kandooreport.line1_text=" Inventory Item description" 
			LET p_rec_kandooreport.line2_text=" " 
							
		OTHERWISE
			LET p_rec_kandooreport.header_text = "MISSING IN DEFAULT TEMPLATES"

	END CASE

	RETURN p_rec_kandooreport.* 		 
END FUNCTION 