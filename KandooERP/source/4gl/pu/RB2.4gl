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
GLOBALS "../pu/RB2_GLOBALS.4gl" 
# \brief module RB2 Orders Report - by GL Account Code


DEFINE mdou_start_flg INTEGER 

FUNCTION RB2_main() 
	DEFER quit 
	DEFER interrupt
	
	CALL setModuleId("RB2")

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN "1" #UI/MENU Mode 
			OPEN WINDOW R124 with FORM "R124" 
			CALL  windecoration_r("R124") 
		
			MENU " ORDER BY GL Account" 
		
				BEFORE MENU 
					CALL publish_toolbar("kandoo","RB2","menu-order_by_gl_acc-1")
					CALL RB2_rpt_process(RB2_rpt_query())  
					CALL rpt_rmsreps_reset(NULL)
		
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
					
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				COMMAND "Run Report" " SELECT criteria AND PRINT REPORT" 
					CALL RB2_rpt_process(RB2_rpt_query())
					CALL rpt_rmsreps_reset(NULL)
		
				ON ACTION "Print Manager" 					#COMMAND KEY ("P",f11) "Print" "Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				COMMAND "Exit" " Exit TO menus" 
					EXIT MENU 
		
			END MENU 
			CLOSE WINDOW R124 
 	 
		WHEN "2" #Background Process with rmsreps.report_code
			CALL RB2_rpt_process(NULL)  

		WHEN "3" #Only create query-where-part
			OPEN WINDOW R124 with FORM "R124" 
			CALL  windecoration_r("R124") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(RB2_rpt_query()) #save where clause in env 
			CLOSE WINDOW R124 
			
		WHEN "4" #Background Process with SQL WHERE ARGUMENT
			CALL RB2_rpt_process(get_url_sel_text())
	END CASE
END FUNCTION 


FUNCTION RB2_rpt_query()
	DEFINE l_where_text STRING  
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
			CALL publish_toolbar("kandoo","RB2","construct-purchdetl-1") 

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


FUNCTION RB2_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT  #report array index

	DEFINE 
	exist SMALLINT, 
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

	LET l_rpt_idx = rpt_start(getmoduleid(),"RB2_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT RB2_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------


	LET mdou_start_flg = 0 


	LET l_query_text = 
	"SELECT purchdetl.*, purchhead.curr_code,purchhead.order_date, ", 
	" purchhead.conv_qty ", 
	"FROM purchdetl, purchhead ", 
	"WHERE purchdetl.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
	" purchhead.cmpy_code = purchdetl.cmpy_code AND ", 
	" purchdetl.vend_code = purchhead.vend_code AND ", 
	" purchdetl.order_num = purchhead.order_num AND ", 
	" purchhead.status_ind <> \"C\" AND ", 
	glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("RB2_rpt_list")].sel_text clipped," ",  
	" ORDER BY purchdetl.acct_code, purchdetl.order_num" 

	PREPARE choice FROM l_query_text 
	DECLARE selcurs CURSOR FOR choice 

 
	OPEN selcurs 

	WHILE true 
		FETCH selcurs INTO pr_purchdetl.*,pr_curr_code,pr_order_date, pr_conv_qty 
		IF status = notfound THEN 
			EXIT WHILE 
		END IF 

		#---------------------------------------------------------
		OUTPUT TO REPORT RB1_rpt_list(l_rpt_idx,
		pr_purchdetl.*, 
		pr_curr_code, 
		pr_order_date, 
		pr_conv_qty) 
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


