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
# FUNCTION IRB_main()
#
# Purpose - Serialized Items Report 
############################################################
FUNCTION IRB_main()

	CALL setModuleId("IRB") 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN "1" #UI/MENU Mode
			OPEN WINDOW I127 WITH FORM "I127" 
			 CALL windecoration_i("I127")
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title
			
			MENU "Serialized Items" 

				BEFORE MENU 
					CALL publish_toolbar("kandoo","IRB","menu-Serial_Stock-1") -- albo kd-505
					CALL rpt_rmsreps_reset(NULL)
					CALL IRB_rpt_process(IRB_rpt_query())

				ON ACTION "WEB-HELP" -- albo kd-372 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar()

				ON ACTION "Report" #COMMAND "Run Report" " SELECT Criteria AND Print Report"
					CALL rpt_rmsreps_reset(NULL)
					CALL IRB_rpt_process(IRB_rpt_query())

				ON ACTION "PRINT MANAGER" --COMMAND "Print" "Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "CANCEL" --COMMAND KEY (interrupt, "E") "Exit" " Exit TO menus" 
					EXIT MENU

			END MENU
			CLOSE WINDOW I127

		WHEN "2" #Background Process with rmsreps.report_code
			CALL IRB_rpt_process(NULL)  

		WHEN "3" #Only create query-where-part
			OPEN WINDOW I127 WITH FORM "I127" 
			 CALL windecoration_i("I127") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(IRB_rpt_query()) #save where clause in env 
			CLOSE WINDOW I127 
			
		WHEN "4" #Background Process with SQL WHERE ARGUMENT
			CALL IRB_rpt_process(get_url_sel_text())
	END CASE

END FUNCTION 
############################################################
# END FUNCTION IRB_main()
############################################################

############################################################
# FUNCTION IRB_rpt_query() 
# RETURN r_where_text (Query By Example)
# DataSource for the report driver with CONSTRUCT
############################################################
FUNCTION IRB_rpt_query() 
	DEFINE r_where_text LIKE rmsreps.sel_text

	CONSTRUCT BY NAME r_where_text ON 
	serialinfo.part_code, 
	product.desc_text, 
	product.desc2_text, 
	serialinfo.ware_code, 
	serialinfo.serial_code, 
	serialinfo.asset_num, 
	serialinfo.vend_code, 
	serialinfo.po_num,
	serialinfo.receipt_date, 
	serialinfo.receipt_num, 
	serialinfo.cust_code, 
	serialinfo.trans_num,
	serialinfo.ship_date,
	serialinfo.credit_num,
	serialinfo.trantype_ind, 
	serialinfo.ref_num 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","IRB","construct-serialinfo-1") -- albo kd-505 

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
# END FUNCTION IRB_rpt_query() 
############################################################

