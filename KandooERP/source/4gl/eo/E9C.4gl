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
GLOBALS "../eo/E9C_GLOBALS.4gl" 
###########################################################################
# MODULE Scope Variables
###########################################################################
DEFINE modu_q1_segm_acct_text STRING 

###########################################################################
# FUNCTION E9C_main()
#
# OAC (E9C!!!) - OE Customer Orders by GL Selection/Salesperson
###########################################################################
FUNCTION E9C_main() 
	DEFER QUIT 
	DEFER INTERRUPT 

	CALL setModuleId("E9C") -- albo 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 	

			OPEN WINDOW E441 with FORM "E441" 
			 CALL windecoration_e("E441") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title

			MENU " Order Report by GL/Sales " 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","E9C","menu-Order_Report-1") -- albo kd-502 
					CALL rpt_rmsreps_reset(NULL)
					CALL E9C_rpt_process(E9C_rpt_query())
							
				ON ACTION "WEB-HELP" -- albo kd-370 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "REPORT" #COMMAND "Run report" " SELECT criteria AND PRINT report" 
					CALL rpt_rmsreps_reset(NULL)
					CALL E9C_rpt_process(E9C_rpt_query())
		
				ON ACTION "PRINT MANAGER" #COMMAND "Print" "Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "CANCEL" #COMMAND "Exit" " Exit TO menus" 
					EXIT MENU 

			END MENU 
			CLOSE WINDOW E441 

		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL E9C_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW E441 with FORM "E441" 
			 CALL windecoration_e("E441") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(E9C_rpt_query()) #save where clause in env 
			CLOSE WINDOW E441 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL E9C_rpt_process(get_url_sel_text())
	END CASE 	
	
END FUNCTION 
###########################################################################
# END FUNCTION E9C_main()
###########################################################################


###########################################################################
# FUNCTION E9C_rpt_query() 
#
# CONSTRUCT where clause for report data
# RETURN NULL or l_where_text
###########################################################################
FUNCTION E9C_rpt_query() 
	DEFINE l_where_text STRING
	DEFINE l_where_text_part STRING
	DEFINE l_order_status char(1) 

	CLEAR screen 

	INPUT l_order_status WITHOUT DEFAULTS FROM order_status 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","E9C","input-l_order_status-1") -- albo kd-502 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

		AFTER FIELD l_order_status 
			IF int_flag != 0 OR 
			quit_flag != 0 THEN 
				EXIT PROGRAM 
			ELSE 
				IF l_order_status IS NULL OR 
				(l_order_status <> "F" AND 
				l_order_status <> "O") THEN 
					LET l_order_status = "A" 
				END IF 
				CASE 
					WHEN l_order_status = "A" 
						LET l_where_text_part = " 1=1" 
					WHEN l_order_status = "O" 
						LET l_where_text_part = " AND orderdetl.order_qty > orderdetl.inv_qty" 
					WHEN l_order_status = "F" 
						LET l_where_text_part = " AND orderdetl.order_qty = orderdetl.inv_qty" 
				END CASE 
			END IF 

	END INPUT 


	IF int_flag != 0 OR quit_flag != 0 THEN 
		RETURN NULL 
	ELSE 
		IF l_order_status IS NULL OR (l_order_status <> "F" AND	l_order_status <> "O") THEN 
			LET l_order_status = "A" 
		END IF 
		CASE 
			WHEN l_order_status = "A" 
				LET l_where_text_part = " AND 1=1" 
			WHEN l_order_status = "O" 
				LET l_where_text_part = " AND orderdetl.order_qty > orderdetl.inv_qty" 
			WHEN l_order_status = "F" 
				LET l_where_text_part = " AND orderdetl.order_qty = orderdetl.inv_qty" 
		END CASE 
	END IF
	
	CLEAR screen 
	
	OPEN WINDOW we442 with FORM "E442" 
	 CALL windecoration_e("E442") -- albo kd-755 

	MESSAGE " Enter criteria FOR selection - ESC TO begin search"	attribute(yellow) 

	CONSTRUCT BY NAME l_where_text ON orderhead.order_date, 
	orderhead.sales_code 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","E9C","construct-orderhead-1") -- albo kd-502 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	IF l_where_text IS NULL THEN
		LET l_where_text = " 1=1"
	END IF  

   IF l_where_text_part IS NOT NULL AND LENGTH(l_where_text_part) <> 0 THEN
		LET l_where_text = l_where_text clipped, l_where_text_part 
	END IF

	# add on the search dimension of segments.......

	CALL segment_con(glob_rec_kandoouser.cmpy_code, "account") 
	RETURNING modu_q1_segm_acct_text 
	LET l_where_text = l_where_text clipped, modu_q1_segm_acct_text 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN NULL 
	ELSE 
		RETURN l_where_text
	END IF 
