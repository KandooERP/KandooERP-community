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
GLOBALS "../eo/E9D_GLOBALS.4gl"
###########################################################################
# MODULE Variables
###########################################################################
	DEFINE modu_os_value_c decimal(16,2) 
	DEFINE modu_os_value_cust_c decimal(16,2) 
	DEFINE modu_os_value_tot_c decimal(16,2) 
	DEFINE modu_os_value_i decimal(16,2) 
	DEFINE modu_os_value_cust_i decimal(16,2) 
	DEFINE modu_os_value_tot_i decimal(16,2) 
###########################################################################
# FUNCTION E9D_main()
#
# E9D Sales Order Status Report
###########################################################################
FUNCTION E9D_main()
	DEFER QUIT 
	DEFER INTERRUPT 
	
	CALL setModuleId("E9D") -- albo 

	LET modu_os_value_c = 0 
	LET modu_os_value_cust_c = 0 
	LET modu_os_value_tot_c = 0 
	LET modu_os_value_i = 0 
	LET modu_os_value_cust_i = 0 
	LET modu_os_value_tot_i = 0 

	#LET glob_rec_arparms.inv_ref1_text = glob_rec_arparms.inv_ref1_text clipped, "................" 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 	

			OPEN WINDOW E456 with FORM "E456" 
			 CALL windecoration_e("E456") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title
		
			DISPLAY glob_rec_arparms.inv_ref1_text TO inv_ref1_text attribute (white) 
		
			MENU " Order Status report" 
		
				BEFORE MENU 
					CALL publish_toolbar("kandoo","E9D","menu-Order_Status-1") -- albo kd-502 
		
				ON ACTION "WEB-HELP" -- albo kd-370 
					CALL onlinehelp(getmoduleid(),null) 
		
				COMMAND "Incomplete" " SELECT incomplete orders FOR report" 
					CALL E9D_rpt_query("I") 
		
				COMMAND "Completed" " SELECT completed orders FOR report" 
					CALL E9D_rpt_query("C") 
		
				COMMAND "Both" " SELECT both incomplete & completed orders FOR report" 
					CALL E9D_rpt_query("B") 
		
				ON ACTION "PRINT MANAGER" 			#COMMAND KEY ("P",f11) "Print" "Print OR view using RMS"
					CALL run_prog("URS","","","","") 
	
				ON ACTION "CANCEL" #COMMAND key(INTERRUPT, "E") "Exit" "Exit this program" 
					EXIT MENU 
		
			END MENU 
		
			CLOSE WINDOW E456 
		
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL E9D_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW E400 with FORM "E456" 
			 CALL windecoration_e("E456") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(E9D_rpt_query("B")) #save where clause in env 
			CLOSE WINDOW E456 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL E9D_rpt_process(get_url_sel_text())
	END CASE 	
END FUNCTION 
###########################################################################
# END FUNCTION E9D_main()
###########################################################################

###########################################################################
# FUNCTION E9D_rpt_query(p_order_type)
#
# 
###########################################################################
FUNCTION E9D_rpt_query(p_order_type) 
	DEFINE l_where_text STRING
	DEFINE p_order_type char(1) 

	MESSAGE kandoomsg2("U",1001,"") 

	CONSTRUCT BY NAME l_where_text ON 
	orderhead.cust_code, 
	orderhead.ord_text, 
	orderhead.order_num, 
	orderhead.order_date, 
	orderdetl.part_code, 
	orderdetl.order_qty, 
	orderhead.goods_amt, 
	orderhead.total_amt 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","E9D","construct-orderhead-1") -- albo kd-502 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 
	
	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		MESSAGE kandoomsg2("U",9501,"") 
		RETURN NULL
	ELSE
		LET glob_rec_rpt_selector.ref1_ind = p_order_type
		RETURN l_where_text
	END IF 

END FUNCTION
###########################################################################
# END FUNCTION E9D_rpt_query(p_order_type)
###########################################################################


