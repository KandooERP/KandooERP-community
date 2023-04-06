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
# Purpose - Work In Progress Listing
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "../mn/M_MN_GLOBALS.4gl"
GLOBALS "../mn/M4_GROUP_GLOBALS.4gl" 
GLOBALS "../mn/M47_GLOBALS.4gl"

GLOBALS 

	DEFINE 
	fv_query_text STRING, 
 	pr_menunames RECORD LIKE menunames.* 

END GLOBALS 
###########################################################################
# MAIN
#
# Purpose - Work In Progress Listing
###########################################################################
MAIN 
	#Initial UI Init
	CALL setModuleId("M47") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	OPEN WINDOW M186 with FORM "M186" 
	CALL  windecoration_m("M186" ) -- albo kd-762 

	CALL kandoomenu("M", 162) RETURNING pr_menunames.* 
	MENU pr_menunames.menu_text 

		ON ACTION "WEB-HELP" -- albo kd-376 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND pr_menunames.cmd1_code pr_menunames.cmd1_text # REPORT 
			IF report_main() THEN 
				NEXT option pr_menunames.cmd2_code # PRINT 
			END IF 

		ON ACTION "Print Manager"		#command pr_menunames.cmd2_code pr_menunames.cmd2_text # Print
			CALL run_prog("URS", "", "", "", "") 
			NEXT option pr_menunames.cmd1_code # REPORT 

		COMMAND pr_menunames.cmd4_code pr_menunames.cmd4_text # EXIT 
			EXIT MENU 

		COMMAND KEY(interrupt) 
			EXIT MENU 
	END MENU 

	CLOSE WINDOW M186 

END MAIN 
###########################################################################
#END MAIN
###########################################################################


