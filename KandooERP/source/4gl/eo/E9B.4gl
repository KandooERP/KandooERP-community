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
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "../eo/E_EO_GLOBALS.4gl"
GLOBALS "../eo/E9_GROUP_GLOBALS.4gl"  
GLOBALS "../eo/E9B_GLOBALS.4gl" 
###########################################################################
# FUNCTION E9B_main() 
#
# OAB (E9B!!!) - OE Customer Orders by Date
###########################################################################
FUNCTION E9B_main() 
	DEFER QUIT 
	DEFER INTERRUPT 

	CALL setModuleId("E98")  
	
	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 	
			OPEN WINDOW E441 with FORM "E441" 
			 CALL windecoration_e("E441") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title

			MENU " Order Report by date" 
		
				BEFORE MENU 
					CALL publish_toolbar("kandoo","E9B","menu-Order Report-1") -- albo KD-502 
					CALL rpt_rmsreps_reset(NULL)
					CALL E9B_rpt_process(E9B_rpt_query())
							
				ON ACTION "WEB-HELP" -- albo kd-370 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "REPORT" #COMMAND "Run report" " SELECT criteria AND PRINT report" 
					CALL rpt_rmsreps_reset(NULL)
					CALL E9B_rpt_process(E9B_rpt_query())
		
				ON ACTION "PRINT MANAGER" #COMMAND "Print" "Print OR view using RMS"
					CALL run_prog("URS","","","","") 
					NEXT option "Exit" 
		
				ON ACTION "CANCEL" #COMMAND "Exit" " Exit TO menus" 
					EXIT MENU 
		
			END MENU 
			CLOSE WINDOW E441

		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL E9B_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW E441 with FORM "E441" 
			 CALL windecoration_e("E441") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(E9B_rpt_query()) #save where clause in env 
			CLOSE WINDOW E441 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL E9B_rpt_process(get_url_sel_text())
	END CASE 	
				
END FUNCTION 
###########################################################################
# END FUNCTION E9B_main() 
###########################################################################


############################################################
# FUNCTION E9B_rpt_query() 
#
# CONSTRUCT where clause for report data
# RETURN NULL or l_where_text_part
############################################################
FUNCTION E9B_rpt_query() 
	DEFINE l_where_text_part STRING
	DEFINE l_where_text STRING	
	DEFINE l_order_status char(1) 

	CLEAR screen 

	INPUT l_order_status WITHOUT DEFAULTS FROM order_status 
		BEFORE INPUT 
		CALL publish_toolbar("kandoo","E9B","input-order_status-1") -- albo kd-502 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

		AFTER FIELD l_order_status 
			IF int_flag != 0 OR 
			quit_flag != 0 THEN 
				RETURN NULL
			ELSE 
				IF l_order_status IS NULL OR 
				(l_order_status <> "F" AND 
				l_order_status <> "O") THEN 
					LET l_order_status = "A" 
				END IF 
				CASE 
					WHEN l_order_status = "A" 
						LET l_where_text_part = " 1=1 " 
					WHEN l_order_status = "O" 
						LET l_where_text_part = " AND orderdetl.order_qty > orderdetl.inv_qty " 
					WHEN l_order_status = "F" 
						LET l_where_text_part = " AND orderdetl.order_qty = orderdetl.inv_qty " 
				END CASE 
			END IF 

	END INPUT 

	CLOSE WINDOW E441 

	IF int_flag != 0 OR quit_flag != 0 THEN 
		RETURN NULL 
	ELSE 
		IF l_order_status IS NULL OR(l_order_status <> "F" AND l_order_status <> "O") THEN 
			LET l_order_status = "A" 
		END IF 
		
		CASE 
			WHEN l_order_status = "A" 
				LET l_where_text_part = " AND 1=1 " 
			WHEN l_order_status = "O" 
				LET l_where_text_part = " AND orderdetl.order_qty > orderdetl.inv_qty " 
			WHEN l_order_status = "F" 
				LET l_where_text_part = " AND orderdetl.order_qty = orderdetl.inv_qty " 
		END CASE 
	END IF

	CLEAR screen 
	OPEN WINDOW E440 with FORM "E440" 
	 CALL windecoration_e("E440") -- albo kd-755 

	MESSAGE " Enter criteria FOR selection - ESC TO begin search" attribute(yellow) 

	CONSTRUCT BY NAME l_where_text ON 
		orderhead.order_num, 
		orderhead.cust_code, 
		customer.name_text, 
		customer.type_code, 
		orderdetl.part_code, 
		orderhead.entry_date, 
		orderhead.order_date, 
		orderhead.sales_code, 
		orderdetl.cat_code, 
		product.class_code 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","E9B","construct-orderhead-1") -- albo kd-502 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	LET l_where_text = l_where_text clipped, l_where_text_part 

	CLOSE WINDOW E440

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN NULL 
	ELSE 
		RETURN l_where_text
	END IF 
END FUNCTION 
############################################################
# END FUNCTION E9B_rpt_query() 
############################################################


