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
# TODO: prodledg.source_code has been added in the construct, but not in the reports, to avoid conflict with the reports branch. To be added after merge
# TODO: clean code priority 1
# TODO: clean code priority 2
# TODO: clean code priority 3
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "I_IN_GLOBALS.4gl" 
GLOBALS "IA_GLOBALS.4gl" #note: this IS FOR all ia<n> programs 

############################################################
# FUNCTION IAW_main()
# RETURN VOID
#
# Purpose - Product Ledger by Warehouse Report
############################################################
FUNCTION IAW_main()

	CALL setModuleId("IAW") 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN "1" #UI/MENU Mode
			OPEN WINDOW I161 WITH FORM "I161" 
			 CALL windecoration_i("I161")
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title

			MENU "Product Ledger by Warehouse" 

				BEFORE MENU 
					CALL publish_toolbar("kandoo","IAW","menu-Product_Ledger-1") -- albo kd-505 
					CALL rpt_rmsreps_reset(NULL)
					CALL IAW_rpt_process(IAW_rpt_query())

				ON ACTION "WEB-HELP" -- albo kd-372 
					CALL onlinehelp(getmoduleid(),NULL) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar()

				ON ACTION "Report" #COMMAND "Run Report" " SELECT Criteria AND Print Report"
					CALL rpt_rmsreps_reset(NULL)
					CALL IAW_rpt_process(IAW_rpt_query())

				ON ACTION "PRINT MANAGER" --COMMAND "Print" "Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "CANCEL" --COMMAND KEY (interrupt, "E") "Exit" " Exit TO menus" 
					EXIT MENU

			END MENU
			CLOSE WINDOW I161

		WHEN "2" #Background Process with rmsreps.report_code
			CALL IAW_rpt_process(NULL)  

		WHEN "3" #Only create query-where-part
			OPEN WINDOW I161 with FORM "I161" 
			 CALL windecoration_i("I161") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(IAW_rpt_query()) #save where clause in env 
			CLOSE WINDOW I161 
			
		WHEN "4" #Background Process with SQL WHERE ARGUMENT
			CALL IAW_rpt_process(get_url_sel_text())
	END CASE

END FUNCTION 
############################################################
# END FUNCTION IAW_main() 
############################################################

############################################################
# FUNCTION IAW_rpt_query() 
# RETURN r_where_text (Query By Example)
# DataSource for the report driver with CONSTRUCT
############################################################
FUNCTION IAW_rpt_query() 
	DEFINE r_where_text LIKE rmsreps.sel_text

	MESSAGE " Enter criteria FOR selection - ESC TO begin search"

	CONSTRUCT r_where_text ON 
	prodledg.part_code, 
	product.desc_text, 
	product.desc2_text, 
	product.maingrp_code, 
	product.prodgrp_code, 
	prodledg.ware_code, 
	prodledg.tran_date, 
	prodledg.year_num, 
	prodledg.period_num, 
	prodledg.trantype_ind, 
	prodledg.source_text, 
	prodledg.source_num, 
	prodledg.tran_qty, 
	prodledg.cost_amt, 
	prodledg.sales_amt 
	FROM 
	prodledg.part_code, 
	product.desc_text, 
	product.desc2_text, 
	product.maingrp_code, 
	product.prodgrp_code, 
	prodledg.ware_code, 
	prodledg.tran_date, 
	prodledg.year_num, 
	prodledg.period_num, 
	prodledg.trantype_ind, 
	prodledg.source_text, 
	prodledg.source_num, 
	prodledg.tran_qty, 
	prodledg.cost_amt, 
	prodledg.sales_amt 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","IAW","construct-prodledg-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN NULL 
	ELSE 
		RETURN r_where_text
	END IF

END FUNCTION 
############################################################
# END FUNCTION IAW_rpt_query() 
############################################################