END FUNCTION
###########################################################################
# END FUNCTION E9C_rpt_query() 
###########################################################################


############################################################
# FUNCTION E9C_rpt_process(p_where_text) 
#
#
############################################################
FUNCTION E9C_rpt_process(p_where_text) 
	DEFINE p_where_text STRING
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE l_rec_subtot RECORD 
		sub1 char(40), 
		sub2 char(40), 
		sub3 char(40) 
	END RECORD 
	DEFINE l_rec_order RECORD 
		cmpy_code LIKE orderhead.cmpy_code, 
		acct_code LIKE orderdetl.acct_code, 
		sales_code LIKE orderhead.sales_code, 
		cust_code LIKE customer.cust_code, 
		order_num LIKE orderhead.order_num, 
		order_date LIKE orderhead.order_date, 
		total_amt LIKE orderhead.total_amt, 
		cost_amt LIKE orderhead.cost_amt, 
		subtotal1 char(18), 
		subtotal2 char(18), 
		subtotal3 char(18) 
	END RECORD 	
	DEFINE l_rec_position RECORD 
		sub1_start INTEGER, 
		sub1_end INTEGER, 
		desc_text1 char(20), 
		op1_flag char(1), 
		sub2_start INTEGER, 
		sub2_end INTEGER, 
		desc_text2 char(20), 
		op2_flag char(1), 
		sub3_start INTEGER, 
		sub3_end INTEGER, 
		desc_text3 char(20), 
		op3_flag char(1) 
	END RECORD 
	DEFINE i,j INTEGER	
		
	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"E9C_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT E9C_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------


		CALL subtotal(glob_rec_kandoouser.cmpy_code,"account") RETURNING l_rec_position.*, l_rec_subtot.* 

		LET l_query_text = 
		" SELECT unique orderhead.cmpy_code, orderdetl.acct_code, ", 
		" orderhead.sales_code, orderhead.cust_code, ", 
		" orderhead.order_num, orderhead.order_date, ", 
		" orderhead.total_amt, orderhead.cost_amt ", 
		" FROM orderhead, orderdetl, account ", 
		" WHERE orderhead.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
		" AND orderhead.cmpy_code = orderdetl.cmpy_code ", 
		" AND orderhead.cust_code = orderdetl.cust_code ", 
		" AND orderhead.order_num = orderdetl.order_num ", 
		" AND orderdetl.cmpy_code = account.cmpy_code ", 
		" AND orderdetl.acct_code = account.acct_code ", 
		" AND ",glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("E9C_rpt_list")].sel_text clipped," ",	
		" ORDER BY ", 
		l_rec_subtot.sub1, 
		l_rec_subtot.sub2, 
		l_rec_subtot.sub3, 
		" orderhead.sales_code " 
 		
		PREPARE choice FROM l_query_text 
		DECLARE selcurs cursor FOR choice 

		FOREACH selcurs INTO l_rec_order.* 
			LET i = l_rec_position.sub1_start 
			LET j = l_rec_position.sub1_end 
			LET l_rec_order.subtotal1 = l_rec_order.acct_code[i,j] 
			LET i = l_rec_position.sub2_start 
			LET j = l_rec_position.sub2_end 
			LET l_rec_order.subtotal2 = l_rec_order.acct_code[i,j] 
			LET i = l_rec_position.sub3_start 
			LET j = l_rec_position.sub3_end 
			LET l_rec_order.subtotal3 = l_rec_order.acct_code[i,j] 

				#---------------------------------------------------------
				OUTPUT TO REPORT E9C_rpt_list(l_rpt_idx,
				l_rec_order.*,l_rec_position.*) 
				IF NOT rpt_int_flag_handler2("Order:",l_rec_order.order_num, NULL,l_rpt_idx) THEN
					EXIT FOREACH 
				END IF 
				#---------------------------------------------------------	
			
		END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT E9C_rpt_list
	CALL rpt_finish("E9C_rpt_list")
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
# END FUNCTION E9C_rpt_process(p_where_text) 
############################################################


