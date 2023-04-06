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
# GLOBAL SCOPE VARIABLES
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "../ar/A_AR_GLOBALS.4gl"
GLOBALS "../ar/AED_GLOBALS.4gl" 
#####################################################################
# FUNCTION AED_main() 
#
#   AED - Margin Analysis Report
#         Print the Divisional Sales Margin Analysis Report
#####################################################################
FUNCTION AED_main() 
	DEFER quit 
	DEFER interrupt 

	CALL setModuleId("AED") 

	CREATE temp TABLE shuffle (divn_code CHAR(18), 
	dept_code CHAR(18), 
	cat_code CHAR(3), 
	part_code CHAR(15), 
	cust_code CHAR(8), 
	inv_date DATE, 
	inv_num INTEGER, 
	inv_line_num SMALLINT, 
	unit_sales_amt DECIMAL(16,4), 
	unit_cost_amt DECIMAL(16,4), 
	sales_qty DECIMAL(8,2), 
	curr_code CHAR(3), 
	conv_qty float) with no LOG
	 
	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 
			OPEN WINDOW A704 with FORM "A704" 
			CALL windecoration_a("A704")
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

			MENU " Divisional Margin Analysis" 

				BEFORE MENU 
					CALL publish_toolbar("kandoo","AED","menu-divisional-margin-analysis") 
					CALL AED_rpt_process(AED_rpt_query())
					
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				ON ACTION "Report" #COMMAND "Run" " Enter selection criteria AND generate REPORT"
						CALL AED_rpt_process(AED_rpt_query())

				ON ACTION "Print Manager" #COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "CANCEL"	#COMMAND KEY("E",interrupt)"Exit" " Exit TO menus"
					EXIT MENU 
					
			END MENU 

			CLOSE WINDOW A704 

	 
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL AED_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW A704 with FORM "A704" 
			CALL windecoration_a("A704") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(AED_rpt_query()) #save where clause in env 
			CLOSE WINDOW A704 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL AED_rpt_process(get_url_sel_text())
	END CASE 	
END FUNCTION 



#####################################################################
# FUNCTION AED_rpt_query() 
#
#
#####################################################################
FUNCTION AED_rpt_query() 
	DEFINE l_where_text STRING

	MESSAGE kandoomsg2("U",1001,"") 
	#1001 Enter Selection Criteria; OK TO Continue
	CONSTRUCT BY NAME l_where_text ON invoicehead.cust_code, 
	invoicehead.inv_num, 
	invoicedetl.part_code, 
	invoicedetl.cat_code, 
	product.class_code, 
	customer.type_code, 
	invoicehead.sale_code, 
	invoicehead.term_code, 
	invoicehead.tax_code 


		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","AED","construct-customer") 

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
		#IF NOT get_time_frame() THEN 
		#	RETURN NULL 
		#END IF 
		#original: LET glob_rec_rmsreps.sel_text[1500,2000] = segment_con(glob_rec_kandoouser.cmpy_code,"invoicedetl")
		LET glob_rec_rpt_selector.sel_option1 = segment_con(glob_rec_kandoouser.cmpy_code,"invoicedetl") 	
		RETURN l_where_text
	END IF  

END FUNCTION 

