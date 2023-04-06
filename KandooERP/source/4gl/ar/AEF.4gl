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
# GLOBAL SCOPE VARIABLES
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl"
  
###########################################################################
# MODULE SCOPE VARIABLES
###########################################################################
	DEFINE modu_query_text1 CHAR(1500) 
	DEFINE modu_query_text2 CHAR(1500) 
	DEFINE modu_len SMALLINT 
	DEFINE modu_s SMALLINT 
	DEFINE modu_col SMALLINT 
	DEFINE modu_sel_cnt INTEGER 
	DEFINE modu_cmpy_head CHAR(80) 
	DEFINE modu_rep_type CHAR(1) #glob_rec_rpt_selector.ref1_ind = modu_rep_type
	DEFINE modu_report_tot1 LIKE invoicedetl.line_total_amt 
	DEFINE modu_report_tot2 LIKE invoicedetl.line_total_amt 
	DEFINE modu_pagebr CHAR(1)
	 
###########################################################################
# FUNCTION AEF_main()
#
# Sales Margin by Item Report
# CALL security ("S1D") - IS this actually S1D ??? (s1d.4gl/mk does NOT l_exist)
###########################################################################
FUNCTION AEF_main() 
	DEFER interrupt 
	DEFER quit 
	
	CALL setModuleId("AEF") 

	CREATE temp TABLE itemsum(cat_code CHAR(3), 
	part_code CHAR(15), 
	level_code CHAR(1), 
	cust_code CHAR(8), 
	order_num INTEGER, 
	ship_qty FLOAT, 
	line_total_amt money(14,2), 
	ware_code CHAR(3) 
	)with no LOG 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 
			OPEN WINDOW A701 with FORM "A701" 
			CALL windecoration_a("A701") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title
		
			MENU " Sales Margin by Item Report" 
		
				BEFORE MENU 
					CALL publish_toolbar("kandoo","AEF","menu-sales-margin-item") 
					CALL AEF_rpt_process(AEF_rpt_query())
					
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				ON ACTION "Report" #COMMAND "Run" " Enter Selection Criteria AND Generate Report"
					CALL AEF_rpt_process(AEF_rpt_query())
					
				ON ACTION "Print Manager"		#COMMAND "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "Exit"	#  COMMAND KEY (interrupt,"E")"Exit" " Exit TO Menus"
					EXIT MENU 
			END MENU 
		
			CLOSE WINDOW A701 
	 
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL AEF_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW A701 with FORM "A701" 
			CALL windecoration_a("A701") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(AEF_rpt_query()) #save where clause in env 
			CLOSE WINDOW A701 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL AEF_rpt_process(get_url_sel_text())
	END CASE 	
END FUNCTION 
###########################################################################
# END FUNCTION AEF_main()
###########################################################################


