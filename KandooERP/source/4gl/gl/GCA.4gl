# Module name : GCA.4gl
#Description : A detailed reconciliation REPORT, similar TO GC5 except
#                : it runs off the originating items AND does NOT
#                : consolidate.  Also reports currency conversions
###########################################################################

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "../gl/G_GL_GLOBALS.4gl"
GLOBALS "../gl/GC_GROUP_GLOBALS.4gl" 
GLOBALS "../gl/GCA_GLOBALS.4gl"
GLOBALS 
	DEFINE glob_rec_recon RECORD 
		re_date DATE, 
		re_type char(2), 
		re_ref INTEGER, 
		re_desc char(30), 
		re_debit decimal(16,4), 
		re_cred DECIMAL (16,4), 
		re_dep_num LIKE banking.bank_dep_num, 
		re_conv_qty LIKE batchdetl.conv_qty, 
		re_bs_debit decimal(16,4), 
		re_bs_cred decimal(16,4), 
		re_no_conv SMALLINT, 
		re_check_sum decimal(16,4) #use this TO verify the data 
	END RECORD 
	DEFINE glob_bal_amt LIKE account.bal_amt 
	DEFINE glob_comment_text char(8) 
	DEFINE glob_rec_bank RECORD LIKE bank.* 
	DEFINE glob_sent_one SMALLINT 
	DEFINE glob_unpos_jour money(12,2) 
	DEFINE glob_unpos_cheques money(12,2) 
	DEFINE glob_unpos_cash money(12,2) 
	DEFINE glob_unpos_members money(12,2) 
	DEFINE glob_msg_ans char(1) 
END GLOBALS 
###########################################################################
# MODULE Scope Variables
###########################################################################

###########################################################################
# MAIN
#
#
###########################################################################
MAIN 
	DEFER quit 
	DEFER interrupt 
	
	CALL setModuleId("GCA") 
	CALL ui_init(0) #initial ui init 
	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_g_gl() #init g/gl general ledger module 

	IF get_gl_setup_cash_book_installed() != "Y" THEN 
		CALL fgl_winmessage("Cashbook Error",kandoomsg2("G",9502,""),"ERROR") 
		EXIT PROGRAM 
	END IF 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 	 
			OPEN WINDOW G136 with FORM "G136" 
			CALL windecoration_g("G136") 
		
			MENU " Bank Reconciliation " 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","GCA","menu-bank-reconciliation") 
					CALL GCA_rpt_process(GCA_rpt_query()) 
					CALL rpt_rmsreps_reset(NULL) 
		
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				ON ACTION "Report" #COMMAND "Report" " SELECT criteria AND PRINT REPORT"
					CALL GCA_rpt_process(GCA_rpt_query()) 
					CALL rpt_rmsreps_reset(NULL) 
		
				ON ACTION "PRINT MANAGER"			#COMMAND "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		 
				ON ACTION "Exit"			#COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus"
					EXIT MENU 
		
			END MENU 
		
			CLOSE WINDOW G136 

		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL GCA_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW G136 with FORM "G136" 
			CALL windecoration_g("G136") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(GCA_rpt_query()) #save where clause in env 
			CLOSE WINDOW G136 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL GCA_rpt_process(get_url_sel_text())

	END CASE 	

END MAIN 



