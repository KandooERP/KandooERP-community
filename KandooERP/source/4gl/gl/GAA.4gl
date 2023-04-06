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
GLOBALS "../gl/GA_GLOBALS.4gl" 
############################################################
# MODULE Scope Variables
############################################################
DEFINE modu_first_time SMALLINT 
DEFINE modu_close_amt CHAR(20) 
DEFINE modu_open_amt CHAR(20) 
###############################################################
# FUNCTION GAA_main()
#
# GAA  Account Detail Report
#  This IS a variation on REPORT GA3, which lists the ledger details
#  in ORDER of account code, year number, period number, reference
#  text AND reference number.  Please note that in some instances, the
#  use of the additional reference fields in the sort causes Online TO
#  do a sequential scan of accountledger rather than use the index.
#  GAA IS maintained as a separate REPORT so as NOT TO introduce
#  performance problems INTO GA3.
###############################################################
FUNCTION GAA_main() 
	DEFER quit 
	DEFER interrupt 
	
	CALL setModuleId("GAA")

	LET modu_first_time = 1 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 
			OPEN WINDOW G103 with FORM "G103" 
			CALL windecoration_g("G103") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
		
			MENU " Account Detail by Reference " 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","GAA","menu-account-det-by-ref") 
					CALL GAA_rpt_process(GAA_rpt_query())
					CALL rpt_rmsreps_reset(NULL)
					
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				ON ACTION "Report" 		#COMMAND "Report" " SELECT criteria AND PRINT REPORT"
					CALL GAA_rpt_process(GAA_rpt_query())
					CALL rpt_rmsreps_reset(NULL)
		
				ON ACTION "Print Manager" 		#COMMAND KEY ("P",f11) "Print" "Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "Exit" 		#COMMAND KEY(interrupt,"E")"Exit" " RETURN TO menus"
					EXIT MENU 
		
			END MENU 
		
			CLOSE WINDOW G103
			 
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL GAA_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW G103 with FORM "G103" 
			CALL windecoration_g("G103") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(GAA_rpt_query()) #save where clause in env 
			CLOSE WINDOW G103 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL GAA_rpt_process(get_url_sel_text())
	END CASE 			
END FUNCTION 


###############################################################
# FUNCTION GAA_rpt_query()
#
#
###############################################################
FUNCTION GAA_rpt_query() 
	DEFINE l_where_text STRING
	DEFINE l_where2_text STRING
	DEFINE l_rec_accountledger RECORD LIKE accountledger.* 
	DEFINE l_prev_acct_code LIKE accountledger.acct_code 
	DEFINE l_tmpmsg STRING 

	MESSAGE kandoomsg2("U",1001,"") #1001 Enter selection criteria - ESC TO Continue
	CONSTRUCT l_where_text ON accountledger.acct_code, 
	coa.desc_text, 
	accountledger.year_num, 
	accountledger.period_num, 
	accountledger.jour_code, 
	accountledger.jour_num, 
	accountledger.jour_seq_num, 
	accountledger.seq_num, 
	accountledger.tran_date, 
	accountledger.ref_text, 
	accountledger.ref_num, 
	accountledger.desc_text, 
	accountledger.debit_amt, 
	accountledger.credit_amt, 
	accountledger.stats_qty 
	FROM accountledger.acct_code, 
	coa.desc_text, 
	accountledger.year_num, 
	accountledger.period_num, 
	accountledger.jour_code, 
	accountledger.jour_num, 
	accountledger.jour_seq_num, 
	accountledger.seq_num, 
	accountledger.tran_date, 
	accountledger.ref_text, 
	accountledger.ref_num, 
	accountledger.desc_text, 
	accountledger.debit_amt, 
	accountledger.credit_amt, 
	accountledger.stats_qty 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","GAA","construct-accountledger") 

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

	CALL segment_con(glob_rec_kandoouser.cmpy_code, "accountledger") 
	RETURNING l_where2_text 

	IF l_where2_text IS NULL THEN 
		RETURN NULL 
	END IF 

	LET l_where_text = l_where_text clipped, l_where2_text
	
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL
	ELSE
		RETURN l_where_text
	END IF 	
END FUNCTION	


