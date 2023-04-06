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
GLOBALS "../pu/RAD_GLOBALS.4gl"
###########################################################################
# MODULE Scope Variables
###########################################################################   
DEFINE modu_start_flg INTEGER 
###########################################################################
# FUNCTION RAD_main() 
#
# RAD produces a Goods Receipt Report by Product by Day
###########################################################################   
FUNCTION RAD_main() 
	CALL authenticate("RAD") 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN "1" #UI/MENU Mode 

	OPEN WINDOW R137 with FORM "R137" 
	CALL  windecoration_r("R137") 

	MENU "Goods Receipts by Date" 

		BEFORE MENU 
			CALL publish_toolbar("kandoo","RAD","menu-goods_receipt-1") 
			CALL RAD_rpt_process(RAD_rpt_query())
			
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null)
			 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		COMMAND "Run Report" "SELECT criteria AND PRINT REPORT" 
			CALL RAD_rpt_process(RAD_rpt_query())

		ON ACTION "Print Manager"	#COMMAND KEY ("P",f11) "Print" "Print OR view using RMS"
			CALL run_prog("URS","","","","") 


		COMMAND KEY(interrupt, "E") "Exit" "Exit this program" 
			EXIT MENU 

	END MENU 
	CLOSE WINDOW R137 

		WHEN "2" #Background Process with rmsreps.report_code
			CALL RAD_rpt_process(NULL)  

		WHEN "3" #Only create query-where-part
			OPEN WINDOW R137 with FORM "R137" 
			CALL  windecoration_r("R137") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(RAD_rpt_query()) #save where clause in env 
			CLOSE WINDOW R137 
			
		WHEN "4" #Background Process with SQL WHERE ARGUMENT
			CALL RAD_rpt_process(get_url_sel_text())
	END CASE 
END FUNCTION 
###########################################################################
# END FUNCTION RAD_main() 
#
# RAD produces a Goods Receipt Report by Product by Day
###########################################################################   


###########################################################################
# FUNCTION RAD_rpt_query()
#
#
###########################################################################   
FUNCTION RAD_rpt_query()
 	DEFINE l_where_text STRING 

	LET msgresp = kandoomsg("U",1001,"") #"Enter criteria FOR selection - ESC TO begin search"

	CONSTRUCT BY NAME l_where_text ON purchdetl.acct_code, 
	poaudit.year_num, 
	poaudit.period_num, 
	poaudit.po_num, 
	poaudit.vend_code, 
	purchdetl.ref_text, 
	poaudit.tran_date 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","RAD","construct-poaudit-1") 

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
###########################################################################
# END FUNCTION RAD_rpt_query()
#
#
###########################################################################   


