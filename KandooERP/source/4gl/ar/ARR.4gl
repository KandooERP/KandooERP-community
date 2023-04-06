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
GLOBALS "../ar/AR_GROUP_GLOBALS.4gl"
GLOBALS "../ar/ARR_GLOBALS.4gl" 

###################################################################
# FUNCTION ARR_main()
#
# ARR Invoice Aging by Purchase Code
# New Account Aging by Reference REPORT
###################################################################
FUNCTION ARR_main() 
	DEFER quit 
	DEFER interrupt

	CALL setModuleId("ARR")
	CALL init_report_ar() #report default data from db-arparms
	CALL AR_temp_tables_create()

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query

		WHEN RPT_OP_MENU #UI/MENU Mode 	
			OPEN WINDOW A210 with FORM "A210" 
			CALL windecoration_a("A210") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
		
			LET glob_rec_rpt_selector.ref1_text = glob_rec_arparms.inv_ref1_text
			--LET glob_temp_text = glob_rec_arparms.inv_ref1_text clipped, "................" 
			--LET glob_ref_text_1 = glob_temp_text[1,16] 	
			DISPLAY glob_rec_arparms.inv_ref1_text TO inv_ref1_text
			--DISPLAY glob_ref_text_1 TO ref_text_1
			 
			MENU " Invoice Aging" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","ARR","menu-invoice-aging") 
					CALL ARR_rpt_process(ARR_rpt_query())
					CALL AR_temp_tables_delete()
					
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				ON ACTION "Report" #COMMAND "Report" " SELECT Criteria AND PRINT REPORT"
					CALL ARR_rpt_process(ARR_rpt_query())
					CALL AR_temp_tables_delete()
		
				ON ACTION "Print Manager" #COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "CANCEL" #COMMAND KEY (interrupt, "E") "Exit" " Exit TO menus"
					EXIT MENU 
		
			END MENU 
			
			CLOSE WINDOW A210 
	 
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL ARR_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW A210 with FORM "A210" 
			CALL windecoration_a("A210") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(ARR_rpt_query()) #save where clause in env 
			CLOSE WINDOW A210 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL ARR_rpt_process(get_url_sel_text())
	END CASE
	
	CALL AR_temp_tables_drop()

END FUNCTION 

