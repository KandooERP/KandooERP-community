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
DEFINE modu_income CHAR(1)
DEFINE modu_expense CHAR(1)
DEFINE modu_asset CHAR(1)
DEFINE modu_rec_purchdetl RECORD LIKE purchdetl.* 
DEFINE modu_rec_poaudit RECORD LIKE poaudit.* 
DEFINE modu_inc_used money(16,2) 
DEFINE modu_inc_avail money(16,2) 
DEFINE modu_inc_commit money(16,2) 

DEFINE modu_tot_used money(16,2) 
DEFINE modu_tot_avail money(16,2) 
DEFINE modu_tot_commit money(16,2) 

DEFINE modu_avail_amt money(16,2) 
DEFINE modu_used_amt money(16,2) 
DEFINE modu_commit_amt money(16,2) 

DEFINE modu_active_flag SMALLINT 
DEFINE modu_temp_year INTEGER 
DEFINE modu_temp_period INTEGER 

###############################################################
# FUNCTION GA6_main()
#
#  GA6  Available Funds Report
###############################################################
FUNCTION GA6_main() 
	DEFER quit 
	DEFER interrupt 
	
	CALL setModuleId("GA6")

	LET modu_income = "I" 
	LET modu_expense = "E" 
	LET modu_asset = "A" 

	LET modu_tot_used = 0 
	LET modu_tot_avail = 0 
	LET modu_tot_commit = 0 
	LET modu_inc_used = 0 
	LET modu_inc_avail = 0 
	LET modu_inc_commit = 0 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 	
			OPEN WINDOW G158 with FORM "G158" 
			CALL windecoration_g("G158") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
		
			MENU "Available Funds Report " 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","GA6","menu-avail-funds-rep") 
					CALL GA6_rpt_process(GA6_rpt_query())
					CALL rpt_rmsreps_reset(NULL)
					
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
		
				ON ACTION "Report"	#COMMAND "Report" " SELECT crite7ria AND PRINT REPORT"
					CALL GA6_rpt_process(GA6_rpt_query())
					CALL rpt_rmsreps_reset(NULL)
		
				ON ACTION "Print Manager" 			#COMMAND KEY ("P",f11) "Print" "Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "Exit" 		#COMMAND KEY(interrupt, "E") "Exit" "Exit this program"
					EXIT MENU 
 
			END MENU 
		
			CLOSE WINDOW G158 
	 
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL GA6_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW G158 with FORM "G158" 
			CALL windecoration_g("G158") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(GA6_rpt_query()) #save where clause in env 
			CLOSE WINDOW G158 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL GA6_rpt_process(get_url_sel_text())
	END CASE 
END FUNCTION 


###############################################################
# FUNCTION GA6_rpt_query()
#
#
###############################################################
FUNCTION GA6_rpt_query() 
	DEFINE l_where_text STRING
	DEFINE l_where2_text STRING	
	DEFINE l_rec_account RECORD LIKE account.* 
	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_tmpmsg STRING 

	MESSAGE kandoomsg2("U",1001,"") #1001 Enter Selection Criteria

	CONSTRUCT BY NAME l_where_text ON coa.desc_text, 
	coa.type_ind, 
	coa.group_code 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","GA6","construct-coa") 

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

	# add on the search dimension of segments.......
	LET l_where2_text =  segment_con(glob_rec_kandoouser.cmpy_code, "coa") 
	IF l_where2_text IS NULL THEN 
		RETURN NULL
	ELSE
		LET l_where_text = l_where_text clipped, " ", l_where2_text 
	END IF 

	OPEN WINDOW G187 with FORM "G187" 
	CALL windecoration_g("G187") 

	INPUT modu_temp_year,	glob_budg_num 
	FROM account.year_num,formonly.budg_num 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GA6","inp-budget") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null)
			 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE FIELD year_num 
			CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,today) 
			RETURNING modu_temp_year, modu_temp_period 
			DISPLAY modu_temp_year TO account.year_num 

		AFTER FIELD year_num 
			IF modu_temp_year IS NULL THEN 
				ERROR kandoomsg2("A",9102,"") 
				NEXT FIELD year_num 
			END IF 

	END INPUT 

	CLOSE WINDOW G187 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL
	ELSE
		LET glob_rec_rpt_selector.ref1_num = modu_temp_year
		LET glob_rec_rpt_selector.ref2_num = modu_temp_period
		LET glob_rec_rpt_selector.ref3_num = glob_budg_num
		RETURN l_where_text
	END IF 

