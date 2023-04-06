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
# FUNCTION GA2(pArg)
#
#  GA2  Account Period Summary Report
############################################################
FUNCTION GA2_main() 
	DEFINE p_arg STRING 

	DEFER quit 
	DEFER interrupt 
	
	CALL setModuleId("GA2")
	
	OPEN WINDOW G105 with FORM "G105" 
	CALL windecoration_g("G105") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 	

	MENU " Account Period Summary" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","GA2","menu-account-period") 
			CALL GA2_rpt_process(GA2_rpt_query())
			CALL rpt_rmsreps_reset(NULL)
			
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "Report" 	#COMMAND "Report" " SELECT criteria AND PRINT REPORT"
			CALL GA2_rpt_process(GA2_rpt_query())
			CALL rpt_rmsreps_reset(NULL)

		ON ACTION "Print Manager" #COMMAND KEY ("P",f11) "Print" "Print OR view using RMS"
			CALL run_prog("URS","","","","") 

		ON ACTION "Exit" #COMMAND KEY(interrupt,"E")"Exit" " RETURN TO menus"
			EXIT MENU 

	END MENU 

	CLOSE WINDOW G105 
END FUNCTION 
############################################################
# END FUNCTION GA2(pArg)
############################################################


############################################################
# FUNCTION GA2_rpt_query()
#
#
############################################################
FUNCTION GA2_rpt_query() 
	DEFINE l_where_text STRING 
	DEFINE l_where2_text STRING	
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE l_rec_accounthist RECORD LIKE accounthist.* 
	DEFINE l_tmpmsg STRING 

	MESSAGE kandoomsg2("U",1001,"") 	#1001 Enter selection criteria - ESC TO START REPORT"
	CONSTRUCT BY NAME l_where_text ON 
		accounthist.acct_code, 
		accounthist.year_num, 
		accounthist.period_num, 
		account.bal_amt, 
		accounthist.ytd_pre_close_amt, 
		accounthist.open_amt, 
		accounthist.close_amt, 
		accounthist.pre_close_amt, 
		accounthist.debit_amt, 
		accounthist.credit_amt, 
		accounthist.stats_qty, 
		accounthist.budg1_amt, 
		accounthist.budg2_amt, 
		accounthist.budg3_amt, 
		accounthist.budg4_amt, 
		accounthist.budg5_amt, 
		accounthist.budg6_amt 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","G2A","construct-accounthist") 

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
		CALL segment_con(glob_rec_kandoouser.cmpy_code, "accounthist") 
		RETURNING l_where2_text 
	
		IF l_where2_text IS NOT NULL THEN 
			LET l_where_text = l_where_text clipped, l_where2_text 
		END IF
		RETURN l_where_text
	END IF 
	
END FUNCTION 
############################################################
# END FUNCTION GA2_rpt_query()
############################################################


