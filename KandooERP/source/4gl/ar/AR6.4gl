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
GLOBALS "../ar/AR_GROUP_GLOBALS.4gl"
GLOBALS "../ar/AR6_GLOBALS.4gl" 
############################################################
# FUNCTION ar6_main())
#
# AR6 Sales Commissions
############################################################
FUNCTION ar6_main() 
	DEFER quit 
	DEFER interrupt
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

	CALL setModuleId("AR6")
	CALL init_report_ar() #report default data from db-arparms
	CALL AR_temp_tables_create()

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 
			OPEN WINDOW A188 with FORM "A188" 
			CALL windecoration_a("A188") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

			MENU "Commission Report" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","AR6","menu-comission-REPORT") 
					CALL AR6_rpt_process(AR6_rpt_query())
					CALL AR_temp_tables_delete()
		
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				ON ACTION "REPORT" #COMMAND "Run REPORT" " SELECT criteria AND PRINT REPORT" 
					CALL AR6_rpt_process(AR6_rpt_query())
					CALL AR_temp_tables_delete()
		
				ON ACTION "Print Manager" #COMMAND "Print" "Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "CANCEL"	#COMMAND "Exit" " Exit TO menu" 
					EXIT MENU 
		
			END MENU 
			CLOSE WINDOW A188 
	 
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL AR6_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW A188 with FORM "A188" 
			CALL windecoration_a("A188") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(AR6_rpt_query()) #save where clause in env 
			CLOSE WINDOW A188 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL AR6_rpt_process(get_url_sel_text())
	END CASE 	

	CALL AR_temp_tables_drop()
END FUNCTION 


############################################################
# FUNCTION AR6_rpt_query()
#
#
############################################################
FUNCTION AR6_rpt_query() 
	DEFINE l_where_text STRING
	DEFINE l_sales_sel CHAR(1) 
	DEFINE l_date_sel CHAR(1) 
	DEFINE l_cust_sel CHAR(1) 
	DEFINE l_vee CHAR(1) 
	DEFINE l_ach CHAR(1) 
	DEFINE l_bsale CHAR(3) 
	DEFINE l_esale CHAR(3) 
	DEFINE l_bdate DATE 
	DEFINE l_edate DATE 
	DEFINE l_bcust CHAR(8) 
	DEFINE l_ecust CHAR(8) 
	DEFINE l_output STRING #report output file name inc. path

	CLEAR screen 

