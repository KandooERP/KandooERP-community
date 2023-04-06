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
GLOBALS "../ar/A_AR_GLOBALS.4gl"
GLOBALS "../ar/AD_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/ADD_GLOBALS.4gl" 
############################################################
# MODULE Scope Variables
############################################################
DEFINE modu_tot_amt DECIMAL(16,2) #Will be incremented/added in actual report block 
--DEFINE modu_tot_disc DECIMAL(16,2) #Will be incremented/added in actual report block 
#####################################################################
# FUNCTION ADD_main()
#
# ADD Credit Listing by Authority Code
#####################################################################
FUNCTION ADD_main() 
	DEFINE l_temp_text CHAR(32)

	DEFER interrupt 
	DEFER quit 
	
	CALL setModuleId("ADD") 

	LET l_temp_text = glob_rec_arparms.credit_ref1_text clipped, "................" 
	LET glob_ref_text = l_temp_text 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 
			OPEN WINDOW A121 with FORM "A121" 
			CALL windecoration_a("A121") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title
		
			DISPLAY glob_ref_text TO credit_ref1_text 
			MENU " Credit by Reference Number" 
		
				BEFORE MENU 
					CALL publish_toolbar("kandoo","ADD","menu-credit-reference-num") 
					CALL ADD_rpt_process(ADD_rpt_query())
					
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
		
				ON ACTION "Report" #COMMAND "Run Report" " SELECT criteria AND PRINT REPORT"
					CALL ADD_rpt_process(ADD_rpt_query())
		
				ON ACTION "Print Manager" 	#COMMAND KEY ("P",f11) "Print" "Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "Exit" 	#COMMAND KEY (interrupt, "E") "Exit" " Exit TO menus"
					EXIT MENU 
		
		
			END MENU 
		
			CLOSE WINDOW A121 
	 
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL ADD_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW A121 with FORM "A121" 
			CALL windecoration_a("A121") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(ADD_rpt_query()) #save where clause in env 
			CLOSE WINDOW A121 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL ADD_rpt_process(get_url_sel_text())
	END CASE 	
END FUNCTION 

#####################################################################
# FUNCTION ADD_rpt_query()
# RETURN l_where_text 
#
#####################################################################
FUNCTION ADD_rpt_query() 
	DEFINE l_where_text STRING
	CLEAR FORM 
	DISPLAY glob_ref_text TO credit_ref1_text 

	MESSAGE kandoomsg2("A",1001,"") 
	#1001 Enter Selection Criteria - ESC TO Continue

	CONSTRUCT BY NAME l_where_text ON credithead.cust_code, 
	customer.name_text, 
	credithead.cred_num, 
	credithead.cred_date, 
	credithead.job_code, 
	credithead.cred_text, 
	customer.currency_code, 
	credithead.goods_amt, 
	credithead.hand_amt, 
	credithead.freight_amt, 
	credithead.tax_amt, 
	credithead.total_amt, 
	credithead.appl_amt, 
	credithead.disc_amt, 
	credithead.year_num, 
	credithead.period_num, 
	credithead.posted_flag, 
	credithead.on_state_flag, 
	credithead.cred_ind, 
	credithead.entry_code, 
	credithead.entry_date, 
	credithead.sale_code, 
	credithead.com1_text, 
	credithead.com2_text, 
	credithead.rev_date, 
	credithead.rev_num 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","ADD","construct-credithead") 

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
		RETURN l_where_text
	END IF 
END FUNCTION

