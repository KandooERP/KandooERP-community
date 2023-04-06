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
# 1. FUNCTION ARC_main() -> FUNCTION ARC_rpt_query() -> FUNCTION db_period_get_datasource(p_filter) -> DISPLAY ARRAY (Year/Period)-> 
# FUNCTION ARC_rpt_process(p_where_text) -> CALL invoice() # REPORT all invoice postings -> FUNCTION get_cust_accts() [FOR EACH]->FUNCTION tax_postings(p_post_type) ->FUNCTION get_cust_accts() ->FUNCTION tax_postings(p_post_type)
#                                        -> CALL credit() # REPORT all credit postings -> FUNCTION add_tax(p_tax_code, p_tax_amt)
#                                        -> CALL receipt() # REPORT all receipt postings
#                                        -> CALL exch_var() # REPORT all exchange postings
	
		
# FUNCTION invoice() -> FOR EACH -> CALL tax_postings(TRAN_TYPE_CREDIT_CR)
#											-> CALL add_tax(p_tax_code, p_tax_amt) 
#
# FUNCTION credit() -> CALL add_tax(p_tax_code, p_tax_amt)
#

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl" 
GLOBALS "../ar/AR_GROUP_GLOBALS.4gl"
GLOBALS "../ar/ARC_GLOBALS.4gl" 
############################################################
# MODULE Scope Variables
############################################################
 
	DEFINE modu_rec_journal RECORD LIKE journal.* 
#	DEFINE modu_rec_period RECORD LIKE period.* 
	DEFINE modu_rec_bal_rec RECORD 
		tran_type_ind LIKE batchdetl.tran_type_ind, 
		acct_code LIKE batchdetl.acct_code, 
		desc_text LIKE batchdetl.desc_text 
	END RECORD 
	
	DEFINE modu_arr_rec_period DYNAMIC ARRAY OF RECORD --array[400] OF RECORD 
		year_num SMALLINT, 
		period_num SMALLINT 
	END RECORD 
	
	DEFINE modu_prev_cust_type LIKE customer.type_code 
	
	DEFINE modu_rec_docdata RECORD 
		ref_num LIKE batchdetl.ref_num, 
		ref_text LIKE batchdetl.ref_text, 
		tran_date DATE, 
		currency_code LIKE batchdetl.currency_code, 
		conv_qty LIKE batchdetl.conv_qty 
	END RECORD 
	
	DEFINE modu_rec_detldata RECORD 
		post_acct_code LIKE batchdetl.acct_code, 
		desc_text LIKE batchdetl.desc_text, 
		debit_amt LIKE batchdetl.debit_amt, 
		credit_amt LIKE batchdetl.credit_amt 
	END RECORD 
	
	DEFINE modu_rec_detltax RECORD 
		tax_code LIKE invoicedetl.tax_code, 
		ext_tax_amt LIKE invoicedetl.ext_tax_amt 
	END RECORD 
	
	DEFINE modu_taxtemp RECORD 
		tax_acct_code LIKE batchdetl.acct_code, 
		tax_amt LIKE invoicedetl.ext_tax_amt 
	END RECORD 
	
	DEFINE modu_rec_current RECORD 
		cust_type LIKE customer.type_code, 
		ar_acct_code LIKE arparms.ar_acct_code, 
		freight_acct_code LIKE arparms.freight_acct_code, 
		lab_acct_code LIKE arparms.lab_acct_code, 
		tax_acct_code LIKE arparms.tax_acct_code, 
		disc_acct_code LIKE arparms.disc_acct_code, 
		exch_acct_code LIKE arparms.exch_acct_code, 
		bal_acct_code LIKE arparms.ar_acct_code, 
		tran_type_ind LIKE batchdetl.tran_type_ind, 
		freight_amt LIKE invoicehead.freight_amt, 
		freight_tax_code LIKE invoicehead.freight_tax_code, 
		freight_tax_amt LIKE invoicehead.freight_tax_amt, 
		hand_amt LIKE invoicehead.hand_amt, 
		hand_tax_code LIKE invoicehead.hand_tax_code, 
		hand_tax_amt LIKE invoicehead.hand_tax_amt, 
		disc_amt LIKE invoicehead.disc_amt, 
		post_flag LIKE invoicehead.posted_flag, 
		jour_code LIKE batchhead.jour_code, 
		jour_num LIKE batchhead.jour_num, 
		ref_num LIKE batchdetl.ref_num, 
		base_debit_amt LIKE batchdetl.debit_amt, 
		base_credit_amt LIKE batchdetl.credit_amt, 
		currency_code LIKE currency.currency_code, 
		exch_ref_code LIKE exchangevar.ref_code 
	END RECORD 
	
	DEFINE modu_passed_desc LIKE batchdetl.desc_text 
	DEFINE modu_idx SMALLINT --, scrn 
	DEFINE modu_sel_text STRING 
	DEFINE modu_where_text STRING 
	DEFINE modu_fisc_year SMALLINT 
	DEFINE modu_fisc_per SMALLINT 
	DEFINE modu_type CHAR(4) 


#####################################################################
# MAIN
#
# ARC - AR Reporting on GL distribution
# This program reports on all transactions FROM AR FOR the nominated
# period (posted AND unposted) by account code
#####################################################################
FUNCTION ARC_main() 
	DEFER quit 
	DEFER interrupt
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

	CALL setModuleId("ARC")
	CALL init_report_ar() #report default data from db-arparms
	CALL AR_temp_tables_create()

	LET modu_type = "FULL" 
	
	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query

		WHEN RPT_OP_MENU #UI/MENU Mode 
			OPEN WINDOW A191 with FORM "A191" 
			CALL windecoration_a("A191") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
		
			MENU "Post Report" 
		
				BEFORE MENU 
					CALL publish_toolbar("kandoo","ARC","menu-post-REPORT") 
					CALL ARC_rpt_process(ARC_rpt_query())
					CALL AR_temp_tables_delete()
					
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 		
		
				ON ACTION "Report" #COMMAND "Run Report" "Enter period selection criteria"
					CALL ARC_rpt_process(ARC_rpt_query())
					CALL AR_temp_tables_delete()
		
				ON ACTION "Print Manager" #COMMAND KEY ("P",f11) "Print" "Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "Exit" 	#COMMAND KEY (interrupt, "E") "Exit" "Exit TO menus"
					EXIT MENU 		
		
			END MENU 
	 		CLOSE WINDOW A191
	 		
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL ARC_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW A191 with FORM "A191" 
			CALL windecoration_a("A191") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(ARC_rpt_query()) #save where clause in env 
			CLOSE WINDOW A191 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL ARC_rpt_process(get_url_sel_text())
	END CASE

	CALL AR_temp_tables_drop()
 
