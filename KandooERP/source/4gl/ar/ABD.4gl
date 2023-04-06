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
GLOBALS "../ar/AB_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/ABD_GLOBALS.4gl" 
#####################################################################
# FUNCTION ABD_main()
#
# Invoice Adjustment Report
#####################################################################
FUNCTION ABD_main()

	CALL setModuleId("ABD") 

	CREATE temp TABLE t_invoicehead(cust_code CHAR(8), 
	name_text CHAR(30), 
	currency_code CHAR(3), 
	inv_num INTEGER, 
	inv_date DATE, 
	inv_type CHAR(2), 
	line_text CHAR(30), 
	unit_sale_amt DECIMAL(16,4)) 
	with no LOG 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 	

		OPEN WINDOW A650 with FORM "A650" 
		CALL windecoration_a("A650") 
		CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
	
		MENU "AR Adjusments " 
	
			BEFORE MENU 
				CALL publish_toolbar("kandoo","ABD","menu-ar-adjustments") 
				CALL ABD_rpt_process(ABD_rpt_query())
				CALL rpt_rmsreps_reset(NULL)
				
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
	
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
	
			ON ACTION "REPORT" #COMMAND "Report" " SELECT Criteria AND Print Report"
				CALL ABD_rpt_process(ABD_rpt_query())		
				CALL rpt_rmsreps_reset(NULL) 
	
			ON ACTION "PRINT MANAGER"	#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
				CALL run_prog("URS","","","","") 

			ON ACTION "CANCEL" #COMMAND KEY(interrupt,"E")"Exit" " RETURN TO Menus"
				EXIT MENU 
	
		END MENU 
	
		CLOSE WINDOW A650
	 
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL ABD_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW A650 with FORM "A650" 
			CALL windecoration_a("A650") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(ABD_rpt_query()) #save where clause in env 
			CLOSE WINDOW A650 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL ABD_rpt_process(get_url_sel_text())
	END CASE	

	IF fgl_find_table("t_invoicehead") THEN
		DROP TABLE t_invoicehead 
	END IF 	 

END FUNCTION

