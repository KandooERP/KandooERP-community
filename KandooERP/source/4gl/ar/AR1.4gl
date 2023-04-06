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
GLOBALS "../ar/AR1_GLOBALS.4gl" 
############################################################
# MODULE Scope Variables
############################################################
DEFINE modu_rec_invoicehead_short record
           cust_code like invoicehead.cust_code,
           name_text like customer.name_text,
           currency_code like customer.currency_code,
           tele_text like customer.tele_text,
           inv_num like invoicehead.inv_num,
           inv_date like invoicehead.inv_date,
           due_date like invoicehead.inv_date,
           purchase_code like invoicehead.purchase_code,
           total_amt like invoicehead.total_amt,
           paid_amt like invoicehead.paid_amt
       end record
       
DEFINE modu_tot_unpaid money(15,2)
DEFINE modu_tot_curr money(15,2)
DEFINE modu_tot_o30 money(15,2)
DEFINE modu_tot_o60 money(15,2)
DEFINE modu_tot_o90 money(15,2)
DEFINE modu_tot_plus money(15,2) 
DEFINE modu_age_date DATE 
DEFINE modu_conv_ind CHAR(1) 
DEFINE modu_rpt_notes_flag CHAR(1)        
############################################################
# FUNCTION ar1_main(p_mode)
#
# Customer Report - Detailed Account Aging
############################################################
FUNCTION AR1_main() 
	DEFER quit 
	DEFER interrupt
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	CALL setModuleId("AR1")
	CALL init_report_ar() #report default data from db-arparms
	CALL AR_temp_tables_create()
	
	LET modu_tot_unpaid = 0 
	LET modu_tot_curr = 0 
	LET modu_tot_o30 = 0 
	LET modu_tot_o60 = 0 
	LET modu_tot_o90 = 0 
	LET modu_tot_plus = 0 	

	LET modu_age_date = today 
	LET modu_conv_ind = "1" 
	LET modu_rpt_notes_flag = "N"

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query

		WHEN RPT_OP_MENU #UI/MENU Mode 		 
			OPEN WINDOW A105 with FORM "A105" 
			CALL windecoration_a("A105") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

			MENU " Aging" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","AR1","menu-aging") 
					CALL AR1_rpt_process(AR1_rpt_query())
					CALL AR_temp_tables_delete()
		
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				ON ACTION "REPORT"	#COMMAND "Report" " SELECT criteria AND PRINT REPORT" 
					CALL AR1_rpt_process(AR1_rpt_query())
					CALL AR_temp_tables_delete()
		
				ON ACTION "Print Manager" #COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "Aging Defaults" #COMMAND "Aging Defaults" " Enter Date TO age FROM" 
					OPEN WINDOW u511 with FORM "U511" 
					CALL windecoration_u("U511") 
		
					INPUT modu_age_date, 
					modu_conv_ind, 
					modu_rpt_notes_flag WITHOUT DEFAULTS 
					FROM age_date, 
					conv_ind, 
					notes_flag 
		
		
						BEFORE INPUT 
							CALL publish_toolbar("kandoo","AR1","inp-aging") 
		
						ON ACTION "WEB-HELP" 
							CALL onlinehelp(getmoduleid(),null) 
		
						ON ACTION "actToolbarManager" 
							CALL setuptoolbar() 
		
						AFTER FIELD age_date 
							IF modu_age_date IS NULL THEN 
								NEXT FIELD age_date 
							END IF 
		
					END INPUT 
		
					CLOSE WINDOW u511 
		
					NEXT option "Report" 
		
				ON ACTION "CANCEL" #COMMAND KEY(interrupt,"E") "Exit" " Exit TO menus"
					LET int_flag = FALSE
					LET quit_flag = FALSE
					EXIT MENU 
		
			END MENU 
		
			CLOSE WINDOW A105 

	 
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL AR1_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW A105 with FORM "A105" 
			CALL windecoration_a("A105") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(AR1_rpt_query()) #save where clause in env 
			CLOSE WINDOW A105 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL AR1_rpt_process(get_url_sel_text())
	END CASE
	
	CALL AR_temp_tables_drop()
END FUNCTION 


############################################################
# FUNCTION AR1_rpt_query() 
#
#
############################################################
FUNCTION AR1_rpt_query() 
	DEFINE l_where_text STRING
	
	CALL set_aging(glob_rec_kandoouser.cmpy_code,modu_age_date) 
	CLEAR FORM 
	

	MESSAGE kandoomsg2("U",1001,"") 
	#1001" Enter Selection Criteria - ESC TO Continue"
	CONSTRUCT BY NAME l_where_text ON 
	customer.cust_code, 
	customer.name_text, 
	customer.addr1_text, 
	customer.addr2_text, 
	customer.city_text, 
	customer.state_code, 
	customer.post_code, 
	customer.country_code, 
	customer.corp_cust_code, 
	customer.currency_code,
	customer.sales_anly_flag,
	customer.inv_addr_flag, 
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
	customer.fax_text,
	customer.tele_text,
	customer.mobile_phone,
	customer.email


		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","AR1","construct-customer") 

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
# FUNCTION AR1_rpt_process()  
#
#
############################################################
FUNCTION AR1_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT   
	DEFINE l_rec_tempdoc RECORD 
		tm_cust LIKE customer.cust_code, 
		tm_name LIKE customer.name_text, 
		tm_cury LIKE customer.currency_code, 
		tm_tele LIKE customer.tele_text, 
		tm_date LIKE customer.setup_date, 
		tm_type CHAR(2), 
		tm_doc INTEGER, 
		tm_refer CHAR(20), 
		tm_late INTEGER, 
		tm_amount money(12,2), 
		tm_unpaid money(12,2), 
		tm_curr money(12,2), 
		tm_o30 money(12,2), 
		tm_o60 money(12,2), 
		tm_o90 money(12,2), 
		tm_plus money(12,2) 
	END RECORD 
	DEFINE l_rec_invoicepay RECORD LIKE invoicepay.* 
