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
GLOBALS "../ar/AW_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/AW4_GLOBALS.4gl" 
############################################################
# Module Scope Variables
############################################################
--DEFINE modu_rec_arparmext RECORD LIKE arparmext.* 
DEFINE modu_rec_tentarbal RECORD LIKE tentarbal.* 
DEFINE modu_rec_coa RECORD LIKE coa.* 
DEFINE modu_rec_invoicedetl RECORD LIKE invoicedetl.* 
DEFINE modu_rec_credreas RECORD LIKE credreas.* 
--DEFINE modu_query_text CHAR(300) 
######################################################################################
# FUNCTION AW4_main()
#
#   - Program AW4  - generates appropriate transactions TO write off
#                    customer balances
######################################################################################
FUNCTION AW4_main() 
	DEFINE l_continue CHAR(1) 

	DEFER quit 
	DEFER interrupt
	
	CALL setModuleId("AW4") 


			OPEN WINDOW A661 with FORM "A661" 
			CALL windecoration_a("A661") 
		
			MENU " Customer Write Off " 
		
				BEFORE MENU 
					CALL publish_toolbar("kandoo","AW4","menu-customer-balance") 
					CALL set_default_settings() 
					CALL AW4_rpt_process(AW4_rpt_query())
		
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
					
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				COMMAND "Generate" " Generate Customer Write Off Transactions" 
					CALL set_default_settings() 
					CALL AW4_rpt_process(AW4_rpt_query())
		
				ON ACTION "Print Manager"		#COMMAND KEY ("P",f11) "Print" " Print Customer Write Off Report using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "CANCEL" #COMMAND KEY(interrupt,"E")"Exit" " EXIT PROGRAM" 
					EXIT MENU 
		
		
			END MENU 
		
			CLOSE WINDOW A661 

END FUNCTION 


######################################################################################
# FUNCTION set_default_settings()
#
#
######################################################################################
FUNCTION set_default_settings() 

	LET glob_rec_invoicehead.inv_date = today 
	LET modu_rec_invoicedetl.line_text = "Write Off Customer Balance" 
	LET modu_rec_invoicedetl.line_acct_code = glob_rec_arparmext.writeoff_acct_code 

	CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,today) 
	RETURNING glob_rec_invoicehead.year_num, glob_rec_invoicehead.period_num 
	
	SELECT * INTO modu_rec_coa.* FROM coa 
	WHERE acct_code = modu_rec_invoicedetl.line_acct_code 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	
	SELECT reason_code INTO modu_rec_credreas.reason_code FROM arparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parm_code = "1" 
	
	SELECT reason_text INTO modu_rec_credreas.reason_text FROM credreas 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND reason_code = modu_rec_credreas.reason_code 
	
	IF status = NOTFOUND THEN 
		LET modu_rec_credreas.reason_text = "" 
	END IF 
	
	DISPLAY glob_rec_invoicehead.inv_date TO inv_date 
	DISPLAY glob_rec_invoicehead.year_num TO year_num
	DISPLAY glob_rec_invoicehead.period_num TO period_num
	DISPLAY modu_rec_invoicedetl.line_text TO line_text
	DISPLAY modu_rec_invoicedetl.line_acct_code TO line_acct_code
	DISPLAY modu_rec_coa.desc_text TO desc_text
	DISPLAY modu_rec_credreas.reason_code TO reason_code
	DISPLAY modu_rec_credreas.reason_text TO reason_text

END FUNCTION 