###########################################################################
# FUNCTION report_main()
#
# 
###########################################################################
FUNCTION report_main()
	DEFINE l_rpt_idx SMALLINT  #report array index 
	DEFINE 
	fv_where_part CHAR(2000), 
	fv_status_ind CHAR(2000), 
	fv_balance LIKE shoporddetl.required_qty, 
	fr_shopordhead RECORD LIKE shopordhead.*, 
	fr_shoporddetl RECORD LIKE shoporddetl.* 


	LET msgresp = kandoomsg("M",1500,"")	# MESSAGE "Enter Selection Criteria - ESC TO Accept, DEL TO Exit"

	CONSTRUCT fv_where_part 
	ON shoporddetl.work_centre_code, 
	shopordhead.shop_order_num, 
	shopordhead.suffix_num, 
	shopordhead.cust_code, 
	shopordhead.part_code, 
	shopordhead.status_ind, 
	shopordhead.start_date, 
	shopordhead.end_date, 
	shopordhead.actual_start, 
	shopordhead.actual_end 
	FROM work_centre_code, 
	shop_order_num, 
	suffix_num, 
	cust_code, 
	product, 
	status_ind, 
	start_date, 
	end_date, 
	actual_start, 
	actual_end 

		ON ACTION "WEB-HELP" -- albo kd-376 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (fv_where_part IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"M47_rpt_list_wip",fv_where_part, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT M47_rpt_list_wip TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET fv_where_part = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------

	LET fv_query_text = " SELECT * ", 
	" FROM shopordhead, shoporddetl ", 
	" WHERE shopordhead.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	" AND shopordhead.cmpy_code = ", 
	" shoporddetl.cmpy_code ", 
	" AND shopordhead.shop_order_num = ", 
	" shoporddetl.shop_order_num ", 
	" AND ", fv_where_part clipped," ", 
	" ORDER BY shoporddetl.work_centre_code", 
	", shoporddetl.part_code", 
	", shoporddetl.start_date", 
	", shoporddetl.shop_order_num" 

	PREPARE statement1 FROM fv_query_text 
	DECLARE ts_cur CURSOR FOR statement1 


	FOREACH ts_cur INTO fr_shopordhead.*, fr_shoporddetl.* 
		IF (fr_shoporddetl.type_ind = "W") 
		AND (fr_shoporddetl.work_centre_code IS NOT null) THEN
		 	#---------------------------------------------------------
			OUTPUT TO REPORT M47_rpt_list_wip(l_rpt_idx,
			fr_shopordhead.*,	fr_shoporddetl.*) 
		 	#---------------------------------------------------------			
		END IF 
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT M47_rpt_list_wip
	CALL rpt_finish("M47_rpt_list_wip")
	#------------------------------------------------------------

	RETURN true 

END FUNCTION 
###########################################################################
# END FUNCTION report_main()
###########################################################################


###########################################################################
# REPORT M47_rpt_list_wip(p_rpt_idx,rr_shopordhead, rr_shoporddetl) 
#
# 
###########################################################################
REPORT M47_rpt_list_wip(p_rpt_idx,rr_shopordhead, rr_shoporddetl) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE 
	rv_product_desc_text CHAR(30), 
	rv_cmpy_name CHAR(30), 
	rv_title CHAR(70), 
	rv_product_uom CHAR(4), 
	rv_desc_txt CHAR(10), 

	rv_position SMALLINT, 
	rv_cnt SMALLINT, 
	rv_first_item SMALLINT, 

	rv_act_cost LIKE shoporddetl.std_wgted_cost_amt, 
	rv_cost LIKE shoporddetl.std_wgted_cost_amt, 
	rv_price LIKE shoporddetl.std_wgted_cost_amt, 

	rv_weight_qty LIKE product.weight_qty, 
	rv_cubic_qty LIKE product.cubic_qty, 
	rv_tt_weight_qty LIKE product.weight_qty, 
	rv_tt_cubic_qty LIKE product.cubic_qty, 

	rv_required_qty LIKE shopordhead.order_qty, 
	rv_completed_qty LIKE shoporddetl.issued_qty, 
	rv_balance_qty LIKE shoporddetl.issued_qty, 

	rv_status_ind LIKE wipreceipt.status_ind, 

	rv_required_time LIKE wipreceipt.receipt_qty, 
	rv_completed_time LIKE wipreceipt.receipt_qty, 
	rv_balance_time LIKE wipreceipt.receipt_qty, 

	rv_tt_required_qty LIKE shopordhead.order_qty, 
	rv_tt_completed_qty LIKE shoporddetl.issued_qty, 
	rv_tt_balance_qty LIKE shoporddetl.issued_qty, 

	rv_tt_required_time LIKE wipreceipt.receipt_qty, 
	rv_tt_completed_time LIKE wipreceipt.receipt_qty, 
	rv_tt_balance_time LIKE wipreceipt.receipt_qty, 

	rv_tt_est_cost LIKE shoporddetl.std_wgted_cost_amt, 
	rv_tt_act_cost LIKE shoporddetl.act_act_cost_amt, 

	rr_wipreceipt RECORD LIKE wipreceipt.*, 
	rr_prodstatus RECORD LIKE prodstatus.*, 
	rr_workcentre RECORD LIKE workcentre.*, 
	rr_shopordhead RECORD LIKE shopordhead.*, 
	rr_shoporddetl RECORD LIKE shoporddetl.* 


	OUTPUT 
	top margin 0 
	left margin 0 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
		

			SELECT * 
			INTO rr_workcentre.* 
			FROM workcentre 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND work_centre_code = rr_shoporddetl.work_centre_code 

			PRINT COLUMN 1, "Work Centre : ", 
			COLUMN 15, rr_workcentre.work_centre_code, 
			COLUMN 30, rr_workcentre.desc_text, 
			COLUMN 65, "Unit of Measure : ", 
			COLUMN 85, rr_shopordhead.uom_code, 
			COLUMN 90, "Time Units : ", 
			COLUMN 101, rr_workcentre.processing_ind 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			IF rr_workcentre.count_centre_ind = "O" THEN 
				PRINT COLUMN 57, "----- D A T E S ------", 
				COLUMN 80, "-QUANTITY-", 
				COLUMN 91, "---TIME---" 
				PRINT COLUMN 57, "Est Actual", 
				COLUMN 80, "Required", 
				COLUMN 91, "Required", 
				COLUMN 111, "WEIGHT VOLUME" 
				PRINT COLUMN 1, "Shop", 
				COLUMN 11, "Suffix", 
				COLUMN 31, "Product", 
				COLUMN 57, "Start Start", 
				COLUMN 80, "Completed", 
				COLUMN 91, "Completed", 
				COLUMN 107, "----------------------" 
				PRINT COLUMN 1, "Order", 
				COLUMN 11, "Number", 
				COLUMN 22, "Customer", 
				COLUMN 31, "Description", 
				COLUMN 47, "Status", 
				COLUMN 57, "Due Due", 
				COLUMN 80, "Remaining", 
				COLUMN 91, "Remaining", 
				COLUMN 102, "UOM" 
			ELSE 
				PRINT COLUMN 57, "----- D A T E S ------", 
				COLUMN 80, "-QUANTITY-", 
				COLUMN 91, "---TIME---" 
				PRINT COLUMN 57, "Est Actual", 
				COLUMN 80, "Required", 
				COLUMN 91, "Required", 
				COLUMN 109, "PROCESSING COSTS" 
				PRINT COLUMN 1, "Shop", 
				COLUMN 11, "Suffix", 
				COLUMN 31, "Product", 
				COLUMN 57, "Start Start", 
				COLUMN 80, "Completed", 
				COLUMN 91, "Completed", 
				COLUMN 107, "----------------------" 
				PRINT COLUMN 1, "Order", 
				COLUMN 11, "Number", 
				COLUMN 22, "Customer", 
				COLUMN 31, "Description", 
				COLUMN 47, "Status", 
				COLUMN 57, "Due Due", 
				COLUMN 80, "Remaining", 
				COLUMN 91, "Remaining", 
				COLUMN 102, "UOM", 
				COLUMN 108, "Estimated", 
				COLUMN 121, "Actual" 
			END IF 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		BEFORE GROUP OF rr_shoporddetl.work_centre_code 
			LET rv_tt_required_qty = 0 
			LET rv_tt_completed_qty = 0 
			LET rv_tt_balance_qty = 0 
			LET rv_tt_weight_qty = 0 
			LET rv_tt_cubic_qty = 0 

			LET rv_tt_required_time = 0 
			LET rv_tt_completed_time = 0 
			LET rv_tt_balance_time = 0 

			LET rv_tt_est_cost = 0 
			LET rv_tt_act_cost = 0 

			SKIP TO top OF PAGE 

		ON EVERY ROW 
			IF rr_shopordhead.status_ind = "R" THEN 
				LET rv_desc_txt = "Released" 
			ELSE 
				LET rv_desc_txt = "Held" 
			END IF 

			SELECT * 
			INTO rr_workcentre.* 
			FROM workcentre 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND work_centre_code = rr_shoporddetl.work_centre_code 

			LET rv_cost = 0 
			LET rv_price = 0 

			SELECT sum(rate_amt) 
			INTO rv_cost 
			FROM workctrrate 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND work_centre_code = rr_shoporddetl.work_centre_code 
			AND rate_ind = "V" 

			SELECT sum(rate_amt) 
			INTO rv_price 
			FROM workctrrate 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND work_centre_code = rr_shoporddetl.work_centre_code 
			AND rate_ind = "F" 

			IF rv_price IS NULL THEN 
				LET rv_price = 0 
			END IF 
			IF rv_cost IS NULL THEN 
				LET rv_cost = 0 
			END IF 

			IF rr_workcentre.processing_ind = "Q" THEN 
				LET rv_cost = ((rv_cost / rr_workcentre.time_qty) 
				* rr_shoporddetl.oper_factor_amt * 
				rr_shopordhead.order_qty) + rv_price 
			ELSE 
				LET rv_cost = (rv_cost * rr_shoporddetl.oper_factor_amt * 
				rr_shopordhead.order_qty) + rv_price 
			END IF 

			IF rv_cost IS NULL THEN 
				LET rv_cost = 0 
			END IF 

			LET rv_required_qty = rr_shopordhead.order_qty 
			* rr_shoporddetl.oper_factor_amt 

			SELECT sum(receipt_qty) 
			INTO rv_completed_qty 
			FROM wipreceipt 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND work_centre_code = rr_shoporddetl.work_centre_code 
			AND shop_order_num = rr_shoporddetl.shop_order_num 
			AND suffix_num = rr_shoporddetl.suffix_num 
			AND sequence_num = rr_shoporddetl.sequence_num 
			AND type_ind = "M" 

			SELECT sum(cost_amt) 
			INTO rv_act_cost 
			FROM wipreceipt 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND work_centre_code = rr_shoporddetl.work_centre_code 
			AND shop_order_num = rr_shoporddetl.shop_order_num 
			AND suffix_num = rr_shoporddetl.suffix_num 
			AND sequence_num = rr_shoporddetl.sequence_num 

			IF rv_required_qty IS NULL THEN 
				LET rv_required_qty = 0 
			END IF 
			IF rv_completed_qty IS NULL THEN 
				LET rv_completed_qty = 0 
			END IF 

			IF rr_workcentre.processing_ind = "Q" THEN 
				LET rv_required_time = (rv_required_qty 
				* rr_shoporddetl.oper_factor_amt) 
				/ rr_workcentre.time_qty 
			ELSE 
				LET rv_required_time = (rv_required_qty 
				* rr_shoporddetl.oper_factor_amt) 
				* rr_workcentre.time_qty 
			END IF 

			SELECT sum(receipt_qty) 
			INTO rv_completed_time 
			FROM wipreceipt 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND work_centre_code = rr_shoporddetl.work_centre_code 
			AND shop_order_num = rr_shoporddetl.shop_order_num 
			AND suffix_num = rr_shoporddetl.suffix_num 
			AND sequence_num = rr_shoporddetl.sequence_num 
			AND type_ind = "T" 

			LET rv_status_ind = NULL 

			SELECT status_ind 
			INTO rv_status_ind 
			FROM wipreceipt 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND work_centre_code = rr_shoporddetl.work_centre_code 
			AND shop_order_num = rr_shoporddetl.shop_order_num 
			AND suffix_num = rr_shoporddetl.suffix_num 
			AND sequence_num = rr_shoporddetl.sequence_num 
			AND status_ind = "C" 

			SELECT unique * 
			INTO rr_wipreceipt.* 
			FROM wipreceipt 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND work_centre_code = rr_shoporddetl.work_centre_code 
			AND shop_order_num = rr_shoporddetl.shop_order_num 
			AND suffix_num = rr_shoporddetl.suffix_num 
			AND sequence_num = rr_shoporddetl.sequence_num 
			AND status_ind = "C" 

			IF rv_status_ind = "C" THEN 
				LET rv_desc_txt = "Complete" 
			END IF 

			IF rv_completed_time IS NULL THEN 
				LET rv_completed_time = 0 
			END IF 

			SELECT desc_text, weight_qty, cubic_qty 
			INTO rv_product_desc_text, rv_weight_qty, rv_cubic_qty 
			FROM product 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = rr_shopordhead.part_code 

			IF rr_shoporddetl.act_act_cost_amt IS NULL THEN 
				LET rr_shoporddetl.act_act_cost_amt = 0 
			END IF 

			IF rv_required_qty > rv_completed_qty THEN 
				LET rv_balance_qty = rv_required_qty - rv_completed_qty 
			ELSE 
				LET rv_balance_qty = NULL 
			END IF 

			LET rv_weight_qty = rv_weight_qty * rv_balance_qty 
			LET rv_cubic_qty = rv_cubic_qty * rv_balance_qty 


			IF rv_required_time > rv_completed_time THEN 
				LET rv_balance_time = rv_required_time - rv_completed_time 
			ELSE 
				LET rv_balance_time = NULL 
			END IF 


			IF rr_workcentre.count_centre_ind = "O" THEN 
				PRINT COLUMN 1, rr_shoporddetl.shop_order_num USING "<<<<<<<<", 
				COLUMN 11, rr_shoporddetl.suffix_num, 
				COLUMN 22, rr_shopordhead.cust_code USING "<<<<<<<<", 
				COLUMN 31, rr_shopordhead.part_code, 
				COLUMN 47, rv_desc_txt, 
				COLUMN 57, rr_shoporddetl.start_date, 
				COLUMN 69, rr_shoporddetl.end_date, 
				COLUMN 80, rv_required_qty USING "#######.##", 
				COLUMN 91, rv_required_time USING "#######.##", 
				COLUMN 103, rr_wipreceipt.uom_code, 
				COLUMN 105, rv_weight_qty USING "#######.##", 
				COLUMN 117, rv_cubic_qty USING "#######.##" 

				PRINT COLUMN 31, rv_product_desc_text [1,25], 
				COLUMN 57, rr_shoporddetl.actual_start_date, 
				COLUMN 69, rr_shoporddetl.actual_end_date, 
				COLUMN 80, rv_completed_qty USING "#######.##", 
				COLUMN 91, rv_completed_time USING "#######.##" 

				PRINT COLUMN 80, rv_balance_qty USING "#######.##", 
				COLUMN 91, rv_balance_time USING "#######.##" 
				PRINT 
			ELSE 
				PRINT COLUMN 1, rr_shoporddetl.shop_order_num USING "<<<<<<<<", 
				COLUMN 11, rr_shoporddetl.suffix_num, 
				COLUMN 22, rr_shopordhead.cust_code USING "<<<<<<<<", 
				COLUMN 31, rr_shopordhead.part_code, 
				COLUMN 47, rv_desc_txt, 
				COLUMN 57, rr_shoporddetl.start_date, 
				COLUMN 69, rr_shoporddetl.end_date, 
				COLUMN 80, rv_required_qty USING "#######.##", 
				COLUMN 91, rv_required_time USING "#######.##", 
				COLUMN 103, rr_wipreceipt.uom_code, 
				COLUMN 105, rv_cost USING "#######.##", 
				COLUMN 117, rv_act_cost USING "#######.##" 

				PRINT COLUMN 31, rv_product_desc_text [1,25], 
				COLUMN 57, rr_shoporddetl.actual_start_date, 
				COLUMN 69, rr_shoporddetl.actual_end_date, 
				COLUMN 80, rv_completed_qty USING "#######.##", 
				COLUMN 91, rv_completed_time USING "#######.##" 

				PRINT COLUMN 80, rv_balance_qty USING "#######.##", 
				COLUMN 91, rv_balance_time USING "#######.##" 
				PRINT 
			END IF 

			LET rv_tt_required_qty = rv_tt_required_qty + rv_required_qty 
			LET rv_tt_required_time = rv_tt_required_time + rv_required_time 
			LET rv_tt_est_cost = rv_tt_est_cost + rv_cost 
			LET rv_tt_act_cost = rv_tt_act_cost + rv_act_cost 

			LET rv_tt_completed_qty = rv_tt_completed_qty + rv_completed_qty 
			LET rv_tt_completed_time = rv_tt_completed_time + rv_completed_time 

			LET rv_tt_weight_qty = rv_tt_weight_qty + rv_weight_qty 
			LET rv_tt_cubic_qty = rv_tt_cubic_qty + rv_cubic_qty 

			LET rv_tt_balance_qty = rv_tt_balance_qty + rv_balance_qty 
			LET rv_tt_balance_time = rv_tt_balance_time + rv_balance_time 

		AFTER GROUP OF rr_shoporddetl.work_centre_code 
			PRINT COLUMN 80, "-----------------------------------------------" 
			IF rr_workcentre.count_centre_ind = "O" THEN 
				PRINT COLUMN 44, "Total FOR Work Centre : Required :", 
				COLUMN 80, rv_tt_required_qty USING "#######.##", 
				COLUMN 91, rv_tt_required_time USING "#######.##", 
				COLUMN 103, rr_wipreceipt.uom_code, 
				COLUMN 107, rv_tt_weight_qty USING "#######.##", 
				COLUMN 117, rv_tt_cubic_qty USING "#######.##" 
				PRINT COLUMN 68, "Completed :", 
				COLUMN 80, rv_tt_completed_qty USING "#######.##", 
				COLUMN 91, rv_tt_completed_time USING "#######.##" 
				PRINT COLUMN 68, "Remaining :", 
				COLUMN 80, rv_tt_balance_qty USING "#######.##", 
				COLUMN 91, rv_tt_balance_time USING "#######.##" 
			ELSE 
				PRINT COLUMN 44, "Total FOR Work Centre : Required :", 
				COLUMN 80, rv_tt_required_qty USING "#######.##", 
				COLUMN 91, rv_tt_required_time USING "#######.##", 
				COLUMN 103, rr_wipreceipt.uom_code, 
				COLUMN 107, rv_tt_est_cost USING "#######.##", 
				COLUMN 117, rv_tt_act_cost USING "#######.##" 
				PRINT COLUMN 68, "Completed :", 
				COLUMN 80, rv_tt_completed_qty USING "#######.##", 
				COLUMN 91, rv_tt_completed_time USING "#######.##" 
				PRINT COLUMN 68, "Remaining :", 
				COLUMN 80, rv_tt_balance_qty USING "#######.##", 
				COLUMN 91, rv_tt_balance_time USING "#######.##" 
			END IF 
			PRINT COLUMN 80, "-----------------------------------------------" 

		ON LAST ROW 
			PRINT 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4]


END REPORT 
###########################################################################
# END REPORT M47_rpt_list_wip(p_rpt_idx,rr_shopordhead, rr_shoporddetl) 
###########################################################################