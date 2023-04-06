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

############################################################
# FUNCTION AE2_main() 
#
# AE2 Sales Analysis by Invoice
############################################################
FUNCTION AE2_main() 
	DEFER interrupt 
	DEFER quit 
	
	CALL setModuleId("AE2")

	CREATE temp TABLE shuffle (tm_cust CHAR(8), 
	tm_name CHAR(30), 
	tm_curr CHAR(3), 
	tm_date DATE, 
	tm_doc INTEGER, 
	tm_refer CHAR(20), 
	tm_amount money(12,2), 
	tm_cost money(12,2), 
	tm_disc money(12,2), 
	tm_comm money(12,2), 
	tm_post CHAR(1), 
	tm_type CHAR(2)) with no LOG 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 
			OPEN WINDOW A177 with FORM "A177" 
			CALL windecoration_a("A177") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title
		
			MENU " Invoice Sales Analysis" 
		
				BEFORE MENU 
					CALL publish_toolbar("kandoo","AE2","menu-inv-sales-analysis") 
					CALL AE2_rpt_process(AE2_rpt_query())	
					
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				ON ACTION "Report" #COMMAND "Report" " SELECT Criteria AND PRINT REPORT"
					CALL AE2_rpt_process(AE2_rpt_query())		
		
				ON ACTION "Print Manager"		#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "Exit" #COMMAND KEY (interrupt, "E") "Exit" " Exit TO menus"
					EXIT MENU 
		
			END MENU 
		
			CLOSE WINDOW A177 
	 
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL AE2_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW A177 with FORM "A177" 
			CALL windecoration_a("A177") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(AE2_rpt_query()) #save where clause in env 
			CLOSE WINDOW A177 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL AE2_rpt_process(get_url_sel_text())
	END CASE 				
END FUNCTION 


############################################################
# FUNCTION AE2_rpt_query()  
#
#
############################################################
FUNCTION AE2_rpt_query() 
	DEFINE l_where_text STRING
	
	CLEAR FORM 
	
	MESSAGE kandoomsg2("U", 1001, "")#1001 " Enter Selection Criteria - ESC TO Continue"
	CONSTRUCT BY NAME l_where_text ON customer.cust_code, 
	customer.name_text, 
	customer.state_code, 
	customer.post_code, 
	customer.country_code, --@db-patch_2020_10_04--
	customer.currency_code, 
	customer.type_code, 
	invoicehead.inv_date, 
	invoicehead.entry_date, 
	invoicehead.year_num, 
	invoicehead.period_num, 
	invoicehead.sale_code, 
	customer.term_code, 
	customer.tax_code 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","AE2","construct-customer") 

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
		LET glob_rec_rpt_selector.ref1_ind = upshift( fgl_winbutton("Tax Include", "Include Tax in invoice totals?", "No", "Yes|No", "question", 1)) 
		RETURN l_where_text
	END IF 
END FUNCTION 