######################################################################################
# FUNCTION AW4_rpt_query() 
#
#
######################################################################################
FUNCTION AW4_rpt_query() 
	DEFINE l_failed_it SMALLINT 
	DEFINE l_save_date LIKE invoicehead.inv_date 
	DEFINE l_msgresp LIKE language.yes_flag 

	MESSAGE kandoomsg2("A",1080,"") 

	#1080 Enter Write Off Generation Details;  OK TO Continue.
	INPUT glob_rec_invoicehead.inv_date, 
	modu_rec_invoicedetl.line_text, 
	modu_rec_invoicedetl.line_acct_code, 
	glob_rec_invoicehead.com1_text, 
	glob_rec_invoicehead.com2_text, 
	modu_rec_credreas.reason_code, 
	glob_rec_invoicehead.year_num, 
	glob_rec_invoicehead.period_num WITHOUT DEFAULTS 
	FROM
	inv_date, 
	line_text, 
	line_acct_code, 
	com1_text, 
	com2_text, 
	reason_code, 
	year_num, 
	period_num	

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","AW4","inp-write_off") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
			
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield(line_acct_code) 
					LET glob_temp_text = show_acct(glob_rec_kandoouser.cmpy_code) 
					IF glob_temp_text IS NOT NULL THEN 
						LET modu_rec_invoicedetl.line_acct_code = glob_temp_text 
						DISPLAY BY NAME modu_rec_invoicedetl.line_acct_code 

					END IF 
					NEXT FIELD line_acct_code 
					
		ON ACTION "LOOKUP" infield(reason_code) 
					#FUNCTION show_credreas(p_cmpy,p_filter_where2_text,p_def_reason_code) 
					LET glob_temp_text = show_credreas(glob_rec_kandoouser.cmpy_code,NULL,modu_rec_credreas.reason_code) 
					IF glob_temp_text IS NOT NULL THEN 
						LET modu_rec_credreas.reason_code = glob_temp_text 
					END IF 
					NEXT FIELD reason_code 

			
		BEFORE FIELD inv_date 
			LET l_save_date = glob_rec_invoicehead.inv_date 
			
		AFTER FIELD inv_date 
			IF glob_rec_invoicehead.inv_date IS NULL THEN 
				LET glob_rec_invoicehead.inv_date = today 
				NEXT FIELD inv_date 
			END IF 
			IF l_save_date != glob_rec_invoicehead.inv_date THEN 
				CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,glob_rec_invoicehead.inv_date) 
				RETURNING glob_rec_invoicehead.year_num, 
				glob_rec_invoicehead.period_num 
				DISPLAY BY NAME glob_rec_invoicehead.year_num, 
				glob_rec_invoicehead.period_num 
			END IF 
			
		AFTER FIELD line_text 
			IF modu_rec_invoicedetl.line_text IS NULL THEN 
				ERROR kandoomsg2("A",9212,"") 
				#9212 Description must be entered.
				LET modu_rec_invoicedetl.line_text = "Write Off Customer Balance" 
				NEXT FIELD line_text 
			END IF 
			
		AFTER FIELD line_acct_code 
			SELECT * INTO modu_rec_coa.* FROM coa 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND acct_code = modu_rec_invoicedetl.line_acct_code 
			IF status = NOTFOUND THEN 
				ERROR kandoomsg2("A",9307,"") 
				#9307" Write Off GL Account NOT found;  Try Window.
				NEXT FIELD int_acct_code 
			END IF 
			IF NOT acct_type(glob_rec_kandoouser.cmpy_code,modu_rec_invoicedetl.line_acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"") THEN 
				NEXT FIELD line_acct_code 
			END IF 
			DISPLAY BY NAME modu_rec_coa.desc_text 

		AFTER FIELD reason_code 
			IF modu_rec_credreas.reason_code IS NULL 
			OR modu_rec_credreas.reason_code = " " THEN 
				LET l_msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered.
				NEXT FIELD reason_code 
			END IF 
			SELECT reason_text INTO modu_rec_credreas.reason_text FROM credreas 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND reason_code = modu_rec_credreas.reason_code 
			IF status = NOTFOUND THEN 
				ERROR kandoomsg2("A",9058,"") 
				#9058 Credit reason do NOT exist.
				NEXT FIELD reason_code 
			END IF 
			DISPLAY BY NAME modu_rec_credreas.reason_text 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				IF modu_rec_credreas.reason_code IS NULL 
				OR modu_rec_credreas.reason_code = " " THEN 
					LET l_msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered.
					NEXT FIELD reason_code 
				END IF 

				CALL valid_period(
					glob_rec_kandoouser.cmpy_code, 
					glob_rec_invoicehead.year_num, 
					glob_rec_invoicehead.period_num, LEDGER_TYPE_AR) 
				RETURNING 
					glob_rec_invoicehead.year_num, 
					glob_rec_invoicehead.period_num, 
					l_failed_it 

				IF l_failed_it = 1 THEN 
					NEXT FIELD year_num 
				END IF 

				SELECT * INTO modu_rec_coa.* FROM coa 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND acct_code = modu_rec_invoicedetl.line_acct_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("A",9307,"") 
					#9307 Service Fee Income GL Account NOT found;  Try Window.
					NEXT FIELD line_acct_code 
				END IF 

				IF NOT acct_type(glob_rec_kandoouser.cmpy_code,modu_rec_invoicedetl.line_acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"Y") THEN 
					NEXT FIELD line_acct_code 
				END IF 
			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL
	ELSE
	LET glob_rec_rpt_selector.ref1_date = glob_rec_invoicehead.inv_date 
	
	LET glob_rec_rpt_selector.ref2_text = modu_rec_invoicedetl.line_text
	LET glob_rec_rpt_selector.ref3_text = glob_rec_invoicehead.com1_text 
	LET glob_rec_rpt_selector.ref4_text = glob_rec_invoicehead.com2_text 

	LET glob_rec_rpt_selector.ref1_code = modu_rec_invoicedetl.line_acct_code 
	LET glob_rec_rpt_selector.ref2_code = modu_rec_credreas.reason_code 

	LET glob_rec_rpt_selector.ref1_num = glob_rec_invoicehead.year_num 
	LET glob_rec_rpt_selector.ref2_num = glob_rec_invoicehead.period_num
	
		RETURN " 1=1 " #we have no construct.. any value would ok
	END IF 
