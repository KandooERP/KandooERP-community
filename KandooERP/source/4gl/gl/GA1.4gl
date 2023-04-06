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

############################################################
# FUNCTION GA1_main() 

# Account vs Budget Report
#
############################################################
FUNCTION GA1_main() 
	DEFER quit 
	DEFER interrupt 
	
	CALL setModuleId("GA1") 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 

			OPEN WINDOW G158 with FORM "G158" 
			CALL windecoration_g("G158") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
		
			MENU " Account vs Budget Report " 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","GA1","menu-account-vs-budget") 
					CALL GA1_rpt_process(GA1_rpt_query())
					CALL rpt_rmsreps_reset(NULL)
					
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				ON ACTION "Report" 		#COMMAND "Report" " SELECT Criteria AND PRINT REPORT"
					CALL GA1_rpt_process(GA1_rpt_query())
					CALL rpt_rmsreps_reset(NULL)
		
				ON ACTION "Print Manager" 				#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "Exit" 		#COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus"
					EXIT MENU 
			END MENU 
		
			CLOSE WINDOW G158
	 
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL GA1_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW G158 with FORM "G158" 
			CALL windecoration_g("G158") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(GA1_rpt_query()) #save where clause in env 
			CLOSE WINDOW G158 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL GA1_rpt_process(get_url_sel_text())
	END CASE 				 
END FUNCTION 


############################################################
# FUNCTION GA1_rpt_query()
#
#
############################################################
FUNCTION GA1_rpt_query()
	DEFINE l_where_text STRING
	DEFINE l_where2_text STRING
	
	MESSAGE kandoomsg2("U",1001,"") 
	CONSTRUCT BY NAME l_where_text ON 
	coa.desc_text, 
	coa.type_ind, 
	coa.group_code , 
	account.year_num 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","GA1","construct-coa") 

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
		# add on the search dimension of segments.......
		CALL segment_con(glob_rec_kandoouser.cmpy_code, "account") 
		RETURNING l_where2_text
		IF l_where2_text IS NOT NULL THEN 
			LET l_where_text = l_where_text clipped, " ",l_where2_text
		END IF
		
		LET glob_ans = choose_budget_number(1) 
	
		IF glob_ans NOT matches "[1-6]" 
		OR glob_ans IS NULL 
		OR int_flag 
		OR quit_flag THEN 
			CLOSE WINDOW wa1b1 
			ERROR kandoomsg2("U",9501,"") 
			RETURN false 
		END IF 
	
		LET glob_budg_num = glob_ans 		
		
		LET glob_rec_rpt_selector.ref1_num = glob_budg_num		 	
		RETURN l_where_text
	END IF 
END FUNCTION
	
