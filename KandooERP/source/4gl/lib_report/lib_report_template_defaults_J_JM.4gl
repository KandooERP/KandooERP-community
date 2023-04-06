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
FUNCTION rpt_set_kandooreport_defaults_J_JM(p_rec_kandooreport)
	DEFINE p_rec_kandooreport RECORD LIKE kandooreport.*
	

	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	
	CASE upshift(p_rec_kandooreport.report_code)


		######################################################################
		# JM - Job Management
		#
		######################################################################

		WHEN "J33"
			LET p_rec_kandooreport.header_text = "J33 - Invoice Print" 
			LET p_rec_kandooreport.width_num = 80 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "J33" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 

		WHEN "J34"
			LET p_rec_kandooreport.header_text = "J34 - Pre Invoice Report" 
			LET p_rec_kandooreport.width_num = 100 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "J34" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 

		WHEN "J3C"
			LET p_rec_kandooreport.header_text = "J3C - JM Pre Bill Report" 
			LET p_rec_kandooreport.width_num = 100 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "J3C" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 

			LET p_rec_kandooreport.bottom_margin = 0
			LET p_rec_kandooreport.left_margin = 0
			LET p_rec_kandooreport.top_margin = 5
			--LET p_rec_kandooreport.page_length = 66
			LET p_rec_kandooreport.right_margin	= 100

		WHEN "J4A"
			LET p_rec_kandooreport.header_text = "J4A - Completed Activity Status Report " 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "J4A" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N

		WHEN "J7A-SUC"
			LET p_rec_kandooreport.header_text = "J4A - Completed Activity Status Report " 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "J7A" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N

		WHEN "J7A-ERR"
			LET p_rec_kandooreport.header_text = "J4A - Completed Activity Status Report " 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "J7A" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N


		WHEN "J91"
			LET p_rec_kandooreport.header_text = "J91 - JM Product Issue Report" 
			LET p_rec_kandooreport.width_num = 80 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "J91" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N
			LET p_rec_kandooreport.line1_text = "Job Management Product Issue"

		WHEN "JA5"
			LET p_rec_kandooreport.header_text = "Contract Listing " 
			LET p_rec_kandooreport.width_num = 80 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "JA5" 
			LET p_rec_kandooreport.selection_flag = "Y" 

		WHEN "JA6"
			LET p_rec_kandooreport.header_text = "Job Management Tentative Invoices" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "JA5" 
			LET p_rec_kandooreport.selection_flag = "Y" 

		WHEN "JA8" #huho: so strange, code refered to Kandooreport "WR1"
			LET p_rec_kandooreport.header_text = "Tentative Invoice Report " 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "JA8" 
			LET p_rec_kandooreport.selection_flag = "Y" 
			LET p_rec_kandooreport.line1_text = "Invoice No Item Description Quantity Unit Price Extended Price" 
							
		WHEN "JR1"
			LET p_rec_kandooreport.header_text = "JM Activity Transaction Report " 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "JR1" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 

		WHEN "JR2"
			LET p_rec_kandooreport.header_text = "JM Costing Report " 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "JR2" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 

		WHEN "JR3"
			LET p_rec_kandooreport.header_text = "JM Costing Report " 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "JR3" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 

		WHEN "JR4"
			LET p_rec_kandooreport.header_text = "Job Management Resource Report" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "JR4" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
			
		WHEN "JR5"
			LET p_rec_kandooreport.header_text = "Job Revenue AND Cost Analysis Report" #
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "JR5" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
			LET p_rec_kandooreport.line1_text = NULL 

		WHEN "JR6"
			LET p_rec_kandooreport.header_text = "JM Timesheets by Person" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "JR6" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
																							#123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012
			LET p_rec_kandooreport.line1_text =  "Time    Person                         Department                              Task Period         Period Ending" 
			LET p_rec_kandooreport.line2_text =  "    Posted   Task Date       Job    Client                 Varn. Activity Resource Quantity       Charge   Activity Title & comment" 

		WHEN "JR8"
			LET p_rec_kandooreport.header_text = "JM Hours by Department" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "JR8" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
																					#123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012
			LET p_rec_kandooreport.line1_text =	"Department    Person" 
			LET p_rec_kandooreport.line2_text =	"  Period End       Task Date                Job           Varn. Activity           Hours    Activity Title & comment" 

		WHEN "JR9"
			LET p_rec_kandooreport.header_text = "JM Resource Allocation Report" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "JR9" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 

		WHEN "JRA"
			LET p_rec_kandooreport.header_text = "JR Job Summary" 
			LET p_rec_kandooreport.width_num = 131 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "JRA" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 


		WHEN "JRB"
			LET p_rec_kandooreport.header_text = "Contract Status Report" 
			LET p_rec_kandooreport.width_num = 143 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "JRB" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 

		WHEN "JRC"
			LET p_rec_kandooreport.header_text = "JM Activity Transaction Report" 
			LET p_rec_kandooreport.width_num = 112 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "JRC" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 

		WHEN "JRD"
			LET p_rec_kandooreport.header_text = "Job Type Report" 
			LET p_rec_kandooreport.width_num = 80 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "JRD" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
			

		WHEN "JRE-SUM"
			LET p_rec_kandooreport.header_text = "JRE - Summary Job Report" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "JRE" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 


		WHEN "JRE-FULL"
			LET p_rec_kandooreport.header_text = "JRE - Full Job Report" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "JRE" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
			

		WHEN "JRF"
			LET p_rec_kandooreport.header_text = "JM WIP Reconciliation Report" 
			LET p_rec_kandooreport.width_num = 80 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "JRF" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 

		WHEN "JRG"
			LET p_rec_kandooreport.header_text = "JM Pre-Invoice Summary Report" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "JRG" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
			
		WHEN "JRH"
			LET p_rec_kandooreport.header_text = "Detailed Resource Reconciliation Report" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "JRH" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
																						#123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012
			LET p_rec_kandooreport.line1_text = "Date       Transact       Cost         Charge      Billed        Cost        Billed       Billed     Comments" 
			LET p_rec_kandooreport.line2_text = " Amount Amount Amount Quantity Quantity Cost of Sales" 

		WHEN "JRI"
			LET p_rec_kandooreport.header_text = "JM Costing Report" #JRI - Job Cost Material/Labour Report  
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "JRI" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
																						#123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012
			LET p_rec_kandooreport.line1_text ="Job      Description    Invoiced             Labour            Materials            Other               Total         Gross      GP" 
			LET p_rec_kandooreport.line2_text ="Code                     Amount           Cost   %             Cost   %          Cost      %            Cost          Profit     %"

		WHEN "JRL"
			LET p_rec_kandooreport.header_text = "JR Master List"   
			LET p_rec_kandooreport.width_num = 60 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "JRL" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 


		WHEN "JRM"
			LET p_rec_kandooreport.header_text = "JM Cost Transaction Report " 
			LET p_rec_kandooreport.width_num = 145 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "JRM" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 

		WHEN "JRN"
			LET p_rec_kandooreport.header_text = "Job Accrual Report " 
			LET p_rec_kandooreport.width_num = 121 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "JRN" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 

		WHEN "JRO"
			LET p_rec_kandooreport.header_text = "Job Cost Worksheet " 
			LET p_rec_kandooreport.width_num = 150 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "JRO" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 

		WHEN "JRQ"
		   LET p_rec_kandooreport.header_text = "JM Hours by Department"
		   LET p_rec_kandooreport.width_num = 132
		   LET p_rec_kandooreport.length_num = 66
		   LET p_rec_kandooreport.menupath_text = "JR8"
		   LET p_rec_kandooreport.exec_ind = "1"
		   LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N
																						#123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012
		   LET p_rec_kandooreport.line1_text = "Department    Person"
		   LET p_rec_kandooreport.line2_text = "  Period End       Task Date                Job           Varn. Activity           Hours    Activity Title & comment"

		WHEN "JRR"
			LET p_rec_kandooreport.header_text = "JM Missing/Incomplete Timesheets by Person" #Department Person Problem T/S Day Hours
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "JRR" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
			LET p_rec_kandooreport.line1_text = "Department                             Person                        Problem                T/S    Day                 Hours" 
			LET p_rec_kandooreport.line2_text = NULL 
																					#123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012

		WHEN "JRS"
			LET p_rec_kandooreport.header_text = "JM Chargeable Hours by Person" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "JRS" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
			LET p_rec_kandooreport.line1_text = NULL 
			LET p_rec_kandooreport.line2_text = NULL 
			#123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012

		WHEN "JS1"
			LET p_rec_kandooreport.header_text = "AP Posting Report"
			LET p_rec_kandooreport.width_num = 132
			LET p_rec_kandooreport.length_num = 66
			LET p_rec_kandooreport.menupath_text = "JS1"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N

		WHEN "JS4"

			LET p_rec_kandooreport.header_text = "JS4 - Print Invoices/Credits"
			LET p_rec_kandooreport.width_num = 188 #132
			LET p_rec_kandooreport.length_num = 55 #66
			LET p_rec_kandooreport.menupath_text = "JS1"
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N
			LET p_rec_kandooreport.bottom_margin = 10
			
			LET p_rec_kandooreport.left_margin = 0
			LET p_rec_kandooreport.top_margin = 10
			--LET p_rec_kandooreport.page_length = 33
			--LET p_rec_kandooreport.right_margin	= 80
		OTHERWISE
			LET p_rec_kandooreport.header_text = "MISSING IN DEFAULT TEMPLATES"

	END CASE

	RETURN p_rec_kandooreport.* 		 
END FUNCTION 