END FUNCTION 


######################################################################################
# FUNCTION AW4_rpt_process()
#
#
######################################################################################
FUNCTION AW4_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT  
	
	DEFINE l_trans_num INTEGER 
	DEFINE l_message CHAR(30) 
	DEFINE l_err_cnt SMALLINT 
	DEFINE l_reason_code CHAR(3) 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_customer RECORD LIKE customer.*

	IF promptTF("",kandoomsg2("A",8027,""),1) THEN
		SELECT unique 1 FROM tentarbal 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		IF status = NOTFOUND THEN 
			CALL fgl_winmessage("No Tentative Balances TO adjust",kandoomsg2("A",7083,""),"INFO") 
			#7083 There Are No Tentative Balances TO adjust.
			RETURN FALSE 
		END IF 
	END IF 


	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"AW4_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT AW4_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AW4_rpt_list")].sel_text
	#------------------------------------------------------------

	#Read rmsreps variables
	LET glob_rec_invoicehead.inv_date = glob_rec_rpt_selector.ref1_date 
	LET modu_rec_invoicedetl.line_text = glob_rec_rpt_selector.ref2_text
	LET glob_rec_invoicehead.com1_text = glob_rec_rpt_selector.ref3_text 
	LET glob_rec_invoicehead.com2_text = glob_rec_rpt_selector.ref4_text 
	LET modu_rec_invoicedetl.line_acct_code = glob_rec_rpt_selector.ref1_code 
	LET modu_rec_credreas.reason_code = glob_rec_rpt_selector.ref2_code
	LET glob_rec_invoicehead.year_num = glob_rec_rpt_selector.ref1_num 
	LET glob_rec_invoicehead.period_num = glob_rec_rpt_selector.ref2_num 

	LET l_err_cnt = 0

	LET l_query_text = "SELECT * FROM tentarbal,customer ", 
	"WHERE tentarbal.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND customer.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND customer.cust_code = tentarbal.cust_code "
	 
	IF glob_rec_arparms.report_ord_flag = "C" THEN 
		LET l_query_text = l_query_text clipped," ORDER BY currency_code,", 
		"tentarbal.cust_code" 
	ELSE 
		LET l_query_text = l_query_text clipped," ORDER BY currency_code,", 
		"customer.name_text,", 
		"tentarbal.cust_code" 
	END IF 

	PREPARE s_tentarbal FROM l_query_text 
	DECLARE c_tentarbal CURSOR with HOLD FOR s_tentarbal 		 

	FOREACH c_tentarbal INTO modu_rec_tentarbal.*,l_rec_customer.* 
		--MESSAGE modu_rec_tentarbal.cust_code," ",l_rec_customer.name_text  attribute(yellow) 
		LET glob_rec_invoicehead.cust_code = modu_rec_tentarbal.cust_code 
		LET glob_rec_invoicehead.sale_code = l_rec_customer.sale_code 
		LET glob_rec_invoicehead.tax_code = l_rec_customer.tax_code 
		LET glob_rec_invoicehead.term_code = l_rec_customer.term_code 

		IF modu_rec_tentarbal.credit_amt != 0 THEN 
			LET modu_rec_invoicedetl.unit_sale_amt = modu_rec_tentarbal.credit_amt 
			LET modu_rec_invoicedetl.unit_tax_amt = 0 
			LET l_trans_num = A2A_create_invoice(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,glob_rec_invoicehead.*,modu_rec_invoicedetl.*)
			 
			IF l_trans_num IS NOT NULL THEN 
				DELETE FROM tentarbal 
				WHERE cmpy_code = modu_rec_tentarbal.cmpy_code 
				AND cust_code = modu_rec_tentarbal.cust_code 
				IF NOT auto_invoice_pay(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,l_trans_num) THEN 
					LET l_message = l_trans_num," has NOT been fully applied" 
				END IF 

				#---------------------------------------------------------
				OUTPUT TO REPORT AW4_rpt_list(l_rpt_idx,
				modu_rec_tentarbal.*,l_rec_customer.*,l_trans_num,TRAN_TYPE_INVOICE_IN,l_message)
				IF NOT rpt_int_flag_handler2("Customer:",l_rec_customer.cust_code, NULL,l_rpt_idx) THEN
					EXIT FOREACH 
				END IF 
				#---------------------------------------------------------	
			ELSE 
				LET l_err_cnt = true 
				EXIT FOREACH 
			END IF 
		END IF 
		
		IF modu_rec_tentarbal.debit_amt != 0 THEN 
			LET modu_rec_invoicedetl.unit_sale_amt = modu_rec_tentarbal.debit_amt * -1 
			LET modu_rec_invoicedetl.unit_tax_amt = 0 
			LET l_trans_num = create_credit(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,glob_rec_invoicehead.*,modu_rec_invoicedetl.*,modu_rec_credreas.reason_code) 
			IF l_trans_num IS NOT NULL THEN 
				DELETE FROM tentarbal 
				WHERE cmpy_code = modu_rec_tentarbal.cmpy_code 
				AND cust_code = modu_rec_tentarbal.cust_code 
				IF auto_credit_apply(glob_rec_kandoouser.sign_on_code,l_trans_num,"") THEN 
					LET l_message = "" 
				ELSE 
					LET l_message = "credit note apply error" 
				END IF 

				#---------------------------------------------------------
				OUTPUT TO REPORT AW4_rpt_list(l_rpt_idx,
				modu_rec_tentarbal.*,l_rec_customer.*,l_trans_num,TRAN_TYPE_CREDIT_CR,l_message)
				IF NOT rpt_int_flag_handler2("Customer:",l_rec_customer.cust_code, NULL,l_rpt_idx) THEN
					EXIT FOREACH 
				END IF 
				#---------------------------------------------------------				
				 
			ELSE 
				LET l_err_cnt = true 
				EXIT FOREACH 
			END IF 
		END IF 
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT AW4_rpt_list
	CALL rpt_finish("AW4_rpt_list")
	#------------------------------------------------------------
	  
	UPDATE arparmext 
	SET last_writeoff_date = glob_rec_invoicehead.inv_date 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF l_err_cnt THEN 
		ERROR kandoomsg2("A",7081,l_err_cnt) 
		#7078 Tentative Balance Write Off Did Not Complete Successfully.
	ELSE 
		ERROR kandoomsg2("A",7079,l_err_cnt) 
		#7079 Customer Balance Write Off Completed Successfully.
	END IF 

	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
	
