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
GLOBALS "../ar/AB_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/AB0_GLOBALS.4gl" 
###########################################################################
# MODULE Scope Variables
###########################################################################
--DEFINE modu_orig_cust_code CHAR(30)
--DEFINE modu_rec_customer RECORD LIKE customer.* #used for different customers in the report (one report has multiple customers)
############################################################
# FUNCTION AB1_main()
#
# Invoice Listing By Customer
############################################################
FUNCTION AB1_main() 
	DEFINE l_cmd_arg STRING
	
	CALL setModuleId("AB1")

--	INITIALIZE modu_rec_customer.* TO NULL 
	LET glob_v_name_text = NULL 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 	
			OPEN WINDOW A190 with FORM "A190" 
			CALL windecoration_a("A190") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

			DISPLAY glob_rec_arparms.inv_ref2a_text TO inv_ref2a_text
			DISPLAY glob_rec_arparms.inv_ref2b_text TO inv_ref2b_text
		
			MENU " Invoices by Customer Report" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","AB1","menu-invoices-customer")
					CALL rpt_rmsreps_reset(NULL)					 
					CALL AB1_rpt_process(AB1_rpt_query())
					
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
					
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				ON ACTION "REPORT" #COMMAND "Run Report" " SELECT criteria AND PRINT REPORT" 
					CALL rpt_rmsreps_reset(NULL)
					CALL AB1_rpt_process(AB1_rpt_query())
		
				ON ACTION "PRINT MANAGER" #COMMAND "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "CANCEL" #COMMAND KEY (interrupt, "E") "Exit" " Exit TO menus" 
					EXIT MENU 
		
			END MENU 
			CLOSE WINDOW A190
	 
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL AB1_rpt_process(NULL)
			  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW A190 with FORM "A190" 
			CALL windecoration_a("A190") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(AB1_rpt_query()) #save where clause in env 
			CLOSE WINDOW A190 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL AB1_rpt_process(get_url_sel_text())
	END CASE 	
END FUNCTION 
############################################################
# END FUNCTION AB1_main()
############################################################


############################################################
# FUNCTION AB1_rpt_query()
#
# RETURN l_where_text
############################################################
FUNCTION AB1_rpt_query()
	DEFINE l_where_text STRING
	DEFINE l_rec_invoicehead RECORD LIKE invoicehead.* 
	DEFINE l_rec_temp_rec RECORD 
		sort_field CHAR(30), 
		org_cust_code LIKE invoicehead.cust_code, 
		inv_num LIKE invoicehead.inv_num 
	END RECORD 
	
	CLEAR FORM 
	
	DISPLAY glob_rec_arparms.inv_ref2a_text TO inv_ref2a_text
	DISPLAY glob_rec_arparms.inv_ref2b_text TO inv_ref2b_text 
	MESSAGE " Enter criteria FOR selection - ESC TO begin search" 

	CONSTRUCT l_where_text ON invoicehead.cust_code, 
	customer.name_text, 
	invoicehead.org_cust_code, 
	o_cust.name_text, 
	customer.currency_code, 
	invoicehead.inv_num, 
	invoicehead.purchase_code, 
	invoicehead.inv_date, 
	invoicehead.year_num, 
	invoicehead.period_num, 
	invoicehead.total_amt, 
	invoicehead.paid_amt, 
	invoicehead.posted_flag 
	FROM invoicehead.cust_code, 
	customer.name_text, 
	invoicehead.org_cust_code, 
	org_name_text, 
	customer.currency_code, 
	invoicehead.inv_num, 
	invoicehead.purchase_code, 
	invoicehead.inv_date, 
	invoicehead.year_num, 
	invoicehead.period_num, 
	invoicehead.total_amt, 
	invoicehead.paid_amt, 
	invoicehead.posted_flag 


		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","AB1","construct-invoicehead") 

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
############################################################
# END FUNCCTION AB1_rpt_query()
############################################################


