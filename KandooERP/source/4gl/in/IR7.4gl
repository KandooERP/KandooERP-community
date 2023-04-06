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
DEFINE modu_tran_type_text CHAR(120) 
DEFINE modu_rec_jmparms RECORD LIKE jmparms.* 
DEFINE modu_start_date DATE
DEFINE modu_end_date DATE 
DEFINE modu_hold_cost_per DECIMAL(7,2) 

############################################################
# FUNCTION IR7_main()
#
# Purpose - Return on Investment Report
############################################################
FUNCTION IR7_main()

	CALL setModuleId("IR7") 
#TODO replace with global_rec_jmparms when FUNCTION init_i_in will be finished
	SELECT * INTO modu_rec_jmparms.* FROM jmparms 
	WHERE jmparms.cmpy_code = glob_rec_kandoouser.cmpy_code AND 
			jmparms.key_code = "1" 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN "1" #UI/MENU Mode
			OPEN WINDOW I646 WITH FORM "I646" 
			 CALL windecoration_i("I646")
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title
			
			MENU "Return on Investment" 

				BEFORE MENU 
					CALL publish_toolbar("kandoo","IR7","menu-Investment_Report-1") -- albo kd-505
					CALL rpt_rmsreps_reset(NULL)
					CALL IR7_rpt_process(IR7_rpt_query())

				ON ACTION "WEB-HELP" -- albo kd-372 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar()

				ON ACTION "Report" #COMMAND "Run Report" " SELECT Criteria AND Print Report"
					CALL rpt_rmsreps_reset(NULL)
					CALL IR7_rpt_process(IR7_rpt_query())

				ON ACTION "PRINT MANAGER" --COMMAND "Print" "Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "CANCEL" --COMMAND KEY (interrupt, "E") "Exit" " Exit TO menus" 
					EXIT MENU

			END MENU
			CLOSE WINDOW I646

		WHEN "2" #Background Process with rmsreps.report_code
			CALL IR7_rpt_process(NULL)  

		WHEN "3" #Only create query-where-part
			OPEN WINDOW I646 with FORM "I646" 
			 CALL windecoration_i("I646") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(IR7_rpt_query()) #save where clause in env 
			CLOSE WINDOW I646 
			
		WHEN "4" #Background Process with SQL WHERE ARGUMENT
			CALL IR7_rpt_process(get_url_sel_text())
	END CASE

END FUNCTION 
############################################################
# END FUNCTION IR7_main()
############################################################

