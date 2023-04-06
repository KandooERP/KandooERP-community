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

#	Source code beautified by beautify.pl on 2020-01-03 09:12:31	$Id: $

#KandooERP runs on Querix Lycia www.querix.com
#Adapted by eric@begooden.it,hoelzl@querix.com,a.bondar@querix.com

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "../ar/A_AR_GLOBALS.4gl"
GLOBALS "../ar/AS_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/AS6_GLOBALS.4gl" 
############################################################
# Module Scope Variables
############################################################
DEFINE modu_goforit CHAR(1) 
DEFINE modu_prntco CHAR(1) 
DEFINE modu_prntdun CHAR(1) 
DEFINE modu_update_it CHAR(1) 
DEFINE modu_bcust LIKE customer.cust_code 
DEFINE modu_ecust LIKE customer.cust_code 
DEFINE modu_zero_stat CHAR(1) 
DEFINE modu_statement_date DATE 

##############################################################
# FUNCTION AS6_main()
#
# brief module AS6 Statement Printing Program
##############################################################
FUNCTION AS6_main() 
	DEFER QUIT 
	DEFER INTERRUPT 
	
	CALL setModuleId("AS6") 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode
			OPEN WINDOW A951 WITH FORM "A951" 
			CALL windecoration_a("A951")
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title
			
			MENU "Print Statements" 

				BEFORE MENU 
					CALL publish_toolbar("kandoo","AS6","menu-PRINT-statements")
					CALL rpt_rmsreps_reset(NULL)
					CALL AS6_rpt_process(AS6_rpt_query())

				ON ACTION "WEB-HELP" -- albo kd-372 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar()

				ON ACTION "Report" #COMMAND "Run Report" " SELECT Criteria AND Print Report"
					CALL rpt_rmsreps_reset(NULL)
					CALL AS6_rpt_process(AS6_rpt_query())

				ON ACTION "PRINT MANAGER" --COMMAND "Print" "Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "CANCEL" --COMMAND KEY (interrupt, "E") "Exit" " Exit TO menus" 
					EXIT MENU

			END MENU
			CLOSE WINDOW A951

		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL AS6_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW A951 with FORM "A951" 
			CALL windecoration_a("A951") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(AS6_rpt_query()) #save where clause in env 
			CLOSE WINDOW A951 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL AS6_rpt_process(get_url_sel_text())
	END CASE	
	 
END FUNCTION 
##############################################################
# END FUNCTION AS6_main()
##############################################################


##############################################################
# FUNCTION AS6_rpt_query()
# only input NO construct l_where_text = NULL or "1=1"
#
##############################################################
FUNCTION AS6_rpt_query() 
	#init
	LET modu_statement_date = TODAY 
	LET modu_prntco = "N"
	LET modu_zero_stat = "N"
	LET modu_prntdun = "N"
	LET modu_bcust = NULL
	LET modu_ecust = NULL
	LET modu_update_it = "N"

	INPUT 
		modu_prntco, 
		modu_zero_stat, 
		modu_prntdun, 
		modu_bcust, 
		modu_ecust, 
		modu_statement_date, 
		modu_update_it WITHOUT DEFAULTS 
	FROM 
		prntco, 
		zero_stat, 
		prntdun, 
		bcust, 
		ecust, 
		statement_date, 
		update_it ATTRIBUTE(UNBUFFERED)
		
		AFTER FIELD bcust
			IF modu_bcust IS NULL THEN
				LET modu_bcust = "        "
			END IF

		AFTER FIELD ecust
			IF modu_ecust IS NULL THEN
				LET modu_ecust = "zzzzzzzz"
			END IF

		AFTER INPUT
			IF modu_bcust IS NULL THEN
				LET modu_bcust = "        "
			END IF
			IF modu_ecust IS NULL THEN
				LET modu_ecust = "zzzzzzzz"
			END IF

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN NULL
	ELSE 
		#For rmsreps
		LET glob_rec_rpt_selector.ref1_ind = modu_prntco #CHAR(1)
		LET glob_rec_rpt_selector.ref2_ind = modu_zero_stat #CHAR(1)
		LET glob_rec_rpt_selector.ref3_ind = modu_prntdun  #CHAR(1)
		LET glob_rec_rpt_selector.ref4_ind = modu_update_it #CHAR(1)
	
		LET glob_rec_rpt_selector.ref1_code = modu_bcust #LIKE customer.cust_code 
		LET glob_rec_rpt_selector.ref2_code = modu_ecust #LIKE customer.cust_code 
	
		LET glob_rec_rpt_selector.ref1_date = modu_statement_date #DATE

