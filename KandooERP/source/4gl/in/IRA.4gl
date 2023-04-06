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
DEFINE modu_year_num LIKE prodhist.year_num 
DEFINE modu_period_num LIKE prodhist.period_num 

############################################################
# FUNCTION IRA_main()
#
# Purpose - Inventory History Report.
############################################################
FUNCTION IRA_main()

	CALL setModuleId("IRA") 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN "1" #UI/MENU Mode
			OPEN WINDOW I169a WITH FORM "I169a" 
			 CALL windecoration_i("I169a")
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title
			
			MENU "Inventory History" 

				BEFORE MENU 
					CALL publish_toolbar("kandoo","IRA","menu-History_Report-1") -- albo kd-505
					CALL rpt_rmsreps_reset(NULL)
					CALL IRA_rpt_process(IRA_rpt_query())

				ON ACTION "WEB-HELP" -- albo kd-372 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar()

				ON ACTION "Report" #COMMAND "Run Report" " SELECT Criteria AND Print Report"
					CALL rpt_rmsreps_reset(NULL)
					CALL IRA_rpt_process(IRA_rpt_query())

				ON ACTION "PRINT MANAGER" --COMMAND "Print" "Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "CANCEL" --COMMAND KEY (interrupt, "E") "Exit" " Exit TO menus" 
					EXIT MENU

			END MENU
			CLOSE WINDOW I169a

		WHEN "2" #Background Process with rmsreps.report_code
			CALL IRA_rpt_process(NULL)  

		WHEN "3" #Only create query-where-part
			OPEN WINDOW I169a WITH FORM "I169a" 
			 CALL windecoration_i("I169a") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(IRA_rpt_query()) #save where clause in env 
			CLOSE WINDOW I169a 
			
		WHEN "4" #Background Process with SQL WHERE ARGUMENT
			CALL IRA_rpt_process(get_url_sel_text())
	END CASE

END FUNCTION 
############################################################
# END FUNCTION IRA_main()
############################################################

############################################################
# FUNCTION IRA_rpt_query() 
# RETURN r_where_text (Query By Example)
# DataSource for the report driver with CONSTRUCT
############################################################
FUNCTION IRA_rpt_query() 
	DEFINE r_where_text LIKE rmsreps.sel_text

	CLEAR FORM 
	CONSTRUCT BY NAME r_where_text ON 
	prodstatus.part_code, 
	product.desc_text, 
	product.desc2_text, 
	product.prodgrp_code, 
	product.maingrp_code, 
	product.cat_code, 
	product.class_code, 
	prodstatus.ware_code, 
	prodstatus.onhand_qty, 
	prodstatus.back_qty, 
	prodstatus.bin1_text, 
	prodstatus.bin2_text, 
	prodstatus.bin3_text, 
	prodstatus.last_sale_date, 
	prodstatus.last_receipt_date, 
	prodstatus.stocked_flag, 
	prodstatus.stockturn_qty 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","IRA","construct-prodstatus-1") -- albo kd-505 
			MESSAGE " Enter criteria FOR selection - ESC TO begin search"

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN NULL 
	END IF 

	OPEN WINDOW I170a WITH FORM "I170a" 
	 CALL windecoration_i("I170a") -- albo kd-758 
	CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,TODAY) RETURNING modu_year_num, modu_period_num 

	INPUT modu_year_num,modu_period_num WITHOUT DEFAULTS FROM year_num,period_num 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","IRA","input-pr_year_num-1") -- albo kd-505 
			MESSAGE " Enter criteria FOR selection - ESC TO begin search"

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 
			IF modu_year_num IS NULL THEN 
				ERROR kandoomsg2("A",9102,"") 
				NEXT FIELD year_num 
			END IF 
			IF modu_period_num IS NULL THEN 
				ERROR kandoomsg2("A",9102,"") 
				NEXT FIELD period_num 
			END IF 
			IF modu_period_num = 0 THEN 
				ERROR kandoomsg2("G",9025,"Period") 
				NEXT FIELD period_num 
			END IF 

	END INPUT 
	CLOSE WINDOW I170a 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN NULL 
	ELSE 
		RETURN r_where_text
	END IF

