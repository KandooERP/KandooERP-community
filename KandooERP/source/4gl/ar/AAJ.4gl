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
GLOBALS "../ar/A_AR_GLOBALS.4gl"
GLOBALS "../ar/AA_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/AAJ_GLOBALS.4gl"
############################################################
# MODULE Scope Variables
############################################################
DEFINE modu_rec_criteria RECORD 
	order_ind CHAR(1), 
	age_date DATE 
END RECORD 
DEFINE modu_curr_date DATE 
DEFINE modu_temp_text VARCHAR(200)	
#####################################################################
# FUNCTION AAJ_main()
# Detailed Account Aging
#           Page Break on Salesperson
#           Report Order Dynamic
#           Aging Date IS as entered
#####################################################################
FUNCTION AAJ_main()
--	LET modu_curr_date = today 

	IF NOT fgl_find_table("t_document") THEN	
		CREATE temp TABLE t_document (cust_code CHAR(8), 
		name_text CHAR(30), 
		hold_code CHAR(3), 
		type_code CHAR(3), 
		sale_code CHAR(8), 
		trans_type CHAR(2), 
		trans_num INTEGER, 
		trans_date DATE, 
		trans_ref CHAR(20), 
		days_num INTEGER, 
		curr_code CHAR(3), 
		conv_qty FLOAT, 
		total_amt money(12,2), 
		unpaid_amt money(12,2), 
		curr_amt money(12,2), 
		over1_amt money(12,2), 
		over30_amt money(12,2), 
		over60_amt money(12,2), 
		over90_amt money(12,2)) with no LOG 
	END IF
	
	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 
			OPEN WINDOW Aa622 with FORM "A622" 
			CALL windecoration_a("A622") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title

			DISPLAY glob_rec_arparms.cust_age_date TO cust_age_date
			DISPLAY modu_curr_date TO curr_date

			MENU " Detailed Aging (by salesperson)" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","AAJ","menu-detailed-aging-salesp")
					CALL rpt_rmsreps_reset(NULL) 
					CALL AAJ_rpt_process(AAJ_rpt_query())
					
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				ON ACTION "Report" 	#COMMAND "Run" " SELECT criteria AND PRINT REPORT"
					CALL rpt_rmsreps_reset(NULL)
					IF fgl_find_table("t_document") THEN
						DELETE FROM t_document WHERE "1=1"
					END IF					

					CALL AAJ_rpt_process(AAJ_rpt_query())

				ON ACTION "Print" #COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog ("URS","","","","") 

				ON ACTION "CANCEL" #COMMAND KEY(interrupt,"E")"Exit" " RETURN TO menus"
					EXIT MENU 


			END MENU 

			CLOSE WINDOW A622 

			
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL AAJ_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW A622 with FORM "A622" 
			CALL windecoration_a("A622") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(AAJ_rpt_query()) #save where clause in env 
			CLOSE WINDOW A622 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL AAJ_rpt_process(get_url_sel_text())
	END CASE 

	IF fgl_find_table("t_document") THEN
		DROP TABLE t_document
	END IF
	
END FUNCTION
#####################################################################
# END FUNCTION AAJ_main()
#####################################################################