END FUNCTION 
#####################################################################
# END MAIN
#####################################################################


#####################################################################
# FUNCTION db_period_get_datasource(p_filter)
#
#
#####################################################################
FUNCTION db_period_get_datasource(p_filter)
	DEFINE p_filter BOOLEAN
	DEFINE l_arr_rec_period DYNAMIC ARRAY OF RECORD --array[400] OF RECORD 
		year_num SMALLINT, 
		period_num SMALLINT 
	END RECORD
	DEFINE l_period RECORD LIKE period.* 
	DEFINE l_idx SMALLINT
	DEFINE l_where_text STRING
	
	IF p_filter THEN	
		CLEAR FORM 
		#DISPLAY "                               " AT 2,1 # CLEAR menu MESSAGE
		MESSAGE "Enter selection - ESC TO search"	attribute (yellow) 
	
		CONSTRUCT BY NAME l_where_text ON 
			year_num, 
			period_num 
	
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","ARC","construct-period") 
	
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
	
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
	
		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET quit_flag = false 
			LET int_flag = false 
			LET l_where_text = " 1=1 "
		END IF 
	ELSE
		LET l_where_text = " 1=1 "
	END IF

	LET modu_sel_text = 
		"SELECT unique year_num, ", 
		"period_num ", 
		"FROM period ", 
		"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
		"AND ", l_where_text clipped, " ", 
		"ORDER BY year_num, period_num " 

	PREPARE q_period FROM modu_sel_text 
	DECLARE c_period CURSOR FOR q_period 

	LET l_idx = 0 
	FOREACH c_period INTO l_period.year_num, l_period.period_num 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_period[l_idx].year_num = l_period.year_num 
		LET l_arr_rec_period[l_idx].period_num = l_period.period_num

		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF			 
	END FOREACH 

	RETURN l_arr_rec_period
END FUNCTION
#####################################################################
# END FUNCTION db_period_get_datasource(p_filter)
#####################################################################


#####################################################################
# FUNCTION ARC_rpt_query()
#
#
#####################################################################
FUNCTION ARC_rpt_query() 
 
	CALL modu_arr_rec_period.clear()
	CALL db_period_get_datasource(FALSE) RETURNING modu_arr_rec_period

	#MESSAGE ""
	MESSAGE "RETURN on line TO PRINT - DEL TO Exit" 

	--OPTIONS INSERT KEY f36 
	--OPTIONS DELETE KEY f36 

--	INPUT ARRAY modu_arr_rec_period WITHOUT DEFAULTS FROM sr_period.* ATTRIBUTE(UNBUFFERED, APPEND ROW = FALSE, INSERT ROW = FALSE, AUTO APPEND = FALSE, DELETE ROW = FALSE) 
	DISPLAY ARRAY modu_arr_rec_period TO sr_period.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","ARC","inp-period") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "FILTER"
			CALL modu_arr_rec_period.clear()
			CALL db_period_get_datasource(TRUE) RETURNING modu_arr_rec_period

		BEFORE ROW 
			LET modu_idx = arr_curr()
		
		ON ACTION("ACCEPT","DOUBLECLICK") 
			LET modu_fisc_per = modu_arr_rec_period[modu_idx].period_num 
			LET modu_fisc_year = modu_arr_rec_period[modu_idx].year_num 
			IF modu_fisc_year IS NULL THEN 
				ERROR " No year/period selected" 
				NEXT FIELD year_num 
			END IF 
			MESSAGE "Report being generated - please wait" 
			--CALL ARC_rpt_process() 
 
			EXIT DISPLAY
--			MESSAGE "RETURN on line TO PRINT - DEL TO EXIT" 
--			NEXT FIELD year_num 

	END DISPLAY 

	--OPTIONS INSERT KEY f1 
	--OPTIONS DELETE KEY f2 

	IF int_flag OR quit_flag THEN 
		LET quit_flag = false 
		LET int_flag = false
		RETURN NULL
	ELSE
		LET glob_rec_rpt_selector.ref1_num = modu_fisc_per
		LET glob_rec_rpt_selector.ref2_num = modu_fisc_year
		RETURN "1=1"
	END IF 
 END FUNCTION 
#####################################################################
# END FUNCTION ARC_rpt_query()
#####################################################################


