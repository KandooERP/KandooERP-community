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
GLOBALS "../eo/E9A_GLOBALS.4gl"
###########################################################################
# FUNCTION E9A_main() 
#
# 
###########################################################################
FUNCTION E9A_main() 
	DEFER QUIT 
	DEFER INTERRUPT 

	CALL setModuleId("E98") 
	
	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 	
			OPEN WINDOW E419 with FORM "E419" 
			 CALL windecoration_e("E419")
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title

			MENU " Current Order detail" 
		
				BEFORE MENU 
					CALL publish_toolbar("kandoo","E9A","menu-Current_Order-1") -- albo kd-502 
					CALL rpt_rmsreps_reset(NULL)
					CALL E9A_rpt_process(E9A_rpt_query())
					
				ON ACTION "WEB-HELP" -- albo kd-370 
					CALL onlinehelp(getmoduleid(),null) 
		
				COMMAND "Run report" " SELECT criteria AND PRINT report" 
					CALL rpt_rmsreps_reset(NULL)
					CALL E9A_rpt_process(E9A_rpt_query())
		
				ON ACTION "PRINT MANAGER"				#COMMAND "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "CANCEL" #COMMAND KEY("INTERRUPT","E") "Exit" " Exit TO menus" 
					EXIT MENU 

			END MENU 
			CLOSE WINDOW E419

		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL E9A_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW E419 with FORM "E419" 
			 CALL windecoration_e("E419") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(E9A_rpt_query()) #save where clause in env 
			CLOSE WINDOW E419 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL E9A_rpt_process(get_url_sel_text())
	END CASE 	
END FUNCTION 
###########################################################################
# END FUNCTION E9A_main() 
###########################################################################


############################################################
# FUNCTION E9A_rpt_query() 
#
# CONSTRUCT where clause for report data
# RETURN NULL or l_where_text
############################################################
FUNCTION E9A_rpt_query() 
	DEFINE l_where_text STRING

	MESSAGE kandoomsg2("U",1001,"") #1001 "Enter criteria FOR selection - ESC TO begin search"
	CONSTRUCT BY NAME l_where_text ON orderdetl.cust_code, 
	customer.name_text, 
	orderdetl.part_code, 
	orderdetl.order_qty, 
	orderdetl.desc_text, 
	orderdetl.unit_price_amt 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","E9A","construct-orderdetl-1") -- albo kd-502 

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
# END FUNCTION E9A_rpt_query() 
############################################################


