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
# MODULE Scope Variables
############################################################
DEFINE modu_update_flag SMALLINT  

############################################################
# FUNCTION IS9_main()
#
# Purpose - Vendor Price List Comparison Report
############################################################
FUNCTION IS9_main()

	CALL setModuleId("IS9") 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN "1" #UI/MENU Mode
			OPEN WINDOW I705 WITH FORM "I705" 
			 CALL windecoration_i("I705")
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title
			
			MENU "Vendor Price List Comparison" 

				BEFORE MENU 
					CALL publish_toolbar("kandoo","IS9","menu-Price_List-1") -- albo kd-505
					CALL fgl_dialog_setactionlabel("Update","Update prices","{CONTEXT}/public/querix/icon/svg/24/ic_edit_24px.svg",4,FALSE,"Update product prices and generate Report")
					CALL rpt_rmsreps_reset(NULL)

				ON ACTION "WEB-HELP" -- albo kd-372 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar()

				ON ACTION "Report" #COMMAND "Run Report" " SELECT Criteria AND Print Report"
					LET modu_update_flag = FALSE 
					CALL rpt_rmsreps_reset(NULL)
					CALL IS9_rpt_process(IS9_rpt_query()) 

				ON ACTION "Update" #COMMAND "Update" "Update product prices and generate Report"
					LET modu_update_flag = TRUE 
					CALL rpt_rmsreps_reset(NULL)
					CALL IS9_rpt_process(IS9_rpt_query())

				ON ACTION "PRINT MANAGER" --COMMAND "Print" "Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "CANCEL" --COMMAND KEY (interrupt, "E") "Exit" " Exit TO menus" 
					EXIT MENU

			END MENU
			CLOSE WINDOW I705

		WHEN "2" #Background Process with rmsreps.report_code
			CALL IS9_rpt_process(NULL)  

		WHEN "3" #Only create query-where-part
			OPEN WINDOW I705 with FORM "I705" 
			 CALL windecoration_i("I705") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(IS9_rpt_query()) #save where clause in env 
			CLOSE WINDOW I705 
			
		WHEN "4" #Background Process with SQL WHERE ARGUMENT
			CALL IS9_rpt_process(get_url_sel_text())
	END CASE

END FUNCTION
############################################################
# END FUNCTION IS9_main()
############################################################

############################################################
# FUNCTION IS9_rpt_query() 
# RETURN r_where_text (Query By Example)
# DataSource for the report driver with CONSTRUCT
############################################################
FUNCTION IS9_rpt_query() 
	DEFINE r_where_text LIKE rmsreps.sel_text
	DEFINE l_msg_err STRING

	MESSAGE " Enter criteria FOR selection - ESC TO begin search"

	CONSTRUCT BY NAME r_where_text ON 
	product.vend_code, 
	product.part_code, 
	product.desc_text, 
	product.desc2_text, 
	product.cat_code, 
	product.maingrp_code, 
	product.prodgrp_code, 
	product.class_code, 
	product.oem_text 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","IS9","construct-product-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN NULL 
	ELSE 
		IF modu_update_flag THEN 
			IF r_where_text = " 1=1" THEN 
				LET l_msg_err = "WARNING: All supplier prices have been selected to be updated!\nCommence reset of supplier prices to zero?" 
			ELSE
				LET l_msg_err = "Commence reset of supplier prices to zero?"
				#LET l_msgresp = kandoomsg("I",8052,"") 
				#8052 Commence reset of supplier prices TO zero? (Y/N)
			END IF 
			IF promptTF("",l_msg_err,TRUE) THEN 
				LET modu_update_flag = TRUE
			ELSE 
				LET modu_update_flag = FALSE
			END IF 
		END IF
		RETURN r_where_text
	END IF

END FUNCTION 
############################################################
# END FUNCTION IS9_rpt_query() 
############################################################

