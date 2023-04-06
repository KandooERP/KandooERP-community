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
GLOBALS "../ar/AB0_GLOBALS.4gl" 
GLOBALS "../ar/AB5_GLOBALS.4gl"
############################################################
# MODULE Scope Variables
############################################################
DEFINE modu_tot_amt DECIMAL(16,2) #Will be incremented/added in actual report block 
--DEFINE glob_totp_amt DECIMAL(16,2) #Will be incremented/added in actual report block 
DEFINE modu_tot_disc DECIMAL(16,2) #Will be incremented/added in actual report block
DEFINE modu_tot_paid DECIMAL(16,2) #Will be incremented/added in actual report block  
############################################################
# FUNCTION ab5_main() 
#
# Invoice Listing By Order Number
############################################################
FUNCTION ab5_main() 

	CALL setModuleId("AB5") 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 		
			OPEN WINDOW A134 with FORM "A134" 
			CALL windecoration_a("A134") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
		
			DISPLAY glob_rec_arparms.inv_ref1_text TO inv_ref1_text 
			MENU " Invoice by Order Number" 
		
				BEFORE MENU 
					CALL publish_toolbar("kandoo","AB5","menu-invoice-ORDER-number") 
					CALL rpt_rmsreps_reset(NULL) 
					CALL AB5_rpt_process(AB5_rpt_query())
					
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
					
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				ON ACTION "REPORT"	#COMMAND "Report" " SELECT criteria AND PRINT REPORT" 
					CALL rpt_rmsreps_reset(NULL)
					CALL AB5_rpt_process(AB5_rpt_query())
		
				ON ACTION "Print Manager" #COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "CANCEL" #COMMAND KEY (interrupt, "E") "Exit" " Exit TO menus" 
					EXIT MENU 
		
			END MENU 
		
			CLOSE WINDOW A134 
	 
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL AB5_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW A134 with FORM "A134" 
			CALL windecoration_a("A134") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(AB5_rpt_query()) #save where clause in env 
			CLOSE WINDOW A134 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL AB5_rpt_process(get_url_sel_text())
	END CASE 	
END FUNCTION 