############################################################
# FUNCTION E9D_rpt_process(p_where_text) 
#
#
############################################################
FUNCTION E9D_rpt_process(p_where_text) 
	DEFINE p_where_text STRING
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE l_order_type CHAR #"C"omplete or "I"ncomplete order report
	DEFINE l_status_sel_text STRING
	--DEFINE l_status_sel_text char(27) 
	DEFINE l_prev_cust_code LIKE orderhead.cust_code 
	DEFINE l_prev_order_num LIKE orderhead.order_num 
	DEFINE l_rec_report_line RECORD 
		cmpy_code LIKE orderhead.cmpy_code, 
		cust_code LIKE orderhead.cust_code, 
		order_num LIKE orderhead.order_num, 
		ord_text LIKE orderhead.ord_text, 
		status_ind LIKE orderhead.status_ind, 
		ware_code LIKE orderhead.ware_code, 
		line_num LIKE orderdetl.line_num, 
		part_code LIKE orderdetl.part_code, 
		desc_text LIKE orderdetl.desc_text, 
		order_qty LIKE orderdetl.order_qty, 
		inv_qty LIKE orderdetl.inv_qty, 
		unit_price_amt LIKE orderdetl.unit_price_amt, 
		inv_num LIKE invoicedetl.inv_num, 
		ship_qty LIKE invoicedetl.ship_qty, 
		unit_sale_amt LIKE invoicedetl.unit_sale_amt 
	END RECORD 		 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE

		RETURN FALSE		
	END IF
	IF get_url_report_code() IS NOT NULL THEN
		LET l_order_type = db_rmsreps_get_ref1_ind(UI_OFF,get_url_report_code())
	END IF

	IF l_order_type = "C" OR l_order_type = "B" THEN
		LET l_rpt_idx = rpt_start("E9D-C","E9D_rpt_list_c",p_where_text, RPT_SHOW_RMS_DIALOG)
		IF l_rpt_idx = 0 THEN #User pressed CANCEL
			RETURN FALSE
		END IF	
		START REPORT E9D_rpt_list_c TO rpt_get_report_file_with_path2(l_rpt_idx)
		WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
		TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
		BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
		LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
		RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
		LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	END IF

	IF l_order_type = "I" OR l_order_type = "B" THEN
		LET l_rpt_idx = rpt_start("E9D-I","E9D_rpt_list_i",p_where_text, RPT_SHOW_RMS_DIALOG)
		IF l_rpt_idx = 0 THEN #User pressed CANCEL
			RETURN FALSE
		END IF	
		START REPORT E9D_rpt_list_i TO rpt_get_report_file_with_path2(l_rpt_idx)
		WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
		TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
		BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
		LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
		RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
		IF p_where_text IS NULL THEN
			LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
		END IF
	END IF


	#------------------------------------------------------------
#	# Retrieve rmsreps data
#	IF l_order_type IS NOT NULL THEN
#		LET l_order_type = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref1_ind
#	END IF
	#------------------------------------------------------------

	#------------------------------------------------------------



	IF l_order_type = "C" THEN 
		LET l_status_sel_text = "orderhead.status_ind = \"C\" " 
	ELSE 
		IF l_order_type = "I" THEN 
			LET l_status_sel_text = "orderhead.status_ind != \"C\" " 
		ELSE 
			LET l_status_sel_text = "1=1 " 
		END IF 
	END IF 

	LET l_query_text = 
	"SELECT orderhead.cmpy_code, ", 
	"orderhead.cust_code, ", 
	"orderhead.order_num, ", 
	"orderhead.ord_text, ", 
	"orderhead.status_ind, ", 
	"orderhead.ware_code, ", 
	"orderdetl.line_num, ", 
	"orderdetl.part_code, ", 
	"orderdetl.desc_text, ", 
	"orderdetl.order_qty, ", 
	"orderdetl.inv_qty, ", 
	"orderdetl.unit_price_amt, ", 
	"invoicedetl.inv_num, ", 
	"invoicedetl.ship_qty, ", 
	"invoicedetl.unit_sale_amt ", 
	"FROM orderhead, ", 
	"orderdetl, ", 
	"outer invoicedetl ", 
	"WHERE orderhead.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\"", 
	" AND orderhead.cmpy_code = orderdetl.cmpy_code ", 
	" AND orderhead.cust_code = orderdetl.cust_code ", 
	" AND orderhead.order_num = orderdetl.order_num ", 
	" AND orderdetl.cmpy_code = invoicedetl.cmpy_code ", 
	" AND orderdetl.order_num = invoicedetl.order_num ", 
	" AND orderdetl.line_num = invoicedetl.order_line_num ", 
	" AND orderdetl.order_qty != 0 ", 
	" AND orderdetl.order_qty IS NOT NULL ", " ",
	" AND ", l_status_sel_text clipped,	
	"AND ", p_where_text clipped," ",	
	" ORDER BY orderhead.cust_code, ", 
	"orderhead.order_num, ", 
	"orderdetl.line_num" 

	PREPARE p_order FROM l_query_text 
	DECLARE c_orderdetl cursor FOR p_order 

