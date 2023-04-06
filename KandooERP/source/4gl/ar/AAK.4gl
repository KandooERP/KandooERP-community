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
GLOBALS "../ar/AAK_GLOBALS.4gl" 
############################################################
# MODULE Scope Variables
############################################################
--DEFINE modu_where_text CHAR(400) 
DEFINE modu_last_age_date LIKE arparms.cust_age_date 
DEFINE modu_base_currency LIKE glparms.base_currency_code 

DEFINE modu_temp_text VARCHAR(200)  
#####################################################################
# FUNCTION AAK_main()
#
# AAK Summary Debtor Aging Report
#####################################################################
FUNCTION AAK_main()

CALL setModuleId("AAK")
	
	SELECT cust_age_date INTO modu_last_age_date 
	FROM arparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parm_code = "1" 

	SELECT base_currency_code INTO modu_base_currency 
	FROM glparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND key_code = "1" 

	OPEN WINDOW A623 with FORM "A623" 
	CALL windecoration_a("A623") 

	DISPLAY modu_last_age_date TO cust_age_date 
	DISPLAY "Summary Debtors Aging Report" TO kandooreport.header_text 

	IF (today - modu_last_age_date >= 7 ) THEN 
		CALL fgl_winmessage("",kandoomsg2("A",1046,""),"warning") 
		#1046 Warning: Customer Account Aging Required - Refer Menu AS5
	END IF 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 
			MENU " Summary Debtors Aging Report" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","AAK","menu-summary-debtors-aging") 
					CALL rpt_rmsreps_reset(NULL)
					IF AAK_enter_order() THEN 
						CALL AAK_rpt_process(AAK_rpt_query())
					END IF
					
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				ON ACTION "Report" #COMMAND "Report" " SELECT criteria AND PRINT REPORT"
					CALL rpt_rmsreps_reset(NULL)
					IF AAK_enter_order() THEN 
						CALL AAK_rpt_process(AAK_rpt_query())
					END IF
{											
					#CALL AAK_rpt_process(AAK_rpt_query())

					IF AAK_enter_order() THEN 
						IF AAK_rpt_query() THEN 
							#CALL rpt_rmsreps_set_page_num(0)
							NEXT option "Print Manager" 
						END IF 
					END IF 
	}	
				ON ACTION "Print Manager"	#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "CANCEL" #COMMAND KEY(interrupt,"E")"Exit" " RETURN TO menus"
					EXIT MENU 
		
			END MENU
			 
			CLOSE WINDOW A623

		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL AAK_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW A623 with FORM "A623" 
			CALL windecoration_a("A623") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(AAK_rpt_query()) #save where clause in env 
			CLOSE WINDOW A623 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL AAK_rpt_process(get_url_sel_text())
	END CASE
		 
END FUNCTION 
#####################################################################
# END FUNCTION AAK_main()
#####################################################################


#####################################################################
# FUNCTION AAK_enter_order()
#
#
#####################################################################
FUNCTION AAK_enter_order() 
	DEFINE l_ord_ind CHAR(1)

	LET l_ord_ind = "1" 
	INPUT l_ord_ind WITHOUT DEFAULTS FROM ord_ind
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","AAK","inp-ord_ind") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL 
	ELSE 
		RETURN l_ord_ind
	END IF 

END FUNCTION 
#####################################################################
# END FUNCTION AAK_enter_order()
#####################################################################


#####################################################################
# FUNCTION AAK_rpt_query()
#
#
#####################################################################
FUNCTION AAK_rpt_query() 
	DEFINE l_query_text STRING
	DEFINE l_where_text STRING
	DEFINE l_rec_customer RECORD LIKE customer.*
	DEFINE l_order_text CHAR(20)
	DEFINE l_old_sale_code CHAR(8)
	DEFINE l_name_text LIKE salesperson.name_text
	DEFINE l_conv_rate FLOAT
	
	MESSAGE kandoomsg2("A",1001,"") #1001 Enter Selection Criteria - ESC TO Continue

	#Sort Order
	LET glob_rec_rpt_selector.sel_order = AAK_enter_order()
	IF glob_rec_rpt_selector.sel_order IS NULL THEN
		RETURN NULL
	END IF
	
	CONSTRUCT BY NAME l_where_text ON cust_code, 
	name_text, 
	addr1_text, 
	addr2_text, 
	city_text, 
	state_code, 
	post_code, 
	country_code, 
	country_text, 
	currency_code, 
	curr_amt, 
	over1_amt, 
	over30_amt, 
	over60_amt, 
	over90_amt, 
	bal_amt, 
	hold_code, 
	type_code, 
	sale_code, 
	territory_code, 
	contact_text, 
	tele_text,
	mobile_phone, 
	fax_text, 
	email


		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","AAK","construct-customer") 

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
# END FUNCTION AAK_rpt_query()
#####################################################################


