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
# FUNCTION IAG_main()
# RETURN VOID
# WARNING: !!! This report is not intended to be viewed visually !!! (albo)
#          This program IS intended TO be OUTPUT FOR a spreadsheet program
# Purpose - Zero Stock Supply Report
############################################################
FUNCTION IAG_main()

	CALL setModuleId("IAG") 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN "1" #UI/MENU Mode
			OPEN WINDOW I689 WITH FORM "I689" 
			 CALL windecoration_i("I689")
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title

			MENU "Zero Stock Supply" 

				BEFORE MENU 
					CALL publish_toolbar("kandoo","IAG","menu-Zero Stock-1") -- albo kd-505 
					CALL rpt_rmsreps_reset(NULL)
					CALL IAG_rpt_process(IAG_rpt_query())

				ON ACTION "WEB-HELP" -- albo kd-372 
					CALL onlinehelp(getmoduleid(),NULL) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar()

				ON ACTION "Report" #COMMAND "Run Report" " SELECT Criteria AND Print Report"
					CALL rpt_rmsreps_reset(NULL)
					CALL IAG_rpt_process(IAG_rpt_query())

				ON ACTION "PRINT MANAGER" --COMMAND "Print" "Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "CANCEL" --COMMAND KEY (interrupt, "E") "Exit" " Exit TO menus" 
					EXIT MENU

			END MENU
			CLOSE WINDOW I689

		WHEN "2" #Background Process with rmsreps.report_code
			CALL IAG_rpt_process(NULL)  

		WHEN "3" #Only create query-where-part
			OPEN WINDOW I689 with FORM "I689" 
			 CALL windecoration_i("I689") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(IAG_rpt_query()) #save where clause in env 
			CLOSE WINDOW I689 
			
		WHEN "4" #Background Process with SQL WHERE ARGUMENT
			CALL IAG_rpt_process(get_url_sel_text())
	END CASE	

END FUNCTION 
############################################################
# END FUNCTION IAG_main() 
############################################################

############################################################
# FUNCTION IAG_rpt_query() 
# RETURN r_where_text (Query By Example)
# DataSource for the report driver with CONSTRUCT
############################################################
FUNCTION IAG_rpt_query() 
	DEFINE r_where_text LIKE rmsreps.sel_text

	MESSAGE " Enter criteria FOR selection - ESC TO begin search"
 
	CONSTRUCT BY NAME r_where_text ON 
	product.maingrp_code, 
	product.prodgrp_code, 
	product.vend_code, 
	product.part_code, 
	product.desc_text 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","IAG","construct-product-1") -- albo kd-505 

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
# END FUNCTION IAG_rpt_query() 
############################################################

