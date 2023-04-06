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
FUNCTION rpt_set_kandooreport_defaults_P_AP(p_rec_kandooreport)
	DEFINE p_rec_kandooreport RECORD LIKE kandooreport.*
	

	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	
	CASE upshift(p_rec_kandooreport.report_code)
#############################################################################
# P
#############################################################################	

		WHEN "P32"
			LET p_rec_kandooreport.header_text = "Payment Register " 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "P32" 
			LET p_rec_kandooreport.selection_flag = "Y" 
			LET p_rec_kandooreport.line1_text = " Voucher Voucher Due Voucher Payment Discount Discount Invoice Voucher" 
			LET p_rec_kandooreport.line2_text = " Number Date Date Amount Amount Date Amount Number Comments" 

		WHEN "P34"
			LET p_rec_kandooreport.header_text = "N/A" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "P34" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" 
			LET p_rec_kandooreport.line1_text = ""
			LET p_rec_kandooreport.line2_text = ""

		WHEN "P3A"
			LET p_rec_kandooreport.header_text = "Automatic Payments Exception Report" 
			LET p_rec_kandooreport.width_num = 80 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "P3A" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" 
			LET p_rec_kandooreport.line1_text = "Date Time            Comments"
			LET p_rec_kandooreport.line2_text = ""

		WHEN "P3A."
			LET p_rec_kandooreport.header_text = "N/A" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "P3A" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" 
			LET p_rec_kandooreport.line1_text = ""
			LET p_rec_kandooreport.line2_text = ""

		WHEN "P6A"
			LET p_rec_kandooreport.header_text = 'Automatic Debit Apply' 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "P6A" 
			LET p_rec_kandooreport.selection_flag = 'Y' 
			LET p_rec_kandooreport.line1_text = "Debit", 7 spaces, 
			"Debit", 2 spaces, 
			"Vendor", 3 spaces, 
			"Voucher", 2 spaces, 
			"Vendor", 10 spaces, 
			"---- Debit Applications -----", 2 spaces, 
			"Discount", 1 spaces, 
			"----- Voucher Payments ------", 3 spaces, 
			"Voucher" 
			LET p_rec_kandooreport.line2_text = "No.", 9 spaces, 
			"Amount", 1 spaces, 
			"Code", 5 spaces, 
			"Code", 5 spaces, 
			"Invoice", 10 spaces, 
			"Previous", 3 spaces, 
			"Current", 5 spaces, 
			"Total", 2 spaces, 
			"Taken", 5 spaces, 
			"Previous", 3 spaces, 
			"Current", 5 spaces, 
			"Total", 3 spaces, 
			"Amount" 

		WHEN "P72"
			LET p_rec_kandooreport.header_text = "Recurring Vouchers Processing Report" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "P72" 
			LET p_rec_kandooreport.selection_flag = "N"
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 			 
			LET p_rec_kandooreport.line1_text = "Vendor Voucher ", 
			"Line Account Description", 
			30 spaces, 
			"--Vendor Curr.--- --Base Curr.--- Rate" 

		WHEN "P73"
			LET p_rec_kandooreport.header_text = "Recurring Voucher Report" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "P73" 
			LET p_rec_kandooreport.selection_flag = "Y" 
			LET p_rec_kandooreport.line1_text = "Vendor Payment Description", 
			" Group ", 
			" Start Finish Invoice ", 
			" ----- Voucher Amount ---- Exch Rate" 

		WHEN "P93"		
			LET p_rec_kandooreport.header_text = "Contractor Details Report" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66

		WHEN "P94"		
			LET p_rec_kandooreport.header_text = "P94 ???" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66
			 			 
							
		WHEN "P96-PAYD"		
			LET p_rec_kandooreport.header_text = "AP Tax Summary Report" 
			LET p_rec_kandooreport.width_num = 80 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "P96" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
			LET p_rec_kandooreport.line1_text = "Prescribed Payments System (PPS)" 			
			LET p_rec_kandooreport.line2_text = "Payer's Reconciliation Report" 
			LET p_rec_kandooreport.line3_text = "FOR the year ending "

		WHEN "P96-REC" #IF all vendors selected, create a Payer Reconciliation REPORT		
			LET p_rec_kandooreport.header_text = "Tax Payer Reconciliation" 
			LET p_rec_kandooreport.width_num = 80 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "P96" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
			LET p_rec_kandooreport.line1_text = "Prescribed Payments System (PPS)" 			
			LET p_rec_kandooreport.line2_text = "Payer's Reconciliation Report" 
			LET p_rec_kandooreport.line3_text = "FOR the year ending "
			
		WHEN "PA1"
			LET p_rec_kandooreport.header_text = "AP Vendor Listing"
			LET p_rec_kandooreport.width_num = 132 		
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "PA1" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
			LET p_rec_kandooreport.line1_text = NULL 		
						
		WHEN "PA2"
			LET p_rec_kandooreport.header_text = "AP Vendor Phone Listing" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "PA2" 
			LET p_rec_kandooreport.selection_flag = "Y" 
			LET p_rec_kandooreport.line1_text[01,4] = "Code" 
			LET p_rec_kandooreport.line1_text[10,38] = "Name" 
			LET p_rec_kandooreport.line1_text[40,59] = "City" 
			LET p_rec_kandooreport.line1_text[61,63] = " " 
			LET p_rec_kandooreport.line1_text[65,82] = "Telephone" 
			LET p_rec_kandooreport.line1_text[84,101] = "Facsimilie" 
			LET p_rec_kandooreport.line1_text[103,120] ="Contact" 
			LET p_rec_kandooreport.line1_text[122,132] ="ABN" 

		WHEN "PA3"
			LET p_rec_kandooreport.header_text = "AP Vendor Notes"	
			LET p_rec_kandooreport.width_num = 80 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "PA3"
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
			LET p_rec_kandooreport.line1_text = NULL 		
						
						
		WHEN "PA5"
			LET p_rec_kandooreport.header_text = "AP Vendor Credit Status"	
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "PA5"
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
			LET p_rec_kandooreport.line1_text = NULL 					
			
		WHEN "PA6"
			LET p_rec_kandooreport.header_text = "AP Vendor Credit Aging"
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "PA6"
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
			LET p_rec_kandooreport.line1_text = NULL 	
			
		WHEN "PA7"
			LET p_rec_kandooreport.header_text = "Vendor History Ledger Listing" 
			LET p_rec_kandooreport.width_num = 80 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "PA7" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
			LET p_rec_kandooreport.line1_text = NULL 	
			
		WHEN "PA8"
			LET p_rec_kandooreport.header_text = "Vendor Ledger Listing"
			LET p_rec_kandooreport.width_num = 80
			LET p_rec_kandooreport.length_num = 66
			LET p_rec_kandooreport.menupath_text = "PA8"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N