############################################################
# FUNCTION IS9_rpt_process(p_where_text) 
# 
# The report driver
############################################################
FUNCTION IS9_rpt_process(p_where_text)
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_ware_code LIKE prodstatus.ware_code 
	DEFINE l_list_amt LIKE prodstatus.list_amt 
	DEFINE l_for_cost_amt LIKE prodstatus.for_cost_amt 
	DEFINE l_for_curr_code LIKE prodstatus.for_curr_code 

	#------------------------------------------------------------
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE
		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"IS9_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	

	START REPORT IS9_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	LET l_query_text = 
	"SELECT product.vend_code,prodstatus.ware_code,product.part_code,product.desc_text,", 
	"oem_text,price_uom_code,prodstatus.list_amt,", 
	"prodstatus.for_cost_amt,prodstatus.for_curr_code ", 
	"FROM product,prodstatus ", 
	"WHERE product.cmpy_code ='",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND product.status_ind != '3' ", 
	"AND product.vend_code IS NOT NULL ", 
	"AND prodstatus.cmpy_code = product.cmpy_code ", 
	"AND prodstatus.part_code = product.part_code ", 
	"AND ",p_where_text CLIPPED," ", 
	"AND NOT exists (SELECT UNIQUE 1 FROM prodquote ", 
	"WHERE prodquote.vend_code = product.vend_code ", 
	"AND prodquote.oem_text = product.oem_text ", 
	"AND prodquote.cmpy_code = product.cmpy_code) ", 
	"ORDER BY product.vend_code,prodstatus.ware_code,product.part_code" 

	PREPARE s_product FROM l_query_text 
	DECLARE c_product CURSOR FOR s_product 

	IF modu_update_flag = TRUE THEN
		BEGIN WORK
		FOREACH c_product INTO
			l_rec_product.vend_code, 
			l_ware_code, 
			l_rec_product.part_code

			UPDATE prodstatus SET prodstatus.for_cost_amt = 0 
			WHERE prodstatus.cmpy_code = glob_rec_kandoouser.cmpy_code
			AND prodstatus.part_code = l_rec_product.part_code

		END FOREACH		
		COMMIT WORK
	END IF

	FOREACH c_product INTO 
		l_rec_product.vend_code, 
		l_ware_code, 
		l_rec_product.part_code, 
		l_rec_product.desc_text, 
		l_rec_product.oem_text, 
		l_rec_product.price_uom_code, 
		l_list_amt, 
		l_for_cost_amt, 
		l_for_curr_code 
		#---------------------------------------------------------
		OUTPUT TO REPORT IS9_rpt_list (l_rpt_idx,l_rec_product.*, l_ware_code, l_list_amt,l_for_cost_amt, l_for_curr_code) 
		IF NOT rpt_int_flag_handler2("Product: ",l_rec_product.part_code,"",l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT IS9_rpt_list
	RETURN rpt_finish("IS9_rpt_list")
	#------------------------------------------------------------

END FUNCTION 
############################################################
# END FUNCTION IS9_rpt_process() 
############################################################

############################################################
# REPORT IS9_rpt_list(p_rpt_idx,p_rec_product,p_ware_code,p_list_amt,p_for_cost_amt,p_for_curr_code)
#
# Report Definition/Layout
############################################################
REPORT IS9_rpt_list(p_rpt_idx,p_rec_product,p_ware_code,p_list_amt,p_for_cost_amt,p_for_curr_code) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_product RECORD LIKE product.* 
	DEFINE p_ware_code LIKE warehouse.ware_code 
	DEFINE p_list_amt LIKE prodstatus.list_amt
	DEFINE p_for_cost_amt LIKE prodstatus.for_cost_amt
	DEFINE p_for_curr_code LIKE prodstatus.for_curr_code
	DEFINE l_name_text LIKE vendor.name_text 
	DEFINE l_desc_text LIKE warehouse.desc_text 

	ORDER EXTERNAL BY p_rec_product.vend_code,p_ware_code 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,PAGENO) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1  CLIPPED #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2  CLIPPED #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3  CLIPPED #wasl_arr_line[3]
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text CLIPPED  
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text CLIPPED  
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3  CLIPPED #wasl_arr_line[3]

	BEFORE GROUP OF p_rec_product.vend_code 
		SELECT vendor.name_text INTO l_name_text 
		FROM vendor 
		WHERE vendor.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND vendor.vend_code = p_rec_product.vend_code 
		IF STATUS = NOTFOUND THEN 
			LET l_name_text = "" 
		END IF 
		PRINT COLUMN 001, "Vendor: ",p_rec_product.vend_code CLIPPED,"  ",l_name_text CLIPPED 
		PRINT 

	BEFORE GROUP OF p_ware_code 
		SELECT warehouse.desc_text INTO l_desc_text 
		FROM warehouse 
		WHERE warehouse.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND warehouse.ware_code = p_ware_code 
		IF STATUS = NOTFOUND THEN 
			LET l_desc_text = "" 
		END IF 
		PRINT COLUMN 001, "Warehouse: ",p_ware_code CLIPPED,"  ",l_desc_text CLIPPED 

	ON EVERY ROW 
		IF p_list_amt IS NULL THEN 
			LET p_list_amt = 0 
		END IF 
		IF p_for_cost_amt IS NULL THEN 
			LET p_for_cost_amt = 0 
		END IF 
		PRINT 
		COLUMN 001, p_rec_product.part_code CLIPPED, 
		COLUMN 019, p_rec_product.desc_text CLIPPED, 
		COLUMN 058, p_rec_product.oem_text CLIPPED, 
		COLUMN 091, p_rec_product.price_uom_code CLIPPED, 
		COLUMN 098, p_list_amt     USING "---,---,--&.&&",
		COLUMN 113, p_for_cost_amt USING "---,---,--&.&&",
		COLUMN 129, p_for_curr_code CLIPPED 

	AFTER GROUP OF p_ware_code 
		PRINT 

	AFTER GROUP OF p_rec_product.vend_code 
		SKIP TO top OF PAGE 

	ON LAST ROW 
		SKIP 1 LINES 
		#End Of Report
		IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
			PRINT COLUMN 01,"Selection Criteria:" 
			PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text CLIPPED WORDWRAP RIGHT MARGIN 100 
		END IF 
		PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report 			
		LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = PAGENO

END REPORT
