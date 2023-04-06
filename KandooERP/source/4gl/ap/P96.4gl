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
# \brief module P96  Tax Payment Summary & Reconciliation Reports
#
#This file IS used as GLOBALS file FROM P96b.4gl
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/P9_GROUP_GLOBALS.4gl" 
GLOBALS "../ap/P96_GLOBALS.4gl"
###########################################################################
# MODULE Scope Variables
###########################################################################


############################################################
# MODULE SCOPE VARIABLES
############################################################

############################################################
# FUNCTION P96_main()
#
#
############################################################
FUNCTION P96_main() 

	DEFER quit 
	DEFER interrupt 

--	CALL setModuleId("P96") 


	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode  
			OPEN WINDOW A202 with FORM "A202" 
			CALL winDecoration_a("A202") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title

--			DISPLAY BY NAME modu_rec_aging.*
--			DISPLAY BY NAME glob_rec_arparms.cust_age_date 

			MENU " Account Aging" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","P96","menu-tax-1") 
					CALL P96_rpt_process(P96_rpt_query())
					CALL rpt_rmsreps_reset(NULL)

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				ON ACTION "REPORT" #COMMAND "Run" " SELECT Criteria AND PRINT REPORT" 
					CALL P96_rpt_process(P96_rpt_query())
					CALL rpt_rmsreps_reset(NULL)

			END MENU 

			CLOSE WINDOW A202 

			 
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL P96_rpt_process()  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW P208 with FORM "P208" 
			CALL windecoration_p("P208") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

			CALL set_url_sel_text(P96_rpt_query()) #save where clause in env 
			CLOSE WINDOW P208 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL P96_rpt_process(get_url_sel_text())
	END CASE 

END FUNCTION 
############################################################
# END FUNCTION P96_main()
############################################################