END FUNCTION 
############################################################
# END FUNCTION IRA_rpt_query() 
############################################################

############################################################
# FUNCTION IRA_rpt_process(p_where_text) 
# 
# The report driver
############################################################
FUNCTION IRA_rpt_process(p_where_text)
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_ware_code LIKE prodstatus.ware_code 

	#------------------------------------------------------------
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE
		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"IRA_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	

	START REPORT IRA_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	LET l_query_text = 
	"SELECT product.part_code,product.desc_text,prodstatus.ware_code ", 
	"FROM product,prodstatus ", 
	"WHERE product.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND prodstatus.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND product.part_code = prodstatus.part_code ", 
	"AND ", p_where_text CLIPPED," ", 
	"ORDER BY product.desc_text" 

	PREPARE choice FROM l_query_text 
	DECLARE selcurs CURSOR FOR choice 

	FOREACH selcurs INTO l_rec_product.part_code,l_rec_product.desc_text,l_ware_code 
		#---------------------------------------------------------
		OUTPUT TO REPORT IRA_rpt_list(l_rpt_idx,glob_rec_kandoouser.cmpy_code,l_rec_product.part_code,
												l_rec_product.desc_text,l_ware_code,modu_year_num,modu_period_num) 
		IF NOT rpt_int_flag_handler2("Product: ",l_rec_product.part_code,"",l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT IRA_rpt_list
	RETURN rpt_finish("IRA_rpt_list")
	#------------------------------------------------------------

END FUNCTION 
############################################################
# END FUNCTION IRA_rpt_process() 
############################################################

############################################################
# REPORT IRA_rpt_list(p_rpt_idx,p_cmpy_code,p_part_code,p_desc_text,p_ware_code,p_year_num,p_period_num)
#
# Report Definition/Layout
############################################################
REPORT IRA_rpt_list(p_rpt_idx,p_cmpy_code,p_part_code,p_desc_text,p_ware_code,p_year_num,p_period_num) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_cmpy_code LIKE kandoouser.cmpy_code
	DEFINE p_part_code LIKE product.part_code 
	DEFINE p_desc_text LIKE product.desc_text 
	DEFINE p_ware_code LIKE prodstatus.ware_code 
	DEFINE p_year_num LIKE prodhist.year_num
	DEFINE p_period_num LIKE prodhist.period_num 
	DEFINE l_arr_months ARRAY[11] OF RECORD 
		months_ago LIKE prodhist.sales_qty 
	END RECORD
	DEFINE l_current LIKE prodhist.sales_qty
	DEFINE l_ytd LIKE prodhist.sales_qty
	DEFINE l_end_qty LIKE prodhist.end_qty
	DEFINE l_line STRING	
	DEFINE l_offset SMALLINT
	DEFINE i SMALLINT

	ORDER EXTERNAL BY p_desc_text 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,PAGENO) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 CLIPPED #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 CLIPPED #wasl_arr_line[2]
			LET l_line = " by Product for "||p_year_num USING "&&&&"||" Period "||p_period_num USING "&&"  
			LET l_offset = (LENGTH(glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3) - LENGTH(l_line))/2
			PRINT COLUMN l_offset, l_line CLIPPED
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]
         PRINT COLUMN 01, "Product Code    Description                          Ware Code"
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text CLIPPED 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text CLIPPED 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]

	ON EVERY ROW 
		FOR i = 1 TO 11 
			INITIALIZE l_arr_months[i].months_ago TO NULL 
			LET p_period_num = p_period_num - 1 
			IF p_period_num = 0 THEN 
				LET p_period_num = 12 
				LET p_year_num = p_year_num - 1 
			END IF 
			SELECT prodhist.sales_qty - prodhist.credit_qty INTO l_arr_months[i].months_ago FROM prodhist 
			WHERE prodhist.cmpy_code = p_cmpy_code AND 
					prodhist.part_code = p_part_code AND 
					prodhist.ware_code = p_ware_code AND 
					prodhist.year_num  = p_year_num	 AND 
					prodhist.period_num = p_period_num 
			IF l_arr_months[i].months_ago IS NULL THEN
				LET l_arr_months[i].months_ago = 0
			END IF 
		END FOR 

		LET l_current = NULL 
		SELECT prodhist.sales_qty - prodhist.credit_qty INTO l_current FROM prodhist 
		WHERE prodhist.cmpy_code = p_cmpy_code AND 
				prodhist.part_code = p_part_code AND 
				prodhist.ware_code = p_ware_code AND 
				prodhist.year_num  = p_year_num  AND 
				prodhist.period_num = p_period_num 
		IF l_current IS NULL THEN 
			LET l_current = 0 
		END IF 

		LET l_ytd = NULL 
		SELECT SUM(prodhist.sales_qty - prodhist.credit_qty) INTO l_ytd FROM prodhist 
		WHERE prodhist.cmpy_code = p_cmpy_code AND 
				prodhist.part_code = p_part_code AND 
				prodhist.ware_code = p_ware_code AND 
				prodhist.year_num  = p_year_num  AND 
				prodhist.period_num <= p_period_num 
		IF l_ytd IS NULL THEN 
			LET l_ytd = 0 
		END IF 

		LET l_end_qty = NULL 
		SELECT SUM(prodledg.tran_qty) INTO l_end_qty FROM prodledg 
		WHERE prodledg.cmpy_code = p_cmpy_code AND 
				prodledg.part_code = p_part_code AND 
				prodledg.ware_code = p_ware_code AND 
				(prodledg.year_num < p_year_num OR	(prodledg.year_num = p_year_num AND prodledg.period_num <= p_period_num)) AND 
				prodledg.trantype_ind != "U" 
		IF l_end_qty IS NULL THEN 
			LET l_end_qty = 0 
		END IF 

		PRINT 
		COLUMN 01, p_part_code CLIPPED, 
		COLUMN 17, p_desc_text CLIPPED, 
		COLUMN 54, p_ware_code CLIPPED 
		PRINT
		COLUMN 01, l_arr_months[11].months_ago USING "-----&.&&",  
		COLUMN 10, l_arr_months[10].months_ago USING "-----&.&&", 
		COLUMN 19, l_arr_months[9].months_ago  USING "-----&.&&", 
		COLUMN 28, l_arr_months[8].months_ago  USING "-----&.&&", 
		COLUMN 37, l_arr_months[7].months_ago  USING "-----&.&&", 
		COLUMN 46, l_arr_months[6].months_ago  USING "-----&.&&", 
		COLUMN 55, l_arr_months[5].months_ago  USING "-----&.&&", 
		COLUMN 64, l_arr_months[4].months_ago  USING "-----&.&&", 
		COLUMN 74, l_arr_months[3].months_ago  USING "-----&.&&", 
		COLUMN 84, l_arr_months[2].months_ago  USING "-----&.&&", 
		COLUMN 94, l_arr_months[1].months_ago  USING "-----&.&&", 
		COLUMN 104,l_current                   USING "-----&.&&", 
		COLUMN 114,l_ytd                       USING "-----&.&&", 
		COLUMN 124,l_end_qty                   USING "-----&.&&" 

	ON LAST ROW 
		NEED 12 LINES 
		SKIP 2 LINES 
		#End Of Report
		IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
			PRINT COLUMN 01,"Selection Criteria:" 
			PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text CLIPPED WORDWRAP RIGHT MARGIN 100 
		END IF 
		PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report 			
		LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = PAGENO

END REPORT 
