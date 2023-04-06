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
GLOBALS "../ar/AD_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/ADU_GLOBALS.4gl" 
#####################################################################
# FUNCTION ADU_main()
#
# ADU - Unapplied Credits Report
#####################################################################
FUNCTION ADU_main() 
	DEFER interrupt 
	DEFER quit 

	CALL setModuleId("ADU")  

	LET glob_temp_text = glob_rec_arparms.credit_ref1_text clipped,	"..................." 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 	
			OPEN WINDOW A121 with FORM "A121" 
			CALL windecoration_a("A121") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title

			DISPLAY glob_temp_text TO arparms.credit_ref1_text 

			MENU " Unapplied Credits" 

				BEFORE MENU 
					CALL publish_toolbar("kandoo","ADU","menu-unapplied-credits") 
					CALL ADU_rpt_process(ADU_rpt_query())
					
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				ON ACTION "Report" 	#COMMAND "Run" " Enter Selection Criteria AND generate REPORT"
					CALL ADU_rpt_process(ADU_rpt_query())

				ON ACTION "Print Manager" 	#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "Exit" 		#COMMAND KEY("E",interrupt)"Exit" " Exit TO menus"
					EXIT MENU 
			END MENU 

			CLOSE WINDOW A121 

	 
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL ADU_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW A121 with FORM "A121" 
			CALL windecoration_a("A121") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(ADU_rpt_query()) #save where clause in env 
			CLOSE WINDOW A121 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL ADU_rpt_process(get_url_sel_text())
	END CASE 

END FUNCTION 


#####################################################################
# FUNCTION ADU_rpt_query()
#
#
#####################################################################
FUNCTION ADU_rpt_query() 
	DEFINE l_where_text STRING
	
	MESSAGE kandoomsg2("U",1001,"")	#1001 "Enter Selection Criteria; OK TO Continue"
	
	CONSTRUCT l_where_text ON credithead.cust_code, 
	customer.name_text, 
	credithead.org_cust_code, 
	credithead.cred_num, 
	credithead.cred_date, 
	credithead.job_code, 
	credithead.cred_text, 
	customer.currency_code, 
	credithead.goods_amt, 
	credithead.hand_amt, 
	credithead.freight_amt, 
	credithead.tax_amt, 
	credithead.total_amt, 
	credithead.appl_amt, 
	credithead.disc_amt, 
	credithead.year_num, 
	credithead.period_num, 
	credithead.posted_flag, 
	credithead.on_state_flag, 
	credithead.cred_ind, 
	credithead.entry_code, 
	credithead.entry_date, 
	credithead.sale_code, 
	credithead.com1_text, 
	credithead.com2_text, 
	credithead.rev_date, 
	credithead.rev_num 
	FROM credithead.cust_code, 
	customer.name_text, 
	credithead.org_cust_code, 
	credithead.cred_num, 
	credithead.cred_date, 
	credithead.job_code, 
	credithead.cred_text, 
	customer.currency_code, 
	credithead.goods_amt, 
	credithead.hand_amt, 
	credithead.freight_amt, 
	credithead.tax_amt, 
	credithead.total_amt, 
	credithead.appl_amt, 
	credithead.disc_amt, 
	credithead.year_num, 
	credithead.period_num, 
	credithead.posted_flag, 
	credithead.on_state_flag, 
	credithead.cred_ind, 
	credithead.entry_code, 
	credithead.entry_date, 
	credithead.sale_code, 
	credithead.com1_text, 
	credithead.com2_text, 
	credithead.rev_date, 
	credithead.rev_num 


		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","ADU","construct-credithead") 

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