############################################################
# FUNCTION GCA_rpt_query()
#
#
############################################################
FUNCTION GCA_rpt_query() 

	INPUT BY NAME glob_rec_bank.bank_code 
	WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GCA","inp-bank_code") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield (bank_code) 
			CALL show_bank(glob_rec_kandoouser.cmpy_code) RETURNING glob_rec_bank.bank_code, 
			glob_rec_bank.acct_code 
			DISPLAY BY NAME glob_rec_bank.bank_code 

			NEXT FIELD bank_code 

		ON CHANGE bank_code
			CALL db_bank_get_rec(UI_ON,glob_rec_bank.bank_code) RETURNING glob_rec_bank.* 
			IF glob_rec_bank.bank_code IS NULL THEN
				ERROR kandoomsg2("U",9111,"Bank code")
				NEXT FIELD bank_code
			END IF
			
			DISPLAY glob_rec_bank.name_acct_text TO name_acct_text 
			DISPLAY glob_rec_bank.name_acct_text TO name_acct_text
			DISPLAY glob_rec_bank.acct_code TO acct_code 
			DISPLAY glob_rec_bank.state_bal_amt TO state_bal_amt
			DISPLAY glob_rec_bank.sheet_num TO sheet_num 

		AFTER FIELD bank_code 
			CALL db_bank_get_rec(UI_ON,glob_rec_bank.bank_code) RETURNING glob_rec_bank.* 
			IF glob_rec_bank.bank_code IS NULL THEN
				ERROR kandoomsg2("U",9111,"Bank code")
				NEXT FIELD bank_code
			END IF
--			SELECT bank.* 
--			INTO glob_rec_bank.* 
--			FROM bank 
--			WHERE bank.bank_code = glob_rec_bank.bank_code 
--			AND bank.cmpy_code = glob_rec_kandoouser.cmpy_code 
--			IF (status = NOTFOUND) THEN 
--				LET glob_msg_ans = kandoomsg("U",9111,"Bank code") 
--				NEXT FIELD bank_code 
--			END IF 
			
			DISPLAY glob_rec_bank.name_acct_text TO name_acct_text 
			DISPLAY glob_rec_bank.name_acct_text TO name_acct_text
			DISPLAY glob_rec_bank.acct_code TO acct_code 
			DISPLAY glob_rec_bank.state_bal_amt TO state_bal_amt
			DISPLAY glob_rec_bank.sheet_num TO sheet_num 


	END INPUT 
	
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL
	ELSE
		LET glob_rec_rpt_selector.ref1_text = glob_rec_bank.bank_code 
		LET glob_rec_rpt_selector.ref1_code = glob_rec_kandoouser.cmpy_code
		RETURN "N/A"
	END IF 	
END FUNCTION 



############################################################
# FUNCTION GCA_rpt_process()
#
#
############################################################
FUNCTION GCA_rpt_process(p_where_text) 
	DEFINE p_where_text STRING
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE l_lv_no_link INTEGER 
	DEFINE l_query_text STRING 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"GCA_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT GCA_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0
	#------------------------------------------------------------

	LET glob_rec_bank.bank_code = glob_rec_rpt_selector.ref1_text
	LET glob_rec_bank.cmpy_code = glob_rec_rpt_selector.ref1_code 

	CALL db_bank_get_rec(UI_ON,glob_rec_bank.bank_code) RETURNING glob_rec_bank.*
	
	SELECT bal_amt 
	INTO glob_bal_amt 
	FROM account 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND acct_code = glob_rec_bank.acct_code 
	AND year_num = 
		(select max (year_num) 
		FROM account 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND acct_code = glob_rec_bank.acct_code) 

	IF status = NOTFOUND THEN 
		LET glob_bal_amt = 0 
	END IF 

#?????????????????????????????????????????????????????????
	#gets the manually entered banking details
	#link back TO the original batch
