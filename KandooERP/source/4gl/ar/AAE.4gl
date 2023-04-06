
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
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl"
GLOBALS "../ar/AA_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/AAE_GLOBALS.4gl"
############################################################
# MODULE Scope Variables
############################################################
DEFINE modu_tot_over1 DECIMAL(16,2) 
DEFINE modu_tot_over30 DECIMAL(16,2) 
DEFINE modu_tot_over60 DECIMAL(16,2) 
DEFINE modu_tot_over90 DECIMAL(16,2) 
DEFINE modu_tot_curr DECIMAL(16,2) 
DEFINE modu_tot_bal DECIMAL(16,2)
#####################################################################
# FUNCTION AAE_main()
#
# Summary Aging Report - Customers in Credit Only
#####################################################################
FUNCTION AAE_main()
	CALL setModuleId("AAE") 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 
			OPEN WINDOW A112 with FORM "A112" 
			CALL windecoration_a("A112")
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

			MENU " Customer Summary Aging (Credit)" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","AAE","menu-customer-summary-aging") 
					CALL rpt_rmsreps_reset(NULL)
					CALL AAE_rpt_process(AAE_rpt_query())
					 
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				ON ACTION "Report" #COMMAND "Run" " SELECT criteria AND PRINT REPORT"
					CALL rpt_rmsreps_reset(NULL)
					CALL AAE_rpt_process(AAE_rpt_query())

				ON ACTION "Print Manager" #COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
					NEXT option "Exit" 

				ON ACTION "CANCEL" #COMMAND KEY (interrupt, "E")"Exit" " Exit TO menus" 
					EXIT MENU 

			END MENU 

			CLOSE WINDOW A112 

		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL AAE_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW A112 with FORM "A112" 
			CALL windecoration_a("A112") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(AAE_rpt_query()) #save where clause in env 
			CLOSE WINDOW A112 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL AAE_rpt_process(get_url_sel_text())
	END CASE

END FUNCTION 
#####################################################################
# END FUNCTION AAE_main()
#####################################################################


#####################################################################
# FUNCTION AAE_rpt_query()
#
#
#####################################################################
FUNCTION AAE_rpt_query() 
	DEFINE l_where_text STRING

	MESSAGE kandoomsg2("U",1001,"") 

	#1001 Enter criteria FOR selection; OK TO begin search
	CONSTRUCT BY NAME l_where_text ON cust_code, 
	name_text, 
	currency_code, 
	addr1_text, 
	addr2_text, 
	city_text, 
	state_code, 
	post_code, 
	country_code, 
	tele_text, 
	mobile_phone,
	email, 
	comment_text, 
	curr_amt, 
	over1_amt, 
	over30_amt, 
	over60_amt, 
	over90_amt, 
	bal_amt, 
	vat_code, 
	inv_level_ind, 
	cond_code, 
	avg_cred_day_num, 
	hold_code, 
	type_code, 
	sale_code, 
	territory_code, 
	cred_limit_amt, 
	onorder_amt, 
	last_inv_date, 
	last_pay_date, 
	setup_date, 
	delete_date 


		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","AAE","construct-customer") 

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
# END FUNCTION AAE_rpt_query()
#####################################################################