#####################################################################
# FUNCTION ADU_rpt_process(p_where_text) 
#
#
#####################################################################
FUNCTION ADU_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT  
	DEFINE l_rec_credit RECORD 
		cust_code LIKE customer.cust_code, 
		name_text LIKE customer.name_text, 
		currency_code LIKE customer.currency_code, 
		cred_num LIKE credithead.cred_num, 
		total_amt LIKE credithead.total_amt, 
		cred_date LIKE credithead.cred_date, 
		appl_num LIKE invoicepay.appl_num, 
		inv_num LIKE invoicepay.inv_num, 
		apply_num LIKE invoicepay.apply_num, 
		pay_date LIKE invoicepay.pay_date, 
		pay_amt LIKE invoicepay.pay_amt, 
		disc_amt LIKE invoicepay.disc_amt 
	END RECORD 
	DEFINE l_report_ord_flag LIKE arparms.report_ord_flag 
	DEFINE l_order_text CHAR(200) 


	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"ADU_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT ADU_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------


	#???
	SELECT report_ord_flag INTO l_report_ord_flag FROM arparms 
	WHERE arparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND arparms.parm_code = "1" 

	IF l_report_ord_flag = "C" THEN 
		LET l_order_text = " ORDER BY customer.cust_code, cred_num, apply_num" 
	ELSE 
		LET l_order_text = " ORDER BY name_text, customer.cust_code, cred_num, apply_num" 
	END IF 

	LET l_query_text = "SELECT customer.cust_code, customer.name_text, ", 
	"customer.currency_code, credithead.cred_num, ", 
	"credithead.total_amt, credithead.entry_date, ", 
	"invoicepay.appl_num, invoicepay.inv_num, ", 
	"invoicepay.apply_num, invoicepay.pay_date, ", 
	"invoicepay.pay_amt, invoicepay.disc_amt ", 
	"FROM credithead, customer, outer invoicepay ", 
	"WHERE credithead.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND customer.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND invoicepay.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND credithead.cust_code = invoicepay.cust_code ", 
	"AND credithead.cust_code = customer.cust_code ", 
	"AND credithead.appl_amt != credithead.total_amt ", 
	"AND credithead.cred_num = invoicepay.ref_num ", 
	"AND invoicepay.pay_type_ind = 'CR' AND ", 
	glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ADU_rpt_list")].sel_text clipped, l_order_text clipped 
	PREPARE s_credithead FROM l_query_text 
	DECLARE c_credithead CURSOR FOR s_credithead 

	FOREACH c_credithead INTO l_rec_credit.* 
		IF l_rec_credit.total_amt IS NULL THEN 
			LET l_rec_credit.total_amt = 0 
		END IF 
		#---------------------------------------------------------
		OUTPUT TO REPORT ADU_rpt_list(l_rpt_idx,l_rec_credit.*)  
		IF NOT rpt_int_flag_handler2("CREDIT:",l_rec_credit.cred_num, l_rec_credit.name_text,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------			
	END FOREACH 
	 
	#------------------------------------------------------------
	FINISH REPORT ADU_rpt_list
	CALL rpt_finish("ADU_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 



#####################################################################
# REPORT ADU_rpt_list(p_rpt_idx,p_rec_credit) 
#
#
#####################################################################
REPORT ADU_rpt_list(p_rpt_idx,p_rec_credit) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_credit RECORD 
		cust_code LIKE customer.cust_code, 
		name_text LIKE customer.name_text, 
		currency_code LIKE customer.currency_code, 
		cred_num LIKE credithead.cred_num, 
		total_amt LIKE credithead.total_amt, 
		cred_date LIKE credithead.cred_date, 
		appl_num LIKE invoicepay.appl_num, 
		inv_num LIKE invoicepay.inv_num, 
		apply_num LIKE invoicepay.apply_num, 
		pay_date LIKE invoicepay.pay_date, 
		pay_amt LIKE invoicepay.pay_amt, 
		disc_amt LIKE invoicepay.disc_amt 
	END RECORD
	DEFINE l_ord_num LIKE invoicehead.ord_num
	DEFINE l_cust_cred_amt LIKE invoicepay.pay_amt 

	OUTPUT 
--	left margin 0 
	ORDER external BY p_rec_credit.cust_code, 
	p_rec_credit.cred_num, 
	p_rec_credit.appl_num 
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  


		BEFORE GROUP OF p_rec_credit.cust_code 
			NEED 4 LINES 
			PRINT "" 
			PRINT "" 
			PRINT COLUMN 1, "Customer Code: ", p_rec_credit.cust_code, 
			COLUMN 25, p_rec_credit.name_text, 
			" Currency " , p_rec_credit.currency_code 
			LET l_cust_cred_amt = 0 

		BEFORE GROUP OF p_rec_credit.cred_num 
			NEED 4 LINES 
			SKIP 1 line 
			PRINT COLUMN 1, "Credit: ", p_rec_credit.cred_num USING "########", 
			COLUMN 23, "Date: ", p_rec_credit.cred_date USING "dd/mm/yyyy", 
			COLUMN 41, "Amount: ", p_rec_credit.total_amt USING "---,---,--&.&&" 
			LET l_cust_cred_amt = l_cust_cred_amt + p_rec_credit.total_amt 

		ON EVERY ROW 
			IF p_rec_credit.appl_num IS NOT NULL 
			AND p_rec_credit.cred_num IS NOT NULL THEN 
				SELECT ord_num INTO l_ord_num FROM invoicehead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cust_code = p_rec_credit.cust_code 
				AND inv_num = p_rec_credit.inv_num 
				IF status = NOTFOUND THEN 
					LET l_ord_num = NULL 
				END IF 
				PRINT COLUMN 1, p_rec_credit.appl_num USING "########", 
				COLUMN 15, p_rec_credit.pay_date USING "dd/mm/yyyy", 
				COLUMN 27, p_rec_credit.inv_num USING "########", 
				COLUMN 37, p_rec_credit.apply_num USING "######", 
				COLUMN 46, l_ord_num USING "########", 
				COLUMN 75, p_rec_credit.pay_amt USING "---,---,--&.&&" 
			END IF 

		AFTER GROUP OF p_rec_credit.cust_code 
			NEED 4 LINES 
			PRINT COLUMN 75, "============== ==============" 
			PRINT COLUMN 57, "Customer Totals:", 
			COLUMN 75, GROUP sum(p_rec_credit.pay_amt) USING "---,---,--&.&&"; 
			IF GROUP sum(p_rec_credit.pay_amt) IS NULL THEN 
				PRINT COLUMN 90, l_cust_cred_amt USING "---,---,--&.&&" 
			ELSE 
				PRINT COLUMN 90, l_cust_cred_amt - GROUP sum(p_rec_credit.pay_amt) 
				USING "---,---,--&.&&" 
			END IF 

		AFTER GROUP OF p_rec_credit.cred_num 
			NEED 4 LINES 
			PRINT COLUMN 75, "-------------- --------------" 
			PRINT COLUMN 75, GROUP sum(p_rec_credit.pay_amt) USING "---,---,--&.&&"; 
			IF GROUP sum(p_rec_credit.pay_amt) IS NULL THEN 
				PRINT COLUMN 90, p_rec_credit.total_amt USING "---,---,--&.&&" 
			ELSE 
				PRINT COLUMN 90, p_rec_credit.total_amt - GROUP sum(p_rec_credit.pay_amt) 
				USING "---,---,--&.&&" 
			END IF 

		ON LAST ROW 
			NEED 6 LINES 
			SKIP 1 line 
			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	
			 
END REPORT