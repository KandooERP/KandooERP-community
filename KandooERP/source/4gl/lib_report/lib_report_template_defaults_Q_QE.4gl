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
FUNCTION rpt_set_kandooreport_defaults_Q_QE(p_rec_kandooreport)
	DEFINE p_rec_kandooreport RECORD LIKE kandooreport.*
	

	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	
	CASE upshift(p_rec_kandooreport.report_code)

		######################################################################
		# Q - Quotation System
		#
		######################################################################
		WHEN "QA1"
			LET p_rec_kandooreport.header_text = "Quotation By Customer" 
			LET p_rec_kandooreport.width_num = 80 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "QA1" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N
			CALL fgl_winmessage("Kandooreport Template needs adjusting","Kandooreport QA1","error")
			#LET p_rec_kandooreport.line1_text = " Quote   ",pr_arparms.inv_ref2a_text,"                Date     Valid                Quotation  Status"
			#LET p_rec_kandooreport.line2_text = " Number  ",pr_arparms.inv_ref2b_text,"                         Until                  Amount"
						#IMPORANT TO DO
			# @needs fixing and adding -> pr_arparms	
 
			-- #1234567890                            901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012
			LET p_rec_kandooreport.line1_text = " Quote " 
			LET p_rec_kandooreport.line2_text = " Date Valid Quotation Status" 

			#LET p_rec_kandooreport.line1_text = " Quote ",pr_arparms.inv_ref2a_text," Date Valid Quotation Status" 

			-- #1234567890                            901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012
			LET p_rec_kandooreport.line3_text = " Number " 
			LET p_rec_kandooreport.line4_text = " Until Amount"
			#LET p_rec_kandooreport.line2_text = " Number ",pr_arparms.inv_ref2b_text," Until Amount" 

		WHEN "QA5"
			LET p_rec_kandooreport.header_text = "Quotation Detail Line" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "QA5" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N #Supports background (none-ui) process Y/N 
																					#123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012
			LET p_rec_kandooreport.line1_text = "Line   Product       Description                                    Quoted   Reserved  Unit   Unit Price         Extended" 
			LET p_rec_kandooreport.line2_text = "   #   Code                                                       Quantity   Quantity                               Price" 

		WHEN "QA8"
			LET p_rec_kandooreport.header_text = "QE Quotation # "  #"QE - Quotation Documents" 
			LET p_rec_kandooreport.width_num = 77 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "QA5" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
																					#123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012
			LET p_rec_kandooreport.line1_text = "Line   Product       Description                                    Quoted   Reserved  Unit   Unit Price         Extended" 
			LET p_rec_kandooreport.line2_text = "   #   Code                                                       Quantity   Quantity                               Price" 


#	left margin 1 
#	PAGE length 60 
#	top margin 0 
#	bottom margin 0 
	
		WHEN "QA8-OUT"
			LET p_rec_kandooreport.header_text = "Quotation Detail Line" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "QA5" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" #Supports background (none-ui) process Y/N 
																					#123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012
			LET p_rec_kandooreport.line1_text = "Line   Product       Description                                    Quoted   Reserved  Unit   Unit Price         Extended" 
			LET p_rec_kandooreport.line2_text = "   #   Code                                                       Quantity   Quantity                               Price" 
#	PAGE length 15 
#	right margin 60 
#	top margin 1 
#	bottom margin 1 


		OTHERWISE
			LET p_rec_kandooreport.header_text = "MISSING IN DEFAULT TEMPLATES"

	END CASE

	RETURN p_rec_kandooreport.* 		 
END FUNCTION 