############################################################
# FUNCTION E9B_rpt_process(p_where_text) 
#
#
############################################################
FUNCTION E9B_rpt_process(p_where_text) 
	DEFINE p_where_text STRING
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]		
	DEFINE l_rec_order RECORD 
		cmpy_code LIKE orderhead.cmpy_code, 
		order_num LIKE orderhead.order_num, 
		order_date LIKE orderhead.order_date, 
		cust_code LIKE customer.cust_code, 
		part_code LIKE orderdetl.part_code, 
		uom_code LIKE orderdetl.uom_code, 
		order_qty LIKE orderdetl.order_qty, 
		inv_qty LIKE orderdetl.inv_qty, 
		unit_price_amt LIKE orderdetl.unit_price_amt 
	END RECORD 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"E9B_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT E9B_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------


		LET l_query_text = 
			" SELECT orderhead.cmpy_code, orderhead.order_num, ", 
			" orderhead.order_date, orderhead.cust_code, ", 
			" orderdetl.part_code, orderdetl.uom_code, ", 
			" orderdetl.order_qty, orderdetl.inv_qty, ", 
			" orderdetl.unit_price_amt ", 
			" FROM orderhead, orderdetl, customer,product ", 
			" WHERE orderhead.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
			" AND orderhead.cmpy_code = orderdetl.cmpy_code ", 
			" AND orderhead.cust_code = orderdetl.cust_code ", 
			" AND orderhead.order_num = orderdetl.order_num ", 
			" AND orderhead.cmpy_code = customer.cmpy_code ", 
			" AND orderhead.cust_code = customer.cust_code ", 
			" AND orderdetl.cmpy_code = product.cmpy_code ", 
			" AND orderdetl.part_code = product.part_code ", 
			"AND ",glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("E9B_rpt_list")].sel_text clipped," ",		  
			" ORDER BY orderhead.order_num" 

		PREPARE choice FROM l_query_text 
		DECLARE selcurs cursor FOR choice 

		FOREACH selcurs INTO l_rec_order.* 
			#---------------------------------------------------------
			OUTPUT TO REPORT E9B_rpt_list(l_rpt_idx,
			l_rec_order.*)  
			IF NOT rpt_int_flag_handler2("Order:",l_rec_order.order_num, NULL,l_rpt_idx) THEN
				EXIT FOREACH 
			END IF 
			#---------------------------------------------------------			
		END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT E9B_rpt_list
	CALL rpt_finish("E9B_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = FALSE 
		ERROR " Printing was aborted" 
		RETURN FALSE 
	ELSE 
		RETURN TRUE 
	END IF 
END FUNCTION 
############################################################
# FUNCTION E9B_rpt_process(p_where_text) 
############################################################


############################################################
# REPORT E9B_rpt_list(p_rec_orderhead) 
#
#
############################################################
REPORT E9B_rpt_list(p_rpt_idx,p_rec_order) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE p_rec_order RECORD 
		cmpy_code LIKE orderhead.cmpy_code, 
		order_num LIKE orderhead.order_num, 
		order_date LIKE orderhead.order_date, 
		cust_code LIKE customer.cust_code, 
		part_code LIKE orderdetl.part_code, 
		uom_code LIKE orderdetl.uom_code, 
		order_qty LIKE orderdetl.order_qty, 
		inv_qty LIKE orderdetl.inv_qty, 
		unit_price_amt LIKE orderdetl.unit_price_amt 
	END RECORD 
	DEFINE l_ost_amt money(15,2) 
	DEFINE l_tot_ost_amt money(15,2) 

	OUTPUT 
	left margin 1 
	ORDER external BY p_rec_order.cmpy_code, p_rec_order.order_num 

	FORMAT 

		PAGE HEADER 

			IF pageno = 1 THEN 
				LET l_ost_amt = 0 
				LET l_tot_ost_amt = 0 
			END IF 
			
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 3, "Order", 
			COLUMN 12, "Order", 
			COLUMN 22, "Client", 
			COLUMN 34, "Product", 
			COLUMN 47, "UOM", 
			COLUMN 52, "Quantity", 
			COLUMN 63, "Quantity", 
			COLUMN 75, "Unit", 
			COLUMN 86, "Outstanding" 

			PRINT COLUMN 2, "Number", 
			COLUMN 12, "Date", 
			COLUMN 24, "ID", 
			COLUMN 36, "ID", 
			COLUMN 52, "Ordered", 
			COLUMN 63, "Invoiced", 
			COLUMN 75, "Price", 
			COLUMN 88, "Amount" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		ON EVERY ROW 
			PRINT COLUMN 30, p_rec_order.part_code, 
			COLUMN 47, p_rec_order.uom_code, 
			COLUMN 52, p_rec_order.order_qty USING "######&.&&", 
			COLUMN 63, p_rec_order.inv_qty USING "######&.&&", 
			COLUMN 72, p_rec_order.unit_price_amt USING "---,---,--$.&&"; 
			LET l_ost_amt = (p_rec_order.order_qty - p_rec_order.inv_qty) * 
			p_rec_order.unit_price_amt 
			PRINT COLUMN 86, l_ost_amt USING "---,---,--$.&&" 
			LET l_tot_ost_amt = l_tot_ost_amt + l_ost_amt 

		BEFORE GROUP OF p_rec_order.order_num 
			PRINT COLUMN 1, p_rec_order.order_num USING "########", 
			COLUMN 11, p_rec_order.order_date USING "dd/mm/yy", 
			COLUMN 21, p_rec_order.cust_code; 

		AFTER GROUP OF p_rec_order.order_num 
			PRINT COLUMN 72, "--------------", 
			COLUMN 86, "--------------" 
			PRINT COLUMN 1, "Order totals:", 
			COLUMN 72, l_tot_ost_amt USING "---,---,--$.&&" 
			LET l_tot_ost_amt = 0 
			SKIP 1 LINES 
			
		ON LAST ROW 
			NEED 6 LINES			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
						
END REPORT 
############################################################
# END REPORT E9B_rpt_list(p_rec_orderhead) 
############################################################