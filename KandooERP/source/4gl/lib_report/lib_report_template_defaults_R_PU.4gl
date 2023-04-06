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
FUNCTION rpt_set_kandooreport_defaults_R_PU(p_rec_kandooreport)
	DEFINE p_rec_kandooreport RECORD LIKE kandooreport.*
	

	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	
	CASE upshift(p_rec_kandooreport.report_code)

		######################################################################
		# PU - Purchasing System
		#
		######################################################################
		WHEN "RA1"
			LET p_rec_kandooreport.header_text = "PU Purchase Order Listing (by Vendor)" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "RA1" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
			LET p_rec_kandooreport.line1_text = "Vendor   Order No.      Order Date     Due Date          Status    Warehouse   Authorised  Goods Amt       Tax Amt     Total Amt" 

		WHEN "RA2"
			LET p_rec_kandooreport.header_text = "PU Purchase Order Listing (by Number)" 		
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "RA2" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
			LET p_rec_kandooreport.line1_text = "Vendor   Order No.      Order Date     Due Date          Status    Warehouse   Authorised  Goods Amt       Tax Amt     Total Amt" 

		WHEN "RA3"
			LET p_rec_kandooreport.header_text = "PU Purchase Order Listing (by Due Date)" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "RA3" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
			LET p_rec_kandooreport.line1_text = "Vendor   Order No.      Order Date     Due Date          Status    Warehouse   Authorised  Goods Amt       Tax Amt     Total Amt" 

		WHEN "RA4"
			LET p_rec_kandooreport.header_text = "PU Purchase Order Listing (by Due Date)" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "RA4" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 


		WHEN "RA5"
			LET p_rec_kandooreport.header_text = "PU Purchase Order Listing (by Due Date)" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "RA5" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 


		WHEN "RA6"
			LET p_rec_kandooreport.header_text = "Purchase Orders Detail by Product" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "RA6" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
{
			PRINT COLUMN 1, "Ref ", 
			COLUMN 27, "Vendor", 
			COLUMN 37, "Order", 
			COLUMN 45, "Curr", 
			COLUMN 52, "Quantity", 
			COLUMN 63, "UOM", 
			COLUMN 76, "Cost", 
			COLUMN 94, "Tax", 
			COLUMN 100 , "Acct", 
			COLUMN 121, "Total" 

			PRINT COLUMN 1, "Code", 
			COLUMN 37, "Number", 
			COLUMN 45, "Code", 
			COLUMN 100, "Code" 
}


		WHEN "RA7"
			LET p_rec_kandooreport.header_text = "Purchase Orders Detail by Product" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "RA7" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 

		WHEN "RA8"
			LET p_rec_kandooreport.header_text = "Purchase Orders Detail by Currency Code" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "RA8" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 

{
			PRINT 
			#COLUMN  1, "Vendor ",
			COLUMN 1, "Order", 
			COLUMN 10, "Ref", 
			COLUMN 26 , "Acct", 
			COLUMN 47, "Quantity", 
			COLUMN 58, "UOM", 
			COLUMN 71, "Cost", 
			COLUMN 85, "Tax", 
			COLUMN 98, "Total", 
			COLUMN 118, "Base " 


			PRINT 
			COLUMN 1, "Number", 
			COLUMN 26, "Code", 
			COLUMN 97, "Amount", 
			COLUMN 117, "Value" 
}

		WHEN "RA9"
			LET p_rec_kandooreport.header_text = "Purchase Orders Detail by Currency Code" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "RA9" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
{
			PRINT COLUMN 1, "Order", 
			COLUMN 11, "Vendor", 
			COLUMN 25, "Ref", 
			COLUMN 48, "Qty", 
			COLUMN 58, "Qty", 
			COLUMN 68, "Qty", 
			COLUMN 75, "UOM", 
			COLUMN 80, "Curr", 
			COLUMN 96, "Cost", 
			COLUMN 110, "Tax", 
			COLUMN 121, " Value" 


			PRINT COLUMN 1, "Number", 
			COLUMN 25, "Code", 
			COLUMN 48, "Ordered", 
			COLUMN 58, "Received", 
			COLUMN 68, "Outstd", 
			COLUMN 80, "Code ", 
			COLUMN 119, "Outstanding" 
}
		WHEN "RAA"
			LET p_rec_kandooreport.header_text = "PU Goods Receipt Listing (by Order)" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "RAA" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
			LET p_rec_kandooreport.line1_text = "   Order   Date  Ware  Vendor Line  Product        Description                       Ordered    Received   Outstanding   Line Amount" 



		WHEN "RAB"
			LET p_rec_kandooreport.header_text = "PU Goods Receipts by Product" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "RAB" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 

