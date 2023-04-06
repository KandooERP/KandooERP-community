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

#	Source code beautified by beautify.pl on 2020-01-03 09:12:31	$Id: $

#KandooERP runs on Querix Lycia www.querix.com
#Adapted by eric@begooden.it,hoelzl@querix.com,a.bondar@querix.com

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl" 
GLOBALS "I_IN_GLOBALS.4gl" 

############################################################
# FUNCTION IC1_main()
#
# Purpose - Product Pricing Report
############################################################
FUNCTION IC1_main()

	CALL setModuleId("IC1") 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN "1" #UI/MENU Mode
			OPEN WINDOW I162 WITH FORM "I162" 
			 CALL windecoration_i("I162")
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title
			
			MENU "Product Pricing" 

				BEFORE MENU 
					CALL publish_toolbar("kandoo","IC1","menu-Product_Pricing-1") -- albo kd-505
					CALL rpt_rmsreps_reset(NULL)
					CALL IC1_rpt_process(IC1_rpt_query())

				ON ACTION "WEB-HELP" -- albo kd-372 
					CALL onlinehelp(getmoduleid(),NULL) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar()

				ON ACTION "Report" #COMMAND "Run Report" " SELECT Criteria AND Print Report"
					CALL rpt_rmsreps_reset(NULL)
					CALL IC1_rpt_process(IC1_rpt_query())

				ON ACTION "PRINT MANAGER" --COMMAND "Print" "Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "CANCEL" --COMMAND KEY (interrupt, "E") "Exit" " Exit TO menus" 
					EXIT MENU

			END MENU
			CLOSE WINDOW I162

		WHEN "2" #Background Process with rmsreps.report_code
			CALL IC1_rpt_process(NULL)  

		WHEN "3" #Only create query-where-part
			OPEN WINDOW I162 with FORM "I162" 
			 CALL windecoration_i("I162") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(IC1_rpt_query()) #save where clause in env 
			CLOSE WINDOW I162 
			
		WHEN "4" #Background Process with SQL WHERE ARGUMENT
			CALL IC1_rpt_process(get_url_sel_text())
	END CASE

END FUNCTION
############################################################
# FUNCTION IC1_main()
############################################################

#####################################################################
# FUNCTION IC1_rpt_query()
# RETURN r_where_text (Query By Example)
# DataSource for the report driver with CONSTRUCT
#####################################################################
FUNCTION IC1_rpt_query() 
	DEFINE r_where_text LIKE rmsreps.sel_text

	MESSAGE " Enter criteria FOR selection - ESC TO begin search"

	CONSTRUCT BY NAME r_where_text ON 
	prodstatus.part_code, 
	product.desc_text, 
	product.desc2_text, 
	product.maingrp_code, 
	product.prodgrp_code, 
	prodstatus.status_ind, 
	prodstatus.ware_code, 
	prodstatus.onhand_qty, 
	prodstatus.reserved_qty, 
	prodstatus.back_qty, 
	prodstatus.forward_qty, 
	prodstatus.onord_qty, 
	prodstatus.bin1_text, 
	prodstatus.bin2_text, 
	prodstatus.bin3_text, 
	prodstatus.last_sale_date, 
	prodstatus.last_receipt_date, 
	prodstatus.stocked_flag, 
	prodstatus.stockturn_qty, 
	prodstatus.abc_ind 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","IC1","construct-prodstatus-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),NULL) 

	END CONSTRUCT
	 
	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN NULL
	ELSE
		RETURN r_where_text
	END IF 

END FUNCTION 
#####################################################################
# END FUNCTION IC1_rpt_query()
#####################################################################