#	DISPLAY "EXIT: disabled code because of <Anton Dickinson> ecp issue with outer" 
#	DISPLAY "see gl/gca.4gl" 
#	EXIT PROGRAM (1) 


	LET l_query_text = 
	" SELECT banking.bk_bankdt, ", 
	" banking.bk_type, ", 
	" banking.bk_desc, ", 
	" banking.bk_debit, ", 
	" banking.bk_cred, ", 
	" banking.bank_dep_num, ", #contains the jour_num 
	" batchdetl.conv_qty ", 
	" FROM banking, outer batchdetl ", 
	" WHERE banking.bk_cmpy = '", glob_rec_kandoouser.cmpy_code CLIPPED, "'", 
	" AND banking.bk_acct = '", glob_rec_bank.acct_code CLIPPED, "'", 
	" AND (banking.bk_sh_no IS NULL OR banking.bk_rec_part = 'Y') ", 
	" AND banking.bk_type != 'CD' ", #don't want cashreceipts 
	" AND batchdetl.cmpy_code = '", glob_rec_kandoouser.cmpy_code CLIPPED, "'", 
	" AND batchdetl.jour_code = 'CB' ", 
	" AND batchdetl.jour_num = banking.bank_dep_num ", 
	" AND batchdetl.acct_code = banking.bk_acct ", 
	" ORDER BY bk_bankdt, bank_dep_num " 

	PREPARE eretd FROM l_query_text 
	DECLARE cb_3 CURSOR FOR eretd 
	
	INITIALIZE glob_rec_recon.* TO NULL 
	LET glob_comment_text = NULL 

	FOREACH cb_3 INTO glob_rec_recon.re_date, 
		glob_rec_recon.re_type, 
		glob_rec_recon.re_desc, 
		glob_rec_recon.re_debit, 
		glob_rec_recon.re_cred, 
		glob_rec_recon.re_dep_num, 
		glob_rec_recon.re_conv_qty 

		LET glob_comment_text = glob_rec_recon.re_dep_num 
		IF glob_comment_text IS NULL THEN 
			LET glob_comment_text = "No link" 
		END IF 

		#convert TO base
		LET glob_rec_recon.re_no_conv = false 
		
		IF glob_rec_recon.re_conv_qty IS NULL OR glob_rec_recon.re_conv_qty = 0 THEN 
			LET glob_rec_recon.re_conv_qty = get_conv_rate(
				glob_rec_kandoouser.cmpy_code, 
				glob_rec_bank.currency_code, 
				glob_rec_recon.re_date, 
				CASH_EXCHANGE_SELL) 
			LET glob_rec_recon.re_no_conv = true 
		END IF
		 
		LET glob_rec_recon.re_bs_cred = glob_rec_recon.re_cred / glob_rec_recon.re_conv_qty 
		LET glob_rec_recon.re_bs_debit = glob_rec_recon.re_debit / glob_rec_recon.re_conv_qty 

		LET glob_rec_recon.re_check_sum = glob_rec_recon.re_cred - glob_rec_recon.re_debit 

		LET glob_sent_one = true 

		CALL reset_nulls() 

		#---------------------------------------------------------
		OUTPUT TO REPORT GCA_rpt_list(l_rpt_idx,
		"Unreconciled deposits/credits", 
		glob_rec_bank.*, 
		glob_rec_recon.*, 
		glob_comment_text, 
		glob_bal_amt)  
		--IF NOT rpt_int_flag_handler2("Receipt:",l_rec_cashreceipt.cash_num, l_rec_customer.name_text,l_rpt_idx) THEN
		--	EXIT FOREACH 
		--END IF 
		#---------------------------------------------------------

		INITIALIZE glob_rec_recon.* TO NULL 

	END FOREACH 
	#gets the entries FROM AR by originating item conversion rate

	DECLARE cb_4 CURSOR FOR 
	SELECT bk_bankdt, 
	banking.bk_type, 
	banking.bank_dep_num, #contains the deposit number 
	sum(banking.bk_cred) 
	FROM banking 
	WHERE banking.bk_cmpy = glob_rec_kandoouser.cmpy_code 
	AND banking.bk_acct = glob_rec_bank.acct_code 
	AND (banking.bk_sh_no IS NULL OR banking.bk_rec_part = "Y") 
	AND banking.bk_type = 'CD' #cashreceipts only 
	AND banking.bk_cred != 0 # dont pick up 0 bank records 
	GROUP BY bk_bankdt, banking.bk_type, banking.bank_dep_num 
	ORDER BY bk_bankdt, banking.bk_type, bank_dep_num 


	INITIALIZE glob_rec_recon.* TO NULL 
	LET glob_comment_text = NULL 
	LET l_lv_no_link = 0 

	FOREACH cb_4 INTO glob_rec_recon.re_date, 
		glob_rec_recon.re_type, 
		glob_rec_recon.re_dep_num, 
		glob_rec_recon.re_check_sum 


		DECLARE cb_41 CURSOR FOR 
		SELECT cashreceipt.cust_code, 
		cashreceipt.cash_amt, 
		cashreceipt.conv_qty, 
		cashreceipt.cash_num 
		FROM cashreceipt 
		WHERE cashreceipt.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cashreceipt.cash_acct_code = glob_rec_bank.acct_code 
		AND cashreceipt.bank_dep_num = glob_rec_recon.re_dep_num 

		FOREACH cb_41 INTO glob_rec_recon.re_desc, 
			glob_rec_recon.re_cred, 
			glob_rec_recon.re_conv_qty, 
			glob_comment_text 

			LET glob_sent_one = true 

			#convert TO base
			LET glob_rec_recon.re_no_conv = false 
			IF glob_rec_recon.re_conv_qty IS NULL OR 
			glob_rec_recon.re_conv_qty = 0 THEN 
				LET glob_rec_recon.re_conv_qty = get_conv_rate(
					glob_rec_kandoouser.cmpy_code, 
					glob_rec_bank.currency_code, 
					glob_rec_recon.re_date, 
					CASH_EXCHANGE_SELL) 
				
				LET glob_rec_recon.re_no_conv = true 
			END IF 
			
			LET glob_rec_recon.re_bs_cred = glob_rec_recon.re_cred / glob_rec_recon.re_conv_qty 
			LET glob_rec_recon.re_bs_debit = 0 
			LET glob_rec_recon.re_debit = 0 

			CALL reset_nulls() 

			#---------------------------------------------------------
			OUTPUT TO REPORT GCA_rpt_list(l_rpt_idx,
			"Unreconciled deposits/credits", 
			glob_rec_bank.*, glob_rec_recon.*, glob_comment_text, glob_bal_amt) 
			#---------------------------------------------------------

			LET glob_rec_recon.re_desc = '' 
			LET glob_rec_recon.re_cred = 0 
			LET glob_rec_recon.re_conv_qty = 0 
			LET glob_comment_text = '' 
		END FOREACH 

		#IF the link TO cashreceipts failed THEN make sure
		#total prints
		IF glob_rec_recon.re_cred IS NULL THEN 
			LET l_lv_no_link = l_lv_no_link - 1 
			LET glob_rec_recon.re_dep_num = l_lv_no_link 
			LET glob_rec_recon.re_cred = glob_rec_recon.re_check_sum 
			LET glob_comment_text = "No link" 
			LET glob_rec_recon.re_desc = "No link TO cashreceipts" 
			LET glob_sent_one = true 

			#convert TO base
			LET glob_rec_recon.re_no_conv = false 
			IF glob_rec_recon.re_conv_qty IS NULL OR 
			glob_rec_recon.re_conv_qty = 0 THEN 
				LET glob_rec_recon.re_conv_qty = get_conv_rate(
					glob_rec_kandoouser.cmpy_code, 
					glob_rec_bank.currency_code, 
					glob_rec_recon.re_date, 
					CASH_EXCHANGE_SELL) 
			
				LET glob_rec_recon.re_no_conv = true 
			END IF 
			
			LET glob_rec_recon.re_bs_cred = glob_rec_recon.re_cred / glob_rec_recon.re_conv_qty 
			LET glob_rec_recon.re_bs_debit = 0 
			LET glob_rec_recon.re_debit = 0 

			CALL reset_nulls() 

			#---------------------------------------------------------
			OUTPUT TO REPORT GCA_rpt_list(l_rpt_idx,
			"Unreconciled deposits/credits", 
			glob_rec_bank.*, glob_rec_recon.*, glob_comment_text, glob_bal_amt) 
			#---------------------------------------------------------

		END IF 

		INITIALIZE glob_rec_recon.* TO NULL 

	END FOREACH 

