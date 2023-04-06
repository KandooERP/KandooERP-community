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
# FUNCTION FUNCTION GA5_main()
#
# GA5  Budget Variation Report
############################################################
FUNCTION GA5_main()
	DEFER quit 
	DEFER interrupt 
	
	CALL setModuleId("GA1")

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 
		OPEN WINDOW G158 with FORM "G158" 
		CALL windecoration_g("G158") 
		CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
	
		MENU " Budget Variation" 
			BEFORE MENU 
				CALL publish_toolbar("kandoo","GA5","menu-budget-variation") 
				CALL GA5_rpt_process(GA5_rpt_query())
				CALL rpt_rmsreps_reset(NULL)
				
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
	
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
	
	
			ON ACTION "Report" 			#COMMAND "Report" " SELECT Criteria AND PRINT REPORT"
				CALL GA5_rpt_process(GA5_rpt_query())
				CALL rpt_rmsreps_reset(NULL)
	
			ON ACTION "Print Manager" 			#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
				CALL run_prog("URS","","","","") 
	
			ON ACTION "Exit" 		#COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus"
				EXIT MENU 
		END MENU 
	
		CLOSE WINDOW G158 

	 
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL GA5_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW G158 with FORM "G158" 
			CALL windecoration_g("G158") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(GA5_rpt_query()) #save where clause in env 
			CLOSE WINDOW G158 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL GA5_rpt_process(get_url_sel_text())
	END CASE
END FUNCTION 


############################################################
# FUNCTION GA5_rpt_query()
#
#
############################################################
FUNCTION GA5_rpt_query() 
	DEFINE l_where_text STRING
	DEFINE l_where2_text STRING
	DEFINE l_zero_suppress CHAR(1) 




	MESSAGE kandoomsg2("U",1001,"") 

	CONSTRUCT l_where_text ON coa.desc_text, 
	coa.type_ind, 
	coa.group_code, 
	accounthist.year_num , 
	accounthist.period_num 
	FROM coa.desc_text, 
	coa.type_ind, 
	coa.group_code, 
	account.year_num, 
	accounthist.period_num 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","GA5","construct-coa") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 



	IF int_flag OR quit_flag THEN
		LET int_flag = FALSE 
		RETURN NULL 
	ELSE
		LET l_where2_text = segment_con(glob_rec_kandoouser.cmpy_code, "accounthist")
	# add on the search dimension of segments.......
		IF l_where2_text IS NOT NULL THEN
			LET l_where_text = l_where_text clipped, l_where2_text
		END IF 
	END IF
	
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL
	ELSE

		LET glob_ans = choose_budget_number(1) 
		IF glob_ans NOT matches "[1-6]" 
		OR glob_ans IS NULL 
		OR int_flag 
		OR quit_flag THEN 
	
			ERROR kandoomsg2("U",9501,"") 
			#9501 Printing was aborted.
			RETURN false 
		END IF 
		LET glob_budg_num = glob_ans 
		
		LET l_zero_suppress = kandoomsg("U",8501,"") 
		LET l_zero_suppress = downshift(l_zero_suppress) 
	
		IF int_flag OR quit_flag THEN 
			ERROR kandoomsg2("U",9501,"") 
			#9501 Printing was aborted.
			RETURN false 
		END IF 

		LET glob_rec_rpt_selector.ref1_ind = glob_budg_num
		LET glob_rec_rpt_selector.ref2_ind = l_zero_suppress

		RETURN l_where_text
	END IF 
END FUNCTION