--	DISPLAY " customer:" at 1,10 
--
--	DISPLAY " Order number:" at 2,10 

	LET l_prev_cust_code = NULL 
	LET l_prev_order_num = NULL 

	FOREACH c_orderdetl INTO l_rec_report_line.* 
		IF l_prev_cust_code != l_rec_report_line.cust_code OR l_prev_cust_code IS NULL THEN 
--			DISPLAY l_rec_report_line.cust_code at 1,24 
--
--			DISPLAY l_rec_report_line.order_num at 2,24 

			LET l_prev_cust_code = l_rec_report_line.cust_code 
			LET l_prev_order_num = l_rec_report_line.order_num 
		END IF 

		IF l_prev_order_num != l_rec_report_line.order_num OR	l_prev_order_num IS NULL THEN 
--			DISPLAY l_rec_report_line.order_num at 2,24 

			LET l_prev_order_num = l_rec_report_line.order_num 
		END IF 

		IF int_flag OR quit_flag THEN 
			#8503 Continue Report(Y/N)
			IF kandoomsg("U",8503,"") = "N" THEN 
					ERROR kandoomsg2("U",9501,"") #9501 Report Terminated		 
					SLEEP 2
				EXIT FOREACH 
			END IF 
		END IF 

		IF l_rec_report_line.status_ind = "C" THEN 
			OUTPUT TO REPORT E9D_list_c(l_rec_report_line.*,l_rpt_idx) 
		ELSE 
			OUTPUT TO REPORT E9D_list_i(l_rec_report_line.*,l_rpt_idx) 
		END IF 
	END FOREACH 

	IF l_order_type = "B" OR l_order_type = "C" THEN 
		#------------------------------------------------------------
		FINISH REPORT E9D_rpt_list_c
		CALL rpt_finish("E9D_rpt_list_c")
		#------------------------------------------------------------
	END IF 

	IF l_order_type = "B" OR l_order_type = "I" THEN 
		#------------------------------------------------------------
		FINISH REPORT E9D_rpt_list_i
		CALL rpt_finish("E9D_rpt_list_i")
		#------------------------------------------------------------ 
	END IF 


END FUNCTION 
############################################################
# END FUNCTION E9D_rpt_process(p_where_text) 
############################################################


