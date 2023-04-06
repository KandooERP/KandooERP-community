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
DEFINE modu_currency CHAR(1) 
############################################################
# v
#
#  Batches by Account Report
############################################################
FUNCTION GB6_main() 
	DEFER QUIT 
	DEFER INTERRUPT 
	
	CALL setModuleId("GB6")

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 	
			OPEN WINDOW G157 with FORM "G157" 
			CALL windecoration_g("G157") 
		
			MENU " Batch Detail by Account" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","GB6","menu-batch-det-by-account") 
					CALL GB6_rpt_process(GB6_rpt_query())
					
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
		
				ON ACTION "Report" 		#COMMAND "Run" " SELECT criteria AND PRINT REPORT"
					CALL GB6_rpt_process(GB6_rpt_query())
		
				ON ACTION "Print Manager" #COMMAND KEY ("P",f11) "Print" "Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "Exit" 	#COMMAND KEY(interrupt,"E")"Exit" " RETURN TO menus"
					EXIT MENU 
		 
			END MENU 
		
			CLOSE WINDOW G157 
	 
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL GB6_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW G157 with FORM "G157" 
			CALL windecoration_g("G157") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(GB6_rpt_query()) #save where clause in env 
			CLOSE WINDOW G157 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL GB6_rpt_process(get_url_sel_text())
	END CASE 	
END FUNCTION 


############################################################
# FUNCTION GB6_rpt_query() 
#
#
############################################################
FUNCTION GB6_rpt_query() 
	DEFINE l_where_text STRING


	MESSAGE kandoomsg2("U",1001,"") #1001 Enter Selection Criteria - ESC TO Continue "
	CONSTRUCT l_where_text ON batchdetl.jour_code, 
	batchhead.jour_num, 
	batchhead.jour_date, 
	batchdetl.acct_code, 
	batchdetl.analysis_text, 
	batchdetl.desc_text, 
	batchdetl.for_debit_amt, 
	batchdetl.for_credit_amt, 
	batchdetl.stats_qty, 
	batchdetl.ref_text, 
	batchhead.year_num, 
	batchhead.period_num, 
	batchhead.currency_code 
	FROM batchdetl.jour_code, 
	batchhead.jour_num, 
	batchhead.jour_date, 
	batchdetl.acct_code, 
	batchdetl.analysis_text, 
	batchdetl.desc_text, 
	batchdetl.for_debit_amt, 
	batchdetl.for_credit_amt, 
	batchdetl.stats_qty, 
	batchdetl.ref_text, 
	batchhead.year_num, 
	batchhead.period_num, 
	batchhead.currency_code 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","GB6","construct-batchhead") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 
	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL 
	END IF
	 
	CALL segment_con(glob_rec_kandoouser.cmpy_code, "batchdetl") 
	RETURNING q1_text 
	IF q1_text IS NULL THEN 
		RETURN NULL 
	END IF 
	
	LET l_where_text = l_where_text clipped, q1_text
	
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		MESSAGE "Report Generation aborted"
		RETURN NULL
	ELSE
		LET msg_ans = kandoomsg("G",3511,"") 
		LET modu_currency = upshift(msg_ans) 
		IF modu_currency = "Y" THEN 
			LET modu_currency = "B" 
		ELSE 
			LET modu_currency = "F" 
		END IF 	
		LET glob_rec_rpt_selector.ref1_ind = modu_currency
		RETURN l_where_text
	END IF 
END FUNCTION


