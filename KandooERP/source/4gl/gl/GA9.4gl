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
--DEFINE modu_outputa CHAR(60)
--DEFINE modu_rpt_pagena LIKE rmsreps.page_num 
###############################################################
# FUNCTION GA9_main()
#
# GA9  Budget Worksheet Report
###############################################################
FUNCTION GA9_main() 
	DEFER quit 
	DEFER interrupt 
	
	CALL setModuleId("GA7")

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 	
			OPEN WINDOW G158 with FORM "G158" 
			CALL windecoration_g("G158") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
		
			MENU " Budget Worksheet" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","GA9","menu-budget-worksheet") 
					CALL GA9_rpt_process(GA9_rpt_query())
					CALL rpt_rmsreps_reset(NULL)
					
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				ON ACTION "Report" 		#COMMAND "Report" " SELECT Criteria AND PRINT REPORT"
					CALL GA9_rpt_process(GA9_rpt_query())
					CALL rpt_rmsreps_reset(NULL)
					
				ON ACTION "Print Manager" 		#COMMAND "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "Exit" 		#COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus"
					EXIT MENU 
		
			END MENU 
		
			CLOSE WINDOW G158 

		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL GA9_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW G158 with FORM "G158" 
			CALL windecoration_g("G158") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(GA9_rpt_query()) #save where clause in env 
			CLOSE WINDOW G158 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL GA9_rpt_process(get_url_sel_text())
	END CASE
END FUNCTION 


###############################################################
# FUNCTION GA9_rpt_query()
#
#
###############################################################
FUNCTION GA9_rpt_query() 
	DEFINE l_where_text STRING
	DEFINE l_where2_text STRING

	DEFINE l_rec_accounthist RECORD LIKE accounthist.* 
	--DEFINE l_rec_coa RECORD LIKE coa.*
	DEFINE l_fullreport SMALLINT
	DEFINE l_ans CHAR(1)
	DEFINE l_tmpmsg STRING 
	DEFINE l_msgresp LIKE language.yes_flag 


	LET l_ans = choose_budget_group(0) 
	IF l_ans = "0" THEN 
		LET l_fullreport = false 
	ELSE 
		IF int_flag OR quit_flag THEN 
			RETURN NULL 
		ELSE 
			LET l_fullreport = true 
		END IF 
	END IF 

	MESSAGE kandoomsg2("U",1001,"") 
	
	CONSTRUCT l_where_text ON coa.desc_text, 
	coa.type_ind, 
	coa.group_code, 
	accounthist.year_num, 
	accounthist.period_num 
	FROM coa.desc_text, 
	coa.type_ind, 
	coa.group_code, 
	account.year_num, 
	accounthist.period_num 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","GA9","construct-coa") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
			
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	# add on the search dimension of segments.......
	IF int_flag OR quit_flag THEN 
		RETURN NULL 
	END IF 

	CALL segment_con(glob_rec_kandoouser.cmpy_code, "accounthist") RETURNING l_where2_text 
	IF int_flag OR quit_flag THEN 
		MESSAGE kandoomsg2("U",9501,"") 
		#9501 Printing was aborted"
		RETURN NULL 
	END IF 

	LET l_where_text = l_where_text clipped, l_where2_text

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL
	ELSE
		LET glob_rec_rpt_selector.ref1_ind = l_fullreport
		RETURN l_where_text
	END IF 	
	
END FUNCTION	
	

