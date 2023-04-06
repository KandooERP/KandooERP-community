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
GLOBALS "../pu/RA9_GLOBALS.4gl"
###########################################################################
# MODULE Scope Variables
###########################################################################   
DEFINE modu_start_flg INTEGER 
###########################################################################
# FUNCTION RA9_main() 
#
# RA9 Purchase Order Outstanding Quantities Detail Report
###########################################################################   
FUNCTION RA9_main() 
 	DEFER quit 
	DEFER interrupt 
	CALL setModuleId("RA9") -- albo

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN "1" #UI/MENU Mode 	

	OPEN WINDOW R124 with FORM "R124a" 
	CALL  windecoration_r("R124a") 
		
		
			MENU " Purchase Order Outstanding Qtys" 
		
				BEFORE MENU 
					CALL publish_toolbar("kandoo","RA9","menu-purchase_order_outstd-1") 
					CALL RA9_rpt_process(RA9_rpt_query())
					
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				COMMAND "Report" " SELECT Criteria AND PRINT REPORT" 
					CALL RA9_rpt_query()
					CALL RA9_rpt_process(RA9_rpt_query()) 
		
				ON ACTION "Print Manager" #COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				COMMAND KEY(interrupt, "E") "Exit" " Exit TO menu" 
					EXIT MENU 
		
			END MENU 
			CLOSE WINDOW R124 
			

		WHEN "2" #Background Process with rmsreps.report_code
			CALL RA9_rpt_process(NULL)  

		WHEN "3" #Only create query-where-part
			OPEN WINDOW R124 with FORM "R124a" 
			CALL  windecoration_r("R124a") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(RA9_rpt_query()) #save where clause in env 
			CLOSE WINDOW R124 
			
		WHEN "4" #Background Process with SQL WHERE ARGUMENT
			CALL RA9_rpt_process(get_url_sel_text())
	END CASE			
			
END FUNCTION 
###########################################################################
# END FUNCTION RA9_main() 
########################################################################### 


###########################################################################
# FUNCTION RA9_rpt_query()
#
# 
########################################################################### 
FUNCTION RA9_rpt_query() 
	DEFINE l_where_text STRING 

	MESSAGE kandoomsg2("U",1001,"") #1001 Enter Selection Criteria;  OK TO Continue.
	CONSTRUCT BY NAME l_where_text ON purchdetl.vend_code, 
	poaudit.po_num, 
	purchhead.curr_code, 
	purchdetl.type_ind, 
	purchdetl.ref_text, 
	purchdetl.job_code, 
	purchhead.status_ind, 
	purchdetl.activity_code, 
	purchdetl.acct_code 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","RA9","construct-purchhead-1") 

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
# END FUNCTION RA9_rpt_query()
########################################################################### 


###########################################################################
# FUNCTION RA9_rpt_process(p_where_text)
#
# 
########################################################################### 
FUNCTION RA9_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT  #report array index 
	DEFINE exist SMALLINT 
	DEFINE pr_purchdetl RECORD 
		order_num LIKE purchdetl.order_num, 
		vend_code LIKE purchdetl.vend_code, 
		curr_code LIKE purchhead.curr_code, 

		conv_qty LIKE purchhead.conv_qty, 
		order_date LIKE purchhead.order_date, 
		ref_text LIKE purchdetl.ref_text, 
		line_num LIKE purchdetl.line_num , 
		order_qty LIKE poaudit.order_qty, 
		received_qty LIKE poaudit.received_qty 
	END RECORD 

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
	"SELECT purchdetl.order_num, purchdetl.vend_code, purchhead.curr_code, ", 
	" purchhead.conv_qty, ", 
	" purchhead.order_date, purchdetl.ref_text, purchdetl.line_num, ", 
	" sum(poaudit.order_qty), sum(poaudit.received_qty) ", 
	"FROM purchdetl, purchhead, poaudit ", 
	"WHERE purchdetl.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
	" purchdetl.cmpy_code = purchhead.cmpy_code AND ", 
	" purchdetl.order_num = purchhead.order_num AND ", 
	" purchdetl.vend_code = purchhead.vend_code AND ", 
	" purchdetl.cmpy_code = poaudit.cmpy_code AND ", 
	" purchdetl.order_num = poaudit.po_num AND ", 
	" purchdetl.vend_code = poaudit.vend_code AND ", 
	" purchdetl.line_num = poaudit.line_num AND ", 
	glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("RA9_rpt_list")].sel_text clipped," ",
	" group by purchdetl.order_num, purchdetl.vend_code, ", 
	" purchhead.curr_code, ", 
	" purchhead.conv_qty, ", 
	" purchhead.order_date, ", 
	" purchdetl.ref_text, purchdetl.line_num ", 
	" having sum(poaudit.order_qty) > sum(poaudit.received_qty) ", 
	" ORDER BY purchdetl.order_num, purchdetl.vend_code" 


	PREPARE choice FROM l_query_text 
	DECLARE selcurs CURSOR FOR choice 

	OPEN selcurs 
	--   OPEN WINDOW wfPU AT 10,10  -- albo  KD-756
	--      with 1 rows, 50 columns
	--      ATTRIBUTE(border)
 
	WHILE true 
		FETCH selcurs INTO pr_purchdetl.* 
		IF status = notfound THEN 
			EXIT WHILE 
		END IF 
		#---------------------------------------------------------
		OUTPUT TO REPORT RA9_rpt_list(l_rpt_idx,pr_purchdetl.*) 
		IF NOT rpt_int_flag_handler2("Purchase Order:",pr_purchdetl.order_num ,NULL,l_rpt_idx) THEN
			EXIT WHILE 
		END IF 
		#---------------------------------------------------------		
		
	END WHILE 
	#------------------------------------------------------------
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
# END FUNCTION RA9_rpt_process(p_where_text)
########################################################################### 