############################################################
# FUNCTION P96_rpt_query()
#
#
############################################################
FUNCTION P96_rpt_query() 
	DEFINE l_recon_req SMALLINT 
	DEFINE l_where_text CHAR(2048) 
	DEFINE l_last_period LIKE period.period_num
	DEFINE l_msgresp LIKE language.yes_flag 


	CLEAR FORM 
	INITIALIZE glob_rec_parameters.* TO NULL 

	LET glob_rec_parameters.rrn_num = NULL 
	WHILE TRUE 

		INPUT BY NAME 
			glob_rec_parameters.tax_vend_code, 
			glob_rec_parameters.rrn_num, 
			glob_rec_parameters.sign_on_code, 
			glob_rec_parameters.year_num	WITHOUT DEFAULTS

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","P96","inp-parameters-1") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			AFTER FIELD tax_vend_code 
				IF glob_rec_parameters.tax_vend_code IS NULL THEN 
					LET l_msgresp = kandoomsg("P",9114,"") 				#9114 Tax Vendor must be entered
					NEXT FIELD tax_vend_code 
				END IF 

				SELECT name_text INTO glob_rec_parameters.name_text FROM vendor 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND vend_code = glob_rec_parameters.tax_vend_code 
				IF status = NOTFOUND THEN 
					LET l_msgresp = kandoomsg("P",9501,"") 				#9501 Vendor NOT found
					NEXT FIELD tax_vend_code 
				END IF 
				DISPLAY BY NAME glob_rec_parameters.name_text 

				SELECT unique 1 FROM vendortype 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND tax_vend_code = glob_rec_parameters.tax_vend_code 
				IF status = NOTFOUND THEN 
					LET l_msgresp = kandoomsg("P",9126,"") 				#9126 Vendor IS NOT a Tax Vendor
					NEXT FIELD tax_vend_code 
				END IF 

			AFTER FIELD rrn_num 
				IF glob_rec_parameters.rrn_num IS NULL THEN 
					LET l_msgresp = kandoomsg("U",9011,"") 				#9011 Reference Number must be entered
					NEXT FIELD rrn_num 
				END IF 

			AFTER FIELD sign_on_code 
				IF glob_rec_parameters.sign_on_code IS NOT NULL THEN 
					SELECT * FROM kandoouser 
					WHERE sign_on_code = glob_rec_parameters.sign_on_code 
					IF status = NOTFOUND THEN 
						LET l_msgresp = kandoomsg("U",9111,"User") 					#9111 User NOT found
						NEXT FIELD sign_on_code 
					END IF 
				END IF 

			AFTER FIELD year_num 
				IF glob_rec_parameters.year_num IS NULL THEN 
					LET l_msgresp = kandoomsg("U",9019,"") 				#9019 Year must be entered
					NEXT FIELD year_num 
				END IF 

				SELECT max(period_num) INTO l_last_period FROM period 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND year_num = glob_rec_parameters.year_num 
				IF status = NOTFOUND THEN 
					LET l_msgresp = kandoomsg("U",9020,"")					#9020 Financial Year NOT SET up
					NEXT FIELD year_num 
				END IF 

				SELECT end_date INTO glob_year_end_date FROM period 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND year_num = glob_rec_parameters.year_num 
				AND period_num = l_last_period 
				DISPLAY BY NAME glob_year_end_date 

			AFTER INPUT 
				IF int_flag OR quit_flag THEN 
					EXIT INPUT 
				END IF 

				IF glob_rec_parameters.tax_vend_code IS NULL THEN 
					LET l_msgresp = kandoomsg("P",9114,"") 				#9114 Tax Vendor must be entered
					NEXT FIELD tax_vend_code 
				END IF 

				SELECT name_text INTO glob_rec_parameters.name_text FROM vendor 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND vend_code = glob_rec_parameters.tax_vend_code 
				IF status = NOTFOUND THEN 
					LET l_msgresp = kandoomsg("P",9501,"") 				#9501 Vendor NOT found
					NEXT FIELD tax_vend_code 
				END IF 

				DISPLAY BY NAME glob_rec_parameters.name_text 

				SELECT unique 1 FROM vendortype 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND tax_vend_code = glob_rec_parameters.tax_vend_code 
				IF status = NOTFOUND THEN 
					LET l_msgresp = kandoomsg("P",9126,"") 				#9126 Vendor IS NOT a Tax Vendor
					NEXT FIELD tax_vend_code 
				END IF 

				IF glob_rec_parameters.rrn_num IS NULL THEN 
					LET l_msgresp = kandoomsg("U",9011,"") 				#9011 Reference Number must be entered
					NEXT FIELD rrn_num 
				END IF 

				IF glob_rec_parameters.year_num IS NULL THEN 
					LET l_msgresp = kandoomsg("U",9019,"")			#9019 Year must be entered
					NEXT FIELD year_num 
				END IF 

				SELECT unique 1 FROM period 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND year_num = glob_rec_parameters.year_num 
				IF status = NOTFOUND THEN 
					LET l_msgresp = kandoomsg("U",9020,"") 					#9020 Financial Year NOT SET up
					NEXT FIELD year_num 
				END IF 

		END INPUT 

		IF int_flag OR quit_flag THEN 
			EXIT WHILE 
		END IF 

		CONSTRUCT BY NAME l_where_text ON 
			cheque.period_num, 
			cheque.vend_code 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","P91","construct-cheque-1") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			AFTER CONSTRUCT 
				IF int_flag OR quit_flag THEN 
					EXIT CONSTRUCT 
				END IF 

				IF field_touched(vend_code) OR field_touched(period_num) THEN 
					LET l_recon_req = FALSE 
				ELSE 
					LET l_recon_req = TRUE 
				END IF 


		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = FALSE 
			LET quit_flag = FALSE 
			CONTINUE WHILE 
		END IF 
		EXIT WHILE 
	END WHILE 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN NULL 
	ELSE 
		LET glob_rec_rpt_selector.sel_option1 = glob_rec_parameters.tax_vend_code
		LET glob_rec_rpt_selector.ref1_num = glob_rec_parameters.rrn_num 
		LET glob_rec_rpt_selector.ref3_code = glob_rec_parameters.sign_on_code
		LET glob_rec_rpt_selector.ref2_code = glob_rec_parameters.year_num
		LET glob_rec_rpt_selector.ref1_ind = l_recon_req
		LET glob_rec_rpt_selector.ref1_date = today					
		RETURN l_where_text
	END IF