###############################################################
# FUNCTION GA9_rpt_process()
#
#
###############################################################
FUNCTION GA9_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT 


	DEFINE l_rec_accounthist RECORD LIKE accounthist.* 
	--DEFINE l_rec_coa RECORD LIKE coa.*
	DEFINE l_fullreport SMALLINT
	DEFINE l_ans CHAR(1)
	DEFINE l_tmpmsg STRING 
	DEFINE l_msgresp LIKE language.yes_flag 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false
		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"GA9_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT GA9_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0
	LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GA9_rpt_list")].sel_text
	#------------------------------------------------------------

	LET l_fullreport = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GA9_rpt_list")].ref1_ind
	
	IF l_fullreport THEN 
		LET l_rpt_idx = rpt_start("GA9-F","GA9_rpt_list_full",p_where_text, RPT_SHOW_RMS_DIALOG)
		IF l_rpt_idx = 0 THEN #User pressed CANCEL
			RETURN FALSE
		END IF	
		START REPORT GA9_rpt_list_full TO rpt_get_report_file_with_path2(l_rpt_idx)
		WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0
		LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GA9_rpt_list_full")].sel_text

	END IF 

		 
	LET l_query_text = "SELECT accounthist.* ", 
	"FROM accounthist , coa ", 
	"WHERE coa.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "'", 
	" AND accounthist.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "'", 
	" AND coa.acct_code = accounthist.acct_code AND ", 
	glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GA9_rpt_list")].sel_text clipped, " ",
	" ORDER BY accounthist.acct_code,", 
	" accounthist.year_num, accounthist.period_num " 

	PREPARE choice FROM l_query_text 
	DECLARE selcurs CURSOR FOR choice 
	OPEN selcurs 


	FOREACH selcurs INTO l_rec_accounthist.* 
		#---------------------------------------------------------
		OUTPUT TO REPORT GA9_rpt_list(l_rpt_idx,l_rec_accounthist.* ) 
		IF NOT rpt_int_flag_handler2("Account:",l_rec_accounthist.acct_code, NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------		

		IF l_fullreport THEN 
		#---------------------------------------------------------	
			OUTPUT TO REPORT GA9_rpt_list_full(l_rpt_idx,l_rec_accounthist.* )
		#---------------------------------------------------------	 
		END IF 


	END FOREACH 

 

	#------------------------------------------------------------
	FINISH REPORT GA9_rpt_list
	CALL rpt_finish("GA9_rpt_list")
	#------------------------------------------------------------
	
	IF int_flag THEN
		MESSAGE "Report Generation Canceled..."
		RETURN FALSE
	ELSE
		IF l_fullreport AND NOT(int_flag OR quit_flag) THEN 
			#------------------------------------------------------------
			FINISH REPORT GA9_rpt_list_full
			CALL rpt_finish("GA9_rpt_list_full")
			#------------------------------------------------------------		
		END IF 

		RETURN TRUE
	END IF 	
END FUNCTION 


###############################################################
# REPORT GA9_rpt_list(p_rec_accounthist )
#
#
###############################################################
REPORT GA9_rpt_list(p_rpt_idx,p_rec_accounthist )
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx] 
	DEFINE p_rec_accounthist RECORD LIKE accounthist.* 
	DEFINE l_rec_coa RECORD LIKE coa.*
	DEFINE l_ybud1_amt money(16,2) 
	DEFINE l_ybud2_amt money(16,2) 
	DEFINE l_ybud3_amt money(16,2) 
	DEFINE l_ybud4_amt money(16,2) 


	OUTPUT 
--	left margin 0 
	ORDER external BY p_rec_accounthist.acct_code, 
	p_rec_accounthist.year_num, p_rec_accounthist.period_num 

	FORMAT 

	######################
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 4, " -------- Budget", 
			COLUMN 20, " One ---------- ", 
			COLUMN 36, " -------- Budget", 
			COLUMN 52, " Two ---------- ", 
			COLUMN 68, " -------- Budget", 
			COLUMN 84, " Three -------- ", 
			COLUMN 100, " -------- Budget", 
			COLUMN 116, " Four ---------" 
			PRINT COLUMN 4, " Period ", 
			COLUMN 20, " Year TO Date ", 
			COLUMN 36, " Period ", 
			COLUMN 52, " Year TO Date ", 
			COLUMN 68, " Period ", 
			COLUMN 84, " Year TO Date ", 
			COLUMN 100, " Period ", 
			COLUMN 116, " Year TO Date" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]
 
		ON EVERY ROW 
			# get the ytd budget amt
			SELECT sum(budg1_amt), sum(budg2_amt), sum(budg3_amt), sum(budg4_amt) 
			INTO l_ybud1_amt, l_ybud2_amt, l_ybud3_amt, l_ybud4_amt 
			FROM accounthist 
			WHERE cmpy_code = p_rec_accounthist.cmpy_code 
			AND acct_code = p_rec_accounthist.acct_code 
			AND year_num = p_rec_accounthist.year_num 
			AND period_num <= p_rec_accounthist.period_num 
			# And finally IF I,L OR N THEN reverse signs
			IF l_rec_coa.type_ind = "I" OR l_rec_coa.type_ind = "L" 
			OR l_rec_coa.type_ind = "N" THEN 
				LET p_rec_accounthist.budg1_amt = 0 - p_rec_accounthist.budg1_amt + 0 
				LET p_rec_accounthist.budg2_amt = 0 - p_rec_accounthist.budg2_amt + 0 
				LET p_rec_accounthist.budg3_amt = 0 - p_rec_accounthist.budg3_amt + 0 
				LET p_rec_accounthist.budg4_amt = 0 - p_rec_accounthist.budg4_amt + 0 
				LET l_ybud1_amt = 0 - l_ybud1_amt + 0 
				LET l_ybud2_amt = 0 - l_ybud2_amt + 0 
				LET l_ybud3_amt = 0 - l_ybud3_amt + 0 
				LET l_ybud4_amt = 0 - l_ybud4_amt + 0 
			END IF 
			PRINT COLUMN 1, p_rec_accounthist.period_num USING "###", 
			COLUMN 4, p_rec_accounthist.budg1_amt USING "----,---,---,--&", 
			COLUMN 20, l_ybud1_amt USING "----,---,---,--&", 
			COLUMN 36, p_rec_accounthist.budg2_amt USING "----,---,---,--&", 
			COLUMN 52, l_ybud2_amt USING "----,---,---,--&", 
			COLUMN 68, p_rec_accounthist.budg3_amt USING "----,---,---,--&", 
			COLUMN 84, l_ybud3_amt USING "----,---,---,--&", 
			COLUMN 100, p_rec_accounthist.budg4_amt USING "----,---,---,--&", 
			COLUMN 116, l_ybud4_amt USING "----,---,---,--&" 

		ON LAST ROW 
			SKIP 1 line 

			SKIP 1 line 
			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 


		BEFORE GROUP OF p_rec_accounthist.acct_code 
			SELECT * 
			INTO l_rec_coa.* 
			FROM coa 
			WHERE cmpy_code = p_rec_accounthist.cmpy_code 
			AND acct_code = p_rec_accounthist.acct_code 
			SKIP 2 LINES 
			PRINT COLUMN 5, " Account: ", p_rec_accounthist.acct_code, 
			2 spaces, l_rec_coa.desc_text 

		BEFORE GROUP OF p_rec_accounthist.year_num 
			PRINT COLUMN 5, " Year: ", p_rec_accounthist.year_num USING "####" 
			SKIP 1 line 
