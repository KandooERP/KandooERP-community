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
FUNCTION rpt_set_kandooreport_defaults_G_GL(p_rec_kandooreport)
	DEFINE p_rec_kandooreport RECORD LIKE kandooreport.*
	

	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	
	CASE upshift(p_rec_kandooreport.report_code)


		######################################################################
		# GL General Ledger 
		#
		######################################################################

		WHEN "G27"
			LET p_rec_kandooreport.header_text ="Error Exception Report - External Batch Load" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "G27" 
			LET p_rec_kandooreport.selection_flag = "N" 
			LET p_rec_kandooreport.line1_text = 
						" Line",3 spaces, 
						"Tran Date",2 space, 
						"Account Code",11 spaces, 
						"Debit Amount",4 spaces, 
						"Credit Amount",3 spaces, 
						"Error Description" 

		WHEN "G32"
			LET p_rec_kandooreport.header_text = "Disbursement Journal Posting Report" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "G32" 
			LET p_rec_kandooreport.exec_flag  = "N"			
			LET p_rec_kandooreport.selection_flag = "N" 
			LET p_rec_kandooreport.line1_text = 60 spaces, "------- Base Currency ------ ------ Batch Currency ------" 
			LET p_rec_kandooreport.line2_text = 	"Seq Type Account Description Debit Amt Credit Amt Debit Amt Credit Amt Exchange"


		WHEN "G33"
			LET p_rec_kandooreport.header_text = "Journal Disbursement Report" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "G33" 
			LET p_rec_kandooreport.selection_flag = "Y" 
			LET p_rec_kandooreport.line1_text = "Disbursement Journal ", 
				"-- Last Journal Generated --", 
				" Type Account Description", 
				" Quantity Analysis" 
			LET p_rec_kandooreport.line2_text = " ", 	" Batch Date Year/Period" 

		WHEN "GA1"
			LET p_rec_kandooreport.header_text = "GA1 - Account versus Budget Report" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "GA1" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
{
			PRINT COLUMN 1, "Year", 
			COLUMN 18, "Beginning", 
			COLUMN 33, "Year TO Date", 
			COLUMN 53, "Year TO Date", 
			COLUMN 73, "Year TO Date", 
			COLUMN 95, "Year Budget" 

			PRINT COLUMN 18, " Balance", 
			COLUMN 33, " Debits", 
			COLUMN 53, " Credits", 
			COLUMN 73, "Pre-Closing", 
			COLUMN 95, "Number: ", glob_budg_num USING "<<<<" 	
}
		WHEN "GA2"
			LET p_rec_kandooreport.header_text = "GA2 - Account Period Summary Report" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "GA2" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
{
			PRINT COLUMN 1, "Year", 
			COLUMN 12, "Beginning", 
			COLUMN 32, " Period", 
			COLUMN 52, " Period", 
			COLUMN 72, " Ending", 
			COLUMN 92, "Pre-Closing" 
			PRINT COLUMN 5, "Period", 
			COLUMN 12, " Balance", 
			COLUMN 32, " Debits", 
			COLUMN 52, " Credits", 
			COLUMN 72, " Balance", 
			COLUMN 92, "Balance" 
}			
		WHEN "GA3"
			LET p_rec_kandooreport.header_text = "Account Detail Report" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "GA3" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
			LET p_rec_kandooreport.line1_text = "Jour Batch    Description                             Debits           Credits       Quantity      Source    Source  Analysis"
			LET p_rec_kandooreport.line2_text = "Code  Num                                                                                                    Number"


		WHEN "GA4"
			LET p_rec_kandooreport.header_text = "Financial Work Sheet Report" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "GA4" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
			LET p_rec_kandooreport.line1_text = "         Account         Type   Description                                Debits            Credits"
{
			CASE modu_report_type 
				WHEN "1" 
					LET l_header_text_text = "Report Type ", 
					modu_report_type, " : Closing balances FOR" 
				WHEN "2" 
					LET l_header_text_text = "Report Type ", 
					modu_report_type, " : Year TO date totals FOR" 
				OTHERWISE 
					LET l_header_text_text = "Invalid Report Type : ", modu_report_type 
			END CASE 
			PRINT COLUMN 01, l_header_text_text clipped," ", 
			modu_year_num USING "<<<<", "/", 
			modu_period_num USING "<<<<" 
}

		WHEN "GA5"
			LET p_rec_kandooreport.header_text = "Financial Work Sheet Report" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "GA5" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N
			LET p_rec_kandooreport.line1_text = "Budget Variance Report"
			{
			PRINT COLUMN 1, "Year", 
			COLUMN 10, " ------------------ This Period ------------------------ ", 
			COLUMN 72, " ------------------ Year TO Date ----------------------- " 

			PRINT COLUMN 5, "Period", 
			COLUMN 14, "Actual", 
			COLUMN 34, "Budget ", glob_budg_num USING "<<<<", 
			COLUMN 54, "Variance", 
			COLUMN 74, "Actual", 
			COLUMN 94, " Budget ", glob_budg_num USING "<<<<", 
			COLUMN 114, "Variance" 
}

		WHEN "GA6"
			LET p_rec_kandooreport.header_text = "Financial Work Sheet Report" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "GA6" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N
			LET p_rec_kandooreport.line1_text = "Available Funds Report"
{
			PRINT COLUMN 1, "Account", 
			COLUMN 20, "Description", 
			COLUMN 42, "Year", 
			COLUMN 55, "Budget ", glob_budg_num USING "<<<<", 
			COLUMN 74, "Actual", 
			COLUMN 88, "Committed", 
			COLUMN 106, "Expended", 
			COLUMN 122, "Available" 
}			

		WHEN "GA7"
			LET p_rec_kandooreport.header_text = "GA7 - Budget Percentage Report" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "GA7" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N
			LET p_rec_kandooreport.line1_text = "Budget Percentage Report"	
			LET p_rec_kandooreport.line2_text = "GL Budget Percentage"

