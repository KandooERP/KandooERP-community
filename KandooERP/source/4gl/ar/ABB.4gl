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
GLOBALS "../ar/ABB_GLOBALS.4gl"  
############################################################
# MODULE Scope Variables
############################################################
DEFINE modu_tot_amt DECIMAL(16,2) #Will be incremented/added in actual report block 
DEFINE modu_totp_amt DECIMAL(16,2) #Will be incremented/added in actual report block 
############################################################
# FUNCTION abb_main() 
#
# Invoice Detail Report
############################################################
FUNCTION abb_main() 

	CALL setModuleId("ABB") 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 

			OPEN WINDOW A143 with FORM "A143" 
			CALL windecoration_a("A143") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
		
		
			MENU "Invoice Detail by Product" 
		
				BEFORE MENU 
					CALL publish_toolbar("kandoo","ABB","menu-invoice-detail-product") 
					CALL ABB_rpt_process(ABB_rpt_query())
					CALL rpt_rmsreps_reset(NULL)
					
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
					
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				ON ACTION "REPORT" --COMMAND "Run Report" " SELECT criteria AND PRINT REPORT" 
					CALL ABB_rpt_process(ABB_rpt_query())
					CALL rpt_rmsreps_reset(NULL)
		
				ON ACTION "Print Manager" #COMMAND "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "CANCEL" --COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus" 
					EXIT MENU 
		
			END MENU 
		
			CLOSE WINDOW A143 
	 
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL ABB_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW A143 with FORM "A143" 
			CALL windecoration_a("A143") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(ABB_rpt_query()) #save where clause in env 
			CLOSE WINDOW A143 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL ABB_rpt_process(get_url_sel_text())
	END CASE
END FUNCTION 


############################################################
# FUNCTION abb_rpt_query()  
#
#
############################################################
FUNCTION abb_rpt_query() 
	DEFINE l_where_text STRING

	MESSAGE kandoomsg2("A",1001,"") 
	#1001 Enter criteria FOR selection - ESC TO begin search"

	IF glob_rec_company.module_text[23] = "W" THEN 
		CONSTRUCT BY NAME l_where_text ON l.cust_code, 
		c.name_text, 
		c.currency_code, 
		c.type_code, 
		i.sale_code, 
		i.year_num, 
		i.period_num, 
		l.inv_num, 
		l.cat_code, 
		part_code, 
		ware_code, 
		ship_qty, 
		line_text 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","ABB","construct-invoice") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null)
				 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END CONSTRUCT 

	ELSE 
		CONSTRUCT BY NAME l_where_text ON l.cust_code, 
		c.name_text, 
		c.currency_code, 
		c.type_code, 
		i.sale_code, 
		i.year_num, 
		i.period_num, 
		l.inv_num, 
		l.cat_code, 
		part_code, 
		ware_code, 
		ship_qty, 
		line_text, 
		unit_sale_amt 


			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","ABB","construct-invoice") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null)
				 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END CONSTRUCT 

	END IF 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL
	ELSE
		RETURN l_where_text
	END IF 
END FUNCTION