#####################################################################
# FUNCTION IC1_rpt_process(p_where_text) 
#
# The report driver
#####################################################################
FUNCTION IC1_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT   
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.*
	DEFINE l_rec_product RECORD LIKE product.* 

	#------------------------------------------------------------
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"IC1_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	

	START REPORT IC1_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	LET l_query_text = 
	"SELECT prodstatus.*,product.* ",
	"FROM prodstatus,product ", 
	"WHERE prodstatus.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND product.cmpy_code = prodstatus.cmpy_code ", 
	"AND product.part_code = prodstatus.part_code ", 
	"AND ", p_where_text CLIPPED," ",	
	"ORDER BY prodstatus.part_code,prodstatus.ware_code" 

	PREPARE s_product FROM l_query_text 
	DECLARE c_product CURSOR FOR s_product 

	FOREACH c_product INTO l_rec_prodstatus.*,l_rec_product.* 
		#---------------------------------------------------------
		OUTPUT TO REPORT IC1_rpt_list(l_rpt_idx,l_rec_prodstatus.*,l_rec_product.*) 
		IF NOT rpt_int_flag_handler2("Product: ",l_rec_product.part_code,"",l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------	
	END FOREACH 
	 
	#------------------------------------------------------------
	FINISH REPORT IC1_rpt_list
	RETURN rpt_finish("IC1_rpt_list")
	#------------------------------------------------------------

END FUNCTION 
#####################################################################
# END FUNCTION IC1_rpt_process(p_where_text) 
#####################################################################

#####################################################################
# REPORT IC1_rpt_list(p_rpt_idx,p_rec_prodstatus,p_rec_product)
#
# Report Definition/Layout
#####################################################################
REPORT IC1_rpt_list(p_rpt_idx,p_rec_prodstatus,p_rec_product) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_prodstatus RECORD LIKE prodstatus.* 
	DEFINE p_rec_product RECORD LIKE product.* 
	DEFINE l_rec_warehouse RECORD LIKE warehouse.* 
	DEFINE l_rec_uom RECORD LIKE uom.* 
	DEFINE l_conv_rate LIKE uomconv.conversion_qty 

	ORDER EXTERNAL BY p_rec_prodstatus.part_code,p_rec_prodstatus.ware_code 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,PAGENO) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  

	BEFORE GROUP OF p_rec_prodstatus.part_code 
		NEED 3 LINES 
		PRINT COLUMN 1, p_rec_product.part_code CLIPPED, 
		COLUMN 17, p_rec_product.desc_text CLIPPED 

	ON EVERY ROW 
		INITIALIZE l_rec_warehouse.* TO NULL 
		SELECT * INTO l_rec_warehouse.* FROM warehouse 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND ware_code = p_rec_prodstatus.ware_code 
		INITIALIZE l_rec_uom.* TO NULL 
		SELECT * INTO l_rec_uom.* FROM uom 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND uom_code = p_rec_product.price_uom_code 
		IF p_rec_product.sell_uom_code = p_rec_product.price_uom_code THEN 
			LET l_conv_rate = 1 
		ELSE 
			LET l_conv_rate = get_uom_conversion_factor(glob_rec_kandoouser.cmpy_code,p_rec_product.part_code,p_rec_product.sell_uom_code,p_rec_product.price_uom_code,2) 
			IF l_conv_rate < 0 THEN 
				LET l_conv_rate = 0 
			END IF 
		END IF 
		PRINT COLUMN 13, p_rec_prodstatus.ware_code, 
		COLUMN 17, l_rec_warehouse.desc_text[1,24], 
		COLUMN 42, p_rec_product.price_uom_code, 
		COLUMN 47, l_rec_uom.desc_text[1,14], 
		COLUMN 61, (p_rec_prodstatus.list_amt * l_conv_rate)   USING "-----,--&.&&", 
		COLUMN 76, (p_rec_prodstatus.price1_amt * l_conv_rate) USING "-----,--&.&&", 
		COLUMN 91, (p_rec_prodstatus.price2_amt * l_conv_rate) USING "-----,--&.&&", 
		COLUMN 106,(p_rec_prodstatus.price3_amt * l_conv_rate) USING "-----,--&.&&", 
		COLUMN 121,(p_rec_prodstatus.price4_amt * l_conv_rate) USING "-----,--&.&&" 
		PRINT COLUMN 61, (p_rec_prodstatus.price5_amt * l_conv_rate) USING "-----,--&.&&", 
		COLUMN 76, (p_rec_prodstatus.price6_amt * l_conv_rate) USING "-----,--&.&&", 
		COLUMN 91, (p_rec_prodstatus.price7_amt * l_conv_rate) USING "-----,--&.&&", 
		COLUMN 106,(p_rec_prodstatus.price8_amt * l_conv_rate) USING "-----,--&.&&", 
		COLUMN 121,(p_rec_prodstatus.price9_amt * l_conv_rate) USING "-----,--&.&&" 
			
	ON LAST ROW 
		SKIP 1 LINE
		#End Of Report
		IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
			PRINT COLUMN 01,"Selection Criteria:" 
			PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text CLIPPED WORDWRAP RIGHT MARGIN 100 
		END IF 
		PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report 			
		LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = PAGENO 	
			
END REPORT
