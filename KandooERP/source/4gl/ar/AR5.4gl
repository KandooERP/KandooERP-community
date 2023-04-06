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
GLOBALS "../ar/AR5_GLOBALS.4gl" 
############################################################
# MODULE Scope Variables
############################################################
--DEFINE modu_rec_customer RECORD LIKE customer.* #not used 
DEFINE modu_tot_amt money(15,2) 
DEFINE modu_tot_rep money(15,2) 
###############################################################
# FUNCTION AR5(p_mode)
#
#
###############################################################
FUNCTION AR5_main() 
	DEFER quit 
	DEFER interrupt
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

	CALL setModuleId("AR5")
	CALL init_report_ar() #report default data from db-arparms
	CALL AR_temp_tables_create()

	LET modu_tot_amt = 0 
	LET modu_tot_rep = 0 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 
			OPEN WINDOW A953 with FORM "A953" 
			CALL windecoration_a("A953") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
		
			MENU "Forecast Report" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","AR5","menu-forecast-REPORT") 
					CALL AR5_rpt_process(AR5_rpt_query())
					CALL AR_temp_tables_delete()
					
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				ON ACTION "Report" #COMMAND "Run Report" " SELECT Criteria AND Print Report"
					CALL AR5_rpt_process(AR5_rpt_query())
					CALL AR_temp_tables_delete()
		
				ON ACTION "Print Manager" #COMMAND "Print" "Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "Exit" #COMMAND "Exit" " Exit TO Menus"
					EXIT MENU 
		
			END MENU 
	 		CLOSE WINDOW A953
	 		
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL AR5_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW A953 with FORM "A953" 
			CALL windecoration_a("A953") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(AR5_rpt_query()) #save where clause in env 
			CLOSE WINDOW A953 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL AR5_rpt_process(get_url_sel_text())
	END CASE 

	CALL AR_temp_tables_drop()
	
END FUNCTION 