{
			PRINT COLUMN 1, "Year", 
			COLUMN 10, " ------------------ This Period ------------------------ ", 
			COLUMN 72, " ------------------ Year TO Date ----------------------- " 

			PRINT COLUMN 5, "Period", 
			COLUMN 14, "Actual", 
			COLUMN 34, "Budget ", glob_budg_num USING "<<<<", 
			COLUMN 54, "% of Budget", 
			COLUMN 74, "Actual", 
			COLUMN 94, " Budget ", glob_budg_num USING "<<<<", 
			COLUMN 114, "% of Budget" 
}		

		WHEN "GA8"
			LET p_rec_kandooreport.header_text = "GA8 - Available Funds Report" #Available Funds Report (Menu GA8) - Year 
			LET p_rec_kandooreport.width_num = 110 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "GA8" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N
{
			PRINT COLUMN 1, "Account", 
			COLUMN 17, "Description", 
			COLUMN 35, "Budget ", glob_budg_num USING "<<<<", 
			COLUMN 49, "Actual", 
			COLUMN 61, "Actual", 
			COLUMN 70, "Committed", 
			COLUMN 83, "Total", 
			COLUMN 94, "% of", 
			COLUMN 101, "Available" 
			PRINT COLUMN 49, "M T D ", 
			COLUMN 61, "Y T D", 
			COLUMN 83, "Expended ", 
			COLUMN 94, "Budget" 

}
						
		WHEN "GA9"
			LET p_rec_kandooreport.header_text = "GA9 - Budget 1-4 Worksheet Report" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "GA9" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N

