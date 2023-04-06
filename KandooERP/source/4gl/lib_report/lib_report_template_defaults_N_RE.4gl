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
FUNCTION rpt_set_kandooreport_defaults_N_RE(p_rec_kandooreport)
	DEFINE p_rec_kandooreport RECORD LIKE kandooreport.*
	

	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	
	CASE upshift(p_rec_kandooreport.report_code)

		WHEN "N11"
			LET p_rec_kandooreport.header_text = "Requistions Load Exception Report" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "N11"
			LET p_rec_kandooreport.selection_flag= "N" 
			LET p_rec_kandooreport.line1_text = "Date Time Comments" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "N" 

		WHEN "N21"
			LET p_rec_kandooreport.header_text = "RE Picking Slip Generation" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "N21"
			LET p_rec_kandooreport.selection_flag= "N" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "N" 
			LET p_rec_kandooreport.line1_text = "P-I-C-K-I-N-G L-I-S-T"	

		WHEN "N32"
			LET p_rec_kandooreport.header_text = "RE Requisition Product Back Order Allocation Report" 
			LET p_rec_kandooreport.width_num = 100 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "N21"
			LET p_rec_kandooreport.selection_flag= "N" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "N" 
			LET p_rec_kandooreport.left_margin = 0
			LET p_rec_kandooreport.top_margin = 0
			--LET p_rec_kandooreport.page_length = 66
			LET p_rec_kandooreport.right_margin	= 100

		WHEN "N4R"
			LET p_rec_kandooreport.header_text = "RE Pending Purchase Order Report" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "N21"
			LET p_rec_kandooreport.selection_flag= "N" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "N" 
			LET p_rec_kandooreport.left_margin = 0
			LET p_rec_kandooreport.top_margin = 0
			--LET p_rec_kandooreport.page_length = 66
			LET p_rec_kandooreport.right_margin	= 100
			LET p_rec_kandooreport.line1_text = "** All monetary VALUES are in base currency **"			
			
		WHEN "NS1"
			LET p_rec_kandooreport.header_text = "RE Purchase Orders" 
			LET p_rec_kandooreport.width_num = 80 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "NS1"
			LET p_rec_kandooreport.selection_flag= "N" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "N" 
			LET p_rec_kandooreport.left_margin = 0
			LET p_rec_kandooreport.top_margin = 0
			--LET p_rec_kandooreport.page_length = 66
			LET p_rec_kandooreport.right_margin	= 80			
			#	bottom margin 0 

		WHEN "NPR"
			LET p_rec_kandooreport.header_text = "Requisition Person Details Report" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "NPR"
			LET p_rec_kandooreport.selection_flag= "N" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "N" 
			LET p_rec_kandooreport.left_margin = 0
			LET p_rec_kandooreport.top_margin = 0
			--LET p_rec_kandooreport.page_length = 66
			LET p_rec_kandooreport.right_margin	= 132
			LET p_rec_kandooreport.line1_text = ""			

		WHEN "NR1"
			LET p_rec_kandooreport.header_text = "RE Requisitions By Person" 
			LET p_rec_kandooreport.width_num = 84 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "NR1"
			LET p_rec_kandooreport.selection_flag= "N" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "N" 
			LET p_rec_kandooreport.left_margin = 0
			LET p_rec_kandooreport.top_margin = 0
			--LET p_rec_kandooreport.page_length = 66
			LET p_rec_kandooreport.right_margin	= 84
			LET p_rec_kandooreport.line1_text = ""					

		WHEN "NR2"
			LET p_rec_kandooreport.header_text = "RE Requisition Details By Line" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "NR3"
			LET p_rec_kandooreport.selection_flag= "N" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "N" 
			LET p_rec_kandooreport.left_margin = 0
			LET p_rec_kandooreport.top_margin = 0
			--LET p_rec_kandooreport.page_length = 66
			LET p_rec_kandooreport.right_margin	= 132
			LET p_rec_kandooreport.line1_text = ""	
			
		WHEN "NR3"
			LET p_rec_kandooreport.header_text = "RE Requisitions History By Product" 
			LET p_rec_kandooreport.width_num = 100 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "NR3"
			LET p_rec_kandooreport.selection_flag= "N" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "N" 
			LET p_rec_kandooreport.left_margin = 0
			LET p_rec_kandooreport.top_margin = 0
			--LET p_rec_kandooreport.page_length = 66
			LET p_rec_kandooreport.right_margin	= 100
			LET p_rec_kandooreport.line1_text = ""	

		WHEN "NR4"
			LET p_rec_kandooreport.header_text = "RE Requisition Back Order Detail List" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "NR4"
			LET p_rec_kandooreport.selection_flag= "N" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "N" 
			LET p_rec_kandooreport.left_margin = 0
			LET p_rec_kandooreport.top_margin = 0
			--LET p_rec_kandooreport.page_length = 66
			LET p_rec_kandooreport.right_margin	= 100
			LET p_rec_kandooreport.line1_text = ""	

		WHEN "NR5"
			LET p_rec_kandooreport.header_text = "" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "NR5"
			LET p_rec_kandooreport.selection_flag= "N" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "N" 
			LET p_rec_kandooreport.left_margin = 0
			LET p_rec_kandooreport.top_margin = 0
			--LET p_rec_kandooreport.page_length = 66
			LET p_rec_kandooreport.right_margin	= 100
			LET p_rec_kandooreport.line1_text = ""							
		OTHERWISE
			LET p_rec_kandooreport.header_text = "MISSING IN DEFAULT TEMPLATES"

	END CASE

	RETURN p_rec_kandooreport.* 		 
END FUNCTION 