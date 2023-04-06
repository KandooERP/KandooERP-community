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
GLOBALS "../pu/RAC_GLOBALS.4gl"
###########################################################################
# MODULE Scope Variables
###########################################################################   
DEFINE modu_start_flg INTEGER 
###########################################################################
# FUNCTION RAC_main()
#
# RAC produces a Goods Receipt Report by G/L code
########################################################################### 
FUNCTION RAC_main() 
 	DEFER quit 
	DEFER interrupt 
	CALL setModuleId("RAC") -- albo
	 
	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN "1" #UI/MENU Mode 	

			OPEN WINDOW R137 with FORM "R137" 
			CALL  windecoration_r("R137") 
		
			MENU "Goods Receipts by GL" 
		
				BEFORE MENU 
					CALL publish_toolbar("kandoo","RAC","menu-goods_receipt-1") 
					CALL RAC_rpt_process(RAC_rpt_query())
					
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
					
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				COMMAND "Run Report" "SELECT criteria AND PRINT REPORT" 
					CALL RAC_rpt_process(RAC_rpt_query())
		
				ON ACTION "Print Manager" 			#COMMAND KEY ("P",f11) "Print" "Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				COMMAND KEY(interrupt, "E") "Exit" "Exit this program" 
					EXIT MENU 
		
			END MENU 
			CLOSE WINDOW R137 

		WHEN "2" #Background Process with rmsreps.report_code
			CALL RAC_rpt_process(NULL)  

		WHEN "3" #Only create query-where-part
			OPEN WINDOW R107 with FORM "R107" 
			CALL  windecoration_r("R107") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(RAC_rpt_query()) #save where clause in env 
			CLOSE WINDOW R107 
			
		WHEN "4" #Background Process with SQL WHERE ARGUMENT
			CALL RAC_rpt_process(get_url_sel_text())
	END CASE
END FUNCTION 
###########################################################################
# END FUNCTION RAC_main()
########################################################################### 


###########################################################################
# FUNCTION RAC_rpt_query() 
#
# 
########################################################################### 
FUNCTION RAC_rpt_query() 
	DEFINE l_where_text STRING 

	MESSAGE kandoomsg2("U",1001,"") # "Enter criteria FOR selection - ESC TO begin search"

	CONSTRUCT BY NAME l_where_text ON purchdetl.acct_code, 
	poaudit.year_num, 
	poaudit.period_num, 
	poaudit.po_num, 
	poaudit.vend_code, 
	purchdetl.ref_text, 

	poaudit.tran_date 


		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","RAC","construct-purchhead-1") 

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
# END FUNCTION RAC_rpt_query() 
########################################################################### 