###############################################################
# FUNCTION AR5_rpt_query()
#
#
###############################################################
FUNCTION AR5_rpt_query() 
--	DEFINE l_ord_num1 SMALLINT 
--	DEFINE l_ord_num2 SMALLINT 
--	DEFINE l_ord_num3 SMALLINT 
	DEFINE l_ord1 SMALLINT 
	DEFINE l_ord2 SMALLINT 
	DEFINE l_ord3 SMALLINT 
	DEFINE l_exist SMALLINT 
	DEFINE l_adjusted_days INTEGER 
	DEFINE l_rec_tempdoc RECORD 
		tm_cust LIKE customer.cust_code, 
		tm_name LIKE customer.name_text, 
		tm_date LIKE customer.setup_date, 
		tm_estdt DATE, 
		tm_story CHAR(1), 
		tm_select CHAR(3), 
		tm_doc INTEGER, 
		tm_type CHAR(2), 
		tm_refer CHAR(20), 
		tm_due INTEGER, 
		tm_slot SMALLINT, 
		tm_desc CHAR(40), 
		tm_amount money(12,2), 
		tm_dis money(12,2), 
		tm_unpaid money(12,2), 
		tm_past money(12,2), 
		tm_1t7 money(12,2), 
		tm_8t14 money(12,2), 
		tm_15t21 money(12,2), 
		tm_22t28 money(12,2), 
		tm_29t60 money(12,2), 
		tm_61t90 money(12,2), 
		tm_plus money(12,2) 
	END RECORD 
	DEFINE l_rec_invoicehead RECORD 
		cmpy_code LIKE invoicehead.cmpy_code, 
		cust_code LIKE invoicehead.cust_code, 
		name_text LIKE customer.name_text, 
		inv_num LIKE invoicehead.inv_num, 
		inv_date LIKE invoicehead.inv_date, 
		expected_date LIKE invoicehead.expected_date, 
		story_flag LIKE invoicehead.story_flag, 
		due_date LIKE invoicehead.due_date, 
		cred_taken_num LIKE customer.cred_taken_num, 
		cred_given_num LIKE customer.cred_given_num, 
		purchase_code LIKE invoicehead.purchase_code, 
		total_amt LIKE invoicehead.total_amt, 
		paid_amt LIKE invoicehead.paid_amt, 
		disc_amt LIKE invoicehead.disc_amt, 
		disc_taken_amt LIKE invoicehead.disc_taken_amt 
	END RECORD 
	DEFINE l_rec_credithead RECORD 
		cust_code LIKE credithead.cust_code, 
		name_text LIKE customer.name_text, 
		cred_num LIKE credithead.cred_num, 
		cred_date LIKE credithead.cred_date, 
		cred_text LIKE credithead.cred_text, 
		total_amt LIKE credithead.total_amt, 
		appl_amt LIKE credithead.appl_amt 
	END RECORD 
	DEFINE l_vee CHAR(1) 



	CLEAR screen 


	INPUT l_ord1 WITHOUT DEFAULTS FROM ord1 ATTRIBUTE(UNBUFFERED)
		BEFORE INPUT
			CALL publish_toolbar("kandoo","AR5","INPUT-SortOrder-1")
 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar()

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
												 
		ON CHANGE ord1	
			CASE l_ord1 
				WHEN 1 
					DISPLAY "1. Sort By: Promised Date (FROM collection calls)" TO lbprimarypriority 
				WHEN 2 
					DISPLAY "1. Sort By: Historical Analysis (FROM previous payments)" TO lbprimarypriority 
				WHEN 3 
					DISPLAY "1. Sort By: Due Date (FROM invoice)" TO lbprimarypriority 
				OTHERWISE 
					CONTINUE INPUT
			END CASE 
			
		ON ACTION ("ACCEPT","DOUBLECLICK")
			EXIT INPUT
	END INPUT

	CALL displayModuleTitle("SELECT secondary cash flow priority") 
	DISPLAY "Secundary Cash Flow Priority" TO lbcashflowpriority 

	INPUT l_ord2 WITHOUT DEFAULTS FROM ord1 ATTRIBUTE(UNBUFFERED) 
		BEFORE INPUT
			CALL publish_toolbar("kandoo","AR5","INPUT-SortOrder-2")

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar()

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON CHANGE ord1	
			CASE l_ord1 
				WHEN 1 
					DISPLAY "2. Sort By: Promised Date (FROM collection calls)" TO lbsecondarypriority 
				WHEN 2 
					DISPLAY "2. Sort By: Historical Analysis (FROM previous payments)" TO lbsecondarypriority 
				WHEN 3 
					DISPLAY "2. Sort By: Due Date (FROM invoice)" TO lbsecondarypriority 
				OTHERWISE 
					CONTINUE INPUT
			END CASE 

	END INPUT
		
	#some interesting code how not to do this...
	IF l_ord1 = 1 
	AND l_ord2 = 2 THEN 
		LET l_ord3 = 3 
	END IF 
	IF l_ord1 = 1 
	AND l_ord2 = 3 THEN 
		LET l_ord3 = 2 
	END IF 
	IF l_ord1 = 2 
	AND l_ord2 = 1 THEN 
		LET l_ord3 = 3 
	END IF 
	IF l_ord1 = 2 
	AND l_ord2 = 3 THEN 
		LET l_ord3 = 1 
	END IF 
	IF l_ord1 = 3 
	AND l_ord2 = 1 THEN 
		LET l_ord3 = 2 
	END IF 
	IF l_ord1 = 3 
	AND l_ord2 = 2 THEN 
		LET l_ord3 = 1 
	END IF 


	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL
	ELSE
		LET glob_rec_rpt_selector.ref1_num = l_ord1
		LET glob_rec_rpt_selector.ref2_num = l_ord2
		LET glob_rec_rpt_selector.ref3_num = l_ord3
		RETURN " 1=1 "
	END IF 	
	
END FUNCTION

