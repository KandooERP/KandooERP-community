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
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl"
GLOBALS "../ar/AD_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/ADR_GLOBALS.4gl" 
#####################################################################
# FUNCTION ADR_main()
#
# ADR - Credit Listing - REPORT which shows Credits by Credit Reason
#####################################################################
FUNCTION ADR_main() 
	DEFER interrupt 
	DEFER quit
	
	CALL setModuleId("ADR") 
	CALL ui_init(0) #Initial UI Init
	CALL authenticate(getmoduleid()) 
	CALL init_a_ar() #init a/ar module 


	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 	
			OPEN WINDOW A653 with FORM "A653" 
			CALL windecoration_a("A653")
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
		
			MENU " Credit Listing" 
		
				BEFORE MENU 
					CALL publish_toolbar("kandoo","ADR","menu-credit-listing") 
					#CALL ADR_rpt_process(ADR_rpt_query())
					
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				ON ACTION "REPORT_DETAILED" #  COMMAND KEY ("D",f20) "Detail" " SELECT criteria AND PRINT detailed REPORT"
					LET glob_mode = "DET" 
					CALL ADR_rpt_process(ADR_rpt_query())
		
				ON ACTION "REPORT_SUMMARY" #COMMAND "Summary" " SELECT criteria AND PRINT summary REPORT"
					LET glob_mode = "SUM" 
					CALL ADR_rpt_process(ADR_rpt_query())
		
				ON ACTION "Print Manager" #COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "Exit" #COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus"
					EXIT MENU 
		
			END MENU 
		
			CLOSE WINDOW A653 
	 
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL ADR_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW A653 with FORM "A653" 
			CALL windecoration_a("A653") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(ADR_rpt_query()) #save where clause in env 
			CLOSE WINDOW A653 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL ADR_rpt_process(get_url_sel_text())
	END CASE	
END FUNCTION 



#####################################################################
# FUNCTION ADR_rpt_query()
#
#
#####################################################################
FUNCTION ADR_rpt_query() 
	DEFINE l_where_text STRING
	DEFINE l_rec_credithead RECORD 
		reason_code LIKE creditdetl.reason_code, 
		cust_code LIKE customer.cust_code, 
		line_num LIKE creditdetl.line_num, 
		cred_num LIKE credithead.cred_num, 
		cred_date LIKE credithead.cred_date, 
		year_num LIKE credithead.year_num, 
		period_num LIKE credithead.period_num, 
		part_code LIKE creditdetl.part_code, 
		ship_qty LIKE creditdetl.ship_qty, 
		line_text LIKE creditdetl.line_text, 
		uom_code LIKE creditdetl.uom_code, 
		unit_sales_amt LIKE creditdetl.unit_sales_amt, 
		ext_sales_amt LIKE creditdetl.ext_sales_amt, 
		com1_text LIKE credithead.com1_text, 
		com2_text LIKE credithead.com2_text 
	END RECORD 


	CLEAR FORM 

	MESSAGE kandoomsg2("W",1001,"") 
	#1001 " Enter criteria FOR selection - ESC TO begin search"
	CONSTRUCT BY NAME l_where_text ON creditdetl.cred_num, 
	creditdetl.reason_code, 
	creditdetl.cust_code, 
	customer.name_text, 
	credithead.cred_date, 
	credithead.entry_date, 
	credithead.territory_code, 
	customer.currency_code, 
	creditdetl.unit_sales_amt, 
	credithead.cred_ind, 
	credithead.year_num, 
	credithead.period_num, 
	creditdetl.ware_code, 
	creditdetl.part_code, 
	creditdetl.ship_qty, 
	creditdetl.line_text, 
	creditdetl.ext_sales_amt 


		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","ADR","construct-creditdetl") 

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

