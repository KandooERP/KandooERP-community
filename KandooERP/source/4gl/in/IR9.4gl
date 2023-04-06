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
DEFINE modu_year_num LIKE prodledg.year_num 
DEFINE modu_period_num LIKE prodledg.period_num

############################################################
# FUNCTION IR9_main()
#
# Purpose - Inventory Snapshot Report.
############################################################
FUNCTION IR9_main()

	CALL setModuleId("IR9") 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN "1" #UI/MENU Mode
			OPEN WINDOW I178 WITH FORM "I178" 
			 CALL windecoration_i("I178")
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title
			
			MENU "Inventory Snapshot" 

				BEFORE MENU 
					CALL publish_toolbar("kandoo","IR9","menu-Investment_Report-1") -- albo kd-505
					CALL rpt_rmsreps_reset(NULL)
					CALL IR9_rpt_process(IR9_rpt_query())

				ON ACTION "WEB-HELP" -- albo kd-372 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar()

				ON ACTION "Report" #COMMAND "Run Report" " SELECT Criteria AND Print Report"
					CALL rpt_rmsreps_reset(NULL)
					CALL IR9_rpt_process(IR9_rpt_query())

				ON ACTION "PRINT MANAGER" --COMMAND "Print" "Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "CANCEL" --COMMAND KEY (interrupt, "E") "Exit" " Exit TO menus" 
					EXIT MENU

			END MENU
			CLOSE WINDOW I178

		WHEN "2" #Background Process with rmsreps.report_code
			CALL IR9_rpt_process(NULL)  

		WHEN "3" #Only create query-where-part
			OPEN WINDOW I178 with FORM "I178" 
			 CALL windecoration_i("I178") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(IR9_rpt_query()) #save where clause in env 
			CLOSE WINDOW I178 
			
		WHEN "4" #Background Process with SQL WHERE ARGUMENT
			CALL IR9_rpt_process(get_url_sel_text())
	END CASE

END FUNCTION 
############################################################
# END FUNCTION IR9_main()
############################################################

############################################################
# FUNCTION IR9_rpt_query() 
# RETURN r_where_text (Query By Example)
# DataSource for the report driver with CONSTRUCT
############################################################
FUNCTION IR9_rpt_query() 
	DEFINE r_where_text LIKE rmsreps.sel_text
	DEFINE l_cnt INTEGER

	INPUT modu_year_num,modu_period_num FROM year_num,period_num 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","IR9","input-pr_year_num-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 
			IF modu_year_num IS NULL OR modu_year_num = 0 THEN 
				ERROR "You must enter a year" 
				NEXT FIELD year_num 
			END IF 
			IF modu_period_num IS NULL OR modu_period_num = 0 THEN 
				ERROR "You must enter a period" 
				NEXT FIELD period_num 
			END IF 
			SELECT COUNT(*) INTO l_cnt FROM prodledg 
			WHERE (prodledg.year_num < modu_year_num	OR (prodledg.year_num = modu_year_num AND prodledg.period_num <= modu_period_num )) AND 
					prodledg.cmpy_code = glob_rec_kandoouser.cmpy_code	AND 
					post_flag = "Y" 
			IF l_cnt = 0 THEN 
				ERROR "There are no rows FOR this criteria" 
            CONTINUE INPUT
			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN NULL 
	ELSE 
		LET r_where_text = "(prodledg.year_num < ",modu_year_num," OR (prodledg.year_num = ",modu_year_num," AND prodledg.period_num <= ",modu_period_num,"))"
		RETURN r_where_text
	END IF

END FUNCTION 
############################################################
# END FUNCTION IR9_rpt_query() 
############################################################