############################################################
# FUNCTION GA5_rpt_process(p_where_text) 
#
#
############################################################
FUNCTION GA5_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT  
	DEFINE l_exist SMALLINT 
	DEFINE l_rec_accounthist RECORD LIKE accounthist.* 
	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_zero_suppress CHAR(1) 
	DEFINE l_tmpmsg STRING 
	DEFINE l_msgresp LIKE language.yes_flag 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"GA5_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT GA5_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0
	LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GA5_rpt_list")].sel_text
	#------------------------------------------------------------

	LET glob_budg_num = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GA5_rpt_list")].ref1_ind
	LET l_zero_suppress = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GA5_rpt_list")].ref2_ind
		
	LET l_query_text = "SELECT accounthist.* ", 
	"FROM accounthist , coa ", 
	"WHERE coa.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
	" AND accounthist.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
	" AND coa.acct_code = accounthist.acct_code AND ", 
	glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GA5_rpt_list")].sel_text clipped, " ",
	" ORDER BY accounthist.acct_code,", 
	" accounthist.year_num, accounthist.period_num " 
	PREPARE s_accounthist FROM l_query_text 
	DECLARE c_accounthist CURSOR FOR s_accounthist 
{

	LET glob_ans = choose_budget_number(1) 
	IF glob_ans NOT matches "[1-6]" 
	OR glob_ans IS NULL 
	OR int_flag 
	OR quit_flag THEN 

		LET glob_msg_ans = kandoomsg("U",9501,"") 
		#9501 Printing was aborted.
		RETURN false 
	END IF 
	LET glob_budg_num = glob_ans 

	LET l_zero_suppress = kandoomsg("U",8501,"") 
	LET l_zero_suppress = downshift(l_zero_suppress) 

	IF int_flag OR quit_flag THEN 
		LET glob_msg_ans = kandoomsg("U",9501,"") 
		#9501 Printing was aborted.
		RETURN false 
	END IF 
}


	FOREACH c_accounthist INTO l_rec_accounthist.* 

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
				LET l_rec_accounthist.budg1_amt = l_rec_accounthist.budg2_amt 
			WHEN (glob_budg_num = 3) 
				LET l_rec_accounthist.budg1_amt = l_rec_accounthist.budg3_amt 
			WHEN (glob_budg_num = 4) 
				LET l_rec_accounthist.budg1_amt = l_rec_accounthist.budg4_amt 
			WHEN (glob_budg_num = 5) 
				LET l_rec_accounthist.budg1_amt = l_rec_accounthist.budg5_amt 
			WHEN (glob_budg_num = 6) 
				LET l_rec_accounthist.budg1_amt = l_rec_accounthist.budg6_amt 
		END CASE 
		#---------------------------------------------------------
		OUTPUT TO REPORT GA5_rpt_list(l_rpt_idx,l_rec_accounthist.*, l_zero_suppress ) 
		IF NOT rpt_int_flag_handler2("Account:",l_rec_accounthist.acct_code, NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------			

	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT GA5_rpt_list
	CALL rpt_finish("GA5_rpt_list")
	#------------------------------------------------------------
	
	IF int_flag THEN
		MESSAGE "Report Generation Canceled..."
		RETURN FALSE
	ELSE
		RETURN TRUE
	END IF 	
END FUNCTION 



############################################################
# REPORT GA5_rpt_list(p_rpt_idx,p_rec_accounthist,p_zero_suppress )
#
#
############################################################
REPORT GA5_rpt_list(p_rpt_idx,p_rec_accounthist,p_zero_suppress ) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_accounthist RECORD LIKE accounthist.* 
	DEFINE p_zero_suppress CHAR(1) 

	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_ybud_amt money(16,2)
	DEFINE l_yvar_amt money(16,2)
	DEFINE l_pvar_amt money(16,2)

	OUTPUT 

	left margin 0 
	#right margin
	#top margin
	#page length

	ORDER external BY p_rec_accounthist.acct_code, 
	p_rec_accounthist.year_num, p_rec_accounthist.period_num 

	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 

			PRINT COLUMN 1, "Year", 
			COLUMN 10, " ------------------ This Period ------------------------ ", 
			COLUMN 72, " ------------------ Year TO Date ----------------------- " 

			PRINT COLUMN 5, "Period", 
			COLUMN 14, "Actual", 
			COLUMN 34, "Budget ", glob_budg_num USING "<<<<", 
			COLUMN 54, "Variance", 
			COLUMN 74, "Actual", 
			COLUMN 94, " Budget ", glob_budg_num USING "<<<<", 
			COLUMN 114, "Variance" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		ON EVERY ROW 

			# get the ytd budget amt
			CASE glob_budg_num 
				WHEN (1) 
					SELECT sum(budg1_amt) 
					INTO l_ybud_amt 
					FROM accounthist 
					WHERE cmpy_code = p_rec_accounthist.cmpy_code 
					AND acct_code = p_rec_accounthist.acct_code 
					AND year_num = p_rec_accounthist.year_num 
					AND period_num <= p_rec_accounthist.period_num 

				WHEN (2) 
					SELECT sum(budg2_amt) 
					INTO l_ybud_amt 
					FROM accounthist 
					WHERE cmpy_code = p_rec_accounthist.cmpy_code 
					AND acct_code = p_rec_accounthist.acct_code 
					AND year_num = p_rec_accounthist.year_num 
					AND period_num <= p_rec_accounthist.period_num 

				WHEN (3) 
					SELECT sum(budg3_amt) 
					INTO l_ybud_amt 
					FROM accounthist 
					WHERE cmpy_code = p_rec_accounthist.cmpy_code 
					AND acct_code = p_rec_accounthist.acct_code 
					AND year_num = p_rec_accounthist.year_num 
					AND period_num <= p_rec_accounthist.period_num 

				WHEN (4) 
					SELECT sum(budg4_amt) 
					INTO l_ybud_amt 
					FROM accounthist 
					WHERE cmpy_code = p_rec_accounthist.cmpy_code 
					AND acct_code = p_rec_accounthist.acct_code 
					AND year_num = p_rec_accounthist.year_num 
					AND period_num <= p_rec_accounthist.period_num 

				WHEN (5) 
					SELECT sum(budg5_amt) 
					INTO l_ybud_amt 
					FROM accounthist 
					WHERE cmpy_code = p_rec_accounthist.cmpy_code 
					AND acct_code = p_rec_accounthist.acct_code 
					AND year_num = p_rec_accounthist.year_num 
					AND period_num <= p_rec_accounthist.period_num 

				WHEN (6) 
					SELECT sum(budg6_amt) 
					INTO l_ybud_amt 
					FROM accounthist 
					WHERE cmpy_code = p_rec_accounthist.cmpy_code 
					AND acct_code = p_rec_accounthist.acct_code 
					AND year_num = p_rec_accounthist.year_num 
					AND period_num <= p_rec_accounthist.period_num 
			END CASE 
			# And finally IF I,L OR N THEN reverse signs
			IF l_rec_coa.type_ind = "I" 
			OR l_rec_coa.type_ind = "L" 
			OR l_rec_coa.type_ind = "N" 
			THEN 
				LET p_rec_accounthist.ytd_pre_close_amt = 0 - p_rec_accounthist.ytd_pre_close_amt + 0 
				LET p_rec_accounthist.pre_close_amt = 0 - p_rec_accounthist.pre_close_amt + 0 
				LET p_rec_accounthist.budg1_amt = 0 - p_rec_accounthist.budg1_amt + 0 
				LET l_ybud_amt = 0 - l_ybud_amt + 0 
			END IF 

			# now work out the variances
			LET l_pvar_amt = p_rec_accounthist.pre_close_amt - p_rec_accounthist.budg1_amt 
			LET l_yvar_amt = p_rec_accounthist.ytd_pre_close_amt - l_ybud_amt 

			IF p_rec_accounthist.pre_close_amt = 0 AND 
			p_rec_accounthist.budg1_amt = 0 AND 
			l_pvar_amt = 0 AND 
			p_rec_accounthist.ytd_pre_close_amt = 0 AND 
			l_ybud_amt = 0 AND 
			l_yvar_amt = 0 AND 
			p_zero_suppress = "y" THEN 
			ELSE 
				PRINT COLUMN 1, p_rec_accounthist.year_num USING "####", 
				COLUMN 6, p_rec_accounthist.period_num USING "###", 
				COLUMN 10, p_rec_accounthist.pre_close_amt USING "----,---,---,--&.&&", 
				COLUMN 30, p_rec_accounthist.budg1_amt USING "----,---,---,--&.&&", 
				COLUMN 50, l_pvar_amt USING "----,---,---,--&.&&", 
				COLUMN 70, p_rec_accounthist.ytd_pre_close_amt 
				USING "----,---,---,--&.&&", 
				COLUMN 90, l_ybud_amt USING "----,---,---,--&.&&", 
				COLUMN 110, l_yvar_amt USING "----,---,---,--&.&&" 
			END IF 

		ON LAST ROW 
			SKIP 1 line 
			PRINT COLUMN 1, "Report Totals:" 
			PRINT COLUMN 10, sum(p_rec_accounthist.pre_close_amt) 
			USING "----,---,---,--&.&&", 
			COLUMN 30, sum(p_rec_accounthist.budg1_amt) 
			USING "----,---,---,--&.&&", 
			COLUMN 50, sum(p_rec_accounthist.pre_close_amt - p_rec_accounthist.budg1_amt) 
			USING "----,---,---,--&.&&" 
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
			PRINT COLUMN 5, " Account: ", p_rec_accounthist.acct_code , 
			2 spaces, l_rec_coa.desc_text 


		BEFORE GROUP OF p_rec_accounthist.year_num 
			SKIP 1 line 

END REPORT 