#####################################################################
# FUNCTION ARC_rpt_process()
#
#
#####################################################################
FUNCTION ARC_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT  

	
	#------------------------------------------------------------
	BEGIN WORK 
	#------------------------------------------------------------
{
	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"ARC_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT ARC_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ARC_rpt_list")].sel_text
	#------------------------------------------------------------
}
		--LET modu_fisc_per = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ARC_rpt_list")].ref1_num
		--LET modu_fisc_year = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ARC_rpt_list")].ref2_num
		
		# Check that the journals are present

		SELECT * 
		INTO modu_rec_journal.* 
		FROM journal 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND jour_code = glob_rec_arparms.cash_jour_code 
		IF status = NOTFOUND THEN 
			CALL fgl_winmessage("ERROR","Cash Receipts Journal NOT found \nExit Program ","ERROR") 			
			EXIT PROGRAM 
		END IF 

		SELECT * 
		INTO modu_rec_journal.* 
		FROM journal 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND jour_code = glob_rec_arparms.sales_jour_code 
		IF status = NOTFOUND THEN 
			CALL fgl_winmessage("ERROR"," Sales Journal NOT found\nExit Program ","ERROR") 
			EXIT PROGRAM 
		END IF 

		# REPORT all invoice postings
		CALL invoice() 
		# REPORT all credit postings
		CALL credit() 
		# REPORT all receipt postings
		CALL receipt() 
		# REPORT all exchange postings
		CALL exch_var() 
{
	#------------------------------------------------------------
	FINISH REPORT ARC_rpt_list
	CALL rpt_finish("ARC_rpt_list")
	#------------------------------------------------------------
}
	COMMIT WORK
	 
END FUNCTION 
#####################################################################
# END FUNCTION ARC_rpt_process()
#####################################################################


#####################################################################
# FUNCTION get_cust_accts()
#
#
#####################################################################
FUNCTION get_cust_accts() 

	# receivables control, handling, freight, tax AND discount reporting
	# accounts determined by customer type unless NULL

	SELECT 
		ar_acct_code, 
		freight_acct_code, 
		lab_acct_code, 
		tax_acct_code, 
		disc_acct_code, 
		exch_acct_code 
	INTO 
		modu_rec_current.ar_acct_code, 
		vmodu_rec_current.freight_acct_code, 
		modu_rec_current.lab_acct_code, 
		modu_rec_current.tax_acct_code, 
		modu_rec_current.disc_acct_code, 
		modu_rec_current.exch_acct_code 
	FROM customertype 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND type_code = modu_rec_current.cust_type 

	IF status = NOTFOUND THEN 
		LET modu_rec_current.ar_acct_code = NULL 
		LET modu_rec_current.freight_acct_code = NULL 
		LET modu_rec_current.lab_acct_code = NULL 
		LET modu_rec_current.tax_acct_code = NULL 
		LET modu_rec_current.disc_acct_code = NULL 
		LET modu_rec_current.exch_acct_code = NULL 
	END IF 

	IF modu_rec_current.ar_acct_code IS NULL THEN 
		LET modu_rec_current.ar_acct_code = glob_rec_arparms.ar_acct_code 
	END IF 

	IF modu_rec_current.freight_acct_code IS NULL THEN 
		LET modu_rec_current.freight_acct_code = glob_rec_arparms.freight_acct_code 
	END IF 

	IF modu_rec_current.lab_acct_code IS NULL THEN 
		LET modu_rec_current.lab_acct_code = glob_rec_arparms.lab_acct_code 
	END IF 

	IF modu_rec_current.tax_acct_code IS NULL THEN 
		LET modu_rec_current.tax_acct_code = glob_rec_arparms.tax_acct_code 
	END IF 

	IF modu_rec_current.disc_acct_code IS NULL THEN 
		LET modu_rec_current.disc_acct_code = glob_rec_arparms.disc_acct_code 
	END IF 

	IF modu_rec_current.exch_acct_code IS NULL THEN 
		LET modu_rec_current.exch_acct_code = glob_rec_arparms.exch_acct_code 
	END IF 

	LET modu_prev_cust_type = modu_rec_current.cust_type 

END FUNCTION 
#####################################################################
# END FUNCTION get_cust_accts()
#####################################################################


#####################################################################
# FUNCTION ARC_report_gl_batches()
#
#
#####################################################################
FUNCTION ARC_report_gl_batches() 

	# batch posting details according TO receivables control account AND
	# currency code (ie. all entries FOR the same currency AND
	# control/balancing account in one batch)

	DECLARE p_curs CURSOR FOR 
	SELECT unique t_posttemp.ar_acct_code, 
	t_posttemp.currency_code 
	FROM t_posttemp 

	FOREACH p_curs INTO modu_rec_current.bal_acct_code, 
		modu_rec_current.currency_code 
		LET modu_rec_bal_rec.acct_code = modu_rec_current.bal_acct_code 

		LET modu_sel_text = 
			" SELECT ", "\"", modu_rec_current.tran_type_ind clipped, "\",", 
			" t_posttemp.ref_num, ", 
			" t_posttemp.ref_text, ", 
			" t_posttemp.post_acct_code, ", 
			" t_posttemp.desc_text, ", 
			" t_posttemp.debit_amt, ", 
			" t_posttemp.credit_amt, ", 
			" t_posttemp.base_debit_amt, ", 
			" t_posttemp.base_credit_amt, ", 
			" t_posttemp.currency_code, ", 
			" t_posttemp.conv_qty, ", 
			" t_posttemp.tran_date, ", 
			" t_posttemp.post_flag ", 
			" FROM t_posttemp ", 
			" WHERE t_posttemp.ar_acct_code = ", 
			"\"", modu_rec_bal_rec.acct_code clipped, "\"", 
			" AND t_posttemp.currency_code = \"", 
			modu_rec_current.currency_code, "\"" 

		LET modu_rec_current.jour_num = 
			jourprint2(modu_sel_text, 
			glob_rec_kandoouser.cmpy_code, 
			glob_rec_kandoouser.sign_on_code, 
			modu_rec_bal_rec.*, 
			modu_fisc_per, 
			modu_fisc_year, 
			modu_rec_current.jour_code, 
			"A", 
			modu_rec_current.currency_code, 
			#glob_rec_rmsreps.file_text,
			#glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ARC_rpt_list")].file_text, 
			modu_type) 

	END FOREACH 

END FUNCTION 
#####################################################################
# END FUNCTION ARC_report_gl_batches()
#####################################################################


