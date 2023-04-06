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
DEFINE modu_req_ind CHAR(1) 
DEFINE modu_requisitions_on SMALLINT
DEFINE modu_reorder_flag LIKE language.yes_flag 
DEFINE modu_detailed LIKE language.yes_flag
DEFINE modu_factor INTEGER 
DEFINE modu_reorder_qty LIKE prodstatus.onhand_qty 

############################################################
# FUNCTION ID8_main()
#
# Purpose - Stock Replenishment Report
############################################################
FUNCTION ID8_main()
	DEFINE l_cnt INTEGER

	CALL setModuleId("ID8") 

	LET modu_requisitions_on = FALSE 
	SELECT COUNT(*) INTO l_cnt FROM reqperson 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
			person_code = glob_rec_kandoouser.sign_on_code 
	IF l_cnt > 0 THEN 
		# found a person
		LET modu_requisitions_on = TRUE 
		CALL create_table("reqdetl","t_reqdetl","","Y")
	END IF 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN "1" #UI/MENU Mode
			OPEN WINDOW I187 WITH FORM "I187" 
			 CALL windecoration_i("I187")
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title
			
			MENU "Stock Replenishment" 

				BEFORE MENU 
					CALL publish_toolbar("kandoo","ID8","menu-Replenishment-1") -- albo kd-505
					CALL rpt_rmsreps_reset(NULL)
					CALL ID8_rpt_process(ID8_rpt_query())

				ON ACTION "WEB-HELP" -- albo kd-372 
					CALL onlinehelp(getmoduleid(),NULL) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar()

				ON ACTION "Report" #COMMAND "Run Report" " SELECT Criteria AND Print Report"
					CALL rpt_rmsreps_reset(NULL)
					CALL ID8_rpt_process(ID8_rpt_query())

				ON ACTION "PRINT MANAGER" --COMMAND "Print" "Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "CANCEL" --COMMAND KEY (interrupt, "E") "Exit" " Exit TO menus" 
					EXIT MENU

			END MENU
			CLOSE WINDOW I187

		WHEN "2" #Background Process with rmsreps.report_code
			CALL ID8_rpt_process(NULL)  

		WHEN "3" #Only create query-where-part
			OPEN WINDOW I187 with FORM "I187" 
			 CALL windecoration_i("I187") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(ID8_rpt_query()) #save where clause in env 
			CLOSE WINDOW I187 
			
		WHEN "4" #Background Process with SQL WHERE ARGUMENT
			CALL ID8_rpt_process(get_url_sel_text())
	END CASE	

	IF modu_requisitions_on THEN 
		DROP TABLE t_reqdetl 
	END IF

END FUNCTION
############################################################
# END FUNCTION ID8_main()
############################################################

