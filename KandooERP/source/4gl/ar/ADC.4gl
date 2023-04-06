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
GLOBALS "../ar/ADC_GLOBALS.4gl" 
############################################################
# MODULE Scope Variables
############################################################
DEFINE modu_tot_amt DECIMAL(16,2) #Will be incremented/added in actual report block 
DEFINE modu_totp_amt DECIMAL(16,2) #Will be incremented/added in actual report block 
#####################################################################
# FUNCTION ADC_main()
#
# ADC Credit Listing by Period
#####################################################################
FUNCTION ADC_main() 
	DEFINE l_temp_text CHAR(32) 
	DEFER interrupt 
	DEFER quit 	
	
	CALL setModuleId("ADC") 

	LET l_temp_text = glob_rec_arparms.credit_ref1_text clipped, "................" 
	LET glob_ref_text = l_temp_text 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 	
			OPEN WINDOW A121 with FORM "A121" 
			CALL windecoration_a("A121") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title
		
			DISPLAY glob_ref_text TO credit_ref1_text 
			
			MENU " Credit Report" 
		
				BEFORE MENU 
					CALL publish_toolbar("kandoo","ADC","menu-credit-rep") 
					CALL ADC_rpt_process(ADC_rpt_query())
					
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				ON ACTION "Report" 	#COMMAND "Run Report" " SELECT criteria AND PRINT REPORT"
					CALL ADC_rpt_process(ADC_rpt_query())
		
				ON ACTION "Print Manager"	#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
					NEXT option "Exit" 
		
				ON ACTION "Exit" #COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus"
					EXIT MENU 
		
			END MENU 
		
			CLOSE WINDOW A121 
	 
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL ADC_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW A121 with FORM "A121" 
			CALL windecoration_a("A121") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(ADC_rpt_query()) #save where clause in env 
			CLOSE WINDOW A121 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL ADC_rpt_process(get_url_sel_text())
	END CASE 		
END FUNCTION 


#####################################################################
# FUNCTION ADC_rpt_query()
#
#
#####################################################################
FUNCTION ADC_rpt_query() 
	DEFINE l_where_text STRING
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
			CALL publish_toolbar("kandoo","ADC","construct-credithead") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 
END FUNCTION