{
			PRINT COLUMN 1, "Product", 
			COLUMN 11, "Vendor", 
			COLUMN 20, "Ware", 
			COLUMN 26, "Order", 
			COLUMN 49, "Date", 
			COLUMN 61, "Order", 
			COLUMN 76, "Received", 
			COLUMN 92, "Outstanding" 

			PRINT COLUMN 1, "Code", 
			COLUMN 20, "Code", 
			COLUMN 61, "Quantity", 
			COLUMN 76, "Quantity", 
			COLUMN 92, "Quantity" 
}

		WHEN "RAC"
			LET p_rec_kandooreport.header_text = "Goods Receipt by GL" 
			LET p_rec_kandooreport.menupath_text = "RAC" 
			LET p_rec_kandooreport.width_num = 80 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
{
			PRINT COLUMN 1, "Order", 
			COLUMN 9, "Batch", 
			COLUMN 17, "Vendor ID", 
			COLUMN 29, "Reference", 
			COLUMN 45, "Description", 
			COLUMN 76, "Received", 
			COLUMN 95, "Line Total", 
			COLUMN 106, "Curr", 
			COLUMN 114, "Base Value" 

			PRINT COLUMN 1, "Number", 
			COLUMN 9, "Number", 
			COLUMN 76, "Quantity", 
			COLUMN 106, "Code", 
			COLUMN 123, "Posted" 
}						
		WHEN "RAD"
			LET p_rec_kandooreport.header_text = "Goods Receipt by Date " 
			LET p_rec_kandooreport.menupath_text = "RAD" 
			LET p_rec_kandooreport.width_num = 80 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
{
			PRINT COLUMN 1, "Date", 
			COLUMN 10, "Reference", 
			COLUMN 27, "Description", 
			COLUMN 60, "Received", 
			COLUMN 105, "Curr" 
			PRINT COLUMN 27, "Vendor ID", 
			COLUMN 37, "Order", 
			COLUMN 47, "GR Num.", 
			COLUMN 60, "Quantity", 
			COLUMN 78, "Unit Cost", 
			COLUMN 93, "Line Total", 
			COLUMN 105, "Code", 
			COLUMN 115, "Base Value" 
}
		WHEN "RAE"
			LET p_rec_kandooreport.header_text = "PU Purchase Order Expedite Report" 
			LET p_rec_kandooreport.menupath_text = "RAE" 
			LET p_rec_kandooreport.width_num = 80 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
			LET p_rec_kandooreport.line1_text = "ITEM PART/ACTIVITY NO             QUANTITY  QUANTITY   QUANTITY        UNIT LEAD" 
			LET p_rec_kandooreport.line2_text = "                                  ORDERED   RECEIVED   OUTSTANDING    PRICE TIME"

		WHEN "RAF"
			LET p_rec_kandooreport.header_text = "PU Purchase Order Detail 2 Report" 
			LET p_rec_kandooreport.menupath_text = "RAF" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 

		WHEN "RB1"
			LET p_rec_kandooreport.header_text = "Purchase Orders Detail by Number" 
			LET p_rec_kandooreport.menupath_text = "RB1" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 

		WHEN "RB2"
			LET p_rec_kandooreport.header_text = "Purchase Orders Detail by GL Account" 
			LET p_rec_kandooreport.menupath_text = "RB2" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 

		WHEN "RB3"
			LET p_rec_kandooreport.header_text = "Purchase Orders Detail by Job ID" 
			LET p_rec_kandooreport.menupath_text = "RB3" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
{
			PRINT COLUMN 1, TRAN_TYPE_JOB_JOB, 
			COLUMN 11, " Order", 
			COLUMN 20, " Order", 
			COLUMN 34, " Received", 
			COLUMN 48, " Vouchered", 
			COLUMN 62, " TO be ", 
			COLUMN 76, " TO be " 
			PRINT COLUMN 1, " Code", 
			COLUMN 11, "Number", 
			COLUMN 20, " Amount ", 
			COLUMN 34, " Amount ", 
			COLUMN 48, " Amount ", 
			COLUMN 62, " Received ", 
			COLUMN 76, "Vouchered " 
}
		WHEN "RB4"
			LET p_rec_kandooreport.header_text = "Purchase Orders Detail by Product" 
			LET p_rec_kandooreport.menupath_text = "RB4" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
{

			PRINT COLUMN 1, " Product", 
			COLUMN 22, " Order", 
			COLUMN 31, " Order", 
			COLUMN 55, " Received", 
			COLUMN 79, " Vouchered", 
			COLUMN 103, " TO be", 
			COLUMN 117 ," TO be" 

			PRINT COLUMN 1, " ID", 
			COLUMN 22, "Number", 
			COLUMN 31, " Qty", 
			COLUMN 41, " Amount ", 
			COLUMN 55, " Qty", 
			COLUMN 65, " Amount ", 
			COLUMN 79, " Qty", 
			COLUMN 89, " Amount ", 
			COLUMN 103, " Received ", 
			COLUMN 117, "Vouchered " 
}
		WHEN "RB5"
			LET p_rec_kandooreport.header_text = "Purchase Orders Commitments by Number" 
			LET p_rec_kandooreport.menupath_text = "RB5" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
			{
			PRINT COLUMN 1, " Order", 
			COLUMN 9, " Order", 
			COLUMN 18, " Order", 
			COLUMN 45, " Received", 
			COLUMN 72, " Vouchered", 
			COLUMN 99, "To be Received", 
			COLUMN 115 , "To be Vouchered" 

			PRINT COLUMN 1, "Number", 
			COLUMN 9, " Date", 
			COLUMN 18, " Qty", 
			COLUMN 29, " Amount ", 
			COLUMN 45, " Qty", 
			COLUMN 56, " Amount ", 
			COLUMN 72, " Qty", 
			COLUMN 83, " Amount ", 
			COLUMN 99, " Amount ", 
			COLUMN 115, " Amount " 
}
		WHEN "RB6"
			LET p_rec_kandooreport.header_text = "Purchase Orders Commitments by GL Account" 
			LET p_rec_kandooreport.menupath_text = "RB6" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
{
			PRINT COLUMN 1, " GL Account", 
			COLUMN 20, " Description", 
			COLUMN 52, " Order", 
			COLUMN 61, " Order", 
			COLUMN 75, " Received", 
			COLUMN 89, " Vouchered", 
			COLUMN 103, " TO be ", 
			COLUMN 117, " TO be " 

			PRINT COLUMN 1, " Code", 
			COLUMN 52, "Number", 
			COLUMN 61, " Amount ", 
			COLUMN 75, " Amount ", 
			COLUMN 89, " Amount ", 
			COLUMN 103, " Received ", 
			COLUMN 117, "Vouchered " 
}

		WHEN "RB6"
			LET p_rec_kandooreport.header_text = "Purchase Orders Commitments by GL Account" 
			LET p_rec_kandooreport.menupath_text = "RB6" 
			LET p_rec_kandooreport.width_num = 155 #WOW 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 

		WHEN "RB7"
			LET p_rec_kandooreport.header_text = "Outstanding POs" 
			LET p_rec_kandooreport.menupath_text = "RB7" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N
			LET p_rec_kandooreport.left_margin = 5
			
		WHEN "RB8"
			LET p_rec_kandooreport.header_text = "Purchase Orders Commitments by Product" 
			LET p_rec_kandooreport.menupath_text = "RB8" 
			LET p_rec_kandooreport.width_num = 132  
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N
	