###########################################################################
# FUNCTION AEF_rpt_query() 
#
#
###########################################################################
FUNCTION AEF_rpt_query() 
	#these variables will be stored in rmsreps
	DEFINE l_where_text STRING
	DEFINE l_rec_fiscal_period_range RECORD
		year_num1 LIKE period.year_num, #glob_rec_rpt_selector.ref1_num
		period_num1 LIKE period.period_num, #glob_rec_rpt_selector.ref3_code
		year_num2 LIKE period.year_num, #glob_rec_rpt_selector.ref2_num
		period_num2 LIKE period.period_num #glob_rec_rpt_selector.ref4_code
	END RECORD
	DEFINE l_part_level LIKE invoicedetl.level_code #glob_rec_rpt_selector.ref2_code 
	DEFINE l_nilval CHAR(1)  #glob_rec_rpt_selector.ref2_code 	
	#----------------------------------------------	
	DEFINE l_exist SMALLINT 
	DEFINE l_rec_itemsum RECORD 
		cat_code LIKE invoicedetl.cat_code, 
		part_code LIKE invoicedetl.part_code, 
		level_code LIKE invoicedetl.level_code, 
		cust_code LIKE invoicehead.cust_code, 
		order_num LIKE invoicehead.ord_num, 
		ship_qty LIKE invoicedetl.ship_qty, 
		line_total_amt LIKE invoicedetl.line_total_amt, 
		ware_code LIKE prodstatus.ware_code 
	END RECORD 
	DEFINE l_rec_itemsum2 RECORD 
		cat_code LIKE invoicedetl.cat_code, 
		part_code LIKE invoicedetl.part_code, 
		level_code LIKE invoicedetl.level_code, 
		ware_code LIKE prodstatus.ware_code, 
		ship_qty LIKE invoicedetl.ship_qty, 
		line_total_amt LIKE invoicedetl.line_total_amt, 
		one_perc LIKE invoicedetl.line_total_amt 
	END RECORD 
	DEFINE l_cont CHAR(1) 
	DEFINE l_ware_code LIKE invoicedetl.ware_code
	DEFINE l_part_code LIKE invoicedetl.part_code
	DEFINE l_inv_num LIKE invoicedetl.inv_num
	DEFINE l_line_num LIKE invoicedetl.line_num 


	LET modu_rep_type = "B"

	#Fiscal Period AND report type selector
	MESSAGE kandoomsg2("A",1001,"")	#1001 Enter Selection Criteria; ESC TO Continue
	INPUT 
		modu_rep_type, #glob_rec_rpt_selector.ref1_ind
		l_rec_fiscal_period_range.year_num1, 
		l_rec_fiscal_period_range.period_num1, 
		l_rec_fiscal_period_range.year_num2, 
		l_rec_fiscal_period_range.period_num2 WITHOUT DEFAULTS 
	FROM
	 	rep_type, 
		year_num1, 
		period_num1, 
		year_num2, 
		period_num2 ATTRIBUTE(UNBUFFERED)	

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","AEF","inp-period") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER FIELD rep_type #glob_rec_rpt_selector.ref1_ind 
			CASE modu_rep_type 
				WHEN "S" #Summary Report
					NEXT FIELD year_num1 

				WHEN "D" #Detailed Report
					LET l_rec_fiscal_period_range.year_num1 = "" 
					LET l_rec_fiscal_period_range.period_num1 = "" 
					LET l_rec_fiscal_period_range.year_num2 = "" 
					LET l_rec_fiscal_period_range.period_num2 = "" 
					
					DISPLAY l_rec_fiscal_period_range.year_num1 TO year_num1 
					DISPLAY l_rec_fiscal_period_range.period_num1 TO period_num1 
					DISPLAY l_rec_fiscal_period_range.year_num2 TO year_num2 
					DISPLAY l_rec_fiscal_period_range.period_num2 TO period_num2 
					
					EXIT INPUT 

				WHEN "B" #Both (Summary & Detailed Report)
					NEXT FIELD year_num1 

				OTHERWISE 
					ERROR "You must INPUT either 'modu_s' OR 'D' OR 'B'" 
					NEXT FIELD rep_type 
			END CASE 

		AFTER FIELD year_num1 
			IF l_rec_fiscal_period_range.year_num1 IS NULL THEN 
				ERROR kandoomsg2("U",9901,"")		#9901 Value must be entered
				NEXT FIELD year_num1 
			END IF 

		AFTER FIELD period_num1 
			IF l_rec_fiscal_period_range.period_num1 IS NULL THEN 
				ERROR kandoomsg2("U",9901,"")	#9901 Value must be entered
				NEXT FIELD period_num1 
			END IF 

		AFTER FIELD year_num2 
			IF l_rec_fiscal_period_range.year_num2 IS NULL THEN 
				ERROR kandoomsg2("U",9901,"")	#9901 Value must be entered
				NEXT FIELD year_num2 
			END IF 
			IF l_rec_fiscal_period_range.year_num2 < l_rec_fiscal_period_range.year_num1 THEN 
				ERROR "Then ending year cannot be less than the starting year" 
					NEXT FIELD year_num2 
				END IF 
				IF l_rec_fiscal_period_range.year_num1 < l_rec_fiscal_period_range.year_num2 - 1 THEN 
					ERROR "Summary REPORT can only cover a two year time span" 
					NEXT FIELD year_num2 
				END IF 

		AFTER FIELD period_num2 
			IF l_rec_fiscal_period_range.period_num2 IS NULL THEN 
				ERROR "You must INPUT a value FOR the ending period" 
				NEXT FIELD period_num2 
			END IF 
			IF l_rec_fiscal_period_range.year_num1 = l_rec_fiscal_period_range.year_num2 
			AND l_rec_fiscal_period_range.period_num2 < l_rec_fiscal_period_range.period_num1 THEN 
				ERROR 
				"Ending period must be greater than starting period FOR same year" 
				NEXT FIELD period_num2 
			END IF 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 
			IF l_rec_fiscal_period_range.year_num1 IS NULL THEN 
				ERROR "You must INPUT a value FOR the starting year" 
				NEXT FIELD year_num1 
			END IF 
			IF l_rec_fiscal_period_range.period_num1 IS NULL THEN 
				ERROR "You must INPUT a value FOR the starting period" 
				NEXT FIELD period_num1 
			END IF 
			IF l_rec_fiscal_period_range.year_num2 IS NULL THEN 
				ERROR "You must INPUT a value FOR the ending year" 
				NEXT FIELD year_num2 
			END IF 
			IF l_rec_fiscal_period_range.year_num2 < l_rec_fiscal_period_range.year_num1 THEN 
				ERROR "Then ending year cannot be less than the starting year" 
					NEXT FIELD year_num2 
				END IF 
				IF l_rec_fiscal_period_range.year_num1 < l_rec_fiscal_period_range.year_num2 - 1 THEN 
					ERROR "Summary REPORT can only cover a two year time span" 
					NEXT FIELD year_num2 
				END IF 
				IF l_rec_fiscal_period_range.period_num2 IS NULL THEN 
					ERROR "You must INPUT a value FOR the ending period" 
					NEXT FIELD period_num2 
				END IF 
				IF l_rec_fiscal_period_range.year_num1 = l_rec_fiscal_period_range.year_num2 
				AND l_rec_fiscal_period_range.period_num2 < l_rec_fiscal_period_range.period_num1 THEN 
					ERROR 
					"Ending period must be greater than starting period FOR same year" 
					NEXT FIELD period_num2 
				END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = 0 
		LET quit_flag = 0 
		RETURN NULL
	ELSE
	LET glob_rec_rpt_selector.ref1_ind = modu_rep_type 
	LET glob_rec_rpt_selector.ref1_num = l_rec_fiscal_period_range.year_num1
	LET glob_rec_rpt_selector.ref2_num = l_rec_fiscal_period_range.period_num1
	LET glob_rec_rpt_selector.ref3_num = l_rec_fiscal_period_range.year_num2
	LET glob_rec_rpt_selector.ref4_num = l_rec_fiscal_period_range.period_num2 	
	END IF 

	CONSTRUCT BY NAME l_where_text ON product.vend_code, 
	invoicedetl.cust_code, 
	invoicedetl.level_code, 
	invoicedetl.cat_code, 
	invoicedetl.part_code 


		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","AEF","construct-invoicedetl") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = 0 
		LET quit_flag = 0 
		RETURN NULL
	END IF 

	#Part Level Selector
	INPUT l_part_level FROM part_level 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","AEF","inp-part_level") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER FIELD part_level 
			IF (l_part_level < 1 OR l_part_level > 9) 
			AND l_part_level IS NOT NULL THEN 
				ERROR 'you must enter a product price level between 1 AND 9' 
				NEXT FIELD part_level 
			END IF 
	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = 0 
		LET quit_flag = 0 
		RETURN NULL
	ELSE
		LET glob_rec_rpt_selector.ref2_ind = l_part_level
	END IF 


	LET modu_pagebr = NULL 

	#huho
	LET modu_pagebr = "N" 
	LET modu_pagebr[1] = fgl_winbutton("Page Break", "Page break on Supplier?", "No", "Yes|No|Cancel", "exclamation", 1) 


	IF int_flag OR quit_flag OR modu_pagebr[1] = "C" THEN 
		LET int_flag = 0 
		LET quit_flag = 0 
		CLOSE WINDOW getinfo 
		RETURN 
	END IF 


	LET l_nilval = NULL  #glob_rec_rpt_selector.ref2_code
	LET l_nilval[1] = fgl_winbutton("Nil Values", "Show nil VALUES?", "No", "Yes|No|Cancel", "exclamation", 1) 
	LET glob_rec_rpt_selector.ref2_code = l_nilval[1]

	IF int_flag !=0 OR quit_flag !=0 OR l_nilval[1] = "C" THEN 
		CLOSE WINDOW nilval 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL
	ELSE
		RETURN l_where_text
	END IF 
END FUNCTION
###########################################################################
# END FUNCTION AEF_rpt_query() 
###########################################################################


