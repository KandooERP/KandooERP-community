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
GLOBALS "../ar/ART_J_GLOBALS.4gl"  
############################################################
# FUNCTION ART_J_main() 
#
# ART Summary Aging by JMJ Debt Type AND Customer Type
# Account Aging by Reference REPORT
# New faciltity TO REPORT outstanding IN/CR/CA amounts by
# customer reference (purchase_code), aged INTO current,
# over 30, over 60 AND over 90 days according TO selected date

############################################################
FUNCTION ART_J_main() 
	DEFER quit 
	DEFER interrupt
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

	CALL setModuleId("ART_J")
	CALL init_report_ar() #report default data from db-arparms
	CALL AR_temp_tables_create()

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query

		WHEN RPT_OP_MENU #UI/MENU Mode
			LET glob_ref_prompt = glob_rec_arparms.inv_ref1_text CLIPPED,"............" 
		
			OPEN WINDOW A647 with FORM "A647" 
			CALL windecoration_a("A647") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
		
			DISPLAY glob_rec_arparms.inv_ref1_text TO inv_ref1_text 
			DISPLAY glob_ref_prompt TO ref_prompt 
		
			MENU "Aging Report" 
		
				BEFORE MENU 
					CALL publish_toolbar("kandoo","ART","menu-aging-REPORT") 
					#NOTE: There is no Default Report - User has to choose which report type is required prior
												
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
					
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				ON ACTION "REPORT_SUMMARY"
					CALL ART_J_rpt_process(ART_J_rpt_query("Summary"))
					CALL AR_temp_tables_delete()
		
				ON ACTION "REPORT_DETAILED"
					CALL ART_J_rpt_process(ART_J_rpt_query("Detailed"))
					CALL AR_temp_tables_delete()
		
				ON ACTION "REPORT_ITEMISED"
					CALL ART_J_rpt_process(ART_J_rpt_query("Itemised"))
					CALL AR_temp_tables_delete() 
		
				ON ACTION "Print Manager"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "CANCEL" 
					EXIT MENU 
		
			END MENU 
			CLOSE WINDOW A647			
 	 
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL ART_J_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW A647 with FORM "A647" 
			CALL windecoration_a("A647") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(ART_J_rpt_query("Detailed")) #save where clause in env 
			CLOSE WINDOW A647 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL ART_J_rpt_process(get_url_sel_text())
	END CASE

	CALL AR_temp_tables_drop() 
END FUNCTION 


############################################################
# FUNCTION ART_J_rpt_query(p_mode_text) 
#
#
############################################################
FUNCTION ART_J_rpt_query(p_mode_text) 
	DEFINE p_mode_text CHAR(10) # "Detailed", "Summary" 
	DEFINE l_where_text STRING
	DEFINE l_rec_trans RECORD 
		purchase_code LIKE invoicehead.purchase_code, 
		type_code LIKE customer.type_code, 
		ref3_code LIKE customer.ref3_code, # jmj imprest = y? 
		cust_code LIKE customer.cust_code, 
		name_text LIKE customer.name_text, 
		due_date LIKE invoicehead.due_date, 
		tran_type_ind CHAR(2), # transaction type = TRAN_TYPE_INVOICE_IN, TRAN_TYPE_CREDIT_CR, TRAN_TYPE_RECEIPT_CA 
		tran_num LIKE invoicehead.inv_num, 
		total_amt LIKE invoicehead.total_amt, 
		apply_amt LIKE invoicehead.paid_amt, 
		currency_code LIKE customer.currency_code, 
		conv_qty LIKE invoicehead.conv_qty 
	END RECORD 
	DEFINE l_rec_aged_amts RECORD 
		days_late SMALLINT, 
		unpaid_amt LIKE invoicehead.total_amt, 
		curr_amt LIKE invoicehead.total_amt, 
		o30_amt LIKE invoicehead.total_amt, 
		o60_amt LIKE invoicehead.total_amt, 
		o90_amt LIKE invoicehead.total_amt, 
		plus90_amt LIKE invoicehead.total_amt 
	END RECORD 
	DEFINE l_prev_purch_code LIKE invoicehead.purchase_code 
	DEFINE l_i SMALLINT 
	DEFINE l_x SMALLINT 
	DEFINE l_j SMALLINT 
	DEFINE l_h SMALLINT 

	CLEAR 
		aging_date, 
		type_code, 
		cust_code, 
		name_text, 
		currency_code, 
		purchase_code 

	MESSAGE " Enter date on which TO base aging in this REPORT" attribute(yellow) 

	LET glob_aging_date = TODAY 

	INPUT glob_aging_date	WITHOUT DEFAULTS FROM aging_date

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","ART","inp-aging") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER FIELD aging_date 
			IF glob_aging_date IS NULL THEN 
				ERROR " Must enter a date" 
				NEXT FIELD aging_date 
			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL 
	END IF 

	MESSAGE " Enter criteria FOR selection - ESC TO begin REPORT" attribute(yellow) 

	CONSTRUCT BY NAME l_where_text ON 
	customer.type_code, 
	customer.cust_code, 
	customer.name_text, 
	customer.currency_code, 
	invoicehead.purchase_code 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","ART","construct-customer") 

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
		LET glob_rec_rpt_selector.ref1_code = p_mode_text
		RETURN l_where_text
	END IF 	
