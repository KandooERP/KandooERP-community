###########################################################################
# This program IS free software; you can redistribute it AND/OR modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 2 of the License, OR (at your
# option) any later version.
#
# This program IS distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License FOR more l_details.
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
GLOBALS "../ar/AAH_GLOBALS.4gl" 
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
# FUNCTION AAH_main()
#
# AAH - Aging REPORT by state
#####################################################################
FUNCTION AAH_main()
	CALL setModuleId("AAH") 	

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode
			OPEN WINDOW A112 with FORM "A112" 
			CALL windecoration_a("A112") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title
		
			MENU " Summary Aging by State" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","AAH","menu-summary-aging-state") 
					LET modu_tot_over1 = 0 
					LET modu_tot_over30 = 0 
					LET modu_tot_over60 = 0 
					LET modu_tot_over90 = 0 
					LET modu_tot_curr = 0 
					LET modu_tot_bal = 0 
					CALL rpt_rmsreps_reset(NULL)
					CALL AAH_rpt_process(AAH_rpt_query())
					 
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				ON ACTION "Report" 	#COMMAND "Run" " SELECT Criteria AND PRINT REPORT"
					LET modu_tot_over1 = 0 
					LET modu_tot_over30 = 0 
					LET modu_tot_over60 = 0 
					LET modu_tot_over90 = 0 
					LET modu_tot_curr = 0 
					LET modu_tot_bal = 0 
					CALL rpt_rmsreps_reset(NULL)
					CALL AAH_rpt_process(AAH_rpt_query()) 
		
				ON ACTION "Print Manager"	#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "CANCEL" #COMMAND KEY("E",interrupt)"Exit" " Exit TO menus"
					EXIT MENU 
		
			END MENU 
		
			CLOSE WINDOW A112
			 
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL AAH_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW A112 with FORM "A112" 
			CALL windecoration_a("A112") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(AAH_rpt_query()) #save where clause in env 
			CLOSE WINDOW A112 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL AAH_rpt_process(get_url_sel_text())
	END CASE

END FUNCTION 
#####################################################################
# END FUNCTION AAH_main()
#####################################################################


#####################################################################
# FUNCTION AAH_rpt_query()
#
#
#####################################################################
FUNCTION AAH_rpt_query() 
	DEFINE l_where_text STRING

	MESSAGE kandoomsg2("U",1001,"") 

	#1001 " Enter criteria FOR selection - ESC TO begin search"
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
			CALL publish_toolbar("kandoo","AAH","construct-customer") 

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
# END FUNCTION AAH_rpt_query()
#####################################################################


