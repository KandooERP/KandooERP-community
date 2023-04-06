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
GLOBALS "../ar/ARB_GLOBALS.4gl" 
############################################################
# MODULE Scope Variables
############################################################
############################################################
# FUNCTION ARB(p_mode)
#
#  module ARB Sales Commissions without profit FOR salespersons
############################################################
FUNCTION ARB_main() 
	DEFER quit 
	DEFER interrupt
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

	CALL setModuleId("ARB")
	CALL init_report_ar() #report default data from db-arparms
	CALL AR_temp_tables_create()

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query

		WHEN RPT_OP_MENU #UI/MENU Mode 	
			OPEN WINDOW A216 with FORM "A216" 
			CALL windecoration_a("A216") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
		
			MENU "Commission Report" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","ARB","menu-comission-REPORT") 
					CALL ARB_rpt_process(ARB_rpt_query())
					CALL AR_temp_tables_delete()
		
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				ON ACTION "REPORT" COMMAND "Run Report" " SELECT criteria AND PRINT REPORT" 
					CALL ARB_rpt_process(ARB_rpt_query())
					CALL AR_temp_tables_delete()
		
				ON ACTION "Print Manager" #COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 		
				
				ON ACTION "CANCEL" #COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus" 
					EXIT MENU 
		
			END MENU 
			
			CLOSE WINDOW A216
	 
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL ARB_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW A216 with FORM "A216" 
			CALL windecoration_a("A216") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(ARB_rpt_query()) #save where clause in env 
			CLOSE WINDOW A216 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL ARB_rpt_process(get_url_sel_text())
	END CASE
		
	CALL AR_temp_tables_drop()
		 
END FUNCTION 


############################################################
# FUNCTION ARB_rpt_query()
#
#
############################################################
FUNCTION ARB_rpt_query() 
	DEFINE l_where_text STRING

	CLEAR FORM
	 
	MESSAGE "Enter Selection Criteria - ESC TO Continue"	attribute(yellow) 
	CONSTRUCT BY NAME l_where_text ON invoicehead.sale_code, 
	salesperson.name_text, 
	salesperson.terri_code, 
	invoicehead.cust_code, 
	invoicehead.inv_date, 
	invoicehead.inv_num, 
	invoicehead.currency_code, 
	invoicehead.total_amt, 
	invoicehead.year_num, 
	invoicehead.period_num 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","ARB","construct-invoicehead") 

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


