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
# FUNCTION IB5_main()
#
# Purpose - Critical Status Report
############################################################
FUNCTION IB5_main()

	CALL setModuleId("IB5") 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN "1" #UI/MENU Mode
			OPEN WINDOW I162 WITH FORM "I162" 
			 CALL windecoration_i("I162")
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title
			
			MENU "Minimum Reorder" 

				BEFORE MENU 
					CALL publish_toolbar("kandoo","IB5","menu-Critical_Status-1") -- albo kd-505
					CALL rpt_rmsreps_reset(NULL)
					CALL IB5_rpt_process(IB5_rpt_query())

				ON ACTION "WEB-HELP" -- albo kd-372 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar()

				ON ACTION "Report" #COMMAND "Run Report" " SELECT Criteria AND Print Report"
					CALL rpt_rmsreps_reset(NULL)
					CALL IB5_rpt_process(IB5_rpt_query())

				ON ACTION "PRINT MANAGER" --COMMAND "Print" "Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "CANCEL" --COMMAND KEY (interrupt, "E") "Exit" " Exit TO menus" 
					EXIT MENU

			END MENU
			CLOSE WINDOW I162

		WHEN "2" #Background Process with rmsreps.report_code
			CALL IB5_rpt_process(NULL)  

		WHEN "3" #Only create query-where-part
			OPEN WINDOW I162 with FORM "I162" 
			 CALL windecoration_i("I162") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(IB4_rpt_query()) #save where clause in env 
			CLOSE WINDOW I162 
			
		WHEN "4" #Background Process with SQL WHERE ARGUMENT
			CALL IB5_rpt_process(get_url_sel_text())
	END CASE

END FUNCTION 
############################################################
# END FUNCTION IB5_main()
############################################################

############################################################
# FUNCTION IB5_rpt_query() 
# RETURN r_where_text (Query By Example)
# DataSource for the report driver with CONSTRUCT
############################################################
FUNCTION IB5_rpt_query() 
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
			CALL publish_toolbar("kandoo","IB5","construct-prodstatus-1") -- albo kd-505 

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
# END FUNCTION IB5_rpt_query() 
############################################################