{
	#some base inits
	IF l_sales_sel NOT matches "[AS]" OR l_sales_sel IS NULL THEN
		LET l_sales_sel = "A"
	END IF 
	IF l_date_sel NOT matches "[AS]" OR l_date_sel IS NULL THEN
		LET l_date_sel = "A"
	END IF 
	IF l_cust_sel NOT matches "[AS]" OR l_cust_sel IS NULL THEN
		LET l_cust_sel = "A"
	END IF 
}	
	INPUT 
	l_sales_sel, 
	l_bsale, 
	l_esale, 
	l_date_sel, 
	l_bdate, 
	l_edate, 
	l_cust_sel, 
	l_bcust, 
	l_ecust 
	FROM 
	sales_sel, 
	bsale, 
	esale, 
	date_sel, 
	bdate, 
	edate, 
	cust_sel, 
	bcust, 
	ecust 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","AR6","inp-sales") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
			
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER FIELD sales_sel 
			IF l_sales_sel IS NULL 
			OR l_sales_sel <> "S" THEN 
				LET l_sales_sel = "A" 
				LET l_bsale = " " 
				LET l_esale = "ZZZ" 
				DISPLAY 
				l_sales_sel, 
				l_bsale, 
				l_esale 
				TO 
				sales_sel, 
				bsale, 
				esale 

				NEXT FIELD date_sel 
			END IF 

		AFTER FIELD bsale 
			IF l_bsale IS NULL THEN 
				LET l_bsale = " " 
			END IF 

		AFTER FIELD esale 
			IF l_esale IS NULL THEN 
				LET l_esale = "ZZZ" 
				DISPLAY l_esale TO esale 
			END IF 

		AFTER FIELD date_sel 
			IF l_date_sel IS NULL 
			OR l_date_sel <> "S" THEN 
				LET l_date_sel = "A" 
				LET l_bdate = "31/12/1899" 
				LET l_edate = "31/12/2099" 
				DISPLAY 
				l_date_sel, 
				l_bdate, 
				l_edate 
				TO 
				date_sel, 
				bdate, 
				edate 

				NEXT FIELD cust_sel 
			END IF 

		AFTER FIELD bdate 
			IF l_bdate IS NULL THEN 
				LET l_bdate = "31/12/1899" 
				DISPLAY l_bdate TO bdate 
			END IF 

		AFTER FIELD edate 
			IF l_edate IS NULL THEN 
				LET l_edate = "31/12/2099"				 
				DISPLAY l_edate TO edate 
			END IF 
			IF l_bdate > l_edate THEN 
				ERROR " Beginning date must be <= end" 
				NEXT FIELD bdate 
			END IF 

		AFTER FIELD cust_sel 
			IF l_cust_sel IS NULL 
			OR l_cust_sel <> "S" THEN 
				LET l_cust_sel = "A" 
				LET l_bcust = " " 
				LET l_ecust = "ZZZZZZZZ" 
				DISPLAY 
				l_cust_sel, 
				l_bcust, 
				l_ecust 
				TO 
				cust_sel, 
				bcust, 
				ecust 

			END IF 
			IF l_cust_sel = "A" THEN 
				EXIT INPUT 
			END IF 

		AFTER FIELD bcust 
			IF l_bcust IS NULL THEN 
				LET l_bcust = " " 
			END IF 

		AFTER FIELD ecust 
			IF l_ecust IS NULL THEN 
				LET l_ecust = "ZZZZZZZZ" 
				DISPLAY l_ecust TO ecust
			END IF 

		AFTER INPUT 
			IF l_sales_sel IS NULL 
			OR l_sales_sel <> "S" THEN 
				LET l_sales_sel = "A" 
				LET l_bsale = " " 
				LET l_esale = "ZZZ" 
			END IF

			IF l_date_sel IS NULL 
			OR l_date_sel <> "S" THEN 
				LET l_date_sel = "A" 
				LET l_bdate = "31/12/1899" 
				LET l_edate = "31/12/2099" 
			END IF
			
			IF l_cust_sel IS NULL 
			OR l_cust_sel <> "S" THEN 
				LET l_cust_sel = "A" 
				LET l_bcust = " " 
				LET l_ecust = "ZZZZZZZZ"
			END IF

			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
				EXIT PROGRAM 
			END IF 

	END INPUT 

	LET l_vee = "V" 
	LET l_ach = "H" 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL
	ELSE
		LET glob_rec_rpt_selector.ref1_ind = l_sales_sel 
		LET glob_rec_rpt_selector.ref1_code = l_bsale 
		LET glob_rec_rpt_selector.ref2_code = l_esale 

		LET glob_rec_rpt_selector.ref2_ind = l_date_sel 
		LET glob_rec_rpt_selector.ref1_date = l_bdate 
		LET glob_rec_rpt_selector.ref2_date = l_edate 
	
		LET glob_rec_rpt_selector.ref3_ind = l_cust_sel 
		LET glob_rec_rpt_selector.ref3_code = l_bcust 
		LET glob_rec_rpt_selector.ref4_code = l_ecust
					
		RETURN " 1=1 "
	END IF 	
END FUNCTION