###########################################################################
# FUNCTION subtotal(p_cmpy_code,p_tablename)
#
#
###########################################################################
FUNCTION subtotal(p_cmpy_code,p_tablename)
	DEFINE p_cmpy_code char(2) 
	DEFINE p_tablename char(15)
	DEFINE l_rec_structure RECORD LIKE structure.* 
	DEFINE l_arr_rec_structure array[10] OF RECORD 
		level_ind char(1), 
		start_num LIKE structure.start_num, 
		length_num LIKE structure.length_num, 
		desc_text LIKE structure.desc_text 
	END RECORD 
	DEFINE l_rec_position RECORD 
		sub1_start INTEGER, 
		sub1_end INTEGER, 
		desc_text1 char(20), 
		op1_flag char(1), 
		sub2_start INTEGER, 
		sub2_end INTEGER, 
		desc_text2 char(20), 
		op2_flag char(1), 
		sub3_start INTEGER, 
		sub3_end INTEGER, 
		desc_text3 char(20), 
		op3_flag char(1) 
	END RECORD 
	DEFINE l_rec_subtot RECORD 
		sub1 char(40), 
		sub2 char(40), 
		sub3 char(40) 
	END RECORD 
	DEFINE i, l_idx SMALLINT 
--	DEFINE l_start_pos SMALLINT 
--	DEFINE end_pos SMALLINT
--	DEFINE order_cnt INTEGER 

	OPEN WINDOW E443 with FORM "E443" 
	 CALL windecoration_e("E443") -- albo kd-755 

	DECLARE structurecurs cursor FOR 
	SELECT * 
	INTO l_rec_structure.* 
	FROM structure 
	WHERE cmpy_code = p_cmpy_code 
	AND start_num > 0 
	AND (type_ind = "S" OR type_ind = "C") 
	ORDER BY start_num 

	FOR l_idx = 1 TO 10 
		INITIALIZE l_arr_rec_structure[l_idx].* TO NULL 
	END FOR 
	
	LET l_idx = 0 
	FOREACH structurecurs 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_structure[l_idx].desc_text = l_rec_structure.desc_text 
		LET l_arr_rec_structure[l_idx].start_num = l_rec_structure.start_num 
		LET l_arr_rec_structure[l_idx].length_num = l_rec_structure.length_num 
		LET l_arr_rec_structure[l_idx].level_ind = " " 
	END FOREACH 

	CALL set_count(l_idx) 

	MESSAGE " Enter '1' WHERE subtotalling required - ESC TO continue" attribute(yellow) 

	#INPUT ARRAY l_arr_rec_structure WITHOUT DEFAULTS FROM sr_structure.* 
	DISPLAY ARRAY l_arr_rec_structure TO sr_structure.*
		BEFORE DISPLAY
			CALL publish_toolbar("kandoo","E9C","input-l_arr_rec_structure-1") -- albo kd-502 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE ROW 
			LET l_idx = arr_curr() 

	END DISPLAY 

	IF int_flag != 0 OR	quit_flag != 0 THEN 
		EXIT PROGRAM 
	ELSE 
		--LET order_cnt = 0 
		LET l_rec_position.op1_flag = "N" 
		LET l_rec_position.op2_flag = "N" 
		LET l_rec_position.op3_flag = "N" 
		FOR l_idx = 1 TO arr_count() 
			CASE 
				WHEN l_arr_rec_structure[l_idx].level_ind = 1 
					LET l_rec_subtot.sub1 = p_tablename clipped,".acct_code[", 
					l_arr_rec_structure[l_idx].start_num USING "<<<<<" , 
					",", 
					l_arr_rec_structure[l_idx].start_num + 
					l_arr_rec_structure[l_idx].length_num - 1 
					USING "<<<<<", 
					"]" 
					LET l_rec_position.sub1_start = l_arr_rec_structure[l_idx].start_num 
					LET l_rec_position.sub1_end = l_arr_rec_structure[l_idx].start_num + 
					l_arr_rec_structure[l_idx].length_num - 1 
					LET l_rec_position.desc_text1 = l_arr_rec_structure[l_idx].desc_text 
					LET l_rec_position.op1_flag = "Y" 
				WHEN l_arr_rec_structure[l_idx].level_ind = 2 
					LET l_rec_subtot.sub2 = p_tablename clipped,".acct_code[", 
					l_arr_rec_structure[l_idx].start_num USING "<<<<<", 
					",", 
					l_arr_rec_structure[l_idx].start_num + 
					l_arr_rec_structure[l_idx].length_num - 1 
					USING "<<<<<", 
					"]" 
					LET l_rec_position.sub2_start = l_arr_rec_structure[l_idx].start_num 
					LET l_rec_position.sub2_end = l_arr_rec_structure[l_idx].start_num + 
					l_arr_rec_structure[l_idx].length_num - 1 
					LET l_rec_position.desc_text2 = l_arr_rec_structure[l_idx].desc_text 
					LET l_rec_position.op2_flag = "Y" 
				WHEN l_arr_rec_structure[l_idx].level_ind = 3 
					LET l_rec_subtot.sub3 = p_tablename clipped,".acct_code[", 
					l_arr_rec_structure[l_idx].start_num USING "<<<<<", 
					",", 
					l_arr_rec_structure[l_idx].start_num + 
					l_arr_rec_structure[l_idx].length_num - 1 
					USING "<<<<<", 
					"]" 
					LET l_rec_position.sub3_start = l_arr_rec_structure[l_idx].start_num 
					LET l_rec_position.sub3_end = l_arr_rec_structure[l_idx].start_num + 
					l_arr_rec_structure[l_idx].length_num - 1 
					LET l_rec_position.desc_text3 = l_arr_rec_structure[l_idx].desc_text 
					LET l_rec_position.op3_flag = "Y" 
			END CASE
			 
		END FOR
		 
	END IF 
	
	IF l_rec_subtot.sub1 IS NOT NULL THEN 
		LET l_rec_subtot.sub1 = l_rec_subtot.sub1 clipped,"," 
	ELSE 
		LET l_rec_position.sub1_start = 1 
		LET l_rec_position.sub1_end = 18 
	END IF 
	IF l_rec_subtot.sub2 IS NOT NULL THEN 
		LET l_rec_subtot.sub2 = l_rec_subtot.sub2 clipped,"," 
	ELSE 
		LET l_rec_position.sub2_start = 1 
		LET l_rec_position.sub2_end = 18 
	END IF 
	IF l_rec_subtot.sub3 IS NOT NULL THEN 
		LET l_rec_subtot.sub3 = l_rec_subtot.sub3 clipped,"," 
	ELSE 
		LET l_rec_position.sub3_start = 1 
		LET l_rec_position.sub3_end = 18 
	END IF 
	RETURN l_rec_position.*,l_rec_subtot.* 