--	DEFINE l_rec_invoicehead RECORD #not used ??? 
--		cust_code LIKE invoicehead.cust_code, 
--		name_text LIKE customer.name_text, 
--		currency_code LIKE customer.currency_code, 
--		tele_text LIKE customer.tele_text, 
--		inv_num LIKE invoicehead.inv_num, 
--		inv_date LIKE invoicehead.inv_date, 
--		due_date LIKE invoicehead.inv_date, 
--		purchase_code LIKE invoicehead.purchase_code, 
--		total_amt LIKE invoicehead.total_amt, 
--		paid_amt LIKE invoicehead.paid_amt 
--	END RECORD 
	DEFINE l_rec_credithead RECORD 
		cust_code LIKE credithead.cust_code, 
		name_text LIKE customer.name_text, 
		currency_code LIKE customer.currency_code, 
		tele_text LIKE customer.tele_text, 
		cred_num LIKE credithead.cred_num, 
		cred_date LIKE credithead.cred_date, 
		cred_text LIKE credithead.cred_text, 
		total_amt LIKE credithead.total_amt, 
		appl_amt LIKE credithead.appl_amt 
	END RECORD 
	DEFINE l_rec_cashreceipt RECORD 
		cust_code LIKE cashreceipt.cust_code, 
		name_text LIKE customer.name_text, 
		currency_code LIKE customer.currency_code, 
		tele_text LIKE customer.tele_text, 
		cash_num LIKE cashreceipt.cash_num, 
		cash_date LIKE cashreceipt.cash_date, 
		cheque_text LIKE cashreceipt.cheque_text, 
		cash_amt LIKE cashreceipt.cash_amt, 
		applied_amt LIKE cashreceipt.applied_amt 
	END RECORD 
	DEFINE l_use_customer_report_option CHAR(1) 
	DEFINE l_output STRING #report output file name inc. path

	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"AR1_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT AR1_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AR1_rpt_list")].sel_text
	#------------------------------------------------------------

	CALL set_aging(glob_rec_kandoouser.cmpy_code,modu_age_date) 
	
	LET modu_tot_unpaid = 0 
	LET modu_tot_curr = 0 
	LET modu_tot_o30 = 0 
	LET modu_tot_o60 = 0 
	LET modu_tot_o90 = 0 
	LET modu_tot_plus = 0 

	LET l_query_text = 
	"SELECT invoicehead.cust_code,", 
	"customer.name_text,", 
	"customer.currency_code,", 
	"customer.tele_text,", 
	"invoicehead.inv_num,", 
	"invoicehead.inv_date,", 
	"invoicehead.due_date,", 
	"invoicehead.purchase_code,", 
	"invoicehead.total_amt,", 
	"invoicehead.paid_amt ", 
	"FROM invoicehead,", 
	"customer ", 
	"WHERE customer.cmpy_code = \"",glob_rec_kandoouser.cmpy_code CLIPPED,"\" ", 
	"AND invoicehead.cust_code = customer.cust_code ", 
	"AND invoicehead.cmpy_code = customer.cmpy_code ", 
	"AND invoicehead.total_amt != invoicehead.paid_amt ", 
	"AND invoicehead.posted_flag != \"V\" ", 
	"AND invoicehead.inv_date <= '",modu_age_date,"' ", 
	"AND ",glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AR1_rpt_list")].sel_text clipped
	 
	PREPARE s_invoice FROM l_query_text 
	DECLARE c_invoice CURSOR FOR s_invoice
	 
	FOREACH c_invoice INTO modu_rec_invoicehead_short.* 
		IF get_debug() THEN 
			DISPLAY "########### AR1 - AR1_rpt_query() - SELECT invoicehead.cust_code..... ################"		 
			DISPLAY modu_rec_invoicehead_short.* 
		END IF

		LET l_rec_tempdoc.tm_cust = modu_rec_invoicehead_short.cust_code 
		LET l_rec_tempdoc.tm_name = modu_rec_invoicehead_short.name_text 
		LET l_rec_tempdoc.tm_cury = modu_rec_invoicehead_short.currency_code 
		LET l_rec_tempdoc.tm_tele = modu_rec_invoicehead_short.tele_text 
		LET l_rec_tempdoc.tm_date = modu_rec_invoicehead_short.inv_date 
		LET l_rec_tempdoc.tm_type = TRAN_TYPE_INVOICE_IN 
		LET l_rec_tempdoc.tm_doc = modu_rec_invoicehead_short.inv_num 
		LET l_rec_tempdoc.tm_refer = modu_rec_invoicehead_short.purchase_code 
		LET l_rec_tempdoc.tm_late = get_age_bucket(TRAN_TYPE_INVOICE_IN,modu_rec_invoicehead_short.due_date) 
		LET l_rec_tempdoc.tm_amount = modu_rec_invoicehead_short.total_amt 
		LET l_rec_tempdoc.tm_unpaid = modu_rec_invoicehead_short.total_amt - modu_rec_invoicehead_short.paid_amt 
		LET l_rec_tempdoc.tm_plus = 0 
		LET l_rec_tempdoc.tm_o90 = 0 
		LET l_rec_tempdoc.tm_o60 = 0 
		LET l_rec_tempdoc.tm_o30 = 0 
		LET l_rec_tempdoc.tm_curr = 0 
		CASE 
			WHEN l_rec_tempdoc.tm_late > 90 
				LET l_rec_tempdoc.tm_plus = l_rec_tempdoc.tm_unpaid 
			WHEN l_rec_tempdoc.tm_late > 60 
				LET l_rec_tempdoc.tm_o90 = l_rec_tempdoc.tm_unpaid 
			WHEN l_rec_tempdoc.tm_late > 30 
				LET l_rec_tempdoc.tm_o60 = l_rec_tempdoc.tm_unpaid 
			WHEN l_rec_tempdoc.tm_late > 0 
				LET l_rec_tempdoc.tm_o30 = l_rec_tempdoc.tm_unpaid 
			OTHERWISE 
				LET l_rec_tempdoc.tm_curr = l_rec_tempdoc.tm_unpaid 
		END CASE 

		INSERT INTO t_ar1_rpt_data_shuffle VALUES (l_rec_tempdoc.*) 

		IF int_flag OR quit_flag THEN 
			#8503 Continue Report (Y/N)
			IF kandoomsg("U",8503,"") = "N" THEN 
				ERROR kandoomsg2("U",9501,"") 
				#9501 Report Terminated
				LET int_flag = true 
				LET quit_flag = true 
				EXIT FOREACH 
			END IF 
		END IF 
	END FOREACH 
	
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 
	LET l_query_text = 
	"SELECT credithead.cust_code,", 
	"customer.name_text,", 
	"customer.currency_code,", 
	"customer.tele_text,", 
	"credithead.cred_num,", 
	"credithead.cred_date,", 
	"credithead.cred_text,", 
	"credithead.total_amt, ", 
	"credithead.appl_amt ", 
	"FROM credithead,", 
	"customer ", 
	"WHERE customer.cmpy_code = \"",glob_rec_kandoouser.cmpy_code CLIPPED,"\" ", 
	"AND credithead.cmpy_code = customer.cmpy_code ", 
	"AND credithead.cust_code = customer.cust_code ", 
	"AND credithead.total_amt != credithead.appl_amt ", 
	"AND credithead.posted_flag != \"V\" ", 
	"AND credithead.cred_date <= '",modu_age_date,"' ", 
	"AND ",glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AR1_rpt_list")].sel_text clipped 
	PREPARE s_credit FROM l_query_text 
	DECLARE c_credit CURSOR FOR s_credit 

	#MESSAGE " Reporting on Customer Credit..."  

	FOREACH c_credit INTO l_rec_credithead.* 
		LET l_rec_tempdoc.tm_cust = l_rec_credithead.cust_code 
		LET l_rec_tempdoc.tm_name = l_rec_credithead.name_text 
		LET l_rec_tempdoc.tm_cury = l_rec_credithead.currency_code 
		LET l_rec_tempdoc.tm_tele = l_rec_credithead.tele_text 
		LET l_rec_tempdoc.tm_date = l_rec_credithead.cred_date 
		LET l_rec_tempdoc.tm_type = TRAN_TYPE_CREDIT_CR 
		LET l_rec_tempdoc.tm_doc = l_rec_credithead.cred_num 
		LET l_rec_tempdoc.tm_refer = l_rec_credithead.cred_text 
		LET l_rec_tempdoc.tm_late = get_age_bucket(TRAN_TYPE_CREDIT_CR,l_rec_credithead.cred_date) 
		LET l_rec_tempdoc.tm_amount = 0 - l_rec_credithead.total_amt + 0 
		LET l_rec_tempdoc.tm_unpaid = 0 - (l_rec_credithead.total_amt -	l_rec_credithead.appl_amt) + 0 
		LET l_rec_tempdoc.tm_plus = 0 
		LET l_rec_tempdoc.tm_o90 = 0 
		LET l_rec_tempdoc.tm_o60 = 0 
		LET l_rec_tempdoc.tm_o30= 0 
		LET l_rec_tempdoc.tm_curr = 0 
		CASE 
			WHEN l_rec_tempdoc.tm_late > 90 
				LET l_rec_tempdoc.tm_plus = l_rec_tempdoc.tm_unpaid 
			WHEN l_rec_tempdoc.tm_late > 60 
				LET l_rec_tempdoc.tm_o90 = l_rec_tempdoc.tm_unpaid 
			WHEN l_rec_tempdoc.tm_late > 30 
				LET l_rec_tempdoc.tm_o60 = l_rec_tempdoc.tm_unpaid 
			WHEN l_rec_tempdoc.tm_late > 0 
				LET l_rec_tempdoc.tm_o30 = l_rec_tempdoc.tm_unpaid 
			OTHERWISE 
				LET l_rec_tempdoc.tm_curr = l_rec_tempdoc.tm_unpaid 
		END CASE 

		IF int_flag OR quit_flag THEN 
			#8503 Continue Report (Y/N)
			IF kandoomsg("U",8503,"") = "N" THEN 
				ERROR kandoomsg2("U",9501,"") 
				#9501 Report Terminated
				LET int_flag = true 
				LET quit_flag = true 
				EXIT FOREACH 
			END IF 
		END IF 
		
		INSERT INTO t_ar1_rpt_data_shuffle VALUES (l_rec_tempdoc.*)
		 
	END FOREACH
	 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 
	LET l_query_text = 
	"SELECT cashreceipt.cust_code,", 
	"customer.name_text,", 
	"customer.currency_code,", 
	"customer.tele_text,", 
	"cashreceipt.cash_num,", 
	"cashreceipt.cash_date,", 
	"cashreceipt.cheque_text,", 
	"cashreceipt.cash_amt, ", 
	"cashreceipt.applied_amt ", 
	"FROM cashreceipt,", 
	"customer ", 
	"WHERE customer.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND cashreceipt.cmpy_code = customer.cmpy_code ", 
	"AND cashreceipt.cust_code = customer.cust_code ", 
	"AND cashreceipt.cash_amt != cashreceipt.applied_amt ", 
	"AND cashreceipt.posted_flag != '", CASHRECEIPT_POST_FLAG_STATUS_VOIDED_V, "' ", 
	"AND cashreceipt.cash_date <= '",modu_age_date,"' ", 
	"AND ",glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AR1_rpt_list")].sel_text clipped 
	PREPARE s_cashrec FROM l_query_text 
	DECLARE c_cashrec CURSOR FOR s_cashrec 

	--MESSAGE " Reporting on Customer Cash Receipt..."  

	FOREACH c_cashrec INTO l_rec_cashreceipt.* 
		LET l_rec_tempdoc.tm_cust = l_rec_cashreceipt.cust_code 
		LET l_rec_tempdoc.tm_name = l_rec_cashreceipt.name_text 
		LET l_rec_tempdoc.tm_cury = l_rec_cashreceipt.currency_code 
		LET l_rec_tempdoc.tm_tele = l_rec_cashreceipt.tele_text 
		LET l_rec_tempdoc.tm_date = l_rec_cashreceipt.cash_date 
		LET l_rec_tempdoc.tm_type = TRAN_TYPE_RECEIPT_CA 
		LET l_rec_tempdoc.tm_doc = l_rec_cashreceipt.cash_num 
		LET l_rec_tempdoc.tm_refer = l_rec_cashreceipt.cheque_text 
		LET l_rec_tempdoc.tm_late = get_age_bucket(TRAN_TYPE_RECEIPT_CA,l_rec_cashreceipt.cash_date) 
		LET l_rec_tempdoc.tm_amount = l_rec_cashreceipt.cash_amt 
		LET l_rec_tempdoc.tm_unpaid = 0 - (l_rec_cashreceipt.cash_amt -	l_rec_cashreceipt.applied_amt) 
		LET l_rec_tempdoc.tm_plus = 0 
		LET l_rec_tempdoc.tm_o90 = 0 
		LET l_rec_tempdoc.tm_o60 = 0 
		LET l_rec_tempdoc.tm_o30= 0 
		LET l_rec_tempdoc.tm_curr = 0 
		CASE 
			WHEN l_rec_tempdoc.tm_late > 90 
				LET l_rec_tempdoc.tm_plus = l_rec_tempdoc.tm_unpaid 
			WHEN l_rec_tempdoc.tm_late > 60 
				LET l_rec_tempdoc.tm_o90 = l_rec_tempdoc.tm_unpaid 
			WHEN l_rec_tempdoc.tm_late > 30 
				LET l_rec_tempdoc.tm_o60 = l_rec_tempdoc.tm_unpaid 
			WHEN l_rec_tempdoc.tm_late > 0 
				LET l_rec_tempdoc.tm_o30 = l_rec_tempdoc.tm_unpaid 
			OTHERWISE 
				LET l_rec_tempdoc.tm_curr = l_rec_tempdoc.tm_unpaid 
		END CASE 

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
		
		INSERT INTO t_ar1_rpt_data_shuffle VALUES (l_rec_tempdoc.*) 
		INITIALIZE l_rec_tempdoc.* TO NULL
		 
	END FOREACH 

	################################
	#   INVOICEPAYS
	################################
	# Now we need TO reopen anything closed since the cutoff date
	#################################################################
	LET l_query_text = 
	"SELECT invoicepay.* FROM invoicepay,customer ", 
	"WHERE invoicepay.cmpy_code = \"",glob_rec_kandoouser.cmpy_code CLIPPED,"\" ", 
	"AND invoicepay.pay_date > \"",modu_age_date CLIPPED,"\" ", 
	"AND invoicepay.cmpy_code = customer.cmpy_code ", 
	"AND invoicepay.cust_code = customer.cust_code ", 
	"AND ",glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AR1_rpt_list")].sel_text clipped 
	PREPARE s_invoicepay FROM l_query_text 
	DECLARE c_invoicepay CURSOR FOR s_invoicepay 

	--MESSAGE "Reporting on Customer Invoice Pay..."  

	FOREACH c_invoicepay INTO l_rec_invoicepay.* 
		#################################################################
		# The invoice will already be in the temporary table IF it
		# was entered before the cutoff date AND paid later
		#################################################################
		SELECT * INTO l_rec_tempdoc.* 
		FROM t_ar1_rpt_data_shuffle 
		WHERE tm_doc = l_rec_invoicepay.inv_num 
		AND tm_type = TRAN_TYPE_INVOICE_IN 
		
		IF status = 0 THEN 
			LET l_rec_tempdoc.tm_unpaid = l_rec_tempdoc.tm_unpaid	+ l_rec_invoicepay.pay_amt +l_rec_invoicepay.disc_amt 
			CASE 
				WHEN l_rec_tempdoc.tm_late > 90 
					LET l_rec_tempdoc.tm_plus = l_rec_tempdoc.tm_unpaid 
				WHEN l_rec_tempdoc.tm_late > 60 
					LET l_rec_tempdoc.tm_o90 = l_rec_tempdoc.tm_unpaid 
				WHEN l_rec_tempdoc.tm_late > 30 
					LET l_rec_tempdoc.tm_o60 = l_rec_tempdoc.tm_unpaid 
				WHEN l_rec_tempdoc.tm_late > 0 
					LET l_rec_tempdoc.tm_o30 = l_rec_tempdoc.tm_unpaid 
				OTHERWISE 
					LET l_rec_tempdoc.tm_curr = l_rec_tempdoc.tm_unpaid 
			END CASE 
			
			UPDATE t_ar1_rpt_data_shuffle SET tm_unpaid = l_rec_tempdoc.tm_unpaid, 
			tm_plus = l_rec_tempdoc.tm_plus, 
			tm_o90 = l_rec_tempdoc.tm_o90, 
			tm_o60 = l_rec_tempdoc.tm_o60, 
			tm_o30 = l_rec_tempdoc.tm_o30, 
			tm_cur = l_rec_tempdoc.tm_curr 
			WHERE tm_doc = l_rec_invoicepay.inv_num 
			AND tm_type = TRAN_TYPE_INVOICE_IN
			 
		ELSE 
			###################################################################
			# But paid date IS NOT always applied date so check Invoice if
			# it IS NOT in temporary table AND add it IF it was entered
			# before the cutoff date
			###################################################################
			SELECT invoicehead.cust_code, 
			customer.name_text, 
			customer.currency_code, 
			customer.tele_text, 
			invoicehead.inv_num, 
			invoicehead.inv_date, 
			invoicehead.due_date, 
			invoicehead.purchase_code, 
			invoicehead.total_amt, 
			invoicehead.paid_amt 
			INTO modu_rec_invoicehead_short.* 
			FROM invoicehead, 
			customer 
			WHERE invoicehead.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND invoicehead.inv_num = l_rec_invoicepay.inv_num 
			AND invoicehead.cust_code = l_rec_invoicepay.cust_code 
			AND customer.cust_code = invoicehead.cust_code 
			AND customer.cmpy_code = invoicehead.cmpy_code 
			AND inv_date <= modu_age_date 
			IF status = 0 THEN 
				LET l_rec_tempdoc.tm_cust = modu_rec_invoicehead_short.cust_code 
				LET l_rec_tempdoc.tm_name = modu_rec_invoicehead_short.name_text 
				LET l_rec_tempdoc.tm_cury = modu_rec_invoicehead_short.currency_code 
				LET l_rec_tempdoc.tm_tele = modu_rec_invoicehead_short.tele_text 
				LET l_rec_tempdoc.tm_date = modu_rec_invoicehead_short.inv_date 
				LET l_rec_tempdoc.tm_type = TRAN_TYPE_INVOICE_IN 
				LET l_rec_tempdoc.tm_doc = modu_rec_invoicehead_short.inv_num 
				LET l_rec_tempdoc.tm_refer = modu_rec_invoicehead_short.purchase_code 
				LET l_rec_tempdoc.tm_late = get_age_bucket(TRAN_TYPE_INVOICE_IN, modu_rec_invoicehead_short.due_date) 
				LET l_rec_tempdoc.tm_amount = modu_rec_invoicehead_short.total_amt 
				LET l_rec_tempdoc.tm_unpaid = modu_rec_invoicehead_short.total_amt - modu_rec_invoicehead_short.paid_amt +	l_rec_invoicepay.pay_amt + l_rec_invoicepay.disc_amt
				 
				LET l_rec_tempdoc.tm_plus = 0 
				LET l_rec_tempdoc.tm_o90 = 0 
				LET l_rec_tempdoc.tm_o60 = 0 
				LET l_rec_tempdoc.tm_o30 = 0 
				LET l_rec_tempdoc.tm_curr = 0 
				CASE 
					WHEN l_rec_tempdoc.tm_late > 90 
						LET l_rec_tempdoc.tm_plus = l_rec_tempdoc.tm_unpaid 
					WHEN l_rec_tempdoc.tm_late > 60 
						LET l_rec_tempdoc.tm_o90 = l_rec_tempdoc.tm_unpaid 
					WHEN l_rec_tempdoc.tm_late > 30 
						LET l_rec_tempdoc.tm_o60 = l_rec_tempdoc.tm_unpaid 
					WHEN l_rec_tempdoc.tm_late > 0 
						LET l_rec_tempdoc.tm_o30 = l_rec_tempdoc.tm_unpaid 
					OTHERWISE 
						LET l_rec_tempdoc.tm_curr = l_rec_tempdoc.tm_unpaid 
				END CASE 
				INSERT INTO t_ar1_rpt_data_shuffle VALUES (l_rec_tempdoc.*) 
			END IF 
		END IF 
		#################################################################
		# Need TO check temp table FOR cash receipt first. IF it IS there
		# THEN UPDATE it
		#################################################################
		IF l_rec_invoicepay.pay_type_ind = TRAN_TYPE_RECEIPT_CA THEN 
			SELECT * INTO l_rec_tempdoc.* 
			FROM t_ar1_rpt_data_shuffle 
			WHERE tm_doc = l_rec_invoicepay.ref_num 
			AND tm_type = TRAN_TYPE_RECEIPT_CA
			 
			IF status = 0 THEN 
				LET l_rec_tempdoc.tm_unpaid = l_rec_tempdoc.tm_unpaid - 
				l_rec_invoicepay.pay_amt 
				CASE 
					WHEN l_rec_tempdoc.tm_late > 90 
						LET l_rec_tempdoc.tm_plus = l_rec_tempdoc.tm_unpaid 
					WHEN l_rec_tempdoc.tm_late > 60 
						LET l_rec_tempdoc.tm_o90 = l_rec_tempdoc.tm_unpaid 
					WHEN l_rec_tempdoc.tm_late > 30 
						LET l_rec_tempdoc.tm_o60 = l_rec_tempdoc.tm_unpaid 
					WHEN l_rec_tempdoc.tm_late > 0 
						LET l_rec_tempdoc.tm_o30 = l_rec_tempdoc.tm_unpaid 
					OTHERWISE 
						LET l_rec_tempdoc.tm_curr = l_rec_tempdoc.tm_unpaid 
				END CASE 
				
				UPDATE t_ar1_rpt_data_shuffle SET tm_unpaid = l_rec_tempdoc.tm_unpaid, 
				tm_plus = l_rec_tempdoc.tm_plus, 
				tm_o90 = l_rec_tempdoc.tm_o90, 
				tm_o60 = l_rec_tempdoc.tm_o60, 
				tm_o30 = l_rec_tempdoc.tm_o30, 
				tm_cur = l_rec_tempdoc.tm_curr 
				WHERE tm_doc = l_rec_invoicepay.ref_num 
				AND tm_type = TRAN_TYPE_RECEIPT_CA
				 
			ELSE 
				#################################################################
				# IF cashreceipt IS NOT in temp table THEN SELECT it AND INSERT
				# it IF it was entered before cutoff date
				#################################################################
				SELECT cashreceipt.cust_code, 
				customer.name_text, 
				customer.currency_code, 
				customer.tele_text, 
				cashreceipt.cash_num, 
				cashreceipt.cash_date, 
				cashreceipt.cheque_text, 
				cashreceipt.cash_amt, 
				cashreceipt.applied_amt 
				INTO l_rec_cashreceipt.* 
				FROM cashreceipt, 
				customer 
				WHERE cashreceipt.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cashreceipt.cash_num = l_rec_invoicepay.ref_num 
				AND cashreceipt.cash_date <= modu_age_date 
				AND customer.cust_code = cashreceipt.cust_code 
				AND customer.cmpy_code = cashreceipt.cmpy_code
				 
				IF status = 0 THEN 
					LET l_rec_tempdoc.tm_cust = l_rec_cashreceipt.cust_code 
					LET l_rec_tempdoc.tm_name = l_rec_cashreceipt.name_text 
					LET l_rec_tempdoc.tm_cury = l_rec_cashreceipt.currency_code 
					LET l_rec_tempdoc.tm_tele = l_rec_cashreceipt.tele_text 
					LET l_rec_tempdoc.tm_date = l_rec_cashreceipt.cash_date 
					LET l_rec_tempdoc.tm_type = TRAN_TYPE_RECEIPT_CA 
					LET l_rec_tempdoc.tm_doc = l_rec_cashreceipt.cash_num 
					LET l_rec_tempdoc.tm_refer = l_rec_cashreceipt.cheque_text 
					LET l_rec_tempdoc.tm_late = get_age_bucket(TRAN_TYPE_RECEIPT_CA, l_rec_cashreceipt.cash_date) 
					LET l_rec_tempdoc.tm_unpaid = (l_rec_cashreceipt.applied_amt - l_rec_invoicepay.pay_amt )	- l_rec_cashreceipt.cash_amt 
					LET l_rec_tempdoc.tm_amount = l_rec_cashreceipt.cash_amt 
					LET l_rec_tempdoc.tm_plus = 0 
					LET l_rec_tempdoc.tm_o90 = 0 
					LET l_rec_tempdoc.tm_o60 = 0 
					LET l_rec_tempdoc.tm_o30= 0 
					LET l_rec_tempdoc.tm_curr = 0
					 
					CASE 
						WHEN l_rec_tempdoc.tm_late > 90 
							LET l_rec_tempdoc.tm_plus = l_rec_tempdoc.tm_unpaid 
						WHEN l_rec_tempdoc.tm_late > 60 
							LET l_rec_tempdoc.tm_o90 = l_rec_tempdoc.tm_unpaid 
						WHEN l_rec_tempdoc.tm_late > 30 
							LET l_rec_tempdoc.tm_o60 = l_rec_tempdoc.tm_unpaid 
						WHEN l_rec_tempdoc.tm_late > 0 
							LET l_rec_tempdoc.tm_o30 = l_rec_tempdoc.tm_unpaid 
						OTHERWISE 
							LET l_rec_tempdoc.tm_curr = l_rec_tempdoc.tm_unpaid 
					END CASE 
					
					INSERT INTO t_ar1_rpt_data_shuffle VALUES (l_rec_tempdoc.*) 
					
				END IF 
			END IF 
		ELSE 
		
			# Must be a credit
			SELECT * INTO l_rec_tempdoc.* 
			FROM t_ar1_rpt_data_shuffle 
			WHERE tm_doc = l_rec_invoicepay.ref_num 
			AND tm_type = TRAN_TYPE_CREDIT_CR
			 
			IF status = 0 THEN 
				LET l_rec_tempdoc.tm_unpaid = l_rec_tempdoc.tm_unpaid - l_rec_invoicepay.pay_amt 
				CASE 
					WHEN l_rec_tempdoc.tm_late > 90 
						LET l_rec_tempdoc.tm_plus = l_rec_tempdoc.tm_unpaid 
					WHEN l_rec_tempdoc.tm_late > 60 
						LET l_rec_tempdoc.tm_o90 = l_rec_tempdoc.tm_unpaid 
					WHEN l_rec_tempdoc.tm_late > 30 
						LET l_rec_tempdoc.tm_o60 = l_rec_tempdoc.tm_unpaid 
					WHEN l_rec_tempdoc.tm_late > 0 
						LET l_rec_tempdoc.tm_o30 = l_rec_tempdoc.tm_unpaid 
					OTHERWISE 
						LET l_rec_tempdoc.tm_curr = l_rec_tempdoc.tm_unpaid 
				END CASE 
				
				UPDATE t_ar1_rpt_data_shuffle SET tm_unpaid = l_rec_tempdoc.tm_unpaid, 
				tm_plus = l_rec_tempdoc.tm_plus, 
				tm_o90 = l_rec_tempdoc.tm_o90, 
				tm_o60 = l_rec_tempdoc.tm_o60, 
				tm_o30 = l_rec_tempdoc.tm_o30, 
				tm_cur = l_rec_tempdoc.tm_curr 
				WHERE tm_doc = l_rec_invoicepay.ref_num 
				AND tm_type = TRAN_TYPE_CREDIT_CR 
			ELSE
			 
				#################################################################
				# IF credit IS NOT in temp table THEN SELECT it AND INSERT
				# it IF it was entered before cutoff date
				#################################################################
				SELECT credithead.cust_code, 
				customer.name_text, 
				customer.currency_code, 
				customer.tele_text, 
				credithead.cred_num, 
				credithead.cred_date, 
				credithead.cred_text, 
				credithead.total_amt, 
				credithead.appl_amt 
				INTO l_rec_credithead.* 
				FROM credithead, 
				customer 
				WHERE credithead.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND credithead.cred_num = l_rec_invoicepay.ref_num 
				AND credithead.cred_date <= modu_age_date 
				AND customer.cust_code = credithead.cust_code 
				AND customer.cmpy_code = credithead.cmpy_code 
				IF status = 0 THEN 
					LET l_rec_tempdoc.tm_cust = l_rec_credithead.cust_code 
					LET l_rec_tempdoc.tm_name = l_rec_credithead.name_text 
					LET l_rec_tempdoc.tm_cury = l_rec_credithead.currency_code 
					LET l_rec_tempdoc.tm_tele = l_rec_credithead.tele_text 
					LET l_rec_tempdoc.tm_date = l_rec_credithead.cred_date 
					LET l_rec_tempdoc.tm_type = TRAN_TYPE_CREDIT_CR 
					LET l_rec_tempdoc.tm_doc = l_rec_credithead.cred_num 
					LET l_rec_tempdoc.tm_refer = l_rec_credithead.cred_text 
					LET l_rec_tempdoc.tm_late = get_age_bucket(TRAN_TYPE_CREDIT_CR, l_rec_credithead.cred_date) 
					LET l_rec_tempdoc.tm_amount = 0 - l_rec_credithead.total_amt + 0 
					LET l_rec_tempdoc.tm_unpaid = (l_rec_credithead.appl_amt -	l_rec_invoicepay.pay_amt ) - l_rec_credithead.total_amt 
					LET l_rec_tempdoc.tm_plus = 0 
					LET l_rec_tempdoc.tm_o90 = 0 
					LET l_rec_tempdoc.tm_o60 = 0 
					LET l_rec_tempdoc.tm_o30= 0 
					LET l_rec_tempdoc.tm_curr = 0 
					
					CASE 
						WHEN l_rec_tempdoc.tm_late > 90 
							LET l_rec_tempdoc.tm_plus = l_rec_tempdoc.tm_unpaid 
						WHEN l_rec_tempdoc.tm_late > 60 
							LET l_rec_tempdoc.tm_o90 = l_rec_tempdoc.tm_unpaid 
						WHEN l_rec_tempdoc.tm_late > 30 
							LET l_rec_tempdoc.tm_o60 = l_rec_tempdoc.tm_unpaid 
						WHEN l_rec_tempdoc.tm_late > 0 
							LET l_rec_tempdoc.tm_o30 = l_rec_tempdoc.tm_unpaid 
						OTHERWISE 
							LET l_rec_tempdoc.tm_curr = l_rec_tempdoc.tm_unpaid 
					END CASE
					 
					INSERT INTO t_ar1_rpt_data_shuffle VALUES (l_rec_tempdoc.*)
					 
				END IF 
			END IF 
		END IF
		 
		IF int_flag OR quit_flag THEN 
			#8503 Continue Report (Y/N)
			IF kandoomsg("U",8503,"") = "N" THEN 
				ERROR kandoomsg2("U",9501,"") 
				#9501 Report Terminated
				LET int_flag = true 
				LET quit_flag = true 
				EXIT FOREACH 
			END IF 
		END IF 
	END FOREACH 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF

	LET l_use_customer_report_option = get_kandoooption_feature_state("AR", "RO") 

	IF l_use_customer_report_option = "Y" THEN 
		IF glob_rec_arparms.report_ord_flag = "A" THEN 
			LET l_query_text = "SELECT * FROM t_ar1_rpt_data_shuffle",	" ORDER BY tm_name, tm_cust, tm_date, tm_doc" 
		ELSE 
			LET l_query_text = "SELECT * FROM t_ar1_rpt_data_shuffle",	" ORDER BY tm_cust, tm_date, tm_doc" 
		END IF 
	ELSE 
		LET l_query_text = "SELECT * FROM t_ar1_rpt_data_shuffle", 	" ORDER BY tm_cust, tm_date, tm_doc" 
	END IF 

	PREPARE s_shuffle FROM l_query_text 
	DECLARE selcurs CURSOR FOR s_shuffle 
	
	FOREACH selcurs INTO l_rec_tempdoc.* 
		#---------------------------------------------------------
		OUTPUT TO REPORT AR1_rpt_list(l_rpt_idx,l_rec_tempdoc.*)  
		IF NOT rpt_int_flag_handler2("Customer:",l_rec_tempdoc.tm_cust, l_rec_credithead.name_text,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------	
	END FOREACH

	#------------------------------------------------------------
	FINISH REPORT AR1_rpt_list
	CALL rpt_finish("AR1_rpt_list")
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
# REPORT AR1_rpt_list(p_rec_tempdoc) 
#
#
############################################################
REPORT AR1_rpt_list(p_rpt_idx,p_rec_tempdoc) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_tempdoc RECORD 
		tm_cust CHAR(8), 
		tm_name CHAR(30), 
		tm_cury CHAR(3), 
		tm_tele CHAR(20), 
		tm_date DATE, 
		tm_type CHAR(2), 
		tm_doc INTEGER, 
		tm_refer CHAR(20), 
		tm_late INTEGER, 
		tm_amount money(12,2), 
		tm_unpaid money(12,2), 
		tm_curr money(12,2), 
		tm_o30 money(12,2), 
		tm_o60 money(12,2), 
		tm_o90 money(12,2), 
		tm_plus money(12,2) 
	END RECORD 
	DEFINE l_conv_text CHAR(20) 
	DEFINE l_notes CHAR(6) 
	DEFINE l_rec_customernote RECORD LIKE customernote.* 
	DEFINE l_conv_date DATE
	DEFINE l_line1 NCHAR(130) 
	DEFINE l_line2 NCHAR(130) 
	DEFINE l_line_temp NCHAR(130) 
	DEFINE l_query_text STRING
			 
	OUTPUT 
--	left margin 0 
	ORDER external BY p_rec_tempdoc.tm_cust, p_rec_tempdoc.tm_date, p_rec_tempdoc.tm_doc 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #was l_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #was l_arr_line[3]  
			
			PRINT COLUMN 1, "Date", 
			COLUMN 8, "Trans", 
			COLUMN 15, " Ref", 
			COLUMN 25, glob_rec_arparms.inv_ref2a_text, 
			COLUMN 36, " Days", 
			COLUMN 47, " Total", 
			COLUMN 59, " Unpaid", 
			COLUMN 72, "Current", 
			COLUMN 87, " 1-30", 
			COLUMN 100, "31-60", 
			COLUMN 113, "61-90", 
			COLUMN 124, "90 Plus" 
			PRINT COLUMN 9, "Type", 
			COLUMN 13, "Number", 
			COLUMN 25, glob_rec_arparms.inv_ref2b_text, 
			COLUMN 37, "Late", 
			COLUMN 47, "Amount", 
			COLUMN 60, "Amount", 
			COLUMN 87, " Days", 
			COLUMN 100, " Days", 
			COLUMN 113, " Days", 
			COLUMN 124, " Days" 
			--PRINT COLUMN 1, "Aging FROM: ", modu_age_date USING "dd/mm/yy", 
			--"--------------------------------------------------------", 
			--"------------------------------------------------------" 
			LET l_line_temp = "Aging FROM: ", modu_age_date USING "dd/mm/yy"
			PRINT COLUMN 1, rpt_get_string_with_trailing_char_line(p_rpt_idx,l_line_temp,"-")
			#PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #was l_arr_line[3]  
			
		ON EVERY ROW 
			PRINT COLUMN 1, p_rec_tempdoc.tm_date USING "dd/mm/yy", 
			COLUMN 10, p_rec_tempdoc.tm_type, 
			COLUMN 13, p_rec_tempdoc.tm_doc USING "########", 
			COLUMN 22, p_rec_tempdoc.tm_refer[1,13], 
			COLUMN 36, p_rec_tempdoc.tm_late USING "---&", 
			COLUMN 41, p_rec_tempdoc.tm_amount USING "-----,--&.&&", 
			COLUMN 54, p_rec_tempdoc.tm_unpaid USING "-----,--&.&&", 
			COLUMN 67, p_rec_tempdoc.tm_curr USING "-----,--&.&&", 
			COLUMN 80, p_rec_tempdoc.tm_o30 USING "-----,--&.&&", 
			COLUMN 93, p_rec_tempdoc.tm_o60 USING "-----,--&.&&", 
			COLUMN 106, p_rec_tempdoc.tm_o90 USING "-----,--&.&&", 
			COLUMN 119, p_rec_tempdoc.tm_plus USING "-----,--&.&&" 

			CASE 
				WHEN modu_conv_ind = "1" 
					LET l_conv_text = "aging date" 
					LET l_conv_date = modu_age_date 
				WHEN modu_conv_ind = "2" 
					LET l_conv_text = "transaction date" 
					LET l_conv_date = p_rec_tempdoc.tm_date 
				WHEN modu_conv_ind = "3" 
					LET l_conv_text = "todays date" 
					LET l_conv_date = today 
			END CASE 

			IF modu_conv_ind = "2" THEN 
				LET modu_tot_unpaid = modu_tot_unpaid + conv_currency2(p_rec_tempdoc.tm_type,p_rec_tempdoc.tm_doc, p_rec_tempdoc.tm_cust, 
				p_rec_tempdoc.tm_unpaid,glob_rec_kandoouser.cmpy_code,p_rec_tempdoc.tm_cury, "F", 
				l_conv_date) 
				LET modu_tot_curr = modu_tot_curr + conv_currency2(p_rec_tempdoc.tm_type,p_rec_tempdoc.tm_doc, p_rec_tempdoc.tm_cust, 
				p_rec_tempdoc.tm_curr, glob_rec_kandoouser.cmpy_code,p_rec_tempdoc.tm_cury, "F", 
				l_conv_date) 
				LET modu_tot_o30 = modu_tot_o30 + conv_currency2(p_rec_tempdoc.tm_type,p_rec_tempdoc.tm_doc, p_rec_tempdoc.tm_cust, 
				p_rec_tempdoc.tm_o30, glob_rec_kandoouser.cmpy_code,p_rec_tempdoc.tm_cury, "F", 
				l_conv_date) 
				LET modu_tot_o60 = modu_tot_o60 + conv_currency2(p_rec_tempdoc.tm_type,p_rec_tempdoc.tm_doc, p_rec_tempdoc.tm_cust, 
				p_rec_tempdoc.tm_o60, glob_rec_kandoouser.cmpy_code,p_rec_tempdoc.tm_cury, "F", 
				l_conv_date) 
				LET modu_tot_o90 = modu_tot_o90 + conv_currency2(p_rec_tempdoc.tm_type,p_rec_tempdoc.tm_doc, p_rec_tempdoc.tm_cust, 
				p_rec_tempdoc.tm_o90, glob_rec_kandoouser.cmpy_code,p_rec_tempdoc.tm_cury, "F", 
				l_conv_date) 
				LET modu_tot_plus = modu_tot_plus + conv_currency2(p_rec_tempdoc.tm_type,p_rec_tempdoc.tm_doc, p_rec_tempdoc.tm_cust, 
				p_rec_tempdoc.tm_plus, glob_rec_kandoouser.cmpy_code,p_rec_tempdoc.tm_cury, "F", 
				l_conv_date) 
			ELSE 

				LET modu_tot_unpaid = modu_tot_unpaid + conv_currency(p_rec_tempdoc.tm_unpaid, glob_rec_kandoouser.cmpy_code, 
				p_rec_tempdoc.tm_cury, "F", 
				l_conv_date, "S") 
				LET modu_tot_curr = modu_tot_curr + conv_currency(p_rec_tempdoc.tm_curr, glob_rec_kandoouser.cmpy_code, 
				p_rec_tempdoc.tm_cury, "F", 
				l_conv_date, "S") 
				LET modu_tot_o30 = modu_tot_o30 + conv_currency(p_rec_tempdoc.tm_o30, glob_rec_kandoouser.cmpy_code, 
				p_rec_tempdoc.tm_cury, "F", 
				l_conv_date, "S") 
				LET modu_tot_o60 = modu_tot_o60 + conv_currency(p_rec_tempdoc.tm_o60, glob_rec_kandoouser.cmpy_code, 
				p_rec_tempdoc.tm_cury, "F", 
				l_conv_date, "S") 
				LET modu_tot_o90 = modu_tot_o90 + conv_currency(p_rec_tempdoc.tm_o90, glob_rec_kandoouser.cmpy_code, 
				p_rec_tempdoc.tm_cury, "F", 
				l_conv_date, "S") 
				LET modu_tot_plus = modu_tot_plus + conv_currency(p_rec_tempdoc.tm_plus, glob_rec_kandoouser.cmpy_code, 
				p_rec_tempdoc.tm_cury, "F", 
				l_conv_date, "S") 
			END IF 
			
		BEFORE GROUP OF p_rec_tempdoc.tm_cust 
			SKIP 1 LINES 
			PRINT COLUMN 1, "Customer Code: ", p_rec_tempdoc.tm_cust, 2 spaces, 
			p_rec_tempdoc.tm_name , 2 spaces , p_rec_tempdoc.tm_tele 
			PRINT COLUMN 1, "Currency: ", p_rec_tempdoc.tm_cury 

			IF modu_rpt_notes_flag = "Y" THEN 
				LET l_notes = "Notes:" 
				LET l_query_text = 
				"SELECT *", 
				" FROM customernote", 
				" WHERE customernote.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
				" AND customernote.cust_code = \"",p_rec_tempdoc.tm_cust,"\" " 
				PREPARE s_customernote FROM l_query_text 
				DECLARE c_customernote CURSOR FOR s_customernote 
				SKIP 1 LINES 
				FOREACH c_customernote INTO l_rec_customernote.* 
					PRINT COLUMN 1, l_notes, 
					COLUMN 8, l_rec_customernote.note_date USING "dd/mm/yy", 
					COLUMN 19, l_rec_customernote.note_num USING "--&.&&", 
					COLUMN 28, l_rec_customernote.note_text 
					LET l_notes = " " 
				END FOREACH 
				SKIP 1 LINES 
			END IF 

		AFTER GROUP OF p_rec_tempdoc.tm_cust 
			PRINT COLUMN 55, "-----------------------------------------------", 
			"-----------------------------" 
			PRINT COLUMN 50, GROUP sum(p_rec_tempdoc.tm_unpaid) USING "-----,---,--&.&&", 
			COLUMN 76, GROUP sum(p_rec_tempdoc.tm_o30) USING "-----,---,--&.&&", 
			COLUMN 102, GROUP sum(p_rec_tempdoc.tm_o90) USING "-----,---,--&.&&" 
			PRINT COLUMN 63, GROUP sum(p_rec_tempdoc.tm_curr) USING "-----,---,--&.&&", 
			COLUMN 89, GROUP sum(p_rec_tempdoc.tm_o60) USING "-----,---,--&.&&", 
			COLUMN 115, GROUP sum(p_rec_tempdoc.tm_plus) USING "-----,---,--&.&&" 
			
		ON LAST ROW 
			PRINT COLUMN 1, "All VALUES in local currency", 
			COLUMN 55, "-----------------------------------------------", 
			"-----------------------------" 
			PRINT COLUMN 1, "Converted as AT ",l_conv_text clipped, 
			COLUMN 50, modu_tot_unpaid USING "-----,---,--&.&&", 
			COLUMN 76, modu_tot_o30 USING "-----,---,--&.&&", 
			COLUMN 102, modu_tot_o90 USING "-----,---,--&.&&" 
			PRINT COLUMN 63, modu_tot_curr USING "-----,---,--&.&&", 
			COLUMN 89, modu_tot_o60 USING "-----,---,--&.&&", 
			COLUMN 115, modu_tot_plus USING "-----,---,--&.&&" 
			SKIP 1 line 
			
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	
			


END REPORT