#####################################################################
# FUNCTION AAJ_rpt_query()
#
#
#####################################################################
FUNCTION AAJ_rpt_query() 
	DEFINE l_where_text CHAR(500)
	DEFINE l_detail CHAR(1)
	DEFINE l_age_ind CHAR(1)
	DEFINE l_seq_no SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag
	
	CLEAR FORM 
	DISPLAY glob_rec_arparms.cust_age_date TO cust_age_date
	DISPLAY modu_curr_date TO curr_date

	LET l_detail = "D" 
	LET l_age_ind = "1" 
	LET modu_rec_criteria.order_ind = "1" 
	LET modu_rec_criteria.age_date = NULL 
	LET l_msgresp = kandoomsg("A",1034,"") 	#1034 Enter REPORT parameters - ESC TO Continue
	INPUT l_age_ind, 
		modu_rec_criteria.age_date, 
		modu_rec_criteria.order_ind, 
		l_detail WITHOUT DEFAULTS 
	FROM
		l_age_ind, 
		modu_rec_criteria.age_date, 
		modu_rec_criteria.order_ind, 
		l_detail	

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","AAJ","inp-rep-param") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER FIELD age_ind 
			CASE l_age_ind 
				WHEN "1" 
					LET modu_rec_criteria.age_date = glob_rec_arparms.cust_age_date 
				WHEN "2" 
					LET modu_rec_criteria.age_date = today 
				WHEN "3" 
					IF modu_rec_criteria.age_date IS NULL THEN 
						LET modu_rec_criteria.age_date = today 
					END IF 
			END CASE 
			LET l_seq_no = 1 

		BEFORE FIELD age_date 
			IF l_age_ind != "3" THEN 
				IF l_seq_no = 1 THEN 
					NEXT FIELD order_ind 
				ELSE 
					NEXT FIELD age_ind 
				END IF 
			END IF 

		AFTER FIELD order_ind 
			LET l_seq_no = 3 


	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 
	
	LET l_msgresp = kandoomsg("U",1001,"") 	#1001 Enter Selection Criteria - ESC TO Continue
	CONSTRUCT BY NAME l_where_text ON cust_code, 
	name_text, 
	addr1_text, 
	addr2_text, 
	city_text, 
	state_code, 
	post_code, 
	country_code, 
	country_text, 
	currency_code, 
	curr_amt, 
	over1_amt, 
	over30_amt, 
	over60_amt, 
	over90_amt, 
	bal_amt, 
	hold_code, 
	type_code, 
	sale_code, 
	territory_code, 
	contact_text, 
	tele_text, 
	mobile_phone,	
	fax_text,
	email 


		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","AAJ","construct-customer") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL
	END IF 

	LET glob_rec_rpt_selector.sel_text = l_where_text 
	LET glob_rec_rpt_selector.ref1_code = modu_rec_criteria.order_ind 
	LET glob_rec_rpt_selector.ref1_date = modu_rec_criteria.age_date 
	LET glob_rec_rpt_selector.ref2_code = l_detail 

	RETURN l_where_text
END FUNCTION 
#####################################################################
# END FUNCTION AAJ_rpt_query()
#####################################################################


