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
GLOBALS "../ar/ARA_GLOBALS.4gl" 
############################################################
# MODULE Scope Variables
############################################################
DEFINE modu_tot_amt DECIMAL(16,2) #Will be incremented/added in actual report block 

######################################################################
# FUNCTION ara_main()
#
# ARA Audit Trail
######################################################################
FUNCTION ARA_main() 
	DEFER quit 
	DEFER interrupt
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

	CALL setModuleId("ARA")
	CALL init_report_ar() #report default data from db-arparms
	CALL AR_temp_tables_create()

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query

		WHEN RPT_OP_MENU #UI/MENU Mode 
			OPEN WINDOW A187 with FORM "A187" 
			CALL windecoration_a("A187") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
		
			MENU " Audit Trail" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","ARA","menu-audit-trail") 
					CALL rpt_rmsreps_reset(NULL)
					CALL ARA_rpt_process(ARA_rpt_query())
					CALL AR_temp_tables_delete()		
		
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				ON ACTION "Report" 	#COMMAND "Report" " SELECT Criteria AND PRINT REPORT"
					CALL rpt_rmsreps_reset(NULL)
					CALL ARA_rpt_process(ARA_rpt_query())
					CALL AR_temp_tables_delete()
					
				ON ACTION "Print Manager"	#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
	
				ON ACTION "CANCEL" #COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus"
					EXIT MENU 
		
			END MENU 
		
			CLOSE WINDOW A187
	 
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL ARA_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW A187 with FORM "A187" 
			CALL windecoration_a("A187") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(ARA_rpt_query()) #save where clause in env 
			CLOSE WINDOW A187 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL ARA_rpt_process(get_url_sel_text())
	END CASE
		
	CALL AR_temp_tables_drop() 
END FUNCTION 


######################################################################
# FUNCTION ARA_rpt_query())
#
#
######################################################################
FUNCTION ARA_rpt_query() 
	DEFINE l_where_text STRING
	CLEAR FORM 
	
	MESSAGE kandoomsg2("U",1001,"") 
	#1001 Enter Selection Criteria;  OK TO Continue.

	CONSTRUCT BY NAME l_where_text ON 
	araudit.tran_date, 
	araudit.cust_code, 
	araudit.seq_num, 
	araudit.tran_type_ind, 
	araudit.source_num, 
	araudit.tran_text, 
	customer.currency_code, 
	araudit.tran_amt, 
	araudit.year_num, 
	araudit.period_num 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","ARA","construct-araudit") 

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


