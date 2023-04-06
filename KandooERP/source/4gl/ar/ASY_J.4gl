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
############################################################
# Module Scope Variables
############################################################
DEFINE modu_intrate DECIMAL(10,2) 
DEFINE modu_interest_rate DECIMAL(9,1) 
DEFINE modu_proposed_date DATE 
DEFINE modu_days INTEGER 
DEFINE modu_header_text CHAR(40) 
DEFINE modu_input_year SMALLINT 
DEFINE modu_input_period SMALLINT 
DEFINE modu_report_type CHAR(1) 
####################################################################################
# FUNCTION ASY_J_main()
#
#
####################################################################################
FUNCTION ASY_J_main() 
	DEFER QUIT 
	DEFER INTERRUPT 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

	CALL setModuleId("ASY_J") 

	LET modu_header_text = "Credit Note Listing" 

	CREATE temp TABLE t_debttype( 
		debt_type_code CHAR(3), 
		desc_text CHAR(30), 
		total_amt dec(16,2)) with no LOG 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 	
			OPEN WINDOW A663 with FORM "A663" 
			CALL windecoration_a("A663") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title
		
			DISPLAY modu_header_text TO header_text attribute(white) 
		
			MENU " Credit Notes " 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","ASY_J","menu-credit-notes") 
					CALL ASY_J_rpt_process(ASY_J_rpt_query())
					CALL rpt_rmsreps_reset(NULL)
		
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				ON ACTION "Report" 	#COMMAND "Report" " SELECT criteria AND PRINT REPORT"
					CALL ASY_J_rpt_process(ASY_J_rpt_query())
					CALL rpt_rmsreps_reset(NULL)
		
				ON ACTION "Print Manager" #COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "Exit" 	#COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus"
					EXIT MENU 
			END MENU 
			CLOSE WINDOW A663 

	 
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL ASY_J_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW A663 with FORM "A663" 
			CALL windecoration_a("A663") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(ASY_J_rpt_query()) #save where clause in env 
			CLOSE WINDOW A663 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL ASY_J_rpt_process(get_url_sel_text())
	END CASE
	
END FUNCTION



####################################################################################
# FUNCTION ASY_J_rpt_query()
#
#
####################################################################################
FUNCTION ASY_J_rpt_query() 
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE l_rec_period RECORD LIKE period.* 
	DEFINE l_rec_credithead RECORD LIKE credithead.* 
	DEFINE l_rec_credit	RECORD 
		cust_code LIKE credithead.cust_code, 
		cred_date LIKE credithead.cred_date, 
		cred_num LIKE credithead.cred_num, 
		year_num LIKE credithead.year_num, 
		period_num LIKE credithead.period_num, 
		pay_amt LIKE invoicepay.pay_amt, 
		inv_date LIKE invoicehead.inv_date, 
		inv_num LIKE invoicehead.inv_num, 
		inv_year_num LIKE invoicehead.year_num, 
		inv_period_num LIKE invoicehead.period_num, 
		inv_debt_type LIKE invoicehead.purchase_code 
	END RECORD 
	--DEFINE glob_rec_rmsreps.file_text CHAR(50) 
	DEFINE l_exp_date DATE 
	DEFINE l_query_text CHAR(3000) 
	DEFINE l_msgresp LIKE language.yes_flag 

	CLEAR FORM 
	DISPLAY modu_header_text TO header_text attribute(white) 
	DELETE FROM t_debttype 
	
	#CALL rpt_rmsreps_set_page_num(0)
	LET l_rec_credithead.year_num = YEAR(TODAY) 
	LET l_rec_credithead.period_num = 1 
	LET modu_proposed_date = NULL 
	LET modu_interest_rate = NULL 
	LET l_msgresp=kandoomsg("W",1001,"") 

	#1001 " Enter criteria FOR selection - ESC TO begin search"
	INPUT l_rec_credithead.year_num, l_rec_credithead.period_num WITHOUT DEFAULTS 
	FROM year_num, period_num


		BEFORE INPUT 
			CALL publish_toolbar("kandoo","ASY_J","inp-credithead") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER FIELD year_num 
			IF l_rec_credithead.year_num IS NULL 
			OR l_rec_credithead.year_num = 0 THEN 
				LET l_msgresp=kandoomsg("U",9019,"") 
				#9019 Year must be entered
				NEXT FIELD year_num 
			END IF 

		AFTER FIELD period_num 
			IF l_rec_credithead.period_num IS NULL 
			OR l_rec_credithead.period_num = 0 THEN 
				LET l_msgresp=kandoomsg("I",9121,"") 
				#9019 period must be entered
				NEXT FIELD period_num 
			END IF 
			IF l_rec_credithead.year_num < 1996 THEN 
				LET l_msgresp=kandoomsg("G",9012," ") 
				#9012 Fiscal year AND period invalid
				NEXT FIELD year_num 
			END IF 
			SELECT (end_date + 10) INTO l_exp_date FROM period 
			WHERE period_num = l_rec_credithead.period_num 
			AND year_num = l_rec_credithead.year_num 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF status = NOTFOUND THEN 
				LET l_exp_date = NULL 
			END IF 
			LET modu_proposed_date = l_exp_date 
			DISPLAY modu_proposed_date TO proposed_date 

		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN 
				IF l_rec_credithead.year_num IS NULL 
				OR l_rec_credithead.year_num = 0 THEN 
					LET l_msgresp=kandoomsg("U",9019,"") 
					#9019 Year must be entered
					NEXT FIELD year_num 
				END IF 
				IF l_rec_credithead.period_num IS NULL 
				OR l_rec_credithead.period_num = 0 THEN 
					LET l_msgresp=kandoomsg("I",9121,"") 
					#9019 period must be entered
					NEXT FIELD period_num 
				END IF 
				IF l_rec_credithead.year_num < 1996 THEN 
					LET l_msgresp=kandoomsg("G",9012," ") 
					#9012 Fiscal year AND period invalid
					NEXT FIELD year_num 
				END IF 
			END IF 


	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 



	LET modu_report_type = fgl_winbutton("Report Type", "GE OR Non-GE credits?", "GE", "GE|Non-GE", "question", 1) 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL
	ELSE
		LET glob_rec_rpt_selector.ref1_num = l_rec_credithead.year_num
		LET glob_rec_rpt_selector.ref2_num = l_rec_credithead.period_num
		LET glob_rec_rpt_selector.ref1_ind = modu_report_type	

		LET glob_rec_rpt_selector.ref1_date = l_exp_date	
		LET glob_rec_rpt_selector.ref2_date = modu_proposed_date	
		LET glob_rec_rpt_selector.ref1_per = modu_interest_rate					

		RETURN "1=1" 
	END IF 