{
			PRINT COLUMN 4, " -------- Budget", 
			COLUMN 20, " One ---------- ", 
			COLUMN 36, " -------- Budget", 
			COLUMN 52, " Two ---------- ", 
			COLUMN 68, " -------- Budget", 
			COLUMN 84, " Three -------- ", 
			COLUMN 100, " -------- Budget", 
			COLUMN 116, " Four ---------" 
			PRINT COLUMN 4, " Period ", 
			COLUMN 20, " Year TO Date ", 
			COLUMN 36, " Period ", 
			COLUMN 52, " Year TO Date ", 
			COLUMN 68, " Period ", 
			COLUMN 84, " Year TO Date ", 
			COLUMN 100, " Period ", 
			COLUMN 116, " Year TO Date" 
}

		WHEN "GA9-F" #Full Report
			LET p_rec_kandooreport.header_text = "GA9 - Budget 5-6 Worksheet Report" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "GA9" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N
{
			PRINT COLUMN 36, " -------- Budget", 
			COLUMN 52, " Five --------- ", 
			COLUMN 68, " -------- Budget", 
			COLUMN 84, " Six ---------- " 
			PRINT COLUMN 36, " Period ", 
			COLUMN 52, " Year TO Date ", 
			COLUMN 68, " Period ", 
			COLUMN 84, " Year TO Date " 

}			
		WHEN "GAA"
			LET p_rec_kandooreport.header_text = "GAA - Ledger Detail by Reference" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "GA9" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N
{
			PRINT COLUMN 1, "Jour", 
			COLUMN 6, "Batch", 
			COLUMN 20, "Description", 
			COLUMN 53, " Debit", 
			COLUMN 73, " Credits", 
			COLUMN 95, "Source", 
			COLUMN 108, "Source " 
			PRINT COLUMN 1, "Code", 
			COLUMN 6, " Num", 
			COLUMN 108, "Number" 

}			

		WHEN "GAC"
			LET p_rec_kandooreport.header_text = "GAC - GL Budget Worksheet" #GL Budget Worksheet
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "GA9" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N
{
			PRINT COLUMN 10, "Starting Period: ", glob_speriod USING "##", 
			COLUMN 50, "Budget : ", modu_budget_name_text, 
			COLUMN 90, "Ending Period: ", glob_eperiod USING "##" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

			PRINT COLUMN 3, "Period", 
			COLUMN 12, "Period", 
			COLUMN 21, "Period", 
			COLUMN 30, "Period", 
			COLUMN 39, "Period", 
			COLUMN 48, "Period", 
			COLUMN 57, "Period", 
			COLUMN 66, "Period", 
			COLUMN 75, "Period", 
			COLUMN 84, "Period", 
			COLUMN 93, "Period", 
			COLUMN 102, "Period", 
			COLUMN 111, "Period", 
			COLUMN 120, "Total" 

			PRINT COLUMN 3, " One", 
			COLUMN 12, "Two", 
			COLUMN 21, "Three", 
			COLUMN 30, " Four", 
			COLUMN 39, " Five", 
			COLUMN 48, " Six", 
			COLUMN 57, "Seven", 
			COLUMN 66, "Eight", 
			COLUMN 75, " Nine", 
			COLUMN 84, " Ten", 
			COLUMN 93, "Eleven", 
			COLUMN 102, "Twelve", 
			COLUMN 111, "Thirteen", 
			COLUMN 120, "Account" 
}			
		WHEN "GAG"
			LET p_rec_kandooreport.header_text = "Ledger Detail by Chart Code" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "GAG" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 

