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
DEFINE modu_user_def_var INTEGER 
DEFINE modu_def_lead_time INTEGER 

############################################################
# FUNCTION ID7_main()
#
# Purpose - Weekly Recommended Reorder Report
############################################################
FUNCTION ID7_main()

	CALL setModuleId("ID7") 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN "1" #UI/MENU Mode
			OPEN WINDOW I181 WITH FORM "I181" 
			 CALL windecoration_i("I181")
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title
			
			MENU "Weekly Recommended Reorder Report" 

				BEFORE MENU 
					CALL publish_toolbar("kandoo","ID7","menu-Replenishment-1") -- albo kd-505
					CALL rpt_rmsreps_reset(NULL)
					CALL ID7_rpt_process(ID7_rpt_query())

				ON ACTION "WEB-HELP" -- albo kd-372 
					CALL onlinehelp(getmoduleid(),NULL) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar()

				ON ACTION "Report" #COMMAND "Run Report" " SELECT Criteria AND Print Report"
					CALL rpt_rmsreps_reset(NULL)
					CALL ID7_rpt_process(ID7_rpt_query())

				ON ACTION "PRINT MANAGER" --COMMAND "Print" "Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "CANCEL" --COMMAND KEY (interrupt, "E") "Exit" " Exit TO menus" 
					EXIT MENU

			END MENU
			CLOSE WINDOW I181

		WHEN "2" #Background Process with rmsreps.report_code
			CALL ID7_rpt_process(NULL)  

		WHEN "3" #Only create query-where-part
			OPEN WINDOW I181 with FORM "I181" 
			 CALL windecoration_i("I181") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(ID7_rpt_query()) #save where clause in env 
			CLOSE WINDOW I181 
			
		WHEN "4" #Background Process with SQL WHERE ARGUMENT
			CALL ID7_rpt_process(get_url_sel_text())
	END CASE	

END FUNCTION
############################################################
# END FUNCTION ID7_main()
############################################################

############################################################
# FUNCTION ID7_rpt_query() 
# RETURN r_where_text (Query By Example)
# DataSource for the report driver with CONSTRUCT
############################################################
FUNCTION ID7_rpt_query() 
	DEFINE r_where_text LIKE rmsreps.sel_text

	CLEAR FORM 
	DIALOG ATTRIBUTES(UNBUFFERED)

		INPUT modu_def_lead_time,modu_user_def_var WITHOUT DEFAULTS FROM def_lead_time,user_def_var  
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","ID7","input-def_lead_time-1") -- albo kd-505 
				MESSAGE kandoomsg2("G",1054,"") 
				# 1054 Enter Report Details;  OK TO Continue.
				LET modu_user_def_var = 130 

			AFTER FIELD def_lead_time 
				IF modu_def_lead_time IS NULL THEN 
					ERROR kandoomsg2("U",9102,"") 
					#9102 Value must be entered.
					NEXT FIELD def_lead_time 
				END IF 
				IF modu_def_lead_time = 0 THEN 
					ERROR kandoomsg2("G",9025,"Lead time") 
					# 9025 Lead time must be greater than zero.
					NEXT FIELD def_lead_time 
				END IF 

			AFTER FIELD user_def_var 
				IF modu_user_def_var IS NULL THEN 
					ERROR kandoomsg2("U",9102,"") 
					#9102 Value must be entered.
					NEXT FIELD user_def_var 
				END IF 
				IF modu_user_def_var = 0 THEN 
					LET modu_user_def_var = 130 
					ERROR kandoomsg2("G",9025,"User defined variable") 
					#9025 User defined variable must be greater than zero.
					NEXT FIELD user_def_var 
				END IF 
		END INPUT 

		CONSTRUCT BY NAME r_where_text ON 
		product.vend_code, 
		product.cat_code, 
		product.part_code, 
		product.desc_text, 
		product.desc2_text 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","ID7","construct-vend_code-1") -- albo kd-505 
				MESSAGE kandoomsg2("U",1001,"")
				#1001 Enter Selection Criteria;  OK TO Continue.
		END CONSTRUCT 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

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
# END FUNCTION ID7_rpt_query() 
############################################################