#####################################################################
# FUNCTION GB6_rpt_process(p_where_text) 
#
#
#####################################################################
FUNCTION GB6_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT  
	DEFINE l_rec_batchdetl RECORD LIKE batchdetl.* 
	DEFINE l_rec_coa RECORD LIKE coa.* 	

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"GB6_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT GB6_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0
	LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GB6_rpt_list")].sel_text
	#------------------------------------------------------------
	#data selector from rmsreps
	LET modu_currency = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GB6_rpt_list")].ref1_ind 
				 
	LET l_query_text = 
	"SELECT * FROM batchdetl, batchhead ", 
	"WHERE batchdetl.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND batchhead.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND batchhead.jour_code = batchdetl.jour_code ", 
	"AND batchhead.jour_num = batchdetl.jour_num ", 
	"AND ",glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GB6_rpt_list")].sel_text clipped," ", 
	"ORDER BY batchdetl.acct_code " 



	PREPARE choice FROM l_query_text 
	DECLARE selcurs CURSOR FOR choice 


	#DISPLAY "Batch: " TO lbLabel1

	FOREACH selcurs INTO l_rec_batchdetl.* 
		#---------------------------------------------------------
		OUTPUT TO REPORT GB6_rpt_list(l_rpt_idx,l_rec_batchdetl.*)  
		IF NOT rpt_int_flag_handler2("Batch:",l_rec_batchdetl.jour_num, NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------	
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT GB6_rpt_list
	CALL rpt_finish("GB6_rpt_list")
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
# REPORT GB6_rpt_list(p_rec_batchdetl)  
#
#
############################################################
REPORT GB6_rpt_list(p_rpt_idx,p_rec_batchdetl) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_batchdetl RECORD LIKE batchdetl.* 
	DEFINE l_rec_batchhead RECORD LIKE batchhead.* 
	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_note_mark1 CHAR(3)
	DEFINE l_note_mark2 CHAR(3)
	DEFINE l_temp_text CHAR(115) 
	DEFINE l_note_info CHAR(70) 
	DEFINE l_cmpy_head CHAR(132) 
	DEFINE l_i SMALLINT 
	DEFINE l_col2 SMALLINT 
	DEFINE l_col SMALLINT 
	DEFINE l_cnt SMALLINT 

	OUTPUT 
	--left margin 0 
	ORDER external BY p_rec_batchdetl.acct_code
	 
	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  
			PRINT COLUMN 1, "--------------------------------------------", 
			"--------------------------------------------", 
			"--------------------------------------------" 
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
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		BEFORE GROUP OF p_rec_batchdetl.acct_code 
			SKIP 1 LINES 
			SELECT * INTO l_rec_coa.* FROM coa 
			WHERE cmpy_code = p_rec_batchdetl.cmpy_code 
			AND acct_code = p_rec_batchdetl.acct_code 
			PRINT COLUMN 1, "Account: ", p_rec_batchdetl.acct_code, 
			COLUMN 20, l_rec_coa.desc_text 

		AFTER GROUP OF p_rec_batchdetl.acct_code 
			SKIP 1 LINES 
			PRINT COLUMN 1, "Account Total: (In Base modu_currency)", 
			COLUMN 78, 
			GROUP sum(p_rec_batchdetl.debit_amt) USING "-----,---,---,--&.&&", 
			COLUMN 103, 
			GROUP sum(p_rec_batchdetl.credit_amt) USING "-----,---,---,--&.&&" 

		ON EVERY ROW 
			SELECT * INTO l_rec_batchhead.* FROM batchhead 
			WHERE cmpy_code = p_rec_batchdetl.cmpy_code 
			AND jour_code = p_rec_batchdetl.jour_code 
			AND jour_num = p_rec_batchdetl.jour_num 
			PRINT COLUMN 1, p_rec_batchdetl.jour_code, 
			COLUMN 5, p_rec_batchdetl.jour_num USING "#######", 
			COLUMN 15, l_rec_batchhead.year_num USING "####", 
			COLUMN 20, l_rec_batchhead.period_num USING "###", 
			COLUMN 25, p_rec_batchdetl.tran_type_ind, 
			COLUMN 30, p_rec_batchdetl.acct_code , 
			COLUMN 50, p_rec_batchdetl.desc_text; 

			IF modu_currency= "F" THEN 
				PRINT COLUMN 80, p_rec_batchdetl.for_debit_amt USING "---,---,---,--&.&&", 
				COLUMN 105, p_rec_batchdetl.for_credit_amt 
				USING "---,---,---,--&.&&", 
				1 space, p_rec_batchdetl.currency_code clipped 
			ELSE 
				PRINT COLUMN 80, p_rec_batchdetl.debit_amt USING "---,---,---,--&.&&", 
				COLUMN 105, p_rec_batchdetl.credit_amt USING "---,---,---,--&.&&" 
			END IF 

			LET l_note_mark1 = p_rec_batchdetl.desc_text[1,3] 
			LET l_note_mark2 = p_rec_batchdetl.desc_text[16,18] 
			IF l_note_mark1 = "###" 
			AND l_note_mark2 = "###" THEN 
				LET l_temp_text = p_rec_batchdetl.desc_text[4,15] 
				DECLARE no_curs CURSOR FOR 
				SELECT note_text, note_num INTO l_note_info, l_cnt FROM notes 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND note_code = l_temp_text 
				ORDER BY note_num 
				FOREACH no_curs 
					PRINT COLUMN 22, l_note_info 
				END FOREACH 
			END IF 

		ON LAST ROW 
			SKIP 1 line 
			PRINT COLUMN 1, "Report Total: ( In Base modu_currency)"; 
			PRINT COLUMN 78,sum(p_rec_batchdetl.debit_amt) USING "-----,---,---,--&.&&", 
			COLUMN 103,sum(p_rec_batchdetl.credit_amt) USING "-----,---,---,--&.&&" 
			SKIP 2 line 
			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 
END REPORT 