############################################################
# FUNCTION AR6_rpt_process() 
#
#
############################################################
FUNCTION AR6_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT 
	DEFINE l_rec_tempdoc RECORD 
		tm_sale LIKE customer.sale_code, 
		tm_name LIKE salesperson.name_text, 
		tm_cust LIKE customer.cust_code, 
		tm_doc INTEGER, 
		tm_date LIKE customer.setup_date, 
		tm_per SMALLINT, 
		tm_amount money(12,2), 
		tm_paid money(12,2), 
		tm_prof money(12,2), 
		tm_comm money(12,2) 
	END RECORD 

	DEFINE l_rec_invoicehead RECORD 
		cust_code LIKE invoicehead.cust_code, 
		sale_code LIKE invoicehead.sale_code, 
		name_text LIKE salesperson.name_text, 
		comm_per LIKE salesperson.comm_per, 
		inv_num LIKE invoicehead.inv_num, 
		inv_date LIKE invoicehead.inv_date, 
		total_amt LIKE invoicehead.total_amt, 
		goods_amt LIKE invoicehead.goods_amt, 
		freight_amt LIKE invoicehead.freight_amt, 
		tax_amt LIKE invoicehead.tax_amt, 
		cost_amt LIKE invoicehead.cost_amt, 
		paid_amt LIKE invoicehead.paid_amt, 
		period_num LIKE invoicehead.period_num, 
		disc_amt LIKE invoicehead.disc_amt 
	END RECORD 

	DEFINE l_rec_credithead RECORD 
		cust_code LIKE credithead.cust_code, 
		sale_code LIKE credithead.sale_code, 
		name_text LIKE salesperson.name_text, 
		comm_per LIKE salesperson.comm_per, 
		cred_num LIKE credithead.cred_num, 
		cred_date LIKE credithead.cred_date, 
		total_amt LIKE credithead.total_amt, 
		freight_amt LIKE credithead.freight_amt, 
		tax_amt LIKE credithead.tax_amt, 
		cost_amt LIKE credithead.cost_amt, 
		period_num LIKE credithead.period_num 
	END RECORD 

	DEFINE l_sales_sel CHAR(1) 
	DEFINE l_date_sel CHAR(1) 
	DEFINE l_cust_sel CHAR(1) 
	DEFINE l_vee CHAR(1) 
	DEFINE l_ach CHAR(1) 
	DEFINE l_bsale CHAR(3) 
	DEFINE l_esale CHAR(3) 

	DEFINE l_bdate DATE 
	DEFINE l_edate DATE 

	DEFINE l_bcust CHAR(8) 
	DEFINE l_ecust CHAR(8) 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"AR6_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT AR6_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AR6_rpt_list")].sel_text
	#------------------------------------------------------------

	LET l_sales_sel = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AR6_rpt_list")].ref1_ind
	LET l_bsale = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AR6_rpt_list")].ref1_code 
	LET l_esale = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AR6_rpt_list")].ref2_code 

	LET l_date_sel = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AR6_rpt_list")].ref2_ind 
	LET l_bdate =  glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AR6_rpt_list")].ref1_date  
	LET l_edate = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AR6_rpt_list")].ref2_date  

	LET l_cust_sel = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AR6_rpt_list")].ref3_ind 
	LET l_bcust = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AR6_rpt_list")].ref3_code 
	LET l_ecust = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AR6_rpt_list")].ref4_code 

