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
GLOBALS "../gl/GR_GROUP_GLOBALS.4gl"
GLOBALS "../gl/GRA_GLOBALS.4gl" 
GLOBALS 
	DEFINE glob_rec_coa RECORD LIKE coa.* 
END GLOBALS
 
############################################################
# MODULEL Scope Variables
############################################################
--	DEFINE modu_line1 CHAR(130) 
--	DEFINE modu_line2 CHAR(130) 
	DEFINE modu_rept_curr_code LIKE currency.currency_code 
	DEFINE modu_conv_qty LIKE rate_exchange.conv_sell_qty 
	DEFINE modu_msg_ans CHAR(1) 
--	DEFINE modu_ans CHAR(1) 
	DEFINE modu_q1_text CHAR(500) 
--	DEFINE modu_where_part STRING 
--	DEFINE modu_query_text CHAR(890) 


############################################################
# FUNCTION GRA_main()
#
# Trial Balance Report
############################################################
FUNCTION GRA_main() 
	DEFER quit 
	DEFER interrupt 

	CALL setModuleId("GRA") 


	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 
			OPEN WINDOW G188 with FORM "G188" 
			CALL windecoration_g("G188") 
		
			MENU "Trial Balance " 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","GRA","menu-trial-balance") 
					CALL GRA_rpt_process(GRA_rpt_query())
					CALL rpt_rmsreps_reset(NULL)
					
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				ON ACTION "Report" #COMMAND "Report" " SELECT criteria AND PRINT REPORT"
					CALL GRA_rpt_process(GRA_rpt_query())
					CALL rpt_rmsreps_reset(NULL)
		
				ON ACTION "Print Manager" 		#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "Exit" 		#COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus"
					EXIT MENU 
		
			END MENU 
		
			CLOSE WINDOW G188 

		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL GRA_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW G188 with FORM "G188" 
			CALL windecoration_g("G188") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(GRA_rpt_query()) #save where clause in env 
			CLOSE WINDOW G188 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL GRA_rpt_process(get_url_sel_text())
	END CASE 				
END FUNCTION 


############################################################
# FUNCTION GRA_rpt_query()
#
#
############################################################
FUNCTION GRA_rpt_query() 
	DEFINE l_where_text STRING
	DEFINE l_rec_accounthist RECORD LIKE accounthist.* 
	DEFINE l_rec_accounthistcur RECORD LIKE accounthistcur.* 
	DEFINE l_exist SMALLINT 
	DEFINE l_count int 
	DEFINE l_print_over_two_lines CHAR(1) 
	DEFINE l_Print_Account_Total CHAR(1)

	MESSAGE kandoomsg2("U",1001,"") 
	IF glob_rec_glparms.use_currency_flag != "Y" THEN 
		CONSTRUCT BY NAME l_where_text ON year_num, period_num 
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","GRA","construct-year1") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null)
				 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
		END CONSTRUCT 

	ELSE 
		CONSTRUCT BY NAME l_where_text ON year_num, period_num, currency_code 
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","GRA","construct-year2") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
		END CONSTRUCT 

	END IF 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		MESSAGE "Report Query aborted"
		RETURN NULL 
	END IF
	
	# add on the search dimension of segments.......
	IF l_where_text matches "*currency_code*" THEN #user entered currency code in filter/construct 
		CALL segment_con(glob_rec_kandoouser.cmpy_code, "accounthistcur") RETURNING modu_q1_text 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			RETURN false 
		END IF 
	ELSE #user did NOT enter any currency code in filter/construct 
		CALL segment_con(glob_rec_kandoouser.cmpy_code, "accounthist") RETURNING modu_q1_text 
		LET modu_conv_qty = 1 
		LET modu_rept_curr_code = glob_rec_glparms.base_currency_code 
	END IF 
	LET l_where_text = l_where_text clipped, " ", modu_q1_text 

	LET l_Print_Account_Total = kandoomsg("G",3512,"") 
	#3512 Print Account Total? (Y/N):
	LET l_Print_Account_Total = upshift(l_Print_Account_Total) 
	IF l_Print_Account_Total IS NULL OR l_Print_Account_Total <> "N" THEN 
		LET l_Print_Account_Total = "Y" 
	END IF 

	# Determine IF user wants detail lines over 1 OR two lines
	LET modu_msg_ans = kandoomsg("G",3520,"") 
	#3520 Print over Two lines (Y/N):
	LET l_print_over_two_lines = upshift(modu_msg_ans) 
	IF l_print_over_two_lines IS NULL OR l_print_over_two_lines <> "N" THEN 
		LET l_print_over_two_lines = "Y" 
	END IF 
	
	IF int_flag THEN
		RETURN NULL
	ELSE
		LET glob_rec_rpt_selector.ref1_ind = l_Print_Account_Total
		LET glob_rec_rpt_selector.ref2_ind = l_print_over_two_lines
		RETURN l_where_text
	END IF
