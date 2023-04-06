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

#	Source code beautified by beautify.pl on 2020-01-03 09:12:32	$Id: $

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
DEFINE modu_cost_selection CHAR(1)
DEFINE modu_fifo_lifo_ind CHAR(1) 

############################################################
# FUNCTION IBD_main()
#
# Purpose - Stock Sales Extract Report
############################################################
FUNCTION IBD_main()

	CALL setModuleId("IBD") 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN "1" #UI/MENU Mode
			OPEN WINDOW I679 WITH FORM "I679" 
			 CALL windecoration_i("I679")
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title
			
			MENU "Stock Sales Extract" 

				BEFORE MENU 
					CALL publish_toolbar("kandoo","IBD","menu-Stock_Sales_Extract-1") -- albo kd-505
					CALL rpt_rmsreps_reset(NULL)
					CALL IBD_rpt_process(IBD_rpt_query())

				ON ACTION "WEB-HELP" -- albo kd-372 
					CALL onlinehelp(getmoduleid(),NULL) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar()

				ON ACTION "Report" #COMMAND "Run Report" " SELECT Criteria AND Print Report"
					CALL rpt_rmsreps_reset(NULL)
					CALL IBD_rpt_process(IBD_rpt_query())

				ON ACTION "PRINT MANAGER" --COMMAND "Print" "Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "CANCEL" --COMMAND KEY (interrupt, "E") "Exit" " Exit TO menus" 
					EXIT MENU

			END MENU
			CLOSE WINDOW I679

		WHEN "2" #Background Process with rmsreps.report_code
			CALL IBD_rpt_process(NULL)  

		WHEN "3" #Only create query-where-part
			OPEN WINDOW I679 with FORM "I679" 
			 CALL windecoration_i("I679") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(IBD_rpt_query()) #save where clause in env 
			CLOSE WINDOW I679 
			
		WHEN "4" #Background Process with SQL WHERE ARGUMENT
			CALL IBD_rpt_process(get_url_sel_text())
	END CASE

END FUNCTION 
############################################################
# END FUNCTION IBD_main()
############################################################

############################################################
# FUNCTION IBD_rpt_query() 
# RETURN r_where_text (Query By Example)
# DataSource for the report driver with CONSTRUCT
############################################################
FUNCTION IBD_rpt_query() 
	DEFINE r_where_text LIKE rmsreps.sel_text
 
	MENU "Cost Selection" 

		BEFORE MENU 
			CALL publish_toolbar("kandoo","IBD","Cost Selection") -- albo kd-505 
			CALL fgl_dialog_setactionlabel("Actual","Actual","{CONTEXT}/public/querix/icon/svg/24/ic_accept_24px.svg",2,FALSE,"Calculate onhand value using actual cost")            
			CALL fgl_dialog_setactionlabel("FIFO","FIFO","{CONTEXT}/public/querix/icon/svg/24/ic_accept_24px.svg",3,FALSE,"Calculate onhand value using FIFO cost")
			CALL fgl_dialog_setactionlabel("LIFO","LIFO","{CONTEXT}/public/querix/icon/svg/24/ic_accept_24px.svg",4,FALSE,"Calculate onhand value using LIFO cost")
			CALL fgl_dialog_setactionlabel("Standard","Standard","{CONTEXT}/public/querix/icon/svg/24/ic_accept_24px.svg",5,FALSE,"Calculate onhand value using standard cost")
			CALL fgl_dialog_setactionlabel("Weighted","Weighted","{CONTEXT}/public/querix/icon/svg/24/ic_accept_24px.svg",6,FALSE,"Calculate onhand value using weighted average cost")

			SELECT cost_ind INTO modu_fifo_lifo_ind FROM inparms 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND parm_code = '1' 
			IF STATUS = NOTFOUND THEN  -- albo
				LET modu_fifo_lifo_ind = "?"
			END IF

			IF modu_fifo_lifo_ind <> "F" THEN 
				HIDE option "FIFO" 
			END IF 
			IF modu_fifo_lifo_ind <> "L" THEN 
				HIDE option "LIFO" 
			END IF

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),NULL) 

		ON ACTION "Actual"  --> Calculate onhand value using actual cost 
			LET modu_cost_selection = "A" 
			EXIT MENU 

		ON ACTION "FIFO"  --> Calculate onhand value using FIFO cost 
			LET modu_cost_selection = "F" 
			EXIT MENU 

		ON ACTION "LIFO"  --> Calculate onhand value using LIFO cost 
			LET modu_cost_selection = "L" 
			EXIT MENU 

		ON ACTION "Standard"  --> Calculate onhand value using standard cost 
			LET modu_cost_selection = "S" 
			EXIT MENU 

		ON ACTION "Weighted"  --> Calculate onhand value using weighted average cost 
			LET modu_cost_selection = "W" 
			EXIT MENU 

		ON ACTION "CANCEL" 
			LET modu_cost_selection = NULL
			EXIT MENU

	END MENU 

	IF int_flag OR quit_flag OR
		modu_cost_selection IS NULL THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN NULL 
	END IF 

	MESSAGE " Enter criteria FOR selection - ESC TO begin search"

	CONSTRUCT BY NAME r_where_text ON
	prodstatus.ware_code, 
	product.part_code, 
	product.desc_text, 
	product.desc2_text, 
	product.prodgrp_code, 
	product.maingrp_code, 
	product.cat_code, 
	product.class_code, 
	product.vend_code, 
	product.oem_text 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","IBD","construct-prodstatus-1") -- albo kd-505 

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
############################################################
# END FUNCTION IBD_rpt_query() 
############################################################

