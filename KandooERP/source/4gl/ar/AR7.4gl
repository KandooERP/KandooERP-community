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
GLOBALS "../ar/AR7_GLOBALS.4gl" 
######################################################################################
# FUNCTION ar7_main() 
#
# AR7 Sales Tax Billed
######################################################################################
FUNCTION ar7_main() 
	DEFER quit 
	DEFER interrupt
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

	CALL setModuleId("AR7")
	CALL init_report_ar() #report default data from db-arparms
	CALL AR_temp_tables_create()

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 
			OPEN WINDOW A189 with FORM "A189" 
			CALL windecoration_a("A189") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 	

			MENU " Sales Tax Report" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","AR7","menu-sales-tax") 
					CALL AR7_rpt_process(AR7_rpt_query())
					CALL AR_temp_tables_delete()
		
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				ON ACTION "Report" #COMMAND "Report" " SELECT criteria AND PRINT REPORT"
					CALL AR7_rpt_process(AR7_rpt_query())
					CALL AR_temp_tables_delete()
		
				ON ACTION "Print Manager" #COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "Exit" 		#COMMAND KEY(interrupt,"E")"Exit" " Exit TO menu"
					EXIT MENU 
			END MENU 
		
			CLOSE WINDOW A189 
	 
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL AR7_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW A189 with FORM "A189" 
			CALL windecoration_a("A189") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(AR7_rpt_query()) #save where clause in env 
			CLOSE WINDOW A189 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL AR7_rpt_process(get_url_sel_text())
	END CASE 
	CALL AR_temp_tables_drop()
END FUNCTION 