###########################################################################
# FUNCTION AEF_rpt_process() 
#
#
###########################################################################
FUNCTION AEF_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING 
	DEFINE l_rpt_idx SMALLINT  
	#these variables are stored in rmsreps
	DEFINE l_rec_fiscal_period_range RECORD
		year_num1 LIKE period.year_num, #glob_rec_rpt_selector.ref1_num
		period_num1 LIKE period.period_num, #glob_rec_rpt_selector.ref3_code
		year_num2 LIKE period.year_num, #glob_rec_rpt_selector.ref2_num
		period_num2 LIKE period.period_num #glob_rec_rpt_selector.ref4_code
	END RECORD
 
	DEFINE l_part_level LIKE invoicedetl.level_code #glob_rec_rpt_selector.ref2_code 
	DEFINE l_nilval CHAR(1)  #glob_rec_rpt_selector.ref2_code 	
	#------------------------------------------
	
	DEFINE l_exist SMALLINT 
	DEFINE l_rec_itemsum RECORD 
		cat_code LIKE invoicedetl.cat_code, 
		part_code LIKE invoicedetl.part_code, 
		level_code LIKE invoicedetl.level_code, 
		cust_code LIKE invoicehead.cust_code, 
		order_num LIKE invoicehead.ord_num, 
		ship_qty LIKE invoicedetl.ship_qty, 
		line_total_amt LIKE invoicedetl.line_total_amt, 
		ware_code LIKE prodstatus.ware_code 
	END RECORD 
	DEFINE l_rec_itemsum2 RECORD 
		cat_code LIKE invoicedetl.cat_code, 
		part_code LIKE invoicedetl.part_code, 
		level_code LIKE invoicedetl.level_code, 
		ware_code LIKE prodstatus.ware_code, 
		ship_qty LIKE invoicedetl.ship_qty, 
		line_total_amt LIKE invoicedetl.line_total_amt, 
		one_perc LIKE invoicedetl.line_total_amt 
	END RECORD 
	DEFINE l_cont CHAR(1) 
	DEFINE l_ware_code LIKE invoicedetl.ware_code
	DEFINE l_part_code LIKE invoicedetl.part_code
	DEFINE l_inv_num LIKE invoicedetl.inv_num
	DEFINE l_line_num LIKE invoicedetl.line_num 


	# Check Arguments and URL ------------------------------------------------------------
	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF
	#------------------------------------------------------------
	# NOTE: 
	# modu_rep_type = "D" = Detailed Report
	# modu_s = "S" = Summary report
	# modu_rep_type = "B" = #Both (Summary & Detailed Report)
	#------------------------------------------------------------

	#------------------------------------------------------------	
	#In normal mode, the variable/value is stored in module scope: modu_rep_type
	#In background process mode, we need to pull it from rmsreps
	IF rpt_get_is_background_process() 	THEN
		LET modu_rep_type = db_rmsreps_get_ref1_ind(UI_OFF,get_url_report_code()) #this variable are stored in rmsreps	
	END IF 
	#------------------------------------------------------------

	#Report Type = Detailed
	IF modu_rep_type = "D" OR modu_rep_type = "B" THEN #Detailed Or Both
		#------------------------------------------------------------
		LET l_rpt_idx = rpt_start("AEF-DET","AEF_rpt_list_detailed",p_where_text, RPT_SHOW_RMS_DIALOG)
		IF l_rpt_idx = 0 THEN #User pressed CANCEL
			RETURN FALSE
		END IF	
		START REPORT AEF_rpt_list_detailed TO rpt_get_report_file_with_path2(l_rpt_idx)
		WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
		TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
		BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
		LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
		RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
		LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AEF_rpt_list_detailed")].sel_text

		#these variables are stored in rmsreps
		LET l_rec_fiscal_period_range.year_num1 = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AEF_rpt_list_detailed")].ref1_num 
		LET l_rec_fiscal_period_range.period_num1 = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AEF_rpt_list_detailed")].ref2_num 
		LET l_rec_fiscal_period_range.year_num2 = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AEF_rpt_list_detailed")].ref3_num  
		LET l_rec_fiscal_period_range.period_num2 = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AEF_rpt_list_detailed")].ref4_num  	
		LET l_part_level = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AEF_rpt_list_detailed")].ref2_ind
		LET l_nilval = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AEF_rpt_list_detailed")].ref2_code 
		#------------------------------------------------------------
	END IF
	
	#Report Type = Summary
	IF modu_rep_type = "S" OR modu_rep_type = "B" THEN #Detailed Or Both
		#------------------------------------------------------------
		LET l_rpt_idx = rpt_start("AEE-SUM","AEF_rpt_list_summary",p_where_text, RPT_SHOW_RMS_DIALOG)
		IF l_rpt_idx = 0 THEN #User pressed CANCEL
			RETURN FALSE
		END IF	
		START REPORT AEF_rpt_list_summary TO rpt_get_report_file_with_path2(l_rpt_idx)
		WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
		TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
		BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
		LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
		RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
		LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AEF_rpt_list_summary")].sel_text

		#these variables are stored in rmsreps
		LET l_rec_fiscal_period_range.year_num1 = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AEF_rpt_list_summary")].ref1_num 
		LET l_rec_fiscal_period_range.period_num1 = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AEF_rpt_list_summary")].ref2_num 
		LET l_rec_fiscal_period_range.year_num2 = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AEF_rpt_list_summary")].ref3_num  
		LET l_rec_fiscal_period_range.period_num2 = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AEF_rpt_list_summary")].ref4_num  	
		LET l_part_level = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AEF_rpt_list_summary")].ref2_ind
		LET l_nilval = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AEF_rpt_list_summary")].ref2_code 
		#------------------------------------------------------------

	END IF	
		#------------------------------------------------------------

	

	#Detailed Report Driver
	IF modu_rep_type = "D" OR modu_rep_type = "B" THEN #Detailed or Both
		LET modu_query_text1 = 
		" SELECT invoicedetl.cat_code, ", 
		" invoicedetl.part_code, ", 
		" invoicedetl.level_code, ", 
		" invoicehead.cust_code, ", 
		" invoicehead.ord_num, ", 
		" invoicedetl.ship_qty, ", 
		" invoicedetl.line_total_amt, ", 
		" invoicedetl.ware_code, ", 
		" invoicedetl.inv_num, ", 
		" invoicedetl.line_num ", 
		" FROM invoicehead, invoicedetl, product ", 
		" WHERE invoicehead.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
		" invoicehead.cmpy_code = invoicedetl.cmpy_code AND ", 
		" invoicehead.cmpy_code = product.cmpy_code AND ", 
		" invoicehead.cust_code = invoicedetl.cust_code AND ", 
		" invoicehead.inv_num = invoicedetl.inv_num AND ", 
		" invoicedetl.part_code = product.part_code AND ", 
		glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AEF_rpt_list_detailed")].sel_text clipped 
	END IF 
	
	#Summary Report Driver
	IF modu_rep_type = "S" OR modu_rep_type = "B" THEN #Summary or Both
		IF l_rec_fiscal_period_range.year_num1 = l_rec_fiscal_period_range.year_num2 
		THEN 
			LET modu_query_text2 = 
			" SELECT invoicedetl.cat_code, ", 
			" invoicedetl.part_code, ", 
			" invoicedetl.level_code, ", 
			" invoicehead.cust_code, ", 
			" invoicehead.ord_num, ", 
			" invoicedetl.ship_qty, ", 
			" invoicedetl.line_total_amt, ", 
			" invoicedetl.ware_code, ", 
			" invoicedetl.inv_num, ", 
			" invoicedetl.line_num ", 
			" FROM invoicehead, invoicedetl, product ", 
			" WHERE invoicehead.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
			" invoicehead.cmpy_code = invoicedetl.cmpy_code AND ", 
			" invoicehead.cmpy_code = product.cmpy_code AND ", 
			" invoicehead.cust_code = invoicedetl.cust_code AND ", 
			" invoicehead.inv_num = invoicedetl.inv_num AND ", 
			" invoicehead.year_num = ", l_rec_fiscal_period_range.year_num1, " AND ", 
			" invoicehead.period_num >= ", l_rec_fiscal_period_range.period_num1, " AND ", 
			" invoicehead.period_num <=", l_rec_fiscal_period_range.period_num2, " AND ", 
			" invoicedetl.part_code = product.part_code AND ", 
			glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AEF_rpt_list_summary")].sel_text clipped 
		ELSE 
			LET modu_query_text2 = 
			" SELECT invoicedetl.cat_code, ", 
			" invoicedetl.part_code, ", 
			" invoicedetl.level_code, ", 
			" invoicehead.cust_code, ", 
			" invoicehead.ord_num, ", 
			" invoicedetl.ship_qty, ", 
			" invoicedetl.line_total_amt, ", 
			" invoicedetl.ware_code, ", 
			" invoicedetl.inv_num, ", 
			" invoicedetl.line_num ", 
			" FROM invoicehead, invoicedetl, product ", 
			" WHERE invoicehead.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
			" invoicehead.cmpy_code = invoicedetl.cmpy_code AND ", 
			" invoicehead.cmpy_code = product.cmpy_code AND ", 
			" invoicehead.cust_code = invoicedetl.cust_code AND ", 
			" invoicehead.inv_num = invoicedetl.inv_num AND ", 
			" ((invoicehead.year_num = ", l_rec_fiscal_period_range.year_num1, " AND ", 
			" invoicehead.period_num >= ", l_rec_fiscal_period_range.period_num1, ") OR ", 
			" (invoicehead.year_num = ", l_rec_fiscal_period_range.year_num2, " AND ", 
			" invoicehead.period_num <=", l_rec_fiscal_period_range.period_num2, " )) AND ", 
			" invoicedetl.part_code = product.part_code AND ", 
			glob_arr_rec_rpt_rmsreps[1].sel_text clipped 
		END IF 
	END IF 
	CLEAR screen 
	--DISPLAY " Searching Database Please Stand By" at 12,10 

	DELETE FROM itemsum 
	WHERE 1=1 
	
	
	####################################################################
	###   Detailed Report
	###
	IF modu_rep_type = "D" OR modu_rep_type = "B" THEN #Detailed or Both
