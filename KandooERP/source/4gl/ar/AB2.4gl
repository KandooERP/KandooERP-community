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
GLOBALS "../ar/AB_GROUP_GLOBALS.4gl" 
############################################################
# MODULE Scope Variables
############################################################
DEFINE modu_tot_amt DECIMAL(16,2) #Will be incremented/added in actual report block 
DEFINE modu_tot_disc DECIMAL(16,2) #Will be incremented/added in actual report block 
DEFINE modu_tot_paid DECIMAL(16,2) #Will be incremented/added in actual report block 
#####################################################################
# FUNCTION AB2_main()
#
# Invoice Listing By Number
#####################################################################
FUNCTION AB2_main()
	DEFINE l_cmd_arg STRING
	
	CALL setModuleId("AB2") 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 

			OPEN WINDOW A616 with FORM "A616" 
			CALL windecoration_a("A616") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

			DISPLAY glob_rec_arparms.inv_ref1_text  TO arparms.inv_ref1_text #label for invoice ref text

			MENU " Invoice By Number Report" 
		
				BEFORE MENU 
					CALL publish_toolbar("kandoo","AB2","menu-invoice-number")
					CALL rpt_rmsreps_reset(NULL) 
					CALL AB2_rpt_process(AB2_rpt_query())
					
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				ON ACTION "Report" #COMMAND "Run Report" " SELECT Criteria AND Print Report"
					CALL rpt_rmsreps_reset(NULL)
					CALL AB2_rpt_process(AB2_rpt_query())
		
				ON ACTION "Print Manager" #COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "CANCEL" #COMMAND KEY(interrupt,"E")"Exit" " RETURN TO Menus"
					EXIT MENU 
		
			END MENU 
		
			CLOSE WINDOW A616 
	
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL AB2_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW A616 with FORM "A616" 
			CALL windecoration_a("A616") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(AB2_rpt_query()) #save where clause in env 
			CLOSE WINDOW A616 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL AB2_rpt_process(get_url_sel_text())
	END CASE 
END FUNCTION 


#####################################################################
# FUNCTION AB2_rpt_query()
#
#
#####################################################################
FUNCTION AB2_rpt_query() 
	DEFINE l_where_text STRING
	--DEFINE l_rec_invoicehead RECORD LIKE invoicehead.*
	DEFINE l_name_text LIKE customer.name_text
	DEFINE l_i SMALLINT 
	DEFINE l_output STRING #Report output file with path
	
	MESSAGE kandoomsg2("A",1001,"") 
	#1001 Enter Selection Criteria - ESC TO Continue

	CONSTRUCT l_where_text ON invoicehead.cust_code, 
	customer.name_text, 
	invoicehead.org_cust_code, 
	o_cust.name_text, 
	customer.currency_code, 
	inv_num, 
	purchase_code, 
	inv_date, 
	year_num, 
	period_num, 
	total_amt, 
	paid_amt, 
	posted_flag 
	FROM invoicehead.cust_code, 
	customer.name_text, 
	invoicehead.org_cust_code, 
	formonly.org_name_text, 
	customer.currency_code, 
	inv_num, 
	purchase_code, 
	inv_date, 
	year_num, 
	period_num, 
	total_amt, 
	paid_amt, 
	posted_flag 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","AB2","construct-invoicehead") 

		AFTER FIELD formonly.org_name_text
			IF get_fldbuf(formonly.org_name_text) IS NOT NULL THEN
				LET glob_rec_rpt_selector.ref1_ind = "Y"
			END IF

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

		#LET glob_rec_rpt_selector.ref1_ind = "Y" in construct
		RETURN l_where_text
	END IF 
	
END FUNCTION

