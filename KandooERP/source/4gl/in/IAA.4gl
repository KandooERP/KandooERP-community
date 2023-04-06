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

#KandooERP runs on Querix Lycia www.querix.com
#Adapted by eric@begooden.it,hoelzl@querix.com,a.bondar@querix.com

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl"
GLOBALS "../common/glob_GLOBALS_report.4gl" 
GLOBALS "I_IN_GLOBALS.4gl"

############################################################
# FUNCTION IAA_main()
# RETURN VOID
#
# Purpose - Product History Report
############################################################
FUNCTION IAA_main()

	CALL setModuleId("IAA") 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN "1" #UI/MENU Mode
			OPEN WINDOW I111 WITH FORM "I111" 
			 CALL windecoration_i("I111")
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title
			
			MENU "Product Relationship Report" 

				BEFORE MENU 
					CALL publish_toolbar("kandoo","IAA","menu-Product_Report-1") -- albo kd-505 
					CALL rpt_rmsreps_reset(NULL)
					CALL IAA_rpt_process(IAA_rpt_query())

				ON ACTION "WEB-HELP" -- albo kd-372 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar()

				ON ACTION "Report" #COMMAND "Run Report" " SELECT Criteria AND Print Report"
					CALL rpt_rmsreps_reset(NULL)
					CALL IAA_rpt_process(IAA_rpt_query())

				ON ACTION "PRINT MANAGER" --COMMAND "Print" "Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "CANCEL" --COMMAND KEY (interrupt, "E") "Exit" " Exit TO menus" 
					EXIT MENU

			END MENU
			CLOSE WINDOW I111

		WHEN "2" #Background Process with rmsreps.report_code
			CALL IAA_rpt_process(NULL)  

		WHEN "3" #Only create query-where-part
			OPEN WINDOW I111 with FORM "I111" 
			 CALL windecoration_i("I111") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(IAA_rpt_query()) #save where clause in env 
			CLOSE WINDOW I111 
			
		WHEN "4" #Background Process with SQL WHERE ARGUMENT
			CALL IAA_rpt_process(get_url_sel_text())
	END CASE	

END FUNCTION 
############################################################
# END FUNCTION IAA_main() 
############################################################

############################################################
# FUNCTION IAA_rpt_query() 
# RETURN r_where_text (Query By Example)
# DataSource for the report driver with CONSTRUCT
############################################################
FUNCTION IAA_rpt_query() 
	DEFINE r_where_text LIKE rmsreps.sel_text

	MESSAGE " Enter criteria FOR selection - ESC TO begin search"

	CONSTRUCT r_where_text ON 
	prodhist.part_code, 
	product.desc_text, 
	prodhist.ware_code, 
	warehouse.desc_text, 
	product.maingrp_code, 
	product.prodgrp_code, 
	prodhist.year_num, 
	prodhist.period_num, 
	prodhist.start_qty, 
	prodhist.end_qty, 
	prodhist.gross_per, 
	prodhist.stock_turn_qty, 
	prodhist.sales_qty, 
	prodhist.sales_amt, 
	prodhist.credit_qty, 
	prodhist.credit_amt, 
	prodhist.pur_qty, 
	prodhist.pur_amt, 
	prodhist.transin_qty, 
	prodhist.transin_amt, 
	prodhist.transout_qty, 
	prodhist.transout_amt, 
	prodhist.adj_qty, 
	prodhist.adj_amt 
	FROM 
	prodhist.part_code, 
	product.desc_text, 
	prodhist.ware_code, 
	warehouse.desc_text, 
	product.maingrp_code, 
	product.prodgrp_code, 
	prodhist.year_num, 
	prodhist.period_num, 
	prodhist.start_qty, 
	prodhist.end_qty, 
	prodhist.gross_per, 
	prodhist.stock_turn_qty, 
	prodhist.sales_qty, 
	prodhist.sales_amt, 
	prodhist.credit_qty, 
	prodhist.credit_amt, 
	prodhist.pur_qty, 
	prodhist.pur_amt, 
	prodhist.transin_qty, 
	prodhist.transin_amt, 
	prodhist.transout_qty, 
	prodhist.transout_amt, 
	prodhist.adj_qty, 
	prodhist.adj_amt 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","IAA","construct-prodhist-1") -- albo kd-505 

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
# END FUNCTION IAA_rpt_query() 
############################################################

