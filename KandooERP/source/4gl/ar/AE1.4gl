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
# FUNCTION AE1_main() 
#
# Sales Analysis by Invoice
############################################################
FUNCTION AE1_main() 
	DEFER interrupt 
	DEFER quit 
	
	CALL setModuleId("AE1") 

	CREATE temp TABLE shuffle (tm_cust CHAR(8), 
	tm_name CHAR(30), 
	tm_date DATE, 
	tm_type CHAR(2), 
	tm_doc INTEGER, 
	tm_refer CHAR(20), 
	tm_amount money(12,2), 
	tm_cost money(12,2), 
	tm_comm money(12,2), 
	tm_dis money(12,2), 
	tm_post CHAR(1)) with no LOG 


	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 	

			OPEN WINDOW A177 with FORM "A177" 
			CALL windecoration_a("A177") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title
		
			MENU " Sales Analysis" 
		
				BEFORE MENU 
					CALL publish_toolbar("kandoo","AE1","menu-sales-analysis") 
					CALL AE1_rpt_process(AE1_rpt_query())
					
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
					
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
		
				COMMAND "Report" " SELECT Criteria AND PRINT REPORT" 
					CALL AE1_rpt_process(AE1_rpt_query())
		
				ON ACTION "Print Manager" #COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
					 
				ON ACTION "CANCEL" 	#COMMAND KEY (interrupt, "E") "Exit" " Exit TO menus"
					EXIT MENU 
		
			END MENU 
			CLOSE WINDOW A177
	 
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL AE1_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW A177 with FORM "A177" 
			CALL windecoration_a("A177") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(AE1_rpt_query()) #save where clause in env 
			CLOSE WINDOW A177 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL AE1_rpt_process(get_url_sel_text())
	END CASE 			
		 
END FUNCTION 


############################################################
# FUNCTION AE1_rpt_query() 
#
#
############################################################
FUNCTION AE1_rpt_query() 
	DEFINE l_where_text STRING
	
	CLEAR FORM 
	MESSAGE kandoomsg2("U", 1001, "") 

	#1001 " Enter Selection Criteria - ESC TO Continue "
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
			CALL publish_toolbar("kandoo","AE1","construct-customer") 

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
		LET glob_rec_rpt_selector.ref1_ind = upshift(fgl_winbutton("Tax Include", "Include Tax in invoice totals?", "No", "Yes|No", "question", 1))		RETURN l_where_text
	END IF 
END FUNCTION