############################################################
# FUNCTION IAG_rpt_process(p_where_text) 
# 
# The report driver
############################################################
FUNCTION IAG_rpt_process(p_where_text)
	DEFINE p_where_text STRING
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT
	DEFINE l_for_cost_amt LIKE prodstatus.for_cost_amt 
	DEFINE l_act_cost_amt LIKE prodstatus.act_cost_amt 
	DEFINE l_last_receipt_date LIKE prodstatus.last_receipt_date 
	DEFINE l_tran_qty LIKE prodledg.tran_qty 
	DEFINE l_ware_code LIKE prodstatus.ware_code 
	DEFINE l_cmpy_code LIKE product.cmpy_code 
	DEFINE l_vend_code LIKE product.vend_code 
	DEFINE l_maingrp_code LIKE product.maingrp_code 
	DEFINE l_prodgrp_code LIKE product.prodgrp_code 
	DEFINE l_part_code LIKE product.part_code 
	DEFINE l_part_desc LIKE product.desc_text 
	DEFINE l_oem_text LIKE product.oem_text 
	DEFINE l_tariff_code LIKE product.tariff_code 

	#------------------------------------------------------------
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE
		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"IAG_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	

	START REPORT IAG_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	LET l_query_text = 
	"SELECT product.cmpy_code,product.vend_code,", 
	"product.maingrp_code,product.prodgrp_code,", 
	"product.part_code,product.desc_text,", 
	"product.oem_text,product.tariff_code,", 
	"prodstatus.ware_code,SUM(prodledg.tran_qty),", 
	"prodstatus.for_cost_amt,prodstatus.act_cost_amt,", 
	"prodstatus.last_receipt_date ", 
	"FROM product,prodledg,prodstatus ", 
	"WHERE product.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND prodledg.cmpy_code = product.cmpy_code ", 
	"AND prodstatus.cmpy_code = product.cmpy_code ", 
	"AND prodledg.part_code = product.part_code ", 
	"AND prodstatus.part_code = product.part_code ", 
	"AND prodstatus.for_cost_amt = 0" , 
	"AND prodledg.ware_code = prodstatus.ware_code ", 
	"AND ",p_where_text CLIPPED," ", 
	"GROUP BY 1,2,3,4,5,6,7,8,9,11,12,13 ", 
	"HAVING SUM(prodledg.tran_qty) > 0 ", 
	"ORDER BY product.vend_code,product.maingrp_code,product.prodgrp_code" 

	PREPARE p_product FROM l_query_text 
	DECLARE c_product CURSOR FOR p_product 
	
	FOREACH c_product INTO  l_cmpy_code,l_vend_code,l_maingrp_code,l_prodgrp_code,l_part_code,l_part_desc,l_oem_text, 
									l_tariff_code,l_ware_code, l_tran_qty,l_for_cost_amt, l_act_cost_amt,l_last_receipt_date 
		#---------------------------------------------------------
		OUTPUT TO REPORT IAG_rpt_list(l_rpt_idx,l_cmpy_code,l_vend_code,l_maingrp_code,l_prodgrp_code,l_part_code,l_part_desc,l_oem_text,
												l_tariff_code,l_ware_code,l_tran_qty,l_for_cost_amt,l_act_cost_amt,l_last_receipt_date) 
		IF NOT rpt_int_flag_handler2("Product: ",l_part_code,"",l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT IAG_rpt_list
	RETURN rpt_finish("IAG_rpt_list")
	#------------------------------------------------------------

END FUNCTION
############################################################
# END FUNCTION IAG_rpt_process() 
############################################################

############################################################
# REPORT IAG_rpt_list(p_rpt_idx,p_rec_product,p_rec_prodstatus)
#
# Report Definition/Layout
############################################################
REPORT IAG_rpt_list (p_rpt_idx,p_cmpy_code,p_vend_code,p_maingrp_code,p_prodgrp_code,p_part_code,p_part_desc,p_oem_text, 
							p_tariff_code,p_ware_code,p_tran_qty,p_for_cost_amt,p_act_cost_amt,p_last_receipt_date)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_for_cost_amt LIKE prodstatus.for_cost_amt 
	DEFINE p_act_cost_amt LIKE prodstatus.act_cost_amt 
	DEFINE p_last_receipt_date LIKE prodstatus.last_receipt_date 
	DEFINE p_tran_qty LIKE prodledg.tran_qty 
	DEFINE p_ware_code LIKE prodstatus.ware_code 
	DEFINE p_cmpy_code LIKE product.cmpy_code 
	DEFINE p_vend_code LIKE product.vend_code 
	DEFINE p_maingrp_code LIKE product.maingrp_code 
	DEFINE p_prodgrp_code LIKE product.prodgrp_code 
	DEFINE p_part_code LIKE product.part_code 
	DEFINE p_part_desc LIKE product.desc_text 
	DEFINE p_oem_text LIKE product.oem_text 
	DEFINE p_tariff_code LIKE product.tariff_code 
	DEFINE p_name_text LIKE vendor.name_text 
	DEFINE p_currency_code LIKE vendor.currency_code 
	DEFINE p_maingrp_desc LIKE maingrp.desc_text 
	DEFINE p_prodgrp_desc LIKE prodgrp.desc_text 
	DEFINE p_duty_per LIKE tariff.duty_per 
	DEFINE p_cost_amt LIKE prodquote.cost_amt 

	ORDER EXTERNAL BY p_vend_code,p_maingrp_code,p_prodgrp_code 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,PAGENO) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 CLIPPED #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 CLIPPED #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]
--			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text CLIPPED 
         PRINT COLUMN 01, "Vendor Code,Vendor Name,Currency Code,Main Group Code,Description,Product Group,Description,Part Code,Description,OEM Code,Tariff Code,Tariff Rate,Qty,Latest Foreign Cost,Latest Cost,Last Receipt Date,Cost Amount"
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]

	BEFORE GROUP OF p_vend_code 
		SELECT name_text, currency_code INTO p_name_text, p_currency_code 
		FROM vendor 
		WHERE cmpy_code = p_cmpy_code 
		AND vend_code = p_vend_code 

	BEFORE GROUP OF p_maingrp_code 
		SELECT desc_text INTO p_maingrp_desc 
		FROM maingrp 
		WHERE cmpy_code = p_cmpy_code 
		AND maingrp_code = p_maingrp_code 
			
	BEFORE GROUP OF p_prodgrp_code 
		SELECT desc_text INTO p_prodgrp_desc 
		FROM prodgrp 
		WHERE cmpy_code = p_cmpy_code 
		AND prodgrp_code = p_prodgrp_code 
			
	ON EVERY ROW 
		SELECT duty_per INTO p_duty_per FROM tariff 
		WHERE cmpy_code = p_cmpy_code 
		AND tariff_code = p_tariff_code 
		SELECT cost_amt INTO p_cost_amt FROM prodquote 
		WHERE cmpy_code = p_cmpy_code 
		AND part_code = p_part_code 
		AND vend_code = p_vend_code 
		PRINT COLUMN 01, p_vend_code,",", 
		p_name_text,",", 
		p_currency_code,",", 
		p_maingrp_code,",", 
		p_maingrp_desc,",", 
		p_prodgrp_code,",", 
		p_prodgrp_desc,",", 
		p_part_code,",", 
		p_part_desc,",", 
		p_oem_text,",", 
		p_tariff_code,",", 
		p_duty_per,",", 
		p_tran_qty,",", 
		p_for_cost_amt,",", 
		p_act_cost_amt,",", 
		p_last_receipt_date,",", 
		p_cost_amt 
		
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