#####################################################################
# FUNCTION AE2_rpt_process(p_where_text) 
#
#
#####################################################################
FUNCTION AE2_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT  
	DEFINE l_rec_credithead RECORD LIKE credithead.* 
	DEFINE l_rec_invoicehead RECORD LIKE invoicehead.* 
	DEFINE l_rec_customer RECORD LIKE customer.*
	DEFINE l_rec_tempdoc RECORD 
		tm_cust LIKE customer.cust_code, 
		tm_name LIKE customer.name_text, 
		tm_curr LIKE customer.currency_code, 
		tm_date LIKE customer.setup_date, 
		tm_doc INTEGER, 
		tm_refer CHAR(20), 
		tm_amount money(12,2), 
		tm_cost money(12,2), 
		tm_disc money(12,2), 
		tm_comm money(12,2), 
		tm_post CHAR(1), 
		tm_type CHAR(2) 
	END RECORD 
	DEFINE i SMALLINT
	
	DELETE FROM shuffle WHERE 1=1 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"AE2_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT AE2_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	LET l_query_text = 
	"SELECT unique invoicehead.*,", 
	"customer.name_text,", 
	"customer.currency_code ", 
	"FROM invoicehead,", 
	"customer ", 
	"WHERE customer.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND invoicehead.cmpy_code = customer.cmpy_code ", 
	"AND invoicehead.cust_code = customer.cust_code ", 
	" AND ", p_where_text CLIPPED ," ",
	"ORDER BY invoicehead.cmpy_code,", 
	"invoicehead.cust_code,", 
	"invoicehead.inv_num" 

	PREPARE s_invoice FROM l_query_text 
	DECLARE c_invoice CURSOR FOR s_invoice 
	
	FOREACH c_invoice INTO l_rec_invoicehead.*, 
		l_rec_customer.name_text, 
		l_rec_customer.currency_code 
		LET l_rec_tempdoc.tm_cust = l_rec_invoicehead.cust_code 
		LET l_rec_tempdoc.tm_name = l_rec_customer.name_text 
		LET l_rec_tempdoc.tm_curr = l_rec_customer.currency_code 
		LET l_rec_tempdoc.tm_date = l_rec_invoicehead.inv_date 
		LET l_rec_tempdoc.tm_doc = l_rec_invoicehead.inv_num 
		LET l_rec_tempdoc.tm_refer = l_rec_invoicehead.purchase_code 
		LET l_rec_tempdoc.tm_comm = l_rec_invoicehead.disc_taken_amt 
		LET l_rec_tempdoc.tm_post = l_rec_invoicehead.posted_flag 
		
		IF l_rec_invoicehead.inv_ind = "4" THEN 
			LET l_rec_tempdoc.tm_type = "AD" 
		ELSE 
			LET l_rec_tempdoc.tm_type = TRAN_TYPE_INVOICE_IN 
		END IF
		 
		IF glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AE2_rpt_list")].ref1_ind = "N" THEN 
			LET l_rec_invoicehead.total_amt = l_rec_invoicehead.total_amt 
			- l_rec_invoicehead.tax_amt 
		END IF 
		LET l_rec_tempdoc.tm_amount = 
		conv_currency(l_rec_invoicehead.total_amt, glob_rec_kandoouser.cmpy_code, 
		l_rec_customer.currency_code, "F", 
		l_rec_invoicehead.inv_date, "S") 
		LET l_rec_tempdoc.tm_cost = 
		conv_currency(l_rec_invoicehead.cost_amt, glob_rec_kandoouser.cmpy_code, 
		l_rec_customer.currency_code, "F", 
		l_rec_invoicehead.inv_date, "S")
		 
		IF l_rec_invoicehead.disc_amt IS NULL THEN 
			LET l_rec_tempdoc.tm_disc = 0 
		ELSE 
			LET l_rec_tempdoc.tm_disc = 
			conv_currency(l_rec_invoicehead.disc_amt, glob_rec_kandoouser.cmpy_code, 
			l_rec_customer.currency_code, "F", 
			l_rec_invoicehead.inv_date, "S") 
		END IF 

		INSERT INTO shuffle VALUES (l_rec_tempdoc.*) 
		INITIALIZE l_rec_tempdoc.* TO NULL 
	END FOREACH 
	
	FOR i = 1 TO (length(p_where_text)-15) 
		IF p_where_text[i,i+14] = "invoicehead.inv" THEN 
			LET p_where_text[i,i+14] = "credithead.cred" 
		END IF 
	END FOR 
	FOR i = 1 TO (length(p_where_text)-11) 
		IF p_where_text[i,i+10] = "invoicehead" THEN 
			LET p_where_text[i,i+10] = " credithead" 
		END IF 
	END FOR 

	LET l_query_text = 
	"SELECT credithead.*,", 
	"customer.name_text,", 
	"customer.currency_code ", 
	"FROM credithead,", 
	"customer ", 
	"WHERE customer.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND credithead.cmpy_code = customer.cmpy_code ", 
	"AND credithead.cust_code = customer.cust_code ", 
	" AND ", p_where_text CLIPPED ," ", 
	"ORDER BY credithead.cmpy_code,", 
	"credithead.cust_code,", 
	"credithead.cred_num" 

	PREPARE s_credit FROM l_query_text 
	DECLARE c_credit CURSOR FOR s_credit 

	FOREACH c_credit INTO l_rec_credithead.*, 
		l_rec_customer.name_text, 
		l_rec_customer.currency_code 
		LET l_rec_tempdoc.tm_cust = l_rec_credithead.cust_code 
		LET l_rec_tempdoc.tm_name = l_rec_customer.name_text 
		LET l_rec_tempdoc.tm_curr = l_rec_customer.currency_code 
		LET l_rec_tempdoc.tm_date = l_rec_credithead.cred_date 
		LET l_rec_tempdoc.tm_doc = l_rec_credithead.cred_num 
		LET l_rec_tempdoc.tm_refer = l_rec_credithead.cred_text 
		LET l_rec_tempdoc.tm_comm = 0 
		LET l_rec_tempdoc.tm_disc = 0 
		LET l_rec_tempdoc.tm_post = l_rec_credithead.posted_flag 
		IF l_rec_credithead.cred_ind = "4" THEN 
			LET l_rec_tempdoc.tm_type = "AD" 
		ELSE 
			LET l_rec_tempdoc.tm_type = TRAN_TYPE_CREDIT_CR 
		END IF 
		IF glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AE2_rpt_list")] = "N" THEN 
			LET l_rec_credithead.total_amt = l_rec_credithead.total_amt	- l_rec_credithead.tax_amt 
		END IF 
		LET l_rec_tempdoc.tm_amount = conv_currency(l_rec_credithead.total_amt, glob_rec_kandoouser.cmpy_code, 
		l_rec_customer.currency_code, "F",	l_rec_credithead.cred_date, "S") 
		LET l_rec_tempdoc.tm_amount = 0 - l_rec_tempdoc.tm_amount + 0 
		LET l_rec_tempdoc.tm_cost = 
		conv_currency(l_rec_credithead.cost_amt, glob_rec_kandoouser.cmpy_code, 
		l_rec_customer.currency_code, "F", 
		l_rec_credithead.cred_date, "S") 
		LET l_rec_tempdoc.tm_cost = 0 - l_rec_tempdoc.tm_cost + 0 
		DISPLAY "" at 1,25 
		DISPLAY l_rec_tempdoc.tm_cust at 1,25 

		DISPLAY "" at 2,25 
		DISPLAY l_rec_tempdoc.tm_doc at 2,25 

		INSERT INTO shuffle VALUES (l_rec_tempdoc.*) 
		INITIALIZE l_rec_tempdoc.* TO NULL 
	END FOREACH 
	
	DECLARE selcurs CURSOR FOR 
	SELECT * 
	FROM shuffle 
	ORDER BY tm_cust, tm_doc 
	
	FOREACH selcurs INTO l_rec_tempdoc.* 
		#---------------------------------------------------------
		OUTPUT TO REPORT AE2_rpt_list(l_rpt_idx,l_rec_tempdoc.*)  
		IF NOT rpt_int_flag_handler2("Inv. Customer:",l_rec_tempdoc.tm_cust, l_rec_tempdoc.tm_doc,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------			
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT AE2_rpt_list
	RETURN rpt_finish("AE2_rpt_list")
	#------------------------------------------------------------
 
END FUNCTION 


############################################################
# REPORT AE2_rpt_list(p_rec_tempdoc)  
#
#
############################################################
REPORT AE2_rpt_list(p_rpt_idx,p_rec_tempdoc) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_tempdoc RECORD 
		tm_cust LIKE customer.cust_code, 
		tm_name LIKE customer.name_text, 
		tm_curr LIKE customer.currency_code, 
		tm_date LIKE customer.setup_date, 
		tm_doc INTEGER, 
		tm_refer CHAR(20), 
		tm_amount money(12,2), 
		tm_cost money(12,2), 
		tm_disc money(12,2), 
		tm_comm money(12,2), 
		tm_post CHAR(1), 
		tm_type CHAR(2) 
	END RECORD 
	DEFINE l_len INTEGER
	DEFINE l_s INTEGER
	DEFINE l_net_profit money(12,2) 

	OUTPUT 
--	left margin 0 
	ORDER external BY p_rec_tempdoc.tm_date, 
	p_rec_tempdoc.tm_doc 
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2]
			 
			PRINT COLUMN 1, "(** all amounts local currency at rate ON day OF transaction **)" 
			IF glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AE2_rpt_list")] = "N" THEN 
				PRINT COLUMN 5, "Invoice Amounts are exclusive of Tax " 
			ELSE 
				PRINT COLUMN 5, "Invoice Amounts are inclusive of Tax " 
			END IF
			 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  
			PRINT COLUMN 1, "Date", 
			COLUMN 9, "Trans", 
			COLUMN 16, "Doc", 
			COLUMN 22, "Customer", 
			COLUMN 61, "Invoice", 
			COLUMN 75, "Invoice", 
			COLUMN 88, "Discount", 
			COLUMN 116, "Net", 
			COLUMN 125, "Profit" 
			PRINT COLUMN 9, "Type", 
			COLUMN 17, "#", 
			COLUMN 22, "Name", 
			COLUMN 62, "Amount", 
			COLUMN 78, "Cost", 
			COLUMN 90, "Amount", 
			COLUMN 113, "Profit", 
			COLUMN 127, "%"
			 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  

		ON EVERY ROW 
			LET l_net_profit = p_rec_tempdoc.tm_amount 
			- ( p_rec_tempdoc.tm_cost 
			+ p_rec_tempdoc.tm_disc) 
			IF p_rec_tempdoc.tm_amount != 0.00 
			OR p_rec_tempdoc.tm_amount IS NULL THEN 
				PRINT COLUMN 1, p_rec_tempdoc.tm_date USING "dd/mm/yy", 
				COLUMN 10, p_rec_tempdoc.tm_type, 
				COLUMN 13, p_rec_tempdoc.tm_doc USING "########", 
				COLUMN 22, p_rec_tempdoc.tm_name, 
				COLUMN 55, p_rec_tempdoc.tm_amount USING "--,---,--&.&&", 
				COLUMN 69, p_rec_tempdoc.tm_cost USING "--,---,--&.&&", 
				COLUMN 83, p_rec_tempdoc.tm_disc USING "--,---,--&.&&", 
				COLUMN 106,l_net_profit USING "--,---,--&.&&", 
				COLUMN 124,(p_rec_tempdoc.tm_amount - p_rec_tempdoc.tm_cost) 
				/ p_rec_tempdoc.tm_amount * 100 USING "###.##%" 
			ELSE 
				PRINT COLUMN 1, p_rec_tempdoc.tm_date USING "dd/mm/yy", 
				COLUMN 10, p_rec_tempdoc.tm_type, 
				COLUMN 13, p_rec_tempdoc.tm_doc USING "########", 
				COLUMN 22, p_rec_tempdoc.tm_name, 
				COLUMN 55, p_rec_tempdoc.tm_amount USING "--,---,--&.&&", 
				COLUMN 69, p_rec_tempdoc.tm_cost USING "--,---,--&.&&", 
				COLUMN 83, p_rec_tempdoc.tm_disc USING "--,---,--&.&&", 
				COLUMN 106,l_net_profit USING "--,---,--&.&&", 
				COLUMN 125," 0.0%" 
			END IF 
		ON LAST ROW 
			IF sum(p_rec_tempdoc.tm_amount) != 0 THEN 
				PRINT COLUMN 40,"----------------------------------------------", 
				"----------------------------------------------" 

				PRINT COLUMN 1, "Report Totals in Base Currency:", 
				COLUMN 52, sum(p_rec_tempdoc.tm_amount) USING "-----,---,--&.&&", 
				COLUMN 80, sum(p_rec_tempdoc.tm_disc) USING "-----,---,--&.&&", 
				COLUMN 124, (sum(p_rec_tempdoc.tm_amount) 
				- sum(p_rec_tempdoc.tm_cost)) / 
				sum(p_rec_tempdoc.tm_amount) 
				* 100 USING "###.##%" 

				PRINT COLUMN 66, sum(p_rec_tempdoc.tm_cost) USING "-----,---,--&.&&", 
				COLUMN 103, sum(p_rec_tempdoc.tm_amount) - 
				(sum(p_rec_tempdoc.tm_cost) 
				+ sum(p_rec_tempdoc.tm_disc) 
				+ sum(p_rec_tempdoc.tm_comm)) USING "-----,---,--&.&&" 
				SKIP 1 line 
			END IF 
			SKIP 1 line 
			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	 
END REPORT 