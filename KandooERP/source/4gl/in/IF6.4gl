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
DEFINE modu_detail_flag CHAR(1)
DEFINE modu_book_tax CHAR(1) 
DEFINE modu_start_date DATE 
DEFINE modu_end_date DATE 
DEFINE modu_val_date DATE 
DEFINE modu_arr_date ARRAY[6] OF DATE 
 
############################################################
# FUNCTION IF6_main()
#
# Purpose - Aged Stock Valuation Summary by Product Group Report
############################################################
FUNCTION IF6_main()

	CALL setModuleId("IF6") 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN "1" #UI/MENU Mode
			OPEN WINDOW I707 WITH FORM "I707" 
			 CALL windecoration_i("I707")
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title
			
			MENU "Aged Stock Valuation Summary" 

				BEFORE MENU 
					CALL publish_toolbar("kandoo","IF6","menu-Aged Stock-1") -- albo kd-505
					CALL rpt_rmsreps_reset(NULL)
					CALL IF6_rpt_process(IF6_rpt_query())

				ON ACTION "WEB-HELP" -- albo kd-372 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar()

				ON ACTION "Report" #COMMAND "Run Report" " SELECT Criteria AND Print Report"
					CALL rpt_rmsreps_reset(NULL)
					CALL IF6_rpt_process(IF6_rpt_query())

				ON ACTION "PRINT MANAGER" --COMMAND "Print" "Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "CANCEL" --COMMAND KEY (interrupt, "E") "Exit" " Exit TO menus" 
					EXIT MENU

			END MENU
			CLOSE WINDOW I707

		WHEN "2" #Background Process with rmsreps.report_code
			CALL IF6_rpt_process(NULL)  

		WHEN "3" #Only create query-where-part
			OPEN WINDOW I707 with FORM "I707" 
			 CALL windecoration_i("I707") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(IF6_rpt_query()) #save where clause in env 
			CLOSE WINDOW I707 
			
		WHEN "4" #Background Process with SQL WHERE ARGUMENT
			CALL IF6_rpt_process(get_url_sel_text())
	END CASE

END FUNCTION 
############################################################
# END FUNCTION IF6_main()
############################################################ 

############################################################
# FUNCTION IF6_rpt_query() 
# RETURN r_where_text (Query By Example)
# DataSource for the report driver with CONSTRUCT
############################################################
FUNCTION IF6_rpt_query() 
	DEFINE r_where_text LIKE rmsreps.sel_text
	DEFINE l_day SMALLINT 
	DEFINE l_month SMALLINT
	DEFINE l_year SMALLINT
	DEFINE i SMALLINT

	LET modu_detail_flag = "N"
	LET modu_book_tax = "B"
	LET modu_start_date = NULL
	LET modu_end_date = NULL
	LET modu_val_date = NULL								

	CLEAR FORM	
	DIALOG ATTRIBUTES(UNBUFFERED)
		INPUT modu_detail_flag,modu_book_tax,modu_start_date,modu_end_date,modu_val_date WITHOUT DEFAULTS
		FROM  detail_flag,book_tax,start_date,end_date,val_date  
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","IF6","input-pr_detail_flag-1") -- albo kd-505 
				MESSAGE " Enter criteria FOR selection - ESC TO begin search"
			AFTER FIELD detail_flag 
				IF modu_detail_flag IS NULL THEN 
					LET modu_detail_flag = "N" 
				END IF 
			AFTER FIELD book_tax
				IF modu_book_tax IS NULL THEN 
					LET modu_book_tax = "B" 
				END IF 
			AFTER FIELD start_date
				IF modu_start_date IS NULL THEN 
					LET modu_start_date = "01/01/0001" 
				END IF 
			AFTER FIELD end_date
				IF modu_end_date IS NULL THEN 
					LET modu_end_date = "31/12/9999" 
				END IF
			AFTER FIELD val_date			 
				IF modu_val_date IS NULL THEN 
					LET modu_val_date = TODAY 
				END IF	 
			AFTER INPUT
				IF modu_detail_flag IS NULL THEN 
					LET modu_detail_flag = "N" 
				END IF 
				IF modu_book_tax IS NULL THEN 
					LET modu_book_tax = "B" 
				END IF 
				IF modu_start_date IS NULL THEN 
					LET modu_start_date = "01/01/0001" 
				END IF 
				IF modu_end_date IS NULL THEN 
					LET modu_end_date = "31/12/9999" 
				END IF
				IF modu_val_date IS NULL THEN 
					LET modu_val_date = TODAY 
				END IF	 
				IF modu_start_date > modu_end_date THEN
					ERROR "The Transaction start date is greater than the Transaction end date."
					NEXT FIELD start_date
				END IF
				# FORMAT dates FOR CASE statement
				LET l_day = DAY(modu_val_date) 
				LET l_month = MONTH(modu_val_date) 
				LET l_year = YEAR(modu_val_date) 
				FOR i = 1 TO 6 
					LET modu_arr_date[i] = MDY(l_month,l_day,l_year - i) 
				END FOR 
		END INPUT 

		CONSTRUCT r_where_text ON 
		product.cat_code, 
		product.class_code, 
		costledg.part_code, 
		costledg.ware_code 
		FROM 
		cat_code, 
		class_code, 
		part_code, 
		ware_code 
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","IF6","construct-product-1") -- albo kd-505 
				MESSAGE " Enter criteria FOR selection - ESC TO begin search"
		END CONSTRUCT 
	
		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),NULL) 

		ON ACTION "ACCEPT" 
			ACCEPT DIALOG
			
		ON ACTION "CANCEL" 
			EXIT DIALOG

	END DIALOG

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN NULL 
	ELSE 
		RETURN r_where_text
	END IF