###########################################################################
# REPORT E9D_list_c(l_rec_report_line) 
#
# E9D Sales Order Status Report
###########################################################################
REPORT E9D_list_c(p_rpt_idx,l_rec_report_line) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE l_rec_report_line RECORD 
		cmpy_code LIKE orderhead.cmpy_code, 
		cust_code LIKE orderhead.cust_code, 
		order_num LIKE orderhead.order_num, 
		ord_text LIKE orderhead.ord_text, 
		status_ind LIKE orderhead.status_ind, 
		ware_code LIKE orderhead.ware_code, 
		line_num LIKE orderdetl.line_num, 
		part_code LIKE orderdetl.part_code, 
		desc_text LIKE orderdetl.desc_text, 
		order_qty LIKE orderdetl.order_qty, 
		inv_qty LIKE orderdetl.inv_qty, 
		unit_price_amt LIKE orderdetl.unit_price_amt, 
		inv_num LIKE invoicedetl.inv_num, 
		ship_qty LIKE invoicedetl.ship_qty, 
		unit_sale_amt LIKE invoicedetl.unit_sale_amt 
	END RECORD 
	DEFINE l_cust_code_text LIKE orderhead.cust_code 
	DEFINE l_order_num_text char(8) 
	DEFINE l_cust_ref_text LIKE orderhead.ord_text
	DEFINE l_part_code_text LIKE orderdetl.part_code 
	DEFINE l_order_qty_text, l_os_qty_text char(10) 
	DEFINE l_os_value_text char(12) 
	DEFINE l_pick_num LIKE pickdetl.pick_num 
	DEFINE l_top_of_page SMALLINT 

	OUTPUT 

	ORDER external BY l_rec_report_line.cust_code, 
	l_rec_report_line.order_num, 
	l_rec_report_line.line_num 

	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 1, "Customer", 
			COLUMN 10, "Customer", 
			COLUMN 34, "Order", 
			COLUMN 40, "Product", 
			COLUMN 59, "Order", 
			COLUMN 71, "Pick", 
			COLUMN 79, "Invoice", 
			COLUMN 88, "Invoice", 
			COLUMN 101, "Invoice", 
			COLUMN 112, "Outstdg", 
			COLUMN 125, "Outstdg" 

			PRINT COLUMN 3, "Code", 
			COLUMN 10, "Reference", 
			COLUMN 33, "Number", 
			COLUMN 42, "Code", 
			COLUMN 58, "Quantity", 
			COLUMN 70, "Number", 
			COLUMN 80, "Number", 
			COLUMN 88, "Quantity", 
			COLUMN 102, "Value", 
			COLUMN 111, "Quantity", 
			COLUMN 126, "Value" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			LET l_top_of_page = TRUE 

			LET l_cust_code_text = l_rec_report_line.cust_code 
			LET l_order_num_text = l_rec_report_line.order_num USING "########" 
			LET l_cust_ref_text = l_rec_report_line.ord_text 
			IF l_rec_report_line.part_code IS NULL THEN 
				LET l_part_code_text = l_rec_report_line.desc_text 
			ELSE 
				LET l_part_code_text = l_rec_report_line.part_code 
			END IF 
			LET l_order_qty_text = 
			l_rec_report_line.order_qty USING "------&.&&" 
			IF l_rec_report_line.order_qty <= l_rec_report_line.inv_qty THEN 
				LET l_os_qty_text = NULL 
				LET l_os_value_text = NULL 
			ELSE 
				LET l_os_qty_text = 
				(l_rec_report_line.order_qty - l_rec_report_line.inv_qty) 
				USING "------&.&&" 
				LET l_os_value_text = 
				((l_rec_report_line.order_qty - l_rec_report_line.inv_qty) * 
				l_rec_report_line.unit_price_amt) USING "--------&.&&" 
			END IF 


		BEFORE GROUP OF l_rec_report_line.cust_code 
			LET l_cust_code_text = l_rec_report_line.cust_code 
			IF NOT l_top_of_page THEN 
				SKIP 1 line 
			END IF 

		BEFORE GROUP OF l_rec_report_line.order_num 
			LET l_order_num_text = l_rec_report_line.order_num USING "########" 
			LET l_cust_ref_text = l_rec_report_line.ord_text 
			IF NOT l_top_of_page THEN 
				SKIP 1 line 
			END IF 

		AFTER GROUP OF l_rec_report_line.order_num 
			NEED 3 LINES 
			PRINT COLUMN 56, ' --------', 
			COLUMN 86, ' --------', 
			COLUMN 98, ' --------', 
			COLUMN 109, ' --------', 
			COLUMN 120, ' ----------' 
			PRINT COLUMN 56, GROUP sum(l_rec_report_line.order_qty) USING "------&.&&", 
			COLUMN 86, GROUP sum(l_rec_report_line.ship_qty) 
			USING "------&.&&", 
			COLUMN 98, 
			GROUP sum(l_rec_report_line.ship_qty * l_rec_report_line.unit_sale_amt) 
			USING "------&.&&", 
			COLUMN 109, GROUP sum(l_rec_report_line.order_qty - l_rec_report_line.inv_qty) USING "------&.&&", 
			COLUMN 120, modu_os_value_c USING "--------&.&&" 
			LET modu_os_value_cust_c = modu_os_value_cust_c + modu_os_value_c 
			LET modu_os_value_c = 0 
			IF l_top_of_page THEN 
				SKIP 2 line 
			END IF 

		AFTER GROUP OF l_rec_report_line.cust_code 
			SKIP 1 line 
			PRINT COLUMN 56, ' --------', 
			COLUMN 86, ' --------', 
			COLUMN 98, ' --------', 
			COLUMN 109, ' --------', 
			COLUMN 120, ' ----------' 
			PRINT COLUMN 30, 'customer total :', 
			COLUMN 56, GROUP sum(l_rec_report_line.order_qty) USING "------&.&&", 
			COLUMN 86, GROUP sum(l_rec_report_line.ship_qty) 
			USING "------&.&&", 
			COLUMN 98, 
			GROUP sum(l_rec_report_line.ship_qty * l_rec_report_line.unit_sale_amt) 
			USING "------&.&&", 
			COLUMN 109, GROUP sum(l_rec_report_line.order_qty - l_rec_report_line.inv_qty) USING "------&.&&", 
			COLUMN 120, modu_os_value_cust_c USING "--------&.&&" 
			LET modu_os_value_tot_c = modu_os_value_tot_c + modu_os_value_cust_c 
			LET modu_os_value_c = 0 
			IF l_top_of_page THEN 
				SKIP 2 line 
			END IF 


		BEFORE GROUP OF l_rec_report_line.line_num 
			IF l_rec_report_line.part_code IS NULL THEN 
				LET l_part_code_text = l_rec_report_line.desc_text 
			ELSE 
				LET l_part_code_text = l_rec_report_line.part_code 
			END IF 
			LET l_order_qty_text = 
			l_rec_report_line.order_qty USING "------&.&&" 
			IF l_rec_report_line.order_qty <= l_rec_report_line.inv_qty THEN 
				LET l_os_qty_text = NULL 
				LET l_os_value_text = NULL 
			ELSE 
				LET l_os_qty_text = 
				(l_rec_report_line.order_qty - l_rec_report_line.inv_qty) 
				USING "------&.&&" 
				LET l_os_value_text = 
				((l_rec_report_line.order_qty - l_rec_report_line.inv_qty) * 
				l_rec_report_line.unit_price_amt) USING "--------&.&&" 
			END IF 
			IF NOT l_top_of_page THEN 
				SKIP 1 line 
			END IF 

		ON EVERY ROW 
			LET l_pick_num = NULL 
			IF l_rec_report_line.inv_num IS NOT NULL THEN 
				SELECT ref_num 
				INTO l_pick_num 
				FROM invoicehead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cust_code = l_rec_report_line.cust_code 
				AND inv_num = l_rec_report_line.inv_num 
			END IF 
			IF l_pick_num IS NULL THEN 
				DECLARE c_pickdetl cursor FOR 
				SELECT pick_num 
				INTO l_pick_num 
				FROM pickdetl 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND ware_code = l_rec_report_line.ware_code 
				AND order_num = l_rec_report_line.order_num 
				AND order_line_num = l_rec_report_line.line_num 
				FOREACH c_pickdetl INTO l_pick_num 
					EXIT FOREACH 
				END FOREACH 
			END IF 

			PRINT COLUMN 01, l_cust_code_text, 
			COLUMN 10, l_cust_ref_text, 
			COLUMN 31, l_order_num_text, 
			COLUMN 40, l_part_code_text, 
			COLUMN 56, l_order_qty_text, 
			COLUMN 67, l_pick_num USING "#########", 
			COLUMN 77, l_rec_report_line.inv_num USING "#########", 
			COLUMN 86, l_rec_report_line.ship_qty USING "------&.&&", 
			COLUMN 98, 
			(l_rec_report_line.ship_qty * l_rec_report_line.unit_sale_amt) 
			USING "------&.&&", 
			COLUMN 109, l_os_qty_text, 
			COLUMN 120, l_os_value_text 

			LET l_cust_code_text = NULL 
			LET l_cust_ref_text = NULL 
			LET l_order_num_text = NULL 
			LET l_part_code_text = NULL 
			LET l_order_qty_text = NULL 
			LET l_os_qty_text = NULL 
			LET l_os_value_text = NULL 
			LET l_top_of_page = FALSE 

		ON LAST ROW 
			SKIP 6 line 
			PRINT COLUMN 56, ' ========', 
			COLUMN 86, ' ========', 
			COLUMN 98, ' ========', 
			COLUMN 109, ' ========', 
			COLUMN 120, ' ==========' 
			PRINT COLUMN 30, 'report total :', 
			COLUMN 56, sum(l_rec_report_line.order_qty) USING "------&.&&", 
			COLUMN 86, sum(l_rec_report_line.ship_qty) 
			USING "------&.&&", 
			COLUMN 98, 
			sum(l_rec_report_line.ship_qty * l_rec_report_line.unit_sale_amt) 
			USING "------&.&&", 
			COLUMN 109, sum(l_rec_report_line.order_qty - l_rec_report_line.inv_qty) USING "------&.&&", 
			COLUMN 120, modu_os_value_tot_c USING "--------&.&&" 
			LET modu_os_value_cust_c = 0 

			SKIP 1 line 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	