###############################################################
# FUNCTION AR5_rpt_process() 
#
#
###############################################################
FUNCTION AR5_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_ord1 SMALLINT #glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AR5_rpt_list")].ref1_num
	DEFINE l_ord2 SMALLINT #glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AR5_rpt_list")].ref2_num 
	DEFINE l_ord3 SMALLINT #glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AR5_rpt_list")].ref3_num

	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT 
	DEFINE l_ord_num1 SMALLINT
	DEFINE l_ord_num2 SMALLINT 
	DEFINE l_ord_num3 SMALLINT 
	DEFINE l_exist SMALLINT 
	DEFINE l_adjusted_days INTEGER 
	DEFINE l_rec_tempdoc RECORD 
		tm_cust LIKE customer.cust_code, 
		tm_name LIKE customer.name_text, 
		tm_date LIKE customer.setup_date, 
		tm_estdt DATE, 
		tm_story CHAR(1), 
		tm_select CHAR(3), 
		tm_doc INTEGER, 
		tm_type CHAR(2), 
		tm_refer CHAR(20), 
		tm_due INTEGER, 
		tm_slot SMALLINT, 
		tm_desc CHAR(40), 
		tm_amount money(12,2), 
		tm_dis money(12,2), 
		tm_unpaid money(12,2), 
		tm_past money(12,2), 
		tm_1t7 money(12,2), 
		tm_8t14 money(12,2), 
		tm_15t21 money(12,2), 
		tm_22t28 money(12,2), 
		tm_29t60 money(12,2), 
		tm_61t90 money(12,2), 
		tm_plus money(12,2) 
	END RECORD 
	DEFINE l_rec_invoicehead RECORD 
		cmpy_code LIKE invoicehead.cmpy_code, 
		cust_code LIKE invoicehead.cust_code, 
		name_text LIKE customer.name_text, 
		inv_num LIKE invoicehead.inv_num, 
		inv_date LIKE invoicehead.inv_date, 
		expected_date LIKE invoicehead.expected_date, 
		story_flag LIKE invoicehead.story_flag, 
		due_date LIKE invoicehead.due_date, 
		cred_taken_num LIKE customer.cred_taken_num, 
		cred_given_num LIKE customer.cred_given_num, 
		purchase_code LIKE invoicehead.purchase_code, 
		total_amt LIKE invoicehead.total_amt, 
		paid_amt LIKE invoicehead.paid_amt, 
		disc_amt LIKE invoicehead.disc_amt, 
		disc_taken_amt LIKE invoicehead.disc_taken_amt 
	END RECORD 
	DEFINE l_rec_credithead RECORD 
		cust_code LIKE credithead.cust_code, 
		name_text LIKE customer.name_text, 
		cred_num LIKE credithead.cred_num, 
		cred_date LIKE credithead.cred_date, 
		cred_text LIKE credithead.cred_text, 
		total_amt LIKE credithead.total_amt, 
		appl_amt LIKE credithead.appl_amt 
	END RECORD 
	
	DEFINE l_vee CHAR(1) 


	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"AR5_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT AR5_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	LET l_ord1 = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AR5_rpt_list")].ref1_num
	LET l_ord2 = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AR5_rpt_list")].ref2_num
	LET l_ord3 = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AR5_rpt_list")].ref3_num


	DECLARE inv_curs CURSOR FOR 
	SELECT i.cmpy_code, i.cust_code, c.name_text, i.inv_num, 
	i.inv_date,i.expected_date, i.story_flag, i.due_date, c.cred_taken_num, 
	c.cred_given_num, i.purchase_code,i.total_amt, 
	i.paid_amt, i.disc_amt, i.disc_taken_amt 

	FROM invoicehead i, customer c 
	WHERE c.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND i.cust_code = c.cust_code 
	AND i.cmpy_code = c.cmpy_code 
	AND i.total_amt != i.paid_amt 

	FOREACH inv_curs INTO l_rec_invoicehead.* 
		LET l_ord_num1 = l_ord1 
		LET l_ord_num2 = l_ord2 
		LET l_ord_num3 = l_ord3 
		LET l_rec_tempdoc.tm_cust = l_rec_invoicehead.cust_code 
		LET l_rec_tempdoc.tm_name = l_rec_invoicehead.name_text 
		LET l_rec_tempdoc.tm_date = l_rec_invoicehead.inv_date 
		LET l_rec_tempdoc.tm_story = l_rec_invoicehead.story_flag 
		LET l_rec_tempdoc.tm_type = TRAN_TYPE_INVOICE_IN 
		LET l_rec_tempdoc.tm_doc = l_rec_invoicehead.inv_num 
		LET l_rec_tempdoc.tm_refer = l_rec_invoicehead.purchase_code 
		LET l_rec_tempdoc.tm_due = l_rec_invoicehead.due_date - today 
		LET l_rec_tempdoc.tm_dis = l_rec_invoicehead.disc_amt - l_rec_invoicehead.disc_taken_amt 
		LET l_rec_tempdoc.tm_amount = l_rec_invoicehead.total_amt 
		LET l_rec_tempdoc.tm_unpaid = l_rec_invoicehead.total_amt - 
		l_rec_invoicehead.paid_amt 

		LET l_rec_tempdoc.tm_plus = 0 
		LET l_rec_tempdoc.tm_1t7 = 0 
		LET l_rec_tempdoc.tm_8t14 = 0 
		LET l_rec_tempdoc.tm_15t21 = 0 
		LET l_rec_tempdoc.tm_22t28 = 0 
		LET l_rec_tempdoc.tm_29t60 = 0 
		LET l_rec_tempdoc.tm_61t90 = 0 
		LET l_rec_tempdoc.tm_past = 0 
		LABEL again: 

		IF l_ord_num1 = 1 
		AND l_rec_invoicehead.expected_date IS NULL THEN 
			LET l_ord_num1 = l_ord_num2 
			LET l_ord_num2 = l_ord_num3 
		ELSE 
			LET l_rec_tempdoc.tm_select = "EXPT" 
			LET l_adjusted_days = l_rec_invoicehead.expected_date - today 
		END IF 

		IF (l_ord_num1 = 2 
		AND (l_rec_invoicehead.cred_given_num = 0 
		OR l_rec_invoicehead.cred_given_num IS null)) 
		THEN 
			LET l_ord_num1 = l_ord_num2 
			LET l_ord_num2 = l_ord_num3 
			GOTO again 
		ELSE 
			IF l_rec_invoicehead.cred_taken_num = 0 THEN LET l_rec_invoicehead.cred_taken_num = 1 END IF 
				IF l_rec_invoicehead.cred_given_num = 0 THEN LET l_rec_invoicehead.cred_given_num = 1 END IF 
					LET l_adjusted_days = (l_rec_invoicehead.inv_date 
					+ ((l_rec_invoicehead.cred_taken_num 
					/ l_rec_invoicehead.cred_given_num) 
					* (l_rec_invoicehead.due_date 
					- l_rec_invoicehead.inv_date)) 
					- today) 

					LET l_rec_tempdoc.tm_select = "HIST" 
				END IF 
				IF l_ord_num1 = 3 
				THEN 
					LET l_rec_tempdoc.tm_select = "DUE" 
					LET l_adjusted_days = l_rec_tempdoc.tm_due 
				END IF 


				IF l_adjusted_days > 90 THEN 
					LET l_rec_tempdoc.tm_plus = l_rec_tempdoc.tm_unpaid 
					LET l_rec_tempdoc.tm_slot = 0 
					LET l_rec_tempdoc.tm_desc = "Over 90 days FROM today" 
				ELSE 
					IF l_adjusted_days > 60 THEN 
						LET l_rec_tempdoc.tm_61t90 = l_rec_tempdoc.tm_unpaid 
						LET l_rec_tempdoc.tm_slot = 1 
						LET l_rec_tempdoc.tm_desc = "60 TO 90 days FROM today" 
					ELSE 
						IF l_adjusted_days > 28 THEN 
							LET l_rec_tempdoc.tm_29t60 = l_rec_tempdoc.tm_unpaid 
							LET l_rec_tempdoc.tm_slot = 2 
							LET l_rec_tempdoc.tm_desc = "29 TO 60 days FROM today" 
						ELSE 
							IF l_adjusted_days > 21 THEN 
								LET l_rec_tempdoc.tm_22t28 = l_rec_tempdoc.tm_unpaid 
								LET l_rec_tempdoc.tm_slot = 3 
								LET l_rec_tempdoc.tm_desc = "22 TO 28 days FROM today" 
							ELSE 
								IF l_adjusted_days > 14 THEN 
									LET l_rec_tempdoc.tm_15t21 = l_rec_tempdoc.tm_unpaid 
									LET l_rec_tempdoc.tm_slot = 4 
									LET l_rec_tempdoc.tm_desc = "15 TO 21 days FROM today" 
								ELSE 
									IF l_adjusted_days > 7 THEN 
										LET l_rec_tempdoc.tm_8t14 = l_rec_tempdoc.tm_unpaid 
										LET l_rec_tempdoc.tm_slot = 5 
										LET l_rec_tempdoc.tm_desc = "8 TO 14 days FROM today" 
									ELSE 
										IF l_adjusted_days > 0 THEN 
											LET l_rec_tempdoc.tm_1t7 = l_rec_tempdoc.tm_unpaid 
											LET l_rec_tempdoc.tm_slot = 6 
											LET l_rec_tempdoc.tm_desc = "1 TO 7 days FROM today" 
										ELSE 
											LET l_rec_tempdoc.tm_past = l_rec_tempdoc.tm_unpaid 
											LET l_rec_tempdoc.tm_slot = 7 
											LET l_rec_tempdoc.tm_desc = "Now - Past Due" 
										END IF 
									END IF 
								END IF 
							END IF 
						END IF 
					END IF 
				END IF 

				LET l_rec_tempdoc.tm_estdt = today + l_adjusted_days 
				INSERT INTO t_ar5_rpt_data_shuffle VALUES (l_rec_tempdoc.*) 
				--DISPLAY "" at 12,10 
				--DISPLAY " Invoice: ", l_rec_invoicehead.inv_num at 12,10 


			END FOREACH 


			DECLARE cre_curs CURSOR FOR 
			SELECT r.cust_code, c.name_text, r.cred_num, 
			r.cred_date, r.cred_text, r.total_amt, 
			r.appl_amt 
			FROM credithead r, customer c 
			WHERE c.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND r.cmpy_code = c.cmpy_code 
			AND r.cust_code = c.cust_code 
			AND r.total_amt != r.appl_amt 


			FOREACH cre_curs INTO l_rec_credithead.* 

				LET l_rec_tempdoc.tm_cust = l_rec_credithead.cust_code 
				LET l_rec_tempdoc.tm_name = l_rec_credithead.name_text 
				LET l_rec_tempdoc.tm_date = l_rec_credithead.cred_date 
				LET l_rec_tempdoc.tm_doc = l_rec_credithead.cred_num 
				LET l_rec_tempdoc.tm_type = TRAN_TYPE_CREDIT_CR 
				LET l_rec_tempdoc.tm_refer = l_rec_credithead.cred_text 
				LET l_rec_tempdoc.tm_due = l_rec_credithead.cred_date - today 
				LET l_rec_tempdoc.tm_amount = - l_rec_credithead.total_amt 
				LET l_rec_tempdoc.tm_unpaid = - l_rec_credithead.total_amt + 
				l_rec_credithead.appl_amt 

				LET l_rec_tempdoc.tm_plus = 0 
				LET l_rec_tempdoc.tm_1t7 = 0 
				LET l_rec_tempdoc.tm_8t14 = 0 
				LET l_rec_tempdoc.tm_15t21 = 0 
				LET l_rec_tempdoc.tm_22t28 = 0 
				LET l_rec_tempdoc.tm_29t60 = 0 
				LET l_rec_tempdoc.tm_61t90 = 0 
				LET l_rec_tempdoc.tm_past = 0 
				CASE 
					WHEN l_rec_tempdoc.tm_due > 90 
						LET l_rec_tempdoc.tm_plus = l_rec_tempdoc.tm_unpaid 
						LET l_rec_tempdoc.tm_slot = 0 
						LET l_rec_tempdoc.tm_desc = "Over 90 days FROM today" 
					WHEN l_rec_tempdoc.tm_due > 60 
						LET l_rec_tempdoc.tm_61t90 = l_rec_tempdoc.tm_unpaid 
						LET l_rec_tempdoc.tm_slot = 1 
						LET l_rec_tempdoc.tm_desc = "61 TO 90 days FROM today" 
					WHEN l_rec_tempdoc.tm_due > 28 
						LET l_rec_tempdoc.tm_29t60 = l_rec_tempdoc.tm_unpaid 
						LET l_rec_tempdoc.tm_slot = 2 
						LET l_rec_tempdoc.tm_desc = "29 TO 60 days FROM today" 
					WHEN l_rec_tempdoc.tm_due > 21 
						LET l_rec_tempdoc.tm_22t28 = l_rec_tempdoc.tm_unpaid 
						LET l_rec_tempdoc.tm_slot = 3 
						LET l_rec_tempdoc.tm_desc = "22 TO 28 days FROM today" 
					WHEN l_rec_tempdoc.tm_due > 14 
						LET l_rec_tempdoc.tm_15t21 = l_rec_tempdoc.tm_unpaid 
						LET l_rec_tempdoc.tm_slot = 4 
						LET l_rec_tempdoc.tm_desc = "15 TO 21 days FROM today" 
					WHEN l_rec_tempdoc.tm_due > 7 
						LET l_rec_tempdoc.tm_8t14 = l_rec_tempdoc.tm_unpaid 
						LET l_rec_tempdoc.tm_slot = 5 
						LET l_rec_tempdoc.tm_desc = "8 TO 14 days FROM today" 
					WHEN l_rec_tempdoc.tm_due > 0 
						LET l_rec_tempdoc.tm_1t7 = l_rec_tempdoc.tm_unpaid 
						LET l_rec_tempdoc.tm_slot = 6 
						LET l_rec_tempdoc.tm_desc = "1 TO 7 days FROM today" 
					OTHERWISE 
						LET l_rec_tempdoc.tm_past = l_rec_tempdoc.tm_unpaid 
						LET l_rec_tempdoc.tm_slot = 7 
						LET l_rec_tempdoc.tm_desc = "Now - Past Due" 
				END CASE 