############################################################
# FUNCTION E9A_rpt_process(p_where_text) 
#
#
############################################################
FUNCTION E9A_rpt_process(p_where_text) 
	DEFINE p_where_text STRING
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	

	DEFINE l_rec_orderdetl RECORD 
		cust_code LIKE orderdetl.cust_code, 
		name_text LIKE customer.name_text, 
		order_num LIKE orderdetl.order_num, 
		line_num LIKE orderdetl.line_num, 
		part_code LIKE orderdetl.part_code, 
		ware_code LIKE orderdetl.ware_code, 
		order_qty LIKE orderdetl.order_qty, 
		picked_qty LIKE orderdetl.picked_qty, 
		sched_qty LIKE orderdetl.sched_qty, 
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

	LET l_rpt_idx = rpt_start(getmoduleid(),"E9A_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT E9A_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------
	
	LET l_query_text = "SELECT orderdetl.cust_code,customer.name_text,", 
	"orderdetl.order_num,orderdetl.line_num,", 
	"orderdetl.part_code,orderdetl.ware_code,", 
	"orderdetl.order_qty, orderdetl.picked_qty,", 
	"orderdetl.sched_qty, orderdetl.desc_text,", 
	"orderdetl.uom_code, orderdetl.unit_price_amt,", 
	"orderdetl.ext_price_amt ", 
	" FROM orderdetl, customer ", 
	" WHERE orderdetl.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\"", 
	" AND customer.cmpy_code = orderdetl.cmpy_code ", 
	" AND customer.cust_code = orderdetl.cust_code ", 
	" AND ", p_where_text clipped, 
	" AND (orderdetl.picked_qty > 0 ", 
	" OR orderdetl.sched_qty > 0) ", 
	" ORDER BY orderdetl.cust_code, orderdetl.order_num, ", 
	" orderdetl.line_num" 
	PREPARE s_orderdetl FROM l_query_text 
	DECLARE c_orderdetl cursor FOR s_orderdetl 

	FOREACH c_orderdetl INTO l_rec_orderdetl.* 
		LET l_rec_orderdetl.ext_price_amt = l_rec_orderdetl.unit_price_amt 
		* (l_rec_orderdetl.picked_qty 
		+ l_rec_orderdetl.sched_qty) 
		#---------------------------------------------------------
		OUTPUT TO REPORT E9A_rpt_list(l_rpt_idx,
		l_rec_orderdetl.*)  
		IF NOT rpt_int_flag_handler2("Reporting on Order:",l_rec_orderdetl.order_num, NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------				
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT E9A_rpt_list
	CALL rpt_finish("E9A_rpt_list")
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
# END FUNCTION E9A_rpt_process(p_where_text) 
############################################################


############################################################
# REPORT E9A_rpt_list(p_rec_orderhead) 
#
#
############################################################
REPORT E9A_rpt_list(p_rpt_idx,p_rec_orderdetl) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE p_rec_orderdetl RECORD 
		cust_code LIKE orderdetl.cust_code, 
		name_text LIKE customer.name_text, 
		order_num LIKE orderdetl.order_num, 
		line_num LIKE orderdetl.line_num, 
		part_code LIKE orderdetl.part_code, 
		ware_code LIKE orderdetl.ware_code, 
		order_qty LIKE orderdetl.order_qty, 
		picked_qty LIKE orderdetl.picked_qty, 
		sched_qty LIKE orderdetl.sched_qty, 
		desc_text LIKE orderdetl.desc_text, 
		uom_code LIKE orderdetl.uom_code, 
		unit_price_amt LIKE orderdetl.unit_price_amt, 
		ext_price_amt LIKE orderdetl.ext_price_amt 
	END RECORD 

	OUTPUT 

	ORDER external BY p_rec_orderdetl.cust_code, p_rec_orderdetl.order_num, p_rec_orderdetl.line_num 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 1, "Line", 
			COLUMN 8,"Product", 
			COLUMN 23, "Ordered", 
			COLUMN 33, "Scheduled", 
			COLUMN 43, "Picked", 
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

		ON EVERY ROW 
			PRINT COLUMN 1, p_rec_orderdetl.line_num USING "###", 
			COLUMN 5, p_rec_orderdetl.part_code, 
			COLUMN 20, p_rec_orderdetl.order_qty USING "######.##", 
			COLUMN 30, p_rec_orderdetl.sched_qty USING "######.##", 
			COLUMN 40, p_rec_orderdetl.picked_qty USING "######.##", 
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
			
		BEFORE GROUP OF p_rec_orderdetl.order_num 
			PRINT COLUMN 5, "Order #: ", p_rec_orderdetl.order_num USING "#######" 
			
		AFTER GROUP OF p_rec_orderdetl.order_num 
			PRINT COLUMN 10, " Order total:", 
			COLUMN 115, "===============" 
			PRINT COLUMN 115, GROUP sum(p_rec_orderdetl.ext_price_amt) 
			USING "--,---,--&.&&" 
			
		AFTER GROUP OF p_rec_orderdetl.cust_code 
			PRINT COLUMN 10, "Client total:", 
			COLUMN 115, "===============" 
			PRINT COLUMN 115, GROUP sum(p_rec_orderdetl.ext_price_amt) 
			USING "--,---,--&.&&" 
END REPORT 
############################################################
# END REPORT E9A_rpt_list(p_rec_orderhead) 
############################################################