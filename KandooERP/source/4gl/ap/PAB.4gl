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
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/PA0_GLOBALS.4gl"
############################################################
# MODULE Scope Variables
############################################################
DEFINE modu_total_amount DECIMAL(16,2) 
############################################################
# FUNCTION PAB_main()
#
# Vendor Ledger
############################################################
FUNCTION PAB_main() 

	DEFER quit 
	DEFER interrupt 
	
	CALL setModuleId("PAB") 	

	CREATE temp TABLE t_openitem(order_field CHAR(38), 
	vend_code CHAR(8), 
	name_text CHAR(30), 
	contra_cust_code CHAR(8), 
	currency_code CHAR(3), 
	tran_date DATE, 
	tran_type CHAR(2), 
	tran_num CHAR(8), 
	tran_ref CHAR(20), 
	tran_amt DECIMAL(16,2), 
	base_amt DECIMAL(16,2), 
	hold_code CHAR(2), 
	com_text CHAR(61)) with no LOG	
	CREATE INDEX openitem_key ON t_openitem(order_field,tran_date,tran_type) 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode
			OPEN WINDOW P100 with FORM "P100" 
			CALL windecoration_p("P100") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

			MENU " Open Item Report" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","PAB","menu-open_item_rep-1")
					CALL rpt_rmsreps_reset(NULL) 
					CALL PAB_rpt_process(PAB_rpt_query())
			
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				ON ACTION "Report" 				#COMMAND "Run" " Enter selection criteria AND generate REPORT"
					CALL rpt_rmsreps_reset(NULL) 
					CALL PAB_rpt_process(PAB_rpt_query())

				ON ACTION "Print Manager" 				#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "CANCEL" 				#COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus"
					EXIT MENU 

			END MENU 

			CLOSE WINDOW P100 
			
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL PAB_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW P100 with FORM "P100" 
			CALL windecoration_p("P100") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(PAB_rpt_query()) #save where clause in env 
			CLOSE WINDOW P100 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL PAB_rpt_process(get_url_sel_text())
	END CASE
END FUNCTION
############################################################
# END FUNCTION PAB_main()
############################################################


############################################################
# FUNCTION PAB_rpt_query()
#
#
############################################################
FUNCTION PAB_rpt_query() 
	DEFINE l_where_text STRING 

	MESSAGE kandoomsg2("W", 1001, "") #1001 " Enter criteria FOR selection - ESC TO begin search"
	CONSTRUCT BY NAME l_where_text ON 
		vend_code, 
		name_text, 
		addr1_text, 
		addr2_text, 
		addr3_text, 
		city_text, 
		state_code, 
		post_code, 
		country_code, 
--		country_text, 
		our_acct_code, 
		contact_text, 
		tele_text, 
		extension_text, 
		fax_text, 
		type_code, 
		term_code, 
		tax_code, 
		currency_code, 
		tax_text, 
		bank_acct_code, 
		drop_flag, 
		language_code 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","PAB","construct-remsreps-1") 

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
# END FUNCTION PAB_rpt_query()
############################################################