############################################################
# FUNCTION AB5_rpt_query()
#
#
############################################################
FUNCTION AB5_rpt_query() 
	DEFINE l_where_text STRING

	CLEAR FORM 
	
	DISPLAY glob_rec_arparms.inv_ref1_text TO inv_ref1_text 
	MESSAGE kandoomsg2("U",1001,"") 	#1001 Enter selection criteria; OK TO continue.


	CONSTRUCT l_where_text ON invoicehead.cust_code, 
	customer.name_text, 
	invoicehead.org_cust_code, 
	invoicehead.purchase_code, 
	invoicehead.inv_num, 
	invoicehead.inv_date, 
	invoicehead.ord_num, 
	invoicehead.sale_code, 
	invoicehead.territory_code, 
	customer.currency_code, 
	invoicehead.goods_amt, 
	invoicehead.freight_amt, 
	invoicehead.hand_amt, 
	invoicehead.tax_amt, 
	invoicehead.total_amt, 
	invoicehead.paid_amt, 
	invoicehead.year_num, 
	invoicehead.period_num, 
	invoicehead.posted_flag, 
	invoicehead.post_date, 
	invoicehead.jour_num, 
	invoicehead.entry_date, 
	invoicehead.rev_date, 
	invoicehead.ship_date, 
	invoicehead.due_date, 
	invoicehead.stat_date, 
	invoicehead.paid_date 
	FROM cust_code, 
	name_text, 
	org_cust_code, 
	purchase_code, 
	inv_num, 
	inv_date, 
	ord_num, 
	sale_code, 
	territory_code, 
	currency_code, 
	goods_amt, 
	freight_amt, 
	hand_amt, 
	tax_amt, 
	total_amt, 
	paid_amt, 
	year_num, 
	period_num, 
	posted_flag, 
	post_date, 
	jour_num, 
	entry_date, 
	rev_date, 
	ship_date, 
	due_date, 
	stat_date, 
	paid_date 


		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","AB5","construct-invoicehead") 

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
# FUNCTION AB5_rpt_process(p_where_text) 
#
#
############################################################
FUNCTION AB5_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING	
	DEFINE l_rpt_idx SMALLINT  #report array index
	DEFINE l_rec_invoicehead RECORD 
		cust_code LIKE invoicehead.cust_code, 
		name_text LIKE customer.name_text, 
		currency_code LIKE customer.currency_code, 
		inv_num LIKE invoicehead.inv_num, 
		paid_date LIKE invoicehead.paid_date, 
		due_date LIKE invoicehead.due_date, 
		disc_date LIKE invoicehead.disc_date, 
		goods_amt LIKE invoicehead.goods_amt, 
		hand_amt LIKE invoicehead.hand_amt, 
		freight_amt LIKE invoicehead.freight_amt, 
		tax_amt LIKE invoicehead.tax_amt, 
		total_amt LIKE invoicehead.total_amt, 
		disc_amt LIKE invoicehead.disc_amt, 
		paid_amt LIKE invoicehead.paid_amt, 
		disc_taken_amt LIKE invoicehead.disc_taken_amt, 
		entry_code LIKE invoicehead.entry_code, 
		entry_date LIKE invoicehead.entry_date, 
		purchase_code LIKE invoicehead.purchase_code, 
		inv_date LIKE invoicehead.inv_date, 
		year_num LIKE invoicehead.year_num, 
		period_num LIKE invoicehead.period_num, 
		posted_flag LIKE invoicehead.posted_flag, 
		ord_num LIKE invoicehead.ord_num, 
		on_state_flag LIKE invoicehead.on_state_flag, 
		com1_text LIKE invoicehead.com1_text, 
		com2_text LIKE invoicehead.com2_text, 
		rev_date LIKE invoicehead.rev_date, 
		rev_num LIKE invoicehead.rev_num 
	END RECORD 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"AB5_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT AB5_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------


	LET modu_tot_amt = 0 
	LET modu_tot_paid = 0 
	LET modu_tot_disc = 0 
	CLEAR FORM 
	
	

	LET l_query_text = 
	" SELECT unique invoicehead.cust_code,customer.name_text, ", 
	" customer.currency_code, invoicehead.inv_num, ", 
	" invoicehead.paid_date, invoicehead.due_date, ", 
	" invoicehead.disc_date, invoicehead.goods_amt, ", 
	" invoicehead.hand_amt, invoicehead.freight_amt, ", 
	" invoicehead.tax_amt, invoicehead.total_amt, ", 
	" invoicehead.disc_amt, invoicehead.paid_amt, ", 
	" invoicehead.disc_taken_amt, invoicehead.entry_code, ", 
	" invoicehead.entry_date, invoicehead.purchase_code, ", 
	" invoicehead.inv_date, invoicehead.year_num, ", 
	" invoicehead.period_num, invoicehead.posted_flag, ", 
	" invoicehead.ord_num, invoicehead.on_state_flag, ", 
	" invoicehead.com1_text, invoicehead.com2_text, ", 
	" invoicehead.rev_date, invoicehead.rev_num ", 
	" FROM invoicehead , customer ", 
	" WHERE invoicehead.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
	" customer.cust_code = invoicehead.cust_code AND ", 
	" customer.cmpy_code = invoicehead.cmpy_code AND ", 
	" (invoicehead.ord_num != '0' OR ", 
	" invoicehead.ord_num IS NOT NULL) AND ", 
	glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AB5_rpt_list")].sel_text clipped, 
	" ORDER BY invoicehead.ord_num" 
	
	PREPARE choice FROM l_query_text 
	DECLARE selcurs CURSOR FOR choice 
	
	FOREACH selcurs INTO l_rec_invoicehead.* 
		#---------------------------------------------------------
		OUTPUT TO REPORT AB5_rpt_list(l_rpt_idx,
		l_rec_invoicehead.*)  
		
		IF NOT rpt_int_flag_handler2("Customer:",l_rec_invoicehead.cust_code, l_rec_invoicehead.name_text,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------		
	END FOREACH 
	 
	#------------------------------------------------------------
	FINISH REPORT AB5_rpt_list
	CALL rpt_finish("AB5_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 


###########################################################################
# REPORT AB5_rpt_list(p_rec_invoicehead)
#
#
###########################################################################
REPORT AB5_rpt_list(p_rpt_idx,p_rec_invoicehead) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE p_rec_invoicehead RECORD 
		cust_code LIKE invoicehead.cust_code, 
		name_text LIKE customer.name_text, 
		currency_code LIKE customer.currency_code, 
		inv_num LIKE invoicehead.inv_num, 
		paid_date LIKE invoicehead.paid_date, 
		due_date LIKE invoicehead.due_date, 
		disc_date LIKE invoicehead.disc_date, 
		goods_amt LIKE invoicehead.goods_amt, 
		hand_amt LIKE invoicehead.hand_amt, 
		freight_amt LIKE invoicehead.freight_amt, 
		tax_amt LIKE invoicehead.tax_amt, 
		total_amt LIKE invoicehead.total_amt, 
		disc_amt LIKE invoicehead.disc_amt, 
		paid_amt LIKE invoicehead.paid_amt, 
		disc_taken_amt LIKE invoicehead.disc_taken_amt, 
		entry_code LIKE invoicehead.entry_code, 
		entry_date LIKE invoicehead.entry_date, 
		purchase_code LIKE invoicehead.purchase_code, 
		inv_date LIKE invoicehead.inv_date, 
		year_num LIKE invoicehead.year_num, 
		period_num LIKE invoicehead.period_num, 
		posted_flag LIKE invoicehead.posted_flag, 
		ord_num LIKE invoicehead.ord_num, 
		on_state_flag LIKE invoicehead.on_state_flag, 
		com1_text LIKE invoicehead.com1_text, 
		com2_text LIKE invoicehead.com2_text, 
		rev_date LIKE invoicehead.rev_date, 
		rev_num LIKE invoicehead.rev_num 
	END RECORD
	DEFINE l_len INTEGER 
	DEFINE l_s INTEGER
	DEFINE l_line1 NCHAR(130) 
	DEFINE l_line2 NCHAR(130) 
		
	OUTPUT 
	left margin 0 
	
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 1, "Order ", 
			COLUMN 10, "Customer", 
			COLUMN 20, "Invoice", 
			COLUMN 28, "Currency", 
			COLUMN 39, glob_rec_arparms.inv_ref2a_text, 
			COLUMN 61, " Date", 
			COLUMN 69, "Year", 
			COLUMN 74, "Period", 
			COLUMN 88, "Total", 
			COLUMN 101, "Discount", 
			COLUMN 119, "Paid", 
			COLUMN 125, "Posted" 
			PRINT COLUMN 1, "Number ", 
			COLUMN 12, "Code", 
			COLUMN 39, glob_rec_arparms.inv_ref2b_text, 
			COLUMN 87, "Invoice", 
			COLUMN 101, "Possible", 
			COLUMN 118, "Amount", 
			COLUMN 126, " (GL) " 
			
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  
			
		ON EVERY ROW 
			IF p_rec_invoicehead.disc_amt IS NULL THEN 
				LET p_rec_invoicehead.disc_amt = 0 
			END IF 
			PRINT COLUMN 1, p_rec_invoicehead.ord_num USING "########", 
			COLUMN 10, p_rec_invoicehead.cust_code, 
			COLUMN 20, p_rec_invoicehead.inv_num USING "########", 
			COLUMN 30, p_rec_invoicehead.currency_code , 
			COLUMN 39, p_rec_invoicehead.purchase_code, 
			COLUMN 60, p_rec_invoicehead.inv_date USING "dd/mm/yy", 
			COLUMN 69, p_rec_invoicehead.year_num USING "####", 
			COLUMN 76, p_rec_invoicehead.period_num USING "##", 
			COLUMN 80, p_rec_invoicehead.total_amt USING "---,---,--&.&&", 
			COLUMN 95, p_rec_invoicehead.disc_amt USING "---,---,--&.&&", 
			COLUMN 110, p_rec_invoicehead.paid_amt USING "---,---,--&.&&", 
			COLUMN 129, p_rec_invoicehead.posted_flag 
			LET modu_tot_amt = modu_tot_amt + conv_currency(p_rec_invoicehead.total_amt, glob_rec_kandoouser.cmpy_code, 
			p_rec_invoicehead.currency_code, "F", p_rec_invoicehead.inv_date, "l_s") 
			LET modu_tot_disc = modu_tot_disc + conv_currency(p_rec_invoicehead.disc_amt, glob_rec_kandoouser.cmpy_code, 
			p_rec_invoicehead.currency_code, "F", p_rec_invoicehead.inv_date, "l_s") 
			LET modu_tot_paid = modu_tot_paid + conv_currency(p_rec_invoicehead.paid_amt, glob_rec_kandoouser.cmpy_code, 
			p_rec_invoicehead.currency_code, "F", p_rec_invoicehead.inv_date, "l_s") 
			
		ON LAST ROW 
			NEED 6 LINES 
			SKIP 1 line 
			PRINT COLUMN 1, rpt_get_char_line(p_rpt_idx,NULL,"-") 
			PRINT COLUMN 1, "Report Totals In Base Currency:" 
			PRINT COLUMN 1, "Invoices:", count(*) USING "######", 
			COLUMN 83, modu_tot_amt USING "---,---,--&.&&", 
			COLUMN 95, modu_tot_disc USING "---,---,--&.&&", 
			COLUMN 111, modu_tot_paid USING "---,---,--&.&&" 
			SKIP 1 line 
			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = pageno
END REPORT