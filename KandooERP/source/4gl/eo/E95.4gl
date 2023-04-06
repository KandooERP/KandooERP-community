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
GLOBALS "../eo/E95_GLOBALS.4gl"
###########################################################################
# MODULE Scope Variables
###########################################################################
###########################################################################
# FUNCTION E95_main() 
#
# OA5 (E95!!!) Order Detail Report
###########################################################################
FUNCTION E95_main() 
	DEFER QUIT 
	DEFER INTERRUPT 

	CALL setModuleId("E95") 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 	

			OPEN WINDOW E400 with FORM "E400" 
			 CALL windecoration_e("E400") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title
		
			DISPLAY BY NAME glob_rec_arparms.inv_ref1_text
		
			MENU " Order Detail report" 
		
				BEFORE MENU 
					CALL publish_toolbar("kandoo","E95","menu-Order_Detail-1") -- albo kd-502 
					CALL rpt_rmsreps_reset(NULL)
					CALL E95_rpt_process(E95_rpt_query())
					
				ON ACTION "WEB-HELP" -- albo kd-370 
					CALL onlinehelp(getmoduleid(),null) 
		
				COMMAND "Report" " SELECT criteria AND PRINT report" 
					CALL rpt_rmsreps_reset(NULL)
					CALL E95_rpt_process(E95_rpt_query())
		
				ON ACTION "PRINT MANAGER" 		#COMMAND "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "CANCEL" #COMMAND KEY (INTERRUPT, "E") "Exit" " Exit TO menus" 
					EXIT MENU 
		
			END MENU 
		
			CLOSE WINDOW E400 

		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL E95_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW E400 with FORM "E400" 
			 CALL windecoration_e("E400") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(E95_rpt_query()) #save where clause in env 
			CLOSE WINDOW E400 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL E95_rpt_process(get_url_sel_text())
	END CASE 			

END FUNCTION 


###########################################################################
# FUNCTION E95_rpt_query()  
#
#
###########################################################################
FUNCTION E95_rpt_query()  
	DEFINE l_where_text STRING

	CLEAR FORM
	 
	DISPLAY glob_rec_arparms.inv_ref1_text TO inv_ref1_text 
	
	MESSAGE kandoomsg2("U",1001,"") 
	#1001 " Enter criteria FOR selection - ESC TO begin search"

	CONSTRUCT BY NAME l_where_text ON 
	orderhead.cust_code, 
	customer.name_text, 
	orderhead.order_num, 
	orderhead.currency_code, 
	orderhead.goods_amt, 
	orderhead.hand_amt, 
	orderhead.freight_amt, 
	orderhead.tax_amt, 
	orderhead.cost_amt, 
	orderhead.total_amt, 
	orderhead.disc_amt, 
	orderhead.ord_text, 
	orderhead.entry_code, 
	orderhead.ship_date, 
	orderhead.entry_date, 
	orderhead.last_inv_num, 
	orderhead.status_ind, 
	orderhead.com1_text, 
	orderhead.com2_text 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","E95","construct-orderhead-1") -- albo kd-502 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN NULL 
	ELSE 
		RETURN l_where_text
	END IF 
END FUNCTION 