#####################################################################
# FUNCTION ABD_rpt_query()
#
#
#####################################################################
FUNCTION ABD_rpt_query() 
 	DEFINE l_where_text STRING

	MESSAGE kandoomsg2("A",1001,"") 
	#1001 Enter Selection Criteria - ESC TO Continue
	DELETE FROM t_invoicehead WHERE 1=1 

	CONSTRUCT l_where_text ON invoicehead.cust_code, 
	customer.name_text, 
	customer.currency_code, 
	invoicehead.inv_num, 
	invoicehead.inv_date, 
	invoicehead.year_num, 
	invoicehead.period_num, 
	invoicehead.sale_code, 
	invoicehead.tax_code, 
	invoicehead.term_code, 
	invoicedetl.line_text, 
	invoicedetl.unit_sale_amt, 
	invoicedetl.unit_tax_amt, 
	invoicehead.com1_text, 
	invoicehead.com2_text 
	FROM cust_code, 
	name_text, 
	currency_code, 
	inv_num, 
	inv_date, 
	year_num, 
	period_num, 
	sale_code, 
	tax_code, 
	term_code, 
	line_text, 
	unit_sale_amt, 
	unit_tax_amt, 
	com1_text, 
	com2_text 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","ABD","construct-invoice") 

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
# FUNCTION ABD_rpt_process() 
#
#
#####################################################################
FUNCTION ABD_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_where_text STRING #special case - array segment manipulation
	DEFINE l_rpt_idx SMALLINT 
	DEFINE l_rec_invoicehead RECORD 
		cust_code LIKE invoicehead.cust_code, 
		name_text LIKE customer.name_text, 
		currency_code LIKE customer.currency_code, 
		inv_num LIKE invoicehead.inv_num, 
		inv_date LIKE invoicehead.inv_date, 
		inv_type CHAR(2), 
		line_text LIKE invoicedetl.line_text, 
		unit_sale_amt LIKE invoicedetl.unit_sale_amt 
	END RECORD 
	DEFINE l_length INTEGER 
	DEFINE l_i INTEGER 
	DEFINE l_c INTEGER 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"ABD_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT ABD_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text	
	#------------------------------------------------------------

	LET l_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ABD_rpt_list")].sel_text clipped
	LET l_query_text = "SELECT invoicehead.cust_code, customer.name_text, ", 
	"customer.currency_code, invoicehead.inv_num, ", 
	"invoicehead.inv_date, 'IN', ", 
	"invoicedetl.line_text, invoicedetl.unit_sale_amt ", 
	"FROM invoicehead, customer, invoicedetl ", 
	"WHERE invoicehead.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
	"AND customer.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
	"AND invoicedetl.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
	"AND invoicehead.cust_code = customer.cust_code ", 
	"AND invoicedetl.inv_num = invoicehead.inv_num ", 
	"AND invoicehead.inv_ind = '4' ", 
	"AND ", l_where_text clipped, " ", 
	"ORDER BY invoicehead.cust_code, invoicehead.inv_num " 
	PREPARE s_invoicehead FROM l_query_text 
	DECLARE c_invoicehead CURSOR FOR s_invoicehead 

	FOREACH c_invoicehead INTO l_rec_invoicehead.* 
		INSERT INTO t_invoicehead VALUES (l_rec_invoicehead.*) 
	END FOREACH 

	LET l_length = length(l_where_text) 
	FOR l_i = 1 TO l_length 
		IF l_i < (l_length - 20) THEN 
			IF l_where_text[l_i,l_i+20] = "invoicehead.term_code" THEN 
				LET l_c = l_i + 20 
				LET l_where_text[l_i,l_c] = "1=1 " 
				FOR l_c = l_c TO l_length 
					IF l_where_text[l_c,l_c+2] = 'AND' THEN 
						EXIT FOR 
					ELSE 
						LET l_where_text[l_c] = ' ' 
					END IF 
				END FOR 
			END IF 
		END IF 

		IF l_i < (l_length - 24) THEN 
			IF l_where_text[l_i,l_i+ 24] = "invoicedetl.unit_sale_amt" THEN 
				LET l_where_text[l_i,l_i+24] = "creditdetl.unit_sales_amt" 
			END IF 
		END IF 

		IF l_i < (l_length - 15) THEN 
			IF l_where_text[l_i,l_i+ 15] = "invoicedetl.inv_" THEN 
				LET l_where_text[l_i,l_i+15] = "creditdetl.cred_" 
			END IF 
			IF l_where_text[l_i,l_i+ 15] = "invoicehead.inv_" THEN 
				LET l_where_text[l_i,l_i+15] = "credithead.cred_" 
			END IF 
		END IF 
		IF l_i < (l_length - 6) THEN 
			IF l_where_text[l_i,l_i+ 6] = "invoice" THEN 
				LET l_where_text[l_i,l_i+6] = " credit" 
			END IF 
		END IF 
	END FOR 


	LET l_query_text = "SELECT credithead.cust_code, customer.name_text, ", 
	"customer.currency_code, credithead.cred_num, ", 
	"credithead.cred_date, 'CR', ", 
	"creditdetl.line_text, ", 
	"creditdetl.unit_sales_amt * -1 ", 
	"FROM credithead, customer, creditdetl ", 
	"WHERE credithead.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
	"AND customer.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
	"AND creditdetl.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
	"AND credithead.cust_code = customer.cust_code ", 
	"AND creditdetl.cred_num = credithead.cred_num ", 
	"AND credithead.cred_ind = '4' ", 
	"AND ", l_where_text clipped, " ", 
	"ORDER BY credithead.cust_code, credithead.cred_num" 

	PREPARE s_credithead FROM l_query_text 
	DECLARE c_credithead CURSOR FOR s_credithead 

	FOREACH c_credithead INTO l_rec_invoicehead.* 
		INSERT INTO t_invoicehead VALUES (l_rec_invoicehead.*) 
	END FOREACH 

	DECLARE c_transprint CURSOR FOR 
	SELECT * FROM t_invoicehead 
	WHERE 1=1 
	ORDER BY cust_code, inv_num 

	FOREACH c_transprint INTO l_rec_invoicehead.*
		#---------------------------------------------------------
		OUTPUT TO REPORT ABD_rpt_list(l_rpt_idx,
		l_rec_invoicehead.*)  
		IF NOT rpt_int_flag_handler2("Invoice:",l_rec_invoicehead.inv_num, l_rec_invoicehead.name_text,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT ABD_rpt_list
	CALL rpt_finish("ABD_rpt_list")
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
# REPORT ABD_rpt_list(p_rpt_idx,p_rec_invoicehead) 
#
#
#####################################################################
REPORT ABD_rpt_list(p_rpt_idx,p_rec_invoicehead) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE p_rec_invoicehead RECORD 
		cust_code LIKE invoicehead.cust_code, 
		name_text LIKE customer.name_text, 
		currency_code LIKE customer.currency_code, 
		inv_num LIKE invoicehead.inv_num, 
		inv_date LIKE invoicehead.inv_date, 
		inv_type CHAR(2), 
		line_text LIKE invoicedetl.line_text, 
		unit_sale_amt LIKE invoicedetl.unit_sale_amt 
	END RECORD 
	DEFINE l_col SMALLINT 
	DEFINE l_i SMALLINT 
	DEFINE l_line1 CHAR(130) 
	DEFINE l_line2 CHAR(130) 

	OUTPUT 
	left margin 0 
	ORDER external BY p_rec_invoicehead.cust_code, p_rec_invoicehead.inv_num 
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			
			PRINT COLUMN 02, "Trans", 
			COLUMN 12, "Entry", 
			COLUMN 18, "Type", 
			COLUMN 24, "Description", 
			COLUMN 61, "Adjustment" 
			PRINT COLUMN 02, "Number", 
			COLUMN 12, "Date", 
			COLUMN 62, "Amount" 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

		ON EVERY ROW 
			PRINT COLUMN 01, p_rec_invoicehead.inv_num USING "########", 
			COLUMN 10, p_rec_invoicehead.inv_date USING "dd/mm/yy", 
			COLUMN 19, p_rec_invoicehead.inv_type, 
			COLUMN 24, p_rec_invoicehead.line_text, 
			COLUMN 55, p_rec_invoicehead.unit_sale_amt USING "---,---,--&.&&" 

		BEFORE GROUP OF p_rec_invoicehead.cust_code 
			SKIP 1 line 
			PRINT COLUMN 01, "Customer Code:", 
			COLUMN 15, p_rec_invoicehead.cust_code, 
			COLUMN 25, p_rec_invoicehead.name_text, 
			COLUMN 50, "Currency:", 
			COLUMN 61, p_rec_invoicehead.currency_code 
			SKIP 1 line 

		AFTER GROUP OF p_rec_invoicehead.cust_code 
			PRINT COLUMN 55, rpt_get_char_line(p_rpt_idx,14,"=")  --"==============" 
			PRINT COLUMN 55, GROUP sum(p_rec_invoicehead.unit_sale_amt) USING "---,---,--&.&&" 

		ON LAST ROW 
			PRINT COLUMN 55, rpt_get_char_line(p_rpt_idx,14,"=")  --"==============" 
			PRINT COLUMN 01, "Report Totals:" 
			PRINT COLUMN 55, sum(p_rec_invoicehead.unit_sale_amt) 
			USING "---,---,--&.&&" 
			SKIP 1 line 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	
END REPORT 