{
			PRINT COLUMN 1, "Jour", 
			COLUMN 6, "Batch", 
			COLUMN 20, "Description", 
			COLUMN 53, " Debit", 
			COLUMN 73, " Credits", 
			COLUMN 95, "Source", 
			COLUMN 108, "Source " 
			PRINT COLUMN 1, "Code", 
			COLUMN 6, " Num", 
			COLUMN 108, "Number" 
}
		WHEN "GAH"
			LET p_rec_kandooreport.header_text = "Account Detail by Journal Code" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "GAH" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
{
			PRINT COLUMN 1, "Jour", 
			COLUMN 6, "Batch", 
			COLUMN 13, "Description", 
			COLUMN 55, "Debits", 
			COLUMN 72, "Credits", 
			COLUMN 82, "Tran", 
			COLUMN 91, "Tran", 
			COLUMN 99, "Source", 
			COLUMN 110, "Source " , 
			COLUMN 115, "Analysis" 
			PRINT COLUMN 1, "Code", 
			COLUMN 6, " Num", 
			COLUMN 82, "Type", 
			COLUMN 91, "Date", 
			COLUMN 110, "Number" 

}

		WHEN "GAI"
			LET p_rec_kandooreport.header_text = "Account Reference Detail" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "GAI" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
			LET p_rec_kandooreport.line1_text = "Jour Batch  Description                          Debits           Credits  Tran   Tran   Source   Source   Source   Analysis"
			LET p_rec_kandooreport.line2_text = "Code  Num                                                                  Type   Date            Number    Ref"

		WHEN "GAJ"
			LET p_rec_kandooreport.header_text = "Account History by Journal Code" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "GAJ" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
{
			PRINT COLUMN 1, "Jour", 
			COLUMN 6, "Batch", 
			COLUMN 13, "Description", 
			COLUMN 55, "Debits", 
			COLUMN 72, "Credits", 
			COLUMN 82, "Tran", 
			COLUMN 91, "Tran", 
			COLUMN 99, "Source", 
			COLUMN 110, "Source " , 
			COLUMN 115, "Analysis" 
			PRINT COLUMN 1, "Code", 
			COLUMN 6, " Num", 
			COLUMN 82, "Type", 
			COLUMN 91, "Date", 
			COLUMN 110, "Number" 
}

		WHEN "GB1"
			LET p_rec_kandooreport.header_text = "GL Journal Batches" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "GB1" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N
{
			PRINT COLUMN 01, "Batch", 
			COLUMN 09, "Entry", 
			COLUMN 19, "Entry", 
			COLUMN 27, "Year", 
			COLUMN 43, "Control", 
			COLUMN 56, "Total Base", 
			COLUMN 69, "Total Foreign", 
			COLUMN 83, "Cur.", 
			COLUMN 91, "Control", 
			COLUMN 111, "Post Post" 
			PRINT COLUMN 01, "Number", 
			COLUMN 09, "Person", 
			COLUMN 20, "Date ", 
			COLUMN 30, "Period", 
			COLUMN 44, "Amount", 
			COLUMN 57, "Currency", 
			COLUMN 73, "Currency", 
			COLUMN 83, "Code", 
			COLUMN 90, "Quantity", 
			COLUMN 101,"Quantity", 
			COLUMN 113, "? Run No" 
}
		WHEN "GB2"
			LET p_rec_kandooreport.header_text = "GL Journals by Batch" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "GB2" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N
{
			PRINT COLUMN 01, "Batch", 
			COLUMN 10, "Jour", 
			COLUMN 19, "Entry", 
			COLUMN 29, "Year", 
			COLUMN 49, "Total Base", 
			COLUMN 71, "Total Foreign", 
			COLUMN 85, "Currency", 
			COLUMN 95, "Posted Post Run" 
			PRINT COLUMN 01, "Number", 
			COLUMN 10, "Code", 
			COLUMN 18, " Date ", 
			COLUMN 33, "Period", 
			COLUMN 50, "Currency", 
			COLUMN 74, "Currency", 
			COLUMN 87, "Code", 
			COLUMN 95, " ? Number" 
}
		WHEN "GB3"
			LET p_rec_kandooreport.header_text = "GL Journal by Entry Date" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "GB3" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N
{
			PRINT COLUMN 01, "Entry", 
			COLUMN 10, "Entry", 
			COLUMN 19, "Journal", 
			COLUMN 27, "Batch", 
			COLUMN 34, "Year", 
			COLUMN 55, "Total Base", 
			COLUMN 73, "Total Foreign", 
			COLUMN 87, "Currency", 
			COLUMN 96, "Posted", 
			COLUMN 103, "Post Run" 
			PRINT COLUMN 01, "Date", 
			COLUMN 10, "Person", 
			COLUMN 27, "Number", 
			COLUMN 39, "Period", 
			COLUMN 56, "Currency", 
			COLUMN 76, "Currency", 
			COLUMN 89, "Code", 
			COLUMN 96, " ?", 
			COLUMN 104, "Number" 
}			
		WHEN "GB4"
			LET p_rec_kandooreport.header_text = "Batch Details" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "GB4" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N
			LET p_rec_kandooreport.line1_text = "Batch Details - amounts in Foreign modu_currency"
			LET p_rec_kandooreport.line2_text = "Batch Details - amounts in Base modu_currency"							
{
			PRINT COLUMN 1, "Seq", 
			COLUMN 6, "Type", 
			COLUMN 15, "Account", 
			COLUMN 34, "Description", 
			COLUMN 65, "Quantity", 
			COLUMN 79, "Analysis", 
			COLUMN 105, "Debit", 
			COLUMN 124, "Credit" 
 
}

		WHEN "GB5"
			LET p_rec_kandooreport.header_text = "Batch modu_currency Details" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "GB5" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N
{
			PRINT COLUMN 2, "Seq", 
			COLUMN 7, "Type", 
			COLUMN 14, "Account", 
			COLUMN 46, "Curr", 
			COLUMN 52, "Exch", 
			COLUMN 57, "-------------BASE VALUES-------------", 
			COLUMN 95, "-----------FOREIGN VALUES------------" 
			PRINT COLUMN 14, "Description", 
			COLUMN 46, "Code", 
			COLUMN 52, "Rate", 
			COLUMN 70, "Debit", 
			COLUMN 88, "Credit", 
			COLUMN 108, "Debit", 
			COLUMN 126, "Credit" 
}			

		WHEN "GB6"
			LET p_rec_kandooreport.header_text = "Batch Details by Account" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "GB6" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N
{
			PRINT COLUMN 1, "Jour", 
			COLUMN 8, "Batch", 
			COLUMN 15, "Year", 
			COLUMN 24, "Type", 
			COLUMN 30, "Account", 
			COLUMN 60, "Description", 
			COLUMN 85, "Debit", 
			COLUMN 110, "Credit" 
			PRINT COLUMN 1, "Code", 
			COLUMN 18, "Period" 
}

		WHEN "GB7"
			LET p_rec_kandooreport.header_text = "Post Run Report" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "GB7" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N
{
			PRINT COLUMN 10, "Batch", 
			COLUMN 18, "Year", 
			COLUMN 34, "Total Debits", 
			COLUMN 55, "Total Credits " 
			PRINT COLUMN 10, "Number", 
			COLUMN 22, "Period" 
}			

		WHEN "GB8"
			LET p_rec_kandooreport.header_text = "Trial Multi-Ledger Posting" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "GB8" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N