############################################################
# FUNCTION IR7_rpt_query() 
# RETURN r_where_text (Query By Example)
# DataSource for the report driver with CONSTRUCT
############################################################
FUNCTION IR7_rpt_query() 
	DEFINE r_where_text LIKE rmsreps.sel_text
	DEFINE l_rec_tran_type RECORD 
		inv_flag CHAR(1), 
		cred_flag CHAR(1), 
		inv_iss_flag CHAR(1), 
		jm_iss_flag CHAR(1) 
	END RECORD 

	OPEN WINDOW i209 with FORM "I209" 
	 CALL windecoration_i("I209") -- albo kd-758 
	LET modu_start_date = TODAY - 183 
	LET modu_end_date = TODAY 
	LET modu_hold_cost_per = 0 
	LET l_rec_tran_type.inv_flag = "Y" 
	LET l_rec_tran_type.cred_flag = "Y" 
	LET l_rec_tran_type.inv_iss_flag = "Y" 
	IF modu_rec_jmparms.jm_flag = "Y" THEN 
		DISPLAY "Job Management Issues...." TO jm_prompt_text 
		LET l_rec_tran_type.jm_iss_flag = "Y" 
	ELSE 
		CLEAR jm_prompt_text 
		LET l_rec_tran_type.jm_iss_flag = NULL 
	END IF 

	INPUT  
	modu_start_date, 
	modu_end_date, 
	modu_hold_cost_per, 
	l_rec_tran_type.inv_flag, 
	l_rec_tran_type.cred_flag, 
	l_rec_tran_type.inv_iss_flag, 
	l_rec_tran_type.jm_iss_flag 
	WITHOUT DEFAULTS
	FROM
	start_date, 
	end_date, 
	hold_cost_per, 
	inv_flag, 
	cred_flag, 
	inv_iss_flag, 
	jm_iss_flag 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","IR7","input-start_date-1") -- albo kd-505 
			MESSAGE " Enter criteria FOR selection - ESC TO begin search"

		BEFORE FIELD jm_iss_flag 
			IF modu_rec_jmparms.jm_flag != "Y" THEN 
				EXIT INPUT 
			END IF 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		AFTER FIELD start_date 
			IF modu_start_date IS NULL THEN 
				LET modu_start_date = TODAY - 183 
			END IF 

		AFTER FIELD end_date 
			IF modu_end_date IS NULL THEN 
				LET modu_end_date = TODAY 
			END IF 
			IF modu_end_date < modu_start_date THEN 
				ERROR " End Date IS less than Starting Date" 
				NEXT FIELD start_date 
			END IF 

		AFTER FIELD hold_cost_per 
			IF modu_hold_cost_per IS NULL THEN 
				LET modu_hold_cost_per = 0 
			END IF 

	END INPUT 
	CLOSE WINDOW i209 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN NULL 
	END IF

	CURRENT WINDOW IS I646
	CONSTRUCT BY NAME r_where_text ON 
	product.part_code, 
	product.desc_text, 
	product.desc2_text, 
	product.cat_code, 
	product.prodgrp_code,
	product.class_code, 
 	product.maingrp_code, 
	product.alter_part_code, 
	product.super_part_code, 
	product.compn_part_code, 
	product.pur_uom_code, 
	product.stock_uom_code, 
	product.sell_uom_code, 
	product.target_turn_qty, 
	product.stock_turn_qty, 
	product.last_calc_date, 
	product.stock_days_num, 
	product.vend_code, 
	product.oem_text 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","IR7","construct-product-1") -- albo kd-505 
			MESSAGE " Enter criteria FOR selection - ESC TO begin search"

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN NULL 
	ELSE 
		LET modu_tran_type_text = "1!=1" 
		IF l_rec_tran_type.inv_flag = "Y" THEN 
			LET modu_tran_type_text = modu_tran_type_text CLIPPED," OR trantype_ind = \"S\"" 
		END IF 
		IF l_rec_tran_type.cred_flag = "Y" THEN 
			LET modu_tran_type_text = modu_tran_type_text CLIPPED," OR trantype_ind = \"C\"" 
		END IF 
		IF l_rec_tran_type.inv_iss_flag = "Y" THEN 
			LET modu_tran_type_text = modu_tran_type_text CLIPPED," OR trantype_ind = \"I\"" 
		END IF 
		IF l_rec_tran_type.jm_iss_flag = "Y" THEN 
			LET modu_tran_type_text = modu_tran_type_text CLIPPED," OR trantype_ind = \"J\"" 
		END IF 
		LET modu_tran_type_text = "(",modu_tran_type_text CLIPPED,")" 
		RETURN r_where_text
	END IF

END FUNCTION 
############################################################
# END FUNCTION IR7_rpt_query() 
############################################################

