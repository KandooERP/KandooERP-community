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
# GLOBAL SCOPE VARIABLES
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl"

############################################################
# MODULE SCOPE VARIABLES
############################################################
############################################################
# FUNCTION AEC_main()
#
# Sales Analysis by Invoice (with Inventory Sel.Crit)
############################################################
FUNCTION AEC_main() 
	DEFER quit 
	DEFER interrupt 

	CALL setModuleId("AEC") 

	CREATE temp TABLE t_document(cust_code CHAR(8), 
	name_text CHAR(30), 
	curr_code CHAR(3), 
	conv_qty FLOAT, 
	trans_date DATE, 
	trans_num INTEGER, 
	net_amt DECIMAL(16,2), 
	grs_amt DECIMAL(16,2), 
	cost_amt DECIMAL(16,2), 
	prof_amt DECIMAL(16,2), 
	disc_per FLOAT, 
	tran_type CHAR(2)) with no LOG 


	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 	

			OPEN WINDOW A645 with FORM "A645" 
			CALL windecoration_a("A645")
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
		
#			DISPLAY glob_rec_kandooreport.header_text TO header_text
			
			
			MENU " Sales Analysis (by invoice)" 
		
				BEFORE MENU 
					CALL publish_toolbar("kandoo","AEC","menu-sales-analysis-invoice") 
					CALL AEC_rpt_process(AEC_rpt_query())
					
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				ON ACTION "REPORT" #COMMAND "Report" " SELECT criteria AND PRINT REPORT" 
					CALL AEC_rpt_process(AEC_rpt_query()) 
		
				ON ACTION "Print Manager"	#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "CANCEL" #COMMAND KEY(interrupt,"E")"Exit" " RETURN TO menus" 
					EXIT MENU 
		
			END MENU 
			CLOSE WINDOW A645
		 
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL AEC_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW A645 with FORM "A645" #A645 or A148 ?
			CALL windecoration_a("A645") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(AEC_rpt_query()) #save where clause in env 
			CLOSE WINDOW A645 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL AEC_rpt_process(get_url_sel_text())
	END CASE

	IF fgl_find_table("t_document") THEN
		DROP TABLE t_document 
	END IF 	 	

END FUNCTION 


############################################################
# FUNCTION AEC_rpt_query()
#
#
############################################################
FUNCTION AEC_rpt_query() 
	DEFINE l_where_text STRING
	
	MESSAGE kandoomsg2("A",1001,"")	#A1001" Enter Selection Criteria - ESC TO Continue

	CONSTRUCT BY NAME l_where_text ON customer.cust_code, 
	customer.name_text, 
	customer.addr1_text, 
	customer.addr2_text, 
	customer.city_text, 
	customer.state_code, 
	customer.post_code, 
	customer.country_code, 
