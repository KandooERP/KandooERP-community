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
FUNCTION rpt_set_kandooreport_defaults_F_FA(p_rec_kandooreport)
	DEFINE p_rec_kandooreport RECORD LIKE kandooreport.*
	

	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	
	CASE upshift(p_rec_kandooreport.report_code)

		WHEN "F61"
			LET p_rec_kandooreport.header_text = "FA Asset Register" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "F61" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
			#1234567890123456789012345678901234567890
			LET p_rec_kandooreport.line1_text = "" 

		WHEN "F62"
			LET p_rec_kandooreport.header_text = "FA Asset Additions" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "F62" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
			#1234567890123456789012345678901234567890
			LET p_rec_kandooreport.line1_text = "" 


		WHEN "F63"
			LET p_rec_kandooreport.header_text = "FA Asset Disposals" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "F63" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
			#1234567890123456789012345678901234567890
			LET p_rec_kandooreport.line1_text = "" 

		WHEN "F64"
			LET p_rec_kandooreport.header_text = "FA Asset Transactions" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "F64" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
			#1234567890123456789012345678901234567890
			LET p_rec_kandooreport.line1_text = "" 


		WHEN "F65"
			LET p_rec_kandooreport.header_text = "FA Category Master" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "F65" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
			#1234567890123456789012345678901234567890
			LET p_rec_kandooreport.line1_text = "" 


		WHEN "F67"
			LET p_rec_kandooreport.header_text = "FA Authority Report" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "F67" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
			#1234567890123456789012345678901234567890
			LET p_rec_kandooreport.line1_text = "" 

		WHEN "F6D"
			LET p_rec_kandooreport.header_text = "FA Asset Depreciation Reconciliation" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "F6D" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
			#1234567890123456789012345678901234567890
			LET p_rec_kandooreport.line1_text = "" 

		WHEN "F81"
			LET p_rec_kandooreport.header_text = "FA Asset Listing" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "F81" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
			#1234567890123456789012345678901234567890
			LET p_rec_kandooreport.line1_text = "" 

		WHEN "F82"
			LET p_rec_kandooreport.header_text = "FA Insurance Listing" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "F82" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
			#1234567890123456789012345678901234567890
			LET p_rec_kandooreport.line1_text = "" 			

		WHEN "F83"
			LET p_rec_kandooreport.header_text = "FA Lease Listing" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "F83" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
			#1234567890123456789012345678901234567890
			LET p_rec_kandooreport.line1_text = "" 	
							
		WHEN "F84"
			LET p_rec_kandooreport.header_text = "FA Asset Summary Report" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "F84" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
			#1234567890123456789012345678901234567890
			LET p_rec_kandooreport.line1_text = "" 	
							
		WHEN "FB1"
			LET p_rec_kandooreport.header_text = "FA Batch Detail" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "FB1" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
			#1234567890123456789012345678901234567890
			LET p_rec_kandooreport.line1_text = "" 	

		WHEN "FGL-BDT"
			LET p_rec_kandooreport.header_text = "FA - GL Batch Prep" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "FGL" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
			#1234567890123456789012345678901234567890
			LET p_rec_kandooreport.line1_text = "" 	

		WHEN "FGL-AUDIT"
			LET p_rec_kandooreport.header_text = "FA - GL Batch Audit" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "FGL" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
			#1234567890123456789012345678901234567890
			LET p_rec_kandooreport.line1_text = "" 	

		WHEN "FL2"
			LET p_rec_kandooreport.header_text = "FA Stock Location" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "FL2" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
			#1234567890123456789012345678901234567890
			LET p_rec_kandooreport.line1_text = "" 	

		WHEN "FP1"
			LET p_rec_kandooreport.header_text = "FA Posting Audit Trail" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "FP1" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
			#1234567890123456789012345678901234567890
			LET p_rec_kandooreport.line1_text = "" 	

		WHEN "FP2-STATUS"
			LET p_rec_kandooreport.header_text = "FA Depreciation Status" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "FP2" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
			#1234567890123456789012345678901234567890
			LET p_rec_kandooreport.line1_text = "" 	

		WHEN "FP2-CALC"
			LET p_rec_kandooreport.header_text = "Fixed Assets Depreciation Calculation" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "FP2" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
			#1234567890123456789012345678901234567890
			LET p_rec_kandooreport.line1_text = "" 	

		WHEN "FP2-AUDIT"
			LET p_rec_kandooreport.header_text = "FA - Depreciation Audit" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "FP2" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
			#1234567890123456789012345678901234567890
			LET p_rec_kandooreport.line1_text = "" 	
									
		OTHERWISE
			LET p_rec_kandooreport.header_text = "MISSING IN DEFAULT TEMPLATES"

	END CASE

	RETURN p_rec_kandooreport.* 		 
END FUNCTION 