REPORT rb2_list(p_rpt_idx,pr_purchdetl,pr_curr_code,pr_order_date, pr_conv_qty) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	 
	DEFINE 
	pr_purchdetl RECORD LIKE purchdetl.*, 
	pr_frgn RECORD 
		unit_cost_amt LIKE poaudit.unit_cost_amt, 
		unit_tax_amt LIKE poaudit.unit_tax_amt 
	END RECORD, 
	pr_poaudit RECORD LIKE poaudit.*, 
	pr_curr_code LIKE purchhead.curr_code, 
	pr_conv_qty LIKE purchhead.conv_qty, 
	pr_order_date LIKE purchhead.order_date, 
	coa_desc LIKE coa.desc_text, 
	s, len, new_flg INTEGER 

	OUTPUT 
	--left margin 0 
	ORDER external BY pr_purchdetl.acct_code, 
	pr_purchdetl.order_num 
	FORMAT 
		PAGE HEADER 
			IF pageno = 1 THEN 
				LET order_amt_ggtot = 0 
				LET received_amt_ggtot = 0 
				LET voucher_amt_ggtot = 0 
				LET order_amt_gtot = 0 
				LET received_amt_gtot = 0 
				LET voucher_amt_gtot = 0 
				LET order_amt_tot = 0 
				LET received_amt_tot = 0 
				LET voucher_amt_tot = 0 
			END IF

			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			 
		
			PRINT COLUMN 1, "** Values in Base Currency " 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 1, " GL Account", 
			COLUMN 20, " Description", 
			COLUMN 52, " Order", 
			COLUMN 61, " Order", 
			COLUMN 75, " Received", 
			COLUMN 89, " Vouchered", 
			COLUMN 103, " TO be ", 
			COLUMN 117, " TO be " 
			PRINT COLUMN 1, " Code", 
			COLUMN 52, "Number", 
			COLUMN 61, " Amount ", 
			COLUMN 75, " Amount ", 
			COLUMN 89, " Amount ", 
			COLUMN 103, " Received ", 
			COLUMN 117, "Vouchered " 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		BEFORE GROUP OF pr_purchdetl.acct_code 
			SELECT desc_text INTO coa_desc FROM coa 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND acct_code = pr_purchdetl.acct_code 
			PRINT COLUMN 1, pr_purchdetl.acct_code, 
			COLUMN 20, coa_desc[1,30]; 
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
			LET order_amt_tot = order_amt_tot + (pr_poaudit.order_qty * poaudit_value) 
			LET received_amt_tot = received_amt_tot + 
			(pr_poaudit.received_qty * poaudit_value) 
			LET voucher_amt_tot = voucher_amt_tot + 
			(pr_poaudit.voucher_qty * poaudit_value) 
		AFTER GROUP OF pr_purchdetl.order_num 
			PRINT COLUMN 52, pr_purchdetl.order_num USING "#######", 
			COLUMN 61, order_amt_tot USING "------,---.&&", 
			COLUMN 75, received_amt_tot USING "------,---.&&", 
			COLUMN 89, voucher_amt_tot USING "------,---.&&", 
			COLUMN 103, order_amt_tot - received_amt_tot USING "------,---.&&", 
			COLUMN 117, order_amt_tot - voucher_amt_tot USING "------,---.&&" 
			LET order_amt_gtot = order_amt_gtot + order_amt_tot 
			LET received_amt_gtot = received_amt_gtot + received_amt_tot 
			LET voucher_amt_gtot = voucher_amt_gtot + voucher_amt_tot 
			LET order_amt_tot = 0 
			LET received_amt_tot = 0 
			LET voucher_amt_tot = 0 
		AFTER GROUP OF pr_purchdetl.acct_code 
			PRINT COLUMN 61, "-------------", 
			COLUMN 75, "-------------", 
			COLUMN 89, "-------------", 
			COLUMN 103, "-------------", 
			COLUMN 117, "-------------" 
			PRINT COLUMN 1, "GL Account Totals: ", 
			COLUMN 61, order_amt_gtot USING "------,---.&&", 
			COLUMN 75, received_amt_gtot USING "------,---.&&", 
			COLUMN 89, voucher_amt_gtot USING "------,---.&&", 
			COLUMN 103,order_amt_gtot-received_amt_gtot USING "------,---.&&", 
			COLUMN 117,order_amt_gtot - voucher_amt_gtot USING "------,---.&&" 
			LET order_amt_ggtot = order_amt_ggtot + order_amt_gtot 
			LET received_amt_ggtot = received_amt_ggtot + received_amt_gtot 
			LET voucher_amt_ggtot = voucher_amt_ggtot + voucher_amt_gtot 
			LET order_amt_gtot = 0 
			LET received_amt_gtot = 0 
			LET voucher_amt_gtot = 0 
			SKIP 1 line 
		ON LAST ROW 
			PRINT COLUMN 61, "=============", 
			COLUMN 75, "=============", 
			COLUMN 89, "=============", 
			COLUMN 103, "=============", 
			COLUMN 117, "=============" 
			PRINT COLUMN 1, "Report Totals: ", 
			COLUMN 61, order_amt_ggtot USING "------,---.&&", 
			COLUMN 75, received_amt_ggtot USING "------,---.&&", 
			COLUMN 89, voucher_amt_ggtot USING "------,---.&&", 
			COLUMN 103,order_amt_ggtot-received_amt_ggtot USING "------,---.&&", 
			COLUMN 117,order_amt_ggtot-voucher_amt_ggtot USING "------,---.&&" 
			SKIP 1 line 
			SKIP 1 line 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			
			LET order_amt_ggtot = 0 
			LET received_amt_ggtot = 0 
			LET voucher_amt_ggtot = 0 
END REPORT 
