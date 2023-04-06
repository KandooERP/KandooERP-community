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
GLOBALS "../ar/A_AR_GLOBALS.4gl"
GLOBALS "../ar/AC_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/ACB_GLOBALS.4gl"
GLOBALS "../common/glob_GLOBALS_report.4gl"
#####################################################################
# FUNCTION ACB_main() 
#
# glob_from_batch = get_url_batch_number()
#
#  Description:   Debtors Cash Receipts Listing
#                 Provides the facility TO produce a Cash Receipts Listing
#                  FOR processing of Bank Lodgements.
#####################################################################
FUNCTION ACB_main() 
	DEFER interrupt 
	DEFER quit 
	
	CALL setModuleId("ACB") 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 	
			OPEN WINDOW A801 with FORM "A801" 
			CALL windecoration_a("A801") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title

			MENU " Cash Receipt by Customer" 

				BEFORE MENU 
					CALL publish_toolbar("kandoo","ACB","menu-cash-receipt-customer") 
					CALL ACB_rpt_process(ACB_rpt_query())
					
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				ON ACTION "Report" #COMMAND "Run" " Enter selection criteria AND generate REPORT"
					CALL ACB_rpt_process(ACB_rpt_query())

				ON ACTION "Print Manager" #COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "Cancel" #COMMAND KEY("E",interrupt)"Exit" " Exit TO menus"
					EXIT MENU 

			END MENU 

			CLOSE WINDOW A801 

	 
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL ACB_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW A801 with FORM "A801" 
			CALL windecoration_a("A801") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(ACB_rpt_query()) #save where clause in env 
			CLOSE WINDOW A801 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL ACB_rpt_process(get_url_sel_text())
	END CASE 	

END FUNCTION 
#####################################################################
# END FUNCTION ACB_main() 
#####################################################################


#####################################################################
# FUNCTION ACB_rpt_query()
#
#
#####################################################################
FUNCTION ACB_rpt_query() 
	DEFINE l_from_batch LIKE cashrcphdr.batch_no 
	DEFINE l_to_batch LIKE cashrcphdr.batch_no 
	
	INITIALIZE l_from_batch TO NULL 
	INITIALIZE l_to_batch TO NULL 

	INPUT l_from_batch, l_to_batch WITHOUT DEFAULTS 
	FROM from_batch_no, to_batch_no 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","ACB","inp-batch") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield (from_batch_no)  
				CALL view_batch(glob_cmpy_code) RETURNING l_from_batch 
				DISPLAY l_from_batch TO from_batch_no 

		ON ACTION "LOOKUP" infield (to_batch_no) 
				CALL view_batch(glob_cmpy_code) RETURNING l_to_batch 
				DISPLAY l_to_batch TO to_batch_no 

		AFTER FIELD from_batch_no 
			IF l_from_batch IS NOT NULL THEN 
				SELECT batch_no 
				FROM cashrcphdr 
				WHERE cmpy_code = glob_cmpy_code 
				AND batch_no = l_from_batch 

				IF status = NOTFOUND THEN 
					ERROR "No such batch exists in the database" 
					NEXT FIELD from_batch_no 
				END IF 

			END IF 

		AFTER FIELD to_batch_no 
			IF l_to_batch IS NOT NULL THEN 
				SELECT batch_no 
				FROM cashrcphdr 
				WHERE cmpy_code = glob_cmpy_code 
				AND batch_no = l_to_batch 

				IF status = NOTFOUND THEN 
					ERROR "No such batch exists in the database" 
					NEXT FIELD to_batch_no 
				END IF 
			END IF 

		AFTER INPUT #l_from_batch is a smallint !!!!
			IF l_to_batch IS NULL OR l_to_batch = 0 THEN #originalIF l_to_batch IS NULL THEN 
				IF l_from_batch = 0 THEN #IS NULL THEN 
					### SELECT  all batches
					LET l_from_batch = 0 
					SELECT batch_no INTO l_to_batch 
					FROM arparms 
					WHERE cmpy_code = glob_cmpy_code 
				ELSE 
					LET l_to_batch = l_from_batch 
				END IF 
			ELSE 
				IF l_from_batch = 0 THEN --IS NULL THEN 
					LET l_from_batch = l_to_batch 
				END IF 
			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL #=false
	ELSE
		LET glob_from_batch = l_from_batch
		LET glob_to_batch = l_to_batch
		LET glob_rec_rpt_selector.ref1_num = l_from_batch
		LET glob_rec_rpt_selector.ref2_num = l_to_batch
		 
		RETURN "N/A" #no where selector etc.. to pass and NULL would be cancel
	END IF 