END FUNCTION

	
###############################################################
# FUNCTION GA6_rpt_process() 
#
#
###############################################################
FUNCTION GA6_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT  
	DEFINE l_rec_account RECORD LIKE account.* 
	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_tmpmsg STRING 


	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"GA6_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT GA6_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0
	LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GA6_rpt_list")].sel_text
	#------------------------------------------------------------


	LET modu_temp_year = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GA6_rpt_list")].ref1_num 
	LET modu_temp_period = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GA6_rpt_list")].ref2_num 
	LET glob_budg_num = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GA6_rpt_list")].ref3_num 
				 
	LET l_query_text = "SELECT coa.* ", 
	"FROM coa ", 
	"WHERE coa.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' AND ", 
	glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GA6_rpt_list")].sel_text clipped, " ",
	"ORDER BY coa.type_ind desc, coa.acct_code " 

	PREPARE s_coa FROM l_query_text 
	DECLARE c_coa CURSOR FOR s_coa 


	FOREACH c_coa INTO l_rec_coa.* 
		LET modu_active_flag = 0 
		IF l_rec_coa.type_ind = "I" 
		OR l_rec_coa.type_ind = "E" 
		OR l_rec_coa.type_ind = "A" THEN 

			INITIALIZE l_rec_account.* TO NULL 

			SELECT * 
			INTO l_rec_account.* 
			FROM account 
			WHERE account.cmpy_code = l_rec_coa.cmpy_code AND 
			account.acct_code = l_rec_coa.acct_code AND 
			account.year_num = modu_temp_year 
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
			OUTPUT TO REPORT GA6_rpt_list(l_rpt_idx,l_rec_account.*, l_rec_coa.* )  
			IF NOT rpt_int_flag_handler2("Account:",l_rec_coa.acct_code, NULL,l_rpt_idx) THEN
				EXIT FOREACH 
			END IF 
			#---------------------------------------------------------	
		END IF 

	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT GA6_rpt_list
	CALL rpt_finish("GA6_rpt_list")
	#------------------------------------------------------------
	
	IF int_flag THEN
		MESSAGE "Report Generation Canceled..."
		RETURN FALSE
	ELSE
		RETURN TRUE
	END IF 	  
END FUNCTION 


###############################################################
# REPORT GA6_rpt_list(p_rec_account, p_rec_coa )
#
#
###############################################################
REPORT GA6_rpt_list(p_rpt_idx,p_rec_account, p_rec_coa ) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_account RECORD LIKE account.* 
	DEFINE p_rec_coa RECORD LIKE coa.* 
	DEFINE l_purch_type LIKE purchhead.type_ind 
	DEFINE l_purch_curr LIKE purchhead.curr_code 
	DEFINE l_poaudit_amt LIKE poaudit.ext_cost_amt 
	DEFINE l_sub_tot_flag SMALLINT 

	OUTPUT 