#####################################################################
# FUNCTION invoice()
#
#
#####################################################################
FUNCTION invoice() 
	DEFINE l_cmpy LIKE company.cmpy_code 

	LET modu_prev_cust_type = " " 
	LET modu_rec_current.tran_type_ind = TRAN_TYPE_INVOICE_IN 
	LET modu_rec_current.jour_code = glob_rec_arparms.sales_jour_code 
	LET modu_rec_current.base_debit_amt = 0 

	# SELECT all unposted invoices FOR the required period

	DECLARE in_curs CURSOR FOR 
	SELECT 
		h.cmpy_code, 
		h.inv_num, 
		h.cust_code, 
		h.inv_date, 
		h.currency_code, 
		h.conv_qty, 
		c.type_code, 
		h.freight_amt, 
		h.freight_tax_code, 
		h.freight_tax_amt, 
		h.hand_amt, 
		h.hand_tax_code, 
		h.hand_tax_amt, 
		h.posted_flag 
	FROM invoicehead h, customer c 
	WHERE h.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND h.year_num = modu_fisc_year 
	AND h.period_num = modu_fisc_per 
	AND h.cmpy_code = c.cmpy_code 
	AND h.cust_code = c.cust_code 
	ORDER BY h.cmpy_code, h.cust_code, h.inv_num 

	FOREACH in_curs INTO l_cmpy, 
		modu_rec_docdata.*, 
		modu_rec_current.cust_type, 
		modu_rec_current.freight_amt, 
		modu_rec_current.freight_tax_code, 
		modu_rec_current.freight_tax_amt, 
		modu_rec_current.hand_amt, 
		modu_rec_current.hand_tax_code, 
		modu_rec_current.hand_tax_amt, 
		modu_rec_current.post_flag 

		IF modu_rec_current.cust_type != modu_prev_cust_type THEN 
			CALL get_cust_accts() 
		END IF 

		# INSERT posting data FOR the Invoice freight AND handling amounts

		IF modu_rec_current.freight_amt != 0 THEN 

			IF modu_rec_docdata.conv_qty IS NOT NULL THEN 
				IF modu_rec_docdata.conv_qty != 0 THEN 
					LET modu_rec_current.base_credit_amt = 
					modu_rec_current.freight_amt / modu_rec_docdata.conv_qty 
				END IF 
			END IF 

			INSERT INTO t_posttemp VALUES (
				modu_rec_docdata.ref_num, # invoice number 
				modu_rec_docdata.ref_text, # customer code 
				modu_rec_current.freight_acct_code, # freight control account 
				modu_rec_docdata.ref_num, # invoice number 
				0, 
				modu_rec_current.freight_amt, # invoice freight amount 
				modu_rec_current.base_debit_amt, # zero FOR freight 
				modu_rec_current.base_credit_amt, # converted freight amt 
				modu_rec_docdata.currency_code, # invoice currency code 
				modu_rec_docdata.conv_qty, # invoice conv rate 
				modu_rec_docdata.tran_date, # invoice DATE 
				modu_rec_current.post_flag, # invoice post flag 
				modu_rec_current.ar_acct_code) # ar control account 

		END IF 

		IF modu_rec_current.hand_amt != 0 THEN 

			IF modu_rec_docdata.conv_qty IS NOT NULL THEN 
				IF modu_rec_docdata.conv_qty != 0 THEN 
					LET modu_rec_current.base_credit_amt = 
					modu_rec_current.hand_amt / modu_rec_docdata.conv_qty 
				END IF 
			END IF 

			INSERT INTO t_posttemp VALUES 
			(modu_rec_docdata.ref_num, # invoice number 
			modu_rec_docdata.ref_text, # customer code 
			modu_rec_current.lab_acct_code, # handling control account 
			modu_rec_docdata.ref_num, # invoice number 
			0, 
			modu_rec_current.hand_amt, # invoice handling amount 
			modu_rec_current.base_debit_amt, # zero FOR handling 
			modu_rec_current.base_credit_amt, # converted handling amt 
			modu_rec_docdata.currency_code, # invoice currency code 
			modu_rec_docdata.conv_qty, # invoice conv rate 
			modu_rec_docdata.tran_date, # invoice DATE 
			modu_rec_current.post_flag, # invoice post flag 
			modu_rec_current.ar_acct_code) # ar control account 

		END IF 

		# accumulate handling AND freight tax

		IF modu_rec_current.freight_tax_amt != 0 THEN 
			CALL add_tax(modu_rec_current.freight_tax_code, 
			modu_rec_current.freight_tax_amt) 
		END IF 

		IF modu_rec_current.hand_tax_amt != 0 THEN 
			CALL add_tax(modu_rec_current.hand_tax_code, 
			modu_rec_current.hand_tax_amt) 
		END IF 


		# create posting details FOR the line items FOR the selected invoices

		DECLARE id_curs CURSOR FOR 
		SELECT line_acct_code, 
		line_text, 
		0, 
		ext_sale_amt, 
		tax_code, 
		ext_tax_amt 
		FROM invoicedetl 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND inv_num = modu_rec_docdata.ref_num 
		AND cust_code = modu_rec_docdata.ref_text 

		FOREACH id_curs INTO modu_rec_detldata.*, modu_rec_detltax.* 

			IF modu_rec_docdata.conv_qty IS NOT NULL THEN 
				IF modu_rec_docdata.conv_qty != 0 THEN 
					LET modu_rec_current.base_credit_amt =	modu_rec_detldata.credit_amt / modu_rec_docdata.conv_qty 
				END IF 
			END IF 

			INSERT INTO t_posttemp VALUES 
			(modu_rec_docdata.ref_num, # invoice number 
			modu_rec_docdata.ref_text, # customer code 
			modu_rec_detldata.post_acct_code, # line item gl account 
			modu_rec_detldata.desc_text, # line item desc 
			modu_rec_detldata.debit_amt, # zero FOR TRAN_TYPE_INVOICE_IN 
			modu_rec_detldata.credit_amt, # line item sale amount 
			modu_rec_current.base_debit_amt, # zero FOR TRAN_TYPE_INVOICE_IN 
			modu_rec_current.base_credit_amt, # converted sale amount 
			modu_rec_docdata.currency_code, # invoice currency code 
			modu_rec_docdata.conv_qty, # invoice conv rate 
			modu_rec_docdata.tran_date, # invoice DATE 
			modu_rec_current.post_flag, # stats qty NOT yet in use 
			modu_rec_current.ar_acct_code) # ar control account 

			IF modu_rec_detltax.ext_tax_amt != 0 THEN 
				CALL add_tax(modu_rec_detltax.tax_code, 
				modu_rec_detltax.ext_tax_amt) 
			END IF 
		END FOREACH 

		# now INSERT the accumulated tax postings

		CALL tax_postings(TRAN_TYPE_CREDIT_CR) 

	END FOREACH 

	LET modu_rec_bal_rec.tran_type_ind = TRAN_TYPE_INVOICE_IN 
	LET modu_rec_bal_rec.desc_text = "AR Invoice Balancing Entry" 

	CALL ARC_report_gl_batches() 

	DELETE FROM t_posttemp WHERE 1 = 1 