############################################################
# FUNCTION E95_rpt_process(p_where_text) 
#
#
############################################################
FUNCTION E95_rpt_process(p_where_text) 
	DEFINE p_where_text STRING
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]		
	--DEFINE exist SMALLINT, 
	DEFINE l_rec_orderdetl RECORD 
		cust_code LIKE orderdetl.cust_code, 
		name_text LIKE customer.name_text, 
		order_num LIKE orderdetl.order_num, 
		ord_text LIKE orderhead.ord_text, 
		line_num LIKE orderdetl.line_num, 
		part_code LIKE orderdetl.part_code, 
		ware_code LIKE orderdetl.ware_code, 
		order_qty LIKE orderdetl.order_qty, 
		picked_qty LIKE orderdetl.picked_qty, 
		back_qty LIKE orderdetl.back_qty, 
		desc_text LIKE orderdetl.desc_text, 
		uom_code LIKE orderdetl.uom_code, 
		unit_price_amt LIKE orderdetl.unit_price_amt, 
		ext_price_amt LIKE orderdetl.ext_price_amt 
	END RECORD 
	
	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"E95_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT E95_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------


	LET l_query_text = 
	" SELECT orderdetl.cust_code,customer.name_text,orderdetl.order_num,orderhead.ord_text,orderdetl.line_num,orderdetl.part_code,orderdetl.ware_code,orderdetl.order_qty, ", 
	" orderdetl.picked_qty, orderdetl.back_qty, orderdetl.desc_text, orderdetl.uom_code, orderdetl.unit_price_amt, orderdetl.ext_price_amt FROM ", 
	" orderdetl, customer, orderhead WHERE orderdetl.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND customer.cmpy_code = orderdetl.cmpy_code ", 
	" AND customer.cust_code = orderdetl.cust_code ", 
	" AND orderdetl.cmpy_code = orderhead.cmpy_code ", 
	" AND orderdetl.cust_code = orderhead.cust_code ", 
	" AND orderdetl.order_num = orderhead.order_num ", 
	" AND ",glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("E95_rpt_list")].sel_text clipped," ",
	" ORDER BY orderdetl.cust_code, orderdetl.order_num, orderdetl.line_num" 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN FALSE 
	END IF 

	PREPARE choice FROM l_query_text 
	DECLARE selcurs cursor FOR choice 

	DISPLAY "Order: " at 1,2 

	FOREACH selcurs INTO l_rec_orderdetl.* 
		#---------------------------------------------------------
		OUTPUT TO REPORT E95_rpt_list(l_rpt_idx,
		l_rec_orderdetl.*)  
		IF NOT rpt_int_flag_handler2("Order:",l_rec_orderdetl.order_num, NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------		
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT E95_rpt_list
	CALL rpt_finish("E95_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = FALSE 
		ERROR " Printing was aborted" 
		RETURN FALSE 
	ELSE 
		RETURN TRUE 
	END IF
END FUNCTION 


###########################################################################
# REPORT E95_rpt_list(p_rpt_idx,p_rec_orderdetl) 
#
#
###########################################################################
REPORT E95_rpt_list(p_rpt_idx,p_rec_orderdetl) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE p_rec_orderdetl RECORD 
		cust_code LIKE orderdetl.cust_code, 
		name_text LIKE customer.name_text, 
		order_num LIKE orderdetl.order_num, 
		ord_text LIKE orderhead.ord_text, 
		line_num LIKE orderdetl.line_num, 
		part_code LIKE orderdetl.part_code, 
		ware_code LIKE orderdetl.ware_code, 
		order_qty LIKE orderdetl.order_qty, 
		picked_qty LIKE orderdetl.picked_qty, 
		back_qty LIKE orderdetl.back_qty, 
		desc_text LIKE orderdetl.desc_text, 
		uom_code LIKE orderdetl.uom_code, 
		unit_price_amt LIKE orderdetl.unit_price_amt, 
		ext_price_amt LIKE orderdetl.ext_price_amt 
	END RECORD 

	OUTPUT 

	ORDER external BY p_rec_orderdetl.cust_code, p_rec_orderdetl.order_num, 
	p_rec_orderdetl.line_num 

	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 1, "Line", 
			COLUMN 8,"Item", 
			COLUMN 23, "Ordered", 
			COLUMN 33, "Shipped", 
			COLUMN 43, "Backorder", 
			COLUMN 60, "Description", 
			COLUMN 95, "Unit", 
			COLUMN 101, "Unit price", 
			COLUMN 120, "Extended" 

			PRINT COLUMN 1, " # ", 
			COLUMN 8, " id", 
			COLUMN 23, " qty", 
			COLUMN 33, " qty", 
			COLUMN 43, " qty", 
			COLUMN 120, " price" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			#page trailer
			#IF print_option = "s" THEN
			#pause " Type RETURN TO continue"
			#END IF
		ON EVERY ROW 

			PRINT COLUMN 1, p_rec_orderdetl.line_num USING "###", 
			COLUMN 5, p_rec_orderdetl.part_code, 
			COLUMN 20, p_rec_orderdetl.order_qty USING "-----&.&&", 
			COLUMN 30, p_rec_orderdetl.picked_qty USING "-----&.&&", 
			COLUMN 40, p_rec_orderdetl.back_qty USING "-----&.&&", 
			COLUMN 55, p_rec_orderdetl.desc_text, 
			COLUMN 90, p_rec_orderdetl.uom_code, 
			COLUMN 100, p_rec_orderdetl.unit_price_amt USING "---,--&.&&", 
			COLUMN 115, p_rec_orderdetl.ext_price_amt USING "--,---,--&.&&" 

		ON LAST ROW 
			SKIP 1 line 
			PRINT COLUMN 2, "Report Totals: Lines: ", count(*) USING "###", 
			COLUMN 100, "Price:", 
			COLUMN 115, sum(p_rec_orderdetl.ext_price_amt) USING "--,---,--&.&&" 

			#End Of Report 
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			
			 
		BEFORE GROUP OF p_rec_orderdetl.cust_code 
			PRINT COLUMN 1, "ID: ",p_rec_orderdetl.cust_code, 
			COLUMN 15, p_rec_orderdetl.name_text clipped 
			SKIP 1 line 
			--LET rpt_pageno = pageno 

		BEFORE GROUP OF p_rec_orderdetl.order_num 
			PRINT COLUMN 5, "Order #: ", p_rec_orderdetl.order_num USING "########"; 
			IF p_rec_orderdetl.ord_text IS NOT NULL THEN 
				PRINT COLUMN 25, "Ref: ",p_rec_orderdetl.ord_text 
			ELSE 
				PRINT COLUMN 25, " " 
			END IF 
			
		AFTER GROUP OF p_rec_orderdetl.order_num 
			PRINT COLUMN 115, "===============" 
			PRINT COLUMN 115, GROUP sum(p_rec_orderdetl.ext_price_amt) USING "--,---,--&.&&" 

		AFTER GROUP OF p_rec_orderdetl.cust_code 
			PRINT COLUMN 10, "Client total:", 
			COLUMN 115, "===============" 
			PRINT COLUMN 115, GROUP sum(p_rec_orderdetl.ext_price_amt) USING "--,---,--&.&&" 

END REPORT 