#		#------------------------------------------------------------	 
#		CALL upd_rms(glob_rec_kandoouser.cmpy_code, glob_rec_kandoouser.sign_on_code, glob_rec_kandoouser.security_ind, 
#		glob_rec_rmsreps.report_width_num, "S1D", "Item Sales Report - Detailed") 
#		RETURNING glob_rec_rmsreps.file_text 
#
#		START REPORT AEF_rpt_list_detailed TO glob_rec_rmsreps.file_text 
#		MESSAGE "Processing Report - ", trim(glob_rec_rmsreps.report_text), ": ", trim(glob_rec_rmsreps.file_text)
#		#------------------------------------------------------------
	END IF
	
	####################################################################
	###   Summary Report
	###
	IF modu_rep_type = "S" OR modu_rep_type = "B" THEN #Summary or both

		
		PREPARE choice1 FROM modu_query_text1 
		DECLARE selcurs1 CURSOR FOR choice1 

		CLEAR screen 
		MESSAGE "Loading temporary table...."

		FOREACH selcurs1 INTO l_rec_itemsum.*, l_inv_num, l_line_num 
			LET l_ware_code = l_rec_itemsum.ware_code 
			CALL check_status(l_rec_itemsum.part_code, l_part_level, l_ware_code, 
			l_inv_num, l_line_num) RETURNING l_cont 
			IF l_cont = "Y" THEN 
		--		MESSAGE "Category: ", trim( l_rec_itemsum.cat_code) 
		--		MESSAGE "Part Code: ", trim(l_rec_itemsum.part_code) 

				IF ((l_rec_itemsum.line_total_amt <> 0) OR (l_nilval = "Y" AND 
				l_rec_itemsum.line_total_amt = 0)) THEN 
					IF l_rec_itemsum.level_code IS NULL OR 
					l_rec_itemsum.level_code = " " THEN 
						DECLARE ordcurs CURSOR FOR 
						SELECT level_ind 
						INTO l_rec_itemsum.level_code 
						FROM orderdetl 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
						cust_code = l_rec_itemsum.cust_code AND 
						order_num = l_rec_itemsum.order_num AND 
						part_code = l_rec_itemsum.part_code 
						OPEN ordcurs 
						FETCH ordcurs 
						CLOSE ordcurs 
					END IF
					 
					INSERT INTO itemsum VALUES (l_rec_itemsum.*)
					 
				END IF 
			END IF 

		END FOREACH 

--		CLEAR screen 
--		MESSAGE "Creating index...."  

		CREATE INDEX tmp_item ON itemsum(cat_code, part_code, level_code) 
		DECLARE itemcurs CURSOR FOR 
		SELECT cat_code, part_code, level_code, ware_code, sum(ship_qty), 
		sum(line_total_amt) 
		FROM itemsum 
		GROUP BY cat_code, part_code, level_code, ware_code 
		ORDER BY part_code, level_code 