###############################################################
# FUNCTION GAA_rpt_process()
#
#
###############################################################
FUNCTION GAA_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT   
	DEFINE l_rec_accountledger RECORD LIKE accountledger.* 
	DEFINE l_prev_acct_code LIKE accountledger.acct_code 
	DEFINE l_tmpmsg STRING 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false
		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"GAA_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT GAA_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0
	LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GAA_rpt_list")].sel_text
	#------------------------------------------------------------


		 
	LET l_query_text = 
	"SELECT accountledger.* FROM accountledger, coa ", 
	"WHERE coa.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
	"AND accountledger.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
	"AND coa.acct_code = accountledger.acct_code ", 
	"AND ",glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GAA_rpt_list")].sel_text clipped," ", 
	" ORDER BY accountledger.acct_code, ", 
	" accountledger.year_num, accountledger.period_num, ", 
	" accountledger.ref_text, accountledger.ref_num " 

	PREPARE s_accountledger FROM l_query_text 
	DECLARE c_accountledger CURSOR FOR s_accountledger 


	#   DISPLAY "Account: " TO lbLabel1

	LET l_prev_acct_code = " " 

	FOREACH c_accountledger INTO l_rec_accountledger.* 
		#---------------------------------------------------------
		OUTPUT TO REPORT GAA_rpt_list(l_rpt_idx,l_rec_accountledger.*)
		IF NOT rpt_int_flag_handler2("Account:",l_rec_accountledger.acct_code, NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------		

--		IF l_rec_accountledger.acct_code != l_prev_acct_code THEN 
--			#DISPLAY l_rec_accountledger.acct_code TO lbLabel1b
--			LET l_tmpmsg = l_rec_accountledger.acct_code 
--		END IF 
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT GAA_rpt_list
	CALL rpt_finish("GAA_rpt_list")
	#------------------------------------------------------------
	
	IF int_flag THEN
		MESSAGE "Report Generation Canceled..."
		RETURN FALSE
	ELSE
		RETURN TRUE
	END IF 	  
END FUNCTION 


###############################################################
# REPORT GAA_rpt_list(p_rec_accountledger)
###############################################################
REPORT GAA_rpt_list(p_rpt_idx,p_rec_accountledger) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_accountledger RECORD LIKE accountledger.* 
	DEFINE l_rec_accounthist RECORD LIKE accounthist.* 
	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_cmpy_head CHAR(132) 
	DEFINE l_note_mark1 CHAR(3)
	DEFINE l_note_mark2 CHAR(3)
	DEFINE l_temp_text CHAR(115) 
	DEFINE l_note_info CHAR(70) 
	DEFINE l_cnt SMALLINT 
	DEFINE i SMALLINT 
	DEFINE l_col2 SMALLINT 
	DEFINE l_col SMALLINT 

	OUTPUT 
	--left margin 0 
	ORDER external BY p_rec_accountledger.acct_code, 
	p_rec_accountledger.year_num, 
	p_rec_accountledger.period_num, 
	p_rec_accountledger.ref_text, 
	p_rec_accountledger.ref_num 
	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

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
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

		BEFORE GROUP OF p_rec_accountledger.acct_code 
			SELECT * INTO l_rec_coa.* FROM coa 
			WHERE acct_code = p_rec_accountledger.acct_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF status = NOTFOUND THEN 
				LET l_rec_coa.desc_text = "** Not found **" 
			END IF 
			SKIP 2 LINES 
			PRINT COLUMN 5, " Account: ", p_rec_accountledger.acct_code, 
			2 spaces, l_rec_coa.desc_text 
			LET modu_first_time = 1 

		BEFORE GROUP OF p_rec_accountledger.year_num 
			SKIP 1 line 
			PRINT COLUMN 1, "Year:", p_rec_accountledger.year_num USING "###&" 

		BEFORE GROUP OF p_rec_accountledger.period_num 
			SKIP 1 line 

		AFTER GROUP OF p_rec_accountledger.period_num 
			PRINT COLUMN 1, "Period:", p_rec_accountledger.period_num USING "##&", 
			COLUMN 50, GROUP sum(p_rec_accountledger.debit_amt) 
			USING "----,---,---,--&.&&", 
			COLUMN 70, GROUP sum(p_rec_accountledger.credit_amt) 
			USING "----,---,---,--&.&&" 
			LET modu_close_amt = ac_form(glob_rec_kandoouser.cmpy_code, 
			l_rec_accounthist.close_amt, 
			l_rec_coa.type_ind, 
			glob_rec_glparms.style_ind) 
			PRINT COLUMN 10, "Closing Balance", 
			COLUMN 40, modu_close_amt 
			LET modu_first_time = 1 

		ON EVERY ROW 
			IF modu_first_time = 1 THEN 
				SELECT * INTO l_rec_accounthist.* FROM accounthist 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND acct_code = p_rec_accountledger.acct_code 
				AND period_num = p_rec_accountledger.period_num 
				AND year_num = p_rec_accountledger.year_num 
				LET modu_open_amt = ac_form(glob_rec_kandoouser.cmpy_code, 
				l_rec_accounthist.open_amt, 
				l_rec_coa.type_ind, 
				glob_rec_glparms.style_ind) 
				PRINT COLUMN 10, "Opening Balance", 
				COLUMN 40, modu_open_amt 
				LET modu_first_time = 0 
			END IF 

			PRINT COLUMN 1, p_rec_accountledger.jour_code[1,2], 
			COLUMN 4, p_rec_accountledger.jour_num USING "<<<<<", 
			COLUMN 10, p_rec_accountledger.desc_text, 
			COLUMN 50, p_rec_accountledger.debit_amt USING "----,---,---,--&.&&", 
			COLUMN 70, p_rec_accountledger.credit_amt USING "----,---,---,--&.&&", 
			COLUMN 95, p_rec_accountledger.ref_text, 
			COLUMN 105, p_rec_accountledger.ref_num USING "########" 

			LET l_note_mark1 = p_rec_accountledger.desc_text[1,3] 
			LET l_note_mark2 = p_rec_accountledger.desc_text[14,17] 

			IF l_note_mark1 = "###" 
			AND l_note_mark2 = "###" THEN 
				LET l_temp_text = p_rec_accountledger.desc_text[4,14] 
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
			COLUMN 50, sum(p_rec_accountledger.debit_amt) 
			USING "----,---,---,--&.&&", 
			COLUMN 70, sum(p_rec_accountledger.credit_amt) 
			USING "----,---,---,--&.&&" 
			SKIP 1 line 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 


END REPORT