{
			PRINT COLUMN 002,"Seq", 
			COLUMN 007,"Type", 
			COLUMN 014,"Account", 
			COLUMN 046,"Curr", 
			COLUMN 052,"Exch", 
			COLUMN 058,"------------ BASE VALUES ------------", 
			COLUMN 096,"---------- FOREIGN VALUES -----------" 
			PRINT COLUMN 014,"Description", 
			COLUMN 046,"Code", 
			COLUMN 052,"Rate", 
			COLUMN 070,"Debit", 
			COLUMN 088,"Credit", 
			COLUMN 108,"Debit", 
			COLUMN 126,"Credit" 
}

		WHEN "GBQ"
			LET p_rec_kandooreport.header_text = "AR General Ledger Drill Down" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "GBQ" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
			LET p_rec_kandooreport.line1_text[2,4] = "Seq" 
			LET p_rec_kandooreport.line1_text[6,9] = "Type" 
			LET p_rec_kandooreport.line1_text[11,17] = "Account" 
			LET p_rec_kandooreport.line1_text[30,40] = "Description" 
			LET p_rec_kandooreport.line1_text[73,85] = "Base Currency" 
			LET p_rec_kandooreport.line1_text[101,118] = "Source Transaction" 
			LET p_rec_kandooreport.line2_text[70,74] = "Debit" 
			LET p_rec_kandooreport.line2_text[84,89] = "Credit" 
			LET p_rec_kandooreport.line2_text[99,104] = "Number" 
			LET p_rec_kandooreport.line2_text[114,121] = "Customer" 

		WHEN "GC5"
			LET p_rec_kandooreport.header_text = "Bank Account Reconciliation report" 
			LET p_rec_kandooreport.width_num = 80 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "GC5" 
			LET p_rec_kandooreport.selection_flag = "Y" 
			LET p_rec_kandooreport.line1_text =	"- Date -- Trans No.--- Reference Information --------------",	"------ Debit-Credit -" 

		WHEN "GC9"
			LET p_rec_kandooreport.header_text = "Bank Statement Report" 
			LET p_rec_kandooreport.width_num = 110 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "GC9" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N
			LET p_rec_kandooreport.line1_text = "Seq  Date    Trans   Ref   Description                              Debit          Credit         Balance" 
			LET p_rec_kandooreport.line2_text = "Num          Type    Num" 

		WHEN "GCA"
			LET p_rec_kandooreport.header_text = "Detailed Reconciliation Report" 
			LET p_rec_kandooreport.width_num = 80 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "GCA" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 

		WHEN "GCL-A"
			LET p_rec_kandooreport.header_text = "Statement Load Audit Trail" 
			LET p_rec_kandooreport.width_num = 80 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "GCL" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 

		WHEN "GCL-B"
			LET p_rec_kandooreport.header_text = "Statement Load Audit Trail" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "GCL" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 

		WHEN "GCL-C"
			LET p_rec_kandooreport.header_text = "Statement Load Audit Trail" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "GCL" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 


		WHEN "GCP"
			LET p_rec_kandooreport.header_text = "Bank Statement print" 
			LET p_rec_kandooreport.width_num = 80 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "GCP" 
			LET p_rec_kandooreport.exec_ind = "1" 
			
		WHEN "GCW"
			LET p_rec_kandooreport.header_text = "WHICS-OPEN GL Load Exception Report - (Menu gcw)" 
			LET p_rec_kandooreport.width_num = 80 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "GCW" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
			#LET p_rec_kandooreport.line1_text = "Jour Batch Description Debits Credits Tran Tran Source Source Source Analysis" 
			#LET p_rec_kandooreport.line2_text = "Code Num Type Date Number Ref" 
{
			PRINT COLUMN 01, "Time", 
			COLUMN 11, "Comments" 
}

		WHEN "GP6"
			LET p_rec_kandooreport.header_text = "Period END Reconciliation" 
			LET p_rec_kandooreport.width_num = 182 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "GP6" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N

		WHEN "GGR"
			LET p_rec_kandooreport.header_text = "GL Segment Detail Report (Menu-GGR)" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "GR1" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N
			LET p_rec_kandooreport.line2_text = " GL Segment Detail Report (Menu-GGR)" 
			LET p_rec_kandooreport.line3_text  = " GL Segment Summary Report (Menu-GGR)" 
			LET p_rec_kandooreport.line4_text  = " GL Summary Report by Total Code (Menu-GGR)"

