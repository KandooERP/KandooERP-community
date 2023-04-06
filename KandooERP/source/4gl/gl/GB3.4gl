###########################################################################
# This program IS free software; you can redistribute it AND/OR modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 2 of the License, OR (at your
# option) any later version.
#
# This program IS distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License FOR more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; IF NOT, write TO the Free Software Foundation, Inc.,
# 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
#
###########################################################################
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 
GLOBALS "../gl/GB_globals.4gl" 
############################################################
# MODULE Scope Variables
############################################################
############################################################
# FUNCTION GB3_main()
#
# GB3  Batches By Entry Date
############################################################
FUNCTION GB3_main() 
	DEFER QUIT 
	DEFER INTERRUPT 
	
	CALL setModuleId("GB3")

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 	
			OPEN WINDOW G109 with FORM "G109" 
			CALL windecoration_g("G109") 
		
			MENU " Batch by Entry Date" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","GB3","menu-batch-by-date") 
					CALL GB3_rpt_process(GB3_rpt_query())
		
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
		
				ON ACTION "Report" 	#COMMAND "Run" " SELECT criteria AND PRINT REPORT"
					CALL GB3_rpt_process(GB3_rpt_query()) 
		
				ON ACTION "Print Manager" 				#COMMAND KEY ("P",f11) "Print" "Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "Exit" #COMMAND KEY(interrupt,"E")"Exit" " RETURN TO menus"
					EXIT MENU 
		
			END MENU 
		
			CLOSE WINDOW G109 
	 
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL GB3_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW G109 with FORM "G109" 
			CALL windecoration_g("G109") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(GB3_rpt_query()) #save where clause in env 
			CLOSE WINDOW G109 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL GB3_rpt_process(get_url_sel_text())
	END CASE 	
END FUNCTION 


############################################################
# FUNCTION GB3_rpt_query()
#
#
############################################################
FUNCTION GB3_rpt_query()
	DEFINE l_where_text STRING 


	MESSAGE kandoomsg2("U",1001,"") #1001 Enter Selection Criteria - ESC TO Continue "
	CONSTRUCT BY NAME l_where_text ON batchhead.jour_code, 
	batchhead.jour_num, 
	batchhead.year_num, 
	batchhead.period_num, 
	batchhead.post_flag, 
	batchhead.currency_code, 
	batchhead.rate_type_ind, 
	batchhead.conv_qty, 
	batchhead.control_qty, 
	batchhead.control_amt, 
	batchhead.stats_qty, 
	batchhead.for_debit_amt, 
	batchhead.for_credit_amt, 
	batchhead.com1_text, 
	batchhead.com2_text, 
	batchhead.entry_code, 
	batchhead.jour_date 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","GB3","construct-batchhead") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
			
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 
	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL
	ELSE
		RETURN l_where_text
	END IF 
END FUNCTION 


#####################################################################
# FUNCTION GB3_rpt_process(p_where_text) 
#
#
#####################################################################
FUNCTION GB3_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT  
	DEFINE l_rec_batchhead RECORD LIKE batchhead.* 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"GB3_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT GB3_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0
	LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GB3_rpt_list")].sel_text
	#------------------------------------------------------------

	
	LET l_query_text = "SELECT * FROM batchhead ", 
	"WHERE batchhead.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND ", glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GB3_rpt_list")].sel_text clipped, " ", 
	"ORDER BY batchhead.jour_date" 
	PREPARE choice FROM l_query_text 
	DECLARE selcurs CURSOR FOR choice 

	FOREACH selcurs INTO l_rec_batchhead.* 
		#---------------------------------------------------------
		OUTPUT TO REPORT GB3_rpt_list(l_rpt_idx,l_rec_batchhead.*)  
		IF NOT rpt_int_flag_handler2("Batch:",l_rec_batchhead.jour_num , NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------		

	END FOREACH 
	#------------------------------------------------------------
	FINISH REPORT GB3_rpt_list
	CALL rpt_finish("GB3_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 


############################################################
# REPORT gb3_list(p_rpt_idx,p_rec_batchhead)
#
#
############################################################
REPORT gb3_list(p_rpt_idx,p_rec_batchhead)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx] 
	DEFINE p_rec_batchhead RECORD LIKE batchhead.*
	DEFINE l_error_message CHAR(55)
	DEFINE l_temp_text CHAR(115)
	DEFINE l_cmpy_head CHAR(132) 
	DEFINE i SMALLINT 
	DEFINE l_col2 SMALLINT 
	DEFINE l_col SMALLINT 

	OUTPUT 
	left margin 0 
	ORDER external BY p_rec_batchhead.jour_date 
	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

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
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]
			
		ON EVERY ROW 
			IF p_rec_batchhead.for_debit_amt != p_rec_batchhead.for_credit_amt THEN 
				LET l_error_message = "* BATCH UNBALANCED *" 
			ELSE 
				LET l_error_message = " " 
			END IF 
			IF p_rec_batchhead.currency_code = glob_rec_glparms.base_currency_code THEN 
				LET p_rec_batchhead.currency_code = "" 
			END IF 
			PRINT COLUMN 1, p_rec_batchhead.jour_date USING "dd/mm/yy", 
			COLUMN 10, p_rec_batchhead.entry_code, 
			COLUMN 19, p_rec_batchhead.jour_code, 
			COLUMN 23, p_rec_batchhead.jour_num USING "########", 
			COLUMN 34, p_rec_batchhead.year_num USING "####", 
			COLUMN 39, p_rec_batchhead.period_num USING "###", 
			COLUMN 44, p_rec_batchhead.debit_amt USING "--,---,---,---,--&.&&", 
			COLUMN 63, p_rec_batchhead.for_debit_amt USING "--,---,---,---,--&.&&", 
			COLUMN 89, p_rec_batchhead.currency_code, 
			COLUMN 98, p_rec_batchhead.post_flag, 
			COLUMN 103, p_rec_batchhead.post_run_num USING "#######", 
			COLUMN 111, l_error_message 
			
		ON LAST ROW 
			SKIP 1 line 
			PRINT COLUMN 1, "Report Total:", 
			COLUMN 44, sum(p_rec_batchhead.debit_amt) USING "--,---,---,---,--&.&&" 
			SKIP 2 line 
				 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	
			
			
END REPORT