############################################################
# FUNCTION PAB_rpt_process(p_where_text)
#
#
############################################################
FUNCTION PAB_rpt_process(p_where_text)
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT  #report array index
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_voucher RECORD LIKE voucher.* 
	DEFINE l_rec_debithead RECORD LIKE debithead.* 
	DEFINE l_rec_cheque RECORD LIKE cheque.* 
	DEFINE l_rec_invoicehead RECORD LIKE invoicehead.* 
	DEFINE l_rec_credithead RECORD LIKE credithead.* 
	DEFINE l_rec_cashreceipt RECORD LIKE cashreceipt.* 
	DEFINE l_rec_openitem RECORD 
				order_field CHAR(30), 
				vend_code CHAR(8), 
				name_text CHAR(30), 
				contra_cust_code CHAR(8), 
				currency_code CHAR(3), 
				tran_date DATE, 
				tran_type CHAR(2), 
				tran_num CHAR(8), 
				tran_ref CHAR(20), 
				tran_amt DECIMAL(16,2), 
				base_amt DECIMAL(16,2), 
				hold_code CHAR(2), 
				com_text CHAR(61) 
			END RECORD 
	DEFINE l_output STRING #report output file name inc. path

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"PAB_rpt_list ",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT PAB_rpt_list  TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------


	#now done it CALL init_p_ap() #init P/AP module
	#SELECT * INTO pr_apparms.* FROM apparms
	# WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
	#   AND parm_code = "1"
	LET l_query_text = "SELECT * FROM vendor ", 
	" WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	" AND ", p_where_text clipped 
	PREPARE s_vendor FROM l_query_text 
	DECLARE c_vendor CURSOR FOR s_vendor 
	
	FOREACH c_vendor INTO l_rec_vendor.* 
		DECLARE c_voucher CURSOR FOR 
		SELECT * INTO l_rec_voucher.* FROM voucher 
		WHERE vend_code = l_rec_vendor.vend_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND paid_amt != total_amt
		 
		FOREACH c_voucher INTO l_rec_voucher.* 
			IF glob_rec_apparms.report_ord_flag = "C" THEN 
				LET l_rec_openitem.order_field = l_rec_vendor.vend_code 
			ELSE 
				LET l_rec_openitem.order_field = l_rec_vendor.name_text,l_rec_vendor.vend_code 
			END IF 
			LET l_rec_openitem.vend_code = l_rec_vendor.vend_code 
			LET l_rec_openitem.name_text = l_rec_vendor.name_text 
			LET l_rec_openitem.contra_cust_code = l_rec_vendor.contra_cust_code 
			LET l_rec_openitem.currency_code = l_rec_vendor.currency_code 
			LET l_rec_openitem.tran_date = l_rec_voucher.vouch_date 
			LET l_rec_openitem.tran_type = "VO" 
			LET l_rec_openitem.tran_num = l_rec_voucher.vouch_code 
			LET l_rec_openitem.tran_ref = l_rec_voucher.inv_text 
			LET l_rec_openitem.tran_amt = l_rec_voucher.total_amt - l_rec_voucher.paid_amt 
			LET l_rec_openitem.base_amt = l_rec_openitem.tran_amt / l_rec_voucher.conv_qty 
			LET l_rec_openitem.hold_code = l_rec_voucher.hold_code 
			LET l_rec_openitem.com_text = l_rec_voucher.com1_text clipped," ",			l_rec_voucher.com2_text
			 
			INSERT INTO t_openitem VALUES (l_rec_openitem.*)
			 
		END FOREACH
		 
		DECLARE c_debithead CURSOR FOR 
		SELECT * INTO l_rec_debithead.* FROM debithead 
		WHERE vend_code = l_rec_vendor.vend_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND apply_amt != total_amt
		 
		FOREACH c_debithead INTO l_rec_debithead.* 
			IF glob_rec_apparms.report_ord_flag = "C" THEN 
				LET l_rec_openitem.order_field = l_rec_vendor.vend_code 
			ELSE 
				LET l_rec_openitem.order_field = l_rec_vendor.name_text, l_rec_vendor.vend_code 
			END IF 
			LET l_rec_openitem.vend_code = l_rec_vendor.vend_code 
			LET l_rec_openitem.name_text = l_rec_vendor.name_text 
			LET l_rec_openitem.contra_cust_code = l_rec_vendor.contra_cust_code 
			LET l_rec_openitem.currency_code = l_rec_vendor.currency_code 
			LET l_rec_openitem.tran_date = l_rec_debithead.debit_date 
			LET l_rec_openitem.tran_type = "DM" 
			LET l_rec_openitem.tran_num = l_rec_debithead.debit_num 
			LET l_rec_openitem.tran_ref = l_rec_debithead.rma_num 
			LET l_rec_openitem.tran_amt = l_rec_debithead.apply_amt - l_rec_debithead.total_amt 
			LET l_rec_openitem.base_amt = l_rec_openitem.tran_amt / l_rec_debithead.conv_qty 
			LET l_rec_openitem.hold_code = NULL 
			LET l_rec_openitem.com_text = l_rec_debithead.com1_text clipped," ",l_rec_debithead.com2_text
			 
			INSERT INTO t_openitem VALUES (l_rec_openitem.*)
			 
		END FOREACH
		 
		DECLARE c_cheque CURSOR FOR 
		SELECT * INTO l_rec_cheque.* FROM cheque 
		WHERE vend_code = l_rec_vendor.vend_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND pay_amt != apply_amt 
		
		FOREACH c_cheque INTO l_rec_cheque.* 
			IF glob_rec_apparms.report_ord_flag = "C" THEN 
				LET l_rec_openitem.order_field = l_rec_vendor.vend_code 
			ELSE 
				LET l_rec_openitem.order_field = l_rec_vendor.name_text, l_rec_vendor.vend_code 
			END IF 
			LET l_rec_openitem.vend_code = l_rec_vendor.vend_code 
			LET l_rec_openitem.name_text = l_rec_vendor.name_text 
			LET l_rec_openitem.contra_cust_code = l_rec_vendor.contra_cust_code 
			LET l_rec_openitem.currency_code = l_rec_vendor.currency_code 
			LET l_rec_openitem.tran_date = l_rec_cheque.cheq_date 
			LET l_rec_openitem.tran_type = "CH" 
			LET l_rec_openitem.tran_num = l_rec_cheque.cheq_code 
			LET l_rec_openitem.tran_ref = l_rec_cheque.com3_text 
			LET l_rec_openitem.tran_amt = l_rec_cheque.apply_amt - l_rec_cheque.pay_amt 
			LET l_rec_openitem.base_amt = l_rec_openitem.tran_amt / l_rec_cheque.conv_qty 
			LET l_rec_openitem.hold_code = NULL 
			LET l_rec_openitem.com_text = l_rec_cheque.com1_text clipped," ",	l_rec_cheque.com2_text 
		
			INSERT INTO t_openitem VALUES (l_rec_openitem.*)
			 
		END FOREACH
		 
		IF l_rec_vendor.contra_cust_code IS NOT NULL THEN 
			DECLARE c_invoicehead CURSOR FOR 
			SELECT * INTO l_rec_invoicehead.* FROM invoicehead 
			WHERE cust_code = l_rec_vendor.contra_cust_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND total_amt != paid_amt 
		
			FOREACH c_invoicehead INTO l_rec_invoicehead.* 
				IF glob_rec_apparms.report_ord_flag = "C" THEN 
					LET l_rec_openitem.order_field = l_rec_vendor.vend_code 
				ELSE 
					LET l_rec_openitem.order_field = l_rec_vendor.name_text, l_rec_vendor.vend_code 
				END IF 
				
				LET l_rec_openitem.vend_code = l_rec_vendor.vend_code 
				LET l_rec_openitem.name_text = l_rec_vendor.name_text 
				LET l_rec_openitem.contra_cust_code = l_rec_vendor.contra_cust_code 
				LET l_rec_openitem.currency_code = l_rec_vendor.currency_code 
				LET l_rec_openitem.tran_date = l_rec_invoicehead.inv_date 
				LET l_rec_openitem.tran_type = TRAN_TYPE_INVOICE_IN 
				LET l_rec_openitem.tran_num = l_rec_invoicehead.inv_num 
				LET l_rec_openitem.tran_ref = l_rec_invoicehead.purchase_code 
				LET l_rec_openitem.tran_amt = l_rec_invoicehead.paid_amt - l_rec_invoicehead.total_amt 
				LET l_rec_openitem.base_amt = l_rec_openitem.tran_amt / l_rec_invoicehead.conv_qty 
				LET l_rec_openitem.hold_code = NULL 
				LET l_rec_openitem.com_text = l_rec_invoicehead.com1_text clipped," ", l_rec_invoicehead.com2_text 
		
				INSERT INTO t_openitem VALUES (l_rec_openitem.*) 
			END FOREACH 
		
			DECLARE c_credithead CURSOR FOR 
			SELECT * INTO l_rec_credithead.* FROM credithead 
			WHERE cust_code = l_rec_vendor.contra_cust_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND total_amt != appl_amt 
		
			FOREACH c_credithead INTO l_rec_credithead.* 
				IF glob_rec_apparms.report_ord_flag = "C" THEN 
					LET l_rec_openitem.order_field = l_rec_vendor.vend_code 
				ELSE 
					LET l_rec_openitem.order_field = l_rec_vendor.name_text, l_rec_vendor.vend_code 
				END IF 
				LET l_rec_openitem.vend_code = l_rec_vendor.vend_code 
				LET l_rec_openitem.name_text = l_rec_vendor.name_text 
				LET l_rec_openitem.contra_cust_code = l_rec_vendor.contra_cust_code 
				LET l_rec_openitem.currency_code = l_rec_vendor.currency_code 
				LET l_rec_openitem.tran_date = l_rec_credithead.cred_date 
				LET l_rec_openitem.tran_type = TRAN_TYPE_CREDIT_CR 
				LET l_rec_openitem.tran_num = l_rec_credithead.cred_num 
				LET l_rec_openitem.tran_ref = l_rec_credithead.rma_num 
				LET l_rec_openitem.tran_amt = l_rec_credithead.total_amt - l_rec_credithead.appl_amt 
				LET l_rec_openitem.base_amt = l_rec_openitem.tran_amt / l_rec_credithead.conv_qty 
				LET l_rec_openitem.hold_code = NULL 
				LET l_rec_openitem.com_text = l_rec_credithead.com1_text clipped," ",	l_rec_credithead.com2_text 
		
				INSERT INTO t_openitem VALUES (l_rec_openitem.*)
				 
			END FOREACH 
		
			DECLARE c_cashreceipt CURSOR FOR 
			SELECT * INTO l_rec_cashreceipt.* FROM cashreceipt 
			WHERE cust_code = l_rec_vendor.contra_cust_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cash_amt != applied_amt 
		
			FOREACH c_cashreceipt INTO l_rec_cashreceipt.* 
				IF glob_rec_apparms.report_ord_flag = "C" THEN 
					LET l_rec_openitem.order_field = l_rec_vendor.vend_code 
				ELSE 
					LET l_rec_openitem.order_field = l_rec_vendor.name_text,	l_rec_vendor.vend_code 
				END IF 
				LET l_rec_openitem.vend_code = l_rec_vendor.vend_code 
				LET l_rec_openitem.name_text = l_rec_vendor.name_text 
				LET l_rec_openitem.contra_cust_code = l_rec_vendor.contra_cust_code 
				LET l_rec_openitem.currency_code = l_rec_vendor.currency_code 
				LET l_rec_openitem.tran_date = l_rec_cashreceipt.cash_date 
				LET l_rec_openitem.tran_type = TRAN_TYPE_RECEIPT_CA 
				LET l_rec_openitem.tran_num = l_rec_cashreceipt.cash_num 
				LET l_rec_openitem.tran_ref = l_rec_cashreceipt.cheque_text 
				LET l_rec_openitem.tran_amt = l_rec_cashreceipt.cash_amt - l_rec_cashreceipt.applied_amt 
				LET l_rec_openitem.base_amt = l_rec_openitem.tran_amt / l_rec_cashreceipt.conv_qty 
				LET l_rec_openitem.hold_code = NULL 
				LET l_rec_openitem.com_text = l_rec_cashreceipt.com1_text clipped," ",l_rec_cashreceipt.com2_text 
				INSERT INTO t_openitem VALUES (l_rec_openitem.*) 
			END FOREACH 

		END IF 
	END FOREACH 

	DECLARE c_openitem CURSOR FOR 
	SELECT * FROM t_openitem 
	ORDER BY order_field, tran_date, tran_type 
	LET modu_total_amount = 0 

	FOREACH c_openitem INTO l_rec_openitem.*
		#---------------------------------------------------------
		OUTPUT TO REPORT PAB_rpt_list(l_rpt_idx,
		l_rec_openitem.*) 
		IF NOT rpt_int_flag_handler2("Vendor:",l_rec_openitem.vend_code, l_rec_openitem.name_text,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------	
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT PAB_rpt_list
	CALL rpt_finish("PAB_rpt_list")
	#------------------------------------------------------------

	DELETE FROM t_openitem 
	WHERE 1=1 

	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
	RETURN true 
	
END FUNCTION 


############################################################
# REPORT PAB_rpt_list(p_rpt_idx,p_openitem) 
#
#
############################################################
REPORT PAB_rpt_list(p_rpt_idx,p_openitem)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx] 
	DEFINE p_openitem RECORD 
				order_field CHAR(30), 
				vend_code CHAR(8), 
				name_text CHAR(30), 
				contra_cust_code CHAR(8), 
				currency_code CHAR(3), 
				tran_date DATE, 
				tran_type CHAR(2), 
				tran_num CHAR(8), 
				tran_ref CHAR(20), 
				tran_amt DECIMAL(16,2), 
				base_amt DECIMAL(16,2), 
				hold_code CHAR(2), 
				com_text CHAR(61) 
			END RECORD 
	DEFINE l_vendor_total DECIMAL(16,2) 

	OUTPUT 
 
	ORDER external BY p_openitem.order_field, 
	p_openitem.tran_date, 
	p_openitem.tran_num 
	
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			
		BEFORE GROUP OF p_openitem.order_field 
			SKIP 1 line 
			LET l_vendor_total = 0 
			IF p_openitem.contra_cust_code IS NOT NULL THEN 
				PRINT COLUMN 01, "Vendor Code: ", p_openitem.vend_code, 
				COLUMN 23, p_openitem.name_text, 
				COLUMN 56, "Contra Customer: ", p_openitem.contra_cust_code, 
				COLUMN 82, "Currency: ", p_openitem.currency_code 
			ELSE 
				PRINT COLUMN 01, "Vendor Code: ", p_openitem.vend_code, 
				COLUMN 23, p_openitem.name_text, 
				COLUMN 56, "Currency: ", p_openitem.currency_code 
			END IF 
			SKIP 1 line 
			
		ON EVERY ROW 
			PRINT COLUMN 01, p_openitem.tran_date USING "dd/mm/yyyy", 
			COLUMN 13, p_openitem.tran_type, 
			COLUMN 19, p_openitem.tran_num, 
			COLUMN 29, p_openitem.tran_ref, 
			COLUMN 50, p_openitem.tran_amt USING "--,---,--&.&&", 
			COLUMN 66, p_openitem.hold_code, 
			COLUMN 72, p_openitem.com_text 
			
		AFTER GROUP OF p_openitem.order_field 
			SKIP 1 line 
			PRINT COLUMN 50, "=============" 
			PRINT COLUMN 50, GROUP sum(p_openitem.tran_amt) USING "--,---,--&.&&" 
			LET modu_total_amount = modu_total_amount + GROUP sum(p_openitem.base_amt) 
			
		ON LAST ROW 
			NEED 8 LINES 
			SKIP 1 line 
			PRINT COLUMN 10, "Total Items In Base Currency: ", 
			count(*) USING "#####", 
			COLUMN 46, modu_total_amount USING "--,---,---,--&.&&" 
			SKIP 2 LINES
			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			
END REPORT
############################################################
# END REPORT PAB_rpt_list(p_rpt_idx,p_openitem) 
############################################################