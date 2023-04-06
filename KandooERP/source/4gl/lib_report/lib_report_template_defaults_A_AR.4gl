############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl" 

#####################################################################
# FUNCTION rpt_set_kandooreport_defaults(p_rec_kandooreport)
#
# Set the default report parameters
# RETURN p_rec_kandooreport.*
#####################################################################
FUNCTION rpt_set_kandooreport_defaults_a_ar(p_rec_kandooreport)
	DEFINE p_rec_kandooreport RECORD LIKE kandooreport.*
	
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	
	CASE upshift(p_rec_kandooreport.report_code)

		#AR Accounts Receivable	

		######################################################################
		# AR - Accounts Receivable 
		#
		######################################################################

		WHEN "A62"		
			LET p_rec_kandooreport.header_text = "AR Trial Deposit List" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "A62" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
			LET p_rec_kandooreport.line1_text = "Line Reference  Date        Deposit Amt    Drawer               Bank/Card       Branch/Card No       Cheque No  Location Sation Code" 

		WHEN "A64"		
			LET p_rec_kandooreport.header_text = "AR Bank Deposit Slip" 
			LET p_rec_kandooreport.width_num = 88 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "A64" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N
			
		WHEN "A2E"		
			LET p_rec_kandooreport.header_text = "AR Invoice Transfer" 
			LET p_rec_kandooreport.width_num = 80 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "A2E" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
			LET p_rec_kandooreport.line1_text = "Customer Name",24 spaces,"Address" 


		WHEN "AA1"		
			LET p_rec_kandooreport.header_text = "AR - Customer Address Listing" 
			LET p_rec_kandooreport.width_num = 140 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "AA1" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" 
			LET p_rec_kandooreport.line1_text = "Customer Name                           Address                                                      City                 State  Post Code" 
			LET p_rec_kandooreport.line2_text = "  code                                                                                                                                    "

		WHEN "AA2"		
			LET p_rec_kandooreport.header_text = "AR Customer Phone Listing" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "AA2" 
			LET p_rec_kandooreport.selection_flag = "Y" 
			LET p_rec_kandooreport.line1_text[01,4] = "Code" 
			LET p_rec_kandooreport.line1_text[10,38] = "Name" 
			LET p_rec_kandooreport.line1_text[40,59] = "City" 
			LET p_rec_kandooreport.line1_text[61,63] = " " 
			LET p_rec_kandooreport.line1_text[65,82] = "Telephone" 
			LET p_rec_kandooreport.line1_text[84,101] = "Facsimilie" 
			LET p_rec_kandooreport.line1_text[103,120] ="Mobile Phone" 
			LET p_rec_kandooreport.line1_text[122,132] ="ABN" 

		WHEN "AA3"
			LET p_rec_kandooreport.header_text = "AR - Customer Note Listing" 
			LET p_rec_kandooreport.width_num = 80 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "AA3" 
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" 

		WHEN "AA5"		
			LET p_rec_kandooreport.header_text = "AR - Customer Address By Postcode" 
			LET p_rec_kandooreport.width_num = 140 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "AA5" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" 
			LET p_rec_kandooreport.line1_text = "Customer Name                           Address                                                      City                 State  Contact"
			LET p_rec_kandooreport.line2_text = "  code                                                                                                                                  "

		WHEN "AA6"		
			LET p_rec_kandooreport.header_text = "AR - Customer Address Listing By Salesperson" 
			LET p_rec_kandooreport.width_num = 140 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "AA6" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" 
			LET p_rec_kandooreport.line1_text = "Customer Name                           Address                                                      City                 State  Contact"
			LET p_rec_kandooreport.line2_text = "  code                                                                                                                                  "
		
		WHEN "AA7"		
			LET p_rec_kandooreport.header_text = "AR - Customer Listing by Customer Type" 
			LET p_rec_kandooreport.width_num = 140 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "AA7" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" 
			LET p_rec_kandooreport.line1_text = "Customer Name                           Address                                                      City                 State  Contact"
			LET p_rec_kandooreport.line2_text = "  code                                                                                                                                  "
	
		WHEN "AA8"
			LET p_rec_kandooreport.header_text = "AR Customer Shipping Address Listing" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "AA8" 
			LET p_rec_kandooreport.selection_flag = "Y" 
			LET p_rec_kandooreport.line1_text[01,10] = "Ship Code" 
			LET p_rec_kandooreport.line1_text[12,20] = "Name" 
			LET p_rec_kandooreport.line1_text[42,60] = "Address" 
			LET p_rec_kandooreport.line1_text[102,106]="City" 
			LET p_rec_kandooreport.line1_text[122,132]="State Post" 
		
		WHEN "AA9"	
			LET p_rec_kandooreport.header_text = "Customer Promotions Report"
			LET p_rec_kandooreport.width_num = 132
			LET p_rec_kandooreport.length_num = 66
			LET p_rec_kandooreport.menupath_text = "AA9"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N
			LET p_rec_kandooreport.line1_text = "      Prom  Prom    Start       End                    Main  Prod  Product         Class    Ware   Discount UOM    Disc List  Status"
			LET p_rec_kandooreport.line2_text = "      Type  Code    Date        Date                   Group Group Code            Code     Code      Price Code      % Level"

		WHEN "AAA"	
			LET p_rec_kandooreport.header_text = "Customer Credit Status Report"
			LET p_rec_kandooreport.width_num = 132
			LET p_rec_kandooreport.length_num = 66
			LET p_rec_kandooreport.menupath_text = "AAA"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N
			LET p_rec_kandooreport.line1_text = "   Customer        Name                  Hold         Credit   Limit            Current         Sales   Last      Last      Payment  "
			LET p_rec_kandooreport.line2_text = "   Code                                  Code         Amount   % used           Balance         Orders  Sale      Payment     Ratio  "
	
		WHEN "AAB_B"	
			LET p_rec_kandooreport.header_text = "Customer Summary Aging"
			LET p_rec_kandooreport.width_num = 132
			LET p_rec_kandooreport.length_num = 66
			LET p_rec_kandooreport.menupath_text = "AAB_B"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N
			                              #123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012
			LET p_rec_kandooreport.line1_text = "Customer           Name                 Balance            Current        1-30 Days      31-60 Days     61-90 Days    90 Plus  Hold"
			                              #123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012
			LET p_rec_kandooreport.line2_text = "  Code                     Currency                                       Overdue        Overdue        Overdue       Overdue Sales"

		WHEN "AAB"		
			LET p_rec_kandooreport.header_text = "Customer Summary Aging"
			LET p_rec_kandooreport.width_num = 132
			LET p_rec_kandooreport.length_num = 66
			LET p_rec_kandooreport.menupath_text = "AAB"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N
			                              #123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012
			LET p_rec_kandooreport.line1_text = "Customer           Name                     Balance        Current        1-30 Days      31-60 Days     61-90 Days    90 Plus   Hold"
			                              #123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012
			LET p_rec_kandooreport.line2_text = "  Code                            Currency                                Overdue        Overdue        Overdue       Overdue  Sales"

		WHEN "AAC"		
			LET p_rec_kandooreport.header_text = "Customer History Listing"
			LET p_rec_kandooreport.width_num = 132
			LET p_rec_kandooreport.length_num = 66
			LET p_rec_kandooreport.menupath_text = "AAC"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N
			                              #123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012
			LET p_rec_kandooreport.line1_text = "    Year Period       Sales        Cost of        Credits       Value of         Profit           Profit %            Cash"
			                              #123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012
			LET p_rec_kandooreport.line2_text = "                                     Sales                       Credits                                          Received"

		WHEN "AAD"		
			LET p_rec_kandooreport.header_text = "AR - Customer Ledger Listing" 
			LET p_rec_kandooreport.width_num = 80 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "AAD" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" 
			LET p_rec_kandooreport.line1_text = "Customer ------------------------ Transaction ----------------------- Cumulative" 
			LET p_rec_kandooreport.line2_text = "      No.      Date   Type  Number   Description         Amount        Balance" 

		WHEN "AAE"		
			LET p_rec_kandooreport.header_text = "Customer Summary Aging"
			LET p_rec_kandooreport.width_num = 132
			LET p_rec_kandooreport.length_num = 66
			LET p_rec_kandooreport.menupath_text = "AAE"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N
			                              #123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012
			LET p_rec_kandooreport.line1_text = "Customer           Name                     Balance        Current        1-30 Days      31-60 Days     61-90 Days    90 Plus   Hold"
			                              #123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012
			LET p_rec_kandooreport.line2_text = "  Code                            Currency                                Overdue        Overdue        Overdue       Overdue  Sales"

		WHEN "AAF"
			LET p_rec_kandooreport.header_text = "Customer Summary Aging"
			LET p_rec_kandooreport.width_num = 132
			LET p_rec_kandooreport.length_num = 66
			LET p_rec_kandooreport.menupath_text = "AAF"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N
{
			PRINT COLUMN 1, "Customer", 
			COLUMN 20, "Name", 
			COLUMN 45, "Balance", 
			COLUMN 60, "Current", 
			COLUMN 75, "1-30 Days", 
			COLUMN 90, "31-60 Days", 
			COLUMN 105, "61-90 Days", 
			COLUMN 119, "90 Plus", 
			COLUMN 129, "Hold" 
			PRINT COLUMN 1, " Code ", 
			COLUMN 35, "Currency", 
			COLUMN 75, "Overdue", 
			COLUMN 90, "Overdue", 
			COLUMN 105, "Overdue", 
			COLUMN 119, "Overdue", 
			COLUMN 128, "Sales" 
}			
		WHEN "AAG"
			LET p_rec_kandooreport.header_text = "Customer Summary Aging By Currency"
			LET p_rec_kandooreport.width_num = 132
			LET p_rec_kandooreport.length_num = 66
			LET p_rec_kandooreport.menupath_text = "AAG"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N
			{
			PRINT COLUMN 1, "Customer", 
			COLUMN 20, "Name", 
			COLUMN 40, "Balance", 
			COLUMN 55, "Current", 
			COLUMN 70, "1-30 Days", 
			COLUMN 85, "31-60 Days", 
			COLUMN 100, "61-90 Days", 
			COLUMN 114, "90 Plus", 
			COLUMN 126, "Hold" 
			PRINT COLUMN 1, " Code ", 
			COLUMN 75, "Overdue", 
			COLUMN 85, "Overdue", 
			COLUMN 100, "Overdue", 
			COLUMN 114, "Overdue", 
			COLUMN 126, "Sales" 

			}
		WHEN "AAH"
			LET p_rec_kandooreport.header_text = "AAH - Summary Aging by State Report"
			LET p_rec_kandooreport.width_num = 132
			LET p_rec_kandooreport.length_num = 66
			LET p_rec_kandooreport.menupath_text = "AAH"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N
			{
			PRINT COLUMN 1, "Debtors l_details", 
			COLUMN 37, "Balance", 
			COLUMN 52, "Current", 
			COLUMN 66, "1-30 Days", 
			COLUMN 80, "31-60 Days", 
			COLUMN 95, "61-90 Days", 
			COLUMN 113, "90 Plus" 
			PRINT COLUMN 67, "Overdue", 
			COLUMN 82, "Overdue", 
			COLUMN 97, "Overdue", 
			COLUMN 113, "Overdue" 
			}
		WHEN "AAI"	
			LET p_rec_kandooreport.header_text = "AAI - Corporate Debtors Address Listing"
			LET p_rec_kandooreport.width_num = 132
			LET p_rec_kandooreport.length_num = 66
			LET p_rec_kandooreport.menupath_text = "AAI"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N


		WHEN "AAJ"	
			LET p_rec_kandooreport.header_text = "Salesperson Customer Account Aging" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "AAJ" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 

		WHEN "AAK"
			LET p_rec_kandooreport.header_text = "Summary Debtors Aging Report" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "AAK" 
			LET p_rec_kandooreport.selection_flag = "Y" 
			LET p_rec_kandooreport.line1_text = 
			"------------------------ Month Due -----------------------------", " Percent Hold" 
			LET p_rec_kandooreport.line2_text =	"Customer Name Balance"
					
		WHEN "AAL"
			LET p_rec_kandooreport.header_text = "Customer Summary Aging "
			LET p_rec_kandooreport.width_num = 132
			LET p_rec_kandooreport.length_num = 66
			LET p_rec_kandooreport.menupath_text = "AAL"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N
			LET p_rec_kandooreport.line1_text = "Customer           Name                  Balance         Current       1-30 Days      31-60 Days      61-90 Days      90 Plus  Hold"
			LET p_rec_kandooreport.line2_text = "  Code                     Currency                                      Overdue        Overdue        Overdue        Overdue Sales"

		WHEN "AAM"
			LET p_rec_kandooreport.header_text = "Debtors Funds Employed Report"
			LET p_rec_kandooreport.width_num = 132
			LET p_rec_kandooreport.length_num = 66
			LET p_rec_kandooreport.menupath_text = "AAM"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N
			                              #123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012
			LET p_rec_kandooreport.line1_text = "Segment             (In Base Currency)   Balance         Current       1-30 Days      31-60 Days      61-90 Days         90 Plus  "
			                              #4567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012
			LET p_rec_kandooreport.line2_text = "                                                 Overdue         Overdue         Overdue          Overdue  "

		WHEN "AAP"
			LET p_rec_kandooreport.header_text = "Customer Aging by Fiscal Period" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "AAP" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 

		WHEN "AAT"
			LET p_rec_kandooreport.header_text = "AAT - Summary Aging by Customer Type Report" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "AAT" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 

		WHEN "AAT_J"
			LET p_rec_kandooreport.header_text = "AAT - Summary Aging by Customer Type Report" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "AAT_J" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N  

		WHEN "AAU" 
			LET p_rec_kandooreport.header_text = "AAU - Customer Audit Listing Report" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "AAU" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 

		WHEN "AAU_rpt_list_add"
			LET p_rec_kandooreport.header_text = "AAU - Customer Audit Listing Report - Additions" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "AAU" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 

		WHEN "AAU_rpt_list_upd" 
			LET p_rec_kandooreport.header_text = "AAU - Customer Audit Listing Report - Alterations" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "AAU" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 


		WHEN "AAU_rpt_list_del" 
			LET p_rec_kandooreport.header_text = "AAU - Customer Audit Listing Report - Deletions" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "AAU" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 


		WHEN "AAZ" 
			LET p_rec_kandooreport.header_text = "AAZ - Invoice Stories" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "AAZ" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 

		#AB
		WHEN "AB1"
			LET p_rec_kandooreport.header_text = "AB1 - Invoice by Customer Report" 
			LET p_rec_kandooreport.width_num = 108 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "AB1" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
			LET p_rec_kandooreport.line1_text = "Invoice  Purchase                         Date   Year Period      Total      Possible         Paid   Posted"
			LET p_rec_kandooreport.line2_text = "Number    Code                                                   Invoice     Discount        Amount   (GL)"

		WHEN "AB2"
			LET p_rec_kandooreport.header_text = "AR - Invoice by Number Report " 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "AB2" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
{
			PRINT COLUMN 1, "Invoice",
			COLUMN 10, "Customer", 
			COLUMN 25, "Name", 
			COLUMN 55, "Date", 
			COLUMN 61, "Year", 
			COLUMN 66, "Period", 
			COLUMN 74, "Currency", 
			COLUMN 88, "Total", 
			COLUMN 101, "Discount", 
			COLUMN 119, "Paid", 
			COLUMN 125, "Posted" 
			
			PRINT COLUMN 1, "Number", 
			COLUMN 12, "Code", 
			COLUMN 87, "Invoice", 
			COLUMN 101, "Possible", 
			COLUMN 118, "Amount", 
			COLUMN 125, " (GL) " 
}
		WHEN "AB3"
			LET p_rec_kandooreport.header_text = "AR - Invoice by Period Report" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "AB3" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
{
			PRINT COLUMN 1, "Invoice", 
			COLUMN 10, "Customer", 
			COLUMN 25, "Name", 
			COLUMN 47, "Currency", 
			COLUMN 59, " Date", 
			COLUMN 68, "Year", 
			COLUMN 73, "Period", 
			COLUMN 88, "Total", 
			COLUMN 101, "Discount", 
			COLUMN 119, "glob_paid", 
			COLUMN 125, "Posted" 

			PRINT COLUMN 1, "Number", 
			COLUMN 12, "Code", 
			COLUMN 87, "Invoice", 
			COLUMN 101, "Possible", 
			COLUMN 118, "Amount", 
			COLUMN 125, " (GL) " 
}
		WHEN "AB4"
			LET p_rec_kandooreport.header_text = "AR - Invoice by Reference Report" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "AB4" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
{
			PRINT COLUMN 1, "Invoice", 
			COLUMN 10, "Purchase", 
			COLUMN 25, "Name", 
			COLUMN 50, " Date", 
			COLUMN 59, "Year", 
			COLUMN 64, "Period", 
			COLUMN 76, "Total", 
			COLUMN 89, "Discount", 
			COLUMN 106, "Paid", 
			COLUMN 112, "Posted" 

			PRINT COLUMN 1, "Number", 
			COLUMN 12, "Code", 
			COLUMN 75, "Invoice", 
			COLUMN 89, "Possible", 
			COLUMN 105, "Amount" 
}
		WHEN "AB5"
			LET p_rec_kandooreport.header_text = "AR - Invoice by Order Number Report" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "AB5" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 