{
	#some base inits
	IF l_sales_sel NOT matches "[AS]" OR l_sales_sel IS NULL THEN
		LET l_sales_sel = "A"
	END IF 
	IF l_date_sel NOT matches "[AS]" OR l_date_sel IS NULL THEN
		LET l_date_sel = "A"
	END IF 
	IF l_cust_sel NOT matches "[AS]" OR l_cust_sel IS NULL THEN
		LET l_cust_sel = "A"
	END IF 
	}
	
	LET l_vee = "V" 
	LET l_ach = "H" 

	LET l_query_text = 
	"SELECT invoicehead.cust_code,invoicehead.sale_code, salesperson.name_text,salesperson.comm_per, invoicehead.inv_num, invoicehead.inv_date, invoicehead.total_amt, ", 
	"invoicehead.goods_amt, invoicehead.freight_amt, invoicehead.tax_amt, invoicehead.cost_amt, invoicehead.paid_amt, invoicehead.period_num, invoicehead.disc_amt ", 
	"FROM invoicehead , salesperson ", 
	" WHERE invoicehead.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND salesperson.cmpy_code = invoicehead.cmpy_code AND salesperson.sale_code = invoicehead.sale_code AND ", 
	"invoicehead.sale_code between \"",l_bsale,"\" AND \"",l_esale,"\" AND invoicehead.inv_date between \"",l_bdate,"\" AND \"",l_edate,"\" ", 
	"AND invoicehead.cust_code between \"",l_bcust,"\" AND \"",l_ecust,"\" ", 
	"AND invoicehead.posted_flag != \"",l_vee,"\" AND invoicehead.posted_flag != \"",l_ach,"\"" 

	PREPARE invoicer FROM l_query_text 
	DECLARE invcurs CURSOR FOR invoicer 
	OPEN invcurs 

	FOREACH invcurs INTO l_rec_invoicehead.* 
		LET l_rec_tempdoc.tm_cust = l_rec_invoicehead.cust_code 
		LET l_rec_tempdoc.tm_sale = l_rec_invoicehead.sale_code 
		LET l_rec_tempdoc.tm_name = l_rec_invoicehead.name_text 
		LET l_rec_tempdoc.tm_date = l_rec_invoicehead.inv_date 
		LET l_rec_tempdoc.tm_per = l_rec_invoicehead.period_num 
		LET l_rec_tempdoc.tm_doc = l_rec_invoicehead.inv_num 
		LET l_rec_tempdoc.tm_amount = l_rec_invoicehead.goods_amt + l_rec_invoicehead.tax_amt 
		LET l_rec_tempdoc.tm_paid = l_rec_invoicehead.paid_amt 
		IF l_rec_invoicehead.total_amt IS NULL THEN LET l_rec_invoicehead.total_amt = 0 END IF 
		IF l_rec_invoicehead.freight_amt IS NULL THEN LET l_rec_invoicehead.freight_amt = 0 END IF 
		IF l_rec_invoicehead.tax_amt IS NULL THEN LET l_rec_invoicehead.tax_amt = 0 END IF 
		IF l_rec_invoicehead.disc_amt IS NULL THEN LET l_rec_invoicehead.disc_amt = 0 END IF 
		IF l_rec_invoicehead.cost_amt IS NULL THEN LET l_rec_invoicehead.cost_amt = 0 END IF 
		LET l_rec_tempdoc.tm_prof = l_rec_invoicehead.goods_amt - l_rec_invoicehead.cost_amt 
		IF l_rec_tempdoc.tm_prof IS NULL THEN LET l_rec_tempdoc.tm_prof = 0 END IF 
		LET l_rec_tempdoc.tm_comm = (l_rec_tempdoc.tm_prof * l_rec_invoicehead.comm_per) 
		IF l_rec_tempdoc.tm_comm IS NULL THEN LET l_rec_tempdoc.tm_comm = 0 END IF 
		IF l_rec_tempdoc.tm_comm <> 0 THEN 
			LET l_rec_tempdoc.tm_comm = l_rec_tempdoc.tm_comm / 100 
		END IF 
		INSERT INTO t_ar6_rpt_data_shuffle VALUES (l_rec_tempdoc.*) 
		INITIALIZE l_rec_tempdoc.* TO NULL 
	END FOREACH 

	LET l_query_text = 
	"SELECT credithead.cust_code, credithead.sale_code, salesperson.name_text,salesperson.comm_per, credithead.cred_num, credithead.cred_date, ", 
	"credithead.total_amt, credithead.freight_amt, credithead.tax_amt, credithead.cost_amt, credithead.period_num ", 
	"FROM credithead , salesperson ", 
	"WHERE credithead.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND salesperson.cmpy_code = credithead.cmpy_code AND salesperson.sale_code = credithead.sale_code AND ", 
	"credithead.sale_code between \"",l_bsale,"\" AND \"",l_esale,"\" AND credithead.cred_date between \"",l_bdate,"\" AND \"",l_edate,"\" ", 
	"AND credithead.cust_code between \"",l_bcust,"\" AND \"",l_ecust,"\" AND credithead.posted_flag != \"",l_vee,"\" AND credithead.posted_flag != \"",l_ach,"\"" 

	PREPARE creditor FROM l_query_text 
	DECLARE credcurs CURSOR FOR creditor 
	OPEN credcurs 

	FOREACH credcurs INTO l_rec_credithead.* 
		LET l_rec_tempdoc.tm_sale = l_rec_credithead.sale_code 
		LET l_rec_tempdoc.tm_cust = l_rec_credithead.cust_code 
		LET l_rec_tempdoc.tm_name = l_rec_credithead.name_text 
		LET l_rec_tempdoc.tm_date = l_rec_credithead.cred_date 
		LET l_rec_tempdoc.tm_doc = l_rec_credithead.cred_num 
		LET l_rec_tempdoc.tm_amount = l_rec_credithead.total_amt 
		LET l_rec_tempdoc.tm_per = l_rec_credithead.period_num 
		IF l_rec_credithead.total_amt IS NULL THEN LET l_rec_credithead.total_amt = 0 END IF 
		IF l_rec_credithead.freight_amt IS NULL THEN LET l_rec_credithead.freight_amt = 0 END IF 
		IF l_rec_credithead.tax_amt IS NULL THEN LET l_rec_credithead.tax_amt = 0 END IF 
		IF l_rec_credithead.cost_amt IS NULL THEN LET l_rec_credithead.cost_amt = 0 END IF 
		LET l_rec_tempdoc.tm_prof = (l_rec_credithead.total_amt - l_rec_credithead.cost_amt) * -1 
		LET l_rec_tempdoc.tm_comm = (l_rec_tempdoc.tm_prof * l_rec_credithead.comm_per) 
		IF l_rec_tempdoc.tm_comm != 0 THEN 
			LET l_rec_tempdoc.tm_comm = l_rec_tempdoc.tm_comm / 100 
		END IF 
		INSERT INTO t_ar6_rpt_data_shuffle VALUES (l_rec_tempdoc.*) 
		INITIALIZE l_rec_tempdoc.* TO NULL 
	END FOREACH 
	CLEAR screen 

	DECLARE selcurs CURSOR FOR 
	SELECT * FROM t_ar6_rpt_data_shuffle 
	ORDER BY tm_sale, tm_date, tm_doc 

	FOREACH selcurs INTO l_rec_tempdoc.* 
		#---------------------------------------------------------
		OUTPUT TO REPORT AR6_rpt_list(l_rpt_idx,l_rec_tempdoc.*)  
		IF NOT rpt_int_flag_handler2("Document:",l_rec_tempdoc.tm_doc, l_rec_credithead.name_text,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------													
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT AR6_rpt_list
	RETURN rpt_finish("AR6_rpt_list")
	#------------------------------------------------------------

END FUNCTION 


############################################################
# REPORT AR6_rpt_list(p_rec_tempdoc)
#
#
############################################################
REPORT AR6_rpt_list(p_rpt_idx,p_rec_tempdoc) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_tempdoc 
	RECORD 
		tm_sale CHAR(3), 
		tm_name CHAR(30), 
		tm_cust CHAR(8), 
		tm_doc INTEGER, 
		tm_date DATE, 
		tm_per SMALLINT, 
		tm_amount money(12,2), 
		tm_paid money(12,2), 
		tm_prof money(12,2), 
		tm_comm money(12,2) 
	END RECORD 
	
	ORDER EXTERNAL BY p_rec_tempdoc.tm_sale, p_rec_tempdoc.tm_date,p_rec_tempdoc.tm_doc 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,PAGENO) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 CLIPPED #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 CLIPPED #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text CLIPPED 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text CLIPPED 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]

	BEFORE GROUP OF p_rec_tempdoc.tm_sale 
		PRINT COLUMN 01, "Salesperson : ", p_rec_tempdoc.tm_sale CLIPPED,"  ", p_rec_tempdoc.tm_name CLIPPED 

	ON EVERY ROW 
		PRINT 
		COLUMN 01, p_rec_tempdoc.tm_cust CLIPPED, 
		COLUMN 10, p_rec_tempdoc.tm_doc    USING "########", 
		COLUMN 20, p_rec_tempdoc.tm_date   USING "dd/mm/yy", 
		COLUMN 30, p_rec_tempdoc.tm_per    USING "##", 
		COLUMN 35, p_rec_tempdoc.tm_amount USING "----,---,--$.&&", 
		COLUMN 52, p_rec_tempdoc.tm_prof   USING "--,---,--$.&&", 
		COLUMN 67, p_rec_tempdoc.tm_comm   USING "--,---,--$.&&" 

	AFTER GROUP OF p_rec_tempdoc.tm_sale 
		PRINT COLUMN 39, "-----------------------------------------" 
		PRINT 
		COLUMN 35, GROUP SUM(p_rec_tempdoc.tm_amount) USING "----,---,--$.&&", 
		COLUMN 52, GROUP SUM(p_rec_tempdoc.tm_prof)   USING "--,---,--$.&&", 
		COLUMN 67, GROUP SUM(p_rec_tempdoc.tm_comm)   USING "--,---,--$.&&" 

	ON LAST ROW 
		PRINT COLUMN 39, "-----------------------------------------" 
		PRINT 
		COLUMN 35, SUM(p_rec_tempdoc.tm_amount)       USING "----,---,--$.&&", 
		COLUMN 52, SUM(p_rec_tempdoc.tm_prof)         USING "--,---,--$.&&", 
		COLUMN 67, SUM(p_rec_tempdoc.tm_comm)         USING "--,---,--$.&&" 
		SKIP 1 line 
		#End Of Report
		IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
			PRINT COLUMN 01,"Selection Criteria:" 
			PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
		END IF 
		PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	

END REPORT