END FUNCTION	


############################################################
# FUNCTION ART_J_rpt_process(p_mode_text) 
#
#
############################################################
FUNCTION ART_J_rpt_process(p_where_text) 
	DEFINE p_where_text STRING
	DEFINE p_mode_text CHAR(10) # "Detailed", "Summary" #will be retrieved from rmsreps  glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ART_J_rpt_list")].ref1_code 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT
	DEFINE l_rec_trans RECORD 
		purchase_code LIKE invoicehead.purchase_code, 
		type_code LIKE customer.type_code, 
		ref3_code LIKE customer.ref3_code, # jmj imprest = y? 
		cust_code LIKE customer.cust_code, 
		name_text LIKE customer.name_text, 
		due_date LIKE invoicehead.due_date, 
		tran_type_ind CHAR(2), # transaction type = TRAN_TYPE_INVOICE_IN, TRAN_TYPE_CREDIT_CR, TRAN_TYPE_RECEIPT_CA 
		tran_num LIKE invoicehead.inv_num, 
		total_amt LIKE invoicehead.total_amt, 
		apply_amt LIKE invoicehead.paid_amt, 
		currency_code LIKE customer.currency_code, 
		conv_qty LIKE invoicehead.conv_qty 
	END RECORD 
	DEFINE l_rec_aged_amts RECORD 
		days_late SMALLINT, 
		unpaid_amt LIKE invoicehead.total_amt, 
		curr_amt LIKE invoicehead.total_amt, 
		o30_amt LIKE invoicehead.total_amt, 
		o60_amt LIKE invoicehead.total_amt, 
		o90_amt LIKE invoicehead.total_amt, 
		plus90_amt LIKE invoicehead.total_amt 
	END RECORD 
	DEFINE l_prev_purch_code LIKE invoicehead.purchase_code 
	DEFINE l_i SMALLINT 
	DEFINE l_x SMALLINT 
	DEFINE l_j SMALLINT 
	DEFINE l_h SMALLINT 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"ART_J_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	

	START REPORT ART_J_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	LET p_mode_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ART_J_rpt_list")].ref1_code

	CALL set_aging(glob_rec_kandoouser.cmpy_code,glob_aging_date) 

	LET l_query_text = 
	"SELECT invoicehead.purchase_code, ", 
	"customer.type_code, ", 
	"customer.ref3_code, ", # jmj imprest y? 
	"customer.cust_code, ", 
	"customer.name_text, ", 
	"invoicehead.due_date, ", 
	"'IN', ", # tran type 
	"invoicehead.inv_num, ", 
	"invoicehead.total_amt, ", 
	"invoicehead.paid_amt, ", 
	"customer.currency_code, ", 
	"invoicehead.conv_qty ", 
	"FROM invoicehead, customer ", 
	"WHERE customer.cmpy_code = '",glob_rec_kandoouser.cmpy_code, "' ", 
	"AND invoicehead.cmpy_code = '",glob_rec_kandoouser.cmpy_code, "' ", 
	"AND invoicehead.cust_code = customer.cust_code ", 
	"AND invoicehead.total_amt != invoicehead.paid_amt ", 
	"AND invoicehead.posted_flag != 'V' ", 
	"AND ", p_where_text CLIPPED

	LET l_x = length(p_where_text) 
	IF l_x > 25 THEN 
		FOR l_i = 1 TO (l_x - 25) 
			IF p_where_text[l_i,l_i+24] = "invoicehead.purchase_code" THEN 
				LET p_where_text[l_i,l_i+24] = "credithead.cred_text " 
			END IF 
		END FOR 
	END IF 

	LET l_query_text = l_query_text CLIPPED, " UNION ALL ", 
	"SELECT credithead.cred_text, ", # purchase_code 
	"customer.type_code, ", 
	"customer.ref3_code, ", # jmj imprest y? 
	"customer.cust_code, ", 
	"customer.name_text, ", 
	"credithead.cred_date, ", # due_date! 
	"'CR', ", # tran type 
	"credithead.cred_num, ", 
	"credithead.total_amt, ", 
	"credithead.appl_amt, ", 
	"customer.currency_code, ", 
	"credithead.conv_qty ", 
	"FROM credithead, customer ", 
	"WHERE customer.cmpy_code = '",glob_rec_kandoouser.cmpy_code, "' ", 
	"AND credithead.cmpy_code = '",glob_rec_kandoouser.cmpy_code, "' ", 
	"AND credithead.cust_code = customer.cust_code ", 
	"AND credithead.total_amt != credithead.appl_amt ", 
	"AND credithead.posted_flag != 'V' ", 
	"AND ", p_where_text CLIPPED 

	LET l_x = length(p_where_text) 
	IF l_x > 20 THEN 
		FOR l_i = 1 TO (l_x - 20) 
			IF p_where_text[l_i,l_i+19] = "credithead.cred_text" THEN 
				LET p_where_text[l_i,l_i] = " " 
				LET p_where_text = p_where_text[1,l_i]," 1=1" 
				EXIT FOR 
			END IF 
		END FOR 
	END IF 

	LET l_query_text = l_query_text CLIPPED, " UNION ALL ", 
	"SELECT 'CA ', ", # purchase_code! 
	"customer.type_code, ", 
	"customer.ref3_code, ", # jmj imprest y? 
	"customer.cust_code, ", 
	"customer.name_text, ", 
	"cashreceipt.cash_date,", # due_date! 
	"'CA', ", # tran type 
	"cashreceipt.cash_num, ", 
	"cashreceipt.cash_amt, ", 
	"cashreceipt.applied_amt, ", 
	"customer.currency_code, ", 
	"cashreceipt.conv_qty ", 
	"FROM cashreceipt, customer ", 
	"WHERE customer.cmpy_code = '",glob_rec_kandoouser.cmpy_code, "' ", 
	"AND cashreceipt.cmpy_code = '",glob_rec_kandoouser.cmpy_code, "' ", 
	"AND cashreceipt.cust_code = customer.cust_code ", 
	"AND cashreceipt.cash_amt != cashreceipt.applied_amt ", 
	"AND cashreceipt.posted_flag != '", CASHRECEIPT_POST_FLAG_STATUS_VOIDED_V, "' ", 
	"AND ", p_where_text CLIPPED 

	LET l_prev_purch_code = " " 

	MESSAGE glob_rec_arparms.inv_ref1_text   

	PREPARE q_trans FROM l_query_text 
	DECLARE c_trans CURSOR FOR q_trans 

	FOREACH c_trans INTO l_rec_trans.* 

		IF l_rec_trans.conv_qty IS NOT NULL THEN 
			IF l_rec_trans.conv_qty != 0 THEN 
				LET l_rec_trans.total_amt = l_rec_trans.total_amt / l_rec_trans.conv_qty 
				LET l_rec_trans.apply_amt = l_rec_trans.apply_amt / l_rec_trans.conv_qty 
			END IF 
		END IF 

		IF l_rec_trans.ref3_code matches "[Yy]*" THEN # jmj specific 
			LET l_rec_trans.ref3_code = "Imprest" 
		ELSE 
			LET l_rec_trans.ref3_code = " " 
		END IF 
		LET l_rec_aged_amts.days_late = get_age_bucket(l_rec_trans.tran_type_ind, l_rec_trans.due_date) 
		LET l_rec_aged_amts.unpaid_amt = l_rec_trans.total_amt - l_rec_trans.apply_amt 
		IF l_rec_trans.tran_type_ind != TRAN_TYPE_INVOICE_IN THEN 
			LET l_rec_aged_amts.unpaid_amt = 0 - l_rec_aged_amts.unpaid_amt 
			LET l_rec_aged_amts.days_late = 0 
		END IF 

		LET l_rec_aged_amts.plus90_amt = 0 
		LET l_rec_aged_amts.o90_amt = 0 
		LET l_rec_aged_amts.o60_amt = 0 
		LET l_rec_aged_amts.o30_amt = 0 
		LET l_rec_aged_amts.curr_amt = 0 
		CASE 
			WHEN l_rec_aged_amts.days_late > 90 
				LET l_rec_aged_amts.plus90_amt = l_rec_aged_amts.unpaid_amt 
			WHEN l_rec_aged_amts.days_late > 60 
				LET l_rec_aged_amts.o90_amt = l_rec_aged_amts.unpaid_amt 
			WHEN l_rec_aged_amts.days_late > 30 
				LET l_rec_aged_amts.o60_amt = l_rec_aged_amts.unpaid_amt 
			WHEN l_rec_aged_amts.days_late > 0 
				LET l_rec_aged_amts.o30_amt = l_rec_aged_amts.unpaid_amt 
			OTHERWISE 
				LET l_rec_aged_amts.curr_amt = l_rec_aged_amts.unpaid_amt 
		END CASE 

		IF l_prev_purch_code != l_rec_trans.purchase_code THEN 
			#MESSAGE l_rec_trans.purchase_code  
			LET l_prev_purch_code = l_rec_trans.purchase_code 
		END IF 
		#---------------------------------------------------------
		OUTPUT TO REPORT ART_J_rpt_list(l_rpt_idx,l_rec_trans.*,l_rec_aged_amts.*,p_mode_text)   
		IF NOT rpt_int_flag_handler2("Customer:",l_rec_trans.purchase_code, l_rec_trans.cust_code,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT ART_J_rpt_list
	RETURN rpt_finish("ART_J_rpt_list")
	#------------------------------------------------------------
 
END FUNCTION 


############################################################
# REPORT ART_J_rpt_list(p_rec_trans, p_rec_aged_amts, p_mode_text)  
#
#
############################################################
REPORT ART_J_rpt_list(p_rpt_idx,p_rec_trans, p_rec_aged_amts, p_mode_text) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_trans RECORD 
		purchase_code LIKE invoicehead.purchase_code, 
		type_code LIKE customer.type_code, 
		ref3_code LIKE customer.ref3_code, # jmj imprest = y? 
		cust_code LIKE customer.cust_code, 
		name_text LIKE customer.name_text, 
		due_date LIKE invoicehead.due_date, 
		tran_type_ind CHAR(2), # transaction type = TRAN_TYPE_INVOICE_IN, TRAN_TYPE_CREDIT_CR, TRAN_TYPE_RECEIPT_CA 
		tran_num LIKE invoicehead.inv_num, 
		total_amt LIKE invoicehead.total_amt, 
		apply_amt LIKE invoicehead.paid_amt, 
		currency_code LIKE customer.currency_code, 
		conv_qty LIKE invoicehead.conv_qty 
	END RECORD
	DEFINE p_rec_aged_amts RECORD 
		days_late SMALLINT, 
		unpaid_amt LIKE invoicehead.total_amt, 
		curr_amt LIKE invoicehead.total_amt, 
		o30_amt LIKE invoicehead.total_amt, 
		o60_amt LIKE invoicehead.total_amt, 
		o90_amt LIKE invoicehead.total_amt, 
		plus90_amt LIKE invoicehead.total_amt 
	END RECORD
	DEFINE p_mode_text CHAR(10) # "Detailed", "Summary", "Itemised" 
	DEFINE l_rec_customertype RECORD LIKE customertype.*
	DEFINE l_rec_jmj_debttype RECORD LIKE jmj_debttype.*
	DEFINE l_totl_amt DECIMAL(16,2)
	DEFINE l_curr_amt DECIMAL(16,2)
	DEFINE l_o30_amt DECIMAL(16,2)
	DEFINE l_o60_amt DECIMAL(16,2)
	DEFINE l_o90_amt DECIMAL(16,2)
	DEFINE l_p90_amt DECIMAL(16,2)
	DEFINE l_curr_per DECIMAL(16,2) 
	DEFINE l_o30_per DECIMAL(16,2)
	DEFINE l_o60_per DECIMAL(16,2) 
	DEFINE l_o90_per DECIMAL(16,4) 
	DEFINE l_p90_per DECIMAL(16,4) 
	DEFINE l_line1 NCHAR(130) 
	DEFINE l_line2 NCHAR(130) 
	
	ORDER BY p_rec_trans.purchase_code, # ref3 IS altered AFTER SELECT 
	p_rec_trans.type_code, 
	p_rec_trans.ref3_code, # jmj imprest y 
	p_rec_trans.cust_code, 
	p_rec_trans.due_date 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,PAGENO) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 CLIPPED #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 CLIPPED #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]
			PRINT COLUMN 55, "Aging as at: ", glob_aging_date USING "dd/mm/yy"
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text CLIPPED 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text CLIPPED 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]	

	BEFORE GROUP OF p_rec_trans.purchase_code 
		SELECT * 
		INTO l_rec_jmj_debttype.* 
		FROM jmj_debttype 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND debt_type_code = p_rec_trans.purchase_code 
		IF status = NOTFOUND THEN 
			LET l_rec_jmj_debttype.desc_text = "???" 
		END IF 
		NEED 5 LINES 
		SKIP 1 LINE 
		PRINT COLUMN 01, glob_rec_arparms.inv_ref1_text CLIPPED,":"," ",p_rec_trans.purchase_code CLIPPED," ",l_rec_jmj_debttype.desc_text CLIPPED 

	ON EVERY ROW 
		IF p_mode_text = "Itemised" THEN 
			PRINT 
			COLUMN 01, p_rec_trans.cust_code CLIPPED, 
			COLUMN 10, p_rec_trans.due_date       USING "dd/mm/yy", 
			COLUMN 19, p_rec_trans.tran_type_ind CLIPPED, 
			COLUMN 21, p_rec_trans.tran_num       USING "&&&&&&&&", 
			COLUMN 38, p_rec_aged_amts.days_late  USING "----&", 
			COLUMN 43, p_rec_aged_amts.unpaid_amt USING "----,---,--&.&&", 
			COLUMN 58, p_rec_aged_amts.curr_amt   USING "----,---,--&.&&", 
			COLUMN 73, p_rec_aged_amts.o30_amt    USING "----,---,--&.&&", 
			COLUMN 88, p_rec_aged_amts.o60_amt    USING "----,---,--&.&&", 
			COLUMN 103,p_rec_aged_amts.o90_amt    USING "----,---,--&.&&", 
			COLUMN 118,p_rec_aged_amts.plus90_amt USING "----,---,--&.&&" 
		END IF 

	AFTER GROUP OF p_rec_trans.cust_code 
		IF p_mode_text != "Summary" THEN 
			PRINT 
			COLUMN 05, p_rec_trans.name_text CLIPPED, 
			COLUMN 38, GROUP AVG(p_rec_aged_amts.days_late) 	USING "----&", 
			COLUMN 43, GROUP SUM(p_rec_aged_amts.unpaid_amt)	USING "----,---,--&.&&", 
			COLUMN 58, GROUP SUM(p_rec_aged_amts.curr_amt) 		USING "----,---,--&.&&", 
			COLUMN 73, GROUP SUM(p_rec_aged_amts.o30_amt) 		USING "----,---,--&.&&", 
			COLUMN 88, GROUP SUM(p_rec_aged_amts.o60_amt) 		USING "----,---,--&.&&", 
			COLUMN 103, GROUP SUM(p_rec_aged_amts.o90_amt)		USING "----,---,--&.&&", 
			COLUMN 118, GROUP SUM(p_rec_aged_amts.plus90_amt)	USING "----,---,--&.&&" 
		END IF 

	AFTER GROUP OF p_rec_trans.ref3_code # jmj specific 
		SELECT * 
		INTO l_rec_customertype.* 
		FROM customertype 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND type_code = p_rec_trans.type_code 
		IF status = NOTFOUND THEN 
			LET l_rec_customertype.type_text = "???" 
		END IF 
		PRINT 
		COLUMN 01, l_rec_customertype.type_text[1,25] CLIPPED, 
		COLUMN 27, p_rec_trans.ref3_code CLIPPED, # jmj specific 
		COLUMN 38, GROUP AVG(p_rec_aged_amts.days_late) 		USING "----&", 
		COLUMN 43, GROUP SUM(p_rec_aged_amts.unpaid_amt)		USING "----,---,--&.&&", 
		COLUMN 58, GROUP SUM(p_rec_aged_amts.curr_amt) 			USING "----,---,--&.&&", 
		COLUMN 73, GROUP SUM(p_rec_aged_amts.o30_amt) 			USING "----,---,--&.&&", 
		COLUMN 88, GROUP SUM(p_rec_aged_amts.o60_amt) 			USING "----,---,--&.&&", 
		COLUMN 103, GROUP SUM(p_rec_aged_amts.o90_amt)			USING "----,---,--&.&&", 
		COLUMN 118, GROUP SUM(p_rec_aged_amts.plus90_amt)		USING "----,---,--&.&&" 
		IF p_mode_text != "Summary" THEN 
			SKIP 1 LINE 
		END IF 

	AFTER GROUP OF p_rec_trans.purchase_code 
		NEED 3 LINES 
		PRINT COLUMN 46, "-----------------------------------------------", 
		"----------------------------------------" 
		PRINT 
		COLUMN 05, l_rec_jmj_debttype.desc_text CLIPPED, 
		COLUMN 38, GROUP AVG(p_rec_aged_amts.days_late) 		USING "----&", 
		COLUMN 43, GROUP SUM(p_rec_aged_amts.unpaid_amt)		USING "----,---,--&.&&", 
		COLUMN 58, GROUP SUM(p_rec_aged_amts.curr_amt) 			USING "----,---,--&.&&", 
		COLUMN 73, GROUP SUM(p_rec_aged_amts.o30_amt) 			USING "----,---,--&.&&", 
		COLUMN 88, GROUP SUM(p_rec_aged_amts.o60_amt) 			USING "----,---,--&.&&", 
		COLUMN 103, GROUP SUM(p_rec_aged_amts.o90_amt)			USING "----,---,--&.&&", 
		COLUMN 118, GROUP SUM(p_rec_aged_amts.plus90_amt)		USING "----,---,--&.&&" 

	ON LAST ROW 
		NEED 9 LINES 
		SKIP 1 LINE 
		PRINT COLUMN 46, "===============================================", 
		"========================================" 
		LET l_totl_amt = SUM(p_rec_aged_amts.unpaid_amt) 
		LET l_curr_amt = SUM(p_rec_aged_amts.curr_amt) 
		LET l_o30_amt = SUM(p_rec_aged_amts.o30_amt) 
		LET l_o60_amt = SUM(p_rec_aged_amts.o60_amt) 
		LET l_o90_amt = SUM(p_rec_aged_amts.o90_amt) 
		LET l_p90_amt = SUM(p_rec_aged_amts.plus90_amt) 
		IF l_totl_amt <> 0 THEN 
			IF l_curr_amt <> 0 THEN 
				LET l_curr_per = (l_curr_amt / l_totl_amt) * 100 
			ELSE 
				LET l_curr_per = 0 
			END IF 
			IF l_o30_amt <> 0 THEN 
				LET l_o30_per = (l_o30_amt / l_totl_amt) * 100 
			ELSE 
				LET l_o30_per = 0 
			END IF 
			IF l_o60_amt <> 0 THEN 
				LET l_o60_per = (l_o60_amt / l_totl_amt) * 100 
			ELSE 
				LET l_o60_per = 0 
			END IF 
			IF l_o90_amt <> 0 THEN 
				LET l_o90_per = (l_o90_amt / l_totl_amt) * 100 
			ELSE 
				LET l_o90_per = 0 
			END IF 
			IF l_p90_amt <> 0 THEN 
				LET l_p90_per = (l_p90_amt / l_totl_amt) * 100 
			ELSE 
				LET l_p90_per = 0 
			END IF 
		ELSE 
			LET l_curr_per = 0 
			LET l_o30_per = 0 
			LET l_o60_per = 0 
			LET l_o90_per = 0 
			LET l_p90_per = 0 
		END IF 
			
		PRINT 
		COLUMN 38, AVG(p_rec_aged_amts.days_late) 	USING "----&", 
		COLUMN 43, SUM(p_rec_aged_amts.unpaid_amt)	USING "----,---,--&.&&", 
		COLUMN 58, SUM(p_rec_aged_amts.curr_amt) 		USING "----,---,--&.&&", 
		COLUMN 73, SUM(p_rec_aged_amts.o30_amt) 		USING "----,---,--&.&&", 
		COLUMN 88, SUM(p_rec_aged_amts.o60_amt) 		USING "----,---,--&.&&", 
		COLUMN 103, SUM(p_rec_aged_amts.o90_amt)		USING "----,---,--&.&&", 
		COLUMN 118, SUM(p_rec_aged_amts.plus90_amt)	USING "----,---,--&.&&" 
		PRINT 
		COLUMN 10, "PERCENTAGE OF TOTAL", 
		COLUMN 43, " 100.00", 
		COLUMN 58, l_curr_per 								USING "----,---,--&.&&", 
		COLUMN 73, l_o30_per 								USING "----,---,--&.&&", 
		COLUMN 88, l_o60_per 								USING "----,---,--&.&&", 
		COLUMN 103, l_o90_per 								USING "----,---,--&.&&", 
		COLUMN 118, l_p90_per 								USING "----,---,--&.&&" 
		SKIP 1 LINE 
		PRINT COLUMN 35, "(Amounts converted TO base currency", 
		" using rate as AT transaction date)" 
		SKIP 1 LINE 
		#End Of Report
		IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
			PRINT COLUMN 01,"Selection Criteria:" 
			PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text CLIPPED wordwrap right margin 100 
		END IF 
		PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	
		
END REPORT
 