######################################################################
# FUNCTION ARA_rpt_process()
#
#
######################################################################
FUNCTION ARA_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT  
	DEFINE l_rec_araudit RECORD 
		tran_date LIKE araudit.tran_date, 
		cust_code LIKE araudit.cust_code, 
		currency_code LIKE customer.currency_code, 
		tran_type_ind LIKE araudit.tran_type_ind, 
		source_num LIKE araudit.source_num, 
		tran_text LIKE araudit.tran_text, 
		conv_qty LIKE araudit.conv_qty, 
		tran_amt LIKE araudit.tran_amt, 
		sales_code money(12,2), 
		dr_cash money(12,2), 
		dr_cred money(12,2) 
	END RECORD 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"ARA_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	

	START REPORT ARA_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	LET modu_tot_amt = 0 
	LET glob_day_amt = 0 
	LET glob_tot_sales = 0 
	LET glob_day_sales = 0 
	LET glob_tot_cash = 0 
	LET glob_day_cash = 0 
	LET glob_tot_cred = 0 
	LET glob_day_cred = 0 

	LET l_query_text = 
	"SELECT araudit.tran_date,", 
	"araudit.cust_code,", 
	"customer.currency_code,", 
	"araudit.tran_type_ind,", 
	"araudit.source_num,", 
	"araudit.tran_text,", 
	"araudit.conv_qty,", 
	"araudit.tran_amt ", 
	"FROM araudit,", 
	"customer ", 
	"WHERE araudit.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\"", 
	"AND customer.cmpy_code = araudit.cmpy_code ", 
	"AND customer.cust_code = araudit.cust_code ", 
	"AND ", p_where_text CLIPPED," ", 
	"ORDER BY araudit.tran_date,", 
	"araudit.cust_code" 

	PREPARE s_audit FROM l_query_text 
	DECLARE c_audit CURSOR FOR s_audit

	FOREACH c_audit INTO l_rec_araudit.* 
		IF l_rec_araudit.tran_type_ind = TRAN_TYPE_INVOICE_IN THEN 
			LET l_rec_araudit.sales_code = l_rec_araudit.tran_amt 
		ELSE 
			LET l_rec_araudit.sales_code = 0 
		END IF 
		IF l_rec_araudit.tran_type_ind = TRAN_TYPE_RECEIPT_CA THEN 
			LET l_rec_araudit.dr_cash = l_rec_araudit.tran_amt * -1 
		ELSE 
			LET l_rec_araudit.dr_cash = 0 
		END IF 
		IF l_rec_araudit.tran_type_ind = TRAN_TYPE_CREDIT_CR THEN 
			LET l_rec_araudit.dr_cred = l_rec_araudit.tran_amt * -1 
		ELSE 
			LET l_rec_araudit.dr_cred = 0 
		END IF

		#---------------------------------------------------------
		OUTPUT TO REPORT ARA_rpt_list(l_rpt_idx,l_rec_araudit.*) 
		IF NOT rpt_int_flag_handler2("Customer:",l_rec_araudit.cust_code, l_rec_araudit.tran_date,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------			 
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT ARA_rpt_list
	RETURN rpt_finish("ARA_rpt_list")
	#------------------------------------------------------------

END FUNCTION 


######################################################################
# REPORT ARA_rpt_list(p_rpt_idx,p_rec_araudit)
#
#
######################################################################
REPORT ARA_rpt_list(p_rpt_idx,p_rec_araudit) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_araudit RECORD 
		tran_date LIKE araudit.tran_date, 
		cust_code LIKE araudit.cust_code, 
		currency_code LIKE customer.currency_code, 
		tran_type_ind LIKE araudit.tran_type_ind, 
		source_num LIKE araudit.source_num, 
		tran_text LIKE araudit.tran_text, 
		conv_qty LIKE araudit.conv_qty, 
		tran_amt LIKE araudit.tran_amt, 
		sales_code money(12,2), 
		dr_cash money(12,2), 
		dr_cred money(12,2) 
	END RECORD 
	DEFINE l_line1 NCHAR(130) 
	DEFINE l_line2 NCHAR(130) 
	
	ORDER EXTERNAL BY p_rec_araudit.tran_date,p_rec_araudit.cust_code 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,PAGENO) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 CLIPPED #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 CLIPPED #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text CLIPPED 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]

	BEFORE GROUP OF p_rec_araudit.tran_date 
		PRINT COLUMN 1, p_rec_araudit.tran_date  USING "dd/mm/yy" 

	ON EVERY ROW 
		PRINT 
		COLUMN 1, p_rec_araudit.cust_code CLIPPED, 
		COLUMN 10, p_rec_araudit.tran_type_ind CLIPPED, 
		COLUMN 20, p_rec_araudit.source_num      USING "########", 
		COLUMN 30, p_rec_araudit.tran_text CLIPPED, 
		COLUMN 55, p_rec_araudit.currency_code CLIPPED, 
		COLUMN 60, p_rec_araudit.tran_amt        USING "--,---,---,--$.&&", 
		COLUMN 78, p_rec_araudit.sales_code      USING "--,---,---,--$.&&", 
		COLUMN 96, p_rec_araudit.dr_cash         USING "--,---,---,--$.&&", 
		COLUMN 114,p_rec_araudit.dr_cred         USING "--,---,---,--$.&&" 

		LET glob_day_amt = glob_day_amt + (p_rec_araudit.tran_amt / p_rec_araudit.conv_qty) 
		LET glob_day_sales = glob_day_sales + (p_rec_araudit.sales_code / p_rec_araudit.conv_qty) 
		LET glob_day_cash = glob_day_cash + (p_rec_araudit.dr_cash / p_rec_araudit.conv_qty) 
		LET glob_day_cred = glob_day_cred + (p_rec_araudit.dr_cred / p_rec_araudit.conv_qty)

	AFTER GROUP OF p_rec_araudit.tran_date 
		SKIP 1 LINE 
		PRINT COLUMN 1, "Totals in base currency", 
		COLUMN 60, "---------------------------------------", 
		"----------------------------------" 
		PRINT 
		COLUMN 60, glob_day_amt                  USING "--,---,---,--$.&&", 
		COLUMN 78, glob_day_sales                USING "--,---,---,--$.&&", 
		COLUMN 96, glob_day_cash                 USING "--,---,---,--$.&&", 
		COLUMN 114,glob_day_cred                 USING "--,---,---,--$.&&" 
		LET modu_tot_amt = modu_tot_amt + glob_day_amt 
		LET glob_tot_sales = glob_tot_sales + glob_day_sales 
		LET glob_tot_cash = glob_tot_cash + glob_day_cash 
		LET glob_tot_cred = glob_tot_cred + glob_day_cred 

	ON LAST ROW 
		PRINT COLUMN 1, "Totals in foreign currency" 
		PRINT 
		COLUMN 60, SUM(p_rec_araudit.tran_amt)   USING "--,---,---,--$.&&", 
		COLUMN 78, SUM(p_rec_araudit.sales_code) USING "--,---,---,--$.&&", 
		COLUMN 96, SUM(p_rec_araudit.dr_cash)    USING "--,---,---,--$.&&", 
		COLUMN 114,SUM(p_rec_araudit.dr_cred)    USING "--,---,---,--$.&&" 
		SKIP 1 LINE 
		#End Of Report
		IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
			PRINT COLUMN 01,"Selection Criteria:" 
			PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text CLIPPED WORDWRAP RIGHT MARGIN 100 
		END IF 
		PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report 			
		LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = PAGENO

END REPORT 