############################################################
# FUNCTION AE1_rpt_process() 
#
#
############################################################
FUNCTION AE1_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT 
	DEFINE l_rec_tempdoc RECORD 
		tm_cust LIKE customer.cust_code, 
		tm_name LIKE customer.name_text, 
		tm_date LIKE customer.setup_date, 
		tm_type CHAR(2), 
		tm_doc INTEGER, 
		tm_refer CHAR(20), 
		tm_amount money(12,2), 
		tm_cost money(12,2), 
		tm_comm money(12,2), 
		tm_dis money(12,2), 
		tm_post CHAR(1) 
	END RECORD
	DEFINE l_rec_invoicehead RECORD 
		cust_code LIKE invoicehead.cust_code, 
		name_text LIKE customer.name_text, 
		inv_num LIKE invoicehead.inv_num, 
		inv_date LIKE invoicehead.inv_date, 
		purchase_code LIKE invoicehead.purchase_code, 
		total_amt LIKE invoicehead.total_amt, 
		cost_amt LIKE invoicehead.cost_amt, 

		tax_amt LIKE invoicehead.tax_amt, 
		disc_amt LIKE invoicehead.disc_amt, 
		disc_taken_amt LIKE invoicehead.disc_taken_amt, 
		posted_flag LIKE invoicehead.posted_flag, 
		inv_ind LIKE invoicehead.inv_ind 
	END RECORD
	DEFINE l_rec_credithead RECORD 
		cust_code LIKE credithead.cust_code, 
		name_text LIKE customer.name_text, 
		cred_num LIKE credithead.cred_num, 
		cred_date LIKE credithead.cred_date, 
		cred_ind LIKE credithead.cred_ind, 
		cred_text LIKE credithead.cred_text, 
		total_amt LIKE credithead.total_amt, 
		cost_amt LIKE credithead.cost_amt, 
		tax_amt LIKE credithead.tax_amt, 
		appl_amt LIKE credithead.appl_amt, 
		posted_flag LIKE credithead.posted_flag 
	END RECORD
	DEFINE l_temp_rec RECORD 
		sort_field CHAR(30),
		tm_name CHAR(30),
		tm_date DATE
	END RECORD 
	DEFINE i SMALLINT
	DEFINE l_rec_customer RECORD LIKE customer.*

	DELETE FROM shuffle WHERE 1=1 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"AE1_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT AE1_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	IF glob_rec_arparms.report_ord_flag = "C" THEN 
		LET l_query_text = 
		"SELECT unique invoicehead.cust_code,", 
		"customer.name_text,", 
		"invoicehead.inv_num,", 
		"invoicehead.inv_date,", 
		"invoicehead.purchase_code,", 
		"invoicehead.total_amt,", 
		"invoicehead.cost_amt,", 
		"invoicehead.tax_amt,", 
		"invoicehead.disc_amt,", 
		"invoicehead.disc_taken_amt,", 
		"invoicehead.posted_flag ", 
		"FROM invoicehead,", 
		"customer ", 
		"WHERE customer.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
		"AND invoicehead.cust_code = customer.cust_code ", 
		"AND invoicehead.cmpy_code = customer.cmpy_code ", 
		" AND ", p_where_text CLIPPED ," ",
		"ORDER BY invoicehead.cust_code" 
	ELSE 
		LET l_query_text = 
		"SELECT unique invoicehead.cust_code,", 
		"customer.name_text,", 
		"invoicehead.inv_num,", 
		"invoicehead.inv_date,", 
		"invoicehead.purchase_code,", 
		"invoicehead.total_amt,", 
		"invoicehead.cost_amt,", 
		"invoicehead.tax_amt,", 
		"invoicehead.disc_amt,", 
		"invoicehead.disc_taken_amt,", 
		"invoicehead.posted_flag ", 
		"FROM invoicehead,", 
		"customer ", 
		"WHERE customer.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
		"AND invoicehead.cust_code = customer.cust_code ", 
		"AND invoicehead.cmpy_code = customer.cmpy_code ", 
		" AND ", p_where_text CLIPPED ," ",
		"ORDER BY customer.name_text" 
	END IF 

	PREPARE invoicer FROM l_query_text 
	DECLARE invcurs CURSOR FOR invoicer 

	FOREACH invcurs INTO l_rec_invoicehead.* 
		LET l_rec_tempdoc.tm_cust = l_rec_invoicehead.cust_code 
		SELECT * 
		INTO l_rec_customer.* 
		FROM customer 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = l_rec_invoicehead.cust_code 
		LET l_rec_tempdoc.tm_name = l_rec_invoicehead.name_text 
		LET l_rec_tempdoc.tm_date = l_rec_invoicehead.inv_date 
		IF l_rec_invoicehead.inv_ind = "4" THEN 
			LET l_rec_tempdoc.tm_type = "AD" 
		ELSE 
			LET l_rec_tempdoc.tm_type = TRAN_TYPE_INVOICE_IN 
		END IF 
		LET l_rec_tempdoc.tm_doc = l_rec_invoicehead.inv_num 
		LET l_rec_tempdoc.tm_refer = l_rec_invoicehead.purchase_code 
		IF glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AE1_rpt_list")].ref1_ind = "N" THEN 
			LET l_rec_invoicehead.total_amt = l_rec_invoicehead.total_amt 
			- l_rec_invoicehead.tax_amt 
		END IF 
		LET l_rec_tempdoc.tm_amount = conv_currency(l_rec_invoicehead.total_amt, 
		glob_rec_kandoouser.cmpy_code, 
		l_rec_customer.currency_code, 
		"F", 
		l_rec_invoicehead.inv_date, 
		"S") 
		LET l_rec_tempdoc.tm_post = l_rec_invoicehead.posted_flag 
		LET l_rec_tempdoc.tm_cost = conv_currency(l_rec_invoicehead.cost_amt, 
		glob_rec_kandoouser.cmpy_code, 
		l_rec_customer.currency_code, 
		"F", 
		l_rec_invoicehead.inv_date, 
		"S") 
		IF l_rec_invoicehead.disc_amt IS NULL THEN 
			LET l_rec_tempdoc.tm_dis = 0 
		ELSE 
			LET l_rec_tempdoc.tm_dis = conv_currency(l_rec_invoicehead.disc_amt, 
			glob_rec_kandoouser.cmpy_code, 
			l_rec_customer.currency_code, 
			"F", 
			l_rec_invoicehead.inv_date, 
			"S") 
		END IF 
		LET l_rec_tempdoc.tm_comm = 0 
		INSERT INTO shuffle VALUES (l_rec_tempdoc.*) 
		INITIALIZE l_rec_tempdoc.* TO NULL 

	END FOREACH 
	# now that we have searched FOR invoicehead.inv_date, we
	# replace this with credithead.cred_date
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
	IF glob_rec_arparms.report_ord_flag = "C" THEN 
		LET l_query_text = 
		"SELECT credithead.cust_code, customer.name_text, ", 
		" credithead.cred_num, credithead.cred_date, ", 
		" credithead.cred_ind, credithead.cred_text, ", 
		" credithead.total_amt, ", 
		" credithead.cost_amt, ", 
		" credithead.tax_amt, ", 
		" credithead.appl_amt, ", 
		" credithead.posted_flag ", 
		"FROM credithead, customer ", 
		"WHERE customer.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
		" credithead.cmpy_code = customer.cmpy_code AND ", 
		" credithead.cust_code = customer.cust_code ", 
		" AND ", p_where_text CLIPPED ," ",
		"ORDER BY credithead.cust_code" 
	ELSE 
		LET l_query_text = 
		"SELECT credithead.cust_code, customer.name_text, ", 
		" credithead.cred_num, credithead.cred_date, ", 
		" credithead.cred_ind, credithead.cred_text, ", 
		" credithead.total_amt, ", 
		" credithead.cost_amt, ", 
		" credithead.tax_amt, ", 
		" credithead.appl_amt, ", 
		" credithead.posted_flag ", 
		"FROM credithead, customer ", 
		"WHERE customer.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
		" credithead.cmpy_code = customer.cmpy_code AND ", 
		" credithead.cust_code = customer.cust_code ", 
		" AND ", p_where_text CLIPPED ," ", 
		"ORDER BY customer.name_text" 
	END IF 
	 
	PREPARE creditor FROM l_query_text 
	DECLARE credcurs CURSOR FOR creditor
	 
	FOREACH credcurs INTO l_rec_credithead.* 
		LET l_rec_tempdoc.tm_cust = l_rec_credithead.cust_code 
		SELECT * 
		INTO l_rec_customer.* 
		FROM customer 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = l_rec_credithead.cust_code 
		LET l_rec_tempdoc.tm_name = l_rec_credithead.name_text 
		LET l_rec_tempdoc.tm_date = l_rec_credithead.cred_date 
		LET l_rec_tempdoc.tm_doc = l_rec_credithead.cred_num 
		LET l_rec_tempdoc.tm_dis = 0 
		LET l_rec_tempdoc.tm_refer = l_rec_credithead.cred_text 
		IF glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AE1_rpt_list")].ref1_ind = "N" THEN 
			LET l_rec_credithead.total_amt = l_rec_credithead.total_amt 
			- l_rec_credithead.tax_amt 
		END IF 
		LET l_rec_tempdoc.tm_amount = conv_currency(l_rec_credithead.total_amt, 
		glob_rec_kandoouser.cmpy_code, 
		l_rec_customer.currency_code, 
		"F", 
		l_rec_credithead.cred_date, 
		"S") 
		LET l_rec_tempdoc.tm_amount = 0 - l_rec_tempdoc.tm_amount + 0 
		LET l_rec_tempdoc.tm_cost = conv_currency(l_rec_credithead.cost_amt, 
		glob_rec_kandoouser.cmpy_code, 
		l_rec_customer.currency_code, 
		"F", 
		l_rec_credithead.cred_date, 
		"S") 
		LET l_rec_tempdoc.tm_cost = 0 - l_rec_tempdoc.tm_cost + 0 
		LET l_rec_tempdoc.tm_post = l_rec_credithead.posted_flag 
		LET l_rec_tempdoc.tm_comm = 0 
		IF l_rec_credithead.cred_ind = "4" THEN 
			LET l_rec_tempdoc.tm_type = "AD" 
		ELSE 
			LET l_rec_tempdoc.tm_type = TRAN_TYPE_CREDIT_CR 
		END IF 

		INSERT INTO shuffle VALUES (l_rec_tempdoc.*) 
		INITIALIZE l_rec_tempdoc.* TO NULL 
	END FOREACH 
	 
	DECLARE selcurs CURSOR FOR 
	SELECT * 
	FROM shuffle 
	ORDER BY tm_cust, 
	tm_date, 
	tm_doc 

	FOREACH selcurs INTO l_rec_tempdoc.* 
		IF glob_rec_arparms.report_ord_flag = "C" THEN 
			LET l_temp_rec.sort_field = l_rec_tempdoc.tm_cust 
		ELSE 
			LET l_temp_rec.sort_field = l_rec_tempdoc.tm_name 
		END IF 
		LET l_temp_rec.tm_date=l_rec_tempdoc.tm_date 
		LET l_temp_rec.tm_name=l_rec_tempdoc.tm_name 

		#---------------------------------------------------------
		OUTPUT TO REPORT AE1_rpt_list(l_rpt_idx,l_rec_tempdoc.*,l_temp_rec.*)  
		IF NOT rpt_int_flag_handler2("Customer:",l_rec_tempdoc.tm_name, l_rec_tempdoc.tm_doc,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------	

	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT AE1_rpt_list
	RETURN rpt_finish("AE1_rpt_list")
	#------------------------------------------------------------
 
END FUNCTION 

############################################################
# REPORT AE1_rpt_list(p_rec_tempdoc,p_rec_temp_rec)  
#
#
############################################################
REPORT AE1_rpt_list(p_rpt_idx,p_rec_tempdoc,p_rec_temp_rec) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_tempdoc RECORD 
		tm_cust CHAR(8), 
		tm_name CHAR(30), 
		tm_date DATE, 
		tm_type CHAR(2), 
		tm_doc INTEGER, 
		tm_refer CHAR(20), 
		tm_amount money(12,2), 
		tm_cost money(12,2), 
		tm_comm money(12,2), 
		tm_dis money(12,2), 
		tm_post CHAR(1) 
	END RECORD 
	DEFINE p_rec_temp_rec RECORD 
		sort_field CHAR(30), 
		tm_name CHAR(30), 
		tm_date DATE 
	END RECORD 
	DEFINE l_v INTEGER 
	DEFINE l_s INTEGER 
	DEFINE l_net_profit money(12,2) 
	DEFINE l_offset1 SMALLINT
	DEFINE l_offset2 SMALLINT
	DEFINE l_line1 CHAR(120)
	DEFINE l_line2 CHAR(120)	 	
	DEFINE l_rpt_date LIKE rmsreps.report_date
		
	OUTPUT 
--	left margin 0 
	ORDER BY p_rec_temp_rec.sort_field, 
	p_rec_temp_rec.tm_date 
	
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  

			PRINT COLUMN 1, "(** all amounts local currency at rate ON day OF transaction **)" 

			IF glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AE1_rpt_list")].ref1_ind = "N" THEN 
				PRINT COLUMN 5, "Invoice Amounts are exclusive of Tax " 
			ELSE 
				PRINT COLUMN 5, "Invoice Amounts are inclusive of Tax " 
			END IF 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

			PRINT COLUMN 1, "Date", 
			COLUMN 10, "Trans", 
			COLUMN 18, " Doc", 
			COLUMN 33, glob_rec_arparms.inv_ref2a_text, 
			COLUMN 52, "Invoice", 
			COLUMN 66, " Cost ", 
			COLUMN 77, "Discount", 
			COLUMN 91, "Commission", 
			COLUMN 111, " Net ", 
			COLUMN 120, "Profit" 
			PRINT COLUMN 10, "Type", 
			COLUMN 18, "Number", 
			COLUMN 34, glob_rec_arparms.inv_ref2b_text, 
			COLUMN 52, "Amount", 
			COLUMN 66, "Amount", 
			COLUMN 78, "Amount", 
			COLUMN 93, "Amount", 
			COLUMN 111, "Profit", 
			COLUMN 122, "%" 
			
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

		ON EVERY ROW 
			IF p_rec_tempdoc.tm_cost IS NULL THEN LET p_rec_tempdoc.tm_cost = 0 END IF 
				IF p_rec_tempdoc.tm_amount IS NULL THEN LET p_rec_tempdoc.tm_amount = 0 END IF 
					IF p_rec_tempdoc.tm_dis IS NULL THEN LET p_rec_tempdoc.tm_dis = 0 END IF 
						IF p_rec_tempdoc.tm_comm IS NULL THEN LET p_rec_tempdoc.tm_comm = 0 END IF 
							LET l_net_profit = p_rec_tempdoc.tm_amount 
							- ( p_rec_tempdoc.tm_cost 
							+ p_rec_tempdoc.tm_dis 
							+ p_rec_tempdoc.tm_comm) 
							IF p_rec_tempdoc.tm_amount != 0.00 THEN 
								PRINT COLUMN 1, p_rec_tempdoc.tm_date USING "dd/mm/yy", 
								COLUMN 10, p_rec_tempdoc.tm_type, 
								COLUMN 15, p_rec_tempdoc.tm_doc USING "########", 
								COLUMN 25, p_rec_tempdoc.tm_refer, 
								COLUMN 46, p_rec_tempdoc.tm_amount USING "--,---,--&.&&", 
								COLUMN 59, p_rec_tempdoc.tm_cost USING "--,---,--&.&&", 
								COLUMN 72, p_rec_tempdoc.tm_dis USING "--,---,--&.&&", 
								COLUMN 88, p_rec_tempdoc.tm_comm USING "--,---,--&.&&", 
								COLUMN 104, l_net_profit USING "--,---,--&.&&", 
								COLUMN 119, (p_rec_tempdoc.tm_amount - p_rec_tempdoc.tm_cost) / 
								p_rec_tempdoc.tm_amount * 100 USING "###.##%" 
							ELSE 
								PRINT COLUMN 1, p_rec_tempdoc.tm_date USING "dd/mm/yy", 
								COLUMN 10, p_rec_tempdoc.tm_type, 
								COLUMN 15, p_rec_tempdoc.tm_doc USING "########", 
								COLUMN 25, p_rec_tempdoc.tm_refer, 
								COLUMN 46, p_rec_tempdoc.tm_amount USING "--,---,--&.&&", 
								COLUMN 59, p_rec_tempdoc.tm_cost USING "--,---,--&.&&", 
								COLUMN 72, p_rec_tempdoc.tm_dis USING "--,---,--&.&&", 
								COLUMN 88, p_rec_tempdoc.tm_comm USING "--,---,--&.&&", 
								COLUMN 104, l_net_profit USING "--,---,--&.&&", 
								COLUMN 120, " 0.0%" 
							END IF 

		BEFORE GROUP OF p_rec_temp_rec.sort_field 
			SKIP 2 LINES 
			PRINT COLUMN 1, "Customer Code: ", p_rec_tempdoc.tm_cust, 2 spaces, 

			COLUMN 28, p_rec_tempdoc.tm_name 

		AFTER GROUP OF p_rec_temp_rec.sort_field 
			IF GROUP sum(p_rec_tempdoc.tm_amount) != 0 THEN 
				PRINT COLUMN 40, "-----------------------------------------------------", 
				"---------------------------------" 
				PRINT COLUMN 43, GROUP sum(p_rec_tempdoc.tm_amount) USING "-----,---,--&.&&", 
				COLUMN 69, GROUP sum(p_rec_tempdoc.tm_dis) USING "-----,---,--&.&&", 
				COLUMN 101, GROUP sum(p_rec_tempdoc.tm_amount) - 
				(group sum(p_rec_tempdoc.tm_cost) 
				+ GROUP sum(p_rec_tempdoc.tm_dis) 
				+ GROUP sum(p_rec_tempdoc.tm_comm)) USING "-----,---,--&.&&" 
				PRINT 
				COLUMN 56, GROUP sum(p_rec_tempdoc.tm_cost) USING "-----,---,--&.&&", 
				COLUMN 85, GROUP sum(p_rec_tempdoc.tm_comm) USING "-----,---,--&.&&", 
				COLUMN 119, (group sum(p_rec_tempdoc.tm_amount) 
				- GROUP sum(p_rec_tempdoc.tm_cost)) / 
				GROUP sum(p_rec_tempdoc.tm_amount) 
				* 100 USING "###.##%" 
			END IF 
		ON LAST ROW 
			IF sum(p_rec_tempdoc.tm_amount) != 0 THEN 
				PRINT COLUMN 40, "-----------------------------------------------------", 
				"---------------------------------" 
				PRINT COLUMN 43, sum(p_rec_tempdoc.tm_amount) USING "-----,---,--&.&&", 
				COLUMN 69, sum(p_rec_tempdoc.tm_dis) USING "-----,---,--&.&&", 
				COLUMN 101, sum(p_rec_tempdoc.tm_amount) - 
				(sum(p_rec_tempdoc.tm_cost) 
				+ sum(p_rec_tempdoc.tm_dis) 
				+ sum(p_rec_tempdoc.tm_comm)) USING "-----,---,--&.&&" 

				PRINT 
				COLUMN 56, sum(p_rec_tempdoc.tm_cost) USING "-----,---,--&.&&", 
				COLUMN 85, sum(p_rec_tempdoc.tm_comm) USING "-----,---,--&.&&", 
				COLUMN 119, (sum(p_rec_tempdoc.tm_amount) 
				- sum(p_rec_tempdoc.tm_cost)) / 
				sum(p_rec_tempdoc.tm_amount) 
				* 100 USING "###.##%" 

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