END FUNCTION 
############################################################
# END FUNCTION P96_rpt_query()
############################################################


############################################################
# FUNCTION P96_rpt_process(p_where_text)
#
#
############################################################
FUNCTION P96_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx] 
	DEFINE l_rec_paydetail RECORD 
		payee_vend_code LIKE vendor.vend_code, 
		cheq_date LIKE cheque.cheq_date, 
		tax_per LIKE cheque.tax_per, 
		pay_amt LIKE cheque.pay_amt, 
		net_pay_amt LIKE cheque.net_pay_amt, 
		tax_amt LIKE cheque.net_pay_amt, 
		tax_ind LIKE cheque.withhold_tax_ind 
	END RECORD 
	DEFINE l_rpt_wid LIKE rmsreps.report_width_num
	DEFINE l_recon_req SMALLINT 
	DEFINE l_prev_vendor LIKE vendor.vend_code 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start("P96-PAYD","P96_rpt_list_paydetail",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT P96_rpt_list_paydetail TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("P96_rpt_list_reconciliation")].sel_text
	#------------------------------------------------------------


	LET glob_rec_parameters.tax_vend_code = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_option1 
	LET glob_rec_parameters.rrn_num  = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref1_num
	LET glob_rec_parameters.sign_on_code = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref3_code
	LET glob_rec_parameters.year_num = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref2_code
	LET l_recon_req = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref1_ind
	#LET glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref1_date = today #HuHo ???			


	LET glob_uline4 = "----" 
	LET glob_uline4 = "--------------" 
	LET glob_uline28 = "----------------------------" 
	LET glob_uline74 = "-------------------------------------", 
	"-------------------------------------" 


	LET glob_signature_file = NULL
	 
	SELECT signature_text INTO glob_signature_file FROM kandoouser 
	WHERE sign_on_code = glob_rec_parameters.sign_on_code
	 
	SELECT * INTO glob_rec_company.* FROM company 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET l_query_text = 
	"SELECT cheque.vend_code, ", 
	"cheque.cheq_date, ", 
	"cheque.tax_per, ", 
	"cheque.pay_amt, ", 
	"cheque.net_pay_amt, ", 
	"cheque.tax_amt, ", 
	"cheque.withhold_tax_ind ", 
	"FROM vendor,cheque,vendortype ", 
	"WHERE cheque.cmpy_code = \"", glob_rec_kandoouser.cmpy_code, "\"", 
	" AND vendor.cmpy_code = \"", glob_rec_kandoouser.cmpy_code, "\"", 
	" AND vendortype.cmpy_code = \"", glob_rec_kandoouser.cmpy_code, "\"", 
	" AND cheque.vend_code = vendor.vend_code ", 
	" AND vendor.type_code = vendortype.type_code ", 
	" AND vendortype.tax_vend_code = \"", glob_rec_parameters.tax_vend_code, "\"", 
	" AND cheque.year_num = \"", glob_rec_parameters.year_num, "\"", 
	" AND cheque.whtax_rep_ind != '0'", 
	" AND ", p_where_text clipped, 
	" ORDER BY cheque.vend_code, cheque.cheq_date" 
	PREPARE s_paydetail FROM l_query_text 
	DECLARE c_paydetail CURSOR FOR s_paydetail 
	
	LET glob_payee_total = 0 
	LET glob_payee_amt_total = 0 
	LET glob_payee_tax_total = 0 

	LET l_prev_vendor = NULL
	 
	FOREACH c_paydetail INTO l_rec_paydetail.* 
		IF l_prev_vendor IS NULL OR l_prev_vendor != l_rec_paydetail.payee_vend_code THEN 
			LET l_prev_vendor = l_rec_paydetail.payee_vend_code 
		END IF 
		
		#---------------------------------------------------------
		OUTPUT TO REPORT P96_rpt_list_paydetail(l_rpt_idx,
		l_rec_paydetail.*) 
		IF NOT rpt_int_flag_handler2("Vendor:",l_rec_paydetail.payee_vend_code,NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------	
		 
	END FOREACH
	 
	#------------------------------------------------------------
	FINISH REPORT P96_rpt_list_paydetail
	CALL rpt_finish("P96_rpt_list_paydetail")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 	
	#------------------------------------------------------------
	
	##################################################################################################
	#
	# Tax Payer Reconciliation
	# IF all vendors selected, create a Payer Reconciliation REPORT
	##################################################################################################

	# IF all vendors selected, create a Payer Reconciliation REPORT
	IF l_recon_req THEN 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
--	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
--		LET int_flag = false 
--		LET quit_flag = false
--
--		RETURN FALSE
--	END IF

	LET l_rpt_idx = rpt_start("P96-REC","P96_rpt_list_reconciliation",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT P96_rpt_list_reconciliation TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

		#---------------------------------------------------------
		OUTPUT TO REPORT P96_rpt_list_reconciliation(l_rpt_idx) 
		#---------------------------------------------------------		 
	
		#------------------------------------------------------------
		FINISH REPORT P96_rpt_list_reconciliation
		CALL rpt_finish("P96_rpt_list_reconciliation")
		#------------------------------------------------------------
		 
		IF int_flag THEN 
			LET int_flag = false 
			ERROR " Printing was aborted" 
			RETURN false 
		ELSE 
			RETURN true 
		END IF 	
 
	END IF 
END FUNCTION 
############################################################
# END FUNCTION P96_rpt_process(p_where_text)
############################################################


############################################################
# REPORT P96_rpt_list_reconciliation(p_rpt_idx)
#
#
############################################################
REPORT P96_rpt_list_reconciliation(p_rpt_idx) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE l_tax_pay_total LIKE vendor.bal_amt 

	OUTPUT 


	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
		
			PRINT COLUMN 24, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			SKIP 1 line 
			PRINT COLUMN 26, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text 
			SKIP 1 line 
			PRINT COLUMN 24, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line3_text , 
			glob_year_end_date USING "dd mmm yyyy"
			 
			SKIP 2 LINES 
			PRINT COLUMN 01, "Name", 
			COLUMN 37, "Tax File Number ", glob_rec_parameters.rrn_num 
			PRINT COLUMN 01, glob_uline4 
			PRINT COLUMN 01, glob_rec_company.name_text 
			SKIP 1 line 
			PRINT COLUMN 01, glob_uline74 
			PRINT COLUMN 01, 
			"Total Gross Payments FROM Payment Summaries - ", 
			glob_payee_amt_total USING "---,---,---,--&.&&" 
			SKIP 1 line 
			PRINT COLUMN 01, 
			"Total Tax Deductions FROM Payment Summaries - ", 
			glob_payee_tax_total USING "---,---,---,--&.&&" 
			SELECT sum(net_pay_amt) 
			INTO l_tax_pay_total 
			FROM cheque 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND vend_code = glob_rec_parameters.tax_vend_code 
			AND year_num = glob_rec_parameters.year_num 
			SKIP 1 line 
			PRINT COLUMN 01, "Total Tax Paid TO Tax Office - ", 
			COLUMN 47, l_tax_pay_total USING "---,---,---,--&.&&" 
			SKIP 1 line 
			PRINT COLUMN 01, "Total Payment Summaries Included - ", 
			COLUMN 47, glob_payee_total USING "###########&"
			 
		ON LAST ROW 
			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	
			
END REPORT
############################################################
# END REPORT P96_rpt_list_reconciliation(p_rpt_idx)
############################################################