#####################################################################
# FUNCTION AED_rpt_process()
#
#
#####################################################################
FUNCTION AED_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING 
	DEFINE l_rpt_idx SMALLINT   	
	DEFINE l_rec_tempdoc RECORD 
		divn_code LIKE coa.acct_code, 
		dept_code LIKE coa.acct_code, 
		cat_code LIKE category.cat_code, 
		part_code LIKE product.part_code, 
		cust_code LIKE customer.cust_code, 
		inv_date LIKE invoicehead.inv_date, 
		inv_num LIKE invoicehead.inv_num, 
		inv_line_num LIKE invoicedetl.line_num, 
		unit_sales_amt LIKE invoicedetl.unit_sale_amt, 
		unit_cost_amt LIKE invoicedetl.unit_cost_amt, 
		sales_qty LIKE invoicedetl.ship_qty, 
		curr_code LIKE customer.currency_code, 
		conv_qty LIKE invoicehead.conv_qty 
	END RECORD	
	DEFINE l_rec_structure RECORD LIKE structure.* 
	DEFINE l_start_divn SMALLINT
	DEFINE l_end_divn SMALLINT
	DEFINE l_start_dept SMALLINT
	DEFINE l_end_dept SMALLINT	 
	DEFINE l_idx SMALLINT 
	DEFINE l_continue SMALLINT 

	DELETE FROM shuffle WHERE 1=1 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"AED_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT AED_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AED_rpt_list")].sel_text
	#------------------------------------------------------------

	LET glob_tot_wd_amt = 0 
	LET l_continue = true 
 
	LET glob_from_date = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AED_rpt_list")].ref1_date 
	LET glob_to_date = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AED_rpt_list")].ref2_date 
	--LET glob_seg_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AED_rpt_list")].sel_option1 #glob_rec_rmsreps.sel_text[1500,2000] 
	--LET glob_rec_rmsreps.sel_text[1500,2000] = " " #??? what now ?

	DECLARE c_structure CURSOR FOR 
	SELECT * FROM structure 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND type_ind in ("S","L") 
	AND start_num > 0 
	ORDER BY start_num 
	LET l_idx = 0 

	FOREACH c_structure INTO l_rec_structure.* 
		LET l_idx = l_idx + 1 
		IF l_idx = 1 THEN 
			LET l_start_divn = l_rec_structure.start_num 
			LET l_end_divn = l_rec_structure.start_num 
			+ l_rec_structure.length_num - 1 
			LET glob_divn_text = l_rec_structure.desc_text 
		END IF 
		
		IF l_idx = 2 THEN 
			LET l_start_dept = l_rec_structure.start_num 
			LET l_end_dept = l_rec_structure.start_num 
			+ l_rec_structure.length_num - 1 
			LET glob_dept_text = l_rec_structure.desc_text 
			EXIT FOREACH 
		END IF 
	END FOREACH 

	LET l_query_text = "SELECT invoicedetl.line_acct_code, ", 
	" invoicedetl.line_acct_code, ", 
	" invoicedetl.cat_code, ", 
	" invoicedetl.part_code, ", 
	" invoicehead.cust_code, ", 
	" invoicehead.inv_date, ", 
	" invoicehead.inv_num, ", 
	" invoicedetl.line_num, ", 
	" invoicedetl.unit_sale_amt, ", 
	" invoicedetl.unit_cost_amt, ", 
	" invoicedetl.ship_qty,", 
	" customer.currency_code, ", 
	" invoicehead.conv_qty ", 
	" FROM invoicehead, invoicedetl, customer, product ", 
	" WHERE customer.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	" AND invoicehead.cmpy_code = customer.cmpy_code ", 
	" AND invoicedetl.cmpy_code = customer.cmpy_code ", 
	" AND product.cmpy_code = customer.cmpy_code ", 
	" AND invoicedetl.inv_num = invoicehead.inv_num ", 
	" AND invoicehead.cust_code = customer.cust_code ", 
	" AND product.part_code = invoicedetl.part_code ", 
	" AND invoicehead.inv_ind <> '3' ", 
	" AND invoicehead.inv_date >= '",glob_from_date,"' ", 
	" AND invoicehead.inv_date <= '",glob_to_date,"' ", 
	" AND ",glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AED_rpt_list")].sel_text clipped, " ",
	glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AED_rpt_list")].sel_option1 CLIPPED #glob_seg_text clipped 
	
	PREPARE s_invoice FROM l_query_text 
	DECLARE c_invoice CURSOR FOR s_invoice 
	FOREACH c_invoice INTO l_rec_tempdoc.* 
		LET l_rec_tempdoc.unit_cost_amt = l_rec_tempdoc.unit_cost_amt / l_rec_tempdoc.conv_qty 
		LET l_rec_tempdoc.unit_sales_amt = l_rec_tempdoc.unit_sales_amt / l_rec_tempdoc.conv_qty 
		LET l_rec_tempdoc.divn_code = l_rec_tempdoc.divn_code[l_start_divn,l_end_divn] 
		LET l_rec_tempdoc.dept_code = l_rec_tempdoc.dept_code[l_start_dept,l_end_dept]
		 
		INSERT INTO shuffle VALUES (l_rec_tempdoc.*) 
		IF NOT rpt_int_flag_handler2("Invoice:",l_rec_tempdoc.cust_code, l_rec_tempdoc.inv_num,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 		
	END FOREACH 

	IF l_continue THEN 
		DECLARE c_divnision CURSOR FOR 
		SELECT * FROM shuffle 
		ORDER BY divn_code, dept_code, cust_code, inv_num, inv_line_num 
		FOREACH c_divnision INTO l_rec_tempdoc.* 
			#---------------------------------------------------------
			OUTPUT TO REPORT AED_rpt_list(l_rpt_idx,l_rec_tempdoc.*)  
			IF NOT rpt_int_flag_handler2("Invoice:",l_rec_tempdoc.cust_code,l_rec_tempdoc.inv_num,l_rpt_idx) THEN
				EXIT FOREACH 
			END IF 
			#---------------------------------------------------------		
		END FOREACH 
	END IF 
	 
	#------------------------------------------------------------
	FINISH REPORT AED_rpt_list
	RETURN rpt_finish("AED_rpt_list")
	#------------------------------------------------------------
 
END FUNCTION 


#####################################################################
# REPORT AED_rpt_list(l_rec_tempdoc)
#
#
#####################################################################
REPORT AED_rpt_list(p_rpt_idx,l_rec_tempdoc) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE l_rec_tempdoc RECORD 
		divn_code LIKE coa.acct_code, 
		dept_code LIKE coa.acct_code, 
		cat_code LIKE category.cat_code, 
		part_code LIKE product.part_code, 
		cust_code LIKE customer.cust_code, 
		inv_date LIKE invoicehead.inv_date, 
		inv_num LIKE invoicehead.inv_num, 
		inv_line_num LIKE invoicedetl.line_num, 
		unit_sales_amt LIKE invoicedetl.unit_sale_amt, 
		unit_cost_amt LIKE invoicedetl.unit_cost_amt, 
		sales_qty LIKE invoicedetl.ship_qty, 
		curr_code LIKE customer.currency_code, 
		conv_qty LIKE invoicehead.conv_qty 
	END RECORD 
	DEFINE l_inv_count SMALLINT 
	DEFINE l_inv_line SMALLINT 

	OUTPUT 
--	left margin 1 
	ORDER external BY l_rec_tempdoc.divn_code, 
	l_rec_tempdoc.dept_code, 
	l_rec_tempdoc.cust_code, 
	l_rec_tempdoc.inv_num, 
	l_rec_tempdoc.inv_line_num 
	
	FORMAT 
		PAGE HEADER 
			#Special additional header line
			LET glob_arr_rec_rpt_kandooreport[p_rpt_idx].line3_text  = 
			42 spaces, " FOR the Period FROM: ", 
			glob_from_date USING "dd/mm/yyyy", 
			" TO: ", glob_to_date USING "dd/mm/yyyy"
			 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2]

			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line3_text 
			 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  

		BEFORE GROUP OF l_rec_tempdoc.divn_code 
			SKIP TO top OF PAGE 
			PRINT COLUMN 01, glob_divn_text clipped, ": ",l_rec_tempdoc.divn_code 

		BEFORE GROUP OF l_rec_tempdoc.dept_code 
			SKIP 1 line 
			PRINT COLUMN 01, glob_dept_text clipped, ": ",l_rec_tempdoc.dept_code 
			SKIP 1 line 

		BEFORE GROUP OF l_rec_tempdoc.cust_code 
			LET l_inv_count = 0 

		BEFORE GROUP OF l_rec_tempdoc.inv_num 
			LET l_inv_line = 0 

		ON EVERY ROW 
			PRINT COLUMN 001, l_rec_tempdoc.cust_code, 
			COLUMN 012, l_rec_tempdoc.inv_date USING "dd/mm/yy", 
			COLUMN 024, l_rec_tempdoc.inv_num USING "#######&", 
			COLUMN 037, l_rec_tempdoc.inv_line_num USING "##&", 
			COLUMN 043, l_rec_tempdoc.sales_qty USING "#####&", 
			COLUMN 052, l_rec_tempdoc.unit_sales_amt USING "--,---,--&.&&", 
			COLUMN 064, l_rec_tempdoc.unit_cost_amt USING "--,---,--&.&&", 
			COLUMN 078, l_rec_tempdoc.unit_sales_amt * l_rec_tempdoc.sales_qty 
			USING "----,---,--&.&&", 
			COLUMN 098, l_rec_tempdoc.unit_cost_amt * l_rec_tempdoc.sales_qty 
			USING "----,---,--&.&&"; 
			IF (l_rec_tempdoc.unit_sales_amt * l_rec_tempdoc.sales_qty) > 0 THEN 
				PRINT COLUMN 118, (((l_rec_tempdoc.unit_sales_amt * l_rec_tempdoc.sales_qty) 
				- (l_rec_tempdoc.unit_cost_amt * l_rec_tempdoc.sales_qty)) 
				* 100) / (l_rec_tempdoc.unit_sales_amt 
				* l_rec_tempdoc.sales_qty) USING "---&.&" 
			ELSE 
				PRINT COLUMN 118, " " 
			END IF 
			IF l_rec_tempdoc.unit_cost_amt = 0 THEN 
				LET glob_tot_wd_amt = glob_tot_wd_amt 
				+ (l_rec_tempdoc.unit_sales_amt 
				* l_rec_tempdoc.sales_qty) 
			END IF 
			LET l_inv_line = l_inv_line + 1 

		AFTER GROUP OF l_rec_tempdoc.inv_num 
			LET l_inv_count = l_inv_count + 1 
			PRINT COLUMN 042, "Total FOR Invoice: ", 
			COLUMN 061, l_rec_tempdoc.inv_num USING "########", 
			COLUMN 078, GROUP sum (l_rec_tempdoc.unit_sales_amt * 
			l_rec_tempdoc.sales_qty) USING "----,---,--&.&&","*", 
			COLUMN 098, GROUP sum (l_rec_tempdoc.unit_cost_amt * 
			l_rec_tempdoc.sales_qty) 
			USING "----,---,--&.&&","*"; 
			IF (group sum (l_rec_tempdoc.unit_sales_amt * l_rec_tempdoc.sales_qty) > 0) THEN 
				PRINT COLUMN 118, ((group sum (l_rec_tempdoc.unit_sales_amt 
				* l_rec_tempdoc.sales_qty) 
				- GROUP sum (l_rec_tempdoc.unit_cost_amt 
				* l_rec_tempdoc.sales_qty)) 
				* 100) / GROUP sum (l_rec_tempdoc.unit_sales_amt 
				* l_rec_tempdoc.sales_qty) USING "---&.&" 
			ELSE 
				PRINT COLUMN 118, " " 
			END IF 

		AFTER GROUP OF l_rec_tempdoc.cust_code 
			PRINT COLUMN 042, "Total FOR Customer: ", 
			COLUMN 061, l_rec_tempdoc.cust_code, 
			COLUMN 078, GROUP sum (l_rec_tempdoc.unit_sales_amt * 
			l_rec_tempdoc.sales_qty) USING "----,---,--&.&&","**", 
			COLUMN 098, GROUP sum (l_rec_tempdoc.unit_cost_amt * 
			l_rec_tempdoc.sales_qty) USING "----,---,--&.&&","**"; 
			IF (group sum(l_rec_tempdoc.unit_sales_amt * l_rec_tempdoc.sales_qty) > 0) THEN 
				PRINT COLUMN 118, ((group sum (l_rec_tempdoc.unit_sales_amt 
				* l_rec_tempdoc.sales_qty) 
				- GROUP sum (l_rec_tempdoc.unit_cost_amt 
				* l_rec_tempdoc.sales_qty)) * 100) 
				/ GROUP sum (l_rec_tempdoc.unit_sales_amt 
				* l_rec_tempdoc.sales_qty) USING "---&.&" 
			ELSE 
				PRINT COLUMN 118, " " 
			END IF 
			SKIP 1 LINES 

		AFTER GROUP OF l_rec_tempdoc.dept_code 
			PRINT COLUMN 042, "Total FOR ",glob_dept_text clipped,": ", 
			l_rec_tempdoc.dept_code clipped, 
			COLUMN 078, GROUP sum (l_rec_tempdoc.unit_sales_amt 
			* l_rec_tempdoc.sales_qty) USING "----,---,--&.&&","***", 
			COLUMN 098, GROUP sum (l_rec_tempdoc.unit_cost_amt * 
			l_rec_tempdoc.sales_qty) USING "----,---,--&.&&","***"; 
			IF (group sum(l_rec_tempdoc.unit_cost_amt * l_rec_tempdoc.sales_qty) > 0) THEN 
				PRINT COLUMN 118,((group sum (l_rec_tempdoc.unit_sales_amt 
				* l_rec_tempdoc.sales_qty) - GROUP sum 
				(l_rec_tempdoc.unit_cost_amt * l_rec_tempdoc.sales_qty)) 
				* 100) / GROUP sum (l_rec_tempdoc.unit_sales_amt 
				* l_rec_tempdoc.sales_qty) USING "---&.&" 
			ELSE 
				PRINT COLUMN 118, " " 
			END IF 
			SKIP 1 LINES 

		AFTER GROUP OF l_rec_tempdoc.divn_code 
			PRINT COLUMN 042, "Total FOR ",glob_divn_text clipped,": ", 
			l_rec_tempdoc.divn_code clipped, 
			COLUMN 078, GROUP sum (l_rec_tempdoc.unit_sales_amt 
			* l_rec_tempdoc.sales_qty) USING "----,---,--&.&&","****", 
			COLUMN 098, GROUP sum (l_rec_tempdoc.unit_cost_amt * 
			l_rec_tempdoc.sales_qty) USING "----,---,--&.&&","****"; 
			IF (group sum(l_rec_tempdoc.unit_cost_amt * l_rec_tempdoc.sales_qty) > 0) THEN 
				PRINT COLUMN 118,((group sum (l_rec_tempdoc.unit_sales_amt 
				* l_rec_tempdoc.sales_qty) - GROUP sum 
				(l_rec_tempdoc.unit_cost_amt * l_rec_tempdoc.sales_qty)) 
				* 100) / GROUP sum (l_rec_tempdoc.unit_sales_amt 
				* l_rec_tempdoc.sales_qty) USING "---&.&" 
			ELSE 
				PRINT COLUMN 118, " " 
			END IF 

		ON LAST ROW 
			SKIP TO top OF PAGE 
			SKIP 2 LINES 
			PRINT COLUMN 42, "Total FOR Report: ", 
			COLUMN 78, sum (l_rec_tempdoc.unit_sales_amt * l_rec_tempdoc.sales_qty) 
			USING "----,---,--&.&&", 
			COLUMN 98, sum (l_rec_tempdoc.unit_cost_amt * l_rec_tempdoc.sales_qty) 
			USING "----,---,--&.&&"; 
			IF (sum (l_rec_tempdoc.unit_sales_amt * l_rec_tempdoc.sales_qty) > 0) THEN 
				PRINT COLUMN 118, ((sum (l_rec_tempdoc.unit_sales_amt 
				* l_rec_tempdoc.sales_qty) 
				- sum (l_rec_tempdoc.unit_cost_amt 
				* l_rec_tempdoc.sales_qty)) * 100) 
				/ sum (l_rec_tempdoc.unit_sales_amt 
				* l_rec_tempdoc.sales_qty) USING "---&.&" 
			ELSE 
				PRINT COLUMN 118, " " 
			END IF 
			SKIP 1 LINES 
			PRINT COLUMN 042, "Total Written Down: ", 
			COLUMN 078, glob_tot_wd_amt USING "----,---,--&.&&" 
			SKIP 1 LINES 
			PRINT COLUMN 042, "Net Written Down: ", 
			COLUMN 078, (sum (l_rec_tempdoc.unit_sales_amt * l_rec_tempdoc.sales_qty)) 
			- glob_tot_wd_amt USING "----,---,--&.&&", 
			COLUMN 098, sum (l_rec_tempdoc.unit_cost_amt * l_rec_tempdoc.sales_qty) USING "----,---,--&.&&"; 
			IF (sum(l_rec_tempdoc.unit_sales_amt * l_rec_tempdoc.sales_qty) 
			- glob_tot_wd_amt) > 0 THEN 
				PRINT COLUMN 118, ((sum (l_rec_tempdoc.unit_sales_amt 
				* l_rec_tempdoc.sales_qty) - glob_tot_wd_amt 
				- sum (l_rec_tempdoc.unit_cost_amt 
				* l_rec_tempdoc.sales_qty)) * 100) 
				/ (sum (l_rec_tempdoc.unit_sales_amt 
				* l_rec_tempdoc.sales_qty) - glob_tot_wd_amt) 
				USING "---&.&" 
			ELSE 
				PRINT COLUMN 118, " " 
			END IF 
			SKIP 2 line 
			
			SKIP 1 line 
		 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AED_rpt_list")].sel_option1 clipped wordwrap right margin 120
				PRINT COLUMN 10, "AND invoice date between: '", 
				glob_from_date, "' AND '", glob_to_date,"'" 
				wordwrap right margin 120 
				 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	
				