############################################################
# FUNCTION IB5_rpt_process(p_where_text)
#
# The report driver
############################################################
FUNCTION IB5_rpt_process(p_where_text)
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT
	DEFINE l_rec_report_line RECORD 
		part_code LIKE prodstatus.part_code, 
		ware_code LIKE prodstatus.ware_code, 
		onhand_qty LIKE prodstatus.onhand_qty, 
		onord_qty LIKE prodstatus.onord_qty, 
		reserved_qty LIKE prodstatus.reserved_qty, 
		back_qty LIKE prodstatus.back_qty, 
		forward_qty LIKE prodstatus.forward_qty, 
		critical_qty LIKE prodstatus.critical_qty, 
		desc_text LIKE product.desc_text, 
		desc2_text LIKE product.desc2_text 
	END RECORD 

	#------------------------------------------------------------
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"IB5_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	

	START REPORT IB5_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	LET l_query_text = 
	"SELECT prodstatus.part_code,", 
	"prodstatus.ware_code,", 
	"prodstatus.onhand_qty,", 
	"prodstatus.onord_qty,", 
	"prodstatus.reserved_qty,", 
	"prodstatus.back_qty,", 
	"prodstatus.forward_qty,", 
	"prodstatus.critical_qty,", 
	"product.desc_text,", 
	"product.desc2_text " , 
	"FROM prodstatus,product ", 
	"WHERE prodstatus.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND product.cmpy_code = prodstatus.cmpy_code ", 
	"AND product.part_code = prodstatus.part_code ", 
	"AND ", p_where_text CLIPPED," ", 
	"ORDER BY prodstatus.part_code,prodstatus.ware_code" 

	PREPARE s_report_line FROM l_query_text 
	DECLARE c_report_line CURSOR FOR s_report_line 

	FOREACH c_report_line INTO l_rec_report_line.* 
		IF (l_rec_report_line.onhand_qty 
		+ l_rec_report_line.onord_qty 
		- l_rec_report_line.reserved_qty 
		- l_rec_report_line.back_qty 
		- l_rec_report_line.forward_qty) < l_rec_report_line.critical_qty THEN 
		#---------------------------------------------------------
		OUTPUT TO REPORT IB5_rpt_list (l_rpt_idx,l_rec_report_line.*) 
		IF NOT rpt_int_flag_handler2("Product: ",l_rec_report_line.part_code,"",l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------
		END IF
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT IB5_rpt_list
	RETURN rpt_finish("IB5_rpt_list")
	#------------------------------------------------------------

END FUNCTION 
############################################################
# FUNCTION IB5_rpt_process(p_where_text)
############################################################

############################################################
# REPORT IB5_rpt_list(p_rpt_idx,p_rec_report_line)
#
# Report Definition/Layout
############################################################
REPORT IB5_rpt_list(p_rpt_idx,p_rec_report_line) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_report_line RECORD 
		part_code LIKE prodstatus.part_code, 
		ware_code LIKE prodstatus.ware_code, 
		onhand_qty LIKE prodstatus.onhand_qty, 
		onord_qty LIKE prodstatus.onord_qty, 
		reserved_qty LIKE prodstatus.reserved_qty, 
		back_qty LIKE prodstatus.back_qty, 
		forward_qty LIKE prodstatus.forward_qty, 
		critical_qty LIKE prodstatus.critical_qty, 
		desc_text LIKE product.desc_text, 
		desc2_text LIKE product.desc2_text 
	END RECORD 
	DEFINE l_avail LIKE prodstatus.onhand_qty 
	DEFINE l_tot_avail LIKE prodstatus.onhand_qty 

	ORDER external BY p_rec_report_line.part_code 

	FORMAT 
		FIRST PAGE HEADER
			LET l_avail = 0 
			LET l_tot_avail = 0
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

	BEFORE GROUP OF p_rec_report_line.part_code 
		NEED 3 LINES 
		LET l_tot_avail = 0 
		PRINT COLUMN 1, "Product: ", 
		COLUMN 12, p_rec_report_line.part_code CLIPPED, 
		COLUMN 30, p_rec_report_line.desc_text CLIPPED
		IF p_rec_report_line.desc2_text IS NULL 
		OR p_rec_report_line.desc2_text = " " THEN 
		ELSE 
			PRINT COLUMN 30, p_rec_report_line.desc2_text CLIPPED 
		END IF

	ON EVERY ROW 
		LET l_avail = p_rec_report_line.onhand_qty 
		- p_rec_report_line.reserved_qty 
		- p_rec_report_line.back_qty 
		PRINT COLUMN 1, p_rec_report_line.ware_code, 
		COLUMN 13, p_rec_report_line.onhand_qty USING "----,--&.&&", 
		COLUMN 31, p_rec_report_line.reserved_qty USING "----,--&.&&", 
		COLUMN 49, p_rec_report_line.back_qty USING "----,--&.&&", 
		COLUMN 67, l_avail USING "----,--&.&&", 
		COLUMN 85, p_rec_report_line.critical_qty USING "----,--&.&&", 
		COLUMN 103, p_rec_report_line.onord_qty USING "----,--&.&&", 
		COLUMN 121, p_rec_report_line.forward_qty USING "----,--&.&&" 
		LET l_tot_avail = l_tot_avail + l_avail 
			
	AFTER GROUP OF p_rec_report_line.part_code 
		NEED 3 LINES 
		PRINT COLUMN 11, "----------------------------------------", 
		"----------------------------------------", 
		"-----------------------------------------" 
		PRINT COLUMN 1, "Totals:", 
		COLUMN 13, GROUP sum(p_rec_report_line.onhand_qty) USING "----,--&.&&", 
		COLUMN 31, GROUP sum(p_rec_report_line.reserved_qty) USING "----,--&.&&", 
		COLUMN 49, GROUP sum(p_rec_report_line.back_qty) USING "----,--&.&&", 
		COLUMN 67, l_tot_avail USING "----,--&.&&", 
		COLUMN 85, GROUP sum(p_rec_report_line.critical_qty) USING "----,--&.&&", 
		COLUMN 103, GROUP sum(p_rec_report_line.onord_qty) USING "----,--&.&&", 
		COLUMN 121, GROUP sum(p_rec_report_line.forward_qty) USING "----,--&.&&" 
		SKIP 1 LINE 
			
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