###################################################################
# FUNCTION ARR_rpt_query()
#
#
###################################################################
FUNCTION ARR_rpt_query() 
	DEFINE l_where_text STRING 
	DEFINE l_aging_date DATE

	LET l_aging_date = today 
	MESSAGE kandoomsg2("U",1001,"") 

	#1001 Enter Selection Criteria;  OK TO Continue.
	INPUT l_aging_date WITHOUT DEFAULTS FROM aging_date 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","ARR","inp-aging") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER FIELD aging_date 
			IF l_aging_date IS NULL THEN 
				ERROR kandoomsg2("U",9102,"") 
				#9102 Value must be entered.
				NEXT FIELD aging_date 
			END IF 


	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL
	ELSE
		LET glob_rec_rpt_selector.ref1_date = l_aging_date 
	END IF 

	CONSTRUCT BY NAME l_where_text ON 
	customer.cust_code, 
	customer.name_text, 
	customer.currency_code, 
	customer.type_code, 
	invoicehead.purchase_code, 
	invoicehead.term_code, 
	invoicehead.tax_code, 
	invoicehead.year_num, 
	invoicehead.period_num 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","ARR","construct-customer") 

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

	
###################################################################
# FUNCTION ARR_rpt_process(p_where_text)
#
#
###################################################################
FUNCTION ARR_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT
	DEFINE l_aging_date DATE   
	DEFINE l_rec_invoice RECORD 
		cust_code LIKE customer.cust_code, 
		name_text LIKE customer.name_text, 
		currency_code LIKE customer.currency_code, 
		type_code LIKE customer.type_code, 
		purchase_code LIKE invoicehead.purchase_code, 
		term_code LIKE invoicehead.term_code, 
		tax_code LIKE invoicehead.tax_code, 
		year_num LIKE invoicehead.year_num, 
		period_num LIKE invoicehead.period_num, 
		inv_num LIKE invoicehead.inv_num, 
		inv_date LIKE invoicehead.inv_date, 
		due_date LIKE invoicehead.inv_date, 
		total_amt LIKE invoicehead.total_amt, 
		paid_amt LIKE invoicehead.paid_amt, 
		conv_qty LIKE invoicehead.conv_qty 
	END RECORD 
	DEFINE l_rec_aged_amts RECORD 
		days_late SMALLINT, 
		unpaid_amt LIKE invoicehead.total_amt, 
		curr_amt LIKE invoicehead.total_amt, 
		o30_amt LIKE invoicehead.total_amt, 
		o60_amt LIKE invoicehead.total_amt, 
		o90_amt LIKE invoicehead.total_amt, 
		plus90_amt LIKE invoicehead.total_amt 
	END RECORD 
	DEFINE l_prev_purch_code LIKE invoicehead.purchase_code 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"ARR_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	

	START REPORT ARR_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	LET l_aging_date = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ARR_rpt_list")].ref1_date
	
	CALL set_aging(glob_rec_kandoouser.cmpy_code,l_aging_date) 

	LET l_query_text = 
	"SELECT invoicehead.cust_code, ", 
	"customer.name_text, ", 
	"customer.currency_code, ", 
	"customer.type_code, ", 
	"invoicehead.purchase_code, ", 
	"invoicehead.term_code, ", 
	"invoicehead.tax_code, ", 
	"invoicehead.year_num, ", 
	"invoicehead.period_num, ", 
	"invoicehead.inv_num, ", 
	"invoicehead.inv_date, ", 
	"invoicehead.due_date, ", 
	"invoicehead.total_amt, ", 
	"invoicehead.paid_amt, ", 
	"invoicehead.conv_qty ", 
	"FROM invoicehead, customer ", 
	"WHERE customer.cmpy_code = \"",glob_rec_kandoouser.cmpy_code, "\" ", 
	"AND invoicehead.cmpy_code = customer.cmpy_code ", 
	"AND invoicehead.cust_code = customer.cust_code ", 
	"AND ", p_where_text CLIPPED," ",
	"AND invoicehead.total_amt != invoicehead.paid_amt ", 
	"AND invoicehead.posted_flag != \"V\" ", 
	"ORDER BY invoicehead.purchase_code, ", 
	"invoicehead.inv_date, ", 
	"invoicehead.inv_num" 

	LET l_prev_purch_code = " " 

	PREPARE q_invoicehead FROM l_query_text 
	DECLARE c_invoicehead CURSOR FOR q_invoicehead 

	FOREACH c_invoicehead INTO l_rec_invoice.* 
		IF int_flag OR quit_flag THEN 
			#8503 Continue Report (Y/N)
			IF kandoomsg("U",8503,"") = "N" THEN 
				MESSAGE kandoomsg2("U",9501,"") 
				#8503 Printing was aborted.
				LET int_flag = true 
				EXIT FOREACH 
			END IF 
		END IF 
		IF l_rec_invoice.conv_qty IS NOT NULL THEN 
			IF l_rec_invoice.conv_qty != 0 THEN 
				LET l_rec_invoice.total_amt = l_rec_invoice.total_amt / l_rec_invoice.conv_qty 
				LET l_rec_invoice.paid_amt = l_rec_invoice.paid_amt / l_rec_invoice.conv_qty 
			END IF 
		END IF 

		LET l_rec_aged_amts.days_late = get_age_bucket(TRAN_TYPE_INVOICE_IN,l_rec_invoice.due_date) 
		LET l_rec_aged_amts.unpaid_amt = 
		l_rec_invoice.total_amt - l_rec_invoice.paid_amt 

		LET l_rec_aged_amts.plus90_amt = 0 
		LET l_rec_aged_amts.o90_amt = 0 
		LET l_rec_aged_amts.o60_amt = 0 
		LET l_rec_aged_amts.o30_amt = 0 
		LET l_rec_aged_amts.curr_amt = 0 

		CASE 
			WHEN l_rec_aged_amts.days_late > 90 
				LET l_rec_aged_amts.plus90_amt = l_rec_aged_amts.unpaid_amt 
			WHEN l_rec_aged_amts.days_late > 60 
				LET l_rec_aged_amts.o90_amt = l_rec_aged_amts.unpaid_amt 
			WHEN l_rec_aged_amts.days_late > 30 
				LET l_rec_aged_amts.o60_amt = l_rec_aged_amts.unpaid_amt 
			WHEN l_rec_aged_amts.days_late > 0 
				LET l_rec_aged_amts.o30_amt = l_rec_aged_amts.unpaid_amt 
			OTHERWISE 
				LET l_rec_aged_amts.curr_amt = l_rec_aged_amts.unpaid_amt 
		END CASE 

		IF l_prev_purch_code != l_rec_invoice.purchase_code THEN 
			MESSAGE l_rec_invoice.purchase_code 
			#DISPLAY l_rec_invoice.purchase_code AT 1,18

			LET l_prev_purch_code = l_rec_invoice.purchase_code 
		END IF 
		#---------------------------------------------------------
		OUTPUT TO REPORT ARR_rpt_list(l_rpt_idx,l_rec_invoice.*,	l_rec_aged_amts.*,l_aging_date) 
		IF NOT rpt_int_flag_handler2("Cstomer Invoice:",l_rec_invoice.cust_code, l_rec_invoice.inv_num,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------	
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT ARR_rpt_list
	RETURN rpt_finish("ARR_rpt_list")
	#------------------------------------------------------------

END FUNCTION 


###################################################################
# REPORT ARR_rpt_list(p_rpt_idx,p_rec_invoice, p_rec_aged_amts) 
#
#
###################################################################
REPORT ARR_rpt_list(p_rpt_idx,p_rec_invoice, p_rec_aged_amts, p_aging_date) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_invoice RECORD 
		cust_code LIKE customer.cust_code, 
		name_text LIKE customer.name_text, 
		currency_code LIKE customer.currency_code, 
		type_code LIKE customer.type_code, 
		purchase_code LIKE invoicehead.purchase_code, 
		term_code LIKE invoicehead.term_code, 
		tax_code LIKE invoicehead.tax_code, 
		year_num LIKE invoicehead.year_num, 
		period_num LIKE invoicehead.period_num, 
		inv_num LIKE invoicehead.inv_num, 
		inv_date LIKE invoicehead.inv_date, 
		due_date LIKE invoicehead.inv_date, 
		total_amt LIKE invoicehead.total_amt, 
		paid_amt LIKE invoicehead.paid_amt, 
		conv_qty LIKE invoicehead.conv_qty 
	END RECORD
	DEFINE p_rec_aged_amts RECORD 
		days_late SMALLINT, 
		unpaid_amt LIKE invoicehead.total_amt, 
		curr_amt LIKE invoicehead.total_amt, 
		o30_amt LIKE invoicehead.total_amt, 
		o60_amt LIKE invoicehead.total_amt, 
		o90_amt LIKE invoicehead.total_amt, 
		plus90_amt LIKE invoicehead.total_amt 
	END RECORD 
	DEFINE p_aging_date DATE
	DEFINE l_line1 NCHAR(130) 
	DEFINE l_line2 NCHAR(130)
	
	ORDER EXTERNAL BY p_rec_invoice.purchase_code,p_rec_invoice.inv_date,p_rec_invoice.inv_num 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,PAGENO) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 CLIPPED #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 CLIPPED #wasl_arr_line[2] 
			PRINT COLUMN 01, "**All amounts in local currency AT rate on day of transaction**"
			PRINT COLUMN 01, "  Aging FROM: ", p_aging_date USING "dd/mm/yy"
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text CLIPPED 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text CLIPPED 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]	


	BEFORE GROUP OF p_rec_invoice.purchase_code 
		PRINT COLUMN 1, glob_rec_arparms.inv_ref1_text CLIPPED,":"," ", p_rec_invoice.purchase_code CLIPPED 

	ON EVERY ROW 
		PRINT 
		COLUMN 03, p_rec_invoice.inv_date     USING "dd/mm/yy", 
		COLUMN 12, p_rec_invoice.inv_num      USING "########", 
		COLUMN 21, p_rec_invoice.cust_code CLIPPED, 
		COLUMN 30, p_rec_aged_amts.days_late  USING "---&", 
		COLUMN 35, p_rec_invoice.total_amt    USING "--,---,--&.&&", 
		COLUMN 49, p_rec_aged_amts.unpaid_amt USING "--,---,--&.&&", 
		COLUMN 63, p_rec_aged_amts.curr_amt   USING "--,---,--&.&&", 
		COLUMN 77, p_rec_aged_amts.o30_amt    USING "--,---,--&.&&", 
		COLUMN 91, p_rec_aged_amts.o60_amt    USING "--,---,--&.&&", 
		COLUMN 105,p_rec_aged_amts.o90_amt    USING "--,---,--&.&&", 
		COLUMN 119,p_rec_aged_amts.plus90_amt USING "--,---,--&.&&" 

	AFTER GROUP OF p_rec_invoice.purchase_code 
		NEED 3 LINES 
		PRINT COLUMN 45,"---------------------------------------------------------------------------------------"
		PRINT 
		COLUMN 45, GROUP SUM(p_rec_aged_amts.unpaid_amt) USING "--,---,---,--&.&&", 
		COLUMN 73, GROUP SUM(p_rec_aged_amts.o30_amt) 	 USING "--,---,---,--&.&&", 
		COLUMN 101,GROUP SUM(p_rec_aged_amts.o90_amt)	 USING "--,---,---,--&.&&" 
		PRINT 
		COLUMN 59, GROUP SUM(p_rec_aged_amts.curr_amt)   USING "--,---,---,--&.&&", 
		COLUMN 87, GROUP SUM(p_rec_aged_amts.o60_amt) 	 USING "--,---,---,--&.&&", 
		COLUMN 115,GROUP SUM(p_rec_aged_amts.plus90_amt) USING "--,---,---,--&.&&" 

	ON LAST ROW 
		PRINT COLUMN 45,"---------------------------------------------------------------------------------------"  
		PRINT 
		COLUMN 45, SUM(p_rec_aged_amts.unpaid_amt) 		 USING "--,---,---,--&.&&", 
		COLUMN 73, SUM(p_rec_aged_amts.o30_amt) 		    USING "--,---,---,--&.&&", 
		COLUMN 101,SUM(p_rec_aged_amts.o90_amt)		    USING "--,---,---,--&.&&" 
		PRINT 
		COLUMN 59, SUM(p_rec_aged_amts.curr_amt)		    USING "--,---,---,--&.&&", 
		COLUMN 87, SUM(p_rec_aged_amts.o60_amt) 		    USING "--,---,---,--&.&&", 
		COLUMN 115,SUM(p_rec_aged_amts.plus90_amt)		 USING "--,---,---,--&.&&" 
		SKIP 1 LINE 
		#End Of Report
		IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
			PRINT COLUMN 01,"Selection Criteria:" 
			PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text CLIPPED wordwrap right margin 100 
		END IF 
		PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	

END REPORT 
