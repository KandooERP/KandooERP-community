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
# FUNCTION IR1_main()
#
# Purpose - Period Activity Report
############################################################
FUNCTION IR1_main() 

	CALL setModuleId("IR1") 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN "1" #UI/MENU Mode
			OPEN WINDOW I112 WITH FORM "I112" 
			 CALL windecoration_i("I112")
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title
			
			MENU "Period Activity" 

				BEFORE MENU 
					CALL publish_toolbar("kandoo","IR1","menu-Period_Activity-1") -- albo kd-505
					CALL rpt_rmsreps_reset(NULL)
					CALL IR1_rpt_process(IR1_rpt_query())

				ON ACTION "WEB-HELP" -- albo kd-372 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar()

				ON ACTION "Report" #COMMAND "Run Report" " SELECT Criteria AND Print Report"
					CALL rpt_rmsreps_reset(NULL)
					CALL IR1_rpt_process(IR1_rpt_query())

				ON ACTION "PRINT MANAGER" --COMMAND "Print" "Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "CANCEL" --COMMAND KEY (interrupt, "E") "Exit" " Exit TO menus" 
					EXIT MENU

			END MENU
			CLOSE WINDOW I112

		WHEN "2" #Background Process with rmsreps.report_code
			CALL IR1_rpt_process(NULL)  

		WHEN "3" #Only create query-where-part
			OPEN WINDOW I112 with FORM "I112" 
			 CALL windecoration_i("I112") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(IR1_rpt_query()) #save where clause in env 
			CLOSE WINDOW I112 
			
		WHEN "4" #Background Process with SQL WHERE ARGUMENT
			CALL IR1_rpt_process(get_url_sel_text())
	END CASE	

END FUNCTION 
############################################################
# END FUNCTION IR1_main()
############################################################ 

############################################################
# FUNCTION IR1_rpt_query() 
# RETURN r_where_text (Query By Example)
# DataSource for the report driver with CONSTRUCT
############################################################
FUNCTION IR1_rpt_query() 
	DEFINE r_where_text LIKE rmsreps.sel_text

	MESSAGE " Enter criteria FOR selection - ESC TO begin search"
 
	CONSTRUCT r_where_text ON 
	prodledg.part_code, 
	product.desc_text, 
	prodledg.ware_code, 
	warehouse.desc_text, 
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
	prodledg.ware_code, 
	warehouse.desc_text, 
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
			CALL publish_toolbar("kandoo","IR1","construct-prodledg-1") -- albo kd-505 

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
# END FUNCTION IR1_rpt_query() 
############################################################

