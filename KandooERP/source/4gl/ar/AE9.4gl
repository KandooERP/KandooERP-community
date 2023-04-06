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
# FUNCTION AE9_main()
#
# AE9 Sales Analysis by Invoicehead Department Code
############################################################
FUNCTION AE9_main()  
	DEFER interrupt 
	DEFER quit 
	
	CALL setModuleId("AE9")
	
	CREATE temp TABLE shuffle ( 
	tm_inv_num SMALLINT, 
	tm_line_num SMALLINT, 
	tm_period_num SMALLINT, 
	tm_cust CHAR(8), 
	tm_name CHAR(30), 
	tm_part_code CHAR(16), 
	tm_cat_code CHAR(3), 
	tm_ship_qty DECIMAL(8,2), 
	tm_ext_cost_amt money(12,2), 
	tm_ext_sale_amt money(12,2)) with no LOG 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 	
			OPEN WINDOW A105 with FORM "A105" 
			CALL windecoration_a("A105") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title
		
			MENU " Customer by Product Sales Analysis" 
		
				BEFORE MENU 
					CALL publish_toolbar("kandoo","AE9","menu-customer-product-sales") 
					CALL AE9_rpt_process(AE9_rpt_query())

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				ON ACTION "Report" #COMMAND "Report" " SELECT criteria AND PRINT REPORT"
					CALL AE9_rpt_process(AE9_rpt_query())
					
				ON ACTION "Print Manager"	#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "Exit"#COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus"
					EXIT MENU 
		
			END MENU 
		
			CLOSE WINDOW A105 
	 
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL AE9_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW A105 with FORM "A105" 
			CALL windecoration_a("A105") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(AE9_rpt_query()) #save where clause in env 
			CLOSE WINDOW A105 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL AE9_rpt_process(get_url_sel_text())
	END CASE 				
END FUNCTION 

############################################################
# FUNCTION AE9_rpt_query()  
#
#
############################################################
FUNCTION AE9_rpt_query() 
	DEFINE l_where_text STRING
	DEFINE l_rec_period RECORD LIKE period.* 
	
	CLEAR FORM 

	OPEN WINDOW u137 with FORM "U137" 
	CALL windecoration_u("U137") 

	CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,today) 
	RETURNING l_rec_period.year_num, 
	l_rec_period.period_num 

	INPUT BY NAME l_rec_period.year_num, 	l_rec_period.period_num WITHOUT DEFAULTS 


		BEFORE INPUT 
			CALL publish_toolbar("kandoo","AE9","inp-period") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


	END INPUT 

	CLOSE WINDOW u137 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 
	MESSAGE kandoomsg2("U",1001,"") #1001 " Enter Selection Criteria - ESC TO Continue"
	CONSTRUCT BY NAME l_where_text ON customer.cust_code, 
	customer.name_text, 
	customer.addr1_text, 
	customer.addr2_text, 
	customer.city_text, 
	customer.state_code, 
	customer.post_code, 
	customer.country_code, --@db-patch_2020_10_04--
	customer.currency_code, 
	customer.corp_cust_code, 
	customer.inv_addr_flag, 
	customer.sales_anly_flag, 
	customer.credit_chk_flag, 
	customer.type_code, 
	customer.sale_code, 
	customer.term_code, 
	customer.tax_code, 
	customer.bank_acct_code, 
	customer.setup_date, 
	customer.contact_text, 
	customer.tax_num_text, 
	customer.int_chge_flag, 
	customer.registration_num, 
	customer.vat_code, 
 	customer.tele_text, 
	customer.mobile_phone, 
	customer.fax_text ,
	customer.email	

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","AE9","construct-customer") 

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
		LET glob_rec_rpt_selector.ref1_num = l_rec_period.year_num
		LET glob_rec_rpt_selector.ref2_num = l_rec_period.period_num	
		RETURN l_where_text
	END IF 
END FUNCTION 


