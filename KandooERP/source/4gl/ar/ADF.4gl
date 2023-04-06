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
GLOBALS "../ar/ADF_GLOBALS.4gl" 
#####################################################################
# FUNCTION ADF_main()
#
# ADF Credit Applications
#####################################################################
FUNCTION ADF_main() 
	DEFER interrupt 
	DEFER quit 
	
	CALL setModuleId("ADF") 
	 
	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 	
			OPEN WINDOW A200 with FORM "A200" 
			CALL windecoration_a("A200") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title

			MENU " Credit Applications Report" 
		
				BEFORE MENU 
					CALL publish_toolbar("kandoo","ADF","menu-credit-applications-rep") 
					CALL ADF_rpt_process(ADF_rpt_query())
					
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				ON ACTION "Report" #COMMAND "Run Report" " SELECT criteria AND PRINT REPORT"
					CALL ADF_rpt_process(ADF_rpt_query())
		
				ON ACTION "Print Manager" 	#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "Exit" #COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus"
					EXIT MENU 
		
			END MENU 
		
			CLOSE WINDOW A200 
	 
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL ADF_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW A200 with FORM "A200" 
			CALL windecoration_a("A200") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(ADF_rpt_query()) #save where clause in env 
			CLOSE WINDOW A200 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL ADF_rpt_process(get_url_sel_text())
	END CASE 
	
END FUNCTION 