{
			PRINT COLUMN 1, " Product", 
			COLUMN 22, " Order", 
			COLUMN 31, " Order", 
			COLUMN 55, " Received", 
			COLUMN 79, " Vouchered", 
			COLUMN 103, " TO be", 
			COLUMN 117 ," TO be" 

			PRINT COLUMN 1, "ID", 
			COLUMN 22, "Number", 
			COLUMN 31, " Qty", 
			COLUMN 41, " Amount ", 
			COLUMN 55, " Qty", 
			COLUMN 65, " Amount ", 
			COLUMN 79, " Qty", 
			COLUMN 89, " Amount ", 
			COLUMN 103, " Received ", 
			COLUMN 117, "Vouchered " 
}			


		WHEN "RB9"
			LET p_rec_kandooreport.header_text = "Purchase Orders Detail by GL Account" 
			LET p_rec_kandooreport.menupath_text = "RB9" 
			LET p_rec_kandooreport.width_num = 132  
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N	
			
		WHEN "RBA"
			LET p_rec_kandooreport.header_text = "Purchase Orders Detail by GL Account" 
			LET p_rec_kandooreport.menupath_text = "RBA" 
			LET p_rec_kandooreport.width_num = 132  
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N
{
			PRINT COLUMN 1, " GL Account", 
			COLUMN 22, " Order", 
			COLUMN 31, " Order", 
			COLUMN 45, " Received", 
			COLUMN 59, " Vouchered", 
			COLUMN 73, " TO be ", 
			COLUMN 87, " TO be ", 
			COLUMN 105, "Received Amt" 

			PRINT COLUMN 1, " Code", 
			COLUMN 22, "Number", 
			COLUMN 31, " Amount ", 
			COLUMN 45, " Amount ", 
			COLUMN 59, " Amount ", 
			COLUMN 73, " Received ", 
			COLUMN 87, "Vouchered ", 
			COLUMN 105, "NOT Vouchered"
}

		WHEN "RBB"
			LET p_rec_kandooreport.header_text = "Available Funds Report - Missing Program" 
			LET p_rec_kandooreport.menupath_text = "RBB" 
			LET p_rec_kandooreport.width_num = 132  
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N

		WHEN "RBC"
			LET p_rec_kandooreport.header_text = "Missing in docs" 
			LET p_rec_kandooreport.menupath_text = "RBC" 
			LET p_rec_kandooreport.width_num = 132  
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N

		WHEN "RS1-00"
			LET p_rec_kandooreport.header_text = "Purchase Orders" 
			LET p_rec_kandooreport.menupath_text = "RS1" 
			LET p_rec_kandooreport.width_num = 80  
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N

			LET p_rec_kandooreport.bottom_margin = 5
			LET p_rec_kandooreport.left_margin = 0
			LET p_rec_kandooreport.top_margin = 0
			--LET p_rec_kandooreport.page_length = 66
			LET p_rec_kandooreport.right_margin	= 85

		WHEN "RS1-01"
			LET p_rec_kandooreport.header_text = "Purchase Orders" 
			LET p_rec_kandooreport.menupath_text = "RS1" 
			LET p_rec_kandooreport.width_num = 80  
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N

			LET p_rec_kandooreport.bottom_margin = 13
			LET p_rec_kandooreport.left_margin = 0
			LET p_rec_kandooreport.top_margin = 0
			--LET p_rec_kandooreport.page_length = 66
			LET p_rec_kandooreport.right_margin	= 85

		WHEN "RS1-02"
			LET p_rec_kandooreport.header_text = "Purchase Orders" 
			LET p_rec_kandooreport.menupath_text = "RS1" 
			LET p_rec_kandooreport.width_num = 80  
			LET p_rec_kandooreport.length_num = 1 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N

			LET p_rec_kandooreport.bottom_margin = 0
			LET p_rec_kandooreport.left_margin = 0
			LET p_rec_kandooreport.top_margin = 0
			--LET p_rec_kandooreport.page_length = 1
			LET p_rec_kandooreport.right_margin	= 80

		WHEN "RS1-03"
			LET p_rec_kandooreport.header_text = "Purchase Orders" 
			LET p_rec_kandooreport.menupath_text = "RS1" 
			LET p_rec_kandooreport.width_num = 75  
			LET p_rec_kandooreport.length_num = 1 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N

			LET p_rec_kandooreport.bottom_margin = 0
			LET p_rec_kandooreport.left_margin = 0
			LET p_rec_kandooreport.top_margin = 0
			--LET p_rec_kandooreport.page_length = 1
			LET p_rec_kandooreport.right_margin	= 75

		WHEN "RS1-04"
			LET p_rec_kandooreport.header_text = "Purchase Orders" 
			LET p_rec_kandooreport.menupath_text = "RS1" 
			LET p_rec_kandooreport.width_num = 80  
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N

			LET p_rec_kandooreport.bottom_margin = 0
			LET p_rec_kandooreport.left_margin = 0
			LET p_rec_kandooreport.top_margin = 0
			--LET p_rec_kandooreport.page_length = 66
			LET p_rec_kandooreport.right_margin	= 80
			
		WHEN "RS1-05"
			LET p_rec_kandooreport.header_text = "Purchase Orders" 
			LET p_rec_kandooreport.menupath_text = "RS1" 
			LET p_rec_kandooreport.width_num = 110  
			LET p_rec_kandooreport.length_num = 51
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N

			LET p_rec_kandooreport.bottom_margin = 0
			LET p_rec_kandooreport.left_margin = 0
			LET p_rec_kandooreport.top_margin = 0
			--LET p_rec_kandooreport.page_length = 51
			LET p_rec_kandooreport.right_margin	= 110
			

		WHEN "RS1-06"
			LET p_rec_kandooreport.header_text = "Purchase Orders" 
			LET p_rec_kandooreport.menupath_text = "RS1" 
			LET p_rec_kandooreport.width_num = 75  
			LET p_rec_kandooreport.length_num = 66
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N

			LET p_rec_kandooreport.bottom_margin = 0
			LET p_rec_kandooreport.left_margin = 0
			LET p_rec_kandooreport.top_margin = 0
			--LET p_rec_kandooreport.page_length = 66
			LET p_rec_kandooreport.right_margin	= 75

		WHEN "RS1-07"
			LET p_rec_kandooreport.header_text = "Purchase Orders" 
			LET p_rec_kandooreport.menupath_text = "RS1" 
			LET p_rec_kandooreport.width_num = 120  
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N

			LET p_rec_kandooreport.bottom_margin = 0
			LET p_rec_kandooreport.left_margin = 0
			LET p_rec_kandooreport.top_margin = 0
			--LET p_rec_kandooreport.page_length = 66
			LET p_rec_kandooreport.right_margin	= 120

		#--------------------------------------------------
		#Do not remove
		#WHEN "RS5" -> uses RS1 / RS1c.4gl RS1_rpt_list_07 
		#--------------------------------------------------


		OTHERWISE
			LET p_rec_kandooreport.header_text = "MISSING IN DEFAULT TEMPLATES"

	END CASE

	RETURN p_rec_kandooreport.* 		 
END FUNCTION 