END REPORT 
###########################################################################
# END REPORT E9D_list_c(l_rec_report_line) 
###########################################################################


###########################################################################
# REPORT E9D_list_i(p_rpt_idx,p_rec_report_line)
#
# 
###########################################################################
REPORT E9D_list_i(p_rpt_idx,p_rec_report_line) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE p_rec_report_line RECORD 
		cmpy_code LIKE orderhead.cmpy_code, 
		cust_code LIKE orderhead.cust_code, 
		order_num LIKE orderhead.order_num, 
		ord_text LIKE orderhead.ord_text, 
		status_ind LIKE orderhead.status_ind, 
		ware_code LIKE orderhead.ware_code, 
		line_num LIKE orderdetl.line_num, 
		part_code LIKE orderdetl.part_code, 
		desc_text LIKE orderdetl.desc_text, 
		order_qty LIKE orderdetl.order_qty, 
		inv_qty LIKE orderdetl.inv_qty, 
		unit_price_amt LIKE orderdetl.unit_price_amt, 
		inv_num LIKE invoicedetl.inv_num, 
		ship_qty LIKE invoicedetl.ship_qty, 
		unit_sale_amt LIKE invoicedetl.unit_sale_amt 
	END RECORD 
	DEFINE l_cust_code_text LIKE orderhead.cust_code 
	DEFINE l_order_num_text char(8) 
	DEFINE l_cust_ref_text LIKE orderhead.ord_text 
	DEFINE l_part_code_text LIKE orderdetl.part_code 
	DEFINE l_order_qty_text char(10) 
	DEFINE l_os_qty_text char(10) 
	DEFINE l_os_value_text char(12) 
	DEFINE l_pick_num LIKE pickdetl.pick_num 
	DEFINE l_top_of_page SMALLINT 

	OUTPUT 

	ORDER external BY p_rec_report_line.cust_code, 
	p_rec_report_line.order_num, 
	p_rec_report_line.line_num 

	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 1, "Customer", 
			COLUMN 10, "Customer", 
			COLUMN 34, "Order", 
			COLUMN 40, "Product", 
			COLUMN 59, "Order", 
			COLUMN 71, "Pick", 
			COLUMN 79, "Invoice", 
			COLUMN 88, "Invoice", 
			COLUMN 101, "Invoice", 
			COLUMN 112, "Outstdg", 
			COLUMN 125, "Outstdg" 

			PRINT COLUMN 3, "Code", 
			COLUMN 10, "Reference", 
			COLUMN 33, "Number", 
			COLUMN 42, "Code", 
			COLUMN 58, "Quantity", 
			COLUMN 70, "Number", 
			COLUMN 80, "Number", 
			COLUMN 88, "Quantity", 
			COLUMN 102, "Value", 
			COLUMN 111, "Quantity", 
			COLUMN 126, "Value" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			LET l_top_of_page = TRUE 

			LET l_cust_code_text = p_rec_report_line.cust_code 
			LET l_order_num_text = p_rec_report_line.order_num USING "########" 
			LET l_cust_ref_text = p_rec_report_line.ord_text 
			IF p_rec_report_line.part_code IS NULL THEN 
				LET l_part_code_text = p_rec_report_line.desc_text 
			ELSE 
				LET l_part_code_text = p_rec_report_line.part_code 
			END IF 
			LET l_order_qty_text = 
			p_rec_report_line.order_qty USING "------&.&&" 
			IF p_rec_report_line.order_qty <= p_rec_report_line.inv_qty THEN 
				LET l_os_qty_text = NULL 
				LET l_os_value_text = NULL 
			ELSE 
				LET l_os_qty_text = 
				(p_rec_report_line.order_qty - p_rec_report_line.inv_qty) 
				USING "------&.&&" 
				LET l_os_value_text = 
				((p_rec_report_line.order_qty - p_rec_report_line.inv_qty) * 
				p_rec_report_line.unit_price_amt) USING "--------&.&&" 
			END IF 


		BEFORE GROUP OF p_rec_report_line.cust_code 
			LET l_cust_code_text = p_rec_report_line.cust_code 
			IF NOT l_top_of_page THEN 
				SKIP 1 line 
			END IF 

		BEFORE GROUP OF p_rec_report_line.order_num 
			LET l_order_num_text = p_rec_report_line.order_num USING "########" 
			IF NOT l_top_of_page THEN 
				SKIP 1 line 
			END IF 

		AFTER GROUP OF p_rec_report_line.order_num 
			NEED 3 LINES 
			PRINT COLUMN 56, ' --------', 
			COLUMN 86, ' --------', 
			COLUMN 98, ' --------', 
			COLUMN 109, ' --------', 
			COLUMN 120, ' ----------' 
			PRINT COLUMN 56, GROUP sum(p_rec_report_line.order_qty) USING "------&.&&", 
			COLUMN 86, GROUP sum(p_rec_report_line.ship_qty) 
			USING "------&.&&", 
			COLUMN 98, 
			GROUP sum(p_rec_report_line.ship_qty * p_rec_report_line.unit_sale_amt) 
			USING "------&.&&", 
			COLUMN 109, GROUP sum(p_rec_report_line.order_qty - p_rec_report_line.inv_qty) USING "------&.&&", 
			COLUMN 120, modu_os_value_i USING "--------&.&&" 
			LET modu_os_value_cust_i = modu_os_value_cust_i + modu_os_value_i 
			LET modu_os_value_i = 0 
			IF l_top_of_page THEN 
				SKIP 2 line 
			END IF 

		AFTER GROUP OF p_rec_report_line.cust_code 
			SKIP 1 line 
			PRINT COLUMN 56, ' --------', 
			COLUMN 86, ' --------', 
			COLUMN 98, ' --------', 
			COLUMN 109, ' --------', 
			COLUMN 120, ' ----------' 
			PRINT COLUMN 30, 'customer total :', 
			COLUMN 56, GROUP sum(p_rec_report_line.order_qty) USING "------&.&&", 
			COLUMN 86, GROUP sum(p_rec_report_line.ship_qty) 
			USING "------&.&&", 
			COLUMN 98, 
			GROUP sum(p_rec_report_line.ship_qty * p_rec_report_line.unit_sale_amt) 
			USING "------&.&&", 
			COLUMN 109, GROUP sum(p_rec_report_line.order_qty - p_rec_report_line.inv_qty) USING "------&.&&", 
			#   COLUMN 120, group sum((p_rec_report_line.order_qty - p_rec_report_line.inv_qty)* p_rec_report_line.unit_price_amt ) using "--------&.&&"
			COLUMN 120, modu_os_value_cust_i USING "--------&.&&" 
			LET modu_os_value_tot_i = modu_os_value_tot_i + modu_os_value_cust_i 
			LET modu_os_value_cust_i = 0 
			IF l_top_of_page THEN 
				SKIP 2 line 
			END IF 

		BEFORE GROUP OF p_rec_report_line.line_num 
			IF p_rec_report_line.part_code IS NULL THEN 
				LET l_part_code_text = p_rec_report_line.desc_text 
			ELSE 
				LET l_part_code_text = p_rec_report_line.part_code 
			END IF 
			LET l_order_qty_text = 
			p_rec_report_line.order_qty USING "------&.&&" 
			IF p_rec_report_line.order_qty <= p_rec_report_line.inv_qty THEN 
				LET l_os_qty_text = NULL 
				LET l_os_value_text = NULL 
			ELSE 
				LET l_os_qty_text = 
				(p_rec_report_line.order_qty - p_rec_report_line.inv_qty) 
				USING "------&.&&" 
				LET l_os_value_text = 
				((p_rec_report_line.order_qty - p_rec_report_line.inv_qty) * 
				p_rec_report_line.unit_price_amt) USING "--------&.&&" 
				LET modu_os_value_i = modu_os_value_i + 
				((p_rec_report_line.order_qty - p_rec_report_line.inv_qty) * 
				p_rec_report_line.unit_price_amt) 
			END IF 
			IF NOT l_top_of_page THEN 
				SKIP 1 line 
			END IF 

		ON EVERY ROW 
			LET l_pick_num = NULL 
			IF p_rec_report_line.inv_num IS NOT NULL THEN 
				SELECT ref_num 
				INTO l_pick_num 
				FROM invoicehead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cust_code = p_rec_report_line.cust_code 
				AND inv_num = p_rec_report_line.inv_num 
			END IF 
			IF l_pick_num IS NULL THEN 
				DECLARE c_pickdetl2 cursor FOR 
				SELECT pick_num 
				INTO l_pick_num 
				FROM pickdetl 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND ware_code = p_rec_report_line.ware_code 
				AND order_num = p_rec_report_line.order_num 
				AND order_line_num = p_rec_report_line.line_num 
				FOREACH c_pickdetl2 INTO l_pick_num 
					EXIT FOREACH 
				END FOREACH 
			END IF 

			PRINT COLUMN 01, l_cust_code_text, 
			COLUMN 10, l_cust_ref_text, 
			COLUMN 31, l_order_num_text, 
			COLUMN 40, l_part_code_text, 
			COLUMN 56, l_order_qty_text, 
			COLUMN 67, l_pick_num USING "#########", 
			COLUMN 77, p_rec_report_line.inv_num USING "#########", 
			COLUMN 86, p_rec_report_line.ship_qty USING "------&.&&", 
			COLUMN 98, 
			(p_rec_report_line.ship_qty * p_rec_report_line.unit_sale_amt) 
			USING "------&.&&", 
			COLUMN 109, l_os_qty_text, 
			COLUMN 120, l_os_value_text 

			LET l_cust_code_text = NULL 
			LET l_cust_ref_text = NULL 
			LET l_order_num_text = NULL 
			LET l_part_code_text = NULL 
			LET l_order_qty_text = NULL 
			LET l_os_qty_text = NULL 
			LET l_os_value_text = NULL 
			LET l_top_of_page = FALSE 

		ON LAST ROW 
			SKIP 6 line 
			PRINT COLUMN 56, ' ========', 
			COLUMN 86, ' ========', 
			COLUMN 98, ' ========', 
			COLUMN 109, ' ========', 
			COLUMN 120, ' ==========' 
			PRINT COLUMN 30, 'report total :', 
			COLUMN 56, sum(p_rec_report_line.order_qty) USING "------&.&&", 
			COLUMN 86, sum(p_rec_report_line.ship_qty) 
			USING "------&.&&", 
			COLUMN 98, 
			sum(p_rec_report_line.ship_qty * p_rec_report_line.unit_sale_amt) 
			USING "------&.&&", 
			COLUMN 109, sum(p_rec_report_line.order_qty - p_rec_report_line.inv_qty) USING "------&.&&", 
			COLUMN 120, modu_os_value_tot_i USING "--------&.&&" 
			LET modu_os_value_tot_i = 0 

			SKIP 1 line 
			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			

END REPORT 
###########################################################################
# END REPORT E9D_list_i(p_rpt_idx,p_rec_report_line)
###########################################################################