############################################################
# FUNCTION abb_rpt_query()  
#
#
############################################################
FUNCTION abb_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT 
	DEFINE l_rec_invoicedetl RECORD 
		cust_code LIKE invoicedetl.cust_code, 
		name_text LIKE customer.name_text, 
		currency_code LIKE customer.currency_code, 
		inv_num LIKE invoicedetl.inv_num, 
		inv_date LIKE invoicehead.inv_date, 
		line_num LIKE invoicedetl.line_num, 
		part_code LIKE invoicedetl.part_code, 
		ware_code LIKE invoicedetl.ware_code, 
		ord_qty LIKE invoicedetl.ord_qty, 
		ship_qty LIKE invoicedetl.ship_qty, 
		back_qty LIKE invoicedetl.back_qty, 
		line_text LIKE invoicedetl.line_text, 
		uom_code LIKE invoicedetl.uom_code, 
		unit_sale_amt LIKE invoicedetl.unit_sale_amt, 
		ext_sale_amt LIKE invoicedetl.ext_sale_amt, 
		price_uom_code LIKE invoicedetl.price_uom_code 
	END RECORD 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"ABB_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT ABB_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text	
	#------------------------------------------------------------

	
	LET modu_tot_amt = 0 

	LET l_query_text = 
	" SELECT L.cust_code,C.name_text,C.currency_code, ", 
	" L.inv_num,I.inv_date,L.line_num,L.part_code,L.ware_code, ", 
	" L.ord_qty, L.ship_qty, L.back_qty, L.line_text, L.uom_code, ", 
	" L.unit_sale_amt, L.ext_sale_amt, L.price_uom_code ", 
	" FROM invoicedetl L, customer C, invoicehead I ", 
	" WHERE L.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
	" C.cmpy_code = L.cmpy_code AND ", 
	" I.inv_num = L.inv_num AND ", 
	" I.cmpy_code = L.cmpy_code AND ", 
	" C.cust_code = L.cust_code AND ", 
	glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ABB_rpt_list")].sel_text clipped, " ", 
	"ORDER BY L.part_code, L.inv_num" 

	PREPARE choice FROM l_query_text 
	DECLARE selcurs CURSOR FOR choice 


	FOREACH selcurs INTO l_rec_invoicedetl.* 

		#---------------------------------------------------------
		OUTPUT TO REPORT ABB_rpt_list(l_rpt_idx, l_rec_invoicedetl.*)  
		IF NOT rpt_int_flag_handler2("Customer:",l_rec_invoicedetl.cust_code, l_rec_invoicedetl.name_text,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------

	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT ABB_rpt_list
	CALL rpt_finish("ABB_rpt_list")
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
# REPORT ABB_rpt_list(l_rec_invoicedetl) 
#
#
############################################################
REPORT ABB_rpt_list(p_rpt_idx,l_rec_invoicedetl) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE l_rec_invoicedetl RECORD 
		cust_code LIKE invoicedetl.cust_code, 
		name_text LIKE customer.name_text, 
		currency_code LIKE customer.currency_code, 
		inv_num LIKE invoicedetl.inv_num, 
		inv_date LIKE invoicehead.inv_date, 
		line_num LIKE invoicedetl.line_num, 
		part_code LIKE invoicedetl.part_code, 
		ware_code LIKE invoicedetl.ware_code, 
		ord_qty LIKE invoicedetl.ord_qty, 
		ship_qty LIKE invoicedetl.ship_qty, 
		back_qty LIKE invoicedetl.back_qty, 
		line_text LIKE invoicedetl.line_text, 
		uom_code LIKE invoicedetl.uom_code, 
		unit_sale_amt LIKE invoicedetl.unit_sale_amt, 
		ext_sale_amt LIKE invoicedetl.ext_sale_amt, 
		price_uom_code LIKE invoicedetl.price_uom_code 
	END RECORD
	DEFINE l_len INTEGER
	DEFINE l_s INTEGER
	DEFINE l_conversion_qty FLOAT 
	DEFINE l_line1 NCHAR(130) 
	DEFINE l_line2 NCHAR(130) 
	
	OUTPUT 
--	left margin 0 
	ORDER external BY l_rec_invoicedetl.part_code, l_rec_invoicedetl.inv_num 

	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			
			PRINT COLUMN 1, "Date", 
			COLUMN 10, "Customer", 
			COLUMN 21, "Invoice", 
			COLUMN 41, "Invoiced", 
			COLUMN 50, "Unit", 
			COLUMN 56, "Description", 
			COLUMN 98, "Unit Price", 
			COLUMN 119, "Extended" 

			PRINT COLUMN 10, " Code", 
			COLUMN 21, "Number", 
			COLUMN 41, " Qty", 
			COLUMN 86, "Currency", 
			COLUMN 119, " Price" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
 
		ON EVERY ROW 

			IF glob_rec_company.module_text[23] = "W" 
			AND l_rec_invoicedetl.price_uom_code IS NOT NULL THEN 
				IF l_rec_invoicedetl.price_uom_code != l_rec_invoicedetl.uom_code THEN 
					LET l_conversion_qty = get_uom_conversion_factor(
						glob_rec_kandoouser.cmpy_code, 
						l_rec_invoicedetl.part_code, 
						l_rec_invoicedetl.uom_code, 
						l_rec_invoicedetl.price_uom_code,
						1) 
					IF l_conversion_qty <= 0 THEN 
						LET l_rec_invoicedetl.unit_sale_amt = NULL 
					ELSE 
						LET l_rec_invoicedetl.unit_sale_amt = l_rec_invoicedetl.unit_sale_amt * l_conversion_qty 
					END IF 
				END IF 
			END IF 

			PRINT COLUMN 01, l_rec_invoicedetl.inv_date USING "dd/mm/yy", 
			COLUMN 10, l_rec_invoicedetl.cust_code, 
			COLUMN 20, l_rec_invoicedetl.inv_num USING "########", 
			COLUMN 40, l_rec_invoicedetl.ship_qty USING "######.##", " ",	l_rec_invoicedetl.uom_code, 
			COLUMN 56, l_rec_invoicedetl.line_text, 
			COLUMN 88, l_rec_invoicedetl.currency_code, 
			COLUMN 95, l_rec_invoicedetl.unit_sale_amt USING "--,---,---.&&", " ",l_rec_invoicedetl.price_uom_code, 
			COLUMN 115, l_rec_invoicedetl.ext_sale_amt USING "--,---,---.&&" 

			LET modu_tot_amt = modu_tot_amt + 
				conv_currency(
					l_rec_invoicedetl.ext_sale_amt, 
					glob_rec_kandoouser.cmpy_code, 
					l_rec_invoicedetl.currency_code, 
					"F", 
					l_rec_invoicedetl.inv_date, 
					"l_s") 
			
			LET modu_totp_amt = modu_totp_amt + 
				conv_currency(
					l_rec_invoicedetl.ext_sale_amt, 
					glob_rec_kandoouser.cmpy_code, 
					l_rec_invoicedetl.currency_code, 
					"F", 
					l_rec_invoicedetl.inv_date, 
					"l_s")
			 
		ON LAST ROW 
			SKIP 1 line 
			PRINT COLUMN 2, "Total Lines: ", count(*) USING "###", 
			COLUMN 70, "Report Totals in Base Currency: ", 
			COLUMN 115, modu_tot_amt USING "--,---,---.&&" 
			SKIP 1 line 

			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 		

		BEFORE GROUP OF l_rec_invoicedetl.part_code 
			SKIP 1 line 
			LET modu_totp_amt = 0 
			PRINT COLUMN 1, "Product ID: ",l_rec_invoicedetl.part_code, 
			COLUMN 15, l_rec_invoicedetl.line_text clipped 

		AFTER GROUP OF l_rec_invoicedetl.part_code 
			PRINT COLUMN 115, "===============" 
			PRINT COLUMN 1, "Product Total:", 
			COLUMN 115, modu_totp_amt USING "--,---,---.&&" 
END REPORT