############################################################
# FUNCTION AB2_rpt_process(p_where_text) 
#
#
############################################################
FUNCTION AB2_rpt_process(p_where_text) 	
	DEFINE p_where_text STRING
	DEFINE l_query_text STRING
	DEFINE l_where_text STRING #special because we some operations...
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx] 
	DEFINE l_rec_invoicehead RECORD LIKE invoicehead.*
	DEFINE l_name_text LIKE customer.name_text	
	DEFINE l_col SMALLINT 
	DEFINE l_i SMALLINT
	DEFINE l_filter_with_cust_name nchar(1)
	
	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"AB2_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT AB2_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	LET l_filter_with_cust_name = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref1_ind

	LET modu_tot_amt = 0 
	LET modu_tot_paid = 0 
	LET modu_tot_disc = 0 
	
	IF l_filter_with_cust_name= "Y" THEN #IF l_where_text[l_i,l_i+5] = "o_cust" THEN 
	
		LET l_query_text = "SELECT invoicehead.*, ", 
		"customer.name_text ", 
		"FROM invoicehead, customer, customer o_cust ", 
		"WHERE invoicehead.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
		"AND customer.cust_code = invoicehead.cust_code ", 
		"AND customer.cmpy_code = invoicehead.cmpy_code ", 
		"AND o_cust.cust_code = invoicehead.org_cust_code ", 
		"AND o_cust.cmpy_code = invoicehead.cmpy_code ", 
		"AND ",glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AB2_rpt_list")].sel_text clipped," ", 
		"ORDER BY inv_num" 
	ELSE 
		LET l_query_text = "SELECT invoicehead.*, ", 
		"customer.name_text ", 
		"FROM invoicehead, customer, outer customer o_cust ", 
		"WHERE invoicehead.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
		"AND customer.cust_code = invoicehead.cust_code ", 
		"AND customer.cmpy_code = invoicehead.cmpy_code ", 
		"AND o_cust.cust_code = invoicehead.org_cust_code ", 
		"AND o_cust.cmpy_code = invoicehead.cmpy_code ", 
		"AND ",glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AB2_rpt_list")].sel_text clipped," ", 
		"ORDER BY inv_num" 
	END IF 
	
	PREPARE s_invoicehead FROM l_query_text 
	DECLARE c_invoicehead CURSOR FOR s_invoicehead 
	FOREACH c_invoicehead INTO l_rec_invoicehead.*,l_name_text 
		#---------------------------------------------------------
		OUTPUT TO REPORT AB2_rpt_list(l_rpt_idx,
		l_rec_invoicehead.*,l_name_text)  
		IF NOT rpt_int_flag_handler2("Invoice:",l_rec_invoicehead.inv_num, l_name_text,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT AB2_rpt_list
	CALL rpt_finish("AB2_rpt_list")
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
# REPORT AB2_rpt_list(p_rpt_idx,p_rec_invoicehead,p_name_text) 
#
#
#####################################################################
REPORT AB2_rpt_list(p_rpt_idx,p_rec_invoicehead,p_name_text) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_invoicehead RECORD LIKE invoicehead.* 
	DEFINE p_name_text LIKE customer.name_text 
	DEFINE l_rec_company RECORD LIKE company.* 
	DEFINE l_col SMALLINT 
	DEFINE l_i SMALLINT 
	DEFINE l_line1 NCHAR(130) 
	DEFINE l_line2 NCHAR(130) 

	OUTPUT 
--	left margin 0 
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 			
			 
			PRINT COLUMN 1, "Invoice",
			COLUMN 10, "Customer", 
			COLUMN 25, "Name", 
			COLUMN 55, "Date", 
			COLUMN 61, "Year", 
			COLUMN 66, "Period", 
			COLUMN 74, "Currency", 
			COLUMN 88, "Total", 
			COLUMN 101, "Discount", 
			COLUMN 119, "Paid", 
			COLUMN 125, "Posted" 
			
			PRINT COLUMN 1, "Number", 
			COLUMN 12, "Code", 
			COLUMN 87, "Invoice", 
			COLUMN 101, "Possible", 
			COLUMN 118, "Amount", 
			COLUMN 125, " (GL) " 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		ON EVERY ROW 
			PRINT COLUMN 1, p_rec_invoicehead.inv_num USING "########", 
			COLUMN 10, p_rec_invoicehead.cust_code, 
			COLUMN 20, p_name_text, 
			COLUMN 52, p_rec_invoicehead.inv_date USING "dd/mm/yy", 
			COLUMN 61, p_rec_invoicehead.year_num USING "####", 
			COLUMN 67, p_rec_invoicehead.period_num USING "###", 
			COLUMN 76, p_rec_invoicehead.currency_code, 
			COLUMN 80, p_rec_invoicehead.total_amt USING "---,---,---.&&", 
			COLUMN 95, p_rec_invoicehead.disc_amt USING "---,---,---.&&", 
			COLUMN 110, p_rec_invoicehead.paid_amt USING "---,---,---.&&", 
			COLUMN 128, p_rec_invoicehead.posted_flag 
			LET modu_tot_amt = modu_tot_amt + 
				conv_currency(p_rec_invoicehead.total_amt, glob_rec_kandoouser.cmpy_code, 
				p_rec_invoicehead.currency_code, "F", p_rec_invoicehead.inv_date, "S") 
			LET modu_tot_disc =	modu_tot_disc +
				conv_currency(p_rec_invoicehead.disc_amt, glob_rec_kandoouser.cmpy_code, 
				p_rec_invoicehead.currency_code, "F", p_rec_invoicehead.inv_date, "S") 
			LET modu_tot_paid =	modu_tot_paid + 
				conv_currency(p_rec_invoicehead.paid_amt, glob_rec_kandoouser.cmpy_code, 
				p_rec_invoicehead.currency_code, "F", p_rec_invoicehead.inv_date, "S") 

		ON LAST ROW 
			PRINT COLUMN 1, rpt_get_char_line(p_rpt_idx,NULL,"-") 
			PRINT COLUMN 1, "In Base Currency" 
			PRINT COLUMN 1, "Report Totals:" 
			PRINT COLUMN 1, "Invs: ", count(*) USING "<<<<<", 
			COLUMN 80, modu_tot_amt USING "---,---,---.&&", 
			COLUMN 95, modu_tot_disc USING "---,---,---.&&", 
			COLUMN 110, modu_tot_paid USING "---,---,---.&&" 
			SKIP 1 line 
			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = pageno
END REPORT