--		CLEAR screen 
--		MESSAGE "Creating Detail Report...." 

		LET modu_sel_cnt = 0 
		LET modu_report_tot1 = 0 
		LET modu_report_tot2 = 0 

		FOREACH itemcurs INTO l_rec_itemsum2.* 
			LET modu_sel_cnt = modu_sel_cnt + 1 
			MESSAGE "Category: ", trim(l_rec_itemsum2.cat_code) 
			MESSAGE "Part Code: ", trim(l_rec_itemsum2.part_code) 

			LET l_rec_itemsum2.one_perc = (0.01 * l_rec_itemsum2.line_total_amt) 
			#---------------------------------------------------------
			OUTPUT TO REPORT AEF_rpt_list_detailed(l_rpt_idx,l_rec_itemsum2.*,l_rec_fiscal_period_range.*,l_nilval,l_part_level)  
			IF NOT rpt_int_flag_handler2("Item:",l_rec_itemsum2.cat_code,l_rec_itemsum2.part_code,l_rpt_idx) THEN
				EXIT FOREACH 
			END IF 
			#---------------------------------------------------------
			 
		END FOREACH 

		CLOSE itemcurs 
		DROP INDEX tmp_item 

--		DISPLAY " Database Search IS Complete" at 12,10 
	  
	END IF 




#***************************************************************************************



	DELETE FROM itemsum 
	WHERE 1=1 
	####################################################################
	###   Summary Report
	###
	IF modu_rep_type = "S" OR modu_rep_type = "B" THEN #Summary or Both
	
		PREPARE choice2 FROM modu_query_text2 
		DECLARE selcurs2 CURSOR FOR choice2 

		CLEAR screen 
		MESSAGE "Loading temporary table...."  

		FOREACH selcurs2 INTO l_rec_itemsum.*, l_inv_num, l_line_num 
			LET l_ware_code = l_rec_itemsum.ware_code 
			CALL check_status(l_rec_itemsum.part_code, l_part_level, l_ware_code, 
			l_inv_num, l_line_num) RETURNING l_cont 
			IF l_cont = "Y" THEN 
 
				--MESSAGE "Category: ", trim(l_rec_itemsum.cat_code)
				--MESSAGE "Part Code: ", trim(l_rec_itemsum.part_code) 

				IF ((l_rec_itemsum.line_total_amt <> 0) OR (l_nilval = "Y" AND 
				l_rec_itemsum.line_total_amt = 0)) THEN 
					IF l_rec_itemsum.level_code IS NULL OR 
					l_rec_itemsum.level_code = " " 
					THEN 
						DECLARE ordcurs2 CURSOR FOR 
						SELECT level_ind 
						INTO l_rec_itemsum.level_code 
						FROM orderdetl 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
						cust_code = l_rec_itemsum.cust_code AND 
						order_num = l_rec_itemsum.order_num AND 
						part_code = l_rec_itemsum.part_code 
						OPEN ordcurs2 
						FETCH ordcurs2 
						CLOSE ordcurs2 
					END IF 

					INSERT INTO itemsum VALUES (l_rec_itemsum.*) 
				END IF 

			END IF 

		END FOREACH 

		CLEAR screen 
--		MESSAGE "Creating index...." 

		CREATE INDEX tmp_item ON itemsum(cat_code, part_code, level_code) 
		DECLARE itemcurs2 CURSOR FOR 
		SELECT cat_code, part_code, level_code, ware_code, sum(ship_qty), 
		sum(line_total_amt) 
		FROM itemsum 
		GROUP BY cat_code, part_code, level_code, ware_code 
		ORDER BY cat_code, part_code, level_code, ware_code 

		CLEAR screen 
--		MESSAGE "Creating Summary Report...."  

		LET modu_sel_cnt = 0 
		LET modu_report_tot1 = 0 
		LET modu_report_tot2 = 0 

		FOREACH itemcurs2 INTO l_rec_itemsum2.* 
			LET modu_sel_cnt = modu_sel_cnt + 1 
--			MESSAGE "Category: ", trim(l_rec_itemsum2.cat_code) 
--			MESSAGE "Part Code: ", trim(l_rec_itemsum2.part_code)
			LET l_rec_itemsum2.one_perc = (0.01 * l_rec_itemsum2.line_total_amt) 
			#---------------------------------------------------------
			OUTPUT TO REPORT AEF_rpt_list_summary(l_rpt_idx,l_rec_itemsum2.*,l_rec_fiscal_period_range.*,l_nilval,l_part_level)  
			IF NOT rpt_int_flag_handler2("Item:",l_rec_itemsum2.cat_code,l_rec_itemsum2.part_code,l_rpt_idx) THEN
				EXIT FOREACH 
			END IF 
			#---------------------------------------------------------

		END FOREACH 

		CLOSE itemcurs2 
		DROP INDEX tmp_item 

	END IF 
	
	#Finish Summary report (if exists)
	IF rpt_rmsreps_idx_funcname_exists(UI_OFF,"AEF_rpt_list_summary") THEN
		#------------------------------------------------------------
		FINISH REPORT AEF_rpt_list_summary
		CALL rpt_finish("AEF_rpt_list_summary")
		#------------------------------------------------------------
		 
		IF int_flag THEN 
			LET int_flag = false 
			ERROR " Printing was aborted" 
			RETURN false 
		ELSE 
			RETURN true 
		END IF 	
	END IF
	
	#Finish Detailed report (if exists)
	IF rpt_rmsreps_idx_funcname_exists(UI_OFF,"AEF_rpt_list_detailed") THEN
		#------------------------------------------------------------
		FINISH REPORT AEF_rpt_list_detailed
		CALL rpt_finish("AEF_rpt_list_detailed")
		#------------------------------------------------------------
		 
		IF int_flag THEN 
			LET int_flag = false 
			ERROR " Printing was aborted" 
			RETURN false 
		ELSE 
			RETURN true 
		END IF 	
	END IF
	
	
END FUNCTION 
###########################################################################
# END FUNCTION AEF_rpt_process() 
###########################################################################


