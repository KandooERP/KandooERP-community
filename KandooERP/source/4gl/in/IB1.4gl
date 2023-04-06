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
# MODULE Scope Variables
############################################################
DEFINE modu_detail SMALLINT 

############################################################
# FUNCTION IB1_main()
# RETURN VOID
#
# Purpose - Product Status Report by Warehouse
############################################################
FUNCTION IB1_main()

	CALL setModuleId("IB1") 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN "1" #UI/MENU Mode
			OPEN WINDOW I162 WITH FORM "I162" 
			 CALL windecoration_i("I162")
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title
			
			MENU "Product Status" 

				BEFORE MENU 
					CALL publish_toolbar("kandoo","IB1","menu-Product_Status-1") -- albo kd-505 

				ON ACTION "WEB-HELP" -- albo kd-372 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar()

				ON ACTION "REPORT_DETAILED"   --COMMAND "Detail" " Enter Selection Criteria AND produce Detail Report"
					LET modu_detail = 1 
					CALL rpt_rmsreps_reset(NULL)
					CALL IB1_rpt_process(IB1_rpt_query())

				ON ACTION "REPORT_SUMMARY"    --COMMAND "Summary" " Enter Selection Criteria AND produce Summary Report"
					LET modu_detail = 2 
					CALL rpt_rmsreps_reset(NULL)
					CALL IB1_rpt_process(IB1_rpt_query())

				ON ACTION "PRINT MANAGER" --COMMAND "Print" "Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "CANCEL" --COMMAND KEY (interrupt, "E") "Exit" " Exit TO menus" 
					EXIT MENU

			END MENU
			CLOSE WINDOW I162

		WHEN "2" #Background Process with rmsreps.report_code
			LET modu_detail = 1
			CALL IB1_rpt_process(NULL)  

		WHEN "3" #Only create query-where-part
			OPEN WINDOW I162 with FORM "I162" 
			 CALL windecoration_i("I162") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(IB1_rpt_query()) #save where clause in env 
			CLOSE WINDOW I162 
			
		WHEN "4" #Background Process with SQL WHERE ARGUMENT
			LET modu_detail = 1
			CALL IB1_rpt_process(get_url_sel_text())
	END CASE	

END FUNCTION 
############################################################
# END FUNCTION IB1_main() 
############################################################

############################################################
# FUNCTION IB1_rpt_query() 
# RETURN r_where_text (Query By Example)
# DataSource for the report driver with CONSTRUCT
############################################################
FUNCTION IB1_rpt_query() 
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
			CALL publish_toolbar("kandoo","IB1","construct-prodstatus-1") -- albo kd-505 

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
# END FUNCTION IB1_rpt_query() 
############################################################