END REPORT 


###############################################################
# REPORT GA9_rpt_list_full(p_rpt_idx,p_rec_accounthist )
#
#
###############################################################
REPORT GA9_rpt_list_full(p_rpt_idx,p_rec_accounthist )
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_accounthist RECORD LIKE accounthist.* 
	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_ybud5_amt money(16,2) 
	DEFINE l_ybud6_amt money(16,2) 

	OUTPUT 
--	left margin 0 
	ORDER external BY p_rec_accounthist.acct_code, 
	p_rec_accounthist.year_num, p_rec_accounthist.period_num 

	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 36, " -------- Budget", 
			COLUMN 52, " Five --------- ", 
			COLUMN 68, " -------- Budget", 
			COLUMN 84, " Six ---------- " 
			PRINT COLUMN 36, " Period ", 
			COLUMN 52, " Year TO Date ", 
			COLUMN 68, " Period ", 
			COLUMN 84, " Year TO Date " 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		ON EVERY ROW 
			# get the ytd budget amt
			SELECT sum(budg5_amt), sum(budg6_amt) 
			INTO l_ybud5_amt, l_ybud6_amt 
			FROM accounthist 
			WHERE cmpy_code = p_rec_accounthist.cmpy_code 
			AND acct_code = p_rec_accounthist.acct_code 
			AND year_num = p_rec_accounthist.year_num 
			AND period_num <= p_rec_accounthist.period_num 

			# And finally IF I,L OR N THEN reverse signs
			IF l_rec_coa.type_ind = "I" OR l_rec_coa.type_ind = "L" 
			OR l_rec_coa.type_ind = "N" THEN 
				LET p_rec_accounthist.budg5_amt = 0 - p_rec_accounthist.budg5_amt + 0 
				LET p_rec_accounthist.budg6_amt = 0 - p_rec_accounthist.budg6_amt + 0 
				LET l_ybud5_amt = 0 - l_ybud5_amt + 0 
				LET l_ybud6_amt = 0 - l_ybud6_amt + 0 
			END IF 

			PRINT COLUMN 1, p_rec_accounthist.period_num USING "###", 
			COLUMN 36, p_rec_accounthist.budg5_amt USING "----,---,---,--&", 
			COLUMN 52, l_ybud5_amt USING "----,---,---,--&", 
			COLUMN 68, p_rec_accounthist.budg6_amt USING "----,---,---,--&", 
			COLUMN 84, l_ybud6_amt USING "----,---,---,--&" 

		ON LAST ROW 
			SKIP 1 line 

			SKIP 1 line 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 

		BEFORE GROUP OF p_rec_accounthist.acct_code 
			SELECT * 
			INTO l_rec_coa.* 
			FROM coa 
			WHERE cmpy_code = p_rec_accounthist.cmpy_code 
			AND acct_code = p_rec_accounthist.acct_code 
			SKIP 2 LINES 
			PRINT COLUMN 5, " Account: ", p_rec_accounthist.acct_code, 
			2 spaces, l_rec_coa.desc_text 

		BEFORE GROUP OF p_rec_accounthist.year_num 
			PRINT COLUMN 5, " Year: ", p_rec_accounthist.year_num USING "####" 
			SKIP 1 line 

END REPORT 