###########################################################################
# FUNCTION check_status( p_part_code, p_part_level, p_ware_code, p_inv_num, p_line_num)
#
#
###########################################################################
FUNCTION check_status(p_part_code, p_part_level, p_ware_code, p_inv_num, p_line_num) 
	DEFINE p_part_code LIKE product.part_code
	DEFINE p_part_level CHAR(1)
	DEFINE p_ware_code LIKE invoicedetl.ware_code
	DEFINE p_inv_num LIKE invoicedetl.inv_num 
	DEFINE p_line_num LIKE invoicedetl.line_num 
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.*
	DEFINE l_return CHAR(1) 

	IF p_part_level IS NOT NULL THEN 
		INITIALIZE l_rec_prodstatus.* TO NULL 
		SELECT price1_amt, price2_amt, price3_amt, price4_amt, price5_amt, 
		price6_amt, price7_amt, price8_amt, price9_amt 
		INTO l_rec_prodstatus.price1_amt, l_rec_prodstatus.price2_amt, 
		l_rec_prodstatus.price3_amt, l_rec_prodstatus.price4_amt, 
		l_rec_prodstatus.price5_amt, l_rec_prodstatus.price6_amt, 
		l_rec_prodstatus.price7_amt, l_rec_prodstatus.price8_amt, 
		l_rec_prodstatus.price9_amt 
		FROM invdetl_price 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND inv_num = p_inv_num 
		AND line_num = p_line_num 

		IF status = NOTFOUND THEN 
			SELECT prodstatus.* 
			INTO l_rec_prodstatus.* 
			FROM prodstatus 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = p_part_code 
			AND ware_code = p_ware_code 
		END IF 

		CASE 
			WHEN p_part_level = "1" 
				IF l_rec_prodstatus.price1_amt > 0.00 THEN 
					LET l_return = "Y" 
				END IF 
			WHEN p_part_level = "2" 
				IF l_rec_prodstatus.price2_amt > 0.00 THEN 
					LET l_return = "Y" 
				END IF 
			WHEN p_part_level = RPT_OP_CONSTRUCT 
				IF l_rec_prodstatus.price3_amt > 0.00 THEN 
					LET l_return = "Y" 
				END IF 
			WHEN p_part_level = "4" 
				IF l_rec_prodstatus.price4_amt > 0.00 THEN 
					LET l_return = "Y" 
				END IF 
			WHEN p_part_level = "5" 
				IF l_rec_prodstatus.price5_amt > 0.00 THEN 
					LET l_return = "Y" 
				END IF 
			WHEN p_part_level = "6" 
				IF l_rec_prodstatus.price6_amt > 0.00 THEN 
					LET l_return = "Y" 
				END IF 
			WHEN p_part_level = "7" 
				IF l_rec_prodstatus.price7_amt > 0.00 THEN 
					LET l_return = "Y" 
				END IF 
			WHEN p_part_level = "8" 
				IF l_rec_prodstatus.price8_amt > 0.00 THEN 
					LET l_return = "Y" 
				END IF 
			WHEN p_part_level = "9" 
				IF l_rec_prodstatus.price9_amt > 0.00 THEN 
					LET l_return = "Y" 
				END IF 
			OTHERWISE 
				LET l_return = "N" 

		END CASE 

	ELSE 
		LET l_return = "Y" 
	END IF 

	RETURN l_return 
END FUNCTION 
###########################################################################
# END FUNCTION check_status( p_part_code, p_part_level, p_ware_code, p_inv_num, p_line_num)
###########################################################################


