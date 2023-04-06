{
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
}
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl"
GLOBALS "../ar/AB_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/AB0_GLOBALS.4gl" 
############################################################
# MODULE Scope Variables
############################################################
#DEFINE
#glob_rec_arparms record
#   inv_ref1_text LIKE arparms.inv_ref1_text,
#   inv_ref2a_text LIKE arparms.inv_ref2a_text,
#   inv_ref2b_text LIKE arparms.inv_ref2b_text
#END RECORD
############################################################
# FUNCTION ab4_main()
#
# Invoice Listing By P.O.
############################################################
FUNCTION ab4_main() 

	CALL setModuleId("AB4") 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 	
			OPEN WINDOW A135 with FORM "A135" 
			CALL windecoration_a("A135") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
		
			DISPLAY glob_rec_arparms.inv_ref2a_text TO inv_ref2a_text
			DISPLAY glob_rec_arparms.inv_ref2b_text TO inv_ref2b_text 
		
			MENU " Invoice Report" 
		
				BEFORE MENU 
					CALL publish_toolbar("kandoo","AB4","menu-invoice-REPORT") 
					CALL AB4_rpt_process(AB4_rpt_query())
					CALL rpt_rmsreps_reset(NULL)
					
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				COMMAND "REPORT" " SELECT criteria AND PRINT REPORT" 
					CALL AB4_rpt_process(AB4_rpt_query())
					CALL rpt_rmsreps_reset(NULL)
		
				ON ACTION "PRINT MANAGER" --	#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 		
	
				ON ACTION "CANCEL" --COMMAND KEY (interrupt, "E") "Exit" " Exit TO menus"
					EXIT MENU 
		
			END MENU 
		
			CLOSE WINDOW A135 
	 
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL AB4_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW A135 with FORM "A135" 
			CALL windecoration_a("A135") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(AB4_rpt_query()) #save where clause in env 
			CLOSE WINDOW A135 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL AB4_rpt_process(get_url_sel_text())
	END CASE 
END FUNCTION 


############################################################
# FUNCTION AB4_rpt_query() 
#
#
############################################################
FUNCTION AB4_rpt_query() 
	DEFINE l_where_text STRING
	DEFINE l_rec_invoicehead RECORD 
		cust_code LIKE invoicehead.cust_code, 
		name_text LIKE customer.name_text, 
		currency_code LIKE invoicehead.currency_code, 
		inv_num LIKE invoicehead.inv_num, 
		purchase_code LIKE invoicehead.purchase_code, 
		job_code LIKE invoicehead.job_code, 
		inv_date LIKE invoicehead.inv_date, 
		year_num LIKE invoicehead.year_num, 
		period_num LIKE invoicehead.period_num, 
		total_amt LIKE invoicehead.total_amt, 
		disc_amt LIKE invoicehead.disc_amt, 
		paid_amt LIKE invoicehead.paid_amt, 
		posted_flag LIKE invoicehead.posted_flag 
	END RECORD 


	CLEAR FORM 
	DISPLAY glob_rec_arparms.inv_ref2a_text TO inv_ref2a_text
	DISPLAY glob_rec_arparms.inv_ref2b_text TO inv_ref2b_text 

	MESSAGE kandoomsg2("U",1001,"") 

	CONSTRUCT BY NAME l_where_text ON invoicehead.cust_code, 
	customer.name_text, 
	customer.currency_code, 
	invoicehead.inv_num, 
	invoicehead.purchase_code, 
	invoicehead.inv_date, 
	invoicehead.year_num, 
	invoicehead.period_num, 
	invoicehead.total_amt, 
	invoicehead.paid_amt, 
	invoicehead.posted_flag 


		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","AB4","construct-invoicehead") 

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


