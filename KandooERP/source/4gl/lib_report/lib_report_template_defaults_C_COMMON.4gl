############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl" 

#####################################################################
# FUNCTION rpt_set_kandooreport_defaults_c_common(p_rec_kandooreport)
#
# Set the default report parameters
# RETURN p_rec_kandooreport.*
#####################################################################
FUNCTION rpt_set_kandooreport_defaults_c_common(p_rec_kandooreport)
	DEFINE p_rec_kandooreport RECORD LIKE kandooreport.*
	
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	
	CASE upshift(p_rec_kandooreport.report_code)

		#AR Accounts Receivable	

		######################################################################
		#  
		#
		######################################################################

		WHEN "CJOURPRINT"		
			LET p_rec_kandooreport.header_text = "Subsidiary Ledger Period Posting Report" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "ARC" #AR - Accounts Receivable
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "N" 

		WHEN "CJOURPRINT"		
			LET p_rec_kandooreport.header_text = "Subsidiary Ledger Period Posting Report" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "PR6" #AR - Accounts Receivable
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "N" 

		WHEN "CJOURPRINT"		
			LET p_rec_kandooreport.header_text = "Subsidiary Ledger Period Posting Report" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "IR8" #AR - Accounts Receivable
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "N" 			
{
			IF p_type = "FULL" THEN 
				PRINT 
				COLUMN 1, "Jour", 
				COLUMN 6, "Description", 
				COLUMN 22, "Source", 
				COLUMN 31, "Source", 
				COLUMN 40, "Curr", 
				COLUMN 47, "Exch", 
				COLUMN 54, "---------Base Currency--------", 
				COLUMN 87, "-------Foreign Currency-------", 
				COLUMN 119, "Post", 
				COLUMN 127, "Trans" 

				PRINT 
				COLUMN 1, "Code", 
				COLUMN 22, "Text", 
				COLUMN 33, "Num", 
				COLUMN 40, "Code", 
				COLUMN 47, "Rate", 
				COLUMN 61, "Debit", 
				COLUMN 78, "Credit", 
				COLUMN 95, "Debit", 
				COLUMN 111, "Credit", 
				COLUMN 119, "(?)", 
				COLUMN 128, "Date" 
			ELSE 
				PRINT 
				COLUMN 1, "Jour", 
				COLUMN 10, "Source", 
				COLUMN 21, "Source", 
				COLUMN 33,"----------Base Currency---------", 
				COLUMN 70, "Post" 

				PRINT 
				COLUMN 1, "Code", 
				COLUMN 10, "Text", 
				COLUMN 23, "Num", 
				COLUMN 42, "Debit", 
				COLUMN 59, "Credit", 
				COLUMN 71, "(?)" 
			END IF 

}
		WHEN "CPOST-REPORT-2"		
			LET p_rec_kandooreport.header_text = "Subsidiary Ledger Period Posting Report" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "GCW" #GC - Cash Book
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "N" 		


		OTHERWISE
			LET p_rec_kandooreport.header_text = "MISSING IN DEFAULT TEMPLATES"

	END CASE

	RETURN p_rec_kandooreport.* 		 
END FUNCTION 