###########################################################################
# REPORT AEF_rpt_list_detailed(p_rpt_idx,p_rec_itemsum,p_rec_fiscal_period_range)  
#
#
###########################################################################
REPORT AEF_rpt_list_detailed(p_rpt_idx,p_rec_itemsum,p_rec_fiscal_period_range,p_nilval,p_part_level) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_fiscal_period_range RECORD
		year_num1 LIKE period.year_num, #glob_rec_rpt_selector.ref1_num
		period_num1 LIKE period.period_num, #glob_rec_rpt_selector.ref3_code
		year_num2 LIKE period.year_num, #glob_rec_rpt_selector.ref2_num
		period_num2 LIKE period.period_num #glob_rec_rpt_selector.ref4_code
	END RECORD
	DEFINE p_rec_itemsum RECORD 
		cat_code LIKE invoicedetl.cat_code, 
		part_code LIKE invoicedetl.part_code, 
		level_code LIKE invoicedetl.level_code, 
		ware_code LIKE prodstatus.ware_code, 
		ship_qty LIKE invoicedetl.ship_qty, 
		line_total_amt LIKE invoicedetl.line_total_amt, 
		one_perc LIKE invoicedetl.line_total_amt 
	END RECORD 
	DEFINE p_nilval CHAR(1)
	DEFINE p_part_level LIKE invoicedetl.level_code #glob_rec_rpt_selector.ref2_code

	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.*
	DEFINE l_gm_prod_total LIKE invoicedetl.line_total_amt
	DEFINE l_unit_sell_price LIKE prodstatus.list_amt
	DEFINE l_gross_margin LIKE prodstatus.list_amt
	DEFINE l_name_text LIKE vendor.name_text 
	DEFINE l_desc_text LIKE product.desc_text 

	OUTPUT 
	left margin 1 
	ORDER external BY p_rec_itemsum.part_code, p_rec_itemsum.level_code 
	
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2]
			 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 
			
			PRINT COLUMN 01, "Product", 
			COLUMN 18, "Product", 
			COLUMN 59, "Sale", 
			COLUMN 67, "Quantity", 
			COLUMN 79, "Stand Unit", 
			COLUMN 97, "Total", 
			COLUMN 107, "Standard", 
			COLUMN 128, "Gross" 
			PRINT COLUMN 01, "Code", 
			COLUMN 18, "Description", 
			COLUMN 59, "Type", 
			COLUMN 69, "Sold", 
			COLUMN 79, "Sell Price", 
			COLUMN 97, "Sales", 
			COLUMN 106, "Unit Cost", 
			COLUMN 127, "Margin" 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3  

		BEFORE GROUP OF p_rec_itemsum.part_code 
			LET l_gm_prod_total = 0 
			SELECT desc_text INTO l_desc_text FROM product 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
			part_code = p_rec_itemsum.part_code 
			PRINT COLUMN 01, p_rec_itemsum.part_code, 
			COLUMN 18, l_desc_text; 

		ON EVERY ROW 
			SELECT * INTO l_rec_prodstatus.* FROM prodstatus 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND ware_code = p_rec_itemsum.ware_code 
			AND part_code = p_rec_itemsum.part_code 
			CASE p_rec_itemsum.level_code 
				WHEN "L" LET l_unit_sell_price = l_rec_prodstatus.list_amt 
				WHEN "1" LET l_unit_sell_price = l_rec_prodstatus.price1_amt 
				WHEN "2" LET l_unit_sell_price = l_rec_prodstatus.price2_amt 
				WHEN "3" LET l_unit_sell_price = l_rec_prodstatus.price3_amt 
				WHEN "4" LET l_unit_sell_price = l_rec_prodstatus.price4_amt 
				WHEN "5" LET l_unit_sell_price = l_rec_prodstatus.price5_amt 
				WHEN "6" LET l_unit_sell_price = l_rec_prodstatus.price6_amt 
				WHEN "7" LET l_unit_sell_price = l_rec_prodstatus.price7_amt 
				WHEN "8" LET l_unit_sell_price = l_rec_prodstatus.price8_amt 
				WHEN "9" LET l_unit_sell_price = l_rec_prodstatus.price9_amt 
				WHEN "C" LET l_unit_sell_price = l_rec_prodstatus.wgted_cost_amt 
			END CASE 
			LET l_gross_margin = (p_rec_itemsum.line_total_amt 
			- (p_rec_itemsum.ship_qty * l_rec_prodstatus.est_cost_amt)) 
			PRINT COLUMN 59, p_rec_itemsum.level_code, 
			COLUMN 66, p_rec_itemsum.ship_qty USING "######&.&", 
			COLUMN 77, l_unit_sell_price USING "-----,--&.&&", 
			COLUMN 90, p_rec_itemsum.line_total_amt USING "-----,--&.&&", 
			COLUMN 103, l_rec_prodstatus.est_cost_amt USING "-----,--&.&&", 
			COLUMN 121, l_gross_margin USING "-----,--&.&&" 
			LET modu_report_tot1 = modu_report_tot1 + p_rec_itemsum.line_total_amt 
			LET l_gm_prod_total = l_gm_prod_total + l_gross_margin 
			LET modu_report_tot2 = modu_report_tot2 + l_gross_margin 

		AFTER GROUP OF p_rec_itemsum.part_code 
			IF modu_sel_cnt > 0 THEN 
				PRINT COLUMN 66, "---------", 
				COLUMN 90, "------------", 
				COLUMN 121, "------------" 
				PRINT COLUMN 1, 
				"Product Sales Total.................................", 
				COLUMN 66, GROUP sum(p_rec_itemsum.ship_qty) USING "#######.#", 
				COLUMN 90, GROUP sum(p_rec_itemsum.line_total_amt) 
				USING "-----,--&.&&", 
				COLUMN 121, l_gm_prod_total USING "-----,--&.&&" 
				SKIP 1 LINES 
			ELSE 
			
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #was l_arr_line[2]
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #was l_arr_line[3]
				 
				SKIP 4 LINES 
				PRINT COLUMN 1, "No records satisfied your selection criteria" 
				SKIP 4 LINES 
			END IF 

		ON LAST ROW 
			SKIP 02 LINES 
			PRINT COLUMN 90, "------------", 
			COLUMN 121, "------------" 
			PRINT COLUMN 050, 'report totals', 
			COLUMN 090, modu_report_tot1 USING "-----,--&.&&", 
			COLUMN 121, modu_report_tot2 USING "-----,--&.&&" 
			PRINT COLUMN 90, "------------", 
			COLUMN 121, "------------"
			PRINT 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100
				
			 
			
				PRINT COLUMN 8, "Report used the following selection criteria:" 
				SKIP 2 LINES 
				IF modu_rep_type = "S" THEN 
					PRINT COLUMN 10, "Starting Year : ", p_rec_fiscal_period_range.year_num1 
					PRINT COLUMN 10, "Starting Period: ", p_rec_fiscal_period_range.period_num1 
					PRINT COLUMN 10, "Ending Year : ", p_rec_fiscal_period_range.year_num2 
					PRINT COLUMN 10, "Ending Period : ", p_rec_fiscal_period_range.period_num2 
				END IF 
				
				PRINT COLUMN 10, "Include nil VALUES : ", p_nilval 
				PRINT 
	
				PRINT COLUMN 10, "WHERE:-" 
				SKIP 1 LINES 
				IF p_part_level IS NOT NULL THEN
					PRINT COLUMN 10, "Product Part Level=", p_part_level
{				 
					LET modu_where_part = modu_where_part clipped, ' ', 'and product price level = ', 
					p_part_level 
				END IF 
				LET modu_len = length (modu_where_part) 
				FOR modu_s = 1 TO 1121 step 60 
					IF modu_len > modu_s THEN 
						PRINT COLUMN 10, "|", modu_where_part [modu_s, modu_s + 59], "|" 
					ELSE 
						LET modu_s = 32000 
					END IF 
				END FOR 
				# the last line doesnt have 60 characters of modu_where_part TO display
				IF modu_len > 1181 THEN 
					PRINT COLUMN 10, "|", modu_where_part [1181, 1200], "|" 
				END IF 
}	
				END IF
				SKIP 1 line 
			END IF
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 			
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4]
END REPORT 
###########################################################################
# END REPORT AEF_rpt_list_detailed(p_rpt_idx,p_rec_itemsum,p_rec_fiscal_period_range)  
###########################################################################


###########################################################################
# REPORT AEF_rpt_list_summary(p_rpt_idx,p_rec_itemsum,p_rec_fiscal_period_range)
#
#
###########################################################################
REPORT AEF_rpt_list_summary(p_rpt_idx,p_rec_itemsum,p_rec_fiscal_period_range,p_nilval,p_part_level)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx] 
	DEFINE p_rec_itemsum RECORD 
		cat_code LIKE invoicedetl.cat_code, 
		part_code LIKE invoicedetl.part_code, 
		level_code LIKE invoicedetl.level_code, 
		ware_code LIKE prodstatus.ware_code, 
		ship_qty LIKE invoicedetl.ship_qty, 
		line_total_amt LIKE invoicedetl.line_total_amt, 
		one_perc LIKE invoicedetl.line_total_amt 
	END RECORD 
	DEFINE p_rec_fiscal_period_range RECORD
		year_num1 LIKE period.year_num,
		period_num1 LIKE period.period_num,
		year_num2 LIKE period.year_num,
		period_num2 LIKE period.period_num 
	END RECORD
	DEFINE p_nilval CHAR(1)
	DEFINE p_part_level LIKE invoicedetl.level_code #glob_rec_rpt_selector.ref2_code

	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.*
	DEFINE l_gm_prod_total LIKE invoicedetl.line_total_amt
	DEFINE l_unit_sell_price LIKE prodstatus.list_amt
	DEFINE l_gross_margin LIKE prodstatus.list_amt 
	DEFINE l_name_text LIKE vendor.name_text 
	DEFINE l_desc_text LIKE product.desc_text 

	OUTPUT 
