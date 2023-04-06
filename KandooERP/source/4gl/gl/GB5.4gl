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
GLOBALS "../gl/G_GL_GLOBALS.4gl" 
GLOBALS "../gl/GB_globals.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl" 

############################################################
# MODULE Scope Variables
############################################################
DEFINE modu_newpage CHAR(1) 
DEFINE modu_currency CHAR(1) 
DEFINE modu_multiple_curr_flag SMALLINT 
DEFINE modu_prog_parent CHAR(3) 
DEFINE modu_sent_batch_num INTEGER 
DEFINE modu_last_batch_num INTEGER 
############################################################
# FUNCTION GB5_main()
#
# Batch modu_currency details
############################################################
FUNCTION GB5_main() 
	DEFER QUIT 
	DEFER INTERRUPT 
	
	CALL setModuleId("GB5")
	
	LET modu_last_batch_num = get_url_last_batch_number() 
	LET modu_sent_batch_num = get_url_sent_batch_number() 
	LET modu_prog_parent = get_url_prog_parent() 

--	IF modu_prog_parent != " " THEN 
--		CALL GB5_rpt_2_process() 
--	ELSE 

		OPEN WINDOW G157 with FORM "G157" 
		CALL windecoration_g("G157") 

--		LET modu_prog_parent = "GB5" 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 

		MENU " Batch modu_currency" 
			BEFORE MENU 
				CALL publish_toolbar("kandoo","GB5","menu-batch-modu_currency") 
				CALL GB5_rpt_process(GB5_rpt_query())
				
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			ON ACTION "Report" 		#COMMAND "Run" " SELECT criteria AND PRINT REPORT"
				CALL GB5_rpt_process(GB5_rpt_query())

			ON ACTION "Print Manager" #COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
				CALL run_prog("URS","","","","") 

			ON ACTION "Exit" 		#COMMAND KEY(interrupt,"E")"Exit" " RETURN TO menus"
				EXIT MENU 

		END MENU 

		CLOSE WINDOW G157 
	 
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL GB5_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW G157 with FORM "G157" 
			CALL windecoration_g("G157") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(GB5_rpt_query()) #save where clause in env 
			CLOSE WINDOW G157 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL GB5_rpt_process(get_url_sel_text())
	END CASE 
END FUNCTION 


############################################################
# FUNCTION GB5_rpt_query()
#
#
############################################################
FUNCTION GB5_rpt_query() 
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
			CALL publish_toolbar("kandoo","GB5","construct-batchhead") 

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

		LET msg_ans = kandoomsg("G",3510,"") 
		#3510 New page each batch (y/n):? "
		LET modu_newpage = upshift(msg_ans) 
		IF modu_newpage IS NULL THEN 
			LET modu_newpage = "Y" 
		END IF 	
		LET glob_rec_rpt_selector.ref1_ind = modu_newpage
		RETURN l_where_text
	END IF 
END FUNCTION