######################################################################################
# FUNCTION AR7_rpt_query()
#
#
######################################################################################
FUNCTION AR7_rpt_query() 
	DEFINE l_where_text STRING
	DEFINE l_query_text CHAR(900)
	DEFINE l_cmpy_code LIKE company.cmpy_code
	DEFINE l_rec_taxamts RECORD 
		ref_num LIKE invoicehead.inv_num, 
		tran_date DATE, 
		cust_code LIKE invoicehead.cust_code, 
		tax_num_text LIKE customer.tax_num_text, 
		currency_code LIKE invoicehead.currency_code, 
		total_amt LIKE invoicehead.total_amt, 
		tax_code LIKE invoicehead.tax_code, 
		ext_sale_amt LIKE invoicedetl.ext_sale_amt, 
		ext_tax_amt LIKE invoicedetl.ext_tax_amt, 
		conv_qty LIKE invoicehead.conv_qty 
	END RECORD
	DEFINE l_rec_handling RECORD 
		hand_amt LIKE invoicehead.hand_amt, 
		hand_tax_amt LIKE invoicehead.hand_tax_amt, 
		hand_tax_code LIKE invoicehead.hand_tax_code 
	END RECORD
	DEFINE l_rec_freight RECORD 
		freight_amt LIKE invoicehead.hand_amt, 
		freight_tax_amt LIKE invoicehead.hand_tax_amt, 
		freight_tax_code LIKE invoicehead.hand_tax_code 
	END RECORD
	DEFINE l_prev_ref_num LIKE invoicehead.inv_num 
	DEFINE l_output STRING #report output file name inc. path

	CLEAR FORM 

	MESSAGE kandoomsg2("U",1001,"") 

	#some base inits
	IF glob_period_sel NOT matches "[AS]" OR glob_period_sel IS NULL THEN
		LET glob_period_sel = "A"
	END IF 
	IF glob_date_sel NOT matches "[AS]" OR glob_date_sel IS NULL  THEN
		LET glob_date_sel = "A"
	END IF 
	IF glob_cust_sel NOT matches "[AS]" OR glob_cust_sel IS NULL  THEN
		LET glob_cust_sel = "A"
	END IF 
	IF glob_tax_sel NOT matches "[AS]" OR glob_tax_sel IS NULL  THEN
		LET glob_tax_sel = "A"
	END IF 

	LET glob_bdate = "01/01/1900" 
	LET glob_edate = TODAY --"31/12/2099" 


	INPUT glob_period_sel, #CHAR(1)
	glob_year_num, #LIKE invoicehead.year_num
	glob_bper, #LIKE invoicehead.period_num
	glob_eper, #LIKE invoicehead.period_num 
	
	glob_date_sel, #CHAR(1)
	glob_bdate, #DATE
	glob_edate, #DATE
	 
	glob_cust_sel, #CHAR(1)
	glob_bcust, #LIKE customer.cust_code
	glob_ecust, #LIKE customer.cust_code
	 
	glob_tax_sel, #CHAR(1)
	glob_btax, #LIKE tax.tax_code
	glob_etax  #LIKE tax.tax_code
	WITHOUT DEFAULTS
	FROM
	period_sel, 
	year_num, 
	bper, 
	eper, 
	date_sel, 
	bdate, 
	edate, 
	cust_sel, 
	bcust, 
	ecust, 
	tax_sel, 
	btax, 
	etax 	

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","AR7","inp-rep") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER FIELD period_sel 
			IF glob_period_sel IS NULL 
			OR glob_period_sel <> "S" THEN 
				LET glob_period_sel = "A" 
				LET glob_year_num = NULL 
				LET glob_bper = 1 
				LET glob_eper = 99 
				
				DISPLAY glob_period_sel TO period_sel 
				DISPLAY glob_bper TO bper
				DISPLAY glob_eper TO eper 

				--NEXT FIELD date_sel 
			END IF
			 
		AFTER FIELD bper 
			IF glob_bper IS NULL THEN 
				LET glob_bper = 1 
				DISPLAY glob_bper TO per 

			END IF
			 
		AFTER FIELD eper 
			IF glob_eper IS NULL THEN 
				LET glob_eper = 99 
				DISPLAY glob_eper TO eper 

			END IF 
			IF glob_bper > glob_eper THEN 
				ERROR " Beginning period must be <= end" 
				NEXT FIELD bper 
			END IF 
			IF glob_year_num IS NULL AND NOT (glob_bper = 1 AND glob_eper = 99) THEN 
				ERROR " Year must be entered FOR period selection" 
				NEXT FIELD year_num 
			END IF 

		AFTER FIELD date_sel 
			IF glob_date_sel IS NULL 
			OR glob_date_sel <> "S" THEN 
				LET glob_date_sel = "A" 
				LET glob_bdate = "01/01/1900" 
				LET glob_edate = TODAY --"31/12/2099" 
				
				DISPLAY glob_date_sel TO date_sel
				DISPLAY glob_bdate TO bdate
				DISPLAY glob_edate TO edate

				NEXT FIELD cust_sel 
			END IF 

		AFTER FIELD bdate 
			IF glob_bdate IS NULL THEN 
				LET glob_bdate = 1 
				DISPLAY glob_bdate TO bdate 

			END IF 

		AFTER FIELD edate 
			IF glob_edate IS NULL THEN 
				LET glob_edate = "31/12/2099" 
				DISPLAY glob_edate TO edate 

			END IF 
			IF glob_bdate > glob_edate THEN 
				ERROR " Beginning date must be <= end" 
				NEXT FIELD bdate 
			END IF 

		AFTER FIELD cust_sel 
			IF glob_cust_sel IS NULL 
			OR glob_cust_sel <> "S" THEN 
				LET glob_cust_sel = "A" 
				LET glob_bcust = " " 
				LET glob_ecust = "ZZZZZZZZ" 
				DISPLAY glob_cust_sel TO cust_sel 
				DISPLAY glob_bcust TO bcust
				DISPLAY glob_ecust TO ecust

				NEXT FIELD tax_sel 
			END IF 

		AFTER FIELD bcust 
			IF glob_bcust IS NULL THEN 
				LET glob_bcust = " " 
			END IF 

		AFTER FIELD ecust 
			IF glob_ecust IS NULL THEN 
				LET glob_ecust = "ZZZZZZZZ" 
				DISPLAY glob_ecust TO ecust 

			END IF 
			IF glob_bcust > glob_ecust THEN 
				ERROR " Beginning customer must be <= end" 
				NEXT FIELD bcust 
			END IF 

		AFTER FIELD tax_sel 
			IF glob_tax_sel IS NULL 
			OR glob_tax_sel <> "S" THEN 
				LET glob_tax_sel = "A" 
				LET glob_btax = " " 
				LET glob_etax = "ZZZ" 
				DISPLAY glob_tax_sel TO tax_sel
				DISPLAY glob_btax TO btax
				DISPLAY glob_etax TO etax 
					
				EXIT INPUT 
			END IF 

		AFTER FIELD btax 
			IF glob_btax IS NULL THEN 
				LET glob_btax = " " 
			END IF 

		AFTER FIELD etax 
			IF glob_etax IS NULL THEN 
				LET glob_etax = "zzz" 
				DISPLAY glob_etax TO etax  
			END IF 
			IF glob_btax > glob_etax THEN 
				ERROR " Beginning tax code must be <= end" 
				NEXT FIELD btax 
			END IF 

		AFTER INPUT

			IF glob_period_sel IS NULL 
			OR glob_period_sel <> "S" THEN 
				LET glob_period_sel = "A" 
				LET glob_year_num = NULL 
				LET glob_bper = 1 
				LET glob_eper = 99 
			END IF

			IF glob_cust_sel IS NULL 
			OR glob_cust_sel <> "S" THEN 
				LET glob_cust_sel = "A" 
				LET glob_bcust = " " 
				LET glob_ecust = "ZZZZZZZZ"
			END IF

			IF glob_period_sel IS NULL 
			OR glob_period_sel <> "S" THEN 
				LET glob_period_sel = "A" 
				LET glob_year_num = NULL 
				LET glob_bper = 1 
				LET glob_eper = 99 
			END IF

			IF glob_tax_sel IS NULL 
			OR glob_tax_sel <> "S" THEN 
				LET glob_tax_sel = "A" 
				LET glob_btax = " " 
				LET glob_etax = "ZZZ" 
			END IF
			
	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 
 
	IF glob_year_num IS NULL THEN 
		LET l_where_text = " 1=1 " 
	ELSE 
		LET l_where_text = " glob_year_num = ", glob_year_num, 
		" AND period_num between ", glob_bper, " AND ", glob_eper, " " 
	END IF 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL
	ELSE
	
		LET glob_rec_rpt_selector.ref1_ind = glob_period_sel #CHAR(1)
		LET glob_rec_rpt_selector.ref1_num = glob_year_num #LIKE invoicehead.year_num
		LET glob_rec_rpt_selector.ref2_num = glob_bper #LIKE invoicehead.period_num
		LET glob_rec_rpt_selector.ref3_num = glob_eper #LIKE invoicehead.period_num 
		
		LET glob_rec_rpt_selector.ref2_ind = glob_date_sel #CHAR(1)
		LET glob_rec_rpt_selector.ref1_date = glob_bdate #DATE
		LET glob_rec_rpt_selector.ref2_date = glob_edate #DATE
		 
		LET glob_rec_rpt_selector.ref3_ind = glob_cust_sel #CHAR(1)
		LET glob_rec_rpt_selector.ref1_code = glob_bcust #LIKE customer.cust_code
		LET glob_rec_rpt_selector.ref2_code = glob_ecust #LIKE customer.cust_code
		 
		LET glob_rec_rpt_selector.ref4_ind = glob_tax_sel #CHAR(1)
		LET glob_rec_rpt_selector.ref3_code = glob_btax #LIKE tax.tax_code
		LET glob_rec_rpt_selector.ref4_code = glob_etax  #LIKE tax.tax_code
					
		RETURN l_where_text
	END IF 	