END FUNCTION 
#####################################################################
# END FUNCTION invoice()
#####################################################################


#####################################################################
# FUNCTION credit()
#
#
#####################################################################
FUNCTION credit() 
	DEFINE l_cmpy LIKE company.cmpy_code 

	LET modu_prev_cust_type = " " 
	LET modu_rec_current.tran_type_ind = TRAN_TYPE_CREDIT_CR 
	LET modu_rec_current.jour_code = glob_rec_arparms.sales_jour_code 
	LET modu_rec_current.base_credit_amt = 0 

	# SELECT all unposted credits FOR the required period

	DECLARE cr_curs CURSOR FOR 
	SELECT h.cmpy_code, 
	h.cred_num, 
	h.cust_code, 
	h.cred_date, 
	h.currency_code, 
	h.conv_qty, 
	c.type_code, 
	h.freight_amt, 
	h.freight_tax_code, 
	h.freight_tax_amt, 
	h.hand_amt, 
	h.hand_tax_code, 
	h.hand_tax_amt, 
	h.disc_amt, 
	h.posted_flag 
	FROM credithead h, customer c 
	WHERE h.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND h.year_num = modu_fisc_year 
	AND h.period_num = modu_fisc_per 
	AND h.cmpy_code = c.cmpy_code 
	AND h.cust_code = c.cust_code 
	ORDER BY h.cmpy_code, h.cust_code, h.cred_num 

	FOREACH cr_curs INTO l_cmpy, 
		modu_rec_docdata.*, 
		modu_rec_current.cust_type, 
		modu_rec_current.freight_amt, 
		modu_rec_current.freight_tax_code, 
		modu_rec_current.freight_tax_amt, 
		modu_rec_current.hand_amt, 
		modu_rec_current.hand_tax_code, 
		modu_rec_current.hand_tax_amt, 
		modu_rec_current.disc_amt, 
		modu_rec_current.post_flag 

		IF modu_rec_current.cust_type != modu_prev_cust_type THEN 
			CALL get_cust_accts() 
		END IF 

		# INSERT posting data FOR the Credit freight, handling, tax AND discount
		# amounts

		IF modu_rec_current.freight_amt != 0 THEN 

			IF modu_rec_docdata.conv_qty IS NOT NULL THEN 
				IF modu_rec_docdata.conv_qty != 0 THEN 
					LET modu_rec_current.base_debit_amt = 
					modu_rec_current.freight_amt / modu_rec_docdata.conv_qty 
				END IF 
			END IF 


			INSERT INTO t_posttemp VALUES 
			(modu_rec_docdata.ref_num, # credit number 
			modu_rec_docdata.ref_text, # customer code 
			modu_rec_current.freight_acct_code, # freight control account 
			modu_rec_docdata.ref_num, # credit number 
			modu_rec_current.freight_amt, # credit freight amount 
			0, 
			modu_rec_current.base_debit_amt, # converted freight amt 
			modu_rec_current.base_credit_amt, # zero FOR credits 
			modu_rec_docdata.currency_code, # credit currency code 
			modu_rec_docdata.conv_qty, # credit conv rate 
			modu_rec_docdata.tran_date, # credit DATE 
			modu_rec_current.post_flag, # credit ppst flag 
			modu_rec_current.ar_acct_code) # ar control account 
		END IF 

		IF modu_rec_current.hand_amt != 0 THEN 

			IF modu_rec_docdata.conv_qty IS NOT NULL THEN 
				IF modu_rec_docdata.conv_qty != 0 THEN 
					LET modu_rec_current.base_debit_amt = 
					modu_rec_current.hand_amt / modu_rec_docdata.conv_qty 
				END IF 
			END IF 


			INSERT INTO t_posttemp VALUES 
			(modu_rec_docdata.ref_num, # credit number 
			modu_rec_docdata.ref_text, # customer code 
			modu_rec_current.lab_acct_code, # handling control account 
			modu_rec_docdata.ref_num, # credit number 
			modu_rec_current.hand_amt, # credit handling amount 
			0, 
			modu_rec_current.base_debit_amt, # converted freight amt 
			modu_rec_current.base_credit_amt, # zero FOR credits 
			modu_rec_docdata.currency_code, # credit currency code 
			modu_rec_docdata.conv_qty, # credit conv rate 
			modu_rec_docdata.tran_date, # credit DATE 
			modu_rec_current.post_flag, # credit post flag 
			modu_rec_current.ar_acct_code) # ar control account 
		END IF 

		IF modu_rec_current.disc_amt IS NOT NULL AND modu_rec_current.disc_amt != 0 
		THEN 

			IF modu_rec_docdata.conv_qty IS NOT NULL THEN 
				IF modu_rec_docdata.conv_qty != 0 THEN 
					LET modu_rec_current.base_debit_amt = 
					modu_rec_current.disc_amt / modu_rec_docdata.conv_qty 
				END IF 
			END IF 

			INSERT INTO t_posttemp VALUES 
			(modu_rec_docdata.ref_num, # credit number 
			modu_rec_docdata.ref_text, # customer code 
			modu_rec_current.disc_acct_code, # discount control account 
			modu_rec_docdata.ref_num, # credit number 
			modu_rec_current.disc_amt, # credit discount amount 
			0, 
			modu_rec_current.base_debit_amt, # converted discount amt 
			modu_rec_current.base_credit_amt, # zero FOR credits 
			modu_rec_docdata.currency_code, # credit currency code 
			modu_rec_docdata.conv_qty, # credit conv rate 
			modu_rec_docdata.tran_date, # credit DATE 
			modu_rec_current.post_flag, # credit post flag 
			modu_rec_current.ar_acct_code) # ar control account 

		END IF 

		# accumulate handling AND freight tax

		IF modu_rec_current.freight_tax_amt != 0 THEN 
			CALL add_tax(modu_rec_current.freight_tax_code, 
			modu_rec_current.freight_tax_amt) 
		END IF 

		IF modu_rec_current.hand_tax_amt != 0 THEN 
			CALL add_tax(modu_rec_current.hand_tax_code, 
			modu_rec_current.hand_tax_amt) 
		END IF 

		# create posting details FOR the line items FOR the selected credits

		DECLARE cd_curs CURSOR FOR 
		SELECT line_acct_code, 
		line_text, 
		ext_sales_amt, 
		0, 
		tax_code, 
		ext_tax_amt 
		FROM creditdetl 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cred_num = modu_rec_docdata.ref_num 
		AND cust_code = modu_rec_docdata.ref_text 

		FOREACH cd_curs INTO modu_rec_detldata.*, 
			modu_rec_detltax.* 

			IF modu_rec_docdata.conv_qty IS NOT NULL THEN 
				IF modu_rec_docdata.conv_qty != 0 THEN 
					LET modu_rec_current.base_debit_amt = 
					modu_rec_detldata.debit_amt / modu_rec_docdata.conv_qty 
				END IF 
			END IF 

			INSERT INTO t_posttemp VALUES 
			(modu_rec_docdata.ref_num, # credit number 
			modu_rec_docdata.ref_text, # customer code 
			modu_rec_detldata.post_acct_code, # line item gl account 
			modu_rec_detldata.desc_text, # line item desc 
			modu_rec_detldata.debit_amt, # line item sale amount 
			modu_rec_detldata.credit_amt, # zero FOR TRAN_TYPE_CREDIT_CR 
			modu_rec_current.base_debit_amt, # converted amt 
			modu_rec_current.base_credit_amt, # zero FOR credits 
			modu_rec_docdata.currency_code, # credit currency code 
			modu_rec_docdata.conv_qty, # credit conv rate 
			modu_rec_docdata.tran_date, # credit DATE 
			modu_rec_current.post_flag, # credit post flag 
			modu_rec_current.ar_acct_code) # ar control account 

			IF modu_rec_detltax.ext_tax_amt != 0 THEN 
				CALL add_tax(modu_rec_detltax.tax_code, 
				modu_rec_detltax.ext_tax_amt) 
			END IF 

		END FOREACH 

		# now INSERT the accumulated tax postings

		CALL tax_postings("DR") 

	END FOREACH 

	LET modu_rec_bal_rec.tran_type_ind = TRAN_TYPE_CREDIT_CR 
	LET modu_rec_bal_rec.desc_text = "AR Credit Balancing Entry" 

	CALL ARC_report_gl_batches() 

	DELETE FROM t_posttemp WHERE 1 = 1 