#####################################################################
# FUNCTION ID7_rpt_process(p_where_text) 
#
# The report driver
#####################################################################
FUNCTION ID7_rpt_process(p_where_text) 
	DEFINE p_where_text LIKE rmsreps.sel_text
	DEFINE l_query_text LIKE rmsreps.sel_text
	DEFINE l_rpt_idx SMALLINT
	DEFINE l_rec_product RECORD 
		cmpy_code LIKE product.cmpy_code, 
		vend_code LIKE product.vend_code, 
		cat_code LIKE product.cat_code, 
		part_code LIKE prodstatus.part_code, 
		desc_text LIKE product.desc_text, 
		days_lead_num LIKE product.days_lead_num, 
		purchase_cost LIKE prodstatus.act_cost_amt, 
		total_reorder_qty DECIMAL(12,4), 
		net_stock_total DECIMAL(12,4), 
		ware_code LIKE product.ware_code
	END RECORD
	DEFINE l_w_part_code LIKE product.part_code
	DEFINE l_tot_qty_onhand DECIMAL(12,4)
	DEFINE l_tot_back_ord_qty DECIMAL(12,4)
	DEFINE l_tot_ord_qty DECIMAL(12,4)
	DEFINE l_demand DECIMAL(12,4)
	DEFINE l_additional_demand DECIMAL(12,4)
	DEFINE l_reorder_val DECIMAL(14,4)
	DEFINE l_reorder_calc1 DECIMAL(12,4)
	DEFINE l_reorder_calc2 DECIMAL(16,6)
	DEFINE l_reorder_qty DECIMAL(12,4)
	DEFINE l_reorder_point DECIMAL(12,4)
	DEFINE l_greatest_date LIKE prodstatus.last_receipt_date 
	DEFINE l_greatest_cost LIKE prodstatus.act_cost_amt 
	DEFINE l_receipt_date LIKE prodstatus.last_receipt_date 
	DEFINE l_act_cost LIKE prodstatus.act_cost_amt 
	DEFINE l_pr_onhand_qty LIKE prodstatus.onhand_qty 
	DEFINE l_pr_onord_qty LIKE prodstatus.onord_qty 
	DEFINE l_pr_back_qty LIKE prodstatus.back_qty 
	DEFINE l_rounded_qty INTEGER 

	#------------------------------------------------------------
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE
		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"ID7_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF

	START REPORT ID7_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	LET l_query_text = 
	"SELECT DISTINCT product.cmpy_code,", 
	"product.vend_code,", 
	"product.cat_code,", 
	"product.part_code,", 
	"product.desc_text,", 
	"product.days_lead_num, ", 
	"product.ware_code ",
	"FROM product ", 
	"WHERE product.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND product.super_part_code IS NULL ", 
	"AND product.status_ind != \'3\' ", 
	"AND ", p_where_text CLIPPED," ", 
	"ORDER BY product.vend_code,product.part_code" 

	PREPARE s_product FROM l_query_text 
	DECLARE c_product CURSOR FOR s_product 

	LET l_query_text =
	"SELECT last_receipt_date,act_cost_amt,onhand_qty,onord_qty,back_qty ", 
	"FROM prodstatus ", 
	"WHERE prodstatus.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ",
	"AND prodstatus.part_code = ? ", 
	"AND prodstatus.status_ind NOT MATCHES ""[34]"""

	PREPARE s_prodstatus FROM l_query_text 
	DECLARE c_costcurs CURSOR FOR s_prodstatus

	LET l_query_text =
	"SELECT part_code FROM product ", 
	"WHERE product.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ",
	"AND product.super_part_code = ?"

	PREPARE s_product_1 FROM l_query_text 
	DECLARE c_super_cursor CURSOR FOR s_product_1 

	FOREACH c_product INTO 
	l_rec_product.cmpy_code,
	l_rec_product.vend_code,
	l_rec_product.cat_code,
	l_rec_product.part_code,
	l_rec_product.desc_text,
	l_rec_product.days_lead_num,
	l_rec_product.ware_code
	
		# accumulate across all warehouses (TQH, TBQ AND TOQ)
		# retrieve purchase cost FROM warehouse with greatest receipt date
		LET l_tot_qty_onhand = 0 
		LET l_tot_ord_qty = 0 
		LET l_tot_back_ord_qty = 0 
		LET l_greatest_cost = 0 
		LET l_greatest_date = 1 

		FOREACH c_costcurs USING l_rec_product.part_code INTO l_receipt_date,l_act_cost,l_pr_onhand_qty,l_pr_onord_qty,l_pr_back_qty   
			IF l_pr_onhand_qty IS NOT NULL THEN 
				LET l_tot_qty_onhand = l_tot_qty_onhand + l_pr_onhand_qty 
			END IF 
			IF l_pr_onord_qty IS NOT NULL THEN 
				LET l_tot_ord_qty = l_tot_ord_qty + l_pr_onord_qty 
			END IF 
			IF l_pr_back_qty IS NOT NULL THEN 
				LET l_tot_back_ord_qty = l_tot_back_ord_qty + l_pr_back_qty 
			END IF 
			IF l_act_cost IS NULL THEN 
				CONTINUE FOREACH 
			END IF 
			IF l_receipt_date IS NULL THEN 
				IF l_greatest_date = 1 
				AND l_act_cost != 0 THEN 
					LET l_greatest_cost = l_act_cost 
				ELSE 
					CONTINUE FOREACH 
				END IF 
			END IF 
			IF l_receipt_date > l_greatest_date THEN 
				LET l_greatest_date = l_receipt_date 
				LET l_greatest_cost = l_act_cost 
			END IF 
		END FOREACH 
		LET l_rec_product.purchase_cost = l_greatest_cost 

		#     calculate net stock total (NST)
		LET l_rec_product.net_stock_total = l_tot_qty_onhand + l_tot_ord_qty - l_tot_back_ord_qty 

		#     calculate l_demand
		SELECT SUM(tran_qty) INTO l_demand FROM prodledg 
		WHERE prodledg.cmpy_code = glob_rec_kandoouser.cmpy_code	AND 
				prodledg.part_code = l_rec_product.part_code	AND 
				prodledg.tran_date > TODAY - 365	AND 
				prodledg.trantype_ind IN ("S","I","J") 
		IF l_demand IS NULL THEN 
			LET l_demand = 0 
		END IF 
		LET l_demand = l_demand * -1 

		#     add additional l_demand IF product IS a superseeded part code
		LET l_additional_demand = 0 

		FOREACH c_super_cursor USING l_rec_product.part_code INTO l_w_part_code 
			SELECT SUM(tran_qty) INTO l_additional_demand FROM prodledg 
			WHERE prodledg.cmpy_code = glob_rec_kandoouser.cmpy_code	AND 
					prodledg.part_code = l_w_part_code	AND 
					prodledg.tran_date > TODAY - 365	AND 
					prodledg.trantype_ind IN ("S","I","J") 
			IF l_additional_demand IS NULL THEN 
				LET l_additional_demand = 0 
			ELSE 
				LET l_additional_demand = l_additional_demand * -1 
			END IF 
			EXIT FOREACH 
		END FOREACH 
		LET l_demand = l_demand + l_additional_demand 

		#     calculate reorder point (ROP)
		IF l_rec_product.days_lead_num IS NULL 
		OR l_rec_product.days_lead_num = 0 THEN 
			LET l_reorder_point = l_demand * (modu_def_lead_time / 365) 
		ELSE 
			LET l_reorder_point = l_demand * (l_rec_product.days_lead_num / 365) 
		END IF 

		#     calculate reorder quantity (ROQ)
		LET l_reorder_calc1 = l_demand / 12 
		IF l_rec_product.purchase_cost = 0 THEN 
			LET l_reorder_calc2 = 0 
		ELSE 
			LET l_reorder_val = modu_user_def_var * (l_demand / l_rec_product.purchase_cost) 
			IF l_reorder_val > 0 THEN 
				LET l_reorder_calc2 = sqrt_func(l_reorder_val,1) 
			ELSE 
				LET l_reorder_calc2 = 0 
			END IF 
		END IF 
		IF l_reorder_calc1 > l_reorder_calc2 THEN 
			LET l_reorder_qty = l_reorder_calc1 
		ELSE 
			LET l_reorder_qty = l_reorder_calc2 
		END IF 
		IF l_reorder_qty IS NULL THEN 
			LET l_reorder_qty = 0 
		END IF 

		#     calculate TOTAL REORDER QUANTITY (TRQ)
		IF l_reorder_point > l_rec_product.net_stock_total THEN 
			LET l_rec_product.total_reorder_qty = l_reorder_point - l_rec_product.net_stock_total + l_reorder_qty 
		ELSE 
			LET l_rec_product.total_reorder_qty = 0 
		END IF 

		#     UPDATE the prodstatus table
		UPDATE prodstatus	SET prodstatus.reorder_point_qty = l_reorder_point,prodstatus.reorder_qty = l_reorder_qty 
		WHERE prodstatus.cmpy_code = l_rec_product.cmpy_code AND 
				prodstatus.part_code = l_rec_product.part_code AND
				prodstatus.ware_code = l_rec_product.ware_code
		#     round reorder qty FOR REPORT
		LET l_rounded_qty = l_rec_product.total_reorder_qty 
		LET l_rec_product.total_reorder_qty = l_rounded_qty 

		#     NOTE: Zero OR negative TRQ amounts should NOT be reported
		IF l_rec_product.total_reorder_qty > 0 THEN 
			#---------------------------------------------------------
			OUTPUT TO REPORT ID7_rpt_list(l_rpt_idx,l_rec_product.*) 
			IF NOT rpt_int_flag_handler2("Product: ",l_rec_product.part_code,"",l_rpt_idx) THEN
				EXIT FOREACH 
			END IF 
			#---------------------------------------------------------
		END IF 
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT ID7_rpt_list
	RETURN rpt_finish("ID7_rpt_list")
	#------------------------------------------------------------