############################################################
# FUNCTION IRB_rpt_process(p_where_text) 
# 
# The report driver
############################################################
FUNCTION IRB_rpt_process(p_where_text)
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT
	DEFINE l_rec_serialinfo RECORD LIKE serialinfo.*
	DEFINE l_product_desc LIKE product.desc_text
	DEFINE l_product_desc2 LIKE product.desc2_text
	DEFINE l_rec_purchdetl RECORD LIKE purchdetl.* 

	#------------------------------------------------------------
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE
		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"IRB_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	

	START REPORT IRB_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	LET l_query_text = 
	"SELECT serialinfo.*,product.desc_text,product.desc2_text ", 
	"FROM serialinfo,product ", 
	"WHERE serialinfo.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND product.cmpy_code = serialinfo.cmpy_code ", 
	"AND product.part_code = serialinfo.part_code ", 
	"AND ", p_where_text CLIPPED," ", 
	"ORDER BY serialinfo.part_code,serialinfo.vend_code,serialinfo.ware_code,serialinfo.receipt_date,serialinfo.serial_code" 
	PREPARE choice FROM l_query_text 
	DECLARE selcurs CURSOR FOR choice 

	LET l_query_text =
	"SELECT * FROM purchdetl ", 
	"WHERE purchdetl.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
			"AND purchdetl.order_num = ? ", 
			"AND purchdetl.ref_text = ? ", 
			"AND purchdetl.charge_amt != 0" 
	PREPARE p_purchdetl FROM l_query_text 
	DECLARE po_curs CURSOR FOR p_purchdetl 

	FOREACH selcurs INTO l_rec_serialinfo.*,l_product_desc,l_product_desc2 
		OPEN po_curs USING l_rec_serialinfo.po_num,l_rec_serialinfo.part_code  
		FETCH po_curs INTO l_rec_purchdetl.* 
		IF STATUS = NOTFOUND THEN 
			LET l_rec_purchdetl.job_code = NULL 
			LET l_rec_purchdetl.charge_amt = 0 
		END IF 
		#---------------------------------------------------------
		OUTPUT TO REPORT IRB_rpt_list(l_rpt_idx,l_rec_serialinfo.*,l_product_desc,l_product_desc2,l_rec_purchdetl.*)
		IF NOT rpt_int_flag_handler2("Product: ",l_rec_serialinfo.part_code,"",l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT IRB_rpt_list
	RETURN rpt_finish("IRB_rpt_list")
	#------------------------------------------------------------

END FUNCTION 
############################################################
# END FUNCTION IRB_rpt_process() 
############################################################

############################################################
# REPORT IRB_rpt_list(p_rpt_idx,pr_serialinfo,p_product_desc,p_product_desc2,p_rec_purchdetl)
#
# Report Definition/Layout
############################################################
REPORT IRB_rpt_list(p_rpt_idx,p_rec_serialinfo,p_product_desc,p_product_desc2,p_rec_purchdetl) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_serialinfo RECORD LIKE serialinfo.* 
	DEFINE p_product_desc LIKE product.desc_text
	DEFINE p_product_desc2 LIKE product.desc2_text
	DEFINE p_rec_purchdetl RECORD LIKE purchdetl.*
	DEFINE l_warehouse_name LIKE warehouse.desc_text
	DEFINE l_vendor_name LIKE vendor.name_text 
	DEFINE l_rr_cnt INTEGER 
	DEFINE l_rr_cnt_tot INTEGER
	DEFINE l_rr_cnt_ware INTEGER

	ORDER EXTERNAL BY p_rec_serialinfo.part_code,p_rec_serialinfo.vend_code,p_rec_serialinfo.ware_code,p_rec_serialinfo.receipt_date,p_rec_serialinfo.serial_code 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,PAGENO) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 CLIPPED #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 CLIPPED #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text CLIPPED 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text CLIPPED 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]

	BEFORE GROUP OF p_rec_serialinfo.part_code 
		LET l_rr_cnt = 0 
		SKIP 1 LINE 
		PRINT COLUMN 01, "Item: ", 
		COLUMN 07, p_rec_serialinfo.part_code CLIPPED, 
		COLUMN 27, p_product_desc CLIPPED," ",p_product_desc2 CLIPPED 

	BEFORE GROUP OF p_rec_serialinfo.vend_code 
		SELECT vendor.name_text INTO l_vendor_name FROM vendor 
		WHERE vendor.cmpy_code = glob_rec_kandoouser.cmpy_code AND 
				vendor.vend_code = p_rec_serialinfo.vend_code 
		IF STATUS = NOTFOUND THEN 
			LET l_vendor_name = NULL 
		END IF 
		PRINT COLUMN 4, "Supplier: ", 
		COLUMN 15, p_rec_serialinfo.vend_code CLIPPED, 
		COLUMN 25, l_vendor_name CLIPPED

	BEFORE GROUP OF p_rec_serialinfo.ware_code 
		LET l_rr_cnt_ware = 0 
		SELECT warehouse.desc_text INTO l_warehouse_name FROM warehouse 
		WHERE warehouse.cmpy_code = glob_rec_kandoouser.cmpy_code AND 
				warehouse.ware_code = p_rec_serialinfo.ware_code 
		IF STATUS = NOTFOUND THEN 
			LET l_warehouse_name = NULL 
		END IF 
		PRINT COLUMN 06, "Warehouse: ", 
		COLUMN 17, p_rec_serialinfo.ware_code CLIPPED, 
		COLUMN 22, l_warehouse_name CLIPPED

	ON EVERY ROW 
		LET l_rr_cnt = l_rr_cnt + 1 
		LET l_rr_cnt_ware = l_rr_cnt_ware + 1 
		LET l_rr_cnt_tot = l_rr_cnt_tot + 1 
		PRINT COLUMN 8, p_rec_serialinfo.serial_code CLIPPED, 
		COLUMN 32, p_rec_serialinfo.po_num                  USING "########", 
		COLUMN 42, p_rec_serialinfo.receipt_date            USING "dd/mm/yyyy", 
		COLUMN 54, p_rec_serialinfo.receipt_num             USING "########", 
		COLUMN 64, p_rec_purchdetl.job_code CLIPPED, 
		COLUMN 74, p_rec_serialinfo.trans_num               USING "########", 
		COLUMN 84, p_rec_purchdetl.charge_amt               USING "-,---,--&.&&", 
		COLUMN 98, p_rec_serialinfo.ship_date               USING "dd/mm/yy", 
		COLUMN 108,p_rec_serialinfo.credit_num              USING "########", 
		COLUMN 118,p_rec_serialinfo.ref_num                 USING "########", 
		COLUMN 130,p_rec_serialinfo.trantype_ind CLIPPED
		PRINT COLUMN 8, "Asset:", 
		COLUMN 15, p_rec_serialinfo.asset_num CLIPPED

	AFTER GROUP OF p_rec_serialinfo.ware_code 
		PRINT COLUMN 94, "Warehouse Count: ",l_rr_cnt_ware  USING "#######" 

	AFTER GROUP OF p_rec_serialinfo.part_code 
		PRINT COLUMN 82, "--------------------------------------" 
		PRINT COLUMN 67, "Total: ", 
		COLUMN 83, GROUP SUM(p_rec_purchdetl.charge_amt)    USING "--,---,--&.&&", 
		COLUMN 104, "Count: ", l_rr_cnt                     USING "#######" 
		PRINT COLUMN 82, "--------------------------------------" 

	ON LAST ROW 
		NEED 3 LINES 
		PRINT COLUMN 82, "--------------------------------------" 
		PRINT COLUMN 60, "Report Total: ", 
		COLUMN 82, SUM(p_rec_purchdetl.charge_amt)          USING "---,---,--&.&&", 
		COLUMN 104, "Count:", l_rr_cnt_tot                  USING "########" 
		PRINT COLUMN 82, "--------------------------------------" 
		SKIP 2 LINES
		#End Of Report
		IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
			PRINT COLUMN 01,"Selection Criteria:" 
			PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text CLIPPED WORDWRAP RIGHT MARGIN 100 
		END IF 
		PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report 			
		LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = PAGENO

END REPORT 