{
			PRINT COLUMN 1, "Order ", 
			COLUMN 10, "Customer", 
			COLUMN 20, "Invoice", 
			COLUMN 28, "Currency", 
			COLUMN 39, glob_rec_arparms.inv_ref2a_text, 
			COLUMN 61, " Date", 
			COLUMN 69, "Year", 
			COLUMN 74, "Period", 
			COLUMN 88, "Total", 
			COLUMN 101, "Discount", 
			COLUMN 119, "Paid", 
			COLUMN 125, "Posted" 
			PRINT COLUMN 1, "Number ", 
			COLUMN 12, "Code", 
			COLUMN 39, glob_rec_arparms.inv_ref2b_text, 
			COLUMN 87, "Invoice", 
			COLUMN 101, "Possible", 
			COLUMN 118, "Amount", 
			COLUMN 126, " (GL) " 
}
		WHEN "ABA"
			LET p_rec_kandooreport.header_text = "AR - Invoice Detail Report" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "ABA" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 

{
			PRINT COLUMN 1, "Line", 
			COLUMN 8,"Product", 
			COLUMN 30, "Invoiced", 
			COLUMN 60, "Description", 
			COLUMN 90, "Unit", 
			COLUMN 98, "Unit Price", 
			COLUMN 120, "Extended" 

			PRINT COLUMN 1, " # ", 
			COLUMN 8, " ID", 
			COLUMN 30, " Qty", 
			COLUMN 120, " Price"
}
		WHEN "ABB"
			LET p_rec_kandooreport.header_text = "AR - Invoice by Product Code Report" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "ABB" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 