#####################################################################
# FUNCTION ADD_rpt_process() 
#
#
#####################################################################
FUNCTION ADD_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT 
	
	DEFINE l_title_text CHAR(60)
	DEFINE l_rec_credithead RECORD 
		cust_code LIKE credithead.cust_code, 
		name_text LIKE customer.name_text, 
		currency_code LIKE customer.currency_code, 
		cred_num LIKE credithead.cred_num, 
		goods_amt LIKE credithead.goods_amt, 
		hand_amt LIKE credithead.hand_amt, 
		freight_amt LIKE credithead.freight_amt, 
		tax_amt LIKE credithead.tax_amt, 
		total_amt LIKE credithead.total_amt, 
		disc_amt LIKE credithead.disc_amt, 
		appl_amt LIKE credithead.appl_amt, 
		entry_code LIKE credithead.entry_code, 
		entry_date LIKE credithead.entry_date, 
		cred_text LIKE credithead.cred_text, 
		cred_date LIKE credithead.cred_date, 
		year_num LIKE credithead.year_num, 
		period_num LIKE credithead.period_num, 
		posted_flag LIKE credithead.posted_flag, 
		on_state_flag LIKE credithead.on_state_flag, 
		cred_ind LIKE credithead.cred_ind, 
		com1_text LIKE credithead.com1_text, 
		com2_text LIKE credithead.com2_text, 
		rev_date LIKE credithead.rev_date, 
		rev_num LIKE credithead.rev_num 
	END RECORD 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"ADD_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT ADD_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------


	DISPLAY glob_ref_text TO credit_ref1_text 
	LET modu_tot_amt = 0 
	LET glob_tot_appl = 0 

	
	LET l_query_text = 
	" SELECT credithead.cust_code, customer.name_text, ", 
	" customer.currency_code, credithead.cred_num, ", 
	" credithead.goods_amt, credithead.hand_amt, ", 
	" credithead.freight_amt, credithead.tax_amt, ", 
	" credithead.total_amt, credithead.disc_amt, ", 
	" credithead.appl_amt, credithead.entry_code, ", 
	" credithead.entry_date, credithead.cred_text, ", 
	" credithead.cred_date, credithead.year_num, ", 
	" credithead.period_num, credithead.posted_flag, ", 
	" credithead.on_state_flag,credithead.cred_ind,", 
	" credithead.com1_text, ", 
	" credithead.com2_text, credithead.rev_date, credithead.rev_num ", 
	" FROM credithead, customer ", 
	" WHERE credithead.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
	" customer.cmpy_code = credithead.cmpy_code AND ", 
	" customer.cust_code = credithead.cust_code AND ", 
	 glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ADD_rpt_list")].sel_text clipped, 
	" ORDER BY credithead.cred_text" 
	
	PREPARE choice FROM l_query_text 
	DECLARE selcurs CURSOR FOR choice 


	LET l_title_text = "AR Credit by ", glob_rec_arparms.credit_ref1_text clipped 

	FOREACH selcurs INTO l_rec_credithead.* 
		#---------------------------------------------------------
		OUTPUT TO REPORT ADD_rpt_list(l_rpt_idx,l_rec_credithead.*)  
		IF NOT rpt_int_flag_handler2("Credit:",l_rec_credithead.cred_num, l_rec_credithead.name_text,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------	
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT ADD_rpt_list
	CALL rpt_finish("ADD_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF
END FUNCTION 



#####################################################################
# REPORT add_list(p_rpt_idx,p_rec_credithead) 
#
#
#####################################################################
REPORT add_list(p_rpt_idx,p_rec_credithead) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_credithead RECORD 
		cust_code LIKE credithead.cust_code, 
		name_text LIKE customer.name_text, 
		currency_code LIKE customer.currency_code, 
		cred_num LIKE credithead.cred_num, 
		goods_amt LIKE credithead.goods_amt, 
		hand_amt LIKE credithead.hand_amt, 
		freight_amt LIKE credithead.freight_amt, 
		tax_amt LIKE credithead.tax_amt, 
		total_amt LIKE credithead.total_amt, 
		disc_amt LIKE credithead.disc_amt, 
		appl_amt LIKE credithead.appl_amt, 
		entry_code LIKE credithead.entry_code, 
		entry_date LIKE credithead.entry_date, 
		cred_text LIKE credithead.cred_text, 
		cred_date LIKE credithead.cred_date, 
		year_num LIKE credithead.year_num, 
		period_num LIKE credithead.period_num, 
		posted_flag LIKE credithead.posted_flag, 
		on_state_flag LIKE credithead.on_state_flag, 
		cred_ind LIKE credithead.cred_ind, 
		com1_text LIKE credithead.com1_text, 
		com2_text LIKE credithead.com2_text, 
		rev_date LIKE credithead.rev_date, 
		rev_num LIKE credithead.rev_num 
	END RECORD
	DEFINE l_len INTEGER 
	DEFINE l_s INTEGER 
	DEFINE l_tmp_str STRING
	
	OUTPUT 

	left margin 0 

	ORDER external BY p_rec_credithead.cred_text, p_rec_credithead.cred_num 

	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 


			LET l_tmp_str = "Credit Listing by ", trim(glob_rec_arparms.credit_ref1_text)
			CALL rpt_set_header_footer_line_x(p_rpt_idx,1,l_tmp_str, NULL, NULL)

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].line1_text
			
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]
 
			PRINT COLUMN 1, glob_rec_arparms.credit_ref2a_text, 
			COLUMN 13, "Credit", 
			COLUMN 21, "Customer", 
			COLUMN 30, "Date", 
			COLUMN 42, "Period", 
			COLUMN 60, "Total", 
			COLUMN 72, "Amount", 
			COLUMN 80, "Posted" 
			PRINT COLUMN 1, glob_rec_arparms.credit_ref2b_text, 
			COLUMN 12, "Number", 
			COLUMN 22, " Code ", 
			COLUMN 48, "Currency", 
			COLUMN 60, "Amount", 
			COLUMN 72, "Applied" 
			
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]
			 
		ON EVERY ROW 
			PRINT COLUMN 1, p_rec_credithead.cred_text, 
			COLUMN 10, p_rec_credithead.cred_num USING "########", 
			COLUMN 21, p_rec_credithead.cust_code, 
			COLUMN 30, p_rec_credithead.cred_date USING "dd/mm/yy", 
			COLUMN 39, p_rec_credithead.year_num USING "####", 
			COLUMN 44, p_rec_credithead.period_num USING "###", 
			COLUMN 48, p_rec_credithead.currency_code, 
			COLUMN 52, p_rec_credithead.total_amt USING "---,---,--$.&&", 
			COLUMN 65, p_rec_credithead.appl_amt USING "---,---,--$.&&", 
			COLUMN 83, p_rec_credithead.posted_flag 
			LET modu_tot_amt = modu_tot_amt + conv_currency(p_rec_credithead.total_amt, glob_rec_kandoouser.cmpy_code, 
			p_rec_credithead.currency_code, "F", p_rec_credithead.cred_date, "l_s") 
			LET glob_tot_appl = glob_tot_appl + conv_currency(p_rec_credithead.appl_amt, glob_rec_kandoouser.cmpy_code, 
			p_rec_credithead.currency_code, "F", p_rec_credithead.cred_date, "l_s")
			 
		ON LAST ROW 
			NEED 4 LINES 
			PRINT COLUMN 52, "=============================" 

			PRINT COLUMN 1 , "Report Totals in Base Currency:", 
			COLUMN 52, modu_tot_amt USING "---,---,--$.&&", 
			COLUMN 65, glob_tot_appl USING "---,---,--$.&&" 
			SKIP 1 line 
			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	
			
END REPORT 