############################################################
# FUNCTION IR9_rpt_process(p_where_text) 
# 
# The report driver
############################################################
FUNCTION IR9_rpt_process(p_where_text)
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT
	DEFINE l_rec_prodledg RECORD LIKE prodledg.*
	DEFINE l_total_cost_amt LIKE invoicedetl.ext_cost_amt 

	#------------------------------------------------------------
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE
		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"IR9_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	

	START REPORT IR9_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	LET l_query_text =
	"SELECT * ", 
	"FROM prodledg ", 
	"WHERE ",p_where_text CLIPPED," ", 
	"AND prodledg.cmpy_code = '",glob_rec_kandoouser.cmpy_code CLIPPED,"' ", 
	"AND prodledg.post_flag = 'Y' ", 
	"ORDER BY prodledg.part_code,prodledg.ware_code" 

	PREPARE s_product FROM l_query_text
	DECLARE c_1 CURSOR FOR s_product

	FOREACH c_1 INTO l_rec_prodledg.* 
		IF l_rec_prodledg.cost_amt IS NULL THEN 
			LET l_rec_prodledg.cost_amt = 0 
		END IF 
		IF l_rec_prodledg.tran_qty IS NULL THEN 
			LET l_rec_prodledg.tran_qty = 0 
		END IF 
		LET l_total_cost_amt = l_rec_prodledg.tran_qty * l_rec_prodledg.cost_amt 
		IF l_rec_prodledg.trantype_ind = "U" THEN # THEN we dont want qty 
			LET l_rec_prodledg.tran_qty = 0 
		END IF 
		#---------------------------------------------------------
		OUTPUT TO REPORT IR9_rpt_list(l_rpt_idx,l_rec_prodledg.*,l_total_cost_amt) 
		IF NOT rpt_int_flag_handler2("Product: ",l_rec_prodledg.part_code,"",l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT IR9_rpt_list
	RETURN rpt_finish("IR9_rpt_list")
	#------------------------------------------------------------
 
END FUNCTION 
############################################################
# END FUNCTION IR9_rpt_process() 
############################################################

############################################################
# REPORT IR9_rpt_list(p_rpt_idx,p_rec_prodledg,p_total_cost_amt)
#
# Report Definition/Layout
############################################################
REPORT IR9_rpt_list(p_rpt_idx,p_rec_prodledg,p_total_cost_amt) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_prodledg RECORD LIKE prodledg.* 
	DEFINE p_total_cost_amt LIKE invoicedetl.ext_cost_amt 
	DEFINE l_warehouse CHAR(27) 
	DEFINE l_ware_count SMALLINT
	DEFINE l_line CHAR(80)	
	DEFINE l_offset SMALLINT

	ORDER EXTERNAL BY p_rec_prodledg.part_code,p_rec_prodledg.ware_code

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,PAGENO) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 CLIPPED #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 CLIPPED #wasl_arr_line[2] 
			LET l_line = "Year: ",modu_year_num USING "####"," Period: ",modu_period_num USING "###" 
			LET l_offset = (LENGTH(glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3) - LENGTH(l_line))/2 
			PRINT COLUMN l_offset, l_line CLIPPED 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text CLIPPED 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]

	BEFORE GROUP OF p_rec_prodledg.part_code 
		LET l_ware_count = 0
		SKIP 1 LINE 
 		PRINT COLUMN 1, "Product: ", p_rec_prodledg.part_code CLIPPED 

	AFTER GROUP OF p_rec_prodledg.ware_code 
		LET l_ware_count = l_ware_count + 1 
		SELECT desc_text INTO l_warehouse FROM warehouse 
		WHERE warehouse.cmpy_code = glob_rec_kandoouser.cmpy_code AND 
				warehouse.ware_code = p_rec_prodledg.ware_code 
		IF STATUS = NOTFOUND THEN 
			LET l_warehouse = " " 
		END IF 

		PRINT COLUMN 1, p_rec_prodledg.ware_code CLIPPED, 
		COLUMN 5,  l_warehouse CLIPPED, 
		COLUMN 33, NVL(GROUP SUM(p_rec_prodledg.tran_qty),0)                                        USING "---,---,--&.&&", 
		COLUMN 50, NVL(GROUP SUM(p_total_cost_amt),0)                                               USING "---,---,--&.&&", 
		COLUMN 67; 
		IF NVL(GROUP SUM(p_rec_prodledg.tran_qty),0) != 0 THEN 
			PRINT (NVL(GROUP SUM(p_total_cost_amt),0) / NVL(GROUP SUM(p_rec_prodledg.tran_qty),0))   USING "---,---,--&.&&" 
		ELSE 
			PRINT 
		END IF 

	AFTER GROUP OF p_rec_prodledg.part_code 
		IF l_ware_count > 1 THEN 
			PRINT COLUMN 33, "--------------", 
			COLUMN 50, "--------------", 
			COLUMN 67; 
			IF NVL(GROUP SUM(p_rec_prodledg.tran_qty),0) != 0 THEN 
				PRINT "--------------" 
			ELSE 
				PRINT 
			END IF 
			PRINT COLUMN 1, "TOTAL", 
			COLUMN 33, NVL(GROUP SUM(p_rec_prodledg.tran_qty),0)                                     USING "---,---,--&.&&", 
			COLUMN 50, NVL(GROUP SUM(p_total_cost_amt),0) 	                                         USING "---,---,--&.&&", 
			COLUMN 67; 
			IF NVL(GROUP SUM(p_rec_prodledg.tran_qty),0) != 0 THEN 
				PRINT (NVL(GROUP SUM(p_total_cost_amt),0) / NVL(GROUP SUM(p_rec_prodledg.tran_qty),0))USING "---,---,--&.&&" 
			ELSE 
				PRINT 
			END IF 
		END IF 

	ON LAST ROW 
		NEED 3 LINES 
		SKIP 1 LINE 
		PRINT COLUMN 50, "==============" 
		PRINT COLUMN 1, "Inventory Balance", 
		COLUMN 50, NVL(SUM(p_total_cost_amt),0)	                                                  USING "---,---,--&.&&" 
		SKIP 1 LINE
		#End Of Report
		IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
			PRINT COLUMN 01,"Selection Criteria:" 
			PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text CLIPPED WORDWRAP RIGHT MARGIN 100 
		END IF 
		PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report 			
		LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = PAGENO

END REPORT 