END FUNCTION 


######################################################################################
# REPORT AW4_rpt_list(p_rec_tentarbal,p_rec_customer,p_trans_num,p_adj_type,p_message)
# ADJ_SUMMARY
#
######################################################################################
REPORT AW4_rpt_list(p_rpt_idx,p_rec_tentarbal,p_rec_customer,p_trans_num,p_adj_type,p_message) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE p_rec_tentarbal RECORD LIKE tentarbal.* 
	DEFINE p_rec_customer RECORD LIKE customer.* 
	DEFINE p_trans_num INTEGER 
	DEFINE p_adj_type CHAR(2) 
	DEFINE p_message CHAR(30) 	
	DEFINE l_rec_currency RECORD LIKE currency.*	 
	DEFINE l_name_text CHAR(30) 
	DEFINE l_line1 CHAR(80) 
	DEFINE l_offset1 SMALLINT 
	DEFINE l_offset2 SMALLINT 

	OUTPUT 
--	PAGE length 66 
--	left margin 0 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 			 
			PRINT COLUMN 1,"Customer", 
			COLUMN 11,"Name", 
			COLUMN 55,"Adjustment", 
			COLUMN 68,"Trans", 
			COLUMN 100 ,"Credit", 
			COLUMN 120,"Debit" 
			PRINT COLUMN 56,"Type", 
			COLUMN 68,"Number" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		ON EVERY ROW 
			SELECT customer.name_text INTO l_name_text FROM customer 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cust_code = p_rec_tentarbal.cust_code 
			PRINT COLUMN 1,p_rec_tentarbal.cust_code, 
			COLUMN 11,l_name_text, 
			COLUMN 56,p_adj_type, 
			COLUMN 66,p_trans_num USING "#######&", 
			COLUMN 92,p_rec_tentarbal.debit_amt USING "---,---,--&.&&", 
			COLUMN 111,p_rec_tentarbal.credit_amt USING "---,---,--&.&&" 
			IF p_message IS NOT NULL THEN 
				PRINT COLUMN 10,p_message 
			END IF 

		AFTER GROUP OF p_rec_customer.currency_code 
			NEED 3 LINES 
			SKIP 1 line 
			PRINT COLUMN 92,"=====",p_rec_customer.currency_code,"======", 
			COLUMN 111,"=====",p_rec_customer.currency_code,"======" 
			SELECT desc_text INTO l_rec_currency.desc_text FROM currency 
			WHERE currency_code = p_rec_customer.currency_code 
			PRINT COLUMN 1,"Currrency Total: ",p_rec_customer.currency_code, 
			COLUMN 22,l_rec_currency.desc_text, 
			COLUMN 92,group sum(p_rec_tentarbal.debit_amt) 
			USING "---,---,--&.&&", 
			COLUMN 111,group sum(p_rec_tentarbal.credit_amt) 
			USING "---,---,--&.&&" 
			SKIP 1 line 


		ON LAST ROW 
			NEED 2 LINES 
			SKIP 2 LINES 
			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			

END REPORT 