{
			PRINT COLUMN 1, "Date", 
			COLUMN 10, "Customer", 
			COLUMN 21, "Invoice", 
			COLUMN 41, "Invoiced", 
			COLUMN 50, "Unit", 
			COLUMN 56, "Description", 
			COLUMN 98, "Unit Price", 
			COLUMN 119, "Extended" 

			PRINT COLUMN 10, " Code", 
			COLUMN 21, "Number", 
			COLUMN 41, " Qty", 
			COLUMN 86, "Currency", 
			COLUMN 119, " Price" 
}
		WHEN "ABD"
			LET p_rec_kandooreport.header_text = "AR Adjustment Report"
			LET p_rec_kandooreport.width_num = 80 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "ABD" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
{
			PRINT COLUMN 02, "Trans", 
			COLUMN 12, "Entry", 
			COLUMN 18, "Type", 
			COLUMN 24, "Description", 
			COLUMN 61, "Adjustment" 
			PRINT COLUMN 02, "Number", 
			COLUMN 12, "Date", 
			COLUMN 62, "Amount" 
}			
		WHEN "AC1"
			LET p_rec_kandooreport.header_text = "Receipts by Customer"
			LET p_rec_kandooreport.width_num = 80
			LET p_rec_kandooreport.length_num = 66
			LET p_rec_kandooreport.menupath_text = "AC1"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N
			                              #123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012
			LET p_rec_kandooreport.line1_text = "Receipt  Cheque         Date      Year           Amount         Amount    Posted"
			                              #123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012
			LET p_rec_kandooreport.line2_text = "Number   Reference                    Period     Received       Applied    (GL) "

		WHEN "AC2"
			LET p_rec_kandooreport.header_text = "Receipts By Number"
			LET p_rec_kandooreport.width_num = 132
			LET p_rec_kandooreport.length_num = 66
			LET p_rec_kandooreport.menupath_text = "AC2"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N
			                              #123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012
			LET p_rec_kandooreport.line1_text = "Receipt  Cheque         Date      Year Period         Amount          Amount  Posted Customer  Name"
			                              #123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012
			LET p_rec_kandooreport.line2_text = "Number   Number                                       Received        Applied  (GL)   Code  "

		WHEN "AC3"
			LET p_rec_kandooreport.header_text = "Receipts By Period"
			LET p_rec_kandooreport.width_num = 80
			LET p_rec_kandooreport.length_num = 66
			LET p_rec_kandooreport.menupath_text = "AC3"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag =	"Y"
																		#123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012
			LET p_rec_kandooreport.line1_text = "Receipt  Cheque         Date      Period         Amount         Amount    Posted"
																		#123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012
			LET p_rec_kandooreport.line2_text = "Number   Reference                               Received       Applied    (GL)"

		WHEN "AC4"
			LET p_rec_kandooreport.header_text = "Receipts by Cheque"
			LET p_rec_kandooreport.width_num = 80
			LET p_rec_kandooreport.length_num = 66
			LET p_rec_kandooreport.menupath_text = "AC4"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N
			#123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012
			LET p_rec_kandooreport.line1_text = "Receipt  Cheque         Date      Year           Amount    Amount         Posted"
			#123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012
			LET p_rec_kandooreport.line2_text = "Number   Reference                     Period    Received        Applied"

		WHEN "AC5"
			LET p_rec_kandooreport.header_text = "Cash Applications"
			LET p_rec_kandooreport.width_num = 132
			LET p_rec_kandooreport.length_num = 66
			LET p_rec_kandooreport.menupath_text = "AC5"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N
			#123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012
			LET p_rec_kandooreport.line1_text = "Application   Date      Invoice   Payment   Cheque                   Amount             Amount         Discount"
			#123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012
			LET p_rec_kandooreport.line2_text = "Number        Applied   Number    Number    Reference                Outstanding        Applied        Given"

		WHEN "AC6"
			LET p_rec_kandooreport.header_text = "AC6 - Daily Bank Deposit Slips"
			LET p_rec_kandooreport.width_num = 132
			LET p_rec_kandooreport.length_num = 66
			LET p_rec_kandooreport.menupath_text = "AC6"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N
			
		WHEN "AC8"
			LET p_rec_kandooreport.header_text = "Receipts by Reference"
			LET p_rec_kandooreport.width_num = 80
			LET p_rec_kandooreport.length_num = 66
			LET p_rec_kandooreport.menupath_text = "AC8"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N
			#123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012
			LET p_rec_kandooreport.line1_text = "Receipt  Reference      Date      Year           Amount          Amount   Posted"
			#123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012
			LET p_rec_kandooreport.line2_text = "Number                                 Period    Received        Applied"

		WHEN "AC9"
			LET p_rec_kandooreport.header_text = "Receipts by Number"
			LET p_rec_kandooreport.width_num = 132
			LET p_rec_kandooreport.length_num = 66
			LET p_rec_kandooreport.menupath_text = "AC9"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N
			LET p_rec_kandooreport.line1_text = "Receipt  Customer Name"
			LET p_rec_kandooreport.line2_text = "Number              Date        Received   --------------------------- Payment Details --------------------------- ---- Banked -----"
			LET p_rec_kandooreport.line3_text = "                                 Amount  Type Cheque     Bank            Branch               Drawer               Date     Deposit"

		WHEN "ACA"
			LET p_rec_kandooreport.header_text = "Unapplied Receipts"
			LET p_rec_kandooreport.width_num = 132
			LET p_rec_kandooreport.length_num = 66
			LET p_rec_kandooreport.menupath_text = "ACA"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N
			#123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012
			LET p_rec_kandooreport.line1_text = "Application   Date      Invoice   Payment      Order       Cheque             Amount         Unapplied"
			#123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012
			LET p_rec_kandooreport.line2_text = " Number       Applied   Number    Number      Number       Reference          Applied         Amount"

		WHEN "ACB"
			LET p_rec_kandooreport.header_text = "AR - Cash Receipts Listing"
			LET p_rec_kandooreport.width_num = 132
			LET p_rec_kandooreport.length_num = 66
			LET p_rec_kandooreport.menupath_text = "ACB"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N
			
		WHEN "ADA"
			LET p_rec_kandooreport.header_text = "AR Credit by Customer Report"
			LET p_rec_kandooreport.width_num = 80		
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "ADA"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N			
{
			PRINT COLUMN 1, "Credit", 
			COLUMN 10, glob_rec_arparms.credit_ref2a_text, 
			COLUMN 25, "Date", 
			COLUMN 35, "Year", 
			COLUMN 50, "Total", 
			COLUMN 65, "Amount", 
			COLUMN 73, "Posted" 
			PRINT COLUMN 1, "Number", 
			COLUMN 10, glob_rec_arparms.credit_ref2b_text, 
			COLUMN 39, "Period", 
			COLUMN 50, "Amount", 
			COLUMN 65, "Applied", 
			COLUMN 73, " (GL) " 
}
		WHEN "ADB" #AR Credit Listing by Number
			LET p_rec_kandooreport.header_text = "AR - Credit Listing by Number"
			LET p_rec_kandooreport.width_num = 80		
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "ADB"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N		
{
			PRINT COLUMN 1, "Credit", 
			COLUMN 10, glob_rec_arparms.credit_ref2a_text, 
			COLUMN 21, "Customer", 
			COLUMN 30, "Date", 
			COLUMN 40, "Year", 
			COLUMN 48, "Currency", 
			COLUMN 59, "Total", 
			COLUMN 71, "Amount", 
			COLUMN 79, "Posted" 
			PRINT COLUMN 1, "Number", 
			COLUMN 11, glob_rec_arparms.credit_ref2b_text, 
			COLUMN 22, " Code", 
			COLUMN 43, "Period", 
			COLUMN 59, "Amount", 
			COLUMN 71, "Applied", 
			COLUMN 79, " (GL)" 
}			 
		WHEN "ADC" 
			LET p_rec_kandooreport.header_text = "AR - Credit by Period Report"
			LET p_rec_kandooreport.width_num = 80		
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "ADC"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N	
				