###########################################################################
# FUNCTION RAD_rpt_process(p_where_text) 
#
#
###########################################################################   
FUNCTION RAD_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT  #report array index 
	DEFINE pr_poaudit RECORD 
		acct_code LIKE purchdetl.acct_code, 
		tran_code LIKE poaudit.tran_code, 
		tran_num LIKE poaudit.tran_num, 
		tran_date LIKE poaudit.tran_date, 
		year_num LIKE poaudit.year_num, 
		period_num LIKE poaudit.period_num, 
		po_num LIKE poaudit.po_num, 
		jour_num LIKE poaudit.jour_num, 
		vend_code LIKE poaudit.vend_code, 
		ref_text LIKE purchdetl.ref_text, 
		desc_text LIKE purchdetl.desc_text, 
		received_qty LIKE poaudit.received_qty, 
		unit_cost_amt LIKE poaudit.unit_cost_amt, 
		line_total_amt LIKE poaudit.line_total_amt, 
		curr_code LIKE purchhead.curr_code, 
		conv_qty LIKE purchhead.conv_qty 
	END RECORD 
	
	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"RA1_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT RA1_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = 0, 
	BOTTOM MARGIN = 0, 
	LEFT MARGIN = 0, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------


	LET l_query_text = " SELECT purchdetl.acct_code, poaudit.tran_code, ", 
	" poaudit.tran_num, poaudit.tran_date, ", 
	" poaudit.year_num, ", 
	" poaudit.period_num, poaudit.po_num, ", 
	" poaudit.jour_num, poaudit.vend_code, ", 
	" purchdetl.ref_text, purchdetl.desc_text, ", 
	" poaudit.received_qty,poaudit.unit_cost_amt, ", 
	" poaudit.line_total_amt, ", 

	" purchhead.curr_code, ", 
	" purchhead.conv_qty ", 
	" FROM poaudit, purchdetl, purchhead ", 
	" WHERE poaudit.cmpy_code= \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
	" poaudit.cmpy_code = purchdetl.cmpy_code AND ", 
	" purchhead.cmpy_code = purchdetl.cmpy_code AND ", 
	" poaudit.po_num = purchdetl.order_num AND ", 
	" purchhead.order_num = purchdetl.order_num AND ", 
	" poaudit.line_num = purchdetl.line_num AND ", 
	" poaudit.received_qty > 0 AND ", 
	" (poaudit.tran_code = \"GR\" OR ", 
	" poaudit.tran_code = \"GA\") AND ", 
	glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("RA1_rpt_list")].sel_text clipped," ",
	" ORDER BY poaudit.tran_date, ", 
	" purchdetl.ref_text, ", 
	" poaudit.po_num" 





	PREPARE statement_1 FROM l_query_text 
	DECLARE poaudit_set CURSOR FOR statement_1 
	OPEN poaudit_set 

	FOREACH poaudit_set INTO pr_poaudit.*
		#---------------------------------------------------------
		OUTPUT TO REPORT RA1_rpt_list(l_rpt_idx,pr_poaudit.*) 
		IF NOT rpt_int_flag_handler2("roduct Code:",pr_poaudit.ref_text,NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------			 

	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT RA1_rpt_list
	CALL rpt_finish("RA1_rpt_list")
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
# END FUNCTION RAD_rpt_process(p_where_text) 
###########################################################################  

###########################################################################
# REPORT RAD_rpt_list(pr_poaudit)  
#
#
###########################################################################  
REPORT RAD_rpt_list(pr_poaudit) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE pr_poaudit RECORD 
		acct_code LIKE purchdetl.acct_code, 
		tran_code LIKE poaudit.tran_code, 
		tran_num LIKE poaudit.tran_num, 
		tran_date LIKE poaudit.tran_date, 
		year_num LIKE poaudit.year_num, 
		period_num LIKE poaudit.period_num, 
		po_num LIKE poaudit.po_num, 
		jour_num LIKE poaudit.jour_num, 
		vend_code LIKE poaudit.vend_code, 
		ref_text LIKE purchdetl.ref_text, 
		desc_text LIKE purchdetl.desc_text, 
		received_qty LIKE poaudit.received_qty, 
		unit_cost_amt LIKE poaudit.unit_cost_amt, 
		line_total_amt LIKE poaudit.line_total_amt, 

		curr_code LIKE purchhead.curr_code, 
		conv_qty LIKE purchhead.conv_qty 
	END RECORD 
	DEFINE b_total_amt LIKE poaudit.line_total_amt 
	DEFINE bt_total_amt, bp_total_amt, br_total_amt LIKE poaudit.unit_cost_amt 
	DEFINE first_time SMALLINT 

	OUTPUT 
 
	ORDER external BY pr_poaudit.tran_date, pr_poaudit.ref_text, 
	pr_poaudit.po_num 

	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  
			#PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			#PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			

			PRINT COLUMN 1, "Date", 
			COLUMN 10, "Reference", 
			COLUMN 27, "Description", 
			COLUMN 60, "Received", 
			COLUMN 105, "Curr" 
			PRINT COLUMN 27, "Vendor ID", 
			COLUMN 37, "Order", 
			COLUMN 47, "GR Num.", 
			COLUMN 60, "Quantity", 
			COLUMN 78, "Unit Cost", 
			COLUMN 93, "Line Total", 
			COLUMN 105, "Code", 
			COLUMN 115, "Base Value" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

		BEFORE GROUP OF pr_poaudit.tran_date 
			LET bt_total_amt = 0 
			IF first_time = 0 THEN 
				LET br_total_amt = 0 
				LET first_time = 1 
			END IF 
			PRINT COLUMN 1, pr_poaudit.tran_date 


		BEFORE GROUP OF pr_poaudit.ref_text 
			LET bp_total_amt = 0 
			PRINT COLUMN 10, pr_poaudit.ref_text[1,15], 
			COLUMN 25, pr_poaudit.desc_text 

		ON EVERY ROW 
			PRINT COLUMN 27, pr_poaudit.vend_code, 
			COLUMN 37, pr_poaudit.po_num USING "<<<<<<<", 
			COLUMN 47, pr_poaudit.tran_code, 
			COLUMN 49, pr_poaudit.tran_num USING "<<<<<<<", 
			COLUMN 60, pr_poaudit.received_qty USING "######&.&&", 
			COLUMN 72, pr_poaudit.unit_cost_amt 
			USING "----,---,--&.&&", 
			COLUMN 89, pr_poaudit.line_total_amt 
			USING "----,---,--&.&&" , 
			COLUMN 105, pr_poaudit.curr_code ; 
			LET b_total_amt = pr_poaudit.line_total_amt / pr_poaudit.conv_qty 
			PRINT COLUMN 113, b_total_amt 
			USING "----,---,--&.&&" 
			LET bp_total_amt = bp_total_amt + b_total_amt 
			LET bt_total_amt = bt_total_amt + b_total_amt 
			LET br_total_amt = br_total_amt + b_total_amt 

		AFTER GROUP OF pr_poaudit.ref_text 
			PRINT COLUMN 60, "----------", 
			COLUMN 113, "---------------" 
			PRINT COLUMN 25, "Product Total:", 
			COLUMN 59, GROUP sum(pr_poaudit.received_qty) 
			USING "#######&.&&", 
			COLUMN 113, bp_total_amt 
			USING "----,---,--&.&&" 
			SKIP 1 LINES 

		AFTER GROUP OF pr_poaudit.tran_date 
			PRINT COLUMN 60, "----------", 
			COLUMN 113, "---------------" 
			PRINT COLUMN 25, "Total FOR : ", pr_poaudit.tran_date USING "dd/mm/yy", 
			COLUMN 59, GROUP sum(pr_poaudit.received_qty) 
			USING "#######&.&&", 
			COLUMN 113, bt_total_amt 
			USING "----,---,--&.&&" 
			SKIP 1 LINES 

		ON LAST ROW 
			PRINT COLUMN 60, "-----------", 
			COLUMN 113, "---------------" 
			PRINT COLUMN 25, "Report Total", 
			COLUMN 59, sum(pr_poaudit.received_qty) 
			USING "#######&.&&", 
			COLUMN 113, br_total_amt 
			USING "----,---,--&.&&" 
			SKIP 2 LINES 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	


END REPORT 
###########################################################################
# END REPORT RAD_rpt_list(pr_poaudit)  
###########################################################################