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
GLOBALS "../pu/RBA_GLOBALS.4gl" 
# \brief module RBA Orders Report - by GL Account Code


FUNCTION RBA_main() 
	DEFER quit 
	DEFER interrupt
	
	CALL setModuleId("RBA")

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN "1" #UI/MENU Mode 
			OPEN WINDOW R124 with FORM "R124" 
			CALL  windecoration_r("R124") 
		
			MENU " ORDER BY GL Account" 
		
				BEFORE MENU 
					CALL publish_toolbar("kandoo","RBA","menu-order_by_gl_acc-1") 
					CALL RBA_rpt_process(RBA_rpt_query())
					CALL rpt_rmsreps_reset(NULL)
		
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
					
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				ON ACTION "REPORT" #COMMAND "Run Report" " SELECT criteria AND PRINT REPORT" 
					CALL RBA_rpt_process(RBA_rpt_query())
					CALL rpt_rmsreps_reset(NULL)
		
				ON ACTION "Print Manager"					#COMMAND "Print" "Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				COMMAND KEY(interrupt, "E") "Exit" " Exit TO menus" 
					EXIT MENU 

			END MENU 
			CLOSE WINDOW R124 
	 
		WHEN "2" #Background Process with rmsreps.report_code
			CALL RBA_rpt_process(NULL)  

		WHEN "3" #Only create query-where-part
			OPEN WINDOW R124 with FORM "R124" 
			CALL  windecoration_r("R124") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(RBA_rpt_query()) #save where clause in env 
			CLOSE WINDOW R124 
			
		WHEN "4" #Background Process with SQL WHERE ARGUMENT
			CALL RBA_rpt_process(get_url_sel_text())
	END CASE 
END FUNCTION 


FUNCTION RBA_rpt_query() 
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
			CALL publish_toolbar("kandoo","RBA","construct-purchhead-1") 

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