############################################################
# FUNCTION GA1_rpt_process(p_where_text)
#
#
############################################################
FUNCTION GA1_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT  	
	DEFINE l_rec_account RECORD LIKE account.* 
	DEFINE l_rec_accounthist RECORD LIKE accounthist.* 
	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_msgresp LIKE language.yes_flag 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false
		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"GA1_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT GA1_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0
	LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GA1_rpt_list")].sel_text
	#------------------------------------------------------------


	LET glob_budg_num = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GA1_rpt_list")].ref1_num
	
	LET l_query_text = "SELECT * ", 
	"FROM account, coa ", 
	"WHERE coa.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "'", 
	" AND account.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "'", 
	" AND coa.acct_code = account.acct_code AND ", 
	glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GA1_rpt_list")].sel_text clipped, " ",
	" ORDER BY account.acct_code,", 
	" account.year_num " 
	PREPARE choice FROM l_query_text 
	DECLARE selcurs CURSOR FOR choice 
	OPEN selcurs 



	FOREACH selcurs INTO l_rec_account.*, l_rec_coa.* 
		IF int_flag OR quit_flag THEN 
			IF kandoomsg("U",8503,"") = "N" THEN 
				#8503 Continue Report (Y/N)
				LET l_msgresp=kandoomsg("U",9501,"") 
				#9501 Printing was aborted.
				EXIT FOREACH 
			END IF 
		END IF 
		# move over chosen budget
		CASE 
			WHEN (glob_budg_num = 2) 
				LET l_rec_account.budg1_amt = l_rec_account.budg2_amt 
			WHEN (glob_budg_num = 3) 
				LET l_rec_account.budg1_amt = l_rec_account.budg3_amt 
			WHEN (glob_budg_num = 4) 
				LET l_rec_account.budg1_amt = l_rec_account.budg4_amt 
			WHEN (glob_budg_num = 5) 
				LET l_rec_account.budg1_amt = l_rec_account.budg5_amt 
			WHEN (glob_budg_num = 6) 
				LET l_rec_account.budg1_amt = l_rec_account.budg6_amt 
		END CASE 
		#---------------------------------------------------------
		OUTPUT TO REPORT GA1_rpt_list(l_rpt_idx,l_rec_account.*, l_rec_coa.*) 
		IF NOT rpt_int_flag_handler2("Account:",l_rec_account.acct_code, NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------		

	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT GA1_rpt_list
	CALL rpt_finish("GA1_rpt_list")
	#------------------------------------------------------------
	
	IF int_flag THEN
		MESSAGE "Report Generation Canceled..."
		RETURN FALSE
	ELSE
		RETURN TRUE
	END IF 	  
END FUNCTION 


############################################################
# REPORT GA1_rpt_list(p_rpt_idx,l_rec_account, l_rec_coa)
#
#
############################################################
REPORT GA1_rpt_list(p_rpt_idx,l_rec_account, l_rec_coa) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE l_rec_account RECORD LIKE account.* 
	DEFINE l_rec_accounthist RECORD LIKE accounthist.* 
	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_msgresp LIKE language.yes_flag 

	OUTPUT 

	--left margin 0 
	#right margin
	#top margin
	#page length

	ORDER external BY l_rec_account.acct_code, l_rec_account.year_num 

	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 


			PRINT COLUMN 1, "Year", 
			COLUMN 18, "Beginning", 
			COLUMN 33, "Year TO Date", 
			COLUMN 53, "Year TO Date", 
			COLUMN 73, "Year TO Date", 
			COLUMN 95, "Year Budget" 

			PRINT COLUMN 18, " Balance", 
			COLUMN 33, " Debits", 
			COLUMN 53, " Credits", 
			COLUMN 73, "Pre-Closing", 
			COLUMN 95, "Number: ", glob_budg_num USING "<<<<" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		ON EVERY ROW 

			PRINT COLUMN 1, l_rec_account.year_num USING "####", 
			COLUMN 10, l_rec_account.open_amt USING "----,---,---,--&.&&", 
			COLUMN 30, l_rec_account.debit_amt USING "----,---,---,--&.&&", 
			COLUMN 50, l_rec_account.credit_amt USING "----,---,---,--&.&&", 
			COLUMN 70, l_rec_account.ytd_pre_close_amt USING "----,---,---,--&.&&", 
			COLUMN 90, l_rec_account.budg1_amt USING "----,---,---,--&.&&" 

		ON LAST ROW 

			PRINT COLUMN 1, "Report Totals:" 
			PRINT 
			COLUMN 10, sum(l_rec_account.open_amt) USING "----,---,---,--&.&&", 
			COLUMN 30, sum(l_rec_account.debit_amt) USING "----,---,---,--&.&&", 
			COLUMN 50, sum(l_rec_account.credit_amt) USING "----,---,---,--&.&&", 
			COLUMN 70, sum(l_rec_account.ytd_pre_close_amt) USING "----,---,---,--&.&&", 
			COLUMN 90, sum(l_rec_account.budg1_amt) USING "----,---,---,--&.&&" 

			SKIP 1 line 

			SKIP 1 line 
			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 


		BEFORE GROUP OF l_rec_account.acct_code 

			SKIP 2 LINES 
			PRINT COLUMN 5, " Account: ", l_rec_account.acct_code , 
			2 spaces, l_rec_coa.desc_text 

		AFTER GROUP OF l_rec_account.acct_code 

			PRINT COLUMN 1, "Account:", 
			COLUMN 10, GROUP sum(l_rec_account.open_amt) USING "----,---,---,--&.&&", 
			COLUMN 30, GROUP sum(l_rec_account.debit_amt) USING "----,---,---,--&.&&", 
			COLUMN 50, GROUP sum(l_rec_account.credit_amt) USING "----,---,---,--&.&&", 
			COLUMN 70, GROUP sum(l_rec_account.ytd_pre_close_amt) USING "----,---,---,--&.&&", 
			COLUMN 90, GROUP sum(l_rec_account.budg1_amt) USING "----,---,---,--&.&&" 

END REPORT