END FUNCTION 
############################################################
# END FUNCTION ID7_rpt_process(p_where_text) 
############################################################

#####################################################################
# REPORT ID7_rpt_list(p_rpt_idx,p_rec_product)
#
# Report Definition/Layout
#####################################################################
REPORT ID7_rpt_list(p_rpt_idx,p_rec_product) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_product RECORD 
		cmpy_code LIKE product.cmpy_code, 
		vend_code LIKE product.vend_code, 
		cat_code LIKE product.cat_code, 
		part_code LIKE prodstatus.part_code, 
		desc_text LIKE product.desc_text, 
		days_lead_num LIKE product.days_lead_num, 
		purchase_cost LIKE prodstatus.act_cost_amt, 
		total_reorder_qty DECIMAL(12,4), 
		net_stock_total DECIMAL(12,4), 
		ware_code LIKE product.ware_code
	END RECORD 
	DEFINE l_line_cost LIKE prodstatus.for_cost_amt 
	DEFINE l_total_cost LIKE prodstatus.for_cost_amt 
	DEFINE l_rpt_total_cost LIKE prodstatus.for_cost_amt 

	ORDER EXTERNAL BY p_rec_product.vend_code,p_rec_product.part_code 
	
	FORMAT 
		FIRST PAGE HEADER 
			LET l_rpt_total_cost = 0 
			LET l_line_cost = 0 
			LET l_total_cost = 0
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

	BEFORE GROUP OF p_rec_product.vend_code 
		SKIP 1 LINE 
		PRINT COLUMN 01, "Vendor: ", 
		COLUMN 09, p_rec_product.vend_code CLIPPED

	ON EVERY ROW 
		#LET total_reorder_qty_rnd = p_rec_product.total_reorder_qty
		LET l_line_cost = p_rec_product.total_reorder_qty * p_rec_product.purchase_cost 
		LET l_total_cost = l_total_cost + l_line_cost 
		PRINT COLUMN 01, p_rec_product.part_code CLIPPED, 
		COLUMN 17, p_rec_product.desc_text       CLIPPED, 
		COLUMN 54, p_rec_product.net_stock_total   USING "---,---,---,--&", 
		COLUMN 70, p_rec_product.total_reorder_qty USING "---,---,---,--&", 
		COLUMN 86, l_line_cost                     USING "---,---,---,-$&" 
 
	AFTER GROUP OF p_rec_product.vend_code 
		SKIP 1 LINE 
		LET l_rpt_total_cost = l_rpt_total_cost + l_total_cost 
		PRINT COLUMN 59, "Total FOR Vendor: ", 
		COLUMN 77, p_rec_product.vend_code CLIPPED, 
		COLUMN 86, l_total_cost USING "---,---,---,-$&" 
		LET l_total_cost = 0 
		SKIP TO top OF PAGE 

	ON LAST ROW 
		NEED 8 LINES 
		SKIP 1 LINE 
		PRINT COLUMN 02,"Report Totals:", 
		COLUMN 80,l_rpt_total_cost USING "-,---,---,---,---,-$&" 
		SKIP 2 LINES 
		#End Of Report
		IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
			PRINT COLUMN 01,"Selection Criteria:" 
			PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text CLIPPED WORDWRAP RIGHT MARGIN 100 
		END IF 
		PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report CLIPPED			
		LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = PAGENO

END REPORT 