END FUNCTION 
#####################################################################
# END FUNCTION ACB_rpt_query()
#####################################################################


#####################################################################
# FUNCTION ACB_rpt_process(p_from_batch, p_to_batch)
#
# #receipt_list
#####################################################################
FUNCTION ACB_rpt_process(p_from_batch)
	DEFINE p_from_batch LIKE cashrcphdr.batch_no 
	DEFINE p_to_batch LIKE cashrcphdr.batch_no 
	DEFINE l_rpt_idx SMALLINT 
	DEFINE l_sec_lvl LIKE kandoouser.security_ind 
	--DEFINE l_rpt_output CHAR (60)
	DEFINE l_cash_total LIKE cashreceipt.cash_amt
	DEFINE l_bank_total LIKE cashreceipt.cash_amt
	DEFINE l_rec_cashrcphdr RECORD LIKE cashrcphdr.*
	DEFINE l_rec_cashreceipt RECORD LIKE cashreceipt.*
	DEFINE l_rec_customer RECORD LIKE customer.* 

	IF get_url_batch_number() != 0 THEN  
		LET p_from_batch = get_url_batch_number() 
		LET p_to_batch = p_from_batch 
	END IF 

	#------------------------------------------------------------
	IF ((p_from_batch IS NULL OR p_to_batch IS NULL) AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"ACB_rpt_list",NULL, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT ACB_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------


	DECLARE scurs_cashrcphdr SCROLL CURSOR with HOLD FOR 
	SELECT cashrcphdr.* INTO l_rec_cashrcphdr.* 
	FROM cashrcphdr 
	WHERE cashrcphdr.batch_no >= p_from_batch #func_arg1
	AND cashrcphdr.batch_no <= p_to_batch  #func_arg2
	AND cashrcphdr.batch_total = cashrcphdr.batch_total_input 
	AND cashrcphdr.bank_flag IS NULL 
	AND cashrcphdr.cmpy_code = glob_cmpy_code 
	ORDER BY batch_no 

	### Check that there exist some batches that are able TO be listed
	OPEN scurs_cashrcphdr 
	FETCH FIRST scurs_cashrcphdr 
	IF status THEN 
		CALL fgl_winmessage("ERROR","None of the chosen batches can generate reports","ERROR") 
		CLOSE scurs_cashrcphdr 
		RETURN 
	END IF 
	CLOSE scurs_cashrcphdr 

	SELECT security_ind INTO l_sec_lvl 
	FROM kandoouser 
	WHERE kandoouser.sign_on_code= glob_username 

	IF l_sec_lvl > "9" THEN 
		LET l_sec_lvl = "9" 
	END IF 

	FOREACH scurs_cashrcphdr 
		LET l_cash_total = 0 
		LET l_bank_total = 0 

		DECLARE scurs_cashreceipt CURSOR FOR 
		SELECT cashreceipt.* 
		INTO l_rec_cashreceipt.* 
		FROM cashreceipt 
		WHERE cmpy_code = glob_cmpy_code 
		AND batch_no = l_rec_cashrcphdr.batch_no 
		AND cash_type_ind in (PAYMENT_TYPE_CASH_C,PAYMENT_TYPE_CHEQUE_Q,PAYMENT_TYPE_CC_P) 
		ORDER BY cust_code, cash_num 

		FOREACH scurs_cashreceipt 
			CALL db_customer_get_rec(UI_OFF,l_rec_cashreceipt.cust_code) RETURNING l_rec_customer.*
--			SELECT customer.* INTO l_rec_customer.* 
--			FROM customer 
--			WHERE cmpy_code = glob_cmpy_code 
--			AND cust_code = l_rec_cashreceipt.cust_code 

			LET l_bank_total = l_bank_total + l_rec_cashreceipt.cash_amt 

			IF l_rec_cashreceipt.cheque_text IS NULL THEN 
				###Receipt was a cash payment
				LET l_cash_total = l_cash_total + l_rec_cashreceipt.cash_amt 
			ELSE 
				### Receipt was a cheque
				### Find some text FOR the Town/City portion of the REPORT
				IF l_rec_customer.city_text IS NULL THEN 
					IF l_rec_customer.addr2_text IS NOT NULL THEN 
						LET l_rec_customer.city_text = l_rec_customer.addr2_text 
					ELSE 
						IF l_rec_customer.addr1_text IS NOT NULL THEN 
							LET l_rec_customer.city_text = l_rec_customer.addr1_text 
						END IF 
					END IF 
				END IF 
				#---------------------------------------------------------
				OUTPUT TO REPORT ACB_rpt_list(l_rpt_idx,
						l_rec_cashrcphdr.batch_date, 
						l_rec_cashrcphdr.batch_no, 
						l_rec_customer.cust_code, 
						l_rec_customer.name_text, 
						l_rec_customer.city_text, 
						l_rec_cashreceipt.cash_amt, 
						l_rec_cashreceipt.drawer_text, 
						l_rec_cashreceipt.bank_text[1,2], 
						l_rec_cashreceipt.branch_text[1,4], 
						l_bank_total) 
				IF NOT rpt_int_flag_handler2("Receipt:",l_rec_cashrcphdr.batch_no, l_rec_customer.cust_code,l_rpt_idx) THEN
					EXIT FOREACH 
				END IF 
				#---------------------------------------------------------	
			END IF 
		END FOREACH #scurs_cashreceipt 

		### OUTPUT cash total
		OUTPUT TO REPORT ACB_rpt_list(l_rec_cashrcphdr.batch_date, 
		l_rec_cashrcphdr.batch_no, 
		"", " CASH", "", l_cash_total, 
		" CASH", "", "", l_bank_total) 

		#---------------------------------------------------------
		OUTPUT TO REPORT ACB_rpt_list(l_rpt_idx,
		l_rec_cashrcphdr.batch_date, 
		l_rec_cashrcphdr.batch_no, 
		"", " CASH", "", l_cash_total, 
		" CASH", "", "", l_bank_total)  
		IF NOT rpt_int_flag_handler2("Receipt:",l_rec_cashrcphdr.batch_no, l_rec_customer.cust_code,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------	

		BEGIN WORK 
			LOCK TABLE cashrcphdr in share MODE 
			LOCK TABLE banking in share MODE 

			UPDATE cashrcphdr SET bank_flag = "Y" 
			WHERE batch_no = l_rec_cashrcphdr.batch_no 
			AND cmpy_code = glob_cmpy_code 

			INSERT INTO banking (bk_cmpy, bk_acct, bk_type, bk_bankdt, 
			bk_desc, bk_cred, bk_enter) 
			VALUES (glob_cmpy_code, l_rec_cashreceipt.cash_acct_code, "CD", 
			today, "Debtors Receipts", l_bank_total ,"Bankdeps") 

		COMMIT WORK 

	END FOREACH #scurs_cashrcphdr 

	#------------------------------------------------------------
	FINISH REPORT ACB_rpt_list
	CALL rpt_finish("ACB_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION #ACB_rpt_process() 
#####################################################################
# END FUNCTION ACB_rpt_process(p_from_batch, p_to_batch)
#####################################################################


#####################################################################
# REPORT ACB_rpt_list(p_rpt_idx,p_rec_report) 
#
#
#####################################################################
REPORT ACB_rpt_list(p_rpt_idx,p_rec_report) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_report RECORD 
		batch_date LIKE cashrcphdr.batch_date, 
		batch_no LIKE cashrcphdr.batch_no, 
		cust_code LIKE customer.cust_code, 
		name_text LIKE customer.name_text, 
		city_text CHAR(15), 
		cash_amt LIKE cashreceipt.cash_amt, 
		drawer_text LIKE cashreceipt.drawer_text, 
		bank CHAR(2), 
		branch CHAR(4), 
		bank_total LIKE cashreceipt.cash_amt 
	END RECORD 

	ORDER BY p_rec_report.batch_no 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		BEFORE GROUP OF p_rec_report.batch_no 
			PRINT COLUMN 14, "Debtors Bank Listing FOR ", p_rec_report.batch_date 
			USING "dd/mm/yyyy", COLUMN 78, "Debtors Bank Listing FOR ", 
			p_rec_report.batch_date USING "dd/mm/yyyy" 
			PRINT 
			PRINT "Batch Number: ", p_rec_report.batch_no, COLUMN 68, 
			"Batch Number: ", p_rec_report.batch_no 
			SKIP 2 LINES 
			PRINT "Client Customer Name", COLUMN 40, "Town/City", COLUMN 68, 
			"Drawer Name", COLUMN 94, "Branch Bank Amount" 
			PRINT 

		ON EVERY ROW 
			PRINT p_rec_report.cust_code, COLUMN 9, p_rec_report.name_text, COLUMN 40, 
			p_rec_report.city_text, COLUMN 56, 
			p_rec_report.cash_amt USING "#####&.##", 
			COLUMN 68, p_rec_report.drawer_text, COLUMN 95, p_rec_report.branch, 
			COLUMN 104, p_rec_report.bank, COLUMN 110, 
			p_rec_report.cash_amt USING "#####&.##" 

		AFTER GROUP OF p_rec_report.batch_no 
			NEED 2 LINES 
			PRINT COLUMN 55, "----------", COLUMN 109, "----------" 
			PRINT COLUMN 34, "TOTAL:", COLUMN 55, 
			p_rec_report.bank_total USING "###,###.##", COLUMN 96, "TOTAL:", 
			COLUMN 109, p_rec_report.bank_total USING "###,###.##" 
			SKIP TO top OF PAGE 

		ON LAST ROW 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 
		
END REPORT 
#####################################################################
# END REPORT ACB_rpt_list(p_rpt_idx,p_rec_report) 
#
#
#####################################################################


########################################################
#Somebody messed up reptfunc.4gl, so it references rpt_list
#ans rpt_default. I have TO invent these two dumies TO make this pxxxx program
#link. who ever did it.. FIX THIS MESS and never do this agaoin...Regards HuHo


#####################################################################
# REPORT ACB_rpt_list_dummy(p_rec_receipt)
#
#
#####################################################################
REPORT ACB_rpt_list_dummy(p_rec_receipt) 
	DEFINE p_rec_receipt RECORD 
		cust_code LIKE cashreceipt.cust_code, 
		name_text LIKE customer.name_text, 
		currency_code LIKE customer.currency_code, 
		cash_num LIKE cashreceipt.cash_num, 
		cash_amt LIKE cashreceipt.cash_amt, 
		cash_date LIKE cashreceipt.cash_date, 
		applied_amt LIKE cashreceipt.applied_amt, 
		cheque_text LIKE cashreceipt.cheque_text, 
		appl_num LIKE invoicepay.appl_num, 
		inv_num LIKE invoicepay.inv_num, 
		apply_num LIKE invoicepay.apply_num, 
		pay_date LIKE invoicepay.pay_date, 
		pay_amt LIKE invoicepay.pay_amt, 
		disc_amt LIKE invoicepay.disc_amt 
	END RECORD
	 
	OUTPUT 
	left margin 0 

	FORMAT 
		ON EVERY ROW 
			PRINT "FIXME" 

END REPORT 
#####################################################################
# END REPORT ACB_rpt_list_dummy(p_rec_receipt)
#####################################################################