############################################################
# FUNCTION IB1_rpt_process() 
# RETURN true/false
# 
# The report driver
############################################################
FUNCTION IB1_rpt_process(p_where_text)
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT

	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_parent_part LIKE product.part_code 
	DEFINE l_filler LIKE product.part_code
	DEFINE l_flex_part LIKE product.part_code
	DEFINE l_flex_number LIKE product.part_code
	DEFINE l_rec_prodstatus RECORD 
		part_code LIKE prodstatus.part_code, 
		status_ind LIKE prodstatus.status_ind, 
		ware_code LIKE prodstatus.ware_code, 
		onhand_qty LIKE prodstatus.onhand_qty, 
		reserved_qty LIKE prodstatus.reserved_qty, 
		back_qty LIKE prodstatus.back_qty, 
		onord_qty LIKE prodstatus.onord_qty, 
		forward_qty LIKE prodstatus.forward_qty, 
		desc_text LIKE product.desc_text, 
		desc2_text LIKE product.desc2_text 
	END RECORD

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"IB1_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	

	START REPORT IB1_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	LET l_query_text = 
	"SELECT prodstatus.part_code,", 
	"prodstatus.status_ind,", 
	"prodstatus.ware_code,", 
	"prodstatus.onhand_qty,", 
	"prodstatus.reserved_qty,", 
	"prodstatus.back_qty,", 
	"prodstatus.onord_qty,", 
	"prodstatus.forward_qty,", 
	"product.desc_text,", 
	"product.desc2_text ", 
	"FROM prodstatus,", 
	"product ", 
	"WHERE prodstatus.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND product.cmpy_code = prodstatus.cmpy_code ", 
	"AND product.part_code = prodstatus.part_code "
	
	IF p_where_text IS NOT NULL THEN
		LET l_query_text = trim(l_query_text), " AND ", trim(p_where_text)
	END IF

	LET l_query_text = trim(l_query_text), " ORDER BY prodstatus.ware_code,prodstatus.part_code" 

	PREPARE choice FROM l_query_text 
	DECLARE selcurs CURSOR FOR choice 

	FOREACH selcurs INTO l_rec_prodstatus.* 
		IF modu_detail = 2 THEN 
			SELECT * INTO l_rec_product.* FROM product 
			WHERE part_code = l_rec_prodstatus.part_code 
			AND glob_rec_kandoouser.cmpy_code = cmpy_code 
			CALL break_prod(glob_rec_kandoouser.cmpy_code,l_rec_prodstatus.part_code,l_rec_product.class_code,0) 
			RETURNING l_parent_part,l_filler,l_flex_part,l_flex_number 
		END IF 
		#---------------------------------------------------------
		OUTPUT TO REPORT IB1_rpt_list (l_rpt_idx,l_rec_prodstatus.*,l_parent_part) 
		IF NOT rpt_int_flag_handler2("Product: ",l_rec_prodstatus.part_code,"",l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------
	END FOREACH 
 
	#------------------------------------------------------------
	FINISH REPORT IB1_rpt_list
	RETURN rpt_finish("IB1_rpt_list")
	#------------------------------------------------------------

END FUNCTION 
############################################################
# END FUNCTION IB1_rpt_process() 
############################################################

############################################################
# REPORT IB1_rpt_list(p_rpt_idx,p_rec_prodstatus,p_parent_part)
#
# Report Definition/Layout
############################################################
REPORT IB1_rpt_list(p_rpt_idx,p_rec_prodstatus,p_parent_part) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_prodstatus RECORD 
		part_code LIKE prodstatus.part_code, 
		status_ind LIKE prodstatus.status_ind, 
		ware_code LIKE prodstatus.ware_code, 
		onhand_qty LIKE prodstatus.onhand_qty, 
		reserved_qty LIKE prodstatus.reserved_qty, 
		back_qty LIKE prodstatus.back_qty, 
		onord_qty LIKE prodstatus.onord_qty, 
		forward_qty LIKE prodstatus.forward_qty, 
		desc_text LIKE product.desc_text, 
		desc2_text LIKE product.desc2_text 
	END RECORD
	DEFINE p_parent_part LIKE product.part_code
	DEFINE l_rec_warehouse RECORD LIKE warehouse.*
	DEFINE l_avail DECIMAL(16,2) 
	DEFINE l_for_avail DECIMAL(16,2)
	DEFINE l_rec_opparms RECORD LIKE opparms.*

	ORDER EXTERNAL BY p_rec_prodstatus.ware_code,p_parent_part 

	FORMAT 
		FIRST PAGE HEADER
#TODO replace with global l_rec_opparms when FUNCTION init_i_in will be finished
			LET l_avail = 0 
			LET l_for_avail = 0
			SELECT * INTO l_rec_opparms.* FROM opparms 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
					key_num = "1" 
			IF STATUS = NOTFOUND THEN 
				LET l_rec_opparms.cal_available_flag = "N" 
			END IF 
			CALL rpt_set_page_num(p_rpt_idx,PAGENO) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,PAGENO) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

	BEFORE GROUP OF p_rec_prodstatus.ware_code 
		SKIP TO top OF PAGE 
		SELECT * INTO l_rec_warehouse.* FROM warehouse 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND ware_code = p_rec_prodstatus.ware_code 
		SKIP 1 line 
		PRINT COLUMN 1, "Warehouse: ", p_rec_prodstatus.ware_code CLIPPED, 
		" (", l_rec_warehouse.desc_text CLIPPED, ")" 
		SKIP 1 line

	ON EVERY ROW 
		NEED 2 LINES 
		IF l_rec_opparms.cal_available_flag = "N" THEN 
			LET l_avail = p_rec_prodstatus.onhand_qty 
			- p_rec_prodstatus.reserved_qty - p_rec_prodstatus.back_qty 
		ELSE 
			LET l_avail = p_rec_prodstatus.onhand_qty - p_rec_prodstatus.reserved_qty 
		END IF 
		LET l_for_avail = l_avail + p_rec_prodstatus.onord_qty 
		- p_rec_prodstatus.forward_qty 
		IF modu_detail = 1 THEN 
			NEED 4 LINES 
			PRINT COLUMN 03, p_rec_prodstatus.part_code, 
			COLUMN 20, p_rec_prodstatus.status_ind, 
			COLUMN 36, p_rec_prodstatus.onhand_qty USING "---------&.&&", 
			COLUMN 51, p_rec_prodstatus.reserved_qty USING "--------&.&&", 
			COLUMN 65, p_rec_prodstatus.back_qty USING "--------&.&&", 
			COLUMN 79, l_avail USING "--------&.&&", 
			COLUMN 93, p_rec_prodstatus.onord_qty USING "--------&.&&", 
			COLUMN 107, p_rec_prodstatus.forward_qty USING "--------&.&&", 
			COLUMN 121, l_for_avail USING "--------&.&&" 
			PRINT COLUMN 06, p_rec_prodstatus.desc_text 
			PRINT COLUMN 06, p_rec_prodstatus.desc2_text 
		END IF 
 
	AFTER GROUP OF p_rec_prodstatus.ware_code 
		IF l_rec_opparms.cal_available_flag = "N" THEN 
			LET l_avail = GROUP sum(p_rec_prodstatus.onhand_qty - 
			p_rec_prodstatus.reserved_qty - 
			p_rec_prodstatus.back_qty) 
		ELSE 
			LET l_avail = GROUP sum(p_rec_prodstatus.onhand_qty - 
			p_rec_prodstatus.reserved_qty) 
		END IF 
		LET l_for_avail = l_avail + GROUP sum(p_rec_prodstatus.onord_qty 
		- p_rec_prodstatus.forward_qty) 
		NEED 4 LINES 
		PRINT COLUMN 35,"--------------", 
		COLUMN 50,"-------------", 
		COLUMN 64,"-------------", 
		COLUMN 78,"-------------", 
		COLUMN 92,"-------------", 
		COLUMN 106,"-------------", 
		COLUMN 120,"-------------" 
		PRINT COLUMN 3, "Warehouse Total:", 
		COLUMN 36,group sum(p_rec_prodstatus.onhand_qty) 
		USING "---------&.&&", 
		COLUMN 51,group sum(p_rec_prodstatus.reserved_qty) 
		USING "--------&.&&", 
		COLUMN 65,group sum(p_rec_prodstatus.back_qty) USING "--------&.&&", 
		COLUMN 79,l_avail USING "--------&.&&", 
		COLUMN 93,group sum(p_rec_prodstatus.onord_qty) 
		USING "--------&.&&", 
		COLUMN 107, GROUP sum(p_rec_prodstatus.forward_qty) 
		USING "--------&.&&", 
		COLUMN 121, l_for_avail USING "--------&.&&" 

	AFTER GROUP OF p_parent_part 
		IF modu_detail = 2 THEN 
			IF l_rec_opparms.cal_available_flag = "N" THEN 
				LET l_avail = GROUP sum(p_rec_prodstatus.onhand_qty - 
				p_rec_prodstatus.reserved_qty - 
				p_rec_prodstatus.back_qty) 
			ELSE 
				LET l_avail = GROUP sum(p_rec_prodstatus.onhand_qty - 
				p_rec_prodstatus.reserved_qty) 
			END IF 
			LET l_for_avail = l_avail + GROUP sum(p_rec_prodstatus.onord_qty 
			- p_rec_prodstatus.forward_qty) 
			PRINT COLUMN 03, p_parent_part, 
			COLUMN 20, p_rec_prodstatus.status_ind, 
			COLUMN 36,group sum(p_rec_prodstatus.onhand_qty) 
			USING "---------&.&&", 
			COLUMN 51,group sum(p_rec_prodstatus.reserved_qty) 
			USING "--------&.&&", 
			COLUMN 65,group sum(p_rec_prodstatus.back_qty) 
			USING "--------&.&&", 
			COLUMN 79,l_avail USING "--------&.&&", 
			COLUMN 93,group sum(p_rec_prodstatus.onord_qty) 
			USING "--------&.&&", 
			COLUMN 107,group sum(p_rec_prodstatus.forward_qty) 
			USING "--------&.&&", 
			COLUMN 121,l_for_avail USING "--------&.&&" 
		END IF 

	ON LAST ROW 
		NEED 9 LINES 
		SKIP 2 LINES 
		IF l_rec_opparms.cal_available_flag = "N" THEN 
			LET l_avail = sum(p_rec_prodstatus.onhand_qty - 
			p_rec_prodstatus.reserved_qty - 
			p_rec_prodstatus.back_qty ) 
		ELSE 
			LET l_avail = sum(p_rec_prodstatus.onhand_qty - 
			p_rec_prodstatus.reserved_qty) 
		END IF 
		LET l_for_avail = l_avail + sum(p_rec_prodstatus.onord_qty 
		- p_rec_prodstatus.forward_qty) 
		PRINT COLUMN 35,"==============", 
		COLUMN 50,"=============", 
		COLUMN 64,"=============", 
		COLUMN 78,"=============", 
		COLUMN 92,"=============", 
		COLUMN 106,"=============", 
		COLUMN 120,"=============" 
		PRINT COLUMN 3, "Report Total:", 
		COLUMN 36,sum(p_rec_prodstatus.onhand_qty) USING "---------&.&&", 
		COLUMN 51,sum(p_rec_prodstatus.reserved_qty) USING "--------&.&&", 
		COLUMN 65,sum(p_rec_prodstatus.back_qty) USING "--------&.&&", 
		COLUMN 79,l_avail USING "--------&.&&", 
		COLUMN 93,sum(p_rec_prodstatus.onord_qty) USING "--------&.&&", 
		COLUMN 107,sum(p_rec_prodstatus.forward_qty) USING "--------&.&&", 
		COLUMN 121,l_for_avail USING "--------&.&&" 
		SKIP 2 LINES 
		#End Of Report
		IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
			PRINT COLUMN 01,"Selection Criteria:" 
			PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text CLIPPED WORDWRAP RIGHT MARGIN 100 
		END IF 
		PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report 			
		LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = PAGENO

END REPORT 
