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
GLOBALS "../pu/RA8_GLOBALS.4gl"
###########################################################################
# MODULE Scope Variables
###########################################################################   
DEFINE modu_start_flg INTEGER 
###########################################################################
# FUNCTION RA8_main()
#
# RA8 Purchase Order Detail Report by Currency Code
###########################################################################   
FUNCTION RA8_main() 
 	DEFER quit 
	DEFER interrupt 
	CALL setModuleId("RA8") -- albo
	 
	OPEN WINDOW R124 with FORM "R124" 
	CALL  windecoration_r("R124") 

	MENU " Purchase Order Detail by Currency Code" 

		BEFORE MENU 
			CALL publish_toolbar("kandoo","RA8","menu-purchase_order_det-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
			
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "REPORT" --COMMAND "Report" " SELECT criteria AND PRINT REPORT" 
			CALL RA8_rpt_query() 
			NEXT option "Print Manager" 

		ON ACTION "Print Manager" 		#COMMAND KEY ("P",f11) "Print" "Print OR view using RMS"
			CALL run_prog("URS","","","","") 

		ON ACTION "CANCEL" --COMMAND KEY(interrupt, "E") "Exit" " Exit TO menus" 
			EXIT MENU 
	END MENU 
	CLOSE WINDOW R124 
END FUNCTION 
###########################################################################
# END FUNCTION RA8_main()
###########################################################################   


###########################################################################
# FUNCTION RA8_rpt_query() 
#
# 
###########################################################################   
FUNCTION RA8_rpt_query() 
	DEFINE l_where_text STRING 

	MESSAGE kandoomsg2("U",1001,"")	#1001 Enter Selection Criteria;  OK TO Continue.
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
			CALL publish_toolbar("kandoo","RA8","construct-purchhead-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN 
	END IF 


	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL
	ELSE
		RETURN l_where_text
	END IF 
	
END FUNCTION 
###########################################################################
# END FUNCTION RA8_rpt_query() 
###########################################################################   


###########################################################################
# FUNCTION RA8_rpt_process(p_where_text)
#
# 
###########################################################################   
FUNCTION RA8_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT  #report array index
	DEFINE exist SMALLINT, 
	pr_purchdetl RECORD LIKE purchdetl.*, 
	pr_order_date LIKE purchhead.order_date, 
	pr_curr_code LIKE purchhead.curr_code, 
	pr_conv_qty LIKE purchhead.conv_qty 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"RA9_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT RA9_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = 0, 
	BOTTOM MARGIN = 0, 
	LEFT MARGIN = 0, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------


	LET modu_start_flg = 0 
	
	LET l_query_text = 
	"SELECT purchdetl.*, purchhead.curr_code, purchhead.order_date, ", 
	" purchhead.conv_qty ", 
	"FROM purchdetl, purchhead ", 
	"WHERE purchdetl.cmpy_code = \"",glob_rec_kandoouser.cmpy_code, "\" AND purchhead.cmpy_code = purchdetl.cmpy_code AND purchdetl.vend_code = purchhead.vend_code AND purchdetl.order_num = purchhead.order_num AND ", 
	glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("RA9_rpt_list")].sel_text clipped," ",
	" ORDER BY purchhead.curr_code, purchdetl.vend_code, purchdetl.order_num" 


	PREPARE choice FROM l_query_text 
	DECLARE selcurs CURSOR FOR choice 

	OPEN selcurs 
 
	WHILE true 
		FETCH selcurs INTO pr_purchdetl.*,pr_curr_code,pr_order_date, 
		pr_conv_qty 
		IF status = notfound THEN 
			EXIT WHILE 
		END IF 
		IF int_flag OR quit_flag THEN 
			#8503 Continue Report(Y/N)
			IF kandoomsg("U",8503,"") = "N" THEN 
				#9501 Printing was aborted.
				LET msgresp=kandoomsg("U",9501,"") 
				EXIT WHILE 
			END IF 
		END IF 
		#---------------------------------------------------------
		OUTPUT TO REPORT RA9_rpt_list(l_rpt_idx,pr_purchdetl.*, pr_curr_code,pr_order_date, pr_conv_qty)
		IF NOT rpt_int_flag_handler2("Purchase Order:",pr_purchdetl.order_num,NULL,l_rpt_idx) THEN
			EXIT WHILE 
		END IF 
		#---------------------------------------------------------			

	END WHILE 

	FINISH REPORT RA9_rpt_list
	CALL rpt_finish("RA9_rpt_list")
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
# END FUNCTION RA8_rpt_process(p_where_text)
###########################################################################   


###########################################################################
# REPORT RA8_rpt_list(p_rpt_idx,pr_purchdetl,pr_curr_code,pr_order_date, pr_conv_qty)
#
# 
###########################################################################   
REPORT RA8_rpt_list(p_rpt_idx,pr_purchdetl,pr_curr_code,pr_order_date, pr_conv_qty)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]

	DEFINE pr_purchdetl RECORD LIKE purchdetl.*, 
	pr_poaudit RECORD LIKE poaudit.*, 
	pr_curr_code LIKE purchhead.curr_code, 
	pr_conv_qty LIKE purchhead.conv_qty, 
	pr_order_date LIKE purchhead.order_date, 
	new_o_flg,order_count,new_v_flg, v_order_num, new_c_flg INTEGER, 
	order_total, total_amt, 
	curr_total, grand_total, v_total LIKE poaudit.unit_cost_amt, 
	b_total_amt LIKE poaudit.line_total_amt, 
	b_order_total, b_curr_total, 
	b_v_total LIKE poaudit.unit_cost_amt 
	DEFINE l_offset1 SMALLINT
	DEFINE l_offset2 SMALLINT
	
	OUTPUT 
	left margin 0 
	ORDER external BY pr_curr_code, pr_purchdetl.vend_code, pr_purchdetl.order_num 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT 
			#COLUMN  1, "Vendor ",
			COLUMN 1, "Order", 
			COLUMN 10, "Ref", 
			COLUMN 26 , "Acct", 
			COLUMN 47, "Quantity", 
			COLUMN 58, "UOM", 
			COLUMN 71, "Cost", 
			COLUMN 85, "Tax", 
			COLUMN 98, "Total", 
			COLUMN 118, "Base " 


			PRINT 
			COLUMN 1, "Number", 
			COLUMN 26, "Code", 
			COLUMN 97, "Amount", 
			COLUMN 117, "Value" 


			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		ON EVERY ROW 
			PRINT COLUMN 10, pr_purchdetl.ref_text[1,15], 
			COLUMN 26, pr_purchdetl.acct_code ; 
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


			LET total_amt = pr_poaudit.line_total_amt / pr_conv_qty 
			PRINT COLUMN 45, pr_poaudit.order_qty , 
			COLUMN 58, pr_purchdetl.uom_code , 
			COLUMN 63, pr_poaudit.unit_cost_amt USING "---,---,---.&&" , 
			COLUMN 77, pr_poaudit.unit_tax_amt USING "--,---,---.&&", 
			COLUMN 92, pr_poaudit.line_total_amt USING "---,---,---.&&", 
			COLUMN 111,total_amt USING "---,---,---.&&" 
			LET order_total = order_total + total_amt 
			LET b_order_total = b_order_total + pr_poaudit.line_total_amt 

		BEFORE GROUP OF pr_curr_code 
			IF modu_start_flg = 0 THEN 
				LET order_count = 0 
				LET order_total = 0 
				LET total_amt = 0 
				LET curr_total = 0 
				LET v_total = 0 
				LET b_order_total = 0 
				LET b_total_amt = 0 
				LET b_curr_total = 0 
				LET b_v_total = 0 
				LET grand_total = 0 
				LET modu_start_flg = 1 
			END IF 
			PRINT COLUMN 1, "Currency Code: ", pr_curr_code 

		BEFORE GROUP OF pr_purchdetl.vend_code 
			PRINT COLUMN 30, "Vendor: " , pr_purchdetl.vend_code 

		BEFORE GROUP OF pr_purchdetl.order_num 
			PRINT COLUMN 1, pr_purchdetl.order_num USING "<<<<<<<<<<<" ; 
			LET v_order_num = v_order_num + 1 

		AFTER GROUP OF pr_curr_code 
			PRINT COLUMN 92, "===============", 
			COLUMN 111, "===============" 
			PRINT COLUMN 1, "Currency Total: ", 
			COLUMN 89,b_curr_total USING "--,---,---,---.&&", 
			COLUMN 108,curr_total USING "--,---,---,---.&&" 
			LET grand_total = grand_total + curr_total 
			LET curr_total = 0 
			LET b_curr_total = 0 
			SKIP 1 line 

		AFTER GROUP OF pr_purchdetl.vend_code 
			PRINT COLUMN 92, "----------------", 
			COLUMN 111, "----------------" 
			PRINT COLUMN 10, "Vendor Totals:", 
			COLUMN 25, "Orders:", v_order_num USING "<<<<<"; 
			IF v_order_num <> 0 THEN 
				PRINT COLUMN 40, "Avg: ", (v_total/v_order_num) 
				USING "--,---,---,---.&&"; 
			ELSE 
				PRINT COLUMN 40, "Avg: 0.00"; 
			END IF 
			PRINT COLUMN 89, b_v_total USING "--,---,---,---.&&", 
			COLUMN 108, v_total USING "--,---,---,---.&&" 
			SKIP 1 line 
			LET order_count = order_count + v_order_num 
			LET curr_total = curr_total + v_total 
			LET b_curr_total = b_curr_total + b_v_total 
			LET v_order_num = 0 
			LET v_total = 0 
			LET b_v_total = 0 

		AFTER GROUP OF pr_purchdetl.order_num 
			LET v_total = v_total + order_total 
			LET b_v_total = b_v_total + b_order_total 
			LET order_total = 0 
			LET b_order_total = 0 

		ON LAST ROW 
			NEED 5 LINES 
			SKIP 1 line 
			PRINT COLUMN 1, "Report Totals:", 
			COLUMN 108, grand_total USING "--,---,---,---.&&" 
			PRINT COLUMN 1, "Orders:", order_count USING "#####"; 
			IF order_count <> 0 THEN 
				PRINT COLUMN 15, "Avg: ", 
				(grand_total / order_count) USING "-,---,---,---.&&"; 
			ELSE 
				PRINT COLUMN 15, "Avg: 0.00"; 
			END IF 
			SKIP 2 LINES 

			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	

END REPORT 
###########################################################################
# END REPORT RA8_rpt_list(p_rpt_idx,pr_purchdetl,pr_curr_code,pr_order_date, pr_conv_qty)
########################################################################### 