###########################################################################
# REPORT RA9_rpt_list(p_rpt_idx,pr_purchdetl)
#
# 
########################################################################### 
REPORT RA9_rpt_list(p_rpt_idx,pr_purchdetl) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE b_order_total LIKE poaudit.unit_cost_amt 
	DEFINE pr_poaudit RECORD LIKE poaudit.* 
	DEFINE pr_purchdetl RECORD 
		order_num LIKE purchdetl.order_num, 
		vend_code LIKE purchdetl.vend_code, 
		curr_code LIKE purchhead.curr_code, 

		conv_qty LIKE purchhead.conv_qty, 
		order_date LIKE purchhead.order_date, 
		ref_text LIKE purchdetl.ref_text, 
		line_num LIKE purchdetl.line_num, 
		order_qty LIKE poaudit.order_qty, 
		received_qty LIKE poaudit.received_qty 
	END RECORD 
	DEFINE ostd_qty LIKE poaudit.order_qty 
	DEFINE rep_uom_code LIKE purchdetl.uom_code 
	DEFINE new_flg, order_count INTEGER 
	DEFINE order_total, total_amt, grand_total LIKE poaudit.unit_cost_amt 
	
	OUTPUT 
	--left margin 0 
	ORDER external BY pr_purchdetl.order_num, pr_purchdetl.vend_code 

	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			

			PRINT COLUMN 1, "Order", 
			COLUMN 11, "Vendor", 
			COLUMN 25, "Ref", 
			COLUMN 48, "Qty", 
			COLUMN 58, "Qty", 
			COLUMN 68, "Qty", 
			COLUMN 75, "UOM", 
			COLUMN 80, "Curr", 
			COLUMN 96, "Cost", 
			COLUMN 110, "Tax", 
			COLUMN 121, " Value" 


			PRINT COLUMN 1, "Number", 
			COLUMN 25, "Code", 
			COLUMN 48, "Ordered", 
			COLUMN 58, "Received", 
			COLUMN 68, "Outstd", 
			COLUMN 80, "Code ", 
			COLUMN 119, "Outstanding" 


			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 


		ON EVERY ROW 
			PRINT COLUMN 25, pr_purchdetl.ref_text[1,15] , 
			COLUMN 45, pr_purchdetl.order_qty USING "#####&.&&", 
			COLUMN 55, pr_purchdetl.received_qty USING "#####&.&&"; 
			LET ostd_qty = pr_purchdetl.order_qty - pr_purchdetl.received_qty 
			SELECT uom_code 
			INTO rep_uom_code 
			FROM purchdetl 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
			order_num = pr_purchdetl.order_num AND 
			vend_code = pr_purchdetl.vend_code AND 
			line_num = pr_purchdetl.line_num 
			PRINT COLUMN 65, ostd_qty USING "#####&.&&", 
			COLUMN 75, rep_uom_code ; 
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
			PRINT COLUMN 80, pr_purchdetl.curr_code; 
			PRINT COLUMN 88, pr_poaudit.unit_cost_amt USING "---,---,---.&&" , 
			COLUMN 102, pr_poaudit.unit_tax_amt USING "---,---,---.&&"; 
			LET total_amt = ostd_qty * 
			(pr_poaudit.unit_cost_amt + pr_poaudit.unit_tax_amt) 
			LET order_total = order_total + total_amt 
			LET b_order_total = b_order_total + (total_amt / pr_purchdetl.conv_qty) 
			PRINT COLUMN 117,total_amt USING "---,---,---.&&" 

		ON LAST ROW 
			NEED 5 LINES 
			SKIP 1 line 
			PRINT COLUMN 1, "Report Totals in Base Currency :", 
			COLUMN 114, grand_total USING "--,---,---,---.&&" 
			PRINT COLUMN 1, "Orders:", order_count USING "#####"; 
			IF order_count <> 0 THEN 
				PRINT COLUMN 15, "Avg: ", (grand_total / order_count) 
				USING "---,---,---.&&"; 
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


		BEFORE GROUP OF pr_purchdetl.order_num 
			IF modu_start_flg = 0 THEN 
				LET order_count = 0 
				LET order_total = 0 
				LET b_order_total = 0 
				LET total_amt = 0 
				LET grand_total = 0 
				LET modu_start_flg = 1 
			END IF 
			LET order_count = order_count + 1 
			PRINT COLUMN 1, pr_purchdetl.order_num USING "<<<<<####", 
			COLUMN 11, pr_purchdetl.vend_code ; 

		AFTER GROUP OF pr_purchdetl.order_num 
			PRINT COLUMN 118, "-------------" 
			PRINT COLUMN 1, "Order Total:", 
			COLUMN 114, order_total USING "--,---,---,---.&&" 
			SKIP 2 LINES 

			LET grand_total = grand_total + b_order_total 
			LET order_total = 0 
			LET b_order_total = 0 


END REPORT 
###########################################################################
# END REPORT RA9_rpt_list(p_rpt_idx,pr_purchdetl)
###########################################################################