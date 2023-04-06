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
GLOBALS "../ar/ADE_GLOBALS.4gl"
############################################################
# MODULE Scope Variables
############################################################
DEFINE modu_tot_amt DECIMAL(16,2) #Will be incremented/added in actual report block 
#####################################################################
# FUNCTION ADE_main()
#
# ADE Credit Detail Report
#####################################################################
FUNCTION ADE_main() 
	DEFER interrupt 
	DEFER quit 
	
	CALL setModuleId("ADE") 
	CALL ADE_main()

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 	
			OPEN WINDOW A215 WITH FORM "A215" 
			CALL windecoration_a("A215") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title
		
			MENU "Credit Detail Rpt" 
		
				BEFORE MENU 
					CALL publish_toolbar("kandoo","ADE","menu-credit-detail-rep") 
					CALL ADE_rpt_process(ADE_rpt_query())
					
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				ON ACTION "Report" #COMMAND "Run Report" " SELECT criteria AND PRINT REPORT"
					CALL ADE_rpt_process(ADE_rpt_query())
		
				ON ACTION "Print Manager" #COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "Exit" #COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus"
					EXIT MENU 
		
			END MENU 
		
			CLOSE WINDOW A215
	 
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL ADE_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW A215 with FORM "A215" 
			CALL windecoration_a("A215") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(ADE_rpt_query()) #save where clause in env 
			CLOSE WINDOW A215 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL ADE_rpt_process(get_url_sel_text())
	END CASE 	
		 
END FUNCTION 