FUNCTION RBA_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT  #report array index

	DEFINE 
	pr_poaudit RECORD LIKE poaudit.*, 
	pr_acct_code LIKE purchdetl.acct_code, 
	pr_order_num LIKE purchdetl.order_num, 
	pr_line_num LIKE purchdetl.line_num, 
	pr_order_amt, pr_received_amt, pr_voucher_amt LIKE poaudit.unit_cost_amt, 
	pr_curr_code LIKE purchhead.curr_code, 
	pr_conv_qty LIKE purchhead.conv_qty, 
	pr_base_value LIKE poaudit.unit_cost_amt, 
	prev_acct_code LIKE purchdetl.acct_code 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"RBA_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT RBA_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------

	
	LET l_query_text = "SELECT purchdetl.acct_code, ", 
	"purchdetl.order_num, ", 
	"purchdetl.line_num, ", 
	"purchhead.curr_code, ", 
	"purchhead.conv_qty ", 
	"FROM purchdetl, purchhead ", 
	"WHERE purchdetl.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND purchhead.cmpy_code = purchdetl.cmpy_code ", 
	"AND purchdetl.vend_code = purchhead.vend_code ", 
	"AND purchdetl.order_num = purchhead.order_num ", 
	"AND ", glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("RBA_rpt_list")].sel_text clipped," ",
	" ORDER BY purchdetl.acct_code, ", 
	"purchdetl.order_num" 

	PREPARE choice FROM l_query_text 
	DECLARE selcurs CURSOR FOR choice
	 
	LET prev_acct_code = " " 

	FOREACH selcurs INTO pr_acct_code, 
		pr_order_num, 
		pr_line_num, 
		pr_curr_code, 
		pr_conv_qty 
		CALL po_line_info(glob_rec_kandoouser.cmpy_code, 
		pr_order_num, 
		pr_line_num) 
		RETURNING pr_poaudit.order_qty, 
		pr_poaudit.received_qty, 
		pr_poaudit.voucher_qty, 
		pr_poaudit.unit_cost_amt, 
		pr_poaudit.ext_cost_amt, 
		pr_poaudit.unit_tax_amt, 
		pr_poaudit.ext_tax_amt, 
		pr_poaudit.line_total_amt 

		# convert po line cost TO base currency AND calculate line totals
		# accordingly

		LET pr_base_value = 

		(pr_poaudit.unit_tax_amt + pr_poaudit.unit_cost_amt) / pr_conv_qty 

		LET pr_order_amt = pr_poaudit.order_qty * pr_base_value 
		LET pr_received_amt = 
		pr_poaudit.received_qty * pr_base_value 
		LET pr_voucher_amt = 
		pr_poaudit.voucher_qty * pr_base_value 


		#---------------------------------------------------------
		OUTPUT TO REPORT RBA_rpt_list(l_rpt_idx,
		pr_acct_code, 
		pr_order_num, 
		pr_order_amt, 
		pr_received_amt, 
		pr_voucher_amt) 
		IF NOT rpt_int_flag_handler2("Purchase Account:",pr_acct_code, NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------

		IF pr_acct_code != prev_acct_code THEN 
			LET prev_acct_code = pr_acct_code 
		END IF 
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT RBA_rpt_list
	CALL rpt_finish("RBA_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF
END FUNCTION 

REPORT RBA_rpt_list(p_rpt_idx,pr_acct_code, 
	pr_order_num, 
	pr_order_amt, 
	pr_received_amt, 
	pr_voucher_amt) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE 
	pr_acct_code LIKE purchdetl.acct_code, 
	pr_order_num LIKE purchdetl.order_num, 
	pr_order_amt, pr_received_amt, pr_voucher_amt , 
	order_amt_tot, received_amt_tot, voucher_amt_tot LIKE poaudit.unit_cost_amt, 
	len, s INTEGER 

	OUTPUT 
	--left margin 0 

	ORDER external BY pr_acct_code, pr_order_num 

	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			PRINT COLUMN 1, 
			"** Values in Base Currency " 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

			PRINT COLUMN 1, " GL Account", 
			COLUMN 22, " Order", 
			COLUMN 31, " Order", 
			COLUMN 45, " Received", 
			COLUMN 59, " Vouchered", 
			COLUMN 73, " TO be ", 
			COLUMN 87, " TO be ", 
			COLUMN 105, "Received Amt" 

			PRINT COLUMN 1, " Code", 
			COLUMN 22, "Number", 
			COLUMN 31, " Amount ", 
			COLUMN 45, " Amount ", 
			COLUMN 59, " Amount ", 
			COLUMN 73, " Received ", 
			COLUMN 87, "Vouchered ", 
			COLUMN 105, "NOT Vouchered" 


			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

		BEFORE GROUP OF pr_acct_code 
			PRINT COLUMN 1, pr_acct_code 

		AFTER GROUP OF pr_order_num 
			LET order_amt_tot = GROUP sum(pr_order_amt) 
			LET received_amt_tot = GROUP sum(pr_received_amt) 
			LET voucher_amt_tot = GROUP sum(pr_voucher_amt) 
			PRINT COLUMN 22, pr_order_num USING "#######", 
			COLUMN 31, order_amt_tot USING "------,---.&&", 
			COLUMN 45, received_amt_tot USING "------,---.&&", 
			COLUMN 59, voucher_amt_tot USING "------,---.&&", 
			COLUMN 73, order_amt_tot - received_amt_tot 
			USING "------,---.&&", 
			COLUMN 87, order_amt_tot - voucher_amt_tot 
			USING "------,---.&&", 
			COLUMN 105, received_amt_tot - voucher_amt_tot 
			USING "------,---.&&" 

		AFTER GROUP OF pr_acct_code 
			LET order_amt_tot = GROUP sum(pr_order_amt) 
			LET received_amt_tot = GROUP sum(pr_received_amt) 
			LET voucher_amt_tot = GROUP sum(pr_voucher_amt) 
			PRINT COLUMN 31, "-------------", 
			COLUMN 45, "-------------", 
			COLUMN 59, "-------------", 
			COLUMN 73, "-------------", 
			COLUMN 87, "-------------", 
			COLUMN 105, "-------------" 
			PRINT COLUMN 1, "GL Account Totals: ", 
			COLUMN 31, order_amt_tot USING "------,---.&&", 
			COLUMN 45, received_amt_tot USING "------,---.&&", 
			COLUMN 59, voucher_amt_tot USING "------,---.&&", 
			COLUMN 73, order_amt_tot - received_amt_tot 
			USING "------,---.&&", 
			COLUMN 87, order_amt_tot - voucher_amt_tot 
			USING "------,---.&&", 
			COLUMN 105, received_amt_tot - voucher_amt_tot 
			USING "------,---.&&" 
			SKIP 1 line 

		ON LAST ROW 
			LET order_amt_tot = sum(pr_order_amt) 
			LET received_amt_tot = sum(pr_received_amt) 
			LET voucher_amt_tot = sum(pr_voucher_amt) 
			PRINT COLUMN 31, "=============", 
			COLUMN 45, "=============", 
			COLUMN 59, "=============", 
			COLUMN 73, "=============", 
			COLUMN 87, "=============", 
			COLUMN 105, "=============" 
			PRINT COLUMN 1, "Report Totals: ", 
			COLUMN 31, order_amt_tot USING "------,---.&&", 
			COLUMN 45, received_amt_tot USING "------,---.&&", 
			COLUMN 59, voucher_amt_tot USING "------,---.&&", 
			COLUMN 73, order_amt_tot - received_amt_tot 
			USING "------,---.&&", 
			COLUMN 87, order_amt_tot - voucher_amt_tot 
			USING "------,---.&&", 
			COLUMN 105, received_amt_tot - voucher_amt_tot 
			USING "------,---.&&" 
			SKIP 1 line 


			SKIP 1 line 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			

END REPORT 
