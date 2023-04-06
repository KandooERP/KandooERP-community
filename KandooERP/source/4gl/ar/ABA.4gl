
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
GLOBALS "../ar/ABA_GLOBALS.4gl" 
############################################################
# MODULE Scope Variables
############################################################
DEFINE modu_tot_amt DECIMAL(16,2) #Will be incremented/added in actual report block 

############################################################
# FUNCTION aba_main()
#
# Invoice Detail Report
############################################################
FUNCTION aba_main() 

	CALL setModuleId("ABA") 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 	

			OPEN WINDOW A143 with FORM "A143" 
			CALL windecoration_a("A143") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
		
			MENU "Invoice Detail Report" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","ABA","menu-invoice-detail-rep") 
					CALL ABA_rpt_process(ABA_rpt_query())
					CALL rpt_rmsreps_reset(NULL)
		
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null)
					 
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				ON ACTION "REPORT" --COMMAND "Run Report" " SELECT criteria AND PRINT REPORT" 
					CALL ABA_rpt_process(ABA_rpt_query())
					CALL rpt_rmsreps_reset(NULL)
		
				ON ACTION "PRINT MANAGER" --COMMAND "Print" "Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "CANCEL" --COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus" 
					EXIT MENU 
		
			END MENU 
		
			CLOSE WINDOW A143 
	 
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL ABA_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW A190 with FORM "A190" 
			CALL windecoration_a("A190") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(ABA_rpt_query()) #save where clause in env 
			CLOSE WINDOW A190 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL ABA_rpt_process(get_url_sel_text())
	END CASE 
END FUNCTION 