END FUNCTION 
#####################################################################
# END FUNCTION credit()
#####################################################################


#####################################################################
# FUNCTION receipt()
#
#
#####################################################################
FUNCTION receipt() 
	DEFINE l_cmpy LIKE company.cmpy_code 

	LET modu_prev_cust_type = " " 
	LET modu_rec_current.tran_type_ind = TRAN_TYPE_RECEIPT_CA 
	LET modu_rec_current.jour_code = glob_rec_arparms.cash_jour_code 
	LET modu_rec_current.base_credit_amt = 0 

	# SELECT all unposted cash receipts FOR the required period

	DECLARE ca_curs CURSOR FOR 
	SELECT r.cmpy_code, 
	r.cash_num, 
	r.cust_code, 
	r.cash_date, 
	r.currency_code, 
	r.conv_qty, 
	c.type_code, 
	r.cash_acct_code, 
	r.cash_num, 
	r.cash_amt, 
	0, 
	r.disc_amt, 
	r.posted_flag 
	FROM cashreceipt r, customer c 
	WHERE r.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND r.year_num = modu_fisc_year 
	AND r.period_num = modu_fisc_per 
	AND r.cmpy_code = c.cmpy_code 
	AND r.cust_code = c.cust_code 
	ORDER BY r.cmpy_code, r.cust_code, r.cash_num 

	FOREACH ca_curs INTO l_cmpy, 
		modu_rec_docdata.*, 
		modu_rec_current.cust_type, 
		modu_rec_detldata.*, 
		modu_rec_current.disc_amt, 
		modu_rec_current.post_flag 

		IF modu_rec_current.cust_type != modu_prev_cust_type THEN 
			CALL get_cust_accts() 
		END IF 

		# INSERT posting data FOR the Receipt discount amount

		IF modu_rec_current.disc_amt IS NOT NULL AND modu_rec_current.disc_amt != 0 
		THEN 

			IF modu_rec_docdata.conv_qty IS NOT NULL THEN 
				IF modu_rec_docdata.conv_qty != 0 THEN 
					LET modu_rec_current.base_debit_amt = 
					modu_rec_current.disc_amt / modu_rec_docdata.conv_qty 
				END IF 
			END IF 

			INSERT INTO t_posttemp VALUES 
			(modu_rec_docdata.ref_num, # receipt number 
			modu_rec_docdata.ref_text, # customer code 
			modu_rec_current.disc_acct_code, # discount control account 
			modu_rec_docdata.ref_num, # receipt number 
			modu_rec_current.disc_amt, # receipt discount amount 
			0, 
			modu_rec_current.base_debit_amt, # converted discount amt 
			modu_rec_current.base_credit_amt, # 0 FOR receipts 
			modu_rec_docdata.currency_code, # receipt currency code 
			modu_rec_docdata.conv_qty, # receipt conv rate 
			modu_rec_docdata.tran_date, # receipt DATE 
			modu_rec_current.post_flag, # receipt post flag 
			modu_rec_current.ar_acct_code) # ar control account 

		END IF 

		# create posting details FOR the selected receipts

		IF modu_rec_docdata.conv_qty IS NOT NULL THEN 
			IF modu_rec_docdata.conv_qty != 0 THEN 
				LET modu_rec_current.base_debit_amt = 
				modu_rec_detldata.debit_amt / modu_rec_docdata.conv_qty 
			END IF 
		END IF 

		INSERT INTO t_posttemp VALUES 
		(modu_rec_docdata.ref_num, # receipt number 
		modu_rec_docdata.ref_text, # customer code 
		modu_rec_detldata.post_acct_code, # cash receipt gl account 
		modu_rec_detldata.desc_text, # recipt number 
		modu_rec_detldata.debit_amt, # receipt amount 
		modu_rec_detldata.credit_amt, # zero FOR TRAN_TYPE_RECEIPT_CA 
		modu_rec_current.base_debit_amt, # converted receipt amt 
		modu_rec_current.base_credit_amt, # 0 FOR receipts 
		modu_rec_docdata.currency_code, # receipt currency code 
		modu_rec_docdata.conv_qty, # receipt conv rate 
		modu_rec_docdata.tran_date, # receipt DATE 
		modu_rec_current.post_flag, # receipt post flag 
		modu_rec_current.ar_acct_code) # ar control account 

	END FOREACH 

	LET modu_rec_bal_rec.tran_type_ind = TRAN_TYPE_RECEIPT_CA 
	LET modu_rec_bal_rec.desc_text = "AR Receipt Balancing Entry" 

	CALL ARC_report_gl_batches() 

	DELETE FROM t_posttemp WHERE 1 = 1 