#####################################################################
# FUNCTION GB5_rpt_process(p_where_text) 
#
#
#####################################################################
FUNCTION GB5_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT 
	DEFINE l_rec_batchdetl RECORD LIKE batchdetl.* 
	DEFINE l_save_curr_code LIKE batchdetl.currency_code 	
	
	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"GB5_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT GB5_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0
	LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GB5_rpt_list")].sel_text
	#------------------------------------------------------------


	LET modu_newpage = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GB5_rpt_list")].ref1_ind
		
	LET l_query_text = 
	"SELECT unique batchdetl.* FROM batchdetl, batchhead ", 
	"WHERE batchhead.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND batchdetl.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND batchhead.jour_num = batchdetl.jour_num ", 
	"AND batchhead.jour_code = batchdetl.jour_code ", 
	"AND ",glob_where_part clipped," ", 
	" ORDER BY batchdetl.jour_num, ", 
	" batchdetl.seq_num " 
	PREPARE choice FROM l_query_text 
	DECLARE selcurs CURSOR FOR choice 


	LET l_save_curr_code = NULL 
	LET modu_multiple_curr_flag = false 

	#DISPLAY "Batch: " TO lbLabel1

	FOREACH selcurs INTO l_rec_batchdetl.* 
		IF l_save_curr_code IS NULL THEN 
			LET l_save_curr_code = l_rec_batchdetl.currency_code 
		ELSE 
			IF l_rec_batchdetl.currency_code != l_save_curr_code THEN 
				LET modu_multiple_curr_flag = true 
			END IF 
		END IF 
		#---------------------------------------------------------
		OUTPUT TO REPORT GB5_rpt_list(l_rpt_idx,l_rec_batchdetl.*)
		IF NOT rpt_int_flag_handler2("Batch:",l_rec_batchdetl.jour_num , NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------			
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT GB5_rpt_list
	CALL rpt_finish("GB5_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF  
END FUNCTION 
{

############################################################
# FUNCTION GB5_rpt_2_process()
#
#
############################################################
FUNCTION GB5_rpt_2_process() 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE l_rec_batchdetl RECORD LIKE batchdetl.* 
	DEFINE l_save_curr_code LIKE batchdetl.currency_code 

	LET query_text = 
	"SELECT unique batchdetl.* FROM batchdetl, batchhead ", 
	"WHERE batchhead.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND batchdetl.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND batchhead.jour_num = batchdetl.jour_num ", 
	"AND batchhead.jour_code = batchdetl.jour_code " 

	IF modu_last_batch_num IS NULL 
	OR modu_last_batch_num = 0 THEN 
		LET query_text = query_text clipped, 
		" AND batchdetl.jour_num = '",modu_sent_batch_num,"' ", 
		" ORDER BY batchdetl.jour_num, ", " batchdetl.seq_num " 
	ELSE 
		LET query_text = query_text clipped, 
		" AND batchdetl.jour_num between '",modu_sent_batch_num,"' ", 
		" AND '",modu_last_batch_num,"' ", 
		" ORDER BY batchdetl.jour_num, ", " batchdetl.seq_num " 
	END IF 
	PREPARE b_choice FROM query_text 
	DECLARE b_selcurs CURSOR FOR b_choice
	 
	LET glob_rpt_note = "GL Batch Detail Listing - ", modu_prog_parent clipped 
	LET glob_rpt_output = init_report(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,glob_rpt_note)
	 
	START REPORT GB5_rpt_list TO glob_rpt_output
	 
	LET modu_newpage = "N" 
	LET l_save_curr_code = NULL 
	LET modu_multiple_curr_flag = false
	 
	FOREACH b_selcurs INTO l_rec_batchdetl.* 
		IF l_save_curr_code IS NULL THEN 
			LET l_save_curr_code = l_rec_batchdetl.currency_code 
		ELSE 
			IF l_rec_batchdetl.currency_code != l_save_curr_code THEN 
				LET modu_multiple_curr_flag = true 
			END IF 
		END IF 
		#---------------------------------------------------------
		OUTPUT TO REPORT GB5_rpt_list(l_rpt_idx,l_rec_batchdetl.*)
		IF NOT rpt_int_flag_handler2("Batch:",l_rec_batchdetl.jour_num , NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------		
	END FOREACH 
	
	#------------------------------------------------------------
	FINISH REPORT GB5_rpt_list
	CALL rpt_finish("GB5_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF  
	 
END FUNCTION 

}
############################################################
# REPORT GB5_rpt_list(p_rpt_idx,p_rec_batchdetl)
#
#
############################################################
REPORT GB5_rpt_list(p_rpt_idx,p_rec_batchdetl)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx] 
	DEFINE p_rec_batchdetl RECORD LIKE batchdetl.* 
	DEFINE l_rec_batchhead RECORD LIKE batchhead.* 
	DEFINE l_note_mark1 CHAR(3)
	DEFINE l_note_mark2 CHAR(3)
	DEFINE l_temp_text CHAR(115)
	DEFINE l_note_info CHAR(70)
	DEFINE l_cmpy_head CHAR(132) 
	--DEFINE l_i SMALLINT 
	DEFINE l_col2 SMALLINT 
	DEFINE l_col SMALLINT 
	DEFINE l_cnt SMALLINT 

	OUTPUT 
--	left margin 0 
	ORDER external BY p_rec_batchdetl.jour_num 
	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
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
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]
			 
		BEFORE GROUP OF p_rec_batchdetl.jour_num 
			IF modu_newpage = "Y" THEN 
				SKIP TO top OF PAGE 
			ELSE 
				SKIP 3 LINES 
			END IF 
			SELECT * INTO l_rec_batchhead.* FROM batchhead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND jour_num = p_rec_batchdetl.jour_num 
			AND jour_code = p_rec_batchdetl.jour_code 
			PRINT COLUMN 1, "Batch: ", p_rec_batchdetl.jour_num 
			PRINT COLUMN 5, "Date: ", l_rec_batchhead.jour_date, 
			COLUMN 25, "Posting Period: ", l_rec_batchhead.year_num, "/", 
			l_rec_batchhead.period_num USING "<<<<<", 
			COLUMN 55, "Entered By: ", l_rec_batchhead.entry_code 
			PRINT COLUMN 5, "Cleared : ", l_rec_batchhead.cleared_flag, 
			COLUMN 25,"Posting Run: ", l_rec_batchhead.post_run_num USING "#######" 
			IF l_rec_batchhead.com1_text IS NOT NULL THEN 
				PRINT COLUMN 5, "Comments:", 
				COLUMN 16, l_rec_batchhead.com1_text 
			END IF 
			IF l_rec_batchhead.com2_text IS NOT NULL THEN 
				PRINT COLUMN 16, l_rec_batchhead.com2_text 
			END IF
			 
		AFTER GROUP OF p_rec_batchdetl.jour_num 
			PRINT COLUMN 1, "Control Total: ", l_rec_batchhead.control_amt USING 
			"----,---,---,--&.&&" , " Batch Total : "; 
			PRINT COLUMN 57, 
			GROUP sum(p_rec_batchdetl.debit_amt) USING "---,---,---,--&.&&", 
			COLUMN 76, 
			GROUP sum(p_rec_batchdetl.credit_amt) USING "---,---,---,--&.&&", 
			COLUMN 95, 
			GROUP sum(p_rec_batchdetl.for_debit_amt) USING "---,---,---,--&.&&", 
			COLUMN 114, 
			GROUP sum(p_rec_batchdetl.for_credit_amt) USING "---,---,---,--&.&&"
			 
		ON EVERY ROW 
			PRINT COLUMN 1, p_rec_batchdetl.seq_num USING "#####", 
			COLUMN 7, p_rec_batchdetl.tran_type_ind, 
			COLUMN 12, p_rec_batchdetl.acct_code , 
			COLUMN 46, p_rec_batchdetl.currency_code, 
			COLUMN 50, p_rec_batchdetl.conv_qty USING "###.###", 
			COLUMN 57, p_rec_batchdetl.debit_amt USING "---,---,---,--&.&&", 
			COLUMN 76, p_rec_batchdetl.credit_amt USING "---,---,---,--&.&&", 
			COLUMN 95, p_rec_batchdetl.for_debit_amt USING "---,---,---,--&.&&", 
			COLUMN 114, p_rec_batchdetl.for_credit_amt USING "---,---,---,--&.&&" 
			PRINT COLUMN 12, p_rec_batchdetl.desc_text 
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
			SKIP 2 LINES 
			PRINT COLUMN 1, "Report Total:", 
			COLUMN 57, sum(p_rec_batchdetl.debit_amt) 
			USING "---,---,---,--&.&&", 
			COLUMN 76, sum(p_rec_batchdetl.credit_amt) USING "---,---,---,--&.&&", 
			COLUMN 95, sum(p_rec_batchdetl.for_debit_amt) 
			USING "---,---,---,--&.&&", 
			COLUMN 114, sum(p_rec_batchdetl.for_credit_amt) 
			USING "---,---,---,--&.&&" 
			SKIP 2 line 
			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	
			
			
END REPORT