############################################################
# FUNCTION ABA_rpt_query() 
#
# RETURN l_where_text
############################################################
FUNCTION ABA_rpt_query()
	DEFINE l_where_text STRING 

	MESSAGE kandoomsg2("A",1001,"") 
	#1001 Enter criteria FOR selection - ESC TO begin search"

	IF glob_rec_company.module_text[23] = "W" THEN 
		CONSTRUCT BY NAME l_where_text ON i.cust_code, 
		c.name_text, 
		c.currency_code, 
		c.type_code, 
		h.sale_code, 
		h.year_num, 
		h.period_num, 
		i.inv_num, 
		i.cat_code, 
		part_code, 
		ware_code, 
		ship_qty, 
		line_text 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","ABA","construct-invoicehead") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null)
				 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END CONSTRUCT 

	ELSE 
		CONSTRUCT BY NAME l_where_text ON i.cust_code, 
		c.name_text, 
		c.currency_code, 
		c.type_code, 
		h.sale_code, 
		h.year_num, 
		h.period_num, 
		i.inv_num, 
		i.cat_code, 
		part_code, 
		ware_code, 
		ship_qty, 
		line_text, 
		unit_sale_amt 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","ABA","construct-invoicehead") 

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
# FUNCTION ABA_rpt_query() 
#
# RETURN l_where_text
############################################################
FUNCTION ABA_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT  
	--DEFINE l_exist SMALLINT
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
		price_uom_code LIKE invoicedetl.price_uom_code, 
		ext_sale_amt LIKE invoicedetl.ext_sale_amt 
	END RECORD 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"ABA_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT ABA_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text	
	#------------------------------------------------------------


	LET l_query_text = 
	"SELECT I.cust_code, ", 
	"C.name_text, ", 
	"C.currency_code, ", 
	"I.inv_num, ", 
	"H.inv_date, ", 
	"I.line_num, ", 
	"I.part_code, ", 
	"I.ware_code, ", 
	"I.ord_qty, ", 
	"I.ship_qty, ", 
	"I.back_qty, ", 
	"I.line_text, ", 
	"I.uom_code, ", 
	"I.unit_sale_amt, ", 
	"I.price_uom_code, ", 
	"I.ext_sale_amt FROM ", 
	"invoicedetl I, customer C, invoicehead H ", 
	"WHERE I.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND C.cmpy_code = I.cmpy_code AND ", 
	"C.cust_code = I.cust_code AND ", 
	"I.inv_num = H.inv_num AND ", 
	"I.cmpy_code = H.cmpy_code AND ", 
	glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ABA_rpt_list")].sel_text clipped, " ",
	"ORDER BY I.cust_code, I.inv_num, I.line_num" 

	PREPARE choice FROM l_query_text 
	DECLARE selcurs CURSOR FOR choice
	
	FOREACH selcurs INTO l_rec_invoicedetl.* 
		#---------------------------------------------------------
		OUTPUT TO REPORT ABA_rpt_list(l_rpt_idx,
		l_rec_invoicedetl.*)  
		
		IF NOT rpt_int_flag_handler2("Customer:",l_rec_invoicedetl.cust_code, l_rec_invoicedetl.name_text,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------	
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT ABA_rpt_list
	CALL rpt_finish("ABA_rpt_list")
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
# REPORT ABA_rpt_list(p_rec_invoicedetl)  
#
#
############################################################
REPORT ABA_rpt_list(p_rpt_idx,p_rec_invoicedetl) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_invoicedetl RECORD 
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
		price_uom_code LIKE invoicedetl.price_uom_code, 
		ext_sale_amt LIKE invoicedetl.ext_sale_amt 
	END RECORD 
	DEFINE l_i SMALLINT 
	DEFINE l_idx SMALLINT
	DEFINE l_cnt SMALLINT	
	DEFINE l_rep_note CHAR(60)
	DEFINE l_arr_temp_note1 array[100] OF CHAR(30) 
	DEFINE l_arr_temp_note2 array[100] OF CHAR(30) 
	DEFINE l_conversion_qty FLOAT 
	DEFINE l_len INTEGER 
	DEFINE s INTEGER 


	OUTPUT 
--	left margin 0 
	ORDER external BY p_rec_invoicedetl.cust_code, p_rec_invoicedetl.inv_num, 
	p_rec_invoicedetl.line_num 

	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 1, "Line", 
			COLUMN 8,"Product", 
			COLUMN 30, "Invoiced", 
			COLUMN 60, "Description", 
			COLUMN 90, "Unit", 
			COLUMN 98, "Unit Price", 
			COLUMN 120, "Extended" 

			PRINT COLUMN 1, " # ", 
			COLUMN 8, " ID", 
			COLUMN 30, " Qty", 
			COLUMN 120, " Price" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		ON EVERY ROW 

			PRINT COLUMN 1, p_rec_invoicedetl.line_num USING "###", 
			COLUMN 5, p_rec_invoicedetl.part_code, 
			COLUMN 30, p_rec_invoicedetl.ship_qty USING "######.##"; 

			LET l_idx = 0 
			IF p_rec_invoicedetl.line_text[1,3] = "###" 
			AND p_rec_invoicedetl.line_text[16,18] = "###" 
			THEN 
				LET p_rec_invoicedetl.line_text = p_rec_invoicedetl.line_text[4,15] 

				DECLARE note_curs CURSOR FOR 
				SELECT note_text, note_num 
				INTO l_rep_note, l_cnt 
				FROM notes 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
				note_code = p_rec_invoicedetl.line_text 
				ORDER BY note_num 
				FOREACH note_curs 
					LET l_idx = l_idx + 1 
					LET l_arr_temp_note1[l_idx] = l_rep_note[1,30] 
					LET l_arr_temp_note2[l_idx] = l_rep_note[31,60] 
				END FOREACH 
				PRINT COLUMN 55, l_arr_temp_note1[1]; 
			ELSE 
				PRINT COLUMN 55, p_rec_invoicedetl.line_text; 
			END IF 
			
			IF glob_rec_company.module_text[23] = "W" 
			AND p_rec_invoicedetl.price_uom_code IS NOT NULL THEN 
				IF p_rec_invoicedetl.price_uom_code != p_rec_invoicedetl.uom_code THEN 
					LET l_conversion_qty = get_uom_conversion_factor(
					glob_rec_kandoouser.cmpy_code, 
					p_rec_invoicedetl.part_code, 
					p_rec_invoicedetl.uom_code, 
					p_rec_invoicedetl.price_uom_code,
					1) 
					IF l_conversion_qty <= 0 THEN 
						LET p_rec_invoicedetl.unit_sale_amt = NULL 
					ELSE 
						LET p_rec_invoicedetl.unit_sale_amt 
						= p_rec_invoicedetl.unit_sale_amt * l_conversion_qty 
					END IF 
				END IF 
			END IF
			 
			PRINT COLUMN 90, p_rec_invoicedetl.uom_code, 
			COLUMN 95, p_rec_invoicedetl.unit_sale_amt USING "--,---,---.&&", 
			1 space, p_rec_invoicedetl.price_uom_code, 
			COLUMN 115, p_rec_invoicedetl.ext_sale_amt USING "--,---,---.&&" 

			IF l_idx > 0 
			THEN 
				IF l_arr_temp_note2[1] IS NOT NULL THEN 
					PRINT COLUMN 55, l_arr_temp_note2[1] 
				END IF 
				FOR l_i = 2 TO l_idx 
					PRINT COLUMN 55, l_arr_temp_note1[l_i] 
					IF l_arr_temp_note2[l_i] IS NOT NULL THEN 
						PRINT COLUMN 55, l_arr_temp_note2[l_i] 
					END IF 
				END FOR 
			END IF 
			LET modu_tot_amt = modu_tot_amt + conv_currency(p_rec_invoicedetl.ext_sale_amt, glob_rec_kandoouser.cmpy_code, 
			p_rec_invoicedetl.currency_code, "F", p_rec_invoicedetl.inv_date, "S") 
			
		ON LAST ROW 
			NEED 5 LINES 
			SKIP 1 line 
			PRINT COLUMN 1, "Report Total In Base Currency:" 
			PRINT COLUMN 2, "Total Lines: ", count(*) USING "###", 
			COLUMN 112, modu_tot_amt USING "-----,---,---.&&" 
			SKIP 1 line 

			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			

		BEFORE GROUP OF p_rec_invoicedetl.cust_code 
			PRINT COLUMN 1, "Customer Code: ",p_rec_invoicedetl.cust_code, 
			COLUMN 25, p_rec_invoicedetl.name_text clipped, " Currency ", 
			p_rec_invoicedetl.currency_code 
			SKIP 1 line 

		BEFORE GROUP OF p_rec_invoicedetl.inv_num 
			PRINT COLUMN 5, "Invoice: ", p_rec_invoicedetl.inv_num USING "########" 

		AFTER GROUP OF p_rec_invoicedetl.inv_num 
			PRINT COLUMN 115, "===============" 
			PRINT COLUMN 115, GROUP sum(p_rec_invoicedetl.ext_sale_amt) USING "--,---,---.&&" 

		AFTER GROUP OF p_rec_invoicedetl.cust_code 
			PRINT COLUMN 115, "===============" 
			PRINT COLUMN 115, GROUP sum(p_rec_invoicedetl.ext_sale_amt) USING "--,---,---.&&" 
END REPORT