END FUNCTION 
###########################################################################
# END FUNCTION subtotal(p_cmpy_code,p_tablename)
###########################################################################


############################################################
# REPORT E9C_rpt_list(p_rpt_idx,p_rec_order,p_rec_position) 
#
#
############################################################
REPORT E9C_rpt_list(p_rpt_idx,p_rec_order,p_rec_position) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_order RECORD 
		cmpy_code LIKE orderhead.cmpy_code, 
		acct_code LIKE orderdetl.acct_code, 
		sales_code LIKE orderhead.sales_code, 
		cust_code LIKE customer.cust_code, 
		order_num LIKE orderhead.order_num, 
		order_date LIKE orderhead.order_date, 
		total_amt LIKE orderhead.total_amt, 
		cost_amt LIKE orderhead.cost_amt, 
		subtotal1 char(18), 
		subtotal2 char(18), 
		subtotal3 char(18) 
	END RECORD 
	DEFINE p_rec_position RECORD 
		sub1_start INTEGER, 
		sub1_end INTEGER, 
		desc_text1 char(20), 
		op1_flag char(1), 
		sub2_start INTEGER, 
		sub2_end INTEGER, 
		desc_text2 char(20), 
		op2_flag char(1), 
		sub3_start INTEGER, 
		sub3_end INTEGER, 
		desc_text3 char(20), 
		op3_flag char(1) 
	END RECORD 

	OUTPUT 
	 
	ORDER external BY p_rec_order.cmpy_code,p_rec_order.subtotal1, 
	p_rec_order.subtotal2, p_rec_order.subtotal3, 
	p_rec_order.sales_code 

	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 1, "Client", 
			COLUMN 12, "Order", 
			COLUMN 22, "Order", 
			COLUMN 36, "Total", 
			COLUMN 52, "Cost", 
			COLUMN 68, "Gross", 
			COLUMN 84, "Gross" 

			PRINT COLUMN 1, "ID", 
			COLUMN 12, "Number", 
			COLUMN 22, "Date", 
			COLUMN 36, "Price", 
			COLUMN 52, "Price", 
			COLUMN 68, "Profit ($)", 
			COLUMN 84, "Profit (%)" 


			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		ON EVERY ROW 
			PRINT COLUMN 1, p_rec_order.cust_code, 
			COLUMN 12, p_rec_order.order_num USING "########", 
			COLUMN 22, p_rec_order.order_date USING "dd/mm/yyyy", 
			COLUMN 36, p_rec_order.total_amt USING "---,---,--$.&&", 
			COLUMN 52, p_rec_order.cost_amt USING "---,---,--$.&&", 
			COLUMN 68, (p_rec_order.total_amt - p_rec_order.cost_amt) 
			USING "---,---,--$.&&"; 
			IF p_rec_order.total_amt <> 0 THEN 
				PRINT COLUMN 84, (p_rec_order.total_amt - p_rec_order.cost_amt)/ 
				p_rec_order.total_amt * 100 USING "----&.&&%" 
			ELSE 
				PRINT COLUMN 84," 0.00%" 
			END IF 

		BEFORE GROUP OF p_rec_order.subtotal1 
			IF p_rec_position.op1_flag = "Y" THEN 
				SKIP 1 LINES 
				PRINT COLUMN 1, p_rec_position.desc_text1,": ", 
				p_rec_order.subtotal1 
			END IF 

			   {BEFORE GROUP OF p_rec_order.subtotal2
			      IF p_rec_position.op2_flag = "Y" THEN
			         PRINT COLUMN  1,  p_rec_position.desc_text2,": ",
			                         p_rec_order.subtotal2
			      END IF

			   BEFORE GROUP OF p_rec_order.subtotal3
			      IF p_rec_position.op3_flag = "Y" THEN
			         PRINT COLUMN  1,  p_rec_position.desc_text3,": ",
			                         p_rec_order.subtotal3
			      END IF
			}

		BEFORE GROUP OF p_rec_order.sales_code 
			SKIP 1 LINES 
			PRINT COLUMN 1, "Salesperson: ",p_rec_order.sales_code 

		AFTER GROUP OF p_rec_order.subtotal1 
			PRINT COLUMN 36, "--------------", 
			COLUMN 52, "--------------", 
			COLUMN 68, "--------------" 
			PRINT COLUMN 1, p_rec_position.desc_text1, "Sub-total: ", 
			COLUMN 36, GROUP sum(p_rec_order.total_amt) USING "---,---,--$.&&", 
			COLUMN 52, GROUP sum(p_rec_order.cost_amt) USING "---,---,--$.&&", 
			COLUMN 68, GROUP sum(p_rec_order.total_amt - p_rec_order.cost_amt) 
			USING "---,---,--$.&&" 

			{   AFTER GROUP OF p_rec_order.subtotal2
			      PRINT COLUMN 36, "--------------",
			            COLUMN 52, "--------------"
			      PRINT COLUMN 1, "Group Sub-total: ",
			            COLUMN 36, group sum(p_rec_order.total_amt) using "---,---,--$.&&",
			            COLUMN 52, group sum(p_rec_order.cost_amt) using "---,---,--$.&&"

			   AFTER GROUP OF p_rec_order.subtotal2
			      PRINT COLUMN 36, "--------------",
			            COLUMN 52, "--------------"
			      PRINT COLUMN 1, "Group Sub-total: ",
			            COLUMN 36, group sum(p_rec_order.total_amt) using "---,---,--$.&&",
			            COLUMN 52, group sum(p_rec_order.cost_amt) using "---,---,--$.&&"
			}

		ON LAST ROW 
			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			
END REPORT 
############################################################
# END REPORT E9C_rpt_list(p_rpt_idx,p_rec_order,p_rec_position) 
############################################################