#####################################################################
# FUNCTION AAJ_rpt_process()
#
#
#####################################################################
FUNCTION AAJ_rpt_process(p_where_text) 
	DEFINE p_where_text STRING
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE l_rec_document RECORD 
		cust_code LIKE customer.cust_code, 
		name_text LIKE customer.name_text, 
		hold_code LIKE customer.hold_code, 
		type_code LIKE customer.type_code, 
		sale_code LIKE customer.cust_code, 
		trans_type LIKE araudit.tran_type_ind, 
		trans_num LIKE invoicehead.inv_num, 
		trans_date LIKE invoicehead.inv_date, 
		trans_ref CHAR(20), 
		days_num INTEGER, 
		curr_code LIKE invoicehead.currency_code, 
		conv_qty LIKE invoicehead.conv_qty, 
		trans_amt LIKE invoicehead.total_amt, 
		unpaid_amt LIKE invoicehead.paid_amt, 
		curr_amt LIKE customer.curr_amt, 
		over1_amt LIKE customer.over1_amt, 
		over30_amt LIKE customer.over30_amt, 
		over60_amt LIKE customer.over60_amt, 
		over90_amt LIKE customer.over90_amt 
	END RECORD
	DEFINE l_rec_customer RECORD LIKE customer.*
	DEFINE l_rec_salesperson RECORD LIKE salesperson.*
	DEFINE l_rec_invoicehead RECORD LIKE invoicehead.*
	DEFINE l_rec_credithead RECORD LIKE credithead.*
	DEFINE l_rec_cashreceipt RECORD LIKE cashreceipt.*
	DEFINE l_query_text CHAR(800)
	DEFINE l_order_text CHAR(20)
	DEFINE l_detail CHAR(1) 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF
	
	LET l_rpt_idx = rpt_start(getmoduleid(),"AAJ_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT AAJ_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	
	LET modu_rec_criteria.order_ind = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AAA_rpt_list")].ref1_code 
	LET modu_rec_criteria.age_date = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AAA_rpt_list")].ref1_date 
	LET l_detail = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AAA_rpt_list")].ref2_code 
	CALL set_aging(glob_rec_kandoouser.cmpy_code,modu_rec_criteria.age_date) 

	CASE modu_rec_criteria.order_ind 
		WHEN "1" 
			LET l_order_text = "cust_code" 
		WHEN "2" 
			LET l_order_text = "name_text" 
		WHEN "3" 
			LET l_order_text = "post_code,cust_code" 
		WHEN "4" 
			LET l_order_text = "state_code,cust_code" 
	END CASE 

	LET l_query_text = "SELECT * FROM customer ", 
	"WHERE cmpy_code='",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND delete_flag='N' ", 
	"AND ",glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AAJ_rpt_list")].sel_text clipped," ", 
	"ORDER BY cmpy_code,sale_code,",l_order_text clipped 
	PREPARE s_customer FROM l_query_text 
	DECLARE c_customer CURSOR FOR s_customer 
	## program requires three cursors
	## 1. invoices
	LET l_query_text ="SELECT * FROM invoicehead ", 
	"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND cust_code = ? ", 
	"AND paid_amt != total_amt" 
	PREPARE s_invoice FROM l_query_text 
	DECLARE c_invoice CURSOR FOR s_invoice 
	## 2. credits
	LET l_query_text ="SELECT * FROM credithead ", 
	"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND cust_code = ? ", 
	"AND appl_amt != total_amt" 
	PREPARE s_credit FROM l_query_text 
	DECLARE c_credit CURSOR FOR s_credit 
	
	#-------------------
	# 3. cashreceipts
	#-------------------
	LET l_query_text =
		"SELECT * FROM cashreceipt ", 
		"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND cust_code = ? ", 
		"AND applied_amt != cash_amt" 
	
	PREPARE s_cash FROM l_query_text 
	DECLARE c_cash CURSOR FOR s_cash 

	FOREACH c_customer INTO l_rec_customer.* 

		#Get sales person
		CALL db_salesperson_get_rec(UI_OFF,l_rec_customer.sale_code) RETURNING l_rec_salesperson.*
		
		IF NOT rpt_int_flag_handler2("Salesperson:",l_rec_salesperson.sale_code,l_rec_salesperson.name_text,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF
		 
		DELETE FROM t_document WHERE 1=1 
		
		LET l_rec_document.cust_code = l_rec_customer.cust_code 
		LET l_rec_document.name_text = l_rec_customer.name_text 
		LET l_rec_document.hold_code = l_rec_customer.hold_code 
		LET l_rec_document.type_code = l_rec_customer.type_code 
		LET l_rec_document.sale_code = l_rec_customer.sale_code 
		
		OPEN c_invoice USING l_rec_customer.cust_code 

		FOREACH c_invoice INTO l_rec_invoicehead.* 
			LET l_rec_document.trans_type = TRAN_TYPE_INVOICE_IN 
			LET l_rec_document.trans_num = l_rec_invoicehead.inv_num 
			LET l_rec_document.trans_date = l_rec_invoicehead.inv_date 
			LET l_rec_document.trans_ref = l_rec_invoicehead.purchase_code 
			LET l_rec_document.days_num = get_age_bucket(TRAN_TYPE_INVOICE_IN,l_rec_invoicehead.due_date) 
			LET l_rec_document.curr_code = l_rec_invoicehead.currency_code 
			LET l_rec_document.conv_qty = l_rec_invoicehead.conv_qty 
			LET l_rec_document.trans_amt = l_rec_invoicehead.total_amt 
			LET l_rec_document.unpaid_amt = l_rec_invoicehead.total_amt - l_rec_invoicehead.paid_amt 
			INSERT INTO t_document VALUES (l_rec_document.*) 
		END FOREACH 

		OPEN c_credit USING l_rec_customer.cust_code 
		FOREACH c_credit INTO l_rec_credithead.* 
			LET l_rec_document.trans_type = TRAN_TYPE_CREDIT_CR 
			LET l_rec_document.trans_num = l_rec_credithead.cred_num 
			LET l_rec_document.trans_date = l_rec_credithead.cred_date 
			LET l_rec_document.trans_ref = l_rec_credithead.cred_text 
			LET l_rec_document.days_num = get_age_bucket(TRAN_TYPE_CREDIT_CR,l_rec_credithead.cred_date) 
			LET l_rec_document.curr_code = l_rec_credithead.currency_code 
			LET l_rec_document.conv_qty = l_rec_credithead.conv_qty 
			LET l_rec_document.trans_amt = 0 - l_rec_credithead.total_amt 
			LET l_rec_document.unpaid_amt = 0 - (l_rec_credithead.total_amt 
			- l_rec_credithead.appl_amt) 
			INSERT INTO t_document VALUES (l_rec_document.*) 
		END FOREACH 

		OPEN c_cash USING l_rec_customer.cust_code 
		FOREACH c_cash INTO l_rec_cashreceipt.* 
			LET l_rec_document.trans_type = TRAN_TYPE_RECEIPT_CA 
			LET l_rec_document.trans_num = l_rec_cashreceipt.cash_num 
			LET l_rec_document.trans_date = l_rec_cashreceipt.cash_date 
			LET l_rec_document.trans_ref = l_rec_cashreceipt.cheque_text 
			LET l_rec_document.days_num=get_age_bucket(TRAN_TYPE_RECEIPT_CA,l_rec_cashreceipt.cash_date) 
			LET l_rec_document.curr_code = l_rec_cashreceipt.currency_code 
			LET l_rec_document.conv_qty = l_rec_cashreceipt.conv_qty 
			LET l_rec_document.trans_amt = 0 - l_rec_cashreceipt.cash_amt 
			LET l_rec_document.unpaid_amt = 0 - (l_rec_cashreceipt.cash_amt 
			- l_rec_cashreceipt.applied_amt) 
			INSERT INTO t_document VALUES (l_rec_document.*) 
		END FOREACH 

		DECLARE c_t_document CURSOR FOR 
		SELECT * FROM t_document 
		ORDER BY trans_date, trans_num 
		FOREACH c_t_document INTO l_rec_document.* 
			LET l_rec_document.curr_amt = 0 
			LET l_rec_document.over1_amt = 0 
			LET l_rec_document.over30_amt = 0 
			LET l_rec_document.over60_amt = 0 
			LET l_rec_document.over90_amt = 0 

			CASE 
				WHEN l_rec_document.days_num > 90 
					LET l_rec_document.over90_amt = l_rec_document.unpaid_amt 
				WHEN l_rec_document.days_num > 60 
					LET l_rec_document.over60_amt = l_rec_document.unpaid_amt 
				WHEN l_rec_document.days_num > 30 
					LET l_rec_document.over30_amt = l_rec_document.unpaid_amt 
				WHEN l_rec_document.days_num > 0 
					LET l_rec_document.over1_amt = l_rec_document.unpaid_amt 
				OTHERWISE 
					LET l_rec_document.curr_amt = l_rec_document.unpaid_amt 
			END CASE 

			OUTPUT TO REPORT AAJ_rpt_list (l_rec_document.*, l_detail) 
			#-------------------------------------------------------------------
			OUTPUT TO REPORT AAJ_rpt_list(l_rpt_idx,l_rec_document.*, l_detail) 
			IF NOT rpt_int_flag_handler2("Customer:",l_rec_customer.cust_code, l_rec_document.trans_type,l_rpt_idx) THEN
				EXIT FOREACH 
			END IF
			#-------------------------------------------------------------------			
		END FOREACH 

	END FOREACH 
	 
	#------------------------------------------------------------
	FINISH REPORT AA9_rpt_list
	CALL rpt_finish("AAJ_rpt_list")
	#------------------------------------------------------------
END FUNCTION 
#####################################################################
# END FUNCTION AAJ_rpt_process()
#####################################################################


#####################################################################
# REPORT AAJ_rpt_list(p_rec_document, p_detail)
#
#
#####################################################################
REPORT AAJ_rpt_list(p_rpt_idx,p_rec_document, p_detail) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_document RECORD 
		cust_code LIKE customer.cust_code, 
		name_text LIKE customer.name_text, 
		hold_code LIKE customer.hold_code, 
		type_code LIKE customer.type_code, 
		sale_code LIKE customer.cust_code, 
		trans_type LIKE araudit.tran_type_ind, 
		trans_num LIKE invoicehead.inv_num, 
		trans_date LIKE invoicehead.inv_date, 
		trans_ref CHAR(20), 
		days_num INTEGER, 
		curr_code LIKE invoicehead.currency_code, 
		conv_qty LIKE invoicehead.conv_qty, 
		trans_amt LIKE invoicehead.total_amt, 
		unpaid_amt LIKE invoicehead.paid_amt, 
		curr_amt LIKE customer.curr_amt, 
		over1_amt LIKE customer.over1_amt, 
		over30_amt LIKE customer.over30_amt, 
		over60_amt LIKE customer.over60_amt, 
		over90_amt LIKE customer.over90_amt 
	END RECORD
	DEFINE p_detail CHAR(1)
	
	DEFINE l_arr_line array[4] OF CHAR(132)
	DEFINE l_cust_age_date DATE
	DEFINE l_idx_num SMALLINT
	DEFINE l_overdue_per FLOAT
	--DEFINE l_x SMALLINT 

	OUTPUT 
--	left margin 0 
	ORDER external BY p_rec_document.sale_code, 
	p_rec_document.cust_code, 
	p_rec_document.trans_date, 
	p_rec_document.trans_num 
	
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			IF p_detail = "D" THEN 
				LET glob_arr_rec_rpt_header_footer[p_rpt_idx].line1_text = 
				" ------------- Transaction ------------- Days ", 
				" Transaction Balance", 
				" ------------------------ Month Due -----------------------" 
				LET glob_arr_rec_rpt_header_footer[p_rpt_idx].line2_text = 
				" Date Type Number Reference Late Amount Amount" 
			ELSE 
				LET glob_arr_rec_rpt_header_footer[p_rpt_idx].line1_text = 
				" Customer Name Type Hold ", 
				" Balance", 
				" ------------------------ Month Due -----------------------" 
				LET glob_arr_rec_rpt_header_footer[p_rpt_idx].line2_text = 
				" Amount" 
			END IF 
			IF month(modu_rec_criteria.age_date) = 12 THEN 
				LET l_cust_age_date = mdy( 1,1,year(modu_rec_criteria.age_date) + 1) 
			ELSE 
				LET l_cust_age_date = mdy( month(modu_rec_criteria.age_date) + 1, 
				1, 
				year(modu_rec_criteria.age_date) ) 
			END IF 

			FOR l_idx_num = 1 TO 5 
				LET l_cust_age_date = l_cust_age_date - 1 units month 
				LET glob_arr_rec_rpt_header_footer[p_rpt_idx].line2_text = 
					glob_arr_rec_rpt_header_footer[p_rpt_idx].line2_text clipped,7 spaces, 
					l_cust_age_date USING "mmmyy" 
			END FOR 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  
			PRINT glob_arr_rec_rpt_header_footer[p_rpt_idx].line1_text 
			PRINT glob_arr_rec_rpt_header_footer[p_rpt_idx].line2_text 
			PRINT COLUMN 01,l_arr_line[3] 
			SELECT name_text INTO modu_temp_text 
			FROM salesperson 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND sale_code = p_rec_document.sale_code 
			IF status = NOTFOUND THEN 
				LET modu_temp_text = "**********" 
			END IF 
			PRINT COLUMN 1, "Salesperson:", 
			COLUMN 14, p_rec_document.sale_code, 
			COLUMN 24, modu_temp_text[1,30] 
			PRINT COLUMN 2, "Aging Date:", 
			COLUMN 14, modu_rec_criteria.age_date USING "dd/mm/yy" 

		BEFORE GROUP OF p_rec_document.sale_code 
			NEED 60 LINES 

		BEFORE GROUP OF p_rec_document.cust_code 
			IF p_detail = "D" THEN 
				SKIP 1 LINES 
				PRINT COLUMN 1, "Customer:", 
				COLUMN 11, p_rec_document.cust_code, 
				COLUMN 20, p_rec_document.name_text, " ", 
				p_rec_document.type_code," ", p_rec_document.hold_code 
			ELSE 
				PRINT COLUMN 1, p_rec_document.cust_code, 
				COLUMN 11, p_rec_document.name_text, " ", 
				p_rec_document.type_code," ", p_rec_document.hold_code; 
			END IF 

		ON EVERY ROW 
			IF p_detail = "D" THEN 
				PRINT COLUMN 2, p_rec_document.trans_date USING "dd/mm/yy", 
				COLUMN 11, p_rec_document.trans_type, 
				COLUMN 14, p_rec_document.trans_num USING "########", 
				COLUMN 23, p_rec_document.trans_ref, 
				COLUMN 43, p_rec_document.days_num USING "---&", 
				COLUMN 48, p_rec_document.trans_amt USING "-----,--&.&&", 
				COLUMN 60, p_rec_document.unpaid_amt USING "-----,--&.&&", 
				COLUMN 72, p_rec_document.curr_amt USING "-----,--&.&&", 
				COLUMN 84, p_rec_document.over1_amt USING "-----,--&.&&", 
				COLUMN 96, p_rec_document.over30_amt USING "-----,--&.&&", 
				COLUMN 108,p_rec_document.over60_amt USING "-----,--&.&&", 
				COLUMN 120,p_rec_document.over90_amt USING "-----,--&.&&" 
			END IF 

		AFTER GROUP OF p_rec_document.cust_code 
			IF p_detail = "D" THEN 
				PRINT COLUMN 48, " ----------------------------", 
				" ",p_rec_document.curr_code," ", 
				"----------------------------------------" 
			END IF 
			IF GROUP sum(p_rec_document.unpaid_amt) != 0 THEN 
				LET l_overdue_per = 100 * (group sum(p_rec_document.unpaid_amt) 
				- GROUP sum(p_rec_document.curr_amt)) 
				/ (group sum(p_rec_document.unpaid_amt)) 
			ELSE 
				LET l_overdue_per = 0 
			END IF 
			IF p_detail = "D" THEN 
				PRINT COLUMN 13,"Totals: (percent overdue:", 
				l_overdue_per USING "%##&.&",")"; 
			END IF 
			PRINT COLUMN 60, GROUP sum(p_rec_document.unpaid_amt) USING "-----,--&.&&", 
			COLUMN 72, GROUP sum(p_rec_document.curr_amt) USING "-----,--&.&&", 
			COLUMN 84, GROUP sum(p_rec_document.over1_amt) USING "-----,--&.&&", 
			COLUMN 96, GROUP sum(p_rec_document.over30_amt) USING "-----,--&.&&", 
			COLUMN 108,group sum(p_rec_document.over60_amt) USING "-----,--&.&&", 
			COLUMN 120,group sum(p_rec_document.over90_amt) USING "-----,--&.&&" 

		AFTER GROUP OF p_rec_document.sale_code 
			NEED 5 LINES 
			SKIP 2 LINES 
			PRINT COLUMN 01, "Salesperson Totals: (Base Currency)", 
			COLUMN 48, " ----------------------------", 
			" ",glob_rec_glparms.base_currency_code," ", 
			"----------------------------------------" 
			IF GROUP sum(p_rec_document.unpaid_amt) != 0 THEN 
				LET l_overdue_per = 100 * (group sum(p_rec_document.unpaid_amt) 
				- GROUP sum(p_rec_document.curr_amt)) 
				/ (group sum(p_rec_document.unpaid_amt)) 
			ELSE 
				LET l_overdue_per = 0 
			END IF 
			PRINT COLUMN 21,"(percent overdue:",l_overdue_per using "%##&.&",")", 
			COLUMN 60, GROUP sum(p_rec_document.unpaid_amt 
			/p_rec_document.conv_qty) USING "-----,--&.&&", 
			COLUMN 72, GROUP sum(p_rec_document.curr_amt 
			/p_rec_document.conv_qty) USING "-----,--&.&&", 
			COLUMN 84, GROUP sum(p_rec_document.over1_amt 
			/p_rec_document.conv_qty) USING "-----,--&.&&", 
			COLUMN 96, GROUP sum(p_rec_document.over30_amt 
			/p_rec_document.conv_qty) USING "-----,--&.&&", 
			COLUMN 108,group sum(p_rec_document.over60_amt 
			/p_rec_document.conv_qty) USING "-----,--&.&&", 
			COLUMN 120,group sum(p_rec_document.over90_amt 
			/p_rec_document.conv_qty) USING "-----,--&.&&" 
		ON LAST ROW 
			PRINT l_arr_line[3] 
			NEED 6 LINES 
			SKIP 1 line 
			PRINT COLUMN 01, "Report Totals: (Base Currency)", 
			COLUMN 48, " ============================", 
			" ",glob_rec_glparms.base_currency_code," ", 
			"========================================" 
			IF sum(p_rec_document.unpaid_amt) != 0 THEN 
				LET l_overdue_per = 100 * (sum(p_rec_document.unpaid_amt) 
				- sum(p_rec_document.curr_amt)) 
				/ (sum(p_rec_document.unpaid_amt)) 
			ELSE 
				LET l_overdue_per = 0 
			END IF 
			PRINT COLUMN 21,"(percent overdue:",l_overdue_per using "%##&.&",")", 
			COLUMN 60, sum(p_rec_document.unpaid_amt /p_rec_document.conv_qty) USING "-----,--&.&&", 
			COLUMN 72, sum(p_rec_document.curr_amt /p_rec_document.conv_qty) USING "-----,--&.&&", 
			COLUMN 84, sum(p_rec_document.over1_amt /p_rec_document.conv_qty) USING "-----,--&.&&", 
			COLUMN 96, sum(p_rec_document.over30_amt /p_rec_document.conv_qty) USING "-----,--&.&&", 
			COLUMN 108,sum(p_rec_document.over60_amt /p_rec_document.conv_qty) USING "-----,--&.&&", 
			COLUMN 120,sum(p_rec_document.over90_amt /p_rec_document.conv_qty) USING "-----,--&.&&" 
			SKIP 1 line 
						
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = pageno
			
			
END REPORT
#####################################################################
# END REPORT AAJ_rpt_list(p_rec_document, p_detail)
#####################################################################