#####################################################################
# FUNCTION AAH_rpt_process(p_where_text) 
#
#
#####################################################################
FUNCTION AAH_rpt_process(p_where_text) 
	DEFINE p_where_text STRING
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE l_query_text STRING
	DEFINE l_rec_customer RECORD LIKE customer.* 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL	
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF
	
	MESSAGE kandoomsg2("U",1002,"") 
	#1002 Searching Database;  Please Wait.
	IF glob_rec_arparms.report_ord_flag = "C" THEN 
		LET l_query_text = "SELECT * FROM customer ", 
		"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\"", 
		" AND bal_amt != 0 ", 
		" AND ",p_where_text clipped, 
		" ORDER BY cust_code[1,1], cust_code " 
	ELSE 
		LET l_query_text = "SELECT * FROM customer ", 
		" WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
		" AND bal_amt != 0 ", 
		" AND ",p_where_text clipped," ", 
		" ORDER BY cust_code[1,1], name_text, cust_code " 
	END IF 
	PREPARE s_customer FROM l_query_text 
	DECLARE c_customer CURSOR FOR s_customer 

	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start(getmoduleid(),"AAH_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT AAH_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------


	FOREACH c_customer INTO l_rec_customer.* 
		#------------------------------------------------------------
		OUTPUT TO REPORT AAH_rpt_list(l_rpt_idx,l_rec_customer.*) 
		IF NOT rpt_int_flag_handler2("Customer:",l_rec_customer.cust_code, l_rec_customer.name_text,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#------------------------------------------------------------
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT AA2_rpt_list
	CALL rpt_finish("AA2_rpt_list")
	#------------------------------------------------------------

	IF int_flag THEN
		RETURN FALSE
	ELSE
		RETURN TRUE
	END IF 
END FUNCTION 
#####################################################################
# END FUNCTION AAH_rpt_process(p_where_text) 
#####################################################################


#####################################################################
# REPORT AAH_rpt_list(p_group,p_rec_customer)
#
#
#####################################################################
REPORT AAH_rpt_list(p_rpt_idx,p_group,p_rec_customer)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_group CHAR(1)
	DEFINE p_rec_customer RECORD LIKE customer.*
	DEFINE l_cust_bal_amt LIKE customer.bal_amt
	DEFINE l_cust_curr_amt LIKE customer.curr_amt
	DEFINE l_cust_over1_amt LIKE customer.over1_amt
	DEFINE l_cust_over30_amt LIKE customer.over30_amt
	DEFINE l_cust_over60_amt LIKE customer.over60_amt
	DEFINE l_cust_over90_amt LIKE customer.over90_amt
	DEFINE l_temp_country LIKE customer.country_code --@db-patch_2020_10_04--
	DEFINE l_first_record CHAR(1) 
	DEFINE l_details CHAR(20) 
	DEFINE l_print_flag CHAR(1) 
	DEFINE l_state_flag CHAR(1) 

	OUTPUT 
--	left margin 0 
	ORDER external BY p_group 

	FORMAT 
		PAGE HEADER 
			IF pageno = 1 THEN 
				LET l_first_record = "Y" 
				LET l_print_flag = "N" 
				LET modu_tot_bal = 0 
				LET modu_tot_curr = 0 
				LET modu_tot_over1 = 0 
				LET modu_tot_over30 = 0 
				LET modu_tot_over60 = 0 
				LET modu_tot_over90 = 0 
				LET l_cust_bal_amt = 0 
				LET l_cust_curr_amt = 0 
				LET l_cust_over1_amt = 0 
				LET l_cust_over30_amt = 0 
				LET l_cust_over60_amt = 0 
				LET l_cust_over90_amt = 0 
			END IF 
			
			
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 1, "Debtors l_details", 
			COLUMN 37, "Balance", 
			COLUMN 52, "Current", 
			COLUMN 66, "1-30 Days", 
			COLUMN 80, "31-60 Days", 
			COLUMN 95, "61-90 Days", 
			COLUMN 113, "90 Plus" 
			PRINT COLUMN 67, "Overdue", 
			COLUMN 82, "Overdue", 
			COLUMN 97, "Overdue", 
			COLUMN 113, "Overdue" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		ON EVERY ROW 
			LET l_cust_bal_amt = l_cust_bal_amt + conv_currency(p_rec_customer.bal_amt, 
			glob_rec_kandoouser.cmpy_code, p_rec_customer.currency_code, "F", today, "S") 
			LET l_cust_curr_amt = l_cust_curr_amt + conv_currency(p_rec_customer.curr_amt, 
			glob_rec_kandoouser.cmpy_code, p_rec_customer.currency_code, "F", today, "S") 
			LET l_cust_over1_amt = l_cust_over1_amt + conv_currency(p_rec_customer.over1_amt, 
			glob_rec_kandoouser.cmpy_code, p_rec_customer.currency_code, "F", today, "S") 
			LET l_cust_over30_amt = l_cust_over30_amt + conv_currency(p_rec_customer.over30_amt, 
			glob_rec_kandoouser.cmpy_code, p_rec_customer.currency_code, "F", today, "S") 
			LET l_cust_over60_amt = l_cust_over60_amt + conv_currency(p_rec_customer.over60_amt, 
			glob_rec_kandoouser.cmpy_code, p_rec_customer.currency_code, "F", today, "S") 
			LET l_cust_over90_amt = l_cust_over90_amt + conv_currency(p_rec_customer.over90_amt, 
			glob_rec_kandoouser.cmpy_code, p_rec_customer.currency_code, "F", today, "S") 
		BEFORE GROUP OF p_group 
			CASE 
				WHEN p_rec_customer.cust_code[1,1] = "0" 
					LET l_details = "NORTHERN TERRITORY" 
				WHEN p_rec_customer.cust_code[1,1] = "2" 
					LET l_details = "NEW SOUTH WALES" 
				WHEN p_rec_customer.cust_code[1,1] = "3" 
					LET l_details = "VICTORIA" 
				WHEN p_rec_customer.cust_code[1,1] = "4" 
					LET l_details = "QUEENSLAND" 
				WHEN p_rec_customer.cust_code[1,1] = "5" 
					LET l_details = "SOUTH AUSTRLIA" 
				WHEN p_rec_customer.cust_code[1,1] = "6" 
					LET l_details = "WESTERN AUSTRALIA" 
				WHEN p_rec_customer.cust_code[1,1] = "7" 
					LET l_details = "TASMANIA" 
				WHEN p_rec_customer.cust_code[1,1] = "8" 
					LET l_details = "OVERSEAS" 
			END CASE 

		AFTER GROUP OF p_group 
			PRINT COLUMN 1, l_details, 
			COLUMN 30, l_cust_bal_amt USING "----,---,--$.&&", 
			COLUMN 45, l_cust_curr_amt USING "----,---,--$.&&", 
			COLUMN 60, l_cust_over1_amt USING "----,---,--$.&&", 
			COLUMN 75, l_cust_over30_amt USING "----,---,--$.&&", 
			COLUMN 90, l_cust_over60_amt USING "----,---,--$.&&", 
			COLUMN 104, l_cust_over90_amt USING "----,---,--$.&&" 
			LET modu_tot_bal = modu_tot_bal + l_cust_bal_amt 
			LET modu_tot_curr = modu_tot_curr + l_cust_curr_amt 
			LET modu_tot_over1 = modu_tot_over1 + l_cust_over1_amt 
			LET modu_tot_over30 = modu_tot_over30 + l_cust_over30_amt 
			LET modu_tot_over60 = modu_tot_over60 + l_cust_over60_amt 
			LET modu_tot_over90 = modu_tot_over90 + l_cust_over90_amt 
			LET l_cust_bal_amt = 0 
			LET l_cust_curr_amt = 0 
			LET l_cust_over1_amt = 0 
			LET l_cust_over30_amt = 0 
			LET l_cust_over60_amt = 0 
			LET l_cust_over90_amt = 0 

		ON LAST ROW 
			PRINT COLUMN 35,"-----------------------------------------", 
			"---------------------------------------------------" 
			PRINT COLUMN 1, "In Base Currency" 
			PRINT COLUMN 1, "Totals: ", 
			COLUMN 27, modu_tot_bal USING "---,---,---,--$.&&", 
			COLUMN 42, modu_tot_curr USING "----,---,--$.&&", 
			COLUMN 60, modu_tot_over1 USING "----,---,--$.&&", 
			COLUMN 75, modu_tot_over30 USING "----,---,--$.&&", 
			COLUMN 90, modu_tot_over60 USING "----,---,--$.&&", 
			COLUMN 104, modu_tot_over90 USING "----,---,--$.&&" 
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
# END REPORT AAH_rpt_list(p_group,p_rec_customer)
#####################################################################