END FUNCTION 
#####################################################################
# END FUNCTION receipt()
#####################################################################


#####################################################################
# FUNCTION exch_var()
#
#
#####################################################################
FUNCTION exch_var() 

	LET modu_prev_cust_type = " " 
	LET modu_rec_current.tran_type_ind = "EXA" 
	LET modu_rec_current.jour_code = glob_rec_arparms.cash_jour_code 

	# INSERT posting data FOR the Receivables exchange variances
	# positive VALUES post as debits, negative VALUES as credits
	# with sign reversed

	DECLARE exd_curs CURSOR FOR 
	SELECT e.ref1_num, 
	e.ref2_num, 
	e.tran_date, 
	e.currency_code, 
	0, 
	e.ref_code, 
	e.exchangevar_amt, 
	c.type_code, 
	e.posted_flag 
	FROM exchangevar e, customer c 
	WHERE e.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND e.year_num = modu_fisc_year 
	AND e.period_num = modu_fisc_per 
	AND e.source_ind = "A" 
	AND e.cmpy_code = c.cmpy_code 
	AND e.ref_code = c.cust_code 
	AND e.exchangevar_amt > 0 
	ORDER BY e.ref_code 

	FOREACH exd_curs INTO modu_rec_docdata.*, 
		modu_rec_current.exch_ref_code, 
		modu_rec_current.base_debit_amt, 
		modu_rec_current.cust_type, 
		modu_rec_current.post_flag 

		IF modu_rec_current.cust_type != modu_prev_cust_type THEN 
			CALL get_cust_accts() 
		END IF 

		INSERT INTO t_posttemp VALUES 
		(modu_rec_docdata.ref_num, # exch var ref 1 
		modu_rec_docdata.ref_text, # exch var ref 2 
		modu_rec_current.exch_acct_code, # exchange control account 
		modu_rec_current.exch_ref_code, # customer code FOR source_ind "A" 
		0, 
		0, 
		modu_rec_current.base_debit_amt, # exch var amount IF +ve, 
		0, 
		modu_rec_docdata.currency_code, # exch var currency code 
		modu_rec_docdata.conv_qty, # exch var conversion rate 
		modu_rec_docdata.tran_date, # exch var DATE 
		modu_rec_current.post_flag, # exchange var post flag 
		modu_rec_current.ar_acct_code) # control account 


	END FOREACH 

	LET modu_rec_bal_rec.tran_type_ind = "EXA" 
	LET modu_rec_bal_rec.desc_text = " AR Exch Var Balancing Entry" 

	CALL ARC_report_gl_batches() 

	DELETE FROM t_posttemp WHERE 1 = 1 

	# now credits

	DECLARE exc_curs CURSOR FOR 
	SELECT e.ref1_num, 
	e.ref2_num, 
	e.tran_date, 
	e.currency_code, 
	0, 
	e.ref_code, 
	e.exchangevar_amt, 
	c.type_code, 
	e.posted_flag 
	FROM exchangevar e, customer c 
	WHERE e.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND e.year_num = modu_fisc_year 
	AND e.period_num = modu_fisc_per 
	AND e.source_ind = "A" 
	AND e.cmpy_code = c.cmpy_code 
	AND e.ref_code = c.cust_code 
	AND e.exchangevar_amt < 0 
	ORDER BY e.ref_code 

	FOREACH exc_curs INTO modu_rec_docdata.*, 
		modu_rec_current.exch_ref_code, 
		modu_rec_current.base_credit_amt, 
		modu_rec_current.cust_type, 
		modu_rec_current.post_flag 

		IF modu_rec_current.cust_type != modu_prev_cust_type THEN 
			CALL get_cust_accts() 
		END IF 

		LET modu_rec_current.base_credit_amt = 
		0 - modu_rec_current.base_credit_amt + 0 

		INSERT INTO t_posttemp VALUES 
		(modu_rec_docdata.ref_num, # exch var ref 1 
		modu_rec_docdata.ref_text, # exch var ref 2 
		modu_rec_current.exch_acct_code, # exchange control account 
		modu_rec_current.exch_ref_code, # customer code FOR source_ind "A" 
		0, 
		0, 
		0, 
		modu_rec_current.base_credit_amt, # exch var amount, sign reversed 
		modu_rec_docdata.currency_code, # exch var currency code 
		modu_rec_docdata.conv_qty, # exch var conversion rate 
		modu_rec_docdata.tran_date, # exch var DATE 
		modu_rec_current.post_flag, # exch var post flag 
		modu_rec_current.ar_acct_code) # control account 


	END FOREACH 

	LET modu_rec_bal_rec.tran_type_ind = "EXA" 
	LET modu_rec_bal_rec.desc_text = " AR Exch Var Balancing Entry" 

	CALL ARC_report_gl_batches() 

	DELETE FROM t_posttemp WHERE 1 = 1 