############################################################
# FUNCTION IAW_rpt_process(p_where_text) 
# 
# The report driver
############################################################
FUNCTION IAW_rpt_process(p_where_text)
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT
	DEFINE l_rec_prodledg RECORD LIKE prodledg.* 
	DEFINE l_prod_desc_text LIKE product.desc_text 
	DEFINE l_prod_desc2_text LIKE product.desc2_text 

	#------------------------------------------------------------
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE
		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"IAW_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	

	START REPORT IAW_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	LET l_query_text = 
	"SELECT prodledg.*,product.desc_text,product.desc2_text ", 
	"FROM prodledg,product ", 
	"WHERE prodledg.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND product.part_code = prodledg.part_code ", 
	"AND product.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND ",p_where_text CLIPPED," ", 
	"ORDER BY prodledg.ware_code,prodledg.part_code,prodledg.seq_num" 

	PREPARE choice FROM l_query_text 
	DECLARE selcurs CURSOR FOR choice 

	FOREACH selcurs INTO l_rec_prodledg.*,l_prod_desc_text,l_prod_desc2_text 
		IF l_rec_prodledg.trantype_ind = "S" OR 
			l_rec_prodledg.trantype_ind = "C" THEN 
			LET l_rec_prodledg.sales_amt = l_rec_prodledg.sales_amt * -1 
		END IF 
		#---------------------------------------------------------
		OUTPUT TO REPORT IAW_rpt_list(l_rpt_idx,l_rec_prodledg.part_code[1,9],l_rec_prodledg.*,l_prod_desc_text,l_prod_desc2_text) 
		IF NOT rpt_int_flag_handler2("Product: ",l_rec_prodledg.part_code,"",l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT IAW_rpt_list
	RETURN rpt_finish("IAW_rpt_list")
	#------------------------------------------------------------

END FUNCTION
############################################################
# END FUNCTION IAW_rpt_process() 
############################################################ 

############################################################
# REPORT IAW_rpt_list(p_rpt_idx,p_part_code,p_rec_prodledg,p_prod_desc_text,p_prod_desc2_text)
#
# Report Definition/Layout
############################################################
REPORT IAW_rpt_list(p_rpt_idx,p_part_code,p_rec_prodledg,p_prod_desc_text,p_prod_desc2_text)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_part_code LIKE product.part_code 
	DEFINE p_rec_prodledg RECORD LIKE prodledg.* 
	DEFINE p_prod_desc_text LIKE product.desc_text 
	DEFINE p_prod_desc2_text LIKE product.desc2_text 
	DEFINE l_factor DECIMAL(2) 
	DEFINE l_rec_warehouse RECORD LIKE warehouse.* 

	ORDER EXTERNAL BY p_rec_prodledg.ware_code,p_part_code,p_rec_prodledg.part_code,p_rec_prodledg.seq_num 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,PAGENO) #update page number and report header LINE 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 CLIPPED #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 CLIPPED #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text CLIPPED 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text CLIPPED 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]

	BEFORE GROUP OF p_part_code 
		SKIP 1 LINE 

	BEFORE GROUP OF p_rec_prodledg.part_code 
		SKIP 1 LINE 
		PRINT COLUMN 1, "Product: ", p_rec_prodledg.part_code CLIPPED," (", p_prod_desc_text CLIPPED,p_prod_desc2_text CLIPPED, ")" 

	BEFORE GROUP OF p_rec_prodledg.ware_code 
		SKIP TO TOP OF PAGE 
		SELECT warehouse.desc_text INTO l_rec_warehouse.desc_text FROM warehouse 
		WHERE warehouse.cmpy_code = p_rec_prodledg.cmpy_code AND 
				warehouse.ware_code = p_rec_prodledg.ware_code 
		PRINT COLUMN 01, "Warehouse: ", p_rec_prodledg.ware_code CLIPPED," (", l_rec_warehouse.desc_text CLIPPED, ")" 
		SKIP 1 LINE 

	ON EVERY ROW 
		IF p_rec_prodledg.sales_amt < 0 THEN 
			LET p_rec_prodledg.sales_amt = p_rec_prodledg.sales_amt * -1 
			LET l_factor = -1 
		ELSE 
			LET l_factor = 1 
		END IF 
		PRINT COLUMN 1, p_rec_prodledg.tran_date                                       USING "dd/mm/yy", 
		COLUMN 10, p_rec_prodledg.year_num                                             USING "###&", 
		COLUMN 15, p_rec_prodledg.period_num                                           USING "##&", 
		COLUMN 19, p_rec_prodledg.trantype_ind CLIPPED, 
		COLUMN 21, p_rec_prodledg.source_text CLIPPED, 
		COLUMN 30, p_rec_prodledg.source_num                                           USING "#######&", 
		COLUMN 39, p_rec_prodledg.tran_qty                                             USING "----,---,---,--&.&", 
		COLUMN 58, p_rec_prodledg.cost_amt                                             USING "-,---,---,--&.&&&&", 
		COLUMN 77, p_rec_prodledg.cost_amt * p_rec_prodledg.tran_qty                   USING "---,---,---,--&.&&", 
		COLUMN 96, p_rec_prodledg.sales_amt                                            USING "-,---,---,--&.&&&&", 
		COLUMN 115,((p_rec_prodledg.sales_amt * l_factor) * p_rec_prodledg.tran_qty)   USING "---,---,---,--&.&&" 

	AFTER GROUP OF p_rec_prodledg.ware_code 
		NEED 2 LINES 
		PRINT COLUMN 45,"--------------------------------------", 
		"--------------------------------------------------" 
		PRINT COLUMN 1, "Warehouse Total: ", p_rec_prodledg.ware_code CLIPPED, 
		COLUMN 39, NVL(GROUP SUM(p_rec_prodledg.tran_qty),0)		                      USING "----,---,---,--&.&", 
		COLUMN 77, NVL(GROUP SUM(p_rec_prodledg.cost_amt * p_rec_prodledg.tran_qty),0) USING "---,---,---,--&.&&", 
		COLUMN 115,NVL(GROUP SUM(p_rec_prodledg.sales_amt * p_rec_prodledg.tran_qty),0)USING "---,---,---,--&.&&" 

	AFTER GROUP OF p_rec_prodledg.part_code 
		NEED 2 LINES 
		PRINT COLUMN 45,"======================================", 
		"==================================================" 
		PRINT COLUMN 5, "Product Total: ", p_rec_prodledg.part_code, 
		COLUMN 39, NVL(GROUP SUM(p_rec_prodledg.tran_qty),0)		                      USING "---,---,---,---&.&", 
		COLUMN 77, NVL(GROUP SUM(p_rec_prodledg.cost_amt * p_rec_prodledg.tran_qty),0) USING "---,---,---,--&.&&", 
		COLUMN 115,NVL(GROUP SUM(p_rec_prodledg.sales_amt * p_rec_prodledg.tran_qty),0)USING "---,---,---,--&.&&" 

	AFTER GROUP OF p_part_code 
		NEED 2 LINES 
		PRINT COLUMN 45,"======================================", 
		"==================================================" 
		PRINT COLUMN 3, "Product Total: ", p_part_code, 
		COLUMN 39, NVL(GROUP SUM(p_rec_prodledg.tran_qty),0) 	                         USING "----,---,---,--&.&", 
		COLUMN 77, NVL(GROUP SUM(p_rec_prodledg.cost_amt * p_rec_prodledg.tran_qty),0) USING "---,---,---,--&.&&", 
		COLUMN 115,NVL(GROUP SUM(p_rec_prodledg.sales_amt * p_rec_prodledg.tran_qty),0)USING "---,---,---,--&.&&" 

	ON LAST ROW 
		NEED 9 LINES 
		SKIP 2 LINES 
		PRINT COLUMN 45,"--------------------------------------", 
		"--------------------------------------------------" 
		PRINT COLUMN 1, "Report Total:", 
		COLUMN 39, NVL(SUM(p_rec_prodledg.tran_qty),0)                                 USING "----,---,---,--&.&", 
		COLUMN 77, NVL(SUM(p_rec_prodledg.cost_amt * p_rec_prodledg.tran_qty),0)       USING "---,---,---,--&.&&", 
		COLUMN 115,NVL(SUM(p_rec_prodledg.sales_amt * p_rec_prodledg.tran_qty),0)      USING "---,---,---,--&.&&" 
		SKIP 2 LINES 
		#End Of Report
		IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
			PRINT COLUMN 01,"Selection Criteria:" 
			PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text CLIPPED WORDWRAP RIGHT MARGIN 100 
		END IF 
		PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report 			
		LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = PAGENO

END REPORT 