#                                 123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012
			LET p_rec_kandooreport.line1_text = " Date         Trans  Reference    Description         Amount         Balance"

		WHEN "PA9"
			LET p_rec_kandooreport.header_text = "Vendor Listing" 
			LET p_rec_kandooreport.width_num = 80 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "PA9" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
			LET p_rec_kandooreport.line1_text = NULL 	
			

		WHEN "PAA-1-ADD"
			LET p_rec_kandooreport.header_text = "Vendor Audit Listing Report -Additions-"
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "PAA" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 		

		WHEN "PAA-2-ALT" #Alterations
			LET p_rec_kandooreport.header_text = "Vendor Audit Listing Report - Alterations-"
			LET p_rec_kandooreport.width_num = 132  
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "PAA" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 		

		WHEN "PAA-3-DEL"
			LET p_rec_kandooreport.header_text = "Vendor Audit Listing Report -Delitions-"
			LET p_rec_kandooreport.width_num = 90 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "PAA" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 

		WHEN "PAB"
			LET p_rec_kandooreport.header_text = "Vendor Open Item Report"
			LET p_rec_kandooreport.width_num = 132
			LET p_rec_kandooreport.length_num = 66
			LET p_rec_kandooreport.menupath_text = "PAB"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N
	#                                 123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012
			LET p_rec_kandooreport.line1_text = "Tran Date   Type  Number    Refernce Text          Open Amount   Hold  Comments"

		WHEN "PB1"
			LET p_rec_kandooreport.header_text = "Vouchers by Vendor" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "PB1" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
			LET p_rec_kandooreport.line1_text = "Voucher     Vendor              Date     Posting        Total        Possible          Paid   Posted  Hold" 
			LET p_rec_kandooreport.line2_text = "Number   Invoice Number                Year Period     Voucher       Discount         Amount   (GL)   Code"
			LET p_rec_kandooreport.line3_text = "----------------------------------------------------------------------------------------------------------" 			

		WHEN "PB2"
			LET p_rec_kandooreport.header_text = "Vouchers by Number" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "PB2" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
			LET p_rec_kandooreport.line1_text = "" 
			LET p_rec_kandooreport.line2_text = "" 
			LET p_rec_kandooreport.line3_text = "----------------------------------------------------------------------------------------------------------" 			
{
			PRINT COLUMN 1,"All totals in base currency" 
			PRINT COLUMN 1, rpt_get_char_line(NULL,"-")
			PRINT COLUMN 2, "Voucher", 
			COLUMN 10, "Vendor ", 
			COLUMN 22, "Vendor Name", 
			COLUMN 53, "Vendor", 
			COLUMN 69, "Curr", 
			COLUMN 75, "Date", 
			COLUMN 81, "Period", 
			COLUMN 92, "Total", 
			COLUMN 105,"Discount", 
			COLUMN 120,"Paid", 
			COLUMN 127,"Posted" 
			PRINT COLUMN 2, "Number", 
			COLUMN 11, "Code", 
			COLUMN 49, "Invoice Number", 
			COLUMN 69, "Code", 
			COLUMN 92, "Voucher", 
			COLUMN 105,"Possible", 
			COLUMN 120,"Amount" 
}
		WHEN "PB3"
			LET p_rec_kandooreport.header_text = "Voucher by Period Report" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "PB3" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
			LET p_rec_kandooreport.line1_text = "" 
			LET p_rec_kandooreport.line2_text = "" 
			LET p_rec_kandooreport.line3_text = "----------------------------------------------------------------------------------------------------------" 			
{
			PRINT COLUMN 2, "Voucher", 
			COLUMN 10, "Vendor", 
			COLUMN 20, "Vendor Name", 
			COLUMN 53, "Vendor", 
			COLUMN 73, "Date", 
			COLUMN 79, "Period", 
			COLUMN 89, "Total", 
			COLUMN 101,"Discount", 
			COLUMN 118,"Paid", 
			COLUMN 124,"Currency" 
			PRINT COLUMN 2, "Number", 
			COLUMN 11, "Code", 
			COLUMN 50, "Invoice Number", 
			COLUMN 88, "Voucher", 
			COLUMN 101,"Possible", 
			COLUMN 117,"Amount", 
			COLUMN 127,"Posted" 

}

		WHEN "PB4"
			LET p_rec_kandooreport.header_text = "Voucher by Vendor Invoice Report" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "PB4" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
			LET p_rec_kandooreport.line1_text = "" 
			LET p_rec_kandooreport.line2_text = "" 
			LET p_rec_kandooreport.line3_text = "----------------------------------------------------------------------------------------------------------" 			

		WHEN "PB5-1-PO"
			LET p_rec_kandooreport.header_text = "Voucher Distributions ny Purchase Order Report" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "PB5" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
			LET p_rec_kandooreport.line1_text = "" 
			LET p_rec_kandooreport.line2_text = "" 
			LET p_rec_kandooreport.line3_text = "----------------------------------------------------------------------------------------------------------" 			


		WHEN "PB5" #Report container for 3 reports (no output)
			LET p_rec_kandooreport.entry_type = 1 #Container
			LET p_rec_kandooreport.header_text = "Voucher Distributions (3 Reports) PO, Jobs & GL" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "PB5" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
			LET p_rec_kandooreport.rmsdialog_flag = "N"
			LET p_rec_kandooreport.printnow_flag = "N"
			LET p_rec_kandooreport.titleedit_flag = "N"
						
		WHEN "PB5-1-PO"
			LET p_rec_kandooreport.header_text = "Voucher Distribution - Purchase Order" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "PB5" 
			LET p_rec_kandooreport.exec_ind = "2" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
			LET p_rec_kandooreport.line1_text = "" 
			LET p_rec_kandooreport.line2_text = "" 
			LET p_rec_kandooreport.line3_text = "----------------------------------------------------------------------------------------------------------" 			


		WHEN "PB5-2-JOBS"
			LET p_rec_kandooreport.header_text = "Voucher Distribution  - Jobs" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "PB5" 
			LET p_rec_kandooreport.exec_ind = "2" 
			LET p_rec_kandooreport.exec_flag = "N" 
			LET p_rec_kandooreport.line1_text = "" 
			LET p_rec_kandooreport.line2_text = "" 
			LET p_rec_kandooreport.line3_text = "----------------------------------------------------------------------------------------------------------" 			

		WHEN "PB5-3-GL"
			LET p_rec_kandooreport.header_text = "Voucher Distribution - GL" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "PB5" 
			LET p_rec_kandooreport.exec_ind = "2" 
			LET p_rec_kandooreport.exec_flag = "N" 
			LET p_rec_kandooreport.line1_text = "" 
			LET p_rec_kandooreport.line2_text = "" 
			LET p_rec_kandooreport.line3_text = "----------------------------------------------------------------------------------------------------------" 			

		WHEN "PB6"
			LET p_rec_kandooreport.header_text = "Vouchers by Batch Number"
			LET p_rec_kandooreport.width_num = 132
			LET p_rec_kandooreport.length_num = 66
			LET p_rec_kandooreport.menupath_text = "PB6"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N
			LET p_rec_kandooreport.line1_text = " Voucher Vendor    Vendor Name                      Vendor              Date   Year Period   Total                    Paid  Currency"
			LET p_rec_kandooreport.line2_text = " Number   Code                                   Invoice Number                             Voucher                 Amount    Posted"
			                            #123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
			LET p_rec_kandooreport.line3_text = "----------------------------------------------------------------------------------------------------------"

		WHEN "PB7"
			LET p_rec_kandooreport.header_text = "Approved Vouchers by Number Report" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "PB7" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
			LET p_rec_kandooreport.line1_text = " Voucher Vendor Vendor Name Vendor Date Year Period Total Paid Currency" 
			LET p_rec_kandooreport.line2_text = " Number Code Invoice Number Voucher Amount Posted" 
			#123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
			LET p_rec_kandooreport.line3_text = "----------------------------------------------------------------------------------------------------------" 
{
			PRINT COLUMN 2, "Voucher", 
			COLUMN 10, "Vendor", 
			COLUMN 21, "Vendor", 
			COLUMN 39, "Due Date", 
			COLUMN 49, "------Approved------- ", 
			COLUMN 71, "FROM", 
			COLUMN 87, "Total", 
			COLUMN 100,"Discount", 
			COLUMN 117,"Paid", 
			COLUMN 124,"Currency" 
			PRINT COLUMN 2, "Number", 
			COLUMN 11, "Code", 
			COLUMN 18, "Invoice Number", 
			COLUMN 50, "By", 
			COLUMN 57, "Code", 
			COLUMN 63, "Date", 
			COLUMN 70, "Voucher", 
			COLUMN 78, "Period", 
			COLUMN 86, "Voucher", 
			COLUMN 100,"Possible", 
			COLUMN 116,"Amount", 
			COLUMN 127,"Posted" 

}
		WHEN "PB8"
			LET p_rec_kandooreport.header_text = "Unapproved Vouchers By Vendor" 
			LET p_rec_kandooreport.width_num = 90 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "PB8" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
			{
			PRINT COLUMN 2, "Voucher", 
			COLUMN 13,"Vendor", 
			COLUMN 33,"Date", 
			COLUMN 39,"Period", 
			COLUMN 50,"Total", 
			COLUMN 62,"Possible", 
			COLUMN 79,"Paid", 
			COLUMN 85,"Posted" 
			PRINT COLUMN 2, "Number", 
			COLUMN 10,"Invoice Number", 
			COLUMN 49,"Voucher", 
			COLUMN 62,"Discount", 
			COLUMN 78,"Amount", 
			COLUMN 86,"(GL)" 
}
		WHEN "PB9"
			LET p_rec_kandooreport.header_text = "Vouchers By Period" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "PB9" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
			
		WHEN "PBA"
			LET p_rec_kandooreport.header_text = "Voucher Detail Report" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "PBA" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
			LET p_rec_kandooreport.line1_text = " Voucher Vendor Vendor Name Vendor Date Year Period Total Paid Currency" 
			LET p_rec_kandooreport.line2_text = " Number Code Invoice Number Voucher Amount Posted" 
			#123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
			LET p_rec_kandooreport.line3_text = "----------------------------------------------------------------------------------------------------------" 

		WHEN "PBC"
			LET p_rec_kandooreport.header_text = "Voucher Audit Trail Report" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "PBC" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 