--@db-patch_2020_10_04--	customer.country_text, --@db-patch_2020_10_04--
	invoicehead.org_cust_code, 
	customer.type_code, 
	invoicehead.sale_code, 
	invoicehead.territory_code, 
	customer.term_code, 
	invoicehead.tax_code, 
	invoicehead.currency_code, 
	invoicehead.inv_date, 
	invoicehead.entry_date, 
	invoicehead.year_num, 
	invoicehead.period_num, 
	product.maingrp_code, 
	product.prodgrp_code, 
	product.part_code, 
	product.desc_text, 
	product.desc2_text, 
	product.class_code, 
	product.cat_code 


		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","AEC","construct-customer") 

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
# FUNCTION AEC_rpt_process)
#
#
############################################################
FUNCTION AEC_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT 
	DEFINE l_rec_document RECORD 
		cust_code LIKE customer.cust_code, 
		name_text LIKE customer.name_text, 
		curr_code LIKE invoicehead.currency_code, 
		conv_qty LIKE invoicehead.conv_qty, 
		trans_date LIKE invoicehead.inv_date, 
		trans_num LIKE invoicehead.inv_num, 
		net_amt LIKE invoicehead.total_amt, 
		grs_amt LIKE invoicehead.total_amt, 
		cost_amt LIKE invoicehead.total_amt, 
		prof_amt LIKE invoicehead.total_amt, 
		disc_per FLOAT, 
		trans_type LIKE araudit.tran_type_ind 
	END RECORD 
	DEFINE l_rec_invoicedetl RECORD LIKE invoicedetl.*
	DEFINE l_rec_creditdetl RECORD LIKE creditdetl.*
	DEFINE l_i SMALLINT 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"AEC_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT AEC_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	DELETE FROM t_document WHERE 1=1 

	LET l_query_text = "SELECT list_amt FROM prodstatus ", 
	"WHERE cmpy_code='",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND ware_code=? AND part_code=? "
	 
	PREPARE s_prodstatus FROM l_query_text 
	DECLARE c_prodstatus CURSOR FOR s_prodstatus 

	LET l_query_text = 
	"SELECT unique invoicehead.cust_code,", 
	"customer.name_text,", 
	"customer.currency_code,", 
	"invoicehead.conv_qty,", 
	"invoicehead.inv_date,", 
	"invoicehead.inv_num ", 
	"FROM invoicehead,", 
	"customer,", 
	"invoicedetl,", 
	"product ", 
	"WHERE customer.cmpy_code='",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND customer.delete_flag='N' ", 
	"AND invoicehead.cmpy_code= '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND invoicehead.cust_code=customer.cust_code ", 
	"AND invoicehead.inv_ind !='3' ", 
	"AND invoicehead.total_amt <> 0 ", 
	"AND invoicedetl.cmpy_code='",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND invoicedetl.inv_num=invoicehead.inv_num ", 
	"AND product.cmpy_code='",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND product.part_code = invoicedetl.part_code ", 
	"AND ",p_where_text CLIPPED
	 
	PREPARE s_invoicehead FROM l_query_text 
	DECLARE c_invoicehead CURSOR FOR s_invoicehead 
	
	LET glob_temp_text = "SELECT * FROM invoicedetl ", 
	"WHERE cmpy_code='",glob_rec_kandoouser.cmpy_code,"' AND inv_num=? ", 
	"AND part_code IS NOT NULL" 
	
	PREPARE s_invoicedetl FROM glob_temp_text 
	DECLARE c_invoicedetl CURSOR FOR s_invoicedetl 
	
	WHILE true 
		FOREACH c_invoicehead INTO l_rec_document.* 
			LET l_rec_document.trans_type = TRAN_TYPE_INVOICE_IN 
			LET l_rec_document.grs_amt = 0 
			LET l_rec_document.net_amt = 0 
			LET l_rec_document.cost_amt = 0 
			
			OPEN c_invoicedetl USING l_rec_document.trans_num 
			FOREACH c_invoicedetl INTO l_rec_invoicedetl.* 

				IF l_rec_invoicedetl.list_price_amt IS NULL 
				OR l_rec_invoicedetl.list_price_amt = 0 THEN 
					OPEN c_prodstatus USING l_rec_invoicedetl.ware_code, 
					l_rec_invoicedetl.part_code 
					FETCH c_prodstatus INTO l_rec_invoicedetl.list_price_amt 
					CLOSE c_prodstatus 
				END IF 
				LET l_rec_document.net_amt = l_rec_document.net_amt 
				+ l_rec_invoicedetl.ext_sale_amt 
				LET l_rec_document.cost_amt = l_rec_document.cost_amt 
				+ l_rec_invoicedetl.ext_cost_amt 
				LET l_rec_document.grs_amt = l_rec_document.grs_amt 
				+ (l_rec_invoicedetl.ship_qty * l_rec_invoicedetl.list_price_amt) 
			END FOREACH 
			LET l_rec_document.prof_amt = l_rec_document.net_amt - l_rec_document.cost_amt 
			LET l_rec_document.net_amt = l_rec_document.net_amt/l_rec_document.conv_qty 
			LET l_rec_document.grs_amt = l_rec_document.grs_amt/l_rec_document.conv_qty 
			LET l_rec_document.cost_amt = l_rec_document.cost_amt/l_rec_document.conv_qty 
			LET l_rec_document.prof_amt = l_rec_document.prof_amt/l_rec_document.conv_qty 
			LET l_rec_document.prof_amt = l_rec_document.net_amt - l_rec_document.cost_amt 
	
			INSERT INTO t_document VALUES (l_rec_document.*) 
	
			IF int_flag OR quit_flag THEN 
				EXIT WHILE 
			END IF 
		END FOREACH 

		FOR l_i = 1 TO (length(p_where_text)-15) 
			IF p_where_text[l_i,l_i+14] = "invoicehead.inv" THEN 
				LET p_where_text[l_i,l_i+14] = "credithead.cred" 
			END IF 
		END FOR 
		
		FOR l_i = 1 TO (length(p_where_text)-11) 
			IF p_where_text[l_i,l_i+10] = "invoicehead" THEN 
				LET p_where_text[l_i,l_i+10] = " credithead" 
			END IF 
		END FOR 
		
		LET l_query_text = 
		"SELECT unique credithead.cust_code, ", 
		"customer.name_text, ", 
		"customer.currency_code, ", 
		"credithead.conv_qty, ", 
		"credithead.cred_date, ", 
		"credithead.cred_num ", 
		"FROM customer,", 
		"credithead,", 
		"creditdetl,", 
		"product ", 
		"WHERE customer.cmpy_code='",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND customer.delete_flag='N' ", 
		"AND credithead.cmpy_code='",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND credithead.cust_code = customer.cust_code ", 
		"AND creditdetl.cmpy_code='",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND credithead.cred_num = creditdetl.cred_num ", 
		"AND product.cmpy_code='",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND creditdetl.part_code = product.part_code ", 
		"AND ",p_where_text CLIPPED
	
		PREPARE s_credithead FROM l_query_text 
		DECLARE c_credithead CURSOR FOR s_credithead 
		
		LET glob_temp_text = "SELECT * FROM creditdetl ", 
		"WHERE cmpy_code='",glob_rec_kandoouser.cmpy_code,"' AND cred_num=? ", 
		"AND part_code IS NOT NULL" 
		
		PREPARE s_creditdetl FROM glob_temp_text 
		DECLARE c_creditdetl CURSOR FOR s_creditdetl 
		
		FOREACH c_credithead INTO l_rec_document.* 
			LET l_rec_document.trans_type = TRAN_TYPE_CREDIT_CR 
			LET l_rec_document.grs_amt = 0 
			LET l_rec_document.net_amt = 0 
			LET l_rec_document.cost_amt = 0 
			LET l_rec_document.prof_amt = 0 
			OPEN c_creditdetl USING l_rec_document.trans_num 

			FOREACH c_creditdetl INTO l_rec_creditdetl.* 
				DISPLAY " Processing Credits " at 2,2 

				IF l_rec_creditdetl.list_amt IS NULL 
				OR l_rec_creditdetl.list_amt = 0 THEN 
					OPEN c_prodstatus USING l_rec_creditdetl.ware_code, 
					l_rec_creditdetl.part_code 
					FETCH c_prodstatus INTO l_rec_creditdetl.list_amt 
					CLOSE c_prodstatus 
				END IF 
				LET l_rec_document.net_amt = l_rec_document.net_amt 
				+ l_rec_creditdetl.ext_sales_amt 
				LET l_rec_document.cost_amt = l_rec_document.cost_amt 
				+ l_rec_creditdetl.ext_cost_amt 
				LET l_rec_document.grs_amt = l_rec_document.grs_amt 
				+ (l_rec_creditdetl.ship_qty * l_rec_creditdetl.list_amt) 
			END FOREACH 

			LET l_rec_document.prof_amt = l_rec_document.net_amt - l_rec_document.cost_amt 
			LET l_rec_document.net_amt = 0-(l_rec_document.net_amt/l_rec_document.conv_qty) 
			LET l_rec_document.grs_amt = 0-(l_rec_document.grs_amt/l_rec_document.conv_qty) 
			LET l_rec_document.cost_amt = 0-(l_rec_document.cost_amt/l_rec_document.conv_qty) 
			LET l_rec_document.prof_amt = 0-(l_rec_document.prof_amt/l_rec_document.conv_qty) 

			INSERT INTO t_document VALUES (l_rec_document.*) 

			IF int_flag OR quit_flag THEN 
				EXIT WHILE 
			END IF 
		END FOREACH 
		EXIT WHILE 
	END WHILE 

	DECLARE c_t_document CURSOR FOR 
	SELECT * FROM t_document 
	ORDER BY trans_date, 
	trans_num 
	FOREACH c_t_document INTO l_rec_document.* 
		IF l_rec_document.grs_amt = 0 THEN 
			LET l_rec_document.disc_per = 0 
		ELSE 
			LET l_rec_document.disc_per = 100 
			*(l_rec_document.grs_amt-l_rec_document.net_amt)/l_rec_document.grs_amt 
		END IF 

		#---------------------------------------------------------
		OUTPUT TO REPORT AEC_rpt_list(l_rpt_idx,l_rec_document.*)  
		IF NOT rpt_int_flag_handler2("Invoice:",l_rec_document.name_text, NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------			 
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT AEC_rpt_list
	RETURN rpt_finish("AEC_rpt_list")
	#------------------------------------------------------------
 
END FUNCTION 

############################################################
# REPORT aec_list(p_rpt_idx,p_rec_document)
#
#
############################################################
REPORT AEC_rpt_list(p_rpt_idx,p_rec_document) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_document RECORD 
		cust_code LIKE customer.cust_code, 
		name_text LIKE customer.name_text, 
		curr_code LIKE invoicehead.currency_code, 
		conv_qty LIKE invoicehead.conv_qty, 
		trans_date LIKE invoicehead.inv_date, 
		trans_num LIKE invoicehead.inv_num, 
		net_amt LIKE invoicehead.total_amt, 
		grs_amt LIKE invoicehead.total_amt, 
		cost_amt LIKE invoicehead.total_amt, 
		prof_amt LIKE invoicehead.total_amt, 
		disc_per FLOAT, 
		trans_type LIKE araudit.tran_type_ind 
	END RECORD
	DEFINE l_tot_disc FLOAT
	DEFINE l_arr_line array[4] OF CHAR(132)
	DEFINE l_div_check LIKE invoicehead.total_amt 
	DEFINE l_x SMALLINT 

	OUTPUT 
--	left margin 0 

	ORDER external BY p_rec_document.trans_date, p_rec_document.trans_num 
	
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  
			
		ON EVERY ROW 
			PRINT COLUMN 01, p_rec_document.trans_date USING "dd/mm/yy", 
			COLUMN 10, p_rec_document.trans_type, 
			COLUMN 13, p_rec_document.trans_num USING "########", 
			COLUMN 22, p_rec_document.name_text, 
			COLUMN 55, p_rec_document.net_amt USING "--,---,--$.&&", 
			COLUMN 72, p_rec_document.cost_amt USING "--,---,--$.&&", 
			COLUMN 89, p_rec_document.grs_amt USING "--,---,--$.&&", 
			COLUMN 106, p_rec_document.prof_amt USING "--,---,--$.&&", 
			COLUMN 123, p_rec_document.disc_per USING "---&.&&%" 
			
		ON LAST ROW 
			NEED 3 LINES 
			LET l_div_check = sum(p_rec_document.grs_amt) 
			IF l_div_check = 0 THEN 
				LET l_tot_disc = 0 
			ELSE 
				LET l_tot_disc = ((sum(p_rec_document.grs_amt) - sum(p_rec_document.net_amt)) / 
				l_div_check) * 100 
			END IF 
			PRINT COLUMN 01, "Report Totals: (Base Currency)", 
			COLUMN 50, "======================================", 
			" ",glob_rec_glparms.base_currency_code," ", 
			"=======================================" 
			PRINT COLUMN 52, sum (p_rec_document.net_amt) USING "-----,---,--$.&&", 
			COLUMN 69, sum (p_rec_document.cost_amt) USING "-----,---,--$.&&", 
			COLUMN 86, sum (p_rec_document.grs_amt) USING "-----,---,--$.&&", 
			COLUMN 103, sum (p_rec_document.net_amt - p_rec_document.cost_amt) 
			USING "-----,---,--$.&&", 
			COLUMN 123, l_tot_disc USING "---&.&&%" 
			SKIP 1 line 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  
			
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	
			
END REPORT 