END FUNCTION


############################################################
# FUNCTION GRA_rpt_process() 
#
#
############################################################
FUNCTION GRA_rpt_process(p_where_text)
	DEFINE p_where_text STRING 
	DEFINE l_rpt_idx SMALLINT  
	DEFINE l_query_text STRING 
	DEFINE l_rec_accounthist RECORD LIKE accounthist.* 
	DEFINE l_rec_accounthistcur RECORD LIKE accounthistcur.* 
	DEFINE l_exist SMALLINT 
	DEFINE l_count int 
	DEFINE l_print_over_two_lines CHAR(1) 
	DEFINE l_Print_Account_Total CHAR(1)

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false
		RETURN FALSE
	END IF
	#------------------------------------------------------------

	LET l_Print_Account_Total = glob_rec_rpt_selector.ref1_ind
	LET l_print_over_two_lines = glob_rec_rpt_selector.ref2_ind
			



	IF p_where_text matches "*currency_code*" THEN 


		#------------------------------------------------------------
		LET l_rpt_idx = rpt_start(getmoduleid(),"GRA_rpt_list_curr",p_where_text, RPT_SHOW_RMS_DIALOG)
		IF l_rpt_idx = 0 THEN #User pressed CANCEL
			RETURN FALSE
		END IF	
		START REPORT GRA_rpt_list_curr TO rpt_get_report_file_with_path2(l_rpt_idx)
		WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0
		LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GRA_rpt_list_curr")].sel_text
		#------------------------------------------------------------


		LET l_query_text = "SELECT * ", 
		"FROM accounthistcur ", 
		"WHERE cmpy_code = \"", glob_rec_kandoouser.cmpy_code, "\" AND ", 
		glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GRA_rpt_list_curr")].sel_text clipped, " ", 
		"ORDER BY currency_code, acct_code,", 
		"year_num, period_num " 
		PREPARE curr_choice FROM l_query_text 
		DECLARE curr_set CURSOR FOR curr_choice 
		OPEN curr_set 

		FOREACH curr_set INTO l_rec_accounthistcur.* 
			#---------------------------------------------------------
			OUTPUT TO REPORT GRA_rpt_list_curr(l_rpt_idx,l_rec_accounthistcur.*, glob_rec_glparms.*,l_print_over_two_lines,l_Print_Account_Total) 
			IF NOT rpt_int_flag_handler2("Account:",l_rec_accounthistcur.acct_code, NULL,l_rpt_idx) THEN
				EXIT FOREACH 
			END IF 
			#---------------------------------------------------------		
		END FOREACH 

		#------------------------------------------------------------
		FINISH REPORT GRA_rpt_list_curr
		CALL rpt_finish("GRA_rpt_list_curr")
		#------------------------------------------------------------

	ELSE 

		#------------------------------------------------------------
		LET l_rpt_idx = rpt_start(getmoduleid(),"GRA_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
		IF l_rpt_idx = 0 THEN #User pressed CANCEL
			RETURN FALSE
		END IF	
		START REPORT GRA_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
		WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0
		LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GRA_rpt_list")].sel_text
		#------------------------------------------------------------

		#      OPEN WINDOW wfGL WITH FORM "U999" ATTRIBUTES(BORDER)
		#		CALL windecoration_u("U999")


		LET l_query_text = "SELECT * ", 
		"FROM accounthist ", 
		"WHERE cmpy_code = \"", glob_rec_kandoouser.cmpy_code, "\" AND ", 
		glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GRA_rpt_list")].sel_text clipped, " ", 
		" ORDER BY acct_code, year_num, period_num " 
		PREPARE base_choice FROM l_query_text 
		DECLARE base_set CURSOR FOR base_choice 
		OPEN base_set 

		LET l_count = 0 
		FOREACH base_set INTO l_rec_accounthist.* # convert VALUES using conversion rate 
			#---------------------------------------------------------
			OUTPUT TO REPORT GRA_rpt_list(l_rpt_idx,l_rec_accounthist.*, glob_rec_glparms.*,l_print_over_two_lines,l_Print_Account_Total)  
			IF NOT rpt_int_flag_handler2("Account:",l_rec_accounthist.acct_code, NULL,l_rpt_idx) THEN
				EXIT FOREACH 
			END IF 
			#---------------------------------------------------------		
			LET l_count = l_count + 1 
		END FOREACH 

		IF l_count > 0 THEN 
			MESSAGE "Report with ", trim(l_count), " rows processed" 
		ELSE 
			ERROR "Report for company <", trim(glob_rec_kandoouser.cmpy_code), ">, with ", trim(p_where_text), " has ", trim(l_count), " rows (NONE) processed" 
			SLEEP 2 
		END IF

		#------------------------------------------------------------
		FINISH REPORT GRA_rpt_list
		CALL rpt_finish("GRA_rpt_list")
		#------------------------------------------------------------		 
	END IF 
	
	IF int_flag THEN
		MESSAGE "Report Generation Canceled..."
		RETURN FALSE
	ELSE
		RETURN TRUE
	END IF 	  
END FUNCTION 


############################################################
# REPORT GRA_rpt_list(p_rec_accounthist, p_rec_glparms, p_two_lines )
#
#
############################################################
REPORT GRA_rpt_list(p_rpt_idx,p_rec_accounthist, p_rec_glparms, p_two_lines,p_Print_Account_Total ) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_accounthist RECORD LIKE accounthist.* 
	DEFINE p_rec_glparms RECORD LIKE glparms.* 
	DEFINE p_two_lines CHAR(1) 
	DEFINE p_Print_Account_Total CHAR(1)
	DEFINE l_sum_open_amt DECIMAL(16,2) 
	DEFINE l_sum_debit_amt DECIMAL(16,2) 
	DEFINE l_sum_credit_amt DECIMAL(16,2) 
	DEFINE l_sum_close_amt DECIMAL(16,2) 
	DEFINE l_tot_chr_close_amt CHAR(20) 
	DEFINE l_tot_chr_open_amt CHAR(20) 
	DEFINE l_grp_chr_close_amt CHAR(20) 
	DEFINE l_grp_chr_open_amt CHAR(20) 
	DEFINE l_chr_close_amt CHAR(20) 
	DEFINE l_chr_open_amt CHAR(20) 
	#DEFINE l_yy DECIMAL(4,0)
	DEFINE l_summary_only CHAR(1) 
	DEFINE l_tempchar800 nchar(800) 

	OUTPUT 
--	left margin 0 
	ORDER BY p_rec_accounthist.acct_code, 
	p_rec_accounthist.year_num, 
	p_rec_accounthist.period_num 

	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 01, "Values in Currency: ", modu_rept_curr_code  
			PRINT COLUMN 01, "Exchange rate : ", modu_conv_qty USING "<<<.<<<" 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  

			IF p_two_lines = "Y" THEN 
				PRINT COLUMN 1, "Account", 
				COLUMN 36, "Year", 
				COLUMN 54, "Opening", 
				COLUMN 74, "Period", 
				COLUMN 94, "Period", 
				COLUMN 114, "Ending" 
				PRINT COLUMN 1, "Number", 
				COLUMN 15, "Description", 
				COLUMN 40, "Period", 
				COLUMN 54, "Balance", 
				COLUMN 74, "Debits", 
				COLUMN 94, "Credits", 
				COLUMN 114, "Balance" 
			ELSE 
				PRINT COLUMN 1, "Account" , 
				COLUMN 45, "Year", 
				COLUMN 61, "Opening", 
				COLUMN 81, "Period", 
				COLUMN 101,"Period", 
				COLUMN 119, "Ending" 
				PRINT COLUMN 1, "Number", 
				COLUMN 20, "Description", 
				COLUMN 50, "Period", 
				COLUMN 61, "Balance", 
				COLUMN 81, "Debits", 
				COLUMN 101,"Credits", 
				COLUMN 119, "Balance" 
			END IF 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  

		ON EVERY ROW 
			NEED 5 LINES 
			SELECT * INTO glob_rec_coa.* 
			FROM coa 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND acct_code = p_rec_accounthist.acct_code 

			IF p_rec_accounthist.open_amt != 0 OR p_rec_accounthist.debit_amt != 0 
			OR p_rec_accounthist.credit_amt != 0 OR p_rec_accounthist.close_amt != 0 THEN 
				LET l_chr_open_amt = ac_form(glob_rec_kandoouser.cmpy_code, p_rec_accounthist.open_amt, 
				glob_rec_coa.type_ind, 
				p_rec_glparms.style_ind) 
				LET l_chr_close_amt = ac_form(glob_rec_kandoouser.cmpy_code, p_rec_accounthist.close_amt, 
				glob_rec_coa.type_ind, 
				p_rec_glparms.style_ind) 

				IF p_two_lines = "Y" THEN 
					PRINT COLUMN 1, p_rec_accounthist.acct_code , 
					COLUMN 36, p_rec_accounthist.year_num USING "####", 
					COLUMN 41, p_rec_accounthist.period_num USING "###", 
					COLUMN 45, l_chr_open_amt, 
					COLUMN 66, p_rec_accounthist.debit_amt USING "----,---,---,--&.&&", 
					COLUMN 86, p_rec_accounthist.credit_amt USING "----,---,---,--&.&&", 
					COLUMN 106, l_chr_close_amt 
					PRINT COLUMN 15, glob_rec_coa.desc_text[1,40] 

				ELSE 
					PRINT COLUMN 1, p_rec_accounthist.acct_code , 
					COLUMN 20, glob_rec_coa.desc_text[1,25], 
					COLUMN 45, p_rec_accounthist.year_num USING "####", 
					COLUMN 50, p_rec_accounthist.period_num USING "###", 
					COLUMN 54, l_chr_open_amt, 
					COLUMN 74, p_rec_accounthist.debit_amt USING "----,---,---,--&.&&", 
					COLUMN 94, p_rec_accounthist.credit_amt USING "----,---,---,--&.&&", 
					COLUMN 114, l_chr_close_amt 
				END IF 
			END IF 

		ON LAST ROW 
			SKIP 1 line 
			LET l_tot_chr_open_amt = ac_form(glob_rec_kandoouser.cmpy_code, sum(p_rec_accounthist.open_amt), 
			glob_rec_coa.type_ind, 
			p_rec_glparms.style_ind) 
			LET l_tot_chr_close_amt = ac_form(glob_rec_kandoouser.cmpy_code, sum(p_rec_accounthist.close_amt), 
			glob_rec_coa.type_ind, 
			p_rec_glparms.style_ind) 


			IF p_two_lines = "Y" THEN 
				PRINT COLUMN 1, "Grand Total:", 
				COLUMN 45, l_tot_chr_open_amt , 
				COLUMN 66, sum(p_rec_accounthist.debit_amt) 
				USING "----,---,---,--&.&&", 
				COLUMN 86, sum(p_rec_accounthist.credit_amt) 
				USING "----,---,---,--&.&&", 
				COLUMN 106,l_tot_chr_close_amt 
			ELSE 
				PRINT COLUMN 1, "Grand Total:", 
				COLUMN 54, l_tot_chr_open_amt , 
				COLUMN 74, sum(p_rec_accounthist.debit_amt) 
				USING "----,---,---,--&.&&", 
				COLUMN 94 ,sum(p_rec_accounthist.credit_amt) 
				USING "----,---,---,--&.&&", 
				COLUMN 114,l_tot_chr_close_amt 
			END IF 
			SKIP 1 line 
			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4]

		AFTER GROUP OF p_rec_accounthist.acct_code 
			IF p_Print_Account_Total = "Y" AND 
			(group sum(p_rec_accounthist.open_amt) != 0 OR 
			GROUP sum(p_rec_accounthist.debit_amt) != 0 OR 
			GROUP sum(p_rec_accounthist.credit_amt) != 0 OR 
			GROUP sum(p_rec_accounthist.close_amt) != 0) THEN 
				LET l_grp_chr_open_amt = ac_form(glob_rec_kandoouser.cmpy_code,group sum(p_rec_accounthist.open_amt), 
				glob_rec_coa.type_ind, 
				p_rec_glparms.style_ind) 
				LET l_grp_chr_close_amt=ac_form(glob_rec_kandoouser.cmpy_code,group sum(p_rec_accounthist.close_amt), 
				glob_rec_coa.type_ind, 
				p_rec_glparms.style_ind) 


				IF p_two_lines = "Y" THEN 
					PRINT COLUMN 1, "Account Total:", 
					COLUMN 45, l_grp_chr_open_amt , 
					COLUMN 66, GROUP sum(p_rec_accounthist.debit_amt) 
					USING "----,---,---,--&.&&", 
					COLUMN 86, GROUP sum(p_rec_accounthist.credit_amt) 
					USING "----,---,---,--&.&&", 
					COLUMN 106,l_grp_chr_close_amt 
				ELSE 
					PRINT COLUMN 1, "Account Total:", 
					COLUMN 54, l_grp_chr_open_amt , 
					COLUMN 74, GROUP sum(p_rec_accounthist.debit_amt) 
					USING "----,---,---,--&.&&", 
					COLUMN 94, GROUP sum(p_rec_accounthist.credit_amt) 
					USING "----,---,---,--&.&&", 
					COLUMN 114,l_grp_chr_close_amt 
				END IF 
				SKIP 1 LINES 
			END IF 