END FUNCTION


####################################################################################
# FUNCTION ASY_J_rpt_process()
#
#
####################################################################################
FUNCTION ASY_J_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING 
	DEFINE l_rpt_idx SMALLINT  
	DEFINE l_rec_period RECORD LIKE period.* 
	DEFINE l_rec_credithead RECORD LIKE credithead.* 
	DEFINE l_rec_credit	RECORD 
		cust_code LIKE credithead.cust_code, 
		cred_date LIKE credithead.cred_date, 
		cred_num LIKE credithead.cred_num, 
		year_num LIKE credithead.year_num, 
		period_num LIKE credithead.period_num, 
		pay_amt LIKE invoicepay.pay_amt, 
		inv_date LIKE invoicehead.inv_date, 
		inv_num LIKE invoicehead.inv_num, 
		inv_year_num LIKE invoicehead.year_num, 
		inv_period_num LIKE invoicehead.period_num, 
		inv_debt_type LIKE invoicehead.purchase_code 
	END RECORD 
	--DEFINE glob_rec_rmsreps.file_text CHAR(50) 
	DEFINE l_exp_date DATE 

	#DISPLAY modu_header_text TO header_text attribute(white) 
	DELETE FROM t_debttype 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"ASY_J_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT ASY_J_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------

	LET l_rec_credithead.year_num = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref1_num 
	LET l_rec_credithead.period_num = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref2_num 
	LET modu_report_type = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref1_ind 	
	LET l_exp_date = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref1_date
	LET modu_proposed_date = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref2_date
	LET modu_interest_rate = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref1_per
	#------------------------------------------------------------
	


	IF modu_report_type = "G" THEN 
		LET l_query_text = 
		"SELECT invoicepay.cust_code, credithead.cred_date, ", 
		"invoicepay.ref_num, credithead.year_num, ", 
		"credithead.period_num, invoicepay.pay_amt, ", 
		"invoicehead.inv_date, invoicepay.inv_num, ", 
		"invoicehead.year_num, invoicehead.period_num, ", 
		"invoicehead.purchase_code ", 
		"FROM credithead, invoicepay, invoicehead ", 
		"WHERE invoicehead.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND invoicepay.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND credithead.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND invoicepay.pay_type_ind = 'CR' ", 
		"AND (invoicepay.rev_flag <> 'Y' ", 
		" OR invoicepay.rev_flag IS NULL) ", 
		"AND (invoicepay.inv_num = invoicehead.inv_num ", 
		"AND invoicehead.year_num < 1996) ", 
		"AND (invoicepay.ref_num = credithead.cred_num ", 
		"AND (credithead.year_num = ",l_rec_credithead.year_num," ", 
		"AND credithead.period_num = ",l_rec_credithead.period_num,")) ", 
		"ORDER BY invoicepay.cust_code, invoicepay.ref_num, ", 
		"invoicepay.inv_num" 
	ELSE 
		LET l_query_text = 
		"SELECT invoicepay.cust_code, credithead.cred_date, ", 
		"invoicepay.ref_num, credithead.year_num, ", 
		"credithead.period_num, invoicepay.pay_amt, ", 
		"invoicehead.inv_date, invoicepay.inv_num, ", 
		"invoicehead.year_num, invoicehead.period_num, ", 
		"invoicehead.purchase_code ", 
		"FROM credithead, invoicepay, invoicehead ", 
		"WHERE invoicehead.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND invoicepay.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND credithead.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND invoicepay.pay_type_ind = 'CR' ", 
		"AND (invoicepay.rev_flag <> 'Y' ", 
		" OR invoicepay.rev_flag IS NULL) ", 
		"AND (invoicepay.ref_num = credithead.cred_num ", 
		"AND credithead.year_num < 1996) ", 
		"AND (invoicepay.inv_num = invoicehead.inv_num ", 
		"AND (invoicehead.year_num = ",l_rec_credithead.year_num," ", 
		"AND invoicehead.period_num = ",l_rec_credithead.period_num,")) ", 
		"ORDER BY invoicepay.cust_code, invoicepay.ref_num, ", 
		"invoicepay.inv_num" 
	END IF 

	PREPARE s_credit FROM l_query_text 
	DECLARE c_credit CURSOR FOR s_credit
	
	#------------------------------------------------------------
	IF glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_text IS NULL THEN 
		LET glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_text = "Credit Note Report Listing - ", 
		l_rec_credithead.year_num USING "&&&&","/", 
		l_rec_credithead.period_num USING "&&" 
	END IF 
	IF modu_report_type = "G" THEN 
		LET glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_text = "Post-GE ", glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_text clipped 
	ELSE 
		LET glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_text = "Pre-GE ", glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_text clipped 
	END IF 

	LET modu_input_year = l_rec_credithead.year_num 
	LET modu_input_period = l_rec_credithead.period_num 
 

	OPEN WINDOW A952 with FORM "A952" 
	CALL windecoration_a("A952") 

	#DISPLAY "Reporting on Credits  : " AT 1,2
	CALL displayModuleTitle("Reporting on Credits") 
	CALL ui.interface.refresh() 

	FOREACH c_credit INTO l_rec_credit.* 
		#---------------------------------------------------------
		OUTPUT TO REPORT ASY_J_rpt_list(l_rpt_idx,
		l_rec_credit.*) 
		IF NOT rpt_int_flag_handler2("Credit Num:",l_rec_credit.cred_num, NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT ASY_J_rpt_list
	CALL rpt_finish("ASY_J_rpt_list")
	#------------------------------------------------------------

	CLOSE WINDOW A952 
		 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 



####################################################################################
# REPORT ASY_J_rpt_list(p_rpt_idx,p_rec_credit)
#
#
####################################################################################
REPORT ASY_J_rpt_list(p_rpt_idx,p_rec_credit) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE p_rec_credit 
	RECORD 
		cust_code LIKE credithead.cust_code, 
		cred_date LIKE credithead.cred_date, 
		cred_num LIKE credithead.cred_num, 
		ca_year_num LIKE credithead.year_num, 
		period_num LIKE credithead.period_num, 
		pay_amt LIKE invoicepay.pay_amt, 
		inv_date LIKE invoicehead.inv_date, 
		inv_num LIKE invoicehead.inv_num, 
		inv_year_num LIKE invoicehead.year_num, 
		inv_period_num LIKE invoicehead.period_num, 
		inv_debt_type LIKE invoicehead.purchase_code 
	END RECORD 
	DEFINE l_name_text LIKE customer.name_text 
	DEFINE l_debt_type_code LIKE jmj_debttype.debt_type_code 
	DEFINE l_desc_text CHAR(30) 
	DEFINE l_total_amt DECIMAL(16,2) 
	DEFINE l_need_lines SMALLINT 

	OUTPUT 
--	left margin 1 
	ORDER external BY p_rec_credit.cust_code 

	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			
			PRINT COLUMN 01, "Credit ", 
			COLUMN 14, "Credit ", 
			COLUMN 26, "Credit ", 
			COLUMN 40, "Invoice", 
			COLUMN 50, "Invoice", 
			COLUMN 60, "Debt", 
			COLUMN 69, "Invoice", 
			COLUMN 99, "Applied" 

			PRINT COLUMN 02, "Date", 
			COLUMN 15, "Number", 
			COLUMN 24, "Year/Period", 
			COLUMN 41, "Date", 
			COLUMN 51, "Number", 
			COLUMN 60, "Type", 
			COLUMN 67, "Year/Period", 
			COLUMN 100, "Amount" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		BEFORE GROUP OF p_rec_credit.cust_code 
			INITIALIZE l_name_text TO NULL 
			SELECT name_text INTO l_name_text FROM customer 
			WHERE cust_code = p_rec_credit.cust_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			SKIP 1 line 
			PRINT COLUMN 01, "Customer: ", 
			COLUMN 10, p_rec_credit.cust_code, 
			COLUMN 25, l_name_text 

		AFTER GROUP OF p_rec_credit.cust_code 
			PRINT COLUMN 01, "============================================", 
			"========================================", 
			"==================================" 
			PRINT COLUMN 01, "Totals FOR ", 
			COLUMN 10, p_rec_credit.cust_code, 
			COLUMN 25, l_name_text, 
			COLUMN 88, GROUP sum(p_rec_credit.pay_amt) USING "--,---,---,--&.&&" 

			PRINT COLUMN 01, "============================================", 
			"========================================", 
			"==================================" 

		ON EVERY ROW 
			PRINT COLUMN 01, p_rec_credit.cred_date USING "dd/mm/yy", 
			COLUMN 13, p_rec_credit.cred_num USING "#######&", 
			COLUMN 26, p_rec_credit.ca_year_num USING "&&&&", 
			COLUMN 30, p_rec_credit.period_num USING "/&&", 
			COLUMN 39, p_rec_credit.inv_date USING "dd/mm/yy", 
			COLUMN 49, p_rec_credit.inv_num USING "#######&", 
			COLUMN 60, p_rec_credit.inv_debt_type[1,3], 
			COLUMN 69, p_rec_credit.inv_year_num USING "&&&&", 
			COLUMN 73, p_rec_credit.inv_period_num USING "/&&", 
			COLUMN 88, p_rec_credit.pay_amt USING "--,---,---,--&.&&" 
			IF p_rec_credit.inv_debt_type IS NULL THEN 
				LET l_debt_type_code = " " 
			ELSE 
				LET l_debt_type_code = p_rec_credit.inv_debt_type[1,3] 
			END IF 
			IF p_rec_credit.pay_amt IS NULL THEN 
				LET l_total_amt = 0 
			ELSE 
				LET l_total_amt = p_rec_credit.pay_amt 
			END IF 
			UPDATE t_debttype 
			SET total_amt = total_amt + l_total_amt 
			WHERE debt_type_code = l_debt_type_code 
			IF sqlca.sqlerrd[3] = 0 THEN 
				SELECT desc_text INTO l_desc_text 
				FROM jmj_debttype 
				WHERE debt_type_code = l_debt_type_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = NOTFOUND THEN 
					LET l_desc_text = "*Unknown Debt Type*" 
				END IF 
				INSERT INTO t_debttype VALUES (l_debt_type_code, 
				l_desc_text, 
				l_total_amt 
				) 
			END IF 

		ON LAST ROW 
			SELECT count(*) 
			INTO l_need_lines 
			FROM t_debttype 
			IF l_need_lines IS NULL THEN 
				LET l_need_lines = 0 
			END IF 
			LET l_need_lines = l_need_lines + 5 
			NEED l_need_lines LINES 
			SKIP 1 line 
			PRINT COLUMN 01, "Report Totals: Debt Type", 
			COLUMN 26, "Description" 
			DECLARE c_debttype CURSOR FOR 
			SELECT * FROM t_debttype 
			ORDER BY debt_type_code 
			FOREACH c_debttype INTO l_debt_type_code, 
				l_desc_text, 
				l_total_amt 
				PRINT COLUMN 16, l_debt_type_code, 
				COLUMN 26, l_desc_text, 
				COLUMN 88, l_total_amt USING "--,---,---,--&.&&" 
			END FOREACH 
			PRINT COLUMN 88, "-----------------" 
			PRINT COLUMN 88, sum (p_rec_credit.pay_amt) USING "--,---,---,--&.&&" 
			SKIP 2 line 
			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			
END REPORT 