{
			PRINT COLUMN 1, "Credit", 
			COLUMN 10, glob_rec_arparms.credit_ref2a_text, 
			COLUMN 21, "Customer", 
			COLUMN 30, "Date", 
			COLUMN 53, "Total", 
			COLUMN 67, "Amount", 
			COLUMN 75, "Posted" 
			PRINT COLUMN 1, "Number", 
			COLUMN 10, glob_rec_arparms.credit_ref2b_text, 
			COLUMN 22, " Code ", 
			COLUMN 53, "Amount", 
			COLUMN 67, "Applied", 
			COLUMN 75, " (GL)" 
}
		WHEN "ADD" #ADD - Credit by Reference Report
			LET p_rec_kandooreport.header_text = "ADD - Credit by Reference Report"
			LET p_rec_kandooreport.width_num = 80		
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "ADB"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N	
{
			PRINT COLUMN 1, glob_rec_arparms.credit_ref2a_text, 
			COLUMN 13, "Credit", 
			COLUMN 21, "Customer", 
			COLUMN 30, "Date", 
			COLUMN 42, "Period", 
			COLUMN 60, "Total", 
			COLUMN 72, "Amount", 
			COLUMN 80, "Posted" 
			PRINT COLUMN 1, glob_rec_arparms.credit_ref2b_text, 
			COLUMN 12, "Number", 
			COLUMN 22, " Code ", 
			COLUMN 48, "Currency", 
			COLUMN 60, "Amount", 
			COLUMN 72, "Applied" 
}
		WHEN "ADE" 
			LET p_rec_kandooreport.header_text = "ADE - Credit Detail Report"
			LET p_rec_kandooreport.width_num = 132		
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "ADE"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N	
{
			PRINT COLUMN 1, "Line", 
			COLUMN 8, "Product", 
			COLUMN 22, "Credited", 
			COLUMN 42, "Description", 
			COLUMN 64, "Unit", 
			COLUMN 69, "Unit Price", 
			COLUMN 81, "Extended", 
			COLUMN 105,"Extended", 
			COLUMN 117,"Line Total" 
			PRINT COLUMN 2,"No. ", 
			COLUMN 10,"ID", 
			COLUMN 24,"Qty", 
			COLUMN 82,"Price", 
			COLUMN 106,"Tax" 
}

		WHEN "ADF"
			LET p_rec_kandooreport.header_text = "ADF - Credit Application Report"
			LET p_rec_kandooreport.width_num = 80		
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "ADF"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N

		WHEN "ADR-DET"
			LET p_rec_kandooreport.header_text = "ADR - Credit by Reason Report"
			LET p_rec_kandooreport.width_num = 132		
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "ADR"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N
{
			PRINT COLUMN 09, "Line", 
			COLUMN 18, "Product", 
			COLUMN 32, "Credited", 
			COLUMN 41, "Description", 
			COLUMN 73, "Unit", 
			COLUMN 80, "Unit Price", 
			COLUMN 98, "Extended" 
			
			PRINT COLUMN 10, "No.", 
			COLUMN 20, "ID", 
			COLUMN 34, "Qty", 
			COLUMN 101, "Price"

---------------

			PRINT COLUMN 16, "Credit", 
			COLUMN 30, "Date", 
			COLUMN 42, "Year/Per", 
			COLUMN 58, "Total", 
			COLUMN 71, "Comments" 

}																				
		WHEN "ADR-SUM"
			LET p_rec_kandooreport.header_text = "ADR - Credit by Reason Report"
			LET p_rec_kandooreport.width_num = 132		
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "ADR"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N
{
			PRINT COLUMN 09, "Line", 
			COLUMN 18, "Product", 
			COLUMN 32, "Credited", 
			COLUMN 41, "Description", 
			COLUMN 73, "Unit", 
			COLUMN 80, "Unit Price", 
			COLUMN 98, "Extended" 
			
			PRINT COLUMN 10, "No.", 
			COLUMN 20, "ID", 
			COLUMN 34, "Qty", 
			COLUMN 101, "Price"

---------------

			PRINT COLUMN 16, "Credit", 
			COLUMN 30, "Date", 
			COLUMN 42, "Year/Per", 
			COLUMN 58, "Total", 
			COLUMN 71, "Comments" 

}	
		WHEN "ADU"
			LET p_rec_kandooreport.header_text = "Unapplied Credits"
			LET p_rec_kandooreport.width_num = 132
			LET p_rec_kandooreport.length_num = 66
			LET p_rec_kandooreport.menupath_text = "ADU"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N
			LET p_rec_kandooreport.line1_text = "Application    Date        Invoice   Payment      Order                         Amount       Unapplied"
			LET p_rec_kandooreport.line2_text = " Number        Applied     Number    Number      Number                         Applied         Amount"


		WHEN "AE1"
			LET p_rec_kandooreport.header_text = "AE1 - Analysis by Customer Report"
			LET p_rec_kandooreport.width_num = 132
			LET p_rec_kandooreport.length_num = 66
			LET p_rec_kandooreport.menupath_text = "AE1"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N
{
			PRINT COLUMN 1, "Date", 
			COLUMN 10, "Trans", 
			COLUMN 18, " Doc", 
			COLUMN 33, glob_rec_arparms.inv_ref2a_text, 
			COLUMN 52, "Invoice", 
			COLUMN 66, " Cost ", 
			COLUMN 77, "Discount", 
			COLUMN 91, "Commission", 
			COLUMN 111, " Net ", 
			COLUMN 120, "Profit" 
			PRINT COLUMN 10, "Type", 
			COLUMN 18, "Number", 
			COLUMN 34, glob_rec_arparms.inv_ref2b_text, 
			COLUMN 52, "Amount", 
			COLUMN 66, "Amount", 
			COLUMN 78, "Amount", 
			COLUMN 93, "Amount", 
			COLUMN 111, "Profit", 
			COLUMN 122, "%" 
}
		WHEN "AE2"
			LET p_rec_kandooreport.header_text = "AE2 - Analysis by Invoice Report"
			LET p_rec_kandooreport.width_num = 132
			LET p_rec_kandooreport.length_num = 66
			LET p_rec_kandooreport.menupath_text = "AE2"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N