############################################################
# FUNCTION IBD_rpt_process() 
#
# The report driver
############################################################
FUNCTION IBD_rpt_process(p_where_text)
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.* 

	#------------------------------------------------------------
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"IBD_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	

	START REPORT IBD_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	LET l_query_text = 
	"SELECT prodstatus.* ",
	"FROM prodstatus,product ", 
	"WHERE product.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND product.cmpy_code = prodstatus.cmpy_code ", 
	"AND prodstatus.part_code = product.part_code ", 
	"AND product.status_ind != '3' ", 
	"AND prodstatus.status_ind != '3' ", 
	"AND prodstatus.stocked_flag = 'Y' ", 
	"AND ", p_where_text CLIPPED," ",	
	"ORDER BY prodstatus.part_code, ware_code"

	PREPARE s_prodstatus FROM l_query_text 
	DECLARE c_prodstatus CURSOR FOR s_prodstatus 

	FOREACH c_prodstatus INTO l_rec_prodstatus.* 
		#---------------------------------------------------------
		OUTPUT TO REPORT IBD_rpt_list (l_rpt_idx,l_rec_prodstatus.*) 
		IF NOT rpt_int_flag_handler2("Product: ",l_rec_prodstatus.part_code,"",l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------
	END FOREACH

	#------------------------------------------------------------
	FINISH REPORT IBD_rpt_list
	RETURN rpt_finish("IBD_rpt_list")
	#------------------------------------------------------------

END FUNCTION 
############################################################
# END FUNCTION IBD_rpt_process() 
############################################################

############################################################
# FUNCTION get_cost(p_rec_prodstatus,p_onhand_qty)
#
#
############################################################
FUNCTION get_cost(p_rec_prodstatus,p_onhand_qty) 
	DEFINE p_rec_prodstatus RECORD LIKE prodstatus.*
	DEFINE p_onhand_qty LIKE prodstatus.onhand_qty
	DEFINE l_db_status INTEGER 
	DEFINE l_calc_status SMALLINT 
	DEFINE l_fifo_lifo_cost LIKE prodstatus.act_cost_amt 
	DEFINE r_onhand_value LIKE prodstatus.act_cost_amt 

	CASE 
		WHEN modu_cost_selection = "W" 
			LET r_onhand_value = p_onhand_qty * p_rec_prodstatus.wgted_cost_amt 
		WHEN modu_cost_selection = "A" 
			LET r_onhand_value = p_onhand_qty * p_rec_prodstatus.act_cost_amt 
		WHEN modu_cost_selection = "S" 
			LET r_onhand_value = p_onhand_qty * p_rec_prodstatus.est_cost_amt 
		WHEN modu_cost_selection = "F" 
			OR modu_cost_selection = "L" 
			CALL fifo_lifo_issue(glob_rec_kandoouser.cmpy_code,p_rec_prodstatus.part_code,p_rec_prodstatus.ware_code,TODAY, 
										1,"A",p_onhand_qty,modu_fifo_lifo_ind,FALSE)RETURNING l_calc_status,l_db_status,l_fifo_lifo_cost 
			IF l_calc_status THEN 
				LET r_onhand_value = p_onhand_qty * l_fifo_lifo_cost 
			ELSE 
				LET r_onhand_value = p_onhand_qty * p_rec_prodstatus.act_cost_amt 
			END IF 
		OTHERWISE 
			LET r_onhand_value = p_onhand_qty * p_rec_prodstatus.wgted_cost_amt 
	END CASE 

	RETURN r_onhand_value 

END FUNCTION 
############################################################
# END FUNCTION get_cost(p_rec_prodstatus,p_onhand_qty)
############################################################

############################################################
# REPORT IBD_rpt_list(p_rpt_idx,p_rec_prodstatus)
#
# Report Definition/Layout
############################################################
REPORT IBD_rpt_list(p_rpt_idx,p_rec_prodstatus) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_prodstatus RECORD LIKE prodstatus.*
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_unit_sale_amt LIKE prodledg.tran_qty 
	DEFINE l_last_purchase_date DATE 
	DEFINE l_last_sale_date DATE
	DEFINE l_cost_text CHAR(50) 
	DEFINE l_onhand_value LIKE prodstatus.act_cost_amt 
	DEFINE l_lv_tran_date DATE 

	ORDER EXTERNAL BY p_rec_prodstatus.part_code, p_rec_prodstatus.ware_code 

	FORMAT 
		FIRST PAGE HEADER 

			CASE 
				WHEN modu_cost_selection = "A" 
					LET l_cost_text = "Last Actual Cost"
				WHEN modu_cost_selection = "F" 
					LET l_cost_text = "FIFO Cost"
				WHEN modu_cost_selection = "L" 
					LET l_cost_text = "LIFO Cost"
				WHEN modu_cost_selection = "S" 
					LET l_cost_text = "Standard Cost" 
				WHEN modu_cost_selection = "W" 
					LET l_cost_text = "Weighted Average" 
				OTHERWISE 
					LET l_cost_text = "Unknown option using Weighted Average Cost" 
			END CASE 

			CALL rpt_set_page_num(p_rpt_idx,PAGENO) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, "Report Type: ",l_cost_text CLIPPED
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,PAGENO) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, "Report Type: ",l_cost_text CLIPPED
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

	AFTER GROUP OF p_rec_prodstatus.part_code 
		LET l_lv_tran_date=(TODAY - 1 UNITS YEAR) 

		SELECT * INTO l_rec_product.* FROM product 
		WHERE part_code = p_rec_prodstatus.part_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 

		SELECT SUM(tran_qty) INTO l_unit_sale_amt FROM prodledg 
		WHERE part_code = l_rec_product.part_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND (trantype_ind = "S" 
		OR trantype_ind = "C") 
		AND tran_date <= TODAY 
		#AND tran_date >= (TODAY - 1 UNITS YEAR)
		AND tran_date >= l_lv_tran_date 

		LET l_unit_sale_amt = 0 - l_unit_sale_amt 
		IF l_unit_sale_amt IS NULL THEN 
			LET l_unit_sale_amt = 0 
		END IF 
		LET l_last_purchase_date = GROUP MAX(p_rec_prodstatus.last_receipt_date) 
		IF l_last_purchase_date = 0 THEN 
			LET l_last_purchase_date = NULL 
		END IF 

		SELECT MAX(tran_date) INTO l_last_sale_date FROM prodledg 
		WHERE part_code = p_rec_prodstatus.part_code 
		AND ware_code = p_rec_prodstatus.ware_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND trantype_ind = "S" 

		IF l_last_sale_date = "31/12/1899" THEN 
			LET l_last_sale_date = NULL 
		END IF 
		LET l_onhand_value = get_cost(p_rec_prodstatus.*,GROUP SUM(p_rec_prodstatus.onhand_qty)) 

		PRINT COLUMN 01, l_rec_product.part_code, 
		COLUMN 18, l_rec_product.desc_text, 
		COLUMN 55, l_rec_product.cat_code, 
		COLUMN 60, l_rec_product.prodgrp_code, 
		COLUMN 63, GROUP SUM(p_rec_prodstatus.onhand_qty) USING "--,---,--&.&&", 
		COLUMN 78, l_onhand_value USING "--,---,--&.&&", 
		COLUMN 94, l_last_purchase_date, 
		COLUMN 108,l_last_sale_date, 
		COLUMN 119,l_unit_sale_amt USING "--,---,--&.&&" 

	ON LAST ROW 
		SKIP 2 LINES 
		#End Of Report
		IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
			PRINT COLUMN 01,"Selection Criteria:" 
			PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text CLIPPED WORDWRAP RIGHT MARGIN 100 
		END IF 
		PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report 			
		LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = PAGENO

END REPORT