--				DISPLAY "" at 12,10 
--				DISPLAY "Credit: ", l_rec_credithead.cred_num at 12,10 
					MESSAGE "Credit: ", trim(l_rec_credithead.cred_num)

				LET l_rec_tempdoc.tm_estdt = today 
				INSERT INTO t_ar5_rpt_data_shuffle VALUES (l_rec_tempdoc.*) 

			END FOREACH 

			DECLARE selcurs CURSOR FOR 
			SELECT * FROM t_ar5_rpt_data_shuffle 
			ORDER BY tm_slot asc , tm_amount desc 

			FOREACH selcurs INTO l_rec_tempdoc.* 
				#---------------------------------------------------------
				OUTPUT TO REPORT AR5_rpt_list(l_rpt_idx,l_rec_tempdoc.*)  
				IF NOT rpt_int_flag_handler2("Customer:",l_rec_tempdoc.tm_cust, l_rec_credithead.name_text,l_rpt_idx) THEN
					EXIT FOREACH 
				END IF 
				#---------------------------------------------------------			
			END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT AR5_rpt_list
	CALL rpt_finish("AR5_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF
END FUNCTION 


###############################################################
# REPORT ar5_rpt_list(p_rec_tempdoc)
#
#
###############################################################
REPORT ar5_rpt_list(p_rpt_idx,p_rec_tempdoc) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE l_rec_customer RECORD LIKE customer.*
	DEFINE p_rec_tempdoc 
	RECORD 
		tm_cust CHAR(8), 
		tm_name CHAR(30), 
		tm_date DATE, 
		tm_estdt DATE, 
		tm_story CHAR(1), 
		tm_select CHAR(4), 
		tm_doc INTEGER, 
		tm_type CHAR(2), 
		tm_refer CHAR(20), 
		tm_due INTEGER, 
		tm_slot SMALLINT, 
		tm_desc CHAR(40), 
		tm_amount money(12,2), 
		tm_dis money(12,2), 
		tm_unpaid money(12,2), 
		tm_past money(12,2), 
		tm_1t7 money(12,2), 
		tm_8t14 money(12,2), 
		tm_15t21 money(12,2), 
		tm_22t28 money(12,2), 
		tm_29t60 money(12,2), 
		tm_61t90 money(12,2), 
		tm_plus money(12,2) 
	END RECORD 
	DEFINE l_line1 NCHAR(130) 
	DEFINE l_line2 NCHAR(130) 

	OUTPUT 
--	left margin 0 

	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #was l_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #was l_arr_line[3]  
			
			PRINT COLUMN 1, "Cust ID", 
			COLUMN 15, "Customer Name", 
			COLUMN 41, "Type", 
			COLUMN 50, "Doc.", 
			COLUMN 57, "Due", 
			COLUMN 67, "Days", 
			COLUMN 75, "Estimated", 
			COLUMN 90, "Estimate", 
			COLUMN 108, "Unpaid", 
			COLUMN 120, "Story" 

			PRINT COLUMN 48, "Number", 
			COLUMN 57, "Date", 
			COLUMN 65, "Till Due", 
			COLUMN 75, "Pay Date", 
			COLUMN 90, "Method", 
			COLUMN 97, "Currency", 
			COLUMN 108, "Amount" 
			PRINT COLUMN 1, "Forecast FROM ", today USING "dd/mm/yy" 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #was l_arr_line[3]
		ON EVERY ROW 

			SELECT * 
			INTO l_rec_customer.* 
			FROM customer 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cust_code = p_rec_tempdoc.tm_cust 

			PRINT COLUMN 1, p_rec_tempdoc.tm_cust, 
			COLUMN 10, p_rec_tempdoc.tm_name, 
			COLUMN 41, p_rec_tempdoc.tm_type, 
			COLUMN 45, p_rec_tempdoc.tm_doc USING "########", 
			COLUMN 56, p_rec_tempdoc.tm_date USING "dd/mm/yy", 
			COLUMN 67, p_rec_tempdoc.tm_due USING "----", 
			COLUMN 75, p_rec_tempdoc.tm_estdt USING "dd/mm/yy", 
			COLUMN 90, p_rec_tempdoc.tm_select, 
			COLUMN 99, l_rec_customer.currency_code, 
			COLUMN 105, p_rec_tempdoc.tm_unpaid USING "--,---,--$.&&", 
			COLUMN 122, p_rec_tempdoc.tm_story 
			LET modu_tot_amt = modu_tot_amt + conv_currency(p_rec_tempdoc.tm_amount, glob_rec_kandoouser.cmpy_code, 
			l_rec_customer.currency_code, "F", today, "S") 

		ON LAST ROW 
			PRINT COLUMN 1, "Totals in base currency ----------------", 
			"----------------------------------", 
			"------------------------------------------", 
			"---------------" 

			PRINT COLUMN 1, "Report Totals", 
			COLUMN 99, modu_tot_rep USING "----,---,---,--$.&&" 
			PRINT COLUMN 1, "----------------------------------------", 
			"----------------------------------", 
			"------------------------------------------", 
			"---------------" 
			SKIP 1 line 
			
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	
			
			
		BEFORE GROUP OF p_rec_tempdoc.tm_slot 
			SKIP 2 LINES 
			PRINT COLUMN 1, "Transactions Due ", p_rec_tempdoc.tm_desc 

		AFTER GROUP OF p_rec_tempdoc.tm_slot 
			PRINT COLUMN 1, "Totals in base currency ----------------", 
			"-----------------------------------", 
			"----------------------------------------", 
			"----------------" 

			PRINT COLUMN 1, "Week Total", 
			COLUMN 99, modu_tot_amt USING "----,---,---,--$.&&" 
			PRINT COLUMN 1, "----------------------------------------", 
			"--------------------------------------", 
			"-------------------------------------", 
			"----------------" 
			LET modu_tot_rep = modu_tot_rep + modu_tot_amt 
			LET modu_tot_amt = 0 
END REPORT