############################################################
# FUNCTION IR1_rpt_process(p_where_text) 
# 
# The report driver
############################################################
FUNCTION IR1_rpt_process(p_where_text)
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT
	DEFINE l_rec_prodledg RECORD 
		part_code LIKE prodledg.part_code, 
		desc_text LIKE product.desc_text, 
		ware_code LIKE prodledg.ware_code, 
		desc1_text LIKE warehouse.desc_text, 
		tran_date LIKE prodledg.tran_date, 
		year_num LIKE prodledg.year_num, 
		period_num LIKE prodledg.period_num, 
		trantype_ind LIKE prodledg.trantype_ind, 
		source_text LIKE prodledg.source_text, 
		source_num LIKE prodledg.source_num, 
		tran_qty LIKE prodledg.tran_qty, 
		cost_amt LIKE prodledg.cost_amt, 
		sales_amt LIKE prodledg.sales_amt, 
		ecost money(12,2), 
		eprice money(12,2) 
	END RECORD

	#------------------------------------------------------------
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE
		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"IR1_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	

	START REPORT IR1_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	LET l_query_text = 
	"SELECT prodledg.part_code,", 
	"product.desc_text,", 
	"prodledg.ware_code,", 
	"warehouse.desc_text,", 
	"prodledg.tran_date,", 
	"prodledg.year_num,", 
	"prodledg.period_num,", 
	"prodledg.trantype_ind,", 
	"prodledg.source_text,", 
	"prodledg.source_num,", 
	"prodledg.tran_qty,", 
	"prodledg.cost_amt,", 
	"prodledg.sales_amt ", 
	"FROM prodledg,product,warehouse ", 
	"WHERE prodledg.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND product.part_code = prodledg.part_code ", 
	"AND product.cmpy_code = prodledg.cmpy_code ", 
	"AND warehouse.cmpy_code = prodledg.cmpy_code ", 
	"AND warehouse.ware_code = prodledg.ware_code ", 
	"AND ", p_where_text CLIPPED," ", 
	"ORDER BY prodledg.trantype_ind,prodledg.part_code,prodledg.ware_code" 

	PREPARE choice FROM l_query_text 
	DECLARE selcurs CURSOR FOR choice 

	FOREACH selcurs INTO l_rec_prodledg.* 
		LET l_rec_prodledg.ecost = l_rec_prodledg.tran_qty * l_rec_prodledg.cost_amt 
		LET l_rec_prodledg.eprice = l_rec_prodledg.tran_qty * l_rec_prodledg.sales_amt 
		IF l_rec_prodledg.trantype_ind = "S" OR l_rec_prodledg.trantype_ind = "C" THEN 
			LET l_rec_prodledg.eprice = -l_rec_prodledg.eprice 
		END IF 
		#---------------------------------------------------------
		OUTPUT TO REPORT IR1_rpt_list(l_rpt_idx,l_rec_prodledg.*) 
		IF NOT rpt_int_flag_handler2("Product: ",l_rec_prodledg.part_code,"",l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT IR1_rpt_list
	RETURN rpt_finish("IR1_rpt_list")
	#------------------------------------------------------------

END FUNCTION 
############################################################
# END FUNCTION IR1_rpt_process() 
############################################################

############################################################
# REPORT IR1_rpt_list(p_rpt_idx,p_rec_prodledg)
#
# Report Definition/Layout
############################################################
REPORT IR1_rpt_list(p_rpt_idx,p_rec_prodledg) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_prodledg RECORD 
		part_code LIKE prodledg.part_code, 
		desc_text LIKE product.desc_text, 
		ware_code LIKE prodledg.ware_code, 
		desc1_text LIKE warehouse.desc_text, 
		tran_date LIKE prodledg.tran_date, 
		year_num LIKE prodledg.year_num, 
		period_num LIKE prodledg.period_num, 
		trantype_ind LIKE prodledg.trantype_ind, 
		source_text LIKE prodledg.source_text, 
		source_num LIKE prodledg.source_num, 
		tran_qty LIKE prodledg.tran_qty, 
		cost_amt LIKE prodledg.cost_amt, 
		sales_amt LIKE prodledg.sales_amt, 
		ecost money(12,2), 
		eprice money(12,2) 
	END RECORD 
	DEFINE l_whatitis CHAR(30) 

	ORDER EXTERNAL BY p_rec_prodledg.trantype_ind,p_rec_prodledg.part_code,p_rec_prodledg.ware_code 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,PAGENO) #update page number and report header line 1
			CASE (p_rec_prodledg.trantype_ind) 
				WHEN "A" LET l_whatitis = "Adjustments" 
				WHEN "B" LET l_whatitis = "Backorders" 
				WHEN "S" LET l_whatitis = "Sales" 
				WHEN "C" LET l_whatitis = "Credits" 
				WHEN "R" LET l_whatitis = "Receipts" 
				WHEN "I" LET l_whatitis = "Issues" 
				WHEN "T" LET l_whatitis = "Transfers" 
				WHEN "P" LET l_whatitis = "Purchases" 
			END CASE 

			PRINT COLUMN 1, "Activity: ", l_whatitis CLIPPED 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 CLIPPED #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 CLIPPED #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text CLIPPED 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text CLIPPED 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]

	BEFORE GROUP OF p_rec_prodledg.trantype_ind 
		SKIP TO TOP OF PAGE 

	BEFORE GROUP OF p_rec_prodledg.part_code 
		SKIP 1 LINES 
		PRINT COLUMN 1, "Product: ", p_rec_prodledg.part_code CLIPPED,"  ", p_rec_prodledg.desc_text CLIPPED 

	BEFORE GROUP OF p_rec_prodledg.ware_code 
		SKIP 1 LINE 
		PRINT COLUMN 1, "Warehouse: ", p_rec_prodledg.ware_code CLIPPED,"  ", p_rec_prodledg.desc1_text CLIPPED 
		SKIP 1 LINE

	ON EVERY ROW 
		PRINT COLUMN 01,p_rec_prodledg.tran_date     USING "dd/mm/yy", 
		COLUMN 10,p_rec_prodledg.source_text CLIPPED, 
		COLUMN 25,p_rec_prodledg.source_num          USING "########", 
		COLUMN 35,p_rec_prodledg.tran_qty            USING "---,---,--&.&&", 
		COLUMN 50,p_rec_prodledg.cost_amt            USING "--,---,--&.&&&&", 
		COLUMN 66,p_rec_prodledg.ecost               USING "---,---,--&.&&", 
		COLUMN 81,p_rec_prodledg.sales_amt           USING "---,---,--&.&&", 
		COLUMN 96,p_rec_prodledg.eprice              USING "---,---,--&.&&" 

	AFTER GROUP OF p_rec_prodledg.trantype_ind 
		PRINT COLUMN 35, "---------------------------------------------", 
		"---------------------------------" 
		PRINT COLUMN 5, "Total Activity: ", 
		COLUMN 35,NVL(GROUP SUM(p_rec_prodledg.tran_qty),0)USING "---,---,--&.&&", 
		COLUMN 66,NVL(GROUP SUM(p_rec_prodledg.ecost),0) 	USING "---,---,--&.&&", 
		COLUMN 96,NVL(GROUP SUM(p_rec_prodledg.eprice),0)	USING "---,---,--&.&&" 

	AFTER GROUP OF p_rec_prodledg.part_code 
		PRINT COLUMN 35, "---------------------------------------------", 
		"---------------------------------" 
		PRINT COLUMN 5, "Total Item: ", 
		COLUMN 35,NVL(GROUP SUM(p_rec_prodledg.tran_qty),0)USING "---,---,--&.&&", 
		COLUMN 66,NVL(GROUP SUM(p_rec_prodledg.ecost),0) 	USING "---,---,--&.&&", 
		COLUMN 96,NVL(GROUP SUM(p_rec_prodledg.eprice),0)	USING "---,---,--&.&&" 

	AFTER GROUP OF p_rec_prodledg.ware_code 
		PRINT COLUMN 35, "---------------------------------------------", 
		"---------------------------------" 
		PRINT COLUMN 5, "Total Warehouse: ", 
		COLUMN 35,NVL(GROUP SUM(p_rec_prodledg.tran_qty),0)USING "---,---,--&.&&", 
		COLUMN 66,NVL(GROUP SUM(p_rec_prodledg.ecost),0) 	USING "---,---,--&.&&", 
		COLUMN 96,NVL(GROUP SUM(p_rec_prodledg.eprice),0)	USING "---,---,--&.&&" 

	ON LAST ROW 
		NEED 6 LINES 
		PRINT COLUMN 35, "=============================================", 
		"=================================" 
		PRINT COLUMN 5, "Total: ", 
		COLUMN 35,NVL(SUM(p_rec_prodledg.tran_qty),0)      USING "---,---,--&.&&", 
		COLUMN 66,NVL(SUM(p_rec_prodledg.ecost),0)         USING "---,---,--&.&&", 
		COLUMN 96,NVL(SUM(p_rec_prodledg.eprice),0)        USING "---,---,--&.&&" 
		#End Of Report
		SKIP 1 LINE
		IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
			PRINT COLUMN 01,"Selection Criteria:" 
			PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text CLIPPED WORDWRAP RIGHT MARGIN 100 
		END IF 
		PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report 			
		LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = PAGENO

END REPORT 
