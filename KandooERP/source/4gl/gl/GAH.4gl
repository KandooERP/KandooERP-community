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
DEFINE modu_rec_accountledger RECORD LIKE accountledger.* 
--DEFINE l_rec_coa RECORD LIKE coa.* 
DEFINE modu_open_amt CHAR(20)
DEFINE modu_close_amt CHAR(20)
DEFINE modu_first_time SMALLINT 
###############################################################
# FUNCTION GAH_main()
#
# #   GAH - Account Detail Report ( based on GAH )
#         Ordered by Acct. Code, Year / Period, Journal Code, Seq. No.
#         Includes Summary AT END of REPORT showing total DB / CR 's,
#         AND Net Movement by journal code
###############################################################
FUNCTION GAH_main() 
	DEFER quit 
	DEFER interrupt 
	
	CALL setModuleId("GAG") 

	CREATE temp TABLE t_accountledger 
	( jour_code CHAR(3) , 
	desc_text CHAR(30) , 
	debit_amt dec(16,2) , 
	credit_amt dec(16,2) ) with no LOG 

	LET modu_first_time = 1 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode
			OPEN WINDOW G103 with FORM "G103" 
			CALL windecoration_g("G103") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
		
			MENU " Account Detail by Journal" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","GAH","menu-account-det-by-journal") 
					CALL GAH_rpt_process(GAH_rpt_query())
					CALL rpt_rmsreps_reset(NULL)
					
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				ON ACTION "REPORT" #COMMAND "Report" " SELECT Criteria AND Print Report" 
					CALL GAH_rpt_process(GAH_rpt_query())	
					CALL rpt_rmsreps_reset(NULL)	
		
				ON ACTION "Print Manager" 	#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "CANCEL" #COMMAND KEY(interrupt,"E")"Exit" " RETURN TO menus" 
					EXIT MENU 
		
			END MENU 
		
			CLOSE WINDOW G103 

		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL GAH_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW G103 with FORM "G103" 
			CALL windecoration_g("G103") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(GAH_rpt_query()) #save where clause in env 
			CLOSE WINDOW G103 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL GAH_rpt_process(get_url_sel_text())
	END CASE 
	
	DROP TABLE t_accountledger			
END FUNCTION 


###############################################################
# FUNCTION GAH_rpt_query()
#
#
###############################################################
FUNCTION GAH_rpt_query()
 	DEFINE l_where_text STRING
 	DEFINE l_where2_text STRING
 	 	
	MESSAGE kandoomsg2("G",1001,"") #1001 Enter selection criteria - ESC TO Continue" 
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
			CALL publish_toolbar("kandoo","GAH","construct-accountledger") 

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
		LET l_where2_text = segment_con(glob_rec_kandoouser.cmpy_code, "accountledger") 
		IF l_where2_text IS NULL THEN 
			RETURN NULL 
		ELSE
			LET l_where_text = l_where_text clipped, l_where2_text 
		END IF
	END IF

	RETURN l_where_text	
END FUNCTION 