{

			PRINT COLUMN 1, " Vendor", 
			COLUMN 16,"Vendor", 
			COLUMN 40,"Curr.", 
			COLUMN 46,"Vouch", 
			COLUMN 53,"Invoice", 
			COLUMN 63,"Total", 
			COLUMN 80," GL", 
			COLUMN 119, "Distribution" 
			PRINT COLUMN 1, " ID ", 
			COLUMN 16, "Name", 
			COLUMN 46, "Number", 
			COLUMN 53, "Number", 
			COLUMN 63, "Voucher", 
			COLUMN 80, "Account", 
			COLUMN 96, "Description", 
			COLUMN 124,"Amount" 

}
		WHEN "PBD"
		  LET p_rec_kandooreport.header_text = "Duplicate Voucher Exception Report"
		  LET p_rec_kandooreport.width_num = 132
		  LET p_rec_kandooreport.length_num = 66
		  LET p_rec_kandooreport.menupath_text = "PBD"
		  LET p_rec_kandooreport.exec_ind = "1"
		  LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N
		  LET p_rec_kandooreport.line1_text = "Voucher     Vendor              Date     Posting        Total        Possible          Paid   Posted  Hold"
		  LET p_rec_kandooreport.line2_text = "Number   Invoice Number                Year Period     Voucher       Discount         Amount   (GL)   Code"
		  LET p_rec_kandooreport.line3_text = "----------------------------------------------------------------------------------------------------------"

		WHEN "PBE"
			LET p_rec_kandooreport.header_text = "Voucher Approval Report" 
			LET p_rec_kandooreport.width_num = 80 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "PBE" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
			LET p_rec_kandooreport.line1_text = "" 
			LET p_rec_kandooreport.line2_text = "" 
			LET p_rec_kandooreport.line3_text = "----------------------------------------------------------------------------------------------------------" 
			LET p_rec_kandooreport.top_margin = 5

		WHEN "PC1" 
			LET p_rec_kandooreport.header_text = "Cheque Detail Report"
			LET p_rec_kandooreport.width_num = 132
			LET p_rec_kandooreport.length_num = 66
			LET p_rec_kandooreport.menupath_text = "PC1"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N
			LET p_rec_kandooreport.line1_text = " "
			LET p_rec_kandooreport.line2_text = " "
			LET p_rec_kandooreport.line3_text = "----------------------------------------------------------------------------------------------------------"		 

		WHEN "PC2"
			LET p_rec_kandooreport.header_text = "Cheque by Number Report"
			LET p_rec_kandooreport.width_num = 132
			LET p_rec_kandooreport.length_num = 66
			LET p_rec_kandooreport.menupath_text = "PC2"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N

		WHEN "PC3"
			LET p_rec_kandooreport.header_text = "Cheque by Period Report"
			LET p_rec_kandooreport.width_num = 132
			LET p_rec_kandooreport.length_num = 66
			LET p_rec_kandooreport.menupath_text = "PC3"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N
			
		WHEN "PC4"
			LET p_rec_kandooreport.header_text = "Cancelled Cheques Report"
			LET p_rec_kandooreport.width_num = 132
			LET p_rec_kandooreport.length_num = 66
			LET p_rec_kandooreport.menupath_text = "PC4"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N
			                              #123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012
			LET p_rec_kandooreport.line1_text = "Cheque     Vendor   Posted  Original   Cheque  Currency        Gross            Net   Cancel    Batch Reason"
			LET p_rec_kandooreport.line2_text = "Number       ID     (Y/N)  Year Period Date      Code         Amount          Amount Year Period  Num"

		WHEN "PC5"
			LET p_rec_kandooreport.header_text = "Cheque Application Report"
			LET p_rec_kandooreport.width_num = 80
			LET p_rec_kandooreport.length_num = 66
			LET p_rec_kandooreport.menupath_text = "PC5"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N

		WHEN "PC7-TRSR"
			LET p_rec_kandooreport.header_text = "Treasury Report"
			LET p_rec_kandooreport.width_num = 132
			LET p_rec_kandooreport.length_num = 66
			LET p_rec_kandooreport.menupath_text = "PC7"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N

		WHEN "PC7-DISTR"
			LET p_rec_kandooreport.header_text = "Distribution by Account"
			LET p_rec_kandooreport.width_num = 80
			LET p_rec_kandooreport.length_num = 66
			LET p_rec_kandooreport.menupath_text = "PC7"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N

		WHEN "PC8"
			LET p_rec_kandooreport.header_text = "AP Treasury Report I - Cheque Allocation"
			LET p_rec_kandooreport.width_num = 132
			LET p_rec_kandooreport.length_num = 66
			LET p_rec_kandooreport.menupath_text = "PC8"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N

		WHEN "PC8-A"
			LET p_rec_kandooreport.header_text = "AP Treasury Report II - Distribution by Account"
			LET p_rec_kandooreport.width_num = 132
			LET p_rec_kandooreport.length_num = 66
			LET p_rec_kandooreport.menupath_text = "PC8"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N

		WHEN "PC8-B"
			LET p_rec_kandooreport.header_text = "AP Treasury Report III - Detail"
			LET p_rec_kandooreport.width_num = 132
			LET p_rec_kandooreport.length_num = 66
			LET p_rec_kandooreport.menupath_text = "PC8"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N

		WHEN "PC9"
			LET p_rec_kandooreport.header_text = "EFT Payments Report"
			LET p_rec_kandooreport.width_num = 132
			LET p_rec_kandooreport.length_num = 66
			LET p_rec_kandooreport.menupath_text = "PC9"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N

		WHEN "PCA"
			LET p_rec_kandooreport.header_text = "AP Debits by Vendor"
			LET p_rec_kandooreport.width_num = 132
			LET p_rec_kandooreport.length_num = 66
			LET p_rec_kandooreport.menupath_text = "PCA"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N
			                              #123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012
			LET p_rec_kandooreport.line1_text = "Debit      Vendor Reference       Date          Posting          Total          Applied           Base           Base"
			                              #123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012
			LET p_rec_kandooreport.line2_text = "Number                                        Year Period        Amount         Amount           Amount         Applied       Posted"

		WHEN "PCB"
			LET p_rec_kandooreport.header_text = "AP Debits by Number"
			LET p_rec_kandooreport.width_num = 132
			LET p_rec_kandooreport.length_num = 66
			LET p_rec_kandooreport.menupath_text = "PCB"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N

		WHEN "PCC"
			LET p_rec_kandooreport.header_text = "AP Debits by Period"
			LET p_rec_kandooreport.width_num = 132
			LET p_rec_kandooreport.length_num = 66
			LET p_rec_kandooreport.menupath_text = "PCC"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N

		WHEN "PCD"
			LET p_rec_kandooreport.header_text = "AP Debits by Batch Number"
			LET p_rec_kandooreport.width_num = 132
			LET p_rec_kandooreport.length_num = 66
			LET p_rec_kandooreport.menupath_text = "PCD"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N
			LET p_rec_kandooreport.line1_text = " Debit   Vendor      Vendor Name                 Vendor Reference       Date     Posting         Total          Applied  Currency"
			                              #123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012
			LET p_rec_kandooreport.line2_text = " Number   Code                                                                 Year Period       Debit          Amount        Posted"

		WHEN "PCE"
			LET p_rec_kandooreport.header_text = "AP Debit Detail List"
			LET p_rec_kandooreport.width_num = 132
			LET p_rec_kandooreport.length_num = 66
			LET p_rec_kandooreport.menupath_text = "PCE"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N

		WHEN "PCF"
			LET p_rec_kandooreport.header_text = "AP Remittance Advices (PCF)"
			LET p_rec_kandooreport.width_num = 80
			LET p_rec_kandooreport.length_num = 66
			LET p_rec_kandooreport.menupath_text = "PCF"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N

		WHEN "PCFB"
			LET p_rec_kandooreport.header_text = "AP Remittance Advices (PCFb)"
			LET p_rec_kandooreport.width_num = 80
			LET p_rec_kandooreport.length_num = 66
			LET p_rec_kandooreport.menupath_text = "PCFb"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N

		WHEN "PCFK"
			LET p_rec_kandooreport.header_text = "AP Remittance Advices (PCFk)"
			LET p_rec_kandooreport.width_num = 80
			LET p_rec_kandooreport.length_num = 66
			LET p_rec_kandooreport.menupath_text = "PCFk"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N


		WHEN "PCG"
			LET p_rec_kandooreport.header_text = "AP Intersegment Payments"
			LET p_rec_kandooreport.width_num = 80
			LET p_rec_kandooreport.length_num = 66
			LET p_rec_kandooreport.menupath_text = "PCG"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N

		WHEN "PCH"
			LET p_rec_kandooreport.header_text = "AP Missing Cheque Numbers"
			LET p_rec_kandooreport.width_num = 80
			LET p_rec_kandooreport.length_num = 66
			LET p_rec_kandooreport.menupath_text = "PCH"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N

		WHEN "PCJ"
			LET p_rec_kandooreport.header_text = "AP Debit Applications"
			LET p_rec_kandooreport.width_num = 96
			LET p_rec_kandooreport.length_num = 66
			LET p_rec_kandooreport.menupath_text = "PCJ"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N

		WHEN "PCK"
			LET p_rec_kandooreport.header_text = "AP Prescribed Payments"
			LET p_rec_kandooreport.width_num = 132
			LET p_rec_kandooreport.length_num = 66
			LET p_rec_kandooreport.menupath_text = "PCK"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N

		WHEN "PCL"
			LET p_rec_kandooreport.header_text = "AP Cleansing Report"
			LET p_rec_kandooreport.width_num = 80
			LET p_rec_kandooreport.length_num = 66
			LET p_rec_kandooreport.menupath_text = "PCL"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N

		WHEN "PP1"
			LET p_rec_kandooreport.header_text = "AP Posting Report"
			LET p_rec_kandooreport.width_num = 132
			LET p_rec_kandooreport.length_num = 66
			LET p_rec_kandooreport.menupath_text = "PP1"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N


		WHEN "PR1"
			LET p_rec_kandooreport.header_text = "AP Detailed Aging " 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "PR1" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.selection_flag = "Y" 
			LET p_rec_kandooreport.line1_text = "Trn Doc Vendor Days Total Unpaid Current 1-30 31-60 61-90 90 Plus" 
			LET p_rec_kandooreport.line2_text = "Typ Num Reference Late /Base /Base Days Days Days Days"			 
	
		WHEN "PR2"			
			LET p_rec_kandooreport.header_text = "AP Activity Summary" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "PR2" 
			LET p_rec_kandooreport.selection_flag = "Y" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.line1_text = " Date Trans Document Vendor Total Discount Unpaid Posted " 
			LET p_rec_kandooreport.line2_text = " Type Number Reference Amount Amount Amount" 

		WHEN "PR3"			
			LET p_rec_kandooreport.header_text = "Creditors Audit Trail" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "PR3" 
			LET p_rec_kandooreport.selection_flag = "Y" 
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.bottom_margin = 0
			LET p_rec_kandooreport.left_margin = 0
			LET p_rec_kandooreport.top_margin = 4
			#LET p_rec_kandooreport.page_length = 66
			LET p_rec_kandooreport.right_margin	= 132
		 
			LET p_rec_kandooreport.line1_text = "Trans Trans Doc Invoice Transaction Payment Pay Payment Amount Account Transaction Description" 
			LET p_rec_kandooreport.line2_text = " Date Type Number Number Amount Amount Type Number Allocated Number " 
			LET p_rec_kandooreport.line3_text = ""

		WHEN "PR5"			
			LET p_rec_kandooreport.header_text = "Cash Requirements Forecast" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "PR5" 
			LET p_rec_kandooreport.selection_flag = "Y" 
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N			
			LET p_rec_kandooreport.bottom_margin = 0
			LET p_rec_kandooreport.left_margin = 0
			LET p_rec_kandooreport.top_margin = 4
			#LET p_rec_kandooreport.page_length = 66
			LET p_rec_kandooreport.right_margin	= 132
		 
			LET p_rec_kandooreport.line1_text = "Invoice Days Discount Unpaid Past 1 TO 7 8 TO 14 15 TO 21 22 TO 28 29 TO 60 61 TO 90 90 Plus" 
			LET p_rec_kandooreport.line2_text = " Date Due Amount Amount Due Days Days Days Days Days Days Days" 
			LET p_rec_kandooreport.line3_text = " Amounts in whole currency units - Forecast FROM: " 


		WHEN "PR7"			
			LET p_rec_kandooreport.header_text = "AP Payment Register" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "PR7" 
			LET p_rec_kandooreport.selection_flag = "Y" 
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N			
			LET p_rec_kandooreport.bottom_margin = 0
			LET p_rec_kandooreport.left_margin = 0
			LET p_rec_kandooreport.top_margin = 4
			#LET p_rec_kandooreport.page_length = 66
			LET p_rec_kandooreport.right_margin	= 132
			LET p_rec_kandooreport.line1_text = " Voucher Due Amount Discount Discount"
			LET p_rec_kandooreport.line2_text = " Numbers Date Date Date"  
			LET p_rec_kandooreport.line3_text = "" 

		WHEN "PR8"			
			LET p_rec_kandooreport.header_text = "AP Summary Aging" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "PR8" 
			LET p_rec_kandooreport.selection_flag = "Y" 
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N			
			LET p_rec_kandooreport.bottom_margin = 0
			LET p_rec_kandooreport.left_margin = 0
			LET p_rec_kandooreport.top_margin = 4
			#LET p_rec_kandooreport.page_length = 66
			LET p_rec_kandooreport.right_margin	= 132
			LET p_rec_kandooreport.line1_text = "Creditors Details Unpaid Current 1-30 31-60 61-90 90 Plus" 
			LET p_rec_kandooreport.line2_text = " Days Days Days Days"  
			LET p_rec_kandooreport.line3_text = "" 

		WHEN "PR9"			
			LET p_rec_kandooreport.header_text = "AP Snapshot - Year " 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "PR9" 
			LET p_rec_kandooreport.selection_flag = "Y" 
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N			
			LET p_rec_kandooreport.bottom_margin = 0
			LET p_rec_kandooreport.left_margin = 0
			LET p_rec_kandooreport.top_margin = 4
			#LET p_rec_kandooreport.page_length = 66
			LET p_rec_kandooreport.right_margin	= 132
			LET p_rec_kandooreport.line1_text = "Creditors Details Unpaid Current 1-30 31-60 61-90 90 Plus" 
			LET p_rec_kandooreport.line2_text = " Days Days Days Days"  
			LET p_rec_kandooreport.line3_text = "" 			


		WHEN "PRA"			
			LET p_rec_kandooreport.header_text = "AP Audit Trail" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "PRA" 
			LET p_rec_kandooreport.selection_flag = "Y" 
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N			
			LET p_rec_kandooreport.bottom_margin = 0
			LET p_rec_kandooreport.left_margin = 0
			LET p_rec_kandooreport.top_margin = 4
			#LET p_rec_kandooreport.page_length = 66
			LET p_rec_kandooreport.right_margin	= 132
			LET p_rec_kandooreport.line1_text = "Vendor Type Ref Trans Description Amount Vouchers Cheques Debits" 
			LET p_rec_kandooreport.line2_text = " Date"  
			LET p_rec_kandooreport.line3_text = " All VALUES in base currency"  			


		WHEN "PRB"			
			LET p_rec_kandooreport.header_text = "AP Batch Posting REPORT" 
			LET p_rec_kandooreport.width_num = 150 #WOW, never had 150 before...
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "PRB" 
			LET p_rec_kandooreport.selection_flag = "Y" 
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N			
			LET p_rec_kandooreport.bottom_margin = 0
			LET p_rec_kandooreport.left_margin = 0
			LET p_rec_kandooreport.top_margin = 4
			#LET p_rec_kandooreport.page_length = 66
			LET p_rec_kandooreport.right_margin	= 150 
			LET p_rec_kandooreport.line1_text = "" 
			LET p_rec_kandooreport.line2_text = ""  
			LET p_rec_kandooreport.line3_text = ""  			

		WHEN "PRC"			
			LET p_rec_kandooreport.header_text = "Period Activity Report" 
			LET p_rec_kandooreport.width_num = 132 #WOW, never had 150 before...
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "PRC" 
			LET p_rec_kandooreport.selection_flag = "Y" 
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N			
			LET p_rec_kandooreport.bottom_margin = 0
			LET p_rec_kandooreport.left_margin = 0
			LET p_rec_kandooreport.top_margin = 4
			#LET p_rec_kandooreport.page_length = 66
			LET p_rec_kandooreport.right_margin	= 150 
			LET p_rec_kandooreport.line1_text = " Date Trans Document Vendor Total Discount Unpaid Posted" 
			LET p_rec_kandooreport.line2_text = " Type Number Reference Amount Amount Amount"   
			LET p_rec_kandooreport.line3_text = " All VALUES in base currency"  	

		WHEN "PRD"			
			LET p_rec_kandooreport.header_text = "Period Aged Analysis by Type" 
			LET p_rec_kandooreport.width_num = 132
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "PRD" 
			LET p_rec_kandooreport.selection_flag = "Y" 
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N			
			LET p_rec_kandooreport.bottom_margin = 0
			LET p_rec_kandooreport.left_margin = 0
			LET p_rec_kandooreport.top_margin = 4
			#LET p_rec_kandooreport.page_length = 66
			LET p_rec_kandooreport.right_margin	= 150 
			LET p_rec_kandooreport.line1_text = "Vendor Type Unpaid Current 1-30 31-60 61-90 90 Plus" 
			LET p_rec_kandooreport.line2_text = " Days Days Days Days"  
			LET p_rec_kandooreport.line3_text = "" 

		WHEN "PRE"		
			LET p_rec_kandooreport.header_text = "Creditor Funds Employed Report"
			LET p_rec_kandooreport.width_num = 132
			LET p_rec_kandooreport.length_num = 66
			LET p_rec_kandooreport.menupath_text = "PRE"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N
			                            #123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012
			LET p_rec_kandooreport.line1_text = "Segment  (In Base Currency)  Balance         Current       1-30 Days      31-60 Days      61-90 Days        90+ Days        Received"
			                            #123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012
			LET p_rec_kandooreport.line2_text = "                                     Overdue         Overdue         Overdue          Overdue"


		WHEN "PRJ"			
			LET p_rec_kandooreport.header_text = "Purchase Journal Report" 
			LET p_rec_kandooreport.width_num = 132
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "PRJ" 
			LET p_rec_kandooreport.selection_flag = "Y" 
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N			
			LET p_rec_kandooreport.bottom_margin = 0
			LET p_rec_kandooreport.left_margin = 0
			LET p_rec_kandooreport.top_margin = 4
			#LET p_rec_kandooreport.page_length = 66
			LET p_rec_kandooreport.right_margin	= 150 
			LET p_rec_kandooreport.line1_text = "" 
			LET p_rec_kandooreport.line2_text = ""  
			LET p_rec_kandooreport.line3_text = "" 
			
		WHEN "PRK"			
			LET p_rec_kandooreport.header_text = "Purchase Order Voucher Report" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "PRK" 
			LET p_rec_kandooreport.selection_flag = "Y" 
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N			
			LET p_rec_kandooreport.bottom_margin = 0
			LET p_rec_kandooreport.left_margin = 0
			LET p_rec_kandooreport.top_margin = 1
			#LET p_rec_kandooreport.page_length = 66
			LET p_rec_kandooreport.right_margin	= 132
			LET p_rec_kandooreport.line1_text = "" 
			LET p_rec_kandooreport.line2_text = ""  
			LET p_rec_kandooreport.line3_text = ""  			

		WHEN "PRT"			
			LET p_rec_kandooreport.header_text = "Summary Aging By Vendor Type As AT :" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "PRT" 
			LET p_rec_kandooreport.selection_flag = "Y" 
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N			
			LET p_rec_kandooreport.bottom_margin = 0
			LET p_rec_kandooreport.left_margin = 0
			LET p_rec_kandooreport.top_margin = 1
			#LET p_rec_kandooreport.page_length = 66
			LET p_rec_kandooreport.right_margin	= 132
			LET p_rec_kandooreport.line1_text = "" 
			LET p_rec_kandooreport.line2_text = ""  
			LET p_rec_kandooreport.line3_text = ""  			

		WHEN "PS4"
			LET p_rec_kandooreport.header_text    = "AP Mail Labels"
			LET p_rec_kandooreport.width_num      = 80
			LET p_rec_kandooreport.length_num     = 6
			LET p_rec_kandooreport.menupath_text  = "PS4"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "N"
			LET p_rec_kandooreport.selection_flag = "N" 
			LET p_rec_kandooreport.top_margin = 0
			LET p_rec_kandooreport.bottom_margin = 0
			LET p_rec_kandooreport.left_margin = 0
			--LET p_rec_kandooreport.page_length = 6
			LET p_rec_kandooreport.right_margin	= 80
			LET p_rec_kandooreport.line1_text = ""  
			LET p_rec_kandooreport.line2_text = ""

		WHEN "PSA"
			LET p_rec_kandooreport.header_text    = "WHICS-OPEN AP Load Exception Report"
			LET p_rec_kandooreport.width_num      = 80
			LET p_rec_kandooreport.length_num     = 6
			LET p_rec_kandooreport.menupath_text  = "PSA"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "N"
			LET p_rec_kandooreport.selection_flag = "N" 
			LET p_rec_kandooreport.top_margin = 0
			LET p_rec_kandooreport.bottom_margin = 0
			LET p_rec_kandooreport.left_margin = 1
			--LET p_rec_kandooreport.page_length = 6
			LET p_rec_kandooreport.right_margin	= 80
			LET p_rec_kandooreport.line1_text = ""  
			LET p_rec_kandooreport.line2_text = ""


		WHEN "PSL_J_LOAD"
			LET p_rec_kandooreport.header_text    = "Vendor Load - "
			LET p_rec_kandooreport.width_num      = 132
			LET p_rec_kandooreport.length_num     = 66
			LET p_rec_kandooreport.menupath_text  = "PSL_J"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "N"
			LET p_rec_kandooreport.selection_flag = "N" 
			LET p_rec_kandooreport.bottom_margin = 0
			LET p_rec_kandooreport.left_margin = 0
			LET p_rec_kandooreport.top_margin = 5
			--LET p_rec_kandooreport.page_length = 132
			LET p_rec_kandooreport.right_margin	= 80
			LET p_rec_kandooreport.line1_text = 
				"Company", 4 spaces, 
				"Vendor", 4 spaces, 
				"Name", 29 spaces, 
				"Type", 3 spaces, 
				"Highest Balance", 7 spaces, 
				"YTD Amount", 3 spaces, 
				"Fax", 20 spaces, 
				"Insert/Update"  
			LET p_rec_kandooreport.line2_text = ""

		WHEN "PSL_J_ERROR"
			LET p_rec_kandooreport.header_text    = "Vendor Exception Report - "
			LET p_rec_kandooreport.width_num      = 132
			LET p_rec_kandooreport.length_num     = 66
			LET p_rec_kandooreport.menupath_text  = "PSL_J"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "N"
			LET p_rec_kandooreport.selection_flag = "N" 
			LET p_rec_kandooreport.bottom_margin = 0
			LET p_rec_kandooreport.left_margin = 0
			LET p_rec_kandooreport.top_margin = 5
			--LET p_rec_kandooreport.page_length = 132
			LET p_rec_kandooreport.right_margin	= 80
			LET p_rec_kandooreport.line1_text = 
				"Processing Group", 2 spaces, 
				"Vendor Code", 14 spaces, 
				"Status"  
			LET p_rec_kandooreport.line2_text = ""


		WHEN "PSU_J_LOAD"
			LET p_rec_kandooreport.header_text    = "Voucher / Debit Load - "
			LET p_rec_kandooreport.width_num      = 132
			LET p_rec_kandooreport.length_num     = 66
			LET p_rec_kandooreport.menupath_text  = "PSU_J"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "N"
			LET p_rec_kandooreport.selection_flag = "N" 
			LET p_rec_kandooreport.bottom_margin = 0
			LET p_rec_kandooreport.left_margin = 0
			LET p_rec_kandooreport.top_margin = 5
			--LET p_rec_kandooreport.page_length = 132
			LET p_rec_kandooreport.right_margin	= 80
			LET p_rec_kandooreport.line1_text = 
				"Company", 6 spaces, 
				"Vendor", 8 spaces, 
				"Voucher No.", 8 spaces, 
				"Debit No." , 15 spaces, 
				"Total Distributions", 26 spaces, 
				"Total Distributed"  
			LET p_rec_kandooreport.line2_text = ""

		WHEN "PSU_J_ERROR"
			LET p_rec_kandooreport.header_text    = "Voucher / Debit Load Exception Report - "
			LET p_rec_kandooreport.width_num      = 132
			LET p_rec_kandooreport.length_num     = 66
			LET p_rec_kandooreport.menupath_text  = "PSU_J"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "N"
			LET p_rec_kandooreport.selection_flag = "N" 
			LET p_rec_kandooreport.bottom_margin = 0
			LET p_rec_kandooreport.left_margin = 0
			LET p_rec_kandooreport.top_margin = 5
			--LET p_rec_kandooreport.page_length = 132
			LET p_rec_kandooreport.right_margin	= 80
			LET p_rec_kandooreport.line1_text = "Cmpy", 4 spaces,	"Vendor", 2 spaces,	"Reference", 7 spaces,	"Status" 
			LET p_rec_kandooreport.line2_text = ""

		WHEN "PSV"	
			LET p_rec_kandooreport.header_text = "ACCOUNTS PAYABLE VERIFY"
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "PSV" 
			LET p_rec_kandooreport.selection_flag= "N" 

		WHEN "PSW-1"	
			LET p_rec_kandooreport.header_text = "AP Voucher/Cheque Load Exception Report"
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "PSW" 
			LET p_rec_kandooreport.selection_flag= "N" 
			LET p_rec_kandooreport.line1_text = "WHICS-Open", 10 spaces, 
			"Tran" 
			LET p_rec_kandooreport.line2_text = "glob_rec_kandoouser.cmpy_code", 1 spaces, 
			"Payee #", 8 spaces, 
			"Type", 4 spaces, 
			"Reference", 2 spaces, 
			"Status" 

		WHEN "PSW-2"
			LET p_rec_kandooreport.header_text = "AP Voucher/Cheque Load"
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "PSW" 
			LET p_rec_kandooreport.selection_flag = "N" 
			LET p_rec_kandooreport.line1_text = "Company", 2 spaces, 
			"Vendor", 4 spaces, 
			"Tran. Date", 2 spaces, 
			"Voucher No.", 4 spaces, 
			"Cheque No.", 19 spaces, 
			"Dist. Lines", 5 spaces, 
			"Debit Amount", 6 spaces, 
			"Credit Amount" 
					
		WHEN "PX1"		
			LET p_rec_kandooreport.header_text = "Standard Remittance Print Routine"
			LET p_rec_kandooreport.width_num = 80
			LET p_rec_kandooreport.length_num = 66
			LET p_rec_kandooreport.menupath_text = "PX1"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N
			
		WHEN "PX2"		
			LET p_rec_kandooreport.header_text = "PX2 Standard Remittance Advice Print Routine"
			LET p_rec_kandooreport.width_num = 80
			LET p_rec_kandooreport.length_num = 66
			LET p_rec_kandooreport.menupath_text = "PX2"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N

		WHEN "PX3_J-S"
			LET p_rec_kandooreport.header_text = "External Payment Summary"
			LET p_rec_kandooreport.width_num = 132
			LET p_rec_kandooreport.length_num = 66
			LET p_rec_kandooreport.menupath_text = "PX3_J"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N


		WHEN "PX3_J-U"
			LET p_rec_kandooreport.header_text = "External Payment GE Capital F/S "
			LET p_rec_kandooreport.width_num = 132
			LET p_rec_kandooreport.length_num = 66
			LET p_rec_kandooreport.menupath_text = "PX3_J"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N


		OTHERWISE
			LET p_rec_kandooreport.header_text = "MISSING IN DEFAULT TEMPLATES"
	END CASE

	RETURN p_rec_kandooreport.* 
END FUNCTION 