{
			PRINT COLUMN 01, "Description", 
			COLUMN 36, modu_arr_column[1].desc_text, 
			COLUMN 51, modu_arr_column[2].desc_text, 
			COLUMN 66, modu_arr_column[3].desc_text, 
			COLUMN 81, modu_arr_column[4].desc_text, 
			COLUMN 96, modu_arr_column[5].desc_text, 
			COLUMN 111, modu_arr_column[6].desc_text, 
			COLUMN 126, modu_arr_column[7].desc_text, 
			COLUMN 139, modu_arr_column[8].desc_text, 
			COLUMN 156, modu_arr_column[9].desc_text, 
			COLUMN 175, "Total" 

}
		WHEN "GGR-2"
			LET p_rec_kandooreport.header_text = "GL Segment Summary Report (Menu-GGR)" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "GR1" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N
			LET p_rec_kandooreport.line2_text = " GL Segment Detail Report (Menu-GGR)" 
			LET p_rec_kandooreport.line3_text  = " GL Segment Summary Report (Menu-GGR)" 
			LET p_rec_kandooreport.line4_text  = " GL Summary Report by Total Code (Menu-GGR)"
{
			PRINT COLUMN 01, "Description", 
			COLUMN 36, modu_arr_column[1].desc_text, 
			COLUMN 51, modu_arr_column[2].desc_text, 
			COLUMN 66, modu_arr_column[3].desc_text, 
			COLUMN 81, modu_arr_column[4].desc_text, 
			COLUMN 96, modu_arr_column[5].desc_text, 
			COLUMN 111, modu_arr_column[6].desc_text, 
			COLUMN 126, modu_arr_column[7].desc_text, 
			COLUMN 139, modu_arr_column[8].desc_text, 
			COLUMN 156, modu_arr_column[9].desc_text, 
			COLUMN 175, "Total" 
}
		WHEN "GGR-3"
			LET p_rec_kandooreport.header_text = "GL Summary Report by Total Code " 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "GR1" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N
			LET p_rec_kandooreport.line2_text = " GL Segment Detail Report (Menu-GGR)" 
			LET p_rec_kandooreport.line3_text  = " GL Segment Summary Report (Menu-GGR)" 
			LET p_rec_kandooreport.line4_text  = " GL Summary Report by Total Code (Menu-GGR)"

			{
			PRINT COLUMN 01, "Description", 
			COLUMN 36, modu_arr_column[1].desc_text, 
			COLUMN 51, modu_arr_column[2].desc_text, 
			COLUMN 66, modu_arr_column[3].desc_text, 
			COLUMN 81, modu_arr_column[4].desc_text, 
			COLUMN 96, modu_arr_column[5].desc_text, 
			COLUMN 111, modu_arr_column[6].desc_text, 
			COLUMN 126, modu_arr_column[7].desc_text, 
			COLUMN 139, modu_arr_column[8].desc_text, 
			COLUMN 156, modu_arr_column[9].desc_text, 
			COLUMN 175, "Total" 
}



		WHEN "GR1"
			LET p_rec_kandooreport.header_text = "GR1 - Chart of Accounts Report" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "GR1" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N