###############################################################
# FUNCTION GAH_rpt_process ()
#
#
###############################################################
FUNCTION GAH_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT    
	DEFINE l_prev_acct_code LIKE accountledger.acct_code 
	DEFINE l_tmpmsg STRING 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"GAH_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT GAH_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0
	LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GAH_rpt_list")].sel_text
	#------------------------------------------------------------


	LET l_query_text = 
	"SELECT accountledger.* FROM accountledger, coa ", 
	"WHERE coa.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
	"AND accountledger.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
	"AND coa.acct_code = accountledger.acct_code ", 
	"AND ",glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GAH_rpt_list")].sel_text clipped," ", 
	" ORDER BY accountledger.acct_code, accountledger.year_num,", 
	" accountledger.period_num, accountledger.jour_code,", 
	" accountledger.seq_num " 

	PREPARE s_accountledger FROM l_query_text 
	DECLARE c_accountledger CURSOR FOR s_accountledger 



	# Clear temp. table
	DELETE FROM t_accountledger 


	#   DISPLAY "Account: " TO lbLabel1

	LET l_prev_acct_code = " " 

	FOREACH c_accountledger INTO modu_rec_accountledger.* 
		IF modu_rec_accountledger.debit_amt IS NULL THEN 
			LET modu_rec_accountledger.debit_amt = 0 
		END IF 

		IF modu_rec_accountledger.credit_amt IS NULL THEN 
			LET modu_rec_accountledger.credit_amt = 0 
		END IF 
		#---------------------------------------------------------
		OUTPUT TO REPORT GAH_rpt_list(l_rpt_idx,modu_rec_accountledger.*)
		IF NOT rpt_int_flag_handler2("Account:",modu_rec_accountledger.acct_code, NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------

		IF l_prev_acct_code != modu_rec_accountledger.acct_code THEN 
			#         DISPLAY modu_rec_accountledger.acct_code TO lbLabel1b
			#MESSAGE modu_rec_accountledger.acct_code 
			LET l_prev_acct_code = modu_rec_accountledger.acct_code 
		END IF 
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT GAH_rpt_list
	CALL rpt_finish("GAH_rpt_list")
	#------------------------------------------------------------
	
	IF int_flag THEN
		MESSAGE "Report Generation Canceled..."
		RETURN FALSE
	ELSE
		RETURN TRUE
	END IF 	
END FUNCTION 


###############################################################
# REPORT GAH_rpt_list(p_rpt_idx,p_rec_accountledger)
#
#
###############################################################
REPORT GAH_rpt_list(p_rpt_idx,p_rec_accountledger) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_accountledger RECORD LIKE accountledger.* 
	DEFINE l_rec_accounthist RECORD LIKE accounthist.*
	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_note_mark1 CHAR(3)
	DEFINE l_note_mark2 CHAR(3)
	DEFINE l_temp_text CHAR(115)
	DEFINE l_note_info CHAR(70) 
	--DEFINE l_debit_tot CHAR(20)
	--DEFINE l_credit_tot CHAR(20)
	DEFINE l_cmpy_head CHAR(132) 
	DEFINE i SMALLINT 
	DEFINE l_col2 SMALLINT 
	DEFINE l_col SMALLINT 
	DEFINE l_cnt SMALLINT 
	DEFINE l_jour_code LIKE accountledger.jour_code 
	DEFINE l_move_db_amt LIKE accounthist.debit_amt 
	DEFINE l_debit_amt LIKE accounthist.debit_amt 
	DEFINE l_move_cr_amt LIKE accounthist.credit_amt 
	DEFINE l_credit_amt LIKE accounthist.credit_amt 
	DEFINE l_desc_text LIKE accountledger.desc_text 
	DEFINE l_jour_desc_text LIKE journal.desc_text 

	OUTPUT 
	--left margin 0 
	ORDER external BY p_rec_accountledger.acct_code, 
	p_rec_accountledger.year_num, 
	p_rec_accountledger.period_num, 
	p_rec_accountledger.jour_code, 
	p_rec_accountledger.seq_num 
	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 1, "Jour", 
			COLUMN 6, "Batch", 
			COLUMN 13, "Description", 
			COLUMN 55, "Debits", 
			COLUMN 72, "Credits", 
			COLUMN 82, "Tran", 
			COLUMN 91, "Tran", 
			COLUMN 99, "Source", 
			COLUMN 110, "Source " , 
			COLUMN 115, "Analysis" 
			PRINT COLUMN 1, "Code", 
			COLUMN 6, " Num", 
			COLUMN 82, "Type", 
			COLUMN 91, "Date", 
			COLUMN 110, "Number" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			IF modu_first_time = 0 THEN 
				PRINT COLUMN 1, " .... Account: ", p_rec_accountledger.acct_code, 
				2 spaces, l_rec_coa.desc_text 
			ELSE 
				PRINT COLUMN 1, " " 
			END IF 

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
			SKIP 1 LINES 

		AFTER GROUP OF p_rec_accountledger.period_num 
			PRINT COLUMN 1, "Period: ", p_rec_accountledger.year_num USING "###&","/", 
			p_rec_accountledger.period_num USING "<<<", 
			COLUMN 44, GROUP sum(p_rec_accountledger.debit_amt) 
			USING "--,---,---,--&.&&", 
			COLUMN 62, GROUP sum(p_rec_accountledger.credit_amt) 
			USING "--,---,---,--&.&&" 
			LET modu_close_amt = ac_form(glob_rec_kandoouser.cmpy_code, 
			l_rec_accounthist.close_amt, 
			l_rec_coa.type_ind, 
			glob_rec_glparms.style_ind) 
			PRINT COLUMN 10, "Closing Balance", 
			COLUMN 26, modu_close_amt 
			SKIP 1 line 
			LET modu_first_time = 1 

		ON EVERY ROW 
			IF modu_first_time = 1 THEN 
				SELECT * INTO l_rec_accounthist.* FROM accounthist 
				WHERE acct_code = p_rec_accountledger.acct_code 
				AND year_num = p_rec_accountledger.year_num 
				AND period_num = p_rec_accountledger.period_num 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 

				IF status = NOTFOUND THEN 
					LET l_rec_accounthist.open_amt = 0 
					LET l_rec_accounthist.close_amt = 0 
				END IF 

				LET modu_open_amt = ac_form(glob_rec_kandoouser.cmpy_code, 
				l_rec_accounthist.open_amt, 
				l_rec_coa.type_ind, 
				glob_rec_glparms.style_ind) 
				PRINT COLUMN 10, "Opening Balance", 
				COLUMN 26, modu_open_amt 
				LET modu_first_time = 0 
			END IF 

			IF l_rec_coa.uom_code IS NULL THEN 
				LET p_rec_accountledger.stats_qty = NULL 
			END IF 

			PRINT COLUMN 1, p_rec_accountledger.jour_code[1,2], 
			COLUMN 4, p_rec_accountledger.jour_num USING "<<<<<<<&", 
			COLUMN 13, p_rec_accountledger.desc_text[1,30], 
			COLUMN 44, p_rec_accountledger.debit_amt USING "--,---,---,--&.&&", 
			COLUMN 62, p_rec_accountledger.credit_amt USING "--,---,---,--&.&&", 
			COLUMN 82, p_rec_accountledger.tran_type_ind, 
			COLUMN 89, p_rec_accountledger.tran_date USING "dd/mm/yy", 
			COLUMN 99, p_rec_accountledger.ref_text, 
			COLUMN 108, p_rec_accountledger.ref_num USING "########", 
			COLUMN 117, p_rec_accountledger.analysis_text 
			#
			# Keep track of DB / CR FOR jour_code's
			#    ( NB. Zero-accounts will have a NULL jour_code )
			#
			IF p_rec_accountledger.jour_code IS NOT NULL THEN 
				LET l_debit_amt = p_rec_accountledger.debit_amt 
				LET l_credit_amt = p_rec_accountledger.credit_amt 
				IF l_debit_amt IS NULL THEN 
					LET l_debit_amt = 0 
				END IF 
				IF l_credit_amt IS NULL THEN 
					LET l_credit_amt = 0 
				END IF 
				UPDATE t_accountledger 
				SET debit_amt = debit_amt + l_debit_amt, 
				credit_amt = credit_amt + l_credit_amt 
				WHERE jour_code = p_rec_accountledger.jour_code 

				IF sqlca.sqlerrd[3] = 0 THEN 
					SELECT desc_text INTO l_jour_desc_text 
					FROM journal 
					WHERE jour_code = p_rec_accountledger.jour_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					INSERT INTO t_accountledger VALUES ( p_rec_accountledger.jour_code, 
					l_jour_desc_text, 
					l_debit_amt , 
					l_credit_amt ) 
				END IF 

			END IF 
			#
			#
			#
			LET l_note_mark1 = p_rec_accountledger.desc_text[1,3] 
			LET l_note_mark2 = p_rec_accountledger.desc_text[16,18] 

			IF l_note_mark1 = "###" 
			AND l_note_mark2 = "###" THEN 
				LET l_temp_text = p_rec_accountledger.desc_text[4,15] 
				DECLARE no_curs CURSOR FOR 
				SELECT note_text, 
				note_num 
				INTO l_note_info, 
				l_cnt 
				FROM notes 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND note_code = l_temp_text 
				ORDER BY note_num 
				FOREACH no_curs 
					PRINT COLUMN 22, l_note_info 
				END FOREACH 
			END IF 

		ON LAST ROW 
			SKIP 2 LINES 
			PRINT COLUMN 1, "Type" , 
			COLUMN 13, "Journal" , 
			COLUMN 55, "Debits" , 
			COLUMN 72, "Credits" , 
			COLUMN 94, "Movement" 
			PRINT COLUMN 1, "----" , 
			COLUMN 13, "-------" , 
			COLUMN 55, "------" , 
			COLUMN 72, "-------" , 
			COLUMN 94, "--------" 

			DECLARE c2_accountledger CURSOR FOR 
			SELECT * FROM t_accountledger 
			ORDER BY jour_code 

			FOREACH c2_accountledger INTO l_jour_code, 
				l_desc_text, 
				l_debit_amt, 
				l_credit_amt 
				PRINT COLUMN 1, l_jour_code[1,2], 
				COLUMN 13, l_desc_text[1,30], 
				COLUMN 44, l_debit_amt USING "--,---,---,--&.&&" , 
				COLUMN 62, l_credit_amt USING "--,---,---,--&.&&" ; 

				IF l_debit_amt >= l_credit_amt THEN # movement OF 0 = db 
					PRINT COLUMN 82, l_debit_amt - l_credit_amt 
					USING "--,---,---,--&.&&", 
					' db' 
				ELSE 
					PRINT COLUMN 82, l_credit_amt - l_debit_amt 
					USING "--,---,---,--&.&&", 
					' cr' 
				END IF 

			END FOREACH 
			#
			# Calculate movement total
			#

			SELECT sum(debit_amt) INTO l_move_db_amt 
			FROM t_accountledger 

			IF l_move_db_amt IS NULL THEN 
				LET l_move_db_amt = 0 
			END IF 

			SELECT sum(credit_amt) INTO l_move_cr_amt 
			FROM t_accountledger 

			IF l_move_cr_amt IS NULL THEN 
				LET l_move_cr_amt = 0 
			END IF 

			SKIP 2 LINES 
			PRINT COLUMN 1, "Report Total:", 
			COLUMN 44, sum(p_rec_accountledger.debit_amt) 
			USING "--,---,---,--&.&&", 
			COLUMN 62, sum(p_rec_accountledger.credit_amt) 
			USING "--,---,---,--&.&&"; 
			IF l_move_db_amt >= l_move_cr_amt THEN # movement OF 0 = db 
				PRINT COLUMN 82, l_move_db_amt - l_move_cr_amt 
				USING "--,---,---,--&.&&", 
				' db' 
			ELSE 
				PRINT COLUMN 82, l_move_cr_amt - l_move_db_amt 
				USING "--,---,---,--&.&&", 
				' cr' 
			END IF 

			SKIP 2 line 
			#End Of Report
				IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
					PRINT COLUMN 01,"Selection Criteria:" 
					PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
				END IF 
				PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 

			 
END REPORT