END FUNCTION


######################################################################################
# FUNCTION AR7_rpt_process()
#
#
######################################################################################
FUNCTION AR7_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT 
	DEFINE l_cmpy_code LIKE company.cmpy_code
	DEFINE l_rec_taxamts RECORD 
		ref_num LIKE invoicehead.inv_num, 
		tran_date DATE, 
		cust_code LIKE invoicehead.cust_code, 
		tax_num_text LIKE customer.tax_num_text, 
		currency_code LIKE invoicehead.currency_code, 
		total_amt LIKE invoicehead.total_amt, 
		tax_code LIKE invoicehead.tax_code, 
		ext_sale_amt LIKE invoicedetl.ext_sale_amt, 
		ext_tax_amt LIKE invoicedetl.ext_tax_amt, 
		conv_qty LIKE invoicehead.conv_qty 
	END RECORD
	DEFINE l_rec_handling RECORD 
		hand_amt LIKE invoicehead.hand_amt, 
		hand_tax_amt LIKE invoicehead.hand_tax_amt, 
		hand_tax_code LIKE invoicehead.hand_tax_code 
	END RECORD
	DEFINE l_rec_freight RECORD 
		freight_amt LIKE invoicehead.hand_amt, 
		freight_tax_amt LIKE invoicehead.hand_tax_amt, 
		freight_tax_code LIKE invoicehead.hand_tax_code 
	END RECORD
	DEFINE l_prev_ref_num LIKE invoicehead.inv_num 

	CLEAR FORM 
 


	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"AR7_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT AR7_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AR7_rpt_list")].sel_text
	#------------------------------------------------------------

	LET glob_period_sel = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AR7_rpt_list")].ref1_ind #CHAR(1)
	LET glob_year_num = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AR7_rpt_list")].ref1_num  #LIKE invoicehead.year_num
	LET glob_bper = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AR7_rpt_list")].ref2_num  #LIKE invoicehead.period_num
	LET glob_eper = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AR7_rpt_list")].ref3_num  #LIKE invoicehead.period_num 
	
	LET glob_date_sel = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AR7_rpt_list")].ref2_ind  #CHAR(1)
	LET glob_bdate = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AR7_rpt_list")].ref1_date  #DATE
	LET glob_edate = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AR7_rpt_list")].ref2_date  #DATE
	 
	LET glob_cust_sel = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AR7_rpt_list")].ref3_ind  #CHAR(1)
	LET glob_bcust = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AR7_rpt_list")].ref1_code  #LIKE customer.cust_code
	LET glob_ecust = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AR7_rpt_list")].ref2_code  #LIKE customer.cust_code
	 
	LET glob_tax_sel = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AR7_rpt_list")].ref4_ind #CHAR(1)
	LET glob_btax = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AR7_rpt_list")].ref3_code #LIKE tax.tax_code
	LET glob_etax = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AR7_rpt_list")].ref4_code   #LIKE tax.tax_code


	LET l_query_text = 
	"SELECT I.cmpy_code, ", 
	"I.inv_num, ", 
	"I.inv_date, ", 
	"I.cust_code, ", 
	"I.tax_cert_text, ", 
	"I.currency_code, ", 
	"I.total_amt, ", 
	"\" \", ", 
	"0, ", 
	"0, ", 
	"I.conv_qty, ", 
	"I.hand_amt, ", 
	"I.hand_tax_amt, ", 
	"I.hand_tax_code, ", 
	"I.freight_amt, ", 
	"I.freight_tax_amt, ", 
	"I.freight_tax_code ", 
	"FROM invoicehead I ", 
	"WHERE I.cmpy_code = \"", glob_rec_kandoouser.cmpy_code, "\" ", 
	"AND I.inv_date between \"", glob_bdate, "\" AND \"", glob_edate, "\" ", 
	"AND I.cust_code between \"", glob_bcust, "\" AND \"", glob_ecust, "\" ", 
	"AND ", glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AR7_rpt_list")].sel_text CLIPPED, " ",
	"AND I.posted_flag != \"V\" ", 
	"AND I.posted_flag != \"H\" " 


	PREPARE q_invoice FROM l_query_text 
	DECLARE invcurs CURSOR FOR q_invoice
	 
	FOREACH invcurs INTO l_cmpy_code, 
		l_rec_taxamts.*, 
		l_rec_handling.*, 
		l_rec_freight.* 

		# Insert one row FOR handling AND freight per invoice IF tax code
		# in selected range. Replace NULL code with blanks FOR proper
		# REPORT grouping

		IF l_rec_handling.hand_tax_code IS NULL THEN 
			LET l_rec_handling.hand_tax_code = " " 
		END IF 

		IF (glob_tax_sel = "A" OR 
		(l_rec_handling.hand_tax_code >= glob_btax AND 
		l_rec_handling.hand_tax_code <= glob_etax)) AND 
		l_rec_handling.hand_amt != 0 THEN 
			LET l_rec_taxamts.ext_sale_amt = l_rec_handling.hand_amt 
			LET l_rec_taxamts.ext_tax_amt = l_rec_handling.hand_tax_amt 
			LET l_rec_taxamts.tax_code = l_rec_handling.hand_tax_code 
			INSERT INTO t_taxamts 
			VALUES (l_rec_taxamts.*) 
		END IF 

		IF l_rec_freight.freight_tax_code IS NULL THEN 
			LET l_rec_freight.freight_tax_code = " " 
		END IF 

		IF (glob_tax_sel = "A" OR 
		(l_rec_freight.freight_tax_code >= glob_btax AND 
		l_rec_freight.freight_tax_code <= glob_etax)) AND 
		l_rec_freight.freight_amt != 0 THEN 
			LET l_rec_taxamts.ext_sale_amt = l_rec_freight.freight_amt 
			LET l_rec_taxamts.ext_tax_amt = l_rec_freight.freight_tax_amt 
			LET l_rec_taxamts.tax_code = l_rec_freight.freight_tax_code
			 
			INSERT INTO t_taxamts 
			VALUES (l_rec_taxamts.*) 

		END IF 

		# SELECT all detail tax amounts FOR selected invoices.
		# Insert only details with tax codes in the selected range

		DECLARE c_invoicedetl CURSOR FOR 
		SELECT tax_code, 
		ext_sale_amt, 
		ext_tax_amt 
		INTO l_rec_taxamts.tax_code, 
		l_rec_taxamts.ext_sale_amt, 
		l_rec_taxamts.ext_tax_amt 
		FROM invoicedetl 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = l_rec_taxamts.cust_code 
		AND inv_num = l_rec_taxamts.ref_num 

		FOREACH c_invoicedetl 
			IF l_rec_taxamts.tax_code IS NULL THEN 
				LET l_rec_taxamts.tax_code = " " 
			END IF 
			IF glob_tax_sel = "A" OR 
			(l_rec_taxamts.tax_code >= glob_btax AND 
			l_rec_taxamts.tax_code <= glob_etax) THEN 
				INSERT INTO t_taxamts 
				VALUES (l_rec_taxamts.*) 
			END IF 
		END FOREACH 

	END FOREACH 

	LET l_query_text = 
	"SELECT C.cmpy_code, ", 
	"C.cred_num, ", 
	"C.cred_date, ", 
	"C.cust_code, ", 
	"\" \", ", 
	"C.currency_code, ", 
	"C.total_amt, ", 
	"\" \", ", 
	"0, ", 
	"0, ", 
	"C.conv_qty, ", 
	"C.hand_amt, ", 
	"C.hand_tax_amt, ", 
	"C.hand_tax_code, ", 
	"C.freight_amt, ", 
	"C.freight_tax_amt, ", 
	"C.freight_tax_code ", 
	"FROM credithead C ", 
	"WHERE C.cmpy_code = \"",glob_rec_kandoouser.cmpy_code, "\" ", 
	"AND C.cred_date between \"", glob_bdate, "\" AND \"", glob_edate, "\" ", 
	"AND C.cust_code between \"", glob_bcust, "\" AND \"", glob_ecust, "\" ", 
	"AND ", glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AR7_rpt_list")].sel_text, " ", 
	"AND C.posted_flag != \"V\" ", 
	"AND C.posted_flag != \"H\" " 

	PREPARE q_credit FROM l_query_text 
	DECLARE c_credit CURSOR FOR q_credit 
	FOREACH c_credit INTO l_cmpy_code, 
		l_rec_taxamts.*, 
		l_rec_handling.*, 
		l_rec_freight.* 
		SELECT tax_num_text 
		INTO l_rec_taxamts.tax_num_text 
		FROM customer 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = l_rec_taxamts.cust_code 

		# Insert one row FOR handling AND freight per credit
		# Reverse signs FOR credits

		LET l_rec_taxamts.total_amt = l_rec_taxamts.total_amt * -1 

		IF l_rec_handling.hand_tax_code IS NULL THEN 
			LET l_rec_handling.hand_tax_code = " " 
		END IF 

		IF (glob_tax_sel = "A" OR 
		(l_rec_handling.hand_tax_code >= glob_btax AND 
		l_rec_handling.hand_tax_code <= glob_etax)) AND 
		l_rec_handling.hand_amt != 0 THEN 
			LET l_rec_taxamts.ext_sale_amt = l_rec_handling.hand_amt * -1 
			LET l_rec_taxamts.ext_tax_amt = l_rec_handling.hand_tax_amt * -1 
			LET l_rec_taxamts.tax_code = l_rec_handling.hand_tax_code
			 
			INSERT INTO t_taxamts 
			VALUES (l_rec_taxamts.*)
			 
		END IF 

		IF l_rec_freight.freight_tax_code IS NULL THEN 
			LET l_rec_freight.freight_tax_code = " " 
		END IF 

		IF (glob_tax_sel = "A" OR 
		(l_rec_freight.freight_tax_code >= glob_btax AND 
		l_rec_freight.freight_tax_code <= glob_etax)) AND 
		l_rec_freight.freight_amt != 0 THEN 
			LET l_rec_taxamts.ext_sale_amt = l_rec_freight.freight_amt * -1 
			LET l_rec_taxamts.ext_tax_amt = l_rec_freight.freight_tax_amt * -1 
			LET l_rec_taxamts.tax_code = l_rec_freight.freight_tax_code
			 
			INSERT INTO t_taxamts 
			VALUES (l_rec_taxamts.*)
			 
		END IF 

		# SELECT all detail tax amounts FOR selected credits.
		# Insert only details with tax codes in the selected range

		DECLARE c_creditdetl CURSOR FOR 
		SELECT tax_code, 
		ext_sales_amt, 
		ext_tax_amt 
		INTO l_rec_taxamts.tax_code, 
		l_rec_taxamts.ext_sale_amt, 
		l_rec_taxamts.ext_tax_amt 
		FROM creditdetl 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = l_rec_taxamts.cust_code 
		AND cred_num = l_rec_taxamts.ref_num
		 
		FOREACH c_creditdetl 
			IF l_rec_taxamts.tax_code IS NULL THEN 
				LET l_rec_taxamts.tax_code = " " 
			END IF 
			IF glob_tax_sel = "A" OR 
			(l_rec_taxamts.tax_code >= glob_btax AND 
			l_rec_taxamts.tax_code <= glob_etax) THEN 
				LET l_rec_taxamts.ext_sale_amt = l_rec_taxamts.ext_sale_amt * -1 
				LET l_rec_taxamts.ext_tax_amt = l_rec_taxamts.ext_tax_amt * -1
				 
				INSERT INTO t_taxamts 
				VALUES (l_rec_taxamts.*)
				 
			END IF 
		END FOREACH 
	END FOREACH 

	DECLARE c_taxamts CURSOR FOR 
	SELECT * 
	FROM t_taxamts 
	ORDER BY tran_date, 
	ref_num 

	LET glob_base_total_amt = 0 
	LET l_prev_ref_num = 0 
	LET glob_rows_output = 0 

	FOREACH c_taxamts INTO l_rec_taxamts.* 
		LET glob_rows_output = glob_rows_output + 1 
		#---------------------------------------------------------
		OUTPUT TO REPORT AR7_rpt_list(l_rpt_idx,l_rec_taxamts.*)  
		IF NOT rpt_int_flag_handler2("Tax Ref:",l_rec_taxamts.ref_num, NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		LET l_prev_ref_num = l_rec_taxamts.ref_num 
		#---------------------------------------------------------													
	END FOREACH 



	#------------------------------------------------------------
	FINISH REPORT AR7_rpt_list
	CALL rpt_finish("AR7_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION


######################################################################################
# REPORT ar7_rpt_list(l_rec_taxamts)
#
#
######################################################################################
REPORT ar7_rpt_list(p_rpt_idx,l_rec_taxamts) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE l_rec_taxamts RECORD 
		ref_num LIKE invoicehead.inv_num, 
		tran_date DATE, 
		cust_code LIKE invoicehead.cust_code, 
		tax_num_text LIKE customer.tax_num_text, 
		currency_code LIKE invoicehead.currency_code, 
		total_amt LIKE invoicehead.total_amt, 
		tax_code LIKE invoicehead.tax_code, 
		ext_sale_amt LIKE invoicedetl.ext_sale_amt, 
		ext_tax_amt LIKE invoicedetl.ext_tax_amt, 
		conv_qty LIKE invoicehead.conv_qty 
	END RECORD
	DEFINE l_rec_basetax RECORD 
		tax_code LIKE invoicedetl.tax_code, 
		base_sale_amt DECIMAL(16,2), 
		base_tax_amt DECIMAL(16,2) 
	END RECORD 
	DEFINE l_tax_per LIKE tax.tax_per
	DEFINE l_tot_sale_amt LIKE invoicedetl.ext_sale_amt
	DEFINE l_tot_tax_amt LIKE invoicedetl.ext_tax_amt
	DEFINE l_rnd_tax_amt DECIMAL(16,2)
	DEFINE l_first_base_tot SMALLINT 
	DEFINE l_header_printed SMALLINT 

	OUTPUT 
--	left margin 0 
	ORDER external BY l_rec_taxamts.tran_date, 
	l_rec_taxamts.ref_num, 
	l_rec_taxamts.tax_code 
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #was l_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #was l_arr_line[3]
			PRINT COLUMN 1, "Ref ", 
			COLUMN 11, "Trans", 
			COLUMN 23, "Customer", 
			COLUMN 47, "Currency", 
			COLUMN 65, "Total", 
			COLUMN 76, "Tax", 
			COLUMN 82, "Tax", 
			COLUMN 98, "Taxable", 
			COLUMN 119, "Tax" 
			PRINT COLUMN 1, "Number", 
			COLUMN 11, "Date", 
			COLUMN 23, "Code", 
			COLUMN 33, "Tax Number", 
			COLUMN 49, "Code", 
			COLUMN 65, "Amount", 
			COLUMN 76, "Code", 
			COLUMN 82, "Perc", 
			COLUMN 98, "Amount", 
			COLUMN 119, "Amount" 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #was l_arr_line[3]
 
		BEFORE GROUP OF l_rec_taxamts.ref_num 
			LET l_header_printed = false 
			IF l_rec_taxamts.conv_qty IS NOT NULL THEN 
				IF l_rec_taxamts.conv_qty != 0 THEN 
					LET glob_base_total_amt = 
					glob_base_total_amt + (l_rec_taxamts.total_amt / l_rec_taxamts.conv_qty) 
				END IF 
			END IF 


		AFTER GROUP OF l_rec_taxamts.tax_code 
			SELECT tax_per 
			INTO l_tax_per 
			FROM tax 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND tax_code = l_rec_taxamts.tax_code 
			IF status = NOTFOUND THEN 
				LET l_tax_per = NULL 
			END IF 

			# Tax amounts are totalled TO 4 dec places AND rounded TO 2
			# before printing

			LET l_tot_sale_amt = GROUP sum(l_rec_taxamts.ext_sale_amt) 
			LET l_tot_tax_amt = GROUP sum(l_rec_taxamts.ext_tax_amt) 
			LET l_rnd_tax_amt = l_tot_tax_amt * 1 

			IF l_header_printed THEN 
				PRINT COLUMN 76, l_rec_taxamts.tax_code, 
				COLUMN 81, l_tax_per USING "#&.&&", 
				COLUMN 89, l_tot_sale_amt USING "-,---,---,--&.&&", 
				COLUMN 109, l_rnd_tax_amt USING "-,---,---,--&.&&" 
			ELSE 
				PRINT COLUMN 1, l_rec_taxamts.ref_num USING "########", 
				COLUMN 11, l_rec_taxamts.tran_date USING "dd/mm/yy", 
				COLUMN 23, l_rec_taxamts.cust_code, 
				COLUMN 33, l_rec_taxamts.tax_num_text, 
				COLUMN 50, l_rec_taxamts.currency_code, 
				COLUMN 55, l_rec_taxamts.total_amt USING "-,---,---,--&.&&", 
				COLUMN 76, l_rec_taxamts.tax_code, 
				COLUMN 81, l_tax_per USING "#&.&&", 
				COLUMN 89, l_tot_sale_amt USING "-,---,---,--&.&&", 
				COLUMN 109, l_rnd_tax_amt USING "-,---,---,--&.&&" 
				LET l_header_printed = true 
			END IF 

			# Check that REPORT IS NOT empty before updating base currency totals

			IF glob_rows_output > 0 THEN 

				IF l_rec_taxamts.conv_qty IS NOT NULL THEN 
					IF l_rec_taxamts.conv_qty != 0 THEN 
						LET l_rec_basetax.base_sale_amt = 
						l_tot_sale_amt / l_rec_taxamts.conv_qty 
					END IF 
				END IF 

				IF l_rec_taxamts.conv_qty IS NOT NULL THEN 
					IF l_rec_taxamts.conv_qty != 0 THEN 
						LET l_rec_basetax.base_tax_amt = 
						l_tot_tax_amt / l_rec_taxamts.conv_qty 
					END IF 
				END IF 

				SELECT tax_code 
				INTO l_rec_basetax.tax_code 
				FROM t_basetax 
				WHERE tax_code = l_rec_taxamts.tax_code 
				IF status = NOTFOUND THEN 
					LET l_rec_basetax.tax_code = l_rec_taxamts.tax_code 
					INSERT INTO t_basetax 
					VALUES (l_rec_basetax.*) 
				ELSE 
					UPDATE t_basetax 
					SET base_sale_amt = base_sale_amt + l_rec_basetax.base_sale_amt, 
					base_tax_amt = base_tax_amt + l_rec_basetax.base_tax_amt 
					WHERE tax_code = l_rec_taxamts.tax_code 
				END IF 
			END IF 

		ON LAST ROW 

			# Check that REPORT IS NOT empty before printing base currency totals

			IF glob_rows_output > 0 THEN 
				PRINT COLUMN 1, "--------------------------------------------", 
				"------------------------------------------", 
				"------------------------------------------" 
				LET l_first_base_tot = true 
				DECLARE c_basetax CURSOR FOR 
				SELECT * 
				INTO l_rec_basetax.* 
				FROM t_basetax 
				ORDER BY tax_code 
				FOREACH c_basetax 
					LET l_rnd_tax_amt = l_rec_basetax.base_tax_amt * 1 
					IF l_first_base_tot THEN 
						PRINT COLUMN 27, "Totals in Base Currency", 
						COLUMN 53, glob_base_total_amt 
						USING "---,---,---,--&.&&", 
						COLUMN 76, l_rec_basetax.tax_code, 
						COLUMN 87, l_rec_basetax.base_sale_amt 
						USING "---,---,---,--&.&&", 
						COLUMN 107, l_rnd_tax_amt 
						USING "---,---,---,--&.&&" 
						LET l_first_base_tot = false 
					ELSE 
						PRINT COLUMN 76, l_rec_basetax.tax_code, 
						COLUMN 87, l_rec_basetax.base_sale_amt 
						USING "---,---,---,--&.&&", 
						COLUMN 107, l_rnd_tax_amt 
						USING "---,---,---,--&.&&" 
					END IF 
				END FOREACH 
				PRINT COLUMN 1, "--------------------------------------------", 
				"------------------------------------------", 
				"------------------------------------------" 
			END IF 

			NEED 10 LINES 
			PRINT COLUMN 1, "Selection Criteria:" 
			IF glob_period_sel = "A" THEN 
				PRINT COLUMN 5, "Years : All" 
				PRINT COLUMN 5, "Periods : All" 
			ELSE 
				PRINT COLUMN 5, "Year : ", glob_year_num USING "<<<<" 
				PRINT COLUMN 5, "Periods : ", glob_bper USING "<<<<", 
				" TO ", glob_eper USING "<<<<" 
			END IF 
			IF glob_date_sel = "A" THEN 
				PRINT COLUMN 5, "Transaction Dates : All" 
			ELSE 
				PRINT COLUMN 5, "Transaction Dates : ", glob_bdate, " TO ", glob_edate 
			END IF 
			IF glob_cust_sel = "A" THEN 
				PRINT COLUMN 5, "Customers : All" 
			ELSE 
				PRINT COLUMN 5, "Customers : ", glob_bcust, " TO ", glob_ecust 
			END IF 
			IF glob_tax_sel = "A" THEN 
				PRINT COLUMN 5, "Tax Codes : All" 
			ELSE 
				PRINT COLUMN 5, "Tax Codes : ", glob_btax, " TO ", glob_etax 
			END IF 
			
			SKIP 3 LINES			
			
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	
			

END REPORT