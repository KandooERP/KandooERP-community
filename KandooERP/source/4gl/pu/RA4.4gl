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
GLOBALS "../pu/RA_GROUP_GLOBALS.4gl"
GLOBALS "../pu/RA4_GLOBALS.4gl" 
###########################################################################
# FUNCTION RA4_main()
#
# RA4 Purchase Order listing voucher details
###########################################################################
FUNCTION RA4_main() 
	DEFER quit 
	DEFER interrupt 

	CALL setModuleId("RA4") -- albo 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN "1" #UI/MENU Mode 	

			OPEN WINDOW R139 with FORM "R139" 
			CALL  windecoration_r("R139") 
		
			MENU " Purchase Order Voucher Details" 
		
				BEFORE MENU 
					CALL publish_toolbar("kandoo","RA4","menu-purchase_order_voucher-1") 
					CALL RA4_rpt_process(RA4_rpt_query())
					
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
					
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				ON ACTION "REPORT" # "Run Report" " SELECT criteria AND PRINT REPORT" 
					CALL RA4_rpt_process(RA4_rpt_query())
		
				ON ACTION "Print Manager" 	#COMMAND "Print" "Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				COMMAND KEY(interrupt, "E") "Exit" "Exit this program" 
					EXIT MENU 
		
			END MENU 
		
			CLOSE WINDOW R139 


		WHEN "2" #Background Process with rmsreps.report_code
			CALL RA4_rpt_process(NULL)  

		WHEN "3" #Only create query-where-part
			OPEN WINDOW R139 with FORM "R139" 
			CALL  windecoration_r("R139") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(RA4_rpt_query()) #save where clause in env 
			CLOSE WINDOW R139 
			
		WHEN "4" #Background Process with SQL WHERE ARGUMENT
			CALL RA4_rpt_process(get_url_sel_text())
	END CASE
 
END FUNCTION 
###########################################################################
# END FUNCTION RA4_main()
###########################################################################


###########################################################################
# FUNCTION RA4_rpt_query()
#
# 
###########################################################################
FUNCTION RA4_rpt_query()
	DEFINE l_where_text STRING  
	DEFINE exist SMALLINT 
	DEFINE pr_purchhead RECORD 
		order_num LIKE purchhead.order_num, 
		vend_code LIKE purchhead.vend_code, 
		curr_code LIKE purchhead.curr_code, 

		conv_qty LIKE purchhead.conv_qty, 
		order_date LIKE purchhead.order_date, 
		line_num LIKE poaudit.line_num, 
		tran_code LIKE poaudit.tran_code, 
		tran_num LIKE poaudit.tran_num, 
		unit_cost_amt LIKE poaudit.ext_cost_amt, 
		unit_tax_amt LIKE poaudit.ext_tax_amt, 
		order_qty LIKE poaudit.order_qty, 
		received_qty LIKE poaudit.received_qty, 
		voucher_qty LIKE poaudit.voucher_qty, 
		line_total_amt LIKE poaudit.line_total_amt, 
		seq_num LIKE poaudit.seq_num 
	END RECORD 
	
	LET msgresp = kandoomsg("U",1001,"") #" Enter criteria FOR selection - ESC TO begin search"

	CONSTRUCT BY NAME l_where_text ON purchhead.order_num, 
	purchhead.vend_code, 
	purchhead.year_num, 
	purchhead.period_num, 
	purchhead.order_date, 
	poaudit.posted_flag, 
	purchhead.curr_code 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","RA4","construct-purchhead-1") 

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
		RETURN l_where_text
	END IF 
END FUNCTION
###########################################################################
# END FUNCTION RA4_rpt_query()
###########################################################################