END FUNCTION 
#####################################################################
# END FUNCTION exch_var()
#####################################################################


#####################################################################
# FUNCTION add_tax(p_tax_code, p_tax_amt)
#
#
#####################################################################
FUNCTION add_tax(p_tax_code, p_tax_amt) 
	DEFINE p_tax_code LIKE tax.tax_code
	DEFINE p_tax_amt LIKE invoicedetl.ext_tax_amt
	DEFINE l_rowid SMALLINT 


	# Posting account IS current FOR type IF tax code IS NULL OR FROM
	# tax table (defaulting TO current) OTHERWISE

	IF p_tax_code IS NULL THEN 
		LET modu_taxtemp.tax_acct_code = modu_rec_current.tax_acct_code 
	ELSE 
		SELECT sell_acct_code 
		INTO modu_taxtemp.tax_acct_code 
		FROM tax 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND tax_code = p_tax_code 
		IF status = NOTFOUND THEN 
			LET modu_taxtemp.tax_acct_code = NULL 
		END IF 
		IF modu_taxtemp.tax_acct_code IS NULL THEN 
			LET modu_taxtemp.tax_acct_code = modu_rec_current.tax_acct_code 
		END IF 
	END IF 

	# IF a total already exists FOR this account, add TO it, OTHERWISE
	# INSERT it
	SELECT rowid 
	INTO l_rowid 
	FROM t_taxtemp 
	WHERE tax_acct_code = modu_taxtemp.tax_acct_code 
	IF status = NOTFOUND THEN 
		LET modu_taxtemp.tax_amt = p_tax_amt 
		INSERT INTO t_taxtemp 
		VALUES (modu_taxtemp.*) 
	ELSE 
		UPDATE t_taxtemp 
		SET tax_amt = tax_amt + p_tax_amt 
		WHERE rowid = l_rowid 
	END IF 

END FUNCTION 
#####################################################################
# END FUNCTION add_tax(p_tax_code, p_tax_amt)
#####################################################################


#####################################################################
# FUNCTION tax_postings(p_post_type)
#
#
#####################################################################
FUNCTION tax_postings(p_post_type) 
	DEFINE p_post_type CHAR(2) 
	DEFINE l_post_type LIKE batchdetl.credit_amt
	DEFINE l_rnd_tax_amt_dr LIKE batchdetl.debit_amt 

	DECLARE c_taxtemp CURSOR FOR 
	SELECT * 
	INTO modu_taxtemp.* 
	FROM t_taxtemp 
	WHERE tax_amt != 0 
	FOREACH c_taxtemp 
		IF p_post_type = TRAN_TYPE_CREDIT_CR THEN 

			IF modu_rec_docdata.conv_qty IS NOT NULL THEN 
				IF modu_rec_docdata.conv_qty != 0 THEN 
					LET modu_rec_current.base_credit_amt = 
					modu_taxtemp.tax_amt / modu_rec_docdata.conv_qty 
				END IF 
			END IF 

			LET l_post_type = modu_taxtemp.tax_amt * 1 
			LET l_rnd_tax_amt_dr = 0 
		ELSE 

			IF modu_rec_docdata.conv_qty IS NOT NULL THEN 
				IF modu_rec_docdata.conv_qty != 0 THEN 
					LET modu_rec_current.base_debit_amt = 
					modu_taxtemp.tax_amt / modu_rec_docdata.conv_qty 
				END IF 
			END IF 

			LET l_rnd_tax_amt_dr = modu_taxtemp.tax_amt * 1 
			LET l_post_type = 0 
		END IF 

		INSERT INTO t_posttemp VALUES 
		(modu_rec_docdata.ref_num, # inv/cred number 
		modu_rec_docdata.ref_text, # customer code 
		modu_taxtemp.tax_acct_code, # tax posting account 
		modu_rec_docdata.ref_num, # inv/cred number 
		l_rnd_tax_amt_dr, # rounded tax amount FOR 
		l_post_type, # this account 
		modu_rec_current.base_debit_amt, # converted tax amt 
		modu_rec_current.base_credit_amt, # converted tax amt 
		modu_rec_docdata.currency_code, # inv/cred currency code 
		modu_rec_docdata.conv_qty, # inv/cred conv rate 
		modu_rec_docdata.tran_date, # inv/cred DATE 
		modu_rec_current.post_flag, # posted flag 
		modu_rec_current.ar_acct_code) # ar control account 
	END FOREACH 

	DELETE FROM t_taxtemp WHERE 1 = 1 

END FUNCTION
#####################################################################
# END FUNCTION tax_postings(p_post_type)
#####################################################################