#???????????????????????????
#	DISPLAY "EXIT: disabled code because of <Anton Dickinson> ecp issue with outer" 
#	DISPLAY "see gl/gca.4gl" 
#	EXIT PROGRAM (1) 

	LET l_query_text = 
	" SELECT cheq_date, ", 
	" cheq_code, ", 
	" name_text, ", 
	" net_pay_amt, ", 
	" conv_qty, ", 
	#(pay_amt / conv_qty),
	" cheq_code ", 
	" FROM cheque C, outer vendor V ", 
	" WHERE C.cmpy_code = '", glob_rec_kandoouser.cmpy_code CLIPPED, "'", 
	" AND C.bank_acct_code = '", glob_rec_bank.acct_code CLIPPED, "'", 
	" AND (rec_state_num IS NULL OR part_recon_flag = 'Y') ", 
	" AND C.cmpy_code = '", glob_rec_kandoouser.cmpy_code CLIPPED, "'", 
	" AND C.vend_code = V.vend_code ", 
	" AND V.cmpy_code = '", glob_rec_kandoouser.cmpy_code CLIPPED, "'", 
	" ORDER BY cheq_date " 



	#now load cheques FROM cheque accounts payable AP
	PREPARE eert FROM l_query_text 
	DECLARE cb_2 CURSOR FOR eert 

	INITIALIZE glob_rec_recon.* TO NULL 

	FOREACH cb_2 INTO glob_rec_recon.re_date, 
		glob_rec_recon.re_ref, 
		glob_rec_recon.re_desc, 
		glob_rec_recon.re_debit, 
		glob_rec_recon.re_conv_qty, 
		glob_comment_text 


		LET glob_rec_recon.re_dep_num = 0 


		#convert TO base.
		#could have done this in the SELECT but keeps consistent
		#AND allows bad data TO be trapped.
		LET glob_rec_recon.re_no_conv = false 
		IF glob_rec_recon.re_conv_qty IS NULL OR 
		glob_rec_recon.re_conv_qty = 0 THEN 
			LET glob_rec_recon.re_conv_qty = get_conv_rate(
				glob_rec_kandoouser.cmpy_code, 
				glob_rec_bank.currency_code, 
				glob_rec_recon.re_date, 
				CASH_EXCHANGE_SELL) 
			LET glob_rec_recon.re_no_conv = true 
		END IF 
		
		LET glob_rec_recon.re_bs_debit = glob_rec_recon.re_debit / glob_rec_recon.re_conv_qty 


		LET glob_sent_one = true 
		LET glob_rec_recon.re_type = "AP" 

		CALL reset_nulls() 

		#---------------------------------------------------------
		OUTPUT TO REPORT GCA_rpt_list(l_rpt_idx,
		"Unpresented cheques", 
		glob_rec_bank.*, glob_rec_recon.*, glob_comment_text, glob_bal_amt) 
		#---------------------------------------------------------

	END FOREACH 


	IF NOT glob_sent_one THEN 
		#---------------------------------------------------------
		OUTPUT TO REPORT GCA_rpt_list(l_rpt_idx,
		"*** No Unreconciled Items ***", 
		glob_rec_bank.*, glob_rec_recon.*, "", glob_bal_amt) 
		#---------------------------------------------------------
	END IF

	#------------------------------------------------------------
	FINISH REPORT GCA_rpt_list
	CALL rpt_finish("GCA_rpt_list")
	#------------------------------------------------------------