############################################################
# FUNCTION ARB_rpt_process(p_where_text) 
#
#
############################################################
FUNCTION ARB_rpt_process(p_where_text) 
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
	DEFINE l_where_text STRING 
	DEFINE l_i SMALLINT 
	DEFINE l_j SMALLINT 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"ARB_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT ARB_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ARB_rpt_list")].sel_text
	#------------------------------------------------------------


	LET l_query_text = 
	"SELECT invoicehead.cust_code,", 
	"invoicehead.sale_code,", 
	"salesperson.name_text,", 
	"salesperson.comm_per,", 
	"invoicehead.inv_num,", 
	"invoicehead.inv_date,", 
	"invoicehead.total_amt, ", 
	"invoicehead.goods_amt,", 
	"invoicehead.freight_amt,", 
	"invoicehead.tax_amt,", 
	"invoicehead.cost_amt,", 
	"invoicehead.paid_amt,", 
	"invoicehead.period_num,", 
	"invoicehead.disc_amt ", 
	"FROM invoicehead ,", 
	"salesperson ", 
	"WHERE invoicehead.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND salesperson.cmpy_code = invoicehead.cmpy_code ", 
	"AND salesperson.sale_code = invoicehead.sale_code ", 
	"AND invoicehead.posted_flag != \"V\" ", 
	"AND invoicehead.posted_flag != \"H\" ", 
	"AND ",glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ARB_rpt_list")].sel_text clipped," ", 
	"ORDER BY invoicehead.sale_code,invoicehead.cust_code"
	 
	PREPARE s_invoice FROM l_query_text 
	DECLARE c_invoice CURSOR FOR s_invoice 

	#MESSAGE " Reporting on Salesperson.. Invoice......"
	  
	FOREACH c_invoice INTO l_rec_invoicehead.* 
		LET l_rec_tempdoc.tm_cust = l_rec_invoicehead.cust_code 
		LET l_rec_tempdoc.tm_sale = l_rec_invoicehead.sale_code 
		LET l_rec_tempdoc.tm_name = l_rec_invoicehead.name_text 
		LET l_rec_tempdoc.tm_date = l_rec_invoicehead.inv_date 
		LET l_rec_tempdoc.tm_per = l_rec_invoicehead.period_num 
		LET l_rec_tempdoc.tm_doc = l_rec_invoicehead.inv_num 
		LET l_rec_tempdoc.tm_amount = l_rec_invoicehead.goods_amt 
		+ l_rec_invoicehead.tax_amt 
		LET l_rec_tempdoc.tm_paid = l_rec_invoicehead.paid_amt 
		IF l_rec_invoicehead.total_amt IS NULL THEN 
			LET l_rec_invoicehead.total_amt = 0 
		END IF 
		IF l_rec_invoicehead.freight_amt IS NULL THEN 
			LET l_rec_invoicehead.freight_amt = 0 
		END IF 
		IF l_rec_invoicehead.tax_amt IS NULL THEN 
			LET l_rec_invoicehead.tax_amt = 0 
		END IF 
		IF l_rec_invoicehead.disc_amt IS NULL THEN 
			LET l_rec_invoicehead.disc_amt = 0 
		END IF 
		IF l_rec_invoicehead.cost_amt IS NULL THEN 
			LET l_rec_invoicehead.cost_amt = 0 
		END IF 
		LET l_rec_tempdoc.tm_prof = l_rec_invoicehead.goods_amt 
		- l_rec_invoicehead.cost_amt 
		IF l_rec_tempdoc.tm_prof IS NULL THEN 
			LET l_rec_tempdoc.tm_prof = 0 
		END IF 
		LET l_rec_tempdoc.tm_comm = l_rec_tempdoc.tm_amount 
		* l_rec_invoicehead.comm_per 
		IF l_rec_tempdoc.tm_comm IS NULL THEN 
			LET l_rec_tempdoc.tm_comm = 0 
		END IF 
		IF l_rec_tempdoc.tm_comm != 0 THEN 
			LET l_rec_tempdoc.tm_comm = l_rec_tempdoc.tm_comm / 100 
		END IF 
		INSERT INTO t_arb_rpt_data_shuffle VALUES (l_rec_tempdoc.*) 
		INITIALIZE l_rec_tempdoc.* TO NULL 
		DISPLAY l_rec_invoicehead.name_text at 1,28 

		DISPLAY l_rec_invoicehead.inv_num at 2,28 

		IF int_flag OR quit_flag THEN 
			#8503 Continue Report (Y/N)
			IF kandoomsg("U",8503,"") = "N" THEN 
				MESSAGE kandoomsg2("U",9501,"") 
				#9501 Report Terminated
				LET int_flag = true 
				LET quit_flag = true 
				EXIT FOREACH 
			END IF 
		END IF 
	END FOREACH 

	LET l_j = (length(p_where_text)) 

	FOR l_i = 1 TO (l_j-11) 
		IF p_where_text[l_i,l_i+10] = "invoicehead" THEN 
			LET p_where_text[l_i,l_i+10] = " credithead" 
		END IF 
	END FOR 
	FOR l_i = 1 TO (l_j-3) 
		IF p_where_text[l_i,l_i+2] = "inv" THEN 
			LET p_where_text = 
			p_where_text[1,l_i-1],"cred",p_where_text[l_i+3,l_j] 
			LET l_j=l_j+1 
		END IF 
	END FOR 

	LET l_query_text = 
	"SELECT credithead.cust_code,", 
	"credithead.sale_code,", 
	"salesperson.name_text,", 
	"salesperson.comm_per,", 
	"credithead.cred_num,", 
	"credithead.cred_date, ", 
	"credithead.total_amt,", 
	"credithead.freight_amt,", 
	"credithead.tax_amt,", 
	"credithead.cost_amt,", 
	"credithead.period_num ", 
	"FROM credithead,", 
	"salesperson ", 
	"WHERE credithead.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND salesperson.cmpy_code = credithead.cmpy_code ", 
	"AND salesperson.sale_code = credithead.sale_code ", 
	"AND credithead.posted_flag != \"V\" ", 
	"AND credithead.posted_flag != \"H\" ", 
	"AND ",p_where_text clipped," ", 
	"ORDER BY credithead.sale_code,credithead.cust_code" 
	
	PREPARE s_credit FROM l_query_text 
	DECLARE c_credit CURSOR FOR s_credit
	 
	#DISPLAY " Credit......." at 2,1 
	FOREACH c_credit INTO l_rec_credithead.* 
		LET l_rec_tempdoc.tm_sale = l_rec_credithead.sale_code 
		LET l_rec_tempdoc.tm_cust = l_rec_credithead.cust_code 
		LET l_rec_tempdoc.tm_name = l_rec_credithead.name_text 
		LET l_rec_tempdoc.tm_date = l_rec_credithead.cred_date 
		LET l_rec_tempdoc.tm_doc = l_rec_credithead.cred_num 
		LET l_rec_tempdoc.tm_amount = 0 - l_rec_credithead.total_amt 
		LET l_rec_tempdoc.tm_per = l_rec_credithead.period_num 
		IF l_rec_credithead.total_amt IS NULL THEN 
			LET l_rec_credithead.total_amt = 0 
		END IF 
		IF l_rec_credithead.freight_amt IS NULL THEN 
			LET l_rec_credithead.freight_amt = 0 
		END IF 
		IF l_rec_credithead.tax_amt IS NULL THEN 
			LET l_rec_credithead.tax_amt = 0 
		END IF 
		IF l_rec_credithead.cost_amt IS NULL THEN 
			LET l_rec_credithead.cost_amt = 0 
		END IF 
		LET l_rec_tempdoc.tm_prof = 0 - ( l_rec_credithead.total_amt 
		- l_rec_credithead.cost_amt) 
		LET l_rec_tempdoc.tm_comm = l_rec_tempdoc.tm_amount 
		* l_rec_credithead.comm_per 
		IF l_rec_tempdoc.tm_comm != 0 THEN 
			LET l_rec_tempdoc.tm_comm = l_rec_tempdoc.tm_comm / 100 
		END IF 
		DISPLAY l_rec_credithead.name_text at 1,28 

		DISPLAY l_rec_credithead.cred_num at 2,28 

		INSERT INTO t_arb_rpt_data_shuffle VALUES (l_rec_tempdoc.*) 
		INITIALIZE l_rec_tempdoc.* TO NULL 
		IF int_flag OR quit_flag THEN 
			#8503 Continue Report (Y/N)
			IF kandoomsg("U",8503,"") = "N" THEN 
				MESSAGE kandoomsg2("U",9501,"") 
				#9501 Report Terminated
				LET int_flag = true 
				LET quit_flag = true 
				EXIT FOREACH 
			END IF 
		END IF 
	END FOREACH
	 
	 
	DECLARE selcurs CURSOR FOR 
	SELECT * 
	FROM t_arb_rpt_data_shuffle 
	ORDER BY tm_sale, 
	tm_cust, 
	tm_date, 
	tm_doc 
	
	FOREACH selcurs INTO l_rec_tempdoc.* 
		#---------------------------------------------------------
		OUTPUT TO REPORT ARB_rpt_list(l_rpt_idx,l_rec_tempdoc.*)  
		IF NOT rpt_int_flag_handler2("Customer:",l_rec_tempdoc.tm_cust, l_rec_credithead.name_text,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------	
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT ARB_rpt_list
	CALL rpt_finish("ARB_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF  
END FUNCTION 


############################################################
# REPORT ARB_rpt_list(p_rpt_idx,l_rec_tempdoc) 
#
#
############################################################
REPORT ARB_rpt_list(p_rpt_idx,l_rec_tempdoc) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE l_rec_tempdoc RECORD 
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
	DEFINE l_name_text LIKE customer.name_text 
	
	OUTPUT 
	left margin 0 
	ORDER external BY l_rec_tempdoc.tm_sale, 
	l_rec_tempdoc.tm_date, 
	l_rec_tempdoc.tm_doc 
	
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #was l_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #was l_arr_line[3]  
			
			PRINT COLUMN 1, "ID", 
			COLUMN 10, "Name", 
			COLUMN 41, "Document", 
			COLUMN 51, " Date", 
			COLUMN 61, "Period", 
			COLUMN 75, "Amount", 
			COLUMN 85, "Commission"
			 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #was l_arr_line[3]

		ON EVERY ROW 
			SELECT name_text INTO l_name_text FROM customer 
			WHERE cust_code = l_rec_tempdoc.tm_cust 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			PRINT COLUMN 1, l_rec_tempdoc.tm_cust, 
			COLUMN 10, l_name_text, 
			COLUMN 41, l_rec_tempdoc.tm_doc USING "########", 
			COLUMN 51, l_rec_tempdoc.tm_date USING "dd/mm/yy", 
			COLUMN 63, l_rec_tempdoc.tm_per USING "##", 
			COLUMN 68, l_rec_tempdoc.tm_amount USING "--,---,--$.&&", 
			COLUMN 82, l_rec_tempdoc.tm_comm USING "--,---,--$.&&" 
			
		BEFORE GROUP OF l_rec_tempdoc.tm_sale 
			SKIP 2 LINES 
			PRINT COLUMN 1, "Salesperson : ",l_rec_tempdoc.tm_sale, 
			2 spaces,l_rec_tempdoc.tm_name 
			
		AFTER GROUP OF l_rec_tempdoc.tm_sale 
			PRINT COLUMN 68, "---------------------------" 
			PRINT COLUMN 68, GROUP sum(l_rec_tempdoc.tm_amount) 
			USING "--,---,--$.&&", 
			COLUMN 82, GROUP sum(l_rec_tempdoc.tm_comm) 
			USING "--,---,--$.&&" 
			
		ON LAST ROW 
			PRINT COLUMN 68, "---------------------------" 
			PRINT COLUMN 68, sum(l_rec_tempdoc.tm_amount) USING "--,---,--$.&&", 
			COLUMN 82, sum(l_rec_tempdoc.tm_comm) USING "--,---,--$.&&" 
			SKIP 1 line 
			
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	
			


END REPORT 