{
			PRINT COLUMN 1, "(** all amounts local currency at rate ON day OF transaction **)" 
			IF modu_tx_ans = "N" THEN 
				PRINT COLUMN 5, "Invoice Amounts are exclusive of Tax " 
			ELSE 
				PRINT COLUMN 5, "Invoice Amounts are inclusive of Tax " 
			END IF
			 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  
			PRINT COLUMN 1, "Date", 
			COLUMN 9, "Trans", 
			COLUMN 16, "Doc", 
			COLUMN 22, "Customer", 
			COLUMN 61, "Invoice", 
			COLUMN 75, "Invoice", 
			COLUMN 88, "Discount", 
			COLUMN 116, "Net", 
			COLUMN 125, "Profit" 
			PRINT COLUMN 9, "Type", 
			COLUMN 17, "#", 
			COLUMN 22, "Name", 
			COLUMN 62, "Amount", 
			COLUMN 78, "Cost", 
			COLUMN 90, "Amount", 
			COLUMN 113, "Profit", 
			COLUMN 127, "%"
}						
		WHEN "AE3"
			LET p_rec_kandooreport.header_text = "AE3 - Analysis by Salesperson Report"
			LET p_rec_kandooreport.width_num = 132
			LET p_rec_kandooreport.length_num = 66
			LET p_rec_kandooreport.menupath_text = "AE3"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
{
			PRINT COLUMN 1, 
			"(** all amounts local currency at rate ON day OF transaction **)" 
			IF modu_tx_ans = "N" THEN 
				PRINT COLUMN 5, "Invoice Amounts are exclusive of Tax " 
			ELSE 
				PRINT COLUMN 5, "Invoice Amounts are inclusive of Tax " 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2]
			PRINT COLUMN 1, "Date", 
			COLUMN 9, "Trans", 
			COLUMN 15, " Doc", 
			COLUMN 22, "Customer", 
			COLUMN 53, "Invoice", 
			COLUMN 67, "Invoice", 
			COLUMN 80, "Discount", 
			COLUMN 92, "Commission", 
			COLUMN 115, "Net", 
			COLUMN 120, "Profit" 
			PRINT COLUMN 9, "Type", 
			COLUMN 17, "#", 
			COLUMN 22, "Name", 
			COLUMN 54, "Amount", 
			COLUMN 70, "Cost", 
			COLUMN 82, "Amount", 
			COLUMN 96, "Amount", 
			COLUMN 112, "Profit", 
			COLUMN 123, "%" 

}
		WHEN "AE4"
			LET p_rec_kandooreport.header_text = "AE4 - Analysis by Customer Type Report"
			LET p_rec_kandooreport.width_num = 132
			LET p_rec_kandooreport.length_num = 66
			LET p_rec_kandooreport.menupath_text = "AE4"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N  
{
			PRINT COLUMN 1, "(** all amounts local currency at rate ON day OF transaction **)" 
			IF modu_tx_ans = "N" THEN 
				PRINT COLUMN 5, "Invoice Amounts are exclusive of Tax " 
			ELSE 
				PRINT COLUMN 5, "Invoice Amounts are inclusive of Tax " 
			END IF
			 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

			PRINT COLUMN 1, "Date", 
			COLUMN 9, "Trans", 
			COLUMN 15, "Doc", 
			COLUMN 22, "Customer", 
			COLUMN 47, "Type", 
			COLUMN 59, "Invoice", 
			COLUMN 73, "Invoice", 
			COLUMN 86, "Discount", 
			COLUMN 98, "Commission", 
			COLUMN 118,"Net", 
			COLUMN 125,"Profit" 
			PRINT COLUMN 9, "Type", 
			COLUMN 17, "#", 
			COLUMN 22, "Name", 
			COLUMN 60, "Amount", 
			COLUMN 76, "Cost", 
			COLUMN 88, "Amount", 
			COLUMN 102,"Amount", 
			COLUMN 116,"Profit", 
			COLUMN 127,"%" 
}
		WHEN "AE6"
			LET p_rec_kandooreport.header_text = "AE6 - Analysis by Customer excluding Tax Report"
			LET p_rec_kandooreport.width_num = 132
			LET p_rec_kandooreport.length_num = 66
			LET p_rec_kandooreport.menupath_text = "AE6"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
{
			PRINT COLUMN 1, 
			"**All amounts in local currency AT rate on day of transaction**" 
			
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]
  
			PRINT COLUMN 13, "PTD", 
			COLUMN 24, "PTD", 
			COLUMN 38, "PTD", 
			COLUMN 52, "PTD", 
			COLUMN 64, "PTD", 
			COLUMN 77, "YTD", 
			COLUMN 91, "YTD", 
			COLUMN 104, "YTD", 
			COLUMN 117, "YTD", 
			COLUMN 126, "YTD" 
			PRINT COLUMN 10, "Quantity", 
			COLUMN 23, "Sales", 
			COLUMN 38, "Cost", 
			COLUMN 50, "Margin", 
			COLUMN 62, "Margin", 
			COLUMN 74, "Quantity", 
			COLUMN 90, "Sales", 
			COLUMN 104, "Cost", 
			COLUMN 115, "Margin", 
			COLUMN 124, "Margin" 
			PRINT COLUMN 52, "($)", 
			COLUMN 64, "(%)", 
			COLUMN 117, "($)", 
			COLUMN 126, "(%)" 
}
		WHEN "AE7"
			LET p_rec_kandooreport.header_text = "AE7 - Analysis by Product excluding Tax Report"
			LET p_rec_kandooreport.width_num = 132
			LET p_rec_kandooreport.length_num = 66
			LET p_rec_kandooreport.menupath_text = "AE7"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
{
			PRINT COLUMN 1, 
			"**All amounts in local currency AT rate on day of transaction**"
			 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

			PRINT COLUMN 13, "PTD", 
			COLUMN 24, "PTD", 
			COLUMN 38, "PTD", 
			COLUMN 52, "PTD", 
			COLUMN 61, "PTD", 
			COLUMN 78, "YTD", 
			COLUMN 90, "YTD", 
			COLUMN 104, "YTD", 
			COLUMN 116, "YTD", 
			COLUMN 127, "YTD" 
			PRINT COLUMN 10, "Quantity", 
			COLUMN 21, "Sales", 
			COLUMN 38, "Cost", 
			COLUMN 50, "Margin", 
			COLUMN 59, "Margin", 
			COLUMN 75, "Quantity", 
			COLUMN 89, "Sales", 
			COLUMN 104, "Cost", 
			COLUMN 114, "Margin", 
			COLUMN 125, "Margin" 
			PRINT COLUMN 52, "($)", 
			COLUMN 61, "(%)", 
			COLUMN 116, "($)", 
			COLUMN 127, "(%)"
}
		WHEN "AE8"
			LET p_rec_kandooreport.header_text = "AE8 - Analysis by Salesperson excluding Tax Report"
			LET p_rec_kandooreport.width_num = 132
			LET p_rec_kandooreport.length_num = 66
			LET p_rec_kandooreport.menupath_text = "AE8"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
{
			PRINT COLUMN 1, 
			"**All amounts in local currency AT rate on day of transaction**" 
			PRINT COLUMN 1, "--------------------------------------------------", 
			"--------------------------------------------------", 
			"-------------------------------" 
			PRINT COLUMN 13, "PTD", 
			COLUMN 24, "PTD", 
			COLUMN 38, "PTD", 
			COLUMN 52, "PTD", 
			COLUMN 61, "PTD", 
			COLUMN 78, "YTD", 
			COLUMN 90, "YTD", 
			COLUMN 104, "YTD", 
			COLUMN 116, "YTD", 
			COLUMN 127, "YTD" 
			PRINT COLUMN 10, "Quantity", 
			COLUMN 21, "Sales", 
			COLUMN 38, "Cost", 
			COLUMN 50, "Margin", 
			COLUMN 59, "Margin", 
			COLUMN 75, "Quantity", 
			COLUMN 89, "Sales", 
			COLUMN 104, "Cost", 
			COLUMN 114, "Margin", 
			COLUMN 125, "Margin" 
			PRINT 
			COLUMN 52, "($)", 
			COLUMN 61, "(%)", 
			COLUMN 116, "($)", 
			COLUMN 127, "(%)" 
}
		WHEN "AE9"
			LET p_rec_kandooreport.header_text = "AE9 - Analysis by Invoice & Department Code Report"
			LET p_rec_kandooreport.width_num = 132
			LET p_rec_kandooreport.length_num = 66
			LET p_rec_kandooreport.menupath_text = "AE9"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
{
			PRINT 
			COLUMN 1, "Period", 
			COLUMN 13, "PTD", 
			COLUMN 24, "PTD", 
			COLUMN 38, "PTD", 
			COLUMN 52, "PTD", 
			COLUMN 61, "PTD", 
			COLUMN 78, "YTD", 
			COLUMN 90, "YTD", 
			COLUMN 104, "YTD", 
			COLUMN 116, "YTD", 
			COLUMN 127, "YTD" 
			PRINT 
			COLUMN 1, "Number", 
			COLUMN 10, "Quantity", 
			COLUMN 21, "Sales", 
			COLUMN 38, "Cost", 
			COLUMN 50, "Margin", 
			COLUMN 59, "Margin", 
			COLUMN 75, "Quantity", 
			COLUMN 89, "Sales", 
			COLUMN 104, "Cost", 
			COLUMN 114, "Margin", 
			COLUMN 125, "Margin" 
			PRINT 
			COLUMN 1, p_curr_period clipped, 
			COLUMN 52, "($)", 
			COLUMN 61, "(%)", 
			COLUMN 116, "($)", 
			COLUMN 127, "(%)"
}
		WHEN "AEC"
			LET p_rec_kandooreport.header_text = "AEC - Analysis by Invoice & Discount Report" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "AEC" 
			LET p_rec_kandooreport.selection_flag = "Y" 
			LET p_rec_kandooreport.line1_text ="--- Transaction ---- Customer",28 spaces," Nett Cost Gross Profit Discount"
			LET p_rec_kandooreport.line2_text =" Date Type Number ",28 spaces,"Amount Amount Amount Amount Percent" 
									 											
		WHEN "AED"
			LET p_rec_kandooreport.header_text = "Divisional Margin Analysis"
			LET p_rec_kandooreport.width_num = 132
			LET p_rec_kandooreport.length_num = 66
			LET p_rec_kandooreport.menupath_text = "AED"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N
			                              #123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012
			LET p_rec_kandooreport.line1_text = "Customer     --------- Invoice ---------   Quantity     -------- Unit -------         -------- Extended --------       %"
			                              #123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012
			LET p_rec_kandooreport.line2_text = "  Code       Date       Number      Line                Sales            Cost         Sales                 Cost     Margin"

		WHEN "AEE"
			LET p_rec_kandooreport.header_text = "Inventory Margin Analysis"
			LET p_rec_kandooreport.width_num = 132
			LET p_rec_kandooreport.length_num = 66
			LET p_rec_kandooreport.menupath_text = "AEE"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N
			                              #123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012
			LET p_rec_kandooreport.line1_text = "Product    Part            --- Reference ---     Quantity      --------- Unit -------         ------- Extended -------          %"
			                              #123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012
			LET p_rec_kandooreport.line2_text = "Category   Code            Cust #  Invoice #                   Sales             Cost         Sales               Cost        Margin"

		WHEN "AEE-SUM"
			LET p_rec_kandooreport.header_text = "AEF Item Sales Report - Summary (S1D)"
			LET p_rec_kandooreport.width_num = 132
			LET p_rec_kandooreport.length_num = 66
			LET p_rec_kandooreport.menupath_text = "AEF"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N
{
			PRINT COLUMN 01, "Product", 
			COLUMN 18, "Product", 
			COLUMN 59, "Sale", 
			COLUMN 67, "Quantity", 
			COLUMN 79, "Stand Unit", 
			COLUMN 97, "Total", 
			COLUMN 107, "Standard", 
			COLUMN 128, "Gross" 
			PRINT COLUMN 01, "Code", 
			COLUMN 18, "Description", 
			COLUMN 59, "Type", 
			COLUMN 69, "Sold", 
			COLUMN 79, "Sell Price", 
			COLUMN 97, "Sales", 
			COLUMN 106, "Unit Cost", 
			COLUMN 127, "Margin" 
}
		WHEN "AEF-DET"
			LET p_rec_kandooreport.header_text = "AEF Item Sales Report - Detail (S1D)"
			LET p_rec_kandooreport.width_num = 132
			LET p_rec_kandooreport.length_num = 66
			LET p_rec_kandooreport.menupath_text = "AEF"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N