END REPORT 

{

#####################################################################
# FUNCTION get_time_frame()
#
#
#####################################################################
FUNCTION get_time_frame() 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_from_year_num LIKE period.year_num
	DEFINE l_from_period_num LIKE period.period_num
	DEFINE l_to_year_num LIKE period.year_num
	DEFINE l_to_period_num LIKE period.period_num
	DEFINE l_year_text CHAR(7) 

	OPEN WINDOW A705 with FORM "A705" 
	CALL windecoration_a("A705") 

	INITIALIZE glob_to_date TO NULL 
	INITIALIZE glob_from_date TO NULL 
	INITIALIZE l_from_year_num TO NULL 
	INITIALIZE l_from_period_num TO NULL 
	INITIALIZE l_to_year_num TO NULL 
	INITIALIZE l_to_period_num TO NULL 
	LET l_msgresp = kandoomsg("U",1020,"Time Frame") 
	#1020 Enter Time Frame Details; OK TO Continue.
	INPUT l_from_year_num, 
	l_from_period_num, 
	l_to_year_num, 
	l_to_period_num, 
	glob_from_date, 
	glob_to_date 
	FROM
	l_from_year_num, 
	l_from_period_num, 
	l_to_year_num, 
	l_to_period_num, 
	glob_from_date, 
	glob_to_date

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","AED","inp-period") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				IF l_from_year_num IS NULL 
				AND l_from_period_num IS NULL 
				AND l_to_year_num IS NULL 
				AND l_to_period_num IS NULL 
				AND glob_from_date IS NULL 
				AND glob_to_date IS NULL THEN 
					LET l_msgresp = kandoomsg("J",9616,"") 
					#9616 Enter either a period range OR a date range
					NEXT FIELD from_year_num 
				END IF 
				
				IF (l_from_year_num IS NOT NULL 
				OR l_from_period_num IS NOT NULL 
				OR l_to_year_num IS NOT NULL 
				OR l_to_period_num IS NOT null) 
				AND (glob_from_date IS NOT NULL 
				OR glob_to_date IS NOT null) THEN 
					LET l_msgresp = kandoomsg("J",9615,"") 
					#9615 Both year/period AND date ranges cannot be entered.
					NEXT FIELD from_year_num 
				END IF 
				
				IF l_from_year_num IS NOT NULL THEN 
					IF l_from_period_num IS NULL THEN 
						LET l_msgresp = kandoomsg("U",9102,"") 
						#9102 Value must be entered
						NEXT FIELD from_period_num 
					END IF 
				END IF 
				
				IF l_to_year_num IS NOT NULL THEN 
					IF l_to_period_num IS NULL THEN 
						LET l_msgresp = kandoomsg("U",9102,"") 
						#9102 Value must be entered
						NEXT FIELD to_period_num 
					END IF 
				END IF 
				
				IF l_from_period_num IS NOT NULL THEN 
					IF l_from_year_num IS NULL THEN 
						LET l_msgresp = kandoomsg("U",9102,"") 
						#9102 Value must be entered
						NEXT FIELD from_year_num 
					END IF 
				END IF 
				
				IF l_to_period_num IS NOT NULL THEN 
					IF l_to_year_num IS NULL THEN 
						LET l_msgresp = kandoomsg("U",9102,"") 
						#9102 Value must be entered
						NEXT FIELD to_year_num 
					END IF 
				END IF 
				
				IF l_to_year_num < l_from_year_num THEN 
					LET l_msgresp = kandoomsg("U",9907,l_from_year_num) 
					#9907 "Value must be >= FROM year"
					NEXT FIELD to_year_num 
				END IF 
				IF l_from_year_num = l_to_year_num 
				AND l_to_period_num < l_from_period_num THEN 
					LET l_msgresp = kandoomsg("U",9907,l_from_period_num) 
					#9907 "Value must be >= FROM period"
					NEXT FIELD to_period_num 
				END IF 
				IF glob_to_date < glob_from_date THEN 
					LET l_msgresp = kandoomsg("U",9907,glob_from_date) 
					#9907 "Value must be >= FROM date"
					NEXT FIELD to_date 
				END IF 
				IF l_from_year_num IS NOT NULL 
				AND l_from_period_num IS NOT NULL THEN 
					SELECT start_date INTO glob_from_date FROM period 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND year_num = l_from_year_num 
					AND period_num = l_from_period_num 
					IF status = NOTFOUND THEN 
						LET l_year_text = l_from_year_num USING "####","/", 
						l_from_period_num USING "##" 
						LET l_msgresp = kandoomsg("G",9201,l_year_text) 
						#9201 "Year AND Period NOT defined FOR yyyy/mm"
						NEXT FIELD from_year_num 
					END IF 
				END IF 
				
				IF l_to_year_num IS NOT NULL 
				AND l_to_period_num IS NOT NULL THEN 
					SELECT end_date INTO glob_to_date FROM period 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND year_num = l_to_year_num 
					AND period_num = l_to_period_num 
					IF status = NOTFOUND THEN 
						LET l_year_text = l_to_year_num USING "####","/", 
						l_to_period_num USING "##" 
						LET l_msgresp = kandoomsg("G",9201,l_year_text) 
						#9201 "Year AND Period NOT defined FOR yyyy/mm"
						INITIALIZE glob_to_date TO NULL 
						INITIALIZE glob_from_date TO NULL 
						NEXT FIELD to_year_num 
					END IF 
				END IF 
				IF l_from_year_num IS NULL 
				AND l_to_year_num IS NOT NULL THEN 
					LET glob_from_date = "1/1/1" 
				END IF 
				IF l_to_year_num IS NULL 
				AND l_from_year_num IS NOT NULL THEN 
					LET glob_to_date = "31/12/9999" 
				END IF 
				IF glob_from_date IS NULL THEN 
					LET glob_from_date = "1/1/1" 
				END IF 
				IF glob_to_date IS NULL THEN 
					LET glob_to_date = "31/12/9999" 
				END IF 
			END IF 


	END INPUT 

	CLOSE WINDOW A705 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 
	LET glob_rec_rpt_selector.ref1_date = glob_from_date 
	LET glob_rec_rpt_selector.ref2_date = glob_to_date 
	RETURN true 
END FUNCTION 
}