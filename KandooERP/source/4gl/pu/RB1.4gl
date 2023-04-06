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
GLOBALS "../pu/R_PU_GLOBALS.4gl" 
GLOBALS "../pu/RB_GROUP_GLOBALS.4gl"
GLOBALS "../pu/RB1_GLOBALS.4gl" 

# \brief module RB1 Orders Report by Number

DEFINE mdou_start_flg INTEGER 

FUNCTION RB1_main() 
	DEFER quit 
	DEFER interrupt
	
	CALL setModuleId("RB1")

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN "1" #UI/MENU Mode 	
			OPEN WINDOW R124 with FORM "R124" 
			CALL  windecoration_r("R124") 
		
		
			MENU " Outstanding ORDER BY Number" 
		
				BEFORE MENU 
					CALL publish_toolbar("kandoo","RB1","menu-outst_order-1")
					CALL RB1_rpt_process(RB1_rpt_query()) 
					CALL rpt_rmsreps_reset(NULL)
		
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
					
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				ON ACTION "REPORT" #COMMAND "Run Report" " SELECT criteria AND PRINT REPORT" 
					CALL RB1_rpt_process(RB1_rpt_query())
					CALL rpt_rmsreps_reset(NULL)
		
				ON ACTION "Print Manager"		#COMMAND "Print" "Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				COMMAND "Exit" " Exit TO menus" 
					EXIT MENU 
			END MENU 
		
			CLOSE WINDOW R124 
	 
		WHEN "2" #Background Process with rmsreps.report_code
			CALL RB1_rpt_process(NULL)  

		WHEN "3" #Only create query-where-part
			OPEN WINDOW R124 with FORM "R124" 
			CALL  windecoration_r("R124") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(RB1_rpt_query()) #save where clause in env 
			CLOSE WINDOW R124 
			
		WHEN "4" #Background Process with SQL WHERE ARGUMENT
			CALL RB1_rpt_process(get_url_sel_text())
	END CASE
END FUNCTION 


FUNCTION RB1_rpt_query() 
	DEFINE l_where_text STRING 

	#" Enter criteria FOR selection - ESC TO begin search"
	LET msgresp = kandoomsg("U",1001,"") 

	CONSTRUCT BY NAME l_where_text ON purchdetl.vend_code, 
	purchdetl.order_num, 
	purchhead.curr_code, 
	purchdetl.type_ind, 
	purchdetl.ref_text, 
	purchdetl.job_code, 
	purchhead.status_ind, 
	purchdetl.activity_code, 
	purchdetl.acct_code 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","RB1","construct-purchdetl-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null)
			 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false
		ERROR " Printing was aborted" 
		RETURN NULL
	ELSE
		RETURN l_where_text
	END IF 
	
END FUNCTION 


