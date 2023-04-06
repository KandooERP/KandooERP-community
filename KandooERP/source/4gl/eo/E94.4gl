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
GLOBALS "../eo/E94_GLOBALS.4gl"
###########################################################################
# MODULE Scope Variables
###########################################################################
###########################################################################
# FUNCTION E94_main()
#
# OA4 (e94 !!!) Order Listing By Job
###########################################################################
FUNCTION E94_main() 
	DEFER QUIT 
	DEFER INTERRUPT 

	CALL setModuleId("E94") -- albo 

	--LET temp_text = glob_rec_arparms.inv_ref1_text clipped, "................" 
	--LET ref_text = temp_text 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 

			OPEN WINDOW E400 with FORM "E400" 
			 CALL windecoration_e("E400")
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title

			DISPLAY glob_rec_arparms.inv_ref1_text TO inv_ref1_text 
		
			MENU " Order rpt" 
		
				BEFORE MENU 
					CALL publish_toolbar("kandoo","E94","menu-Order_Rpt-1") -- albo kd-502 
					CALL rpt_rmsreps_reset(NULL)
					CALL E94_rpt_process(E94_rpt_query())
							
				ON ACTION "WEB-HELP" -- albo kd-370 
					CALL onlinehelp(getmoduleid(),null) 
		
				COMMAND "Report" " SELECT criteria AND PRINT report" 
					CALL rpt_rmsreps_reset(NULL)
					CALL E94_rpt_process(E94_rpt_query())
		
				ON ACTION "PRINT MANAGER" 		#COMMAND "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "CANCEL" #COMMAND KEY (INTERRUPT, "E") "Exit" " Exit TO menus" 
					EXIT MENU 
		
			END MENU 
			CLOSE WINDOW E400 

		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL E94_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW E400 with FORM "E400" 
			 CALL windecoration_e("E400") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(E94_rpt_query()) #save where clause in env 
			CLOSE WINDOW E400 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL E94_rpt_process(get_url_sel_text())
	END CASE 	

END FUNCTION


###########################################################################
# FUNCTION E94_rpt_query() 
#
#
###########################################################################
FUNCTION E94_rpt_query() 
	DEFINE l_where_text STRING 
 

	CLEAR FORM 
	DISPLAY glob_rec_arparms.inv_ref1_text TO inv_ref1_text 

	MESSAGE " Enter criteria FOR selection - ESC TO begin search" attribute(yellow) 

	CONSTRUCT BY NAME l_where_text ON orderhead.cust_code, 
	customer.name_text, 
	orderhead.order_num, 
	orderhead.currency_code, 
	orderhead.ord_text, 
	orderhead.last_inv_num, 
	orderhead.status_ind 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","E94","construct-orderhead-1") -- albo kd-502 

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
# FUNCTION E94_rpt_process(p_where_text) 
#
#
############################################################
FUNCTION E94_rpt_process(p_where_text) 
	DEFINE p_where_text STRING
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE l_rec_orderhead RECORD 
		cust_code LIKE orderhead.cust_code, 
		name_text LIKE customer.name_text, 
		order_num LIKE orderhead.order_num, 
		ord_text LIKE orderhead.ord_text, 
		last_inv_num LIKE orderhead.last_inv_num, 
		order_date LIKE orderhead.order_date, 
		total_amt LIKE orderhead.total_amt, 
		status_ind LIKE orderhead.status_ind, 
		ship_date LIKE orderhead.ship_date 
	END RECORD
	
	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"E94_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT E94_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------

	LET l_query_text = 
	"SELECT orderhead.cust_code, customer.name_text, orderhead.order_num, orderhead.ord_text, orderhead.last_inv_num, orderhead.order_date, ", 
	"orderhead.total_amt, orderhead.status_ind, orderhead.ship_date FROM orderhead, customer WHERE orderhead.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND customer.cmpy_code = orderhead.cmpy_code AND customer.cust_code = orderhead.cust_code ", 
	"AND ",glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("E94_rpt_list")].sel_text clipped," ",	
	"ORDER BY orderhead.cust_code, orderhead.order_num" 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN FALSE 
	END IF 

	PREPARE choice FROM l_query_text 
	DECLARE selcurs cursor FOR choice 

	FOREACH selcurs INTO l_rec_orderhead.* 
		#---------------------------------------------------------
		OUTPUT TO REPORT E94_rpt_list(l_rpt_idx,
		l_rec_orderhead.*)  
		IF NOT rpt_int_flag_handler2("Order:",l_rec_orderhead.order_num, NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT E94_rpt_list
	CALL rpt_finish("E94_rpt_list")
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
# REPORT E94_rpt_list(p_rpt_idx,l_rec_orderhead) 
#
#
###########################################################################
REPORT E94_rpt_list(p_rpt_idx,l_rec_orderhead) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE l_rec_orderhead RECORD 
		cust_code LIKE orderhead.cust_code, 
		name_text LIKE customer.name_text, 
		order_num LIKE orderhead.order_num, 
		ord_text LIKE orderhead.ord_text, 
		last_inv_num LIKE orderhead.last_inv_num, 
		order_date LIKE orderhead.order_date, 
		total_amt LIKE orderhead.total_amt, 
		status_ind LIKE orderhead.status_ind, 
		ship_date LIKE orderhead.ship_date 
	END RECORD 

	OUTPUT 

	ORDER external BY 
	l_rec_orderhead.cust_code, l_rec_orderhead.order_num 

	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  

			PRINT COLUMN 1, "Order", 
			COLUMN 10, glob_rec_arparms.inv_ref2a_text, 
			COLUMN 31, "Last", 
			COLUMN 43, "Date", 
			COLUMN 67, "Order", 
			COLUMN 75, "Status" 

			PRINT COLUMN 1, "Number", 
			COLUMN 10, glob_rec_arparms.inv_ref2b_text, 
			COLUMN 30, "Invoice", 
			COLUMN 67, "Amount" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

			PAGE TRAILER 
--				IF print_option = "s" THEN 
--					PAUSE " Type RETURN TO continue" 
--				END IF 
				
		ON EVERY ROW 
			PRINT COLUMN 1, l_rec_orderhead.order_num USING "########", 
			COLUMN 10, l_rec_orderhead.ord_text, 
			COLUMN 21, l_rec_orderhead.last_inv_num USING "########", 
			COLUMN 41, l_rec_orderhead.order_date USING "dd/mm/yy", 
			COLUMN 60, l_rec_orderhead.total_amt USING "--,---,--$.&&", 
			COLUMN 78, l_rec_orderhead.status_ind 
			
		ON LAST ROW 
			SKIP 1 line 
			PRINT COLUMN 1, "Ords:", count(*) USING "####", 
			COLUMN 11, "Avg: ", COLUMN 30, 
			avg(l_rec_orderhead.total_amt) USING "--,---,--$.&&", 
			COLUMN 60, sum(l_rec_orderhead.total_amt) USING "--,---,--$.&&" 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			

END REPORT