END FUNCTION
############################################################
# END FUNCTION IF6_rpt_query() 
############################################################

############################################################
# FUNCTION IF6_rpt_process(p_where_text) 
# 
# The report driver
############################################################
FUNCTION IF6_rpt_process(p_where_text)
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT
	DEFINE l_maingrp_code LIKE product.maingrp_code
	DEFINE l_rec_costledg RECORD LIKE costledg.*
	DEFINE l_cat_code LIKE category.cat_code

	IF modu_detail_flag = "Y" THEN 
		LET l_query_text = "SELECT 1, product.maingrp_code, costledg.* " 
	ELSE 
		LET l_query_text = "SELECT product.cat_code, 1, costledg.* " 
	END IF 

	#------------------------------------------------------------
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE
		RETURN FALSE
	END IF

	IF modu_book_tax = "B" THEN 
		LET l_rpt_idx = rpt_start(getmoduleid(),"IF6_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	ELSE 
		LET l_rpt_idx = rpt_start(trim(getmoduleid())||".","IF6_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	END IF

	START REPORT IF6_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	LET l_query_text = l_query_text CLIPPED," ", 
	"FROM product,costledg,prodstatus ", 
	"WHERE product.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND costledg.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND prodstatus.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND product.part_code = costledg.part_code ", 
	"AND prodstatus.part_code = costledg.part_code ", 
	"AND prodstatus.ware_code = costledg.ware_code ", 
	"AND costledg.tran_date > '",modu_start_date,"' ", 
	"AND costledg.tran_date < '",modu_end_date,"' ", 
	"AND costledg.onhand_qty != 0 ", 
	"AND ",p_where_text CLIPPED 

	IF modu_detail_flag = "Y" THEN 
		LET l_query_text = l_query_text CLIPPED," ", 
		"ORDER BY product.maingrp_code,costledg.part_code,costledg.ware_code" 
	ELSE 
		LET l_query_text = l_query_text CLIPPED," ", 
		"ORDER BY product.cat_code,costledg.part_code,costledg.ware_code" 
	END IF 

	PREPARE s_costledg FROM l_query_text 
	DECLARE c_costledg CURSOR FOR s_costledg 

	FOREACH c_costledg INTO l_cat_code, l_maingrp_code, l_rec_costledg.* 
		#---------------------------------------------------------
		OUTPUT TO REPORT IF6_rpt_list(l_rpt_idx,l_cat_code,l_maingrp_code,l_rec_costledg.*,modu_book_tax) 
		IF NOT rpt_int_flag_handler2("Product: ",l_rec_costledg.part_code,"",l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT IF6_rpt_list
	RETURN rpt_finish("IF6_rpt_list")
	#------------------------------------------------------------

END FUNCTION
############################################################
# END FUNCTION IF6_rpt_process() 
############################################################

############################################################
# REPORT IF6_rpt_list(p_rpt_idx,p_cat_code,p_maingrp_code,p_rec_costledg,p_book_tax)
#
# Report Definition/Layout
############################################################
REPORT IF6_rpt_list(p_rpt_idx,p_cat_code,p_maingrp_code,p_rec_costledg,p_book_tax) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_cat_code LIKE category.cat_code
	DEFINE p_maingrp_code LIKE product.maingrp_code
	DEFINE p_rec_costledg RECORD LIKE costledg.*
	DEFINE p_book_tax CHAR(1) 
	DEFINE l_rec_category RECORD LIKE category.*
 	DEFINE l_rec_maingrp RECORD LIKE maingrp.*
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_prod_oh_qty  FLOAT 
	DEFINE l_prod_wd_qty  FLOAT
	DEFINE l_main_oh_qty  FLOAT 
	DEFINE l_main_wd_qty  FLOAT
	DEFINE l_oh_qty       FLOAT 
	DEFINE l_wd_qty       FLOAT 
	DEFINE l_oh_tot_qty   FLOAT 
	DEFINE l_wd_tot_qty   FLOAT
	DEFINE l_prod_y1_amt  DECIMAL(16,4)
	DEFINE l_prod_y2_amt  DECIMAL(16,4)
	DEFINE l_prod_y3_amt  DECIMAL(16,4)
	DEFINE l_prod_y4_amt  DECIMAL(16,4)
	DEFINE l_prod_y5_amt  DECIMAL(16,4)
	DEFINE l_prod_y6_amt  DECIMAL(16,4)
	DEFINE l_prod_y7_amt  DECIMAL(16,4)
	DEFINE l_prod_sum_amt DECIMAL(16,4)
	DEFINE l_prod_wd_amt  DECIMAL(16,4)
	DEFINE l_main_y1_amt  DECIMAL(16,4)
	DEFINE l_main_y2_amt  DECIMAL(16,4)
	DEFINE l_main_y3_amt  DECIMAL(16,4)
	DEFINE l_main_y4_amt  DECIMAL(16,4)
	DEFINE l_main_y5_amt  DECIMAL(16,4)
	DEFINE l_main_y6_amt  DECIMAL(16,4)
	DEFINE l_main_y7_amt  DECIMAL(16,4)
	DEFINE l_main_sum_amt DECIMAL(16,4)
	DEFINE l_main_wd_amt  DECIMAL(16,4)
	DEFINE l_y1_amt       DECIMAL(16,4) 
	DEFINE l_y2_amt       DECIMAL(16,4) 
	DEFINE l_y3_amt       DECIMAL(16,4) 
	DEFINE l_y4_amt       DECIMAL(16,4) 
	DEFINE l_y5_amt       DECIMAL(16,4) 
	DEFINE l_y6_amt       DECIMAL(16,4) 
	DEFINE l_y7_amt       DECIMAL(16,4) 
	DEFINE l_y_sum_amt    DECIMAL(16,4) 
	DEFINE l_y1_tot_amt   DECIMAL(16,4) 
	DEFINE l_y2_tot_amt   DECIMAL(16,4) 
	DEFINE l_y3_tot_amt   DECIMAL(16,4) 
	DEFINE l_y4_tot_amt   DECIMAL(16,4) 
	DEFINE l_y5_tot_amt   DECIMAL(16,4) 
	DEFINE l_y6_tot_amt   DECIMAL(16,4) 
	DEFINE l_y7_tot_amt   DECIMAL(16,4) 
	DEFINE l_wd_amt       DECIMAL(16,4) 
	DEFINE l_y_tot_amt    DECIMAL(16,4) 
	DEFINE l_wd_tot_amt   DECIMAL(16,4) 

	ORDER EXTERNAL BY p_cat_code,p_maingrp_code,p_rec_costledg.part_code,p_rec_costledg.ware_code 

	FORMAT 
		FIRST PAGE HEADER 
			# initialise variables FOR accumulation
			LET l_y1_amt = 0 
			LET l_y2_amt = 0 
			LET l_y3_amt = 0 
			LET l_y4_amt = 0 
			LET l_y5_amt = 0 
			LET l_y6_amt = 0 
			LET l_y7_amt = 0 
			LET l_y_sum_amt = 0 
			LET l_y1_tot_amt = 0 
			LET l_y2_tot_amt = 0 
			LET l_y3_tot_amt = 0 
			LET l_y4_tot_amt = 0 
			LET l_y5_tot_amt = 0 
			LET l_y6_tot_amt = 0 
			LET l_y7_tot_amt = 0 
			LET l_y_tot_amt = 0 
			LET l_oh_qty = 0 
			LET l_oh_tot_qty = 0 
			LET l_wd_amt = 0 
			LET l_wd_tot_amt = 0 
			LET l_wd_qty = 0 
			LET l_wd_tot_qty = 0 
			CALL rpt_set_page_num(p_rpt_idx,PAGENO) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 CLIPPED #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 CLIPPED #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text CLIPPED 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text CLIPPED
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,PAGENO) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 CLIPPED #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 CLIPPED #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text CLIPPED 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text CLIPPED
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]

		BEFORE GROUP OF p_rec_costledg.part_code 
			IF modu_detail_flag = "Y" THEN 
				SELECT * INTO l_rec_product.* FROM product 
				WHERE product.cmpy_code = glob_rec_kandoouser.cmpy_code AND 
						product.part_code = p_rec_costledg.part_code 
				LET l_prod_y1_amt = 0 
				LET l_prod_y2_amt = 0 
				LET l_prod_y3_amt = 0 
				LET l_prod_y4_amt = 0 
				LET l_prod_y5_amt = 0 
				LET l_prod_y6_amt = 0 
				LET l_prod_y7_amt = 0 
				LET l_prod_sum_amt = 0 
				LET l_prod_oh_qty = 0 
				LET l_prod_wd_amt = 0 
				LET l_prod_wd_qty = 0 
			END IF 

	BEFORE GROUP OF p_maingrp_code 
		IF modu_detail_flag = "Y" THEN 
			SELECT * INTO l_rec_maingrp.* FROM maingrp 
			WHERE maingrp.cmpy_code = glob_rec_kandoouser.cmpy_code AND 
					maingrp.maingrp_code = p_maingrp_code 
			PRINT COLUMN 01, "Main Group: ",l_rec_maingrp.maingrp_code CLIPPED," ",l_rec_maingrp.desc_text CLIPPED 
			LET l_main_y1_amt = 0 
			LET l_main_y2_amt = 0 
			LET l_main_y3_amt = 0 
			LET l_main_y4_amt = 0 
			LET l_main_y5_amt = 0 
			LET l_main_y6_amt = 0 
			LET l_main_y7_amt = 0 
			LET l_main_sum_amt = 0 
			LET l_main_oh_qty = 0 
			LET l_main_wd_amt = 0 
			LET l_main_wd_qty = 0 
		END IF 

	BEFORE GROUP OF p_cat_code 
		IF modu_detail_flag = "N" THEN 
			SELECT * INTO l_rec_category.* FROM category 
			WHERE category.cmpy_code = glob_rec_kandoouser.cmpy_code	AND 
					category.cat_code = p_cat_code 
		END IF 

	ON EVERY ROW 
		IF p_book_tax = "T" THEN 
			LET p_rec_costledg.curr_cost_amt = p_rec_costledg.tax_cost_amt 
			LET p_rec_costledg.curr_wo_amt = p_rec_costledg.tax_wo_amt 
			LET p_rec_costledg.prev_wo_amt = p_rec_costledg.prev_tax_wo_amt 
		END IF 
		CASE 
			WHEN p_rec_costledg.tran_date < modu_arr_date[6] 
				LET l_y7_tot_amt = l_y7_tot_amt + (p_rec_costledg.onhand_qty * p_rec_costledg.curr_cost_amt) 
				LET l_prod_y7_amt = l_prod_y7_amt + (p_rec_costledg.onhand_qty *p_rec_costledg.curr_cost_amt) 
				LET l_main_y7_amt = l_main_y7_amt + (p_rec_costledg.onhand_qty * p_rec_costledg.curr_cost_amt) 
				LET l_y7_amt = l_y7_amt + (p_rec_costledg.onhand_qty * p_rec_costledg.curr_cost_amt) 
			WHEN p_rec_costledg.tran_date < modu_arr_date[5] 
				LET l_y6_tot_amt = l_y6_tot_amt + (p_rec_costledg.onhand_qty * p_rec_costledg.curr_cost_amt) 
				LET l_y6_amt = l_y6_amt + (p_rec_costledg.onhand_qty * p_rec_costledg.curr_cost_amt) 
				LET l_prod_y6_amt = l_prod_y6_amt + (p_rec_costledg.onhand_qty * p_rec_costledg.curr_cost_amt) 
				LET l_main_y6_amt = l_main_y6_amt + (p_rec_costledg.onhand_qty * p_rec_costledg.curr_cost_amt) 
			WHEN p_rec_costledg.tran_date < modu_arr_date[4] 
				LET l_y5_tot_amt = l_y5_tot_amt + (p_rec_costledg.onhand_qty * p_rec_costledg.curr_cost_amt) 
				LET l_y5_amt = l_y5_amt + (p_rec_costledg.onhand_qty * p_rec_costledg.curr_cost_amt) 
				LET l_prod_y5_amt = l_prod_y5_amt + (p_rec_costledg.onhand_qty * p_rec_costledg.curr_cost_amt) 
				LET l_main_y5_amt = l_main_y5_amt + (p_rec_costledg.onhand_qty * p_rec_costledg.curr_cost_amt) 
			WHEN p_rec_costledg.tran_date < modu_arr_date[3] 
				LET l_y4_tot_amt = l_y4_tot_amt + (p_rec_costledg.onhand_qty * p_rec_costledg.curr_cost_amt) 
				LET l_y4_amt = l_y4_amt + (p_rec_costledg.onhand_qty * p_rec_costledg.curr_cost_amt) 
				LET l_prod_y4_amt = l_prod_y4_amt + (p_rec_costledg.onhand_qty * p_rec_costledg.curr_cost_amt) 
				LET l_main_y4_amt = l_main_y4_amt + (p_rec_costledg.onhand_qty * p_rec_costledg.curr_cost_amt) 
			WHEN p_rec_costledg.tran_date < modu_arr_date[2] 
				LET l_y3_tot_amt = l_y3_tot_amt + (p_rec_costledg.onhand_qty * p_rec_costledg.curr_cost_amt) 
				LET l_y3_amt = l_y3_amt + (p_rec_costledg.onhand_qty * p_rec_costledg.curr_cost_amt) 
				LET l_prod_y3_amt = l_prod_y3_amt + (p_rec_costledg.onhand_qty * p_rec_costledg.curr_cost_amt) 
				LET l_main_y3_amt = l_main_y3_amt + (p_rec_costledg.onhand_qty * p_rec_costledg.curr_cost_amt) 
			WHEN p_rec_costledg.tran_date < modu_arr_date[1] 
				LET l_y2_tot_amt = l_y2_tot_amt + (p_rec_costledg.onhand_qty * p_rec_costledg.curr_cost_amt) 
				LET l_y2_amt = l_y2_amt + (p_rec_costledg.onhand_qty * p_rec_costledg.curr_cost_amt) 
				LET l_prod_y2_amt = l_prod_y2_amt + (p_rec_costledg.onhand_qty * p_rec_costledg.curr_cost_amt) 
				LET l_main_y2_amt = l_main_y2_amt + (p_rec_costledg.onhand_qty * p_rec_costledg.curr_cost_amt) 
			OTHERWISE 
				LET l_y1_tot_amt = l_y1_tot_amt + (p_rec_costledg.onhand_qty * p_rec_costledg.curr_cost_amt) 
				LET l_y1_amt = l_y1_amt + (p_rec_costledg.onhand_qty * p_rec_costledg.curr_cost_amt) 
				LET l_prod_y1_amt = l_prod_y1_amt + (p_rec_costledg.onhand_qty * p_rec_costledg.curr_cost_amt) 
				LET l_main_y1_amt = l_main_y1_amt + (p_rec_costledg.onhand_qty * p_rec_costledg.curr_cost_amt) 
		END CASE 
		LET l_y_sum_amt = l_y_sum_amt + (p_rec_costledg.onhand_qty * p_rec_costledg.curr_cost_amt) 
		LET l_prod_sum_amt = l_prod_sum_amt + (p_rec_costledg.onhand_qty * p_rec_costledg.curr_cost_amt) 
		LET l_main_sum_amt = l_main_sum_amt + (p_rec_costledg.onhand_qty * p_rec_costledg.curr_cost_amt) 
		LET l_y_tot_amt = l_y_tot_amt + (p_rec_costledg.onhand_qty * p_rec_costledg.curr_cost_amt) 
		LET l_oh_qty = l_oh_qty + p_rec_costledg.onhand_qty 
		LET l_prod_oh_qty = l_prod_oh_qty + p_rec_costledg.onhand_qty 
		LET l_main_oh_qty = l_main_oh_qty + p_rec_costledg.onhand_qty 
		LET l_oh_tot_qty = l_oh_tot_qty + p_rec_costledg.onhand_qty 
		IF p_rec_costledg.curr_wo_amt != 0 OR p_rec_costledg.prev_wo_amt != 0 THEN 
			LET l_wd_tot_amt = l_wd_tot_amt + (p_rec_costledg.onhand_qty * (p_rec_costledg.curr_wo_amt + p_rec_costledg.prev_wo_amt)) 
			LET l_wd_amt = l_wd_amt + (p_rec_costledg.onhand_qty * (p_rec_costledg.curr_wo_amt + p_rec_costledg.prev_wo_amt)) 
			LET l_prod_wd_amt = l_prod_wd_amt + (p_rec_costledg.onhand_qty * (p_rec_costledg.curr_wo_amt + p_rec_costledg.prev_wo_amt)) 
			LET l_main_wd_amt = l_main_wd_amt + (p_rec_costledg.onhand_qty * (p_rec_costledg.curr_wo_amt + p_rec_costledg.prev_wo_amt)) 
			LET l_wd_qty = l_wd_qty + p_rec_costledg.onhand_qty 
			LET l_prod_wd_qty = l_prod_wd_qty + p_rec_costledg.onhand_qty 
			LET l_main_wd_qty = l_main_wd_qty + p_rec_costledg.onhand_qty 
			LET l_wd_tot_qty = l_wd_tot_qty + p_rec_costledg.onhand_qty 
		END IF 

	AFTER GROUP OF p_rec_costledg.part_code 
		IF modu_detail_flag = "Y" THEN 
			PRINT 
			COLUMN 001, p_rec_costledg.part_code CLIPPED, 
			COLUMN 017, l_prod_oh_qty  USING "######&", 
			COLUMN 025, l_prod_y1_amt  USING "###,###,##&.&&", 
			COLUMN 039, l_prod_y2_amt  USING "###,###,##&.&&", 
			COLUMN 053, l_prod_y3_amt  USING "###,###,##&.&&", 
			COLUMN 067, l_prod_y4_amt  USING "###,###,##&.&&", 
			COLUMN 081, l_prod_y5_amt  USING "###,###,##&.&&", 
			COLUMN 095, l_prod_y6_amt  USING "###,###,##&.&&", 
			COLUMN 109, l_prod_y7_amt  USING "###,###,##&.&&", 
			COLUMN 124, l_prod_sum_amt USING "###,###,##&.&&", 
			COLUMN 139, l_prod_wd_qty  USING "######&", 
			COLUMN 147, l_prod_wd_amt  USING "###,###,##&.&&" 
		END IF 

	AFTER GROUP OF p_maingrp_code 
		IF modu_detail_flag = "Y" THEN 
--			PRINT COLUMN 001, "Main Group ",l_rec_maingrp.maingrp_code CLIPPED," Total", 
			PRINT 
			COLUMN 001, "Main Group Total",
			COLUMN 017, l_main_oh_qty  USING "######&", 
			COLUMN 025, l_main_y1_amt  USING "###,###,##&.&&", 
			COLUMN 039, l_main_y2_amt  USING "###,###,##&.&&", 
			COLUMN 053, l_main_y3_amt  USING "###,###,##&.&&", 
			COLUMN 067, l_main_y4_amt  USING "###,###,##&.&&", 
			COLUMN 081, l_main_y5_amt  USING "###,###,##&.&&", 
			COLUMN 095, l_main_y6_amt  USING "###,###,##&.&&", 
			COLUMN 109, l_main_y7_amt  USING "###,###,##&.&&", 
			COLUMN 124, l_main_sum_amt USING "###,###,##&.&&", 
			COLUMN 139, l_main_wd_qty  USING "######&", 
			COLUMN 147, l_main_wd_amt  USING "###,###,##&.&&" 
			SKIP 1 LINE 
		END IF 

	AFTER GROUP OF p_cat_code 
		IF modu_detail_flag = "N" THEN 
			PRINT 
			COLUMN 001, l_rec_category.cat_code CLIPPED, 
			COLUMN 005, l_rec_category.desc_text[1,12] CLIPPED,
			COLUMN 017, l_oh_qty       USING "######&", 
			COLUMN 025, l_y1_amt       USING "###,###,##&.&&", 
			COLUMN 039, l_y2_amt       USING "###,###,##&.&&", 
			COLUMN 053, l_y3_amt       USING "###,###,##&.&&", 
			COLUMN 067, l_y4_amt       USING "###,###,##&.&&", 
			COLUMN 081, l_y5_amt       USING "###,###,##&.&&", 
			COLUMN 095, l_y6_amt       USING "###,###,##&.&&", 
			COLUMN 109, l_y7_amt       USING "###,###,##&.&&", 
			COLUMN 124, l_y_sum_amt    USING "###,###,##&.&&", 
			COLUMN 139, l_wd_qty       USING "######&", 
			COLUMN 147, l_wd_amt       USING "###,###,##&.&&" 
			LET l_y1_amt = 0 
			LET l_y2_amt = 0 
			LET l_y3_amt = 0 
			LET l_y4_amt = 0 
			LET l_y5_amt = 0 
			LET l_y6_amt = 0 
			LET l_y7_amt = 0 
			LET l_y_sum_amt = 0 
			LET l_oh_qty = 0 
			LET l_wd_amt = 0 
			LET l_wd_qty = 0 
		END IF 

	ON LAST ROW 
		SKIP 1 LINE 
		PRINT 
		COLUMN 004, "Report Total:", 
		COLUMN 017, l_oh_tot_qty      USING "######&", 
		COLUMN 025, l_y1_tot_amt      USING "###,###,##&.&&", 
		COLUMN 039, l_y2_tot_amt      USING "###,###,##&.&&", 
		COLUMN 053, l_y3_tot_amt      USING "###,###,##&.&&", 
		COLUMN 067, l_y4_tot_amt      USING "###,###,##&.&&", 
		COLUMN 081, l_y5_tot_amt      USING "###,###,##&.&&", 
		COLUMN 095, l_y6_tot_amt      USING "###,###,##&.&&", 
		COLUMN 109, l_y7_tot_amt      USING "###,###,##&.&&", 
		COLUMN 124, l_y_tot_amt       USING "###,###,##&.&&", 
		COLUMN 139, l_wd_tot_qty      USING "######&", 
		COLUMN 147, l_wd_tot_amt      USING "###,###,##&.&&" 
		SKIP 2 LINES 
		#End Of Report
		IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
			PRINT COLUMN 01,"Selection Criteria:" 
			PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text CLIPPED WORDWRAP RIGHT MARGIN 100 
		END IF 
		PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report 			
		LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = PAGENO

END REPORT 
