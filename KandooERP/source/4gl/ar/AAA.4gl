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
GLOBALS "../ar/AAA_GLOBALS.4gl" 
############################################################
# MODULE Scope Variables
############################################################
DEFINE modu_temp_text VARCHAR(200) 	#Used but NOWHERE assigned a value..?!?
DEFINE modu_total_bal LIKE batchhead.debit_amt  
DEFINE modu_total_onorder LIKE batchhead.debit_amt 
DEFINE modu_total_limit LIKE batchhead.debit_amt 

#####################################################################
# FUNCTION AA0_main()
#
# Credit Status Report -  Lists the credit STATUS of customers
#####################################################################
FUNCTION AAA_main()
	CALL setModuleId("AAA")
	
	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 	
			OPEN WINDOW A112 with FORM "A112" 
			CALL windecoration_a("A112")
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
		
			MENU " Credit Status Report" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","AAA","menu-credit-STATUS-rep") 
					CALL rpt_rmsreps_reset(NULL)
					CALL AAA_rpt_process(AAA_rpt_query())
					 
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				ON ACTION "Report" #COMMAND "Run" " SELECT Criteria AND PRINT REPORT"
					CALL rpt_rmsreps_reset(NULL)
					CALL AAA_rpt_process(AAA_rpt_query())  
		
				ON ACTION "Print Manager" #COMMAND "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
					NEXT option "Exit" 
		
				ON ACTION "Exit" #COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus"
					EXIT MENU 
		
			END MENU 
		
			CLOSE WINDOW A112 
			
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL AAA_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW A112 with FORM "A112" 
			CALL windecoration_a("A112") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(AAA_rpt_query()) #save where clause in env 
			CLOSE WINDOW A112 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL AAA_rpt_process(get_url_sel_text())
	END CASE 	

END FUNCTION 
#####################################################################
# END FUNCTION AA0_main()
#####################################################################


#####################################################################
# FUNCTION AAA_rpt_query()
#
#
#####################################################################
FUNCTION AAA_rpt_query() 
	DEFINE l_rec_customer RECORD LIKE customer.*
	DEFINE l_where_text STRING 
	DEFINE l_where2_text STRING
	CLEAR FORM 

	LET modu_total_limit = 0 
	LET modu_total_bal = 0 
	LET modu_total_onorder = 0 
	LET l_where2_text = NULL 
 
	MESSAGE kandoomsg2("A",1078,"") 	#A1078 "Enter Selection Criteria - ESC TO begin search"
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
			CALL publish_toolbar("kandoo","AAA","construct-customer") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "REPORTING CODE" --ON KEY (F8) 
			LET l_where2_text = report_criteria(glob_rec_kandoouser.cmpy_code,"AR") 
			IF l_where2_text IS NULL OR l_where2_text = "1=1" THEN 
				CONTINUE CONSTRUCT 
			ELSE 
				EXIT CONSTRUCT 
			END IF 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL 
	ELSE 
		IF l_where2_text IS NOT NULL THEN 
			LET l_where_text = l_where_text CLIPPED, "AND ", l_where2_text 
		END IF 
	END IF
	
	RETURN l_where_text
END FUNCTION
#####################################################################
# END FUNCTION AAA_rpt_query()
#####################################################################