#####################################################################
# FUNCTION AAK_rpt_process(p_where_text) 
#
#
#####################################################################
FUNCTION AAK_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_rpt_idx SMALLINT
	DEFINE l_query_text STRING
	--DEFINE l_where_text STRING
	DEFINE l_rec_customer RECORD LIKE customer.*
	DEFINE l_order_text CHAR(20)
	DEFINE l_old_sale_code CHAR(8)
	DEFINE l_name_text LIKE salesperson.name_text
	DEFINE l_conv_rate FLOAT

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"AAK_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT AAK_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	CASE glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AAK_rpt_list")].sel_order 
		WHEN "1" 
			LET l_order_text = "cust_code" 
		WHEN "2" 
			LET l_order_text = "name_text,cust_code" 
		WHEN "3" 
			LET l_order_text = "state_code,cust_code" 
		WHEN "4" 
			LET l_order_text = "post_code,cust_code" 
	END CASE 

	LET l_query_text = "SELECT * FROM customer ", 
	"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND delete_flag='N'", 
	"AND ",glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AAK_rpt_list")].sel_text clipped," ", 
	"ORDER BY cmpy_code,sale_code,",l_order_text 
	PREPARE s_customer FROM l_query_text 
	DECLARE c_customer CURSOR FOR s_customer 

	LET l_old_sale_code = " " 

	FOREACH c_customer INTO l_rec_customer.* 
		IF l_old_sale_code != l_rec_customer.sale_code THEN 
			LET l_old_sale_code = l_rec_customer.sale_code 
			SELECT name_text INTO l_name_text 
			FROM salesperson 
			WHERE cmpy_code = l_rec_customer.cmpy_code 
			AND sale_code = l_rec_customer.sale_code 

			--DISPLAY "" at 1,30 
			--DISPLAY l_name_text at 1,30 

		END IF 

		IF l_rec_customer.currency_code = modu_base_currency THEN 
			LET l_conv_rate = 1 
		ELSE 
			LET l_conv_rate = get_conv_rate( 
			glob_rec_kandoouser.cmpy_code, 
			l_rec_customer.currency_code, 
			modu_last_age_date,
			CASH_EXCHANGE_SELL) 
		END IF 

		#---------------------------------------------------------
		OUTPUT TO REPORT AAK_rpt_list(l_rpt_idx,l_name_text, l_rec_customer.*,l_conv_rate) 
		IF NOT rpt_int_flag_handler2("Customer:",l_rec_customer.cust_code, l_rec_customer.name_text,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------

	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT AAK_rpt_list
	CALL rpt_finish("AAK_rpt_list")
	#------------------------------------------------------------

	IF int_flag THEN
		RETURN FALSE
	ELSE
		RETURN TRUE
	END IF 	 
END FUNCTION 
#####################################################################
# END FUNCTION AAK_rpt_process(p_where_text) 
#####################################################################


#####################################################################
# REPORT AAK_rpt_list(p_name_text,p_rec_customer,p_conv_rate)
#
#
#####################################################################
REPORT AAK_rpt_list(p_rpt_idx,p_name_text,p_rec_customer,p_conv_rate) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_customer RECORD LIKE customer.*
	DEFINE p_name_text LIKE salesperson.name_text
	DEFINE p_conv_rate FLOAT

	DEFINE l_cust_age_date DATE
	DEFINE l_overdue_per FLOAT
	DEFINE l_total_bal_amt FLOAT
	DEFINE l_total_curr_amt FLOAT
	DEFINE l_total_per FLOAT
	DEFINE l_arr_line array[4] OF CHAR(132)
	DEFINE l_idx_num SMALLINT 
	DEFINE l_i SMALLINT 
	DEFINE l_x SMALLINT 

	OUTPUT 
--	left margin 0 
--	PAGE length 66 
	ORDER external BY p_rec_customer.cmpy_code, p_rec_customer.sale_code 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		BEFORE GROUP OF p_rec_customer.sale_code 
			NEED 63 LINES 
			--LET glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text = "Customer Name Balance"
 
			IF month(modu_last_age_date) = 12 THEN 
				LET l_cust_age_date = mdy( 1,1,year(modu_last_age_date) + 1) 
			ELSE 
				LET l_cust_age_date = mdy( month(modu_last_age_date) + 1, 1, year(modu_last_age_date) ) 
			END IF 
			FOR l_idx_num = 1 TO 5 
				LET l_cust_age_date = l_cust_age_date - 1 units month 
				LET glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text = 
				glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text clipped,8 spaces, 
				l_cust_age_date USING "mmmyy" 
			END FOR 
			LET glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text = 
			glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text clipped, " Overdue Code"
			 
			LET l_i = glob_arr_rec_rpt_rmsreps[p_rpt_idx].report_width_num
			
			PRINT COLUMN 01, "Salesperson: ", 
			COLUMN 14, p_rec_customer.sale_code, 
			COLUMN 23, p_name_text, 
			COLUMN 54,glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text[1,(l_i-53)] 
			PRINT COLUMN 01,glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text[1,l_i] 
			PRINT COLUMN 01, l_arr_line[3] 

		ON EVERY ROW 
			IF p_rec_customer.bal_amt = 0 THEN 
				LET l_overdue_per = 0 
			ELSE 
				LET l_overdue_per = ( ( (p_rec_customer.bal_amt - p_rec_customer.curr_amt) / p_rec_customer.bal_amt ) * 100 ) 
			END IF 
			PRINT COLUMN 01,p_rec_customer.cust_code, 
			COLUMN 10,p_rec_customer.name_text [1,25], 
			COLUMN 37,p_rec_customer.currency_code, 
			COLUMN 41,p_rec_customer.bal_amt USING "-,---,--&.&&", 
			COLUMN 54,p_rec_customer.curr_amt USING "-,---,--&.&&", 
			COLUMN 67,p_rec_customer.over1_amt USING "-,---,--&.&&", 
			COLUMN 80,p_rec_customer.over30_amt USING "-,---,--&.&&", 
			COLUMN 93,p_rec_customer.over60_amt USING "-,---,--&.&&", 
			COLUMN 106,p_rec_customer.over90_amt USING "-,---,--&.&&", 
			COLUMN 120,l_overdue_per USING "-##&.&&", 
			COLUMN 129,p_rec_customer.hold_code 

		AFTER GROUP OF p_rec_customer.sale_code 
			LET l_total_bal_amt = GROUP sum(p_rec_customer.bal_amt*p_conv_rate) 
			LET l_total_curr_amt = GROUP sum(p_rec_customer.curr_amt*p_conv_rate) 
			IF (l_total_bal_amt = 0) THEN 
				LET l_total_per = 0 
			ELSE 
				LET l_total_per = ((l_total_bal_amt - l_total_curr_amt) /l_total_bal_amt) * 100 
			END IF 
			PRINT COLUMN 41,"---------------------------------------- ", 
			modu_base_currency, 
			" -------------------------------- -------" 
			PRINT COLUMN 01,"totals(Base Currency):", 
			COLUMN 41, l_total_bal_amt USING "-,---,--&.&&", 
			COLUMN 54, l_total_curr_amt USING "-,---,--&.&&", 
			COLUMN 67,group sum(p_rec_customer.over1_amt*p_conv_rate) USING "-,---,--&.&&", 
			COLUMN 80,group sum(p_rec_customer.over30_amt*p_conv_rate) USING "-,---,--&.&&", 
			COLUMN 93,group sum(p_rec_customer.over60_amt*p_conv_rate) USING "-,---,--&.&&", 
			COLUMN 106,group sum(p_rec_customer.over90_amt*p_conv_rate) USING "-,---,--&.&&", 
			COLUMN 120, l_total_per USING "-##&.&&" 
			PRINT COLUMN 01,"Total Customers: ", GROUP count(*) USING "<<<<<<&" 

		ON LAST ROW 
			SKIP 1 LINES 
			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = pageno
			
END REPORT
#####################################################################
# END REPORT AAK_rpt_list(p_name_text,p_rec_customer,p_conv_rate)
#####################################################################