{
			PRINT COLUMN 01, "Product", 
			COLUMN 18, "Product", 
			COLUMN 59, "Sale", 
			COLUMN 67, "Quantity", 
			COLUMN 79, "Stand Unit", 
			COLUMN 97, "Total", 
			COLUMN 107, "Standard", 
			COLUMN 128, "Gross" 
			PRINT COLUMN 01, "Code", 
			COLUMN 18, "Description", 
			COLUMN 59, "Type", 
			COLUMN 69, "Sold", 
			COLUMN 79, "Sell Price", 
			COLUMN 97, "Sales", 
			COLUMN 106, "Unit Cost", 
			COLUMN 127, "Margin" 
}
		WHEN "AR1"
			LET p_rec_kandooreport.header_text = "AR Detailed Aging Report"
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.width_num = 132
			LET p_rec_kandooreport.menupath_text = "AR1" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 	
{
			PRINT COLUMN 1, "Date", 
			COLUMN 8, "Trans", 
			COLUMN 15, " Ref", 
			COLUMN 25, glob_rec_arparms.inv_ref2a_text, 
			COLUMN 36, " Days", 
			COLUMN 47, " Total", 
			COLUMN 59, " Unpaid", 
			COLUMN 72, "Current", 
			COLUMN 87, " 1-30", 
			COLUMN 100, "31-60", 
			COLUMN 113, "61-90", 
			COLUMN 124, "90 Plus" 
			PRINT COLUMN 9, "Type", 
			COLUMN 13, "Number", 
			COLUMN 25, glob_rec_arparms.inv_ref2b_text, 
			COLUMN 37, "Late", 
			COLUMN 47, "Amount", 
			COLUMN 60, "Amount", 
			COLUMN 87, " Days", 
			COLUMN 100, " Days", 
			COLUMN 113, " Days", 
			COLUMN 124, " Days" 

}					
		WHEN "AR2"
			LET p_rec_kandooreport.header_text = "AR Summary Aging Report"
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.width_num = 110 #strange value
			LET p_rec_kandooreport.menupath_text = "AR2" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 			

{
			PRINT COLUMN 1, "Date", 
			COLUMN 9, "Trans", 
			COLUMN 18, " Ref", 
			COLUMN 29, glob_rec_arparms.inv_ref2a_text, 
			COLUMN 52, "Invoice", 
			COLUMN 65, " Payment ", 
			COLUMN 79, "Discount", 
			COLUMN 94, "Credited", 
			COLUMN 104, "Posted" 
			PRINT COLUMN 9, "Type", 
			COLUMN 18, "Number", 
			COLUMN 29, glob_rec_arparms.inv_ref2b_text, 
			COLUMN 52, "Amount", 
			COLUMN 66, "Amount", 
			COLUMN 80, "Amount", 
			COLUMN 95, "Amount", 
			COLUMN 104, " (GL)" 
}			
		WHEN "AR3"
			LET p_rec_kandooreport.header_text = "AR Activity Summary Report"
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.width_num = 110 #strange value

			LET p_rec_kandooreport.menupath_text = "AR3" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 			
{
			PRINT COLUMN 1, "Date", 
			COLUMN 9, "Trans", 
			COLUMN 15, " Doc", 
			COLUMN 24, glob_rec_arparms.inv_ref2a_text, 
			COLUMN 48, "Invoice", 
			COLUMN 61, " Payment ", 
			COLUMN 75, "Discount", 
			COLUMN 89, "Credited", 
			COLUMN 98, "Posted", 
			COLUMN 105, "Year", 
			COLUMN 110, "Period" 

			PRINT COLUMN 9, "Type", 
			COLUMN 15, "Number", 
			COLUMN 24, glob_rec_arparms.inv_ref2b_text, 
			COLUMN 48, "Amount", 
			COLUMN 62, "Amount", 
			COLUMN 76, "Amount", 
			COLUMN 90, "Amount" 
}			
		WHEN "AR5"
			LET p_rec_kandooreport.header_text = "AR Cash Forecast Report"
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.width_num = 132
			LET p_rec_kandooreport.menupath_text = "AR5" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 			
{
			PRINT COLUMN 1, "Cust ID", 
			COLUMN 15, "Customer Name", 
			COLUMN 41, "Type", 
			COLUMN 50, "Doc.", 
			COLUMN 57, "Due", 
			COLUMN 67, "Days", 
			COLUMN 75, "Estimated", 
			COLUMN 90, "Estimate", 
			COLUMN 108, "Unpaid", 
			COLUMN 120, "Story" 

			PRINT COLUMN 48, "Number", 
			COLUMN 57, "Date", 
			COLUMN 65, "Till Due", 
			COLUMN 75, "Pay Date", 
			COLUMN 90, "Method", 
			COLUMN 97, "Currency", 
			COLUMN 108, "Amount" 
}						
		WHEN "AR6"
			LET p_rec_kandooreport.header_text = "AR Sales Commission Report"
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.width_num = 80
			LET p_rec_kandooreport.menupath_text = "AR6" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 			
			LET p_rec_kandooreport.line1_text = "Customer    Ref      Date  Period        Amount         Profit     Commission"
			LET p_rec_kandooreport.line2_text = " Code       No."

		WHEN "AR7"
			LET p_rec_kandooreport.header_text = "AR Sales Tax Billed Report"
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.width_num = 128
			LET p_rec_kandooreport.menupath_text = "AR7" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 			
	