#####################################################################
# FUNCTION ADE_rpt_query()
#
#
#####################################################################
FUNCTION ADE_rpt_query() 
	DEFINE l_where_text STRING

	CLEAR FORM 

	MESSAGE " Enter Selection Criteria - ESC TO Continue" attribute(yellow) 

	CONSTRUCT BY NAME l_where_text ON creditdetl.cred_num, 
	creditdetl.cust_code, 
	customer.name_text, 
	creditdetl.ware_code, 
	customer.currency_code, 
	credithead.total_amt, 
	creditdetl.part_code, 
	creditdetl.ship_qty, 
	creditdetl.line_text, 
	creditdetl.line_total_amt 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","ADE","construct-creditdetl") 

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
# FUNCTION ADE_rpt_process(p_where_text)
#
#
#####################################################################
FUNCTION ADE_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT   
	
	DEFINE l_rec_creditdetl RECORD 
		cust_code LIKE creditdetl.cust_code, 
		name_text LIKE customer.name_text, 
		currency_code LIKE customer.currency_code, 
		cred_num LIKE creditdetl.cred_num, 
		line_num LIKE creditdetl.line_num, 
		part_code LIKE creditdetl.part_code, 
		ware_code LIKE creditdetl.ware_code, 
		ship_qty LIKE creditdetl.ship_qty, 
		line_text LIKE creditdetl.line_text, 
		uom_code LIKE creditdetl.uom_code, 
		unit_sales_amt LIKE creditdetl.unit_sales_amt, 
		ext_sales_amt LIKE creditdetl.ext_sales_amt, 
		unit_tax_amt LIKE creditdetl.unit_tax_amt, 
		ext_tax_amt LIKE creditdetl.ext_tax_amt, 

		cred_date LIKE credithead.cred_date, 

		line_total_amt LIKE creditdetl.line_total_amt, 
		price_uom_code LIKE creditdetl.price_uom_code 
	END RECORD 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"ADE_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT ADE_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------


	LET modu_tot_amt = 0 
	LET glob_tot_amt1 = 0 
	LET glob_tot_amt2 = 0 
	LET glob_tot_appl = 0 

	LET l_query_text = 
	"SELECT creditdetl.cust_code,", 
	"customer.name_text,", 
	"customer.currency_code,", 
	"creditdetl.cred_num,", 
	"creditdetl.line_num,", 
	"creditdetl.part_code, ", 
	"creditdetl.ware_code,", 
	"creditdetl.ship_qty, ", 
	"creditdetl.line_text,", 
	"creditdetl.uom_code,", 
	"creditdetl.unit_sales_amt,", 
	"creditdetl.ext_sales_amt,", 
	"creditdetl.unit_tax_amt,", 
	"creditdetl.ext_tax_amt,", 
	"credithead.cred_date,", 
	"line_total_amt, ", 
	"price_uom_code ", 
	"FROM creditdetl,", 
	"credithead,", 
	"customer ", 
	"WHERE creditdetl.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND credithead.cmpy_code = creditdetl.cmpy_code ", 
	"AND customer.cmpy_code = creditdetl.cmpy_code ", 
	"AND customer.cust_code = creditdetl.cust_code ", 
	"AND credithead.cred_num = creditdetl.cred_num ", 
	"AND ",glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ADE_rpt_list")].sel_text clipped," ", 
	" ORDER BY creditdetl.cust_code,", 
	"creditdetl.cred_num,", 
	"creditdetl.line_num" 
	
	PREPARE s_credit FROM l_query_text 
	DECLARE c_credit CURSOR FOR s_credit 

	FOREACH c_credit INTO l_rec_creditdetl.* 
		#---------------------------------------------------------
		OUTPUT TO REPORT ADE_rpt_list(l_rpt_idx,l_rec_creditdetl.*)  
		IF NOT rpt_int_flag_handler2("Credit :",l_rec_creditdetl.cred_num , l_rec_creditdetl.cust_code,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------	
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT ADE_rpt_list
	CALL rpt_finish("ADE_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
	RETURN true 
END FUNCTION 

#####################################################################
# REPORT ade_list(p_rpt_idx,p_rec_creditdetl)
#
#
#####################################################################
REPORT ade_list(p_rpt_idx,p_rec_creditdetl)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx] 
	DEFINE p_rec_creditdetl RECORD 
		cust_code LIKE creditdetl.cust_code, 
		name_text LIKE customer.name_text, 
		currency_code LIKE customer.currency_code, 
		cred_num LIKE creditdetl.cred_num, 
		line_num LIKE creditdetl.line_num, 
		part_code LIKE creditdetl.part_code, 
		ware_code LIKE creditdetl.ware_code, 
		ship_qty LIKE creditdetl.ship_qty, 
		line_text LIKE creditdetl.line_text, 
		uom_code LIKE creditdetl.uom_code, 
		unit_sales_amt LIKE creditdetl.unit_sales_amt, 
		ext_sales_amt LIKE creditdetl.ext_sales_amt, 
		unit_tax_amt LIKE creditdetl.unit_tax_amt, 
		ext_tax_amt LIKE creditdetl.ext_tax_amt, 

		cred_date LIKE credithead.cred_date, 
		line_total_amt LIKE creditdetl.line_total_amt, 
		price_uom_code LIKE creditdetl.price_uom_code 
	END RECORD 
	DEFINE l_len INTEGER 
	DEFINE l_s INTEGER 
	DEFINE l_conversion_qty FLOAT 

	OUTPUT 
--	left margin 0 
	ORDER external BY p_rec_creditdetl.cust_code, p_rec_creditdetl.cred_num, 
	p_rec_creditdetl.line_num 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  

			PRINT COLUMN 1, "Line", 
			COLUMN 8, "Product", 
			COLUMN 22, "Credited", 
			COLUMN 42, "Description", 
			COLUMN 64, "Unit", 
			COLUMN 69, "Unit Price", 
			COLUMN 81, "Extended", 
			COLUMN 105,"Extended", 
			COLUMN 117,"Line Total" 
			
			PRINT COLUMN 2,"No. ", 
			COLUMN 10,"ID", 
			COLUMN 24,"Qty", 
			COLUMN 82,"Price", 
			COLUMN 106,"Tax"
			 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		BEFORE GROUP OF p_rec_creditdetl.cust_code 
			PRINT COLUMN 1, "Customer Code: ",p_rec_creditdetl.cust_code, 
			COLUMN 28, p_rec_creditdetl.name_text," Currency ", 
			p_rec_creditdetl.currency_code 
			SKIP 1 line 

		BEFORE GROUP OF p_rec_creditdetl.cred_num 
			PRINT COLUMN 5, "Credit: ",p_rec_creditdetl.cred_num USING "########" 

		ON EVERY ROW 
			IF glob_rec_company.module_text[23] = "W" 
			AND p_rec_creditdetl.price_uom_code IS NOT NULL THEN 
				IF p_rec_creditdetl.price_uom_code != p_rec_creditdetl.uom_code THEN 
					LET l_conversion_qty = get_uom_conversion_factor(glob_rec_kandoouser.cmpy_code, p_rec_creditdetl.part_code, 
					p_rec_creditdetl.uom_code, 
					p_rec_creditdetl.price_uom_code,1) 
					IF l_conversion_qty <= 0 THEN 
						LET p_rec_creditdetl.unit_sales_amt = NULL 
					ELSE 
						LET p_rec_creditdetl.unit_sales_amt 
						= p_rec_creditdetl.unit_sales_amt * l_conversion_qty 
					END IF 
				END IF 
			END IF 
			PRINT COLUMN 1, p_rec_creditdetl.line_num USING "###", 
			COLUMN 5, p_rec_creditdetl.part_code, 
			COLUMN 22, p_rec_creditdetl.ship_qty USING "######.##", 
			COLUMN 32, p_rec_creditdetl.line_text, 
			COLUMN 64, p_rec_creditdetl.uom_code, 
			COLUMN 69, p_rec_creditdetl.unit_sales_amt USING "-----$.&&", 
			COLUMN 79, p_rec_creditdetl.ext_sales_amt USING "-----,--$.&&", 
			COLUMN 103, p_rec_creditdetl.ext_tax_amt USING "-----,--$.&&", 
			COLUMN 117, p_rec_creditdetl.line_total_amt USING "-------,--$.&&" 
			LET modu_tot_amt = modu_tot_amt 
			+ conv_currency(p_rec_creditdetl.ext_sales_amt, glob_rec_kandoouser.cmpy_code, 
			p_rec_creditdetl.currency_code, "F", 
			p_rec_creditdetl.cred_date, "l_s") 
			LET glob_tot_amt1 = glob_tot_amt1 
			+ conv_currency(p_rec_creditdetl.ext_tax_amt, glob_rec_kandoouser.cmpy_code, 
			p_rec_creditdetl.currency_code, "F", 
			p_rec_creditdetl.cred_date, "l_s") 
			LET glob_tot_amt2 = glob_tot_amt2 
			+ conv_currency(p_rec_creditdetl.line_total_amt, glob_rec_kandoouser.cmpy_code, 
			p_rec_creditdetl.currency_code, "F", 
			p_rec_creditdetl.cred_date, "l_s") 

		AFTER GROUP OF p_rec_creditdetl.cred_num 
			PRINT COLUMN 78, "-------------", 
			COLUMN 102, "-------------", 
			COLUMN 118, "-------------" 
			PRINT COLUMN 78, GROUP sum(p_rec_creditdetl.ext_sales_amt) 
			USING "--,---,--$.&&", 
			COLUMN 102, GROUP sum(p_rec_creditdetl.ext_tax_amt) 
			USING "--,---,--$.&&", 
			COLUMN 118, GROUP sum(p_rec_creditdetl.line_total_amt) 
			USING "--,---,--$.&&" 
		AFTER GROUP OF p_rec_creditdetl.cust_code 
			PRINT COLUMN 78, "=============", 
			COLUMN 102, "=============", 
			COLUMN 118, "=============" 
			PRINT COLUMN 78, GROUP sum(p_rec_creditdetl.ext_sales_amt) 
			USING "--,---,--$.&&", 
			COLUMN 102, GROUP sum(p_rec_creditdetl.ext_tax_amt) 
			USING "--,---,--$.&&", 
			COLUMN 118, GROUP sum(p_rec_creditdetl.line_total_amt) 
			USING "--,---,--$.&&" 
		ON LAST ROW 
			SKIP 1 line 
			PRINT COLUMN 2, "Report Totals In Base Currency" 
			PRINT COLUMN 10,"Total Lines: ", count(*) USING "###", 
			COLUMN 78, modu_tot_amt USING "--,---,--$.&&", 
			COLUMN 102, glob_tot_amt1 USING "--,---,--$.&&", 
			COLUMN 116, glob_tot_amt2 USING "----,---,--$.&&" 
			LET modu_tot_amt = 0 
			LET glob_tot_amt1 = 0 
			LET glob_tot_amt2 = 0 
			SKIP 1 line 

			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	
			

END REPORT 