############################################################
# FUNCTION IR7_rpt_process(p_where_text) 
# 
# The report driver
############################################################
FUNCTION IR7_rpt_process(p_where_text)
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT
	DEFINE l_rec_product RECORD LIKE product.*

	#------------------------------------------------------------
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE
		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"IR7_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	

	START REPORT IR7_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	LET l_query_text = 
	"SELECT * ", 
	"FROM product ", 
	"WHERE product.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND ", p_where_text CLIPPED," ", 
	"ORDER BY product.part_code" 

	PREPARE s_product FROM l_query_text 
	DECLARE c_product CURSOR FOR s_product 

	FOREACH c_product INTO l_rec_product.* 
		#---------------------------------------------------------
		OUTPUT TO REPORT IR7_rpt_list(l_rpt_idx,l_rec_product.*) 
		IF NOT rpt_int_flag_handler2("Product: ",l_rec_product.part_code,"",l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT IR7_rpt_list
	RETURN rpt_finish("IR7_rpt_list")
	#------------------------------------------------------------

END FUNCTION 
############################################################
# END FUNCTION IR7_rpt_process() 
############################################################

############################################################
# REPORT IR7_rpt_list(p_rpt_idx,p_rec_product)
#
# Report Definition/Layout
############################################################
REPORT IR7_rpt_list(p_rpt_idx,p_rec_product) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_product RECORD LIKE product.* 
	DEFINE l_tot_sales MONEY(14,2)
	DEFINE l_tot_avg_stock MONEY(14,2)
	DEFINE l_tot_costs MONEY(14,2)
	DEFINE l_profit DECIMAL(7,2)
	DEFINE l_roi FLOAT
	DEFINE l_rec_calc_turn RECORD 
		stk_turn_qty DECIMAL(10,4), 
		stk_cost_amt DECIMAL(16,4), 
		stk_sales_amt DECIMAL(16,4), 
		avg_stk_amt DECIMAL(16,4), 
		reorder_point_qty LIKE prodstatus.reorder_point_qty, 
		reorder_qty LIKE prodstatus.reorder_qty 
	END RECORD
	DEFINE l_grs_prft_amt DECIMAL(16,4) 
	DEFINE l_hold_cost_amt DECIMAL(16,4) 

	ORDER EXTERNAL BY p_rec_product.part_code 

	FORMAT 
		FIRST PAGE HEADER 
			LET l_tot_sales = 0 
			LET l_tot_costs = 0 
			LET l_tot_avg_stock = 0 
			CALL rpt_set_page_num(p_rpt_idx,PAGENO) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 CLIPPED #was l_arr_line[1]
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 CLIPPED #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]
			PRINT COLUMN 01,"Holding Cost: ",modu_hold_cost_per,"%" 
			PRINT COLUMN 01,"Analysis From: ", modu_start_date, " ", "To: ", modu_end_date 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text CLIPPED 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text CLIPPED 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,PAGENO) #update page number and report header line 1
			SKIP 1 LINE
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 CLIPPED #was l_arr_line[1]
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 CLIPPED #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]
			PRINT COLUMN 01,"Holding Cost: ",modu_hold_cost_per,"%" 
			PRINT COLUMN 01,"Analysis FROM: ", modu_start_date, " ", "To: ", modu_end_date 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text CLIPPED 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text CLIPPED 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]

	ON EVERY ROW 
		CALL calc_turn( glob_rec_kandoouser.cmpy_code, 
		p_rec_product.part_code, 
		" ", # starting warehouse code 
		"zzz", # ending warehouse code 
		modu_start_date, 
		modu_end_date, 
		"N", # no, dont want reorder point info 
		0, # only want stock turn calculations 
		modu_tran_type_text) RETURNING l_rec_calc_turn.* 
		##
		## Calculating Gross Profit GP
		LET l_grs_prft_amt = l_rec_calc_turn.stk_sales_amt - l_rec_calc_turn.stk_cost_amt 
		##
		## Calculating Holding Cost
		LET l_hold_cost_amt = l_rec_calc_turn.avg_stk_amt * modu_hold_cost_per/100 * (modu_end_date - modu_start_date)/365 
		## Calculating ROI
		## ROI = (GP - Holding Costs)/ (Avg cost + Holding cost)
		IF l_rec_calc_turn.avg_stk_amt = 0 THEN 
			IF l_rec_calc_turn.stk_sales_amt > 0 THEN 
				LET l_roi = 100 
			ELSE 
				LET l_roi = 0 
			END IF 
		ELSE 
			LET l_roi = ((l_grs_prft_amt) - (l_hold_cost_amt))	/ (l_rec_calc_turn.avg_stk_amt + (l_hold_cost_amt)) * 100 
		END IF 
		IF l_rec_calc_turn.stk_sales_amt = 0 THEN 
			LET l_profit = 0 
		ELSE 
			LET l_profit = l_grs_prft_amt / l_rec_calc_turn.stk_sales_amt * 100 
		END IF 
		PRINT COLUMN 1, p_rec_product.part_code CLIPPED, 
		COLUMN 17, p_rec_product.desc_text[1,29] CLIPPED, 
		COLUMN 46, l_rec_calc_turn.avg_stk_amt   USING "------,--&.&&", 
		COLUMN 59, l_rec_calc_turn.stk_sales_amt USING "------,--&.&&", 
		COLUMN 72, l_rec_calc_turn.stk_cost_amt  USING "------,--&.&&", 
		COLUMN 85, l_grs_prft_amt                USING "------,--&.&&", 
		COLUMN 98, l_profit                      USING "-----&.&&", 
		COLUMN 107,p_rec_product.target_turn_qty USING "###&.&&", 
		COLUMN 114,l_rec_calc_turn.stk_turn_qty  USING "###&.&&", 
		COLUMN 122,l_roi                         USING "----&.&&%" 
		LET l_tot_sales = l_tot_sales + l_rec_calc_turn.stk_sales_amt 
		LET l_tot_costs = l_tot_costs + l_rec_calc_turn.stk_cost_amt 
		LET l_tot_avg_stock = l_tot_avg_stock + l_rec_calc_turn.avg_stk_amt 

	ON LAST ROW 
		NEED 8 LINES 
		SKIP 2 LINES 
		PRINT COLUMN 1, "Report Totals : ", 
		COLUMN 46, l_tot_avg_stock               USING "------,--&.&&", 
		COLUMN 59, l_tot_sales                   USING "------,--&.&&", 
		COLUMN 72, l_tot_costs                   USING "------,--&.&&", 
		COLUMN 85, (l_tot_sales - l_tot_costs)   USING "------,--&.&&" 
		SKIP 1 LINES 
		#End Of Report
		IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
			PRINT COLUMN 01,"Selection Criteria:" 
			PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text CLIPPED WORDWRAP RIGHT MARGIN 100 
		END IF 
		PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report 			
		LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = PAGENO

END REPORT 