{
			PRINT COLUMN 1, "Ref ", 
			COLUMN 11, "Trans", 
			COLUMN 23, "Customer", 
			COLUMN 47, "Currency", 
			COLUMN 65, "Total", 
			COLUMN 76, "Tax", 
			COLUMN 82, "Tax", 
			COLUMN 98, "Taxable", 
			COLUMN 119, "Tax" 
			PRINT COLUMN 1, "Number", 
			COLUMN 11, "Date", 
			COLUMN 23, "Code", 
			COLUMN 33, "Tax Number", 
			COLUMN 49, "Code", 
			COLUMN 65, "Amount", 
			COLUMN 76, "Code", 
			COLUMN 82, "Perc", 
			COLUMN 98, "Amount", 
			COLUMN 119, "Amount"
}
		WHEN "AR8"
			LET p_rec_kandooreport.header_text = "AR Snapshot Report"
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.width_num = 80 #128
			LET p_rec_kandooreport.menupath_text = "AR8" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 			
						
		WHEN "ARA"
			LET p_rec_kandooreport.header_text = "AR Audit Trail Report"
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.width_num = 132
			LET p_rec_kandooreport.menupath_text = "ARA" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 			
			LET p_rec_kandooreport.line1_text = "Customer Type     Reference  Description           Currency         Amount             Sales              Cash           Credits"
						
		WHEN "ARB"
			LET p_rec_kandooreport.header_text = "AR Salesperson Commission Report"
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.width_num = 94			
			LET p_rec_kandooreport.menupath_text = "ARB" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 			
			
		WHEN "ARC"
			LET p_rec_kandooreport.header_text = "AR Period Post Report"
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.width_num = 132			
			LET p_rec_kandooreport.menupath_text = "ARC" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 			
											
		WHEN "ARD"
			LET p_rec_kandooreport.header_text = "AR Customer Summary Aging Report"
			LET p_rec_kandooreport.menupath_text = "ARD" 
			LET p_rec_kandooreport.width_num = 174
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 			
			LET p_rec_kandooreport.line1_text = "Customer           Name                  Balance           Current         1-30 Days        31-60 Days        61-90 Days           90 Plus    Hold"
			LET p_rec_kandooreport.line2_text = "  Code                     Currency                                         Overdue           Overdue           Overdue            Overdue    Sales"

		WHEN "ARR"
			LET p_rec_kandooreport.header_text = "AR Detailed Aging by Reference Report"
			LET p_rec_kandooreport.menupath_text = "ARR" 
			LET p_rec_kandooreport.width_num = 132	
			LET p_rec_kandooreport.length_num = 66
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 			
			LET p_rec_kandooreport.line1_text = "    Date     Invoice   Customer     Days       Total       Unpaid      Current         1-30        31-60        61-90      90 Plus"
			LET p_rec_kandooreport.line2_text = "              Number     Code       Late      Amount       Amount                      Days         Days         Days        Days"
			
		WHEN "ART_J"
			LET p_rec_kandooreport.header_text = "AR Account Aging by Debt Type/Customer Type"																							
			LET p_rec_kandooreport.menupath_text = "ART_J" 
			LET p_rec_kandooreport.width_num = 132		
			LET p_rec_kandooreport.length_num = 66
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 			
			LET p_rec_kandooreport.line1_text = "                                      Days         Unpaid        Current           1-30          31-60          61-90        90 Plus"
			LET p_rec_kandooreport.line2_text = "                                      Late         Amount                          Days           Days           Days          Days"

		WHEN "AS1"
			LET p_rec_kandooreport.header_text = "AS1 - Print Invoices/Credits" 
			LET p_rec_kandooreport.width_num = 80 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "AS1" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
			LET p_rec_kandooreport.line1_text = "" 
			LET p_rec_kandooreport.titleedit_flag = "N" #User must NOT modify report title for invoices 
			
		WHEN "AS2F"
			LET p_rec_kandooreport.header_text = "AS2F - Customer Invoice List" 
			LET p_rec_kandooreport.width_num = 80 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "AS2" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
			LET p_rec_kandooreport.line1_text = "" 

		WHEN "AS2G"
			LET p_rec_kandooreport.header_text = "AS2G - Customers Over Their Credit Limit" 
			LET p_rec_kandooreport.width_num = 80 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "AS2" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
			LET p_rec_kandooreport.line1_text = "" 

		WHEN "AS5"
			LET p_rec_kandooreport.header_text = "Customer Ageing Exception Report" 
			LET p_rec_kandooreport.width_num = 80 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "AS5" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
			LET p_rec_kandooreport.line1_text = "Customer  Name                            Reason" 

		WHEN "AS6"
			LET p_rec_kandooreport.header_text = "AS6 - Print Statements" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66
			LET p_rec_kandooreport.menupath_text = "AS6" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 

		WHEN "AS7" #"jourintf_rpt_list_bd"
			LET p_rec_kandooreport.header_text = "AS7 - Post Period Activity" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "AS7" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 

		WHEN "AS8"
			LET p_rec_kandooreport.header_text = "AS8 - Charge Interest & Service Fee" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "AS8" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
{
			PRINT COLUMN 1,"Code", 
			COLUMN 10,"Name" 
			PRINT COLUMN 10,"Invoice", 
			COLUMN 22,"Service Charge", 
			COLUMN 45,"Balance", 
			COLUMN 60,"Current", 
			COLUMN 75,"1 TO 30", 
			COLUMN 90,"31 TO 60", 
			COLUMN 105,"61 TO 90", 
			COLUMN 120,"90 + days" 
}			
		WHEN "ASA"
			LET p_rec_kandooreport.header_text = "ASA - Mailing Labels" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 6 #label has only 6 lines, no header/footer etc.. 
			LET p_rec_kandooreport.menupath_text = "ASA" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 

		WHEN "ASA_C"
			LET p_rec_kandooreport.header_text = "ASA_C - Mailing Labels" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "ASA_C" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 

		WHEN "ASAa"
			LET p_rec_kandooreport.header_text = "ASAa - Mailing Labels" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "ASAa" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 

		#WHEN "ASB" #Has no report LOL
			
		WHEN "ASD_J"
			LET p_rec_kandooreport.header_text = "Debtor Load - ", today USING "dd/mm/yy" #Debtor Exception Report  
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "ASD" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
			LET p_rec_kandooreport.selection_flag = "N" 
			LET p_rec_kandooreport.line1_text = "glob_rec_kandoouser.cmpy_code Code", 2 spaces, 
					"Customer", 33 spaces, 
					"Type", 4 spaces, 
					"YTD Sales", 3 spaces, 
					"MTD Sales", 2 spaces, 
					"Creditor Controller ID" 

		WHEN "ASD_J-ERROR"
			LET p_rec_kandooreport.header_text = "Debtor Load - ", today USING "dd/mm/yy" #Debtor Exception Report  
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "ASD" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
			LET p_rec_kandooreport.selection_flag = "N" 
			LET p_rec_kandooreport.line1_text = "glob_rec_kandoouser.cmpy_code Code", 2 spaces, 
					"Customer", 33 spaces, 
					"Type", 4 spaces, 
					"YTD Sales", 3 spaces, 
					"MTD Sales", 2 spaces, 
					"Creditor Controller ID" 

		WHEN "ASDIb_J"
			LET p_rec_kandooreport.header_text = "Debtor Exception Report - ", today USING "dd/mm/yy" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "ASD" 
			LET p_rec_kandooreport.selection_flag = "N" 
			LET p_rec_kandooreport.line1_text = "Processing Group", 2 spaces, 
				"Client Code", 14 spaces, 
				"Status" 

		WHEN "ASI_J"
			LET p_rec_kandooreport.header_text = "Invoice Detail Load - ", today USING "dd/mm/yy" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "ASI" 
			LET p_rec_kandooreport.selection_flag = "N" 
			LET p_rec_kandooreport.line1_text = "Company", 2 spaces, 
				"Client Code", 2 spaces, 
				"Customer", 2 spaces, 
				"Corporate Debtor Code", 3 spaces, 
				"Transaction No.", 8 spaces, 
				"Date", 8 spaces, 
				"Total Lines", 9 spaces, 
				"Total Amount" 

		WHEN "ASI_J-ERROR"
			LET p_rec_kandooreport.header_text = "Invoice Detail Exception Report - ",	today USING "dd/mm/yy" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "ASI" 
			LET p_rec_kandooreport.selection_flag = "N" 
			LET p_rec_kandooreport.line1_text = "Processing Group", 2 spaces, 
				"Client Code", 2 spaces, 
				"JMJ Inv.No", 2 spaces, 
				"Status" 
			
		WHEN "ASL"
			#LET p_rec_kandooreport.header_text = "External Invoice Load Exceptions - (Load No:", glob_rec_loadparms.seq_num USING "<<<<<",")"
			LET p_rec_kandooreport.header_text = "External Invoice Load Exceptions" # - (Load No:", glob_rec_loadparms.seq_num USING "<<<<<",")" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "ASL" 
			LET p_rec_kandooreport.selection_flag = "N" 
			LET p_rec_kandooreport.line1_text = "Company", 3 spaces, 
				"Customer", 3 spaces, 
				"Ext.Ref", 3 spaces, 
				"Status" 

		WHEN "ASL-SAW"
			LET p_rec_kandooreport.header_text = "External Invoice Load Summary"
			#LET p_rec_kandooreport.header_text = trim(p_rec_kandooreport.header_text),
			#     " - (Load No:", glob_rec_loadparms.seq_num using "<<<<<",")"		
			LET p_rec_kandooreport.width_num      = 80
			LET p_rec_kandooreport.length_num     = 66
			LET p_rec_kandooreport.menupath_text  = "ASL"
			LET p_rec_kandooreport.selection_flag = "N"
			LET p_rec_kandooreport.line1_text     = "Customer",           4 spaces,
			                                 "Ext. Ref:",          3 spaces,
			                                 "Type",               4 spaces,
			                                 "Tran Number",        8 spaces,
			                                 "Amount"
                                     		

		WHEN "ASL-VOYG"
			LET p_rec_kandooreport.header_text = "Voyager Invoice Load - ", 
			today USING "dd/mm/yy" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "ASL" 
			LET p_rec_kandooreport.selection_flag = "N" 
			LET p_rec_kandooreport.line1_text = "Company" , 5 spaces, 
			"Customer" , 36 spaces, 
			"Invoice No.", 22 spaces, 
			"Date" , 7 spaces, 
			"Total Lines", 9 spaces, 
			"Total Amount" 		


		WHEN "ASL-PROF"
			LET p_rec_kandooreport.header_text = "Invoice Load - ", 
			today USING "dd/mm/yy" 
			#LET p_rec_kandooreport.header_text = "Invoice Load - ", 
			#today USING "dd/mm/yy" 

			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "ASL" 
			LET p_rec_kandooreport.selection_flag = "N" 
			LET p_rec_kandooreport.line1_text = "Company" , 5 spaces, 
			"Customer" , 36 spaces, 
			"Invoice No.", 5 spaces, 
			"Credit No." , 7 spaces, 
			"Date" , 7 spaces, 
			"Total Lines", 9 spaces, 
			"Total Amount" 
	
	{

FUNCTION set2_defaults() 
{
	LET glob_rec_kandooreport.header_text = "Invoice Load - ", 
	today USING "dd/mm/yy" 
	LET glob_rec_kandooreport.width_num = 132 
	LET glob_rec_kandooreport.length_num = 66 
	LET glob_rec_kandooreport.menupath_text = "ASL" 
	LET glob_rec_kandooreport.selection_flag = "N" 
	LET glob_rec_kandooreport.line1_text = "Company" , 5 spaces, 
	"Customer" , 36 spaces, 
	"Invoice No.", 5 spaces, 
	"Credit No." , 7 spaces, 
	"Date" , 7 spaces, 
	"Total Lines", 9 spaces, 
	"Total Amount" 
	UPDATE kandooreport 
	SET * = glob_rec_kandooreport.* 
	WHERE report_code = glob_rec_kandooreport.report_code 
	AND language_code = glob_rec_kandooreport.language_code 

END FUNCTION 

}

		WHEN "ASL-KAO"

			LET p_rec_kandooreport.header_text = "Invoice Load - LBS TO database - ", 
			today USING "dd/mm/yy" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "ASL" 
			LET p_rec_kandooreport.selection_flag = "N" 
			LET p_rec_kandooreport.line1_text = "Company" , 5 spaces, 
			"Customer" , 36 spaces, 
			"Invoice No.", 5 spaces, 
			"Credit No." , 7 spaces, 
			"Date" , 7 spaces, 
			"Total Lines", 9 spaces, 
			"Total Amount" 
		
		
		WHEN "ASU"
			LET p_rec_kandooreport.header_text = "AR Transaction Purging Report"
			LET p_rec_kandooreport.width_num = 132
			LET p_rec_kandooreport.length_num = 66
			LET p_rec_kandooreport.menupath_text = "ASU"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N
			LET p_rec_kandooreport.line1_text = "Customer                                                  Deleted Transactions                                Summary Transactions"
			LET p_rec_kandooreport.line2_text = "                                             -----------------------------------------------              --------------------------"
			LET p_rec_kandooreport.line3_text = "                                             Invoice    Credit      Cash   Araudit     Total              Invoice    Credit     Cash"

		WHEN "ASU."
			LET p_rec_kandooreport.header_text = "AR Transaction Purging ERROR Report"
			LET p_rec_kandooreport.width_num = 132
			LET p_rec_kandooreport.length_num = 66
			LET p_rec_kandooreport.menupath_text = "ASU"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N
			LET p_rec_kandooreport.line1_text = "Customer                                         Reason"

		WHEN "ASV"
			LET p_rec_kandooreport.header_text = "ACCOUNTS RECEIVABLE VERIFY"
			LET p_rec_kandooreport.width_num = 132
			LET p_rec_kandooreport.length_num = 66
			LET p_rec_kandooreport.menupath_text = "ASV"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N


		#ASW_rpt_1_exception_list
		WHEN "ASW1" #Note: There are 2 reports using the same configuration in the original code
			LET p_rec_kandooreport.header_text = "AR Invoice/Receipt Load Exception Report - ", today USING "dd/mm/yy" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "ASW" 
			LET p_rec_kandooreport.selection_flag= "N" 
			LET p_rec_kandooreport.line1_text = "WHICS", 14 spaces, "Tran" 
			LET p_rec_kandooreport.line2_text = "glob_rec_kandoouser.cmpy_code", 1 spaces, 
				"Date", 10 spaces, 
				"Type", 2 spaces, 
				"Status" 		

		#ASW_rpt_2_list
		WHEN "ASW2" #Note: There are 2 reports using the same configuration in the original code
			LET p_rec_kandooreport.header_text = "AR Invoice/Receipt Load - ", 
			today USING "dd/mm/yyyy" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "ASW" 
			LET p_rec_kandooreport.selection_flag = "N" 
			LET p_rec_kandooreport.line1_text = "Company", 2 spaces, 
			"Customer", 2 spaces, 
			"Tran. Date", 2 spaces, 
			"Invoice No.", 4 spaces, 
			"Receipt No.", 18 spaces, 
			"Inv.Lines", 7 spaces, 
			"Debit Amount", 6 spaces, 
			"Credit Amount" 

		WHEN "AW3"
			LET p_rec_kandooreport.header_text = "AW3 - Tentative Balance Write Off Report"
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "AW3" 
			LET p_rec_kandooreport.selection_flag = "N" 
			LET p_rec_kandooreport.line1_text = "Sales Exception Report"
{
			PRINT COLUMN 8,"Customer", 
			COLUMN 18,"Name", 
			COLUMN 68, "----- Write Off -----", 
			COLUMN 96,"Customer", 
			COLUMN 107,"Days Since" 
			PRINT COLUMN 68 ,"Credit", 
			COLUMN 84,"Debit", 
			COLUMN 96,"Balance", 
			COLUMN 108,"Activity" 
}				
		WHEN "AW4"
			LET p_rec_kandooreport.header_text = "AW4 - Customer Balance Write Off" #Customer Balance Write Off
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "AW4" 
			LET p_rec_kandooreport.selection_flag = "N" 
			LET p_rec_kandooreport.line1_text = "Customer Balance Write Off"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N

		WHEN "ASY_J"
			LET p_rec_kandooreport.header_text = "ASY_J - Credit Note Report Listing " #Customer Balance Write Off
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "ASY_J" 
			LET p_rec_kandooreport.selection_flag = "N" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N
{
			PRINT COLUMN 01, "Credit ", 
			COLUMN 14, "Credit ", 
			COLUMN 26, "Credit ", 
			COLUMN 40, "Invoice", 
			COLUMN 50, "Invoice", 
			COLUMN 60, "Debt", 
			COLUMN 69, "Invoice", 
			COLUMN 99, "Applied" 

			PRINT COLUMN 02, "Date", 
			COLUMN 15, "Number", 
			COLUMN 24, "Year/Period", 
			COLUMN 41, "Date", 
			COLUMN 51, "Number", 
			COLUMN 60, "Type", 
			COLUMN 67, "Year/Period", 
			COLUMN 100, "Amount" 
}

		WHEN "ASZ_J"
			LET p_rec_kandooreport.header_text = "ASY_J - Proposed Payment Date and Interest Rate " #Customer Balance Write Off
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "ASZ_J" 
			LET p_rec_kandooreport.selection_flag = "N" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N


{
			PRINT COLUMN 01, "Receipt", 
			COLUMN 14, "Receipt", 
			COLUMN 26, "Receipt", 
			COLUMN 40, "Invoice", 
			COLUMN 50, "Invoice", 
			COLUMN 60, "Debt", 
			COLUMN 69, "Invoice", 
			COLUMN 81, "Number", 
			COLUMN 99, "Applied", 
			COLUMN 110, "Interest" 

			PRINT COLUMN 02, "Date", 
			COLUMN 15, "Number", 
			COLUMN 24, "Year/Period", 
			COLUMN 41, "Date", 
			COLUMN 51, "Number", 
			COLUMN 60, "Type", 
			COLUMN 67, "Year/Period", 
			COLUMN 81, "of Days", 
			COLUMN 100, "Amount", 
			COLUMN 109, "Calculated" 

}
		WHEN "AZ3" #Error report - only shown if error happened
			LET p_rec_kandooreport.header_text = "AZ3 - Salesperson Maintenance - Exception Report"
			LET p_rec_kandooreport.width_num = 80 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "AZ3" 
			LET p_rec_kandooreport.selection_flag = "N" 
			LET p_rec_kandooreport.line1_text = "Sales Exception Report"
{
			PRINT COLUMN 01, today USING "dd/mm/yyyy", 46 spaces, "Sales Exception Report", 45 spaces, "Page: ",p_page_no USING "##&" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 01,"Customer Reason" 
			
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]
}

		OTHERWISE
			LET p_rec_kandooreport.header_text = "MISSING IN DEFAULT TEMPLATES"

	END CASE

	RETURN p_rec_kandooreport.* 		 
END FUNCTION 