--	left margin 1 

	ORDER external BY p_rec_itemsum.cat_code, 
	p_rec_itemsum.part_code, 
	p_rec_itemsum.level_code 
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2]

			
			 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 01, "Product", 
			COLUMN 18, "Product", 
			COLUMN 59, "Sale", 
			COLUMN 67, "Quantity", 
			COLUMN 79, "Stand Unit", 
			COLUMN 97, "Total", 
			COLUMN 107, "Standard", 
			COLUMN 128, "Gross" 
			PRINT COLUMN 01, "Code", 
			COLUMN 18, "Description", 
			COLUMN 59, "Type", 
			COLUMN 69, "Sold", 
			COLUMN 79, "Sell Price", 
			COLUMN 97, "Sales", 
			COLUMN 106, "Unit Cost", 
			COLUMN 127, "Margin" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		BEFORE GROUP OF p_rec_itemsum.cat_code 
			LET l_gm_prod_total = 0 
			IF modu_pagebr = "Y" THEN 
				SKIP TO top OF PAGE 
			END IF 
			SELECT name_text INTO l_name_text 
			FROM vendor 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
			vend_code = p_rec_itemsum.cat_code 
			PRINT COLUMN 01, "Supplier: ", p_rec_itemsum.cat_code, 
			COLUMN 20, l_name_text 
			PRINT COLUMN 01, "--------" 
			SKIP 1 line 

		BEFORE GROUP OF p_rec_itemsum.part_code 
			SELECT desc_text INTO l_desc_text FROM product 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = p_rec_itemsum.part_code 
			PRINT COLUMN 01, p_rec_itemsum.part_code, 
			COLUMN 18, l_desc_text; 

		ON EVERY ROW 
			SELECT * INTO l_rec_prodstatus.* FROM prodstatus 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND ware_code = p_rec_itemsum.ware_code 
			AND part_code = p_rec_itemsum.part_code 
			CASE p_rec_itemsum.level_code 
				WHEN "L" LET l_unit_sell_price = l_rec_prodstatus.list_amt 
				WHEN "1" LET l_unit_sell_price = l_rec_prodstatus.price1_amt 
				WHEN "2" LET l_unit_sell_price = l_rec_prodstatus.price2_amt 
				WHEN "3" LET l_unit_sell_price = l_rec_prodstatus.price3_amt 
				WHEN "4" LET l_unit_sell_price = l_rec_prodstatus.price4_amt 
				WHEN "5" LET l_unit_sell_price = l_rec_prodstatus.price5_amt 
				WHEN "6" LET l_unit_sell_price = l_rec_prodstatus.price6_amt 
				WHEN "7" LET l_unit_sell_price = l_rec_prodstatus.price7_amt 
				WHEN "8" LET l_unit_sell_price = l_rec_prodstatus.price8_amt 
				WHEN "9" LET l_unit_sell_price = l_rec_prodstatus.price9_amt 
				WHEN "C" LET l_unit_sell_price = l_rec_prodstatus.wgted_cost_amt 
			END CASE 
			LET l_gross_margin = (p_rec_itemsum.line_total_amt - (p_rec_itemsum.ship_qty * l_rec_prodstatus.est_cost_amt)) 
			PRINT COLUMN 59, p_rec_itemsum.level_code, 
			COLUMN 66, p_rec_itemsum.ship_qty USING "######&.&", 
			COLUMN 77, l_unit_sell_price USING "-----,--&.&&", 
			COLUMN 90, p_rec_itemsum.line_total_amt USING "-----,--&.&&", 
			COLUMN 103, l_rec_prodstatus.est_cost_amt USING "-----,--&.&&", 
			COLUMN 121, l_gross_margin USING "-----,--&.&&" 
			LET modu_report_tot1 = modu_report_tot1 + p_rec_itemsum.line_total_amt 
			LET l_gm_prod_total = l_gm_prod_total + l_gross_margin 
			LET modu_report_tot2 = modu_report_tot2 + l_gross_margin 

		AFTER GROUP OF p_rec_itemsum.cat_code 
			IF modu_sel_cnt > 0 
			THEN 
				PRINT COLUMN 66, "---------", 
				COLUMN 90, "------------", 
				COLUMN 121, "------------" 
				PRINT COLUMN 1, 
				"Supplier Total.................................", 
				COLUMN 66, GROUP sum(p_rec_itemsum.ship_qty) 
				USING "######&.&", 
				COLUMN 90, GROUP sum(p_rec_itemsum.line_total_amt) 
				USING "-----,--&.&&", 
				COLUMN 121, l_gm_prod_total USING "-----,--&.&&" 
				SKIP 1 LINES 
			ELSE 
			
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #was l_arr_line[2]
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #was l_arr_line[3]
				
				
				 
				SKIP 4 LINES 
				PRINT COLUMN 1, "No records satisfied your selection criteria" 
				SKIP 4 LINES 
			END IF 

		ON LAST ROW 
			SKIP 02 LINES 
			PRINT COLUMN 90, "------------", 
			COLUMN 121, "------------" 
			PRINT COLUMN 050, 'report totals', 
			COLUMN 90, modu_report_tot1 USING "-----,--&.&&", 
			COLUMN 121, modu_report_tot2 USING "-----,--&.&&" 
			PRINT COLUMN 90, "------------", 
			COLUMN 121, "------------" 
			SKIP 01 LINES 
			PRINT COLUMN 8, "Report used the following selection criteria:" 
			SKIP 2 LINES 
			IF modu_rep_type = "S" THEN 
				PRINT COLUMN 10, "Starting Year : ", p_rec_fiscal_period_range.year_num1 
				PRINT COLUMN 10, "Starting Period: ", p_rec_fiscal_period_range.period_num1 
				PRINT COLUMN 10, "Ending Year : ", p_rec_fiscal_period_range.year_num2 
				PRINT COLUMN 10, "Ending Period : ", p_rec_fiscal_period_range.period_num2 
			END IF 
			PRINT 
			PRINT COLUMN 10, "Include nil VALUES : ", p_nilval 

			PRINT COLUMN 10, "WHERE:-" 
			SKIP 1 LINES 
			IF p_part_level IS NOT NULL AND modu_rep_type != "B" THEN #NOT Both
				PRINT COLUMN 10, "Product Part Level=", p_part_level
				--LET modu_where_part = modu_where_part clipped, ' ', 'and product price level = ',	p_part_level 
			END IF 
			{
			LET modu_len = length (modu_where_part) 
			FOR modu_s = 1 TO 1121 step 60 
				IF modu_len > modu_s THEN 
					PRINT COLUMN 10, "|", modu_where_part [modu_s, modu_s + 59], "|" 
				ELSE 
					LET modu_s = 32000 
				END IF 
			END FOR 
			
			# the last line doesnt have 60 characters of modu_where_part TO display
			IF modu_len > 1181 THEN 
				PRINT COLUMN 10, "|", modu_where_part [1181, 1200], "|" 
			END IF 
}
			SKIP 1 line 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 			
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4]
END REPORT
###########################################################################
# END REPORT AEF_rpt_list_summary(p_rpt_idx,p_rec_itemsum,p_rec_fiscal_period_range)
###########################################################################