###########################################################################
# FUNCTION RA4_rpt_process(p_where_text)
#
# 
###########################################################################
FUNCTION RA4_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT  #report array index 
	DEFINE exist SMALLINT 
	DEFINE pr_purchhead RECORD 
		order_num LIKE purchhead.order_num, 
		vend_code LIKE purchhead.vend_code, 
		curr_code LIKE purchhead.curr_code, 

		conv_qty LIKE purchhead.conv_qty, 
		order_date LIKE purchhead.order_date, 
		line_num LIKE poaudit.line_num, 
		tran_code LIKE poaudit.tran_code, 
		tran_num LIKE poaudit.tran_num, 
		unit_cost_amt LIKE poaudit.ext_cost_amt, 
		unit_tax_amt LIKE poaudit.ext_tax_amt, 
		order_qty LIKE poaudit.order_qty, 
		received_qty LIKE poaudit.received_qty, 
		voucher_qty LIKE poaudit.voucher_qty, 
		line_total_amt LIKE poaudit.line_total_amt, 
		seq_num LIKE poaudit.seq_num 
	END RECORD 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"RA4_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT RA4_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = 0, 
	BOTTOM MARGIN = 0, 
	LEFT MARGIN = 0, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------

	#CLEAR SCREEN
	#DISPLAY "Searching database - please wait" AT 12,10
	#   ATTRIBUTE(yellow)

	LET l_query_text = 
	" SELECT purchhead.order_num, purchhead.vend_code, ", 
	" purchhead.curr_code, purchhead.conv_qty, ", 
	" purchhead.order_date, ", 
	" poaudit.line_num, poaudit.tran_code, ", 
	" poaudit.tran_num, poaudit.unit_cost_amt, ", 
	" poaudit.unit_tax_amt, poaudit.order_qty, ", 
	" poaudit.received_qty, poaudit.voucher_qty, ", 
	" poaudit.line_total_amt, poaudit.seq_num ", 
	" FROM purchhead, poaudit ", 
	" WHERE purchhead.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
	" purchhead.cmpy_code = poaudit.cmpy_code AND ", 
	" purchhead.vend_code = poaudit.vend_code AND ", 
	" purchhead.order_num = poaudit.po_num AND ", 
	glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("RA4_rpt_list")].sel_text clipped," ", 
	" ORDER BY purchhead.order_num, poaudit.line_num, ", 
	" poaudit.seq_num " 


	PREPARE choice FROM l_query_text 
	DECLARE selcurs CURSOR FOR choice 

	OPEN selcurs 
	--   OPEN WINDOW wfPU AT 10,10  -- albo  KD-756
	--      with 1 rows, 50 columns
	--      ATTRIBUTE(border, MESSAGE line first)

	WHILE true 
		FETCH selcurs INTO pr_purchhead.* 
		IF status = notfound THEN 
			EXIT WHILE 
		END IF 

		#---------------------------------------------------------
		OUTPUT TO REPORT RA4_rpt_list(l_rpt_idx,pr_purchhead.*) 
		IF NOT rpt_int_flag_handler2("Purchase Order:",pr_purchhead.order_num ,NULL,l_rpt_idx) THEN
			EXIT WHILE 
		END IF 
		#---------------------------------------------------------			

	END WHILE 

	#------------------------------------------------------------
	FINISH REPORT RA4_rpt_list
	CALL rpt_finish("RA4_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 

END FUNCTION 
###########################################################################
# END FUNCTION RA4_rpt_process(p_where_text)
###########################################################################


###########################################################################
# REPORT RA4_rpt_list(p_rpt_idx,pr_purchhead)
#
# 
###########################################################################
REPORT RA4_rpt_list(p_rpt_idx,pr_purchhead) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	 
	DEFINE pr_purchhead RECORD 
		order_num LIKE purchhead.order_num, 
		vend_code LIKE purchhead.vend_code, 
		curr_code LIKE purchhead.curr_code, 
		conv_qty LIKE purchhead.conv_qty, 
		order_date LIKE purchhead.order_date, 
		line_num LIKE poaudit.line_num, 
		tran_code LIKE poaudit.tran_code, 
		tran_num LIKE poaudit.tran_num, 
		unit_cost_amt LIKE poaudit.ext_cost_amt, 
		unit_tax_amt LIKE poaudit.ext_tax_amt, 
		order_qty LIKE poaudit.order_qty, 
		received_qty LIKE poaudit.received_qty, 
		voucher_qty LIKE poaudit.voucher_qty, 
		line_total_amt LIKE poaudit.line_total_amt, 
		seq_num LIKE poaudit.seq_num 
	END RECORD 
	DEFINE rep_desc_text LIKE purchdetl.desc_text 
	DEFINE g_r_total_amt LIKE poaudit.line_total_amt 
	DEFINE g_v_total_amt LIKE voucher.total_amt 
	DEFINE g_o_total_amt LIKE voucher.paid_amt 
	DEFINE receipt_total LIKE poaudit.line_total_amt 
	DEFINE order_tot, received_tot, vouch_tot, tax_tot LIKE poaudit.unit_cost_amt 

	OUTPUT 

	ORDER external BY pr_purchhead.order_num, pr_purchhead.line_num,pr_purchhead.seq_num 

	FORMAT 

		PAGE HEADER 

			IF pageno = 1 THEN 
				LET g_r_total_amt = 0 
				LET g_v_total_amt = 0 
				LET g_o_total_amt = 0 
			END IF 

			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text			
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			#PRINT COLUMN 1, "**All monetary VALUES are in vendor currency**"


			PRINT COLUMN 1, "Line", 
			COLUMN 6, " Description", 
			COLUMN 32, "Tran", 
			COLUMN 37, " Ref", 
			COLUMN 44, " Unit ", 
			COLUMN 60, " Unit", 
			COLUMN 76, " Order", 
			COLUMN 83, "Recved", 
			COLUMN 90, " Vouch", 
			COLUMN 97, " Line" 

			PRINT COLUMN 1, "Num", 
			COLUMN 32, "Code", 
			COLUMN 37, " Num", 
			COLUMN 44, " Cost", 
			COLUMN 60, " Tax", 
			COLUMN 76, " Qty", 
			COLUMN 83, " Qty ", 
			COLUMN 90, " Qty ", 
			COLUMN 97, " Total" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		BEFORE GROUP OF pr_purchhead.order_num 
			PRINT COLUMN 1, "Order Number: ", pr_purchhead.order_num 
			USING "########", 
			COLUMN 25, "Vendor ID: ", pr_purchhead.vend_code, 
			COLUMN 45, "Currency : ", pr_purchhead.curr_code 

		BEFORE GROUP OF pr_purchhead.line_num 
			SELECT desc_text 
			INTO rep_desc_text 
			FROM purchdetl 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
			order_num = pr_purchhead.order_num AND 
			line_num = pr_purchhead.line_num 

		ON EVERY ROW 
			PRINT COLUMN 1, pr_purchhead.line_num USING "####", 
			COLUMN 6, rep_desc_text[1,25], 
			COLUMN 32, pr_purchhead.tran_code, 
			COLUMN 35, pr_purchhead.tran_num USING "########", 
			COLUMN 44, pr_purchhead.unit_cost_amt USING "----,---,---.&&", 
			COLUMN 60, pr_purchhead.unit_tax_amt USING "----,---,---.&&", 
			COLUMN 76, pr_purchhead.order_qty USING "------", 
			COLUMN 83, pr_purchhead.received_qty USING "------", 
			COLUMN 90, pr_purchhead.voucher_qty USING "------", 
			COLUMN 97, pr_purchhead.line_total_amt USING "----,---,---.&&" 

		AFTER GROUP OF pr_purchhead.line_num 
			PRINT COLUMN 76, "------", 
			COLUMN 83, "------", 
			COLUMN 90, "------" 

			PRINT COLUMN 5, "Line Quantity Totals: ", 
			COLUMN 76, GROUP sum(pr_purchhead.order_qty) USING "------", 
			COLUMN 83, GROUP sum(pr_purchhead.received_qty) USING "------", 
			COLUMN 90, GROUP sum(pr_purchhead.voucher_qty) USING "------" 
			SKIP 1 LINES 

		AFTER GROUP OF pr_purchhead.order_num 
			IF (pr_purchhead.order_num != 0) AND 
			(pr_purchhead.vend_code IS NOT null) THEN 
				CALL po_head_info(glob_rec_kandoouser.cmpy_code, pr_purchhead.order_num) 
				RETURNING order_tot, received_tot, vouch_tot, tax_tot 
				PRINT COLUMN 2, "Order Totals: ", 
				COLUMN 28, "Ordered ", 
				COLUMN 52, "Received ", 
				COLUMN 76, "Vouchered " 
				PRINT COLUMN 20, order_tot USING "----,---,---.&&", 
				COLUMN 45, received_tot USING "----,---,---.&&", 
				COLUMN 70, vouch_tot USING "----,---,---.&&" 
				PRINT COLUMN 1, "--------------------------------------------", 
				"----------------------------------------", 
				"----------------------------------------" 
				SKIP 1 LINES 

				LET g_o_total_amt = g_o_total_amt + (order_tot / pr_purchhead.conv_qty) 
				LET g_r_total_amt = g_r_total_amt + (received_tot / pr_purchhead.conv_qty) 
				LET g_v_total_amt = g_v_total_amt + (vouch_tot / pr_purchhead.conv_qty) 
			END IF
			 
		ON LAST ROW 
			NEED 13 LINES 
			PRINT COLUMN 1, 
			"** Report Totals in Base Currency " 
			SKIP 1 LINES 
			PRINT COLUMN 10, "Goods Ordered Grand Total: ", g_o_total_amt 
			USING "----,---,---.&&" 
			SKIP 1 LINES 
			PRINT COLUMN 10, "Goods Receipt Grand Total: ", g_r_total_amt 
			USING "----,---,---.&&" , " -" 
			PRINT COLUMN 10, "Voucher Grand Total : ", 
			g_v_total_amt USING "----,---,---.&&" 
			PRINT COLUMN 10, " ---------------" 
			PRINT COLUMN 10, "Total Difference : ", 
			g_r_total_amt - g_v_total_amt USING "----,---,---.&&" 
			PRINT COLUMN 10, " ---------------" 

			SKIP 1 line 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	


			PRINT COLUMN 40, "******** END OF REPORT (RA4) ********" 
			LET g_r_total_amt = 0 
			LET g_v_total_amt = 0 
			LET g_o_total_amt = 0 

END REPORT 
###########################################################################
# END REPORT RA4_rpt_list(p_rpt_idx,pr_purchhead)
###########################################################################