############################################################
# FUNCTION AB4_rpt_query() 
#
#
############################################################
FUNCTION AB4_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT  
--	DEFINE l_title_text CHAR(60) 
	DEFINE l_rec_invoicehead RECORD 
		cust_code LIKE invoicehead.cust_code, 
		name_text LIKE customer.name_text, 
		currency_code LIKE invoicehead.currency_code, 
		inv_num LIKE invoicehead.inv_num, 
		purchase_code LIKE invoicehead.purchase_code, 
		job_code LIKE invoicehead.job_code, 
		inv_date LIKE invoicehead.inv_date, 
		year_num LIKE invoicehead.year_num, 
		period_num LIKE invoicehead.period_num, 
		total_amt LIKE invoicehead.total_amt, 
		disc_amt LIKE invoicehead.disc_amt, 
		paid_amt LIKE invoicehead.paid_amt, 
		posted_flag LIKE invoicehead.posted_flag 
	END RECORD 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"AB4_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT AB4_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text	
	#------------------------------------------------------------

	LET l_query_text = 
	"SELECT unique invoicehead.cust_code,customer.name_text,customer.currency_code, invoicehead.inv_num,invoicehead.purchase_code,invoicehead.job_code,invoicehead.inv_date, invoicehead.year_num, invoicehead.period_num, invoicehead.total_amt, ", 
	"invoicehead.disc_amt, invoicehead.paid_amt, invoicehead.posted_flag FROM invoicehead , customer WHERE invoicehead.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\"", 
	"AND customer.cmpy_code = invoicehead.cmpy_code AND customer.cust_code = invoicehead.cust_code AND ",
	glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AB4_rpt_list")].sel_text clipped, 
	" ORDER BY invoicehead.cust_code, invoicehead.purchase_code" 

	PREPARE choice FROM l_query_text 
	DECLARE selcurs CURSOR FOR choice 

	FOREACH selcurs INTO l_rec_invoicehead.* 
		#---------------------------------------------------------
		OUTPUT TO REPORT AB4_rpt_list(l_rpt_idx,l_rec_invoicehead.*)  
		
		IF NOT rpt_int_flag_handler2("Invoice:",l_rec_invoicehead.inv_num, l_rec_invoicehead.name_text,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------

	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT AB4_rpt_list
	CALL rpt_finish("AB4_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF  
END FUNCTION 


############################################################
# REPORT AB4_rpt_list(p_rpt_idx,p_rec_invoicehead) 
#
# RETURN VOID
############################################################
REPORT AB4_rpt_list(p_rpt_idx,p_rec_invoicehead) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE p_rec_invoicehead RECORD 
		cust_code LIKE invoicehead.cust_code, 
		name_text LIKE customer.name_text, 
		currency_code LIKE customer.currency_code, 
		inv_num LIKE invoicehead.inv_num, 
		purchase_code LIKE invoicehead.purchase_code, 
		job_code LIKE invoicehead.job_code, 
		inv_date LIKE invoicehead.inv_date, 
		year_num LIKE invoicehead.year_num, 
		period_num LIKE invoicehead.period_num, 
		total_amt LIKE invoicehead.total_amt, 
		disc_amt LIKE invoicehead.disc_amt, 
		paid_amt LIKE invoicehead.paid_amt, 
		posted_flag LIKE invoicehead.posted_flag 
	END RECORD 
	
	OUTPUT 
--	left margin 0 
	ORDER external BY p_rec_invoicehead.cust_code, p_rec_invoicehead.purchase_code 

	FORMAT 


		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 1, "Invoice", 
			COLUMN 10, "Purchase", 
			COLUMN 25, "Name", 
			COLUMN 50, " Date", 
			COLUMN 59, "Year", 
			COLUMN 64, "Period", 
			COLUMN 76, "Total", 
			COLUMN 89, "Discount", 
			COLUMN 106, "Paid", 
			COLUMN 112, "Posted" 

			PRINT COLUMN 1, "Number", 
			COLUMN 12, "Code", 
			COLUMN 75, "Invoice", 
			COLUMN 89, "Possible", 
			COLUMN 105, "Amount" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		ON EVERY ROW 
			PRINT COLUMN 01, p_rec_invoicehead.inv_num USING "########", 
			COLUMN 10, p_rec_invoicehead.purchase_code, 
			COLUMN 50, p_rec_invoicehead.inv_date USING "dd/mm/yy", 
			COLUMN 59, p_rec_invoicehead.year_num USING "####", 
			COLUMN 65, p_rec_invoicehead.period_num USING "##", 
			COLUMN 68, p_rec_invoicehead.total_amt USING "---,---,---.&&", 
			COLUMN 83, p_rec_invoicehead.disc_amt USING "---,---,---.&&", 
			COLUMN 98, p_rec_invoicehead.paid_amt USING "---,---,---.&&", 
			COLUMN 115, p_rec_invoicehead.posted_flag 


		ON LAST ROW 
			SKIP 1 line 
			SKIP 1 line 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = pageno 


		BEFORE GROUP OF p_rec_invoicehead.cust_code 
			SKIP 2 LINES 
			PRINT COLUMN 2, "Customer : ", 
			p_rec_invoicehead.cust_code, 
			p_rec_invoicehead.name_text, 
			" Currency ", 
			p_rec_invoicehead.currency_code 
			SKIP 1 line 


		AFTER GROUP OF p_rec_invoicehead.cust_code 
			SKIP 1 line 
			PRINT COLUMN 1, " Customer Totals:" 
			PRINT COLUMN 1, "Invs:", GROUP count(*) USING "####", 
			COLUMN 21, "Avg: ", GROUP avg(p_rec_invoicehead.total_amt) 
			USING "---,---,---.&&", 
			COLUMN 68, GROUP sum(p_rec_invoicehead.total_amt) USING "---,---,---.&&", 
			COLUMN 83, GROUP sum(p_rec_invoicehead.disc_amt) USING "---,---,---.&&", 
			COLUMN 98, GROUP sum(p_rec_invoicehead.paid_amt) USING "---,---,---.&&" 
			SKIP 1 line 

END REPORT 