--	left margin 0 
	ORDER external BY p_rec_coa.type_ind, p_rec_coa.acct_code 
	FORMAT 
		PAGE HEADER 
			IF pageno = 1 THEN 
				LET modu_tot_used = 0 
				LET modu_tot_avail = 0 
				LET modu_tot_commit = 0 
				LET modu_inc_used = 0 
				LET modu_inc_avail = 0 
				LET modu_inc_commit = 0 
			END IF 

			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 			
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 			

			PRINT COLUMN 1, "Account", 
			COLUMN 20, "Description", 
			COLUMN 42, "Year", 
			COLUMN 55, "Budget ", glob_budg_num USING "<<<<", 
			COLUMN 74, "Actual", 
			COLUMN 88, "Committed", 
			COLUMN 106, "Expended", 
			COLUMN 122, "Available" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 		

		ON EVERY ROW 
			IF p_rec_account.cmpy_code IS NOT NULL THEN 
				LET modu_active_flag = 1 
				# And finally IF I THEN reverse signs
				IF p_rec_coa.type_ind = "I" THEN 
					LET p_rec_account.ytd_pre_close_amt = 0-p_rec_account.ytd_pre_close_amt+0 
					LET p_rec_account.budg1_amt = 0-p_rec_account.budg1_amt+0 
				END IF 
			ELSE 
				LET p_rec_account.ytd_pre_close_amt = 0 
				LET p_rec_account.budg1_amt = 0 
			END IF 
			# now work out the commitments
			LET modu_commit_amt = 0 
			DECLARE pu_curs CURSOR FOR 
			SELECT * 
			INTO modu_rec_purchdetl.* 
			FROM purchdetl 
			WHERE cmpy_code = p_rec_account.cmpy_code 
			AND acct_code = p_rec_account.acct_code 
			FOREACH pu_curs 
				LET modu_active_flag = 1 
				SELECT type_ind, curr_code 
				INTO l_purch_type, l_purch_curr 
				FROM purchhead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
				order_num = modu_rec_purchdetl.order_num 
				CALL po_line_info(glob_rec_kandoouser.cmpy_code, modu_rec_purchdetl.order_num, modu_rec_purchdetl.line_num) 
				RETURNING modu_rec_poaudit.order_qty, modu_rec_poaudit.received_qty, 
				modu_rec_poaudit.voucher_qty, modu_rec_poaudit.unit_cost_amt, 
				modu_rec_poaudit.ext_cost_amt, modu_rec_poaudit.unit_tax_amt, 
				modu_rec_poaudit.ext_tax_amt, modu_rec_poaudit.line_total_amt 
				LET l_poaudit_amt = modu_rec_poaudit.unit_cost_amt + modu_rec_poaudit.unit_tax_amt 
				IF l_purch_type = 3 THEN 
					IF modu_rec_poaudit.order_qty > modu_rec_poaudit.voucher_qty THEN 
						LET l_poaudit_amt = conv_currency(l_poaudit_amt, glob_rec_kandoouser.cmpy_code, l_purch_curr, 
						"F", today, "B") 
						LET modu_commit_amt = modu_commit_amt + 
						((modu_rec_poaudit.order_qty - modu_rec_poaudit.voucher_qty) 
						* l_poaudit_amt) 
					END IF 
				ELSE 
					IF modu_rec_poaudit.order_qty > modu_rec_poaudit.received_qty THEN 
						LET l_poaudit_amt = conv_currency(l_poaudit_amt, glob_rec_kandoouser.cmpy_code, l_purch_curr, 
						"F", today, "B") 
						LET modu_commit_amt = modu_commit_amt + 
						((modu_rec_poaudit.order_qty - modu_rec_poaudit.received_qty) 
						* l_poaudit_amt) 
					END IF 
				END IF 
			END FOREACH 
			LET modu_used_amt = p_rec_account.ytd_pre_close_amt + modu_commit_amt 
			LET modu_avail_amt = p_rec_account.budg1_amt - modu_used_amt 
			IF modu_active_flag = 1 THEN 
				LET modu_active_flag = 0 
				LET l_sub_tot_flag = 1 
				PRINT COLUMN 1, p_rec_coa.acct_code, 
				COLUMN 20, p_rec_coa.desc_text[1,20], 
				COLUMN 42, p_rec_account.year_num USING "####", 
				COLUMN 47, p_rec_account.budg1_amt USING "----,---,---,--&", 
				COLUMN 64, p_rec_account.ytd_pre_close_amt USING "----,---,---,--&", 
				COLUMN 81, modu_commit_amt USING "----,---,---,--&", 
				COLUMN 98, modu_used_amt USING "----,---,---,--&", 
				COLUMN 115, modu_avail_amt USING "----,---,---,--&" 
			END IF 
			LET modu_tot_commit = modu_tot_commit + modu_commit_amt 
			LET modu_tot_used = modu_tot_used + modu_used_amt 
			LET modu_tot_avail = modu_tot_avail + modu_avail_amt 
		ON LAST ROW 
			SKIP 1 line 
			SKIP 1 line 
			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	
			

			LET modu_tot_used = 0 
			LET modu_tot_avail = 0 
			LET modu_tot_commit = 0 
			LET modu_inc_used = 0 
			LET modu_inc_avail = 0 
			LET modu_inc_commit = 0 

		AFTER GROUP OF p_rec_coa.type_ind 
			SKIP 1 line 
			CASE 
				WHEN p_rec_coa.type_ind = "I" 
					PRINT COLUMN 1, "modu_income Totals: ", 
					COLUMN 47, (0 - GROUP sum(p_rec_account.budg1_amt)) 
					USING "----,---,---,--&", 
					COLUMN 64, (0 - GROUP sum(p_rec_account.ytd_pre_close_amt)) 
					USING "----,---,---,--&", 
					COLUMN 81, modu_tot_commit USING "----,---,---,--&", 
					COLUMN 98, modu_tot_used USING "----,---,---,--&", 
					COLUMN 115, modu_tot_avail USING "----,---,---,--&" 
					LET modu_tot_commit = 0 
					LET modu_tot_used = 0 
					LET modu_tot_avail = 0 
				WHEN p_rec_coa.type_ind = "A" OR p_rec_coa.type_ind = "E" 
					IF p_rec_coa.type_ind = "A" THEN 
						PRINT COLUMN 1, "modu_asset Totals: "; 
					ELSE 
						PRINT COLUMN 1, "modu_expense Totals: "; 
					END IF 
					PRINT COLUMN 47, GROUP sum(p_rec_account.budg1_amt) 
					USING "----,---,---,--&", 
					COLUMN 64, GROUP sum(p_rec_account.ytd_pre_close_amt) 
					USING "----,---,---,--&", 
					COLUMN 81, modu_tot_commit USING "----,---,---,--&", 
					COLUMN 98, modu_tot_used USING "----,---,---,--&", 
					COLUMN 115, modu_tot_avail USING "----,---,---,--&" 
					LET modu_tot_commit = 0 
					LET modu_tot_used = 0 
					LET modu_tot_avail = 0 
			END CASE 
		BEFORE GROUP OF p_rec_coa.type_ind 
			CASE 
				WHEN p_rec_coa.type_ind = "I" 
					PRINT COLUMN 1, " modu_income: " 
				WHEN p_rec_coa.type_ind = "E" 
					PRINT COLUMN 1, " modu_expense: " 
				WHEN p_rec_coa.type_ind = "A" 
					PRINT COLUMN 1, " modu_asset: " 
			END CASE 
END REPORT 