#####################################################################
# FUNCTION ADC_rpt_process()
#
#
#####################################################################
FUNCTION ADC_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT  
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

	CLEAR FORM 
	DISPLAY glob_ref_text TO credit_ref1_text 	
	LET modu_tot_amt = 0 
	LET glob_tot_appl = 0 
	LET modu_totp_amt = 0 
	LET glob_totp_appl = 0 
	LET glob_toty_amt = 0 
	LET glob_toty_appl = 0 

	
	LET l_query_text = 
	"SELECT credithead.cust_code, customer.name_text, ", 
	" customer.currency_code, credithead.cred_num, ", 
	" credithead.goods_amt, credithead.hand_amt, ", 
	" credithead.freight_amt, credithead.tax_amt, ", 
	" credithead.total_amt, credithead.disc_amt, ", 
	" credithead.appl_amt, credithead.entry_code, ", 
	" credithead.entry_date, credithead.cred_text, ", 
	" credithead.cred_date, credithead.year_num, ", 
	" credithead.period_num, credithead.posted_flag, ", 
	" credithead.on_state_flag,credithead.cred_ind,", 
	" credithead.com1_text,", 
	" credithead.com2_text, credithead.rev_date, credithead.rev_num ", 
	" FROM credithead, customer ", 
	" WHERE credithead.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
	" customer.cmpy_code = credithead.cmpy_code AND ", 
	" customer.cust_code = credithead.cust_code AND ", 
	glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ADC_rpt_list")].sel_text clipped," ", 
	"ORDER BY credithead.cred_ind,credithead.cred_num" 

	PREPARE choice FROM l_query_text 
	DECLARE selcurs CURSOR FOR choice 

	FOREACH selcurs INTO l_rec_credithead.* 
		#---------------------------------------------------------
		OUTPUT TO REPORT ADC_rpt_list(l_rpt_idx,l_rec_credithead.*)  
		IF NOT rpt_int_flag_handler2("Receipt:",l_rec_credithead.cust_code, l_rec_credithead.cred_num ,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------	
	END FOREACH
	 
	#------------------------------------------------------------
	FINISH REPORT ADC_rpt_list
	CALL rpt_finish("ADC_rpt_list")
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
# REPORT ADC_list(p_rec_credithead)
#
#
#####################################################################
REPORT adc_list(p_rpt_idx,p_rec_credithead) 
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

	OUTPUT 
	left margin 0 
	ORDER BY p_rec_credithead.year_num, 
	p_rec_credithead.period_num 
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  

			PRINT COLUMN 1, "Credit", 
			COLUMN 10, glob_rec_arparms.credit_ref2a_text, 
			COLUMN 21, "Customer", 
			COLUMN 30, "Date", 
			COLUMN 53, "Total", 
			COLUMN 67, "Amount", 
			COLUMN 75, "Posted" 
			PRINT COLUMN 1, "Number", 
			COLUMN 10, glob_rec_arparms.credit_ref2b_text, 
			COLUMN 22, " Code ", 
			COLUMN 53, "Amount", 
			COLUMN 67, "Applied", 
			COLUMN 75, " (GL)" 
			
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		BEFORE GROUP OF p_rec_credithead.year_num 
			SKIP TO top OF PAGE 

		BEFORE GROUP OF p_rec_credithead.period_num 
			PRINT COLUMN 1, "Year: ", p_rec_credithead.year_num USING "####", 
			COLUMN 15, "Period: ", p_rec_credithead.period_num USING "###" 
			SKIP 1 line 

		ON EVERY ROW 
			PRINT COLUMN 1, p_rec_credithead.cred_num USING "########", 
			COLUMN 10, p_rec_credithead.cred_text, 
			COLUMN 21, p_rec_credithead.cust_code, 
			COLUMN 30, p_rec_credithead.cred_date USING "dd/mm/yy", 
			COLUMN 41, p_rec_credithead.currency_code , 
			COLUMN 45, p_rec_credithead.total_amt USING "---,---,--$.&&", 
			COLUMN 60, p_rec_credithead.appl_amt USING "---,---,--$.&&", 
			COLUMN 78, p_rec_credithead.posted_flag 
			LET glob_amt = conv_currency(p_rec_credithead.total_amt, glob_rec_kandoouser.cmpy_code, 
			p_rec_credithead.currency_code, "F", p_rec_credithead.cred_date, "l_s") 
			LET glob_appl = conv_currency(p_rec_credithead.appl_amt, glob_rec_kandoouser.cmpy_code, 
			p_rec_credithead.currency_code, "F", p_rec_credithead.cred_date, "l_s") 
			LET modu_tot_amt = modu_tot_amt + glob_amt 
			LET glob_tot_appl = glob_tot_appl + glob_appl 
			LET modu_totp_amt = modu_totp_amt + glob_amt 
			LET glob_totp_appl = glob_totp_appl + glob_appl 
			LET glob_toty_amt = glob_toty_amt + glob_amt 
			LET glob_toty_appl = glob_toty_appl + glob_appl 

		AFTER GROUP OF p_rec_credithead.period_num 
			PRINT COLUMN 45, "==============================" 
			PRINT COLUMN 1, "Period Totals In Base Currency:", 
			COLUMN 45, modu_totp_amt USING "---,---,--$.&&", 
			COLUMN 60, glob_totp_appl USING "---,---,--$.&&" 
			LET modu_totp_amt = 0 
			LET glob_totp_appl = 0 

		AFTER GROUP OF p_rec_credithead.year_num 
			PRINT COLUMN 45, "==============================" 
			PRINT COLUMN 1, "Year Totals In Base Currency:", 
			COLUMN 45, glob_toty_amt USING "---,---,--$.&&", 
			COLUMN 60, glob_toty_appl USING "---,---,--$.&&" 
			LET glob_toty_amt = 0 
			LET glob_toty_appl = 0 

		ON LAST ROW 
			SKIP 1 line 
			PRINT COLUMN 1, "Report Totals In Base Currency:", 
			COLUMN 45, modu_tot_amt USING "---,---,--$.&&", 
			COLUMN 60, glob_tot_appl USING "---,---,--$.&&" 
			SKIP 1 line 

			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	
			

END REPORT 