{
			PRINT COLUMN 1, "Account", 
			COLUMN 20, "Description", 
			COLUMN 64, "Start", 
			COLUMN 76, "End", 
			COLUMN 83, "Org.", 
			COLUMN 90, "Type" , 
			COLUMN 96, "Qty", 
			COLUMN 102, "Analysis Prompt" 
			PRINT COLUMN 61, "Year", 
			COLUMN 66, "Per.", 
			COLUMN 71, "Year", 
			COLUMN 76, "Per.", 
			COLUMN 96, "UOM" 
}			

		WHEN "GR2"
			LET p_rec_kandooreport.header_text = "GL Report Instructions" 
			LET p_rec_kandooreport.width_num = 118 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "GR2" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N
{
			PRINT COLUMN 1, "Line", 
			COLUMN 8, "Column", 
			COLUMN 17, "Sign", 
			COLUMN 24, "Label", 
			COLUMN 42, "Segment", 
			COLUMN 66, "Begin", 
			COLUMN 86, " End", 
			COLUMN 105, "Drop", 
			COLUMN 115, "Save" 

			PRINT COLUMN 13, "Command", 
			COLUMN 66, "Account", 
			COLUMN 86, "Account", 
			COLUMN 104, "Lines" , 
			COLUMN 115, " In " 
}

		WHEN "GR3"
			LET p_rec_kandooreport.header_text = "Valid Segment Codes" 
			LET p_rec_kandooreport.width_num = 80 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "GR3" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N
{
			PRINT COLUMN 1, "Code", 
			COLUMN 20, "Description" 
}

		WHEN "GR4"
			LET p_rec_kandooreport.header_text = "GR4 - Journal Codes List" 
			LET p_rec_kandooreport.width_num = 80 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "GR4" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N

{
			PRINT COLUMN 1, "Code", 
			COLUMN 20, "Description", 
			COLUMN 55, "GL Journal" 
}

		WHEN "GR9"
			LET p_rec_kandooreport.header_text = "Group Codes" 
			LET p_rec_kandooreport.width_num = 80 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "GR9" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N

		WHEN "GRA"
			LET p_rec_kandooreport.header_text = "GRA - Trial Balance Report" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "GRA" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N			

		WHEN "GRC"
			LET p_rec_kandooreport.header_text = "GRC - Accounts Receivable Reconciliation Report" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "GRC" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N			
{
			PRINT 
			COLUMN 1, "Year", 
			COLUMN 6, "Period", 
			COLUMN 23, "Invoices", 
			COLUMN 40, "Credits", 
			COLUMN 50, "Cash Receipts", 
			COLUMN 70, "Discounts", 
			COLUMN 87, "Exchange", 
			COLUMN 102, "Net Value", 
			COLUMN 116, "Action Required" 

			PRINT 
			COLUMN 87, "Variance" 

}						

		WHEN "GRD"
			LET p_rec_kandooreport.header_text = "GRD - Subsidiary Reconciliation Report" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "GRD" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N	
{
			PRINT COLUMN 01, "All VALUES in base currency ", 18 spaces

			PRINT 
			COLUMN 1, "Year", 
			COLUMN 6, "Period", 
			COLUMN 23, "Vouchers", 
			COLUMN 41, "Debits", 
			COLUMN 57, "Cheques", 
			COLUMN 70, "Discounts", 
			COLUMN 87, "Realised", 
			COLUMN 102, "Net Value", 
			COLUMN 116, "Action Required" 

			PRINT 
			COLUMN 87, "Exchange" 
			PRINT 
			COLUMN 87, "Variance" 

}

		WHEN "GRF"
			LET p_rec_kandooreport.header_text = "GRF - Trial Balance - Pre-Close Report" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "GRF" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N	

		WHEN "GRF-CURR"
			LET p_rec_kandooreport.header_text = "GRF - Trial Balance (Multi Currency) - Pre-Close Report" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "GRF" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N	
{
			PRINT COLUMN 1, "Account", 
			COLUMN 72, "Opening", 
			COLUMN 91, "Period", 
			COLUMN 109, "Period", 
			COLUMN 127, "Ending" 
			PRINT COLUMN 1, "Number", 
			COLUMN 20, "Description", 
			COLUMN 72, "Balance", 
			COLUMN 91, "Debits", 
			COLUMN 108, "Credits", 
			COLUMN 126, "Balance" 

}			

		WHEN "GRG"
			LET p_rec_kandooreport.header_text = "GL Summary Trial Balance" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "GRG" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N	

		WHEN "GRH-D"
			LET p_rec_kandooreport.header_text = "GL Unrealised Exchange Variances - Detail" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "GRH" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N	
{
			PRINT COLUMN 01, "Potential Unrealised Exchange Rate Losses/Gains"

			PRINT COLUMN 1, "Account", 
			COLUMN 21, "Description", 
			COLUMN 53, "Currency", 
			COLUMN 75, "Current", 
			COLUMN 97, "l_potential" 
			PRINT COLUMN 1, "Number", 
			COLUMN 53, "Balances", 
			COLUMN 75, "l_base Value", 
			COLUMN 97, "l_base Value", 
			COLUMN 121, "l_variance" 
}
		WHEN "GRH-S"
			LET p_rec_kandooreport.header_text = "GL Unrealised Exchange Variances - Summary" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "GRH" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N	
{
			PRINT COLUMN 1, "Currency", 
			COLUMN 35, "Exchange", 
			COLUMN 53, "Currency", 
			COLUMN 75, "Current", 
			COLUMN 97, "l_potential" 
			PRINT COLUMN 1, "Code", 
			COLUMN 7, "Description", 
			COLUMN 35, "Rate Used", 
			COLUMN 53, "Balances", 
			COLUMN 75, "l_base Value", 
			COLUMN 97, "l_base Value", 
			COLUMN 121, "l_variance" 
}

		WHEN "GRI"
			LET p_rec_kandooreport.header_text = "GRI - Multi-Ledger Relationships List" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "GRI" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N	
{
			PRINT COLUMN 01,"Ledger", 
			COLUMN 20,"Description", 
			COLUMN 61,"Account", 
			COLUMN 80,"Description" 
}

		WHEN "GRJ"
			LET p_rec_kandooreport.header_text = "GRJ - Consolidated Reporting Codes" 
			LET p_rec_kandooreport.width_num = 80 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "GRJ" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N
{
			PRINT COLUMN 01,"Consol Code", 
			COLUMN 20,"Description" 
}

		WHEN "GRK-SC"
			LET p_rec_kandooreport.header_text = "GRK - Consolidated Summary Trial Balance" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "GRK" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N

		WHEN "GRK-MC"
			LET p_rec_kandooreport.header_text = "GRK - Consolidated Summary Trial Balance" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "GRK" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N

