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
DEFINE modu_post_run_num INTEGER 
DEFINE modu_first_time SMALLINT 
DEFINE modu_rec_postrun RECORD LIKE postrun.* 
############################################################
# FUNCTION GB7_main()
#
#  GB7  Post run REPORT
############################################################
FUNCTION GB7_main()
	DEFER QUIT 
	DEFER INTERRUPT 
	
	CALL setModuleId("GB7")
	
	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 		 
			LET modu_post_run_num = get_url_post_run_num() 
			IF modu_post_run_num > 0 THEN 
				CALL GB7_rpt_process(GB7_rpt_query())
				CALL donePrompt(NULL,NULL,"ACCEPT") 
			ELSE

				OPEN WINDOW G150 with FORM "G150" 
				CALL windecoration_g("G150") 
		
				MENU " Post Run Report" 
					BEFORE MENU 
						CALL publish_toolbar("kandoo","GB7","menu-post-run-rep") 
						CALL GB7_rpt_process(GB7_rpt_query())
						
					ON ACTION "WEB-HELP" 
						CALL onlinehelp(getmoduleid(),null) 
		
					ON ACTION "actToolbarManager" 
						CALL setuptoolbar() 
		
					ON ACTION "Report" #COMMAND "Run" " Enter selection criteria AND generate REPORT"
						CALL GB7_rpt_process(GB7_rpt_query())
		
					ON ACTION "Print Manager" 		#COMMAND "Print" " Print OR view using RMS"
						CALL run_prog("URS","","","","") 
		
					ON ACTION "Exit" 	#COMMAND KEY (interrupt,"E")"Exit" " Exit TO Menus"
						EXIT MENU 
		
				END MENU 
		
				CLOSE WINDOW G150 
			END IF
						
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL GB7_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW G150 with FORM "G150" 
			CALL windecoration_g("G150") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(GB7_rpt_query()) #save where clause in env 
			CLOSE WINDOW G150 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL GB7_rpt_process(get_url_sel_text())
	END CASE 	

	
END FUNCTION 


############################################################
# FUNCTION GB7_rpt_query()
#
#
############################################################
FUNCTION GB7_rpt_query() 
	DEFINE l_where_text STRING
	DEFINE l_rec_batchhead RECORD LIKE batchhead.* 
	DEFINE l_msgresp LIKE language.yes_flag
	 
	IF (get_url_post_run_num() IS NOT NULL) AND (get_url_post_run_num() > 0) THEN
		LET l_where_text =  "post_run_num = ", trim(get_url_post_run_num()), " " 
	ELSE 
		MESSAGE kandoomsg2("U",1001,"") 
		CONSTRUCT BY NAME l_where_text ON postrun.post_run_num, 
		postrun.post_date, 
		postrun.start_total_amt, 
		postrun.post_amt, 
		postrun.end_total_amt 
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","GB7","construct-postrun") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
		END CONSTRUCT 

	END IF

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		MESSAGE "Report Generation aborted"
		RETURN NULL
	ELSE
		RETURN l_where_text
	END IF 

END FUNCTION


############################################################
# FUNCTION GB7_rpt_process())
#
#
############################################################
FUNCTION GB7_rpt_process(p_where_text) 
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

	LET l_rpt_idx = rpt_start(getmoduleid(),"GB7_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT GB7_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0
	LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GB7_rpt_list")].sel_text
	#------------------------------------------------------------
		
	LET l_query_text = "SELECT * ", 
	"FROM postrun ", 
	"WHERE postrun.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
	glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GB7_rpt_list")].sel_text clipped, 
	" ORDER BY postrun.post_run_num " 
	
	PREPARE s_postrun FROM l_query_text 
	DECLARE c_postrun CURSOR FOR s_postrun
	 
	FOREACH c_postrun INTO modu_rec_postrun.*
		#---------------------------------------------------------
		OUTPUT TO REPORT GB7_rpt_list(l_rpt_idx,modu_rec_postrun.* )
		IF NOT rpt_int_flag_handler2("Post Run:",modu_rec_postrun.post_run_num, NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------		 
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT GB7_rpt_list
	CALL rpt_finish("GB7_rpt_list")
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
# REPORT GB7_rpt_list(p_rpt_idx,p_rec_postrun)
#
#
############################################################
REPORT GB7_rpt_list(p_rpt_idx,p_rec_postrun) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_postrun RECORD LIKE postrun.* 
	DEFINE l_rec_batchhead RECORD LIKE batchhead.* 
	DEFINE l_debit_total FLOAT 

	OUTPUT 
	
	--left margin 0 
	ORDER external BY p_rec_postrun.post_run_num
	 
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			PRINT COLUMN 10, "Batch", 
			COLUMN 18, "Year", 
			COLUMN 34, "Total Debits", 
			COLUMN 55, "Total Credits " 
			PRINT COLUMN 10, "Number", 
			COLUMN 22, "Period" 
			
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		ON EVERY ROW 
			IF modu_first_time = 0 THEN 
				LET modu_first_time = 1 
				PRINT COLUMN 10, "Beg. Bal.", 
				COLUMN 28, p_rec_postrun.start_total_amt USING "---,---,---,--&.&&", 
				COLUMN 50, p_rec_postrun.start_total_amt USING "---,---,---,--&.&&" 
			END IF 
			DECLARE c_batchhead CURSOR FOR 
			SELECT * FROM batchhead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND post_run_num = p_rec_postrun.post_run_num 
			ORDER BY jour_num 
			LET l_debit_total = 0 
			FOREACH c_batchhead INTO l_rec_batchhead.* 
				PRINT COLUMN 09, l_rec_batchhead.jour_num USING "#######", 
				COLUMN 18, l_rec_batchhead.year_num USING "####", 
				COLUMN 26, l_rec_batchhead.period_num USING "&#", 
				COLUMN 28, l_rec_batchhead.debit_amt USING "---,---,---,--&.&&", 
				COLUMN 50, l_rec_batchhead.credit_amt USING "---,---,---,--&.&&" 
				LET l_debit_total = l_rec_batchhead.debit_amt + l_debit_total 
			END FOREACH 

		AFTER GROUP OF p_rec_postrun.post_run_num 
			PRINT COLUMN 31, "-------------------------------------" 
			PRINT COLUMN 10, "End. Bal.", 
			COLUMN 28, p_rec_postrun.end_total_amt USING "---,---,---,--&.&&", 
			COLUMN 50, p_rec_postrun.end_total_amt USING "---,---,---,--&.&&" 
			LET modu_first_time = 0 
			IF l_debit_total != (p_rec_postrun.end_total_amt - p_rec_postrun.start_total_amt) THEN 
				PRINT COLUMN 1, "Error: Debit total IS NOT the difference between beginning AND END balances" 
			END IF 
			SKIP 5 LINES 

		BEFORE GROUP OF p_rec_postrun.post_run_num 
			PRINT COLUMN 1, "Posting Run Number: ", 
			COLUMN 21, p_rec_postrun.post_run_num USING "<<<<<<<#" 
			PRINT COLUMN 8, "Post Amount: ", 
			COLUMN 21, p_rec_postrun.post_amt USING "<<<,<<<,<<<,<<&.&&" 
			PRINT COLUMN 3, "Posting Run Date: ", 
			COLUMN 21, p_rec_postrun.post_date 
			SKIP 1 line 

		ON LAST ROW 
			SKIP 2 LINES 
			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	
			
END REPORT