#####################################################################
# FUNCTION AAE_rpt_process(p_where_text) 
#
#
#####################################################################
FUNCTION AAE_rpt_process(p_where_text) 
	DEFINE p_where_text STRING
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE l_rec_customer RECORD LIKE customer.*
--	DEFINE l_rec_arparms RECORD LIKE arparms.*
	DEFINE l_query_text STRING

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF
	
	LET modu_tot_over1 = 0 
	LET modu_tot_over30 = 0 
	LET modu_tot_over60 = 0 
	LET modu_tot_over90 = 0 
	LET modu_tot_curr = 0 
	LET modu_tot_bal = 0 

	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start(getmoduleid(),"AAE_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT AAE_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------
	
	IF glob_rec_arparms.report_ord_flag = "C" THEN 
		LET l_query_text = "SELECT * FROM customer ", 
		"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\"", 
		" AND bal_amt < 0 ", 
		" AND ",p_where_text clipped, 
		" ORDER BY cust_code " 
	ELSE 
		LET l_query_text = "SELECT * FROM customer ", 
		" WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
		" AND bal_amt < 0 ", 
		" AND ",p_where_text clipped," ", 
		" ORDER BY name_text, cust_code " 
	END IF 

	PREPARE s_customer FROM l_query_text 
	DECLARE c_customer CURSOR FOR s_customer 

	FOREACH c_customer INTO l_rec_customer.* 
		#------------------------------------------------------------
		OUTPUT TO REPORT AAE_rpt_list(l_rpt_idx,l_rec_customer.*) 
		IF NOT rpt_int_flag_handler2("Customer:",l_rec_customer.cust_code, l_rec_customer.name_text,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#------------------------------------------------------------
	END FOREACH 
	 
	#------------------------------------------------------------
	FINISH REPORT AAE_rpt_list
	CALL rpt_finish("AAE_rpt_list")
	#------------------------------------------------------------

	IF int_flag THEN
		RETURN FALSE
	ELSE
		RETURN TRUE
	END IF 
END FUNCTION 
#####################################################################
# END FUNCTION AAE_rpt_process(p_where_text) 
#####################################################################


#####################################################################
# REPORT AAE_rpt_list(p_rec_customer)
#
#
#####################################################################
REPORT AAE_rpt_list(p_rpt_idx,p_rec_customer) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_customer RECORD LIKE customer.* 

	OUTPUT 
--	left margin 0 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		ON EVERY ROW 
			PRINT COLUMN 1, p_rec_customer.cust_code clipped, 
			COLUMN 10, p_rec_customer.name_text[1,25], 
			COLUMN 36, p_rec_customer.currency_code, 
			COLUMN 39, p_rec_customer.bal_amt USING "----,---,--&.&&", 
			COLUMN 54, p_rec_customer.curr_amt USING "----,---,--&.&&", 
			COLUMN 69, p_rec_customer.over1_amt USING "----,---,--&.&&", 
			COLUMN 84, p_rec_customer.over30_amt USING "----,---,--&.&&", 
			COLUMN 99, p_rec_customer.over60_amt USING "----,---,--&.&&", 
			COLUMN 114, p_rec_customer.over90_amt USING "----,---,--&.&&", 
			COLUMN 130, p_rec_customer.hold_code 
			LET modu_tot_bal = modu_tot_bal + conv_currency(p_rec_customer.bal_amt, glob_rec_kandoouser.cmpy_code, 
			p_rec_customer.currency_code, "F", today, "S") 
			LET modu_tot_curr = modu_tot_curr + conv_currency(p_rec_customer.curr_amt, glob_rec_kandoouser.cmpy_code, 
			p_rec_customer.currency_code, "F", today, "S") 
			LET modu_tot_over1 = modu_tot_over1 + conv_currency(p_rec_customer.over1_amt, glob_rec_kandoouser.cmpy_code, 
			p_rec_customer.currency_code, "F", today, "S") 
			LET modu_tot_over30 = modu_tot_over30 + conv_currency(p_rec_customer.over30_amt, glob_rec_kandoouser.cmpy_code, 
			p_rec_customer.currency_code, "F", today, "S") 
			LET modu_tot_over60 = modu_tot_over60 + conv_currency(p_rec_customer.over60_amt, glob_rec_kandoouser.cmpy_code, 
			p_rec_customer.currency_code, "F", today, "S") 
			LET modu_tot_over90 = modu_tot_over90 + conv_currency(p_rec_customer.over90_amt, glob_rec_kandoouser.cmpy_code, 
			p_rec_customer.currency_code, "F", today, "S") 
			
		ON LAST ROW 
			PRINT COLUMN 35,"-----------------------------------------", 
			"-----------------------------------------------------" 
			PRINT COLUMN 1, "In Base Currency" 
			PRINT COLUMN 1, "Total Customers: ", count(*) USING "###", 
			2 spaces, "Totals: ", 
			COLUMN 37, modu_tot_bal USING "---,---,---,--&.&&", 
			COLUMN 70, modu_tot_over1 USING "----,---,--&.&&", 
			COLUMN 100, modu_tot_over60 USING "----,---,--&.&&" 
			PRINT COLUMN 55, modu_tot_curr USING "----,---,--&.&&", 
			COLUMN 85, modu_tot_over30 USING "----,---,--&.&&", 
			COLUMN 115, modu_tot_over90 USING "----,---,--&.&&" 
			SKIP 1 line 


			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = pageno
END REPORT
#####################################################################
# END REPORT AAE_rpt_list(p_rec_customer)
#####################################################################