############################################################
# FUNCTION IAA_rpt_process(p_where_text) 
# 
# The report driver
############################################################
FUNCTION IAA_rpt_process(p_where_text)
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT
	DEFINE l_rec_prodhist RECORD LIKE prodhist.* 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_rec_warehouse RECORD LIKE warehouse.*

	#------------------------------------------------------------
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE
		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"IAA_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	

	START REPORT IAA_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	LET l_query_text = 
	"SELECT prodhist.*,product.*,warehouse.* ", 
	"FROM prodhist,product,warehouse ", 
	"WHERE prodhist.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND product.cmpy_code = prodhist.cmpy_code ", 
	"AND warehouse.cmpy_code = prodhist.cmpy_code ", 
	"AND product.part_code = prodhist.part_code ", 
	"AND warehouse.ware_code = prodhist.ware_code ", 
	"AND ",p_where_text CLIPPED," ", 
	"ORDER BY prodhist.part_code,prodhist.ware_code,prodhist.year_num,prodhist.period_num" 

	PREPARE choice FROM l_query_text 
	DECLARE selcurs CURSOR FOR choice 

	FOREACH selcurs INTO l_rec_prodhist.*,l_rec_product.*,l_rec_warehouse.* 
		#---------------------------------------------------------
		OUTPUT TO REPORT IAA_rpt_list(l_rpt_idx,l_rec_prodhist.*,l_rec_product.*,l_rec_warehouse.*) 
		IF NOT rpt_int_flag_handler2("Product: ",l_rec_product.part_code,"",l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT IAA_rpt_list
	RETURN rpt_finish("IAA_rpt_list")
	#------------------------------------------------------------

END FUNCTION 
############################################################
# END FUNCTION IAA_rpt_process() 
############################################################

############################################################
# REPORT IAA_rpt_list(p_rpt_idx,p_rec_prodhist,p_rec_product,p_rec_warehouse)
#
# Report Definition/Layout
############################################################
REPORT IAA_rpt_list(p_rpt_idx,p_rec_prodhist,p_rec_product,p_rec_warehouse)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_prodhist RECORD LIKE prodhist.* 
	DEFINE p_rec_product RECORD LIKE product.* 
	DEFINE p_rec_warehouse RECORD LIKE warehouse.* 

	ORDER EXTERNAL BY p_rec_prodhist.part_code,p_rec_prodhist.ware_code,p_rec_prodhist.year_num,p_rec_prodhist.period_num 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,PAGENO) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 CLIPPED #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 CLIPPED #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text CLIPPED 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text CLIPPED 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]

	BEFORE GROUP OF p_rec_prodhist.part_code 
		#   skip TO top of page
		NEED 7 LINES #including GROUP ware_code AND AFTER ROW 
		SKIP 2 LINES 
		PRINT COLUMN 1, p_rec_prodhist.part_code CLIPPED, " ", 
		"(", p_rec_product.desc_text CLIPPED, ")" 

	BEFORE GROUP OF p_rec_prodhist.ware_code 
		NEED 4 LINES #including AFTER ROW 
		SKIP 1 LINE 
		PRINT COLUMN 5, p_rec_prodhist.ware_code CLIPPED, " ", 
		"(", p_rec_warehouse.desc_text CLIPPED, ")" 
		SKIP 1 LINE

	ON EVERY ROW 
		PRINT COLUMN 20, p_rec_prodhist.year_num USING "###&", 
		COLUMN 25, p_rec_prodhist.period_num     USING "##&", 
		COLUMN 29, p_rec_prodhist.sales_amt      USING "---,---,--&.&&", 
		COLUMN 44, p_rec_prodhist.credit_amt     USING "---,---,--&.&&", 
		COLUMN 59, p_rec_prodhist.reclassout_amt USING "---,---,--&.&&", 
		COLUMN 74, p_rec_prodhist.reclassin_amt  USING "---,---,--&.&&", 
		COLUMN 89, p_rec_prodhist.pur_amt        USING "---,---,--&.&&", 
		COLUMN 104,p_rec_prodhist.transin_amt    USING "---,---,--&.&&", 
		COLUMN 119,p_rec_prodhist.transout_amt   USING "---,---,--&.&&" 
 
	AFTER GROUP OF p_rec_prodhist.year_num 
		NEED 2 LINES 
		PRINT COLUMN 29, "----------------------------------------", 
		"----------------------------------------", 
		"------------------------" 
		PRINT COLUMN 10, "Year Total: ", 
		COLUMN 29, NVL(GROUP SUM(p_rec_prodhist.sales_amt),0)  	  USING "---,---,--&.&&", 
		COLUMN 44, NVL(GROUP SUM(p_rec_prodhist.credit_amt),0)	  USING "---,---,--&.&&", 
		COLUMN 59, NVL(GROUP SUM(p_rec_prodhist.reclassout_amt),0) USING "---,---,--&.&&", 
		COLUMN 74, NVL(GROUP SUM(p_rec_prodhist.reclassin_amt),0)  USING "---,---,--&.&&", 
		COLUMN 89, NVL(GROUP SUM(p_rec_prodhist.pur_amt),0)        USING "---,---,--&.&&", 
		COLUMN 104,NVL(GROUP SUM(p_rec_prodhist.transin_amt),0)    USING "---,---,--&.&&", 
		COLUMN 119,NVL(GROUP SUM(p_rec_prodhist.transout_amt),0)   USING "---,---,--&.&&" 

	AFTER GROUP OF p_rec_prodhist.ware_code 
		NEED 2 LINES 
		PRINT COLUMN 29, "----------------------------------------", 
		"----------------------------------------", 
		"------------------------" 
		PRINT COLUMN 5, "Warehouse Total: ", 
		COLUMN 29, NVL(GROUP SUM(p_rec_prodhist.sales_amt),0) 	  USING "---,---,--&.&&", 
		COLUMN 44, NVL(GROUP SUM(p_rec_prodhist.credit_amt),0)	  USING "---,---,--&.&&", 
		COLUMN 59, NVL(GROUP SUM(p_rec_prodhist.reclassout_amt),0) USING "---,---,--&.&&", 
		COLUMN 74, NVL(GROUP SUM(p_rec_prodhist.reclassin_amt),0)  USING "---,---,--&.&&", 
		COLUMN 89, NVL(GROUP SUM(p_rec_prodhist.pur_amt),0) 		  USING "---,---,--&.&&", 
		COLUMN 104,NVL(GROUP SUM(p_rec_prodhist.transin_amt),0)	  USING "---,---,--&.&&", 
		COLUMN 119,NVL(GROUP SUM(p_rec_prodhist.transout_amt),0)	  USING "---,---,--&.&&" 

	AFTER GROUP OF p_rec_prodhist.part_code 
		NEED 2 LINES 
		PRINT COLUMN 29, "----------------------------------------", 
		"----------------------------------------", 
		"------------------------" 
		PRINT COLUMN 1, "Product Total: ", 
		COLUMN 29, NVL(GROUP SUM(p_rec_prodhist.sales_amt),0)		  USING "---,---,--&.&&", 
		COLUMN 44, NVL(GROUP SUM(p_rec_prodhist.credit_amt),0)	  USING "---,---,--&.&&", 
		COLUMN 59, NVL(GROUP SUM(p_rec_prodhist.reclassout_amt),0) USING "---,---,--&.&&", 
		COLUMN 74, NVL(GROUP SUM(p_rec_prodhist.reclassin_amt),0)  USING "---,---,--&.&&", 
		COLUMN 89, NVL(GROUP SUM(p_rec_prodhist.pur_amt),0) 		  USING "---,---,--&.&&", 
		COLUMN 104,NVL(GROUP SUM(p_rec_prodhist.transin_amt),0)	  USING "---,---,--&.&&", 
		COLUMN 119,NVL(GROUP SUM(p_rec_prodhist.transout_amt),0)	  USING "---,---,--&.&&" 

	ON LAST ROW 
		NEED 8 LINES 
		SKIP 1 LINE 
		PRINT COLUMN 1, "Report Total:", 
		COLUMN 29, NVL(SUM(p_rec_prodhist.sales_amt),0) 	  USING "---,---,--&.&&", 
		COLUMN 44, NVL(SUM(p_rec_prodhist.credit_amt),0)	  USING "---,---,--&.&&", 
		COLUMN 59, NVL(SUM(p_rec_prodhist.reclassout_amt),0) USING "---,---,--&.&&", 
		COLUMN 74, NVL(SUM(p_rec_prodhist.reclassin_amt),0)  USING "---,---,--&.&&", 
		COLUMN 89, NVL(SUM(p_rec_prodhist.pur_amt),0) 		  USING "---,---,--&.&&", 
		COLUMN 104,NVL(SUM(p_rec_prodhist.transin_amt),0)	  USING "---,---,--&.&&", 
		COLUMN 119,NVL(SUM(p_rec_prodhist.transout_amt),0)	  USING "---,---,--&.&&" 
		SKIP 2 LINES 
		#End Of Report
		IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
			PRINT COLUMN 01,"Selection Criteria:" 
			PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text CLIPPED WORDWRAP RIGHT MARGIN 100 
		END IF 
		PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report 			
		LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = PAGENO

END REPORT 