--		LET modu_goforit = "Y" -- (albo) 
		LET modu_goforit = "N" -- (albo) I don't understand why need to print the report twice
		LET modu_goforit = upshift(modu_goforit) 

		IF modu_goforit = "Y" THEN 
			RETURN AS6_rpt_process("1=1") 
		ELSE 
			MESSAGE " Statements NOT run " 
			RETURN FALSE 
		END IF 
	END IF 

END FUNCTION 
##############################################################
# END FUNCTION AS6_rpt_query()
##############################################################


##############################################################
# FUNCTION AS6_rpt_process(p_where_text) 
# p_where_text = NULL or "1=1" all required selector where parts are in glob_rec_rpt_selector / rmsreps
#
##############################################################
FUNCTION AS6_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT   
	DEFINE l_rec_invoicehead RECORD LIKE invoicehead.*
	DEFINE l_rec_credithead RECORD LIKE credithead.*
	DEFINE l_rec_cashreceipt RECORD LIKE cashreceipt.*
	DEFINE l_rec_doc RECORD 
		d_cust CHAR(8), 
		d_date DATE, 
		d_code CHAR(1), 
		d_ref INTEGER, 
		d_desc CHAR(17), 
		d_amt MONEY(12,2), 
		d_age INTEGER, 
		d_post CHAR(1), 
		d_bal MONEY(12,2) 
	END RECORD 
	DEFINE l_docs SMALLINT
	DEFINE l_late_pay1 MONEY(12,2) 
	DEFINE l_late_pay MONEY(12,2) 
	DEFINE l_late_dis1 MONEY(12,2)
	DEFINE l_late_dis MONEY(12,2)
	DEFINE l_sum_inv MONEY(12,2)
	DEFINE l_work_cust LIKE customer.cust_code
	DEFINE l_err_message CHAR(40)
	DEFINE l_row_id INTEGER
	DEFINE l_cnt INTEGER

	IF fgl_find_table("doctab") THEN
		DROP TABLE doctab 
	END IF 

	#------------------------------------------------------------
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"AS6_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	

	START REPORT AS6_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	#FROM rmsreps
	LET modu_prntco = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref1_ind  #CHAR(1)
	LET modu_zero_stat = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref2_ind  #CHAR(1)
	LET modu_prntdun = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref3_ind   #CHAR(1)
	LET modu_update_it = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref4_ind  #CHAR(1)
	
	LET modu_bcust= glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref1_code  #LIKE customer.cust_code 
	LET modu_ecust = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref2_code  #LIKE customer.cust_code 
	
	LET modu_statement_date = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref1_date  #DATE

	LET l_err_message = "AS6 - invoicehead UPDATE" 

	BEGIN WORK 

		LOCK TABLE cashreceipt in share MODE 
		LOCK TABLE invoicehead in share MODE 
		LOCK TABLE credithead in share MODE 

		CREATE temp TABLE doctab (d_cust CHAR(8), 
		d_date DATE, 
		d_code CHAR(1), 
		d_ref INTEGER, 
		d_desc CHAR(17), 
		d_amt MONEY(12,2), 
		d_age INTEGER, 
		d_post CHAR(1), 
		d_bal MONEY(12,2)) with no LOG 

		DECLARE invcurs CURSOR FOR 
		SELECT invoicehead.rowid, invoicehead.* 
		FROM invoicehead 
		WHERE invoicehead.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND invoicehead.cust_code >= modu_bcust 
		AND invoicehead.cust_code <= modu_ecust 
		AND invoicehead.inv_date <= modu_statement_date 
		AND (invoicehead.total_amt <> invoicehead.paid_amt OR invoicehead.on_state_flag <> "Y" 
		OR invoicehead.paid_date IS NOT NULL AND invoicehead.paid_date > modu_statement_date) 

		FOREACH invcurs INTO l_row_id, l_rec_invoicehead.* 

			LET l_err_message = "AS6 - customer lookup" 

			SELECT COUNT(*) 
			INTO l_cnt 
			FROM customer 
			WHERE customer.cust_code = l_rec_invoicehead.cust_code 
			AND customer.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND customer.stmnt_ind != "N" 

			IF l_cnt <> 0 THEN
				# In the CASE of a late payment being included in the paid_amt
				# figure subtract this payment FROM the paid_amt....
				# need TO look AT original document
				LET l_err_message = "AS6 - late payment lookup" 

				SELECT SUM(invoicepay.pay_amt), SUM(invoicepay.disc_amt) 
				INTO l_late_pay, l_late_dis 
				FROM invoicepay, credithead 
				WHERE invoicepay.cmpy_code = l_rec_invoicehead.cmpy_code 
				AND invoicepay.cust_code = l_rec_invoicehead.cust_code 
				AND invoicepay.inv_num = l_rec_invoicehead.inv_num 
				AND invoicepay.pay_type_ind = TRAN_TYPE_CREDIT_CR 
				AND credithead.cmpy_code = l_rec_invoicehead.cmpy_code 
				AND credithead.cred_num = invoicepay.ref_num 
				AND credithead.cust_code = l_rec_invoicehead.cust_code 
				AND credithead.cred_date > modu_statement_date 

				SELECT SUM(invoicepay.pay_amt), SUM(invoicepay.disc_amt) 
				INTO l_late_pay1, l_late_dis1 
				FROM invoicepay, cashreceipt 
				WHERE invoicepay.cmpy_code = l_rec_invoicehead.cmpy_code 
				AND invoicepay.cust_code = l_rec_invoicehead.cust_code 
				AND invoicepay.inv_num = l_rec_invoicehead.inv_num 
				AND invoicepay.pay_type_ind = TRAN_TYPE_RECEIPT_CA 
				AND cashreceipt.cmpy_code = l_rec_invoicehead.cmpy_code 
				AND cashreceipt.cash_num = invoicepay.ref_num 
				AND cashreceipt.cust_code = l_rec_invoicehead.cust_code 
				AND cashreceipt.cash_date > modu_statement_date 

				IF l_late_pay IS NULL THEN LET l_late_pay = 0 END IF 
				IF l_late_dis IS NULL THEN LET l_late_dis = 0 END IF 
				IF l_late_pay1 IS NULL THEN LET l_late_pay1 = 0 END IF 
				IF l_late_dis1 IS NULL THEN LET l_late_dis1 = 0 END IF 

				LET l_late_pay = l_late_pay + l_late_pay1 
				LET l_late_dis = l_late_dis + l_late_dis1 

				MESSAGE "Invoice: ", l_rec_invoicehead.inv_num 

				LET l_docs = l_docs + 1 
				LET l_rec_doc.d_cust = l_rec_invoicehead.cust_code 
				LET l_rec_doc.d_date = l_rec_invoicehead.inv_date 
				LET l_rec_doc.d_code = "I" 
				LET l_rec_doc.d_ref = l_rec_invoicehead.inv_num 
				LET l_rec_doc.d_desc = "Invoice" 
				LET l_rec_doc.d_amt = l_rec_invoicehead.total_amt 
				LET l_rec_doc.d_age = modu_statement_date - l_rec_invoicehead.due_date 
				LET l_rec_doc.d_bal = l_rec_invoicehead.total_amt 
					- l_rec_invoicehead.paid_amt 
					- (l_late_pay + l_late_dis) 
				LET l_rec_doc.d_post = l_rec_invoicehead.posted_flag
								 
				IF l_rec_invoicehead.on_state_flag <> "Y"	AND modu_update_it = "Y" THEN 
					LET l_rec_invoicehead.on_state_flag = "Y" 
					UPDATE invoicehead SET on_state_flag = l_rec_invoicehead.on_state_flag 
					WHERE rowid = l_row_id 
				END IF 

				LET l_err_message = "AS6 - doctab INSERT" 
				INSERT INTO doctab VALUES (l_rec_doc.*) 
				LET l_late_pay = 0 
				LET l_late_dis = 0 
			END IF 

		END FOREACH 

		LET l_err_message = "AS6 - Credhead UPDATE" 
		DECLARE credcurs CURSOR FOR 
		SELECT credithead.rowid, credithead.* 
		FROM credithead 
		WHERE credithead.cred_date <= modu_statement_date 
		AND credithead.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND credithead.cust_code >= modu_bcust 
		AND credithead.cust_code <= modu_ecust 
		AND (credithead.total_amt <> credithead.appl_amt OR credithead.on_state_flag <> "Y") 

		FOREACH credcurs INTO l_row_id, l_rec_credithead.* 

			SELECT COUNT(*) 
			INTO l_cnt 
			FROM customer 
			WHERE customer.cust_code = l_rec_credithead.cust_code 
			AND customer.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND customer.stmnt_ind != "N" 

			IF l_cnt <> 0 THEN
				LET l_docs = l_docs + 1 
				LET l_rec_doc.d_cust = l_rec_credithead.cust_code 
				LET l_rec_doc.d_ref = l_rec_credithead.cred_num 
				LET l_rec_doc.d_date = l_rec_credithead.cred_date 
				LET l_rec_doc.d_code = "C" 
				LET l_rec_doc.d_desc = "Credit" 
				LET l_rec_doc.d_amt = l_rec_credithead.total_amt 
				LET l_rec_doc.d_age = modu_statement_date - l_rec_credithead.cred_date 
				LET l_rec_doc.d_bal = l_rec_credithead.appl_amt - l_rec_credithead.total_amt 
				LET l_rec_doc.d_post = l_rec_credithead.posted_flag 
							
				IF l_rec_credithead.on_state_flag <> "Y"	AND modu_update_it = "Y" THEN 
					LET l_rec_credithead.on_state_flag = "Y" 
					UPDATE credithead SET on_state_flag = l_rec_credithead.on_state_flag 
					WHERE rowid = l_row_id 
				END IF 

				LET l_err_message = "AS6 - doctab INSERT" 
				INSERT INTO doctab VALUES (l_rec_doc.*) 
			END IF 

		END FOREACH 

		LET l_err_message = "AS6 - Cash receipt UPDATE" 
		DECLARE cashcurs CURSOR FOR 
		SELECT cashreceipt.rowid, cashreceipt.* 
		FROM cashreceipt 
		WHERE cashreceipt.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cashreceipt.cust_code >= modu_bcust 
		AND cashreceipt.cust_code <= modu_ecust 
		AND cashreceipt.cash_date <= modu_statement_date 
		AND (cashreceipt.cash_amt <> cashreceipt.applied_amt OR cashreceipt.on_state_flag <> "Y") 

		FOREACH cashcurs INTO l_row_id, l_rec_cashreceipt.* 

			SELECT COUNT(*) 
			INTO l_cnt 
			FROM customer 
			WHERE customer.cust_code = l_rec_cashreceipt.cust_code 
			AND customer.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND customer.stmnt_ind != "N" 

			IF l_cnt <> 0 THEN 
				# In the CASE of a late invoice being included in the applied_amt
				# figure subtract this payment FROM the applied_amt ....

				SELECT SUM(p.pay_amt), SUM(p.disc_amt) 
				INTO l_late_pay, l_late_dis 
				FROM invoicepay p,invoicehead i 
				WHERE p.cmpy_code = l_rec_cashreceipt.cmpy_code 
				AND p.cust_code = l_rec_cashreceipt.cust_code 
				AND p.ref_num = l_rec_cashreceipt.cash_num 
				AND p.cmpy_code = i.cmpy_code 
				AND p.cust_code = i.cust_code 
				AND p.inv_num = i.inv_num 
				AND i.inv_date > modu_statement_date 

				IF l_late_pay IS NULL THEN LET l_late_pay = 0 END IF 
				IF l_late_dis IS NULL THEN LET l_late_dis = 0 END IF 

				MESSAGE " Receipts: ", l_rec_cashreceipt.cash_num 

				LET l_docs = l_docs + 1 
				LET l_rec_doc.d_cust = l_rec_cashreceipt.cust_code 
				LET l_rec_doc.d_date = l_rec_cashreceipt.cash_date 
				LET l_rec_doc.d_code = "P" 
				LET l_rec_doc.d_ref = l_rec_cashreceipt.cash_num 
				LET l_rec_doc.d_desc = "Payment" 
				LET l_rec_doc.d_amt = l_rec_cashreceipt.cash_amt 
				LET l_rec_doc.d_age = modu_statement_date - l_rec_cashreceipt.cash_date 
				LET l_rec_doc.d_bal = l_rec_cashreceipt.applied_amt 
					- l_rec_cashreceipt.cash_amt 
					- l_late_pay - l_late_dis 
				LET l_rec_doc.d_post = l_rec_cashreceipt.posted_flag 
										
				IF l_rec_cashreceipt.on_state_flag <> "Y" AND modu_update_it = "Y" THEN 
					LET l_rec_cashreceipt.on_state_flag = "Y" 

						# UPDATE -------------------------
					UPDATE cashreceipt SET on_state_flag = l_rec_cashreceipt.on_state_flag 
					WHERE rowid = l_row_id 

				END IF 

				LET l_err_message = "AS6 - doctab INSERT" 
				INSERT INTO doctab VALUES (l_rec_doc.*) 
			END IF 
		END FOREACH 

	COMMIT WORK 

	#
	# do NOT PRINT zero value statements IF requested
	#

	IF modu_zero_stat = "N"	THEN 
		DECLARE zercurs CURSOR FOR 
		SELECT UNIQUE doctab.d_cust 
		FROM doctab 
		ORDER BY doctab.d_cust 

		FOREACH zercurs INTO l_work_cust 

			# now get the sum of the invoices AND payments AND credits
			SELECT SUM(doctab.d_bal) 
			INTO l_sum_inv 
			FROM doctab 
			WHERE doctab.d_cust = l_work_cust 

			# next IF the sum outstanding = 0 THEN we have a zero value statement
			# so delete all these customer details off

			IF l_sum_inv = 0 THEN 
				MESSAGE " Zero Value Customer: ", l_work_cust 
				DELETE FROM doctab 
				WHERE d_cust = l_work_cust 
			END IF 

		END FOREACH 
	END IF 

	DECLARE doccurs CURSOR FOR 
	SELECT * 
	FROM doctab 
	ORDER BY doctab.d_cust, doctab.d_date 

	FOREACH doccurs INTO l_rec_doc.* 
		#---------------------------------------------------------
		OUTPUT TO REPORT AS6_rpt_list(l_rpt_idx, l_rec_doc.*, modu_prntco, modu_statement_date, modu_prntdun, glob_rec_kandoouser.cmpy_code)
		IF NOT rpt_int_flag_handler2("Document:",l_rec_doc.d_ref, NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT AS6_rpt_list
	RETURN rpt_finish("AS6_rpt_list")
	#------------------------------------------------------------

END FUNCTION 
##############################################################
# END FUNCTION AS6_rpt_process(p_where_text) 
##############################################################