###########################################################################
# FUNCTION RAC_rpt_process(p_where_text)
#
# 
########################################################################### 
FUNCTION RAC_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT  #report array index
	DEFINE pr_poaudit RECORD 
		acct_code LIKE purchdetl.acct_code, 

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
		posted_flag LIKE poaudit.posted_flag, 

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

	LET l_rpt_idx = rpt_start(getmoduleid(),"RAC_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT RAC_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = 0, 
	BOTTOM MARGIN = 0, 
	LEFT MARGIN = 0, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------

	
	LET l_query_text = " SELECT purchdetl.acct_code, poaudit.tran_date, ", 
	" poaudit.year_num, ", 
	" poaudit.period_num, poaudit.po_num, ", 
	" poaudit.jour_num, poaudit.vend_code, ", 
	" purchdetl.ref_text, purchdetl.desc_text, ", 
	" poaudit.received_qty,poaudit.unit_cost_amt, ", 
	" poaudit.line_total_amt, ", 

	" poaudit.posted_flag, ", 

	" purchhead.curr_code, ", 
	" purchhead.conv_qty ", 
	" FROM poaudit, purchdetl, purchhead ", 
	" WHERE poaudit.cmpy_code= \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
	" poaudit.cmpy_code = purchdetl.cmpy_code AND ", 
	" purchhead.cmpy_code = purchdetl.cmpy_code AND ", 
	" poaudit.po_num = purchdetl.order_num AND ", 
	" purchhead.order_num = purchdetl.order_num AND ", 
	" poaudit.line_num = purchdetl.line_num AND ", 
	" poaudit.received_qty != 0 AND ", 

	" (poaudit.tran_code = \"GR\" OR ", 
	" poaudit.tran_code = \"GA\") AND ", 
	glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("RAC_rpt_list")].sel_text clipped," ",
	" ORDER BY purchdetl.acct_code, poaudit.year_num, ", 
	" poaudit.period_num, poaudit.po_num" 


	PREPARE statement_1 FROM l_query_text 
	DECLARE poaudit_set CURSOR FOR statement_1 
	OPEN poaudit_set 
	--   OPEN WINDOW wfPU AT 10,10  -- albo  KD-756
	--      with 1 rows, 50 columns
	--      ATTRIBUTE(border, MESSAGE line first)


	FOREACH poaudit_set INTO pr_poaudit.* 
		#---------------------------------------------------------
		OUTPUT TO REPORT RAC_rpt_list(l_rpt_idx,pr_poaudit.*) 
		IF NOT rpt_int_flag_handler2("L Account Code:",pr_poaudit.acct_code,NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------		
	END FOREACH 


	#------------------------------------------------------------
	FINISH REPORT RAC_rpt_list
	CALL rpt_finish("RAC_rpt_list")
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
# END FUNCTION RAC_rpt_process(p_where_text)
###########################################################################


###########################################################################
# REPORT RAC_rpt_list(pr_poaudit)
#
# 
########################################################################### 
REPORT RAC_rpt_list(pr_poaudit) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE pr_poaudit RECORD 
		acct_code LIKE purchdetl.acct_code, 

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

		posted_flag LIKE poaudit.posted_flag, 

		curr_code LIKE purchhead.curr_code, 
		conv_qty LIKE purchhead.conv_qty 
	END RECORD 
	DEFINE gl_desc_text LIKE coa.desc_text  

	DEFINE first_time SMALLINT 
	DEFINE b_total_amt LIKE poaudit.line_total_amt 
	DEFINE bp_total_amt LIKE poaudit.unit_cost_amt 
	DEFINE by_total_amt LIKE poaudit.unit_cost_amt 
	DEFINE ba_total_amt LIKE poaudit.unit_cost_amt  
	DEFINE br_total_amt LIKE poaudit.unit_cost_amt 
	DEFINE l_offset1 SMALLINT
	DEFINE l_offset2 SMALLINT

	OUTPUT 

	ORDER external BY pr_poaudit.acct_code, pr_poaudit.year_num, pr_poaudit.period_num, pr_poaudit.po_num 

	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  
			#PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			#PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			

			PRINT COLUMN 1, "Order", 
			COLUMN 9, "Batch", 
			COLUMN 17, "Vendor ID", 
			COLUMN 29, "Reference", 
			COLUMN 45, "Description", 
			COLUMN 76, "Received", 
			COLUMN 95, "Line Total", 
			COLUMN 106, "Curr", 
			COLUMN 114, "Base Value" 

			PRINT COLUMN 1, "Number", 
			COLUMN 9, "Number", 
			COLUMN 76, "Quantity", 
			COLUMN 106, "Code", 
			COLUMN 123, "Posted" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		BEFORE GROUP OF pr_poaudit.acct_code 
			SELECT desc_text 
			INTO gl_desc_text 
			FROM coa 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
			acct_code = pr_poaudit.acct_code 

			PRINT COLUMN 1, "Account Code: ", pr_poaudit.acct_code, 
			COLUMN 40, gl_desc_text clipped 

			LET ba_total_amt = 0 
			IF first_time = 0 THEN 
				LET br_total_amt = 0 
				LET first_time = 1 
			END IF 
		BEFORE GROUP OF pr_poaudit.year_num 
			LET by_total_amt = 0 

		BEFORE GROUP OF pr_poaudit.period_num 
			PRINT COLUMN 1, "Year: ", pr_poaudit.year_num, 
			COLUMN 15, "Period: ", pr_poaudit.period_num 
			LET bp_total_amt = 0 

		BEFORE GROUP OF pr_poaudit.po_num 
			PRINT COLUMN 1, pr_poaudit.po_num USING "#######", 
			COLUMN 9, pr_poaudit.jour_num USING "#######", 
			COLUMN 17, pr_poaudit.vend_code; 

		ON EVERY ROW 
			PRINT COLUMN 29, pr_poaudit.ref_text[1,15], 
			COLUMN 45, pr_poaudit.desc_text[1,30], 
			COLUMN 76, pr_poaudit.received_qty USING "######&.&&"; 

			LET b_total_amt = pr_poaudit.line_total_amt / pr_poaudit.conv_qty 
			PRINT COLUMN 90, pr_poaudit.line_total_amt 
			USING "----,---,--&.&&", 

			COLUMN 106, pr_poaudit.curr_code, 
			COLUMN 111, b_total_amt 
			USING "----,---,--&.&&", 
			COLUMN 127, pr_poaudit.posted_flag 
			LET bp_total_amt = bp_total_amt + b_total_amt 
			LET by_total_amt = by_total_amt + b_total_amt 
			LET ba_total_amt = ba_total_amt + b_total_amt 
			LET br_total_amt = br_total_amt + b_total_amt 





		AFTER GROUP OF pr_poaudit.period_num 
			PRINT COLUMN 111, "---------------" 
			PRINT COLUMN 55, "Period Total:", 

			COLUMN 111, bp_total_amt 
			USING "----,---,--&.&&" 
			SKIP 1 LINES 

		AFTER GROUP OF pr_poaudit.year_num 
			PRINT COLUMN 111, "---------------" 
			PRINT COLUMN 55, "Year Total:", 

			COLUMN 111, by_total_amt 
			USING "----,---,--&.&&" 
			SKIP 1 LINES 

		AFTER GROUP OF pr_poaudit.acct_code 
			PRINT COLUMN 111, "---------------" 
			PRINT COLUMN 55, "GL Account Total:", 

			COLUMN 111, ba_total_amt 
			USING "----,---,--&.&&" 
			SKIP 1 LINES 

		ON LAST ROW 
			PRINT COLUMN 111, "---------------" 
			PRINT COLUMN 55, "Report Total:", 

			COLUMN 111, br_total_amt 
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
# END REPORT RAC_rpt_list(pr_poaudit)
########################################################################### 