{
			PRINT COLUMN 01, "Account", 
			COLUMN 40, "Year", 
			COLUMN 45, l_period_head, 
			COLUMN 59, "Opening", 
			COLUMN 75, l_todate_head, 
			COLUMN 94, l_todate_head, 
			COLUMN 118,"Ending" 
			PRINT COLUMN 01, "Number", 
			COLUMN 15, "Name", 
			COLUMN 59, "Balance", 
			COLUMN 78, "Debits", 
			COLUMN 98,"Credits", 
			COLUMN 118,"Balance" 

}
			
		WHEN "GRL"
			LET p_rec_kandooreport.header_text = "Approved Funds Account" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "GRL" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
			LET p_rec_kandooreport.line1_text = "  Account   Limit   Purchase Orders      Vouchers     Debit Notes        Journals        Consumed       Available  Active  Complete"

		#GS1_rpt_list_finance
		WHEN "GS1" 
			LET p_rec_kandooreport.header_text = "Finance Report" 
			LET p_rec_kandooreport.width_num = 80 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "GS1" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
 
		WHEN "GSJ"
			LET p_rec_kandooreport.header_text = "Approved Funds Account" 
			LET p_rec_kandooreport.width_num = 100 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "GSJ" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "N" 
{
			PRINT COLUMN 03,"Account Code", 
			COLUMN 22,"Description", 
			COLUMN 62,"Budget Total", 
			COLUMN 87,"File Total" 

}

		WHEN "GSJ-EXP"
			LET p_rec_kandooreport.header_text = "Approved Funds Account - Export" 
			LET p_rec_kandooreport.width_num = 100 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "GSJ" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 

#		WHEN "GSJ"
#			LET p_rec_kandooreport.header_text = "Budget Import Report" #"Approved Funds Account" 
#			LET p_rec_kandooreport.width_num = 100 
#			LET p_rec_kandooreport.length_num = 66 
#			LET p_rec_kandooreport.menupath_text = "GSJ" 
#			LET p_rec_kandooreport.exec_ind = "1" 
#			LET p_rec_kandooreport.exec_flag = "N" 

		WHEN "GSP"
			LET p_rec_kandooreport.header_text = "Micropay Payroll Load (GSP) - Exception Report" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "GSP" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "N" 
			
		WHEN "GST"
			LET p_rec_kandooreport.header_text = "GST - Consolidating batches TO another machine" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "GST" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
			
						
		WHEN "GW1"
			LET p_rec_kandooreport.header_text = "GST - Consolidating batches TO another machine" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "GST" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 

		WHEN "GW5" #this module may get's dropped
			LET p_rec_kandooreport.header_text = "GL Reportwriter Header Definitions" 
			LET p_rec_kandooreport.width_num = 128 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "GST" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
			LET p_rec_kandooreport.line1_text = "Management Report Writer Report Definitions"

			
		OTHERWISE
			LET p_rec_kandooreport.header_text = "MISSING IN DEFAULT TEMPLATES"

	END CASE

	RETURN p_rec_kandooreport.* 		 
END FUNCTION 