#####################################################################
# FUNCTION AE9_rpt_process(p_where_text) 
#
#
#####################################################################
FUNCTION AE9_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT 
	DEFINE l_rec_tempdoc RECORD 
		tm_inv_num LIKE invoicedetl.inv_num, 
		tm_line_num LIKE invoicedetl.line_num, 
		tm_period_num LIKE invoicehead.period_num, 
		tm_cust LIKE customer.cust_code, 
		tm_name LIKE customer.name_text, 
		tm_part_code LIKE invoicedetl.part_code, 
		tm_cat_code LIKE invoicedetl.cat_code, 
		tm_ship_qty DECIMAL(8,2), 
		tm_ext_cost_amt money(12,2), 
		tm_ext_sale_amt money(12,2) 
	END RECORD 
	DEFINE l_rec_invoicedetl RECORD 
		inv_num LIKE invoicehead.inv_num, 
		line_num LIKE invoicehead.line_num, 
		period_num LIKE invoicehead.period_num, 
		cust_code LIKE invoicedetl.cust_code, 
		name_text LIKE customer.name_text, 
		part_code LIKE invoicedetl.part_code, 
		cat_code LIKE invoicedetl.cat_code, 
		ship_qty LIKE invoicedetl.ship_qty, 
		ext_cost_amt LIKE invoicedetl.ext_cost_amt, 
		ext_sale_amt LIKE invoicedetl.ext_sale_amt 
	END RECORD
	DEFINE l_rec_creditdetl RECORD 
		cred_num LIKE credithead.cred_num, 
		line_num LIKE credithead.line_num, 
		period_num LIKE credithead.period_num, 
		cust_code LIKE creditdetl.cust_code, 
		name_text LIKE customer.name_text, 
		part_code LIKE creditdetl.part_code, 
		cat_code LIKE creditdetl.cat_code, 
		ship_qty LIKE creditdetl.ship_qty, 
		ext_cost_amt LIKE creditdetl.ext_cost_amt, 
		ext_sale_amt LIKE creditdetl.ext_sales_amt 
	END RECORD

	DEFINE l_rec_period RECORD LIKE period.* 

	DELETE FROM shuffle WHERE 1=1 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"AE9_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT AE9_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	#Variables via rmsreps
	LET l_rec_period.year_num = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref1_num
	LET l_rec_period.period_num = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref2_num

	LET l_query_text = 
	"SELECT unique invoicedetl.inv_num,", 
	"invoicedetl.line_num,", 
	"invoicehead.period_num, ", 
	"invoicedetl.cust_code,", 
	"customer.name_text,", 
	"invoicedetl.part_code,", 
	"invoicedetl.cat_code,", 
	"invoicedetl.ship_qty,", 
	"invoicedetl.ext_cost_amt,", 
	"invoicedetl.ext_sale_amt ", 
	"FROM invoicehead,", 
	"invoicedetl,", 
	"customer ", 
	"WHERE customer.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND invoicehead.cmpy_code = customer.cmpy_code ", 
	"AND invoicedetl.cmpy_code = invoicehead.cmpy_code ", 
	"AND invoicedetl.inv_num = invoicehead.inv_num ", 
	"AND invoicehead.cust_code = customer.cust_code ", 
	"AND invoicedetl.inv_num in ", 
	"(SELECT inv_num ", 
	"FROM invoicehead ", 
	"WHERE cmpy_code<= \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND period_num<=",l_rec_period.period_num," ", 
	"AND year_num = ",l_rec_period.year_num,") ", 
	"AND ",p_where_text clipped 

	PREPARE s_invoice FROM l_query_text 
	DECLARE c_invoice CURSOR FOR s_invoice 
	  
	FOREACH c_invoice INTO l_rec_invoicedetl.* 
		LET l_rec_tempdoc.tm_period_num = l_rec_invoicedetl.period_num 
		LET l_rec_tempdoc.tm_cust = l_rec_invoicedetl.cust_code 
		LET l_rec_tempdoc.tm_name = l_rec_invoicedetl.name_text 
		LET l_rec_tempdoc.tm_part_code = l_rec_invoicedetl.part_code 
		LET l_rec_tempdoc.tm_cat_code = l_rec_invoicedetl.cat_code 
		IF l_rec_tempdoc.tm_cat_code IS NULL THEN 
			LET l_rec_tempdoc.tm_cat_code = TRAN_TYPE_JOB_JOB 
		END IF 
		LET l_rec_tempdoc.tm_ship_qty = l_rec_invoicedetl.ship_qty
		 
		IF int_flag OR quit_flag THEN 
			#8503 Continue Report (Y/N)
			IF kandoomsg("U",8503,"") = "N" THEN 
				MESSAGE kandoomsg2("U",9501,"") 
				#9501 Report Terminated
				LET int_flag = true 
				LET quit_flag = true 
				EXIT FOREACH 
			END IF 
		END IF 
		
		LET l_rec_tempdoc.tm_ext_cost_amt = l_rec_invoicedetl.ext_cost_amt 
		LET l_rec_tempdoc.tm_ext_sale_amt = l_rec_invoicedetl.ext_sale_amt
		 
		INSERT INTO shuffle VALUES (l_rec_tempdoc.*)
		 
		INITIALIZE l_rec_tempdoc.* TO NULL 
	END FOREACH
	 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF
	 
	LET l_query_text = 
	"SELECT unique creditdetl.cred_num,", 
	"creditdetl.line_num,", 
	"credithead.period_num,", 
	"creditdetl.cust_code,", 
	"customer.name_text,", 
	"creditdetl.part_code,", 
	"creditdetl.cat_code,", 
	"creditdetl.ship_qty,", 
	"creditdetl.ext_cost_amt,", 
	"creditdetl.ext_sales_amt ", 
	"FROM credithead,", 
	"creditdetl,", 
	"customer ", 
	"WHERE customer.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND credithead.cmpy_code = customer.cmpy_code ", 
	"AND creditdetl.cmpy_code = credithead.cmpy_code ", 
	"AND credithead.cust_code = customer.cust_code ", 
	"AND credithead.cred_num = creditdetl.cred_num ", 
	"AND creditdetl.cred_num in ", 
	"(SELECT cred_num ", 
	"FROM credithead ", 
	"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND period_num <= ",l_rec_period.period_num," ", 
	"AND year_num = ",l_rec_period.year_num,") ", 
	"AND ",p_where_text clipped 

	PREPARE s_credit FROM l_query_text 
	DECLARE c_credit CURSOR FOR s_credit 

	FOREACH c_credit INTO l_rec_creditdetl.* 
		LET l_rec_tempdoc.tm_period_num = l_rec_creditdetl.period_num 
		LET l_rec_tempdoc.tm_cust = l_rec_creditdetl.cust_code 
		LET l_rec_tempdoc.tm_name = l_rec_creditdetl.name_text 
		LET l_rec_tempdoc.tm_part_code = l_rec_creditdetl.part_code 
		LET l_rec_tempdoc.tm_cat_code = l_rec_creditdetl.cat_code 
		IF l_rec_tempdoc.tm_cat_code IS NULL THEN 
			LET l_rec_tempdoc.tm_cat_code = TRAN_TYPE_JOB_JOB 
		END IF 
		LET l_rec_tempdoc.tm_ship_qty = - l_rec_creditdetl.ship_qty 

		IF int_flag OR quit_flag THEN 
			#8503 Continue Report (Y/N)
			IF kandoomsg("U",8503,"") = "N" THEN 
				MESSAGE kandoomsg2("U",9501,"") 
				#9501 Report Terminated
				LET int_flag = true 
				LET quit_flag = true 
				EXIT FOREACH 
			END IF 
		END IF
		 
		LET l_rec_tempdoc.tm_ext_cost_amt = - l_rec_creditdetl.ext_cost_amt 
		LET l_rec_tempdoc.tm_ext_sale_amt = - l_rec_creditdetl.ext_sale_amt
		 
		INSERT INTO shuffle VALUES (l_rec_tempdoc.*)
		 
		INITIALIZE l_rec_tempdoc.* TO NULL 
	END FOREACH
	 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF
		
	 
	DECLARE selcurs CURSOR FOR 
	SELECT * 
	FROM shuffle 
	ORDER BY tm_cat_code, 
	tm_part_code
	 
	FOREACH selcurs INTO l_rec_tempdoc.* 
		#---------------------------------------------------------
		OUTPUT TO REPORT AE9_rpt_list(l_rpt_idx,l_rec_tempdoc.*, l_rec_period.period_num) 
		IF NOT rpt_int_flag_handler2("Customer Period:",l_rec_tempdoc.tm_cust, l_rec_tempdoc.tm_period_num,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------	
	END FOREACH

	#------------------------------------------------------------
	FINISH REPORT AE9_rpt_list
	RETURN rpt_finish("AE9_rpt_list")
	#------------------------------------------------------------
 
END FUNCTION 

############################################################
# REPORT AE9_rpt_list(p_rec_tempdoc, p_curr_period) 
#
#
############################################################
REPORT AE9_rpt_list(p_rpt_idx,p_rec_tempdoc, p_curr_period) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_tempdoc RECORD 
		tm_inv_num SMALLINT, 
		tm_line_num SMALLINT, 
		tm_period_num SMALLINT, 
		tm_cust CHAR(8), 
		tm_name CHAR(30), 
		tm_part_code CHAR(16), 
		tm_cat_code CHAR(3), 
		tm_ship_qty DECIMAL(8,2), 
		tm_ext_cost_amt money(12,2), 
		tm_ext_sale_amt money(12,2) 
	END RECORD 
	DEFINE p_curr_period SMALLINT 
	DEFINE l_net_profit money(12,2) 

	ORDER external BY 
	p_rec_tempdoc.tm_cat_code, 
	p_rec_tempdoc.tm_part_code 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  

			PRINT 
			COLUMN 1, "Period", 
			COLUMN 13, "PTD", 
			COLUMN 24, "PTD", 
			COLUMN 38, "PTD", 
			COLUMN 52, "PTD", 
			COLUMN 61, "PTD", 
			COLUMN 78, "YTD", 
			COLUMN 90, "YTD", 
			COLUMN 104, "YTD", 
			COLUMN 116, "YTD", 
			COLUMN 127, "YTD" 
			PRINT 
			COLUMN 1, "Number", 
			COLUMN 10, "Quantity", 
			COLUMN 21, "Sales", 
			COLUMN 38, "Cost", 
			COLUMN 50, "Margin", 
			COLUMN 59, "Margin", 
			COLUMN 75, "Quantity", 
			COLUMN 89, "Sales", 
			COLUMN 104, "Cost", 
			COLUMN 114, "Margin", 
			COLUMN 125, "Margin" 
			PRINT 
			COLUMN 1, p_curr_period clipped, 
			COLUMN 52, "($)", 
			COLUMN 61, "(%)", 
			COLUMN 116, "($)", 
			COLUMN 127, "(%)" 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			#1234567890123456789012345678901234567890123456789012345678901234567890
			IF pageno > 1 
			THEN PRINT COLUMN 1, "Continuation of Sales Analysis FOR Product Category ", p_rec_tempdoc.tm_cat_code 
			ELSE PRINT COLUMN 1," " 
			END IF 
			
		BEFORE GROUP OF p_rec_tempdoc.tm_cat_code 
			SKIP 2 LINES 
			PRINT COLUMN 1, "Product Category ID: ", p_rec_tempdoc.tm_cat_code 
			
		BEFORE GROUP OF p_rec_tempdoc.tm_part_code 
			SKIP 1 line 
			PRINT COLUMN 3, "Product ID: ", p_rec_tempdoc.tm_part_code 
			SKIP 1 line 
			
		AFTER GROUP OF p_rec_tempdoc.tm_cat_code 
			IF GROUP sum(p_rec_tempdoc.tm_ship_qty) != 0 
			THEN 
				IF (group sum(p_rec_tempdoc.tm_ext_sale_amt) 
				WHERE p_rec_tempdoc.tm_period_num = p_curr_period) !=0 
				AND GROUP sum(p_rec_tempdoc.tm_ext_sale_amt) != 0 
				THEN 
					SKIP 1 line 
					NEED 4 LINES 
					PRINT COLUMN 11, "----------------------------------------", 
					"--------------------------------------------------", 
					"-------------------------------" 
					PRINT 
					COLUMN 1, "Totals FOR ", p_rec_tempdoc.tm_cat_code 
					PRINT 
					COLUMN 17, GROUP sum(p_rec_tempdoc.tm_ext_sale_amt) 
					WHERE p_rec_tempdoc.tm_period_num = p_curr_period USING "--,---,--$.&&", 
					COLUMN 30, GROUP sum(p_rec_tempdoc.tm_ext_cost_amt) 
					WHERE p_rec_tempdoc.tm_period_num = p_curr_period USING "--,---,--$.&&", 
					COLUMN 41, (group sum(p_rec_tempdoc.tm_ext_sale_amt) WHERE p_rec_tempdoc.tm_period_num = p_curr_period ) 
					- (group sum(p_rec_tempdoc.tm_ext_cost_amt) WHERE p_rec_tempdoc.tm_period_num = p_curr_period) 
					USING "--,---,--$.&&", 
					COLUMN 59, ((group sum(p_rec_tempdoc.tm_ext_sale_amt) WHERE p_rec_tempdoc.tm_period_num = p_curr_period ) 
					- ( GROUP sum(p_rec_tempdoc.tm_ext_cost_amt) WHERE p_rec_tempdoc.tm_period_num = p_curr_period)) 
					/ (group sum(p_rec_tempdoc.tm_ext_sale_amt) WHERE p_rec_tempdoc.tm_period_num = p_curr_period) * 100 
					USING "----.##%", 
					COLUMN 82, GROUP sum(p_rec_tempdoc.tm_ext_sale_amt) USING "--,---,--$.&&", 
					COLUMN 95, GROUP sum(p_rec_tempdoc.tm_ext_cost_amt) USING "--,---,--$.&&", 
					COLUMN 106, (group sum(p_rec_tempdoc.tm_ext_sale_amt) 
					- GROUP sum(p_rec_tempdoc.tm_ext_cost_amt)) USING "--,---,--$.&&", 
					COLUMN 124, (group sum(p_rec_tempdoc.tm_ext_sale_amt) 
					- GROUP sum(p_rec_tempdoc.tm_ext_cost_amt) ) 
					/ GROUP sum(p_rec_tempdoc.tm_ext_sale_amt) * 100 
					USING "----.##%" 
					PRINT COLUMN 11, "========================================", 
					"==================================================", 
					"===============================" 
				ELSE 
					IF (group sum(p_rec_tempdoc.tm_ext_sale_amt) 
					WHERE p_rec_tempdoc.tm_period_num = p_curr_period) =0 
					AND GROUP sum(p_rec_tempdoc.tm_ext_sale_amt) != 0 
					THEN 
						PRINT COLUMN 11, "----------------------------------------", 
						"--------------------------------------------------", 
						"-------------------------------" 
						PRINT 
						COLUMN 1, "Totals FOR ", p_rec_tempdoc.tm_cat_code 
						PRINT 
						COLUMN 17, GROUP sum(p_rec_tempdoc.tm_ext_sale_amt) 
						WHERE p_rec_tempdoc.tm_period_num = p_curr_period USING "--,---,--$.&&", 
						COLUMN 30, GROUP sum(p_rec_tempdoc.tm_ext_cost_amt) 
						WHERE p_rec_tempdoc.tm_period_num = p_curr_period USING "--,---,--$.&&", 
						COLUMN 41, (group sum(p_rec_tempdoc.tm_ext_sale_amt) WHERE p_rec_tempdoc.tm_period_num = p_curr_period ) 
						- (group sum(p_rec_tempdoc.tm_ext_cost_amt) WHERE p_rec_tempdoc.tm_period_num = p_curr_period) 
						USING "--,---,--$.&&", 
						COLUMN 59, "****%", 
						COLUMN 82, GROUP sum(p_rec_tempdoc.tm_ext_sale_amt) USING "--,---,--$.&&", 
						COLUMN 95, GROUP sum(p_rec_tempdoc.tm_ext_cost_amt) USING "--,---,--$.&&", 
						COLUMN 106, (group sum(p_rec_tempdoc.tm_ext_sale_amt) 
						- GROUP sum(p_rec_tempdoc.tm_ext_cost_amt)) USING "--,---,--$.&&", 
						COLUMN 124, (group sum(p_rec_tempdoc.tm_ext_sale_amt) 
						- GROUP sum(p_rec_tempdoc.tm_ext_cost_amt) ) 
						/ GROUP sum(p_rec_tempdoc.tm_ext_sale_amt) * 100 
						USING "----.##%" 
						PRINT COLUMN 11, "========================================", 
						"==================================================", 
						"===============================" 
					ELSE 
						IF (group sum(p_rec_tempdoc.tm_ext_sale_amt) 
						WHERE p_rec_tempdoc.tm_period_num = p_curr_period) =0 
						AND GROUP sum(p_rec_tempdoc.tm_ext_sale_amt) = 0 
						THEN 
							PRINT COLUMN 11, "----------------------------------------", 
							"--------------------------------------------------", 
							"-------------------------------" 
							PRINT 
							COLUMN 1, "Totals FOR ", p_rec_tempdoc.tm_cat_code 
							PRINT 
							COLUMN 17, GROUP sum(p_rec_tempdoc.tm_ext_sale_amt) 
							WHERE p_rec_tempdoc.tm_period_num = p_curr_period USING "--,---,--$.&&", 
							COLUMN 30, GROUP sum(p_rec_tempdoc.tm_ext_cost_amt) 
							WHERE p_rec_tempdoc.tm_period_num = p_curr_period USING "--,---,--$.&&", 
							COLUMN 41, (group sum(p_rec_tempdoc.tm_ext_sale_amt) WHERE p_rec_tempdoc.tm_period_num = p_curr_period ) 
							- (group sum(p_rec_tempdoc.tm_ext_cost_amt) WHERE p_rec_tempdoc.tm_period_num = p_curr_period) 
							USING "--,---,--$.&&", 
							COLUMN 59, "*****", 
							COLUMN 82, GROUP sum(p_rec_tempdoc.tm_ext_sale_amt) USING "--,---,--$.&&", 
							COLUMN 95, GROUP sum(p_rec_tempdoc.tm_ext_cost_amt) USING "--,---,--$.&&", 
							COLUMN 106, (group sum(p_rec_tempdoc.tm_ext_sale_amt) 
							- GROUP sum(p_rec_tempdoc.tm_ext_cost_amt)) USING "--,---,--$.&&", 
							COLUMN 124, "****%" 
							PRINT COLUMN 11, "========================================", 
							"==================================================", 
							"===============================" 
						END IF 
					END IF 
				END IF 
			END IF 
			
		AFTER GROUP OF p_rec_tempdoc.tm_part_code 
			IF GROUP sum(p_rec_tempdoc.tm_ship_qty) != 0 
			THEN 
				NEED 4 LINES 
				PRINT COLUMN 11, "----------------------------------------", 
				"--------------------------------------------------", 
				"-------------------------------" 
				IF (group sum(p_rec_tempdoc.tm_ext_sale_amt) 
				WHERE p_rec_tempdoc.tm_period_num = p_curr_period) !=0 
				AND GROUP sum(p_rec_tempdoc.tm_ext_sale_amt) != 0 
				THEN 
					PRINT 
					COLUMN 3, "Total Sales of Product ", p_rec_tempdoc.tm_part_code 
					PRINT 
					COLUMN 17, GROUP sum(p_rec_tempdoc.tm_ext_sale_amt) 
					WHERE p_rec_tempdoc.tm_period_num = p_curr_period USING "--,---,--$.&&", 
					COLUMN 30, GROUP sum(p_rec_tempdoc.tm_ext_cost_amt) 
					WHERE p_rec_tempdoc.tm_period_num = p_curr_period USING "--,---,--$.&&", 
					COLUMN 41, (group sum(p_rec_tempdoc.tm_ext_sale_amt) WHERE p_rec_tempdoc.tm_period_num = p_curr_period ) 
					- (group sum(p_rec_tempdoc.tm_ext_cost_amt) WHERE p_rec_tempdoc.tm_period_num = p_curr_period) 
					USING "--,---,--$.&&", 
					COLUMN 59, ((group sum(p_rec_tempdoc.tm_ext_sale_amt) WHERE p_rec_tempdoc.tm_period_num = p_curr_period ) 
					- ( GROUP sum(p_rec_tempdoc.tm_ext_cost_amt) WHERE p_rec_tempdoc.tm_period_num = p_curr_period)) 
					/ (group sum(p_rec_tempdoc.tm_ext_sale_amt) WHERE p_rec_tempdoc.tm_period_num = p_curr_period) * 100 
					USING "----.##%", 
					COLUMN 82, GROUP sum(p_rec_tempdoc.tm_ext_sale_amt) USING "--,---,--$.&&", 
					COLUMN 95, GROUP sum(p_rec_tempdoc.tm_ext_cost_amt) USING "--,---,--$.&&", 
					COLUMN 106, (group sum(p_rec_tempdoc.tm_ext_sale_amt) 
					- GROUP sum(p_rec_tempdoc.tm_ext_cost_amt)) USING "--,---,--$.&&", 
					COLUMN 124, (group sum(p_rec_tempdoc.tm_ext_sale_amt) 
					- GROUP sum(p_rec_tempdoc.tm_ext_cost_amt) ) 
					/ GROUP sum(p_rec_tempdoc.tm_ext_sale_amt) * 100 
					USING "----.##%" 
				ELSE 
					IF (group sum(p_rec_tempdoc.tm_ext_sale_amt) 
					WHERE p_rec_tempdoc.tm_period_num = p_curr_period) =0 
					AND GROUP sum(p_rec_tempdoc.tm_ext_sale_amt) != 0 
					THEN 
						PRINT 
						COLUMN 3, "Total Sales of Product ", p_rec_tempdoc.tm_part_code 
						PRINT 
						COLUMN 17, GROUP sum(p_rec_tempdoc.tm_ext_sale_amt) 
						WHERE p_rec_tempdoc.tm_period_num = p_curr_period USING "--,---,--$.&&", 
						COLUMN 30, GROUP sum(p_rec_tempdoc.tm_ext_cost_amt) 
						WHERE p_rec_tempdoc.tm_period_num = p_curr_period USING "--,---,--$.&&", 
						COLUMN 41, (group sum(p_rec_tempdoc.tm_ext_sale_amt) WHERE p_rec_tempdoc.tm_period_num = p_curr_period ) 
						- (group sum(p_rec_tempdoc.tm_ext_cost_amt) WHERE p_rec_tempdoc.tm_period_num = p_curr_period) 
						USING "--,---,--$.&&", 
						COLUMN 59, "****%", 
						COLUMN 82, GROUP sum(p_rec_tempdoc.tm_ext_sale_amt) USING "--,---,--$.&&", 
						COLUMN 95, GROUP sum(p_rec_tempdoc.tm_ext_cost_amt) USING "--,---,--$.&&", 
						COLUMN 106, (group sum(p_rec_tempdoc.tm_ext_sale_amt) 
						- GROUP sum(p_rec_tempdoc.tm_ext_cost_amt)) USING "--,---,--$.&&", 
						COLUMN 124, (group sum(p_rec_tempdoc.tm_ext_sale_amt) 
						- GROUP sum(p_rec_tempdoc.tm_ext_cost_amt) ) 
						/ GROUP sum(p_rec_tempdoc.tm_ext_sale_amt) * 100 
						USING "----.##%" 
					ELSE 
						IF (group sum(p_rec_tempdoc.tm_ext_sale_amt) 
						WHERE p_rec_tempdoc.tm_period_num = p_curr_period) =0 
						AND GROUP sum(p_rec_tempdoc.tm_ext_sale_amt) = 0 
						THEN 
							PRINT 
							COLUMN 3, "Total Sales of Product ", p_rec_tempdoc.tm_part_code 
							PRINT 
							COLUMN 17, GROUP sum(p_rec_tempdoc.tm_ext_sale_amt) 
							WHERE p_rec_tempdoc.tm_period_num = p_curr_period USING "--,---,--$.&&", 
							COLUMN 30, GROUP sum(p_rec_tempdoc.tm_ext_cost_amt) 
							WHERE p_rec_tempdoc.tm_period_num = p_curr_period USING "--,---,--$.&&", 
							COLUMN 41, (group sum(p_rec_tempdoc.tm_ext_sale_amt) WHERE p_rec_tempdoc.tm_period_num = p_curr_period ) 
							- (group sum(p_rec_tempdoc.tm_ext_cost_amt) WHERE p_rec_tempdoc.tm_period_num = p_curr_period) 
							USING "--,---,--$.&&", 
							COLUMN 59, "****%", 
							#COLUMN 72, group sum(p_rec_tempdoc.tm_ship_qty) using "---,---.&&",
							COLUMN 82, GROUP sum(p_rec_tempdoc.tm_ext_sale_amt) USING "--,---,--$.&&", 
							COLUMN 95, GROUP sum(p_rec_tempdoc.tm_ext_cost_amt) USING "--,---,--$.&&", 
							COLUMN 106, (group sum(p_rec_tempdoc.tm_ext_sale_amt) 
							- GROUP sum(p_rec_tempdoc.tm_ext_cost_amt)) USING "--,---,--$.&&", 
							COLUMN 124, "****%" 
						END IF 
					END IF 
				END IF 
			END IF 
			
		ON LAST ROW 
			IF sum(p_rec_tempdoc.tm_ship_qty) != 0 
			THEN 
				SKIP 2 LINES 
				NEED 6 LINES 
				PRINT COLUMN 11, "========================================", 
				"==================================================", 
				"===============================" 
				SKIP 1 line 
				IF sum(p_rec_tempdoc.tm_ship_qty) != 0 
				THEN 
					IF (sum(p_rec_tempdoc.tm_ext_sale_amt) 
					WHERE p_rec_tempdoc.tm_period_num = p_curr_period) !=0 
					AND sum(p_rec_tempdoc.tm_ext_sale_amt) != 0 
					THEN 
						PRINT 
						COLUMN 1, "Totals ", 
						COLUMN 17, sum(p_rec_tempdoc.tm_ext_sale_amt) 
						WHERE p_rec_tempdoc.tm_period_num = p_curr_period USING "---,---,--$.&&", 
						COLUMN 41, (sum(p_rec_tempdoc.tm_ext_sale_amt) WHERE p_rec_tempdoc.tm_period_num = p_curr_period ) 
						- (sum(p_rec_tempdoc.tm_ext_cost_amt) WHERE p_rec_tempdoc.tm_period_num = p_curr_period) 
						USING "---,---,--$.&&", 
						COLUMN 59, ((sum(p_rec_tempdoc.tm_ext_sale_amt) WHERE p_rec_tempdoc.tm_period_num = p_curr_period ) 
						- ( sum(p_rec_tempdoc.tm_ext_cost_amt) WHERE p_rec_tempdoc.tm_period_num = p_curr_period)) 
						/ (sum(p_rec_tempdoc.tm_ext_sale_amt) WHERE p_rec_tempdoc.tm_period_num = p_curr_period) * 100 
						USING "----.##%", 
						COLUMN 82, sum(p_rec_tempdoc.tm_ext_sale_amt) USING "---,---,--$.&&", 
						COLUMN 106, (sum(p_rec_tempdoc.tm_ext_sale_amt) 
						- sum(p_rec_tempdoc.tm_ext_cost_amt)) USING "---,---,--$.&&", 
						COLUMN 124, (sum(p_rec_tempdoc.tm_ext_sale_amt) 
						- sum(p_rec_tempdoc.tm_ext_cost_amt) ) 
						/ sum(p_rec_tempdoc.tm_ext_sale_amt) * 100 
						USING "----.##%" 
						PRINT 
						COLUMN 1, "FOR Report", 
						COLUMN 30, sum(p_rec_tempdoc.tm_ext_cost_amt) 
						WHERE p_rec_tempdoc.tm_period_num = p_curr_period USING "---,---,--$.&&", 
						COLUMN 95, sum(p_rec_tempdoc.tm_ext_cost_amt) USING "---,---,--$.&&" 
					ELSE 
						IF (sum(p_rec_tempdoc.tm_ext_sale_amt) 
						WHERE p_rec_tempdoc.tm_period_num = p_curr_period) =0 
						AND sum(p_rec_tempdoc.tm_ext_sale_amt) != 0 
						THEN 
							PRINT 
							COLUMN 1, "Totals ", 
							COLUMN 17, sum(p_rec_tempdoc.tm_ext_sale_amt) 
							WHERE p_rec_tempdoc.tm_period_num = p_curr_period USING "---,---,--$.&&", 
							COLUMN 41, (sum(p_rec_tempdoc.tm_ext_sale_amt) WHERE p_rec_tempdoc.tm_period_num = p_curr_period ) 
							- (sum(p_rec_tempdoc.tm_ext_cost_amt) WHERE p_rec_tempdoc.tm_period_num = p_curr_period) 
							USING "---,---,--$.&&", 
							COLUMN 59, "****%", 
							COLUMN 82, sum(p_rec_tempdoc.tm_ext_sale_amt) USING "---,---,--$.&&", 
							COLUMN 106, (sum(p_rec_tempdoc.tm_ext_sale_amt) 
							- sum(p_rec_tempdoc.tm_ext_cost_amt)) USING "---,---,--$.&&", 
							COLUMN 124, (sum(p_rec_tempdoc.tm_ext_sale_amt) 
							- sum(p_rec_tempdoc.tm_ext_cost_amt) ) 
							/ sum(p_rec_tempdoc.tm_ext_sale_amt) * 100 
							USING "----.##%" 
							PRINT 
							COLUMN 1, "FOR Report", 
							COLUMN 30, sum(p_rec_tempdoc.tm_ext_cost_amt) 
							WHERE p_rec_tempdoc.tm_period_num = p_curr_period USING "---,---,--$.&&", 
							COLUMN 95, sum(p_rec_tempdoc.tm_ext_cost_amt) USING "---,---,--$.&&" 
						ELSE 
							IF (sum(p_rec_tempdoc.tm_ext_sale_amt) 
							WHERE p_rec_tempdoc.tm_period_num = p_curr_period) =0 
							AND sum(p_rec_tempdoc.tm_ext_sale_amt) = 0 
							THEN 
								PRINT 
								COLUMN 1, "Totals ", 
								COLUMN 17, sum(p_rec_tempdoc.tm_ext_sale_amt) 
								WHERE p_rec_tempdoc.tm_period_num = p_curr_period USING "---,---,--$.&&", 
								COLUMN 41, (sum(p_rec_tempdoc.tm_ext_sale_amt) WHERE p_rec_tempdoc.tm_period_num = p_curr_period ) 
								- (sum(p_rec_tempdoc.tm_ext_cost_amt) WHERE p_rec_tempdoc.tm_period_num = p_curr_period) 
								USING "---,---,--$.&&", 
								COLUMN 59, "****%", 
								COLUMN 82, sum(p_rec_tempdoc.tm_ext_sale_amt) USING "---,---,--$.&&", 
								COLUMN 106, (sum(p_rec_tempdoc.tm_ext_sale_amt) 
								- sum(p_rec_tempdoc.tm_ext_cost_amt)) USING "---,---,--$.&&", 
								COLUMN 124, "****%" 
								PRINT 
								COLUMN 1, "FOR Report", 
								COLUMN 30, sum(p_rec_tempdoc.tm_ext_cost_amt) 
								WHERE p_rec_tempdoc.tm_period_num = p_curr_period USING "---,---,--$.&&", 
								COLUMN 95, sum(p_rec_tempdoc.tm_ext_cost_amt) USING "---,---,--$.&&" 
							END IF 
						END IF 
					END IF 
				END IF 
				SKIP 1 line 
				PRINT COLUMN 11, "========================================", 
				"==================================================", 
				"===============================" 
				SKIP 1 line 
			END IF 
			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 

END REPORT 