#####################################################################
# FUNCTION ADR_rpt_process(p_where_text) 
#
#
#####################################################################
FUNCTION ADR_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT  
	DEFINE l_rec_credithead RECORD 
		reason_code LIKE creditdetl.reason_code, 
		cust_code LIKE customer.cust_code, 
		line_num LIKE creditdetl.line_num, 
		cred_num LIKE credithead.cred_num, 
		cred_date LIKE credithead.cred_date, 
		year_num LIKE credithead.year_num, 
		period_num LIKE credithead.period_num, 
		part_code LIKE creditdetl.part_code, 
		ship_qty LIKE creditdetl.ship_qty, 
		line_text LIKE creditdetl.line_text, 
		uom_code LIKE creditdetl.uom_code, 
		unit_sales_amt LIKE creditdetl.unit_sales_amt, 
		ext_sales_amt LIKE creditdetl.ext_sales_amt, 
		com1_text LIKE credithead.com1_text, 
		com2_text LIKE credithead.com2_text 
	END RECORD 
	
	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	#NOTE: 2 different reports depending on glob_mode
	#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

	IF glob_mode = "DET" THEN 
		#**********************************	
		LET l_rpt_idx = rpt_start("ADR-DET","ADR_rpt_list_credit_1",p_where_text, RPT_SHOW_RMS_DIALOG)
		IF l_rpt_idx = 0 THEN #User pressed CANCEL
			RETURN FALSE
		END IF
		IF glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ADR_rpt_list_credit_1")].report_text IS NULL THEN 
			IF glob_mode = "DET" THEN 
				CALL rpt_set_header_footer_line_2_append(rpt_rmsreps_idx_get_idx("ADR_rpt_list_credit_1"),NULL, "(Detailed)")
				LET glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_text = "Credits by Credit Reason (Detailed)"
			END IF 
		END IF			
		START REPORT ADR_rpt_list_credit_1 TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
		#**********************************
	ELSE #SUM
		#**********************************	
		LET l_rpt_idx = rpt_start("ADR-SUM","ADR_rpt_list_credit_2",p_where_text, RPT_SHOW_RMS_DIALOG)
		IF l_rpt_idx = 0 THEN #User pressed CANCEL
			RETURN FALSE
		END IF	
		IF glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ADR_rpt_list_credit_2")].report_text IS NULL THEN 
			IF glob_mode = "SUM" THEN 
				CALL rpt_set_header_footer_line_2_append(rpt_rmsreps_idx_get_idx("ADR_rpt_list_credit_2"),NULL, "(Detailed)")
				LET glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_text = "Credits by Credit Reason (Detailed)"
			END IF 
		END IF	
		START REPORT ADR_rpt_list_credit_2 TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
		#**********************************

	END IF 
		

	#------------------------------------------------------------
	
	LET l_query_text = "SELECT creditdetl.reason_code,", 
	"customer.cust_code,", 
	"creditdetl.line_num,", 
	"creditdetl.cred_num,", 
	"credithead.cred_date,", 
	"credithead.year_num,", 
	"credithead.period_num,", 
	"creditdetl.part_code,", 
	"creditdetl.ship_qty,", 
	"creditdetl.line_text,", 
	"creditdetl.uom_code,", 
	"creditdetl.unit_sales_amt,", 
	"creditdetl.ext_sales_amt, ", 
	"credithead.com1_text, ", 
	"credithead.com2_text ", 
	"FROM customer,creditdetl,credithead ", 
	"WHERE creditdetl.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND customer.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND credithead.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND creditdetl.cust_code = customer.cust_code ", 
	"AND credithead.cred_num = creditdetl.cred_num "

	IF glob_mode = "DET" THEN
		LET l_query_text = trim(l_query_text),	" AND ", glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ADR_rpt_list_credit_1")].sel_text clipped," "
	END IF	
	IF glob_mode = "SUM" THEN
		LET l_query_text = trim(l_query_text),	" AND ", glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ADR_rpt_list_credit_2")].sel_text clipped," "
	END IF	
	
	LET l_query_text = trim(l_query_text), " ",	 
	"ORDER BY creditdetl.reason_code,customer.cust_code,", 
	"creditdetl.cred_num,creditdetl.line_num" 

	PREPARE s_credithead FROM l_query_text 
	DECLARE c_credithead CURSOR FOR s_credithead

	#------------------------------------------------------------
	
	--LET l_msgresp=kandoomsg("U",1506,"") 
	-- #1506 Searching Database Please Stand By"
	#CALL displayStatus("Reporting on Customer:")
	#DISPLAY "" AT 1,2
	#DISPLAY "Reporting on Customer: " AT 1,2
	MESSAGE "Reporting on Customer" 

	FOREACH c_credithead INTO l_rec_credithead.* 
		DISPLAY l_rec_credithead.cust_code at 1,25 

	#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	#NOTE: 2 different reports depending on glob_mode
	#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

		#**********************************	
		IF glob_mode = "DET" THEN 
			#---------------------------------------------------------
			OUTPUT TO REPORT ADR_rpt_list_credit_1(l_rpt_idx,l_rec_credithead.*)  
			#---------------------------------------------------------				
		ELSE 
			#---------------------------------------------------------
			OUTPUT TO REPORT ADR_rpt_list_credit_2(l_rpt_idx,l_rec_credithead.*)  
			#---------------------------------------------------------				
		END IF 
		IF NOT rpt_int_flag_handler2("Receipt:",l_rec_credithead.cust_code, l_rec_credithead.reason_code,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 

	END FOREACH 

	#------------------------------------------------------------
	IF glob_mode = "DET" THEN 
		FINISH REPORT ADR_rpt_list_credit_1
		CALL rpt_finish("ADR_rpt_list_credit_1") 
	ELSE 
		FINISH REPORT ADR_rpt_list_credit_2 
		CALL rpt_finish("ADR_rpt_list_credit_2")		
	END IF 
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 


#####################################################################
# REPORT ADR_rpt_list_credit_1(p_rpt_idx,p_rec_credithead) 
# glob_mode = "DET"
#
#####################################################################
REPORT ADR_rpt_list_credit_1(p_rpt_idx,p_rec_credithead) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_credithead RECORD 
		reason_code LIKE creditdetl.reason_code, 
		cust_code LIKE customer.cust_code, 
		line_num LIKE creditdetl.line_num, 
		cred_num LIKE credithead.cred_num, 
		cred_date LIKE credithead.cred_date, 
		year_num LIKE credithead.year_num, 
		period_num LIKE credithead.period_num, 
		part_code LIKE creditdetl.part_code, 
		ship_qty LIKE creditdetl.ship_qty, 
		line_text LIKE creditdetl.line_text, 
		uom_code LIKE creditdetl.uom_code, 
		unit_sales_amt LIKE creditdetl.unit_sales_amt, 
		ext_sales_amt LIKE creditdetl.ext_sales_amt, 
		com1_text LIKE credithead.com1_text, 
		com2_text LIKE credithead.com2_text 
	END RECORD 
--	DEFINE l_line1 CHAR(80) 
--	DEFINE l_offset1 SMALLINT 
--	DEFINE l_offset3 SMALLINT 
	DEFINE l_rec_credreas RECORD LIKE credreas.* 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	
	OUTPUT 
--	left margin 1 
	ORDER external BY p_rec_credithead.reason_code, 
	p_rec_credithead.cust_code, 
	p_rec_credithead.cred_num, 
	p_rec_credithead.line_num 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  
			 
			PRINT COLUMN 09, "Line", 
			COLUMN 18, "Product", 
			COLUMN 32, "Credited", 
			COLUMN 41, "Description", 
			COLUMN 73, "Unit", 
			COLUMN 80, "Unit Price", 
			COLUMN 98, "Extended" 
			
			PRINT COLUMN 10, "No.", 
			COLUMN 20, "ID", 
			COLUMN 34, "Qty", 
			COLUMN 101, "Price"
			 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		BEFORE GROUP OF p_rec_credithead.reason_code 
			SKIP TO top OF PAGE 
			INITIALIZE l_rec_credreas.* TO NULL 
			SELECT * INTO l_rec_credreas.* FROM credreas 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND reason_code = p_rec_credithead.reason_code 
			IF status = NOTFOUND THEN 
				LET l_rec_credreas.reason_text = "CREDIT REASON NOT ON FILE" 
			END IF 
			PRINT COLUMN 01, "Reason: ", 
			COLUMN 09, p_rec_credithead.reason_code, 
			COLUMN 13, l_rec_credreas.reason_text 
			SKIP 1 line 

		BEFORE GROUP OF p_rec_credithead.cust_code 
			INITIALIZE l_rec_customer.* TO NULL 
			CALL db_customer_get_rec(UI_OFF,p_rec_credithead.cust_code) RETURNING l_rec_customer.*
--			SELECT * INTO l_rec_customer.* FROM customer 
--			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
--			AND cust_code = p_rec_credithead.cust_code 
			PRINT COLUMN 05, "Customer: ", 
			COLUMN 15, p_rec_credithead.cust_code, 
			COLUMN 23, l_rec_customer.name_text, 
			COLUMN 54, "Currency:", 
			COLUMN 64, l_rec_customer.currency_code 
			SKIP 1 line 

		BEFORE GROUP OF p_rec_credithead.cred_num 
			PRINT COLUMN 07,"Credit:", 
			COLUMN 15,p_rec_credithead.cred_num USING "########", 
			COLUMN 25,"Date: ", 
			COLUMN 31,p_rec_credithead.cred_date USING "dd/mm/yyyy", 
			COLUMN 43,"Year/Per:", 
			COLUMN 53,p_rec_credithead.year_num USING "####", 
			COLUMN 57,"/", 
			COLUMN 58,p_rec_credithead.period_num USING "&#"; 
			IF p_rec_credithead.com1_text IS NULL 
			AND p_rec_credithead.com2_text IS NULL THEN 
				PRINT COLUMN 61, " " 
			ELSE 
				PRINT COLUMN 61,"Comments: ", 
				COLUMN 71,p_rec_credithead.com1_text," ",p_rec_credithead.com2_text 
			END IF 

		ON EVERY ROW 
			PRINT COLUMN 11, p_rec_credithead.line_num USING "##", 
			COLUMN 14, p_rec_credithead.part_code, 
			COLUMN 29, p_rec_credithead.ship_qty USING "----,--&.&&", 
			COLUMN 41, p_rec_credithead.line_text, 
			COLUMN 73, p_rec_credithead.uom_code, 
			COLUMN 81, p_rec_credithead.unit_sales_amt USING "--,--&.&&", 
			COLUMN 95, p_rec_credithead.ext_sales_amt USING "----,--&.&&" 

		AFTER GROUP OF p_rec_credithead.cred_num 
			NEED 2 LINES 
			PRINT COLUMN 93, "-------------" 
			PRINT COLUMN 95, GROUP sum(p_rec_credithead.ext_sales_amt) 
			USING "----,--&.&&" 
			SKIP 2 LINES 

		AFTER GROUP OF p_rec_credithead.cust_code 
			NEED 4 LINES 
			PRINT COLUMN 93, "=============" 
			PRINT COLUMN 05, "Customer Total", 
			COLUMN 95, GROUP sum(p_rec_credithead.ext_sales_amt) 
			USING "----,--&.&&" 
			PRINT COLUMN 93, "=============" 
			SKIP 2 LINES 

		AFTER GROUP OF p_rec_credithead.reason_code 
			NEED 2 LINES 
			PRINT COLUMN 93, "=============" 
			PRINT COLUMN 01, "Reason Total", 
			COLUMN 95, GROUP sum(p_rec_credithead.ext_sales_amt) 
			USING "----,--&.&&" 
		ON LAST ROW 
			SKIP 3 LINES 
			NEED 3 LINES 
			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	
			
END REPORT 


#####################################################################
# REPORT ADR_rpt_list_credit_2(p_rec_credithead)
#
#
#####################################################################
REPORT ADR_rpt_list_credit_2(p_rpt_idx) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_credithead RECORD 
		reason_code LIKE creditdetl.reason_code, 
		cust_code LIKE customer.cust_code, 
		line_num LIKE creditdetl.line_num, 
		cred_num LIKE credithead.cred_num, 
		cred_date LIKE credithead.cred_date, 
		year_num LIKE credithead.year_num, 
		period_num LIKE credithead.period_num, 
		part_code LIKE creditdetl.part_code, 
		ship_qty LIKE creditdetl.ship_qty, 
		line_text LIKE creditdetl.line_text, 
		uom_code LIKE creditdetl.uom_code, 
		unit_sales_amt LIKE creditdetl.unit_sales_amt, 
		ext_sales_amt LIKE creditdetl.ext_sales_amt, 
		com1_text LIKE credithead.com1_text, 
		com2_text LIKE credithead.com2_text 
	END RECORD 
	DEFINE l_rec_credreas RECORD LIKE credreas.*
	DEFINE l_rec_customer RECORD LIKE customer.* 
--	DEFINE l_line1 CHAR(80)
--	DEFINE l_offset1 SMALLINT 
--	DEFINE l_offset3 SMALLINT 

	OUTPUT 
--	left margin 1 
	ORDER external BY p_rec_credithead.reason_code, 
	p_rec_credithead.cust_code, 
	p_rec_credithead.cred_num, 
	p_rec_credithead.line_num 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  

			PRINT COLUMN 16, "Credit", 
			COLUMN 30, "Date", 
			COLUMN 42, "Year/Per", 
			COLUMN 58, "Total", 
			COLUMN 71, "Comments" 
			
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  

		BEFORE GROUP OF p_rec_credithead.reason_code 
			SKIP TO top OF PAGE 
			INITIALIZE l_rec_credreas.* TO NULL 
			SELECT * INTO l_rec_credreas.* FROM credreas 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND reason_code = p_rec_credithead.reason_code 
			IF status = NOTFOUND THEN 
				LET l_rec_credreas.reason_text = "CREDIT REASON NOT ON FILE" 
			END IF 
			PRINT COLUMN 01, "Reason: ", 
			COLUMN 09, p_rec_credithead.reason_code, 
			COLUMN 13, l_rec_credreas.reason_text 
			SKIP 1 line 

		BEFORE GROUP OF p_rec_credithead.cust_code 
			INITIALIZE l_rec_customer.* TO NULL 
			CALL db_customer_get_rec(UI_OFF,p_rec_credithead.cust_code) RETURNING l_rec_customer.*
--			SELECT * INTO l_rec_customer.* FROM customer 
--			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
--			AND cust_code = p_rec_credithead.cust_code 
			PRINT COLUMN 05, "Customer: ", 
			COLUMN 15, p_rec_credithead.cust_code, 
			COLUMN 23, l_rec_customer.name_text, 
			COLUMN 54, "Currency:", 
			COLUMN 64, l_rec_customer.currency_code 
			SKIP 1 line 

		BEFORE GROUP OF p_rec_credithead.cred_num 
			PRINT COLUMN 14,p_rec_credithead.cred_num USING "########", 
			COLUMN 27,p_rec_credithead.cred_date USING "dd/mm/yyyy", 
			COLUMN 43,p_rec_credithead.year_num USING "####","/", 
			p_rec_credithead.period_num USING "&#"; 
		AFTER GROUP OF p_rec_credithead.cred_num 
			PRINT COLUMN 52, GROUP sum(p_rec_credithead.ext_sales_amt) 
			USING "----,--&.&&", 
			COLUMN 71, p_rec_credithead.com1_text," ", 
			p_rec_credithead.com2_text 

		AFTER GROUP OF p_rec_credithead.cust_code 
			NEED 4 LINES 
			PRINT COLUMN 52, "===========" 
			PRINT COLUMN 05, "Customer Total", 
			COLUMN 52, GROUP sum(p_rec_credithead.ext_sales_amt) 
			USING "----,--&.&&" 
			PRINT COLUMN 52, "===========" 
			SKIP 2 LINES 

		AFTER GROUP OF p_rec_credithead.reason_code 
			NEED 2 LINES 
			PRINT COLUMN 52, "===========" 
			PRINT COLUMN 01, "Reason Total", 
			COLUMN 52, GROUP sum(p_rec_credithead.ext_sales_amt) 
			USING "----,--&.&&" 

		ON LAST ROW 
			SKIP 3 LINES 
			NEED 3 LINES 
			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	
			
END REPORT 