#####################################################################
# FUNCTION AAA_rpt_process()
#
#
#####################################################################
FUNCTION AAA_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_rpt_idx SMALLINT 	
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_customer RECORD LIKE customer.*
	DEFINE l_query_text CHAR(1000) 

	CLEAR FORM 

	LET modu_total_limit = 0 
	LET modu_total_bal = 0 
	LET modu_total_onorder = 0 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF
	
	LET l_rpt_idx = rpt_start(getmoduleid(),"AAA_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT AAA_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	
	LET l_query_text = "SELECT * FROM customer ", 
	"WHERE ",glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AAA_rpt_list")].sel_text clipped, 
	" AND (bal_amt > 0 OR onorder_amt > 0) ", 
	" AND cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" " 

	IF glob_rec_arparms.report_ord_flag = "C" THEN 
		LET l_query_text = l_query_text clipped," ORDER BY currency_code, cust_code" 
	ELSE 
		LET l_query_text = l_query_text clipped," ORDER BY currency_code,name_text,cust_code" 
	END IF 

	WHENEVER ERROR CONTINUE 

	PREPARE s_customer FROM l_query_text 
	DECLARE c_customer CURSOR FOR s_customer 

	FOREACH c_customer INTO l_rec_customer.* 
		#-------------------------------------------------------------------
		OUTPUT TO REPORT AAA_rpt_list(l_rpt_idx,l_rec_customer.*) 
		IF NOT rpt_int_flag_handler2("Customer:",l_rec_customer.cust_code, l_rec_customer.name_text,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF
		#-------------------------------------------------------------------
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT AAA_rpt_list
	CALL rpt_finish("AAA_rpt_list")
	#------------------------------------------------------------

	IF int_flag THEN
		RETURN FALSE
	ELSE
		RETURN TRUE
	END IF 	
END FUNCTION 
#####################################################################
# END FUNCTION AAA_rpt_process()
#####################################################################


#####################################################################
# REPORT AAA_rpt_list(p_rec_customer)
#
#
#####################################################################
REPORT AAA_rpt_list(p_rpt_idx,p_rec_customer) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]

	DEFINE p_rec_customer RECORD LIKE customer.*
	--DEFINE l_line1 CHAR(80)
	--DEFINE l_line2 CHAR(80)
	--DEFINE l_offset1  SMALLINT
	--DEFINE l_offset2 SMALLINT
	DEFINE l_ratio DECIMAL(6,2)
	DEFINE l_cred_utilisation DECIMAL(6,2)
	DEFINE l_group_limit LIKE batchhead.debit_amt
	DEFINE l_group_bal LIKE batchhead.debit_amt
	DEFINE l_group_onorder LIKE batchhead.debit_amt
	DEFINE l_arr_line array[4] OF CHAR(132)
	DEFINE l_rec_currency RECORD LIKE currency.*
	DEFINE l_curr_rate FLOAT 

	OUTPUT 
--	left margin 0 
	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text			
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		BEFORE GROUP OF p_rec_customer.currency_code 
			SELECT * INTO l_rec_currency.* FROM currency 
			WHERE currency_code = p_rec_customer.currency_code 
			PRINT l_rec_currency.currency_code, " ", l_rec_currency.desc_text 

		ON EVERY ROW 
			IF p_rec_customer.cred_limit_amt != 0 THEN 
				LET l_cred_utilisation = 
				100*((p_rec_customer.bal_amt + p_rec_customer.onorder_amt)/p_rec_customer.cred_limit_amt) 
			ELSE 
				LET l_cred_utilisation = 0 
			END IF 
			IF l_cred_utilisation > 100 THEN 
				LET l_cred_utilisation = 100 
			END IF 
			IF p_rec_customer.cred_given_num != 0 AND 
			p_rec_customer.cred_taken_num != 0 THEN 
				LET l_ratio = p_rec_customer.cred_taken_num / p_rec_customer.cred_given_num 
			ELSE 
				LET l_ratio = 0 
			END IF 
			PRINT COLUMN 4, p_rec_customer.cust_code clipped, 
			COLUMN 13, p_rec_customer.name_text, 
			COLUMN 43, p_rec_customer.hold_code, 
			COLUMN 46, p_rec_customer.cred_limit_amt USING "---,---,---,--&", 
			COLUMN 63, l_cred_utilisation USING "---&.&&", 
			COLUMN 70, p_rec_customer.bal_amt USING "---,---,---,--&.&&", 
			COLUMN 89, p_rec_customer.onorder_amt USING "---,---,--&.&&", 
			COLUMN 105, p_rec_customer.last_inv_date USING "dd/mm/yy", 
			COLUMN 115, p_rec_customer.last_pay_date USING "dd/mm/yy", 
			COLUMN 125, l_ratio USING "###&.&&" 

		AFTER GROUP OF p_rec_customer.currency_code 
			LET l_group_limit = GROUP sum(p_rec_customer.cred_limit_amt) 
			LET l_group_bal = GROUP sum(p_rec_customer.bal_amt) 
			LET l_group_onorder = GROUP sum(p_rec_customer.onorder_amt) 
			PRINT COLUMN 46, "---------------", 
			COLUMN 70, "------------------", 
			COLUMN 89, "--------------" 
			PRINT COLUMN 17,"Totals: ", l_rec_currency.currency_code, 
			COLUMN 46, l_group_limit USING "---,---,---,--&", 
			COLUMN 70, l_group_bal USING "---,---,---,--&.&&", 
			COLUMN 89, l_group_onorder USING "---,---,--&.&&" 
			SKIP 1 line 
			
			CALL get_conv_rate(glob_rec_kandoouser.cmpy_code, p_rec_customer.currency_code, today, CASH_EXCHANGE_SELL) 
			RETURNING l_curr_rate 
			
			LET modu_total_limit = modu_total_limit + (l_group_limit/l_curr_rate) 
			LET modu_total_bal = modu_total_bal + (l_group_bal/l_curr_rate) 
			LET modu_total_onorder = modu_total_onorder + (l_group_onorder/l_curr_rate) 
			LET l_group_limit = 0 
			LET l_group_bal = 0 
			LET l_group_onorder = 0 

		ON LAST ROW 
			NEED 8 LINES 
			PRINT COLUMN 46, "---------------------------------------------------------" 
			PRINT COLUMN 10, "Report Totals: ",glob_rec_arparms.currency_code 
			PRINT COLUMN 10, "Total Customers: ", count(*) USING "####", 2 spaces, "Totals: ", 
			COLUMN 46, modu_total_limit USING "---,---,---,--&", 
			COLUMN 70, modu_total_bal USING "---,---,---,--&.&&", 
			COLUMN 89, modu_total_onorder USING "---,---,--&.&&" 
			SKIP 1 line 

			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = pageno

			PRINT COLUMN 01, "Report Type: ", glob_arr_rec_rpt_rmsreps[p_rpt_idx].ref1_ind 
			--PRINT COLUMN 01, l_arr_line[4] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 			

			 
END REPORT
#####################################################################
# END REPORT AAA_rpt_list(p_rec_customer)
#####################################################################