############################################################
# FUNCTION ID8_rpt_query() 
# RETURN r_where_text (Query By Example)
# DataSource for the report driver with CONSTRUCT
############################################################
FUNCTION ID8_rpt_query() 
	DEFINE r_where_text LIKE rmsreps.sel_text
	DEFINE l_rec_reqperson RECORD LIKE reqperson.*
	DEFINE l_err_message STRING

	MESSAGE " Enter criteria FOR selection - ESC TO begin search"

	CLEAR FORM
	DIALOG ATTRIBUTES(UNBUFFERED)

		INPUT modu_req_ind,modu_factor,modu_detailed,modu_reorder_flag WITHOUT DEFAULTS FROM req_ind,factor,detailed,reorder_flag  
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","ID8","input-pr_req_ind-1") -- albo kd-505 
				LET modu_req_ind = "N" 
				LET modu_factor = 130 
				LET modu_detailed = "Y" 
				LET modu_reorder_flag = "Y" 

			AFTER INPUT 
				IF modu_req_ind = "Y" THEN
					SELECT * INTO l_rec_reqperson.* FROM reqperson 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code	AND 
							person_code = glob_rec_kandoouser.sign_on_code 
					IF STATUS = NOTFOUND THEN 
						# Not found a person
              		LET l_err_message = "User """,glob_rec_kandoouser.sign_on_code CLIPPED,""" does not have access to Internal Requisitions." 
						ERROR l_err_message
						NEXT FIELD req_ind
					END IF			
				END IF
				IF modu_factor IS NULL THEN 
					LET modu_factor = 0 
				END IF 
		END INPUT 

		CONSTRUCT BY NAME r_where_text ON 
		prodstatus.ware_code, 
		prodstatus.part_code, 
		product.desc_text, 
		product.desc2_text, 
		product.cat_code, 
		product.maingrp_code, 
		product.prodgrp_code, 
		product.class_code, 
		prodstatus.onhand_qty, 
		prodstatus.reserved_qty, 
		prodstatus.back_qty, 
		prodstatus.onord_qty, 
		prodstatus.last_sale_date, 
		prodstatus.last_receipt_date, 
		prodstatus.stocked_flag, 
		prodstatus.stockturn_qty, 
		prodstatus.abc_ind 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","ID8","construct-prodstatus-1") -- albo kd-505 
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
# END FUNCTION ID8_rpt_query() 
############################################################

#####################################################################
# FUNCTION ID8_rpt_process(p_where_text) 
#
# The report driver
#####################################################################
FUNCTION ID8_rpt_process(p_where_text) 
	DEFINE p_where_text LIKE rmsreps.sel_text
	DEFINE l_query_text LIKE rmsreps.sel_text
	DEFINE l_rpt_idx SMALLINT
	DEFINE l_rec_reqdetl RECORD LIKE reqdetl.* 
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.* 
	DEFINE l_rec_product RECORD LIKE product.* 

	IF modu_requisitions_on THEN 
		DELETE FROM t_reqdetl WHERE 1=1 
	END IF 

	#------------------------------------------------------------
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE
		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"ID8_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF

	START REPORT ID8_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	LET l_query_text = 
	"SELECT prodstatus.*,product.* ", 
	"FROM prodstatus,product ", 
	"WHERE prodstatus.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND product.cmpy_code = prodstatus.cmpy_code ", 
	"AND product.part_code = prodstatus.part_code ", 
	"AND product.super_part_code IS NULL ", 
	"AND prodstatus.status_ind = '1' ", 
	"AND product.status_ind = '1' ", 
	"AND ", p_where_text CLIPPED," ", 
	"ORDER BY prodstatus.ware_code,prodstatus.part_code" 

	PREPARE s_prodstatus FROM l_query_text 
	DECLARE c_prodstatus CURSOR FOR s_prodstatus 

	FOREACH c_prodstatus INTO l_rec_prodstatus.*, l_rec_product.* 
			#---------------------------------------------------------
			OUTPUT TO REPORT ID8_rpt_list(l_rpt_idx,l_rec_prodstatus.*,l_rec_product.*) 
			IF NOT rpt_int_flag_handler2("Product: ",l_rec_product.part_code,"",l_rpt_idx) THEN
				LET modu_req_ind = "N"
				EXIT FOREACH 
			END IF 
			#---------------------------------------------------------
			IF modu_req_ind = "Y" AND modu_requisitions_on = TRUE AND modu_reorder_qty > 0 THEN 
				INITIALIZE l_rec_reqdetl.* TO NULL 
				LET l_rec_reqdetl.part_code = l_rec_prodstatus.part_code 
				LET l_rec_reqdetl.vend_code = l_rec_prodstatus.ware_code 
				LET l_rec_reqdetl.req_qty = modu_reorder_qty 
				INSERT INTO t_reqdetl VALUES (l_rec_reqdetl.*) 
			END IF 
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT ID8_rpt_list
	IF modu_req_ind = "Y" THEN 
		CALL create_req(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code) 
	END IF
	RETURN rpt_finish("ID8_rpt_list")
	#------------------------------------------------------------

END FUNCTION 
############################################################
# END FUNCTION ID8_rpt_process(p_where_text) 
############################################################

#####################################################################
# REPORT ID8_rpt_list(p_rpt_idx,p_rec_prodstatus,p_rec_product)
#
# Report Definition/Layout
#####################################################################
REPORT ID8_rpt_list(p_rpt_idx,p_rec_prodstatus,p_rec_product) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_prodstatus RECORD LIKE prodstatus.* 
	DEFINE p_rec_product RECORD LIKE product.* 
	DEFINE l_rec_product2 RECORD LIKE product.* 
	DEFINE l_rec_ingroup RECORD LIKE ingroup.* 
	DEFINE l_rec_warehouse RECORD LIKE warehouse.* 
	DEFINE l_rec_prodnote RECORD LIKE prodnote.* 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_orderhead RECORD LIKE orderhead.* 
	DEFINE l_rec_orderdetl RECORD LIKE orderdetl.* 
	DEFINE l_rec_purchhead RECORD LIKE purchhead.* 
	DEFINE l_rec_purchdetl RECORD LIKE purchdetl.* 
	DEFINE l_arr_rec_trend ARRAY[12] OF RECORD 
		period_num SMALLINT, 
		year_num SMALLINT, 
		trend_qty INTEGER 
	END RECORD 
	DEFINE l_arr_super_part ARRAY[300] OF CHAR(15)
	DEFINE l_allocated_qty  LIKE prodstatus.onhand_qty
	DEFINE l_available_qty  LIKE prodstatus.onhand_qty
	DEFINE l_future_qty  LIKE prodstatus.onhand_qty
	DEFINE l_super_ytds  LIKE prodstatus.onhand_qty
	DEFINE l_ytds_qty  LIKE prodstatus.onhand_qty
	DEFINE l_super_trend_qty  LIKE prodstatus.onhand_qty
	DEFINE l_reorder_point  LIKE prodstatus.onhand_qty
	DEFINE l_reorder_qty2  LIKE prodstatus.onhand_qty
	DEFINE l_order_qty  LIKE prodstatus.onhand_qty
	DEFINE l_quote_qty  LIKE prodstatus.onhand_qty
	DEFINE l_excess_qty  LIKE prodstatus.onhand_qty
	DEFINE l_received_qty  LIKE prodstatus.onhand_qty
	DEFINE l_voucher_qty  LIKE prodstatus.onhand_qty
	DEFINE l_purchase_qty LIKE prodstatus.onhand_qty 
	DEFINE l_ytdc_amt LIKE prodstatus.list_amt
	DEFINE l_super_ytdc LIKE prodstatus.list_amt
	DEFINE l_unit_cost_amt LIKE prodstatus.list_amt
	DEFINE l_ext_cost_amt LIKE prodstatus.list_amt
	DEFINE l_unit_tax_amt LIKE prodstatus.list_amt
	DEFINE l_ext_tax_amt LIKE prodstatus.list_amt
	DEFINE l_line_total_amt LIKE prodstatus.list_amt 
	DEFINE l_line_text CHAR(132) 
	DEFINE l_year_text CHAR(4) 
	DEFINE l_order_count SMALLINT	
	DEFINE l_purchase_count SMALLINT
	DEFINE l_note_count SMALLINT
	DEFINE l_dont_print SMALLINT 
	DEFINE l_mid_year SMALLINT
	DEFINE l_order_cnt SMALLINT
	DEFINE l_year_num SMALLINT
	DEFINE l_period_num SMALLINT
	DEFINE l_year_num2 SMALLINT
	DEFINE l_end_period SMALLINT
	DEFINE l_end_year SMALLINT
	DEFINE l_mid_period SMALLINT
	DEFINE l_super_part LIKE product.part_code 
	DEFINE l_tran_date DATE 
	DEFINE idx, i, k, j, y, x SMALLINT

	ORDER EXTERNAL BY p_rec_prodstatus.ware_code,p_rec_prodstatus.part_code 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,PAGENO) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 CLIPPED #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 CLIPPED #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]
			SELECT *	INTO l_rec_warehouse.* FROM warehouse 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
					ware_code = p_rec_prodstatus.ware_code 
			IF STATUS = NOTFOUND THEN 
				LET l_rec_warehouse.desc_text = "**********" 
			END IF 
			PRINT COLUMN 1, "Warehouse:", 
			COLUMN 12, p_rec_prodstatus.ware_code CLIPPED, 
			COLUMN 16, l_rec_warehouse.desc_text CLIPPED
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text CLIPPED 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text CLIPPED
			IF modu_detailed = "N" THEN 
				PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3] 
			ELSE 
				SKIP 1 LINE 
			END IF

	BEFORE GROUP OF p_rec_prodstatus.ware_code 
		SKIP TO TOP OF PAGE 

	BEFORE GROUP OF p_rec_prodstatus.part_code 
		FOR i = 1 TO 300 
			IF l_arr_super_part[i] IS NULL THEN 
				EXIT FOR 
			END IF 
			INITIALIZE l_arr_super_part[i] TO NULL 
		END FOR 
		IF modu_detailed = "Y" THEN 
			SKIP TO TOP OF PAGE 
		END IF 

	ON EVERY ROW 
		LET l_allocated_qty = p_rec_prodstatus.back_qty + p_rec_prodstatus.reserved_qty 
		LET l_available_qty = p_rec_prodstatus.onhand_qty	- l_allocated_qty 
		LET l_future_qty = l_available_qty + p_rec_prodstatus.onord_qty 
		#Moved TO variable because non-Informix RDBMS do NOT have
		#UNITS but <Anton Dickinson> does
		LET l_tran_date = (TODAY - 1 UNITS YEAR) 

		SELECT SUM(tran_qty), SUM(cost_amt) INTO l_ytds_qty, l_ytdc_amt 
		FROM prodledg 
		WHERE tran_date <= TODAY 
		#AND tran_date > (TODAY - 1 UNITS YEAR)
		AND tran_date > l_tran_date 
		AND part_code = p_rec_prodstatus.part_code 
		AND ware_code = p_rec_prodstatus.ware_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND trantype_ind in ('S','C','I','J') 

		IF l_ytds_qty IS NULL THEN 
			LET l_ytds_qty = 0 
		END IF 
		IF l_ytdc_amt IS NULL THEN 
			LET l_ytdc_amt = 0 
		END IF 
		LET idx = 1 
		LET x = 1 
		LET l_arr_super_part[1] = p_rec_product.part_code 
		WHILE TRUE 
			LET y = idx 
			FOR i = x TO idx 
				DECLARE c_superseded CURSOR FOR 
				SELECT part_code FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND super_part_code = l_arr_super_part[i] 
				FOREACH c_superseded INTO l_super_part 
					FOR j = 1 TO y 
						IF l_arr_super_part[j] = l_super_part THEN 
							CONTINUE FOREACH 
						END IF 
					END FOR 
					LET y = y + 1 
					LET l_arr_super_part[y] = l_super_part 
					IF y = 300 THEN 
						EXIT WHILE 
					END IF 
				END FOREACH 
			END FOR 
			IF idx != y THEN 
				LET x = idx + 1 
				LET idx = y 
			ELSE 
				EXIT WHILE 
			END IF 
		END WHILE 
		FOR i = 2 TO 300 
			IF l_arr_super_part[i] IS NULL THEN 
				EXIT FOR 
			END IF 
			LET l_super_ytds = 0 
			LET l_super_ytdc = 0 

			LET l_tran_date = (TODAY - 1 UNITS YEAR) 

			SELECT SUM(tran_qty), SUM(cost_amt) 
			INTO l_super_ytds, l_super_ytdc FROM prodledg 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND tran_date <= TODAY 
			AND part_code = l_arr_super_part[i] 
			#AND tran_date > (TODAY - 1 UNITS YEAR)
			AND tran_date > l_tran_date 
			AND ware_code = p_rec_prodstatus.ware_code 
			AND trantype_ind in ('S','C','I','J') 
			IF l_super_ytds IS NULL THEN 
				LET l_super_ytds = 0 
			END IF 
			IF l_super_ytdc IS NULL THEN 
				LET l_super_ytdc = 0 
			END IF 
			LET l_ytds_qty = l_ytds_qty + l_super_ytds 
			LET l_ytdc_amt = l_ytdc_amt + l_super_ytdc 
		END FOR 
		LET l_ytds_qty = l_ytds_qty * -1 
		LET l_reorder_point = p_rec_prodstatus.critical_qty + (l_ytds_qty * (p_rec_product.days_lead_num	/ 365)) 
		IF l_future_qty < l_reorder_point THEN 
			LET modu_reorder_qty = l_ytds_qty/12 
			IF p_rec_prodstatus.act_cost_amt = 0 
			OR p_rec_prodstatus.act_cost_amt IS NULL THEN 
				LET l_reorder_qty2 = 0 
			ELSE 
				LET l_reorder_qty2 = modu_factor * (l_ytds_qty / p_rec_prodstatus.act_cost_amt) 
				LET l_reorder_qty2 = sqrt_func(l_reorder_qty2,0) 
			END IF 
			IF l_reorder_qty2 > modu_reorder_qty THEN 
				LET modu_reorder_qty = l_reorder_qty2 
			END IF 
		ELSE 
			LET modu_reorder_qty = 0 
		END IF 
		LET l_dont_print = FALSE 
		IF modu_reorder_qty > 0 
		OR modu_reorder_flag = "N" THEN 
			PRINT COLUMN 001, p_rec_product.part_code CLIPPED, 
			COLUMN 017, p_rec_product.desc_text CLIPPED, 
			COLUMN 054, p_rec_prodstatus.onhand_qty   USING "------&", 
			COLUMN 063, l_allocated_qty           USING "------&", 
			COLUMN 072, l_available_qty           USING "------&", 
			COLUMN 081, p_rec_prodstatus.onord_qty    USING "------&", 
			COLUMN 090, l_future_qty              USING "------&", 
			COLUMN 099, p_rec_prodstatus.critical_qty USING "------&", 
			COLUMN 108, p_rec_product.days_lead_num   USING "------&", 
			COLUMN 117, l_reorder_point           USING "------&", 
			COLUMN 126, modu_reorder_qty           USING "------&" 
			IF l_reorder_point > 0	AND modu_reorder_qty > 0 THEN 
				WHENEVER ERROR CONTINUE 
				UPDATE prodstatus 
				SET reorder_point_qty = l_reorder_point,reorder_qty = modu_reorder_qty 
				WHERE part_code = p_rec_prodstatus.part_code 
				AND ware_code = p_rec_prodstatus.ware_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				WHENEVER ERROR stop 
			END IF 
		ELSE 
			LET l_dont_print = TRUE 
		END IF 

	AFTER GROUP OF p_rec_prodstatus.part_code 
		IF modu_detailed = "Y" AND NOT l_dont_print THEN 
			SKIP 1 LINE 
			IF p_rec_prodstatus.bin1_text IS NOT NULL 
			OR p_rec_prodstatus.bin2_text IS NOT NULL 
			OR p_rec_prodstatus.bin3_text IS NOT NULL THEN 
				PRINT COLUMN 001, "Bin Locations:", 
				COLUMN 016, p_rec_prodstatus.bin1_text CLIPPED, 
				COLUMN 032, p_rec_prodstatus.bin2_text CLIPPED, 
				COLUMN 048, p_rec_prodstatus.bin3_text CLIPPED 
			END IF 
			INITIALIZE l_rec_product2.* TO NULL 
			DECLARE c_product3 CURSOR FOR 
			SELECT * FROM product 
			WHERE super_part_code = p_rec_product.part_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			OPEN c_product3 
			FETCH c_product3 INTO l_rec_product2.* 
			IF STATUS = 0 THEN 
				PRINT COLUMN 001, "Supersedes :", 
				COLUMN 016, l_rec_product2.part_code CLIPPED, 
				COLUMN 032, l_rec_product2.desc_text CLIPPED," ",l_rec_product2.desc2_text CLIPPED 
			END IF 
			IF p_rec_product.alter_part_code IS NOT NULL THEN 
				INITIALIZE l_rec_product2.* TO NULL 
				SELECT * INTO l_rec_product2.* FROM product 
				WHERE part_code = p_rec_product.alter_part_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF STATUS = NOTFOUND THEN 
					SELECT * INTO l_rec_ingroup.* FROM ingroup 
					WHERE type_ind = "A" 
					AND ingroup_code = p_rec_product.alter_part_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					PRINT COLUMN 001, "Alternate :", 
					COLUMN 016, l_rec_ingroup.ingroup_code CLIPPED, 
					COLUMN 032, l_rec_ingroup.desc_text CLIPPED 
				ELSE 
					PRINT COLUMN 001, "Alternate :", 
					COLUMN 016, p_rec_product.alter_part_code CLIPPED, 
					COLUMN 032, l_rec_product2.desc_text CLIPPED," ",l_rec_product2.desc2_text CLIPPED 
				END IF 
			END IF 
			LET l_excess_qty = l_future_qty - modu_reorder_qty 
			SELECT COUNT(*) INTO l_order_cnt FROM orderhead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND order_num in (SELECT order_num FROM orderdetl 
			WHERE part_code = p_rec_prodstatus.part_code 
			AND ware_code = p_rec_prodstatus.ware_code 
			AND order_qty != inv_qty 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code) 
			SELECT SUM(order_qty - inv_qty) INTO l_order_qty 
			FROM orderdetl 
			WHERE part_code = p_rec_prodstatus.part_code 
			AND ware_code = p_rec_prodstatus.ware_code 
			AND order_qty != inv_qty 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF l_order_qty IS NULL THEN 
				LET l_order_qty = 0 
			END IF 
			SELECT SUM(order_qty) INTO l_quote_qty 
			FROM quotedetl,quotehead 
			WHERE part_code = p_rec_prodstatus.part_code 
			AND quotedetl.ware_code = p_rec_prodstatus.ware_code 
			AND quotehead.order_num = quotedetl.order_num 
			AND quotehead.status_ind = "U" 
			AND quotehead.cmpy_code = quotedetl.cmpy_code 
			AND quotedetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF l_quote_qty IS NULL THEN 
				LET l_quote_qty = 0 
			END IF 
			PRINT COLUMN 001, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3] 
			PRINT COLUMN 001, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line3_text  --> glob_rec_kandooreport.line3_text 
			PRINT COLUMN 001, p_rec_product.prodgrp_code CLIPPED, 
			COLUMN 005, p_rec_product.cat_code CLIPPED, 
			COLUMN 009, p_rec_product.class_code CLIPPED, 
			COLUMN 020, p_rec_prodstatus.last_receipt_date USING "dd/mm/yyyy", 
			COLUMN 032, p_rec_prodstatus.act_cost_amt      USING "------&.&&&&", 
			COLUMN 046, p_rec_product.pur_uom_code CLIPPED, 
			COLUMN 051, p_rec_product.stock_uom_code CLIPPED, 
			COLUMN 057, l_ytds_qty/12 USING "-------&", 
			COLUMN 067, l_ytds_qty    USING "-------&", 
			COLUMN 078, l_ytdc_amt    USING "------&.&&", 
			COLUMN 090, l_excess_qty  USING "------&", 
			COLUMN 100, l_order_qty   USING "------&", 
			COLUMN 110, l_quote_qty   USING "------&", 
			COLUMN 120, l_order_cnt   USING "-----&" 
			PRINT COLUMN 001, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3] 
			CALL get_fiscal_year_period_for_date(glob_rec_kandoouser.cmpy_code,TODAY) 
			RETURNING l_year_num, 
			l_period_num 
			LET l_line_text = "Quarterly:" 
			LET l_period_num = l_period_num - 1 
			IF l_period_num = 0 THEN 
				LET l_period_num = 12 
				LET l_year_num = l_year_num - 1 
			END IF 
			LET l_end_year = l_year_num 
			LET l_mid_year = l_year_num 
			FOR i = 0 TO 11 
				LET l_arr_rec_trend[i+1].period_num = l_period_num 
				LET l_arr_rec_trend[i+1].year_num = l_year_num 
				LET l_end_period = l_arr_rec_trend[i+1].period_num - 2 
				LET l_mid_period = l_end_period + 1 
				IF l_end_period <= 0 THEN 
					IF l_end_period = 0 THEN 
						LET l_mid_period = 1 
						LET l_mid_year = l_year_num 
					ELSE 
						LET l_mid_period = 12 
						LET l_mid_year = l_year_num - 1 
					END IF 
					LET l_end_period = l_end_period + 12 
					LET l_end_year = l_year_num - 1 
				END IF 
				SELECT SUM(sales_qty-credit_qty) INTO l_arr_rec_trend[i+1].trend_qty 
				FROM prodhist 
				WHERE part_code = p_rec_prodstatus.part_code 
				AND ware_code = p_rec_prodstatus.ware_code 
				AND ((year_num = l_arr_rec_trend[i+1].year_num 
				AND period_num = l_arr_rec_trend[i+1].period_num) 
				OR (year_num = l_mid_year 
				AND period_num = l_mid_period) 
				OR (year_num = l_end_year 
				AND period_num = l_end_period)) 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF l_arr_rec_trend[i+1].trend_qty IS NULL THEN 
					LET l_arr_rec_trend[i+1].trend_qty = 0 
				END IF 
				FOR k = 2 TO 300 
					IF l_arr_super_part[k] IS NULL THEN 
						EXIT FOR 
					END IF 
					SELECT SUM(sales_qty-credit_qty) INTO l_super_trend_qty 
					FROM prodhist 
					WHERE part_code = l_arr_super_part[k] 
					AND ware_code = p_rec_prodstatus.ware_code 
					AND ((year_num = l_arr_rec_trend[i+1].year_num 
					AND period_num = l_arr_rec_trend[i+1].period_num) 
					OR (year_num = l_mid_year 
					AND period_num = l_mid_period) 
					OR (year_num = l_end_year 
					AND period_num = l_end_period)) 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					IF l_super_trend_qty IS NULL THEN 
						LET l_super_trend_qty = 0 
					END IF 
					LET l_arr_rec_trend[i+1].trend_qty = l_arr_rec_trend[i+1].trend_qty	+ l_super_trend_qty 
				END FOR 
				WHENEVER ERROR CONTINUE 
				LET l_year_text = l_year_num 
				LET l_year_num2 = l_year_text[3,4] 
				IF l_year_num2 IS NULL THEN 
					LET l_year_num2 = 0 
				END IF 
				WHENEVER ERROR stop 
				IF i = 0 THEN 
					LET l_line_text = l_line_text CLIPPED, "   ",l_arr_rec_trend[i+1].period_num USING "##", "/",l_year_num2 USING "&&" 
				ELSE 
					LET l_line_text = l_line_text CLIPPED, "    ",l_arr_rec_trend[i+1].period_num USING "##", "/",l_year_num2 USING "&&" 
				END IF 
				LET l_period_num = l_period_num - 3 
				IF l_period_num <= 0 THEN 
					LET l_period_num = l_period_num + 12 
					LET l_year_num = l_year_num - 1 
					LET l_mid_year = l_year_num 
					LET l_end_year = l_year_num 
				END IF 
			END FOR 
			LET l_line_text = l_line_text CLIPPED, "  Min Ord Qty" 
			PRINT COLUMN 001, l_line_text CLIPPED
			PRINT COLUMN 012, l_arr_rec_trend[1].trend_qty USING "------&", 
			COLUMN 021, l_arr_rec_trend[2].trend_qty  USING "------&", 
			COLUMN 030, l_arr_rec_trend[3].trend_qty  USING "------&", 
			COLUMN 039, l_arr_rec_trend[4].trend_qty  USING "------&", 
			COLUMN 048, l_arr_rec_trend[5].trend_qty  USING "------&", 
			COLUMN 057, l_arr_rec_trend[6].trend_qty  USING "------&", 
			COLUMN 066, l_arr_rec_trend[7].trend_qty  USING "------&", 
			COLUMN 075, l_arr_rec_trend[8].trend_qty  USING "------&", 
			COLUMN 084, l_arr_rec_trend[9].trend_qty  USING "------&", 
			COLUMN 093, l_arr_rec_trend[10].trend_qty USING "------&", 
			COLUMN 102, l_arr_rec_trend[11].trend_qty USING "------&", 
			COLUMN 111, l_arr_rec_trend[12].trend_qty USING "------&", 
			COLUMN 120, p_rec_product.min_ord_qty     USING "------&" 
			PRINT COLUMN 001, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3] 
			SELECT * INTO l_rec_vendor.* FROM vendor 
			WHERE vend_code = p_rec_product.vend_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			PRINT COLUMN 001, "Preferred Supplier :", 
			COLUMN 023, p_rec_product.vend_code CLIPPED, 
			COLUMN 032, l_rec_vendor.name_text CLIPPED, 
			COLUMN 064, "Last FOB Cost", 
			COLUMN 079, p_rec_prodstatus.for_cost_amt USING "------&.&&&&", 
			COLUMN 093, p_rec_prodstatus.for_curr_code CLIPPED, 
			COLUMN 099, "Order Qty:" 
			SKIP 1 LINE 
			LET l_note_count = 0 
			DECLARE c_prodnote CURSOR FOR 
			SELECT * FROM prodnote 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = p_rec_product.part_code 
			ORDER BY note_date, note_seq 
			FOREACH c_prodnote INTO l_rec_prodnote.* 
				LET l_note_count = l_note_count + 1 
				IF l_note_count = 1 THEN 
					PRINT COLUMN 001,"Product Notes :", 
					COLUMN 018, l_rec_prodnote.note_date USING "dd/mm/yyyy", 
					COLUMN 030, l_rec_prodnote.note_text CLIPPED; 
				ELSE 
					PRINT COLUMN 018, l_rec_prodnote.note_date USING "dd/mm/yyyy", 
					COLUMN 030, l_rec_prodnote.note_text CLIPPED; 
				END IF 
				CASE 
					WHEN l_note_count = 1 
						PRINT COLUMN 099, "Supplier :" 
					WHEN l_note_count = 3 
						PRINT COLUMN 099, "Priority :" 
					OTHERWISE 
						PRINT COLUMN 099, " " 
				END CASE 
			END FOREACH 
			CASE 
				WHEN l_note_count = 0 
					PRINT COLUMN 099, "Supplier :" 
					SKIP 1 LINE 
					PRINT COLUMN 099, "Priority :" 
				WHEN l_note_count = 1 
					SKIP 1 LINE 
					PRINT COLUMN 099, "Priority :" 
				WHEN l_note_count = 2 
					PRINT COLUMN 099, "Priority :" 
			END CASE 
			PRINT COLUMN 001, "---------------------------------------", 
			"---------------------------------------", 
			"------------------" 
			LET l_order_count = 0 
			DECLARE c_orderdetl CURSOR FOR 
			SELECT * FROM orderdetl 
			WHERE part_code = p_rec_prodstatus.part_code 
			AND ware_code = p_rec_prodstatus.ware_code 
			AND order_qty != inv_qty 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			FOREACH c_orderdetl INTO l_rec_orderdetl.* 
				IF l_order_count = 0 THEN 
					PRINT COLUMN 001, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line4_text  --> glob_rec_kandooreport.line4_text 
					PRINT COLUMN 017, "----------------------------------------", 
					"----------------------------------------" 
					LET l_order_count = l_order_count + 1 
				END IF 
				SELECT * INTO l_rec_orderhead.* FROM orderhead 
				WHERE order_num = l_rec_orderdetl.order_num 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET l_order_qty = l_rec_orderdetl.order_qty	- l_rec_orderdetl.inv_qty 
				PRINT COLUMN 018, l_rec_orderdetl.cust_code, 
				COLUMN 028, l_rec_orderdetl.order_num      USING "########", 
				COLUMN 037, l_rec_orderhead.order_date     USING "dd/mm/yyyy", 
				COLUMN 049, l_rec_orderdetl.order_qty      USING "-------&", 
				COLUMN 059, l_rec_orderdetl.uom_code, 
				COLUMN 064, l_rec_orderdetl.unit_price_amt USING "-----&.&&&&", 
				COLUMN 076, l_rec_orderdetl.ext_price_amt  USING "------&.&&", 
				COLUMN 087, l_rec_orderhead.ship_date      USING "dd/mm/yyyy" 
			END FOREACH 
			SKIP 1 LINE 
			LET l_purchase_count = 0 
			DECLARE c_purchdetl CURSOR FOR 
			SELECT purchdetl.*,purchhead.* FROM purchdetl, purchhead 
			WHERE ref_text = p_rec_prodstatus.part_code 
			AND ware_code = p_rec_prodstatus.ware_code 
			AND purchdetl.order_num = purchhead.order_num 
			AND purchdetl.type_ind = "I" 
			AND purchdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND purchdetl.cmpy_code = purchhead.cmpy_code 
			AND purchhead.status_ind != "C" 
			FOREACH c_purchdetl INTO l_rec_purchdetl.*, l_rec_purchhead.* 
				IF l_purchase_count = 0 THEN 
					PRINT COLUMN 001, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line5_text  --glob_rec_kandooreport.line5_text 
					PRINT COLUMN 017, "----------------------------------------", 
					"----------------------------------------" 
					LET l_purchase_count = l_purchase_count + 1 
				END IF 
				CALL po_line_info(glob_rec_kandoouser.cmpy_code,l_rec_purchhead.order_num,l_rec_purchdetl.line_num) 
				RETURNING l_order_qty, 
				l_received_qty, 
				l_voucher_qty, 
				l_unit_cost_amt, 
				l_ext_cost_amt, 
				l_unit_tax_amt, 
				l_ext_tax_amt, 
				l_line_total_amt 
				LET l_purchase_qty = l_order_qty - l_received_qty 
				IF l_purchase_qty > 0 THEN 
					PRINT COLUMN 018, l_rec_purchdetl.vend_code CLIPPED, 
					COLUMN 028, l_rec_purchdetl.order_num  USING "########", 
					COLUMN 037, l_rec_purchhead.order_date USING "dd/mm/yyyy", 
					COLUMN 049, l_purchase_qty             USING "-------&", 
					COLUMN 059, l_rec_purchdetl.uom_code CLIPPED, 
					COLUMN 064, l_unit_cost_amt            USING "-----&.&&&&", 
					COLUMN 076, l_ext_cost_amt             USING "------&.&&", 
					COLUMN 087, l_rec_purchhead.due_date   USING "dd/mm/yyyy" 
				END IF 
			END FOREACH 
		END IF 
			
		ON LAST ROW 
		SKIP 1 LINE 
		#End Of Report
		IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
			PRINT COLUMN 01,"Selection Criteria:" 
			PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text CLIPPED WORDWRAP RIGHT MARGIN 100 
			PRINT COLUMN 10, "AND user defined factor = ",modu_factor USING "<<<<<<"
		END IF 
		PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report CLIPPED			
		LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = PAGENO

END REPORT 