END FUNCTION 


############################################################
# REPORT GCA_rpt_list(p_rpt_idx,p_header_text, p_rec_rr_bank, p_rec_rr_recon, p_comment_text, p_rr_bal_amt)
#
#
############################################################
REPORT GCA_rpt_list(p_rpt_idx,p_header_text, p_rec_rr_bank, p_rec_rr_recon, p_comment_text, p_rr_bal_amt)
 	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_header_text char(30) 
	DEFINE p_rec_rr_bank RECORD LIKE bank.* 
	DEFINE p_rec_rr_recon 
	RECORD 
		re_date DATE, 
		re_type char(2), 
		re_ref INTEGER, 
		re_desc char(30), 
		re_debit decimal(16,4), 
		re_cred DECIMAL (16,4), 
		re_dep_num LIKE banking.bank_dep_num, 
		re_conv_qty LIKE batchdetl.conv_qty, 
		re_bs_debit decimal(16,4), 
		re_bs_cred decimal(16,4), 
		re_no_conv SMALLINT, 
		re_check_sum DECIMAL (16,4) 
	END RECORD 
	DEFINE p_comment_text char(8) 
	DEFINE p_rr_bal_amt LIKE account.bal_amt 

	DEFINE l_rv_check_sum DECIMAL (16,4) 
	DEFINE l_rr_bank_bal decimal(16,4) 
	DEFINE l_rr_bank_debit decimal(16,4) 
	DEFINE l_rr_bank_credit decimal(16,4) 
	--DEFINE  l_tot_debit DECIMAL(16,4)
	--DEFINE l_tot_cred DECIMAL(16,4)
	DEFINE l_clo_bal decimal(16,4) 
	DEFINE l_rv_show_caveat SMALLINT 
	--DEFINE l_rec_rr_company RECORD LIKE company.* 

	ORDER BY p_header_text, 
	p_rec_rr_recon.re_date, #intersperse the banking entries 
	p_rec_rr_recon.re_type, 
	p_rec_rr_recon.re_dep_num 


	FORMAT 

		FIRST PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 


			PRINT p_rec_rr_bank.name_acct_text 

			PRINT "Account ", p_rec_rr_bank.iban 

			PRINT "Last Statement Page ", p_rec_rr_bank.sheet_num USING "<<<<<", 
			1 spaces, "Closing Balances "; 
			PRINT COLUMN 37, p_rec_rr_bank.state_bal_amt USING "------,---,---.--"; 
			PRINT " (", p_rec_rr_bank.currency_code, ")"; 
			PRINT COLUMN 95, p_rec_rr_bank.state_base_bal_amt USING "------,---,---.--"; 
			PRINT " (base)"; 
			PRINT 


			PRINT 

		BEFORE GROUP OF p_header_text 
			PRINT 
			PRINT COLUMN 16, p_header_text; 
			PRINT COLUMN 51, glob_rec_bank.currency_code; 
			PRINT COLUMN 89, "Exch. rate"; 
			PRINT COLUMN 113, glob_rec_company.curr_code 

		ON EVERY ROW 

			#credits & debits reverse sides
			PRINT COLUMN 1, p_rec_rr_recon.re_date USING "dd/mm/yy" ; 
			PRINT COLUMN 10, p_rec_rr_recon.re_desc[1,25]; 
			#informix 4GL(?) has no means of suppressing zero on a DECIMAL. ha.
			IF p_rec_rr_recon.re_cred != 0 THEN 
				PRINT COLUMN 37, p_rec_rr_recon.re_cred USING "------,---,---.--"; 
			END IF 
			IF p_rec_rr_recon.re_debit != 0 THEN 
				PRINT COLUMN 55, p_rec_rr_recon.re_debit USING "------,---,---.--"; 
			END IF 
			CASE 
				WHEN p_rec_rr_recon.re_type = 'AP' 
					PRINT COLUMN 73, "CHQ ", p_comment_text ; 
				WHEN p_rec_rr_recon.re_type = 'CD' 
					PRINT COLUMN 73, "CSH ", p_comment_text ; 
				OTHERWISE 
					PRINT COLUMN 73, "BCH ", p_comment_text ; 
			END CASE 
			PRINT COLUMN 86, p_rec_rr_recon.re_conv_qty USING "###.&&&"; 
			IF p_rec_rr_recon.re_no_conv THEN 
				PRINT COLUMN 94, "*"; 
				LET l_rv_show_caveat = true 
			END IF 
			IF p_rec_rr_recon.re_bs_cred != 0 THEN 
				PRINT COLUMN 95, p_rec_rr_recon.re_bs_cred USING "------,---,---.--"; 
			END IF 
			IF p_rec_rr_recon.re_bs_debit != 0 THEN 
				PRINT COLUMN 113, p_rec_rr_recon.re_bs_debit USING "------,---,---.--" 
			ELSE 
				PRINT 
			END IF 



		AFTER GROUP OF p_rec_rr_recon.re_dep_num 
			#check the totals TO make sure they agree.

			LET l_rv_check_sum = (group sum(p_rec_rr_recon.re_cred)) - 
			(group sum(p_rec_rr_recon.re_debit)) 

			IF p_rec_rr_recon.re_check_sum != l_rv_check_sum THEN 
				PRINT 
				"ERROR **** the total in banking does NOT equal the total ", 
				"of the originating items. "; 

				IF p_rec_rr_recon.re_dep_num IS NOT NULL 
				AND p_rec_rr_recon.re_dep_num != 0 THEN 
					PRINT "There are errors in your data FOR Bank deposit number "; 
					PRINT p_rec_rr_recon.re_dep_num USING "<<<<<<<<" 
				ELSE 
					PRINT 
				END IF 

			END IF 


		ON LAST ROW 


			NEED 14 LINES 

			PRINT 
			PRINT 
			PRINT " Cash Book Current position" 
			PRINT " --------------------------" 

			PRINT 

			PRINT "Total Debits " ; 
			PRINT COLUMN 37, sum(p_rec_rr_recon.re_cred) USING "------,---,---.--"; 
			PRINT COLUMN 95, sum(p_rec_rr_recon.re_bs_cred) USING "------,---,---.--" 

			PRINT "Total Credits "; 
			PRINT COLUMN 55, sum(p_rec_rr_recon.re_debit) USING "------,---,---.--"; 
			PRINT COLUMN 113, sum(p_rec_rr_recon.re_bs_debit) USING "------,---,---.--" 

			PRINT 
			PRINT "Cash Book Current Balance "; 

			IF p_rec_rr_bank.state_bal_amt IS NULL THEN 
				LET p_rec_rr_bank.state_bal_amt = 0 
			END IF 

			IF p_rec_rr_bank.state_base_bal_amt IS NULL THEN 
				LET p_rec_rr_bank.state_base_bal_amt = 0 
			END IF 


			#PRINT fx total
			LET l_rr_bank_bal = p_rec_rr_bank.state_bal_amt + sum(p_rec_rr_recon.re_cred) 
			- sum(p_rec_rr_recon.re_debit) 
			IF l_rr_bank_bal >= 0 THEN 
				PRINT COLUMN 54, l_rr_bank_bal USING "###,###,###,##&.&& dr"; 
			ELSE 
				LET l_rr_bank_bal = - l_rr_bank_bal 
				PRINT COLUMN 36, l_rr_bank_bal USING "###,###,###,##&.&& cr"; 
			END IF 

			#PRINT base total
			LET l_rr_bank_bal = p_rec_rr_bank.state_base_bal_amt + sum(p_rec_rr_recon.re_bs_cred) 
			- sum(p_rec_rr_recon.re_bs_debit) 
			IF l_rr_bank_bal >= 0 THEN 
				PRINT COLUMN 112, l_rr_bank_bal USING "######,###,##&.&& dr" 
			ELSE 
				LET l_rr_bank_bal = - l_rr_bank_bal 
				PRINT COLUMN 94, l_rr_bank_bal USING "######,###,##&.&& cr" 
			END IF 





			PRINT 
			PRINT " General Ledger summary" 
			PRINT " ----------------------" 

			PRINT COLUMN 1, "**** All VALUES in base currency ****" 
			PRINT 

			PRINT "General Ledger Balance ", today, 
			COLUMN 113, p_rr_bal_amt USING "------,---,---.##" 

			# now get unposted cheques

			SELECT sum(net_pay_amt / conv_qty) 
			INTO glob_unpos_cheques 
			FROM cheque 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND bank_acct_code = p_rec_rr_bank.acct_code 
			AND post_flag = "N" 

			IF glob_unpos_cheques IS NULL THEN 
				LET glob_unpos_cheques = 0 
			END IF 

			LET glob_unpos_cheques = 0 - glob_unpos_cheques + 0 

			PRINT "Less unposted cheques", 
			COLUMN 95, glob_unpos_cheques USING "------,---,---.##" 



			# now get the unposted cash receipts

			SELECT sum(cash_amt / conv_qty) 
			INTO glob_unpos_cash 
			FROM cashreceipt 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cash_acct_code = p_rec_rr_bank.acct_code 
			AND posted_flag = "N" 

			IF glob_unpos_cash IS NULL THEN 
				LET glob_unpos_cash = 0 
			END IF 

			PRINT "Plus unposted deposits", 
			COLUMN 95, glob_unpos_cash USING "------,---,---.##" 

						{        # now get the unposted membership receipts
						        LET glob_unpos_members = 0

						        SELECT sum(rec_amt)
						           INTO glob_unpos_members
						           FROM bm_contrechead
						           WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
						         AND bank_code = p_rec_rr_bank.bank_code
						         AND banked_flag = "Y"
						         AND posted_flag = "N"

						        IF glob_unpos_members IS NULL THEN
						            LET glob_unpos_members = 0
						        END IF

						        PRINT "Plus unposted members deposits",
						           COLUMN 95, glob_unpos_members using "------,---,---.##" }

			# now get the unposted journals

			LET glob_unpos_jour = 0 

			SELECT sum(batchdetl.debit_amt - batchdetl.credit_amt) 
			INTO glob_unpos_jour 
			FROM batchdetl, batchhead 
			WHERE batchhead.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND batchhead.post_flag = "N" 
			AND batchhead.cmpy_code = batchdetl.cmpy_code 
			AND batchdetl.acct_code = p_rec_rr_bank.acct_code 
			AND batchdetl.jour_num = batchhead.jour_num 
			AND batchdetl.jour_code = batchhead.jour_code 

			IF glob_unpos_jour IS NULL THEN 
				LET glob_unpos_jour = 0 
			END IF 

			PRINT "Plus unposted batches(net)" , 
			COLUMN 95, glob_unpos_jour USING "------,---,---.##" 

			PRINT COLUMN 95 , "-----------------------------------" 
			LET p_rr_bal_amt = p_rr_bal_amt + 
			glob_unpos_cheques + 
			glob_unpos_cash + 
			glob_unpos_jour 
			#+ glob_unpos_members

			PRINT "General Ledger Current balance"; 
			IF p_rr_bal_amt >= 0 THEN 
				PRINT COLUMN 112, p_rr_bal_amt USING "######,###,##&.&& dr" 
			ELSE 
				PRINT COLUMN 94, p_rr_bal_amt USING "######,###,##&.&& cr" 
			END IF 


			#need TO SET up some REPORT info.
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100
				PRINT "Bank : ", glob_rec_bank.bank_code," ",	glob_rec_bank.acct_name_text 
				PRINT "Bank Account code : ", glob_rec_bank.acct_code 
				PRINT "Bank Currency : ", glob_rec_bank.currency_code 
				 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	
			
			PRINT 
			PRINT 
			IF l_rv_show_caveat THEN 
				PRINT 
				PRINT "Note: In some instances the link TO the originating item "; 
				PRINT " was NOT possible." 
				PRINT "In these cases the conversion took place AT the daily rate"; 
				PRINT " AND as such may NOT equal the actual conversion in the gl" 
				PRINT "Such lines are denoted by asterix" 
				PRINT 
				PRINT 
			END IF 


END REPORT 





############################################################
# FUNCTION reset_nulls()
#
#
############################################################
FUNCTION reset_nulls() 


	IF glob_rec_recon.re_debit IS NULL THEN 
		LET glob_rec_recon.re_debit = 0 
	END IF 
	IF glob_rec_recon.re_cred IS NULL THEN 
		LET glob_rec_recon.re_cred = 0 
	END IF 
	IF glob_rec_recon.re_dep_num IS NULL THEN 
		LET glob_rec_recon.re_dep_num = 0 
	END IF 
	IF glob_rec_recon.re_bs_debit IS NULL THEN 
		LET glob_rec_recon.re_bs_debit = 0 
	END IF 
	IF glob_rec_recon.re_bs_cred IS NULL THEN 
		LET glob_rec_recon.re_bs_cred = 0 
	END IF 


END FUNCTION 