END REPORT 


############################################################
# REPORT GRA_rpt_list_curr(p_rpt_idx,p_rec_accounthistcur, p_rec_glparms,p_two_lines )
#
#
############################################################
REPORT GRA_rpt_list_curr(p_rpt_idx,p_rec_accounthistcur, p_rec_glparms,p_two_lines,p_Print_Account_Total )
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx] 
	DEFINE p_rec_accounthistcur RECORD LIKE accounthistcur.* 
	DEFINE p_rec_glparms RECORD LIKE glparms.* 
	DEFINE p_two_lines CHAR(1) 
	DEFINE p_Print_Account_Total CHAR(1)

	DEFINE l_sum_open_amt DECIMAL(16,2) 
	#DEFINE l_sum_debit_amtt DECIMAL(16,2)
	DEFINE l_sum_credit_amt DECIMAL(16,2) 
	DEFINE l_sum_close_amt DECIMAL(16,2) 

	DEFINE l_tot_chr_close_amt CHAR(20) 
	DEFINE l_tot_chr_open_amt CHAR(20) 
	DEFINE l_grp_chr_close_amt CHAR(20) 

	DEFINE l_grp_chr_open_amt CHAR(20) 
	DEFINE l_chr_close_amt CHAR(20) 
	DEFINE l_chr_open_amt CHAR(20) 

	#DEFINE l_yy DECIMAL(4,0)
	DEFINE l_summary_only CHAR(1) 

	OUTPUT 
	left margin 0 
	ORDER BY p_rec_accounthistcur.currency_code, 
	p_rec_accounthistcur.acct_code, 
	p_rec_accounthistcur.year_num, 
	p_rec_accounthistcur.period_num 
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 

			PRINT COLUMN 01, "Values in Currency: ", p_rec_accounthistcur.currency_code 

			IF p_two_lines = "Y" THEN 
				PRINT COLUMN 1, "Account", 
				COLUMN 36, "Year", 
				COLUMN 53, "Opening", 
				COLUMN 74, "Period", 
				COLUMN 94, "Period", 
				COLUMN 114, "Ending" 
				PRINT COLUMN 1, "Number", 
				COLUMN 15, "Description", 
				COLUMN 40, "Period", 
				COLUMN 53, "Balance", 
				COLUMN 74, "Debits", 
				COLUMN 94, "Credits", 
				COLUMN 114, "Balance" 
			ELSE 
				PRINT COLUMN 1, "Account" , 
				COLUMN 60, "Year", 
				COLUMN 76, "Opening", 
				COLUMN 96, "Period", 
				COLUMN 116,"Period", 
				COLUMN 134, "Ending" 
				PRINT COLUMN 1, "Number", 
				COLUMN 20, "Description", 
				COLUMN 65, "Period", 
				COLUMN 76, "Balance", 
				COLUMN 96, "Debits", 
				COLUMN 116,"Credits", 
				COLUMN 134, "Balance" 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		ON EVERY ROW 
			SELECT * INTO glob_rec_coa.* 
			FROM coa 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND acct_code = p_rec_accounthistcur.acct_code 
			IF p_rec_accounthistcur.open_amt != 0 OR p_rec_accounthistcur.debit_amt != 0 
			OR p_rec_accounthistcur.credit_amt != 0 OR p_rec_accounthistcur.close_amt != 0 THEN 
				LET l_chr_open_amt = ac_form(glob_rec_kandoouser.cmpy_code, p_rec_accounthistcur.open_amt, 
				glob_rec_coa.type_ind, 
				p_rec_glparms.style_ind) 
				LET l_chr_close_amt = ac_form(glob_rec_kandoouser.cmpy_code, p_rec_accounthistcur.close_amt, 
				glob_rec_coa.type_ind, 
				p_rec_glparms.style_ind) 

				IF p_two_lines = "Y" THEN 
					PRINT COLUMN 1, p_rec_accounthistcur.acct_code , 
					COLUMN 36, p_rec_accounthistcur.year_num USING "####", 
					COLUMN 41, p_rec_accounthistcur.period_num USING "###", 
					COLUMN 45, l_chr_open_amt, 
					COLUMN 66, p_rec_accounthistcur.debit_amt USING "----,---,---,--&.&&", 
					COLUMN 86, p_rec_accounthistcur.credit_amt USING "----,---,---,--&.&&", 
					COLUMN 106, l_chr_close_amt 
					PRINT COLUMN 15, glob_rec_coa.desc_text[1,40] 
				ELSE 
					PRINT COLUMN 1, p_rec_accounthistcur.acct_code , 
					COLUMN 20, glob_rec_coa.desc_text[1,40], 
					COLUMN 45, p_rec_accounthistcur.year_num USING "####", 
					COLUMN 50, p_rec_accounthistcur.period_num USING "###", 
					COLUMN 54, l_chr_open_amt, 
					COLUMN 74, p_rec_accounthistcur.debit_amt USING "----,---,---,--&.&&", 
					COLUMN 94, p_rec_accounthistcur.credit_amt USING "----,---,---,--&.&&", 
					COLUMN 114, l_chr_close_amt 
				END IF 


				LET glob_rec_coa.desc_text = NULL 
			END IF 

		ON LAST ROW 
			SKIP 1 line 
			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 


		BEFORE GROUP OF p_rec_accounthistcur.currency_code 
			SKIP TO top OF PAGE 
			PRINT COLUMN 1, "Currency : ", 
			COLUMN 12, p_rec_accounthistcur.currency_code 
			SKIP 1 line 

		AFTER GROUP OF p_rec_accounthistcur.currency_code 
			SKIP 1 line 
			LET l_tot_chr_open_amt = ac_form(glob_rec_kandoouser.cmpy_code, 
			GROUP sum(p_rec_accounthistcur.open_amt), 
			glob_rec_coa.type_ind, 
			p_rec_glparms.style_ind) 
			LET l_tot_chr_close_amt = ac_form(glob_rec_kandoouser.cmpy_code, 
			GROUP sum(p_rec_accounthistcur.close_amt), 
			glob_rec_coa.type_ind, 
			p_rec_glparms.style_ind) 


			IF p_two_lines = "Y" THEN 
				PRINT COLUMN 1, "Grand Total:", 
				COLUMN 45, l_tot_chr_open_amt , 
				COLUMN 66, GROUP sum(p_rec_accounthistcur.debit_amt) 
				USING "----,---,---,--&.&&", 
				COLUMN 86, GROUP sum(p_rec_accounthistcur.credit_amt) 
				USING "----,---,---,--&.&&", 
				COLUMN 106,l_tot_chr_close_amt 
			ELSE 
				PRINT COLUMN 1, "Grand Total:", 
				COLUMN 54, l_tot_chr_open_amt , 
				COLUMN 74, GROUP sum(p_rec_accounthistcur.debit_amt) 
				USING "----,---,---,--&.&&", 
				COLUMN 94 ,group sum(p_rec_accounthistcur.credit_amt) 
				USING "----,---,---,--&.&&", 
				COLUMN 114,l_tot_chr_close_amt 
			END IF 

		AFTER GROUP OF p_rec_accounthistcur.acct_code 
			IF p_Print_Account_Total = "Y" AND 
			(group sum(p_rec_accounthistcur.open_amt) != 0 OR 
			GROUP sum(p_rec_accounthistcur.debit_amt) != 0 OR 
			GROUP sum(p_rec_accounthistcur.credit_amt) != 0 OR 
			GROUP sum(p_rec_accounthistcur.close_amt) != 0) THEN 
				LET l_grp_chr_open_amt = ac_form(glob_rec_kandoouser.cmpy_code,group sum(p_rec_accounthistcur.open_amt), 
				glob_rec_coa.type_ind, 
				p_rec_glparms.style_ind) 
				LET l_grp_chr_close_amt=ac_form(glob_rec_kandoouser.cmpy_code,group sum(p_rec_accounthistcur.close_amt), 
				glob_rec_coa.type_ind, 
				p_rec_glparms.style_ind) 


				IF p_two_lines = "Y" THEN 
					PRINT COLUMN 1, "Account Total:", 
					COLUMN 45, l_grp_chr_open_amt, 
					COLUMN 66, GROUP sum(p_rec_accounthistcur.debit_amt) 
					USING "----,---,---,--&.&&", 
					COLUMN 86, GROUP sum(p_rec_accounthistcur.credit_amt) 
					USING "----,---,---,--&.&&", 
					COLUMN 106,l_grp_chr_close_amt 
				ELSE 
					PRINT COLUMN 1, "Account Total:", 
					COLUMN 54, l_grp_chr_open_amt, 
					COLUMN 74, GROUP sum(p_rec_accounthistcur.debit_amt) 
					USING "----,---,---,--&.&&", 
					COLUMN 94, GROUP sum(p_rec_accounthistcur.credit_amt) 
					USING "----,---,---,--&.&&", 
					COLUMN 114,l_grp_chr_close_amt 
				END IF 
				SKIP 1 LINES 
			END IF 
END REPORT