############################################################
# FUNCTION AB1_rpt_process(p_where_text) 
#
#
############################################################
FUNCTION AB1_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT  #report array index
	DEFINE l_rec_invoicehead RECORD LIKE invoicehead.*
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_temp_rec RECORD 
		sort_field CHAR(30), 
		org_cust_code LIKE invoicehead.cust_code, 
		inv_num LIKE invoicehead.inv_num 
	END RECORD 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"AB1_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT AB1_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------

	
	LET glob_y = length(p_where_text) 
	LET glob_word = "" 
	LET glob_use_outer = true 

	
	FOR glob_x = 1 TO glob_y 
		LET glob_letter = p_where_text[glob_x, (glob_x+1)] 
		IF glob_letter = " " OR 
		glob_letter = "=" OR 
		glob_letter = "(" OR 
		glob_letter = ")" OR 
		glob_letter = "[" OR 
		glob_letter = "]" OR 
		glob_letter = "." OR 
		glob_letter = "," THEN 
			LET glob_word = "" 
		END IF 
		LET glob_word = glob_word CLIPPED,glob_letter 
		IF glob_word = "o_cust" THEN 
			LET glob_use_outer = false 
			EXIT FOR 
		END IF 
	END FOR 


	IF glob_use_outer THEN 
		IF glob_rec_arparms.report_ord_flag = "C" THEN 
			LET l_query_text = 
			"SELECT invoicehead.*,", 
			"customer.name_text,customer.cust_code,", 
			"customer.currency_code,", 
			"o_cust.name_text ", 
			"FROM invoicehead, customer, outer customer o_cust ", 
			"WHERE invoicehead.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
			"AND customer.cust_code = invoicehead.cust_code ", 
			"AND customer.cmpy_code = invoicehead.cmpy_code ", 
			"AND o_cust.cust_code = invoicehead.org_cust_code ", 
			"AND o_cust.cmpy_code = invoicehead.cmpy_code ", 
			"AND ",glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AB1_rpt_list")].sel_text CLIPPED," ",		 
			"ORDER BY customer.cust_code" 
		ELSE 
			LET l_query_text = 
			"SELECT invoicehead.*,", 
			"customer.name_text,", 
			"customer.currency_code,", 
			"o_cust.name_text ", 
			"FROM invoicehead, customer, outer customer o_cust ", 
			"WHERE invoicehead.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
			"AND customer.cust_code = invoicehead.cust_code ", 
			"AND customer.cmpy_code = invoicehead.cmpy_code ", 
			"AND o_cust.cust_code = invoicehead.org_cust_code ", 
			"AND o_cust.cmpy_code = invoicehead.cmpy_code ", 
			"AND ",glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AB1_rpt_list")].sel_text CLIPPED," ", 
			"ORDER BY customer.name_text" 
		END IF 
	ELSE 
		IF glob_rec_arparms.report_ord_flag = "C" THEN 
			LET l_query_text = 
			"SELECT invoicehead.*,", 
			"customer.name_text,", 
			"customer.currency_code,", 
			"o_cust.name_text ", 
			"FROM invoicehead, customer, customer o_cust ", 
			"WHERE invoicehead.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
			"AND customer.cust_code = invoicehead.cust_code ", 
			"AND customer.cmpy_code = invoicehead.cmpy_code ", 
			"AND o_cust.cust_code = invoicehead.org_cust_code ", 
			"AND o_cust.cmpy_code = invoicehead.cmpy_code ", 
			"AND ",glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AB1_rpt_list")].sel_text CLIPPED," ", 
			"ORDER BY customer.cust_code" 
		ELSE 
			LET l_query_text = 
			"SELECT invoicehead.*,", 
			"customer.name_text,", 
			"customer.currency_code,", 
			"o_cust.name_text ", 
			"FROM invoicehead, customer, customer o_cust ", 
			"WHERE invoicehead.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
			"AND customer.cust_code = invoicehead.cust_code ", 
			"AND customer.cmpy_code = invoicehead.cmpy_code ", 
			"AND o_cust.cust_code = invoicehead.org_cust_code ", 
			"AND o_cust.cmpy_code = invoicehead.cmpy_code ", 
			"AND ",glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AB1_rpt_list")].sel_text CLIPPED," ", 
			"ORDER BY customer.name_text" 
		END IF 
	END IF 


	PREPARE choice FROM l_query_text 
	DECLARE selcurs CURSOR FOR choice 

	FOREACH selcurs INTO l_rec_invoicehead.*, 
		l_rec_customer.name_text, 
		l_rec_customer.currency_code, 
		glob_org_name_text 

		IF glob_rec_arparms.report_ord_flag = "C" THEN 
			LET l_rec_temp_rec.sort_field = l_rec_invoicehead.cust_code 
		ELSE 
			LET l_rec_temp_rec.sort_field = l_rec_customer.name_text 
		END IF 
		LET l_rec_temp_rec.org_cust_code=l_rec_invoicehead.org_cust_code 
		LET l_rec_temp_rec.inv_num=l_rec_invoicehead.inv_num 

		#---------------------------------------------------------
		OUTPUT TO REPORT AB1_rpt_list(l_rpt_idx,
		l_rec_invoicehead.*, 
		l_rec_customer.name_text, 
		l_rec_customer.currency_code, 
		glob_org_name_text, 
		l_rec_temp_rec.*)  
		IF NOT rpt_int_flag_handler2("Customer:",l_rec_customer.cust_code, l_rec_customer.name_text,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------

	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT AB1_rpt_list
	CALL rpt_finish("AB1_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 
############################################################
# END FUNCTION AB1_rpt_process(p_where_text) 
############################################################


############################################################
# REPORT AB1_rpt_list(p_rpt_idx,
#	p_rec_invoicehead, 
#	p_name_text, 
#	p_currency_code, 
#	p_org_name_text, 
#	p_temp_rec) 
#
#
############################################################
REPORT AB1_rpt_list(p_rpt_idx,
	p_rec_invoicehead, 
	p_name_text, 
	p_currency_code, 
	p_org_name_text, 
	p_temp_rec) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE p_rec_invoicehead RECORD LIKE invoicehead.*
	DEFINE p_name_text LIKE customer.name_text
	DEFINE p_currency_code LIKE customer.currency_code
	DEFINE p_org_name_text LIKE customer.name_text
	DEFINE p_temp_rec RECORD 
		sort_field NCHAR(30), 
		org_cust_code LIKE invoicehead.cust_code, 
		inv_num LIKE invoicehead.inv_num 
	END RECORD 

	DEFINE l_org_total_amt LIKE invoicehead.total_amt
	DEFINE l_org_disc_amt LIKE invoicehead.disc_amt
	DEFINE l_org_paid_amt LIKE invoicehead.paid_amt
	
	ORDER external BY p_temp_rec.sort_field,p_temp_rec.org_cust_code,p_temp_rec.inv_num 

	FORMAT 
		PAGE HEADER
			CALL rpt_set_page_num(p_rpt_idx,PAGENO) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 CLIPPED #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 CLIPPED #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text CLIPPED 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text CLIPPED 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]

		BEFORE GROUP OF p_temp_rec.sort_field 
			SKIP 1 LINE 
			PRINT COLUMN 1, "Customer Code: ", p_rec_invoicehead.cust_code CLIPPED, 
			2 SPACES, p_name_text CLIPPED , 
			COLUMN 69, p_currency_code CLIPPED

		BEFORE GROUP OF p_temp_rec.org_cust_code 
			SKIP 1 LINE 
			IF p_rec_invoicehead.org_cust_code IS NOT NULL THEN 
				PRINT COLUMN 1, "Originating Code : ", p_rec_invoicehead.org_cust_code CLIPPED, 
				2 SPACES, p_org_name_text CLIPPED , 
				COLUMN 69, p_currency_code CLIPPED
			END IF 
			LET l_org_total_amt = 0 
			LET l_org_disc_amt = 0 
			LET l_org_paid_amt = 0 
			SKIP 1 LINE 

		ON EVERY ROW 
			PRINT COLUMN 01, p_rec_invoicehead.inv_num USING "#######&", 
			COLUMN 10, p_rec_invoicehead.purchase_code CLIPPED, 
			COLUMN 41, p_rec_invoicehead.inv_date      USING "dd/mm/yy", 
			COLUMN 50, p_rec_invoicehead.year_num      USING "###&", 
			COLUMN 55, p_rec_invoicehead.period_num    USING "##&", 
			COLUMN 59, p_rec_invoicehead.total_amt     USING "--,---,--&.&&", 
			COLUMN 73, p_rec_invoicehead.disc_amt      USING "--,---,--&.&&", 
			COLUMN 87, p_rec_invoicehead.paid_amt      USING "--,---,--&.&&", 
			COLUMN 105,p_rec_invoicehead.posted_flag CLIPPED 

			LET l_org_total_amt = l_org_total_amt + p_rec_invoicehead.total_amt 
			LET l_org_disc_amt = l_org_disc_amt + p_rec_invoicehead.disc_amt 
			LET l_org_paid_amt = l_org_paid_amt + p_rec_invoicehead.paid_amt 

		AFTER GROUP OF p_temp_rec.sort_field 
			PRINT COLUMN 1, rpt_get_char_line(p_rpt_idx,NULL,"-") 
			PRINT COLUMN 1, "Customer Totals:" 
			PRINT COLUMN 1, "Invs:", NVL(GROUP COUNT(*),0)                   USING "###&", 
			COLUMN 22, "Avg: ", NVL(GROUP AVG(p_rec_invoicehead.total_amt),0)USING "--,---,--&.&&", 
			COLUMN 59, NVL(GROUP SUM(p_rec_invoicehead.total_amt),0)         USING "--,---,--&.&&", 
			COLUMN 73, NVL(GROUP SUM(p_rec_invoicehead.disc_amt),0)          USING "--,---,--&.&&", 
			COLUMN 87, NVL(GROUP SUM(p_rec_invoicehead.paid_amt),0)          USING "--,---,--&.&&"
			
		AFTER GROUP OF p_temp_rec.org_cust_code 
			IF p_rec_invoicehead.org_cust_code IS NULL THEN 
				PRINT COLUMN 1, rpt_get_char_line(p_rpt_idx,NULL,"-") 
			ELSE 
				PRINT COLUMN 1, "Originating Customer Totals:" 
				PRINT COLUMN 1, "Invs:", NVL(GROUP COUNT(*),0)                   USING "###&", 
				COLUMN 22, "Avg: ", NVL(GROUP AVG(p_rec_invoicehead.total_amt),0)USING "--,---,--&.&&", 
				COLUMN 59, l_org_total_amt                                       USING "--,---,--&.&&", 
				COLUMN 73, l_org_disc_amt                                        USING "--,---,--&.&&", 
				COLUMN 87, l_org_paid_amt                                        USING "--,---,--&.&&" 
				PRINT COLUMN 1, rpt_get_char_line(p_rpt_idx,NULL,"-") 
			END IF
			LET l_org_total_amt = 0 
			LET l_org_disc_amt = 0 
			LET l_org_paid_amt = 0
			 
		ON LAST ROW 
			SKIP 1 LINE 
			SKIP 1 LINE
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text CLIPPED WORDWRAP RIGHT MARGIN 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4]
 				
END REPORT
############################################################
# END REPORT AB1_rpt_list(p_rpt_idx,#	p_rec_invoicehead,#	p_name_text,#	p_currency_code,#	p_org_name_text,#	p_temp_rec)#
############################################################