FUNCTION RB1_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT  #report array index
	DEFINE exist SMALLINT, 
	pr_purchdetl RECORD LIKE purchdetl.*, 
	pr_curr_code LIKE purchhead.curr_code, 
	pr_conv_qty LIKE purchhead.conv_qty, 
	pr_order_date LIKE purchhead.order_date 


	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"RB1_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT RB1_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------


	LET mdou_start_flg = 0 
	LET l_query_text = 
	"SELECT purchdetl.*, purchhead.curr_code,purchhead.order_date,", 
	" purchhead.conv_qty ", 
	"FROM purchdetl, purchhead ", 
	"WHERE purchdetl.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
	" purchhead.cmpy_code = purchdetl.cmpy_code AND ", 
	" purchdetl.vend_code = purchhead.vend_code AND ", 
	" purchdetl.order_num = purchhead.order_num AND ", 
	" purchhead.status_ind <> \"C\" AND ", 
	glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("RB1_rpt_list")].sel_text clipped," ", 
	" ORDER BY purchdetl.order_num, purchdetl.vend_code" 

	PREPARE choice FROM l_query_text 
	DECLARE selcurs CURSOR FOR choice 

	OPEN selcurs 

	WHILE true 
		FETCH selcurs INTO pr_purchdetl.*, pr_curr_code,pr_order_date, 
		pr_conv_qty 
		IF status = notfound THEN 
			EXIT WHILE 
		END IF 

		#---------------------------------------------------------
		OUTPUT TO REPORT RB1_rpt_list(l_rpt_idx,
		pr_purchdetl.*,pr_curr_code,pr_order_date,pr_conv_qty) 
		IF NOT rpt_int_flag_handler2("Purchase Order:",pr_purchdetl.order_num, NULL,l_rpt_idx) THEN
			EXIT WHILE 
		END IF 
		#---------------------------------------------------------		

	END WHILE 

	#------------------------------------------------------------
	FINISH REPORT RB1_rpt_list
	CALL rpt_finish("RB1_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF
END FUNCTION 


REPORT RB1_rpt_list(p_rpt_idx,pr_purchdetl,pr_curr_code,pr_order_date, pr_conv_qty)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	 
	DEFINE pr_purchdetl RECORD LIKE purchdetl.*, 
	pr_frgn RECORD 
		unit_cost_amt LIKE poaudit.unit_cost_amt, 
		unit_tax_amt LIKE poaudit.unit_tax_amt 
	END RECORD, 
	pr_poaudit RECORD LIKE poaudit.*, 
	pr_curr_code LIKE purchhead.curr_code, 

	pr_conv_qty LIKE purchhead.conv_qty, 
	pr_order_date LIKE purchhead.order_date, 
	s, len, new_flg, order_count INTEGER 

	OUTPUT 
--	left margin 0 
	ORDER external BY pr_purchdetl.order_num, pr_purchdetl.vend_code 

	FORMAT 

		PAGE HEADER 

			IF pageno = 1 THEN 
				LET order_qty_gtot = 0 
				LET received_qty_gtot = 0 
				LET voucher_qty_gtot = 0 
				LET order_amt_gtot = 0 
				LET received_amt_gtot = 0 
				LET voucher_amt_gtot = 0 
				LET order_qty_tot = 0 
				LET received_qty_tot = 0 
				LET voucher_qty_tot = 0 
				LET order_amt_tot = 0 
				LET received_amt_tot = 0 
				LET voucher_amt_tot = 0 
			END IF 

			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 1, " Order", 
			COLUMN 9, " Order", 
			COLUMN 18, " Order", 
			COLUMN 45, " Received", 
			COLUMN 72, " Vouchered", 
			COLUMN 99, "To be Received", 
			COLUMN 115 , "To be Vouchered" 

			PRINT COLUMN 1, "Number", 
			COLUMN 9, " Date", 
			COLUMN 18, " Qty", 
			COLUMN 29, " Amount", 
			COLUMN 45, " Qty", 
			COLUMN 56, " Amount", 
			COLUMN 72, " Qty", 
			COLUMN 83, " Amount", 
			COLUMN 99, " Amount", 
			COLUMN 115, " Amount" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		BEFORE GROUP OF pr_purchdetl.order_num 
			PRINT COLUMN 1, pr_purchdetl.order_num USING "#######", 
			COLUMN 9, pr_order_date USING "dd/mm/yy"; 

		ON EVERY ROW 
			INITIALIZE pr_poaudit.* TO NULL 
			CALL po_line_info(glob_rec_kandoouser.cmpy_code, 
			pr_purchdetl.order_num, 
			pr_purchdetl.line_num) 
			RETURNING pr_poaudit.order_qty, 
			pr_poaudit.received_qty, 
			pr_poaudit.voucher_qty, 
			pr_poaudit.unit_cost_amt, 
			pr_poaudit.ext_cost_amt, 
			pr_poaudit.unit_tax_amt, 
			pr_poaudit.ext_tax_amt, 
			pr_poaudit.line_total_amt 

			LET poaudit_value = pr_poaudit.unit_tax_amt + pr_poaudit.unit_cost_amt 



			LET poaudit_value = poaudit_value / pr_conv_qty 

			LET order_qty_tot = order_qty_tot + pr_poaudit.order_qty 
			LET received_qty_tot = received_qty_tot + pr_poaudit.received_qty 
			LET voucher_qty_tot = voucher_qty_tot + pr_poaudit.voucher_qty 
			LET order_amt_tot = order_amt_tot + (pr_poaudit.order_qty 
			* poaudit_value) 
			LET received_amt_tot = received_amt_tot + (pr_poaudit.received_qty 
			* poaudit_value) 
			LET voucher_amt_tot = voucher_amt_tot + (pr_poaudit.voucher_qty 
			* poaudit_value) 

		AFTER GROUP OF pr_purchdetl.order_num 
			PRINT COLUMN 18, order_qty_tot USING "######.##", 
			COLUMN 29, order_amt_tot USING "---,---,---.&&", 
			COLUMN 45, received_qty_tot USING "######.##", 
			COLUMN 56, received_amt_tot USING "---,---,---.&&", 
			COLUMN 72, voucher_qty_tot USING "######.##", 
			COLUMN 83, voucher_amt_tot USING "---,---,---.&&", 
			COLUMN 99, order_amt_tot - received_amt_tot USING "---,---,---.&&", 
			COLUMN 115, order_amt_tot - voucher_amt_tot USING "---,---,---.&&" 
			LET order_qty_gtot = order_qty_gtot + order_qty_tot 
			LET received_qty_gtot = received_qty_gtot + received_qty_tot 
			LET voucher_qty_gtot = voucher_qty_gtot + voucher_qty_tot 
			LET order_amt_gtot = order_amt_gtot + order_amt_tot 
			LET received_amt_gtot = received_amt_gtot + received_amt_tot 
			LET voucher_amt_gtot = voucher_amt_gtot + voucher_amt_tot 
			LET order_count = order_count + 1 
			LET order_qty_tot = 0 
			LET received_qty_tot = 0 
			LET voucher_qty_tot = 0 
			LET order_amt_tot = 0 
			LET received_amt_tot = 0 
			LET voucher_amt_tot = 0 

		ON LAST ROW 
			NEED 5 LINES 
			PRINT COLUMN 18, "----------", 
			COLUMN 29, "---------------", 
			COLUMN 45, "----------", 
			COLUMN 56, "---------------", 
			COLUMN 72, "----------", 
			COLUMN 83, "---------------", 
			COLUMN 99, "---------------", 
			COLUMN 115, "---------------" 
			PRINT COLUMN 1, "Report Totals: ", 
			COLUMN 18, order_qty_gtot USING "######.##", 
			COLUMN 29, order_amt_gtot USING "---,---,---.&&", 
			COLUMN 45, received_qty_gtot USING "######.##", 
			COLUMN 56, received_amt_gtot USING "---,---,---.&&", 
			COLUMN 72, voucher_qty_gtot USING "######.##", 
			COLUMN 83, voucher_amt_gtot USING "---,---,---.&&", 
			COLUMN 99,order_amt_gtot-received_amt_gtot USING "---,---,---.&&", 
			COLUMN 115,order_amt_gtot - voucher_amt_gtot USING "---,---,---.&&" 
			PRINT COLUMN 1, "Total Number of Orders:", order_count USING "####" 
			SKIP 1 line 

			SKIP 1 line 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			
			LET order_qty_gtot = 0 
			LET received_qty_gtot = 0 
			LET voucher_qty_gtot = 0 
			LET order_amt_gtot = 0 
			LET received_amt_gtot = 0 
			LET voucher_amt_gtot = 0 
			LET order_count = 0 
END REPORT 