############################################################
# FUNCTION GA2_rpt_process(p_where_text)
#
#
############################################################
FUNCTION GA2_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT  #report array index
	DEFINE l_rec_accounthist RECORD LIKE accounthist.* 
	DEFINE l_tmpmsg STRING 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false
		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"GA2_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT GA2_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0
	LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GA2_rpt_list")].sel_text
	#------------------------------------------------------------

	LET l_query_text = 
		"SELECT accounthist.* FROM accounthist, account ", 
		"WHERE accounthist.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND account.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND account.cmpy_code = accounthist.cmpy_code ", # ericv 20190511: this part was missing in the join 
		"AND account.acct_code = accounthist.acct_code ", 
		"AND account.year_num = accounthist.year_num ", 
		"AND ",glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GA2_rpt_list")].sel_text clipped," ",
		"ORDER BY accounthist.acct_code,", 
		" accounthist.year_num, accounthist.period_num " 

	PREPARE choice FROM l_query_text 
	DECLARE selcurs CURSOR FOR choice 


	FOREACH selcurs INTO l_rec_accounthist.* 
		#---------------------------------------------------------
		OUTPUT TO REPORT GA2_rpt_list(l_rpt_idx,l_rec_accounthist.*) 
		IF NOT rpt_int_flag_handler2("Account:",l_rec_accounthist.acct_code, NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------			
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT GA2_rpt_list
	CALL rpt_finish("GA2_rpt_list")
	#------------------------------------------------------------
	
	IF int_flag THEN
		MESSAGE "Report Generation Canceled..."
		RETURN FALSE
	ELSE
		RETURN TRUE
	END IF 	
END FUNCTION 
############################################################
# END FUNCTION GA2_rpt_process(p_where_text)
############################################################


############################################################
# REPORT GA2_rpt_list(l_rec_accounthist)
#
#
############################################################
REPORT GA2_rpt_list(p_rpt_idx,l_rec_accounthist) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE l_rec_accounthist RECORD LIKE accounthist.* 
	DEFINE l_rec_coa RECORD LIKE coa.* 
	--DEFINE l_temp_text CHAR(115) 
	DEFINE l_cmpy_head CHAR(132) 
	DEFINE i SMALLINT 
	DEFINE l_col2 SMALLINT 
	DEFINE l_col SMALLINT 

	OUTPUT 
--	left margin 0 
	ORDER external BY 
		l_rec_accounthist.acct_code, 
		l_rec_accounthist.year_num, 
		l_rec_accounthist.period_num 
	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 1, "Year", 
			COLUMN 12, "Beginning", 
			COLUMN 32, " Period", 
			COLUMN 52, " Period", 
			COLUMN 72, " Ending", 
			COLUMN 92, "Pre-Closing" 

			PRINT COLUMN 5, "Period", 
			COLUMN 12, " Balance", 
			COLUMN 32, " Debits", 
			COLUMN 52, " Credits", 
			COLUMN 72, " Balance", 
			COLUMN 92, "Balance" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		BEFORE GROUP OF l_rec_accounthist.acct_code 
			NEED 4 LINES 
			SKIP 2 LINES 
			SELECT * INTO l_rec_coa.* FROM coa 
			WHERE cmpy_code = l_rec_accounthist.cmpy_code 
			AND acct_code = l_rec_accounthist.acct_code 

			PRINT COLUMN 5, " Account: ", l_rec_accounthist.acct_code ,	2 spaces, l_rec_coa.desc_text 
			SKIP 1 line 

		AFTER GROUP OF l_rec_accounthist.acct_code 
			NEED 4 LINES 
			SKIP 2 line 
			PRINT COLUMN 1, "Acct:", 
			COLUMN 9, GROUP sum(l_rec_accounthist.open_amt) USING "---,---,---,--&.&&", 
			COLUMN 29, GROUP sum(l_rec_accounthist.debit_amt) USING "---,---,---,--&.&&", 
			COLUMN 49, GROUP sum(l_rec_accounthist.credit_amt) USING "---,---,---,--&.&&", 
			COLUMN 69, GROUP sum(l_rec_accounthist.close_amt) USING "---,---,---,--&.&&", 
			COLUMN 89, GROUP sum(l_rec_accounthist.pre_close_amt) USING "---,---,---,--&.&&" 

		AFTER GROUP OF l_rec_accounthist.year_num 
			PRINT COLUMN 1, "Year:", 
			COLUMN 9, GROUP sum(l_rec_accounthist.open_amt) USING "---,---,---,--&.&&", 
			COLUMN 29, GROUP sum(l_rec_accounthist.debit_amt) USING "---,---,---,--&.&&", 
			COLUMN 49, GROUP sum(l_rec_accounthist.credit_amt) USING "---,---,---,--&.&&", 
			COLUMN 69, GROUP sum(l_rec_accounthist.close_amt) USING "---,---,---,--&.&&", 
			COLUMN 89, GROUP sum(l_rec_accounthist.pre_close_amt) USING "---,---,---,--&.&&" 

		ON EVERY ROW 
			PRINT COLUMN 1, l_rec_accounthist.year_num USING "####", 
			COLUMN 6, l_rec_accounthist.period_num USING "##", 
			COLUMN 9, l_rec_accounthist.open_amt USING "---,---,---,--&.&&", 
			COLUMN 29, l_rec_accounthist.debit_amt USING "---,---,---,--&.&&", 
			COLUMN 49, l_rec_accounthist.credit_amt USING "---,---,---,--&.&&", 
			COLUMN 69 , l_rec_accounthist.close_amt USING "---,---,---,--&.&&", 
			COLUMN 89, l_rec_accounthist.pre_close_amt USING "---,---,---,--&.&&" 

		ON LAST ROW 
			NEED 8 LINES 
			SKIP 2 LINES 

			PRINT COLUMN 1, "Rpt :", 
			COLUMN 9, sum(l_rec_accounthist.open_amt) USING "---,---,---,--&.&&", 
			COLUMN 29, sum(l_rec_accounthist.debit_amt) USING "---,---,---,--&.&&", 
			COLUMN 49, sum(l_rec_accounthist.credit_amt) USING "---,---,---,--&.&&", 
			COLUMN 69, sum(l_rec_accounthist.close_amt) USING "---,---,---,--&.&&", 
			COLUMN 89, sum(l_rec_accounthist.pre_close_amt) USING "---,---,---,--&.&&" 
			SKIP 2 line 
			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 

END REPORT 
############################################################
# END REPORT GA2_rpt_list(l_rec_accounthist)
############################################################