#####################################################################
# FUNCTION ADF_rpt_query()
#
#
#####################################################################
FUNCTION ADF_rpt_query() 
	DEFINE l_where_text STRING

	CLEAR FORM 

	MESSAGE" Enter Selection Criteria - ESC TO Continue" attribute(yellow) 

	CONSTRUCT l_where_text ON credithead.cust_code, 
	customer.name_text, 
	credithead.cred_num, 
	customer.currency_code, 
	credithead.total_amt, 
	credithead.appl_amt, 
	credithead.cred_date, 
	invoicepay.appl_num, 
	invoicepay.inv_num, 
	invoicepay.apply_num, 
	invoicepay.pay_date, 
	invoicepay.pay_amt, 
	invoicepay.disc_amt 
	FROM credithead.cust_code, 
	customer.name_text, 
	credithead.cred_num, 
	customer.currency_code, 
	credithead.total_amt, 
	credithead.appl_amt, 
	credithead.cred_date, 
	invoicepay.appl_num, 
	invoicepay.inv_num, 
	invoicepay.apply_num, 
	invoicepay.pay_date, 
	invoicepay.pay_amt, 
	invoicepay.disc_amt 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","ADF","construct-invoicepay") 

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
# FUNCTION ADF_rpt_process()
#
#
#####################################################################
FUNCTION ADF_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT 
	DEFINE l_rec_credit RECORD 
		cust_code LIKE credithead.cust_code, 
		name_text LIKE customer.name_text, 
		currency_code LIKE customer.currency_code, 
		cred_num LIKE credithead.cred_num, 
		total_amt LIKE credithead.total_amt, 
		cred_date LIKE credithead.cred_date, 
		appl_amt LIKE credithead.appl_amt, 
		appl_num LIKE invoicepay.appl_num, 
		inv_num LIKE invoicepay.inv_num, 
		apply_num LIKE invoicepay.apply_num, 
		pay_date LIKE invoicepay.pay_date, 
		pay_amt LIKE invoicepay.pay_amt, 
		disc_amt LIKE invoicepay.disc_amt 
	END RECORD 	
	
	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"ADF_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT ADF_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	 
	LET l_query_text = 
	"SELECT credithead.cust_code, customer.name_text, ", 
	" customer.currency_code, credithead.cred_num, ", 
	" credithead.total_amt, credithead.cred_date, ", 
	" credithead.appl_amt, ", 
	" invoicepay.appl_num, invoicepay.inv_num, ", 
	" invoicepay.apply_num, invoicepay.pay_date, ", 
	" invoicepay.pay_amt, invoicepay.disc_amt ", 
	" FROM credithead, invoicepay, customer ", 
	" WHERE credithead.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
	" credithead.cmpy_code = invoicepay.cmpy_code AND ", 
	" credithead.cmpy_code = customer.cmpy_code AND ", 
	" credithead.cust_code = invoicepay.cust_code AND ", 
	" credithead.cust_code = customer.cust_code AND ", 
	" credithead.cred_num = invoicepay.ref_num AND ", 
	" invoicepay.pay_type_ind = ", "\"", TRAN_TYPE_CREDIT_CR, "\"", " AND ", 
	glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ADF_rpt_list")].sel_text clipped, " ", 
	"ORDER BY credithead.cust_code, ", 
	"credithead.cred_num, invoicepay.apply_num" 
	PREPARE choice FROM l_query_text 
	DECLARE selcurs CURSOR FOR choice
	
	FOREACH selcurs INTO l_rec_credit.* 
		#---------------------------------------------------------
		OUTPUT TO REPORT ADF_rpt_list(l_rpt_idx,l_rec_credit.*)  
		IF NOT rpt_int_flag_handler2("Receipt:",l_rec_credit.cust_code, l_rec_credit.cred_num ,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------	
	END FOREACH 
	
	#------------------------------------------------------------
	FINISH REPORT ADF_rpt_list
	CALL rpt_finish("ADF_rpt_list")
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
# REPORT adf_list(p_rpt_idx,p_rec_credit)
#
#
#####################################################################
REPORT adf_list(p_rpt_idx,p_rec_credit) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_credit RECORD 
		cust_code LIKE credithead.cust_code, 
		name_text LIKE customer.name_text, 
		currency_code LIKE customer.currency_code, 
		cred_num LIKE credithead.cred_num, 
		total_amt LIKE credithead.total_amt, 
		cred_date LIKE credithead.cred_date, 
		appl_amt LIKE credithead.appl_amt, 
		appl_num LIKE invoicepay.appl_num, 
		inv_num LIKE invoicepay.inv_num, 
		apply_num LIKE invoicepay.apply_num, 
		pay_date LIKE invoicepay.pay_date, 
		pay_amt LIKE invoicepay.pay_amt, 
		disc_amt LIKE invoicepay.disc_amt 
	END RECORD 

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

			PRINT COLUMN 1, "Application", 
			COLUMN 15,"Date", 
			COLUMN 25,"Invoice", 
			COLUMN 35,"Payment", 
			COLUMN 72,"Amount ", 
			COLUMN 86,"Discount" 
			PRINT COLUMN 1, "Number", 
			COLUMN 15,"Applied", 
			COLUMN 25,"Number", 
			COLUMN 35,"Number", 
			COLUMN 72,"Applied", 
			COLUMN 86,"Given" 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]
 
		ON EVERY ROW 
			PRINT COLUMN 1, p_rec_credit.appl_num USING "####", 
			COLUMN 15, p_rec_credit.pay_date USING "dd/mm/yy", 
			COLUMN 25, p_rec_credit.inv_num USING "########", 
			COLUMN 35, p_rec_credit.apply_num USING "####", 
			COLUMN 65, p_rec_credit.pay_amt USING "---,---,--$.&&", 
			COLUMN 80, p_rec_credit.disc_amt USING "---,---,--$.&&" 

		BEFORE GROUP OF p_rec_credit.cust_code 
			SKIP 2 LINES 
			PRINT COLUMN 1, "Customer Code: ", p_rec_credit.cust_code, 
			COLUMN 28, p_rec_credit.name_text, 
			COLUMN 60,"Currency ",p_rec_credit.currency_code 

		BEFORE GROUP OF p_rec_credit.cred_num 
			SKIP 1 line 
			PRINT COLUMN 1, "Credit: ",p_rec_credit.cred_num USING "########", 
			COLUMN 20,"Date: ",p_rec_credit.pay_date USING "dd/mm/yy", 
			COLUMN 37,"Amount: ",p_rec_credit.total_amt 
			USING "---,---,--$.&&" 

		AFTER GROUP OF p_rec_credit.cust_code 
			PRINT COLUMN 65, "============== ==============" 
			PRINT COLUMN 1 , "Customer Totals:", 
			COLUMN 65, GROUP sum(p_rec_credit.pay_amt) 
			USING "---,---,--$.&&", 
			COLUMN 80, GROUP sum(p_rec_credit.disc_amt) 
			USING "---,---,--$.&&" 

		AFTER GROUP OF p_rec_credit.cred_num 
			PRINT COLUMN 65, "============== ==============" 
			PRINT COLUMN 65, GROUP sum(p_rec_credit.pay_amt) 
			USING "---,---,--$.&&", 
			COLUMN 80, GROUP sum(p_rec_credit.disc_amt) USING "---,---,--$.&&" 

		ON LAST ROW 
			SKIP 1 LINES 
			PRINT COLUMN 65, "============== ==============" 
			PRINT COLUMN 1 , "Report Totals:", 
			COLUMN 65, sum(p_rec_credit.pay_amt) USING "---,---,--$.&&", 
			COLUMN 80, sum(p_rec_credit.disc_amt) USING "---,---,--$.&&" 
			SKIP 1 LINES
			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	
			

END REPORT 